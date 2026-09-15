#if os(macOS)
import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import ИсполнениеОператора
#endif

enum FUMFeatureFlags {
    static let cameraEnabled = false
}

@main
struct FUMApp: App {
    @NSApplicationDelegateAdaptor(FUMAppDelegate.self) private var appDelegate

    init() {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        if КомандноеИсполнениеОператора.выбран(аргументы: аргументы) {
            do {
                let приёмПрофиля: ((МеткаИсполнения) -> Void)? = аргументы.contains("--профиль") ? { метка in
                    if let данные = try? JSONEncoder().encode(метка) {
                        try? FileHandle.standardError.write(contentsOf: данные + Data([10]))
                    }
                } : nil
                let данные = try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы, профиль: приёмПрофиля)
                try FileHandle.standardOutput.write(contentsOf: данные)
                exit(0)
            } catch {
                let сообщение = "FUMA: отказ исполнения оператора: \(error)\n"
                try? FileHandle.standardError.write(contentsOf: Data(сообщение.utf8))
                exit(2)
            }
        }
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

#else
import Foundation
@main enum FUMAНедоступнаяПлатформа {
    static func main() throws {
        throw NSError(domain: "FUMA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Интерфейс FUMA для этой платформы ещё не подключён; используйте сценарий-runtime."])
    }
}
#endif
