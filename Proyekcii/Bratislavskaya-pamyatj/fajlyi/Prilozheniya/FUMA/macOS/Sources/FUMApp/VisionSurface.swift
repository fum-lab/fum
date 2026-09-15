import SwiftUI

struct VisionSurface: View {
    let snapshot: AXVisionUISnapshot
    let showGrid: Bool

    private var windows: [AXVisionUIWindowMark] {
        snapshot.windowMarks.sorted { $0.frame.width * $0.frame.height > $1.frame.width * $1.frame.height }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            Canvas { canvas, canvasSize in
                let rect = CGRect(origin: .zero, size: canvasSize)
                canvas.fill(Path(rect), with: .color(Color(nsColor: .textBackgroundColor)))

                if showGrid {
                    drawGrid(in: rect, on: canvas)
                }

                if windows.isEmpty {
                    drawEmptyState(in: rect, on: canvas)
                } else {
                    drawDesktop(in: rect, on: canvas, time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Label("AX Vision", systemImage: snapshot.status == "ok" ? "eye" : "lock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(snapshot.status == "ok" ? .teal : .orange)
                Text(snapshot.message ?? "\(snapshot.windowCount) windows mapped from Accessibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: 360, alignment: .leading)
            }
            .padding(18)
        }
    }

    private func drawGrid(in rect: CGRect, on canvas: GraphicsContext) {
        var path = Path()
        let step: CGFloat = 32

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        canvas.stroke(path, with: .color(.primary.opacity(0.045)), lineWidth: 1)
    }

    private func drawEmptyState(in rect: CGRect, on canvas: GraphicsContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let ring = CGRect(x: center.x - 72, y: center.y - 72, width: 144, height: 144)
        canvas.stroke(Path(ellipseIn: ring), with: .color(.teal.opacity(0.32)), lineWidth: 2)
        canvas.stroke(Path(ellipseIn: ring.insetBy(dx: 22, dy: 22)), with: .color(.orange.opacity(0.28)), lineWidth: 2)

        let title = Text(snapshot.statusLabel)
            .font(.system(size: 21, weight: .semibold))
            .foregroundStyle(.primary)
        canvas.draw(title, at: CGPoint(x: center.x, y: center.y + 96), anchor: .center)

        if let message = snapshot.message {
            let detail = Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            canvas.draw(detail, at: CGPoint(x: center.x, y: center.y + 122), anchor: .center)
        }
    }

    private func drawDesktop(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        let bounds = desktopBounds()
        let content = rect.insetBy(dx: 54, dy: 72)
        let desktopPath = Path(roundedRect: content, cornerRadius: 8)
        canvas.fill(desktopPath, with: .color(Color(nsColor: .controlBackgroundColor).opacity(0.72)))
        canvas.stroke(desktopPath, with: .color(.primary.opacity(0.12)), lineWidth: 1)

        for (index, window) in windows.enumerated() {
            let mapped = map(window.frame, from: bounds, into: content)
            let pulse = window.isActive ? 0.18 + 0.08 * sin(time * 3.0) : 0
            let color = paletteColor(for: window.appName)
            let windowPath = Path(roundedRect: mapped, cornerRadius: min(8, max(3, mapped.height * 0.12)))

            canvas.fill(windowPath, with: .color(color.opacity(0.20 + pulse)))
            canvas.stroke(windowPath, with: .color(color.opacity(window.isActive ? 0.92 : 0.56)), lineWidth: window.isActive ? 2 : 1)

            if mapped.width > 70, mapped.height > 26 {
                let label = Text(window.appName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                canvas.draw(label, at: CGPoint(x: mapped.minX + 8, y: mapped.minY + 10), anchor: .leading)
            }

            if mapped.width > 145, mapped.height > 48, !window.title.isEmpty {
                let title = Text(window.title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                canvas.draw(title, at: CGPoint(x: mapped.minX + 8, y: mapped.minY + 26), anchor: .leading)
            }

            if index < 8 {
                let dot = Path(ellipseIn: CGRect(x: mapped.maxX - 10, y: mapped.minY + 6, width: 5, height: 5))
                canvas.fill(dot, with: .color(color.opacity(0.85)))
            }
        }
    }

    private func desktopBounds() -> CGRect {
        let frames = windows.map(\.frame)
        guard let first = frames.first else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let union = frames.dropFirst().reduce(first) { $0.union($1) }
        return union.insetBy(dx: -max(80, union.width * 0.06), dy: -max(80, union.height * 0.06))
    }

    private func map(_ frame: CGRect, from bounds: CGRect, into content: CGRect) -> CGRect {
        let width = max(bounds.width, 1)
        let height = max(bounds.height, 1)
        let x = content.minX + ((frame.minX - bounds.minX) / width) * content.width
        let y = content.minY + ((frame.minY - bounds.minY) / height) * content.height
        let mappedWidth = max(5, (frame.width / width) * content.width)
        let mappedHeight = max(5, (frame.height / height) * content.height)
        return CGRect(x: x, y: y, width: mappedWidth, height: mappedHeight)
    }

    private func paletteColor(for name: String) -> Color {
        let palette: [Color] = [.teal, .orange, .mint, .pink, .blue, .yellow, .green, .red]
        let index = abs(name.hashValue) % palette.count
        return palette[index]
    }
}
