import CryptoKit
import Foundation

private struct ModelOnlyAnyCodingKey: CodingKey {
  let stringValue: String
  let intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init?(intValue: Int) {
    self.stringValue = String(intValue)
    self.intValue = intValue
  }
}

private func rejectUnknownKeys<Key: CodingKey & CaseIterable>(
  _ decoder: Decoder,
  allowed _: Key.Type
) throws {
  let container = try decoder.container(keyedBy: ModelOnlyAnyCodingKey.self)
  let allowedKeys = Set(Key.allCases.map(\.stringValue))
  let unknownKeys = container.allKeys.map(\.stringValue).filter { !allowedKeys.contains($0) }
  guard unknownKeys.isEmpty else {
    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Неизвестные поля: \(unknownKeys.sorted().joined(separator: ", "))."
      )
    )
  }
}

public enum ModelOnlyExecutionMode: String, Codable, Equatable, Sendable {
  case local
  case remote
}

public enum ModelOnlyDisclosureClass: String, Codable, Equatable, Sendable {
  case synthetic
  case projectPublic = "project_public"
  case userData = "user_data"
  case secret
}

public enum ModelOnlyBudgetDurability: String, Codable, Equatable, Sendable {
  case processMemory = "process_memory"
}

public enum ModelOnlyComputeUnit: String, Codable, Equatable, Sendable {
  case wallClockMillisecond = "wall_clock_millisecond"
}

public enum ModelOnlyMoneyUnit: String, Codable, Equatable, Sendable {
  case none
  case usdMicrounit = "usd_microunit"
}

public struct ModelOnlyRuntimeIdentity: Codable, Equatable, Sendable {
  public let name: String
  public let version: String

  public init(name: String, version: String) {
    self.name = name
    self.version = version
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case name
    case version
  }

  public init(from decoder: Decoder) throws {
    try rejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    version = try container.decode(String.self, forKey: .version)
  }
}

public struct ModelOnlyDisclosurePolicy: Codable, Equatable, Sendable {
  public let allowedClasses: [ModelOnlyDisclosureClass]
  public let maxInputBytes: Int64
  public let allowedPurposes: [String]

  public init(
    allowedClasses: [ModelOnlyDisclosureClass],
    maxInputBytes: Int64,
    allowedPurposes: [String]
  ) {
    self.allowedClasses = allowedClasses
    self.maxInputBytes = maxInputBytes
    self.allowedPurposes = allowedPurposes
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case allowedClasses = "allowed_classes"
    case maxInputBytes = "max_input_bytes"
    case allowedPurposes = "allowed_purposes"
  }

  public init(from decoder: Decoder) throws {
    try rejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    allowedClasses = try container.decode([ModelOnlyDisclosureClass].self, forKey: .allowedClasses)
    maxInputBytes = try container.decode(Int64.self, forKey: .maxInputBytes)
    allowedPurposes = try container.decode([String].self, forKey: .allowedPurposes)
  }
}

public struct ModelOnlyBudget: Codable, Equatable, Sendable {
  public let calls: Int64
  public let inputTokens: Int64
  public let outputTokens: Int64
  public let wallClockMilliseconds: Int64
  public let computeUnits: Int64
  public let moneyMicrounits: Int64

  public init(
    calls: Int64,
    inputTokens: Int64,
    outputTokens: Int64,
    wallClockMilliseconds: Int64,
    computeUnits: Int64,
    moneyMicrounits: Int64
  ) {
    self.calls = calls
    self.inputTokens = inputTokens
    self.outputTokens = outputTokens
    self.wallClockMilliseconds = wallClockMilliseconds
    self.computeUnits = computeUnits
    self.moneyMicrounits = moneyMicrounits
  }

  public static let zero = ModelOnlyBudget(
    calls: 0,
    inputTokens: 0,
    outputTokens: 0,
    wallClockMilliseconds: 0,
    computeUnits: 0,
    moneyMicrounits: 0
  )

  enum CodingKeys: String, CodingKey, CaseIterable {
    case calls
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case wallClockMilliseconds = "wall_clock_milliseconds"
    case computeUnits = "compute_units"
    case moneyMicrounits = "money_microunits"
  }

  public init(from decoder: Decoder) throws {
    try rejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    calls = try container.decode(Int64.self, forKey: .calls)
    inputTokens = try container.decode(Int64.self, forKey: .inputTokens)
    outputTokens = try container.decode(Int64.self, forKey: .outputTokens)
    wallClockMilliseconds = try container.decode(Int64.self, forKey: .wallClockMilliseconds)
    computeUnits = try container.decode(Int64.self, forKey: .computeUnits)
    moneyMicrounits = try container.decode(Int64.self, forKey: .moneyMicrounits)
  }

  fileprivate var values: [Int64] {
    [calls, inputTokens, outputTokens, wallClockMilliseconds, computeUnits, moneyMicrounits]
  }

  fileprivate var hasNegativeValue: Bool {
    values.contains { $0 < 0 }
  }

  fileprivate func isComponentwiseLessThanOrEqual(to other: ModelOnlyBudget) -> Bool {
    zip(values, other.values).allSatisfy { $0 <= $1 }
  }

  fileprivate func checkedAdding(_ other: ModelOnlyBudget) throws -> ModelOnlyBudget {
    let calls = try Self.checkedAdd(calls, other.calls)
    let inputTokens = try Self.checkedAdd(inputTokens, other.inputTokens)
    let outputTokens = try Self.checkedAdd(outputTokens, other.outputTokens)
    let wallClockMilliseconds = try Self.checkedAdd(
      wallClockMilliseconds,
      other.wallClockMilliseconds
    )
    let computeUnits = try Self.checkedAdd(computeUnits, other.computeUnits)
    let moneyMicrounits = try Self.checkedAdd(moneyMicrounits, other.moneyMicrounits)
    return ModelOnlyBudget(
      calls: calls,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      wallClockMilliseconds: wallClockMilliseconds,
      computeUnits: computeUnits,
      moneyMicrounits: moneyMicrounits
    )
  }

  fileprivate func checkedSubtracting(_ other: ModelOnlyBudget) throws -> ModelOnlyBudget {
    let calls = try Self.checkedSubtract(calls, other.calls)
    let inputTokens = try Self.checkedSubtract(inputTokens, other.inputTokens)
    let outputTokens = try Self.checkedSubtract(outputTokens, other.outputTokens)
    let wallClockMilliseconds = try Self.checkedSubtract(
      wallClockMilliseconds,
      other.wallClockMilliseconds
    )
    let computeUnits = try Self.checkedSubtract(computeUnits, other.computeUnits)
    let moneyMicrounits = try Self.checkedSubtract(moneyMicrounits, other.moneyMicrounits)
    return ModelOnlyBudget(
      calls: calls,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      wallClockMilliseconds: wallClockMilliseconds,
      computeUnits: computeUnits,
      moneyMicrounits: moneyMicrounits
    )
  }

  private static func checkedAdd(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
    let (value, overflow) = lhs.addingReportingOverflow(rhs)
    guard !overflow else { throw ModelOnlyBudgetArithmeticError.overflow }
    return value
  }

  private static func checkedSubtract(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
    let (value, overflow) = lhs.subtractingReportingOverflow(rhs)
    guard !overflow else { throw ModelOnlyBudgetArithmeticError.overflow }
    return value
  }
}

public struct ModelOnlyBudgetProfile: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let profileID: String
  public let executionMode: ModelOnlyExecutionMode
  public let providerIdentity: String
  public let providerInterfaceID: String
  public let endpoint: String
  public let modelIdentity: String
  public let runtimeIdentity: ModelOnlyRuntimeIdentity
  public let tokenizerIdentity: String
  public let tokenizationMethod: ModelOnlyTokenizationMethod
  public let computeUnit: ModelOnlyComputeUnit
  public let moneyUnit: ModelOnlyMoneyUnit
  public let disclosure: ModelOnlyDisclosurePolicy
  public let maximumBudget: ModelOnlyBudget
  public let perInvocationReservation: ModelOnlyBudget
  public let maxOutputTokens: Int64
  public let durability: ModelOnlyBudgetDurability

  public init(
    schemaVersion: Int,
    profileID: String,
    executionMode: ModelOnlyExecutionMode,
    providerIdentity: String,
    providerInterfaceID: String,
    endpoint: String,
    modelIdentity: String,
    runtimeIdentity: ModelOnlyRuntimeIdentity,
    tokenizerIdentity: String,
    tokenizationMethod: ModelOnlyTokenizationMethod,
    computeUnit: ModelOnlyComputeUnit,
    moneyUnit: ModelOnlyMoneyUnit,
    disclosure: ModelOnlyDisclosurePolicy,
    maximumBudget: ModelOnlyBudget,
    perInvocationReservation: ModelOnlyBudget,
    maxOutputTokens: Int64,
    durability: ModelOnlyBudgetDurability
  ) {
    self.schemaVersion = schemaVersion
    self.profileID = profileID
    self.executionMode = executionMode
    self.providerIdentity = providerIdentity
    self.providerInterfaceID = providerInterfaceID
    self.endpoint = endpoint
    self.modelIdentity = modelIdentity
    self.runtimeIdentity = runtimeIdentity
    self.tokenizerIdentity = tokenizerIdentity
    self.tokenizationMethod = tokenizationMethod
    self.computeUnit = computeUnit
    self.moneyUnit = moneyUnit
    self.disclosure = disclosure
    self.maximumBudget = maximumBudget
    self.perInvocationReservation = perInvocationReservation
    self.maxOutputTokens = maxOutputTokens
    self.durability = durability
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case profileID = "profile_id"
    case executionMode = "execution_mode"
    case providerIdentity = "provider_identity"
    case providerInterfaceID = "provider_interface_id"
    case endpoint
    case modelIdentity = "model_identity"
    case runtimeIdentity = "runtime_identity"
    case tokenizerIdentity = "tokenizer_identity"
    case tokenizationMethod = "tokenization_method"
    case computeUnit = "compute_unit"
    case moneyUnit = "money_unit"
    case disclosure
    case maximumBudget = "maximum_budget"
    case perInvocationReservation = "per_invocation_reservation"
    case maxOutputTokens = "max_output_tokens"
    case durability
  }

  public init(from decoder: Decoder) throws {
    try rejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    profileID = try container.decode(String.self, forKey: .profileID)
    executionMode = try container.decode(ModelOnlyExecutionMode.self, forKey: .executionMode)
    providerIdentity = try container.decode(String.self, forKey: .providerIdentity)
    providerInterfaceID = try container.decode(String.self, forKey: .providerInterfaceID)
    endpoint = try container.decode(String.self, forKey: .endpoint)
    modelIdentity = try container.decode(String.self, forKey: .modelIdentity)
    runtimeIdentity = try container.decode(ModelOnlyRuntimeIdentity.self, forKey: .runtimeIdentity)
    tokenizerIdentity = try container.decode(String.self, forKey: .tokenizerIdentity)
    tokenizationMethod = try container.decode(
      ModelOnlyTokenizationMethod.self, forKey: .tokenizationMethod)
    computeUnit = try container.decode(ModelOnlyComputeUnit.self, forKey: .computeUnit)
    moneyUnit = try container.decode(ModelOnlyMoneyUnit.self, forKey: .moneyUnit)
    disclosure = try container.decode(ModelOnlyDisclosurePolicy.self, forKey: .disclosure)
    maximumBudget = try container.decode(ModelOnlyBudget.self, forKey: .maximumBudget)
    perInvocationReservation = try container.decode(
      ModelOnlyBudget.self,
      forKey: .perInvocationReservation
    )
    maxOutputTokens = try container.decode(Int64.self, forKey: .maxOutputTokens)
    durability = try container.decode(ModelOnlyBudgetDurability.self, forKey: .durability)
  }
}

public struct BudgetedModelOnlyInvocation: Codable, Equatable, Sendable {
  public let invocationID: String
  public let input: String
  public let disclosureClass: ModelOnlyDisclosureClass
  public let purpose: String

  public init(
    invocationID: String,
    input: String,
    disclosureClass: ModelOnlyDisclosureClass,
    purpose: String
  ) {
    self.invocationID = invocationID
    self.input = input
    self.disclosureClass = disclosureClass
    self.purpose = purpose
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case invocationID = "invocation_id"
    case input
    case disclosureClass = "disclosure_class"
    case purpose
  }

  public init(from decoder: Decoder) throws {
    try rejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    invocationID = try container.decode(String.self, forKey: .invocationID)
    input = try container.decode(String.self, forKey: .input)
    disclosureClass = try container.decode(ModelOnlyDisclosureClass.self, forKey: .disclosureClass)
    purpose = try container.decode(String.self, forKey: .purpose)
  }
}

public enum ProviderUsageSource: String, Codable, Equatable, Sendable {
  case structuredProviderResponse = "structured_provider_response"
}

public struct ProviderTokenUsage: Codable, Equatable, Sendable {
  public let inputTokens: Int64
  public let outputTokens: Int64
  public let totalTokens: Int64
  public let source: ProviderUsageSource

  public init(
    inputTokens: Int64,
    outputTokens: Int64,
    totalTokens: Int64,
    source: ProviderUsageSource = .structuredProviderResponse
  ) {
    self.inputTokens = inputTokens
    self.outputTokens = outputTokens
    self.totalTokens = totalTokens
    self.source = source
  }

  enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case totalTokens = "total_tokens"
    case source
  }
}

public enum ModelOnlyTokenizationMethod: String, Codable, Equatable, Sendable {
  case exact
  case conservativeUpperBound = "conservative_upper_bound"
}

public struct ModelOnlyTokenizationEvidence: Codable, Equatable, Sendable {
  public let tokenizerIdentity: String
  public let method: ModelOnlyTokenizationMethod
  public let inputSHA256: String
  public let inputTokens: Int64

  public init(
    tokenizerIdentity: String,
    method: ModelOnlyTokenizationMethod,
    inputSHA256: String,
    inputTokens: Int64
  ) {
    self.tokenizerIdentity = tokenizerIdentity
    self.method = method
    self.inputSHA256 = inputSHA256
    self.inputTokens = inputTokens
  }

  enum CodingKeys: String, CodingKey {
    case tokenizerIdentity = "tokenizer_identity"
    case method
    case inputSHA256 = "input_sha256"
    case inputTokens = "input_tokens"
  }
}

protocol ModelOnlyInputTokenizing: Sendable {
  var identity: String { get }
  var method: ModelOnlyTokenizationMethod { get }

  func countInputTokens(_ input: String, profile: ModelOnlyBudgetProfile) async throws -> Int64
}

protocol ModelOnlyMonotonicClock: Sendable {
  func nowMilliseconds() -> UInt64
}

struct SystemModelOnlyMonotonicClock: ModelOnlyMonotonicClock {
  func nowMilliseconds() -> UInt64 {
    DispatchTime.now().uptimeNanoseconds / 1_000_000
  }
}

extension ModelOnlyInputTokenizing {
  var method: ModelOnlyTokenizationMethod { .exact }
}

struct ModelOnlyProviderCapability: Codable, Equatable, Sendable {
  let executionMode: ModelOnlyExecutionMode
  let providerIdentity: String
  let providerInterfaceID: String
  let endpoint: String
  let tokenizerIdentity: String
  let maxOutputTokenField: String?
  let trustedUsageSource: ProviderUsageSource?
}

struct ModelOnlyProviderRequest: Codable, Equatable, Sendable {
  let invocationID: String
  let input: String
  let modelIdentity: String
  let maxOutputTokens: Int64
  let maxOutputTokenField: String
  let timeoutMilliseconds: Int64
}

struct ModelOnlyProviderResponse: Codable, Equatable, Sendable {
  let responseID: String
  let modelIdentity: String
  let runtimeIdentity: ModelOnlyRuntimeIdentity
  let text: String
  let finishReason: String
  let usage: ProviderTokenUsage?
  let elapsedMilliseconds: Int64
  let responseBodySHA256: String
}

enum ModelOnlyProviderTransportOutcome: Equatable, Sendable {
  case completed(ModelOnlyProviderResponse)
  case timedOut
  case partialResponse
  case invalidResponse
  case arithmeticOverflow
  case responseTooLarge
  case failed
}

protocol ModelOnlyBudgetTransport: Sendable {
  var capability: ModelOnlyProviderCapability { get }

  func generate(_ request: ModelOnlyProviderRequest) async -> ModelOnlyProviderTransportOutcome
}

public enum BudgetedModelOnlyAttemptStatus: String, Codable, Equatable, Sendable {
  case completed
  case failed
}

public enum ModelOnlyBudgetFailureCode: String, Codable, Equatable, Sendable {
  case invalidProfile = "invalid_profile"
  case disclosureDenied = "disclosure_denied"
  case providerIdentityMismatch = "provider_identity_mismatch"
  case tokenizerIdentityMismatch = "tokenizer_identity_mismatch"
  case tokenizerFailed = "tokenizer_failed"
  case inputTokenLimitExceeded = "input_token_limit_exceeded"
  case unsupportedOutputTokenLimit = "unsupported_output_token_limit"
  case budgetInsufficient = "budget_insufficient"
  case negativeBudgetValue = "negative_budget_value"
  case budgetArithmeticOverflow = "budget_arithmetic_overflow"
  case budgetCountersInconsistent = "budget_counters_inconsistent"
  case invocationInProgress = "invocation_in_progress"
  case invocationConflict = "invocation_conflict"
  case providerTimedOut = "provider_timed_out"
  case providerPartialResponse = "provider_partial_response"
  case providerResponseTooLarge = "provider_response_too_large"
  case providerUsageMissing = "provider_usage_missing"
  case providerUsageInconsistent = "provider_usage_inconsistent"
  case providerFailed = "provider_failed"
}

public struct ModelOnlyBudgetFailure: Error, Codable, Equatable, Sendable {
  public let code: ModelOnlyBudgetFailureCode
  public let message: String
  public let retryable: Bool

  public init(code: ModelOnlyBudgetFailureCode, message: String, retryable: Bool = false) {
    self.code = code
    self.message = message
    self.retryable = retryable
  }
}

public struct ModelOnlyBudgetReservation: Codable, Equatable, Sendable {
  public let ledgerInstanceID: String
  public let durability: ModelOnlyBudgetDurability
  public let invocationID: String
  public let maximum: ModelOnlyBudget

  public init(
    ledgerInstanceID: String,
    durability: ModelOnlyBudgetDurability,
    invocationID: String,
    maximum: ModelOnlyBudget
  ) {
    self.ledgerInstanceID = ledgerInstanceID
    self.durability = durability
    self.invocationID = invocationID
    self.maximum = maximum
  }
}

public enum ModelOnlyBudgetSettlementKind: String, Codable, Equatable, Sendable {
  case reconciledWithMeasuredLocalCompute = "reconciled_with_measured_local_compute"
  case releasedWithMeasuredPreProviderCompute = "released_with_measured_pre_provider_compute"
  case conservativeFullReservation = "conservative_full_reservation"
}

public struct ModelOnlyBudgetSettlement: Codable, Equatable, Sendable {
  public let kind: ModelOnlyBudgetSettlementKind
  public let reservedMaximum: ModelOnlyBudget
  public let charged: ModelOnlyBudget

  public init(
    kind: ModelOnlyBudgetSettlementKind,
    reservedMaximum: ModelOnlyBudget,
    charged: ModelOnlyBudget
  ) {
    self.kind = kind
    self.reservedMaximum = reservedMaximum
    self.charged = charged
  }
}

public struct ModelOnlyBudgetSnapshot: Codable, Equatable, Sendable {
  public let maximum: ModelOnlyBudget
  public let reserved: ModelOnlyBudget
  public let charged: ModelOnlyBudget

  public init(
    maximum: ModelOnlyBudget,
    reserved: ModelOnlyBudget = .zero,
    charged: ModelOnlyBudget = .zero
  ) {
    self.maximum = maximum
    self.reserved = reserved
    self.charged = charged
  }
}

public struct BudgetedModelOnlyAttempt: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let profileID: String
  public let invocationID: String
  public let requestSHA256: String?
  public let status: BudgetedModelOnlyAttemptStatus
  public let output: String?
  public let providerUsage: ProviderTokenUsage?
  public let tokenization: ModelOnlyTokenizationEvidence?
  public let reservation: ModelOnlyBudgetReservation?
  public let settlement: ModelOnlyBudgetSettlement?
  public let failure: ModelOnlyBudgetFailure?
  public let providerResponseID: String?
  public let providerModelIdentity: String?
  public let providerRuntimeIdentity: ModelOnlyRuntimeIdentity?
  public let providerFinishReason: String?
  public let providerResponseSHA256: String?

  public init(
    schemaVersion: Int = 2,
    profileID: String,
    invocationID: String,
    requestSHA256: String?,
    status: BudgetedModelOnlyAttemptStatus,
    output: String?,
    providerUsage: ProviderTokenUsage?,
    tokenization: ModelOnlyTokenizationEvidence?,
    reservation: ModelOnlyBudgetReservation?,
    settlement: ModelOnlyBudgetSettlement?,
    failure: ModelOnlyBudgetFailure?,
    providerResponseID: String? = nil,
    providerModelIdentity: String? = nil,
    providerRuntimeIdentity: ModelOnlyRuntimeIdentity? = nil,
    providerFinishReason: String? = nil,
    providerResponseSHA256: String? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.profileID = profileID
    self.invocationID = invocationID
    self.requestSHA256 = requestSHA256
    self.status = status
    self.output = output
    self.providerUsage = providerUsage
    self.tokenization = tokenization
    self.reservation = reservation
    self.settlement = settlement
    self.failure = failure
    self.providerResponseID = providerResponseID
    self.providerModelIdentity = providerModelIdentity
    self.providerRuntimeIdentity = providerRuntimeIdentity
    self.providerFinishReason = providerFinishReason
    self.providerResponseSHA256 = providerResponseSHA256
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case profileID = "profile_id"
    case invocationID = "invocation_id"
    case requestSHA256 = "request_sha256"
    case status
    case output
    case providerUsage = "provider_usage"
    case tokenization
    case reservation
    case settlement
    case failure
    case providerResponseID = "provider_response_id"
    case providerModelIdentity = "provider_model_identity"
    case providerRuntimeIdentity = "provider_runtime_identity"
    case providerFinishReason = "provider_finish_reason"
    case providerResponseSHA256 = "provider_response_sha256"
  }
}

private enum ModelOnlyBudgetArithmeticError: Error {
  case overflow
}

private struct ModelOnlyActiveReservation: Sendable {
  let requestSHA256: String
  let maximum: ModelOnlyBudget
}

private struct ModelOnlyTerminalEntry: Sendable {
  let requestSHA256: String
  let attempt: BudgetedModelOnlyAttempt
}

private enum ModelOnlyLedgerLookupOutcome: Sendable {
  case absent
  case replay(BudgetedModelOnlyAttempt)
  case failed(ModelOnlyBudgetFailureCode)
}

private enum ModelOnlyLedgerBeginOutcome: Sendable {
  case reserved(ModelOnlyBudgetReservation)
  case replay(BudgetedModelOnlyAttempt)
  case terminal(BudgetedModelOnlyAttempt)
  case failed(ModelOnlyBudgetFailureCode)
}

private enum ModelOnlyLedgerTerminalOutcome: Sendable {
  case recorded(BudgetedModelOnlyAttempt)
  case replay(BudgetedModelOnlyAttempt)
  case failed(ModelOnlyBudgetFailureCode)
}

extension BudgetedModelOnlyAttempt {
  fileprivate func replacingSettlement(
    _ replacement: ModelOnlyBudgetSettlement
  ) -> BudgetedModelOnlyAttempt {
    BudgetedModelOnlyAttempt(
      schemaVersion: schemaVersion,
      profileID: profileID,
      invocationID: invocationID,
      requestSHA256: requestSHA256,
      status: status,
      output: output,
      providerUsage: providerUsage,
      tokenization: tokenization,
      reservation: reservation,
      settlement: replacement,
      failure: failure,
      providerResponseID: providerResponseID,
      providerModelIdentity: providerModelIdentity,
      providerRuntimeIdentity: providerRuntimeIdentity,
      providerFinishReason: providerFinishReason,
      providerResponseSHA256: providerResponseSHA256
    )
  }
}

public actor VolatileModelBudgetLedger {
  public nonisolated let instanceID: String
  public nonisolated let durability: ModelOnlyBudgetDurability = .processMemory

  private let maximum: ModelOnlyBudget
  private var reserved: ModelOnlyBudget
  private var charged: ModelOnlyBudget
  private var activeReservations: [String: ModelOnlyActiveReservation] = [:]
  private var terminalEntries: [String: ModelOnlyTerminalEntry] = [:]

  public init(
    maximum: ModelOnlyBudget,
    initialCharged: ModelOnlyBudget = .zero,
    initialReserved: ModelOnlyBudget = .zero,
    instanceID: String = UUID().uuidString.lowercased()
  ) {
    self.instanceID = instanceID
    self.maximum = maximum
    self.reserved = initialReserved
    self.charged = initialCharged
  }

  public func snapshot() -> ModelOnlyBudgetSnapshot {
    ModelOnlyBudgetSnapshot(maximum: maximum, reserved: reserved, charged: charged)
  }

  fileprivate func lookup(
    invocationID: String,
    requestSHA256: String
  ) -> ModelOnlyLedgerLookupOutcome {
    if let terminal = terminalEntries[invocationID] {
      return terminal.requestSHA256 == requestSHA256
        ? .replay(terminal.attempt) : .failed(.invocationConflict)
    }
    if let active = activeReservations[invocationID] {
      return .failed(
        active.requestSHA256 == requestSHA256 ? .invocationInProgress : .invocationConflict
      )
    }
    return .absent
  }

  fileprivate func recordUnreservedTerminal(
    _ attempt: BudgetedModelOnlyAttempt
  ) -> ModelOnlyLedgerTerminalOutcome {
    guard let requestSHA256 = attempt.requestSHA256 else {
      return .failed(.budgetCountersInconsistent)
    }
    switch lookup(invocationID: attempt.invocationID, requestSHA256: requestSHA256) {
    case .replay(let existing):
      return .replay(existing)
    case .failed(let code):
      return .failed(code)
    case .absent:
      terminalEntries[attempt.invocationID] = ModelOnlyTerminalEntry(
        requestSHA256: requestSHA256,
        attempt: attempt
      )
      return .recorded(attempt)
    }
  }

  fileprivate func begin(
    profileID: String,
    invocationID: String,
    requestSHA256: String,
    expectedMaximum: ModelOnlyBudget,
    reservation amount: ModelOnlyBudget
  ) -> ModelOnlyLedgerBeginOutcome {
    switch lookup(invocationID: invocationID, requestSHA256: requestSHA256) {
    case .replay(let existing):
      return .replay(existing)
    case .failed(let code):
      return .failed(code)
    case .absent:
      break
    }
    guard expectedMaximum == maximum else {
      return recordBeginFailure(
        profileID: profileID,
        invocationID: invocationID,
        requestSHA256: requestSHA256,
        code: .budgetCountersInconsistent
      )
    }
    if maximum.hasNegativeValue || reserved.hasNegativeValue || charged.hasNegativeValue
      || amount.hasNegativeValue
    {
      return recordBeginFailure(
        profileID: profileID,
        invocationID: invocationID,
        requestSHA256: requestSHA256,
        code: .negativeBudgetValue
      )
    }
    let used: ModelOnlyBudget
    let available: ModelOnlyBudget
    let newReserved: ModelOnlyBudget
    do {
      used = try charged.checkedAdding(reserved)
      guard used.isComponentwiseLessThanOrEqual(to: maximum) else {
        return recordBeginFailure(
          profileID: profileID,
          invocationID: invocationID,
          requestSHA256: requestSHA256,
          code: .budgetCountersInconsistent
        )
      }
      available = try maximum.checkedSubtracting(used)
      guard amount.isComponentwiseLessThanOrEqual(to: available) else {
        return recordBeginFailure(
          profileID: profileID,
          invocationID: invocationID,
          requestSHA256: requestSHA256,
          code: .budgetInsufficient
        )
      }
      newReserved = try reserved.checkedAdding(amount)
    } catch {
      return recordBeginFailure(
        profileID: profileID,
        invocationID: invocationID,
        requestSHA256: requestSHA256,
        code: .budgetArithmeticOverflow
      )
    }
    reserved = newReserved
    activeReservations[invocationID] = ModelOnlyActiveReservation(
      requestSHA256: requestSHA256,
      maximum: amount
    )
    return .reserved(
      ModelOnlyBudgetReservation(
        ledgerInstanceID: instanceID,
        durability: durability,
        invocationID: invocationID,
        maximum: amount
      )
    )
  }

  private func recordBeginFailure(
    profileID: String,
    invocationID: String,
    requestSHA256: String,
    code: ModelOnlyBudgetFailureCode
  ) -> ModelOnlyLedgerBeginOutcome {
    let attempt = BudgetedModelOnlyAttempt(
      profileID: profileID,
      invocationID: invocationID,
      requestSHA256: requestSHA256,
      status: .failed,
      output: nil,
      providerUsage: nil,
      tokenization: nil,
      reservation: nil,
      settlement: nil,
      failure: ModelOnlyBudgetFailure(
        code: code,
        message: "Ledger атомарно отклонил affordability следующего reservation."
      )
    )
    terminalEntries[invocationID] = ModelOnlyTerminalEntry(
      requestSHA256: requestSHA256,
      attempt: attempt
    )
    return .terminal(attempt)
  }

  fileprivate func finish(
    _ attempt: BudgetedModelOnlyAttempt,
    charged actual: ModelOnlyBudget,
    kind: ModelOnlyBudgetSettlementKind
  ) -> ModelOnlyLedgerTerminalOutcome {
    guard let requestSHA256 = attempt.requestSHA256 else {
      return .failed(.budgetCountersInconsistent)
    }
    if let terminal = terminalEntries[attempt.invocationID] {
      return terminal.requestSHA256 == requestSHA256
        ? .replay(terminal.attempt) : .failed(.invocationConflict)
    }
    guard let active = activeReservations[attempt.invocationID] else {
      return .failed(.budgetCountersInconsistent)
    }
    guard active.requestSHA256 == requestSHA256 else {
      return .failed(.invocationConflict)
    }
    guard !actual.hasNegativeValue else { return .failed(.negativeBudgetValue) }
    guard actual.isComponentwiseLessThanOrEqual(to: active.maximum) else {
      return .failed(.budgetCountersInconsistent)
    }
    let newReserved: ModelOnlyBudget
    let newCharged: ModelOnlyBudget
    do {
      newReserved = try reserved.checkedSubtracting(active.maximum)
      newCharged = try charged.checkedAdding(actual)
      let newUsed = try newCharged.checkedAdding(newReserved)
      guard !newReserved.hasNegativeValue,
        newUsed.isComponentwiseLessThanOrEqual(to: maximum)
      else {
        return .failed(.budgetCountersInconsistent)
      }
    } catch {
      return .failed(.budgetArithmeticOverflow)
    }
    let settlement = ModelOnlyBudgetSettlement(
      kind: kind,
      reservedMaximum: active.maximum,
      charged: actual
    )
    let terminalAttempt = attempt.replacingSettlement(settlement)
    reserved = newReserved
    charged = newCharged
    activeReservations.removeValue(forKey: attempt.invocationID)
    terminalEntries[attempt.invocationID] = ModelOnlyTerminalEntry(
      requestSHA256: requestSHA256,
      attempt: terminalAttempt
    )
    return .recorded(terminalAttempt)
  }
}

public actor BudgetedModelOnlyAdapter {
  public let profile: ModelOnlyBudgetProfile

  private static let absoluteInternalPrehashInputBytes: Int64 = 1_048_576
  private static let profileMetadataBytes: Int64 = 4_096
  private static let invocationMetadataBytes: Int64 = 1_024
  private static let maximumAllowedClasses = 16
  private static let maximumAllowedPurposes = 64

  private let tokenizer: any ModelOnlyInputTokenizing
  private let transport: any ModelOnlyBudgetTransport
  private let ledger: VolatileModelBudgetLedger
  private let clock: any ModelOnlyMonotonicClock
  private let prehashInputByteLimit: Int64

  public init(
    profile: ModelOnlyBudgetProfile,
    tokenizer: PinnedModelOnlyExactTokenization,
    transport: LMStudioRESTV0BudgetTransport,
    ledger: VolatileModelBudgetLedger? = nil
  ) {
    self.profile = profile
    self.tokenizer = tokenizer
    self.transport = transport
    self.ledger = ledger ?? VolatileModelBudgetLedger(maximum: profile.maximumBudget)
    self.clock = SystemModelOnlyMonotonicClock()
    self.prehashInputByteLimit = min(
      max(profile.disclosure.maxInputBytes, 0),
      max(tokenizer.inputBytes, 0)
    )
  }

  init(
    profile: ModelOnlyBudgetProfile,
    tokenizer: any ModelOnlyInputTokenizing,
    transport: any ModelOnlyBudgetTransport,
    ledger: VolatileModelBudgetLedger? = nil,
    clock: any ModelOnlyMonotonicClock = SystemModelOnlyMonotonicClock()
  ) {
    self.profile = profile
    self.tokenizer = tokenizer
    self.transport = transport
    self.ledger = ledger ?? VolatileModelBudgetLedger(maximum: profile.maximumBudget)
    self.clock = clock
    self.prehashInputByteLimit = min(
      max(profile.disclosure.maxInputBytes, 0),
      Self.absoluteInternalPrehashInputBytes
    )
  }

  public func budgetSnapshot() async -> ModelOnlyBudgetSnapshot {
    await ledger.snapshot()
  }

  public func complete(_ invocation: BudgetedModelOnlyInvocation) async -> BudgetedModelOnlyAttempt
  {
    if let failure = validatePrehashProfileBounds() {
      return prehashFailureAttempt(
        invocation: invocation,
        code: failure,
        message: "Профиль превышает абсолютные пределы prehash-метаданных."
      )
    }
    if let failure = validateProfile() {
      return prehashFailureAttempt(
        invocation: invocation,
        code: failure,
        message: "Бюджетный model-only-профиль не прошёл строгую проверку."
      )
    }
    if let failure = validatePrehashInvocationBounds(invocation) {
      return prehashFailureAttempt(
        invocation: invocation,
        code: failure,
        message: "Вход отклонён ограниченной проверкой до сериализации и хэширования."
      )
    }
    let requestSHA256 = Self.requestSHA256(profile: profile, invocation: invocation)
    switch await ledger.lookup(
      invocationID: invocation.invocationID,
      requestSHA256: requestSHA256
    ) {
    case .replay(let existing):
      return existing
    case .failed(let code):
      return failureAttempt(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: code,
        message: Self.invocationStateMessage(code)
      )
    case .absent:
      break
    }

    if let failure = validateDisclosure(invocation) {
      return await recordUnreservedFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: failure,
        message: "Раскрытие данных не разрешено независимым профилем."
      )
    }
    if let failure = validateCapabilities() {
      return await recordUnreservedFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: failure,
        message: "Provider-интерфейс не подтверждает требуемую исполнимую capability."
      )
    }

    let reservationOutcome = await ledger.begin(
      profileID: profile.profileID,
      invocationID: invocation.invocationID,
      requestSHA256: requestSHA256,
      expectedMaximum: profile.maximumBudget,
      reservation: profile.perInvocationReservation
    )
    let reservation: ModelOnlyBudgetReservation
    switch reservationOutcome {
    case .reserved(let value):
      reservation = value
    case .replay(let existing):
      return existing
    case .terminal(let attempt):
      return attempt
    case .failed(let code):
      return failureAttempt(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: code,
        message: Self.invocationStateMessage(code)
      )
    }

    let tokenizationStarted = clock.nowMilliseconds()
    let inputTokens: Int64
    do {
      inputTokens = try await tokenizer.countInputTokens(
        invocation.input,
        profile: profile
      )
    } catch let failure as ModelOnlyBudgetFailure {
      return await preProviderFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenizationStarted: tokenizationStarted,
        code: failure.code,
        message: failure.message
      )
    } catch {
      return await preProviderFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenizationStarted: tokenizationStarted,
        code: .tokenizerFailed,
        message: "Provider-compatible tokenizer завершился отказом."
      )
    }
    guard
      let tokenizationElapsed = Self.elapsedMilliseconds(
        since: tokenizationStarted,
        now: clock.nowMilliseconds()
      )
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: nil,
        code: .budgetArithmeticOverflow,
        message: "Измерение времени предварительной токенизации переполнено."
      )
    }
    guard inputTokens >= 0 else {
      return await preProviderFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenizationElapsed: tokenizationElapsed,
        code: .negativeBudgetValue,
        message: "Tokenizer вернул отрицательный счётчик."
      )
    }
    guard inputTokens <= reservation.maximum.inputTokens else {
      return await preProviderFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenizationElapsed: tokenizationElapsed,
        code: .inputTokenLimitExceeded,
        message: "Предварительная токенизация превышает зарезервированный вход."
      )
    }

    let tokenization = ModelOnlyTokenizationEvidence(
      tokenizerIdentity: tokenizer.identity,
      method: tokenizer.method,
      inputSHA256: Self.sha256(Data(invocation.input.utf8)),
      inputTokens: inputTokens
    )
    let generationLimit = min(
      reservation.maximum.wallClockMilliseconds,
      reservation.maximum.computeUnits
    )
    guard tokenizationElapsed < generationLimit else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerTimedOut,
        message: "Предварительная токенизация исчерпала общий временной бюджет."
      )
    }
    let providerRequest = ModelOnlyProviderRequest(
      invocationID: invocation.invocationID,
      input: invocation.input,
      modelIdentity: profile.modelIdentity,
      maxOutputTokens: profile.maxOutputTokens,
      maxOutputTokenField: "max_tokens",
      timeoutMilliseconds: generationLimit - tokenizationElapsed
    )
    let outcome = await transport.generate(providerRequest)
    guard
      let measuredTotalElapsed = Self.elapsedMilliseconds(
        since: tokenizationStarted,
        now: clock.nowMilliseconds()
      )
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .budgetArithmeticOverflow,
        message: "Общее монотонное измерение времени переполнено."
      )
    }
    guard measuredTotalElapsed <= generationLimit else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerTimedOut,
        message: "Transport завершился после общего временного предела."
      )
    }

    switch outcome {
    case .timedOut:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerTimedOut,
        message: "Provider превысил оставшееся абсолютное время reservation."
      )
    case .partialResponse:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerPartialResponse,
        message: "Получен частичный provider-ответ без доверенного завершения."
      )
    case .invalidResponse:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerUsageInconsistent,
        message: "Provider вернул полный, но malformed или несовместимый JSON-ответ."
      )
    case .arithmeticOverflow:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .budgetArithmeticOverflow,
        message: "Числовое поле provider-ответа выходит за диапазон Int64."
      )
    case .responseTooLarge:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerResponseTooLarge,
        message: "Provider-ответ превысил независимый байтовый предел."
      )
    case .failed:
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerFailed,
        message: "Provider завершил вызов типизированным отказом."
      )
    case .completed(let response):
      return await completeProviderResponse(
        response,
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        tokenizationElapsed: tokenizationElapsed,
        measuredTotalElapsed: measuredTotalElapsed
      )
    }
  }

  private func validateProfile() -> ModelOnlyBudgetFailureCode? {
    guard profile.schemaVersion == 2,
      profile.executionMode == .local,
      !profile.profileID.isEmpty,
      !profile.providerIdentity.isEmpty,
      !profile.providerInterfaceID.isEmpty,
      !profile.endpoint.isEmpty,
      !profile.modelIdentity.isEmpty,
      !profile.runtimeIdentity.name.isEmpty,
      !profile.runtimeIdentity.version.isEmpty,
      !profile.tokenizerIdentity.isEmpty,
      profile.tokenizationMethod == .exact,
      profile.computeUnit == .wallClockMillisecond,
      !profile.disclosure.allowedClasses.isEmpty,
      !profile.disclosure.allowedPurposes.isEmpty,
      profile.disclosure.maxInputBytes >= 0,
      profile.maxOutputTokens > 0,
      profile.perInvocationReservation.outputTokens == profile.maxOutputTokens,
      profile.perInvocationReservation.calls == 1,
      profile.perInvocationReservation.wallClockMilliseconds > 0,
      profile.perInvocationReservation.computeUnits > 0,
      profile.durability == .processMemory,
      Self.endpointMatchesExecutionMode(profile)
    else {
      return .invalidProfile
    }
    guard !profile.maximumBudget.hasNegativeValue,
      !profile.perInvocationReservation.hasNegativeValue
    else {
      return .negativeBudgetValue
    }
    guard
      profile.perInvocationReservation.isComponentwiseLessThanOrEqual(
        to: profile.maximumBudget
      )
    else {
      return .budgetInsufficient
    }
    if profile.executionMode == .local {
      guard profile.moneyUnit == .none,
        profile.maximumBudget.moneyMicrounits == 0,
        profile.perInvocationReservation.moneyMicrounits == 0
      else {
        return .invalidProfile
      }
    }
    return nil
  }

  private func validatePrehashProfileBounds() -> ModelOnlyBudgetFailureCode? {
    let boundedMetadata = [
      profile.profileID,
      profile.providerIdentity,
      profile.providerInterfaceID,
      profile.endpoint,
      profile.modelIdentity,
      profile.runtimeIdentity.name,
      profile.runtimeIdentity.version,
      profile.tokenizerIdentity,
    ].allSatisfy {
      Self.hasAtMostUTF8Bytes($0, limit: Self.profileMetadataBytes)
    }
    guard boundedMetadata,
      profile.disclosure.allowedClasses.count <= Self.maximumAllowedClasses,
      profile.disclosure.allowedPurposes.count <= Self.maximumAllowedPurposes,
      profile.disclosure.allowedPurposes.allSatisfy({
        Self.hasAtMostUTF8Bytes($0, limit: Self.invocationMetadataBytes)
      }),
      profile.disclosure.maxInputBytes >= 0,
      profile.disclosure.maxInputBytes <= Self.absoluteInternalPrehashInputBytes
    else {
      return .invalidProfile
    }
    return nil
  }

  private func validatePrehashInvocationBounds(
    _ invocation: BudgetedModelOnlyInvocation
  ) -> ModelOnlyBudgetFailureCode? {
    guard
      Self.hasAtMostUTF8Bytes(
        invocation.invocationID,
        limit: Self.invocationMetadataBytes
      ),
      Self.hasAtMostUTF8Bytes(invocation.purpose, limit: Self.invocationMetadataBytes),
      Self.hasAtMostUTF8Bytes(invocation.input, limit: prehashInputByteLimit)
    else {
      return .disclosureDenied
    }
    return nil
  }

  private static func endpointMatchesExecutionMode(_ profile: ModelOnlyBudgetProfile) -> Bool {
    guard
      let components = URLComponents(string: profile.endpoint),
      components.user == nil,
      components.password == nil,
      components.query == nil,
      components.fragment == nil,
      let host = components.host,
      !host.isEmpty
    else {
      return false
    }
    switch profile.executionMode {
    case .local:
      return components.scheme == "http"
        && (host == "127.0.0.1" || host == "::1")
        && components.port != nil
    case .remote:
      return components.scheme == "https"
    }
  }

  private func validateDisclosure(
    _ invocation: BudgetedModelOnlyInvocation
  ) -> ModelOnlyBudgetFailureCode? {
    guard !invocation.invocationID.isEmpty,
      profile.disclosure.allowedClasses.contains(invocation.disclosureClass),
      profile.disclosure.allowedPurposes.contains(invocation.purpose),
      Int64(invocation.input.utf8.count) <= profile.disclosure.maxInputBytes
    else {
      return .disclosureDenied
    }
    return nil
  }

  private func validateCapabilities() -> ModelOnlyBudgetFailureCode? {
    let capability = transport.capability
    guard capability.maxOutputTokenField == "max_tokens",
      capability.trustedUsageSource == .structuredProviderResponse
    else {
      return .unsupportedOutputTokenLimit
    }
    guard capability.executionMode == profile.executionMode,
      capability.providerIdentity == profile.providerIdentity,
      capability.providerInterfaceID == profile.providerInterfaceID,
      capability.endpoint == profile.endpoint
    else {
      return .providerIdentityMismatch
    }
    guard capability.tokenizerIdentity == profile.tokenizerIdentity,
      tokenizer.identity == profile.tokenizerIdentity,
      tokenizer.method == profile.tokenizationMethod
    else {
      return .tokenizerIdentityMismatch
    }
    return nil
  }

  private func completeProviderResponse(
    _ response: ModelOnlyProviderResponse,
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String,
    reservation: ModelOnlyBudgetReservation,
    tokenization: ModelOnlyTokenizationEvidence,
    tokenizationElapsed: Int64,
    measuredTotalElapsed: Int64
  ) async -> BudgetedModelOnlyAttempt {
    guard response.modelIdentity == profile.modelIdentity,
      response.runtimeIdentity == profile.runtimeIdentity
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerIdentityMismatch,
        message: "Ответ пришёл от другой модели или runtime."
      )
    }
    guard let usage = response.usage else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerUsageMissing,
        message: "В provider-ответе отсутствует доверенное usage."
      )
    }
    guard usage.inputTokens >= 0, usage.outputTokens >= 0, usage.totalTokens >= 0,
      response.elapsedMilliseconds >= 0
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .negativeBudgetValue,
        message: "Provider вернул отрицательный счётчик."
      )
    }
    let summedTokens: Int64
    do {
      summedTokens = try ModelOnlyBudget(
        calls: 0,
        inputTokens: usage.inputTokens,
        outputTokens: 0,
        wallClockMilliseconds: 0,
        computeUnits: 0,
        moneyMicrounits: 0
      ).checkedAdding(
        ModelOnlyBudget(
          calls: 0,
          inputTokens: usage.outputTokens,
          outputTokens: 0,
          wallClockMilliseconds: 0,
          computeUnits: 0,
          moneyMicrounits: 0
        )
      ).inputTokens
    } catch {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .budgetArithmeticOverflow,
        message: "Сумма provider-счётчиков переполнена."
      )
    }
    guard usage.totalTokens == summedTokens,
      tokenization.method == .exact,
      usage.inputTokens == tokenization.inputTokens,
      usage.outputTokens <= profile.maxOutputTokens
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerUsageInconsistent,
        message: "Provider usage не согласуется с токенизацией или исполнимым пределом."
      )
    }

    let (reportedTotalElapsed, elapsedOverflow) = tokenizationElapsed.addingReportingOverflow(
      response.elapsedMilliseconds
    )
    guard !elapsedOverflow else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .budgetArithmeticOverflow,
        message: "Общее измеренное время переполнено."
      )
    }
    let totalElapsed = max(measuredTotalElapsed, reportedTotalElapsed)
    let generationLimit = min(
      reservation.maximum.wallClockMilliseconds,
      reservation.maximum.computeUnits
    )
    guard totalElapsed <= generationLimit else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerTimedOut,
        message: "Provider-ответ получен после общего временного предела."
      )
    }
    guard Self.isSHA256(response.responseBodySHA256) else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerUsageInconsistent,
        message: "Provider-ответ не содержит хэш точных полученных байтов."
      )
    }

    let charged = ModelOnlyBudget(
      calls: 1,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      wallClockMilliseconds: totalElapsed,
      computeUnits: totalElapsed,
      moneyMicrounits: 0
    )
    guard charged.isComponentwiseLessThanOrEqual(to: reservation.maximum) else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: .providerUsageInconsistent,
        message: "Подтверждённое usage превышает сохранённый reservation."
      )
    }
    let draft = BudgetedModelOnlyAttempt(
      profileID: profile.profileID,
      invocationID: invocation.invocationID,
      requestSHA256: requestSHA256,
      status: .completed,
      output: response.text,
      providerUsage: usage,
      tokenization: tokenization,
      reservation: reservation,
      settlement: nil,
      failure: nil,
      providerResponseID: response.responseID,
      providerModelIdentity: response.modelIdentity,
      providerRuntimeIdentity: response.runtimeIdentity,
      providerFinishReason: response.finishReason,
      providerResponseSHA256: response.responseBodySHA256
    )
    let settlementOutcome = await ledger.finish(
      draft,
      charged: charged,
      kind: .reconciledWithMeasuredLocalCompute
    )
    switch settlementOutcome {
    case .recorded(let attempt), .replay(let attempt):
      return attempt
    case .failed(let code):
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: tokenization,
        code: code,
        message: "Ledger не смог атомарно согласовать provider usage."
      )
    }
  }

  private func conservativeFailure(
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String,
    reservation: ModelOnlyBudgetReservation,
    tokenization: ModelOnlyTokenizationEvidence?,
    code: ModelOnlyBudgetFailureCode,
    message: String
  ) async -> BudgetedModelOnlyAttempt {
    let draft = failureAttempt(
      invocation: invocation,
      requestSHA256: requestSHA256,
      code: code,
      message: message,
      tokenization: tokenization,
      reservation: reservation
    )
    let settlementOutcome = await ledger.finish(
      draft,
      charged: reservation.maximum,
      kind: .conservativeFullReservation
    )
    switch settlementOutcome {
    case .recorded(let attempt), .replay(let attempt):
      return attempt
    case .failed(let ledgerCode):
      return failureAttempt(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: ledgerCode,
        message: "Ledger не смог сохранить консервативный терминальный исход.",
        tokenization: tokenization,
        reservation: reservation
      )
    }
  }

  private func preProviderFailure(
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String,
    reservation: ModelOnlyBudgetReservation,
    tokenizationStarted: UInt64,
    code: ModelOnlyBudgetFailureCode,
    message: String
  ) async -> BudgetedModelOnlyAttempt {
    guard
      let elapsed = Self.elapsedMilliseconds(
        since: tokenizationStarted,
        now: clock.nowMilliseconds()
      )
    else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: nil,
        code: .budgetArithmeticOverflow,
        message: "Измерение времени предварительного отказа переполнено."
      )
    }
    return await preProviderFailure(
      invocation: invocation,
      requestSHA256: requestSHA256,
      reservation: reservation,
      tokenizationElapsed: elapsed,
      code: code,
      message: message
    )
  }

  private func preProviderFailure(
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String,
    reservation: ModelOnlyBudgetReservation,
    tokenizationElapsed: Int64,
    code: ModelOnlyBudgetFailureCode,
    message: String
  ) async -> BudgetedModelOnlyAttempt {
    let charged = ModelOnlyBudget(
      calls: 0,
      inputTokens: 0,
      outputTokens: 0,
      wallClockMilliseconds: tokenizationElapsed,
      computeUnits: tokenizationElapsed,
      moneyMicrounits: 0
    )
    guard charged.isComponentwiseLessThanOrEqual(to: reservation.maximum) else {
      return await conservativeFailure(
        invocation: invocation,
        requestSHA256: requestSHA256,
        reservation: reservation,
        tokenization: nil,
        code: .providerTimedOut,
        message: "Предварительная обработка исчерпала reservation."
      )
    }
    let draft = failureAttempt(
      invocation: invocation,
      requestSHA256: requestSHA256,
      code: code,
      message: message,
      reservation: reservation
    )
    switch await ledger.finish(
      draft,
      charged: charged,
      kind: .releasedWithMeasuredPreProviderCompute
    ) {
    case .recorded(let attempt), .replay(let attempt):
      return attempt
    case .failed(let ledgerCode):
      return failureAttempt(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: ledgerCode,
        message: "Ledger не смог сохранить предварительный терминальный исход.",
        reservation: reservation
      )
    }
  }

  private func recordUnreservedFailure(
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String,
    code: ModelOnlyBudgetFailureCode,
    message: String
  ) async -> BudgetedModelOnlyAttempt {
    let draft = failureAttempt(
      invocation: invocation,
      requestSHA256: requestSHA256,
      code: code,
      message: message
    )
    switch await ledger.recordUnreservedTerminal(draft) {
    case .recorded(let attempt), .replay(let attempt):
      return attempt
    case .failed(let ledgerCode):
      return failureAttempt(
        invocation: invocation,
        requestSHA256: requestSHA256,
        code: ledgerCode,
        message: Self.invocationStateMessage(ledgerCode)
      )
    }
  }

  private func failureAttempt(
    invocation: BudgetedModelOnlyInvocation,
    requestSHA256: String?,
    code: ModelOnlyBudgetFailureCode,
    message: String,
    tokenization: ModelOnlyTokenizationEvidence? = nil,
    reservation: ModelOnlyBudgetReservation? = nil,
    settlement: ModelOnlyBudgetSettlement? = nil
  ) -> BudgetedModelOnlyAttempt {
    BudgetedModelOnlyAttempt(
      profileID: profile.profileID,
      invocationID: invocation.invocationID,
      requestSHA256: requestSHA256,
      status: .failed,
      output: nil,
      providerUsage: nil,
      tokenization: tokenization,
      reservation: reservation,
      settlement: settlement,
      failure: ModelOnlyBudgetFailure(code: code, message: message)
    )
  }

  private func prehashFailureAttempt(
    invocation: BudgetedModelOnlyInvocation,
    code: ModelOnlyBudgetFailureCode,
    message: String
  ) -> BudgetedModelOnlyAttempt {
    let safeProfileID =
      Self.hasAtMostUTF8Bytes(
        profile.profileID,
        limit: Self.profileMetadataBytes
      ) ? profile.profileID : "invalid-profile"
    let safeInvocationID =
      Self.hasAtMostUTF8Bytes(
        invocation.invocationID,
        limit: Self.invocationMetadataBytes
      ) ? invocation.invocationID : "invalid-invocation"
    return BudgetedModelOnlyAttempt(
      profileID: safeProfileID,
      invocationID: safeInvocationID,
      requestSHA256: nil,
      status: .failed,
      output: nil,
      providerUsage: nil,
      tokenization: nil,
      reservation: nil,
      settlement: nil,
      failure: ModelOnlyBudgetFailure(code: code, message: message)
    )
  }

  private static func invocationStateMessage(_ code: ModelOnlyBudgetFailureCode) -> String {
    code == .invocationInProgress
      ? "Вызов с тем же входом уже имеет активный reservation."
      : "Идентификатор вызова уже связан с другим входом или профилем."
  }

  private static func elapsedMilliseconds(since started: UInt64, now: UInt64) -> Int64? {
    guard now >= started else { return nil }
    let elapsed = now - started
    guard elapsed <= UInt64(Int64.max) else { return nil }
    return Int64(elapsed)
  }

  private static func isSHA256(_ value: String) -> Bool {
    guard value.hasPrefix("sha256:") else { return false }
    let digest = value.dropFirst("sha256:".count)
    return digest.count == 64 && digest.allSatisfy { $0.isHexDigit }
  }

  fileprivate static func hasAtMostUTF8Bytes(_ value: String, limit: Int64) -> Bool {
    guard limit >= 0 else { return false }
    var remaining = limit
    for _ in value.utf8 {
      guard remaining > 0 else { return false }
      remaining -= 1
    }
    return true
  }

  private static func requestSHA256(
    profile: ModelOnlyBudgetProfile,
    invocation: BudgetedModelOnlyInvocation
  ) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let profileData = (try? encoder.encode(profile)) ?? Data()
    let invocationData = (try? encoder.encode(invocation)) ?? Data()
    var data = Data()
    data.append(profileData)
    data.append(0)
    data.append(invocationData)
    return sha256(data)
  }

  fileprivate static func sha256(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

public struct PinnedModelOnlyExactTokenization: ModelOnlyInputTokenizing {
  private struct InputAttestation: Sendable {
    let inputSHA256: String
    let inputBytes: Int64
    let inputTokens: Int64
  }

  public static let lmStudioQwen3SmallFixtureV1 = PinnedModelOnlyExactTokenization(
    identity: "lmstudio.rest-v0.qwen3-0.6b.prompt-attestation.v1",
    providerIdentity: "lmstudio",
    providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
    endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
    modelIdentity: "qwen/qwen3-0.6b",
    runtimeIdentity: ModelOnlyRuntimeIdentity(
      name: "llama.cpp-mac-arm64-apple-metal-advsimd",
      version: "2.27.1"
    ),
    inputSHA256: "sha256:3b4f065553a72298c43e428be7ac80976181ac641c95bf4c588253fb2c6a203f",
    inputBytes: 27,
    inputTokens: 14
  )

  public static let lmStudioQwen3LiveEpisodeV1 = PinnedModelOnlyExactTokenization(
    identity: "lmstudio.rest-v0.qwen3-0.6b.live-episode-attestation.v1",
    providerIdentity: "lmstudio",
    providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
    endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
    modelIdentity: "qwen/qwen3-0.6b",
    runtimeIdentity: ModelOnlyRuntimeIdentity(
      name: "llama.cpp-mac-arm64-apple-metal-advsimd",
      version: "2.27.1"
    ),
    inputAttestations: [
      InputAttestation(
        inputSHA256: "sha256:0ee3d9bd4a4553bdc542c52a8d47b6d08bd672cb1a364877d2bea11cc0795864",
        inputBytes: 467,
        inputTokens: 219
      ),
      InputAttestation(
        inputSHA256: "sha256:5301ee0fef1db1216ea01a1e0a673fe6fe5932185ff4ad1b747e7e14a912bdcb",
        inputBytes: 467,
        inputTokens: 214
      ),
    ]
  )

  public let identity: String
  public let providerIdentity: String
  public let providerInterfaceID: String
  public let endpoint: String
  public let modelIdentity: String
  public let runtimeIdentity: ModelOnlyRuntimeIdentity
  public let inputSHA256: String
  public let inputBytes: Int64
  public let inputTokens: Int64
  public let method: ModelOnlyTokenizationMethod = .exact
  private let inputAttestations: [InputAttestation]

  public var inputAttestationCount: Int { inputAttestations.count }

  init(
    identity: String,
    providerIdentity: String,
    providerInterfaceID: String,
    endpoint: String,
    modelIdentity: String,
    runtimeIdentity: ModelOnlyRuntimeIdentity,
    inputSHA256: String,
    inputBytes: Int64,
    inputTokens: Int64
  ) {
    let inputAttestation = InputAttestation(
      inputSHA256: inputSHA256,
      inputBytes: inputBytes,
      inputTokens: inputTokens
    )
    self.init(
      identity: identity,
      providerIdentity: providerIdentity,
      providerInterfaceID: providerInterfaceID,
      endpoint: endpoint,
      modelIdentity: modelIdentity,
      runtimeIdentity: runtimeIdentity,
      inputAttestations: [inputAttestation]
    )
  }

  private init(
    identity: String,
    providerIdentity: String,
    providerInterfaceID: String,
    endpoint: String,
    modelIdentity: String,
    runtimeIdentity: ModelOnlyRuntimeIdentity,
    inputAttestations: [InputAttestation]
  ) {
    precondition(!inputAttestations.isEmpty)
    let primaryInput = inputAttestations[0]
    self.identity = identity
    self.providerIdentity = providerIdentity
    self.providerInterfaceID = providerInterfaceID
    self.endpoint = endpoint
    self.modelIdentity = modelIdentity
    self.runtimeIdentity = runtimeIdentity
    inputSHA256 = primaryInput.inputSHA256
    inputBytes = primaryInput.inputBytes
    inputTokens = primaryInput.inputTokens
    self.inputAttestations = inputAttestations
  }

  public func countInputTokens(_ input: String, profile: ModelOnlyBudgetProfile) async throws
    -> Int64
  {
    let maximumInputBytes = inputAttestations.map(\.inputBytes).max() ?? -1
    guard profile.tokenizerIdentity == identity,
      profile.tokenizationMethod == method,
      profile.providerIdentity == providerIdentity,
      profile.providerInterfaceID == providerInterfaceID,
      profile.endpoint == endpoint,
      profile.modelIdentity == modelIdentity,
      profile.runtimeIdentity == runtimeIdentity,
      BudgetedModelOnlyAdapter.hasAtMostUTF8Bytes(input, limit: maximumInputBytes)
    else {
      throw ModelOnlyBudgetFailure(
        code: .tokenizerIdentityMismatch,
        message: "Точная токенизационная аттестация не закреплена за этим входом и моделью."
      )
    }
    let inputData = Data(input.utf8)
    let inputSHA256 = BudgetedModelOnlyAdapter.sha256(inputData)
    guard
      let inputAttestation = inputAttestations.first(where: {
        $0.inputBytes == Int64(inputData.count)
          && $0.inputTokens >= 0
          && $0.inputSHA256 == inputSHA256
      })
    else {
      throw ModelOnlyBudgetFailure(
        code: .tokenizerIdentityMismatch,
        message: "Точная токенизационная аттестация не закреплена за этим входом и моделью."
      )
    }
    return inputAttestation.inputTokens
  }
}
