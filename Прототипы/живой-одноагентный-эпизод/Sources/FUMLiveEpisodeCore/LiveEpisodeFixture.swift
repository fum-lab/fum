import Foundation

public enum LiveEpisodeFixtureError: Error, Equatable, Sendable {
  case unexpectedPlannerDecision
  case invariantViolation(String)
}

public struct LiveEpisodeFixtureResult: Equatable, Sendable {
  public let passport: LiveEpisodePassport
  public let events: [LiveEpisodeEvent]
  public let state: LiveEpisodeState

  public init(
    passport: LiveEpisodePassport,
    events: [LiveEpisodeEvent],
    state: LiveEpisodeState
  ) {
    self.passport = passport
    self.events = events
    self.state = state
  }
}

public enum LiveEpisodeFixture {
  public static func run() throws -> LiveEpisodeFixtureResult {
    let provider = LiveProviderIdentity(
      providerID: "fum.fixture.model-only.v1",
      interfaceID: "fum.fixture.in-memory.v1",
      modelID: "fixture-model",
      runtimeID: "FUMLiveEpisodeFixture/1"
    )
    let reservation = LiveBudget(
      calls: 1,
      inputTokens: 8,
      outputTokens: 8,
      wallClockMilliseconds: 500,
      computeUnits: 500,
      moneyMicrounits: 0
    )
    let passport = LiveEpisodePassport(
      episodeID: "episode-two-variant-fixture",
      goal: LiveEpisodeGoal(
        goalID: "goal-compare-two-variants",
        summary: "Сравнить два model-only-варианта, не исполняя ожидающий переход."
      ),
      context: LiveEpisodeContext(
        objectID: "context-two-variant-fixture",
        contentSHA256: hash("1"),
        disclosureClass: .synthetic,
        purpose: "fixture_variant_comparison"
      ),
      modelPolicy: LiveModelPolicy(
        profileID: "fum.fixture.live-episode-budget.v1",
        executionMode: .local,
        providerIdentity: provider,
        disclosure: LiveDisclosurePolicy(
          allowedClasses: [.synthetic],
          maximumInputBytes: 4_096,
          allowedPurposes: ["fixture_variant_comparison"]
        ),
        moneyUnit: .none,
        maximumBudget: LiveBudget(
          calls: 2,
          inputTokens: 16,
          outputTokens: 16,
          wallClockMilliseconds: 1_000,
          computeUnits: 1_000,
          moneyMicrounits: 0
        ),
        perInvocationReservation: reservation,
        maximumVariants: 3
      ),
      actionAllowlist: [
        LiveAllowedAction(
          allowanceID: "allow-store-candidate",
          operation: "store_candidate",
          adapterID: "fixture-inert-adapter",
          effectClass: "external_write"
        )
      ],
      verificationCriteria: [
        LiveVerificationCriterion(
          criterionID: "criterion-variant-origin",
          subject: "Model-only-ответ и строго разобранное намерение имеют общее происхождение.",
          verifierID: "fixture-pure-verifier",
          expectedResult: "passed"
        )
      ],
      checkpointPolicy: LiveCheckpointPolicy(
        checkpointOnBudgetRejection: true,
        requireCheckpointForTransitionConfirmation: true,
        requireConfirmedGenerationForContinuation: true
      ),
      terminalOutcomes: [.completed, .needsInput, .budgetExhausted, .failed]
    )

    let coordinates = LiveTransitionCoordinates(
      episodeID: passport.episodeID,
      transitionID: "transition-store-candidate",
      objectID: "candidate-record",
      expectedEffectSHA256: hash("2")
    )
    var state = try LiveEpisodeReducer.initialState(passport: passport)

    func event(_ eventID: String, _ payload: LiveEpisodeEventPayload) -> LiveEpisodeEvent {
      LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: eventID,
        sequence: state.nextSequence,
        payload: payload
      )
    }

    func apply(_ next: LiveEpisodeEvent) throws {
      state = try LiveEpisodeReducer.applying(next, to: state)
    }

    try apply(
      event(
        "event-common-checkpoint",
        .modelCheckpointCreated(
          LiveModelCheckpointCreated(
            checkpointID: "checkpoint-common-ancestor",
            ancestorSHA256: hash("3")
          )
        )
      )
    )
    try apply(
      event(
        "event-pending-transition",
        .pendingTransitionDeclared(
          LivePendingTransitionDeclared(
            coordinates: coordinates,
            allowanceID: "allow-store-candidate",
            parentCheckpointID: "checkpoint-common-ancestor"
          )
        )
      )
    )

    let variantAIntent = LiveUntrustedActionIntent(
      intentID: "intent-variant-a",
      operation: "store_candidate",
      adapterID: "fixture-inert-adapter",
      effectClass: "external_write",
      objectID: coordinates.objectID,
      expectedEffectSHA256: coordinates.expectedEffectSHA256,
      argumentsSHA256: hash("4")
    )
    let variantBIntent = LiveUntrustedActionIntent(
      intentID: "intent-variant-b",
      operation: "store_candidate",
      adapterID: "fixture-inert-adapter",
      effectClass: "external_write",
      objectID: coordinates.objectID,
      expectedEffectSHA256: coordinates.expectedEffectSHA256,
      argumentsSHA256: hash("5")
    )

    try applyVariant(
      suffix: "a",
      intent: variantAIntent,
      provider: provider,
      reservation: reservation,
      passport: passport,
      state: &state
    )
    try applyVariant(
      suffix: "b",
      intent: variantBIntent,
      provider: provider,
      reservation: reservation,
      passport: passport,
      state: &state
    )

    let exhaustedProposal = LiveModelInvocationProposal(
      requestID: "request-variant-c",
      variantID: "variant-c",
      parentCheckpointID: "checkpoint-common-ancestor",
      inputObjectID: "input-variant-c",
      inputSHA256: hash("6"),
      disclosureClass: .synthetic,
      purpose: "fixture_variant_comparison",
      reservation: reservation
    )
    let plan = try LiveEpisodeReducer.planModelInvocation(
      exhaustedProposal,
      checkpointID: "checkpoint-budget-exhausted",
      in: state
    )
    guard case .checkpoint(let checkpoint) = plan else {
      throw LiveEpisodeFixtureError.unexpectedPlannerDecision
    }
    try apply(event("event-budget-checkpoint", .budgetCheckpointCreated(checkpoint)))

    try apply(
      event(
        "event-model-selection",
        .modelSelectionRecorded(
          LiveModelSelectionRecorded(
            selectionID: "selection-two-variant-fixture",
            selectedVariantID: "variant-a",
            sourceResponseID: "response-variant-a",
            sourceIntentID: "intent-variant-a",
            consideredVariantIDs: ["variant-a", "variant-b"],
            basisVerificationIDs: ["verification-variant-a", "verification-variant-b"]
          )
        )
      )
    )
    let generation = LiveGenerationConfirmed(
      generationID: "generation-after-selection",
      confirmedThroughSequence: state.nextSequence - 1,
      stateSHA256: hash("7")
    )
    try apply(event("event-generation-confirmed", .generationConfirmed(generation)))
    try apply(
      event(
        "event-continuation-decided",
        .continuationDecided(
          LiveContinuationDecided(
            decision: .budgetExhausted,
            generationID: generation.generationID,
            basisEventIDs: [
              "event-budget-checkpoint", "event-model-selection", "event-generation-confirmed",
            ],
            reason: "Два варианта проверены; следующий вызов не помещается в бюджет."
          )
        )
      )
    )

    guard state.model.variants.count == 2,
      state.model.selection?.status == .selectedInModel,
      state.model.selection?.selectedVariantID == "variant-a",
      state.transition?.phase == .awaitingConfirmation,
      state.latestBudgetCheckpoint?.checkpoint.reason == .insufficientBudget,
      !state.events.contains(where: {
        if case .modelRequestRecorded(let request) = $0.payload {
          return request.proposal.requestID == exhaustedProposal.requestID
        }
        return false
      })
    else {
      throw LiveEpisodeFixtureError.invariantViolation(
        "Фикстура нарушила независимость выбора, перехода или бюджетной точки."
      )
    }
    let replayed = try LiveEpisodeReducer.replay(passport: passport, events: state.events)
    guard replayed == state, let last = state.events.last else {
      throw LiveEpisodeFixtureError.invariantViolation(
        "Воспроизведение или идемпотентное повторение изменило состояние."
      )
    }
    let repeated = try LiveEpisodeReducer.applying(last, to: state)
    guard repeated == state else {
      throw LiveEpisodeFixtureError.invariantViolation(
        "Воспроизведение или идемпотентное повторение изменило состояние."
      )
    }
    return LiveEpisodeFixtureResult(passport: passport, events: state.events, state: state)
  }

  private static func applyVariant(
    suffix: String,
    intent: LiveUntrustedActionIntent,
    provider: LiveProviderIdentity,
    reservation: LiveBudget,
    passport: LiveEpisodePassport,
    state: inout LiveEpisodeState
  ) throws {
    let variantID = "variant-\(suffix)"
    let requestID = "request-variant-\(suffix)"
    let responseID = "response-variant-\(suffix)"
    let proposal = LiveModelInvocationProposal(
      requestID: requestID,
      variantID: variantID,
      parentCheckpointID: "checkpoint-common-ancestor",
      inputObjectID: "input-variant-\(suffix)",
      inputSHA256: hash(suffix == "a" ? "8" : "9"),
      disclosureClass: .synthetic,
      purpose: "fixture_variant_comparison",
      reservation: reservation
    )
    let plan = try LiveEpisodeReducer.planModelInvocation(
      proposal,
      checkpointID: "unused-checkpoint-\(suffix)",
      in: state
    )
    guard case .request(let request) = plan else {
      throw LiveEpisodeFixtureError.unexpectedPlannerDecision
    }
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        passport: passport,
        sequence: state.nextSequence,
        eventID: "event-request-variant-\(suffix)",
        payload: .modelRequestRecorded(request)
      ),
      to: state
    )
    let output = try LiveStrictIntentParser.canonicalOutput(for: intent)
    let response = LiveModelResponseRecorded(
      responseID: responseID,
      requestID: requestID,
      variantID: variantID,
      providerIdentity: provider,
      status: .completed,
      output: output,
      outputSHA256: LiveStrictIntentParser.sha256(of: output),
      charged: LiveBudget(
        calls: 1,
        inputTokens: 4,
        outputTokens: 4,
        wallClockMilliseconds: 100,
        computeUnits: 100,
        moneyMicrounits: 0
      )
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        passport: passport,
        sequence: state.nextSequence,
        eventID: "event-response-variant-\(suffix)",
        payload: .modelResponseRecorded(response)
      ),
      to: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        passport: passport,
        sequence: state.nextSequence,
        eventID: "event-intent-variant-\(suffix)",
        payload: .untrustedIntentParsed(
          LiveUntrustedIntentParsed(
            variantID: variantID,
            sourceResponseID: responseID,
            intent: intent
          )
        )
      ),
      to: state
    )
    state = try LiveEpisodeReducer.applying(
      makeEvent(
        passport: passport,
        sequence: state.nextSequence,
        eventID: "event-verification-variant-\(suffix)",
        payload: .verificationRecorded(
          LiveVerificationRecorded(
            verificationID: "verification-variant-\(suffix)",
            criterionID: "criterion-variant-origin",
            scope: .modelVariant,
            subjectID: variantID,
            coordinates: nil,
            status: .passed,
            evidence: LiveEvidenceObject(
              evidenceID: "evidence-variant-\(suffix)",
              evidenceSHA256: hash(suffix == "a" ? "a" : "b")
            )
          )
        )
      ),
      to: state
    )
  }

  private static func makeEvent(
    passport: LiveEpisodePassport,
    sequence: Int64,
    eventID: String,
    payload: LiveEpisodeEventPayload
  ) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: eventID,
      sequence: sequence,
      payload: payload
    )
  }

  private static func hash(_ character: Character) -> String {
    "sha256:" + String(repeating: String(character), count: 64)
  }
}
