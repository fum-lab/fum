import XCTest

@testable import FUMLiveEpisodeCore

final class LiveEpisodeFixtureTests: XCTestCase {
  func testTwoVariantFixturePreservesProvenanceAndClosedTransition() throws {
    let result = try LiveEpisodeFixture.run()
    let state = result.state
    let checkpoint = try XCTUnwrap(state.model.commonCheckpoint)
    let selection = try XCTUnwrap(state.model.selection)

    XCTAssertEqual(state.model.variants.count, 2)
    XCTAssertEqual(
      Set(state.model.variants.map(\.proposal.parentCheckpointID)),
      Set([checkpoint.checkpointID])
    )
    XCTAssertEqual(Set(state.model.variants.map(\.proposal.variantID)), ["variant-a", "variant-b"])

    for variant in state.model.variants {
      XCTAssertNotNil(variant.responseEventID, variant.proposal.variantID)
      XCTAssertNotNil(variant.response, variant.proposal.variantID)
      XCTAssertNotNil(variant.intentEventID, variant.proposal.variantID)
      XCTAssertNotNil(variant.intent, variant.proposal.variantID)
      XCTAssertEqual(variant.verificationEventIDs.count, 1, variant.proposal.variantID)
      XCTAssertEqual(variant.verifications.map(\.status), [.passed], variant.proposal.variantID)
      XCTAssertTrue(
        variant.verifications.allSatisfy { !$0.evidence.evidenceSHA256.isEmpty },
        variant.proposal.variantID
      )
    }

    let selectedVariant = try XCTUnwrap(
      state.model.variants.first(where: {
        $0.proposal.variantID == selection.selectedVariantID
      })
    )
    XCTAssertEqual(selection.status, .selectedInModel)
    XCTAssertEqual(selection.consideredVariantIDs, ["variant-a", "variant-b"])
    XCTAssertEqual(selection.sourceResponseID, selectedVariant.response?.responseID)
    XCTAssertEqual(selection.sourceIntentID, selectedVariant.intent?.intent.intentID)
    XCTAssertEqual(
      Set(selection.basisVerificationIDs),
      Set(["verification-variant-a", "verification-variant-b"])
    )

    let transition = try XCTUnwrap(state.transition)
    XCTAssertEqual(transition.phase, .awaitingConfirmation)
    XCTAssertNil(transition.confirmation)
    XCTAssertNil(transition.authorization)
    XCTAssertNil(transition.preflight)
    XCTAssertNil(transition.execution)
    XCTAssertNil(transition.observation)
    XCTAssertNil(transition.verification)

    XCTAssertEqual(state.latestBudgetCheckpoint?.checkpoint.reason, .insufficientBudget)
    XCTAssertFalse(
      result.events.contains(where: { event in
        guard case .modelRequestRecorded(let request) = event.payload else { return false }
        return request.proposal.requestID == "request-variant-c"
      })
    )
  }

  func testFixtureReplaysAndRepeatsItsLastEventIdempotently() throws {
    let result = try LiveEpisodeFixture.run()

    let replayed = try LiveEpisodeReducer.replay(
      passport: result.passport,
      events: result.events
    )
    XCTAssertEqual(replayed, result.state)

    let last = try XCTUnwrap(result.events.last)
    let repeated = try LiveEpisodeReducer.applying(last, to: result.state)
    XCTAssertEqual(repeated, result.state)
  }

  func testLateConfirmationAdvancesOnlyTransitionAfterTerminalModelDecision() throws {
    let result = try LiveEpisodeFixture.run()
    let terminal = result.state
    let coordinates = try XCTUnwrap(terminal.transition?.declaration.coordinates)
    let confirmation = LiveEpisodeEvent(
      episodeID: terminal.passport.episodeID,
      eventID: "event-late-transition-confirmation",
      sequence: terminal.nextSequence,
      payload: .transitionUserConfirmed(
        LiveTransitionUserConfirmed(
          coordinates: coordinates,
          evidence: LiveEvidenceObject(
            evidenceID: "evidence-late-transition-confirmation",
            evidenceSHA256: "sha256:" + String(repeating: "c", count: 64)
          )
        )
      )
    )

    let confirmed = try LiveEpisodeReducer.applying(confirmation, to: terminal)

    XCTAssertTrue(confirmed.isTerminal)
    XCTAssertEqual(confirmed.transition?.phase, .transitionUserConfirmed)
    XCTAssertEqual(confirmed.model, terminal.model)
    XCTAssertEqual(confirmed.continuation, terminal.continuation)
    XCTAssertEqual(confirmed.latestBudgetCheckpoint, terminal.latestBudgetCheckpoint)
    XCTAssertEqual(confirmed.events, terminal.events + [confirmation])

    let proposal = try XCTUnwrap(terminal.latestBudgetCheckpoint?.checkpoint.proposal)
    let forbiddenModelEvent = LiveEpisodeEvent(
      episodeID: terminal.passport.episodeID,
      eventID: "event-model-after-terminal-decision",
      sequence: confirmed.nextSequence,
      payload: .modelRequestRecorded(LiveModelRequestRecorded(proposal: proposal))
    )
    XCTAssertThrowsError(
      try LiveEpisodeReducer.applying(forbiddenModelEvent, to: confirmed)
    ) { error in
      XCTAssertEqual(error as? LiveEpisodeError, .terminalEpisode)
    }
  }
}
