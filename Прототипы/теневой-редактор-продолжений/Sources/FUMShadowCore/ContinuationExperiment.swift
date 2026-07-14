import Foundation

public enum ExperimentStatus: String, Codable, Equatable, Sendable {
    case collecting
    case completed
    case invalidated
    case failed
}

public enum ExperimentInvalidationReason: String, Codable, Equatable, Sendable {
    case prefixChanged
    case documentShortened
    case replacedByNewCheckpoint
    case modelFailure
}

public struct ShadowCheckpoint: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let documentVersion: Int
    public let prefixByteCount: Int
    public let prefixFingerprint: UInt64
    public let modelContext: Data
    public let contextSeed: Data
    public let modelIdentity: String
    public let horizonBytes: Int
    public let indexConfiguration: SuffixIndexConfiguration

    public init(
        prefix: Data,
        documentVersion: Int,
        modelIdentity: String,
        horizonBytes: Int,
        contextWindowBytes: Int,
        indexConfiguration: SuffixIndexConfiguration,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        precondition(horizonBytes > 0, "horizonBytes must be positive")
        precondition(contextWindowBytes > 0, "contextWindowBytes must be positive")
        self.id = id
        self.createdAt = createdAt
        self.documentVersion = documentVersion
        self.prefixByteCount = prefix.count
        self.prefixFingerprint = StableFingerprint.fnv1a64(prefix)
        self.modelContext = Self.validUTF8Suffix(prefix, limit: contextWindowBytes)
        self.contextSeed = Data(prefix.suffix(indexConfiguration.maxDepth))
        self.modelIdentity = modelIdentity
        self.horizonBytes = horizonBytes
        self.indexConfiguration = indexConfiguration
    }

    private static func validUTF8Suffix(_ data: Data, limit: Int) -> Data {
        var candidate = Data(data.suffix(limit))
        while !candidate.isEmpty, String(data: candidate, encoding: .utf8) == nil {
            candidate.removeFirst()
        }
        return candidate
    }
}

public struct ContinuationExperiment: Sendable {
    public let checkpoint: ShadowCheckpoint
    public private(set) var status: ExperimentStatus = .collecting
    public private(set) var invalidationReason: ExperimentInvalidationReason?
    public private(set) var humanContinuation = Data()
    public private(set) var modelContinuation = Data()
    public private(set) var comparison: ContinuationMetrics?
    public private(set) var latestDocumentVersion: Int
    private var humanStructureBuilder: ContinuationStructureBuilder
    private var modelStructureBuilder: ContinuationStructureBuilder

    public var humanStructure: ContinuationStructure {
        humanStructureBuilder.structure
    }

    public var modelStructure: ContinuationStructure {
        modelStructureBuilder.structure
    }

    public init(
        prefix: Data,
        documentVersion: Int,
        modelIdentity: String,
        horizonBytes: Int,
        contextWindowBytes: Int,
        indexConfiguration: SuffixIndexConfiguration
    ) {
        let checkpoint = ShadowCheckpoint(
            prefix: prefix,
            documentVersion: documentVersion,
            modelIdentity: modelIdentity,
            horizonBytes: horizonBytes,
            contextWindowBytes: contextWindowBytes,
            indexConfiguration: indexConfiguration
        )
        self.checkpoint = checkpoint
        latestDocumentVersion = documentVersion
        humanStructureBuilder = ContinuationStructureBuilder(
            seed: checkpoint.contextSeed,
            configuration: checkpoint.indexConfiguration
        )
        modelStructureBuilder = ContinuationStructureBuilder(
            seed: checkpoint.contextSeed,
            configuration: checkpoint.indexConfiguration
        )
    }

    public mutating func appendModelChunk(_ data: Data) {
        guard status == .collecting, modelContinuation.count < checkpoint.horizonBytes else {
            return
        }
        let remaining = checkpoint.horizonBytes - modelContinuation.count
        let accepted = Data(data.prefix(remaining))
        modelContinuation.append(accepted)
        modelStructureBuilder.append(accepted)
    }

    public mutating func observeDocument(_ document: Data, documentVersion: Int) throws {
        guard status == .collecting else { return }
        latestDocumentVersion = documentVersion

        guard document.count >= checkpoint.prefixByteCount else {
            invalidate(.documentShortened)
            return
        }

        let currentPrefix = Data(document.prefix(checkpoint.prefixByteCount))
        guard StableFingerprint.fnv1a64(currentPrefix) == checkpoint.prefixFingerprint else {
            invalidate(.prefixChanged)
            return
        }

        humanContinuation = Data(
            document
                .dropFirst(checkpoint.prefixByteCount)
                .prefix(checkpoint.horizonBytes)
        )
        humanStructureBuilder = ContinuationStructureBuilder(
            seed: checkpoint.contextSeed,
            configuration: checkpoint.indexConfiguration
        )
        humanStructureBuilder.append(humanContinuation)
        if humanContinuation.count >= checkpoint.horizonBytes {
            try complete()
        }
    }

    /// Records bytes from a verified insertion at the end of the document.
    /// The caller remains responsible for using `observeDocument` for edits
    /// that can change or shorten the checkpoint prefix.
    public mutating func observeAppendedBytes(
        _ data: Data,
        documentVersion: Int
    ) throws {
        guard status == .collecting else { return }
        latestDocumentVersion = documentVersion
        let remaining = checkpoint.horizonBytes - humanContinuation.count
        guard remaining > 0 else {
            try complete()
            return
        }
        let accepted = Data(data.prefix(remaining))
        humanContinuation.append(accepted)
        humanStructureBuilder.append(accepted)
        if humanContinuation.count >= checkpoint.horizonBytes {
            try complete()
        }
    }

    public mutating func completeCurrentHumanHorizon() throws {
        guard status == .collecting, !humanContinuation.isEmpty else { return }
        try complete()
    }

    public mutating func invalidate(_ reason: ExperimentInvalidationReason) {
        guard status == .collecting else { return }
        status = .invalidated
        invalidationReason = reason
    }

    public mutating func failModel() {
        guard status == .collecting else { return }
        status = .failed
        invalidationReason = .modelFailure
    }

    private mutating func complete() throws {
        comparison = try ContinuationComparator.compare(
            human: humanContinuation,
            model: modelContinuation,
            seed: checkpoint.contextSeed,
            humanConfiguration: checkpoint.indexConfiguration,
            modelConfiguration: checkpoint.indexConfiguration
        )
        status = .completed
    }
}

enum StableFingerprint {
    static func fnv1a64(_ data: Data) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}
