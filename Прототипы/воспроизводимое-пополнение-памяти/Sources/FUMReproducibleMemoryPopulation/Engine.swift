import CryptoKit
import Foundation

public enum CanonicalMemoryJSON {
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  public static func sha256(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }
}

public struct MemoryPopulationEngine: Sendable {
  public static let maximumInputBytes = 1_048_576

  private static let maximumSeparatorBytes = 64

  public init() {}

  public func run(_ input: Data) throws -> MemoryPopulationArtifact {
    try execute(input, continuingFrom: nil).artifact
  }

  public func generation(
    from input: Data,
    continuingFrom previous: StoredMemoryGeneration? = nil
  ) throws -> MemoryGeneration {
    let result = try execute(input, continuingFrom: previous)
    let artifact = result.artifact
    let generation = MemoryGeneration(
      schemaVersion: 1,
      policyVersion: MemoryPopulationPolicy.version,
      previousGenerationSHA256: previous?.generationSHA256,
      inputSHA256: artifact.inputSHA256,
      snapshotSHA256: artifact.snapshotSHA256,
      traceSHA256: artifact.traceSHA256,
      viewModelSHA256: artifact.viewModelSHA256,
      snapshot: artifact.snapshot,
      trace: artifact.trace,
      viewModel: artifact.viewModel,
      provenance: MemoryGenerationProvenance(
        inputEventIDs: result.program.events.map(\.id),
        acceptedEventIDs: artifact.trace.entries.map(\.eventID),
        memoryExecutorVersion: MemoryPopulationPolicy.executorID,
        projectionOperatorVersion: MemoryViewProjectionOperator.version
      )
    )
    try validateMemoryGeneration(generation)
    return generation
  }

  private func execute(
    _ input: Data,
    continuingFrom previous: StoredMemoryGeneration?
  ) throws -> (program: MemoryPopulationProgram, artifact: MemoryPopulationArtifact) {
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
    let previousGeneration = try validatedPrevious(previous)
    try validate(
      program,
      startingSequence: previousGeneration?.trace.entries.count ?? 0,
      existingEventIDs: Set(previousGeneration?.trace.entries.map(\.eventID) ?? [])
    )
    if let previousGeneration,
      previousGeneration.snapshot.datasetID != program.datasetID
    {
      throw MemoryPopulationError.incompatibleGeneration(
        "dataset_id продолжения не совпадает с подтверждённой памятью."
      )
    }

    var recordsByKey = Dictionary(
      uniqueKeysWithValues: (previousGeneration?.snapshot.records ?? []).map {
        ($0.key, $0)
      }
    )
    var traceEntries = previousGeneration?.trace.entries ?? []
    var snapshotValueBytes = recordsByKey.values.reduce(0) {
      $0 + $1.value.utf8.count
    }

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
            executor: MemoryPopulationPolicy.executorID
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
        guard outputValueBytes <= MemoryPopulationPolicy.maximumRecordValueBytes else {
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
            executor: MemoryPopulationPolicy.executorID
          )
        )
        reads = sourceKeys
      }

      let nextSnapshotValueBytes = snapshotValueBytes + record.value.utf8.count
      guard nextSnapshotValueBytes <= MemoryPopulationPolicy.maximumSnapshotValueBytes else {
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
          sourceEventSHA256: CanonicalMemoryJSON.sha256(
            try CanonicalMemoryJSON.encode(event)
          ),
          outputRecordSHA256: CanonicalMemoryJSON.sha256(
            try CanonicalMemoryJSON.encode(record)
          )
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
    let viewModel = MemoryViewProjectionOperator().project(snapshot)

    return (
      program,
      MemoryPopulationArtifact(
        schemaVersion: 2,
        inputSHA256: CanonicalMemoryJSON.sha256(input),
        snapshotSHA256: CanonicalMemoryJSON.sha256(
          try CanonicalMemoryJSON.encode(snapshot)
        ),
        traceSHA256: CanonicalMemoryJSON.sha256(
          try CanonicalMemoryJSON.encode(trace)
        ),
        viewModelSHA256: CanonicalMemoryJSON.sha256(
          try CanonicalMemoryJSON.encode(viewModel)
        ),
        snapshot: snapshot,
        trace: trace,
        viewModel: viewModel,
        guiProjectionPrerequisites: guiProjectionPrerequisites
      )
    )
  }

  private func validatedPrevious(
    _ previous: StoredMemoryGeneration?
  ) throws -> MemoryGeneration? {
    guard let previous else { return nil }
    let canonical = try CanonicalMemoryJSON.encode(previous.generation)
    guard CanonicalMemoryJSON.sha256(canonical) == previous.generationSHA256 else {
      throw MemoryPopulationError.corruptGeneration(
        "Хэш подтверждённого поколения не совпадает с содержимым."
      )
    }
    try validateMemoryGeneration(previous.generation)
    return previous.generation
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

  private func validate(
    _ program: MemoryPopulationProgram,
    startingSequence: Int,
    existingEventIDs: Set<String>
  ) throws {
    guard program.schemaVersion == MemoryPopulationPolicy.schemaVersion else {
      throw MemoryPopulationError.unsupportedSchema(program.schemaVersion)
    }
    guard program.policyVersion == MemoryPopulationPolicy.version else {
      throw MemoryPopulationError.invalidInput(
        "policy_version не поддерживается текущим интерпретатором."
      )
    }
    guard isMemoryIdentifier(program.datasetID) else {
      throw MemoryPopulationError.invalidInput("dataset_id имеет недопустимый формат.")
    }
    guard !program.events.isEmpty,
      startingSequence + program.events.count <= MemoryPopulationPolicy.maximumEvents
    else {
      throw MemoryPopulationError.invalidInput(
        "Общая цепочка должна содержать от 1 до \(MemoryPopulationPolicy.maximumEvents) событий."
      )
    }

    var eventIDs = existingEventIDs
    for (index, event) in program.events.enumerated() {
      let expectedSequence = startingSequence + index + 1
      guard event.sequence == expectedSequence else {
        throw MemoryPopulationError.invalidEvent(
          "\(event.id): ожидалась sequence \(expectedSequence), получена \(event.sequence)"
        )
      }
      guard isMemoryIdentifier(event.id), eventIDs.insert(event.id).inserted else {
        throw MemoryPopulationError.invalidEvent(
          "Событие \(expectedSequence) имеет недопустимый или повторный id."
        )
      }
      guard isMemoryIdentifier(event.target) else {
        throw MemoryPopulationError.invalidEvent(
          "\(event.id): target имеет недопустимый формат."
        )
      }

      switch event.operation {
      case .remember:
        guard let value = event.value, !value.isEmpty,
          value.utf8.count <= MemoryPopulationPolicy.maximumValueBytes,
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
          sources.count <= MemoryPopulationPolicy.maximumSources,
          Set(sources).count == sources.count,
          sources.allSatisfy(isMemoryIdentifier),
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

  private func orderedUnique(_ values: [String]) -> [String] {
    var seen = Set<String>()
    return values.filter { seen.insert($0).inserted }
  }

}
