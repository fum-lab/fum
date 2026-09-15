import Foundation
import ПутиИсполнения

typealias JSONObject = [String: Any]

struct AttentionConfig {
    var rootURL: URL
    var memoryRootURL: URL
    var intervalSeconds: TimeInterval
    var idleSeconds: TimeInterval
    var statusEverySeconds: TimeInterval
    var once: Bool
    var verbose: Bool

    static func parse(arguments: [String]) -> AttentionConfig {
        let root = ПутиПриложения.текущие.оперативныеДанные.path
        let memoryRoot = ПутиПриложения.текущие.память.path

        var config = AttentionConfig(
            rootURL: URL(fileURLWithPath: root, isDirectory: true),
            memoryRootURL: URL(fileURLWithPath: memoryRoot, isDirectory: true),
            intervalSeconds: 1,
            idleSeconds: 90,
            statusEverySeconds: 10,
            once: false,
            verbose: false
        )

        var index = 1
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--root":
                if let value = arguments.value(after: &index) {
                    config.rootURL = URL(fileURLWithPath: value, isDirectory: true)
                }
            case "--memory-root":
                if let value = arguments.value(after: &index) {
                    config.memoryRootURL = URL(fileURLWithPath: value, isDirectory: true)
                }
            case "--interval":
                if let value = arguments.value(after: &index), let seconds = TimeInterval(value) {
                    config.intervalSeconds = max(0.25, seconds)
                }
            case "--idle-seconds":
                if let value = arguments.value(after: &index), let seconds = TimeInterval(value) {
                    config.idleSeconds = max(5, seconds)
                }
            case "--status-every":
                if let value = arguments.value(after: &index), let seconds = TimeInterval(value) {
                    config.statusEverySeconds = max(1, seconds)
                }
            case "--once":
                config.once = true
            case "--verbose":
                config.verbose = true
            case "--help", "-h":
                print(Self.helpText)
                Foundation.exit(0)
            default:
                fputs("Unknown argument: \(argument)\n", stderr)
                print(Self.helpText)
                Foundation.exit(2)
            }
            index += 1
        }

        do {
            config.rootURL = try ПутиПриложения.внешнийКаталог(config.rootURL.path)
            config.memoryRootURL = try ПутиПриложения.внешнийКаталог(config.memoryRootURL.path)
        } catch {
            fputs("Runtime and memory must be absolute directories outside Git checkouts.\n", stderr)
            Foundation.exit(2)
        }
        return config
    }

    static let helpText = """
    Usage: fum-attention-loop [options]

    Watches FUM.app runtime snapshots and writes compact realtime attention events.

    Options:
      --root PATH          Runtime directory outside Git. Default: FUM_RUNTIME_ROOT or user Application Support/FUM/run
      --memory-root PATH   Memory directory outside Git. Default: FUM_MEMORY_ROOT or user Application Support/FUM/memory
      --interval SECONDS   Poll interval. Default: 1
      --idle-seconds N     Idle threshold. Default: 90
      --status-every N     Verbose status print interval. Default: 10
      --once               Read once, write latest status, append loop_started, then exit
      --verbose            Print compact status lines
    """
}

extension Array where Element == String {
    func value(after index: inout Int) -> String? {
        let next = index + 1
        guard next < count else {
            fputs("Missing value after \(self[index])\n", stderr)
            Foundation.exit(2)
        }
        index = next
        return self[next]
    }
}

struct ApplicationInfo: Equatable {
    var name: String
    var bundleIdentifier: String
    var pid: Int?

    var payload: JSONObject {
        var result: JSONObject = [
            "name": name,
            "bundleIdentifier": bundleIdentifier
        ]
        if let pid {
            result["pid"] = pid
        }
        return result
    }

    var fingerprint: String {
        "\(bundleIdentifier)|\(name)"
    }

    static func from(_ value: Any?) -> ApplicationInfo? {
        guard let object = value as? JSONObject else {
            return nil
        }
        let name = object["name"] as? String ?? ""
        let bundleIdentifier = object["bundleIdentifier"] as? String ?? ""
        let pid = intValue(object["pid"])
        guard !name.isEmpty || !bundleIdentifier.isEmpty else {
            return nil
        }
        return ApplicationInfo(name: name, bundleIdentifier: bundleIdentifier, pid: pid)
    }
}

struct WindowInfo {
    var title: String
    var role: String
    var frame: JSONObject?

    var payload: JSONObject {
        var result: JSONObject = [
            "title": title,
            "role": role
        ]
        if let frame {
            result["frame"] = frame
        }
        return result
    }

    var fingerprint: String {
        "\(role)|\(title)|\(frameSignature)"
    }

    private var frameSignature: String {
        guard let frame else {
            return ""
        }
        let x = doubleValue(frame["x"]) ?? 0
        let y = doubleValue(frame["y"]) ?? 0
        let width = doubleValue(frame["width"]) ?? 0
        let height = doubleValue(frame["height"]) ?? 0
        return "\(Int(x)):\(Int(y)):\(Int(width)):\(Int(height))"
    }
}

struct InputObservation {
    var status: String
    var message: String
    var snapshotTimestamp: String
    var recentEventCount: Int
    var activeApplication: ApplicationInfo?
    var latestEventAt: Date?
    var recentEvents: [JSONObject]
}

struct AXObservation {
    var status: String
    var message: String
    var snapshotTimestamp: String
    var activeApplication: ApplicationInfo?
    var activeWindow: WindowInfo?
}

final class AttentionLoop {
    private let config: AttentionConfig
    private let isoFormatter = ISO8601DateFormatter()
    private let fractionalISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private var seenInputEventKeys: [String] = []
    private var seenInputEventKeySet = Set<String>()
    private var lastInputStatus: String?
    private var lastAXStatus: String?
    private var lastApplicationFingerprint: String?
    private var lastWindowFingerprint: String?
    private var lastActivityAt: Date?
    private var isIdle = false
    private var totalInputEventsObserved = 0
    private var totalMemoryEventsWritten = 0
    private var lastMemoryEventAt: String?
    private var lastVerboseStatus = Date.distantPast

    init(config: AttentionConfig) {
        self.config = config
    }

    var inputURL: URL {
        config.rootURL.appendingPathComponent("senses/input/latest.json")
    }

    var axURL: URL {
        config.rootURL.appendingPathComponent("senses/ax-vision/latest.json")
    }

    var latestURL: URL {
        config.rootURL.appendingPathComponent("realtime/attention/latest.json")
    }

    var eventsURL: URL {
        config.memoryRootURL.appendingPathComponent("realtime/attention-loop/events.jsonl")
    }

    func run() {
        appendMemoryEvent(type: "loop_started", details: [
            "mode": config.once ? "once" : "loop",
            "intervalSeconds": config.intervalSeconds,
            "idleSeconds": config.idleSeconds,
            "root": config.rootURL.path,
            "eventsPath": eventsURL.path
        ])

        var isFirstTick = true
        repeat {
            tick(seedExistingInputEvents: isFirstTick)
            isFirstTick = false
            if config.once {
                break
            }
            Thread.sleep(forTimeInterval: config.intervalSeconds)
        } while true
    }

    private func tick(seedExistingInputEvents: Bool) {
        let now = Date()
        let input = readInputObservation()
        let ax = readAXObservation()

        let newInputEvents = seedExistingInputEvents
            ? []
            : input.recentEvents.filter { event in
                let key = inputEventFingerprint(event)
                return !seenInputEventKeySet.contains(key)
            }
        rememberInputEvents(input.recentEvents)

        if lastInputStatus != input.status {
            appendMemoryEvent(type: "input_status_changed", details: [
                "previousStatus": lastInputStatus ?? "",
                "status": input.status,
                "message": input.message
            ])
            lastInputStatus = input.status
        }

        if lastAXStatus != ax.status {
            appendMemoryEvent(type: "ax_status_changed", details: [
                "previousStatus": lastAXStatus ?? "",
                "status": ax.status,
                "message": ax.message
            ])
            lastAXStatus = ax.status
        }

        let activeApplication = input.activeApplication ?? ax.activeApplication
        if let activeApplication, lastApplicationFingerprint != activeApplication.fingerprint {
            appendMemoryEvent(type: "application_changed", details: [
                "activeApplication": activeApplication.payload
            ])
            lastApplicationFingerprint = activeApplication.fingerprint
        }

        if let window = ax.activeWindow {
            let fingerprint = "\(ax.activeApplication?.fingerprint ?? "")|\(window.fingerprint)"
            if lastWindowFingerprint != fingerprint {
                var details: JSONObject = [
                    "window": window.payload
                ]
                if let app = ax.activeApplication {
                    details["activeApplication"] = app.payload
                }
                appendMemoryEvent(type: "focus_changed", details: details)
                lastWindowFingerprint = fingerprint
            }
        }

        if !newInputEvents.isEmpty {
            totalInputEventsObserved += newInputEvents.count
            let latestInputAt = latestDate(in: newInputEvents) ?? input.latestEventAt ?? now
            lastActivityAt = latestInputAt
            if isIdle {
                isIdle = false
                appendMemoryEvent(type: "idle_ended", details: [
                    "lastActivityAt": isoFormatter.string(from: latestInputAt)
                ])
            }
            appendInputActivityEvent(newInputEvents, activeApplication: activeApplication, latestInputAt: latestInputAt)
        } else if lastActivityAt == nil {
            lastActivityAt = input.latestEventAt ?? now
        }

        if !isIdle, let lastActivityAt, now.timeIntervalSince(lastActivityAt) >= config.idleSeconds {
            isIdle = true
            appendMemoryEvent(type: "idle_started", details: [
                "idleSeconds": Int(now.timeIntervalSince(lastActivityAt)),
                "lastActivityAt": isoFormatter.string(from: lastActivityAt)
            ])
        }

        writeLatestStatus(now: now, input: input, ax: ax)
        printVerboseStatusIfNeeded(now: now, input: input, ax: ax)
    }

    private func readInputObservation() -> InputObservation {
        guard let snapshot = readJSONFile(inputURL) else {
            return InputObservation(
                status: "missing_snapshot",
                message: "Input snapshot is missing.",
                snapshotTimestamp: "",
                recentEventCount: 0,
                activeApplication: nil,
                latestEventAt: nil,
                recentEvents: []
            )
        }

        let events = (snapshot["recentEvents"] as? [Any] ?? [])
            .compactMap { $0 as? JSONObject }
            .map(sanitizeInputEvent)
        let activeApplication = events
            .compactMap { ApplicationInfo.from($0["activeApplication"]) }
            .first
        let latestEventAt = latestDate(in: events)

        return InputObservation(
            status: snapshot["status"] as? String ?? "unknown",
            message: snapshot["message"] as? String ?? "",
            snapshotTimestamp: snapshot["timestamp"] as? String ?? "",
            recentEventCount: intValue(snapshot["recentEventCount"]) ?? events.count,
            activeApplication: activeApplication,
            latestEventAt: latestEventAt,
            recentEvents: events
        )
    }

    private func readAXObservation() -> AXObservation {
        guard let snapshot = readJSONFile(axURL) else {
            return AXObservation(
                status: "missing_snapshot",
                message: "AX snapshot is missing.",
                snapshotTimestamp: "",
                activeApplication: nil,
                activeWindow: nil
            )
        }

        let applications = snapshot["applications"] as? [Any] ?? []
        let activeAppObject = applications
            .compactMap { $0 as? JSONObject }
            .first { ($0["isActive"] as? Bool) == true }
        let activeApplication = activeAppObject.map { app -> ApplicationInfo in
            ApplicationInfo(
                name: app["name"] as? String ?? "",
                bundleIdentifier: "",
                pid: nil
            )
        }
        let activeWindow = activeAppObject
            .flatMap { $0["windows"] as? [Any] }?
            .compactMap { $0 as? JSONObject }
            .first
            .map { window -> WindowInfo in
                WindowInfo(
                    title: String((window["title"] as? String ?? "").prefix(220)),
                    role: window["role"] as? String ?? "",
                    frame: window["frame"] as? JSONObject
                )
            }

        return AXObservation(
            status: snapshot["status"] as? String ?? "unknown",
            message: snapshot["message"] as? String ?? "",
            snapshotTimestamp: snapshot["timestamp"] as? String ?? "",
            activeApplication: activeApplication,
            activeWindow: activeWindow
        )
    }

    private func sanitizeInputEvent(_ event: JSONObject) -> JSONObject {
        var sanitized: JSONObject = [:]
        for key in ["type", "device", "timestamp", "keyCode", "modifiers", "isAutorepeat", "buttonNumber", "clickState", "scrollPhase"] {
            if let value = event[key] {
                sanitized[key] = value
            }
        }
        if let app = ApplicationInfo.from(event["activeApplication"]) {
            sanitized["activeApplication"] = app.payload
        }
        return sanitized
    }

    private func rememberInputEvents(_ events: [JSONObject]) {
        for event in events {
            let key = inputEventFingerprint(event)
            guard !seenInputEventKeySet.contains(key) else {
                continue
            }
            seenInputEventKeys.append(key)
            seenInputEventKeySet.insert(key)
        }

        if seenInputEventKeys.count > 512 {
            let overflow = seenInputEventKeys.count - 512
            let removed = seenInputEventKeys.prefix(overflow)
            for key in removed {
                seenInputEventKeySet.remove(key)
            }
            seenInputEventKeys.removeFirst(overflow)
        }
    }

    private func appendInputActivityEvent(_ events: [JSONObject], activeApplication: ApplicationInfo?, latestInputAt: Date) {
        var deviceCounts: [String: Int] = [:]
        var eventTypeCounts: [String: Int] = [:]

        for event in events {
            let device = event["device"] as? String ?? "unknown"
            let type = event["type"] as? String ?? "unknown"
            deviceCounts[device, default: 0] += 1
            eventTypeCounts[type, default: 0] += 1
        }

        var details: JSONObject = [
            "eventCount": events.count,
            "deviceCounts": deviceCounts,
            "eventTypes": eventTypeCounts,
            "latestInputAt": isoFormatter.string(from: latestInputAt)
        ]
        if let activeApplication {
            details["activeApplication"] = activeApplication.payload
        }

        appendMemoryEvent(type: "input_activity", details: details)
    }

    private func writeLatestStatus(now: Date, input: InputObservation, ax: AXObservation) {
        var inputPayload: JSONObject = [
            "status": input.status,
            "message": input.message,
            "snapshotTimestamp": input.snapshotTimestamp,
            "recentEventCount": input.recentEventCount
        ]
        if let activeApplication = input.activeApplication {
            inputPayload["activeApplication"] = activeApplication.payload
        }
        if let latestEventAt = input.latestEventAt {
            inputPayload["latestEventAt"] = isoFormatter.string(from: latestEventAt)
        }

        var axPayload: JSONObject = [
            "status": ax.status,
            "message": ax.message,
            "snapshotTimestamp": ax.snapshotTimestamp
        ]
        if let app = ax.activeApplication {
            axPayload["activeApplication"] = app.payload
        }
        if let window = ax.activeWindow {
            axPayload["window"] = window.payload
        }

        var attentionPayload: JSONObject = [
            "isIdle": isIdle,
            "totalInputEventsObserved": totalInputEventsObserved,
            "totalMemoryEventsWritten": totalMemoryEventsWritten
        ]
        if let lastActivityAt {
            attentionPayload["lastActivityAt"] = isoFormatter.string(from: lastActivityAt)
        }
        if let lastMemoryEventAt {
            attentionPayload["lastMemoryEventAt"] = lastMemoryEventAt
        }

        let payload: JSONObject = [
            "timestamp": isoFormatter.string(from: now),
            "status": "ok",
            "source": "fum-attention-loop",
            "pid": ProcessInfo.processInfo.processIdentifier,
            "mode": config.once ? "once" : "loop",
            "intervalSeconds": config.intervalSeconds,
            "idleSeconds": config.idleSeconds,
            "paths": [
                "inputSnapshot": inputURL.path,
                "axSnapshot": axURL.path,
                "events": eventsURL.path
            ],
            "input": inputPayload,
            "ax": axPayload,
            "attention": attentionPayload
        ]
        writeJSONFile(payload, to: latestURL)
    }

    private func appendMemoryEvent(type: String, details: JSONObject) {
        let timestamp = isoFormatter.string(from: Date())
        let payload: JSONObject = [
            "timestamp": timestamp,
            "type": type,
            "source": "fum-attention-loop",
            "details": details
        ]

        do {
            try appendJSONLine(payload, to: eventsURL)
            totalMemoryEventsWritten += 1
            lastMemoryEventAt = timestamp
        } catch {
            fputs("Failed to append attention event: \(error.localizedDescription)\n", stderr)
        }
    }

    private func printVerboseStatusIfNeeded(now: Date, input: InputObservation, ax: AXObservation) {
        guard config.verbose else {
            return
        }
        guard now.timeIntervalSince(lastVerboseStatus) >= config.statusEverySeconds else {
            return
        }
        lastVerboseStatus = now
        let app = input.activeApplication?.name ?? ax.activeApplication?.name ?? "unknown"
        print("\(isoFormatter.string(from: now)) input=\(input.status) ax=\(ax.status) app=\(app) idle=\(isIdle)")
    }

    private func readJSONFile(_ url: URL) -> JSONObject? {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? JSONObject else {
            return nil
        }
        return object
    }

    private func writeJSONFile(_ payload: JSONObject, to url: URL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url, options: [.atomic])
        } catch {
            fputs("Failed to write attention status: \(error.localizedDescription)\n", stderr)
        }
    }

    private func appendJSONLine(_ payload: JSONObject, to url: URL) throws {
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
    }

    private func latestDate(in events: [JSONObject]) -> Date? {
        events
            .compactMap { ($0["timestamp"] as? String).flatMap(parseISODate) }
            .max()
    }

    private func parseISODate(_ string: String) -> Date? {
        fractionalISOFormatter.date(from: string) ?? isoFormatter.date(from: string)
    }

    private func inputEventFingerprint(_ event: JSONObject) -> String {
        let keys = [
            "timestamp",
            "type",
            "device",
            "keyCode",
            "modifiers",
            "isAutorepeat",
            "buttonNumber",
            "clickState",
            "scrollPhase"
        ]
        let parts = keys.map { key -> String in
            guard let value = event[key] else {
                return "\(key)="
            }
            return "\(key)=\(value)"
        }
        let app = ApplicationInfo.from(event["activeApplication"])?.fingerprint ?? ""
        return (parts + ["app=\(app)"]).joined(separator: "|")
    }
}

func intValue(_ value: Any?) -> Int? {
    if let int = value as? Int {
        return int
    }
    if let number = value as? NSNumber {
        return number.intValue
    }
    return nil
}

func doubleValue(_ value: Any?) -> Double? {
    if let double = value as? Double {
        return double
    }
    if let number = value as? NSNumber {
        return number.doubleValue
    }
    return nil
}

let config = AttentionConfig.parse(arguments: CommandLine.arguments)
AttentionLoop(config: config).run()
