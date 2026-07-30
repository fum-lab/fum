import Foundation
import XCTest

@testable import FUMPureModelStep

final class LMStudioModelOnlyAdapterTests: XCTestCase {
  func testRecordedResponseProducesVersionedCompletedEnvelopeAndPassport() async throws {
    let transport = RecordedModelOnlyProcessTransport(
      outcome: .completed(Data("Наблюдаемый ответ".utf8))
    )
    let adapter = LMStudioModelOnlyAdapter(
      configuration: configuration(),
      transport: transport
    )

    let result = await adapter.complete(try request())

    XCTAssertEqual(result.schemaVersion, 1)
    XCTAssertEqual(result.status, .completed)
    XCTAssertEqual(result.output?.content, "Наблюдаемый ответ")
    XCTAssertEqual(result.output?.finishReason, "stop")
    XCTAssertEqual(result.passport?.schemaVersion, 1)
    XCTAssertEqual(result.passport?.adapterID, "fum.lm-studio-cli.one-shot.v1")
    XCTAssertEqual(result.passport?.sampling.temperature, "unknown")
    XCTAssertEqual(result.passport?.sampling.topP, "unknown")
    XCTAssertEqual(result.passport?.sampling.topK, "unknown")
    XCTAssertEqual(result.passport?.sampling.seed, "unknown")
    XCTAssertEqual(result.passport?.modelWeightsSHA256, "unknown")
    XCTAssertTrue(result.inputSHA256.hasPrefix("sha256:"))
  }

  func testRecordedTypedFailuresNeverExposeDiagnosticText() async throws {
    let cases: [(ModelOnlyProcessOutcome, ModelOnlyFailureCode)] = [
      (.timedOut, .providerTimedOut),
      (.cancelled, .providerCancelled),
      (.outputLimitExceeded, .outputLimitExceeded),
      (.refused, .providerRefused),
      (.failed, .providerFailed),
      (.unavailable, .providerUnavailable),
    ]

    for (outcome, expectedCode) in cases {
      let result = await LMStudioModelOnlyAdapter(
        configuration: configuration(),
        transport: RecordedModelOnlyProcessTransport(outcome: outcome)
      ).complete(try request())

      XCTAssertEqual(result.status, .rejected)
      XCTAssertEqual(result.failure?.code, expectedCode)
      XCTAssertFalse(
        result.failure?.message.contains(configuration().executableURL.path) ?? true
      )
      XCTAssertFalse(result.failure?.message.contains("secret-marker") ?? true)
      XCTAssertNil(result.output)
    }
  }

  func testUnconfiguredProviderIsRejectedWithoutCallingTransportOrEcho() async throws {
    let transport = RecordingModelOnlyProcessTransport(outcome: .failed)
    let result = await LMStudioModelOnlyAdapter(
      configuration: nil,
      transport: transport
    ).complete(try request())

    let callCount = await transport.callCount
    XCTAssertEqual(result.failure?.code, .providerUnconfigured)
    XCTAssertEqual(callCount, 0)
    XCTAssertNil(result.output)
  }

  func testProviderMismatchIsRejectedBeforeProcessLaunch() async throws {
    let transport = RecordingModelOnlyProcessTransport(
      outcome: .completed(Data("must-not-run".utf8))
    )
    let result = await LMStudioModelOnlyAdapter(
      configuration: configuration(),
      transport: transport
    ).complete(try request(model: "another-model"))

    let callCount = await transport.callCount
    XCTAssertEqual(result.failure?.code, .providerMismatch)
    XCTAssertEqual(callCount, 0)
  }

  func testOneShotCommandContainsNoToolOrFileArgumentsAndRunsOnce() async throws {
    let transport = RecordingModelOnlyProcessTransport(
      outcome: .completed(Data("ok".utf8))
    )
    let result = await LMStudioModelOnlyAdapter(
      configuration: configuration(),
      transport: transport
    ).complete(try request())

    let callCount = await transport.callCount
    let capturedSpecification = await transport.lastSpecification
    XCTAssertEqual(result.status, .completed)
    XCTAssertEqual(callCount, 1)
    let specification = try XCTUnwrap(capturedSpecification)
    XCTAssertEqual(specification.arguments.first, "chat")
    XCTAssertTrue(specification.arguments.contains("--prompt"))
    XCTAssertTrue(specification.arguments.contains("--dont-fetch-catalog"))
    XCTAssertTrue(specification.arguments.contains("-y"))
    XCTAssertFalse(specification.arguments.contains("tools"))
    XCTAssertFalse(specification.arguments.contains("files"))
    XCTAssertFalse(specification.arguments.contains("--stats"))
    XCTAssertEqual(specification.environment["CI"], "1")
    XCTAssertEqual(specification.environment["NO_COLOR"], "1")
    XCTAssertEqual(specification.environment["TERM"], "dumb")
    XCTAssertEqual(specification.maxOutputBytes, 128)
    XCTAssertEqual(specification.timeoutMilliseconds, 1_000)
  }

  func testProviderSpecificArgvLimitAndNULAreTypedRejections() async throws {
    let transport = RecordingModelOnlyProcessTransport(outcome: .failed)
    let nulResult = await LMStudioModelOnlyAdapter(
      configuration: configuration(),
      transport: transport
    ).complete(try request(user: "zero\u{0}byte"))
    let largeResult = await LMStudioModelOnlyAdapter(
      configuration: configuration(),
      transport: transport
    ).complete(try request(user: String(repeating: "x", count: 65_537)))

    let callCount = await transport.callCount
    XCTAssertEqual(nulResult.failure?.code, .providerInputUnsupported)
    XCTAssertEqual(largeResult.failure?.code, .providerInputUnsupported)
    XCTAssertEqual(callCount, 0)
  }

  func testFoundationTransportAcceptsExactLimitAndRejectsLimitPlusOne() async throws {
    let transport = FoundationModelOnlyProcessTransport()
    let printfExecutable = try executableURL(named: "printf")
    let exact = await transport.run(
      ModelOnlyProcessSpecification(
        executableURL: printfExecutable,
        arguments: ["1234"],
        environment: [:],
        maxOutputBytes: 4,
        timeoutMilliseconds: 1_000
      )
    )
    let overflow = await transport.run(
      ModelOnlyProcessSpecification(
        executableURL: printfExecutable,
        arguments: ["12345"],
        environment: [:],
        maxOutputBytes: 4,
        timeoutMilliseconds: 1_000
      )
    )

    XCTAssertEqual(exact, .completed(Data("1234".utf8)))
    XCTAssertEqual(overflow, .outputLimitExceeded)
  }

  func testFoundationTransportDistinguishesTimeoutAndCallerCancellation() async throws {
    let transport = FoundationModelOnlyProcessTransport()
    let sleepExecutable = try executableURL(named: "sleep")
    let timeout = await transport.run(
      ModelOnlyProcessSpecification(
        executableURL: sleepExecutable,
        arguments: ["5"],
        environment: [:],
        maxOutputBytes: 32,
        timeoutMilliseconds: 20
      )
    )
    let task = Task {
      await transport.run(
        ModelOnlyProcessSpecification(
          executableURL: sleepExecutable,
          arguments: ["5"],
          environment: [:],
          maxOutputBytes: 32,
          timeoutMilliseconds: 5_000
        )
      )
    }
    try await Task.sleep(for: .milliseconds(20))
    task.cancel()
    let cancelled = await task.value

    XCTAssertEqual(timeout, .timedOut)
    XCTAssertEqual(cancelled, .cancelled)
  }

  func testLiveLMStudioOneShotWhenExplicitlyConfigured() async throws {
    let environment = ProcessInfo.processInfo.environment
    guard environment["FUM_RUN_LIVE_MODEL_TEST"] == "1" else {
      throw XCTSkip("Живой model-only-вызов включается только явно.")
    }
    guard
      let executable = environment["FUM_LM_STUDIO_EXECUTABLE"],
      let model = environment["FUM_LM_STUDIO_MODEL"],
      let runtime = environment["FUM_LM_STUDIO_RUNTIME"],
      let application = environment["FUM_LM_STUDIO_APPLICATION"]
    else {
      XCTFail("Для явного live-прогона нужен полный паспорт LM Studio.")
      return
    }
    let allowedEnvironment = ["HOME", "PATH", "TMPDIR"].reduce(into: [String: String]()) {
      result, key in
      result[key] = environment[key]
    }
    let adapter = LMStudioModelOnlyAdapter(
      configuration: LMStudioConfiguration(
        executableURL: URL(fileURLWithPath: executable),
        modelIdentifier: model,
        runtimeVersion: runtime,
        applicationVersion: application,
        environment: allowedEnvironment
      )
    )

    let result = await adapter.complete(
      try request(
        model: model,
        user: "Ответь только словом READY.",
        maxOutputBytes: 4_096,
        timeoutMilliseconds: 120_000,
        runtime: runtime
      )
    )

    XCTAssertEqual(result.status, .completed, result.failure?.message ?? "")
    XCTAssertFalse(result.output?.content.isEmpty ?? true)
    XCTAssertEqual(result.passport?.provider.model, model)
    XCTAssertEqual(result.passport?.provider.runtime, runtime)
  }

  private func configuration() -> LMStudioConfiguration {
    LMStudioConfiguration(
      executableURL: URL(fileURLWithPath: "recorded-lms"),
      modelIdentifier: "publisher/model/file.gguf",
      runtimeVersion: "lms/71bd99c",
      applicationVersion: "0.4.20+1",
      environment: ["PATH": "recorded"]
    )
  }

  private func executableURL(named name: String) throws -> URL {
    let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
    for directory in path.split(separator: ":") {
      let candidate = URL(fileURLWithPath: String(directory), isDirectory: true)
        .appendingPathComponent(name)
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    throw XCTSkip("Системная команда \(name) не найдена в PATH.")
  }

  private func request(
    model: String = "publisher/model/file.gguf",
    user: String = "Ответь одним наблюдаемым текстом.",
    maxOutputBytes: Int = 128,
    timeoutMilliseconds: Int = 1_000,
    runtime: String = "lms/71bd99c"
  ) throws -> ModelStepRequest {
    let object: [String: Any] = [
      "schema_version": 1,
      "invocation_id": "lm-studio-recorded-v1",
      "provider": [
        "kind": "local_cli",
        "id": "fum.lm-studio-cli.one-shot.v1",
        "model": model,
        "runtime": runtime,
      ],
      "messages": [
        ["role": "system", "content": "Вывод остаётся инертным текстом."],
        ["role": "user", "content": user],
      ],
      "response_format": "text",
      "limits": [
        "max_output_bytes": maxOutputBytes,
        "timeout_milliseconds": timeoutMilliseconds,
      ],
      "capabilities": ["tools": false, "files": false, "network": false],
    ]
    return try ModelStepJSON.decodeRequest(
      JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    )
  }
}

private actor RecordingModelOnlyProcessTransport: ModelOnlyProcessTransport {
  private(set) var callCount = 0
  private(set) var lastSpecification: ModelOnlyProcessSpecification?
  private let outcome: ModelOnlyProcessOutcome

  init(outcome: ModelOnlyProcessOutcome) {
    self.outcome = outcome
  }

  func run(_ specification: ModelOnlyProcessSpecification) async -> ModelOnlyProcessOutcome {
    callCount += 1
    lastSpecification = specification
    return outcome
  }
}
