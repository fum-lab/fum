import Foundation
import XCTest

@testable import FUMReproducibleMemoryPopulation

final class CanonicalMemoryJSONTests: XCTestCase {
  private struct BoundaryValue: Encodable {
    let z = 9_007_199_254_740_991
    let a = "строка/😀\u{2028}\n\t\"\\\u{0001}"
  }

  private struct FloatingValue: Encodable {
    let value: Double
  }

  private struct DuplicateNestedContainer: Encodable {
    private enum Keys: String, CodingKey {
      case value
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      _ = container.nestedContainer(keyedBy: Keys.self, forKey: .value)
      _ = container.nestedContainer(keyedBy: Keys.self, forKey: .value)
    }
  }

  private struct ExplicitSuperEncoder: Encodable {
    private enum Keys: String, CodingKey {
      case value
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      try container.encode("value", forKey: .value)
      let superEncoder = container.superEncoder()
      var superValue = superEncoder.singleValueContainer()
      try superValue.encode("base")
    }
  }

  private indirect enum NestedObject: Encodable {
    private enum Keys: String, CodingKey {
      case a
    }

    case leaf
    case child(NestedObject)

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      switch self {
      case .leaf:
        break
      case .child(let child):
        try container.encode(child, forKey: .a)
      }
    }
  }

  func testEncoderUsesProfileOrderingEscapingUnicodeAndSafeIntegers() throws {
    let encoded = try CanonicalMemoryJSON.encode(BoundaryValue())
    let expected =
      "{\"a\":\"строка/😀\u{2028}\\n\\t\\\"\\\\\\u0001\",\"z\":9007199254740991}"

    XCTAssertEqual(String(decoding: encoded, as: UTF8.self), expected)
    XCTAssertEqual(CanonicalMemoryJSON.profileID, "fum.memory.canonical-json.v1")
  }

  func testCanonicalizerNormalizesRepresentationAndCanonicalGateRejectsSource() throws {
    let source = Data(
      "{ \"z\" : 9007199254740991, \"a\" : \"строка\\/\\ud83d\\ude00\\u2028\\n\\t\\\"\\\\\\u0001\" }"
        .utf8
    )
    let expected = try CanonicalMemoryJSON.encode(BoundaryValue())

    XCTAssertEqual(try CanonicalMemoryJSON.canonicalize(source), expected)
    XCTAssertThrowsError(try CanonicalMemoryJSON.requireCanonical(source))
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(expected))
  }

  func testProfileRejectsUnsupportedAndAmbiguousValues() throws {
    XCTAssertThrowsError(try CanonicalMemoryJSON.encode(FloatingValue(value: 1.5)))
    XCTAssertThrowsError(try CanonicalMemoryJSON.encode([Optional<String>.none]))
    XCTAssertThrowsError(try CanonicalMemoryJSON.encode([Int64.max]))

    let rejected = [
      #"{"a":null}"#,
      #"{"a":1,"a":1}"#,
      #"{"a":-0}"#,
      #"{"a":-1}"#,
      #"{"a":1.0}"#,
      #"{"a":1e0}"#,
      #"{"a":9007199254740992}"#,
      #"{"ключ":"значение"}"#,
      #"{"a":"\ufdd0"}"#,
    ]
    for input in rejected {
      XCTAssertThrowsError(
        try CanonicalMemoryJSON.canonicalize(Data(input.utf8)),
        "Ожидался отказ для: \(input)"
      )
    }
  }

  func testNestedContainerFailureRemainsVisibleAndSuperKeyDoesNotTrap() throws {
    XCTAssertThrowsError(try CanonicalMemoryJSON.encode(DuplicateNestedContainer()))
    XCTAssertEqual(
      try CanonicalMemoryJSON.encode(ExplicitSuperEncoder()),
      Data(#"{"super":"base","value":"value"}"#.utf8)
    )
  }

  func testWriterAndParserShareTheNormativeDepthBoundary() throws {
    var maximum = NestedObject.leaf
    for _ in 0..<CanonicalMemoryJSON.maximumDepth {
      maximum = .child(maximum)
    }
    let maximumBytes = try CanonicalMemoryJSON.encode(maximum)
    XCTAssertNoThrow(try CanonicalMemoryJSON.requireCanonical(maximumBytes))

    let tooDeep = NestedObject.child(maximum)
    XCTAssertThrowsError(try CanonicalMemoryJSON.encode(tooDeep))
  }

  func testSemanticallyEqualExternalProgramsHashOnlyCanonicalProfileBytes() throws {
    let compact = Data(
      #"{"schema_version":1,"policy_version":"fum.memory.policy.v1","dataset_id":"hash.profile","events":[{"id":"event.one","sequence":1,"operation":"remember","target":"value","value":"текст"}]}"#
        .utf8
    )
    let reordered = Data(
      #"""
      {
        "events": [
          {"value":"текст","target":"value","operation":"remember","sequence":1,"id":"event.one"}
        ],
        "dataset_id": "hash.profile",
        "policy_version": "fum.memory.policy.v1",
        "schema_version": 1
      }
      """#.utf8
    )

    let first = try MemoryPopulationEngine().run(compact)
    let second = try MemoryPopulationEngine().run(reordered)

    XCTAssertEqual(first.inputSHA256, second.inputSHA256)
    XCTAssertEqual(
      first.inputSHA256,
      CanonicalMemoryJSON.sha256(
        try CanonicalMemoryJSON.canonicalize(compact)
      )
    )
  }

  func testTypedProgramBoundaryPreservesDistinctNFCAndNFDPreimages() throws {
    let nfc = Data(
      #"{"schema_version":1,"policy_version":"fum.memory.policy.v1","dataset_id":"unicode.profile","events":[{"id":"event.one","sequence":1,"operation":"remember","target":"value","value":"é"}]}"#
        .utf8
    )
    let nfd = Data(
      #"{"schema_version":1,"policy_version":"fum.memory.policy.v1","dataset_id":"unicode.profile","events":[{"id":"event.one","sequence":1,"operation":"remember","target":"value","value":"é"}]}"#
        .utf8
    )

    let nfcResult = try MemoryPopulationEngine().run(nfc)
    let nfdResult = try MemoryPopulationEngine().run(nfd)

    XCTAssertNotEqual(nfcResult.inputSHA256, nfdResult.inputSHA256)
    XCTAssertEqual(
      nfcResult.inputSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.canonicalize(nfc))
    )
    XCTAssertEqual(
      nfdResult.inputSHA256,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.canonicalize(nfd))
    )
  }
}
