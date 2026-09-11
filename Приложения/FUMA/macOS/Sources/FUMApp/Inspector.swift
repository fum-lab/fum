import SwiftUI

struct Inspector: View {
    let focus: WorkspaceFocus
    let emphasis: Double
    let prompt: String
    let visionSnapshot: AXVisionUISnapshot
    @ObservedObject var cameraVision: CameraVisionModel
    let inputSnapshot: InputSenseUISnapshot
    @ObservedObject var videoPlayer: VideoPlayerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Inspector")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 20)

            ForEach(metrics) { metric in
                Metric(label: metric.label, value: metric.value, symbol: metric.symbol, color: metric.color)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text(listTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(summaryItems) { item in
                    Label(item.text, systemImage: item.symbol)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(width: 240)
    }

    private var metrics: [InspectorMetric] {
        switch focus {
        case .organs:
            [
                InspectorMetric(label: "AX Vision", value: visionSnapshot.statusLabel, symbol: "eye", color: .teal),
                InspectorMetric(label: "Input", value: inputSnapshot.statusLabel, symbol: "keyboard", color: .orange),
                InspectorMetric(label: "Camera", value: cameraVision.statusLabel, symbol: "camera.viewfinder", color: .indigo),
                InspectorMetric(label: "Gaze", value: cameraVision.gazeStatus, symbol: "cursorarrow.motionlines", color: .cyan),
                InspectorMetric(label: "People", value: cameraVision.faceRecognition.status, symbol: "person.crop.rectangle.stack", color: .mint)
            ]
        case .knowledge:
            [
                InspectorMetric(label: "Глоссарий", value: "Documents/glossary", symbol: "text.book.closed", color: .purple),
                InspectorMetric(label: "Аксиомы", value: "Documents/axioms", symbol: "checkmark.seal", color: .blue),
                InspectorMetric(label: "Индекс", value: "Glossarij.md · Aksiomy_FUM.md", symbol: "list.bullet.rectangle", color: .green)
            ]
        case .vision:
            [
                InspectorMetric(label: "Status", value: visionSnapshot.statusLabel, symbol: focus.symbol, color: focus.color),
                InspectorMetric(label: "Applications", value: "\(visionSnapshot.applications.count)", symbol: "macwindow.on.rectangle", color: .blue),
                InspectorMetric(label: "Windows", value: "\(visionSnapshot.windowCount)", symbol: "rectangle.3.group", color: .orange)
            ]
        case .camera:
            [
                InspectorMetric(label: "Status", value: cameraVision.statusLabel, symbol: focus.symbol, color: focus.color),
                InspectorMetric(label: "Brightness", value: "\(Int(cameraVision.brightness * 100))%", symbol: "sun.max", color: .yellow),
                InspectorMetric(label: "Motion", value: "\(Int(cameraVision.motion * 100))%", symbol: "waveform.path.ecg", color: .indigo),
                InspectorMetric(label: "Gaze", value: cameraVision.gazeStatus, symbol: "eye", color: .cyan),
                InspectorMetric(label: "People", value: cameraVision.faceRecognition.visibleSummary, symbol: "person.crop.rectangle.stack", color: .mint),
                InspectorMetric(label: "Calibration", value: "\(Int(cameraVision.gazeCalibrationProgress * 100))%", symbol: "scope", color: .mint),
                InspectorMetric(label: "Cursor", value: cameraVision.isGazeCursorEnabled ? "Enabled" : "Paused", symbol: "cursorarrow.motionlines", color: .purple)
            ]
        case .video:
            [
                InspectorMetric(label: "Library", value: "\(videoPlayer.videos.count) media items", symbol: focus.symbol, color: focus.color),
                InspectorMetric(label: "Playback", value: videoPlayer.isPlaying ? "Playing" : "Paused", symbol: "waveform", color: .red),
                InspectorMetric(label: "Selected", value: videoPlayer.selectedVideo?.title ?? "None", symbol: "film", color: .purple)
            ]
        case .compose, .map, .review, .ship:
            [
                InspectorMetric(label: "Focus", value: focus.title, symbol: focus.symbol, color: focus.color),
                InspectorMetric(label: "Emphasis", value: "\(Int(emphasis * 100))%", symbol: "slider.horizontal.3", color: .blue),
                InspectorMetric(label: "Prompt", value: prompt, symbol: "text.bubble", color: .green)
            ]
        }
    }

    private var listTitle: String {
        switch focus {
        case .organs:
            return "Organs"
        case .knowledge:
            return "Knowledge Sources"
        case .vision:
            return "Visible Apps"
        case .camera:
            return "Camera Signals"
        case .video:
            return "Video Memory"
        default:
            return "Next Surfaces"
        }
    }

    private var summaryItems: [InspectorSummaryItem] {
        switch focus {
        case .organs:
            return organsSummaries.map { InspectorSummaryItem(text: $0, symbol: "sensor.tag.radiowaves.forward") }
        case .knowledge:
            return [
                "Порядок берется из индексных Markdown-файлов",
                "Поиск смотрит в заголовок, раздел и текст",
                "Файлы открываются наружу из детали"
            ].map { InspectorSummaryItem(text: $0, symbol: "doc.text") }
        case .vision:
            return visionSnapshot.visibleAppSummaries.prefix(6).map { InspectorSummaryItem(text: $0, symbol: "app.window") }
        case .camera:
            return cameraSummaries.map { InspectorSummaryItem(text: $0, symbol: "scope") }
        case .video:
            return videoSummaries.map { InspectorSummaryItem(text: $0, symbol: "play.square.stack") }
        case .compose, .map, .review, .ship:
            return ["Memory browser", "Tool console", "Design trace"].map { InspectorSummaryItem(text: $0, symbol: "square.dashed") }
        }
    }

    private var cameraSummaries: [String] {
        [
            cameraVision.isRunning ? "Preview stream active" : "Preview stream idle",
            cameraVision.frameSize.width > 0 ? "Frame \(Int(cameraVision.frameSize.width))x\(Int(cameraVision.frameSize.height))" : "Waiting for frames",
            cameraVision.gazeSample == nil ? "Waiting for eyes" : "Gaze \(Int((cameraVision.gazeSample?.confidence ?? 0) * 100))%",
            "\(cameraVision.faceRecognition.knownPeople.count) known people",
            cameraVision.faceRecognition.visibleFaces.isEmpty ? "No visible people" : cameraVision.faceRecognition.visibleSummary,
            "Calibration \(Int(cameraVision.gazeCalibrationProgress * 100))%",
            "Local analysis only"
        ]
    }

    private var organsSummaries: [String] {
        [
            "AX windows \(visionSnapshot.windowCount)",
            "Input events \(inputSnapshot.recentEventCount)",
            cameraVision.isRunning ? "Camera online" : "Camera idle",
            cameraVision.faceRecognition.visibleSummary,
            cameraVision.isGazeCursorEnabled ? "Gaze cursor enabled" : "Gaze cursor paused"
        ]
    }

    private var videoSummaries: [String] {
        [
            videoPlayer.statusText,
            videoPlayer.selectedVideo?.directory ?? "No selected directory",
            videoPlayer.duration > 0 ? "\(formatTime(videoPlayer.currentTime)) / \(formatTime(videoPlayer.duration))" : "Timeline idle"
        ]
    }
}

private struct InspectorMetric: Identifiable {
    let label: String
    let value: String
    let symbol: String
    let color: Color

    var id: String {
        "\(label)-\(symbol)"
    }
}

private struct InspectorSummaryItem: Identifiable {
    let text: String
    let symbol: String

    var id: String {
        "\(symbol)-\(text)"
    }
}
