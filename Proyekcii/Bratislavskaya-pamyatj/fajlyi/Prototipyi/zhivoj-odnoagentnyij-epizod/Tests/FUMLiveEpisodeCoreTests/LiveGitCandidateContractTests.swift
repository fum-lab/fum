import Foundation
import XCTest

@testable import FUMLiveEpisodeCore

final class LiveGitCandidateContractTests: XCTestCase {
  func testLegacyAllowedActionRoundTripsWithoutCandidatePolicyField() throws {
    let legacy = LiveAllowedAction(
      allowanceID: "allow-legacy",
      operation: "store_candidate",
      adapterID: "legacy-adapter",
      effectClass: "external_write"
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(legacy)

    XCTAssertEqual(
      String(decoding: data, as: UTF8.self),
      #"{"adapter_id":"legacy-adapter","allowance_id":"allow-legacy","effect_class":"external_write","operation":"store_candidate"}"#
    )
    XCTAssertEqual(try JSONDecoder().decode(LiveAllowedAction.self, from: data), legacy)
  }

  func testCandidatePolicyIsVersionedClosedAndRejectsUnsafePathsAndWrongOperation() throws {
    let policy = makePolicy()
    XCTAssertNoThrow(try policy.validate())

    for path in ["/absolute.txt", "../escape.txt", "safe/../escape.txt", ".git/config"] {
      XCTAssertThrowsError(try replacingPolicy(policy, allowedPaths: [path]).validate()) {
        XCTAssertTrue($0 is LiveGitCandidateContractError)
      }
    }

    let candidateAction = LiveAllowedAction(
      allowanceID: "allow-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated_git_write",
      candidateCommitPolicy: policy
    )
    XCTAssertNoThrow(try candidateAction.validateCandidateCommitPolicy())

    let wrongOperation = LiveAllowedAction(
      allowanceID: "allow-candidate",
      operation: "store_candidate",
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated_git_write",
      candidateCommitPolicy: policy
    )
    XCTAssertThrowsError(try wrongOperation.validateCandidateCommitPolicy()) {
      XCTAssertEqual(
        $0 as? LiveGitCandidateContractError,
        .invalidPolicy("candidate_commit_policy допустим только для create_candidate_commit.")
      )
    }

    let encoded = try LiveGitCandidateCanonicalJSON.encode(candidateAction)
    var object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    )
    var nested = try XCTUnwrap(object["candidate_commit_policy"] as? [String: Any])
    nested["unexpected"] = true
    object["candidate_commit_policy"] = nested
    let unknownField = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    XCTAssertThrowsError(
      try JSONDecoder().decode(LiveAllowedAction.self, from: unknownField)
    )

    let unknownGrammar = String(decoding: encoded, as: UTF8.self)
      .replacingOccurrences(of: "git_diff_check_v1", with: "shell_v1")
    XCTAssertThrowsError(
      try JSONDecoder().decode(
        LiveAllowedAction.self,
        from: Data(unknownGrammar.utf8)
      )
    )
  }

  func testReceiptChainRequiresExactOrderCoordinatesProducersAndPredecessorHashes() throws {
    let policy = makePolicy()
    let coordinates = makeCoordinates()
    let receipts = makeReceiptChain(policy: policy, coordinates: coordinates)

    XCTAssertNoThrow(
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: coordinates
      )
    )
    let candidateOwnedEvents = makeReceiptEvents(receipts)
    for (index, stage) in LiveGitCandidateStage.allCases.enumerated() {
      XCTAssertNoThrow(
        try LiveGitCandidateReceiptChain.validatePrefix(
          Array(receipts.prefix(index + 1)),
          through: stage,
          policy: policy,
          expectedCoordinates: coordinates,
          candidateOwnedEvents: Array(candidateOwnedEvents.prefix(index + 1))
        )
      )
    }
    XCTAssertThrowsError(
      try LiveGitCandidateReceiptChain.validatePrefix(
        [],
        through: .transitionUserConfirmed,
        policy: policy,
        expectedCoordinates: coordinates
      )
    )
    XCTAssertNoThrow(
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: coordinates,
        candidateOwnedEvents: candidateOwnedEvents
      )
    )
    XCTAssertThrowsError(
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: coordinates,
        candidateOwnedEvents: Array(candidateOwnedEvents.dropLast())
      )
    )
    var reorderedEvents = candidateOwnedEvents
    reorderedEvents.swapAt(1, 2)
    XCTAssertThrowsError(
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: coordinates,
        candidateOwnedEvents: reorderedEvents
      )
    )

    var reordered = receipts
    reordered.swapAt(1, 2)
    assertReceiptChainRejected(reordered, policy: policy, coordinates: coordinates)

    var foreign = receipts
    foreign[3] = replacingReceipt(
      foreign[3],
      coordinates: LiveTransitionCoordinates(
        episodeID: coordinates.episodeID,
        transitionID: "transition-foreign",
        objectID: coordinates.objectID,
        expectedEffectSHA256: coordinates.expectedEffectSHA256
      )
    )
    assertReceiptChainRejected(foreign, policy: policy, coordinates: coordinates)

    var wrongProducer = receipts
    wrongProducer[2] = replacingReceipt(wrongProducer[2], producerID: "producer-model")
    assertReceiptChainRejected(wrongProducer, policy: policy, coordinates: coordinates)

    var brokenPredecessor = receipts
    brokenPredecessor[4] = replacingReceipt(
      brokenPredecessor[4],
      predecessor: LiveGitCandidateReceiptLink(
        receiptID: receipts[3].receiptID,
        receiptSHA256: hash("not-the-predecessor")
      )
    )
    assertReceiptChainRejected(brokenPredecessor, policy: policy, coordinates: coordinates)

    var duplicateEvidence = receipts
    duplicateEvidence[4] = replacingReceipt(
      duplicateEvidence[4],
      evidence: receipts[0].evidence
    )
    assertReceiptChainRejected(duplicateEvidence, policy: policy, coordinates: coordinates)
  }

  func testAllowedAuthorizationRequiresSelectedIntentAndFiveStageEvidenceIsUnique() throws {
    let fixture = try LiveEpisodeFixture.run()
    var state = try stateThroughSelection(fixture)
    let coordinates = try XCTUnwrap(state.transition?.declaration.coordinates)
    let selectedIntentID = try XCTUnwrap(state.model.selection?.sourceIntentID)
    let otherIntentID = try XCTUnwrap(
      state.model.variants
        .compactMap(\.intent?.intent.intentID)
        .first(where: { $0 != selectedIntentID })
    )
    let allowanceID = try XCTUnwrap(state.transition?.declaration.allowanceID)

    state = try apply(
      .transitionUserConfirmed(
        LiveTransitionUserConfirmed(
          coordinates: coordinates,
          evidence: evidence("evidence-confirmation", "confirmation")
        )
      ),
      eventID: "event-confirmation",
      to: state
    )

    XCTAssertThrowsError(
      try apply(
        .authorizationDecided(
          LiveAuthorizationDecided(
            coordinates: coordinates,
            intentID: otherIntentID,
            allowanceID: allowanceID,
            decision: .allowed,
            evidence: evidence("evidence-other-intent", "other-intent")
          )
        ),
        eventID: "event-other-intent-authorization",
        to: state
      )
    ) { error in
      guard case .falseStatusElevation = error as? LiveEpisodeError else {
        return XCTFail("Ожидался falseStatusElevation, получено \(error).")
      }
    }

    XCTAssertThrowsError(
      try apply(
        .authorizationDecided(
          LiveAuthorizationDecided(
            coordinates: coordinates,
            intentID: selectedIntentID,
            allowanceID: allowanceID,
            decision: .allowed,
            evidence: evidence("evidence-confirmation", "duplicate-confirmation")
          )
        ),
        eventID: "event-duplicate-authorization-evidence",
        to: state
      )
    ) { error in
      XCTAssertEqual(
        error as? LiveEpisodeError,
        .duplicateTransitionEvidence(evidenceID: "evidence-confirmation")
      )
    }

    state = try apply(
      .authorizationDecided(
        LiveAuthorizationDecided(
          coordinates: coordinates,
          intentID: selectedIntentID,
          allowanceID: allowanceID,
          decision: .allowed,
          evidence: evidence("evidence-authorization", "authorization")
        )
      ),
      eventID: "event-authorization",
      to: state
    )
    state = try assertDuplicateThenApply(
      duplicateEvidenceID: "evidence-confirmation",
      validEvidence: evidence("evidence-preflight", "preflight"),
      eventID: "event-preflight",
      state: state
    ) { evidence in
      .preflightCompleted(
        LivePreflightCompleted(
          coordinates: coordinates,
          authorizationEvidenceID: "evidence-authorization",
          status: .passed,
          evidence: evidence
        )
      )
    }
    state = try assertDuplicateThenApply(
      duplicateEvidenceID: "evidence-authorization",
      validEvidence: evidence("evidence-execution", "execution"),
      eventID: "event-execution",
      state: state
    ) { evidence in
      .executionRecorded(
        LiveExecutionRecorded(
          coordinates: coordinates,
          preflightEvidenceID: "evidence-preflight",
          status: .succeeded,
          evidence: evidence
        )
      )
    }
    state = try assertDuplicateThenApply(
      duplicateEvidenceID: "evidence-preflight",
      validEvidence: evidence("evidence-observation", "observation"),
      eventID: "event-observation",
      state: state
    ) { evidence in
      .observationRecorded(
        LiveObservationRecorded(
          coordinates: coordinates,
          executionEvidenceID: "evidence-execution",
          status: .observed,
          evidence: evidence
        )
      )
    }
    XCTAssertEqual(state.transition?.phase, .observed)
  }

  func testModelIntentCannotDecodeAsIndependentStageReceipt() throws {
    let intent = LiveUntrustedActionIntent(
      intentID: "intent-model-claim",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated_git_write",
      objectID: "candidate-object",
      expectedEffectSHA256: hash("effect"),
      argumentsSHA256: hash("arguments")
    )
    let modelOutput = try LiveStrictIntentParser.canonicalOutput(for: intent)

    XCTAssertThrowsError(
      try JSONDecoder().decode(
        LiveGitCandidateStageReceipt.self,
        from: Data(modelOutput.utf8)
      )
    )
  }

  private func makePolicy() -> LiveGitCandidateCommitPolicy {
    LiveGitCandidateCommitPolicy(
      allowedPaths: ["Sources/Candidate.swift", "Tests/CandidateTests.swift"],
      checkers: [
        LiveGitCandidateCheckerSpec(
          checkerID: "checker-git-diff",
          argvGrammar: .gitDiffCheckV1
        )
      ],
      baseCommitOID: String(repeating: "1", count: 40),
      expectedTreeOID: String(repeating: "2", count: 40),
      expectedCandidateOID: String(repeating: "3", count: 40),
      candidateBranch: "refs/heads/fum-candidate/episode-test",
      resultRef: "refs/fum/candidates/episode-test",
      author: LiveGitCandidateSignature(
        name: "FUM Candidate",
        email: "candidate@example.invalid",
        timestampSeconds: 1_700_000_000,
        timeZoneOffsetMinutes: 0
      ),
      committer: LiveGitCandidateSignature(
        name: "FUM Candidate",
        email: "candidate@example.invalid",
        timestampSeconds: 1_700_000_000,
        timeZoneOffsetMinutes: 0
      ),
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

  private func replacingPolicy(
    _ policy: LiveGitCandidateCommitPolicy,
    allowedPaths: [String]
  ) -> LiveGitCandidateCommitPolicy {
    LiveGitCandidateCommitPolicy(
      schemaIdentity: policy.schemaIdentity,
      schemaVersion: policy.schemaVersion,
      allowedPaths: allowedPaths,
      checkers: policy.checkers,
      baseCommitOID: policy.baseCommitOID,
      expectedTreeOID: policy.expectedTreeOID,
      expectedCandidateOID: policy.expectedCandidateOID,
      candidateBranch: policy.candidateBranch,
      resultRef: policy.resultRef,
      author: policy.author,
      committer: policy.committer,
      message: policy.message,
      producerIDs: policy.producerIDs
    )
  }

  private func makeCoordinates() -> LiveTransitionCoordinates {
    LiveTransitionCoordinates(
      episodeID: "episode-candidate-contract",
      transitionID: "transition-candidate-contract",
      objectID: "candidate-object",
      expectedEffectSHA256: hash("candidate-effect")
    )
  }

  private func makeReceiptChain(
    policy: LiveGitCandidateCommitPolicy,
    coordinates: LiveTransitionCoordinates
  ) -> [LiveGitCandidateStageReceipt] {
    var receipts: [LiveGitCandidateStageReceipt] = []
    for (index, stage) in LiveGitCandidateStage.allCases.enumerated() {
      let predecessor = receipts.last.map {
        LiveGitCandidateReceiptLink(
          receiptID: $0.receiptID,
          receiptSHA256: try! LiveGitCandidateCanonicalJSON.sha256($0)
        )
      }
      receipts.append(
        LiveGitCandidateStageReceipt(
          receiptID: "receipt-\(index + 1)",
          eventID: "event-stage-receipt-\(index + 1)",
          stage: stage,
          coordinates: coordinates,
          evidence: evidence("evidence-receipt-\(index + 1)", "receipt-\(index + 1)"),
          producerID: policy.producerIDs.producerID(for: stage),
          predecessor: predecessor
        )
      )
    }
    return receipts
  }

  private func replacingReceipt(
    _ receipt: LiveGitCandidateStageReceipt,
    coordinates: LiveTransitionCoordinates? = nil,
    evidence: LiveEvidenceObject? = nil,
    producerID: String? = nil,
    predecessor: LiveGitCandidateReceiptLink?? = nil
  ) -> LiveGitCandidateStageReceipt {
    LiveGitCandidateStageReceipt(
      schemaIdentity: receipt.schemaIdentity,
      schemaVersion: receipt.schemaVersion,
      receiptID: receipt.receiptID,
      eventID: receipt.eventID,
      stage: receipt.stage,
      coordinates: coordinates ?? receipt.coordinates,
      evidence: evidence ?? receipt.evidence,
      producerID: producerID ?? receipt.producerID,
      predecessor: predecessor ?? receipt.predecessor
    )
  }

  private func makeReceiptEvents(
    _ receipts: [LiveGitCandidateStageReceipt]
  ) -> [LiveEpisodeEvent] {
    receipts.enumerated().map { index, receipt in
      let payload: LiveEpisodeEventPayload
      switch receipt.stage {
      case .transitionUserConfirmed:
        payload = .transitionUserConfirmed(
          LiveTransitionUserConfirmed(
            coordinates: receipt.coordinates,
            evidence: receipt.evidence
          )
        )
      case .authorized:
        payload = .authorizationDecided(
          LiveAuthorizationDecided(
            coordinates: receipt.coordinates,
            intentID: "intent-selected",
            allowanceID: "allow-candidate",
            decision: .allowed,
            evidence: receipt.evidence
          )
        )
      case .preflightPassed:
        payload = .preflightCompleted(
          LivePreflightCompleted(
            coordinates: receipt.coordinates,
            authorizationEvidenceID: receipts[index - 1].evidence.evidenceID,
            status: .passed,
            evidence: receipt.evidence
          )
        )
      case .executed:
        payload = .executionRecorded(
          LiveExecutionRecorded(
            coordinates: receipt.coordinates,
            preflightEvidenceID: receipts[index - 1].evidence.evidenceID,
            status: .succeeded,
            evidence: receipt.evidence
          )
        )
      case .observed:
        payload = .observationRecorded(
          LiveObservationRecorded(
            coordinates: receipt.coordinates,
            executionEvidenceID: receipts[index - 1].evidence.evidenceID,
            status: .observed,
            evidence: receipt.evidence
          )
        )
      }
      return LiveEpisodeEvent(
        episodeID: receipt.coordinates.episodeID,
        eventID: receipt.eventID,
        sequence: Int64(index + 1),
        payload: payload
      )
    }
  }

  private func assertReceiptChainRejected(
    _ receipts: [LiveGitCandidateStageReceipt],
    policy: LiveGitCandidateCommitPolicy,
    coordinates: LiveTransitionCoordinates,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: coordinates
      ),
      file: (file),
      line: line
    ) { error in
      XCTAssertTrue(error is LiveGitCandidateContractError, file: (file), line: line)
    }
  }

  private func stateThroughSelection(
    _ fixture: LiveEpisodeFixtureResult
  ) throws -> LiveEpisodeState {
    let selectionIndex = try XCTUnwrap(
      fixture.events.firstIndex(where: { $0.kind == .modelSelectionRecorded })
    )
    return try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: Array(fixture.events.prefix(through: selectionIndex))
    )
  }

  private func apply(
    _ payload: LiveEpisodeEventPayload,
    eventID: String,
    to state: LiveEpisodeState
  ) throws -> LiveEpisodeState {
    try LiveEpisodeReducer.applying(
      LiveEpisodeEvent(
        episodeID: state.passport.episodeID,
        eventID: eventID,
        sequence: state.nextSequence,
        payload: payload
      ),
      to: state
    )
  }

  private func assertDuplicateThenApply(
    duplicateEvidenceID: String,
    validEvidence: LiveEvidenceObject,
    eventID: String,
    state: LiveEpisodeState,
    payload: (LiveEvidenceObject) -> LiveEpisodeEventPayload
  ) throws -> LiveEpisodeState {
    XCTAssertThrowsError(
      try apply(
        payload(evidence(duplicateEvidenceID, "duplicate-\(eventID)")),
        eventID: "\(eventID)-duplicate",
        to: state
      )
    ) { error in
      XCTAssertEqual(
        error as? LiveEpisodeError,
        .duplicateTransitionEvidence(evidenceID: duplicateEvidenceID)
      )
    }
    return try apply(payload(validEvidence), eventID: eventID, to: state)
  }

  private func evidence(_ evidenceID: String, _ body: String) -> LiveEvidenceObject {
    LiveEvidenceObject(evidenceID: evidenceID, evidenceSHA256: hash(body))
  }

  private func hash(_ value: String) -> String {
    LiveStrictIntentParser.sha256(of: value)
  }
}
