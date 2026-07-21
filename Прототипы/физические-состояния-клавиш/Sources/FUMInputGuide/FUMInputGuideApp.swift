import AppKit
import SwiftUI

final class FUMInputGuideAppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct FUMInputGuideApp: App {
  @NSApplicationDelegateAdaptor(FUMInputGuideAppDelegate.self) private var appDelegate
  @StateObject private var model = CaptureViewModel()

  var body: some Scene {
    Window("Сбор клавиатурных событий FUM", id: "keyboard-capture-guide") {
      ContentView(model: model)
        .frame(minWidth: 980, minHeight: 680)
    }
    .defaultSize(width: 1120, height: 760)

    Settings {
      Text("Настройки отсутствуют: каждый сбор начинается с нового явного согласия.")
        .padding()
    }
  }
}
