import AppKit
import AVFoundation
import SwiftUI

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.cameraLayer.session = session
        return view
    }

    func updateNSView(_ view: CameraPreviewNSView, context: Context) {
        view.cameraLayer.session = session
    }
}

final class CameraPreviewNSView: NSView {
    private let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        let hostLayer = CALayer()
        hostLayer.masksToBounds = true
        layer = hostLayer

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.masksToBounds = true
        hostLayer.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    var cameraLayer: AVCaptureVideoPreviewLayer {
        previewLayer
    }

    override func layout() {
        super.layout()
        layer?.masksToBounds = true
        previewLayer.frame = bounds
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        previewLayer.frame = bounds
    }
}

struct CameraVisionSurface: View {
    @ObservedObject var cameraVision: CameraVisionModel
    let showGrid: Bool

    var body: some View {
        ZStack {
            if cameraVision.canPreview {
                CameraPreviewView(session: cameraVision.session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay {
                        CameraVisionOverlay(
                            brightness: cameraVision.brightness,
                            motion: cameraVision.motion,
                            gazeSample: cameraVision.gazeSample,
                            visibleFaces: cameraVision.faceRecognition.visibleFaces,
                            frameSize: cameraVision.frameSize,
                            showGrid: showGrid
                        )
                    }
            } else {
                CameraPermissionSurface(cameraVision: cameraVision)
            }
        }
        .clipped()
        .background(Color(nsColor: .textBackgroundColor))
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Camera Vision", systemImage: cameraVision.canPreview ? "camera.viewfinder" : "lock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(cameraVision.canPreview ? .indigo : .orange)
                Text(cameraVision.statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
        .overlay(alignment: .topTrailing) {
            if cameraVision.canPreview {
                CameraPeoplePanel(cameraVision: cameraVision)
                    .padding(18)
            }
        }
        .onAppear {
            if FUMFeatureFlags.cameraEnabled {
                cameraVision.start()
            }
        }
    }
}

struct CameraVisionOverlay: View {
    let brightness: Double
    let motion: Double
    let gazeSample: CameraGazeSample?
    let visibleFaces: [RecognizedCameraFace]
    let frameSize: CGSize
    let showGrid: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            Canvas { canvas, size in
                let rect = CGRect(origin: .zero, size: size)
                let time = context.date.timeIntervalSinceReferenceDate

                canvas.fill(Path(rect), with: .color(.black.opacity(0.10)))

                if showGrid {
                    drawGrid(in: rect, on: canvas)
                }

                drawReticle(in: rect, on: canvas, time: time)
                drawMotionScan(in: rect, on: canvas, time: time)
                drawFaces(in: rect, on: canvas)
                drawGaze(in: rect, on: canvas)
                drawMeter(in: rect, on: canvas)
            }
        }
    }

    private func drawGrid(in rect: CGRect, on canvas: GraphicsContext) {
        var path = Path()
        let step: CGFloat = 42

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        canvas.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
    }

    private func drawReticle(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * CGFloat(0.12 + motion * 0.07)
        let alpha = 0.42 + sin(time * 2.2) * 0.10
        canvas.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(.indigo.opacity(alpha)), lineWidth: 2)
        canvas.stroke(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(.white.opacity(0.8)), lineWidth: 1)

        var crosshair = Path()
        crosshair.move(to: CGPoint(x: center.x - radius - 24, y: center.y))
        crosshair.addLine(to: CGPoint(x: center.x - radius + 18, y: center.y))
        crosshair.move(to: CGPoint(x: center.x + radius - 18, y: center.y))
        crosshair.addLine(to: CGPoint(x: center.x + radius + 24, y: center.y))
        crosshair.move(to: CGPoint(x: center.x, y: center.y - radius - 24))
        crosshair.addLine(to: CGPoint(x: center.x, y: center.y - radius + 18))
        crosshair.move(to: CGPoint(x: center.x, y: center.y + radius - 18))
        crosshair.addLine(to: CGPoint(x: center.x, y: center.y + radius + 24))
        canvas.stroke(crosshair, with: .color(.white.opacity(0.48)), lineWidth: 1)
    }

    private func drawMotionScan(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        let progress = CGFloat(time.remainder(dividingBy: 2.4) / 2.4)
        let y = rect.minY + rect.height * progress
        let band = CGRect(x: rect.minX, y: y - 18, width: rect.width, height: 36)
        canvas.fill(Path(band), with: .linearGradient(
            Gradient(colors: [.clear, .indigo.opacity(0.16 + motion * 0.36), .clear]),
            startPoint: CGPoint(x: band.midX, y: band.minY),
            endPoint: CGPoint(x: band.midX, y: band.maxY)
        ))
        canvas.stroke(Path(CGRect(x: rect.minX, y: y, width: rect.width, height: 1)), with: .color(.white.opacity(0.36)), lineWidth: 1)
    }

    private func drawMeter(in rect: CGRect, on canvas: GraphicsContext) {
        let panel = CGRect(x: rect.maxX - 190, y: rect.minY + 24, width: 154, height: 74)
        canvas.fill(Path(roundedRect: panel, cornerRadius: 8), with: .color(.black.opacity(0.36)))
        drawBar(label: "Light", value: brightness, y: panel.minY + 18, panel: panel, on: canvas, color: .yellow)
        drawBar(label: "Motion", value: motion, y: panel.minY + 46, panel: panel, on: canvas, color: .indigo)

        if frameSize.width > 0 {
            let text = Text("\(Int(frameSize.width))x\(Int(frameSize.height))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            canvas.draw(text, at: CGPoint(x: panel.maxX - 12, y: panel.maxY - 9), anchor: .trailing)
        }
    }

    private func drawBar(label: String, value: Double, y: CGFloat, panel: CGRect, on canvas: GraphicsContext, color: Color) {
        let text = Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.82))
        canvas.draw(text, at: CGPoint(x: panel.minX + 12, y: y), anchor: .leading)

        let track = CGRect(x: panel.minX + 62, y: y - 4, width: 72, height: 8)
        canvas.fill(Path(roundedRect: track, cornerRadius: 4), with: .color(.white.opacity(0.16)))
        canvas.fill(Path(roundedRect: CGRect(x: track.minX, y: track.minY, width: track.width * CGFloat(min(max(value, 0), 1)), height: track.height), cornerRadius: 4), with: .color(color.opacity(0.86)))
    }

    private func drawFaces(in rect: CGRect, on canvas: GraphicsContext) {
        for face in visibleFaces {
            let box = faceBox(face.boundingBox, in: rect)
            let color = face.isKnown ? Color.green : Color.orange
            let lineWidth: CGFloat = face.isKnown ? 2.5 : 1.6
            let path = Path(roundedRect: box, cornerRadius: 8)
            canvas.stroke(path, with: .color(color.opacity(0.88)), lineWidth: lineWidth)
            canvas.fill(path, with: .color(color.opacity(face.isKnown ? 0.08 : 0.05)))

            let label = "\(face.displayName) \(face.scoreLabel)"
            let text = Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
            let labelRect = CGRect(x: box.minX, y: max(rect.minY + 8, box.minY - 24), width: min(max(CGFloat(label.count) * 7.2 + 18, 74), 180), height: 22)
            canvas.fill(Path(roundedRect: labelRect, cornerRadius: 6), with: .color(.black.opacity(0.48)))
            canvas.draw(text, at: CGPoint(x: labelRect.minX + 9, y: labelRect.midY), anchor: .leading)
        }
    }

    private func faceBox(_ normalizedBox: CGRect, in rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX + normalizedBox.minX * rect.width,
            y: rect.minY + (1 - normalizedBox.maxY) * rect.height,
            width: normalizedBox.width * rect.width,
            height: normalizedBox.height * rect.height
        )
    }

    private func drawGaze(in rect: CGRect, on canvas: GraphicsContext) {
        guard let gazeSample else {
            return
        }

        let normalized = gazeSample.screenNormalizedPoint
        let point = CGPoint(
            x: rect.minX + normalized.x * rect.width,
            y: rect.minY + normalized.y * rect.height
        )
        let radius = CGFloat(15 + min(max(gazeSample.confidence, 0), 1) * 20)
        let outer = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        let inner = Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))

        canvas.fill(outer, with: .color(.cyan.opacity(0.18)))
        canvas.stroke(outer, with: .color(.cyan.opacity(0.78)), lineWidth: 2)
        canvas.fill(inner, with: .color(.white.opacity(0.92)))
    }
}

struct CameraPeoplePanel: View {
    @ObservedObject var cameraVision: CameraVisionModel
    @State private var enrollmentName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("People", systemImage: "person.crop.rectangle.stack")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(cameraVision.faceRecognition.knownPeople.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(cameraVision.faceRecognition.status)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(cameraVision.faceRecognition.visibleFaces.contains(where: \.isKnown) ? .green : .secondary)
                .lineLimit(2)

            if !cameraVision.faceRecognition.visibleFaces.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(cameraVision.faceRecognition.visibleFaces) { face in
                        HStack(spacing: 8) {
                            Image(systemName: face.isKnown ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.questionmark")
                                .foregroundStyle(face.isKnown ? .green : .orange)
                            Text(face.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            Spacer()
                            Text(face.scoreLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Name", text: $enrollmentName)
                    .textFieldStyle(.roundedBorder)

                Button {
                    if cameraVision.enrollVisibleFace(named: enrollmentName) {
                        enrollmentName = ""
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(!cameraVision.faceRecognition.enrollmentCandidateAvailable || enrollmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Enroll the largest visible face")
            }

            if !cameraVision.faceRecognition.knownPeople.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(cameraVision.faceRecognition.knownPeople) { person in
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(person.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(person.sampleCount) samples")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                cameraVision.forgetKnownPerson(id: person.id)
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                            .help("Forget \(person.name)")
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 260, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }
}

struct CameraPermissionSurface: View {
    @ObservedObject var cameraVision: CameraVisionModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(.indigo)

            Text(cameraVision.statusLabel)
                .font(.system(size: 21, weight: .semibold))

            Text(FUMFeatureFlags.cameraEnabled ? "Camera sight needs macOS camera permission for this local FUM interface." : "Camera is disabled in this FUM.app build.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if FUMFeatureFlags.cameraEnabled {
                HStack(spacing: 10) {
                    Button {
                        cameraVision.start()
                    } label: {
                        Label("Request", systemImage: "lock.open")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Button {
                        cameraVision.openCameraSettings()
                    } label: {
                        Image(systemName: "gear")
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.bordered)
                    .help("Open Camera privacy settings")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CameraVisionDock: View {
    @ObservedObject var cameraVision: CameraVisionModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: cameraVision.canPreview ? "camera.fill" : "camera.slash")
                .foregroundStyle(cameraVision.canPreview ? .indigo : .orange)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(cameraVision.statusLabel)
                    .font(.system(size: 14, weight: .semibold))
                Text("light \(Int(cameraVision.brightness * 100))% · gaze \(Int((cameraVision.gazeSample?.confidence ?? 0) * 100))% · people \(cameraVision.faceRecognition.visibleSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if !cameraVision.canPreview && FUMFeatureFlags.cameraEnabled {
                Button {
                    cameraVision.start()
                } label: {
                    Label("Request", systemImage: "lock.open")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if FUMFeatureFlags.cameraEnabled {
                Toggle(isOn: Binding(
                    get: { cameraVision.isGazeCursorEnabled },
                    set: { cameraVision.setGazeCursorEnabled($0) }
                )) {
                    Label("Cursor", systemImage: "cursorarrow.motionlines")
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        .frame(maxWidth: 520)
    }
}
