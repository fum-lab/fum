import Foundation

struct LiveAnyCodingKey: CodingKey {
  let stringValue: String
  let intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init?(intValue: Int) {
    self.stringValue = String(intValue)
    self.intValue = intValue
  }
}

func liveRejectUnknownKeys<Key: CodingKey & CaseIterable>(
  _ decoder: Decoder,
  allowed _: Key.Type
) throws {
  let container = try decoder.container(keyedBy: LiveAnyCodingKey.self)
  let allowedKeys = Set(Key.allCases.map(\.stringValue))
  let unknownKeys = container.allKeys.map(\.stringValue).filter { !allowedKeys.contains($0) }
  guard unknownKeys.isEmpty else {
    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Неизвестные поля: \(unknownKeys.sorted().joined(separator: ", "))."
      )
    )
  }
}

public enum LiveEpisodeSchema {
  public static let identity = "fum.live_single_agent_episode.event"
  public static let version = 1
}

public enum LiveExecutionMode: String, Codable, Equatable, Sendable {
  case local
  case remote
}

public enum LiveMoneyUnit: String, Codable, Equatable, Sendable {
  case none
  case usdMicrounit = "usd_microunit"
}

public enum LiveDisclosureClass: String, Codable, Equatable, Sendable {
  case synthetic
  case projectPublic = "project_public"
  case userData = "user_data"
  case secret
}

public struct LiveBudget: Codable, Equatable, Sendable {
  public let calls: Int64
  public let inputTokens: Int64
  public let outputTokens: Int64
  public let wallClockMilliseconds: Int64
  public let computeUnits: Int64
  public let moneyMicrounits: Int64

  public init(
    calls: Int64,
    inputTokens: Int64,
    outputTokens: Int64,
    wallClockMilliseconds: Int64,
    computeUnits: Int64,
    moneyMicrounits: Int64
  ) {
    self.calls = calls
    self.inputTokens = inputTokens
    self.outputTokens = outputTokens
    self.wallClockMilliseconds = wallClockMilliseconds
    self.computeUnits = computeUnits
    self.moneyMicrounits = moneyMicrounits
  }

  public static let zero = LiveBudget(
    calls: 0,
    inputTokens: 0,
    outputTokens: 0,
    wallClockMilliseconds: 0,
    computeUnits: 0,
    moneyMicrounits: 0
  )

  enum CodingKeys: String, CodingKey, CaseIterable {
    case calls
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case wallClockMilliseconds = "wall_clock_milliseconds"
    case computeUnits = "compute_units"
    case moneyMicrounits = "money_microunits"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    calls = try container.decode(Int64.self, forKey: .calls)
    inputTokens = try container.decode(Int64.self, forKey: .inputTokens)
    outputTokens = try container.decode(Int64.self, forKey: .outputTokens)
    wallClockMilliseconds = try container.decode(Int64.self, forKey: .wallClockMilliseconds)
    computeUnits = try container.decode(Int64.self, forKey: .computeUnits)
    moneyMicrounits = try container.decode(Int64.self, forKey: .moneyMicrounits)
  }
}

public struct LiveBudgetState: Codable, Equatable, Sendable {
  public let maximum: LiveBudget
  public let reserved: LiveBudget
  public let charged: LiveBudget

  public init(
    maximum: LiveBudget,
    reserved: LiveBudget = .zero,
    charged: LiveBudget = .zero
  ) {
    self.maximum = maximum
    self.reserved = reserved
    self.charged = charged
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case maximum
    case reserved
    case charged
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    maximum = try container.decode(LiveBudget.self, forKey: .maximum)
    reserved = try container.decode(LiveBudget.self, forKey: .reserved)
    charged = try container.decode(LiveBudget.self, forKey: .charged)
  }
}

public struct LiveProviderIdentity: Codable, Equatable, Sendable {
  public let providerID: String
  public let interfaceID: String
  public let modelID: String
  public let runtimeID: String

  public init(providerID: String, interfaceID: String, modelID: String, runtimeID: String) {
    self.providerID = providerID
    self.interfaceID = interfaceID
    self.modelID = modelID
    self.runtimeID = runtimeID
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case providerID = "provider_id"
    case interfaceID = "interface_id"
    case modelID = "model_id"
    case runtimeID = "runtime_id"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    providerID = try container.decode(String.self, forKey: .providerID)
    interfaceID = try container.decode(String.self, forKey: .interfaceID)
    modelID = try container.decode(String.self, forKey: .modelID)
    runtimeID = try container.decode(String.self, forKey: .runtimeID)
  }
}

public struct LiveDisclosurePolicy: Codable, Equatable, Sendable {
  public let allowedClasses: [LiveDisclosureClass]
  public let maximumInputBytes: Int64
  public let allowedPurposes: [String]

  public init(
    allowedClasses: [LiveDisclosureClass],
    maximumInputBytes: Int64,
    allowedPurposes: [String]
  ) {
    self.allowedClasses = allowedClasses
    self.maximumInputBytes = maximumInputBytes
    self.allowedPurposes = allowedPurposes
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case allowedClasses = "allowed_classes"
    case maximumInputBytes = "maximum_input_bytes"
    case allowedPurposes = "allowed_purposes"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    allowedClasses = try container.decode([LiveDisclosureClass].self, forKey: .allowedClasses)
    maximumInputBytes = try container.decode(Int64.self, forKey: .maximumInputBytes)
    allowedPurposes = try container.decode([String].self, forKey: .allowedPurposes)
  }
}

public struct LiveModelPolicy: Codable, Equatable, Sendable {
  public let profileID: String
  public let executionMode: LiveExecutionMode
  public let providerIdentity: LiveProviderIdentity
  public let disclosure: LiveDisclosurePolicy
  public let moneyUnit: LiveMoneyUnit
  public let maximumBudget: LiveBudget
  public let perInvocationReservation: LiveBudget
  public let maximumVariants: Int64

  public init(
    profileID: String,
    executionMode: LiveExecutionMode,
    providerIdentity: LiveProviderIdentity,
    disclosure: LiveDisclosurePolicy,
    moneyUnit: LiveMoneyUnit,
    maximumBudget: LiveBudget,
    perInvocationReservation: LiveBudget,
    maximumVariants: Int64
  ) {
    self.profileID = profileID
    self.executionMode = executionMode
    self.providerIdentity = providerIdentity
    self.disclosure = disclosure
    self.moneyUnit = moneyUnit
    self.maximumBudget = maximumBudget
    self.perInvocationReservation = perInvocationReservation
    self.maximumVariants = maximumVariants
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case profileID = "profile_id"
    case executionMode = "execution_mode"
    case providerIdentity = "provider_identity"
    case disclosure
    case moneyUnit = "money_unit"
    case maximumBudget = "maximum_budget"
    case perInvocationReservation = "per_invocation_reservation"
    case maximumVariants = "maximum_variants"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    profileID = try container.decode(String.self, forKey: .profileID)
    executionMode = try container.decode(LiveExecutionMode.self, forKey: .executionMode)
    providerIdentity = try container.decode(LiveProviderIdentity.self, forKey: .providerIdentity)
    disclosure = try container.decode(LiveDisclosurePolicy.self, forKey: .disclosure)
    moneyUnit = try container.decode(LiveMoneyUnit.self, forKey: .moneyUnit)
    maximumBudget = try container.decode(LiveBudget.self, forKey: .maximumBudget)
    perInvocationReservation = try container.decode(
      LiveBudget.self,
      forKey: .perInvocationReservation
    )
    maximumVariants = try container.decode(Int64.self, forKey: .maximumVariants)
  }
}

public struct LiveEpisodeGoal: Codable, Equatable, Sendable {
  public let goalID: String
  public let summary: String

  public init(goalID: String, summary: String) {
    self.goalID = goalID
    self.summary = summary
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case goalID = "goal_id"
    case summary
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    goalID = try container.decode(String.self, forKey: .goalID)
    summary = try container.decode(String.self, forKey: .summary)
  }
}

public struct LiveEpisodeContext: Codable, Equatable, Sendable {
  public let objectID: String
  public let contentSHA256: String
  public let disclosureClass: LiveDisclosureClass
  public let purpose: String

  public init(
    objectID: String,
    contentSHA256: String,
    disclosureClass: LiveDisclosureClass,
    purpose: String
  ) {
    self.objectID = objectID
    self.contentSHA256 = contentSHA256
    self.disclosureClass = disclosureClass
    self.purpose = purpose
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case objectID = "object_id"
    case contentSHA256 = "content_sha256"
    case disclosureClass = "disclosure_class"
    case purpose
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    objectID = try container.decode(String.self, forKey: .objectID)
    contentSHA256 = try container.decode(String.self, forKey: .contentSHA256)
    disclosureClass = try container.decode(LiveDisclosureClass.self, forKey: .disclosureClass)
    purpose = try container.decode(String.self, forKey: .purpose)
  }
}

public struct LiveAllowedAction: Codable, Equatable, Sendable {
  public let allowanceID: String
  public let operation: String
  public let adapterID: String
  public let effectClass: String
  public let candidateCommitPolicy: LiveGitCandidateCommitPolicy?

  public init(
    allowanceID: String,
    operation: String,
    adapterID: String,
    effectClass: String,
    candidateCommitPolicy: LiveGitCandidateCommitPolicy? = nil
  ) {
    self.allowanceID = allowanceID
    self.operation = operation
    self.adapterID = adapterID
    self.effectClass = effectClass
    self.candidateCommitPolicy = candidateCommitPolicy
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case allowanceID = "allowance_id"
    case operation
    case adapterID = "adapter_id"
    case effectClass = "effect_class"
    case candidateCommitPolicy = "candidate_commit_policy"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    allowanceID = try container.decode(String.self, forKey: .allowanceID)
    operation = try container.decode(String.self, forKey: .operation)
    adapterID = try container.decode(String.self, forKey: .adapterID)
    effectClass = try container.decode(String.self, forKey: .effectClass)
    candidateCommitPolicy = try container.decodeIfPresent(
      LiveGitCandidateCommitPolicy.self,
      forKey: .candidateCommitPolicy
    )
  }
}

public struct LiveVerificationCriterion: Codable, Equatable, Sendable {
  public let criterionID: String
  public let subject: String
  public let verifierID: String
  public let expectedResult: String

  public init(
    criterionID: String,
    subject: String,
    verifierID: String,
    expectedResult: String
  ) {
    self.criterionID = criterionID
    self.subject = subject
    self.verifierID = verifierID
    self.expectedResult = expectedResult
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case criterionID = "criterion_id"
    case subject
    case verifierID = "verifier_id"
    case expectedResult = "expected_result"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    criterionID = try container.decode(String.self, forKey: .criterionID)
    subject = try container.decode(String.self, forKey: .subject)
    verifierID = try container.decode(String.self, forKey: .verifierID)
    expectedResult = try container.decode(String.self, forKey: .expectedResult)
  }
}

public struct LiveCheckpointPolicy: Codable, Equatable, Sendable {
  public let checkpointOnBudgetRejection: Bool
  public let requireCheckpointForTransitionConfirmation: Bool
  public let requireConfirmedGenerationForContinuation: Bool

  public init(
    checkpointOnBudgetRejection: Bool,
    requireCheckpointForTransitionConfirmation: Bool,
    requireConfirmedGenerationForContinuation: Bool
  ) {
    self.checkpointOnBudgetRejection = checkpointOnBudgetRejection
    self.requireCheckpointForTransitionConfirmation =
      requireCheckpointForTransitionConfirmation
    self.requireConfirmedGenerationForContinuation = requireConfirmedGenerationForContinuation
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case checkpointOnBudgetRejection = "checkpoint_on_budget_rejection"
    case requireCheckpointForTransitionConfirmation =
      "require_checkpoint_for_transition_confirmation"
    case requireConfirmedGenerationForContinuation =
      "require_confirmed_generation_for_continuation"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checkpointOnBudgetRejection = try container.decode(
      Bool.self,
      forKey: .checkpointOnBudgetRejection
    )
    requireCheckpointForTransitionConfirmation = try container.decode(
      Bool.self,
      forKey: .requireCheckpointForTransitionConfirmation
    )
    requireConfirmedGenerationForContinuation = try container.decode(
      Bool.self,
      forKey: .requireConfirmedGenerationForContinuation
    )
  }
}

public enum LiveTerminalOutcome: String, Codable, Equatable, Sendable {
  case completed
  case needsInput = "needs_input"
  case budgetExhausted = "budget_exhausted"
  case blocked
  case refused
  case cancelled
  case failed
}

public struct LiveEpisodePassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let episodeID: String
  public let goal: LiveEpisodeGoal
  public let context: LiveEpisodeContext
  public let modelPolicy: LiveModelPolicy
  public let actionAllowlist: [LiveAllowedAction]
  public let verificationCriteria: [LiveVerificationCriterion]
  public let checkpointPolicy: LiveCheckpointPolicy
  public let terminalOutcomes: [LiveTerminalOutcome]

  public init(
    schemaIdentity: String = LiveEpisodeSchema.identity,
    schemaVersion: Int = LiveEpisodeSchema.version,
    episodeID: String,
    goal: LiveEpisodeGoal,
    context: LiveEpisodeContext,
    modelPolicy: LiveModelPolicy,
    actionAllowlist: [LiveAllowedAction],
    verificationCriteria: [LiveVerificationCriterion],
    checkpointPolicy: LiveCheckpointPolicy,
    terminalOutcomes: [LiveTerminalOutcome]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.goal = goal
    self.context = context
    self.modelPolicy = modelPolicy
    self.actionAllowlist = actionAllowlist
    self.verificationCriteria = verificationCriteria
    self.checkpointPolicy = checkpointPolicy
    self.terminalOutcomes = terminalOutcomes
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case goal
    case context
    case modelPolicy = "model_policy"
    case actionAllowlist = "action_allowlist"
    case verificationCriteria = "verification_criteria"
    case checkpointPolicy = "checkpoint_policy"
    case terminalOutcomes = "terminal_outcomes"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    episodeID = try container.decode(String.self, forKey: .episodeID)
    goal = try container.decode(LiveEpisodeGoal.self, forKey: .goal)
    context = try container.decode(LiveEpisodeContext.self, forKey: .context)
    modelPolicy = try container.decode(LiveModelPolicy.self, forKey: .modelPolicy)
    actionAllowlist = try container.decode([LiveAllowedAction].self, forKey: .actionAllowlist)
    verificationCriteria = try container.decode(
      [LiveVerificationCriterion].self,
      forKey: .verificationCriteria
    )
    checkpointPolicy = try container.decode(LiveCheckpointPolicy.self, forKey: .checkpointPolicy)
    terminalOutcomes = try container.decode([LiveTerminalOutcome].self, forKey: .terminalOutcomes)
  }
}

public struct LiveTransitionCoordinates: Codable, Equatable, Sendable {
  public let episodeID: String
  public let transitionID: String
  public let schemaVersion: Int
  public let objectID: String
  public let expectedEffectSHA256: String

  public init(
    episodeID: String,
    transitionID: String,
    schemaVersion: Int = LiveEpisodeSchema.version,
    objectID: String,
    expectedEffectSHA256: String
  ) {
    self.episodeID = episodeID
    self.transitionID = transitionID
    self.schemaVersion = schemaVersion
    self.objectID = objectID
    self.expectedEffectSHA256 = expectedEffectSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case episodeID = "episode_id"
    case transitionID = "transition_id"
    case schemaVersion = "schema_version"
    case objectID = "object_id"
    case expectedEffectSHA256 = "expected_effect_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    episodeID = try container.decode(String.self, forKey: .episodeID)
    transitionID = try container.decode(String.self, forKey: .transitionID)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    objectID = try container.decode(String.self, forKey: .objectID)
    expectedEffectSHA256 = try container.decode(String.self, forKey: .expectedEffectSHA256)
  }
}

public struct LiveEvidenceObject: Codable, Equatable, Sendable {
  public let evidenceID: String
  public let evidenceSHA256: String

  public init(evidenceID: String, evidenceSHA256: String) {
    self.evidenceID = evidenceID
    self.evidenceSHA256 = evidenceSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case evidenceID = "evidence_id"
    case evidenceSHA256 = "evidence_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    evidenceID = try container.decode(String.self, forKey: .evidenceID)
    evidenceSHA256 = try container.decode(String.self, forKey: .evidenceSHA256)
  }
}

public struct LiveModelCheckpointCreated: Codable, Equatable, Sendable {
  public let checkpointID: String
  public let ancestorSHA256: String

  public init(checkpointID: String, ancestorSHA256: String) {
    self.checkpointID = checkpointID
    self.ancestorSHA256 = ancestorSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case checkpointID = "checkpoint_id"
    case ancestorSHA256 = "ancestor_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checkpointID = try container.decode(String.self, forKey: .checkpointID)
    ancestorSHA256 = try container.decode(String.self, forKey: .ancestorSHA256)
  }
}

public struct LivePendingTransitionDeclared: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let allowanceID: String
  public let parentCheckpointID: String

  public init(
    coordinates: LiveTransitionCoordinates,
    allowanceID: String,
    parentCheckpointID: String
  ) {
    self.coordinates = coordinates
    self.allowanceID = allowanceID
    self.parentCheckpointID = parentCheckpointID
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case allowanceID = "allowance_id"
    case parentCheckpointID = "parent_checkpoint_id"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    allowanceID = try container.decode(String.self, forKey: .allowanceID)
    parentCheckpointID = try container.decode(String.self, forKey: .parentCheckpointID)
  }
}

public struct LiveModelInvocationProposal: Codable, Equatable, Sendable {
  public let requestID: String
  public let variantID: String
  public let parentCheckpointID: String
  public let inputObjectID: String
  public let inputSHA256: String
  public let disclosureClass: LiveDisclosureClass
  public let purpose: String
  public let reservation: LiveBudget

  public init(
    requestID: String,
    variantID: String,
    parentCheckpointID: String,
    inputObjectID: String,
    inputSHA256: String,
    disclosureClass: LiveDisclosureClass,
    purpose: String,
    reservation: LiveBudget
  ) {
    self.requestID = requestID
    self.variantID = variantID
    self.parentCheckpointID = parentCheckpointID
    self.inputObjectID = inputObjectID
    self.inputSHA256 = inputSHA256
    self.disclosureClass = disclosureClass
    self.purpose = purpose
    self.reservation = reservation
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case requestID = "request_id"
    case variantID = "variant_id"
    case parentCheckpointID = "parent_checkpoint_id"
    case inputObjectID = "input_object_id"
    case inputSHA256 = "input_sha256"
    case disclosureClass = "disclosure_class"
    case purpose
    case reservation
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requestID = try container.decode(String.self, forKey: .requestID)
    variantID = try container.decode(String.self, forKey: .variantID)
    parentCheckpointID = try container.decode(String.self, forKey: .parentCheckpointID)
    inputObjectID = try container.decode(String.self, forKey: .inputObjectID)
    inputSHA256 = try container.decode(String.self, forKey: .inputSHA256)
    disclosureClass = try container.decode(LiveDisclosureClass.self, forKey: .disclosureClass)
    purpose = try container.decode(String.self, forKey: .purpose)
    reservation = try container.decode(LiveBudget.self, forKey: .reservation)
  }
}

public struct LiveModelRequestRecorded: Codable, Equatable, Sendable {
  public let proposal: LiveModelInvocationProposal

  public init(proposal: LiveModelInvocationProposal) {
    self.proposal = proposal
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case proposal
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    proposal = try container.decode(LiveModelInvocationProposal.self, forKey: .proposal)
  }
}

public enum LiveModelResponseStatus: String, Codable, Equatable, Sendable {
  case completed
  case failed
}

public struct LiveModelResponseRecorded: Codable, Equatable, Sendable {
  public let responseID: String
  public let requestID: String
  public let variantID: String
  public let providerIdentity: LiveProviderIdentity
  public let status: LiveModelResponseStatus
  public let output: String
  public let outputSHA256: String
  public let charged: LiveBudget

  public init(
    responseID: String,
    requestID: String,
    variantID: String,
    providerIdentity: LiveProviderIdentity,
    status: LiveModelResponseStatus,
    output: String,
    outputSHA256: String,
    charged: LiveBudget
  ) {
    self.responseID = responseID
    self.requestID = requestID
    self.variantID = variantID
    self.providerIdentity = providerIdentity
    self.status = status
    self.output = output
    self.outputSHA256 = outputSHA256
    self.charged = charged
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case responseID = "response_id"
    case requestID = "request_id"
    case variantID = "variant_id"
    case providerIdentity = "provider_identity"
    case status
    case output
    case outputSHA256 = "output_sha256"
    case charged
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    responseID = try container.decode(String.self, forKey: .responseID)
    requestID = try container.decode(String.self, forKey: .requestID)
    variantID = try container.decode(String.self, forKey: .variantID)
    providerIdentity = try container.decode(LiveProviderIdentity.self, forKey: .providerIdentity)
    status = try container.decode(LiveModelResponseStatus.self, forKey: .status)
    output = try container.decode(String.self, forKey: .output)
    outputSHA256 = try container.decode(String.self, forKey: .outputSHA256)
    charged = try container.decode(LiveBudget.self, forKey: .charged)
  }
}

public struct LiveUntrustedActionIntent: Codable, Equatable, Sendable {
  public let intentID: String
  public let operation: String
  public let adapterID: String
  public let effectClass: String
  public let objectID: String
  public let expectedEffectSHA256: String
  public let argumentsSHA256: String

  public init(
    intentID: String,
    operation: String,
    adapterID: String,
    effectClass: String,
    objectID: String,
    expectedEffectSHA256: String,
    argumentsSHA256: String
  ) {
    self.intentID = intentID
    self.operation = operation
    self.adapterID = adapterID
    self.effectClass = effectClass
    self.objectID = objectID
    self.expectedEffectSHA256 = expectedEffectSHA256
    self.argumentsSHA256 = argumentsSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case intentID = "intent_id"
    case operation
    case adapterID = "adapter_id"
    case effectClass = "effect_class"
    case objectID = "object_id"
    case expectedEffectSHA256 = "expected_effect_sha256"
    case argumentsSHA256 = "arguments_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    intentID = try container.decode(String.self, forKey: .intentID)
    operation = try container.decode(String.self, forKey: .operation)
    adapterID = try container.decode(String.self, forKey: .adapterID)
    effectClass = try container.decode(String.self, forKey: .effectClass)
    objectID = try container.decode(String.self, forKey: .objectID)
    expectedEffectSHA256 = try container.decode(String.self, forKey: .expectedEffectSHA256)
    argumentsSHA256 = try container.decode(String.self, forKey: .argumentsSHA256)
  }
}

public struct LiveUntrustedIntentParsed: Codable, Equatable, Sendable {
  public let variantID: String
  public let sourceResponseID: String
  public let intent: LiveUntrustedActionIntent

  public init(
    variantID: String,
    sourceResponseID: String,
    intent: LiveUntrustedActionIntent
  ) {
    self.variantID = variantID
    self.sourceResponseID = sourceResponseID
    self.intent = intent
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case variantID = "variant_id"
    case sourceResponseID = "source_response_id"
    case intent
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    variantID = try container.decode(String.self, forKey: .variantID)
    sourceResponseID = try container.decode(String.self, forKey: .sourceResponseID)
    intent = try container.decode(LiveUntrustedActionIntent.self, forKey: .intent)
  }
}

public enum LiveModelSelectionStatus: String, Codable, Equatable, Sendable {
  case selectedInModel = "selected_in_model"
}

public struct LiveModelSelectionRecorded: Codable, Equatable, Sendable {
  public let selectionID: String
  public let status: LiveModelSelectionStatus
  public let selectedVariantID: String
  public let sourceResponseID: String
  public let sourceIntentID: String
  public let consideredVariantIDs: [String]
  public let basisVerificationIDs: [String]

  public init(
    selectionID: String,
    status: LiveModelSelectionStatus = .selectedInModel,
    selectedVariantID: String,
    sourceResponseID: String,
    sourceIntentID: String,
    consideredVariantIDs: [String],
    basisVerificationIDs: [String]
  ) {
    self.selectionID = selectionID
    self.status = status
    self.selectedVariantID = selectedVariantID
    self.sourceResponseID = sourceResponseID
    self.sourceIntentID = sourceIntentID
    self.consideredVariantIDs = consideredVariantIDs
    self.basisVerificationIDs = basisVerificationIDs
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case selectionID = "selection_id"
    case status
    case selectedVariantID = "selected_variant_id"
    case sourceResponseID = "source_response_id"
    case sourceIntentID = "source_intent_id"
    case consideredVariantIDs = "considered_variant_ids"
    case basisVerificationIDs = "basis_verification_ids"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    selectionID = try container.decode(String.self, forKey: .selectionID)
    status = try container.decode(LiveModelSelectionStatus.self, forKey: .status)
    selectedVariantID = try container.decode(String.self, forKey: .selectedVariantID)
    sourceResponseID = try container.decode(String.self, forKey: .sourceResponseID)
    sourceIntentID = try container.decode(String.self, forKey: .sourceIntentID)
    consideredVariantIDs = try container.decode([String].self, forKey: .consideredVariantIDs)
    basisVerificationIDs = try container.decode([String].self, forKey: .basisVerificationIDs)
  }
}

public struct LiveTransitionUserConfirmed: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let evidence: LiveEvidenceObject

  public init(coordinates: LiveTransitionCoordinates, evidence: LiveEvidenceObject) {
    self.coordinates = coordinates
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LiveAuthorizationDecision: String, Codable, Equatable, Sendable {
  case allowed
  case denied
}

public struct LiveAuthorizationDecided: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let intentID: String
  public let allowanceID: String
  public let decision: LiveAuthorizationDecision
  public let evidence: LiveEvidenceObject

  public init(
    coordinates: LiveTransitionCoordinates,
    intentID: String,
    allowanceID: String,
    decision: LiveAuthorizationDecision,
    evidence: LiveEvidenceObject
  ) {
    self.coordinates = coordinates
    self.intentID = intentID
    self.allowanceID = allowanceID
    self.decision = decision
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case intentID = "intent_id"
    case allowanceID = "allowance_id"
    case decision
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    intentID = try container.decode(String.self, forKey: .intentID)
    allowanceID = try container.decode(String.self, forKey: .allowanceID)
    decision = try container.decode(LiveAuthorizationDecision.self, forKey: .decision)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LivePreflightStatus: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct LivePreflightCompleted: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let authorizationEvidenceID: String
  public let status: LivePreflightStatus
  public let evidence: LiveEvidenceObject

  public init(
    coordinates: LiveTransitionCoordinates,
    authorizationEvidenceID: String,
    status: LivePreflightStatus,
    evidence: LiveEvidenceObject
  ) {
    self.coordinates = coordinates
    self.authorizationEvidenceID = authorizationEvidenceID
    self.status = status
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case authorizationEvidenceID = "authorization_evidence_id"
    case status
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    authorizationEvidenceID = try container.decode(String.self, forKey: .authorizationEvidenceID)
    status = try container.decode(LivePreflightStatus.self, forKey: .status)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LiveExecutionStatus: String, Codable, Equatable, Sendable {
  case succeeded
  case failed
}

public struct LiveExecutionRecorded: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let preflightEvidenceID: String
  public let status: LiveExecutionStatus
  public let evidence: LiveEvidenceObject

  public init(
    coordinates: LiveTransitionCoordinates,
    preflightEvidenceID: String,
    status: LiveExecutionStatus,
    evidence: LiveEvidenceObject
  ) {
    self.coordinates = coordinates
    self.preflightEvidenceID = preflightEvidenceID
    self.status = status
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case preflightEvidenceID = "preflight_evidence_id"
    case status
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    preflightEvidenceID = try container.decode(String.self, forKey: .preflightEvidenceID)
    status = try container.decode(LiveExecutionStatus.self, forKey: .status)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LiveObservationStatus: String, Codable, Equatable, Sendable {
  case observed
  case notObserved = "not_observed"
}

public struct LiveObservationRecorded: Codable, Equatable, Sendable {
  public let coordinates: LiveTransitionCoordinates
  public let executionEvidenceID: String
  public let status: LiveObservationStatus
  public let evidence: LiveEvidenceObject

  public init(
    coordinates: LiveTransitionCoordinates,
    executionEvidenceID: String,
    status: LiveObservationStatus,
    evidence: LiveEvidenceObject
  ) {
    self.coordinates = coordinates
    self.executionEvidenceID = executionEvidenceID
    self.status = status
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case coordinates
    case executionEvidenceID = "execution_evidence_id"
    case status
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    executionEvidenceID = try container.decode(String.self, forKey: .executionEvidenceID)
    status = try container.decode(LiveObservationStatus.self, forKey: .status)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LiveVerificationScope: String, Codable, Equatable, Sendable {
  case modelVariant = "model_variant"
  case transition
}

public enum LiveVerificationStatus: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct LiveVerificationRecorded: Codable, Equatable, Sendable {
  public let verificationID: String
  public let criterionID: String
  public let scope: LiveVerificationScope
  public let subjectID: String
  public let coordinates: LiveTransitionCoordinates?
  public let status: LiveVerificationStatus
  public let evidence: LiveEvidenceObject

  public init(
    verificationID: String,
    criterionID: String,
    scope: LiveVerificationScope,
    subjectID: String,
    coordinates: LiveTransitionCoordinates?,
    status: LiveVerificationStatus,
    evidence: LiveEvidenceObject
  ) {
    self.verificationID = verificationID
    self.criterionID = criterionID
    self.scope = scope
    self.subjectID = subjectID
    self.coordinates = coordinates
    self.status = status
    self.evidence = evidence
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case verificationID = "verification_id"
    case criterionID = "criterion_id"
    case scope
    case subjectID = "subject_id"
    case coordinates
    case status
    case evidence
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    verificationID = try container.decode(String.self, forKey: .verificationID)
    criterionID = try container.decode(String.self, forKey: .criterionID)
    scope = try container.decode(LiveVerificationScope.self, forKey: .scope)
    subjectID = try container.decode(String.self, forKey: .subjectID)
    coordinates = try container.decodeIfPresent(
      LiveTransitionCoordinates.self,
      forKey: .coordinates
    )
    status = try container.decode(LiveVerificationStatus.self, forKey: .status)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
  }
}

public enum LiveBudgetCheckpointReason: String, Codable, Equatable, Sendable {
  case insufficientBudget = "insufficient_budget"
  case zeroMoneyNotProvenFreeLocal = "zero_money_not_proven_free_local"
}

public struct LiveBudgetCheckpointCreated: Codable, Equatable, Sendable {
  public let checkpointID: String
  public let proposal: LiveModelInvocationProposal
  public let reason: LiveBudgetCheckpointReason
  public let budget: LiveBudgetState

  public init(
    checkpointID: String,
    proposal: LiveModelInvocationProposal,
    reason: LiveBudgetCheckpointReason,
    budget: LiveBudgetState
  ) {
    self.checkpointID = checkpointID
    self.proposal = proposal
    self.reason = reason
    self.budget = budget
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case checkpointID = "checkpoint_id"
    case proposal
    case reason
    case budget
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checkpointID = try container.decode(String.self, forKey: .checkpointID)
    proposal = try container.decode(LiveModelInvocationProposal.self, forKey: .proposal)
    reason = try container.decode(LiveBudgetCheckpointReason.self, forKey: .reason)
    budget = try container.decode(LiveBudgetState.self, forKey: .budget)
  }
}

public struct LiveGenerationConfirmed: Codable, Equatable, Sendable {
  public let generationID: String
  public let confirmedThroughSequence: Int64
  public let stateSHA256: String

  public init(generationID: String, confirmedThroughSequence: Int64, stateSHA256: String) {
    self.generationID = generationID
    self.confirmedThroughSequence = confirmedThroughSequence
    self.stateSHA256 = stateSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case generationID = "generation_id"
    case confirmedThroughSequence = "confirmed_through_sequence"
    case stateSHA256 = "state_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    generationID = try container.decode(String.self, forKey: .generationID)
    confirmedThroughSequence = try container.decode(Int64.self, forKey: .confirmedThroughSequence)
    stateSHA256 = try container.decode(String.self, forKey: .stateSHA256)
  }
}

public enum LiveContinuationDecision: String, Codable, Equatable, Sendable {
  case `continue`
  case completed
  case needsInput = "needs_input"
  case budgetExhausted = "budget_exhausted"
  case blocked
  case refused
  case cancelled
  case failed
}

public struct LiveContinuationDecided: Codable, Equatable, Sendable {
  public let decision: LiveContinuationDecision
  public let generationID: String
  public let basisEventIDs: [String]
  public let reason: String

  public init(
    decision: LiveContinuationDecision,
    generationID: String,
    basisEventIDs: [String],
    reason: String
  ) {
    self.decision = decision
    self.generationID = generationID
    self.basisEventIDs = basisEventIDs
    self.reason = reason
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case decision
    case generationID = "generation_id"
    case basisEventIDs = "basis_event_ids"
    case reason
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    decision = try container.decode(LiveContinuationDecision.self, forKey: .decision)
    generationID = try container.decode(String.self, forKey: .generationID)
    basisEventIDs = try container.decode([String].self, forKey: .basisEventIDs)
    reason = try container.decode(String.self, forKey: .reason)
  }
}

public enum LiveEpisodeEventKind: String, Codable, Equatable, Sendable {
  case modelCheckpointCreated = "model_checkpoint_created"
  case pendingTransitionDeclared = "pending_transition_declared"
  case modelRequestRecorded = "model_request_recorded"
  case modelResponseRecorded = "model_response_recorded"
  case untrustedIntentParsed = "untrusted_intent_parsed"
  case modelSelectionRecorded = "model_selection_recorded"
  case transitionUserConfirmed = "transition_user_confirmed"
  case authorizationDecided = "authorization_decided"
  case preflightCompleted = "preflight_completed"
  case executionRecorded = "execution_recorded"
  case observationRecorded = "observation_recorded"
  case verificationRecorded = "verification_recorded"
  case budgetCheckpointCreated = "budget_checkpoint_created"
  case generationConfirmed = "generation_confirmed"
  case continuationDecided = "continuation_decided"
}

public enum LiveEpisodeEventPayload: Equatable, Sendable {
  case modelCheckpointCreated(LiveModelCheckpointCreated)
  case pendingTransitionDeclared(LivePendingTransitionDeclared)
  case modelRequestRecorded(LiveModelRequestRecorded)
  case modelResponseRecorded(LiveModelResponseRecorded)
  case untrustedIntentParsed(LiveUntrustedIntentParsed)
  case modelSelectionRecorded(LiveModelSelectionRecorded)
  case transitionUserConfirmed(LiveTransitionUserConfirmed)
  case authorizationDecided(LiveAuthorizationDecided)
  case preflightCompleted(LivePreflightCompleted)
  case executionRecorded(LiveExecutionRecorded)
  case observationRecorded(LiveObservationRecorded)
  case verificationRecorded(LiveVerificationRecorded)
  case budgetCheckpointCreated(LiveBudgetCheckpointCreated)
  case generationConfirmed(LiveGenerationConfirmed)
  case continuationDecided(LiveContinuationDecided)

  public var kind: LiveEpisodeEventKind {
    switch self {
    case .modelCheckpointCreated: .modelCheckpointCreated
    case .pendingTransitionDeclared: .pendingTransitionDeclared
    case .modelRequestRecorded: .modelRequestRecorded
    case .modelResponseRecorded: .modelResponseRecorded
    case .untrustedIntentParsed: .untrustedIntentParsed
    case .modelSelectionRecorded: .modelSelectionRecorded
    case .transitionUserConfirmed: .transitionUserConfirmed
    case .authorizationDecided: .authorizationDecided
    case .preflightCompleted: .preflightCompleted
    case .executionRecorded: .executionRecorded
    case .observationRecorded: .observationRecorded
    case .verificationRecorded: .verificationRecorded
    case .budgetCheckpointCreated: .budgetCheckpointCreated
    case .generationConfirmed: .generationConfirmed
    case .continuationDecided: .continuationDecided
    }
  }
}

public struct LiveEpisodeEvent: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let episodeID: String
  public let eventID: String
  public let sequence: Int64
  public let payload: LiveEpisodeEventPayload

  public var kind: LiveEpisodeEventKind { payload.kind }

  public init(
    schemaIdentity: String = LiveEpisodeSchema.identity,
    schemaVersion: Int = LiveEpisodeSchema.version,
    episodeID: String,
    eventID: String,
    sequence: Int64,
    payload: LiveEpisodeEventPayload
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.episodeID = episodeID
    self.eventID = eventID
    self.sequence = sequence
    self.payload = payload
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case eventID = "event_id"
    case sequence
    case kind
    case payload
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    episodeID = try container.decode(String.self, forKey: .episodeID)
    eventID = try container.decode(String.self, forKey: .eventID)
    sequence = try container.decode(Int64.self, forKey: .sequence)
    let kind = try container.decode(LiveEpisodeEventKind.self, forKey: .kind)
    switch kind {
    case .modelCheckpointCreated:
      payload = .modelCheckpointCreated(
        try container.decode(LiveModelCheckpointCreated.self, forKey: .payload))
    case .pendingTransitionDeclared:
      payload = .pendingTransitionDeclared(
        try container.decode(LivePendingTransitionDeclared.self, forKey: .payload))
    case .modelRequestRecorded:
      payload = .modelRequestRecorded(
        try container.decode(LiveModelRequestRecorded.self, forKey: .payload))
    case .modelResponseRecorded:
      payload = .modelResponseRecorded(
        try container.decode(LiveModelResponseRecorded.self, forKey: .payload))
    case .untrustedIntentParsed:
      payload = .untrustedIntentParsed(
        try container.decode(LiveUntrustedIntentParsed.self, forKey: .payload))
    case .modelSelectionRecorded:
      payload = .modelSelectionRecorded(
        try container.decode(LiveModelSelectionRecorded.self, forKey: .payload))
    case .transitionUserConfirmed:
      payload = .transitionUserConfirmed(
        try container.decode(LiveTransitionUserConfirmed.self, forKey: .payload))
    case .authorizationDecided:
      payload = .authorizationDecided(
        try container.decode(LiveAuthorizationDecided.self, forKey: .payload))
    case .preflightCompleted:
      payload = .preflightCompleted(
        try container.decode(LivePreflightCompleted.self, forKey: .payload))
    case .executionRecorded:
      payload = .executionRecorded(
        try container.decode(LiveExecutionRecorded.self, forKey: .payload))
    case .observationRecorded:
      payload = .observationRecorded(
        try container.decode(LiveObservationRecorded.self, forKey: .payload))
    case .verificationRecorded:
      payload = .verificationRecorded(
        try container.decode(LiveVerificationRecorded.self, forKey: .payload))
    case .budgetCheckpointCreated:
      payload = .budgetCheckpointCreated(
        try container.decode(LiveBudgetCheckpointCreated.self, forKey: .payload))
    case .generationConfirmed:
      payload = .generationConfirmed(
        try container.decode(LiveGenerationConfirmed.self, forKey: .payload))
    case .continuationDecided:
      payload = .continuationDecided(
        try container.decode(LiveContinuationDecided.self, forKey: .payload))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaIdentity, forKey: .schemaIdentity)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    try container.encode(episodeID, forKey: .episodeID)
    try container.encode(eventID, forKey: .eventID)
    try container.encode(sequence, forKey: .sequence)
    try container.encode(kind, forKey: .kind)
    switch payload {
    case .modelCheckpointCreated(let value):
      try container.encode(value, forKey: .payload)
    case .pendingTransitionDeclared(let value):
      try container.encode(value, forKey: .payload)
    case .modelRequestRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .modelResponseRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .untrustedIntentParsed(let value):
      try container.encode(value, forKey: .payload)
    case .modelSelectionRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .transitionUserConfirmed(let value):
      try container.encode(value, forKey: .payload)
    case .authorizationDecided(let value):
      try container.encode(value, forKey: .payload)
    case .preflightCompleted(let value):
      try container.encode(value, forKey: .payload)
    case .executionRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .observationRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .verificationRecorded(let value):
      try container.encode(value, forKey: .payload)
    case .budgetCheckpointCreated(let value):
      try container.encode(value, forKey: .payload)
    case .generationConfirmed(let value):
      try container.encode(value, forKey: .payload)
    case .continuationDecided(let value):
      try container.encode(value, forKey: .payload)
    }
  }
}

public enum LiveEpisodeError: Error, Equatable, Sendable {
  case unsupportedSchema(identity: String, version: Int)
  case invalidPassport(String)
  case invalidEvent(String)
  case identityMismatch(field: String, expected: String, actual: String)
  case unexpectedSequence(expected: Int64, actual: Int64)
  case eventConflict(eventID: String)
  case eventOrderViolation(kind: LiveEpisodeEventKind, reason: String)
  case unknownReference(String)
  case transitionEvidenceMismatch
  case duplicateTransitionEvidence(evidenceID: String)
  case untrustedActionMismatch
  case modelSelectionWithoutResponse(variantID: String)
  case modelSelectionWithoutIntent(variantID: String)
  case modelSelectionWithoutVerification(variantID: String)
  case falseStatusElevation(String)
  case budgetInsufficient
  case budgetArithmeticOverflow
  case invalidBudgetCheckpoint
  case terminalEpisode
}
