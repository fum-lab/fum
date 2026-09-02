import Foundation
import XCTest

@testable import FUMPureModelStep

final class ModelStepContractTests: XCTestCase {
  func testValidRequestEchoesLastUserMessageAndReportsUTF8ByteCounts() throws {
    let system = "Отвечай наблюдаемым текстом."
    let user = "Чистый шаг."
    let data = requestData(system: system, user: user, maxOutputBytes: 256)

    let request = try ModelStepJSON.decodeRequest(data)
    let response = try DeterministicEchoProvider().complete(request)

    XCTAssertEqual(response.schemaVersion, 1)
    XCTAssertEqual(response.invocationID, "fixture-v1")
    XCTAssertEqual(response.provider.kind, "stub")
    XCTAssertEqual(response.provider.id, "fum.deterministic-echo.v1")
    XCTAssertEqual(response.status, "completed")
    XCTAssertEqual(response.output.content, user)
    XCTAssertEqual(response.output.finishReason, "stop")
    XCTAssertEqual(response.metrics.inputBytes, system.utf8.count + user.utf8.count)
    XCTAssertEqual(response.metrics.outputBytes, user.utf8.count)
  }

  func testCanonicalResponseIsByteIdenticalAcrossRepeatedCalls() throws {
    let data = requestData(system: "system", user: "repeatable", maxOutputBytes: 64)
    let request = try ModelStepJSON.decodeRequest(data)
    let provider = DeterministicEchoProvider()

    let first = try ModelStepJSON.encodeResponse(provider.complete(request))
    let second = try ModelStepJSON.encodeResponse(provider.complete(request))

    XCTAssertEqual(first, second)
    XCTAssertTrue(String(decoding: first, as: UTF8.self).hasPrefix("{\"input_sha256\":"))
  }

  func testInputHashChangesWithExplicitContext() throws {
    let firstRequest = try ModelStepJSON.decodeRequest(
      requestData(system: "system", user: "first", maxOutputBytes: 64)
    )
    let secondRequest = try ModelStepJSON.decodeRequest(
      requestData(system: "system", user: "second", maxOutputBytes: 64)
    )

    let provider = DeterministicEchoProvider()
    let first = try provider.complete(firstRequest)
    let second = try provider.complete(secondRequest)

    XCTAssertNotEqual(first.inputSHA256, second.inputSHA256)
    XCTAssertTrue(first.inputSHA256.hasPrefix("sha256:"))
    XCTAssertEqual(first.inputSHA256.count, 71)
  }

  func testRejectsToolsAtTheProviderBoundary() {
    let json = """
      {
        "schema_version": 1,
        "invocation_id": "fixture-v1",
        "provider": {
          "kind": "stub",
          "id": "fum.deterministic-echo.v1",
          "model": "deterministic-echo",
          "runtime": "FUMPureModelStep/1"
        },
        "messages": [{"role": "user", "content": "hello"}],
        "response_format": "text",
        "limits": {"max_output_bytes": 64, "timeout_milliseconds": 1000},
        "capabilities": {"tools": false, "files": false, "network": false},
        "tools": []
      }
      """

    assertContractError(Data(json.utf8), code: "unknown_field")
  }

  func testRejectsUnknownMessageFields() {
    let json = """
      {
        "schema_version": 1,
        "invocation_id": "fixture-v1",
        "provider": {
          "kind": "stub",
          "id": "fum.deterministic-echo.v1",
          "model": "deterministic-echo",
          "runtime": "FUMPureModelStep/1"
        },
        "messages": [{"role": "user", "content": "hello", "secret-field-marker": true}],
        "response_format": "text",
        "limits": {"max_output_bytes": 64, "timeout_milliseconds": 1000},
        "capabilities": {"tools": false, "files": false, "network": false}
      }
      """

    assertContractError(
      Data(json.utf8),
      code: "unknown_field",
      messageMustNotContain: "secret-field-marker"
    )
  }

  func testRequiresAtLeastOneUserMessage() {
    let json = """
      {
        "schema_version": 1,
        "invocation_id": "fixture-v1",
        "provider": {
          "kind": "stub",
          "id": "fum.deterministic-echo.v1",
          "model": "deterministic-echo",
          "runtime": "FUMPureModelStep/1"
        },
        "messages": [{"role": "system", "content": "system only"}],
        "response_format": "text",
        "limits": {"max_output_bytes": 64, "timeout_milliseconds": 1000},
        "capabilities": {"tools": false, "files": false, "network": false}
      }
      """

    assertContractError(Data(json.utf8), code: "invalid_request")
  }

  func testRejectsOutputThatExceedsTheDeclaredLimit() throws {
    let request = try ModelStepJSON.decodeRequest(
      requestData(system: "system", user: "four", maxOutputBytes: 3)
    )

    XCTAssertThrowsError(try DeterministicEchoProvider().complete(request)) { error in
      XCTAssertEqual((error as? ModelStepContractError)?.code, "output_limit_exceeded")
    }
  }

  func testRejectsMalformedJSONWithStableCode() {
    assertContractError(Data("{".utf8), code: "invalid_json")
  }

  func testRejectsAnyRequestedEffectCapability() {
    for capability in ["tools", "files", "network"] {
      let capabilities = ["tools", "files", "network"]
        .map { "\"\($0)\": \($0 == capability ? "true" : "false")" }
        .joined(separator: ", ")
      let json = """
        {
          "schema_version": 1,
          "invocation_id": "fixture-v1",
          "provider": {
            "kind": "stub",
            "id": "fum.deterministic-echo.v1",
            "model": "deterministic-echo",
            "runtime": "FUMPureModelStep/1"
          },
          "messages": [{"role": "user", "content": "hello"}],
          "response_format": "text",
          "limits": {"max_output_bytes": 64, "timeout_milliseconds": 1000},
          "capabilities": {
            \(capabilities)
          }
        }
        """

      assertContractError(Data(json.utf8), code: "capability_not_allowed")
    }
  }

  func testRejectsEmptyProviderModelAndRuntimeLikeTheSchema() {
    for emptyField in ["model", "runtime"] {
      var provider: [String: Any] = [
        "kind": "stub",
        "id": "fum.deterministic-echo.v1",
        "model": "deterministic-echo",
        "runtime": "FUMPureModelStep/1",
      ]
      provider[emptyField] = ""
      let object: [String: Any] = [
        "schema_version": 1,
        "invocation_id": "fixture-v1",
        "provider": provider,
        "messages": [["role": "user", "content": "hello"]],
        "response_format": "text",
        "limits": ["max_output_bytes": 64, "timeout_milliseconds": 1_000],
        "capabilities": ["tools": false, "files": false, "network": false],
      ]

      assertContractError(
        try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
        code: "invalid_request"
      )
    }
  }

  func testRejectsProviderMismatch() throws {
    let request = try ModelStepJSON.decodeRequest(
      requestData(
        system: "system",
        user: "content",
        maxOutputBytes: 64,
        providerID: "another.stub.v1"
      )
    )

    XCTAssertThrowsError(try DeterministicEchoProvider().complete(request)) { error in
      XCTAssertEqual((error as? ModelStepContractError)?.code, "provider_mismatch")
    }
  }

  func testShellMetacharactersRemainOpaqueText() throws {
    let user = "$(printf shell-marker); a && b; `ignored`"
    let request = try ModelStepJSON.decodeRequest(
      requestData(system: "echo", user: user, maxOutputBytes: 256)
    )

    let response = try DeterministicEchoProvider().complete(request)

    XCTAssertEqual(response.output.content, user)
  }

  private func requestData(
    system: String,
    user: String,
    maxOutputBytes: Int,
    providerID: String = "fum.deterministic-echo.v1"
  ) -> Data {
    let object: [String: Any] = [
      "schema_version": 1,
      "invocation_id": "fixture-v1",
      "provider": [
        "kind": "stub",
        "id": providerID,
        "model": "deterministic-echo",
        "runtime": "FUMPureModelStep/1",
      ],
      "messages": [
        ["role": "system", "content": system],
        ["role": "user", "content": user],
      ],
      "response_format": "text",
      "limits": [
        "max_output_bytes": maxOutputBytes,
        "timeout_milliseconds": 1_000,
      ],
      "capabilities": [
        "tools": false,
        "files": false,
        "network": false,
      ],
    ]
    return try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }

  private func assertContractError(
    _ data: Data,
    code: String,
    messageMustNotContain: String? = nil
  ) {
    XCTAssertThrowsError(try ModelStepJSON.decodeRequest(data)) { error in
      XCTAssertEqual((error as? ModelStepContractError)?.code, code)
      if let messageMustNotContain {
        XCTAssertFalse(
          (error as? ModelStepContractError)?.message.contains(messageMustNotContain) ?? true
        )
      }
    }
  }
}
