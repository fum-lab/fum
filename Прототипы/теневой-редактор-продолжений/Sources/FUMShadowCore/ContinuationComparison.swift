import Foundation

public struct ContinuationStructure: Codable, Equatable, Sendable {
    public let configuration: SuffixIndexConfiguration
    public let continuationByteCount: Int
    public let transitionCounts: [ContextTransition: Int]
    public let skippedNodeCreations: Int

    public init(
        seed: Data,
        continuation: Data,
        configuration: SuffixIndexConfiguration
    ) {
        var builder = ContinuationStructureBuilder(seed: seed, configuration: configuration)
        builder.append(continuation)
        self = builder.structure
    }
}

public struct ContinuationStructureBuilder: Sendable {
    public let configuration: SuffixIndexConfiguration
    private var recentBytes: [UInt8]
    private var knownContexts: Set<Data> = [Data()]
    private var counts: [ContextTransition: Int] = [:]
    private var continuationByteCount = 0
    private var skippedNodeCreations = 0

    public init(seed: Data, configuration: SuffixIndexConfiguration) {
        self.configuration = configuration
        self.recentBytes = Array(seed.suffix(configuration.maxDepth))
    }

    public var structure: ContinuationStructure {
        ContinuationStructure(
            configuration: configuration,
            continuationByteCount: continuationByteCount,
            transitionCounts: counts,
            skippedNodeCreations: skippedNodeCreations
        )
    }

    public mutating func append(_ data: Data) {
        for nextByte in data {
            record(context: Data(), nextByte: nextByte)

            let availableDepth = min(configuration.maxDepth, recentBytes.count)
            if availableDepth > 0 {
                for depth in 1...availableDepth {
                    let context = Data(recentBytes.suffix(depth))
                    if !knownContexts.contains(context) {
                        guard knownContexts.count < configuration.maxNodes else {
                            skippedNodeCreations += 1
                            break
                        }
                        knownContexts.insert(context)
                    }
                    record(context: context, nextByte: nextByte)
                }
            }

            recentBytes.append(nextByte)
            if recentBytes.count > configuration.maxDepth {
                recentBytes.removeFirst(recentBytes.count - configuration.maxDepth)
            }
            continuationByteCount += 1
        }
    }

    private mutating func record(context: Data, nextByte: UInt8) {
        let transition = ContextTransition(context: context, nextByte: nextByte)
        counts[transition, default: 0] += 1
    }
}

private extension ContinuationStructure {
    init(
        configuration: SuffixIndexConfiguration,
        continuationByteCount: Int,
        transitionCounts: [ContextTransition: Int],
        skippedNodeCreations: Int
    ) {
        self.configuration = configuration
        self.continuationByteCount = continuationByteCount
        self.transitionCounts = transitionCounts
        self.skippedNodeCreations = skippedNodeCreations
    }
}

public enum ContinuationComparisonError: Error, Equatable, Sendable {
    case configurationMismatch
}

public struct ContinuationMetrics: Codable, Equatable, Sendable {
    public let humanBytes: Int
    public let modelBytes: Int
    public let commonPrefixBytes: Int
    public let editDistanceBytes: Int
    public let normalizedEditDistance: Double
    public let sharedTransitionWeight: Int
    public let humanOnlyTransitionWeight: Int
    public let modelOnlyTransitionWeight: Int
    public let weightedJaccardSimilarity: Double
}

public enum ContinuationComparator {
    public static func compare(
        human: Data,
        model: Data,
        seed: Data,
        humanConfiguration: SuffixIndexConfiguration,
        modelConfiguration: SuffixIndexConfiguration
    ) throws -> ContinuationMetrics {
        guard humanConfiguration == modelConfiguration else {
            throw ContinuationComparisonError.configurationMismatch
        }

        let humanStructure = ContinuationStructure(
            seed: seed,
            continuation: human,
            configuration: humanConfiguration
        )
        let modelStructure = ContinuationStructure(
            seed: seed,
            continuation: model,
            configuration: modelConfiguration
        )
        let humanCounts = humanStructure.transitionCounts
        let modelCounts = modelStructure.transitionCounts
        let keys = Set(humanCounts.keys).union(modelCounts.keys)
        var sharedWeight = 0
        var humanOnlyWeight = 0
        var modelOnlyWeight = 0
        var unionWeight = 0

        for key in keys {
            let humanCount = humanCounts[key, default: 0]
            let modelCount = modelCounts[key, default: 0]
            sharedWeight += min(humanCount, modelCount)
            humanOnlyWeight += max(humanCount - modelCount, 0)
            modelOnlyWeight += max(modelCount - humanCount, 0)
            unionWeight += max(humanCount, modelCount)
        }

        let humanBytes = Array(human)
        let modelBytes = Array(model)
        let editDistance = levenshteinDistance(humanBytes, modelBytes)
        let maximumLength = max(humanBytes.count, modelBytes.count)

        return ContinuationMetrics(
            humanBytes: humanBytes.count,
            modelBytes: modelBytes.count,
            commonPrefixBytes: commonPrefixLength(humanBytes, modelBytes),
            editDistanceBytes: editDistance,
            normalizedEditDistance: maximumLength == 0
                ? 0
                : Double(editDistance) / Double(maximumLength),
            sharedTransitionWeight: sharedWeight,
            humanOnlyTransitionWeight: humanOnlyWeight,
            modelOnlyTransitionWeight: modelOnlyWeight,
            weightedJaccardSimilarity: unionWeight == 0
                ? 1
                : Double(sharedWeight) / Double(unionWeight)
        )
    }

    private static func commonPrefixLength(_ left: [UInt8], _ right: [UInt8]) -> Int {
        var index = 0
        while index < left.count, index < right.count, left[index] == right[index] {
            index += 1
        }
        return index
    }

    private static func levenshteinDistance(_ left: [UInt8], _ right: [UInt8]) -> Int {
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        for (leftOffset, leftByte) in left.enumerated() {
            var current = Array(repeating: 0, count: right.count + 1)
            current[0] = leftOffset + 1
            for (rightOffset, rightByte) in right.enumerated() {
                let substitution = previous[rightOffset] + (leftByte == rightByte ? 0 : 1)
                let deletion = previous[rightOffset + 1] + 1
                let insertion = current[rightOffset] + 1
                current[rightOffset + 1] = min(substitution, deletion, insertion)
            }
            previous = current
        }
        return previous[right.count]
    }
}
