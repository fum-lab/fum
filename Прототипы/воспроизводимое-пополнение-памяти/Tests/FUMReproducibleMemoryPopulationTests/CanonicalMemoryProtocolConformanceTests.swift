import Foundation
import XCTest

@testable import FUMReproducibleMemoryPopulation

final class CanonicalMemoryProtocolConformanceTests: XCTestCase {
  private struct Manifest: Decodable {
    let schemaVersion: Int
    let profile: String
    let accepted: [AcceptedVector]
    let rejected: [RejectedVector]
    let hashes: [HashVector]

    enum CodingKeys: String, CodingKey {
      case schemaVersion = "schema_version"
      case profile
      case accepted
      case rejected
      case hashes
    }
  }

  private struct AcceptedVector: Decodable {
    let id: String
    let carrier: String
    let inputBase64: String?
    let inputBase64File: String?
    let canonicalBase64: String?
    let canonicalBase64File: String?
    let canonicalSHA256: String

    enum CodingKeys: String, CodingKey {
      case id
      case carrier
      case inputBase64 = "input_base64"
      case inputBase64File = "input_base64_file"
      case canonicalBase64 = "canonical_base64"
      case canonicalBase64File = "canonical_base64_file"
      case canonicalSHA256 = "canonical_sha256"
    }
  }

  private struct RejectedVector: Decodable {
    let id: String
    let carrier: String
    let mode: String
    let inputBase64: String

    enum CodingKeys: String, CodingKey {
      case id
      case carrier
      case mode
      case inputBase64 = "input_base64"
    }
  }

  private struct HashVector: Decodable {
    let id: String
    let inputBase64: String
    let sha256: String

    enum CodingKeys: String, CodingKey {
      case id
      case inputBase64 = "input_base64"
      case sha256
    }
  }

  private struct PythonReport: Decodable {
    let profile: String
    let checked: [PythonCheck]
  }

  private struct PythonCheck: Decodable, Equatable {
    let id: String
    let verdict: String
    let sha256: String
  }

  func testSwiftMatchesEverySharedGoldenVector() throws {
    let resources = try resourceDirectory()
    let manifest = try loadManifest(from: resources)
    XCTAssertEqual(manifest.schemaVersion, 1)
    XCTAssertEqual(manifest.profile, CanonicalMemoryJSON.profileID)

    var canonicalByID: [String: Data] = [:]
    for vector in manifest.accepted {
      let expected = try payload(
        inline: vector.canonicalBase64,
        filename: vector.canonicalBase64File,
        resources: resources
      )
      let source: Data
      if vector.inputBase64 != nil || vector.inputBase64File != nil {
        source = try payload(
          inline: vector.inputBase64,
          filename: vector.inputBase64File,
          resources: resources
        )
      } else {
        source = expected
      }
      XCTAssertEqual(
        try CanonicalMemoryJSON.canonicalize(source),
        expected,
        "Swift выдал другие байты для \(vector.id)."
      )
      XCTAssertNoThrow(
        try CanonicalMemoryJSON.requireCanonical(expected),
        "Golden bytes не каноничны для \(vector.id)."
      )
      XCTAssertEqual(
        CanonicalMemoryJSON.sha256(expected),
        vector.canonicalSHA256,
        "Swift выдал другой SHA-256 для \(vector.id)."
      )
      if vector.carrier == "generation" {
        let generation = try JSONDecoder().decode(MemoryGeneration.self, from: expected)
        XCTAssertNoThrow(try validateMemoryGeneration(generation))
      } else if vector.carrier == "event" {
        let event = try JSONDecoder().decode(MemoryInputEvent.self, from: expected)
        XCTAssertEqual(try CanonicalMemoryJSON.encode(event), expected)
        if vector.id == "remember-event-value-boundary" {
          XCTAssertEqual(event.value?.utf8.count, MemoryPopulationPolicy.maximumValueBytes)
          let program = MemoryPopulationProgram(
            schemaVersion: MemoryPopulationPolicy.schemaVersion,
            policyVersion: MemoryPopulationPolicy.version,
            datasetID: "golden.boundary.v1",
            events: [event]
          )
          XCTAssertNoThrow(
            try MemoryPopulationEngine().run(CanonicalMemoryJSON.encode(program))
          )
        }
      } else if vector.carrier == "program" {
        let program = try JSONDecoder().decode(MemoryPopulationProgram.self, from: expected)
        XCTAssertEqual(try CanonicalMemoryJSON.encode(program), expected)
        XCTAssertNoThrow(try MemoryPopulationEngine().run(expected))
      }
      canonicalByID[vector.id] = expected
    }

    for vector in manifest.rejected {
      let source = try XCTUnwrap(
        Data(base64Encoded: vector.inputBase64),
        "Недопустимый Base64 для \(vector.id)."
      )
      switch vector.mode {
      case "invalid":
        XCTAssertThrowsError(
          try CanonicalMemoryJSON.canonicalize(source),
          "Swift должен отклонить \(vector.id)."
        )
      case "noncanonical":
        XCTAssertNotEqual(try CanonicalMemoryJSON.canonicalize(source), source)
        XCTAssertThrowsError(
          try CanonicalMemoryJSON.requireCanonical(source),
          "Swift должен отклонить неканонические байты \(vector.id)."
        )
      default:
        XCTFail("Неизвестный класс отказа \(vector.mode).")
      }
    }

    for vector in manifest.hashes {
      let source = try XCTUnwrap(Data(base64Encoded: vector.inputBase64))
      XCTAssertEqual(CanonicalMemoryJSON.sha256(source), vector.sha256)
    }

    try assertRuntimeEmitsGoldenGenerations(
      initial: try XCTUnwrap(canonicalByID["initial-generation"]),
      continuation: try XCTUnwrap(canonicalByID["continuation-generation"]),
      currentPointer: try XCTUnwrap(canonicalByID["current-pointer"])
    )
  }

  func testIndependentPythonImplementationMatchesTheSharedCorpus() throws {
    let resources = try resourceDirectory()
    let manifest = try loadManifest(from: resources)
    let executable = try pythonExecutable()
    let process = Process()
    process.executableURL = executable
    process.arguments = [
      "-I",
      resources.appendingPathComponent("canonical_memory_json_v1.py").path,
      "--manifest",
      resources.appendingPathComponent("manifest.json").path,
      "--json",
    ]
    var environment = ProcessInfo.processInfo.environment
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    process.environment = environment
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardOutput = standardOutput
    process.standardError = standardError
    try process.run()
    process.waitUntilExit()

    let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
    let diagnostic = String(
      decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )
    XCTAssertEqual(process.terminationStatus, 0, diagnostic)
    let report = try JSONDecoder().decode(PythonReport.self, from: output)
    XCTAssertEqual(report.profile, CanonicalMemoryJSON.profileID)
    let expectedChecks =
      manifest.accepted.map {
        PythonCheck(id: $0.id, verdict: "accepted", sha256: $0.canonicalSHA256)
      }
      + manifest.rejected.map {
        PythonCheck(id: $0.id, verdict: "rejected", sha256: "")
      }
      + manifest.hashes.map {
        PythonCheck(id: $0.id, verdict: "hash", sha256: $0.sha256)
      }
    XCTAssertEqual(Set(expectedChecks.map(\.id)).count, expectedChecks.count)
    XCTAssertEqual(
      report.checked.sorted { $0.id < $1.id },
      expectedChecks.sorted { $0.id < $1.id }
    )
  }

  private func assertRuntimeEmitsGoldenGenerations(
    initial initialBytes: Data,
    continuation continuationBytes: Data,
    currentPointer currentPointerBytes: Data
  ) throws {
    let engine = MemoryPopulationEngine()
    let initial = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    XCTAssertEqual(try CanonicalMemoryJSON.encode(initial), initialBytes)
    let storedInitial = StoredMemoryGeneration(
      generationSHA256: CanonicalMemoryJSON.sha256(initialBytes),
      generation: initial
    )
    let continuation = try engine.generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: storedInitial
    )
    XCTAssertEqual(try CanonicalMemoryJSON.encode(continuation), continuationBytes)

    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-canonical-protocol-\(UUID().uuidString)",
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: root) }
    let store = MemoryGenerationStore(rootURL: root)
    _ = try store.commit(initial)
    _ = try store.commit(continuation)
    XCTAssertEqual(
      try Data(contentsOf: root.appendingPathComponent("CURRENT.json")),
      currentPointerBytes
    )
  }

  private func resourceDirectory() throws -> URL {
    let direct = Bundle.module.url(
      forResource: "КаноническийПротокол-v1",
      withExtension: nil,
      subdirectory: "Фикстуры"
    )
    let fallback = Bundle.module.url(
      forResource: "КаноническийПротокол-v1",
      withExtension: nil
    )
    return try XCTUnwrap(direct ?? fallback)
  }

  private func loadManifest(from resources: URL) throws -> Manifest {
    try JSONDecoder().decode(
      Manifest.self,
      from: Data(contentsOf: resources.appendingPathComponent("manifest.json"))
    )
  }

  private func payload(
    inline: String?,
    filename: String?,
    resources: URL
  ) throws -> Data {
    if let inline {
      return try XCTUnwrap(Data(base64Encoded: inline))
    }
    let filename = try XCTUnwrap(filename)
    XCTAssertEqual(URL(fileURLWithPath: filename).lastPathComponent, filename)
    let encoded = try Data(contentsOf: resources.appendingPathComponent(filename))
    return try XCTUnwrap(Data(base64Encoded: encoded, options: [.ignoreUnknownCharacters]))
  }

  private func pythonExecutable() throws -> URL {
    let entries = ProcessInfo.processInfo.environment["PATH"]?.split(separator: ":") ?? []
    for entry in entries {
      let directory = String(entry)
      guard directory.hasPrefix("/") else { continue }
      let candidate = URL(fileURLWithPath: directory).appendingPathComponent("python3")
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    throw CanonicalMemoryJSONError("python3 не найден в абсолютных каталогах PATH.")
  }
}
