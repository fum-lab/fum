import Foundation
import XCTest

@testable import FUMVerifiableMultiAgentContour

final class EpisodePassportContractTests: XCTestCase {
  func testBundledEpisodePassportFixtureInventoryIsStable() {
    XCTAssertEqual(
      EpisodePassportFixtures.identifiers,
      [
        "valid",
        "invalid-assertion-vote",
        "invalid-missing-role",
        "invalid-shared-package",
        "invalid-unsaved-memory",
      ]
    )
  }

  func testValidFixtureProducesStableCanonicalReport() throws {
    let data = try EpisodePassportFixtures.load(named: "valid")

    let first = EpisodePassportPreflight.analyze(data)
    let second = EpisodePassportPreflight.analyze(data)

    XCTAssertEqual(first.decision, .valid)
    XCTAssertEqual(first.episodeID, "fum.episode.symbolic-baseline.v1")
    XCTAssertTrue(first.violations.isEmpty)
    XCTAssertTrue(first.passportSHA256.hasPrefix("sha256:"))
    XCTAssertEqual(first.passportSHA256.count, 71)
    XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())
  }

  func testRequiredNegativeFixturesExposeSpecificViolations() throws {
    let expectations = [
      "invalid-missing-role": "dangling_role_reference",
      "invalid-shared-package": "shared_work_package",
      "invalid-assertion-vote": "assertion_vote_forbidden",
      "invalid-unsaved-memory": "artifact_not_persisted",
    ]

    for (identifier, expectedCode) in expectations {
      let report = EpisodePassportPreflight.analyze(
        try EpisodePassportFixtures.load(named: identifier)
      )

      XCTAssertEqual(report.decision, .invalid, identifier)
      XCTAssertTrue(codes(report).contains(expectedCode), identifier)
    }
  }

  func testDifferentHypothesisSetsDistinguishContributionsWithOneRole() throws {
    let data = try mutateValid { root in
      var workPackages = try XCTUnwrap(root["work_packages"] as? [[String: Any]])
      workPackages[1]["role_id"] = "producer.primary"
      root["work_packages"] = workPackages

      var contributions = try XCTUnwrap(root["contributions"] as? [[String: Any]])
      contributions[1]["role_id"] = "producer.primary"
      root["contributions"] = contributions
    }

    let report = EpisodePassportPreflight.analyze(data)

    XCTAssertEqual(report.decision, .valid)
    XCTAssertTrue(report.violations.isEmpty)
  }

  func testRoleAndHypothesisEqualityMakesContributionsIndistinguishable() throws {
    let data = try mutateValid { root in
      var workPackages = try XCTUnwrap(root["work_packages"] as? [[String: Any]])
      workPackages[1]["role_id"] = "producer.primary"
      workPackages[1]["hypothesis_ids"] = ["hypothesis.primary"]
      root["work_packages"] = workPackages

      var contributions = try XCTUnwrap(root["contributions"] as? [[String: Any]])
      contributions[1]["role_id"] = "producer.primary"
      contributions[1]["hypothesis_ids"] = ["hypothesis.primary"]
      root["contributions"] = contributions
    }

    let report = EpisodePassportPreflight.analyze(data)

    XCTAssertEqual(report.decision, .invalid)
    XCTAssertTrue(codes(report).contains("contributions_indistinguishable"))
  }

  func testIdenticalArtifactHashesDoNotImplyInvalidityOrIndependence() throws {
    let data = try mutateValid { root in
      var artifacts = try XCTUnwrap(root["artifacts"] as? [[String: Any]])
      let sharedHash = "sha256:" + String(repeating: "a", count: 64)
      for index in artifacts.indices {
        artifacts[index]["sha256"] = sharedHash
      }
      root["artifacts"] = artifacts
    }

    let report = EpisodePassportPreflight.analyze(data)

    XCTAssertEqual(report.decision, .valid)
    XCTAssertTrue(report.violations.isEmpty)
    let encoded = try XCTUnwrap(String(data: report.canonicalJSONData(), encoding: .utf8))
    XCTAssertFalse(encoded.contains("independence"))
  }

  func testUnknownDuplicateAndDanglingTypedReferenceFailClosed() throws {
    let unknown = EpisodePassportPreflight.analyze(
      try mutateValid { $0["unexpected"] = true }
    )
    XCTAssertTrue(codes(unknown).contains("unknown_field"))

    let source = try XCTUnwrap(
      String(data: EpisodePassportFixtures.load(named: "valid"), encoding: .utf8)
    )
    let duplicated = source.replacingOccurrences(
      of: "\"episode_id\":",
      with: "\"episode_id\": \"duplicate\", \"episode_id\":"
    )
    let duplicate = EpisodePassportPreflight.analyze(Data(duplicated.utf8))
    XCTAssertTrue(codes(duplicate).contains("duplicate_key"))

    let dangling = EpisodePassportPreflight.analyze(
      try mutateValid { root in
        var goal = try XCTUnwrap(root["goal"] as? [String: Any])
        goal["criteria_artifact_id"] = "criteria.missing"
        root["goal"] = goal
      }
    )
    XCTAssertTrue(codes(dangling).contains("dangling_artifact_reference"))

    let wrongKind = EpisodePassportPreflight.analyze(
      try mutateValid { root in
        var goal = try XCTUnwrap(root["goal"] as? [String: Any])
        goal["criteria_artifact_id"] = "goal.main"
        root["goal"] = goal
      }
    )
    XCTAssertTrue(codes(wrongKind).contains("artifact_kind_mismatch"))
  }

  func testViolationsAreDeduplicatedSortedAndStable() throws {
    let data = try mutateValid { root in
      var policy = try XCTUnwrap(root["evidence_policy"] as? [String: Any])
      policy["agreement_is_evidence"] = true
      policy["independence_inferred_from_count"] = true
      root["evidence_policy"] = policy

      var selection = try XCTUnwrap(root["selection"] as? [String: Any])
      selection["basis"] = "assertion_vote"
      root["selection"] = selection
    }

    let first = EpisodePassportPreflight.analyze(data)
    let second = EpisodePassportPreflight.analyze(data)
    let ordering = first.violations.map { "\($0.code)\u{0}\($0.path)\u{0}\($0.message)" }

    XCTAssertEqual(ordering, ordering.sorted())
    XCTAssertEqual(Set(first.violations).count, first.violations.count)
    XCTAssertEqual(first, second)
    XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())
  }

  private func codes(_ report: EpisodePassportReport) -> Set<String> {
    Set(report.violations.map(\.code))
  }

  private func mutateValid(
    _ mutation: (inout [String: Any]) throws -> Void
  ) throws -> Data {
    let data = try EpisodePassportFixtures.load(named: "valid")
    var root = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    try mutation(&root)
    return try JSONSerialization.data(
      withJSONObject: root,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }
}
