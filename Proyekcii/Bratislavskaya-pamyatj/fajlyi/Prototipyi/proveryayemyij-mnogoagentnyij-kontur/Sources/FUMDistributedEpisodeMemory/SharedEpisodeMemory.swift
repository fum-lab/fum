import FUMReproducibleMemoryPopulation
import FUMVerifiableMultiAgentContour
import Foundation

public protocol SharedEpisodeCanonicalValue: Codable, Sendable {}

extension SharedEpisodeCanonicalValue {
  public func canonicalJSONData() throws -> Data {
    try CanonicalMemoryJSON.encode(self)
  }
}

public enum SharedEpisodeMemoryError: Error, Equatable, Sendable {
  case invalidSeed(String)
  case invalidContribution(String)
  case invalidVerification(String)
  case invalidSelection(String)
  case invalidControl(String)
  case budgetLimitExceeded(SharedEpisodeBudgetDimension)
  case protectedReserveRequired
  case settlementExceedsReservation
  case invalidTerminal(String)
  case terminalEpisode
  case invalidResumption(String)
  case incompatibleGeneration(String)
  case corruptGeneration(String)
  case generationConflict(expected: String?, actual: String?)
  case generationStore(String)
}

extension SharedEpisodeMemoryError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidSeed(let message):
      return "Недопустимый seed общей памяти: \(message)"
    case .invalidContribution(let message):
      return "Недопустимый вклад общей памяти: \(message)"
    case .invalidVerification(let message):
      return "Недопустимая проверка общей памяти: \(message)"
    case .invalidSelection(let message):
      return "Недопустимое решение выбора: \(message)"
    case .invalidControl(let message):
      return "Недопустимое событие управления эпизодом: \(message)"
    case .budgetLimitExceeded(let dimension):
      return "Лимит бюджета исчерпан по размерности \(dimension.rawValue)."
    case .protectedReserveRequired:
      return "Действие пытается расходовать защищённый резерв проверки или передачи."
    case .settlementExceedsReservation:
      return "Фактический расход превышает предварительную резервацию."
    case .invalidTerminal(let message):
      return "Недопустимый терминальный исход: \(message)"
    case .terminalEpisode:
      return "Текущее поколение эпизода уже терминально и не принимает новые события."
    case .invalidResumption(let message):
      return "Недопустимое возобновление эпизода: \(message)"
    case .incompatibleGeneration(let message):
      return "Несовместимое поколение общей памяти: \(message)"
    case .corruptGeneration(let message):
      return "Повреждённое поколение общей памяти: \(message)"
    case .generationConflict(let expected, let actual):
      return
        "Конфликт поколения общей памяти: ожидалось \(expected ?? "пустое состояние"), подтверждено \(actual ?? "пустое состояние")."
    case .generationStore(let message):
      return "Ошибка хранилища общей памяти: \(message)"
    }
  }
}

public struct SharedEpisodeEmbeddedArtifact:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let artifactID: String
  public let kind: String
  public let logicalPath: String
  public let mediaType: String
  public let contentBase64: String
  public let contentSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case artifactID = "artifact_id"
    case kind
    case logicalPath = "logical_path"
    case mediaType = "media_type"
    case contentBase64 = "content_base64"
    case contentSHA256 = "content_sha256"
  }

  public init(
    schemaVersion: Int = 1,
    artifactID: String,
    kind: String,
    logicalPath: String,
    mediaType: String,
    contentBase64: String,
    contentSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.artifactID = artifactID
    self.kind = kind
    self.logicalPath = logicalPath
    self.mediaType = mediaType
    self.contentBase64 = contentBase64
    self.contentSHA256 = contentSHA256
  }

  public init(
    artifactID: String,
    kind: String,
    logicalPath: String,
    mediaType: String,
    data: Data
  ) {
    self.init(
      artifactID: artifactID,
      kind: kind,
      logicalPath: logicalPath,
      mediaType: mediaType,
      contentBase64: data.base64EncodedString(),
      contentSHA256: CanonicalMemoryJSON.sha256(data)
    )
  }

  public func decodedData() throws -> Data {
    guard let data = Data(base64Encoded: contentBase64),
      data.base64EncodedString() == contentBase64,
      CanonicalMemoryJSON.sha256(data) == contentSHA256
    else {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "Встроенный артефакт \(artifactID) не совпадает со своим хэшем или Base64."
      )
    }
    return data
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeExactCanonical(Self.self, data: data, kind: "встроенный артефакт")
  }
}

public struct SharedEpisodeMemorySeed:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let episodeID: String
  public let runGenerationID: String
  public let activeWorkPackageArtifactID: String
  public let predecessorTerminalGenerationSHA256: String?
  public let controlPlan: SharedEpisodeControlPlan
  public let passportArtifactID: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String
  public let artifacts: [SharedEpisodeEmbeddedArtifact]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case runGenerationID = "run_generation_id"
    case activeWorkPackageArtifactID = "active_work_package_artifact_id"
    case predecessorTerminalGenerationSHA256 =
      "predecessor_terminal_generation_sha256"
    case controlPlan = "control_plan"
    case passportArtifactID = "passport_artifact_id"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
    case artifacts
  }

  public init(
    schemaVersion: Int = SharedEpisodeMemorySeed.currentSchemaVersion,
    episodeID: String,
    runGenerationID: String = "run.generation.1",
    activeWorkPackageArtifactID: String = "package.primary",
    predecessorTerminalGenerationSHA256: String? = nil,
    controlPlan: SharedEpisodeControlPlan = .fixtureDefault,
    passportArtifactID: String,
    passportSHA256: String,
    artifactManifestSHA256: String,
    artifacts: [SharedEpisodeEmbeddedArtifact]
  ) {
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.runGenerationID = runGenerationID
    self.activeWorkPackageArtifactID = activeWorkPackageArtifactID
    self.predecessorTerminalGenerationSHA256 =
      predecessorTerminalGenerationSHA256
    self.controlPlan = controlPlan
    self.passportArtifactID = passportArtifactID
    self.passportSHA256 = passportSHA256
    self.artifactManifestSHA256 = artifactManifestSHA256
    self.artifacts = artifacts
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    let seed = try decodeExactCanonical(Self.self, data: data, kind: "seed общей памяти")
    _ = try validateSharedEpisodeSeed(seed)
    return seed
  }
}

public enum SharedEpisodeContributorKind: String, Codable, Equatable, Sendable {
  case author
  case role
}

public struct SharedEpisodeContributor:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let kind: SharedEpisodeContributorKind
  public let identifier: String

  public init(kind: SharedEpisodeContributorKind, identifier: String) {
    self.kind = kind
    self.identifier = identifier
  }
}

public struct SharedEpisodeContributionContent:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let mediaType: String
  public let body: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case mediaType = "media_type"
    case body
  }

  public init(
    schemaVersion: Int = 1,
    mediaType: String,
    body: String
  ) {
    self.schemaVersion = schemaVersion
    self.mediaType = mediaType
    self.body = body
  }
}

public struct SharedEpisodeContributionOrigin:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let roleID: String
  public let workPackageArtifactID: String
  public let inputManifestArtifactID: String
  public let contributionArtifactID: String
  public let hypothesisIDs: [String]

  enum CodingKeys: String, CodingKey {
    case roleID = "role_id"
    case workPackageArtifactID = "work_package_artifact_id"
    case inputManifestArtifactID = "input_manifest_artifact_id"
    case contributionArtifactID = "contribution_artifact_id"
    case hypothesisIDs = "hypothesis_ids"
  }

  public init(
    roleID: String,
    workPackageArtifactID: String,
    inputManifestArtifactID: String,
    contributionArtifactID: String,
    hypothesisIDs: [String]
  ) {
    self.roleID = roleID
    self.workPackageArtifactID = workPackageArtifactID
    self.inputManifestArtifactID = inputManifestArtifactID
    self.contributionArtifactID = contributionArtifactID
    self.hypothesisIDs = hypothesisIDs
  }
}

public struct SharedEpisodeContribution:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 2

  public let schemaVersion: Int
  public let contributionID: String
  public let parentGenerationSHA256: String
  public let contributor: SharedEpisodeContributor
  public let contentSHA256: String
  public let content: SharedEpisodeContributionContent
  public let origin: SharedEpisodeContributionOrigin
  public let provenance: SharedEpisodeContributionProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case contributionID = "contribution_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case contributor
    case contentSHA256 = "content_sha256"
    case content
    case origin
    case provenance
  }

  public init(
    schemaVersion: Int = SharedEpisodeContribution.currentSchemaVersion,
    contributionID: String,
    parentGenerationSHA256: String,
    contributor: SharedEpisodeContributor,
    contentSHA256: String,
    content: SharedEpisodeContributionContent,
    origin: SharedEpisodeContributionOrigin,
    provenance: SharedEpisodeContributionProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.contributionID = contributionID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.contributor = contributor
    self.contentSHA256 = contentSHA256
    self.content = content
    self.origin = origin
    self.provenance = provenance
  }

  public func rebinding(
    parentGenerationSHA256: String
  ) -> SharedEpisodeContribution {
    SharedEpisodeContribution(
      schemaVersion: schemaVersion,
      contributionID: contributionID,
      parentGenerationSHA256: parentGenerationSHA256,
      contributor: contributor,
      contentSHA256: contentSHA256,
      content: content,
      origin: origin,
      provenance: provenance.rebinding(
        parentGenerationSHA256: parentGenerationSHA256
      )
    )
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeExactCanonical(Self.self, data: data, kind: "вклад общей памяти")
  }
}

public enum SharedEpisodeJournalEvent:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  case contribution(SharedEpisodeContribution)
  case verification(SharedEpisodeVerificationRecord)
  case control(SharedEpisodeControlCommand)

  private enum Kind: String, Codable {
    case contribution
    case verification
    case control
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case contribution
    case verification
    case control
  }

  public var kind: SharedEpisodeControlCommand.Kind {
    switch self {
    case .contribution:
      .contribution
    case .verification:
      .verification
    case .control(let command):
      command.kind
    }
  }

  public var identifier: String {
    switch self {
    case .contribution(let value):
      value.contributionID
    case .verification(let value):
      value.recordID
    case .control(let value):
      value.identifier
    }
  }

  public var parentGenerationSHA256: String {
    switch self {
    case .contribution(let value):
      value.parentGenerationSHA256
    case .verification(let value):
      value.parentGenerationSHA256
    case .control(let value):
      value.parentGenerationSHA256
    }
  }

  public var contribution: SharedEpisodeContribution? {
    guard case .contribution(let value) = self else { return nil }
    return value
  }

  public var verification: SharedEpisodeVerificationRecord? {
    guard case .verification(let value) = self else { return nil }
    return value
  }

  public var control: SharedEpisodeControlCommand? {
    guard case .control(let value) = self else { return nil }
    return value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .contribution:
      guard Set(container.allKeys) == Set([.kind, .contribution]) else {
        throw DecodingError.dataCorruptedError(
          forKey: .kind,
          in: container,
          debugDescription: "Событие вклада содержит лишний или отсутствующий payload."
        )
      }
      self = .contribution(
        try container.decode(SharedEpisodeContribution.self, forKey: .contribution)
      )
    case .verification:
      guard Set(container.allKeys) == Set([.kind, .verification]) else {
        throw DecodingError.dataCorruptedError(
          forKey: .kind,
          in: container,
          debugDescription: "Событие проверки содержит лишний или отсутствующий payload."
        )
      }
      self = .verification(
        try container.decode(SharedEpisodeVerificationRecord.self, forKey: .verification)
      )
    case .control:
      guard Set(container.allKeys) == Set([.kind, .control]) else {
        throw DecodingError.dataCorruptedError(
          forKey: .kind,
          in: container,
          debugDescription: "Управляющее событие содержит лишний или отсутствующий payload."
        )
      }
      self = .control(
        try container.decode(SharedEpisodeControlCommand.self, forKey: .control)
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .contribution(let value):
      try container.encode(Kind.contribution, forKey: .kind)
      try container.encode(value, forKey: .contribution)
    case .verification(let value):
      try container.encode(Kind.verification, forKey: .kind)
      try container.encode(value, forKey: .verification)
    case .control(let value):
      try container.encode(Kind.control, forKey: .kind)
      try container.encode(value, forKey: .control)
    }
  }
}

public struct SharedEpisodeJournalEntry:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let ordinal: Int
  public let eventSHA256: String
  public let event: SharedEpisodeJournalEvent

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case ordinal
    case eventSHA256 = "event_sha256"
    case event
  }

  public init(
    schemaVersion: Int = SharedEpisodeJournalEntry.currentSchemaVersion,
    ordinal: Int,
    eventSHA256: String,
    event: SharedEpisodeJournalEvent
  ) {
    self.schemaVersion = schemaVersion
    self.ordinal = ordinal
    self.eventSHA256 = eventSHA256
    self.event = event
  }
}

public struct SharedEpisodeEventJournal:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let episodeID: String
  public let entries: [SharedEpisodeJournalEntry]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case entries
  }

  public init(
    schemaVersion: Int = SharedEpisodeEventJournal.currentSchemaVersion,
    episodeID: String,
    entries: [SharedEpisodeJournalEntry]
  ) {
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.entries = entries
  }
}

public struct SharedEpisodeState:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let episodeID: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String
  public let contributions: [SharedEpisodeContribution]
  public let verifications: [SharedEpisodeVerificationRecord]
  public let provenanceReport: SharedEpisodeProvenanceReport
  public let verificationReport: SharedEpisodeVerificationReport
  public let controlState: SharedEpisodeControlState

  public var selectionDecisions: [SharedEpisodeSelectionDecision] {
    controlState.selectionDecisions
  }

  public var budgetState: SharedEpisodeBudgetState {
    controlState.budgetState
  }

  public var pendingTransitions: [SharedEpisodeParkedTransition] {
    controlState.pendingTransitions
  }

  public var terminal: SharedEpisodeTerminalRecord? {
    controlState.terminal
  }

  public var unresolvedDisagreementIDs: [String] {
    controlState.unresolvedDisagreementIDs
  }

  public var openReservations: [SharedEpisodeOpenReservation] {
    controlState.openReservations
  }

  public var controlReport: SharedEpisodeControlReport {
    controlState.controlReport
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
    case contributions
    case verifications
    case provenanceReport = "provenance_report"
    case verificationReport = "verification_report"
    case controlState = "control_state"
  }

  public init(
    schemaVersion: Int = SharedEpisodeState.currentSchemaVersion,
    episodeID: String,
    passportSHA256: String,
    artifactManifestSHA256: String,
    contributions: [SharedEpisodeContribution],
    verifications: [SharedEpisodeVerificationRecord],
    provenanceReport: SharedEpisodeProvenanceReport,
    verificationReport: SharedEpisodeVerificationReport,
    controlState: SharedEpisodeControlState
  ) {
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.passportSHA256 = passportSHA256
    self.artifactManifestSHA256 = artifactManifestSHA256
    self.contributions = contributions
    self.verifications = verifications
    self.provenanceReport = provenanceReport
    self.verificationReport = verificationReport
    self.controlState = controlState
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeExactCanonical(Self.self, data: data, kind: "состояние общей памяти")
  }
}

public struct SharedEpisodeGenerationProvenance:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let inputContributionIDs: [String]
  public let inputVerificationRecordIDs: [String]
  public let inputControlEventIDs: [String]
  public let acceptedContributionIDs: [String]
  public let acceptedVerificationRecordIDs: [String]
  public let acceptedControlEventIDs: [String]
  public let reducerVersion: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String

  enum CodingKeys: String, CodingKey {
    case inputContributionIDs = "input_contribution_ids"
    case inputVerificationRecordIDs = "input_verification_record_ids"
    case inputControlEventIDs = "input_control_event_ids"
    case acceptedContributionIDs = "accepted_contribution_ids"
    case acceptedVerificationRecordIDs = "accepted_verification_record_ids"
    case acceptedControlEventIDs = "accepted_control_event_ids"
    case reducerVersion = "reducer_version"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
  }

  public init(
    inputContributionIDs: [String],
    inputVerificationRecordIDs: [String],
    inputControlEventIDs: [String],
    acceptedContributionIDs: [String],
    acceptedVerificationRecordIDs: [String],
    acceptedControlEventIDs: [String],
    reducerVersion: String,
    passportSHA256: String,
    artifactManifestSHA256: String
  ) {
    self.inputContributionIDs = inputContributionIDs
    self.inputVerificationRecordIDs = inputVerificationRecordIDs
    self.inputControlEventIDs = inputControlEventIDs
    self.acceptedContributionIDs = acceptedContributionIDs
    self.acceptedVerificationRecordIDs = acceptedVerificationRecordIDs
    self.acceptedControlEventIDs = acceptedControlEventIDs
    self.reducerVersion = reducerVersion
    self.passportSHA256 = passportSHA256
    self.artifactManifestSHA256 = artifactManifestSHA256
  }
}

public struct SharedEpisodeGeneration:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let canonicalProfile: String
  public let reducerVersion: String
  public let previousGenerationSHA256: String?
  public let inputSHA256: String
  public let seedSHA256: String
  public let eventJournalSHA256: String
  public let stateSHA256: String
  public let seed: SharedEpisodeMemorySeed
  public let eventJournal: SharedEpisodeEventJournal
  public let state: SharedEpisodeState
  public let provenance: SharedEpisodeGenerationProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case reducerVersion = "reducer_version"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case inputSHA256 = "input_sha256"
    case seedSHA256 = "seed_sha256"
    case eventJournalSHA256 = "event_journal_sha256"
    case stateSHA256 = "state_sha256"
    case seed
    case eventJournal = "event_journal"
    case state
    case provenance
  }

  public init(
    schemaVersion: Int = SharedEpisodeGeneration.currentSchemaVersion,
    canonicalProfile: String = CanonicalMemoryJSON.profileID,
    reducerVersion: String,
    previousGenerationSHA256: String?,
    inputSHA256: String,
    seedSHA256: String,
    eventJournalSHA256: String,
    stateSHA256: String,
    seed: SharedEpisodeMemorySeed,
    eventJournal: SharedEpisodeEventJournal,
    state: SharedEpisodeState,
    provenance: SharedEpisodeGenerationProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.canonicalProfile = canonicalProfile
    self.reducerVersion = reducerVersion
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.inputSHA256 = inputSHA256
    self.seedSHA256 = seedSHA256
    self.eventJournalSHA256 = eventJournalSHA256
    self.stateSHA256 = stateSHA256
    self.seed = seed
    self.eventJournal = eventJournal
    self.state = state
    self.provenance = provenance
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    do {
      try CanonicalMemoryJSON.requireCanonical(data)
      guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let schemaVersion = root["schema_version"] as? Int
      else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Поколение не содержит точную версию схемы."
        )
      }
      guard schemaVersion == currentSchemaVersion else {
        throw SharedEpisodeMemoryError.incompatibleGeneration(
          "Поколение имеет версию схемы \(schemaVersion), ожидается \(currentSchemaVersion)."
        )
      }
      let generation = try decodeExactCanonical(
        Self.self,
        data: data,
        kind: "поколение общей памяти"
      )
      try SharedEpisodeMemoryReducer.validate(generation)
      return generation
    } catch let error as SharedEpisodeMemoryError {
      switch error {
      case .incompatibleGeneration:
        throw error
      case .corruptGeneration:
        throw error
      default:
        throw SharedEpisodeMemoryError.corruptGeneration(error.description)
      }
    } catch {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "Канонические байты поколения не соответствуют точной схеме."
      )
    }
  }
}

public struct StoredSharedEpisodeGeneration:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let generationSHA256: String
  public let generation: SharedEpisodeGeneration

  enum CodingKeys: String, CodingKey {
    case generationSHA256 = "generation_sha256"
    case generation
  }

  public init(
    generationSHA256: String,
    generation: SharedEpisodeGeneration
  ) {
    self.generationSHA256 = generationSHA256
    self.generation = generation
  }

  public var state: SharedEpisodeState {
    generation.state
  }
}

public struct SharedEpisodeControlledContinuation: Equatable, Sendable {
  public let reserved: SharedEpisodeGeneration
  public let completed: SharedEpisodeGeneration

  public init(
    reserved: SharedEpisodeGeneration,
    completed: SharedEpisodeGeneration
  ) {
    self.reserved = reserved
    self.completed = completed
  }
}

public enum SharedEpisodeMemoryReducer {
  public static let version = "fum.shared-episode-memory.reducer.v4"
  public static let maximumContributions = 256
  public static let maximumVerifications = 256
  public static let maximumControlEvents = 1_024
  public static let maximumEvents =
    maximumContributions + maximumVerifications + maximumControlEvents

  public static func foundation(
    seed: SharedEpisodeMemorySeed
  ) throws -> SharedEpisodeGeneration {
    guard seed.predecessorTerminalGenerationSHA256 == nil else {
      throw SharedEpisodeMemoryError.invalidResumption(
        "Seed со ссылкой на предшественника допускается только через resumedFoundation."
      )
    }
    let journal = SharedEpisodeEventJournal(
      episodeID: seed.episodeID,
      entries: []
    )
    return try replayDetails(seed: seed, journal: journal).generation
  }

  public static func resumedFoundation(
    seed: SharedEpisodeMemorySeed,
    predecessorTerminal: SharedEpisodeGeneration
  ) throws -> SharedEpisodeGeneration {
    try validate(predecessorTerminal)
    guard predecessorTerminal.state.terminal != nil else {
      throw SharedEpisodeMemoryError.invalidResumption(
        "Предшественник не имеет терминального исхода."
      )
    }
    let predecessorSHA256 = CanonicalMemoryJSON.sha256(
      try predecessorTerminal.canonicalJSONData()
    )
    let predecessorPackage = predecessorTerminal.seed.artifacts.first(where: {
      $0.artifactID == predecessorTerminal.seed.activeWorkPackageArtifactID
    })
    let resumedPackage = seed.artifacts.first(where: {
      $0.artifactID == seed.activeWorkPackageArtifactID
    })
    guard seed.predecessorTerminalGenerationSHA256 == predecessorSHA256,
      seed.episodeID == predecessorTerminal.seed.episodeID,
      seed.runGenerationID != predecessorTerminal.seed.runGenerationID,
      seed.activeWorkPackageArtifactID
        != predecessorTerminal.seed.activeWorkPackageArtifactID,
      let predecessorPackage,
      let resumedPackage,
      predecessorPackage.contentSHA256 != resumedPackage.contentSHA256
    else {
      throw SharedEpisodeMemoryError.invalidResumption(
        "Нужны новые semantic run и рабочий пакет с точной ссылкой на терминального предшественника."
      )
    }
    let journal = SharedEpisodeEventJournal(
      episodeID: seed.episodeID,
      entries: []
    )
    return try replayDetails(seed: seed, journal: journal).generation
  }

  public static func continuation(
    from previous: SharedEpisodeGeneration,
    contribution: SharedEpisodeContribution
  ) throws -> SharedEpisodeControlledContinuation {
    try validate(previous)
    guard previous.state.terminal == nil else {
      throw SharedEpisodeMemoryError.terminalEpisode
    }
    let previousSHA256 = CanonicalMemoryJSON.sha256(
      try previous.canonicalJSONData()
    )
    guard contribution.parentGenerationSHA256 == previousSHA256 else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Вклад не ссылается на точное родительское поколение."
      )
    }
    let ordinal = previous.eventJournal.entries.count + 1
    let roundID = "round.auto.contribution.\(ordinal)"
    let budget = try SharedEpisodeControlKernel.meteredUsage(
      for: contribution,
      executors: previous.state.controlState.usedExecutorIDs.contains(
        contribution.provenance.executorID
      ) ? 0 : 1,
      rounds: previous.state.controlState.usedRoundIDs.contains(roundID) ? 0 : 1
    )
    let reservation = SharedEpisodeActionReservation(
      permitID: "permit.auto.contribution.\(ordinal)",
      actionID: "action.auto.contribution.\(ordinal)",
      parentGenerationSHA256: previousSHA256,
      phase: .productive,
      kind: .contribution,
      executorID: contribution.provenance.executorID,
      roundID: roundID,
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: budget
    )
    let reserved = try continuation(
      from: previous,
      control: .actionReserved(reservation)
    )
    let reservedSHA256 = CanonicalMemoryJSON.sha256(
      try reserved.canonicalJSONData()
    )
    let completed = try continuation(
      from: reserved,
      control: .contribution(
        contribution.rebinding(parentGenerationSHA256: reservedSHA256),
        SharedEpisodeActionSettlement(
          permitID: reservation.permitID,
          actionID: reservation.actionID,
          actual: budget
        )
      )
    )
    return SharedEpisodeControlledContinuation(
      reserved: reserved,
      completed: completed
    )
  }

  public static func continuation(
    from previous: SharedEpisodeGeneration,
    verification: SharedEpisodeVerificationRecord
  ) throws -> SharedEpisodeControlledContinuation {
    try validate(previous)
    guard previous.state.terminal == nil else {
      throw SharedEpisodeMemoryError.terminalEpisode
    }
    let previousSHA256 = CanonicalMemoryJSON.sha256(
      try previous.canonicalJSONData()
    )
    guard verification.parentGenerationSHA256 == previousSHA256 else {
      throw SharedEpisodeMemoryError.invalidVerification(
        "Проверка не ссылается на точное родительское поколение."
      )
    }
    let ordinal = previous.eventJournal.entries.count + 1
    let roundID = "round.auto.verification.\(ordinal)"
    let budget = try SharedEpisodeControlKernel.meteredUsage(
      for: verification,
      executors: previous.state.controlState.usedExecutorIDs.contains(
        verification.provenance.executorID
      ) ? 0 : 1,
      rounds: previous.state.controlState.usedRoundIDs.contains(roundID) ? 0 : 1
    )
    let reservation = SharedEpisodeActionReservation(
      permitID: "permit.auto.verification.\(ordinal)",
      actionID: "action.auto.verification.\(ordinal)",
      parentGenerationSHA256: previousSHA256,
      phase: .verification,
      kind: .verification,
      executorID: verification.provenance.executorID,
      roundID: roundID,
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: budget
    )
    let reserved = try continuation(
      from: previous,
      control: .actionReserved(reservation)
    )
    let reservedSHA256 = CanonicalMemoryJSON.sha256(
      try reserved.canonicalJSONData()
    )
    let completed = try continuation(
      from: reserved,
      control: .verification(
        verification.rebinding(parentGenerationSHA256: reservedSHA256),
        SharedEpisodeActionSettlement(
          permitID: reservation.permitID,
          actionID: reservation.actionID,
          actual: budget
        )
      )
    )
    return SharedEpisodeControlledContinuation(
      reserved: reserved,
      completed: completed
    )
  }

  public static func continuation(
    from previous: SharedEpisodeGeneration,
    control: SharedEpisodeControlCommand
  ) throws -> SharedEpisodeGeneration {
    try validate(previous)
    guard previous.state.terminal == nil else {
      throw SharedEpisodeMemoryError.terminalEpisode
    }
    let previousSHA256 = CanonicalMemoryJSON.sha256(
      try previous.canonicalJSONData()
    )
    guard control.parentGenerationSHA256 == previousSHA256 else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Событие не ссылается на точное родительское поколение."
      )
    }
    let controlEventCount = previous.eventJournal.entries.reduce(into: 0) {
      if case .control = $1.event { $0 += 1 }
    }
    guard previous.eventJournal.entries.count < maximumEvents,
      controlEventCount < maximumControlEvents
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Журнал достиг предела управляющих событий версии 4."
      )
    }

    let event = SharedEpisodeJournalEvent.control(control)
    let eventData = try event.canonicalJSONData()
    let entry = SharedEpisodeJournalEntry(
      ordinal: previous.eventJournal.entries.count + 1,
      eventSHA256: CanonicalMemoryJSON.sha256(eventData),
      event: event
    )
    let journal = SharedEpisodeEventJournal(
      episodeID: previous.seed.episodeID,
      entries: previous.eventJournal.entries + [entry]
    )
    return try replayDetails(seed: previous.seed, journal: journal).generation
  }

  public static func replay(
    seed: SharedEpisodeMemorySeed,
    journal: SharedEpisodeEventJournal
  ) throws -> SharedEpisodeState {
    try replayDetails(seed: seed, journal: journal).state
  }

  public static func validate(_ generation: SharedEpisodeGeneration) throws {
    guard generation.schemaVersion == SharedEpisodeGeneration.currentSchemaVersion else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Поддерживается только схема поколения версии 4."
      )
    }
    guard generation.canonicalProfile == CanonicalMemoryJSON.profileID else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Поколение использует другой профиль канонических байтов."
      )
    }
    guard generation.reducerVersion == version else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Поколение создано другой версией редуктора."
      )
    }
    guard isSharedEpisodeSHA256(generation.inputSHA256),
      isSharedEpisodeSHA256(generation.seedSHA256),
      isSharedEpisodeSHA256(generation.eventJournalSHA256),
      isSharedEpisodeSHA256(generation.stateSHA256),
      generation.previousGenerationSHA256.map(isSharedEpisodeSHA256) ?? true
    else {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "Поколение содержит некорректный SHA-256."
      )
    }

    let replayed = try replayDetails(
      seed: generation.seed,
      journal: generation.eventJournal
    ).generation
    guard replayed == generation else {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "Поколение не выводится из seed и полного канонического журнала."
      )
    }
  }

  private static func replayDetails(
    seed: SharedEpisodeMemorySeed,
    journal: SharedEpisodeEventJournal
  ) throws -> (state: SharedEpisodeState, generation: SharedEpisodeGeneration) {
    let context = try validateSharedEpisodeSeed(seed)
    let controlEventCount = journal.entries.reduce(into: 0) {
      if case .control = $1.event { $0 += 1 }
    }
    guard journal.schemaVersion == SharedEpisodeEventJournal.currentSchemaVersion,
      journal.episodeID == seed.episodeID,
      journal.entries.count <= maximumEvents,
      controlEventCount <= maximumControlEvents
    else {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "Журнал имеет неподдерживаемую схему, эпизод или размер."
      )
    }

    var state = SharedEpisodeState(
      episodeID: seed.episodeID,
      passportSHA256: seed.passportSHA256,
      artifactManifestSHA256: seed.artifactManifestSHA256,
      contributions: [],
      verifications: [],
      provenanceReport: try SharedEpisodeProvenanceValidator.analyze([]),
      verificationReport: try SharedEpisodeVerificationValidator.analyze(
        contributions: [],
        verifications: []
      ),
      controlState: try SharedEpisodeControlKernel.initialState(
        plan: seed.controlPlan
      )
    )
    var prefixJournal = SharedEpisodeEventJournal(
      episodeID: seed.episodeID,
      entries: []
    )
    var generation = try makeGeneration(
      seed: seed,
      journal: prefixJournal,
      state: state,
      previousGenerationSHA256: seed.predecessorTerminalGenerationSHA256,
      inputSHA256: CanonicalMemoryJSON.sha256(try seed.canonicalJSONData()),
      inputContributionIDs: [],
      inputVerificationRecordIDs: [],
      inputControlEventIDs: []
    )
    var eventIDs = Set<String>()

    for (index, entry) in journal.entries.enumerated() {
      guard entry.schemaVersion == SharedEpisodeJournalEntry.currentSchemaVersion,
        entry.ordinal == index + 1
      else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Журнал содержит разрыв или неподдерживаемую запись."
        )
      }
      let eventData = try entry.event.canonicalJSONData()
      let eventSHA256 = CanonicalMemoryJSON.sha256(eventData)
      guard entry.eventSHA256 == eventSHA256,
        eventIDs.insert(entry.event.identifier).inserted
      else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Хэш или идентификатор записи журнала не согласован."
        )
      }

      let expectedParentSHA256 = CanonicalMemoryJSON.sha256(
        try generation.canonicalJSONData()
      )
      guard entry.event.parentGenerationSHA256 == expectedParentSHA256 else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Событие не продолжает подтверждённую хэш-цепочку журнала."
        )
      }
      guard state.terminal == nil else {
        throw SharedEpisodeMemoryError.terminalEpisode
      }

      var contributions = state.contributions
      var verifications = state.verifications
      var controlState = state.controlState
      var inputContributionIDs: [String] = []
      var inputVerificationRecordIDs: [String] = []
      var inputControlEventIDs: [String] = []
      switch entry.event {
      case .contribution, .verification:
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Схема 4 отклоняет доменный результат без предварительной резервации и точного settlement."
        )
      case .control(let command):
        switch command {
        case .contribution(let contribution, _):
          guard contributions.count < maximumContributions else {
            throw SharedEpisodeMemoryError.corruptGeneration(
              "Журнал превышает предел вкладов версии 4."
            )
          }
          try validateContribution(
            contribution,
            context: context,
            priorProvenances: contributions.map(\.provenance)
          )
          contributions.append(contribution)
          for (verificationIndex, acceptedVerification) in verifications.enumerated() {
            try validateVerificationRecord(
              acceptedVerification,
              context: context,
              contributions: contributions,
              priorVerifications: Array(verifications.prefix(verificationIndex))
            )
          }
          inputContributionIDs = [contribution.contributionID]
        case .verification(let verification, _):
          guard verifications.count < maximumVerifications else {
            throw SharedEpisodeMemoryError.corruptGeneration(
              "Журнал превышает предел проверок версии 4."
            )
          }
          try validateVerificationRecord(
            verification,
            context: context,
            contributions: contributions,
            priorVerifications: verifications
          )
          verifications.append(verification)
          inputVerificationRecordIDs = [verification.recordID]
        case .actionReserved, .selection, .modelOnlyCompleted,
          .transitionParked, .terminal:
          break
        }

        let verificationReport = try SharedEpisodeVerificationValidator.analyze(
          contributions: contributions,
          verifications: verifications
        )
        let unresolved = currentUnresolvedDisagreementIDs(
          report: verificationReport,
          controlState: controlState
        )
        controlState = try SharedEpisodeControlKernel.apply(
          command,
          to: controlState,
          plan: seed.controlPlan,
          expectedParentGenerationSHA256: expectedParentSHA256,
          selectionContext: command.kind == .selection || command.kind == .terminal
            ? try selectionEvidenceContext(
              context: context,
              contributions: contributions,
              verifications: verifications,
              report: verificationReport,
              journal: prefixJournal
            ) : nil,
          currentUnresolvedDisagreementIDs: unresolved
        )
        inputControlEventIDs = [command.identifier]
      }

      let verificationReport = try SharedEpisodeVerificationValidator.analyze(
        contributions: contributions,
        verifications: verifications
      )
      prefixJournal = SharedEpisodeEventJournal(
        episodeID: seed.episodeID,
        entries: prefixJournal.entries + [entry]
      )
      state = SharedEpisodeState(
        episodeID: seed.episodeID,
        passportSHA256: seed.passportSHA256,
        artifactManifestSHA256: seed.artifactManifestSHA256,
        contributions: contributions,
        verifications: verifications,
        provenanceReport: try SharedEpisodeProvenanceValidator.analyze(
          contributions.map(\.provenance)
        ),
        verificationReport: verificationReport,
        controlState: controlState
      )
      generation = try makeGeneration(
        seed: seed,
        journal: prefixJournal,
        state: state,
        previousGenerationSHA256: expectedParentSHA256,
        inputSHA256: eventSHA256,
        inputContributionIDs: inputContributionIDs,
        inputVerificationRecordIDs: inputVerificationRecordIDs,
        inputControlEventIDs: inputControlEventIDs
      )
    }

    return (state, generation)
  }

  private static func currentUnresolvedDisagreementIDs(
    report: SharedEpisodeVerificationReport,
    controlState: SharedEpisodeControlState
  ) -> [String] {
    var latestResolutionByID: [String: SharedEpisodeDisagreementResolution] = [:]
    for decision in controlState.selectionDecisions {
      for disposition in decision.disagreementDispositions {
        latestResolutionByID[disposition.disagreementID] = disposition.resolution
      }
    }
    return report.disagreements.map(\.disagreementID)
      .filter { latestResolutionByID[$0] != .resolved }
      .sorted()
  }

  private static func selectionEvidenceContext(
    context: SharedEpisodeSeedContext,
    contributions: [SharedEpisodeContribution],
    verifications: [SharedEpisodeVerificationRecord],
    report: SharedEpisodeVerificationReport,
    journal: SharedEpisodeEventJournal
  ) throws -> SharedEpisodeSelectionEvidenceContext {
    guard
      let criteriaArtifact = context.artifactsByID[
        context.criteriaDocument.criteriaArtifactID
      ]
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Выбор не нашёл встроенный артефакт критериев."
      )
    }
    let assessmentByID = report.assessmentsByRecordID
    var reservationsByPermitID: [String: SharedEpisodeActionReservation] = [:]
    var distinguishingCheckIDByVerificationRecordID: [String: String] = [:]
    for entry in journal.entries {
      guard case .control(let command) = entry.event else { continue }
      switch command {
      case .actionReserved(let reservation):
        reservationsByPermitID[reservation.permitID] = reservation
      case .verification(let verification, let settlement):
        if let checkID = reservationsByPermitID[settlement.permitID]?
          .distinguishingCheckID
        {
          distinguishingCheckIDByVerificationRecordID[verification.recordID] = checkID
        }
      case .contribution, .selection, .modelOnlyCompleted,
        .transitionParked, .terminal:
        break
      }
    }
    let verificationIndexByID = Dictionary(
      uniqueKeysWithValues: verifications.enumerated().map { ($0.element.recordID, $0.offset) }
    )
    return SharedEpisodeSelectionEvidenceContext(
      criteriaArtifactID: criteriaArtifact.artifactID,
      criteriaSHA256: criteriaArtifact.contentSHA256,
      criterionIDs: context.criteriaDocument.criteria.map(\.criterionID).sorted(),
      contributions: try contributions.map { contribution in
        SharedEpisodeSelectionContributionSnapshot(
          contributionID: contribution.contributionID,
          contentSHA256: contribution.contentSHA256,
          provenanceSHA256: CanonicalMemoryJSON.sha256(
            try contribution.provenance.canonicalJSONData()
          )
        )
      }.sorted { $0.contributionID < $1.contributionID },
      verifications: verifications.map { verification in
        let contributionIDs = Array(
          Set(verification.content.claims.map(\.contributionID))
        ).sorted()
        return SharedEpisodeSelectionVerificationSnapshot(
          recordID: verification.recordID,
          distinguishingCheckID: distinguishingCheckIDByVerificationRecordID[
            verification.recordID
          ],
          contributionIDs: contributionIDs,
          evidenceIDs: verification.content.evidence.map(\.evidenceID).sorted(),
          evidenceBindings: contributionIDs.map { contributionID in
            let claimIDs = Set(
              verification.content.claims.filter {
                $0.contributionID == contributionID
              }.map(\.claimID)
            )
            return SharedEpisodeSelectionEvidenceBinding(
              contributionID: contributionID,
              evidenceIDs: verification.content.evidence.filter {
                claimIDs.contains($0.claimID)
              }.map(\.evidenceID).sorted()
            )
          },
          outcome: verification.content.outcome,
          standing: assessmentByID[verification.recordID]?.standing
            ?? .unconfirmedProvenance
        )
      }.sorted { $0.recordID < $1.recordID },
      disagreements: try report.disagreements.map { disagreement in
        guard
          let verification = verifications.first(where: { record in
            record.content.disagreements.contains {
              $0.disagreementID == disagreement.disagreementID
            }
          }),
          let claim = verification.content.claims.first(where: {
            $0.claimID == disagreement.claimID
          }),
          let verificationIndex = verificationIndexByID[verification.recordID]
        else {
          throw SharedEpisodeMemoryError.invalidSelection(
            "Разногласие не связано с точной проверкой и утверждением."
          )
        }
        let originalEvidenceIDs = verification.content.evidence.filter {
          $0.claimID == claim.claimID
        }.map(\.evidenceID)
        let laterDistinguishingEvidenceIDs = verifications.enumerated().flatMap {
          index, candidate -> [String] in
          guard index > verificationIndex,
            distinguishingCheckIDByVerificationRecordID[candidate.recordID] != nil
          else { return [] }
          let claimIDs = Set(
            candidate.content.claims.compactMap {
              candidateClaim in
              candidateClaim.claimID == claim.claimID
                && candidateClaim.contributionID == claim.contributionID
                && candidateClaim.resultSHA256 == claim.resultSHA256
                ? candidateClaim.claimID : nil
            })
          return candidate.content.evidence.compactMap {
            claimIDs.contains($0.claimID) ? $0.evidenceID : nil
          }
        }
        return SharedEpisodeSelectionDisagreementSnapshot(
          disagreementID: disagreement.disagreementID,
          verificationRecordID: verification.recordID,
          claimID: claim.claimID,
          contributionID: claim.contributionID,
          resultSHA256: claim.resultSHA256,
          eligibleEvidenceIDs: Array(
            Set(originalEvidenceIDs + laterDistinguishingEvidenceIDs)
          ).sorted()
        )
      }.sorted { $0.disagreementID < $1.disagreementID }
    )
  }

  private static func makeGeneration(
    seed: SharedEpisodeMemorySeed,
    journal: SharedEpisodeEventJournal,
    state: SharedEpisodeState,
    previousGenerationSHA256: String?,
    inputSHA256: String,
    inputContributionIDs: [String],
    inputVerificationRecordIDs: [String],
    inputControlEventIDs: [String]
  ) throws -> SharedEpisodeGeneration {
    SharedEpisodeGeneration(
      reducerVersion: version,
      previousGenerationSHA256: previousGenerationSHA256,
      inputSHA256: inputSHA256,
      seedSHA256: CanonicalMemoryJSON.sha256(try seed.canonicalJSONData()),
      eventJournalSHA256: CanonicalMemoryJSON.sha256(
        try journal.canonicalJSONData()
      ),
      stateSHA256: CanonicalMemoryJSON.sha256(try state.canonicalJSONData()),
      seed: seed,
      eventJournal: journal,
      state: state,
      provenance: SharedEpisodeGenerationProvenance(
        inputContributionIDs: inputContributionIDs,
        inputVerificationRecordIDs: inputVerificationRecordIDs,
        inputControlEventIDs: inputControlEventIDs,
        acceptedContributionIDs: journal.entries.compactMap { entry in
          switch entry.event {
          case .contribution(let contribution):
            contribution.contributionID
          case .control(.contribution(let contribution, _)):
            contribution.contributionID
          case .verification, .control:
            nil
          }
        },
        acceptedVerificationRecordIDs: journal.entries.compactMap { entry in
          switch entry.event {
          case .verification(let verification):
            verification.recordID
          case .control(.verification(let verification, _)):
            verification.recordID
          case .contribution, .control:
            nil
          }
        },
        acceptedControlEventIDs: journal.entries.map {
          $0.event.control?.identifier
        }.compactMap { $0 },
        reducerVersion: version,
        passportSHA256: seed.passportSHA256,
        artifactManifestSHA256: seed.artifactManifestSHA256
      )
    )
  }
}

public struct SharedEpisodeMemoryStore {
  private static let maximumGenerationBytes = 16_777_216

  public let rootURL: URL
  private let contentStore: ContentAddressedGenerationStore

  public init(rootURL: URL) {
    self.rootURL = rootURL
    contentStore = ContentAddressedGenerationStore(
      rootURL: rootURL,
      canonicalProfile: CanonicalMemoryJSON.profileID,
      maximumGenerationBytes: Self.maximumGenerationBytes,
      validateGeneration: { data in
        _ = try SharedEpisodeGeneration.decodeCanonical(data)
      },
      validateLineage: { candidateData, current in
        try Self.validateLineage(candidateData: candidateData, current: current)
      }
    )
  }

  public func loadCurrent() throws -> StoredSharedEpisodeGeneration? {
    let stored = try translateStoreErrors {
      try contentStore.loadCurrent()
    }
    guard let stored else { return nil }
    return StoredSharedEpisodeGeneration(
      generationSHA256: stored.generationSHA256,
      generation: try SharedEpisodeGeneration.decodeCanonical(stored.canonicalData)
    )
  }

  public func commit(
    _ generation: SharedEpisodeGeneration
  ) throws -> StoredSharedEpisodeGeneration {
    try SharedEpisodeMemoryReducer.validate(generation)
    let canonicalData = try generation.canonicalJSONData()
    let stored = try translateStoreErrors {
      try contentStore.commit(
        canonicalData,
        expectedPreviousGenerationSHA256: generation.previousGenerationSHA256
      )
    }
    return StoredSharedEpisodeGeneration(
      generationSHA256: stored.generationSHA256,
      generation: try SharedEpisodeGeneration.decodeCanonical(stored.canonicalData)
    )
  }

  private static func validateLineage(
    candidateData: Data,
    current: StoredContentAddressedGeneration?
  ) throws {
    let candidate = try SharedEpisodeGeneration.decodeCanonical(candidateData)
    guard let current else {
      guard candidate.previousGenerationSHA256 == nil,
        candidate.seed.predecessorTerminalGenerationSHA256 == nil,
        candidate.eventJournal.entries.isEmpty,
        candidate.state.contributions.isEmpty,
        candidate.state.verifications.isEmpty
      else {
        throw SharedEpisodeMemoryError.incompatibleGeneration(
          "Первое подтверждённое поколение должно быть безвкладовым foundation."
        )
      }
      return
    }

    let previous = try SharedEpisodeGeneration.decodeCanonical(current.canonicalData)
    guard candidate.previousGenerationSHA256 == current.generationSHA256 else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Преемник не закрепляет точный хэш CURRENT."
      )
    }
    if candidate.eventJournal.entries.isEmpty {
      let previousPackage = previous.seed.artifacts.first(where: {
        $0.artifactID == previous.seed.activeWorkPackageArtifactID
      })
      let candidatePackage = candidate.seed.artifacts.first(where: {
        $0.artifactID == candidate.seed.activeWorkPackageArtifactID
      })
      guard previous.state.terminal != nil,
        candidate.state.terminal == nil,
        candidate.state.contributions.isEmpty,
        candidate.state.verifications.isEmpty,
        candidate.seed.predecessorTerminalGenerationSHA256
          == current.generationSHA256,
        candidate.seed.episodeID == previous.seed.episodeID,
        candidate.seed.runGenerationID != previous.seed.runGenerationID,
        candidate.seed.activeWorkPackageArtifactID
          != previous.seed.activeWorkPackageArtifactID,
        let previousPackage,
        let candidatePackage,
        previousPackage.contentSHA256 != candidatePackage.contentSHA256
      else {
        throw SharedEpisodeMemoryError.incompatibleGeneration(
          "Новый semantic run требует терминального CURRENT, точную ссылку и другой прошедший preflight рабочий пакет."
        )
      }
      return
    }

    guard candidate.seed == previous.seed else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Преемник изменяет подтверждённый паспорт или рабочие артефакты."
      )
    }
    guard candidate.eventJournal.entries.count == previous.eventJournal.entries.count + 1,
      Array(
        candidate.eventJournal.entries.prefix(previous.eventJournal.entries.count)
      ) == previous.eventJournal.entries,
      candidate.eventJournal.entries.last?.event.parentGenerationSHA256
        == current.generationSHA256
    else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Преемник должен добавить ровно одно событие к точному родителю."
      )
    }
  }

  private func translateStoreErrors<T>(_ body: () throws -> T) throws -> T {
    do {
      return try body()
    } catch let error as SharedEpisodeMemoryError {
      throw error
    } catch let error as ContentAddressedGenerationStoreError {
      switch error {
      case .incompatibleGeneration(let message):
        throw SharedEpisodeMemoryError.incompatibleGeneration(message)
      case .corruptGeneration(let message):
        throw SharedEpisodeMemoryError.corruptGeneration(message)
      case .generationConflict(let expected, let actual):
        throw SharedEpisodeMemoryError.generationConflict(
          expected: expected,
          actual: actual
        )
      case .generationStore(let message):
        throw SharedEpisodeMemoryError.generationStore(message)
      }
    } catch {
      throw SharedEpisodeMemoryError.generationStore(
        "Необработанная ошибка файлового протокола."
      )
    }
  }
}

public enum SharedEpisodeContributionFixture:
  String, CaseIterable, Codable, Equatable, Sendable
{
  case primary
  case adversarial
}

public enum SharedEpisodeMemoryFixtures {
  public static func seed(
    controlPlan: SharedEpisodeControlPlan = .fixtureDefault
  ) throws -> SharedEpisodeMemorySeed {
    let workPackageSource = try WorkPackageFixtures.load(named: "ready")
    let workspaceRoot = try WorkPackageFixtures.workspaceRoot()
    let requirements = try Data(
      contentsOf: workspaceRoot.appendingPathComponent("inputs/requirements.txt"),
      options: [.mappedIfSafe]
    )

    let requirementsArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "input.requirements",
      kind: "work_package_input",
      logicalPath: "inputs/requirements.txt",
      mediaType: "text/plain;charset=utf-8",
      data: requirements
    )
    let primaryManifest = try fixtureInputManifest(
      identifier: "manifest.primary",
      input: requirementsArtifact
    )
    let adversarialManifest = try fixtureInputManifest(
      identifier: "manifest.adversarial",
      input: requirementsArtifact
    )
    let primaryPackage = try fixtureWorkPackage(
      identifier: "package.primary",
      source: workPackageSource,
      workspaceRoot: workspaceRoot
    )
    let adversarialPackage = try fixtureWorkPackage(
      identifier: "package.adversarial",
      source: workPackageSource,
      workspaceRoot: workspaceRoot
    )
    let primaryPackageArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "package.primary",
      kind: "work_package",
      logicalPath: "work-packages/primary.json",
      mediaType: "application/json",
      data: primaryPackage
    )
    let adversarialPackageArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "package.adversarial",
      kind: "work_package",
      logicalPath: "work-packages/adversarial.json",
      mediaType: "application/json",
      data: adversarialPackage
    )
    let primaryManifestArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "manifest.primary",
      kind: "input_manifest",
      logicalPath: "input-manifests/primary.json",
      mediaType: "application/json",
      data: primaryManifest
    )
    let adversarialManifestArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "manifest.adversarial",
      kind: "input_manifest",
      logicalPath: "input-manifests/adversarial.json",
      mediaType: "application/json",
      data: adversarialManifest
    )
    let contributionContentSHA256 = CanonicalMemoryJSON.sha256(
      try fixtureContributionContent().canonicalJSONData()
    )
    let instrumentObservationSHA256 = CanonicalMemoryJSON.sha256(
      try fixtureInstrumentObservation().canonicalJSONData()
    )
    let criteriaArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "criteria.main",
      kind: "criteria",
      logicalPath: "verification/criteria.json",
      mediaType: "application/json",
      data: try fixtureVerificationCriteria().canonicalJSONData()
    )
    let verificationPlanArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "verification.main",
      kind: "verification",
      logicalPath: "verification/plan.json",
      mediaType: "application/json",
      data: try fixtureVerificationPlan().canonicalJSONData()
    )
    let selectionPolicyArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "selection.main",
      kind: "selection",
      logicalPath: "control/selection-policy.json",
      mediaType: "application/json",
      data: try controlPlan.canonicalJSONData()
    )
    let stopPolicyArtifact = SharedEpisodeEmbeddedArtifact(
      artifactID: "stop.main",
      kind: "stop",
      logicalPath: "control/stop-policy.json",
      mediaType: "application/json",
      data: try controlPlan.canonicalJSONData()
    )
    let passport = try fixturePassport(
      source: EpisodePassportFixtures.load(named: "valid"),
      artifactSHA256ByID: [
        primaryPackageArtifact.artifactID: primaryPackageArtifact.contentSHA256,
        adversarialPackageArtifact.artifactID: adversarialPackageArtifact.contentSHA256,
        primaryManifestArtifact.artifactID: primaryManifestArtifact.contentSHA256,
        adversarialManifestArtifact.artifactID: adversarialManifestArtifact.contentSHA256,
        "contribution.primary": contributionContentSHA256,
        "contribution.adversarial": contributionContentSHA256,
        "observation.compiler": instrumentObservationSHA256,
        criteriaArtifact.artifactID: criteriaArtifact.contentSHA256,
        verificationPlanArtifact.artifactID: verificationPlanArtifact.contentSHA256,
        selectionPolicyArtifact.artifactID: selectionPolicyArtifact.contentSHA256,
        stopPolicyArtifact.artifactID: stopPolicyArtifact.contentSHA256,
      ]
    )
    let passportReport = EpisodePassportPreflight.analyze(passport)
    guard case .valid = passportReport.decision,
      let episodeID = passportReport.episodeID
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Встроенный паспорт эпизода не прошёл предпусковую проверку."
      )
    }

    let artifacts = [
      SharedEpisodeEmbeddedArtifact(
        artifactID: "passport.valid",
        kind: "episode_passport",
        logicalPath: "passport/valid.json",
        mediaType: "application/json",
        data: passport
      ),
      primaryPackageArtifact,
      adversarialPackageArtifact,
      primaryManifestArtifact,
      adversarialManifestArtifact,
      criteriaArtifact,
      requirementsArtifact,
      selectionPolicyArtifact,
      stopPolicyArtifact,
      verificationPlanArtifact,
    ].sorted { $0.artifactID < $1.artifactID }
    let manifest = SharedEpisodeArtifactManifest(
      schemaVersion: 1,
      artifacts: artifacts
    )
    let manifestSHA256 = CanonicalMemoryJSON.sha256(
      try manifest.canonicalJSONData()
    )
    let passportArtifact = try requiredArtifact(
      "passport.valid",
      in: artifacts
    )
    let seed = SharedEpisodeMemorySeed(
      episodeID: episodeID,
      controlPlan: controlPlan,
      passportArtifactID: passportArtifact.artifactID,
      passportSHA256: passportArtifact.contentSHA256,
      artifactManifestSHA256: manifestSHA256,
      artifacts: artifacts
    )
    _ = try validateSharedEpisodeSeed(seed)
    return seed
  }

  public static func contribution(
    named fixture: SharedEpisodeContributionFixture,
    parentGenerationSHA256: String
  ) throws -> SharedEpisodeContribution {
    guard isSharedEpisodeSHA256(parentGenerationSHA256) else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Родительский SHA-256 имеет недопустимый формат."
      )
    }
    let content = fixtureContributionContent()
    let contentSHA256 = CanonicalMemoryJSON.sha256(
      try content.canonicalJSONData()
    )
    let roleID: String
    let packageID: String
    let manifestID: String
    let contributionID: String
    let hypothesisID: String
    let executorID: String
    let modelID: String
    let modelCorrelationID: String
    let observation: SharedEpisodeInstrumentObservation?
    switch fixture {
    case .primary:
      roleID = "producer.primary"
      packageID = "package.primary"
      manifestID = "manifest.primary"
      contributionID = "contribution.primary"
      hypothesisID = "hypothesis.primary"
      executorID = "executor.primary"
      modelID = "model.fixture.primary"
      modelCorrelationID = "correlation.model.primary"
      observation = fixtureInstrumentObservation()
    case .adversarial:
      roleID = "producer.adversarial"
      packageID = "package.adversarial"
      manifestID = "manifest.adversarial"
      contributionID = "contribution.adversarial"
      hypothesisID = "hypothesis.adversarial"
      executorID = "executor.adversarial"
      modelID = "model.fixture.adversarial"
      modelCorrelationID = "correlation.model.adversarial"
      observation = nil
    }
    let seed = try seed()
    let artifactsByID = Dictionary(
      uniqueKeysWithValues: seed.artifacts.map { ($0.artifactID, $0) }
    )
    guard let packageArtifact = artifactsByID[packageID],
      let inputArtifact = artifactsByID["input.requirements"]
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Фикстура вклада не нашла свои хэшированные рабочие входы."
      )
    }
    let providerID = "provider.fixture"
    let modelBasisSHA256 = CanonicalMemoryJSON.sha256(
      Data("\(providerID):\(modelID)".utf8)
    )
    let providerBasisSHA256 = CanonicalMemoryJSON.sha256(Data(providerID.utf8))
    let systemTemplateSHA256 = CanonicalMemoryJSON.sha256(
      Data("fixture-system-template-v1".utf8)
    )
    let observations = observation.map { [$0] } ?? []
    let derivedObservationIDs = observation.map { [$0.observationID] } ?? []
    return SharedEpisodeContribution(
      contributionID: contributionID,
      parentGenerationSHA256: parentGenerationSHA256,
      contributor: SharedEpisodeContributor(kind: .author, identifier: executorID),
      contentSHA256: contentSHA256,
      content: content,
      origin: SharedEpisodeContributionOrigin(
        roleID: roleID,
        workPackageArtifactID: packageID,
        inputManifestArtifactID: manifestID,
        contributionArtifactID: contributionID,
        hypothesisIDs: [hypothesisID]
      ),
      provenance: SharedEpisodeContributionProvenance(
        contributionID: contributionID,
        executorID: executorID,
        roleID: roleID,
        workPackageArtifactID: packageID,
        modelID: modelID,
        providerID: providerID,
        taskSHA256: packageArtifact.contentSHA256,
        localInputSHA256s: [inputArtifact.contentSHA256],
        parentGenerationSHA256: parentGenerationSHA256,
        resultSHA256: contentSHA256,
        correlationLinks: [
          SharedEpisodeCorrelationLink(
            groupID: modelCorrelationID,
            kind: .model,
            basisSHA256: modelBasisSHA256,
            sourceContributionID: nil
          ),
          SharedEpisodeCorrelationLink(
            groupID: "correlation.provider.fixture",
            kind: .provider,
            basisSHA256: providerBasisSHA256,
            sourceContributionID: nil
          ),
          SharedEpisodeCorrelationLink(
            groupID: "correlation.source.requirements",
            kind: .sourceMaterial,
            basisSHA256: inputArtifact.contentSHA256,
            sourceContributionID: nil
          ),
          SharedEpisodeCorrelationLink(
            groupID: "correlation.template.fixture",
            kind: .systemTemplate,
            basisSHA256: systemTemplateSHA256,
            sourceContributionID: nil
          ),
        ],
        instrumentObservations: observations,
        derivedFromObservationIDs: derivedObservationIDs
      )
    )
  }

  public static func correlatedCopy(
    index: Int,
    parentGenerationSHA256: String
  ) throws -> SharedEpisodeContribution {
    guard index >= 1 else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Индекс коррелированной копии должен быть положительным."
      )
    }
    let source = try contribution(
      named: .adversarial,
      parentGenerationSHA256: parentGenerationSHA256
    )
    let contributionID = "contribution.correlated-copy.\(index)"
    let provenance = SharedEpisodeContributionProvenance(
      schemaVersion: source.provenance.schemaVersion,
      contributionID: contributionID,
      executorID: source.provenance.executorID,
      roleID: source.provenance.roleID,
      workPackageArtifactID: source.provenance.workPackageArtifactID,
      modelID: source.provenance.modelID,
      providerID: source.provenance.providerID,
      taskSHA256: source.provenance.taskSHA256,
      localInputSHA256s: source.provenance.localInputSHA256s,
      parentGenerationSHA256: parentGenerationSHA256,
      resultSHA256: source.provenance.resultSHA256,
      correlationLinks: source.provenance.correlationLinks,
      instrumentObservations: [],
      derivedFromObservationIDs: []
    )
    return SharedEpisodeContribution(
      schemaVersion: source.schemaVersion,
      contributionID: contributionID,
      parentGenerationSHA256: parentGenerationSHA256,
      contributor: source.contributor,
      contentSHA256: source.contentSHA256,
      content: source.content,
      origin: source.origin,
      provenance: provenance
    )
  }

  public static func verification(
    named fixture: SharedEpisodeVerificationFixture,
    parentGenerationSHA256: String
  ) throws -> SharedEpisodeVerificationRecord {
    guard isSharedEpisodeSHA256(parentGenerationSHA256) else {
      throw SharedEpisodeMemoryError.invalidVerification(
        "Родительский SHA-256 проверки имеет недопустимый формат."
      )
    }
    let seed = try seed()
    let artifactsByID = Dictionary(
      uniqueKeysWithValues: seed.artifacts.map { ($0.artifactID, $0) }
    )
    guard let criteriaArtifact = artifactsByID["criteria.main"],
      let planArtifact = artifactsByID["verification.main"]
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Фикстура проверки не нашла закреплённые критерии и план."
      )
    }
    let criteria = try decodeExactCanonical(
      SharedEpisodeVerificationCriteriaDocument.self,
      data: criteriaArtifact.decodedData(),
      kind: "критерии фикстуры проверки"
    )
    let plan = try decodeExactCanonical(
      SharedEpisodeVerificationPlan.self,
      data: planArtifact.decodedData(),
      kind: "план фикстуры проверки"
    )
    let targetResultSHA256 = CanonicalMemoryJSON.sha256(
      try fixtureContributionContent().canonicalJSONData()
    )
    let claim = SharedEpisodeVerificationClaim(
      claimID: "claim.primary",
      contributionID: "contribution.primary",
      resultSHA256: targetResultSHA256
    )
    let observation = fixtureInstrumentObservation()
    let observationSHA256 = CanonicalMemoryJSON.sha256(
      try observation.canonicalJSONData()
    )

    let recordSuffix: String
    let outcome: SharedEpisodeVerificationOutcome
    let findings: [(SharedEpisodeVerificationCriterion, SharedEpisodeVerificationEvidenceFinding)]
    let disagreements: [SharedEpisodeVerificationDisagreement]
    switch fixture {
    case .externalPassed:
      recordSuffix = "external-passed"
      outcome = .passed
      findings = criteria.criteria.map { ($0, .supports) }
      disagreements = []
    case .selfPassed:
      recordSuffix = "self-passed"
      outcome = .passed
      findings = criteria.criteria.map { ($0, .supports) }
      disagreements = []
    case .correlatedPassed:
      recordSuffix = "correlated-passed"
      outcome = .passed
      findings = criteria.criteria.map { ($0, .supports) }
      disagreements = []
    case .inconclusive:
      recordSuffix = "inconclusive"
      outcome = .inconclusive
      findings = [(criteria.criteria[0], .insufficient)]
      disagreements = []
    case .failed:
      recordSuffix = "failed"
      outcome = .failed
      findings = [(criteria.criteria[2], .contradicts)]
      disagreements = [
        SharedEpisodeVerificationDisagreement(
          disagreementID: "disagreement.claim-conflict",
          claimID: claim.claimID,
          kind: .claimConflict,
          statement: "Инструментальное наблюдение противоречит проверяемому утверждению."
        ),
        SharedEpisodeVerificationDisagreement(
          disagreementID: "disagreement.negative-result",
          claimID: claim.claimID,
          kind: .negativeResult,
          statement: "Отрицательный результат сохранён независимо от последующего решения."
        ),
        SharedEpisodeVerificationDisagreement(
          disagreementID: "disagreement.objection",
          claimID: claim.claimID,
          kind: .objection,
          statement: "Проверяющий возражает против принятия утверждения без оговорки."
        ),
        SharedEpisodeVerificationDisagreement(
          disagreementID: "disagreement.rejection-reason",
          claimID: claim.claimID,
          kind: .rejectionReason,
          statement: "Утверждение отклонено из-за противоречащего внешнего наблюдения."
        ),
      ]
    }

    let evidence = findings.map { criterion, finding in
      SharedEpisodeVerificationEvidence(
        evidenceID: "evidence.\(recordSuffix).\(criterion.criterionID)",
        claimID: claim.claimID,
        criterionID: criterion.criterionID,
        observationID: observation.observationID,
        observationSHA256: observationSHA256,
        resultSHA256: observation.resultSHA256,
        finding: finding
      )
    }.sorted { $0.evidenceID < $1.evidenceID }
    let content = SharedEpisodeVerificationContent(
      verificationPlanArtifactID: plan.verificationPlanArtifactID,
      criterionIDs: plan.criterionIDs,
      claims: [claim],
      evidence: evidence,
      outcome: outcome,
      disagreements: disagreements.sorted { $0.disagreementID < $1.disagreementID }
    )
    let contentSHA256 = CanonicalMemoryJSON.sha256(try content.canonicalJSONData())
    let recordID = "verification.record.\(recordSuffix)"

    let executorID: String
    let modelID: String
    let providerID: String
    let modelGroupID: String
    let providerGroupID: String
    switch fixture {
    case .selfPassed:
      executorID = "executor.primary"
      modelID = "model.fixture.verifier.self"
      providerID = "provider.verifier.self"
      modelGroupID = "correlation.model.verifier.self"
      providerGroupID = "correlation.provider.verifier.self"
    case .correlatedPassed:
      executorID = "executor.verifier.correlated"
      modelID = "model.fixture.verifier.correlated"
      providerID = "provider.fixture"
      modelGroupID = "correlation.model.verifier.correlated"
      providerGroupID = "correlation.provider.fixture"
    case .externalPassed, .inconclusive, .failed:
      executorID = "executor.verifier.external"
      modelID = "model.fixture.verifier.external"
      providerID = "provider.verifier.external"
      modelGroupID = "correlation.model.verifier.external"
      providerGroupID = "correlation.provider.verifier.external"
    }
    let modelBasisSHA256 = CanonicalMemoryJSON.sha256(
      Data("\(providerID):\(modelID)".utf8)
    )
    let correlationLinks = [
      SharedEpisodeCorrelationLink(
        groupID: modelGroupID,
        kind: .model,
        basisSHA256: modelBasisSHA256
      ),
      SharedEpisodeCorrelationLink(
        groupID: providerGroupID,
        kind: .provider,
        basisSHA256: CanonicalMemoryJSON.sha256(Data(providerID.utf8))
      ),
      SharedEpisodeCorrelationLink(
        groupID: "correlation.source.verification-criteria",
        kind: .sourceMaterial,
        basisSHA256: criteriaArtifact.contentSHA256
      ),
      SharedEpisodeCorrelationLink(
        groupID: "correlation.source.verification-plan",
        kind: .sourceMaterial,
        basisSHA256: planArtifact.contentSHA256
      ),
      SharedEpisodeCorrelationLink(
        groupID: "correlation.template.verifier.fixture",
        kind: .systemTemplate,
        basisSHA256: CanonicalMemoryJSON.sha256(Data("fixture-verifier-template-v1".utf8))
      ),
    ].sorted { left, right in
      if left.groupID != right.groupID { return left.groupID < right.groupID }
      return left.kind.rawValue < right.kind.rawValue
    }
    return SharedEpisodeVerificationRecord(
      recordID: recordID,
      parentGenerationSHA256: parentGenerationSHA256,
      verifier: SharedEpisodeContributor(kind: .author, identifier: executorID),
      contentSHA256: contentSHA256,
      content: content,
      provenance: SharedEpisodeVerificationProvenance(
        recordID: recordID,
        executorID: executorID,
        roleID: plan.verifierRoleID,
        verificationPlanArtifactID: plan.verificationPlanArtifactID,
        modelID: modelID,
        providerID: providerID,
        taskSHA256: planArtifact.contentSHA256,
        localInputSHA256s: [
          criteriaArtifact.contentSHA256,
          planArtifact.contentSHA256,
        ].sorted(),
        parentGenerationSHA256: parentGenerationSHA256,
        resultSHA256: contentSHA256,
        correlationLinks: correlationLinks
      )
    )
  }

  private static func fixtureInputManifest(
    identifier: String,
    input: SharedEpisodeEmbeddedArtifact
  ) throws -> Data {
    try SharedEpisodeFixtureInputManifest(
      schemaVersion: 1,
      manifestID: identifier,
      inputs: [
        SharedEpisodeFixtureInputManifestEntry(
          artifactID: input.artifactID,
          logicalPath: input.logicalPath,
          sha256: input.contentSHA256
        )
      ]
    ).canonicalJSONData()
  }

  private static func fixtureContributionContent() -> SharedEpisodeContributionContent {
    SharedEpisodeContributionContent(
      mediaType: "text/plain;charset=utf-8",
      body: "Одинаковое наблюдаемое содержание двух различимых вкладов."
    )
  }

  private static func fixtureVerificationCriteria()
    -> SharedEpisodeVerificationCriteriaDocument
  {
    SharedEpisodeVerificationCriteriaDocument(
      criteriaArtifactID: "criteria.main",
      criteria: [
        SharedEpisodeVerificationCriterion(
          criterionID: "criterion.form",
          kind: .form,
          statement: "Каноническая форма и типизированные ссылки проверки замкнуты."
        ),
        SharedEpisodeVerificationCriterion(
          criterionID: "criterion.instrumental-fact",
          kind: .instrumentalFact,
          statement: "Инструментальный факт закреплён точным наблюдением и его SHA-256."
        ),
        SharedEpisodeVerificationCriterion(
          criterionID: "criterion.semantic-assessment",
          kind: .semanticAssessment,
          statement: "Семантическая оценка явно отделена от машинно подтверждаемого факта."
        ),
      ]
    )
  }

  private static func fixtureVerificationPlan() -> SharedEpisodeVerificationPlan {
    SharedEpisodeVerificationPlan(
      verificationPlanArtifactID: "verification.main",
      verifierRoleID: "verifier.main",
      criteriaArtifactID: "criteria.main",
      criterionIDs: [
        "criterion.form",
        "criterion.instrumental-fact",
        "criterion.semantic-assessment",
      ],
      allowedContributionIDs: [
        "contribution.adversarial",
        "contribution.primary",
      ],
      allowedObservationIDs: ["observation.compiler"],
      forbiddenCorrelationGroupIDs: [
        "correlation.model.adversarial",
        "correlation.model.primary",
        "correlation.provider.fixture",
        "correlation.source.requirements",
        "correlation.template.fixture",
      ]
    )
  }

  private static func fixtureInstrumentObservation() -> SharedEpisodeInstrumentObservation {
    SharedEpisodeInstrumentObservation(
      observationID: "observation.compiler",
      sourceAuthority: .localTool,
      callID: "call.fixture.primary.1",
      inputSHA256: CanonicalMemoryJSON.sha256(Data("fixture-tool-input".utf8)),
      resultSHA256: CanonicalMemoryJSON.sha256(Data("fixture-tool-result".utf8)),
      observedAtSeconds: 1_780_000_002
    )
  }

  private static func fixtureWorkPackage(
    identifier: String,
    source: Data,
    workspaceRoot: URL
  ) throws -> Data {
    guard var root = try JSONSerialization.jsonObject(with: source) as? [String: Any] else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Встроенная фикстура рабочего пакета не является JSON-объектом."
      )
    }
    root["package_id"] = identifier
    let serialized = try JSONSerialization.data(
      withJSONObject: root,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let canonical = try CanonicalMemoryJSON.canonicalize(serialized)
    let report = WorkPackagePreflight.analyze(
      canonical,
      workspaceRoot: workspaceRoot
    )
    guard case .ready = report.decision, report.packageID == identifier else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Рабочий пакет \(identifier) не прошёл предпусковую проверку."
      )
    }
    return canonical
  }

  private static func fixturePassport(
    source: Data,
    artifactSHA256ByID: [String: String]
  ) throws -> Data {
    guard var root = try JSONSerialization.jsonObject(with: source) as? [String: Any],
      var artifacts = root["artifacts"] as? [[String: Any]]
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Встроенная фикстура паспорта не содержит реестр артефактов."
      )
    }
    var rebound = Set<String>()
    for index in artifacts.indices {
      guard let identifier = artifacts[index]["artifact_id"] as? String,
        let sha256 = artifactSHA256ByID[identifier]
      else {
        continue
      }
      artifacts[index]["sha256"] = sha256
      rebound.insert(identifier)
    }
    guard rebound == Set(artifactSHA256ByID.keys) else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Паспорт не объявляет все рабочие пакеты и входные манифесты."
      )
    }
    root["artifacts"] = artifacts
    let serialized = try JSONSerialization.data(
      withJSONObject: root,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    return try CanonicalMemoryJSON.canonicalize(serialized)
  }

  private static func requiredArtifact(
    _ identifier: String,
    in artifacts: [SharedEpisodeEmbeddedArtifact]
  ) throws -> SharedEpisodeEmbeddedArtifact {
    guard let artifact = artifacts.first(where: { $0.artifactID == identifier }) else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Встроенный артефакт \(identifier) отсутствует."
      )
    }
    return artifact
  }
}

struct SharedEpisodeArtifactManifest:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  let schemaVersion: Int
  let artifacts: [SharedEpisodeEmbeddedArtifact]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case artifacts
  }
}

struct SharedEpisodeFixtureInputManifest:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  let schemaVersion: Int
  let manifestID: String
  let inputs: [SharedEpisodeFixtureInputManifestEntry]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case manifestID = "manifest_id"
    case inputs
  }
}

struct SharedEpisodeFixtureInputManifestEntry:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  let artifactID: String
  let logicalPath: String
  let sha256: String

  enum CodingKeys: String, CodingKey {
    case artifactID = "artifact_id"
    case logicalPath = "logical_path"
    case sha256
  }
}

private struct SharedEpisodePassportContribution {
  let roleID: String
  let workPackageArtifactID: String
  let inputManifestArtifactID: String
  let contributionArtifactID: String
  let hypothesisIDs: [String]
}

private struct SharedEpisodePassportArtifactDeclaration {
  let kind: String
  let sha256: String
}

private struct SharedEpisodePassportObservation {
  let artifactID: String
  let contributionID: String
}

private struct SharedEpisodePassportVerification {
  let artifactID: String
  let roleID: String
  let contributionIDs: [String]
  let observationIDs: [String]
}

private struct SharedEpisodePassportSelection {
  let artifactID: String
  let roleID: String
  let verificationID: String
  let consideredContributionIDs: [String]
  let basis: String
}

private struct SharedEpisodePassportStop {
  let artifactID: String
  let selectionID: String
}

private struct SharedEpisodePassportEvidencePolicy {
  let agreementIsEvidence: Bool
  let independenceInferredFromCount: Bool
}

private struct SharedEpisodeInputBinding: Hashable {
  let artifactID: String
  let logicalPath: String
  let sha256: String
}

private struct SharedEpisodePassportIndex {
  let artifacts: [String: SharedEpisodePassportArtifactDeclaration]
  let criteriaArtifactID: String
  let roles: [String: String]
  let contributions: [String: SharedEpisodePassportContribution]
  let observations: [String: SharedEpisodePassportObservation]
  let verification: SharedEpisodePassportVerification
  let selection: SharedEpisodePassportSelection
  let stop: SharedEpisodePassportStop
  let evidencePolicy: SharedEpisodePassportEvidencePolicy
}

private struct SharedEpisodeSeedContext {
  let artifactsByID: [String: SharedEpisodeEmbeddedArtifact]
  let passportArtifacts: [String: SharedEpisodePassportArtifactDeclaration]
  let passportRoles: [String: String]
  let passportContributions: [String: SharedEpisodePassportContribution]
  let passportObservations: [String: SharedEpisodePassportObservation]
  let criteriaDocument: SharedEpisodeVerificationCriteriaDocument
  let verificationPlan: SharedEpisodeVerificationPlan
  let packageInputsByID: [String: Set<SharedEpisodeInputBinding>]
  let manifestInputsByID: [String: Set<SharedEpisodeInputBinding>]
}

private func validateSharedEpisodeSeed(
  _ seed: SharedEpisodeMemorySeed
) throws -> SharedEpisodeSeedContext {
  guard seed.schemaVersion == SharedEpisodeMemorySeed.currentSchemaVersion,
    isSharedEpisodeIdentifier(seed.episodeID),
    isSharedEpisodeIdentifier(seed.runGenerationID),
    isSharedEpisodeIdentifier(seed.activeWorkPackageArtifactID),
    seed.predecessorTerminalGenerationSHA256.map(isSharedEpisodeSHA256) ?? true,
    isSharedEpisodeIdentifier(seed.passportArtifactID),
    isSharedEpisodeSHA256(seed.passportSHA256),
    isSharedEpisodeSHA256(seed.artifactManifestSHA256),
    !seed.artifacts.isEmpty,
    seed.artifacts.count <= 64
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Схема, идентификаторы, хэши или размер реестра недопустимы."
    )
  }
  guard seed.artifacts.map(\.artifactID) == seed.artifacts.map(\.artifactID).sorted(),
    Set(seed.artifacts.map(\.artifactID)).count == seed.artifacts.count,
    Set(seed.artifacts.map(\.logicalPath)).count == seed.artifacts.count
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Артефакты должны быть уникальны и отсортированы по идентификатору."
    )
  }

  guard
    let activePackage = seed.artifacts.first(where: {
      $0.artifactID == seed.activeWorkPackageArtifactID
    }), activePackage.kind == "work_package"
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Активный рабочий пакет не встроен в seed как work_package."
    )
  }

  var artifactsByID: [String: SharedEpisodeEmbeddedArtifact] = [:]
  var artifactsByPath: [String: SharedEpisodeEmbeddedArtifact] = [:]
  var totalBytes = 0
  for artifact in seed.artifacts {
    guard artifact.schemaVersion == 1,
      isSharedEpisodeIdentifier(artifact.artifactID),
      isSharedEpisodeIdentifier(artifact.kind),
      isSafeSharedEpisodePath(artifact.logicalPath),
      !artifact.mediaType.isEmpty,
      artifact.mediaType.utf8.count <= 128,
      isSharedEpisodeSHA256(artifact.contentSHA256),
      let data = Data(base64Encoded: artifact.contentBase64),
      data.base64EncodedString() == artifact.contentBase64,
      CanonicalMemoryJSON.sha256(data) == artifact.contentSHA256,
      data.count <= 1_048_576
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Артефакт \(artifact.artifactID) нарушает схему, путь, Base64, хэш или лимит."
      )
    }
    totalBytes += data.count
    guard totalBytes <= 4_194_304 else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Совокупный размер встроенных артефактов превышает 4 МиБ."
      )
    }
    artifactsByID[artifact.artifactID] = artifact
    artifactsByPath[artifact.logicalPath] = artifact
  }

  let manifest = SharedEpisodeArtifactManifest(
    schemaVersion: 1,
    artifacts: seed.artifacts
  )
  guard
    CanonicalMemoryJSON.sha256(try manifest.canonicalJSONData())
      == seed.artifactManifestSHA256
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Хэш манифеста не выводится из встроенных артефактов."
    )
  }
  guard let passportArtifact = artifactsByID[seed.passportArtifactID],
    passportArtifact.kind == "episode_passport",
    passportArtifact.contentSHA256 == seed.passportSHA256,
    let passportData = Data(base64Encoded: passportArtifact.contentBase64)
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Seed не закрепляет точный встроенный паспорт."
    )
  }
  do {
    try CanonicalMemoryJSON.requireCanonical(passportData)
  } catch {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не соответствует общему каноническому профилю."
    )
  }
  let passportReport = EpisodePassportPreflight.analyze(passportData)
  guard case .valid = passportReport.decision,
    passportReport.episodeID == seed.episodeID,
    passportReport.passportSHA256 == seed.passportSHA256
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный паспорт недействителен или относится к другому эпизоду."
    )
  }

  let passportIndex = try sharedEpisodePassportIndex(passportData)
  try SharedEpisodeControlKernel.validatePlan(seed.controlPlan)
  let controlPlanData = try seed.controlPlan.canonicalJSONData()
  let controlPlanSHA256 = CanonicalMemoryJSON.sha256(controlPlanData)
  for (artifactID, kind) in [
    (seed.controlPlan.selectionPlanArtifactID, "selection"),
    (seed.controlPlan.stopPolicyID, "stop"),
  ] {
    guard let artifact = artifactsByID[artifactID],
      artifact.kind == kind,
      artifact.contentSHA256 == controlPlanSHA256,
      try artifact.decodedData() == controlPlanData,
      let declaration = passportIndex.artifacts[artifactID],
      declaration.kind == kind,
      declaration.sha256 == controlPlanSHA256
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Политика \(artifactID) не встроена в seed и паспорт точными каноническими байтами."
      )
    }
  }
  guard
    passportIndex.selection.artifactID
      == seed.controlPlan.selectionPlanArtifactID,
    passportIndex.selection.roleID == seed.controlPlan.selectorRoleID,
    passportIndex.selection.roleID == seed.controlPlan.selectorID,
    passportIndex.selection.verificationID
      == passportIndex.verification.artifactID,
    Set(passportIndex.selection.consideredContributionIDs)
      == Set(passportIndex.contributions.keys),
    passportIndex.selection.basis == seed.controlPlan.selectionBasis.rawValue,
    passportIndex.stop.artifactID == seed.controlPlan.stopPolicyID,
    passportIndex.stop.selectionID == passportIndex.selection.artifactID,
    passportIndex.evidencePolicy.agreementIsEvidence
      == seed.controlPlan.agreementIsEvidence,
    passportIndex.evidencePolicy.independenceInferredFromCount
      == seed.controlPlan.independenceInferredFromCount
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "План управления не совпадает с закреплёнными паспортом выбором, ролью, основанием, stop-политикой и запретом голосования."
    )
  }
  var packageInputsByID: [String: Set<SharedEpisodeInputBinding>] = [:]
  var manifestInputsByID: [String: Set<SharedEpisodeInputBinding>] = [:]
  let embeddedInputsByPath = try Dictionary(
    uniqueKeysWithValues: artifactsByPath.map { path, artifact in
      (path, try artifact.decodedData())
    }
  )
  for artifact in seed.artifacts
  where artifact.kind == "work_package" || artifact.kind == "input_manifest" {
    guard let declaration = passportIndex.artifacts[artifact.artifactID],
      declaration.kind == artifact.kind,
      declaration.sha256 == artifact.contentSHA256,
      let data = Data(base64Encoded: artifact.contentBase64)
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Артефакт \(artifact.artifactID) не совпадает с точной декларацией паспорта."
      )
    }
    switch artifact.kind {
    case "work_package":
      packageInputsByID[artifact.artifactID] = try validateEmbeddedWorkPackage(
        data,
        expectedArtifactID: artifact.artifactID,
        artifactsByPath: artifactsByPath,
        embeddedInputsByPath: embeddedInputsByPath
      )
    case "input_manifest":
      manifestInputsByID[artifact.artifactID] = try validateEmbeddedInputManifest(
        data,
        expectedArtifactID: artifact.artifactID,
        artifactsByID: artifactsByID,
        artifactsByPath: artifactsByPath
      )
    default:
      break
    }
  }
  for (identifier, declaration) in passportIndex.artifacts
  where declaration.kind == "work_package" || declaration.kind == "input_manifest" {
    guard let artifact = artifactsByID[identifier],
      artifact.kind == declaration.kind,
      artifact.contentSHA256 == declaration.sha256
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Объявленный паспортом артефакт \(identifier) не встроен с точными kind и SHA-256."
      )
    }
  }
  guard seed.artifacts.contains(where: { $0.kind == "work_package" }),
    seed.artifacts.contains(where: { $0.kind == "input_manifest" })
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Seed должен встраивать рабочий пакет и его входной манифест."
    )
  }
  for provenance in passportIndex.contributions.values {
    guard
      let packageDeclaration = passportIndex.artifacts[
        provenance.workPackageArtifactID
      ],
      packageDeclaration.kind == "work_package",
      let packageArtifact = artifactsByID[provenance.workPackageArtifactID],
      packageArtifact.kind == packageDeclaration.kind,
      packageArtifact.contentSHA256 == packageDeclaration.sha256,
      let manifestDeclaration = passportIndex.artifacts[
        provenance.inputManifestArtifactID
      ],
      manifestDeclaration.kind == "input_manifest",
      let manifestArtifact = artifactsByID[provenance.inputManifestArtifactID],
      manifestArtifact.kind == manifestDeclaration.kind,
      manifestArtifact.contentSHA256 == manifestDeclaration.sha256,
      packageInputsByID[provenance.workPackageArtifactID]
        == manifestInputsByID[provenance.inputManifestArtifactID]
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Ссылочное происхождение паспорта не обеспечено точными встроенными рабочими артефактами."
      )
    }
  }

  guard
    let criteriaDeclaration = passportIndex.artifacts[
      passportIndex.criteriaArtifactID
    ],
    criteriaDeclaration.kind == "criteria",
    let criteriaArtifact = artifactsByID[passportIndex.criteriaArtifactID],
    criteriaArtifact.kind == criteriaDeclaration.kind,
    criteriaArtifact.contentSHA256 == criteriaDeclaration.sha256,
    let verificationDeclaration = passportIndex.artifacts[
      passportIndex.verification.artifactID
    ],
    verificationDeclaration.kind == "verification",
    let verificationArtifact = artifactsByID[
      passportIndex.verification.artifactID
    ],
    verificationArtifact.kind == verificationDeclaration.kind,
    verificationArtifact.contentSHA256 == verificationDeclaration.sha256
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не закрепляет точные встроенные критерии и план проверки."
    )
  }
  let criteriaDocument: SharedEpisodeVerificationCriteriaDocument
  let verificationPlan: SharedEpisodeVerificationPlan
  do {
    criteriaDocument = try decodeExactCanonical(
      SharedEpisodeVerificationCriteriaDocument.self,
      data: criteriaArtifact.decodedData(),
      kind: "встроенные критерии проверки"
    )
    verificationPlan = try decodeExactCanonical(
      SharedEpisodeVerificationPlan.self,
      data: verificationArtifact.decodedData(),
      kind: "встроенный план проверки"
    )
  } catch {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенные критерии или план проверки не соответствуют точной канонической схеме."
    )
  }
  let criterionIDs = criteriaDocument.criteria.map(\.criterionID)
  guard criteriaDocument.schemaVersion == 1,
    criteriaDocument.criteriaArtifactID == passportIndex.criteriaArtifactID,
    !criteriaDocument.criteria.isEmpty,
    criteriaDocument.criteria.count <= 64,
    criterionIDs == criterionIDs.sorted(),
    Set(criterionIDs).count == criterionIDs.count,
    criterionIDs.allSatisfy(isSharedEpisodeIdentifier),
    Set(criteriaDocument.criteria.map(\.kind))
      == Set([
        SharedEpisodeVerificationCriterionKind.form,
        .instrumentalFact,
        .semanticAssessment,
      ]),
    criteriaDocument.criteria.allSatisfy({ criterion in
      criterion.schemaVersion == 1 && !criterion.statement.isEmpty
        && criterion.statement.utf8.count <= 4_096
    }),
    verificationPlan.schemaVersion == 1,
    verificationPlan.verificationPlanArtifactID
      == passportIndex.verification.artifactID,
    verificationPlan.verifierRoleID == passportIndex.verification.roleID,
    passportIndex.roles[verificationPlan.verifierRoleID] == "verifier",
    verificationPlan.criteriaArtifactID == criteriaDocument.criteriaArtifactID,
    verificationPlan.criterionIDs == criterionIDs,
    verificationPlan.allowedContributionIDs
      == verificationPlan.allowedContributionIDs.sorted(),
    Set(verificationPlan.allowedContributionIDs).count
      == verificationPlan.allowedContributionIDs.count,
    Set(verificationPlan.allowedContributionIDs)
      == Set(passportIndex.verification.contributionIDs),
    verificationPlan.allowedObservationIDs
      == verificationPlan.allowedObservationIDs.sorted(),
    Set(verificationPlan.allowedObservationIDs).count
      == verificationPlan.allowedObservationIDs.count,
    Set(verificationPlan.allowedObservationIDs)
      == Set(passportIndex.verification.observationIDs),
    !verificationPlan.forbiddenCorrelationGroupIDs.isEmpty,
    verificationPlan.forbiddenCorrelationGroupIDs
      == verificationPlan.forbiddenCorrelationGroupIDs.sorted(),
    Set(verificationPlan.forbiddenCorrelationGroupIDs).count
      == verificationPlan.forbiddenCorrelationGroupIDs.count,
    verificationPlan.forbiddenCorrelationGroupIDs.allSatisfy(
      isSharedEpisodeIdentifier
    )
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Критерии и план проверки не совпадают с заранее объявленным паспортом."
    )
  }

  return SharedEpisodeSeedContext(
    artifactsByID: artifactsByID,
    passportArtifacts: passportIndex.artifacts,
    passportRoles: passportIndex.roles,
    passportContributions: passportIndex.contributions,
    passportObservations: passportIndex.observations,
    criteriaDocument: criteriaDocument,
    verificationPlan: verificationPlan,
    packageInputsByID: packageInputsByID,
    manifestInputsByID: manifestInputsByID
  )
}

private func validateEmbeddedWorkPackage(
  _ data: Data,
  expectedArtifactID: String,
  artifactsByPath: [String: SharedEpisodeEmbeddedArtifact],
  embeddedInputsByPath: [String: Data]
) throws -> Set<SharedEpisodeInputBinding> {
  do {
    try CanonicalMemoryJSON.requireCanonical(data)
  } catch {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный рабочий пакет не является каноническим JSON."
    )
  }
  let preflight = WorkPackagePreflight.analyze(
    data,
    embeddedInputsByPath: embeddedInputsByPath
  )
  guard preflight.decision == .ready,
    preflight.packageID == expectedArtifactID
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный рабочий пакет \(expectedArtifactID) не прошёл полный preflight по закреплённым входам."
    )
  }
  guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
    root["schema_version"] as? Int == 1,
    let packageID = root["package_id"] as? String,
    packageID == expectedArtifactID,
    let inputs = root["inputs"] as? [[String: Any]],
    !inputs.isEmpty
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный рабочий пакет не содержит обязательную схему и входы."
    )
  }
  var bindings = Set<SharedEpisodeInputBinding>()
  for input in inputs {
    guard let inputID = input["id"] as? String,
      isSharedEpisodeIdentifier(inputID),
      let path = input["path"] as? String,
      let sha256 = input["sha256"] as? String,
      isSharedEpisodeSHA256(sha256),
      let artifact = artifactsByPath[path],
      artifact.contentSHA256 == sha256,
      bindings.insert(
        SharedEpisodeInputBinding(
          artifactID: artifact.artifactID,
          logicalPath: path,
          sha256: sha256
        )
      ).inserted
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Вход рабочего пакета отсутствует или не совпадает с объявленным хэшем."
      )
    }
  }
  return bindings
}

private func validateEmbeddedInputManifest(
  _ data: Data,
  expectedArtifactID: String,
  artifactsByID: [String: SharedEpisodeEmbeddedArtifact],
  artifactsByPath: [String: SharedEpisodeEmbeddedArtifact]
) throws -> Set<SharedEpisodeInputBinding> {
  let manifest: SharedEpisodeFixtureInputManifest
  do {
    manifest = try decodeExactCanonical(
      SharedEpisodeFixtureInputManifest.self,
      data: data,
      kind: "встроенный входной манифест"
    )
  } catch {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный манифест \(expectedArtifactID) не соответствует точной схеме."
    )
  }
  guard manifest.schemaVersion == 1,
    manifest.manifestID == expectedArtifactID,
    !manifest.inputs.isEmpty,
    manifest.inputs.count <= 128,
    Set(manifest.inputs.map(\.artifactID)).count == manifest.inputs.count,
    Set(manifest.inputs.map(\.logicalPath)).count == manifest.inputs.count
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Манифест \(expectedArtifactID) имеет неверную версию, id или неоднозначные входы."
    )
  }
  var bindings = Set<SharedEpisodeInputBinding>()
  for input in manifest.inputs {
    guard isSharedEpisodeIdentifier(input.artifactID),
      isSafeSharedEpisodePath(input.logicalPath),
      isSharedEpisodeSHA256(input.sha256),
      let artifactByID = artifactsByID[input.artifactID],
      let artifactByPath = artifactsByPath[input.logicalPath],
      artifactByID == artifactByPath,
      artifactByID.logicalPath == input.logicalPath,
      artifactByID.contentSHA256 == input.sha256,
      bindings.insert(
        SharedEpisodeInputBinding(
          artifactID: input.artifactID,
          logicalPath: input.logicalPath,
          sha256: input.sha256
        )
      ).inserted
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Вход манифеста \(expectedArtifactID) не связан с теми же встроенными байтами."
      )
    }
  }
  return bindings
}

private func sharedEpisodePassportIndex(
  _ data: Data
) throws -> SharedEpisodePassportIndex {
  guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
    let artifacts = root["artifacts"] as? [[String: Any]],
    let goal = root["goal"] as? [String: Any],
    let criteriaArtifactID = goal["criteria_artifact_id"] as? String,
    let roles = root["roles"] as? [[String: Any]],
    let contributions = root["contributions"] as? [[String: Any]],
    let observations = root["observations"] as? [[String: Any]],
    let verification = root["verification"] as? [String: Any],
    let selection = root["selection"] as? [String: Any],
    let stop = root["stop"] as? [String: Any],
    let evidencePolicy = root["evidence_policy"] as? [String: Any]
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не содержит критерии, роли, реестры артефактов и проверки."
    )
  }
  var artifactIndex: [String: SharedEpisodePassportArtifactDeclaration] = [:]
  for value in artifacts {
    guard let artifactID = value["artifact_id"] as? String,
      let kind = value["kind"] as? String,
      let sha256 = value["sha256"] as? String,
      isSharedEpisodeIdentifier(artifactID),
      isSharedEpisodeIdentifier(kind),
      isSharedEpisodeSHA256(sha256),
      artifactIndex[artifactID] == nil
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Паспорт содержит неоднозначную декларацию артефакта."
      )
    }
    artifactIndex[artifactID] = SharedEpisodePassportArtifactDeclaration(
      kind: kind,
      sha256: sha256
    )
  }
  guard artifactIndex[criteriaArtifactID]?.kind == "criteria" else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не связывает цель с точным артефактом критериев."
    )
  }

  var roleIndex: [String: String] = [:]
  for value in roles {
    guard let roleID = value["role_id"] as? String,
      let kind = value["kind"] as? String,
      isSharedEpisodeIdentifier(roleID),
      ["producer", "verifier", "selector"].contains(kind),
      roleIndex[roleID] == nil
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Паспорт содержит неоднозначную роль."
      )
    }
    roleIndex[roleID] = kind
  }

  var contributionIndex: [String: SharedEpisodePassportContribution] = [:]
  for value in contributions {
    guard let contributionID = value["contribution_id"] as? String,
      let artifactID = value["artifact_id"] as? String,
      let roleID = value["role_id"] as? String,
      let packageID = value["package_id"] as? String,
      let manifestID = value["input_manifest_id"] as? String,
      let hypothesisIDs = value["hypothesis_ids"] as? [String],
      !hypothesisIDs.isEmpty,
      contributionIndex[contributionID] == nil,
      artifactIndex[artifactID]?.kind == "contribution",
      artifactIndex[packageID]?.kind == "work_package",
      artifactIndex[manifestID]?.kind == "input_manifest"
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Паспорт содержит неоднозначное происхождение вклада."
      )
    }
    contributionIndex[contributionID] = SharedEpisodePassportContribution(
      roleID: roleID,
      workPackageArtifactID: packageID,
      inputManifestArtifactID: manifestID,
      contributionArtifactID: artifactID,
      hypothesisIDs: hypothesisIDs
    )
  }
  var observationIndex: [String: SharedEpisodePassportObservation] = [:]
  for value in observations {
    guard let observationID = value["observation_id"] as? String,
      let artifactID = value["artifact_id"] as? String,
      let contributionID = value["contribution_id"] as? String,
      isSharedEpisodeIdentifier(observationID),
      observationIndex[observationID] == nil,
      artifactIndex[artifactID]?.kind == "observation",
      contributionIndex[contributionID] != nil
    else {
      throw SharedEpisodeMemoryError.invalidSeed(
        "Паспорт содержит неоднозначное инструментальное наблюдение."
      )
    }
    observationIndex[observationID] = SharedEpisodePassportObservation(
      artifactID: artifactID,
      contributionID: contributionID
    )
  }
  guard let verificationID = verification["verification_id"] as? String,
    let verificationArtifactID = verification["artifact_id"] as? String,
    verificationID == verificationArtifactID,
    artifactIndex[verificationArtifactID]?.kind == "verification",
    let verificationRoleID = verification["role_id"] as? String,
    roleIndex[verificationRoleID] == "verifier",
    let verificationContributionIDs = verification["contribution_ids"] as? [String],
    !verificationContributionIDs.isEmpty,
    Set(verificationContributionIDs).count == verificationContributionIDs.count,
    verificationContributionIDs.allSatisfy({ contributionIndex[$0] != nil }),
    let verificationObservationIDs = verification["observation_ids"] as? [String],
    !verificationObservationIDs.isEmpty,
    Set(verificationObservationIDs).count == verificationObservationIDs.count,
    verificationObservationIDs.allSatisfy({ observationIndex[$0] != nil })
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт содержит неоднозначный или незамкнутый план проверки."
    )
  }
  guard let selectionID = selection["selection_id"] as? String,
    let selectionArtifactID = selection["artifact_id"] as? String,
    selectionID == selectionArtifactID,
    artifactIndex[selectionArtifactID]?.kind == "selection",
    let selectionRoleID = selection["role_id"] as? String,
    roleIndex[selectionRoleID] == "selector",
    let selectionVerificationID = selection["verification_id"] as? String,
    selectionVerificationID == verificationArtifactID,
    let consideredContributionIDs =
      selection["considered_contribution_ids"] as? [String],
    !consideredContributionIDs.isEmpty,
    Set(consideredContributionIDs).count == consideredContributionIDs.count,
    consideredContributionIDs.allSatisfy({ contributionIndex[$0] != nil }),
    let selectionBasis = selection["basis"] as? String,
    selectionBasis == SharedEpisodeSelectionBasis.verifiedEvidence.rawValue,
    let stopID = stop["stop_id"] as? String,
    let stopArtifactID = stop["artifact_id"] as? String,
    stopID == stopArtifactID,
    artifactIndex[stopArtifactID]?.kind == "stop",
    let stopSelectionID = stop["selection_id"] as? String,
    stopSelectionID == selectionID,
    let agreementIsEvidence = evidencePolicy["agreement_is_evidence"] as? Bool,
    let independenceInferredFromCount =
      evidencePolicy["independence_inferred_from_count"] as? Bool,
    !agreementIsEvidence,
    !independenceInferredFromCount
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не замыкает выбор, роль selector, проверку, stop-политику и политику доказательств без голосования."
    )
  }
  return SharedEpisodePassportIndex(
    artifacts: artifactIndex,
    criteriaArtifactID: criteriaArtifactID,
    roles: roleIndex,
    contributions: contributionIndex,
    observations: observationIndex,
    verification: SharedEpisodePassportVerification(
      artifactID: verificationArtifactID,
      roleID: verificationRoleID,
      contributionIDs: verificationContributionIDs,
      observationIDs: verificationObservationIDs
    ),
    selection: SharedEpisodePassportSelection(
      artifactID: selectionArtifactID,
      roleID: selectionRoleID,
      verificationID: selectionVerificationID,
      consideredContributionIDs: consideredContributionIDs,
      basis: selectionBasis
    ),
    stop: SharedEpisodePassportStop(
      artifactID: stopArtifactID,
      selectionID: stopSelectionID
    ),
    evidencePolicy: SharedEpisodePassportEvidencePolicy(
      agreementIsEvidence: agreementIsEvidence,
      independenceInferredFromCount: independenceInferredFromCount
    )
  )
}

private func validateVerificationRecord(
  _ verification: SharedEpisodeVerificationRecord,
  context: SharedEpisodeSeedContext,
  contributions: [SharedEpisodeContribution],
  priorVerifications: [SharedEpisodeVerificationRecord]
) throws {
  let plan = context.verificationPlan
  let criteria = context.criteriaDocument
  guard let criteriaArtifact = context.artifactsByID[criteria.criteriaArtifactID],
    let planArtifact = context.artifactsByID[plan.verificationPlanArtifactID]
  else {
    throw SharedEpisodeMemoryError.invalidVerification(
      "Паспортные критерии или план проверки отсутствуют во встроенном снимке."
    )
  }
  _ = try SharedEpisodeVerificationValidator.analyze(
    contributions: contributions,
    verifications: priorVerifications + [verification]
  )
  let acceptedContributionIDs = Set(contributions.map(\.contributionID))
  let claimContributionIDs = Set(verification.content.claims.map(\.contributionID))
  let evidenceObservationIDs = Set(verification.content.evidence.map(\.observationID))
  let expectedLocalInputs = [
    criteriaArtifact.contentSHA256,
    planArtifact.contentSHA256,
  ].sorted()
  let modelLinks = verification.provenance.correlationLinks.filter {
    $0.kind == .model
  }
  let providerLinks = verification.provenance.correlationLinks.filter {
    $0.kind == .provider
  }
  let sourceMaterialSHA256s = Set(
    verification.provenance.correlationLinks
      .filter { $0.kind == .sourceMaterial }
      .map(\.basisSHA256)
  )
  guard context.passportRoles[verification.provenance.roleID] == "verifier",
    verification.provenance.roleID == plan.verifierRoleID,
    verification.content.verificationPlanArtifactID
      == plan.verificationPlanArtifactID,
    verification.provenance.verificationPlanArtifactID
      == plan.verificationPlanArtifactID,
    verification.content.criterionIDs == plan.criterionIDs,
    Set(plan.allowedContributionIDs).isSuperset(of: claimContributionIDs),
    acceptedContributionIDs.isSuperset(of: claimContributionIDs),
    Set(plan.allowedObservationIDs).isSuperset(of: evidenceObservationIDs),
    verification.provenance.taskSHA256 == planArtifact.contentSHA256,
    verification.provenance.localInputSHA256s == expectedLocalInputs,
    verification.provenance.modelID == nil || !modelLinks.isEmpty,
    verification.provenance.providerID == nil || !providerLinks.isEmpty,
    sourceMaterialSHA256s == Set(expectedLocalInputs)
  else {
    throw SharedEpisodeMemoryError.invalidVerification(
      "Проверка не совпадает с заранее объявленными паспортом, ролью, критериями и планом."
    )
  }

  let claimsByID = Dictionary(
    uniqueKeysWithValues: verification.content.claims.map { ($0.claimID, $0) }
  )
  for evidence in verification.content.evidence {
    guard let claim = claimsByID[evidence.claimID],
      context.passportObservations[evidence.observationID]?.contributionID
        == claim.contributionID
    else {
      throw SharedEpisodeMemoryError.invalidVerification(
        "Доказательство не связывает наблюдение с тем же проверяемым вкладом."
      )
    }
  }

  let producerCorrelationGroupIDs = Set(
    contributions.flatMap { contribution in
      contribution.provenance.correlationLinks.map(\.groupID)
    }
  )
  guard
    Set(plan.forbiddenCorrelationGroupIDs).isSuperset(
      of: producerCorrelationGroupIDs
    )
  else {
    throw SharedEpisodeMemoryError.invalidVerification(
      "План не объявляет все наблюдаемые группы корреляции производителей."
    )
  }

  if verification.content.outcome == .failed {
    let disagreementKinds = Set(verification.content.disagreements.map(\.kind))
    guard disagreementKinds.contains(.negativeResult),
      disagreementKinds.contains(.rejectionReason)
    else {
      throw SharedEpisodeMemoryError.invalidVerification(
        "Исход failed не сохраняет отрицательный результат и причину отклонения."
      )
    }
  }
}

private func validateContribution(
  _ contribution: SharedEpisodeContribution,
  context: SharedEpisodeSeedContext,
  priorProvenances: [SharedEpisodeContributionProvenance]
) throws {
  guard contribution.schemaVersion == SharedEpisodeContribution.currentSchemaVersion,
    isSharedEpisodeIdentifier(contribution.contributionID),
    isSharedEpisodeSHA256(contribution.parentGenerationSHA256),
    isSharedEpisodeIdentifier(contribution.contributor.identifier),
    contribution.content.schemaVersion == 1,
    !contribution.content.mediaType.isEmpty,
    contribution.content.mediaType.utf8.count <= 128,
    !contribution.content.body.isEmpty,
    contribution.content.body.utf8.count <= 65_536,
    isSharedEpisodeSHA256(contribution.contentSHA256),
    contribution.contentSHA256
      == CanonicalMemoryJSON.sha256(try contribution.content.canonicalJSONData()),
    isSharedEpisodeIdentifier(contribution.origin.roleID),
    isSharedEpisodeIdentifier(contribution.origin.workPackageArtifactID),
    isSharedEpisodeIdentifier(contribution.origin.inputManifestArtifactID),
    isSharedEpisodeIdentifier(contribution.origin.contributionArtifactID),
    !contribution.origin.hypothesisIDs.isEmpty,
    contribution.origin.hypothesisIDs
      == contribution.origin.hypothesisIDs.sorted(),
    Set(contribution.origin.hypothesisIDs).count
      == contribution.origin.hypothesisIDs.count,
    contribution.origin.hypothesisIDs.allSatisfy(isSharedEpisodeIdentifier)
  else {
    throw SharedEpisodeMemoryError.invalidContribution(
      "Вклад нарушает схему, хэши, ограничения или точность происхождения."
    )
  }
  _ = try SharedEpisodeProvenanceValidator.analyze(
    priorProvenances + [contribution.provenance]
  )
  guard
    let declared = context.passportContributions[
      contribution.origin.contributionArtifactID
    ],
    declared.roleID == contribution.origin.roleID,
    declared.workPackageArtifactID == contribution.origin.workPackageArtifactID,
    declared.inputManifestArtifactID == contribution.origin.inputManifestArtifactID,
    declared.contributionArtifactID == contribution.origin.contributionArtifactID,
    declared.hypothesisIDs == contribution.origin.hypothesisIDs,
    let contributionDeclaration = context.passportArtifacts[
      contribution.origin.contributionArtifactID
    ],
    contributionDeclaration.kind == "contribution",
    contributionDeclaration.sha256 == contribution.contentSHA256,
    let packageDeclaration = context.passportArtifacts[
      contribution.origin.workPackageArtifactID
    ],
    packageDeclaration.kind == "work_package",
    let packageArtifact = context.artifactsByID[
      contribution.origin.workPackageArtifactID
    ],
    packageArtifact.kind == packageDeclaration.kind,
    packageArtifact.contentSHA256 == packageDeclaration.sha256,
    let manifestDeclaration = context.passportArtifacts[
      contribution.origin.inputManifestArtifactID
    ],
    manifestDeclaration.kind == "input_manifest",
    let manifestArtifact = context.artifactsByID[
      contribution.origin.inputManifestArtifactID
    ],
    manifestArtifact.kind == manifestDeclaration.kind,
    manifestArtifact.contentSHA256 == manifestDeclaration.sha256,
    let packageInputs = context.packageInputsByID[
      contribution.origin.workPackageArtifactID
    ],
    let manifestInputs = context.manifestInputsByID[
      contribution.origin.inputManifestArtifactID
    ],
    packageInputs == manifestInputs,
    contribution.provenance.contributionID == contribution.contributionID,
    contribution.provenance.roleID == contribution.origin.roleID,
    contribution.provenance.workPackageArtifactID
      == contribution.origin.workPackageArtifactID,
    contribution.provenance.taskSHA256 == packageArtifact.contentSHA256,
    contribution.provenance.localInputSHA256s
      == packageInputs.map(\.sha256).sorted(),
    contribution.provenance.parentGenerationSHA256
      == contribution.parentGenerationSHA256,
    contribution.provenance.resultSHA256 == contribution.contentSHA256,
    Set(
      contribution.provenance.correlationLinks
        .filter { $0.kind == .sourceMaterial }
        .map(\.basisSHA256)
    ) == Set(packageInputs.map(\.sha256))
  else {
    throw SharedEpisodeMemoryError.invalidContribution(
      "Происхождение вклада не совпадает с паспортом и встроенным рабочим пакетом."
    )
  }
  let declaredObservationIDs = Set(
    context.passportObservations.compactMap { entry in
      entry.value.contributionID == contribution.origin.contributionArtifactID
        ? entry.key : nil
    }
  )
  guard
    declaredObservationIDs
      == Set(contribution.provenance.instrumentObservations.map(\.observationID))
  else {
    throw SharedEpisodeMemoryError.invalidContribution(
      "Набор инструментальных наблюдений вклада не совпадает с паспортом."
    )
  }
  for observation in contribution.provenance.instrumentObservations {
    guard
      let declaredObservation = context.passportObservations[
        observation.observationID
      ],
      let artifactDeclaration = context.passportArtifacts[
        declaredObservation.artifactID
      ],
      artifactDeclaration.kind == "observation",
      artifactDeclaration.sha256
        == CanonicalMemoryJSON.sha256(try observation.canonicalJSONData())
    else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Инструментальное наблюдение не закреплено точным паспортным SHA-256."
      )
    }
  }
  guard contribution.contributor.kind == .author,
    contribution.contributor.identifier == contribution.provenance.executorID
  else {
    throw SharedEpisodeMemoryError.invalidContribution(
      "Исполнитель вклада не связан с его происхождением."
    )
  }
}

private func decodeExactCanonical<T: SharedEpisodeCanonicalValue>(
  _ type: T.Type,
  data: Data,
  kind: String
) throws -> T {
  do {
    try CanonicalMemoryJSON.requireCanonical(data)
    let value = try JSONDecoder().decode(type, from: data)
    guard try value.canonicalJSONData() == data else {
      throw SharedEpisodeMemoryError.corruptGeneration(
        "\(kind) содержит поля вне точной схемы."
      )
    }
    return value
  } catch let error as SharedEpisodeMemoryError {
    throw error
  } catch {
    throw SharedEpisodeMemoryError.corruptGeneration(
      "\(kind) не соответствует точным каноническим байтам."
    )
  }
}

private func isSharedEpisodeSHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}

private func isSharedEpisodeIdentifier(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 128 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    switch scalar.value {
    case 45, 46, 48...57, 65...90, 95, 97...122:
      return true
    default:
      return false
    }
  }
}

private func isSafeSharedEpisodePath(_ value: String) -> Bool {
  guard !value.isEmpty,
    value.utf8.count <= 1_024,
    !value.hasPrefix("/"),
    !value.contains("\\"),
    !value.unicodeScalars.contains(where: { $0.value < 0x20 })
  else {
    return false
  }
  return value.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
    !$0.isEmpty && $0 != "." && $0 != ".."
  }
}
