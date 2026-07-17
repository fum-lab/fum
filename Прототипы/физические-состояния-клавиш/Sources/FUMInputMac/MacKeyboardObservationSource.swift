import FUMInputCore

public typealias KeyboardObservationHandler = @Sendable (PhysicalKeyObservation) -> Void

public protocol MacKeyboardObservationSource: AnyObject {
  var sourceID: InputSourceID { get }
  func start(handler: @escaping KeyboardObservationHandler) throws
  func stop()
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
