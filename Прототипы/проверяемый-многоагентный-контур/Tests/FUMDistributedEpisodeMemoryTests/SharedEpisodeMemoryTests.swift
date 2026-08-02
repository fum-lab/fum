import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class SharedEpisodeMemoryTests: XCTestCase {
  func testSeparateProbeProcessesBootstrapContinueAndReplayCurrent() throws {
    let root = try temporaryDirectory()
    let detachedRoot = try temporaryDirectory()
    let detachedProbe = detachedRoot.appendingPathComponent(
      "FUMWorkPackageProbe",
      isDirectory: false
    )
    try FileManager.default.copyItem(at: probeExecutableURL(), to: detachedProbe)

    let bootstrap = try runProbe(["memory", "bootstrap", root.path])
    let continuation = try runProbe(["memory", "continue", root.path, "primary"])
    let verification = try runProbe([
      "memory", "verify", root.path, "external_passed",
    ])
    let replay = try runProbe(
      ["memory", "show", root.path],
      executableURL: detachedProbe
    )

    XCTAssertEqual(bootstrap.status, 0, String(decoding: bootstrap.error, as: UTF8.self))
    XCTAssertEqual(
      continuation.status,
      0,
      String(decoding: continuation.error, as: UTF8.self)
    )
    XCTAssertEqual(
      verification.status,
      0,
      String(decoding: verification.error, as: UTF8.self)
    )
    XCTAssertEqual(replay.status, 0, String(decoding: replay.error, as: UTF8.self))
    XCTAssertEqual(
      Set([
        bootstrap.processID,
        continuation.processID,
        verification.processID,
        replay.processID,
      ]).count,
      4
    )
    XCTAssertEqual(verification.output, replay.output)
    let canonical = try XCTUnwrap(replay.output.last == 0x0a ? replay.output.dropLast() : nil)
    let generation = try SharedEpisodeGeneration.decodeCanonical(Data(canonical))
    XCTAssertEqual(generation.state.contributions.count, 1)
    XCTAssertEqual(generation.state.verifications.count, 1)
    XCTAssertEqual(generation.state.verificationReport.externalPassedCount, 1)
  }

  func testNewStoreContinuesConfirmedGenerationAndReplaysCanonicalBytes() throws {
    let root = try temporaryDirectory()
    let firstProcess = SharedEpisodeMemoryStore(rootURL: root)
    let foundation = try firstProcess.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )

    let secondProcess = SharedEpisodeMemoryStore(rootURL: root)
    let recovered = try XCTUnwrap(secondProcess.loadCurrent())
    XCTAssertEqual(recovered, foundation)
    let contribution = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: recovered.generationSHA256
    )
    let continued = try secondProcess.commit(
      SharedEpisodeMemoryReducer.continuation(
        from: recovered.generation,
        contribution: contribution
      )
    )

    let thirdProcess = SharedEpisodeMemoryStore(rootURL: root)
    let resumed = try XCTUnwrap(thirdProcess.loadCurrent())
    let decoded = try SharedEpisodeGeneration.decodeCanonical(
      resumed.generation.canonicalJSONData()
    )
    let replayed = try SharedEpisodeMemoryReducer.replay(
      seed: decoded.seed,
      journal: decoded.eventJournal
    )

    XCTAssertEqual(resumed, continued)
    XCTAssertEqual(replayed, resumed.state)
    XCTAssertEqual(try replayed.canonicalJSONData(), try resumed.state.canonicalJSONData())
  }

  func testGenerationRoundTripPreservesContributionProvenanceAndCorrelationReport() throws {
    let seed = try SharedEpisodeMemoryFixtures.seed()
    let foundation = try SharedEpisodeMemoryReducer.foundation(seed: seed)
    let foundationSHA256 = contentSHA256(try foundation.canonicalJSONData())
    let contribution = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: foundationSHA256
    )
    let continued = try SharedEpisodeMemoryReducer.continuation(
      from: foundation,
      contribution: contribution
    )

    let decoded = try SharedEpisodeGeneration.decodeCanonical(
      continued.canonicalJSONData()
    )
    let journalProvenance = try XCTUnwrap(
      decoded.eventJournal.entries.first?.event.contribution?.provenance
    )
    let stateProvenance = try XCTUnwrap(decoded.state.contributions.first?.provenance)

    XCTAssertEqual(journalProvenance, contribution.provenance)
    XCTAssertEqual(stateProvenance, contribution.provenance)
    XCTAssertEqual(journalProvenance.correlationLinks.count, 4)
    XCTAssertEqual(journalProvenance.instrumentObservations.count, 1)
    XCTAssertEqual(
      journalProvenance.derivedFromObservationIDs,
      journalProvenance.instrumentObservations.map(\.observationID)
    )
    XCTAssertEqual(
      decoded.state.provenanceReport.statusesByContributionID[contribution.contributionID],
      .independentByObservedFeatures
    )
    XCTAssertEqual(decoded.state.provenanceReport.independentConfirmationCount, 1)
    XCTAssertFalse(decoded.state.provenanceReport.semanticIndependenceProven)
  }

  func testEarlierGenerationSchemaIsClassifiedAsIncompatible() throws {
    let generation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )
    var root = try jsonObject(data: generation.canonicalJSONData())
    root["schema_version"] = 2

    XCTAssertThrowsError(
      try SharedEpisodeGeneration.decodeCanonical(canonicalJSONObject(root))
    ) { error in
      guard case SharedEpisodeMemoryError.incompatibleGeneration = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testFixtureBindsPassportPackageManifestAndContributionHashes() throws {
    let seed = try SharedEpisodeMemoryFixtures.seed()
    let artifacts = Dictionary(uniqueKeysWithValues: seed.artifacts.map { ($0.artifactID, $0) })
    let passport = try jsonObject(
      data: try XCTUnwrap(artifacts[seed.passportArtifactID]).decodedData()
    )
    let declarations = try XCTUnwrap(passport["artifacts"] as? [[String: Any]])
    let sha256ByID = Dictionary(
      uniqueKeysWithValues: try declarations.map { declaration in
        (
          try XCTUnwrap(declaration["artifact_id"] as? String),
          try XCTUnwrap(declaration["sha256"] as? String)
        )
      }
    )

    for identifier in ["package.primary", "package.adversarial"] {
      let artifact = try XCTUnwrap(artifacts[identifier])
      let body = try jsonObject(data: artifact.decodedData())
      XCTAssertEqual(body["package_id"] as? String, identifier)
      XCTAssertEqual(sha256ByID[identifier], artifact.contentSHA256)
    }
    for identifier in ["manifest.primary", "manifest.adversarial"] {
      let artifact = try XCTUnwrap(artifacts[identifier])
      let body = try jsonObject(data: artifact.decodedData())
      XCTAssertEqual(body["manifest_id"] as? String, identifier)
      XCTAssertEqual(sha256ByID[identifier], artifact.contentSHA256)
    }
    for identifier in ["criteria.main", "verification.main"] {
      let artifact = try XCTUnwrap(artifacts[identifier])
      XCTAssertEqual(sha256ByID[identifier], artifact.contentSHA256)
      XCTAssertNoThrow(try artifact.decodedData())
    }
    let contribution = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: "sha256:" + String(repeating: "a", count: 64)
    )
    XCTAssertEqual(sha256ByID["contribution.primary"], contribution.contentSHA256)
    XCTAssertEqual(sha256ByID["contribution.adversarial"], contribution.contentSHA256)
  }

  func testPassportArtifactHashCannotBeDetachedFromEmbeddedBytes() throws {
    let seed = try SharedEpisodeMemoryFixtures.seed()
    let original = try artifact("package.primary", in: seed)
    var body = try jsonObject(data: original.decodedData())
    body["goal"] = "Другое каноническое тело с тем же строковым происхождением."
    let changed = try canonicalJSONObject(body)
    let detached = try rebuiltSeed(
      seed,
      replacing: original.artifactID,
      with: changed,
      rebindPassportDeclaration: false
    )

    XCTAssertThrowsError(try SharedEpisodeMemoryReducer.foundation(seed: detached)) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testRehashedPackageAndManifestStillRequireExactInternalIdentityAndInputs() throws {
    let seed = try SharedEpisodeMemoryFixtures.seed()
    let packageArtifact = try artifact("package.primary", in: seed)
    var packageBody = try jsonObject(data: packageArtifact.decodedData())
    packageBody["package_id"] = "package.detached"
    let wrongPackage = try rebuiltSeed(
      seed,
      replacing: packageArtifact.artifactID,
      with: canonicalJSONObject(packageBody),
      rebindPassportDeclaration: true
    )
    XCTAssertThrowsError(try SharedEpisodeMemoryReducer.foundation(seed: wrongPackage)) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }

    let manifestArtifact = try artifact("manifest.primary", in: seed)
    var manifestBody = try jsonObject(data: manifestArtifact.decodedData())
    manifestBody["manifest_id"] = "manifest.detached"
    let wrongManifestID = try rebuiltSeed(
      seed,
      replacing: manifestArtifact.artifactID,
      with: canonicalJSONObject(manifestBody),
      rebindPassportDeclaration: true
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.foundation(seed: wrongManifestID)
    ) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }

    manifestBody = try jsonObject(data: manifestArtifact.decodedData())
    var inputs = try XCTUnwrap(manifestBody["inputs"] as? [[String: Any]])
    inputs[0]["sha256"] = "sha256:" + String(repeating: "b", count: 64)
    manifestBody["inputs"] = inputs
    let wrongManifestInput = try rebuiltSeed(
      seed,
      replacing: manifestArtifact.artifactID,
      with: canonicalJSONObject(manifestBody),
      rebindPassportDeclaration: true
    )
    XCTAssertThrowsError(
      try SharedEpisodeMemoryReducer.foundation(seed: wrongManifestInput)
    ) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testTwoContinuationsFromOneParentCloseSecondPublicationWithConflict() throws {
    let root = try temporaryDirectory()
    let firstStore = SharedEpisodeMemoryStore(rootURL: root)
    let parent = try firstStore.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let firstCandidate = try SharedEpisodeMemoryReducer.continuation(
      from: parent.generation,
      contribution: SharedEpisodeMemoryFixtures.contribution(
        named: .primary,
        parentGenerationSHA256: parent.generationSHA256
      )
    )
    let secondCandidate = try SharedEpisodeMemoryReducer.continuation(
      from: parent.generation,
      contribution: SharedEpisodeMemoryFixtures.contribution(
        named: .adversarial,
        parentGenerationSHA256: parent.generationSHA256
      )
    )

    let winner = try firstStore.commit(firstCandidate)
    let secondStore = SharedEpisodeMemoryStore(rootURL: root)
    XCTAssertThrowsError(try secondStore.commit(secondCandidate)) { error in
      guard
        case SharedEpisodeMemoryError.generationConflict(
          expected: parent.generationSHA256,
          actual: winner.generationSHA256
        ) = error
      else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
    XCTAssertEqual(try secondStore.loadCurrent(), winner)
  }

  func testTwoProcessesLinearizeCompetingContinuationsFromOneParent() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let parent = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let candidates = try [
      SharedEpisodeMemoryReducer.continuation(
        from: parent.generation,
        contribution: SharedEpisodeMemoryFixtures.contribution(
          named: .primary,
          parentGenerationSHA256: parent.generationSHA256
        )
      ),
      SharedEpisodeMemoryReducer.continuation(
        from: parent.generation,
        contribution: SharedEpisodeMemoryFixtures.contribution(
          named: .adversarial,
          parentGenerationSHA256: parent.generationSHA256
        )
      ),
    ]
    let candidateURLs = [
      root.appendingPathComponent("candidate-primary.json"),
      root.appendingPathComponent("candidate-adversarial.json"),
    ]
    for (candidate, url) in zip(candidates, candidateURLs) {
      try candidate.canonicalJSONData().write(to: url)
    }
    let barrier = root.appendingPathComponent("cas-barrier", isDirectory: true)
    let resultURLs = [
      root.appendingPathComponent("result-primary.json"),
      root.appendingPathComponent("result-adversarial.json"),
    ]
    let processes = try zip(candidateURLs, resultURLs).enumerated().map { index, pair in
      try makeCASWorkerProcess(
        workerID: "worker-\(index)",
        storeURL: root,
        candidateURL: pair.0,
        resultURL: pair.1,
        barrierURL: barrier
      )
    }
    for process in processes {
      try process.run()
    }
    for (index, process) in processes.enumerated() {
      try waitForProcess(process, label: "CAS worker \(index)")
    }

    let results = try resultURLs.map {
      try JSONDecoder().decode(EpisodeCASWorkerResult.self, from: Data(contentsOf: $0))
    }
    let published = results.filter { $0.status == "published" }
    let conflicted = results.filter { $0.status == "conflict" }
    XCTAssertEqual(published.count, 1, "Ровно один процесс должен опубликовать преемника.")
    XCTAssertEqual(conflicted.count, 1, "Второй процесс должен получить CAS-конфликт.")
    let winnerSHA256 = try XCTUnwrap(published.first?.generationSHA256)
    XCTAssertEqual(conflicted.first?.expectedGenerationSHA256, parent.generationSHA256)
    XCTAssertEqual(conflicted.first?.actualGenerationSHA256, winnerSHA256)
    XCTAssertEqual(try XCTUnwrap(store.loadCurrent()).generationSHA256, winnerSHA256)
  }

  func testInterprocessCASWorker() throws {
    let environment = ProcessInfo.processInfo.environment
    guard let workerID = environment["FUM_SHARED_MEMORY_CAS_WORKER_ID"],
      let storePath = environment["FUM_SHARED_MEMORY_CAS_STORE"],
      let candidatePath = environment["FUM_SHARED_MEMORY_CAS_CANDIDATE"],
      let resultPath = environment["FUM_SHARED_MEMORY_CAS_RESULT"],
      let barrierPath = environment["FUM_SHARED_MEMORY_CAS_BARRIER"]
    else {
      return
    }
    let barrierURL = URL(fileURLWithPath: barrierPath, isDirectory: true)
    try FileManager.default.createDirectory(at: barrierURL, withIntermediateDirectories: true)
    try Data(workerID.utf8).write(
      to: barrierURL.appendingPathComponent("ready-\(workerID)"),
      options: [.atomic]
    )
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(10))
    while clock.now < deadline {
      let ready = try FileManager.default.contentsOfDirectory(
        at: barrierURL,
        includingPropertiesForKeys: nil
      ).filter { $0.lastPathComponent.hasPrefix("ready-") }
      if ready.count == 2 { break }
      Thread.sleep(forTimeInterval: 0.01)
    }
    let ready = try FileManager.default.contentsOfDirectory(
      at: barrierURL,
      includingPropertiesForKeys: nil
    ).filter { $0.lastPathComponent.hasPrefix("ready-") }
    guard ready.count == 2 else {
      throw SharedEpisodeMemoryError.generationStore(
        "Межпроцессный барьер не дождался обоих писателей."
      )
    }

    let candidate = try SharedEpisodeGeneration.decodeCanonical(
      Data(contentsOf: URL(fileURLWithPath: candidatePath))
    )
    let result: EpisodeCASWorkerResult
    do {
      let stored = try SharedEpisodeMemoryStore(
        rootURL: URL(fileURLWithPath: storePath, isDirectory: true)
      ).commit(candidate)
      result = EpisodeCASWorkerResult(
        status: "published",
        generationSHA256: stored.generationSHA256,
        expectedGenerationSHA256: nil,
        actualGenerationSHA256: nil,
        diagnostic: nil
      )
    } catch SharedEpisodeMemoryError.generationConflict(let expected, let actual) {
      result = EpisodeCASWorkerResult(
        status: "conflict",
        generationSHA256: nil,
        expectedGenerationSHA256: expected,
        actualGenerationSHA256: actual,
        diagnostic: nil
      )
    } catch {
      result = EpisodeCASWorkerResult(
        status: "unexpected",
        generationSHA256: nil,
        expectedGenerationSHA256: nil,
        actualGenerationSHA256: nil,
        diagnostic: String(describing: error)
      )
    }
    try JSONEncoder().encode(result).write(
      to: URL(fileURLWithPath: resultPath),
      options: [.atomic]
    )
  }

  func testCorruptedConfirmedGenerationFailsClosed() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let stored = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let generationURL = root.appendingPathComponent("generations").appendingPathComponent(
      "\(stored.generationSHA256.dropFirst(7)).json"
    )
    try Data("{}".utf8).write(to: generationURL)

    XCTAssertThrowsError(try SharedEpisodeMemoryStore(rootURL: root).loadCurrent()) { error in
      guard case SharedEpisodeMemoryError.corruptGeneration = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testDamagedEmbeddedArtifactFailsBeforePublication() throws {
    let seed = try SharedEpisodeMemoryFixtures.seed()
    var artifacts = seed.artifacts
    let original = artifacts[0]
    artifacts[0] = SharedEpisodeEmbeddedArtifact(
      artifactID: original.artifactID,
      kind: original.kind,
      logicalPath: original.logicalPath,
      mediaType: original.mediaType,
      contentBase64: Data("damaged".utf8).base64EncodedString(),
      contentSHA256: original.contentSHA256
    )
    let damaged = SharedEpisodeMemorySeed(
      episodeID: seed.episodeID,
      passportArtifactID: seed.passportArtifactID,
      passportSHA256: seed.passportSHA256,
      artifactManifestSHA256: seed.artifactManifestSHA256,
      artifacts: artifacts
    )

    XCTAssertThrowsError(try SharedEpisodeMemoryReducer.foundation(seed: damaged)) { error in
      guard case SharedEpisodeMemoryError.invalidSeed = error else {
        return XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testIncompletePublicationDoesNotPromoteMissingGeneration() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let confirmed = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let missingHash = "sha256:" + String(repeating: "a", count: 64)
    let pointer = Data(
      "{\"canonical_profile\":\"fum.memory.canonical-json.v1\",\"generation_sha256\":\"\(missingHash)\",\"schema_version\":2}"
        .utf8
    )
    try pointer.write(to: root.appendingPathComponent("CURRENT.json"))

    XCTAssertThrowsError(try SharedEpisodeMemoryStore(rootURL: root).loadCurrent()) { error in
      guard case SharedEpisodeMemoryError.corruptGeneration = error else {
        return XCTFail("Unexpected error after \(confirmed.generationSHA256): \(error)")
      }
    }
  }

  func testExactPublicationRetryIsIdempotent() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let generation = try SharedEpisodeMemoryReducer.foundation(
      seed: SharedEpisodeMemoryFixtures.seed()
    )

    let first = try store.commit(generation)
    let repeated = try SharedEpisodeMemoryStore(rootURL: root).commit(generation)

    XCTAssertEqual(repeated, first)
  }

  func testInvalidContributorParentContentAndProvenanceLeaveCurrentUnchanged() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let parent = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let valid = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: parent.generationSHA256
    )
    let detachedContent = SharedEpisodeContributionContent(
      mediaType: valid.content.mediaType,
      body: "Иное самосогласованное содержание не совпадает с паспортной декларацией."
    )
    let observation = try XCTUnwrap(valid.provenance.instrumentObservations.first)
    let detachedObservation = SharedEpisodeInstrumentObservation(
      observationID: observation.observationID,
      sourceAuthority: observation.sourceAuthority,
      callID: observation.callID,
      inputSHA256: observation.inputSHA256,
      resultSHA256: "sha256:" + String(repeating: "e", count: 64),
      observedAtSeconds: observation.observedAtSeconds
    )
    let detachedObservationProvenance = SharedEpisodeContributionProvenance(
      contributionID: valid.provenance.contributionID,
      executorID: valid.provenance.executorID,
      roleID: valid.provenance.roleID,
      workPackageArtifactID: valid.provenance.workPackageArtifactID,
      modelID: valid.provenance.modelID,
      providerID: valid.provenance.providerID,
      taskSHA256: valid.provenance.taskSHA256,
      localInputSHA256s: valid.provenance.localInputSHA256s,
      parentGenerationSHA256: valid.provenance.parentGenerationSHA256,
      resultSHA256: valid.provenance.resultSHA256,
      correlationLinks: valid.provenance.correlationLinks,
      instrumentObservations: [detachedObservation],
      derivedFromObservationIDs: [detachedObservation.observationID]
    )
    let detachedExecutorProvenance = SharedEpisodeContributionProvenance(
      contributionID: valid.provenance.contributionID,
      executorID: "executor.detached",
      roleID: valid.provenance.roleID,
      workPackageArtifactID: valid.provenance.workPackageArtifactID,
      modelID: valid.provenance.modelID,
      providerID: valid.provenance.providerID,
      taskSHA256: valid.provenance.taskSHA256,
      localInputSHA256s: valid.provenance.localInputSHA256s,
      parentGenerationSHA256: valid.provenance.parentGenerationSHA256,
      resultSHA256: valid.provenance.resultSHA256,
      correlationLinks: valid.provenance.correlationLinks,
      instrumentObservations: valid.provenance.instrumentObservations,
      derivedFromObservationIDs: valid.provenance.derivedFromObservationIDs
    )
    let invalid = [
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: SharedEpisodeContributor(kind: .role, identifier: "producer.detached"),
        contentSHA256: valid.contentSHA256,
        content: valid.content,
        origin: valid.origin,
        provenance: valid.provenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: "sha256:" + String(repeating: "c", count: 64),
        contributor: valid.contributor,
        contentSHA256: valid.contentSHA256,
        content: valid.content,
        origin: valid.origin,
        provenance: valid.provenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: valid.contributor,
        contentSHA256: "sha256:" + String(repeating: "d", count: 64),
        content: valid.content,
        origin: valid.origin,
        provenance: valid.provenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: valid.contributor,
        contentSHA256: contentSHA256(try detachedContent.canonicalJSONData()),
        content: detachedContent,
        origin: valid.origin,
        provenance: valid.provenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: valid.contributor,
        contentSHA256: valid.contentSHA256,
        content: valid.content,
        origin: SharedEpisodeContributionOrigin(
          roleID: valid.origin.roleID,
          workPackageArtifactID: valid.origin.workPackageArtifactID,
          inputManifestArtifactID: "manifest.detached",
          contributionArtifactID: valid.origin.contributionArtifactID,
          hypothesisIDs: valid.origin.hypothesisIDs
        ),
        provenance: valid.provenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: valid.contributor,
        contentSHA256: valid.contentSHA256,
        content: valid.content,
        origin: valid.origin,
        provenance: detachedObservationProvenance
      ),
      SharedEpisodeContribution(
        contributionID: valid.contributionID,
        parentGenerationSHA256: valid.parentGenerationSHA256,
        contributor: valid.contributor,
        contentSHA256: valid.contentSHA256,
        content: valid.content,
        origin: valid.origin,
        provenance: detachedExecutorProvenance
      ),
    ]

    for contribution in invalid {
      XCTAssertThrowsError(
        try SharedEpisodeMemoryReducer.continuation(
          from: parent.generation,
          contribution: contribution
        )
      )
      XCTAssertEqual(try store.loadCurrent(), parent)
    }
  }

  func testMemoryCLIClassifiesSyntaxAndCorruptionFailClosed() throws {
    let empty = try temporaryDirectory()
    let invalidSyntax = try runProbe(["memory", "continue", empty.path, "unknown"])
    XCTAssertEqual(invalidSyntax.status, 2)
    XCTAssertTrue(invalidSyntax.output.isEmpty)
    XCTAssertTrue(
      String(decoding: invalidSyntax.error, as: UTF8.self).contains("Неизвестный вклад"))
    let invalidVerification = try runProbe([
      "memory", "verify", empty.path, "unknown",
    ])
    XCTAssertEqual(invalidVerification.status, 2)
    XCTAssertTrue(invalidVerification.output.isEmpty)
    XCTAssertTrue(
      String(decoding: invalidVerification.error, as: UTF8.self).contains(
        "Неизвестная проверка"
      )
    )

    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let confirmed = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let generationURL = root.appendingPathComponent("generations").appendingPathComponent(
      "\(confirmed.generationSHA256.dropFirst(7)).json"
    )
    try Data("{}".utf8).write(to: generationURL)
    let corrupt = try runProbe(["memory", "show", root.path])
    XCTAssertEqual(corrupt.status, 3)
    XCTAssertTrue(corrupt.output.isEmpty)
    XCTAssertTrue(String(decoding: corrupt.error, as: UTF8.self).contains("отклонила команду"))
  }

  func testInterruptedPreparationAndUnknownFilesArePreserved() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let parent = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let candidate = try SharedEpisodeMemoryReducer.continuation(
      from: parent.generation,
      contribution: SharedEpisodeMemoryFixtures.contribution(
        named: .primary,
        parentGenerationSHA256: parent.generationSHA256
      )
    )
    let candidateData = try candidate.canonicalJSONData()
    let candidateSHA256 = contentSHA256(candidateData)
    let generations = root.appendingPathComponent("generations", isDirectory: true)
    let orphan = generations.appendingPathComponent(
      "\(candidateSHA256.dropFirst(7)).json"
    )
    try candidateData.write(to: orphan)
    let stagedPointer = root.appendingPathComponent(".CURRENT.interrupted.tmp")
    try Data(
      "{\"canonical_profile\":\"fum.memory.canonical-json.v1\",\"generation_sha256\":\"\(candidateSHA256)\",\"schema_version\":2}"
        .utf8
    ).write(to: stagedPointer)
    let unknown = root.appendingPathComponent("owned-by-another-tool.txt")
    try Data("keep".utf8).write(to: unknown)

    let replay = try runProbe(["memory", "show", root.path])
    var expected = try parent.generation.canonicalJSONData()
    expected.append(0x0a)
    XCTAssertEqual(replay.status, 0, String(decoding: replay.error, as: UTF8.self))
    XCTAssertEqual(replay.output, expected)
    XCTAssertEqual(try XCTUnwrap(store.loadCurrent()), parent)

    XCTAssertEqual(try Data(contentsOf: orphan), candidateData)
    XCTAssertTrue(FileManager.default.fileExists(atPath: stagedPointer.path))
    XCTAssertEqual(try Data(contentsOf: unknown), Data("keep".utf8))

    let continued = try runProbe(["memory", "continue", root.path, "primary"])
    XCTAssertEqual(continued.status, 0, String(decoding: continued.error, as: UTF8.self))
    XCTAssertEqual(try XCTUnwrap(store.loadCurrent()).generationSHA256, candidateSHA256)
    XCTAssertTrue(FileManager.default.fileExists(atPath: stagedPointer.path))
    XCTAssertEqual(try Data(contentsOf: unknown), Data("keep".utf8))
  }

  func testEqualContentFromDifferentOriginsRemainsDistinct() throws {
    let root = try temporaryDirectory()
    let store = SharedEpisodeMemoryStore(rootURL: root)
    let foundation = try store.commit(
      SharedEpisodeMemoryReducer.foundation(seed: try SharedEpisodeMemoryFixtures.seed())
    )
    let primary = try SharedEpisodeMemoryFixtures.contribution(
      named: .primary,
      parentGenerationSHA256: foundation.generationSHA256
    )
    let afterPrimary = try store.commit(
      SharedEpisodeMemoryReducer.continuation(
        from: foundation.generation,
        contribution: primary
      )
    )
    let adversarial = try SharedEpisodeMemoryFixtures.contribution(
      named: .adversarial,
      parentGenerationSHA256: afterPrimary.generationSHA256
    )
    let afterAdversarial = try store.commit(
      SharedEpisodeMemoryReducer.continuation(
        from: afterPrimary.generation,
        contribution: adversarial
      )
    )

    XCTAssertEqual(primary.contentSHA256, adversarial.contentSHA256)
    XCTAssertEqual(afterAdversarial.state.contributions.count, 2)
    XCTAssertNotEqual(
      afterAdversarial.state.contributions[0].contributor,
      afterAdversarial.state.contributions[1].contributor
    )
    XCTAssertNotEqual(
      afterAdversarial.state.contributions[0].origin,
      afterAdversarial.state.contributions[1].origin
    )
    XCTAssertEqual(
      afterAdversarial.state.provenanceReport.statusesByContributionID[primary.contributionID],
      .correlated
    )
    XCTAssertEqual(
      afterAdversarial.state.provenanceReport.statusesByContributionID[
        adversarial.contributionID
      ],
      .correlated
    )
    XCTAssertEqual(afterAdversarial.state.provenanceReport.independentConfirmationCount, 1)
    XCTAssertFalse(afterAdversarial.state.provenanceReport.semanticIndependenceProven)
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-shared-episode-memory-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    addTeardownBlock {
      try? FileManager.default.removeItem(at: url)
    }
    return url
  }

  private func artifact(
    _ identifier: String,
    in seed: SharedEpisodeMemorySeed
  ) throws -> SharedEpisodeEmbeddedArtifact {
    try XCTUnwrap(seed.artifacts.first { $0.artifactID == identifier })
  }

  private func jsonObject(data: Data) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private func canonicalJSONObject(_ value: [String: Any]) throws -> Data {
    try JSONSerialization.data(
      withJSONObject: value,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }

  private func rebuiltSeed(
    _ seed: SharedEpisodeMemorySeed,
    replacing artifactID: String,
    with data: Data,
    rebindPassportDeclaration: Bool
  ) throws -> SharedEpisodeMemorySeed {
    let original = try artifact(artifactID, in: seed)
    var artifacts = seed.artifacts.filter { $0.artifactID != artifactID }
    let replacement = SharedEpisodeEmbeddedArtifact(
      artifactID: original.artifactID,
      kind: original.kind,
      logicalPath: original.logicalPath,
      mediaType: original.mediaType,
      data: data
    )
    artifacts.append(replacement)

    if rebindPassportDeclaration {
      let originalPassport = try artifact(seed.passportArtifactID, in: seed)
      var passport = try jsonObject(data: originalPassport.decodedData())
      var declarations = try XCTUnwrap(passport["artifacts"] as? [[String: Any]])
      let index = try XCTUnwrap(
        declarations.firstIndex { $0["artifact_id"] as? String == artifactID }
      )
      declarations[index]["sha256"] = replacement.contentSHA256
      passport["artifacts"] = declarations
      let reboundPassport = SharedEpisodeEmbeddedArtifact(
        artifactID: originalPassport.artifactID,
        kind: originalPassport.kind,
        logicalPath: originalPassport.logicalPath,
        mediaType: originalPassport.mediaType,
        data: try canonicalJSONObject(passport)
      )
      artifacts.removeAll { $0.artifactID == originalPassport.artifactID }
      artifacts.append(reboundPassport)
    }

    artifacts.sort { $0.artifactID < $1.artifactID }
    let passport = try XCTUnwrap(
      artifacts.first { $0.artifactID == seed.passportArtifactID }
    )
    let manifest = SharedEpisodeArtifactManifest(schemaVersion: 1, artifacts: artifacts)
    return SharedEpisodeMemorySeed(
      episodeID: seed.episodeID,
      passportArtifactID: passport.artifactID,
      passportSHA256: passport.contentSHA256,
      artifactManifestSHA256: contentSHA256(try manifest.canonicalJSONData()),
      artifacts: artifacts
    )
  }

  private func contentSHA256(_ data: Data) -> String {
    SharedEpisodeEmbeddedArtifact(
      artifactID: "hash.fixture",
      kind: "hash",
      logicalPath: "hash.fixture",
      mediaType: "application/octet-stream",
      data: data
    ).contentSHA256
  }

  private func probeExecutableURL() -> URL {
    Bundle(for: SharedEpisodeMemoryTests.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("FUMWorkPackageProbe", isDirectory: false)
  }

  private func runProbe(
    _ arguments: [String],
    executableURL: URL? = nil
  ) throws -> ProbeResult {
    let executable = executableURL ?? probeExecutableURL()
    XCTAssertTrue(FileManager.default.isExecutableFile(atPath: executable.path))

    let capture = try temporaryDirectory()
    let outputURL = capture.appendingPathComponent("stdout")
    let errorURL = capture.appendingPathComponent("stderr")
    XCTAssertTrue(FileManager.default.createFile(atPath: outputURL.path, contents: nil))
    XCTAssertTrue(FileManager.default.createFile(atPath: errorURL.path, contents: nil))
    let outputHandle = try FileHandle(forWritingTo: outputURL)
    let errorHandle = try FileHandle(forWritingTo: errorURL)
    defer {
      try? outputHandle.close()
      try? errorHandle.close()
    }

    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    process.standardOutput = outputHandle
    process.standardError = errorHandle
    try process.run()
    let processID = process.processIdentifier
    process.waitUntilExit()
    try outputHandle.close()
    try errorHandle.close()
    return ProbeResult(
      processID: processID,
      status: process.terminationStatus,
      output: try Data(contentsOf: outputURL),
      error: try Data(contentsOf: errorURL)
    )
  }

  private func makeCASWorkerProcess(
    workerID: String,
    storeURL: URL,
    candidateURL: URL,
    resultURL: URL,
    barrierURL: URL
  ) throws -> Process {
    let process = Process()
    process.executableURL = try executableURL(named: "xcrun")
    process.arguments = [
      "xctest",
      "-XCTest",
      "SharedEpisodeMemoryTests/testInterprocessCASWorker",
      Bundle(for: SharedEpisodeMemoryTests.self).bundleURL.path,
    ]
    var environment = ProcessInfo.processInfo.environment
    environment["FUM_SHARED_MEMORY_CAS_WORKER_ID"] = workerID
    environment["FUM_SHARED_MEMORY_CAS_STORE"] = storeURL.path
    environment["FUM_SHARED_MEMORY_CAS_CANDIDATE"] = candidateURL.path
    environment["FUM_SHARED_MEMORY_CAS_RESULT"] = resultURL.path
    environment["FUM_SHARED_MEMORY_CAS_BARRIER"] = barrierURL.path
    process.environment = environment
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    return process
  }

  private func executableURL(named name: String) throws -> URL {
    let pathEntries = ProcessInfo.processInfo.environment["PATH"]?.split(separator: ":") ?? []
    for pathEntry in pathEntries {
      let directory = String(pathEntry)
      guard directory.hasPrefix("/") else { continue }
      let candidate = URL(fileURLWithPath: directory, isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    throw SharedEpisodeMemoryError.generationStore(
      "Исполняемый файл \(name) не найден в абсолютных каталогах PATH."
    )
  }

  private func waitForProcess(
    _ process: Process,
    label: String,
    timeout: Duration = .seconds(30)
  ) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while process.isRunning, clock.now < deadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    if process.isRunning {
      process.terminate()
      throw SharedEpisodeMemoryError.generationStore(
        "Процесс \(label) не завершился до предельного срока."
      )
    }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw SharedEpisodeMemoryError.generationStore(
        "Процесс \(label) завершился с кодом \(process.terminationStatus)."
      )
    }
  }
}

private struct ProbeResult {
  let processID: Int32
  let status: Int32
  let output: Data
  let error: Data
}

private struct EpisodeCASWorkerResult: Codable {
  let status: String
  let generationSHA256: String?
  let expectedGenerationSHA256: String?
  let actualGenerationSHA256: String?
  let diagnostic: String?
}
