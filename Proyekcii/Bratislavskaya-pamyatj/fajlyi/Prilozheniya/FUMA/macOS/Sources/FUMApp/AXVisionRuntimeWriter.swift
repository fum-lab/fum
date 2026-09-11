#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import Foundation

enum AXVisionRuntimeWriter {
    private static let outputURL = URL(fileURLWithPath: ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("senses/ax-vision/latest.json").path)

    static func write(_ snapshot: AXVisionUISnapshot) {
        let payload: [String: Any] = [
            "timestamp": snapshot.timestamp,
            "status": snapshot.status,
            "message": snapshot.message ?? "",
            "source": "FUM.app",
            "applications": snapshot.applications.map(applicationPayload)
        ]

        do {
            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: outputURL, options: [.atomic])
        } catch {
            NSLog("Failed to write AX vision runtime snapshot: \(error.localizedDescription)")
        }
    }

    private static func applicationPayload(_ app: AXVisionUIApp) -> [String: Any] {
        [
            "name": app.name,
            "isActive": app.isActive,
            "windows": app.windows.map(windowPayload)
        ]
    }

    private static func windowPayload(_ window: AXVisionUIWindow) -> [String: Any] {
        var payload: [String: Any] = [
            "title": window.title,
            "role": window.role
        ]

        if let frame = window.frame {
            payload["frame"] = [
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height
            ]
        }

        return payload
    }
}
