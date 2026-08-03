import CryptoKit
import Darwin
import Dispatch
import Foundation

public enum WritingSubnodeOutcome: String, Codable, Equatable, Sendable {
  case candidateCommitted = "candidate_committed"
  case noOp = "no_op"
  case blockedBeforeWrite = "blocked_before_write"
  case forbiddenPath = "forbidden_path"
  case dirtySource = "dirty_source"
  case inputChanged = "input_changed"
  case secretDetected = "secret_detected"
  case checkFailed = "check_failed"
  case publicationRejected = "publication_rejected"
  case runAlreadyExists = "run_already_exists"
  case baseChanged = "base_changed"
}

public struct WritingSubnodeWrite: Equatable, Sendable {
  public let path: String
  public let contents: Data

  public init(path: String, contents: Data) {
    self.path = path
    self.contents = contents
  }
}

public enum WritingSubnodeCheckStatus: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct WritingSubnodeCheckObservation: Codable, Equatable, Sendable {
  public let status: WritingSubnodeCheckStatus
  public let evidence: String

  public init(status: WritingSubnodeCheckStatus, evidence: String) {
    self.status = status
    self.evidence = evidence
  }
}

public struct WritingSubnodeRecordedCheck: Codable, Equatable, Sendable {
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

public enum WritingSubnodeCheckSpecification: Codable, Equatable, Sendable {
  case regularFileSHA256(path: String, expectedSHA256: String)
}

public struct WritingSubnodeCheckRegistry: Sendable {
  private let specifications: [String: WritingSubnodeCheckSpecification]

  public init(specifications: [String: WritingSubnodeCheckSpecification] = [:]) {
    self.specifications = specifications
  }

  fileprivate func contains(_ identifier: String) -> Bool {
    guard let specification = specifications[identifier] else { return false }
    switch specification {
    case .regularFileSHA256(let path, let expectedSHA256):
      return WritingSubnodeValidation.isRelativePath(path)
        && WritingSubnodeValidation.isSHA256(expectedSHA256)
    }
  }

  fileprivate func run(
    _ identifier: String,
    treeOID: String,
    checkoutURL: URL,
    git: WritingSubnodeGit
  ) -> WritingSubnodeCheckObservation {
    guard let specification = specifications[identifier] else {
      return WritingSubnodeCheckObservation(status: .failed, evidence: "checker_not_registered")
    }
    do {
      switch specification {
      case .regularFileSHA256(let path, let expectedSHA256):
        let blob = try git.data(["cat-file", "blob", "\(treeOID):\(path)"], at: checkoutURL)
        let actualSHA256 = WritingSubnodeJSON.sha256(blob)
        return WritingSubnodeCheckObservation(
          status: actualSHA256 == expectedSHA256 ? .passed : .failed,
          evidence: actualSHA256
        )
      }
    } catch {
      return WritingSubnodeCheckObservation(status: .failed, evidence: "checker_error")
    }
  }

  fileprivate func stableBindings(_ identifiers: [String]) throws -> [WritingStableCheck] {
    try identifiers.sorted().map { identifier in
      let specificationSHA256: String
      if let specification = specifications[identifier] {
        specificationSHA256 = WritingSubnodeJSON.sha256(
          try WritingSubnodeJSON.encode(specification)
        )
      } else {
        specificationSHA256 = WritingSubnodeJSON.sha256(
          Data("unregistered-check:\(identifier)".utf8)
        )
      }
      return WritingStableCheck(
        checkID: identifier,
        specificationSHA256: specificationSHA256
      )
    }
  }
}

public struct WritingSubnodeExecutionRequest: Sendable {
  public let episodeID: String
  public let stepGenerationID: String
  public let cardID: String
  public let stepID: String
  public let runID: String
  public let subnodeID: String
  public let repositoryID: String
  public let sourceCheckoutURL: URL
  public let executionRootURL: URL
  public let targetRef: String
  public let baseOID: String
  public let commitMessage: String
  public let writes: [WritingSubnodeWrite]

  public init(
    episodeID: String,
    stepGenerationID: String,
    cardID: String,
    stepID: String,
    runID: String,
    subnodeID: String,
    repositoryID: String,
    sourceCheckoutURL: URL,
    executionRootURL: URL,
    targetRef: String,
    baseOID: String,
    commitMessage: String,
    writes: [WritingSubnodeWrite]
  ) {
    self.episodeID = episodeID
    self.stepGenerationID = stepGenerationID
    self.cardID = cardID
    self.stepID = stepID
    self.runID = runID
    self.subnodeID = subnodeID
    self.repositoryID = repositoryID
    self.sourceCheckoutURL = sourceCheckoutURL
    self.executionRootURL = executionRootURL
    self.targetRef = targetRef
    self.baseOID = baseOID
    self.commitMessage = commitMessage
    self.writes = writes
  }
}

public struct VerifiedWritingSubnodeWorkPackage: Sendable {
  public let data: Data
  public let workspaceRoot: URL
  public let report: WorkPackageReport
  fileprivate let snapshot: WritingWorkPackageSnapshot
}

public enum WritingSubnodeWorkPackageVerification: Sendable {
  case ready(VerifiedWritingSubnodeWorkPackage)
  case blocked(WorkPackageReport)
}

public struct WritingSubnodePassportInput: Codable, Equatable, Sendable {
  public let inputID: String
  public let path: String
  public let sha256: String
  public let required: Bool

  enum CodingKeys: String, CodingKey {
    case inputID = "input_id"
    case path
    case sha256
    case required
  }
}

public struct WritingSubnodePassportDependency: Codable, Equatable, Sendable {
  public let dependencyID: String
  public let status: String
  public let evidence: String

  enum CodingKeys: String, CodingKey {
    case dependencyID = "dependency_id"
    case status
    case evidence
  }
}

public struct WritingSubnodePassportBudget: Codable, Equatable, Sendable {
  public let unit: String
  public let limit: Int
  public let reading: Int
  public let work: Int
  public let verification: Int
  public let response: Int
  public let reserve: Int
}

public struct WritingSubnodePassportConstraints: Codable, Equatable, Sendable {
  public let changePolicy: String
  public let allowedPaths: [String]
  public let excludedPaths: [String]
  public let isolatedClone: Bool
  public let sourceMutationAllowed: Bool
  public let modelCallsAllowed: Bool
  public let networkAllowed: Bool
  public let integrationAllowed: Bool

  enum CodingKeys: String, CodingKey {
    case changePolicy = "change_policy"
    case allowedPaths = "allowed_paths"
    case excludedPaths = "excluded_paths"
    case isolatedClone = "isolated_clone"
    case sourceMutationAllowed = "source_mutation_allowed"
    case modelCallsAllowed = "model_calls_allowed"
    case networkAllowed = "network_allowed"
    case integrationAllowed = "integration_allowed"
  }
}

public struct WritingSubnodePassportHandoff: Codable, Equatable, Sendable {
  public let format: String
  public let requiredArtifacts: [String]

  enum CodingKeys: String, CodingKey {
    case format
    case requiredArtifacts = "required_artifacts"
  }
}

public enum WritingSubnodeTransferState: String, Codable, Equatable, Sendable {
  case prepared
}

public struct WritingSubnodePassportTransfer: Codable, Equatable, Sendable {
  public let targetRepositoryID: String
  public let targetRef: String
  public let state: WritingSubnodeTransferState
  public let accepted: Bool
  public let published: Bool

  enum CodingKeys: String, CodingKey {
    case targetRepositoryID = "target_repository_id"
    case targetRef = "target_ref"
    case state
    case accepted
    case published
  }
}

public struct WritingSubnodePassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let outcome: WritingSubnodeOutcome
  public let episodeID: String
  public let stepGenerationID: String
  public let cardID: String
  public let stepID: String
  public let runID: String
  public let subnodeID: String
  public let cloneID: String
  public let repositoryID: String
  public let packageID: String
  public let workPackageSHA256: String
  public let workPackageReportSHA256: String
  public let executionRequestSHA256: String
  public let sourceRepositorySHA256: String
  public let baseOID: String
  public let parentOID: String
  public let treeOID: String
  public let commitOID: String
  public let branchRef: String
  public let resultRef: String
  public let inputs: [WritingSubnodePassportInput]
  public let dependencies: [WritingSubnodePassportDependency]
  public let actualPaths: [String]
  public let diffSHA256: String
  public let checks: [WritingSubnodeRecordedCheck]
  public let constraints: WritingSubnodePassportConstraints
  public let budget: WritingSubnodePassportBudget
  public let handoff: WritingSubnodePassportHandoff
  public let transfer: WritingSubnodePassportTransfer

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case outcome
    case episodeID = "episode_id"
    case stepGenerationID = "step_generation_id"
    case cardID = "card_id"
    case stepID = "step_id"
    case runID = "run_id"
    case subnodeID = "subnode_id"
    case cloneID = "clone_id"
    case repositoryID = "repository_id"
    case packageID = "package_id"
    case workPackageSHA256 = "work_package_sha256"
    case workPackageReportSHA256 = "work_package_report_sha256"
    case executionRequestSHA256 = "execution_request_sha256"
    case sourceRepositorySHA256 = "source_repository_sha256"
    case baseOID = "base_oid"
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
    case commitOID = "commit_oid"
    case branchRef = "branch_ref"
    case resultRef = "result_ref"
    case inputs
    case dependencies
    case actualPaths = "actual_paths"
    case diffSHA256 = "diff_sha256"
    case checks
    case constraints
    case budget
    case handoff
    case transfer
  }

  public func canonicalJSONData() throws -> Data {
    try WritingSubnodeJSON.encode(self)
  }
}

public struct WritingSubnodeExecutionResult: Sendable {
  public let outcome: WritingSubnodeOutcome
  public let passport: WritingSubnodePassport?
  public let passportCanonicalJSON: Data?
  public let passportSHA256: String?
  public let cloneURL: URL?
  public let parentUnchanged: Bool
  public let workPackageReport: WorkPackageReport?

  fileprivate init(
    outcome: WritingSubnodeOutcome,
    passport: WritingSubnodePassport? = nil,
    passportCanonicalJSON: Data? = nil,
    cloneURL: URL? = nil,
    parentUnchanged: Bool = true,
    workPackageReport: WorkPackageReport? = nil
  ) {
    self.outcome = outcome
    self.passport = passport
    self.passportCanonicalJSON = passportCanonicalJSON
    passportSHA256 = passportCanonicalJSON.map(WritingSubnodeJSON.sha256)
    self.cloneURL = cloneURL
    self.parentUnchanged = parentUnchanged
    self.workPackageReport = workPackageReport
  }
}

public enum WritingSubnodeExecutorError: Error, CustomStringConvertible, Sendable {
  case invalidRequest(String)
  case unsafePath(String)
  case gitFailed(String)
  case persistenceFailed(String)
  case sourceChanged

  public var description: String {
    switch self {
    case .invalidRequest(let message): message
    case .unsafePath(let message): message
    case .gitFailed(let message): message
    case .persistenceFailed(let message): message
    case .sourceChanged: "Исходный checkout изменился во время исполнения."
    }
  }
}

public struct WritingSubnodePassportStore: Sendable {
  public let rootURL: URL

  public init(rootURL: URL) {
    self.rootURL = rootURL
  }

  public func load(runID: String) throws -> WritingSubnodePassport {
    guard WritingSubnodeValidation.isIdentifier(runID) else {
      throw WritingSubnodeExecutorError.invalidRequest("Некорректный run_id.")
    }
    let passportRoot = rootURL.appending(path: "passports", directoryHint: .isDirectory)
    guard WritingSubnodePersistence.isPlainDirectory(passportRoot) else {
      throw WritingSubnodeExecutorError.unsafePath("Каталог паспортов небезопасен.")
    }
    let url =
      passportRoot
      .appending(path: "\(runID).json")
    let data = try WritingSubnodePersistence.readStableRegularFile(
      at: url,
      maximumBytes: 1_048_576
    )
    let passport = try JSONDecoder().decode(WritingSubnodePassport.self, from: data)
    guard passport.schemaIdentity == "fum.writing-subnode.candidate-passport",
      passport.schemaVersion == 1,
      passport.outcome == .candidateCommitted,
      passport.runID == runID,
      try passport.canonicalJSONData() == data
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Паспорт не является каноническим JSON.")
    }
    return passport
  }
}

public struct WritingSubnodeCandidateRecovery: Sendable {
  public init() {}

  public func recover(
    executionRootURL: URL,
    runID: String
  ) throws -> WritingSubnodeExecutionResult {
    try WritingSubnodeRecovery.recover(
      executionRootURL: executionRootURL,
      runID: runID,
      expectedExecutionRequestSHA256: nil
    )
  }
}

public struct WritingSubnodeExecutor: Sendable {
  private let checkRegistry: WritingSubnodeCheckRegistry

  public init(checkRegistry: WritingSubnodeCheckRegistry = WritingSubnodeCheckRegistry()) {
    self.checkRegistry = checkRegistry
  }

  public func verifyWorkPackage(
    _ data: Data,
    workspaceRoot: URL
  ) -> WritingSubnodeWorkPackageVerification {
    let report = WorkPackagePreflight.analyze(data, workspaceRoot: workspaceRoot)
    guard report.decision == .ready,
      let package = try? JSONDecoder().decode(WritingWorkPackageEnvelope.self, from: data)
    else {
      return .blocked(report)
    }
    return .ready(
      VerifiedWritingSubnodeWorkPackage(
        data: data,
        workspaceRoot: workspaceRoot,
        report: report,
        snapshot: WritingWorkPackageSnapshot(package)
      )
    )
  }

  public func execute(
    workPackageData: Data,
    workspaceRoot: URL,
    request: WritingSubnodeExecutionRequest
  ) throws -> WritingSubnodeExecutionResult {
    switch verifyWorkPackage(workPackageData, workspaceRoot: workspaceRoot) {
    case .ready(let verified):
      return try execute(verified, request: request)
    case .blocked(let report):
      return try recordBlockedWorkPackage(
        workPackageData,
        workspaceRoot: workspaceRoot,
        request: request,
        report: report
      )
    }
  }

  private func recordBlockedWorkPackage(
    _ workPackageData: Data,
    workspaceRoot: URL,
    request: WritingSubnodeExecutionRequest,
    report: WorkPackageReport
  ) throws -> WritingSubnodeExecutionResult {
    try WritingSubnodeValidation.validate(request)
    let sourceURL = request.sourceCheckoutURL.standardizedFileURL.resolvingSymlinksInPath()
    let executionRootURL = request.executionRootURL.standardizedFileURL.resolvingSymlinksInPath()
    let verifiedWorkspaceURL = workspaceRoot.standardizedFileURL.resolvingSymlinksInPath()
    guard verifiedWorkspaceURL == sourceURL,
      !WritingSubnodeValidation.isDescendant(executionRootURL, of: sourceURL),
      !WritingSubnodeValidation.isDescendant(sourceURL, of: executionRootURL),
      executionRootURL != sourceURL
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Рабочая область должна совпадать с исходным checkout, а каталог исполнения — быть отдельным и не охватывать его."
      )
    }
    let git = WritingSubnodeGit()
    try WritingSubnodeValidation.validateRef(request.targetRef, git: git)
    try WritingSubnodeSourceAudit.validateConfiguration(sourceURL, git: git)
    let sourceBefore = try SourceRepositorySnapshot.capture(sourceURL, git: git)
    func finish(_ outcome: WritingSubnodeOutcome) throws -> WritingSubnodeExecutionResult {
      guard try SourceRepositorySnapshot.capture(sourceURL, git: git) == sourceBefore else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      return WritingSubnodeExecutionResult(
        outcome: outcome,
        workPackageReport: report
      )
    }
    do {
      let executionRequestSHA256 = try stableRequestSHA256(
        request,
        workPackageSHA256: WritingSubnodeJSON.sha256(workPackageData),
        sourceRepositorySHA256: try sourceBefore.canonicalSHA256(),
        checks: []
      )
      try WritingSubnodePersistence.ensurePlainDirectory(executionRootURL)
      let runRoot = executionRootURL.appending(path: "runs", directoryHint: .isDirectory)
      try WritingSubnodePersistence.ensurePlainDirectory(runRoot)
      let runURL = runRoot.appending(path: request.runID, directoryHint: .isDirectory)
      _ = try WritingSubnodePersistence.reserveDirectory(runURL)
      let runLock = try WritingSubnodePersistence.acquireRunLock(
        at: runURL.appending(path: "execution.lock")
      )
      guard let runLock else {
        return try finish(.runAlreadyExists)
      }
      defer { runLock.release() }

      let requestHashURL = runURL.appending(path: "request.sha256")
      if WritingSubnodePersistence.pathExists(requestHashURL) {
        let recorded = try WritingSubnodePersistence.readStableUTF8RegularFile(
          at: requestHashURL,
          maximumBytes: 128
        )
        guard recorded == executionRequestSHA256 else {
          return try finish(.runAlreadyExists)
        }
      } else {
        try WritingSubnodePersistence.persistExclusive(
          Data(executionRequestSHA256.utf8),
          at: requestHashURL
        )
      }

      let receiptStore = WritingSubnodeRunReceiptStore(runURL: runURL)
      if let receipt = try receiptStore.loadIfPresent() {
        guard receipt.executionRequestSHA256 == executionRequestSHA256,
          receipt.outcome == .blockedBeforeWrite,
          receipt.passportSHA256 == nil
        else {
          return try finish(.runAlreadyExists)
        }
      } else {
        let cloneURL = runURL.appending(path: "clone", directoryHint: .isDirectory)
        let passportURL =
          executionRootURL
          .appending(path: "passports", directoryHint: .isDirectory)
          .appending(path: "\(request.runID).json")
        guard !WritingSubnodePersistence.pathExists(cloneURL),
          !WritingSubnodePersistence.pathExists(passportURL)
        else {
          return try finish(.runAlreadyExists)
        }
        try receiptStore.persist(
          WritingSubnodeRunReceipt(
            executionRequestSHA256: executionRequestSHA256,
            outcome: .blockedBeforeWrite,
            passportSHA256: nil
          )
        )
      }
      return try finish(.blockedBeforeWrite)
    } catch {
      guard (try? SourceRepositorySnapshot.capture(sourceURL, git: git)) == sourceBefore else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      throw error
    }
  }

  public func execute(
    _ verifiedPackage: VerifiedWritingSubnodeWorkPackage,
    request: WritingSubnodeExecutionRequest
  ) throws -> WritingSubnodeExecutionResult {
    try WritingSubnodeValidation.validate(request)
    let sourceURL = request.sourceCheckoutURL.standardizedFileURL.resolvingSymlinksInPath()
    let executionRootURL = request.executionRootURL.standardizedFileURL.resolvingSymlinksInPath()
    let verifiedWorkspaceURL =
      verifiedPackage.workspaceRoot.standardizedFileURL.resolvingSymlinksInPath()
    guard verifiedWorkspaceURL == sourceURL,
      !WritingSubnodeValidation.isDescendant(executionRootURL, of: sourceURL),
      !WritingSubnodeValidation.isDescendant(sourceURL, of: executionRootURL),
      executionRootURL != sourceURL
    else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Проверенная рабочая область должна совпадать с исходным checkout, а каталог исполнения — быть отдельным и не охватывать его."
      )
    }
    let git = WritingSubnodeGit()
    try WritingSubnodeSourceAudit.validateConfiguration(sourceURL, git: git)
    let sourceBefore = try SourceRepositorySnapshot.capture(sourceURL, git: git)
    do {
      let result = try executeIsolated(
        verifiedPackage,
        request: request,
        sourceURL: sourceURL,
        executionRootURL: executionRootURL,
        sourceBefore: sourceBefore,
        git: git
      )
      guard try SourceRepositorySnapshot.capture(sourceURL, git: git) == sourceBefore else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      return result
    } catch {
      guard (try? SourceRepositorySnapshot.capture(sourceURL, git: git)) == sourceBefore else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      throw error
    }
  }

  private func executeIsolated(
    _ verifiedPackage: VerifiedWritingSubnodeWorkPackage,
    request: WritingSubnodeExecutionRequest,
    sourceURL: URL,
    executionRootURL: URL,
    sourceBefore: SourceRepositorySnapshot,
    git: WritingSubnodeGit
  ) throws -> WritingSubnodeExecutionResult {
    let branchRef = "refs/heads/fum-step/\(request.stepID)/\(request.subnodeID)-\(request.runID)"
    let resultRef =
      "refs/fum/results/\(request.repositoryID)/\(request.stepID)/\(request.subnodeID)-\(request.runID)"
    try WritingSubnodeValidation.validateRef(branchRef, git: git)
    try WritingSubnodeValidation.validateRef(resultRef, git: git)
    try WritingSubnodeValidation.validateRef(request.targetRef, git: git)
    let stableChecks = try checkRegistry.stableBindings(verifiedPackage.snapshot.checkIDs)
    let sourceRepositorySHA256 = try sourceBefore.canonicalSHA256()
    let executionRequestSHA256 = try stableRequestSHA256(
      request,
      workPackageSHA256: verifiedPackage.report.contractSHA256,
      sourceRepositorySHA256: sourceRepositorySHA256,
      checks: stableChecks
    )
    try WritingSubnodePersistence.ensurePlainDirectory(executionRootURL)
    let runRoot = executionRootURL.appending(path: "runs", directoryHint: .isDirectory)
    try WritingSubnodePersistence.ensurePlainDirectory(runRoot)
    let runURL = runRoot.appending(path: request.runID, directoryHint: .isDirectory)
    _ = try WritingSubnodePersistence.reserveDirectory(runURL)
    let runLock = try WritingSubnodePersistence.acquireRunLock(
      at: runURL.appending(path: "execution.lock")
    )
    guard let runLock else {
      return WritingSubnodeExecutionResult(outcome: .runAlreadyExists)
    }
    defer { runLock.release() }

    let requestHashURL = runURL.appending(path: "request.sha256")
    if WritingSubnodePersistence.pathExists(requestHashURL) {
      let recorded = try WritingSubnodePersistence.readStableUTF8RegularFile(
        at: requestHashURL, maximumBytes: 128)
      guard recorded == executionRequestSHA256 else {
        return WritingSubnodeExecutionResult(outcome: .runAlreadyExists)
      }
    } else {
      try WritingSubnodePersistence.persistExclusive(
        Data(executionRequestSHA256.utf8), at: requestHashURL)
    }

    let cloneURL = runURL.appending(path: "clone", directoryHint: .isDirectory)
    let receiptStore = WritingSubnodeRunReceiptStore(runURL: runURL)
    if let receipt = try receiptStore.loadIfPresent() {
      guard receipt.executionRequestSHA256 == executionRequestSHA256 else {
        return WritingSubnodeExecutionResult(outcome: .runAlreadyExists)
      }
      if receipt.outcome == .candidateCommitted {
        let recovered = try WritingSubnodeRecovery.recover(
          executionRootURL: executionRootURL,
          runID: request.runID,
          expectedExecutionRequestSHA256: executionRequestSHA256
        )
        guard recovered.passportSHA256 == receipt.passportSHA256 else {
          throw WritingSubnodeExecutorError.persistenceFailed(
            "Квитанция запуска не совпадает с проверенным паспортом."
          )
        }
        return recovered
      }
      return WritingSubnodeExecutionResult(
        outcome: receipt.outcome,
        cloneURL: WritingSubnodePersistence.isPlainDirectory(cloneURL) ? cloneURL : nil
      )
    }
    let passportURL = executionRootURL.appending(path: "passports", directoryHint: .isDirectory)
      .appending(path: "\(request.runID).json")
    if WritingSubnodePersistence.pathExists(passportURL) {
      let recovered = try WritingSubnodeRecovery.recover(
        executionRootURL: executionRootURL,
        runID: request.runID,
        expectedExecutionRequestSHA256: executionRequestSHA256
      )
      try receiptStore.persist(
        WritingSubnodeRunReceipt(
          executionRequestSHA256: executionRequestSHA256,
          outcome: .candidateCommitted,
          passportSHA256: recovered.passportSHA256
        )
      )
      return recovered
    }
    try WritingSubnodePersistence.archiveIncompleteCloneIfPresent(cloneURL, in: runURL)

    func finish(
      _ outcome: WritingSubnodeOutcome,
      cloneURL: URL? = nil,
      report: WorkPackageReport? = nil
    ) throws -> WritingSubnodeExecutionResult {
      precondition(outcome != .candidateCommitted)
      try receiptStore.persist(
        WritingSubnodeRunReceipt(
          executionRequestSHA256: executionRequestSHA256,
          outcome: outcome,
          passportSHA256: nil
        )
      )
      return WritingSubnodeExecutionResult(
        outcome: outcome,
        cloneURL: cloneURL,
        workPackageReport: report
      )
    }

    guard verifiedPackage.snapshot.checkIDs.allSatisfy(checkRegistry.contains) else {
      return try finish(.blockedBeforeWrite)
    }

    let sourceHead = try git.text(["rev-parse", "--verify", "HEAD^{commit}"], at: sourceURL)
    guard sourceHead == request.baseOID else {
      return try finish(.baseChanged)
    }
    guard try git.text(["cat-file", "-t", request.baseOID], at: sourceURL) == "commit" else {
      return try finish(.baseChanged)
    }
    guard
      try git.text(
        ["for-each-ref", "--format=%(objectname)", "--", branchRef, resultRef],
        at: sourceURL
      ).isEmpty
    else {
      return try finish(.runAlreadyExists)
    }

    let currentReport = WorkPackagePreflight.analyze(
      verifiedPackage.data,
      workspaceRoot: verifiedPackage.workspaceRoot
    )
    guard currentReport == verifiedPackage.report else {
      let inputViolation = currentReport.violations.contains {
        $0.code.hasPrefix("input_") || $0.code.hasPrefix("required_input")
      }
      return try finish(
        inputViolation ? .inputChanged : .blockedBeforeWrite,
        report: currentReport
      )
    }
    guard sourceBefore.status.isEmpty else {
      return try finish(.dirtySource)
    }
    guard request.writes.allSatisfy({ WritingSubnodeValidation.isRelativePath($0.path) }),
      request.writes.allSatisfy({ verifiedPackage.snapshot.permits($0.path) })
    else {
      return try finish(.forbiddenPath)
    }
    let cloneID = "writing-clone-\(request.stepID)-\(request.subnodeID)-\(request.runID)"
    let publicationValues =
      [
        request.episodeID, request.stepGenerationID, request.cardID, request.stepID,
        request.runID, request.subnodeID, request.repositoryID, request.targetRef,
        request.commitMessage, verifiedPackage.snapshot.packageID,
        verifiedPackage.snapshot.changePolicy, verifiedPackage.snapshot.handoffFormat,
        verifiedPackage.snapshot.budget.unit, branchRef, resultRef, cloneID,
      ]
      + verifiedPackage.snapshot.dependencies.flatMap { [$0.id, $0.status, $0.evidence] }
      + verifiedPackage.snapshot.inputs.flatMap { [$0.id, $0.path, $0.sha256] }
      + verifiedPackage.snapshot.checkIDs
      + request.writes.map(\.path)
      + verifiedPackage.snapshot.allowedPaths + verifiedPackage.snapshot.excludedPaths
      + verifiedPackage.snapshot.requiredArtifacts
    if let unsafeValue = publicationValues.lazy.compactMap({
      WritingSubnodeValidation.publicationOutcome(Data($0.utf8))
    }).first {
      return try finish(unsafeValue)
    }
    if let unsafeWrite = request.writes.lazy.compactMap({
      WritingSubnodeValidation.publicationOutcome($0.contents)
    }).first {
      return try finish(unsafeWrite)
    }

    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        sourceURL.path, cloneURL.path,
      ],
      at: executionRootURL
    )
    _ = try git.data(["remote", "remove", "origin"], at: cloneURL)
    try verifyCloneIsolation(cloneURL: cloneURL, sourceURL: sourceURL, git: git)
    let shortBranch = String(branchRef.dropFirst("refs/heads/".count))
    _ = try git.data(
      ["checkout", "--quiet", "-b", shortBranch, request.baseOID, "--"], at: cloneURL)
    guard
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: cloneURL).isEmpty,
      try git.text(["rev-parse", "HEAD"], at: cloneURL) == request.baseOID
    else {
      return try finish(.dirtySource, cloneURL: cloneURL)
    }

    for write in request.writes.sorted(by: { $0.path < $1.path }) {
      do {
        try WritingSubnodePersistence.materialize(write, cloneURL: cloneURL)
      } catch WritingSubnodeExecutorError.unsafePath {
        return try finish(.forbiddenPath, cloneURL: cloneURL)
      }
      _ = try git.data(["add", "--", write.path], at: cloneURL)
    }
    let actualPaths = try git.nulStrings(
      [
        "diff", "--cached", "--no-ext-diff", "--no-textconv", "--name-only", "--no-renames",
        "-z", request.baseOID, "--",
      ],
      at: cloneURL
    ).sorted()
    guard !actualPaths.isEmpty else {
      return try finish(.noOp, cloneURL: cloneURL)
    }
    guard actualPaths.allSatisfy(verifiedPackage.snapshot.permits),
      Set(actualPaths).isSubset(of: Set(request.writes.map(\.path))),
      Set(verifiedPackage.snapshot.requiredArtifacts).isSubset(of: Set(actualPaths))
    else {
      return try finish(.forbiddenPath, cloneURL: cloneURL)
    }
    let preCheckTreeOID = try git.text(["write-tree"], at: cloneURL)
    if let outcome = try validateCandidateTree(
      paths: actualPaths,
      treeOID: preCheckTreeOID,
      cloneURL: cloneURL,
      git: git
    ) {
      return try finish(outcome, cloneURL: cloneURL)
    }
    let preCheckStatus = try git.data(
      ["status", "--porcelain=v2", "-z", "--untracked-files=all"],
      at: cloneURL
    )

    var observations: [WritingSubnodeRecordedCheck] = []
    let stableChecksByID = Dictionary(
      uniqueKeysWithValues: stableChecks.map { ($0.checkID, $0.specificationSHA256) }
    )
    for checkID in verifiedPackage.snapshot.checkIDs {
      let observation = checkRegistry.run(
        checkID,
        treeOID: preCheckTreeOID,
        checkoutURL: cloneURL,
        git: git
      )
      observations.append(
        WritingSubnodeRecordedCheck(
          checkID: checkID,
          specificationSHA256: stableChecksByID[checkID] ?? "",
          status: observation.status,
          evidence: WritingSubnodeValidation.safeEvidence(observation.evidence)
        )
      )
    }
    guard observations.allSatisfy({ $0.status == .passed }) else {
      return try finish(.checkFailed, cloneURL: cloneURL)
    }

    let finalPaths = try git.nulStrings(
      [
        "diff", "--cached", "--no-ext-diff", "--no-textconv", "--name-only", "--no-renames",
        "-z", request.baseOID, "--",
      ],
      at: cloneURL
    ).sorted()
    let treeOID = try git.text(["write-tree"], at: cloneURL)
    let finalStatus = try git.data(
      ["status", "--porcelain=v2", "-z", "--untracked-files=all"],
      at: cloneURL
    )
    guard finalPaths.allSatisfy(verifiedPackage.snapshot.permits),
      Set(finalPaths).isSubset(of: Set(request.writes.map(\.path))),
      Set(verifiedPackage.snapshot.requiredArtifacts).isSubset(of: Set(finalPaths))
    else {
      return try finish(.forbiddenPath, cloneURL: cloneURL)
    }
    if let outcome = try validateCandidateTree(
      paths: finalPaths,
      treeOID: treeOID,
      cloneURL: cloneURL,
      git: git
    ) {
      return try finish(outcome, cloneURL: cloneURL)
    }
    guard finalPaths == actualPaths,
      treeOID == preCheckTreeOID,
      finalStatus == preCheckStatus
    else {
      return try finish(.forbiddenPath, cloneURL: cloneURL)
    }
    let baseTreeOID = try git.text(["rev-parse", "\(request.baseOID)^{tree}"], at: cloneURL)
    guard treeOID != baseTreeOID else {
      return try finish(.noOp, cloneURL: cloneURL)
    }
    let diff = try git.data(
      [
        "diff", "--cached", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        request.baseOID, "--",
      ],
      at: cloneURL
    )
    if let diffOutcome = WritingSubnodeValidation.publicationOutcome(
      diff,
      allowingGitNullDevice: true
    ) {
      return try finish(diffOutcome, cloneURL: cloneURL)
    }
    let commitOID = try git.text(
      ["commit-tree", treeOID, "-p", request.baseOID],
      at: cloneURL,
      input: Data((request.commitMessage + "\n").utf8),
      additionalEnvironment: [
        "GIT_AUTHOR_NAME": "FUM Writing Subnode",
        "GIT_AUTHOR_EMAIL": "writing-subnode@invalid",
        "GIT_AUTHOR_DATE": "2000-01-01T00:00:00Z",
        "GIT_COMMITTER_NAME": "FUM Writing Subnode",
        "GIT_COMMITTER_EMAIL": "writing-subnode@invalid",
        "GIT_COMMITTER_DATE": "2000-01-01T00:00:00Z",
      ]
    )
    let refTransaction = Data(
      """
      start
      update \(branchRef) \(commitOID) \(request.baseOID)
      create \(resultRef) \(commitOID)
      prepare
      commit

      """.utf8
    )
    _ = try git.data(["update-ref", "--stdin"], at: cloneURL, input: refTransaction)
    let topology = try git.text(["rev-list", "--parents", "-n", "1", commitOID], at: cloneURL)
      .split(separator: " ").map(String.init)
    guard topology == [commitOID, request.baseOID],
      try git.text(["rev-parse", "\(commitOID)^{tree}"], at: cloneURL) == treeOID,
      try git.text(["rev-parse", branchRef], at: cloneURL) == commitOID,
      try git.text(["rev-parse", resultRef], at: cloneURL) == commitOID
    else {
      throw WritingSubnodeExecutorError.gitFailed("Кандидатный commit не прошёл итоговую проверку.")
    }

    let reportData = try verifiedPackage.report.canonicalJSONData()
    let snapshot = verifiedPackage.snapshot
    let passport = WritingSubnodePassport(
      schemaIdentity: "fum.writing-subnode.candidate-passport",
      schemaVersion: 1,
      outcome: .candidateCommitted,
      episodeID: request.episodeID,
      stepGenerationID: request.stepGenerationID,
      cardID: request.cardID,
      stepID: request.stepID,
      runID: request.runID,
      subnodeID: request.subnodeID,
      cloneID: cloneID,
      repositoryID: request.repositoryID,
      packageID: snapshot.packageID,
      workPackageSHA256: verifiedPackage.report.contractSHA256,
      workPackageReportSHA256: WritingSubnodeJSON.sha256(reportData),
      executionRequestSHA256: executionRequestSHA256,
      sourceRepositorySHA256: sourceRepositorySHA256,
      baseOID: request.baseOID,
      parentOID: request.baseOID,
      treeOID: treeOID,
      commitOID: commitOID,
      branchRef: branchRef,
      resultRef: resultRef,
      inputs: snapshot.inputs.map {
        WritingSubnodePassportInput(
          inputID: $0.id,
          path: $0.path,
          sha256: $0.sha256,
          required: $0.required
        )
      },
      dependencies: snapshot.dependencies.map {
        WritingSubnodePassportDependency(
          dependencyID: $0.id,
          status: $0.status,
          evidence: $0.evidence
        )
      },
      actualPaths: finalPaths,
      diffSHA256: WritingSubnodeJSON.sha256(diff),
      checks: observations,
      constraints: WritingSubnodePassportConstraints(
        changePolicy: snapshot.changePolicy,
        allowedPaths: snapshot.allowedPaths,
        excludedPaths: snapshot.excludedPaths,
        isolatedClone: true,
        sourceMutationAllowed: false,
        modelCallsAllowed: false,
        networkAllowed: false,
        integrationAllowed: false
      ),
      budget: WritingSubnodePassportBudget(
        unit: snapshot.budget.unit,
        limit: snapshot.budget.limit,
        reading: snapshot.budget.reading,
        work: snapshot.budget.work,
        verification: snapshot.budget.verification,
        response: snapshot.budget.response,
        reserve: snapshot.budget.reserve
      ),
      handoff: WritingSubnodePassportHandoff(
        format: snapshot.handoffFormat,
        requiredArtifacts: snapshot.requiredArtifacts
      ),
      transfer: WritingSubnodePassportTransfer(
        targetRepositoryID: request.repositoryID,
        targetRef: request.targetRef,
        state: .prepared,
        accepted: false,
        published: false
      )
    )
    let canonicalPassport = try passport.canonicalJSONData()
    guard WritingSubnodeValidation.publicationOutcome(canonicalPassport) == nil else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Паспорт не прошёл публикационную проверку."
      )
    }
    let passportRoot = executionRootURL.appending(path: "passports", directoryHint: .isDirectory)
    try WritingSubnodePersistence.ensurePlainDirectory(passportRoot)
    try WritingSubnodePersistence.persistExclusive(
      canonicalPassport,
      at: passportRoot.appending(path: "\(request.runID).json")
    )
    try receiptStore.persist(
      WritingSubnodeRunReceipt(
        executionRequestSHA256: executionRequestSHA256,
        outcome: .candidateCommitted,
        passportSHA256: WritingSubnodeJSON.sha256(canonicalPassport)
      )
    )
    return WritingSubnodeExecutionResult(
      outcome: .candidateCommitted,
      passport: passport,
      passportCanonicalJSON: canonicalPassport,
      cloneURL: cloneURL
    )
  }

  private func stableRequestSHA256(
    _ request: WritingSubnodeExecutionRequest,
    workPackageSHA256: String,
    sourceRepositorySHA256: String,
    checks: [WritingStableCheck]
  ) throws -> String {
    let stable = WritingStableExecutionRequest(
      schemaVersion: 1,
      episodeID: request.episodeID,
      stepGenerationID: request.stepGenerationID,
      cardID: request.cardID,
      stepID: request.stepID,
      runID: request.runID,
      subnodeID: request.subnodeID,
      repositoryID: request.repositoryID,
      targetRef: request.targetRef,
      baseOID: request.baseOID,
      workPackageSHA256: workPackageSHA256,
      sourceRepositorySHA256: sourceRepositorySHA256,
      commitMessage: request.commitMessage,
      checks: checks,
      writes: request.writes.sorted(by: { $0.path < $1.path }).map {
        WritingStableWrite(
          path: $0.path,
          contentsSHA256: WritingSubnodeJSON.sha256($0.contents),
          byteCount: $0.contents.count
        )
      }
    )
    return WritingSubnodeJSON.sha256(try WritingSubnodeJSON.encode(stable))
  }

  private func verifyCloneIsolation(cloneURL: URL, sourceURL: URL, git: WritingSubnodeGit) throws {
    let sourceGit = try git.text(["rev-parse", "--absolute-git-dir"], at: sourceURL)
    let cloneGit = try git.text(["rev-parse", "--absolute-git-dir"], at: cloneURL)
    let cloneCommon = try git.text(
      ["rev-parse", "--path-format=absolute", "--git-common-dir"],
      at: cloneURL
    )
    let expected = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
      .standardizedFileURL.resolvingSymlinksInPath().path
    let alternates = URL(fileURLWithPath: cloneGit).appending(path: "objects/info/alternates")
    guard sourceGit != cloneGit,
      URL(fileURLWithPath: cloneGit).standardizedFileURL.resolvingSymlinksInPath().path == expected,
      URL(fileURLWithPath: cloneCommon).standardizedFileURL.resolvingSymlinksInPath().path
        == expected,
      !FileManager.default.fileExists(atPath: alternates.path)
    else {
      throw WritingSubnodeExecutorError.gitFailed("Git-метаданные клона не изолированы.")
    }
  }

  private func validateCandidateTree(
    paths: [String],
    treeOID: String,
    cloneURL: URL,
    git: WritingSubnodeGit
  ) throws -> WritingSubnodeOutcome? {
    try WritingSubnodeCandidateAudit.validateTree(
      paths: paths,
      treeOID: treeOID,
      cloneURL: cloneURL,
      git: git
    )
  }
}

enum WritingSubnodeCandidateAudit {
  static func validateTree(
    paths: [String],
    treeOID: String,
    cloneURL: URL,
    git: WritingSubnodeGit
  ) throws -> WritingSubnodeOutcome? {
    for path in paths {
      let records = try git.data(["ls-tree", "-z", treeOID, "--", path], at: cloneURL)
        .split(separator: 0, omittingEmptySubsequences: true)
      guard records.count == 1,
        let tab = records[0].firstIndex(of: 9)
      else {
        return .forbiddenPath
      }
      let metadata = records[0][..<tab].split(separator: 32)
      let recordedPath = String(
        decoding: records[0][records[0].index(after: tab)...], as: UTF8.self)
      guard metadata.count == 3,
        ["100644", "100755"].contains(String(decoding: metadata[0], as: UTF8.self)),
        String(decoding: metadata[1], as: UTF8.self) == "blob",
        recordedPath == path,
        WritingSubnodeValidation.isRelativePath(path)
      else {
        return .forbiddenPath
      }
      let blob = try git.data(["cat-file", "blob", "\(treeOID):\(path)"], at: cloneURL)
      if let outcome = WritingSubnodeValidation.publicationOutcome(blob) { return outcome }
    }
    return nil
  }
}

private enum WritingSubnodeRecovery {
  static func recover(
    executionRootURL: URL,
    runID: String,
    expectedExecutionRequestSHA256: String?
  ) throws -> WritingSubnodeExecutionResult {
    guard WritingSubnodeValidation.isIdentifier(runID) else {
      throw WritingSubnodeExecutorError.invalidRequest("Некорректный run_id.")
    }
    let root = executionRootURL.standardizedFileURL.resolvingSymlinksInPath()
    guard WritingSubnodePersistence.isPlainDirectory(root) else {
      throw WritingSubnodeExecutorError.unsafePath("Корень исполнения небезопасен.")
    }
    let runsURL = root.appending(path: "runs", directoryHint: .isDirectory)
    let runURL = runsURL.appending(path: runID, directoryHint: .isDirectory)
    let cloneURL = runURL.appending(path: "clone", directoryHint: .isDirectory)
    guard WritingSubnodePersistence.isPlainDirectory(runsURL),
      WritingSubnodePersistence.isPlainDirectory(runURL),
      WritingSubnodePersistence.isPlainDirectory(cloneURL)
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Изолированный клон запуска отсутствует.")
    }
    let recordedRequestSHA256 = try WritingSubnodePersistence.readStableUTF8RegularFile(
      at: runURL.appending(path: "request.sha256"),
      maximumBytes: 128
    )
    guard WritingSubnodeValidation.isSHA256(recordedRequestSHA256),
      expectedExecutionRequestSHA256.map({ $0 == recordedRequestSHA256 }) ?? true
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Хэш запроса запуска не совпадает.")
    }
    let passport = try WritingSubnodePassportStore(rootURL: root).load(runID: runID)
    let canonical = try passport.canonicalJSONData()
    let canonicalSHA256 = WritingSubnodeJSON.sha256(canonical)
    let receipt = try WritingSubnodeRunReceiptStore(runURL: runURL).loadIfPresent()
    if expectedExecutionRequestSHA256 == nil {
      guard receipt != nil else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Для независимого восстановления отсутствует квитанция запуска."
        )
      }
    }
    if let receipt {
      guard receipt.executionRequestSHA256 == recordedRequestSHA256,
        receipt.outcome == .candidateCommitted,
        receipt.passportSHA256 == canonicalSHA256
      else {
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Квитанция запуска не совпадает с каноническим паспортом."
        )
      }
    }
    let expectedBranchRef =
      "refs/heads/fum-step/\(passport.stepID)/\(passport.subnodeID)-\(passport.runID)"
    let expectedResultRef =
      "refs/fum/results/\(passport.repositoryID)/\(passport.stepID)/\(passport.subnodeID)-\(passport.runID)"
    let identifiers = [
      passport.episodeID, passport.stepGenerationID, passport.cardID, passport.stepID,
      passport.runID, passport.subnodeID, passport.repositoryID, passport.packageID,
    ]
    let hashes = [
      passport.workPackageSHA256, passport.workPackageReportSHA256,
      passport.executionRequestSHA256, passport.sourceRepositorySHA256, passport.diffSHA256,
    ]
    let budgetValues = [
      passport.budget.limit, passport.budget.reading, passport.budget.work,
      passport.budget.verification, passport.budget.response, passport.budget.reserve,
    ]
    guard identifiers.allSatisfy(WritingSubnodeValidation.isIdentifier),
      hashes.allSatisfy(WritingSubnodeValidation.isSHA256),
      passport.executionRequestSHA256 == recordedRequestSHA256,
      passport.baseOID == passport.parentOID,
      WritingSubnodeValidation.isObjectID(passport.commitOID),
      WritingSubnodeValidation.isObjectID(passport.treeOID),
      WritingSubnodeValidation.isObjectID(passport.parentOID),
      passport.branchRef == expectedBranchRef,
      passport.resultRef == expectedResultRef,
      passport.cloneID
        == "writing-clone-\(passport.stepID)-\(passport.subnodeID)-\(passport.runID)",
      passport.actualPaths == passport.actualPaths.sorted(),
      Set(passport.actualPaths).count == passport.actualPaths.count,
      passport.actualPaths.allSatisfy(WritingSubnodeValidation.isRelativePath),
      passport.inputs.allSatisfy({
        WritingSubnodeValidation.isIdentifier($0.inputID)
          && WritingSubnodeValidation.isRelativePath($0.path)
          && WritingSubnodeValidation.isSHA256($0.sha256)
      }),
      passport.dependencies.allSatisfy({
        WritingSubnodeValidation.isIdentifier($0.dependencyID)
          && WritingSubnodeValidation.isIdentifier($0.status)
          && WritingSubnodeValidation.publicationOutcome(Data($0.evidence.utf8)) == nil
      }),
      passport.constraints.allowedPaths.allSatisfy(WritingSubnodeValidation.isRelativePath),
      passport.constraints.excludedPaths.allSatisfy(WritingSubnodeValidation.isScopePath),
      passport.handoff.requiredArtifacts.allSatisfy(WritingSubnodeValidation.isRelativePath),
      WritingSubnodeValidation.isIdentifier(passport.handoff.format),
      WritingSubnodeValidation.isIdentifier(passport.budget.unit),
      budgetValues.allSatisfy({ (0...1_000_000).contains($0) }),
      passport.budget.reading + passport.budget.work + passport.budget.verification
        + passport.budget.response + passport.budget.reserve <= passport.budget.limit,
      passport.transfer.targetRepositoryID == passport.repositoryID,
      passport.transfer.state == .prepared,
      !passport.transfer.accepted,
      !passport.transfer.published,
      passport.constraints.isolatedClone,
      !passport.constraints.sourceMutationAllowed,
      !passport.constraints.modelCallsAllowed,
      !passport.constraints.networkAllowed,
      !passport.constraints.integrationAllowed,
      passport.checks.allSatisfy({
        $0.status == .passed
          && WritingSubnodeValidation.isSHA256($0.specificationSHA256)
          && WritingSubnodeValidation.publicationOutcome(Data($0.evidence.utf8)) == nil
      }),
      WritingSubnodeValidation.publicationOutcome(canonical) == nil
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Паспорт не прошёл независимую проверку.")
    }
    try WritingSubnodeValidation.validateRef(passport.branchRef, git: WritingSubnodeGit())
    try WritingSubnodeValidation.validateRef(passport.resultRef, git: WritingSubnodeGit())
    try WritingSubnodeValidation.validateRef(passport.transfer.targetRef, git: WritingSubnodeGit())

    let git = WritingSubnodeGit()
    let cloneGitURL = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
    guard WritingSubnodePersistence.isPlainDirectory(cloneGitURL) else {
      throw WritingSubnodeExecutorError.unsafePath(
        "Git-каталог восстановленного клона небезопасен."
      )
    }
    _ = try WritingSubnodeFilesystem.byteInventorySHA256(at: cloneURL)
    try WritingSubnodeSourceAudit.validateConfiguration(cloneURL, git: git)
    try validateCloneLayout(cloneURL: cloneURL, git: git)
    guard
      try git.text(["rev-parse", "--verify", passport.branchRef], at: cloneURL)
        == passport.commitOID,
      try git.text(["cat-file", "-t", passport.branchRef], at: cloneURL) == "commit",
      try git.text(["rev-parse", "--verify", passport.resultRef], at: cloneURL)
        == passport.commitOID,
      try git.text(["cat-file", "-t", passport.resultRef], at: cloneURL) == "commit",
      try git.text(["rev-parse", "\(passport.commitOID)^{tree}"], at: cloneURL)
        == passport.treeOID,
      try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: cloneURL).isEmpty
    else {
      throw WritingSubnodeExecutorError.gitFailed("Ссылки или рабочее дерево кандидата изменены.")
    }
    let topology = try git.text(
      ["rev-list", "--parents", "-n", "1", passport.commitOID],
      at: cloneURL
    ).split(separator: " ").map(String.init)
    guard topology == [passport.commitOID, passport.parentOID] else {
      throw WritingSubnodeExecutorError.gitFailed("Топология кандидатного commit изменилась.")
    }
    let actualPaths = try git.nulStrings(
      [
        "diff", "--name-only", "--no-ext-diff", "--no-textconv", "--no-renames", "-z",
        passport.parentOID, passport.commitOID, "--",
      ],
      at: cloneURL
    ).sorted()
    let permitted = actualPaths.allSatisfy { path in
      passport.constraints.allowedPaths.contains {
        WritingSubnodeValidation.path(path, isWithin: $0)
      }
        && !passport.constraints.excludedPaths.contains {
          WritingSubnodeValidation.pathsOverlap(path, $0)
        }
    }
    guard actualPaths == passport.actualPaths,
      permitted,
      Set(passport.handoff.requiredArtifacts).isSubset(of: Set(actualPaths)),
      try WritingSubnodeCandidateAudit.validateTree(
        paths: actualPaths,
        treeOID: passport.treeOID,
        cloneURL: cloneURL,
        git: git
      ) == nil
    else {
      throw WritingSubnodeExecutorError.gitFailed("Diff кандидата вышел за проверенную область.")
    }
    let diff = try git.data(
      [
        "diff", "--binary", "--no-ext-diff", "--no-textconv", "--no-renames",
        passport.parentOID, passport.commitOID, "--",
      ],
      at: cloneURL
    )
    guard WritingSubnodeJSON.sha256(diff) == passport.diffSHA256,
      WritingSubnodeValidation.publicationOutcome(diff, allowingGitNullDevice: true) == nil
    else {
      throw WritingSubnodeExecutorError.gitFailed("Содержимое diff кандидата изменено.")
    }
    return WritingSubnodeExecutionResult(
      outcome: .candidateCommitted,
      passport: passport,
      passportCanonicalJSON: canonical,
      cloneURL: cloneURL
    )
  }

  private static func validateCloneLayout(cloneURL: URL, git: WritingSubnodeGit) throws {
    let cloneGit = try git.text(["rev-parse", "--absolute-git-dir"], at: cloneURL)
    let cloneCommon = try git.text(
      ["rev-parse", "--path-format=absolute", "--git-common-dir"], at: cloneURL)
    let expected = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
      .standardizedFileURL.path
    let alternates = URL(fileURLWithPath: cloneGit).appending(path: "objects/info/alternates")
    guard
      URL(fileURLWithPath: cloneGit).standardizedFileURL.path == expected,
      URL(fileURLWithPath: cloneCommon).standardizedFileURL.path == expected,
      !WritingSubnodePersistence.pathExists(alternates),
      try git.text(["remote"], at: cloneURL).isEmpty
    else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Git-метаданные восстановленного клона небезопасны.")
    }
  }
}

private struct WritingStableExecutionRequest: Encodable {
  let schemaVersion: Int
  let episodeID: String
  let stepGenerationID: String
  let cardID: String
  let stepID: String
  let runID: String
  let subnodeID: String
  let repositoryID: String
  let targetRef: String
  let baseOID: String
  let workPackageSHA256: String
  let sourceRepositorySHA256: String
  let commitMessage: String
  let checks: [WritingStableCheck]
  let writes: [WritingStableWrite]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case stepGenerationID = "step_generation_id"
    case cardID = "card_id"
    case stepID = "step_id"
    case runID = "run_id"
    case subnodeID = "subnode_id"
    case repositoryID = "repository_id"
    case targetRef = "target_ref"
    case baseOID = "base_oid"
    case workPackageSHA256 = "work_package_sha256"
    case sourceRepositorySHA256 = "source_repository_sha256"
    case commitMessage = "commit_message"
    case checks
    case writes
  }
}

private struct WritingStableCheck: Encodable {
  let checkID: String
  let specificationSHA256: String

  enum CodingKeys: String, CodingKey {
    case checkID = "check_id"
    case specificationSHA256 = "specification_sha256"
  }
}

private struct WritingStableWrite: Encodable {
  let path: String
  let contentsSHA256: String
  let byteCount: Int

  enum CodingKeys: String, CodingKey {
    case path
    case contentsSHA256 = "contents_sha256"
    case byteCount = "byte_count"
  }
}

private struct WritingWorkPackageEnvelope: Decodable {
  let packageID: String
  let inputs: [WritingWorkPackageInput]
  let changeScope: WritingWorkPackageScope
  let dependencies: [WritingWorkPackageDependency]
  let checks: [WritingWorkPackageCheck]
  let handoff: WritingWorkPackageHandoff
  let budget: WritingWorkPackageBudget

  enum CodingKeys: String, CodingKey {
    case packageID = "package_id"
    case inputs
    case changeScope = "change_scope"
    case dependencies
    case checks
    case handoff
    case budget
  }
}

private struct WritingWorkPackageInput: Decodable, Sendable {
  let id: String
  let path: String
  let sha256: String
  let required: Bool
}

private struct WritingWorkPackageScope: Decodable {
  let policy: String
  let allowedPaths: [String]
  let excludedPaths: [String]

  enum CodingKeys: String, CodingKey {
    case policy
    case allowedPaths = "allowed_paths"
    case excludedPaths = "excluded_paths"
  }
}

private struct WritingWorkPackageDependency: Decodable, Sendable {
  let id: String
  let status: String
  let evidence: String
}

private struct WritingWorkPackageCheck: Decodable {
  let id: String
}

private struct WritingWorkPackageHandoff: Decodable {
  let format: String
  let requiredArtifacts: [String]

  enum CodingKeys: String, CodingKey {
    case format
    case requiredArtifacts = "required_artifacts"
  }
}

private struct WritingWorkPackageBudget: Decodable, Sendable {
  let unit: String
  let limit: Int
  let reading: Int
  let work: Int
  let verification: Int
  let response: Int
  let reserve: Int
}

private struct WritingWorkPackageSnapshot: Sendable {
  let packageID: String
  let inputs: [WritingWorkPackageInput]
  let changePolicy: String
  let allowedPaths: [String]
  let excludedPaths: [String]
  let dependencies: [WritingWorkPackageDependency]
  let checkIDs: [String]
  let handoffFormat: String
  let requiredArtifacts: [String]
  let budget: WritingWorkPackageBudget

  init(_ package: WritingWorkPackageEnvelope) {
    packageID = package.packageID
    inputs = package.inputs
    changePolicy = package.changeScope.policy
    allowedPaths = package.changeScope.allowedPaths.sorted()
    excludedPaths = package.changeScope.excludedPaths.sorted()
    dependencies = package.dependencies
    checkIDs = package.checks.map(\.id)
    handoffFormat = package.handoff.format
    requiredArtifacts = package.handoff.requiredArtifacts.sorted()
    budget = package.budget
  }

  func permits(_ candidate: String) -> Bool {
    allowedPaths.contains { WritingSubnodeValidation.path(candidate, isWithin: $0) }
      && !excludedPaths.contains { WritingSubnodeValidation.pathsOverlap(candidate, $0) }
  }
}

private struct SourceRepositorySnapshot: Equatable {
  let head: String
  let symbolicHead: String
  let status: String
  let refs: Data
  let objectInventory: Data
  let indexSHA256: String?
  let byteInventorySHA256: String

  static func capture(_ sourceURL: URL, git: WritingSubnodeGit) throws -> Self {
    let byteInventorySHA256 = try WritingSubnodeFilesystem.byteInventorySHA256(at: sourceURL)
    let gitDirectory = try git.text(["rev-parse", "--absolute-git-dir"], at: sourceURL)
    let indexURL = URL(fileURLWithPath: gitDirectory).appending(path: "index")
    let indexHash =
      WritingSubnodePersistence.pathExists(indexURL)
      ? WritingSubnodeJSON.sha256(
        try WritingSubnodePersistence.readStableRegularFile(
          at: indexURL,
          maximumBytes: 64 * 1_024 * 1_024
        )
      ) : nil
    return SourceRepositorySnapshot(
      head: try git.text(["rev-parse", "--verify", "HEAD^{commit}"], at: sourceURL),
      symbolicHead: (try? git.text(["symbolic-ref", "-q", "HEAD"], at: sourceURL)) ?? "",
      status: try git.text(["status", "--porcelain=v1", "--untracked-files=all"], at: sourceURL),
      refs: try git.data(
        ["for-each-ref", "--format=%(refname)%00%(objectname)%00%(symref)%00"], at: sourceURL),
      objectInventory: try git.data(["rev-list", "--objects", "--all"], at: sourceURL),
      indexSHA256: indexHash,
      byteInventorySHA256: byteInventorySHA256
    )
  }

  func canonicalSHA256() throws -> String {
    try WritingSubnodeJSON.sha256(
      WritingSubnodeJSON.encode(
        StableSourceRepositorySnapshot(
          head: head,
          symbolicHead: symbolicHead,
          status: status,
          refsSHA256: WritingSubnodeJSON.sha256(refs),
          objectInventorySHA256: WritingSubnodeJSON.sha256(objectInventory),
          indexSHA256: indexSHA256,
          byteInventorySHA256: byteInventorySHA256
        )
      )
    )
  }
}

private struct StableSourceRepositorySnapshot: Encodable {
  let head: String
  let symbolicHead: String
  let status: String
  let refsSHA256: String
  let objectInventorySHA256: String
  let indexSHA256: String?
  let byteInventorySHA256: String

  enum CodingKeys: String, CodingKey {
    case head
    case symbolicHead = "symbolic_head"
    case status
    case refsSHA256 = "refs_sha256"
    case objectInventorySHA256 = "object_inventory_sha256"
    case indexSHA256 = "index_sha256"
    case byteInventorySHA256 = "byte_inventory_sha256"
  }
}

private enum WritingSubnodeSourceAudit {
  static func validateConfiguration(_ sourceURL: URL, git: WritingSubnodeGit) throws {
    let gitDirectory = sourceURL.appending(path: ".git", directoryHint: .isDirectory)
    try WritingSubnodeFilesystem.validatePlainTreeWithoutSymlinks(at: gitDirectory)
    let configURL = gitDirectory.appending(path: "config")
    let configData =
      WritingSubnodePersistence.pathExists(configURL)
      ? try WritingSubnodePersistence.readStableRegularFile(
        at: configURL,
        maximumBytes: 1_048_576
      ) : Data()
    let keys = try git.nulStrings(
      ["config", "--file", "-", "--no-includes", "--name-only", "--null", "--list"],
      at: sourceURL,
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
        || (key.hasPrefix("submodule.")
          && [".active", ".branch", ".ignore", ".url"].contains(where: key.hasSuffix))
    }
    guard safe else {
      throw WritingSubnodeExecutorError.invalidRequest(
        "Локальная Git-конфигурация репозитория содержит незарегистрированную настройку."
      )
    }
  }
}

enum WritingSubnodeFilesystem {
  static func validatePlainTreeWithoutSymlinks(at rootURL: URL) throws {
    guard WritingSubnodePersistence.isPlainDirectory(rootURL) else {
      throw WritingSubnodeExecutorError.unsafePath("Git-каталог не является обычным каталогом.")
    }
    guard
      let enumerator = FileManager.default.enumerator(
        at: rootURL,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey],
        options: []
      )
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Не удалось перечислить Git-каталог.")
    }
    for case let url as URL in enumerator {
      var metadata = stat()
      guard url.path.withCString({ lstat($0, &metadata) }) == 0,
        metadata.st_mode & S_IFMT == S_IFDIR || metadata.st_mode & S_IFMT == S_IFREG
      else {
        throw WritingSubnodeExecutorError.unsafePath(
          "Git-каталог содержит ссылку или специальный файловый объект."
        )
      }
    }
  }

  static func byteInventorySHA256(at rootURL: URL) throws -> String {
    guard WritingSubnodePersistence.isPlainDirectory(rootURL) else {
      throw WritingSubnodeExecutorError.unsafePath(
        "Исходный checkout не является обычным каталогом.")
    }
    let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]
    guard
      let enumerator = FileManager.default.enumerator(
        at: rootURL,
        includingPropertiesForKeys: keys,
        options: []
      )
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось перечислить исходный checkout.")
    }
    let urls = enumerator.compactMap { $0 as? URL }.sorted { left, right in
      relativePath(left, root: rootURL) < relativePath(right, root: rootURL)
    }
    var hasher = SHA256()
    var totalBytes: Int64 = 0
    for url in urls {
      let relative = relativePath(url, root: rootURL)
      guard !relative.isEmpty else { continue }
      var metadata = stat()
      guard url.path.withCString({ lstat($0, &metadata) }) == 0 else {
        throw WritingSubnodeExecutorError.sourceChanged
      }
      if metadata.st_mode & S_IFMT == S_IFDIR {
        update(&hasher, kind: "directory", relative: relative, payload: Data())
      } else if metadata.st_mode & S_IFMT == S_IFLNK {
        let destination = try FileManager.default.destinationOfSymbolicLink(atPath: url.path)
        update(&hasher, kind: "symlink", relative: relative, payload: Data(destination.utf8))
      } else if metadata.st_mode & S_IFMT == S_IFREG {
        totalBytes += metadata.st_size
        guard totalBytes <= 4 * 1_024 * 1_024 * 1_024 else {
          throw WritingSubnodeExecutorError.invalidRequest(
            "Побайтовый снимок исходного checkout превышает лимит 4 ГиБ."
          )
        }
        let digest = try regularFileSHA256(at: url, expected: metadata)
        update(&hasher, kind: "file", relative: relative, payload: Data(digest.utf8))
      } else {
        throw WritingSubnodeExecutorError.unsafePath(
          "Исходный checkout содержит специальный файловый объект."
        )
      }
    }
    return "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  private static func relativePath(_ url: URL, root: URL) -> String {
    String(url.path.dropFirst(root.path.count + 1))
  }

  private static func update(
    _ hasher: inout SHA256,
    kind: String,
    relative: String,
    payload: Data
  ) {
    for component in [Data(kind.utf8), Data(relative.utf8), payload] {
      var size = UInt64(component.count).bigEndian
      withUnsafeBytes(of: &size) { hasher.update(bufferPointer: $0) }
      hasher.update(data: component)
    }
  }

  private static func regularFileSHA256(at url: URL, expected: stat) throws -> String {
    let descriptor = url.path.withCString {
      open($0, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
    }
    guard descriptor >= 0 else { throw WritingSubnodeExecutorError.sourceChanged }
    defer { _ = close(descriptor) }
    var before = stat()
    guard fstat(descriptor, &before) == 0,
      before.st_mode & S_IFMT == S_IFREG,
      before.st_dev == expected.st_dev,
      before.st_ino == expected.st_ino,
      before.st_size == expected.st_size
    else {
      throw WritingSubnodeExecutorError.sourceChanged
    }
    var hasher = SHA256()
    var buffer = [UInt8](repeating: 0, count: 64 * 1_024)
    while true {
      let count = Darwin.read(descriptor, &buffer, buffer.count)
      if count == 0 { break }
      if count < 0 {
        if errno == EINTR { continue }
        throw WritingSubnodeExecutorError.sourceChanged
      }
      buffer.withUnsafeBytes { raw in
        hasher.update(bufferPointer: UnsafeRawBufferPointer(rebasing: raw[..<count]))
      }
    }
    var after = stat()
    guard fstat(descriptor, &after) == 0,
      before.st_dev == after.st_dev,
      before.st_ino == after.st_ino,
      before.st_size == after.st_size,
      before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
      before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec
    else {
      throw WritingSubnodeExecutorError.sourceChanged
    }
    return "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }
}

struct WritingSubnodeGit: Sendable {
  func text(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> String {
    String(
      decoding: try data(
        arguments, at: directory, input: input, additionalEnvironment: additionalEnvironment),
      as: UTF8.self
    )
    .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func data(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> Data {
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
      ] + arguments
    process.currentDirectoryURL = directory
    var environment = ProcessInfo.processInfo.environment.filter {
      !$0.key.uppercased().hasPrefix("GIT_")
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] = WritingSubnodeSystemRuntime.nullDevicePath
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    environment["LC_ALL"] = "C"
    for (key, value) in additionalEnvironment { environment[key] = value }
    process.environment = environment
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    let output: Data
    let inputWriteSucceeded: Bool
    if let input {
      let inputPipe = Pipe()
      let writeStatusPipe = Pipe()
      process.standardInput = inputPipe
      try process.run()
      try pipe.fileHandleForWriting.close()
      let writing = DispatchGroup()
      writing.enter()
      let writer = Thread {
        defer { writing.leave() }
        let succeeded: Bool
        do {
          try inputPipe.fileHandleForWriting.write(contentsOf: input)
          succeeded = true
        } catch {
          succeeded = false
        }
        try? inputPipe.fileHandleForWriting.close()
        try? writeStatusPipe.fileHandleForWriting.write(
          contentsOf: Data([succeeded ? 1 : 0])
        )
        try? writeStatusPipe.fileHandleForWriting.close()
      }
      writer.name = "fum-writing-subnode-git-stdin"
      writer.start()
      output = pipe.fileHandleForReading.readDataToEndOfFile()
      writing.wait()
      inputWriteSucceeded = writeStatusPipe.fileHandleForReading.readDataToEndOfFile() == Data([1])
    } else {
      try process.run()
      try pipe.fileHandleForWriting.close()
      output = pipe.fileHandleForReading.readDataToEndOfFile()
      inputWriteSucceeded = true
    }
    process.waitUntilExit()
    guard inputWriteSucceeded, process.terminationStatus == 0 else {
      throw WritingSubnodeExecutorError.gitFailed(
        "Git-команда завершилась с кодом \(process.terminationStatus)."
      )
    }
    return output
  }

  func nulStrings(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil
  ) throws -> [String] {
    try data(arguments, at: directory, input: input)
      .split(separator: 0, omittingEmptySubsequences: true)
      .map {
        guard let value = String(data: Data($0), encoding: .utf8) else {
          throw WritingSubnodeExecutorError.gitFailed("Git вернул путь не в UTF-8.")
        }
        return value
      }
  }
}

enum WritingSubnodeJSON {
  static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  static func sha256(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

enum WritingSubnodeValidation {
  static func validate(_ request: WritingSubnodeExecutionRequest) throws {
    let identifiers = [
      request.episodeID, request.stepGenerationID, request.cardID, request.stepID, request.runID,
      request.subnodeID, request.repositoryID,
    ]
    let runRefComponent = "\(request.subnodeID)-\(request.runID)"
    guard identifiers.allSatisfy(isIdentifier),
      runRefComponent.utf8.count <= 240,
      request.baseOID.count == 40 || request.baseOID.count == 64,
      request.baseOID.allSatisfy({ "0123456789abcdef".contains($0) }),
      request.targetRef.hasPrefix("refs/heads/"),
      !request.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      request.commitMessage.unicodeScalars.count <= 4_096,
      request.writes.count <= 128,
      Set(request.writes.map(\.path)).count == request.writes.count,
      Set(
        request.writes.map {
          $0.path.precomposedStringWithCanonicalMapping.lowercased()
        }
      ).count == request.writes.count,
      request.writes.allSatisfy({ isLexicallyRelativePath($0.path) }),
      request.writes.allSatisfy({ $0.contents.count <= 16 * 1_024 * 1_024 }),
      request.writes.reduce(0, { $0 + $1.contents.count }) <= 64 * 1_024 * 1_024
    else {
      throw WritingSubnodeExecutorError.invalidRequest("Запрос пишущего подузла некорректен.")
    }
  }

  static func validateRef(_ ref: String, git: WritingSubnodeGit) throws {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    process.arguments = ["--no-replace-objects", "--no-optional-locks", "check-ref-format", ref]
    process.environment = [
      "GIT_CONFIG_NOSYSTEM": "1",
      "GIT_CONFIG_GLOBAL": WritingSubnodeSystemRuntime.nullDevicePath,
      "GIT_OPTIONAL_LOCKS": "0",
      "LC_ALL": "C",
    ]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw WritingSubnodeExecutorError.invalidRequest("Полный ref пишущего подузла некорректен.")
    }
  }

  static func isIdentifier(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard !bytes.isEmpty, bytes.count <= 128 else { return false }
    let alphaNumeric: (UInt8) -> Bool = {
      (0x30...0x39).contains($0) || (0x41...0x5A).contains($0) || (0x61...0x7A).contains($0)
    }
    guard let first = bytes.first, alphaNumeric(first) else { return false }
    return bytes.allSatisfy { alphaNumeric($0) || [0x2D, 0x2E, 0x5F].contains($0) }
  }

  static func isRelativePath(_ value: String) -> Bool {
    isLexicallyRelativePath(value)
      && !value.split(separator: "/", omittingEmptySubsequences: false).contains {
        String($0).precomposedStringWithCanonicalMapping.lowercased() == ".git"
      }
  }

  static func isScopePath(_ value: String) -> Bool {
    isLexicallyRelativePath(value)
  }

  private static func isLexicallyRelativePath(_ value: String) -> Bool {
    let segments = value.split(separator: "/", omittingEmptySubsequences: false)
    let forbidden = CharacterSet(charactersIn: "*?[]{}$\\")
    return !value.isEmpty && value.utf8.count <= 1_024 && !value.hasPrefix("/")
      && !value.hasPrefix("~") && !value.contains("://")
      && value.rangeOfCharacter(from: forbidden) == nil
      && !value.unicodeScalars.contains(where: {
        $0.value <= 0x1F || (0x7F...0x9F).contains($0.value)
      })
      && !segments.contains(where: {
        $0.isEmpty || $0 == "." || $0 == ".." || $0.utf8.count > 240
      })
  }

  static func path(_ candidate: String, isWithin root: String) -> Bool {
    candidate == root || candidate.hasPrefix(root + "/")
  }

  static func pathsOverlap(_ left: String, _ right: String) -> Bool {
    path(left, isWithin: right) || path(right, isWithin: left)
  }

  static func isDescendant(_ candidate: URL, of root: URL) -> Bool {
    let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
    return candidate.path.hasPrefix(rootPath)
  }

  static func containsSecret(_ data: Data) -> Bool {
    guard let text = String(data: data, encoding: .utf8) else { return false }
    let secretPattern =
      #"(?i)(?:-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----|authorization[\t ]*:[\t ]*bearer[\t ]+[^\s]+|github_pat_|gh[pousr]_|AKIA[0-9A-Z]{16})"#
    return text.range(of: secretPattern, options: .regularExpression) != nil
  }

  static func isSHA256(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    return bytes.count == 71 && bytes.starts(with: Array("sha256:".utf8))
      && bytes.dropFirst(7).allSatisfy {
        (0x30...0x39).contains($0) || (0x61...0x66).contains($0)
      }
  }

  static func isObjectID(_ value: String) -> Bool {
    (value.count == 40 || value.count == 64)
      && value.allSatisfy { "0123456789abcdef".contains($0) }
  }

  static func publicationOutcome(
    _ data: Data,
    allowingGitNullDevice: Bool = false
  ) -> WritingSubnodeOutcome? {
    if containsSecret(data) { return .secretDetected }
    guard var text = String(data: data, encoding: .utf8) else { return .publicationRejected }
    if allowingGitNullDevice {
      text = text.replacingOccurrences(of: "--- /dev/null\n", with: "--- deleted\n")
        .replacingOccurrences(of: "+++ /dev/null\n", with: "+++ deleted\n")
    }
    let localMarkers = [
      "file://",
      "/Users/", "/home/",
      "/tmp/", "/private/tmp/", "/var/folders/",
      "localhost", "127.0.0.1",
    ]
    if localMarkers.contains(where: text.contains) { return .publicationRejected }
    let absolutePathPattern =
      #"(?i)(?:^|[\s\"'(=,:])(?:/(?!/)[^\s\"',)\]}]*|[a-z]:[\\/][^\s\"',)\]}]*|\\\\[^\s\"',)\]}]+)"#
    let homeExpansionPattern =
      #"(?i)(?:^|[\s\"'(=,:])(?:~(?:[a-z0-9._-]+)?(?:[\\/]|(?=$|\s))|\$(?:\{)?(?:home|userprofile)(?:\})?|%(?:userprofile|homedrive|homepath)%)"#
    let fileURIPattern = #"(?i)(?:^|[\s\"'(=,:])file://"#
    return [absolutePathPattern, homeExpansionPattern, fileURIPattern].contains {
      text.range(of: $0, options: .regularExpression) != nil
    } ? .publicationRejected : nil
  }

  static func safeEvidence(_ value: String) -> String {
    guard !value.isEmpty, value.unicodeScalars.count <= 2_048,
      publicationOutcome(Data(value.utf8)) == nil
    else {
      return "evidence_redacted"
    }
    return value
  }

}

private struct WritingSubnodeRunReceipt: Codable, Equatable {
  let schemaIdentity = "fum.writing-subnode.run-receipt"
  let schemaVersion = 1
  let executionRequestSHA256: String
  let outcome: WritingSubnodeOutcome
  let passportSHA256: String?

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case executionRequestSHA256 = "execution_request_sha256"
    case outcome
    case passportSHA256 = "passport_sha256"
  }
}

private struct WritingSubnodeRunReceiptStore {
  let runURL: URL

  private var receiptURL: URL { runURL.appending(path: "result.json") }

  func loadIfPresent() throws -> WritingSubnodeRunReceipt? {
    guard WritingSubnodePersistence.pathExists(receiptURL) else { return nil }
    let data = try WritingSubnodePersistence.readStableRegularFile(
      at: receiptURL,
      maximumBytes: 4_096
    )
    let receipt = try JSONDecoder().decode(WritingSubnodeRunReceipt.self, from: data)
    guard receipt.schemaIdentity == "fum.writing-subnode.run-receipt",
      receipt.schemaVersion == 1,
      WritingSubnodeValidation.isSHA256(receipt.executionRequestSHA256),
      (receipt.outcome == .candidateCommitted)
        == (receipt.passportSHA256.map(WritingSubnodeValidation.isSHA256) == true),
      try WritingSubnodeJSON.encode(receipt) == data
    else {
      throw WritingSubnodeExecutorError.persistenceFailed("Квитанция запуска некорректна.")
    }
    return receipt
  }

  func persist(_ receipt: WritingSubnodeRunReceipt) throws {
    let canonical = try WritingSubnodeJSON.encode(receipt)
    guard WritingSubnodeValidation.publicationOutcome(canonical) == nil else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Квитанция запуска не прошла публикационную проверку."
      )
    }
    try WritingSubnodePersistence.persistExclusive(canonical, at: receiptURL)
  }
}

enum WritingSubnodePersistence {
  final class RunLock: @unchecked Sendable {
    private var descriptor: Int32

    fileprivate init(descriptor: Int32) {
      self.descriptor = descriptor
    }

    func release() {
      guard descriptor >= 0 else { return }
      _ = flock(descriptor, LOCK_UN)
      _ = close(descriptor)
      descriptor = -1
    }

    deinit { release() }
  }

  static func pathExists(_ url: URL) -> Bool {
    var metadata = stat()
    return url.path.withCString { lstat($0, &metadata) } == 0
  }

  static func isPlainDirectory(_ url: URL) -> Bool {
    var metadata = stat()
    return url.path.withCString { lstat($0, &metadata) } == 0
      && metadata.st_mode & S_IFMT == S_IFDIR
  }

  static func ensurePlainDirectory(_ url: URL) throws {
    var metadata = stat()
    if url.path.withCString({ lstat($0, &metadata) }) == 0 {
      guard metadata.st_mode & S_IFMT == S_IFDIR else {
        throw WritingSubnodeExecutorError.unsafePath("Ожидался обычный каталог исполнения.")
      }
      return
    }
    let parent = url.deletingLastPathComponent()
    if parent.path != url.path { try ensurePlainDirectory(parent) }
    guard url.path.withCString({ mkdir($0, 0o700) }) == 0 || errno == EEXIST else {
      throw WritingSubnodeExecutorError.persistenceFailed("Не удалось создать каталог исполнения.")
    }
    var createdMetadata = stat()
    guard url.path.withCString({ lstat($0, &createdMetadata) }) == 0,
      createdMetadata.st_mode & S_IFMT == S_IFDIR
    else {
      throw WritingSubnodeExecutorError.unsafePath("Созданный каталог исполнения небезопасен.")
    }
  }

  static func reserveDirectory(_ url: URL) throws -> Bool {
    if url.path.withCString({ mkdir($0, 0o700) }) == 0 { return true }
    if errno == EEXIST {
      var metadata = stat()
      guard url.path.withCString({ lstat($0, &metadata) }) == 0,
        metadata.st_mode & S_IFMT == S_IFDIR
      else {
        throw WritingSubnodeExecutorError.unsafePath("Путь запуска небезопасен.")
      }
      return false
    }
    throw WritingSubnodeExecutorError.persistenceFailed("Не удалось зарезервировать запуск.")
  }

  static func acquireRunLock(at url: URL) throws -> RunLock? {
    let descriptor = url.path.withCString {
      open($0, O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
    }
    guard descriptor >= 0 else {
      throw WritingSubnodeExecutorError.unsafePath("Файл блокировки запуска небезопасен.")
    }
    var metadata = stat()
    guard fstat(descriptor, &metadata) == 0,
      metadata.st_mode & S_IFMT == S_IFREG,
      metadata.st_nlink == 1
    else {
      _ = close(descriptor)
      throw WritingSubnodeExecutorError.unsafePath(
        "Файл блокировки запуска не является обычным файлом."
      )
    }
    guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
      let lockError = errno
      _ = close(descriptor)
      if lockError == EWOULDBLOCK { return nil }
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось получить блокировку запуска."
      )
    }
    return RunLock(descriptor: descriptor)
  }

  static func readStableUTF8RegularFile(
    at url: URL,
    maximumBytes: Int
  ) throws -> String {
    let data = try readStableRegularFile(at: url, maximumBytes: maximumBytes)
    guard let value = String(data: data, encoding: .utf8) else {
      throw WritingSubnodeExecutorError.persistenceFailed("Артефакт запуска не является UTF-8.")
    }
    return value
  }

  static func readStableRegularFile(at url: URL, maximumBytes: Int) throws -> Data {
    let descriptor = url.path.withCString {
      open($0, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
    }
    guard descriptor >= 0 else {
      throw WritingSubnodeExecutorError.unsafePath("Артефакт запуска небезопасен.")
    }
    defer { _ = close(descriptor) }
    var before = stat()
    guard fstat(descriptor, &before) == 0,
      before.st_mode & S_IFMT == S_IFREG,
      before.st_nlink == 1,
      before.st_size >= 0,
      before.st_size <= maximumBytes
    else {
      throw WritingSubnodeExecutorError.unsafePath("Артефакт запуска не является обычным файлом.")
    }
    var result = Data()
    result.reserveCapacity(Int(before.st_size))
    var buffer = [UInt8](repeating: 0, count: 64 * 1_024)
    while true {
      let count = Darwin.read(descriptor, &buffer, buffer.count)
      if count == 0 { break }
      if count < 0 {
        if errno == EINTR { continue }
        throw WritingSubnodeExecutorError.persistenceFailed(
          "Не удалось прочитать артефакт запуска.")
      }
      guard result.count + count <= maximumBytes else {
        throw WritingSubnodeExecutorError.persistenceFailed("Артефакт запуска превышает лимит.")
      }
      result.append(buffer, count: count)
    }
    var after = stat()
    guard fstat(descriptor, &after) == 0,
      before.st_dev == after.st_dev,
      before.st_ino == after.st_ino,
      before.st_size == after.st_size,
      before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
      before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec,
      result.count == Int(after.st_size)
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Артефакт запуска изменился во время чтения."
      )
    }
    return result
  }

  static func persistExclusive(_ data: Data, at url: URL) throws {
    let parent = url.deletingLastPathComponent()
    guard isPlainDirectory(parent) else {
      throw WritingSubnodeExecutorError.unsafePath("Родитель артефакта запуска небезопасен.")
    }
    let temporaryURL = parent.appending(path: ".tmp-\(UUID().uuidString)")
    let descriptor = temporaryURL.path.withCString {
      open($0, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0o600)
    }
    guard descriptor >= 0 else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось создать неизменяемый артефакт.")
    }
    var descriptorOpen = true
    defer {
      if descriptorOpen { _ = close(descriptor) }
      _ = temporaryURL.path.withCString { unlink($0) }
    }
    var offset = 0
    let success = data.withUnsafeBytes { storage -> Bool in
      guard let base = storage.baseAddress else { return data.isEmpty }
      while offset < data.count {
        let count = Darwin.write(descriptor, base.advanced(by: offset), data.count - offset)
        if count < 0 {
          if errno == EINTR { continue }
          return false
        }
        offset += count
      }
      return true
    }
    guard success, fsync(descriptor) == 0, close(descriptor) == 0 else {
      throw WritingSubnodeExecutorError.persistenceFailed("Не удалось сохранить артефакт запуска.")
    }
    descriptorOpen = false
    guard
      temporaryURL.path.withCString({ temporaryPath in
        url.path.withCString { finalPath in
          renamex_np(temporaryPath, finalPath, UInt32(RENAME_EXCL))
        }
      }) == 0
    else {
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось атомарно зафиксировать артефакт запуска."
      )
    }
    let directoryDescriptor = parent.path.withCString {
      open($0, O_RDONLY | O_CLOEXEC | O_DIRECTORY | O_NOFOLLOW)
    }
    guard directoryDescriptor >= 0 else {
      throw WritingSubnodeExecutorError.persistenceFailed("Не удалось открыть каталог артефакта.")
    }
    defer { _ = close(directoryDescriptor) }
    guard fsync(directoryDescriptor) == 0 else {
      throw WritingSubnodeExecutorError.persistenceFailed("Не удалось синхронизировать каталог.")
    }
  }

  static func archiveIncompleteCloneIfPresent(_ cloneURL: URL, in runURL: URL) throws {
    guard pathExists(cloneURL) else { return }
    guard isPlainDirectory(cloneURL) else {
      throw WritingSubnodeExecutorError.unsafePath("Незавершённый клон небезопасен.")
    }
    let archiveRoot = runURL.appending(path: "abandoned", directoryHint: .isDirectory)
    try ensurePlainDirectory(archiveRoot)
    for sequence in 1...10_000 {
      let destination = archiveRoot.appending(
        path: String(format: "clone-%05d", sequence),
        directoryHint: .isDirectory
      )
      if pathExists(destination) { continue }
      if cloneURL.path.withCString({ sourcePath in
        destination.path.withCString { destinationPath in rename(sourcePath, destinationPath) }
      }) == 0 {
        return
      }
      if errno == EEXIST { continue }
      throw WritingSubnodeExecutorError.persistenceFailed(
        "Не удалось сохранить незавершённую попытку."
      )
    }
    throw WritingSubnodeExecutorError.persistenceFailed(
      "Исчерпан диапазон архивов незавершённых попыток."
    )
  }

  static func materialize(_ write: WritingSubnodeWrite, cloneURL: URL) throws {
    let components = write.path.split(separator: "/").map(String.init)
    guard let fileName = components.last else {
      throw WritingSubnodeExecutorError.unsafePath("Пустой путь записи.")
    }
    var directory = cloneURL
    for component in components.dropLast() {
      directory.append(path: component, directoryHint: .isDirectory)
      var metadata = stat()
      if directory.path.withCString({ lstat($0, &metadata) }) == 0 {
        guard metadata.st_mode & S_IFMT == S_IFDIR else {
          throw WritingSubnodeExecutorError.unsafePath("Компонент пути записи небезопасен.")
        }
      } else {
        guard directory.path.withCString({ mkdir($0, 0o700) }) == 0 else {
          throw WritingSubnodeExecutorError.persistenceFailed("Не удалось создать каталог записи.")
        }
      }
    }
    let target = directory.appending(path: fileName)
    var metadata = stat()
    if target.path.withCString({ lstat($0, &metadata) }) == 0,
      metadata.st_mode & S_IFMT != S_IFREG
    {
      throw WritingSubnodeExecutorError.unsafePath("Цель записи не является обычным файлом.")
    }
    try write.contents.write(to: target, options: [.atomic])
  }
}
