import Foundation
import XCTest

@testable import FUMReproducibleMemoryPopulation

final class ContentAddressedGenerationStoreTests: XCTestCase {
  private struct ProbeGeneration: Codable, Equatable {
    let schemaVersion: Int
    let previousGenerationSHA256: String?
    let payload: String

    enum CodingKeys: String, CodingKey {
      case schemaVersion = "schema_version"
      case previousGenerationSHA256 = "previous_generation_sha256"
      case payload
    }
  }

  func testStoresNonMemoryGenerationWithCurrentCASAndIdempotentRetry() throws {
    let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-content-addressed-generation-store-\(UUID().uuidString)",
      isDirectory: true
    )
    defer { try? FileManager.default.removeItem(at: storeURL) }

    let validateGeneration: (Data) throws -> Void = { data in
      try CanonicalMemoryJSON.requireCanonical(data)
      let generation = try JSONDecoder().decode(ProbeGeneration.self, from: data)
      guard generation.schemaVersion == 1,
        try CanonicalMemoryJSON.encode(generation) == data
      else {
        throw ProbeError.invalidGeneration
      }
    }
    let validateLineage: (Data, StoredContentAddressedGeneration?) throws -> Void =
      { candidateData, current in
        let candidate = try JSONDecoder().decode(ProbeGeneration.self, from: candidateData)
        guard candidate.previousGenerationSHA256 == current?.generationSHA256 else {
          throw ProbeError.invalidLineage
        }
      }
    let store = ContentAddressedGenerationStore(
      rootURL: storeURL,
      canonicalProfile: CanonicalMemoryJSON.profileID,
      maximumGenerationBytes: 4_096,
      validateGeneration: validateGeneration,
      validateLineage: validateLineage
    )

    let initialData = try CanonicalMemoryJSON.encode(
      ProbeGeneration(
        schemaVersion: 1,
        previousGenerationSHA256: nil,
        payload: "initial"
      )
    )
    let initial = try store.commit(
      initialData,
      expectedPreviousGenerationSHA256: nil
    )
    XCTAssertEqual(try store.loadCurrent(), initial)

    let continuationData = try CanonicalMemoryJSON.encode(
      ProbeGeneration(
        schemaVersion: 1,
        previousGenerationSHA256: initial.generationSHA256,
        payload: "continuation"
      )
    )
    let continuation = try store.commit(
      continuationData,
      expectedPreviousGenerationSHA256: initial.generationSHA256
    )
    XCTAssertEqual(try store.loadCurrent(), continuation)
    XCTAssertEqual(
      try store.commit(
        continuationData,
        expectedPreviousGenerationSHA256: initial.generationSHA256
      ),
      continuation
    )

    let staleData = try CanonicalMemoryJSON.encode(
      ProbeGeneration(
        schemaVersion: 1,
        previousGenerationSHA256: initial.generationSHA256,
        payload: "stale"
      )
    )
    XCTAssertThrowsError(
      try store.commit(
        staleData,
        expectedPreviousGenerationSHA256: initial.generationSHA256
      )
    ) { error in
      XCTAssertEqual(
        error as? ContentAddressedGenerationStoreError,
        .generationConflict(
          expected: initial.generationSHA256,
          actual: continuation.generationSHA256
        )
      )
    }
    XCTAssertEqual(try store.loadCurrent(), continuation)
  }

  private enum ProbeError: Error {
    case invalidGeneration
    case invalidLineage
  }
}
