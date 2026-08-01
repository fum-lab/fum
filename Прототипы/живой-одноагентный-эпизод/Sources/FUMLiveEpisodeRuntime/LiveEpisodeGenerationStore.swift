import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

struct LiveEpisodeGenerationStore {
  let rootURL: URL

  private let contentStore: ContentAddressedGenerationStore

  init(rootURL: URL) {
    self.rootURL = rootURL
    contentStore = ContentAddressedGenerationStore(
      rootURL: rootURL,
      canonicalProfile: CanonicalMemoryJSON.profileID,
      maximumGenerationBytes: LiveEpisodeRuntimeSchema.maximumGenerationBytes,
      validateGeneration: Self.validateGenerationData,
      validateLineage: Self.validateLineage
    )
  }

  func loadCurrent() throws -> StoredLiveEpisodeGeneration? {
    do {
      guard let stored = try contentStore.loadCurrent() else { return nil }
      return try Self.decodeStored(stored)
    } catch {
      throw Self.mapStoreError(error)
    }
  }

  func commit(
    passport: LiveEpisodePassport,
    events: [LiveEpisodeEvent],
    invocations: [LiveEpisodeInvocationReceipt],
    expectedPreviousGenerationSHA256: String?
  ) throws -> StoredLiveEpisodeGeneration {
    let state: LiveEpisodeState
    do {
      state = try Self.replayAndValidateConfirmations(passport: passport, events: events)
    } catch let error as LiveEpisodeRuntimeError {
      throw error
    } catch {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "События кандидата не проходят чистый reducer."
      )
    }
    let journal = LiveEpisodeEventJournal(
      episodeID: passport.episodeID,
      events: events
    )
    let receiptJournal = LiveEpisodeInvocationReceiptJournal(
      episodeID: passport.episodeID,
      invocations: invocations
    )
    try Self.validateInvocationReceipts(receiptJournal, events: events)
    let generation = LiveEpisodeGeneration(
      canonicalProfile: CanonicalMemoryJSON.profileID,
      previousGenerationSHA256: expectedPreviousGenerationSHA256,
      passportSHA256: try Self.hash(passport),
      eventJournalSHA256: try Self.hash(journal),
      invocationReceiptJournalSHA256: try Self.hash(receiptJournal),
      stateSHA256: try Self.hash(state),
      passport: passport,
      eventJournal: journal,
      invocationReceiptJournal: receiptJournal
    )
    let data = try CanonicalMemoryJSON.encode(generation)
    do {
      let stored = try contentStore.commit(
        data,
        expectedPreviousGenerationSHA256: expectedPreviousGenerationSHA256
      )
      return try Self.decodeStored(stored)
    } catch {
      throw Self.mapStoreError(error)
    }
  }

  static func invocationReceipt(
    for command: LiveEpisodeModelInvocationCommand
  ) throws -> LiveEpisodeInvocationReceipt {
    LiveEpisodeInvocationReceipt(
      requestEventID: command.requestEventID,
      responseEventID: command.responseEventID,
      responseID: command.responseID,
      budgetCheckpointEventID: command.budgetCheckpointEventID,
      budgetCheckpointID: command.budgetCheckpointID,
      proposal: command.proposal,
      commandSHA256: CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(command))
    )
  }

  private static func decodeStored(
    _ stored: StoredContentAddressedGeneration
  ) throws -> StoredLiveEpisodeGeneration {
    let generation = try decodeGeneration(stored.canonicalData)
    let state = try replayAndValidateConfirmations(
      passport: generation.passport,
      events: generation.eventJournal.events
    )
    return StoredLiveEpisodeGeneration(
      generationSHA256: stored.generationSHA256,
      generation: generation,
      state: state
    )
  }

  private static func validateGenerationData(_ data: Data) throws {
    _ = try decodeGeneration(data)
  }

  private static func decodeGeneration(_ data: Data) throws -> LiveEpisodeGeneration {
    do {
      try CanonicalMemoryJSON.requireCanonical(data)
      let generation = try JSONDecoder().decode(LiveEpisodeGeneration.self, from: data)
      guard try CanonicalMemoryJSON.encode(generation) == data else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Поколение содержит поля вне точной схемы."
        )
      }
      try validate(generation)
      return generation
    } catch let error as LiveEpisodeRuntimeError {
      throw error
    } catch {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Файл поколения не соответствует канонической схеме live-эпизода."
      )
    }
  }

  private static func validate(_ generation: LiveEpisodeGeneration) throws {
    guard generation.schemaIdentity == LiveEpisodeRuntimeSchema.generationIdentity,
      generation.schemaVersion == LiveEpisodeRuntimeSchema.generationVersion,
      generation.canonicalProfile == CanonicalMemoryJSON.profileID,
      generation.reducerPolicy == LiveEpisodeRuntimeSchema.reducerPolicy
    else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Identity, версия, канонический профиль или reducer поколения не поддерживаются."
      )
    }
    if let previous = generation.previousGenerationSHA256, !isSHA256(previous) {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Ссылка на предыдущее поколение не является SHA-256."
      )
    }
    guard generation.eventJournal.schemaIdentity == LiveEpisodeSchema.identity,
      generation.eventJournal.schemaVersion == LiveEpisodeSchema.version,
      generation.eventJournal.episodeID == generation.passport.episodeID,
      generation.invocationReceiptJournal.schemaIdentity
        == LiveEpisodeRuntimeSchema.generationIdentity,
      generation.invocationReceiptJournal.schemaVersion
        == LiveEpisodeRuntimeSchema.generationVersion,
      generation.invocationReceiptJournal.episodeID == generation.passport.episodeID
    else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Журнал не совпадает со схемой или episode_id паспорта."
      )
    }
    guard try hash(generation.passport) == generation.passportSHA256,
      try hash(generation.eventJournal) == generation.eventJournalSHA256,
      try hash(generation.invocationReceiptJournal)
        == generation.invocationReceiptJournalSHA256
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Хэш паспорта или журнала не совпадает с каноническими байтами."
      )
    }
    try validateInvocationReceipts(
      generation.invocationReceiptJournal,
      events: generation.eventJournal.events
    )
    let state: LiveEpisodeState
    do {
      state = try replayAndValidateConfirmations(
        passport: generation.passport,
        events: generation.eventJournal.events
      )
    } catch let error as LiveEpisodeRuntimeError {
      throw error
    } catch {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Журнал поколения не воспроизводится чистым reducer."
      )
    }
    guard try hash(state) == generation.stateSHA256 else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Хэш воспроизведённого состояния не совпадает с поколением."
      )
    }
  }

  private static func validateLineage(
    _ candidateData: Data,
    _ current: StoredContentAddressedGeneration?
  ) throws {
    let candidate = try decodeGeneration(candidateData)
    guard let current else {
      guard candidate.previousGenerationSHA256 == nil else {
        throw LiveEpisodeRuntimeError.incompatibleGeneration(
          "Начальное поколение не может иметь предка."
        )
      }
      guard
        !candidate.eventJournal.events.contains(where: {
          if case .generationConfirmed = $0.payload { return true }
          return false
        })
      else {
        throw LiveEpisodeRuntimeError.incompatibleGeneration(
          "Начальное поколение не может ссылаться на ещё не существовавший CURRENT."
        )
      }
      return
    }
    let previous = try decodeGeneration(current.canonicalData)
    guard candidate.previousGenerationSHA256 == current.generationSHA256 else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Предок кандидата не совпадает с CURRENT."
      )
    }
    guard candidate.passport == previous.passport,
      candidate.passportSHA256 == previous.passportSHA256
    else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Преемник изменяет неизменяемый паспорт эпизода."
      )
    }
    let oldEvents = previous.eventJournal.events
    let newEvents = candidate.eventJournal.events
    guard newEvents.count > oldEvents.count,
      Array(newEvents.prefix(oldEvents.count)) == oldEvents
    else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Преемник не продолжает точный префикс типизированных событий."
      )
    }
    let oldInvocations = previous.invocationReceiptJournal.invocations
    let newInvocations = candidate.invocationReceiptJournal.invocations
    guard newInvocations.count >= oldInvocations.count,
      Array(newInvocations.prefix(oldInvocations.count)) == oldInvocations
    else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Преемник не продолжает точный префик invocation-receipts."
      )
    }
    let appended = Array(newEvents.dropFirst(oldEvents.count))
    let confirmations = appended.enumerated().compactMap {
      index, event -> (Int, LiveGenerationConfirmed)? in
      guard case .generationConfirmed(let confirmation) = event.payload else { return nil }
      return (index, confirmation)
    }
    guard confirmations.count <= 1 else {
      throw LiveEpisodeRuntimeError.incompatibleGeneration(
        "Один преемник не может подтверждать несколько поколений."
      )
    }
    if let (index, confirmation) = confirmations.first {
      let previousState = try replayAndValidateConfirmations(
        passport: previous.passport,
        events: oldEvents
      )
      guard index == 0,
        confirmation.generationID == String(current.generationSHA256.dropFirst(7)),
        confirmation.confirmedThroughSequence == previousState.nextSequence - 1,
        confirmation.stateSHA256 == (try hash(previousState))
      else {
        throw LiveEpisodeRuntimeError.incompatibleGeneration(
          "generation_confirmed должен быть первым новым событием и ссылаться на точные дайджест, sequence и state предыдущего CURRENT."
        )
      }
    }
  }

  private static func validateInvocationReceipts(
    _ journal: LiveEpisodeInvocationReceiptJournal,
    events: [LiveEpisodeEvent]
  ) throws {
    var requestIDs = Set<String>()
    var variantIDs = Set<String>()
    for invocation in journal.invocations {
      guard requestIDs.insert(invocation.proposal.requestID).inserted,
        variantIDs.insert(invocation.proposal.variantID).inserted,
        isSHA256(invocation.commandSHA256),
        isTechnicalIdentifier(invocation.requestEventID),
        isTechnicalIdentifier(invocation.responseEventID),
        isTechnicalIdentifier(invocation.responseID),
        isTechnicalIdentifier(invocation.budgetCheckpointEventID),
        isTechnicalIdentifier(invocation.budgetCheckpointID)
      else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Invocation-receipts содержат конфликт, неверный command hash или identifier."
        )
      }
      let requestEvent = events.first(where: { $0.eventID == invocation.requestEventID })
      let checkpointEvent = events.first(where: {
        $0.eventID == invocation.budgetCheckpointEventID
      })
      let requestMatches: Bool
      if let requestEvent, case .modelRequestRecorded(let payload) = requestEvent.payload {
        requestMatches = payload.proposal == invocation.proposal
      } else {
        requestMatches = false
      }
      let checkpointMatches: Bool
      if let checkpointEvent,
        case .budgetCheckpointCreated(let payload) = checkpointEvent.payload
      {
        checkpointMatches =
          payload.checkpointID == invocation.budgetCheckpointID
          && payload.proposal == invocation.proposal
      } else {
        checkpointMatches = false
      }
      guard requestMatches != checkpointMatches else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Invocation-receipt должен точно совпадать либо с request, либо с budget-checkpoint."
        )
      }
      if requestMatches,
        let responseEvent = events.first(where: { $0.eventID == invocation.responseEventID })
      {
        guard case .modelResponseRecorded(let response) = responseEvent.payload,
          response.responseID == invocation.responseID,
          response.requestID == invocation.proposal.requestID,
          response.variantID == invocation.proposal.variantID
        else {
          throw LiveEpisodeRuntimeError.corruptGeneration(
            "Response не совпадает с durable invocation-receipt."
          )
        }
      }
    }
    let ownedEvents = events.filter {
      switch $0.kind {
      case .modelRequestRecorded, .budgetCheckpointCreated: true
      default: false
      }
    }
    guard ownedEvents.count == journal.invocations.count else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Каждый provider- или budget-owned event требует ровно один durable invocation-receipt."
      )
    }
    for event in events {
      guard case .modelResponseRecorded(let response) = event.payload else { continue }
      guard
        journal.invocations.filter({ receipt in
          let requestExists = events.contains(where: { requestEvent in
            guard requestEvent.eventID == receipt.requestEventID,
              case .modelRequestRecorded(let request) = requestEvent.payload
            else { return false }
            return request.proposal == receipt.proposal
          })
          return requestExists
            && receipt.responseEventID == event.eventID
            && receipt.responseID == response.responseID
            && receipt.proposal.requestID == response.requestID
            && receipt.proposal.variantID == response.variantID
        }).count == 1
      else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Каждый provider-owned response требует точную durable invocation-receipt."
        )
      }
    }
  }

  private static func replayAndValidateConfirmations(
    passport: LiveEpisodePassport,
    events: [LiveEpisodeEvent]
  ) throws -> LiveEpisodeState {
    var state = try LiveEpisodeReducer.initialState(passport: passport)
    for event in events {
      if case .generationConfirmed(let confirmation) = event.payload {
        guard confirmation.stateSHA256 == (try hash(state)) else {
          throw LiveEpisodeRuntimeError.corruptGeneration(
            "generation_confirmed не совпадает с точным состоянием до события."
          )
        }
      }
      state = try LiveEpisodeReducer.applying(event, to: state)
    }
    return state
  }

  private static func hash<T: Encodable>(_ value: T) throws -> String {
    CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(value))
  }

  private static func isSHA256(_ value: String) -> Bool {
    value.hasPrefix("sha256:") && value.count == 71
      && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
  }

  private static func isTechnicalIdentifier(_ value: String) -> Bool {
    let scalars = value.unicodeScalars
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let firstAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    return !scalars.isEmpty && scalars.count <= 128
      && scalars.first.map(firstAllowed.contains) == true
      && scalars.allSatisfy(allowed.contains)
  }

  private static func mapStoreError(_ error: Error) -> Error {
    if let runtimeError = error as? LiveEpisodeRuntimeError { return runtimeError }
    guard let storeError = error as? ContentAddressedGenerationStoreError else { return error }
    switch storeError {
    case .incompatibleGeneration(let message):
      return LiveEpisodeRuntimeError.incompatibleGeneration(message)
    case .corruptGeneration(let message):
      return LiveEpisodeRuntimeError.corruptGeneration(message)
    case .generationConflict(let expected, let actual):
      return LiveEpisodeRuntimeError.generationConflict(expected: expected, actual: actual)
    case .generationStore(let message):
      return LiveEpisodeRuntimeError.generationStore(message)
    }
  }
}
