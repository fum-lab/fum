import AppKit
import CoreGraphics
import FUMInputCore

public final class NSEventKeyboardSource: MacKeyboardObservationSource, @unchecked Sendable {
  public let sourceID: InputSourceID = .nsEvent

  private var monitor: Any?
  private var handler: KeyboardObservationHandler?

  public init() {}

  public func start(handler: @escaping KeyboardObservationHandler) throws {
    guard monitor == nil else {
      throw MacKeyboardSourceError.alreadyRunning
    }
    guard CGPreflightListenEventAccess() else {
      throw MacKeyboardSourceError.permissionRequired(
        "для глобального NSEvent-монитора требуется Input Monitoring"
      )
    }
    self.handler = handler
    monitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.keyDown, .keyUp, .flagsChanged]
    ) { [weak self] event in
      self?.receive(event)
    }
    guard monitor != nil else {
      self.handler = nil
      throw MacKeyboardSourceError.sourceUnavailable(
        "глобальный NSEvent-монитор недоступен"
      )
    }
  }

  public func stop() {
    if let monitor {
      NSEvent.removeMonitor(monitor)
    }
    monitor = nil
    handler = nil
  }

  private func receive(_ event: NSEvent) {
    let state: PhysicalKeyState?
    let isAutoRepeat: Bool
    switch event.type {
    case .keyDown:
      state = .pressed
      isAutoRepeat = event.isARepeat
    case .keyUp:
      state = .released
      isAutoRepeat = false
    case .flagsChanged:
      state =
        CGEventSource.keyState(
          .hidSystemState,
          key: CGKeyCode(event.keyCode)
        ) ? .pressed : .released
      isAutoRepeat = false
    default:
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
        monotonicNanoseconds: UInt64(event.timestamp * 1_000_000_000),
        isAutoRepeat: isAutoRepeat
      ))
  }
}
