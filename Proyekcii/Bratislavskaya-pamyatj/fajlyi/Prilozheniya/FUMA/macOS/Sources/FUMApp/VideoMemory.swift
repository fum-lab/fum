#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import AppKit
import AVFoundation
import AVKit
import CMpvShim
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum MediaTrackKind: String, Sendable {
    case video
    case audio
    case subtitle
}

struct MediaTrack: Identifiable, Equatable, Sendable {
    let id: String
    let url: URL
    let title: String
    let kind: MediaTrackKind
    let role: String
    let language: String?
    let fileSize: Int64
    let modifiedAt: Date?

    var displayTitle: String {
        if let language {
            return "\(role) · \(language)"
        }
        return role
    }

    var subtitle: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct SubtitleCue: Sendable {
    let start: Double
    let end: Double
    let text: String
}

struct VideoItem: Identifiable, Equatable, Sendable {
    let id: String
    let url: URL
    let title: String
    let directory: String
    let fileSize: Int64
    let modifiedAt: Date?
    let videoTracks: [MediaTrack]
    let audioTracks: [MediaTrack]
    let subtitleTracks: [MediaTrack]

    var subtitle: String {
        let size = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        let trackSummary = "\(videoTracks.count)v \(audioTracks.count)a \(subtitleTracks.count)s"
        guard let modifiedAt else {
            return "\(trackSummary) · \(size)"
        }
        return "\(trackSummary) · \(size) · \(modifiedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct ExternalPlaybackRequest {
    let video: VideoItem
    let videoTrack: MediaTrack
    let audioTrack: MediaTrack?
    let subtitleTrack: MediaTrack?
    let autoplay: Bool
    let startTime: Double
}

@MainActor
final class VideoPlayerModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var selectedVideo: VideoItem?
    @Published var isPlaying = false
    @Published var volume: Double = 0.9
    @Published var rate: Float = 1.0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isScrubbing = false
    @Published var statusText = "Loading library"
    @Published var isScanningLibrary = false
    @Published var isPreparingVideo = false
    @Published var isBuffering = false
    @Published var selectedVideoTrack: MediaTrack?
    @Published var selectedAudioTrack: MediaTrack?
    @Published var selectedSubtitleTrack: MediaTrack?
    @Published var subtitleText = ""
    @Published var isUsingExternalPlayer = false
    @Published var isUsingSubtitleOnlyTimeline = false
    @Published var externalPlayerStatusText = ""
    @Published var activeVectorCut: FUMVectorVideoDocument?
    @Published var activeVectorCutURL: URL?
    @Published var vectorCutStatusText = "No vector cut"

    let player = AVPlayer()

    private let libraryURL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Movies", isDirectory: true)
        .appendingPathComponent("FUM YouTube", isDirectory: true)
    private let logger = JSONLInteractionLogger(path: ПутиПриложения.текущие.память.appendingPathComponent("video-player/events.jsonl").path)
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var itemDurationObservation: NSKeyValueObservation?
    private var libraryReloadTask: Task<Void, Never>?
    private weak var activeEmbeddedPlayer: EmbeddedMPVPlaybackController?
    private var pendingExternalPlayback: ExternalPlaybackRequest?
    private var pendingExternalSeekTarget: Double?
    private var pendingExternalSeekStartedAt: Date?
    private var hasStarted = false
    private var shouldPreparePlaybackWhenReady = false
    private var subtitleCues: [SubtitleCue] = []
    private var subtitleOnlyTimer: Timer?
    private var subtitleOnlyStartedAt: Date?
    private var subtitleOnlyBaseTime: Double = 0

    var selectedTrackUsesExternalPlayer: Bool {
        guard let selectedVideoTrack else { return false }
        return requiresExternalPlayer(videoTrack: selectedVideoTrack)
    }

    var isSubtitleOnlyPlayback: Bool {
        selectedVideo != nil && selectedVideoTrack == nil && selectedAudioTrack == nil
    }

    var isAudioOnlyPlayback: Bool {
        selectedVideo != nil && selectedVideoTrack == nil && selectedAudioTrack != nil
    }

    var subtitleTimelineDisplayText: String {
        if !subtitleText.isEmpty {
            return subtitleText
        }
        if let nextCue = nextSubtitleCue(after: currentTime) {
            return nextCue.text
        }
        return selectedSubtitleTrack == nil ? "Subtitles off" : "..."
    }

    var subtitleTimelineSecondaryText: String {
        guard let selectedSubtitleTrack else { return "" }
        return "\(selectedSubtitleTrack.displayTitle) · \(selectedSubtitleTrack.url.lastPathComponent)"
    }

    var mediaOnlyStageTitle: String {
        if isAudioOnlyPlayback {
            return selectedAudioTrack?.displayTitle ?? "Audio"
        }
        return selectedSubtitleTrack?.displayTitle ?? "Subtitles"
    }

    var mediaOnlyStageDetail: String {
        if let selectedAudioTrack {
            return selectedAudioTrack.url.lastPathComponent
        }
        return selectedSubtitleTrack?.url.lastPathComponent ?? ""
    }

    func start(preparesPlayback: Bool = true) {
        if preparesPlayback {
            shouldPreparePlaybackWhenReady = true
        }

        guard !hasStarted else {
            if preparesPlayback {
                preparePlaybackWhenPossible()
            }
            return
        }

        hasStarted = true
        player.volume = Float(volume)
        observePlayer()
        logger.append(type: "app_started", payload: [
            "libraryPath": libraryURL.path
        ])
        reloadLibrary()
    }

    func reloadLibrary() {
        libraryReloadTask?.cancel()
        isScanningLibrary = true
        statusText = "Scanning \(libraryURL.path)"

        let libraryURL = libraryURL
        libraryReloadTask = Task {
            let scannedVideos = await Task.detached(priority: .userInitiated) {
                Self.scanLibrary(at: libraryURL)
            }.value

            guard !Task.isCancelled else { return }

            videos = scannedVideos
            statusText = videos.isEmpty ? "No media in \(libraryURL.path)" : "\(videos.count) media item\(videos.count == 1 ? "" : "s") ready"
            isScanningLibrary = false
            logger.append(type: "library_scanned", payload: [
                "libraryPath": libraryURL.path,
                "videoCount": videos.count
            ])

            preparePlaybackWhenPossible()
        }
    }

    func activatePlaybackSurface() {
        start(preparesPlayback: true)
        preparePlaybackWhenPossible()
    }

    private func preparePlaybackWhenPossible() {
        guard shouldPreparePlaybackWhenReady else { return }
        guard selectedVideo == nil, let first = videos.first else { return }
        select(first, autoplay: false)
    }

    func select(_ video: VideoItem, autoplay: Bool) {
        selectedVideo = video
        selectedVideoTrack = video.videoTracks.first
        selectedAudioTrack = video.audioTracks.first
        selectedSubtitleTrack = video.subtitleTracks.first
        subtitleCues = selectedSubtitleTrack.map(Self.loadSubtitleCues) ?? []
        subtitleText = ""
        prepareSelectedMedia(autoplay: autoplay, startTime: 0)
    }

    func selectVideoTrack(id: String) {
        guard let selectedVideo, let track = selectedVideo.videoTracks.first(where: { $0.id == id }) else { return }
        selectedVideoTrack = track
        prepareSelectedMedia(autoplay: isPlaying, startTime: currentTime)
        logger.append(type: "video_track_selected", video: selectedVideo, payload: trackPayload(track))
    }

    func selectAudioTrack(id: String) {
        guard let selectedVideo, let track = selectedVideo.audioTracks.first(where: { $0.id == id }) else { return }
        selectedAudioTrack = track
        prepareSelectedMedia(autoplay: isPlaying, startTime: currentTime)
        logger.append(type: "audio_track_selected", video: selectedVideo, payload: trackPayload(track))
    }

    func selectSubtitleTrack(id: String) {
        guard let selectedVideo else { return }
        selectedSubtitleTrack = selectedVideo.subtitleTracks.first(where: { $0.id == id })
        subtitleCues = selectedSubtitleTrack.map(Self.loadSubtitleCues) ?? []
        if isUsingSubtitleOnlyTimeline {
            duration = subtitleTimelineDuration()
            currentTime = max(0, min(currentTime, duration > 0 ? duration : currentTime))
            subtitleText = subtitleText(at: currentTime)
            if isPlaying {
                startSubtitleOnlyClock()
            }
        } else {
            subtitleText = subtitleText(at: currentTime)
        }
        logger.append(type: "subtitle_track_selected", video: selectedVideo, payload: selectedSubtitleTrack.map(trackPayload) ?? [
            "track": "off"
        ])
    }

    func disableSubtitles() {
        guard selectedSubtitleTrack != nil else { return }
        selectedSubtitleTrack = nil
        subtitleCues = []
        subtitleText = ""
        if isUsingSubtitleOnlyTimeline {
            stopSubtitleOnlyClock()
            isPlaying = false
            duration = 0
            currentTime = 0
            statusText = "No subtitle track selected"
        }
        logger.append(type: "subtitle_track_disabled", video: selectedVideo)
    }

    private func prepareSelectedMedia(autoplay: Bool, startTime: Double) {
        guard let video = selectedVideo else { return }
        resetActiveExternalPlayer()
        stopSubtitleOnlyClock()
        currentTime = 0
        duration = 0
        isPreparingVideo = true
        isBuffering = false
        itemDurationObservation = nil

        guard let videoTrack = selectedVideoTrack else {
            if let audioTrack = selectedAudioTrack {
                prepareAudioOnlyPlayback(video: video, audioTrack: audioTrack, autoplay: autoplay, startTime: startTime)
                return
            }
            prepareSubtitleOnlyPlayback(video: video, autoplay: autoplay, startTime: startTime)
            return
        }

        isUsingSubtitleOnlyTimeline = false

        if requiresExternalPlayer(videoTrack: videoTrack) {
            let request = ExternalPlaybackRequest(
                video: video,
                videoTrack: videoTrack,
                audioTrack: selectedAudioTrack,
                subtitleTrack: selectedSubtitleTrack,
                autoplay: autoplay,
                startTime: startTime
            )
            guard let activeEmbeddedPlayer else {
                pendingExternalPlayback = request
                player.pause()
                player.replaceCurrentItem(with: nil)
                isUsingExternalPlayer = true
                isPreparingVideo = false
                externalPlayerStatusText = "Preparing embedded VP9 renderer"
                statusText = externalPlayerStatusText
                logger.append(type: "external_player_waiting_for_surface", video: video, payload: externalPlayerPayload(videoTrack: videoTrack, audioTrack: selectedAudioTrack, subtitleTrack: selectedSubtitleTrack, extra: [
                    "autoplay": autoplay,
                    "startTime": startTime
                ]))
                return
            }
            loadEmbeddedPlayer(activeEmbeddedPlayer, request: request)
            return
        }

        let item = makePlayerItem(videoTrack: videoTrack, audioTrack: selectedAudioTrack)
        applyPlayerItem(item, video: video, videoTrack: videoTrack, audioTrack: selectedAudioTrack, autoplay: autoplay, startTime: startTime, source: "direct")
    }

    private func applyPlayerItem(_ item: AVPlayerItem, video: VideoItem, videoTrack: MediaTrack, audioTrack: MediaTrack?, autoplay: Bool, startTime: Double, source: String) {
        isUsingSubtitleOnlyTimeline = false
        itemDurationObservation = item.observe(\.duration, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                self.duration = item.duration.secondsValue
                self.isPreparingVideo = self.duration <= 0
            }
        }
        player.replaceCurrentItem(with: item)
        if startTime > 0 {
            seek(to: startTime, reason: "track_switch_seek")
        }
        logger.append(type: "video_selected", video: video, payload: [
            "autoplay": autoplay,
            "videoTrack": videoTrack.url.lastPathComponent,
            "audioTrack": audioTrack?.url.lastPathComponent ?? "embedded",
            "playbackSource": source
        ])

        if autoplay {
            play()
        } else {
            player.pause()
        }
    }

    private func applyAudioOnlyItem(_ item: AVPlayerItem, video: VideoItem, audioTrack: MediaTrack, autoplay: Bool, startTime: Double) {
        isUsingSubtitleOnlyTimeline = false
        itemDurationObservation = item.observe(\.duration, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                self.duration = item.duration.secondsValue
                self.isPreparingVideo = self.duration <= 0
            }
        }
        player.replaceCurrentItem(with: item)
        if startTime > 0 {
            seek(to: startTime, reason: "track_switch_seek")
        }
        statusText = "Audio-only ready"
        logger.append(type: "audio_only_selected", video: video, payload: [
            "autoplay": autoplay,
            "audioTrack": audioTrack.url.path,
            "subtitleTrack": selectedSubtitleTrack?.url.path ?? "off",
            "subtitleCueCount": subtitleCues.count,
            "playbackSource": "audio-only"
        ])

        if autoplay {
            play()
        } else {
            player.pause()
        }
    }

    func registerEmbeddedPlayer(_ player: EmbeddedMPVPlaybackController) {
        activeEmbeddedPlayer = player
        let hadPendingPlayback = pendingExternalPlayback != nil
        logger.append(type: "embedded_player_ready", video: selectedVideo, payload: [
            "hadPendingPlayback": hadPendingPlayback
        ])

        if let pendingExternalPlayback {
            self.pendingExternalPlayback = nil
            loadEmbeddedPlayer(player, request: pendingExternalPlayback)
        } else if let selectedVideo, let selectedVideoTrack, requiresExternalPlayer(videoTrack: selectedVideoTrack) {
            loadEmbeddedPlayer(player, request: ExternalPlaybackRequest(
                video: selectedVideo,
                videoTrack: selectedVideoTrack,
                audioTrack: selectedAudioTrack,
                subtitleTrack: selectedSubtitleTrack,
                autoplay: isPlaying,
                startTime: currentTime
            ))
        }
    }

    func unregisterEmbeddedPlayer(_ player: EmbeddedMPVPlaybackController) {
        if activeEmbeddedPlayer === player {
            activeEmbeddedPlayer = nil
        }
    }

    func embeddedPlayerDidFail(_ error: Error) {
        isPreparingVideo = false
        isBuffering = false
        isUsingExternalPlayer = false
        isUsingSubtitleOnlyTimeline = false
        externalPlayerStatusText = error.localizedDescription
        statusText = "Embedded VP9 failed"

        if let selectedVideo, let selectedVideoTrack {
            logger.append(type: "external_player_failed", video: selectedVideo, payload: externalPlayerPayload(videoTrack: selectedVideoTrack, audioTrack: selectedAudioTrack, subtitleTrack: selectedSubtitleTrack, extra: [
                "error": error.localizedDescription,
                "mode": "libmpv",
                "stage": "renderer_setup"
            ]))
        } else {
            logger.append(type: "external_player_failed", payload: [
                "error": error.localizedDescription,
                "mode": "libmpv",
                "stage": "renderer_setup"
            ])
        }
    }

    private func loadEmbeddedPlayer(_ player: EmbeddedMPVPlaybackController, request: ExternalPlaybackRequest) {
        self.player.pause()
        self.player.replaceCurrentItem(with: nil)

        do {
            try player.load(request, volume: volume, rate: rate)
            isUsingExternalPlayer = true
            isUsingSubtitleOnlyTimeline = false
            isPreparingVideo = false
            isBuffering = false
            isPlaying = request.autoplay
            externalPlayerStatusText = "Playing VP9 inside FUM with libmpv"
            statusText = externalPlayerStatusText
            logger.append(type: "external_player_started", video: request.video, payload: externalPlayerPayload(videoTrack: request.videoTrack, audioTrack: request.audioTrack, subtitleTrack: request.subtitleTrack, extra: [
                "autoplay": request.autoplay,
                "startTime": request.startTime,
                "mode": "libmpv"
            ]))
        } catch {
            isPreparingVideo = false
            isUsingExternalPlayer = false
            isUsingSubtitleOnlyTimeline = false
            isPlaying = false
            externalPlayerStatusText = error.localizedDescription
            statusText = "Embedded VP9 failed"
            logger.append(type: "external_player_failed", video: request.video, payload: externalPlayerPayload(videoTrack: request.videoTrack, audioTrack: request.audioTrack, subtitleTrack: request.subtitleTrack, extra: [
                "error": error.localizedDescription,
                "mode": "libmpv"
            ]))
        }
    }

    func openVideos() {
        let panel = NSOpenPanel()
        panel.title = "Open media"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .video]
            + [.audio]
            + ["webm", "mkv", "m4a", "mp3", "aac", "opus", "srt", "vtt"].compactMap { UTType(filenameExtension: $0) }
        panel.directoryURL = libraryURL

        guard panel.runModal() == .OK else {
            logger.append(type: "open_panel_cancelled")
            return
        }

        let opened = panel.urls.map(Self.makeVideoItem)
        videos = (opened + videos).uniquedByURL()
        logger.append(type: "external_media_opened", payload: [
            "count": opened.count,
            "paths": opened.map(\.url.path)
        ])
        if let first = opened.first {
            select(first, autoplay: true)
        }
    }

    func revealSelected() {
        guard let selectedVideo else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedVideo.url.deletingLastPathComponent()])
        logger.append(type: "video_revealed", video: selectedVideo)
    }

    func saveVectorCut() {
        guard let selectedVideo, let selectedVideoTrack else {
            vectorCutStatusText = "Select a video first"
            return
        }

        let document = FUMVectorVideoDocument.makeSingleSourceCut(
            video: selectedVideo,
            videoTrack: selectedVideoTrack,
            audioTrack: selectedAudioTrack,
            subtitleTrack: selectedSubtitleTrack,
            currentTime: currentTime,
            duration: duration
        )

        try? FileManager.default.createDirectory(at: FUMVectorVideoDocumentStore.defaultDirectory, withIntermediateDirectories: true)

        let panel = NSSavePanel()
        panel.title = "Save vector cut"
        panel.canCreateDirectories = true
        panel.directoryURL = FUMVectorVideoDocumentStore.defaultDirectory
        panel.nameFieldStringValue = FUMVectorVideoDocumentStore.suggestedFileName(for: document.title)
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else {
            logger.append(type: "vector_cut_save_cancelled", video: selectedVideo)
            return
        }

        do {
            let outputURL = try FUMVectorVideoDocumentStore.write(document, to: url)
            activeVectorCut = document
            activeVectorCutURL = outputURL
            vectorCutStatusText = document.shortSummary
            logger.append(type: "vector_cut_saved", video: selectedVideo, payload: [
                "path": outputURL.path,
                "schema": document.schema,
                "version": document.version,
                "sourceCount": document.sources.count,
                "trackCount": document.timeline.tracks.count
            ])
        } catch {
            vectorCutStatusText = "Save failed"
            logger.append(type: "vector_cut_save_failed", video: selectedVideo, payload: [
                "error": String(describing: error)
            ])
        }
    }

    func openVectorCut() {
        let panel = NSOpenPanel()
        panel.title = "Open vector cut"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = FUMVectorVideoDocumentStore.defaultDirectory
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else {
            logger.append(type: "vector_cut_open_cancelled")
            return
        }

        do {
            let document = try FUMVectorVideoDocumentStore.read(from: url)
            activeVectorCut = document
            activeVectorCutURL = url
            vectorCutStatusText = document.shortSummary
            logger.append(type: "vector_cut_opened", payload: [
                "path": url.path,
                "schema": document.schema,
                "version": document.version,
                "sourceCount": document.sources.count,
                "trackCount": document.timeline.tracks.count
            ])
        } catch {
            vectorCutStatusText = "Open failed"
            logger.append(type: "vector_cut_open_failed", payload: [
                "path": url.path,
                "error": String(describing: error)
            ])
        }
    }

    func revealVectorCut() {
        guard let activeVectorCutURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([activeVectorCutURL])
        logger.append(type: "vector_cut_revealed", payload: [
            "path": activeVectorCutURL.path
        ])
    }

    func playPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        if isUsingSubtitleOnlyTimeline {
            startSubtitleOnlyClock()
            logger.append(type: "play_requested", video: selectedVideo, payload: playbackPayload(extra: [
                "playbackBackend": "subtitle-timeline"
            ]))
            return
        }

        if isUsingExternalPlayer {
            activeEmbeddedPlayer?.setPaused(false)
            isPlaying = true
            logger.append(type: "play_requested", video: selectedVideo, payload: playbackPayload(extra: [
                "playbackBackend": "mpv"
            ]))
            return
        }

        if player.currentItem == nil, selectedVideo != nil {
            prepareSelectedMedia(autoplay: true, startTime: currentTime)
            return
        }

        player.playImmediately(atRate: rate)
        logger.append(type: "play_requested", video: selectedVideo, payload: playbackPayload())
    }

    func pause() {
        if isUsingSubtitleOnlyTimeline {
            tickSubtitleOnlyClock()
            stopSubtitleOnlyClock()
            isPlaying = false
            logger.append(type: "pause_requested", video: selectedVideo, payload: playbackPayload(extra: [
                "playbackBackend": "subtitle-timeline"
            ]))
            return
        }

        if isUsingExternalPlayer {
            activeEmbeddedPlayer?.setPaused(true)
            isPlaying = false
            logger.append(type: "pause_requested", video: selectedVideo, payload: playbackPayload(extra: [
                "playbackBackend": "mpv"
            ]))
            return
        }

        player.pause()
        logger.append(type: "pause_requested", video: selectedVideo, payload: playbackPayload())
    }

    func skip(by seconds: Double) {
        seek(to: currentTime + seconds, reason: seconds < 0 ? "skip_backward" : "skip_forward")
    }

    func seek(to seconds: Double, reason: String = "seek") {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        if isUsingSubtitleOnlyTimeline {
            currentTime = clamped
            subtitleText = subtitleText(at: clamped)
            if isPlaying {
                startSubtitleOnlyClock()
            }
            logger.append(type: reason, video: selectedVideo, payload: playbackPayload(extra: [
                "targetTime": clamped,
                "playbackBackend": "subtitle-timeline"
            ]))
            return
        }

        if isUsingExternalPlayer {
            currentTime = clamped
            subtitleText = subtitleText(at: clamped)
            pendingExternalSeekTarget = clamped
            pendingExternalSeekStartedAt = Date()
            activeEmbeddedPlayer?.seekAbsolute(clamped)
            logger.append(type: reason, video: selectedVideo, payload: playbackPayload(extra: [
                "targetTime": clamped,
                "playbackBackend": "mpv"
            ]))
            return
        }

        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        logger.append(type: reason, video: selectedVideo, payload: playbackPayload(extra: [
            "targetTime": clamped
        ]))
    }

    func beginScrubbing() {
        isScrubbing = true
    }

    func scrub(to seconds: Double) {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        isScrubbing = true
        currentTime = clamped
        subtitleText = subtitleText(at: clamped)
    }

    func finishScrubbing() {
        guard isScrubbing else { return }
        let targetTime = currentTime
        isScrubbing = false
        seek(to: targetTime, reason: "scrub_seek")
    }

    func setVolume(_ value: Double) {
        volume = min(max(value, 0), 1)
        player.volume = Float(volume)
        if isUsingExternalPlayer {
            activeEmbeddedPlayer?.setVolume(volume)
        }
        logger.append(type: "volume_changed", video: selectedVideo, payload: playbackPayload(extra: [
            "volume": volume
        ]))
    }

    func setRate(_ value: Float) {
        rate = value
        if isUsingSubtitleOnlyTimeline {
            if isPlaying {
                tickSubtitleOnlyClock()
                startSubtitleOnlyClock()
            }
        } else if isUsingExternalPlayer {
            activeEmbeddedPlayer?.setRate(rate)
        } else if isPlaying {
            player.rate = rate
        }
        logger.append(type: "rate_changed", video: selectedVideo, payload: playbackPayload(extra: [
            "rate": rate
        ]))
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                guard !self.isUsingExternalPlayer, !self.isUsingSubtitleOnlyTimeline else { return }
                self.duration = self.player.currentItem?.duration.secondsValue ?? self.duration
                guard !self.isScrubbing else { return }
                self.currentTime = time.secondsValue
                self.subtitleText = self.subtitleText(at: self.currentTime)
            }
        }

        statusObservation = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self else { return }
                guard !self.isUsingExternalPlayer, !self.isUsingSubtitleOnlyTimeline else { return }
                let playing = player.timeControlStatus == .playing
                self.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                if player.timeControlStatus != .waitingToPlayAtSpecifiedRate, self.duration > 0 {
                    self.isPreparingVideo = false
                }
                if self.isPlaying != playing {
                    self.isPlaying = playing
                    self.logger.append(type: playing ? "playback_started" : "playback_paused", video: self.selectedVideo, payload: self.playbackPayload())
                }
            }
        }
    }

    private func resetActiveExternalPlayer() {
        pendingExternalPlayback = nil
        pendingExternalSeekTarget = nil
        pendingExternalSeekStartedAt = nil
        isScrubbing = false
        activeEmbeddedPlayer?.stop()
        isUsingExternalPlayer = false
        externalPlayerStatusText = ""
    }

    private func prepareAudioOnlyPlayback(video: VideoItem, audioTrack: MediaTrack, autoplay: Bool, startTime: Double) {
        player.pause()
        isUsingExternalPlayer = false
        isUsingSubtitleOnlyTimeline = false
        isPreparingVideo = true
        isBuffering = false
        let item = AVPlayerItem(url: audioTrack.url)
        applyAudioOnlyItem(item, video: video, audioTrack: audioTrack, autoplay: autoplay, startTime: startTime)
    }

    private func prepareSubtitleOnlyPlayback(video: VideoItem, autoplay: Bool, startTime: Double) {
        player.pause()
        player.replaceCurrentItem(with: nil)
        itemDurationObservation = nil
        isUsingExternalPlayer = false
        isUsingSubtitleOnlyTimeline = true
        isPreparingVideo = false
        isBuffering = false
        duration = subtitleTimelineDuration()
        currentTime = max(0, min(startTime, duration > 0 ? duration : startTime))
        subtitleText = subtitleText(at: currentTime)
        statusText = selectedSubtitleTrack == nil ? "No subtitle track selected" : "Subtitle-only timeline ready"
        logger.append(type: "subtitle_only_selected", video: video, payload: [
            "autoplay": autoplay,
            "startTime": startTime,
            "duration": duration,
            "subtitleTrack": selectedSubtitleTrack?.url.path ?? "off",
            "subtitleCueCount": subtitleCues.count
        ])

        if autoplay {
            startSubtitleOnlyClock()
        } else {
            isPlaying = false
        }
    }

    private func startSubtitleOnlyClock() {
        guard duration > 0 else {
            stopSubtitleOnlyClock()
            isPlaying = false
            statusText = selectedSubtitleTrack == nil ? "No subtitle track selected" : "Subtitle timeline is empty"
            return
        }

        if currentTime >= duration {
            currentTime = 0
        }
        subtitleText = subtitleText(at: currentTime)
        stopSubtitleOnlyClock()
        subtitleOnlyBaseTime = currentTime
        subtitleOnlyStartedAt = Date()
        isPlaying = true
        statusText = "Playing subtitles only"
        subtitleOnlyTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickSubtitleOnlyClock()
            }
        }
    }

    private func stopSubtitleOnlyClock() {
        subtitleOnlyTimer?.invalidate()
        subtitleOnlyTimer = nil
        subtitleOnlyStartedAt = nil
        subtitleOnlyBaseTime = currentTime
    }

    private func tickSubtitleOnlyClock() {
        guard isUsingSubtitleOnlyTimeline, isPlaying, let subtitleOnlyStartedAt else { return }
        guard !isScrubbing else { return }

        let elapsed = Date().timeIntervalSince(subtitleOnlyStartedAt)
        let nextTime = subtitleOnlyBaseTime + elapsed * Double(rate)
        currentTime = max(0, min(nextTime, duration))
        subtitleText = subtitleText(at: currentTime)

        if duration > 0, currentTime >= duration {
            stopSubtitleOnlyClock()
            isPlaying = false
            statusText = "Subtitle timeline ended"
            logger.append(type: "playback_ended", video: selectedVideo, payload: playbackPayload(extra: [
                "playbackBackend": "subtitle-timeline"
            ]))
        }
    }

    func updateEmbeddedPlayerProgress(currentTime: Double, duration: Double, isPaused: Bool) {
        guard isUsingExternalPlayer else { return }
        self.duration = duration
        self.isPlaying = !isPaused
        if let pendingExternalSeekTarget {
            let elapsed = Date().timeIntervalSince(pendingExternalSeekStartedAt ?? .distantPast)
            if abs(currentTime - pendingExternalSeekTarget) > 0.75, elapsed < 5.0 {
                self.currentTime = pendingExternalSeekTarget
                self.subtitleText = subtitleText(at: pendingExternalSeekTarget)
                return
            }
            self.pendingExternalSeekTarget = nil
            pendingExternalSeekStartedAt = nil
        }
        guard !isScrubbing else { return }
        self.currentTime = currentTime
        self.subtitleText = subtitleText(at: currentTime)
        if duration > 0 {
            isPreparingVideo = false
            isBuffering = false
        }
    }

    func embeddedPlayerDidPrepareExternalTracks(audioPath: String?, subtitlePath: String?, activeAudioID: String?, audioCodec: String?) {
        guard let selectedVideo, let selectedVideoTrack else { return }
        logger.append(type: "external_player_tracks_ready", video: selectedVideo, payload: externalPlayerPayload(videoTrack: selectedVideoTrack, audioTrack: selectedAudioTrack, subtitleTrack: selectedSubtitleTrack, extra: [
            "activeAudioID": activeAudioID ?? "unknown",
            "activeAudioCodec": audioCodec ?? "unknown",
            "attachedAudioTrack": audioPath ?? "embedded",
            "selectedSubtitleTrack": subtitlePath ?? "off",
            "subtitlesRenderedBy": "fum_overlay",
            "mpvSubtitles": "disabled",
            "mode": "libmpv"
        ]))
    }

    nonisolated private static func scanLibrary(at libraryURL: URL) -> [VideoItem] {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            return []
        }

        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        let mediaExtensions = Set(["mp4", "mov", "m4v", "webm", "mkv", "m4a", "mp3", "aac", "opus", "srt", "vtt"])
        guard let enumerator = FileManager.default.enumerator(
            at: libraryURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let tracks = enumerator
            .compactMap { $0 as? URL }
            .filter { mediaExtensions.contains($0.pathExtension.lowercased()) }
            .compactMap(Self.makeTrack)

        let grouped = Dictionary(grouping: tracks) { track in
            track.url.deletingLastPathComponent().standardizedFileURL.path
        }

        return grouped.compactMap { _, tracks in
            Self.makeVideoItem(from: tracks)
        }
            .sorted { left, right in
                (left.modifiedAt ?? .distantPast) > (right.modifiedAt ?? .distantPast)
            }
    }

    nonisolated private static func makeTrack(url: URL) -> MediaTrack? {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let kind = inferKind(from: url)
        guard kind != nil else { return nil }
        let role = inferRole(from: url, kind: kind!)
        let language = inferLanguage(from: url, kind: kind!)
        return MediaTrack(
            id: url.standardizedFileURL.path,
            url: url,
            title: url.deletingPathExtension().lastPathComponent,
            kind: kind!,
            role: role,
            language: language,
            fileSize: Int64(values?.fileSize ?? 0),
            modifiedAt: values?.contentModificationDate
        )
    }

    nonisolated private static func makeVideoItem(from tracks: [MediaTrack]) -> VideoItem? {
        let videoTracks = tracks
            .filter { $0.kind == .video }
            .sorted { left, right in
                let leftRank = playbackPreferenceRank(for: left)
                let rightRank = playbackPreferenceRank(for: right)
                if leftRank != rightRank { return leftRank > rightRank }
                if left.fileSize == right.fileSize { return left.title < right.title }
                return left.fileSize > right.fileSize
            }
        let audioTracks = tracks
            .filter { $0.kind == .audio }
            .sorted { $0.fileSize > $1.fileSize }
        let subtitleTracks = tracks
            .filter { $0.kind == .subtitle }
            .sorted { $0.displayTitle < $1.displayTitle }
        guard let primary = videoTracks.first ?? audioTracks.first ?? subtitleTracks.first else { return nil }
        let totalSize = tracks.reduce(Int64(0)) { $0 + $1.fileSize }
        let modifiedAt = tracks.compactMap(\.modifiedAt).max()
        return VideoItem(
            id: primary.url.deletingLastPathComponent().standardizedFileURL.path,
            url: primary.url,
            title: cleanTitle(primary.title),
            directory: primary.url.deletingLastPathComponent().lastPathComponent,
            fileSize: totalSize,
            modifiedAt: modifiedAt,
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks
        )
    }

    nonisolated private static func makeVideoItem(url: URL) -> VideoItem {
        let track = makeTrack(url: url) ?? MediaTrack(
            id: url.standardizedFileURL.path,
            url: url,
            title: url.deletingPathExtension().lastPathComponent,
            kind: .video,
            role: "video",
            language: nil,
            fileSize: 0,
            modifiedAt: nil
        )
        return makeVideoItem(from: [track])!
    }

    nonisolated private static func inferKind(from url: URL) -> MediaTrackKind? {
        let ext = url.pathExtension.lowercased()
        let name = url.deletingPathExtension().lastPathComponent.lowercased()
        if ["srt", "vtt"].contains(ext) { return .subtitle }
        if let formatID = youtubeFormatID(from: url), youtubeAudioFormatIDs.contains(formatID) { return .audio }
        if name.contains(".audio.") || ["m4a", "mp3", "aac", "opus"].contains(ext) { return .audio }
        if ["mp4", "mov", "m4v", "webm", "mkv"].contains(ext) { return .video }
        return nil
    }

    nonisolated private static func inferRole(from url: URL, kind: MediaTrackKind) -> String {
        let name = url.deletingPathExtension().lastPathComponent.lowercased()
        switch kind {
        case .video:
            if isYouTubeVP9Video(url) { return "VP9 video" }
            if isYouTubeAV1Video(url) { return "AV1 video" }
            if name.contains(".vp9") { return "VP9 2160p" }
            if name.contains(".av1") || name.contains(".video") { return "video" }
            return "embedded video"
        case .audio:
            if isYouTubeOpusAudio(url) { return "Opus audio" }
            if isYouTubeAACAudio(url) { return "AAC audio" }
            if name.contains(".translated.") { return "translated audio" }
            if name.contains(".generated.") || name.contains(".ai.") { return "AI audio" }
            if name.contains(".original.") { return "original audio" }
            return "audio"
        case .subtitle:
            if name.contains(".ru-orig.") { return "original captions" }
            if name.contains(".translated.") { return "translated captions" }
            if name.contains(".generated.") || name.contains(".ai.") { return "AI captions" }
            return "captions"
        }
    }

    nonisolated private static func inferLanguage(from url: URL, kind: MediaTrackKind) -> String? {
        let tokens = url.deletingPathExtension().lastPathComponent
            .split(separator: ".")
            .map(String.init)
        let known = ["ru-orig", "ru", "en", "de", "fr", "es", "it", "uk"]
        if let token = tokens.reversed().first(where: { known.contains($0) }) {
            return token
        }
        if kind == .audio, url.lastPathComponent.contains(".ru.") {
            return "ru"
        }
        return nil
    }

    nonisolated private static func cleanTitle(_ title: String) -> String {
        var cleaned = title
        if let streamSuffixRange = cleaned.range(
            of: #"\.(video|audio)(?:\.[A-Za-z0-9_-]+)*\.\d{2,4}$"#,
            options: .regularExpression
        ) {
            cleaned.removeSubrange(streamSuffixRange)
        }

        cleaned = cleaned
            .replacingOccurrences(of: ".video.vp9", with: "")
            .replacingOccurrences(of: ".video", with: "")
            .replacingOccurrences(of: ".audio.original.ru", with: "")
            .replacingOccurrences(of: ".audio", with: "")
        if let suffixRange = cleaned.range(of: #"\.\d{2,4}$"#, options: .regularExpression) {
            cleaned.removeSubrange(suffixRange)
        }
        return cleaned
    }

    nonisolated private static func playbackPreferenceRank(for track: MediaTrack) -> Int {
        let ext = track.url.pathExtension.lowercased()
        let name = track.url.deletingPathExtension().lastPathComponent.lowercased()
        if isYouTubeVP9Video(track.url) { return 560 }
        if isYouTubeAV1Video(track.url) { return 520 }
        if name.contains(".vp9") { return 560 }
        if name.contains(".av1") { return 520 }
        if ext == "mov" || ext == "m4v" { return 500 }
        if ext == "mp4", !name.contains(".av1") { return 450 }
        if ext == "webm" { return 320 }
        if ext == "mkv" { return 300 }
        return 250
    }

    private func requiresExternalPlayer(videoTrack: MediaTrack) -> Bool {
        let ext = videoTrack.url.pathExtension.lowercased()
        let name = videoTrack.url.deletingPathExtension().lastPathComponent.lowercased()
        return ext == "webm"
            || ext == "mkv"
            || name.contains(".video.")
            || name.contains(".vp9")
            || name.contains(".av1")
            || Self.isYouTubeVP9Video(videoTrack.url)
            || Self.isYouTubeAV1Video(videoTrack.url)
    }

    nonisolated private static let youtubeAudioFormatIDs: Set<String> = [
        "139", "140", "141",
        "249", "250", "251",
        "599", "600"
    ]

    nonisolated private static let youtubeOpusAudioFormatIDs: Set<String> = [
        "249", "250", "251", "600"
    ]

    nonisolated private static let youtubeAACAudioFormatIDs: Set<String> = [
        "139", "140", "141", "599"
    ]

    nonisolated private static let youtubeAV1VideoFormatIDs: Set<String> = [
        "394", "395", "396", "397", "398", "399", "400", "401"
    ]

    nonisolated private static let youtubeVP9VideoFormatIDs: Set<String> = [
        "242", "243", "244", "247", "248", "271", "272", "313", "315", "337"
    ]

    nonisolated private static func youtubeFormatID(from url: URL) -> String? {
        url.deletingPathExtension().lastPathComponent
            .split(separator: ".")
            .map(String.init)
            .reversed()
            .first(where: isASCIIInteger)
    }

    nonisolated private static func isASCIIInteger(_ value: String) -> Bool {
        !value.isEmpty && value.unicodeScalars.allSatisfy { scalar in
            scalar.value >= 48 && scalar.value <= 57
        }
    }

    nonisolated private static func isYouTubeAV1Video(_ url: URL) -> Bool {
        guard let formatID = youtubeFormatID(from: url) else { return false }
        return youtubeAV1VideoFormatIDs.contains(formatID)
    }

    nonisolated private static func isYouTubeVP9Video(_ url: URL) -> Bool {
        guard let formatID = youtubeFormatID(from: url) else { return false }
        return youtubeVP9VideoFormatIDs.contains(formatID)
    }

    nonisolated private static func isYouTubeOpusAudio(_ url: URL) -> Bool {
        guard let formatID = youtubeFormatID(from: url) else { return false }
        return youtubeOpusAudioFormatIDs.contains(formatID)
    }

    nonisolated private static func isYouTubeAACAudio(_ url: URL) -> Bool {
        guard let formatID = youtubeFormatID(from: url) else { return false }
        return youtubeAACAudioFormatIDs.contains(formatID)
    }

    private func externalPlayerPayload(videoTrack: MediaTrack, audioTrack: MediaTrack?, subtitleTrack: MediaTrack?, extra: [String: Any] = [:]) -> [String: Any] {
        var payload: [String: Any] = [
            "backend": "libmpv",
            "videoTrack": videoTrack.url.path,
            "audioTrack": audioTrack?.url.path ?? "embedded",
            "subtitleTrack": subtitleTrack?.url.path ?? "off",
            "subtitleCueCount": subtitleTrack == nil ? 0 : subtitleCues.count
        ]
        extra.forEach { payload[$0.key] = $0.value }
        return payload
    }

    private func makePlayerItem(videoTrack: MediaTrack, audioTrack: MediaTrack?) -> AVPlayerItem {
        guard let audioTrack else {
            return AVPlayerItem(url: videoTrack.url)
        }

        let videoAsset = AVURLAsset(url: videoTrack.url)
        let audioAsset = AVURLAsset(url: audioTrack.url)
        let composition = AVMutableComposition()
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)

        do {
            if let sourceVideo = videoAsset.tracks(withMediaType: .video).first,
               let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionVideo.insertTimeRange(timeRange, of: sourceVideo, at: .zero)
                compositionVideo.preferredTransform = sourceVideo.preferredTransform
            }
            if let sourceAudio = audioAsset.tracks(withMediaType: .audio).first,
               let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let audioRange = CMTimeRange(start: .zero, duration: min(videoAsset.duration, audioAsset.duration))
                try compositionAudio.insertTimeRange(audioRange, of: sourceAudio, at: .zero)
            }
            return AVPlayerItem(asset: composition)
        } catch {
            statusText = "Track composition failed; using video only"
            logger.append(type: "track_composition_failed", video: selectedVideo, payload: [
                "error": String(describing: error),
                "videoTrack": videoTrack.url.path,
                "audioTrack": audioTrack.url.path
            ])
            return AVPlayerItem(url: videoTrack.url)
        }
    }

    private func subtitleText(at seconds: Double) -> String {
        guard !subtitleCues.isEmpty else { return "" }
        return subtitleCues.first { seconds >= $0.start && seconds <= $0.end }?.text ?? ""
    }

    private func nextSubtitleCue(after seconds: Double) -> SubtitleCue? {
        subtitleCues.first { $0.start > seconds }
    }

    private func subtitleTimelineDuration() -> Double {
        subtitleCues.map(\.end).max() ?? 0
    }

    nonisolated private static func loadSubtitleCues(from track: MediaTrack) -> [SubtitleCue] {
        guard let content = try? String(contentsOf: track.url, encoding: .utf8) else { return [] }
        return parseSubtitleCues(content)
    }

    nonisolated private static func parseSubtitleCues(_ content: String) -> [SubtitleCue] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return normalized.components(separatedBy: "\n\n").compactMap { block in
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard let timingIndex = lines.firstIndex(where: { $0.contains("-->") }) else { return nil }
            let parts = lines[timingIndex].components(separatedBy: "-->")
            guard parts.count == 2,
                  let start = parseSubtitleTime(parts[0]),
                  let end = parseSubtitleTime(parts[1]) else { return nil }
            let text = lines.dropFirst(timingIndex + 1)
                .map { $0.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression) }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return SubtitleCue(start: start, end: end, text: text)
        }
    }

    nonisolated private static func parseSubtitleTime(_ value: String) -> Double? {
        let timestamp = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .first
            .map(String.init)
        guard let timestamp else { return nil }

        let cleaned = timestamp
            .replacingOccurrences(of: ",", with: ".")
        let pieces = cleaned.split(separator: ":").map(String.init)
        guard pieces.count == 2 || pieces.count == 3,
              let seconds = Double(pieces.last ?? ""),
              let minutes = Double(pieces.dropLast().last ?? "") else { return nil }
        let hours: Double
        if pieces.count > 2 {
            guard let parsedHours = Double(pieces.dropLast(2).last ?? "") else { return nil }
            hours = parsedHours
        } else {
            hours = 0
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    private func trackPayload(_ track: MediaTrack) -> [String: Any] {
        [
            "path": track.url.path,
            "role": track.role,
            "language": track.language ?? "",
            "fileSize": track.fileSize
        ]
    }

    private func playbackPayload(extra: [String: Any] = [:]) -> [String: Any] {
        var payload: [String: Any] = [
            "currentTime": currentTime,
            "duration": duration,
            "rate": rate,
            "volume": volume,
            "isPlaying": isPlaying
        ]
        extra.forEach { payload[$0.key] = $0.value }
        return payload
    }
}

struct VideoPlayerWorkbench: View {
    @ObservedObject var model: VideoPlayerModel

    var body: some View {
        HStack(spacing: 0) {
            VideoLibrarySidebar(model: model)
            Divider()
            VStack(spacing: 0) {
                PlayerTopBar(model: model)
                Divider()
                PlayerStage(model: model)
                Divider()
                PlaybackControls(model: model)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            model.activatePlaybackSurface()
        }
    }
}

struct PlayerStage: View {
    @ObservedObject var model: VideoPlayerModel

    private var loadingTitle: String {
        if model.isBuffering {
            return model.isAudioOnlyPlayback ? "Buffering audio" : "Buffering video"
        }
        return model.isAudioOnlyPlayback ? "Preparing audio" : "Preparing video"
    }

    private var loadingDetail: String {
        model.isBuffering ? "Filling the playback buffer" : "Reading media timing"
    }

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)

            if model.selectedVideo == nil {
                ContentUnavailableView("No media selected", systemImage: "play.rectangle", description: Text("Open media or add files to the configured media library."))
            } else if model.isAudioOnlyPlayback || model.isSubtitleOnlyPlayback {
                MediaOnlyStage(model: model)
            } else if model.selectedTrackUsesExternalPlayer {
                EmbeddedMPVPlayerView(model: model)
            } else {
                AVKitPlayerView(player: model.player)
            }

            if model.selectedVideo != nil, model.isPreparingVideo || model.isBuffering {
                PlayerLoadingOverlay(title: loadingTitle, detail: loadingDetail)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            if !model.subtitleText.isEmpty {
                VStack {
                    Spacer()
                    Text(model.subtitleText)
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.68))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: model.isPreparingVideo)
        .animation(.easeInOut(duration: 0.18), value: model.isBuffering)
        .animation(.easeInOut(duration: 0.12), value: model.subtitleText)
    }
}

struct MediaOnlyStage: View {
    @ObservedObject var model: VideoPlayerModel

    private var primaryText: String {
        if model.selectedSubtitleTrack != nil {
            return model.subtitleTimelineDisplayText
        }
        return model.selectedVideo?.title ?? model.mediaOnlyStageTitle
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: model.isAudioOnlyPlayback ? "waveform.circle.fill" : "captions.bubble.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(model.isAudioOnlyPlayback ? .blue : .red)

            VStack(spacing: 4) {
                Text(model.mediaOnlyStageTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(model.mediaOnlyStageDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Text(primaryText)
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: 760)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct VideoLibrarySidebar: View {
    @ObservedObject var model: VideoPlayerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "play.rectangle.on.rectangle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.red)
                Text("FUM Player")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.top, 18)

            HStack(spacing: 8) {
                Button {
                    model.openVideos()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Open media files")

                Button {
                    model.reloadLibrary()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Reload library")

                Button {
                    model.revealSelected()
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .disabled(model.selectedVideo == nil)
                .help("Reveal selected video")
            }

            Text(model.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            VectorCutPanel(model: model)

            if model.isScanningLibrary {
                LoadingStatusBadge(title: "Scanning library", detail: "Looking for fresh media")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(model.videos) { video in
                        VideoRow(
                            video: video,
                            selected: model.selectedVideo == video
                        ) {
                            model.select(video, autoplay: true)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 14)
        .frame(width: 310)
    }
}

struct VectorCutPanel: View {
    @ObservedObject var model: VideoPlayerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "timeline.selection")
                    .foregroundStyle(.red)
                    .frame(width: 18)

                Text("Vector cut")
                    .font(.caption.weight(.semibold))

                Spacer(minLength: 0)

                Button {
                    model.saveVectorCut()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(model.selectedVideo == nil)
                .help("Save vector cut")

                Button {
                    model.openVectorCut()
                } label: {
                    Image(systemName: "folder")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Open vector cut")

                Button {
                    model.revealVectorCut()
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(model.activeVectorCutURL == nil)
                .help("Reveal vector cut")
            }

            Text(model.activeVectorCut?.title ?? "No document")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(model.vectorCutStatusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LoadingStatusBadge: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            FUMLoadingIndicator(size: 22, lineWidth: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

struct PlayerLoadingOverlay: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            FUMLoadingIndicator(size: 54, lineWidth: 5)

            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

struct FUMLoadingIndicator: View {
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees(phase.truncatingRemainder(dividingBy: 1.2) / 1.2 * 360)
            let pulse = 0.72 + 0.18 * sin(phase * 4)

            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.16), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0.10, to: 0.78)
                    .stroke(
                        AngularGradient(
                            colors: [.red.opacity(0.25), .red, .orange, .red.opacity(0.25)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(rotation)

                Circle()
                    .fill(.red.opacity(0.18))
                    .frame(width: size * pulse, height: size * pulse)

                Circle()
                    .fill(.red)
                    .frame(width: max(5, size * 0.14), height: max(5, size * 0.14))
                    .offset(y: -size / 2)
                    .rotationEffect(rotation)
            }
            .frame(width: size, height: size)
        }
        .accessibilityLabel("Loading")
    }
}

struct VideoRow: View {
    let video: VideoItem
    let selected: Bool
    let action: () -> Void

    private var symbol: String {
        if selected {
            return "play.circle.fill"
        }
        if !video.videoTracks.isEmpty {
            return "film"
        }
        if !video.audioTracks.isEmpty {
            return "waveform"
        }
        return "captions.bubble"
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(selected ? .red : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                    Text(video.directory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(video.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(selected ? Color.red.opacity(0.11) : Color.primary.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct PlayerTopBar: View {
    @ObservedObject var model: VideoPlayerModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.selectedVideo?.title ?? "FUM Player")
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                Text(model.selectedVideoTrack?.url.path ?? model.selectedAudioTrack?.url.path ?? model.selectedSubtitleTrack?.url.path ?? model.selectedVideo?.url.path ?? ПутиПриложения.текущие.память.appendingPathComponent("video-player/events.jsonl").path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text("\(formatTime(model.currentTime)) / \(formatTime(model.duration))")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 128, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }
}

struct PlaybackControls: View {
    @ObservedObject var model: VideoPlayerModel
    @State private var isEditingTimeline = false

    var body: some View {
        VStack(spacing: 10) {
            MediaTrackControls(model: model)

            Slider(
                value: Binding(
                    get: { model.currentTime },
                    set: { value in
                        if isEditingTimeline {
                            model.scrub(to: value)
                        } else {
                            model.seek(to: value, reason: "scrub_seek")
                        }
                    }
                ),
                in: 0...max(model.duration, 1),
                onEditingChanged: { editing in
                    isEditingTimeline = editing
                    if editing {
                        model.beginScrubbing()
                    } else {
                        model.finishScrubbing()
                    }
                }
            )
            .disabled(model.selectedVideo == nil)

            HStack(spacing: 14) {
                Button {
                    model.skip(by: -10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .frame(width: 32, height: 30)
                }
                .buttonStyle(.borderless)
                .disabled(model.selectedVideo == nil)
                .help("Back 10 seconds")

                Button {
                    model.playPause()
                } label: {
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.selectedVideo == nil)
                .help(model.isPlaying ? "Pause" : "Play")

                Button {
                    model.skip(by: 10)
                } label: {
                    Image(systemName: "goforward.10")
                        .frame(width: 32, height: 30)
                }
                .buttonStyle(.borderless)
                .disabled(model.selectedVideo == nil)
                .help("Forward 10 seconds")

                Spacer()

                Picker("", selection: Binding(
                    get: { model.rate },
                    set: { model.setRate($0) }
                )) {
                    Text("0.5x").tag(Float(0.5))
                    Text("1x").tag(Float(1.0))
                    Text("1.25x").tag(Float(1.25))
                    Text("1.5x").tag(Float(1.5))
                    Text("2x").tag(Float(2.0))
                }
                .labelsHidden()
                .frame(width: 86)
                .help("Playback speed")

                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { model.volume },
                            set: { model.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 120)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct MediaTrackControls: View {
    @ObservedObject var model: VideoPlayerModel

    var body: some View {
        HStack(spacing: 10) {
            trackPicker(
                symbol: "film.stack",
                title: "Video track",
                selection: Binding(
                    get: { model.selectedVideoTrack?.id ?? "" },
                    set: { if !$0.isEmpty { model.selectVideoTrack(id: $0) } }
                ),
                tracks: model.selectedVideo?.videoTracks ?? [],
                emptyTitle: "No video"
            )

            trackPicker(
                symbol: "waveform",
                title: "Audio track",
                selection: Binding(
                    get: { model.selectedAudioTrack?.id ?? "" },
                    set: { if !$0.isEmpty { model.selectAudioTrack(id: $0) } }
                ),
                tracks: model.selectedVideo?.audioTracks ?? [],
                emptyTitle: "No audio"
            )

            subtitlePicker
        }
        .disabled(model.selectedVideo == nil)
    }

    private var subtitlePicker: some View {
        HStack(spacing: 6) {
            Image(systemName: "captions.bubble")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Picker("Subtitles", selection: Binding(
                get: { model.selectedSubtitleTrack?.id ?? "off" },
                set: { value in
                    value == "off" ? model.disableSubtitles() : model.selectSubtitleTrack(id: value)
                }
            )) {
                Text("Off").tag("off")
                ForEach(model.selectedVideo?.subtitleTracks ?? []) { track in
                    Text(track.displayTitle).tag(track.id)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 210)
            .help("Subtitle track")
        }
    }

    private func trackPicker(symbol: String, title: String, selection: Binding<String>, tracks: [MediaTrack], emptyTitle: String = "Embedded") -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Picker(title, selection: selection) {
                if tracks.isEmpty {
                    Text(emptyTitle).tag("")
                }
                ForEach(tracks) { track in
                    Text(track.displayTitle).tag(track.id)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 210)
            .help(title)
        }
    }
}

struct AVKitPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.allowsPictureInPicturePlayback = true
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

struct EmbeddedMPVPlayerView: NSViewRepresentable {
    @ObservedObject var model: VideoPlayerModel

    func makeNSView(context: Context) -> EmbeddedMPVRenderNSView {
        let view = EmbeddedMPVRenderNSView()
        view.attach(model: model)
        return view
    }

    func updateNSView(_ nsView: EmbeddedMPVRenderNSView, context: Context) {
        nsView.attach(model: model)
    }

    static func dismantleNSView(_ nsView: EmbeddedMPVRenderNSView, coordinator: ()) {
        nsView.shutdown()
    }
}

@MainActor
final class EmbeddedMPVRenderNSView: NSOpenGLView {
    private weak var model: VideoPlayerModel?
    private var playbackController: EmbeddedMPVPlaybackController?

    init() {
        super.init(frame: .zero, pixelFormat: Self.makePixelFormat())!
        wantsBestResolutionOpenGLSurface = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        pixelFormat = Self.makePixelFormat()
        wantsBestResolutionOpenGLSurface = true
    }

    override var isOpaque: Bool { true }

    func attach(model: VideoPlayerModel) {
        self.model = model
        setupControllerIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.setupControllerIfNeeded()
            self?.needsDisplay = true
        }
    }

    override func prepareOpenGL() {
        super.prepareOpenGL()
        var swapInterval: GLint = 1
        openGLContext?.setValues(&swapInterval, for: .swapInterval)
        setupControllerIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupControllerIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.setupControllerIfNeeded()
            self?.needsDisplay = true
        }
    }

    override func reshape() {
        super.reshape()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        openGLContext?.makeCurrentContext()
        playbackController?.render(width: Int(bounds.width * backingScaleFactor), height: Int(bounds.height * backingScaleFactor))
        openGLContext?.flushBuffer()
    }

    func shutdown() {
        if let playbackController {
            model?.unregisterEmbeddedPlayer(playbackController)
            playbackController.shutdown()
        }
        playbackController = nil
    }

    private var backingScaleFactor: CGFloat {
        window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
    }

    private func setupControllerIfNeeded() {
        guard playbackController == nil, let model, openGLContext != nil else { return }
        openGLContext?.makeCurrentContext()
        do {
            let controller = try EmbeddedMPVPlaybackController(view: self, model: model)
            playbackController = controller
            model.registerEmbeddedPlayer(controller)
            needsDisplay = true
        } catch {
            model.embeddedPlayerDidFail(error)
        }
    }

    private static func makePixelFormat() -> NSOpenGLPixelFormat {
        let attributes: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAOpenGLProfile),
            UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFAColorSize),
            UInt32(24),
            UInt32(NSOpenGLPFAAlphaSize),
            UInt32(8),
            UInt32(0)
        ]
        return NSOpenGLPixelFormat(attributes: attributes)!
    }
}

enum EmbeddedMPVError: LocalizedError {
    case createFailed
    case commandFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "libmpv could not create an embedded player"
        case let .commandFailed(action, message):
            return "\(action): \(message)"
        }
    }
}

@MainActor
final class EmbeddedMPVPlaybackController {
    private struct PendingAttachment {
        let audioPath: String?
        let subtitlePath: String?
        let startTime: Double
        let autoplay: Bool
    }

    private weak var view: EmbeddedMPVRenderNSView?
    private weak var model: VideoPlayerModel?
    private var player: OpaquePointer?
    private var renderer: OpaquePointer?
    private var renderTimer: Timer?
    private var eventTimer: Timer?
    private var progressTimer: Timer?
    private var pendingAttachment: PendingAttachment?

    init(view: EmbeddedMPVRenderNSView, model: VideoPlayerModel) throws {
        self.view = view
        self.model = model

        guard let player = mpv_create() else {
            throw EmbeddedMPVError.createFailed
        }
        self.player = player

        mpv_set_option_string(player, "terminal", "no")
        mpv_set_option_string(player, "config", "no")
        mpv_set_option_string(player, "input-default-bindings", "no")
        mpv_set_option_string(player, "osc", "no")
        mpv_set_option_string(player, "keep-open", "yes")
        mpv_set_option_string(player, "vo", "libmpv")
        mpv_set_option_string(player, "sid", "no")
        mpv_set_option_string(player, "sub-auto", "no")
        mpv_set_option_string(player, "sub-visibility", "no")

        try check(mpv_initialize(player), action: "Initialize libmpv")

        var renderer: OpaquePointer?
        try check(fum_mpv_create_opengl_renderer(&renderer, player), action: "Create libmpv OpenGL renderer")
        self.renderer = renderer

        renderTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.view?.needsDisplay = true
            }
        }
        eventTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processEvents()
            }
        }
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollProgress()
            }
        }
    }

    fileprivate func load(_ request: ExternalPlaybackRequest, volume: Double, rate: Float) throws {
        guard let player else { throw EmbeddedMPVError.createFailed }

        setPaused(true)
        setVolume(volume)
        setRate(rate)
        pendingAttachment = PendingAttachment(
            audioPath: request.audioTrack?.url.path,
            subtitlePath: request.subtitleTrack?.url.path,
            startTime: request.startTime,
            autoplay: request.autoplay
        )

        try request.videoTrack.url.path.withCString { path in
            try check(fum_mpv_load_file_async(player, path), action: "Queue VP9 video")
        }
    }

    func setPaused(_ paused: Bool) {
        guard let player else { return }
        _ = fum_mpv_set_flag_property(player, "pause", paused ? 1 : 0)
    }

    func setVolume(_ volume: Double) {
        guard let player else { return }
        _ = fum_mpv_set_double_property(player, "volume", min(max(volume, 0), 1) * 100)
    }

    func setRate(_ rate: Float) {
        guard let player else { return }
        _ = fum_mpv_set_double_property(player, "speed", Double(rate))
    }

    func seekAbsolute(_ seconds: Double) {
        guard let player else { return }
        _ = fum_mpv_seek_absolute(player, seconds)
    }

    func seekRelative(_ seconds: Double) {
        guard let player else { return }
        _ = fum_mpv_seek_relative(player, seconds)
    }

    func stop() {
        guard let player else { return }
        _ = fum_mpv_stop(player)
    }

    func render(width: Int, height: Int) {
        guard let renderer else { return }
        _ = fum_mpv_render_opengl(renderer, Int32(max(width, 1)), Int32(max(height, 1)), 1)
    }

    func shutdown() {
        renderTimer?.invalidate()
        eventTimer?.invalidate()
        progressTimer?.invalidate()
        renderTimer = nil
        eventTimer = nil
        progressTimer = nil
        pendingAttachment = nil
        if let renderer {
            fum_mpv_free_renderer(renderer)
            self.renderer = nil
        }
        if let player {
            mpv_terminate_destroy(player)
            self.player = nil
        }
    }

    private func processEvents() {
        guard let player else { return }
        while true {
            var eventID: Int32 = 0
            var error: Int32 = 0
            var replyUserdata: UInt64 = 0
            let code = fum_mpv_poll_event(player, &eventID, &error, &replyUserdata)
            guard code >= 0 else { return }
            if fum_mpv_event_is_none(eventID) != 0 {
                return
            }
            if fum_mpv_event_is_file_loaded(eventID) != 0 {
                attachPendingExternalTracks()
            }
        }
    }

    private func attachPendingExternalTracks() {
        guard let player, let attachment = pendingAttachment else { return }
        pendingAttachment = nil

        do {
            if let audioPath = attachment.audioPath {
                try audioPath.withCString { path in
                    try check(fum_mpv_add_audio_file(player, path), action: "Attach audio track")
                }
                _ = fum_mpv_set_string_property(player, "aid", "auto")
            }
            _ = fum_mpv_set_string_property(player, "sid", "no")
            _ = fum_mpv_set_flag_property(player, "sub-visibility", 0)
            if attachment.startTime > 0 {
                seekAbsolute(attachment.startTime)
            }
            setPaused(!attachment.autoplay)
            model?.embeddedPlayerDidPrepareExternalTracks(
                audioPath: attachment.audioPath,
                subtitlePath: attachment.subtitlePath,
                activeAudioID: stringProperty("aid"),
                audioCodec: stringProperty("audio-codec-name")
            )
        } catch {
            model?.embeddedPlayerDidFail(error)
        }
    }

    private func stringProperty(_ name: String) -> String? {
        guard let player else { return nil }
        return name.withCString { propertyName in
            guard let value = fum_mpv_get_string_property(player, propertyName) else {
                return nil
            }
            defer { fum_mpv_free(value) }
            return String(cString: value)
        }
    }

    private func pollProgress() {
        guard let player else { return }
        var time = 0.0
        var total = 0.0
        var paused: Int32 = 1
        _ = fum_mpv_get_double_property(player, "time-pos", &time)
        _ = fum_mpv_get_double_property(player, "duration", &total)
        _ = fum_mpv_get_flag_property(player, "pause", &paused)
        model?.updateEmbeddedPlayerProgress(currentTime: time, duration: total, isPaused: paused != 0)
    }

    private func check(_ code: Int32, action: String) throws {
        guard code < 0 else { return }
        let message = fum_mpv_error_string(code).map(String.init(cString:)) ?? "unknown libmpv error"
        throw EmbeddedMPVError.commandFailed(action, message)
    }
}

struct JSONLInteractionLogger {
    let path: String
    private let isoFormatter = ISO8601DateFormatter()

    func append(type: String, video: VideoItem? = nil, payload: [String: Any] = [:]) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        var event = payload
        event["timestamp"] = isoFormatter.string(from: Date())
        event["type"] = type

        if let video {
            event["video"] = [
                "title": video.title,
                "path": video.url.path,
                "directory": video.directory,
                "fileSize": video.fileSize
            ]
        }

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: expandedPath) {
                FileManager.default.createFile(atPath: expandedPath, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            let data = try JSONSerialization.data(withJSONObject: event, options: [.sortedKeys])
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            try handle.close()
        } catch {
            fputs("Failed to append video player event to \(expandedPath): \(error)\n", stderr)
        }
    }
}

extension Array where Element == VideoItem {
    func uniquedByURL() -> [VideoItem] {
        var seen = Set<String>()
        return filter { item in
            seen.insert(item.url.standardizedFileURL.path).inserted
        }
    }
}

extension CMTime {
    var secondsValue: Double {
        guard isNumeric else { return 0 }
        let value = seconds
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds > 0 else {
        return "00:00"
    }
    let total = Int(seconds.rounded(.down))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}
