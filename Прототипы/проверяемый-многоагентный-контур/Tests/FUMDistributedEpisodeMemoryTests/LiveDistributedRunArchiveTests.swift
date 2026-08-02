import FUMReproducibleMemoryPopulation
import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class LiveDistributedRunArchiveTests: XCTestCase {
  func testArchivePersistsHashedArtifactsAndReplaysCanonicalCurrent() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let request = try makeRequest(repositoryRoot: repositoryRoot)
    let requestData = try request.canonicalJSONData()

    let archived = try LiveDistributedRunArchive.archive(
      requestData: requestData,
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let recovered = try XCTUnwrap(
      LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
    )

    XCTAssertEqual(archived, recovered)
    XCTAssertEqual(
      try archived.generation.canonicalJSONData(),
      try recovered.generation.canonicalJSONData()
    )
    XCTAssertNil(recovered.generation.previousGenerationSHA256)
    XCTAssertEqual(
      recovered.generation.generationProfile,
      LiveDistributedRunGeneration.profileID
    )
    XCTAssertEqual(recovered.generation.terminal.outcome, .goalMet)
    XCTAssertEqual(recovered.generation.artifacts.count, request.artifacts.count)
    XCTAssertEqual(
      Set(recovered.generation.artifacts.map(\.artifactID)),
      Set(request.artifacts.map(\.artifactID))
    )
    XCTAssertEqual(
      try recovered.generation.artifact(named: "contribution.normative").decodedData(),
      try artifactData("contribution.normative")
    )
    XCTAssertEqual(
      recovered.generation.correlationGroups.first?.memberArtifactIDs,
      ["contribution.executable", "contribution.normative"]
    )
  }

  func testArchiveRejectsHashMismatchWithoutPublishingCurrent() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    request = request.replacingArtifactSHA256(
      artifactID: "contribution.normative",
      with: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard
        case LiveDistributedRunArchiveError.artifactHashMismatch(
          "contribution.normative"
        ) = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
    XCTAssertNil(
      try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
    )
  }

  func testSuccessorRequiresExactCurrentParent() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    var successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )
    successor = successor.replacingPreviousGenerationSHA256(
      "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: successor.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard
        case LiveDistributedRunArchiveError.generationConflict(
          expected: _,
          actual: let actual
        ) = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
      XCTAssertEqual(actual, first.generationSHA256)
    }
  }

  func testSuccessorAdvancesCurrentFromExactParent() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )

    let second = try LiveDistributedRunArchive.archive(
      requestData: successor.canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let recovered = try XCTUnwrap(
      LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
    )

    XCTAssertEqual(recovered, second)
    XCTAssertEqual(second.generation.previousGenerationSHA256, first.generationSHA256)
    XCTAssertNotEqual(second.generationSHA256, first.generationSHA256)
  }

  func testSuccessorReplayFailsClosedWhenParentGenerationIsMissing() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )
    _ = try LiveDistributedRunArchive.archive(
      requestData: successor.canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )

    let parentURL = storeRoot.appendingPathComponent(
      "generations/\(first.generationSHA256.dropFirst(7)).json"
    )
    try FileManager.default.removeItem(at: parentURL)

    XCTAssertThrowsError(
      try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
    ) { error in
      guard case LiveDistributedRunArchiveError.corruptGeneration = error else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
  }

  func testCommitRejectsExtensionOfBrokenConfirmedLineage() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let secondRequest = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )
    let second = try LiveDistributedRunArchive.archive(
      requestData: secondRequest.canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let thirdRequest = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: second,
      runID: "live.run.3",
      rootThreadID: "00000000-0000-0000-0000-000000000003"
    )
    let currentURL = storeRoot.appendingPathComponent("CURRENT.json")
    let confirmedCurrent = try Data(contentsOf: currentURL)
    let firstURL = storeRoot.appendingPathComponent(
      "generations/\(first.generationSHA256.dropFirst(7)).json"
    )
    try FileManager.default.removeItem(at: firstURL)

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: thirdRequest.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.corruptGeneration = error else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
    XCTAssertEqual(try Data(contentsOf: currentURL), confirmedCurrent)
  }

  func testSuccessorRejectsRepeatedRootSessionWithoutExecutingHandoff() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first,
      rootThreadID: first.generation.provenance.rootCodexThreadID
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: successor.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.incompatibleGeneration = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
  }

  func testSuccessorRejectsResultOutsidePreviousHandoffPath() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )
    let resultData = try Data(
      contentsOf: repositoryRoot.appendingPathComponent("resume-result.json")
    )
    let wrongPath = "unannounced-result.json"
    try resultData.write(to: repositoryRoot.appendingPathComponent(wrongPath))
    let redirected = replacingSourcePath(
      in: successor,
      artifactID: "handoff.result",
      with: wrongPath
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: redirected.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.incompatibleGeneration = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
  }

  func testSuccessorRejectsFailedRequiredInputAttestation() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let first = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    var successor = try makeSuccessorRequest(
      repositoryRoot: repositoryRoot,
      previous: first
    )
    let resultURL = repositoryRoot.appendingPathComponent("resume-result.json")
    var result = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: resultURL))
        as? [String: Any]
    )
    var inputChecks = try XCTUnwrap(result["input_checks"] as? [[String: Any]])
    inputChecks[0]["status"] = "failed"
    result["input_checks"] = inputChecks
    let resultData = try jsonData(result)
    try resultData.write(to: resultURL)
    successor = successor.replacingArtifactSHA256(
      artifactID: "handoff.result",
      with: LiveDistributedRunArchive.contentSHA256(resultData)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: successor.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.incompatibleGeneration = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
    }
  }

  func testArchiveRejectsDecisionArtifactThatContradictsStructuredDecision() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let contradictory = try jsonData([
      "schema_version": 1,
      "status": "inconclusive",
      "verification_artifact_id": "verification.independent",
      "selected_claim_ids": ["claim.executable", "claim.normative"],
      "rejected_claim_ids": [],
      "unresolved_disagreement_ids": [],
      "vote_count_used": false,
    ])
    try contradictory.write(
      to: repositoryRoot.appendingPathComponent("decision.json")
    )
    request = request.replacingArtifactSHA256(
      artifactID: "decision.root",
      with: LiveDistributedRunArchive.contentSHA256(contradictory)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
    XCTAssertNil(try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent())
  }

  func testArchiveRejectsMissingPreflightOrProvenance() throws {
    for removedArtifactID in ["preflight.next", "provenance.correlation"] {
      let repositoryRoot = try temporaryDirectory()
      let storeRoot = try temporaryDirectory()
      let request = try makeRequest(repositoryRoot: repositoryRoot)
      let incomplete = replacingArtifacts(
        in: request,
        with: request.artifacts.filter { $0.artifactID != removedArtifactID }
      )

      XCTAssertThrowsError(
        try LiveDistributedRunArchive.archive(
          requestData: incomplete.canonicalJSONData(),
          repositoryRoot: repositoryRoot,
          storeRoot: storeRoot
        )
      )
      XCTAssertNil(
        try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
      )
    }
  }

  func testArchiveRejectsTruncatedNextPackageEvenWithMatchingHandoff() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let packageURL = repositoryRoot.appendingPathComponent("package-next.json")
    var package = try XCTUnwrap(
      JSONSerialization.jsonObject(with: artifactData("package.next"))
        as? [String: Any]
    )
    let inputs = try XCTUnwrap(package["inputs"] as? [[String: Any]])
    package["inputs"] = [try XCTUnwrap(inputs.first)]
    let packageData = try jsonData(package)
    try packageData.write(to: packageURL)

    let preflightData = try jsonData([
      "schema_version": 1,
      "package_id": packageID(for: "package.next"),
      "contract_sha256": LiveDistributedRunArchive.contentSHA256(packageData),
      "decision": "ready",
      "violations": [],
      "observed_duration_seconds": 0.01,
    ])
    try preflightData.write(
      to: repositoryRoot.appendingPathComponent("preflight-next.json")
    )
    request =
      request
      .replacingArtifactSHA256(
        artifactID: "package.next",
        with: LiveDistributedRunArchive.contentSHA256(packageData)
      )
      .replacingArtifactSHA256(
        artifactID: "preflight.next",
        with: LiveDistributedRunArchive.contentSHA256(preflightData)
      )
    request = replacingHandoff(
      in: request,
      with: LiveDistributedRunHandoff(
        nextCardID: request.handoff.nextCardID,
        nextWorkPackageArtifactID: request.handoff.nextWorkPackageArtifactID,
        requiredArtifactIDs: [
          "package.next", "passport.live", "preflight.next",
        ]
      )
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
    XCTAssertNil(try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent())
  }

  func testArchiveRejectsContributionInputPathSubstitution() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let contributionURL = repositoryRoot.appendingPathComponent(
      "contribution-normative.json"
    )
    var contribution = try XCTUnwrap(
      JSONSerialization.jsonObject(with: artifactData("contribution.normative"))
        as? [String: Any]
    )
    var inputs = try XCTUnwrap(contribution["inputs"] as? [[String: Any]])
    inputs[0]["path"] = fixtureInputPath("package.executable")
    contribution["inputs"] = inputs
    let contributionData = try jsonData(contribution)
    try contributionData.write(to: contributionURL)
    request = request.replacingArtifactSHA256(
      artifactID: "contribution.normative",
      with: LiveDistributedRunArchive.contentSHA256(contributionData)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
  }

  func testArchiveRejectsVerifierThatRepeatsProducerIdentity() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let verificationURL = repositoryRoot.appendingPathComponent("verification.json")
    var verification = try XCTUnwrap(
      JSONSerialization.jsonObject(with: artifactData("verification.independent"))
        as? [String: Any]
    )
    verification["public_executor_id"] = "worker.normative"
    verification["role"] = "normative"
    let verificationData = try jsonData(verification)
    try verificationData.write(to: verificationURL)
    request = request.replacingArtifactSHA256(
      artifactID: "verification.independent",
      with: LiveDistributedRunArchive.contentSHA256(verificationData)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
  }

  func testArchiveRejectsUnknownArtifactKindAndNestedPayloadField() throws {
    do {
      let repositoryRoot = try temporaryDirectory()
      let storeRoot = try temporaryDirectory()
      let request = try makeRequest(repositoryRoot: repositoryRoot)
      let extraData = try jsonData(["schema_version": 1, "payload": "private"])
      try extraData.write(
        to: repositoryRoot.appendingPathComponent("extra-payload.json")
      )
      let extra = LiveDistributedRunArtifactSource(
        artifactID: "extra.payload",
        kind: "opaque_payload",
        logicalPath: "extra-payload.json",
        mediaType: "application/json",
        sourcePath: "extra-payload.json",
        contentSHA256: LiveDistributedRunArchive.contentSHA256(extraData)
      )
      let extended = replacingArtifacts(
        in: request,
        with: request.artifacts + [extra]
      )
      XCTAssertThrowsError(
        try LiveDistributedRunArchive.archive(
          requestData: extended.canonicalJSONData(),
          repositoryRoot: repositoryRoot,
          storeRoot: storeRoot
        )
      )
    }

    do {
      let repositoryRoot = try temporaryDirectory()
      let storeRoot = try temporaryDirectory()
      var request = try makeRequest(repositoryRoot: repositoryRoot)
      var contribution = try XCTUnwrap(
        JSONSerialization.jsonObject(with: artifactData("contribution.normative"))
          as? [String: Any]
      )
      var package = try XCTUnwrap(contribution["package"] as? [String: Any])
      package["private_reasoning"] = "must not be embedded"
      contribution["package"] = package
      let contributionData = try jsonData(contribution)
      request = try replacingArtifactDataAndRefreshingNextPackage(
        in: request,
        repositoryRoot: repositoryRoot,
        artifactID: "contribution.normative",
        data: contributionData
      )
      XCTAssertThrowsError(
        try LiveDistributedRunArchive.archive(
          requestData: request.canonicalJSONData(),
          repositoryRoot: repositoryRoot,
          storeRoot: storeRoot
        )
      ) { error in
        guard case LiveDistributedRunArchiveError.corruptGeneration(let message) = error
        else {
          return XCTFail("Получена неожиданная ошибка: \(error)")
        }
        XCTAssertTrue(message.contains("закрытому профилю"))
      }
    }
  }

  func testArchiveRejectsDuplicateJSONMemberBeforeEmbedding() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let valid = String(
      decoding: try artifactData("contribution.normative"),
      as: UTF8.self
    )
    let poisoned = Data(
      (String(valid.dropLast())
        + ",\"schema_version\":1}")
        .utf8
    )
    request = try replacingArtifactDataAndRefreshingNextPackage(
      in: request,
      repositoryRoot: repositoryRoot,
      artifactID: "contribution.normative",
      data: poisoned
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.corruptGeneration(let message) = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
      XCTAssertTrue(message.contains("закрытому профилю"))
    }
  }

  func testArchiveRejectsFractionalTokenForIntegerField() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let valid = String(
      decoding: try artifactData("contribution.normative"),
      as: UTF8.self
    )
    let poisoned = Data(
      valid.replacingOccurrences(
        of: "\"claim_id\":\"claim.normative\"",
        with:
          "\"claim_id\":\"claim.normative\",\"line_start\":9007199254740992.5"
      ).utf8
    )
    request = try replacingArtifactDataAndRefreshingNextPackage(
      in: request,
      repositoryRoot: repositoryRoot,
      artifactID: "contribution.normative",
      data: poisoned
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    ) { error in
      guard case LiveDistributedRunArchiveError.corruptGeneration(let message) = error
      else {
        return XCTFail("Получена неожиданная ошибка: \(error)")
      }
      XCTAssertTrue(message.contains("закрытому профилю"))
    }
  }

  func testArchiveRejectsNonReadyPreflight() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let preflightURL = repositoryRoot.appendingPathComponent("preflight-next.json")
    let contradictory = try jsonData([
      "schema_version": 1,
      "package_id": packageID(for: "package.next"),
      "contract_sha256": LiveDistributedRunArchive.contentSHA256(
        try artifactData("package.next")
      ),
      "decision": "split_required",
      "violations": [["code": "forced_test_failure"]],
      "observed_duration_seconds": 0.01,
    ])
    try contradictory.write(to: preflightURL)
    request = request.replacingArtifactSHA256(
      artifactID: "preflight.next",
      with: LiveDistributedRunArchive.contentSHA256(contradictory)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
    XCTAssertNil(try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent())
  }

  func testArchiveRejectsContradictoryProvenanceArtifact() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    var request = try makeRequest(repositoryRoot: repositoryRoot)
    let provenanceURL = repositoryRoot.appendingPathComponent("provenance.json")
    var contradictory = try XCTUnwrap(
      JSONSerialization.jsonObject(with: artifactData("provenance.correlation"))
        as? [String: Any]
    )
    var observedSeparation = try XCTUnwrap(
      contradictory["observed_separation"] as? [String: Any]
    )
    observedSeparation["semantic_independence_proven"] = true
    contradictory["observed_separation"] = observedSeparation
    let contradictoryData = try jsonData(contradictory)
    try contradictoryData.write(to: provenanceURL)
    request = request.replacingArtifactSHA256(
      artifactID: "provenance.correlation",
      with: LiveDistributedRunArchive.contentSHA256(contradictoryData)
    )

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
    XCTAssertNil(try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent())
  }

  func testArchiveRejectsSymbolicLinkArtifact() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let request = try makeRequest(repositoryRoot: repositoryRoot)
    let source = repositoryRoot.appendingPathComponent("contribution-normative.json")
    let target = repositoryRoot.appendingPathComponent("target.json")
    try FileManager.default.moveItem(at: source, to: target)
    try FileManager.default.createSymbolicLink(at: source, withDestinationURL: target)

    XCTAssertThrowsError(
      try LiveDistributedRunArchive.archive(
        requestData: request.canonicalJSONData(),
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
    )
    XCTAssertNil(try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent())
  }

  func testArchiveRejectsControlCharactersInSourcePaths() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let request = try makeRequest(repositoryRoot: repositoryRoot)

    for control in ["\0", "\n", "\r", "\t", "\u{7F}"] {
      let unsafePath = "contribution-normative.json\(control)ignored.json"
      let unsafeRequest = replacingSourcePath(
        in: request,
        artifactID: "contribution.normative",
        with: unsafePath
      )

      XCTAssertThrowsError(
        try LiveDistributedRunArchive.archive(
          requestData: unsafeRequest.canonicalJSONData(),
          repositoryRoot: repositoryRoot,
          storeRoot: storeRoot
        )
      ) { error in
        guard case LiveDistributedRunArchiveError.invalidRequest = error
        else {
          return XCTFail("Получена неожиданная ошибка: \(error)")
        }
      }
      XCTAssertNil(
        try LiveDistributedRunArchiveStore(rootURL: storeRoot).loadCurrent()
      )
    }
  }

  func testCurrentUsesCanonicalJSONProfile() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    _ = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )

    let pointerData = try Data(
      contentsOf: storeRoot.appendingPathComponent("CURRENT.json")
    )
    let pointer = try XCTUnwrap(
      JSONSerialization.jsonObject(with: pointerData) as? [String: Any]
    )
    XCTAssertEqual(
      pointer["canonical_profile"] as? String,
      CanonicalMemoryJSON.profileID
    )
  }

  func testGenerationValidationRejectsSemanticBypass() throws {
    let repositoryRoot = try temporaryDirectory()
    let storeRoot = try temporaryDirectory()
    let archived = try LiveDistributedRunArchive.archive(
      requestData: makeRequest(repositoryRoot: repositoryRoot).canonicalJSONData(),
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    )
    let original = archived.generation
    let weakened = LiveDistributedRunGeneration(
      generationProfile: original.generationProfile,
      runID: original.runID,
      previousGenerationSHA256: original.previousGenerationSHA256,
      requestBase64: original.requestBase64,
      requestSHA256: original.requestSHA256,
      question: original.question,
      artifactManifestSHA256: original.artifactManifestSHA256,
      artifacts: original.artifacts,
      correlationGroups: original.correlationGroups,
      decision: original.decision,
      terminal: original.terminal,
      handoff: original.handoff,
      provenance: LiveDistributedRunProvenance(
        rootCodexThreadID: original.provenance.rootCodexThreadID,
        orchestrationSurface: original.provenance.orchestrationSurface,
        modelIdentityObservation: original.provenance.modelIdentityObservation,
        producerArtifactIDs: ["contribution.normative"],
        verifierArtifactID: original.provenance.verifierArtifactID,
        hiddenReasoningPersisted: false,
        orchestratorMessagesPersisted: false
      )
    )

    XCTAssertThrowsError(try LiveDistributedRunArchive.validate(weakened))
  }

  private func makeRequest(
    repositoryRoot: URL,
    runID: String = "live.run.1",
    rootThreadID: String = "00000000-0000-0000-0000-000000000001"
  ) throws -> LiveDistributedRunArchiveRequest {
    for packageArtifactID in [
      "package.normative", "package.executable", "package.verifier",
    ] {
      try fixtureInputData(packageArtifactID).write(
        to: repositoryRoot.appendingPathComponent(
          fixtureInputPath(packageArtifactID)
        )
      )
    }
    let contents: [(String, String, String)] = [
      ("passport.live", "episode_passport", "passport.json"),
      ("package.normative", "work_package", "package-normative.json"),
      ("package.executable", "work_package", "package-executable.json"),
      ("package.verifier", "work_package", "package-verifier.json"),
      ("preflight.normative", "preflight", "preflight-normative.json"),
      ("preflight.executable", "preflight", "preflight-executable.json"),
      ("preflight.verifier", "preflight", "preflight-verifier.json"),
      ("preflight.next", "preflight", "preflight-next.json"),
      ("contribution.normative", "contribution", "contribution-normative.json"),
      ("contribution.executable", "contribution", "contribution-executable.json"),
      ("provenance.correlation", "provenance", "provenance.json"),
      ("verification.independent", "verification", "verification.json"),
      ("decision.root", "decision", "decision.json"),
      ("terminal.root", "terminal", "terminal.json"),
      ("package.next", "work_package", "package-next.json"),
    ]
    var sources: [LiveDistributedRunArtifactSource] = []
    for (artifactID, kind, path) in contents {
      let data = try artifactData(artifactID, rootThreadID: rootThreadID)
      try data.write(to: repositoryRoot.appendingPathComponent(path))
      sources.append(
        LiveDistributedRunArtifactSource(
          artifactID: artifactID,
          kind: kind,
          logicalPath: path,
          mediaType: "application/json",
          sourcePath: path,
          contentSHA256: LiveDistributedRunArchive.contentSHA256(data)
        )
      )
    }

    return LiveDistributedRunArchiveRequest(
      runID: runID,
      previousGenerationSHA256: nil,
      question: "What is proven and what remains unproven?",
      artifacts: sources,
      correlationGroups: [
        LiveDistributedRunCorrelationGroup(
          groupID: "correlation.shared-provider",
          kind: "shared_provider",
          basis: "Both workers used one observed provider surface.",
          memberArtifactIDs: [
            "contribution.executable", "contribution.normative",
          ]
        )
      ],
      decision: LiveDistributedRunDecision(
        status: .accepted,
        basisArtifactIDs: ["verification.independent"],
        selectedClaimIDs: ["claim.normative", "claim.executable"],
        rejectedClaimIDs: [],
        unresolvedDisagreementIDs: []
      ),
      terminal: LiveDistributedRunTerminal(
        outcome: .goalMet,
        reasonCode: "verified_evidence_archived",
        evidenceArtifactIDs: [
          "decision.root", "verification.independent",
        ]
      ),
      handoff: LiveDistributedRunHandoff(
        nextCardID: "FUM-STEP-0083",
        nextWorkPackageArtifactID: "package.next",
        requiredArtifactIDs: [
          "contribution.executable", "contribution.normative", "decision.root",
          "package.next", "passport.live", "preflight.next",
          "provenance.correlation", "terminal.root", "verification.independent",
        ]
      ),
      provenance: LiveDistributedRunProvenance(
        rootCodexThreadID: rootThreadID,
        orchestrationSurface: "Codex collaboration tool",
        modelIdentityObservation: "not disclosed",
        producerArtifactIDs: [
          "contribution.executable", "contribution.normative",
        ],
        verifierArtifactID: "verification.independent",
        hiddenReasoningPersisted: false,
        orchestratorMessagesPersisted: false
      )
    )
  }

  private func makeSuccessorRequest(
    repositoryRoot: URL,
    previous: StoredLiveDistributedRunGeneration,
    runID: String = "live.run.2",
    rootThreadID: String = "00000000-0000-0000-0000-000000000002"
  ) throws -> LiveDistributedRunArchiveRequest {
    let base = try makeRequest(
      repositoryRoot: repositoryRoot,
      runID: runID,
      rootThreadID: rootThreadID
    )
    let previousPackageArtifact = try previous.generation.artifact(
      named: previous.generation.handoff.nextWorkPackageArtifactID
    )
    let previousPackage = try XCTUnwrap(
      JSONSerialization.jsonObject(with: previousPackageArtifact.decodedData())
        as? [String: Any]
    )
    let previousInputs = try XCTUnwrap(previousPackage["inputs"] as? [[String: Any]])
    let inputChecks: [[String: Any]] = try previousInputs.map { input in
      [
        "input_id": try XCTUnwrap(input["id"] as? String),
        "path": try XCTUnwrap(input["path"] as? String),
        "sha256": try XCTUnwrap(input["sha256"] as? String),
        "status": "passed",
      ]
    }
    let resultData = try jsonData([
      "schema_version": 1,
      "previous_generation_sha256": previous.generationSHA256,
      "previous_next_card_id": previous.generation.handoff.nextCardID,
      "previous_work_package_artifact_id": previousPackageArtifact.artifactID,
      "previous_work_package_content_sha256": previousPackageArtifact.contentSHA256,
      "executed_package_id": packageID(for: "package.next"),
      "root_codex_thread_id": rootThreadID,
      "input_checks": inputChecks,
      "terminal_outcome": base.terminal.outcome.rawValue,
      "outcome": "completed",
    ])
    let resultPath = "resume-result.json"
    try resultData.write(to: repositoryRoot.appendingPathComponent(resultPath))
    let resultSource = LiveDistributedRunArtifactSource(
      artifactID: "handoff.result",
      kind: "handoff_result",
      logicalPath: resultPath,
      mediaType: "application/json",
      sourcePath: resultPath,
      contentSHA256: LiveDistributedRunArchive.contentSHA256(resultData)
    )
    return LiveDistributedRunArchiveRequest(
      schemaVersion: base.schemaVersion,
      runID: base.runID,
      previousGenerationSHA256: previous.generationSHA256,
      question: base.question,
      artifacts: base.artifacts + [resultSource],
      correlationGroups: base.correlationGroups,
      decision: base.decision,
      terminal: LiveDistributedRunTerminal(
        schemaVersion: base.terminal.schemaVersion,
        outcome: base.terminal.outcome,
        reasonCode: base.terminal.reasonCode,
        evidenceArtifactIDs: (base.terminal.evidenceArtifactIDs + [resultSource.artifactID])
          .sorted()
      ),
      handoff: base.handoff,
      provenance: base.provenance
    )
  }

  private func artifactData(
    _ artifactID: String,
    rootThreadID: String = "00000000-0000-0000-0000-000000000001"
  ) throws -> Data {
    let question = "What is proven and what remains unproven?"
    switch artifactID {
    case "passport.live":
      return try jsonData([
        "schema_version": 1,
        "question": question,
        "root_codex_thread_id": rootThreadID,
      ])
    case "package.normative", "package.executable", "package.verifier", "package.next":
      return try workPackageData(artifactID, rootThreadID: rootThreadID)
    case "preflight.normative", "preflight.executable", "preflight.verifier",
      "preflight.next":
      let packageArtifactID = packageArtifactID(for: artifactID)
      let packageData = try artifactData(
        packageArtifactID,
        rootThreadID: rootThreadID
      )
      return try jsonData([
        "schema_version": 1,
        "package_id": packageID(for: packageArtifactID),
        "contract_sha256": LiveDistributedRunArchive.contentSHA256(packageData),
        "decision": "ready",
        "violations": [],
        "observed_duration_seconds": 0.01,
      ])
    case "contribution.normative":
      return try jsonData([
        "schema_version": 1,
        "contribution_id": artifactID,
        "public_executor_id": "worker.normative",
        "role": "normative",
        "package": try packageReference(
          "package.normative",
          rootThreadID: rootThreadID
        ),
        "question": question,
        "root_codex_thread_id": rootThreadID,
        "inputs": [
          [
            "path": fixtureInputPath("package.normative"),
            "sha256": LiveDistributedRunArchive.contentSHA256(
              try fixtureInputData("package.normative")
            ),
          ]
        ],
        "claims": [["claim_id": "claim.normative"]],
      ])
    case "contribution.executable":
      return try jsonData([
        "schema_version": 1,
        "contribution_id": artifactID,
        "public_executor_id": "worker.executable",
        "role": "executable",
        "package": try packageReference(
          "package.executable",
          rootThreadID: rootThreadID
        ),
        "question": question,
        "root_codex_thread_id": rootThreadID,
        "inputs": [
          [
            "path": fixtureInputPath("package.executable"),
            "sha256": LiveDistributedRunArchive.contentSHA256(
              try fixtureInputData("package.executable")
            ),
          ]
        ],
        "claims": [["claim_id": "claim.executable"]],
      ])
    case "provenance.correlation":
      return try jsonData([
        "schema_version": 1,
        "root_codex_thread_id": rootThreadID,
        "contributions": [
          [
            "artifact_id": "contribution.executable",
            "public_executor_id": "worker.executable",
            "role": "executable",
            "package_id": packageID(for: "package.executable"),
            "input_manifest_sha256s": [
              LiveDistributedRunArchive.contentSHA256(
                try fixtureInputData("package.executable")
              )
            ],
            "saw_other_contribution_before_publication": false,
          ],
          [
            "artifact_id": "contribution.normative",
            "public_executor_id": "worker.normative",
            "role": "normative",
            "package_id": packageID(for: "package.normative"),
            "input_manifest_sha256s": [
              LiveDistributedRunArchive.contentSHA256(
                try fixtureInputData("package.normative")
              )
            ],
            "saw_other_contribution_before_publication": false,
          ],
        ],
        "correlation_groups": [
          [
            "group_id": "correlation.shared-provider",
            "kind": "shared_provider",
            "basis": "Both workers used one observed provider surface.",
            "member_artifact_ids": [
              "contribution.executable", "contribution.normative",
            ],
          ]
        ],
        "observed_separation": [
          "distinct_roles": true,
          "distinct_package_ids": true,
          "non_overlapping_primary_inputs": true,
          "results_withheld_until_both_published": true,
          "semantic_independence_proven": false,
        ],
        "not_shared_memory": [
          "hidden reasoning", "orchestrator messages", "private child identifiers",
        ],
      ])
    case "verification.independent":
      return try jsonData([
        "schema_version": 1,
        "verification_id": artifactID,
        "public_executor_id": "worker.verifier",
        "role": "verifier",
        "package": try packageReference(
          "package.verifier",
          rootThreadID: rootThreadID
        ),
        "root_codex_thread_id": rootThreadID,
        "inputs": [
          [
            "path": fixtureInputPath("package.verifier"),
            "sha256": LiveDistributedRunArchive.contentSHA256(
              try fixtureInputData("package.verifier")
            ),
          ]
        ],
        "overall_outcome": "passed",
        "claim_assessments": [
          ["claim_id": "claim.normative", "status": "passed"],
          ["claim_id": "claim.executable", "status": "passed"],
        ],
      ])
    case "decision.root":
      return try jsonData([
        "schema_version": 1,
        "status": "accepted",
        "verification_artifact_id": "verification.independent",
        "selected_claim_ids": ["claim.executable", "claim.normative"],
        "rejected_claim_ids": [],
        "unresolved_disagreement_ids": [],
        "vote_count_used": false,
      ])
    case "terminal.root":
      return try jsonData([
        "schema_version": 1,
        "outcome": "goal_met",
        "reason_code": "verified_evidence_archived",
        "unresolved_disagreement_ids": [],
        "handoff_next_card_id": "FUM-STEP-0083",
      ])
    default:
      return try jsonData([
        "schema_version": 1,
        "artifact_id": artifactID,
      ])
    }
  }

  private func workPackageData(
    _ artifactID: String,
    rootThreadID: String
  ) throws -> Data {
    let outputPath = "output/\(artifactID).json"
    let inputs: [[String: Any]]
    let requiredArtifacts: [String]
    let allowedPaths: [String]
    if artifactID == "package.next" {
      let inputArtifactIDs = [
        "passport.live", "contribution.normative", "contribution.executable",
        "provenance.correlation", "verification.independent", "decision.root",
        "terminal.root",
      ]
      inputs = try inputArtifactIDs.map { inputArtifactID in
        let data = try artifactData(
          inputArtifactID,
          rootThreadID: rootThreadID
        )
        return [
          "id": inputArtifactID,
          "path": artifactSourcePath(inputArtifactID),
          "sha256": LiveDistributedRunArchive.contentSHA256(data),
          "required": true,
        ]
      }
      requiredArtifacts = ["memory/CURRENT.json", "resume-result.json"]
      allowedPaths = ["memory", "resume-result.json"]
    } else {
      inputs = [
        [
          "id": "input",
          "path": fixtureInputPath(artifactID),
          "sha256": LiveDistributedRunArchive.contentSHA256(
            try fixtureInputData(artifactID)
          ),
          "required": true,
        ]
      ]
      requiredArtifacts = [outputPath]
      allowedPaths = [outputPath]
    }
    return try jsonData([
      "schema_version": 1,
      "package_id": packageID(for: artifactID),
      "goal": "Validate one bounded live-run role.",
      "deliverables": [
        [
          "id": "result",
          "role": "primary",
          "description": "One bounded result.",
          "depends_on": [],
        ]
      ],
      "inputs": inputs,
      "change_scope": [
        "policy": "listed_paths_only",
        "allowed_paths": allowedPaths,
        "excluded_paths": ["runtime", "network"],
      ],
      "dependencies": [
        [
          "id": "local-runtime",
          "status": "resolved",
          "evidence": "The fixture uses only local files.",
        ]
      ],
      "checks": [
        [
          "id": "archive-test",
          "description": "The archive test validates the bounded result.",
        ]
      ],
      "handoff": [
        "format": "canonical_json_v1",
        "required_artifacts": requiredArtifacts,
      ],
      "budget": [
        "unit": "planning_units",
        "limit": 100,
        "reading": 20,
        "work": 35,
        "verification": 20,
        "response": 10,
        "reserve": 15,
      ],
      "preflight": [
        "before_model_call": true,
        "before_user_data_mutation": true,
      ],
    ])
  }

  private func packageReference(
    _ artifactID: String,
    rootThreadID: String
  ) throws -> [String: Any] {
    let packageData = try self.artifactData(
      artifactID,
      rootThreadID: rootThreadID
    )
    return [
      "path": packageSourcePath(artifactID),
      "package_id": packageID(for: artifactID),
      "preflight_contract_sha256": LiveDistributedRunArchive.contentSHA256(
        packageData
      ),
    ]
  }

  private func fixtureInputData(_ packageArtifactID: String) throws -> Data {
    return Data("input for \(packageArtifactID)\n".utf8)
  }

  private func fixtureInputPath(_ packageArtifactID: String) -> String {
    "input-\(packageArtifactID).txt"
  }

  private func artifactSourcePath(_ artifactID: String) -> String {
    switch artifactID {
    case "passport.live": "passport.json"
    case "contribution.normative": "contribution-normative.json"
    case "contribution.executable": "contribution-executable.json"
    case "provenance.correlation": "provenance.json"
    case "verification.independent": "verification.json"
    case "decision.root": "decision.json"
    case "terminal.root": "terminal.json"
    default: "unknown-artifact.json"
    }
  }

  private func packageArtifactID(for preflightArtifactID: String) -> String {
    "package." + preflightArtifactID.dropFirst("preflight.".count)
  }

  private func packageID(for artifactID: String) -> String {
    "fum.test.\(artifactID).v1"
  }

  private func packageSourcePath(_ artifactID: String) -> String {
    switch artifactID {
    case "package.normative": "package-normative.json"
    case "package.executable": "package-executable.json"
    case "package.verifier": "package-verifier.json"
    case "package.next": "package-next.json"
    default: "unknown-package.json"
    }
  }

  private func replacingArtifactDataAndRefreshingNextPackage(
    in request: LiveDistributedRunArchiveRequest,
    repositoryRoot: URL,
    artifactID: String,
    data: Data
  ) throws -> LiveDistributedRunArchiveRequest {
    let source = try XCTUnwrap(
      request.artifacts.first { $0.artifactID == artifactID }
    )
    try data.write(to: repositoryRoot.appendingPathComponent(source.sourcePath))
    var updated = request.replacingArtifactSHA256(
      artifactID: artifactID,
      with: LiveDistributedRunArchive.contentSHA256(data)
    )

    let packageSource = try XCTUnwrap(
      updated.artifacts.first { $0.artifactID == "package.next" }
    )
    let packageURL = repositoryRoot.appendingPathComponent(packageSource.sourcePath)
    var package = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: packageURL))
        as? [String: Any]
    )
    var inputs = try XCTUnwrap(package["inputs"] as? [[String: Any]])
    let inputIndex = try XCTUnwrap(
      inputs.firstIndex { $0["id"] as? String == artifactID }
    )
    inputs[inputIndex]["sha256"] = LiveDistributedRunArchive.contentSHA256(data)
    package["inputs"] = inputs
    let packageData = try jsonData(package)
    try packageData.write(to: packageURL)
    updated = updated.replacingArtifactSHA256(
      artifactID: "package.next",
      with: LiveDistributedRunArchive.contentSHA256(packageData)
    )

    let preflightSource = try XCTUnwrap(
      updated.artifacts.first { $0.artifactID == "preflight.next" }
    )
    let preflightURL = repositoryRoot.appendingPathComponent(preflightSource.sourcePath)
    var preflight = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: preflightURL))
        as? [String: Any]
    )
    preflight["contract_sha256"] = LiveDistributedRunArchive.contentSHA256(
      packageData
    )
    let preflightData = try jsonData(preflight)
    try preflightData.write(to: preflightURL)
    return updated.replacingArtifactSHA256(
      artifactID: "preflight.next",
      with: LiveDistributedRunArchive.contentSHA256(preflightData)
    )
  }

  private func replacingSourcePath(
    in request: LiveDistributedRunArchiveRequest,
    artifactID: String,
    with sourcePath: String
  ) -> LiveDistributedRunArchiveRequest {
    LiveDistributedRunArchiveRequest(
      schemaVersion: request.schemaVersion,
      runID: request.runID,
      previousGenerationSHA256: request.previousGenerationSHA256,
      question: request.question,
      artifacts: request.artifacts.map { artifact in
        guard artifact.artifactID == artifactID else { return artifact }
        return LiveDistributedRunArtifactSource(
          schemaVersion: artifact.schemaVersion,
          artifactID: artifact.artifactID,
          kind: artifact.kind,
          logicalPath: artifact.logicalPath,
          mediaType: artifact.mediaType,
          sourcePath: sourcePath,
          contentSHA256: artifact.contentSHA256
        )
      },
      correlationGroups: request.correlationGroups,
      decision: request.decision,
      terminal: request.terminal,
      handoff: request.handoff,
      provenance: request.provenance
    )
  }

  private func replacingArtifacts(
    in request: LiveDistributedRunArchiveRequest,
    with artifacts: [LiveDistributedRunArtifactSource]
  ) -> LiveDistributedRunArchiveRequest {
    LiveDistributedRunArchiveRequest(
      schemaVersion: request.schemaVersion,
      runID: request.runID,
      previousGenerationSHA256: request.previousGenerationSHA256,
      question: request.question,
      artifacts: artifacts,
      correlationGroups: request.correlationGroups,
      decision: request.decision,
      terminal: request.terminal,
      handoff: request.handoff,
      provenance: request.provenance
    )
  }

  private func replacingHandoff(
    in request: LiveDistributedRunArchiveRequest,
    with handoff: LiveDistributedRunHandoff
  ) -> LiveDistributedRunArchiveRequest {
    LiveDistributedRunArchiveRequest(
      schemaVersion: request.schemaVersion,
      runID: request.runID,
      previousGenerationSHA256: request.previousGenerationSHA256,
      question: request.question,
      artifacts: request.artifacts,
      correlationGroups: request.correlationGroups,
      decision: request.decision,
      terminal: request.terminal,
      handoff: handoff,
      provenance: request.provenance
    )
  }

  private func jsonData(_ object: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }

  private func temporaryDirectory() throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString,
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: root,
      withIntermediateDirectories: true
    )
    addTeardownBlock {
      try? FileManager.default.removeItem(at: root)
    }
    return root
  }
}
