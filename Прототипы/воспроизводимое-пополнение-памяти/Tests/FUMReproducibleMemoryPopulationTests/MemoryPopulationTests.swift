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

  func testComposeCannotReadUnknownMemory() {
    let input = """
      {
        "schema_version": 1,
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
}
