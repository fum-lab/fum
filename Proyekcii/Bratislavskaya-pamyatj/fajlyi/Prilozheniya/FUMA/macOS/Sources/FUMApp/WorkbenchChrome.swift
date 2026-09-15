import SwiftUI

struct FocusRail: View {
    @Binding var selectedFocus: WorkspaceFocus

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("FUM")
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                ForEach(WorkspaceFocus.allCases) { focus in
                    Button {
                        selectedFocus = focus
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: focus.symbol)
                                .frame(width: 20)
                            Text(focus.title)
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedFocus == focus ? focus.color.opacity(0.16) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedFocus == focus ? .primary : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Session Pulse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    ForEach(0..<12, id: \.self) { index in
                        Capsule()
                            .fill(index.isMultiple(of: 3) ? Color.cyan : Color.primary.opacity(0.18))
                            .frame(width: 6, height: CGFloat(14 + (index % 5) * 5))
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
        .frame(width: 188)
    }
}

struct FocusBar: View {
    let selectedFocus: WorkspaceFocus
    @Binding var emphasis: Double
    @Binding var showGrid: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedFocus.title)
                    .font(.system(size: 18, weight: .semibold))
                Text(selectedFocus.intent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selectedFocus.showsGridControl {
                Toggle("Grid", isOn: $showGrid)
                    .toggleStyle(.switch)
                    .frame(width: 88)
            }

            if selectedFocus.showsSketchControls {
                HStack(spacing: 10) {
                    Image(systemName: "dial.low")
                    Slider(value: $emphasis, in: 0.1...1.0)
                        .frame(width: 148)
                    Image(systemName: "dial.high")
                }
                .foregroundStyle(.secondary)

                Button {
                    emphasis = 0.72
                    showGrid = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Reset drawing controls")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }
}

struct PromptDock: View {
    @Binding var prompt: String
    let focus: WorkspaceFocus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: focus.symbol)
                .foregroundStyle(focus.color)
                .frame(width: 28, height: 28)

            TextField("Ask FUM to make the next action clearer", text: $prompt)
                .textFieldStyle(.plain)
                .font(.system(size: 15))

            Button {
                prompt = "Make \(focus.title.lowercased()) reduce the next required action."
            } label: {
                Image(systemName: "wand.and.stars")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
            .help("Generate a clearer next action")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        .frame(maxWidth: 680)
    }
}

struct VisionStatusDock: View {
    let snapshot: AXVisionUISnapshot

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: snapshot.status == "ok" ? "eye.fill" : "eye.slash")
                .foregroundStyle(snapshot.status == "ok" ? .teal : .orange)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.statusLabel)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(snapshot.applications.count) apps · \(snapshot.windowCount) windows · \(snapshot.shortTimestamp)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if snapshot.needsAccessibilityRequest {
                Button {
                    AXVisionAccessRequester.request()
                } label: {
                    Label("Request", systemImage: "lock.open")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Request Accessibility access")
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

struct Metric: View {
    let label: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
