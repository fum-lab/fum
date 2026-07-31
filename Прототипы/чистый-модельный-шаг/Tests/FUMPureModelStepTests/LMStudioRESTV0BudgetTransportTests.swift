import CryptoKit
import Foundation
import Testing

@testable import FUMPureModelStep

@Suite("LM Studio REST v0 budget transport", .serialized)
struct LMStudioRESTV0BudgetTransportTests {
  @Test("Запрос содержит точный max_tokens и не передаёт provider лишние возможности")
  func requestPinsExecutableOutputLimit() async throws {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [.response(statusCode: 200, data: responseData(), elapsedMilliseconds: 17)]
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration(), client: client)

    let outcome = await transport.generate(request(maxOutputTokens: 3))
    let exchanges = await client.recordedRequests()

    guard case .completed(let response) = outcome else {
      Issue.record("Ожидался строгий успешный provider-ответ.")
      return
    }
    #expect(exchanges.count == 1)
    let body = try #require(exchanges.first?.body)
    let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(object["model"] as? String == "qwen/qwen3-0.6b")
    #expect(object["max_tokens"] as? Int == 3)
    #expect(object["stream"] as? Bool == false)
    #expect(object["tools"] == nil)
    #expect(object["store"] == nil)
    let messages = try #require(object["messages"] as? [[String: String]])
    #expect(messages == [["role": "user", "content": "Return A."]])
    #expect(response.modelIdentity == "qwen/qwen3-0.6b")
    #expect(
      response.runtimeIdentity
        == ModelOnlyRuntimeIdentity(name: "llama.cpp-local", version: "2.27.1"))
    #expect(response.usage == ProviderTokenUsage(inputTokens: 5, outputTokens: 3, totalTokens: 8))
    #expect(response.finishReason == "length")
    #expect(response.elapsedMilliseconds == 17)
    let expectedDigest =
      "sha256:"
      + SHA256.hash(data: responseData()).map {
        String(format: "%02x", $0)
      }.joined()
    #expect(response.responseBodySHA256 == expectedDigest)
    #expect(exchanges.first?.maximumResponseBytes == 1_048_576)
  }

  @Test("Missing usage остаётся completed-ответом для консервативного решения adapter")
  func missingUsageIsNotInventedByTransport() async {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [
        .response(
          statusCode: 200,
          data: responseData(includeUsage: false),
          elapsedMilliseconds: 10
        )
      ]
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration(), client: client)

    let outcome = await transport.generate(request())

    guard case .completed(let response) = outcome else {
      Issue.record("Ответ без usage должен дойти до budget adapter как completed(nil usage).")
      return
    }
    #expect(response.usage == nil)
  }

  @Test("Транспортно частичный ответ и timeout различаются")
  func partialTransportAndTimeoutAreDistinct() async {
    let partialClient = RecordingModelOnlyHTTPClient(outcomes: [.partialResponse])
    let timeoutClient = RecordingModelOnlyHTTPClient(outcomes: [.timedOut])
    let partialTransport = LMStudioRESTV0BudgetTransport(
      configuration: configuration(),
      client: partialClient
    )
    let timeoutTransport = LMStudioRESTV0BudgetTransport(
      configuration: configuration(),
      client: timeoutClient
    )

    let partial = await partialTransport.generate(request())
    let timeout = await timeoutTransport.generate(request())

    #expect(partial == .partialResponse)
    #expect(timeout == .timedOut)
  }

  @Test("Полностью полученный malformed JSON является invalid response")
  func malformedCompletedBodyIsInvalid() async {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [
        .response(statusCode: 200, data: Data(#"{"id":"malformed""#.utf8), elapsedMilliseconds: 5)
      ]
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration(), client: client)

    #expect(await transport.generate(request()) == .invalidResponse)
  }

  @Test("Валидная схема с usage вне Int64 имеет отдельный исход переполнения")
  func wireUsageOverflowIsDistinct() async {
    let data = Data(
      responseText(
        usage:
          #""usage":{"prompt_tokens":9223372036854775808,"completion_tokens":1,"total_tokens":9223372036854775809},"#
      ).utf8
    )
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [.response(statusCode: 200, data: data, elapsedMilliseconds: 2)]
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration(), client: client)

    #expect(await transport.generate(request()) == .arithmeticOverflow)
  }

  @Test("Валидный JSON с неверной схемой не считается частичным")
  func validJSONWithInvalidSchemaIsDistinct() async {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [.response(statusCode: 200, data: Data(#"{"id":3}"#.utf8), elapsedMilliseconds: 2)]
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration(), client: client)

    #expect(await transport.generate(request()) == .invalidResponse)
  }

  @Test("Байтовый предел ответа передаётся HTTP-клиенту и имеет отдельный исход")
  func responseByteLimitIsTyped() async {
    let client = RecordingModelOnlyHTTPClient(outcomes: [.responseTooLarge])
    let configuration = LMStudioRESTV0Configuration(
      endpoint: URL(string: "http://127.0.0.1:1234/api/v0/chat/completions")!,
      tokenizerIdentity: "lmstudio.exact-fixture.v1",
      maximumResponseBytes: 256
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration, client: client)

    #expect(await transport.generate(request()) == .responseTooLarge)
    #expect(await client.recordedRequests().first?.maximumResponseBytes == 256)
  }

  @Test("Настройка не может повысить абсолютный предел тела выше одного MiB")
  func responseByteLimitCannotBeRaisedAboveAbsoluteMaximum() async {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [.response(statusCode: 200, data: responseData(), elapsedMilliseconds: 1)]
    )
    let configuration = LMStudioRESTV0Configuration(
      endpoint: URL(string: "http://127.0.0.1:1234/api/v0/chat/completions")!,
      tokenizerIdentity: "lmstudio.exact-fixture.v1",
      maximumResponseBytes: LMStudioRESTV0BudgetTransport.absoluteMaximumResponseBytes + 1
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration, client: client)

    #expect(await transport.generate(request()) == .failed)
    #expect(await client.callCount() == 0)
  }

  @Test("HTTP redirect отклоняется вместо повторной отправки prompt")
  func redirectDelegateNeverForwardsRequest() async throws {
    let original = URL(string: "http://127.0.0.1:1234/api/v0/chat/completions")!
    let external = URL(string: "https://example.invalid/collect")!
    let session = URLSession(configuration: .ephemeral)
    defer { session.invalidateAndCancel() }
    let task = session.dataTask(with: original)
    let response = try #require(
      HTTPURLResponse(
        url: original,
        statusCode: 307,
        httpVersion: "HTTP/1.1",
        headerFields: ["Location": external.absoluteString]
      )
    )
    let delegate = RejectingModelOnlyRedirectDelegate()
    let proposed = URLRequest(url: external)

    let forwarded = await withCheckedContinuation {
      (continuation: CheckedContinuation<URLRequest?, Never>) in
      delegate.urlSession(
        session,
        task: task,
        willPerformHTTPRedirection: response,
        newRequest: proposed
      ) { request in
        continuation.resume(returning: request)
      }
    }

    #expect(forwarded == nil)
  }

  @Test("Concrete HTTP client не следует redirect и не отправляет prompt повторно")
  func concreteClientRejectsRedirect() async {
    ModelOnlyStubURLProtocol.configure { request, stub in
      if request.url?.lastPathComponent == "source" {
        stub.redirect(to: URL(string: "http://127.0.0.1:1234/target")!)
      } else {
        stub.respond(statusCode: 200, body: Data("unexpected".utf8))
      }
    }
    let client = URLSessionModelOnlyHTTPClient(
      protocolClasses: [ModelOnlyStubURLProtocol.self]
    )
    let outcome = await client.post(
      ModelOnlyHTTPRequest(
        endpoint: URL(string: "http://127.0.0.1:1234/source")!,
        body: Data("secret-prompt".utf8),
        timeoutMilliseconds: 50,
        maximumResponseBytes: 64
      )
    )

    if case .response = outcome {
      Issue.record("Redirect не должен превращаться в успешный HTTP-ответ.")
    }
    #expect(ModelOnlyStubURLProtocol.requestCount() == 1)
  }

  @Test("Concrete HTTP client прекращает чтение на N+1 байте")
  func concreteClientEnforcesResponseByteLimit() async {
    ModelOnlyStubURLProtocol.configure { _, stub in
      stub.respond(statusCode: 200, body: Data("12345".utf8))
    }
    let client = URLSessionModelOnlyHTTPClient(
      protocolClasses: [ModelOnlyStubURLProtocol.self]
    )
    let outcome = await client.post(
      ModelOnlyHTTPRequest(
        endpoint: URL(string: "http://127.0.0.1:1234/data")!,
        body: Data("prompt".utf8),
        timeoutMilliseconds: 1_000,
        maximumResponseBytes: 4
      )
    )

    #expect(outcome == .responseTooLarge)
    #expect(ModelOnlyStubURLProtocol.requestCount() == 1)
  }

  @Test("Concrete HTTP client применяет абсолютный resource timeout")
  func concreteClientAppliesResourceTimeout() async {
    ModelOnlyStubURLProtocol.configure { _, _ in
      // Намеренно не завершаем ответ: timeout обязан прервать resource целиком.
    }
    let client = URLSessionModelOnlyHTTPClient(
      protocolClasses: [ModelOnlyStubURLProtocol.self]
    )
    let outcome = await client.post(
      ModelOnlyHTTPRequest(
        endpoint: URL(string: "http://127.0.0.1:1234/stalled")!,
        body: Data("prompt".utf8),
        timeoutMilliseconds: 50,
        maximumResponseBytes: 64
      )
    )

    #expect(outcome == .timedOut)
  }

  @Test("Не-loopback endpoint закрывается без HTTP-вызова")
  func nonLoopbackEndpointFailsClosed() async {
    let client = RecordingModelOnlyHTTPClient(
      outcomes: [.response(statusCode: 200, data: responseData(), elapsedMilliseconds: 1)]
    )
    let configuration = LMStudioRESTV0Configuration(
      endpoint: URL(string: "https://example.invalid/api/v0/chat/completions")!,
      tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1"
    )
    let transport = LMStudioRESTV0BudgetTransport(configuration: configuration, client: client)

    let outcome = await transport.generate(request())

    #expect(outcome == .failed)
    #expect(await client.callCount() == 0)
  }

  private func configuration() -> LMStudioRESTV0Configuration {
    LMStudioRESTV0Configuration(
      endpoint: URL(string: "http://127.0.0.1:1234/api/v0/chat/completions")!,
      tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1"
    )
  }

  private func request(maxOutputTokens: Int64 = 3) -> ModelOnlyProviderRequest {
    ModelOnlyProviderRequest(
      invocationID: "live-fixture",
      input: "Return A.",
      modelIdentity: "qwen/qwen3-0.6b",
      maxOutputTokens: maxOutputTokens,
      maxOutputTokenField: "max_tokens",
      timeoutMilliseconds: 1_000
    )
  }

  private func responseData(includeUsage: Bool = true) -> Data {
    let usage =
      includeUsage
      ? "\"usage\":{\"prompt_tokens\":5,\"completion_tokens\":3,\"total_tokens\":8},"
      : ""
    return Data(responseText(usage: usage).utf8)
  }

  private func responseText(usage: String) -> String {
    """
    {
      "id":"chatcmpl-fixture",
      "model":"qwen/qwen3-0.6b",
      "choices":[{
        "index":0,
        "message":{"role":"assistant","content":"A"},
        "finish_reason":"length"
      }],
      \(usage)
      "runtime":{"name":"llama.cpp-local","version":"2.27.1"}
    }
    """
  }
}

private actor RecordingModelOnlyHTTPClient: ModelOnlyHTTPClient {
  private var outcomes: [ModelOnlyHTTPOutcome]
  private var requests: [ModelOnlyHTTPRequest] = []

  init(outcomes: [ModelOnlyHTTPOutcome]) {
    self.outcomes = outcomes
  }

  func post(_ request: ModelOnlyHTTPRequest) async -> ModelOnlyHTTPOutcome {
    requests.append(request)
    guard !outcomes.isEmpty else { return .failed }
    return outcomes.removeFirst()
  }

  func callCount() -> Int { requests.count }

  func recordedRequests() -> [ModelOnlyHTTPRequest] { requests }
}

private final class ModelOnlyStubURLProtocol: URLProtocol, @unchecked Sendable {
  typealias Handler = @Sendable (URLRequest, ModelOnlyStubURLProtocol) -> Void

  private static let lock = NSLock()
  nonisolated(unsafe) private static var handler: Handler?
  nonisolated(unsafe) private static var calls = 0

  static func configure(_ handler: @escaping Handler) {
    lock.lock()
    Self.handler = handler
    calls = 0
    lock.unlock()
  }

  static func requestCount() -> Int {
    lock.lock()
    defer { lock.unlock() }
    return calls
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.lock.lock()
    Self.calls += 1
    let handler = Self.handler
    Self.lock.unlock()
    handler?(request, self)
  }

  override func stopLoading() {}

  func respond(statusCode: Int, body: Data) {
    guard
      let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Length": String(body.count)]
      )
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }

  func redirect(to url: URL) {
    guard
      let source = request.url,
      let response = HTTPURLResponse(
        url: source,
        statusCode: 307,
        httpVersion: "HTTP/1.1",
        headerFields: ["Location": url.absoluteString]
      )
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    client?.urlProtocol(
      self,
      wasRedirectedTo: URLRequest(url: url),
      redirectResponse: response
    )
  }
}
