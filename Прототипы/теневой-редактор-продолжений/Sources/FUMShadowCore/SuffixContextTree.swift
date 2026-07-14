import Foundation

public struct SuffixIndexConfiguration: Codable, Equatable, Sendable {
    public let maxDepth: Int
    public let maxNodes: Int

    public init(maxDepth: Int, maxNodes: Int) {
        precondition(maxDepth > 0, "maxDepth must be positive")
        precondition(maxNodes > 0, "maxNodes must be positive")
        self.maxDepth = maxDepth
        self.maxNodes = maxNodes
    }
}

public struct SuffixIndexSummary: Codable, Equatable, Sendable {
    public let processedBytes: Int
    public let nodeCount: Int
    public let skippedNodeCreations: Int

    public init(processedBytes: Int, nodeCount: Int, skippedNodeCreations: Int) {
        self.processedBytes = processedBytes
        self.nodeCount = nodeCount
        self.skippedNodeCreations = skippedNodeCreations
    }
}

public struct ContextTransition: Codable, Hashable, Sendable {
    public let context: Data
    public let nextByte: UInt8

    public init(context: Data, nextByte: UInt8) {
        self.context = context
        self.nextByte = nextByte
    }
}

/// A bounded trie of exact suffix contexts.
///
/// Paths are stored in reverse byte order so appending one UTF-8 byte updates
/// every suffix context in O(maxDepth). Each node stores the observed
/// distribution of the next byte after that context.
public struct BoundedSuffixContextTree: Sendable {
    private struct Node: Sendable {
        var children: [UInt8: Int] = [:]
        var nextByteCounts: [UInt8: Int] = [:]
    }

    public let configuration: SuffixIndexConfiguration
    private var nodes: [Node] = [Node()]
    private var recentBytes: [UInt8] = []
    private var processedBytes = 0
    private var skippedNodeCreations = 0

    public init(configuration: SuffixIndexConfiguration) {
        self.configuration = configuration
        recentBytes.reserveCapacity(configuration.maxDepth)
    }

    public init(data: Data, configuration: SuffixIndexConfiguration) {
        self.init(configuration: configuration)
        append(data)
    }

    /// Builds an index while periodically invoking a caller-supplied
    /// cancellation check. No partially built tree is returned when the check
    /// throws.
    public static func buildCancellable(
        data: Data,
        configuration: SuffixIndexConfiguration,
        cancellationCheckInterval: Int = 512,
        checkCancellation: () throws -> Void = { try Task.checkCancellation() }
    ) throws -> Self {
        precondition(
            cancellationCheckInterval > 0,
            "cancellationCheckInterval must be positive"
        )

        var tree = Self(configuration: configuration)
        try checkCancellation()
        for (offset, byte) in data.enumerated() {
            if offset > 0, offset.isMultiple(of: cancellationCheckInterval) {
                try checkCancellation()
            }
            tree.append(byte)
        }
        try checkCancellation()
        return tree
    }

    public var summary: SuffixIndexSummary {
        SuffixIndexSummary(
            processedBytes: processedBytes,
            nodeCount: nodes.count,
            skippedNodeCreations: skippedNodeCreations
        )
    }

    public mutating func append(_ data: Data) {
        for nextByte in data {
            append(nextByte)
        }
    }

    public func nextByteCount(context: Data, nextByte: UInt8) -> Int {
        var nodeIndex = 0
        for byte in context.suffix(configuration.maxDepth).reversed() {
            guard let child = nodes[nodeIndex].children[byte] else {
                return 0
            }
            nodeIndex = child
        }
        return nodes[nodeIndex].nextByteCounts[nextByte, default: 0]
    }

    public func transitionCounts() -> [ContextTransition: Int] {
        var result: [ContextTransition: Int] = [:]
        collectTransitions(nodeIndex: 0, reversePath: [], result: &result)
        return result
    }

    private func collectTransitions(
        nodeIndex: Int,
        reversePath: [UInt8],
        result: inout [ContextTransition: Int]
    ) {
        let context = Data(reversePath.reversed())
        for (nextByte, count) in nodes[nodeIndex].nextByteCounts {
            result[ContextTransition(context: context, nextByte: nextByte)] = count
        }

        for (byte, childIndex) in nodes[nodeIndex].children {
            collectTransitions(
                nodeIndex: childIndex,
                reversePath: reversePath + [byte],
                result: &result
            )
        }
    }

    private mutating func append(_ nextByte: UInt8) {
        nodes[0].nextByteCounts[nextByte, default: 0] += 1

        var nodeIndex = 0
        for contextByte in recentBytes.reversed().prefix(configuration.maxDepth) {
            let childIndex: Int
            if let existing = nodes[nodeIndex].children[contextByte] {
                childIndex = existing
            } else if nodes.count < configuration.maxNodes {
                childIndex = nodes.count
                nodes.append(Node())
                nodes[nodeIndex].children[contextByte] = childIndex
            } else {
                skippedNodeCreations += 1
                break
            }

            nodes[childIndex].nextByteCounts[nextByte, default: 0] += 1
            nodeIndex = childIndex
        }

        recentBytes.append(nextByte)
        if recentBytes.count > configuration.maxDepth {
            recentBytes.removeFirst(recentBytes.count - configuration.maxDepth)
        }
        processedBytes += 1
    }
}
