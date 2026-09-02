import Foundation

struct DiscoveredUnit: Equatable, Sendable {
  let id: String
  let pattern: String
  let bytes: [UInt8]
  let support: Int
}

struct BoundedContextForest: Sendable {
  private struct Node: Sendable {
    let context: [UInt8]
    var nextCounts: [UInt8: Int]
    var support: Int
  }

  let maxDepth: Int
  let maxNodes: Int
  private var nodes: [String: Node] = [:]
  private var rootCounts: [UInt8: Int] = [:]
  private(set) var processedBytes = 0
  private(set) var prunedContextHex: [String] = []

  init(maxDepth: Int, maxNodes: Int) {
    self.maxDepth = maxDepth
    self.maxNodes = maxNodes
    nodes.reserveCapacity(maxNodes)
    prunedContextHex.reserveCapacity(maxNodes)
  }

  mutating func ingest(events: [StreamEvent]) {
    for event in events {
      ingest(bytes: event.bytes)
    }
  }

  mutating func ingest(bytes: [UInt8]) {
    var history: [UInt8] = []
    history.reserveCapacity(maxDepth)
    for nextByte in bytes {
      rootCounts[nextByte, default: 0] += 1
      let usableDepth = min(maxDepth, history.count)
      if usableDepth > 0 {
        for depth in 1...usableDepth {
          let context = Array(history.suffix(depth))
          observe(context: context, nextByte: nextByte)
        }
      }
      history.append(nextByte)
      if history.count > maxDepth {
        history.removeFirst(history.count - maxDepth)
      }
      processedBytes += 1
    }
  }

  func predictionGainMilliBits(for bytes: [UInt8]) -> Int {
    guard !rootCounts.isEmpty else { return 0 }
    var history: [UInt8] = []
    history.reserveCapacity(maxDepth)
    var gain = 0.0

    for nextByte in bytes {
      let baseline = probability(nextByte: nextByte, counts: rootCounts)
      let context = deepestNode(for: history)
      let predicted =
        context.map { probability(nextByte: nextByte, counts: $0.nextCounts) }
        ?? baseline
      gain += log2(
        max(predicted, Double.leastNonzeroMagnitude) / max(baseline, Double.leastNonzeroMagnitude))

      history.append(nextByte)
      if history.count > maxDepth {
        history.removeFirst(history.count - maxDepth)
      }
    }
    return Int((gain * 1_000).rounded())
  }

  func discoveredUnits(maxUnitBytes: Int) -> [DiscoveredUnit] {
    nodes.values
      .filter {
        $0.support >= 2 && $0.context.count >= 2 && $0.context.count <= maxUnitBytes
      }
      .map { node in
        let pattern = String(decoding: node.context, as: UTF8.self)
        let contextHex = hexString(node.context)
        return DiscoveredUnit(
          id: "unit.\(contextHex)",
          pattern: pattern,
          bytes: node.context,
          support: node.support
        )
      }
      .sorted { $0.id < $1.id }
  }

  func report() -> ContextForestReport {
    let reports = nodes.values.map { node in
      let scores = node.nextCounts
        .map { (String(format: "%03d", $0.key), $0.value) }
      let probabilities = normalizedScores(scores)
      let continuations = node.nextCounts.keys.sorted().map { byte in
        NextProbability(
          byte: byte,
          count: node.nextCounts[byte, default: 0],
          probabilityPPM: probabilities[String(format: "%03d", byte), default: 0]
        )
      }
      return ContextNodeReport(
        contextHex: hexString(node.context),
        depth: node.context.count,
        support: node.support,
        continuations: continuations
      )
    }.sorted { $0.contextHex < $1.contextHex }

    return ContextForestReport(
      processedBytes: processedBytes,
      nodeCount: reports.count,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      nodes: reports
    )
  }

  private mutating func observe(context: [UInt8], nextByte: UInt8) {
    let key = hexString(context)
    if var node = nodes[key] {
      node.nextCounts[nextByte, default: 0] += 1
      node.support += 1
      nodes[key] = node
      return
    }

    guard nodes.count < maxNodes else {
      if prunedContextHex.count < maxNodes, !prunedContextHex.contains(key) {
        prunedContextHex.append(key)
        prunedContextHex.sort()
      }
      return
    }
    nodes[key] = Node(context: context, nextCounts: [nextByte: 1], support: 1)
  }

  private func deepestNode(for history: [UInt8]) -> Node? {
    let usableDepth = min(maxDepth, history.count)
    guard usableDepth > 0 else { return nil }
    for depth in stride(from: usableDepth, through: 1, by: -1) {
      let key = hexString(history.suffix(depth))
      if let node = nodes[key] {
        return node
      }
    }
    return nil
  }

  private func probability(nextByte: UInt8, counts: [UInt8: Int]) -> Double {
    let vocabulary = max(2, counts.count + (counts[nextByte] == nil ? 1 : 0))
    let total = counts.values.reduce(0, +)
    return Double(counts[nextByte, default: 0] + 1) / Double(total + vocabulary)
  }
}

struct LatticeBuildResult: Sendable {
  let report: LatticeReport
  let reconstructedBytes: [UInt8]
  let descriptionBits: Int
  let appliedOperatorIDs: Set<String>
  let rawPreservedByteCount: Int
  let operatorGeneratedByteCount: Int
  let operatorGenerationExact: Bool
}

enum UnitLatticeBuilder {
  private struct Pattern: Sendable {
    let id: String
    let bytes: [UInt8]
    let generatedBytes: [UInt8]
    let origin: OperatorOrigin
    let rawScore: Int
  }

  private struct Path: Sendable {
    let logProbability: Double
    let unitCount: Int
    let signature: String
    let units: [UnitCandidateRecord]
  }

  static func build(
    event: StreamEvent,
    operators: [OperatorProfile],
    discoveredUnits: [DiscoveredUnit],
    configuration: EngineConfiguration
  ) -> LatticeBuildResult {
    let bytes = event.bytes
    let patterns = makePatterns(
      operators: operators,
      discoveredUnits: discoveredUnits,
      maxUnitBytes: configuration.maxUnitBytes
    )
    var candidatesByOffset: [[UnitCandidateRecord]] = Array(repeating: [], count: bytes.count)

    for offset in bytes.indices {
      var rawCandidates:
        [(String, Int, Int, String?, OperatorOrigin, String, String, ReconstructionKind)] = []
      let fallbackHex = hexString([bytes[offset]])
      rawCandidates.append(
        (
          "raw-byte.\(fallbackHex)", 1, 1, nil, .derived, fallbackHex, fallbackHex,
          .rawPreserved
        )
      )

      for pattern in patterns where pattern.bytes.count <= bytes.count - offset {
        let end = offset + pattern.bytes.count
        guard Array(bytes[offset..<end]) == pattern.bytes else { continue }
        rawCandidates.append(
          (
            pattern.id,
            pattern.bytes.count,
            pattern.rawScore,
            pattern.id,
            pattern.origin,
            hexString(pattern.bytes),
            hexString(pattern.generatedBytes),
            .operatorGenerated
          )
        )
      }

      rawCandidates.sort { left, right in
        if left.2 != right.2 { return left.2 > right.2 }
        if left.1 != right.1 { return left.1 > right.1 }
        return left.0 < right.0
      }
      let fallback = rawCandidates.first { $0.3 == nil }
      var limited = Array(rawCandidates.prefix(configuration.maxLatticeCandidatesPerOffset))
      if !limited.contains(where: { $0.3 == nil }), let fallback {
        if !limited.isEmpty { limited.removeLast() }
        limited.append(fallback)
      }
      limited.sort { $0.0 < $1.0 }

      let probabilities = normalizedScores(limited.map { ($0.0, $0.2) })
      candidatesByOffset[offset] = limited.map { item in
        UnitCandidateRecord(
          start: offset,
          length: item.1,
          operatorID: item.3,
          origin: item.4,
          probabilityPPM: probabilities[item.0, default: 0],
          rawScore: item.2,
          bytesHex: item.6,
          sourceBytesHex: item.5,
          generatedBytesHex: item.6,
          reconstructionKind: item.7
        )
      }.sorted(by: candidateOrder)
    }

    let selected = selectPath(candidatesByOffset: candidatesByOffset, byteCount: bytes.count)
    let reconstructed = selected.flatMap { bytesFromHex($0.generatedBytesHex) ?? [] }
    let cost = selected.reduce(0) { partial, unit in
      partial + (unit.operatorID == nil ? unit.length * 8 : configuration.referenceCostBits)
    }
    let applied = Set(selected.compactMap(\.operatorID))
    let rawPreservedByteCount = selected.filter {
      $0.reconstructionKind == .rawPreserved
    }.reduce(0) { $0 + $1.length }
    let operatorGeneratedByteCount = selected.filter {
      $0.reconstructionKind == .operatorGenerated
    }.reduce(0) { $0 + $1.length }
    let operatorGenerationExact = selected.filter {
      $0.reconstructionKind == .operatorGenerated
    }.allSatisfy { $0.sourceBytesHex == $0.generatedBytesHex }
    return LatticeBuildResult(
      report: LatticeReport(
        eventID: event.id,
        byteCount: bytes.count,
        candidates: candidatesByOffset.flatMap { $0 },
        selectedUnits: selected
      ),
      reconstructedBytes: reconstructed,
      descriptionBits: cost,
      appliedOperatorIDs: applied,
      rawPreservedByteCount: rawPreservedByteCount,
      operatorGeneratedByteCount: operatorGeneratedByteCount,
      operatorGenerationExact: operatorGenerationExact
    )
  }

  private static func makePatterns(
    operators: [OperatorProfile],
    discoveredUnits: [DiscoveredUnit],
    maxUnitBytes: Int
  ) -> [Pattern] {
    var result: [Pattern] = []
    for profile in operators.sorted(by: { $0.id < $1.id }) {
      for pattern in profile.recognitionPatterns.sorted() {
        let bytes = Array(pattern.utf8)
        guard !bytes.isEmpty, bytes.count <= maxUnitBytes else { continue }
        result.append(
          Pattern(
            id: profile.id,
            bytes: bytes,
            generatedBytes: profile.generationTemplate.map { Array($0.utf8) } ?? [],
            origin: profile.origin,
            rawScore: max(2, profile.confidencePpm / 1_000 + bytes.count * 4)
          )
        )
      }
    }
    for unit in discoveredUnits where unit.bytes.count <= maxUnitBytes {
      result.append(
        Pattern(
          id: unit.id,
          bytes: unit.bytes,
          generatedBytes: unit.bytes,
          origin: .derived,
          rawScore: max(2, unit.support * 20 + unit.bytes.count)
        )
      )
    }
    return result.sorted { left, right in
      if left.id != right.id { return left.id < right.id }
      return hexString(left.bytes) < hexString(right.bytes)
    }
  }

  private static func selectPath(
    candidatesByOffset: [[UnitCandidateRecord]],
    byteCount: Int
  ) -> [UnitCandidateRecord] {
    guard byteCount > 0 else { return [] }
    var paths: [Path?] = Array(repeating: nil, count: byteCount + 1)
    paths[byteCount] = Path(logProbability: 0, unitCount: 0, signature: "", units: [])

    for offset in stride(from: byteCount - 1, through: 0, by: -1) {
      var best: Path?
      for candidate in candidatesByOffset[offset] {
        let nextOffset = offset + candidate.length
        guard nextOffset <= byteCount, let suffix = paths[nextOffset] else { continue }
        let probability = max(1, candidate.probabilityPPM)
        let label = candidate.operatorID ?? "raw-byte.\(candidate.bytesHex)"
        let path = Path(
          logProbability: log(Double(probability) / 1_000_000) + suffix.logProbability,
          unitCount: suffix.unitCount + 1,
          signature: label + "|" + suffix.signature,
          units: [candidate] + suffix.units
        )
        if isBetter(path, than: best) {
          best = path
        }
      }
      paths[offset] = best
    }
    return paths[0]?.units ?? []
  }

  private static func isBetter(_ candidate: Path, than current: Path?) -> Bool {
    guard let current else { return true }
    let delta = candidate.logProbability - current.logProbability
    if abs(delta) > 0.000_000_001 { return delta > 0 }
    if candidate.unitCount != current.unitCount { return candidate.unitCount < current.unitCount }
    return candidate.signature < current.signature
  }

  private static func candidateOrder(
    _ left: UnitCandidateRecord,
    _ right: UnitCandidateRecord
  ) -> Bool {
    if left.start != right.start { return left.start < right.start }
    if left.length != right.length { return left.length > right.length }
    return (left.operatorID ?? "") < (right.operatorID ?? "")
  }
}

func normalizedScores(_ entries: [(String, Int)]) -> [String: Int] {
  guard !entries.isEmpty else { return [:] }
  let nonnegative = entries.map { ($0.0, max(1, $0.1)) }
  let total = nonnegative.reduce(0) { $0 + $1.1 }
  var result: [String: Int] = [:]
  result.reserveCapacity(nonnegative.count)
  for (key, score) in nonnegative {
    result[key] = score * 1_000_000 / total
  }
  var remainder = 1_000_000 - result.values.reduce(0, +)
  for key in nonnegative.map(\.0).sorted() where remainder > 0 {
    result[key, default: 0] += 1
    remainder -= 1
  }
  return result
}
