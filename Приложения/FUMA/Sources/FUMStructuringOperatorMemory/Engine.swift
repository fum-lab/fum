import Foundation

public struct StructuringOperatorEngine: Sendable {
  public init() {}

  public func run(scenarioID: String, in suite: ScenarioSuite) throws -> ScenarioReport {
    try ScenarioFixtureLoader.validate(suite)
    let scenario = try suite.scenario(id: scenarioID)
    try scenario.configuration.validate()
    let seeds = try suite.operators(ids: scenario.seedOperatorIds)
    let proposals = scenario.recordedLlm?.proposals ?? []
    guard seeds.count + proposals.count <= scenario.configuration.maxOperators else {
      throw OperatorMemoryError.invalidFixture("\(scenario.id): operator limit exceeded")
    }

    let residuals = buildResiduals(
      scenario: scenario,
      operators: seeds + proposals
    )
    let conflictBuild = buildConflicts(operators: seeds + proposals)

    var forest = BoundedContextForest(
      maxDepth: scenario.configuration.maxDepth,
      maxNodes: scenario.configuration.maxNodes
    )
    let trainingEvents =
      scenario.events.count > 1 ? Array(scenario.events.dropLast()) : scenario.events
    forest.ingest(events: trainingEvents)
    let predictionGain =
      scenario.events.count > 1
      ? forest.predictionGainMilliBits(for: scenario.events.last?.bytes ?? [])
      : 0
    if scenario.events.count > 1, let evaluation = scenario.events.last {
      forest.ingest(bytes: evaluation.bytes)
    }

    let discovered = forest.discoveredUnits(maxUnitBytes: scenario.configuration.maxUnitBytes)
    var candidateReports = evaluateCandidates(
      operators: seeds + proposals,
      discovered: discovered,
      scenario: scenario,
      residuals: residuals,
      conflicts: conflictBuild.conflicts,
      conflictLosers: conflictBuild.losers
    )
    let pruning = pruneCandidates(
      reports: &candidateReports,
      maximum: scenario.configuration.maxCandidates
    )

    let profilesByID = Dictionary(uniqueKeysWithValues: (seeds + proposals).map { ($0.id, $0) })
    let activeExplicit = candidateReports.compactMap { candidate -> OperatorProfile? in
      guard candidate.finalStatus == .confirmed else { return nil }
      return profilesByID[candidate.operatorID]
    }
    let activeDerivedIDs = Set(
      candidateReports.filter {
        $0.origin == .derived && $0.finalStatus == .confirmed
      }.map(\.operatorID)
    )
    let activeDiscovered = discovered.filter { activeDerivedIDs.contains($0.id) }

    let latticeResults = scenario.events.map { event in
      UnitLatticeBuilder.build(
        event: event,
        operators: activeExplicit,
        discoveredUnits: activeDiscovered,
        configuration: scenario.configuration
      )
    }
    let exactRoundTrip = zip(scenario.events, latticeResults).allSatisfy { event, result in
      event.bytes == result.reconstructedBytes
    }
    let rawBits = scenario.events.reduce(0) { $0 + $1.bytes.count * 8 }
    let groundedSemanticFacts = inferSemanticFacts(
      scenario: scenario,
      operators: activeExplicit
    )
    let inferredFacts = groundedSemanticFacts.map(\.fact)
    let semanticGeneration = makeSemanticGeneration(inferredFacts)
    let descriptionBits: Int
    if scenario.recoveryMode == .semantic, !inferredFacts.isEmpty {
      descriptionBits = inferredFacts.reduce(0) { partial, fact in
        partial + 8 + (fact.key.utf8.count + fact.value.utf8.count) * 2
      }
    } else {
      descriptionBits = latticeResults.reduce(0) { $0 + $1.descriptionBits }
    }
    let roundTripQuality =
      scenario.recoveryMode == .exact
      ? (exactRoundTrip ? 1_000_000 : 0)
      : semanticQuality(
        actual: inferredFacts,
        expected: scenario.expectedSemanticFacts
      )
    let rawPreservedByteCount = latticeResults.reduce(0) {
      $0 + $1.rawPreservedByteCount
    }
    let operatorGeneratedByteCount = latticeResults.reduce(0) {
      $0 + $1.operatorGeneratedByteCount
    }
    let metrics = ScenarioMetrics(
      predictionGainMilliBits: predictionGain,
      compressionGainBits: rawBits - descriptionBits,
      roundTripQualityPPM: roundTripQuality,
      exactRoundTrip: exactRoundTrip,
      operatorGenerationExact: latticeResults.allSatisfy(\.operatorGenerationExact),
      rawPreservedByteCount: rawPreservedByteCount,
      operatorGeneratedByteCount: operatorGeneratedByteCount,
      rawBits: rawBits,
      descriptionBits: descriptionBits
    )

    var graphEdges = scenario.graphEdges.map {
      OperatorEdgeRecord(
        id: $0.id,
        fromID: $0.fromId,
        toID: $0.toId,
        relation: $0.relation,
        provenance: $0.provenance
      )
    }
    graphEdges.append(
      contentsOf: conflictBuild.conflicts.map { conflict in
        OperatorEdgeRecord(
          id: "graph.\(conflict.id)",
          fromID: conflict.operatorIDs[0],
          toID: conflict.operatorIDs[1],
          relation: .conflicts,
          provenance: Provenance(
            initiator: "automation",
            executor: "deterministic-conflict-check",
            source: scenario.id,
            ordinal: 0
          )
        )
      })
    let graphPath = findGraphPath(
      expected: scenario.expectation.graphPath,
      edges: graphEdges
    )
    let explanations = try buildExplanations(scenario.semanticLinks)

    let confirmedAutomation = scenario.automation.flatMap { fixture -> AutomationFixture? in
      guard
        candidateReports.contains(where: {
          $0.operatorID == fixture.operatorId && $0.finalStatus == .confirmed
        })
      else { return nil }
      return fixture
    }
    let automationTrace = try confirmedAutomation.map(AutomationExecutor.run)
    if let automationTrace {
      graphEdges.append(
        OperatorEdgeRecord(
          id: "automation.verified.\(automationTrace.operatorID)",
          fromID: automationTrace.operatorID,
          toID: "trace:\(automationTrace.traceHash)",
          relation: .verifies,
          provenance: Provenance(
            initiator: "automation",
            executor: "pure-fixture-interpreter",
            source: scenario.id,
            ordinal: automationTrace.steps.count
          )
        )
      )
    }
    let synchronizationTrace = try scenario.synchronization.map(SynchronizationReducer.run)

    let sourceHashes = Dictionary(
      uniqueKeysWithValues: scenario.events.map { ($0.id, $0.sha256) }
    )
    let sourcesUnchanged = sourceHashes == scenario.expectedSourceHashes
    var provenance = scenario.events.map(\.provenance)
    let recordedTrace = scenario.recordedLlm.map {
      RecordedAdapterTrace(
        adapterID: $0.adapterId,
        model: $0.model,
        promptHash: $0.promptHash,
        responseHash: $0.responseHash,
        externalExecution: false
      )
    }
    if let envelope = scenario.recordedLlm {
      provenance.append(
        Provenance(
          initiator: "llm",
          executor: envelope.model,
          source: "recorded:\(envelope.responseHash)",
          ordinal: (provenance.map(\.ordinal).max() ?? 0) + 1
        )
      )
    }

    var appliedIDs = latticeResults.reduce(into: Set<String>()) {
      $0.formUnion($1.appliedOperatorIDs)
    }
    if let automationTrace {
      appliedIDs.insert(automationTrace.operatorID)
    }
    let candidateByID = Dictionary(
      uniqueKeysWithValues: candidateReports.map { ($0.operatorID, $0) })
    let allProfiles = Dictionary(uniqueKeysWithValues: (seeds + proposals).map { ($0.id, $0) })
    let appliedOperators = appliedIDs.sorted().compactMap { id -> AppliedOperator? in
      guard let profile = allProfiles[id], let candidate = candidateByID[id] else { return nil }
      return AppliedOperator(
        id: id,
        version: profile.version,
        origin: profile.origin,
        finalStatus: candidate.finalStatus
      )
    }

    let preliminary = ValidationInputs(
      metrics: metrics,
      residuals: residuals,
      candidates: candidateReports,
      pruning: PruningReport(
        prunedContextHex: forest.prunedContextHex,
        prunedCandidateIDs: pruning
      ),
      graphPath: graphPath,
      synchronizationTrace: synchronizationTrace,
      sourcesUnchanged: sourcesUnchanged
    )
    let violations = validate(expectation: scenario.expectation, inputs: preliminary)

    return ScenarioReport(
      schemaVersion: 1,
      scenarioID: scenario.id,
      scenarioKind: scenario.kind,
      fixtureResourceHash: sha256Digest(try canonicalJSONData(suite)),
      configurationHash: sha256Digest(try canonicalJSONData(scenario.configuration)),
      sourceHashes: sourceHashes,
      provenance: provenance.sorted(by: provenanceOrder),
      forest: forest.report(),
      lattices: latticeResults.map(\.report),
      candidates: candidateReports.sorted { $0.operatorID < $1.operatorID },
      metrics: metrics,
      residuals: residuals,
      conflicts: conflictBuild.conflicts,
      pruning: preliminary.pruning,
      graphEdges: graphEdges.sorted(by: edgeOrder),
      graphPath: graphPath,
      explanations: explanations,
      automationTrace: automationTrace,
      recordedAdapterTrace: recordedTrace,
      appliedOperators: appliedOperators,
      synchronizationTrace: synchronizationTrace,
      groundedSemanticFacts: groundedSemanticFacts,
      semanticGeneration: semanticGeneration,
      sourcesUnchanged: sourcesUnchanged,
      passed: violations.isEmpty && (automationTrace?.passed ?? true),
      violations: violations + ((automationTrace?.passed ?? true) ? [] : ["automation failed"])
    )
  }

  public func runAll(in suite: ScenarioSuite) throws -> [ScenarioReport] {
    try suite.scenarios.map { try run(scenarioID: $0.id, in: suite) }
  }
}

private struct ConflictBuild {
  let conflicts: [ConflictRecord]
  let losers: Set<String>
}

private struct ValidationInputs {
  let metrics: ScenarioMetrics
  let residuals: [DiagnosticResidual]
  let candidates: [OperatorCandidateReport]
  let pruning: PruningReport
  let graphPath: [String]
  let synchronizationTrace: SynchronizationTrace?
  let sourcesUnchanged: Bool
}

private func buildResiduals(
  scenario: ScenarioFixture,
  operators: [OperatorProfile]
) -> [DiagnosticResidual] {
  scenario.residualHints.enumerated().compactMap { index, hint in
    guard let event = scenario.events.first(where: { $0.id == hint.eventId }) else { return nil }
    let needle = Array(hint.needle.utf8)
    guard let offset = firstOffset(of: needle, in: event.bytes) else { return nil }
    let partial = operators.filter { profile in
      profile.negativeExamples.contains(where: {
        $0.contains(hint.needle) || event.text.contains($0)
      })
        || profile.recognitionPatterns.contains(where: {
          $0.contains(hint.needle) || hint.needle.contains($0)
        })
    }.map(\.id).sorted()
    return DiagnosticResidual(
      id: "residual.\(scenario.id).\(index + 1)",
      span: SourceSpan(eventID: event.id, byteOffset: offset, byteLength: needle.count),
      surface: hint.needle,
      category: hint.category,
      explanation: hint.explanation,
      partialOperatorIDs: partial,
      competingExplanations: ["ошибка входа", "кандидат нового оператора"]
    )
  }.sorted { $0.id < $1.id }
}

private func buildConflicts(operators: [OperatorProfile]) -> ConflictBuild {
  var groups: [String: [OperatorProfile]] = [:]
  for profile in operators {
    for pattern in profile.recognitionPatterns {
      groups[pattern, default: []].append(profile)
    }
  }
  var conflicts: [ConflictRecord] = []
  var losers = Set<String>()
  for pattern in groups.keys.sorted() {
    let profiles = groups[pattern, default: []]
    let semanticKeys = Set(profiles.map { $0.semanticKey ?? "" })
    guard profiles.count > 1, semanticKeys.count > 1 else { continue }
    let ordered = profiles.sorted { left, right in
      if left.confidencePpm != right.confidencePpm {
        return left.confidencePpm > right.confidencePpm
      }
      return left.id < right.id
    }
    guard let winner = ordered.first else { continue }
    losers.formUnion(ordered.dropFirst().map(\.id))
    conflicts.append(
      ConflictRecord(
        id: "conflict.\(conflicts.count + 1)",
        operatorIDs: ordered.map(\.id).sorted(),
        pattern: pattern,
        resolution: "higher_confidence:\(winner.id)"
      )
    )
  }
  return ConflictBuild(conflicts: conflicts, losers: losers)
}

private func evaluateCandidates(
  operators: [OperatorProfile],
  discovered: [DiscoveredUnit],
  scenario: ScenarioFixture,
  residuals: [DiagnosticResidual],
  conflicts: [ConflictRecord],
  conflictLosers: Set<String>
) -> [OperatorCandidateReport] {
  var reports: [OperatorCandidateReport] = []
  let residualSurfaces = residuals.map(\.surface)

  for profile in operators {
    let evidence = candidateEvidence(profile: profile, scenario: scenario)
    let support = evidence.support
    let conflictsForOperator = conflicts.filter { $0.operatorIDs.contains(profile.id) }.map(\.id)
    let rejectedByResidual = profile.recognitionPatterns.contains { pattern in
      residualSurfaces.contains { pattern.contains($0) || $0.contains(pattern) }
    }
    let rejectedByNegative = profile.negativeExamples.contains { example in
      scenario.events.contains { $0.text.contains(example) }
    }
    let generationIsReversible =
      profile.generationTemplate.map { template in
        !profile.recognitionPatterns.isEmpty
          && profile.recognitionPatterns.allSatisfy { $0 == template }
      } ?? false
    let reverseQuality = generationIsReversible ? 1_000_000 : 0
    let finalStatus: CandidateStatus
    let reason: String
    if profile.origin == .seed {
      finalStatus = .confirmed
      reason = "prevalidated seed"
    } else if rejectedByResidual || rejectedByNegative {
      finalStatus = .rejected
      reason = "negative evidence or probable input error"
    } else if conflictLosers.contains(profile.id) {
      finalStatus = .conflicting
      reason = "lower-confidence incompatible explanation"
    } else if support < scenario.configuration.minSupport {
      finalStatus = .lowConfidence
      reason = "support below threshold"
    } else if !generationIsReversible {
      finalStatus = .rejected
      reason = "candidate generation is not reversible"
    } else if evidence.compressionGainBits <= 0 && evidence.predictionGainMilliBits <= 0 {
      finalStatus = .rejected
      reason = "candidate has no positive compression or held-out prediction evidence"
    } else {
      finalStatus = .confirmed
      reason = "candidate-specific evidence and reversible generation passed"
    }
    let history =
      profile.status == finalStatus
      ? []
      : [StatusTransition(from: profile.status, to: finalStatus, reason: reason)]
    reports.append(
      OperatorCandidateReport(
        operatorID: profile.id,
        origin: profile.origin,
        initialStatus: profile.status,
        finalStatus: finalStatus,
        support: support,
        predictionGainMilliBits: evidence.predictionGainMilliBits,
        compressionGainBits: evidence.compressionGainBits,
        roundTripQualityPPM: reverseQuality,
        conflictIDs: conflictsForOperator.sorted(),
        history: history
      )
    )
  }

  for unit in discovered {
    let compression =
      unit.support * max(0, unit.bytes.count * 8 - scenario.configuration.referenceCostBits)
      - unit.bytes.count * 8
    let status: CandidateStatus =
      unit.support >= scenario.configuration.minSupport && compression > 0
      ? .confirmed : .lowConfidence
    reports.append(
      OperatorCandidateReport(
        operatorID: unit.id,
        origin: .derived,
        initialStatus: .hypothesis,
        finalStatus: status,
        support: unit.support,
        predictionGainMilliBits: derivedPredictionGain(unit: unit, scenario: scenario),
        compressionGainBits: compression,
        roundTripQualityPPM: 1_000_000,
        conflictIDs: [],
        history: [
          StatusTransition(
            from: .hypothesis,
            to: status,
            reason: status == .confirmed ? "bounded repeated unit" : "weak repeated unit"
          )
        ]
      )
    )
  }
  return reports
}

private struct CandidateEvidence {
  let support: Int
  let predictionGainMilliBits: Int
  let compressionGainBits: Int
}

private func candidateEvidence(
  profile: OperatorProfile,
  scenario: ScenarioFixture
) -> CandidateEvidence {
  let totalSupport = profile.recognitionPatterns.reduce(0) { partial, pattern in
    partial + scenario.events.reduce(0) { $0 + countOccurrences(pattern, in: $1.text) }
  }
  let compression =
    profile.recognitionPatterns.reduce(0) { partial, pattern in
      let occurrences = scenario.events.reduce(0) {
        $0 + countOccurrences(pattern, in: $1.text)
      }
      let savedPerOccurrence = max(
        0,
        pattern.utf8.count * 8 - scenario.configuration.referenceCostBits
      )
      return partial + occurrences * savedPerOccurrence
    } - profile.storageCostBits

  guard scenario.events.count > 1, let heldOut = scenario.events.last else {
    return CandidateEvidence(
      support: totalSupport,
      predictionGainMilliBits: 0,
      compressionGainBits: compression
    )
  }
  let training = scenario.events.dropLast()
  let prediction = profile.recognitionPatterns.reduce(0) { partial, pattern in
    let learned = training.contains { countOccurrences(pattern, in: $0.text) > 0 }
    guard learned else { return partial }
    let heldOutSupport = countOccurrences(pattern, in: heldOut.text)
    let savedBits = max(
      0,
      pattern.utf8.count * 8 - scenario.configuration.referenceCostBits
    )
    return partial + heldOutSupport * savedBits * 1_000
  }
  return CandidateEvidence(
    support: totalSupport,
    predictionGainMilliBits: prediction,
    compressionGainBits: compression
  )
}

private func derivedPredictionGain(
  unit: DiscoveredUnit,
  scenario: ScenarioFixture
) -> Int {
  guard scenario.events.count > 1, let heldOut = scenario.events.last else { return 0 }
  let learned = scenario.events.dropLast().contains {
    countOccurrences(unit.pattern, in: $0.text) > 0
  }
  guard learned else { return 0 }
  let savedBits = max(
    0,
    unit.bytes.count * 8 - scenario.configuration.referenceCostBits
  )
  return countOccurrences(unit.pattern, in: heldOut.text) * savedBits * 1_000
}

private func pruneCandidates(
  reports: inout [OperatorCandidateReport],
  maximum: Int
) -> [String] {
  let protected = reports.filter { $0.origin != .derived }
  let derived = reports.filter { $0.origin == .derived }.sorted(by: candidateUtilityOrder)
  let available = max(0, maximum - protected.count)
  let prunedIDs = derived.dropFirst(available).map(\.operatorID).sorted()
  let pruned = Set(prunedIDs)
  reports = reports.map { report in
    guard pruned.contains(report.operatorID) else { return report }
    return OperatorCandidateReport(
      operatorID: report.operatorID,
      origin: report.origin,
      initialStatus: report.initialStatus,
      finalStatus: .obsolete,
      support: report.support,
      predictionGainMilliBits: report.predictionGainMilliBits,
      compressionGainBits: report.compressionGainBits,
      roundTripQualityPPM: report.roundTripQualityPPM,
      conflictIDs: report.conflictIDs,
      history: report.history + [
        StatusTransition(
          from: report.finalStatus,
          to: .obsolete,
          reason: "deterministic candidate budget pruning"
        )
      ]
    )
  }
  return prunedIDs
}

private func candidateUtilityOrder(
  _ left: OperatorCandidateReport,
  _ right: OperatorCandidateReport
) -> Bool {
  let leftUtility = candidateUtilityScore(left)
  let rightUtility = candidateUtilityScore(right)
  if leftUtility != rightUtility { return leftUtility > rightUtility }
  return left.operatorID < right.operatorID
}

// Стабильная оценка pruning в битах: prediction переводится из миллибитов,
// support имеет вес 100 бит, а равенство разрешается по идентификатору оператора.
func candidateUtilityScore(_ candidate: OperatorCandidateReport) -> Int {
  candidate.compressionGainBits
    + max(0, candidate.predictionGainMilliBits) / 1_000
    + candidate.support * 100
}

private func inferSemanticFacts(
  scenario: ScenarioFixture,
  operators: [OperatorProfile]
) -> [GroundedSemanticFact] {
  let profiles = Dictionary(uniqueKeysWithValues: operators.map { ($0.id, $0) })
  var grounded: [GroundedSemanticFact] = []

  for event in scenario.events {
    for profile in operators.sorted(by: { $0.id < $1.id }) {
      for pattern in profile.recognitionPatterns.sorted() {
        let patternBytes = Array(pattern.utf8)
        for offset in allOffsets(of: patternBytes, in: event.bytes) {
          let semanticPaths = pathsToSemanticFacts(
            from: profile.id,
            profiles: profiles,
            edges: scenario.graphEdges
          )
          for path in semanticPaths {
            guard let semanticID = path.last,
              let semanticProfile = profiles[semanticID],
              let parsed = parseSemanticKey(semanticProfile.semanticKey)
            else { continue }
            grounded.append(
              GroundedSemanticFact(
                fact: SemanticFact(
                  key: parsed.key,
                  value: parsed.value,
                  language: semanticProfile.language,
                  sourceEventId: event.id
                ),
                span: SourceSpan(
                  eventID: event.id,
                  byteOffset: offset,
                  byteLength: patternBytes.count
                ),
                operatorIDs: path
              )
            )
          }
        }
      }
    }
  }

  let ordered = grounded.sorted { left, right in
    let leftKey = groundedIdentity(left)
    let rightKey = groundedIdentity(right)
    if leftKey != rightKey { return leftKey < rightKey }
    if left.operatorIDs.count != right.operatorIDs.count {
      return left.operatorIDs.count < right.operatorIDs.count
    }
    return left.operatorIDs.joined(separator: "\u{0}")
      < right.operatorIDs.joined(separator: "\u{0}")
  }
  var seen = Set<String>()
  return ordered.filter { seen.insert(groundedIdentity($0)).inserted }
}

private func pathsToSemanticFacts(
  from start: String,
  profiles: [String: OperatorProfile],
  edges: [GraphEdgeFixture]
) -> [[String]] {
  var queue: [[String]] = [[start]]
  var visited: Set<String> = [start]
  var results: [[String]] = []
  while !queue.isEmpty {
    let path = queue.removeFirst()
    guard let current = path.last, let profile = profiles[current] else { continue }
    if profile.stratum == .semantic, parseSemanticKey(profile.semanticKey) != nil {
      results.append(path)
      continue
    }
    let next = edges.filter {
      $0.fromId == current
        && [.abstracts, .composes, .specializes, .translatesVia].contains($0.relation)
    }.map(\.toId).sorted()
    for node in next where profiles[node] != nil && visited.insert(node).inserted {
      queue.append(path + [node])
    }
  }
  return results
}

private func parseSemanticKey(_ value: String?) -> (key: String, value: String)? {
  guard let value, let separator = value.firstIndex(of: "=") else { return nil }
  let key = String(value[..<separator])
  let semanticValue = String(value[value.index(after: separator)...])
  guard !key.isEmpty, !semanticValue.isEmpty else { return nil }
  return (key, semanticValue)
}

private func groundedIdentity(_ grounded: GroundedSemanticFact) -> String {
  "\(grounded.fact.sourceEventId)\u{0}\(factIdentity(grounded.fact))"
}

private func makeSemanticGeneration(_ facts: [SemanticFact]) -> String {
  facts.sorted { left, right in
    if left.key != right.key { return left.key < right.key }
    if left.value != right.value { return left.value < right.value }
    return left.sourceEventId < right.sourceEventId
  }.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
}

private func semanticQuality(actual: [SemanticFact], expected: [SemanticFact]) -> Int {
  guard !actual.isEmpty || !expected.isEmpty else { return 1_000_000 }
  var available = actual.map(factIdentity)
  var matches = 0
  for identity in expected.map(factIdentity) {
    if let index = available.firstIndex(of: identity) {
      matches += 1
      available.remove(at: index)
    }
  }
  return 2 * matches * 1_000_000 / (actual.count + expected.count)
}

private func factIdentity(_ fact: SemanticFact) -> String {
  "\(fact.key)\u{0}\(fact.value)\u{0}\(fact.language ?? "")\u{0}\(fact.sourceEventId)"
}

private func findGraphPath(
  expected: [String],
  edges: [OperatorEdgeRecord]
) -> [String] {
  guard let start = expected.first, let target = expected.last else { return [] }
  var queue: [[String]] = [[start]]
  var visited: Set<String> = [start]
  while !queue.isEmpty {
    let path = queue.removeFirst()
    guard let current = path.last else { continue }
    if current == target { return path }
    let next = edges.filter { $0.fromID == current }.map(\.toID).sorted()
    for node in next where visited.insert(node).inserted {
      queue.append(path + [node])
    }
  }
  return []
}

private struct LinkView: Codable {
  let confidencePPM: Int
  let linkID: String
  let operatorID: String
  let sourceEventID: String
  let status: CandidateStatus
  let targetEventID: String
}

private func buildExplanations(_ links: [SemanticLinkFixture]) throws -> [ExplanationRecord] {
  try links.map { link in
    let view = LinkView(
      confidencePPM: link.confidencePpm,
      linkID: link.id,
      operatorID: link.operatorId,
      sourceEventID: link.sourceEventId,
      status: link.status,
      targetEventID: link.targetEventId
    )
    guard let llmView = String(data: try canonicalJSONData(view), encoding: .utf8) else {
      throw OperatorMemoryError.invalidFixture("invalid explanation encoding")
    }
    return ExplanationRecord(
      id: link.id,
      operatorID: link.operatorId,
      sourceEventID: link.sourceEventId,
      targetEventID: link.targetEventId,
      status: link.status,
      confidencePPM: link.confidencePpm,
      humanView:
        "\(link.status.rawValue): \(link.sourceEventId) → \(link.targetEventId) через \(link.operatorId)",
      llmView: llmView,
      counterexample: link.counterexample
    )
  }.sorted { $0.id < $1.id }
}

private func validate(
  expectation: ScenarioExpectation,
  inputs: ValidationInputs
) -> [String] {
  var violations: [String] = []
  if let expected = expectation.exactRoundTrip,
    inputs.metrics.exactRoundTrip != expected
  {
    violations.append("exact round-trip mismatch")
  }
  if let expected = expectation.positivePredictionGain,
    (inputs.metrics.predictionGainMilliBits > 0) != expected
  {
    violations.append("prediction gain mismatch")
  }
  if let expected = expectation.positiveCompressionGain,
    (inputs.metrics.compressionGainBits > 0) != expected
  {
    violations.append("compression gain mismatch")
  }
  if let expected = expectation.semanticQualityPpm,
    inputs.metrics.roundTripQualityPPM != expected
  {
    violations.append("semantic round-trip mismatch")
  }
  let residualCategories = Set(inputs.residuals.map(\.category))
  for category in expectation.residualCategories where !residualCategories.contains(category) {
    violations.append("missing residual \(category.rawValue)")
  }
  for (id, status) in expectation.candidateStatuses.sorted(by: { $0.key < $1.key }) {
    if inputs.candidates.first(where: { $0.operatorID == id })?.finalStatus != status {
      violations.append("candidate status mismatch: \(id)")
    }
  }
  if !expectation.graphPath.isEmpty, inputs.graphPath != expectation.graphPath {
    violations.append("graph path mismatch")
  }
  if inputs.pruning.prunedContextHex.count < expectation.minimumPrunedContexts {
    violations.append("insufficient context pruning")
  }
  if inputs.pruning.prunedCandidateIDs.count < expectation.minimumPrunedCandidates {
    violations.append("insufficient candidate pruning")
  }
  if let expected = expectation.actionExecuted,
    inputs.synchronizationTrace?.actionExecuted != expected
  {
    violations.append("joint action mismatch")
  }
  if expectation.llmBackedRequired,
    inputs.synchronizationTrace?.containsLLMBackedNode != true
  {
    violations.append("LLM-backed node missing")
  }
  if expectation.sourceUnchanged != inputs.sourcesUnchanged {
    violations.append("source mutation mismatch")
  }
  return violations
}

private func countOccurrences(_ needle: String, in haystack: String) -> Int {
  guard !needle.isEmpty else { return 0 }
  var count = 0
  var searchRange = haystack.startIndex..<haystack.endIndex
  while let range = haystack.range(of: needle, range: searchRange) {
    count += 1
    searchRange = range.upperBound..<haystack.endIndex
  }
  return count
}

private func firstOffset(of needle: [UInt8], in bytes: [UInt8]) -> Int? {
  guard !needle.isEmpty, needle.count <= bytes.count else { return nil }
  for offset in 0...(bytes.count - needle.count) {
    if Array(bytes[offset..<(offset + needle.count)]) == needle { return offset }
  }
  return nil
}

private func allOffsets(of needle: [UInt8], in bytes: [UInt8]) -> [Int] {
  guard !needle.isEmpty, needle.count <= bytes.count else { return [] }
  return (0...(bytes.count - needle.count)).filter { offset in
    Array(bytes[offset..<(offset + needle.count)]) == needle
  }
}

private func provenanceOrder(_ left: Provenance, _ right: Provenance) -> Bool {
  if left.ordinal != right.ordinal { return left.ordinal < right.ordinal }
  if left.initiator != right.initiator { return left.initiator < right.initiator }
  return left.source < right.source
}

private func edgeOrder(_ left: OperatorEdgeRecord, _ right: OperatorEdgeRecord) -> Bool {
  if left.fromID != right.fromID { return left.fromID < right.fromID }
  if left.toID != right.toID { return left.toID < right.toID }
  return left.id < right.id
}
