#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import AppKit
import CoreGraphics
import Foundation

final class InputEventMonitor: ObservableObject {
    @Published private(set) var snapshot = InputSenseUISnapshot(
        timestamp: "",
        status: "idle",
        message: "Input monitor is idle.",
        recentEventCount: 0,
        recentEvents: []
    )

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let latestURL = URL(fileURLWithPath: ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("senses/input/latest.json").path)
    private let eventsURL = ПутиПриложения.текущие.память.appendingPathComponent("senses/input/events.jsonl")
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var recentEvents: [[String: Any]] = []
    private var lastPersistedMouseMove = Date.distantPast
    private var lastPermissionRequest = Date.distantPast
    private let permissionRequestInterval: TimeInterval = 30

    func ensureRunning() {
        loadRecentEventsFromDiskIfNeeded()

        guard eventTap == nil else {
            return
        }

        guard CGPreflightListenEventAccess() else {
            requestInputMonitoringAccessIfDue()
            updateSnapshot(
                status: "waiting_for_input_monitoring_permission",
                message: "Input Monitoring access is not enabled for the running FUM.app LaunchAgent process."
            )
            return
        }

        installEventTap()
    }

    func requestAccess() {
        lastPermissionRequest = .distantPast
        requestInputMonitoringAccessIfDue()
        ensureRunning()
    }

    private func requestInputMonitoringAccessIfDue() {
        let now = Date()
        guard now.timeIntervalSince(lastPermissionRequest) >= permissionRequestInterval else {
            return
        }
        lastPermissionRequest = now
        let trusted = CGRequestListenEventAccess()
        if !trusted {
            openInputSettings()
        }
    }

    private func installEventTap() {
        let mask = InputEventKind.allCases.reduce(CGEventMask(0)) { partial, kind in
            partial | CGEventMask(1 << kind.eventType.rawValue)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: inputEventTapCallback,
            userInfo: refcon
        ) else {
            updateSnapshot(
                status: "event_tap_unavailable",
                message: "Could not create a listen-only input event tap for FUM.app."
            )
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        updateSnapshot(status: "ok", message: "Input monitor is listening.")
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            record(event: [
                "type": "event_tap_status",
                "status": String(describing: type),
                "device": "input"
            ])
            return
        }

        guard let payload = InputEventPayload(type: type, event: event).payload else {
            return
        }
        record(event: payload)
    }

    private func record(event payload: [String: Any]) {
        var event = payload
        event["timestamp"] = isoFormatter.string(from: Date())
        event["activeApplication"] = activeApplicationPayload()

        recentEvents.insert(event, at: 0)
        if recentEvents.count > 32 {
            recentEvents.removeLast(recentEvents.count - 32)
        }

        if shouldPersist(event: event) {
            appendJSONLine(event, to: eventsURL)
        }
        updateSnapshot(status: "ok", message: "Input monitor is listening.")
    }

    private func shouldPersist(event: [String: Any]) -> Bool {
        guard event["type"] as? String == "mouse_moved" else {
            return true
        }

        let now = Date()
        guard now.timeIntervalSince(lastPersistedMouseMove) >= 0.25 else {
            return false
        }
        lastPersistedMouseMove = now
        return true
    }

    private func updateSnapshot(status: String, message: String? = nil) {
        let timestamp = isoFormatter.string(from: Date())
        let uiEvents = recentEvents.enumerated().map(InputSenseUIEvent.init(offset:payload:))
        let recentEventCount = recentEvents.count
        let fileSnapshot: [String: Any] = [
            "timestamp": timestamp,
            "status": status,
            "message": message ?? "",
            "recentEventCount": recentEventCount,
            "recentEvents": recentEvents,
            "recordsKeyCharacters": true,
            "source": "FUM.app"
        ]
        writeJSON(fileSnapshot, to: latestURL)

        snapshot = InputSenseUISnapshot(
            timestamp: timestamp,
            status: status,
            message: message,
            recentEventCount: recentEventCount,
            recentEvents: uiEvents
        )
    }

    private func appendJSONLine(_ payload: [String: Any], to url: URL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            try handle.close()
        } catch {
            NSLog("Failed to append input event: \(error.localizedDescription)")
        }
    }

    private func loadRecentEventsFromDiskIfNeeded() {
        guard recentEvents.isEmpty else {
            return
        }

        guard let data = try? Data(contentsOf: eventsURL),
              let contents = String(data: data, encoding: .utf8) else {
            return
        }

        let events = contents
            .split(separator: "\n")
            .suffix(32)
            .compactMap { line -> [String: Any]? in
                guard let lineData = String(line).data(using: .utf8),
                      let payload = try? JSONSerialization.jsonObject(with: lineData),
                      let event = payload as? [String: Any] else {
                    return nil
                }
                return event
            }
            .reversed()

        recentEvents = Array(events)
    }

    private func writeJSON(_ payload: [String: Any], to url: URL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            try data.write(to: url, options: [.atomic])
        } catch {
            NSLog("Failed to write input monitor snapshot: \(error.localizedDescription)")
        }
    }

    private func activeApplicationPayload() -> [String: Any] {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return [:]
        }
        return [
            "pid": app.processIdentifier,
            "name": app.localizedName ?? "",
            "bundleIdentifier": app.bundleIdentifier ?? ""
        ]
    }

    private func openInputSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private func inputEventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }
    let monitor = Unmanaged<InputEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.handle(type: type, event: event)
    return Unmanaged.passUnretained(event)
}

enum InputEventKind: CaseIterable {
    case keyDown
    case keyUp
    case flagsChanged
    case leftMouseDown
    case leftMouseUp
    case rightMouseDown
    case rightMouseUp
    case otherMouseDown
    case otherMouseUp
    case mouseMoved
    case leftMouseDragged
    case rightMouseDragged
    case otherMouseDragged
    case scrollWheel

    var eventType: CGEventType {
        switch self {
        case .keyDown: .keyDown
        case .keyUp: .keyUp
        case .flagsChanged: .flagsChanged
        case .leftMouseDown: .leftMouseDown
        case .leftMouseUp: .leftMouseUp
        case .rightMouseDown: .rightMouseDown
        case .rightMouseUp: .rightMouseUp
        case .otherMouseDown: .otherMouseDown
        case .otherMouseUp: .otherMouseUp
        case .mouseMoved: .mouseMoved
        case .leftMouseDragged: .leftMouseDragged
        case .rightMouseDragged: .rightMouseDragged
        case .otherMouseDragged: .otherMouseDragged
        case .scrollWheel: .scrollWheel
        }
    }
}

struct InputEventPayload {
    let type: CGEventType
    let event: CGEvent

    var payload: [String: Any]? {
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            return keyboardPayload()
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp,
             .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return mousePayload()
        case .scrollWheel:
            return scrollPayload()
        default:
            return nil
        }
    }

    private func keyboardPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "type": eventName,
            "device": "keyboard",
            "keyCode": event.getIntegerValueField(.keyboardEventKeycode),
            "isAutorepeat": event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            "modifiers": modifierPayload(event.flags)
        ]

        if let nsEvent = NSEvent(cgEvent: event) {
            payload["characters"] = nsEvent.characters ?? ""
            payload["charactersIgnoringModifiers"] = nsEvent.charactersIgnoringModifiers ?? ""
        }

        return payload
    }

    private func mousePayload() -> [String: Any] {
        [
            "type": eventName,
            "device": "pointer",
            "location": pointPayload(event.location),
            "buttonNumber": event.getIntegerValueField(.mouseEventButtonNumber),
            "clickState": event.getIntegerValueField(.mouseEventClickState),
            "delta": [
                "x": event.getIntegerValueField(.mouseEventDeltaX),
                "y": event.getIntegerValueField(.mouseEventDeltaY)
            ],
            "modifiers": modifierPayload(event.flags)
        ]
    }

    private func scrollPayload() -> [String: Any] {
        [
            "type": eventName,
            "device": "trackpad_or_mouse",
            "location": pointPayload(event.location),
            "scroll": [
                "x": event.getIntegerValueField(.scrollWheelEventDeltaAxis2),
                "y": event.getIntegerValueField(.scrollWheelEventDeltaAxis1),
                "fixedX": event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2),
                "fixedY": event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1),
                "pointX": event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2),
                "pointY": event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
                "isContinuous": event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0,
                "scrollPhase": event.getIntegerValueField(.scrollWheelEventScrollPhase),
                "momentumPhase": event.getIntegerValueField(.scrollWheelEventMomentumPhase)
            ],
            "modifiers": modifierPayload(event.flags)
        ]
    }

    private var eventName: String {
        switch type {
        case .keyDown: "key_down"
        case .keyUp: "key_up"
        case .flagsChanged: "flags_changed"
        case .leftMouseDown: "left_mouse_down"
        case .leftMouseUp: "left_mouse_up"
        case .rightMouseDown: "right_mouse_down"
        case .rightMouseUp: "right_mouse_up"
        case .otherMouseDown: "other_mouse_down"
        case .otherMouseUp: "other_mouse_up"
        case .mouseMoved: "mouse_moved"
        case .leftMouseDragged: "left_mouse_dragged"
        case .rightMouseDragged: "right_mouse_dragged"
        case .otherMouseDragged: "other_mouse_dragged"
        case .scrollWheel: "scroll_wheel"
        default: "input_event"
        }
    }

    private func pointPayload(_ point: CGPoint) -> [String: Any] {
        [
            "x": point.x,
            "y": point.y
        ]
    }

    private func modifierPayload(_ flags: CGEventFlags) -> [String] {
        var modifiers: [String] = []
        if flags.contains(.maskCommand) { modifiers.append("command") }
        if flags.contains(.maskShift) { modifiers.append("shift") }
        if flags.contains(.maskAlternate) { modifiers.append("option") }
        if flags.contains(.maskControl) { modifiers.append("control") }
        if flags.contains(.maskSecondaryFn) { modifiers.append("fn") }
        if flags.contains(.maskAlphaShift) { modifiers.append("caps_lock") }
        return modifiers
    }
}
