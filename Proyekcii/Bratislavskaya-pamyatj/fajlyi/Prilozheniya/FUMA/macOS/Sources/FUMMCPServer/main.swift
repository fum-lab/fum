import Foundation
#if SWIFT_PACKAGE
import ПутиИсполнения
#endif

typealias JSONObject = [String: Any]

struct ToolFailure: Error {
    let message: String
}

final class FUMMCPServer {
    private let protocolVersion = "2025-06-18"
    private let output = FileHandle.standardOutput
    private let rootURL: URL
    private let codexMemoryURL: URL
    private let isoFormatter = ISO8601DateFormatter()
    private let screenChangedNotification = Notification.Name("fum.mcp.screen_changed")

    init() {
        let root = ПутиПриложения.текущие.оперативныеДанные.path
        rootURL = URL(fileURLWithPath: root, isDirectory: true)
        codexMemoryURL = ПутиПриложения.текущие.память
    }

    var screenURL: URL {
        rootURL.appendingPathComponent("mcp/screen.json")
    }

    var axSnapshotURL: URL {
        rootURL.appendingPathComponent("senses/ax-vision/latest.json")
    }

    var inputSnapshotURL: URL {
        rootURL.appendingPathComponent("senses/input/latest.json")
    }

    var attentionStatusURL: URL {
        rootURL.appendingPathComponent("realtime/attention/latest.json")
    }

    var memoryNotesURL: URL {
        codexMemoryURL.appendingPathComponent("mcp/notes.jsonl")
    }

    func run() {
        while let line = readLine() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            guard let data = trimmed.data(using: .utf8) else {
                writeJSON(errorResponse(id: nil, code: -32700, message: "Input is not valid UTF-8."))
                continue
            }

            do {
                let message = try JSONSerialization.jsonObject(with: data)
                if let batch = message as? [Any] {
                    let responses = batch.compactMap(handle)
                    if !responses.isEmpty {
                        writeJSON(responses)
                    }
                } else if let response = handle(message) {
                    writeJSON(response)
                }
            } catch {
                writeJSON(errorResponse(id: nil, code: -32700, message: "Could not parse JSON-RPC message."))
            }
        }
    }

    private func handle(_ rawMessage: Any) -> JSONObject? {
        guard let message = rawMessage as? JSONObject else {
            return errorResponse(id: nil, code: -32600, message: "JSON-RPC message must be an object.")
        }

        let id = message["id"]
        guard let method = message["method"] as? String else {
            return errorResponse(id: id, code: -32600, message: "JSON-RPC method is required.")
        }

        if id == nil {
            if method == "notifications/initialized" || method == "notifications/cancelled" || method == "exit" {
                return nil
            }
            return nil
        }

        let params = message["params"] as? JSONObject ?? [:]

        do {
            switch method {
            case "initialize":
                return response(id: id, result: initializeResult(params: params))
            case "ping":
                return response(id: id, result: [:])
            case "tools/list":
                return response(id: id, result: ["tools": tools()])
            case "tools/call":
                return response(id: id, result: try callTool(params: params))
            case "resources/list":
                return response(id: id, result: ["resources": resources()])
            case "resources/read":
                return response(id: id, result: try readResource(params: params))
            case "prompts/list":
                return response(id: id, result: ["prompts": []])
            case "logging/setLevel", "shutdown":
                return response(id: id, result: [:])
            default:
                return errorResponse(id: id, code: -32601, message: "Unsupported MCP method: \(method)")
            }
        } catch let failure as ToolFailure {
            return response(id: id, result: toolResult(text: failure.message, isError: true))
        } catch {
            return response(id: id, result: toolResult(text: error.localizedDescription, isError: true))
        }
    }

    private func initializeResult(params: JSONObject) -> JSONObject {
        let requested = params["protocolVersion"] as? String
        return [
            "protocolVersion": requested?.isEmpty == false ? requested as Any : protocolVersion,
            "capabilities": [
                "tools": ["listChanged": false],
                "resources": ["listChanged": false, "subscribe": false]
            ],
            "serverInfo": [
                "name": "fum-mcp",
                "title": "FUM Local MCP Gateway",
                "version": "0.1.0",
                "description": "Local gateway for FUM.app screen, input, AX vision, and memory."
            ],
            "instructions": "Use this server as the local FUM body bridge. Read status before assuming organs are live. Use screen_present for short visible messages in FUM.app. Use ax_snapshot and input_recent_events for summarized local state; do not request raw high-frequency input streams."
        ]
    }

    private func tools() -> [JSONObject] {
        [
            [
                "name": "status",
                "title": "FUM Status",
                "description": "Return FUM.app process, bridge files, and latest organ snapshot status.",
                "inputSchema": objectSchema()
            ],
            [
                "name": "screen_present",
                "title": "Present On FUM Screen",
                "description": "Show a short plaintext or markdown message in the FUM.app screen bridge.",
                "inputSchema": objectSchema(
                    properties: [
                        "title": ["type": "string", "description": "Short optional title."],
                        "text": ["type": "string", "description": "Message to present in FUM.app."],
                        "format": ["type": "string", "enum": ["plain", "markdown"], "description": "Message format. Default: markdown."],
                        "source": ["type": "string", "description": "Human-readable source label. Default: Codex MCP."],
                        "ttlSeconds": ["type": "number", "minimum": 1, "maximum": 86_400, "description": "Optional expiry interval."]
                    ],
                    required: ["text"]
                )
            ],
            [
                "name": "screen_clear",
                "title": "Clear FUM Screen",
                "description": "Clear the current MCP-provided screen presentation in FUM.app.",
                "inputSchema": objectSchema()
            ],
            [
                "name": "ax_snapshot",
                "title": "AX Vision Snapshot",
                "description": "Read the latest Accessibility window snapshot written by FUM.app.",
                "inputSchema": objectSchema(
                    properties: [
                        "maxBytes": ["type": "integer", "minimum": 1024, "maximum": 262_144, "description": "Maximum returned raw JSON bytes. Default: 65536."]
                    ]
                )
            ],
            [
                "name": "input_recent_events",
                "title": "Recent Input Events",
                "description": "Return the latest listen-only keyboard, mouse, and trackpad events summarized by FUM.app.",
                "inputSchema": objectSchema(
                    properties: [
                        "limit": ["type": "integer", "minimum": 1, "maximum": 32, "description": "Maximum number of recent events. Default: 12."],
                        "includeCharacters": ["type": "boolean", "description": "Include typed character fields. Default: false."]
                    ]
                )
            ],
            [
                "name": "attention_status",
                "title": "Realtime Attention Status",
                "description": "Read the latest status written by fum-attention-loop.",
                "inputSchema": objectSchema(
                    properties: [
                        "maxBytes": ["type": "integer", "minimum": 1024, "maximum": 262_144, "description": "Maximum returned raw JSON bytes. Default: 65536."]
                    ]
                )
            ],
            [
                "name": "memory_note",
                "title": "Append FUM Memory Note",
                "description": "Append a structured note to FUM MCP memory.",
                "inputSchema": objectSchema(
                    properties: [
                        "title": ["type": "string", "description": "Short optional title."],
                        "text": ["type": "string", "description": "Memory note body."],
                        "tags": ["type": "array", "items": ["type": "string"], "description": "Optional tags."]
                    ],
                    required: ["text"]
                )
            ],
            [
                "name": "memory_search",
                "title": "Search FUM Memory",
                "description": "Search FUM MCP notes plus the local glossary and axioms shelves.",
                "inputSchema": objectSchema(
                    properties: [
                        "query": ["type": "string", "description": "Case-insensitive search query."],
                        "limit": ["type": "integer", "minimum": 1, "maximum": 30, "description": "Maximum hits. Default: 8."]
                    ],
                    required: ["query"]
                )
            ]
        ]
    }

    private func resources() -> [JSONObject] {
        [
            [
                "uri": "fum://status",
                "name": "status",
                "title": "FUM Status",
                "description": "FUM bridge status as JSON.",
                "mimeType": "application/json"
            ],
            [
                "uri": "fum://screen",
                "name": "screen",
                "title": "FUM Screen Bridge",
                "description": "Current MCP screen presentation state.",
                "mimeType": "application/json"
            ],
            [
                "uri": "fum://ax-snapshot",
                "name": "ax-snapshot",
                "title": "AX Vision Snapshot",
                "description": "Latest persisted AX vision snapshot.",
                "mimeType": "application/json"
            ],
            [
                "uri": "fum://input-events",
                "name": "input-events",
                "title": "Input Events Snapshot",
                "description": "Latest persisted input events snapshot.",
                "mimeType": "application/json"
            ],
            [
                "uri": "fum://attention-status",
                "name": "attention-status",
                "title": "Realtime Attention Status",
                "description": "Latest status written by fum-attention-loop.",
                "mimeType": "application/json"
            ],
            [
                "uri": "fum://memory-notes",
                "name": "memory-notes",
                "title": "MCP Memory Notes",
                "description": "Recent notes appended through the FUM MCP gateway.",
                "mimeType": "application/x-ndjson"
            ]
        ]
    }

    private func callTool(params: JSONObject) throws -> JSONObject {
        guard let name = params["name"] as? String else {
            throw ToolFailure(message: "tools/call requires params.name.")
        }
        let arguments = params["arguments"] as? JSONObject ?? [:]

        switch name {
        case "status":
            let status = statusPayload()
            return toolResult(text: prettyJSONString(status), structuredContent: status)
        case "screen_present":
            return try screenPresent(arguments: arguments)
        case "screen_clear":
            return try screenClear()
        case "ax_snapshot":
            return readSnapshotTool(url: axSnapshotURL, label: "AX vision", arguments: arguments)
        case "input_recent_events":
            return try inputRecentEvents(arguments: arguments)
        case "attention_status":
            return readSnapshotTool(url: attentionStatusURL, label: "Attention loop", arguments: arguments)
        case "memory_note":
            return try memoryNote(arguments: arguments)
        case "memory_search":
            return try memorySearch(arguments: arguments)
        default:
            throw ToolFailure(message: "Unknown FUM tool: \(name)")
        }
    }

    private func readResource(params: JSONObject) throws -> JSONObject {
        guard let uri = params["uri"] as? String else {
            throw ToolFailure(message: "resources/read requires params.uri.")
        }

        let text: String
        let mimeType: String
        switch uri {
        case "fum://status":
            text = prettyJSONString(statusPayload())
            mimeType = "application/json"
        case "fum://screen":
            text = readTextFile(screenURL, maxBytes: 128 * 1024).text ?? missingResourceJSON(path: screenURL.path)
            mimeType = "application/json"
        case "fum://ax-snapshot":
            text = readTextFile(axSnapshotURL, maxBytes: 256 * 1024).text ?? missingResourceJSON(path: axSnapshotURL.path)
            mimeType = "application/json"
        case "fum://input-events":
            text = readTextFile(inputSnapshotURL, maxBytes: 128 * 1024).text ?? missingResourceJSON(path: inputSnapshotURL.path)
            mimeType = "application/json"
        case "fum://attention-status":
            text = readTextFile(attentionStatusURL, maxBytes: 128 * 1024).text ?? missingResourceJSON(path: attentionStatusURL.path)
            mimeType = "application/json"
        case "fum://memory-notes":
            text = recentLines(from: memoryNotesURL, maxLines: 100, maxBytes: 128 * 1024) ?? ""
            mimeType = "application/x-ndjson"
        default:
            throw ToolFailure(message: "Unknown FUM resource URI: \(uri)")
        }

        return [
            "contents": [
                [
                    "uri": uri,
                    "mimeType": mimeType,
                    "text": text
                ]
            ]
        ]
    }

    private func screenPresent(arguments: JSONObject) throws -> JSONObject {
        guard let rawText = arguments["text"] as? String else {
            throw ToolFailure(message: "screen_present requires text.")
        }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ToolFailure(message: "screen_present text must not be empty.")
        }

        let now = Date()
        var payload: JSONObject = [
            "timestamp": isoFormatter.string(from: now),
            "status": "presenting",
            "title": stringArgument(arguments, "title", defaultValue: "FUM"),
            "text": text,
            "format": stringArgument(arguments, "format", defaultValue: "markdown"),
            "source": stringArgument(arguments, "source", defaultValue: "Codex MCP")
        ]

        let ttlSeconds = doubleArgument(arguments, "ttlSeconds", defaultValue: 0, minimum: 0, maximum: 86_400)
        if ttlSeconds > 0 {
            payload["expiresAt"] = isoFormatter.string(from: now.addingTimeInterval(ttlSeconds))
        }

        try writeJSONFile(payload, to: screenURL)
        postScreenChanged(status: "presenting")
        return toolResult(
            text: "Presented \(text.count) characters on the FUM screen bridge.",
            structuredContent: [
                "path": screenURL.path,
                "presentation": payload
            ]
        )
    }

    private func screenClear() throws -> JSONObject {
        let payload: JSONObject = [
            "timestamp": isoFormatter.string(from: Date()),
            "status": "cleared",
            "title": "",
            "text": "",
            "format": "plain",
            "source": "Codex MCP"
        ]
        try writeJSONFile(payload, to: screenURL)
        postScreenChanged(status: "cleared")
        return toolResult(
            text: "Cleared the FUM screen bridge.",
            structuredContent: [
                "path": screenURL.path,
                "presentation": payload
            ]
        )
    }

    private func readSnapshotTool(url: URL, label: String, arguments: JSONObject) -> JSONObject {
        let maxBytes = intArgument(arguments, "maxBytes", defaultValue: 65_536, minimum: 1_024, maximum: 262_144)
        let result = readTextFile(url, maxBytes: maxBytes)
        guard let text = result.text else {
            return toolResult(
                text: "\(label) snapshot is missing at \(url.path).",
                structuredContent: ["path": url.path, "status": "missing_snapshot"],
                isError: true
            )
        }

        var structured: JSONObject = [
            "path": url.path,
            "truncated": result.truncated
        ]
        if !result.truncated, let data = text.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) {
            structured["snapshot"] = object
        } else {
            structured["rawText"] = text
        }

        return toolResult(
            text: "\(label) snapshot from \(url.path):\n\(text)",
            structuredContent: structured
        )
    }

    private func inputRecentEvents(arguments: JSONObject) throws -> JSONObject {
        let limit = intArgument(arguments, "limit", defaultValue: 12, minimum: 1, maximum: 32)
        let includeCharacters = boolArgument(arguments, "includeCharacters", defaultValue: false)
        guard let snapshot = readJSONFile(inputSnapshotURL) as? JSONObject else {
            return toolResult(
                text: "Input snapshot is missing at \(inputSnapshotURL.path).",
                structuredContent: ["path": inputSnapshotURL.path, "status": "missing_snapshot"],
                isError: true
            )
        }

        let events = snapshot["recentEvents"] as? [Any] ?? []
        let limitedEvents = events.prefix(limit).map { sanitizeInputEvent($0, includeCharacters: includeCharacters) }
        let structured: JSONObject = [
            "path": inputSnapshotURL.path,
            "timestamp": snapshot["timestamp"] ?? "",
            "status": snapshot["status"] ?? "unknown",
            "message": snapshot["message"] ?? "",
            "recentEventCount": snapshot["recentEventCount"] ?? events.count,
            "returnedEventCount": limitedEvents.count,
            "charactersIncluded": includeCharacters,
            "recentEvents": limitedEvents
        ]

        return toolResult(
            text: prettyJSONString(structured),
            structuredContent: structured
        )
    }

    private func memoryNote(arguments: JSONObject) throws -> JSONObject {
        guard let rawText = arguments["text"] as? String else {
            throw ToolFailure(message: "memory_note requires text.")
        }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ToolFailure(message: "memory_note text must not be empty.")
        }

        let tags = (arguments["tags"] as? [Any])?.compactMap { $0 as? String } ?? []
        let note: JSONObject = [
            "timestamp": isoFormatter.string(from: Date()),
            "title": stringArgument(arguments, "title", defaultValue: ""),
            "text": text,
            "tags": tags,
            "source": "fum-mcp"
        ]

        try appendJSONLine(note, to: memoryNotesURL)
        return toolResult(
            text: "Appended FUM memory note.",
            structuredContent: [
                "path": memoryNotesURL.path,
                "note": note
            ]
        )
    }

    private func memorySearch(arguments: JSONObject) throws -> JSONObject {
        guard let rawQuery = arguments["query"] as? String else {
            throw ToolFailure(message: "memory_search requires query.")
        }
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw ToolFailure(message: "memory_search query must not be empty.")
        }

        let limit = intArgument(arguments, "limit", defaultValue: 8, minimum: 1, maximum: 30)
        let lowerQuery = query.lowercased()
        var hits: [JSONObject] = []

        for url in searchableMemoryFiles() {
            guard hits.count < limit else {
                break
            }
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }
            let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() where hits.count < limit {
                let value = String(line)
                if value.lowercased().contains(lowerQuery) {
                    hits.append([
                        "path": url.path,
                        "line": index + 1,
                        "snippet": snippet(value)
                    ])
                }
            }
        }

        let structured: JSONObject = [
            "query": query,
            "hitCount": hits.count,
            "hits": hits
        ]
        return toolResult(text: prettyJSONString(structured), structuredContent: structured)
    }

    private func statusPayload() -> JSONObject {
        let pids = processOutput(ProcessInfo.processInfo.environment["FUM_PGREP_EXECUTABLE"] ?? "pgrep", arguments: ["-x", "FUM"])?
            .split(separator: "\n")
            .map { String($0) } ?? []

        return [
            "timestamp": isoFormatter.string(from: Date()),
            "root": rootURL.path,
            "app": [
                "bundlePath": ProcessInfo.processInfo.environment["FUM_APP_BUNDLE"] as Any? ?? NSNull(),
                "processName": "FUM",
                "isRunning": !pids.isEmpty,
                "pids": pids
            ],
            "files": [
                "screen": fileStatus(screenURL),
                "axSnapshot": fileStatus(axSnapshotURL),
                "inputSnapshot": fileStatus(inputSnapshotURL),
                "attentionStatus": fileStatus(attentionStatusURL),
                "memoryNotes": fileStatus(memoryNotesURL)
            ]
        ]
    }

    private func objectSchema(properties: JSONObject = [:], required: [String] = []) -> JSONObject {
        var schema: JSONObject = [
            "type": "object",
            "properties": properties,
            "additionalProperties": false
        ]
        if !required.isEmpty {
            schema["required"] = required
        }
        return schema
    }

    private func toolResult(text: String, structuredContent: JSONObject? = nil, isError: Bool = false) -> JSONObject {
        var result: JSONObject = [
            "content": [
                [
                    "type": "text",
                    "text": text
                ]
            ],
            "isError": isError
        ]
        if let structuredContent {
            result["structuredContent"] = structuredContent
        }
        return result
    }

    private func response(id: Any?, result: JSONObject) -> JSONObject {
        [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": result
        ]
    }

    private func errorResponse(id: Any?, code: Int, message: String) -> JSONObject {
        [
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }

    private func writeJSON(_ object: Any) {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return
        }
        output.write(data)
        output.write(Data("\n".utf8))
    }

    private func prettyJSONString(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return "\(object)"
        }
        return text
    }

    private func readJSONFile(_ url: URL) -> Any? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private func readTextFile(_ url: URL, maxBytes: Int) -> (text: String?, truncated: Bool) {
        guard let data = try? Data(contentsOf: url) else {
            return (nil, false)
        }
        let truncated = data.count > maxBytes
        let prefix = truncated ? Data(data.prefix(maxBytes)) : data
        return (String(data: prefix, encoding: .utf8), truncated)
    }

    private func writeJSONFile(_ payload: JSONObject, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: [.atomic])
    }

    private func postScreenChanged(status: String) {
        DistributedNotificationCenter.default().postNotificationName(
            screenChangedNotification,
            object: nil,
            userInfo: [
                "path": screenURL.path,
                "status": status
            ],
            deliverImmediately: true
        )
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

    private func fileStatus(_ url: URL) -> JSONObject {
        let manager = FileManager.default
        guard let attributes = try? manager.attributesOfItem(atPath: url.path) else {
            return [
                "path": url.path,
                "exists": false
            ]
        }
        return [
            "path": url.path,
            "exists": true,
            "size": attributes[.size] as? Int ?? 0,
            "modifiedAt": (attributes[.modificationDate] as? Date).map(isoFormatter.string(from:)) ?? ""
        ]
    }

    private func missingResourceJSON(path: String) -> String {
        prettyJSONString([
            "status": "missing",
            "path": path
        ])
    }

    private func recentLines(from url: URL, maxLines: Int, maxBytes: Int) -> String? {
        guard let text = readTextFile(url, maxBytes: maxBytes).text else {
            return nil
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).suffix(maxLines)
        return lines.joined(separator: "\n")
    }

    private func searchableMemoryFiles() -> [URL] {
        var urls: [URL] = [
            rootURL.appendingPathComponent("README.md"),
            memoryNotesURL
        ]

        let documentsFUM = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/FUM", isDirectory: true)
        for directoryName in ["glossary", "axioms"] {
            let directory = documentsFUM.appendingPathComponent(directoryName, isDirectory: true)
            urls.append(contentsOf: files(in: directory, allowedExtensions: ["md", "txt", "jsonl"], limit: 400))
        }

        return urls
    }

    private func files(in directory: URL, allowedExtensions: Set<String>, limit: Int) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            guard urls.count < limit else {
                break
            }
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            if values?.isRegularFile == true && allowedExtensions.contains(url.pathExtension.lowercased()) {
                urls.append(url)
            }
        }
        return urls
    }

    private func snippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 220 else {
            return trimmed
        }
        return String(trimmed.prefix(220)) + "..."
    }

    private func stringArgument(_ arguments: JSONObject, _ name: String, defaultValue: String) -> String {
        guard let value = arguments[name] as? String, !value.isEmpty else {
            return defaultValue
        }
        return value
    }

    private func intArgument(_ arguments: JSONObject, _ name: String, defaultValue: Int, minimum: Int, maximum: Int) -> Int {
        let value: Int
        if let int = arguments[name] as? Int {
            value = int
        } else if let number = arguments[name] as? NSNumber {
            value = number.intValue
        } else {
            value = defaultValue
        }
        return min(max(value, minimum), maximum)
    }

    private func boolArgument(_ arguments: JSONObject, _ name: String, defaultValue: Bool) -> Bool {
        if let value = arguments[name] as? Bool {
            return value
        }
        if let number = arguments[name] as? NSNumber {
            return number.boolValue
        }
        return defaultValue
    }

    private func sanitizeInputEvent(_ event: Any, includeCharacters: Bool) -> Any {
        guard !includeCharacters, var payload = event as? JSONObject else {
            return event
        }

        if payload["characters"] != nil {
            payload["characters"] = "[redacted]"
        }
        if payload["charactersIgnoringModifiers"] != nil {
            payload["charactersIgnoringModifiers"] = "[redacted]"
        }
        return payload
    }

    private func doubleArgument(_ arguments: JSONObject, _ name: String, defaultValue: Double, minimum: Double, maximum: Double) -> Double {
        let value: Double
        if let double = arguments[name] as? Double {
            value = double
        } else if let number = arguments[name] as? NSNumber {
            value = number.doubleValue
        } else {
            value = defaultValue
        }
        return min(max(value, minimum), maximum)
    }

    private func processOutput(_ executable: String, arguments: [String]) -> String? {
        guard let путь = ПутиПриложения.исполняемыйФайл(executable) else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = путь
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}

FUMMCPServer().run()
