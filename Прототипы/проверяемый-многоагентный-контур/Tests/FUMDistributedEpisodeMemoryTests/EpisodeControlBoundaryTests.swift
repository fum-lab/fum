import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class EpisodeControlBoundaryTests: XCTestCase {
  func testPayloadEventsCannotSettleWithoutTheirObservableWork() throws {
    let plan = try payloadBoundaryPlan()

    let contributionFoundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    let contributionDraft = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: boundarySHA256(contributionFoundation)
    )
    let contributionBudget = try SharedEpisodeControlKernel.meteredUsage(
      for: contributionDraft,
      executors: 1,
      rounds: 1
    )
    let contributionReservation = boundaryReservation(
      suffix: "payload.contribution",
      parent: try boundarySHA256(contributionFoundation),
      phase: .productive,
      kind: .contribution,
      reserved: contributionBudget
    )
    let contributionReserved = try SharedEpisodeMemoryReducer.continuation(
      from: contributionFoundation,
      control: .actionReserved(contributionReservation)
    )
    let contribution = contributionDraft.rebinding(
      parentGenerationSHA256: try boundarySHA256(contributionReserved)
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: contributionReserved,
        control: .contribution(
          contribution,
          boundarySettlement(
            contributionReservation,
            actual: boundaryIdentityOnlyBudget
          )
        )
      ),
      "Вклад с моделью, инструментальным наблюдением, входом и выходом не может списать по ним ноль."
    )

    let verificationFoundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    let contributionSteps = try appendBoundaryContribution(
      named: .primary,
      to: verificationFoundation,
      suffix: "payload.verification-input"
    )
    let verificationBudget = try XCTUnwrap(
      plan.continuations.first {
        $0.continuationID == "continuation.boundary.verification"
      }
    ).budget
    let verificationReservation = boundaryReservation(
      suffix: "payload.verification",
      parent: try boundarySHA256(contributionSteps.completed),
      phase: .verification,
      kind: .verification,
      continuationID: "continuation.boundary.verification",
      reserved: verificationBudget
    )
    let verificationReserved = try SharedEpisodeMemoryReducer.continuation(
      from: contributionSteps.completed,
      control: .actionReserved(verificationReservation)
    )
    let verification = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: boundarySHA256(verificationReserved)
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: verificationReserved,
        control: .verification(
          verification,
          boundarySettlement(
            verificationReservation,
            actual: boundaryIdentityOnlyBudget
          )
        )
      ),
      "Проверка с моделью, доказательствами, входом и выходом не может списать по ним ноль."
    )
  }

  func testResolvedDisagreementRejectsEvidenceFromDifferentClaim() throws {
    let plan = try resolutionBoundaryPlan()
    var generation = try SharedEpisodeControlFixtures.selectionPrefix(
      controlPlan: plan,
      correlatedCopyCount: 0,
      includeFailedVerification: true
    )
    let foreign = try appendForeignClaimVerification(
      to: generation,
      distinguishingCheckID: "check.boundary.resolve"
    )
    generation = foreign.completed

    let selectionReservation = boundaryReservation(
      suffix: "foreign-evidence.selection",
      parent: try boundarySHA256(generation),
      phase: .productive,
      kind: .selection,
      reserved: boundaryUnitBudget
    )
    let selectionReserved = try SharedEpisodeMemoryReducer.continuation(
      from: generation,
      control: .actionReserved(selectionReservation)
    )
    let valid = try boundarySelectionDecision(
      generation: selectionReserved,
      parent: boundarySHA256(selectionReserved),
      decisionID: "decision.foreign-evidence.template"
    )
    guard let firstDisagreementID = valid.disagreementDispositions.first?.disagreementID
    else {
      return XCTFail("Фикстура не сохранила разногласие исходного claim.")
    }
    let dispositions = valid.disagreementDispositions.map { disposition in
      disposition.disagreementID == firstDisagreementID
        ? SharedEpisodeDisagreementDisposition(
          disagreementID: disposition.disagreementID,
          resolution: .resolved,
          reasonCode: "reason.foreign-claim-evidence",
          evidenceIDs: [foreign.evidenceID]
        ) : disposition
    }
    let invalid = boundaryDecision(
      copying: valid,
      decisionID: "decision.foreign-evidence.invalid",
      parent: try boundarySHA256(selectionReserved),
      disagreementDispositions: dispositions
    )

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: selectionReserved,
        control: .selection(
          invalid,
          boundarySettlement(selectionReservation, actual: boundaryUnitBudget)
        )
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidSelection = error else {
        return XCTFail("Ожидался invalidSelection, получено: \(error)")
      }
    }
  }

  func testGoalMetRejectsSelectionFromStaleFrontier() throws {
    let prefix = try SharedEpisodeControlFixtures.selectionPrefix(
      correlatedCopyCount: 0,
      includeFailedVerification: false
    )
    var generation = try appendBoundarySelection(to: prefix)
    generation = try appendBoundaryContribution(
      named: .adversarial,
      to: generation,
      suffix: "stale-frontier.new-contribution"
    ).completed

    let terminalReservation = boundaryReservation(
      suffix: "stale-frontier.terminal",
      parent: try boundarySHA256(generation),
      phase: .handoff,
      kind: .terminal,
      reserved: boundaryUnitBudget
    )
    generation = try SharedEpisodeMemoryReducer.continuation(
      from: generation,
      control: .actionReserved(terminalReservation)
    )
    let terminal = SharedEpisodeTerminalRecord(
      terminalID: "terminal.stale-selection-frontier",
      parentGenerationSHA256: try boundarySHA256(generation),
      permitID: terminalReservation.permitID,
      outcome: .goalMet,
      selectionDecisionID: generation.state.selectionDecisions.last?.decisionID,
      reason: SharedEpisodeTerminalReason(
        code: .goalCriteriaMet,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: generation.state.selectionDecisions
          .compactMap(\.selectedContributionID)
          .sorted()
      ),
      unresolvedDisagreementIDs: generation.state.unresolvedDisagreementIDs
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: generation,
        control: .terminal(
          terminal,
          boundarySettlement(
            terminalReservation,
            actual: boundaryIdentityOnlyBudget
          )
        )
      ),
      "goal_met не должен принимать решение со старым frontier вкладов и проверок."
    )
  }

  func testGoalMetRejectsRetainedUnresolvedDisagreement() throws {
    let scenario = try SharedEpisodeControlFixtures.unresolvedConflictScenario(
      distinguishingChecksExhausted: true
    )
    let invalid = SharedEpisodeTerminalRecord(
      terminalID: "terminal.boundary.unresolved-goal",
      parentGenerationSHA256: scenario.terminal.parentGenerationSHA256,
      permitID: scenario.terminal.permitID,
      outcome: .goalMet,
      selectionDecisionID: scenario.terminal.selectionDecisionID,
      reason: SharedEpisodeTerminalReason(
        code: .goalCriteriaMet,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: scenario.generation.state.selectionDecisions
          .compactMap(\.selectedContributionID)
          .sorted()
      ),
      unresolvedDisagreementIDs: scenario.generation.state.unresolvedDisagreementIDs
    )

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: scenario.generation,
        control: .terminal(invalid, scenario.settlement)
      ),
      "goal_met не должен сосуществовать с сохранённым неустранённым разногласием."
    )
  }

  func testLaterDeclaredDistinguishingCheckCanResolveDisagreement() throws {
    let plan = try resolutionBoundaryPlan()
    var generation = try SharedEpisodeControlFixtures.selectionPrefix(
      controlPlan: plan,
      correlatedCopyCount: 0,
      includeFailedVerification: true
    )
    generation = try appendBoundarySelection(to: generation)
    let disagreement = try XCTUnwrap(
      generation.state.verificationReport.disagreements.first
    )
    let distinguishing = try appendForeignClaimVerification(
      to: generation,
      claimID: disagreement.claimID,
      distinguishingCheckID: "check.boundary.resolve"
    )
    generation = distinguishing.completed

    let reservation = boundaryReservation(
      suffix: "resolved-later.selection",
      parent: try boundarySHA256(generation),
      phase: .productive,
      kind: .selection,
      reserved: boundaryUnitBudget
    )
    let reserved = try SharedEpisodeMemoryReducer.continuation(
      from: generation,
      control: .actionReserved(reservation)
    )
    let template = try boundarySelectionDecision(
      generation: reserved,
      parent: boundarySHA256(reserved),
      decisionID: "decision.boundary.resolve-later.template"
    )
    let dispositions = template.disagreementDispositions.map { disposition in
      disposition.disagreementID == disagreement.disagreementID
        ? SharedEpisodeDisagreementDisposition(
          disagreementID: disposition.disagreementID,
          resolution: .resolved,
          reasonCode: "reason.boundary.distinguishing-evidence",
          evidenceIDs: [distinguishing.evidenceID]
        ) : disposition
    }
    let decision = boundaryDecision(
      copying: template,
      decisionID: "decision.boundary.resolve-later",
      parent: try boundarySHA256(reserved),
      disagreementDispositions: dispositions
    )
    let completed = try SharedEpisodeMemoryReducer.continuation(
      from: reserved,
      control: .selection(
        decision,
        boundarySettlement(reservation, actual: boundaryUnitBudget)
      )
    )

    XCTAssertFalse(
      completed.state.unresolvedDisagreementIDs.contains(disagreement.disagreementID)
    )
  }

  func testConveniencePayloadAPIsPublishPersistableTwoPhaseTrace() throws {
    let contributionRoot = try boundaryTemporaryDirectory("contribution")
    defer { try? FileManager.default.removeItem(at: contributionRoot) }
    let contributionStore = SharedEpisodeMemoryStore(rootURL: contributionRoot)
    let contributionFoundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    _ = try contributionStore.commit(contributionFoundation)
    let contribution = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: boundarySHA256(contributionFoundation)
    )
    let convenienceContribution = try SharedEpisodeMemoryReducer.continuation(
      from: contributionFoundation,
      contribution: contribution
    )
    XCTAssertNoThrow(
      try contributionStore.commit(convenienceContribution.reserved),
      "Публичный convenience обязан вернуть сохраняемую промежуточную резервацию."
    )
    XCTAssertNoThrow(
      try contributionStore.commit(convenienceContribution.completed),
      "Публичный convenience обязан вернуть сохраняемое завершение вслед за резервацией."
    )

    let verificationRoot = try boundaryTemporaryDirectory("verification")
    defer { try? FileManager.default.removeItem(at: verificationRoot) }
    let verificationStore = SharedEpisodeMemoryStore(rootURL: verificationRoot)
    let plan = try payloadBoundaryPlan()
    let verificationFoundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed(controlPlan: plan)
    )
    let contributionSteps = try appendBoundaryContribution(
      named: .primary,
      to: verificationFoundation,
      suffix: "convenience.verification-input"
    )
    _ = try verificationStore.commit(verificationFoundation)
    _ = try verificationStore.commit(contributionSteps.reserved)
    _ = try verificationStore.commit(contributionSteps.completed)
    let verification = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: boundarySHA256(contributionSteps.completed)
    )
    let convenienceVerification = try SharedEpisodeMemoryReducer.continuation(
      from: contributionSteps.completed,
      verification: verification
    )
    XCTAssertNoThrow(
      try verificationStore.commit(convenienceVerification.reserved),
      "Verification convenience обязан вернуть сохраняемую промежуточную резервацию."
    )
    XCTAssertNoThrow(
      try verificationStore.commit(convenienceVerification.completed),
      "Verification convenience обязан вернуть сохраняемое завершение вслед за резервацией."
    )
  }

  func testBudgetExhaustedRequiresValidActionAndEffectiveBudgetWitness() throws {
    let boundary = try SharedEpisodeControlFixtures.budgetBoundary(
      dimension: .output,
      overBy: 1
    )
    let malformed = SharedEpisodeActionReservation(
      schemaVersion: boundary.reservation.schemaVersion,
      meteringPolicyID: boundary.reservation.meteringPolicyID,
      permitID: boundary.reservation.permitID,
      actionID: boundary.reservation.actionID,
      parentGenerationSHA256: boundary.reservation.parentGenerationSHA256,
      phase: .productive,
      kind: .terminal,
      executorID: boundary.reservation.executorID,
      roundID: boundary.reservation.roundID,
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: boundary.reservation.reserved
    )
    XCTAssertThrowsError(
      try SharedEpisodeControlFixtures.appendBudgetExhaustedTerminal(
        blockedReservation: malformed,
        to: boundary.generation
      ),
      "budget_exhausted не должен принимать действие с несовместимыми phase и kind."
    )

    let protected = try SharedEpisodeControlFixtures.fullyProtectedReserve()
    let terminalReservation = boundaryReservation(
      suffix: "effective-reserve.terminal",
      parent: try boundarySHA256(protected.generation),
      phase: .handoff,
      kind: .terminal,
      reserved: boundaryUnitBudget
    )
    let terminalReserved = try SharedEpisodeMemoryReducer.continuation(
      from: protected.generation,
      control: .actionReserved(terminalReservation)
    )
    let blocked = protected.productiveReservation.rebinding(
      parentGenerationSHA256: try boundarySHA256(terminalReserved)
    )
    let terminal = SharedEpisodeTerminalRecord(
      terminalID: "terminal.effective-reserve",
      parentGenerationSHA256: try boundarySHA256(terminalReserved),
      permitID: terminalReservation.permitID,
      outcome: .budgetExhausted,
      reason: SharedEpisodeTerminalReason(
        code: .budgetLimitReached,
        budgetDimension: .executors,
        budgetRequiredUnits: 1,
        budgetAvailableUnits: 0,
        blockedReservation: blocked,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: [blocked.actionID]
      ),
      unresolvedDisagreementIDs: terminalReserved.state.unresolvedDisagreementIDs
    )
    XCTAssertNoThrow(
      try SharedEpisodeMemoryReducer.continuation(
        from: terminalReserved,
        control: .terminal(
          terminal,
          boundarySettlement(
            terminalReservation,
            actual: boundaryIdentityOnlyBudget
          )
        )
      ),
      "Точная otherwise-valid резервация, заблокированная protected reserve, должна воспроизводить budget_exhausted."
    )
  }
}

private let boundaryUnitBudget = SharedEpisodeBudgetVector(
  executors: 1,
  rounds: 1,
  modelCalls: 1,
  toolCalls: 1,
  input: 1,
  output: 1
)

private let boundaryIdentityOnlyBudget = SharedEpisodeBudgetVector(
  executors: 1,
  rounds: 1,
  modelCalls: 0,
  toolCalls: 0,
  input: 0,
  output: 0
)

private func payloadBoundaryPlan() throws -> SharedEpisodeControlPlan {
  let fixtureParent = "sha256:\(String(repeating: "0", count: 64))"
  let verification = try SharedEpisodeMemoryFixtures.verification(
    named: .externalPassed,
    parentGenerationSHA256: fixtureParent
  )
  let verificationBudget = try SharedEpisodeControlKernel.meteredUsage(
    for: verification,
    executors: 1,
    rounds: 1
  )
  let maximum = SharedEpisodeBudgetVector(
    executors: 20,
    rounds: 20,
    modelCalls: 20,
    toolCalls: 20,
    input: 1_024,
    output: 65_536
  )
  let verificationReserve = SharedEpisodeBudgetVector(
    executors: 5,
    rounds: 5,
    modelCalls: 5,
    toolCalls: 5,
    input: 256,
    output: 32_768
  )
  return SharedEpisodeControlPlan(
    budget: SharedEpisodeBudgetPlan(
      maximum: maximum,
      verificationReserve: verificationReserve,
      handoffReserve: SharedEpisodeBudgetVector(
        executors: 2,
        rounds: 2,
        modelCalls: 2,
        toolCalls: 2,
        input: 128,
        output: 8_192
      )
    ),
    continuations: [
      SharedEpisodeContinuationCandidate(
        continuationID: "continuation.boundary.verification",
        kind: .verification,
        safe: true,
        productive: true,
        budget: verificationBudget
      )
    ],
    distinguishingChecks: [
      SharedEpisodeDistinguishingCheck(
        checkID: "check.boundary.resolve",
        safe: true,
        productive: true,
        budget: SharedEpisodeBudgetVector(
          executors: 1,
          rounds: 1,
          modelCalls: 4,
          toolCalls: 4,
          input: 256,
          output: 16_384
        )
      )
    ]
  )
}

private func resolutionBoundaryPlan() throws -> SharedEpisodeControlPlan {
  let base = try SharedEpisodeControlFixtures.selectionFixtureControlPlan()
  return SharedEpisodeControlPlan(
    schemaVersion: base.schemaVersion,
    budget: base.budget,
    selectionPolicyID: base.selectionPolicyID,
    selectionPlanArtifactID: base.selectionPlanArtifactID,
    stopPolicyID: base.stopPolicyID,
    selectorID: base.selectorID,
    selectorRoleID: base.selectorRoleID,
    selectionBasis: base.selectionBasis,
    agreementIsEvidence: base.agreementIsEvidence,
    independenceInferredFromCount: base.independenceInferredFromCount,
    continuations: base.continuations,
    distinguishingChecks: [
      SharedEpisodeDistinguishingCheck(
        checkID: "check.boundary.resolve",
        safe: true,
        productive: true,
        budget: SharedEpisodeBudgetVector(
          executors: 1,
          rounds: 1,
          modelCalls: 4,
          toolCalls: 4,
          input: 256,
          output: 16_384
        )
      )
    ]
  )
}

private func boundaryReservation(
  suffix: String,
  parent: String,
  phase: SharedEpisodeActionPhase,
  kind: SharedEpisodeActionKind,
  continuationID: String? = nil,
  distinguishingCheckID: String? = nil,
  reserved: SharedEpisodeBudgetVector
) -> SharedEpisodeActionReservation {
  SharedEpisodeActionReservation(
    permitID: "permit.boundary.\(suffix)",
    actionID: "action.boundary.\(suffix)",
    parentGenerationSHA256: parent,
    phase: phase,
    kind: kind,
    executorID: "executor.boundary.\(suffix)",
    roundID: "round.boundary.\(suffix)",
    continuationID: continuationID,
    distinguishingCheckID: distinguishingCheckID,
    reserved: reserved
  )
}

private func boundarySettlement(
  _ reservation: SharedEpisodeActionReservation,
  actual: SharedEpisodeBudgetVector
) -> SharedEpisodeActionSettlement {
  SharedEpisodeActionSettlement(
    permitID: reservation.permitID,
    actionID: reservation.actionID,
    actual: actual
  )
}

private func appendBoundaryContribution(
  named fixture: SharedEpisodeContributionFixture,
  to generation: SharedEpisodeGeneration,
  suffix: String
) throws -> (
  reserved: SharedEpisodeGeneration,
  completed: SharedEpisodeGeneration
) {
  let draft = try SharedEpisodeMemoryFixtures.contribution(
    named: fixture,
    parentGenerationSHA256: boundarySHA256(generation)
  )
  let budget = try SharedEpisodeControlKernel.meteredUsage(
    for: draft,
    executors: 1,
    rounds: 1
  )
  let reservation = boundaryReservation(
    suffix: suffix,
    parent: try boundarySHA256(generation),
    phase: .productive,
    kind: .contribution,
    reserved: budget
  )
  let reserved = try SharedEpisodeMemoryReducer.continuation(
    from: generation,
    control: .actionReserved(reservation)
  )
  let contribution = draft.rebinding(
    parentGenerationSHA256: try boundarySHA256(reserved)
  )
  let completed = try SharedEpisodeMemoryReducer.continuation(
    from: reserved,
    control: .contribution(
      contribution,
      boundarySettlement(reservation, actual: budget)
    )
  )
  return (reserved, completed)
}

private func appendBoundarySelection(
  to generation: SharedEpisodeGeneration
) throws -> SharedEpisodeGeneration {
  let reservation = boundaryReservation(
    suffix: "valid-selection",
    parent: try boundarySHA256(generation),
    phase: .productive,
    kind: .selection,
    reserved: boundaryUnitBudget
  )
  let reserved = try SharedEpisodeMemoryReducer.continuation(
    from: generation,
    control: .actionReserved(reservation)
  )
  let decision = try boundarySelectionDecision(
    generation: reserved,
    parent: boundarySHA256(reserved),
    decisionID: "decision.boundary.valid"
  )
  return try SharedEpisodeMemoryReducer.continuation(
    from: reserved,
    control: .selection(
      decision,
      boundarySettlement(reservation, actual: boundaryUnitBudget)
    )
  )
}

private func boundarySelectionDecision(
  generation: SharedEpisodeGeneration,
  parent: String,
  decisionID: String
) throws -> SharedEpisodeSelectionDecision {
  guard
    let criteria = generation.seed.artifacts.first(where: {
      $0.artifactID == "criteria.main"
    })
  else {
    throw SharedEpisodeMemoryError.invalidSelection(
      "Boundary fixture не нашла критерии."
    )
  }
  let contributions = generation.state.contributions.sorted {
    $0.contributionID < $1.contributionID
  }
  let verifications = generation.state.verifications.sorted {
    $0.recordID < $1.recordID
  }
  let assessments = generation.state.verificationReport.assessmentsByRecordID
  let selectionContext = try boundarySelectionContext(generation)
  guard
    let selectedID = contributions.first(where: { contribution in
      verifications.contains { verification in
        verification.content.claims.contains {
          $0.contributionID == contribution.contributionID
        }
          && verification.content.outcome == .passed
          && assessments[verification.recordID]?.standing
            == .externalByObservedFeatures
          && !boundaryEvidenceIDs(
            in: verification,
            contributionID: contribution.contributionID
          ).isEmpty
      }
    })?.contributionID
  else {
    throw SharedEpisodeMemoryError.invalidSelection(
      "Boundary fixture не нашла внешне подтверждённый вклад."
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
      provenanceSHA256: boundarySHA256(
        try contribution.provenance.canonicalJSONData()
      ),
      verificationRecordIDs: relevant.map(\.recordID).sorted(),
      evidenceIDs: Array(
        Set(
          relevant.flatMap {
            boundaryEvidenceIDs(
              in: $0,
              contributionID: contribution.contributionID
            )
          })
      ).sorted(),
      disposition: contribution.contributionID == selectedID
        ? .selected : .rejected,
      reasonCode: contribution.contributionID == selectedID
        ? "reason.boundary.external-evidence" : "reason.boundary.rejected"
    )
  }
  let disagreements = generation.state.verificationReport.disagreements.map {
    SharedEpisodeDisagreementDisposition(
      disagreementID: $0.disagreementID,
      resolution: .retainedUnresolved,
      reasonCode: "reason.boundary.retained",
      evidenceIDs: []
    )
  }.sorted { $0.disagreementID < $1.disagreementID }
  return SharedEpisodeSelectionDecision(
    decisionID: decisionID,
    parentGenerationSHA256: parent,
    selectionContextSHA256: boundarySHA256(
      try selectionContext.canonicalJSONData()
    ),
    replacesDecisionID: generation.state.selectionDecisions.last?.decisionID,
    selectionPolicyID: generation.seed.controlPlan.selectionPolicyID,
    selectionPlanArtifactID: generation.seed.controlPlan.selectionPlanArtifactID,
    stopPolicyID: generation.seed.controlPlan.stopPolicyID,
    selectorID: generation.seed.controlPlan.selectorID,
    selectorRoleID: generation.seed.controlPlan.selectorRoleID,
    criteriaArtifactID: criteria.artifactID,
    criteriaSHA256: criteria.contentSHA256,
    criterionIDs: Array(
      Set(verifications.flatMap { $0.content.criterionIDs })
    ).sorted(),
    considerations: considerations,
    disagreementDispositions: disagreements,
    selectedContributionID: selectedID,
    basis: .verifiedEvidence,
    status: .selectedInModel,
    userConfirmed: false,
    authorized: false
  )
}

private func boundaryDecision(
  copying decision: SharedEpisodeSelectionDecision,
  decisionID: String,
  parent: String,
  disagreementDispositions: [SharedEpisodeDisagreementDisposition]
) -> SharedEpisodeSelectionDecision {
  SharedEpisodeSelectionDecision(
    schemaVersion: decision.schemaVersion,
    decisionID: decisionID,
    parentGenerationSHA256: parent,
    selectionContextSHA256: decision.selectionContextSHA256,
    replacesDecisionID: decision.replacesDecisionID,
    selectionPolicyID: decision.selectionPolicyID,
    selectionPlanArtifactID: decision.selectionPlanArtifactID,
    stopPolicyID: decision.stopPolicyID,
    selectorID: decision.selectorID,
    selectorRoleID: decision.selectorRoleID,
    criteriaArtifactID: decision.criteriaArtifactID,
    criteriaSHA256: decision.criteriaSHA256,
    criterionIDs: decision.criterionIDs,
    considerations: decision.considerations,
    disagreementDispositions: disagreementDispositions,
    selectedContributionID: decision.selectedContributionID,
    basis: decision.basis,
    status: decision.status,
    userConfirmed: decision.userConfirmed,
    authorized: decision.authorized
  )
}

private func boundarySelectionContext(
  _ generation: SharedEpisodeGeneration
) throws -> SharedEpisodeSelectionEvidenceContext {
  guard
    let criteria = generation.seed.artifacts.first(where: {
      $0.artifactID == "criteria.main"
    })
  else {
    throw SharedEpisodeMemoryError.invalidSelection(
      "Boundary fixture не нашла критерии контекста выбора."
    )
  }
  let assessments = generation.state.verificationReport.assessmentsByRecordID
  let verifications = generation.state.verifications
  let distinguishingCheckIDs = boundaryDistinguishingCheckIDs(generation)
  let verificationIndexByID = Dictionary(
    uniqueKeysWithValues: verifications.enumerated().map { ($0.element.recordID, $0.offset) }
  )
  return SharedEpisodeSelectionEvidenceContext(
    criteriaArtifactID: criteria.artifactID,
    criteriaSHA256: criteria.contentSHA256,
    criterionIDs: Array(
      Set(verifications.flatMap { $0.content.criterionIDs })
    ).sorted(),
    contributions: try generation.state.contributions.map {
      SharedEpisodeSelectionContributionSnapshot(
        contributionID: $0.contributionID,
        contentSHA256: $0.contentSHA256,
        provenanceSHA256: boundarySHA256(
          try $0.provenance.canonicalJSONData()
        )
      )
    }.sorted { $0.contributionID < $1.contributionID },
    verifications: verifications.map { verification in
      let contributionIDs = Array(
        Set(verification.content.claims.map(\.contributionID))
      ).sorted()
      return SharedEpisodeSelectionVerificationSnapshot(
        recordID: verification.recordID,
        distinguishingCheckID: distinguishingCheckIDs[verification.recordID],
        contributionIDs: contributionIDs,
        evidenceIDs: verification.content.evidence.map(\.evidenceID).sorted(),
        evidenceBindings: contributionIDs.map { contributionID in
          SharedEpisodeSelectionEvidenceBinding(
            contributionID: contributionID,
            evidenceIDs: boundaryEvidenceIDs(
              in: verification,
              contributionID: contributionID
            )
          )
        },
        outcome: verification.content.outcome,
        standing: assessments[verification.recordID]?.standing
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
        }),
        let verificationIndex = verificationIndexByID[verification.recordID]
      else {
        throw SharedEpisodeMemoryError.invalidSelection(
          "Boundary fixture не связала разногласие с claim."
        )
      }
      let originalEvidenceIDs = verification.content.evidence.filter {
        $0.claimID == claim.claimID
      }.map(\.evidenceID)
      let laterDistinguishingEvidenceIDs = verifications.enumerated().flatMap {
        index, candidate -> [String] in
        guard index > verificationIndex,
          distinguishingCheckIDs[candidate.recordID] != nil
        else { return [] }
        let claimIDs = Set(
          candidate.content.claims.compactMap {
            candidateClaim in
            candidateClaim.claimID == claim.claimID
              && candidateClaim.contributionID == claim.contributionID
              && candidateClaim.resultSHA256 == claim.resultSHA256
              ? candidateClaim.claimID : nil
          })
        return candidate.content.evidence.compactMap {
          claimIDs.contains($0.claimID) ? $0.evidenceID : nil
        }
      }
      return SharedEpisodeSelectionDisagreementSnapshot(
        disagreementID: disagreement.disagreementID,
        verificationRecordID: verification.recordID,
        claimID: claim.claimID,
        contributionID: claim.contributionID,
        resultSHA256: claim.resultSHA256,
        eligibleEvidenceIDs: Array(
          Set(originalEvidenceIDs + laterDistinguishingEvidenceIDs)
        ).sorted()
      )
    }.sorted { $0.disagreementID < $1.disagreementID }
  )
}

private func boundaryEvidenceIDs(
  in verification: SharedEpisodeVerificationRecord,
  contributionID: String
) -> [String] {
  let claimIDs = Set(
    verification.content.claims.compactMap {
      $0.contributionID == contributionID ? $0.claimID : nil
    }
  )
  return verification.content.evidence.compactMap {
    claimIDs.contains($0.claimID) ? $0.evidenceID : nil
  }.sorted()
}

private func boundaryDistinguishingCheckIDs(
  _ generation: SharedEpisodeGeneration
) -> [String: String] {
  var reservationsByPermitID: [String: SharedEpisodeActionReservation] = [:]
  var result: [String: String] = [:]
  for entry in generation.eventJournal.entries {
    guard case .control(let command) = entry.event else { continue }
    switch command {
    case .actionReserved(let reservation):
      reservationsByPermitID[reservation.permitID] = reservation
    case .verification(let verification, let settlement):
      if let checkID = reservationsByPermitID[settlement.permitID]?
        .distinguishingCheckID
      {
        result[verification.recordID] = checkID
      }
    case .contribution, .selection, .modelOnlyCompleted,
      .transitionParked, .terminal:
      break
    }
  }
  return result
}

private func appendForeignClaimVerification(
  to generation: SharedEpisodeGeneration,
  claimID: String = "claim.adversarial.boundary",
  distinguishingCheckID: String? = nil
) throws -> (completed: SharedEpisodeGeneration, evidenceID: String) {
  let parent = try boundarySHA256(generation)
  let template = try SharedEpisodeMemoryFixtures.verification(
    named: .externalPassed,
    parentGenerationSHA256: parent
  )
  let claim = SharedEpisodeVerificationClaim(
    claimID: claimID,
    contributionID: "contribution.primary",
    resultSHA256: try XCTUnwrap(
      generation.state.contributions.first {
        $0.contributionID == "contribution.primary"
      }
    ).contentSHA256
  )
  let evidence = template.content.evidence.map {
    SharedEpisodeVerificationEvidence(
      schemaVersion: $0.schemaVersion,
      evidenceID: "evidence.adversarial.\($0.criterionID)",
      claimID: claimID,
      criterionID: $0.criterionID,
      observationID: $0.observationID,
      observationSHA256: $0.observationSHA256,
      resultSHA256: $0.resultSHA256,
      finding: $0.finding
    )
  }.sorted { $0.evidenceID < $1.evidenceID }
  let content = SharedEpisodeVerificationContent(
    verificationPlanArtifactID: template.content.verificationPlanArtifactID,
    criterionIDs: template.content.criterionIDs,
    claims: [claim],
    evidence: evidence,
    outcome: .passed,
    disagreements: []
  )
  let contentSHA256 = try boundarySHA256(content.canonicalJSONData())
  let recordID = "verification.record.adversarial-external"
  let provenance = SharedEpisodeVerificationProvenance(
    schemaVersion: template.provenance.schemaVersion,
    recordID: recordID,
    executorID: template.provenance.executorID,
    roleID: template.provenance.roleID,
    verificationPlanArtifactID: template.provenance.verificationPlanArtifactID,
    modelID: template.provenance.modelID,
    providerID: template.provenance.providerID,
    taskSHA256: template.provenance.taskSHA256,
    localInputSHA256s: template.provenance.localInputSHA256s,
    parentGenerationSHA256: parent,
    resultSHA256: contentSHA256,
    correlationLinks: template.provenance.correlationLinks
  )
  let draft = SharedEpisodeVerificationRecord(
    recordID: recordID,
    parentGenerationSHA256: parent,
    verifier: template.verifier,
    contentSHA256: contentSHA256,
    content: content,
    provenance: provenance
  )
  let budget = try SharedEpisodeControlKernel.meteredUsage(
    for: draft,
    executors: 1,
    rounds: 1
  )
  let reservedBudget: SharedEpisodeBudgetVector
  if let distinguishingCheckID {
    reservedBudget = try XCTUnwrap(
      generation.seed.controlPlan.distinguishingChecks.first {
        $0.checkID == distinguishingCheckID
      }
    ).budget
  } else {
    reservedBudget = budget
  }
  let reservation = boundaryReservation(
    suffix: "foreign-evidence.verification",
    parent: parent,
    phase: .verification,
    kind: .verification,
    distinguishingCheckID: distinguishingCheckID,
    reserved: reservedBudget
  )
  let reserved = try SharedEpisodeMemoryReducer.continuation(
    from: generation,
    control: .actionReserved(reservation)
  )
  let record = draft.rebinding(
    parentGenerationSHA256: try boundarySHA256(reserved)
  )
  let completed = try SharedEpisodeMemoryReducer.continuation(
    from: reserved,
    control: .verification(
      record,
      boundarySettlement(reservation, actual: budget)
    )
  )
  return (completed, try XCTUnwrap(evidence.first).evidenceID)
}

private func boundarySHA256(
  _ generation: SharedEpisodeGeneration
) throws -> String {
  boundarySHA256(try generation.canonicalJSONData())
}

private func boundarySHA256(_ data: Data) -> String {
  SharedEpisodeEmbeddedArtifact(
    artifactID: "boundary.hash",
    kind: "boundary_hash",
    logicalPath: "boundary/hash.bin",
    mediaType: "application/octet-stream",
    data: data
  ).contentSHA256
}

private func boundaryTemporaryDirectory(_ suffix: String) throws -> URL {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent(
    "fum-episode-control-boundary-\(suffix)-\(UUID().uuidString)",
    isDirectory: true
  )
  try FileManager.default.createDirectory(
    at: url,
    withIntermediateDirectories: false
  )
  return url
}
