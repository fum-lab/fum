import Foundation

public enum MemoryViewElementKind: String, Codable, Equatable, Sendable {
  case text
}

public struct MemoryViewElementProvenance: Codable, Equatable, Sendable {
  public let sourceRecordKeys: [String]
  public let contributingEventIDs: [String]
  public let producedByEventID: String
  public let operatorVersion: String

  enum CodingKeys: String, CodingKey {
    case sourceRecordKeys = "source_record_keys"
    case contributingEventIDs = "contributing_event_ids"
    case producedByEventID = "produced_by_event_id"
    case operatorVersion = "operator_version"
  }
}

public struct MemoryViewElement: Codable, Equatable, Sendable {
  public let id: String
  public let kind: MemoryViewElementKind
  public let label: String
  public let text: String
  public let provenance: MemoryViewElementProvenance
}

public struct MemoryViewIntentContract: Codable, Equatable, Sendable {
  public let kind: MemoryUserIntentKind
  public let intentSchemaVersion: Int
  public let eventSchemaVersion: Int
  public let memoryPolicyVersion: String

  enum CodingKeys: String, CodingKey {
    case kind
    case intentSchemaVersion = "intent_schema_version"
    case eventSchemaVersion = "event_schema_version"
    case memoryPolicyVersion = "memory_policy_version"
  }
}

public struct MemoryViewModel: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let operatorVersion: String
  public let datasetID: String
  public let headless: Bool
  public let boundary: String
  public let elements: [MemoryViewElement]
  public let supportedIntents: [MemoryViewIntentContract]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case operatorVersion = "operator_version"
    case datasetID = "dataset_id"
    case headless
    case boundary
    case elements
    case supportedIntents = "supported_intents"
  }
}

public enum MemoryUserIntentKind: String, Codable, Equatable, Sendable {
  case remember
}

public struct MemoryUserIntent: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let id: String
  public let kind: MemoryUserIntentKind
  public let target: String
  public let value: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case id
    case kind
    case target
    case value
  }

  public init(
    schemaVersion: Int,
    id: String,
    kind: MemoryUserIntentKind,
    target: String,
    value: String
  ) {
    self.schemaVersion = schemaVersion
    self.id = id
    self.kind = kind
    self.target = target
    self.value = value
  }
}

public struct MemoryGenerationProvenance: Codable, Equatable, Sendable {
  public let inputEventIDs: [String]
  public let acceptedEventIDs: [String]
  public let memoryExecutorVersion: String
  public let projectionOperatorVersion: String

  enum CodingKeys: String, CodingKey {
    case inputEventIDs = "input_event_ids"
    case acceptedEventIDs = "accepted_event_ids"
    case memoryExecutorVersion = "memory_executor_version"
    case projectionOperatorVersion = "projection_operator_version"
  }
}

public enum MemoryGenerationSeedKind: String, Codable, Equatable, Sendable {
  case empty
}

public struct MemoryGenerationSeed: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let kind: MemoryGenerationSeedKind
  public let policyVersion: String
  public let datasetID: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case kind
    case policyVersion = "policy_version"
    case datasetID = "dataset_id"
  }

  public init(
    schemaVersion: Int,
    kind: MemoryGenerationSeedKind,
    policyVersion: String,
    datasetID: String
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.policyVersion = policyVersion
    self.datasetID = datasetID
  }
}

public struct MemoryGeneration: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 2

  public let schemaVersion: Int
  public let policyVersion: String
  public let previousGenerationSHA256: String?
  public let inputSHA256: String
  public let seedSHA256: String
  public let eventJournalSHA256: String
  public let snapshotSHA256: String
  public let traceSHA256: String
  public let viewModelSHA256: String
  public let seed: MemoryGenerationSeed
  public let eventJournal: MemoryPopulationProgram
  public let snapshot: MemorySnapshot
  public let trace: MemoryExecutionTrace
  public let viewModel: MemoryViewModel
  public let provenance: MemoryGenerationProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case policyVersion = "policy_version"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case inputSHA256 = "input_sha256"
    case seedSHA256 = "seed_sha256"
    case eventJournalSHA256 = "event_journal_sha256"
    case snapshotSHA256 = "snapshot_sha256"
    case traceSHA256 = "trace_sha256"
    case viewModelSHA256 = "view_model_sha256"
    case seed
    case eventJournal = "event_journal"
    case snapshot
    case trace
    case viewModel = "view_model"
    case provenance
  }

  public init(
    schemaVersion: Int,
    policyVersion: String,
    previousGenerationSHA256: String?,
    inputSHA256: String,
    seedSHA256: String,
    eventJournalSHA256: String,
    snapshotSHA256: String,
    traceSHA256: String,
    viewModelSHA256: String,
    seed: MemoryGenerationSeed,
    eventJournal: MemoryPopulationProgram,
    snapshot: MemorySnapshot,
    trace: MemoryExecutionTrace,
    viewModel: MemoryViewModel,
    provenance: MemoryGenerationProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.policyVersion = policyVersion
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.inputSHA256 = inputSHA256
    self.seedSHA256 = seedSHA256
    self.eventJournalSHA256 = eventJournalSHA256
    self.snapshotSHA256 = snapshotSHA256
    self.traceSHA256 = traceSHA256
    self.viewModelSHA256 = viewModelSHA256
    self.seed = seed
    self.eventJournal = eventJournal
    self.snapshot = snapshot
    self.trace = trace
    self.viewModel = viewModel
    self.provenance = provenance
  }
}

public struct StoredMemoryGeneration: Codable, Equatable, Sendable {
  public let generationSHA256: String
  public let generation: MemoryGeneration

  enum CodingKeys: String, CodingKey {
    case generationSHA256 = "generation_sha256"
    case generation
  }

  public init(generationSHA256: String, generation: MemoryGeneration) {
    self.generationSHA256 = generationSHA256
    self.generation = generation
  }
}
