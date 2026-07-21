import FUMInputCore

public typealias KeyboardObservationHandler = @Sendable (PhysicalKeyObservation) -> Void
public typealias KeyboardSourceDiagnosticHandler = @Sendable (KeyboardSourceDiagnostic) -> Void

public enum KeyboardSourceDiagnosticKind: String, Codable, Sendable {
  case tapDisabledByTimeout
  case tapDisabledByUserInput
}

public struct KeyboardSourceDiagnostic: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let kind: KeyboardSourceDiagnosticKind
  public let monotonicNanoseconds: UInt64?

  public init(
    source: InputSourceID,
    kind: KeyboardSourceDiagnosticKind,
    monotonicNanoseconds: UInt64?
  ) {
    self.source = source
    self.kind = kind
    self.monotonicNanoseconds = monotonicNanoseconds
  }
}

public protocol MacKeyboardObservationSource: AnyObject, Sendable {
  var sourceID: InputSourceID { get }
  func start(
    handler: @escaping KeyboardObservationHandler,
    diagnosticHandler: @escaping KeyboardSourceDiagnosticHandler
  ) throws
  func stop()
}

extension MacKeyboardObservationSource {
  public func start(handler: @escaping KeyboardObservationHandler) throws {
    try start(handler: handler) { _ in }
  }
}

public enum MacKeyboardSourceError: Error, CustomStringConvertible, Sendable {
  case alreadyRunning
  case sourceUnavailable(String)
  case permissionRequired(String)
  case openFailed(String)

  public var description: String {
    switch self {
    case .alreadyRunning:
      "источник уже запущен"
    case .sourceUnavailable(let message):
      message
    case .permissionRequired(let message):
      message
    case .openFailed(let message):
      message
    }
  }
}

public enum MacKeyboardObservationSourceFactory {
  public static let supportedSources: [InputSourceID] = [
    .ioHIDManager, .gcKeyboard, .cgEventTap, .nsEvent,
  ]

  public static func make(_ source: InputSourceID) throws -> any MacKeyboardObservationSource {
    switch source {
    case .ioHIDManager:
      IOHIDKeyboardSource()
    case .gcKeyboard:
      GCKeyboardSource()
    case .cgEventTap:
      CGEventTapKeyboardSource()
    case .nsEvent:
      NSEventKeyboardSource()
    case .uiPresses:
      throw MacKeyboardSourceError.sourceUnavailable(
        "ui-presses проверяется в приложении iOS/iPadOS/tvOS/visionOS"
      )
    }
  }
}
