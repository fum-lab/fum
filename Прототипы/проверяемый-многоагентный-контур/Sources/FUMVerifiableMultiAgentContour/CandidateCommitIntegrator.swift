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
    checkIDs: [String]
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
  public let checks: [CandidateIntegrationRecordedCheck]

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
    case checks
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
  public let targetUnchanged: Bool

  fileprivate init(
    outcome: CandidateCommitIntegrationOutcome,
    passport: CandidateCommitIntegrationPassport? = nil,
    targetUnchanged: Bool = true
  ) {
    self.outcome = outcome
    self.passport = passport
    integrationOID = passport?.integrationOID
    passportCanonicalJSON = try? passport?.canonicalJSONData()
    passportSHA256 = passportCanonicalJSON.map(WritingSubnodeJSON.sha256)
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
  private let hooks: CandidateCommitIntegratorHooks

  public init(
    checkRegistry: CandidateIntegrationCheckRegistry = CandidateIntegrationCheckRegistry()
  ) {
    self.checkRegistry = checkRegistry
    hooks = CandidateCommitIntegratorHooks()
  }

  init(
    checkRegistry: CandidateIntegrationCheckRegistry,
    hooks: CandidateCommitIntegratorHooks
  ) {
    self.checkRegistry = checkRegistry
    self.hooks = hooks
  }

  public func integrate(
    _ request: CandidateCommitIntegrationRequest
  ) throws -> CandidateCommitIntegrationResult {
    let stableChecks = try checkRegistry.stableBindings(request.checkIDs)
    try CandidateIntegrationValidation.validate(request, stableChecks: stableChecks)
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
      schemaVersion: 1,
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
      checks: stableChecks
    )
    let requestSHA256 = WritingSubnodeJSON.sha256(
      try WritingSubnodeJSON.encode(stableRequest)
    )
    let attemptURL = attemptsURL.appending(path: request.attemptID, directoryHint: .isDirectory)
    let requestHashURL = attemptURL.appending(path: "request.sha256")
    let preparedURL = attemptURL.appending(path: "prepared.json")
    let receiptURL = attemptURL.appending(path: "result.json")
    let cloneURL = attemptURL.appending(path: "clone", directoryHint: .isDirectory)

    if WritingSubnodePersistence.pathExists(attemptURL) {
      guard WritingSubnodePersistence.isPlainDirectory(attemptURL),
        try WritingSubnodePersistence.readStableUTF8RegularFile(
          at: requestHashURL,
          maximumBytes: 128
        ) == requestSHA256
      else {
        return CandidateCommitIntegrationResult(outcome: .attemptAlreadyExists)
      }
      if WritingSubnodePersistence.pathExists(receiptURL) {
        return try recoverCompletedAttempt(
          request: request,
          requestSHA256: requestSHA256,
          stableChecks: stableChecks,
          targetURL: targetURL,
          preparedURL: preparedURL,
          receiptURL: receiptURL,
          git: git
        )
      }
      if WritingSubnodePersistence.pathExists(preparedURL) {
        return try resumePreparedAttempt(
          request: request,
          requestSHA256: requestSHA256,
          stableChecks: stableChecks,
          targetURL: targetURL,
          cloneURL: cloneURL,
          preparedURL: preparedURL,
          receiptURL: receiptURL,
          git: git
        )
      }
      try WritingSubnodePersistence.archiveIncompleteCloneIfPresent(cloneURL, in: attemptURL)
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
    let merge = try git.run(
      ["merge", "--no-commit", "--no-ff", "--no-edit"] + candidateOIDs,
      at: cloneURL,
      additionalEnvironment: CandidateIntegrationGit.commitEnvironment
    )
    guard merge.status == 0 else {
      _ = try? git.run(["merge", "--abort"], at: cloneURL)
      _ = try? git.run(["reset", "--hard", request.expectedTargetOID], at: cloneURL)
      return CandidateCommitIntegrationResult(outcome: .mergeConflict)
    }
    let treeOID = try git.text(["write-tree"], at: cloneURL)
    let changedPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        request.expectedTargetOID, treeOID, "--",
      ],
      at: cloneURL
    ).sorted()
    let candidatePaths = Set(recovered.flatMap(\.passport.actualPaths))
    guard !changedPaths.isEmpty,
      Set(changedPaths).isSubset(of: candidatePaths),
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
      return CandidateCommitIntegrationResult(outcome: .checkFailed)
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
      schemaVersion: 1,
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
      checks: checks
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
    targetURL: URL,
    preparedURL: URL,
    receiptURL: URL,
    git: CandidateIntegrationGit
  ) throws -> CandidateCommitIntegrationResult {
    let passport = try loadPrepared(
      at: preparedURL,
      request: request,
      requestSHA256: requestSHA256,
      stableChecks: stableChecks
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
      stableChecks: stableChecks
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
    try validatePreparedTopology(passport, repositoryURL: targetURL, git: git)
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
    stableChecks: [CandidateStableCheck]
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
      passport.schemaVersion == 1,
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
      passport.checks.allSatisfy({
        $0.status == .passed
          && WritingSubnodeValidation.isIdentifier($0.checkID)
          && WritingSubnodeValidation.isSHA256($0.specificationSHA256)
      }),
      passport.checks.map(\.checkID) == stableChecks.map(\.checkID),
      passport.checks.map(\.specificationSHA256)
        == stableChecks.map(\.specificationSHA256),
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
    try validatePreparedTopology(passport, repositoryURL: repositoryURL, git: git)
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
    let changedPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        passport.expectedTargetOID, passport.integrationTreeOID, "--",
      ],
      at: repositoryURL
    ).sorted()
    let candidatePaths = recovered.flatMap(\.passport.actualPaths)
    guard !changedPaths.isEmpty,
      Set(changedPaths).isSubset(of: Set(candidatePaths)),
      !CandidateIntegrationValidation.hasNormalizedPathCollision(candidatePaths),
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
    guard repeatedChecks == passport.checks,
      repeatedChecks.allSatisfy({ $0.status == .passed })
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Подготовленное дерево не прошло повторный набор проверок."
      )
    }
  }

  private func validatePreparedTopology(
    _ passport: CandidateCommitIntegrationPassport,
    repositoryURL: URL,
    git: CandidateIntegrationGit
  ) throws {
    guard
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

private enum CandidateIntegrationValidation {
  static func validate(
    _ request: CandidateCommitIntegrationRequest,
    stableChecks: [CandidateStableCheck]
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
      stableChecks.map(\.checkID) == request.checkIDs.sorted()
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
    var originalsByNormalizedPath: [String: Set<String>] = [:]
    for path in paths {
      let normalized = path.precomposedStringWithCanonicalMapping.lowercased()
      originalsByNormalizedPath[normalized, default: []].insert(path)
    }
    return originalsByNormalizedPath.values.contains { $0.count > 1 }
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
    var environment = ProcessInfo.processInfo.environment.filter {
      !$0.key.uppercased().hasPrefix("GIT_")
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
