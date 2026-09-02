import Foundation

private struct MemoryGenerationSchemaEnvelope: Decodable {
  let schemaVersion: Int

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
  }
}

typealias MemoryGenerationPublicationLockEvent =
  ContentAddressedGenerationPublicationLockEvent
typealias MemoryGenerationCommitCheckpoint =
  ContentAddressedGenerationCommitCheckpoint

public struct MemoryGenerationStore {
  private static let maximumGenerationBytes = 16_777_216

  public let rootURL: URL
  private let contentStore: ContentAddressedGenerationStore

  public init(rootURL: URL) {
    self.init(
      rootURL: rootURL,
      hooksBeforePointerCommit: nil,
      hooksPublicationLockObserver: nil,
      hooksCommitCheckpointObserver: nil
    )
  }

  init(
    rootURL: URL,
    beforePointerCommit: @escaping () throws -> Void,
    publicationLockObserver: ((MemoryGenerationPublicationLockEvent) throws -> Void)? = nil,
    commitCheckpointObserver: ((MemoryGenerationCommitCheckpoint) throws -> Void)? = nil
  ) {
    self.init(
      rootURL: rootURL,
      hooksBeforePointerCommit: beforePointerCommit,
      hooksPublicationLockObserver: publicationLockObserver,
      hooksCommitCheckpointObserver: commitCheckpointObserver
    )
  }

  private init(
    rootURL: URL,
    hooksBeforePointerCommit: (() throws -> Void)?,
    hooksPublicationLockObserver: ((MemoryGenerationPublicationLockEvent) throws -> Void)?,
    hooksCommitCheckpointObserver: ((MemoryGenerationCommitCheckpoint) throws -> Void)?
  ) {
    self.rootURL = rootURL
    contentStore = ContentAddressedGenerationStore(
      rootURL: rootURL,
      canonicalProfile: CanonicalMemoryJSON.profileID,
      maximumGenerationBytes: Self.maximumGenerationBytes,
      validateGeneration: { data in
        _ = try Self.decodeAndValidateGeneration(data)
      },
      validateLineage: { candidateData, current in
        let candidate = try Self.decodeAndValidateGeneration(candidateData)
        let storedCurrent: StoredMemoryGeneration?
        if let current {
          storedCurrent = StoredMemoryGeneration(
            generationSHA256: current.generationSHA256,
            generation: try Self.decodeAndValidateGeneration(current.canonicalData)
          )
        } else {
          storedCurrent = nil
        }
        try Self.validateLineage(of: candidate, continuing: storedCurrent)
      },
      beforePointerCommit: hooksBeforePointerCommit,
      publicationLockObserver: hooksPublicationLockObserver,
      commitCheckpointObserver: hooksCommitCheckpointObserver
    )
  }

  public func loadCurrent() throws -> StoredMemoryGeneration? {
    let stored = try translateStoreErrors {
      try contentStore.loadCurrent()
    }
    guard let stored else { return nil }
    return StoredMemoryGeneration(
      generationSHA256: stored.generationSHA256,
      generation: try Self.decodeAndValidateGeneration(stored.canonicalData)
    )
  }

  public func commit(_ generation: MemoryGeneration) throws -> StoredMemoryGeneration {
    try validateMemoryGeneration(generation)
    let generationData = try CanonicalMemoryJSON.encode(generation)
    let stored = try translateStoreErrors {
      try contentStore.commit(
        generationData,
        expectedPreviousGenerationSHA256: generation.previousGenerationSHA256
      )
    }
    return StoredMemoryGeneration(
      generationSHA256: stored.generationSHA256,
      generation: generation
    )
  }

  private static func decodeAndValidateGeneration(
    _ generationData: Data
  ) throws -> MemoryGeneration {
    let generationEnvelope: MemoryGenerationSchemaEnvelope
    do {
      generationEnvelope = try JSONDecoder().decode(
        MemoryGenerationSchemaEnvelope.self,
        from: generationData
      )
    } catch {
      throw MemoryPopulationError.corruptGeneration(
        "Файл поколения не содержит версию схемы."
      )
    }
    switch generationEnvelope.schemaVersion {
    case 1:
      throw MemoryPopulationError.incompatibleGeneration(
        "Поколение схемы 1 не содержит канонического журнала событий; самодостаточное воспроизведение невозможно."
      )
    case 2:
      throw MemoryPopulationError.incompatibleGeneration(
        "Поколение схемы 2 не закрепляет языконейтральный профиль канонических байтов."
      )
    case MemoryGeneration.currentSchemaVersion:
      break
    default:
      throw MemoryPopulationError.incompatibleGeneration(
        "Файл поколения имеет неподдерживаемую версию схемы."
      )
    }

    let generation: MemoryGeneration
    do {
      try CanonicalMemoryJSON.requireCanonical(generationData)
      generation = try JSONDecoder().decode(MemoryGeneration.self, from: generationData)
      guard try CanonicalMemoryJSON.encode(generation) == generationData else {
        throw CanonicalMemoryJSONError("Файл поколения содержит поля вне точной схемы.")
      }
    } catch {
      throw MemoryPopulationError.corruptGeneration(
        "Файл поколения не соответствует схеме."
      )
    }
    try validateMemoryGeneration(generation)
    return generation
  }

  private static func validateLineage(
    of generation: MemoryGeneration,
    continuing current: StoredMemoryGeneration?
  ) throws {
    guard let current else {
      guard
        generation.provenance.inputEventIDs
          == generation.trace.entries.map(\.eventID),
        generation.eventJournal.events.map(\.id)
          == generation.provenance.inputEventIDs
      else {
        throw MemoryPopulationError.incompatibleGeneration(
          "Начальное поколение должно происходить из всей принятой трассы."
        )
      }
      return
    }

    let previous = current.generation
    guard generation.seed == previous.seed else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Преемник изменяет seed подтверждённой памяти."
      )
    }
    let previousEntries = previous.trace.entries
    let nextEntries = generation.trace.entries
    let previousEvents = previous.eventJournal.events
    let nextEvents = generation.eventJournal.events
    guard generation.snapshot.datasetID == previous.snapshot.datasetID else {
      throw MemoryPopulationError.incompatibleGeneration(
        "dataset_id преемника не совпадает с подтверждённой памятью."
      )
    }
    guard nextEntries.count > previousEntries.count,
      Array(nextEntries.prefix(previousEntries.count)) == previousEntries,
      nextEvents.count > previousEvents.count,
      Array(nextEvents.prefix(previousEvents.count)) == previousEvents
    else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Журнал событий и трасса преемника не продолжают подтверждённую историю."
      )
    }

    let nextRecords = Dictionary(
      uniqueKeysWithValues: generation.snapshot.records.map { ($0.key, $0) }
    )
    guard previous.snapshot.records.allSatisfy({ nextRecords[$0.key] == $0 }) else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Преемник изменяет подтверждённые записи памяти."
      )
    }
    let appendedEventIDs = nextEntries.dropFirst(previousEntries.count).map(\.eventID)
    let appendedJournalEventIDs = nextEvents.dropFirst(previousEvents.count).map(\.id)
    guard generation.provenance.inputEventIDs == appendedEventIDs,
      generation.provenance.inputEventIDs == appendedJournalEventIDs
    else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Происхождение входа не совпадает с добавленной частью трассы."
      )
    }
  }

  private func translateStoreErrors<T>(_ body: () throws -> T) throws -> T {
    do {
      return try body()
    } catch let error as ContentAddressedGenerationStoreError {
      switch error {
      case .incompatibleGeneration(let message):
        throw MemoryPopulationError.incompatibleGeneration(message)
      case .corruptGeneration(let message):
        throw MemoryPopulationError.corruptGeneration(message)
      case .generationConflict(let expected, let actual):
        throw MemoryPopulationError.generationConflict(expected: expected, actual: actual)
      case .generationStore(let message):
        throw MemoryPopulationError.generationStore(message)
      }
    }
  }
}
