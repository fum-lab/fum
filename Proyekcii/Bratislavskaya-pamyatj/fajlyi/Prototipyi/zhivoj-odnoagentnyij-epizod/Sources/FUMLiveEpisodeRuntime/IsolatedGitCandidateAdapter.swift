import Darwin
import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public struct IsolatedGitCandidateAdapter {
  public typealias CheckpointObserver =
    (LiveGitCandidateCheckpoint, URL, String?) throws -> Void

  private let checkerRegistry: LiveGitCheckerRegistry
  private let checkpointObserver: CheckpointObserver?

  public init(
    checkerRegistry: LiveGitCheckerRegistry = LiveGitCheckerRegistry(),
    checkpointObserver: CheckpointObserver? = nil
  ) {
    self.checkerRegistry = checkerRegistry
    self.checkpointObserver = checkpointObserver
  }

  /// Performs the non-mutating checks that justify a runtime-owned `preflight_passed` receipt.
  /// Execution repeats all source/object checks after CURRENT confirms that receipt.
  public func preflight(
    _ request: LiveGitCandidatePreflightRequest
  ) throws -> LiveGitCandidatePreflightResult {
    let planSHA256 = try validatePlan(request.plan)
    try validateIntentAndAllowance(
      coordinates: request.coordinates,
      plan: request.plan,
      planSHA256: planSHA256,
      selectedIntent: request.selectedIntent,
      allowance: request.allowance
    )
    do {
      try LiveGitCandidateReceiptChain.validatePrefix(
        request.confirmedAuthorizationReceipts,
        through: .authorized,
        policy: request.plan.policy,
        expectedCoordinates: request.coordinates,
        candidateOwnedEvents: request.confirmedAuthorizationEvents
      )
    } catch {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Confirmed authorization receipt prefix is invalid: \(error)"
      )
    }
    try validateAuthorizedEvent(
      request.confirmedAuthorizationEvents,
      selectedIntent: request.selectedIntent,
      allowance: request.allowance
    )
    return try readOnlyPreflight(
      sourceCheckoutURL: request.sourceCheckoutURL,
      episodeDirectoryURL: request.episodeDirectoryURL,
      coordinates: request.coordinates,
      plan: request.plan,
      planSHA256: planSHA256
    )
  }

  public func createCandidateCommit(
    _ request: LiveGitCandidateExecutionRequest
  ) throws -> LiveGitCandidateCommitResult {
    let planSHA256 = try validatePlan(request.plan)
    try validateIntentAndAllowance(
      coordinates: request.coordinates,
      plan: request.plan,
      planSHA256: planSHA256,
      selectedIntent: request.selectedIntent,
      allowance: request.allowance
    )
    guard request.confirmedPreflightReceipts.count == 3,
      request.confirmedPreflightEvents.count == 3
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Execution requires the exact three-stage confirmed preflight prefix."
      )
    }
    let preflight = try preflight(
      LiveGitCandidatePreflightRequest(
        sourceCheckoutURL: request.sourceCheckoutURL,
        episodeDirectoryURL: request.episodeDirectoryURL,
        coordinates: request.coordinates,
        plan: request.plan,
        selectedIntent: request.selectedIntent,
        allowance: request.allowance,
        confirmedAuthorizationReceipts: Array(request.confirmedPreflightReceipts.prefix(2)),
        confirmedAuthorizationEvents: Array(request.confirmedPreflightEvents.prefix(2))
      )
    )
    do {
      try request.allowance.validateCandidateCommitPolicy()
      try LiveGitCandidateReceiptChain.validatePrefix(
        request.confirmedPreflightReceipts,
        through: .preflightPassed,
        policy: request.plan.policy,
        expectedCoordinates: request.coordinates,
        candidateOwnedEvents: request.confirmedPreflightEvents
      )
    } catch {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Confirmed preflight receipt prefix is invalid: \(error)"
      )
    }
    let preflightReceipt = request.confirmedPreflightReceipts[2]
    guard preflightReceipt.receiptID == request.plan.preflightReceiptID,
      preflightReceipt.eventID == request.plan.preflightEventID,
      preflightReceipt.evidence == preflight.preflightEvidence
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Confirmed preflight receipt does not bind the adapter's exact read-only observation."
      )
    }
    return try createValidatedCandidate(
      sourceCheckoutURL: request.sourceCheckoutURL,
      episodeDirectoryURL: request.episodeDirectoryURL,
      coordinates: request.coordinates,
      plan: request.plan,
      knownPlanSHA256: planSHA256
    )
  }

  /// A separate read-only contour used only after execution persisted the passport. It does not
  /// trust the in-memory execution result: refs, commit topology, tree, diff, blobs, passport and
  /// registered checkers are all read again from the isolated clone.
  public func observeCandidateCommit(
    _ request: LiveGitCandidateObservationRequest
  ) throws -> LiveGitCandidateObservationResult {
    let planSHA256 = try validatePlan(request.plan)
    guard request.coordinates.expectedEffectSHA256 == planSHA256,
      request.candidateOID == request.plan.policy.expectedCandidateOID,
      request.expectedPassportSHA256.hasPrefix("sha256:"),
      request.expectedPassportSHA256.count == 71
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Observation request does not bind the exact plan, coordinates, candidate, and passport."
      )
    }
    let episodeURL = request.episodeDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
    try requireDirectory(episodeURL, field: "episode directory")
    let cloneURL = episodeURL.appendingPathComponent(
      LiveGitCandidateRuntimeSchema.cloneRelativePath,
      isDirectory: true
    )
    try requireDirectory(cloneURL, field: "candidate clone")
    guard
      let gitStatus = try fileStatus(
        cloneURL.appendingPathComponent(".git", isDirectory: true)
      ), isDirectory(gitStatus), !isSymbolicLink(gitStatus)
    else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Observed candidate clone does not own a regular .git directory."
      )
    }
    let candidateRefOID = try readDirectRef(
      request.plan.policy.candidateBranch,
      cloneURL: cloneURL
    )
    let resultRefOID = try readDirectRef(request.plan.policy.resultRef, cloneURL: cloneURL)
    guard candidateRefOID == request.candidateOID else {
      throw LiveGitCandidateRuntimeError.candidateConflict(
        ref: request.plan.policy.candidateBranch,
        expected: request.candidateOID,
        actual: candidateRefOID
      )
    }
    guard resultRefOID == request.candidateOID else {
      throw LiveGitCandidateRuntimeError.candidateConflict(
        ref: request.plan.policy.resultRef,
        expected: request.candidateOID,
        actual: resultRefOID
      )
    }
    let candidateType = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["cat-file", "-t", request.candidateOID],
        at: cloneURL
      ).output
    )
    guard candidateType == "commit" else {
      throw LiveGitCandidateRuntimeError.gitProcess("Observed candidate is not a commit.")
    }
    let parents = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-list", "--parents", "-n", "1", request.candidateOID],
        at: cloneURL
      ).output
    ).split(separator: " ").map(String.init)
    guard parents == [request.candidateOID, request.plan.policy.baseCommitOID] else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Observed candidate does not have the one exact pinned parent."
      )
    }
    let treeOID = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-parse", "\(request.candidateOID)^{tree}"],
        at: cloneURL
      ).output
    )
    guard treeOID == request.plan.policy.expectedTreeOID else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Observed candidate has a different tree."
      )
    }
    let changedPaths = try nulStrings(
      LiveGitProcessRunner().run(
        [
          "diff-tree", "--no-ext-diff", "--no-textconv", "--no-commit-id", "--name-only",
          "--no-renames", "-r", "-z", request.plan.policy.baseCommitOID,
          request.candidateOID, "--",
        ],
        at: cloneURL
      ).output
    ).sorted()
    let expectedPaths = request.plan.writes.map(\.path)
    guard changedPaths == expectedPaths else {
      throw LiveGitCandidateRuntimeError.unexpectedDiff(
        expected: expectedPaths,
        actual: changedPaths
      )
    }
    var blobsByPath: [String: String] = [:]
    for write in request.plan.writes {
      guard let contents = write.contents else {
        throw LiveGitCandidateRuntimeError.invalidPlan(
          "Observed plan contains non-canonical base64."
        )
      }
      blobsByPath[write.path] = try trimmedGitOutput(
        LiveGitProcessRunner().run(
          ["hash-object", "--stdin"],
          at: cloneURL,
          input: contents
        ).output
      )
    }
    try verifyTreeEntries(
      treeOID: treeOID,
      writes: request.plan.writes,
      blobsByPath: blobsByPath,
      cloneURL: cloneURL
    )
    let observations = try checkerRegistry.verify(
      specifications: request.plan.policy.checkers,
      parentOID: request.plan.policy.baseCommitOID,
      candidateOID: request.candidateOID,
      allowedPaths: request.plan.policy.allowedPaths,
      repositoryURL: cloneURL
    )
    let expectedWrites = try request.plan.writes.map { write in
      guard let contents = write.contents else {
        throw LiveGitCandidateRuntimeError.invalidPlan(
          "Observed plan contains non-canonical base64."
        )
      }
      return LiveGitCandidateExpectedWrite(
        path: write.path,
        mode: write.mode,
        contentsSHA256: CanonicalMemoryJSON.sha256(contents)
      )
    }
    let expectedPassport = LiveGitCandidatePassport(
      planSHA256: planSHA256,
      coordinates: request.coordinates,
      parentOID: request.plan.policy.baseCommitOID,
      treeOID: treeOID,
      candidateOID: request.candidateOID,
      candidateBranchRef: request.plan.policy.candidateBranch,
      resultRef: request.plan.policy.resultRef,
      allowedPaths: request.plan.policy.allowedPaths,
      changedPaths: changedPaths,
      expectedWrites: expectedWrites,
      checkerSpecifications: request.plan.policy.checkers,
      checkerObservations: observations,
      author: request.plan.policy.author,
      committer: request.plan.policy.committer,
      message: request.plan.policy.message,
      preflightEventID: request.plan.preflightEventID,
      preflightReceiptID: request.plan.preflightReceiptID,
      executionEventID: request.plan.executionEventID,
      executionReceiptID: request.plan.executionReceiptID,
      observationEventID: request.plan.observationEventID,
      observationReceiptID: request.plan.observationReceiptID
    )
    try expectedPassport.validate()
    let passportData = try readRegularFileBeneath(
      rootURL: episodeURL,
      relativePath: expectedPassport.storageRelativePath,
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes
    )
    try CanonicalMemoryJSON.requireCanonical(passportData)
    let passport = try JSONDecoder().decode(LiveGitCandidatePassport.self, from: passportData)
    try passport.validate()
    let passportSHA256 = CanonicalMemoryJSON.sha256(passportData)
    guard passport == expectedPassport,
      passportSHA256 == request.expectedPassportSHA256
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Observed durable passport differs from the independently reconstructed candidate."
      )
    }
    return LiveGitCandidateObservationResult(
      passport: passport,
      passportSHA256: passportSHA256
    )
  }

  /// Recovers only the content address of an already persisted passport. This supports the
  /// crash state after an `executed` receipt was confirmed but before the independent observer
  /// produced `observed`; it does not substitute for `observeCandidateCommit`.
  public func candidatePassportSHA256(
    episodeDirectoryURL: URL,
    candidateOID: String
  ) throws -> String {
    guard candidateOID.count == 40 || candidateOID.count == 64,
      candidateOID.allSatisfy({ "0123456789abcdef".contains($0) })
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Passport recovery requires one exact lowercase candidate OID."
      )
    }
    let episodeURL = episodeDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
    try requireDirectory(episodeURL, field: "episode directory")
    let relativePath = LiveGitCandidateRuntimeSchema.passportRelativePath(
      candidateOID: candidateOID
    )
    let data = try readRegularFileBeneath(
      rootURL: episodeURL,
      relativePath: relativePath,
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes
    )
    try CanonicalMemoryJSON.requireCanonical(data)
    let passport = try JSONDecoder().decode(LiveGitCandidatePassport.self, from: data)
    try passport.validate()
    guard passport.candidateOID == candidateOID,
      passport.storageRelativePath == relativePath
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Recovered passport belongs to a different candidate."
      )
    }
    return CanonicalMemoryJSON.sha256(data)
  }

  /// Internal entry used only by the autonomous Git fixture after it constructs the same
  /// canonical binding that the public receipt gate validates.
  func createValidatedCandidate(
    sourceCheckoutURL: URL,
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan
  ) throws -> LiveGitCandidateCommitResult {
    let planSHA256 = try validatePlan(plan)
    guard coordinates.expectedEffectSHA256 == planSHA256 else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Transition expected effect does not equal the canonical plan digest."
      )
    }
    return try createValidatedCandidate(
      sourceCheckoutURL: sourceCheckoutURL,
      episodeDirectoryURL: episodeDirectoryURL,
      coordinates: coordinates,
      plan: plan,
      knownPlanSHA256: planSHA256
    )
  }

  private func createValidatedCandidate(
    sourceCheckoutURL: URL,
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    knownPlanSHA256: String
  ) throws -> LiveGitCandidateCommitResult {
    let sourceURL = sourceCheckoutURL.standardizedFileURL.resolvingSymlinksInPath()
    let episodeURL = episodeDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
    try requireDirectory(sourceURL, field: "source checkout")
    try requireDirectory(episodeURL, field: "episode directory")
    guard !isDescendant(episodeURL, of: sourceURL), episodeURL != sourceURL else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Episode directory must be outside the source checkout."
      )
    }

    let sourceFormat = try trimmedGitOutput(
      LiveGitProcessRunner().run(["rev-parse", "--show-object-format"], at: sourceURL).output
    )
    let oidLength: Int
    switch sourceFormat {
    case "sha1": oidLength = 40
    case "sha256": oidLength = 64
    default:
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Unsupported Git object format \(sourceFormat)."
      )
    }
    try requireOID(plan.policy.baseCommitOID, length: oidLength, field: "base commit")
    try requireOID(plan.policy.expectedTreeOID, length: oidLength, field: "expected tree")
    try requireOID(plan.policy.expectedCandidateOID, length: oidLength, field: "expected candidate")
    let sourceHead = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-parse", "--verify", "HEAD^{commit}"],
        at: sourceURL
      ).output
    )
    guard sourceHead == plan.policy.baseCommitOID else {
      throw LiveGitCandidateRuntimeError.sourceBaseChanged(
        expected: plan.policy.baseCommitOID,
        actual: sourceHead
      )
    }
    try requireSeparateCandidateBranch(plan.policy.candidateBranch, sourceURL: sourceURL)
    let baseType = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["cat-file", "-t", plan.policy.baseCommitOID],
        at: sourceURL
      ).output
    )
    guard baseType == "commit" else {
      throw LiveGitCandidateRuntimeError.invalidPlan("Pinned base object is not a commit.")
    }

    let cloneURL = episodeURL.appendingPathComponent(
      LiveGitCandidateRuntimeSchema.cloneRelativePath,
      isDirectory: true
    )
    try prepareClone(
      cloneURL: cloneURL,
      sourceURL: sourceURL,
      episodeURL: episodeURL,
      baseOID: plan.policy.baseCommitOID,
      objectFormat: sourceFormat
    )
    try checkpointObserver?(.clonePrepared, cloneURL, nil)

    var blobsByPath: [String: String] = [:]
    for write in plan.writes {
      guard let contents = write.contents else {
        throw LiveGitCandidateRuntimeError.invalidPlan(
          "Write \(write.path) does not contain canonical base64."
        )
      }
      try materializeRegularFile(write, contents: contents, cloneURL: cloneURL)
      let blobOID = try trimmedGitOutput(
        LiveGitProcessRunner().run(
          ["hash-object", "-w", "--stdin"],
          at: cloneURL,
          input: contents
        ).output
      )
      try requireOID(blobOID, length: oidLength, field: "candidate blob")
      _ = try LiveGitProcessRunner().run(
        ["update-index", "--add", "--cacheinfo", write.mode.rawValue, blobOID, write.path],
        at: cloneURL
      )
      blobsByPath[write.path] = blobOID
    }
    try checkpointObserver?(.writesStaged, cloneURL, nil)

    let treeOID = try trimmedGitOutput(
      LiveGitProcessRunner().run(["write-tree"], at: cloneURL).output
    )
    guard treeOID == plan.policy.expectedTreeOID else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Constructed tree \(treeOID) differs from pinned tree \(plan.policy.expectedTreeOID)."
      )
    }
    let changedPaths = try nulStrings(
      LiveGitProcessRunner().run(
        [
          "diff", "--cached", "--no-ext-diff", "--no-textconv", "--name-only",
          "--no-renames", "-z", plan.policy.baseCommitOID, "--",
        ],
        at: cloneURL
      ).output
    ).sorted()
    let expectedChangedPaths = plan.writes.map(\.path)
    guard changedPaths == expectedChangedPaths else {
      throw LiveGitCandidateRuntimeError.unexpectedDiff(
        expected: expectedChangedPaths,
        actual: changedPaths
      )
    }
    try verifyTreeEntries(
      treeOID: treeOID,
      writes: plan.writes,
      blobsByPath: blobsByPath,
      cloneURL: cloneURL
    )

    let candidateOID = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["commit-tree", treeOID, "-p", plan.policy.baseCommitOID],
        at: cloneURL,
        input: Data(plan.policy.message.utf8),
        additionalEnvironment: gitIdentityEnvironment(plan.policy)
      ).output
    )
    guard candidateOID == plan.policy.expectedCandidateOID else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Constructed candidate \(candidateOID) differs from pinned candidate \(plan.policy.expectedCandidateOID)."
      )
    }
    let candidateType = try trimmedGitOutput(
      LiveGitProcessRunner().run(["cat-file", "-t", candidateOID], at: cloneURL).output
    )
    guard candidateType == "commit" else {
      throw LiveGitCandidateRuntimeError.gitProcess("Candidate object is not a commit.")
    }
    let observedTree = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-parse", "\(candidateOID)^{tree}"],
        at: cloneURL
      ).output
    )
    guard observedTree == treeOID else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate commit does not retain the constructed tree."
      )
    }

    let checkerObservations = try checkerRegistry.verify(
      specifications: plan.policy.checkers,
      parentOID: plan.policy.baseCommitOID,
      candidateOID: candidateOID,
      allowedPaths: plan.policy.allowedPaths,
      repositoryURL: cloneURL
    )
    try publish(
      candidateOID: candidateOID,
      candidateBranchRef: plan.policy.candidateBranch,
      resultRef: plan.policy.resultRef,
      oidLength: oidLength,
      cloneURL: cloneURL
    )
    try checkpointObserver?(.resultRefPublished, cloneURL, candidateOID)

    let expectedWrites = try plan.writes.map { write in
      guard let contents = write.contents else {
        throw LiveGitCandidateRuntimeError.invalidPlan(
          "Write \(write.path) does not contain canonical base64."
        )
      }
      return LiveGitCandidateExpectedWrite(
        path: write.path,
        mode: write.mode,
        contentsSHA256: CanonicalMemoryJSON.sha256(contents)
      )
    }
    let passport = LiveGitCandidatePassport(
      planSHA256: knownPlanSHA256,
      coordinates: coordinates,
      parentOID: plan.policy.baseCommitOID,
      treeOID: treeOID,
      candidateOID: candidateOID,
      candidateBranchRef: plan.policy.candidateBranch,
      resultRef: plan.policy.resultRef,
      allowedPaths: plan.policy.allowedPaths,
      changedPaths: changedPaths,
      expectedWrites: expectedWrites,
      checkerSpecifications: plan.policy.checkers,
      checkerObservations: checkerObservations,
      author: plan.policy.author,
      committer: plan.policy.committer,
      message: plan.policy.message,
      preflightEventID: plan.preflightEventID,
      preflightReceiptID: plan.preflightReceiptID,
      executionEventID: plan.executionEventID,
      executionReceiptID: plan.executionReceiptID,
      observationEventID: plan.observationEventID,
      observationReceiptID: plan.observationReceiptID
    )
    try passport.validate()
    let canonicalPassport = try passport.canonicalJSON()
    try persistPassport(
      canonicalPassport,
      passport: passport,
      episodeURL: episodeURL
    )
    return LiveGitCandidateCommitResult(
      passport: passport,
      passportCanonicalJSON: canonicalPassport
    )
  }

  private func validatePlan(_ plan: LiveGitCandidatePlan) throws -> String {
    guard plan.schemaIdentity == LiveGitCandidateRuntimeSchema.planIdentity,
      plan.schemaVersion == LiveGitCandidateRuntimeSchema.version,
      plan.operation == LiveGitCandidateRuntimeSchema.operation
    else {
      throw LiveGitCandidateRuntimeError.invalidPlan("Unsupported candidate plan schema.")
    }
    do {
      try plan.policy.validate()
    } catch {
      throw LiveGitCandidateRuntimeError.invalidPlan("Candidate policy is invalid: \(error)")
    }
    let paths = plan.writes.map(\.path)
    guard !paths.isEmpty,
      paths == paths.sorted(),
      Set(paths).count == paths.count,
      Set(paths.map { $0.lowercased() }).count == paths.count,
      paths.allSatisfy(isStrictCandidatePath),
      plan.policy.allowedPaths.allSatisfy(isStrictCandidatePath),
      Set(plan.policy.allowedPaths.map { $0.lowercased() }).count
        == plan.policy.allowedPaths.count,
      Set(paths).isSubset(of: Set(plan.policy.allowedPaths)),
      plan.writes.allSatisfy({ $0.contents != nil }),
      plan.writes.reduce(
        0,
        { partial, write in
          partial + (write.contents?.count ?? LiveEpisodeRuntimeJSON.maximumCommandBytes)
        }) <= LiveEpisodeRuntimeJSON.maximumCommandBytes
    else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Writes must be sorted, unique, bounded, canonical regular-file writes inside allowed_paths."
      )
    }
    let identities = [
      plan.preflightEventID,
      plan.preflightReceiptID,
      plan.executionEventID,
      plan.executionReceiptID,
      plan.observationEventID,
      plan.observationReceiptID,
    ]
    guard identities.allSatisfy(isTechnicalIdentifier),
      Set(identities).count == identities.count
    else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Execution and observation event/receipt IDs must be distinct technical IDs."
      )
    }
    return try plan.canonicalSHA256()
  }

  private func validateIntentAndAllowance(
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    planSHA256: String,
    selectedIntent: LiveUntrustedActionIntent,
    allowance: LiveAllowedAction
  ) throws {
    guard coordinates.expectedEffectSHA256 == planSHA256,
      selectedIntent.expectedEffectSHA256 == planSHA256,
      selectedIntent.argumentsSHA256 == planSHA256
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Transition effect and selected intent arguments must equal the canonical plan digest."
      )
    }
    guard selectedIntent.operation == LiveGitCandidateContract.operation,
      selectedIntent.operation == allowance.operation,
      selectedIntent.adapterID == allowance.adapterID,
      selectedIntent.effectClass == allowance.effectClass,
      selectedIntent.objectID == coordinates.objectID,
      allowance.candidateCommitPolicy == plan.policy
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Selected intent, allowance, coordinates, and candidate policy do not bind exactly."
      )
    }
    do {
      try allowance.validateCandidateCommitPolicy()
    } catch {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Candidate allowance is invalid: \(error)"
      )
    }
  }

  private func validateAuthorizedEvent(
    _ events: [LiveEpisodeEvent],
    selectedIntent: LiveUntrustedActionIntent,
    allowance: LiveAllowedAction
  ) throws {
    guard
      let authorization = events.compactMap({ event in
        if case .authorizationDecided(let value) = event.payload { return value }
        return nil
      }).first,
      authorization.decision == .allowed,
      authorization.intentID == selectedIntent.intentID,
      authorization.allowanceID == allowance.allowanceID
    else {
      throw LiveGitCandidateRuntimeError.invalidEvidence(
        "Authorized receipt does not name the exact selected intent and allowance."
      )
    }
  }

  private func readOnlyPreflight(
    sourceCheckoutURL: URL,
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    planSHA256: String
  ) throws -> LiveGitCandidatePreflightResult {
    let sourceURL = sourceCheckoutURL.standardizedFileURL.resolvingSymlinksInPath()
    let episodeURL = episodeDirectoryURL.standardizedFileURL.resolvingSymlinksInPath()
    try requireDirectory(sourceURL, field: "source checkout")
    try requireDirectory(episodeURL, field: "episode directory")
    guard !isDescendant(episodeURL, of: sourceURL), episodeURL != sourceURL else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Episode directory must be outside the source checkout."
      )
    }
    let objectFormat = try trimmedGitOutput(
      LiveGitProcessRunner().run(["rev-parse", "--show-object-format"], at: sourceURL).output
    )
    let oidLength: Int
    switch objectFormat {
    case "sha1": oidLength = 40
    case "sha256": oidLength = 64
    default:
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Unsupported Git object format \(objectFormat)."
      )
    }
    try requireOID(plan.policy.baseCommitOID, length: oidLength, field: "base commit")
    try requireOID(plan.policy.expectedTreeOID, length: oidLength, field: "expected tree")
    try requireOID(plan.policy.expectedCandidateOID, length: oidLength, field: "expected candidate")
    let sourceHead = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-parse", "--verify", "HEAD^{commit}"],
        at: sourceURL
      ).output
    )
    guard sourceHead == plan.policy.baseCommitOID else {
      throw LiveGitCandidateRuntimeError.sourceBaseChanged(
        expected: plan.policy.baseCommitOID,
        actual: sourceHead
      )
    }
    try requireSeparateCandidateBranch(plan.policy.candidateBranch, sourceURL: sourceURL)
    let baseType = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["cat-file", "-t", plan.policy.baseCommitOID],
        at: sourceURL
      ).output
    )
    guard baseType == "commit" else {
      throw LiveGitCandidateRuntimeError.invalidPlan("Pinned base object is not a commit.")
    }
    let observation = LiveGitCandidatePreflightObservation(
      schemaIdentity: "fum.live_git_candidate.preflight_observation",
      schemaVersion: LiveGitCandidateRuntimeSchema.version,
      planSHA256: planSHA256,
      coordinates: coordinates,
      sourceCheckoutPath: sourceURL.path,
      episodeDirectoryPath: episodeURL.path,
      objectFormat: objectFormat,
      baseCommitOID: sourceHead
    )
    let observationSHA256 = CanonicalMemoryJSON.sha256(
      try CanonicalMemoryJSON.encode(observation)
    )
    return LiveGitCandidatePreflightResult(
      planSHA256: planSHA256,
      baseCommitOID: sourceHead,
      objectFormat: objectFormat,
      preflightEventID: plan.preflightEventID,
      preflightEvidence: LiveEvidenceObject(
        evidenceID: plan.preflightReceiptID,
        evidenceSHA256: observationSHA256
      )
    )
  }

  private func prepareClone(
    cloneURL: URL,
    sourceURL: URL,
    episodeURL: URL,
    baseOID: String,
    objectFormat: String
  ) throws {
    let createdClone: Bool
    if let status = try fileStatus(cloneURL) {
      guard isDirectory(status), !isSymbolicLink(status) else {
        throw LiveGitCandidateRuntimeError.unsafePath(cloneURL.path)
      }
      createdClone = false
    } else {
      _ = try LiveGitProcessRunner().run(
        [
          "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
          sourceURL.path, cloneURL.path,
        ],
        at: episodeURL
      )
      createdClone = true
    }
    let sourceGitDirectory = try trimmedGitOutput(
      LiveGitProcessRunner().run(["rev-parse", "--absolute-git-dir"], at: sourceURL).output
    )
    try prepareCloneMetadata(
      cloneURL: cloneURL,
      sourceGitDirectory: sourceGitDirectory,
      baseOID: baseOID,
      objectFormat: objectFormat,
      createdClone: createdClone
    )
    let cloneGitDirectory = try trimmedGitOutput(
      LiveGitProcessRunner().run(["rev-parse", "--absolute-git-dir"], at: cloneURL).output
    )
    let cloneCommonDirectory = try trimmedGitOutput(
      LiveGitProcessRunner().run(
        ["rev-parse", "--path-format=absolute", "--git-common-dir"], at: cloneURL
      ).output
    )
    let expectedCloneGitDirectory = cloneURL.appendingPathComponent(
      ".git",
      isDirectory: true
    ).standardizedFileURL.resolvingSymlinksInPath().path
    guard cloneGitDirectory != sourceGitDirectory,
      URL(fileURLWithPath: cloneGitDirectory).standardizedFileURL.resolvingSymlinksInPath().path
        == expectedCloneGitDirectory,
      URL(fileURLWithPath: cloneCommonDirectory).standardizedFileURL.resolvingSymlinksInPath().path
        == expectedCloneGitDirectory
    else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate clone does not have isolated Git metadata."
      )
    }
    _ = try LiveGitProcessRunner().run(["read-tree", "--reset", baseOID], at: cloneURL)
  }

  private func prepareCloneMetadata(
    cloneURL: URL,
    sourceGitDirectory: String,
    baseOID: String,
    objectFormat: String,
    createdClone: Bool
  ) throws {
    let cloneDescriptor = try openPlainDirectory(
      cloneURL,
      field: "candidate clone"
    )
    defer { _ = Darwin.close(cloneDescriptor) }
    let gitDescriptor = try openPlainDirectory(
      at: cloneDescriptor,
      component: ".git",
      field: "candidate .git"
    )
    defer { _ = Darwin.close(gitDescriptor) }
    let objectsDescriptor = try openPlainDirectory(
      at: gitDescriptor,
      component: "objects",
      field: "candidate objects"
    )
    defer { _ = Darwin.close(objectsDescriptor) }
    let refsDescriptor = try openPlainDirectory(
      at: gitDescriptor,
      component: "refs",
      field: "candidate refs"
    )
    defer { _ = Darwin.close(refsDescriptor) }
    let repositoryInfoDescriptor = try openPlainDirectory(
      at: gitDescriptor,
      component: "info",
      field: "candidate info"
    )
    defer { _ = Darwin.close(repositoryInfoDescriptor) }
    let infoDescriptor = try openPlainDirectory(
      at: objectsDescriptor,
      component: "info",
      field: "candidate objects/info"
    )
    defer { _ = Darwin.close(infoDescriptor) }
    let packDescriptor = try openPlainDirectory(
      at: objectsDescriptor,
      component: "pack",
      field: "candidate objects/pack"
    )
    defer { _ = Darwin.close(packDescriptor) }

    let cloneIdentities = try [
      cloneDescriptor,
      gitDescriptor,
      objectsDescriptor,
      refsDescriptor,
      repositoryInfoDescriptor,
      infoDescriptor,
      packDescriptor,
    ].map(fileSystemIdentity)
    guard Set(cloneIdentities).count == cloneIdentities.count else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate clone metadata directories are not isolated objects."
      )
    }
    try requirePlainMetadataTree(
      rootDescriptor: objectsDescriptor,
      field: "candidate objects"
    )
    try requirePlainMetadataTree(
      rootDescriptor: refsDescriptor,
      field: "candidate refs"
    )
    try requirePlainMetadataTree(
      rootDescriptor: repositoryInfoDescriptor,
      field: "candidate info"
    )
    let sourceGitURL = URL(fileURLWithPath: sourceGitDirectory, isDirectory: true)
    let sourceDirectories = [
      sourceGitURL,
      sourceGitURL.appendingPathComponent("objects", isDirectory: true),
      sourceGitURL.appendingPathComponent("refs", isDirectory: true),
      sourceGitURL.appendingPathComponent("info", isDirectory: true),
      sourceGitURL.appendingPathComponent("objects/info", isDirectory: true),
      sourceGitURL.appendingPathComponent("objects/pack", isDirectory: true),
    ]
    let sourceIdentities = Set(
      try sourceDirectories.compactMap(directoryIdentityFollowingLinks)
    )
    guard sourceIdentities.isDisjoint(with: cloneIdentities) else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate clone metadata aliases source Git metadata."
      )
    }
    try requireMissingEntry(
      at: infoDescriptor,
      component: "alternates",
      field: "candidate object alternates"
    )
    try requireMissingEntry(
      at: infoDescriptor,
      component: "http-alternates",
      field: "candidate HTTP object alternates"
    )
    try requireSafeRegularEntry(
      at: gitDescriptor,
      component: "HEAD",
      required: true,
      maximumBytes: 4_096,
      field: "candidate HEAD"
    )
    try requireSafeRegularEntry(
      at: gitDescriptor,
      component: "index",
      required: false,
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
      field: "candidate index"
    )
    try requireSafeRegularEntry(
      at: gitDescriptor,
      component: "packed-refs",
      required: false,
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
      field: "candidate packed-refs"
    )

    let marker = LiveGitCloneOwnershipMarker(
      sourceGitDirectory: sourceGitURL.standardizedFileURL.resolvingSymlinksInPath().path,
      baseOID: baseOID,
      objectFormat: objectFormat
    )
    let markerData = try CanonicalMemoryJSON.encode(marker)
    if createdClone {
      try writeExclusiveRegularFile(
        markerData,
        at: gitDescriptor,
        component: LiveGitCloneOwnershipMarker.fileName,
        permissions: 0o400,
        field: "candidate clone ownership marker"
      )
    } else {
      let existingMarker = try readSafeRegularEntry(
        at: gitDescriptor,
        component: LiveGitCloneOwnershipMarker.fileName,
        maximumBytes: 16_384,
        field: "candidate clone ownership marker"
      )
      guard existingMarker == markerData else {
        throw LiveGitCandidateRuntimeError.gitProcess(
          "Candidate clone does not have the exact runtime ownership marker."
        )
      }
    }
    try replaceSafeRegularFile(
      canonicalCloneConfiguration(objectFormat: objectFormat),
      at: gitDescriptor,
      component: "config",
      maximumExistingBytes: 1_048_576,
      permissions: 0o600,
      field: "candidate local config"
    )
  }

  private func verifyTreeEntries(
    treeOID: String,
    writes: [LiveGitRegularFileWrite],
    blobsByPath: [String: String],
    cloneURL: URL
  ) throws {
    let output = try LiveGitProcessRunner().run(
      ["ls-tree", "-z", treeOID, "--"] + writes.map(\.path),
      at: cloneURL
    ).output
    var entries: [String: (mode: String, type: String, oid: String)] = [:]
    for record in output.split(separator: 0, omittingEmptySubsequences: true) {
      guard let tabIndex = record.firstIndex(of: 9) else {
        throw LiveGitCandidateRuntimeError.gitProcess("Malformed NUL ls-tree record.")
      }
      let metadata = record[..<tabIndex].split(separator: 32)
      let pathBytes = record[record.index(after: tabIndex)...]
      guard metadata.count == 3 else {
        throw LiveGitCandidateRuntimeError.gitProcess("Malformed ls-tree metadata.")
      }
      entries[String(decoding: pathBytes, as: UTF8.self)] = (
        String(decoding: metadata[0], as: UTF8.self),
        String(decoding: metadata[1], as: UTF8.self),
        String(decoding: metadata[2], as: UTF8.self)
      )
    }
    guard entries.count == writes.count else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate tree does not contain every exact expected write."
      )
    }
    for write in writes {
      guard let entry = entries[write.path], entry.mode == write.mode.rawValue,
        entry.type == "blob", entry.oid == blobsByPath[write.path]
      else {
        throw LiveGitCandidateRuntimeError.gitProcess(
          "Candidate tree entry \(write.path) is not the exact regular-file blob and mode."
        )
      }
    }
  }

  private func publish(
    candidateOID: String,
    candidateBranchRef: String,
    resultRef: String,
    oidLength: Int,
    cloneURL: URL
  ) throws {
    try publishRef(
      candidateBranchRef,
      candidateOID: candidateOID,
      oidLength: oidLength,
      cloneURL: cloneURL
    )
    try publishRef(
      resultRef,
      candidateOID: candidateOID,
      oidLength: oidLength,
      cloneURL: cloneURL
    )
  }

  private func publishRef(
    _ ref: String,
    candidateOID: String,
    oidLength: Int,
    cloneURL: URL
  ) throws {
    let before = try readDirectRef(ref, cloneURL: cloneURL)
    if before == candidateOID { return }
    guard before == nil else {
      throw LiveGitCandidateRuntimeError.candidateConflict(
        ref: ref,
        expected: candidateOID,
        actual: before
      )
    }
    do {
      _ = try LiveGitProcessRunner().run(
        ["update-ref", "--no-deref", ref, candidateOID, String(repeating: "0", count: oidLength)],
        at: cloneURL
      )
    } catch {
      let after = try readDirectRef(ref, cloneURL: cloneURL)
      guard after == candidateOID else {
        throw LiveGitCandidateRuntimeError.candidateConflict(
          ref: ref,
          expected: candidateOID,
          actual: after
        )
      }
    }
  }

  private func readDirectRef(_ ref: String, cloneURL: URL) throws -> String? {
    let result = try LiveGitProcessRunner().run(
      ["for-each-ref", "--format=%(refname)%00%(objectname)%00%(symref)%00", "--", ref],
      at: cloneURL
    )
    guard !result.output.isEmpty else { return nil }
    var exactFields: [Data]?
    for line in result.output.split(separator: 0x0A, omittingEmptySubsequences: true) {
      let fields = line.split(separator: 0, omittingEmptySubsequences: false).map(Data.init)
      guard fields.count == 4, fields[3].isEmpty else {
        throw LiveGitCandidateRuntimeError.gitProcess("Malformed exact-ref observation.")
      }
      guard String(data: fields[0], encoding: .utf8) == ref else { continue }
      guard exactFields == nil else {
        throw LiveGitCandidateRuntimeError.gitProcess("Exact ref is not unique.")
      }
      exactFields = fields
    }
    guard let fields = exactFields else { return nil }
    guard fields[2].isEmpty else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Candidate and result refs must be direct, non-symbolic refs."
      )
    }
    guard let oid = String(data: fields[1], encoding: .utf8), !oid.isEmpty else {
      throw LiveGitCandidateRuntimeError.gitProcess("Direct ref does not contain an exact OID.")
    }
    return oid
  }

  private func persistPassport(
    _ data: Data,
    passport: LiveGitCandidatePassport,
    episodeURL: URL
  ) throws {
    guard data.count <= LiveEpisodeRuntimeJSON.maximumCommandBytes else {
      throw LiveGitCandidateRuntimeError.persistence("Candidate passport exceeds the fixed limit.")
    }
    let rootDescriptor = episodeURL.withUnsafeFileSystemRepresentation { path -> Int32 in
      guard let path else { return -1 }
      return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard rootDescriptor >= 0 else {
      throw LiveGitCandidateRuntimeError.unsafePath(episodeURL.path)
    }
    var directoryDescriptor = rootDescriptor
    defer { _ = Darwin.close(directoryDescriptor) }
    for component in [
      LiveGitCandidateRuntimeSchema.candidatesRelativePath,
      passport.candidateOID,
    ] {
      var nextDescriptor = component.withCString {
        Darwin.openat(
          directoryDescriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
      }
      if nextDescriptor < 0, errno == ENOENT {
        let creation = component.withCString {
          Darwin.mkdirat(directoryDescriptor, $0, 0o700)
        }
        guard creation == 0 || errno == EEXIST else {
          throw LiveGitCandidateRuntimeError.persistence(
            "Candidate passport directory could not be created."
          )
        }
        guard Darwin.fsync(directoryDescriptor) == 0 else {
          throw LiveGitCandidateRuntimeError.persistence(
            "Candidate passport parent directory could not be synchronized."
          )
        }
        nextDescriptor = component.withCString {
          Darwin.openat(
            directoryDescriptor,
            $0,
            O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
          )
        }
      }
      guard nextDescriptor >= 0 else {
        throw LiveGitCandidateRuntimeError.unsafePath(passport.storageRelativePath)
      }
      _ = Darwin.close(directoryDescriptor)
      directoryDescriptor = nextDescriptor
    }

    let fileName = LiveGitCandidateRuntimeSchema.passportFileName
    if try requireExactExistingPassport(
      at: directoryDescriptor,
      component: fileName,
      expectedData: data,
      expectedPassport: passport
    ) {
      return
    }

    let temporaryName = ".passport-\(UUID().uuidString.lowercased()).tmp"
    let temporaryDescriptor = temporaryName.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
        0o600
      )
    }
    guard temporaryDescriptor >= 0 else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport temporary file could not be created."
      )
    }
    do {
      try writeAll(data, descriptor: temporaryDescriptor)
      guard Darwin.fchmod(temporaryDescriptor, 0o444) == 0,
        Darwin.fsync(temporaryDescriptor) == 0
      else {
        throw LiveGitCandidateRuntimeError.persistence(
          "Candidate passport temporary file could not be synchronized."
        )
      }
    } catch {
      _ = Darwin.close(temporaryDescriptor)
      temporaryName.withCString { _ = Darwin.unlinkat(directoryDescriptor, $0, 0) }
      throw error
    }
    _ = Darwin.close(temporaryDescriptor)

    let linked = temporaryName.withCString { temporary in
      fileName.withCString { final in
        Darwin.linkat(directoryDescriptor, temporary, directoryDescriptor, final, 0)
      }
    }
    let linkError = errno
    temporaryName.withCString { _ = Darwin.unlinkat(directoryDescriptor, $0, 0) }
    if linked != 0, linkError != EEXIST {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport could not be published atomically."
      )
    }
    guard Darwin.fsync(directoryDescriptor) == 0 else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport directory could not be synchronized."
      )
    }
    guard
      try requireExactExistingPassport(
        at: directoryDescriptor,
        component: fileName,
        expectedData: data,
        expectedPassport: passport
      )
    else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Published candidate passport could not be reopened."
      )
    }
  }
}

private struct LiveGitCloneOwnershipMarker: Encodable {
  static let fileName = "fum-runtime-owner.json"

  let schemaIdentity = "fum.live_git_candidate.clone_owner"
  let schemaVersion = 1
  let sourceGitDirectory: String
  let baseOID: String
  let objectFormat: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case sourceGitDirectory = "source_git_directory"
    case baseOID = "base_oid"
    case objectFormat = "object_format"
  }
}

private struct FileSystemIdentity: Hashable {
  let device: UInt64
  let inode: UInt64

  init(_ information: stat) {
    device = UInt64(information.st_dev)
    inode = UInt64(information.st_ino)
  }
}

private func openPlainDirectory(_ url: URL, field: String) throws -> Int32 {
  guard let before = try fileStatus(url), isDirectory(before), !isSymbolicLink(before) else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  let descriptor = url.withUnsafeFileSystemRepresentation { path -> Int32 in
    guard let path else { return -1 }
    return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  var after = stat()
  guard Darwin.fstat(descriptor, &after) == 0,
    isDirectory(after),
    FileSystemIdentity(before) == FileSystemIdentity(after)
  else {
    _ = Darwin.close(descriptor)
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  return descriptor
}

private func openPlainDirectory(
  at parentDescriptor: Int32,
  component: String,
  field: String
) throws -> Int32 {
  var before = stat()
  let inspected = component.withCString {
    Darwin.fstatat(parentDescriptor, $0, &before, AT_SYMLINK_NOFOLLOW)
  }
  guard inspected == 0, isDirectory(before), !isSymbolicLink(before) else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  let descriptor = component.withCString {
    Darwin.openat(
      parentDescriptor,
      $0,
      O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
    )
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  var after = stat()
  guard Darwin.fstat(descriptor, &after) == 0,
    isDirectory(after),
    FileSystemIdentity(before) == FileSystemIdentity(after)
  else {
    _ = Darwin.close(descriptor)
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  return descriptor
}

private func fileSystemIdentity(_ descriptor: Int32) throws -> FileSystemIdentity {
  var information = stat()
  guard Darwin.fstat(descriptor, &information) == 0, isDirectory(information) else {
    throw LiveGitCandidateRuntimeError.gitProcess(
      "Candidate metadata descriptor is no longer a directory."
    )
  }
  return FileSystemIdentity(information)
}

private func directoryIdentityFollowingLinks(_ url: URL) throws -> FileSystemIdentity? {
  let descriptor = url.withUnsafeFileSystemRepresentation { path -> Int32 in
    guard let path else { return -1 }
    return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
  }
  if descriptor < 0 {
    if errno == ENOENT { return nil }
    throw LiveGitCandidateRuntimeError.gitProcess(
      "Source Git metadata directory could not be inspected."
    )
  }
  defer { _ = Darwin.close(descriptor) }
  return try fileSystemIdentity(descriptor)
}

private func requirePlainMetadataTree(
  rootDescriptor: Int32,
  field: String
) throws {
  var visited: Set<FileSystemIdentity> = []
  var entryCount = 0
  try requirePlainMetadataTree(
    directoryDescriptor: rootDescriptor,
    field: field,
    depth: 0,
    visited: &visited,
    entryCount: &entryCount
  )
}

private func requirePlainMetadataTree(
  directoryDescriptor: Int32,
  field: String,
  depth: Int,
  visited: inout Set<FileSystemIdentity>,
  entryCount: inout Int
) throws {
  guard depth <= 128 else {
    throw LiveGitCandidateRuntimeError.gitProcess("The \(field) tree is too deep.")
  }
  let identity = try fileSystemIdentity(directoryDescriptor)
  guard visited.insert(identity).inserted else {
    throw LiveGitCandidateRuntimeError.gitProcess(
      "The \(field) tree aliases an already inspected directory."
    )
  }
  let duplicate = Darwin.dup(directoryDescriptor)
  guard duplicate >= 0, let directory = Darwin.fdopendir(duplicate) else {
    if duplicate >= 0 { _ = Darwin.close(duplicate) }
    throw LiveGitCandidateRuntimeError.gitProcess("The \(field) tree could not be enumerated.")
  }
  defer { _ = Darwin.closedir(directory) }
  while true {
    errno = 0
    guard let entry = Darwin.readdir(directory) else {
      guard errno == 0 else {
        throw LiveGitCandidateRuntimeError.gitProcess(
          "The \(field) tree enumeration failed."
        )
      }
      break
    }
    let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
      pointer.withMemoryRebound(
        to: CChar.self,
        capacity: MemoryLayout.size(ofValue: entry.pointee.d_name)
      ) {
        String(cString: $0)
      }
    }
    if name == "." || name == ".." { continue }
    entryCount += 1
    guard entryCount <= 2_000_000 else {
      throw LiveGitCandidateRuntimeError.gitProcess("The \(field) tree is too large.")
    }
    guard
      let information = try entryStatus(
        at: directoryDescriptor,
        component: name
      )
    else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "The \(field) tree changed during inspection."
      )
    }
    if isDirectory(information) {
      let childDescriptor = try openPlainDirectory(
        at: directoryDescriptor,
        component: name,
        field: "\(field)/\(name)"
      )
      defer { _ = Darwin.close(childDescriptor) }
      try requirePlainMetadataTree(
        directoryDescriptor: childDescriptor,
        field: "\(field)/\(name)",
        depth: depth + 1,
        visited: &visited,
        entryCount: &entryCount
      )
      continue
    }
    guard isRegularFile(information), information.st_nlink == 1 else {
      throw LiveGitCandidateRuntimeError.unsafePath("\(field)/\(name)")
    }
  }
}

private func entryStatus(
  at parentDescriptor: Int32,
  component: String
) throws -> stat? {
  var information = stat()
  let result = component.withCString {
    Darwin.fstatat(parentDescriptor, $0, &information, AT_SYMLINK_NOFOLLOW)
  }
  if result == 0 { return information }
  if errno == ENOENT { return nil }
  throw LiveGitCandidateRuntimeError.persistence(
    "Candidate metadata entry could not be inspected."
  )
}

private func requireMissingEntry(
  at parentDescriptor: Int32,
  component: String,
  field: String
) throws {
  guard try entryStatus(at: parentDescriptor, component: component) == nil else {
    throw LiveGitCandidateRuntimeError.gitProcess("The \(field) must be absent.")
  }
}

private func requireSafeRegularEntry(
  at parentDescriptor: Int32,
  component: String,
  required: Bool,
  maximumBytes: Int,
  field: String
) throws {
  guard let information = try entryStatus(at: parentDescriptor, component: component) else {
    if required { throw LiveGitCandidateRuntimeError.unsafePath(field) }
    return
  }
  guard isRegularFile(information), information.st_nlink == 1,
    information.st_size >= 0, information.st_size <= off_t(maximumBytes)
  else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
}

private func readSafeRegularEntry(
  at parentDescriptor: Int32,
  component: String,
  maximumBytes: Int,
  field: String
) throws -> Data {
  guard let before = try entryStatus(at: parentDescriptor, component: component),
    isRegularFile(before), before.st_nlink == 1
  else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  let descriptor = component.withCString {
    Darwin.openat(
      parentDescriptor,
      $0,
      O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW
    )
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  defer { _ = Darwin.close(descriptor) }
  var after = stat()
  guard Darwin.fstat(descriptor, &after) == 0,
    FileSystemIdentity(before) == FileSystemIdentity(after)
  else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  return try readBoundedRegularFile(descriptor: descriptor, maximumBytes: maximumBytes)
}

private func writeExclusiveRegularFile(
  _ data: Data,
  at parentDescriptor: Int32,
  component: String,
  permissions: mode_t,
  field: String
) throws {
  let descriptor = component.withCString {
    Darwin.openat(
      parentDescriptor,
      $0,
      O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
      permissions
    )
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(field)
  }
  do {
    try writeAll(data, descriptor: descriptor)
    guard Darwin.fchmod(descriptor, permissions) == 0,
      Darwin.fsync(descriptor) == 0,
      Darwin.fsync(parentDescriptor) == 0
    else {
      throw LiveGitCandidateRuntimeError.persistence("The \(field) could not be synchronized.")
    }
    _ = Darwin.close(descriptor)
  } catch {
    _ = Darwin.close(descriptor)
    component.withCString { _ = Darwin.unlinkat(parentDescriptor, $0, 0) }
    throw error
  }
}

private func replaceSafeRegularFile(
  _ data: Data,
  at parentDescriptor: Int32,
  component: String,
  maximumExistingBytes: Int,
  permissions: mode_t,
  field: String
) throws {
  let existing = try readSafeRegularEntry(
    at: parentDescriptor,
    component: component,
    maximumBytes: maximumExistingBytes,
    field: field
  )
  if existing == data { return }
  let temporary = ".\(component)-\(UUID().uuidString.lowercased()).tmp"
  let descriptor = temporary.withCString {
    Darwin.openat(
      parentDescriptor,
      $0,
      O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
      permissions
    )
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.persistence("The \(field) temporary file was refused.")
  }
  do {
    try writeAll(data, descriptor: descriptor)
    guard Darwin.fchmod(descriptor, permissions) == 0,
      Darwin.fsync(descriptor) == 0
    else {
      throw LiveGitCandidateRuntimeError.persistence("The \(field) could not be synchronized.")
    }
    _ = Darwin.close(descriptor)
  } catch {
    _ = Darwin.close(descriptor)
    temporary.withCString { _ = Darwin.unlinkat(parentDescriptor, $0, 0) }
    throw error
  }
  let replaced = temporary.withCString { temporaryPath in
    component.withCString { finalPath in
      Darwin.renameat(parentDescriptor, temporaryPath, parentDescriptor, finalPath)
    }
  }
  if replaced != 0 {
    temporary.withCString { _ = Darwin.unlinkat(parentDescriptor, $0, 0) }
    throw LiveGitCandidateRuntimeError.persistence("The \(field) could not be replaced.")
  }
  guard Darwin.fsync(parentDescriptor) == 0 else {
    throw LiveGitCandidateRuntimeError.persistence("The \(field) parent was not synchronized.")
  }
}

private func canonicalCloneConfiguration(objectFormat: String) -> Data {
  let repositoryFormatVersion = objectFormat == "sha256" ? 1 : 0
  var text = """
    [core]
    \trepositoryformatversion = \(repositoryFormatVersion)
    \tfilemode = true
    \tbare = false
    \tlogallrefupdates = true

    """
  if objectFormat == "sha256" {
    text += """
      [extensions]
      \tobjectformat = sha256

      """
  }
  return Data(text.utf8)
}

private struct LiveGitCandidatePreflightObservation: Encodable {
  let schemaIdentity: String
  let schemaVersion: Int
  let planSHA256: String
  let coordinates: LiveTransitionCoordinates
  let sourceCheckoutPath: String
  let episodeDirectoryPath: String
  let objectFormat: String
  let baseCommitOID: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case planSHA256 = "plan_sha256"
    case coordinates
    case sourceCheckoutPath = "source_checkout_path"
    case episodeDirectoryPath = "episode_directory_path"
    case objectFormat = "object_format"
    case baseCommitOID = "base_commit_oid"
  }
}

private func materializeRegularFile(
  _ write: LiveGitRegularFileWrite,
  contents: Data,
  cloneURL: URL
) throws {
  let components = write.path.split(separator: "/", omittingEmptySubsequences: false)
    .map(String.init)
  guard !components.isEmpty, components.allSatisfy({ !$0.isEmpty }) else {
    throw LiveGitCandidateRuntimeError.unsafePath(write.path)
  }
  let rootDescriptor = cloneURL.withUnsafeFileSystemRepresentation { path -> Int32 in
    guard let path else { return -1 }
    return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
  }
  guard rootDescriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(write.path)
  }
  var parentDescriptor = rootDescriptor
  defer { _ = Darwin.close(parentDescriptor) }
  for component in components.dropLast() {
    var nextDescriptor = component.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
      )
    }
    if nextDescriptor < 0, errno == ENOENT {
      let creation = component.withCString {
        Darwin.mkdirat(parentDescriptor, $0, 0o755)
      }
      guard creation == 0 || errno == EEXIST else {
        throw LiveGitCandidateRuntimeError.unsafePath(write.path)
      }
      nextDescriptor = component.withCString {
        Darwin.openat(
          parentDescriptor,
          $0,
          O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
      }
    }
    guard nextDescriptor >= 0 else {
      throw LiveGitCandidateRuntimeError.unsafePath(write.path)
    }
    _ = Darwin.close(parentDescriptor)
    parentDescriptor = nextDescriptor
  }
  let fileName = components.last!
  var descriptor = fileName.withCString {
    Darwin.openat(
      parentDescriptor,
      $0,
      O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
      0o600
    )
  }
  if descriptor < 0, errno == EEXIST {
    descriptor = fileName.withCString {
      Darwin.openat(
        parentDescriptor,
        $0,
        O_WRONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK
      )
    }
  }
  guard descriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(write.path)
  }
  defer { _ = Darwin.close(descriptor) }
  var information = stat()
  guard Darwin.fstat(descriptor, &information) == 0,
    isRegularFile(information), information.st_nlink == 1,
    Darwin.ftruncate(descriptor, 0) == 0
  else {
    throw LiveGitCandidateRuntimeError.unsafePath(write.path)
  }
  try writeAll(contents, descriptor: descriptor)
  let permissions: mode_t = write.mode == .regular ? 0o644 : 0o755
  guard Darwin.fchmod(descriptor, permissions) == 0,
    Darwin.fsync(descriptor) == 0
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate mode write failed for \(write.path)."
    )
  }
}

private func gitIdentityEnvironment(
  _ policy: LiveGitCandidateCommitPolicy
) -> [String: String] {
  [
    "GIT_AUTHOR_NAME": policy.author.name,
    "GIT_AUTHOR_EMAIL": policy.author.email,
    "GIT_AUTHOR_DATE": gitDate(policy.author),
    "GIT_COMMITTER_NAME": policy.committer.name,
    "GIT_COMMITTER_EMAIL": policy.committer.email,
    "GIT_COMMITTER_DATE": gitDate(policy.committer),
  ]
}

private func gitDate(_ signature: LiveGitCandidateSignature) -> String {
  let minutes = signature.timeZoneOffsetMinutes
  let sign = minutes < 0 ? "-" : "+"
  let magnitude = abs(minutes)
  return String(
    format: "%lld %@%02d%02d",
    signature.timestampSeconds,
    sign,
    magnitude / 60,
    magnitude % 60
  )
}

private func requireOID(_ value: String, length: Int, field: String) throws {
  guard value.count == length,
    value.allSatisfy({ "0123456789abcdef".contains($0) })
  else {
    throw LiveGitCandidateRuntimeError.invalidPlan("Invalid exact \(field) OID.")
  }
}

private func requireSeparateCandidateBranch(
  _ branchRef: String,
  sourceURL: URL
) throws {
  let result = try LiveGitProcessRunner().run(
    ["show-ref", "--verify", "--quiet", branchRef],
    at: sourceURL,
    acceptedStatuses: [0, 1]
  )
  guard result.status == 1 else {
    throw LiveGitCandidateRuntimeError.invalidPlan(
      "Candidate branch must not already exist in the source repository."
    )
  }
}

private func isStrictCandidatePath(_ value: String) -> Bool {
  guard !value.isEmpty,
    value == value.precomposedStringWithCanonicalMapping,
    value == value.trimmingCharacters(in: .whitespacesAndNewlines),
    !value.hasPrefix("/"),
    !value.hasPrefix("~"),
    !value.contains("\\"),
    !value.contains(":"),
    !value.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7f })
  else { return false }
  let components = value.split(separator: "/", omittingEmptySubsequences: false)
  return !components.isEmpty
    && components.allSatisfy {
      !$0.isEmpty && $0 != "." && $0 != ".." && $0.lowercased() != ".git"
    }
}

private func trimmedGitOutput(_ data: Data) throws -> String {
  guard let value = String(data: data, encoding: .utf8) else {
    throw LiveGitCandidateRuntimeError.gitProcess("Git output is not UTF-8.")
  }
  return value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func nulStrings(_ data: Data) throws -> [String] {
  try data.split(separator: 0, omittingEmptySubsequences: true).map { bytes in
    guard let value = String(data: Data(bytes), encoding: .utf8) else {
      throw LiveGitCandidateRuntimeError.gitProcess("Git NUL output is not UTF-8.")
    }
    return value
  }
}

private func isTechnicalIdentifier(_ value: String) -> Bool {
  guard let first = value.unicodeScalars.first, value.unicodeScalars.count <= 128 else {
    return false
  }
  let initial = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
  let rest = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
  return initial.contains(first) && value.unicodeScalars.allSatisfy(rest.contains)
}

private func isDescendant(_ candidate: URL, of parent: URL) -> Bool {
  let candidatePath = candidate.standardizedFileURL.path
  let parentPath = parent.standardizedFileURL.path
  return candidatePath.hasPrefix(parentPath + "/")
}

private func requireDirectory(_ url: URL, field: String) throws {
  guard let status = try fileStatus(url), isDirectory(status), !isSymbolicLink(status) else {
    throw LiveGitCandidateRuntimeError.invalidPlan("The \(field) is not a real directory.")
  }
}

private func readRegularFileBeneath(
  rootURL: URL,
  relativePath: String,
  maximumBytes: Int
) throws -> Data {
  let components = relativePath.split(separator: "/", omittingEmptySubsequences: false)
    .map(String.init)
  guard !components.isEmpty,
    components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("\0") })
  else {
    throw LiveGitCandidateRuntimeError.unsafePath(relativePath)
  }
  let rootDescriptor = rootURL.withUnsafeFileSystemRepresentation { path -> Int32 in
    guard let path else { return -1 }
    return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
  }
  guard rootDescriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(rootURL.path)
  }
  var directoryDescriptor = rootDescriptor
  defer { _ = Darwin.close(directoryDescriptor) }
  for component in components.dropLast() {
    let nextDescriptor = component.withCString {
      Darwin.openat(
        directoryDescriptor,
        $0,
        O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
      )
    }
    guard nextDescriptor >= 0 else {
      throw LiveGitCandidateRuntimeError.unsafePath(relativePath)
    }
    _ = Darwin.close(directoryDescriptor)
    directoryDescriptor = nextDescriptor
  }
  let fileDescriptor = components.last!.withCString {
    Darwin.openat(
      directoryDescriptor,
      $0,
      O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW
    )
  }
  guard fileDescriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.unsafePath(relativePath)
  }
  defer { _ = Darwin.close(fileDescriptor) }
  return try readBoundedRegularFile(descriptor: fileDescriptor, maximumBytes: maximumBytes)
}

private func requireExactExistingPassport(
  at directoryDescriptor: Int32,
  component: String,
  expectedData: Data,
  expectedPassport: LiveGitCandidatePassport
) throws -> Bool {
  let descriptor = component.withCString {
    Darwin.openat(
      directoryDescriptor,
      $0,
      O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW
    )
  }
  if descriptor < 0 {
    let openError = errno
    if openError == ENOENT { return false }
    throw LiveGitCandidateRuntimeError.unsafePath(component)
  }
  defer { _ = Darwin.close(descriptor) }

  var information = stat()
  guard Darwin.fstat(descriptor, &information) == 0 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Existing candidate passport metadata could not be inspected."
    )
  }
  if information.st_nlink == 1 {
    let existing = try readBoundedRegularFile(
      descriptor: descriptor,
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes
    )
    try requireExactPassport(
      existing,
      expectedData: expectedData,
      expectedPassport: expectedPassport
    )
    return true
  }
  guard information.st_nlink == 2 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Existing candidate passport has ambiguous hard-link aliases."
    )
  }
  try recoverExactPassportTemporaryAlias(
    finalDescriptor: descriptor,
    finalComponent: component,
    directoryDescriptor: directoryDescriptor,
    expectedData: expectedData,
    expectedPassport: expectedPassport
  )
  return true
}

private func recoverExactPassportTemporaryAlias(
  finalDescriptor: Int32,
  finalComponent: String,
  directoryDescriptor: Int32,
  expectedData: Data,
  expectedPassport: LiveGitCandidatePassport
) throws {
  var directoryInformation = stat()
  guard Darwin.fstat(directoryDescriptor, &directoryInformation) == 0,
    isDirectory(directoryInformation),
    directoryInformation.st_uid == Darwin.geteuid(),
    directoryInformation.st_mode & 0o022 == 0
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport recovery directory has unsafe metadata."
    )
  }

  var finalBefore = stat()
  guard Darwin.fstat(finalDescriptor, &finalBefore) == 0 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport recovery metadata could not be read."
    )
  }
  let identity = FileSystemIdentity(finalBefore)
  guard
    isExactRecoverablePassportFile(
      finalBefore,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    )
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport hard-link state is not safely recoverable."
    )
  }
  let finalData = try readBoundedRegularFile(
    descriptor: finalDescriptor,
    maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
    expectedLinkCount: 2
  )
  try requireExactPassport(
    finalData,
    expectedData: expectedData,
    expectedPassport: expectedPassport
  )

  let temporaryNames = try strictPassportTemporaryNames(at: directoryDescriptor)
  guard temporaryNames.count == 1 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport temporary alias is missing or ambiguous."
    )
  }
  let temporaryName = temporaryNames[0]
  guard
    let temporaryEntryBefore = try entryStatus(
      at: directoryDescriptor,
      component: temporaryName
    ),
    isExactRecoverablePassportFile(
      temporaryEntryBefore,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    )
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport temporary alias does not identify the exact published inode."
    )
  }
  let temporaryDescriptor = temporaryName.withCString {
    Darwin.openat(
      directoryDescriptor,
      $0,
      O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW
    )
  }
  guard temporaryDescriptor >= 0 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport temporary alias could not be opened safely."
    )
  }
  defer { _ = Darwin.close(temporaryDescriptor) }

  var temporaryOpened = stat()
  guard Darwin.fstat(temporaryDescriptor, &temporaryOpened) == 0,
    isExactRecoverablePassportFile(
      temporaryOpened,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    )
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport temporary alias changed while it was opened."
    )
  }
  let temporaryData = try readBoundedRegularFile(
    descriptor: temporaryDescriptor,
    maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
    expectedLinkCount: 2
  )
  try requireExactPassport(
    temporaryData,
    expectedData: expectedData,
    expectedPassport: expectedPassport
  )

  var finalReady = stat()
  var temporaryReady = stat()
  guard Darwin.fstat(finalDescriptor, &finalReady) == 0,
    Darwin.fstat(temporaryDescriptor, &temporaryReady) == 0,
    isExactRecoverablePassportFile(
      finalReady,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    ),
    isExactRecoverablePassportFile(
      temporaryReady,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    ),
    let finalEntryReady = try entryStatus(
      at: directoryDescriptor,
      component: finalComponent
    ),
    let temporaryEntryReady = try entryStatus(
      at: directoryDescriptor,
      component: temporaryName
    ),
    isExactRecoverablePassportFile(
      finalEntryReady,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    ),
    isExactRecoverablePassportFile(
      temporaryEntryReady,
      identity: identity,
      expectedLinkCount: 2,
      expectedByteCount: expectedData.count
    )
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport aliases changed before recovery."
    )
  }

  let unlinked = temporaryName.withCString {
    Darwin.unlinkat(directoryDescriptor, $0, 0)
  }
  guard unlinked == 0, Darwin.fsync(directoryDescriptor) == 0 else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport temporary alias could not be durably removed."
    )
  }

  var finalAfter = stat()
  var temporaryAfter = stat()
  guard Darwin.fstat(finalDescriptor, &finalAfter) == 0,
    Darwin.fstat(temporaryDescriptor, &temporaryAfter) == 0,
    isExactRecoverablePassportFile(
      finalAfter,
      identity: identity,
      expectedLinkCount: 1,
      expectedByteCount: expectedData.count
    ),
    isExactRecoverablePassportFile(
      temporaryAfter,
      identity: identity,
      expectedLinkCount: 1,
      expectedByteCount: expectedData.count
    ),
    let finalEntryAfter = try entryStatus(
      at: directoryDescriptor,
      component: finalComponent
    ),
    isExactRecoverablePassportFile(
      finalEntryAfter,
      identity: identity,
      expectedLinkCount: 1,
      expectedByteCount: expectedData.count
    ),
    try entryStatus(at: directoryDescriptor, component: temporaryName) == nil
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport recovery did not produce one exact durable link."
    )
  }
}

private func strictPassportTemporaryNames(at directoryDescriptor: Int32) throws -> [String] {
  let enumerationDescriptor = ".".withCString {
    Darwin.openat(
      directoryDescriptor,
      $0,
      O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
    )
  }
  guard enumerationDescriptor >= 0,
    let directory = Darwin.fdopendir(enumerationDescriptor)
  else {
    if enumerationDescriptor >= 0 { _ = Darwin.close(enumerationDescriptor) }
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport directory could not be enumerated safely."
    )
  }
  defer { _ = Darwin.closedir(directory) }
  var result: [String] = []
  while true {
    errno = 0
    guard let entry = Darwin.readdir(directory) else {
      guard errno == 0 else {
        throw LiveGitCandidateRuntimeError.persistence(
          "Candidate passport directory enumeration failed."
        )
      }
      break
    }
    let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
      pointer.withMemoryRebound(
        to: CChar.self,
        capacity: MemoryLayout.size(ofValue: entry.pointee.d_name)
      ) {
        String(cString: $0)
      }
    }
    if isStrictPassportTemporaryName(name) { result.append(name) }
  }
  return result
}

private func isStrictPassportTemporaryName(_ value: String) -> Bool {
  let prefix = ".passport-"
  let suffix = ".tmp"
  guard value.hasPrefix(prefix), value.hasSuffix(suffix) else { return false }
  let token = value.dropFirst(prefix.count).dropLast(suffix.count)
  let bytes = Array(token.utf8)
  guard bytes.count == 36, bytes[14] == 0x34,
    [UInt8]("89ab".utf8).contains(bytes[19])
  else {
    return false
  }
  for index in bytes.indices {
    if [8, 13, 18, 23].contains(index) {
      if bytes[index] != 0x2d { return false }
    } else if !(0x30...0x39).contains(bytes[index]) && !(0x61...0x66).contains(bytes[index]) {
      return false
    }
  }
  return true
}

private func isExactRecoverablePassportFile(
  _ information: stat,
  identity: FileSystemIdentity,
  expectedLinkCount: Int,
  expectedByteCount: Int
) -> Bool {
  isRegularFile(information)
    && FileSystemIdentity(information) == identity
    && Int(information.st_nlink) == expectedLinkCount
    && information.st_uid == Darwin.geteuid()
    && information.st_mode & 0o7777 == 0o444
    && information.st_size == off_t(expectedByteCount)
}

private func readBoundedRegularFile(
  descriptor: Int32,
  maximumBytes: Int,
  expectedLinkCount: Int = 1
) throws -> Data {
  var information = stat()
  guard Darwin.fstat(descriptor, &information) == 0,
    isRegularFile(information),
    Int(information.st_nlink) == expectedLinkCount,
    information.st_size >= 0,
    information.st_size <= off_t(maximumBytes)
  else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Candidate passport is not a bounded regular file."
    )
  }
  var output = Data()
  output.reserveCapacity(Int(information.st_size))
  var buffer = [UInt8](repeating: 0, count: 16_384)
  while true {
    let count = buffer.withUnsafeMutableBytes { bytes in
      Darwin.read(descriptor, bytes.baseAddress, bytes.count)
    }
    guard count >= 0 else {
      throw LiveGitCandidateRuntimeError.persistence("Observed passport read failed.")
    }
    if count == 0 { break }
    guard output.count + count <= maximumBytes else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Observed passport exceeds the fixed limit."
      )
    }
    output.append(contentsOf: buffer.prefix(count))
  }
  return output
}

private func writeAll(_ data: Data, descriptor: Int32) throws {
  try data.withUnsafeBytes { bytes in
    var offset = 0
    while offset < bytes.count {
      guard let baseAddress = bytes.baseAddress else { break }
      let count = Darwin.write(
        descriptor,
        baseAddress.advanced(by: offset),
        bytes.count - offset
      )
      guard count > 0 else {
        throw LiveGitCandidateRuntimeError.persistence(
          "Bounded isolated-file write failed."
        )
      }
      offset += count
    }
  }
}

private func requireExactPassport(
  _ stored: Data,
  expectedData: Data,
  expectedPassport: LiveGitCandidatePassport
) throws {
  guard stored == expectedData else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Existing candidate passport differs from the deterministic result."
    )
  }
  try CanonicalMemoryJSON.requireCanonical(stored)
  let decoded = try JSONDecoder().decode(LiveGitCandidatePassport.self, from: stored)
  guard decoded == expectedPassport else {
    throw LiveGitCandidateRuntimeError.persistence(
      "Existing candidate passport does not decode to the deterministic result."
    )
  }
}

private func fileStatus(_ url: URL) throws -> stat? {
  var information = stat()
  let result = url.withUnsafeFileSystemRepresentation { path -> Int32 in
    guard let path else { return -1 }
    return Darwin.lstat(path, &information)
  }
  if result == 0 { return information }
  if errno == ENOENT { return nil }
  throw LiveGitCandidateRuntimeError.persistence(
    "lstat failed for \(url.path) with errno \(errno)."
  )
}

private func isDirectory(_ status: stat) -> Bool {
  (status.st_mode & S_IFMT) == S_IFDIR
}

private func isRegularFile(_ status: stat) -> Bool {
  (status.st_mode & S_IFMT) == S_IFREG
}

private func isSymbolicLink(_ status: stat) -> Bool {
  (status.st_mode & S_IFMT) == S_IFLNK
}
