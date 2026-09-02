import Foundation
import XCTest

@testable import FUMShadowCore

final class ModelOutputNormalizerTests: XCTestCase {
  func testFullContextEchoIsRemovedAcrossChunks() throws {
    let context = Data("Человек пишет текст.".utf8)
    var normalizer = ModelOutputStreamNormalizer(
      context: context,
      horizonBytes: 64
    )
    var normalized = Data()

    normalized.append(
      try normalizer.append(Data("Человек пишет ".utf8))
    )
    normalized.append(
      try normalizer.append(Data("текст. Продолжение".utf8))
    )
    normalized.append(try normalizer.finish())

    XCTAssertEqual(normalized, Data(" Продолжение".utf8))
  }

  func testEchoWithoutContinuationIsRejected() throws {
    let context = Data("Замороженный префикс".utf8)
    var normalizer = ModelOutputStreamNormalizer(
      context: context,
      horizonBytes: 64
    )

    XCTAssertNoThrow(try normalizer.append(context))
    XCTAssertThrowsError(try normalizer.finish()) { error in
      XCTAssertEqual(
        error as? LocalRuntimeError,
        .invalidModelOutput(.echoedContext)
      )
    }
  }

  func testLongPartialEchoAtHorizonIsRejectedBeforeItCanBeCounted() {
    let context = Data("abcdefghijklmnopqrstuvwxyz".utf8)
    var normalizer = ModelOutputStreamNormalizer(
      context: context,
      horizonBytes: 8
    )

    XCTAssertThrowsError(try normalizer.append(Data("abcdefgh".utf8))) { error in
      XCTAssertEqual(
        error as? LocalRuntimeError,
        .invalidModelOutput(.echoedContext)
      )
    }
  }

  func testLongPartialEchoIsRejectedWhenLaterBytesArriveInSameChunk() {
    let context = Data("abcdefghijklmnopqrstuvwxyz".utf8)
    var normalizer = ModelOutputStreamNormalizer(
      context: context,
      horizonBytes: 8
    )

    XCTAssertThrowsError(try normalizer.append(Data("abcdefgh-DIVERGED".utf8))) { error in
      XCTAssertEqual(
        error as? LocalRuntimeError,
        .invalidModelOutput(.echoedContext)
      )
    }
  }

  func testObviousOllamaHelpIsRejected() {
    let help = Data(
      """
      Run a model

      Usage:
        ollama run MODEL [PROMPT] [flags]

      Flags:
        -h, --help
      """.utf8
    )
    var normalizer = ModelOutputStreamNormalizer(
      context: Data("Контекст".utf8),
      horizonBytes: 128
    )

    XCTAssertThrowsError(try normalizer.append(help)) { error in
      XCTAssertEqual(
        error as? LocalRuntimeError,
        .invalidModelOutput(.commandHelp)
      )
    }
  }

  func testOrdinaryContinuationStreamsAndIsClippedAtHorizon() throws {
    var normalizer = ModelOutputStreamNormalizer(
      context: Data("Исходный текст".utf8),
      horizonBytes: 8
    )
    var normalized = Data()

    normalized.append(try normalizer.append(Data("Новая ветка".utf8)))
    normalized.append(try normalizer.finish())

    XCTAssertEqual(normalized, Data(Data("Новая ветка".utf8).prefix(8)))
    XCTAssertTrue(normalizer.isComplete)
  }
}
