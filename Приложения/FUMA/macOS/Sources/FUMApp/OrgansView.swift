#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import SwiftUI
import AppKit
import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation

struct OrgansSurface: View {
    let visionSnapshot: AXVisionUISnapshot
    let inputSnapshot: InputSenseUISnapshot
    @ObservedObject var inputMonitor: InputEventMonitor
    @ObservedObject var cameraVision: CameraVisionModel
    @ObservedObject var videoPlayer: VideoPlayerModel
    @ObservedObject var mcpBridge: MCPBridgeModel
    @State private var appAccessibilityStatus = PermissionStatusSnapshot.accessibilityForCurrentApp()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FUM")
                        .font(.system(size: 34, weight: .semibold))
                    Text("Единое macOS-приложение для органов чувств и экранного присутствия.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                    OrganStatusCard(title: "AX Vision", status: visionSnapshot.statusLabel, detail: "\(visionSnapshot.applications.count) apps · \(visionSnapshot.windowCount) windows", symbol: "eye", color: .teal, isLive: visionSnapshot.status == "ok") {
                        AXVisionAccessRequester.request()
                    }

                    OrganStatusCard(title: "Input Sense", status: inputSnapshot.statusLabel, detail: "\(inputSnapshot.recentEventCount) recent events", symbol: "keyboard", color: .orange, isLive: inputSnapshot.status == "ok") {
                        inputMonitor.requestAccess()
                    }

                    OrganStatusCard(title: "Camera", status: cameraVision.statusLabel, detail: "light \(Int(cameraVision.brightness * 100))% · gaze \(Int((cameraVision.gazeSample?.confidence ?? 0) * 100))%", symbol: "camera.slash", color: .indigo, isLive: cameraVision.isRunning, action: FUMFeatureFlags.cameraEnabled ? {
                        cameraVision.start()
                    } : nil)

                    OrganStatusCard(title: "People", status: cameraVision.faceRecognition.status, detail: "\(cameraVision.faceRecognition.knownPeople.count) known · \(cameraVision.faceRecognition.visibleFaces.count) visible", symbol: "person.crop.rectangle.stack", color: .mint, isLive: cameraVision.faceRecognition.visibleFaces.contains(where: \.isKnown), action: FUMFeatureFlags.cameraEnabled ? {
                        cameraVision.refreshKnownPeople()
                    } : nil)

                    OrganStatusCard(title: "Gaze Cursor", status: cameraVision.gazeStatus, detail: "calibration \(Int(cameraVision.gazeCalibrationProgress * 100))%", symbol: "cursorarrow.motionlines", color: .cyan, isLive: cameraVision.isGazeCursorEnabled, action: FUMFeatureFlags.cameraEnabled ? {
                        cameraVision.setGazeCursorEnabled(!cameraVision.isGazeCursorEnabled)
                    } : nil)

                    OrganStatusCard(title: "Video Memory", status: videoPlayer.statusText, detail: "\(videoPlayer.videos.count) media items", symbol: "play.rectangle", color: .red, isLive: !videoPlayer.videos.isEmpty) {
                        videoPlayer.start(preparesPlayback: false)
                    }

                    OrganStatusCard(title: "Screen", status: "FUM.app", detail: "monolithic window active", symbol: "display", color: .blue, isLive: true, action: nil)

                    OrganStatusCard(title: "MCP Bridge", status: mcpBridge.statusLabel, detail: mcpBridge.detail, symbol: "server.rack", color: .green, isLive: mcpBridge.isLive) {
                        mcpBridge.reloadNow()
                    }
                }

                OrganPermissionsPanel(
                    visionSnapshot: visionSnapshot,
                    inputSnapshot: inputSnapshot,
                    inputMonitor: inputMonitor,
                    cameraVision: cameraVision,
                    appAccessibilityStatus: appAccessibilityStatus,
                    refreshAppAccessibility: {
                        appAccessibilityStatus = .accessibilityForCurrentApp()
                    }
                )

                MCPScreenPanel(bridge: mcpBridge)

                HStack(alignment: .top, spacing: 16) {
                    OrganEventPanel(inputSnapshot: inputSnapshot)
                    OrganWindowPanel(visionSnapshot: visionSnapshot)
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            appAccessibilityStatus = .accessibilityForCurrentApp()
            if FUMFeatureFlags.cameraEnabled {
                cameraVision.start()
            }
            videoPlayer.start(preparesPlayback: false)
            mcpBridge.reloadNow()
        }
    }
}

struct OrganStatusCard: View {
    let title: String
    let status: String
    let detail: String
    let symbol: String
    let color: Color
    let isLive: Bool
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(isLive ? "Live" : "Needs attention")
                        .font(.caption)
                        .foregroundStyle(isLive ? .green : .secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(status)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let action {
                Button(action: action) {
                    Label(isLive ? "Refresh" : "Enable", systemImage: isLive ? "arrow.clockwise" : "lock.open")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OrganPermissionsPanel: View {
    let visionSnapshot: AXVisionUISnapshot
    let inputSnapshot: InputSenseUISnapshot
    @ObservedObject var inputMonitor: InputEventMonitor
    @ObservedObject var cameraVision: CameraVisionModel
    let appAccessibilityStatus: PermissionStatusSnapshot
    let refreshAppAccessibility: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Permissions", systemImage: "checkmark.shield")
                .font(.system(size: 14, weight: .semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                PermissionControlRow(
                    title: "FUM.app Accessibility",
                    status: appAccessibilityStatus.label,
                    detail: "Gaze cursor and local UI control",
                    symbol: "cursorarrow.motionlines",
                    color: .cyan,
                    isGranted: appAccessibilityStatus.isGranted,
                    requestTitle: "Request",
                    statusTitle: "Status",
                    requestAction: {
                        FUMAppAccessibilityRequester.request()
                        refreshAppAccessibility()
                    },
                    statusAction: refreshAppAccessibility
                )

                PermissionControlRow(
                    title: "AX Vision Accessibility",
                    status: visionSnapshot.statusLabel,
                    detail: "\(visionSnapshot.applications.count) apps · \(visionSnapshot.windowCount) windows",
                    symbol: "eye",
                    color: .teal,
                    isGranted: visionSnapshot.status == "ok",
                    requestTitle: "Request",
                    statusTitle: "Status",
                    requestAction: AXVisionAccessRequester.request,
                    statusAction: AXVisionAccessRequester.refreshStatus
                )

                PermissionControlRow(
                    title: "Input Monitoring",
                    status: inputSnapshot.statusLabel,
                    detail: "\(inputSnapshot.recentEventCount) recent events",
                    symbol: "keyboard",
                    color: .orange,
                    isGranted: inputSnapshot.status == "ok",
                    requestTitle: "Request",
                    statusTitle: "Status",
                    requestAction: inputMonitor.requestAccess,
                    statusAction: inputMonitor.ensureRunning
                )

                if FUMFeatureFlags.cameraEnabled {
                    PermissionControlRow(
                        title: "Camera",
                        status: cameraVision.statusLabel,
                        detail: "FUM.app video frames and gaze estimation",
                        symbol: "camera.viewfinder",
                        color: .indigo,
                        isGranted: cameraVision.authorizationStatus == .authorized,
                        requestTitle: "Request",
                        statusTitle: "Status",
                        requestAction: cameraVision.requestCameraAccess,
                        statusAction: cameraVision.refreshAuthorizationStatus
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PermissionControlRow: View {
    let title: String
    let status: String
    let detail: String
    let symbol: String
    let color: Color
    let isGranted: Bool
    let requestTitle: String
    let statusTitle: String
    let requestAction: () -> Void
    let statusAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isGranted ? .green : .orange)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button(action: requestAction) {
                    Label(requestTitle, systemImage: "lock.open")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Request \(title)")

                Button(action: statusAction) {
                    Label(statusTitle, systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Get current \(title) status")
            }
        }
        .padding(.vertical, 4)
    }
}

struct OrganEventPanel: View {
    let inputSnapshot: InputSenseUISnapshot
    @State private var selectedEventID: String?

    private var selectedEvent: InputSenseUIEvent? {
        if let selectedEventID,
           let selected = inputSnapshot.recentEvents.first(where: { $0.id == selectedEventID }) {
            return selected
        }
        return inputSnapshot.recentEvents.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Input Events", systemImage: "keyboard.badge.ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(inputSnapshot.recentEventCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                InputEventHeaderRow()

                ForEach(inputSnapshot.recentEvents.prefix(12), id: \.id) { event in
                    Button {
                        selectedEventID = event.id
                    } label: {
                        InputEventRow(event: event, isSelected: selectedEvent?.id == event.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.7), lineWidth: 1)
            )

            if let selectedEvent {
                InputEventDetailGrid(event: selectedEvent)
            }

            if inputSnapshot.recentEvents.isEmpty {
                Text(inputSnapshot.message ?? inputSnapshot.statusLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 340, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct InputEventHeaderRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Type")
                .frame(width: 150, alignment: .leading)
            Text("App")
                .frame(width: 110, alignment: .leading)
            Text("Key/Button")
                .frame(width: 92, alignment: .leading)
            Text("Position")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.78))
    }
}

private struct InputEventRow: View {
    let event: InputSenseUIEvent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: event.symbol)
                    .foregroundStyle(event.color)
                    .frame(width: 18)
                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)

            Text(event.activeApplication.isEmpty ? "—" : event.activeApplication)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            Text(event.primaryControl)
                .frame(width: 92, alignment: .leading)
                .lineLimit(1)

            Text(event.positionSummary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .font(.system(size: 12))
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? event.color.opacity(0.13) : Color.clear)
    }
}

private struct InputEventDetailGrid: View {
    let event: InputSenseUIEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Structured Event", systemImage: event.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(event.color)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(event.detailFields) { field in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(field.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(field.value)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(2)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OrganWindowPanel: View {
    let visionSnapshot: AXVisionUISnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Visible Windows", systemImage: "macwindow.on.rectangle")
                .font(.system(size: 14, weight: .semibold))

            ForEach(visionSnapshot.visibleAppSummaries.prefix(8), id: \.self) { summary in
                Label(summary, systemImage: "app.window")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OrgansDock: View {
    let visionSnapshot: AXVisionUISnapshot
    let inputSnapshot: InputSenseUISnapshot
    @ObservedObject var cameraVision: CameraVisionModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sensor.tag.radiowaves.forward")
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("FUM organs")
                    .font(.system(size: 14, weight: .semibold))
                Text("AX \(visionSnapshot.statusLabel) · Input \(inputSnapshot.statusLabel) · Camera \(cameraVision.statusLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        .frame(maxWidth: 680)
    }
}

struct InputSenseUISnapshot {
    var timestamp: String
    var status: String
    var message: String?
    var recentEventCount: Int
    var recentEvents: [InputSenseUIEvent]

    var statusLabel: String {
        switch status {
        case "ok": "Live"
        case "waiting_for_input_monitoring_permission": "Waiting for Input Monitoring"
        case "missing_snapshot": "No Snapshot"
        default: status
        }
    }

    static func load(path: String = ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("senses/input/latest.json").path) -> InputSenseUISnapshot {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return InputSenseUISnapshot(timestamp: "", status: "missing_snapshot", message: nil, recentEventCount: 0, recentEvents: [])
        }

        do {
            let decoded = try JSONDecoder().decode(InputSenseSnapshotFile.self, from: data)
            return InputSenseUISnapshot(
                timestamp: decoded.timestamp ?? "",
                status: decoded.status ?? "ok",
                message: decoded.message,
                recentEventCount: decoded.recentEventCount ?? decoded.recentEvents?.count ?? 0,
                recentEvents: decoded.recentEvents?.enumerated().map(InputSenseUIEvent.init(offset:file:)) ?? []
            )
        } catch {
            return InputSenseUISnapshot(timestamp: "", status: "decode_error", message: error.localizedDescription, recentEventCount: 0, recentEvents: [])
        }
    }
}

struct InputSenseUIEvent: Identifiable {
    var id: String
    var type: String
    var timestamp: String
    var activeApplication: String
    var bundleIdentifier: String
    var processID: Int?
    var device: String
    var keyCode: Int?
    var characters: String
    var charactersIgnoringModifiers: String
    var isAutorepeat: Bool?
    var modifiers: [String]
    var location: InputSensePoint?
    var buttonNumber: Int?
    var clickState: Int?
    var delta: InputSensePoint?
    var scroll: InputSenseScroll?

    init(offset: Int, file: InputSenseEventFile) {
        type = file.type ?? "event"
        timestamp = file.timestamp ?? ""
        device = file.device ?? ""
        activeApplication = file.activeApplication?.name ?? ""
        bundleIdentifier = file.activeApplication?.bundleIdentifier ?? ""
        processID = file.activeApplication?.pid
        keyCode = file.keyCode
        characters = file.characters ?? ""
        charactersIgnoringModifiers = file.charactersIgnoringModifiers ?? ""
        isAutorepeat = file.isAutorepeat
        modifiers = file.modifiers ?? []
        location = file.location
        buttonNumber = file.buttonNumber
        clickState = file.clickState
        delta = file.delta
        scroll = file.scroll
        id = "\(timestamp)-\(offset)-\(type)"
    }

    init(offset: Int, payload: [String: Any]) {
        type = payload["type"] as? String ?? "event"
        timestamp = payload["timestamp"] as? String ?? ""
        device = payload["device"] as? String ?? ""
        let app = payload["activeApplication"] as? [String: Any]
        activeApplication = app?["name"] as? String ?? ""
        bundleIdentifier = app?["bundleIdentifier"] as? String ?? ""
        processID = app?["pid"] as? Int
        keyCode = payload["keyCode"] as? Int
        characters = payload["characters"] as? String ?? ""
        charactersIgnoringModifiers = payload["charactersIgnoringModifiers"] as? String ?? ""
        isAutorepeat = payload["isAutorepeat"] as? Bool
        modifiers = payload["modifiers"] as? [String] ?? []
        location = InputSensePoint(payload["location"])
        buttonNumber = payload["buttonNumber"] as? Int
        clickState = payload["clickState"] as? Int
        delta = InputSensePoint(payload["delta"])
        scroll = InputSenseScroll(payload["scroll"])
        id = "\(timestamp)-\(offset)-\(type)"
    }

    var title: String {
        type.replacingOccurrences(of: "_", with: " ")
    }

    var subtitle: String {
        activeApplication.isEmpty ? timestamp : "\(activeApplication) · \(timestamp)"
    }

    var symbol: String {
        if type.contains("key") {
            return "keyboard"
        }
        if type.contains("mouse") {
            return "cursorarrow"
        }
        if type.contains("scroll") {
            return "trackpad"
        }
        return "circle"
    }

    var color: Color {
        if type.contains("key") || type == "flags_changed" {
            return .orange
        }
        if type.contains("scroll") {
            return .purple
        }
        if type.contains("mouse") {
            return .blue
        }
        return .secondary
    }

    var primaryControl: String {
        if let keyCode {
            let character = characters.isEmpty ? charactersIgnoringModifiers : characters
            if character.isEmpty {
                return "key \(keyCode)"
            }
            if character == " " {
                return "space · \(keyCode)"
            }
            return "\(character) · \(keyCode)"
        }

        if let buttonNumber {
            return "button \(buttonNumber)"
        }

        if type == "scroll_wheel" {
            return "scroll"
        }

        return "—"
    }

    var positionSummary: String {
        if let scroll {
            return "scroll x \(formatNumber(scroll.x)) y \(formatNumber(scroll.y))"
        }

        if let location {
            let movement = delta.map { " · dx \(formatNumber($0.x)) dy \(formatNumber($0.y))" } ?? ""
            return "x \(formatNumber(location.x)) y \(formatNumber(location.y))\(movement)"
        }

        if !modifiers.isEmpty {
            return modifiers.joined(separator: " + ")
        }

        return shortTime
    }

    var shortTime: String {
        guard let date = ISO8601DateFormatter().date(from: timestamp) else {
            return timestamp
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    var detailFields: [InputSenseEventField] {
        var fields = [
            InputSenseEventField(label: "type", value: type),
            InputSenseEventField(label: "device", value: device.isEmpty ? "unknown" : device),
            InputSenseEventField(label: "timestamp", value: timestamp),
            InputSenseEventField(label: "application", value: activeApplication.isEmpty ? "unknown" : activeApplication)
        ]

        if let processID {
            fields.append(InputSenseEventField(label: "pid", value: "\(processID)"))
        }
        if !bundleIdentifier.isEmpty {
            fields.append(InputSenseEventField(label: "bundle", value: bundleIdentifier))
        }
        if let keyCode {
            fields.append(InputSenseEventField(label: "keyCode", value: "\(keyCode)"))
        }
        if !characters.isEmpty {
            fields.append(InputSenseEventField(label: "characters", value: displayCharacters(characters)))
        }
        if let isAutorepeat {
            fields.append(InputSenseEventField(label: "repeat", value: isAutorepeat ? "true" : "false"))
        }
        if !modifiers.isEmpty {
            fields.append(InputSenseEventField(label: "modifiers", value: modifiers.joined(separator: " + ")))
        }
        if let location {
            fields.append(InputSenseEventField(label: "location", value: "x \(formatNumber(location.x)), y \(formatNumber(location.y))"))
        }
        if let buttonNumber {
            fields.append(InputSenseEventField(label: "buttonNumber", value: "\(buttonNumber)"))
        }
        if let clickState {
            fields.append(InputSenseEventField(label: "clickState", value: "\(clickState)"))
        }
        if let delta {
            fields.append(InputSenseEventField(label: "delta", value: "x \(formatNumber(delta.x)), y \(formatNumber(delta.y))"))
        }
        if let scroll {
            fields.append(InputSenseEventField(label: "scroll", value: scroll.summary))
        }

        return fields
    }

    private func displayCharacters(_ value: String) -> String {
        if value == " " {
            return "space"
        }
        if value == "\n" {
            return "return"
        }
        return value
    }

    private func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

struct InputSenseEventField: Identifiable {
    var label: String
    var value: String

    var id: String {
        "\(label)-\(value)"
    }
}

struct InputSenseSnapshotFile: Decodable {
    var timestamp: String?
    var status: String?
    var message: String?
    var recentEventCount: Int?
    var recentEvents: [InputSenseEventFile]?
}

struct InputSenseEventFile: Decodable {
    var timestamp: String?
    var type: String?
    var device: String?
    var activeApplication: InputSenseApplicationFile?
    var keyCode: Int?
    var characters: String?
    var charactersIgnoringModifiers: String?
    var isAutorepeat: Bool?
    var modifiers: [String]?
    var location: InputSensePoint?
    var buttonNumber: Int?
    var clickState: Int?
    var delta: InputSensePoint?
    var scroll: InputSenseScroll?
}

struct InputSenseApplicationFile: Decodable {
    var name: String?
    var bundleIdentifier: String?
    var pid: Int?
}

struct InputSensePoint: Decodable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init?(_ value: Any?) {
        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        let xValue = dictionary["x"]
        let yValue = dictionary["y"]
        guard let x = Self.double(from: xValue),
              let y = Self.double(from: yValue) else {
            return nil
        }

        self.x = x
        self.y = y
    }

    private static func double(from value: Any?) -> Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        return nil
    }
}

struct InputSenseScroll: Decodable {
    var x: Double
    var y: Double
    var fixedX: Double?
    var fixedY: Double?
    var pointX: Int?
    var pointY: Int?
    var isContinuous: Bool?
    var scrollPhase: Int?
    var momentumPhase: Int?

    init(
        x: Double,
        y: Double,
        fixedX: Double? = nil,
        fixedY: Double? = nil,
        pointX: Int? = nil,
        pointY: Int? = nil,
        isContinuous: Bool? = nil,
        scrollPhase: Int? = nil,
        momentumPhase: Int? = nil
    ) {
        self.x = x
        self.y = y
        self.fixedX = fixedX
        self.fixedY = fixedY
        self.pointX = pointX
        self.pointY = pointY
        self.isContinuous = isContinuous
        self.scrollPhase = scrollPhase
        self.momentumPhase = momentumPhase
    }

    init?(_ value: Any?) {
        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        guard let x = Self.double(from: dictionary["x"]),
              let y = Self.double(from: dictionary["y"]) else {
            return nil
        }

        self.x = x
        self.y = y
        fixedX = Self.double(from: dictionary["fixedX"])
        fixedY = Self.double(from: dictionary["fixedY"])
        pointX = dictionary["pointX"] as? Int
        pointY = dictionary["pointY"] as? Int
        isContinuous = dictionary["isContinuous"] as? Bool
        scrollPhase = dictionary["scrollPhase"] as? Int
        momentumPhase = dictionary["momentumPhase"] as? Int
    }

    var summary: String {
        var parts = ["x \(formatNumber(x))", "y \(formatNumber(y))"]
        if let fixedX, let fixedY {
            parts.append("fixed \(formatNumber(fixedX))/\(formatNumber(fixedY))")
        }
        if let isContinuous {
            parts.append(isContinuous ? "continuous" : "discrete")
        }
        if let scrollPhase {
            parts.append("phase \(scrollPhase)")
        }
        if let momentumPhase {
            parts.append("momentum \(momentumPhase)")
        }
        return parts.joined(separator: " · ")
    }

    private static func double(from value: Any?) -> Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        return nil
    }

    private func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}


struct PermissionStatusSnapshot {
    var isGranted: Bool
    var label: String

    static func accessibilityForCurrentApp() -> PermissionStatusSnapshot {
        let trusted = AXIsProcessTrusted()
        return PermissionStatusSnapshot(
            isGranted: trusted,
            label: trusted ? "Granted" : "Not Granted"
        )
    }
}

enum FUMAppAccessibilityRequester {
    static func request() {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        if !trusted {
            openAccessibilitySettings()
        }
    }

    private static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

enum InputSenseAccessRequester {
    static func request() {
        let trusted = CGRequestListenEventAccess()
        if !trusted {
            openInputSettings()
        }
    }

    static func refreshStatus() {
        _ = CGPreflightListenEventAccess()
    }

    private static func openInputSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
