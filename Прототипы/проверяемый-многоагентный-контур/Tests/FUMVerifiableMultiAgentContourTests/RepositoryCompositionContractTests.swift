import Foundation
import XCTest

@testable import FUMVerifiableMultiAgentContour

final class RepositoryCompositionContractTests: XCTestCase {
  func testBundledSchemaIsVersionedClosedAndDistinguishesEveryChildKind() throws {
    let data = try RepositoryCompositionSchema.load()
    let root = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let properties = try XCTUnwrap(root["properties"] as? [String: Any])
    let schemaVersion = try XCTUnwrap(properties["schema_version"] as? [String: Any])
    let children = try XCTUnwrap(properties["children"] as? [String: Any])
    let items = try XCTUnwrap(children["items"] as? [String: Any])
    let variants = try XCTUnwrap(items["oneOf"] as? [[String: Any]])

    XCTAssertEqual(root["$schema"] as? String, "https://json-schema.org/draft/2020-12/schema")
    XCTAssertEqual(root["additionalProperties"] as? Bool, false)
    XCTAssertEqual(schemaVersion["const"] as? Int, 1)
    XCTAssertEqual(variants.count, 3)
    XCTAssertTrue(variants.allSatisfy { $0["additionalProperties"] as? Bool == false })
    let requiredByKind = try Dictionary(
      uniqueKeysWithValues: variants.map { variant in
        let properties = try XCTUnwrap(variant["properties"] as? [String: Any])
        let kind = try XCTUnwrap(properties["kind"] as? [String: Any])
        return (
          try XCTUnwrap(kind["const"] as? String),
          Set(try XCTUnwrap(variant["required"] as? [String]))
        )
      }
    )
    XCTAssertFalse(try XCTUnwrap(requiredByKind["step_branch"]).contains("gitlink_oid"))
    XCTAssertTrue(try XCTUnwrap(requiredByKind["specialized_subnode"]).contains("base_oid"))
    XCTAssertTrue(try XCTUnwrap(requiredByKind["project"]).contains("base_oid"))
  }

  func testNamedFixtureInventoryIsStable() {
    XCTAssertEqual(
      RepositoryCompositionFixtures.identifiers,
      [
        "valid",
        "invalid-access",
        "invalid-ancestor-submodule",
        "invalid-duplicate-identity",
        "invalid-duplicate-path",
        "invalid-missing-revision",
        "invalid-repository-cycle",
        "invalid-self-recursion",
      ]
    )
  }

  func testValidFixtureProvesAllKindsAndSeparatesSnapshotsFromWriters() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let first = RepositoryCompositionPreflight.analyze(
        fixture.passportData,
        context: fixture.context
      )
      let second = RepositoryCompositionPreflight.analyze(
        fixture.passportData,
        context: fixture.context
      )

      XCTAssertEqual(first.decision, .valid)
      XCTAssertEqual(first.compositionID, "fum.repository-composition.fixture.v1")
      XCTAssertTrue(first.violations.isEmpty)
      XCTAssertTrue(first.passportSHA256.hasPrefix("sha256:"))
      XCTAssertEqual(first.passportSHA256.count, 71)
      XCTAssertEqual(first, second)
      XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())

      let root = try passportObject(fixture.passportData)
      let children = try childObjects(root)
      XCTAssertEqual(
        Set(children.compactMap { $0["kind"] as? String }),
        Set(["step_branch", "specialized_subnode", "project"])
      )

      let step = try child(kind: "step_branch", in: children)
      XCTAssertNil(step["submodule_path"])
      XCTAssertNil(step["gitlink_oid"])
      XCTAssertNil(step["upstream_repository_id"])
      XCTAssertNil(step["snapshot_mode"])

      let specialized = try child(kind: "specialized_subnode", in: children)
      XCTAssertNotNil(specialized["upstream_repository_id"])
      XCTAssertEqual(specialized["snapshot_mode"] as? String, "detached_read_only")
      XCTAssertEqual(specialized["writer_mode"] as? String, "separate_clone")

      let project = try child(kind: "project", in: children)
      XCTAssertNil(project["upstream_repository_id"])
      XCTAssertEqual(project["snapshot_mode"] as? String, "detached_read_only")
      XCTAssertEqual(project["writer_mode"] as? String, "separate_clone")

      XCTAssertEqual(
        Set(first.childVerifications.map { $0.kind.rawValue }),
        Set(["step_branch", "specialized_subnode", "project"])
      )

      for kind in ["specialized_subnode", "project"] {
        let verification = try XCTUnwrap(
          first.childVerifications.first { $0.kind.rawValue == kind },
          "Missing verification for \(kind)"
        )
        XCTAssertNotNil(verification.gitlinkOID)
        XCTAssertNotNil(verification.liveRefOID)
        XCTAssertNotEqual(verification.gitlinkOID, verification.liveRefOID)
        XCTAssertEqual(verification.snapshotHEADOID, verification.gitlinkOID)
        XCTAssertEqual(verification.snapshotIsDetached, true)
        XCTAssertEqual(verification.snapshotIsClean, true)
        XCTAssertEqual(verification.writerSymbolicRef, verification.liveRef)
        XCTAssertEqual(verification.writerIsSeparate, true)
      }
    }
  }

  func testIndependentFixtureBuildsHaveStablePassportWithoutRuntimePaths() throws {
    var firstPassport: Data?
    var firstReport: Data?
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      firstPassport = fixture.passportData
      firstReport = try RepositoryCompositionPreflight.analyze(
        fixture.passportData,
        context: fixture.context
      ).canonicalJSONData()
    }
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let passportText = try XCTUnwrap(String(data: fixture.passportData, encoding: .utf8))
      XCTAssertEqual(fixture.passportData, firstPassport)
      XCTAssertEqual(
        try RepositoryCompositionPreflight.analyze(
          fixture.passportData,
          context: fixture.context
        ).canonicalJSONData(),
        firstReport
      )
      XCTAssertFalse(passportText.contains("file:"))
      XCTAssertFalse(passportText.contains(FileManager.default.temporaryDirectory.path))
      XCTAssertTrue(passportText.contains("urn:fum:repository:"))
    }
  }

  func testKindSpecificFieldsAreRequiredAndForbidden() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let forbiddenOnStep = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "step_branch", in: &root) { child in
          child["submodule_path"] = "Подузлы/ошибка"
        }
      }
      assertViolation(
        "field_not_allowed",
        in: RepositoryCompositionPreflight.analyze(
          forbiddenOnStep,
          context: fixture.context
        )
      )

      for requiredField in [
        "submodule_path", "gitlink_oid", "upstream_repository_id", "snapshot_mode",
        "writer_mode",
      ] {
        let missing = try mutatePassport(fixture.passportData) { root in
          try mutateChild(kind: "specialized_subnode", in: &root) { child in
            child.removeValue(forKey: requiredField)
          }
        }
        let report = RepositoryCompositionPreflight.analyze(
          missing,
          context: fixture.context
        )
        assertViolation("missing_field", pathSuffix: "\(requiredField)", in: report)
      }

      let forbiddenOnProject = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "project", in: &root) { child in
          child["upstream_repository_id"] = "repository.core"
        }
      }
      assertViolation(
        "field_not_allowed",
        pathSuffix: "upstream_repository_id",
        in: RepositoryCompositionPreflight.analyze(
          forbiddenOnProject,
          context: fixture.context
        )
      )
    }
  }

  func testRefsCannotMasqueradeAsObjectIDsAndLiveRefMustBeFull() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let branchAsBase = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "step_branch", in: &root) { child in
          child["base_oid"] = "refs/heads/main"
        }
      }
      assertViolation(
        "invalid_oid",
        pathSuffix: "base_oid",
        in: RepositoryCompositionPreflight.analyze(
          branchAsBase,
          context: fixture.context
        )
      )

      let branchAsGitlink = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "specialized_subnode", in: &root) { child in
          child["gitlink_oid"] = "refs/heads/specialized/main"
        }
      }
      assertViolation(
        "invalid_oid",
        pathSuffix: "gitlink_oid",
        in: RepositoryCompositionPreflight.analyze(
          branchAsGitlink,
          context: fixture.context
        )
      )

      let shortLiveRef = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "project", in: &root) { child in
          child["live_ref"] = "main"
        }
      }
      assertViolation(
        "invalid_ref",
        pathSuffix: "live_ref",
        in: RepositoryCompositionPreflight.analyze(
          shortLiveRef,
          context: fixture.context
        )
      )
    }
  }

  func testDuplicateJSONKeyFailsBeforeGitVerification() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let passport = try XCTUnwrap(String(data: fixture.passportData, encoding: .utf8))
      let duplicate = passport.replacingOccurrences(
        of: "\"schema_version\":1",
        with: "\"schema_version\":1,\"schema_version\":1"
      )
      XCTAssertNotEqual(duplicate, passport)
      assertViolation(
        "duplicate_key",
        pathSuffix: "schema_version",
        in: RepositoryCompositionPreflight.analyze(Data(duplicate.utf8), context: fixture.context)
      )
    }
  }

  func testCycleAndRecursiveTopologyFixturesFailClosed() throws {
    let expectations = [
      "invalid-ancestor-submodule": "submodule_references_ancestor",
      "invalid-repository-cycle": "repository_cycle",
      "invalid-self-recursion": "recursive_initialization_forbidden",
    ]

    for (identifier, expectedCode) in expectations {
      try RepositoryCompositionFixtures.withFixture(named: identifier) { fixture in
        let report = RepositoryCompositionPreflight.analyze(
          fixture.passportData,
          context: fixture.context
        )

        XCTAssertEqual(report.decision, .invalid, identifier)
        XCTAssertTrue(codes(report).contains(expectedCode), identifier)
      }
    }
  }

  func testObservedGitTopologyFailsEvenWhenPassportHidesNestedEdges() throws {
    let expectations = [
      "invalid-ancestor-submodule": "submodule_references_ancestor",
      "invalid-repository-cycle": "repository_cycle",
      "invalid-self-recursion": "recursive_initialization_forbidden",
    ]

    for (identifier, expectedCode) in expectations {
      try RepositoryCompositionFixtures.withFixture(named: identifier) { fixture in
        let concealed = try mutatePassport(fixture.passportData) { root in
          var children = try childObjects(root)
          for index in children.indices where children[index]["kind"] as? String != "step_branch" {
            children[index]["nested_submodules"] = []
          }
          root["children"] = children
        }
        assertViolation(
          expectedCode,
          in: RepositoryCompositionPreflight.analyze(concealed, context: fixture.context)
        )
      }
    }
  }

  func testDuplicateRepositoryIdentityAndSubmodulePathFailClosed() throws {
    let expectations = [
      "invalid-duplicate-identity": "duplicate_repository_identity",
      "invalid-duplicate-path": "duplicate_submodule_path",
    ]

    for (identifier, expectedCode) in expectations {
      try RepositoryCompositionFixtures.withFixture(named: identifier) { fixture in
        let report = RepositoryCompositionPreflight.analyze(
          fixture.passportData,
          context: fixture.context
        )

        XCTAssertEqual(report.decision, .invalid, identifier)
        XCTAssertTrue(codes(report).contains(expectedCode), identifier)
      }
    }
  }

  func testAccessAndMissingRevisionFixturesFailClosed() throws {
    let expectations = [
      "invalid-access": "incompatible_access",
      "invalid-missing-revision": "revision_missing",
    ]

    for (identifier, expectedCode) in expectations {
      try RepositoryCompositionFixtures.withFixture(named: identifier) { fixture in
        let report = RepositoryCompositionPreflight.analyze(
          fixture.passportData,
          context: fixture.context
        )

        XCTAssertEqual(report.decision, .invalid, identifier)
        XCTAssertTrue(codes(report).contains(expectedCode), identifier)
      }
    }
  }

  func testParentPublicationBoundaryAndGitlinkAncestryAreEnforced() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let privateChild = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "specialized_subnode", in: &root) { child in
          child["access_level"] = "private"
          child["publication_boundary"] = "private"
        }
      }
      assertViolation(
        "incompatible_access",
        in: RepositoryCompositionPreflight.analyze(privateChild, context: fixture.context)
      )

      let validReport = RepositoryCompositionPreflight.analyze(
        fixture.passportData,
        context: fixture.context
      )
      let projectTip = try XCTUnwrap(
        validReport.childVerifications.first { $0.kind == .project }?.liveRefOID
      )
      let reversedHistory = try mutatePassport(fixture.passportData) { root in
        try mutateChild(kind: "project", in: &root) { child in
          child["base_oid"] = projectTip
        }
      }
      assertViolation(
        "base_not_gitlink_ancestor",
        in: RepositoryCompositionPreflight.analyze(reversedHistory, context: fixture.context)
      )
    }
  }

  func testViolationsAndCanonicalReportAreDeduplicatedSortedAndStable() throws {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { fixture in
      let invalid = try mutatePassport(fixture.passportData) { root in
        root["unexpected"] = true
        var children = try childObjects(root)
        let projectIndex = try childIndex(kind: "project", in: children)
        let specializedIndex = try childIndex(kind: "specialized_subnode", in: children)
        children[projectIndex]["submodule_path"] = children[specializedIndex]["submodule_path"]
        children[projectIndex]["base_oid"] = "refs/heads/not-an-oid"
        root["children"] = children
      }

      let first = RepositoryCompositionPreflight.analyze(
        invalid,
        context: fixture.context
      )
      let second = RepositoryCompositionPreflight.analyze(
        invalid,
        context: fixture.context
      )
      let ordering = first.violations.map {
        "\($0.code)\u{0}\($0.path)\u{0}\($0.message)"
      }

      XCTAssertEqual(first.decision, .invalid)
      XCTAssertGreaterThanOrEqual(first.violations.count, 3)
      XCTAssertEqual(ordering, ordering.sorted())
      XCTAssertEqual(Set(first.violations).count, first.violations.count)
      XCTAssertEqual(first, second)
      XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())
    }
  }

  private func codes(_ report: RepositoryCompositionReport) -> Set<String> {
    Set(report.violations.map(\.code))
  }

  private func assertViolation(
    _ code: String,
    pathSuffix: String? = nil,
    in report: RepositoryCompositionReport,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    XCTAssertEqual(report.decision, .invalid, file: (file), line: line)
    XCTAssertTrue(
      report.violations.contains { violation in
        let pathMatches =
          pathSuffix.map {
            violation.path.hasSuffix(String(UnicodeScalar(0x2F)!) + $0)
          } ?? true
        return violation.code == code
          && pathMatches
      },
      "Missing violation \(code)\(pathSuffix.map { " at *\($0)" } ?? "")",
      file: (file),
      line: line
    )
  }

  private func passportObject(_ data: Data) throws -> [String: Any] {
    try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
  }

  private func childObjects(_ root: [String: Any]) throws -> [[String: Any]] {
    try XCTUnwrap(root["children"] as? [[String: Any]])
  }

  private func child(kind: String, in children: [[String: Any]]) throws -> [String: Any] {
    try XCTUnwrap(children.first { $0["kind"] as? String == kind })
  }

  private func childIndex(kind: String, in children: [[String: Any]]) throws -> Int {
    try XCTUnwrap(children.firstIndex { $0["kind"] as? String == kind })
  }

  private func mutatePassport(
    _ data: Data,
    _ mutation: (inout [String: Any]) throws -> Void
  ) throws -> Data {
    var root = try passportObject(data)
    try mutation(&root)
    return try JSONSerialization.data(
      withJSONObject: root,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }

  private func mutateChild(
    kind: String,
    in root: inout [String: Any],
    _ mutation: (inout [String: Any]) throws -> Void
  ) throws {
    var children = try childObjects(root)
    let index = try childIndex(kind: kind, in: children)
    try mutation(&children[index])
    root["children"] = children
  }
}
