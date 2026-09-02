import FUMReproducibleMemoryPopulation
import Foundation

public enum SharedEpisodeBudgetDimension:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case executors
  case rounds
  case modelCalls = "model_calls"
  case toolCalls = "tool_calls"
  case input
  case output
}

public struct SharedEpisodeBudgetVector:
  SharedEpisodeCanonicalValue, Equatable, Hashable, Sendable
{
  public let executors: Int64
  public let rounds: Int64
  public let modelCalls: Int64
  public let toolCalls: Int64
  public let input: Int64
  public let output: Int64

  enum CodingKeys: String, CodingKey {
    case executors
    case rounds
    case modelCalls = "model_calls"
    case toolCalls = "tool_calls"
    case input = "input_units"
    case output = "output_units"
  }

  public init(
    executors: Int64,
    rounds: Int64,
    modelCalls: Int64,
    toolCalls: Int64,
    input: Int64,
    output: Int64
  ) {
    self.executors = executors
    self.rounds = rounds
    self.modelCalls = modelCalls
    self.toolCalls = toolCalls
    self.input = input
    self.output = output
  }

  public static let zero = SharedEpisodeBudgetVector(
    executors: 0,
    rounds: 0,
    modelCalls: 0,
    toolCalls: 0,
    input: 0,
    output: 0
  )

  public var isZero: Bool {
    values.allSatisfy { $0 == 0 }
  }

  public subscript(dimension: SharedEpisodeBudgetDimension) -> Int64 {
    switch dimension {
    case .executors:
      executors
    case .rounds:
      rounds
    case .modelCalls:
      modelCalls
    case .toolCalls:
      toolCalls
    case .input:
      input
    case .output:
      output
    }
  }

  public func checkedAdding(
    _ other: SharedEpisodeBudgetVector
  ) throws -> SharedEpisodeBudgetVector {
    try SharedEpisodeBudgetVector(
      checked: zip(values, other.values).map { pair in
        let (left, right) = pair
        let result = left.addingReportingOverflow(right)
        guard !result.overflow else {
          throw SharedEpisodeMemoryError.invalidControl(
            "Переполнение при сложении бюджетных векторов."
          )
        }
        return result.partialValue
      }
    )
  }

  public func checkedSubtracting(
    _ other: SharedEpisodeBudgetVector
  ) throws -> SharedEpisodeBudgetVector {
    try SharedEpisodeBudgetVector(
      checked: zip(values, other.values).map { pair in
        let (left, right) = pair
        let result = left.subtractingReportingOverflow(right)
        guard !result.overflow, result.partialValue >= 0 else {
          throw SharedEpisodeMemoryError.invalidControl(
            "Переполнение или отрицательный остаток бюджетного вектора."
          )
        }
        return result.partialValue
      }
    )
  }

  public func isComponentwiseLessThanOrEqual(
    to other: SharedEpisodeBudgetVector
  ) -> Bool {
    SharedEpisodeBudgetDimension.allCases.allSatisfy {
      self[$0] <= other[$0]
    }
  }

  public func firstExceededDimension(
    comparedWith other: SharedEpisodeBudgetVector
  ) -> SharedEpisodeBudgetDimension? {
    SharedEpisodeBudgetDimension.allCases.first { self[$0] > other[$0] }
  }

  fileprivate var values: [Int64] {
    [executors, rounds, modelCalls, toolCalls, input, output]
  }

  fileprivate var isNonnegative: Bool {
    values.allSatisfy { $0 >= 0 }
  }

  fileprivate var isStrictlyPositive: Bool {
    values.allSatisfy { $0 > 0 }
  }

  private init(checked values: [Int64]) throws {
    guard values.count == SharedEpisodeBudgetDimension.allCases.count else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Бюджетный вектор имеет неверное число размерностей."
      )
    }
    self.init(
      executors: values[0],
      rounds: values[1],
      modelCalls: values[2],
      toolCalls: values[3],
      input: values[4],
      output: values[5]
    )
  }
}

public struct SharedEpisodeBudgetPlan:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4
  public static let supportedMeteringPolicyID =
    "fum.episode-metering.provenance-bindings-and-canonical-output.v1"

  public let schemaVersion: Int
  public let meteringPolicyID: String
  public let maximum: SharedEpisodeBudgetVector
  public let verificationReserve: SharedEpisodeBudgetVector
  public let handoffReserve: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case meteringPolicyID = "metering_policy_id"
    case maximum
    case verificationReserve = "verification_reserve"
    case handoffReserve = "handoff_reserve"
  }

  public init(
    schemaVersion: Int = SharedEpisodeBudgetPlan.currentSchemaVersion,
    meteringPolicyID: String = SharedEpisodeBudgetPlan.supportedMeteringPolicyID,
    maximum: SharedEpisodeBudgetVector,
    verificationReserve: SharedEpisodeBudgetVector,
    handoffReserve: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.meteringPolicyID = meteringPolicyID
    self.maximum = maximum
    self.verificationReserve = verificationReserve
    self.handoffReserve = handoffReserve
  }

  public static let fixtureDefault = SharedEpisodeBudgetPlan(
    maximum: SharedEpisodeBudgetVector(
      executors: 16,
      rounds: 16,
      modelCalls: 32,
      toolCalls: 32,
      input: 65_536,
      output: 65_536
    ),
    verificationReserve: SharedEpisodeBudgetVector(
      executors: 2,
      rounds: 2,
      modelCalls: 4,
      toolCalls: 8,
      input: 8_192,
      output: 8_192
    ),
    handoffReserve: SharedEpisodeBudgetVector(
      executors: 1,
      rounds: 1,
      modelCalls: 1,
      toolCalls: 2,
      input: 4_096,
      output: 4_096
    )
  )
}

public enum SharedEpisodeActionPhase:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case productive
  case verification
  case handoff
}

public enum SharedEpisodeActionKind:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case contribution
  case verification
  case selection
  case modelOnly = "model_only"
  case transition
  case terminal
}

public enum SharedEpisodeContinuationKind:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case modelOnly = "model_only"
  case verification
  case selection
}

public struct SharedEpisodeContinuationCandidate:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let continuationID: String
  public let kind: SharedEpisodeContinuationKind
  public let safe: Bool
  public let productive: Bool
  public let budget: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case continuationID = "continuation_id"
    case kind
    case safe
    case productive
    case budget
  }

  public init(
    schemaVersion: Int = SharedEpisodeContinuationCandidate.currentSchemaVersion,
    continuationID: String,
    kind: SharedEpisodeContinuationKind,
    safe: Bool,
    productive: Bool,
    budget: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.continuationID = continuationID
    self.kind = kind
    self.safe = safe
    self.productive = productive
    self.budget = budget
  }
}

public struct SharedEpisodeDistinguishingCheck:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let checkID: String
  public let safe: Bool
  public let productive: Bool
  public let budget: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case checkID = "check_id"
    case safe
    case productive
    case budget
  }

  public init(
    schemaVersion: Int = SharedEpisodeDistinguishingCheck.currentSchemaVersion,
    checkID: String,
    safe: Bool,
    productive: Bool,
    budget: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.checkID = checkID
    self.safe = safe
    self.productive = productive
    self.budget = budget
  }
}

public struct SharedEpisodeControlPlan:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4
  public static let maximumRegistryEntries = 256

  public let schemaVersion: Int
  public let budget: SharedEpisodeBudgetPlan
  public let selectionPolicyID: String
  public let selectionPlanArtifactID: String
  public let stopPolicyID: String
  public let selectorID: String
  public let selectorRoleID: String
  public let selectionBasis: SharedEpisodeSelectionBasis
  public let agreementIsEvidence: Bool
  public let independenceInferredFromCount: Bool
  public let continuations: [SharedEpisodeContinuationCandidate]
  public let distinguishingChecks: [SharedEpisodeDistinguishingCheck]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case budget
    case selectionPolicyID = "selection_policy_id"
    case selectionPlanArtifactID = "selection_plan_artifact_id"
    case stopPolicyID = "stop_policy_id"
    case selectorID = "selector_id"
    case selectorRoleID = "selector_role_id"
    case selectionBasis = "selection_basis"
    case agreementIsEvidence = "agreement_is_evidence"
    case independenceInferredFromCount = "independence_inferred_from_count"
    case continuations
    case distinguishingChecks = "distinguishing_checks"
  }

  public init(
    schemaVersion: Int = SharedEpisodeControlPlan.currentSchemaVersion,
    budget: SharedEpisodeBudgetPlan,
    selectionPolicyID: String = "selection.policy.verified-evidence.v1",
    selectionPlanArtifactID: String = "selection.main",
    stopPolicyID: String = "stop.main",
    selectorID: String = "selector.main",
    selectorRoleID: String = "selector.main",
    selectionBasis: SharedEpisodeSelectionBasis = .verifiedEvidence,
    agreementIsEvidence: Bool = false,
    independenceInferredFromCount: Bool = false,
    continuations: [SharedEpisodeContinuationCandidate],
    distinguishingChecks: [SharedEpisodeDistinguishingCheck]
  ) {
    self.schemaVersion = schemaVersion
    self.budget = budget
    self.selectionPolicyID = selectionPolicyID
    self.selectionPlanArtifactID = selectionPlanArtifactID
    self.stopPolicyID = stopPolicyID
    self.selectorID = selectorID
    self.selectorRoleID = selectorRoleID
    self.selectionBasis = selectionBasis
    self.agreementIsEvidence = agreementIsEvidence
    self.independenceInferredFromCount = independenceInferredFromCount
    self.continuations = continuations
    self.distinguishingChecks = distinguishingChecks
  }

  public static let fixtureDefault = SharedEpisodeControlPlan(
    budget: .fixtureDefault,
    continuations: [
      SharedEpisodeContinuationCandidate(
        continuationID: "continuation.model-only.primary",
        kind: .modelOnly,
        safe: true,
        productive: true,
        budget: SharedEpisodeBudgetVector(
          executors: 1,
          rounds: 1,
          modelCalls: 1,
          toolCalls: 0,
          input: 1_024,
          output: 1_024
        )
      )
    ],
    distinguishingChecks: [
      SharedEpisodeDistinguishingCheck(
        checkID: "check.distinguishing.primary",
        safe: true,
        productive: true,
        budget: SharedEpisodeBudgetVector(
          executors: 1,
          rounds: 1,
          modelCalls: 1,
          toolCalls: 1,
          input: 1_024,
          output: 1_024
        )
      )
    ]
  )
}

public struct SharedEpisodeActionReservation:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let meteringPolicyID: String
  public let permitID: String
  public let actionID: String
  public let parentGenerationSHA256: String
  public let phase: SharedEpisodeActionPhase
  public let kind: SharedEpisodeActionKind
  public let executorID: String
  public let roundID: String
  public let continuationID: String?
  public let distinguishingCheckID: String?
  public let reserved: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case meteringPolicyID = "metering_policy_id"
    case permitID = "permit_id"
    case actionID = "action_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case phase
    case kind
    case executorID = "executor_id"
    case roundID = "round_id"
    case continuationID = "continuation_id"
    case distinguishingCheckID = "distinguishing_check_id"
    case reserved
  }

  public init(
    schemaVersion: Int = SharedEpisodeActionReservation.currentSchemaVersion,
    meteringPolicyID: String = SharedEpisodeBudgetPlan.supportedMeteringPolicyID,
    permitID: String,
    actionID: String,
    parentGenerationSHA256: String,
    phase: SharedEpisodeActionPhase,
    kind: SharedEpisodeActionKind,
    executorID: String,
    roundID: String,
    continuationID: String?,
    distinguishingCheckID: String?,
    reserved: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.meteringPolicyID = meteringPolicyID
    self.permitID = permitID
    self.actionID = actionID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.phase = phase
    self.kind = kind
    self.executorID = executorID
    self.roundID = roundID
    self.continuationID = continuationID
    self.distinguishingCheckID = distinguishingCheckID
    self.reserved = reserved
  }

  public func rebinding(
    parentGenerationSHA256: String
  ) -> SharedEpisodeActionReservation {
    SharedEpisodeActionReservation(
      schemaVersion: schemaVersion,
      meteringPolicyID: meteringPolicyID,
      permitID: permitID,
      actionID: actionID,
      parentGenerationSHA256: parentGenerationSHA256,
      phase: phase,
      kind: kind,
      executorID: executorID,
      roundID: roundID,
      continuationID: continuationID,
      distinguishingCheckID: distinguishingCheckID,
      reserved: reserved
    )
  }
}

public typealias SharedEpisodeOpenReservation = SharedEpisodeActionReservation

public struct SharedEpisodeActionSettlement:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let meteringPolicyID: String
  public let permitID: String
  public let actionID: String
  public let actual: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case meteringPolicyID = "metering_policy_id"
    case permitID = "permit_id"
    case actionID = "action_id"
    case actual
  }

  public init(
    schemaVersion: Int = SharedEpisodeActionSettlement.currentSchemaVersion,
    meteringPolicyID: String = SharedEpisodeBudgetPlan.supportedMeteringPolicyID,
    permitID: String,
    actionID: String,
    actual: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.meteringPolicyID = meteringPolicyID
    self.permitID = permitID
    self.actionID = actionID
    self.actual = actual
  }
}

public enum SharedEpisodeSelectionBasis:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case verifiedEvidence = "verified_evidence"
  case assertionVote = "assertion_vote"
}

public enum SharedEpisodeSelectionStatus:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case selectedInModel = "selected_in_model"
  case recommended
}

public enum SharedEpisodeSelectionDisposition:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case selected
  case rejected
}

public enum SharedEpisodeDisagreementResolution:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case resolved
  case retainedUnresolved = "retained_unresolved"
}

public struct SharedEpisodeDisagreementDisposition:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let disagreementID: String
  public let resolution: SharedEpisodeDisagreementResolution
  public let reasonCode: String
  public let evidenceIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case disagreementID = "disagreement_id"
    case resolution
    case reasonCode = "reason_code"
    case evidenceIDs = "evidence_ids"
  }

  public init(
    schemaVersion: Int = SharedEpisodeDisagreementDisposition.currentSchemaVersion,
    disagreementID: String,
    resolution: SharedEpisodeDisagreementResolution,
    reasonCode: String,
    evidenceIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.disagreementID = disagreementID
    self.resolution = resolution
    self.reasonCode = reasonCode
    self.evidenceIDs = evidenceIDs
  }
}

public struct SharedEpisodeSelectionConsideration:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let contributionID: String
  public let contentSHA256: String
  public let provenanceSHA256: String
  public let verificationRecordIDs: [String]
  public let evidenceIDs: [String]
  public let disposition: SharedEpisodeSelectionDisposition
  public let reasonCode: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case contributionID = "contribution_id"
    case contentSHA256 = "content_sha256"
    case provenanceSHA256 = "provenance_sha256"
    case verificationRecordIDs = "verification_record_ids"
    case evidenceIDs = "evidence_ids"
    case disposition
    case reasonCode = "reason_code"
  }

  public init(
    schemaVersion: Int = SharedEpisodeSelectionConsideration.currentSchemaVersion,
    contributionID: String,
    contentSHA256: String,
    provenanceSHA256: String,
    verificationRecordIDs: [String],
    evidenceIDs: [String],
    disposition: SharedEpisodeSelectionDisposition,
    reasonCode: String
  ) {
    self.schemaVersion = schemaVersion
    self.contributionID = contributionID
    self.contentSHA256 = contentSHA256
    self.provenanceSHA256 = provenanceSHA256
    self.verificationRecordIDs = verificationRecordIDs
    self.evidenceIDs = evidenceIDs
    self.disposition = disposition
    self.reasonCode = reasonCode
  }
}

public struct SharedEpisodeSelectionDecision:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let decisionID: String
  public let parentGenerationSHA256: String
  public let selectionContextSHA256: String
  public let replacesDecisionID: String?
  public let selectionPolicyID: String
  public let selectionPlanArtifactID: String
  public let stopPolicyID: String
  public let selectorID: String
  public let selectorRoleID: String
  public let criteriaArtifactID: String
  public let criteriaSHA256: String
  public let criterionIDs: [String]
  public let considerations: [SharedEpisodeSelectionConsideration]
  public let disagreementDispositions: [SharedEpisodeDisagreementDisposition]
  public let selectedContributionID: String?
  public let basis: SharedEpisodeSelectionBasis
  public let status: SharedEpisodeSelectionStatus
  public let userConfirmed: Bool
  public let authorized: Bool

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case decisionID = "decision_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case selectionContextSHA256 = "selection_context_sha256"
    case replacesDecisionID = "replaces_decision_id"
    case selectionPolicyID = "selection_policy_id"
    case selectionPlanArtifactID = "selection_plan_artifact_id"
    case stopPolicyID = "stop_policy_id"
    case selectorID = "selector_id"
    case selectorRoleID = "selector_role_id"
    case criteriaArtifactID = "criteria_artifact_id"
    case criteriaSHA256 = "criteria_sha256"
    case criterionIDs = "criterion_ids"
    case considerations
    case disagreementDispositions = "disagreement_dispositions"
    case selectedContributionID = "selected_contribution_id"
    case basis
    case status
    case userConfirmed = "user_confirmed"
    case authorized
  }

  public init(
    schemaVersion: Int = SharedEpisodeSelectionDecision.currentSchemaVersion,
    decisionID: String,
    parentGenerationSHA256: String,
    selectionContextSHA256: String,
    replacesDecisionID: String? = nil,
    selectionPolicyID: String = "selection.policy.verified-evidence.v1",
    selectionPlanArtifactID: String = "selection.main",
    stopPolicyID: String = "stop.main",
    selectorID: String,
    selectorRoleID: String,
    criteriaArtifactID: String,
    criteriaSHA256: String,
    criterionIDs: [String],
    considerations: [SharedEpisodeSelectionConsideration],
    disagreementDispositions: [SharedEpisodeDisagreementDisposition],
    selectedContributionID: String?,
    basis: SharedEpisodeSelectionBasis,
    status: SharedEpisodeSelectionStatus,
    userConfirmed: Bool,
    authorized: Bool
  ) {
    self.schemaVersion = schemaVersion
    self.decisionID = decisionID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.selectionContextSHA256 = selectionContextSHA256
    self.replacesDecisionID = replacesDecisionID
    self.selectionPolicyID = selectionPolicyID
    self.selectionPlanArtifactID = selectionPlanArtifactID
    self.stopPolicyID = stopPolicyID
    self.selectorID = selectorID
    self.selectorRoleID = selectorRoleID
    self.criteriaArtifactID = criteriaArtifactID
    self.criteriaSHA256 = criteriaSHA256
    self.criterionIDs = criterionIDs
    self.considerations = considerations
    self.disagreementDispositions = disagreementDispositions
    self.selectedContributionID = selectedContributionID
    self.basis = basis
    self.status = status
    self.userConfirmed = userConfirmed
    self.authorized = authorized
  }
}

public struct SharedEpisodeSelectionContributionSnapshot:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let contributionID: String
  public let contentSHA256: String
  public let provenanceSHA256: String

  enum CodingKeys: String, CodingKey {
    case contributionID = "contribution_id"
    case contentSHA256 = "content_sha256"
    case provenanceSHA256 = "provenance_sha256"
  }

  public init(
    contributionID: String,
    contentSHA256: String,
    provenanceSHA256: String
  ) {
    self.contributionID = contributionID
    self.contentSHA256 = contentSHA256
    self.provenanceSHA256 = provenanceSHA256
  }
}

public struct SharedEpisodeSelectionEvidenceBinding:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let contributionID: String
  public let evidenceIDs: [String]

  enum CodingKeys: String, CodingKey {
    case contributionID = "contribution_id"
    case evidenceIDs = "evidence_ids"
  }

  public init(
    contributionID: String,
    evidenceIDs: [String]
  ) {
    self.contributionID = contributionID
    self.evidenceIDs = evidenceIDs
  }
}

public struct SharedEpisodeSelectionVerificationSnapshot:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let recordID: String
  public let distinguishingCheckID: String?
  public let contributionIDs: [String]
  public let evidenceIDs: [String]
  public let evidenceBindings: [SharedEpisodeSelectionEvidenceBinding]
  public let outcome: SharedEpisodeVerificationOutcome
  public let standing: SharedEpisodeVerificationStanding

  enum CodingKeys: String, CodingKey {
    case recordID = "record_id"
    case distinguishingCheckID = "distinguishing_check_id"
    case contributionIDs = "contribution_ids"
    case evidenceIDs = "evidence_ids"
    case evidenceBindings = "evidence_bindings"
    case outcome
    case standing
  }

  public init(
    recordID: String,
    distinguishingCheckID: String? = nil,
    contributionIDs: [String],
    evidenceIDs: [String],
    evidenceBindings: [SharedEpisodeSelectionEvidenceBinding],
    outcome: SharedEpisodeVerificationOutcome,
    standing: SharedEpisodeVerificationStanding
  ) {
    self.recordID = recordID
    self.distinguishingCheckID = distinguishingCheckID
    self.contributionIDs = contributionIDs
    self.evidenceIDs = evidenceIDs
    self.evidenceBindings = evidenceBindings
    self.outcome = outcome
    self.standing = standing
  }
}

public struct SharedEpisodeSelectionDisagreementSnapshot:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let disagreementID: String
  public let verificationRecordID: String
  public let claimID: String
  public let contributionID: String
  public let resultSHA256: String
  public let eligibleEvidenceIDs: [String]

  enum CodingKeys: String, CodingKey {
    case disagreementID = "disagreement_id"
    case verificationRecordID = "verification_record_id"
    case claimID = "claim_id"
    case contributionID = "contribution_id"
    case resultSHA256 = "result_sha256"
    case eligibleEvidenceIDs = "eligible_evidence_ids"
  }

  public init(
    disagreementID: String,
    verificationRecordID: String,
    claimID: String,
    contributionID: String,
    resultSHA256: String,
    eligibleEvidenceIDs: [String]
  ) {
    self.disagreementID = disagreementID
    self.verificationRecordID = verificationRecordID
    self.claimID = claimID
    self.contributionID = contributionID
    self.resultSHA256 = resultSHA256
    self.eligibleEvidenceIDs = eligibleEvidenceIDs
  }
}

public struct SharedEpisodeSelectionEvidenceContext:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let criteriaArtifactID: String
  public let criteriaSHA256: String
  public let criterionIDs: [String]
  public let contributions: [SharedEpisodeSelectionContributionSnapshot]
  public let verifications: [SharedEpisodeSelectionVerificationSnapshot]
  public let disagreements: [SharedEpisodeSelectionDisagreementSnapshot]

  public var disagreementIDs: [String] {
    disagreements.map(\.disagreementID)
  }

  enum CodingKeys: String, CodingKey {
    case criteriaArtifactID = "criteria_artifact_id"
    case criteriaSHA256 = "criteria_sha256"
    case criterionIDs = "criterion_ids"
    case contributions
    case verifications
    case disagreements
  }

  public init(
    criteriaArtifactID: String,
    criteriaSHA256: String,
    criterionIDs: [String],
    contributions: [SharedEpisodeSelectionContributionSnapshot],
    verifications: [SharedEpisodeSelectionVerificationSnapshot],
    disagreements: [SharedEpisodeSelectionDisagreementSnapshot]
  ) {
    self.criteriaArtifactID = criteriaArtifactID
    self.criteriaSHA256 = criteriaSHA256
    self.criterionIDs = criterionIDs
    self.contributions = contributions
    self.verifications = verifications
    self.disagreements = disagreements
  }
}

public enum SharedEpisodeTransitionPhase:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case awaitingConfirmation = "awaiting_confirmation"
  case confirmed
  case authorized
}

public struct SharedEpisodeParkedTransition:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let transitionID: String
  public let transitionVersion: Int
  public let parentGenerationSHA256: String
  public let permitID: String
  public let objectID: String
  public let objectVersion: String
  public let expectedEffectSHA256: String
  public let confirmationPolicyID: String
  public let phase: SharedEpisodeTransitionPhase
  public let userConfirmed: Bool
  public let authorized: Bool

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case transitionID = "transition_id"
    case transitionVersion = "transition_version"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case permitID = "permit_id"
    case objectID = "object_id"
    case objectVersion = "object_version"
    case expectedEffectSHA256 = "expected_effect_sha256"
    case confirmationPolicyID = "confirmation_policy_id"
    case phase
    case userConfirmed = "user_confirmed"
    case authorized
  }

  public init(
    schemaVersion: Int = SharedEpisodeParkedTransition.currentSchemaVersion,
    transitionID: String,
    transitionVersion: Int,
    parentGenerationSHA256: String,
    permitID: String,
    objectID: String,
    objectVersion: String,
    expectedEffectSHA256: String,
    confirmationPolicyID: String,
    phase: SharedEpisodeTransitionPhase,
    userConfirmed: Bool,
    authorized: Bool
  ) {
    self.schemaVersion = schemaVersion
    self.transitionID = transitionID
    self.transitionVersion = transitionVersion
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.permitID = permitID
    self.objectID = objectID
    self.objectVersion = objectVersion
    self.expectedEffectSHA256 = expectedEffectSHA256
    self.confirmationPolicyID = confirmationPolicyID
    self.phase = phase
    self.userConfirmed = userConfirmed
    self.authorized = authorized
  }
}

public struct SharedEpisodeModelOnlyResult:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let resultID: String
  public let parentGenerationSHA256: String
  public let permitID: String
  public let continuationID: String
  public let contentSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case resultID = "result_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case permitID = "permit_id"
    case continuationID = "continuation_id"
    case contentSHA256 = "content_sha256"
  }

  public init(
    schemaVersion: Int = SharedEpisodeModelOnlyResult.currentSchemaVersion,
    resultID: String,
    parentGenerationSHA256: String,
    permitID: String,
    continuationID: String,
    contentSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.resultID = resultID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.permitID = permitID
    self.continuationID = continuationID
    self.contentSHA256 = contentSHA256
  }

  public func rebinding(
    parentGenerationSHA256: String
  ) -> SharedEpisodeModelOnlyResult {
    SharedEpisodeModelOnlyResult(
      schemaVersion: schemaVersion,
      resultID: resultID,
      parentGenerationSHA256: parentGenerationSHA256,
      permitID: permitID,
      continuationID: continuationID,
      contentSHA256: contentSHA256
    )
  }
}

public enum SharedEpisodeTerminalOutcome:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case goalMet = "goal_met"
  case budgetExhausted = "budget_exhausted"
  case needsInput = "needs_input"
  case unresolvedConflict = "unresolved_conflict"
  case failed
}

public enum SharedEpisodeTerminalReasonCode:
  String, Codable, CaseIterable, Equatable, Hashable, Sendable
{
  case goalCriteriaMet = "goal_criteria_met"
  case budgetLimitReached = "budget_limit_reached"
  case pendingTransitionRequiresInput = "pending_transition_requires_input"
  case noDistinguishingCheck = "no_distinguishing_check"
  case executionFailed = "execution_failed"
  case noLegalProgress = "no_legal_progress"
}

public struct SharedEpisodeTerminalReason:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let code: SharedEpisodeTerminalReasonCode
  public let budgetDimension: SharedEpisodeBudgetDimension?
  public let budgetRequiredUnits: Int64?
  public let budgetAvailableUnits: Int64?
  public let blockedReservation: SharedEpisodeActionReservation?
  public let pendingTransitionID: String?
  public let failureCode: String?
  public let relatedIDs: [String]

  public var blockedActionID: String? {
    blockedReservation?.actionID
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case code
    case budgetDimension = "budget_dimension"
    case budgetRequiredUnits = "budget_required_units"
    case budgetAvailableUnits = "budget_available_units"
    case blockedReservation = "blocked_reservation"
    case pendingTransitionID = "pending_transition_id"
    case failureCode = "failure_code"
    case relatedIDs = "related_ids"
  }

  public init(
    schemaVersion: Int = SharedEpisodeTerminalReason.currentSchemaVersion,
    code: SharedEpisodeTerminalReasonCode,
    budgetDimension: SharedEpisodeBudgetDimension?,
    budgetRequiredUnits: Int64? = nil,
    budgetAvailableUnits: Int64? = nil,
    blockedReservation: SharedEpisodeActionReservation?,
    pendingTransitionID: String?,
    failureCode: String?,
    relatedIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.code = code
    self.budgetDimension = budgetDimension
    self.budgetRequiredUnits = budgetRequiredUnits
    self.budgetAvailableUnits = budgetAvailableUnits
    self.blockedReservation = blockedReservation
    self.pendingTransitionID = pendingTransitionID
    self.failureCode = failureCode
    self.relatedIDs = relatedIDs
  }
}

public struct SharedEpisodeTerminalRecord:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let terminalID: String
  public let parentGenerationSHA256: String
  public let permitID: String
  public let outcome: SharedEpisodeTerminalOutcome
  public let selectionDecisionID: String?
  public let reason: SharedEpisodeTerminalReason
  public let unresolvedDisagreementIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case terminalID = "terminal_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case permitID = "permit_id"
    case outcome
    case selectionDecisionID = "selection_decision_id"
    case reason
    case unresolvedDisagreementIDs = "unresolved_disagreement_ids"
  }

  public init(
    schemaVersion: Int = SharedEpisodeTerminalRecord.currentSchemaVersion,
    terminalID: String,
    parentGenerationSHA256: String,
    permitID: String,
    outcome: SharedEpisodeTerminalOutcome,
    selectionDecisionID: String? = nil,
    reason: SharedEpisodeTerminalReason,
    unresolvedDisagreementIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.terminalID = terminalID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.permitID = permitID
    self.outcome = outcome
    self.selectionDecisionID = selectionDecisionID
    self.reason = reason
    self.unresolvedDisagreementIDs = unresolvedDisagreementIDs
  }
}

public struct SharedEpisodeBudgetState:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let maximum: SharedEpisodeBudgetVector
  public let verificationReserve: SharedEpisodeBudgetVector
  public let handoffReserve: SharedEpisodeBudgetVector
  public let charged: SharedEpisodeBudgetVector
  public let inFlight: SharedEpisodeBudgetVector
  public let remaining: SharedEpisodeBudgetVector
  public let verificationCharged: SharedEpisodeBudgetVector
  public let handoffCharged: SharedEpisodeBudgetVector

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case maximum
    case verificationReserve = "verification_reserve"
    case handoffReserve = "handoff_reserve"
    case charged
    case inFlight = "in_flight"
    case remaining
    case verificationCharged = "verification_charged"
    case handoffCharged = "handoff_charged"
  }

  public init(
    schemaVersion: Int = SharedEpisodeBudgetState.currentSchemaVersion,
    maximum: SharedEpisodeBudgetVector,
    verificationReserve: SharedEpisodeBudgetVector,
    handoffReserve: SharedEpisodeBudgetVector,
    charged: SharedEpisodeBudgetVector,
    inFlight: SharedEpisodeBudgetVector,
    remaining: SharedEpisodeBudgetVector,
    verificationCharged: SharedEpisodeBudgetVector,
    handoffCharged: SharedEpisodeBudgetVector
  ) {
    self.schemaVersion = schemaVersion
    self.maximum = maximum
    self.verificationReserve = verificationReserve
    self.handoffReserve = handoffReserve
    self.charged = charged
    self.inFlight = inFlight
    self.remaining = remaining
    self.verificationCharged = verificationCharged
    self.handoffCharged = handoffCharged
  }
}

public struct SharedEpisodeControlReport:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let safeProductiveContinuationIDs: [String]
  public let affordableDistinguishingCheckIDs: [String]
  public let exhaustedContinuationIDs: [String]
  public let exhaustedDistinguishingCheckIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case safeProductiveContinuationIDs = "safe_productive_continuation_ids"
    case affordableDistinguishingCheckIDs = "affordable_distinguishing_check_ids"
    case exhaustedContinuationIDs = "exhausted_continuation_ids"
    case exhaustedDistinguishingCheckIDs = "exhausted_distinguishing_check_ids"
  }

  public init(
    schemaVersion: Int = SharedEpisodeControlReport.currentSchemaVersion,
    safeProductiveContinuationIDs: [String],
    affordableDistinguishingCheckIDs: [String],
    exhaustedContinuationIDs: [String],
    exhaustedDistinguishingCheckIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.safeProductiveContinuationIDs = safeProductiveContinuationIDs
    self.affordableDistinguishingCheckIDs = affordableDistinguishingCheckIDs
    self.exhaustedContinuationIDs = exhaustedContinuationIDs
    self.exhaustedDistinguishingCheckIDs = exhaustedDistinguishingCheckIDs
  }
}

public struct SharedEpisodeControlState:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 4

  public let schemaVersion: Int
  public let budgetState: SharedEpisodeBudgetState
  public let selectionDecisions: [SharedEpisodeSelectionDecision]
  public let pendingTransitions: [SharedEpisodeParkedTransition]
  public let terminal: SharedEpisodeTerminalRecord?
  public let unresolvedDisagreementIDs: [String]
  public let openReservations: [SharedEpisodeOpenReservation]
  public let completedContinuationIDs: [String]
  public let completedDistinguishingCheckIDs: [String]
  public let seenPermitIDs: [String]
  public let completedActionIDs: [String]
  public let usedExecutorIDs: [String]
  public let usedRoundIDs: [String]
  public let controlReport: SharedEpisodeControlReport

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case budgetState = "budget_state"
    case selectionDecisions = "selection_decisions"
    case pendingTransitions = "pending_transitions"
    case terminal
    case unresolvedDisagreementIDs = "unresolved_disagreement_ids"
    case openReservations = "open_reservations"
    case completedContinuationIDs = "completed_continuation_ids"
    case completedDistinguishingCheckIDs = "completed_distinguishing_check_ids"
    case seenPermitIDs = "seen_permit_ids"
    case completedActionIDs = "completed_action_ids"
    case usedExecutorIDs = "used_executor_ids"
    case usedRoundIDs = "used_round_ids"
    case controlReport = "control_report"
  }

  public init(
    schemaVersion: Int = SharedEpisodeControlState.currentSchemaVersion,
    budgetState: SharedEpisodeBudgetState,
    selectionDecisions: [SharedEpisodeSelectionDecision],
    pendingTransitions: [SharedEpisodeParkedTransition],
    terminal: SharedEpisodeTerminalRecord?,
    unresolvedDisagreementIDs: [String],
    openReservations: [SharedEpisodeOpenReservation],
    completedContinuationIDs: [String],
    completedDistinguishingCheckIDs: [String],
    seenPermitIDs: [String],
    completedActionIDs: [String],
    usedExecutorIDs: [String],
    usedRoundIDs: [String],
    controlReport: SharedEpisodeControlReport
  ) {
    self.schemaVersion = schemaVersion
    self.budgetState = budgetState
    self.selectionDecisions = selectionDecisions
    self.pendingTransitions = pendingTransitions
    self.terminal = terminal
    self.unresolvedDisagreementIDs = unresolvedDisagreementIDs
    self.openReservations = openReservations
    self.completedContinuationIDs = completedContinuationIDs
    self.completedDistinguishingCheckIDs = completedDistinguishingCheckIDs
    self.seenPermitIDs = seenPermitIDs
    self.completedActionIDs = completedActionIDs
    self.usedExecutorIDs = usedExecutorIDs
    self.usedRoundIDs = usedRoundIDs
    self.controlReport = controlReport
  }
}

public enum SharedEpisodeControlCommand:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public enum Kind:
    String, Codable, CaseIterable, Equatable, Hashable, Sendable
  {
    case actionReserved = "action_reserved"
    case contribution
    case verification
    case selection
    case modelOnlyCompleted = "model_only_completed"
    case transitionParked = "transition_parked"
    case terminal
  }

  case actionReserved(SharedEpisodeActionReservation)
  case contribution(SharedEpisodeContribution, SharedEpisodeActionSettlement)
  case verification(SharedEpisodeVerificationRecord, SharedEpisodeActionSettlement)
  case selection(SharedEpisodeSelectionDecision, SharedEpisodeActionSettlement)
  case modelOnlyCompleted(SharedEpisodeModelOnlyResult, SharedEpisodeActionSettlement)
  case transitionParked(SharedEpisodeParkedTransition, SharedEpisodeActionSettlement)
  case terminal(SharedEpisodeTerminalRecord, SharedEpisodeActionSettlement)

  private enum CodingKeys: String, CodingKey {
    case kind
    case reservation
    case contribution
    case verification
    case selection
    case modelOnlyResult = "model_only_result"
    case transition
    case terminal
    case settlement
  }

  public var kind: Kind {
    switch self {
    case .actionReserved:
      .actionReserved
    case .contribution:
      .contribution
    case .verification:
      .verification
    case .selection:
      .selection
    case .modelOnlyCompleted:
      .modelOnlyCompleted
    case .transitionParked:
      .transitionParked
    case .terminal:
      .terminal
    }
  }

  public var identifier: String {
    switch self {
    case .actionReserved(let reservation):
      reservation.permitID
    case .contribution(let contribution, _):
      contribution.contributionID
    case .verification(let verification, _):
      verification.recordID
    case .selection(let decision, _):
      decision.decisionID
    case .modelOnlyCompleted(let result, _):
      result.resultID
    case .transitionParked(let transition, _):
      transition.transitionID
    case .terminal(let terminal, _):
      terminal.terminalID
    }
  }

  public var parentGenerationSHA256: String {
    switch self {
    case .actionReserved(let reservation):
      reservation.parentGenerationSHA256
    case .contribution(let contribution, _):
      contribution.parentGenerationSHA256
    case .verification(let verification, _):
      verification.parentGenerationSHA256
    case .selection(let decision, _):
      decision.parentGenerationSHA256
    case .modelOnlyCompleted(let result, _):
      result.parentGenerationSHA256
    case .transitionParked(let transition, _):
      transition.parentGenerationSHA256
    case .terminal(let terminal, _):
      terminal.parentGenerationSHA256
    }
  }

  public var settlement: SharedEpisodeActionSettlement? {
    switch self {
    case .actionReserved:
      nil
    case .contribution(_, let settlement),
      .verification(_, let settlement),
      .selection(_, let settlement),
      .modelOnlyCompleted(_, let settlement),
      .transitionParked(_, let settlement),
      .terminal(_, let settlement):
      settlement
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(Kind.self, forKey: .kind)
    switch kind {
    case .actionReserved:
      try requireControlKeys(container, [.kind, .reservation])
      self = .actionReserved(
        try container.decode(SharedEpisodeActionReservation.self, forKey: .reservation)
      )
    case .contribution:
      try requireControlKeys(container, [.kind, .contribution, .settlement])
      self = .contribution(
        try container.decode(SharedEpisodeContribution.self, forKey: .contribution),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    case .verification:
      try requireControlKeys(container, [.kind, .verification, .settlement])
      self = .verification(
        try container.decode(SharedEpisodeVerificationRecord.self, forKey: .verification),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    case .selection:
      try requireControlKeys(container, [.kind, .selection, .settlement])
      self = .selection(
        try container.decode(SharedEpisodeSelectionDecision.self, forKey: .selection),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    case .modelOnlyCompleted:
      try requireControlKeys(container, [.kind, .modelOnlyResult, .settlement])
      self = .modelOnlyCompleted(
        try container.decode(SharedEpisodeModelOnlyResult.self, forKey: .modelOnlyResult),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    case .transitionParked:
      try requireControlKeys(container, [.kind, .transition, .settlement])
      self = .transitionParked(
        try container.decode(SharedEpisodeParkedTransition.self, forKey: .transition),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    case .terminal:
      try requireControlKeys(container, [.kind, .terminal, .settlement])
      self = .terminal(
        try container.decode(SharedEpisodeTerminalRecord.self, forKey: .terminal),
        try container.decode(SharedEpisodeActionSettlement.self, forKey: .settlement)
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(kind, forKey: .kind)
    switch self {
    case .actionReserved(let reservation):
      try container.encode(reservation, forKey: .reservation)
    case .contribution(let contribution, let settlement):
      try container.encode(contribution, forKey: .contribution)
      try container.encode(settlement, forKey: .settlement)
    case .verification(let verification, let settlement):
      try container.encode(verification, forKey: .verification)
      try container.encode(settlement, forKey: .settlement)
    case .selection(let selection, let settlement):
      try container.encode(selection, forKey: .selection)
      try container.encode(settlement, forKey: .settlement)
    case .modelOnlyCompleted(let result, let settlement):
      try container.encode(result, forKey: .modelOnlyResult)
      try container.encode(settlement, forKey: .settlement)
    case .transitionParked(let transition, let settlement):
      try container.encode(transition, forKey: .transition)
      try container.encode(settlement, forKey: .settlement)
    case .terminal(let terminal, let settlement):
      try container.encode(terminal, forKey: .terminal)
      try container.encode(settlement, forKey: .settlement)
    }
  }
}

private func requireControlKeys<Key: CodingKey>(
  _ container: KeyedDecodingContainer<Key>,
  _ expected: [Key]
) throws {
  let actualNames = Set(container.allKeys.map(\.stringValue))
  let expectedNames = Set(expected.map(\.stringValue))
  guard actualNames == expectedNames else {
    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Объект команды управления содержит лишние или отсутствующие поля."
      )
    )
  }
}

public enum SharedEpisodeControlKernel {
  static func initialState(
    plan: SharedEpisodeControlPlan
  ) throws -> SharedEpisodeControlState {
    try validatePlan(plan)
    let emptyReport = SharedEpisodeControlReport(
      safeProductiveContinuationIDs: [],
      affordableDistinguishingCheckIDs: [],
      exhaustedContinuationIDs: [],
      exhaustedDistinguishingCheckIDs: []
    )
    let state = SharedEpisodeControlState(
      budgetState: SharedEpisodeBudgetState(
        maximum: plan.budget.maximum,
        verificationReserve: plan.budget.verificationReserve,
        handoffReserve: plan.budget.handoffReserve,
        charged: .zero,
        inFlight: .zero,
        remaining: plan.budget.maximum,
        verificationCharged: .zero,
        handoffCharged: .zero
      ),
      selectionDecisions: [],
      pendingTransitions: [],
      terminal: nil,
      unresolvedDisagreementIDs: [],
      openReservations: [],
      completedContinuationIDs: [],
      completedDistinguishingCheckIDs: [],
      seenPermitIDs: [],
      completedActionIDs: [],
      usedExecutorIDs: [],
      usedRoundIDs: [],
      controlReport: emptyReport
    )
    let completed = replacingReport(
      in: state,
      with: try report(plan: plan, state: state)
    )
    try validate(completed, plan: plan)
    return completed
  }

  static func report(
    plan: SharedEpisodeControlPlan,
    state: SharedEpisodeControlState
  ) throws -> SharedEpisodeControlReport {
    try validatePlan(plan)
    if state.terminal != nil {
      return SharedEpisodeControlReport(
        safeProductiveContinuationIDs: [],
        affordableDistinguishingCheckIDs: [],
        exhaustedContinuationIDs: plan.continuations.map(\.continuationID).sorted(),
        exhaustedDistinguishingCheckIDs: plan.distinguishingChecks.map(\.checkID).sorted()
      )
    }
    let openContinuationIDs = Set(
      state.openReservations.compactMap(\.continuationID)
    )
    let openCheckIDs = Set(
      state.openReservations.compactMap(\.distinguishingCheckID)
    )
    let completedContinuationIDs = Set(state.completedContinuationIDs)
    let completedCheckIDs = Set(state.completedDistinguishingCheckIDs)

    var safeProductive: [String] = []
    var exhaustedContinuations: [String] = []
    for candidate in plan.continuations {
      let unavailable =
        completedContinuationIDs.contains(candidate.continuationID)
        || openContinuationIDs.contains(candidate.continuationID)
      let affordable = try canAfford(
        candidate.budget,
        phase: candidate.kind == .verification ? .verification : .productive,
        state: state
      )
      if candidate.safe, candidate.productive, !unavailable, affordable {
        safeProductive.append(candidate.continuationID)
      } else {
        exhaustedContinuations.append(candidate.continuationID)
      }
    }

    var affordableChecks: [String] = []
    var exhaustedChecks: [String] = []
    for check in plan.distinguishingChecks {
      let unavailable =
        completedCheckIDs.contains(check.checkID)
        || openCheckIDs.contains(check.checkID)
      let affordable = try canAfford(
        check.budget,
        phase: .verification,
        state: state
      )
      if check.safe, check.productive, !unavailable, affordable {
        affordableChecks.append(check.checkID)
      } else {
        exhaustedChecks.append(check.checkID)
      }
    }

    return SharedEpisodeControlReport(
      safeProductiveContinuationIDs: safeProductive.sorted(),
      affordableDistinguishingCheckIDs: affordableChecks.sorted(),
      exhaustedContinuationIDs: exhaustedContinuations.sorted(),
      exhaustedDistinguishingCheckIDs: exhaustedChecks.sorted()
    )
  }

  static func validatePlan(_ plan: SharedEpisodeControlPlan) throws {
    guard plan.schemaVersion == SharedEpisodeControlPlan.currentSchemaVersion,
      plan.budget.schemaVersion == SharedEpisodeBudgetPlan.currentSchemaVersion,
      plan.budget.meteringPolicyID
        == SharedEpisodeBudgetPlan.supportedMeteringPolicyID
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "План управления использует неподдерживаемую версию схемы."
      )
    }
    guard isControlIdentifier(plan.selectionPolicyID),
      isControlIdentifier(plan.selectionPlanArtifactID),
      isControlIdentifier(plan.stopPolicyID),
      isControlIdentifier(plan.selectorID),
      isControlIdentifier(plan.selectorRoleID),
      plan.selectionBasis == .verifiedEvidence,
      !plan.agreementIsEvidence,
      !plan.independenceInferredFromCount
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Политика выбора должна быть неизменяемой политикой доказательств без голосования."
      )
    }
    guard plan.budget.maximum.isStrictlyPositive,
      plan.budget.verificationReserve.isNonnegative,
      plan.budget.handoffReserve.isNonnegative
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Максимумы бюджета должны быть положительными, а резервы — неотрицательными."
      )
    }
    let protected = try plan.budget.verificationReserve.checkedAdding(
      plan.budget.handoffReserve
    )
    guard protected.isComponentwiseLessThanOrEqual(to: plan.budget.maximum) else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Сумма защищённых резервов превышает общий бюджет."
      )
    }
    guard plan.continuations.count <= SharedEpisodeControlPlan.maximumRegistryEntries,
      plan.distinguishingChecks.count <= SharedEpisodeControlPlan.maximumRegistryEntries,
      isSortedUnique(plan.continuations.map(\.continuationID)),
      isSortedUnique(plan.distinguishingChecks.map(\.checkID))
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Реестры продолжений или различающих проверок неограниченны либо неканоничны."
      )
    }
    for candidate in plan.continuations {
      guard
        candidate.schemaVersion
          == SharedEpisodeContinuationCandidate.currentSchemaVersion,
        isControlIdentifier(candidate.continuationID),
        candidate.budget.isNonnegative,
        !candidate.budget.isZero
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Реестр продолжений содержит недопустимую запись."
        )
      }
    }
    for check in plan.distinguishingChecks {
      guard check.schemaVersion == SharedEpisodeDistinguishingCheck.currentSchemaVersion,
        isControlIdentifier(check.checkID),
        check.budget.isNonnegative,
        !check.budget.isZero
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Реестр различающих проверок содержит недопустимую запись."
        )
      }
    }
  }

  static func apply(
    _ command: SharedEpisodeControlCommand,
    to state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan,
    expectedParentGenerationSHA256: String,
    selectionContext: SharedEpisodeSelectionEvidenceContext? = nil,
    currentUnresolvedDisagreementIDs: [String]? = nil
  ) throws -> SharedEpisodeControlState {
    try validate(state, plan: plan)
    guard state.terminal == nil else {
      throw SharedEpisodeMemoryError.terminalEpisode
    }
    guard isControlSHA256(expectedParentGenerationSHA256),
      command.parentGenerationSHA256 == expectedParentGenerationSHA256
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Событие управления не ссылается на точное родительское поколение."
      )
    }

    var next: SharedEpisodeControlState
    switch command {
    case .actionReserved(let reservation):
      next = try reserve(reservation, in: state, plan: plan)

    case .contribution(let contribution, let settlement):
      guard contribution.schemaVersion == SharedEpisodeContribution.currentSchemaVersion,
        isControlIdentifier(contribution.contributionID),
        isControlSHA256(contribution.contentSHA256)
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Закрывающий вклад содержит недопустимую идентичность или хэш."
        )
      }
      guard
        settlement.actual
          == (try meteredUsage(
            for: contribution,
            executors: settlement.actual.executors,
            rounds: settlement.actual.rounds
          ))
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Settlement вклада не совпадает с версионными единицами его происхождения и канонического выхода."
        )
      }
      next = try settle(
        settlement,
        expectedKind: .contribution,
        in: state
      )

    case .verification(let verification, let settlement):
      guard verification.schemaVersion == 1,
        isControlIdentifier(verification.recordID),
        isControlSHA256(verification.contentSHA256)
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Закрывающая проверка содержит недопустимую идентичность или хэш."
        )
      }
      guard
        settlement.actual
          == (try meteredUsage(
            for: verification,
            executors: settlement.actual.executors,
            rounds: settlement.actual.rounds
          ))
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Settlement проверки не совпадает с версионными единицами её происхождения и канонического выхода."
        )
      }
      next = try settle(
        settlement,
        expectedKind: .verification,
        in: state
      )
      if let disagreementIDs = currentUnresolvedDisagreementIDs {
        try validateCanonicalIdentifiers(
          disagreementIDs,
          field: "неустранённые разногласия"
        )
        next = replacingUnresolvedDisagreements(
          in: next,
          with: disagreementIDs
        )
      }

    case .selection(let decision, let settlement):
      guard let selectionContext else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Выбор не получил точный снимок вкладов, проверок и разногласий."
        )
      }
      try validateSelection(
        decision,
        context: selectionContext,
        state: state,
        plan: plan,
        expectedParentGenerationSHA256: expectedParentGenerationSHA256
      )
      next = try settle(settlement, expectedKind: .selection, in: state)
      guard
        !next.selectionDecisions.contains(where: {
          $0.decisionID == decision.decisionID
        })
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Идентификатор решения выбора уже использован."
        )
      }
      let decisions = next.selectionDecisions + [decision]
      let unresolved = decision.disagreementDispositions.compactMap { disposition in
        disposition.resolution == .retainedUnresolved
          ? disposition.disagreementID : nil
      }.sorted()
      next = replacingSelection(
        in: next,
        decisions: decisions,
        unresolvedDisagreementIDs: unresolved
      )

    case .modelOnlyCompleted(let result, let settlement):
      guard result.schemaVersion == SharedEpisodeModelOnlyResult.currentSchemaVersion,
        isControlIdentifier(result.resultID),
        isControlIdentifier(result.permitID),
        isControlIdentifier(result.continuationID),
        isControlSHA256(result.contentSHA256),
        result.permitID == settlement.permitID
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Результат model-only не закрывает точную объявленную ветвь."
        )
      }
      next = try settle(settlement, expectedKind: .modelOnly, in: state)
      guard next.completedContinuationIDs.contains(result.continuationID) else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Model-only результат не совпадает с продолжением своей резервации."
        )
      }

    case .transitionParked(let transition, let settlement):
      try validateTransition(
        transition,
        expectedParentGenerationSHA256: expectedParentGenerationSHA256
      )
      guard transition.permitID == settlement.permitID,
        !state.pendingTransitions.contains(where: {
          $0.transitionID == transition.transitionID
        })
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Внешний переход не закрывает точную резервацию или уже существует."
        )
      }
      next = try settle(settlement, expectedKind: .transition, in: state)
      var transitions = next.pendingTransitions + [transition]
      transitions.sort { $0.transitionID < $1.transitionID }
      next = replacingTransitions(in: next, with: transitions)

    case .terminal(let terminal, let settlement):
      guard let selectionContext else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "Терминальный исход не получил точный текущий снимок выбора."
        )
      }
      try validateTerminal(
        terminal,
        state: state,
        plan: plan,
        selectionContext: selectionContext,
        expectedParentGenerationSHA256: expectedParentGenerationSHA256
      )
      guard terminal.permitID == settlement.permitID else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "Терминальный исход не закрывает точную резервацию передачи."
        )
      }
      next = try settle(settlement, expectedKind: .terminal, in: state)
      next = replacingTerminal(in: next, with: terminal)
    }

    next = replacingReport(
      in: next,
      with: try report(plan: plan, state: next)
    )
    try validate(next, plan: plan)
    return next
  }

  static func reconcilingUnresolvedDisagreements(
    _ disagreementIDs: [String],
    in state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan
  ) throws -> SharedEpisodeControlState {
    try validate(state, plan: plan)
    guard state.terminal == nil else {
      throw SharedEpisodeMemoryError.terminalEpisode
    }
    try validateCanonicalIdentifiers(
      disagreementIDs,
      field: "неустранённые разногласия"
    )
    var next = replacingUnresolvedDisagreements(
      in: state,
      with: disagreementIDs
    )
    next = replacingReport(
      in: next,
      with: try report(plan: plan, state: next)
    )
    try validate(next, plan: plan)
    return next
  }

  private static func reserve(
    _ reservation: SharedEpisodeActionReservation,
    in state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan
  ) throws -> SharedEpisodeControlState {
    try validateProspectiveReservationNonBudget(
      reservation,
      state: state,
      plan: plan
    )
    if let failure = try prospectiveBudgetFailure(reservation, state: state) {
      if reservation.reserved.firstExceededDimension(
        comparedWith: state.budgetState.remaining
      ) != nil {
        throw SharedEpisodeMemoryError.budgetLimitExceeded(failure.dimension)
      }
      throw SharedEpisodeMemoryError.protectedReserveRequired
    }

    let inFlight = try state.budgetState.inFlight.checkedAdding(reservation.reserved)
    let remaining = try state.budgetState.remaining.checkedSubtracting(
      reservation.reserved
    )
    let budgetState = SharedEpisodeBudgetState(
      maximum: state.budgetState.maximum,
      verificationReserve: state.budgetState.verificationReserve,
      handoffReserve: state.budgetState.handoffReserve,
      charged: state.budgetState.charged,
      inFlight: inFlight,
      remaining: remaining,
      verificationCharged: state.budgetState.verificationCharged,
      handoffCharged: state.budgetState.handoffCharged
    )
    var reservations = state.openReservations + [reservation]
    reservations.sort { $0.permitID < $1.permitID }
    return replacingBudgetAndReservations(
      in: state,
      budgetState: budgetState,
      openReservations: reservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: inserting(reservation.permitID, into: state.seenPermitIDs),
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: inserting(reservation.executorID, into: state.usedExecutorIDs),
      usedRoundIDs: inserting(reservation.roundID, into: state.usedRoundIDs)
    )
  }

  private static func settle(
    _ settlement: SharedEpisodeActionSettlement,
    expectedKind: SharedEpisodeActionKind,
    in state: SharedEpisodeControlState
  ) throws -> SharedEpisodeControlState {
    guard settlement.schemaVersion == SharedEpisodeActionSettlement.currentSchemaVersion,
      settlement.meteringPolicyID == SharedEpisodeBudgetPlan.supportedMeteringPolicyID,
      isControlIdentifier(settlement.permitID),
      isControlIdentifier(settlement.actionID),
      settlement.actual.isNonnegative
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Settlement содержит недопустимую схему, идентичность или расход."
      )
    }
    guard
      let reservation = state.openReservations.first(where: {
        $0.permitID == settlement.permitID
      }), reservation.actionID == settlement.actionID,
      reservation.kind == expectedKind,
      reservation.meteringPolicyID == settlement.meteringPolicyID
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Settlement не закрывает точные permit, действие и вид события."
      )
    }
    guard settlement.actual.isComponentwiseLessThanOrEqual(to: reservation.reserved) else {
      throw SharedEpisodeMemoryError.settlementExceedsReservation
    }
    guard settlement.actual.executors == reservation.reserved.executors,
      settlement.actual.rounds == reservation.reserved.rounds
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Settlement не может отменить уже использованные distinct-идентичности."
      )
    }

    let inFlight = try state.budgetState.inFlight.checkedSubtracting(
      reservation.reserved
    )
    let charged = try state.budgetState.charged.checkedAdding(settlement.actual)
    var verificationCharged = state.budgetState.verificationCharged
    var handoffCharged = state.budgetState.handoffCharged
    switch reservation.phase {
    case .productive:
      break
    case .verification:
      verificationCharged = try verificationCharged.checkedAdding(settlement.actual)
    case .handoff:
      handoffCharged = try handoffCharged.checkedAdding(settlement.actual)
    }
    let committedAndReserved = try charged.checkedAdding(inFlight)
    let remaining = try state.budgetState.maximum.checkedSubtracting(
      committedAndReserved
    )
    let budgetState = SharedEpisodeBudgetState(
      maximum: state.budgetState.maximum,
      verificationReserve: state.budgetState.verificationReserve,
      handoffReserve: state.budgetState.handoffReserve,
      charged: charged,
      inFlight: inFlight,
      remaining: remaining,
      verificationCharged: verificationCharged,
      handoffCharged: handoffCharged
    )
    let reservations = state.openReservations.filter {
      $0.permitID != settlement.permitID
    }
    let continuations =
      reservation.continuationID.map {
        inserting($0, into: state.completedContinuationIDs)
      } ?? state.completedContinuationIDs
    let checks =
      reservation.distinguishingCheckID.map {
        inserting($0, into: state.completedDistinguishingCheckIDs)
      } ?? state.completedDistinguishingCheckIDs
    return replacingBudgetAndReservations(
      in: state,
      budgetState: budgetState,
      openReservations: reservations,
      completedContinuationIDs: continuations,
      completedDistinguishingCheckIDs: checks,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: inserting(
        settlement.actionID,
        into: state.completedActionIDs
      ),
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs
    )
  }

  private static func validateSelection(
    _ decision: SharedEpisodeSelectionDecision,
    context: SharedEpisodeSelectionEvidenceContext,
    state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan,
    expectedParentGenerationSHA256: String
  ) throws {
    guard decision.schemaVersion == SharedEpisodeSelectionDecision.currentSchemaVersion,
      isControlIdentifier(decision.decisionID),
      decision.parentGenerationSHA256 == expectedParentGenerationSHA256,
      decision.selectionContextSHA256
        == CanonicalMemoryJSON.sha256(try context.canonicalJSONData()),
      decision.replacesDecisionID == state.selectionDecisions.last?.decisionID,
      decision.selectionPolicyID == plan.selectionPolicyID,
      decision.selectionPlanArtifactID == plan.selectionPlanArtifactID,
      decision.stopPolicyID == plan.stopPolicyID,
      decision.selectorID == plan.selectorID,
      decision.selectorRoleID == plan.selectorRoleID,
      decision.basis == plan.selectionBasis,
      decision.basis == .verifiedEvidence,
      decision.status == .selectedInModel,
      !decision.userConfirmed,
      !decision.authorized,
      isControlIdentifier(decision.selectorID),
      isControlIdentifier(decision.selectorRoleID)
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Решение не совпадает с неизменяемой политикой доказательств или повышает внутренний выбор до авторизации."
      )
    }
    try validateSelectionContext(context, plan: plan)
    guard decision.criteriaArtifactID == context.criteriaArtifactID,
      decision.criteriaSHA256 == context.criteriaSHA256,
      decision.criterionIDs == context.criterionIDs
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Решение не ссылается на точный артефакт и полный набор критериев."
      )
    }
    try validateCanonicalIdentifiers(
      decision.criterionIDs,
      field: "критерии выбора"
    )
    guard
      decision.considerations.map(\.contributionID)
        == context.contributions.map(\.contributionID)
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Решение рассмотрело не точный полный набор вкладов."
      )
    }

    let contributionsByID = Dictionary(
      uniqueKeysWithValues: context.contributions.map { ($0.contributionID, $0) }
    )
    let verificationsByID = Dictionary(
      uniqueKeysWithValues: context.verifications.map { ($0.recordID, $0) }
    )
    let disagreementsByID = Dictionary(
      uniqueKeysWithValues: context.disagreements.map { ($0.disagreementID, $0) }
    )
    var selectedIDs: [String] = []
    for consideration in decision.considerations {
      guard
        consideration.schemaVersion
          == SharedEpisodeSelectionConsideration.currentSchemaVersion,
        let contribution = contributionsByID[consideration.contributionID],
        consideration.contentSHA256 == contribution.contentSHA256,
        consideration.provenanceSHA256 == contribution.provenanceSHA256,
        isControlIdentifier(consideration.reasonCode)
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Рассмотренный вклад не совпадает с точными хэшами или причиной решения."
        )
      }
      try validateCanonicalIdentifiers(
        consideration.verificationRecordIDs,
        field: "проверки рассмотренного вклада"
      )
      try validateCanonicalIdentifiers(
        consideration.evidenceIDs,
        field: "доказательства рассмотренного вклада"
      )
      let expectedVerifications = context.verifications.filter {
        $0.contributionIDs.contains(consideration.contributionID)
      }
      let expectedVerificationIDs = expectedVerifications.map(\.recordID).sorted()
      let expectedEvidenceIDs = Array(
        Set(
          expectedVerifications.flatMap { snapshot in
            snapshot.evidenceBindings.first(where: {
              $0.contributionID == consideration.contributionID
            })?.evidenceIDs ?? []
          })
      ).sorted()
      guard consideration.verificationRecordIDs == expectedVerificationIDs,
        consideration.evidenceIDs == expectedEvidenceIDs,
        consideration.verificationRecordIDs.allSatisfy({
          verificationsByID[$0] != nil
        })
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Решение опустило или подменило проверку либо доказательство вклада."
        )
      }
      if consideration.disposition == .selected {
        selectedIDs.append(consideration.contributionID)
        let hasExternalPassedEvidence = expectedVerifications.contains { snapshot in
          snapshot.outcome == .passed
            && snapshot.standing == .externalByObservedFeatures
            && !(snapshot.evidenceBindings.first(where: {
              $0.contributionID == consideration.contributionID
            })?.evidenceIDs.isEmpty ?? true)
        }
        guard hasExternalPassedEvidence, !consideration.evidenceIDs.isEmpty else {
          throw SharedEpisodeMemoryError.invalidSelection(
            "Выбранный вклад не имеет конкретной внешней успешно проверенной опоры."
          )
        }
      }
    }
    guard selectedIDs.count <= 1,
      selectedIDs.first == decision.selectedContributionID,
      decision.selectedContributionID == nil || selectedIDs.count == 1
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Выбранный результат не совпадает с диспозициями рассмотренных вкладов."
      )
    }

    guard
      decision.disagreementDispositions.map(\.disagreementID)
        == context.disagreementIDs
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Решение не сохранило точный полный набор разногласий."
      )
    }
    for disposition in decision.disagreementDispositions {
      guard
        disposition.schemaVersion
          == SharedEpisodeDisagreementDisposition.currentSchemaVersion,
        isControlIdentifier(disposition.reasonCode)
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Диспозиция разногласия содержит неверную схему или причину."
        )
      }
      try validateCanonicalIdentifiers(
        disposition.evidenceIDs,
        field: "доказательства диспозиции разногласия"
      )
      guard let disagreement = disagreementsByID[disposition.disagreementID],
        Set(disposition.evidenceIDs).isSubset(
          of: Set(disagreement.eligibleEvidenceIDs)
        )
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Диспозиция разногласия ссылается на доказательство другого утверждения или вклада."
        )
      }
      if disposition.resolution == .resolved,
        disposition.evidenceIDs.isEmpty
      {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Разногласие объявлено разрешённым без различающего доказательства."
        )
      }
    }
  }

  private static func validateSelectionContext(
    _ context: SharedEpisodeSelectionEvidenceContext,
    plan: SharedEpisodeControlPlan
  ) throws {
    guard isControlIdentifier(context.criteriaArtifactID),
      isControlSHA256(context.criteriaSHA256),
      isSortedUnique(context.contributions.map(\.contributionID)),
      isSortedUnique(context.verifications.map(\.recordID)),
      isSortedUnique(context.disagreements.map(\.disagreementID))
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Снимок происхождения выбора неканоничен."
      )
    }
    try validateCanonicalIdentifiers(context.criterionIDs, field: "критерии снимка")
    try validateCanonicalIdentifiers(
      context.disagreementIDs,
      field: "разногласия снимка"
    )
    for contribution in context.contributions {
      guard isControlIdentifier(contribution.contributionID),
        isControlSHA256(contribution.contentSHA256),
        isControlSHA256(contribution.provenanceSHA256)
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Снимок вклада содержит недопустимую идентичность или хэш."
        )
      }
    }
    let contributionIDs = Set(context.contributions.map(\.contributionID))
    for verification in context.verifications {
      guard verification.distinguishingCheckID.map(isControlIdentifier) ?? true,
        verification.distinguishingCheckID.map({ checkID in
          plan.distinguishingChecks.contains { $0.checkID == checkID }
        }) ?? true
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Снимок проверки ссылается на неизвестную различающую проверку."
        )
      }
      try validateCanonicalIdentifiers(
        verification.contributionIDs,
        field: "вклады проверки выбора"
      )
      try validateCanonicalIdentifiers(
        verification.evidenceIDs,
        field: "доказательства проверки выбора"
      )
      guard verification.contributionIDs.allSatisfy(contributionIDs.contains),
        verification.evidenceBindings.map(\.contributionID)
          == verification.contributionIDs,
        Set(verification.evidenceBindings.flatMap(\.evidenceIDs))
          == Set(verification.evidenceIDs)
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Снимок проверки теряет вклад или точную привязку его доказательств."
        )
      }
      for binding in verification.evidenceBindings {
        try validateCanonicalIdentifiers(
          binding.evidenceIDs,
          field: "доказательства точного вклада"
        )
      }
    }
    let verificationsByID = Dictionary(
      uniqueKeysWithValues: context.verifications.map { ($0.recordID, $0) }
    )
    for disagreement in context.disagreements {
      guard isControlIdentifier(disagreement.disagreementID),
        isControlIdentifier(disagreement.verificationRecordID),
        isControlIdentifier(disagreement.claimID),
        isControlIdentifier(disagreement.contributionID),
        isControlSHA256(disagreement.resultSHA256),
        let contribution = context.contributions.first(where: {
          $0.contributionID == disagreement.contributionID
        }),
        disagreement.resultSHA256 == contribution.contentSHA256,
        let verification = verificationsByID[disagreement.verificationRecordID],
        verification.contributionIDs.contains(disagreement.contributionID)
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Снимок разногласия не закрепляет точную проверку, вклад, утверждение и его доказательства."
        )
      }
      try validateCanonicalIdentifiers(
        disagreement.eligibleEvidenceIDs,
        field: "допустимые доказательства разногласия"
      )
      let eligibleEvidenceIDs = Set(
        context.verifications.flatMap { candidate -> [String] in
          guard
            candidate.recordID == disagreement.verificationRecordID
              || candidate.distinguishingCheckID != nil,
            candidate.contributionIDs.contains(disagreement.contributionID)
          else { return [] }
          return candidate.evidenceBindings.first(where: {
            $0.contributionID == disagreement.contributionID
          })?.evidenceIDs ?? []
        }
      )
      guard Set(disagreement.eligibleEvidenceIDs).isSubset(of: eligibleEvidenceIDs) else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Снимок разногласия допускает доказательство вне исходного утверждения или завершённой различающей проверки."
        )
      }
    }
  }

  private static func validateTransition(
    _ transition: SharedEpisodeParkedTransition,
    expectedParentGenerationSHA256: String
  ) throws {
    guard transition.schemaVersion == SharedEpisodeParkedTransition.currentSchemaVersion,
      transition.transitionVersion > 0,
      transition.parentGenerationSHA256 == expectedParentGenerationSHA256,
      isControlIdentifier(transition.transitionID),
      isControlIdentifier(transition.permitID),
      isControlIdentifier(transition.objectID),
      isControlIdentifier(transition.objectVersion),
      isControlIdentifier(transition.confirmationPolicyID),
      isControlSHA256(transition.expectedEffectSHA256),
      transition.phase == .awaitingConfirmation,
      !transition.userConfirmed,
      !transition.authorized
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Ожидающий переход должен быть точным, версионированным и неавторизованным."
      )
    }
  }

  private static func validateTerminal(
    _ terminal: SharedEpisodeTerminalRecord,
    state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan,
    selectionContext: SharedEpisodeSelectionEvidenceContext,
    expectedParentGenerationSHA256: String
  ) throws {
    guard terminal.schemaVersion == SharedEpisodeTerminalRecord.currentSchemaVersion,
      terminal.reason.schemaVersion == SharedEpisodeTerminalReason.currentSchemaVersion,
      terminal.parentGenerationSHA256 == expectedParentGenerationSHA256,
      isControlIdentifier(terminal.terminalID),
      isControlIdentifier(terminal.permitID),
      terminal.selectionDecisionID == state.selectionDecisions.last?.decisionID,
      terminal.selectionDecisionID.map(isControlIdentifier) ?? true,
      terminal.unresolvedDisagreementIDs == state.unresolvedDisagreementIDs
    else {
      throw SharedEpisodeMemoryError.invalidTerminal(
        "Терминальная запись неканонична или теряет неустранённые разногласия."
      )
    }
    try validateCanonicalIdentifiers(
      terminal.reason.relatedIDs,
      field: "связанные объекты терминальной причины",
      terminal: true
    )
    guard
      let terminalReservation = state.openReservations.first(where: {
        $0.permitID == terminal.permitID
          && $0.kind == .terminal
          && $0.phase == .handoff
      })
    else {
      throw SharedEpisodeMemoryError.invalidTerminal(
        "Терминальная запись не имеет предварительной handoff-резервации."
      )
    }

    switch terminal.outcome {
    case .goalMet:
      guard terminal.reason.code == .goalCriteriaMet,
        terminal.reason.budgetDimension == nil,
        terminal.reason.blockedReservation == nil,
        terminal.reason.pendingTransitionID == nil,
        terminal.reason.failureCode == nil,
        terminal.reason.budgetRequiredUnits == nil,
        terminal.reason.budgetAvailableUnits == nil,
        terminal.selectionDecisionID != nil,
        state.unresolvedDisagreementIDs.isEmpty,
        terminal.unresolvedDisagreementIDs.isEmpty,
        state.selectionDecisions.last?.selectedContributionID != nil,
        state.selectionDecisions.last?.selectionContextSHA256
          == CanonicalMemoryJSON.sha256(try selectionContext.canonicalJSONData())
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "goal_met требует выбранного по доказательствам результата и точной причины."
        )
      }

    case .budgetExhausted:
      guard terminal.reason.code == .budgetLimitReached,
        let blocked = terminal.reason.blockedReservation,
        let dimension = terminal.reason.budgetDimension,
        let required = terminal.reason.budgetRequiredUnits,
        let available = terminal.reason.budgetAvailableUnits,
        terminal.reason.pendingTransitionID == nil,
        terminal.reason.failureCode == nil,
        blocked.parentGenerationSHA256 == expectedParentGenerationSHA256,
        blocked.phase != .handoff,
        blocked.executorID != terminalReservation.executorID,
        blocked.roundID != terminalReservation.roundID
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "budget_exhausted требует точной отклонённой резервации и размерности."
        )
      }
      try validateProspectiveReservationNonBudget(
        blocked,
        state: state,
        plan: plan
      )
      guard let failure = try prospectiveBudgetFailure(blocked, state: state),
        failure.dimension == dimension,
        failure.required == required,
        failure.available == available
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "Причина budget_exhausted не воспроизводит единственный бюджетный отказ и точные required/available."
        )
      }

    case .needsInput:
      let usefulContinuationIDs = Set(
        plan.continuations.filter { $0.safe && $0.productive }.map(\.continuationID)
      )
      guard terminal.reason.code == .pendingTransitionRequiresInput,
        let transitionID = terminal.reason.pendingTransitionID,
        terminal.reason.budgetDimension == nil,
        terminal.reason.budgetRequiredUnits == nil,
        terminal.reason.budgetAvailableUnits == nil,
        terminal.reason.blockedReservation == nil,
        terminal.reason.failureCode == nil,
        state.controlReport.safeProductiveContinuationIDs.isEmpty,
        !state.openReservations.contains(where: { reservation in
          reservation.continuationID.map(usefulContinuationIDs.contains) ?? false
        }),
        state.pendingTransitions.contains(where: {
          $0.transitionID == transitionID
            && $0.phase == .awaitingConfirmation
            && !$0.userConfirmed
            && !$0.authorized
        })
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "needs_input допустим только после исчерпания безопасных продуктивных продолжений."
        )
      }

    case .unresolvedConflict:
      let distinguishingCheckIDs = Set(
        plan.distinguishingChecks.filter { $0.safe && $0.productive }.map(\.checkID)
      )
      guard terminal.reason.code == .noDistinguishingCheck,
        terminal.reason.budgetDimension == nil,
        terminal.reason.budgetRequiredUnits == nil,
        terminal.reason.budgetAvailableUnits == nil,
        terminal.reason.blockedReservation == nil,
        terminal.reason.pendingTransitionID == nil,
        terminal.reason.failureCode == nil,
        !state.unresolvedDisagreementIDs.isEmpty,
        state.controlReport.affordableDistinguishingCheckIDs.isEmpty,
        !state.openReservations.contains(where: { reservation in
          reservation.distinguishingCheckID.map(distinguishingCheckIDs.contains)
            ?? false
        })
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "unresolved_conflict допустим только после исчерпания различающих проверок."
        )
      }

    case .failed:
      guard
        terminal.reason.code == .executionFailed
          || terminal.reason.code == .noLegalProgress,
        terminal.reason.budgetDimension == nil,
        terminal.reason.budgetRequiredUnits == nil,
        terminal.reason.budgetAvailableUnits == nil,
        terminal.reason.blockedReservation == nil,
        terminal.reason.pendingTransitionID == nil,
        terminal.reason.failureCode.map(isControlIdentifier) == true
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "failed требует машиночитаемого кода сбоя без ложной бюджетной причины."
        )
      }
    }
  }

  static func validate(
    _ state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan
  ) throws {
    try validatePlan(plan)
    guard state.schemaVersion == SharedEpisodeControlState.currentSchemaVersion,
      state.budgetState.schemaVersion == SharedEpisodeBudgetState.currentSchemaVersion,
      state.controlReport.schemaVersion == SharedEpisodeControlReport.currentSchemaVersion,
      state.budgetState.maximum == plan.budget.maximum,
      state.budgetState.verificationReserve == plan.budget.verificationReserve,
      state.budgetState.handoffReserve == plan.budget.handoffReserve
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Состояние управления не совпадает с версией и бюджетом seed."
      )
    }
    let budget = state.budgetState
    guard budget.charged.isNonnegative,
      budget.inFlight.isNonnegative,
      budget.remaining.isNonnegative,
      budget.verificationCharged.isNonnegative,
      budget.handoffCharged.isNonnegative
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Состояние бюджета содержит отрицательную величину."
      )
    }
    let chargedAndInFlight = try budget.charged.checkedAdding(budget.inFlight)
    guard chargedAndInFlight.isComponentwiseLessThanOrEqual(to: budget.maximum),
      try budget.maximum.checkedSubtracting(chargedAndInFlight) == budget.remaining
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Остаток бюджета не выводится из списаний и открытых резерваций."
      )
    }

    try validateCanonicalIdentifiers(
      state.unresolvedDisagreementIDs,
      field: "неустранённые разногласия состояния"
    )
    try validateCanonicalIdentifiers(
      state.completedContinuationIDs,
      field: "завершённые продолжения"
    )
    try validateCanonicalIdentifiers(
      state.completedDistinguishingCheckIDs,
      field: "завершённые различающие проверки"
    )
    try validateCanonicalIdentifiers(state.seenPermitIDs, field: "использованные permit")
    try validateCanonicalIdentifiers(
      state.completedActionIDs,
      field: "завершённые действия"
    )
    try validateCanonicalIdentifiers(
      state.usedExecutorIDs,
      field: "использованные исполнители"
    )
    try validateCanonicalIdentifiers(
      state.usedRoundIDs,
      field: "использованные раунды"
    )
    try validateCanonicalIdentifiers(
      state.controlReport.safeProductiveContinuationIDs,
      field: "доступные продуктивные продолжения"
    )
    try validateCanonicalIdentifiers(
      state.controlReport.affordableDistinguishingCheckIDs,
      field: "доступные различающие проверки"
    )
    try validateCanonicalIdentifiers(
      state.controlReport.exhaustedContinuationIDs,
      field: "исчерпанные продолжения"
    )
    try validateCanonicalIdentifiers(
      state.controlReport.exhaustedDistinguishingCheckIDs,
      field: "исчерпанные различающие проверки"
    )

    guard isSortedUnique(state.openReservations.map(\.permitID)),
      Set(state.openReservations.map(\.actionID)).count
        == state.openReservations.count,
      state.openReservations.allSatisfy({
        state.seenPermitIDs.contains($0.permitID)
          && !state.completedActionIDs.contains($0.actionID)
      })
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Открытые резервации неканоничны или конфликтуют с завершёнными действиями."
      )
    }
    var openTotal = SharedEpisodeBudgetVector.zero
    var verificationInFlight = SharedEpisodeBudgetVector.zero
    var handoffInFlight = SharedEpisodeBudgetVector.zero
    for reservation in state.openReservations {
      try validateReservationRecord(reservation, plan: plan)
      openTotal = try openTotal.checkedAdding(reservation.reserved)
      switch reservation.phase {
      case .productive:
        break
      case .verification:
        verificationInFlight = try verificationInFlight.checkedAdding(
          reservation.reserved
        )
      case .handoff:
        handoffInFlight = try handoffInFlight.checkedAdding(reservation.reserved)
      }
    }
    guard openTotal == budget.inFlight,
      try budget.verificationCharged.checkedAdding(verificationInFlight)
        .isComponentwiseLessThanOrEqual(to: budget.verificationReserve),
      try budget.handoffCharged.checkedAdding(handoffInFlight)
        .isComponentwiseLessThanOrEqual(to: budget.handoffReserve)
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Открытые резервации или фазовые списания не совпадают с бюджетным состоянием."
      )
    }

    guard
      Set(state.selectionDecisions.map(\.decisionID)).count
        == state.selectionDecisions.count,
      isSortedUnique(state.pendingTransitions.map(\.transitionID))
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Решения или ожидающие переходы неканоничны."
      )
    }
    for (index, decision) in state.selectionDecisions.enumerated() {
      guard decision.schemaVersion == SharedEpisodeSelectionDecision.currentSchemaVersion,
        isControlSHA256(decision.selectionContextSHA256),
        decision.replacesDecisionID
          == (index == 0 ? nil : state.selectionDecisions[index - 1].decisionID),
        decision.selectionPolicyID == plan.selectionPolicyID,
        decision.selectionPlanArtifactID == plan.selectionPlanArtifactID,
        decision.stopPolicyID == plan.stopPolicyID,
        decision.basis == .verifiedEvidence,
        decision.status == .selectedInModel,
        !decision.userConfirmed,
        !decision.authorized,
        isSortedUnique(decision.considerations.map(\.contributionID)),
        isSortedUnique(decision.disagreementDispositions.map(\.disagreementID))
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Сохранённое решение выбора нарушает неизменяемую политику."
        )
      }
    }
    for transition in state.pendingTransitions {
      guard transition.schemaVersion == SharedEpisodeParkedTransition.currentSchemaVersion,
        transition.phase == .awaitingConfirmation,
        !transition.userConfirmed,
        !transition.authorized
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Сохранённый внешний переход не является неавторизованным ожиданием."
        )
      }
    }
    if let terminal = state.terminal {
      guard terminal.schemaVersion == SharedEpisodeTerminalRecord.currentSchemaVersion,
        terminal.selectionDecisionID == state.selectionDecisions.last?.decisionID,
        terminal.unresolvedDisagreementIDs == state.unresolvedDisagreementIDs
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Терминальное состояние не сохраняет точные разногласия."
        )
      }
    }
    guard state.controlReport == (try report(plan: plan, state: state)) else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Отчёт доступных продолжений не выводится из плана и бюджета."
      )
    }
  }

  private static func validateReservationRecord(
    _ reservation: SharedEpisodeActionReservation,
    plan: SharedEpisodeControlPlan
  ) throws {
    guard reservation.schemaVersion == SharedEpisodeActionReservation.currentSchemaVersion,
      reservation.meteringPolicyID == plan.budget.meteringPolicyID,
      isControlIdentifier(reservation.permitID),
      isControlIdentifier(reservation.actionID),
      isControlSHA256(reservation.parentGenerationSHA256),
      isControlIdentifier(reservation.executorID),
      isControlIdentifier(reservation.roundID),
      reservation.continuationID.map(isControlIdentifier) ?? true,
      reservation.distinguishingCheckID.map(isControlIdentifier) ?? true,
      reservation.reserved.isNonnegative,
      !reservation.reserved.isZero,
      !(reservation.continuationID != nil
        && reservation.distinguishingCheckID != nil)
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Резервация содержит неверную схему, идентичность, хэш или бюджет."
      )
    }
  }

  private struct ProspectiveBudgetFailure {
    let dimension: SharedEpisodeBudgetDimension
    let required: Int64
    let available: Int64
  }

  private static func validateProspectiveReservationNonBudget(
    _ reservation: SharedEpisodeActionReservation,
    state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan
  ) throws {
    try validateReservationRecord(reservation, plan: plan)
    guard !state.seenPermitIDs.contains(reservation.permitID),
      !state.completedActionIDs.contains(reservation.actionID),
      !state.openReservations.contains(where: {
        $0.actionID == reservation.actionID
      })
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Permit или действие уже использованы в текущем поколении."
      )
    }
    guard reservationKindIsCompatibleWithPhase(reservation) else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Вид действия несовместим с фазой его резервации."
      )
    }
    try validateReservationRegistryReference(reservation, plan: plan, state: state)
    let expectedExecutorUnits: Int64 =
      state.usedExecutorIDs.contains(reservation.executorID) ? 0 : 1
    let expectedRoundUnits: Int64 =
      state.usedRoundIDs.contains(reservation.roundID) ? 0 : 1
    guard reservation.reserved.executors == expectedExecutorUnits,
      reservation.reserved.rounds == expectedRoundUnits
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Размерности исполнителей и раундов должны точно считать новые distinct-идентичности."
      )
    }
  }

  private static func prospectiveBudgetFailure(
    _ reservation: SharedEpisodeActionReservation,
    state: SharedEpisodeControlState
  ) throws -> ProspectiveBudgetFailure? {
    let available = try availableBudget(
      for: reservation.phase,
      state: state
    )
    guard
      let dimension = reservation.reserved.firstExceededDimension(
        comparedWith: available
      )
    else {
      return nil
    }
    return ProspectiveBudgetFailure(
      dimension: dimension,
      required: reservation.reserved[dimension],
      available: available[dimension]
    )
  }

  static func budgetFailureWitness(
    for reservation: SharedEpisodeActionReservation,
    state: SharedEpisodeControlState,
    plan: SharedEpisodeControlPlan
  ) throws -> (
    dimension: SharedEpisodeBudgetDimension,
    required: Int64,
    available: Int64
  )? {
    try validateProspectiveReservationNonBudget(
      reservation,
      state: state,
      plan: plan
    )
    guard
      let failure = try prospectiveBudgetFailure(
        reservation,
        state: state
      )
    else {
      return nil
    }
    return (failure.dimension, failure.required, failure.available)
  }

  public static func meteredUsage(
    for contribution: SharedEpisodeContribution,
    executors: Int64,
    rounds: Int64
  ) throws -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: executors,
      rounds: rounds,
      modelCalls: contribution.provenance.modelID == nil ? 0 : 1,
      toolCalls: Int64(contribution.provenance.instrumentObservations.count),
      input: Int64(contribution.provenance.localInputSHA256s.count),
      output: Int64(try contribution.content.canonicalJSONData().count)
    )
  }

  public static func meteredUsage(
    for verification: SharedEpisodeVerificationRecord,
    executors: Int64,
    rounds: Int64
  ) throws -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: executors,
      rounds: rounds,
      modelCalls: verification.provenance.modelID == nil ? 0 : 1,
      toolCalls: Int64(Set(verification.content.evidence.map(\.observationID)).count),
      input: Int64(verification.provenance.localInputSHA256s.count),
      output: Int64(try verification.content.canonicalJSONData().count)
    )
  }

  private static func validateReservationRegistryReference(
    _ reservation: SharedEpisodeActionReservation,
    plan: SharedEpisodeControlPlan,
    state: SharedEpisodeControlState
  ) throws {
    if let continuationID = reservation.continuationID {
      guard
        let candidate = plan.continuations.first(where: {
          $0.continuationID == continuationID
        }), candidate.safe, candidate.productive,
        candidate.budget == reservation.reserved,
        !state.completedContinuationIDs.contains(continuationID),
        !state.openReservations.contains(where: {
          $0.continuationID == continuationID
        })
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Резервация не совпадает с доступным предобъявленным продолжением."
        )
      }
      let expectedKind: SharedEpisodeActionKind
      switch candidate.kind {
      case .modelOnly:
        expectedKind = .modelOnly
      case .verification:
        expectedKind = .verification
      case .selection:
        expectedKind = .selection
      }
      guard reservation.kind == expectedKind else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Вид продолжения не совпадает с видом зарезервированного действия."
        )
      }
    }
    if let checkID = reservation.distinguishingCheckID {
      guard
        let check = plan.distinguishingChecks.first(where: {
          $0.checkID == checkID
        }), check.safe, check.productive,
        check.budget == reservation.reserved,
        reservation.kind == .verification,
        reservation.phase == .verification,
        !state.completedDistinguishingCheckIDs.contains(checkID),
        !state.openReservations.contains(where: {
          $0.distinguishingCheckID == checkID
        })
      else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Резервация не совпадает с доступной предобъявленной различающей проверкой."
        )
      }
    }
    switch reservation.kind {
    case .modelOnly:
      guard reservation.continuationID != nil else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Model-only действие не ссылается на предобъявленное продолжение."
        )
      }
    case .verification:
      break
    case .contribution, .selection, .transition, .terminal:
      break
    }
  }

  private static func reservationKindIsCompatibleWithPhase(
    _ reservation: SharedEpisodeActionReservation
  ) -> Bool {
    switch (reservation.phase, reservation.kind) {
    case (.productive, .contribution),
      (.productive, .modelOnly),
      (.productive, .selection),
      (.verification, .verification),
      (.verification, .selection),
      (.handoff, .transition),
      (.handoff, .terminal):
      true
    default:
      false
    }
  }

  private static func canAfford(
    _ amount: SharedEpisodeBudgetVector,
    phase: SharedEpisodeActionPhase,
    state: SharedEpisodeControlState
  ) throws -> Bool {
    guard amount.isNonnegative else { return false }
    return amount.isComponentwiseLessThanOrEqual(
      to: try availableBudget(for: phase, state: state)
    )
  }

  private static func availableBudget(
    for phase: SharedEpisodeActionPhase,
    state: SharedEpisodeControlState
  ) throws -> SharedEpisodeBudgetVector {
    let verificationInFlight = try phaseInFlight(.verification, state: state)
    let handoffInFlight = try phaseInFlight(.handoff, state: state)
    let verificationUsed = try state.budgetState.verificationCharged.checkedAdding(
      verificationInFlight
    )
    let handoffUsed = try state.budgetState.handoffCharged.checkedAdding(
      handoffInFlight
    )
    let verificationOutstanding = try state.budgetState.verificationReserve
      .checkedSubtracting(verificationUsed)
    let handoffOutstanding = try state.budgetState.handoffReserve.checkedSubtracting(
      handoffUsed
    )
    switch phase {
    case .productive:
      let protected = try verificationOutstanding.checkedAdding(handoffOutstanding)
      return try state.budgetState.remaining.checkedSubtracting(
        protected
      )
    case .verification:
      return componentwiseMinimum(
        state.budgetState.remaining,
        verificationOutstanding
      )
    case .handoff:
      return componentwiseMinimum(
        state.budgetState.remaining,
        handoffOutstanding
      )
    }
  }

  private static func componentwiseMinimum(
    _ left: SharedEpisodeBudgetVector,
    _ right: SharedEpisodeBudgetVector
  ) -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: min(left.executors, right.executors),
      rounds: min(left.rounds, right.rounds),
      modelCalls: min(left.modelCalls, right.modelCalls),
      toolCalls: min(left.toolCalls, right.toolCalls),
      input: min(left.input, right.input),
      output: min(left.output, right.output)
    )
  }

  private static func phaseInFlight(
    _ phase: SharedEpisodeActionPhase,
    state: SharedEpisodeControlState
  ) throws -> SharedEpisodeBudgetVector {
    try state.openReservations.filter { $0.phase == phase }.reduce(.zero) {
      try $0.checkedAdding($1.reserved)
    }
  }

  private static func replacingBudgetAndReservations(
    in state: SharedEpisodeControlState,
    budgetState: SharedEpisodeBudgetState,
    openReservations: [SharedEpisodeOpenReservation],
    completedContinuationIDs: [String],
    completedDistinguishingCheckIDs: [String],
    seenPermitIDs: [String],
    completedActionIDs: [String],
    usedExecutorIDs: [String],
    usedRoundIDs: [String]
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: budgetState,
      selectionDecisions: state.selectionDecisions,
      pendingTransitions: state.pendingTransitions,
      terminal: state.terminal,
      unresolvedDisagreementIDs: state.unresolvedDisagreementIDs,
      openReservations: openReservations,
      completedContinuationIDs: completedContinuationIDs,
      completedDistinguishingCheckIDs: completedDistinguishingCheckIDs,
      seenPermitIDs: seenPermitIDs,
      completedActionIDs: completedActionIDs,
      usedExecutorIDs: usedExecutorIDs,
      usedRoundIDs: usedRoundIDs,
      controlReport: state.controlReport
    )
  }

  private static func replacingReport(
    in state: SharedEpisodeControlState,
    with report: SharedEpisodeControlReport
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: state.budgetState,
      selectionDecisions: state.selectionDecisions,
      pendingTransitions: state.pendingTransitions,
      terminal: state.terminal,
      unresolvedDisagreementIDs: state.unresolvedDisagreementIDs,
      openReservations: state.openReservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs,
      controlReport: report
    )
  }

  private static func replacingUnresolvedDisagreements(
    in state: SharedEpisodeControlState,
    with disagreementIDs: [String]
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: state.budgetState,
      selectionDecisions: state.selectionDecisions,
      pendingTransitions: state.pendingTransitions,
      terminal: state.terminal,
      unresolvedDisagreementIDs: disagreementIDs,
      openReservations: state.openReservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs,
      controlReport: state.controlReport
    )
  }

  private static func replacingSelection(
    in state: SharedEpisodeControlState,
    decisions: [SharedEpisodeSelectionDecision],
    unresolvedDisagreementIDs: [String]
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: state.budgetState,
      selectionDecisions: decisions,
      pendingTransitions: state.pendingTransitions,
      terminal: state.terminal,
      unresolvedDisagreementIDs: unresolvedDisagreementIDs,
      openReservations: state.openReservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs,
      controlReport: state.controlReport
    )
  }

  private static func replacingTransitions(
    in state: SharedEpisodeControlState,
    with transitions: [SharedEpisodeParkedTransition]
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: state.budgetState,
      selectionDecisions: state.selectionDecisions,
      pendingTransitions: transitions,
      terminal: state.terminal,
      unresolvedDisagreementIDs: state.unresolvedDisagreementIDs,
      openReservations: state.openReservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs,
      controlReport: state.controlReport
    )
  }

  private static func replacingTerminal(
    in state: SharedEpisodeControlState,
    with terminal: SharedEpisodeTerminalRecord
  ) -> SharedEpisodeControlState {
    SharedEpisodeControlState(
      schemaVersion: state.schemaVersion,
      budgetState: state.budgetState,
      selectionDecisions: state.selectionDecisions,
      pendingTransitions: state.pendingTransitions,
      terminal: terminal,
      unresolvedDisagreementIDs: state.unresolvedDisagreementIDs,
      openReservations: state.openReservations,
      completedContinuationIDs: state.completedContinuationIDs,
      completedDistinguishingCheckIDs: state.completedDistinguishingCheckIDs,
      seenPermitIDs: state.seenPermitIDs,
      completedActionIDs: state.completedActionIDs,
      usedExecutorIDs: state.usedExecutorIDs,
      usedRoundIDs: state.usedRoundIDs,
      controlReport: state.controlReport
    )
  }
}

private func inserting(_ value: String, into values: [String]) -> [String] {
  Array(Set(values + [value])).sorted()
}

private func isSortedUnique(_ values: [String]) -> Bool {
  values == values.sorted() && Set(values).count == values.count
}

private func validateCanonicalIdentifiers(
  _ values: [String],
  field: String,
  terminal: Bool = false
) throws {
  guard isSortedUnique(values), values.allSatisfy(isControlIdentifier) else {
    if terminal {
      throw SharedEpisodeMemoryError.invalidTerminal(
        "Поле «\(field)» должно быть отсортированным уникальным списком идентификаторов."
      )
    }
    throw SharedEpisodeMemoryError.invalidControl(
      "Поле «\(field)» должно быть отсортированным уникальным списком идентификаторов."
    )
  }
}

private func isControlSHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}

private func isControlIdentifier(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 128 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    switch scalar.value {
    case 45, 46, 48...57, 65...90, 95, 97...122:
      true
    default:
      false
    }
  }
}
