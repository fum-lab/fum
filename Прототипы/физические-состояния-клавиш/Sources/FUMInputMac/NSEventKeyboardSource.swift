import AppKit
import CoreGraphics
import FUMInputCore

public final class NSEventKeyboardSource: MacKeyboardObservationSource, @unchecked Sendable {
  public let sourceID: InputSourceID = .nsEvent

  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var handler: KeyboardObservationHandler?
  private let timestampNormalizer: MonotonicTimestampNormalizer

  public init(timestampNormalizer: MonotonicTimestampNormalizer = .system) {
    self.timestampNormalizer = timestampNormalizer
  }

  public func start(
    handler: @escaping KeyboardObservationHandler,
    diagnosticHandler: @escaping KeyboardSourceDiagnosticHandler
  ) throws {
    guard globalMonitor == nil, localMonitor == nil else {
      throw MacKeyboardSourceError.alreadyRunning
    }
    guard CGPreflightListenEventAccess() else {
      throw MacKeyboardSourceError.permissionRequired(
        "для глобального NSEvent-монитора требуется Input Monitoring"
      )
    }
    self.handler = handler
    globalMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.keyDown, .keyUp, .flagsChanged]
    ) { [weak self] event in
      self?.receive(event)
    }
    localMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.keyDown, .keyUp, .flagsChanged]
    ) { [weak self] event in
      self?.receive(event)
      return event
    }
    guard globalMonitor != nil, localMonitor != nil else {
      if let globalMonitor {
        NSEvent.removeMonitor(globalMonitor)
      }
      if let localMonitor {
        NSEvent.removeMonitor(localMonitor)
      }
      globalMonitor = nil
      localMonitor = nil
      self.handler = nil
      throw MacKeyboardSourceError.sourceUnavailable(
        "локальный или глобальный NSEvent-монитор недоступен"
      )
    }
  }

  public func stop() {
    if let globalMonitor {
      NSEvent.removeMonitor(globalMonitor)
    }
    if let localMonitor {
      NSEvent.removeMonitor(localMonitor)
    }
    globalMonitor = nil
    localMonitor = nil
    handler = nil
  }

  private func receive(_ event: NSEvent) {
    let state: PhysicalKeyState?
    let isAutoRepeat: Bool
    let eventKind: KeyboardPlatformEventKind
    switch event.type {
    case .keyDown:
      state = .pressed
      isAutoRepeat = event.isARepeat
      eventKind = .keyDown
    case .keyUp:
      state = .released
      isAutoRepeat = false
      eventKind = .keyUp
    case .flagsChanged:
      state =
        CGEventSource.keyState(
          .hidSystemState,
          key: CGKeyCode(event.keyCode)
        ) ? .pressed : .released
      isAutoRepeat = false
      eventKind = .flagsChanged
    default:
      return
    }
    guard
      let monotonicNanoseconds = Self.normalizedTimestamp(
        fromSecondsSinceStartup: event.timestamp,
        using: timestampNormalizer
      )
    else {
      return
    }
    handler?(
      .init(
        source: .nsEvent,
        key: .init(
          deviceID: "combined-session",
          codeSpace: .macVirtualKeyCode,
          usagePage: 0,
          usage: UInt32(event.keyCode)
        ),
        state: state,
        monotonicNanoseconds: monotonicNanoseconds,
        isAutoRepeat: isAutoRepeat,
        diagnostics: .init(
          platformEventKind: eventKind,
          modifierFlags: Self.modifierFlags(from: event.modifierFlags)
        )
      ))
  }

  static func normalizedTimestamp(
    fromSecondsSinceStartup timestamp: TimeInterval,
    using normalizer: MonotonicTimestampNormalizer
  ) -> UInt64? {
    normalizer.nanoseconds(fromSecondsSinceStartup: timestamp)
  }

  private static func modifierFlags(from flags: NSEvent.ModifierFlags) -> [KeyboardModifierFlag] {
    var result: [KeyboardModifierFlag] = []
    let mappings: [(NSEvent.ModifierFlags, KeyboardModifierFlag)] = [
      (.capsLock, .capsLock),
      (.shift, .shift),
      (.control, .control),
      (.option, .option),
      (.command, .command),
      (.numericPad, .numericPad),
      (.help, .help),
      (.function, .secondaryFn),
    ]
    for (mask, name) in mappings where flags.contains(mask) {
      result.append(name)
    }
    return result
  }
}
