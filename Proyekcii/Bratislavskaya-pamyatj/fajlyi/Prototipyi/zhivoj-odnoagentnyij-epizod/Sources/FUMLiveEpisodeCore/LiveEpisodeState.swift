import Foundation

public struct LiveModelVariantState: Codable, Equatable, Sendable {
  public let requestEventID: String
  public let proposal: LiveModelInvocationProposal
  public let responseEventID: String?
  public let response: LiveModelResponseRecorded?
  public let intentEventID: String?
  public let intent: LiveUntrustedIntentParsed?
  public let verificationEventIDs: [String]
  public let verifications: [LiveVerificationRecorded]

  init(
    requestEventID: String,
    proposal: LiveModelInvocationProposal,
    responseEventID: String? = nil,
    response: LiveModelResponseRecorded? = nil,
    intentEventID: String? = nil,
    intent: LiveUntrustedIntentParsed? = nil,
    verificationEventIDs: [String] = [],
    verifications: [LiveVerificationRecorded] = []
  ) {
    self.requestEventID = requestEventID
    self.proposal = proposal
    self.responseEventID = responseEventID
    self.response = response
    self.intentEventID = intentEventID
    self.intent = intent
    self.verificationEventIDs = verificationEventIDs
    self.verifications = verifications
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case requestEventID = "request_event_id"
    case proposal
    case responseEventID = "response_event_id"
    case response
    case intentEventID = "intent_event_id"
    case intent
    case verificationEventIDs = "verification_event_ids"
    case verifications
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requestEventID = try container.decode(String.self, forKey: .requestEventID)
    proposal = try container.decode(LiveModelInvocationProposal.self, forKey: .proposal)
    responseEventID = try container.decodeIfPresent(String.self, forKey: .responseEventID)
    response = try container.decodeIfPresent(LiveModelResponseRecorded.self, forKey: .response)
    intentEventID = try container.decodeIfPresent(String.self, forKey: .intentEventID)
    intent = try container.decodeIfPresent(LiveUntrustedIntentParsed.self, forKey: .intent)
    verificationEventIDs = try container.decode([String].self, forKey: .verificationEventIDs)
    verifications = try container.decode([LiveVerificationRecorded].self, forKey: .verifications)
  }
}

public struct LiveModelAxisState: Codable, Equatable, Sendable {
  public let commonCheckpointEventID: String?
  public let commonCheckpoint: LiveModelCheckpointCreated?
  public let variants: [LiveModelVariantState]
  public let selectionEventID: String?
  public let selection: LiveModelSelectionRecorded?
  public let budget: LiveBudgetState

  init(
    commonCheckpointEventID: String? = nil,
    commonCheckpoint: LiveModelCheckpointCreated? = nil,
    variants: [LiveModelVariantState] = [],
    selectionEventID: String? = nil,
    selection: LiveModelSelectionRecorded? = nil,
    budget: LiveBudgetState
  ) {
    self.commonCheckpointEventID = commonCheckpointEventID
    self.commonCheckpoint = commonCheckpoint
    self.variants = variants
    self.selectionEventID = selectionEventID
    self.selection = selection
    self.budget = budget
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case commonCheckpointEventID = "common_checkpoint_event_id"
    case commonCheckpoint = "common_checkpoint"
    case variants
    case selectionEventID = "selection_event_id"
    case selection
    case budget
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    commonCheckpointEventID = try container.decodeIfPresent(
      String.self,
      forKey: .commonCheckpointEventID
    )
    commonCheckpoint = try container.decodeIfPresent(
      LiveModelCheckpointCreated.self,
      forKey: .commonCheckpoint
    )
    variants = try container.decode([LiveModelVariantState].self, forKey: .variants)
    selectionEventID = try container.decodeIfPresent(String.self, forKey: .selectionEventID)
    selection = try container.decodeIfPresent(LiveModelSelectionRecorded.self, forKey: .selection)
    budget = try container.decode(LiveBudgetState.self, forKey: .budget)
  }
}

public enum LiveTransitionPhase: String, Codable, Equatable, Sendable {
  case awaitingConfirmation = "awaiting_confirmation"
  case transitionUserConfirmed = "transition_user_confirmed"
  case authorized
  case authorizationDenied = "authorization_denied"
  case preflightPassed = "preflight_passed"
  case preflightFailed = "preflight_failed"
  case executed
  case executionFailed = "execution_failed"
  case observed
  case observationFailed = "observation_failed"
  case verified
  case verificationFailed = "verification_failed"
}

public struct LiveTransitionAxisState: Codable, Equatable, Sendable {
  public let declarationEventID: String
  public let declaration: LivePendingTransitionDeclared
  public let confirmationEventID: String?
  public let confirmation: LiveTransitionUserConfirmed?
  public let authorizationEventID: String?
  public let authorization: LiveAuthorizationDecided?
  public let preflightEventID: String?
  public let preflight: LivePreflightCompleted?
  public let executionEventID: String?
  public let execution: LiveExecutionRecorded?
  public let observationEventID: String?
  public let observation: LiveObservationRecorded?
  public let verificationEventID: String?
  public let verification: LiveVerificationRecorded?

  public var phase: LiveTransitionPhase {
    if let verification {
      return verification.status == .passed ? .verified : .verificationFailed
    }
    if let observation {
      return observation.status == .observed ? .observed : .observationFailed
    }
    if let execution {
      return execution.status == .succeeded ? .executed : .executionFailed
    }
    if let preflight {
      return preflight.status == .passed ? .preflightPassed : .preflightFailed
    }
    if let authorization {
      return authorization.decision == .allowed ? .authorized : .authorizationDenied
    }
    if confirmation != nil { return .transitionUserConfirmed }
    return .awaitingConfirmation
  }

  init(
    declarationEventID: String,
    declaration: LivePendingTransitionDeclared,
    confirmationEventID: String? = nil,
    confirmation: LiveTransitionUserConfirmed? = nil,
    authorizationEventID: String? = nil,
    authorization: LiveAuthorizationDecided? = nil,
    preflightEventID: String? = nil,
    preflight: LivePreflightCompleted? = nil,
    executionEventID: String? = nil,
    execution: LiveExecutionRecorded? = nil,
    observationEventID: String? = nil,
    observation: LiveObservationRecorded? = nil,
    verificationEventID: String? = nil,
    verification: LiveVerificationRecorded? = nil
  ) {
    self.declarationEventID = declarationEventID
    self.declaration = declaration
    self.confirmationEventID = confirmationEventID
    self.confirmation = confirmation
    self.authorizationEventID = authorizationEventID
    self.authorization = authorization
    self.preflightEventID = preflightEventID
    self.preflight = preflight
    self.executionEventID = executionEventID
    self.execution = execution
    self.observationEventID = observationEventID
    self.observation = observation
    self.verificationEventID = verificationEventID
    self.verification = verification
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case declarationEventID = "declaration_event_id"
    case declaration
    case confirmationEventID = "confirmation_event_id"
    case confirmation
    case authorizationEventID = "authorization_event_id"
    case authorization
    case preflightEventID = "preflight_event_id"
    case preflight
    case executionEventID = "execution_event_id"
    case execution
    case observationEventID = "observation_event_id"
    case observation
    case verificationEventID = "verification_event_id"
    case verification
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    declarationEventID = try container.decode(String.self, forKey: .declarationEventID)
    declaration = try container.decode(LivePendingTransitionDeclared.self, forKey: .declaration)
    confirmationEventID = try container.decodeIfPresent(String.self, forKey: .confirmationEventID)
    confirmation = try container.decodeIfPresent(
      LiveTransitionUserConfirmed.self,
      forKey: .confirmation
    )
    authorizationEventID = try container.decodeIfPresent(
      String.self,
      forKey: .authorizationEventID
    )
    authorization = try container.decodeIfPresent(
      LiveAuthorizationDecided.self,
      forKey: .authorization
    )
    preflightEventID = try container.decodeIfPresent(String.self, forKey: .preflightEventID)
    preflight = try container.decodeIfPresent(LivePreflightCompleted.self, forKey: .preflight)
    executionEventID = try container.decodeIfPresent(String.self, forKey: .executionEventID)
    execution = try container.decodeIfPresent(LiveExecutionRecorded.self, forKey: .execution)
    observationEventID = try container.decodeIfPresent(String.self, forKey: .observationEventID)
    observation = try container.decodeIfPresent(LiveObservationRecorded.self, forKey: .observation)
    verificationEventID = try container.decodeIfPresent(
      String.self,
      forKey: .verificationEventID
    )
    verification = try container.decodeIfPresent(
      LiveVerificationRecorded.self,
      forKey: .verification
    )
  }
}

public struct LiveBudgetCheckpointState: Codable, Equatable, Sendable {
  public let eventID: String
  public let checkpoint: LiveBudgetCheckpointCreated

  init(eventID: String, checkpoint: LiveBudgetCheckpointCreated) {
    self.eventID = eventID
    self.checkpoint = checkpoint
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case eventID = "event_id"
    case checkpoint
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    eventID = try container.decode(String.self, forKey: .eventID)
    checkpoint = try container.decode(LiveBudgetCheckpointCreated.self, forKey: .checkpoint)
  }
}

public struct LiveGenerationConfirmationState: Codable, Equatable, Sendable {
  public let eventID: String
  public let confirmation: LiveGenerationConfirmed

  init(eventID: String, confirmation: LiveGenerationConfirmed) {
    self.eventID = eventID
    self.confirmation = confirmation
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case eventID = "event_id"
    case confirmation
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    eventID = try container.decode(String.self, forKey: .eventID)
    confirmation = try container.decode(LiveGenerationConfirmed.self, forKey: .confirmation)
  }
}

public struct LiveContinuationState: Codable, Equatable, Sendable {
  public let eventID: String
  public let continuation: LiveContinuationDecided

  init(eventID: String, continuation: LiveContinuationDecided) {
    self.eventID = eventID
    self.continuation = continuation
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case eventID = "event_id"
    case continuation
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    eventID = try container.decode(String.self, forKey: .eventID)
    continuation = try container.decode(LiveContinuationDecided.self, forKey: .continuation)
  }
}

public struct LiveEpisodeState: Codable, Equatable, Sendable {
  public let passport: LiveEpisodePassport
  public let nextSequence: Int64
  public let events: [LiveEpisodeEvent]
  public let model: LiveModelAxisState
  public let transition: LiveTransitionAxisState?
  public let latestBudgetCheckpoint: LiveBudgetCheckpointState?
  public let confirmedGeneration: LiveGenerationConfirmationState?
  public let continuation: LiveContinuationState?

  init(
    passport: LiveEpisodePassport,
    nextSequence: Int64,
    events: [LiveEpisodeEvent],
    model: LiveModelAxisState,
    transition: LiveTransitionAxisState?,
    latestBudgetCheckpoint: LiveBudgetCheckpointState?,
    confirmedGeneration: LiveGenerationConfirmationState?,
    continuation: LiveContinuationState?
  ) {
    self.passport = passport
    self.nextSequence = nextSequence
    self.events = events
    self.model = model
    self.transition = transition
    self.latestBudgetCheckpoint = latestBudgetCheckpoint
    self.confirmedGeneration = confirmedGeneration
    self.continuation = continuation
  }

  public var isTerminal: Bool {
    guard let decision = continuation?.continuation.decision else { return false }
    return decision != .continue
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case passport
    case nextSequence = "next_sequence"
    case events
    case model
    case transition
    case latestBudgetCheckpoint = "latest_budget_checkpoint"
    case confirmedGeneration = "confirmed_generation"
    case continuation
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    passport = try container.decode(LiveEpisodePassport.self, forKey: .passport)
    nextSequence = try container.decode(Int64.self, forKey: .nextSequence)
    events = try container.decode([LiveEpisodeEvent].self, forKey: .events)
    model = try container.decode(LiveModelAxisState.self, forKey: .model)
    transition = try container.decodeIfPresent(LiveTransitionAxisState.self, forKey: .transition)
    latestBudgetCheckpoint = try container.decodeIfPresent(
      LiveBudgetCheckpointState.self,
      forKey: .latestBudgetCheckpoint
    )
    confirmedGeneration = try container.decodeIfPresent(
      LiveGenerationConfirmationState.self,
      forKey: .confirmedGeneration
    )
    continuation = try container.decodeIfPresent(LiveContinuationState.self, forKey: .continuation)
  }
}
