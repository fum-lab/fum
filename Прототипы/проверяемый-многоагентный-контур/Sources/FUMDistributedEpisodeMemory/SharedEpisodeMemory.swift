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
  public let schemaVersion: Int
  public let episodeID: String
  public let passportArtifactID: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String
  public let artifacts: [SharedEpisodeEmbeddedArtifact]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case passportArtifactID = "passport_artifact_id"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
    case artifacts
  }

  public init(
    schemaVersion: Int = 1,
    episodeID: String,
    passportArtifactID: String,
    passportSHA256: String,
    artifactManifestSHA256: String,
    artifacts: [SharedEpisodeEmbeddedArtifact]
  ) {
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
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

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeExactCanonical(Self.self, data: data, kind: "вклад общей памяти")
  }
}

public struct SharedEpisodeJournalEntry:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 2

  public let schemaVersion: Int
  public let ordinal: Int
  public let contributionSHA256: String
  public let contribution: SharedEpisodeContribution

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case ordinal
    case contributionSHA256 = "contribution_sha256"
    case contribution
  }

  public init(
    schemaVersion: Int = SharedEpisodeJournalEntry.currentSchemaVersion,
    ordinal: Int,
    contributionSHA256: String,
    contribution: SharedEpisodeContribution
  ) {
    self.schemaVersion = schemaVersion
    self.ordinal = ordinal
    self.contributionSHA256 = contributionSHA256
    self.contribution = contribution
  }
}

public struct SharedEpisodeEventJournal:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 2

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
  public static let currentSchemaVersion = 2

  public let schemaVersion: Int
  public let episodeID: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String
  public let contributions: [SharedEpisodeContribution]
  public let provenanceReport: SharedEpisodeProvenanceReport

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
    case contributions
    case provenanceReport = "provenance_report"
  }

  public init(
    schemaVersion: Int = SharedEpisodeState.currentSchemaVersion,
    episodeID: String,
    passportSHA256: String,
    artifactManifestSHA256: String,
    contributions: [SharedEpisodeContribution],
    provenanceReport: SharedEpisodeProvenanceReport
  ) {
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.passportSHA256 = passportSHA256
    self.artifactManifestSHA256 = artifactManifestSHA256
    self.contributions = contributions
    self.provenanceReport = provenanceReport
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeExactCanonical(Self.self, data: data, kind: "состояние общей памяти")
  }
}

public struct SharedEpisodeGenerationProvenance:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let inputContributionIDs: [String]
  public let acceptedContributionIDs: [String]
  public let reducerVersion: String
  public let passportSHA256: String
  public let artifactManifestSHA256: String

  enum CodingKeys: String, CodingKey {
    case inputContributionIDs = "input_contribution_ids"
    case acceptedContributionIDs = "accepted_contribution_ids"
    case reducerVersion = "reducer_version"
    case passportSHA256 = "passport_sha256"
    case artifactManifestSHA256 = "artifact_manifest_sha256"
  }

  public init(
    inputContributionIDs: [String],
    acceptedContributionIDs: [String],
    reducerVersion: String,
    passportSHA256: String,
    artifactManifestSHA256: String
  ) {
    self.inputContributionIDs = inputContributionIDs
    self.acceptedContributionIDs = acceptedContributionIDs
    self.reducerVersion = reducerVersion
    self.passportSHA256 = passportSHA256
    self.artifactManifestSHA256 = artifactManifestSHA256
  }
}

public struct SharedEpisodeGeneration:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 2

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

public enum SharedEpisodeMemoryReducer {
  public static let version = "fum.shared-episode-memory.reducer.v2"
  public static let maximumContributions = 256

  public static func foundation(
    seed: SharedEpisodeMemorySeed
  ) throws -> SharedEpisodeGeneration {
    let journal = SharedEpisodeEventJournal(
      episodeID: seed.episodeID,
      entries: []
    )
    return try replayDetails(seed: seed, journal: journal).generation
  }

  public static func continuation(
    from previous: SharedEpisodeGeneration,
    contribution: SharedEpisodeContribution
  ) throws -> SharedEpisodeGeneration {
    try validate(previous)
    let previousSHA256 = CanonicalMemoryJSON.sha256(
      try previous.canonicalJSONData()
    )
    guard contribution.parentGenerationSHA256 == previousSHA256 else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Вклад не ссылается на точное родительское поколение."
      )
    }
    guard previous.eventJournal.entries.count < maximumContributions else {
      throw SharedEpisodeMemoryError.invalidContribution(
        "Журнал достиг предельного числа вкладов версии 2."
      )
    }

    let contributionData = try contribution.canonicalJSONData()
    let entry = SharedEpisodeJournalEntry(
      ordinal: previous.eventJournal.entries.count + 1,
      contributionSHA256: CanonicalMemoryJSON.sha256(contributionData),
      contribution: contribution
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
        "Поддерживается только схема поколения версии 2."
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
    guard journal.schemaVersion == SharedEpisodeEventJournal.currentSchemaVersion,
      journal.episodeID == seed.episodeID,
      journal.entries.count <= maximumContributions
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
      provenanceReport: try SharedEpisodeProvenanceValidator.analyze([])
    )
    var prefixJournal = SharedEpisodeEventJournal(
      episodeID: seed.episodeID,
      entries: []
    )
    var generation = try makeGeneration(
      seed: seed,
      journal: prefixJournal,
      state: state,
      previousGenerationSHA256: nil,
      inputSHA256: CanonicalMemoryJSON.sha256(try seed.canonicalJSONData()),
      inputContributionIDs: []
    )
    var contributionIDs = Set<String>()

    for (index, entry) in journal.entries.enumerated() {
      guard entry.schemaVersion == SharedEpisodeJournalEntry.currentSchemaVersion,
        entry.ordinal == index + 1
      else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Журнал содержит разрыв или неподдерживаемую запись."
        )
      }
      let contribution = entry.contribution
      let contributionData = try contribution.canonicalJSONData()
      let contributionSHA256 = CanonicalMemoryJSON.sha256(contributionData)
      guard entry.contributionSHA256 == contributionSHA256,
        contributionIDs.insert(contribution.contributionID).inserted
      else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Хэш или идентификатор записи журнала не согласован."
        )
      }
      try validateContribution(
        contribution,
        context: context,
        priorProvenances: state.contributions.map(\.provenance)
      )

      let expectedParentSHA256 = CanonicalMemoryJSON.sha256(
        try generation.canonicalJSONData()
      )
      guard contribution.parentGenerationSHA256 == expectedParentSHA256 else {
        throw SharedEpisodeMemoryError.corruptGeneration(
          "Вклад не продолжает подтверждённую хэш-цепочку журнала."
        )
      }

      prefixJournal = SharedEpisodeEventJournal(
        episodeID: seed.episodeID,
        entries: prefixJournal.entries + [entry]
      )
      let contributions = state.contributions + [contribution]
      state = SharedEpisodeState(
        episodeID: seed.episodeID,
        passportSHA256: seed.passportSHA256,
        artifactManifestSHA256: seed.artifactManifestSHA256,
        contributions: contributions,
        provenanceReport: try SharedEpisodeProvenanceValidator.analyze(
          contributions.map(\.provenance)
        )
      )
      generation = try makeGeneration(
        seed: seed,
        journal: prefixJournal,
        state: state,
        previousGenerationSHA256: expectedParentSHA256,
        inputSHA256: contributionSHA256,
        inputContributionIDs: [contribution.contributionID]
      )
    }

    return (state, generation)
  }

  private static func makeGeneration(
    seed: SharedEpisodeMemorySeed,
    journal: SharedEpisodeEventJournal,
    state: SharedEpisodeState,
    previousGenerationSHA256: String?,
    inputSHA256: String,
    inputContributionIDs: [String]
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
        acceptedContributionIDs: journal.entries.map {
          $0.contribution.contributionID
        },
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
        candidate.eventJournal.entries.isEmpty,
        candidate.state.contributions.isEmpty
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
    guard candidate.seed == previous.seed else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Преемник изменяет подтверждённый паспорт или рабочие артефакты."
      )
    }
    guard candidate.eventJournal.entries.count == previous.eventJournal.entries.count + 1,
      Array(
        candidate.eventJournal.entries.prefix(previous.eventJournal.entries.count)
      ) == previous.eventJournal.entries,
      candidate.state.contributions.count == previous.state.contributions.count + 1,
      Array(
        candidate.state.contributions.prefix(previous.state.contributions.count)
      ) == previous.state.contributions,
      candidate.eventJournal.entries.last?.contribution.parentGenerationSHA256
        == current.generationSHA256
    else {
      throw SharedEpisodeMemoryError.incompatibleGeneration(
        "Преемник должен добавить ровно один вклад к точному родителю."
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
  public static func seed() throws -> SharedEpisodeMemorySeed {
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
      requirementsArtifact,
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

private struct SharedEpisodeInputBinding: Hashable {
  let artifactID: String
  let logicalPath: String
  let sha256: String
}

private struct SharedEpisodePassportIndex {
  let artifacts: [String: SharedEpisodePassportArtifactDeclaration]
  let contributions: [String: SharedEpisodePassportContribution]
  let observations: [String: SharedEpisodePassportObservation]
}

private struct SharedEpisodeSeedContext {
  let artifactsByID: [String: SharedEpisodeEmbeddedArtifact]
  let passportArtifacts: [String: SharedEpisodePassportArtifactDeclaration]
  let passportContributions: [String: SharedEpisodePassportContribution]
  let passportObservations: [String: SharedEpisodePassportObservation]
  let packageInputsByID: [String: Set<SharedEpisodeInputBinding>]
  let manifestInputsByID: [String: Set<SharedEpisodeInputBinding>]
}

private func validateSharedEpisodeSeed(
  _ seed: SharedEpisodeMemorySeed
) throws -> SharedEpisodeSeedContext {
  guard seed.schemaVersion == 1,
    isSharedEpisodeIdentifier(seed.episodeID),
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
  var packageInputsByID: [String: Set<SharedEpisodeInputBinding>] = [:]
  var manifestInputsByID: [String: Set<SharedEpisodeInputBinding>] = [:]
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
        artifactsByPath: artifactsByPath
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

  return SharedEpisodeSeedContext(
    artifactsByID: artifactsByID,
    passportArtifacts: passportIndex.artifacts,
    passportContributions: passportIndex.contributions,
    passportObservations: passportIndex.observations,
    packageInputsByID: packageInputsByID,
    manifestInputsByID: manifestInputsByID
  )
}

private func validateEmbeddedWorkPackage(
  _ data: Data,
  expectedArtifactID: String,
  artifactsByPath: [String: SharedEpisodeEmbeddedArtifact]
) throws -> Set<SharedEpisodeInputBinding> {
  do {
    try CanonicalMemoryJSON.requireCanonical(data)
  } catch {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Встроенный рабочий пакет не является каноническим JSON."
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
    let contributions = root["contributions"] as? [[String: Any]],
    let observations = root["observations"] as? [[String: Any]]
  else {
    throw SharedEpisodeMemoryError.invalidSeed(
      "Паспорт не содержит реестры артефактов и вкладов."
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
  return SharedEpisodePassportIndex(
    artifacts: artifactIndex,
    contributions: contributionIndex,
    observations: observationIndex
  )
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
  guard let declared = context.passportContributions[contribution.contributionID],
    declared.roleID == contribution.origin.roleID,
    declared.workPackageArtifactID == contribution.origin.workPackageArtifactID,
    declared.inputManifestArtifactID == contribution.origin.inputManifestArtifactID,
    declared.contributionArtifactID == contribution.origin.contributionArtifactID,
    contribution.origin.contributionArtifactID == contribution.contributionID,
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
      entry.value.contributionID == contribution.contributionID ? entry.key : nil
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
