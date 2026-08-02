import Foundation

@testable import FUMDistributedEpisodeMemory

enum SharedEpisodeSelectionFixture: String, CaseIterable, Sendable {
  case externalEvidence = "external_evidence"
  case assertionVote = "assertion_vote"
  case omitsDisagreement = "omits_disagreement"
}

enum SharedEpisodeResumptionPackageFixture: Sendable {
  case fresh
  case predecessor
}

struct SharedEpisodeTerminalFixture {
  let generation: SharedEpisodeGeneration
}

enum SharedEpisodeControlFixtures {
  static func selectionPrefix(
    correlatedCopyCount: Int,
    includeFailedVerification: Bool
  ) throws -> SharedEpisodeGeneration {
    try selectionPrefix(
      controlPlan: selectionFixtureControlPlan(),
      correlatedCopyCount: correlatedCopyCount,
      includeFailedVerification: includeFailedVerification
    )
  }

  static func appendSelection(
    named fixture: SharedEpisodeSelectionFixture,
    to prefix: SharedEpisodeGeneration
  ) throws -> SharedEpisodeGeneration {
    guard let selected = try selectionSteps(named: fixture, from: prefix).last else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Фикстура выбора не создала завершающее поколение."
      )
    }
    return selected
  }

  static func budgetBoundary(
    dimension: SharedEpisodeBudgetDimension,
    overBy: Int64
  ) throws -> (
    generation: SharedEpisodeGeneration,
    reservation: SharedEpisodeActionReservation,
    expectedRemaining: SharedEpisodeBudgetVector
  ) {
    guard overBy >= 0 else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Смещение бюджетной границы не может быть отрицательным."
      )
    }
    let maximum = SharedEpisodeBudgetVector(
      executors: dimension == .executors ? 1 : 2,
      rounds: dimension == .rounds ? 1 : 2,
      modelCalls: 8,
      toolCalls: 8,
      input: 8,
      output: 8
    )
    let handoffReserve: SharedEpisodeBudgetVector =
      overBy == 0
      ? .zero
      : SharedEpisodeBudgetVector(
        executors: dimension == .executors ? 0 : 1,
        rounds: dimension == .rounds ? 0 : 1,
        modelCalls: 1,
        toolCalls: 1,
        input: 1,
        output: 1
      )
    let prechargeBudget = SharedEpisodeBudgetVector(
      executors: 1,
      rounds: 1,
      modelCalls: 0,
      toolCalls: 0,
      input: 0,
      output: 0
    )
    let needsIdentityPrecharge =
      overBy > 0
      && (dimension == .executors || dimension == .rounds)
    let prechargeContinuation = SharedEpisodeContinuationCandidate(
      continuationID: "continuation.boundary.identity-precharge",
      kind: .modelOnly,
      safe: true,
      productive: true,
      budget: prechargeBudget
    )
    let plan = controlPlan(
      maximum: maximum,
      verificationReserve: .zero,
      handoffReserve: handoffReserve,
      continuations: needsIdentityPrecharge ? [prechargeContinuation] : [],
      distinguishingChecks: []
    )
    var generation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    if needsIdentityPrecharge {
      let precharge = SharedEpisodeActionReservation(
        permitID: "permit.boundary.identity-precharge",
        actionID: "action.boundary.identity-precharge",
        parentGenerationSHA256: try generationSHA256(generation),
        phase: .productive,
        kind: .modelOnly,
        executorID: "executor.boundary.identity-precharge",
        roundID: "round.boundary.identity-precharge",
        continuationID: prechargeContinuation.continuationID,
        distinguishingCheckID: nil,
        reserved: prechargeBudget
      )
      generation = try SharedEpisodeMemoryReducer.continuation(
        from: generation,
        control: .actionReserved(precharge)
      )
      let result = SharedEpisodeModelOnlyResult(
        resultID: "result.boundary.identity-precharge",
        parentGenerationSHA256: try generationSHA256(generation),
        permitID: precharge.permitID,
        continuationID: prechargeContinuation.continuationID,
        contentSHA256: fixtureSHA256("identity precharge")
      )
      generation = try SharedEpisodeMemoryReducer.continuation(
        from: generation,
        control: .modelOnlyCompleted(
          result,
          actionSettlement(for: precharge, actual: prechargeBudget)
        )
      )
    }
    let baseAmount: SharedEpisodeBudgetVector
    if needsIdentityPrecharge && dimension == .executors {
      baseAmount = SharedEpisodeBudgetVector(
        executors: 1,
        rounds: 0,
        modelCalls: 0,
        toolCalls: 0,
        input: 0,
        output: 0
      )
    } else if needsIdentityPrecharge && dimension == .rounds {
      baseAmount = SharedEpisodeBudgetVector(
        executors: 0,
        rounds: 1,
        modelCalls: 0,
        toolCalls: 0,
        input: 0,
        output: 0
      )
    } else {
      baseAmount = SharedEpisodeBudgetVector(
        executors: 1,
        rounds: 1,
        modelCalls: 0,
        toolCalls: 0,
        input: 0,
        output: 0
      )
    }
    let amount =
      needsIdentityPrecharge
      ? baseAmount
      : replacingBudgetComponent(
        in: baseAmount,
        dimension: dimension,
        with: maximum[dimension] + overBy
      )
    let reservation = SharedEpisodeActionReservation(
      permitID: "permit.boundary.\(dimension.rawValue).\(overBy)",
      actionID: "action.boundary.\(dimension.rawValue).\(overBy)",
      parentGenerationSHA256: try generationSHA256(generation),
      phase: .productive,
      kind: .contribution,
      executorID: dimension == .rounds && needsIdentityPrecharge
        ? "executor.boundary.identity-precharge"
        : "executor.boundary.\(dimension.rawValue)",
      roundID: dimension == .executors && needsIdentityPrecharge
        ? "round.boundary.identity-precharge"
        : "round.boundary.\(dimension.rawValue)",
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: amount
    )
    let currentRemaining = generation.state.budgetState.remaining
    let expectedRemaining = SharedEpisodeBudgetVector(
      executors: max(0, currentRemaining.executors - amount.executors),
      rounds: max(0, currentRemaining.rounds - amount.rounds),
      modelCalls: max(0, currentRemaining.modelCalls - amount.modelCalls),
      toolCalls: max(0, currentRemaining.toolCalls - amount.toolCalls),
      input: max(0, currentRemaining.input - amount.input),
      output: max(0, currentRemaining.output - amount.output)
    )
    return (generation, reservation, expectedRemaining)
  }

  static func appendBudgetExhaustedTerminal(
    blockedReservation: SharedEpisodeActionReservation,
    to generation: SharedEpisodeGeneration
  ) throws -> SharedEpisodeGeneration {
    guard
      let blockedDimension = blockedReservation.reserved.firstExceededDimension(
        comparedWith: generation.state.budgetState.remaining
      )
    else {
      throw SharedEpisodeMemoryError.invalidTerminal(
        "Фикстура не получила действие, превышающее доступный бюджет."
      )
    }
    let terminalExecutorID =
      blockedDimension == .executors
      ? generation.state.controlState.usedExecutorIDs.first
      : nil
    let terminalRoundID =
      blockedDimension == .rounds
      ? generation.state.controlState.usedRoundIDs.first
      : nil
    let prepared = try prepareTerminal(
      from: generation,
      suffix: "budget-exhausted",
      outcome: .budgetExhausted,
      executorID: terminalExecutorID,
      roundID: terminalRoundID
    ) { parentSHA256, reservedGeneration in
      let rebound = SharedEpisodeActionReservation(
        schemaVersion: blockedReservation.schemaVersion,
        permitID: blockedReservation.permitID,
        actionID: blockedReservation.actionID,
        parentGenerationSHA256: parentSHA256,
        phase: blockedReservation.phase,
        kind: blockedReservation.kind,
        executorID: blockedReservation.executorID,
        roundID: blockedReservation.roundID,
        continuationID: blockedReservation.continuationID,
        distinguishingCheckID: blockedReservation.distinguishingCheckID,
        reserved: blockedReservation.reserved
      )
      guard
        let witness = try SharedEpisodeControlKernel.budgetFailureWitness(
          for: rebound,
          state: reservedGeneration.state.controlState,
          plan: reservedGeneration.seed.controlPlan
        )
      else {
        throw SharedEpisodeMemoryError.invalidTerminal(
          "Фикстура не воспроизводит исчерпанную размерность бюджета."
        )
      }
      return SharedEpisodeTerminalReason(
        code: .budgetLimitReached,
        budgetDimension: witness.dimension,
        budgetRequiredUnits: witness.required,
        budgetAvailableUnits: witness.available,
        blockedReservation: rebound,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: [rebound.actionID]
      )
    }
    return try SharedEpisodeMemoryReducer.continuation(
      from: prepared.generation,
      control: .terminal(prepared.terminal, prepared.settlement)
    )
  }

  static func fullyProtectedReserve() throws -> (
    generation: SharedEpisodeGeneration,
    productiveReservation: SharedEpisodeActionReservation,
    verificationReservation: SharedEpisodeActionReservation,
    handoffReservation: SharedEpisodeActionReservation
  ) {
    let reserve = uniformBudget(1)
    let plan = controlPlan(
      maximum: uniformBudget(2),
      verificationReserve: reserve,
      handoffReserve: reserve,
      continuations: [],
      distinguishingChecks: []
    )
    let generation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    let parentSHA256 = try generationSHA256(generation)
    return (
      generation,
      reservation(
        suffix: "protected.productive",
        parentGenerationSHA256: parentSHA256,
        phase: .productive,
        kind: .contribution,
        reserved: reserve
      ),
      reservation(
        suffix: "protected.verification",
        parentGenerationSHA256: parentSHA256,
        phase: .verification,
        kind: .selection,
        reserved: reserve
      ),
      reservation(
        suffix: "protected.handoff",
        parentGenerationSHA256: parentSHA256,
        phase: .handoff,
        kind: .transition,
        reserved: reserve
      )
    )
  }

  static func modelOnlySettlement() throws -> (
    generation: SharedEpisodeGeneration,
    reservation: SharedEpisodeActionReservation,
    result: SharedEpisodeModelOnlyResult,
    overSettlement: SharedEpisodeActionSettlement,
    settlement: SharedEpisodeActionSettlement
  ) {
    let generation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let candidate = try requiredModelOnlyCandidate(in: generation.seed.controlPlan)
    let reservation = modelOnlyReservation(
      parentGenerationSHA256: try generationSHA256(generation),
      candidate: candidate,
      suffix: "settlement"
    )
    let result = SharedEpisodeModelOnlyResult(
      resultID: "result.model-only.settlement",
      parentGenerationSHA256: reservation.parentGenerationSHA256,
      permitID: reservation.permitID,
      continuationID: candidate.continuationID,
      contentSHA256: fixtureSHA256("model-only settlement result")
    )
    let actual = SharedEpisodeBudgetVector(
      executors: candidate.budget.executors,
      rounds: candidate.budget.rounds,
      modelCalls: candidate.budget.modelCalls,
      toolCalls: candidate.budget.toolCalls,
      input: candidate.budget.input / 2,
      output: candidate.budget.output / 2
    )
    let settlement = actionSettlement(for: reservation, actual: actual)
    let overSettlement = actionSettlement(
      for: reservation,
      actual: SharedEpisodeBudgetVector(
        executors: actual.executors,
        rounds: actual.rounds,
        modelCalls: actual.modelCalls,
        toolCalls: actual.toolCalls,
        input: actual.input,
        output: candidate.budget.output + 1
      )
    )
    return (generation, reservation, result, overSettlement, settlement)
  }

  static func pendingTransitionModelOnlyTrace() throws -> (
    afterTransitionParked: SharedEpisodeGeneration,
    afterModelOnlyContinuation: SharedEpisodeGeneration
  ) {
    let prefix = try selectionPrefix(
      correlatedCopyCount: 1,
      includeFailedVerification: false
    )
    let selected = try appendSelection(named: .externalEvidence, to: prefix)

    let transitionReservation = reservation(
      suffix: "pending-transition",
      parentGenerationSHA256: try generationSHA256(selected),
      phase: .handoff,
      kind: .transition,
      reserved: unitBudget
    )
    let transitionReserved = try SharedEpisodeMemoryReducer.continuation(
      from: selected,
      control: .actionReserved(transitionReservation)
    )
    let transition = SharedEpisodeParkedTransition(
      transitionID: "transition.pending.fixture",
      transitionVersion: 1,
      parentGenerationSHA256: try generationSHA256(transitionReserved),
      permitID: transitionReservation.permitID,
      objectID: "external.object.fixture",
      objectVersion: "version.1",
      expectedEffectSHA256: fixtureSHA256("pending external effect"),
      confirmationPolicyID: "confirmation.policy.fixture",
      phase: .awaitingConfirmation,
      userConfirmed: false,
      authorized: false
    )
    let parked = try SharedEpisodeMemoryReducer.continuation(
      from: transitionReserved,
      control: .transitionParked(
        transition,
        actionSettlement(
          for: transitionReservation,
          actual: identitySettlementBudget(for: transitionReservation)
        )
      )
    )

    let candidate = try requiredModelOnlyCandidate(in: parked.seed.controlPlan)
    let modelReservation = modelOnlyReservation(
      parentGenerationSHA256: try generationSHA256(parked),
      candidate: candidate,
      suffix: "after-pending-transition"
    )
    let modelReserved = try SharedEpisodeMemoryReducer.continuation(
      from: parked,
      control: .actionReserved(modelReservation)
    )
    let result = SharedEpisodeModelOnlyResult(
      resultID: "result.model-only.after-pending-transition",
      parentGenerationSHA256: try generationSHA256(modelReserved),
      permitID: modelReservation.permitID,
      continuationID: candidate.continuationID,
      contentSHA256: fixtureSHA256("safe model-only continuation")
    )
    let continued = try SharedEpisodeMemoryReducer.continuation(
      from: modelReserved,
      control: .modelOnlyCompleted(
        result,
        actionSettlement(for: modelReservation, actual: candidate.budget)
      )
    )
    return (parked, continued)
  }

  static func needsInputScenario(
    safeProductiveContinuationsExhausted: Bool,
    usefulContinuationInFlight: Bool = false
  ) throws -> (
    generation: SharedEpisodeGeneration,
    terminal: SharedEpisodeTerminalRecord,
    settlement: SharedEpisodeActionSettlement
  ) {
    let continuations: [SharedEpisodeContinuationCandidate]
    if safeProductiveContinuationsExhausted {
      continuations = []
    } else {
      continuations = [
        SharedEpisodeContinuationCandidate(
          continuationID: "continuation.needs-input.model-only",
          kind: .modelOnly,
          safe: true,
          productive: true,
          budget: unitBudget
        )
      ]
    }
    let plan = controlPlan(
      maximum: uniformBudget(10),
      verificationReserve: uniformBudget(2),
      handoffReserve: uniformBudget(4),
      continuations: continuations,
      distinguishingChecks: []
    )
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    let transitionReservation = reservation(
      suffix: "needs-input.transition",
      parentGenerationSHA256: try generationSHA256(foundation),
      phase: .handoff,
      kind: .transition,
      reserved: unitBudget
    )
    let transitionReserved = try SharedEpisodeMemoryReducer.continuation(
      from: foundation,
      control: .actionReserved(transitionReservation)
    )
    let transition = SharedEpisodeParkedTransition(
      transitionID: "transition.needs-input.fixture",
      transitionVersion: 1,
      parentGenerationSHA256: try generationSHA256(transitionReserved),
      permitID: transitionReservation.permitID,
      objectID: "external.input.fixture",
      objectVersion: "version.1",
      expectedEffectSHA256: fixtureSHA256("needs input effect"),
      confirmationPolicyID: "confirmation.policy.needs-input",
      phase: .awaitingConfirmation,
      userConfirmed: false,
      authorized: false
    )
    let parked = try SharedEpisodeMemoryReducer.continuation(
      from: transitionReserved,
      control: .transitionParked(
        transition,
        actionSettlement(for: transitionReservation, actual: unitBudget)
      )
    )
    var terminalParent = parked
    if usefulContinuationInFlight {
      guard let candidate = continuations.first else {
        throw SharedEpisodeMemoryError.invalidControl(
          "Фикстура не нашла полезное продолжение для in-flight сценария."
        )
      }
      let modelReservation = modelOnlyReservation(
        parentGenerationSHA256: try generationSHA256(terminalParent),
        candidate: candidate,
        suffix: "needs-input.in-flight"
      )
      terminalParent = try SharedEpisodeMemoryReducer.continuation(
        from: terminalParent,
        control: .actionReserved(modelReservation)
      )
    }
    let prepared = try prepareTerminal(
      from: terminalParent,
      suffix: safeProductiveContinuationsExhausted
        ? "needs-input.exhausted" : "needs-input.premature",
      outcome: .needsInput
    ) { _, _ in
      SharedEpisodeTerminalReason(
        code: .pendingTransitionRequiresInput,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: transition.transitionID,
        failureCode: nil,
        relatedIDs: [transition.transitionID]
      )
    }
    return (prepared.generation, prepared.terminal, prepared.settlement)
  }

  static func unresolvedConflictScenario(
    distinguishingChecksExhausted: Bool,
    distinguishingCheckInFlight: Bool = false
  ) throws -> (
    generation: SharedEpisodeGeneration,
    terminal: SharedEpisodeTerminalRecord,
    settlement: SharedEpisodeActionSettlement
  ) {
    let exactCheckBudget = try meteredVerificationBudget(named: .inconclusive)
    let maximum = roomyMaximumBudget
    let checkBudget =
      distinguishingChecksExhausted
      ? replacingBudgetComponent(
        in: exactCheckBudget,
        dimension: .output,
        with: maximum.output
      ) : exactCheckBudget
    let plan = controlPlan(
      maximum: maximum,
      verificationReserve: roomyVerificationReserve,
      handoffReserve: roomyHandoffReserve,
      continuations: try selectionFixtureContinuations(includeModelOnly: false),
      distinguishingChecks: [
        SharedEpisodeDistinguishingCheck(
          checkID: "check.unresolved.fixture",
          safe: true,
          productive: true,
          budget: checkBudget
        )
      ]
    )
    let prefix = try selectionPrefix(
      controlPlan: plan,
      correlatedCopyCount: 1,
      includeFailedVerification: true
    )
    let selected = try appendSelection(named: .externalEvidence, to: prefix)
    var terminalParent = selected
    if distinguishingCheckInFlight {
      let checkReservation = reservation(
        suffix: "unresolved.in-flight",
        parentGenerationSHA256: try generationSHA256(terminalParent),
        phase: .verification,
        kind: .verification,
        distinguishingCheckID: "check.unresolved.fixture",
        reserved: checkBudget
      )
      terminalParent = try SharedEpisodeMemoryReducer.continuation(
        from: terminalParent,
        control: .actionReserved(checkReservation)
      )
    }
    let prepared = try prepareTerminal(
      from: terminalParent,
      suffix: distinguishingChecksExhausted
        ? "unresolved.exhausted" : "unresolved.premature",
      outcome: .unresolvedConflict
    ) { _, reservedGeneration in
      SharedEpisodeTerminalReason(
        code: .noDistinguishingCheck,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: reservedGeneration.state.unresolvedDisagreementIDs
      )
    }
    return (prepared.generation, prepared.terminal, prepared.settlement)
  }

  static func terminalEpisode(
    outcome: SharedEpisodeTerminalOutcome
  ) throws -> SharedEpisodeTerminalFixture {
    switch outcome {
    case .goalMet:
      let prefix = try selectionPrefix(
        correlatedCopyCount: 0,
        includeFailedVerification: false
      )
      let selected = try appendSelection(named: .externalEvidence, to: prefix)
      let prepared = try prepareTerminal(
        from: selected,
        suffix: "goal-met",
        outcome: .goalMet
      ) { _, reservedGeneration in
        SharedEpisodeTerminalReason(
          code: .goalCriteriaMet,
          budgetDimension: nil,
          blockedReservation: nil,
          pendingTransitionID: nil,
          failureCode: nil,
          relatedIDs: reservedGeneration.state.selectionDecisions
            .compactMap(\.selectedContributionID)
            .sorted()
        )
      }
      return SharedEpisodeTerminalFixture(
        generation: try applyPreparedTerminal(prepared)
      )

    case .budgetExhausted:
      let boundary = try budgetBoundary(dimension: .modelCalls, overBy: 1)
      return SharedEpisodeTerminalFixture(
        generation: try appendBudgetExhaustedTerminal(
          blockedReservation: boundary.reservation,
          to: boundary.generation
        )
      )

    case .needsInput:
      let scenario = try needsInputScenario(
        safeProductiveContinuationsExhausted: true
      )
      return SharedEpisodeTerminalFixture(
        generation: try SharedEpisodeMemoryReducer.continuation(
          from: scenario.generation,
          control: .terminal(scenario.terminal, scenario.settlement)
        )
      )

    case .unresolvedConflict:
      let scenario = try unresolvedConflictScenario(
        distinguishingChecksExhausted: true
      )
      return SharedEpisodeTerminalFixture(
        generation: try SharedEpisodeMemoryReducer.continuation(
          from: scenario.generation,
          control: .terminal(scenario.terminal, scenario.settlement)
        )
      )

    case .failed:
      let foundation = try SharedEpisodeMemoryReducer.foundation(
        seed: SharedEpisodeMemoryFixtures.seed()
      )
      let prepared = try prepareTerminal(
        from: foundation,
        suffix: "failed",
        outcome: .failed
      ) { _, _ in
        SharedEpisodeTerminalReason(
          code: .executionFailed,
          budgetDimension: nil,
          blockedReservation: nil,
          pendingTransitionID: nil,
          failureCode: "failure.fixture",
          relatedIDs: ["failure.fixture"]
        )
      }
      return SharedEpisodeTerminalFixture(
        generation: try applyPreparedTerminal(prepared)
      )
    }
  }

  static func everyCommandAfterTerminal(
    _ terminal: SharedEpisodeGeneration
  ) throws -> [SharedEpisodeControlCommand] {
    let parentSHA256 = try generationSHA256(terminal)
    let genericReservation = reservation(
      suffix: "post-terminal.action-reserved",
      parentGenerationSHA256: parentSHA256,
      phase: .productive,
      kind: .contribution,
      reserved: unitBudget
    )
    let contribution = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: parentSHA256
    )
    let verification = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: parentSHA256
    )
    let genericSettlement = SharedEpisodeActionSettlement(
      permitID: "permit.post-terminal.generic",
      actionID: "action.post-terminal.generic",
      actual: .zero
    )
    let decision = SharedEpisodeSelectionDecision(
      decisionID: "decision.post-terminal",
      parentGenerationSHA256: parentSHA256,
      selectionContextSHA256: fixtureSHA256("post-terminal selection context"),
      selectionPolicyID: terminal.seed.controlPlan.selectionPolicyID,
      selectionPlanArtifactID: terminal.seed.controlPlan.selectionPlanArtifactID,
      stopPolicyID: terminal.seed.controlPlan.stopPolicyID,
      selectorID: "selector.post-terminal",
      selectorRoleID: "selector.role.post-terminal",
      criteriaArtifactID: "criteria.main",
      criteriaSHA256: fixtureSHA256("post-terminal criteria"),
      criterionIDs: [],
      considerations: [],
      disagreementDispositions: [],
      selectedContributionID: nil,
      basis: .verifiedEvidence,
      status: .selectedInModel,
      userConfirmed: false,
      authorized: false
    )
    let result = SharedEpisodeModelOnlyResult(
      resultID: "result.post-terminal",
      parentGenerationSHA256: parentSHA256,
      permitID: genericSettlement.permitID,
      continuationID: "continuation.post-terminal",
      contentSHA256: fixtureSHA256("post-terminal model result")
    )
    let transition = SharedEpisodeParkedTransition(
      transitionID: "transition.post-terminal",
      transitionVersion: 1,
      parentGenerationSHA256: parentSHA256,
      permitID: genericSettlement.permitID,
      objectID: "external.object.post-terminal",
      objectVersion: "version.1",
      expectedEffectSHA256: fixtureSHA256("post-terminal external effect"),
      confirmationPolicyID: "confirmation.policy.post-terminal",
      phase: .awaitingConfirmation,
      userConfirmed: false,
      authorized: false
    )
    let terminalRecord = SharedEpisodeTerminalRecord(
      terminalID: "terminal.post-terminal",
      parentGenerationSHA256: parentSHA256,
      permitID: genericSettlement.permitID,
      outcome: .failed,
      reason: SharedEpisodeTerminalReason(
        code: .executionFailed,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: "failure.post-terminal",
        relatedIDs: []
      ),
      unresolvedDisagreementIDs: terminal.state.unresolvedDisagreementIDs
    )
    return [
      .actionReserved(genericReservation),
      .contribution(contribution, genericSettlement),
      .verification(verification, genericSettlement),
      .selection(decision, genericSettlement),
      .modelOnlyCompleted(result, genericSettlement),
      .transitionParked(transition, genericSettlement),
      .terminal(terminalRecord, genericSettlement),
    ]
  }

  static func canonicalTerminalTrace() throws -> (
    generations: [SharedEpisodeGeneration],
    finalState: SharedEpisodeState
  ) {
    var generations = try selectionPrefixTrace(
      controlPlan: selectionFixtureControlPlan(),
      correlatedCopyCount: 1,
      includeFailedVerification: true
    )
    guard let prefix = generations.last else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Каноническая трасса не получила foundation."
      )
    }
    let selectionGenerations = try selectionSteps(
      named: .externalEvidence,
      from: prefix
    )
    generations.append(contentsOf: selectionGenerations)
    guard let selected = generations.last else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Каноническая трасса не получила решение выбора."
      )
    }

    let candidate = try requiredModelOnlyCandidate(in: selected.seed.controlPlan)
    let openReservation = modelOnlyReservation(
      parentGenerationSHA256: try generationSHA256(selected),
      candidate: candidate,
      suffix: "canonical.open"
    )
    let withOpenReservation = try SharedEpisodeMemoryReducer.continuation(
      from: selected,
      control: .actionReserved(openReservation)
    )
    generations.append(withOpenReservation)

    let prepared = try prepareTerminal(
      from: withOpenReservation,
      suffix: "canonical.failed",
      outcome: .failed
    ) { _, reservedGeneration in
      SharedEpisodeTerminalReason(
        code: .executionFailed,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: "failure.canonical-fixture",
        relatedIDs: reservedGeneration.state.unresolvedDisagreementIDs
      )
    }
    generations.append(prepared.generation)
    let final = try applyPreparedTerminal(prepared)
    generations.append(final)
    return (generations, final.state)
  }

  static func resumedSeed(
    from predecessor: SharedEpisodeGeneration,
    runGenerationID: String,
    package: SharedEpisodeResumptionPackageFixture,
    predecessorTerminalGenerationSHA256: String
  ) throws -> SharedEpisodeMemorySeed {
    let activeWorkPackageArtifactID: String
    switch package {
    case .predecessor:
      activeWorkPackageArtifactID = predecessor.seed.activeWorkPackageArtifactID
    case .fresh:
      guard
        let freshPackage =
          (predecessor.seed.artifacts
          .filter {
            $0.kind == "work_package"
              && $0.artifactID != predecessor.seed.activeWorkPackageArtifactID
          }
          .sorted(by: { $0.artifactID < $1.artifactID }))
          .first
      else {
        throw SharedEpisodeMemoryError.invalidResumption(
          "Фикстура не нашла свежий рабочий пакет."
        )
      }
      activeWorkPackageArtifactID = freshPackage.artifactID
    }
    return SharedEpisodeMemorySeed(
      schemaVersion: predecessor.seed.schemaVersion,
      episodeID: predecessor.seed.episodeID,
      runGenerationID: runGenerationID,
      activeWorkPackageArtifactID: activeWorkPackageArtifactID,
      predecessorTerminalGenerationSHA256: predecessorTerminalGenerationSHA256,
      controlPlan: predecessor.seed.controlPlan,
      passportArtifactID: predecessor.seed.passportArtifactID,
      passportSHA256: predecessor.seed.passportSHA256,
      artifactManifestSHA256: predecessor.seed.artifactManifestSHA256,
      artifacts: predecessor.seed.artifacts
    )
  }
}

extension SharedEpisodeControlFixtures {
  fileprivate typealias PreparedTerminal = (
    generation: SharedEpisodeGeneration,
    terminal: SharedEpisodeTerminalRecord,
    settlement: SharedEpisodeActionSettlement
  )

  fileprivate static let unitBudget = SharedEpisodeBudgetVector(
    executors: 1,
    rounds: 1,
    modelCalls: 1,
    toolCalls: 1,
    input: 1,
    output: 1
  )

  static func selectionPrefix(
    controlPlan: SharedEpisodeControlPlan,
    correlatedCopyCount: Int,
    includeFailedVerification: Bool
  ) throws -> SharedEpisodeGeneration {
    guard
      let generation = try selectionPrefixTrace(
        controlPlan: controlPlan,
        correlatedCopyCount: correlatedCopyCount,
        includeFailedVerification: includeFailedVerification
      ).last
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Фикстура выбора не создала исходное поколение."
      )
    }
    return generation
  }

  fileprivate static func selectionPrefixTrace(
    controlPlan: SharedEpisodeControlPlan,
    correlatedCopyCount: Int,
    includeFailedVerification: Bool
  ) throws -> [SharedEpisodeGeneration] {
    guard correlatedCopyCount >= 0 else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Число коррелированных копий не может быть отрицательным."
      )
    }
    var current = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: controlPlan)
    )
    var generations = [current]

    let primaryDraft = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: generationSHA256(current)
    )
    let primaryBudget = try SharedEpisodeControlKernel.meteredUsage(
      for: primaryDraft,
      executors: 1,
      rounds: 1
    )
    let primaryReservation = reservation(
      suffix: "setup.contribution.primary",
      parentGenerationSHA256: try generationSHA256(current),
      phase: .productive,
      kind: .contribution,
      reserved: primaryBudget
    )
    current = try SharedEpisodeMemoryReducer.continuation(
      from: current,
      control: .actionReserved(primaryReservation)
    )
    generations.append(current)
    let primary = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: generationSHA256(current)
    )
    current = try SharedEpisodeMemoryReducer.continuation(
      from: current,
      control: .contribution(
        primary,
        actionSettlement(for: primaryReservation, actual: primaryBudget)
      )
    )
    generations.append(current)

    if correlatedCopyCount > 0 {
      for index in 1...correlatedCopyCount {
        let copyDraft = try SharedEpisodeMemoryFixtures.correlatedCopy(
          index: index,
          parentGenerationSHA256: generationSHA256(current)
        )
        let copyBudget = try SharedEpisodeControlKernel.meteredUsage(
          for: copyDraft,
          executors: 1,
          rounds: 1
        )
        let copyReservation = reservation(
          suffix: "setup.contribution.correlated-copy.\(index)",
          parentGenerationSHA256: try generationSHA256(current),
          phase: .productive,
          kind: .contribution,
          reserved: copyBudget
        )
        current = try SharedEpisodeMemoryReducer.continuation(
          from: current,
          control: .actionReserved(copyReservation)
        )
        generations.append(current)
        let copy = try SharedEpisodeMemoryFixtures.correlatedCopy(
          index: index,
          parentGenerationSHA256: generationSHA256(current)
        )
        current = try SharedEpisodeMemoryReducer.continuation(
          from: current,
          control: .contribution(
            copy,
            actionSettlement(for: copyReservation, actual: copyBudget)
          )
        )
        generations.append(current)
      }
    }

    let externalCandidate = try requiredContinuation(
      "continuation.setup.verification.external",
      in: controlPlan
    )
    let externalReservation = reservation(
      suffix: "setup.verification.external",
      parentGenerationSHA256: try generationSHA256(current),
      phase: .verification,
      kind: .verification,
      continuationID: externalCandidate.continuationID,
      reserved: externalCandidate.budget
    )
    current = try SharedEpisodeMemoryReducer.continuation(
      from: current,
      control: .actionReserved(externalReservation)
    )
    generations.append(current)
    let externalVerification = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: generationSHA256(current)
    )
    current = try SharedEpisodeMemoryReducer.continuation(
      from: current,
      control: .verification(
        externalVerification,
        actionSettlement(for: externalReservation, actual: externalCandidate.budget)
      )
    )
    generations.append(current)

    if includeFailedVerification {
      let failedCandidate = try requiredContinuation(
        "continuation.setup.verification.failed",
        in: controlPlan
      )
      let failedReservation = reservation(
        suffix: "setup.verification.failed",
        parentGenerationSHA256: try generationSHA256(current),
        phase: .verification,
        kind: .verification,
        continuationID: failedCandidate.continuationID,
        reserved: failedCandidate.budget
      )
      current = try SharedEpisodeMemoryReducer.continuation(
        from: current,
        control: .actionReserved(failedReservation)
      )
      generations.append(current)
      let failedVerification = try SharedEpisodeMemoryFixtures.verification(
        named: .failed,
        parentGenerationSHA256: generationSHA256(current)
      )
      current = try SharedEpisodeMemoryReducer.continuation(
        from: current,
        control: .verification(
          failedVerification,
          actionSettlement(for: failedReservation, actual: failedCandidate.budget)
        )
      )
      generations.append(current)
    }
    return generations
  }

  fileprivate static func selectionSteps(
    named fixture: SharedEpisodeSelectionFixture,
    from prefix: SharedEpisodeGeneration
  ) throws -> [SharedEpisodeGeneration] {
    let selectionReservation = reservation(
      suffix: "selection.\(fixture.rawValue)",
      parentGenerationSHA256: try generationSHA256(prefix),
      phase: .productive,
      kind: .selection,
      reserved: unitBudget
    )
    let reserved = try SharedEpisodeMemoryReducer.continuation(
      from: prefix,
      control: .actionReserved(selectionReservation)
    )
    let decision = try selectionDecision(
      named: fixture,
      generation: reserved,
      parentGenerationSHA256: generationSHA256(reserved)
    )
    let selected = try SharedEpisodeMemoryReducer.continuation(
      from: reserved,
      control: .selection(
        decision,
        actionSettlement(for: selectionReservation, actual: unitBudget)
      )
    )
    return [reserved, selected]
  }

  fileprivate static func selectionEvidenceContext(
    _ generation: SharedEpisodeGeneration
  ) throws -> SharedEpisodeSelectionEvidenceContext {
    guard
      let criteriaArtifact = generation.seed.artifacts.first(where: {
        $0.artifactID == "criteria.main"
      })
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Фикстура не нашла артефакт критериев."
      )
    }
    let criteriaDocument = try JSONDecoder().decode(
      SharedEpisodeVerificationCriteriaDocument.self,
      from: criteriaArtifact.decodedData()
    )
    let verifications = generation.state.verifications
    let assessmentByID = generation.state.verificationReport.assessmentsByRecordID
    return SharedEpisodeSelectionEvidenceContext(
      criteriaArtifactID: criteriaArtifact.artifactID,
      criteriaSHA256: criteriaArtifact.contentSHA256,
      criterionIDs: criteriaDocument.criteria.map(\.criterionID).sorted(),
      contributions: try generation.state.contributions.map { contribution in
        SharedEpisodeSelectionContributionSnapshot(
          contributionID: contribution.contributionID,
          contentSHA256: contribution.contentSHA256,
          provenanceSHA256: fixtureSHA256(
            try contribution.provenance.canonicalJSONData()
          )
        )
      }.sorted { $0.contributionID < $1.contributionID },
      verifications: verifications.map { verification in
        let contributionIDs = Array(
          Set(verification.content.claims.map(\.contributionID))
        ).sorted()
        return SharedEpisodeSelectionVerificationSnapshot(
          recordID: verification.recordID,
          contributionIDs: contributionIDs,
          evidenceIDs: verification.content.evidence.map(\.evidenceID).sorted(),
          evidenceBindings: contributionIDs.map { contributionID in
            let claimIDs = Set(
              verification.content.claims.compactMap {
                $0.contributionID == contributionID ? $0.claimID : nil
              })
            return SharedEpisodeSelectionEvidenceBinding(
              contributionID: contributionID,
              evidenceIDs: verification.content.evidence.compactMap {
                claimIDs.contains($0.claimID) ? $0.evidenceID : nil
              }.sorted()
            )
          },
          outcome: verification.content.outcome,
          standing: assessmentByID[verification.recordID]?.standing
            ?? .unconfirmedProvenance
        )
      }.sorted { $0.recordID < $1.recordID },
      disagreements: try generation.state.verificationReport.disagreements.map {
        disagreement in
        guard
          let verification = verifications.first(where: { record in
            record.content.disagreements.contains {
              $0.disagreementID == disagreement.disagreementID
            }
          }),
          let claim = verification.content.claims.first(where: {
            $0.claimID == disagreement.claimID
          })
        else {
          throw SharedEpisodeMemoryError.invalidSelection(
            "Фикстура не связала разногласие с точной проверкой и утверждением."
          )
        }
        return SharedEpisodeSelectionDisagreementSnapshot(
          disagreementID: disagreement.disagreementID,
          verificationRecordID: verification.recordID,
          claimID: claim.claimID,
          contributionID: claim.contributionID,
          resultSHA256: claim.resultSHA256,
          eligibleEvidenceIDs: verification.content.evidence.compactMap {
            $0.claimID == claim.claimID ? $0.evidenceID : nil
          }.sorted()
        )
      }.sorted { $0.disagreementID < $1.disagreementID }
    )
  }

  fileprivate static func selectionDecision(
    named fixture: SharedEpisodeSelectionFixture,
    generation: SharedEpisodeGeneration,
    parentGenerationSHA256: String
  ) throws -> SharedEpisodeSelectionDecision {
    guard
      let criteriaArtifact = generation.seed.artifacts.first(where: {
        $0.artifactID == "criteria.main"
      })
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Фикстура не нашла артефакт критериев."
      )
    }
    let contributions = generation.state.contributions.sorted {
      $0.contributionID < $1.contributionID
    }
    let verifications = generation.state.verifications.sorted {
      $0.recordID < $1.recordID
    }
    let assessments = generation.state.verificationReport.assessmentsByRecordID
    guard
      let selectedContributionID = contributions.first(where: { contribution in
        verifications.contains { verification in
          verification.content.claims.contains {
            $0.contributionID == contribution.contributionID
          }
            && verification.content.outcome == .passed
            && assessments[verification.recordID]?.standing
              == .externalByObservedFeatures
            && !verification.content.evidence.isEmpty
        }
      })?.contributionID
    else {
      throw SharedEpisodeMemoryError.invalidSelection(
        "Фикстура не нашла вклад с внешней проверенной опорой."
      )
    }

    let considerations = try contributions.map { contribution in
      let relevant = verifications.filter { verification in
        verification.content.claims.contains {
          $0.contributionID == contribution.contributionID
        }
      }
      return SharedEpisodeSelectionConsideration(
        contributionID: contribution.contributionID,
        contentSHA256: contribution.contentSHA256,
        provenanceSHA256: fixtureSHA256(
          try contribution.provenance.canonicalJSONData()
        ),
        verificationRecordIDs: relevant.map(\.recordID).sorted(),
        evidenceIDs: Array(
          Set(relevant.flatMap { $0.content.evidence.map(\.evidenceID) })
        ).sorted(),
        disposition: contribution.contributionID == selectedContributionID
          ? .selected : .rejected,
        reasonCode: contribution.contributionID == selectedContributionID
          ? "reason.external-evidence" : "reason.not-selected"
      )
    }
    var disagreementDispositions = generation.state.verificationReport.disagreements
      .map {
        SharedEpisodeDisagreementDisposition(
          disagreementID: $0.disagreementID,
          resolution: .retainedUnresolved,
          reasonCode: "reason.retained-unresolved",
          evidenceIDs: []
        )
      }
      .sorted { $0.disagreementID < $1.disagreementID }
    if fixture == .omitsDisagreement, !disagreementDispositions.isEmpty {
      disagreementDispositions.removeLast()
    }
    let criterionIDs = Array(
      Set(verifications.flatMap { $0.content.criterionIDs })
    ).sorted()
    let selectionContext = try selectionEvidenceContext(generation)
    return SharedEpisodeSelectionDecision(
      decisionID: "decision.\(fixture.rawValue)",
      parentGenerationSHA256: parentGenerationSHA256,
      selectionContextSHA256: fixtureSHA256(
        try selectionContext.canonicalJSONData()
      ),
      replacesDecisionID: generation.state.selectionDecisions.last?.decisionID,
      selectionPolicyID: generation.seed.controlPlan.selectionPolicyID,
      selectionPlanArtifactID: generation.seed.controlPlan.selectionPlanArtifactID,
      stopPolicyID: generation.seed.controlPlan.stopPolicyID,
      selectorID: generation.seed.controlPlan.selectorID,
      selectorRoleID: generation.seed.controlPlan.selectorRoleID,
      criteriaArtifactID: criteriaArtifact.artifactID,
      criteriaSHA256: criteriaArtifact.contentSHA256,
      criterionIDs: criterionIDs,
      considerations: considerations,
      disagreementDispositions: disagreementDispositions,
      selectedContributionID: selectedContributionID,
      basis: fixture == .assertionVote ? .assertionVote : .verifiedEvidence,
      status: .selectedInModel,
      userConfirmed: false,
      authorized: false
    )
  }

  fileprivate static func prepareTerminal(
    from generation: SharedEpisodeGeneration,
    suffix: String,
    outcome: SharedEpisodeTerminalOutcome,
    executorID: String? = nil,
    roundID: String? = nil,
    reason: (
      _ parentGenerationSHA256: String,
      _ reservedGeneration: SharedEpisodeGeneration
    ) throws -> SharedEpisodeTerminalReason
  ) throws -> PreparedTerminal {
    let selectedExecutorID = executorID ?? "executor.terminal.\(suffix)"
    let selectedRoundID = roundID ?? "round.terminal.\(suffix)"
    let terminalBudget = SharedEpisodeBudgetVector(
      executors: generation.state.controlState.usedExecutorIDs.contains(
        selectedExecutorID
      ) ? 0 : 1,
      rounds: generation.state.controlState.usedRoundIDs.contains(
        selectedRoundID
      ) ? 0 : 1,
      modelCalls: 1,
      toolCalls: 1,
      input: 1,
      output: 1
    )
    let terminalReservation = SharedEpisodeActionReservation(
      permitID: "permit.terminal.\(suffix)",
      actionID: "action.terminal.\(suffix)",
      parentGenerationSHA256: try generationSHA256(generation),
      phase: .handoff,
      kind: .terminal,
      executorID: selectedExecutorID,
      roundID: selectedRoundID,
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: terminalBudget
    )
    let reservedGeneration = try SharedEpisodeMemoryReducer.continuation(
      from: generation,
      control: .actionReserved(terminalReservation)
    )
    let parentGenerationSHA256 = try generationSHA256(reservedGeneration)
    let terminal = SharedEpisodeTerminalRecord(
      terminalID: "terminal.\(suffix)",
      parentGenerationSHA256: parentGenerationSHA256,
      permitID: terminalReservation.permitID,
      outcome: outcome,
      selectionDecisionID: reservedGeneration.state.selectionDecisions.last?
        .decisionID,
      reason: try reason(parentGenerationSHA256, reservedGeneration),
      unresolvedDisagreementIDs: reservedGeneration.state.unresolvedDisagreementIDs
    )
    return (
      reservedGeneration,
      terminal,
      actionSettlement(
        for: terminalReservation,
        actual: identitySettlementBudget(for: terminalReservation)
      )
    )
  }

  fileprivate static func applyPreparedTerminal(
    _ prepared: PreparedTerminal
  ) throws -> SharedEpisodeGeneration {
    try SharedEpisodeMemoryReducer.continuation(
      from: prepared.generation,
      control: .terminal(prepared.terminal, prepared.settlement)
    )
  }

  fileprivate static func requiredModelOnlyCandidate(
    in plan: SharedEpisodeControlPlan
  ) throws -> SharedEpisodeContinuationCandidate {
    guard
      let candidate = plan.continuations.first(where: {
        $0.kind == .modelOnly && $0.safe && $0.productive
      })
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Фикстура не нашла безопасное model-only продолжение."
      )
    }
    return candidate
  }

  fileprivate static func requiredContinuation(
    _ continuationID: String,
    in plan: SharedEpisodeControlPlan
  ) throws -> SharedEpisodeContinuationCandidate {
    guard
      let candidate = plan.continuations.first(where: {
        $0.continuationID == continuationID
      })
    else {
      throw SharedEpisodeMemoryError.invalidControl(
        "Фикстура не нашла продолжение \(continuationID)."
      )
    }
    return candidate
  }

  fileprivate static let roomyMaximumBudget = SharedEpisodeBudgetVector(
    executors: 32,
    rounds: 32,
    modelCalls: 64,
    toolCalls: 64,
    input: 65_536,
    output: 262_144
  )

  fileprivate static let roomyVerificationReserve = SharedEpisodeBudgetVector(
    executors: 16,
    rounds: 16,
    modelCalls: 32,
    toolCalls: 32,
    input: 32_768,
    output: 131_072
  )

  fileprivate static let roomyHandoffReserve = SharedEpisodeBudgetVector(
    executors: 1,
    rounds: 1,
    modelCalls: 1,
    toolCalls: 2,
    input: 4_096,
    output: 8_192
  )

  static func selectionFixtureControlPlan() throws -> SharedEpisodeControlPlan {
    controlPlan(
      maximum: roomyMaximumBudget,
      verificationReserve: roomyVerificationReserve,
      handoffReserve: roomyHandoffReserve,
      continuations: try selectionFixtureContinuations(includeModelOnly: true),
      distinguishingChecks: [
        SharedEpisodeDistinguishingCheck(
          checkID: "check.distinguishing.primary",
          safe: true,
          productive: true,
          budget: try meteredVerificationBudget(named: .inconclusive)
        )
      ]
    )
  }

  fileprivate static func selectionFixtureContinuations(
    includeModelOnly: Bool
  ) throws -> [SharedEpisodeContinuationCandidate] {
    var continuations = [
      SharedEpisodeContinuationCandidate(
        continuationID: "continuation.setup.verification.external",
        kind: .verification,
        safe: true,
        productive: true,
        budget: try meteredVerificationBudget(named: .externalPassed)
      ),
      SharedEpisodeContinuationCandidate(
        continuationID: "continuation.setup.verification.failed",
        kind: .verification,
        safe: true,
        productive: true,
        budget: try meteredVerificationBudget(named: .failed)
      ),
    ]
    if includeModelOnly {
      continuations.append(
        SharedEpisodeContinuationCandidate(
          continuationID: "continuation.model-only.primary",
          kind: .modelOnly,
          safe: true,
          productive: true,
          budget: unitBudget
        )
      )
    }
    return continuations.sorted { $0.continuationID < $1.continuationID }
  }

  fileprivate static func meteredVerificationBudget(
    named fixture: SharedEpisodeVerificationFixture
  ) throws -> SharedEpisodeBudgetVector {
    let verification = try SharedEpisodeMemoryFixtures.verification(
      named: fixture,
      parentGenerationSHA256: fixtureSHA256("fixture budget parent")
    )
    return try SharedEpisodeControlKernel.meteredUsage(
      for: verification,
      executors: 1,
      rounds: 1
    )
  }

  fileprivate static func modelOnlyReservation(
    parentGenerationSHA256: String,
    candidate: SharedEpisodeContinuationCandidate,
    suffix: String
  ) -> SharedEpisodeActionReservation {
    reservation(
      suffix: "model-only.\(suffix)",
      parentGenerationSHA256: parentGenerationSHA256,
      phase: .productive,
      kind: .modelOnly,
      continuationID: candidate.continuationID,
      reserved: candidate.budget
    )
  }

  fileprivate static func reservation(
    suffix: String,
    parentGenerationSHA256: String,
    phase: SharedEpisodeActionPhase,
    kind: SharedEpisodeActionKind,
    continuationID: String? = nil,
    distinguishingCheckID: String? = nil,
    reserved: SharedEpisodeBudgetVector
  ) -> SharedEpisodeActionReservation {
    SharedEpisodeActionReservation(
      permitID: "permit.\(suffix)",
      actionID: "action.\(suffix)",
      parentGenerationSHA256: parentGenerationSHA256,
      phase: phase,
      kind: kind,
      executorID: "executor.\(suffix)",
      roundID: "round.\(suffix)",
      continuationID: continuationID,
      distinguishingCheckID: distinguishingCheckID,
      reserved: reserved
    )
  }

  fileprivate static func actionSettlement(
    for reservation: SharedEpisodeActionReservation,
    actual: SharedEpisodeBudgetVector
  ) -> SharedEpisodeActionSettlement {
    SharedEpisodeActionSettlement(
      permitID: reservation.permitID,
      actionID: reservation.actionID,
      actual: actual
    )
  }

  fileprivate static func controlPlan(
    maximum: SharedEpisodeBudgetVector,
    verificationReserve: SharedEpisodeBudgetVector,
    handoffReserve: SharedEpisodeBudgetVector,
    continuations: [SharedEpisodeContinuationCandidate],
    distinguishingChecks: [SharedEpisodeDistinguishingCheck]
  ) -> SharedEpisodeControlPlan {
    SharedEpisodeControlPlan(
      budget: SharedEpisodeBudgetPlan(
        maximum: maximum,
        verificationReserve: verificationReserve,
        handoffReserve: handoffReserve
      ),
      continuations: continuations.sorted {
        $0.continuationID < $1.continuationID
      },
      distinguishingChecks: distinguishingChecks.sorted {
        $0.checkID < $1.checkID
      }
    )
  }

  fileprivate static func uniformBudget(_ value: Int64) -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: value,
      rounds: value,
      modelCalls: value,
      toolCalls: value,
      input: value,
      output: value
    )
  }

  fileprivate static func replacingBudgetComponent(
    in budget: SharedEpisodeBudgetVector,
    dimension: SharedEpisodeBudgetDimension,
    with value: Int64
  ) -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: dimension == .executors ? value : budget.executors,
      rounds: dimension == .rounds ? value : budget.rounds,
      modelCalls: dimension == .modelCalls ? value : budget.modelCalls,
      toolCalls: dimension == .toolCalls ? value : budget.toolCalls,
      input: dimension == .input ? value : budget.input,
      output: dimension == .output ? value : budget.output
    )
  }

  fileprivate static func identitySettlementBudget(
    for reservation: SharedEpisodeActionReservation
  ) -> SharedEpisodeBudgetVector {
    SharedEpisodeBudgetVector(
      executors: reservation.reserved.executors,
      rounds: reservation.reserved.rounds,
      modelCalls: 0,
      toolCalls: 0,
      input: 0,
      output: 0
    )
  }

  fileprivate static func generationSHA256(
    _ generation: SharedEpisodeGeneration
  ) throws -> String {
    fixtureSHA256(try generation.canonicalJSONData())
  }

  fileprivate static func fixtureSHA256(_ string: String) -> String {
    fixtureSHA256(Data(string.utf8))
  }

  fileprivate static func fixtureSHA256(_ data: Data) -> String {
    SharedEpisodeEmbeddedArtifact(
      artifactID: "fixture.hash",
      kind: "fixture_hash",
      logicalPath: "fixtures/hash.bin",
      mediaType: "application/octet-stream",
      data: data
    ).contentSHA256
  }
}
