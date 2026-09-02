import XCTest

@testable import FUMLiveEpisodeCore

final class LiveEpisodeReducerTests: XCTestCase {
  func testUnknownSchemaVersionIsRejectedForPassportAndEvent() throws {
    let fixture = try LiveEpisodeFixture.run()
    let unsupportedPassport = replacingPassport(
      fixture.passport,
      schemaVersion: LiveEpisodeSchema.version + 1
    )
    assertLiveError(
      .unsupportedSchema(
        identity: LiveEpisodeSchema.identity,
        version: LiveEpisodeSchema.version + 1
      )
    ) {
      _ = try LiveEpisodeReducer.initialState(passport: unsupportedPassport)
    }

    let initial = try LiveEpisodeReducer.initialState(passport: fixture.passport)
    let first = try XCTUnwrap(fixture.events.first)
    let unsupportedEvent = replacingEvent(
      first,
      schemaVersion: LiveEpisodeSchema.version + 1
    )
    assertLiveError(
      .unsupportedSchema(
        identity: LiveEpisodeSchema.identity,
        version: LiveEpisodeSchema.version + 1
      )
    ) {
      _ = try LiveEpisodeReducer.applying(unsupportedEvent, to: initial)
    }
  }

  func testBrokenSequenceAndOrderAreRejected() throws {
    let fixture = try LiveEpisodeFixture.run()
    let initial = try LiveEpisodeReducer.initialState(passport: fixture.passport)
    let first = try XCTUnwrap(fixture.events.first)
    let wrongSequence = replacingEvent(first, sequence: initial.nextSequence + 1)

    assertLiveError(
      .unexpectedSequence(expected: initial.nextSequence, actual: initial.nextSequence + 1)
    ) {
      _ = try LiveEpisodeReducer.applying(wrongSequence, to: initial)
    }

    let prematureGeneration = makeEvent(
      in: initial,
      eventID: "event-premature-generation",
      payload: .generationConfirmed(
        LiveGenerationConfirmed(
          generationID: "generation-premature",
          confirmedThroughSequence: 0,
          stateSHA256: hash("c")
        )
      )
    )
    XCTAssertThrowsError(
      try LiveEpisodeReducer.applying(prematureGeneration, to: initial)
    ) { error in
      guard let liveError = error as? LiveEpisodeError else {
        return XCTFail("Ожидался LiveEpisodeError, получено: \(error)")
      }
      guard case .eventOrderViolation(let kind, _) = liveError else {
        return XCTFail("Ожидался типизированный отказ порядка, получено: \(error)")
      }
      XCTAssertEqual(kind, .generationConfirmed)
    }
  }

  func testEpisodeAndProviderIdentitySubstitutionAreRejected() throws {
    let fixture = try LiveEpisodeFixture.run()
    let initial = try LiveEpisodeReducer.initialState(passport: fixture.passport)
    let first = try XCTUnwrap(fixture.events.first)
    let foreignEpisode = replacingEvent(first, episodeID: "episode-foreign")

    assertLiveError(
      .identityMismatch(
        field: "episode_id",
        expected: fixture.passport.episodeID,
        actual: "episode-foreign"
      )
    ) {
      _ = try LiveEpisodeReducer.applying(foreignEpisode, to: initial)
    }

    let responseIndex = try eventIndex(
      in: fixture,
      where: {
        $0.kind == .modelResponseRecorded
      })
    let beforeResponse = try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events[..<responseIndex])
    )
    guard case .modelResponseRecorded(let response) = fixture.events[responseIndex].payload else {
      return XCTFail("Фикстура не содержит ожидаемый model-only-ответ.")
    }
    let foreignProvider = LiveProviderIdentity(
      providerID: "provider-foreign",
      interfaceID: response.providerIdentity.interfaceID,
      modelID: response.providerIdentity.modelID,
      runtimeID: response.providerIdentity.runtimeID
    )
    let substituted = LiveModelResponseRecorded(
      responseID: response.responseID,
      requestID: response.requestID,
      variantID: response.variantID,
      providerIdentity: foreignProvider,
      status: response.status,
      output: response.output,
      outputSHA256: response.outputSHA256,
      charged: response.charged
    )
    let event = makeEvent(
      in: beforeResponse,
      eventID: "event-provider-substitution",
      payload: .modelResponseRecorded(substituted)
    )

    assertLiveError(
      .identityMismatch(
        field: "provider_identity",
        expected: fixture.passport.modelPolicy.providerIdentity.providerID,
        actual: foreignProvider.providerID
      )
    ) {
      _ = try LiveEpisodeReducer.applying(event, to: beforeResponse)
    }
  }

  func testSelectionRequiresSavedResponseParsedIntentAndExactSources() throws {
    let fixture = try LiveEpisodeFixture.run()
    let responseIndex = try eventIndex(
      in: fixture,
      where: {
        $0.kind == .modelResponseRecorded
      })
    let intentIndex = try eventIndex(
      in: fixture,
      where: {
        $0.kind == .untrustedIntentParsed
      })
    let selectionIndex = try eventIndex(
      in: fixture,
      where: {
        $0.kind == .modelSelectionRecorded
      })
    let beforeResponse = try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events[..<responseIndex])
    )
    let beforeIntent = try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events[..<intentIndex])
    )
    let beforeSelection = try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events[..<selectionIndex])
    )

    let selection = selectionPayload()
    assertLiveError(.modelSelectionWithoutResponse(variantID: "variant-a")) {
      _ = try LiveEpisodeReducer.applying(
        makeEvent(
          in: beforeResponse,
          eventID: "event-selection-without-response",
          payload: .modelSelectionRecorded(selection)
        ),
        to: beforeResponse
      )
    }
    assertLiveError(.modelSelectionWithoutIntent(variantID: "variant-a")) {
      _ = try LiveEpisodeReducer.applying(
        makeEvent(
          in: beforeIntent,
          eventID: "event-selection-without-intent",
          payload: .modelSelectionRecorded(selection)
        ),
        to: beforeIntent
      )
    }

    let wrongResponse = LiveModelSelectionRecorded(
      selectionID: "selection-wrong-response",
      selectedVariantID: "variant-a",
      sourceResponseID: "response-foreign",
      sourceIntentID: "intent-variant-a",
      consideredVariantIDs: ["variant-a", "variant-b"],
      basisVerificationIDs: ["verification-variant-a", "verification-variant-b"]
    )
    assertLiveError(.modelSelectionWithoutResponse(variantID: "variant-a")) {
      _ = try LiveEpisodeReducer.applying(
        makeEvent(
          in: beforeSelection,
          eventID: "event-selection-wrong-response",
          payload: .modelSelectionRecorded(wrongResponse)
        ),
        to: beforeSelection
      )
    }

    let wrongIntent = LiveModelSelectionRecorded(
      selectionID: "selection-wrong-intent",
      selectedVariantID: "variant-a",
      sourceResponseID: "response-variant-a",
      sourceIntentID: "intent-foreign",
      consideredVariantIDs: ["variant-a", "variant-b"],
      basisVerificationIDs: ["verification-variant-a", "verification-variant-b"]
    )
    assertLiveError(.modelSelectionWithoutIntent(variantID: "variant-a")) {
      _ = try LiveEpisodeReducer.applying(
        makeEvent(
          in: beforeSelection,
          eventID: "event-selection-wrong-intent",
          payload: .modelSelectionRecorded(wrongIntent)
        ),
        to: beforeSelection
      )
    }
  }

  func testCrossTransitionCoordinatesFailAtEveryExternalEvidenceBoundary() throws {
    let fixture = try LiveEpisodeFixture.run()
    var state = try stateThroughSelection(fixture)
    let coordinates = try XCTUnwrap(state.transition?.declaration.coordinates)
    let foreign = LiveTransitionCoordinates(
      episodeID: coordinates.episodeID,
      transitionID: "transition-foreign",
      schemaVersion: coordinates.schemaVersion,
      objectID: coordinates.objectID,
      expectedEffectSHA256: coordinates.expectedEffectSHA256
    )
    let intentID = try XCTUnwrap(state.model.variants.first?.intent?.intent.intentID)
    let allowanceID = try XCTUnwrap(state.transition?.declaration.allowanceID)

    let foreignConfirmation = LiveTransitionUserConfirmed(
      coordinates: foreign,
      evidence: evidence("evidence-cross-confirmation", "1")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-confirmation",
        payload: .transitionUserConfirmed(foreignConfirmation)
      ),
      in: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-confirmation",
        payload: .transitionUserConfirmed(
          LiveTransitionUserConfirmed(
            coordinates: coordinates,
            evidence: evidence("evidence-confirmation", "2")
          )
        )
      ),
      to: state
    )

    let foreignAuthorization = LiveAuthorizationDecided(
      coordinates: foreign,
      intentID: intentID,
      allowanceID: allowanceID,
      decision: .allowed,
      evidence: evidence("evidence-cross-authorization", "3")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-authorization",
        payload: .authorizationDecided(foreignAuthorization)
      ),
      in: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-authorization",
        payload: .authorizationDecided(
          LiveAuthorizationDecided(
            coordinates: coordinates,
            intentID: intentID,
            allowanceID: allowanceID,
            decision: .allowed,
            evidence: evidence("evidence-authorization", "4")
          )
        )
      ),
      to: state
    )

    let foreignPreflight = LivePreflightCompleted(
      coordinates: foreign,
      authorizationEvidenceID: "evidence-authorization",
      status: .passed,
      evidence: evidence("evidence-cross-preflight", "5")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-preflight",
        payload: .preflightCompleted(foreignPreflight)
      ),
      in: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-preflight",
        payload: .preflightCompleted(
          LivePreflightCompleted(
            coordinates: coordinates,
            authorizationEvidenceID: "evidence-authorization",
            status: .passed,
            evidence: evidence("evidence-preflight", "6")
          )
        )
      ),
      to: state
    )

    let foreignExecution = LiveExecutionRecorded(
      coordinates: foreign,
      preflightEvidenceID: "evidence-preflight",
      status: .succeeded,
      evidence: evidence("evidence-cross-execution", "7")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-execution",
        payload: .executionRecorded(foreignExecution)
      ),
      in: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-execution",
        payload: .executionRecorded(
          LiveExecutionRecorded(
            coordinates: coordinates,
            preflightEvidenceID: "evidence-preflight",
            status: .succeeded,
            evidence: evidence("evidence-execution", "8")
          )
        )
      ),
      to: state
    )

    let foreignObservation = LiveObservationRecorded(
      coordinates: foreign,
      executionEvidenceID: "evidence-execution",
      status: .observed,
      evidence: evidence("evidence-cross-observation", "9")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-observation",
        payload: .observationRecorded(foreignObservation)
      ),
      in: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-observation",
        payload: .observationRecorded(
          LiveObservationRecorded(
            coordinates: coordinates,
            executionEvidenceID: "evidence-execution",
            status: .observed,
            evidence: evidence("evidence-observation", "a")
          )
        )
      ),
      to: state
    )

    let foreignVerification = LiveVerificationRecorded(
      verificationID: "verification-cross-transition",
      criterionID: "criterion-variant-origin",
      scope: .transition,
      subjectID: coordinates.transitionID,
      coordinates: foreign,
      status: .passed,
      evidence: evidence("evidence-cross-verification", "b")
    )
    assertTransitionMismatch(
      makeEvent(
        in: state,
        eventID: "event-cross-verification",
        payload: .verificationRecorded(foreignVerification)
      ),
      in: state
    )
  }

  func testExternalStagesCannotElevateWithoutPriorExactEvidence() throws {
    let fixture = try LiveEpisodeFixture.run()
    let state = try stateThroughSelection(fixture)
    let coordinates = try XCTUnwrap(state.transition?.declaration.coordinates)
    let intentID = try XCTUnwrap(state.model.variants.first?.intent?.intent.intentID)
    let allowanceID = try XCTUnwrap(state.transition?.declaration.allowanceID)

    let attempts: [LiveEpisodeEventPayload] = [
      .authorizationDecided(
        LiveAuthorizationDecided(
          coordinates: coordinates,
          intentID: intentID,
          allowanceID: allowanceID,
          decision: .allowed,
          evidence: evidence("evidence-premature-authorization", "c")
        )
      ),
      .preflightCompleted(
        LivePreflightCompleted(
          coordinates: coordinates,
          authorizationEvidenceID: "evidence-missing-authorization",
          status: .passed,
          evidence: evidence("evidence-premature-preflight", "d")
        )
      ),
      .executionRecorded(
        LiveExecutionRecorded(
          coordinates: coordinates,
          preflightEvidenceID: "evidence-missing-preflight",
          status: .succeeded,
          evidence: evidence("evidence-premature-execution", "e")
        )
      ),
      .observationRecorded(
        LiveObservationRecorded(
          coordinates: coordinates,
          executionEvidenceID: "evidence-missing-execution",
          status: .observed,
          evidence: evidence("evidence-premature-observation", "f")
        )
      ),
    ]

    for (index, payload) in attempts.enumerated() {
      XCTAssertThrowsError(
        try LiveEpisodeReducer.applying(
          makeEvent(
            in: state,
            eventID: "event-false-elevation-\(index)",
            payload: payload
          ),
          to: state
        )
      ) { error in
        guard let liveError = error as? LiveEpisodeError else {
          return XCTFail("Ожидался LiveEpisodeError, получено: \(error)")
        }
        guard case .falseStatusElevation = liveError else {
          return XCTFail("Ожидался falseStatusElevation, получено: \(error)")
        }
      }
    }
  }

  func testEveryBudgetDimensionCreatesCheckpointWithoutRequestOrEvent() throws {
    let maximum = budget(2, 16, 16, 1_000, 1_000, 10)
    let reservation = budget(1, 8, 8, 500, 500, 5)
    let exhausted: [(String, LiveBudget)] = [
      ("calls", budget(2, 8, 8, 500, 500, 5)),
      ("input", budget(1, 9, 8, 500, 500, 5)),
      ("output", budget(1, 8, 9, 500, 500, 5)),
      ("wall", budget(1, 8, 8, 501, 500, 5)),
      ("compute", budget(1, 8, 8, 500, 501, 5)),
      ("money", budget(1, 8, 8, 500, 500, 6)),
    ]

    for (index, entry) in exhausted.enumerated() {
      let policy = try modelPolicy(
        executionMode: .local,
        moneyUnit: .usdMicrounit,
        maximum: maximum,
        reservation: reservation
      )
      let state = try stateWithCheckpoint(modelPolicy: policy, charged: entry.1)
      let proposal = proposal(
        requestID: "request-exhausted-\(index)",
        reservation: reservation
      )
      let originalEvents = state.events
      let decision = try LiveEpisodeReducer.planModelInvocation(
        proposal,
        checkpointID: "checkpoint-exhausted-\(index)",
        in: state
      )

      guard case .checkpoint(let checkpoint) = decision else {
        return XCTFail("Измерение \(entry.0) не создало контрольную точку.")
      }
      XCTAssertEqual(checkpoint.reason, .insufficientBudget, entry.0)
      XCTAssertEqual(checkpoint.proposal, proposal, entry.0)
      XCTAssertEqual(state.events, originalEvents, entry.0)
      XCTAssertFalse(
        state.events.contains(where: {
          if case .modelRequestRecorded = $0.payload { return true }
          return false
        }),
        entry.0
      )
    }
  }

  func testZeroMoneyRequiresProvenFreeLocalProfile() throws {
    let maximum = budget(1, 8, 8, 500, 500, 0)
    let reservation = maximum
    let proposal = proposal(requestID: "request-zero-money", reservation: reservation)

    let localState = try stateWithCheckpoint(
      modelPolicy: modelPolicy(
        executionMode: .local,
        moneyUnit: .none,
        maximum: maximum,
        reservation: reservation
      )
    )
    let localDecision = try LiveEpisodeReducer.planModelInvocation(
      proposal,
      checkpointID: "checkpoint-unused-local",
      in: localState
    )
    guard case .request(let request) = localDecision else {
      return XCTFail("Доказанно бесплатный локальный вызов был закрыт.")
    }
    XCTAssertEqual(request.proposal, proposal)

    let remoteState = try stateWithCheckpoint(
      modelPolicy: modelPolicy(
        executionMode: .remote,
        moneyUnit: .usdMicrounit,
        maximum: maximum,
        reservation: reservation
      )
    )
    let remoteDecision = try LiveEpisodeReducer.planModelInvocation(
      proposal,
      checkpointID: "checkpoint-zero-money-remote",
      in: remoteState
    )
    guard case .checkpoint(let checkpoint) = remoteDecision else {
      return XCTFail("Неподтверждённо бесплатный remote-вызов был разрешён.")
    }
    XCTAssertEqual(checkpoint.reason, .zeroMoneyNotProvenFreeLocal)
    XCTAssertTrue(remoteState.events.allSatisfy { $0.kind != .modelRequestRecorded })
  }

  func testSameEventIDWithChangedBodyIsTypedConflict() throws {
    let fixture = try LiveEpisodeFixture.run()
    let initial = try LiveEpisodeReducer.initialState(passport: fixture.passport)
    let first = try XCTUnwrap(fixture.events.first)
    let applied = try LiveEpisodeReducer.applying(first, to: initial)
    let changed = replacingEvent(
      first,
      payload: .modelCheckpointCreated(
        LiveModelCheckpointCreated(
          checkpointID: "checkpoint-common-ancestor",
          ancestorSHA256: hash("f")
        )
      )
    )

    assertLiveError(.eventConflict(eventID: first.eventID)) {
      _ = try LiveEpisodeReducer.applying(changed, to: applied)
    }
    XCTAssertEqual(applied.events, [first])
  }

  private func stateThroughSelection(
    _ fixture: LiveEpisodeFixtureResult
  ) throws -> LiveEpisodeState {
    let index = try eventIndex(
      in: fixture,
      where: {
        $0.kind == .modelSelectionRecorded
      })
    return try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events[...index])
    )
  }

  private func stateWithCheckpoint(
    modelPolicy: LiveModelPolicy,
    charged: LiveBudget = .zero
  ) throws -> LiveEpisodeState {
    let fixture = try LiveEpisodeFixture.run()
    let passport = replacingPassport(fixture.passport, modelPolicy: modelPolicy)
    var state = try LiveEpisodeReducer.initialState(passport: passport)
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        in: state,
        eventID: "event-budget-common-checkpoint",
        payload: .modelCheckpointCreated(
          LiveModelCheckpointCreated(
            checkpointID: "checkpoint-budget-common",
            ancestorSHA256: hash("0")
          )
        )
      ),
      to: state
    )
    let model = LiveModelAxisState(
      commonCheckpointEventID: state.model.commonCheckpointEventID,
      commonCheckpoint: state.model.commonCheckpoint,
      variants: state.model.variants,
      selectionEventID: state.model.selectionEventID,
      selection: state.model.selection,
      budget: LiveBudgetState(
        maximum: modelPolicy.maximumBudget,
        reserved: .zero,
        charged: charged
      )
    )
    return LiveEpisodeState(
      passport: state.passport,
      nextSequence: state.nextSequence,
      events: state.events,
      model: model,
      transition: state.transition,
      latestBudgetCheckpoint: state.latestBudgetCheckpoint,
      confirmedGeneration: state.confirmedGeneration,
      continuation: state.continuation
    )
  }

  private func modelPolicy(
    executionMode: LiveExecutionMode,
    moneyUnit: LiveMoneyUnit,
    maximum: LiveBudget,
    reservation: LiveBudget
  ) throws -> LiveModelPolicy {
    let fixture = try LiveEpisodeFixture.run()
    let original = fixture.passport.modelPolicy
    return LiveModelPolicy(
      profileID: original.profileID,
      executionMode: executionMode,
      providerIdentity: original.providerIdentity,
      disclosure: original.disclosure,
      moneyUnit: moneyUnit,
      maximumBudget: maximum,
      perInvocationReservation: reservation,
      maximumVariants: original.maximumVariants
    )
  }

  private func proposal(
    requestID: String,
    reservation: LiveBudget
  ) -> LiveModelInvocationProposal {
    LiveModelInvocationProposal(
      requestID: requestID,
      variantID: "variant-budget-\(requestID)",
      parentCheckpointID: "checkpoint-budget-common",
      inputObjectID: "input-budget",
      inputSHA256: hash("1"),
      disclosureClass: .synthetic,
      purpose: "fixture_variant_comparison",
      reservation: reservation
    )
  }

  private func selectionPayload() -> LiveModelSelectionRecorded {
    LiveModelSelectionRecorded(
      selectionID: "selection-negative-fixture",
      selectedVariantID: "variant-a",
      sourceResponseID: "response-variant-a",
      sourceIntentID: "intent-variant-a",
      consideredVariantIDs: ["variant-a", "variant-b"],
      basisVerificationIDs: ["verification-variant-a", "verification-variant-b"]
    )
  }

  private func eventIndex(
    in fixture: LiveEpisodeFixtureResult,
    where predicate: (LiveEpisodeEvent) -> Bool
  ) throws -> Int {
    try XCTUnwrap(fixture.events.firstIndex(where: predicate))
  }

  private func makeEvent(
    in state: LiveEpisodeState,
    eventID: String,
    payload: LiveEpisodeEventPayload
  ) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      episodeID: state.passport.episodeID,
      eventID: eventID,
      sequence: state.nextSequence,
      payload: payload
    )
  }

  private func replacingEvent(
    _ event: LiveEpisodeEvent,
    schemaVersion: Int? = nil,
    episodeID: String? = nil,
    sequence: Int64? = nil,
    payload: LiveEpisodeEventPayload? = nil
  ) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      schemaIdentity: event.schemaIdentity,
      schemaVersion: schemaVersion ?? event.schemaVersion,
      episodeID: episodeID ?? event.episodeID,
      eventID: event.eventID,
      sequence: sequence ?? event.sequence,
      payload: payload ?? event.payload
    )
  }

  private func replacingPassport(
    _ passport: LiveEpisodePassport,
    schemaVersion: Int? = nil,
    modelPolicy: LiveModelPolicy? = nil
  ) -> LiveEpisodePassport {
    LiveEpisodePassport(
      schemaIdentity: passport.schemaIdentity,
      schemaVersion: schemaVersion ?? passport.schemaVersion,
      episodeID: passport.episodeID,
      goal: passport.goal,
      context: passport.context,
      modelPolicy: modelPolicy ?? passport.modelPolicy,
      actionAllowlist: passport.actionAllowlist,
      verificationCriteria: passport.verificationCriteria,
      checkpointPolicy: passport.checkpointPolicy,
      terminalOutcomes: passport.terminalOutcomes
    )
  }

  private func evidence(_ identifier: String, _ hex: Character) -> LiveEvidenceObject {
    LiveEvidenceObject(evidenceID: identifier, evidenceSHA256: hash(hex))
  }

  private func budget(
    _ calls: Int64,
    _ input: Int64,
    _ output: Int64,
    _ wall: Int64,
    _ compute: Int64,
    _ money: Int64
  ) -> LiveBudget {
    LiveBudget(
      calls: calls,
      inputTokens: input,
      outputTokens: output,
      wallClockMilliseconds: wall,
      computeUnits: compute,
      moneyMicrounits: money
    )
  }

  private func hash(_ hex: Character) -> String {
    "sha256:" + String(repeating: String(hex), count: 64)
  }

  private func assertTransitionMismatch(
    _ event: LiveEpisodeEvent,
    in state: LiveEpisodeState,
    file: StaticString = (#fileID),
    line: UInt = #line
  ) {
    assertLiveError(.transitionEvidenceMismatch, file: file, line: line) {
      _ = try LiveEpisodeReducer.applying(event, to: state)
    }
  }

  private func assertLiveError(
    _ expected: LiveEpisodeError,
    file: StaticString = (#fileID),
    line: UInt = #line,
    _ operation: () throws -> Void
  ) {
    XCTAssertThrowsError(try operation(), file: file, line: line) { error in
      XCTAssertEqual(error as? LiveEpisodeError, expected, file: file, line: line)
    }
  }
}
