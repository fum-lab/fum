import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public enum LiveGitCandidateAdmissionSchema {
  public static let identity = "fum.live_single_agent_episode.git_candidate_admission"
  public static let version = 1
}

public enum LiveGitCandidateAdmissionStatus: Equatable, Sendable {
  case advanced
  case alreadyApplied
}

public struct LiveGitCandidateUserConfirmationCommand: Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let commandID: String
  public let expectedGenerationSHA256: String
  public let eventID: String
  public let receiptID: String
  public let generationConfirmationEventID: String
  public let evidence: LiveEvidenceObject

  public init(
    schemaIdentity: String = LiveGitCandidateAdmissionSchema.identity,
    schemaVersion: Int = LiveGitCandidateAdmissionSchema.version,
    commandID: String,
    expectedGenerationSHA256: String,
    eventID: String,
    receiptID: String,
    generationConfirmationEventID: String,
    evidence: LiveEvidenceObject
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.expectedGenerationSHA256 = expectedGenerationSHA256
    self.eventID = eventID
    self.receiptID = receiptID
    self.generationConfirmationEventID = generationConfirmationEventID
    self.evidence = evidence
  }
}

public struct LiveGitCandidateAuthorizationCommand: Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let commandID: String
  public let expectedGenerationSHA256: String
  public let eventID: String
  public let receiptID: String
  public let generationConfirmationEventID: String
  public let evidence: LiveEvidenceObject

  public init(
    schemaIdentity: String = LiveGitCandidateAdmissionSchema.identity,
    schemaVersion: Int = LiveGitCandidateAdmissionSchema.version,
    commandID: String,
    expectedGenerationSHA256: String,
    eventID: String,
    receiptID: String,
    generationConfirmationEventID: String,
    evidence: LiveEvidenceObject
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.expectedGenerationSHA256 = expectedGenerationSHA256
    self.eventID = eventID
    self.receiptID = receiptID
    self.generationConfirmationEventID = generationConfirmationEventID
    self.evidence = evidence
  }
}

public struct LiveGitCandidateAdmissionOutput: Equatable, Sendable {
  public let commandID: String
  public let status: LiveGitCandidateAdmissionStatus
  public let generationSHA256: String
  public let state: LiveEpisodeState

  public init(
    commandID: String,
    status: LiveGitCandidateAdmissionStatus,
    generationSHA256: String,
    state: LiveEpisodeState
  ) {
    self.commandID = commandID
    self.status = status
    self.generationSHA256 = generationSHA256
    self.state = state
  }
}

public struct LiveGitCandidateAdmissionRuntime {
  public let episodeDirectoryURL: URL

  private let store: LiveEpisodeGenerationStore

  public init(episodeDirectoryURL: URL) {
    self.episodeDirectoryURL = episodeDirectoryURL
    store = LiveEpisodeGenerationStore(rootURL: episodeDirectoryURL)
  }

  public func recordUserConfirmation(
    _ command: LiveGitCandidateUserConfirmationCommand
  ) throws -> LiveGitCandidateAdmissionOutput {
    try advance(
      AdmissionRequest(command),
      stage: .transitionUserConfirmed
    )
  }

  public func authorizeSelectedIntent(
    _ command: LiveGitCandidateAuthorizationCommand
  ) throws -> LiveGitCandidateAdmissionOutput {
    try advance(
      AdmissionRequest(command),
      stage: .authorized
    )
  }

  private func advance(
    _ request: AdmissionRequest,
    stage: LiveGitCandidateStage
  ) throws -> LiveGitCandidateAdmissionOutput {
    try validate(request)
    let current = try requireCurrent()
    let authority = try candidateAuthority(in: current)
    let priorCount = stage == .transitionUserConfirmed ? 0 : 1
    let targetCount = priorCount + 1

    if authority.receipts.count == targetCount {
      return try resumeExactStage(
        request,
        stage: stage,
        current: current,
        authority: authority
      )
    }
    guard authority.receipts.count == priorCount else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Admission stage does not extend the exact candidate receipt prefix."
      )
    }
    guard current.generationSHA256 == request.expectedGenerationSHA256 else {
      throw LiveEpisodeRuntimeError.generationConflict(
        expected: request.expectedGenerationSHA256,
        actual: current.generationSHA256
      )
    }
    try requireNewStage(request, stage: stage, current: current, authority: authority)

    let payload = try stagePayload(stage, request: request, current: current, authority: authority)
    let event = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: request.eventID,
      sequence: current.state.nextSequence,
      payload: payload
    )
    let receipt = try stageReceipt(
      stage,
      request: request,
      authority: authority
    )
    let receipts = authority.receipts + [receipt]
    let candidateEvents = authority.events + [event]
    try validateReceiptPrefix(
      receipts,
      through: stage,
      authority: authority,
      events: candidateEvents
    )
    _ = try LiveEpisodeReducer.applying(event, to: current.state)
    let stageGeneration = try store.commit(
      passport: current.state.passport,
      events: current.state.events + [event],
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: receipts,
      candidateExecutionCommandSHA256: nil,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
    let confirmed = try confirm(
      stageGeneration,
      eventID: request.generationConfirmationEventID
    )
    return output(request, status: .advanced, current: confirmed)
  }

  private func resumeExactStage(
    _ request: AdmissionRequest,
    stage: LiveGitCandidateStage,
    current: StoredLiveEpisodeGeneration,
    authority: AdmissionAuthority
  ) throws -> LiveGitCandidateAdmissionOutput {
    try requireCommandIDUnused(request.commandID, in: current)
    let expectedReceipt = try stageReceipt(stage, request: request, authority: authority)
    guard authority.receipts.last == expectedReceipt,
      let stageEvent = authority.events.last,
      stageEvent.eventID == request.eventID,
      stageEvent.payload
        == (try stagePayload(stage, request: request, current: current, authority: authority))
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Admission retry does not match the exact durable event and receipt."
      )
    }

    let events = current.generation.eventJournal.events
    if events.last == stageEvent {
      guard
        current.generation.previousGenerationSHA256
          == request.expectedGenerationSHA256,
        !isConfirmed(eventID: request.eventID, in: current)
      else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "Unconfirmed admission retry does not descend from the expected generation."
        )
      }
      try requireUnusedIdentifier(request.generationConfirmationEventID, in: current)
      let confirmed = try confirm(
        current,
        eventID: request.generationConfirmationEventID
      )
      return output(request, status: .advanced, current: confirmed)
    }

    guard events.count >= 2,
      events[events.count - 2] == stageEvent,
      let confirmationEvent = events.last,
      confirmationEvent.eventID == request.generationConfirmationEventID,
      case .generationConfirmed(let confirmation) = confirmationEvent.payload,
      isConfirmed(eventID: request.eventID, in: current)
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Admission retry is not the exact stage or its separate confirmation commit."
      )
    }
    let reconstructedStageSHA256 = try reconstructStageGenerationSHA256(
      current: current,
      expectedPreviousGenerationSHA256: request.expectedGenerationSHA256,
      events: Array(events.dropLast())
    )
    guard current.generation.previousGenerationSHA256 == reconstructedStageSHA256,
      confirmation.generationID == String(reconstructedStageSHA256.dropFirst(7)),
      confirmation.confirmedThroughSequence == stageEvent.sequence,
      confirmation.stateSHA256
        == (try hash(
          LiveEpisodeReducer.replay(
            passport: current.state.passport,
            events: Array(events.dropLast())
          )))
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Confirmed admission retry does not bind the expected stage generation."
      )
    }
    return output(request, status: .alreadyApplied, current: current)
  }

  private func requireNewStage(
    _ request: AdmissionRequest,
    stage: LiveGitCandidateStage,
    current: StoredLiveEpisodeGeneration,
    authority: AdmissionAuthority
  ) throws {
    try requireUnusedIdentifiers(request.identifiers, in: current)
    switch stage {
    case .transitionUserConfirmed:
      guard current.state.transition?.phase == .awaitingConfirmation else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "User confirmation requires an awaiting candidate transition."
        )
      }
    case .authorized:
      guard current.state.transition?.phase == .transitionUserConfirmed,
        let previousReceipt = authority.receipts.first,
        previousReceipt.stage == .transitionUserConfirmed,
        isImmediatelyConfirmed(previousReceipt, in: current)
      else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "Authorization requires the exact separately confirmed user receipt."
        )
      }
      _ = try selectedIntent(in: current, authority: authority)
    case .preflightPassed, .executed, .observed:
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "The admission runtime owns only confirmation and authorization."
      )
    }
  }

  private func stagePayload(
    _ stage: LiveGitCandidateStage,
    request: AdmissionRequest,
    current: StoredLiveEpisodeGeneration,
    authority: AdmissionAuthority
  ) throws -> LiveEpisodeEventPayload {
    let evidence = try boundEvidence(for: request, stage: stage)
    switch stage {
    case .transitionUserConfirmed:
      return .transitionUserConfirmed(
        LiveTransitionUserConfirmed(
          coordinates: authority.coordinates,
          evidence: evidence
        )
      )
    case .authorized:
      let intent = try selectedIntent(in: current, authority: authority)
      return .authorizationDecided(
        LiveAuthorizationDecided(
          coordinates: authority.coordinates,
          intentID: intent.intentID,
          allowanceID: authority.allowance.allowanceID,
          decision: .allowed,
          evidence: evidence
        )
      )
    case .preflightPassed, .executed, .observed:
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "The admission runtime cannot create this candidate stage."
      )
    }
  }

  private func stageReceipt(
    _ stage: LiveGitCandidateStage,
    request: AdmissionRequest,
    authority: AdmissionAuthority
  ) throws -> LiveGitCandidateStageReceipt {
    let predecessor: LiveGitCandidateReceiptLink?
    if let stageIndex = LiveGitCandidateStage.allCases.firstIndex(of: stage),
      stageIndex > 0,
      authority.receipts.indices.contains(stageIndex - 1)
    {
      let previous = authority.receipts[stageIndex - 1]
      predecessor = LiveGitCandidateReceiptLink(
        receiptID: previous.receiptID,
        receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(previous)
      )
    } else {
      predecessor = nil
    }
    return LiveGitCandidateStageReceipt(
      receiptID: request.receiptID,
      eventID: request.eventID,
      stage: stage,
      coordinates: authority.coordinates,
      evidence: try boundEvidence(for: request, stage: stage),
      producerID: authority.policy.producerIDs.producerID(for: stage),
      predecessor: predecessor
    )
  }

  private func boundEvidence(
    for request: AdmissionRequest,
    stage: LiveGitCandidateStage
  ) throws -> LiveEvidenceObject {
    let binding = AdmissionCommandBinding(
      schemaIdentity: request.schemaIdentity,
      schemaVersion: request.schemaVersion,
      stage: stage,
      commandID: request.commandID,
      expectedGenerationSHA256: request.expectedGenerationSHA256,
      eventID: request.eventID,
      receiptID: request.receiptID,
      generationConfirmationEventID: request.generationConfirmationEventID,
      evidence: request.evidence
    )
    return LiveEvidenceObject(
      evidenceID: request.evidence.evidenceID,
      evidenceSHA256: try hash(binding)
    )
  }

  private func confirm(
    _ current: StoredLiveEpisodeGeneration,
    eventID: String
  ) throws -> StoredLiveEpisodeGeneration {
    try requireUnusedIdentifier(eventID, in: current)
    let event = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: eventID,
      sequence: current.state.nextSequence,
      payload: .generationConfirmed(
        LiveGenerationConfirmed(
          generationID: String(current.generationSHA256.dropFirst(7)),
          confirmedThroughSequence: current.state.nextSequence - 1,
          stateSHA256: current.generation.stateSHA256
        )
      )
    )
    _ = try LiveEpisodeReducer.applying(event, to: current.state)
    return try store.commit(
      passport: current.state.passport,
      events: current.state.events + [event],
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: current.generation.candidateReceiptJournal?.receipts ?? [],
      candidateExecutionCommandSHA256: nil,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
  }

  private func candidateAuthority(
    in current: StoredLiveEpisodeGeneration
  ) throws -> AdmissionAuthority {
    let passport = current.state.passport
    guard passport.actionAllowlist.count == 1,
      let allowance = passport.actionAllowlist.first,
      allowance.operation == LiveGitCandidateContract.operation,
      let policy = allowance.candidateCommitPolicy,
      let transition = current.state.transition,
      transition.declaration.allowanceID == allowance.allowanceID,
      transition.declaration.coordinates.episodeID == passport.episodeID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Admission requires one exact candidate allowance and transition."
      )
    }
    let receipts = current.generation.candidateReceiptJournal?.receipts ?? []
    let candidateEvents = try receipts.map { receipt -> LiveEpisodeEvent in
      guard
        let event = current.generation.eventJournal.events.first(where: {
          $0.eventID == receipt.eventID
        })
      else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "Candidate receipt does not have its exact durable event."
        )
      }
      return event
    }
    let authority = AdmissionAuthority(
      allowance: allowance,
      policy: policy,
      coordinates: transition.declaration.coordinates,
      receipts: receipts,
      events: candidateEvents
    )
    if let lastStage = receipts.last?.stage {
      try validateReceiptPrefix(
        receipts,
        through: lastStage,
        authority: authority,
        events: candidateEvents
      )
    }
    return authority
  }

  private func selectedIntent(
    in current: StoredLiveEpisodeGeneration,
    authority: AdmissionAuthority
  ) throws -> LiveUntrustedActionIntent {
    guard let selection = current.state.model.selection,
      selection.status == .selectedInModel,
      let variant = current.state.model.variants.first(where: {
        $0.proposal.variantID == selection.selectedVariantID
      }),
      variant.proposal.variantID == selection.selectedVariantID,
      let response = variant.response,
      response.status == .completed,
      response.responseID == selection.sourceResponseID,
      response.variantID == selection.selectedVariantID,
      let parsed = variant.intent,
      parsed.variantID == selection.selectedVariantID,
      parsed.sourceResponseID == selection.sourceResponseID,
      parsed.intent.intentID == selection.sourceIntentID,
      parsed.intent.operation == authority.allowance.operation,
      parsed.intent.adapterID == authority.allowance.adapterID,
      parsed.intent.effectClass == authority.allowance.effectClass,
      parsed.intent.objectID == authority.coordinates.objectID,
      parsed.intent.expectedEffectSHA256 == authority.coordinates.expectedEffectSHA256
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Authorization does not bind the exact selected candidate intent."
      )
    }
    return parsed.intent
  }

  private func validateReceiptPrefix(
    _ receipts: [LiveGitCandidateStageReceipt],
    through stage: LiveGitCandidateStage,
    authority: AdmissionAuthority,
    events: [LiveEpisodeEvent]
  ) throws {
    do {
      try LiveGitCandidateReceiptChain.validatePrefix(
        receipts,
        through: stage,
        policy: authority.policy,
        expectedCoordinates: authority.coordinates,
        candidateOwnedEvents: events
      )
    } catch {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate receipt prefix is invalid: \(error)"
      )
    }
  }

  private func reconstructStageGenerationSHA256(
    current: StoredLiveEpisodeGeneration,
    expectedPreviousGenerationSHA256: String,
    events: [LiveEpisodeEvent]
  ) throws -> String {
    let generation = current.generation
    let eventJournal = LiveEpisodeEventJournal(
      schemaIdentity: generation.eventJournal.schemaIdentity,
      schemaVersion: generation.eventJournal.schemaVersion,
      episodeID: generation.eventJournal.episodeID,
      events: events
    )
    let state = try LiveEpisodeReducer.replay(
      passport: generation.passport,
      events: events
    )
    let reconstructed = LiveEpisodeGeneration(
      schemaIdentity: generation.schemaIdentity,
      schemaVersion: generation.schemaVersion,
      canonicalProfile: generation.canonicalProfile,
      reducerPolicy: generation.reducerPolicy,
      previousGenerationSHA256: expectedPreviousGenerationSHA256,
      passportSHA256: generation.passportSHA256,
      eventJournalSHA256: try hash(eventJournal),
      invocationReceiptJournalSHA256: generation.invocationReceiptJournalSHA256,
      candidateReceiptJournalSHA256: generation.candidateReceiptJournalSHA256,
      stateSHA256: try hash(state),
      passport: generation.passport,
      eventJournal: eventJournal,
      invocationReceiptJournal: generation.invocationReceiptJournal,
      candidateReceiptJournal: generation.candidateReceiptJournal
    )
    return try hash(reconstructed)
  }

  private func isImmediatelyConfirmed(
    _ receipt: LiveGitCandidateStageReceipt,
    in current: StoredLiveEpisodeGeneration
  ) -> Bool {
    let events = current.generation.eventJournal.events
    guard events.count >= 2,
      events[events.count - 2].eventID == receipt.eventID,
      let confirmationEvent = events.last,
      case .generationConfirmed(let confirmation) = confirmationEvent.payload,
      current.generation.previousGenerationSHA256.map({
        confirmation.generationID == String($0.dropFirst(7))
      }) == true,
      confirmation.confirmedThroughSequence == events[events.count - 2].sequence
    else { return false }
    return true
  }

  private func isConfirmed(
    eventID: String,
    in current: StoredLiveEpisodeGeneration
  ) -> Bool {
    guard let sequence = current.state.events.first(where: { $0.eventID == eventID })?.sequence,
      let confirmation = current.state.confirmedGeneration?.confirmation
    else { return false }
    return confirmation.confirmedThroughSequence >= sequence
  }

  private func validate(_ request: AdmissionRequest) throws {
    guard request.schemaIdentity == LiveGitCandidateAdmissionSchema.identity,
      request.schemaVersion == LiveGitCandidateAdmissionSchema.version,
      isCandidateSHA256(request.expectedGenerationSHA256),
      isCandidateSHA256(request.evidence.evidenceSHA256),
      request.identifiers.allSatisfy(isCandidateIdentifier),
      Set(request.identifiers).count == request.identifiers.count
    else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Admission command has an unsupported schema or invalid identities."
      )
    }
  }

  private func requireUnusedIdentifiers(
    _ identifiers: [String],
    in current: StoredLiveEpisodeGeneration
  ) throws {
    for identifier in identifiers {
      try requireUnusedIdentifier(identifier, in: current)
    }
  }

  private func requireCommandIDUnused(
    _ commandID: String,
    in current: StoredLiveEpisodeGeneration
  ) throws {
    try requireUnusedIdentifier(commandID, in: current)
  }

  private func requireUnusedIdentifier(
    _ identifier: String,
    in current: StoredLiveEpisodeGeneration
  ) throws {
    let receipts = current.generation.candidateReceiptJournal?.receipts ?? []
    let occupied = Set(
      current.generation.eventJournal.events.map(\.eventID)
        + receipts.map(\.receiptID)
        + receipts.map(\.evidence.evidenceID)
    )
    guard !occupied.contains(identifier) else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Admission identifier already belongs to durable episode history."
      )
    }
  }

  private func requireCurrent() throws -> StoredLiveEpisodeGeneration {
    guard let current = try store.loadCurrent() else {
      throw LiveEpisodeRuntimeError.noConfirmedGeneration
    }
    return current
  }

  private func output(
    _ request: AdmissionRequest,
    status: LiveGitCandidateAdmissionStatus,
    current: StoredLiveEpisodeGeneration
  ) -> LiveGitCandidateAdmissionOutput {
    LiveGitCandidateAdmissionOutput(
      commandID: request.commandID,
      status: status,
      generationSHA256: current.generationSHA256,
      state: current.state
    )
  }

  private func hash<T: Encodable>(_ value: T) throws -> String {
    CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(value))
  }
}

private struct AdmissionRequest {
  let schemaIdentity: String
  let schemaVersion: Int
  let commandID: String
  let expectedGenerationSHA256: String
  let eventID: String
  let receiptID: String
  let generationConfirmationEventID: String
  let evidence: LiveEvidenceObject

  var identifiers: [String] {
    [
      commandID,
      eventID,
      receiptID,
      generationConfirmationEventID,
      evidence.evidenceID,
    ]
  }

  init(_ command: LiveGitCandidateUserConfirmationCommand) {
    schemaIdentity = command.schemaIdentity
    schemaVersion = command.schemaVersion
    commandID = command.commandID
    expectedGenerationSHA256 = command.expectedGenerationSHA256
    eventID = command.eventID
    receiptID = command.receiptID
    generationConfirmationEventID = command.generationConfirmationEventID
    evidence = command.evidence
  }

  init(_ command: LiveGitCandidateAuthorizationCommand) {
    schemaIdentity = command.schemaIdentity
    schemaVersion = command.schemaVersion
    commandID = command.commandID
    expectedGenerationSHA256 = command.expectedGenerationSHA256
    eventID = command.eventID
    receiptID = command.receiptID
    generationConfirmationEventID = command.generationConfirmationEventID
    evidence = command.evidence
  }
}

private struct AdmissionCommandBinding: Encodable {
  let schemaIdentity: String
  let schemaVersion: Int
  let stage: LiveGitCandidateStage
  let commandID: String
  let expectedGenerationSHA256: String
  let eventID: String
  let receiptID: String
  let generationConfirmationEventID: String
  let evidence: LiveEvidenceObject

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case stage
    case commandID = "command_id"
    case expectedGenerationSHA256 = "expected_generation_sha256"
    case eventID = "event_id"
    case receiptID = "receipt_id"
    case generationConfirmationEventID = "generation_confirmation_event_id"
    case evidence
  }
}

private struct AdmissionAuthority {
  let allowance: LiveAllowedAction
  let policy: LiveGitCandidateCommitPolicy
  let coordinates: LiveTransitionCoordinates
  let receipts: [LiveGitCandidateStageReceipt]
  let events: [LiveEpisodeEvent]
}

private func isCandidateIdentifier(_ value: String) -> Bool {
  let scalars = value.unicodeScalars
  let initial = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
  let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
  return !scalars.isEmpty && scalars.count <= 128
    && scalars.first.map(initial.contains) == true
    && scalars.allSatisfy(allowed.contains)
}

private func isCandidateSHA256(_ value: String) -> Bool {
  value.hasPrefix("sha256:") && value.count == 71
    && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
}
