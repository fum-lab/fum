#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import AppKit
import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation

enum FUMPermissionCLI {
    static func handleIfNeeded() {
        let arguments = Set(CommandLine.arguments.dropFirst())
        if arguments.contains("--permission-status") {
            printStatus(request: false, outputURL: statusOutputURL())
            exit(0)
        }

        if arguments.contains("--request-permissions") {
            requestPermissions()
            printStatus(request: true, outputURL: statusOutputURL())
            exit(0)
        }
    }

    private static func requestPermissions() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        _ = CGRequestListenEventAccess()

        if FUMFeatureFlags.cameraEnabled && AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .video) { _ in
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 30)
        }

        _ = documentsReadable()
        openSettingsForMissingPermissions()
    }

    private static func printStatus(request: Bool, outputURL: URL?) {
        let payload: [String: Any] = [
            "bundleIdentifier": Bundle.main.bundleIdentifier ?? "",
            "requested": request,
            "accessibility": AXIsProcessTrusted(),
            "inputMonitoring": CGPreflightListenEventAccess(),
            "camera": cameraStatus(),
            "documents": documentsReadable(),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: data, encoding: .utf8) {
            print(text)
            if let outputURL {
                try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? data.write(to: outputURL, options: [.atomic])
            }
        }
    }

    private static func statusOutputURL() -> URL? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--permission-status-output") else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return URL(fileURLWithPath: arguments[valueIndex])
    }

    private static func cameraStatus() -> String {
        guard FUMFeatureFlags.cameraEnabled else {
            return "disabled"
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return "authorized"
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        @unknown default:
            return "unknown"
        }
    }

    private static func documentsReadable() -> Bool {
        let documentsURL = URL(fileURLWithPath: ПутиПриложения.текущие.документы.path)
        do {
            _ = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            return true
        } catch {
            return false
        }
    }

    private static func openSettingsForMissingPermissions() {
        if !AXIsProcessTrusted() {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }

        if !CGPreflightListenEventAccess() {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
        }

        if FUMFeatureFlags.cameraEnabled && AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
        }

        if !documentsReadable() {
            open("x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")
        }
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
