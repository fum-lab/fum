import Foundation
import XCTest

@testable import FUMShadowCore

final class ContinuationComparisonTests: XCTestCase {
  func testIdenticalBranchesHaveZeroDistanceAndEqualStructures() throws {
    let configuration = SuffixIndexConfiguration(maxDepth: 6, maxNodes: 5_000)
    let continuation = Data("продолжение".utf8)
    let metrics = try ContinuationComparator.compare(
      human: continuation,
      model: continuation,
      seed: Data("Начало: ".utf8),
      humanConfiguration: configuration,
      modelConfiguration: configuration
    )

    XCTAssertEqual(metrics.commonPrefixBytes, continuation.count)
    XCTAssertEqual(metrics.editDistanceBytes, 0)
    XCTAssertEqual(metrics.normalizedEditDistance, 0, accuracy: 0.000_001)
    XCTAssertEqual(metrics.humanOnlyTransitionWeight, 0)
    XCTAssertEqual(metrics.modelOnlyTransitionWeight, 0)
    XCTAssertEqual(metrics.weightedJaccardSimilarity, 1, accuracy: 0.000_001)
  }

  func testKnownDifferenceHasExpectedByteMetrics() throws {
    let configuration = SuffixIndexConfiguration(maxDepth: 3, maxNodes: 1_000)
    let metrics = try ContinuationComparator.compare(
      human: Data("abc".utf8),
      model: Data("axc".utf8),
      seed: Data("z".utf8),
      humanConfiguration: configuration,
      modelConfiguration: configuration
    )

    XCTAssertEqual(metrics.commonPrefixBytes, 1)
    XCTAssertEqual(metrics.editDistanceBytes, 1)
    XCTAssertEqual(metrics.normalizedEditDistance, 1.0 / 3.0, accuracy: 0.000_001)
    XCTAssertLessThan(metrics.weightedJaccardSimilarity, 1)
  }

  func testConfigurationsMustMatch() {
    XCTAssertThrowsError(
      try ContinuationComparator.compare(
        human: Data("a".utf8),
        model: Data("a".utf8),
        seed: Data(),
        humanConfiguration: .init(maxDepth: 2, maxNodes: 100),
        modelConfiguration: .init(maxDepth: 3, maxNodes: 100)
      )
    ) { error in
      XCTAssertEqual(error as? ContinuationComparisonError, .configurationMismatch)
    }
  }

  func testIncrementalAndBatchContinuationStructuresAreIdentical() {
    let configuration = SuffixIndexConfiguration(maxDepth: 6, maxNodes: 1_000)
    let seed = Data("контекст ".utf8)
    let continuation = Data("ветка".utf8)
    let batch = ContinuationStructure(
      seed: seed,
      continuation: continuation,
      configuration: configuration
    )
    var builder = ContinuationStructureBuilder(seed: seed, configuration: configuration)

    for byte in continuation {
      builder.append(Data([byte]))
    }

    XCTAssertEqual(builder.structure, batch)
  }
}
