import CryptoKit
import Darwin
import Dispatch
import Foundation

public enum CandidateCommitIntegrationOutcome: String, Codable, Equatable, Sendable {
  case integrated
  case alreadyIntegrated = "already_integrated"
  case targetBusy = "target_busy"
  case targetChanged = "target_changed"
  case casLost = "cas_lost"
  case candidateInvalid = "candidate_invalid"
  case mergeConflict = "merge_conflict"
  case checkFailed = "check_failed"
  case resolutionRequired = "resolution_required"
  case secretDetected = "secret_detected"
  case publicationRejected = "publication_rejected"
  case attemptAlreadyExists = "attempt_already_exists"
}

public struct CandidateCommitReference: Equatable, Sendable {
  public let runID: String
  public let executionRootURL: URL
  public let expectedCommitOID: String
  public let expectedPassportSHA256: String

  public init(
    runID: String,
    executionRootURL: URL,
    expectedCommitOID: String,
    expectedPassportSHA256: String
  ) {
    self.runID = runID
    self.executionRootURL = executionRootURL
    self.expectedCommitOID = expectedCommitOID
    self.expectedPassportSHA256 = expectedPassportSHA256
  }
}

public enum CandidateIntegrationCheckSpecification: Codable, Equatable, Sendable {
  case regularFileSHA256(path: String, expectedSHA256: String)
}

public struct CandidateIntegrationCheckRegistry: Sendable {
  private let specifications: [String: CandidateIntegrationCheckSpecification]

  public init(specifications: [String: CandidateIntegrationCheckSpecification] = [:]) {
    self.specifications = specifications
  }

  fileprivate func stableBindings(_ identifiers: [String]) throws -> [CandidateStableCheck] {
    try identifiers.sorted().map { identifier in
      guard let specification = specifications[identifier],
        WritingSubnodeValidation.isIdentifier(identifier),
        Self.isValid(specification)
      else {
        throw WritingSubnodeExecutorError.invalidRequest(
          "Интеграционная проверка не зарегистрирована или некорректна."
        )
      }
      return CandidateStableCheck(
        checkID: identifier,
        specificationSHA256: WritingSubnodeJSON.sha256(
          try WritingSubnodeJSON.encode(specification)
        )
      )
    }
  }

  fileprivate func run(
    identifiers: [String],
    treeOID: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) -> [CandidateIntegrationRecordedCheck] {
    identifiers.sorted().map { identifier in
      guard let specification = specifications[identifier] else {
        return CandidateIntegrationRecordedCheck(
          checkID: identifier,
          specificationSHA256: WritingSubnodeJSON.sha256(
            Data("unregistered-check:\(identifier)".utf8)
          ),
          status: .failed,
          evidence: "checker_not_registered"
        )
      }
      let specificationSHA256 =
        (try? WritingSubnodeJSON.encode(specification)).map(WritingSubnodeJSON.sha256)
        ?? WritingSubnodeJSON.sha256(Data("invalid-check:\(identifier)".utf8))
      do {
        switch specification {
        case .regularFileSHA256(let path, let expectedSHA256):
          let blob = try git.data(
            ["cat-file", "blob", "\(treeOID):\(path)"],
            at: repositoryURL
          )
          let actualSHA256 = WritingSubnodeJSON.sha256(blob)
          return CandidateIntegrationRecordedCheck(
            checkID: identifier,
            specificationSHA256: specificationSHA256,
            status: actualSHA256 == expectedSHA256 ? .passed : .failed,
            evidence: actualSHA256
          )
        }
      } catch {
        return CandidateIntegrationRecordedCheck(
          checkID: identifier,
          specificationSHA256: specificationSHA256,
          status: .failed,
          evidence: "checker_error"
        )
      }
    }
  }

  private static func isValid(_ specification: CandidateIntegrationCheckSpecification) -> Bool {
    switch specification {
    case .regularFileSHA256(let path, let expectedSHA256):
      WritingSubnodeValidation.isRelativePath(path)
        && WritingSubnodeValidation.isSHA256(expectedSHA256)
    }
  }
}

public struct CandidateCommitIntegrationRequest: Sendable {
  public let attemptID: String
  public let ownerID: String
  public let repositoryID: String
  public let targetRepositoryURL: URL
  public let integrationRootURL: URL
  public let targetRef: String
  public let expectedTargetOID: String
  public let commitMessage: String
  public let candidates: [CandidateCommitReference]
  public let checkIDs: [String]
  public let resolverRuleIDs: [String]

  public init(
    attemptID: String,
    ownerID: String,
    repositoryID: String,
    targetRepositoryURL: URL,
    integrationRootURL: URL,
    targetRef: String,
    expectedTargetOID: String,
    commitMessage: String,
    candidates: [CandidateCommitReference],
    checkIDs: [String],
    resolverRuleIDs: [String] = []
  ) {
    self.attemptID = attemptID
    self.ownerID = ownerID
    self.repositoryID = repositoryID
    self.targetRepositoryURL = targetRepositoryURL
    self.integrationRootURL = integrationRootURL
    self.targetRef = targetRef
    self.expectedTargetOID = expectedTargetOID
    self.commitMessage = commitMessage
    self.candidates = candidates
    self.checkIDs = checkIDs
    self.resolverRuleIDs = resolverRuleIDs
  }
}

public struct CandidateIntegrationRecordedCheck: Codable, Equatable, Sendable {
  public let checkID: String
  public let specificationSHA256: String
  public let status: WritingSubnodeCheckStatus
  public let evidence: String

  enum CodingKeys: String, CodingKey {
    case checkID = "check_id"
    case specificationSHA256 = "specification_sha256"
    case status
    case evidence
  }
}

public struct CandidateIntegrationPassportCandidate: Codable, Equatable, Sendable {
  public let runID: String
  public let commitOID: String
  public let passportSHA256: String
  public let parentOID: String
  public let treeOID: String

  enum CodingKeys: String, CodingKey {
    case runID = "run_id"
    case commitOID = "commit_oid"
    case passportSHA256 = "passport_sha256"
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
  }
}

public struct CandidateCommitIntegrationPassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let attemptID: String
  public let ownerID: String
  public let repositoryID: String
  public let targetRef: String
  public let expectedTargetOID: String
  public let integrationTreeOID: String
  public let integrationOID: String
  public let integrationRef: String
  public let requestSHA256: String
  public let candidates: [CandidateIntegrationPassportCandidate]
  public let resolverRegistryIdentity: String
  public let resolverRegistryVersion: Int
  public let resolverRules: [CandidateConflictResolverBinding]
  public let resolutions: [CandidateConflictResolutionRecord]
  public let checks: [CandidateIntegrationRecordedCheck]
  public let repeatedChecks: [CandidateIntegrationRecordedCheck]

  public var candidateOIDs: [String] { candidates.map(\.commitOID) }

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case attemptID = "attempt_id"
    case ownerID = "owner_id"
    case repositoryID = "repository_id"
    case targetRef = "target_ref"
    case expectedTargetOID = "expected_target_oid"
    case integrationTreeOID = "integration_tree_oid"
    case integrationOID = "integration_oid"
    case integrationRef = "integration_ref"
    case requestSHA256 = "request_sha256"
    case candidates
    case resolverRegistryIdentity = "resolver_registry_identity"
    case resolverRegistryVersion = "resolver_registry_version"
    case resolverRules = "resolver_rules"
    case resolutions
    case checks
    case repeatedChecks = "repeated_checks"
  }

  public func canonicalJSONData() throws -> Data {
    try WritingSubnodeJSON.encode(self)
  }
}

public struct CandidateCommitIntegrationResult: Sendable {
  public let outcome: CandidateCommitIntegrationOutcome
  public let integrationOID: String?
  public let passport: CandidateCommitIntegrationPassport?
  public let passportCanonicalJSON: Data?
  public let passportSHA256: String?
  public let diagnostic: CandidateResolutionDiagnostic?
  public let diagnosticCanonicalJSON: Data?
  public let diagnosticSHA256: String?
  public let targetUnchanged: Bool

  fileprivate init(
    outcome: CandidateCommitIntegrationOutcome,
    passport: CandidateCommitIntegrationPassport? = nil,
    diagnostic: CandidateResolutionDiagnostic? = nil,
    targetUnchanged: Bool = true
  ) {
    self.outcome = outcome
    self.passport = passport
    integrationOID = passport?.integrationOID
    passportCanonicalJSON = try? passport?.canonicalJSONData()
    passportSHA256 = passportCanonicalJSON.map(WritingSubnodeJSON.sha256)
    self.diagnostic = diagnostic
    diagnosticCanonicalJSON = try? diagnostic?.canonicalJSONData()
    diagnosticSHA256 = diagnosticCanonicalJSON.map(WritingSubnodeJSON.sha256)
    self.targetUnchanged = targetUnchanged
  }
}

struct CandidateCommitIntegratorHooks: Sendable {
  let afterTargetLockAcquired: (@Sendable () throws -> Void)?
  let beforeCompareAndSwap: (@Sendable () throws -> Void)?
  let afterCompareAndSwap: (@Sendable () throws -> Void)?

  init(
    afterTargetLockAcquired: (@Sendable () throws -> Void)? = nil,
    beforeCompareAndSwap: (@Sendable () throws -> Void)? = nil,
    afterCompareAndSwap: (@Sendable () throws -> Void)? = nil
  ) {
    self.afterTargetLockAcquired = afterTargetLockAcquired
    self.beforeCompareAndSwap = beforeCompareAndSwap
    self.afterCompareAndSwap = afterCompareAndSwap
  }
}

public struct CandidateCommitIntegrator: Sendable {
  private let checkRegistry: CandidateIntegrationCheckRegistry
  private let resolverRegistry: CandidateConflictResolverRegistry
  private let hooks: CandidateCommitIntegratorHooks

  public init(
    checkRegistry: CandidateIntegrationCheckRegistry = CandidateIntegrationCheckRegistry(),
    resolverRegistry: CandidateConflictResolverRegistry = CandidateConflictResolverRegistry()
  ) {
    self.checkRegistry = checkRegistry
    self.resolverRegistry = resolverRegistry
    hooks = CandidateCommitIntegratorHooks()
  }

  init(
    checkRegistry: CandidateIntegrationCheckRegistry,
    resolverRegistry: CandidateConflictResolverRegistry = CandidateConflictResolverRegistry(),
    hooks: CandidateCommitIntegratorHooks
  ) {
    self.checkRegistry = checkRegistry
    self.resolverRegistry = resolverRegistry
    self.hooks = hooks
  }

  public func integrate(
    _ request: CandidateCommitIntegrationRequest
  ) throws -> CandidateCommitIntegrationResult {
    let stableChecks = try checkRegistry.stableBindings(request.checkIDs)
    let stableResolverRules = try resolverRegistry.stableBindings(request.resolverRuleIDs)
    try CandidateIntegrationValidation.validate(
      request,
      stableChecks: stableChecks,
      stableResolverRules: stableResolverRules
    )
    if let messageOutcome = WritingSubnodeValidation.publicationOutcome(
      Data(request.commitMessage.utf8)
    ) {
      return CandidateCommitIntegrationResult(
        outcome: messageOutcome == .secretDetected ? .secretDetected : .publicationRejected
      )
    }
    let git = CandidateIntegrationGit()
    let targetURL = request.targetRepositoryURL.standardizedFileURL.resolvingSymlinksInPath()
    let integrationRootURL =
      request.integrationRootURL.standardizedFileURL.resolvingSymlinksInPath()
    try CandidateIntegrationValidation.validateLocations(
      targetURL: targetURL,
      integrationRootURL: integrationRootURL
    )
    try CandidateIntegrationValidation.validateCandidateLocations(
      request.candidates,
      targetURL: targetURL,
      integrationRootURL: integrationRootURL
    )
    try CandidateIntegrationValidation.validateBareTarget(targetURL, git: git)
    try WritingSubnodeValidation.validateRef(request.targetRef, git: WritingSubnodeGit())
    try CandidateIntegrationValidation.validateObjectFormat(
      oid: request.expectedTargetOID,
      repositoryURL: targetURL,
      git: git
    )
    try CandidateIntegrationValidation.validateDirectRef(
      request.targetRef,
      repositoryURL: targetURL,
      git: git
    )

    try WritingSubnodePersistence.ensurePlainDirectory(integrationRootURL)
    let locksURL = targetURL.appending(
      path: "fum-integration-locks",
      directoryHint: .isDirectory
    )
    let attemptsURL = integrationRootURL.appending(path: "attempts", directoryHint: .isDirectory)
    try WritingSubnodePersistence.ensurePlainDirectory(locksURL)
    try WritingSubnodePersistence.ensurePlainDirectory(attemptsURL)
    let lockName = CandidateIntegrationValidation.targetLockName(targetRef: request.targetRef)
    guard
      let targetLock = try WritingSubnodePersistence.acquireRunLock(
        at: locksURL.appending(path: "\(lockName).lock")
      )
    else {
      return CandidateCommitIntegrationResult(outcome: .targetBusy)
    }
    defer { targetLock.release() }
    try hooks.afterTargetLockAcquired?()

    let stableRequest = CandidateStableRequest(
      schemaVersion: 2,
      attemptID: request.attemptID,
      ownerID: request.ownerID,
      repositoryID: request.repositoryID,
      targetRef: request.targetRef,
      expectedTargetOID: request.expectedTargetOID,
      commitMessage: request.commitMessage,
      candidates: request.candidates.sorted {
        $0.expectedCommitOID < $1.expectedCommitOID
      }.map {
        CandidateStableReference(
          runID: $0.runID,
          expectedCommitOID: $0.expectedCommitOID,
          expectedPassportSHA256: $0.expectedPassportSHA256
        )
      },
      checks: stableChecks,
      resolverRegistryIdentity: CandidateConflictResolverRegistry.registryIdentity,
      resolverRegistryVersion: CandidateConflictResolverRegistry.registryVersion,
      resolverRules: stableResolverRules
    )
    let requestSHA256 = WritingSubnodeJSON.sha256(
      try WritingSubnodeJSON.encode(stableRequest)
    )
    let attemptURL = attemptsURL.appending(path: request.attemptID, directoryHint: .isDirectory)
    let requestHashURL = attemptURL.appending(path: "request.sha256")
    let preparedURL = attemptURL.appending(path: "prepared.json")
    let receiptURL = attemptURL.appending(path: "result.json")
    let diagnosticURL = attemptURL.appending(path: "resolution-required.json")
    let cloneURL = attemptURL.appending(path: "clone", directoryHint: .isDirectory)
    var replayingDiagnostic = false

    if WritingSubnodePersistence.pathExists(attemptURL) {
      guard WritingSubnodePersistence.isPlainDirectory(attemptURL),
        try WritingSubnodePersistence.readStableUTF8RegularFile(
          at: requestHashURL,
          maximumBytes: 128
        ) == requestSHA256
      else {
        return CandidateCommitIntegrationResult(outcome: .attemptAlreadyExists)
      }
      if WritingSubnodePersistence.pathExists(diagnosticURL) {
        guard !WritingSubnodePersistence.pathExists(preparedURL),
          !WritingSubnodePersistence.pathExists(receiptURL)
        else {
          throw WritingSubnodeExecutorError.persistenceFailed(
            "Попытка одновременно хранит диагностику и подготовленный результат."
          )
        }
        guard
          try targetOID(request.targetRef, targetURL: targetURL, git: git)
            == request.expectedTargetOID
        else {
          return CandidateCommitIntegrationResult(outcome: .targetChanged)
        }
        _ = try loadDiagnostic(
          at: diagnosticURL,
          request: request,
          repositoryURL: cloneURL,
          git: git
        )
        replayingDiagnostic = true
      } else if WritingSubnodePersistence.pathExists(receiptURL) {
        return try recoverCompletedAttempt(
          request: request,
          requestSHA256: requestSHA256,
          stableChecks: stableChecks,
          stableResolverRules: stableResolverRules,
          targetURL: targetURL,
          preparedURL: preparedURL,
          receiptURL: receiptURL,
          git: git
        )
      } else if WritingSubnodePersistence.pathExists(preparedURL) {
        return try resumePreparedAttempt(
          request: request,
          requestSHA256: requestSHA256,
          stableChecks: stableChecks,
          stableResolverRules: stableResolverRules,
          targetURL: targetURL,
          cloneURL: cloneURL,
          preparedURL: preparedURL,
          receiptURL: receiptURL,
          git: git
        )
      } else {
        try WritingSubnodePersistence.archiveIncompleteCloneIfPresent(cloneURL, in: attemptURL)
      }
    } else {
      guard try WritingSubnodePersistence.reserveDirectory(attemptURL) else {
        return CandidateCommitIntegrationResult(outcome: .attemptAlreadyExists)
      }
      try WritingSubnodePersistence.persistExclusive(
        Data(requestSHA256.utf8),
        at: requestHashURL
      )
    }

    guard
      try targetOID(request.targetRef, targetURL: targetURL, git: git)
        == request.expectedTargetOID
    else {
      return CandidateCommitIntegrationResult(outcome: .targetChanged)
    }

    let recovered: [RecoveredIntegrationCandidate]
    do {
      recovered = try recoverCandidates(
        request.candidates,
        request: request,
        targetURL: targetURL,
        git: git
      )
    } catch {
      return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
    }
    guard let commonParent = recovered.first?.passport.parentOID,
      recovered.allSatisfy({ $0.passport.parentOID == commonParent }),
      !CandidateIntegrationValidation.hasNormalizedPathCollision(
        recovered.flatMap(\.passport.actualPaths)
      ),
      try git.succeeds(
        ["merge-base", "--is-ancestor", commonParent, request.expectedTargetOID],
        at: targetURL
      )
    else {
      return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
    }

    if replayingDiagnostic {
      _ = try? git.run(["merge", "--abort"], at: cloneURL)
      _ = try git.data(["reset", "--hard", request.expectedTargetOID], at: cloneURL)
      guard
        try recovered.allSatisfy({ candidate in
          try git.text(
            ["cat-file", "-t", candidate.passport.commitOID],
            at: cloneURL
          ) == "commit"
        })
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Клон диагностической попытки потерял входной commit."
        )
      }
    } else {
      try cloneTarget(targetURL: targetURL, cloneURL: cloneURL, attemptURL: attemptURL, git: git)
      for candidate in recovered {
        let fetch = try git.run(
          [
            "fetch", "--quiet", "--no-tags", "--no-write-fetch-head",
            candidate.cloneURL.path, candidate.passport.resultRef,
          ],
          at: cloneURL
        )
        guard fetch.status == 0,
          try git.text(
            ["cat-file", "-t", candidate.passport.commitOID],
            at: cloneURL
          ) == "commit"
        else {
          return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
        }
      }
    }
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedTargetOID],
      at: cloneURL
    )

    let candidateOIDs = recovered.map(\.passport.commitOID)
    guard
      try !CandidateIntegrationValidation.containsMergeAttributes(
        in: [request.expectedTargetOID] + candidateOIDs,
        repositoryURL: cloneURL,
        git: git
      )
    else {
      return CandidateCommitIntegrationResult(outcome: .publicationRejected)
    }
    if !replayingDiagnostic {
      try retainInputCommits(
        request: request,
        commonParentOID: commonParent,
        candidateOIDs: candidateOIDs,
        cloneURL: cloneURL,
        git: git
      )
    }
    let mergeResult = try mergeCandidates(
      request: request,
      stableResolverRules: stableResolverRules,
      commonParentOID: commonParent,
      recovered: recovered,
      cloneURL: cloneURL,
      git: git
    )
    let treeOID: String
    let resolutions: [CandidateConflictResolutionRecord]
    switch mergeResult {
    case .resolved(let resolvedTreeOID, let recordedResolutions):
      treeOID = resolvedTreeOID
      resolutions = recordedResolutions
    case .resolutionRequired(let diagnostic):
      try persistDiagnostic(diagnostic, at: diagnosticURL)
      return CandidateCommitIntegrationResult(
        outcome: .resolutionRequired,
        diagnostic: diagnostic
      )
    }
    let changedPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        request.expectedTargetOID, treeOID, "--",
      ],
      at: cloneURL
    ).sorted()
    let finalTreePaths = try git.nulStrings(
      ["ls-tree", "-r", "--name-only", "-z", treeOID],
      at: cloneURL
    )
    let finalTreeCollisions = CandidateIntegrationValidation.normalizedPathCollisions(
      finalTreePaths
    )
    if !finalTreeCollisions.isEmpty {
      let diagnostic = try makeDiagnostic(
        request: request,
        commonParentOID: commonParent,
        recovered: recovered,
        affectedPaths: finalTreeCollisions,
        issues: finalTreeCollisions.map {
          CandidateResolutionDiagnosticIssue(reason: .semanticConflict, path: $0)
        },
        checks: [],
        repositoryURL: cloneURL,
        git: git
      )
      try persistDiagnostic(diagnostic, at: diagnosticURL)
      return CandidateCommitIntegrationResult(
        outcome: .resolutionRequired,
        diagnostic: diagnostic
      )
    }
    let candidatePaths = Set(recovered.flatMap(\.passport.actualPaths))
    let resolverOutputPaths = Set(stableResolverRules.map(\.path))
    guard !changedPaths.isEmpty,
      Set(changedPaths).isSubset(of: candidatePaths.union(resolverOutputPaths)),
      changedPaths.allSatisfy(WritingSubnodeValidation.isRelativePath)
    else {
      return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
    }
    if changedPaths.contains(where: CandidateIntegrationValidation.isMachineJunk) {
      return CandidateCommitIntegrationResult(outcome: .publicationRejected)
    }
    if let writerOutcome = try WritingSubnodeCandidateAudit.validateTree(
      paths: changedPaths,
      treeOID: treeOID,
      cloneURL: cloneURL,
      git: WritingSubnodeGit()
    ) {
      switch writerOutcome {
      case .secretDetected:
        return CandidateCommitIntegrationResult(outcome: .secretDetected)
      default:
        return CandidateCommitIntegrationResult(outcome: .publicationRejected)
      }
    }
    let finalDiff = try git.data(
      [
        "diff", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        request.expectedTargetOID, treeOID, "--",
      ],
      at: cloneURL
    )
    if let writerOutcome = WritingSubnodeValidation.publicationOutcome(
      finalDiff,
      allowingGitNullDevice: true
    ) {
      return CandidateCommitIntegrationResult(
        outcome: writerOutcome == .secretDetected ? .secretDetected : .publicationRejected
      )
    }

    let checks = checkRegistry.run(
      identifiers: request.checkIDs,
      treeOID: treeOID,
      repositoryURL: cloneURL,
      git: git
    )
    guard checks.allSatisfy({ $0.status == .passed }) else {
      let diagnostic = try makeDiagnostic(
        request: request,
        commonParentOID: commonParent,
        recovered: recovered,
        affectedPaths: changedPaths,
        issues: checkFailureIssues(
          checks,
          resolutions: resolutions,
          changedPaths: changedPaths
        ),
        checks: checks,
        repositoryURL: cloneURL,
        git: git
      )
      try persistDiagnostic(diagnostic, at: diagnosticURL)
      return CandidateCommitIntegrationResult(
        outcome: .resolutionRequired,
        diagnostic: diagnostic
      )
    }

    do {
      let repeatedRecovery = try recoverCandidates(
        request.candidates,
        request: request,
        targetURL: targetURL,
        git: git
      )
      guard repeatedRecovery.map(\.passport.commitOID) == candidateOIDs,
        repeatedRecovery.map(\.passportSHA256) == recovered.map(\.passportSHA256)
      else {
        return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
      }
    } catch {
      return CandidateCommitIntegrationResult(outcome: .candidateInvalid)
    }

    let repeatedChecks = checkRegistry.run(
      identifiers: request.checkIDs,
      treeOID: treeOID,
      repositoryURL: cloneURL,
      git: git
    )
    guard repeatedChecks.allSatisfy({ $0.status == .passed }) else {
      let diagnostic = try makeDiagnostic(
        request: request,
        commonParentOID: commonParent,
        recovered: recovered,
        affectedPaths: changedPaths,
        issues: checkFailureIssues(
          repeatedChecks,
          resolutions: resolutions,
          changedPaths: changedPaths
        ),
        checks: repeatedChecks,
        repositoryURL: cloneURL,
        git: git
      )
      try persistDiagnostic(diagnostic, at: diagnosticURL)
      return CandidateCommitIntegrationResult(
        outcome: .resolutionRequired,
        diagnostic: diagnostic
      )
    }

    var commitArguments = ["commit-tree", treeOID, "-p", request.expectedTargetOID]
    for candidateOID in candidateOIDs {
      commitArguments += ["-p", candidateOID]
    }
    let integrationOID = try git.text(
      commitArguments,
      at: cloneURL,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: CandidateIntegrationGit.commitEnvironment
    )
    guard
      try CandidateIntegrationValidation.parents(
        of: integrationOID,
        repositoryURL: cloneURL,
        git: git
      ) == [request.expectedTargetOID] + candidateOIDs
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Интеграционный commit получил неожиданную родословную."
      )
    }
    guard !WritingSubnodePersistence.pathExists(diagnosticURL) else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Диагностическая попытка не может стать подготовленной."
      )
    }
    let integrationRef =
      "refs/fum/integrations/\(request.repositoryID)/\(CandidateIntegrationValidation.targetLockName(targetRef: request.targetRef))/\(request.attemptID)"
    let retainTransaction = Data(
      "start\ncreate \(integrationRef) \(integrationOID)\nprepare\ncommit\n".utf8
    )
    let retained = try git.run(
      ["update-ref", "--stdin"],
      at: cloneURL,
      input: retainTransaction
    )
    guard retained.status == 0,
      try git.text(["rev-parse", "--verify", integrationRef], at: cloneURL)
        == integrationOID
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Не удалось закрепить интеграционный commit прямой ссылкой."
      )
    }
    let passport = CandidateCommitIntegrationPassport(
      schemaIdentity: "fum.candidate-commit.integration-passport",
      schemaVersion: 2,
      attemptID: request.attemptID,
      ownerID: request.ownerID,
      repositoryID: request.repositoryID,
      targetRef: request.targetRef,
      expectedTargetOID: request.expectedTargetOID,
      integrationTreeOID: treeOID,
      integrationOID: integrationOID,
      integrationRef: integrationRef,
      requestSHA256: requestSHA256,
      candidates: recovered.map {
        CandidateIntegrationPassportCandidate(
          runID: $0.passport.runID,
          commitOID: $0.passport.commitOID,
          passportSHA256: $0.passportSHA256,
          parentOID: $0.passport.parentOID,
          treeOID: $0.passport.treeOID
        )
      },
      resolverRegistryIdentity: CandidateConflictResolverRegistry.registryIdentity,
      resolverRegistryVersion: CandidateConflictResolverRegistry.registryVersion,
      resolverRules: stableResolverRules,
      resolutions: resolutions,
      checks: checks,
      repeatedChecks: repeatedChecks
    )
    let canonicalPassport = try passport.canonicalJSONData()
    guard WritingSubnodeValidation.publicationOutcome(canonicalPassport) == nil else {
      return CandidateCommitIntegrationResult(outcome: .publicationRejected)
    }
    try WritingSubnodePersistence.persistExclusive(canonicalPassport, at: preparedURL)
    return try publishPrepared(
      passport,
      request: request,
      targetURL: targetURL,
      cloneURL: cloneURL,
      receiptURL: receiptURL,
      git: git,
      integratedOutcome: .integrated
    )
  }

  private func checkFailureIssues(
    _ checks: [CandidateIntegrationRecordedCheck],
    resolutions: [CandidateConflictResolutionRecord],
    changedPaths: [String]
  ) -> [CandidateResolutionDiagnosticIssue] {
    checks.filter { $0.status == .failed }.flatMap { check in
      let matchingResolutions = resolutions.filter {
        $0.requiredCheckIDs.contains(check.checkID)
      }
      if matchingResolutions.isEmpty {
        return [
          CandidateResolutionDiagnosticIssue(
            reason: .checkFailed,
            path: changedPaths.first ?? "integration",
            checkID: check.checkID
          )
        ]
      }
      return matchingResolutions.map { resolution in
        CandidateResolutionDiagnosticIssue(
          reason: .checkFailed,
          path: resolution.path,
          matchingRuleIDs: [resolution.ruleID],
          ruleID: resolution.ruleID,
          checkID: check.checkID
        )
      }
    }
  }

  private func mergeCandidates(
    request: CandidateCommitIntegrationRequest,
    stableResolverRules: [CandidateConflictResolverBinding],
    commonParentOID: String,
    recovered: [RecoveredIntegrationCandidate],
    cloneURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateMergeResolutionResult {
    let candidateOIDs = recovered.map(\.passport.commitOID)
    let resolverPathAmbiguities = try resolverPathAmbiguities(
      stableResolverRules,
      candidatePaths: recovered.flatMap(\.passport.actualPaths)
    )
    if !resolverPathAmbiguities.isEmpty {
      let affectedPaths = resolverPathAmbiguities.flatMap(\.paths)
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: affectedPaths,
          issues: resolverPathAmbiguities.flatMap { ambiguity in
            ambiguity.paths.map { path in
              CandidateResolutionDiagnosticIssue(
                reason: .ambiguousRule,
                path: path,
                matchingRuleIDs: ambiguity.ruleIDs
              )
            }
          },
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }
    var currentOID = request.expectedTargetOID
    var processedCandidateOIDs: [String] = []

    for candidateOID in candidateOIDs {
      let merge = try git.run(
        ["merge", "--no-commit", "--no-ff", "--no-edit", candidateOID],
        at: cloneURL,
        additionalEnvironment: CandidateIntegrationGit.commitEnvironment
      )
      processedCandidateOIDs.append(candidateOID)
      if merge.status != 0 {
        let unresolvedPaths = try git.nulStrings(
          ["diff", "--name-only", "--diff-filter=U", "-z", "--"],
          at: cloneURL
        ).sorted()
        guard !unresolvedPaths.isEmpty else {
          let diagnosticPath = stableResolverRules.first?.path ?? "integration"
          let diagnostic = try makeDiagnostic(
            request: request,
            commonParentOID: commonParentOID,
            recovered: recovered,
            affectedPaths: [diagnosticPath],
            issues: [
              CandidateResolutionDiagnosticIssue(
                reason: .resolverFailed,
                path: diagnosticPath
              )
            ],
            checks: [],
            repositoryURL: cloneURL,
            git: git
          )
          return .resolutionRequired(diagnostic)
        }

        var issues: [CandidateResolutionDiagnosticIssue] = []
        for path in unresolvedPaths {
          let matchingRules = stableResolverRules.filter { $0.path == path }
          guard matchingRules.count == 1, let binding = matchingRules.first else {
            issues.append(
              CandidateResolutionDiagnosticIssue(
                reason: matchingRules.isEmpty ? .unknownPath : .ambiguousRule,
                path: path,
                matchingRuleIDs: matchingRules.map(\.ruleID)
              )
            )
            continue
          }
          if !Set(binding.requiredCheckIDs).isSubset(of: Set(request.checkIDs)) {
            issues.append(
              CandidateResolutionDiagnosticIssue(
                reason: .preconditionFailed,
                path: path,
                matchingRuleIDs: [binding.ruleID],
                ruleID: binding.ruleID
              )
            )
            continue
          }
          do {
            let output = try resolutionOutput(
              for: binding,
              request: request,
              commonParentOID: commonParentOID,
              candidateOIDs: processedCandidateOIDs,
              cloneURL: cloneURL,
              git: git
            )
            try applyResolutionOutput(output, at: cloneURL, git: git)
          } catch let error as CandidateConflictResolverError {
            issues.append(
              error.issue
                ?? CandidateResolutionDiagnosticIssue(
                  reason: .resolverFailed,
                  path: path,
                  matchingRuleIDs: [binding.ruleID],
                  ruleID: binding.ruleID
                )
            )
          } catch {
            issues.append(
              CandidateResolutionDiagnosticIssue(
                reason: .preconditionFailed,
                path: path,
                matchingRuleIDs: [binding.ruleID],
                ruleID: binding.ruleID
              )
            )
          }
        }
        if !issues.isEmpty {
          return .resolutionRequired(
            try makeDiagnostic(
              request: request,
              commonParentOID: commonParentOID,
              recovered: recovered,
              affectedPaths: unresolvedPaths,
              issues: issues,
              checks: [],
              repositoryURL: cloneURL,
              git: git
            )
          )
        }
        let remaining = try git.data(["ls-files", "-u", "-z"], at: cloneURL)
        guard remaining.isEmpty else {
          return .resolutionRequired(
            try makeDiagnostic(
              request: request,
              commonParentOID: commonParentOID,
              recovered: recovered,
              affectedPaths: unresolvedPaths,
              issues: unresolvedPaths.map {
                CandidateResolutionDiagnosticIssue(reason: .resolverFailed, path: $0)
              },
              checks: [],
              repositoryURL: cloneURL,
              git: git
            )
          )
        }
      }

      let intermediateTreeOID = try git.text(["write-tree"], at: cloneURL)
      let intermediateOID = try git.text(
        ["commit-tree", intermediateTreeOID, "-p", currentOID, "-p", candidateOID],
        at: cloneURL,
        input: Data("FUM deterministic integration stage\n".utf8),
        additionalEnvironment: CandidateIntegrationGit.commitEnvironment
      )
      _ = try git.data(["reset", "--hard", intermediateOID], at: cloneURL)
      currentOID = intermediateOID
    }

    let selectedPaths = stableResolverRules.map(\.path)
    let duplicatePaths = Dictionary(grouping: stableResolverRules, by: \.path)
      .filter { $0.value.count > 1 }
    if !duplicatePaths.isEmpty {
      let issues = duplicatePaths.keys.sorted().map { path in
        CandidateResolutionDiagnosticIssue(
          reason: .ambiguousRule,
          path: path,
          matchingRuleIDs: duplicatePaths[path, default: []].map(\.ruleID)
        )
      }
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: Array(duplicatePaths.keys),
          issues: issues,
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }
    let missingCheckRules = stableResolverRules.filter {
      !Set($0.requiredCheckIDs).isSubset(of: Set(request.checkIDs))
    }
    if !missingCheckRules.isEmpty {
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: missingCheckRules.map(\.path),
          issues: missingCheckRules.map {
            CandidateResolutionDiagnosticIssue(
              reason: .preconditionFailed,
              path: $0.path,
              matchingRuleIDs: [$0.ruleID],
              ruleID: $0.ruleID
            )
          },
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }

    let firstPass: CandidateResolverPassResult
    do {
      firstPass = try applySelectedResolvers(
        stableResolverRules,
        request: request,
        commonParentOID: commonParentOID,
        candidateOIDs: candidateOIDs,
        cloneURL: cloneURL,
        git: git
      )
    } catch let error as CandidateConflictResolverError {
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: selectedPaths,
          issues: [
            error.issue
              ?? CandidateResolutionDiagnosticIssue(
                reason: .resolverFailed,
                path: selectedPaths.first ?? "integration"
              )
          ],
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    } catch {
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: selectedPaths,
          issues: selectedPaths.map {
            CandidateResolutionDiagnosticIssue(reason: .preconditionFailed, path: $0)
          },
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }

    let secondPass: CandidateResolverPassResult
    do {
      secondPass = try applySelectedResolvers(
        stableResolverRules,
        request: request,
        commonParentOID: commonParentOID,
        candidateOIDs: candidateOIDs,
        cloneURL: cloneURL,
        git: git
      )
    } catch let error as CandidateConflictResolverError {
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: selectedPaths,
          issues: [
            error.issue
              ?? CandidateResolutionDiagnosticIssue(
                reason: .resolverFailed,
                path: selectedPaths.first ?? "integration"
              )
          ],
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }
    guard firstPass == secondPass else {
      return .resolutionRequired(
        try makeDiagnostic(
          request: request,
          commonParentOID: commonParentOID,
          recovered: recovered,
          affectedPaths: selectedPaths,
          issues: selectedPaths.map {
            CandidateResolutionDiagnosticIssue(reason: .resolverFailed, path: $0)
          },
          checks: [],
          repositoryURL: cloneURL,
          git: git
        )
      )
    }
    return .resolved(
      treeOID: firstPass.treeOID,
      resolutions: firstPass.resolutions
    )
  }

  private func applySelectedResolvers(
    _ bindings: [CandidateConflictResolverBinding],
    request: CandidateCommitIntegrationRequest,
    commonParentOID: String,
    candidateOIDs: [String],
    cloneURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateResolverPassResult {
    var resolutions: [CandidateConflictResolutionRecord] = []
    for binding in bindings {
      let output = try resolutionOutput(
        for: binding,
        request: request,
        commonParentOID: commonParentOID,
        candidateOIDs: candidateOIDs,
        cloneURL: cloneURL,
        git: git
      )
      try applyResolutionOutput(output, at: cloneURL, git: git)
      resolutions.append(output.record)
    }
    return CandidateResolverPassResult(
      treeOID: try git.text(["write-tree"], at: cloneURL),
      resolutions: resolutions
    )
  }

  private func resolutionOutput(
    for binding: CandidateConflictResolverBinding,
    request: CandidateCommitIntegrationRequest,
    commonParentOID: String,
    candidateOIDs: [String],
    cloneURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateConflictResolutionOutput {
    guard let specification = resolverRegistry.specification(for: binding.ruleID) else {
      throw CandidateConflictResolverError.invalidRule(
        "Resolver-правило исчезло из реестра."
      )
    }
    switch specification {
    case .rebuildDerivedManifest(_, _, let sourcePaths, _, _, _):
      var sources: [String: Data] = [:]
      for path in sourcePaths {
        do {
          sources[path] = try regularBlobAtIndex(
            path: path,
            repositoryURL: cloneURL,
            git: git
          )
        } catch {
          throw CandidateConflictResolverError.resolutionRequired(
            CandidateResolutionDiagnosticIssue(
              reason: .preconditionFailed,
              path: binding.path,
              matchingRuleIDs: [binding.ruleID],
              ruleID: binding.ruleID
            )
          )
        }
      }
      return try resolverRegistry.rebuildDerivedManifest(
        ruleID: binding.ruleID,
        sources: sources
      )
    case .mergeStableRecords:
      let base: Data
      do {
        base = try regularBlob(
          at: commonParentOID,
          path: binding.path,
          repositoryURL: cloneURL,
          git: git
        )
      } catch {
        throw CandidateConflictResolverError.resolutionRequired(
          CandidateResolutionDiagnosticIssue(
            reason: .preconditionFailed,
            path: binding.path,
            matchingRuleIDs: [binding.ruleID],
            ruleID: binding.ruleID
          )
        )
      }
      let revisionInputs =
        [("target", request.expectedTargetOID)]
        + candidateOIDs.enumerated().map {
          (String(format: "candidate-%03d", $0.offset + 1), $0.element)
        }
      let variants: [CandidateConflictResolverVariant]
      do {
        variants = try revisionInputs.map { identifier, oid in
          CandidateConflictResolverVariant(
            identifier: identifier,
            data: try regularBlob(
              at: oid,
              path: binding.path,
              repositoryURL: cloneURL,
              git: git
            )
          )
        }
      } catch {
        throw CandidateConflictResolverError.resolutionRequired(
          CandidateResolutionDiagnosticIssue(
            reason: .preconditionFailed,
            path: binding.path,
            matchingRuleIDs: [binding.ruleID],
            ruleID: binding.ruleID
          )
        )
      }
      return try resolverRegistry.mergeStableRecords(
        ruleID: binding.ruleID,
        base: base,
        variants: variants
      )
    }
  }

  private func resolverPathAmbiguities(
    _ bindings: [CandidateConflictResolverBinding],
    candidatePaths: [String]
  ) throws -> [CandidateResolverPathAmbiguity] {
    struct RulePath {
      let path: String
      let ruleID: String
      let isOutput: Bool
    }

    var rulePaths: [RulePath] = []
    for binding in bindings {
      guard let specification = resolverRegistry.specification(for: binding.ruleID) else {
        throw CandidateConflictResolverError.invalidRule(
          "Resolver-правило исчезло из реестра."
        )
      }
      rulePaths.append(RulePath(path: binding.path, ruleID: binding.ruleID, isOutput: true))
      if case .rebuildDerivedManifest(_, _, let sourcePaths, _, _, _) = specification {
        rulePaths += sourcePaths.map {
          RulePath(path: $0, ruleID: binding.ruleID, isOutput: false)
        }
      }
    }

    var ambiguities: [CandidateResolverPathAmbiguity] = []
    let collidingPaths = CandidateIntegrationValidation.normalizedPathCollisions(
      Array(Set(candidatePaths)).sorted() + rulePaths.map(\.path)
    )
    if !collidingPaths.isEmpty {
      ambiguities.append(
        CandidateResolverPathAmbiguity(
          paths: collidingPaths,
          ruleIDs: Set(
            rulePaths.filter { collidingPaths.contains($0.path) }.map(\.ruleID)
          ).sorted()
        )
      )
    }
    let outputsByPath = Dictionary(grouping: rulePaths.filter(\.isOutput), by: \.path)
    for (path, outputs) in outputsByPath where outputs.count > 1 {
      ambiguities.append(
        CandidateResolverPathAmbiguity(
          paths: [path],
          ruleIDs: Set(outputs.map(\.ruleID)).sorted()
        )
      )
    }
    for output in rulePaths.filter(\.isOutput) {
      let dependencies = rulePaths.filter {
        !$0.isOutput && $0.path == output.path && $0.ruleID != output.ruleID
      }
      if !dependencies.isEmpty {
        ambiguities.append(
          CandidateResolverPathAmbiguity(
            paths: [output.path],
            ruleIDs: Set([output.ruleID] + dependencies.map(\.ruleID)).sorted()
          )
        )
      }
    }
    return Dictionary(
      grouping: ambiguities,
      by: { $0.paths.joined(separator: "\u{0}") + "\u{1}" + $0.ruleIDs.joined(separator: "\u{0}") }
    ).values.compactMap(\.first).sorted {
      let left =
        $0.paths.joined(separator: "\u{0}") + "\u{1}"
        + $0.ruleIDs.joined(separator: "\u{0}")
      let right =
        $1.paths.joined(separator: "\u{0}") + "\u{1}"
        + $1.ruleIDs.joined(separator: "\u{0}")
      return left < right
    }
  }

  private func regularBlobAtIndex(
    path: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> Data {
    let listing = try git.data(["ls-files", "--stage", "-z", "--", path], at: repositoryURL)
    let entries = listing.split(separator: 0, omittingEmptySubsequences: true)
    guard entries.count == 1,
      let tab = entries[0].firstIndex(of: 0x09)
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Канонический источник не имеет однозначной index-записи."
      )
    }
    let metadata = entries[0][..<tab].split(separator: 0x20).map {
      String(decoding: $0, as: UTF8.self)
    }
    let listedPath = String(decoding: entries[0][entries[0].index(after: tab)...], as: UTF8.self)
    guard metadata.count == 3,
      metadata[0] == "100644",
      WritingSubnodeValidation.isObjectID(metadata[1]),
      metadata[2] == "0",
      listedPath == path,
      try git.text(["cat-file", "-t", metadata[1]], at: repositoryURL) == "blob"
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Канонический источник не является обычным файлом."
      )
    }
    return try git.data(["cat-file", "blob", metadata[1]], at: repositoryURL)
  }

  private func regularBlob(
    at revision: String,
    path: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> Data {
    let listing = try git.data(
      ["ls-tree", "-z", revision, "--", path],
      at: repositoryURL
    )
    let entries = listing.split(separator: 0, omittingEmptySubsequences: true)
    guard entries.count == 1,
      let tab = entries[0].firstIndex(of: 0x09)
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Канонический источник не имеет однозначной tree-записи."
      )
    }
    let metadata = entries[0][..<tab].split(separator: 0x20).map {
      String(decoding: $0, as: UTF8.self)
    }
    let listedPath = String(decoding: entries[0][entries[0].index(after: tab)...], as: UTF8.self)
    guard metadata.count == 3,
      metadata[0] == "100644",
      metadata[1] == "blob",
      WritingSubnodeValidation.isObjectID(metadata[2]),
      listedPath == path
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Канонический источник не является обычным файлом."
      )
    }
    return try git.data(["cat-file", "blob", metadata[2]], at: repositoryURL)
  }

  private func applyResolutionOutput(
    _ output: CandidateConflictResolutionOutput,
    at cloneURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    let blobOID = try git.text(
      ["hash-object", "-w", "--stdin"],
      at: cloneURL,
      input: output.data
    )
    _ = try git.data(
      ["update-index", "--add", "--cacheinfo", "100644", blobOID, output.record.path],
      at: cloneURL
    )
  }

  private func retainInputCommits(
    request: CandidateCommitIntegrationRequest,
    commonParentOID: String,
    candidateOIDs: [String],
    cloneURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    let identity = CandidateIntegrationValidation.targetLockName(
      targetRef: "\(request.repositoryID):\(request.attemptID)"
    )
    let prefix = "refs/fum/integration-inputs/\(identity)"
    var transaction = "start\n"
    transaction += "create \(prefix)/common-parent \(commonParentOID)\n"
    transaction += "create \(prefix)/target \(request.expectedTargetOID)\n"
    for (index, oid) in candidateOIDs.enumerated() {
      let candidateRef = [
        prefix,
        "candidates",
        String(format: "%03d", index + 1),
      ].joined(separator: "/")
      transaction += "create \(candidateRef) \(oid)\n"
    }
    transaction += "prepare\ncommit\n"
    let retained = try git.run(
      ["update-ref", "--stdin"],
      at: cloneURL,
      input: Data(transaction.utf8)
    )
    guard retained.status == 0,
      try git.text(["rev-parse", "--verify", "\(prefix)/common-parent"], at: cloneURL)
        == commonParentOID,
      try git.text(["rev-parse", "--verify", "\(prefix)/target"], at: cloneURL)
        == request.expectedTargetOID
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Не удалось закрепить входные commit попытки."
      )
    }
  }

  private func makeDiagnostic(
    request: CandidateCommitIntegrationRequest,
    commonParentOID: String,
    recovered: [RecoveredIntegrationCandidate],
    affectedPaths: [String],
    issues: [CandidateResolutionDiagnosticIssue],
    checks: [CandidateIntegrationRecordedCheck],
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateResolutionDiagnostic {
    var inputs = [
      try diagnosticInput(
        role: "common_parent",
        identifier: "common-parent",
        commitOID: commonParentOID,
        affectedPaths: affectedPaths,
        repositoryURL: repositoryURL,
        git: git
      ),
      try diagnosticInput(
        role: "target",
        identifier: "expected-target",
        commitOID: request.expectedTargetOID,
        affectedPaths: affectedPaths,
        repositoryURL: repositoryURL,
        git: git
      ),
    ]
    for candidate in recovered {
      inputs.append(
        try diagnosticInput(
          role: "candidate",
          identifier: candidate.passport.runID,
          commitOID: candidate.passport.commitOID,
          affectedPaths: affectedPaths,
          repositoryURL: repositoryURL,
          git: git
        )
      )
    }
    return CandidateResolutionDiagnostic(
      attemptID: request.attemptID,
      targetRef: request.targetRef,
      expectedTargetOID: request.expectedTargetOID,
      inputs: inputs,
      affectedPaths: affectedPaths,
      issues: issues,
      checks: checks
    )
  }

  private func diagnosticInput(
    role: String,
    identifier: String,
    commitOID: String,
    affectedPaths: [String],
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateResolutionDiagnosticInput {
    let treeOID = try git.text(
      ["rev-parse", "\(commitOID)^{tree}"],
      at: repositoryURL
    )
    var blobOIDs: [String: String] = [:]
    for path in Array(Set(affectedPaths)).sorted() {
      let object = try git.run(
        ["rev-parse", "--verify", "\(commitOID):\(path)"],
        at: repositoryURL
      )
      if object.status == 0 {
        let oid = String(decoding: object.output, as: UTF8.self)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if WritingSubnodeValidation.isObjectID(oid) {
          blobOIDs[path] = oid
        }
      }
    }
    return CandidateResolutionDiagnosticInput(
      role: role,
      identifier: identifier,
      commitOID: commitOID,
      treeOID: treeOID,
      blobOIDs: blobOIDs
    )
  }

  private func persistDiagnostic(
    _ diagnostic: CandidateResolutionDiagnostic,
    at url: URL
  ) throws {
    let canonical = try diagnostic.canonicalJSONData()
    guard WritingSubnodeValidation.publicationOutcome(canonical) == nil else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Диагностика resolver не прошла публикационную проверку."
      )
    }
    if WritingSubnodePersistence.pathExists(url) {
      guard
        try WritingSubnodePersistence.readStableRegularFile(
          at: url,
          maximumBytes: 2 * 1_024 * 1_024
        ) == canonical
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Существующая диагностика resolver не совпадает."
        )
      }
      return
    }
    try WritingSubnodePersistence.persistExclusive(canonical, at: url)
  }

  private func loadDiagnostic(
    at url: URL,
    request: CandidateCommitIntegrationRequest,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateResolutionDiagnostic {
    let data = try WritingSubnodePersistence.readStableRegularFile(
      at: url,
      maximumBytes: 2 * 1_024 * 1_024
    )
    let diagnostic = try JSONDecoder().decode(CandidateResolutionDiagnostic.self, from: data)
    guard diagnostic.schemaIdentity == "fum.candidate-resolution-diagnostic",
      diagnostic.schemaVersion == 1,
      diagnostic.attemptID == request.attemptID,
      diagnostic.targetRef == request.targetRef,
      diagnostic.expectedTargetOID == request.expectedTargetOID,
      !diagnostic.inputs.isEmpty,
      !diagnostic.affectedPaths.isEmpty,
      !diagnostic.issues.isEmpty,
      diagnostic.affectedPaths.allSatisfy(WritingSubnodeValidation.isRelativePath),
      diagnostic.issues.allSatisfy({
        WritingSubnodeValidation.isRelativePath($0.path)
      }),
      try diagnostic.canonicalJSONData() == data,
      WritingSubnodeValidation.publicationOutcome(data) == nil
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Диагностика resolver повреждена."
      )
    }
    try CandidateIntegrationValidation.validateGitDirectory(
      repositoryURL.appending(path: ".git", directoryHint: .isDirectory),
      repositoryURL: repositoryURL
    )
    let identity = CandidateIntegrationValidation.targetLockName(
      targetRef: "\(request.repositoryID):\(request.attemptID)"
    )
    let retainedData = try git.data(
      [
        "for-each-ref", "--format=%(objectname)",
        "refs/fum/integration-inputs/\(identity)/",
      ],
      at: repositoryURL
    )
    let retainedOIDs = retainedData.split(whereSeparator: { $0 == 0x0A }).map {
      String(decoding: $0, as: UTF8.self)
    }.sorted()
    guard retainedOIDs == diagnostic.inputs.map(\.commitOID).sorted(),
      try diagnostic.inputs.allSatisfy({ input in
        try git.text(["cat-file", "-t", input.commitOID], at: repositoryURL) == "commit"
          && git.text(["rev-parse", "\(input.commitOID)^{tree}"], at: repositoryURL)
            == input.treeOID
          && input.blobOIDs.allSatisfy({ path, oid in
            try git.text(
              ["rev-parse", "--verify", "\(input.commitOID):\(path)"],
              at: repositoryURL
            ) == oid
          })
      })
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Входные commit диагностической попытки не сохранены."
      )
    }
    return diagnostic
  }

  private func recoverCandidates(
    _ references: [CandidateCommitReference],
    request: CandidateCommitIntegrationRequest,
    targetURL: URL,
    git: CandidateIntegrationGit
  ) throws -> [RecoveredIntegrationCandidate] {
    try references.sorted { $0.expectedCommitOID < $1.expectedCommitOID }.map { reference in
      let result = try WritingSubnodeCandidateRecovery().recover(
        executionRootURL: reference.executionRootURL,
        runID: reference.runID
      )
      guard let passport = result.passport,
        let passportSHA256 = result.passportSHA256,
        let cloneURL = result.cloneURL,
        passport.commitOID == reference.expectedCommitOID,
        passportSHA256 == reference.expectedPassportSHA256,
        passport.runID == reference.runID,
        passport.repositoryID == request.repositoryID,
        passport.transfer.targetRepositoryID == request.repositoryID,
        passport.transfer.targetRef == request.targetRef,
        try git.text(["rev-parse", "--show-object-format"], at: cloneURL)
          == git.text(["rev-parse", "--show-object-format"], at: targetURL)
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Кандидат не совпадает с закреплённым паспортом интеграции."
        )
      }
      return RecoveredIntegrationCandidate(
        passport: passport,
        passportSHA256: passportSHA256,
        cloneURL: cloneURL
      )
    }
  }

  private func cloneTarget(
    targetURL: URL,
    cloneURL: URL,
    attemptURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    try WritingSubnodePersistence.archiveIncompleteCloneIfPresent(cloneURL, in: attemptURL)
    let clone = try git.run(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout",
        targetURL.path, cloneURL.path,
      ],
      at: attemptURL
    )
    guard clone.status == 0 else {
      throw WritingSubnodeExecutorError.gitFailed("Не удалось создать интеграционный клон.")
    }
    let gitURL = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
    try CandidateIntegrationValidation.validateGitDirectory(
      gitURL,
      repositoryURL: cloneURL
    )
    _ = try git.data(["remote", "remove", "origin"], at: cloneURL)
    let alternates = gitURL.appending(path: "objects/info/alternates")
    guard WritingSubnodePersistence.isPlainDirectory(gitURL),
      !WritingSubnodePersistence.pathExists(alternates),
      try git.text(["remote"], at: cloneURL).isEmpty
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Интеграционный клон не изолирован."
      )
    }
  }

  private func recoverCompletedAttempt(
    request: CandidateCommitIntegrationRequest,
    requestSHA256: String,
    stableChecks: [CandidateStableCheck],
    stableResolverRules: [CandidateConflictResolverBinding],
    targetURL: URL,
    preparedURL: URL,
    receiptURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateCommitIntegrationResult {
    let passport = try loadPrepared(
      at: preparedURL,
      request: request,
      requestSHA256: requestSHA256,
      stableChecks: stableChecks,
      stableResolverRules: stableResolverRules
    )
    let receipt = try loadReceipt(at: receiptURL)
    let passportCanonical = try passport.canonicalJSONData()
    try validatePreparedSemantics(
      passport,
      request: request,
      targetURL: targetURL,
      repositoryURL: targetURL,
      git: git
    )
    guard receipt.requestSHA256 == requestSHA256,
      receipt.passportSHA256 == WritingSubnodeJSON.sha256(passportCanonical),
      receipt.integrationOID == passport.integrationOID,
      try targetContains(
        passport.integrationOID,
        targetRef: request.targetRef,
        targetURL: targetURL,
        git: git
      )
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Завершённая интеграционная попытка повреждена."
      )
    }
    return CandidateCommitIntegrationResult(
      outcome: .alreadyIntegrated,
      passport: passport
    )
  }

  private func resumePreparedAttempt(
    request: CandidateCommitIntegrationRequest,
    requestSHA256: String,
    stableChecks: [CandidateStableCheck],
    stableResolverRules: [CandidateConflictResolverBinding],
    targetURL: URL,
    cloneURL: URL,
    preparedURL: URL,
    receiptURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateCommitIntegrationResult {
    let passport = try loadPrepared(
      at: preparedURL,
      request: request,
      requestSHA256: requestSHA256,
      stableChecks: stableChecks,
      stableResolverRules: stableResolverRules
    )
    let current = try targetOID(request.targetRef, targetURL: targetURL, git: git)
    let alreadyPublished =
      current == passport.integrationOID
      ? true
      : try git.succeeds(
        ["merge-base", "--is-ancestor", passport.integrationOID, current],
        at: targetURL
      )
    if alreadyPublished {
      try validatePreparedSemantics(
        passport,
        request: request,
        targetURL: targetURL,
        repositoryURL: targetURL,
        git: git
      )
      try persistReceipt(for: passport, at: receiptURL)
      return CandidateCommitIntegrationResult(
        outcome: .alreadyIntegrated,
        passport: passport
      )
    }
    guard current == request.expectedTargetOID else {
      return CandidateCommitIntegrationResult(outcome: .targetChanged)
    }
    try CandidateIntegrationValidation.validateGitDirectory(
      cloneURL.appending(path: ".git", directoryHint: .isDirectory),
      repositoryURL: cloneURL
    )
    guard
      try git.text(["rev-parse", "--verify", passport.integrationRef], at: cloneURL)
        == passport.integrationOID
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Прямая ссылка подготовленного интеграционного commit повреждена."
      )
    }
    try validatePreparedSemantics(
      passport,
      request: request,
      targetURL: targetURL,
      repositoryURL: cloneURL,
      git: git
    )
    return try publishPrepared(
      passport,
      request: request,
      targetURL: targetURL,
      cloneURL: cloneURL,
      receiptURL: receiptURL,
      git: git,
      integratedOutcome: .integrated
    )
  }

  private func publishPrepared(
    _ passport: CandidateCommitIntegrationPassport,
    request: CandidateCommitIntegrationRequest,
    targetURL: URL,
    cloneURL: URL,
    receiptURL: URL,
    git: CandidateIntegrationGit,
    integratedOutcome: CandidateCommitIntegrationOutcome
  ) throws -> CandidateCommitIntegrationResult {
    try CandidateIntegrationValidation.validateGitDirectory(
      cloneURL.appending(path: ".git", directoryHint: .isDirectory),
      repositoryURL: cloneURL
    )
    guard
      try git.text(["rev-parse", "--verify", passport.integrationRef], at: cloneURL)
        == passport.integrationOID
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Прямая ссылка подготовленного интеграционного commit повреждена."
      )
    }
    try validatePreparedSemantics(
      passport,
      request: request,
      targetURL: targetURL,
      repositoryURL: cloneURL,
      git: git
    )
    let transfer = try git.run(
      [
        "fetch", "--quiet", "--no-tags", "--no-write-fetch-head", cloneURL.path,
        passport.integrationRef,
      ],
      at: targetURL
    )
    guard transfer.status == 0 else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Не удалось передать интеграционные объекты в целевой репозиторий."
      )
    }
    try validatePreparedTopology(
      passport,
      request: request,
      repositoryURL: targetURL,
      git: git
    )
    guard
      try targetOID(request.targetRef, targetURL: targetURL, git: git)
        == request.expectedTargetOID
    else {
      return CandidateCommitIntegrationResult(outcome: .targetChanged)
    }
    try hooks.beforeCompareAndSwap?()
    let transaction = Data(
      "start\noption no-deref\nupdate \(request.targetRef) \(passport.integrationOID) \(request.expectedTargetOID)\nprepare\ncommit\n"
        .utf8
    )
    let cas = try git.run(["update-ref", "--stdin"], at: targetURL, input: transaction)
    guard cas.status == 0 else {
      return CandidateCommitIntegrationResult(outcome: .casLost)
    }
    try hooks.afterCompareAndSwap?()
    try persistReceipt(for: passport, at: receiptURL)
    return CandidateCommitIntegrationResult(
      outcome: integratedOutcome,
      passport: passport,
      targetUnchanged: false
    )
  }

  private func loadPrepared(
    at url: URL,
    request: CandidateCommitIntegrationRequest,
    requestSHA256: String,
    stableChecks: [CandidateStableCheck],
    stableResolverRules: [CandidateConflictResolverBinding]
  ) throws -> CandidateCommitIntegrationPassport {
    let data = try WritingSubnodePersistence.readStableRegularFile(
      at: url,
      maximumBytes: 2 * 1_024 * 1_024
    )
    let passport = try JSONDecoder().decode(CandidateCommitIntegrationPassport.self, from: data)
    let expectedCandidates = request.candidates.sorted {
      $0.expectedCommitOID < $1.expectedCommitOID
    }
    let expectedIntegrationRef =
      "refs/fum/integrations/\(request.repositoryID)/\(CandidateIntegrationValidation.targetLockName(targetRef: request.targetRef))/\(request.attemptID)"
    guard passport.schemaIdentity == "fum.candidate-commit.integration-passport",
      passport.schemaVersion == 2,
      passport.attemptID == request.attemptID,
      passport.ownerID == request.ownerID,
      passport.repositoryID == request.repositoryID,
      passport.targetRef == request.targetRef,
      passport.expectedTargetOID == request.expectedTargetOID,
      passport.requestSHA256 == requestSHA256,
      passport.integrationRef == expectedIntegrationRef,
      WritingSubnodeValidation.isObjectID(passport.integrationOID),
      WritingSubnodeValidation.isObjectID(passport.integrationTreeOID),
      passport.candidates.map(\.commitOID) == passport.candidates.map(\.commitOID).sorted(),
      Set(passport.candidates.map(\.commitOID)).count == passport.candidates.count,
      passport.candidates.map(\.runID) == expectedCandidates.map(\.runID),
      passport.candidates.map(\.commitOID) == expectedCandidates.map(\.expectedCommitOID),
      passport.candidates.map(\.passportSHA256)
        == expectedCandidates.map(\.expectedPassportSHA256),
      passport.candidates.allSatisfy({
        WritingSubnodeValidation.isIdentifier($0.runID)
          && WritingSubnodeValidation.isObjectID($0.commitOID)
          && WritingSubnodeValidation.isObjectID($0.parentOID)
          && WritingSubnodeValidation.isObjectID($0.treeOID)
          && WritingSubnodeValidation.isSHA256($0.passportSHA256)
      }),
      passport.resolverRegistryIdentity == CandidateConflictResolverRegistry.registryIdentity,
      passport.resolverRegistryVersion == CandidateConflictResolverRegistry.registryVersion,
      passport.resolverRules == stableResolverRules,
      passport.resolutions.count == stableResolverRules.count,
      zip(passport.resolutions, stableResolverRules).allSatisfy({ resolution, binding in
        resolution.ruleID == binding.ruleID
          && resolution.ruleVersion == binding.ruleVersion
          && resolution.path == binding.path
          && resolution.algorithm == binding.algorithm
          && resolution.specificationSHA256 == binding.specificationSHA256
          && resolution.requiredCheckIDs == binding.requiredCheckIDs
      }),
      passport.resolutions.allSatisfy({ resolution in
        WritingSubnodeValidation.isIdentifier(resolution.ruleID)
          && WritingSubnodeValidation.isRelativePath(resolution.path)
          && WritingSubnodeValidation.isSHA256(resolution.specificationSHA256)
          && !resolution.inputSHA256s.isEmpty
          && resolution.inputSHA256s.allSatisfy(WritingSubnodeValidation.isSHA256)
          && WritingSubnodeValidation.isSHA256(resolution.outputSHA256)
          && !resolution.invariants.isEmpty
      }),
      passport.checks.allSatisfy({
        $0.status == .passed
          && WritingSubnodeValidation.isIdentifier($0.checkID)
          && WritingSubnodeValidation.isSHA256($0.specificationSHA256)
      }),
      passport.checks.map(\.checkID) == stableChecks.map(\.checkID),
      passport.checks.map(\.specificationSHA256)
        == stableChecks.map(\.specificationSHA256),
      passport.repeatedChecks == passport.checks,
      try passport.canonicalJSONData() == data,
      WritingSubnodeValidation.publicationOutcome(data) == nil
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленный паспорт интеграции повреждён."
      )
    }
    return passport
  }

  private func loadReceipt(at url: URL) throws -> CandidateIntegrationReceipt {
    let data = try WritingSubnodePersistence.readStableRegularFile(
      at: url,
      maximumBytes: 4_096
    )
    let receipt = try JSONDecoder().decode(CandidateIntegrationReceipt.self, from: data)
    guard receipt.schemaIdentity == "fum.candidate-commit.integration-receipt",
      receipt.schemaVersion == 1,
      WritingSubnodeValidation.isSHA256(receipt.requestSHA256),
      WritingSubnodeValidation.isSHA256(receipt.passportSHA256),
      WritingSubnodeValidation.isObjectID(receipt.integrationOID),
      try WritingSubnodeJSON.encode(receipt) == data
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Квитанция интеграции повреждена."
      )
    }
    return receipt
  }

  private func persistReceipt(
    for passport: CandidateCommitIntegrationPassport,
    at url: URL
  ) throws {
    let receipt = CandidateIntegrationReceipt(
      requestSHA256: passport.requestSHA256,
      passportSHA256: WritingSubnodeJSON.sha256(try passport.canonicalJSONData()),
      integrationOID: passport.integrationOID
    )
    let canonical = try WritingSubnodeJSON.encode(receipt)
    guard WritingSubnodeValidation.publicationOutcome(canonical) == nil else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Квитанция интеграции не прошла публикационную проверку."
      )
    }
    if WritingSubnodePersistence.pathExists(url) {
      guard
        try WritingSubnodePersistence.readStableRegularFile(
          at: url,
          maximumBytes: 4_096
        ) == canonical
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Существующая квитанция интеграции не совпадает."
        )
      }
      return
    }
    try WritingSubnodePersistence.persistExclusive(canonical, at: url)
  }

  private func validatePreparedSemantics(
    _ passport: CandidateCommitIntegrationPassport,
    request: CandidateCommitIntegrationRequest,
    targetURL: URL,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    let recovered = try recoverCandidates(
      request.candidates,
      request: request,
      targetURL: targetURL,
      git: git
    )
    let recoveredDescriptors = recovered.map {
      CandidateIntegrationPassportCandidate(
        runID: $0.passport.runID,
        commitOID: $0.passport.commitOID,
        passportSHA256: $0.passportSHA256,
        parentOID: $0.passport.parentOID,
        treeOID: $0.passport.treeOID
      )
    }
    guard recoveredDescriptors == passport.candidates else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленный паспорт не совпадает с неизменяемым набором кандидатов."
      )
    }
    try validatePreparedTopology(
      passport,
      request: request,
      repositoryURL: repositoryURL,
      git: git
    )
    guard
      try !CandidateIntegrationValidation.containsMergeAttributes(
        in: [passport.expectedTargetOID] + passport.candidateOIDs,
        repositoryURL: repositoryURL,
        git: git
      )
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленное дерево зависит от запрещённых merge-атрибутов."
      )
    }
    guard let commonParentOID = recovered.first?.passport.parentOID,
      recovered.allSatisfy({ $0.passport.parentOID == commonParentOID })
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленные кандидаты не имеют общего предка."
      )
    }
    let replayed: CandidateResolverPassResult
    do {
      replayed = try replayPreparedMerge(
        request: request,
        stableResolverRules: passport.resolverRules,
        commonParentOID: commonParentOID,
        recovered: recovered,
        targetURL: targetURL,
        git: git
      )
    } catch {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Полный повтор merge и resolver подготовленного дерева не выполнился."
      )
    }
    guard replayed.treeOID == passport.integrationTreeOID,
      replayed.resolutions == passport.resolutions
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленное дерево или resolver-записи не совпадают с полным повтором."
      )
    }
    let changedPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        passport.expectedTargetOID, passport.integrationTreeOID, "--",
      ],
      at: repositoryURL
    ).sorted()
    let candidatePaths = recovered.flatMap(\.passport.actualPaths)
    let allowedPaths = Set(candidatePaths).union(passport.resolutions.map(\.path))
    let finalTreePaths = try git.nulStrings(
      ["ls-tree", "-r", "--name-only", "-z", passport.integrationTreeOID],
      at: repositoryURL
    )
    guard !changedPaths.isEmpty,
      Set(changedPaths).isSubset(of: allowedPaths),
      try resolverPathAmbiguities(
        passport.resolverRules,
        candidatePaths: candidatePaths
      ).isEmpty,
      !CandidateIntegrationValidation.hasNormalizedPathCollision(finalTreePaths),
      !changedPaths.contains(where: CandidateIntegrationValidation.isMachineJunk),
      try WritingSubnodeCandidateAudit.validateTree(
        paths: changedPaths,
        treeOID: passport.integrationTreeOID,
        cloneURL: repositoryURL,
        git: WritingSubnodeGit()
      ) == nil
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленное дерево не прошло повторный аудит области и публикации."
      )
    }
    let finalDiff = try git.data(
      [
        "diff", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        passport.expectedTargetOID, passport.integrationTreeOID, "--",
      ],
      at: repositoryURL
    )
    guard
      WritingSubnodeValidation.publicationOutcome(
        finalDiff,
        allowingGitNullDevice: true
      ) == nil
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленный diff не прошёл повторный публикационный аудит."
      )
    }
    let repeatedChecks = checkRegistry.run(
      identifiers: request.checkIDs,
      treeOID: passport.integrationTreeOID,
      repositoryURL: repositoryURL,
      git: git
    )
    guard repeatedChecks == passport.repeatedChecks,
      repeatedChecks.allSatisfy({ $0.status == .passed })
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленное дерево не прошло повторный набор проверок."
      )
    }
  }

  private func replayPreparedMerge(
    request: CandidateCommitIntegrationRequest,
    stableResolverRules: [CandidateConflictResolverBinding],
    commonParentOID: String,
    recovered: [RecoveredIntegrationCandidate],
    targetURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateResolverPassResult {
    let integrationRootURL =
      request.integrationRootURL.standardizedFileURL.resolvingSymlinksInPath()
    let attemptURL = integrationRootURL.appending(
      path: "attempts/\(request.attemptID)",
      directoryHint: .isDirectory
    )
    guard WritingSubnodePersistence.isPlainDirectory(attemptURL) else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Каталог подготовленной попытки повреждён."
      )
    }
    let replayRootURL = attemptURL.appending(
      path: "prepared-replay-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    guard try WritingSubnodePersistence.reserveDirectory(replayRootURL) else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось зарезервировать каталог повтора интеграции."
      )
    }
    defer { try? FileManager.default.removeItem(at: replayRootURL) }
    let replayCloneURL = replayRootURL.appending(path: "clone", directoryHint: .isDirectory)
    try cloneTarget(
      targetURL: targetURL,
      cloneURL: replayCloneURL,
      attemptURL: replayRootURL,
      git: git
    )
    for candidate in recovered {
      let fetch = try git.run(
        [
          "fetch", "--quiet", "--no-tags", "--no-write-fetch-head",
          candidate.cloneURL.path, candidate.passport.resultRef,
        ],
        at: replayCloneURL
      )
      guard fetch.status == 0,
        try git.text(
          ["cat-file", "-t", candidate.passport.commitOID],
          at: replayCloneURL
        ) == "commit"
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Повтор не получил закреплённый кандидат."
        )
      }
    }
    _ = try git.data(
      ["checkout", "--quiet", "--detach", request.expectedTargetOID],
      at: replayCloneURL
    )
    let replay = try mergeCandidates(
      request: request,
      stableResolverRules: stableResolverRules,
      commonParentOID: commonParentOID,
      recovered: recovered,
      cloneURL: replayCloneURL,
      git: git
    )
    switch replay {
    case .resolved(let treeOID, let resolutions):
      return CandidateResolverPassResult(treeOID: treeOID, resolutions: resolutions)
    case .resolutionRequired:
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Повтор подготовленной попытки потребовал ручного разрешения."
      )
    }
  }

  private func validatePreparedTopology(
    _ passport: CandidateCommitIntegrationPassport,
    request: CandidateCommitIntegrationRequest,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    var expectedCommitArguments = ["commit-tree", passport.integrationTreeOID]
    for parentOID in [passport.expectedTargetOID] + passport.candidateOIDs {
      expectedCommitArguments += ["-p", parentOID]
    }
    let expectedIntegrationOID = try git.text(
      expectedCommitArguments,
      at: repositoryURL,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: CandidateIntegrationGit.commitEnvironment
    )
    guard
      WritingSubnodeValidation.publicationOutcome(Data(request.commitMessage.utf8)) == nil,
      expectedIntegrationOID == passport.integrationOID,
      try git.text(["cat-file", "-t", passport.integrationOID], at: repositoryURL)
        == "commit",
      try git.text(
        ["rev-parse", "\(passport.integrationOID)^{tree}"],
        at: repositoryURL
      ) == passport.integrationTreeOID,
      try CandidateIntegrationValidation.parents(
        of: passport.integrationOID,
        repositoryURL: repositoryURL,
        git: git
      ) == [passport.expectedTargetOID] + passport.candidateOIDs,
      try passport.candidates.allSatisfy({ candidate in
        try git.text(["cat-file", "-t", candidate.commitOID], at: repositoryURL) == "commit"
          && git.text(
            ["rev-parse", "\(candidate.commitOID)^{tree}"],
            at: repositoryURL
          ) == candidate.treeOID
          && CandidateIntegrationValidation.parents(
            of: candidate.commitOID,
            repositoryURL: repositoryURL,
            git: git
          ) == [candidate.parentOID]
      })
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленный интеграционный commit повреждён."
      )
    }
  }

  private func targetContains(
    _ integrationOID: String,
    targetRef: String,
    targetURL: URL,
    git: CandidateIntegrationGit
  ) throws -> Bool {
    guard (try? git.text(["cat-file", "-t", integrationOID], at: targetURL)) == "commit"
    else { return false }
    let current = try targetOID(targetRef, targetURL: targetURL, git: git)
    if current == integrationOID { return true }
    return try git.succeeds(
      ["merge-base", "--is-ancestor", integrationOID, current],
      at: targetURL
    )
  }

  private func targetOID(
    _ targetRef: String,
    targetURL: URL,
    git: CandidateIntegrationGit
  ) throws -> String {
    try CandidateIntegrationValidation.validateDirectRef(
      targetRef,
      repositoryURL: targetURL,
      git: git
    )
    let oid = try git.text(["rev-parse", "--verify", targetRef], at: targetURL)
    guard WritingSubnodeValidation.isObjectID(oid),
      try git.text(["cat-file", "-t", targetRef], at: targetURL) == "commit"
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Целевая ссылка не указывает на commit."
      )
    }
    return oid
  }
}

private enum CandidateMergeResolutionResult {
  case resolved(
    treeOID: String,
    resolutions: [CandidateConflictResolutionRecord]
  )
  case resolutionRequired(CandidateResolutionDiagnostic)
}

private struct CandidateResolverPassResult: Equatable {
  let treeOID: String
  let resolutions: [CandidateConflictResolutionRecord]
}

private struct CandidateResolverPathAmbiguity {
  let paths: [String]
  let ruleIDs: [String]
}

private struct RecoveredIntegrationCandidate {
  let passport: WritingSubnodePassport
  let passportSHA256: String
  let cloneURL: URL
}

private struct CandidateStableReference: Encodable {
  let runID: String
  let expectedCommitOID: String
  let expectedPassportSHA256: String

  enum CodingKeys: String, CodingKey {
    case runID = "run_id"
    case expectedCommitOID = "expected_commit_oid"
    case expectedPassportSHA256 = "expected_passport_sha256"
  }
}

struct CandidateStableCheck: Encodable {
  let checkID: String
  let specificationSHA256: String

  enum CodingKeys: String, CodingKey {
    case checkID = "check_id"
    case specificationSHA256 = "specification_sha256"
  }
}

private struct CandidateStableRequest: Encodable {
  let schemaVersion: Int
  let attemptID: String
  let ownerID: String
  let repositoryID: String
  let targetRef: String
  let expectedTargetOID: String
  let commitMessage: String
  let candidates: [CandidateStableReference]
  let checks: [CandidateStableCheck]
  let resolverRegistryIdentity: String
  let resolverRegistryVersion: Int
  let resolverRules: [CandidateConflictResolverBinding]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case attemptID = "attempt_id"
    case ownerID = "owner_id"
    case repositoryID = "repository_id"
    case targetRef = "target_ref"
    case expectedTargetOID = "expected_target_oid"
    case commitMessage = "commit_message"
    case candidates
    case checks
    case resolverRegistryIdentity = "resolver_registry_identity"
    case resolverRegistryVersion = "resolver_registry_version"
    case resolverRules = "resolver_rules"
  }
}

private struct CandidateIntegrationReceipt: Codable, Equatable {
  let schemaIdentity = "fum.candidate-commit.integration-receipt"
  let schemaVersion = 1
  let requestSHA256: String
  let passportSHA256: String
  let integrationOID: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case requestSHA256 = "request_sha256"
    case passportSHA256 = "passport_sha256"
    case integrationOID = "integration_oid"
  }
}

enum CandidateIntegrationValidation {
  static func validate(
    _ request: CandidateCommitIntegrationRequest,
    stableChecks: [CandidateStableCheck],
    stableResolverRules: [CandidateConflictResolverBinding]
  ) throws {
    let identifiers = [request.attemptID, request.ownerID, request.repositoryID]
    let sortedCandidateOIDs = request.candidates.map(\.expectedCommitOID).sorted()
    guard identifiers.allSatisfy(WritingSubnodeValidation.isIdentifier),
      request.targetRef.hasPrefix("refs/heads/"),
      WritingSubnodeValidation.isObjectID(request.expectedTargetOID),
      !request.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      request.commitMessage.unicodeScalars.count <= 4_096,
      (1...32).contains(request.candidates.count),
      Set(sortedCandidateOIDs).count == sortedCandidateOIDs.count,
      request.candidates.allSatisfy({
        WritingSubnodeValidation.isIdentifier($0.runID)
          && WritingSubnodeValidation.isObjectID($0.expectedCommitOID)
          && WritingSubnodeValidation.isSHA256($0.expectedPassportSHA256)
      }),
      Set(request.checkIDs).count == request.checkIDs.count,
      !request.checkIDs.isEmpty,
      stableChecks.map(\.checkID) == request.checkIDs.sorted(),
      Set(request.resolverRuleIDs).count == request.resolverRuleIDs.count,
      stableResolverRules.map(\.ruleID) == request.resolverRuleIDs.sorted()
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Запрос CAS-интеграции некорректен."
      )
    }
  }

  static func validateLocations(targetURL: URL, integrationRootURL: URL) throws {
    guard targetURL != integrationRootURL,
      !WritingSubnodeValidation.isDescendant(targetURL, of: integrationRootURL),
      !WritingSubnodeValidation.isDescendant(integrationRootURL, of: targetURL),
      WritingSubnodePersistence.isPlainDirectory(targetURL)
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Целевой репозиторий и интеграционный корень должны быть раздельны."
      )
    }
  }

  static func validateCandidateLocations(
    _ candidates: [CandidateCommitReference],
    targetURL: URL,
    integrationRootURL: URL
  ) throws {
    for candidate in candidates {
      let executionRootURL =
        candidate.executionRootURL.standardizedFileURL.resolvingSymlinksInPath()
      guard WritingSubnodePersistence.isPlainDirectory(executionRootURL),
        executionRootURL != targetURL,
        executionRootURL != integrationRootURL,
        !WritingSubnodeValidation.isDescendant(executionRootURL, of: targetURL),
        !WritingSubnodeValidation.isDescendant(targetURL, of: executionRootURL),
        !WritingSubnodeValidation.isDescendant(executionRootURL, of: integrationRootURL),
        !WritingSubnodeValidation.isDescendant(integrationRootURL, of: executionRootURL)
      else {
        throw WritingSubnodeExecutorError.invalidRequest(
          "Корень интеграции, целевой репозиторий и корни кандидатов должны быть раздельны."
        )
      }
    }
  }

  static func validateBareTarget(
    _ targetURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    try validateGitDirectory(targetURL, repositoryURL: targetURL)
    let absoluteGitDirectory = try git.text(
      ["rev-parse", "--absolute-git-dir"],
      at: targetURL
    )
    guard try git.text(["rev-parse", "--is-bare-repository"], at: targetURL) == "true",
      URL(fileURLWithPath: absoluteGitDirectory).standardizedFileURL.resolvingSymlinksInPath()
        == targetURL.standardizedFileURL.resolvingSymlinksInPath()
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Целевой репозиторий интеграции должен быть локальным bare-репозиторием."
      )
    }
  }

  static func validateGitDirectory(
    _ gitDirectoryURL: URL,
    repositoryURL: URL
  ) throws {
    try WritingSubnodeFilesystem.validatePlainTreeWithoutSymlinks(at: gitDirectoryURL)
    for relative in ["objects/info/alternates", "objects/info/http-alternates", "info/attributes"] {
      guard
        !WritingSubnodePersistence.pathExists(
          gitDirectoryURL.appending(path: relative)
        )
      else {
        throw WritingSubnodeExecutorError.invalidRequest(
          "Git-каталог содержит внешний источник объектов или атрибутов."
        )
      }
    }
    let configData = try WritingSubnodePersistence.readStableRegularFile(
      at: gitDirectoryURL.appending(path: "config"),
      maximumBytes: 1_048_576
    )
    let keys = try WritingSubnodeGit().nulStrings(
      ["config", "--file", "-", "--no-includes", "--name-only", "--null", "--list"],
      at: repositoryURL,
      input: configData
    ).map { $0.lowercased() }
    let allowedExact = [
      "core.bare", "core.filemode", "core.ignorecase", "core.logallrefupdates",
      "core.precomposeunicode", "core.repositoryformatversion", "core.symlinks",
      "extensions.compatobjectformat", "extensions.objectformat", "extensions.refstorage",
      "user.email", "user.name", "user.useconfigonly",
    ]
    let safe = keys.allSatisfy { key in
      allowedExact.contains(key)
        || (key.hasPrefix("branch.")
          && [".merge", ".pushremote", ".remote"].contains(where: key.hasSuffix))
        || (key.hasPrefix("remote.")
          && [
            ".fetch", ".mirror", ".partialclonefilter", ".promisor", ".pushurl",
            ".skipdefaultupdate", ".skipfetchall", ".tagopt", ".url",
          ].contains(where: key.hasSuffix))
    }
    guard safe else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Локальная Git-конфигурация интеграции содержит незарегистрированную настройку."
      )
    }
  }

  static func validateObjectFormat(
    oid: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    let objectFormat = try git.text(["rev-parse", "--show-object-format"], at: repositoryURL)
    guard
      (objectFormat == "sha1" && oid.count == 40)
        || (objectFormat == "sha256" && oid.count == 64)
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "OID не совпадает с форматом объектов целевого репозитория."
      )
    }
  }

  static func validateDirectRef(
    _ targetRef: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    let symbolic = try git.run(["symbolic-ref", "-q", targetRef], at: repositoryURL)
    guard symbolic.status == 1 else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Целевая ссылка должна быть прямой, а не символической."
      )
    }
  }

  static func targetLockName(targetRef: String) -> String {
    let digest = SHA256.hash(data: Data(targetRef.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  static func containsMergeAttributes(
    in revisions: [String],
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> Bool {
    for revision in revisions {
      let paths = try git.nulStrings(
        ["ls-tree", "-r", "--name-only", "-z", revision],
        at: repositoryURL
      )
      if paths.contains(where: { $0.split(separator: "/").last == ".gitattributes" }) {
        return true
      }
    }
    return false
  }

  static func isMachineJunk(_ path: String) -> Bool {
    let components = path.split(separator: "/").map { $0.lowercased() }
    guard let name = components.last else { return true }
    let exact = [
      ".ds_store", "thumbs.db", "desktop.ini", ".directory", ".spotlight-v100",
      ".trashes", ".gitmodules",
    ]
    return exact.contains(name)
      || components.contains("__macosx")
      || name.hasSuffix(".swp")
      || name.hasSuffix(".swo")
      || name.hasSuffix("~")
  }

  static func hasNormalizedPathCollision(_ paths: [String]) -> Bool {
    !normalizedPathCollisions(paths).isEmpty
  }

  static func normalizedPathCollisions(_ paths: [String]) -> [String] {
    var originalPrefixesByNormalizedPrefix: [String: Set<String>] = [:]
    var fullPathsByNormalizedPrefix: [String: Set<String>] = [:]
    for path in paths {
      let components = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
      var normalizedComponents: [String] = []
      var originalComponents: [String] = []
      for component in components {
        normalizedComponents.append(
          component.precomposedStringWithCanonicalMapping.lowercased()
        )
        originalComponents.append(component)
        let normalizedPrefix = normalizedComponents.joined(separator: "/")
        originalPrefixesByNormalizedPrefix[normalizedPrefix, default: []].insert(
          originalComponents.joined(separator: "/")
        )
        fullPathsByNormalizedPrefix[normalizedPrefix, default: []].insert(path)
      }
    }
    let collidingPrefixes = originalPrefixesByNormalizedPrefix.compactMap { key, originals in
      originals.count > 1 ? key : nil
    }
    return Set(collidingPrefixes.flatMap { fullPathsByNormalizedPrefix[$0, default: []] }).sorted()
  }

  static func parents(
    of oid: String,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws -> [String] {
    let fields = try git.text(
      ["rev-list", "--parents", "-n", "1", oid],
      at: repositoryURL
    ).split(separator: " ").map(String.init)
    guard fields.first == oid else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Git вернул неожиданную запись родословной."
      )
    }
    return Array(fields.dropFirst())
  }
}

struct CandidateIntegrationGit: Sendable {
  static let commitEnvironment = [
    "GIT_AUTHOR_NAME": "FUM Candidate Integrator",
    "GIT_AUTHOR_EMAIL": "fum-integrator@invalid",
    "GIT_AUTHOR_DATE": "2000-01-01T00:00:00Z",
    "GIT_COMMITTER_NAME": "FUM Candidate Integrator",
    "GIT_COMMITTER_EMAIL": "fum-integrator@invalid",
    "GIT_COMMITTER_DATE": "2000-01-01T00:00:00Z",
  ]

  func run(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> CandidateIntegrationGitResult {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    process.arguments =
      [
        "--no-replace-objects", "--no-optional-locks",
        "-c", "core.fsmonitor=false",
        "-c", "core.hooksPath=\(WritingSubnodeSystemRuntime.nullDevicePath)",
        "-c", "core.untrackedCache=false",
        "-c", "protocol.allow=never",
        "-c", "protocol.file.allow=always",
        "-c", "merge.renames=false",
        "-c", "merge.renormalize=false",
      ] + arguments
    process.currentDirectoryURL = directory
    let системноеОкружение = ProcessInfo.processInfo.environment
    var environment: [String: String] = [:]
    if let путьИсполнения = системноеОкружение["PATH"] {
      environment["PATH"] = путьИсполнения
    }
    if let временныйКаталог = системноеОкружение["TMPDIR"] {
      environment["TMPDIR"] = временныйКаталог
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] = WritingSubnodeSystemRuntime.nullDevicePath
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    environment["GIT_ATTR_NOSYSTEM"] = "1"
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["LC_ALL"] = "C"
    for (key, value) in additionalEnvironment { environment[key] = value }
    process.environment = environment
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = outputPipe
    let inputPipe: Pipe?
    if input != nil {
      let pipe = Pipe()
      inputPipe = pipe
      process.standardInput = pipe
    } else {
      inputPipe = nil
    }
    try process.run()
    try outputPipe.fileHandleForWriting.close()
    if let input, let inputPipe {
      try inputPipe.fileHandleForWriting.write(contentsOf: input)
      try inputPipe.fileHandleForWriting.close()
    }
    let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return CandidateIntegrationGitResult(status: process.terminationStatus, output: output)
  }

  func data(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> Data {
    let result = try run(
      arguments,
      at: directory,
      input: input,
      additionalEnvironment: additionalEnvironment
    )
    guard result.status == 0 else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Git-команда завершилась с кодом \(result.status)."
      )
    }
    return result.output
  }

  func text(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> String {
    String(
      decoding: try data(
        arguments,
        at: directory,
        input: input,
        additionalEnvironment: additionalEnvironment
      ),
      as: UTF8.self
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func nulStrings(_ arguments: [String], at directory: URL) throws -> [String] {
    try data(arguments, at: directory)
      .split(separator: 0, omittingEmptySubsequences: true)
      .map {
        guard let value = String(data: Data($0), encoding: .utf8) else {
          throw WritingSubnodeExecutorError.gitFailed("Git вернул не-UTF-8 значение.")
        }
        return value
      }
  }

  func succeeds(_ arguments: [String], at directory: URL) throws -> Bool {
    try run(arguments, at: directory).status == 0
  }
}

struct CandidateIntegrationGitResult: Sendable {
  let status: Int32
  let output: Data
}
