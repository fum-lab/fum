import FUMInputCore

public enum IOHIDObservationFactory {
  public static func keyboardObservation(
    deviceID: String,
    usagePage: UInt32,
    usage: UInt32,
    integerValue: Int,
    monotonicNanoseconds: UInt64
  ) -> PhysicalKeyObservation? {
    guard usagePage == 0x07 || usagePage == 0x0C else {
      return nil
    }
    return .init(
      source: .ioHIDManager,
      key: .init(
        deviceID: deviceID,
        codeSpace: .hidUsage,
        usagePage: usagePage,
        usage: usage
      ),
      state: integerValue == 0 ? .released : .pressed,
      monotonicNanoseconds: monotonicNanoseconds,
      isAutoRepeat: false
    )
  }
}

public enum CGKeyboardEventKind: String, Sendable {
  case keyDown
  case keyUp
  case flagsChanged
}

public enum CGEventObservationFactory {
  public static func keyboardObservation(
    type: CGKeyboardEventKind,
    virtualKeyCode: UInt32,
    monotonicNanoseconds: UInt64,
    isAutoRepeat: Bool,
    queriedPhysicalState: Bool?,
    modifierFlags: [KeyboardModifierFlag] = []
  ) -> PhysicalKeyObservation? {
    let state: PhysicalKeyState?
    switch type {
    case .keyDown:
      state = .pressed
    case .keyUp:
      state = .released
    case .flagsChanged:
      state = queriedPhysicalState.map { $0 ? .pressed : .released }
    }
    return .init(
      source: .cgEventTap,
      key: .init(
        deviceID: "combined-session",
        codeSpace: .macVirtualKeyCode,
        usagePage: 0,
        usage: virtualKeyCode
      ),
      state: state,
      monotonicNanoseconds: monotonicNanoseconds,
      isAutoRepeat: isAutoRepeat,
      diagnostics: .init(
        platformEventKind: type.platformEventKind,
        modifierFlags: modifierFlags
      )
    )
  }
}

extension CGKeyboardEventKind {
  fileprivate var platformEventKind: KeyboardPlatformEventKind {
    switch self {
    case .keyDown:
      .keyDown
    case .keyUp:
      .keyUp
    case .flagsChanged:
      .flagsChanged
    }
  }
}
