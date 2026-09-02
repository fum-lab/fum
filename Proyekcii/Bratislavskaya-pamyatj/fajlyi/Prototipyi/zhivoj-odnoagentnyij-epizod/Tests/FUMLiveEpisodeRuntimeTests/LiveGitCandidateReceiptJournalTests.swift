import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveGitCandidateReceiptJournalTests: XCTestCase {
  func testTrustedAdmissionRecordsConfirmationAndExactSelectedAuthorization() throws {
    try withScratchDirectory { rootURL in
      let fixture = try makeAdmissionFixture(rootURL: rootURL)
      let runtime = LiveGitCandidateAdmissionRuntime(episodeDirectoryURL: rootURL)
      let confirmation = LiveGitCandidateUserConfirmationCommand(
        commandID: "admit-user-confirmation",
        expectedGenerationSHA256: fixture.stored.generationSHA256,
        eventID: "event-user-confirmation",
        receiptID: "receipt-user-confirmation",
        generationConfirmationEventID: "event-confirm-user-confirmation-generation",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-user-confirmation",
          evidenceSHA256: hash("trusted-user-channel")
        )
      )

      let confirmed = try runtime.recordUserConfirmation(confirmation)
      XCTAssertEqual(confirmed.status, .advanced)
      XCTAssertEqual(confirmed.state.transition?.phase, .transitionUserConfirmed)
      let afterConfirmation = try XCTUnwrap(
        LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()
      )
      XCTAssertEqual(afterConfirmation.generationSHA256, confirmed.generationSHA256)
      XCTAssertEqual(
        afterConfirmation.generation.invocationReceiptJournal,
        fixture.stored.generation.invocationReceiptJournal
      )
      XCTAssertNil(
        afterConfirmation.generation.candidateReceiptJournal?.executionCommandSHA256
      )
      XCTAssertNil(
        afterConfirmation.generation.candidateReceiptJournal?
          .observationConfirmationEventID
      )
      XCTAssertEqual(
        afterConfirmation.generation.candidateReceiptJournal?.receipts.map(\.producerID),
        [fixture.policy.producerIDs.transitionUserConfirmed]
      )
      XCTAssertTrue(
        isConfirmed(eventID: confirmation.eventID, in: afterConfirmation.state)
      )

      let confirmationRetry = try runtime.recordUserConfirmation(confirmation)
      XCTAssertEqual(confirmationRetry.status, .alreadyApplied)
      XCTAssertEqual(confirmationRetry.generationSHA256, afterConfirmation.generationSHA256)

      let authorization = LiveGitCandidateAuthorizationCommand(
        commandID: "admit-selected-intent",
        expectedGenerationSHA256: afterConfirmation.generationSHA256,
        eventID: "event-selected-authorization",
        receiptID: "receipt-selected-authorization",
        generationConfirmationEventID: "event-confirm-authorization-generation",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-selected-authorization",
          evidenceSHA256: hash("independent-authorizer")
        )
      )
      let authorized = try runtime.authorizeSelectedIntent(authorization)
      XCTAssertEqual(authorized.status, .advanced)
      XCTAssertEqual(authorized.state.transition?.phase, .authorized)
      XCTAssertEqual(
        authorized.state.transition?.authorization?.intentID,
        fixture.selectedIntent.intentID
      )
      XCTAssertEqual(
        authorized.state.transition?.authorization?.allowanceID,
        fixture.allowance.allowanceID
      )
      let afterAuthorization = try XCTUnwrap(
        LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()
      )
      XCTAssertEqual(
        afterAuthorization.generation.candidateReceiptJournal?.receipts.map(\.producerID),
        [
          fixture.policy.producerIDs.transitionUserConfirmed,
          fixture.policy.producerIDs.authorized,
        ]
      )
      XCTAssertNil(afterAuthorization.generation.candidateReceiptJournal?.executionCommandSHA256)
      XCTAssertNil(
        afterAuthorization.generation.candidateReceiptJournal?
          .observationConfirmationEventID
      )
      XCTAssertTrue(isConfirmed(eventID: authorization.eventID, in: afterAuthorization.state))

      let authorizationRetry = try runtime.authorizeSelectedIntent(authorization)
      XCTAssertEqual(authorizationRetry.status, .alreadyApplied)
      XCTAssertEqual(authorizationRetry.generationSHA256, afterAuthorization.generationSHA256)
    }
  }

  func testAdmissionRejectsStaleCollisionAndMismatchedRetry() throws {
    try withScratchDirectory { rootURL in
      let fixture = try makeAdmissionFixture(rootURL: rootURL)
      let runtime = LiveGitCandidateAdmissionRuntime(episodeDirectoryURL: rootURL)
      let stale = LiveGitCandidateUserConfirmationCommand(
        commandID: "stale-user-confirmation",
        expectedGenerationSHA256: hash("stale-generation"),
        eventID: "event-stale-user-confirmation",
        receiptID: "receipt-stale-user-confirmation",
        generationConfirmationEventID: "event-confirm-stale-generation",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-stale-user-confirmation",
          evidenceSHA256: hash("stale-user-channel")
        )
      )
      XCTAssertThrowsError(try runtime.recordUserConfirmation(stale)) { error in
        guard case .generationConflict = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался generationConflict, получено \(error).")
        }
      }

      let collision = LiveGitCandidateUserConfirmationCommand(
        commandID: "colliding-user-confirmation",
        expectedGenerationSHA256: fixture.stored.generationSHA256,
        eventID: "event-pending-transition",
        receiptID: "receipt-colliding-user-confirmation",
        generationConfirmationEventID: "event-confirm-colliding-generation",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-colliding-user-confirmation",
          evidenceSHA256: hash("colliding-user-channel")
        )
      )
      XCTAssertThrowsError(try runtime.recordUserConfirmation(collision))

      let valid = LiveGitCandidateUserConfirmationCommand(
        commandID: "valid-user-confirmation",
        expectedGenerationSHA256: fixture.stored.generationSHA256,
        eventID: "event-valid-user-confirmation",
        receiptID: "receipt-valid-user-confirmation",
        generationConfirmationEventID: "event-confirm-valid-generation",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-valid-user-confirmation",
          evidenceSHA256: hash("valid-user-channel")
        )
      )
      let advanced = try runtime.recordUserConfirmation(valid)
      let substitutedConfirmationCommand = LiveGitCandidateUserConfirmationCommand(
        commandID: "substituted-user-confirmation",
        expectedGenerationSHA256: valid.expectedGenerationSHA256,
        eventID: valid.eventID,
        receiptID: valid.receiptID,
        generationConfirmationEventID: valid.generationConfirmationEventID,
        evidence: valid.evidence
      )
      XCTAssertThrowsError(
        try runtime.recordUserConfirmation(substitutedConfirmationCommand)
      ) { error in
        guard case .invalidEvidence = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Ожидался typed conflict command ID, получено \(error).")
        }
      }
      let mismatchedRetry = LiveGitCandidateUserConfirmationCommand(
        commandID: valid.commandID,
        expectedGenerationSHA256: valid.expectedGenerationSHA256,
        eventID: valid.eventID,
        receiptID: valid.receiptID,
        generationConfirmationEventID: valid.generationConfirmationEventID,
        evidence: LiveEvidenceObject(
          evidenceID: valid.evidence.evidenceID,
          evidenceSHA256: hash("different-user-channel")
        )
      )
      XCTAssertThrowsError(try runtime.recordUserConfirmation(mismatchedRetry))
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()?.generationSHA256,
        advanced.generationSHA256
      )

      let authorization = LiveGitCandidateAuthorizationCommand(
        commandID: "valid-authorization",
        expectedGenerationSHA256: advanced.generationSHA256,
        eventID: "event-valid-authorization",
        receiptID: "receipt-valid-authorization",
        generationConfirmationEventID: "event-confirm-valid-authorization",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-valid-authorization",
          evidenceSHA256: hash("valid-authorizer")
        )
      )
      let authorized = try runtime.authorizeSelectedIntent(authorization)
      let substitutedAuthorizationCommand = LiveGitCandidateAuthorizationCommand(
        commandID: "substituted-authorization",
        expectedGenerationSHA256: authorization.expectedGenerationSHA256,
        eventID: authorization.eventID,
        receiptID: authorization.receiptID,
        generationConfirmationEventID: authorization.generationConfirmationEventID,
        evidence: authorization.evidence
      )
      XCTAssertThrowsError(
        try runtime.authorizeSelectedIntent(substitutedAuthorizationCommand)
      ) { error in
        guard case .invalidEvidence = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Ожидался typed conflict command ID, получено \(error).")
        }
      }
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()?.generationSHA256,
        authorized.generationSHA256
      )
    }
  }

  func testGenericAppendCannotForgeAnyCandidateStage() async throws {
    try await withAsyncScratchDirectory { rootURL in
      let source = try LiveEpisodeFixture.run()
      let passport = candidatePassport(from: source.passport)
      let runtime = LiveEpisodeRuntime(rootURL: rootURL)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "create-forged-candidate-episode",
          passport: passport,
          initialEvents: Array(source.events.prefix(2))
        )
      )
      let coordinates = try XCTUnwrap(created.state.transition?.declaration.coordinates)
      let allowance = try XCTUnwrap(passport.actionAllowlist.first)
      let evidence = { (suffix: String) in
        LiveEvidenceObject(
          evidenceID: "evidence-forged-\(suffix)",
          evidenceSHA256: self.hash("model-claimed-\(suffix)")
        )
      }
      let payloads: [LiveEpisodeEventPayload] = [
        .transitionUserConfirmed(
          LiveTransitionUserConfirmed(
            coordinates: coordinates,
            evidence: evidence("confirmation")
          )
        ),
        .authorizationDecided(
          LiveAuthorizationDecided(
            coordinates: coordinates,
            intentID: "intent-forged-model-claim",
            allowanceID: allowance.allowanceID,
            decision: .allowed,
            evidence: evidence("authorization")
          )
        ),
        .preflightCompleted(
          LivePreflightCompleted(
            coordinates: coordinates,
            authorizationEvidenceID: "evidence-forged-authorization",
            status: .passed,
            evidence: evidence("preflight")
          )
        ),
        .executionRecorded(
          LiveExecutionRecorded(
            coordinates: coordinates,
            preflightEvidenceID: "evidence-forged-preflight",
            status: .succeeded,
            evidence: evidence("execution")
          )
        ),
        .observationRecorded(
          LiveObservationRecorded(
            coordinates: coordinates,
            executionEvidenceID: "evidence-forged-execution",
            status: .observed,
            evidence: evidence("observation")
          )
        ),
      ]

      for (index, payload) in payloads.enumerated() {
        let forged = LiveEpisodeEvent(
          episodeID: passport.episodeID,
          eventID: "event-forged-stage-\(index)",
          sequence: created.state.nextSequence,
          payload: payload
        )
        do {
          _ = try await runtime.resume(
            LiveEpisodeResumeCommand(
              commandID: "append-forged-candidate-stage-\(index)",
              expectedGenerationSHA256: created.generationSHA256,
              action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [forged]))
            )
          )
          XCTFail("Generic append не должен владеть candidate stage \(index).")
        } catch let error as LiveEpisodeRuntimeError {
          guard case .invalidCommand(let message) = error else {
            return XCTFail("Ожидался invalidCommand, получено \(error).")
          }
          XCTAssertTrue(message.contains("runtime-owned"))
        }
      }
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()?.generationSHA256,
        created.generationSHA256
      )
    }
  }

  func testCandidateStoreRejectsCrossTransitionAndFalseProducer() throws {
    try withScratchDirectory { rootURL in
      let fixture = try makeAdmissionFixture(rootURL: rootURL)
      let evidence = LiveEvidenceObject(
        evidenceID: "evidence-adversarial-confirmation",
        evidenceSHA256: hash("adversarial-confirmation")
      )
      let event = LiveEpisodeEvent(
        episodeID: fixture.passport.episodeID,
        eventID: "event-adversarial-confirmation",
        sequence: fixture.stored.state.nextSequence,
        payload: .transitionUserConfirmed(
          LiveTransitionUserConfirmed(coordinates: fixture.coordinates, evidence: evidence)
        )
      )
      let falseProducer = LiveGitCandidateStageReceipt(
        receiptID: "receipt-adversarial-confirmation",
        eventID: event.eventID,
        stage: .transitionUserConfirmed,
        coordinates: fixture.coordinates,
        evidence: evidence,
        producerID: "model-claimed-user-producer",
        predecessor: nil
      )
      XCTAssertThrowsError(
        try LiveEpisodeGenerationStore(rootURL: rootURL).commit(
          passport: fixture.passport,
          events: fixture.stored.state.events + [event],
          invocations: fixture.stored.generation.invocationReceiptJournal.invocations,
          candidateReceipts: [falseProducer],
          candidateExecutionCommandSHA256: nil,
          expectedPreviousGenerationSHA256: fixture.stored.generationSHA256
        )
      )

      let foreignCoordinates = LiveTransitionCoordinates(
        episodeID: fixture.coordinates.episodeID,
        transitionID: "foreign-transition",
        objectID: fixture.coordinates.objectID,
        expectedEffectSHA256: fixture.coordinates.expectedEffectSHA256
      )
      let foreignEvent = LiveEpisodeEvent(
        episodeID: fixture.passport.episodeID,
        eventID: "event-foreign-confirmation",
        sequence: fixture.stored.state.nextSequence,
        payload: .transitionUserConfirmed(
          LiveTransitionUserConfirmed(coordinates: foreignCoordinates, evidence: evidence)
        )
      )
      let foreignReceipt = LiveGitCandidateStageReceipt(
        receiptID: "receipt-foreign-confirmation",
        eventID: foreignEvent.eventID,
        stage: .transitionUserConfirmed,
        coordinates: foreignCoordinates,
        evidence: evidence,
        producerID: fixture.policy.producerIDs.transitionUserConfirmed,
        predecessor: nil
      )
      XCTAssertThrowsError(
        try LiveEpisodeGenerationStore(rootURL: rootURL).commit(
          passport: fixture.passport,
          events: fixture.stored.state.events + [foreignEvent],
          invocations: fixture.stored.generation.invocationReceiptJournal.invocations,
          candidateReceipts: [foreignReceipt],
          candidateExecutionCommandSHA256: nil,
          expectedPreviousGenerationSHA256: fixture.stored.generationSHA256
        )
      )
    }
  }

  func testLegacyGenerationOmitsCandidateReceiptJournal() throws {
    try withScratchDirectory { rootURL in
      let fixture = try LiveEpisodeFixture.run()
      let runtime = LiveEpisodeRuntime(rootURL: rootURL)
      _ = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "create-legacy-generation",
          passport: fixture.passport,
          initialEvents: Array(fixture.events.prefix(2))
        )
      )
      let stored = try XCTUnwrap(LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent())
      let encoded = try LiveEpisodeRuntimeJSON.encode(stored.generation)
      let text = String(decoding: encoded, as: UTF8.self)

      XCTAssertNil(stored.generation.candidateReceiptJournal)
      XCTAssertNil(stored.generation.candidateReceiptJournalSHA256)
      XCTAssertFalse(text.contains("candidate_receipt_journal"))
    }
  }

  func testCandidateEpisodeRuntimeRejectsBeforeGitWithoutConfirmedAuthorization() throws {
    try withScratchDirectory { rootURL in
      let fixture = try LiveEpisodeFixture.run()
      let passport = candidatePassport(from: fixture.passport)
      let runtime = LiveEpisodeRuntime(rootURL: rootURL)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "create-candidate-without-authorization",
          passport: passport,
          initialEvents: Array(fixture.events.prefix(2))
        )
      )
      let policy = try XCTUnwrap(passport.actionAllowlist[0].candidateCommitPolicy)
      let plan = LiveGitCandidatePlan(
        policy: policy,
        writes: [
          LiveGitRegularFileWrite(
            path: "README.md",
            mode: .regular,
            contents: Data("candidate\n".utf8)
          )
        ],
        preflightEventID: "event-candidate-preflight",
        preflightReceiptID: "receipt-candidate-preflight",
        executionEventID: "event-candidate-execution",
        executionReceiptID: "receipt-candidate-execution",
        observationEventID: "event-candidate-observation",
        observationReceiptID: "receipt-candidate-observation"
      )
      let sourceURL = rootURL.appendingPathComponent("source", isDirectory: true)
      try FileManager.default.createDirectory(at: sourceURL, withIntermediateDirectories: true)
      let candidateRuntime = LiveGitCandidateEpisodeRuntime(
        episodeDirectoryURL: rootURL,
        sourceCheckoutURL: sourceURL
      )

      XCTAssertThrowsError(
        try candidateRuntime.createCandidateCommit(
          LiveGitCandidateEpisodeCommand(
            commandID: "execute-without-authorization",
            expectedGenerationSHA256: created.generationSHA256,
            preflightConfirmationEventID: "event-confirm-candidate-preflight",
            observationConfirmationEventID: "event-confirm-candidate-observation",
            plan: plan
          )
        )
      ) { error in
        guard case .invalidEvidence = error as? LiveGitCandidateRuntimeError else {
          return XCTFail("Ожидался invalidEvidence, получено \(error).")
        }
      }
      XCTAssertFalse(
        FileManager.default.fileExists(
          atPath: rootURL.appendingPathComponent("git-candidate-clone").path
        )
      )
    }
  }

  func testCandidateRuntimeRejectsForeignGenericPreflightConfirmation() async throws {
    try await withAsyncScratchDirectory { rootURL in
      let plan = candidatePlan()
      let fixture = try makeAdmissionFixture(rootURL: rootURL, plan: plan)
      let authorized = try authorizeCandidate(fixture, rootURL: rootURL)
      let command = candidateEpisodeCommand(
        expectedGenerationSHA256: authorized.generationSHA256,
        plan: plan
      )
      let staged = try appendCandidateStages(
        through: .preflightPassed,
        to: authorized,
        fixture: fixture,
        command: command,
        rootURL: rootURL
      )
      let foreign = try await LiveEpisodeRuntime(rootURL: rootURL).resume(
        LiveEpisodeResumeCommand(
          commandID: "generic-foreign-preflight-confirmation",
          expectedGenerationSHA256: staged.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(
              eventID: "event-generic-foreign-preflight-confirmation"
            )
          )
        )
      )
      do {
        _ = try await MainActor.run {
          try LiveGitCandidateEpisodeRuntime(
            episodeDirectoryURL: rootURL,
            sourceCheckoutURL: rootURL.appendingPathComponent(
              "missing-source",
              isDirectory: true
            )
          ).createCandidateCommit(command)
        }
        XCTFail("Чужое generic-подтверждение preflight не должно приниматься.")
      } catch LiveGitCandidateRuntimeError.invalidEvidence(let message) {
        XCTAssertTrue(message.contains("exact immediate generation confirmation"))
      } catch {
        XCTFail("Ожидался invalidEvidence, получено \(error).")
      }
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()?.generationSHA256,
        foreign.generationSHA256
      )
      XCTAssertFalse(
        FileManager.default.fileExists(
          atPath: rootURL.appendingPathComponent("git-candidate-clone").path
        )
      )
    }
  }

  func testCandidateRuntimeRejectsForeignGenericObservationConfirmation() async throws {
    try await withAsyncScratchDirectory { rootURL in
      let plan = candidatePlan()
      let fixture = try makeAdmissionFixture(rootURL: rootURL, plan: plan)
      let authorized = try authorizeCandidate(fixture, rootURL: rootURL)
      let command = candidateEpisodeCommand(
        expectedGenerationSHA256: authorized.generationSHA256,
        plan: plan
      )
      let staged = try appendCandidateStages(
        through: .observed,
        to: authorized,
        fixture: fixture,
        command: command,
        rootURL: rootURL
      )
      let genericRuntime = LiveEpisodeRuntime(rootURL: rootURL)
      let interposed = try await genericRuntime.resume(
        LiveEpisodeResumeCommand(
          commandID: "generic-interposed-observation-verification",
          expectedGenerationSHA256: staged.generationSHA256,
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(
              events: [
                LiveEpisodeEvent(
                  episodeID: fixture.passport.episodeID,
                  eventID: "event-interposed-observation-verification",
                  sequence: staged.state.nextSequence,
                  payload: .verificationRecorded(
                    LiveVerificationRecorded(
                      verificationID: "verification-interposed-observation",
                      criterionID: "criterion-variant-origin",
                      scope: .transition,
                      subjectID: fixture.coordinates.transitionID,
                      coordinates: fixture.coordinates,
                      status: .passed,
                      evidence: LiveEvidenceObject(
                        evidenceID: "evidence-interposed-observation-verification",
                        evidenceSHA256: hash("interposed-observation-verification")
                      )
                    )
                  )
                )
              ]
            )
          )
        )
      )
      let foreign = try await genericRuntime.resume(
        LiveEpisodeResumeCommand(
          commandID: "generic-foreign-observation-confirmation",
          expectedGenerationSHA256: interposed.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(
              eventID: command.observationConfirmationEventID
            )
          )
        )
      )
      do {
        _ = try await MainActor.run {
          try LiveGitCandidateEpisodeRuntime(
            episodeDirectoryURL: rootURL,
            sourceCheckoutURL: rootURL.appendingPathComponent(
              "missing-source",
              isDirectory: true
            )
          ).createCandidateCommit(command)
        }
        XCTFail("Неточное generic-подтверждение observation не должно приниматься.")
      } catch LiveGitCandidateRuntimeError.invalidEvidence(let message) {
        XCTAssertTrue(message.contains("exact immediate generation confirmation"))
      } catch {
        XCTFail("Ожидался invalidEvidence, получено \(error).")
      }
      XCTAssertEqual(
        try LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent()?.generationSHA256,
        foreign.generationSHA256
      )
    }
  }

  func testCandidateStoreRequiresImmutableObservationConfirmationBinding() throws {
    try withScratchDirectory { rootURL in
      let plan = candidatePlan()
      let fixture = try makeAdmissionFixture(rootURL: rootURL, plan: plan)
      let authorized = try authorizeCandidate(fixture, rootURL: rootURL)
      let command = candidateEpisodeCommand(
        expectedGenerationSHA256: authorized.generationSHA256,
        plan: plan
      )

      XCTAssertThrowsError(
        try appendCandidateStages(
          through: .preflightPassed,
          to: authorized,
          fixture: fixture,
          command: command,
          rootURL: rootURL,
          includeObservationConfirmationBinding: false
        )
      ) { error in
        guard case .corruptGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался corruptGeneration, получено \(error).")
        }
      }

      let staged = try appendCandidateStages(
        through: .preflightPassed,
        to: authorized,
        fixture: fixture,
        command: command,
        rootURL: rootURL
      )
      let confirmationEvent = LiveEpisodeEvent(
        episodeID: fixture.passport.episodeID,
        eventID: command.preflightConfirmationEventID,
        sequence: staged.state.nextSequence,
        payload: .generationConfirmed(
          LiveGenerationConfirmed(
            generationID: String(staged.generationSHA256.dropFirst(7)),
            confirmedThroughSequence: staged.state.nextSequence - 1,
            stateSHA256: staged.generation.stateSHA256
          )
        )
      )
      let confirmedState = try LiveEpisodeReducer.applying(
        confirmationEvent,
        to: staged.state
      )
      let journal = try XCTUnwrap(staged.generation.candidateReceiptJournal)
      XCTAssertThrowsError(
        try LiveEpisodeGenerationStore(rootURL: rootURL).commit(
          passport: confirmedState.passport,
          events: confirmedState.events,
          invocations: staged.generation.invocationReceiptJournal.invocations,
          candidateReceipts: journal.receipts,
          candidateExecutionCommandSHA256: journal.executionCommandSHA256,
          candidateObservationConfirmationEventID:
            "event-mutated-observation-confirmation",
          expectedPreviousGenerationSHA256: staged.generationSHA256
        )
      ) { error in
        guard case .incompatibleGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался incompatibleGeneration, получено \(error).")
        }
      }
    }
  }

  private struct AdmissionFixture {
    let passport: LiveEpisodePassport
    let stored: StoredLiveEpisodeGeneration
    let allowance: LiveAllowedAction
    let policy: LiveGitCandidateCommitPolicy
    let coordinates: LiveTransitionCoordinates
    let selectedIntent: LiveUntrustedActionIntent
  }

  private func makeAdmissionFixture(
    rootURL: URL,
    plan: LiveGitCandidatePlan? = nil
  ) throws -> AdmissionFixture {
    let source = try LiveEpisodeFixture.run()
    let passport = candidatePassport(from: source.passport)
    let allowance = try XCTUnwrap(passport.actionAllowlist.first)
    let policy = try XCTUnwrap(allowance.candidateCommitPolicy)
    if let plan, plan.policy != policy {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Test candidate plan does not match the candidate passport policy."
      )
    }
    let planSHA256 = try plan?.canonicalSHA256()
    let selectionIndex = try XCTUnwrap(
      source.events.firstIndex(where: { $0.kind == .modelSelectionRecorded })
    )
    let sourceEvents = Array(source.events.prefix(through: selectionIndex))
    var declaredCoordinates: LiveTransitionCoordinates?
    for event in sourceEvents {
      guard case .pendingTransitionDeclared(let value) = event.payload else { continue }
      declaredCoordinates = value.coordinates
      break
    }
    let sourceCoordinates = try XCTUnwrap(declaredCoordinates)
    let coordinates = LiveTransitionCoordinates(
      episodeID: sourceCoordinates.episodeID,
      transitionID: sourceCoordinates.transitionID,
      schemaVersion: sourceCoordinates.schemaVersion,
      objectID: sourceCoordinates.objectID,
      expectedEffectSHA256: planSHA256 ?? sourceCoordinates.expectedEffectSHA256
    )

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
        argumentsSHA256: planSHA256 ?? parsed.intent.argumentsSHA256
      )
    }

    let events = try sourceEvents.map { event -> LiveEpisodeEvent in
      let payload: LiveEpisodeEventPayload
      switch event.payload {
      case .pendingTransitionDeclared(let declaration):
        payload = .pendingTransitionDeclared(
          LivePendingTransitionDeclared(
            coordinates: coordinates,
            allowanceID: declaration.allowanceID,
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
        episodeID: event.episodeID,
        eventID: event.eventID,
        sequence: event.sequence,
        payload: payload
      )
    }
    let invocations = try invocationReceipts(for: events)
    let stored = try LiveEpisodeGenerationStore(rootURL: rootURL).commit(
      passport: passport,
      events: events,
      invocations: invocations,
      candidateReceipts: [],
      candidateExecutionCommandSHA256: nil,
      expectedPreviousGenerationSHA256: nil
    )
    let selection = try XCTUnwrap(stored.state.model.selection)
    let selectedVariant = try XCTUnwrap(
      stored.state.model.variants.first(where: {
        $0.proposal.variantID == selection.selectedVariantID
      })
    )
    let selectedIntent = try XCTUnwrap(selectedVariant.intent?.intent)
    return AdmissionFixture(
      passport: passport,
      stored: stored,
      allowance: allowance,
      policy: policy,
      coordinates: coordinates,
      selectedIntent: selectedIntent
    )
  }

  private func invocationReceipts(
    for events: [LiveEpisodeEvent]
  ) throws -> [LiveEpisodeInvocationReceipt] {
    var receipts: [LiveEpisodeInvocationReceipt] = []
    for event in events {
      switch event.payload {
      case .modelRequestRecorded(let request):
        var responseEventID: String?
        var matchingResponse: LiveModelResponseRecorded?
        for candidate in events {
          guard case .modelResponseRecorded(let response) = candidate.payload,
            response.requestID == request.proposal.requestID
          else { continue }
          responseEventID = candidate.eventID
          matchingResponse = response
          break
        }
        let exactResponseEventID = try XCTUnwrap(responseEventID)
        let exactResponse = try XCTUnwrap(matchingResponse)
        receipts.append(
          LiveEpisodeInvocationReceipt(
            requestEventID: event.eventID,
            responseEventID: exactResponseEventID,
            responseID: exactResponse.responseID,
            budgetCheckpointEventID: "unused-budget-\(request.proposal.requestID)",
            budgetCheckpointID: "unused-budget-\(request.proposal.requestID)",
            proposal: request.proposal,
            commandSHA256: hash("command-\(request.proposal.requestID)")
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
            commandSHA256: hash("command-\(checkpoint.proposal.requestID)")
          )
        )
      default:
        break
      }
    }
    return receipts
  }

  private func authorizeCandidate(
    _ fixture: AdmissionFixture,
    rootURL: URL
  ) throws -> StoredLiveEpisodeGeneration {
    let runtime = LiveGitCandidateAdmissionRuntime(episodeDirectoryURL: rootURL)
    let confirmed = try runtime.recordUserConfirmation(
      LiveGitCandidateUserConfirmationCommand(
        commandID: "command-exact-confirmation-user",
        expectedGenerationSHA256: fixture.stored.generationSHA256,
        eventID: "event-exact-confirmation-user",
        receiptID: "receipt-exact-confirmation-user",
        generationConfirmationEventID: "event-confirm-exact-confirmation-user",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-exact-confirmation-user",
          evidenceSHA256: hash("trusted-user")
        )
      )
    )
    _ = try runtime.authorizeSelectedIntent(
      LiveGitCandidateAuthorizationCommand(
        commandID: "command-exact-confirmation-authorization",
        expectedGenerationSHA256: confirmed.generationSHA256,
        eventID: "event-exact-confirmation-authorization",
        receiptID: "receipt-exact-confirmation-authorization",
        generationConfirmationEventID: "event-confirm-exact-confirmation-authorization",
        evidence: LiveEvidenceObject(
          evidenceID: "evidence-exact-confirmation-authorization",
          evidenceSHA256: hash("trusted-authorizer")
        )
      )
    )
    return try XCTUnwrap(LiveEpisodeGenerationStore(rootURL: rootURL).loadCurrent())
  }

  private func candidateEpisodeCommand(
    expectedGenerationSHA256: String,
    plan: LiveGitCandidatePlan
  ) -> LiveGitCandidateEpisodeCommand {
    LiveGitCandidateEpisodeCommand(
      commandID: "command-exact-stage-confirmations",
      expectedGenerationSHA256: expectedGenerationSHA256,
      preflightConfirmationEventID: "event-exact-preflight-confirmation",
      observationConfirmationEventID: "event-exact-observation-confirmation",
      plan: plan
    )
  }

  private func appendCandidateStages(
    through finalStage: LiveGitCandidateStage,
    to current: StoredLiveEpisodeGeneration,
    fixture: AdmissionFixture,
    command: LiveGitCandidateEpisodeCommand,
    rootURL: URL,
    includeObservationConfirmationBinding: Bool = true
  ) throws -> StoredLiveEpisodeGeneration {
    guard finalStage == .preflightPassed || finalStage == .observed else {
      throw LiveGitCandidateRuntimeError.invalidPlan(
        "Test helper supports preflight or observation prefixes."
      )
    }
    var state = current.state
    var receipts = current.generation.candidateReceiptJournal?.receipts ?? []

    func append(
      stage: LiveGitCandidateStage,
      eventID: String,
      receiptID: String,
      evidence: LiveEvidenceObject,
      payload: LiveEpisodeEventPayload
    ) throws {
      let previous = try XCTUnwrap(receipts.last)
      let event = LiveEpisodeEvent(
        episodeID: fixture.passport.episodeID,
        eventID: eventID,
        sequence: state.nextSequence,
        payload: payload
      )
      state = try LiveEpisodeReducer.applying(event, to: state)
      receipts.append(
        LiveGitCandidateStageReceipt(
          receiptID: receiptID,
          eventID: eventID,
          stage: stage,
          coordinates: fixture.coordinates,
          evidence: evidence,
          producerID: fixture.policy.producerIDs.producerID(for: stage),
          predecessor: LiveGitCandidateReceiptLink(
            receiptID: previous.receiptID,
            receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(previous)
          )
        )
      )
    }

    let preflightEvidence = LiveEvidenceObject(
      evidenceID: command.plan.preflightReceiptID,
      evidenceSHA256: hash("manual-preflight-evidence")
    )
    try append(
      stage: .preflightPassed,
      eventID: command.plan.preflightEventID,
      receiptID: command.plan.preflightReceiptID,
      evidence: preflightEvidence,
      payload: .preflightCompleted(
        LivePreflightCompleted(
          coordinates: fixture.coordinates,
          authorizationEvidenceID: receipts[1].evidence.evidenceID,
          status: .passed,
          evidence: preflightEvidence
        )
      )
    )

    if finalStage == .observed {
      let executionEvidence = LiveEvidenceObject(
        evidenceID: command.plan.executionReceiptID,
        evidenceSHA256: hash(command.plan.policy.expectedCandidateOID)
      )
      try append(
        stage: .executed,
        eventID: command.plan.executionEventID,
        receiptID: command.plan.executionReceiptID,
        evidence: executionEvidence,
        payload: .executionRecorded(
          LiveExecutionRecorded(
            coordinates: fixture.coordinates,
            preflightEvidenceID: preflightEvidence.evidenceID,
            status: .succeeded,
            evidence: executionEvidence
          )
        )
      )
      let observationEvidence = LiveEvidenceObject(
        evidenceID: command.plan.observationReceiptID,
        evidenceSHA256: hash("manual-observation-evidence")
      )
      try append(
        stage: .observed,
        eventID: command.plan.observationEventID,
        receiptID: command.plan.observationReceiptID,
        evidence: observationEvidence,
        payload: .observationRecorded(
          LiveObservationRecorded(
            coordinates: fixture.coordinates,
            executionEvidenceID: executionEvidence.evidenceID,
            status: .observed,
            evidence: observationEvidence
          )
        )
      )
    }

    return try LiveEpisodeGenerationStore(rootURL: rootURL).commit(
      passport: state.passport,
      events: state.events,
      invocations: current.generation.invocationReceiptJournal.invocations,
      candidateReceipts: receipts,
      candidateExecutionCommandSHA256: try command.canonicalSHA256(),
      candidateObservationConfirmationEventID:
        includeObservationConfirmationBinding
        ? command.observationConfirmationEventID : nil,
      expectedPreviousGenerationSHA256: current.generationSHA256
    )
  }

  private func isConfirmed(eventID: String, in state: LiveEpisodeState) -> Bool {
    guard let sequence = state.events.first(where: { $0.eventID == eventID })?.sequence,
      let confirmation = state.confirmedGeneration?.confirmation
    else { return false }
    return confirmation.confirmedThroughSequence >= sequence
  }

  private func hash(_ value: String) -> String {
    LiveStrictIntentParser.sha256(of: value)
  }

  private func candidatePassport(from legacy: LiveEpisodePassport) -> LiveEpisodePassport {
    let policy = candidatePolicy()
    return LiveEpisodePassport(
      schemaIdentity: legacy.schemaIdentity,
      schemaVersion: legacy.schemaVersion,
      episodeID: legacy.episodeID,
      goal: legacy.goal,
      context: legacy.context,
      modelPolicy: legacy.modelPolicy,
      actionAllowlist: [
        LiveAllowedAction(
          allowanceID: "allow-store-candidate",
          operation: LiveGitCandidateContract.operation,
          adapterID: "fum-git-candidate-v1",
          effectClass: "isolated_git_write",
          candidateCommitPolicy: policy
        )
      ],
      verificationCriteria: legacy.verificationCriteria,
      checkpointPolicy: legacy.checkpointPolicy,
      terminalOutcomes: legacy.terminalOutcomes
    )
  }

  private func candidatePolicy() -> LiveGitCandidateCommitPolicy {
    let oid1 = String(repeating: "1", count: 40)
    let oid2 = String(repeating: "2", count: 40)
    let oid3 = String(repeating: "3", count: 40)
    let signature = LiveGitCandidateSignature(
      name: "FUM Candidate",
      email: "candidate@example.invalid",
      timestampSeconds: 1_700_000_000,
      timeZoneOffsetMinutes: 0
    )
    return LiveGitCandidateCommitPolicy(
      allowedPaths: ["README.md"],
      checkers: [
        LiveGitCandidateCheckerSpec(
          checkerID: "checker-git-diff",
          argvGrammar: .gitDiffCheckV1
        )
      ],
      baseCommitOID: oid1,
      expectedTreeOID: oid2,
      expectedCandidateOID: oid3,
      candidateBranch: "refs/heads/fum-candidate/episode-test",
      resultRef: "refs/fum/candidates/episode-test",
      author: signature,
      committer: signature,
      message: "Create deterministic candidate\n",
      producerIDs: LiveGitCandidateProducerIDs(
        transitionUserConfirmed: "producer-user-confirmation",
        authorized: "producer-authorizer",
        preflightPassed: "producer-preflight",
        executed: "producer-git-executor",
        observed: "producer-git-observer"
      )
    )
  }

  private func candidatePlan() -> LiveGitCandidatePlan {
    LiveGitCandidatePlan(
      policy: candidatePolicy(),
      writes: [
        LiveGitRegularFileWrite(
          path: "README.md",
          mode: .regular,
          contents: Data("candidate\n".utf8)
        )
      ],
      preflightEventID: "event-exact-preflight",
      preflightReceiptID: "receipt-exact-preflight",
      executionEventID: "event-exact-execution",
      executionReceiptID: "receipt-exact-execution",
      observationEventID: "event-exact-observation",
      observationReceiptID: "receipt-exact-observation"
    )
  }

  private func withScratchDirectory<T>(_ body: (URL) throws -> T) throws -> T {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-candidate-receipts-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: url) }
    return try body(url)
  }

  private func withAsyncScratchDirectory<T>(
    _ body: (URL) async throws -> T
  ) async throws -> T {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-candidate-receipts-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: url) }
    return try await body(url)
  }
}
