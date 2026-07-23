import CoreFoundation
import CryptoKit
import Foundation

public struct ModelProviderIdentity: Codable, Equatable, Sendable {
  public let kind: String
  public let id: String
  public let model: String
  public let runtime: String
}

public struct ModelMessage: Codable, Equatable, Sendable {
  public enum Role: String, Codable, Sendable {
    case system
    case user
    case assistant
  }

  public let role: Role
  public let content: String
}

public struct ModelStepLimits: Codable, Equatable, Sendable {
  public let maxOutputBytes: Int
  public let timeoutMilliseconds: Int

  enum CodingKeys: String, CodingKey {
    case maxOutputBytes = "max_output_bytes"
    case timeoutMilliseconds = "timeout_milliseconds"
  }
}

public struct ModelStepCapabilities: Codable, Equatable, Sendable {
  public let tools: Bool
  public let files: Bool
  public let network: Bool
}

public struct ModelStepRequest: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let invocationID: String
  public let provider: ModelProviderIdentity
  public let messages: [ModelMessage]
  public let responseFormat: String
  public let limits: ModelStepLimits
  public let capabilities: ModelStepCapabilities

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case invocationID = "invocation_id"
    case provider
    case messages
    case responseFormat = "response_format"
    case limits
    case capabilities
  }
}

public struct ModelStepOutput: Codable, Equatable, Sendable {
  public let content: String
  public let finishReason: String

  enum CodingKeys: String, CodingKey {
    case content
    case finishReason = "finish_reason"
  }
}

public struct ModelStepMetrics: Codable, Equatable, Sendable {
  public let inputBytes: Int
  public let outputBytes: Int

  enum CodingKeys: String, CodingKey {
    case inputBytes = "input_bytes"
    case outputBytes = "output_bytes"
  }
}

public struct ModelStepResponse: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let invocationID: String
  public let inputSHA256: String
  public let provider: ModelProviderIdentity
  public let status: String
  public let output: ModelStepOutput
  public let metrics: ModelStepMetrics

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case invocationID = "invocation_id"
    case inputSHA256 = "input_sha256"
    case provider
    case status
    case output
    case metrics
  }
}

public struct ModelStepErrorDetail: Codable, Equatable, Sendable {
  public let code: String
  public let message: String
  public let retryable: Bool
}

public struct ModelStepErrorEnvelope: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let invocationID: String?
  public let status: String
  public let error: ModelStepErrorDetail

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case invocationID = "invocation_id"
    case status
    case error
  }

  public init(invocationID: String?, error: ModelStepContractError) {
    schemaVersion = 1
    self.invocationID = invocationID
    status = "rejected"
    self.error = ModelStepErrorDetail(
      code: error.code,
      message: error.message,
      retryable: error.retryable
    )
  }
}

public struct ModelStepContractError: Error, Equatable, Sendable {
  public let code: String
  public let message: String
  public let retryable: Bool

  public init(code: String, message: String, retryable: Bool = false) {
    self.code = code
    self.message = message
    self.retryable = retryable
  }
}

public enum ModelStepJSON {
  public static let maximumEnvelopeBytes = 1_048_576
  private static let maximumOutputBytes = 65_536
  private static let maximumTimeoutMilliseconds = 300_000

  public static func decodeRequest(_ data: Data) throws -> ModelStepRequest {
    guard !data.isEmpty else {
      throw contractError("invalid_json", "Входной JSON отсутствует.")
    }
    guard data.count <= maximumEnvelopeBytes else {
      throw contractError("input_limit_exceeded", "Входной JSON превышает предел версии 1.")
    }

    let raw: Any
    do {
      raw = try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
      throw contractError("invalid_json", "Вход не является завершённым JSON-объектом.")
    }

    guard let object = raw as? [String: Any] else {
      throw contractError("invalid_request", "Верхний уровень запроса должен быть объектом.")
    }
    try requireExactKeys(
      object,
      expected: [
        "schema_version", "invocation_id", "provider", "messages", "response_format",
        "limits", "capabilities",
      ],
      at: "request"
    )

    let schemaVersion = try requireInteger(object["schema_version"], at: "schema_version")
    guard schemaVersion == 1 else {
      throw contractError("unsupported_schema", "Поддерживается только schema_version 1.")
    }

    let invocationID = try requireString(object["invocation_id"], at: "invocation_id")
    guard isTechnicalIdentifier(invocationID) else {
      throw contractError("invalid_request", "invocation_id не соответствует техническому формату.")
    }

    let provider = try decodeProvider(object["provider"])
    let messages = try decodeMessages(object["messages"])
    let responseFormat = try requireString(object["response_format"], at: "response_format")
    guard responseFormat == "text" else {
      throw contractError("unsupported_response_format", "Версия 1 поддерживает только text.")
    }
    let limits = try decodeLimits(object["limits"])
    let capabilities = try decodeCapabilities(object["capabilities"])

    let inputBytes = messages.reduce(into: 0) { count, message in
      count += message.content.utf8.count
    }
    guard inputBytes <= maximumEnvelopeBytes else {
      throw contractError("input_limit_exceeded", "Содержимое сообщений превышает предел версии 1.")
    }
    guard messages.contains(where: { $0.role == .user }) else {
      throw contractError("invalid_request", "Нужно хотя бы одно сообщение user.")
    }

    return ModelStepRequest(
      schemaVersion: schemaVersion,
      invocationID: invocationID,
      provider: provider,
      messages: messages,
      responseFormat: responseFormat,
      limits: limits,
      capabilities: capabilities
    )
  }

  public static func encodeRequest(_ request: ModelStepRequest) throws -> Data {
    try canonicalEncoder().encode(request)
  }

  public static func encodeResponse(_ response: ModelStepResponse) throws -> Data {
    try canonicalEncoder().encode(response)
  }

  public static func encodeError(_ error: ModelStepErrorEnvelope) throws -> Data {
    try canonicalEncoder().encode(error)
  }

  static func inputSHA256(for request: ModelStepRequest) throws -> String {
    let digest = SHA256.hash(data: try encodeRequest(request))
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }

  private static func decodeProvider(_ raw: Any?) throws -> ModelProviderIdentity {
    guard let object = raw as? [String: Any] else {
      throw contractError("invalid_request", "provider должен быть объектом.")
    }
    try requireExactKeys(
      object,
      expected: ["kind", "id", "model", "runtime"],
      at: "provider"
    )
    let kind = try requireString(object["kind"], at: "provider.kind")
    let id = try requireString(object["id"], at: "provider.id")
    let model = try requireString(object["model"], at: "provider.model")
    let runtime = try requireString(object["runtime"], at: "provider.runtime")
    guard isTechnicalIdentifier(kind), isTechnicalIdentifier(id) else {
      throw contractError(
        "invalid_request", "kind и id провайдера должны быть техническими именами.")
    }
    guard !model.isEmpty, !runtime.isEmpty else {
      throw contractError("invalid_request", "Идентичность модели и runtime не должна быть пустой.")
    }
    guard model.unicodeScalars.count <= 256, runtime.unicodeScalars.count <= 256 else {
      throw contractError("invalid_request", "Идентичность модели или runtime слишком длинна.")
    }
    return ModelProviderIdentity(kind: kind, id: id, model: model, runtime: runtime)
  }

  private static func decodeMessages(_ raw: Any?) throws -> [ModelMessage] {
    guard let values = raw as? [Any], !values.isEmpty, values.count <= 128 else {
      throw contractError("invalid_request", "messages должен содержать от 1 до 128 сообщений.")
    }

    return try values.enumerated().map { index, value in
      guard let object = value as? [String: Any] else {
        throw contractError("invalid_request", "Каждое сообщение должно быть объектом.")
      }
      try requireExactKeys(object, expected: ["role", "content"], at: "messages[\(index)]")
      let roleValue = try requireString(object["role"], at: "messages[\(index)].role")
      guard let role = ModelMessage.Role(rawValue: roleValue) else {
        throw contractError("invalid_request", "Роль сообщения не поддерживается версией 1.")
      }
      let content = try requireString(object["content"], at: "messages[\(index)].content")
      guard !content.isEmpty else {
        throw contractError("invalid_request", "Содержимое сообщения не должно быть пустым.")
      }
      return ModelMessage(role: role, content: content)
    }
  }

  private static func decodeLimits(_ raw: Any?) throws -> ModelStepLimits {
    guard let object = raw as? [String: Any] else {
      throw contractError("invalid_request", "limits должен быть объектом.")
    }
    try requireExactKeys(
      object,
      expected: ["max_output_bytes", "timeout_milliseconds"],
      at: "limits"
    )
    let maxOutputBytes = try requireInteger(
      object["max_output_bytes"],
      at: "limits.max_output_bytes"
    )
    let timeoutMilliseconds = try requireInteger(
      object["timeout_milliseconds"],
      at: "limits.timeout_milliseconds"
    )
    guard (1...maximumOutputBytes).contains(maxOutputBytes) else {
      throw contractError(
        "invalid_request", "max_output_bytes находится вне допустимого диапазона.")
    }
    guard (1...maximumTimeoutMilliseconds).contains(timeoutMilliseconds) else {
      throw contractError(
        "invalid_request",
        "timeout_milliseconds находится вне допустимого диапазона."
      )
    }
    return ModelStepLimits(
      maxOutputBytes: maxOutputBytes,
      timeoutMilliseconds: timeoutMilliseconds
    )
  }

  private static func decodeCapabilities(_ raw: Any?) throws -> ModelStepCapabilities {
    guard let object = raw as? [String: Any] else {
      throw contractError("invalid_request", "capabilities должен быть объектом.")
    }
    try requireExactKeys(
      object,
      expected: ["tools", "files", "network"],
      at: "capabilities"
    )
    let tools = try requireBoolean(object["tools"], at: "capabilities.tools")
    let files = try requireBoolean(object["files"], at: "capabilities.files")
    let network = try requireBoolean(object["network"], at: "capabilities.network")
    guard !tools, !files, !network else {
      throw contractError(
        "capability_not_allowed",
        "Чистый модельный шаг не принимает инструменты, файлы или сеть."
      )
    }
    return ModelStepCapabilities(tools: tools, files: files, network: network)
  }

  private static func requireExactKeys(
    _ object: [String: Any],
    expected: Set<String>,
    at path: String
  ) throws {
    let actual = Set(object.keys)
    if !actual.subtracting(expected).isEmpty {
      throw contractError("unknown_field", "Объект \(path) содержит неизвестное поле.")
    }
    if let missing = expected.subtracting(actual).sorted().first {
      throw contractError("invalid_request", "Отсутствует поле \(path).\(missing).")
    }
  }

  private static func requireString(_ raw: Any?, at path: String) throws -> String {
    guard let value = raw as? String else {
      throw contractError("invalid_request", "Поле \(path) должно быть строкой.")
    }
    return value
  }

  private static func requireInteger(_ raw: Any?, at path: String) throws -> Int {
    guard let number = raw as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID(),
      number.doubleValue.rounded() == number.doubleValue
    else {
      throw contractError("invalid_request", "Поле \(path) должно быть целым числом.")
    }
    return number.intValue
  }

  private static func requireBoolean(_ raw: Any?, at path: String) throws -> Bool {
    guard let number = raw as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
      throw contractError("invalid_request", "Поле \(path) должно быть логическим значением.")
    }
    return number.boolValue
  }

  private static func isTechnicalIdentifier(_ value: String) -> Bool {
    value.range(
      of: "^[a-z0-9][a-z0-9._-]{0,127}$",
      options: .regularExpression
    ) != nil
  }

  private static func canonicalEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return encoder
  }

  private static func contractError(
    _ code: String,
    _ message: String,
    retryable: Bool = false
  ) -> ModelStepContractError {
    ModelStepContractError(code: code, message: message, retryable: retryable)
  }
}

public protocol ModelStepProvider: Sendable {
  var descriptor: ModelProviderIdentity { get }
  func complete(_ request: ModelStepRequest) throws -> ModelStepResponse
}

public struct DeterministicEchoProvider: ModelStepProvider {
  public let descriptor = ModelProviderIdentity(
    kind: "stub",
    id: "fum.deterministic-echo.v1",
    model: "deterministic-echo",
    runtime: "FUMPureModelStep/1"
  )

  public init() {}

  public func complete(_ request: ModelStepRequest) throws -> ModelStepResponse {
    guard request.provider == descriptor else {
      throw ModelStepContractError(
        code: "provider_mismatch",
        message: "Запрошенная идентичность провайдера не совпадает с загруженной.")
    }
    guard let content = request.messages.last(where: { $0.role == .user })?.content else {
      throw ModelStepContractError(
        code: "invalid_request",
        message: "Нужно хотя бы одно сообщение user."
      )
    }
    guard content.utf8.count <= request.limits.maxOutputBytes else {
      throw ModelStepContractError(
        code: "output_limit_exceeded",
        message: "Ответ заглушки превышает max_output_bytes."
      )
    }

    let inputBytes = request.messages.reduce(into: 0) { count, message in
      count += message.content.utf8.count
    }
    return ModelStepResponse(
      schemaVersion: 1,
      invocationID: request.invocationID,
      inputSHA256: try ModelStepJSON.inputSHA256(for: request),
      provider: descriptor,
      status: "completed",
      output: ModelStepOutput(content: content, finishReason: "stop"),
      metrics: ModelStepMetrics(inputBytes: inputBytes, outputBytes: content.utf8.count)
    )
  }
}
