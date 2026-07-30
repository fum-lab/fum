import Darwin
import Foundation

public enum ModelOnlyFailureCode: String, Codable, Equatable, Sendable {
  case providerUnconfigured = "provider_unconfigured"
  case providerUnavailable = "provider_unavailable"
  case providerMismatch = "provider_mismatch"
  case providerInputUnsupported = "provider_input_unsupported"
  case providerTimedOut = "provider_timed_out"
  case providerCancelled = "provider_cancelled"
  case outputLimitExceeded = "output_limit_exceeded"
  case providerRefused = "provider_refused"
  case providerFailed = "provider_failed"
  case providerProtocolError = "provider_protocol_error"
}

public enum ModelOnlyAttemptStatus: String, Codable, Equatable, Sendable {
  case completed
  case rejected
}

public struct ModelOnlyFailure: Codable, Equatable, Sendable {
  public let code: ModelOnlyFailureCode
  public let message: String
  public let retryable: Bool
}

public struct ModelOnlySamplingPassport: Codable, Equatable, Sendable {
  public let temperature: String
  public let topP: String
  public let topK: String
  public let seed: String

  enum CodingKeys: String, CodingKey {
    case temperature
    case topP = "top_p"
    case topK = "top_k"
    case seed
  }
}

public struct ModelOnlyProviderLimitsPassport: Codable, Equatable, Sendable {
  public let maxOutputBytes: Int
  public let timeoutMilliseconds: Int
  public let maxOutputTokens: String

  enum CodingKeys: String, CodingKey {
    case maxOutputBytes = "max_output_bytes"
    case timeoutMilliseconds = "timeout_milliseconds"
    case maxOutputTokens = "max_output_tokens"
  }
}

public struct ModelOnlyProviderEnvironmentPassport: Codable, Equatable, Sendable {
  public let scope: String
  public let promptTransport: String
  public let application: String
  public let tools: Bool
  public let files: Bool
  public let network: Bool
  public let executesOutput: Bool

  enum CodingKeys: String, CodingKey {
    case scope
    case promptTransport = "prompt_transport"
    case application
    case tools
    case files
    case network
    case executesOutput = "executes_output"
  }
}

public struct ModelOnlyProviderPassport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let adapterID: String
  public let provider: ModelProviderIdentity
  public let modelWeightsSHA256: String
  public let sampling: ModelOnlySamplingPassport
  public let limits: ModelOnlyProviderLimitsPassport
  public let environment: ModelOnlyProviderEnvironmentPassport

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case adapterID = "adapter_id"
    case provider
    case modelWeightsSHA256 = "model_weights_sha256"
    case sampling
    case limits
    case environment
  }
}

public struct ModelOnlyAttemptEnvelope: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let invocationID: String
  public let inputSHA256: String
  public let status: ModelOnlyAttemptStatus
  public let passport: ModelOnlyProviderPassport?
  public let output: ModelStepOutput?
  public let metrics: ModelStepMetrics?
  public let failure: ModelOnlyFailure?

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case invocationID = "invocation_id"
    case inputSHA256 = "input_sha256"
    case status
    case passport
    case output
    case metrics
    case failure
  }
}

public enum ModelOnlyJSON {
  public static func encodeAttempt(_ attempt: ModelOnlyAttemptEnvelope) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(attempt)
  }
}

public struct LMStudioConfiguration: Sendable {
  public let executableURL: URL
  public let modelIdentifier: String
  public let runtimeVersion: String
  public let applicationVersion: String
  public let environment: [String: String]
  public let ttlSeconds: Int

  public init(
    executableURL: URL,
    modelIdentifier: String,
    runtimeVersion: String,
    applicationVersion: String,
    environment: [String: String],
    ttlSeconds: Int = 1
  ) {
    self.executableURL = executableURL
    self.modelIdentifier = modelIdentifier
    self.runtimeVersion = runtimeVersion
    self.applicationVersion = applicationVersion
    self.environment = environment
    self.ttlSeconds = ttlSeconds
  }

  public var providerIdentity: ModelProviderIdentity {
    ModelProviderIdentity(
      kind: "local_cli",
      id: "fum.lm-studio-cli.one-shot.v1",
      model: modelIdentifier,
      runtime: runtimeVersion
    )
  }
}

public struct ModelOnlyProcessSpecification: Sendable {
  public let executableURL: URL
  public let arguments: [String]
  public let environment: [String: String]
  public let maxOutputBytes: Int
  public let timeoutMilliseconds: Int

  public init(
    executableURL: URL,
    arguments: [String],
    environment: [String: String],
    maxOutputBytes: Int,
    timeoutMilliseconds: Int
  ) {
    self.executableURL = executableURL
    self.arguments = arguments
    self.environment = environment
    self.maxOutputBytes = maxOutputBytes
    self.timeoutMilliseconds = timeoutMilliseconds
  }
}

public enum ModelOnlyProcessOutcome: Equatable, Sendable {
  case completed(Data)
  case timedOut
  case cancelled
  case outputLimitExceeded
  case refused
  case failed
  case unavailable
}

public protocol ModelOnlyProcessTransport: Sendable {
  func run(_ specification: ModelOnlyProcessSpecification) async -> ModelOnlyProcessOutcome
}

public struct RecordedModelOnlyProcessTransport: ModelOnlyProcessTransport {
  public let outcome: ModelOnlyProcessOutcome

  public init(outcome: ModelOnlyProcessOutcome) {
    self.outcome = outcome
  }

  public func run(_ specification: ModelOnlyProcessSpecification) async -> ModelOnlyProcessOutcome {
    outcome
  }
}

public struct FoundationModelOnlyProcessTransport: ModelOnlyProcessTransport {
  public init() {}

  public func run(_ specification: ModelOnlyProcessSpecification) async -> ModelOnlyProcessOutcome {
    let state = ModelOnlyProcessState(specification: specification)
    return await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        state.start(continuation: continuation)
      }
    } onCancel: {
      state.cancel()
    }
  }
}

private final class ModelOnlyProcessState: @unchecked Sendable {
  private let lock = NSLock()
  private let specification: ModelOnlyProcessSpecification
  private let process = Process()
  private let standardOutput = Pipe()
  private let standardError = Pipe()
  private var output = Data()
  private var continuation: CheckedContinuation<ModelOnlyProcessOutcome, Never>?
  private var finished = false
  private var timedOut = false
  private var cancelled = false
  private var exceeded = false

  init(specification: ModelOnlyProcessSpecification) {
    self.specification = specification
  }

  func start(continuation: CheckedContinuation<ModelOnlyProcessOutcome, Never>) {
    lock.lock()
    self.continuation = continuation
    let wasCancelled = cancelled
    lock.unlock()
    guard !wasCancelled else {
      finish(.cancelled)
      return
    }

    guard FileManager.default.isExecutableFile(atPath: specification.executableURL.path) else {
      finish(.unavailable)
      return
    }

    process.executableURL = specification.executableURL
    process.arguments = specification.arguments
    process.environment = specification.environment
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = standardOutput
    process.standardError = standardError
    standardOutput.fileHandleForReading.readabilityHandler = { [weak self] handle in
      self?.consume(handle.availableData)
    }
    standardError.fileHandleForReading.readabilityHandler = { handle in
      _ = handle.availableData
    }
    process.terminationHandler = { [weak self] process in
      self?.terminated(status: process.terminationStatus)
    }

    do {
      try process.run()
    } catch {
      finish(.unavailable)
      return
    }

    DispatchQueue.global(qos: .utility).asyncAfter(
      deadline: .now() + .milliseconds(specification.timeoutMilliseconds)
    ) { [weak self] in
      self?.timeout()
    }
  }

  func cancel() {
    lock.lock()
    guard !finished else {
      lock.unlock()
      return
    }
    cancelled = true
    let running = process.isRunning
    let waitingToStart = continuation != nil
    lock.unlock()
    if running {
      terminateWithFallback()
    } else if waitingToStart {
      finish(.cancelled)
    }
  }

  private func consume(_ data: Data) {
    guard !data.isEmpty else { return }
    lock.lock()
    guard !finished else {
      lock.unlock()
      return
    }
    let remainingThroughSentinel = max(specification.maxOutputBytes + 1 - output.count, 0)
    output.append(data.prefix(remainingThroughSentinel))
    if output.count > specification.maxOutputBytes {
      exceeded = true
    }
    let shouldTerminate = exceeded && process.isRunning
    lock.unlock()
    if shouldTerminate {
      terminateWithFallback()
    }
  }

  private func timeout() {
    lock.lock()
    guard !finished, process.isRunning else {
      lock.unlock()
      return
    }
    timedOut = true
    lock.unlock()
    terminateWithFallback()
  }

  private func terminated(status: Int32) {
    standardOutput.fileHandleForReading.readabilityHandler = nil
    standardError.fileHandleForReading.readabilityHandler = nil
    consume(standardOutput.fileHandleForReading.readDataToEndOfFile())
    _ = standardError.fileHandleForReading.readDataToEndOfFile()

    lock.lock()
    let outcome: ModelOnlyProcessOutcome
    if cancelled {
      outcome = .cancelled
    } else if timedOut {
      outcome = .timedOut
    } else if exceeded {
      outcome = .outputLimitExceeded
    } else if status == 0 {
      outcome = .completed(output)
    } else {
      outcome = .failed
    }
    lock.unlock()
    finish(outcome)
  }

  private func terminateWithFallback() {
    process.terminate()
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self, self.process.isRunning else { return }
      kill(self.process.processIdentifier, SIGKILL)
    }
  }

  private func finish(_ outcome: ModelOnlyProcessOutcome) {
    lock.lock()
    guard !finished else {
      lock.unlock()
      return
    }
    finished = true
    let continuation = self.continuation
    self.continuation = nil
    lock.unlock()
    standardOutput.fileHandleForReading.readabilityHandler = nil
    standardError.fileHandleForReading.readabilityHandler = nil
    continuation?.resume(returning: outcome)
  }
}

public struct LMStudioModelOnlyAdapter: Sendable {
  private static let maximumArgvPromptBytes = 65_536
  private let configuration: LMStudioConfiguration?
  private let transport: any ModelOnlyProcessTransport

  public init(
    configuration: LMStudioConfiguration?,
    transport: any ModelOnlyProcessTransport = FoundationModelOnlyProcessTransport()
  ) {
    self.configuration = configuration
    self.transport = transport
  }

  public func complete(_ request: ModelStepRequest) async -> ModelOnlyAttemptEnvelope {
    let inputSHA256 = (try? ModelStepJSON.inputSHA256(for: request)) ?? "sha256:unknown"
    guard let configuration else {
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: nil,
        code: .providerUnconfigured
      )
    }

    let passport = makePassport(configuration: configuration, request: request)
    guard request.provider == configuration.providerIdentity else {
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerMismatch
      )
    }

    guard
      !request.messages.contains(where: { $0.content.unicodeScalars.contains("\u{0}") }),
      let prompt = renderPrompt(request.messages),
      prompt.utf8.count <= Self.maximumArgvPromptBytes
    else {
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerInputUnsupported
      )
    }

    let specification = ModelOnlyProcessSpecification(
      executableURL: configuration.executableURL,
      arguments: [
        "chat",
        configuration.modelIdentifier,
        "--prompt",
        prompt,
        "--system-prompt",
        "Верни один текстовый ответ. Не вызывай инструменты и не исполняй собственный вывод.",
        "--ttl",
        String(configuration.ttlSeconds),
        "--dont-fetch-catalog",
        "-y",
      ],
      environment: configuration.environment.merging([
        "CI": "1",
        "NO_COLOR": "1",
        "TERM": "dumb",
      ]) { _, fixed in fixed },
      maxOutputBytes: request.limits.maxOutputBytes,
      timeoutMilliseconds: request.limits.timeoutMilliseconds
    )

    switch await transport.run(specification) {
    case .completed(let data):
      guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
        return rejection(
          request: request,
          inputSHA256: inputSHA256,
          passport: passport,
          code: .providerProtocolError
        )
      }
      return ModelOnlyAttemptEnvelope(
        schemaVersion: 1,
        invocationID: request.invocationID,
        inputSHA256: inputSHA256,
        status: .completed,
        passport: passport,
        output: ModelStepOutput(content: content, finishReason: "stop"),
        metrics: ModelStepMetrics(
          inputBytes: request.messages.reduce(0) { $0 + $1.content.utf8.count },
          outputBytes: data.count
        ),
        failure: nil
      )
    case .timedOut:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerTimedOut
      )
    case .cancelled:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerCancelled
      )
    case .outputLimitExceeded:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .outputLimitExceeded
      )
    case .refused:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerRefused
      )
    case .failed:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerFailed
      )
    case .unavailable:
      return rejection(
        request: request,
        inputSHA256: inputSHA256,
        passport: passport,
        code: .providerUnavailable
      )
    }
  }

  private func renderPrompt(_ messages: [ModelMessage]) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    guard
      let data = try? encoder.encode(messages),
      let json = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    return "FUM_MODEL_MESSAGES_V1\n\(json)"
  }

  private func makePassport(
    configuration: LMStudioConfiguration,
    request: ModelStepRequest
  ) -> ModelOnlyProviderPassport {
    ModelOnlyProviderPassport(
      schemaVersion: 1,
      adapterID: "fum.lm-studio-cli.one-shot.v1",
      provider: configuration.providerIdentity,
      modelWeightsSHA256: "unknown",
      sampling: ModelOnlySamplingPassport(
        temperature: "unknown",
        topP: "unknown",
        topK: "unknown",
        seed: "unknown"
      ),
      limits: ModelOnlyProviderLimitsPassport(
        maxOutputBytes: request.limits.maxOutputBytes,
        timeoutMilliseconds: request.limits.timeoutMilliseconds,
        maxOutputTokens: "unknown"
      ),
      environment: ModelOnlyProviderEnvironmentPassport(
        scope: "local_process",
        promptTransport: "argv",
        application: "LM Studio \(configuration.applicationVersion)",
        tools: false,
        files: false,
        network: false,
        executesOutput: false
      )
    )
  }

  private func rejection(
    request: ModelStepRequest,
    inputSHA256: String,
    passport: ModelOnlyProviderPassport?,
    code: ModelOnlyFailureCode
  ) -> ModelOnlyAttemptEnvelope {
    let failure = safeFailure(code)
    return ModelOnlyAttemptEnvelope(
      schemaVersion: 1,
      invocationID: request.invocationID,
      inputSHA256: inputSHA256,
      status: .rejected,
      passport: passport,
      output: nil,
      metrics: nil,
      failure: failure
    )
  }

  private func safeFailure(_ code: ModelOnlyFailureCode) -> ModelOnlyFailure {
    switch code {
    case .providerUnconfigured:
      return ModelOnlyFailure(
        code: code,
        message: "Реальный модельный провайдер не настроен.",
        retryable: false
      )
    case .providerUnavailable:
      return ModelOnlyFailure(
        code: code,
        message: "Локальный runtime провайдера недоступен.",
        retryable: true
      )
    case .providerMismatch:
      return ModelOnlyFailure(
        code: code,
        message: "Идентичность настроенного провайдера не совпадает с запросом.",
        retryable: false
      )
    case .providerInputUnsupported:
      return ModelOnlyFailure(
        code: code,
        message: "Вход не помещается в безопасный профиль argv провайдера.",
        retryable: false
      )
    case .providerTimedOut:
      return ModelOnlyFailure(
        code: code,
        message: "Модельный провайдер превысил заданный тайм-аут.",
        retryable: true
      )
    case .providerCancelled:
      return ModelOnlyFailure(
        code: code,
        message: "Модельный вызов отменён вызывающим runtime.",
        retryable: false
      )
    case .outputLimitExceeded:
      return ModelOnlyFailure(
        code: code,
        message: "Ответ провайдера превысил max_output_bytes.",
        retryable: false
      )
    case .providerRefused:
      return ModelOnlyFailure(
        code: code,
        message: "Провайдер наблюдаемо отказал в выполнении вызова.",
        retryable: false
      )
    case .providerFailed:
      return ModelOnlyFailure(
        code: code,
        message: "Провайдер завершил вызов с ошибкой.",
        retryable: true
      )
    case .providerProtocolError:
      return ModelOnlyFailure(
        code: code,
        message: "Ответ провайдера нарушает профиль model-only.",
        retryable: false
      )
    }
  }
}
