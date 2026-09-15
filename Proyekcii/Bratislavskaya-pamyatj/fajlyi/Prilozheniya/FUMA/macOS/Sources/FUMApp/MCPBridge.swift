#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import Foundation
import SwiftUI

struct MCPScreenPresentation: Equatable, Decodable {
    var timestamp: String
    var status: String
    var title: String
    var text: String
    var format: String
    var source: String
    var expiresAt: String?

    static let empty = MCPScreenPresentation(
        timestamp: "",
        status: "missing",
        title: "",
        text: "",
        format: "plain",
        source: "",
        expiresAt: nil
    )

    var isVisible: Bool {
        status == "presenting"
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isExpired
    }

    var statusLabel: String {
        switch status {
        case "presenting": isVisible ? "Presenting" : "Expired"
        case "cleared": "Cleared"
        case "missing": "No Screen"
        default: status
        }
    }

    var shortTimestamp: String {
        guard !timestamp.isEmpty else {
            return "no timestamp"
        }
        return String(timestamp.suffix(9).dropLast())
    }

    private var isExpired: Bool {
        guard let expiresAt,
              let date = ISO8601DateFormatter().date(from: expiresAt) else {
            return false
        }
        return date <= Date()
    }
}

@MainActor
final class MCPBridgeModel: NSObject, ObservableObject {
    @Published private(set) var screenPresentation = MCPScreenPresentation.empty
    @Published private(set) var lastRefresh = Date.distantPast

    private let screenURL = URL(fileURLWithPath: ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("mcp/screen.json").path)
    private let isoFormatter = ISO8601DateFormatter()
    private let screenChangedNotification = Notification.Name("fum.mcp.screen_changed")

    override init() {
        super.init()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleScreenChangedNotification(_:)),
            name: screenChangedNotification,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    var statusLabel: String {
        screenPresentation.statusLabel
    }

    var detail: String {
        if screenPresentation.isVisible {
            return "\(screenPresentation.source) · \(screenPresentation.shortTimestamp)"
        }
        return screenURL.path
    }

    var isLive: Bool {
        screenPresentation.isVisible || FileManager.default.fileExists(atPath: screenURL.path)
    }

    func reloadNow() {
        defer { lastRefresh = Date() }

        guard let data = try? Data(contentsOf: screenURL) else {
            screenPresentation = .empty
            return
        }

        do {
            screenPresentation = try JSONDecoder().decode(MCPScreenPresentation.self, from: data)
        } catch {
            screenPresentation = MCPScreenPresentation(
                timestamp: isoFormatter.string(from: Date()),
                status: "decode_error",
                title: "",
                text: error.localizedDescription,
                format: "plain",
                source: "FUM.app",
                expiresAt: nil
            )
        }
    }

    func clearScreen() {
        let payload: [String: Any] = [
            "timestamp": isoFormatter.string(from: Date()),
            "status": "cleared",
            "title": "",
            "text": "",
            "format": "plain",
            "source": "FUM.app"
        ]

        do {
            try FileManager.default.createDirectory(at: screenURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: screenURL, options: [.atomic])
            postScreenChanged(status: "cleared")
            reloadNow()
        } catch {
            screenPresentation = MCPScreenPresentation(
                timestamp: isoFormatter.string(from: Date()),
                status: "write_error",
                title: "",
                text: error.localizedDescription,
                format: "plain",
                source: "FUM.app",
                expiresAt: nil
            )
        }
    }

    @objc nonisolated private func handleScreenChangedNotification(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.reloadNow()
        }
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
}

struct MCPScreenOverlay: View {
    @ObservedObject var bridge: MCPBridgeModel

    var body: some View {
        if bridge.screenPresentation.isVisible {
            MCPScreenBanner(presentation: bridge.screenPresentation) {
                bridge.clearScreen()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct MCPScreenBanner: View {
    let presentation: MCPScreenPresentation
    let clearAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "display")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(presentation.title.isEmpty ? "FUM" : presentation.title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(presentation.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(presentation.text)
                    .font(.system(size: 15))
                    .lineLimit(8)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 10)

            Button(action: clearAction) {
                Image(systemName: "xmark")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Clear FUM screen")
        }
        .padding(16)
        .frame(maxWidth: 760, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
    }
}

struct MCPScreenPanel: View {
    @ObservedObject var bridge: MCPBridgeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("MCP Screen", systemImage: "display")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(bridge.screenPresentation.statusLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(bridge.screenPresentation.isVisible ? .green : .secondary)
            }

            if bridge.screenPresentation.isVisible {
                VStack(alignment: .leading, spacing: 6) {
                    Text(bridge.screenPresentation.title.isEmpty ? "FUM" : bridge.screenPresentation.title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(bridge.screenPresentation.text)
                        .font(.system(size: 13))
                        .lineLimit(10)
                        .textSelection(.enabled)
                    Text(bridge.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(bridge.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
