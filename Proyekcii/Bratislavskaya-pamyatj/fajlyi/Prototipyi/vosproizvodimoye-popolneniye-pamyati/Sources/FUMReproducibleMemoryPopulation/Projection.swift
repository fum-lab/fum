import Foundation

public struct MemoryViewProjectionOperator: Sendable {
  public static let version = "fum.view-projection.operator.v1"

  public init() {}

  public func project(_ snapshot: MemorySnapshot) -> MemoryViewModel {
    let elements = snapshot.records.sorted { $0.key < $1.key }.map { record in
      MemoryViewElement(
        id: "memory.\(record.key)",
        kind: .text,
        label: record.key,
        text: record.value,
        provenance: MemoryViewElementProvenance(
          sourceRecordKeys: [record.key],
          contributingEventIDs: record.provenance.contributingEventIDs,
          producedByEventID: record.provenance.producedByEventID,
          operatorVersion: Self.version
        )
      )
    }

    return MemoryViewModel(
      schemaVersion: 1,
      operatorVersion: Self.version,
      datasetID: snapshot.datasetID,
      headless: true,
      boundary:
        "Инертная декларативная модель; renderer не входит в прототип, а жизнеспособный GUI не заявлен.",
      elements: elements,
      supportedIntents: [
        MemoryViewIntentContract(
          kind: .remember,
          intentSchemaVersion: 1,
          eventSchemaVersion: MemoryPopulationPolicy.schemaVersion,
          memoryPolicyVersion: MemoryPopulationPolicy.version
        )
      ]
    )
  }

  public func program(
    for intent: MemoryUserIntent,
    continuing generation: MemoryGeneration
  ) throws -> MemoryPopulationProgram {
    try validateMemoryGeneration(generation)
    guard intent.schemaVersion == 1 else {
      throw MemoryPopulationError.invalidIntent("Неподдерживаемая версия схемы.")
    }
    guard isMemoryIdentifier(intent.id), isMemoryIdentifier(intent.target) else {
      throw MemoryPopulationError.invalidIntent(
        "Идентификатор или целевой ключ имеет недопустимый формат."
      )
    }
    guard
      !intent.value.isEmpty,
      intent.value.utf8.count <= MemoryPopulationPolicy.maximumValueBytes
    else {
      throw MemoryPopulationError.invalidIntent(
        "Значение должно быть непустым и не превышать 16 КиБ."
      )
    }
    guard !generation.snapshot.records.contains(where: { $0.key == intent.target }) else {
      throw MemoryPopulationError.invalidIntent("Целевой ключ уже существует.")
    }

    let eventID = "intent.\(intent.id)"
    guard isMemoryIdentifier(eventID) else {
      throw MemoryPopulationError.invalidIntent(
        "Производный идентификатор события имеет недопустимый формат."
      )
    }
    guard generation.trace.entries.count < MemoryPopulationPolicy.maximumEvents else {
      throw MemoryPopulationError.invalidIntent(
        "Подтверждённая цепочка достигла лимита событий."
      )
    }
    guard !generation.trace.entries.contains(where: { $0.eventID == eventID }) else {
      throw MemoryPopulationError.invalidIntent(
        "Производный идентификатор события уже принят памятью."
      )
    }

    switch intent.kind {
    case .remember:
      return MemoryPopulationProgram(
        schemaVersion: MemoryPopulationPolicy.schemaVersion,
        policyVersion: MemoryPopulationPolicy.version,
        datasetID: generation.snapshot.datasetID,
        events: [
          MemoryInputEvent(
            id: eventID,
            sequence: generation.trace.entries.count + 1,
            operation: .remember,
            target: intent.target,
            value: intent.value
          )
        ]
      )
    }
  }
}

func isMemoryIdentifier(_ value: String) -> Bool {
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
