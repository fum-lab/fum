import Dispatch
import FUMInputCore
import Foundation
import GameController

public final class GCKeyboardSource: MacKeyboardObservationSource, @unchecked Sendable {
  public let sourceID: InputSourceID = .gcKeyboard

  private var keyboard: GCKeyboard?
  private var handler: KeyboardObservationHandler?
  private let timestampNormalizer: MonotonicTimestampNormalizer

  public init(timestampNormalizer: MonotonicTimestampNormalizer = .system) {
    self.timestampNormalizer = timestampNormalizer
  }

  public func start(handler: @escaping KeyboardObservationHandler) throws {
    guard keyboard == nil else {
      throw MacKeyboardSourceError.alreadyRunning
    }
    guard let keyboard = GCKeyboard.coalesced,
      let input = keyboard.keyboardInput
    else {
      throw MacKeyboardSourceError.sourceUnavailable(
        "GCKeyboard.coalesced не предоставляет физическую клавиатуру"
      )
    }
    self.handler = handler
    self.keyboard = keyboard
    input.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
      guard let self else { return }
      self.handler?(
        .init(
          source: .gcKeyboard,
          key: .init(
            deviceID: "coalesced-keyboard",
            codeSpace: .hidUsage,
            usagePage: 0x07,
            usage: UInt32(keyCode.rawValue)
          ),
          state: pressed ? .pressed : .released,
          monotonicNanoseconds: Self.normalizedTimestamp(
            fromNanosecondsSinceStartup: DispatchTime.now().uptimeNanoseconds,
            using: self.timestampNormalizer
          ),
          isAutoRepeat: false
        ))
    }
  }

  public func stop() {
    keyboard?.keyboardInput?.keyChangedHandler = nil
    keyboard = nil
    handler = nil
  }

  static func normalizedTimestamp(
    fromNanosecondsSinceStartup timestamp: UInt64,
    using normalizer: MonotonicTimestampNormalizer
  ) -> UInt64 {
    normalizer.nanoseconds(fromNanosecondsSinceStartup: timestamp)
  }
}
