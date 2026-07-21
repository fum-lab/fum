public enum InputSourceID: String, Codable, CaseIterable, Sendable {
  case ioHIDManager = "iohid-manager"
  case gcKeyboard = "gc-keyboard"
  case cgEventTap = "cg-event-tap"
  case nsEvent = "ns-event"
  case uiPresses = "ui-presses"
}

public enum PhysicalKeyState: String, Codable, Sendable {
  case pressed
  case released
}

public enum PhysicalKeyCodeSpace: String, Codable, Sendable {
  case hidUsage
  case macVirtualKeyCode
}

public enum KeyboardPlatformEventKind: String, Codable, Sendable {
  case keyDown
  case keyUp
  case flagsChanged
}

public enum KeyboardModifierFlag: String, Codable, Sendable {
  case capsLock
  case shift
  case control
  case option
  case command
  case numericPad
  case help
  case secondaryFn
}

public struct KeyboardObservationDiagnostics: Codable, Equatable, Sendable {
  public let platformEventKind: KeyboardPlatformEventKind
  public let modifierFlags: [KeyboardModifierFlag]

  public init(
    platformEventKind: KeyboardPlatformEventKind,
    modifierFlags: [KeyboardModifierFlag]
  ) {
    self.platformEventKind = platformEventKind
    self.modifierFlags = modifierFlags
  }
}

public struct PhysicalKey: Codable, Hashable, Sendable {
  public let deviceID: String
  public let codeSpace: PhysicalKeyCodeSpace
  public let usagePage: UInt32
  public let usage: UInt32

  public init(
    deviceID: String,
    codeSpace: PhysicalKeyCodeSpace = .hidUsage,
    usagePage: UInt32,
    usage: UInt32
  ) {
    self.deviceID = deviceID
    self.codeSpace = codeSpace
    self.usagePage = usagePage
    self.usage = usage
  }
}

public struct PhysicalKeyObservation: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let key: PhysicalKey
  public let state: PhysicalKeyState?
  public let monotonicNanoseconds: UInt64
  public let isAutoRepeat: Bool
  public let diagnostics: KeyboardObservationDiagnostics?

  public init(
    source: InputSourceID,
    key: PhysicalKey,
    state: PhysicalKeyState?,
    monotonicNanoseconds: UInt64,
    isAutoRepeat: Bool,
    diagnostics: KeyboardObservationDiagnostics? = nil
  ) {
    self.source = source
    self.key = key
    self.state = state
    self.monotonicNanoseconds = monotonicNanoseconds
    self.isAutoRepeat = isAutoRepeat
    self.diagnostics = diagnostics
  }
}

public struct PhysicalKeyTransition: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let key: PhysicalKey
  public let previousState: PhysicalKeyState?
  public let state: PhysicalKeyState
  public let monotonicNanoseconds: UInt64

  public init(
    source: InputSourceID,
    key: PhysicalKey,
    previousState: PhysicalKeyState?,
    state: PhysicalKeyState,
    monotonicNanoseconds: UInt64
  ) {
    self.source = source
    self.key = key
    self.previousState = previousState
    self.state = state
    self.monotonicNanoseconds = monotonicNanoseconds
  }
}

public enum ObservationRejection: String, Codable, Equatable, Hashable, Sendable {
  case autoRepeat
  case missingPhysicalState
  case unchangedPhysicalState
}

public enum ObservationResult: Equatable, Sendable {
  case accepted(PhysicalKeyTransition)
  case rejected(ObservationRejection)
}

public struct PhysicalKeyTraceRecord: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public let schemaVersion: Int
  public let sequenceNumber: UInt64
  public let transition: PhysicalKeyTransition

  public init(
    schemaVersion: Int = PhysicalKeyTraceRecord.currentSchemaVersion,
    sequenceNumber: UInt64,
    transition: PhysicalKeyTransition
  ) {
    self.schemaVersion = schemaVersion
    self.sequenceNumber = sequenceNumber
    self.transition = transition
  }
}

public struct PhysicalKeyStateReducer: Sendable {
  private var states: [PhysicalKey: PhysicalKeyState] = [:]

  public init() {}

  public mutating func consume(_ observation: PhysicalKeyObservation) -> ObservationResult {
    if observation.isAutoRepeat {
      return .rejected(.autoRepeat)
    }
    guard let state = observation.state else {
      return .rejected(.missingPhysicalState)
    }
    let previousState = states[observation.key]
    guard previousState != state else {
      return .rejected(.unchangedPhysicalState)
    }
    states[observation.key] = state
    return .accepted(
      .init(
        source: observation.source,
        key: observation.key,
        previousState: previousState,
        state: state,
        monotonicNanoseconds: observation.monotonicNanoseconds
      ))
  }

  public func currentState(of key: PhysicalKey) -> PhysicalKeyState? {
    states[key]
  }
}
