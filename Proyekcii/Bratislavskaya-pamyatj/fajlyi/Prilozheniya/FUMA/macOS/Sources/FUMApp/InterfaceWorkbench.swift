import SwiftUI

struct InterfaceWorkbench: View {
    @State private var selectedFocus: WorkspaceFocus
    @State private var prompt = "Draw a calm workspace for a hard problem."
    @State private var emphasis: Double = 0.58
    @State private var showGrid = true
    @State private var visionSnapshot = AXVisionUISnapshot.live()
    @State private var inputSnapshot = InputSenseUISnapshot(
        timestamp: "",
        status: "idle",
        message: "Input monitor is idle.",
        recentEventCount: 0,
        recentEvents: []
    )
    @StateObject private var cameraVision = CameraVisionModel()
    @StateObject private var videoPlayer = VideoPlayerModel()
    @StateObject private var inputMonitor = InputEventMonitor()
    @StateObject private var mcpBridge = MCPBridgeModel()

    init(initialFocus: WorkspaceFocus = .compose) {
        _selectedFocus = State(initialValue: initialFocus)
    }

    var body: some View {
        HStack(spacing: 0) {
            FocusRail(selectedFocus: $selectedFocus)
            Divider()

            focusColumn

            Divider()
            inspector
        }
        .overlay(alignment: .bottom) {
            MCPScreenOverlay(bridge: mcpBridge)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedFocus) { _, focus in
            activateServices(for: focus)
        }
        .onAppear {
            activateServices(for: selectedFocus)
            inputMonitor.ensureRunning()
            mcpBridge.reloadNow()
        }
        .onReceive(inputMonitor.$snapshot) { snapshot in
            inputSnapshot = snapshot
        }
        .task {
            await refreshSenseSnapshots()
        }
        .task {
            await refreshMCPBridge()
        }
    }

    private var focusColumn: some View {
        VStack(spacing: 0) {
            FocusBar(selectedFocus: selectedFocus, emphasis: $emphasis, showGrid: $showGrid)
            Divider()

            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    focusSurface(size: proxy.size)
                    focusDock
                }
            }
        }
    }

    private var inspector: some View {
        Inspector(
            focus: selectedFocus,
            emphasis: emphasis,
            prompt: prompt,
            visionSnapshot: visionSnapshot,
            cameraVision: cameraVision,
            inputSnapshot: inputSnapshot,
            videoPlayer: videoPlayer
        )
    }

    @ViewBuilder
    private var focusDock: some View {
        switch selectedFocus {
        case .vision:
            VisionStatusDock(snapshot: visionSnapshot)
                .padding(24)
        case .knowledge:
            EmptyView()
        case .organs:
            OrgansDock(
                visionSnapshot: visionSnapshot,
                inputSnapshot: inputSnapshot,
                cameraVision: cameraVision
            )
            .padding(24)
        case .camera:
            CameraVisionDock(cameraVision: cameraVision)
                .padding(24)
        case .video:
            EmptyView()
        case .compose, .map, .review, .ship:
            PromptDock(prompt: $prompt, focus: selectedFocus)
                .padding(24)
        }
    }

    @ViewBuilder
    private func focusSurface(size: CGSize) -> some View {
        switch selectedFocus {
        case .vision:
            VisionSurface(snapshot: visionSnapshot, showGrid: showGrid)
        case .knowledge:
            KnowledgeSurface()
        case .organs:
            OrgansSurface(
                visionSnapshot: visionSnapshot,
                inputSnapshot: inputSnapshot,
                inputMonitor: inputMonitor,
                cameraVision: cameraVision,
                videoPlayer: videoPlayer,
                mcpBridge: mcpBridge
            )
        case .camera:
            CameraVisionSurface(cameraVision: cameraVision, showGrid: showGrid)
        case .video:
            VideoPlayerWorkbench(model: videoPlayer)
        case .compose, .map, .review, .ship:
            GenerativeSurface(
                focus: selectedFocus,
                emphasis: emphasis,
                showGrid: showGrid,
                size: size
            )
        }
    }

    private func activateServices(for focus: WorkspaceFocus) {
        if FUMFeatureFlags.cameraEnabled && (focus == .camera || focus == .organs) {
            cameraVision.start()
        }

        if focus == .video {
            videoPlayer.start(preparesPlayback: true)
        } else if focus == .organs {
            videoPlayer.start(preparesPlayback: false)
        }
    }

    private func refreshSenseSnapshots() async {
        while !Task.isCancelled {
            let nextVisionSnapshot = AXVisionUISnapshot.live()
            visionSnapshot = nextVisionSnapshot
            AXVisionRuntimeWriter.write(nextVisionSnapshot)
            inputMonitor.ensureRunning()
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    private func refreshMCPBridge() async {
        while !Task.isCancelled {
            await MainActor.run {
                mcpBridge.reloadNow()
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}
