import CryptoKit
import Foundation

public enum DurableForkOperationOutcome: String, Codable, Equatable, Sendable {
  case registered
  case candidatePublished = "candidate_published"
  case handoffAccepted = "handoff_accepted"
  case synchronized
  case parentUpdated = "parent_updated"
  case restored
  case remoteMismatch = "remote_mismatch"
  case publicationBoundaryRejected = "publication_boundary_rejected"
  case oidMismatch = "oid_mismatch"
  case conflict
  case recursiveInitializationForbidden = "recursive_initialization_forbidden"
  case invalidComposition = "invalid_composition"
  case invalidRequest = "invalid_request"
}

public struct DurableForkNextStepCandidate: Equatable, Sendable {
  public let stepID: String
  public let cardID: String
  public let cardContentSHA256: String
  public let dispatch: String
  public let requiresCompletedCardIDs: [String]
}

public struct DurableForkNextStepRecord: Equatable, Sendable {
  public let schemaVersion: Int
  public let branchRef: String
  public let state: String
  public let projectPath: String
  public let candidates: [DurableForkNextStepCandidate]

  public func canonicalMarkdownData() -> Data {
    var lines = [
      "+++",
      "schema_version = \(schemaVersion)",
      "branch_ref = \"\(DurableForkValidation.tomlString(branchRef))\"",
      "state = \"\(DurableForkValidation.tomlString(state))\"",
      "project_path = \"\(DurableForkValidation.tomlString(projectPath))\"",
    ]
    for candidate in candidates {
      let dependencies = candidate.requiresCompletedCardIDs
        .map { "\"\(DurableForkValidation.tomlString($0))\"" }
        .joined(separator: ", ")
      lines.append(contentsOf: [
        "",
        "[[candidates]]",
        "step_id = \"\(DurableForkValidation.tomlString(candidate.stepID))\"",
        "dispatch = \"\(DurableForkValidation.tomlString(candidate.dispatch))\"",
        "card_id = \"\(DurableForkValidation.tomlString(candidate.cardID))\"",
        "card_content_sha256 = \"\(candidate.cardContentSHA256)\"",
        "requires_completed_card_ids = [\(dependencies)]",
      ])
    }
    lines.append(contentsOf: [
      "+++",
      "# Выбирать следующий шаг специализированного подузла",
      "",
      "Рабочий набор хранит один проверяемый автоматический кандидат своей ветки.",
      "",
    ])
    return Data(lines.joined(separator: "\n").utf8)
  }
}

public struct DurableForkSpecializationPassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let nodeID: String
  public let repositoryID: String
  public let upstreamRepositoryID: String
  public let assemblyRepositoryID: String
  public let liveRef: String
  public let upstreamRef: String
  public let rulesPath: String
  public let queueRefNamespace: String
  public let queueBootstrapScriptPath: String
  public let nextStepValidatorPath: String
  public let nextStepRecordPath: String
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case nodeID = "node_id"
    case repositoryID = "repository_id"
    case upstreamRepositoryID = "upstream_repository_id"
    case assemblyRepositoryID = "assembly_repository_id"
    case liveRef = "live_ref"
    case upstreamRef = "upstream_ref"
    case rulesPath = "rules_path"
    case queueRefNamespace = "queue_ref_namespace"
    case queueBootstrapScriptPath = "queue_bootstrap_script_path"
    case nextStepValidatorPath = "next_step_validator_path"
    case nextStepRecordPath = "next_step_record_path"
    case accessLevel = "access_level"
    case publicationBoundary = "publication_boundary"
  }

  public func canonicalJSONData() throws -> Data { try DurableForkJSON.encode(self) }
}

public struct DurableForkRegistrationPassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let nodeID: String
  public let repositoryID: String
  public let upstreamRepositoryID: String
  public let assemblyRepositoryID: String
  public let upstreamBaseOID: String
  public let forkOID: String
  public let forkLiveRef: String
  public let assemblyBaseOID: String
  public let assemblyOID: String
  public let assemblyRef: String
  public let submodulePath: String
  public let gitlinkOID: String
  public let specializationPassportSHA256: String
  public let rulesSHA256: String
  public let queueRefNamespace: String
  public let queueBootstrapScriptPath: String
  public let queueBootstrapScriptSHA256: String
  public let nextStepValidatorPath: String
  public let nextStepValidatorSHA256: String
  public let nextStepRecordPath: String
  public let nextStepRecordSHA256: String
  public let projectPath: String
  public let nextStepCardPath: String
  public let nextStepCardID: String
  public let nextStepCardContentSHA256: String
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case nodeID = "node_id"
    case repositoryID = "repository_id"
    case upstreamRepositoryID = "upstream_repository_id"
    case assemblyRepositoryID = "assembly_repository_id"
    case upstreamBaseOID = "upstream_base_oid"
    case forkOID = "fork_oid"
    case forkLiveRef = "fork_live_ref"
    case assemblyBaseOID = "assembly_base_oid"
    case assemblyOID = "assembly_oid"
    case assemblyRef = "assembly_ref"
    case submodulePath = "submodule_path"
    case gitlinkOID = "gitlink_oid"
    case specializationPassportSHA256 = "specialization_passport_sha256"
    case rulesSHA256 = "rules_sha256"
    case queueRefNamespace = "queue_ref_namespace"
    case queueBootstrapScriptPath = "queue_bootstrap_script_path"
    case queueBootstrapScriptSHA256 = "queue_bootstrap_script_sha256"
    case nextStepValidatorPath = "next_step_validator_path"
    case nextStepValidatorSHA256 = "next_step_validator_sha256"
    case nextStepRecordPath = "next_step_record_path"
    case nextStepRecordSHA256 = "next_step_record_sha256"
    case projectPath = "project_path"
    case nextStepCardPath = "next_step_card_path"
    case nextStepCardID = "next_step_card_id"
    case nextStepCardContentSHA256 = "next_step_card_content_sha256"
    case accessLevel = "access_level"
    case publicationBoundary = "publication_boundary"
  }

  public func canonicalJSONData() throws -> Data { try DurableForkJSON.encode(self) }
}

public struct DurableForkFileCheck: Codable, Equatable, Sendable {
  public let checkID: String
  public let path: String
  public let expectedSHA256: String

  public init(checkID: String, path: String, expectedSHA256: String) {
    self.checkID = checkID
    self.path = path
    self.expectedSHA256 = expectedSHA256
  }

  enum CodingKeys: String, CodingKey {
    case checkID = "check_id"
    case path
    case expectedSHA256 = "expected_sha256"
  }
}

public struct DurableForkUpstreamHandoffPassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let handoffID: String
  public let nodeID: String
  public let sourceRepositoryID: String
  public let sourceCommitOID: String
  public let sourceParentOID: String
  public let sourcePassportSHA256: String
  public let targetRepositoryID: String
  public let targetRef: String
  public let parentBaseOID: String
  public let changeScope: [String]
  public let checks: [DurableForkFileCheck]
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel
  public let integrationTreeOID: String
  public let integrationOID: String
  public let state: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case handoffID = "handoff_id"
    case nodeID = "node_id"
    case sourceRepositoryID = "source_repository_id"
    case sourceCommitOID = "source_commit_oid"
    case sourceParentOID = "source_parent_oid"
    case sourcePassportSHA256 = "source_passport_sha256"
    case targetRepositoryID = "target_repository_id"
    case targetRef = "target_ref"
    case parentBaseOID = "parent_base_oid"
    case changeScope = "change_scope"
    case checks
    case accessLevel = "access_level"
    case publicationBoundary = "publication_boundary"
    case integrationTreeOID = "integration_tree_oid"
    case integrationOID = "integration_oid"
    case state
  }

  public func canonicalJSONData() throws -> Data { try DurableForkJSON.encode(self) }
}

public struct DurableForkParentUpdatePassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let updateID: String
  public let assemblyRepositoryID: String
  public let assemblyRef: String
  public let parentBaseOID: String
  public let parentOID: String
  public let submodulePath: String
  public let previousGitlinkOID: String
  public let gitlinkOID: String
  public let childRepositoryID: String
  public let childLiveRef: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case updateID = "update_id"
    case assemblyRepositoryID = "assembly_repository_id"
    case assemblyRef = "assembly_ref"
    case parentBaseOID = "parent_base_oid"
    case parentOID = "parent_oid"
    case submodulePath = "submodule_path"
    case previousGitlinkOID = "previous_gitlink_oid"
    case gitlinkOID = "gitlink_oid"
    case childRepositoryID = "child_repository_id"
    case childLiveRef = "child_live_ref"
  }

  public func canonicalJSONData() throws -> Data { try DurableForkJSON.encode(self) }
}

public struct DurableForkRegistrationRequest: Sendable {
  public let nodeID: String
  public let forkRepositoryID: String
  public let upstreamRepositoryID: String
  public let assemblyRepositoryID: String
  public let coreBareURL: URL
  public let forkBareURL: URL
  public let assemblyBareURL: URL
  public let liveCloneURL: URL
  public let runtimeRootURL: URL
  public let snapshotRootURL: URL
  public let upstreamRef: String
  public let liveRef: String
  public let assemblyRef: String
  public let expectedUpstreamOID: String
  public let expectedAssemblyOID: String
  public let submodulePath: String
  public let submoduleURL: String
  public let rulesPath: String
  public let rulesData: Data
  public let queueRefNamespace: String
  public let queueBootstrapScriptPath: String
  public let queueBootstrapScriptSHA256: String
  public let nextStepValidatorPath: String
  public let nextStepValidatorSHA256: String
  public let nextStepRecordPath: String
  public let projectPath: String
  public let nextStepCardPath: String
  public let nextStepCardID: String
  public let nextStepID: String
  public let nextStepCardData: Data
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel

  public init(
    nodeID: String,
    forkRepositoryID: String,
    upstreamRepositoryID: String,
    assemblyRepositoryID: String,
    coreBareURL: URL,
    forkBareURL: URL,
    assemblyBareURL: URL,
    liveCloneURL: URL,
    runtimeRootURL: URL,
    snapshotRootURL: URL,
    upstreamRef: String,
    liveRef: String,
    assemblyRef: String,
    expectedUpstreamOID: String,
    expectedAssemblyOID: String,
    submodulePath: String,
    submoduleURL: String,
    rulesPath: String,
    rulesData: Data,
    queueRefNamespace: String,
    queueBootstrapScriptPath: String,
    queueBootstrapScriptSHA256: String,
    nextStepValidatorPath: String,
    nextStepValidatorSHA256: String,
    nextStepRecordPath: String,
    projectPath: String,
    nextStepCardPath: String,
    nextStepCardID: String,
    nextStepID: String,
    nextStepCardData: Data,
    accessLevel: RepositoryCompositionAccessLevel,
    publicationBoundary: RepositoryCompositionAccessLevel
  ) {
    self.nodeID = nodeID
    self.forkRepositoryID = forkRepositoryID
    self.upstreamRepositoryID = upstreamRepositoryID
    self.assemblyRepositoryID = assemblyRepositoryID
    self.coreBareURL = coreBareURL
    self.forkBareURL = forkBareURL
    self.assemblyBareURL = assemblyBareURL
    self.liveCloneURL = liveCloneURL
    self.runtimeRootURL = runtimeRootURL
    self.snapshotRootURL = snapshotRootURL
    self.upstreamRef = upstreamRef
    self.liveRef = liveRef
    self.assemblyRef = assemblyRef
    self.expectedUpstreamOID = expectedUpstreamOID
    self.expectedAssemblyOID = expectedAssemblyOID
    self.submodulePath = submodulePath
    self.submoduleURL = submoduleURL
    self.rulesPath = rulesPath
    self.rulesData = rulesData
    self.queueRefNamespace = queueRefNamespace
    self.queueBootstrapScriptPath = queueBootstrapScriptPath
    self.queueBootstrapScriptSHA256 = queueBootstrapScriptSHA256
    self.nextStepValidatorPath = nextStepValidatorPath
    self.nextStepValidatorSHA256 = nextStepValidatorSHA256
    self.nextStepRecordPath = nextStepRecordPath
    self.projectPath = projectPath
    self.nextStepCardPath = nextStepCardPath
    self.nextStepCardID = nextStepCardID
    self.nextStepID = nextStepID
    self.nextStepCardData = nextStepCardData
    self.accessLevel = accessLevel
    self.publicationBoundary = publicationBoundary
  }
}

public struct DurableForkNodeContext: Sendable {
  public let nodeID: String
  public let forkRepositoryID: String
  public let upstreamRepositoryID: String
  public let assemblyRepositoryID: String
  public let coreBareURL: URL
  public let forkBareURL: URL
  public let assemblyBareURL: URL
  public let liveCloneURL: URL
  public let runtimeRootURL: URL
  public let snapshotURL: URL
  public let upstreamRef: String
  public let liveRef: String
  public let assemblyRef: String
  public let upstreamOID: String
  public let forkOID: String
  public let assemblyOID: String
  public let submodulePath: String
  public let submoduleURL: String
  public let gitlinkOID: String
  public let rulesPath: String
  public let liveQueueRef: String
  public let queueRefNamespace: String
  public let queueBootstrapScriptPath: String
  public let nextStepValidatorPath: String
  public let nextStepRecordPath: String
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel
  public let registrationPassport: DurableForkRegistrationPassport
  public let registrationPassportCanonicalJSON: Data
  public let compositionPassportCanonicalJSON: Data
  public let compositionReport: RepositoryCompositionReport

  func updating(
    upstreamOID: String? = nil,
    forkOID: String? = nil,
    assemblyOID: String? = nil,
    gitlinkOID: String? = nil,
    snapshotURL: URL? = nil,
    compositionPassportCanonicalJSON: Data? = nil,
    compositionReport: RepositoryCompositionReport? = nil
  ) -> DurableForkNodeContext {
    DurableForkNodeContext(
      nodeID: nodeID,
      forkRepositoryID: forkRepositoryID,
      upstreamRepositoryID: upstreamRepositoryID,
      assemblyRepositoryID: assemblyRepositoryID,
      coreBareURL: coreBareURL,
      forkBareURL: forkBareURL,
      assemblyBareURL: assemblyBareURL,
      liveCloneURL: liveCloneURL,
      runtimeRootURL: runtimeRootURL,
      snapshotURL: snapshotURL ?? self.snapshotURL,
      upstreamRef: upstreamRef,
      liveRef: liveRef,
      assemblyRef: assemblyRef,
      upstreamOID: upstreamOID ?? self.upstreamOID,
      forkOID: forkOID ?? self.forkOID,
      assemblyOID: assemblyOID ?? self.assemblyOID,
      submodulePath: submodulePath,
      submoduleURL: submoduleURL,
      gitlinkOID: gitlinkOID ?? self.gitlinkOID,
      rulesPath: rulesPath,
      liveQueueRef: liveQueueRef,
      queueRefNamespace: queueRefNamespace,
      queueBootstrapScriptPath: queueBootstrapScriptPath,
      nextStepValidatorPath: nextStepValidatorPath,
      nextStepRecordPath: nextStepRecordPath,
      accessLevel: accessLevel,
      publicationBoundary: publicationBoundary,
      registrationPassport: registrationPassport,
      registrationPassportCanonicalJSON: registrationPassportCanonicalJSON,
      compositionPassportCanonicalJSON: compositionPassportCanonicalJSON
        ?? self.compositionPassportCanonicalJSON,
      compositionReport: compositionReport ?? self.compositionReport
    )
  }
}

public struct DurableForkRegistrationResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let node: DurableForkNodeContext?
  public let registrationPassportSHA256: String?
  public let compositionViolations: [RepositoryCompositionViolation]

  fileprivate init(
    outcome: DurableForkOperationOutcome,
    node: DurableForkNodeContext? = nil,
    compositionViolations: [RepositoryCompositionViolation] = []
  ) {
    self.outcome = outcome
    self.node = node
    self.compositionViolations = compositionViolations
    registrationPassportSHA256 = node.map {
      DurableForkJSON.sha256($0.registrationPassportCanonicalJSON)
    }
  }
}

public struct DurableForkCandidateRequest: Sendable {
  public let node: DurableForkNodeContext
  public let workPackageData: Data
  public let executionRootURL: URL
  public let integrationRootURL: URL
  public let episodeID: String
  public let stepGenerationID: String
  public let cardID: String
  public let stepID: String
  public let runID: String
  public let attemptID: String
  public let ownerID: String
  public let commitMessage: String
  public let integrationCommitMessage: String
  public let writes: [WritingSubnodeWrite]
  public let checkIDs: [String]

  public init(
    node: DurableForkNodeContext,
    workPackageData: Data,
    executionRootURL: URL,
    integrationRootURL: URL,
    episodeID: String,
    stepGenerationID: String,
    cardID: String,
    stepID: String,
    runID: String,
    attemptID: String,
    ownerID: String,
    commitMessage: String,
    integrationCommitMessage: String,
    writes: [WritingSubnodeWrite],
    checkIDs: [String]
  ) {
    self.node = node
    self.workPackageData = workPackageData
    self.executionRootURL = executionRootURL
    self.integrationRootURL = integrationRootURL
    self.episodeID = episodeID
    self.stepGenerationID = stepGenerationID
    self.cardID = cardID
    self.stepID = stepID
    self.runID = runID
    self.attemptID = attemptID
    self.ownerID = ownerID
    self.commitMessage = commitMessage
    self.integrationCommitMessage = integrationCommitMessage
    self.writes = writes
    self.checkIDs = checkIDs
  }
}

public struct DurableForkCandidateResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let node: DurableForkNodeContext?
  public let candidate: WritingSubnodeExecutionResult?
  public let integration: CandidateCommitIntegrationResult?
}

public struct DurableForkHandoffRequest: Sendable {
  public let node: DurableForkNodeContext
  public let handoffID: String
  public let executionRootURL: URL
  public let runID: String
  public let expectedCandidateOID: String
  public let expectedCandidatePassportSHA256: String
  public let integrationRootURL: URL
  public let expectedUpstreamOID: String
  public let changeScope: [String]
  public let checks: [DurableForkFileCheck]
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel
  public let commitMessage: String

  public init(
    node: DurableForkNodeContext,
    handoffID: String,
    executionRootURL: URL,
    runID: String,
    expectedCandidateOID: String,
    expectedCandidatePassportSHA256: String,
    integrationRootURL: URL,
    expectedUpstreamOID: String,
    changeScope: [String],
    checks: [DurableForkFileCheck],
    accessLevel: RepositoryCompositionAccessLevel,
    publicationBoundary: RepositoryCompositionAccessLevel,
    commitMessage: String
  ) {
    self.node = node
    self.handoffID = handoffID
    self.executionRootURL = executionRootURL
    self.runID = runID
    self.expectedCandidateOID = expectedCandidateOID
    self.expectedCandidatePassportSHA256 = expectedCandidatePassportSHA256
    self.integrationRootURL = integrationRootURL
    self.expectedUpstreamOID = expectedUpstreamOID
    self.changeScope = changeScope
    self.checks = checks
    self.accessLevel = accessLevel
    self.publicationBoundary = publicationBoundary
    self.commitMessage = commitMessage
  }
}

public struct DurableForkHandoffResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let node: DurableForkNodeContext?
  public let passport: DurableForkUpstreamHandoffPassport?
  public let passportCanonicalJSON: Data?
  public let passportSHA256: String?

  fileprivate init(
    outcome: DurableForkOperationOutcome,
    node: DurableForkNodeContext? = nil,
    passport: DurableForkUpstreamHandoffPassport? = nil
  ) {
    self.outcome = outcome
    self.node = node
    self.passport = passport
    passportCanonicalJSON = try? passport?.canonicalJSONData()
    passportSHA256 = passportCanonicalJSON.map(DurableForkJSON.sha256)
  }
}

public struct DurableForkSyncRequest: Sendable {
  public let node: DurableForkNodeContext
  public let syncID: String
  public let syncRootURL: URL
  public let expectedForkOID: String
  public let expectedUpstreamOID: String
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel
  public let commitMessage: String

  public init(
    node: DurableForkNodeContext,
    syncID: String,
    syncRootURL: URL,
    expectedForkOID: String,
    expectedUpstreamOID: String,
    accessLevel: RepositoryCompositionAccessLevel,
    publicationBoundary: RepositoryCompositionAccessLevel,
    commitMessage: String
  ) {
    self.node = node
    self.syncID = syncID
    self.syncRootURL = syncRootURL
    self.expectedForkOID = expectedForkOID
    self.expectedUpstreamOID = expectedUpstreamOID
    self.accessLevel = accessLevel
    self.publicationBoundary = publicationBoundary
    self.commitMessage = commitMessage
  }
}

public struct DurableForkSyncResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let node: DurableForkNodeContext?
  public let syncOID: String?
}

public struct DurableForkParentUpdateRequest: Sendable {
  public let node: DurableForkNodeContext
  public let updateID: String
  public let updateRootURL: URL
  public let snapshotRootURL: URL
  public let expectedParentOID: String
  public let expectedPreviousGitlinkOID: String
  public let gitlinkOID: String
  public let commitMessage: String

  public init(
    node: DurableForkNodeContext,
    updateID: String,
    updateRootURL: URL,
    snapshotRootURL: URL,
    expectedParentOID: String,
    expectedPreviousGitlinkOID: String,
    gitlinkOID: String,
    commitMessage: String
  ) {
    self.node = node
    self.updateID = updateID
    self.updateRootURL = updateRootURL
    self.snapshotRootURL = snapshotRootURL
    self.expectedParentOID = expectedParentOID
    self.expectedPreviousGitlinkOID = expectedPreviousGitlinkOID
    self.gitlinkOID = gitlinkOID
    self.commitMessage = commitMessage
  }
}

public struct DurableForkParentUpdateResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let node: DurableForkNodeContext?
  public let passport: DurableForkParentUpdatePassport?
  public let passportCanonicalJSON: Data?
  public let passportSHA256: String?

  fileprivate init(
    outcome: DurableForkOperationOutcome,
    node: DurableForkNodeContext? = nil,
    passport: DurableForkParentUpdatePassport? = nil
  ) {
    self.outcome = outcome
    self.node = node
    self.passport = passport
    passportCanonicalJSON = try? passport?.canonicalJSONData()
    passportSHA256 = passportCanonicalJSON.map(DurableForkJSON.sha256)
  }
}

public struct DurableForkRestoreRequest: Sendable {
  public let node: DurableForkNodeContext
  public let destinationURL: URL
  public let recursiveInitialization: Bool

  public init(
    node: DurableForkNodeContext,
    destinationURL: URL,
    recursiveInitialization: Bool = false
  ) {
    self.node = node
    self.destinationURL = destinationURL
    self.recursiveInitialization = recursiveInitialization
  }
}

public struct DurableForkRestoreResult: Sendable {
  public let outcome: DurableForkOperationOutcome
  public let checkoutURL: URL?
  public let headOID: String?
  public let snapshotIsDetached: Bool?
  public let snapshotIsClean: Bool?
  public let liveRef: String?
  public let nextStepRecordSHA256: String?
  public let nextStepValidationState: String?
  public let queueValidationState: String?
  public let queueRef: String?

  fileprivate init(
    outcome: DurableForkOperationOutcome,
    checkoutURL: URL?,
    headOID: String?,
    snapshotIsDetached: Bool?,
    snapshotIsClean: Bool?,
    liveRef: String?,
    nextStepRecordSHA256: String?,
    nextStepValidationState: String? = nil,
    queueValidationState: String? = nil,
    queueRef: String? = nil
  ) {
    self.outcome = outcome
    self.checkoutURL = checkoutURL
    self.headOID = headOID
    self.snapshotIsDetached = snapshotIsDetached
    self.snapshotIsClean = snapshotIsClean
    self.liveRef = liveRef
    self.nextStepRecordSHA256 = nextStepRecordSHA256
    self.nextStepValidationState = nextStepValidationState
    self.queueValidationState = queueValidationState
    self.queueRef = queueRef
  }
}

public struct DurableForkSubnodeRuntime: Sendable {
  private let writingExecutor: WritingSubnodeExecutor
  private let candidateIntegrator: CandidateCommitIntegrator
  private let git = CandidateIntegrationGit()

  public init(
    writingCheckRegistry: WritingSubnodeCheckRegistry = WritingSubnodeCheckRegistry(),
    integrationCheckRegistry: CandidateIntegrationCheckRegistry =
      CandidateIntegrationCheckRegistry()
  ) {
    writingExecutor = WritingSubnodeExecutor(checkRegistry: writingCheckRegistry)
    candidateIntegrator = CandidateCommitIntegrator(checkRegistry: integrationCheckRegistry)
  }
}

extension DurableForkSubnodeRuntime {
  public func register(
    _ request: DurableForkRegistrationRequest
  ) throws -> DurableForkRegistrationResult {
    guard DurableForkValidation.isIdentifier(request.nodeID),
      DurableForkValidation.isIdentifier(request.forkRepositoryID),
      DurableForkValidation.isIdentifier(request.upstreamRepositoryID),
      DurableForkValidation.isIdentifier(request.assemblyRepositoryID),
      DurableForkValidation.isOID(request.expectedUpstreamOID),
      DurableForkValidation.isOID(request.expectedAssemblyOID),
      DurableForkValidation.isBranchRef(request.upstreamRef),
      DurableForkValidation.isBranchRef(request.liveRef),
      DurableForkValidation.isBranchRef(request.assemblyRef),
      request.queueRefNamespace == "refs/fum/worktree-task-queues",
      DurableForkValidation.isRelativePath(request.submodulePath),
      DurableForkValidation.isRelativePath(request.rulesPath),
      request.rulesPath == "AGENTS.md",
      DurableForkValidation.isRelativePath(request.queueBootstrapScriptPath),
      DurableForkValidation.isSHA256(request.queueBootstrapScriptSHA256),
      DurableForkValidation.isRelativePath(request.nextStepValidatorPath),
      DurableForkValidation.isSHA256(request.nextStepValidatorSHA256),
      DurableForkValidation.isRelativePath(request.nextStepRecordPath),
      DurableForkValidation.isRelativePath(request.nextStepCardPath),
      DurableForkValidation.isRelativePath(request.projectPath),
      request.nextStepRecordPath.hasPrefix("Планирование/следующие-шаги-веток/"),
      request.nextStepCardPath.hasPrefix("Планирование/карточки-шагов/🟡-"),
      DurableForkValidation.isStepCardID(request.nextStepCardID),
      DurableForkValidation.isVersionedStepID(request.nextStepID),
      request.nextStepCardPath.split(separator: "/").last?
        .hasPrefix("🟡-\(request.nextStepCardID)-") == true,
      request.submoduleURL.hasPrefix("../"),
      !request.rulesData.isEmpty,
      !request.nextStepCardData.isEmpty,
      DurableForkValidation.isCanonicalUnrecenciedMarkdown(request.nextStepCardData),
      request.accessLevel == .public,
      request.publicationBoundary == .public,
      request.forkRepositoryID != request.upstreamRepositoryID,
      request.forkRepositoryID != request.assemblyRepositoryID,
      request.upstreamRepositoryID != request.assemblyRepositoryID
    else {
      return DurableForkRegistrationResult(outcome: .invalidRequest)
    }

    let core = request.coreBareURL.standardizedFileURL.resolvingSymlinksInPath()
    let assembly = request.assemblyBareURL.standardizedFileURL.resolvingSymlinksInPath()
    let fork = request.forkBareURL.standardizedFileURL
    let live = request.liveCloneURL.standardizedFileURL
    let runtimeRoot = request.runtimeRootURL.standardizedFileURL
    let snapshotRoot = request.snapshotRootURL.standardizedFileURL
    guard try DurableForkValidation.isBare(core, git: git),
      try DurableForkValidation.isBare(assembly, git: git),
      try DurableForkValidation.refOID(request.upstreamRef, repository: core, git: git)
        == request.expectedUpstreamOID,
      try DurableForkValidation.refOID(request.assemblyRef, repository: assembly, git: git)
        == request.expectedAssemblyOID,
      DurableForkJSON.sha256(
        try git.data(
          [
            "cat-file", "blob",
            "\(request.expectedUpstreamOID):\(request.queueBootstrapScriptPath)",
          ],
          at: core)) == request.queueBootstrapScriptSHA256,
      DurableForkJSON.sha256(
        try git.data(
          [
            "cat-file", "blob",
            "\(request.expectedUpstreamOID):\(request.nextStepValidatorPath)",
          ],
          at: core)) == request.nextStepValidatorSHA256,
      !FileManager.default.fileExists(atPath: fork.path),
      !FileManager.default.fileExists(atPath: live.path),
      !FileManager.default.fileExists(atPath: snapshotRoot.path)
    else {
      return DurableForkRegistrationResult(outcome: .oidMismatch)
    }

    try DurableForkValidation.ensureDirectory(runtimeRoot)
    try DurableForkValidation.requireSeparated(
      [core, assembly, fork, live, runtimeRoot, snapshotRoot]
    )

    _ = try git.data(
      [
        "clone", "--quiet", "--bare", "--no-local", "--no-hardlinks", "--",
        core.path, fork.path,
      ],
      at: runtimeRoot
    )
    _ = try git.data(["remote", "rename", "origin", "upstream"], at: fork)
    _ = try git.data(["remote", "add", "origin", fork.path], at: fork)

    _ = try git.data(
      ["clone", "--quiet", "--no-local", "--no-hardlinks", "--", fork.path, live.path],
      at: runtimeRoot
    )
    _ = try git.data(["remote", "add", "upstream", core.path], at: live)
    try DurableForkValidation.configureAuthor(live, git: git)
    let shortLiveRef = String(request.liveRef.dropFirst("refs/heads/".count))
    _ = try git.data(
      ["checkout", "--quiet", "-b", shortLiveRef, request.expectedUpstreamOID, "--"],
      at: live
    )

    let specialization = DurableForkSpecializationPassport(
      schemaIdentity: "fum.durable-fork-subnode.specialization-passport",
      schemaVersion: 1,
      nodeID: request.nodeID,
      repositoryID: request.forkRepositoryID,
      upstreamRepositoryID: request.upstreamRepositoryID,
      assemblyRepositoryID: request.assemblyRepositoryID,
      liveRef: request.liveRef,
      upstreamRef: request.upstreamRef,
      rulesPath: request.rulesPath,
      queueRefNamespace: request.queueRefNamespace,
      queueBootstrapScriptPath: request.queueBootstrapScriptPath,
      nextStepValidatorPath: request.nextStepValidatorPath,
      nextStepRecordPath: request.nextStepRecordPath,
      accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary
    )
    let specializationData = try specialization.canonicalJSONData()
    let cardSHA256 = DurableForkJSON.sha256(request.nextStepCardData)
    let nextStepRecord = DurableForkNextStepRecord(
      schemaVersion: 5,
      branchRef: request.liveRef,
      state: "open",
      projectPath: request.projectPath,
      candidates: [
        DurableForkNextStepCandidate(
          stepID: request.nextStepID,
          cardID: request.nextStepCardID,
          cardContentSHA256: cardSHA256,
          dispatch: "automatic",
          requiresCompletedCardIDs: []
        )
      ]
    )
    let nextStepData = nextStepRecord.canonicalMarkdownData()
    for write in [
      WritingSubnodeWrite(path: "Паспорт-подузла.json", contents: specializationData),
      WritingSubnodeWrite(path: request.rulesPath, contents: request.rulesData),
      WritingSubnodeWrite(path: request.nextStepRecordPath, contents: nextStepData),
      WritingSubnodeWrite(path: request.nextStepCardPath, contents: request.nextStepCardData),
    ] {
      try WritingSubnodePersistence.materialize(write, cloneURL: live)
      _ = try git.data(["add", "--", write.path], at: live)
    }
    let forkTreeOID = try git.text(["write-tree"], at: live)
    let forkOID = try git.text(
      ["commit-tree", forkTreeOID, "-p", request.expectedUpstreamOID],
      at: live,
      input: Data("Register durable specialized subnode\n".utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment
    )
    let liveRefUpdate = Data(
      "start\nupdate \(request.liveRef) \(forkOID) \(request.expectedUpstreamOID)\nprepare\ncommit\n"
        .utf8
    )
    _ = try git.data(["update-ref", "--stdin"], at: live, input: liveRefUpdate)

    let liveQueueIdentity = try DurableForkValidation.queueIdentity(
      repoRoot: live,
      namespace: request.queueRefNamespace,
      git: git
    )
    let nextStepValidation: [String: Any]
    let nextStepSelection: [String: Any]
    let queueStatus: [String: Any]
    do {
      nextStepValidation = try DurableForkToolRunner.runNextStep(
        repoRoot: live,
        scriptPath: request.nextStepValidatorPath,
        command: "validate"
      )
      nextStepSelection = try DurableForkToolRunner.runNextStep(
        repoRoot: live,
        scriptPath: request.nextStepValidatorPath,
        command: "show"
      )
      queueStatus = try DurableForkToolRunner.runQueue(
        repoRoot: live,
        scriptPath: request.queueBootstrapScriptPath,
        arguments: ["status"]
      )
    } catch {
      for created in [live, fork] where FileManager.default.fileExists(atPath: created.path) {
        try FileManager.default.removeItem(at: created)
      }
      return DurableForkRegistrationResult(outcome: .invalidRequest)
    }
    let selection = nextStepSelection["selection"] as? [String: Any]
    let liveQueueRefs = try git.text(
      ["for-each-ref", "--format=%(refname)", "\(request.queueRefNamespace)/"],
      at: live
    )
    let bareQueueRefs = try git.text(
      ["for-each-ref", "--format=%(refname)", "\(request.queueRefNamespace)/"],
      at: fork
    )
    guard DurableForkToolRunner.string(nextStepValidation, "state") == "valid",
      DurableForkToolRunner.string(nextStepValidation, "active_branch_ref") == request.liveRef,
      DurableForkToolRunner.string(nextStepValidation, "record_path")
        == request.nextStepRecordPath,
      DurableForkToolRunner.string(nextStepValidation, "project_path") == request.projectPath,
      DurableForkToolRunner.integer(nextStepValidation, "ready_count") == 1,
      DurableForkToolRunner.string(nextStepSelection, "state") == "ready",
      DurableForkToolRunner.string(nextStepSelection, "branch_ref") == request.liveRef,
      DurableForkToolRunner.string(nextStepSelection, "record_path") == request.nextStepRecordPath,
      DurableForkToolRunner.string(nextStepSelection, "project_path") == request.projectPath,
      DurableForkToolRunner.string(nextStepSelection, "card_id") == request.nextStepCardID,
      DurableForkValidation.unicodeEquivalent(
        DurableForkToolRunner.string(nextStepSelection, "card_path"),
        request.nextStepCardPath),
      DurableForkToolRunner.string(nextStepSelection, "card_content_sha256") == cardSHA256,
      DurableForkToolRunner.string(nextStepSelection, "step_id") == request.nextStepID,
      DurableForkToolRunner.string(selection, "head") == forkOID,
      DurableForkToolRunner.string(queueStatus, "state") == "idle",
      DurableForkToolRunner.string(queueStatus, "queue_ref") == liveQueueIdentity.ref,
      DurableForkToolRunner.string(queueStatus, "worktree_id") == liveQueueIdentity.worktreeID,
      queueStatus["queue_oid"] is NSNull,
      liveQueueRefs.isEmpty,
      bareQueueRefs.isEmpty
    else {
      for created in [live, fork] where FileManager.default.fileExists(atPath: created.path) {
        try FileManager.default.removeItem(at: created)
      }
      return DurableForkRegistrationResult(outcome: .invalidRequest)
    }

    let forkPush = try git.run(
      ["push", "--porcelain", "origin", "\(forkOID):\(request.liveRef)"],
      at: live
    )
    guard forkPush.status == 0,
      try DurableForkValidation.refOID(request.liveRef, repository: fork, git: git) == forkOID
    else {
      throw WritingSubnodeExecutorError.gitFailed("Не удалось опубликовать ветку fork-подузла.")
    }

    let assemblyWriter = runtimeRoot.appending(
      path: "assembly-registration", directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        assembly.path, assemblyWriter.path,
      ],
      at: runtimeRoot
    )
    try DurableForkValidation.configureAuthor(assemblyWriter, git: git)
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedAssemblyOID, "--"],
      at: assemblyWriter
    )
    let modules = """
      [submodule "durable-specialized-subnode"]
      \tpath = \(request.submodulePath)
      \turl = \(request.submoduleURL)
      """ + "\n"
    try WritingSubnodePersistence.materialize(
      WritingSubnodeWrite(path: ".gitmodules", contents: Data(modules.utf8)),
      cloneURL: assemblyWriter
    )
    _ = try git.data(["add", "--", ".gitmodules"], at: assemblyWriter)
    _ = try git.data(
      ["update-index", "--add", "--cacheinfo", "160000,\(forkOID),\(request.submodulePath)"],
      at: assemblyWriter
    )
    let assemblyTreeOID = try git.text(["write-tree"], at: assemblyWriter)
    let assemblyOID = try git.text(
      ["commit-tree", assemblyTreeOID, "-p", request.expectedAssemblyOID],
      at: assemblyWriter,
      input: Data("Register durable fork subnode snapshot\n".utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment
    )
    guard
      try DurableForkValidation.pushCAS(
        newOID: assemblyOID,
        expectedOID: request.expectedAssemblyOID,
        ref: request.assemblyRef,
        clone: assemblyWriter,
        git: git
      )
    else {
      return DurableForkRegistrationResult(outcome: .oidMismatch)
    }

    let snapshot = try restoreParentSnapshot(
      assemblyBareURL: assembly,
      assemblyOID: assemblyOID,
      submodulePath: request.submodulePath,
      destinationURL: snapshotRoot
    )
    guard snapshot.outcome == .restored,
      let snapshotURL = snapshot.checkoutURL?.appending(
        path: request.submodulePath, directoryHint: .isDirectory)
    else {
      throw WritingSubnodeExecutorError.gitFailed("Не удалось восстановить снимок submodule.")
    }

    let compositionData = try compositionPassportData(
      nodeID: request.nodeID,
      forkRepositoryID: request.forkRepositoryID,
      upstreamRepositoryID: request.upstreamRepositoryID,
      assemblyRepositoryID: request.assemblyRepositoryID,
      upstreamBaseOID: request.expectedUpstreamOID,
      forkOID: forkOID,
      liveRef: request.liveRef,
      assemblyOID: assemblyOID,
      assemblyRef: request.assemblyRef,
      submodulePath: request.submodulePath,
      accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary
    )
    let compositionContext = RepositoryCompositionContext(
      gitExecutableURL: WritingSubnodeSystemRuntime.gitExecutableURL,
      bareRepositoriesByID: [
        request.upstreamRepositoryID: core,
        request.forkRepositoryID: fork,
        request.assemblyRepositoryID: assembly,
      ],
      checkoutsByEntryID: [
        "entry.\(request.nodeID)": RepositoryCompositionCheckoutContext(
          snapshotURL: snapshotURL,
          writerURL: live
        )
      ]
    )
    let compositionReport = RepositoryCompositionPreflight.analyze(
      compositionData,
      context: compositionContext
    )
    guard compositionReport.decision == .valid else {
      let rollback = Data(
        "start\nupdate \(request.assemblyRef) \(request.expectedAssemblyOID) \(assemblyOID)\nprepare\ncommit\n"
          .utf8
      )
      _ = try git.data(["update-ref", "--stdin"], at: assembly, input: rollback)
      for created in [snapshotRoot, live, fork, assemblyWriter] {
        if FileManager.default.fileExists(atPath: created.path) {
          try FileManager.default.removeItem(at: created)
        }
      }
      return DurableForkRegistrationResult(
        outcome: .invalidComposition,
        compositionViolations: compositionReport.violations)
    }

    let registrationPassport = DurableForkRegistrationPassport(
      schemaIdentity: "fum.durable-fork-subnode.registration-passport",
      schemaVersion: 1,
      nodeID: request.nodeID,
      repositoryID: request.forkRepositoryID,
      upstreamRepositoryID: request.upstreamRepositoryID,
      assemblyRepositoryID: request.assemblyRepositoryID,
      upstreamBaseOID: request.expectedUpstreamOID,
      forkOID: forkOID,
      forkLiveRef: request.liveRef,
      assemblyBaseOID: request.expectedAssemblyOID,
      assemblyOID: assemblyOID,
      assemblyRef: request.assemblyRef,
      submodulePath: request.submodulePath,
      gitlinkOID: forkOID,
      specializationPassportSHA256: DurableForkJSON.sha256(specializationData),
      rulesSHA256: DurableForkJSON.sha256(request.rulesData),
      queueRefNamespace: request.queueRefNamespace,
      queueBootstrapScriptPath: request.queueBootstrapScriptPath,
      queueBootstrapScriptSHA256: request.queueBootstrapScriptSHA256,
      nextStepValidatorPath: request.nextStepValidatorPath,
      nextStepValidatorSHA256: request.nextStepValidatorSHA256,
      nextStepRecordPath: request.nextStepRecordPath,
      nextStepRecordSHA256: DurableForkJSON.sha256(nextStepData),
      projectPath: request.projectPath,
      nextStepCardPath: request.nextStepCardPath,
      nextStepCardID: request.nextStepCardID,
      nextStepCardContentSHA256: cardSHA256,
      accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary
    )
    let registrationData = try registrationPassport.canonicalJSONData()
    let node = DurableForkNodeContext(
      nodeID: request.nodeID,
      forkRepositoryID: request.forkRepositoryID,
      upstreamRepositoryID: request.upstreamRepositoryID,
      assemblyRepositoryID: request.assemblyRepositoryID,
      coreBareURL: core,
      forkBareURL: fork,
      assemblyBareURL: assembly,
      liveCloneURL: live,
      runtimeRootURL: runtimeRoot,
      snapshotURL: snapshotURL,
      upstreamRef: request.upstreamRef,
      liveRef: request.liveRef,
      assemblyRef: request.assemblyRef,
      upstreamOID: request.expectedUpstreamOID,
      forkOID: forkOID,
      assemblyOID: assemblyOID,
      submodulePath: request.submodulePath,
      submoduleURL: request.submoduleURL,
      gitlinkOID: forkOID,
      rulesPath: request.rulesPath,
      liveQueueRef: liveQueueIdentity.ref,
      queueRefNamespace: request.queueRefNamespace,
      queueBootstrapScriptPath: request.queueBootstrapScriptPath,
      nextStepValidatorPath: request.nextStepValidatorPath,
      nextStepRecordPath: request.nextStepRecordPath,
      accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary,
      registrationPassport: registrationPassport,
      registrationPassportCanonicalJSON: registrationData,
      compositionPassportCanonicalJSON: compositionData,
      compositionReport: compositionReport
    )
    guard try verifyRemoteBindings(node) else {
      return DurableForkRegistrationResult(outcome: .remoteMismatch)
    }
    return DurableForkRegistrationResult(outcome: .registered, node: node)
  }

  public func verifyRemoteBindings(_ node: DurableForkNodeContext) throws -> Bool {
    let origin = try git.text(["remote", "get-url", "origin"], at: node.liveCloneURL)
    let upstream = try git.text(["remote", "get-url", "upstream"], at: node.liveCloneURL)
    return DurableForkValidation.sameLocation(origin, node.forkBareURL)
      && DurableForkValidation.sameLocation(upstream, node.coreBareURL)
      && origin != upstream
  }

  private func compositionPassportData(
    nodeID: String,
    forkRepositoryID: String,
    upstreamRepositoryID: String,
    assemblyRepositoryID: String,
    upstreamBaseOID: String,
    forkOID: String,
    liveRef: String,
    assemblyOID: String,
    assemblyRef: String,
    submodulePath: String,
    accessLevel: RepositoryCompositionAccessLevel,
    publicationBoundary: RepositoryCompositionAccessLevel
  ) throws -> Data {
    let checks = ["commit_exists", "live_ref_matches", "handoff_ready"]
    let handoff = RepositoryCompositionHandoff(
      targetRepositoryID: assemblyRepositoryID,
      targetRef: assemblyRef,
      requiredCheckIDs: checks
    )
    let passport = RepositoryCompositionPassport(
      schemaVersion: 1,
      passportID: "passport.durable-fork.\(nodeID).v1",
      compositionID: "fum.durable-fork.\(nodeID).v1",
      parentRepository: RepositoryCompositionParentRepository(
        repositoryID: assemblyRepositoryID,
        repositoryURL: "urn:fum:repository:\(assemblyRepositoryID)",
        snapshotOID: assemblyOID,
        liveRef: assemblyRef,
        accessLevel: accessLevel,
        publicationBoundary: publicationBoundary
      ),
      children: [
        RepositoryCompositionChild(
          entryID: "entry.\(nodeID)",
          kind: .specializedSubnode,
          nodeID: nodeID,
          projectID: nil,
          targetRepositoryID: nil,
          repositoryID: forkRepositoryID,
          repositoryURL: "urn:fum:repository:\(forkRepositoryID)",
          upstreamRepositoryID: upstreamRepositoryID,
          baseOID: upstreamBaseOID,
          liveRef: liveRef,
          submodulePath: submodulePath,
          gitlinkOID: forkOID,
          snapshotMode: "detached_read_only",
          writerMode: "separate_clone",
          nestedSubmodules: [],
          accessLevel: accessLevel,
          publicationBoundary: publicationBoundary,
          checks: checks,
          handoff: handoff
        )
      ]
    )
    return try DurableForkJSON.encode(passport)
  }
}

extension DurableForkSubnodeRuntime {
  public func updateParentGitlink(
    _ request: DurableForkParentUpdateRequest
  ) throws -> DurableForkParentUpdateResult {
    let node = request.node
    guard WritingSubnodeValidation.publicationOutcome(Data(request.commitMessage.utf8)) == nil
    else {
      return DurableForkParentUpdateResult(outcome: .publicationBoundaryRejected)
    }
    guard DurableForkValidation.isIdentifier(request.updateID),
      DurableForkValidation.isOID(request.expectedParentOID),
      DurableForkValidation.isOID(request.expectedPreviousGitlinkOID),
      DurableForkValidation.isOID(request.gitlinkOID),
      request.expectedParentOID == node.assemblyOID,
      request.expectedPreviousGitlinkOID == node.gitlinkOID,
      request.gitlinkOID == node.forkOID,
      try DurableForkValidation.refOID(node.assemblyRef, repository: node.assemblyBareURL, git: git)
        == request.expectedParentOID,
      try DurableForkValidation.refOID(node.liveRef, repository: node.forkBareURL, git: git)
        == request.gitlinkOID,
      try git.succeeds(
        [
          "merge-base", "--is-ancestor", request.expectedPreviousGitlinkOID,
          request.gitlinkOID,
        ],
        at: node.forkBareURL
      )
    else {
      return DurableForkParentUpdateResult(outcome: .oidMismatch)
    }
    let previousEntry = try DurableForkValidation.gitlink(
      parentOID: request.expectedParentOID,
      path: node.submodulePath,
      repository: node.assemblyBareURL,
      git: git
    )
    guard previousEntry == request.expectedPreviousGitlinkOID else {
      return DurableForkParentUpdateResult(outcome: .oidMismatch)
    }

    let root = request.updateRootURL.standardizedFileURL
    guard !FileManager.default.fileExists(atPath: root.path) else {
      return DurableForkParentUpdateResult(outcome: .invalidRequest)
    }
    try DurableForkValidation.ensureDirectory(root)
    let clone = root.appending(path: "clone", directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        node.assemblyBareURL.path, clone.path,
      ],
      at: root
    )
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedParentOID, "--"], at: clone)
    _ = try git.data(
      [
        "update-index", "--cacheinfo",
        "160000,\(request.gitlinkOID),\(node.submodulePath)",
      ],
      at: clone
    )
    let treeOID = try git.text(["write-tree"], at: clone)
    let parentOID = try git.text(
      ["commit-tree", treeOID, "-p", request.expectedParentOID],
      at: clone,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment
    )
    let proofRef =
      "refs/heads/fum-proof/"
      + String(DurableForkJSON.sha256(Data(request.updateID.utf8)).dropFirst("sha256:".count))
    let proofPush = try git.run(
      [
        "push", "--porcelain", "--force-with-lease=\(proofRef):",
        "origin", "\(parentOID):\(proofRef)",
      ],
      at: clone
    )
    guard proofPush.status == 0,
      try DurableForkValidation.refOID(
        proofRef, repository: node.assemblyBareURL, git: git) == parentOID
    else {
      return DurableForkParentUpdateResult(outcome: .oidMismatch)
    }
    var proofIsActive = true
    var preserveSnapshot = false
    defer {
      if proofIsActive {
        _ = try? git.run(
          ["update-ref", "-d", proofRef, parentOID], at: node.assemblyBareURL)
      }
      if !preserveSnapshot,
        FileManager.default.fileExists(atPath: request.snapshotRootURL.path)
      {
        try? FileManager.default.removeItem(at: request.snapshotRootURL)
      }
    }
    let restored = try restoreParentSnapshot(
      assemblyBareURL: node.assemblyBareURL,
      assemblyOID: parentOID,
      submodulePath: node.submodulePath,
      destinationURL: request.snapshotRootURL
    )
    guard restored.outcome == .restored,
      let parentCheckout = restored.checkoutURL
    else {
      throw WritingSubnodeExecutorError.gitFailed("Новый снимок родителя не восстановлен.")
    }
    let snapshot = parentCheckout.appending(path: node.submodulePath, directoryHint: .isDirectory)
    let compositionData = try compositionPassportData(
      nodeID: node.nodeID,
      forkRepositoryID: node.forkRepositoryID,
      upstreamRepositoryID: node.upstreamRepositoryID,
      assemblyRepositoryID: node.assemblyRepositoryID,
      upstreamBaseOID: node.registrationPassport.upstreamBaseOID,
      forkOID: request.gitlinkOID,
      liveRef: node.liveRef,
      assemblyOID: parentOID,
      assemblyRef: node.assemblyRef,
      submodulePath: node.submodulePath,
      accessLevel: node.accessLevel,
      publicationBoundary: node.publicationBoundary
    )
    let report = RepositoryCompositionPreflight.analyze(
      compositionData,
      context: RepositoryCompositionContext(
        gitExecutableURL: WritingSubnodeSystemRuntime.gitExecutableURL,
        bareRepositoriesByID: [
          node.upstreamRepositoryID: node.coreBareURL,
          node.forkRepositoryID: node.forkBareURL,
          node.assemblyRepositoryID: node.assemblyBareURL,
        ],
        checkoutsByEntryID: [
          "entry.\(node.nodeID)": RepositoryCompositionCheckoutContext(
            snapshotURL: snapshot,
            writerURL: node.liveCloneURL
          )
        ]
      )
    )
    guard report.decision == .valid else {
      return DurableForkParentUpdateResult(outcome: .invalidComposition)
    }
    let publishLines = [
      "start",
      "update \(node.assemblyRef) \(parentOID) \(request.expectedParentOID)",
      "delete \(proofRef) \(parentOID)",
      "prepare",
      "commit",
    ]
    let publish = Data((publishLines.joined(separator: "\n") + "\n").utf8)
    let publication = try git.run(
      ["update-ref", "--stdin"], at: node.assemblyBareURL, input: publish)
    guard publication.status == 0 else {
      return DurableForkParentUpdateResult(outcome: .oidMismatch)
    }
    proofIsActive = false
    preserveSnapshot = true
    let passport = DurableForkParentUpdatePassport(
      schemaIdentity: "fum.durable-fork-subnode.parent-update-passport",
      schemaVersion: 1,
      updateID: request.updateID,
      assemblyRepositoryID: node.assemblyRepositoryID,
      assemblyRef: node.assemblyRef,
      parentBaseOID: request.expectedParentOID,
      parentOID: parentOID,
      submodulePath: node.submodulePath,
      previousGitlinkOID: request.expectedPreviousGitlinkOID,
      gitlinkOID: request.gitlinkOID,
      childRepositoryID: node.forkRepositoryID,
      childLiveRef: node.liveRef
    )
    return DurableForkParentUpdateResult(
      outcome: .parentUpdated,
      node: node.updating(
        assemblyOID: parentOID,
        gitlinkOID: request.gitlinkOID,
        snapshotURL: snapshot,
        compositionPassportCanonicalJSON: compositionData,
        compositionReport: report
      ),
      passport: passport
    )
  }

  public func restoreParentSnapshot(
    _ request: DurableForkRestoreRequest
  ) throws -> DurableForkRestoreResult {
    guard !request.recursiveInitialization else {
      return DurableForkRestoreResult(
        outcome: .recursiveInitializationForbidden,
        checkoutURL: nil,
        headOID: nil,
        snapshotIsDetached: nil,
        snapshotIsClean: nil,
        liveRef: nil,
        nextStepRecordSHA256: nil
      )
    }
    return try restoreParentSnapshot(
      assemblyBareURL: request.node.assemblyBareURL,
      assemblyOID: request.node.assemblyOID,
      submodulePath: request.node.submodulePath,
      destinationURL: request.destinationURL
    )
  }

  public func restoreLiveClone(
    node: DurableForkNodeContext,
    destinationURL: URL
  ) throws -> DurableForkRestoreResult {
    guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
      return DurableForkRestoreResult(
        outcome: .invalidRequest,
        checkoutURL: nil,
        headOID: nil,
        snapshotIsDetached: nil,
        snapshotIsClean: nil,
        liveRef: nil,
        nextStepRecordSHA256: nil
      )
    }
    let parent = destinationURL.deletingLastPathComponent()
    try DurableForkValidation.ensureDirectory(parent)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        node.forkBareURL.path, destinationURL.path,
      ],
      at: parent
    )
    _ = try git.data(["remote", "add", "upstream", node.coreBareURL.path], at: destinationURL)
    let short = String(node.liveRef.dropFirst("refs/heads/".count))
    _ = try git.data(
      ["checkout", "--quiet", "-b", short, node.forkOID, "--"], at: destinationURL)

    let nextStep = try git.data(
      ["cat-file", "blob", "\(node.forkOID):\(node.nextStepRecordPath)"],
      at: destinationURL
    )
    let rules = try git.data(
      ["cat-file", "blob", "\(node.forkOID):\(node.rulesPath)"], at: destinationURL)
    let cardData = try git.data(
      [
        "cat-file", "blob",
        "\(node.forkOID):\(node.registrationPassport.nextStepCardPath)",
      ],
      at: destinationURL
    )
    let queueScript = try git.data(
      ["cat-file", "blob", "\(node.forkOID):\(node.queueBootstrapScriptPath)"],
      at: destinationURL
    )
    let nextStepValidator = try git.data(
      ["cat-file", "blob", "\(node.forkOID):\(node.nextStepValidatorPath)"],
      at: destinationURL
    )
    let queueIdentity = try DurableForkValidation.queueIdentity(
      repoRoot: destinationURL,
      namespace: node.queueRefNamespace,
      git: git
    )
    let queueRefBefore = try git.run(
      ["rev-parse", "--verify", "--quiet", queueIdentity.ref], at: destinationURL)
    let bareQueueRefsBefore = try git.text(
      ["for-each-ref", "--format=%(refname)", "\(node.queueRefNamespace)/"],
      at: node.forkBareURL
    )
    let nextStepValidation = try DurableForkToolRunner.runNextStep(
      repoRoot: destinationURL,
      scriptPath: node.nextStepValidatorPath,
      command: "validate"
    )
    let nextStepSelection = try DurableForkToolRunner.runNextStep(
      repoRoot: destinationURL,
      scriptPath: node.nextStepValidatorPath,
      command: "show"
    )
    let selection = nextStepSelection["selection"] as? [String: Any]
    let queueBeforeJoin = try DurableForkToolRunner.runQueue(
      repoRoot: destinationURL,
      scriptPath: node.queueBootstrapScriptPath,
      arguments: ["status"]
    )
    let queueRefAfterStatus = try git.run(
      ["rev-parse", "--verify", "--quiet", queueIdentity.ref], at: destinationURL)

    guard try git.text(["symbolic-ref", "-q", "HEAD"], at: destinationURL) == node.liveRef,
      try git.text(["rev-parse", "HEAD"], at: destinationURL) == node.forkOID,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: destinationURL)
        .isEmpty,
      queueIdentity.ref != node.liveQueueRef,
      queueRefBefore.status == 1,
      queueRefAfterStatus.status == 1,
      bareQueueRefsBefore.isEmpty,
      DurableForkToolRunner.string(nextStepValidation, "state") == "valid",
      DurableForkToolRunner.string(nextStepValidation, "active_branch_ref") == node.liveRef,
      DurableForkToolRunner.string(nextStepValidation, "record_path")
        == node.nextStepRecordPath,
      DurableForkToolRunner.string(nextStepValidation, "project_path")
        == node.registrationPassport.projectPath,
      DurableForkToolRunner.integer(nextStepValidation, "ready_count") == 1,
      DurableForkToolRunner.string(nextStepSelection, "state") == "ready",
      DurableForkToolRunner.string(nextStepSelection, "branch_ref") == node.liveRef,
      DurableForkToolRunner.string(nextStepSelection, "record_path") == node.nextStepRecordPath,
      DurableForkToolRunner.string(nextStepSelection, "project_path")
        == node.registrationPassport.projectPath,
      DurableForkToolRunner.string(nextStepSelection, "card_id")
        == node.registrationPassport.nextStepCardID,
      DurableForkValidation.unicodeEquivalent(
        DurableForkToolRunner.string(nextStepSelection, "card_path"),
        node.registrationPassport.nextStepCardPath),
      DurableForkToolRunner.string(nextStepSelection, "card_content_sha256")
        == node.registrationPassport.nextStepCardContentSHA256,
      DurableForkToolRunner.string(selection, "head") == node.forkOID,
      DurableForkToolRunner.string(queueBeforeJoin, "state") == "idle",
      DurableForkToolRunner.string(queueBeforeJoin, "queue_ref") == queueIdentity.ref,
      DurableForkToolRunner.string(queueBeforeJoin, "worktree_id") == queueIdentity.worktreeID,
      queueBeforeJoin["queue_oid"] is NSNull,
      DurableForkJSON.sha256(cardData)
        == node.registrationPassport.nextStepCardContentSHA256,
      DurableForkJSON.sha256(nextStep) == node.registrationPassport.nextStepRecordSHA256,
      DurableForkJSON.sha256(rules) == node.registrationPassport.rulesSHA256,
      DurableForkJSON.sha256(queueScript)
        == node.registrationPassport.queueBootstrapScriptSHA256,
      DurableForkJSON.sha256(nextStepValidator)
        == node.registrationPassport.nextStepValidatorSHA256,
      DurableForkValidation.sameLocation(
        try git.text(["remote", "get-url", "origin"], at: destinationURL),
        node.forkBareURL
      ),
      DurableForkValidation.sameLocation(
        try git.text(["remote", "get-url", "upstream"], at: destinationURL),
        node.coreBareURL
      )
    else {
      throw WritingSubnodeExecutorError.gitFailed("Живой клон не восстановил контракт fork.")
    }

    let queueTaskID = "fum-fixture-durable-fork"
    let joined = try DurableForkToolRunner.runQueue(
      repoRoot: destinationURL,
      scriptPath: node.queueBootstrapScriptPath,
      arguments: ["join", "--task-id", queueTaskID]
    )
    guard DurableForkToolRunner.string(joined, "state") == "admitted",
      DurableForkToolRunner.string(joined, "queue_ref") == queueIdentity.ref,
      let generation = DurableForkToolRunner.string(joined, "generation")
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Новая локальная очередь fork-подузла не допустила тестовый билет.")
    }
    let finished = try DurableForkToolRunner.runQueue(
      repoRoot: destinationURL,
      scriptPath: node.queueBootstrapScriptPath,
      arguments: [
        "finish-clean", "--task-id", queueTaskID, "--generation", generation,
      ]
    )
    let queueAfterFinish = try DurableForkToolRunner.runQueue(
      repoRoot: destinationURL,
      scriptPath: node.queueBootstrapScriptPath,
      arguments: ["status"]
    )
    let localQueueRefs = try git.text(
      ["for-each-ref", "--format=%(refname)", "\(node.queueRefNamespace)/"],
      at: destinationURL
    )
    let bareQueueRefsAfter = try git.text(
      ["for-each-ref", "--format=%(refname)", "\(node.queueRefNamespace)/"],
      at: node.forkBareURL
    )
    guard DurableForkToolRunner.string(finished, "state") == "finished_clean",
      DurableForkToolRunner.string(finished, "queue_ref") == queueIdentity.ref,
      DurableForkToolRunner.string(queueAfterFinish, "state") == "idle",
      DurableForkToolRunner.string(queueAfterFinish, "queue_ref") == queueIdentity.ref,
      DurableForkToolRunner.string(queueAfterFinish, "worktree_id") == queueIdentity.worktreeID,
      DurableForkToolRunner.string(queueAfterFinish, "queue_oid") != nil,
      queueAfterFinish["owner"] is NSNull,
      DurableForkToolRunner.array(queueAfterFinish, "waiting")?.isEmpty == true,
      localQueueRefs == queueIdentity.ref,
      bareQueueRefsAfter.isEmpty,
      try git.text(["symbolic-ref", "-q", "HEAD"], at: destinationURL) == node.liveRef,
      try git.text(["rev-parse", "HEAD"], at: destinationURL) == node.forkOID,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: destinationURL)
        .isEmpty
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Новая локальная очередь fork-подузла не завершила чистую передачу.")
    }

    return DurableForkRestoreResult(
      outcome: .restored,
      checkoutURL: destinationURL,
      headOID: node.forkOID,
      snapshotIsDetached: false,
      snapshotIsClean: true,
      liveRef: node.liveRef,
      nextStepRecordSHA256: DurableForkJSON.sha256(nextStep),
      nextStepValidationState: "valid",
      queueValidationState: "idle",
      queueRef: queueIdentity.ref
    )
  }

  private func restoreParentSnapshot(
    assemblyBareURL: URL,
    assemblyOID: String,
    submodulePath: String,
    destinationURL: URL
  ) throws -> DurableForkRestoreResult {
    guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
      return DurableForkRestoreResult(
        outcome: .invalidRequest,
        checkoutURL: nil,
        headOID: nil,
        snapshotIsDetached: nil,
        snapshotIsClean: nil,
        liveRef: nil,
        nextStepRecordSHA256: nil
      )
    }
    let parent = destinationURL.deletingLastPathComponent()
    try DurableForkValidation.ensureDirectory(parent)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        assemblyBareURL.path, destinationURL.path,
      ],
      at: parent
    )
    _ = try git.data(
      ["checkout", "--quiet", "--detach", assemblyOID, "--"], at: destinationURL)
    let update = try git.run(
      ["submodule", "update", "--init", "--", submodulePath], at: destinationURL)
    guard update.status == 0 else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Нерекурсивное восстановление submodule не удалось.")
    }
    let snapshot = destinationURL.appending(path: submodulePath, directoryHint: .isDirectory)
    let snapshotOID = try git.text(["rev-parse", "HEAD"], at: snapshot)
    let symbolic = try git.run(["symbolic-ref", "-q", "HEAD"], at: snapshot)
    let clean = try git.text(
      ["status", "--porcelain=v1", "--untracked-files=all"], at: snapshot
    ).isEmpty
    let parentSymbolic = try git.run(["symbolic-ref", "-q", "HEAD"], at: destinationURL)
    let exactGitlink = try DurableForkValidation.gitlink(
      parentOID: assemblyOID,
      path: submodulePath,
      repository: destinationURL,
      git: git
    )
    guard try git.text(["rev-parse", "HEAD"], at: destinationURL) == assemblyOID,
      parentSymbolic.status == 1,
      exactGitlink == snapshotOID,
      symbolic.status == 1,
      clean
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Свежий клон родителя не восстановил точный detached-снимок."
      )
    }
    return DurableForkRestoreResult(
      outcome: .restored,
      checkoutURL: destinationURL,
      headOID: snapshotOID,
      snapshotIsDetached: symbolic.status == 1,
      snapshotIsClean: clean,
      liveRef: nil,
      nextStepRecordSHA256: nil
    )
  }
}

extension DurableForkSubnodeRuntime {
  public func synchronizeFromUpstream(
    _ request: DurableForkSyncRequest
  ) throws -> DurableForkSyncResult {
    let node = request.node
    guard request.accessLevel == .public, request.publicationBoundary == .public else {
      return DurableForkSyncResult(
        outcome: .publicationBoundaryRejected,
        node: nil,
        syncOID: nil
      )
    }
    guard WritingSubnodeValidation.publicationOutcome(Data(request.commitMessage.utf8)) == nil
    else {
      return DurableForkSyncResult(
        outcome: .publicationBoundaryRejected,
        node: nil,
        syncOID: nil
      )
    }
    guard DurableForkValidation.isIdentifier(request.syncID),
      DurableForkValidation.isOID(request.expectedForkOID),
      DurableForkValidation.isOID(request.expectedUpstreamOID),
      request.expectedForkOID == node.forkOID,
      request.expectedUpstreamOID == node.upstreamOID,
      try DurableForkValidation.refOID(node.liveRef, repository: node.forkBareURL, git: git)
        == request.expectedForkOID,
      try DurableForkValidation.refOID(node.upstreamRef, repository: node.coreBareURL, git: git)
        == request.expectedUpstreamOID
    else {
      return DurableForkSyncResult(outcome: .oidMismatch, node: nil, syncOID: nil)
    }
    guard
      try !DurableForkValidation.containsGitlink(
        treeish: request.expectedUpstreamOID,
        repository: node.coreBareURL,
        git: git
      )
    else {
      return DurableForkSyncResult(
        outcome: .publicationBoundaryRejected,
        node: nil,
        syncOID: nil
      )
    }
    guard try verifyRemoteBindings(node) else {
      return DurableForkSyncResult(outcome: .remoteMismatch, node: nil, syncOID: nil)
    }

    let root = request.syncRootURL.standardizedFileURL
    guard !FileManager.default.fileExists(atPath: root.path) else {
      return DurableForkSyncResult(outcome: .invalidRequest, node: nil, syncOID: nil)
    }
    try DurableForkValidation.ensureDirectory(root)
    let clone = root.appending(path: "clone", directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        node.forkBareURL.path, clone.path,
      ],
      at: root
    )
    _ = try git.data(["remote", "add", "upstream", node.coreBareURL.path], at: clone)
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedForkOID, "--"], at: clone)
    let fetch = try git.run(
      ["fetch", "--quiet", "--no-tags", "upstream", node.upstreamRef], at: clone)
    guard fetch.status == 0,
      try git.text(["rev-parse", "FETCH_HEAD"], at: clone) == request.expectedUpstreamOID
    else {
      return DurableForkSyncResult(outcome: .oidMismatch, node: nil, syncOID: nil)
    }
    let merge = try git.run(
      ["merge", "--no-commit", "--no-ff", request.expectedUpstreamOID], at: clone)
    guard merge.status == 0 else {
      _ = try? git.run(["merge", "--abort"], at: clone)
      guard
        try DurableForkValidation.refOID(
          node.liveRef, repository: node.forkBareURL, git: git) == request.expectedForkOID
      else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      return DurableForkSyncResult(outcome: .conflict, node: nil, syncOID: nil)
    }
    let treeOID = try git.text(["write-tree"], at: clone)
    let changedPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        request.expectedForkOID, treeOID, "--",
      ],
      at: clone
    ).sorted()
    let mergedDiff = try git.data(
      [
        "diff", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        request.expectedForkOID, treeOID, "--",
      ],
      at: clone
    )
    guard !changedPaths.isEmpty,
      WritingSubnodeValidation.publicationOutcome(mergedDiff, allowingGitNullDevice: true) == nil,
      try WritingSubnodeCandidateAudit.validateTree(
        paths: changedPaths,
        treeOID: treeOID,
        cloneURL: clone,
        git: WritingSubnodeGit()
      ) == nil
    else {
      return DurableForkSyncResult(
        outcome: .publicationBoundaryRejected,
        node: nil,
        syncOID: nil
      )
    }
    let syncOID = try git.text(
      [
        "commit-tree", treeOID, "-p", request.expectedForkOID, "-p",
        request.expectedUpstreamOID,
      ],
      at: clone,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment
    )
    guard
      try DurableForkValidation.pushCAS(
        newOID: syncOID,
        expectedOID: request.expectedForkOID,
        ref: node.liveRef,
        clone: clone,
        git: git
      )
    else {
      return DurableForkSyncResult(outcome: .oidMismatch, node: nil, syncOID: nil)
    }

    _ = try git.data(
      ["fetch", "--quiet", "--no-tags", "origin", node.liveRef], at: node.liveCloneURL)
    guard try git.text(["rev-parse", "FETCH_HEAD"], at: node.liveCloneURL) == syncOID,
      try git.text(["rev-parse", "--verify", "HEAD^{commit}"], at: node.liveCloneURL)
        == request.expectedForkOID
    else {
      throw WritingSubnodeExecutorError.sourceChanged
    }
    let update = Data(
      "start\nupdate \(node.liveRef) \(syncOID) \(request.expectedForkOID)\nprepare\ncommit\n".utf8
    )
    _ = try git.data(["update-ref", "--stdin"], at: node.liveCloneURL, input: update)
    _ = try git.data(["reset", "--hard", "--quiet", syncOID], at: node.liveCloneURL)
    guard try git.text(["symbolic-ref", "-q", "HEAD"], at: node.liveCloneURL) == node.liveRef,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: node.liveCloneURL)
        .isEmpty
    else {
      throw WritingSubnodeExecutorError.sourceChanged
    }
    return DurableForkSyncResult(
      outcome: .synchronized,
      node: node.updating(forkOID: syncOID),
      syncOID: syncOID
    )
  }
}

extension DurableForkSubnodeRuntime {
  public func handoffUpstream(
    _ request: DurableForkHandoffRequest
  ) throws -> DurableForkHandoffResult {
    let node = request.node
    guard request.accessLevel == .public, request.publicationBoundary == .public else {
      return DurableForkHandoffResult(outcome: .publicationBoundaryRejected)
    }
    guard WritingSubnodeValidation.publicationOutcome(Data(request.commitMessage.utf8)) == nil
    else {
      return DurableForkHandoffResult(outcome: .publicationBoundaryRejected)
    }
    guard DurableForkValidation.isIdentifier(request.handoffID),
      DurableForkValidation.isOID(request.expectedCandidateOID),
      DurableForkValidation.isSHA256(request.expectedCandidatePassportSHA256),
      DurableForkValidation.isOID(request.expectedUpstreamOID),
      !request.changeScope.isEmpty,
      Set(request.changeScope).count == request.changeScope.count,
      request.changeScope.allSatisfy(DurableForkValidation.isRelativePath),
      !request.checks.isEmpty,
      Set(request.checks.map(\.checkID)).count == request.checks.count,
      request.checks.allSatisfy({
        DurableForkValidation.isIdentifier($0.checkID)
          && DurableForkValidation.isRelativePath($0.path)
          && DurableForkValidation.isSHA256($0.expectedSHA256)
      }),
      request.expectedUpstreamOID == node.upstreamOID,
      try DurableForkValidation.refOID(node.upstreamRef, repository: node.coreBareURL, git: git)
        == request.expectedUpstreamOID
    else {
      return DurableForkHandoffResult(outcome: .oidMismatch)
    }
    guard try verifyRemoteBindings(node) else {
      return DurableForkHandoffResult(outcome: .remoteMismatch)
    }

    let candidate = try WritingSubnodeCandidateRecovery().recover(
      executionRootURL: request.executionRootURL,
      runID: request.runID
    )
    guard let passport = candidate.passport,
      let passportSHA256 = candidate.passportSHA256,
      let candidateClone = candidate.cloneURL,
      passport.repositoryID == node.forkRepositoryID,
      passport.subnodeID == node.nodeID,
      passport.commitOID == request.expectedCandidateOID,
      passportSHA256 == request.expectedCandidatePassportSHA256,
      Set(passport.actualPaths).isSubset(of: Set(request.changeScope)),
      passport.actualPaths.allSatisfy({ !$0.hasSuffix(".gitmodules") }),
      passport.constraints.networkAllowed == false,
      passport.constraints.integrationAllowed == false,
      try DurableForkValidation.refOID(node.liveRef, repository: node.forkBareURL, git: git)
        == node.forkOID,
      try git.succeeds(
        ["merge-base", "--is-ancestor", passport.commitOID, node.forkOID],
        at: node.forkBareURL
      )
    else {
      return DurableForkHandoffResult(outcome: .invalidRequest)
    }

    let integrationRoot = request.integrationRootURL.standardizedFileURL
    try DurableForkValidation.ensureDirectory(integrationRoot)
    let attempt = integrationRoot.appending(path: request.handoffID, directoryHint: .isDirectory)
    guard !FileManager.default.fileExists(atPath: attempt.path) else {
      return DurableForkHandoffResult(outcome: .invalidRequest)
    }
    try DurableForkValidation.ensureDirectory(attempt)
    let clone = attempt.appending(path: "clone", directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        node.coreBareURL.path, clone.path,
      ],
      at: attempt
    )
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedUpstreamOID, "--"],
      at: clone
    )
    let fetched = try git.run(
      [
        "fetch", "--quiet", "--no-tags", "--no-write-fetch-head", candidateClone.path,
        passport.resultRef,
      ],
      at: clone
    )
    guard fetched.status == 0,
      try git.text(["cat-file", "-t", passport.commitOID], at: clone) == "commit"
    else {
      return DurableForkHandoffResult(outcome: .invalidRequest)
    }
    let diff = try git.data(
      [
        "diff", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        passport.parentOID, passport.commitOID, "--",
      ] + passport.actualPaths,
      at: candidateClone
    )
    guard !diff.isEmpty,
      WritingSubnodeValidation.publicationOutcome(diff, allowingGitNullDevice: true) == nil
    else {
      return DurableForkHandoffResult(outcome: .publicationBoundaryRejected)
    }
    let apply = try git.run(
      ["apply", "--cached", "--index", "--whitespace=nowarn", "--"],
      at: clone,
      input: diff
    )
    guard apply.status == 0 else {
      _ = try? git.run(["reset", "--hard", request.expectedUpstreamOID], at: clone)
      return DurableForkHandoffResult(outcome: .conflict)
    }
    let actualPaths = try git.nulStrings(
      [
        "diff", "--cached", "--name-only", "--no-ext-diff", "--no-textconv",
        "--no-renames", "-z", request.expectedUpstreamOID, "--",
      ],
      at: clone
    ).sorted()
    guard actualPaths == passport.actualPaths.sorted(),
      Set(actualPaths).isSubset(of: Set(request.changeScope))
    else {
      return DurableForkHandoffResult(outcome: .invalidRequest)
    }
    let treeOID = try git.text(["write-tree"], at: clone)
    guard
      try request.checks.allSatisfy({ check in
        try DurableForkValidation.check(check, treeOID: treeOID, repository: clone, git: git)
      })
    else {
      return DurableForkHandoffResult(outcome: .conflict)
    }
    let integrationOID = try git.text(
      [
        "commit-tree", treeOID, "-p", request.expectedUpstreamOID, "-p",
        passport.commitOID,
      ],
      at: clone,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment
    )
    let topology = try git.text(
      ["rev-list", "--parents", "-n", "1", integrationOID], at: clone
    ).split(separator: " ").map(String.init)
    guard topology == [integrationOID, request.expectedUpstreamOID, passport.commitOID] else {
      throw WritingSubnodeExecutorError.gitFailed("Передача вверх потеряла исходный commit.")
    }
    let handoffPassport = DurableForkUpstreamHandoffPassport(
      schemaIdentity: "fum.durable-fork-subnode.upstream-handoff-passport",
      schemaVersion: 1,
      handoffID: request.handoffID,
      nodeID: node.nodeID,
      sourceRepositoryID: node.forkRepositoryID,
      sourceCommitOID: passport.commitOID,
      sourceParentOID: passport.parentOID,
      sourcePassportSHA256: passportSHA256,
      targetRepositoryID: node.upstreamRepositoryID,
      targetRef: node.upstreamRef,
      parentBaseOID: request.expectedUpstreamOID,
      changeScope: request.changeScope.sorted(),
      checks: request.checks.sorted { $0.checkID < $1.checkID },
      accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary,
      integrationTreeOID: treeOID,
      integrationOID: integrationOID,
      state: "accepted"
    )
    let canonical = try handoffPassport.canonicalJSONData()
    guard WritingSubnodeValidation.publicationOutcome(canonical) == nil else {
      return DurableForkHandoffResult(outcome: .publicationBoundaryRejected)
    }
    try WritingSubnodePersistence.persistExclusive(
      canonical,
      at: attempt.appending(path: "handoff-passport.json")
    )
    guard
      try DurableForkValidation.pushCAS(
        newOID: integrationOID,
        expectedOID: request.expectedUpstreamOID,
        ref: node.upstreamRef,
        clone: clone,
        git: git
      )
    else {
      return DurableForkHandoffResult(outcome: .oidMismatch)
    }
    guard
      try DurableForkValidation.refOID(node.liveRef, repository: node.forkBareURL, git: git)
        == node.forkOID,
      try git.succeeds(
        ["merge-base", "--is-ancestor", passport.commitOID, integrationOID],
        at: node.coreBareURL
      )
    else {
      throw WritingSubnodeExecutorError.gitFailed("Родословная передачи вверх не подтверждена.")
    }
    return DurableForkHandoffResult(
      outcome: .handoffAccepted,
      node: node.updating(upstreamOID: integrationOID),
      passport: handoffPassport
    )
  }
}

extension DurableForkSubnodeRuntime {
  public func publishCandidate(
    _ request: DurableForkCandidateRequest
  ) throws -> DurableForkCandidateResult {
    let node = request.node
    guard try verifyRemoteBindings(node) else {
      return DurableForkCandidateResult(
        outcome: .remoteMismatch,
        node: nil,
        candidate: nil,
        integration: nil
      )
    }
    guard
      try DurableForkValidation.refOID(node.liveRef, repository: node.forkBareURL, git: git)
        == node.forkOID,
      try git.text(["rev-parse", "--verify", "HEAD^{commit}"], at: node.liveCloneURL)
        == node.forkOID,
      try git.text(["symbolic-ref", "-q", "HEAD"], at: node.liveCloneURL) == node.liveRef,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: node.liveCloneURL)
        .isEmpty
    else {
      return DurableForkCandidateResult(
        outcome: .oidMismatch,
        node: nil,
        candidate: nil,
        integration: nil
      )
    }
    let parentBefore = try DurableForkValidation.refOID(
      node.assemblyRef, repository: node.assemblyBareURL, git: git)
    let snapshotBefore = try git.text(
      ["rev-parse", "--verify", "HEAD^{commit}"], at: node.snapshotURL)
    let sourceRequest = WritingSubnodeExecutionRequest(
      episodeID: request.episodeID,
      stepGenerationID: request.stepGenerationID,
      cardID: request.cardID,
      stepID: request.stepID,
      runID: request.runID,
      subnodeID: node.nodeID,
      repositoryID: node.forkRepositoryID,
      sourceCheckoutURL: node.liveCloneURL,
      executionRootURL: request.executionRootURL,
      targetRef: node.liveRef,
      baseOID: node.forkOID,
      commitMessage: request.commitMessage,
      writes: request.writes
    )
    let candidate = try writingExecutor.execute(
      workPackageData: request.workPackageData,
      workspaceRoot: node.liveCloneURL,
      request: sourceRequest
    )
    guard candidate.outcome == .candidateCommitted,
      let candidatePassport = candidate.passport,
      let candidatePassportSHA256 = candidate.passportSHA256
    else {
      return DurableForkCandidateResult(
        outcome: .invalidRequest,
        node: nil,
        candidate: candidate,
        integration: nil
      )
    }
    let integrationRequest = CandidateCommitIntegrationRequest(
      attemptID: request.attemptID,
      ownerID: request.ownerID,
      repositoryID: node.forkRepositoryID,
      targetRepositoryURL: node.forkBareURL,
      integrationRootURL: request.integrationRootURL,
      targetRef: node.liveRef,
      expectedTargetOID: node.forkOID,
      commitMessage: request.integrationCommitMessage,
      candidates: [
        CandidateCommitReference(
          runID: request.runID,
          executionRootURL: request.executionRootURL,
          expectedCommitOID: candidatePassport.commitOID,
          expectedPassportSHA256: candidatePassportSHA256
        )
      ],
      checkIDs: request.checkIDs
    )
    let integration = try candidateIntegrator.integrate(integrationRequest)
    guard [.integrated, .alreadyIntegrated].contains(integration.outcome),
      let integrationOID = integration.integrationOID
    else {
      return DurableForkCandidateResult(
        outcome: integration.outcome == .targetChanged || integration.outcome == .casLost
          ? .oidMismatch : .conflict,
        node: nil,
        candidate: candidate,
        integration: integration
      )
    }

    _ = try git.data(
      ["fetch", "--quiet", "--no-tags", "origin", node.liveRef],
      at: node.liveCloneURL
    )
    guard try git.text(["rev-parse", "FETCH_HEAD"], at: node.liveCloneURL) == integrationOID else {
      throw WritingSubnodeExecutorError.gitFailed("Живой клон не получил новую вершину fork.")
    }
    let liveUpdate = Data(
      "start\nupdate \(node.liveRef) \(integrationOID) \(node.forkOID)\nprepare\ncommit\n".utf8
    )
    _ = try git.data(["update-ref", "--stdin"], at: node.liveCloneURL, input: liveUpdate)
    _ = try git.data(["reset", "--hard", "--quiet", integrationOID], at: node.liveCloneURL)
    guard
      try DurableForkValidation.refOID(
        node.assemblyRef, repository: node.assemblyBareURL, git: git) == parentBefore,
      try git.text(["rev-parse", "--verify", "HEAD^{commit}"], at: node.snapshotURL)
        == snapshotBefore,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: node.snapshotURL)
        .isEmpty
    else {
      throw WritingSubnodeExecutorError.sourceChanged
    }
    return DurableForkCandidateResult(
      outcome: .candidatePublished,
      node: node.updating(forkOID: integrationOID),
      candidate: candidate,
      integration: integration
    )
  }
}

enum DurableForkJSON {
  static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  static func sha256(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

private enum DurableForkToolRunner {
  private static let queueBootstrap =
    "import os,subprocess,sys;"
    + "p=sys.argv[1];r=sys.argv[2];"
    + "e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};"
    + "e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';"
    + "b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);"
    + "sys.argv=[p,*sys.argv[3:],'--repo-root',r];exec(compile(b,p,'exec'))"

  static func runNextStep(
    repoRoot: URL,
    scriptPath: String,
    command: String
  ) throws -> [String: Any] {
    try runJSON(
      arguments: [
        repoRoot.appending(path: scriptPath).path,
        command,
        "--repo-root", repoRoot.path,
        "--json",
      ],
      at: repoRoot)
  }

  static func runQueue(
    repoRoot: URL,
    scriptPath: String,
    arguments: [String]
  ) throws -> [String: Any] {
    try runJSON(
      arguments: ["-I", "-c", queueBootstrap, scriptPath, repoRoot.path]
        + arguments + ["--json"],
      at: repoRoot)
  }

  static func string(_ object: [String: Any]?, _ key: String) -> String? {
    object?[key] as? String
  }

  static func integer(_ object: [String: Any]?, _ key: String) -> Int? {
    (object?[key] as? NSNumber)?.intValue
  }

  static func array(_ object: [String: Any]?, _ key: String) -> [Any]? {
    object?[key] as? [Any]
  }

  private static func runJSON(
    arguments: [String],
    at directory: URL
  ) throws -> [String: Any] {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
      .deletingLastPathComponent()
      .appending(path: "env")
    process.arguments = ["python3"] + arguments
    process.currentDirectoryURL = directory
    var environment = ProcessInfo.processInfo.environment.filter {
      !$0.key.uppercased().hasPrefix("GIT_")
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] = WritingSubnodeSystemRuntime.nullDevicePath
    environment["GIT_NO_REPLACE_OBJECTS"] = "1"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    environment["LC_ALL"] = "C"
    process.environment = environment
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = errors.fileHandleForReading.readDataToEndOfFile()
    guard process.terminationStatus == 0 else {
      let detail = String(decoding: errorData, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      throw WritingSubnodeExecutorError.gitFailed(
        "Локальный FUM-валидатор завершился с кодом \(process.terminationStatus): \(detail)")
    }
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Локальный FUM-валидатор вернул не-JSON-объект.")
    }
    return object
  }
}

enum DurableForkValidation {
  struct QueueIdentity: Equatable {
    let ref: String
    let worktreeID: String
  }

  static let commitEnvironment = [
    "GIT_AUTHOR_NAME": "FUM Durable Fork Runtime",
    "GIT_AUTHOR_EMAIL": "durable-fork@invalid",
    "GIT_AUTHOR_DATE": "2000-01-01T00:00:00Z",
    "GIT_COMMITTER_NAME": "FUM Durable Fork Runtime",
    "GIT_COMMITTER_EMAIL": "durable-fork@invalid",
    "GIT_COMMITTER_DATE": "2000-01-01T00:00:00Z",
  ]

  static func isIdentifier(_ value: String) -> Bool {
    guard (1...160).contains(value.utf8.count),
      let first = value.unicodeScalars.first,
      CharacterSet.alphanumerics.contains(first)
    else { return false }
    return value.unicodeScalars.allSatisfy {
      CharacterSet.alphanumerics.contains($0) || "._:-".unicodeScalars.contains($0)
    }
  }

  static func isOID(_ value: String) -> Bool {
    (value.count == 40 || value.count == 64)
      && value.unicodeScalars.allSatisfy {
        (48...57).contains($0.value) || (97...102).contains($0.value)
      }
  }

  static func isSHA256(_ value: String) -> Bool {
    value.hasPrefix("sha256:") && value.count == 71 && isOID(String(value.dropFirst(7)))
      && value.dropFirst(7).count == 64
  }

  static func isStepCardID(_ value: String) -> Bool {
    value.count == "FUM-STEP-0000".count && value.hasPrefix("FUM-STEP-")
      && value.dropFirst("FUM-STEP-".count).allSatisfy(\.isNumber)
  }

  static func isVersionedStepID(_ value: String) -> Bool {
    guard (3...128).contains(value.utf8.count),
      let suffixRange = value.range(of: "-v", options: .backwards),
      suffixRange.lowerBound != value.startIndex
    else { return false }
    let stem = value[..<suffixRange.lowerBound]
    let version = value[suffixRange.upperBound...]
    guard version.first.map({ $0 != "0" }) == true,
      version.allSatisfy(\.isNumber),
      let first = stem.first,
      first.isLowercase || first.isNumber
    else { return false }
    return stem.allSatisfy { $0.isLowercase || $0.isNumber || "._-".contains($0) }
  }

  static func isCanonicalUnrecenciedMarkdown(_ data: Data) -> Bool {
    guard let text = String(data: data, encoding: .utf8), text.hasSuffix("\n"),
      !text.contains("FUM-MD-RECENCY"),
      let lastContentScalar = text.dropLast().unicodeScalars.last
    else { return false }
    return !CharacterSet.whitespacesAndNewlines.contains(lastContentScalar)
  }

  static func queueIdentity(
    repoRoot: URL,
    namespace: String,
    git: CandidateIntegrationGit
  ) throws -> QueueIdentity {
    let gitDirectory = try git.text(["rev-parse", "--absolute-git-dir"], at: repoRoot)
    let worktreeID = String(DurableForkJSON.sha256(Data(gitDirectory.utf8)).dropFirst(7))
    return QueueIdentity(ref: "\(namespace)/\(worktreeID)", worktreeID: worktreeID)
  }

  static func tomlString(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
  }

  static func unicodeEquivalent(_ lhs: String?, _ rhs: String) -> Bool {
    lhs?.precomposedStringWithCanonicalMapping
      == rhs.precomposedStringWithCanonicalMapping
  }

  static func isBranchRef(_ value: String) -> Bool {
    value.hasPrefix("refs/heads/") && isDirectRef(value)
  }

  static func isDirectRef(_ value: String) -> Bool {
    let forbiddenScalarValues: Set<UInt32> = [126, 94, 58, 63, 42, 91, 92]
    return value.hasPrefix("refs/") && !value.hasSuffix("/") && !value.contains("..")
      && !value.unicodeScalars.contains(where: {
        CharacterSet.whitespacesAndNewlines.contains($0)
          || forbiddenScalarValues.contains($0.value)
      })
  }

  static func isRelativePath(_ value: String) -> Bool {
    guard !value.isEmpty, value.utf8.count <= 1_024, !value.hasPrefix("/"),
      !value.hasSuffix("/"), !value.contains("\\"), !value.contains("\0")
    else { return false }
    let parts = value.split(separator: "/", omittingEmptySubsequences: false)
    return !parts.isEmpty && parts.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
  }

  static func ensureDirectory(_ url: URL) throws {
    if FileManager.default.fileExists(atPath: url.path) {
      guard WritingSubnodePersistence.isPlainDirectory(url) else {
        throw WritingSubnodeExecutorError.unsafePath("Каталог runtime небезопасен.")
      }
      return
    }
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    guard WritingSubnodePersistence.isPlainDirectory(url) else {
      throw WritingSubnodeExecutorError.unsafePath("Каталог runtime небезопасен.")
    }
  }

  static func requireSeparated(_ urls: [URL]) throws {
    let normalized = urls.map { $0.standardizedFileURL.resolvingSymlinksInPath().path }
    guard Set(normalized).count == normalized.count else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Репозитории, клоны и runtime-каталоги должны иметь разные пути."
      )
    }
  }

  static func isBare(_ repository: URL, git: CandidateIntegrationGit) throws -> Bool {
    try git.text(["rev-parse", "--is-bare-repository"], at: repository) == "true"
  }

  static func refOID(
    _ ref: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> String {
    try git.text(["show-ref", "--verify", "--hash", ref], at: repository)
  }

  static func configureAuthor(_ repository: URL, git: CandidateIntegrationGit) throws {
    _ = try git.data(["config", "user.name", "FUM Durable Fork Runtime"], at: repository)
    _ = try git.data(["config", "user.email", "durable-fork@invalid"], at: repository)
  }

  static func pushCAS(
    newOID: String,
    expectedOID: String,
    ref: String,
    clone: URL,
    git: CandidateIntegrationGit
  ) throws -> Bool {
    let result = try git.run(
      [
        "push", "--porcelain", "--force-with-lease=\(ref):\(expectedOID)",
        "origin", "\(newOID):\(ref)",
      ],
      at: clone
    )
    return result.status == 0
  }

  static func sameLocation(_ raw: String, _ expected: URL) -> Bool {
    let location: URL
    if raw.hasPrefix("file:") {
      guard let parsed = URL(string: raw), parsed.isFileURL else { return false }
      location = parsed
    } else if raw.hasPrefix("/") {
      location = URL(fileURLWithPath: raw, isDirectory: true)
    } else {
      return false
    }
    return location.standardizedFileURL.resolvingSymlinksInPath()
      == expected.standardizedFileURL.resolvingSymlinksInPath()
  }

  static func check(
    _ check: DurableForkFileCheck,
    treeOID: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> Bool {
    let blob = try git.data(["cat-file", "blob", "\(treeOID):\(check.path)"], at: repository)
    return DurableForkJSON.sha256(blob) == check.expectedSHA256
  }

  static func gitlink(
    parentOID: String,
    path: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> String? {
    let result = try git.run(
      ["-c", "core.quotePath=false", "ls-tree", parentOID, "--", path], at: repository)
    guard result.status == 0 else { return nil }
    let text = String(decoding: result.output, as: UTF8.self)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let pieces = text.split(separator: "\t", maxSplits: 1).first?.split(separator: " ") ?? []
    guard pieces.count == 3, pieces[0] == "160000", pieces[1] == "commit" else { return nil }
    return String(pieces[2])
  }

  static func containsGitlink(
    treeish: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> Bool {
    let data = try git.data(
      ["-c", "core.quotePath=false", "ls-tree", "-r", "-z", treeish], at: repository)
    return data.split(separator: 0, omittingEmptySubsequences: true).contains { record in
      record.starts(with: Data("160000 commit ".utf8))
    }
  }
}
