import Darwin
import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveEpisodeRuntimeTests: XCTestCase {
  func testCreateReplaysOnlyConfirmedCurrentAndExactRepeatIsIdempotent() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let checkpoint = makeCheckpointEvent(passport: passport)
      let command = LiveEpisodeCreateCommand(
        commandID: "command-create",
        passport: passport,
        initialEvents: [checkpoint]
      )

      let first = try runtime.create(command)
      let repeated = try runtime.create(command)
      let replayed = try runtime.replay(LiveEpisodeReplayCommand(commandID: "command-replay"))

      XCTAssertEqual(first.generationSHA256, repeated.generationSHA256)
      XCTAssertEqual(first.state, replayed.state)
      XCTAssertEqual(first.stateSHA256, replayed.stateSHA256)
      let calls = await adapter.callCount()
      XCTAssertEqual(calls, 0)
    }
  }

  func testResumeConfirmsReservationBeforeAdapterAndNeverRepeatsUnresolvedInvocation() async throws
  {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .completed(
          output: "ok",
          charged: LiveBudget(
            calls: 1,
            inputTokens: 1,
            outputTokens: 1,
            wallClockMilliseconds: 1,
            computeUnits: 1,
            moneyMicrounits: 0
          )
        )
      )
      let initialRuntime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try initialRuntime.create(
        LiveEpisodeCreateCommand(
          commandID: "command-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let invocation = makeInvocationCommand(passport: passport)
      let crashRuntime = LiveEpisodeRuntime(
        rootURL: directory,
        modelAdapter: adapter,
        checkpointObserver: { checkpoint, stored in
          XCTAssertEqual(checkpoint, .reservationGenerationConfirmed)
          let restored = try LiveEpisodeGenerationStore(rootURL: directory).loadCurrent()
          XCTAssertEqual(restored?.generationSHA256, stored.generationSHA256)
          XCTAssertEqual(restored?.state.model.budget.reserved, invocation.proposal.reservation)
          throw SyntheticCrash.afterConfirmedReservation
        }
      )

      await assertThrowsErrorAsync(
        try await crashRuntime.resume(
          LiveEpisodeResumeCommand(
            commandID: "command-resume",
            expectedGenerationSHA256: created.generationSHA256,
            action: .invokeModel(invocation)
          )
        )
      ) { error in
        XCTAssertEqual(error as? SyntheticCrash, .afterConfirmedReservation)
      }
      let callsAfterCrash = await adapter.callCount()
      XCTAssertEqual(callsAfterCrash, 0)

      let freshRuntime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let resumed = try await freshRuntime.resume(
        LiveEpisodeResumeCommand(
          commandID: "command-resume-repeat",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      XCTAssertEqual(resumed.status, .providerOutcomeUnresolved)
      let callsAfterResume = await adapter.callCount()
      XCTAssertEqual(callsAfterResume, 0)
      XCTAssertEqual(resumed.state.model.budget.reserved, invocation.proposal.reservation)
    }
  }

  func testUnknownCommandVersionAndInsufficientBudgetAreClosedBeforeAdapter() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 1)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "command-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let first = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "command-first",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(makeInvocationCommand(passport: passport))
        )
      )
      XCTAssertEqual(first.state.model.budget.charged.calls, 1)
      let callsAfterFirst = await adapter.callCount()
      XCTAssertEqual(callsAfterFirst, 1)

      let secondInvocation = makeInvocationCommand(
        passport: passport,
        requestID: "request-b",
        variantID: "variant-b",
        requestEventID: "event-request-b",
        responseEventID: "event-response-b",
        responseID: "response-b",
        budgetCheckpointEventID: "event-budget-b",
        budgetCheckpointID: "checkpoint-budget-b"
      )
      let exhausted = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "command-second",
          expectedGenerationSHA256: first.generationSHA256,
          action: .invokeModel(secondInvocation)
        )
      )
      XCTAssertEqual(exhausted.status, .checkpointed)
      let callsAfterSecond = await adapter.callCount()
      XCTAssertEqual(callsAfterSecond, 1)

      let repeatAdapter = TrapModelAdapter(
        contract: mismatchedContract(for: passport.modelPolicy)
      )
      let repeated = try await LiveEpisodeRuntime(
        rootURL: directory,
        modelAdapter: repeatAdapter
      ).resume(
        LiveEpisodeResumeCommand(
          commandID: "command-second-repeat",
          expectedGenerationSHA256: first.generationSHA256,
          action: .invokeModel(secondInvocation)
        )
      )
      XCTAssertEqual(repeated.status, .alreadyApplied)
      let repeatCalls = await repeatAdapter.callCount()
      XCTAssertEqual(repeatCalls, 0)

      let unknown = LiveEpisodeReplayCommand(schemaVersion: 99, commandID: "command-unknown")
      XCTAssertThrowsError(try runtime.replay(unknown)) { error in
        XCTAssertEqual(
          error as? LiveEpisodeRuntimeError,
          .unsupportedCommandSchema(expected: 1, actual: 99)
        )
      }
    }
  }

  func testExternalCommandsCannotForgeRuntimeOwnedEvents() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let invocation = makeInvocationCommand(passport: passport)
      let request = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: invocation.requestEventID,
        sequence: 1,
        payload: .modelRequestRecorded(
          LiveModelRequestRecorded(proposal: invocation.proposal)
        )
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory)
      XCTAssertThrowsError(
        try runtime.create(
          LiveEpisodeCreateCommand(
            commandID: "forge-create",
            passport: passport,
            initialEvents: [request]
          )
        )
      ) { error in
        XCTAssertTrue(error is LiveEpisodeRuntimeError)
      }
      XCTAssertThrowsError(
        try runtime.inspect(LiveEpisodeInspectCommand(commandID: "still-empty"))
      )
      let initialConfirmation = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-initial-confirmation",
        sequence: 2,
        payload: .generationConfirmed(
          LiveGenerationConfirmed(
            generationID: "initial-generation",
            confirmedThroughSequence: 1,
            stateSHA256: hash("initial-state")
          )
        )
      )
      XCTAssertThrowsError(
        try runtime.create(
          LiveEpisodeCreateCommand(
            commandID: "forge-initial-confirmation",
            passport: passport,
            initialEvents: [makeCheckpointEvent(passport: passport), initialConfirmation]
          )
        )
      )
      XCTAssertThrowsError(
        try runtime.create(
          LiveEpisodeCreateCommand(
            commandID: "forge-duplicate-create",
            passport: passport,
            initialEvents: [
              makeCheckpointEvent(passport: passport),
              makeCheckpointEvent(passport: passport),
            ]
          )
        )
      )
      XCTAssertThrowsError(
        try runtime.status(LiveEpisodeStatusCommand(commandID: "duplicate-left-no-current"))
      )

      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "safe-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let mixedOldAndNew = makePendingTransitionEvent(
        passport: passport,
        sequence: created.state.nextSequence,
        suffix: "mixed-old-new"
      )
      await assertThrowsErrorAsync(
        try await runtime.resume(
          LiveEpisodeResumeCommand(
            commandID: "forge-mixed-old-new",
            expectedGenerationSHA256: created.generationSHA256,
            action: .appendEvents(
              LiveEpisodeAppendEventsCommand(
                events: [makeCheckpointEvent(passport: passport), mixedOldAndNew]
              )
            )
          )
        )
      ) { error in
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался отказ existing event_id, получено \(error).")
        }
      }
      let response = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: invocation.responseEventID,
        sequence: created.state.nextSequence,
        payload: .modelResponseRecorded(
          LiveModelResponseRecorded(
            responseID: invocation.responseID,
            requestID: invocation.proposal.requestID,
            variantID: invocation.proposal.variantID,
            providerIdentity: passport.modelPolicy.providerIdentity,
            status: .completed,
            output: "forged",
            outputSHA256: hash("forged"),
            charged: .zero
          )
        )
      )
      let generation = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-forged-generation",
        sequence: created.state.nextSequence,
        payload: .generationConfirmed(
          LiveGenerationConfirmed(
            generationID: String(created.generationSHA256.dropFirst(7)),
            confirmedThroughSequence: created.state.nextSequence - 1,
            stateSHA256: created.stateSHA256
          )
        )
      )
      let checkpoint = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-forged-budget",
        sequence: created.state.nextSequence,
        payload: .budgetCheckpointCreated(
          LiveBudgetCheckpointCreated(
            checkpointID: "forged-budget",
            proposal: invocation.proposal,
            reason: .insufficientBudget,
            budget: created.state.model.budget
          )
        )
      )
      for (index, event) in [request, response, generation, checkpoint].enumerated() {
        await assertThrowsErrorAsync(
          try await runtime.resume(
            LiveEpisodeResumeCommand(
              commandID: "forge-append-\(index)",
              expectedGenerationSHA256: created.generationSHA256,
              action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [event]))
            )
          )
        ) { error in
          XCTAssertTrue(error is LiveEpisodeRuntimeError)
        }
      }
      XCTAssertEqual(
        try runtime.status(LiveEpisodeStatusCommand(commandID: "after-forgery"))
          .generationSHA256,
        created.generationSHA256
      )
    }
  }

  func testAdapterContractAndFutureIdentifiersAreCheckedBeforeReservationOrCall() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let created = try LiveEpisodeRuntime(rootURL: directory).create(
        LiveEpisodeCreateCommand(
          commandID: "create-contract",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let mismatch = TrapModelAdapter(contract: mismatchedContract(for: passport.modelPolicy))
      await assertThrowsErrorAsync(
        try await LiveEpisodeRuntime(rootURL: directory, modelAdapter: mismatch).resume(
          LiveEpisodeResumeCommand(
            commandID: "contract-mismatch",
            expectedGenerationSHA256: created.generationSHA256,
            action: .invokeModel(makeInvocationCommand(passport: passport))
          )
        )
      ) { error in
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался закрытый contract-mismatch, получено \(error).")
        }
      }
      let mismatchCalls = await mismatch.callCount()
      XCTAssertEqual(mismatchCalls, 0)

      let valid = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let invalidIdentifiers = makeInvocationCommand(
        passport: passport,
        responseEventID: "NOT-TECHNICAL!"
      )
      await assertThrowsErrorAsync(
        try await LiveEpisodeRuntime(rootURL: directory, modelAdapter: valid).resume(
          LiveEpisodeResumeCommand(
            commandID: "invalid-settlement-id",
            expectedGenerationSHA256: created.generationSHA256,
            action: .invokeModel(invalidIdentifiers)
          )
        )
      ) { error in
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался отказ identifier-preflight, получено \(error).")
        }
      }
      let validCalls = await valid.callCount()
      XCTAssertEqual(validCalls, 0)
      XCTAssertEqual(
        try LiveEpisodeRuntime(rootURL: directory).status(
          LiveEpisodeStatusCommand(commandID: "contract-status")
        ).generationSHA256,
        created.generationSHA256
      )
    }
  }

  func testCompletedAndUnknownUsageInvocationsSettleExactlyOnce() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .completed(
          output: "completed",
          charged: LiveBudget(
            calls: 1,
            inputTokens: 2,
            outputTokens: 2,
            wallClockMilliseconds: 10,
            computeUnits: 10,
            moneyMicrounits: 0
          )
        )
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "completed-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let invocation = makeInvocationCommand(passport: passport)
      let first = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "completed-first",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      let firstCalls = await adapter.callCount()
      XCTAssertEqual(firstCalls, 1)
      let trap = TrapModelAdapter(contract: mismatchedContract(for: passport.modelPolicy))
      let repeated = try await LiveEpisodeRuntime(rootURL: directory, modelAdapter: trap).resume(
        LiveEpisodeResumeCommand(
          commandID: "completed-repeat",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      XCTAssertEqual(repeated.status, .alreadyApplied)
      XCTAssertEqual(repeated.state.model.budget.charged, first.state.model.budget.charged)
      let repeatCalls = await trap.callCount()
      XCTAssertEqual(repeatCalls, 0)
    }

    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "timeout-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let invocation = makeInvocationCommand(passport: passport)
      let settled = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "timeout-settled",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      XCTAssertEqual(settled.state.model.budget.charged, invocation.proposal.reservation)
      XCTAssertEqual(settled.state.model.budget.reserved, .zero)
      let repeated = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "timeout-repeat",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      XCTAssertEqual(repeated.status, .alreadyApplied)
      let timeoutCalls = await adapter.callCount()
      XCTAssertEqual(timeoutCalls, 1)
    }
  }

  func testInvalidAdapterEvidenceLeavesDurableUnresolvedReservation() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let adapter = InvalidEvidenceModelAdapter(modelPolicy: passport.modelPolicy)
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "evidence-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let invocation = makeInvocationCommand(passport: passport)
      await assertThrowsErrorAsync(
        try await runtime.resume(
          LiveEpisodeResumeCommand(
            commandID: "evidence-invalid",
            expectedGenerationSHA256: created.generationSHA256,
            action: .invokeModel(invocation)
          )
        )
      ) { error in
        guard case .invalidAdapterResult = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался invalid adapter evidence, получено \(error).")
        }
      }
      let evidenceCalls = await adapter.callCount()
      XCTAssertEqual(evidenceCalls, 1)
      let current = try LiveEpisodeRuntime(rootURL: directory).replay(
        LiveEpisodeReplayCommand(commandID: "evidence-replay")
      )
      XCTAssertEqual(current.state.model.budget.reserved, invocation.proposal.reservation)
      XCTAssertNil(current.state.model.variants.first?.response)

      let trap = TrapModelAdapter(contract: mismatchedContract(for: passport.modelPolicy))
      let repeated = try await LiveEpisodeRuntime(rootURL: directory, modelAdapter: trap).resume(
        LiveEpisodeResumeCommand(
          commandID: "evidence-repeat",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(invocation)
        )
      )
      XCTAssertEqual(repeated.status, .providerOutcomeUnresolved)
      let repeatCalls = await trap.callCount()
      XCTAssertEqual(repeatCalls, 0)
    }
  }

  func testStaleCASPublishesOnlyAnIgnoredOrphanAndKeepsWinnerCurrent() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let checkpoint = makeCheckpointEvent(passport: passport)
      let created = try LiveEpisodeRuntime(rootURL: directory).create(
        LiveEpisodeCreateCommand(
          commandID: "cas-create",
          passport: passport,
          initialEvents: [checkpoint]
        )
      )
      let store = LiveEpisodeGenerationStore(rootURL: directory)
      let winnerEvent = makePendingTransitionEvent(
        passport: passport,
        sequence: created.state.nextSequence,
        suffix: "winner"
      )
      let loserEvent = makePendingTransitionEvent(
        passport: passport,
        sequence: created.state.nextSequence,
        suffix: "loser"
      )
      let winner = try store.commit(
        passport: passport,
        events: created.state.events + [winnerEvent],
        invocations: [],
        expectedPreviousGenerationSHA256: created.generationSHA256
      )
      XCTAssertThrowsError(
        try store.commit(
          passport: passport,
          events: created.state.events + [loserEvent],
          invocations: [],
          expectedPreviousGenerationSHA256: created.generationSHA256
        )
      ) { error in
        guard case .generationConflict = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался stale CAS, получено \(error).")
        }
      }
      let generationFiles = try FileManager.default.contentsOfDirectory(
        at: directory.appendingPathComponent("generations", isDirectory: true),
        includingPropertiesForKeys: nil
      )
      XCTAssertEqual(generationFiles.filter { $0.pathExtension == "json" }.count, 3)
      let replayed = try LiveEpisodeRuntime(rootURL: directory).replay(
        LiveEpisodeReplayCommand(commandID: "cas-replay")
      )
      XCTAssertEqual(replayed.generationSHA256, winner.generationSHA256)
      XCTAssertEqual(
        replayed.state.transition?.declaration.coordinates.transitionID,
        "transition-winner")
    }
  }

  func testAppendIdempotencyRequiresDirectParentAndExactOrderedSuffix() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let runtime = LiveEpisodeRuntime(rootURL: directory)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "append-proof-create",
          passport: passport,
          initialEvents: []
        )
      )
      let checkpoint = makeCheckpointEvent(passport: passport)
      let pending = makePendingTransitionEvent(passport: passport, sequence: 2, suffix: "proof")
      await assertThrowsErrorAsync(
        try await runtime.resume(
          LiveEpisodeResumeCommand(
            commandID: "append-proof-duplicate",
            expectedGenerationSHA256: created.generationSHA256,
            action: .appendEvents(
              LiveEpisodeAppendEventsCommand(events: [checkpoint, checkpoint])
            )
          )
        )
      ) { error in
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался отказ duplicate batch, получено \(error).")
        }
      }
      let exact = LiveEpisodeResumeCommand(
        commandID: "append-proof-exact",
        expectedGenerationSHA256: created.generationSHA256,
        action: .appendEvents(
          LiveEpisodeAppendEventsCommand(events: [checkpoint, pending])
        )
      )
      let advanced = try await runtime.resume(exact)
      XCTAssertEqual(advanced.status, .advanced)
      let repeated = try await runtime.resume(exact)
      XCTAssertEqual(repeated.status, .alreadyApplied)

      let invalidCommands = [
        LiveEpisodeResumeCommand(
          commandID: "append-proof-reversed",
          expectedGenerationSHA256: created.generationSHA256,
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(events: [pending, checkpoint])
          )
        ),
        LiveEpisodeResumeCommand(
          commandID: "append-proof-subset",
          expectedGenerationSHA256: created.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [checkpoint]))
        ),
        LiveEpisodeResumeCommand(
          commandID: "append-proof-fake-parent",
          expectedGenerationSHA256: hash("never-a-parent"),
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(events: [checkpoint, pending])
          )
        ),
      ]
      for command in invalidCommands {
        await assertThrowsErrorAsync(try await runtime.resume(command)) { error in
          guard case .generationConflict = error as? LiveEpisodeRuntimeError else {
            return XCTFail("Ожидался fail-closed stale append, получено \(error).")
          }
        }
      }
    }
  }

  func testCorruptPointerCorruptGenerationAndUnknownPointerVersionFailClosed() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)

      let pointerDirectory = directory.appendingPathComponent("pointer", isDirectory: true)
      _ = try LiveEpisodeRuntime(rootURL: pointerDirectory).create(
        LiveEpisodeCreateCommand(
          commandID: "pointer-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      try Data("not-json".utf8).write(
        to: pointerDirectory.appendingPathComponent("CURRENT.json")
      )
      XCTAssertThrowsError(
        try LiveEpisodeRuntime(rootURL: pointerDirectory).replay(
          LiveEpisodeReplayCommand(commandID: "pointer-corrupt")
        )
      ) { error in
        guard case .corruptGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался corrupt CURRENT, получено \(error).")
        }
      }

      let generationDirectory = directory.appendingPathComponent("generation", isDirectory: true)
      let generated = try LiveEpisodeRuntime(rootURL: generationDirectory).create(
        LiveEpisodeCreateCommand(
          commandID: "generation-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let generationURL =
        generationDirectory
        .appendingPathComponent("generations", isDirectory: true)
        .appendingPathComponent("\(generated.generationSHA256.dropFirst(7)).json")
      try Data("{}".utf8).write(to: generationURL)
      XCTAssertThrowsError(
        try LiveEpisodeRuntime(rootURL: generationDirectory).status(
          LiveEpisodeStatusCommand(commandID: "generation-corrupt")
        )
      ) { error in
        guard case .corruptGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидалось повреждение поколения, получено \(error).")
        }
      }

      let versionDirectory = directory.appendingPathComponent("version", isDirectory: true)
      try FileManager.default.createDirectory(
        at: versionDirectory,
        withIntermediateDirectories: true
      )
      try LiveEpisodeRuntimeJSON.encode(
        TestCurrentPointer(
          schemaVersion: 99,
          canonicalProfile: LiveEpisodeRuntimeJSON.canonicalProfile,
          generationSHA256: hash("unknown-pointer")
        )
      ).write(to: versionDirectory.appendingPathComponent("CURRENT.json"))
      XCTAssertThrowsError(
        try LiveEpisodeRuntime(rootURL: versionDirectory).status(
          LiveEpisodeStatusCommand(commandID: "unknown-pointer-version")
        )
      ) { error in
        guard case .incompatibleGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидалась неизвестная версия CURRENT, получено \(error).")
        }
      }
    }
  }

  func testRuntimeCreatesOnlyExactCurrentConfirmationAndRejectsBatchForgery() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 1)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "confirm-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let first = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "confirm-charge",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(makeInvocationCommand(passport: passport))
        )
      )
      let secondInvocation = makeInvocationCommand(
        passport: passport,
        requestID: "request-confirm-b",
        variantID: "variant-confirm-b",
        requestEventID: "event-request-confirm-b",
        responseEventID: "event-response-confirm-b",
        responseID: "response-confirm-b",
        budgetCheckpointEventID: "event-budget-confirm-b",
        budgetCheckpointID: "checkpoint-budget-confirm-b"
      )
      let checkpointed = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "confirm-checkpoint",
          expectedGenerationSHA256: first.generationSHA256,
          action: .invokeModel(secondInvocation)
        )
      )
      let checkpointedStored = try XCTUnwrap(
        LiveEpisodeGenerationStore(rootURL: directory).loadCurrent()
      )
      let duplicate = makeCheckpointEvent(passport: passport)
      let forged = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-confirm-not-first",
        sequence: checkpointed.state.nextSequence,
        payload: .generationConfirmed(
          LiveGenerationConfirmed(
            generationID: String(checkpointed.generationSHA256.dropFirst(7)),
            confirmedThroughSequence: checkpointed.state.nextSequence - 1,
            stateSHA256: checkpointed.stateSHA256
          )
        )
      )
      XCTAssertThrowsError(
        try LiveEpisodeGenerationStore(rootURL: directory).commit(
          passport: passport,
          events: checkpointed.state.events + [duplicate, forged],
          invocations: checkpointedStored.generation.invocationReceiptJournal.invocations,
          expectedPreviousGenerationSHA256: checkpointed.generationSHA256
        )
      ) { error in
        guard case .incompatibleGeneration = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался отказ confirmation не первым, получено \(error).")
        }
      }

      let confirmed = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "confirm-exact",
          expectedGenerationSHA256: checkpointed.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(eventID: "event-confirm-exact")
          )
        )
      )
      guard case .generationConfirmed(let payload) = confirmed.state.events.last?.payload else {
        return XCTFail("Runtime не сохранил typed generation confirmation.")
      }
      XCTAssertEqual(payload.generationID, String(checkpointed.generationSHA256.dropFirst(7)))
      XCTAssertEqual(payload.confirmedThroughSequence, checkpointed.state.nextSequence - 1)
      XCTAssertEqual(payload.stateSHA256, checkpointed.stateSHA256)

      let repeated = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "confirm-repeat",
          expectedGenerationSHA256: checkpointed.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(eventID: "event-confirm-exact")
          )
        )
      )
      XCTAssertEqual(repeated.status, .alreadyApplied)
    }
  }

  func testReplayIsCanonicalAndCallsNoModelToolGitOrWorkspaceBoundary() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let boundary = BoundarySpyModelAdapter(modelPolicy: passport.modelPolicy)
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: boundary)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "no-call-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let first = try runtime.replay(LiveEpisodeReplayCommand(commandID: "no-call-replay-a"))
      let second = try LiveEpisodeRuntime(rootURL: directory).replay(
        LiveEpisodeReplayCommand(commandID: "no-call-replay-b")
      )
      XCTAssertEqual(first.state, created.state)
      XCTAssertEqual(first.stateSHA256, created.stateSHA256)
      XCTAssertEqual(second.state, first.state)
      XCTAssertEqual(second.stateSHA256, first.stateSHA256)
      let counters = await boundary.counters()
      XCTAssertEqual(counters, BoundaryCounters())
    }
  }

  func testEarlierBudgetCheckpointRepeatAndGlobalCheckpointIDUniqueness() async throws {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 1)
      let adapter = RecordingModelAdapter(
        modelPolicy: passport.modelPolicy,
        result: .unknownUsage
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "multi-budget-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let charged = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "multi-budget-charge",
          expectedGenerationSHA256: created.generationSHA256,
          action: .invokeModel(makeInvocationCommand(passport: passport))
        )
      )
      let invocationB = makeInvocationCommand(
        passport: passport,
        requestID: "request-budget-b",
        variantID: "variant-budget-b",
        requestEventID: "event-request-budget-b",
        responseEventID: "event-response-budget-b",
        responseID: "response-budget-b",
        budgetCheckpointEventID: "event-budget-b",
        budgetCheckpointID: "checkpoint-budget-b"
      )
      let checkpointB = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "multi-budget-b",
          expectedGenerationSHA256: charged.generationSHA256,
          action: .invokeModel(invocationB)
        )
      )
      let invocationC = makeInvocationCommand(
        passport: passport,
        requestID: "request-budget-c",
        variantID: "variant-budget-c",
        requestEventID: "event-request-budget-c",
        responseEventID: "event-response-budget-c",
        responseID: "response-budget-c",
        budgetCheckpointEventID: "event-budget-c",
        budgetCheckpointID: "checkpoint-budget-c"
      )
      let checkpointC = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "multi-budget-c",
          expectedGenerationSHA256: checkpointB.generationSHA256,
          action: .invokeModel(invocationC)
        )
      )
      let repeatB = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "multi-budget-b-repeat",
          expectedGenerationSHA256: charged.generationSHA256,
          action: .invokeModel(invocationB)
        )
      )
      XCTAssertEqual(repeatB.status, .alreadyApplied)
      let calls = await adapter.callCount()
      XCTAssertEqual(calls, 1)

      let reuseB = makeInvocationCommand(
        passport: passport,
        requestID: "request-budget-d",
        variantID: "variant-budget-d",
        requestEventID: "event-request-budget-d",
        responseEventID: "event-response-budget-d",
        responseID: "response-budget-d",
        budgetCheckpointEventID: "event-budget-d",
        budgetCheckpointID: invocationB.budgetCheckpointID
      )
      await assertThrowsErrorAsync(
        try await runtime.resume(
          LiveEpisodeResumeCommand(
            commandID: "multi-budget-reuse-id",
            expectedGenerationSHA256: checkpointC.generationSHA256,
            action: .invokeModel(reuseB)
          )
        )
      ) { error in
        guard case .invalidCommand = error as? LiveEpisodeRuntimeError else {
          return XCTFail("Ожидался глобальный конфликт checkpoint_id, получено \(error).")
        }
      }
    }
  }

  func
    testFreshRuntimeDeterministicallyRestoresPassportBudgetTransitionVariantsSelectionAndTerminal()
    async throws
  {
    try await withScratchDirectory { directory in
      let passport = makePassport(maximumCalls: 2)
      let pending = makePendingTransitionEvent(passport: passport, sequence: 2, suffix: "rich")
      guard case .pendingTransitionDeclared(let declaration) = pending.payload else {
        return XCTFail("Test fixture не создал pending transition.")
      }
      let intentA = LiveUntrustedActionIntent(
        intentID: "intent-rich-a",
        operation: "store_candidate",
        adapterID: "runtime-test-adapter",
        effectClass: "external_write",
        objectID: declaration.coordinates.objectID,
        expectedEffectSHA256: declaration.coordinates.expectedEffectSHA256,
        argumentsSHA256: hash("arguments-rich-a")
      )
      let intentB = LiveUntrustedActionIntent(
        intentID: "intent-rich-b",
        operation: "store_candidate",
        adapterID: "runtime-test-adapter",
        effectClass: "external_write",
        objectID: declaration.coordinates.objectID,
        expectedEffectSHA256: declaration.coordinates.expectedEffectSHA256,
        argumentsSHA256: hash("arguments-rich-b")
      )
      let adapter = QueuedModelAdapter(
        modelPolicy: passport.modelPolicy,
        outcomes: [
          .completed(
            output: try LiveStrictIntentParser.canonicalOutput(for: intentA),
            charged: passport.modelPolicy.perInvocationReservation
          ),
          .completed(
            output: try LiveStrictIntentParser.canonicalOutput(for: intentB),
            charged: passport.modelPolicy.perInvocationReservation
          ),
        ]
      )
      let runtime = LiveEpisodeRuntime(rootURL: directory, modelAdapter: adapter)
      var current = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "rich-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport), pending]
        )
      )

      let invocationA = makeInvocationCommand(
        passport: passport,
        requestID: "request-rich-a",
        variantID: "variant-rich-a",
        requestEventID: "event-request-rich-a",
        responseEventID: "event-response-rich-a",
        responseID: "response-rich-a",
        budgetCheckpointEventID: "event-budget-rich-a",
        budgetCheckpointID: "checkpoint-budget-rich-a"
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-invoke-a",
          expectedGenerationSHA256: current.generationSHA256,
          action: .invokeModel(invocationA)
        )
      )
      let intentEventA = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-intent-rich-a",
        sequence: current.state.nextSequence,
        payload: .untrustedIntentParsed(
          LiveUntrustedIntentParsed(
            variantID: "variant-rich-a",
            sourceResponseID: "response-rich-a",
            intent: intentA
          )
        )
      )
      let verificationEventA = makeVariantVerificationEvent(
        passport: passport,
        sequence: current.state.nextSequence + 1,
        suffix: "rich-a",
        variantID: "variant-rich-a"
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-evidence-a",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(events: [intentEventA, verificationEventA])
          )
        )
      )

      let invocationB = makeInvocationCommand(
        passport: passport,
        requestID: "request-rich-b",
        variantID: "variant-rich-b",
        requestEventID: "event-request-rich-b",
        responseEventID: "event-response-rich-b",
        responseID: "response-rich-b",
        budgetCheckpointEventID: "event-budget-rich-b",
        budgetCheckpointID: "checkpoint-budget-rich-b"
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-invoke-b",
          expectedGenerationSHA256: current.generationSHA256,
          action: .invokeModel(invocationB)
        )
      )
      let intentEventB = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-intent-rich-b",
        sequence: current.state.nextSequence,
        payload: .untrustedIntentParsed(
          LiveUntrustedIntentParsed(
            variantID: "variant-rich-b",
            sourceResponseID: "response-rich-b",
            intent: intentB
          )
        )
      )
      let verificationEventB = makeVariantVerificationEvent(
        passport: passport,
        sequence: current.state.nextSequence + 1,
        suffix: "rich-b",
        variantID: "variant-rich-b"
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-evidence-b",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(events: [intentEventB, verificationEventB])
          )
        )
      )

      let invocationC = makeInvocationCommand(
        passport: passport,
        requestID: "request-rich-c",
        variantID: "variant-rich-c",
        requestEventID: "event-request-rich-c",
        responseEventID: "event-response-rich-c",
        responseID: "response-rich-c",
        budgetCheckpointEventID: "event-budget-rich-c",
        budgetCheckpointID: "checkpoint-budget-rich-c"
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-budget",
          expectedGenerationSHA256: current.generationSHA256,
          action: .invokeModel(invocationC)
        )
      )
      let selectionEvent = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-selection-rich",
        sequence: current.state.nextSequence,
        payload: .modelSelectionRecorded(
          LiveModelSelectionRecorded(
            selectionID: "selection-rich",
            selectedVariantID: "variant-rich-a",
            sourceResponseID: "response-rich-a",
            sourceIntentID: "intent-rich-a",
            consideredVariantIDs: ["variant-rich-a", "variant-rich-b"],
            basisVerificationIDs: ["verification-rich-a", "verification-rich-b"]
          )
        )
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-select",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(
            LiveEpisodeAppendEventsCommand(events: [selectionEvent])
          )
        )
      )
      let confirmedBase = current
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-confirm",
          expectedGenerationSHA256: current.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(eventID: "event-confirm-rich")
          )
        )
      )
      let generationID = String(confirmedBase.generationSHA256.dropFirst(7))
      let continuation = LiveEpisodeEvent(
        episodeID: passport.episodeID,
        eventID: "event-continuation-rich",
        sequence: current.state.nextSequence,
        payload: .continuationDecided(
          LiveContinuationDecided(
            decision: .budgetExhausted,
            generationID: generationID,
            basisEventIDs: [
              "event-budget-rich-c", "event-selection-rich", "event-confirm-rich",
            ],
            reason: "Два варианта приняты; бюджет исчерпан."
          )
        )
      )
      current = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "rich-terminal",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [continuation]))
        )
      )

      let freshRuntime = LiveEpisodeRuntime(rootURL: directory)
      let replayed = try freshRuntime.replay(
        LiveEpisodeReplayCommand(commandID: "rich-fresh-replay")
      )
      let status = try freshRuntime.status(
        LiveEpisodeStatusCommand(commandID: "rich-fresh-status")
      )
      XCTAssertEqual(replayed.generationSHA256, current.generationSHA256)
      XCTAssertEqual(replayed.state, current.state)
      XCTAssertEqual(replayed.state.passport, passport)
      XCTAssertEqual(replayed.state.model.budget.charged.calls, 2)
      XCTAssertEqual(replayed.state.model.budget.reserved, .zero)
      XCTAssertEqual(replayed.state.model.variants.count, 2)
      XCTAssertEqual(replayed.state.model.selection?.selectedVariantID, "variant-rich-a")
      XCTAssertEqual(replayed.state.transition?.phase, .awaitingConfirmation)
      XCTAssertEqual(replayed.state.continuation?.continuation.decision, .budgetExhausted)
      XCTAssertEqual(status.transitionPhase, "awaiting_confirmation")
      XCTAssertEqual(status.terminalOutcome, "budget_exhausted")
      let calls = await adapter.callCount()
      XCTAssertEqual(calls, 2)
    }
  }

  func testProbeProvidesAllFiveVersionedCanonicalJSONCommandsAndFailsClosedWithoutProvider()
    async throws
  {
    try await withScratchDirectory { directory in
      let episode = directory.appendingPathComponent("episode", isDirectory: true)
      let passport = makePassport(maximumCalls: 2)
      let createCommand = LiveEpisodeCreateCommand(
        commandID: "cli-create",
        passport: passport,
        initialEvents: [makeCheckpointEvent(passport: passport)]
      )
      let createResult = try runProbe(
        command: "create",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(createCommand)
      )
      XCTAssertEqual(createResult.status, 0, createResult.diagnostic)
      let created = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeMutationOutput.self,
        from: createResult.output
      )
      XCTAssertEqual(created.schemaVersion, 1)
      XCTAssertEqual(created.command, .create)
      XCTAssertEqual(try LiveEpisodeRuntimeJSON.encode(created), createResult.output)

      let inspectResult = try runProbe(
        command: "inspect",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(
          LiveEpisodeInspectCommand(commandID: "cli-inspect")
        )
      )
      XCTAssertEqual(inspectResult.status, 0, inspectResult.diagnostic)
      let inspected = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeInspectOutput.self,
        from: inspectResult.output
      )
      XCTAssertEqual(inspected.command, .inspect)
      XCTAssertEqual(inspected.stored.generationSHA256, created.generationSHA256)
      XCTAssertEqual(try LiveEpisodeRuntimeJSON.encode(inspected), inspectResult.output)

      let statusResult = try runProbe(
        command: "status",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(
          LiveEpisodeStatusCommand(commandID: "cli-status")
        )
      )
      XCTAssertEqual(statusResult.status, 0, statusResult.diagnostic)
      let status = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeStatusOutput.self,
        from: statusResult.output
      )
      XCTAssertEqual(status.command, .status)
      XCTAssertEqual(status.generationSHA256, created.generationSHA256)

      let pending = makePendingTransitionEvent(
        passport: passport,
        sequence: created.state.nextSequence,
        suffix: "cli"
      )
      let resumeResult = try runProbe(
        command: "resume",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(
          LiveEpisodeResumeCommand(
            commandID: "cli-resume",
            expectedGenerationSHA256: created.generationSHA256,
            action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [pending]))
          )
        )
      )
      XCTAssertEqual(resumeResult.status, 0, resumeResult.diagnostic)
      let resumed = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeMutationOutput.self,
        from: resumeResult.output
      )
      XCTAssertEqual(resumed.command, .resume)
      XCTAssertEqual(resumed.status, .advanced)

      let replayResult = try runProbe(
        command: "replay",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(
          LiveEpisodeReplayCommand(commandID: "cli-replay")
        )
      )
      XCTAssertEqual(replayResult.status, 0, replayResult.diagnostic)
      let replayed = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeReplayOutput.self,
        from: replayResult.output
      )
      XCTAssertEqual(replayed.command, .replay)
      XCTAssertEqual(replayed.generationSHA256, resumed.generationSHA256)
      XCTAssertEqual(try LiveEpisodeRuntimeJSON.encode(replayed), replayResult.output)

      let beforeUnavailable = replayed.generationSHA256
      let unavailable = try runProbe(
        command: "resume",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(
          LiveEpisodeResumeCommand(
            commandID: "cli-provider-unavailable",
            expectedGenerationSHA256: beforeUnavailable,
            action: .invokeModel(makeInvocationCommand(passport: passport))
          )
        )
      )
      XCTAssertEqual(unavailable.status, 2)
      let unavailableError = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeErrorOutput.self,
        from: unavailable.errorOutput
      )
      XCTAssertEqual(unavailableError.code, "invalid_command")
      let afterUnavailable = try runProbe(
        command: "status",
        episode: episode,
        input: Data(#"{"schema_version":1,"command_id":"cli-after-unavailable"}"#.utf8)
      )
      XCTAssertEqual(afterUnavailable.status, 0, afterUnavailable.diagnostic)
      XCTAssertEqual(
        try LiveEpisodeRuntimeJSON.decode(
          LiveEpisodeStatusOutput.self,
          from: afterUnavailable.output
        ).generationSHA256,
        beforeUnavailable
      )

      let unknown = try runProbe(
        command: "status",
        episode: episode,
        input: Data(#"{"schema_version":99,"command_id":"cli-unknown-version"}"#.utf8)
      )
      XCTAssertEqual(unknown.status, 2)
      XCTAssertEqual(
        try LiveEpisodeRuntimeJSON.decode(
          LiveEpisodeErrorOutput.self,
          from: unknown.errorOutput
        ).code,
        "unsupported_command_schema"
      )

      let fixture = try runProbe(arguments: [], input: Data())
      XCTAssertEqual(fixture.status, 0, fixture.diagnostic)
      XCTAssertTrue(
        String(decoding: fixture.output, as: UTF8.self).hasPrefix(
          "live_episode_fixture=passed"
        ))
    }
  }

  func testRealSIGKILLAfterConfirmedReservationRestoresFromCurrentInNewPID() async throws {
    try await withScratchDirectory { directory in
      let episode = directory.appendingPathComponent("episode", isDirectory: true)
      let marker = directory.appendingPathComponent("reservation-marker.json")
      let passport = makePassport(maximumCalls: 2)
      let created = try LiveEpisodeRuntime(rootURL: episode).create(
        LiveEpisodeCreateCommand(
          commandID: "kill-create",
          passport: passport,
          initialEvents: [makeCheckpointEvent(passport: passport)]
        )
      )
      let invocation = makeInvocationCommand(passport: passport)
      let resume = LiveEpisodeResumeCommand(
        commandID: "kill-resume",
        expectedGenerationSHA256: created.generationSHA256,
        action: .invokeModel(invocation)
      )
      let worker = try startProbe(
        command: "resume",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(resume),
        environment: [
          "FUM_LIVE_EPISODE_FAILPOINT": "reservation-generation-confirmed",
          "FUM_LIVE_EPISODE_FAILPOINT_MARKER": marker.path,
        ]
      )
      var workerNeedsKill = true
      defer {
        if workerNeedsKill, worker.process.isRunning {
          _ = Darwin.kill(worker.process.processIdentifier, SIGKILL)
          worker.process.waitUntilExit()
        }
      }
      try waitForFile(marker, process: worker.process, timeout: .seconds(10))
      let markerValue = try LiveEpisodeRuntimeJSON.decode(
        TestFailpointMarker.self,
        from: Data(contentsOf: marker)
      )
      XCTAssertEqual(markerValue.checkpoint, "reservation-generation-confirmed")
      XCTAssertEqual(markerValue.processID, worker.process.processIdentifier)
      XCTAssertNotEqual(markerValue.processID, getpid())
      XCTAssertTrue(worker.process.isRunning)
      XCTAssertEqual(Darwin.kill(worker.process.processIdentifier, SIGKILL), 0)
      try waitForExit(worker.process, timeout: .seconds(5))
      worker.process.waitUntilExit()
      workerNeedsKill = false
      XCTAssertEqual(worker.process.terminationReason, .uncaughtSignal)
      XCTAssertEqual(worker.process.terminationStatus, SIGKILL)

      try FileManager.default.removeItem(at: marker)
      let resumeProcess = try runProbe(
        command: "resume",
        episode: episode,
        input: LiveEpisodeRuntimeJSON.encode(resume)
      )
      XCTAssertEqual(resumeProcess.status, 0, resumeProcess.diagnostic)
      XCTAssertNotEqual(resumeProcess.processID, markerValue.processID)
      let unresolved = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeMutationOutput.self,
        from: resumeProcess.output
      )
      XCTAssertEqual(unresolved.status, .providerOutcomeUnresolved)
      XCTAssertEqual(unresolved.generationSHA256, markerValue.generationSHA256)
      XCTAssertEqual(unresolved.state.model.budget.reserved, invocation.proposal.reservation)
      XCTAssertEqual(unresolved.state.model.budget.charged, .zero)
      XCTAssertFalse(FileManager.default.fileExists(atPath: marker.path))

      let statusProcess = try runProbe(
        command: "status",
        episode: episode,
        input: Data(#"{"schema_version":1,"command_id":"kill-recovery-status"}"#.utf8)
      )
      XCTAssertEqual(statusProcess.status, 0, statusProcess.diagnostic)
      XCTAssertNotEqual(statusProcess.processID, markerValue.processID)
      let status = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeStatusOutput.self,
        from: statusProcess.output
      )
      XCTAssertEqual(status.pendingModelRequestIDs, [invocation.proposal.requestID])
      XCTAssertEqual(status.budget.reserved, invocation.proposal.reservation)
      XCTAssertEqual(status.budget.charged, .zero)
      let generationData = try Data(
        contentsOf:
          episode
          .appendingPathComponent("generations", isDirectory: true)
          .appendingPathComponent("\(status.generationSHA256.dropFirst(7)).json")
      )
      XCTAssertNil(generationData.range(of: Data(invocation.input.utf8)))

      let replayProcess = try runProbe(
        command: "replay",
        episode: episode,
        input: Data(#"{"schema_version":1,"command_id":"kill-recovery-replay"}"#.utf8)
      )
      XCTAssertEqual(replayProcess.status, 0, replayProcess.diagnostic)
      XCTAssertNotEqual(replayProcess.processID, markerValue.processID)
      let replay = try LiveEpisodeRuntimeJSON.decode(
        LiveEpisodeReplayOutput.self,
        from: replayProcess.output
      )
      XCTAssertEqual(replay.state.model.budget.reserved, invocation.proposal.reservation)
      XCTAssertNil(replay.state.model.variants.first?.response)
      XCTAssertFalse(
        FileManager.default.fileExists(
          atPath: episode.appendingPathComponent("reservation-marker.json").path
        ))
    }
  }

  private func makePassport(maximumCalls: Int64) -> LiveEpisodePassport {
    let reservation = LiveBudget(
      calls: 1,
      inputTokens: 8,
      outputTokens: 8,
      wallClockMilliseconds: 500,
      computeUnits: 500,
      moneyMicrounits: 0
    )
    return LiveEpisodePassport(
      episodeID: "episode-runtime-test",
      goal: LiveEpisodeGoal(goalID: "goal-runtime-test", summary: "Проверить runtime."),
      context: LiveEpisodeContext(
        objectID: "context-runtime-test",
        contentSHA256: hash("context"),
        disclosureClass: .synthetic,
        purpose: "runtime_test"
      ),
      modelPolicy: LiveModelPolicy(
        profileID: "fum.runtime-test.v1",
        executionMode: .local,
        providerIdentity: LiveProviderIdentity(
          providerID: "fum.test-provider.v1",
          interfaceID: "fum.test-interface.v1",
          modelID: "test-model",
          runtimeID: "test-runtime"
        ),
        disclosure: LiveDisclosurePolicy(
          allowedClasses: [.synthetic],
          maximumInputBytes: 4_096,
          allowedPurposes: ["runtime_test"]
        ),
        moneyUnit: .none,
        maximumBudget: LiveBudget(
          calls: maximumCalls,
          inputTokens: 8 * maximumCalls,
          outputTokens: 8 * maximumCalls,
          wallClockMilliseconds: 500 * maximumCalls,
          computeUnits: 500 * maximumCalls,
          moneyMicrounits: 0
        ),
        perInvocationReservation: reservation,
        maximumVariants: max(maximumCalls + 1, 2)
      ),
      actionAllowlist: [
        LiveAllowedAction(
          allowanceID: "allow-runtime-test",
          operation: "store_candidate",
          adapterID: "runtime-test-adapter",
          effectClass: "external_write"
        )
      ],
      verificationCriteria: [
        LiveVerificationCriterion(
          criterionID: "criterion-runtime-test",
          subject: "Runtime state",
          verifierID: "runtime-test-verifier",
          expectedResult: "passed"
        )
      ],
      checkpointPolicy: LiveCheckpointPolicy(
        checkpointOnBudgetRejection: true,
        requireCheckpointForTransitionConfirmation: true,
        requireConfirmedGenerationForContinuation: true
      ),
      terminalOutcomes: [.completed, .budgetExhausted, .failed]
    )
  }

  private func mismatchedContract(
    for policy: LiveModelPolicy
  ) -> LiveEpisodeModelAdapterContract {
    let expected = LiveEpisodeModelAdapterContract(modelPolicy: policy)
    return LiveEpisodeModelAdapterContract(
      profileID: expected.profileID,
      executionMode: expected.executionMode,
      providerIdentity: expected.providerIdentity,
      disclosure: expected.disclosure,
      moneyUnit: expected.moneyUnit,
      maximumBudget: expected.maximumBudget,
      perInvocationReservation: expected.perInvocationReservation,
      maximumOutputTokens: expected.maximumOutputTokens + 1,
      timeoutMilliseconds: expected.timeoutMilliseconds,
      maximumComputeUnits: expected.maximumComputeUnits
    )
  }

  private func makeCheckpointEvent(passport: LiveEpisodePassport) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: "event-common-checkpoint",
      sequence: 1,
      payload: .modelCheckpointCreated(
        LiveModelCheckpointCreated(
          checkpointID: "checkpoint-common",
          ancestorSHA256: hash("ancestor")
        )
      )
    )
  }

  private func makePendingTransitionEvent(
    passport: LiveEpisodePassport,
    sequence: Int64,
    suffix: String
  ) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: "event-pending-\(suffix)",
      sequence: sequence,
      payload: .pendingTransitionDeclared(
        LivePendingTransitionDeclared(
          coordinates: LiveTransitionCoordinates(
            episodeID: passport.episodeID,
            transitionID: "transition-\(suffix)",
            objectID: "object-\(suffix)",
            expectedEffectSHA256: hash("effect-\(suffix)")
          ),
          allowanceID: "allow-runtime-test",
          parentCheckpointID: "checkpoint-common"
        )
      )
    )
  }

  private func makeVariantVerificationEvent(
    passport: LiveEpisodePassport,
    sequence: Int64,
    suffix: String,
    variantID: String
  ) -> LiveEpisodeEvent {
    LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: "event-verification-\(suffix)",
      sequence: sequence,
      payload: .verificationRecorded(
        LiveVerificationRecorded(
          verificationID: "verification-\(suffix)",
          criterionID: "criterion-runtime-test",
          scope: .modelVariant,
          subjectID: variantID,
          coordinates: nil,
          status: .passed,
          evidence: LiveEvidenceObject(
            evidenceID: "evidence-\(suffix)",
            evidenceSHA256: hash("evidence-\(suffix)")
          )
        )
      )
    )
  }

  private func makeInvocationCommand(
    passport: LiveEpisodePassport,
    requestID: String = "request-a",
    variantID: String = "variant-a",
    requestEventID: String = "event-request-a",
    responseEventID: String = "event-response-a",
    responseID: String = "response-a",
    budgetCheckpointEventID: String = "event-budget-a",
    budgetCheckpointID: String = "checkpoint-budget-a"
  ) -> LiveEpisodeModelInvocationCommand {
    let input = "runtime input"
    return LiveEpisodeModelInvocationCommand(
      requestEventID: requestEventID,
      responseEventID: responseEventID,
      responseID: responseID,
      budgetCheckpointEventID: budgetCheckpointEventID,
      budgetCheckpointID: budgetCheckpointID,
      proposal: LiveModelInvocationProposal(
        requestID: requestID,
        variantID: variantID,
        parentCheckpointID: "checkpoint-common",
        inputObjectID: "input-\(variantID)",
        inputSHA256: LiveStrictIntentParser.sha256(of: input),
        disclosureClass: .synthetic,
        purpose: "runtime_test",
        reservation: passport.modelPolicy.perInvocationReservation
      ),
      input: input
    )
  }

  private func hash(_ value: String) -> String {
    LiveStrictIntentParser.sha256(of: value)
  }

  private func withScratchDirectory(
    _ body: (URL) async throws -> Void
  ) async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-runtime-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try await body(directory)
  }

  private func runProbe(
    command: String,
    episode: URL,
    input: Data,
    environment: [String: String] = [:]
  ) throws -> ProbeExecution {
    try runProbe(
      arguments: [command, episode.path],
      input: input,
      environment: environment
    )
  }

  private func runProbe(
    arguments: [String],
    input: Data,
    environment: [String: String] = [:]
  ) throws -> ProbeExecution {
    let running = try startProbe(
      arguments: arguments,
      input: input,
      environment: environment
    )
    let processID = running.process.processIdentifier
    running.process.waitUntilExit()
    return ProbeExecution(
      processID: processID,
      status: running.process.terminationStatus,
      output: running.standardOutput.fileHandleForReading.readDataToEndOfFile(),
      errorOutput: running.standardError.fileHandleForReading.readDataToEndOfFile()
    )
  }

  private func startProbe(
    command: String,
    episode: URL,
    input: Data,
    environment: [String: String] = [:]
  ) throws -> RunningProbe {
    try startProbe(
      arguments: [command, episode.path],
      input: input,
      environment: environment
    )
  }

  private func startProbe(
    arguments: [String],
    input: Data,
    environment: [String: String]
  ) throws -> RunningProbe {
    let process = Process()
    process.executableURL = try probeExecutableURL()
    process.arguments = arguments
    var mergedEnvironment = ProcessInfo.processInfo.environment
    for (key, value) in environment { mergedEnvironment[key] = value }
    process.environment = mergedEnvironment
    let standardInput = Pipe()
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardInput = standardInput
    process.standardOutput = standardOutput
    process.standardError = standardError
    try process.run()
    try standardInput.fileHandleForWriting.write(contentsOf: input)
    try standardInput.fileHandleForWriting.close()
    return RunningProbe(
      process: process,
      standardOutput: standardOutput,
      standardError: standardError
    )
  }

  private func probeExecutableURL() throws -> URL {
    let executable =
      Bundle(for: LiveEpisodeRuntimeTests.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("FUMLiveEpisodeProbe")
    guard FileManager.default.isExecutableFile(atPath: executable.path) else {
      throw LiveEpisodeRuntimeError.generationStore(
        "Test executable FUMLiveEpisodeProbe не найден."
      )
    }
    return executable
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
      throw LiveEpisodeRuntimeError.generationStore(
        "Subprocess не достиг failpoint-marker."
      )
    }
  }

  private func waitForExit(_ process: Process, timeout: Duration) throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while process.isRunning, clock.now < deadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
    guard !process.isRunning else {
      throw LiveEpisodeRuntimeError.generationStore(
        "Subprocess не завершился после SIGKILL."
      )
    }
  }
}

private enum SyntheticCrash: Error, Equatable {
  case afterConfirmedReservation
}

private struct TestCurrentPointer: Codable {
  let schemaVersion: Int
  let canonicalProfile: String
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case generationSHA256 = "generation_sha256"
  }
}

private struct TestFailpointMarker: Codable {
  let schemaVersion: Int
  let checkpoint: String
  let processID: Int32
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case checkpoint
    case processID = "process_id"
    case generationSHA256 = "generation_sha256"
  }
}

private struct RunningProbe {
  let process: Process
  let standardOutput: Pipe
  let standardError: Pipe
}

private struct ProbeExecution {
  let processID: Int32
  let status: Int32
  let output: Data
  let errorOutput: Data

  var diagnostic: String {
    String(decoding: errorOutput, as: UTF8.self)
  }
}

private struct BoundaryCounters: Equatable, Sendable {
  var model = 0
  var tool = 0
  var git = 0
  var workspace = 0
}

private actor BoundarySpyModelAdapter: LiveEpisodeModelAdapter {
  nonisolated let contract: LiveEpisodeModelAdapterContract
  private var values = BoundaryCounters()

  init(modelPolicy: LiveModelPolicy) {
    contract = LiveEpisodeModelAdapterContract(modelPolicy: modelPolicy)
  }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult {
    values.model += 1
    return LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: .invalidEvidence("Replay не должен вызывать model boundary.")
    )
  }

  func toolCall() { values.tool += 1 }
  func gitCall() { values.git += 1 }
  func workspaceCall() { values.workspace += 1 }
  func counters() -> BoundaryCounters { values }
}

private actor RecordingModelAdapter: LiveEpisodeModelAdapter {
  nonisolated let contract: LiveEpisodeModelAdapterContract

  private var calls = 0
  private let outcome: LiveEpisodeModelAdapterOutcome

  init(modelPolicy: LiveModelPolicy, result: LiveEpisodeModelAdapterOutcome) {
    contract = LiveEpisodeModelAdapterContract(modelPolicy: modelPolicy)
    outcome = result
  }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult {
    calls += 1
    return LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: outcome
    )
  }

  func callCount() -> Int { calls }
}

private actor QueuedModelAdapter: LiveEpisodeModelAdapter {
  nonisolated let contract: LiveEpisodeModelAdapterContract
  private var outcomes: [LiveEpisodeModelAdapterOutcome]
  private var calls = 0

  init(modelPolicy: LiveModelPolicy, outcomes: [LiveEpisodeModelAdapterOutcome]) {
    contract = LiveEpisodeModelAdapterContract(modelPolicy: modelPolicy)
    self.outcomes = outcomes
  }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult {
    calls += 1
    let outcome =
      outcomes.isEmpty
      ? .invalidEvidence("Test adapter не имеет следующего ответа.") : outcomes.removeFirst()
    return LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: outcome
    )
  }

  func callCount() -> Int { calls }
}

private actor TrapModelAdapter: LiveEpisodeModelAdapter {
  nonisolated let contract: LiveEpisodeModelAdapterContract
  private var calls = 0

  init(contract: LiveEpisodeModelAdapterContract) {
    self.contract = contract
  }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult {
    calls += 1
    return LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: .invalidEvidence("Trap adapter не должен быть вызван.")
    )
  }

  func callCount() -> Int { calls }
}

private actor InvalidEvidenceModelAdapter: LiveEpisodeModelAdapter {
  nonisolated let contract: LiveEpisodeModelAdapterContract
  private var calls = 0

  init(modelPolicy: LiveModelPolicy) {
    contract = LiveEpisodeModelAdapterContract(modelPolicy: modelPolicy)
  }

  func complete(_ request: LiveEpisodeModelAdapterRequest) async -> LiveEpisodeModelAdapterResult {
    calls += 1
    return LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input + "-wrong"),
      providerIdentity: contract.providerIdentity,
      outcome: .completed(output: "untrusted", charged: .zero)
    )
  }

  func callCount() -> Int { calls }
}

private func assertThrowsErrorAsync<T>(
  _ expression: @autoclosure () async throws -> T,
  _ errorHandler: (Error) -> Void
) async {
  do {
    _ = try await expression()
    XCTFail("Ожидался отказ.")
  } catch {
    errorHandler(error)
  }
}
