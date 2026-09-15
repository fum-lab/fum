import SwiftUI

struct GenerativeSurface: View {
    let focus: WorkspaceFocus
    let emphasis: Double
    let showGrid: Bool
    let size: CGSize

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            Canvas { canvas, canvasSize in
                let t = context.date.timeIntervalSinceReferenceDate
                let rect = CGRect(origin: .zero, size: canvasSize)

                canvas.fill(Path(rect), with: .color(Color(nsColor: .textBackgroundColor)))

                if showGrid {
                    drawGrid(in: rect, on: canvas)
                }

                drawRibbons(in: rect, on: canvas, time: t)
                drawCards(in: rect, on: canvas, time: t)
                drawCursor(in: rect, on: canvas, time: t)
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Live Canvas", systemImage: "paintbrush.pointed")
                    .font(.system(size: 13, weight: .semibold))
                Text("Shapes, panels, and affordances respond to the current focus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
    }

    private func drawGrid(in rect: CGRect, on canvas: GraphicsContext) {
        var path = Path()
        let step: CGFloat = 28

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        canvas.stroke(path, with: .color(.primary.opacity(0.055)), lineWidth: 1)
    }

    private func drawRibbons(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        for index in 0..<5 {
            var path = Path()
            let y = rect.midY + CGFloat(index - 2) * 44
            let phase = CGFloat(time.remainder(dividingBy: 8)) * 18 + CGFloat(index * 30)
            path.move(to: CGPoint(x: 60, y: y))

            for x in stride(from: CGFloat(60), through: rect.maxX - 60, by: 30) {
                let wave = sin((x + phase) / 82) * CGFloat(34 + index * 4) * emphasis
                path.addLine(to: CGPoint(x: x, y: y + wave))
            }

            canvas.stroke(
                path,
                with: .color(focus.color.opacity(0.2 + Double(index) * 0.055)),
                style: StrokeStyle(lineWidth: CGFloat(5 - index / 2), lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawCards(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        let cardSize = CGSize(width: min(190, rect.width * 0.22), height: 92)
        let anchors = [
            CGPoint(x: rect.midX - 220, y: rect.midY - 142),
            CGPoint(x: rect.midX + 80, y: rect.midY - 88),
            CGPoint(x: rect.midX - 40, y: rect.midY + 82)
        ]

        for (index, anchor) in anchors.enumerated() {
            let bob = sin(CGFloat(time) * 1.3 + CGFloat(index)) * 7
            let card = CGRect(origin: CGPoint(x: anchor.x, y: anchor.y + bob), size: cardSize)
            let path = Path(roundedRect: card, cornerRadius: 8)
            canvas.fill(path, with: .color(Color(nsColor: .controlBackgroundColor).opacity(0.9)))
            canvas.stroke(path, with: .color(focus.color.opacity(0.45)), lineWidth: 1)

            let title = Text(["Intent", "Sketch", "Action"][index])
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            canvas.draw(title, at: CGPoint(x: card.minX + 18, y: card.minY + 22), anchor: .leading)

            for line in 0..<3 {
                let width = card.width * CGFloat([0.68, 0.48, 0.58][line])
                let lineRect = CGRect(
                    x: card.minX + 18,
                    y: card.minY + 44 + CGFloat(line * 12),
                    width: width,
                    height: 4
                )
                canvas.fill(Path(roundedRect: lineRect, cornerRadius: 2), with: .color(.primary.opacity(0.14)))
            }
        }
    }

    private func drawCursor(in rect: CGRect, on canvas: GraphicsContext, time: TimeInterval) {
        let loop = CGFloat(time.remainder(dividingBy: 5)) / 5
        let point = CGPoint(
            x: rect.minX + 90 + (rect.width - 180) * loop,
            y: rect.midY + sin(loop * .pi * 2) * rect.height * 0.22
        )
        let cursor = Path(ellipseIn: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
        canvas.fill(cursor, with: .color(.white.opacity(0.9)))
        canvas.stroke(cursor, with: .color(focus.color), lineWidth: 3)
    }
}
