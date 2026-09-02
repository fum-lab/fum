import Darwin
import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveGitCandidateRuntimeTests: XCTestCase {
  func testEpisodePolicyRejectsTwoCandidateActions() throws {
    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      XCTAssertThrowsError(
        try fixture.createConfirmedEpisodeCurrent(
          for: prepared,
          duplicateCandidateAction: true
        )
      ) { error in
        guard case .invalidPassport(let message) = error as? LiveEpisodeError else {
          return XCTFail("Expected two-action passport rejection, got \(error).")
        }
        XCTAssertTrue(message.contains("create_candidate_commit"))
      }
      XCTAssertNil(
        try LiveEpisodeGenerationStore(rootURL: fixture.episodeURL).loadCurrent()
      )
    }
  }

  func testEpisodeRuntimeCandidatePassesIndependentAcceptanceAndRetryExactly() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let planned = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate through episode runtime\n")]
      )
      let episode = try fixture.createConfirmedEpisodeCurrent(for: planned)
      let prepared = episode.prepared

      XCTAssertEqual(
        episode.stored.state.passport.actionAllowlist,
        [episode.allowance]
      )
      XCTAssertEqual(
        episode.allowance.candidateCommitPolicy,
        prepared.plan.policy
      )
      XCTAssertEqual(
        episode.selectedIntent.argumentsSHA256,
        try prepared.plan.canonicalSHA256()
      )
      XCTAssertEqual(
        episode.selectedIntent.expectedEffectSHA256,
        prepared.coordinates.expectedEffectSHA256
      )

      let admission = LiveGitCandidateAdmissionRuntime(
        episodeDirectoryURL: fixture.episodeURL
      )
      let userConfirmation = LiveGitCandidateUserConfirmationCommand(
        commandID: "command-runtime-user-confirmation",
        expectedGenerationSHA256: episode.stored.generationSHA256,
        eventID: "event-runtime-user-confirmed",
        receiptID: "receipt-runtime-user-confirmed",
        generationConfirmationEventID: "event-confirm-runtime-user",
        evidence: evidence("evidence-runtime-user", "trusted-user-channel")
      )
      let userConfirmed = try admission.recordUserConfirmation(userConfirmation)
      XCTAssertEqual(userConfirmed.status, .advanced)
      XCTAssertEqual(userConfirmed.state.transition?.phase, .transitionUserConfirmed)

      let authorization = LiveGitCandidateAuthorizationCommand(
        commandID: "command-runtime-authorization",
        expectedGenerationSHA256: userConfirmed.generationSHA256,
        eventID: "event-runtime-authorized",
        receiptID: "receipt-runtime-authorized",
        generationConfirmationEventID: "event-confirm-runtime-authorization",
        evidence: evidence("evidence-runtime-authorization", "trusted-authorizer")
      )
      let authorized = try admission.authorizeSelectedIntent(authorization)
      XCTAssertEqual(authorized.status, .advanced)
      XCTAssertEqual(authorized.state.transition?.phase, .authorized)
      XCTAssertEqual(
        authorized.state.transition?.authorization?.intentID,
        episode.selectedIntent.intentID
      )

      let command = LiveGitCandidateEpisodeCommand(
        commandID: "command-runtime-create-candidate",
        expectedGenerationSHA256: authorized.generationSHA256,
        preflightConfirmationEventID: "event-confirm-runtime-preflight",
        observationConfirmationEventID: "event-confirm-runtime-observation",
        plan: prepared.plan
      )
      let runtime = LiveGitCandidateEpisodeRuntime(
        episodeDirectoryURL: fixture.episodeURL,
        sourceCheckoutURL: fixture.sourceURL
      )
      let output = try runtime.createCandidateCommit(command)
      XCTAssertEqual(output.status, .advanced)
      XCTAssertEqual(output.candidateOID, prepared.plan.policy.expectedCandidateOID)

      let final = try XCTUnwrap(
        LiveEpisodeGenerationStore(rootURL: fixture.episodeURL).loadCurrent()
      )
      let journal = try XCTUnwrap(final.generation.candidateReceiptJournal)
      XCTAssertEqual(journal.receipts.map(\.stage), LiveGitCandidateStage.allCases)
      XCTAssertEqual(
        journal.receipts.map(\.receiptID),
        [
          userConfirmation.receiptID,
          authorization.receiptID,
          prepared.plan.preflightReceiptID,
          prepared.plan.executionReceiptID,
          prepared.plan.observationReceiptID,
        ]
      )
      XCTAssertEqual(journal.executionCommandSHA256, try command.canonicalSHA256())
      XCTAssertEqual(
        journal.observationConfirmationEventID,
        command.observationConfirmationEventID
      )
      XCTAssertEqual(
        journal.receipts[3].evidence.evidenceSHA256,
        LiveStrictIntentParser.sha256(of: output.candidateOID)
      )
      XCTAssertEqual(journal.receipts[4].evidence.evidenceID, prepared.plan.observationReceiptID)
      XCTAssertEqual(journal.receipts[4].evidence.evidenceSHA256, output.passportSHA256)
      XCTAssertEqual(
        try IsolatedGitCandidateAdapter().candidatePassportSHA256(
          episodeDirectoryURL: fixture.episodeURL,
          candidateOID: output.candidateOID
        ),
        output.passportSHA256
      )

      let acceptance = try LiveGitCandidateAcceptanceRuntime(
        episodeDirectoryURL: fixture.episodeURL
      ).evaluate(
        LiveGitCandidateAcceptanceCommand(
          commandID: "command-accept-runtime-candidate",
          candidateOID: output.candidateOID
        )
      )
      XCTAssertEqual(acceptance.verdict, .accepted)
      XCTAssertEqual(acceptance.candidateOID, output.candidateOID)

      let events = final.generation.eventJournal.events
      for (stageEventID, confirmationEventID) in [
        (userConfirmation.eventID, userConfirmation.generationConfirmationEventID),
        (authorization.eventID, authorization.generationConfirmationEventID),
        (prepared.plan.preflightEventID, command.preflightConfirmationEventID),
        (prepared.plan.observationEventID, command.observationConfirmationEventID),
      ] {
        let stageIndex = try XCTUnwrap(events.firstIndex(where: { $0.eventID == stageEventID }))
        let confirmationIndex = try XCTUnwrap(
          events.firstIndex(where: { $0.eventID == confirmationEventID })
        )
        XCTAssertEqual(confirmationIndex, stageIndex + 1)
        guard case .generationConfirmed(let confirmation) = events[confirmationIndex].payload else {
          return XCTFail("Expected a separate generation confirmation after \(stageEventID).")
        }
        XCTAssertEqual(confirmation.confirmedThroughSequence, events[stageIndex].sequence)
      }

      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
      let retry = try runtime.createCandidateCommit(command)
      XCTAssertEqual(retry.status, .alreadyApplied)
      XCTAssertEqual(retry.generationSHA256, final.generationSHA256)
      XCTAssertEqual(retry.candidateOID, output.candidateOID)
      XCTAssertEqual(retry.passportSHA256, output.passportSHA256)

      let substituted = LiveGitCandidateEpisodeCommand(
        commandID: "command-runtime-substituted-candidate",
        expectedGenerationSHA256: command.expectedGenerationSHA256,
        preflightConfirmationEventID: command.preflightConfirmationEventID,
        observationConfirmationEventID: command.observationConfirmationEventID,
        plan: command.plan
      )
      XCTAssertThrowsError(try runtime.createCandidateCommit(substituted)) { error in
        guard case .invalidEvidence = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected command-substitution rejection, got \(error).")
        }
      }
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: fixture.episodeURL).loadCurrent()?
          .generationSHA256,
        final.generationSHA256
      )
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testConfirmedPreflightCreatesDeterministicCandidateWithoutMutatingSource() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let sourceMetadataBefore = try fixture.sourceGitMetadataSnapshot()
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let authorization = try fixture.authorizationPrefix(prepared)
      let adapter = IsolatedGitCandidateAdapter()
      let preflight = try adapter.preflight(
        fixture.preflightRequest(prepared, prefix: authorization)
      )
      let confirmed = try fixture.appendingPreflight(
        to: authorization,
        prepared: prepared,
        result: preflight
      )
      let result = try adapter.createCandidateCommit(
        fixture.executionRequest(prepared, prefix: confirmed)
      )
      let observed = try adapter.observeCandidateCommit(
        LiveGitCandidateObservationRequest(
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan,
          candidateOID: result.candidateOID,
          expectedPassportSHA256: result.passportSHA256
        )
      )

      XCTAssertEqual(result.passport.parentOID, fixture.baseOID)
      XCTAssertEqual(result.passport.candidateOID, result.candidateOID)
      XCTAssertEqual(result.passport.changedPaths, ["README.md"])
      XCTAssertEqual(result.passport.checkerObservations.map(\.status), [.passed])
      XCTAssertEqual(observed.observationEvidence.evidenceSHA256, result.passportSHA256)
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
      XCTAssertEqual(try fixture.sourceGitMetadataSnapshot(), sourceMetadataBefore)
      XCTAssertFalse(fixture.cloneURL.path.hasPrefix(fixture.sourceURL.path + "/"))
      XCTAssertEqual(
        try fixture.git(["show", "\(result.candidateOID):README.md"], at: fixture.cloneURL),
        Data("candidate\n".utf8)
      )
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: result.candidateOID)
      )
      XCTAssertEqual(try Data(contentsOf: passportURL), result.passportCanonicalJSON)
      XCTAssertNoThrow(try result.passport.validate())
      XCTAssertEqual(
        try LiveGitCheckerRegistry().verify(
          passport: result.passport,
          episodeDirectoryURL: fixture.episodeURL
        ),
        result.passport.checkerObservations
      )
    }
  }

  func testRejectsAbsoluteTraversalAndSymlinkEscape() throws {
    try withGitCandidateFixture { fixture in
      for path in ["/absolute.txt", "../escape.txt", "safe/../escape.txt"] {
        XCTAssertThrowsError(
          try IsolatedGitCandidateAdapter().createValidatedCandidate(
            sourceCheckoutURL: fixture.sourceURL,
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: fixture.unsafeCoordinates,
            plan: fixture.unsafePlan(path: path)
          )
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.cloneURL.path))
      }

      let mainBranch = try fixture.replacingCandidateBranch(
        in: fixture.preparedPlan(
          writes: [fixture.write("README.md", "candidate\n")]
        ),
        with: "refs/heads/master"
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: mainBranch.coordinates,
          plan: mainBranch.plan
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.cloneURL.path))

      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("escape/file.txt", "candidate\n")]
      )
      let outsideURL = fixture.rootURL.appendingPathComponent("outside", isDirectory: true)
      try FileManager.default.createDirectory(at: outsideURL, withIntermediateDirectories: false)
      let adapter = IsolatedGitCandidateAdapter(
        checkpointObserver: { checkpoint, cloneURL, _ in
          guard checkpoint == .clonePrepared else { return }
          try FileManager.default.createSymbolicLink(
            at: cloneURL.appendingPathComponent("escape"),
            withDestinationURL: outsideURL
          )
        }
      )
      XCTAssertThrowsError(
        try adapter.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        XCTAssertTrue(error is LiveGitCandidateRuntimeError)
      }
      XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: outsideURL.path), [])
    }
  }

  func testRejectsUnexpectedIndexedDiffAndCheckerFailure() throws {
    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let adapter = IsolatedGitCandidateAdapter(
        checkpointObserver: { checkpoint, cloneURL, _ in
          guard checkpoint == .writesStaged else { return }
          let path = cloneURL.appendingPathComponent("UNEXPECTED.txt")
          try Data("unexpected\n".utf8).write(to: path)
          let blob = try fixture.gitString(
            ["hash-object", "-w", "--stdin"],
            at: cloneURL,
            input: Data("unexpected\n".utf8)
          )
          try fixture.git(
            ["update-index", "--add", "--cacheinfo", "100644", blob, "UNEXPECTED.txt"],
            at: cloneURL
          )
        }
      )
      XCTAssertThrowsError(
        try adapter.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        guard case .invalidPlan = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected exact-tree rejection, got \(error).")
        }
      }
    }

    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "trailing whitespace  \n")]
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        guard case .checkerFailed = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected registered checker failure, got \(error).")
        }
      }
    }
  }

  func testUnknownCheckerIDFailsClosedWithoutPublishing() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let sourceMetadataBefore = try fixture.sourceGitMetadataSnapshot()
      let original = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let prepared = try fixture.replacingCheckers(
        in: original,
        with: [
          LiveGitCandidateCheckerSpec(
            checkerID: "checker-unknown",
            argvGrammar: .gitDiffCheckV1
          )
        ]
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        guard case .checkerFailed(let message) = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected unknown-checker rejection, got \(error).")
        }
        XCTAssertTrue(message.contains("is not registered"))
      }
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(
          candidateOID: prepared.plan.policy.expectedCandidateOID
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: passportURL.path))
      XCTAssertThrowsError(
        try fixture.git(
          ["show-ref", "--verify", prepared.plan.policy.resultRef],
          at: fixture.cloneURL
        )
      )
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
      XCTAssertEqual(try fixture.sourceGitMetadataSnapshot(), sourceMetadataBefore)
    }
  }

  func testRegisteredCheckerIDRejectsMismatchedPersistedGrammar() throws {
    let registry = LiveGitCheckerRegistry()
    XCTAssertNoThrow(
      try registry.validateRegistration(
        checkerID: "checker-git-diff",
        persistedArgvGrammar: LiveGitCandidateCheckerArgvGrammar.gitDiffCheckV1.rawValue
      )
    )
    XCTAssertThrowsError(
      try registry.validateRegistration(
        checkerID: "checker-git-diff",
        persistedArgvGrammar: "git_diff_check_v2"
      )
    ) { error in
      guard case .checkerFailed(let message) = error as? LiveGitCandidateRuntimeError else {
        return XCTFail("Expected checker ID/grammar mismatch rejection, got \(error).")
      }
      XCTAssertTrue(message.contains("does not match"))
    }
  }

  func testRejectsChangedBaseCrossTransitionAndFalseModelConfirmation() throws {
    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      try fixture.advanceSourceHead()
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        guard case .sourceBaseChanged = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected changed-base rejection, got \(error).")
        }
      }
    }

    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let authorization = try fixture.authorizationPrefix(prepared)
      let forgedIntent = LiveUntrustedActionIntent(
        intentID: authorization.intent.intentID,
        operation: authorization.intent.operation,
        adapterID: authorization.intent.adapterID,
        effectClass: authorization.intent.effectClass,
        objectID: authorization.intent.objectID,
        expectedEffectSHA256: authorization.intent.expectedEffectSHA256,
        argumentsSHA256: fixtureHash("model-only-claim")
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().preflight(
          LiveGitCandidatePreflightRequest(
            sourceCheckoutURL: fixture.sourceURL,
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan,
            selectedIntent: forgedIntent,
            allowance: authorization.allowance,
            confirmedAuthorizationReceipts: authorization.receipts,
            confirmedAuthorizationEvents: authorization.events
          )
        )
      )

      let preflight = try IsolatedGitCandidateAdapter().preflight(
        fixture.preflightRequest(prepared, prefix: authorization)
      )
      var confirmed = try fixture.appendingPreflight(
        to: authorization,
        prepared: prepared,
        result: preflight
      )
      let valid = confirmed.receipts[2]
      confirmed.receipts[2] = LiveGitCandidateStageReceipt(
        receiptID: valid.receiptID,
        eventID: valid.eventID,
        stage: valid.stage,
        coordinates: LiveTransitionCoordinates(
          episodeID: prepared.coordinates.episodeID,
          transitionID: "cross-transition",
          objectID: prepared.coordinates.objectID,
          expectedEffectSHA256: prepared.coordinates.expectedEffectSHA256
        ),
        evidence: valid.evidence,
        producerID: valid.producerID,
        predecessor: valid.predecessor
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createCandidateCommit(
          fixture.executionRequest(prepared, prefix: confirmed)
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.cloneURL.path))
    }
  }

  func testCrashAfterCASRetriesIdempotentlyAndConflictingOIDClosesContinuation() throws {
    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let crashing = IsolatedGitCandidateAdapter(
        checkpointObserver: { checkpoint, _, _ in
          if checkpoint == .resultRefPublished { throw SyntheticCrash.afterResultRefCAS }
        }
      )
      XCTAssertThrowsError(
        try crashing.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        XCTAssertEqual(error as? SyntheticCrash, .afterResultRefCAS)
      }
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(
          candidateOID: prepared.plan.policy.expectedCandidateOID
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: passportURL.path))

      let recovered = try IsolatedGitCandidateAdapter().createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      XCTAssertEqual(recovered.candidateOID, prepared.plan.policy.expectedCandidateOID)
      XCTAssertTrue(FileManager.default.fileExists(atPath: passportURL.path))

      try fixture.git(
        ["update-ref", prepared.plan.policy.resultRef, fixture.baseOID],
        at: fixture.cloneURL
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().observeCandidateCommit(
          LiveGitCandidateObservationRequest(
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan,
            candidateOID: recovered.candidateOID,
            expectedPassportSHA256: recovered.passportSHA256
          )
        )
      ) { error in
        guard case .candidateConflict = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Expected conflicting result-ref OID, got \(error).")
        }
      }
    }
  }

  func testCrashBeforePassportTemporaryUnlinkRetriesIdempotently() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let adapter = IsolatedGitCandidateAdapter()
      let result = try adapter.createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: result.candidateOID)
      )
      let temporaryURL = passportURL.deletingLastPathComponent().appendingPathComponent(
        ".passport-00000000-0000-4000-8000-000000000001.tmp"
      )

      XCTAssertEqual(Darwin.link(passportURL.path, temporaryURL.path), 0)
      var linkedInformation = stat()
      XCTAssertEqual(Darwin.lstat(passportURL.path, &linkedInformation), 0)
      XCTAssertEqual(Int(linkedInformation.st_nlink), 2)

      let recovered = try adapter.createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      XCTAssertEqual(recovered.passportCanonicalJSON, result.passportCanonicalJSON)
      XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryURL.path))
      var recoveredInformation = stat()
      XCTAssertEqual(Darwin.lstat(passportURL.path, &recoveredInformation), 0)
      XCTAssertEqual(Int(recoveredInformation.st_nlink), 1)
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testPassportRecoveryRejectsForeignAndAmbiguousAliases() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let adapter = IsolatedGitCandidateAdapter()
      let result = try adapter.createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: result.candidateOID)
      )
      let directoryURL = passportURL.deletingLastPathComponent()
      let foreignAliasURL = directoryURL.appendingPathComponent("foreign-passport.tmp")
      XCTAssertEqual(Darwin.link(passportURL.path, foreignAliasURL.path), 0)
      XCTAssertThrowsError(
        try adapter.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      )
      XCTAssertTrue(FileManager.default.fileExists(atPath: foreignAliasURL.path))
      XCTAssertEqual(Darwin.unlink(foreignAliasURL.path), 0)

      let ownAliasURL = directoryURL.appendingPathComponent(
        ".passport-00000000-0000-4000-8000-000000000002.tmp"
      )
      let ambiguousURL = directoryURL.appendingPathComponent(
        ".passport-00000000-0000-4000-8000-000000000003.tmp"
      )
      XCTAssertEqual(Darwin.link(passportURL.path, ownAliasURL.path), 0)
      XCTAssertTrue(FileManager.default.createFile(atPath: ambiguousURL.path, contents: Data()))
      XCTAssertEqual(Darwin.chmod(ambiguousURL.path, 0o444), 0)
      XCTAssertThrowsError(
        try adapter.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      )
      XCTAssertTrue(FileManager.default.fileExists(atPath: ownAliasURL.path))
      XCTAssertTrue(FileManager.default.fileExists(atPath: ambiguousURL.path))
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testRejectsSymbolicRefsDuringRecoveryAndObservationWithoutMutatingSource() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let crashing = IsolatedGitCandidateAdapter(
        checkpointObserver: { checkpoint, _, _ in
          if checkpoint == .resultRefPublished { throw SyntheticCrash.afterResultRefCAS }
        }
      )
      XCTAssertThrowsError(
        try crashing.createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      ) { error in
        XCTAssertEqual(error as? SyntheticCrash, .afterResultRefCAS)
      }

      try fixture.git(
        [
          "symbolic-ref", prepared.plan.policy.resultRef,
          prepared.plan.policy.candidateBranch,
        ],
        at: fixture.cloneURL
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      )
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(
          candidateOID: prepared.plan.policy.expectedCandidateOID
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: passportURL.path))
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)

      try fixture.git(
        [
          "update-ref", "--no-deref", prepared.plan.policy.resultRef,
          prepared.plan.policy.expectedCandidateOID,
        ],
        at: fixture.cloneURL
      )
      let recovered = try IsolatedGitCandidateAdapter().createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      try fixture.git(
        [
          "symbolic-ref", prepared.plan.policy.candidateBranch,
          prepared.plan.policy.resultRef,
        ],
        at: fixture.cloneURL
      )
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().observeCandidateCommit(
          LiveGitCandidateObservationRequest(
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan,
            candidateOID: recovered.candidateOID,
            expectedPassportSHA256: recovered.passportSHA256
          )
        )
      )
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testRejectsNestedMetadataAliasesBeforeWritingSourceGitMetadata() throws {
    for relativePath in ["objects/__OBJECT_FANOUT__", "refs/heads"] {
      try withGitCandidateFixture { fixture in
        let prepared = try fixture.preparedPlan(
          writes: [fixture.write("README.md", "candidate\n")]
        )
        let initializing = IsolatedGitCandidateAdapter(
          checkpointObserver: { checkpoint, _, _ in
            if checkpoint == .clonePrepared { throw SyntheticCrash.afterClonePrepared }
          }
        )
        XCTAssertThrowsError(
          try initializing.createValidatedCandidate(
            sourceCheckoutURL: fixture.sourceURL,
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan
          )
        ) { error in
          XCTAssertEqual(error as? SyntheticCrash, .afterClonePrepared)
        }

        let exactRelativePath = relativePath.replacingOccurrences(
          of: "__OBJECT_FANOUT__",
          with: String(fixture.baseOID.prefix(2))
        )
        let sourceMarkerURL = fixture.sourceURL.appendingPathComponent(
          ".git/fum-source-metadata-marker"
        )
        try Data("source metadata must stay exact\n".utf8).write(to: sourceMarkerURL)
        let sourceMetadataBefore = try fixture.sourceGitMetadataSnapshot()
        let sourceMetadataURL = fixture.sourceURL.appendingPathComponent(
          ".git/\(exactRelativePath)",
          isDirectory: true
        )
        let cloneMetadataURL = fixture.cloneURL.appendingPathComponent(
          ".git/\(exactRelativePath)",
          isDirectory: true
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceMetadataURL.path))
        if FileManager.default.fileExists(atPath: cloneMetadataURL.path) {
          try FileManager.default.removeItem(at: cloneMetadataURL)
        }
        try FileManager.default.createSymbolicLink(
          at: cloneMetadataURL,
          withDestinationURL: sourceMetadataURL
        )

        XCTAssertThrowsError(
          try IsolatedGitCandidateAdapter().createValidatedCandidate(
            sourceCheckoutURL: fixture.sourceURL,
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan
          )
        )
        XCTAssertEqual(try fixture.sourceGitMetadataSnapshot(), sourceMetadataBefore)
      }
    }
  }

  func testRepositoryLocalExecutionConfigurationCannotRun() throws {
    try withGitCandidateFixture { fixture in
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let markerURL = fixture.rootURL.appendingPathComponent("hostile-config-ran")
      let scriptURL = fixture.rootURL.appendingPathComponent("hostile-config-command")
      try Data(
        "#!/bin/sh\n/usr/bin/touch '\(markerURL.path)'\nexit 97\n".utf8
      ).write(to: scriptURL)
      XCTAssertEqual(chmod(scriptURL.path, 0o755), 0)
      try fixture.git(
        ["config", "uploadpack.packObjectsHook", scriptURL.path],
        at: fixture.sourceURL
      )
      let sourceBefore = try fixture.sourceSnapshot()
      let adapter = IsolatedGitCandidateAdapter(
        checkpointObserver: { checkpoint, cloneURL, _ in
          guard checkpoint == .clonePrepared else { return }
          for (key, value) in [
            ("core.fsmonitor", scriptURL.path),
            ("core.hooksPath", scriptURL.path),
            ("diff.external", scriptURL.path),
            ("diff.hostile.command", scriptURL.path),
            ("diff.hostile.textconv", scriptURL.path),
            ("filter.hostile.clean", scriptURL.path),
            ("filter.hostile.smudge", scriptURL.path),
            ("filter.hostile.process", scriptURL.path),
          ] {
            try fixture.git(["config", key, value], at: cloneURL)
          }
          try Data("README.md diff=hostile filter=hostile\n".utf8).write(
            to: cloneURL.appendingPathComponent(".git/info/attributes")
          )
        }
      )
      let result = try adapter.createValidatedCandidate(
        sourceCheckoutURL: fixture.sourceURL,
        episodeDirectoryURL: fixture.episodeURL,
        coordinates: prepared.coordinates,
        plan: prepared.plan
      )
      XCTAssertNoThrow(
        try adapter.observeCandidateCommit(
          LiveGitCandidateObservationRequest(
            episodeDirectoryURL: fixture.episodeURL,
            coordinates: prepared.coordinates,
            plan: prepared.plan,
            candidateOID: result.candidateOID,
            expectedPassportSHA256: result.passportSHA256
          )
        )
      )
      XCTAssertFalse(FileManager.default.fileExists(atPath: markerURL.path))
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testPassportFIFOIsRejectedWithoutBlockingOrMutatingSource() throws {
    try withGitCandidateFixture { fixture in
      let sourceBefore = try fixture.sourceSnapshot()
      let passportURL = fixture.episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: fixture.baseOID)
      )
      try FileManager.default.createDirectory(
        at: passportURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      XCTAssertEqual(mkfifo(passportURL.path, 0o600), 0)
      XCTAssertThrowsError(
        try IsolatedGitCandidateAdapter().candidatePassportSHA256(
          episodeDirectoryURL: fixture.episodeURL,
          candidateOID: fixture.baseOID
        )
      )
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testHostileGitEnvironmentIsIgnoredAndFixtureRemovesScratchRepository() throws {
    var removedRoot: URL?
    try withGitCandidateFixture { fixture in
      removedRoot = fixture.rootURL
      let prepared = try fixture.preparedPlan(
        writes: [fixture.write("README.md", "candidate\n")]
      )
      let hostileURL = fixture.rootURL.appendingPathComponent("hostile")
      XCTAssertThrowsError(
        try LiveGitProcessRunner().run(
          ["status", "--porcelain=v1"],
          at: fixture.sourceURL,
          additionalEnvironment: ["GIT_DIR": hostileURL.path]
        )
      )
      XCTAssertEqual(setenv("GIT_DIR", hostileURL.path, 1), 0)
      XCTAssertEqual(setenv("GIT_INDEX_FILE", hostileURL.path, 1), 0)
      XCTAssertEqual(setenv("GIT_NO_LAZY_FETCH", "0", 1), 0)
      XCTAssertEqual(setenv("GIT_OBJECT_DIRECTORY", hostileURL.path, 1), 0)
      defer {
        unsetenv("GIT_DIR")
        unsetenv("GIT_INDEX_FILE")
        unsetenv("GIT_NO_LAZY_FETCH")
        unsetenv("GIT_OBJECT_DIRECTORY")
      }
      XCTAssertNoThrow(
        try IsolatedGitCandidateAdapter().createValidatedCandidate(
          sourceCheckoutURL: fixture.sourceURL,
          episodeDirectoryURL: fixture.episodeURL,
          coordinates: prepared.coordinates,
          plan: prepared.plan
        )
      )
    }
    XCTAssertNotNil(removedRoot)
    XCTAssertFalse(FileManager.default.fileExists(atPath: try XCTUnwrap(removedRoot).path))
  }
}

private enum SyntheticCrash: Error, Equatable {
  case afterClonePrepared
  case afterResultRefCAS
}

private struct PreparedCandidate {
  let plan: LiveGitCandidatePlan
  let coordinates: LiveTransitionCoordinates
}

private struct PreparedEpisodeCandidate {
  let prepared: PreparedCandidate
  let stored: StoredLiveEpisodeGeneration
  let allowance: LiveAllowedAction
  let selectedIntent: LiveUntrustedActionIntent
}

private struct CandidatePrefix {
  var receipts: [LiveGitCandidateStageReceipt]
  var events: [LiveEpisodeEvent]
  let intent: LiveUntrustedActionIntent
  let allowance: LiveAllowedAction
}

private struct GitCandidateFixture {
  let rootURL: URL
  let sourceURL: URL
  let episodeURL: URL
  let cloneURL: URL
  let baseOID: String

  var unsafeCoordinates: LiveTransitionCoordinates {
    LiveTransitionCoordinates(
      episodeID: "episode-git-candidate",
      transitionID: "transition-git-candidate",
      objectID: "object-git-candidate",
      expectedEffectSHA256: fixtureHash("unsafe-plan")
    )
  }

  func write(_ path: String, _ string: String) -> LiveGitRegularFileWrite {
    LiveGitRegularFileWrite(path: path, mode: .regular, contents: Data(string.utf8))
  }

  func unsafePlan(path: String) -> LiveGitCandidatePlan {
    LiveGitCandidatePlan(
      policy: policy(
        allowedPaths: [path],
        expectedTreeOID: baseOID,
        expectedCandidateOID: baseOID
      ),
      writes: [write(path, "unsafe\n")],
      preflightEventID: "event-git-preflight",
      preflightReceiptID: "receipt-git-preflight",
      executionEventID: "event-git-execution",
      executionReceiptID: "receipt-git-execution",
      observationEventID: "event-git-observation",
      observationReceiptID: "receipt-git-observation"
    )
  }

  func preparedPlan(writes: [LiveGitRegularFileWrite]) throws -> PreparedCandidate {
    let writes = writes.sorted { $0.path < $1.path }
    let planningURL = rootURL.appendingPathComponent(
      "planning-\(UUID().uuidString)",
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: planningURL) }
    try git(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--", sourceURL.path,
        planningURL.path,
      ],
      at: rootURL
    )
    try git(["checkout", "--detach", "--force", baseOID], at: planningURL)
    for write in writes {
      let target = planningURL.appendingPathComponent(write.path)
      try FileManager.default.createDirectory(
        at: target.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let contents = try XCTUnwrap(write.contents)
      try contents.write(to: target)
      XCTAssertEqual(chmod(target.path, write.mode == .regular ? 0o644 : 0o755), 0)
      let blob = try gitString(["hash-object", "-w", "--stdin"], at: planningURL, input: contents)
      try git(
        ["update-index", "--add", "--cacheinfo", write.mode.rawValue, blob, write.path],
        at: planningURL
      )
    }
    let tree = try gitString(["write-tree"], at: planningURL)
    let candidate = try commitTree(
      tree: tree,
      parent: baseOID,
      message: candidateMessage,
      at: planningURL,
      author: candidateSignature,
      committer: candidateSignature
    )
    let plan = LiveGitCandidatePlan(
      policy: policy(
        allowedPaths: writes.map(\.path),
        expectedTreeOID: tree,
        expectedCandidateOID: candidate
      ),
      writes: writes,
      preflightEventID: "event-git-preflight",
      preflightReceiptID: "receipt-git-preflight",
      executionEventID: "event-git-execution",
      executionReceiptID: "receipt-git-execution",
      observationEventID: "event-git-observation",
      observationReceiptID: "receipt-git-observation"
    )
    let digest = try plan.canonicalSHA256()
    return PreparedCandidate(
      plan: plan,
      coordinates: LiveTransitionCoordinates(
        episodeID: "episode-git-candidate",
        transitionID: "transition-git-candidate",
        objectID: "object-git-candidate",
        expectedEffectSHA256: digest
      )
    )
  }

  func createConfirmedEpisodeCurrent(
    for planned: PreparedCandidate,
    duplicateCandidateAction: Bool = false
  ) throws -> PreparedEpisodeCandidate {
    let source = try LiveEpisodeFixture.run()
    let selectionIndex = try XCTUnwrap(
      source.events.firstIndex(where: { $0.kind == .modelSelectionRecorded })
    )
    let sourceEvents = Array(source.events.prefix(through: selectionIndex))
    let coordinates = LiveTransitionCoordinates(
      episodeID: source.passport.episodeID,
      transitionID: planned.coordinates.transitionID,
      objectID: planned.coordinates.objectID,
      expectedEffectSHA256: planned.coordinates.expectedEffectSHA256
    )
    let prepared = PreparedCandidate(plan: planned.plan, coordinates: coordinates)
    let allowance = LiveAllowedAction(
      allowanceID: "allow-git-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated-git-write",
      candidateCommitPolicy: prepared.plan.policy
    )
    let actionAllowlist =
      duplicateCandidateAction
      ? [
        allowance,
        LiveAllowedAction(
          allowanceID: "allow-git-candidate-duplicate",
          operation: LiveGitCandidateContract.operation,
          adapterID: "fum-git-candidate-v1",
          effectClass: "isolated-git-write",
          candidateCommitPolicy: prepared.plan.policy
        ),
      ] : [allowance]
    let passport = LiveEpisodePassport(
      schemaIdentity: source.passport.schemaIdentity,
      schemaVersion: source.passport.schemaVersion,
      episodeID: source.passport.episodeID,
      goal: source.passport.goal,
      context: source.passport.context,
      modelPolicy: source.passport.modelPolicy,
      actionAllowlist: actionAllowlist,
      verificationCriteria: source.passport.verificationCriteria,
      checkpointPolicy: source.passport.checkpointPolicy,
      terminalOutcomes: source.passport.terminalOutcomes
    )
    _ = try LiveEpisodeReducer.initialState(passport: passport)

    var intentsByVariant: [String: LiveUntrustedActionIntent] = [:]
    for event in sourceEvents {
      guard case .untrustedIntentParsed(let parsed) = event.payload else { continue }
      intentsByVariant[parsed.variantID] = LiveUntrustedActionIntent(
        intentID: parsed.intent.intentID,
        operation: allowance.operation,
        adapterID: allowance.adapterID,
        effectClass: allowance.effectClass,
        objectID: coordinates.objectID,
        expectedEffectSHA256: coordinates.expectedEffectSHA256,
        argumentsSHA256: coordinates.expectedEffectSHA256
      )
    }

    let events = try sourceEvents.map { event -> LiveEpisodeEvent in
      let payload: LiveEpisodeEventPayload
      switch event.payload {
      case .pendingTransitionDeclared(let declaration):
        payload = .pendingTransitionDeclared(
          LivePendingTransitionDeclared(
            coordinates: coordinates,
            allowanceID: allowance.allowanceID,
            parentCheckpointID: declaration.parentCheckpointID
          )
        )
      case .modelResponseRecorded(let response):
        let intent = try XCTUnwrap(intentsByVariant[response.variantID])
        let output = try LiveStrictIntentParser.canonicalOutput(for: intent)
        payload = .modelResponseRecorded(
          LiveModelResponseRecorded(
            responseID: response.responseID,
            requestID: response.requestID,
            variantID: response.variantID,
            providerIdentity: response.providerIdentity,
            status: response.status,
            output: output,
            outputSHA256: LiveStrictIntentParser.sha256(of: output),
            charged: response.charged
          )
        )
      case .untrustedIntentParsed(let parsed):
        payload = .untrustedIntentParsed(
          LiveUntrustedIntentParsed(
            variantID: parsed.variantID,
            sourceResponseID: parsed.sourceResponseID,
            intent: try XCTUnwrap(intentsByVariant[parsed.variantID])
          )
        )
      default:
        payload = event.payload
      }
      return LiveEpisodeEvent(
        schemaIdentity: event.schemaIdentity,
        schemaVersion: event.schemaVersion,
        episodeID: passport.episodeID,
        eventID: event.eventID,
        sequence: event.sequence,
        payload: payload
      )
    }
    let invocations = try episodeInvocationReceipts(for: events)
    let store = LiveEpisodeGenerationStore(rootURL: episodeURL)
    let initial = try store.commit(
      passport: passport,
      events: events,
      invocations: invocations,
      candidateReceipts: [],
      candidateExecutionCommandSHA256: nil,
      expectedPreviousGenerationSHA256: nil
    )
    let confirmationEvent = LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: "event-confirm-runtime-initial-current",
      sequence: initial.state.nextSequence,
      payload: .generationConfirmed(
        LiveGenerationConfirmed(
          generationID: String(initial.generationSHA256.dropFirst(7)),
          confirmedThroughSequence: initial.state.nextSequence - 1,
          stateSHA256: initial.generation.stateSHA256
        )
      )
    )
    let stored = try store.commit(
      passport: passport,
      events: events + [confirmationEvent],
      invocations: invocations,
      candidateReceipts: [],
      candidateExecutionCommandSHA256: nil,
      expectedPreviousGenerationSHA256: initial.generationSHA256
    )
    let selection = try XCTUnwrap(stored.state.model.selection)
    let selectedVariant = try XCTUnwrap(
      stored.state.model.variants.first(where: {
        $0.proposal.variantID == selection.selectedVariantID
      })
    )
    return PreparedEpisodeCandidate(
      prepared: prepared,
      stored: stored,
      allowance: allowance,
      selectedIntent: try XCTUnwrap(selectedVariant.intent?.intent)
    )
  }

  private func episodeInvocationReceipts(
    for events: [LiveEpisodeEvent]
  ) throws -> [LiveEpisodeInvocationReceipt] {
    var receipts: [LiveEpisodeInvocationReceipt] = []
    for event in events {
      switch event.payload {
      case .modelRequestRecorded(let request):
        let match = try XCTUnwrap(
          events.compactMap { candidate -> (LiveEpisodeEvent, LiveModelResponseRecorded)? in
            guard case .modelResponseRecorded(let response) = candidate.payload,
              response.requestID == request.proposal.requestID
            else { return nil }
            return (candidate, response)
          }.first
        )
        receipts.append(
          LiveEpisodeInvocationReceipt(
            requestEventID: event.eventID,
            responseEventID: match.0.eventID,
            responseID: match.1.responseID,
            budgetCheckpointEventID: "unused-budget-\(request.proposal.requestID)",
            budgetCheckpointID: "unused-budget-\(request.proposal.requestID)",
            proposal: request.proposal,
            commandSHA256: fixtureHash("command-\(request.proposal.requestID)")
          )
        )
      case .budgetCheckpointCreated(let checkpoint):
        receipts.append(
          LiveEpisodeInvocationReceipt(
            requestEventID: "unused-request-\(checkpoint.proposal.requestID)",
            responseEventID: "unused-response-event-\(checkpoint.proposal.requestID)",
            responseID: "unused-response-\(checkpoint.proposal.requestID)",
            budgetCheckpointEventID: event.eventID,
            budgetCheckpointID: checkpoint.checkpointID,
            proposal: checkpoint.proposal,
            commandSHA256: fixtureHash("command-\(checkpoint.proposal.requestID)")
          )
        )
      default:
        break
      }
    }
    return receipts
  }

  func replacingCandidateBranch(
    in prepared: PreparedCandidate,
    with branchRef: String
  ) throws -> PreparedCandidate {
    let source = prepared.plan.policy
    let policy = LiveGitCandidateCommitPolicy(
      allowedPaths: source.allowedPaths,
      checkers: source.checkers,
      baseCommitOID: source.baseCommitOID,
      expectedTreeOID: source.expectedTreeOID,
      expectedCandidateOID: source.expectedCandidateOID,
      candidateBranch: branchRef,
      resultRef: source.resultRef,
      author: source.author,
      committer: source.committer,
      message: source.message,
      producerIDs: source.producerIDs
    )
    let plan = LiveGitCandidatePlan(
      policy: policy,
      writes: prepared.plan.writes,
      preflightEventID: prepared.plan.preflightEventID,
      preflightReceiptID: prepared.plan.preflightReceiptID,
      executionEventID: prepared.plan.executionEventID,
      executionReceiptID: prepared.plan.executionReceiptID,
      observationEventID: prepared.plan.observationEventID,
      observationReceiptID: prepared.plan.observationReceiptID
    )
    return PreparedCandidate(
      plan: plan,
      coordinates: LiveTransitionCoordinates(
        episodeID: prepared.coordinates.episodeID,
        transitionID: prepared.coordinates.transitionID,
        objectID: prepared.coordinates.objectID,
        expectedEffectSHA256: try plan.canonicalSHA256()
      )
    )
  }

  func replacingCheckers(
    in prepared: PreparedCandidate,
    with checkers: [LiveGitCandidateCheckerSpec]
  ) throws -> PreparedCandidate {
    let source = prepared.plan.policy
    let policy = LiveGitCandidateCommitPolicy(
      allowedPaths: source.allowedPaths,
      checkers: checkers,
      baseCommitOID: source.baseCommitOID,
      expectedTreeOID: source.expectedTreeOID,
      expectedCandidateOID: source.expectedCandidateOID,
      candidateBranch: source.candidateBranch,
      resultRef: source.resultRef,
      author: source.author,
      committer: source.committer,
      message: source.message,
      producerIDs: source.producerIDs
    )
    let plan = LiveGitCandidatePlan(
      policy: policy,
      writes: prepared.plan.writes,
      preflightEventID: prepared.plan.preflightEventID,
      preflightReceiptID: prepared.plan.preflightReceiptID,
      executionEventID: prepared.plan.executionEventID,
      executionReceiptID: prepared.plan.executionReceiptID,
      observationEventID: prepared.plan.observationEventID,
      observationReceiptID: prepared.plan.observationReceiptID
    )
    return PreparedCandidate(
      plan: plan,
      coordinates: LiveTransitionCoordinates(
        episodeID: prepared.coordinates.episodeID,
        transitionID: prepared.coordinates.transitionID,
        objectID: prepared.coordinates.objectID,
        expectedEffectSHA256: try plan.canonicalSHA256()
      )
    )
  }

  func authorizationPrefix(_ prepared: PreparedCandidate) throws -> CandidatePrefix {
    let intent = LiveUntrustedActionIntent(
      intentID: "intent-git-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated-git-write",
      objectID: prepared.coordinates.objectID,
      expectedEffectSHA256: prepared.coordinates.expectedEffectSHA256,
      argumentsSHA256: prepared.coordinates.expectedEffectSHA256
    )
    let allowance = LiveAllowedAction(
      allowanceID: "allow-git-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: intent.adapterID,
      effectClass: intent.effectClass,
      candidateCommitPolicy: prepared.plan.policy
    )
    let confirmation = LiveGitCandidateStageReceipt(
      receiptID: "receipt-user-confirmed",
      eventID: "event-user-confirmed",
      stage: .transitionUserConfirmed,
      coordinates: prepared.coordinates,
      evidence: evidence("evidence-user-confirmed", "user-confirmed"),
      producerID: prepared.plan.policy.producerIDs.transitionUserConfirmed,
      predecessor: nil
    )
    let authorization = LiveGitCandidateStageReceipt(
      receiptID: "receipt-authorized",
      eventID: "event-authorized",
      stage: .authorized,
      coordinates: prepared.coordinates,
      evidence: evidence("evidence-authorized", "authorized"),
      producerID: prepared.plan.policy.producerIDs.authorized,
      predecessor: LiveGitCandidateReceiptLink(
        receiptID: confirmation.receiptID,
        receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(confirmation)
      )
    )
    return CandidatePrefix(
      receipts: [confirmation, authorization],
      events: [
        LiveEpisodeEvent(
          episodeID: prepared.coordinates.episodeID,
          eventID: confirmation.eventID,
          sequence: 1,
          payload: .transitionUserConfirmed(
            LiveTransitionUserConfirmed(
              coordinates: prepared.coordinates,
              evidence: confirmation.evidence
            )
          )
        ),
        LiveEpisodeEvent(
          episodeID: prepared.coordinates.episodeID,
          eventID: authorization.eventID,
          sequence: 2,
          payload: .authorizationDecided(
            LiveAuthorizationDecided(
              coordinates: prepared.coordinates,
              intentID: intent.intentID,
              allowanceID: allowance.allowanceID,
              decision: .allowed,
              evidence: authorization.evidence
            )
          )
        ),
      ],
      intent: intent,
      allowance: allowance
    )
  }

  func appendingPreflight(
    to prefix: CandidatePrefix,
    prepared: PreparedCandidate,
    result: LiveGitCandidatePreflightResult
  ) throws -> CandidatePrefix {
    var prefix = prefix
    let authorization = try XCTUnwrap(prefix.receipts.last)
    let receipt = LiveGitCandidateStageReceipt(
      receiptID: prepared.plan.preflightReceiptID,
      eventID: prepared.plan.preflightEventID,
      stage: .preflightPassed,
      coordinates: prepared.coordinates,
      evidence: result.preflightEvidence,
      producerID: prepared.plan.policy.producerIDs.preflightPassed,
      predecessor: LiveGitCandidateReceiptLink(
        receiptID: authorization.receiptID,
        receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(authorization)
      )
    )
    prefix.receipts.append(receipt)
    prefix.events.append(
      LiveEpisodeEvent(
        episodeID: prepared.coordinates.episodeID,
        eventID: receipt.eventID,
        sequence: 3,
        payload: .preflightCompleted(
          LivePreflightCompleted(
            coordinates: prepared.coordinates,
            authorizationEvidenceID: authorization.evidence.evidenceID,
            status: .passed,
            evidence: receipt.evidence
          )
        )
      )
    )
    return prefix
  }

  func preflightRequest(
    _ prepared: PreparedCandidate,
    prefix: CandidatePrefix
  ) -> LiveGitCandidatePreflightRequest {
    LiveGitCandidatePreflightRequest(
      sourceCheckoutURL: sourceURL,
      episodeDirectoryURL: episodeURL,
      coordinates: prepared.coordinates,
      plan: prepared.plan,
      selectedIntent: prefix.intent,
      allowance: prefix.allowance,
      confirmedAuthorizationReceipts: prefix.receipts,
      confirmedAuthorizationEvents: prefix.events
    )
  }

  func executionRequest(
    _ prepared: PreparedCandidate,
    prefix: CandidatePrefix
  ) -> LiveGitCandidateExecutionRequest {
    LiveGitCandidateExecutionRequest(
      sourceCheckoutURL: sourceURL,
      episodeDirectoryURL: episodeURL,
      coordinates: prepared.coordinates,
      plan: prepared.plan,
      selectedIntent: prefix.intent,
      allowance: prefix.allowance,
      confirmedPreflightReceipts: prefix.receipts,
      confirmedPreflightEvents: prefix.events
    )
  }

  func sourceSnapshot() throws -> [Data] {
    [
      try git(["rev-parse", "HEAD"], at: sourceURL),
      try git(["show-ref", "--head"], at: sourceURL),
      try git(["ls-files", "--stage", "-z"], at: sourceURL),
      try git(["status", "--porcelain=v1", "-z", "--untracked-files=all"], at: sourceURL),
      try Data(contentsOf: sourceURL.appendingPathComponent("README.md")),
    ]
  }

  func sourceGitMetadataSnapshot() throws -> [String: Data] {
    let gitURL = sourceURL.appendingPathComponent(".git", isDirectory: true)
    let keys: [URLResourceKey] = [
      .isDirectoryKey,
      .isRegularFileKey,
      .isSymbolicLinkKey,
    ]
    guard
      let enumerator = FileManager.default.enumerator(
        at: gitURL,
        includingPropertiesForKeys: keys,
        options: [.skipsPackageDescendants]
      )
    else {
      throw NSError(
        domain: "LiveGitCandidateRuntimeTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Source Git metadata could not be enumerated."]
      )
    }
    var snapshot: [String: Data] = [:]
    for case let url as URL in enumerator {
      let values = try url.resourceValues(forKeys: Set(keys))
      let relativePath = String(url.path.dropFirst(gitURL.path.count + 1))
      if values.isDirectory == true, values.isSymbolicLink != true {
        snapshot["directory:\(relativePath)"] = Data()
      } else if values.isRegularFile == true {
        snapshot["file:\(relativePath)"] = try Data(contentsOf: url)
      } else if values.isSymbolicLink == true {
        snapshot["symlink:\(relativePath)"] = Data(
          try FileManager.default.destinationOfSymbolicLink(atPath: url.path).utf8
        )
      } else {
        snapshot["other:\(relativePath)"] = Data()
      }
    }
    return snapshot
  }

  func advanceSourceHead() throws {
    try Data("new source head\n".utf8).write(to: sourceURL.appendingPathComponent("README.md"))
    try git(["add", "--", "README.md"], at: sourceURL)
    let tree = try gitString(["write-tree"], at: sourceURL)
    let commit = try commitTree(
      tree: tree,
      parent: baseOID,
      message: "advance source\n",
      at: sourceURL,
      author: fixtureSignature,
      committer: fixtureSignature
    )
    try git(["update-ref", "refs/heads/master", commit, baseOID], at: sourceURL)
    try git(["reset", "--hard", commit], at: sourceURL)
  }

  @discardableResult
  func git(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:],
    acceptedStatuses: Set<Int32> = [0]
  ) throws -> Data {
    let process = Process()
    let output = Pipe()
    let errors = Pipe()
    let inputPipe = Pipe()
    process.executableURL = LiveGitSystemRuntime.gitExecutableURL
    process.arguments =
      [
        "--no-replace-objects", "-c",
        "core.hooksPath=\(LiveGitSystemRuntime.nullDevicePath)",
      ] + arguments
    process.currentDirectoryURL = directory
    var environment = cleanGitEnvironment
    for (key, value) in additionalEnvironment { environment[key] = value }
    process.environment = environment
    process.standardOutput = output
    process.standardError = errors
    if input != nil {
      process.standardInput = inputPipe
    } else {
      process.standardInput = FileHandle.nullDevice
    }
    try process.run()
    if let input {
      try inputPipe.fileHandleForWriting.write(contentsOf: input)
      try inputPipe.fileHandleForWriting.close()
    }
    process.waitUntilExit()
    let stdout = output.fileHandleForReading.readDataToEndOfFile()
    let stderr = errors.fileHandleForReading.readDataToEndOfFile()
    guard acceptedStatuses.contains(process.terminationStatus) else {
      throw NSError(
        domain: "LiveGitCandidateRuntimeTests",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: String(decoding: stderr, as: UTF8.self)]
      )
    }
    return stdout
  }

  func gitString(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> String {
    String(
      decoding: try git(
        arguments,
        at: directory,
        input: input,
        additionalEnvironment: additionalEnvironment
      ),
      as: UTF8.self
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func policy(
    allowedPaths: [String],
    expectedTreeOID: String,
    expectedCandidateOID: String
  ) -> LiveGitCandidateCommitPolicy {
    LiveGitCandidateCommitPolicy(
      allowedPaths: allowedPaths.sorted(),
      checkers: [
        LiveGitCandidateCheckerSpec(
          checkerID: "checker-git-diff",
          argvGrammar: .gitDiffCheckV1
        )
      ],
      baseCommitOID: baseOID,
      expectedTreeOID: expectedTreeOID,
      expectedCandidateOID: expectedCandidateOID,
      candidateBranch: "refs/heads/fum-candidates/episode-git-candidate",
      resultRef: "refs/fum/candidates/episode-git-candidate",
      author: candidateSignature,
      committer: candidateSignature,
      message: candidateMessage,
      producerIDs: producerIDs
    )
  }
}

private let candidateMessage = "FUM isolated candidate\n"

private let fixtureSignature = LiveGitCandidateSignature(
  name: "FUM Fixture",
  email: "fixture@fum.invalid",
  timestampSeconds: 1_600_000_000,
  timeZoneOffsetMinutes: 0
)

private let candidateSignature = LiveGitCandidateSignature(
  name: "FUM Candidate Runtime",
  email: "candidate@fum.invalid",
  timestampSeconds: 1_700_000_000,
  timeZoneOffsetMinutes: 0
)

private let producerIDs = LiveGitCandidateProducerIDs(
  transitionUserConfirmed: "producer-user-confirmation",
  authorized: "producer-authorizer",
  preflightPassed: "producer-preflight",
  executed: "producer-git-executor",
  observed: "producer-git-observer"
)

private let cleanGitEnvironment = [
  "GIT_ATTR_NOSYSTEM": "1",
  "GIT_CONFIG_GLOBAL": LiveGitSystemRuntime.nullDevicePath,
  "GIT_CONFIG_NOSYSTEM": "1",
  "GIT_NO_REPLACE_OBJECTS": "1",
  "GIT_OPTIONAL_LOCKS": "0",
  "GIT_TERMINAL_PROMPT": "0",
  "LANG": "C",
  "LC_ALL": "C",
  "PATH": LiveGitSystemRuntime.executableSearchPath,
  "TZ": "UTC",
]

private func withGitCandidateFixture(
  _ body: (GitCandidateFixture) throws -> Void
) throws {
  let fileManager = FileManager.default
  let rootURL = fileManager.temporaryDirectory.appendingPathComponent(
    "fum-live-git-candidate-\(UUID().uuidString)",
    isDirectory: true
  )
  let sourceURL = rootURL.appendingPathComponent("source", isDirectory: true)
  let episodeURL = rootURL.appendingPathComponent("episode", isDirectory: true)
  try fileManager.createDirectory(at: sourceURL, withIntermediateDirectories: true)
  try fileManager.createDirectory(at: episodeURL, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: rootURL) }

  let bootstrap = GitCandidateFixture(
    rootURL: rootURL,
    sourceURL: sourceURL,
    episodeURL: episodeURL,
    cloneURL: episodeURL.appendingPathComponent(
      LiveGitCandidateRuntimeSchema.cloneRelativePath,
      isDirectory: true
    ),
    baseOID: ""
  )
  try bootstrap.git(["init", "--quiet", "--initial-branch=master"], at: sourceURL)
  try Data("base\n".utf8).write(to: sourceURL.appendingPathComponent("README.md"))
  try bootstrap.git(["add", "--", "README.md"], at: sourceURL)
  let tree = try bootstrap.gitString(["write-tree"], at: sourceURL)
  let commit = try commitTree(
    tree: tree,
    parent: nil,
    message: "base\n",
    at: sourceURL,
    author: fixtureSignature,
    committer: fixtureSignature,
    fixture: bootstrap
  )
  try bootstrap.git(["update-ref", "refs/heads/master", commit], at: sourceURL)
  try bootstrap.git(["reset", "--hard", commit], at: sourceURL)

  try body(
    GitCandidateFixture(
      rootURL: rootURL,
      sourceURL: sourceURL,
      episodeURL: episodeURL,
      cloneURL: episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.cloneRelativePath,
        isDirectory: true
      ),
      baseOID: commit
    )
  )
}

private func commitTree(
  tree: String,
  parent: String?,
  message: String,
  at directory: URL,
  author: LiveGitCandidateSignature,
  committer: LiveGitCandidateSignature,
  fixture: GitCandidateFixture? = nil
) throws -> String {
  let runner =
    fixture
    ?? GitCandidateFixture(
      rootURL: directory.deletingLastPathComponent(),
      sourceURL: directory,
      episodeURL: directory,
      cloneURL: directory,
      baseOID: parent ?? ""
    )
  var arguments = ["commit-tree", tree]
  if let parent { arguments += ["-p", parent] }
  return try runner.gitString(
    arguments,
    at: directory,
    input: Data(message.utf8),
    additionalEnvironment: [
      "GIT_AUTHOR_NAME": author.name,
      "GIT_AUTHOR_EMAIL": author.email,
      "GIT_AUTHOR_DATE": gitDate(author),
      "GIT_COMMITTER_NAME": committer.name,
      "GIT_COMMITTER_EMAIL": committer.email,
      "GIT_COMMITTER_DATE": gitDate(committer),
    ]
  )
}

private func gitDate(_ signature: LiveGitCandidateSignature) -> String {
  let sign = signature.timeZoneOffsetMinutes < 0 ? "-" : "+"
  let magnitude = abs(signature.timeZoneOffsetMinutes)
  return String(
    format: "%lld %@%02d%02d",
    signature.timestampSeconds,
    sign,
    magnitude / 60,
    magnitude % 60
  )
}

private func evidence(_ id: String, _ seed: String) -> LiveEvidenceObject {
  LiveEvidenceObject(evidenceID: id, evidenceSHA256: fixtureHash(seed))
}

private func fixtureHash(_ seed: String) -> String {
  let hexadecimal = seed.utf8.map { String(format: "%02x", $0) }.joined()
  return "sha256:" + String((hexadecimal + String(repeating: "0", count: 64)).prefix(64))
}
