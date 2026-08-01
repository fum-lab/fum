import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public enum LiveGitCandidateEpisodeStatus: String, Codable, Equatable, Sendable {
  case advanced
  case alreadyApplied = "already_applied"
}

public struct LiveGitCandidateEpisodeCommand: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let expectedGenerationSHA256: String
  public let preflightConfirmationEventID: String
  public let observationConfirmationEventID: String
  public let plan: LiveGitCandidatePlan

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String,
    expectedGenerationSHA256: String,
    preflightConfirmationEventID: String,
    observationConfirmationEventID: String,
    plan: LiveGitCandidatePlan
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.expectedGenerationSHA256 = expectedGenerationSHA256
    self.preflightConfirmationEventID = preflightConfirmationEventID
    self.observationConfirmationEventID = observationConfirmationEventID
    self.plan = plan
  }

  public func canonicalSHA256() throws -> String {
    CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(self))
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case expectedGenerationSHA256 = "expected_generation_sha256"
    case preflightConfirmationEventID = "preflight_confirmation_event_id"
    case observationConfirmationEventID = "observation_confirmation_event_id"
    case plan
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    commandID = try container.decode(String.self, forKey: .commandID)
    expectedGenerationSHA256 = try container.decode(
      String.self,
      forKey: .expectedGenerationSHA256
    )
    preflightConfirmationEventID = try container.decode(
      String.self,
      forKey: .preflightConfirmationEventID
    )
    observationConfirmationEventID = try container.decode(
      String.self,
      forKey: .observationConfirmationEventID
    )
    plan = try container.decode(LiveGitCandidatePlan.self, forKey: .plan)
  }
}

public struct LiveGitCandidateEpisodeOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let status: LiveGitCandidateEpisodeStatus
  public let generationSHA256: String
  public let candidateOID: String
  public let passportSHA256: String

  public init(
    schemaVersion: Int = LiveEpisodeRuntimeSchema.commandVersion,
    commandID: String,
    status: LiveGitCandidateEpisodeStatus,
    generationSHA256: String,
    candidateOID: String,
    passportSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.status = status
    self.generationSHA256 = generationSHA256
    self.candidateOID = candidateOID
    self.passportSHA256 = passportSHA256
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case status
    case generationSHA256 = "generation_sha256"
    case candidateOID = "candidate_oid"
    case passportSHA256 = "passport_sha256"
  }
}

public struct LiveGitCandidateEpisodeRuntime {
  public let episodeDirectoryURL: URL
  public let sourceCheckoutURL: URL

  private let store: LiveEpisodeGenerationStore
  private let adapter: IsolatedGitCandidateAdapter

  public init(
    episodeDirectoryURL: URL,
    sourceCheckoutURL: URL,
    adapter: IsolatedGitCandidateAdapter = IsolatedGitCandidateAdapter()
  ) {
    self.episodeDirectoryURL = episodeDirectoryURL
    self.sourceCheckoutURL = sourceCheckoutURL
    store = LiveEpisodeGenerationStore(rootURL: episodeDirectoryURL)
    self.adapter = adapter
  }

  public func createCandidateCommit(
    _ command: LiveGitCandidateEpisodeCommand
  ) throws -> LiveGitCandidateEpisodeOutput {
    try validateCommand(command)
    let commandSHA256 = try command.canonicalSHA256()
    var current = try requireCurrent()
    var authority = try self.authority(in: current, plan: command.plan)
    var receiptCount = authority.receipts.count

    if receiptCount == LiveGitCandidateStage.allCases.count {
      let exact = try requireExactCompletedCandidate(
        current: current,
        command: command,
        commandSHA256: commandSHA256,
        authority: authority
      )
      switch try exactStageConfirmationStatus(
        current: current,
        receipt: authority.receipts[4],
        expectedConfirmationEventID: command.observationConfirmationEventID
      ) {
      case .unconfirmed:
        try requireUnusedIdentifiers(
          [command.observationConfirmationEventID],
          in: current
        )
        current = try confirm(
          current,
          eventID: command.observationConfirmationEventID
        )
        authority = try self.authority(in: current, plan: command.plan)
        guard
          try exactStageConfirmationStatus(
            current: current,
            receipt: authority.receipts[4],
            expectedConfirmationEventID: command.observationConfirmationEventID
          ) == .confirmed
        else {
          throw LiveGitCandidateRuntimeError.invalidEvidence(
            "Candidate observation confirmation was not durably recorded."
          )
        }
        return output(
          command: command,
          status: .advanced,
          current: current,
          passportSHA256: exact
        )
      case .confirmed:
        return output(
          command: command,
          status: .alreadyApplied,
          current: current,
          passportSHA256: exact
        )
      }
    }

    guard (2...4).contains(receiptCount) else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate execution requires the exact authorized receipt prefix."
      )
    }
    if receiptCount == 2 {
      guard current.generationSHA256 == command.expectedGenerationSHA256 else {
        throw LiveEpisodeRuntimeError.generationConflict(
          expected: command.expectedGenerationSHA256,
          actual: current.generationSHA256
        )
      }
      guard isConfirmed(eventID: authority.receipts[1].eventID, in: current) else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "The exact authorized receipt prefix is not generation-confirmed."
        )
      }
      try requireUnusedIdentifiers(
        [
          command.commandID,
          command.preflightConfirmationEventID,
          command.observationConfirmationEventID,
          command.plan.preflightEventID,
          command.plan.preflightReceiptID,
          command.plan.executionEventID,
          command.plan.executionReceiptID,
          command.plan.observationEventID,
          command.plan.observationReceiptID,
        ],
        in: current
      )
      current = try appendPreflight(
        to: current,
        command: command,
        commandSHA256: commandSHA256,
        authority: authority
      )
    } else {
      try requireExactCommandBinding(
        current,
        commandSHA256: commandSHA256,
        observationConfirmationEventID: command.observationConfirmationEventID
      )
    }

    authority = try self.authority(in: current, plan: command.plan)
    receiptCount = authority.receipts.count
    if receiptCount == 3 {
      let confirmationStatus = try exactStageConfirmationStatus(
        current: current,
        receipt: authority.receipts[2],
        expectedConfirmationEventID: command.preflightConfirmationEventID
      )
      try validateStoredPreflight(
        current: current,
        command: command,
        authority: authority
      )
      if confirmationStatus == .unconfirmed {
        try requireUnusedIdentifiers(
          [command.preflightConfirmationEventID],
          in: current
        )
        current = try confirm(
          current,
          eventID: command.preflightConfirmationEventID
        )
      }
      authority = try self.authority(in: current, plan: command.plan)
      guard
        try exactStageConfirmationStatus(
          current: current,
          receipt: authority.receipts[2],
          expectedConfirmationEventID: command.preflightConfirmationEventID
        ) == .confirmed
      else {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "Git effect requires a confirmed preflight receipt prefix."
        )
      }
      try requireUnusedIdentifiers(
        [
          command.plan.executionEventID,
          command.plan.executionReceiptID,
          command.plan.observationEventID,
          command.plan.observationReceiptID,
          command.observationConfirmationEventID,
        ],
        in: current
      )
      let result = try adapter.createCandidateCommit(
        LiveGitCandidateExecutionRequest(
          sourceCheckoutURL: sourceCheckoutURL,
          episodeDirectoryURL: episodeDirectoryURL,
          coordinates: authority.coordinates,
          plan: command.plan,
          selectedIntent: authority.selectedIntent,
          allowance: authority.allowance,
          confirmedPreflightReceipts: authority.receipts,
          confirmedPreflightEvents: authority.events
        )
      )
      current = try appendExecution(
        result,
        to: current,
        plan: command.plan,
        authority: authority
      )
      authority = try self.authority(in: current, plan: command.plan)
    }

    guard authority.receipts.count == 4 else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate observation requires one exact durable execution receipt."
      )
    }
    try validateStoredExecution(command: command, authority: authority)
    let passportSHA256 = try adapter.candidatePassportSHA256(
      episodeDirectoryURL: episodeDirectoryURL,
      candidateOID: command.plan.policy.expectedCandidateOID
    )
    let observation = try adapter.observeCandidateCommit(
      LiveGitCandidateObservationRequest(
        episodeDirectoryURL: episodeDirectoryURL,
        coordinates: authority.coordinates,
        plan: command.plan,
        candidateOID: command.plan.policy.expectedCandidateOID,
        expectedPassportSHA256: passportSHA256
      )
    )
    current = try appendObservation(
      observation,
      to: current,
      plan: command.plan,
      authority: authority
    )
    authority = try self.authority(in: current, plan: command.plan)
    guard
      try exactStageConfirmationStatus(
        current: current,
        receipt: authority.receipts[4],
        expectedConfirmationEventID: command.observationConfirmationEventID
      ) == .unconfirmed
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "New candidate observation is not an unconfirmed exact stage generation."
      )
    }
    current = try confirm(
      current,
      eventID: command.observationConfirmationEventID
    )
    authority = try self.authority(in: current, plan: command.plan)
    guard
      try exactStageConfirmationStatus(
        current: current,
        receipt: authority.receipts[4],
        expectedConfirmationEventID: command.observationConfirmationEventID
      ) == .confirmed
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate observation confirmation was not durably recorded."
      )
    }
    return output(
      command: command,
      status: .advanced,
      current: current,
      passportSHA256: observation.passportSHA256
    )
  }

  private func appendPreflight(
    to current: StoredLiveEpisodeGeneration,
    command: LiveGitCandidateEpisodeCommand,
    commandSHA256: String,
    authority: CandidateAuthority
  ) throws -> StoredLiveEpisodeGeneration {
    let result = try adapter.preflight(
      LiveGitCandidatePreflightRequest(
        sourceCheckoutURL: sourceCheckoutURL,
        episodeDirectoryURL: episodeDirectoryURL,
        coordinates: authority.coordinates,
        plan: command.plan,
        selectedIntent: authority.selectedIntent,
        allowance: authority.allowance,
        confirmedAuthorizationReceipts: authority.receipts,
        confirmedAuthorizationEvents: authority.events
      )
    )
    guard result.preflightEventID == command.plan.preflightEventID,
      result.preflightEvidence.evidenceID == command.plan.preflightReceiptID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Preflight result does not bind the exact planned event and receipt."
      )
    }
    let event = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: command.plan.preflightEventID,
      sequence: current.state.nextSequence,
      payload: .preflightCompleted(
        LivePreflightCompleted(
          coordinates: authority.coordinates,
          authorizationEvidenceID: authority.receipts[1].evidence.evidenceID,
          status: .passed,
          evidence: result.preflightEvidence
        )
      )
    )
    let receipt = LiveGitCandidateStageReceipt(
      receiptID: command.plan.preflightReceiptID,
      eventID: command.plan.preflightEventID,
      stage: .preflightPassed,
      coordinates: authority.coordinates,
      evidence: result.preflightEvidence,
      producerID: command.plan.policy.producerIDs.preflightPassed,
      predecessor: try receiptLink(authority.receipts[1])
    )
    let state = try LiveEpisodeReducer.applying(event, to: current.state)
    return try store.commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: authority.receipts + [receipt],
      candidateExecutionCommandSHA256: commandSHA256,
      candidateObservationConfirmationEventID: command.observationConfirmationEventID,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
  }

  private func validateStoredPreflight(
    current: StoredLiveEpisodeGeneration,
    command: LiveGitCandidateEpisodeCommand,
    authority: CandidateAuthority
  ) throws {
    guard authority.receipts.count == 3,
      authority.receipts[2].eventID == command.plan.preflightEventID,
      authority.receipts[2].receiptID == command.plan.preflightReceiptID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Stored preflight does not belong to the exact candidate plan."
      )
    }
    let result = try adapter.preflight(
      LiveGitCandidatePreflightRequest(
        sourceCheckoutURL: sourceCheckoutURL,
        episodeDirectoryURL: episodeDirectoryURL,
        coordinates: authority.coordinates,
        plan: command.plan,
        selectedIntent: authority.selectedIntent,
        allowance: authority.allowance,
        confirmedAuthorizationReceipts: Array(authority.receipts.prefix(2)),
        confirmedAuthorizationEvents: Array(authority.events.prefix(2))
      )
    )
    guard authority.receipts[2].evidence == result.preflightEvidence,
      result.preflightEventID == command.plan.preflightEventID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Stored preflight evidence does not match the repeated read-only preflight."
      )
    }
  }

  private func appendExecution(
    _ result: LiveGitCandidateCommitResult,
    to current: StoredLiveEpisodeGeneration,
    plan: LiveGitCandidatePlan,
    authority: CandidateAuthority
  ) throws -> StoredLiveEpisodeGeneration {
    let executionEvent = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: plan.executionEventID,
      sequence: current.state.nextSequence,
      payload: .executionRecorded(
        LiveExecutionRecorded(
          coordinates: authority.coordinates,
          preflightEvidenceID: authority.receipts[2].evidence.evidenceID,
          status: .succeeded,
          evidence: result.executionEvidence
        )
      )
    )
    let executionReceipt = LiveGitCandidateStageReceipt(
      receiptID: plan.executionReceiptID,
      eventID: plan.executionEventID,
      stage: .executed,
      coordinates: authority.coordinates,
      evidence: result.executionEvidence,
      producerID: plan.policy.producerIDs.executed,
      predecessor: try receiptLink(authority.receipts[2])
    )
    let state = try LiveEpisodeReducer.applying(executionEvent, to: current.state)
    return try store.commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: authority.receipts + [executionReceipt],
      candidateExecutionCommandSHA256:
        current.generation.candidateReceiptJournal?.executionCommandSHA256,
      candidateObservationConfirmationEventID:
        current.generation.candidateReceiptJournal?.observationConfirmationEventID,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
  }

  private func validateStoredExecution(
    command: LiveGitCandidateEpisodeCommand,
    authority: CandidateAuthority
  ) throws {
    guard authority.receipts.count == 4,
      authority.receipts[3].eventID == command.plan.executionEventID,
      authority.receipts[3].receiptID == command.plan.executionReceiptID,
      authority.receipts[3].evidence.evidenceSHA256
        == CanonicalMemoryJSON.sha256(Data(command.plan.policy.expectedCandidateOID.utf8))
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Stored execution does not bind the exact candidate OID and stage identity."
      )
    }
  }

  private func appendObservation(
    _ result: LiveGitCandidateObservationResult,
    to current: StoredLiveEpisodeGeneration,
    plan: LiveGitCandidatePlan,
    authority: CandidateAuthority
  ) throws -> StoredLiveEpisodeGeneration {
    let observationEvent = LiveEpisodeEvent(
      episodeID: current.state.passport.episodeID,
      eventID: plan.observationEventID,
      sequence: current.state.nextSequence,
      payload: .observationRecorded(
        LiveObservationRecorded(
          coordinates: authority.coordinates,
          executionEvidenceID: authority.receipts[3].evidence.evidenceID,
          status: .observed,
          evidence: result.observationEvidence
        )
      )
    )
    let observationReceipt = LiveGitCandidateStageReceipt(
      receiptID: plan.observationReceiptID,
      eventID: plan.observationEventID,
      stage: .observed,
      coordinates: authority.coordinates,
      evidence: result.observationEvidence,
      producerID: plan.policy.producerIDs.observed,
      predecessor: try receiptLink(authority.receipts[3])
    )
    let state = try LiveEpisodeReducer.applying(observationEvent, to: current.state)
    return try store.commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: authority.receipts + [observationReceipt],
      candidateExecutionCommandSHA256:
        current.generation.candidateReceiptJournal?.executionCommandSHA256,
      candidateObservationConfirmationEventID:
        current.generation.candidateReceiptJournal?.observationConfirmationEventID,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
  }

  private func confirm(
    _ current: StoredLiveEpisodeGeneration,
    eventID: String
  ) throws -> StoredLiveEpisodeGeneration {
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
    let state = try LiveEpisodeReducer.applying(event, to: current.state)
    return try store.commit(
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
  }

  private func authority(
    in current: StoredLiveEpisodeGeneration,
    plan: LiveGitCandidatePlan
  ) throws -> CandidateAuthority {
    guard current.state.passport.actionAllowlist.count == 1,
      let allowance = current.state.passport.actionAllowlist.first,
      allowance.operation == LiveGitCandidateContract.operation,
      allowance.candidateCommitPolicy == plan.policy,
      let transition = current.state.transition,
      transition.declaration.allowanceID == allowance.allowanceID,
      let selection = current.state.model.selection,
      let selectedIntent = current.state.model.variants.compactMap(\.intent?.intent)
        .first(where: { $0.intentID == selection.sourceIntentID })
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate execution requires one exact allowance, transition, and selected intent."
      )
    }
    let planSHA256 = try plan.canonicalSHA256()
    guard transition.declaration.coordinates.expectedEffectSHA256 == planSHA256,
      selectedIntent.argumentsSHA256 == planSHA256,
      selectedIntent.expectedEffectSHA256 == planSHA256,
      selectedIntent.operation == allowance.operation,
      selectedIntent.adapterID == allowance.adapterID,
      selectedIntent.effectClass == allowance.effectClass,
      selectedIntent.objectID == transition.declaration.coordinates.objectID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Selected intent and transition do not bind the exact canonical candidate plan."
      )
    }
    let receipts = current.generation.candidateReceiptJournal?.receipts ?? []
    let receiptEventIDs = Set(receipts.map(\.eventID))
    let events = current.generation.eventJournal.events.filter {
      receiptEventIDs.contains($0.eventID)
    }
    if !receipts.isEmpty, let last = receipts.last?.stage {
      do {
        try LiveGitCandidateReceiptChain.validatePrefix(
          receipts,
          through: last,
          policy: plan.policy,
          expectedCoordinates: transition.declaration.coordinates,
          candidateOwnedEvents: events
        )
      } catch {
        throw LiveGitCandidateRuntimeError.invalidEvidence(
          "Candidate receipt authority is invalid: \(error)"
        )
      }
    }
    return CandidateAuthority(
      allowance: allowance,
      selectedIntent: selectedIntent,
      coordinates: transition.declaration.coordinates,
      receipts: receipts,
      events: events
    )
  }

  private func requireExactCompletedCandidate(
    current: StoredLiveEpisodeGeneration,
    command: LiveGitCandidateEpisodeCommand,
    commandSHA256: String,
    authority: CandidateAuthority
  ) throws -> String {
    try requireExactCommandBinding(
      current,
      commandSHA256: commandSHA256,
      observationConfirmationEventID: command.observationConfirmationEventID
    )
    guard authority.receipts.count == 5,
      authority.receipts[2].eventID == command.plan.preflightEventID,
      authority.receipts[2].receiptID == command.plan.preflightReceiptID,
      authority.receipts[3].eventID == command.plan.executionEventID,
      authority.receipts[3].receiptID == command.plan.executionReceiptID,
      authority.receipts[4].eventID == command.plan.observationEventID,
      authority.receipts[4].receiptID == command.plan.observationReceiptID,
      authority.receipts[3].evidence.evidenceSHA256
        == CanonicalMemoryJSON.sha256(Data(command.plan.policy.expectedCandidateOID.utf8))
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Confirmed candidate belongs to a different plan or stage identity."
      )
    }
    return authority.receipts[4].evidence.evidenceSHA256
  }

  private func requireExactCommandBinding(
    _ current: StoredLiveEpisodeGeneration,
    commandSHA256: String,
    observationConfirmationEventID: String
  ) throws {
    guard
      current.generation.candidateReceiptJournal?.executionCommandSHA256
        == commandSHA256,
      current.generation.candidateReceiptJournal?.observationConfirmationEventID
        == observationConfirmationEventID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Stored candidate transition belongs to a different execution command binding."
      )
    }
  }

  private func requireUnusedIdentifiers(
    _ identifiers: [String],
    in current: StoredLiveEpisodeGeneration
  ) throws {
    let receipts = current.generation.candidateReceiptJournal?.receipts ?? []
    let occupied = Set(
      current.generation.eventJournal.events.map(\.eventID)
        + receipts.map(\.receiptID)
        + receipts.map(\.evidence.evidenceID)
    )
    guard identifiers.allSatisfy({ !occupied.contains($0) }) else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "A future candidate identifier already belongs to durable episode history."
      )
    }
  }

  private func exactStageConfirmationStatus(
    current: StoredLiveEpisodeGeneration,
    receipt: LiveGitCandidateStageReceipt,
    expectedConfirmationEventID: String
  ) throws -> ExactStageConfirmationStatus {
    let events = current.generation.eventJournal.events
    guard let stageIndex = events.firstIndex(where: { $0.eventID == receipt.eventID }) else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate stage does not have its exact durable event."
      )
    }
    if stageIndex == events.count - 1 {
      return .unconfirmed
    }
    guard stageIndex == events.count - 2,
      let confirmationEvent = events.last,
      confirmationEvent.sequence == events[stageIndex].sequence + 1,
      confirmationEvent.eventID == expectedConfirmationEventID,
      case .generationConfirmed(let confirmation) = confirmationEvent.payload,
      confirmation.confirmedThroughSequence == events[stageIndex].sequence,
      let stageGenerationSHA256 = current.generation.previousGenerationSHA256,
      confirmation.generationID == String(stageGenerationSHA256.dropFirst(7)),
      current.state.confirmedGeneration?.eventID == confirmationEvent.eventID,
      current.state.confirmedGeneration?.confirmation == confirmation
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate stage requires its command-specified exact immediate generation confirmation."
      )
    }
    return .confirmed
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

  private func output(
    command: LiveGitCandidateEpisodeCommand,
    status: LiveGitCandidateEpisodeStatus,
    current: StoredLiveEpisodeGeneration,
    passportSHA256: String
  ) -> LiveGitCandidateEpisodeOutput {
    LiveGitCandidateEpisodeOutput(
      commandID: command.commandID,
      status: status,
      generationSHA256: current.generationSHA256,
      candidateOID: command.plan.policy.expectedCandidateOID,
      passportSHA256: passportSHA256
    )
  }

  private func validateCommand(_ command: LiveGitCandidateEpisodeCommand) throws {
    let identifiers = [
      command.commandID,
      command.preflightConfirmationEventID,
      command.observationConfirmationEventID,
      command.plan.preflightEventID,
      command.plan.preflightReceiptID,
      command.plan.executionEventID,
      command.plan.executionReceiptID,
      command.plan.observationEventID,
      command.plan.observationReceiptID,
    ]
    guard command.schemaVersion == LiveEpisodeRuntimeSchema.commandVersion,
      isCandidateSHA256(command.expectedGenerationSHA256),
      identifiers.allSatisfy(isCandidateIdentifier),
      Set(identifiers).count == identifiers.count
    else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Candidate episode command has an unsupported schema or invalid identities."
      )
    }
  }

  private func requireCurrent() throws -> StoredLiveEpisodeGeneration {
    guard let current = try store.loadCurrent() else {
      throw LiveEpisodeRuntimeError.noConfirmedGeneration
    }
    return current
  }
}

private struct CandidateAuthority {
  let allowance: LiveAllowedAction
  let selectedIntent: LiveUntrustedActionIntent
  let coordinates: LiveTransitionCoordinates
  let receipts: [LiveGitCandidateStageReceipt]
  let events: [LiveEpisodeEvent]
}

private enum ExactStageConfirmationStatus: Equatable {
  case unconfirmed
  case confirmed
}

private func receiptLink(
  _ receipt: LiveGitCandidateStageReceipt
) throws -> LiveGitCandidateReceiptLink {
  LiveGitCandidateReceiptLink(
    receiptID: receipt.receiptID,
    receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(receipt)
  )
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
