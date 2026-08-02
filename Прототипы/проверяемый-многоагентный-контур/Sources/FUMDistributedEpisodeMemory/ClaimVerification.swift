import FUMReproducibleMemoryPopulation
import Foundation

public enum SharedEpisodeVerificationOutcome:
  String, Codable, Equatable, Hashable, Sendable
{
  case passed
  case failed
  case inconclusive
}

public enum SharedEpisodeVerificationStanding:
  String, Codable, Equatable, Hashable, Sendable
{
  case externalByObservedFeatures = "external_by_observed_features"
  case selfVerification = "self_verification"
  case correlatedVerification = "correlated_verification"
  case unconfirmedProvenance = "unconfirmed_provenance"
}

public enum SharedEpisodeVerificationCriterionKind:
  String, Codable, Equatable, Hashable, Sendable
{
  case form
  case instrumentalFact = "instrumental_fact"
  case semanticAssessment = "semantic_assessment"
}

public enum SharedEpisodeVerificationEvidenceFinding:
  String, Codable, Equatable, Hashable, Sendable
{
  case supports
  case contradicts
  case insufficient
}

public enum SharedEpisodeVerificationDisagreementKind:
  String, Codable, Equatable, Hashable, Sendable
{
  case claimConflict = "claim_conflict"
  case objection
  case negativeResult = "negative_result"
  case rejectionReason = "rejection_reason"
}

public enum SharedEpisodeVerificationFixture:
  String, CaseIterable, Codable, Equatable, Sendable
{
  case externalPassed = "external_passed"
  case selfPassed = "self_passed"
  case correlatedPassed = "correlated_passed"
  case inconclusive
  case failed
}

public struct SharedEpisodeVerificationCriterion:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let criterionID: String
  public let kind: SharedEpisodeVerificationCriterionKind
  public let statement: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case criterionID = "criterion_id"
    case kind
    case statement
  }

  public init(
    schemaVersion: Int = 1,
    criterionID: String,
    kind: SharedEpisodeVerificationCriterionKind,
    statement: String
  ) {
    self.schemaVersion = schemaVersion
    self.criterionID = criterionID
    self.kind = kind
    self.statement = statement
  }
}

public struct SharedEpisodeVerificationCriteriaDocument:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let criteriaArtifactID: String
  public let criteria: [SharedEpisodeVerificationCriterion]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case criteriaArtifactID = "criteria_artifact_id"
    case criteria
  }

  public init(
    schemaVersion: Int = 1,
    criteriaArtifactID: String,
    criteria: [SharedEpisodeVerificationCriterion]
  ) {
    self.schemaVersion = schemaVersion
    self.criteriaArtifactID = criteriaArtifactID
    self.criteria = criteria
  }
}

public struct SharedEpisodeVerificationPlan:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let verificationPlanArtifactID: String
  public let verifierRoleID: String
  public let criteriaArtifactID: String
  public let criterionIDs: [String]
  public let allowedContributionIDs: [String]
  public let allowedObservationIDs: [String]
  public let forbiddenCorrelationGroupIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case verificationPlanArtifactID = "verification_plan_artifact_id"
    case verifierRoleID = "verifier_role_id"
    case criteriaArtifactID = "criteria_artifact_id"
    case criterionIDs = "criterion_ids"
    case allowedContributionIDs = "allowed_contribution_ids"
    case allowedObservationIDs = "allowed_observation_ids"
    case forbiddenCorrelationGroupIDs = "forbidden_correlation_group_ids"
  }

  public init(
    schemaVersion: Int = 1,
    verificationPlanArtifactID: String,
    verifierRoleID: String,
    criteriaArtifactID: String,
    criterionIDs: [String],
    allowedContributionIDs: [String],
    allowedObservationIDs: [String],
    forbiddenCorrelationGroupIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.verificationPlanArtifactID = verificationPlanArtifactID
    self.verifierRoleID = verifierRoleID
    self.criteriaArtifactID = criteriaArtifactID
    self.criterionIDs = criterionIDs
    self.allowedContributionIDs = allowedContributionIDs
    self.allowedObservationIDs = allowedObservationIDs
    self.forbiddenCorrelationGroupIDs = forbiddenCorrelationGroupIDs
  }
}

public struct SharedEpisodeVerificationClaim:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let claimID: String
  public let contributionID: String
  public let resultSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case claimID = "claim_id"
    case contributionID = "contribution_id"
    case resultSHA256 = "result_sha256"
  }

  public init(
    schemaVersion: Int = 1,
    claimID: String,
    contributionID: String,
    resultSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.claimID = claimID
    self.contributionID = contributionID
    self.resultSHA256 = resultSHA256
  }
}

public struct SharedEpisodeVerificationEvidence:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let evidenceID: String
  public let claimID: String
  public let criterionID: String
  public let observationID: String
  public let observationSHA256: String
  public let resultSHA256: String
  public let finding: SharedEpisodeVerificationEvidenceFinding

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case evidenceID = "evidence_id"
    case claimID = "claim_id"
    case criterionID = "criterion_id"
    case observationID = "observation_id"
    case observationSHA256 = "observation_sha256"
    case resultSHA256 = "result_sha256"
    case finding
  }

  public init(
    schemaVersion: Int = 1,
    evidenceID: String,
    claimID: String,
    criterionID: String,
    observationID: String,
    observationSHA256: String,
    resultSHA256: String,
    finding: SharedEpisodeVerificationEvidenceFinding
  ) {
    self.schemaVersion = schemaVersion
    self.evidenceID = evidenceID
    self.claimID = claimID
    self.criterionID = criterionID
    self.observationID = observationID
    self.observationSHA256 = observationSHA256
    self.resultSHA256 = resultSHA256
    self.finding = finding
  }
}

public struct SharedEpisodeVerificationDisagreement:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let disagreementID: String
  public let claimID: String
  public let kind: SharedEpisodeVerificationDisagreementKind
  public let statement: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case disagreementID = "disagreement_id"
    case claimID = "claim_id"
    case kind
    case statement
  }

  public init(
    schemaVersion: Int = 1,
    disagreementID: String,
    claimID: String,
    kind: SharedEpisodeVerificationDisagreementKind,
    statement: String
  ) {
    self.schemaVersion = schemaVersion
    self.disagreementID = disagreementID
    self.claimID = claimID
    self.kind = kind
    self.statement = statement
  }
}

public struct SharedEpisodeVerificationContent:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let verificationPlanArtifactID: String
  public let criterionIDs: [String]
  public let claims: [SharedEpisodeVerificationClaim]
  public let evidence: [SharedEpisodeVerificationEvidence]
  public let outcome: SharedEpisodeVerificationOutcome
  public let disagreements: [SharedEpisodeVerificationDisagreement]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case verificationPlanArtifactID = "verification_plan_artifact_id"
    case criterionIDs = "criterion_ids"
    case claims
    case evidence
    case outcome
    case disagreements
  }

  public init(
    schemaVersion: Int = 1,
    verificationPlanArtifactID: String,
    criterionIDs: [String],
    claims: [SharedEpisodeVerificationClaim],
    evidence: [SharedEpisodeVerificationEvidence],
    outcome: SharedEpisodeVerificationOutcome,
    disagreements: [SharedEpisodeVerificationDisagreement]
  ) {
    self.schemaVersion = schemaVersion
    self.verificationPlanArtifactID = verificationPlanArtifactID
    self.criterionIDs = criterionIDs
    self.claims = claims
    self.evidence = evidence
    self.outcome = outcome
    self.disagreements = disagreements
  }
}

public struct SharedEpisodeVerificationProvenance:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let recordID: String
  public let executorID: String
  public let roleID: String
  public let verificationPlanArtifactID: String
  public let modelID: String?
  public let providerID: String?
  public let taskSHA256: String
  public let localInputSHA256s: [String]
  public let parentGenerationSHA256: String
  public let resultSHA256: String
  public let correlationLinks: [SharedEpisodeCorrelationLink]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case recordID = "record_id"
    case executorID = "executor_id"
    case roleID = "role_id"
    case verificationPlanArtifactID = "verification_plan_artifact_id"
    case modelID = "model_id"
    case providerID = "provider_id"
    case taskSHA256 = "task_sha256"
    case localInputSHA256s = "local_input_sha256s"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case resultSHA256 = "result_sha256"
    case correlationLinks = "correlation_links"
  }

  public init(
    schemaVersion: Int = 1,
    recordID: String,
    executorID: String,
    roleID: String,
    verificationPlanArtifactID: String,
    modelID: String?,
    providerID: String?,
    taskSHA256: String,
    localInputSHA256s: [String],
    parentGenerationSHA256: String,
    resultSHA256: String,
    correlationLinks: [SharedEpisodeCorrelationLink]
  ) {
    self.schemaVersion = schemaVersion
    self.recordID = recordID
    self.executorID = executorID
    self.roleID = roleID
    self.verificationPlanArtifactID = verificationPlanArtifactID
    self.modelID = modelID
    self.providerID = providerID
    self.taskSHA256 = taskSHA256
    self.localInputSHA256s = localInputSHA256s
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.resultSHA256 = resultSHA256
    self.correlationLinks = correlationLinks
  }

  public func rebinding(
    recordID: String,
    resultSHA256: String
  ) -> SharedEpisodeVerificationProvenance {
    SharedEpisodeVerificationProvenance(
      schemaVersion: schemaVersion,
      recordID: recordID,
      executorID: executorID,
      roleID: roleID,
      verificationPlanArtifactID: verificationPlanArtifactID,
      modelID: modelID,
      providerID: providerID,
      taskSHA256: taskSHA256,
      localInputSHA256s: localInputSHA256s,
      parentGenerationSHA256: parentGenerationSHA256,
      resultSHA256: resultSHA256,
      correlationLinks: correlationLinks
    )
  }

  public func rebinding(roleID: String) -> SharedEpisodeVerificationProvenance {
    SharedEpisodeVerificationProvenance(
      schemaVersion: schemaVersion,
      recordID: recordID,
      executorID: executorID,
      roleID: roleID,
      verificationPlanArtifactID: verificationPlanArtifactID,
      modelID: modelID,
      providerID: providerID,
      taskSHA256: taskSHA256,
      localInputSHA256s: localInputSHA256s,
      parentGenerationSHA256: parentGenerationSHA256,
      resultSHA256: resultSHA256,
      correlationLinks: correlationLinks
    )
  }
}

public struct SharedEpisodeVerificationRecord:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let recordID: String
  public let parentGenerationSHA256: String
  public let verifier: SharedEpisodeContributor
  public let contentSHA256: String
  public let content: SharedEpisodeVerificationContent
  public let provenance: SharedEpisodeVerificationProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case recordID = "record_id"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case verifier
    case contentSHA256 = "content_sha256"
    case content
    case provenance
  }

  public init(
    schemaVersion: Int = 1,
    recordID: String,
    parentGenerationSHA256: String,
    verifier: SharedEpisodeContributor,
    contentSHA256: String,
    content: SharedEpisodeVerificationContent,
    provenance: SharedEpisodeVerificationProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.recordID = recordID
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.verifier = verifier
    self.contentSHA256 = contentSHA256
    self.content = content
    self.provenance = provenance
  }
}

public struct SharedEpisodeVerificationAssessment:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let recordID: String
  public let outcome: SharedEpisodeVerificationOutcome
  public let standing: SharedEpisodeVerificationStanding
  public let externalWeight: Int

  enum CodingKeys: String, CodingKey {
    case recordID = "record_id"
    case outcome
    case standing
    case externalWeight = "external_weight"
  }

  public init(
    recordID: String,
    outcome: SharedEpisodeVerificationOutcome,
    standing: SharedEpisodeVerificationStanding,
    externalWeight: Int
  ) {
    self.recordID = recordID
    self.outcome = outcome
    self.standing = standing
    self.externalWeight = externalWeight
  }
}

public struct SharedEpisodeVerificationReport:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let assessments: [SharedEpisodeVerificationAssessment]
  public let disagreements: [SharedEpisodeVerificationDisagreement]
  public let externalPassedCount: Int
  public let agreementIsEvidence: Bool
  public let semanticTruthProven: Bool
  public let absoluteVerifierIndependenceProven: Bool

  public var assessmentsByRecordID: [String: SharedEpisodeVerificationAssessment] {
    assessments.reduce(into: [:]) { result, assessment in
      if result[assessment.recordID] == nil {
        result[assessment.recordID] = assessment
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case assessments
    case disagreements
    case externalPassedCount = "external_passed_count"
    case agreementIsEvidence = "agreement_is_evidence"
    case semanticTruthProven = "semantic_truth_proven"
    case absoluteVerifierIndependenceProven = "absolute_verifier_independence_proven"
  }

  fileprivate init(
    assessments: [SharedEpisodeVerificationAssessment],
    disagreements: [SharedEpisodeVerificationDisagreement],
    externalPassedCount: Int
  ) {
    schemaVersion = 1
    self.assessments = assessments
    self.disagreements = disagreements
    self.externalPassedCount = externalPassedCount
    agreementIsEvidence = false
    semanticTruthProven = false
    absoluteVerifierIndependenceProven = false
  }
}

public enum SharedEpisodeVerificationValidator {
  public static let maximumVerifications = 256
  public static let maximumClaimsPerVerification = 256
  public static let maximumEvidencePerVerification = 512
  public static let maximumDisagreementsPerVerification = 256
  public static let maximumLocalInputs = 128
  public static let maximumCorrelationLinks = 64

  public static func analyze(
    contributions: [SharedEpisodeContribution],
    verifications: [SharedEpisodeVerificationRecord]
  ) throws -> SharedEpisodeVerificationReport {
    guard verifications.count <= maximumVerifications else {
      throw verificationFailure("Число проверок превышает предел версии 1.")
    }

    var contributionByID: [String: SharedEpisodeContribution] = [:]
    var contributionIndexByID: [String: Int] = [:]
    var observationByID: [String: SharedEpisodeInstrumentObservation] = [:]
    for (index, contribution) in contributions.enumerated() {
      guard contributionByID[contribution.contributionID] == nil else {
        throw verificationFailure("Идентификатор проверяемого вклада повторяется.")
      }
      contributionByID[contribution.contributionID] = contribution
      contributionIndexByID[contribution.contributionID] = index
      for observation in contribution.provenance.instrumentObservations {
        guard observationByID[observation.observationID] == nil else {
          throw verificationFailure(
            "Идентификатор внешнего инструментального наблюдения повторяется."
          )
        }
        observationByID[observation.observationID] = observation
      }
    }

    var verificationIndexByID: [String: Int] = [:]
    var evidenceIDs = Set<String>()
    var disagreementIDs = Set<String>()
    for (index, verification) in verifications.enumerated() {
      guard verificationIndexByID[verification.recordID] == nil else {
        throw verificationFailure("Идентификатор записи проверки повторяется.")
      }
      try validateLocal(
        verification,
        contributionByID: contributionByID,
        observationByID: observationByID
      )
      verificationIndexByID[verification.recordID] = index
      for evidence in verification.content.evidence {
        guard evidenceIDs.insert(evidence.evidenceID).inserted else {
          throw verificationFailure("Идентификатор доказательства повторяется.")
        }
      }
      for disagreement in verification.content.disagreements {
        guard disagreementIDs.insert(disagreement.disagreementID).inserted else {
          throw verificationFailure("Идентификатор разногласия повторяется.")
        }
      }
    }

    var unionFind = SharedEpisodeVerificationUnionFind(
      count: contributions.count + verifications.count
    )
    var declarationByGroupID: [String: SharedEpisodeVerificationCorrelationDeclaration] = [:]
    var groupOwnerByID: [String: Int] = [:]
    var groupIDByBasis: [SharedEpisodeVerificationCorrelationBasis: String] = [:]

    for (index, contribution) in contributions.enumerated() {
      try connect(
        links: contribution.provenance.correlationLinks,
        nodeIndex: index,
        contributionIndexByID: contributionIndexByID,
        contributionByID: contributionByID,
        unionFind: &unionFind,
        declarationByGroupID: &declarationByGroupID,
        groupOwnerByID: &groupOwnerByID,
        groupIDByBasis: &groupIDByBasis
      )
    }
    for (index, verification) in verifications.enumerated() {
      try connect(
        links: verification.provenance.correlationLinks,
        nodeIndex: contributions.count + index,
        contributionIndexByID: contributionIndexByID,
        contributionByID: contributionByID,
        unionFind: &unionFind,
        declarationByGroupID: &declarationByGroupID,
        groupOwnerByID: &groupOwnerByID,
        groupIDByBasis: &groupIDByBasis
      )
    }

    var executorOwnerByID: [String: Int] = [:]
    for (index, contribution) in contributions.enumerated() {
      if let owner = executorOwnerByID[contribution.provenance.executorID] {
        unionFind.union(index, owner)
      } else {
        executorOwnerByID[contribution.provenance.executorID] = index
      }
    }
    for (index, verification) in verifications.enumerated() {
      let nodeIndex = contributions.count + index
      if let owner = executorOwnerByID[verification.provenance.executorID] {
        unionFind.union(nodeIndex, owner)
      } else {
        executorOwnerByID[verification.provenance.executorID] = nodeIndex
      }
      for claim in verification.content.claims {
        guard let targetIndex = contributionIndexByID[claim.contributionID] else {
          continue
        }
        if contributions[targetIndex].provenance.roleID == verification.provenance.roleID {
          unionFind.union(nodeIndex, targetIndex)
        }
      }
    }

    let observedNodes =
      contributions.map {
        SharedEpisodeVerificationObservedNode(
          modelID: $0.provenance.modelID,
          providerID: $0.provenance.providerID,
          correlationLinks: $0.provenance.correlationLinks
        )
      }
      + verifications.map {
        SharedEpisodeVerificationObservedNode(
          modelID: $0.provenance.modelID,
          providerID: $0.provenance.providerID,
          correlationLinks: $0.provenance.correlationLinks
        )
      }
    try validateObservableSharedIdentities(observedNodes)

    var candidates:
      [(
        recordID: String,
        outcome: SharedEpisodeVerificationOutcome,
        standing: SharedEpisodeVerificationStanding,
        componentRoot: Int
      )] = []
    for (index, verification) in verifications.enumerated() {
      let targetIndexes = verification.content.claims.compactMap {
        contributionIndexByID[$0.contributionID]
      }
      let standing: SharedEpisodeVerificationStanding
      if targetIndexes.contains(where: {
        contributions[$0].provenance.executorID == verification.provenance.executorID
          || contributions[$0].provenance.roleID == verification.provenance.roleID
      }) {
        standing = .selfVerification
      } else if contributions.indices.contains(where: {
        unionFind.connected(contributions.count + index, $0)
      }) {
        standing = .correlatedVerification
      } else if verification.provenance.modelID == nil
        || verification.provenance.providerID == nil
      {
        standing = .unconfirmedProvenance
      } else {
        standing = .externalByObservedFeatures
      }
      candidates.append(
        (
          recordID: verification.recordID,
          outcome: verification.content.outcome,
          standing: standing,
          componentRoot: unionFind.find(contributions.count + index)
        )
      )
    }
    candidates.sort { $0.recordID < $1.recordID }
    var creditedComponents = Set<Int>()
    let assessments = candidates.map { candidate in
      let receivesExternalWeight =
        candidate.standing == .externalByObservedFeatures
        && candidate.outcome == .passed
        && creditedComponents.insert(candidate.componentRoot).inserted
      return SharedEpisodeVerificationAssessment(
        recordID: candidate.recordID,
        outcome: candidate.outcome,
        standing: candidate.standing,
        externalWeight: receivesExternalWeight ? 1 : 0
      )
    }

    let disagreements = verifications.flatMap(\.content.disagreements).sorted {
      $0.disagreementID < $1.disagreementID
    }
    return SharedEpisodeVerificationReport(
      assessments: assessments,
      disagreements: disagreements,
      externalPassedCount: assessments.reduce(0) { $0 + $1.externalWeight }
    )
  }

  private static func validateLocal(
    _ verification: SharedEpisodeVerificationRecord,
    contributionByID: [String: SharedEpisodeContribution],
    observationByID: [String: SharedEpisodeInstrumentObservation]
  ) throws {
    let content = verification.content
    let provenance = verification.provenance
    guard verification.schemaVersion == 1,
      isVerificationIdentifier(verification.recordID),
      isVerificationSHA256(verification.parentGenerationSHA256),
      verification.verifier.kind == .author,
      isVerificationIdentifier(verification.verifier.identifier),
      isVerificationSHA256(verification.contentSHA256),
      content.schemaVersion == 1,
      isVerificationIdentifier(content.verificationPlanArtifactID),
      provenance.schemaVersion == 1,
      isVerificationIdentifier(provenance.recordID),
      isVerificationIdentifier(provenance.executorID),
      isVerificationIdentifier(provenance.roleID),
      isVerificationIdentifier(provenance.verificationPlanArtifactID),
      provenance.modelID.map(isVerificationObservedIdentity) ?? true,
      provenance.providerID.map(isVerificationObservedIdentity) ?? true,
      isVerificationSHA256(provenance.taskSHA256),
      isVerificationSHA256(provenance.parentGenerationSHA256),
      isVerificationSHA256(provenance.resultSHA256),
      verification.recordID == provenance.recordID,
      verification.parentGenerationSHA256 == provenance.parentGenerationSHA256,
      verification.verifier.identifier == provenance.executorID,
      content.verificationPlanArtifactID == provenance.verificationPlanArtifactID,
      verification.contentSHA256 == provenance.resultSHA256
    else {
      throw verificationFailure(
        "Запись, проверяющий, содержание и происхождение не образуют одну схему версии 1."
      )
    }
    guard
      verification.contentSHA256
        == CanonicalMemoryJSON.sha256(try content.canonicalJSONData())
    else {
      throw verificationFailure("Содержание проверки не совпадает со своим SHA-256.")
    }

    guard !provenance.localInputSHA256s.isEmpty,
      provenance.localInputSHA256s.count <= maximumLocalInputs,
      provenance.localInputSHA256s.allSatisfy(isVerificationSHA256),
      isUniqueAndSorted(provenance.localInputSHA256s),
      provenance.correlationLinks.count <= maximumCorrelationLinks,
      provenance.correlationLinks
        == provenance.correlationLinks.sorted(by: verificationCorrelationOrder)
    else {
      throw verificationFailure(
        "Локальные входы или группы корреляции проверки нарушают пределы и канонический порядок."
      )
    }
    var linkKeys = Set<String>()
    for link in provenance.correlationLinks {
      guard link.schemaVersion == 1,
        isVerificationIdentifier(link.groupID),
        isVerificationSHA256(link.basisSHA256),
        link.sourceContributionID.map(isVerificationIdentifier) ?? true
      else {
        throw verificationFailure("Группа корреляции проверки нарушает схему версии 1.")
      }
      let key = verificationCorrelationKey(link)
      guard linkKeys.insert(key).inserted else {
        throw verificationFailure("Группа корреляции проверки повторяется.")
      }
    }
    let modelLinks = provenance.correlationLinks.filter { $0.kind == .model }
    let providerLinks = provenance.correlationLinks.filter { $0.kind == .provider }
    let sourceMaterialSHA256s = Set(
      provenance.correlationLinks
        .filter { $0.kind == .sourceMaterial }
        .map(\.basisSHA256)
    )
    guard provenance.modelID == nil || !modelLinks.isEmpty,
      provenance.providerID == nil || !providerLinks.isEmpty,
      sourceMaterialSHA256s == Set(provenance.localInputSHA256s)
    else {
      throw verificationFailure(
        "Наблюдаемая модель, провайдер и локальные входы не имеют полной корреляционной привязки."
      )
    }

    guard !content.criterionIDs.isEmpty,
      isUniqueAndSorted(content.criterionIDs),
      content.criterionIDs.allSatisfy(isVerificationIdentifier),
      !content.claims.isEmpty,
      content.claims.count <= maximumClaimsPerVerification,
      content.claims == content.claims.sorted(by: { $0.claimID < $1.claimID }),
      content.evidence.count <= maximumEvidencePerVerification,
      content.evidence == content.evidence.sorted(by: { $0.evidenceID < $1.evidenceID }),
      content.disagreements.count <= maximumDisagreementsPerVerification,
      content.disagreements
        == content.disagreements.sorted(by: { $0.disagreementID < $1.disagreementID })
    else {
      throw verificationFailure(
        "Критерии, утверждения, доказательства или разногласия не имеют канонического порядка."
      )
    }

    var claimIDs = Set<String>()
    var targetContributionIDs = Set<String>()
    for claim in content.claims {
      guard claim.schemaVersion == 1,
        isVerificationIdentifier(claim.claimID),
        isVerificationIdentifier(claim.contributionID),
        isVerificationSHA256(claim.resultSHA256),
        claimIDs.insert(claim.claimID).inserted,
        targetContributionIDs.insert(claim.contributionID).inserted,
        let contribution = contributionByID[claim.contributionID],
        contribution.contentSHA256 == claim.resultSHA256,
        contribution.provenance.resultSHA256 == claim.resultSHA256
      else {
        throw verificationFailure(
          "Проверяемое утверждение повторяется или не закрепляет точный принятый результат."
        )
      }
    }

    var localEvidenceIDs = Set<String>()
    var evidenceBindings = Set<String>()
    for evidence in content.evidence {
      guard evidence.schemaVersion == 1,
        isVerificationIdentifier(evidence.evidenceID),
        claimIDs.contains(evidence.claimID),
        content.criterionIDs.contains(evidence.criterionID),
        isVerificationIdentifier(evidence.observationID),
        isVerificationSHA256(evidence.observationSHA256),
        isVerificationSHA256(evidence.resultSHA256),
        localEvidenceIDs.insert(evidence.evidenceID).inserted,
        let observation = observationByID[evidence.observationID],
        evidence.observationSHA256
          == CanonicalMemoryJSON.sha256(try observation.canonicalJSONData()),
        evidence.resultSHA256 == observation.resultSHA256
      else {
        throw verificationFailure(
          "Доказательство повторяется либо не закрепляет критерий, утверждение и внешнее наблюдение."
        )
      }
      let binding = [
        evidence.claimID,
        evidence.criterionID,
        evidence.observationID,
        evidence.finding.rawValue,
      ].joined(separator: "\u{0}")
      guard evidenceBindings.insert(binding).inserted else {
        throw verificationFailure("Одинаковое доказательство записано под разными именами.")
      }
    }

    var localDisagreementIDs = Set<String>()
    var disagreementBindings = Set<String>()
    for disagreement in content.disagreements {
      guard disagreement.schemaVersion == 1,
        isVerificationIdentifier(disagreement.disagreementID),
        claimIDs.contains(disagreement.claimID),
        isVerificationStatement(disagreement.statement),
        localDisagreementIDs.insert(disagreement.disagreementID).inserted
      else {
        throw verificationFailure(
          "Разногласие повторяется либо не связано с проверяемым утверждением."
        )
      }
      let binding = [
        disagreement.claimID,
        disagreement.kind.rawValue,
        disagreement.statement,
      ].joined(separator: "\u{0}")
      guard disagreementBindings.insert(binding).inserted else {
        throw verificationFailure("Одинаковое разногласие записано под разными именами.")
      }
    }

    let expectedSupportingBindings = Set(
      content.claims.flatMap { claim in
        content.criterionIDs.map { criterionID in
          "\(claim.claimID)\u{0}\(criterionID)"
        }
      }
    )
    let supportingBindings = Set(
      content.evidence.filter { $0.finding == .supports }.map {
        "\($0.claimID)\u{0}\($0.criterionID)"
      }
    )
    let hasNonSupportingEvidence = content.evidence.contains {
      $0.finding != .supports
    }
    if content.outcome == .passed,
      supportingBindings != expectedSupportingBindings || hasNonSupportingEvidence
    {
      throw verificationFailure(
        "Исход passed не обеспечен достаточным доказательством каждого утверждения."
      )
    }
    if content.outcome == .failed,
      !content.evidence.contains(where: { $0.finding == .contradicts })
    {
      throw verificationFailure(
        "Исход failed не закреплён отрицательным внешним доказательством."
      )
    }
  }

  private static func connect(
    links: [SharedEpisodeCorrelationLink],
    nodeIndex: Int,
    contributionIndexByID: [String: Int],
    contributionByID: [String: SharedEpisodeContribution],
    unionFind: inout SharedEpisodeVerificationUnionFind,
    declarationByGroupID: inout [String: SharedEpisodeVerificationCorrelationDeclaration],
    groupOwnerByID: inout [String: Int],
    groupIDByBasis: inout [SharedEpisodeVerificationCorrelationBasis: String]
  ) throws {
    for link in links {
      let declaration = SharedEpisodeVerificationCorrelationDeclaration(
        kind: link.kind,
        basisSHA256: link.basisSHA256
      )
      if let existing = declarationByGroupID[link.groupID], existing != declaration {
        throw verificationFailure(
          "Одна группа корреляции имеет разные виды или опорные хэши."
        )
      }
      declarationByGroupID[link.groupID] = declaration

      if link.kind.isVerificationSharedObservedSource {
        let basis = SharedEpisodeVerificationCorrelationBasis(
          kind: link.kind,
          basisSHA256: link.basisSHA256
        )
        if let existingGroupID = groupIDByBasis[basis], existingGroupID != link.groupID {
          throw verificationFailure(
            "Один наблюдаемый источник разнесён по разным группам корреляции."
          )
        }
        groupIDByBasis[basis] = link.groupID
      }

      if let owner = groupOwnerByID[link.groupID] {
        unionFind.union(nodeIndex, owner)
      } else {
        groupOwnerByID[link.groupID] = nodeIndex
      }

      switch link.kind {
      case .model, .provider, .sourceMaterial, .systemTemplate:
        guard link.sourceContributionID == nil else {
          throw verificationFailure(
            "Группа общего источника не должна подменяться направленным ребром."
          )
        }
      case .copy, .parentResult, .derivedAnswer:
        guard let sourceID = link.sourceContributionID,
          let sourceIndex = contributionIndexByID[sourceID],
          let source = contributionByID[sourceID],
          sourceIndex != nodeIndex,
          link.basisSHA256 == source.provenance.resultSHA256
        else {
          throw verificationFailure(
            "Направленная группа корреляции не закрепляет другой принятый вклад."
          )
        }
        unionFind.union(nodeIndex, sourceIndex)
      }
    }
  }

  private static func validateObservableSharedIdentities(
    _ nodes: [SharedEpisodeVerificationObservedNode]
  ) throws {
    for leftIndex in nodes.indices {
      for rightIndex in nodes.indices where rightIndex > leftIndex {
        let left = nodes[leftIndex]
        let right = nodes[rightIndex]
        if let leftModel = left.modelID,
          leftModel == right.modelID,
          !shareVerificationLink(left, right, kind: .model)
        {
          throw verificationFailure(
            "Общая наблюдаемая модель не отражена одной группой корреляции."
          )
        }
        if let leftProvider = left.providerID,
          leftProvider == right.providerID,
          !shareVerificationLink(left, right, kind: .provider)
        {
          throw verificationFailure(
            "Общий наблюдаемый поставщик не отражён одной группой корреляции."
          )
        }
      }
    }
  }
}

private struct SharedEpisodeVerificationCorrelationDeclaration: Equatable {
  let kind: SharedEpisodeCorrelationKind
  let basisSHA256: String
}

private struct SharedEpisodeVerificationCorrelationBasis: Hashable {
  let kind: SharedEpisodeCorrelationKind
  let basisSHA256: String
}

private struct SharedEpisodeVerificationObservedNode {
  let modelID: String?
  let providerID: String?
  let correlationLinks: [SharedEpisodeCorrelationLink]
}

private struct SharedEpisodeVerificationUnionFind {
  private var parents: [Int]
  private var ranks: [Int]

  init(count: Int) {
    parents = Array(0..<count)
    ranks = Array(repeating: 0, count: count)
  }

  mutating func find(_ index: Int) -> Int {
    var root = index
    while parents[root] != root {
      root = parents[root]
    }
    var cursor = index
    while parents[cursor] != cursor {
      let next = parents[cursor]
      parents[cursor] = root
      cursor = next
    }
    return root
  }

  mutating func union(_ left: Int, _ right: Int) {
    let leftRoot = find(left)
    let rightRoot = find(right)
    guard leftRoot != rightRoot else { return }
    if ranks[leftRoot] < ranks[rightRoot] {
      parents[leftRoot] = rightRoot
    } else if ranks[leftRoot] > ranks[rightRoot] {
      parents[rightRoot] = leftRoot
    } else {
      parents[rightRoot] = leftRoot
      ranks[leftRoot] += 1
    }
  }

  mutating func connected(_ left: Int, _ right: Int) -> Bool {
    find(left) == find(right)
  }
}

extension SharedEpisodeCorrelationKind {
  fileprivate var isVerificationSharedObservedSource: Bool {
    switch self {
    case .model, .provider, .sourceMaterial, .systemTemplate:
      true
    case .parentResult, .copy, .derivedAnswer:
      false
    }
  }
}

private func shareVerificationLink(
  _ left: SharedEpisodeVerificationObservedNode,
  _ right: SharedEpisodeVerificationObservedNode,
  kind: SharedEpisodeCorrelationKind
) -> Bool {
  let leftLinks = left.correlationLinks.filter { $0.kind == kind }
  return right.correlationLinks.contains { rightLink in
    rightLink.kind == kind
      && leftLinks.contains {
        $0.groupID == rightLink.groupID && $0.basisSHA256 == rightLink.basisSHA256
      }
  }
}

private func verificationCorrelationOrder(
  _ left: SharedEpisodeCorrelationLink,
  _ right: SharedEpisodeCorrelationLink
) -> Bool {
  if left.groupID != right.groupID { return left.groupID < right.groupID }
  if left.kind.rawValue != right.kind.rawValue {
    return left.kind.rawValue < right.kind.rawValue
  }
  if left.basisSHA256 != right.basisSHA256 {
    return left.basisSHA256 < right.basisSHA256
  }
  return (left.sourceContributionID ?? "") < (right.sourceContributionID ?? "")
}

private func verificationCorrelationKey(_ link: SharedEpisodeCorrelationLink) -> String {
  [
    link.groupID,
    link.kind.rawValue,
    link.basisSHA256,
    link.sourceContributionID ?? "",
  ].joined(separator: "\u{0}")
}

private func isUniqueAndSorted(_ values: [String]) -> Bool {
  values == values.sorted() && Set(values).count == values.count
}

private func verificationFailure(_ message: String) -> SharedEpisodeMemoryError {
  .invalidVerification(message)
}

private func isVerificationSHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}

private func isVerificationIdentifier(_ value: String) -> Bool {
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

private func isVerificationObservedIdentity(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 256 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    scalar.value >= 0x20 && scalar.value != 0x7f
      && !(0xfdd0...0xfdef).contains(scalar.value)
      && scalar.value & 0xffff != 0xfffe
      && scalar.value & 0xffff != 0xffff
  }
}

private func isVerificationStatement(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 4_096 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    scalar.value >= 0x20 || scalar.value == 0x0a || scalar.value == 0x0d
  }
}
