import CoreGraphics
import GameController

public struct MacInputEnvironmentSnapshot: Codable, Equatable, Sendable {
  public let hidKeyboardCount: Int
  public let gcKeyboardAvailable: Bool
  public let listenEventAccess: Bool

  public init(
    hidKeyboardCount: Int,
    gcKeyboardAvailable: Bool,
    listenEventAccess: Bool
  ) {
    self.hidKeyboardCount = hidKeyboardCount
    self.gcKeyboardAvailable = gcKeyboardAvailable
    self.listenEventAccess = listenEventAccess
  }
}

public enum MacInputEnvironment {
  public static func snapshot() -> MacInputEnvironmentSnapshot {
    .init(
      hidKeyboardCount: IOHIDKeyboardSource.inventory().count,
      gcKeyboardAvailable: GCKeyboard.coalesced?.keyboardInput != nil,
      listenEventAccess: CGPreflightListenEventAccess()
    )
  }
}
