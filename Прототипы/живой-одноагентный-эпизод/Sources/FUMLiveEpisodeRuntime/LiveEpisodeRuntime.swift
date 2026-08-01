import FUMLiveEpisodeCore
import Foundation

public enum LiveEpisodeRuntimeCheckpoint: String, Equatable, Sendable {
  case reservationGenerationConfirmed = "reservation-generation-confirmed"
}

public struct LiveEpisodeRuntime {
  public typealias CheckpointObserver =
    (LiveEpisodeRuntimeCheckpoint, StoredLiveEpisodeGeneration) throws -> Void

  public let rootURL: URL

  private let store: LiveEpisodeGenerationStore
  private let modelAdapter: any LiveEpisodeModelAdapter
  private let checkpointObserver: CheckpointObserver?

  public init(rootURL: URL) {
    self.init(rootURL: rootURL, modelAdapter: LiveEpisodeReadOnlyModelAdapter())
  }

  public init(
    rootURL: URL,
    modelAdapter: any LiveEpisodeModelAdapter,
    checkpointObserver: CheckpointObserver? = nil
  ) {
    self.rootURL = rootURL
    store = LiveEpisodeGenerationStore(rootURL: rootURL)
    self.modelAdapter = modelAdapter
    self.checkpointObserver = checkpointObserver
  }

  public func create(_ command: LiveEpisodeCreateCommand) throws -> LiveEpisodeMutationOutput {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    guard Set(command.initialEvents.map(\.eventID)).count == command.initialEvents.count else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "create.initial_events не принимает duplicate event_id."
      )
    }
    try validateExternalEvents(
      command.initialEvents,
      origin: .create,
      passport: command.passport
    )
    let before = try store.loadCurrent()
    let stored = try store.commit(
      passport: command.passport,
      events: command.initialEvents,
      invocations: [],
      expectedPreviousGenerationSHA256: nil
    )
    return mutationOutput(
      commandID: command.commandID,
      command: .create,
      status: before == nil ? .created : .alreadyApplied,
      stored: stored
    )
  }

  public func inspect(_ command: LiveEpisodeInspectCommand) throws -> LiveEpisodeInspectOutput {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    return LiveEpisodeInspectOutput(commandID: command.commandID, stored: try requireCurrent())
  }

  public func status(_ command: LiveEpisodeStatusCommand) throws -> LiveEpisodeStatusOutput {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    return LiveEpisodeStatusOutput(commandID: command.commandID, stored: try requireCurrent())
  }

  public func replay(_ command: LiveEpisodeReplayCommand) throws -> LiveEpisodeReplayOutput {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    return LiveEpisodeReplayOutput(commandID: command.commandID, stored: try requireCurrent())
  }

  public func resume(_ command: LiveEpisodeResumeCommand) async throws
    -> LiveEpisodeMutationOutput
  {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    let current = try requireCurrent()
    switch command.action {
    case .appendEvents(let append):
      return try appendEvents(append, command: command, current: current)
    case .confirmGeneration(let confirmation):
      return try confirmGeneration(confirmation, command: command, current: current)
    case .invokeModel(let invocation):
      return try await invokeModel(invocation, command: command, current: current)
    }
  }

  /// Synchronous headless path for transitions that are forbidden from reaching a model
  /// adapter. It is used by the single-agent worker on a dedicated large-stack thread.
  public func resumeWithoutModel(_ command: LiveEpisodeResumeCommand) throws
    -> LiveEpisodeMutationOutput
  {
    try validateCommand(schemaVersion: command.schemaVersion, commandID: command.commandID)
    let current = try requireCurrent()
    switch command.action {
    case .appendEvents(let append):
      return try appendEvents(append, command: command, current: current)
    case .confirmGeneration(let confirmation):
      return try confirmGeneration(confirmation, command: command, current: current)
    case .invokeModel:
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Синхронный no-model-путь запрещает model-only-вызовы."
      )
    }
  }

  private func appendEvents(
    _ append: LiveEpisodeAppendEventsCommand,
    command: LiveEpisodeResumeCommand,
    current: StoredLiveEpisodeGeneration
  ) throws -> LiveEpisodeMutationOutput {
    let events = append.events
    guard !events.isEmpty else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "append_events требует непустой список событий."
      )
    }
    guard Set(events.map(\.eventID)).count == events.count else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "append_events не принимает duplicate event_id в одном batch."
      )
    }
    try validateExternalEvents(
      events,
      origin: .append,
      passport: current.state.passport
    )
    let currentCandidateReceipts =
      current.generation.candidateReceiptJournal?.receipts ?? []
    if command.expectedGenerationSHA256 != current.generationSHA256 {
      if current.generation.previousGenerationSHA256 == command.expectedGenerationSHA256,
        events.count <= current.state.events.count,
        Array(current.state.events.suffix(events.count)) == events
      {
        return mutationOutput(
          commandID: command.commandID,
          command: .resume,
          status: .alreadyApplied,
          stored: current
        )
      }
      throw LiveEpisodeRuntimeError.generationConflict(
        expected: command.expectedGenerationSHA256,
        actual: current.generationSHA256
      )
    }
    let currentEventIDs = Set(current.state.events.map(\.eventID))
    guard currentEventIDs.isDisjoint(with: events.map(\.eventID)) else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "append_events при current-CAS требует только новые event_id."
      )
    }
    var state = current.state
    for event in events {
      state = try LiveEpisodeReducer.applying(event, to: state)
    }
    let stored = try store.commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: currentCandidateReceipts,
      candidateExecutionCommandSHA256:
        current.generation.candidateReceiptJournal?.executionCommandSHA256,
      candidateObservationConfirmationEventID:
        current.generation.candidateReceiptJournal?.observationConfirmationEventID,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
    return mutationOutput(
      commandID: command.commandID,
      command: .resume,
      status: .advanced,
      stored: stored
    )
  }

  private func confirmGeneration(
    _ confirmation: LiveEpisodeConfirmGenerationCommand,
    command: LiveEpisodeResumeCommand,
    current: StoredLiveEpisodeGeneration
  ) throws -> LiveEpisodeMutationOutput {
    if command.expectedGenerationSHA256 != current.generationSHA256 {
      if current.generation.previousGenerationSHA256 == command.expectedGenerationSHA256,
        let existing = current.state.events.last,
        existing.eventID == confirmation.eventID,
        case .generationConfirmed(let payload) = existing.payload,
        payload.generationID == digestIdentifier(command.expectedGenerationSHA256)
      {
        return mutationOutput(
          commandID: command.commandID,
          command: .resume,
          status: .alreadyApplied,
          stored: current
        )
      }
      throw LiveEpisodeRuntimeError.generationConflict(
        expected: command.expectedGenerationSHA256,
        actual: current.generationSHA256
      )
    }
    let event = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: confirmation.eventID,
      sequence: current.state.nextSequence,
      payload: .generationConfirmed(
        LiveGenerationConfirmed(
          generationID: digestIdentifier(current.generationSHA256),
          confirmedThroughSequence: current.state.nextSequence - 1,
          stateSHA256: current.generation.stateSHA256
        )
      )
    )
    let state = try LiveEpisodeReducer.applying(event, to: current.state)
    let stored = try store.commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: current.generation.candidateReceiptJournal?.receipts ?? [],
      candidateExecutionCommandSHA256:
        current.generation.candidateReceiptJournal?.executionCommandSHA256,
      candidateObservationConfirmationEventID:
        current.generation.candidateReceiptJournal?.observationConfirmationEventID,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
    return mutationOutput(
      commandID: command.commandID,
      command: .resume,
      status: .advanced,
      stored: stored
    )
  }

  private func invokeModel(
    _ invocation: LiveEpisodeModelInvocationCommand,
    command: LiveEpisodeResumeCommand,
    current: StoredLiveEpisodeGeneration
  ) async throws -> LiveEpisodeMutationOutput {
    try validate(invocation: invocation, state: current.state)
    let candidateReceipt = try LiveEpisodeGenerationStore.invocationReceipt(for: invocation)
    if let receipt = current.generation.invocationReceiptJournal.invocations.first(where: {
      $0.proposal.requestID == invocation.proposal.requestID
        || $0.proposal.variantID == invocation.proposal.variantID
    }) {
      guard receipt == candidateReceipt else {
        throw LiveEpisodeRuntimeError.invalidCommand(
          "Повтор request_id или variant_id не совпадает с полной durable invocation-receipt."
        )
      }
      if let variant = current.state.model.variants.first(where: {
        $0.proposal.requestID == invocation.proposal.requestID
      }) {
        return mutationOutput(
          commandID: command.commandID,
          command: .resume,
          status: variant.response == nil ? .providerOutcomeUnresolved : .alreadyApplied,
          stored: current
        )
      }
      if current.state.events.contains(where: { event in
        guard event.eventID == receipt.budgetCheckpointEventID,
          case .budgetCheckpointCreated(let checkpoint) = event.payload
        else { return false }
        return checkpoint.checkpointID == receipt.budgetCheckpointID
          && checkpoint.proposal == receipt.proposal
      }) {
        return mutationOutput(
          commandID: command.commandID,
          command: .resume,
          status: .alreadyApplied,
          stored: current
        )
      }
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Durable invocation-receipt не связана с подтверждённым событием."
      )
    }
    if let unresolved = current.state.model.variants.first(where: { $0.response == nil }) {
      throw LiveEpisodeRuntimeError.unresolvedModelInvocation(
        requestID: unresolved.proposal.requestID
      )
    }
    try validateUnusedIdentifiers(invocation, state: current.state)
    guard command.expectedGenerationSHA256 == current.generationSHA256 else {
      throw LiveEpisodeRuntimeError.generationConflict(
        expected: command.expectedGenerationSHA256,
        actual: current.generationSHA256
      )
    }
    guard
      modelAdapter.contract
        == LiveEpisodeModelAdapterContract(modelPolicy: current.state.passport.modelPolicy)
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Полный contract model-only-adapter не совпадает с неизменяемым паспортом."
      )
    }

    switch try LiveEpisodeReducer.planModelInvocation(
      invocation.proposal,
      checkpointID: invocation.budgetCheckpointID,
      in: current.state
    ) {
    case .checkpoint(let checkpoint):
      let event = LiveEpisodeEvent(
        episodeID: current.state.passport.episodeID,
        eventID: invocation.budgetCheckpointEventID,
        sequence: current.state.nextSequence,
        payload: .budgetCheckpointCreated(checkpoint)
      )
      let state = try LiveEpisodeReducer.applying(event, to: current.state)
      let stored = try store.commit(
        passport: state.passport,
        events: state.events,
        invocations: current.generation.invocationReceiptJournal.invocations + [candidateReceipt],
        candidateReceipts: current.generation.candidateReceiptJournal?.receipts ?? [],
        candidateExecutionCommandSHA256:
          current.generation.candidateReceiptJournal?.executionCommandSHA256,
        candidateObservationConfirmationEventID:
          current.generation.candidateReceiptJournal?.observationConfirmationEventID,
        expectedPreviousGenerationSHA256: current.generationSHA256
      )
      return mutationOutput(
        commandID: command.commandID,
        command: .resume,
        status: .checkpointed,
        stored: stored
      )

    case .request(let request):
      let requestEvent = LiveEpisodeEvent(
        episodeID: current.state.passport.episodeID,
        eventID: invocation.requestEventID,
        sequence: current.state.nextSequence,
        payload: .modelRequestRecorded(request)
      )
      let reservedState = try LiveEpisodeReducer.applying(requestEvent, to: current.state)
      let reserved = try store.commit(
        passport: reservedState.passport,
        events: reservedState.events,
        invocations: current.generation.invocationReceiptJournal.invocations + [candidateReceipt],
        candidateReceipts: current.generation.candidateReceiptJournal?.receipts ?? [],
        candidateExecutionCommandSHA256:
          current.generation.candidateReceiptJournal?.executionCommandSHA256,
        candidateObservationConfirmationEventID:
          current.generation.candidateReceiptJournal?.observationConfirmationEventID,
        expectedPreviousGenerationSHA256: current.generationSHA256
      )
      try checkpointObserver?(.reservationGenerationConfirmed, reserved)

      let adapterResult = await modelAdapter.complete(
        LiveEpisodeModelAdapterRequest(
          invocationID: invocation.proposal.requestID,
          input: invocation.input,
          disclosureClass: invocation.proposal.disclosureClass,
          purpose: invocation.proposal.purpose,
          reservation: invocation.proposal.reservation
        )
      )
      let response = try response(
        from: adapterResult,
        invocation: invocation,
        passport: reserved.state.passport
      )
      let responseEvent = LiveEpisodeEvent(
        episodeID: reserved.state.passport.episodeID,
        eventID: invocation.responseEventID,
        sequence: reserved.state.nextSequence,
        payload: .modelResponseRecorded(response)
      )
      let settledState = try LiveEpisodeReducer.applying(responseEvent, to: reserved.state)
      let settled = try store.commit(
        passport: settledState.passport,
        events: settledState.events,
        invocations: reserved.generation.invocationReceiptJournal.invocations,
        candidateReceipts: reserved.generation.candidateReceiptJournal?.receipts ?? [],
        candidateExecutionCommandSHA256:
          reserved.generation.candidateReceiptJournal?.executionCommandSHA256,
        candidateObservationConfirmationEventID:
          reserved.generation.candidateReceiptJournal?.observationConfirmationEventID,
        expectedPreviousGenerationSHA256: reserved.generationSHA256
      )
      return mutationOutput(
        commandID: command.commandID,
        command: .resume,
        status: .advanced,
        stored: settled
      )
    }
  }

  private func response(
    from result: LiveEpisodeModelAdapterResult,
    invocation: LiveEpisodeModelInvocationCommand,
    passport: LiveEpisodePassport
  ) throws -> LiveModelResponseRecorded {
    guard result.invocationID == invocation.proposal.requestID,
      result.inputSHA256 == invocation.proposal.inputSHA256,
      result.providerIdentity == passport.modelPolicy.providerIdentity
    else {
      throw LiveEpisodeRuntimeError.invalidAdapterResult(
        "Adapter-result не связан с точным invocation, input и provider identity."
      )
    }
    let status: LiveModelResponseStatus
    let output: String
    let charged: LiveBudget
    switch result.outcome {
    case .completed(let value, let actual):
      status = .completed
      output = value
      charged = actual
    case .failed(let value, let actual):
      status = .failed
      output = value
      charged = actual
    case .unknownUsage:
      status = .failed
      output = ""
      charged = invocation.proposal.reservation
    case .invalidEvidence(let message):
      throw LiveEpisodeRuntimeError.invalidAdapterResult(message)
    }
    guard charged.isComponentwiseLessThanOrEqual(to: invocation.proposal.reservation) else {
      throw LiveEpisodeRuntimeError.invalidAdapterResult(
        "Adapter вернул списание выше подтверждённого reservation."
      )
    }
    return LiveModelResponseRecorded(
      responseID: invocation.responseID,
      requestID: invocation.proposal.requestID,
      variantID: invocation.proposal.variantID,
      providerIdentity: passport.modelPolicy.providerIdentity,
      status: status,
      output: output,
      outputSHA256: LiveStrictIntentParser.sha256(of: output),
      charged: charged
    )
  }

  private func validate(
    invocation: LiveEpisodeModelInvocationCommand,
    state: LiveEpisodeState
  ) throws {
    let passport = state.passport
    guard invocation.proposal.inputSHA256 == LiveStrictIntentParser.sha256(of: invocation.input)
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "input не совпадает с точным input_sha256 предложения."
      )
    }
    guard Int64(invocation.input.utf8.count) <= passport.modelPolicy.disclosure.maximumInputBytes
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "input превышает disclosure-лимит паспорта."
      )
    }
    let identifiers = [
      invocation.requestEventID,
      invocation.responseEventID,
      invocation.responseID,
      invocation.budgetCheckpointEventID,
      invocation.budgetCheckpointID,
    ]
    guard identifiers.allSatisfy(isTechnicalIdentifier) else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Все request/response/budget identifiers должны быть техническими."
      )
    }
    let eventIDs = [
      invocation.requestEventID,
      invocation.responseEventID,
      invocation.budgetCheckpointEventID,
    ]
    guard Set(eventIDs).count == eventIDs.count else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Request, response и budget-checkpoint требуют разных event_id."
      )
    }
  }

  private func validateUnusedIdentifiers(
    _ invocation: LiveEpisodeModelInvocationCommand,
    state: LiveEpisodeState
  ) throws {
    let eventIDs = [
      invocation.requestEventID,
      invocation.responseEventID,
      invocation.budgetCheckpointEventID,
    ]
    let existingEventIDs = Set(state.events.map(\.eventID))
    if !existingEventIDs.isDisjoint(with: eventIDs) {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Event_id model-only-команды уже занят другим событием."
      )
    }
    let responseIDs = state.model.variants.compactMap(\.response?.responseID)
    guard !responseIDs.contains(invocation.responseID) else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "response_id model-only-команды уже занят."
      )
    }
    if state.events.contains(where: { event in
      guard case .budgetCheckpointCreated(let checkpoint) = event.payload else { return false }
      return checkpoint.checkpointID == invocation.budgetCheckpointID
    }) {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "budget_checkpoint_id model-only-команды уже занят."
      )
    }
  }

  private func validateCommand(schemaVersion: Int, commandID: String) throws {
    guard schemaVersion == LiveEpisodeRuntimeSchema.commandVersion else {
      throw LiveEpisodeRuntimeError.unsupportedCommandSchema(
        expected: LiveEpisodeRuntimeSchema.commandVersion,
        actual: schemaVersion
      )
    }
    let scalars = commandID.unicodeScalars
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let firstAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    guard !scalars.isEmpty, scalars.count <= 128, let first = scalars.first,
      firstAllowed.contains(first), scalars.allSatisfy({ allowed.contains($0) })
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "command_id не является техническим идентификатором."
      )
    }
  }

  private func isTechnicalIdentifier(_ value: String) -> Bool {
    let scalars = value.unicodeScalars
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let firstAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    return !scalars.isEmpty && scalars.count <= 128
      && scalars.first.map(firstAllowed.contains) == true
      && scalars.allSatisfy(allowed.contains)
  }

  private enum ExternalEventOrigin: Equatable {
    case create
    case append
  }

  private func validateExternalEvents(
    _ events: [LiveEpisodeEvent],
    origin: ExternalEventOrigin,
    passport: LiveEpisodePassport
  ) throws {
    let candidatePolicy = passport.actionAllowlist.compactMap(\.candidateCommitPolicy).first
    for event in events {
      let allowed: Bool
      switch (origin, event.kind) {
      case (.create, .modelCheckpointCreated), (.create, .pendingTransitionDeclared):
        allowed = true
      case (.append, .modelCheckpointCreated), (.append, .pendingTransitionDeclared),
        (.append, .untrustedIntentParsed), (.append, .modelSelectionRecorded),
        (.append, .transitionUserConfirmed), (.append, .authorizationDecided),
        (.append, .preflightCompleted), (.append, .executionRecorded),
        (.append, .observationRecorded), (.append, .verificationRecorded),
        (.append, .continuationDecided):
        allowed = true
      case (_, .modelRequestRecorded), (_, .modelResponseRecorded),
        (_, .budgetCheckpointCreated), (_, .generationConfirmed):
        allowed = false
      default:
        allowed = false
      }
      guard allowed else {
        let source = origin == .create ? "create.initial_events" : "resume.append_events"
        throw LiveEpisodeRuntimeError.invalidCommand(
          "\(source) не имеет права сохранять событие \(event.kind.rawValue)."
        )
      }
      guard candidatePolicy != nil else { continue }
      switch event.payload {
      case .transitionUserConfirmed, .authorizationDecided, .preflightCompleted,
        .executionRecorded, .observationRecorded:
        throw LiveEpisodeRuntimeError.invalidCommand(
          "Candidate transition stages являются runtime-owned и недоступны через append_events."
        )
      default:
        break
      }
    }
  }

  private func digestIdentifier(_ value: String) -> String {
    value.hasPrefix("sha256:") ? String(value.dropFirst(7)) : value
  }

  private func requireCurrent() throws -> StoredLiveEpisodeGeneration {
    guard let current = try store.loadCurrent() else {
      throw LiveEpisodeRuntimeError.noConfirmedGeneration
    }
    return current
  }

  private func mutationOutput(
    commandID: String,
    command: LiveEpisodeCommandKind,
    status: LiveEpisodeMutationStatus,
    stored: StoredLiveEpisodeGeneration
  ) -> LiveEpisodeMutationOutput {
    LiveEpisodeMutationOutput(
      commandID: commandID,
      command: command,
      status: status,
      generationSHA256: stored.generationSHA256,
      stateSHA256: stored.generation.stateSHA256,
      state: stored.state
    )
  }
}

private struct LiveEpisodeReadOnlyModelAdapter: LiveEpisodeModelAdapter {
  let contract = LiveEpisodeModelAdapterContract(
    profileID: "fum.read-only.v1",
    executionMode: .local,
    providerIdentity: LiveProviderIdentity(
      providerID: "fum.read-only.v1",
      interfaceID: "fum.read-only.v1",
      modelID: "none",
      runtimeID: "none"
    ),
    disclosure: LiveDisclosurePolicy(
      allowedClasses: [],
      maximumInputBytes: 0,
      allowedPurposes: []
    ),
    moneyUnit: .none,
    maximumBudget: .zero,
    perInvocationReservation: .zero,
    maximumOutputTokens: 0,
    timeoutMilliseconds: 0,
    maximumComputeUnits: 0
  )

  func complete(_ request: LiveEpisodeModelAdapterRequest) async
    -> LiveEpisodeModelAdapterResult
  {
    LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: .invalidEvidence("Read-only runtime не вызывает model adapter.")
    )
  }
}

extension LiveBudget {
  fileprivate func isComponentwiseLessThanOrEqual(to other: LiveBudget) -> Bool {
    calls <= other.calls && inputTokens <= other.inputTokens
      && outputTokens <= other.outputTokens
      && wallClockMilliseconds <= other.wallClockMilliseconds
      && computeUnits <= other.computeUnits
      && moneyMicrounits <= other.moneyMicrounits
  }
}
