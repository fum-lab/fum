import Darwin
import Foundation
import XCTest

@testable import FUMVerifiableMultiAgentContour

private let expectedJSONPointerSeparator = "/"

final class WorkPackageContractTests: XCTestCase {
  func testBundledFixtureInventoryIsStable() {
    XCTAssertEqual(
      WorkPackageFixtures.identifiers,
      [
        "ready",
        "split-missing-required-input",
        "split-multiple-deliverables",
        "split-no-reserve",
        "split-unbounded-change-scope",
        "split-unresolved-dependency",
      ]
    )
  }

  func testReadyFixtureProducesStableCanonicalReadyReport() throws {
    let data = try WorkPackageFixtures.load(named: "ready")

    let first = try analyze(data)
    let second = try analyze(data)

    XCTAssertEqual(first.decision, .ready)
    XCTAssertEqual(first.packageID, "fum.work-package.ready.v1")
    XCTAssertTrue(first.violations.isEmpty)
    XCTAssertTrue(first.contractSHA256.hasPrefix("sha256:"))
    XCTAssertEqual(first.contractSHA256.count, 71)
    XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())
  }

  func testNamedNegativeFixturesRequireSplitWithExpectedCodes() throws {
    let expectations = [
      "split-multiple-deliverables": "multiple_deliverables",
      "split-missing-required-input": "required_input_missing",
      "split-unbounded-change-scope": "unbounded_change_scope",
      "split-unresolved-dependency": "unresolved_dependency",
      "split-no-reserve": "reserve_missing",
    ]

    for (identifier, expectedCode) in expectations {
      let report = try analyze(
        try WorkPackageFixtures.load(named: identifier)
      )
      XCTAssertEqual(report.decision, .splitRequired, identifier)
      XCTAssertTrue(report.violations.map(\.code).contains(expectedCode), identifier)
    }
  }

  func testMalformedIncompleteUnknownAndTypeInvalidJSONFailClosed() throws {
    let malformed = try analyze(Data("{".utf8))
    XCTAssertEqual(malformed.decision, .splitRequired)
    XCTAssertEqual(malformed.violations.map(\.code), ["invalid_json"])

    let incomplete = try analyze(
      try mutateReady { $0.removeValue(forKey: "goal") }
    )
    XCTAssertTrue(codes(incomplete).contains("missing_field"))

    let unknown = try analyze(
      try mutateReady { $0["unexpected"] = true }
    )
    XCTAssertTrue(codes(unknown).contains("unknown_field"))

    let invalidType = try analyze(
      try mutateReady { $0["schema_version"] = true }
    )
    XCTAssertTrue(codes(invalidType).contains("invalid_type"))
  }

  func testDuplicateJSONKeyFailsClosedBeforeObjectDecoding() throws {
    let data = try WorkPackageFixtures.load(named: "ready")
    let source = try XCTUnwrap(String(data: data, encoding: .utf8))
    let duplicated = source.replacingOccurrences(
      of: "\"goal\":",
      with: "\"goal\": \"Повторное значение\", \"goal\":"
    )

    let report = try analyze(Data(duplicated.utf8))

    XCTAssertEqual(report.decision, .splitRequired)
    XCTAssertTrue(codes(report).contains("duplicate_key"))
    XCTAssertEqual(
      report.violations.first(where: { $0.code == "duplicate_key" })?.path,
      expectedJSONPointerSeparator + "goal"
    )
  }

  func testInvalidHashBudgetPhaseOrderOverlapAndDuplicatesFailClosed() throws {
    let invalidHash = try analyze(
      try mutateReady { root in
        var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
        inputs[0]["sha256"] = "sha256:not-a-digest"
        root["inputs"] = inputs
      }
    )
    XCTAssertTrue(codes(invalidHash).contains("invalid_hash"))

    let budgetExceeded = try analyze(
      try mutateReady { root in
        var budget = try XCTUnwrap(root["budget"] as? [String: Any])
        budget["work"] = 90
        root["budget"] = budget
      }
    )
    XCTAssertTrue(codes(budgetExceeded).contains("budget_exceeded"))

    let phaseOrder = try analyze(
      try mutateReady { root in
        var preflight = try XCTUnwrap(root["preflight"] as? [String: Any])
        preflight["before_model_call"] = false
        root["preflight"] = preflight
      }
    )
    XCTAssertTrue(codes(phaseOrder).contains("phase_order_invalid"))

    let overlap = try analyze(
      try mutateReady { root in
        var scope = try XCTUnwrap(root["change_scope"] as? [String: Any])
        let allowed = try XCTUnwrap(scope["allowed_paths"] as? [String])
        scope["excluded_paths"] = [allowed[0]]
        root["change_scope"] = scope
      }
    )
    XCTAssertTrue(codes(overlap).contains("scope_overlap"))

    let duplicate = try analyze(
      try mutateReady { root in
        var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
        inputs.append(inputs[0])
        root["inputs"] = inputs
      }
    )
    XCTAssertTrue(codes(duplicate).contains("duplicate_identifier"))
    XCTAssertTrue(codes(duplicate).contains("duplicate_path"))
  }

  func testEmptyChecksOversizedGoalAndNestedUnknownFieldFailClosed() throws {
    let emptyChecks = try analyze(
      try mutateReady { $0["checks"] = [] }
    )
    XCTAssertTrue(codes(emptyChecks).contains("checks_missing"))

    let oversizedGoal = try analyze(
      try mutateReady { $0["goal"] = String(repeating: "x", count: 4_097) }
    )
    XCTAssertTrue(codes(oversizedGoal).contains("string_limit_exceeded"))

    let nestedUnknown = try analyze(
      try mutateReady { root in
        var handoff = try XCTUnwrap(root["handoff"] as? [String: Any])
        handoff["unexpected"] = true
        root["handoff"] = handoff
      }
    )
    XCTAssertTrue(codes(nestedUnknown).contains("unknown_field"))
  }

  func testInputHashAndLegacyAvailabilityDeclarationFailClosed() throws {
    let hashMismatch = try analyze(
      try mutateReady { root in
        var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
        inputs[0]["sha256"] = "sha256:" + String(repeating: "0", count: 64)
        root["inputs"] = inputs
      }
    )
    XCTAssertTrue(codes(hashMismatch).contains("input_hash_mismatch"))

    let selfDeclaredAvailability = try analyze(
      try mutateReady { root in
        var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
        inputs[0]["available"] = true
        root["inputs"] = inputs
      }
    )
    XCTAssertTrue(codes(selfDeclaredAvailability).contains("unknown_field"))
  }

  func testSymbolicLinkInputCannotEscapeWorkspaceDescriptor() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-work-package-\(UUID().uuidString)",
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }
    let workspace = temporaryRoot.appendingPathComponent("workspace", isDirectory: true)
    let outside = temporaryRoot.appendingPathComponent("outside", isDirectory: true)
    try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let sourceURL = try WorkPackageFixtures.workspaceRoot()
      .appendingPathComponent("inputs/requirements.txt")
    let source = try Data(contentsOf: sourceURL)
    let outsideFile = outside.appendingPathComponent("requirements.md")
    try source.write(to: outsideFile)
    try FileManager.default.createSymbolicLink(
      at: workspace.appendingPathComponent("linked-input.md"),
      withDestinationURL: outsideFile
    )
    let contract = try mutateReady { root in
      var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
      inputs[0]["path"] = "linked-input.md"
      root["inputs"] = inputs
    }

    let report = WorkPackagePreflight.analyze(contract, workspaceRoot: workspace)

    XCTAssertEqual(report.decision, .splitRequired)
    XCTAssertTrue(codes(report).contains("input_path_unsafe"))
  }

  func testFIFOInputFailsClosedWithoutBlocking() throws {
    let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-work-package-fifo-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: workspace) }
    let fifo = workspace.appendingPathComponent("input.fifo")
    XCTAssertEqual(Darwin.mkfifo(fifo.path, S_IRUSR | S_IWUSR), 0)
    let contract = try mutateReady { root in
      var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
      inputs[0]["path"] = "input.fifo"
      root["inputs"] = inputs
    }

    let report = WorkPackagePreflight.analyze(contract, workspaceRoot: workspace)

    XCTAssertEqual(report.decision, .splitRequired)
    XCTAssertTrue(codes(report).contains("input_not_regular_file"))
  }

  func testDeepStructureAndExtremeNumbersFailClosedWithoutTrap() throws {
    let deep = Data(
      (String(repeating: "[", count: 66) + "0" + String(repeating: "]", count: 66)).utf8
    )
    XCTAssertTrue(codes(try analyze(deep)).contains("structure_limit_exceeded"))

    for numericLiteral in [
      "9223372036854775807",
      "9223372036854775808",
      "9007199254740993",
      "1e100",
    ] {
      let report = try analyze(
        try replacingReadySource(
          "\"limit\": 100",
          with: "\"limit\": \(numericLiteral)"
        )
      )
      XCTAssertEqual(report.decision, .splitRequired, numericLiteral)
      XCTAssertFalse(report.violations.isEmpty, numericLiteral)
    }
  }

  func testHandoffScopeControlPathAndStructuralBudgetFailClosed() throws {
    let handoffConflict = try analyze(
      try mutateReady { root in
        var handoff = try XCTUnwrap(root["handoff"] as? [String: Any])
        handoff["required_artifacts"] = ["elsewhere/result.json"]
        root["handoff"] = handoff
      }
    )
    XCTAssertTrue(codes(handoffConflict).contains("handoff_scope_conflict"))

    let controlPath = try analyze(
      try mutateReady { root in
        var scope = try XCTUnwrap(root["change_scope"] as? [String: Any])
        scope["allowed_paths"] = ["output/\u{0}result.json"]
        root["change_scope"] = scope
      }
    )
    XCTAssertTrue(codes(controlPath).contains("invalid_path"))

    let underdeclared = try analyze(
      try mutateReady { root in
        var inputs = try XCTUnwrap(root["inputs"] as? [[String: Any]])
        var second = inputs[0]
        second["id"] = "second-input"
        inputs.append(second)
        root["inputs"] = inputs
        var budget = try XCTUnwrap(root["budget"] as? [String: Any])
        budget["reading"] = 1
        root["budget"] = budget
      }
    )
    XCTAssertTrue(codes(underdeclared).contains("budget_underdeclared"))
  }

  func testViolationsAreSortedAndStable() throws {
    let data = try mutateReady { root in
      root["unexpected"] = true
      var budget = try XCTUnwrap(root["budget"] as? [String: Any])
      budget["reserve"] = 0
      budget["work"] = 100
      root["budget"] = budget
    }

    let first = try analyze(data)
    let second = try analyze(data)
    let ordering = first.violations.map { "\($0.code)\u{0}\($0.path)\u{0}\($0.message)" }

    XCTAssertEqual(ordering, ordering.sorted())
    XCTAssertEqual(first, second)
    XCTAssertEqual(try first.canonicalJSONData(), try second.canonicalJSONData())
  }

  private func codes(_ report: WorkPackageReport) -> Set<String> {
    Set(report.violations.map(\.code))
  }

  private func analyze(_ data: Data) throws -> WorkPackageReport {
    WorkPackagePreflight.analyze(
      data,
      workspaceRoot: try WorkPackageFixtures.workspaceRoot()
    )
  }

  private func replacingReadySource(_ needle: String, with replacement: String) throws -> Data {
    let data = try WorkPackageFixtures.load(named: "ready")
    let source = try XCTUnwrap(String(data: data, encoding: .utf8))
    let replaced = source.replacingOccurrences(of: needle, with: replacement)
    XCTAssertNotEqual(source, replaced)
    return Data(replaced.utf8)
  }

  private func mutateReady(
    _ mutation: (inout [String: Any]) throws -> Void
  ) throws -> Data {
    let data = try WorkPackageFixtures.load(named: "ready")
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
