import AppKit
import ApplicationServices
import Foundation
import ПутиИсполнения

struct Options {
    var interval: TimeInterval = 0.5
    var once = false
    var json = false
    var quiet = false
    var requestAccess = false
    var waitForPermission = false
    var permissionRetryInterval: TimeInterval = 5.0
    var outputPath: String?
    var changesOutputPath: String?
    var includeElements = false
    var treeDepth = 0
    var pid: pid_t?
    var appName: String?
    var prompt = true
    var maxArrayItems = 40
    var maxStringLength = 500
}

struct AXVision {
    let options: Options

    func run() {
        var stateRecorder = AXVisionStateRecorder(path: options.changesOutputPath)

        if options.requestAccess {
            let trusted = requestAccessibilityTrust()
            let snapshot = accessRequestSnapshot(trusted: trusted)
            emitSnapshot(snapshot)
            stateRecorder.record(snapshot: snapshot)
            exit(trusted ? 0 : 1)
        }

        while !ensureAccessibilityTrust() {
            let message = "Accessibility access is not enabled. Grant access in System Settings > Privacy & Security > Accessibility."
            let snapshot = permissionSnapshot(message: message)
            emitSnapshot(snapshot)
            stateRecorder.record(snapshot: snapshot)

            guard options.waitForPermission else {
                fputs("\(message) Then run again.\n", stderr)
                exit(1)
            }

            if !options.quiet {
                fputs("\(message) Waiting...\n", stderr)
            }
            Thread.sleep(forTimeInterval: options.permissionRetryInterval)
        }

        repeat {
            let snapshot = makeSnapshot()
            emitSnapshot(snapshot)
            stateRecorder.record(snapshot: snapshot)
            if !options.once {
                Thread.sleep(forTimeInterval: options.interval)
            }
        } while !options.once
    }

    private func ensureAccessibilityTrust() -> Bool {
        if !options.prompt {
            return AXIsProcessTrusted()
        }

        return requestAccessibilityTrust()
    }

    private func requestAccessibilityTrust() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        if !trusted {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        return trusted
    }

    private func makeSnapshot() -> [String: Any] {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .filter { app in
                if let pid = options.pid, app.processIdentifier != pid {
                    return false
                }
                if let appName = options.appName?.lowercased() {
                    let localized = app.localizedName?.lowercased() ?? ""
                    let bundle = app.bundleIdentifier?.lowercased() ?? ""
                    return localized.contains(appName) || bundle.contains(appName)
                }
                return true
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
            .map(readApplication)

        return [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "status": "ok",
            "interval": options.interval,
            "applications": apps
        ]
    }

    private func permissionSnapshot(message: String) -> [String: Any] {
        [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "status": "waiting_for_accessibility_permission",
            "message": message,
            "applications": []
        ]
    }

    private func accessRequestSnapshot(trusted: Bool) -> [String: Any] {
        [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "status": trusted ? "accessibility_trusted" : "accessibility_prompted",
            "trusted": trusted,
            "applications": []
        ]
    }

    private func readApplication(_ app: NSRunningApplication) -> [String: Any] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        let windows = attributeValue(appElement, kAXWindowsAttribute)
            .flatMap { $0 as? [Any] }?
            .compactMap { value -> AXUIElement? in
                guard CFGetTypeID(value as CFTypeRef) == AXUIElementGetTypeID() else {
                    return nil
                }
                return (value as! AXUIElement)
            }
            .map { readElement($0, depth: options.includeElements ? options.treeDepth : 0, forceCoreWindowAttributes: true) } ?? []

        var payload: [String: Any] = [
            "pid": app.processIdentifier,
            "name": app.localizedName ?? "",
            "bundleIdentifier": app.bundleIdentifier ?? "",
            "isActive": app.isActive,
            "windowCount": windows.count,
            "windows": windows
        ]

        if options.includeElements {
            payload["applicationElement"] = readElement(appElement, depth: options.treeDepth, forceCoreWindowAttributes: false)
        }

        return payload
    }

    private func readElement(_ element: AXUIElement, depth: Int, forceCoreWindowAttributes: Bool) -> [String: Any] {
        let attributeNames = copyAttributeNames(element)
        var attributes: [String: Any] = [:]

        for name in attributeNames.sorted() {
            if !forceCoreWindowAttributes && depth == 0 && name == kAXChildrenAttribute as String {
                continue
            }
            guard let value = attributeValue(element, name) else {
                continue
            }
            attributes[name] = serialize(value, depth: max(depth - 1, 0))
        }

        var payload: [String: Any] = [
            "role": stringAttribute(element, kAXRoleAttribute) ?? "",
            "subrole": stringAttribute(element, kAXSubroleAttribute) ?? "",
            "title": stringAttribute(element, kAXTitleAttribute) ?? "",
            "attributes": attributes
        ]

        if forceCoreWindowAttributes {
            payload["position"] = serializeAttribute(element, kAXPositionAttribute)
            payload["size"] = serializeAttribute(element, kAXSizeAttribute)
            payload["frame"] = framePayload(element)
            payload["minimized"] = serializeAttribute(element, kAXMinimizedAttribute)
            payload["focused"] = serializeAttribute(element, kAXFocusedAttribute)
        }

        if options.includeElements, depth > 0, let children = attributeValue(element, kAXChildrenAttribute) as? [Any] {
            let childPayloads: [[String: Any]] = children.prefix(options.maxArrayItems).compactMap { child in
                guard CFGetTypeID(child as CFTypeRef) == AXUIElementGetTypeID() else {
                    return nil
                }
                return readElement(child as! AXUIElement, depth: depth - 1, forceCoreWindowAttributes: false)
            }
            payload["children"] = childPayloads
            if children.count > options.maxArrayItems {
                payload["childrenTruncated"] = children.count - options.maxArrayItems
            }
        }

        return payload
    }

    private func framePayload(_ element: AXUIElement) -> Any {
        guard
            let pointValue = attributeValue(element, kAXPositionAttribute),
            let sizeValue = attributeValue(element, kAXSizeAttribute),
            let point = axPoint(pointValue),
            let size = axSize(sizeValue)
        else {
            return NSNull()
        }

        return [
            "x": point.x,
            "y": point.y,
            "width": size.width,
            "height": size.height
        ]
    }

    private func serializeAttribute(_ element: AXUIElement, _ attribute: String) -> Any {
        guard let value = attributeValue(element, attribute) else {
            return NSNull()
        }
        return serialize(value, depth: 0)
    }

    private func copyAttributeNames(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        let error = AXUIElementCopyAttributeNames(element, &names)
        guard error == .success, let names else {
            return []
        }
        return (names as? [String]) ?? []
    }

    private func attributeValue(_ element: AXUIElement, _ attribute: String) -> Any? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            return nil
        }
        return value
    }

    private func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        attributeValue(element, attribute) as? String
    }

    private func serialize(_ rawValue: Any, depth: Int) -> Any {
        let value = rawValue as CFTypeRef
        let typeID = CFGetTypeID(value)

        if typeID == CFStringGetTypeID() {
            return clipped(rawValue as? String ?? "\(rawValue)")
        }
        if typeID == CFBooleanGetTypeID() {
            return CFBooleanGetValue((value as! CFBoolean))
        }
        if typeID == CFNumberGetTypeID() {
            return rawValue
        }
        if typeID == AXValueGetTypeID() {
            return serializeAXValue(rawValue as! AXValue)
        }
        if typeID == AXUIElementGetTypeID() {
            if depth <= 0 {
                return elementSummary(rawValue as! AXUIElement)
            }
            return readElement(rawValue as! AXUIElement, depth: depth, forceCoreWindowAttributes: false)
        }
        if typeID == CFArrayGetTypeID() {
            let array = (rawValue as? [Any]) ?? []
            var items = array.prefix(options.maxArrayItems).map { serialize($0, depth: max(depth - 1, 0)) }
            if array.count > options.maxArrayItems {
                items.append(["truncated": array.count - options.maxArrayItems])
            }
            return items
        }
        if typeID == CFDictionaryGetTypeID() {
            var dictionary: [String: Any] = [:]
            for (key, value) in (rawValue as? [AnyHashable: Any]) ?? [:] {
                dictionary["\(key)"] = serialize(value, depth: max(depth - 1, 0))
            }
            return dictionary
        }
        if let url = rawValue as? URL {
            return url.absoluteString
        }
        if let data = rawValue as? Data {
            return ["dataLength": data.count]
        }

        return clipped(String(describing: rawValue))
    }

    private func serializeAXValue(_ value: AXValue) -> Any {
        switch AXValueGetType(value) {
        case .cgPoint:
            var point = CGPoint.zero
            AXValueGetValue(value, .cgPoint, &point)
            return ["x": point.x, "y": point.y]
        case .cgSize:
            var size = CGSize.zero
            AXValueGetValue(value, .cgSize, &size)
            return ["width": size.width, "height": size.height]
        case .cgRect:
            var rect = CGRect.zero
            AXValueGetValue(value, .cgRect, &rect)
            return ["x": rect.origin.x, "y": rect.origin.y, "width": rect.size.width, "height": rect.size.height]
        case .cfRange:
            var range = CFRange()
            AXValueGetValue(value, .cfRange, &range)
            return ["location": range.location, "length": range.length]
        case .axError:
            var error = AXError.success
            AXValueGetValue(value, .axError, &error)
            return ["axError": String(describing: error)]
        case .illegal:
            return ["axValue": "illegal"]
        @unknown default:
            return ["axValue": String(describing: AXValueGetType(value))]
        }
    }

    private func axPoint(_ value: Any) -> CGPoint? {
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

    private func axSize(_ value: Any) -> CGSize? {
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

    private func elementSummary(_ element: AXUIElement) -> [String: Any] {
        [
            "role": stringAttribute(element, kAXRoleAttribute) ?? "",
            "subrole": stringAttribute(element, kAXSubroleAttribute) ?? "",
            "title": stringAttribute(element, kAXTitleAttribute) ?? ""
        ]
    }

    private func clipped(_ value: String) -> String {
        guard value.count > options.maxStringLength else {
            return value
        }
        let end = value.index(value.startIndex, offsetBy: options.maxStringLength)
        return String(value[..<end]) + "...<truncated>"
    }

    private func emitSnapshot(_ snapshot: [String: Any]) {
        let compactData = try! JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])
        if let outputPath = options.outputPath {
            write(data: compactData, to: outputPath)
        }

        guard !options.quiet else {
            return
        }

        if options.json {
            let data = try! JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys])
            print(String(data: data, encoding: .utf8)!)
            return
        }

        print("\u{001B}[2J\u{001B}[H", terminator: "")
        print("FUM AX Vision \(snapshot["timestamp"] ?? "")")
        print("Press Ctrl-C to stop.\n")

        let apps = snapshot["applications"] as? [[String: Any]] ?? []
        for app in apps {
            let name = app["name"] as? String ?? ""
            let pid = app["pid"] as? pid_t ?? 0
            let windows = app["windows"] as? [[String: Any]] ?? []
            guard !windows.isEmpty || options.includeElements else {
                continue
            }

            print("\(name) [pid \(pid)] windows=\(windows.count)")
            for (index, window) in windows.enumerated() {
                let title = window["title"] as? String ?? ""
                let frame = window["frame"] as? [String: Any] ?? [:]
                let x = frame["x"] as? CGFloat ?? 0
                let y = frame["y"] as? CGFloat ?? 0
                let width = frame["width"] as? CGFloat ?? 0
                let height = frame["height"] as? CGFloat ?? 0
                let role = window["role"] as? String ?? ""
                let subrole = window["subrole"] as? String ?? ""
                print("  \(index + 1). \(role)/\(subrole) \(Int(x)),\(Int(y)) \(Int(width))x\(Int(height))  \(title)")
            }
            print("")
        }
    }

    private func write(data: Data, to path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
        } catch {
            fputs("Failed to write snapshot to \(expandedPath): \(error)\n", stderr)
        }
    }
}

struct AXVisionStateRecorder {
    let path: String?
    private var previousState: AXVisionCompactState?

    init(path: String?) {
        self.path = path
    }

    mutating func record(snapshot: [String: Any]) {
        guard let path else {
            return
        }

        let currentState = AXVisionCompactState(snapshot: snapshot)
        let events = AXVisionStateChange.events(from: previousState, to: currentState)
        append(events: events, to: path)
        previousState = currentState
    }

    private func append(events: [[String: Any]], to path: String) {
        guard !events.isEmpty else {
            return
        }

        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: expandedPath) {
                FileManager.default.createFile(atPath: expandedPath, contents: nil)
            }

            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            for event in events {
                let data = try JSONSerialization.data(withJSONObject: event, options: [.sortedKeys])
                try handle.write(contentsOf: data)
                try handle.write(contentsOf: Data("\n".utf8))
            }
            try handle.close()
        } catch {
            fputs("Failed to append AX vision state changes to \(expandedPath): \(error)\n", stderr)
        }
    }
}

struct AXVisionStateChange {
    static func events(from previous: AXVisionCompactState?, to current: AXVisionCompactState) -> [[String: Any]] {
        guard let previous else {
            return [
                current.baseEvent(type: "state_initialized").merging([
                    "applications": current.apps.values.sorted { $0.pid < $1.pid }.map(\.payload),
                    "windows": current.windows.values.sorted { $0.key < $1.key }.map(\.payload)
                ]) { _, new in new }
            ]
        }

        var events: [[String: Any]] = []

        if previous.status != current.status {
            events.append(current.baseEvent(type: "status_changed").merging([
                "from": previous.status,
                "to": current.status,
                "message": current.message ?? NSNull()
            ]) { _, new in new })
        }

        events.append(contentsOf: appEvents(from: previous, to: current))
        events.append(contentsOf: windowEvents(from: previous, to: current))

        return events
    }

    private static func appEvents(from previous: AXVisionCompactState, to current: AXVisionCompactState) -> [[String: Any]] {
        let previousKeys = Set(previous.apps.keys)
        let currentKeys = Set(current.apps.keys)
        var events: [[String: Any]] = []

        for key in currentKeys.subtracting(previousKeys).sorted() {
            guard let app = current.apps[key] else { continue }
            events.append(current.baseEvent(type: "application_added").merging(["application": app.payload]) { _, new in new })
        }

        for key in previousKeys.subtracting(currentKeys).sorted() {
            guard let app = previous.apps[key] else { continue }
            events.append(current.baseEvent(type: "application_removed").merging(["application": app.payload]) { _, new in new })
        }

        for key in previousKeys.intersection(currentKeys).sorted() {
            guard let oldApp = previous.apps[key], let newApp = current.apps[key] else { continue }
            let changes = newApp.changedFields(from: oldApp)
            if !changes.isEmpty {
                events.append(current.baseEvent(type: "application_changed").merging([
                    "application": newApp.identityPayload,
                    "changes": changes
                ]) { _, new in new })
            }
        }

        return events
    }

    private static func windowEvents(from previous: AXVisionCompactState, to current: AXVisionCompactState) -> [[String: Any]] {
        let previousKeys = Set(previous.windows.keys)
        let currentKeys = Set(current.windows.keys)
        var events: [[String: Any]] = []

        for key in currentKeys.subtracting(previousKeys).sorted() {
            guard let window = current.windows[key] else { continue }
            events.append(current.baseEvent(type: "window_added").merging(["window": window.payload]) { _, new in new })
        }

        for key in previousKeys.subtracting(currentKeys).sorted() {
            guard let window = previous.windows[key] else { continue }
            events.append(current.baseEvent(type: "window_removed").merging(["window": window.payload]) { _, new in new })
        }

        for key in previousKeys.intersection(currentKeys).sorted() {
            guard let oldWindow = previous.windows[key], let newWindow = current.windows[key] else { continue }
            let changes = newWindow.changedFields(from: oldWindow)
            if !changes.isEmpty {
                events.append(current.baseEvent(type: "window_changed").merging([
                    "window": newWindow.identityPayload,
                    "changes": changes
                ]) { _, new in new })
            }
        }

        return events
    }
}

struct AXVisionCompactState {
    let timestamp: String
    let status: String
    let message: String?
    let apps: [String: AXVisionAppState]
    let windows: [String: AXVisionWindowState]

    init(snapshot: [String: Any]) {
        timestamp = snapshot["timestamp"] as? String ?? ISO8601DateFormatter().string(from: Date())
        status = snapshot["status"] as? String ?? "unknown"
        message = snapshot["message"] as? String

        let appPayloads = snapshot["applications"] as? [[String: Any]] ?? []
        var appStates: [String: AXVisionAppState] = [:]
        var windowStates: [String: AXVisionWindowState] = [:]

        for appPayload in appPayloads {
            let app = AXVisionAppState(payload: appPayload)
            appStates[app.key] = app

            let windowPayloads = appPayload["windows"] as? [[String: Any]] ?? []
            for (index, windowPayload) in windowPayloads.enumerated() {
                let window = AXVisionWindowState(app: app, index: index, payload: windowPayload)
                windowStates[window.key] = window
            }
        }

        apps = appStates
        windows = windowStates
    }

    func baseEvent(type: String) -> [String: Any] {
        [
            "timestamp": timestamp,
            "type": type,
            "status": status,
            "applicationCount": apps.count,
            "windowCount": windows.count
        ]
    }
}

struct AXVisionAppState: Equatable {
    let pid: Int
    let name: String
    let bundleIdentifier: String
    let isActive: Bool
    let windowCount: Int

    var key: String {
        "pid:\(pid)"
    }

    init(payload: [String: Any]) {
        pid = intValue(payload["pid"])
        name = payload["name"] as? String ?? ""
        bundleIdentifier = payload["bundleIdentifier"] as? String ?? ""
        isActive = boolValue(payload["isActive"])
        windowCount = intValue(payload["windowCount"])
    }

    var identityPayload: [String: Any] {
        [
            "pid": pid,
            "name": name,
            "bundleIdentifier": bundleIdentifier
        ]
    }

    var payload: [String: Any] {
        identityPayload.merging([
            "isActive": isActive,
            "windowCount": windowCount
        ]) { _, new in new }
    }

    func changedFields(from old: AXVisionAppState) -> [String: Any] {
        var changes: [String: Any] = [:]
        addChange(&changes, key: "name", old: old.name, new: name)
        addChange(&changes, key: "bundleIdentifier", old: old.bundleIdentifier, new: bundleIdentifier)
        addChange(&changes, key: "isActive", old: old.isActive, new: isActive)
        addChange(&changes, key: "windowCount", old: old.windowCount, new: windowCount)
        return changes
    }
}

struct AXVisionWindowState: Equatable {
    let key: String
    let appPid: Int
    let appName: String
    let index: Int
    let title: String
    let role: String
    let subrole: String
    let frame: AXVisionFrameState?
    let focused: Bool?
    let minimized: Bool?

    init(app: AXVisionAppState, index: Int, payload: [String: Any]) {
        key = "\(app.key):window:\(index)"
        appPid = app.pid
        appName = app.name
        self.index = index
        title = payload["title"] as? String ?? ""
        role = payload["role"] as? String ?? ""
        subrole = payload["subrole"] as? String ?? ""
        frame = AXVisionFrameState(payload: payload["frame"])
        focused = optionalBoolValue(payload["focused"])
        minimized = optionalBoolValue(payload["minimized"])
    }

    var identityPayload: [String: Any] {
        [
            "key": key,
            "appPid": appPid,
            "appName": appName,
            "index": index,
            "role": role,
            "subrole": subrole
        ]
    }

    var payload: [String: Any] {
        identityPayload.merging([
            "title": title,
            "frame": frame?.payload ?? NSNull(),
            "focused": focused ?? NSNull(),
            "minimized": minimized ?? NSNull()
        ]) { _, new in new }
    }

    func changedFields(from old: AXVisionWindowState) -> [String: Any] {
        var changes: [String: Any] = [:]
        addChange(&changes, key: "title", old: old.title, new: title)
        addChange(&changes, key: "role", old: old.role, new: role)
        addChange(&changes, key: "subrole", old: old.subrole, new: subrole)
        addChange(&changes, key: "frame", old: old.frame?.payload ?? NSNull(), new: frame?.payload ?? NSNull(), changed: old.frame != frame)
        addChange(&changes, key: "focused", old: old.focused ?? NSNull(), new: focused ?? NSNull(), changed: old.focused != focused)
        addChange(&changes, key: "minimized", old: old.minimized ?? NSNull(), new: minimized ?? NSNull(), changed: old.minimized != minimized)
        return changes
    }
}

struct AXVisionFrameState: Equatable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    init?(payload: Any?) {
        guard let payload = payload as? [String: Any] else {
            return nil
        }
        x = intValue(payload["x"])
        y = intValue(payload["y"])
        width = intValue(payload["width"])
        height = intValue(payload["height"])
    }

    var payload: [String: Any] {
        [
            "x": x,
            "y": y,
            "width": width,
            "height": height
        ]
    }
}

func addChange<T: Equatable>(_ changes: inout [String: Any], key: String, old: T, new: T) {
    guard old != new else {
        return
    }
    changes[key] = ["from": old, "to": new]
}

func addChange(_ changes: inout [String: Any], key: String, old: Any, new: Any, changed: Bool) {
    guard changed else {
        return
    }
    changes[key] = ["from": old, "to": new]
}

func intValue(_ value: Any?) -> Int {
    if let value = value as? Int {
        return value
    }
    if let value = value as? Double {
        return Int(value.rounded())
    }
    if let value = value as? CGFloat {
        return Int(value.rounded())
    }
    if let value = value as? NSNumber {
        return value.intValue
    }
    return 0
}

func boolValue(_ value: Any?) -> Bool {
    optionalBoolValue(value) ?? false
}

func optionalBoolValue(_ value: Any?) -> Bool? {
    if let value = value as? Bool {
        return value
    }
    if let value = value as? NSNumber {
        return value.boolValue
    }
    return nil
}

func parseOptions(_ arguments: [String]) -> Options {
    var options = Options()
    var index = 0

    func requireValue(for flag: String) -> String {
        guard index + 1 < arguments.count else {
            fputs("Missing value for \(flag)\n", stderr)
            exit(2)
        }
        index += 1
        return arguments[index]
    }

    while index < arguments.count {
        let argument = arguments[index]
        switch argument {
        case "--background":
            options.quiet = true
            options.prompt = false
            options.waitForPermission = true
            options.outputPath = options.outputPath ?? ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("senses/ax-vision/latest.json").path
            options.changesOutputPath = options.changesOutputPath ?? ПутиПриложения.текущие.память.appendingPathComponent("senses/ax-vision/state-changes.jsonl").path
        case "--request-access":
            options.requestAccess = true
        case "--once":
            options.once = true
        case "--json":
            options.json = true
        case "--quiet":
            options.quiet = true
        case "--include-elements":
            options.includeElements = true
        case "--wait-for-permission":
            options.waitForPermission = true
        case "--no-prompt":
            options.prompt = false
        case "--output":
            options.outputPath = requireValue(for: argument)
        case "--changes-output":
            options.changesOutputPath = requireValue(for: argument)
        case "--no-change-log":
            options.changesOutputPath = nil
        case "--interval":
            options.interval = max(0.1, TimeInterval(requireValue(for: argument)) ?? options.interval)
        case "--permission-retry-interval":
            options.permissionRetryInterval = max(1.0, TimeInterval(requireValue(for: argument)) ?? options.permissionRetryInterval)
        case "--tree-depth":
            options.treeDepth = max(0, Int(requireValue(for: argument)) ?? options.treeDepth)
        case "--pid":
            options.pid = pid_t(Int32(requireValue(for: argument)) ?? 0)
        case "--app":
            options.appName = requireValue(for: argument)
        case "--max-array-items":
            options.maxArrayItems = max(1, Int(requireValue(for: argument)) ?? options.maxArrayItems)
        case "--max-string-length":
            options.maxStringLength = max(80, Int(requireValue(for: argument)) ?? options.maxStringLength)
        case "--help", "-h":
            printHelp()
            exit(0)
        default:
            fputs("Unknown argument: \(argument)\n\n", stderr)
            printHelp()
            exit(2)
        }
        index += 1
    }

    if options.treeDepth > 0 {
        options.includeElements = true
    }

    return options
}

func printHelp() {
    print("""
    fum-ax-vision: realtime macOS Accessibility reader

    Usage:
      fum-ax-vision-sense [options]

    Options:
      --background              Quiet launchd-friendly mode; writes senses/ax-vision/latest.json under FUM_RUNTIME_ROOT and waits for permission.
      --request-access          Ask macOS for Accessibility access and open the Accessibility settings pane.
      --once                    Print one snapshot and exit.
      --json                    Print full JSON instead of the compact realtime view.
      --quiet                   Do not print snapshots to stdout.
      --output <path>           Write the latest snapshot as JSON, atomically replacing the file each interval.
      --changes-output <path>   Append compact AX state changes as JSONL.
      --no-change-log           Disable JSONL state-change recording.
      --interval <seconds>      Polling interval for realtime mode. Default: 0.5.
      --pid <pid>               Read only one process.
      --app <name-or-bundle>    Filter by localized app name or bundle id.
      --include-elements        Include application/child AX element attributes.
      --tree-depth <n>          Recursively inspect AX children to depth n.
      --max-array-items <n>     Limit long AX arrays. Default: 40.
      --max-string-length <n>   Clip long strings. Default: 500.
      --wait-for-permission     Keep running and retry if Accessibility permission is missing.
      --permission-retry-interval <seconds>
                                Retry interval while waiting for permission. Default: 5.
      --no-prompt               Do not open the Accessibility permission prompt.
      --help                    Show this help.

    Examples:
      fum-ax-vision-sense
      fum-ax-vision-sense --request-access
      fum-ax-vision-sense --once --json --app Safari
      fum-ax-vision-sense --background --include-elements --tree-depth 1
      fum-ax-vision-sense --changes-output "$FUM_MEMORY_ROOT/senses/ax-vision/state-changes.jsonl"
      fum-ax-vision-sense --app Finder --include-elements --tree-depth 2 --json
    """)
}

let options = parseOptions(Array(CommandLine.arguments.dropFirst()))
AXVision(options: options).run()
