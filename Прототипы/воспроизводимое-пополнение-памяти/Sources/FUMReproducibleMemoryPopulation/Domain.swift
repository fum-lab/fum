import Foundation

private struct StrictJSONKey: CodingKey, Hashable {
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

private func requireExactKeys(_ decoder: Decoder, expected: Set<String>) throws {
  let container = try decoder.container(keyedBy: StrictJSONKey.self)
  let actual = Set(container.allKeys.map(\.stringValue))
  guard actual == expected else {
    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Объект содержит непредусмотренный набор полей."
      )
    )
  }
}

public enum MemoryOperation: String, Codable, Equatable, Sendable {
  case remember
  case compose
}

public struct MemoryPopulationProgram: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let datasetID: String
  public let events: [MemoryInputEvent]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case datasetID = "dataset_id"
    case events
  }

  public init(from decoder: Decoder) throws {
    try requireExactKeys(decoder, expected: ["schema_version", "dataset_id", "events"])
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    datasetID = try container.decode(String.self, forKey: .datasetID)
    events = try container.decode([MemoryInputEvent].self, forKey: .events)
  }
}

public struct MemoryInputEvent: Codable, Equatable, Sendable {
  public let id: String
  public let sequence: Int
  public let operation: MemoryOperation
  public let target: String
  public let value: String?
  public let sources: [String]?
  public let separator: String?

  enum CodingKeys: String, CodingKey {
    case id
    case sequence
    case operation
    case target
    case value
    case sources
    case separator
  }

  public init(from decoder: Decoder) throws {
    let strictContainer = try decoder.container(keyedBy: StrictJSONKey.self)
    guard let operationKey = StrictJSONKey(stringValue: "operation") else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Не удалось создать ключ operation."
        )
      )
    }
    let decodedOperation = try strictContainer.decode(
      MemoryOperation.self,
      forKey: operationKey
    )

    switch decodedOperation {
    case .remember:
      try requireExactKeys(
        decoder,
        expected: ["id", "sequence", "operation", "target", "value"]
      )
    case .compose:
      try requireExactKeys(
        decoder,
        expected: ["id", "sequence", "operation", "target", "sources", "separator"]
      )
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    sequence = try container.decode(Int.self, forKey: .sequence)
    operation = decodedOperation
    target = try container.decode(String.self, forKey: .target)
    switch decodedOperation {
    case .remember:
      value = try container.decode(String.self, forKey: .value)
      sources = nil
      separator = nil
    case .compose:
      value = nil
      sources = try container.decode([String].self, forKey: .sources)
      separator = try container.decode(String.self, forKey: .separator)
    }
  }
}

public struct MemoryRecordProvenance: Codable, Equatable, Sendable {
  public let sourceDatasetID: String
  public let contributingEventIDs: [String]
  public let producedByEventID: String
  public let executor: String

  enum CodingKeys: String, CodingKey {
    case sourceDatasetID = "source_dataset_id"
    case contributingEventIDs = "contributing_event_ids"
    case producedByEventID = "produced_by_event_id"
    case executor
  }
}

public struct MemoryRecord: Codable, Equatable, Sendable {
  public let key: String
  public let value: String
  public let provenance: MemoryRecordProvenance
}

public struct MemoryTraceEntry: Codable, Equatable, Sendable {
  public let ordinal: Int
  public let eventID: String
  public let operation: MemoryOperation
  public let reads: [String]
  public let writes: [String]
  public let sourceEventSHA256: String
  public let outputRecordSHA256: String

  enum CodingKeys: String, CodingKey {
    case ordinal
    case eventID = "event_id"
    case operation
    case reads
    case writes
    case sourceEventSHA256 = "source_event_sha256"
    case outputRecordSHA256 = "output_record_sha256"
  }
}

public struct MemorySnapshot: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let datasetID: String
  public let records: [MemoryRecord]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case datasetID = "dataset_id"
    case records
  }
}

public struct MemoryExecutionTrace: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let datasetID: String
  public let entries: [MemoryTraceEntry]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case datasetID = "dataset_id"
    case entries
  }
}

public enum GUIProjectionPrerequisiteStatus: String, Codable, Equatable, Sendable {
  case markersMissing = "markers_missing"
  case markersPresent = "markers_present"
}

public struct GUIProjectionPrerequisiteReport: Codable, Equatable, Sendable {
  public let headless: Bool
  public let status: GUIProjectionPrerequisiteStatus
  public let requiredMarkers: [String]
  public let observedMarkers: [String]
  public let missingMarkers: [String]
  public let evidenceRecordKeys: [String]
  public let boundary: String

  enum CodingKeys: String, CodingKey {
    case headless
    case status
    case requiredMarkers = "required_markers"
    case observedMarkers = "observed_markers"
    case missingMarkers = "missing_markers"
    case evidenceRecordKeys = "evidence_record_keys"
    case boundary
  }
}

public struct MemoryPopulationArtifact: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let inputSHA256: String
  public let snapshotSHA256: String
  public let traceSHA256: String
  public let snapshot: MemorySnapshot
  public let trace: MemoryExecutionTrace
  public let guiProjectionPrerequisites: GUIProjectionPrerequisiteReport

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case inputSHA256 = "input_sha256"
    case snapshotSHA256 = "snapshot_sha256"
    case traceSHA256 = "trace_sha256"
    case snapshot
    case trace
    case guiProjectionPrerequisites = "gui_projection_prerequisites"
  }
}

public enum MemoryPopulationError: Error, Equatable, Sendable {
  case inputTooLarge(Int)
  case invalidInput(String)
  case unsupportedSchema(Int)
  case invalidEvent(String)
  case duplicateTarget(eventID: String, key: String)
  case missingRecord(eventID: String, key: String)
  case recordTooLarge(eventID: String, byteCount: Int)
  case memoryBudgetExceeded(eventID: String, byteCount: Int)
  case missingFixture(String)
}

extension MemoryPopulationError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .inputTooLarge(let byteCount):
      return "Вход превышает допустимый размер: \(byteCount) байт."
    case .invalidInput(let message):
      return message
    case .unsupportedSchema(let version):
      return "Неподдерживаемая версия схемы: \(version)."
    case .invalidEvent(let message):
      return message
    case .duplicateTarget(let eventID, let key):
      return "\(eventID): запись \(key) уже существует."
    case .missingRecord(let eventID, let key):
      return "\(eventID): запись \(key) для чтения не найдена."
    case .recordTooLarge(let eventID, let byteCount):
      return "\(eventID): результат записи превышает лимит: \(byteCount) байт."
    case .memoryBudgetExceeded(let eventID, let byteCount):
      return "\(eventID): снимок превышает общий лимит памяти: \(byteCount) байт."
    case .missingFixture(let name):
      return "Встроенная фикстура \(name) не найдена."
    }
  }
}
