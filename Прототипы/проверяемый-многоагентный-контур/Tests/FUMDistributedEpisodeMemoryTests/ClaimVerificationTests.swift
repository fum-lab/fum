import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class ClaimVerificationTests: XCTestCase {
  func testIndependentVerificationPassesDeclaredClaimsWithExternalEvidence() throws {
    let episode = try verifiedEpisode(record: .externalPassed)
    let assessment = try XCTUnwrap(
      episode.state.verificationReport.assessmentsByRecordID[
        "verification.record.external-passed"
      ]
    )

    XCTAssertEqual(assessment.outcome, .passed)
    XCTAssertEqual(assessment.standing, .externalByObservedFeatures)
    XCTAssertEqual(assessment.externalWeight, 1)
    XCTAssertEqual(episode.state.verificationReport.externalPassedCount, 1)
    XCTAssertFalse(episode.state.verificationReport.semanticTruthProven)
    XCTAssertFalse(episode.state.verificationReport.absoluteVerifierIndependenceProven)
    XCTAssertFalse(episode.state.verificationReport.agreementIsEvidence)
  }

  func testSelfAndCorrelatedVerificationRemainStoredWithoutExternalWeight() throws {
    for fixture in [
      SharedEpisodeVerificationFixture.selfPassed,
      SharedEpisodeVerificationFixture.correlatedPassed,
    ] {
      let episode = try verifiedEpisode(record: fixture)
      let recordID = try XCTUnwrap(episode.state.verifications.last?.recordID)
      let assessment = try XCTUnwrap(
        episode.state.verificationReport.assessmentsByRecordID[recordID]
      )

      XCTAssertEqual(assessment.outcome, .passed)
      XCTAssertEqual(
        assessment.standing,
        fixture == .selfPassed ? .selfVerification : .correlatedVerification
      )
      XCTAssertEqual(assessment.externalWeight, 0)
      XCTAssertEqual(episode.state.verificationReport.externalPassedCount, 0)
      XCTAssertEqual(episode.state.verifications.count, 1)
    }
  }

  func testCorrelationThroughStoredSelfVerificationCannotLaunderExternalWeight() throws {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    let selfVerification = try SharedEpisodeMemoryFixtures.verification(
      named: .selfPassed,
      parentGenerationSHA256: verificationSHA(
        try withContributions.canonicalJSONData()
      )
    )
    let withSelfVerification = try SharedEpisodeMemoryReducer.continuation(
      from: withContributions,
      verification: selfVerification
    )
    let correlatedThroughSelf = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: verificationSHA(
        try withSelfVerification.canonicalJSONData()
      )
    )
    let accepted = try SharedEpisodeMemoryReducer.continuation(
      from: withSelfVerification,
      verification: correlatedThroughSelf
    )

    XCTAssertEqual(
      accepted.state.verificationReport.assessmentsByRecordID[
        correlatedThroughSelf.recordID
      ]?.standing,
      .correlatedVerification
    )
    XCTAssertEqual(accepted.state.verificationReport.externalPassedCount, 0)
  }

  func testEqualUnverifiedAnswersCannotBecomePassedConsensus() throws {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    XCTAssertEqual(Set(withContributions.state.contributions.map(\.contentSHA256)).count, 1)

    let parentSHA256 = verificationSHA(try withContributions.canonicalJSONData())
    let base = try SharedEpisodeMemoryFixtures.verification(
      named: .inconclusive,
      parentGenerationSHA256: parentSHA256
    )
    let claims = withContributions.state.contributions.map {
      SharedEpisodeVerificationClaim(
        claimID:
          $0.contributionID == "contribution.primary"
          ? "claim.primary" : "claim.adversarial",
        contributionID: $0.contributionID,
        resultSHA256: $0.contentSHA256
      )
    }.sorted { $0.claimID < $1.claimID }
    let falselyPassedContent = SharedEpisodeVerificationContent(
      verificationPlanArtifactID: base.content.verificationPlanArtifactID,
      criterionIDs: base.content.criterionIDs,
      claims: claims,
      evidence: [],
      outcome: .passed,
      disagreements: []
    )
    let falselyPassedSHA256 = verificationSHA(
      try falselyPassedContent.canonicalJSONData()
    )
    let falselyPassed = SharedEpisodeVerificationRecord(
      recordID: "verification.record.false-consensus-pass",
      parentGenerationSHA256: parentSHA256,
      verifier: base.verifier,
      contentSHA256: falselyPassedSHA256,
      content: falselyPassedContent,
      provenance: base.provenance.rebinding(
        recordID: "verification.record.false-consensus-pass",
        resultSHA256: falselyPassedSHA256
      )
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: withContributions,
        verification: falselyPassed
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidVerification(let message) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(message.contains("достаточ"), message)
    }

    let inconclusiveContent = SharedEpisodeVerificationContent(
      verificationPlanArtifactID: base.content.verificationPlanArtifactID,
      criterionIDs: base.content.criterionIDs,
      claims: claims,
      evidence: [],
      outcome: .inconclusive,
      disagreements: []
    )
    let inconclusiveSHA256 = verificationSHA(
      try inconclusiveContent.canonicalJSONData()
    )
    let inconclusive = SharedEpisodeVerificationRecord(
      recordID: "verification.record.false-consensus-inconclusive",
      parentGenerationSHA256: parentSHA256,
      verifier: base.verifier,
      contentSHA256: inconclusiveSHA256,
      content: inconclusiveContent,
      provenance: base.provenance.rebinding(
        recordID: "verification.record.false-consensus-inconclusive",
        resultSHA256: inconclusiveSHA256
      )
    )
    let accepted = try SharedEpisodeMemoryReducer.continuation(
      from: withContributions,
      verification: inconclusive
    )
    XCTAssertEqual(accepted.state.verificationReport.assessments.first?.outcome, .inconclusive)
    XCTAssertEqual(accepted.state.verificationReport.externalPassedCount, 0)
    XCTAssertFalse(accepted.state.verificationReport.agreementIsEvidence)
  }

  func testInsufficientEvidenceIsInconclusiveAndCannotBeDeclaredPassed() throws {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    let parentSHA256 = verificationSHA(try withContributions.canonicalJSONData())
    let inconclusive = try SharedEpisodeMemoryFixtures.verification(
      named: .inconclusive,
      parentGenerationSHA256: parentSHA256
    )
    let accepted = try SharedEpisodeMemoryReducer.continuation(
      from: withContributions,
      verification: inconclusive
    )

    XCTAssertEqual(
      accepted.state.verificationReport.assessments.first?.outcome,
      .inconclusive
    )
    XCTAssertEqual(accepted.state.verificationReport.externalPassedCount, 0)

    let falselyPassed = SharedEpisodeVerificationRecord(
      recordID: "verification.record.false-pass",
      parentGenerationSHA256: parentSHA256,
      verifier: inconclusive.verifier,
      contentSHA256: verificationSHA(
        try SharedEpisodeVerificationContent(
          verificationPlanArtifactID: inconclusive.content.verificationPlanArtifactID,
          criterionIDs: inconclusive.content.criterionIDs,
          claims: inconclusive.content.claims,
          evidence: inconclusive.content.evidence,
          outcome: .passed,
          disagreements: inconclusive.content.disagreements
        ).canonicalJSONData()
      ),
      content: SharedEpisodeVerificationContent(
        verificationPlanArtifactID: inconclusive.content.verificationPlanArtifactID,
        criterionIDs: inconclusive.content.criterionIDs,
        claims: inconclusive.content.claims,
        evidence: inconclusive.content.evidence,
        outcome: .passed,
        disagreements: inconclusive.content.disagreements
      ),
      provenance: inconclusive.provenance.rebinding(
        recordID: "verification.record.false-pass",
        resultSHA256: verificationSHA(
          try SharedEpisodeVerificationContent(
            verificationPlanArtifactID: inconclusive.content.verificationPlanArtifactID,
            criterionIDs: inconclusive.content.criterionIDs,
            claims: inconclusive.content.claims,
            evidence: inconclusive.content.evidence,
            outcome: .passed,
            disagreements: inconclusive.content.disagreements
          ).canonicalJSONData()
        )
      )
    )

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: withContributions,
        verification: falselyPassed
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidVerification(let message) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(message.contains("достаточ"), message)
    }
  }

  func testVerifierIdentityAndRoleAreBoundToPassportPlan() throws {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    let parentSHA256 = verificationSHA(try withContributions.canonicalJSONData())
    let valid = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: parentSHA256
    )
    let detached = SharedEpisodeVerificationRecord(
      recordID: valid.recordID,
      parentGenerationSHA256: valid.parentGenerationSHA256,
      verifier: SharedEpisodeContributor(
        kind: .author,
        identifier: valid.verifier.identifier
      ),
      contentSHA256: valid.contentSHA256,
      content: valid.content,
      provenance: valid.provenance.rebinding(roleID: "producer.primary")
    )

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: withContributions,
        verification: detached
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidVerification(let message) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertTrue(message.contains("паспорт"), message)
    }
  }

  func testVerifierCannotOmitCorrelationLinksForDeclaredInputs() throws {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    let parentSHA256 = verificationSHA(try withContributions.canonicalJSONData())
    let valid = try SharedEpisodeMemoryFixtures.verification(
      named: .externalPassed,
      parentGenerationSHA256: parentSHA256
    )
    let provenance = valid.provenance
    let detached = SharedEpisodeVerificationRecord(
      recordID: valid.recordID,
      parentGenerationSHA256: valid.parentGenerationSHA256,
      verifier: valid.verifier,
      contentSHA256: valid.contentSHA256,
      content: valid.content,
      provenance: SharedEpisodeVerificationProvenance(
        recordID: provenance.recordID,
        executorID: provenance.executorID,
        roleID: provenance.roleID,
        verificationPlanArtifactID: provenance.verificationPlanArtifactID,
        modelID: provenance.modelID,
        providerID: provenance.providerID,
        taskSHA256: provenance.taskSHA256,
        localInputSHA256s: provenance.localInputSHA256s,
        parentGenerationSHA256: provenance.parentGenerationSHA256,
        resultSHA256: provenance.resultSHA256,
        correlationLinks: []
      )
    )

    XCTAssertThrowsError(
      try SharedEpisodeVerificationValidator.analyze(
        contributions: withContributions.state.contributions,
        verifications: [detached]
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidVerification = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }

    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.continuation(
        from: withContributions,
        verification: detached
      )
    ) { error in
      guard case SharedEpisodeMemoryError.invalidVerification = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testConflictingDisagreementsSurviveLaterGenerationAndRecovery() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-verification-\(UUID().uuidString)",
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: root) }

    let store = SharedEpisodeMemoryStore(rootURL: root)
    var stored = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    for fixture in [
      SharedEpisodeContributionFixture.primary,
      SharedEpisodeContributionFixture.adversarial,
    ] {
      let contribution = try SharedEpisodeMemoryFixtures.contribution(
        named: fixture,
        parentGenerationSHA256: stored.generationSHA256
      )
      stored = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: stored.generation,
          contribution: contribution
        )
      )
    }
    var failedVerification: SharedEpisodeVerificationRecord?
    for fixture in [
      SharedEpisodeVerificationFixture.failed,
      SharedEpisodeVerificationFixture.externalPassed,
    ] {
      let verification = try SharedEpisodeMemoryFixtures.verification(
        named: fixture,
        parentGenerationSHA256: stored.generationSHA256
      )
      if fixture == .failed { failedVerification = verification }
      stored = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: stored.generation,
          verification: verification
        )
      )
    }

    let recovered = try XCTUnwrap(SharedEpisodeMemoryStore(rootURL: root).loadCurrent())
    let decoded = try SharedEpisodeGeneration.decodeCanonical(
      recovered.generation.canonicalJSONData()
    )
    let replayed = try SharedEpisodeMemoryReducer.replay(
      seed: decoded.seed,
      journal: decoded.eventJournal
    )

    XCTAssertEqual(recovered, stored)
    XCTAssertEqual(
      decoded.state.verifications.map(\.recordID),
      [
        "verification.record.failed",
        "verification.record.external-passed",
      ])
    XCTAssertEqual(replayed, decoded.state)
    XCTAssertEqual(
      replayed.verificationReport.assessments.map(\.outcome),
      [.passed, .failed]
    )
    XCTAssertEqual(
      replayed.verificationReport.disagreements,
      try XCTUnwrap(failedVerification).content.disagreements
    )
  }

  private func verifiedEpisode(
    record fixture: SharedEpisodeVerificationFixture
  ) throws -> SharedEpisodeGeneration {
    let foundation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    let withContributions = try appendFixtureContributions(to: foundation)
    let verification = try SharedEpisodeMemoryFixtures.verification(
      named: fixture,
      parentGenerationSHA256: verificationSHA(
        try withContributions.canonicalJSONData()
      )
    )
    return try SharedEpisodeMemoryReducer.continuation(
      from: withContributions,
      verification: verification
    )
  }

  private func appendFixtureContributions(
    to foundation: SharedEpisodeGeneration
  ) throws -> SharedEpisodeGeneration {
    var generation = foundation
    for fixture in [
      SharedEpisodeContributionFixture.primary,
      SharedEpisodeContributionFixture.adversarial,
    ] {
      let parentSHA256 = verificationSHA(try generation.canonicalJSONData())
      generation = try SharedEpisodeMemoryReducer.continuation(
        from: generation,
        contribution: SharedEpisodeMemoryFixtures.contribution(
          named: fixture,
          parentGenerationSHA256: parentSHA256
        )
      )
    }
    return generation
  }
}

private func verificationSHA(_ value: String) -> String {
  verificationSHA(Data(value.utf8))
}

private func verificationSHA(_ data: Data) -> String {
  SharedEpisodeEmbeddedArtifact(
    artifactID: "hash.verification-test",
    kind: "hash",
    logicalPath: "hash.verification-test",
    mediaType: "application/octet-stream",
    data: data
  ).contentSHA256
}
