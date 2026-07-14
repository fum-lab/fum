import Foundation
import XCTest
@testable import FUMShadowCore

final class ContinuationExperimentTests: XCTestCase {
    func testCheckpointRemainsFrozenWhileHumanContinues() throws {
        let prefix = Data("Начало".utf8)
        var experiment = ContinuationExperiment(
            prefix: prefix,
            documentVersion: 7,
            modelIdentity: "fixture/local",
            horizonBytes: 7,
            contextWindowBytes: 64,
            indexConfiguration: .init(maxDepth: 8, maxNodes: 1_000)
        )
        let originalCheckpoint = experiment.checkpoint

        experiment.appendModelChunk(Data(" мира".utf8))
        try experiment.observeDocument(Data("Начало дома".utf8), documentVersion: 8)

        XCTAssertEqual(experiment.checkpoint, originalCheckpoint)
        XCTAssertEqual(experiment.status, .completed)
        XCTAssertEqual(experiment.humanContinuation, Data(" дом".utf8))
        XCTAssertNotNil(experiment.comparison)
    }

    func testEditBeforeCheckpointInvalidatesExperiment() throws {
        var experiment = ContinuationExperiment(
            prefix: Data("Начало".utf8),
            documentVersion: 1,
            modelIdentity: "fixture/local",
            horizonBytes: 3,
            contextWindowBytes: 64,
            indexConfiguration: .init(maxDepth: 8, maxNodes: 1_000)
        )

        try experiment.observeDocument(Data("Иначало".utf8), documentVersion: 2)

        XCTAssertEqual(experiment.status, .invalidated)
        XCTAssertEqual(experiment.invalidationReason, .prefixChanged)
        XCTAssertNil(experiment.comparison)
    }

    func testPredictionIsClippedToFrozenHorizon() {
        var experiment = ContinuationExperiment(
            prefix: Data("x".utf8),
            documentVersion: 1,
            modelIdentity: "fixture/local",
            horizonBytes: 3,
            contextWindowBytes: 64,
            indexConfiguration: .init(maxDepth: 3, maxNodes: 100)
        )

        experiment.appendModelChunk(Data("abcdef".utf8))

        XCTAssertEqual(experiment.modelContinuation, Data("abc".utf8))
    }

    func testContextWindowKeepsValidUTF8Suffix() {
        let prefix = Data("абвгде".utf8)
        let checkpoint = ShadowCheckpoint(
            prefix: prefix,
            documentVersion: 1,
            modelIdentity: "fixture/local",
            horizonBytes: 3,
            contextWindowBytes: 5,
            indexConfiguration: .init(maxDepth: 3, maxNodes: 100)
        )

        XCTAssertNotNil(String(data: checkpoint.modelContext, encoding: .utf8))
        XCTAssertLessThanOrEqual(checkpoint.modelContext.count, 5)
    }

    func testVerifiedEndAppendsAreObservedIncrementally() throws {
        var experiment = ContinuationExperiment(
            prefix: Data("Начало".utf8),
            documentVersion: 1,
            modelIdentity: "local-test",
            horizonBytes: 5,
            contextWindowBytes: 64,
            indexConfiguration: .init(maxDepth: 8, maxNodes: 1_000)
        )

        try experiment.observeAppendedBytes(Data("ab".utf8), documentVersion: 2)
        XCTAssertEqual(experiment.humanContinuation, Data("ab".utf8))
        XCTAssertEqual(experiment.status, .collecting)

        try experiment.observeAppendedBytes(Data("cdef".utf8), documentVersion: 3)
        XCTAssertEqual(experiment.humanContinuation, Data("abcde".utf8))
        XCTAssertEqual(experiment.latestDocumentVersion, 3)
        XCTAssertEqual(experiment.status, .completed)
    }

    func testBothContinuationStructuresGrowBeforeComparisonCompletes() throws {
        var experiment = ContinuationExperiment(
            prefix: Data("seed".utf8),
            documentVersion: 1,
            modelIdentity: "local-test",
            horizonBytes: 8,
            contextWindowBytes: 64,
            indexConfiguration: .init(maxDepth: 4, maxNodes: 1_000)
        )

        experiment.appendModelChunk(Data("model".utf8))
        try experiment.observeAppendedBytes(Data("human".utf8), documentVersion: 2)

        XCTAssertEqual(experiment.status, .collecting)
        XCTAssertEqual(experiment.modelStructure.continuationByteCount, 5)
        XCTAssertEqual(experiment.humanStructure.continuationByteCount, 5)
        XCTAssertFalse(experiment.modelStructure.transitionCounts.isEmpty)
        XCTAssertFalse(experiment.humanStructure.transitionCounts.isEmpty)
    }
}
