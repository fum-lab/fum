import Foundation

enum FUMVectorVideoFormat {
    static let schema = "fum.video.vector-cut"
    static let version = 1
    static let fileSuffix = ".fumcut.json"
}

struct FUMVectorVideoDocument: Codable, Equatable, Identifiable, Sendable {
    var schema: String
    var version: Int
    var id: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var canvas: FUMVectorVideoCanvas
    var playback: FUMVectorVideoPlayback
    var sources: [FUMVectorVideoSource]
    var timeline: FUMVectorVideoTimeline
    var markers: [FUMVectorVideoMarker]
    var notes: [String: String]

    var shortSummary: String {
        "\(sources.count) source\(sources.count == 1 ? "" : "s") · \(timeline.tracks.count) track\(timeline.tracks.count == 1 ? "" : "s") · \(formatDuration(playback.duration))"
    }

    static func makeSingleSourceCut(
        video: VideoItem,
        videoTrack: MediaTrack,
        audioTrack: MediaTrack?,
        subtitleTrack: MediaTrack?,
        currentTime: Double,
        duration: Double
    ) -> FUMVectorVideoDocument {
        let now = Date()
        let documentID = "cut-\(UUID().uuidString.lowercased())"
        let timelineDuration = max(0, duration)
        let videoSourceID = sourceID(for: videoTrack, role: "video")
        let audioSourceID = audioTrack.map { sourceID(for: $0, role: "audio") } ?? videoSourceID
        let subtitleSourceID = subtitleTrack.map { sourceID(for: $0, role: "subtitle") }

        var sources = [
            FUMVectorVideoSource(
                id: videoSourceID,
                kind: .video,
                uri: videoTrack.url.standardizedFileURL.absoluteString,
                displayName: videoTrack.title,
                role: videoTrack.role,
                language: videoTrack.language,
                mediaType: videoTrack.url.pathExtension.lowercased(),
                duration: timelineDuration > 0 ? timelineDuration : nil,
                fileSize: videoTrack.fileSize,
                modifiedAt: videoTrack.modifiedAt,
                metadata: [
                    "libraryDirectory": video.directory,
                    "containerTitle": video.title
                ]
            )
        ]

        if let audioTrack {
            sources.append(FUMVectorVideoSource(
                id: audioSourceID,
                kind: .audio,
                uri: audioTrack.url.standardizedFileURL.absoluteString,
                displayName: audioTrack.title,
                role: audioTrack.role,
                language: audioTrack.language,
                mediaType: audioTrack.url.pathExtension.lowercased(),
                duration: timelineDuration > 0 ? timelineDuration : nil,
                fileSize: audioTrack.fileSize,
                modifiedAt: audioTrack.modifiedAt,
                metadata: [
                    "libraryDirectory": video.directory,
                    "containerTitle": video.title
                ]
            ))
        }

        if let subtitleTrack, let subtitleSourceID {
            sources.append(FUMVectorVideoSource(
                id: subtitleSourceID,
                kind: .subtitle,
                uri: subtitleTrack.url.standardizedFileURL.absoluteString,
                displayName: subtitleTrack.title,
                role: subtitleTrack.role,
                language: subtitleTrack.language,
                mediaType: subtitleTrack.url.pathExtension.lowercased(),
                duration: timelineDuration > 0 ? timelineDuration : nil,
                fileSize: subtitleTrack.fileSize,
                modifiedAt: subtitleTrack.modifiedAt,
                metadata: [
                    "libraryDirectory": video.directory,
                    "containerTitle": video.title
                ]
            ))
        }

        let fullRange = FUMVectorVideoTimeRange(start: 0, duration: timelineDuration)
        var tracks = [
            FUMVectorVideoTrack(
                id: "track-video-main",
                kind: .visual,
                name: "Main video",
                muted: false,
                locked: false,
                clips: [
                    FUMVectorVideoClip(
                        id: "clip-\(videoSourceID)",
                        kind: .media,
                        sourceID: videoSourceID,
                        timeRange: fullRange,
                        sourceRange: fullRange,
                        speed: 1,
                        opacity: 1,
                        volume: nil,
                        transform: .identity,
                        crop: nil,
                        text: nil,
                        effects: [],
                        transitions: []
                    )
                ]
            ),
            FUMVectorVideoTrack(
                id: "track-audio-main",
                kind: .audio,
                name: audioTrack == nil ? "Embedded audio" : "External audio",
                muted: false,
                locked: false,
                clips: [
                    FUMVectorVideoClip(
                        id: "clip-\(audioSourceID)-audio",
                        kind: .media,
                        sourceID: audioSourceID,
                        timeRange: fullRange,
                        sourceRange: fullRange,
                        speed: 1,
                        opacity: nil,
                        volume: 1,
                        transform: nil,
                        crop: nil,
                        text: nil,
                        effects: [],
                        transitions: []
                    )
                ]
            )
        ]

        if let subtitleSourceID {
            tracks.append(FUMVectorVideoTrack(
                id: "track-subtitle-main",
                kind: .subtitle,
                name: "Captions",
                muted: false,
                locked: false,
                clips: [
                    FUMVectorVideoClip(
                        id: "clip-\(subtitleSourceID)",
                        kind: .captionData,
                        sourceID: subtitleSourceID,
                        timeRange: fullRange,
                        sourceRange: fullRange,
                        speed: 1,
                        opacity: 1,
                        volume: nil,
                        transform: nil,
                        crop: nil,
                        text: nil,
                        effects: [],
                        transitions: []
                    )
                ]
            ))
        }

        return FUMVectorVideoDocument(
            schema: FUMVectorVideoFormat.schema,
            version: FUMVectorVideoFormat.version,
            id: documentID,
            title: video.title,
            createdAt: now,
            updatedAt: now,
            canvas: FUMVectorVideoCanvas(width: 1920, height: 1080, backgroundColor: "#000000"),
            playback: FUMVectorVideoPlayback(frameRate: 30, duration: timelineDuration, previewTime: max(0, currentTime)),
            sources: sources,
            timeline: FUMVectorVideoTimeline(tracks: tracks),
            markers: [],
            notes: [
                "storage": "Live vector montage: references source media and edit operations, no rendered movie file."
            ]
        )
    }
}

struct FUMVectorVideoCanvas: Codable, Equatable, Sendable {
    var width: Int
    var height: Int
    var backgroundColor: String
}

struct FUMVectorVideoPlayback: Codable, Equatable, Sendable {
    var frameRate: Double
    var duration: Double
    var previewTime: Double
}

struct FUMVectorVideoSource: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var kind: FUMVectorVideoSourceKind
    var uri: String
    var displayName: String
    var role: String
    var language: String?
    var mediaType: String?
    var duration: Double?
    var fileSize: Int64?
    var modifiedAt: Date?
    var metadata: [String: String]
}

enum FUMVectorVideoSourceKind: String, Codable, Sendable {
    case video
    case audio
    case subtitle
    case image
    case vector
    case html
    case text
    case generated
    case remote
}

struct FUMVectorVideoTimeline: Codable, Equatable, Sendable {
    var tracks: [FUMVectorVideoTrack]
}

struct FUMVectorVideoTrack: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var kind: FUMVectorVideoTrackKind
    var name: String
    var muted: Bool
    var locked: Bool
    var clips: [FUMVectorVideoClip]
}

enum FUMVectorVideoTrackKind: String, Codable, Sendable {
    case visual
    case audio
    case subtitle
    case overlay
    case control
}

struct FUMVectorVideoClip: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var kind: FUMVectorVideoClipKind
    var sourceID: String?
    var timeRange: FUMVectorVideoTimeRange
    var sourceRange: FUMVectorVideoTimeRange?
    var speed: Double
    var opacity: Double?
    var volume: Double?
    var transform: FUMVectorVideoTransform?
    var crop: FUMVectorVideoInsets?
    var text: FUMVectorVideoText?
    var effects: [FUMVectorVideoEffect]
    var transitions: [FUMVectorVideoTransition]
}

enum FUMVectorVideoClipKind: String, Codable, Sendable {
    case media
    case captionData
    case text
    case shape
    case composition
}

struct FUMVectorVideoTimeRange: Codable, Equatable, Sendable {
    var start: Double
    var duration: Double

    var end: Double {
        start + duration
    }
}

struct FUMVectorVideoTransform: Codable, Equatable, Sendable {
    static let identity = FUMVectorVideoTransform(x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, anchorX: 0.5, anchorY: 0.5)

    var x: Double
    var y: Double
    var scaleX: Double
    var scaleY: Double
    var rotation: Double
    var anchorX: Double
    var anchorY: Double
}

struct FUMVectorVideoInsets: Codable, Equatable, Sendable {
    var top: Double
    var right: Double
    var bottom: Double
    var left: Double
}

struct FUMVectorVideoText: Codable, Equatable, Sendable {
    var body: String
    var language: String?
    var style: FUMVectorVideoTextStyle
}

struct FUMVectorVideoTextStyle: Codable, Equatable, Sendable {
    var fontFamily: String
    var fontSize: Double
    var color: String
    var backgroundColor: String?
    var alignment: String
}

struct FUMVectorVideoEffect: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var type: String
    var parameters: [String: String]
    var keyframes: [FUMVectorVideoKeyframe]
}

struct FUMVectorVideoKeyframe: Codable, Equatable, Sendable {
    var time: Double
    var property: String
    var value: Double
    var easing: String?
}

struct FUMVectorVideoTransition: Codable, Equatable, Sendable {
    var edge: FUMVectorVideoTransitionEdge
    var type: String
    var duration: Double
    var easing: String?
}

enum FUMVectorVideoTransitionEdge: String, Codable, Sendable {
    case incoming = "in"
    case outgoing = "out"
}

struct FUMVectorVideoMarker: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var time: Double
    var title: String
    var color: String?
}

enum FUMVectorVideoDocumentStore {
    static var defaultDirectory: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent("FUM Vector Cuts", isDirectory: true)
    }

    static func read(from url: URL) throws -> FUMVectorVideoDocument {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document = try decoder.decode(FUMVectorVideoDocument.self, from: data)
        guard document.schema == FUMVectorVideoFormat.schema else {
            throw FUMVectorVideoDocumentError.unsupportedSchema(document.schema)
        }
        guard document.version <= FUMVectorVideoFormat.version else {
            throw FUMVectorVideoDocumentError.unsupportedVersion(document.version)
        }
        return document
    }

    @discardableResult
    static func write(_ document: FUMVectorVideoDocument, to url: URL) throws -> URL {
        var outputURL = url
        if outputURL.pathExtension.isEmpty {
            outputURL.appendPathExtension("fumcut.json")
        }

        var copy = document
        copy.updatedAt = Date()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(copy)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    static func suggestedFileName(for title: String) -> String {
        let slug = title
            .lowercased()
            .map { character in
                character.isLetter || character.isNumber ? String(character) : "-"
            }
            .joined()
            .split(separator: "-")
            .prefix(8)
            .joined(separator: "-")
        return "\(slug.isEmpty ? "fum-cut" : slug)\(FUMVectorVideoFormat.fileSuffix)"
    }
}

enum FUMVectorVideoDocumentError: LocalizedError {
    case unsupportedSchema(String)
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchema(schema):
            return "Unsupported vector video schema: \(schema)"
        case let .unsupportedVersion(version):
            return "Unsupported vector video version: \(version)"
        }
    }
}

private func sourceID(for track: MediaTrack, role: String) -> String {
    "\(role)-\(stableHash(track.url.standardizedFileURL.path))"
}

private func stableHash(_ value: String) -> String {
    let offset: UInt64 = 14_695_981_039_346_656_037
    let prime: UInt64 = 1_099_511_628_211
    let hash = value.utf8.reduce(offset) { partial, byte in
        (partial ^ UInt64(byte)) &* prime
    }
    return String(format: "%016llx", hash)
}

private func formatDuration(_ seconds: Double) -> String {
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
