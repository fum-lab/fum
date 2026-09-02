import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveSingleAgentScenarioTests: XCTestCase {
  func testFactoryPinsPlanAndPreparesExactCleanSourceCheckout() throws {
    try withEmptySourceDirectory { sourceURL in
      let scenario = try LiveSingleAgentScenarioFactory.prepare(at: sourceURL)

      XCTAssertEqual(scenario.sourceCheckoutURL, sourceURL.standardizedFileURL)
      XCTAssertEqual(
        try scenario.plan.canonicalSHA256(),
        LiveSingleAgentScenarioFactory.planSHA256
      )
      XCTAssertEqual(
        scenario.plan.policy.baseCommitOID,
        LiveSingleAgentScenarioFactory.baseCommitOID
      )
      XCTAssertEqual(
        scenario.plan.policy.expectedTreeOID,
        LiveSingleAgentScenarioFactory.candidateTreeOID
      )
      XCTAssertEqual(
        scenario.plan.policy.expectedCandidateOID,
        LiveSingleAgentScenarioFactory.candidateCommitOID
      )
      XCTAssertEqual(
        scenario.coordinates,
        LiveTransitionCoordinates(
          episodeID: "episode-single-agent-v1",
          transitionID: "transition-candidate",
          objectID: "candidate-artifact",
          expectedEffectSHA256: LiveSingleAgentScenarioFactory.planSHA256
        )
      )
      XCTAssertEqual(scenario.actionAllowlist, [scenario.allowance])
      XCTAssertEqual(scenario.allowance.allowanceID, "allow-git-candidate")
      XCTAssertEqual(scenario.allowance.operation, LiveGitCandidateContract.operation)
      XCTAssertEqual(scenario.allowance.adapterID, "fum-git-candidate-v1")
      XCTAssertEqual(scenario.allowance.effectClass, "isolated-git-write")
      XCTAssertEqual(scenario.allowance.candidateCommitPolicy, scenario.plan.policy)

      let runner = LiveGitProcessRunner()
      XCTAssertEqual(
        try gitLine(runner.run(["rev-parse", "HEAD"], at: sourceURL).output),
        LiveSingleAgentScenarioFactory.baseCommitOID
      )
      XCTAssertEqual(
        try gitLine(runner.run(["rev-parse", "HEAD^{tree}"], at: sourceURL).output),
        LiveSingleAgentScenarioFactory.baseTreeOID
      )
      XCTAssertEqual(
        try gitLine(runner.run(["rev-parse", "HEAD:artifact.txt"], at: sourceURL).output),
        LiveSingleAgentScenarioFactory.baseBlobOID
      )
      XCTAssertEqual(
        try gitLine(runner.run(["symbolic-ref", "HEAD"], at: sourceURL).output),
        "refs/heads/master"
      )
      XCTAssertEqual(
        try Data(
          contentsOf: sourceURL.appendingPathComponent(
            LiveSingleAgentScenarioFactory.artifactPath
          )
        ),
        LiveSingleAgentScenarioFactory.baseContents
      )
      XCTAssertTrue(
        try runner.run(
          ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
          at: sourceURL
        ).output.isEmpty
      )
      XCTAssertEqual(
        try runner.run(
          [
            "show-ref", "--verify", "--quiet",
            LiveSingleAgentScenarioFactory.candidateBranch,
          ],
          at: sourceURL,
          acceptedStatuses: [0, 1]
        ).status,
        1
      )
      XCTAssertEqual(
        try runner.run(
          ["show-ref", "--verify", "--quiet", LiveSingleAgentScenarioFactory.resultRef],
          at: sourceURL,
          acceptedStatuses: [0, 1]
        ).status,
        1
      )
      XCTAssertNotEqual(
        try runner.run(
          [
            "cat-file", "-e",
            "\(LiveSingleAgentScenarioFactory.candidateCommitOID)^{commit}",
          ],
          at: sourceURL,
          acceptedStatuses: [0, 1, 128]
        ).status,
        0
      )

      let episodeURL = sourceURL.deletingLastPathComponent().appendingPathComponent(
        "episode",
        isDirectory: true
      )
      try FileManager.default.createDirectory(at: episodeURL, withIntermediateDirectories: false)
      let candidate = try IsolatedGitCandidateAdapter().createValidatedCandidate(
        sourceCheckoutURL: sourceURL,
        episodeDirectoryURL: episodeURL,
        coordinates: scenario.coordinates,
        plan: scenario.plan
      )
      XCTAssertEqual(
        candidate.candidateOID,
        LiveSingleAgentScenarioFactory.candidateCommitOID
      )
      let cloneURL = episodeURL.appendingPathComponent(
        LiveGitCandidateRuntimeSchema.cloneRelativePath,
        isDirectory: true
      )
      for ref in [
        LiveSingleAgentScenarioFactory.candidateBranch,
        LiveSingleAgentScenarioFactory.resultRef,
      ] {
        XCTAssertEqual(
          try gitLine(runner.run(["rev-parse", "--verify", ref], at: cloneURL).output),
          LiveSingleAgentScenarioFactory.candidateCommitOID
        )
      }
      XCTAssertEqual(
        try gitLine(
          runner.run(
            ["rev-parse", "\(LiveSingleAgentScenarioFactory.candidateCommitOID)^{tree}"],
            at: cloneURL
          ).output
        ),
        LiveSingleAgentScenarioFactory.candidateTreeOID
      )
      XCTAssertEqual(
        try gitLine(
          runner.run(
            ["rev-parse", "\(LiveSingleAgentScenarioFactory.candidateCommitOID):artifact.txt"],
            at: cloneURL
          ).output
        ),
        LiveSingleAgentScenarioFactory.candidateBlobOID
      )
      XCTAssertEqual(
        try gitLine(runner.run(["rev-parse", "HEAD"], at: sourceURL).output),
        LiveSingleAgentScenarioFactory.baseCommitOID
      )
      XCTAssertTrue(
        try runner.run(
          ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
          at: sourceURL
        ).output.isEmpty
      )
      XCTAssertEqual(
        try Data(contentsOf: sourceURL.appendingPathComponent("artifact.txt")),
        Data("before\n".utf8)
      )
    }
  }

  func testPlanFactoryPinsExactCandidateObjectIDsAndCanonicalIdentifiers() throws {
    let plan = try LiveSingleAgentScenarioFactory.makePlan()

    XCTAssertEqual(
      plan.writes,
      [
        LiveGitRegularFileWrite(
          path: "artifact.txt",
          mode: .regular,
          contents: Data("accepted\n".utf8)
        )
      ]
    )
    XCTAssertEqual(plan.policy.checkers.count, 1)
    XCTAssertEqual(plan.policy.checkers[0].checkerID, "git-diff-check")
    XCTAssertEqual(plan.policy.checkers[0].argvGrammar, .gitDiffCheckV1)
    XCTAssertEqual(plan.preflightEventID, "event-candidate-preflight")
    XCTAssertEqual(plan.preflightReceiptID, "receipt-candidate-preflight")
    XCTAssertEqual(plan.executionEventID, "event-candidate-execution")
    XCTAssertEqual(plan.executionReceiptID, "receipt-candidate-execution")
    XCTAssertEqual(plan.observationEventID, "event-candidate-observation")
    XCTAssertEqual(plan.observationReceiptID, "receipt-candidate-observation")
    XCTAssertEqual(
      plan.policy.producerIDs.transitionUserConfirmed,
      "single-agent-runtime.confirmation.v1"
    )
    XCTAssertEqual(
      plan.policy.producerIDs.authorized,
      "single-agent-runtime.authorization.v1"
    )
    XCTAssertEqual(
      plan.policy.producerIDs.preflightPassed,
      "git-candidate-adapter.preflight.v1"
    )
    XCTAssertEqual(plan.policy.producerIDs.executed, "git-candidate-adapter.execution.v1")
    XCTAssertEqual(plan.policy.producerIDs.observed, "git-candidate-adapter.observation.v1")
    XCTAssertEqual(
      try plan.canonicalSHA256(),
      "sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808"
    )
  }

  func testFactoryRejectsNonemptyDirectoryWithoutTouchingContents() throws {
    try withEmptySourceDirectory { sourceURL in
      let sentinelURL = sourceURL.appendingPathComponent("sentinel.txt")
      let sentinel = Data("do not touch\n".utf8)
      try sentinel.write(to: sentinelURL)

      XCTAssertThrowsError(try LiveSingleAgentScenarioFactory.prepare(at: sourceURL)) {
        XCTAssertEqual(
          $0 as? LiveSingleAgentScenarioError,
          .sourceDirectoryIsNotEmpty
        )
      }
      XCTAssertEqual(try Data(contentsOf: sentinelURL), sentinel)
      XCTAssertEqual(
        try FileManager.default.contentsOfDirectory(atPath: sourceURL.path).sorted(),
        ["sentinel.txt"]
      )
    }
  }

  private func withEmptySourceDirectory(
    _ body: (URL) throws -> Void
  ) throws {
    let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-single-agent-scenario-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    let sourceURL = rootURL.appendingPathComponent("source", isDirectory: true)
    try FileManager.default.createDirectory(at: sourceURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    try body(sourceURL)
  }

  private func gitLine(_ data: Data) throws -> String {
    try XCTUnwrap(String(data: data, encoding: .utf8))
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
