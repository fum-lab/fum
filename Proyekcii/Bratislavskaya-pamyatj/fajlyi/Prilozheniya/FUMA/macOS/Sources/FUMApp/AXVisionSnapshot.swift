#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import AppKit
import ApplicationServices
import Foundation

struct AXVisionUISnapshot {
    var timestamp: String
    var status: String
    var message: String?
    var applications: [AXVisionUIApp]

    var statusLabel: String {
        switch status {
        case "ok": "Live"
        case "waiting_for_accessibility_permission": "Waiting for Accessibility"
        case "missing_snapshot": "No Snapshot"
        default: status
        }
    }

    var shortTimestamp: String {
        guard !timestamp.isEmpty else {
            return "no timestamp"
        }
        return String(timestamp.suffix(9).dropLast())
    }

    var windowCount: Int {
        applications.reduce(0) { $0 + $1.windows.count }
    }

    var windowMarks: [AXVisionUIWindowMark] {
        applications.flatMap { app in
            app.windows.compactMap { window in
                guard let frame = window.frame, frame.width > 0, frame.height > 0 else {
                    return nil
                }
                return AXVisionUIWindowMark(
                    appName: app.name.isEmpty ? "Unknown" : app.name,
                    title: window.title,
                    role: window.role,
                    frame: frame,
                    isActive: app.isActive
                )
            }
        }
    }

    var visibleAppSummaries: [String] {
        let summaries = applications
            .filter { !$0.windows.isEmpty }
            .map { "\($0.name): \($0.windows.count)" }
        return summaries.isEmpty ? [statusLabel] : summaries
    }

    var needsAccessibilityRequest: Bool {
        status == "waiting_for_accessibility_permission"
    }

    static func live() -> AXVisionUISnapshot {
        guard AXIsProcessTrusted() else {
            return AXVisionUISnapshot(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                status: "waiting_for_accessibility_permission",
                message: "Accessibility access is not enabled for FUM.app.",
                applications: []
            )
        }

        let applications = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
            .map(AXVisionUIApp.live)

        return AXVisionUISnapshot(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            status: "ok",
            message: nil,
            applications: applications
        )
    }

    static func load(path: String = ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("senses/ax-vision/latest.json").path) -> AXVisionUISnapshot {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return AXVisionUISnapshot(timestamp: "", status: "missing_snapshot", message: nil, applications: [])
        }

        do {
            let decoded = try JSONDecoder().decode(AXVisionSnapshotFile.self, from: data)
            return AXVisionUISnapshot(
                timestamp: decoded.timestamp ?? "",
                status: decoded.status ?? "ok",
                message: decoded.message,
                applications: decoded.applications?.map(AXVisionUIApp.init(file:)) ?? []
            )
        } catch {
            return AXVisionUISnapshot(
                timestamp: "",
                status: "decode_error",
                message: error.localizedDescription,
                applications: []
            )
        }
    }
}

enum AXVisionAccessRequester {
    static func request() {
        FUMAppAccessibilityRequester.request()
    }

    static func refreshStatus() {
        _ = AXVisionUISnapshot.live()
    }
}

struct AXVisionUIApp {
    var name: String
    var isActive: Bool
    var windows: [AXVisionUIWindow]

    init(name: String, isActive: Bool, windows: [AXVisionUIWindow]) {
        self.name = name
        self.isActive = isActive
        self.windows = windows
    }

    init(file: AXVisionAppFile) {
        name = file.name ?? ""
        isActive = file.isActive ?? false
        windows = file.windows?.map(AXVisionUIWindow.init(file:)) ?? []
    }

    static func live(app: NSRunningApplication) -> AXVisionUIApp {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        let windows = AXVisionReader.attributeValue(appElement, kAXWindowsAttribute)
            .flatMap { $0 as? [Any] }?
            .compactMap { value -> AXUIElement? in
                guard CFGetTypeID(value as CFTypeRef) == AXUIElementGetTypeID() else {
                    return nil
                }
                return (value as! AXUIElement)
            }
            .map(AXVisionUIWindow.live) ?? []

        return AXVisionUIApp(
            name: app.localizedName ?? "",
            isActive: app.isActive,
            windows: windows
        )
    }
}

struct AXVisionUIWindow {
    var title: String
    var role: String
    var frame: CGRect?

    init(title: String, role: String, frame: CGRect?) {
        self.title = title
        self.role = role
        self.frame = frame
    }

    init(file: AXVisionWindowFile) {
        title = file.title ?? ""
        role = file.role ?? ""
        if let frame = file.frame {
            self.frame = CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height)
        } else {
            self.frame = nil
        }
    }

    static func live(window: AXUIElement) -> AXVisionUIWindow {
        AXVisionUIWindow(
            title: AXVisionReader.stringAttribute(window, kAXTitleAttribute) ?? "",
            role: AXVisionReader.stringAttribute(window, kAXRoleAttribute) ?? "",
            frame: AXVisionReader.frame(window)
        )
    }
}

enum AXVisionReader {
    static func attributeValue(_ element: AXUIElement, _ attribute: String) -> Any? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return nil
        }
        return value
    }

    static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        attributeValue(element, attribute) as? String
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard
            let pointValue = attributeValue(element, kAXPositionAttribute),
            let sizeValue = attributeValue(element, kAXSizeAttribute),
            let point = axPoint(pointValue),
            let size = axSize(sizeValue)
        else {
            return nil
        }

        return CGRect(origin: point, size: size)
    }

    private static func axPoint(_ value: Any) -> CGPoint? {
        guard CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else {
            return nil
        }
        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }
        var point = CGPoint.zero
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    private static func axSize(_ value: Any) -> CGSize? {
        guard CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else {
            return nil
        }
        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }
        var size = CGSize.zero
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }
}

struct AXVisionUIWindowMark {
    var appName: String
    var title: String
    var role: String
    var frame: CGRect
    var isActive: Bool
}

struct AXVisionSnapshotFile: Decodable {
    var timestamp: String?
    var status: String?
    var message: String?
    var applications: [AXVisionAppFile]?
}

struct AXVisionAppFile: Decodable {
    var name: String?
    var isActive: Bool?
    var windows: [AXVisionWindowFile]?
}

struct AXVisionWindowFile: Decodable {
    var title: String?
    var role: String?
    var frame: AXVisionFrameFile?
}

struct AXVisionFrameFile: Decodable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}
