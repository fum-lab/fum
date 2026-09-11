import AppKit
import SwiftUI

enum FUMFeatureFlags {
    static let cameraEnabled = false
}

@main
struct FUMApp: App {
    @NSApplicationDelegateAdaptor(FUMAppDelegate.self) private var appDelegate

    init() {
        FUMPermissionCLI.handleIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            InterfaceWorkbench(initialFocus: .launchFocus)
                .frame(minWidth: 1080, minHeight: 720)
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.regular)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}

final class FUMAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
