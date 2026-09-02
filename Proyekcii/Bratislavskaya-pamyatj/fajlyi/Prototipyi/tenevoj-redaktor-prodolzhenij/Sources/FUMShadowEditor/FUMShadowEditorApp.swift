import AppKit
import SwiftUI

@main
struct FUMShadowEditorApplication: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 980, minHeight: 680)
    }
    .windowResizability(.contentSize)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
  }
}
