import Foundation
import XCTest

@testable import FUMVerifiableMultiAgentContour

final class DurableForkSubnodeRuntimeTests: XCTestCase {
  func testFixtureInventoryIsStable() {
    XCTAssertEqual(
      DurableForkSubnodeFixtures.identifiers,
      [
        "roundtrip",
        "invalid-upstream-remote",
        "invalid-handoff-access",
        "invalid-handoff-base",
        "invalid-sync-oid",
        "invalid-sync-conflict",
        "invalid-sync-access",
        "invalid-sync-publication",
        "invalid-upstream-gitlink",
        "invalid-registration-upstream-gitlink",
        "invalid-ancestor-submodule",
        "invalid-self-recursive-submodule",
        "recursive-init-forbidden",
        "invalid-queue-namespace",
        "invalid-parent-update",
      ]
    )

  }

  func testRoundTripRegistersForkPublishesCandidateHandsOffAndRestoresBothClones() throws {
    let report = try DurableForkSubnodeFixtures.run(named: "roundtrip")

    XCTAssertEqual(report.decision, .passed)
    XCTAssertEqual(
      Set(report.checks.map(\.identifier)),
      Set([
        "fork_has_stable_identity",
        "fork_has_origin_and_upstream",
        "fork_has_own_rules_queue_and_next_step",
        "upstream_is_instance_free_core",
        "parent_gitlink_is_exact",
        "parent_snapshot_is_detached_and_clean",
        "writer_did_not_change_parent",
        "candidate_is_reachable_from_fork_live_ref",
        "handoff_binds_source_scope_checks_access_and_parent",
        "upstream_preserves_source_candidate_in_ancestry",
        "upstream_does_not_move_fork_live_ref_implicitly",
        "sync_is_explicit_and_exact",
        "parent_gitlink_update_is_separate_commit",
        "fresh_parent_clone_restores_exact_snapshot",
        "fresh_live_clone_continues_branch_and_next_step",
        "scenario_is_local_only",
      ])
    )
    XCTAssertNotNil(report.registrationPassportSHA256)
    XCTAssertNotNil(report.handoffPassportSHA256)
    XCTAssertNotNil(report.parentUpdatePassportSHA256)
    XCTAssertNotEqual(report.initialForkOID, report.finalForkOID)
    XCTAssertNotEqual(report.initialParentOID, report.finalParentOID)
    XCTAssertNotEqual(report.initialUpstreamOID, report.finalUpstreamOID)
  }

  func testNegativeScenariosFailClosedWithoutPublishingUnexpectedRefs() throws {
    let expectedChecks: [String: String] = [
      "invalid-upstream-remote": "remote_mismatch_rejected",
      "invalid-handoff-access": "publication_boundary_rejected",
      "invalid-handoff-base": "handoff_base_mismatch_rejected",
      "invalid-sync-oid": "sync_oid_mismatch_rejected",
      "invalid-sync-conflict": "sync_conflict_rejected_without_mutation",
      "invalid-sync-access": "sync_publication_boundary_rejected",
      "invalid-sync-publication": "sync_unsafe_tree_rejected",
      "invalid-upstream-gitlink": "sync_upstream_gitlink_rejected",
      "invalid-registration-upstream-gitlink":
        "registration_upstream_gitlink_rejected_without_refs",
      "invalid-ancestor-submodule": "submodule_references_ancestor",
      "invalid-self-recursive-submodule": "recursive_initialization_forbidden",
      "recursive-init-forbidden": "recursive_initialization_rejected_before_clone",
      "invalid-queue-namespace": "queue_outside_service_namespace_rejected",
      "invalid-parent-update":
        "parent_update_preflight_and_publication_rejected_without_refs",
    ]

    for (identifier, expectedCheck) in expectedChecks {
      let report = try DurableForkSubnodeFixtures.run(named: identifier)
      XCTAssertEqual(report.decision, .passed, identifier)
      XCTAssertEqual(report.checks.map(\.identifier), [expectedCheck], identifier)
      XCTAssertEqual(report.checks.first?.passed, true, identifier)
      XCTAssertEqual(report.unexpectedRefMutation, false, identifier)
    }
  }

  func testCanonicalScenarioReportContainsNoRuntimePathAndIsReproducible() throws {
    let first = try DurableForkSubnodeFixtures.run(named: "roundtrip")
    let second = try DurableForkSubnodeFixtures.run(named: "roundtrip")
    let firstData = try first.canonicalJSONData()
    let secondData = try second.canonicalJSONData()
    let text = try XCTUnwrap(String(data: firstData, encoding: .utf8))

    XCTAssertEqual(firstData, secondData)
    XCTAssertFalse(text.contains(FileManager.default.temporaryDirectory.path))
    XCTAssertFalse(text.contains("file:"))
    XCTAssertTrue(text.contains("urn:fum:"))
  }

  func testInvalidParentUpdateLeavesNoPublishedOrProofRef() throws {
    let report = try DurableForkSubnodeFixtures.run(named: "invalid-parent-update")

    XCTAssertEqual(report.decision, .passed)
    XCTAssertEqual(
      report.checks.map(\.identifier),
      ["parent_update_preflight_and_publication_rejected_without_refs"])
    XCTAssertFalse(report.unexpectedRefMutation)
    XCTAssertEqual(report.initialParentOID, report.finalParentOID)
  }
}
