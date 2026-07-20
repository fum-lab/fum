import CoreFoundation
import CoreGraphics
import FUMInputCore

public final class CGEventTapKeyboardSource: MacKeyboardObservationSource, @unchecked Sendable {
  public let sourceID: InputSourceID = .cgEventTap

  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var handler: KeyboardObservationHandler?
  private let timestampNormalizer: MonotonicTimestampNormalizer

  public init(timestampNormalizer: MonotonicTimestampNormalizer = .system) {
    self.timestampNormalizer = timestampNormalizer
  }

  public func start(handler: @escaping KeyboardObservationHandler) throws {
    guard eventTap == nil else {
      throw MacKeyboardSourceError.alreadyRunning
    }
    guard CGPreflightListenEventAccess() else {
      throw MacKeyboardSourceError.permissionRequired(
        "для CGEventTap требуется разрешение Input Monitoring"
      )
    }
    let mask = Self.mask(for: [.keyDown, .keyUp, .flagsChanged])
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: mask,
        callback: cgKeyboardEventTapCallback,
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    else {
      throw MacKeyboardSourceError.sourceUnavailable(
        "CGEventTap не удалось создать"
      )
    }
    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
    self.handler = handler
    self.eventTap = eventTap
    self.runLoopSource = source
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  public func stop() {
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }
    runLoopSource = nil
    eventTap = nil
    handler = nil
  }

  fileprivate func receive(type: CGEventType, event: CGEvent) {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return
    }
    let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
    let kind: CGKeyboardEventKind
    let queriedState: Bool?
    switch type {
    case .keyDown:
      kind = .keyDown
      queriedState = nil
    case .keyUp:
      kind = .keyUp
      queriedState = nil
    case .flagsChanged:
      kind = .flagsChanged
      queriedState = CGEventSource.keyState(
        .hidSystemState,
        key: CGKeyCode(keyCode)
      )
    default:
      return
    }
    let isAutoRepeat =
      type == .keyDown
      && event.getIntegerValueField(.keyboardEventAutorepeat) != 0
    guard
      let observation = CGEventObservationFactory.keyboardObservation(
        type: kind,
        virtualKeyCode: keyCode,
        monotonicNanoseconds: Self.normalizedTimestamp(
          fromNanosecondsSinceStartup: event.timestamp,
          using: timestampNormalizer
        ),
        isAutoRepeat: isAutoRepeat,
        queriedPhysicalState: queriedState
      )
    else {
      return
    }
    handler?(observation)
  }

  static func normalizedTimestamp(
    fromNanosecondsSinceStartup timestamp: UInt64,
    using normalizer: MonotonicTimestampNormalizer
  ) -> UInt64 {
    normalizer.nanoseconds(fromNanosecondsSinceStartup: timestamp)
  }

  private static func mask(for types: [CGEventType]) -> CGEventMask {
    types.reduce(CGEventMask(0)) {
      $0 | (CGEventMask(1) << CGEventMask($1.rawValue))
    }
  }
}

private func cgKeyboardEventTapCallback(
  proxy: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  guard let userInfo else {
    return Unmanaged.passUnretained(event)
  }
  Unmanaged<CGEventTapKeyboardSource>
    .fromOpaque(userInfo)
    .takeUnretainedValue()
    .receive(type: type, event: event)
  return Unmanaged.passUnretained(event)
}
