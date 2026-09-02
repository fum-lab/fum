import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class EpisodeControlTests: XCTestCase {
  func testSelectionUsesConcreteExternalEvidenceInsteadOfCorrelatedCopies() throws {
    let prefix = try SharedEpisodeControlFixtures.selectionPrefix(
      correlatedCopyCount: 3,
      includeFailedVerification: true
    )
    let selected = try SharedEpisodeControlFixtures.appendSelection(
      named: .externalEvidence,
      to: prefix
    )

    let decision = try XCTUnwrap(selected.state.selectionDecisions.last)
    let chosenID = try XCTUnwrap(decision.selectedContributionID)
    let chosen = try XCTUnwrap(
      prefix.state.contributions.first { $0.contributionID == chosenID }
    )
    let consideration = try XCTUnwrap(
      decision.considerations.first { $0.contributionID == chosenID }
    )

    XCTAssertEqual(decision.basis, .verifiedEvidence)
    XCTAssertEqual(decision.status, .selectedInModel)
    XCTAssertFalse(decision.userConfirmed)
    XCTAssertFalse(decision.authorized)
    XCTAssertEqual(
      Set(decision.considerations.map(\.contributionID)),
      Set(prefix.state.contributions.map(\.contributionID))
    )
    XCTAssertEqual(consideration.contentSHA256, chosen.contentSHA256)
    XCTAssertEqual(
      consideration.provenanceSHA256,
      episodeControlSHA(try chosen.provenance.canonicalJSONData())
    )
    XCTAssertFalse(consideration.verificationRecordIDs.isEmpty)
    XCTAssertFalse(consideration.evidenceIDs.isEmpty)
    XCTAssertTrue(
      consideration.verificationRecordIDs.allSatisfy { recordID in
        prefix.state.verificationReport.assessmentsByRecordID[recordID]?.standing
          == .externalByObservedFeatures
      }
    )
    XCTAssertEqual(
      Set(decision.disagreementDispositions.map(\.disagreementID)),
      Set(prefix.state.verificationReport.disagreements.map(\.disagreementID))
    )
    XCTAssertEqual(
      Set(selected.eventJournal.entries.suffix(2).map(\.event.kind)),
      Set([.actionReserved, .selection])
    )
    XCTAssertTrue(selected.state.openReservations.isEmpty)

    let copyIDs = prefix.state.contributions
      .filter { $0.contributionID != chosenID && $0.contentSHA256 == chosen.contentSHA256 }
      .map(\.contributionID)
    XCTAssertEqual(copyIDs.count, 3)
    XCTAssertTrue(copyIDs.allSatisfy { $0 != decision.selectedContributionID })
  }

  func testSelectionRejectsVotingAndOmittedDisagreements() throws {
    let prefix = try SharedEpisodeControlFixtures.selectionPrefix(
      correlatedCopyCount: 2,
      includeFailedVerification: true
    )

    for fixture in [
      SharedEpisodeSelectionFixture.assertionVote,
      .omitsDisagreement,
    ] {
      XCTAssertThrowsError(
        try SharedEpisodeControlFixtures.appendSelection(named: fixture, to: prefix),
        "Fixture \(fixture) must fail closed."
      ) { error in
        guard case SharedEpisodeMemoryError.invalidSelection = error else {
          return XCTFail("Unexpected error for \(fixture): \(error)")
        }
      }
    }
    XCTAssertTrue(prefix.state.selectionDecisions.isEmpty)
  }

  func testSelectionKeepsEvidenceBoundToItsExactContribution() throws {
    let plan = SharedEpisodeControlPlan.fixtureDefault
    let initial = try SharedEpisodeControlKernel.initialState(plan: plan)
    let reserveParent = episodeControlSHA("selection evidence reserve parent")
    let selectionParent = episodeControlSHA("selection evidence decision parent")
    let unit = SharedEpisodeBudgetVector(
      executors: 1,
      rounds: 1,
      modelCalls: 1,
      toolCalls: 1,
      input: 1,
      output: 1
    )
    let reservation = SharedEpisodeActionReservation(
      permitID: "permit.selection.evidence-binding",
      actionID: "action.selection.evidence-binding",
      parentGenerationSHA256: reserveParent,
      phase: .verification,
      kind: .selection,
      executorID: plan.selectorID,
      roundID: "round.selection.evidence-binding",
      continuationID: nil,
      distinguishingCheckID: nil,
      reserved: unit
    )
    let reserved = try SharedEpisodeControlKernel.apply(
      .actionReserved(reservation),
      to: initial,
      plan: plan,
      expectedParentGenerationSHA256: reserveParent
    )
    let context = SharedEpisodeSelectionEvidenceContext(
      criteriaArtifactID: "criteria.main",
      criteriaSHA256: episodeControlSHA("selection criteria"),
      criterionIDs: ["criterion.primary"],
      contributions: [
        SharedEpisodeSelectionContributionSnapshot(
          contributionID: "contribution.one",
          contentSHA256: episodeControlSHA("contribution one"),
          provenanceSHA256: episodeControlSHA("provenance one")
        ),
        SharedEpisodeSelectionContributionSnapshot(
          contributionID: "contribution.two",
          contentSHA256: episodeControlSHA("contribution two"),
          provenanceSHA256: episodeControlSHA("provenance two")
        ),
      ],
      verifications: [
        SharedEpisodeSelectionVerificationSnapshot(
          recordID: "verification.mixed",
          contributionIDs: ["contribution.one", "contribution.two"],
          evidenceIDs: ["evidence.one"],
          evidenceBindings: [
            SharedEpisodeSelectionEvidenceBinding(
              contributionID: "contribution.one",
              evidenceIDs: ["evidence.one"]
            ),
            SharedEpisodeSelectionEvidenceBinding(
              contributionID: "contribution.two",
              evidenceIDs: []
            ),
          ],
          outcome: .inconclusive,
          standing: .externalByObservedFeatures
        )
      ],
      disagreements: []
    )
    let selectionContextSHA256 = episodeControlSHA(
      try context.canonicalJSONData()
    )
    let settlement = SharedEpisodeActionSettlement(
      permitID: reservation.permitID,
      actionID: reservation.actionID,
      actual: unit
    )
    func decision(secondEvidenceIDs: [String]) -> SharedEpisodeSelectionDecision {
      SharedEpisodeSelectionDecision(
        decisionID: "decision.evidence-binding",
        parentGenerationSHA256: selectionParent,
        selectionContextSHA256: selectionContextSHA256,
        selectionPolicyID: plan.selectionPolicyID,
        selectionPlanArtifactID: plan.selectionPlanArtifactID,
        stopPolicyID: plan.stopPolicyID,
        selectorID: plan.selectorID,
        selectorRoleID: plan.selectorRoleID,
        criteriaArtifactID: context.criteriaArtifactID,
        criteriaSHA256: context.criteriaSHA256,
        criterionIDs: context.criterionIDs,
        considerations: zip(context.contributions, [["evidence.one"], secondEvidenceIDs])
          .map { contribution, evidenceIDs in
            SharedEpisodeSelectionConsideration(
              contributionID: contribution.contributionID,
              contentSHA256: contribution.contentSHA256,
              provenanceSHA256: contribution.provenanceSHA256,
              verificationRecordIDs: ["verification.mixed"],
              evidenceIDs: evidenceIDs,
              disposition: .rejected,
              reasonCode: "reason.not-selected"
            )
          },
        disagreementDispositions: [],
        selectedContributionID: nil,
        basis: .verifiedEvidence,
        status: .selectedInModel,
        userConfirmed: false,
        authorized: false
      )
    }

    XCTAssertThrowsError(
      try SharedEpisodeControlKernel.apply(
        .selection(decision(secondEvidenceIDs: ["evidence.one"]), settlement),
        to: reserved,
        plan: plan,
        expectedParentGenerationSHA256: selectionParent,
        selectionContext: context
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidSelection = error else {
        return XCTFail("Unexpected cross-contribution evidence error: \(error)")
      }
    }
    let accepted = try SharedEpisodeControlKernel.apply(
      .selection(decision(secondEvidenceIDs: []), settlement),
      to: reserved,
      plan: plan,
      expectedParentGenerationSHA256: selectionParent,
      selectionContext: context
    )
    XCTAssertEqual(accepted.selectionDecisions.count, 1)
  }

  func testSeedRejectsSelectorDetachedFromPassportPolicy() throws {
    let original = SharedEpisodeControlPlan.fixtureDefault
    let detached = SharedEpisodeControlPlan(
      schemaVersion: original.schemaVersion,
      budget: original.budget,
      selectionPolicyID: original.selectionPolicyID,
      selectionPlanArtifactID: original.selectionPlanArtifactID,
      stopPolicyID: original.stopPolicyID,
      selectorID: "selector.detached",
      selectorRoleID: original.selectorRoleID,
      selectionBasis: original.selectionBasis,
      agreementIsEvidence: original.agreementIsEvidence,
      independenceInferredFromCount: original.independenceInferredFromCount,
      continuations: original.continuations,
      distinguishingChecks: original.distinguishingChecks
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryFixtures.seed(controlPlan: detached)
    ) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected detached-selector error: \(error)")
      }
    }
  }

  func testEveryBudgetDimensionAdmitsExactFitAndStopsAtOneOver() throws {
    for dimension in SharedEpisodeBudgetDimension.allCases {
      let exact = try SharedEpisodeControlFixtures.budgetBoundary(
        dimension: dimension,
        overBy: 0
      )
      let admitted = try SharedEpisodeMemoryReducer.continuation(
        from: exact.generation,
        control: .actionReserved(exact.reservation)
      )
      let open = try XCTUnwrap(
        admitted.state.openReservations.first {
          $0.permitID == exact.reservation.permitID
        }
      )

      XCTAssertNil(admitted.state.terminal, "Exact fit failed for \(dimension).")
      XCTAssertEqual(open.reserved, exact.reservation.reserved)
      XCTAssertEqual(
        budgetComponent(admitted.state.budgetState.remaining, dimension),
        budgetComponent(exact.expectedRemaining, dimension),
        "Wrong exact-fit remainder for \(dimension)."
      )

      let oneOver = try SharedEpisodeControlFixtures.budgetBoundary(
        dimension: dimension,
        overBy: 1
      )
      XCTAssertThrowsError(
        try SharedEpisodeMemoryReducer.continuation(
          from: oneOver.generation,
          control: .actionReserved(oneOver.reservation)
        ),
        "One-over reservation was admitted for \(dimension)."
      ) { error in
        guard case SharedEpisodeMemoryError.budgetLimitExceeded(let actual) = error else {
          return XCTFail("Unexpected one-over error for \(dimension): \(error)")
        }
        XCTAssertEqual(actual, dimension)
      }

      let stopped = try SharedEpisodeControlFixtures.appendBudgetExhaustedTerminal(
        blockedReservation: oneOver.reservation,
        to: oneOver.generation
      )
      XCTAssertEqual(stopped.state.terminal?.outcome, .budgetExhausted)
      XCTAssertEqual(stopped.state.terminal?.reason.budgetDimension, dimension)
      XCTAssertEqual(
        stopped.state.terminal?.reason.blockedActionID,
        oneOver.reservation.actionID
      )
    }
  }

  func testProductiveActionCannotConsumeVerificationOrHandoffReserve() throws {
    let fixture = try SharedEpisodeControlFixtures.fullyProtectedReserve()

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: fixture.generation,
        control: .actionReserved(fixture.productiveReservation)
      )
    ) { error in
      guard case SharedEpisodeMemoryError.protectedReserveRequired = error else {
        return XCTFail("Unexpected protected-reserve error: \(error)")
      }
    }

    let verification = try SharedEpisodeMemoryReducer.continuation(
      from: fixture.generation,
      control: .actionReserved(fixture.verificationReservation)
    )
    let handoff = try SharedEpisodeMemoryReducer.continuation(
      from: verification,
      control: .actionReserved(
        fixture.handoffReservation.rebinding(
          parentGenerationSHA256: episodeControlSHA(
            try verification.canonicalJSONData()
          )
        )
      )
    )

    XCTAssertEqual(
      Set(handoff.state.openReservations.map(\.phase)),
      Set([.verification, .handoff])
    )
    XCTAssertTrue(handoff.state.budgetState.remaining.isZero)
  }

  func testSettlementClosesExactPermitAndCannotExceedReservation() throws {
    let fixture = try SharedEpisodeControlFixtures.modelOnlySettlement()
    let reserved = try SharedEpisodeMemoryReducer.continuation(
      from: fixture.generation,
      control: .actionReserved(fixture.reservation)
    )

    XCTAssertEqual(reserved.state.openReservations.map(\.permitID), [fixture.reservation.permitID])
    XCTAssertEqual(reserved.state.budgetState.inFlight, fixture.reservation.reserved)

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: reserved,
        control: .modelOnlyCompleted(
          fixture.result.rebinding(
            parentGenerationSHA256: episodeControlSHA(try reserved.canonicalJSONData())
          ),
          fixture.overSettlement
        )
      )
    ) { error in
      guard case SharedEpisodeMemoryError.settlementExceedsReservation = error else {
        return XCTFail("Unexpected over-settlement error: \(error)")
      }
    }

    let settled = try SharedEpisodeMemoryReducer.continuation(
      from: reserved,
      control: .modelOnlyCompleted(
        fixture.result.rebinding(
          parentGenerationSHA256: episodeControlSHA(try reserved.canonicalJSONData())
        ),
        fixture.settlement
      )
    )
    XCTAssertTrue(settled.state.openReservations.isEmpty)
    XCTAssertTrue(settled.state.budgetState.inFlight.isZero)
    XCTAssertEqual(settled.state.budgetState.charged, fixture.settlement.actual)
  }

  func testPendingTransitionDoesNotBlockModelOnlyOrElevateInternalSelection() throws {
    let trace = try SharedEpisodeControlFixtures.pendingTransitionModelOnlyTrace()
    let parked = trace.afterTransitionParked.state
    let continued = trace.afterModelOnlyContinuation.state
    let transitionBefore = try XCTUnwrap(parked.pendingTransitions.first)
    let transitionAfter = try XCTUnwrap(continued.pendingTransitions.first)
    let decision = try XCTUnwrap(continued.selectionDecisions.last)

    XCTAssertEqual(transitionBefore.phase, .awaitingConfirmation)
    XCTAssertEqual(transitionAfter, transitionBefore)
    XCTAssertNil(continued.terminal)
    XCTAssertEqual(decision.status, .selectedInModel)
    XCTAssertFalse(decision.userConfirmed)
    XCTAssertFalse(decision.authorized)
    XCTAssertGreaterThan(
      trace.afterModelOnlyContinuation.eventJournal.entries.count,
      trace.afterTransitionParked.eventJournal.entries.count
    )
    XCTAssertEqual(
      trace.afterModelOnlyContinuation.eventJournal.entries.suffix(2).map(\.event.kind),
      [.actionReserved, .modelOnlyCompleted]
    )
  }

  func testNeedsInputRequiresExhaustedSafeProductiveContinuations() throws {
    let premature = try SharedEpisodeControlFixtures.needsInputScenario(
      safeProductiveContinuationsExhausted: false
    )
    XCTAssertFalse(premature.generation.state.controlReport.safeProductiveContinuationIDs.isEmpty)
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: premature.generation,
        control: .terminal(premature.terminal, premature.settlement)
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidTerminal = error else {
        return XCTFail("Unexpected premature needs_input error: \(error)")
      }
    }

    let inFlight = try SharedEpisodeControlFixtures.needsInputScenario(
      safeProductiveContinuationsExhausted: false,
      usefulContinuationInFlight: true
    )
    XCTAssertTrue(inFlight.generation.state.controlReport.safeProductiveContinuationIDs.isEmpty)
    XCTAssertFalse(inFlight.generation.state.openReservations.isEmpty)
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: inFlight.generation,
        control: .terminal(inFlight.terminal, inFlight.settlement)
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidTerminal = error else {
        return XCTFail("Unexpected in-flight needs_input error: \(error)")
      }
    }

    let exhausted = try SharedEpisodeControlFixtures.needsInputScenario(
      safeProductiveContinuationsExhausted: true
    )
    XCTAssertTrue(exhausted.generation.state.controlReport.safeProductiveContinuationIDs.isEmpty)
    let stopped = try SharedEpisodeMemoryReducer.continuation(
      from: exhausted.generation,
      control: .terminal(exhausted.terminal, exhausted.settlement)
    )
    XCTAssertEqual(stopped.state.terminal?.outcome, .needsInput)
    XCTAssertNotNil(stopped.state.terminal?.reason.pendingTransitionID)
  }

  func testUnresolvedConflictRequiresExhaustedDistinguishingChecks() throws {
    let premature = try SharedEpisodeControlFixtures.unresolvedConflictScenario(
      distinguishingChecksExhausted: false
    )
    XCTAssertFalse(premature.generation.state.unresolvedDisagreementIDs.isEmpty)
    XCTAssertFalse(
      premature.generation.state.controlReport.affordableDistinguishingCheckIDs.isEmpty
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: premature.generation,
        control: .terminal(premature.terminal, premature.settlement)
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidTerminal = error else {
        return XCTFail("Unexpected premature unresolved_conflict error: \(error)")
      }
    }

    let inFlight = try SharedEpisodeControlFixtures.unresolvedConflictScenario(
      distinguishingChecksExhausted: false,
      distinguishingCheckInFlight: true
    )
    XCTAssertTrue(
      inFlight.generation.state.controlReport.affordableDistinguishingCheckIDs.isEmpty
    )
    XCTAssertFalse(inFlight.generation.state.openReservations.isEmpty)
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: inFlight.generation,
        control: .terminal(inFlight.terminal, inFlight.settlement)
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidTerminal = error else {
        return XCTFail("Unexpected in-flight unresolved_conflict error: \(error)")
      }
    }

    let exhausted = try SharedEpisodeControlFixtures.unresolvedConflictScenario(
      distinguishingChecksExhausted: true
    )
    XCTAssertFalse(exhausted.generation.state.unresolvedDisagreementIDs.isEmpty)
    XCTAssertTrue(exhausted.generation.state.controlReport.affordableDistinguishingCheckIDs.isEmpty)
    let stopped = try SharedEpisodeMemoryReducer.continuation(
      from: exhausted.generation,
      control: .terminal(exhausted.terminal, exhausted.settlement)
    )
    XCTAssertEqual(stopped.state.terminal?.outcome, .unresolvedConflict)
    XCTAssertEqual(
      Set(try XCTUnwrap(stopped.state.terminal).unresolvedDisagreementIDs),
      Set(stopped.state.unresolvedDisagreementIDs)
    )
  }

  func testEveryControlEventIsRejectedAfterTerminal() throws {
    let terminal = try SharedEpisodeControlFixtures.terminalEpisode(outcome: .goalMet)
    let commands = try SharedEpisodeControlFixtures.everyCommandAfterTerminal(
      terminal.generation
    )

    XCTAssertEqual(
      Set(commands.map(\.kind)),
      Set(SharedEpisodeControlCommand.Kind.allCases)
    )
    for command in commands {
      XCTAssertThrowsError(
        try SharedEpisodeMemoryReducer.continuation(
          from: terminal.generation,
          control: command
        ),
        "Post-terminal command \(command.kind) was accepted."
      ) { error in
        guard case SharedEpisodeMemoryError.terminalEpisode = error else {
          return XCTFail("Unexpected post-terminal error for \(command.kind): \(error)")
        }
      }
    }
  }

  func testCanonicalReplayAndStoreReloadPreserveControlStateByteForByte() throws {
    let trace = try SharedEpisodeControlFixtures.canonicalTerminalTrace()
    let root = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }

    let store = SharedEpisodeMemoryStore(rootURL: root)
    var stored: StoredSharedEpisodeGeneration?
    for generation in trace.generations {
      stored = try store.commit(generation)
    }
    let expected = try XCTUnwrap(stored)
    let recovered = try XCTUnwrap(SharedEpisodeMemoryStore(rootURL: root).loadCurrent())
    let decoded = try SharedEpisodeGeneration.decodeCanonical(
      recovered.generation.canonicalJSONData()
    )
    let replayed = try SharedEpisodeMemoryReducer.replay(
      seed: decoded.seed,
      journal: decoded.eventJournal
    )

    XCTAssertEqual(recovered, expected)
    XCTAssertEqual(replayed, decoded.state)
    XCTAssertEqual(
      try replayed.canonicalJSONData(),
      try decoded.state.canonicalJSONData()
    )
    XCTAssertEqual(replayed.selectionDecisions, trace.finalState.selectionDecisions)
    XCTAssertEqual(replayed.budgetState.remaining, trace.finalState.budgetState.remaining)
    XCTAssertEqual(replayed.terminal, trace.finalState.terminal)
    XCTAssertEqual(
      replayed.unresolvedDisagreementIDs,
      trace.finalState.unresolvedDisagreementIDs
    )
    XCTAssertEqual(replayed.openReservations, trace.finalState.openReservations)
    XCTAssertFalse(replayed.openReservations.isEmpty)
  }

  func testNewSemanticRunRequiresFreshPackageAndExactTerminalPredecessor() throws {
    let trace = try SharedEpisodeControlFixtures.canonicalTerminalTrace()
    let terminal = try XCTUnwrap(trace.generations.last)
    let terminalSHA256 = episodeControlSHA(
      try terminal.canonicalJSONData()
    )
    let validSeed = try SharedEpisodeControlFixtures.resumedSeed(
      from: terminal,
      runGenerationID: "run.generation.2",
      package: .fresh,
      predecessorTerminalGenerationSHA256: terminalSHA256
    )
    let resumed = try SharedEpisodeMemoryReducer.resumedFoundation(
      seed: validSeed,
      predecessorTerminal: terminal
    )

    XCTAssertEqual(resumed.seed.runGenerationID, "run.generation.2")
    XCTAssertEqual(
      resumed.seed.predecessorTerminalGenerationSHA256,
      terminalSHA256
    )
    XCTAssertNotEqual(
      resumed.seed.activeWorkPackageArtifactID,
      terminal.seed.activeWorkPackageArtifactID
    )
    let oldPackage = try XCTUnwrap(
      terminal.seed.artifacts.first {
        $0.artifactID == terminal.seed.activeWorkPackageArtifactID
      })
    let newPackage = try XCTUnwrap(
      resumed.seed.artifacts.first {
        $0.artifactID == resumed.seed.activeWorkPackageArtifactID
      })
    XCTAssertNotEqual(newPackage.contentSHA256, oldPackage.contentSHA256)
    XCTAssertEqual(resumed.previousGenerationSHA256, terminalSHA256)
    XCTAssertNil(resumed.state.terminal)
    XCTAssertTrue(resumed.eventJournal.entries.isEmpty)

    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    var storedTerminal: StoredSharedEpisodeGeneration?
    for generation in trace.generations {
      storedTerminal = try store.commit(generation)
    }
    XCTAssertEqual(storedTerminal?.generationSHA256, terminalSHA256)
    let storedResumed = try store.commit(resumed)
    XCTAssertEqual(storedResumed.generation, resumed)
    XCTAssertEqual(try store.loadCurrent(), storedResumed)

    let emptyStore = SharedEpisodeMemoryStore(rootURL: try temporaryDirectory())
    XCTAssertThrowsError(try emptyStore.commit(resumed)) { error in
      guard case SharedEpisodeMemoryError.generationConflict = error else {
        return XCTFail("Unexpected empty-store resumption error: \(error)")
      }
    }

    let reusedPackage = try SharedEpisodeControlFixtures.resumedSeed(
      from: terminal,
      runGenerationID: "run.generation.2",
      package: .predecessor,
      predecessorTerminalGenerationSHA256: terminalSHA256
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.resumedFoundation(
        seed: reusedPackage,
        predecessorTerminal: terminal
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidResumption = error else {
        return XCTFail("Unexpected reused-package error: \(error)")
      }
    }

    let wrongPredecessor = try SharedEpisodeControlFixtures.resumedSeed(
      from: terminal,
      runGenerationID: "run.generation.2",
      package: .fresh,
      predecessorTerminalGenerationSHA256: episodeControlSHA("wrong predecessor")
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.resumedFoundation(
        seed: wrongPredecessor,
        predecessorTerminal: terminal
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidResumption = error else {
        return XCTFail("Unexpected predecessor error: \(error)")
      }
    }
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-episode-control-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: false
    )
    return url
  }
}

private func budgetComponent(
  _ budget: SharedEpisodeBudgetVector,
  _ dimension: SharedEpisodeBudgetDimension
) -> Int64 {
  switch dimension {
  case .executors:
    budget.executors
  case .rounds:
    budget.rounds
  case .modelCalls:
    budget.modelCalls
  case .toolCalls:
    budget.toolCalls
  case .input:
    budget.input
  case .output:
    budget.output
  }
}

private func episodeControlSHA(_ value: String) -> String {
  episodeControlSHA(Data(value.utf8))
}

private func episodeControlSHA(_ data: Data) -> String {
  SharedEpisodeEmbeddedArtifact(
    artifactID: "hash.episode-control-test",
    kind: "hash",
    logicalPath: "hash.episode-control-test",
    mediaType: "application/octet-stream",
    data: data
  ).contentSHA256
}
