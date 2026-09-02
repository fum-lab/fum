import XCTest

@testable import FUMShadowCore

final class LocalRuntimePolicyTests: XCTestCase {
  func testOllamaEnvironmentIsForcedToLoopbackAndNoHistory() throws {
    let environment = try LocalRuntimePolicy.ollamaEnvironment(
      base: ["OLLAMA_HOST": "https://remote.example"]
    )

    XCTAssertEqual(environment["OLLAMA_HOST"], "127.0.0.1:11434")
    XCTAssertEqual(environment["OLLAMA_NOHISTORY"], "1")
  }

  func testEmptyModelIsRejected() {
    XCTAssertThrowsError(try LocalRuntimePolicy.validateModelName("  "))
  }

  func testKnownSafeLocalModelNamesAreAccepted() throws {
    for model in [
      "qwen3:0.6b",
      "FUM-Shadow-Local:latest",
      "library/qwen_3.0-test:Q8_0",
      "localhost:5000/fum/model:1.0",
    ] {
      XCTAssertNoThrow(try LocalRuntimePolicy.validateModelName(model), model)
    }
  }

  func testFlagLikeAndMalformedModelNamesAreRejected() {
    let invalidNames = [
      "--help",
      "-qwen3",
      " qwen3:0.6b",
      "qwen3:0.6b ",
      "qwen 3",
      "https://example.test/model",
      "qwen//tag",
      "qwen/../tag",
      "qwen:",
      "модель",
      String(repeating: "a", count: 256),
    ]

    for model in invalidNames {
      XCTAssertThrowsError(try LocalRuntimePolicy.validateModelName(model), model) { error in
        XCTAssertEqual(error as? LocalRuntimeError, .invalidModelName)
      }
    }
  }

  func testShellMetacharactersRemainOrdinaryPromptBytes() {
    let prompt = "`touch /tmp/never` $(whoami); \"quoted\"\nстрока"
    let request = OllamaRequestBuilder.request(
      context: prompt,
      model: "local-model",
      horizonBytes: 64
    )

    XCTAssertEqual(request.standardInput, Data(request.prompt.utf8))
    XCTAssertFalse(request.arguments.contains(prompt))
    XCTAssertEqual(request.arguments.prefix(2), ["run", "local-model"])
  }

  func testLocalProcessStreamsStandardInputWithoutShellInterpretation() async throws {
    let input = Data("`touch /tmp/never` $(whoami); строка\n".utf8)
    let runner = LocalProcessRunner()
    let specification = LocalProcessSpecification(
      executableURL: URL(fileURLWithPath: "/bin/cat"),
      arguments: [],
      standardInput: input,
      environment: ProcessInfo.processInfo.environment,
      maxOutputBytes: 4_096,
      timeoutSeconds: 5
    )

    let output = try await runner.collect(specification)

    XCTAssertEqual(output, input)
  }

  func testLocalProcessClipsOutputAtBudget() async throws {
    let runner = LocalProcessRunner()
    let specification = LocalProcessSpecification(
      executableURL: URL(fileURLWithPath: "/usr/bin/printf"),
      arguments: ["abcdef"],
      standardInput: Data(),
      environment: ProcessInfo.processInfo.environment,
      maxOutputBytes: 3,
      timeoutSeconds: 5
    )

    let output = try await runner.collect(specification)

    XCTAssertEqual(output, Data("abc".utf8))
  }

  func testNonzeroProcessExitIsReported() async {
    let runner = LocalProcessRunner()
    let specification = LocalProcessSpecification(
      executableURL: URL(fileURLWithPath: "/usr/bin/false"),
      arguments: [],
      standardInput: Data(),
      environment: ProcessInfo.processInfo.environment,
      maxOutputBytes: 128,
      timeoutSeconds: 5
    )

    do {
      _ = try await runner.collect(specification)
      XCTFail("Expected a process failure")
    } catch let error as LocalRuntimeError {
      guard case .processFailed(let status, _) = error else {
        return XCTFail("Unexpected error: \(error)")
      }
      XCTAssertNotEqual(status, 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
