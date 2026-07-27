import Foundation
import XCTest

@testable import FUMReproducibleMemoryPopulation

final class MemoryPopulationTests: XCTestCase {
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
    XCTAssertEqual(continued.schemaVersion, 2)
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

    XCTAssertEqual(generation.schemaVersion, 2)
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
      "{\"generation_sha256\":\"\(legacySHA256)\",\"schema_version\":1}".utf8
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
