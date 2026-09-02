import Darwin
import Foundation
import XCTest

@testable import FUMReproducibleMemoryPopulation

final class MemoryPopulationTests: XCTestCase {
  private struct CASWorkerResult: Codable {
    let status: String
    let generationSHA256: String?
    let expectedGenerationSHA256: String?
    let actualGenerationSHA256: String?
    let diagnostic: String?

    enum CodingKeys: String, CodingKey {
      case status
      case generationSHA256 = "generation_sha256"
      case expectedGenerationSHA256 = "expected_generation_sha256"
      case actualGenerationSHA256 = "actual_generation_sha256"
      case diagnostic
    }
  }

  func testBundledBootstrapIsByteIdenticalAcrossRepeatedRuns() throws {
    let input = try MemoryPopulationFixtures.loadBootstrapV1()
    let engine = MemoryPopulationEngine()

    let first = try CanonicalMemoryJSON.encode(engine.run(input))
    let second = try CanonicalMemoryJSON.encode(engine.run(input))

    XCTAssertEqual(first, second)
    XCTAssertFalse(first.isEmpty)
    XCTAssertEqual(first.last, UInt8(ascii: "}"))
  }

  func testSemanticInputChangeChangesSnapshotAndOutput() throws {
    let firstInput = try MemoryPopulationFixtures.loadBootstrapV1()
    let source = String(decoding: firstInput, as: UTF8.self)
    let changedSource = source.replacingOccurrences(
      of: "без графического интерфейса",
      with: "с графическим интерфейсом"
    )
    XCTAssertNotEqual(source, changedSource)

    let engine = MemoryPopulationEngine()
    let first = try engine.run(firstInput)
    let changed = try engine.run(Data(changedSource.utf8))

    XCTAssertNotEqual(first.inputSHA256, changed.inputSHA256)
    XCTAssertNotEqual(first.snapshotSHA256, changed.snapshotSHA256)
    XCTAssertNotEqual(
      try CanonicalMemoryJSON.encode(first),
      try CanonicalMemoryJSON.encode(changed)
    )
  }

  func testRememberAndComposeBuildCanonicalMemoryWithProvenance() throws {
    let artifact = try MemoryPopulationEngine().run(programData())

    XCTAssertEqual(artifact.snapshot.records.map(\.key), ["goal", "interface", "summary"])
    XCTAssertEqual(artifact.trace.entries.count, 3)

    let summary = try XCTUnwrap(
      artifact.snapshot.records.first(where: { $0.key == "summary" })
    )
    XCTAssertEqual(summary.value, "минимальный прототип | без GUI")
    XCTAssertEqual(
      summary.provenance.contributingEventIDs,
      ["event.goal", "event.interface", "event.summary"]
    )
    XCTAssertEqual(summary.provenance.producedByEventID, "event.summary")
    XCTAssertEqual(summary.provenance.executor, "fum.memory.interpreter.v1")

    let finalStep = try XCTUnwrap(artifact.trace.entries.last)
    XCTAssertEqual(finalStep.eventID, "event.summary")
    XCTAssertEqual(finalStep.operation, .compose)
    XCTAssertEqual(finalStep.reads, ["goal", "interface"])
    XCTAssertEqual(finalStep.writes, ["summary"])
    XCTAssertTrue(finalStep.sourceEventSHA256.hasPrefix("sha256:"))
    XCTAssertTrue(finalStep.outputRecordSHA256.hasPrefix("sha256:"))

    let output = String(decoding: try CanonicalMemoryJSON.encode(artifact), as: UTF8.self)
    XCTAssertFalse(output.contains("timestamp"))
    XCTAssertFalse(output.contains("hostname"))
  }

  func testGUIProjectionPrerequisitesReportOnlyObservedMarkersAndRemainHeadless() throws {
    let incomplete = try MemoryPopulationEngine().run(programData())

    XCTAssertTrue(incomplete.guiProjectionPrerequisites.headless)
    XCTAssertEqual(incomplete.guiProjectionPrerequisites.status, .markersMissing)
    XCTAssertEqual(
      incomplete.guiProjectionPrerequisites.observedMarkers,
      ["reproducible-memory", "bounded-internal-execution"]
    )
    XCTAssertEqual(
      incomplete.guiProjectionPrerequisites.missingMarkers,
      ["gui-projection-specification"]
    )

    let allMarkers = try MemoryPopulationEngine().run(
      programWithGUIProjectionSpecification()
    )

    XCTAssertTrue(allMarkers.guiProjectionPrerequisites.headless)
    XCTAssertEqual(allMarkers.guiProjectionPrerequisites.status, .markersPresent)
    XCTAssertTrue(allMarkers.guiProjectionPrerequisites.missingMarkers.isEmpty)
    XCTAssertEqual(
      allMarkers.guiProjectionPrerequisites.observedMarkers,
      allMarkers.guiProjectionPrerequisites.requiredMarkers
    )
  }

  func testFullReplayAndConfirmedContinuationConverge() throws {
    let engine = MemoryPopulationEngine()
    let full = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapV1()
    )
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }

    let store = MemoryGenerationStore(rootURL: storeURL)
    let confirmedBase = try store.commit(base)
    let restoredBase = try XCTUnwrap(store.loadCurrent())
    XCTAssertEqual(restoredBase, confirmedBase)

    let continuationInput = try MemoryPopulationFixtures.loadBootstrapContinuationV1()
    let continued = try engine.generation(
      from: continuationInput,
      continuingFrom: restoredBase
    )
    let confirmedContinuation = try store.commit(continued)
    let restoredContinuation = try XCTUnwrap(store.loadCurrent())

    XCTAssertEqual(restoredContinuation, confirmedContinuation)
    XCTAssertEqual(continued.previousGenerationSHA256, confirmedBase.generationSHA256)
    XCTAssertEqual(continued.schemaVersion, MemoryGeneration.currentSchemaVersion)
    XCTAssertEqual(continued.canonicalProfile, CanonicalMemoryJSON.profileID)
    XCTAssertEqual(continued.policyVersion, MemoryPopulationPolicy.version)
    XCTAssertNotEqual(continued.inputSHA256, full.inputSHA256)
    XCTAssertEqual(continued.snapshot, full.snapshot)
    XCTAssertEqual(continued.trace, full.trace)
    XCTAssertEqual(continued.viewModel, full.viewModel)
    XCTAssertEqual(continued.snapshotSHA256, full.snapshotSHA256)
    XCTAssertEqual(continued.traceSHA256, full.traceSHA256)
    XCTAssertEqual(continued.viewModelSHA256, full.viewModelSHA256)
    XCTAssertEqual(
      continued.provenance.acceptedEventIDs,
      full.provenance.acceptedEventIDs
    )
  }

  func testGenerationContainsCanonicalAcceptedEventsAndReplaysWithoutExternalInput() throws {
    let engine = MemoryPopulationEngine()
    let generation = try engine.generation(from: programData())

    XCTAssertEqual(generation.schemaVersion, MemoryGeneration.currentSchemaVersion)
    XCTAssertEqual(generation.canonicalProfile, CanonicalMemoryJSON.profileID)
    XCTAssertEqual(generation.seed.schemaVersion, 1)
    XCTAssertEqual(generation.seed.kind, .empty)
    XCTAssertEqual(generation.seed.datasetID, generation.snapshot.datasetID)
    XCTAssertEqual(generation.seed.policyVersion, generation.policyVersion)
    XCTAssertEqual(
      generation.eventJournal.events.map(\.id),
      generation.trace.entries.map(\.eventID)
    )
    XCTAssertEqual(
      generation.seedSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(generation.seed))
    )
    XCTAssertEqual(
      generation.eventJournalSHA256,
      CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(generation.eventJournal)
      )
    )
    XCTAssertEqual(
      generation.inputSHA256,
      generation.eventJournalSHA256
    )
    for (event, entry) in zip(
      generation.eventJournal.events,
      generation.trace.entries
    ) {
      XCTAssertEqual(
        entry.sourceEventSHA256,
        CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(event))
      )
    }

    let generationBytes = try CanonicalMemoryJSON.encode(generation)
    let restored = try JSONDecoder().decode(MemoryGeneration.self, from: generationBytes)
    XCTAssertEqual(try CanonicalMemoryJSON.encode(restored), generationBytes)

    let replayed = try engine.replay(restored)
    XCTAssertEqual(replayed.inputSHA256, restored.inputSHA256)
    XCTAssertEqual(replayed.snapshot, restored.snapshot)
    XCTAssertEqual(replayed.trace, restored.trace)
    XCTAssertEqual(replayed.viewModel, restored.viewModel)
    XCTAssertEqual(replayed.snapshotSHA256, restored.snapshotSHA256)
    XCTAssertEqual(replayed.traceSHA256, restored.traceSHA256)
    XCTAssertEqual(replayed.viewModelSHA256, restored.viewModelSHA256)
  }

  func testContinuationGenerationCarriesACompleteSelfContainedJournal() throws {
    let engine = MemoryPopulationEngine()
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let storedBase = StoredMemoryGeneration(
      generationSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(base)
      ),
      generation: base
    )
    let continuation = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: storedBase
    )

    let detachedBytes = try CanonicalMemoryJSON.encode(continuation)
    let detached = try JSONDecoder().decode(MemoryGeneration.self, from: detachedBytes)
    XCTAssertEqual(detached.eventJournal.events.count, 6)
    XCTAssertEqual(
      detached.provenance.inputEventIDs,
      detached.eventJournal.events.suffix(2).map(\.id)
    )
    XCTAssertEqual(
      detached.provenance.acceptedEventIDs,
      detached.eventJournal.events.map(\.id)
    )
    let detachedInput = MemoryPopulationProgram(
      schemaVersion: detached.eventJournal.schemaVersion,
      policyVersion: detached.eventJournal.policyVersion,
      datasetID: detached.eventJournal.datasetID,
      events: Array(detached.eventJournal.events.suffix(2))
    )
    XCTAssertEqual(
      detached.inputSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(detachedInput))
    )

    let replayed = try engine.replay(detached)
    XCTAssertEqual(replayed.inputSHA256, detached.inputSHA256)
    XCTAssertEqual(replayed.snapshot, detached.snapshot)
    XCTAssertEqual(replayed.trace, detached.trace)
    XCTAssertEqual(replayed.viewModel, detached.viewModel)
  }

  func testReplayRejectsInternallyHashedButNonDerivableComposeEvent() throws {
    let engine = MemoryPopulationEngine()
    let honest = try engine.generation(from: programData())
    var forgedEvents = honest.eventJournal.events
    let compose = try XCTUnwrap(forgedEvents.popLast())
    let forgedCompose = MemoryInputEvent(
      id: compose.id,
      sequence: compose.sequence,
      operation: compose.operation,
      target: compose.target,
      sources: compose.sources,
      separator: " => "
    )
    forgedEvents.append(forgedCompose)
    let forgedJournal = MemoryPopulationProgram(
      schemaVersion: honest.eventJournal.schemaVersion,
      policyVersion: honest.eventJournal.policyVersion,
      datasetID: honest.eventJournal.datasetID,
      events: forgedEvents
    )
    let forgedJournalData = try CanonicalMemoryJSON.encode(forgedJournal)

    var forgedEntries = honest.trace.entries
    let composeEntry = try XCTUnwrap(forgedEntries.popLast())
    forgedEntries.append(
      MemoryTraceEntry(
        ordinal: composeEntry.ordinal,
        eventID: composeEntry.eventID,
        operation: composeEntry.operation,
        reads: composeEntry.reads,
        writes: composeEntry.writes,
        sourceEventSHA256: CanonicalMemoryJSON.sha256(
          try CanonicalMemoryJSON.encode(forgedCompose)
        ),
        outputRecordSHA256: composeEntry.outputRecordSHA256
      )
    )
    let forgedTrace = MemoryExecutionTrace(
      schemaVersion: honest.trace.schemaVersion,
      datasetID: honest.trace.datasetID,
      entries: forgedEntries
    )
    let forged = MemoryGeneration(
      schemaVersion: honest.schemaVersion,
      policyVersion: honest.policyVersion,
      previousGenerationSHA256: honest.previousGenerationSHA256,
      inputSHA256: CanonicalMemoryJSON.sha256(forgedJournalData),
      seedSHA256: honest.seedSHA256,
      eventJournalSHA256: CanonicalMemoryJSON.sha256(forgedJournalData),
      snapshotSHA256: honest.snapshotSHA256,
      traceSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(forgedTrace)
      ),
      viewModelSHA256: honest.viewModelSHA256,
      seed: honest.seed,
      eventJournal: forgedJournal,
      snapshot: honest.snapshot,
      trace: forgedTrace,
      viewModel: honest.viewModel,
      provenance: honest.provenance
    )

    XCTAssertEqual(
      forged.eventJournalSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(forged.eventJournal))
    )
    XCTAssertEqual(
      forged.snapshotSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(forged.snapshot))
    )
    XCTAssertEqual(
      forged.traceSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(forged.trace))
    )
    XCTAssertEqual(
      forged.viewModelSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(forged.viewModel))
    )

    XCTAssertThrowsError(try engine.replay(forged)) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration(
          "Поколение не выводится из канонического журнала событий."
        )
      )
    }
  }

  func testReplayRejectsInternallyHashedButNonDerivableRememberEvent() throws {
    let engine = MemoryPopulationEngine()
    let honestProgram = MemoryPopulationProgram(
      schemaVersion: MemoryPopulationPolicy.schemaVersion,
      policyVersion: MemoryPopulationPolicy.version,
      datasetID: "forged-remember-v1",
      events: [
        MemoryInputEvent(
          id: "event.note",
          sequence: 1,
          operation: .remember,
          target: "note",
          value: "честное значение"
        )
      ]
    )
    let honest = try engine.generation(
      from: CanonicalMemoryJSON.encode(honestProgram)
    )
    let forgedEvent = MemoryInputEvent(
      id: "event.note",
      sequence: 1,
      operation: .remember,
      target: "note",
      value: "подменённое значение"
    )
    let forgedJournal = MemoryPopulationProgram(
      schemaVersion: honest.eventJournal.schemaVersion,
      policyVersion: honest.eventJournal.policyVersion,
      datasetID: honest.eventJournal.datasetID,
      events: [forgedEvent]
    )
    let forgedJournalData = try CanonicalMemoryJSON.encode(forgedJournal)
    let honestEntry = try XCTUnwrap(honest.trace.entries.only)
    let forgedTrace = MemoryExecutionTrace(
      schemaVersion: honest.trace.schemaVersion,
      datasetID: honest.trace.datasetID,
      entries: [
        MemoryTraceEntry(
          ordinal: honestEntry.ordinal,
          eventID: honestEntry.eventID,
          operation: honestEntry.operation,
          reads: honestEntry.reads,
          writes: honestEntry.writes,
          sourceEventSHA256: CanonicalMemoryJSON.sha256(
            try CanonicalMemoryJSON.encode(forgedEvent)
          ),
          outputRecordSHA256: honestEntry.outputRecordSHA256
        )
      ]
    )
    let forged = MemoryGeneration(
      schemaVersion: honest.schemaVersion,
      policyVersion: honest.policyVersion,
      previousGenerationSHA256: nil,
      inputSHA256: CanonicalMemoryJSON.sha256(forgedJournalData),
      seedSHA256: honest.seedSHA256,
      eventJournalSHA256: CanonicalMemoryJSON.sha256(forgedJournalData),
      snapshotSHA256: honest.snapshotSHA256,
      traceSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(forgedTrace)
      ),
      viewModelSHA256: honest.viewModelSHA256,
      seed: honest.seed,
      eventJournal: forgedJournal,
      snapshot: honest.snapshot,
      trace: forgedTrace,
      viewModel: honest.viewModel,
      provenance: honest.provenance
    )

    XCTAssertThrowsError(try engine.replay(forged)) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration(
          "Поколение не выводится из канонического журнала событий."
        )
      )
    }
  }

  func testReplayRejectsInputHashThatIsNotBoundToTheJournalSuffix() throws {
    let honest = try MemoryPopulationEngine().generation(from: programData())
    let forged = MemoryGeneration(
      schemaVersion: honest.schemaVersion,
      policyVersion: honest.policyVersion,
      previousGenerationSHA256: honest.previousGenerationSHA256,
      inputSHA256: "sha256:" + String(repeating: "0", count: 64),
      seedSHA256: honest.seedSHA256,
      eventJournalSHA256: honest.eventJournalSHA256,
      snapshotSHA256: honest.snapshotSHA256,
      traceSHA256: honest.traceSHA256,
      viewModelSHA256: honest.viewModelSHA256,
      seed: honest.seed,
      eventJournal: honest.eventJournal,
      snapshot: honest.snapshot,
      trace: honest.trace,
      viewModel: honest.viewModel,
      provenance: honest.provenance
    )

    XCTAssertThrowsError(try MemoryPopulationEngine().replay(forged)) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration(
          "Хэш текущего канонического входа не выводится из журнала событий."
        )
      )
    }
  }

  func testCumulativeJournalCanReplayBeyondSingleExternalInputLimit() throws {
    let engine = MemoryPopulationEngine()
    let value = String(repeating: "x", count: MemoryPopulationPolicy.maximumValueBytes)
    let events = (1...80).map { index in
      MemoryInputEvent(
        id: "event.large.\(index)",
        sequence: index,
        operation: .remember,
        target: "large.\(index)",
        value: value
      )
    }
    let baseProgram = MemoryPopulationProgram(
      schemaVersion: MemoryPopulationPolicy.schemaVersion,
      policyVersion: MemoryPopulationPolicy.version,
      datasetID: "large-journal-v1",
      events: Array(events.prefix(40))
    )
    let continuationProgram = MemoryPopulationProgram(
      schemaVersion: MemoryPopulationPolicy.schemaVersion,
      policyVersion: MemoryPopulationPolicy.version,
      datasetID: "large-journal-v1",
      events: Array(events.suffix(40))
    )
    let baseInput = try CanonicalMemoryJSON.encode(baseProgram)
    let continuationInput = try CanonicalMemoryJSON.encode(continuationProgram)
    XCTAssertLessThan(baseInput.count, MemoryPopulationEngine.maximumInputBytes)
    XCTAssertLessThan(continuationInput.count, MemoryPopulationEngine.maximumInputBytes)

    let base = try engine.generation(from: baseInput)
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let store = MemoryGenerationStore(rootURL: storeURL)
    let storedBase = try store.commit(base)
    let continuation = try engine.generation(
      from: continuationInput,
      continuingFrom: storedBase
    )
    XCTAssertGreaterThan(
      try CanonicalMemoryJSON.encode(continuation.eventJournal).count,
      MemoryPopulationEngine.maximumInputBytes
    )

    let storedContinuation = try store.commit(continuation)
    let restored = try XCTUnwrap(store.loadCurrent())
    XCTAssertEqual(restored, storedContinuation)

    let replayed = try engine.replay(restored.generation)
    XCTAssertEqual(replayed.snapshot, restored.generation.snapshot)
    XCTAssertEqual(replayed.trace, restored.generation.trace)
    XCTAssertEqual(replayed.viewModel, restored.generation.viewModel)
  }

  func testLegacyV1GenerationIsRejectedExplicitlyWithoutRewritingBytes() throws {
    let legacyData = try legacyGenerationV1Data()
    let legacySHA256 =
      "sha256:b1a15c6025848f0f8b610c0dbd160b956c5255776ddef11e36894d504ee4b547"
    XCTAssertEqual(legacyData.count, 5_288)
    XCTAssertEqual(CanonicalMemoryJSON.sha256(legacyData), legacySHA256)
    let pointerData = Data(
      "{\"canonical_profile\":\"\(CanonicalMemoryJSON.profileID)\",\"generation_sha256\":\"\(legacySHA256)\",\"schema_version\":2}"
        .utf8
    )
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let generationsURL = storeURL.appendingPathComponent(
      "generations",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: generationsURL,
      withIntermediateDirectories: true
    )
    let generationURL = generationsURL.appendingPathComponent(
      "\(legacySHA256.dropFirst(7)).json",
      isDirectory: false
    )
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    try legacyData.write(to: generationURL)
    try pointerData.write(to: pointerURL)

    XCTAssertThrowsError(try MemoryGenerationStore(rootURL: storeURL).loadCurrent()) {
      error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .incompatibleGeneration(
          "Поколение схемы 1 не содержит канонического журнала событий; самодостаточное воспроизведение невозможно."
        )
      )
    }
    XCTAssertEqual(try Data(contentsOf: generationURL), legacyData)
    XCTAssertEqual(try Data(contentsOf: pointerURL), pointerData)
  }

  func testLegacyV1PointerIsRejectedExplicitlyWithoutRewritingBytes() throws {
    let zeroSHA256 = "sha256:" + String(repeating: "0", count: 64)
    let legacyPointer = Data(
      "{\"generation_sha256\":\"\(zeroSHA256)\",\"schema_version\":1}".utf8
    )
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(legacyPointer))
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    try legacyPointer.write(to: pointerURL)

    XCTAssertThrowsError(try MemoryGenerationStore(rootURL: storeURL).loadCurrent()) {
      error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .incompatibleGeneration(
          "Указатель CURRENT схемы 1 не закрепляет языконейтральный профиль канонических байтов."
        )
      )
    }
    XCTAssertEqual(try Data(contentsOf: pointerURL), legacyPointer)
  }

  func testLegacyV2GenerationIsRejectedExplicitlyWithoutRewritingBytes() throws {
    let generation = try MemoryPopulationEngine().generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let currentText = String(
      decoding: try CanonicalMemoryJSON.encode(generation),
      as: UTF8.self
    )
    let profilePrefix =
      "{\"canonical_profile\":\"\(CanonicalMemoryJSON.profileID)\","
    XCTAssertTrue(currentText.hasPrefix(profilePrefix))
    XCTAssertEqual(currentText.components(separatedBy: "\"schema_version\":3").count, 2)
    let legacyText =
      ("{" + currentText.dropFirst(profilePrefix.count))
      .replacingOccurrences(of: "\"schema_version\":3", with: "\"schema_version\":2")
    let legacyData = Data(legacyText.utf8)
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(legacyData))
    let legacySHA256 = CanonicalMemoryJSON.sha256(legacyData)
    let pointerData = Data(
      "{\"canonical_profile\":\"\(CanonicalMemoryJSON.profileID)\",\"generation_sha256\":\"\(legacySHA256)\",\"schema_version\":2}"
        .utf8
    )
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let generationsURL = storeURL.appendingPathComponent("generations", isDirectory: true)
    try FileManager.default.createDirectory(
      at: generationsURL,
      withIntermediateDirectories: true
    )
    let generationURL = generationURL(for: legacySHA256, storeURL: storeURL)
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    try legacyData.write(to: generationURL)
    try pointerData.write(to: pointerURL)

    XCTAssertThrowsError(try MemoryGenerationStore(rootURL: storeURL).loadCurrent()) {
      error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .incompatibleGeneration(
          "Поколение схемы 2 не закрепляет языконейтральный профиль канонических байтов."
        )
      )
    }
    XCTAssertEqual(try Data(contentsOf: generationURL), legacyData)
    XCTAssertEqual(try Data(contentsOf: pointerURL), pointerData)
  }

  func testStoreRejectsCanonicalBytesWithFieldsOutsideTheExactSchema() throws {
    let engine = MemoryPopulationEngine()
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let store = MemoryGenerationStore(rootURL: storeURL)
    let generation = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let stored = try store.commit(generation)
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json", isDirectory: false)

    let pointerWithUnknownField = Data(
      "{\"canonical_profile\":\"\(CanonicalMemoryJSON.profileID)\",\"extra\":true,\"generation_sha256\":\"\(stored.generationSHA256)\",\"schema_version\":2}"
        .utf8
    )
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(pointerWithUnknownField))
    try pointerWithUnknownField.write(to: pointerURL)
    XCTAssertThrowsError(try store.loadCurrent()) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration("Указатель CURRENT не соответствует схеме.")
      )
    }

    let canonicalGeneration = try CanonicalMemoryJSON.encode(generation)
    var generationWithUnknownField = Data("{\"aaa\":true,".utf8)
    generationWithUnknownField.append(contentsOf: canonicalGeneration.dropFirst())
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(generationWithUnknownField))
    let mutatedSHA256 = CanonicalMemoryJSON.sha256(generationWithUnknownField)
    try generationWithUnknownField.write(
      to: generationURL(for: mutatedSHA256, storeURL: storeURL)
    )
    let pointerToMutatedGeneration = Data(
      "{\"canonical_profile\":\"\(CanonicalMemoryJSON.profileID)\",\"generation_sha256\":\"\(mutatedSHA256)\",\"schema_version\":2}"
        .utf8
    )
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(pointerToMutatedGeneration))
    try pointerToMutatedGeneration.write(to: pointerURL)
    XCTAssertThrowsError(try store.loadCurrent()) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration("Файл поколения не соответствует схеме.")
      )
    }
  }

  func testInterruptedOrInvalidContinuationKeepsLastConfirmedGeneration() throws {
    enum InjectedFailure: Error {
      case beforePointerCommit
    }

    let engine = MemoryPopulationEngine()
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)
    let continuation = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )

    let invalid = MemoryGeneration(
      schemaVersion: continuation.schemaVersion,
      policyVersion: continuation.policyVersion,
      previousGenerationSHA256: continuation.previousGenerationSHA256,
      inputSHA256: continuation.inputSHA256,
      seedSHA256: continuation.seedSHA256,
      eventJournalSHA256: continuation.eventJournalSHA256,
      snapshotSHA256: "sha256:" + String(repeating: "0", count: 64),
      traceSHA256: continuation.traceSHA256,
      viewModelSHA256: continuation.viewModelSHA256,
      seed: continuation.seed,
      eventJournal: continuation.eventJournal,
      snapshot: continuation.snapshot,
      trace: continuation.trace,
      viewModel: continuation.viewModel,
      provenance: continuation.provenance
    )
    XCTAssertThrowsError(try store.commit(invalid)) { error in
      guard case MemoryPopulationError.corruptGeneration = error else {
        return XCTFail("Ожидалась ошибка целостности поколения, получено: \(error)")
      }
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)

    let incompatibleContinuation = MemoryGeneration(
      schemaVersion: continuation.schemaVersion,
      policyVersion: "fum.memory.policy.v999",
      previousGenerationSHA256: continuation.previousGenerationSHA256,
      inputSHA256: continuation.inputSHA256,
      seedSHA256: continuation.seedSHA256,
      eventJournalSHA256: continuation.eventJournalSHA256,
      snapshotSHA256: continuation.snapshotSHA256,
      traceSHA256: continuation.traceSHA256,
      viewModelSHA256: continuation.viewModelSHA256,
      seed: continuation.seed,
      eventJournal: continuation.eventJournal,
      snapshot: continuation.snapshot,
      trace: continuation.trace,
      viewModel: continuation.viewModel,
      provenance: continuation.provenance
    )
    XCTAssertThrowsError(try store.commit(incompatibleContinuation)) { error in
      guard case MemoryPopulationError.incompatibleGeneration = error else {
        return XCTFail("Ожидалась несовместимость поколения, получено: \(error)")
      }
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)

    let interruptedStore = MemoryGenerationStore(
      rootURL: storeURL,
      beforePointerCommit: { throw InjectedFailure.beforePointerCommit }
    )
    XCTAssertThrowsError(try interruptedStore.commit(continuation)) { error in
      XCTAssertTrue(error is InjectedFailure)
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)

    let incompatibleGeneration = MemoryGeneration(
      schemaVersion: confirmedBase.generation.schemaVersion,
      policyVersion: "fum.memory.policy.v999",
      previousGenerationSHA256: confirmedBase.generation.previousGenerationSHA256,
      inputSHA256: confirmedBase.generation.inputSHA256,
      seedSHA256: confirmedBase.generation.seedSHA256,
      eventJournalSHA256: confirmedBase.generation.eventJournalSHA256,
      snapshotSHA256: confirmedBase.generation.snapshotSHA256,
      traceSHA256: confirmedBase.generation.traceSHA256,
      viewModelSHA256: confirmedBase.generation.viewModelSHA256,
      seed: confirmedBase.generation.seed,
      eventJournal: confirmedBase.generation.eventJournal,
      snapshot: confirmedBase.generation.snapshot,
      trace: confirmedBase.generation.trace,
      viewModel: confirmedBase.generation.viewModel,
      provenance: confirmedBase.generation.provenance
    )
    let incompatibleBase = StoredMemoryGeneration(
      generationSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(incompatibleGeneration)
      ),
      generation: incompatibleGeneration
    )
    XCTAssertThrowsError(
      try engine.generation(
        from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
        continuingFrom: incompatibleBase
      )
    ) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .incompatibleGeneration("Неподдерживаемая версия политики памяти.")
      )
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)
  }

  func testProcessCrashRecoveryAtEveryCommitCheckpoint() throws {
    let scenarios:
      [(
        checkpoint: MemoryGenerationCommitCheckpoint,
        publishesCandidate: Bool
      )] = [
        (.generationTemporaryWritten, false),
        (.generationFileSynchronized, false),
        (.generationPublished, false),
        (.generationsDirectorySynchronized, false),
        (.currentTemporaryWritten, false),
        (.currentFileSynchronized, false),
        (.currentPublished, true),
        (.rootDirectorySynchronized, true),
      ]
    XCTAssertEqual(
      Set(MemoryGenerationCommitCheckpoint.allCases.map(\.rawValue)),
      Set(scenarios.map { $0.checkpoint.rawValue }),
      "Каждая аварийная контрольная точка должна иметь процессный сценарий."
    )

    for startsFromConfirmedBase in [false, true] {
      for scenario in scenarios {
        try assertProcessCrashRecovery(
          at: scenario.checkpoint,
          publishesCandidate: scenario.publishesCandidate,
          startsFromConfirmedBase: startsFromConfirmedBase
        )
      }
    }
  }

  func testIdempotentRetryAfterCurrentPublicationCompletesRootDirectorySync() throws {
    enum InjectedFailure: Error {
      case afterCurrentPublication
    }

    let engine = MemoryPopulationEngine()
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)
    let candidate = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )
    let candidateSHA256 = CanonicalMemoryJSON.sha256(
      try CanonicalMemoryJSON.encode(candidate)
    )

    let ambiguousStore = MemoryGenerationStore(
      rootURL: storeURL,
      beforePointerCommit: {},
      commitCheckpointObserver: { checkpoint in
        if checkpoint == .currentPublished {
          throw InjectedFailure.afterCurrentPublication
        }
      }
    )
    XCTAssertThrowsError(try ambiguousStore.commit(candidate)) { error in
      XCTAssertTrue(error is InjectedFailure)
    }
    XCTAssertEqual(
      try XCTUnwrap(store.loadCurrent()).generationSHA256,
      candidateSHA256,
      "После неоднозначной ошибки опубликованный CURRENT должен читаться как новое поколение."
    )

    var retryCheckpoints: [MemoryGenerationCommitCheckpoint] = []
    let retryStore = MemoryGenerationStore(
      rootURL: storeURL,
      beforePointerCommit: {},
      commitCheckpointObserver: { retryCheckpoints.append($0) }
    )
    let retried = try retryStore.commit(candidate)
    XCTAssertEqual(retried.generationSHA256, candidateSHA256)
    XCTAssertTrue(
      retryCheckpoints.contains(.rootDirectorySynchronized),
      "Идемпотентный повтор обязан завершить синхронизацию каталога после уже видимого CURRENT."
    )
  }

  func testTwoProcessesPublishingIdenticalGenerationAreIdempotent() throws {
    let engine = MemoryPopulationEngine()
    let scratchURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: scratchURL) }
    try FileManager.default.createDirectory(
      at: scratchURL,
      withIntermediateDirectories: true
    )

    let storeURL = scratchURL.appendingPathComponent("store", isDirectory: true)
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)
    let candidate = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )
    let candidateData = try CanonicalMemoryJSON.encode(candidate)
    let candidateSHA256 = CanonicalMemoryJSON.sha256(candidateData)
    let candidateURL = scratchURL.appendingPathComponent("candidate-identical.json")
    try candidateData.write(to: candidateURL)
    let barrierURL = scratchURL.appendingPathComponent(
      "identical-barrier",
      isDirectory: true
    )
    let firstResultURL = scratchURL.appendingPathComponent("identical-first.json")
    let secondResultURL = scratchURL.appendingPathComponent("identical-second.json")

    let firstProcess = try makeCASWorkerProcess(
      workerID: "identical-first",
      storeURL: storeURL,
      candidateURL: candidateURL,
      resultURL: firstResultURL,
      barrierURL: barrierURL
    )
    let secondProcess = try makeCASWorkerProcess(
      workerID: "identical-second",
      storeURL: storeURL,
      candidateURL: candidateURL,
      resultURL: secondResultURL,
      barrierURL: barrierURL
    )
    try firstProcess.run()
    defer { stopCASWorkerIfNeeded(firstProcess) }
    try secondProcess.run()
    defer { stopCASWorkerIfNeeded(secondProcess) }
    try waitForCASWorker(firstProcess, workerID: "identical-first")
    try waitForCASWorker(secondProcess, workerID: "identical-second")

    let results = try [firstResultURL, secondResultURL].map(readCASWorkerResult)
    XCTAssertEqual(results.map(\.status), ["published", "published"])
    XCTAssertEqual(
      results.compactMap(\.generationSHA256),
      [candidateSHA256, candidateSHA256]
    )
    XCTAssertEqual(
      try XCTUnwrap(store.loadCurrent()).generationSHA256,
      candidateSHA256
    )
    XCTAssertEqual(
      try Data(contentsOf: generationURL(for: candidateSHA256, storeURL: storeURL)),
      candidateData
    )
  }

  func testTwoProcessesCompareAndSwapCurrentFromTheSameParent() throws {
    let engine = MemoryPopulationEngine()
    let scratchURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: scratchURL) }
    try FileManager.default.createDirectory(
      at: scratchURL,
      withIntermediateDirectories: true
    )

    let storeURL = scratchURL.appendingPathComponent("store", isDirectory: true)
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)
    let firstCandidate = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )
    let secondCandidate = try engine.generation(
      from: competingContinuationData(),
      continuingFrom: confirmedBase
    )
    let firstCandidateData = try CanonicalMemoryJSON.encode(firstCandidate)
    let secondCandidateData = try CanonicalMemoryJSON.encode(secondCandidate)
    let firstCandidateSHA256 = CanonicalMemoryJSON.sha256(firstCandidateData)
    let secondCandidateSHA256 = CanonicalMemoryJSON.sha256(secondCandidateData)
    XCTAssertNotEqual(firstCandidateSHA256, secondCandidateSHA256)
    XCTAssertEqual(
      firstCandidate.previousGenerationSHA256,
      confirmedBase.generationSHA256
    )
    XCTAssertEqual(
      secondCandidate.previousGenerationSHA256,
      confirmedBase.generationSHA256
    )

    let firstCandidateURL = scratchURL.appendingPathComponent("candidate-first.json")
    let secondCandidateURL = scratchURL.appendingPathComponent("candidate-second.json")
    try firstCandidateData.write(to: firstCandidateURL)
    try secondCandidateData.write(to: secondCandidateURL)
    let barrierURL = scratchURL.appendingPathComponent("barrier", isDirectory: true)
    let firstResultURL = scratchURL.appendingPathComponent("result-first.json")
    let secondResultURL = scratchURL.appendingPathComponent("result-second.json")

    let firstProcess = try makeCASWorkerProcess(
      workerID: "first",
      storeURL: storeURL,
      candidateURL: firstCandidateURL,
      resultURL: firstResultURL,
      barrierURL: barrierURL
    )
    let secondProcess = try makeCASWorkerProcess(
      workerID: "second",
      storeURL: storeURL,
      candidateURL: secondCandidateURL,
      resultURL: secondResultURL,
      barrierURL: barrierURL
    )
    try firstProcess.run()
    defer { stopCASWorkerIfNeeded(firstProcess) }
    try secondProcess.run()
    defer { stopCASWorkerIfNeeded(secondProcess) }
    try waitForCASWorker(firstProcess, workerID: "first")
    try waitForCASWorker(secondProcess, workerID: "second")

    let raceResults = try [firstResultURL, secondResultURL].map(readCASWorkerResult)
    let published = raceResults.filter { $0.status == "published" }
    let conflicted = raceResults.filter { $0.status == "conflict" }
    let unexpected = raceResults.filter { $0.status == "unexpected" }
    XCTAssertTrue(
      unexpected.isEmpty,
      "Неожиданный исход дочернего процесса: \(unexpected.compactMap(\.diagnostic))"
    )
    XCTAssertEqual(published.count, 1, "Ровно один процесс должен опубликовать поколение.")
    XCTAssertEqual(conflicted.count, 1, "Проигравший процесс должен получить конфликт.")
    let winnerSHA256 = try XCTUnwrap(published.only?.generationSHA256)
    let loserSHA256 =
      winnerSHA256 == firstCandidateSHA256
      ? secondCandidateSHA256 : firstCandidateSHA256
    XCTAssertEqual(conflicted.only?.expectedGenerationSHA256, confirmedBase.generationSHA256)
    XCTAssertEqual(conflicted.only?.actualGenerationSHA256, winnerSHA256)
    XCTAssertTrue([firstCandidateSHA256, secondCandidateSHA256].contains(winnerSHA256))

    let confirmedWinner = try XCTUnwrap(store.loadCurrent())
    XCTAssertEqual(confirmedWinner.generationSHA256, winnerSHA256)
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json")
    let confirmedPointerData = try Data(contentsOf: pointerURL)
    XCTAssertEqual(
      try Data(contentsOf: generationURL(for: firstCandidateSHA256, storeURL: storeURL)),
      firstCandidateData
    )
    XCTAssertEqual(
      try Data(contentsOf: generationURL(for: secondCandidateSHA256, storeURL: storeURL)),
      secondCandidateData,
      "Проигравший может оставить только точное неподтверждённое адресуемое поколение."
    )

    let winnerCandidateURL =
      winnerSHA256 == firstCandidateSHA256 ? firstCandidateURL : secondCandidateURL
    let idempotentResultURL = scratchURL.appendingPathComponent("result-idempotent.json")
    let idempotentProcess = try makeCASWorkerProcess(
      workerID: "idempotent",
      storeURL: storeURL,
      candidateURL: winnerCandidateURL,
      resultURL: idempotentResultURL,
      barrierURL: nil
    )
    try idempotentProcess.run()
    defer { stopCASWorkerIfNeeded(idempotentProcess) }
    try waitForCASWorker(idempotentProcess, workerID: "idempotent")
    let idempotentResult = try readCASWorkerResult(idempotentResultURL)
    XCTAssertEqual(idempotentResult.status, "published")
    XCTAssertEqual(idempotentResult.generationSHA256, winnerSHA256)
    XCTAssertEqual(try Data(contentsOf: pointerURL), confirmedPointerData)

    let loserCandidateURL =
      loserSHA256 == firstCandidateSHA256 ? firstCandidateURL : secondCandidateURL
    let staleResultURL = scratchURL.appendingPathComponent("result-stale.json")
    let staleProcess = try makeCASWorkerProcess(
      workerID: "stale",
      storeURL: storeURL,
      candidateURL: loserCandidateURL,
      resultURL: staleResultURL,
      barrierURL: nil
    )
    try staleProcess.run()
    defer { stopCASWorkerIfNeeded(staleProcess) }
    try waitForCASWorker(staleProcess, workerID: "stale")
    let staleResult = try readCASWorkerResult(staleResultURL)
    XCTAssertEqual(staleResult.status, "conflict")
    XCTAssertEqual(staleResult.expectedGenerationSHA256, confirmedBase.generationSHA256)
    XCTAssertEqual(staleResult.actualGenerationSHA256, winnerSHA256)
    XCTAssertEqual(try Data(contentsOf: pointerURL), confirmedPointerData)
    XCTAssertEqual(try XCTUnwrap(store.loadCurrent()).generationSHA256, winnerSHA256)
    XCTAssertEqual(
      try Set(
        FileManager.default.contentsOfDirectory(
          at: storeURL,
          includingPropertiesForKeys: nil
        ).map(\.lastPathComponent)
      ),
      Set(["CURRENT.json", "CURRENT.lock", "generations"])
    )
    XCTAssertEqual(
      try Set(
        FileManager.default.contentsOfDirectory(
          at: storeURL.appendingPathComponent("generations", isDirectory: true),
          includingPropertiesForKeys: nil
        ).map(\.lastPathComponent)
      ),
      Set(
        [confirmedBase.generationSHA256, firstCandidateSHA256, secondCandidateSHA256].map {
          "\($0.dropFirst(7)).json"
        }
      )
    )
  }

  func testWriterWaitsForThePersistentInterprocessCurrentLock() throws {
    let engine = MemoryPopulationEngine()
    let scratchURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: scratchURL) }
    try FileManager.default.createDirectory(
      at: scratchURL,
      withIntermediateDirectories: true
    )

    let storeURL = scratchURL.appendingPathComponent("store", isDirectory: true)
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)
    let candidate = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )
    let candidateURL = scratchURL.appendingPathComponent("candidate.json")
    try CanonicalMemoryJSON.encode(candidate).write(to: candidateURL)

    let lockURL = storeURL.appendingPathComponent("CURRENT.lock")
    let lockDescriptor = lockURL.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
    }
    XCTAssertGreaterThanOrEqual(lockDescriptor, 0)
    guard lockDescriptor >= 0 else { return }
    var parentLock = Darwin.flock()
    parentLock.l_type = Int16(F_WRLCK)
    parentLock.l_whence = Int16(SEEK_SET)
    XCTAssertEqual(Darwin.fcntl(lockDescriptor, F_SETLKW, &parentLock), 0)
    var lockIsHeld = true
    defer {
      if lockIsHeld {
        var unlock = Darwin.flock()
        unlock.l_type = Int16(F_UNLCK)
        unlock.l_whence = Int16(SEEK_SET)
        _ = Darwin.fcntl(lockDescriptor, F_SETLK, &unlock)
      }
      _ = Darwin.close(lockDescriptor)
    }

    let lockTraceURL = scratchURL.appendingPathComponent("lock-trace", isDirectory: true)
    try FileManager.default.createDirectory(
      at: lockTraceURL,
      withIntermediateDirectories: true
    )
    let willAcquireURL = lockTraceURL.appendingPathComponent("will-acquire")
    let didAcquireURL = lockTraceURL.appendingPathComponent("did-acquire")
    let resultURL = scratchURL.appendingPathComponent("lock-result.json")
    let process = try makeCASWorkerProcess(
      workerID: "locked-child",
      storeURL: storeURL,
      candidateURL: candidateURL,
      resultURL: resultURL,
      barrierURL: nil,
      lockTraceURL: lockTraceURL
    )
    try process.run()
    defer { stopCASWorkerIfNeeded(process) }
    try waitForFile(
      willAcquireURL,
      process: process,
      timeout: .seconds(10)
    )
    try assertFileRemainsAbsent(
      didAcquireURL,
      process: process,
      duration: .seconds(1)
    )
    XCTAssertTrue(process.isRunning, "Писатель не дождался межпроцессной блокировки.")
    XCTAssertFalse(FileManager.default.fileExists(atPath: resultURL.path))
    XCTAssertEqual(
      try XCTUnwrap(store.loadCurrent()).generationSHA256, confirmedBase.generationSHA256)

    var unlock = Darwin.flock()
    unlock.l_type = Int16(F_UNLCK)
    unlock.l_whence = Int16(SEEK_SET)
    XCTAssertEqual(Darwin.fcntl(lockDescriptor, F_SETLK, &unlock), 0)
    lockIsHeld = false
    try waitForFile(
      didAcquireURL,
      process: process,
      timeout: .seconds(10)
    )
    try waitForCASWorker(process, workerID: "locked-child")
    let result = try readCASWorkerResult(resultURL)
    XCTAssertEqual(result.status, "published", result.diagnostic ?? "")
    XCTAssertEqual(
      try XCTUnwrap(store.loadCurrent()).generationSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(candidate))
    )
  }

  func testInterprocessCASWorker() throws {
    let environment = ProcessInfo.processInfo.environment
    guard
      let workerID = environment["FUM_MEMORY_CAS_WORKER_ID"],
      let storePath = environment["FUM_MEMORY_CAS_WORKER_STORE"],
      let candidatePath = environment["FUM_MEMORY_CAS_WORKER_CANDIDATE"],
      let resultPath = environment["FUM_MEMORY_CAS_WORKER_RESULT"]
    else {
      return
    }

    let storeURL = URL(fileURLWithPath: storePath, isDirectory: true)
    let candidateURL = URL(fileURLWithPath: candidatePath, isDirectory: false)
    let resultURL = URL(fileURLWithPath: resultPath, isDirectory: false)
    let barrierURL = environment["FUM_MEMORY_CAS_WORKER_BARRIER"].map {
      URL(fileURLWithPath: $0, isDirectory: true)
    }
    let lockTraceURL = environment["FUM_MEMORY_CAS_WORKER_LOCK_TRACE"].map {
      URL(fileURLWithPath: $0, isDirectory: true)
    }
    let beforePointerCommit: () throws -> Void = {
      guard let barrierURL else { return }
      try FileManager.default.createDirectory(
        at: barrierURL,
        withIntermediateDirectories: true
      )
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
        if ready.count == 2 { return }
        Thread.sleep(forTimeInterval: 0.01)
      }
      throw MemoryPopulationError.generationStore(
        "Процессный барьер конкурентного теста не дождался второго писателя."
      )
    }
    let publicationLockObserver: (MemoryGenerationPublicationLockEvent) throws -> Void = {
      event in
      guard let lockTraceURL else { return }
      let filename: String
      switch event {
      case .willAcquire:
        filename = "will-acquire"
      case .didAcquire:
        filename = "did-acquire"
      }
      try Data(workerID.utf8).write(
        to: lockTraceURL.appendingPathComponent(filename),
        options: [.atomic]
      )
    }

    let result: CASWorkerResult
    do {
      let candidateData = try Data(contentsOf: candidateURL, options: [.mappedIfSafe])
      let generation = try JSONDecoder().decode(MemoryGeneration.self, from: candidateData)
      let store = MemoryGenerationStore(
        rootURL: storeURL,
        beforePointerCommit: beforePointerCommit,
        publicationLockObserver: publicationLockObserver
      )
      let stored = try store.commit(generation)
      result = CASWorkerResult(
        status: "published",
        generationSHA256: stored.generationSHA256,
        expectedGenerationSHA256: nil,
        actualGenerationSHA256: nil,
        diagnostic: nil
      )
    } catch MemoryPopulationError.generationConflict(let expected, let actual) {
      result = CASWorkerResult(
        status: "conflict",
        generationSHA256: nil,
        expectedGenerationSHA256: expected,
        actualGenerationSHA256: actual,
        diagnostic: nil
      )
    } catch {
      result = CASWorkerResult(
        status: "unexpected",
        generationSHA256: nil,
        expectedGenerationSHA256: nil,
        actualGenerationSHA256: nil,
        diagnostic: String(describing: error)
      )
    }
    try JSONEncoder().encode(result).write(to: resultURL, options: [.atomic])
  }

  func testProcessCrashWriter() throws {
    let environment = ProcessInfo.processInfo.environment
    guard
      let storePath = environment["FUM_MEMORY_CRASH_WRITER_STORE"],
      let candidatePath = environment["FUM_MEMORY_CRASH_WRITER_CANDIDATE"],
      let checkpointName = environment["FUM_MEMORY_CRASH_WRITER_CHECKPOINT"],
      let markerPath = environment["FUM_MEMORY_CRASH_WRITER_MARKER"]
    else {
      return
    }

    let targetCheckpoint = try XCTUnwrap(
      MemoryGenerationCommitCheckpoint(rawValue: checkpointName)
    )
    let candidateData = try Data(
      contentsOf: URL(fileURLWithPath: candidatePath, isDirectory: false),
      options: [.mappedIfSafe]
    )
    let candidate = try JSONDecoder().decode(MemoryGeneration.self, from: candidateData)
    let markerURL = URL(fileURLWithPath: markerPath, isDirectory: false)
    let store = MemoryGenerationStore(
      rootURL: URL(fileURLWithPath: storePath, isDirectory: true),
      beforePointerCommit: {},
      publicationLockObserver: nil,
      commitCheckpointObserver: { checkpoint in
        guard checkpoint == targetCheckpoint else { return }
        try Data(checkpoint.rawValue.utf8).write(to: markerURL, options: [.atomic])
        while true {
          _ = Darwin.raise(SIGSTOP)
        }
      }
    )

    _ = try store.commit(candidate)
    XCTFail("Писатель не остановился на точке \(checkpointName).")
  }

  func testProcessCrashRecoveryWorker() throws {
    let environment = ProcessInfo.processInfo.environment
    guard
      let storePath = environment["FUM_MEMORY_CRASH_RECOVERY_STORE"],
      let resultPath = environment["FUM_MEMORY_CRASH_RECOVERY_RESULT"]
    else {
      return
    }

    let store = MemoryGenerationStore(
      rootURL: URL(fileURLWithPath: storePath, isDirectory: true)
    )
    let current = try store.loadCurrent()
    try JSONEncoder().encode(current).write(
      to: URL(fileURLWithPath: resultPath, isDirectory: false),
      options: [.atomic]
    )
  }

  func testStoreRejectsUnrelatedOrTraceInconsistentSuccessor() throws {
    let engine = MemoryPopulationEngine()
    let storeURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }
    let store = MemoryGenerationStore(rootURL: storeURL)
    let base = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    let confirmedBase = try store.commit(base)

    let unrelated = try engine.generation(from: programData())
    let forgedLineage = MemoryGeneration(
      schemaVersion: unrelated.schemaVersion,
      policyVersion: unrelated.policyVersion,
      previousGenerationSHA256: confirmedBase.generationSHA256,
      inputSHA256: unrelated.inputSHA256,
      seedSHA256: unrelated.seedSHA256,
      eventJournalSHA256: unrelated.eventJournalSHA256,
      snapshotSHA256: unrelated.snapshotSHA256,
      traceSHA256: unrelated.traceSHA256,
      viewModelSHA256: unrelated.viewModelSHA256,
      seed: unrelated.seed,
      eventJournal: unrelated.eventJournal,
      snapshot: unrelated.snapshot,
      trace: unrelated.trace,
      viewModel: unrelated.viewModel,
      provenance: unrelated.provenance
    )
    XCTAssertThrowsError(try store.commit(forgedLineage)) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .corruptGeneration(
          "Происхождение преемника не выделяет добавленный суффикс журнала."
        )
      )
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)

    let continuation = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: confirmedBase
    )
    var alteredEntries = continuation.trace.entries
    let last = try XCTUnwrap(alteredEntries.popLast())
    alteredEntries.append(
      MemoryTraceEntry(
        ordinal: last.ordinal,
        eventID: last.eventID,
        operation: last.operation,
        reads: last.reads,
        writes: ["forged-target"],
        sourceEventSHA256: last.sourceEventSHA256,
        outputRecordSHA256: last.outputRecordSHA256
      )
    )
    let alteredTrace = MemoryExecutionTrace(
      schemaVersion: continuation.trace.schemaVersion,
      datasetID: continuation.trace.datasetID,
      entries: alteredEntries
    )
    let inconsistent = MemoryGeneration(
      schemaVersion: continuation.schemaVersion,
      policyVersion: continuation.policyVersion,
      previousGenerationSHA256: continuation.previousGenerationSHA256,
      inputSHA256: continuation.inputSHA256,
      seedSHA256: continuation.seedSHA256,
      eventJournalSHA256: continuation.eventJournalSHA256,
      snapshotSHA256: continuation.snapshotSHA256,
      traceSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(alteredTrace)
      ),
      viewModelSHA256: continuation.viewModelSHA256,
      seed: continuation.seed,
      eventJournal: continuation.eventJournal,
      snapshot: continuation.snapshot,
      trace: alteredTrace,
      viewModel: continuation.viewModel,
      provenance: continuation.provenance
    )
    XCTAssertThrowsError(try store.commit(inconsistent)) { error in
      guard case MemoryPopulationError.corruptGeneration = error else {
        return XCTFail("Ожидалась ошибка связности трассы, получено: \(error)")
      }
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)

    let lastRecord = try XCTUnwrap(
      continuation.snapshot.records.first(where: { $0.key == "next-stage" })
    )
    let emptyRecord = MemoryRecord(
      key: lastRecord.key,
      value: "",
      provenance: lastRecord.provenance
    )
    let policySnapshot = MemorySnapshot(
      schemaVersion: continuation.snapshot.schemaVersion,
      datasetID: continuation.snapshot.datasetID,
      records: continuation.snapshot.records.map {
        $0.key == emptyRecord.key ? emptyRecord : $0
      }
    )
    var policyEntries = continuation.trace.entries
    let policyLast = try XCTUnwrap(policyEntries.popLast())
    policyEntries.append(
      MemoryTraceEntry(
        ordinal: policyLast.ordinal,
        eventID: policyLast.eventID,
        operation: policyLast.operation,
        reads: policyLast.reads,
        writes: policyLast.writes,
        sourceEventSHA256: policyLast.sourceEventSHA256,
        outputRecordSHA256: CanonicalMemoryJSON.sha256(
          try CanonicalMemoryJSON.encode(emptyRecord)
        )
      )
    )
    let policyTrace = MemoryExecutionTrace(
      schemaVersion: continuation.trace.schemaVersion,
      datasetID: continuation.trace.datasetID,
      entries: policyEntries
    )
    let policyView = MemoryViewProjectionOperator().project(policySnapshot)
    let policyViolating = MemoryGeneration(
      schemaVersion: continuation.schemaVersion,
      policyVersion: continuation.policyVersion,
      previousGenerationSHA256: continuation.previousGenerationSHA256,
      inputSHA256: continuation.inputSHA256,
      seedSHA256: continuation.seedSHA256,
      eventJournalSHA256: continuation.eventJournalSHA256,
      snapshotSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(policySnapshot)
      ),
      traceSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(policyTrace)
      ),
      viewModelSHA256: CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.encode(policyView)
      ),
      seed: continuation.seed,
      eventJournal: continuation.eventJournal,
      snapshot: policySnapshot,
      trace: policyTrace,
      viewModel: policyView,
      provenance: continuation.provenance
    )
    XCTAssertThrowsError(try store.commit(policyViolating)) { error in
      guard case MemoryPopulationError.corruptGeneration = error else {
        return XCTFail("Ожидался отказ поколения вне политики, получено: \(error)")
      }
    }
    XCTAssertEqual(try store.loadCurrent(), confirmedBase)
  }

  func testProjectionProvenanceAndIntentRoundTripRemainHeadlessAndVersioned() throws {
    let generation = try MemoryPopulationEngine().generation(
      from: MemoryPopulationFixtures.loadBootstrapV1()
    )
    let element = try XCTUnwrap(
      generation.viewModel.elements.first(where: { $0.id == "memory.next-stage" })
    )

    XCTAssertTrue(generation.viewModel.headless)
    XCTAssertEqual(
      generation.viewModel.operatorVersion,
      MemoryViewProjectionOperator.version
    )
    XCTAssertEqual(element.kind, .text)
    XCTAssertEqual(element.provenance.sourceRecordKeys, ["next-stage"])
    XCTAssertEqual(element.provenance.producedByEventID, "event.006.next-stage")
    XCTAssertTrue(
      element.provenance.contributingEventIDs.contains("event.001.goal")
    )
    XCTAssertEqual(
      element.provenance.operatorVersion,
      MemoryViewProjectionOperator.version
    )

    let intent = MemoryUserIntent(
      schemaVersion: 1,
      id: "add-user-note",
      kind: .remember,
      target: "user-note",
      value: "проверяемое намерение"
    )
    let program = try MemoryViewProjectionOperator().program(
      for: intent,
      continuing: generation
    )
    let event = try XCTUnwrap(program.events.only)

    XCTAssertEqual(program.schemaVersion, 1)
    XCTAssertEqual(program.policyVersion, MemoryPopulationPolicy.version)
    XCTAssertEqual(program.datasetID, generation.snapshot.datasetID)
    XCTAssertEqual(event.id, "intent.add-user-note")
    XCTAssertEqual(event.sequence, generation.trace.entries.count + 1)
    XCTAssertEqual(event.operation, .remember)
    XCTAssertEqual(event.target, "user-note")
    XCTAssertEqual(event.value, "проверяемое намерение")

    let projectionJSON = String(
      decoding: try CanonicalMemoryJSON.encode(generation.viewModel),
      as: UTF8.self
    )
    XCTAssertFalse(projectionJSON.contains("source_code"))
    XCTAssertFalse(projectionJSON.contains("import SwiftUI"))
    XCTAssertTrue(projectionJSON.contains("renderer не входит"))
  }

  func testProjectionRejectsIntentWhoseDerivedEventIDAlreadyExists() throws {
    let input = Data(
      """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "intent-collision-v1",
        "events": [
          {
            "id": "intent.add-user-note",
            "sequence": 1,
            "operation": "remember",
            "target": "existing-note",
            "value": "существующее событие"
          }
        ]
      }
      """.utf8
    )
    let generation = try MemoryPopulationEngine().generation(from: input)
    let intent = MemoryUserIntent(
      schemaVersion: 1,
      id: "add-user-note",
      kind: .remember,
      target: "new-note",
      value: "новое значение"
    )

    XCTAssertThrowsError(
      try MemoryViewProjectionOperator().program(for: intent, continuing: generation)
    ) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .invalidIntent("Производный идентификатор события уже принят памятью.")
      )
    }
  }

  func testComposeCannotReadUnknownMemory() {
    let input = """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "missing-source-v1",
        "events": [
          {
            "id": "event.summary",
            "sequence": 1,
            "operation": "compose",
            "target": "summary",
            "sources": ["absent"],
            "separator": ""
          }
        ]
      }
      """

    XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(input.utf8))) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .missingRecord(eventID: "event.summary", key: "absent")
      )
    }
  }

  func testRejectsDuplicateTargetAndNonContiguousSequence() throws {
    let duplicate = """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "duplicate-v1",
        "events": [
          {
            "id": "event.first",
            "sequence": 1,
            "operation": "remember",
            "target": "same",
            "value": "one"
          },
          {
            "id": "event.second",
            "sequence": 2,
            "operation": "remember",
            "target": "same",
            "value": "two"
          }
        ]
      }
      """
    XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(duplicate.utf8))) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .duplicateTarget(eventID: "event.second", key: "same")
      )
    }

    let sequenceGap = String(decoding: programData(), as: UTF8.self)
      .replacingOccurrences(of: "\"sequence\": 2", with: "\"sequence\": 4")
    XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(sequenceGap.utf8))) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .invalidEvent("event.interface: ожидалась sequence 2, получена 4")
      )
    }
  }

  func testRejectsUnknownEnvelopeAndEventFields() {
    let source = String(decoding: programData(), as: UTF8.self)
    let unknownEnvelope = source.replacingOccurrences(
      of: "\"events\": [",
      with: "\"unexpected\": true,\n  \"events\": ["
    )
    let unknownEvent = source.replacingOccurrences(
      of: "\"value\": \"минимальный прототип\"",
      with: "\"value\": \"минимальный прототип\",\n      \"unexpected\": true"
    )

    for input in [unknownEnvelope, unknownEvent] {
      XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(input.utf8))) { error in
        XCTAssertEqual(
          error as? MemoryPopulationError,
          .invalidInput("Вход не соответствует схеме набора событий версии 1.")
        )
      }
    }
  }

  func testRejectsExplicitNullInsteadOfOperationField() {
    let source = String(decoding: programData(), as: UTF8.self)
    let explicitNull = source.replacingOccurrences(
      of: "\"value\": \"минимальный прототип\"",
      with: "\"value\": null"
    )

    XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(explicitNull.utf8))) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .invalidInput("Вход не соответствует схеме набора событий версии 1.")
      )
    }
  }

  func testComposeRejectsOversizedDerivedRecordBeforeSnapshotIsAccepted() throws {
    let value = String(repeating: "я", count: 8_192)
    let events = (1...5).map { index in
      """
          {
            "id": "event.source.\(index)",
            "sequence": \(index),
            "operation": "remember",
            "target": "source.\(index)",
            "value": "\(value)"
          }
      """
    }.joined(separator: ",\n")
    let input = """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "oversized-compose-v1",
        "events": [
      \(events),
          {
            "id": "event.compose",
            "sequence": 6,
            "operation": "compose",
            "target": "oversized",
            "sources": ["source.1", "source.2", "source.3", "source.4", "source.5"],
            "separator": ""
          }
        ]
      }
      """

    XCTAssertThrowsError(try MemoryPopulationEngine().run(Data(input.utf8))) { error in
      XCTAssertEqual(
        error as? MemoryPopulationError,
        .recordTooLarge(eventID: "event.compose", byteCount: 81_920)
      )
    }
  }

  private func programData() -> Data {
    Data(
      """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "test-bootstrap-v1",
        "events": [
          {
            "id": "event.goal",
            "sequence": 1,
            "operation": "remember",
            "target": "goal",
            "value": "минимальный прототип"
          },
          {
            "id": "event.interface",
            "sequence": 2,
            "operation": "remember",
            "target": "interface",
            "value": "без GUI"
          },
          {
            "id": "event.summary",
            "sequence": 3,
            "operation": "compose",
            "target": "summary",
            "sources": ["goal", "interface"],
            "separator": " | "
          }
        ]
      }
      """.utf8
    )
  }

  private func competingContinuationData() -> Data {
    Data(
      """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "fum.bootstrap.memory.v1",
        "events": [
          {
            "id": "event.005.concurrent-alternative",
            "sequence": 5,
            "operation": "remember",
            "target": "concurrent-alternative",
            "value": "альтернативное продолжение от того же родителя"
          }
        ]
      }
      """.utf8
    )
  }

  private func makeCASWorkerProcess(
    workerID: String,
    storeURL: URL,
    candidateURL: URL,
    resultURL: URL,
    barrierURL: URL?,
    lockTraceURL: URL? = nil
  ) throws -> Process {
    let process = Process()
    process.executableURL = try executableURL(named: "xcrun")
    process.arguments = [
      "xctest",
      "-XCTest",
      "MemoryPopulationTests/testInterprocessCASWorker",
      Bundle(for: MemoryPopulationTests.self).bundleURL.path,
    ]
    var environment = ProcessInfo.processInfo.environment
    environment["FUM_MEMORY_CAS_WORKER_ID"] = workerID
    environment["FUM_MEMORY_CAS_WORKER_STORE"] = storeURL.path
    environment["FUM_MEMORY_CAS_WORKER_CANDIDATE"] = candidateURL.path
    environment["FUM_MEMORY_CAS_WORKER_RESULT"] = resultURL.path
    environment["FUM_MEMORY_CAS_WORKER_BARRIER"] = barrierURL?.path
    environment["FUM_MEMORY_CAS_WORKER_LOCK_TRACE"] = lockTraceURL?.path
    process.environment = environment
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    return process
  }

  private func assertProcessCrashRecovery(
    at checkpoint: MemoryGenerationCommitCheckpoint,
    publishesCandidate: Bool,
    startsFromConfirmedBase: Bool
  ) throws {
    let engine = MemoryPopulationEngine()
    let scratchURL = temporaryStoreURL()
    defer { try? FileManager.default.removeItem(at: scratchURL) }
    try FileManager.default.createDirectory(
      at: scratchURL,
      withIntermediateDirectories: true
    )

    let storeURL = scratchURL.appendingPathComponent("store", isDirectory: true)
    let store = MemoryGenerationStore(rootURL: storeURL)
    let pointerURL = storeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    let confirmedBase: StoredMemoryGeneration?
    let confirmedBasePointer: Data?
    let candidate: MemoryGeneration
    if startsFromConfirmedBase {
      let base = try engine.generation(
        from: MemoryPopulationFixtures.loadBootstrapBaseV1()
      )
      let storedBase = try store.commit(base)
      confirmedBase = storedBase
      confirmedBasePointer = try Data(
        contentsOf: pointerURL,
        options: [.mappedIfSafe]
      )
      candidate = try engine.generation(
        from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
        continuingFrom: storedBase
      )
    } else {
      confirmedBase = nil
      confirmedBasePointer = nil
      candidate = try engine.generation(
        from: MemoryPopulationFixtures.loadBootstrapBaseV1()
      )
    }
    let candidateData = try CanonicalMemoryJSON.encode(candidate)
    let candidateSHA256 = CanonicalMemoryJSON.sha256(candidateData)
    let candidateURL = scratchURL.appendingPathComponent("candidate.json", isDirectory: false)
    try candidateData.write(to: candidateURL, options: [.atomic])
    let markerURL = scratchURL.appendingPathComponent("crash-checkpoint", isDirectory: false)

    let writer = try makeCrashWriterProcess(
      storeURL: storeURL,
      candidateURL: candidateURL,
      checkpoint: checkpoint,
      markerURL: markerURL
    )
    try writer.run()
    defer { stopCASWorkerIfNeeded(writer) }
    try waitForCrashCheckpoint(
      markerURL,
      checkpoint: checkpoint,
      process: writer,
      timeout: .seconds(10)
    )
    try killCrashWriter(writer, checkpoint: checkpoint)

    let recoveryResultURL = scratchURL.appendingPathComponent(
      "recovery-result.json",
      isDirectory: false
    )
    let recovery = try makeCrashRecoveryProcess(
      storeURL: storeURL,
      resultURL: recoveryResultURL
    )
    try recovery.run()
    defer { stopCASWorkerIfNeeded(recovery) }
    try waitForCASWorker(
      recovery,
      workerID:
        "crash-recovery-\(startsFromConfirmedBase ? "replacement" : "initial")-\(checkpoint.rawValue)"
    )
    let restored = try JSONDecoder().decode(
      StoredMemoryGeneration?.self,
      from: Data(contentsOf: recoveryResultURL, options: [.mappedIfSafe])
    )
    let expectedSHA256 =
      publishesCandidate
      ? candidateSHA256 : confirmedBase?.generationSHA256
    XCTAssertEqual(
      restored?.generationSHA256,
      expectedSHA256,
      "Неверное восстановление после \(checkpoint.rawValue)."
    )
    if let restored {
      XCTAssertEqual(
        CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(restored.generation)),
        expectedSHA256,
        "Новый процесс должен вернуть целостное поколение."
      )
    }

    let candidateGenerationURL = generationURL(
      for: candidateSHA256,
      storeURL: storeURL
    )
    switch checkpoint {
    case .generationTemporaryWritten, .generationFileSynchronized:
      XCTAssertFalse(
        FileManager.default.fileExists(atPath: candidateGenerationURL.path),
        "До публикации поколения его конечное имя не должно появиться."
      )
    default:
      XCTAssertEqual(
        try Data(contentsOf: candidateGenerationURL, options: [.mappedIfSafe]),
        candidateData,
        "Опубликованный адресуемый объект должен быть точным."
      )
    }

    if publishesCandidate {
      let publishedPointer = try Data(
        contentsOf: pointerURL,
        options: [.mappedIfSafe]
      )
      if let confirmedBasePointer {
        XCTAssertNotEqual(
          publishedPointer,
          confirmedBasePointer,
          "После публикации CURRENT должен указывать на новое поколение."
        )
      } else {
        XCTAssertFalse(publishedPointer.isEmpty)
      }
    } else if let confirmedBasePointer {
      XCTAssertEqual(
        try Data(contentsOf: pointerURL, options: [.mappedIfSafe]),
        confirmedBasePointer,
        "До публикации CURRENT должен сохранять прежнее подтверждённое поколение."
      )
    } else {
      XCTAssertFalse(
        FileManager.default.fileExists(atPath: pointerURL.path),
        "До первой публикации пустое хранилище не должно получать CURRENT."
      )
    }
  }

  private func makeCrashWriterProcess(
    storeURL: URL,
    candidateURL: URL,
    checkpoint: MemoryGenerationCommitCheckpoint,
    markerURL: URL
  ) throws -> Process {
    let process = Process()
    process.executableURL = try executableURL(named: "xcrun")
    process.arguments = [
      "xctest",
      "-XCTest",
      "MemoryPopulationTests/testProcessCrashWriter",
      Bundle(for: MemoryPopulationTests.self).bundleURL.path,
    ]
    var environment = ProcessInfo.processInfo.environment
    environment["FUM_MEMORY_CRASH_WRITER_STORE"] = storeURL.path
    environment["FUM_MEMORY_CRASH_WRITER_CANDIDATE"] = candidateURL.path
    environment["FUM_MEMORY_CRASH_WRITER_CHECKPOINT"] = checkpoint.rawValue
    environment["FUM_MEMORY_CRASH_WRITER_MARKER"] = markerURL.path
    process.environment = environment
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    return process
  }

  private func makeCrashRecoveryProcess(
    storeURL: URL,
    resultURL: URL
  ) throws -> Process {
    let process = Process()
    process.executableURL = try executableURL(named: "xcrun")
    process.arguments = [
      "xctest",
      "-XCTest",
      "MemoryPopulationTests/testProcessCrashRecoveryWorker",
      Bundle(for: MemoryPopulationTests.self).bundleURL.path,
    ]
    var environment = ProcessInfo.processInfo.environment
    environment["FUM_MEMORY_CRASH_RECOVERY_STORE"] = storeURL.path
    environment["FUM_MEMORY_CRASH_RECOVERY_RESULT"] = resultURL.path
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
    throw MemoryPopulationError.generationStore(
      "Исполняемый файл \(name) не найден в абсолютных каталогах PATH."
    )
  }

  private func readCASWorkerResult(_ url: URL) throws -> CASWorkerResult {
    try JSONDecoder().decode(CASWorkerResult.self, from: Data(contentsOf: url))
  }

  private func waitForCASWorker(
    _ process: Process,
    workerID: String,
    timeout: Duration = .seconds(30)
  ) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while process.isRunning, clock.now < deadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    if process.isRunning {
      stopCASWorkerIfNeeded(process)
      throw MemoryPopulationError.generationStore(
        "Дочерний процесс \(workerID) не завершился до предельного срока."
      )
    }
    process.waitUntilExit()
    guard process.terminationStatus == EXIT_SUCCESS else {
      throw MemoryPopulationError.generationStore(
        "Дочерний процесс \(workerID) завершился с кодом \(process.terminationStatus)."
      )
    }
  }

  private func waitForFile(
    _ url: URL,
    process: Process,
    timeout: Duration
  ) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !FileManager.default.fileExists(atPath: url.path), clock.now < deadline {
      if !process.isRunning { break }
      Thread.sleep(forTimeInterval: 0.01)
    }
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw MemoryPopulationError.generationStore(
        "Дочерний процесс не достиг контрольной точки межпроцессной блокировки."
      )
    }
  }

  private func waitForCrashCheckpoint(
    _ markerURL: URL,
    checkpoint: MemoryGenerationCommitCheckpoint,
    process: Process,
    timeout: Duration
  ) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !FileManager.default.fileExists(atPath: markerURL.path), clock.now < deadline {
      if !process.isRunning { break }
      Thread.sleep(forTimeInterval: 0.01)
    }
    guard FileManager.default.fileExists(atPath: markerURL.path) else {
      throw MemoryPopulationError.generationStore(
        "Дочерний писатель не достиг аварийной точки \(checkpoint.rawValue)."
      )
    }
    XCTAssertEqual(
      try String(contentsOf: markerURL, encoding: .utf8),
      checkpoint.rawValue
    )
  }

  private func killCrashWriter(
    _ process: Process,
    checkpoint: MemoryGenerationCommitCheckpoint,
    timeout: Duration = .seconds(5)
  ) throws {
    guard process.isRunning else {
      throw MemoryPopulationError.generationStore(
        "Писатель завершился до SIGKILL на точке \(checkpoint.rawValue)."
      )
    }
    guard Darwin.kill(process.processIdentifier, SIGKILL) == 0 else {
      throw MemoryPopulationError.generationStore(
        "Не удалось принудительно завершить писателя на точке \(checkpoint.rawValue)."
      )
    }

    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while process.isRunning, clock.now < deadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    guard !process.isRunning else {
      throw MemoryPopulationError.generationStore(
        "Писатель не завершился после SIGKILL на точке \(checkpoint.rawValue)."
      )
    }
    process.waitUntilExit()
    guard
      process.terminationReason == .uncaughtSignal,
      process.terminationStatus == SIGKILL
    else {
      throw MemoryPopulationError.generationStore(
        "Писатель не подтвердил завершение сигналом SIGKILL на точке \(checkpoint.rawValue)."
      )
    }
  }

  private func assertFileRemainsAbsent(
    _ url: URL,
    process: Process,
    duration: Duration
  ) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: duration)
    while clock.now < deadline {
      guard process.isRunning else {
        throw MemoryPopulationError.generationStore(
          "Дочерний процесс завершился до освобождения межпроцессной блокировки."
        )
      }
      guard !FileManager.default.fileExists(atPath: url.path) else {
        throw MemoryPopulationError.generationStore(
          "Дочерний процесс получил межпроцессную блокировку до её освобождения."
        )
      }
      Thread.sleep(forTimeInterval: 0.01)
    }
  }

  private func stopCASWorkerIfNeeded(_ process: Process) {
    guard process.isRunning else {
      process.waitUntilExit()
      return
    }
    process.terminate()
    let clock = ContinuousClock()
    let terminationDeadline = clock.now.advanced(by: .seconds(1))
    while process.isRunning, clock.now < terminationDeadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    if process.isRunning {
      _ = Darwin.kill(process.processIdentifier, SIGKILL)
    }
    let killDeadline = clock.now.advanced(by: .seconds(1))
    while process.isRunning, clock.now < killDeadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    if !process.isRunning {
      process.waitUntilExit()
    }
  }

  private func generationURL(for sha256: String, storeURL: URL) -> URL {
    storeURL
      .appendingPathComponent("generations", isDirectory: true)
      .appendingPathComponent("\(sha256.dropFirst(7)).json", isDirectory: false)
  }

  private func programWithGUIProjectionSpecification() -> Data {
    Data(
      """
      {
        "schema_version": 1,
        "policy_version": "fum.memory.policy.v1",
        "dataset_id": "gui-projection-v1",
        "events": [
          {
            "id": "event.goal",
            "sequence": 1,
            "operation": "remember",
            "target": "goal",
            "value": "жизнеспособный образец"
          },
          {
            "id": "event.gui-specification",
            "sequence": 2,
            "operation": "remember",
            "target": "gui-projection-specification",
            "value": "проекция снимка памяти в окно"
          },
          {
            "id": "event.plan",
            "sequence": 3,
            "operation": "compose",
            "target": "plan",
            "sources": ["goal", "gui-projection-specification"],
            "separator": ": "
          }
        ]
      }
      """.utf8
    )
  }

  private func temporaryStoreURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("fum-memory-store-\(UUID().uuidString)", isDirectory: true)
  }

  private func legacyGenerationV1Data() throws -> Data {
    let url =
      Bundle.module.url(
        forResource: "generation-v1",
        withExtension: "base64",
        subdirectory: "Фикстуры"
      ) ?? Bundle.module.url(forResource: "generation-v1", withExtension: "base64")
    let fixtureURL = try XCTUnwrap(url)
    let encoded = try Data(contentsOf: fixtureURL, options: [.mappedIfSafe])
    return try XCTUnwrap(
      Data(base64Encoded: encoded, options: [.ignoreUnknownCharacters])
    )
  }
}

extension Array {
  fileprivate var only: Element? {
    count == 1 ? self[0] : nil
  }
}
