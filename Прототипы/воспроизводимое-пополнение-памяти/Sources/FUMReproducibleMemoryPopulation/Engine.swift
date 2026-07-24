import CryptoKit
import Foundation

public enum CanonicalMemoryJSON {
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }
}

public struct MemoryPopulationEngine: Sendable {
  public static let maximumInputBytes = 1_048_576

  private static let executorID = "fum.memory.interpreter.v1"
  private static let maximumEvents = 256
  private static let maximumValueBytes = 16_384
  private static let maximumRecordValueBytes = 65_536
  private static let maximumSnapshotValueBytes = 4_194_304
  private static let maximumSources = 32
  private static let maximumSeparatorBytes = 64

  public init() {}

  public func run(_ input: Data) throws -> MemoryPopulationArtifact {
    guard input.count <= Self.maximumInputBytes else {
      throw MemoryPopulationError.inputTooLarge(input.count)
    }

    let program: MemoryPopulationProgram
    do {
      program = try JSONDecoder().decode(MemoryPopulationProgram.self, from: input)
    } catch {
      throw MemoryPopulationError.invalidInput(
        "Вход не соответствует схеме набора событий версии 1."
      )
    }
    try validate(program)

    var recordsByKey: [String: MemoryRecord] = [:]
    var traceEntries: [MemoryTraceEntry] = []
    var snapshotValueBytes = 0

    for event in program.events {
      guard recordsByKey[event.target] == nil else {
        throw MemoryPopulationError.duplicateTarget(eventID: event.id, key: event.target)
      }

      let record: MemoryRecord
      let reads: [String]
      switch event.operation {
      case .remember:
        record = MemoryRecord(
          key: event.target,
          value: event.value ?? "",
          provenance: MemoryRecordProvenance(
            sourceDatasetID: program.datasetID,
            contributingEventIDs: [event.id],
            producedByEventID: event.id,
            executor: Self.executorID
          )
        )
        reads = []
      case .compose:
        let sourceKeys = event.sources ?? []
        let sourceRecords = try sourceKeys.map { key in
          guard let source = recordsByKey[key] else {
            throw MemoryPopulationError.missingRecord(eventID: event.id, key: key)
          }
          return source
        }
        let separator = event.separator ?? ""
        let outputValueBytes =
          sourceRecords.reduce(0) { $0 + $1.value.utf8.count }
          + max(0, sourceRecords.count - 1) * separator.utf8.count
        guard outputValueBytes <= Self.maximumRecordValueBytes else {
          throw MemoryPopulationError.recordTooLarge(
            eventID: event.id,
            byteCount: outputValueBytes
          )
        }
        let contributingIDs = orderedUnique(
          sourceRecords.flatMap(\.provenance.contributingEventIDs) + [event.id]
        )
        record = MemoryRecord(
          key: event.target,
          value: sourceRecords.map(\.value).joined(separator: separator),
          provenance: MemoryRecordProvenance(
            sourceDatasetID: program.datasetID,
            contributingEventIDs: contributingIDs,
            producedByEventID: event.id,
            executor: Self.executorID
          )
        )
        reads = sourceKeys
      }

      let nextSnapshotValueBytes = snapshotValueBytes + record.value.utf8.count
      guard nextSnapshotValueBytes <= Self.maximumSnapshotValueBytes else {
        throw MemoryPopulationError.memoryBudgetExceeded(
          eventID: event.id,
          byteCount: nextSnapshotValueBytes
        )
      }
      snapshotValueBytes = nextSnapshotValueBytes

      recordsByKey[event.target] = record
      traceEntries.append(
        MemoryTraceEntry(
          ordinal: event.sequence,
          eventID: event.id,
          operation: event.operation,
          reads: reads,
          writes: [event.target],
          sourceEventSHA256: try sha256(CanonicalMemoryJSON.encode(event)),
          outputRecordSHA256: try sha256(CanonicalMemoryJSON.encode(record))
        )
      )
    }

    let snapshot = MemorySnapshot(
      schemaVersion: 1,
      datasetID: program.datasetID,
      records: recordsByKey.values.sorted { $0.key < $1.key }
    )
    let trace = MemoryExecutionTrace(
      schemaVersion: 1,
      datasetID: program.datasetID,
      entries: traceEntries
    )
    let guiProjectionPrerequisites = assessGUIProjectionPrerequisites(
      snapshot: snapshot,
      trace: trace
    )

    return MemoryPopulationArtifact(
      schemaVersion: 1,
      inputSHA256: sha256(input),
      snapshotSHA256: try sha256(CanonicalMemoryJSON.encode(snapshot)),
      traceSHA256: try sha256(CanonicalMemoryJSON.encode(trace)),
      snapshot: snapshot,
      trace: trace,
      guiProjectionPrerequisites: guiProjectionPrerequisites
    )
  }

  private func assessGUIProjectionPrerequisites(
    snapshot: MemorySnapshot,
    trace: MemoryExecutionTrace
  ) -> GUIProjectionPrerequisiteReport {
    let required = [
      "reproducible-memory",
      "bounded-internal-execution",
      "gui-projection-specification",
    ]
    var observed: [String] = []
    var evidence = Set<String>()

    if !snapshot.records.isEmpty,
      trace.entries.contains(where: { $0.operation == .remember })
    {
      observed.append("reproducible-memory")
      evidence.formUnion(snapshot.records.map(\.key))
    }

    let executionEntries = trace.entries.filter { $0.operation == .compose }
    if !executionEntries.isEmpty {
      observed.append("bounded-internal-execution")
      evidence.formUnion(executionEntries.flatMap { $0.reads + $0.writes })
    }

    if snapshot.records.contains(where: {
      $0.key == "gui-projection-specification" && !$0.value.isEmpty
    }) {
      observed.append("gui-projection-specification")
      evidence.insert("gui-projection-specification")
    }

    let observedSet = Set(observed)
    let missing = required.filter { !observedSet.contains($0) }
    return GUIProjectionPrerequisiteReport(
      headless: true,
      status: missing.isEmpty ? .markersPresent : .markersMissing,
      requiredMarkers: required,
      observedMarkers: observed,
      missingMarkers: missing,
      evidenceRecordKeys: evidence.sorted(),
      boundary: "GUI не создаётся; статус сообщает только о наличии маркеров предпосылок."
    )
  }

  private func validate(_ program: MemoryPopulationProgram) throws {
    guard program.schemaVersion == 1 else {
      throw MemoryPopulationError.unsupportedSchema(program.schemaVersion)
    }
    guard isIdentifier(program.datasetID) else {
      throw MemoryPopulationError.invalidInput("dataset_id имеет недопустимый формат.")
    }
    guard !program.events.isEmpty, program.events.count <= Self.maximumEvents else {
      throw MemoryPopulationError.invalidInput(
        "Набор должен содержать от 1 до \(Self.maximumEvents) событий."
      )
    }

    var eventIDs = Set<String>()
    for (index, event) in program.events.enumerated() {
      guard event.sequence == index + 1 else {
        throw MemoryPopulationError.invalidEvent(
          "\(event.id): ожидалась sequence \(index + 1), получена \(event.sequence)"
        )
      }
      guard isIdentifier(event.id), eventIDs.insert(event.id).inserted else {
        throw MemoryPopulationError.invalidEvent(
          "Событие \(index + 1) имеет недопустимый или повторный id."
        )
      }
      guard isIdentifier(event.target) else {
        throw MemoryPopulationError.invalidEvent(
          "\(event.id): target имеет недопустимый формат."
        )
      }

      switch event.operation {
      case .remember:
        guard let value = event.value, !value.isEmpty,
          value.utf8.count <= Self.maximumValueBytes,
          event.sources == nil,
          event.separator == nil
        else {
          throw MemoryPopulationError.invalidEvent(
            "\(event.id): remember требует только непустое value в пределах лимита."
          )
        }
      case .compose:
        guard event.value == nil,
          let sources = event.sources,
          !sources.isEmpty,
          sources.count <= Self.maximumSources,
          Set(sources).count == sources.count,
          sources.allSatisfy(isIdentifier),
          let separator = event.separator,
          separator.utf8.count <= Self.maximumSeparatorBytes
        else {
          throw MemoryPopulationError.invalidEvent(
            "\(event.id): compose требует уникальные sources и ограниченный separator."
          )
        }
      }
    }
  }

  private func isIdentifier(_ value: String) -> Bool {
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

  private func orderedUnique(_ values: [String]) -> [String] {
    var seen = Set<String>()
    return values.filter { seen.insert($0).inserted }
  }

  private func sha256(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }
}
