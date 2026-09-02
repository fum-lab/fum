import Darwin
import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveSingleAgentEpisodeRuntimeTests: XCTestCase {
  func testRecordedRuntimeUsesTwoModelCallsAndOneNoCallBudgetCheckpoint() async throws {
    try await withRunDirectory { runURL in
      let passport = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      XCTAssertEqual(
        passport.episodePassport.terminalOutcomes,
        [.completed, .needsInput, .budgetExhausted, .failed]
      )

      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      let first = try await runtime.advance()
      XCTAssertEqual(first.status, .checkpoint)
      XCTAssertEqual(first.checkpoint, .selectionGenerationConfirmed)
      XCTAssertNil(first.candidateOID)

      let modelState = try inspectState(in: runURL, commandID: "test-model-state")
      XCTAssertEqual(
        modelState.model.variants.map(\.proposal.variantID), ["variant-a", "variant-b"])
      XCTAssertEqual(
        modelState.events.filter { $0.kind == .modelRequestRecorded }.count,
        2
      )
      XCTAssertEqual(
        modelState.events.filter { $0.kind == .modelResponseRecorded }.count,
        2
      )
      XCTAssertEqual(modelState.model.budget.charged.calls, 2)
      XCTAssertEqual(modelState.model.budget.charged.inputTokens, 433)
      XCTAssertEqual(modelState.model.budget.charged.outputTokens, 384)
      XCTAssertEqual(modelState.model.budget.reserved, .zero)
      XCTAssertEqual(modelState.latestBudgetCheckpoint?.eventID, "event-budget-checkpoint")
      XCTAssertEqual(
        modelState.latestBudgetCheckpoint?.checkpoint.checkpointID,
        "checkpoint-budget-exhausted"
      )
      XCTAssertEqual(
        modelState.latestBudgetCheckpoint?.checkpoint.proposal.variantID,
        "variant-c"
      )
      XCTAssertEqual(
        modelState.latestBudgetCheckpoint?.checkpoint.reason,
        .insufficientBudget
      )
      XCTAssertFalse(
        modelState.events.contains(where: { event in
          guard case .modelRequestRecorded(let request) = event.payload else { return false }
          return request.proposal.variantID == "variant-c"
        })
      )

      _ = try publishFirstCheckpointEvidence(
        output: first,
        passport: passport,
        runURL: runURL
      )
      let second = try runCheckpointWorker(
        checkpoint: .candidateObservationGenerationConfirmed,
        runURL: runURL
      )
      XCTAssertEqual(second.status, .checkpoint)
      XCTAssertEqual(second.checkpoint, .candidateObservationGenerationConfirmed)
      XCTAssertEqual(
        second.candidateOID,
        LiveSingleAgentScenarioFactory.candidateCommitOID
      )

      let third = try await runtime.advance()
      XCTAssertEqual(third.status, .completed)
      XCTAssertEqual(third.terminalOutcome, .completed)
      XCTAssertEqual(third.acceptanceVerdict, .accepted)
      XCTAssertNotNil(third.acceptanceProcessID)
      XCTAssertEqual(
        third.candidateOID,
        LiveSingleAgentScenarioFactory.candidateCommitOID
      )

      let finalState = try inspectState(in: runURL, commandID: "test-terminal-state")
      XCTAssertTrue(finalState.isTerminal)
      XCTAssertEqual(finalState.continuation?.continuation.decision, .completed)
      XCTAssertEqual(
        finalState.events.filter { $0.kind == .continuationDecided }.count,
        1
      )
      XCTAssertEqual(
        finalState.events.filter { $0.kind == .modelRequestRecorded }.count,
        2
      )
      XCTAssertEqual(finalState.model.budget.charged.calls, 2)

      let replay = try runtime.replayProjection()
      XCTAssertEqual(replay.terminalOutcome, .completed)
      XCTAssertEqual(replay.chargedBudget.calls, 2)
      XCTAssertEqual(
        replay.eventKinds.filter { $0 == .continuationDecided }.count,
        1
      )

      let repeated = try await runtime.advance()
      XCTAssertEqual(repeated.status, .completed)
      XCTAssertEqual(repeated.generationSHA256, third.generationSHA256)
      XCTAssertEqual(repeated.stateSHA256, third.stateSHA256)
      XCTAssertNil(repeated.acceptanceProcessID)
      let repeatedState = try inspectState(in: runURL, commandID: "test-repeated-terminal")
      XCTAssertEqual(repeatedState, finalState)

      let receiptURL =
        runURL
        .appendingPathComponent(passport.episodeRelativePath, isDirectory: true)
        .appendingPathComponent("git-candidate-acceptance", isDirectory: true)
        .appendingPathComponent(
          "\(LiveSingleAgentScenarioFactory.candidateCommitOID).json",
          isDirectory: false
        )
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: receiptURL)
      )
      let tamperedReceipt = LiveGitCandidateAcceptanceReceipt(
        verdict: receipt.verdict,
        currentGenerationSHA256: "sha256:" + String(repeating: "0", count: 64),
        admissionSHA256: receipt.admissionSHA256,
        passportSHA256: receipt.passportSHA256,
        candidateOID: receipt.candidateOID,
        observation: receipt.observation,
        rejectionCodes: receipt.rejectionCodes
      )
      try tamperedReceipt.validate()
      try LiveEpisodeRuntimeJSON.encode(tamperedReceipt).write(to: receiptURL)

      XCTAssertThrowsError(try runtime.replayProjection())
      do {
        _ = try await runtime.advance()
        XCTFail("Изменённая receipt не должна сохранять терминальную аттестацию.")
      } catch {
        XCTAssertFalse(String(describing: error).isEmpty)
      }
    }
  }

  func testCandidatePhaseRequiresExternalConfirmationWithoutSourceEffect() async throws {
    try await withRunDirectory { runURL in
      let passport = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      let first = try await runtime.advance()
      XCTAssertEqual(first.checkpoint, .selectionGenerationConfirmed)
      _ = try publishCheckpointMarker(output: first, runURL: runURL)
      let stateBefore = try inspectState(
        in: runURL,
        commandID: "test-external-confirmation-state-before"
      )

      do {
        _ = try await runtime.advance()
        XCTFail("Candidate phase не должна начинаться без внешнего подтверждения.")
      } catch {
        XCTAssertFalse(String(describing: error).isEmpty)
      }

      let stateAfter = try inspectState(
        in: runURL,
        commandID: "test-external-confirmation-state-after"
      )
      XCTAssertEqual(stateAfter, stateBefore)
      XCTAssertEqual(stateAfter.transition?.phase, .awaitingConfirmation)
      XCTAssertEqual(stateAfter.model.budget.charged.calls, 2)
      XCTAssertFalse(
        FileManager.default.fileExists(
          atPath: runURL.appendingPathComponent(
            LiveSingleAgentEpisodeSchema.externalConfirmationFileName,
            isDirectory: false
          ).path
        )
      )
      let episodeURL = runURL.appendingPathComponent(
        passport.episodeRelativePath,
        isDirectory: true
      )
      XCTAssertFalse(
        FileManager.default.fileExists(
          atPath: episodeURL.appendingPathComponent(
            LiveGitCandidateRuntimeSchema.cloneRelativePath,
            isDirectory: true
          ).path
        )
      )
      try assertSourceIsExactAndClean(runURL)
    }
  }

  func testCandidatePhaseRejectsUnknownCheckpointMarkerSchema() async throws {
    try await withRunDirectory { runURL in
      let passport = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      let first = try await runtime.advance()
      let observedWorkerProcessID = first.processID + 1
      let marker = LiveSingleAgentCheckpointMarker(
        schemaIdentity: "fum.live_single_agent_episode.unknown_marker",
        schemaVersion: LiveSingleAgentEpisodeSchema.version + 1,
        checkpoint: .selectionGenerationConfirmed,
        processID: observedWorkerProcessID,
        generationSHA256: first.generationSHA256,
        stateSHA256: first.stateSHA256
      )
      let markerURL =
        runURL
        .appendingPathComponent(
          LiveSingleAgentEpisodeSchema.checkpointRelativePath,
          isDirectory: true
        )
        .appendingPathComponent(
          "\(LiveSingleAgentCheckpointID.selectionGenerationConfirmed.rawValue).json",
          isDirectory: false
        )
      try LiveEpisodeRuntimeJSON.encode(marker).write(
        to: markerURL,
        options: [.withoutOverwriting]
      )
      let confirmation = LiveSingleAgentExternalConfirmation(
        harnessProcessID: getpid(),
        observedCheckpoint: marker.checkpoint,
        observedWorkerProcessID: marker.processID,
        generationSHA256: marker.generationSHA256,
        stateSHA256: marker.stateSHA256,
        executionPassportSHA256: try passport.canonicalSHA256()
      )
      try LiveEpisodeRuntimeJSON.encode(confirmation).write(
        to: runURL.appendingPathComponent(
          LiveSingleAgentEpisodeSchema.externalConfirmationFileName,
          isDirectory: false
        ),
        options: [.withoutOverwriting]
      )
      let before = try inspectState(in: runURL, commandID: "test-marker-schema-before")

      do {
        _ = try await runtime.advance()
        XCTFail("Неизвестная схема checkpoint marker не должна открывать переход.")
      } catch {
        XCTAssertFalse(String(describing: error).isEmpty)
      }

      XCTAssertEqual(
        try inspectState(in: runURL, commandID: "test-marker-schema-after"),
        before
      )
      try assertSourceIsExactAndClean(runURL)
    }
  }

  func testAcceptanceOutputRequiresVersionAndStoredReceiptBinding() async throws {
    try await withRunDirectory { runURL in
      let passport = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      let first = try await runtime.advance()
      _ = try publishFirstCheckpointEvidence(
        output: first,
        passport: passport,
        runURL: runURL
      )
      let second = try runCheckpointWorker(
        checkpoint: .candidateObservationGenerationConfirmed,
        runURL: runURL
      )
      XCTAssertEqual(second.checkpoint, .candidateObservationGenerationConfirmed)
      let before = try inspectState(in: runURL, commandID: "test-acceptance-output-before")
      let fakeExecutableURL = runURL.appendingPathComponent(
        "fake-acceptance-probe.sh",
        isDirectory: false
      )
      let invalidReceiptSHA256 = "sha256:" + String(repeating: "0", count: 64)

      for output in [
        LiveGitCandidateAcceptanceOutput(
          schemaVersion: LiveGitCandidateAcceptanceSchema.version + 1,
          commandID: "single-agent-independent-acceptance",
          candidateOID: LiveSingleAgentScenarioFactory.candidateCommitOID,
          verdict: .accepted,
          receiptSHA256: invalidReceiptSHA256
        ),
        LiveGitCandidateAcceptanceOutput(
          commandID: "single-agent-independent-acceptance",
          candidateOID: LiveSingleAgentScenarioFactory.candidateCommitOID,
          verdict: .accepted,
          receiptSHA256: invalidReceiptSHA256
        ),
      ] {
        try writeFakeAcceptanceExecutable(output, to: fakeExecutableURL)
        let fakeRuntime = LiveSingleAgentEpisodeRuntime(
          runDirectoryURL: runURL,
          acceptanceExecutableURL: fakeExecutableURL
        )
        do {
          _ = try await fakeRuntime.advance()
          XCTFail("Несвязанный acceptance-output не должен завершать эпизод.")
        } catch {
          XCTAssertFalse(String(describing: error).isEmpty)
        }
        XCTAssertEqual(
          try inspectState(in: runURL, commandID: "test-acceptance-output-after"),
          before
        )
      }
      try assertSourceIsExactAndClean(runURL)
    }
  }

  func testExecutionPassportDeclaresOnlyScenarioTerminalOutcomes() throws {
    try withRunDirectorySync { runURL in
      let passport = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )

      XCTAssertEqual(
        passport.episodePassport.terminalOutcomes,
        [.completed, .needsInput, .budgetExhausted, .failed]
      )
      XCTAssertFalse(passport.episodePassport.terminalOutcomes.contains(.blocked))
      XCTAssertFalse(passport.episodePassport.terminalOutcomes.contains(.refused))
      XCTAssertFalse(passport.episodePassport.terminalOutcomes.contains(.cancelled))
      XCTAssertNoThrow(try passport.validate())
    }
  }

  func testAutonomousReducerCoversRemainingPassportTerminalOutcomes() throws {
    let fixture = try LiveEpisodeFixture.run()
    let continuationIndex = try XCTUnwrap(
      fixture.events.firstIndex(where: { $0.kind == .continuationDecided })
    )
    guard case .continuationDecided(let original) = fixture.events[continuationIndex].payload else {
      return XCTFail("Фикстура не содержит терминальное решение.")
    }
    let prefix = Array(fixture.events[..<continuationIndex])
    let before = try LiveEpisodeReducer.replay(
      passport: fixture.passport,
      events: prefix
    )

    for decision in [LiveContinuationDecision.needsInput, .failed] {
      let event = LiveEpisodeEvent(
        episodeID: fixture.passport.episodeID,
        eventID: "event-terminal-\(decision.rawValue)",
        sequence: before.nextSequence,
        payload: .continuationDecided(
          LiveContinuationDecided(
            decision: decision,
            generationID: original.generationID,
            basisEventIDs: original.basisEventIDs,
            reason: "Автономное покрытие допустимого терминального исхода."
          )
        )
      )
      let terminal = try LiveEpisodeReducer.applying(event, to: before)
      XCTAssertTrue(terminal.isTerminal)
      XCTAssertEqual(terminal.continuation?.continuation.decision, decision)
      XCTAssertEqual(
        terminal.events.filter { $0.kind == .continuationDecided }.count,
        1
      )
    }
  }

  func testNoncanonicalExecutionPassportFailsClosedBeforeEpisodeEffects() async throws {
    try await withRunDirectory { runURL in
      _ = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      let passportURL = runURL.appendingPathComponent(
        LiveSingleAgentEpisodeSchema.executionPassportFileName,
        isDirectory: false
      )
      var corrupted = try Data(contentsOf: passportURL)
      corrupted.append(0x0A)
      try corrupted.write(to: passportURL)

      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      do {
        _ = try await runtime.advance()
        XCTFail("Неканонический execution-passport не должен запускать runtime.")
      } catch {
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался fail-closed invalidCommand, получено \(error).")
        }
      }

      XCTAssertEqual(try Data(contentsOf: passportURL), corrupted)
      let episodeURL = runURL.appendingPathComponent(
        LiveSingleAgentEpisodeSchema.episodeRelativePath,
        isDirectory: true
      )
      XCTAssertEqual(
        try FileManager.default.contentsOfDirectory(atPath: episodeURL.path),
        []
      )
      try assertSourceIsExactAndClean(runURL)
    }
  }

  func testCorruptCurrentFailsClosedWithoutNewGenerationOrSourceEffect() async throws {
    try await withRunDirectory { runURL in
      _ = try LiveSingleAgentEpisodeRuntime.prepare(
        runDirectoryURL: runURL,
        transportMode: .recorded
      )
      let runtime = LiveSingleAgentEpisodeRuntime(
        runDirectoryURL: runURL,
        acceptanceExecutableURL: try acceptanceExecutableURL()
      )
      let first = try await runtime.advance()
      XCTAssertEqual(first.checkpoint, .selectionGenerationConfirmed)

      let episodeURL = runURL.appendingPathComponent(
        LiveSingleAgentEpisodeSchema.episodeRelativePath,
        isDirectory: true
      )
      let generationDirectoryURL = episodeURL.appendingPathComponent(
        "generations",
        isDirectory: true
      )
      let generationsBefore = try FileManager.default.contentsOfDirectory(
        atPath: generationDirectoryURL.path
      ).sorted()
      let pointerURL = episodeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
      let corruptPointer = Data("not-json".utf8)
      try corruptPointer.write(to: pointerURL)

      do {
        _ = try await runtime.advance()
        XCTFail("Повреждённый CURRENT не должен запускать продолжение.")
      } catch {
        guard case .corruptGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался fail-closed corruptGeneration, получено \(error).")
        }
      }

      XCTAssertEqual(try Data(contentsOf: pointerURL), corruptPointer)
      XCTAssertEqual(
        try FileManager.default.contentsOfDirectory(atPath: generationDirectoryURL.path)
          .sorted(),
        generationsBefore
      )
      try assertSourceIsExactAndClean(runURL)
    }
  }

  private func inspectState(in runURL: URL, commandID: String) throws -> LiveEpisodeState {
    let episodeURL = runURL.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.episodeRelativePath,
      isDirectory: true
    )
    return try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
      LiveEpisodeInspectCommand(commandID: commandID)
    ).stored.state
  }

  @discardableResult
  private func publishCheckpointMarker(
    output: LiveSingleAgentWorkerOutput,
    runURL: URL
  ) throws -> LiveSingleAgentCheckpointMarker {
    let checkpoint = try XCTUnwrap(output.checkpoint)
    let marker = LiveSingleAgentCheckpointMarker(
      checkpoint: checkpoint,
      processID: output.processID,
      generationSHA256: output.generationSHA256,
      stateSHA256: output.stateSHA256
    )
    let destination =
      runURL
      .appendingPathComponent(
        LiveSingleAgentEpisodeSchema.checkpointRelativePath,
        isDirectory: true
      )
      .appendingPathComponent("\(checkpoint.rawValue).json", isDirectory: false)
    try LiveEpisodeRuntimeJSON.encode(marker).write(
      to: destination,
      options: [.withoutOverwriting]
    )
    return marker
  }

  @discardableResult
  private func publishFirstCheckpointEvidence(
    output: LiveSingleAgentWorkerOutput,
    passport: LiveSingleAgentExecutionPassport,
    runURL: URL
  ) throws -> LiveSingleAgentExternalConfirmation {
    let marker = try publishCheckpointMarker(output: output, runURL: runURL)
    XCTAssertEqual(marker.checkpoint, .selectionGenerationConfirmed)
    let confirmation = LiveSingleAgentExternalConfirmation(
      harnessProcessID: getpid(),
      observedCheckpoint: marker.checkpoint,
      observedWorkerProcessID: marker.processID,
      generationSHA256: marker.generationSHA256,
      stateSHA256: marker.stateSHA256,
      executionPassportSHA256: try passport.canonicalSHA256()
    )
    let destination = runURL.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.externalConfirmationFileName,
      isDirectory: false
    )
    try LiveEpisodeRuntimeJSON.encode(confirmation).write(
      to: destination,
      options: [.withoutOverwriting]
    )
    return confirmation
  }

  private func runCheckpointWorker(
    checkpoint: LiveSingleAgentCheckpointID,
    runURL: URL
  ) throws -> LiveSingleAgentWorkerOutput {
    let process = Process()
    process.executableURL = try workerExecutableURL()
    process.arguments = [runURL.path]
    process.currentDirectoryURL = runURL
    process.environment = [
      "PATH": LiveGitSystemRuntime.executableSearchPath,
      "LC_ALL": "C",
    ]
    process.standardInput = FileHandle.nullDevice
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    try process.run()
    var reaped = false
    defer {
      if !reaped, process.isRunning {
        _ = Darwin.kill(process.processIdentifier, SIGCONT)
        process.terminate()
        process.waitUntilExit()
      }
    }

    let markerURL =
      runURL
      .appendingPathComponent(
        LiveSingleAgentEpisodeSchema.checkpointRelativePath,
        isDirectory: true
      )
      .appendingPathComponent("\(checkpoint.rawValue).json", isDirectory: false)
    let deadline = DispatchTime.now().uptimeNanoseconds + 30_000_000_000
    while !FileManager.default.fileExists(atPath: markerURL.path) {
      guard process.isRunning else {
        process.waitUntilExit()
        reaped = true
        let errors = errorPipe.fileHandleForReading.readDataToEndOfFile()
        throw NSError(
          domain: "LiveSingleAgentEpisodeRuntimeTests",
          code: 3,
          userInfo: [
            NSLocalizedDescriptionKey:
              "Worker завершился до checkpoint: \(String(decoding: errors, as: UTF8.self))."
          ]
        )
      }
      guard DispatchTime.now().uptimeNanoseconds < deadline else {
        throw NSError(
          domain: "LiveSingleAgentEpisodeRuntimeTests",
          code: 4,
          userInfo: [NSLocalizedDescriptionKey: "Worker не достиг checkpoint за 30 секунд."]
        )
      }
      Darwin.usleep(10_000)
    }
    let markerData = try Data(contentsOf: markerURL)
    let marker = try LiveEpisodeRuntimeJSON.decode(
      LiveSingleAgentCheckpointMarker.self,
      from: markerData
    )
    guard markerData == (try LiveEpisodeRuntimeJSON.encode(marker)),
      marker.checkpoint == checkpoint,
      marker.processID == process.processIdentifier
    else {
      throw NSError(
        domain: "LiveSingleAgentEpisodeRuntimeTests",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "Worker checkpoint marker неканоничен."]
      )
    }

    XCTAssertEqual(Darwin.kill(process.processIdentifier, SIGCONT), 0)
    process.waitUntilExit()
    reaped = true
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errors = errorPipe.fileHandleForReading.readDataToEndOfFile()
    XCTAssertEqual(process.terminationReason, .exit)
    XCTAssertEqual(process.terminationStatus, 2)
    XCTAssertFalse(errors.isEmpty)
    let output = try LiveEpisodeRuntimeJSON.decode(
      LiveSingleAgentWorkerOutput.self,
      from: outputData
    )
    XCTAssertEqual(output.processID, process.processIdentifier)
    XCTAssertEqual(output.checkpoint, checkpoint)
    XCTAssertEqual(output.generationSHA256, marker.generationSHA256)
    XCTAssertEqual(output.stateSHA256, marker.stateSHA256)
    return output
  }

  private func assertSourceIsExactAndClean(_ runURL: URL) throws {
    let sourceURL = runURL.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.sourceRelativePath,
      isDirectory: true
    )
    let runner = LiveGitProcessRunner()
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

  private func writeFakeAcceptanceExecutable(
    _ output: LiveGitCandidateAcceptanceOutput,
    to destination: URL
  ) throws {
    let outputText = try XCTUnwrap(
      String(data: LiveEpisodeRuntimeJSON.encode(output), encoding: .utf8)
    )
    XCTAssertFalse(outputText.contains("'"))
    let script =
      "#!" + LiveGitSystemRuntime.shellExecutablePath
      + "\nIFS= read -r input || :\nprintf '%s' '\(outputText)'\n"
    try Data(script.utf8).write(to: destination)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o700],
      ofItemAtPath: destination.path
    )
  }

  private func acceptanceExecutableURL() throws -> URL {
    let executable =
      Bundle(for: LiveSingleAgentEpisodeRuntimeTests.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("FUMLiveCandidateAcceptanceProbe", isDirectory: false)
    guard FileManager.default.isExecutableFile(atPath: executable.path) else {
      throw NSError(
        domain: "LiveSingleAgentEpisodeRuntimeTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Acceptance probe executable не найден."]
      )
    }
    return executable
  }

  private func workerExecutableURL() throws -> URL {
    let executable =
      Bundle(for: LiveSingleAgentEpisodeRuntimeTests.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("FUMLiveEpisodeWorker", isDirectory: false)
    guard FileManager.default.isExecutableFile(atPath: executable.path) else {
      throw NSError(
        domain: "LiveSingleAgentEpisodeRuntimeTests",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Episode worker executable не найден."]
      )
    }
    return executable
  }

  private func gitLine(_ data: Data) throws -> String {
    try XCTUnwrap(String(data: data, encoding: .utf8))
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func withRunDirectory(
    _ body: (URL) async throws -> Void
  ) async throws {
    let runURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-single-agent-runtime-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: runURL, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: runURL) }
    try await body(runURL)
  }

  private func withRunDirectorySync(_ body: (URL) throws -> Void) throws {
    let runURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-single-agent-passport-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: runURL, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: runURL) }
    try body(runURL)
  }
}
