import FUMLiveEpisodeCore
import Foundation

struct LiveRuntimeAnyCodingKey: CodingKey {
  let stringValue: String
  let intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  init?(intValue: Int) {
    stringValue = String(intValue)
    self.intValue = intValue
  }
}

func liveRuntimeRejectUnknownKeys<Key: CodingKey & CaseIterable>(
  _ decoder: Decoder,
  allowed _: Key.Type
) throws {
  let container = try decoder.container(keyedBy: LiveRuntimeAnyCodingKey.self)
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

public enum LiveEpisodeRuntimeSchema {
  public static let generationIdentity = "fum.live_single_agent_episode.generation"
  public static let generationVersion = 1
  public static let commandVersion = 1
  public static let reducerPolicy = "fum.live_single_agent_episode.reducer.v1"
  public static let maximumGenerationBytes = 16_777_216
}

public enum LiveEpisodeRuntimeError: Error, Equatable, Sendable {
  case unsupportedCommandSchema(expected: Int, actual: Int)
  case invalidCommand(String)
  case noConfirmedGeneration
  case incompatibleGeneration(String)
  case corruptGeneration(String)
  case generationConflict(expected: String?, actual: String?)
  case generationStore(String)
  case unresolvedModelInvocation(requestID: String)
  case invalidAdapterResult(String)
}

extension LiveEpisodeRuntimeError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unsupportedCommandSchema(let expected, let actual):
      return "Ожидалась версия команды \(expected), получена \(actual)."
    case .invalidCommand(let message), .incompatibleGeneration(let message),
      .corruptGeneration(let message), .generationStore(let message),
      .invalidAdapterResult(let message):
      return message
    case .noConfirmedGeneration:
      return "Подтверждённое поколение CURRENT не найдено."
    case .generationConflict(let expected, let actual):
      return
        "Конфликт поколения: ожидалось \(expected ?? "пустое состояние"), подтверждено \(actual ?? "пустое состояние")."
    case .unresolvedModelInvocation(let requestID):
      return "Model-only-вызов \(requestID) уже зарезервирован; автоматический повтор запрещён."
    }
  }
}

public struct LiveEpisodeEventJournal: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let episodeID: String
  public let events: [LiveEpisodeEvent]

  public init(
    schemaIdentity: String = LiveEpisodeSchema.identity,
    schemaVersion: Int = LiveEpisodeSchema.version,
    episodeID: String,
    events: [LiveEpisodeEvent]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.events = events
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case events
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    episodeID = try container.decode(String.self, forKey: .episodeID)
    events = try container.decode([LiveEpisodeEvent].self, forKey: .events)
  }
}

public struct LiveEpisodeInvocationReceipt: Codable, Equatable, Sendable {
  public let requestEventID: String
  public let responseEventID: String
  public let responseID: String
  public let budgetCheckpointEventID: String
  public let budgetCheckpointID: String
  public let proposal: LiveModelInvocationProposal
  public let commandSHA256: String

  public init(
    requestEventID: String,
    responseEventID: String,
    responseID: String,
    budgetCheckpointEventID: String,
    budgetCheckpointID: String,
    proposal: LiveModelInvocationProposal,
    commandSHA256: String
  ) {
    self.requestEventID = requestEventID
    self.responseEventID = responseEventID
    self.responseID = responseID
    self.budgetCheckpointEventID = budgetCheckpointEventID
    self.budgetCheckpointID = budgetCheckpointID
    self.proposal = proposal
    self.commandSHA256 = commandSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case requestEventID = "request_event_id"
    case responseEventID = "response_event_id"
    case responseID = "response_id"
    case budgetCheckpointEventID = "budget_checkpoint_event_id"
    case budgetCheckpointID = "budget_checkpoint_id"
    case proposal
    case commandSHA256 = "command_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requestEventID = try container.decode(String.self, forKey: .requestEventID)
    responseEventID = try container.decode(String.self, forKey: .responseEventID)
    responseID = try container.decode(String.self, forKey: .responseID)
    budgetCheckpointEventID = try container.decode(String.self, forKey: .budgetCheckpointEventID)
    budgetCheckpointID = try container.decode(String.self, forKey: .budgetCheckpointID)
    proposal = try container.decode(LiveModelInvocationProposal.self, forKey: .proposal)
    commandSHA256 = try container.decode(String.self, forKey: .commandSHA256)
  }
}

public struct LiveEpisodeInvocationReceiptJournal: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let episodeID: String
  public let invocations: [LiveEpisodeInvocationReceipt]

  public init(
    schemaIdentity: String = LiveEpisodeRuntimeSchema.generationIdentity,
    schemaVersion: Int = LiveEpisodeRuntimeSchema.generationVersion,
    episodeID: String,
    invocations: [LiveEpisodeInvocationReceipt]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.invocations = invocations
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case invocations
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    episodeID = try container.decode(String.self, forKey: .episodeID)
    invocations = try container.decode(
      [LiveEpisodeInvocationReceipt].self,
      forKey: .invocations
    )
  }
}

public struct LiveEpisodeGeneration: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let canonicalProfile: String
  public let reducerPolicy: String
  public let previousGenerationSHA256: String?
  public let passportSHA256: String
  public let eventJournalSHA256: String
  public let invocationReceiptJournalSHA256: String
  public let stateSHA256: String
  public let passport: LiveEpisodePassport
  public let eventJournal: LiveEpisodeEventJournal
  public let invocationReceiptJournal: LiveEpisodeInvocationReceiptJournal

  public init(
    schemaIdentity: String = LiveEpisodeRuntimeSchema.generationIdentity,
    schemaVersion: Int = LiveEpisodeRuntimeSchema.generationVersion,
    canonicalProfile: String,
    reducerPolicy: String = LiveEpisodeRuntimeSchema.reducerPolicy,
    previousGenerationSHA256: String?,
    passportSHA256: String,
    eventJournalSHA256: String,
    invocationReceiptJournalSHA256: String,
    stateSHA256: String,
    passport: LiveEpisodePassport,
    eventJournal: LiveEpisodeEventJournal,
    invocationReceiptJournal: LiveEpisodeInvocationReceiptJournal
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.canonicalProfile = canonicalProfile
    self.reducerPolicy = reducerPolicy
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.passportSHA256 = passportSHA256
    self.eventJournalSHA256 = eventJournalSHA256
    self.invocationReceiptJournalSHA256 = invocationReceiptJournalSHA256
    self.stateSHA256 = stateSHA256
    self.passport = passport
    self.eventJournal = eventJournal
    self.invocationReceiptJournal = invocationReceiptJournal
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case reducerPolicy = "reducer_policy"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case passportSHA256 = "passport_sha256"
    case eventJournalSHA256 = "event_journal_sha256"
    case invocationReceiptJournalSHA256 = "invocation_receipt_journal_sha256"
    case stateSHA256 = "state_sha256"
    case passport
    case eventJournal = "event_journal"
    case invocationReceiptJournal = "invocation_receipt_journal"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    canonicalProfile = try container.decode(String.self, forKey: .canonicalProfile)
    reducerPolicy = try container.decode(String.self, forKey: .reducerPolicy)
    previousGenerationSHA256 = try container.decodeIfPresent(
      String.self,
      forKey: .previousGenerationSHA256
    )
    passportSHA256 = try container.decode(String.self, forKey: .passportSHA256)
    eventJournalSHA256 = try container.decode(String.self, forKey: .eventJournalSHA256)
    invocationReceiptJournalSHA256 = try container.decode(
      String.self,
      forKey: .invocationReceiptJournalSHA256
    )
    stateSHA256 = try container.decode(String.self, forKey: .stateSHA256)
    passport = try container.decode(LiveEpisodePassport.self, forKey: .passport)
    eventJournal = try container.decode(LiveEpisodeEventJournal.self, forKey: .eventJournal)
    invocationReceiptJournal = try container.decode(
      LiveEpisodeInvocationReceiptJournal.self,
      forKey: .invocationReceiptJournal
    )
  }
}

public struct StoredLiveEpisodeGeneration: Codable, Equatable, Sendable {
  public let generationSHA256: String
  public let generation: LiveEpisodeGeneration
  public let state: LiveEpisodeState

  public init(
    generationSHA256: String,
    generation: LiveEpisodeGeneration,
    state: LiveEpisodeState
  ) {
    self.generationSHA256 = generationSHA256
    self.generation = generation
    self.state = state
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case generationSHA256 = "generation_sha256"
    case generation
    case state
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    generationSHA256 = try container.decode(String.self, forKey: .generationSHA256)
    generation = try container.decode(LiveEpisodeGeneration.self, forKey: .generation)
    state = try container.decode(LiveEpisodeState.self, forKey: .state)
  }
}

public struct LiveEpisodeModelAdapterRequest: Equatable, Sendable {
  public let invocationID: String
  public let input: String
  public let disclosureClass: LiveDisclosureClass
  public let purpose: String
  public let reservation: LiveBudget

  public init(
    invocationID: String,
    input: String,
    disclosureClass: LiveDisclosureClass,
    purpose: String,
    reservation: LiveBudget
  ) {
    self.invocationID = invocationID
    self.input = input
    self.disclosureClass = disclosureClass
    self.purpose = purpose
    self.reservation = reservation
  }
}

/// Публичный неизменяемый контракт model-only-adapter. Runtime сверяет его с
/// паспортом до durable reservation и любого provider-ввода-вывода.
public struct LiveEpisodeModelAdapterContract: Equatable, Sendable {
  public let profileID: String
  public let executionMode: LiveExecutionMode
  public let providerIdentity: LiveProviderIdentity
  public let disclosure: LiveDisclosurePolicy
  public let moneyUnit: LiveMoneyUnit
  public let maximumBudget: LiveBudget
  public let perInvocationReservation: LiveBudget
  public let maximumOutputTokens: Int64
  public let timeoutMilliseconds: Int64
  public let maximumComputeUnits: Int64

  public init(
    profileID: String,
    executionMode: LiveExecutionMode,
    providerIdentity: LiveProviderIdentity,
    disclosure: LiveDisclosurePolicy,
    moneyUnit: LiveMoneyUnit,
    maximumBudget: LiveBudget,
    perInvocationReservation: LiveBudget,
    maximumOutputTokens: Int64,
    timeoutMilliseconds: Int64,
    maximumComputeUnits: Int64
  ) {
    self.profileID = profileID
    self.executionMode = executionMode
    self.providerIdentity = providerIdentity
    self.disclosure = disclosure
    self.moneyUnit = moneyUnit
    self.maximumBudget = maximumBudget
    self.perInvocationReservation = perInvocationReservation
    self.maximumOutputTokens = maximumOutputTokens
    self.timeoutMilliseconds = timeoutMilliseconds
    self.maximumComputeUnits = maximumComputeUnits
  }

  public init(modelPolicy: LiveModelPolicy) {
    self.init(
      profileID: modelPolicy.profileID,
      executionMode: modelPolicy.executionMode,
      providerIdentity: modelPolicy.providerIdentity,
      disclosure: modelPolicy.disclosure,
      moneyUnit: modelPolicy.moneyUnit,
      maximumBudget: modelPolicy.maximumBudget,
      perInvocationReservation: modelPolicy.perInvocationReservation,
      maximumOutputTokens: modelPolicy.perInvocationReservation.outputTokens,
      timeoutMilliseconds: modelPolicy.perInvocationReservation.wallClockMilliseconds,
      maximumComputeUnits: modelPolicy.perInvocationReservation.computeUnits
    )
  }
}

public enum LiveEpisodeModelAdapterOutcome: Equatable, Sendable {
  case completed(output: String, charged: LiveBudget)
  case failed(output: String, charged: LiveBudget)
  case unknownUsage
  case invalidEvidence(String)
}

public struct LiveEpisodeModelAdapterResult: Equatable, Sendable {
  public let invocationID: String
  public let inputSHA256: String
  public let providerIdentity: LiveProviderIdentity
  public let outcome: LiveEpisodeModelAdapterOutcome

  public init(
    invocationID: String,
    inputSHA256: String,
    providerIdentity: LiveProviderIdentity,
    outcome: LiveEpisodeModelAdapterOutcome
  ) {
    self.invocationID = invocationID
    self.inputSHA256 = inputSHA256
    self.providerIdentity = providerIdentity
    self.outcome = outcome
  }
}

public protocol LiveEpisodeModelAdapter: Sendable {
  var contract: LiveEpisodeModelAdapterContract { get }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult
}

public struct LiveEpisodeUnavailableModelAdapter: LiveEpisodeModelAdapter {
  public let contract: LiveEpisodeModelAdapterContract

  public init(modelPolicy: LiveModelPolicy) {
    contract = LiveEpisodeModelAdapterContract(modelPolicy: modelPolicy)
  }

  public func complete(_ request: LiveEpisodeModelAdapterRequest) async
    -> LiveEpisodeModelAdapterResult
  {
    LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: .invalidEvidence(
        "Provider не подключён; unavailable-adapter не создаёт provider evidence."
      )
    )
  }
}

public struct LiveEpisodeCreateCommand: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let passport: LiveEpisodePassport
  public let initialEvents: [LiveEpisodeEvent]

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String,
    passport: LiveEpisodePassport,
    initialEvents: [LiveEpisodeEvent]
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.passport = passport
    self.initialEvents = initialEvents
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case passport
    case initialEvents = "initial_events"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    commandID = try container.decode(String.self, forKey: .commandID)
    passport = try container.decode(LiveEpisodePassport.self, forKey: .passport)
    initialEvents = try container.decode([LiveEpisodeEvent].self, forKey: .initialEvents)
  }
}

public struct LiveEpisodeInspectCommand: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    commandID = try container.decode(String.self, forKey: .commandID)
  }
}

public typealias LiveEpisodeStatusCommand = LiveEpisodeInspectCommand
public typealias LiveEpisodeReplayCommand = LiveEpisodeInspectCommand

public struct LiveEpisodeModelInvocationCommand: Codable, Equatable, Sendable {
  public let requestEventID: String
  public let responseEventID: String
  public let responseID: String
  public let budgetCheckpointEventID: String
  public let budgetCheckpointID: String
  public let proposal: LiveModelInvocationProposal
  public let input: String

  public init(
    requestEventID: String,
    responseEventID: String,
    responseID: String,
    budgetCheckpointEventID: String,
    budgetCheckpointID: String,
    proposal: LiveModelInvocationProposal,
    input: String
  ) {
    self.requestEventID = requestEventID
    self.responseEventID = responseEventID
    self.responseID = responseID
    self.budgetCheckpointEventID = budgetCheckpointEventID
    self.budgetCheckpointID = budgetCheckpointID
    self.proposal = proposal
    self.input = input
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case requestEventID = "request_event_id"
    case responseEventID = "response_event_id"
    case responseID = "response_id"
    case budgetCheckpointEventID = "budget_checkpoint_event_id"
    case budgetCheckpointID = "budget_checkpoint_id"
    case proposal
    case input
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requestEventID = try container.decode(String.self, forKey: .requestEventID)
    responseEventID = try container.decode(String.self, forKey: .responseEventID)
    responseID = try container.decode(String.self, forKey: .responseID)
    budgetCheckpointEventID = try container.decode(String.self, forKey: .budgetCheckpointEventID)
    budgetCheckpointID = try container.decode(String.self, forKey: .budgetCheckpointID)
    proposal = try container.decode(LiveModelInvocationProposal.self, forKey: .proposal)
    input = try container.decode(String.self, forKey: .input)
  }
}

public struct LiveEpisodeAppendEventsCommand: Codable, Equatable, Sendable {
  public let events: [LiveEpisodeEvent]

  public init(events: [LiveEpisodeEvent]) {
    self.events = events
  }

  enum CodingKeys: String, CodingKey, CaseIterable { case events }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    events = try container.decode([LiveEpisodeEvent].self, forKey: .events)
  }
}

public struct LiveEpisodeConfirmGenerationCommand: Codable, Equatable, Sendable {
  public let eventID: String

  public init(eventID: String) {
    self.eventID = eventID
  }

  enum CodingKeys: String, CodingKey, CaseIterable { case eventID = "event_id" }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    eventID = try container.decode(String.self, forKey: .eventID)
  }
}

public enum LiveEpisodeResumeAction: Codable, Equatable, Sendable {
  case appendEvents(LiveEpisodeAppendEventsCommand)
  case confirmGeneration(LiveEpisodeConfirmGenerationCommand)
  case invokeModel(LiveEpisodeModelInvocationCommand)

  enum Kind: String, Codable {
    case appendEvents = "append_events"
    case confirmGeneration = "confirm_generation"
    case invokeModel = "invoke_model"
  }
  enum CodingKeys: String, CodingKey, CaseIterable {
    case kind
    case payload
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .appendEvents:
      self = .appendEvents(
        try container.decode(LiveEpisodeAppendEventsCommand.self, forKey: .payload))
    case .confirmGeneration:
      self = .confirmGeneration(
        try container.decode(LiveEpisodeConfirmGenerationCommand.self, forKey: .payload))
    case .invokeModel:
      self = .invokeModel(
        try container.decode(LiveEpisodeModelInvocationCommand.self, forKey: .payload))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .appendEvents(let value):
      try container.encode(Kind.appendEvents, forKey: .kind)
      try container.encode(value, forKey: .payload)
    case .confirmGeneration(let value):
      try container.encode(Kind.confirmGeneration, forKey: .kind)
      try container.encode(value, forKey: .payload)
    case .invokeModel(let value):
      try container.encode(Kind.invokeModel, forKey: .kind)
      try container.encode(value, forKey: .payload)
    }
  }
}

public struct LiveEpisodeResumeCommand: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let expectedGenerationSHA256: String
  public let action: LiveEpisodeResumeAction

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String,
    expectedGenerationSHA256: String,
    action: LiveEpisodeResumeAction
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.expectedGenerationSHA256 = expectedGenerationSHA256
    self.action = action
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case expectedGenerationSHA256 = "expected_generation_sha256"
    case action
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    commandID = try container.decode(String.self, forKey: .commandID)
    expectedGenerationSHA256 = try container.decode(
      String.self,
      forKey: .expectedGenerationSHA256
    )
    action = try container.decode(LiveEpisodeResumeAction.self, forKey: .action)
  }
}

public enum LiveEpisodeCommandKind: String, Codable, Equatable, Sendable {
  case create
  case inspect
  case status
  case resume
  case replay
}

public enum LiveEpisodeMutationStatus: String, Codable, Equatable, Sendable {
  case created
  case advanced
  case checkpointed
  case alreadyApplied = "already_applied"
  case providerOutcomeUnresolved = "provider_outcome_unresolved"
}

public struct LiveEpisodeMutationOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let command: LiveEpisodeCommandKind
  public let status: LiveEpisodeMutationStatus
  public let generationSHA256: String
  public let stateSHA256: String
  public let state: LiveEpisodeState

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String,
    command: LiveEpisodeCommandKind,
    status: LiveEpisodeMutationStatus,
    generationSHA256: String,
    stateSHA256: String,
    state: LiveEpisodeState
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.command = command
    self.status = status
    self.generationSHA256 = generationSHA256
    self.stateSHA256 = stateSHA256
    self.state = state
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case command
    case status
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
    case state
  }
}

public struct LiveEpisodeInspectOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let command: LiveEpisodeCommandKind
  public let stored: StoredLiveEpisodeGeneration

  public init(commandID: String, stored: StoredLiveEpisodeGeneration) {
    schemaVersion = LiveEpisodeRuntimeSchema.commandVersion
    self.commandID = commandID
    command = .inspect
    self.stored = stored
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case command
    case stored
  }
}

public struct LiveEpisodeStatusOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let command: LiveEpisodeCommandKind
  public let generationSHA256: String
  public let stateSHA256: String
  public let episodeID: String
  public let nextSequence: Int64
  public let budget: LiveBudgetState
  public let pendingModelRequestIDs: [String]
  public let transitionPhase: String
  public let terminalOutcome: String

  public init(commandID: String, stored: StoredLiveEpisodeGeneration) {
    schemaVersion = LiveEpisodeRuntimeSchema.commandVersion
    self.commandID = commandID
    command = .status
    generationSHA256 = stored.generationSHA256
    stateSHA256 = stored.generation.stateSHA256
    episodeID = stored.state.passport.episodeID
    nextSequence = stored.state.nextSequence
    budget = stored.state.model.budget
    pendingModelRequestIDs = stored.state.model.variants.compactMap {
      $0.response == nil ? $0.proposal.requestID : nil
    }
    transitionPhase = stored.state.transition?.phase.rawValue ?? "none"
    terminalOutcome = stored.state.continuation?.continuation.decision.rawValue ?? "none"
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case command
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
    case episodeID = "episode_id"
    case nextSequence = "next_sequence"
    case budget
    case pendingModelRequestIDs = "pending_model_request_ids"
    case transitionPhase = "transition_phase"
    case terminalOutcome = "terminal_outcome"
  }
}

public struct LiveEpisodeReplayOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let command: LiveEpisodeCommandKind
  public let generationSHA256: String
  public let stateSHA256: String
  public let state: LiveEpisodeState

  public init(commandID: String, stored: StoredLiveEpisodeGeneration) {
    schemaVersion = LiveEpisodeRuntimeSchema.commandVersion
    self.commandID = commandID
    command = .replay
    generationSHA256 = stored.generationSHA256
    stateSHA256 = stored.generation.stateSHA256
    state = stored.state
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case command
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
    case state
  }
}

public struct LiveEpisodeErrorOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let status: String
  public let code: String
  public let message: String

  public init(code: String, message: String) {
    schemaVersion = LiveEpisodeRuntimeSchema.commandVersion
    status = "failed"
    self.code = code
    self.message = message
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case status
    case code
    case message
  }
}
