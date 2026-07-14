import Foundation
import XCTest
@testable import FUMShadowCore

final class SuffixContextTreeTests: XCTestCase {
    func testKnownBananaTransitions() {
        let configuration = SuffixIndexConfiguration(maxDepth: 4, maxNodes: 1_000)
        let tree = BoundedSuffixContextTree(
            data: Data("banana".utf8),
            configuration: configuration
        )

        XCTAssertEqual(tree.nextByteCount(context: Data("a".utf8), nextByte: ascii("n")), 2)
        XCTAssertEqual(tree.nextByteCount(context: Data("an".utf8), nextByte: ascii("a")), 2)
        XCTAssertEqual(tree.summary.processedBytes, 6)
    }

    func testStreamingAndBatchConstructionAreIdentical() {
        let configuration = SuffixIndexConfiguration(maxDepth: 8, maxNodes: 10_000)
        let data = Data("абракадабра banana".utf8)
        let batch = BoundedSuffixContextTree(data: data, configuration: configuration)
        var streaming = BoundedSuffixContextTree(configuration: configuration)

        for byte in data {
            streaming.append(Data([byte]))
        }

        XCTAssertEqual(streaming.summary, batch.summary)
        XCTAssertEqual(streaming.transitionCounts(), batch.transitionCounts())
    }

    func testNodeBudgetIsNeverExceededAndIsObservable() {
        let configuration = SuffixIndexConfiguration(maxDepth: 16, maxNodes: 4)
        let tree = BoundedSuffixContextTree(
            data: Data("abcdefghijklmnopqrstuvwxyz".utf8),
            configuration: configuration
        )

        XCTAssertLessThanOrEqual(tree.summary.nodeCount, configuration.maxNodes)
        XCTAssertGreaterThan(tree.summary.skippedNodeCreations, 0)
    }

    func testCyrillicBytesProduceDeterministicIndex() {
        let configuration = SuffixIndexConfiguration(maxDepth: 12, maxNodes: 10_000)
        let first = BoundedSuffixContextTree(
            data: Data("мышление мышление".utf8),
            configuration: configuration
        )
        let second = BoundedSuffixContextTree(
            data: Data("мышление мышление".utf8),
            configuration: configuration
        )

        XCTAssertEqual(first.transitionCounts(), second.transitionCounts())
    }

    func testCancellableBuildChecksBeforeWorkAndAtBoundedIntervals() throws {
        let configuration = SuffixIndexConfiguration(maxDepth: 4, maxNodes: 1_000)
        var checks = 0
        let tree = try BoundedSuffixContextTree.buildCancellable(
            data: Data("abcdefgh".utf8),
            configuration: configuration,
            cancellationCheckInterval: 2
        ) {
            checks += 1
        }

        XCTAssertEqual(tree.summary.processedBytes, 8)
        XCTAssertEqual(checks, 5)
    }

    func testCancellableBuildPropagatesCancellationWithoutReturningPartialTree() {
        enum TestCancellation: Error, Equatable {
            case cancelled
        }

        let configuration = SuffixIndexConfiguration(maxDepth: 4, maxNodes: 1_000)
        var checks = 0

        XCTAssertThrowsError(
            try BoundedSuffixContextTree.buildCancellable(
                data: Data("abcdefgh".utf8),
                configuration: configuration,
                cancellationCheckInterval: 2
            ) {
                checks += 1
                if checks == 3 {
                    throw TestCancellation.cancelled
                }
            }
        ) { error in
            XCTAssertEqual(error as? TestCancellation, .cancelled)
        }
        XCTAssertEqual(checks, 3)
    }

    private func ascii(_ character: Character) -> UInt8 {
        String(character).utf8.first!
    }
}
