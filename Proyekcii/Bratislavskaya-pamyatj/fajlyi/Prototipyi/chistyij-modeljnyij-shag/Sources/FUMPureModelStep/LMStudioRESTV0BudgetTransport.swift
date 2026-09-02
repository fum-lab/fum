import CryptoKit
import Foundation

struct ModelOnlyHTTPRequest: Equatable, Sendable {
  let endpoint: URL
  let body: Data
  let timeoutMilliseconds: Int64
  let maximumResponseBytes: Int
}

enum ModelOnlyHTTPOutcome: Equatable, Sendable {
  case response(statusCode: Int, data: Data, elapsedMilliseconds: Int64)
  case timedOut
  case partialResponse
  case responseTooLarge
  case failed
}

protocol ModelOnlyHTTPClient: Sendable {
  func post(_ request: ModelOnlyHTTPRequest) async -> ModelOnlyHTTPOutcome
}

final class RejectingModelOnlyRedirectDelegate: NSObject, URLSessionTaskDelegate,
  @unchecked Sendable
{
  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void
  ) {
    completionHandler(nil)
  }
}

final class URLSessionModelOnlyHTTPClient: ModelOnlyHTTPClient, @unchecked Sendable {
  private let protocolClasses: [AnyClass]?

  init() {
    self.protocolClasses = nil
  }

  init(protocolClasses: [AnyClass]) {
    self.protocolClasses = protocolClasses
  }

  func post(_ request: ModelOnlyHTTPRequest) async -> ModelOnlyHTTPOutcome {
    guard request.timeoutMilliseconds > 0, request.maximumResponseBytes > 0 else {
      return .failed
    }
    let timeout = Double(request.timeoutMilliseconds) / 1_000
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = timeout
    configuration.timeoutIntervalForResource = timeout
    configuration.httpCookieStorage = nil
    configuration.httpShouldSetCookies = false
    configuration.urlCredentialStorage = nil
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    configuration.connectionProxyDictionary = [:]
    configuration.waitsForConnectivity = false
    if let protocolClasses {
      configuration.protocolClasses = protocolClasses
    }
    let session = URLSession(
      configuration: configuration,
      delegate: RejectingModelOnlyRedirectDelegate(),
      delegateQueue: nil
    )
    defer { session.invalidateAndCancel() }

    var urlRequest = URLRequest(url: request.endpoint)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = request.body
    urlRequest.timeoutInterval = timeout
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    let started = DispatchTime.now().uptimeNanoseconds

    do {
      let (bytes, response) = try await session.bytes(for: urlRequest)
      guard let httpResponse = response as? HTTPURLResponse else { return .failed }
      guard httpResponse.url?.absoluteString == request.endpoint.absoluteString else {
        return .failed
      }
      guard !(300..<400).contains(httpResponse.statusCode) else { return .failed }
      var data = Data()
      data.reserveCapacity(min(request.maximumResponseBytes, 64 * 1_024))
      for try await byte in bytes {
        guard data.count < request.maximumResponseBytes else {
          return .responseTooLarge
        }
        data.append(byte)
      }
      let elapsed = Self.elapsedMilliseconds(since: started)
      return .response(
        statusCode: httpResponse.statusCode,
        data: data,
        elapsedMilliseconds: elapsed
      )
    } catch let error as URLError {
      switch error.code {
      case .timedOut:
        return .timedOut
      case .networkConnectionLost:
        return .partialResponse
      default:
        return .failed
      }
    } catch {
      return .failed
    }
  }

  private static func elapsedMilliseconds(since started: UInt64) -> Int64 {
    let finished = DispatchTime.now().uptimeNanoseconds
    guard finished >= started else { return .max }
    let milliseconds = (finished - started) / 1_000_000
    guard milliseconds <= UInt64(Int64.max) else { return .max }
    return Int64(milliseconds)
  }
}

public struct LMStudioRESTV0Configuration: Equatable, Sendable {
  public let endpoint: URL
  public let tokenizerIdentity: String
  public let maximumResponseBytes: Int

  public init(
    endpoint: URL,
    tokenizerIdentity: String,
    maximumResponseBytes: Int = 1_048_576
  ) {
    self.endpoint = endpoint
    self.tokenizerIdentity = tokenizerIdentity
    self.maximumResponseBytes = maximumResponseBytes
  }
}

public struct LMStudioRESTV0BudgetTransport: ModelOnlyBudgetTransport {
  public static let absoluteMaximumResponseBytes = 1_048_576

  private static let chatCompletionsPath =
    ["", "api", "v0", "chat", "completions"].joined(separator: "/")

  let capability: ModelOnlyProviderCapability

  private let configuration: LMStudioRESTV0Configuration
  private let client: any ModelOnlyHTTPClient

  public init(configuration: LMStudioRESTV0Configuration) {
    self.init(configuration: configuration, client: URLSessionModelOnlyHTTPClient())
  }

  init(
    configuration: LMStudioRESTV0Configuration,
    client: any ModelOnlyHTTPClient
  ) {
    self.configuration = configuration
    self.client = client
    self.capability = ModelOnlyProviderCapability(
      executionMode: .local,
      providerIdentity: "lmstudio",
      providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
      endpoint: configuration.endpoint.absoluteString,
      tokenizerIdentity: configuration.tokenizerIdentity,
      maxOutputTokenField: "max_tokens",
      trustedUsageSource: .structuredProviderResponse
    )
  }

  func generate(
    _ request: ModelOnlyProviderRequest
  ) async -> ModelOnlyProviderTransportOutcome {
    guard Self.isExactLoopbackChatEndpoint(configuration.endpoint),
      request.maxOutputTokenField == "max_tokens",
      request.maxOutputTokens > 0,
      request.timeoutMilliseconds > 0,
      configuration.maximumResponseBytes > 0,
      configuration.maximumResponseBytes <= Self.absoluteMaximumResponseBytes,
      !request.modelIdentity.isEmpty
    else {
      return .failed
    }

    let payload = LMStudioRESTV0RequestPayload(
      model: request.modelIdentity,
      messages: [LMStudioRESTV0Message(role: "user", content: request.input)],
      maxTokens: request.maxOutputTokens,
      stream: false
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    guard let body = try? encoder.encode(payload) else { return .failed }

    let outcome = await client.post(
      ModelOnlyHTTPRequest(
        endpoint: configuration.endpoint,
        body: body,
        timeoutMilliseconds: request.timeoutMilliseconds,
        maximumResponseBytes: configuration.maximumResponseBytes
      )
    )
    switch outcome {
    case .timedOut:
      return .timedOut
    case .partialResponse:
      return .partialResponse
    case .responseTooLarge:
      return .responseTooLarge
    case .failed:
      return .failed
    case .response(let statusCode, let data, let elapsedMilliseconds):
      guard (200..<300).contains(statusCode) else { return .failed }
      guard !data.isEmpty else { return .partialResponse }
      guard (try? JSONSerialization.jsonObject(with: data)) != nil else {
        return .invalidResponse
      }
      switch Self.validateUsageNumberRange(in: data) {
      case .overflow:
        return .arithmeticOverflow
      case .invalid:
        return .invalidResponse
      case .valid:
        break
      }
      guard
        let decoded = try? JSONDecoder().decode(LMStudioRESTV0ResponsePayload.self, from: data),
        !decoded.id.isEmpty,
        !decoded.model.isEmpty,
        decoded.choices.count == 1,
        !decoded.runtime.name.isEmpty,
        !decoded.runtime.version.isEmpty,
        elapsedMilliseconds >= 0
      else {
        return .invalidResponse
      }
      let choice = decoded.choices[0]
      let usage = decoded.usage.map {
        ProviderTokenUsage(
          inputTokens: $0.promptTokens,
          outputTokens: $0.completionTokens,
          totalTokens: $0.totalTokens
        )
      }
      return .completed(
        ModelOnlyProviderResponse(
          responseID: decoded.id,
          modelIdentity: decoded.model,
          runtimeIdentity: ModelOnlyRuntimeIdentity(
            name: decoded.runtime.name,
            version: decoded.runtime.version
          ),
          text: choice.message.content,
          finishReason: choice.finishReason,
          usage: usage,
          elapsedMilliseconds: elapsedMilliseconds,
          responseBodySHA256: Self.sha256(data)
        )
      )
    }
  }

  private enum UsageNumberValidation {
    case valid
    case invalid
    case overflow
  }

  private static func validateUsageNumberRange(in data: Data) -> UsageNumberValidation {
    guard
      let root = try? JSONSerialization.jsonObject(with: data),
      let object = root as? [String: Any]
    else {
      return .invalid
    }
    guard let rawUsage = object["usage"] else { return .valid }
    guard let usage = rawUsage as? [String: Any] else { return .invalid }
    for key in ["prompt_tokens", "completion_tokens", "total_tokens"] {
      guard let value = usage[key], let number = value as? NSNumber else {
        return .invalid
      }
      if CFGetTypeID(number) == CFBooleanGetTypeID() { return .invalid }
      let representation = number.stringValue
      guard let decimal = Decimal(string: representation, locale: Locale(identifier: "en_US_POSIX"))
      else {
        return .invalid
      }
      var rounded = Decimal()
      var source = decimal
      NSDecimalRound(&rounded, &source, 0, .plain)
      guard rounded == decimal else { return .invalid }
      if decimal > Decimal(Int64.max) || decimal < Decimal(Int64.min) {
        return .overflow
      }
    }
    return .valid
  }

  private static func sha256(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private static func isExactLoopbackChatEndpoint(_ url: URL) -> Bool {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return false
    }
    return components.scheme == "http"
      && components.host == "127.0.0.1"
      && components.port != nil
      && components.path == Self.chatCompletionsPath
      && components.user == nil
      && components.password == nil
      && components.query == nil
      && components.fragment == nil
  }
}

private struct LMStudioRESTV0RequestPayload: Encodable {
  let model: String
  let messages: [LMStudioRESTV0Message]
  let maxTokens: Int64
  let stream: Bool

  enum CodingKeys: String, CodingKey {
    case model
    case messages
    case maxTokens = "max_tokens"
    case stream
  }
}

private struct LMStudioRESTV0Message: Codable {
  let role: String
  let content: String
}

private struct LMStudioRESTV0ResponsePayload: Decodable {
  let id: String
  let model: String
  let choices: [LMStudioRESTV0Choice]
  let usage: LMStudioRESTV0Usage?
  let runtime: LMStudioRESTV0Runtime
}

private struct LMStudioRESTV0Choice: Decodable {
  let message: LMStudioRESTV0Message
  let finishReason: String

  enum CodingKeys: String, CodingKey {
    case message
    case finishReason = "finish_reason"
  }
}

private struct LMStudioRESTV0Usage: Decodable {
  let promptTokens: Int64
  let completionTokens: Int64
  let totalTokens: Int64

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

private struct LMStudioRESTV0Runtime: Decodable {
  let name: String
  let version: String
}
