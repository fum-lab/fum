import Foundation

private let reservedExplicitOperatorIDPrefixes = ["unit."]

public enum ScenarioFixtureLoader {
  private static let maximumSuiteBytes = 1_000_000
  private static let maximumEnvelopeBytes = 262_144

  public static func loadBundledSuite() throws -> ScenarioSuite {
    let data = try loadBundledResource(
      name: "scenarios",
      extension: "json",
      maximumBytes: maximumSuiteBytes
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let suite = try decoder.decode(ScenarioSuite.self, from: data)
    try validate(suite)
    return suite
  }

  public static func loadBundledMalformedEnvelope() throws -> Data {
    try loadBundledResource(
      name: "malformed-llm-envelope",
      extension: "json",
      maximumBytes: maximumEnvelopeBytes
    )
  }

  private static func loadBundledResource(
    name: String,
    extension fileExtension: String,
    maximumBytes: Int
  ) throws -> Data {
    let url =
      Bundle.module.url(
        forResource: name,
        withExtension: fileExtension,
        subdirectory: "Фикстуры"
      ) ?? Bundle.module.url(forResource: name, withExtension: fileExtension)
    guard let url else {
      throw OperatorMemoryError.missingResource("\(name).\(fileExtension)")
    }

    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    guard let size = values.fileSize, size <= maximumBytes else {
      throw OperatorMemoryError.resourceTooLarge(values.fileSize ?? -1)
    }
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard data.count <= maximumBytes else {
      throw OperatorMemoryError.resourceTooLarge(data.count)
    }
    return data
  }

  static func validate(_ suite: ScenarioSuite) throws {
    guard suite.schemaVersion == 1 else {
      throw OperatorMemoryError.unsupportedSchema(suite.schemaVersion)
    }
    guard suite.operatorCatalog.count <= 256 else {
      throw OperatorMemoryError.invalidFixture("operator catalog exceeds 256 entries")
    }
    guard suite.scenarios.count <= 64 else {
      throw OperatorMemoryError.invalidFixture("scenario catalog exceeds 64 entries")
    }

    try requireUnique(suite.operatorCatalog.map(\.id), label: "operator id")
    try requireUnique(suite.scenarios.map(\.id), label: "scenario id")
    let operatorIDs = Set(suite.operatorCatalog.map(\.id))

    for profile in suite.operatorCatalog {
      try validate(profile)
    }
    let catalogByID = Dictionary(uniqueKeysWithValues: suite.operatorCatalog.map { ($0.id, $0) })
    for scenario in suite.scenarios {
      try scenario.configuration.validate()
      guard scenario.events.count <= scenario.configuration.maxEvents else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): too many events")
      }
      guard scenario.seedOperatorIds.count <= scenario.configuration.maxOperators else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): too many seed operators")
      }
      try requireUnique(scenario.seedOperatorIds, label: "\(scenario.id) seed operator id")
      guard scenario.seedOperatorIds.allSatisfy(operatorIDs.contains) else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): missing seed operator")
      }
      if scenario.expectation.llmBackedRequired, scenario.recordedLlm == nil {
        throw OperatorMemoryError.invalidFixture(
          "\(scenario.id): LLM-backed requirement lacks recorded envelope"
        )
      }
      try requireUnique(scenario.events.map(\.id), label: "\(scenario.id) event id")
      let sortedSequences = scenario.events.map(\.sequence).sorted()
      guard sortedSequences == scenario.events.map(\.sequence) else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): events are not ordered")
      }
      for event in scenario.events {
        guard event.bytes.count <= scenario.configuration.maxEventBytes else {
          throw OperatorMemoryError.invalidFixture("\(scenario.id): event exceeds byte limit")
        }
      }
      let eventIDs = Set(scenario.events.map(\.id))
      guard Set(scenario.expectedSourceHashes.keys) == eventIDs,
        scenario.expectedSourceHashes.values.allSatisfy(isSHA256)
      else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): invalid expected source hashes")
      }
      if let envelope = scenario.recordedLlm {
        try RecordedLLMProposalAdapter.validate(
          envelope,
          maximumProposals: scenario.configuration.maxOperators
        )
        let seedIDs = Set(scenario.seedOperatorIds)
        guard envelope.proposals.allSatisfy({ !seedIDs.contains($0.id) }) else {
          throw OperatorMemoryError.invalidFixture(
            "\(scenario.id): seed/proposal operator id collision"
          )
        }
      }
      let explicitCandidateCount =
        scenario.seedOperatorIds.count + (scenario.recordedLlm?.proposals.count ?? 0)
      guard explicitCandidateCount <= scenario.configuration.maxCandidates else {
        throw OperatorMemoryError.invalidFixture(
          "\(scenario.id): explicit candidates exceed max_candidates"
        )
      }
      guard scenario.graphEdges.count <= 512, scenario.semanticLinks.count <= 512 else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): graph limit exceeded")
      }
      let scenarioProfiles =
        try scenario.seedOperatorIds.map { id -> OperatorProfile in
          guard let profile = catalogByID[id] else {
            throw OperatorMemoryError.invalidFixture("\(scenario.id): missing seed operator")
          }
          return profile
        } + (scenario.recordedLlm?.proposals ?? [])
      try validateGraph(
        scenario.graphEdges,
        operators: scenarioProfiles,
        scenarioID: scenario.id
      )
      let scenarioOperatorIDs = Set(scenarioProfiles.map(\.id))
      try requireUnique(
        scenario.semanticLinks.map(\.id),
        label: "\(scenario.id) semantic link id"
      )
      guard
        scenario.semanticLinks.allSatisfy({ link in
          eventIDs.contains(link.sourceEventId)
            && eventIDs.contains(link.targetEventId)
            && (0...1_000_000).contains(link.confidencePpm)
        })
      else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): invalid semantic link")
      }
      guard scenario.semanticLinks.allSatisfy({ scenarioOperatorIDs.contains($0.operatorId) })
      else {
        throw OperatorMemoryError.invalidFixture("\(scenario.id): unknown semantic-link operator")
      }
      if let automation = scenario.automation {
        guard automation.steps.count <= 32 else {
          throw OperatorMemoryError.invalidFixture("\(scenario.id): automation step limit exceeded")
        }
        guard let profile = scenarioProfiles.first(where: { $0.id == automation.operatorId }) else {
          throw OperatorMemoryError.invalidFixture("\(scenario.id): missing automation operator")
        }
        guard profile.stratum == .automation else {
          throw OperatorMemoryError.invalidFixture(
            "\(scenario.id): automation operator has invalid stratum"
          )
        }
        guard
          scenario.graphEdges.contains(where: { edge in
            edge.toId == automation.operatorId
              && (edge.relation == .projectsTo || edge.relation == .executesAs)
          })
        else {
          throw OperatorMemoryError.invalidFixture(
            "\(scenario.id): automation operator lacks incoming projection"
          )
        }
      }
      if let synchronization = scenario.synchronization {
        guard synchronization.nodes.count <= 32 else {
          throw OperatorMemoryError.invalidFixture("\(scenario.id): node limit exceeded")
        }
        guard synchronization.acts.count <= scenario.configuration.maxEvents else {
          throw OperatorMemoryError.invalidFixture("\(scenario.id): speech-act limit exceeded")
        }
        try requireUnique(
          synchronization.nodes.map(\.id),
          label: "\(scenario.id) synchronization node id"
        )
        try requireUnique(
          synchronization.acts.map(\.id),
          label: "\(scenario.id) speech-act id"
        )
        for node in synchronization.nodes {
          try requireUnique(
            node.initialFacts.map(\.key),
            label: "\(scenario.id) initial fact key"
          )
        }
        let synchronizationNodeIDs = Set(synchronization.nodes.map(\.id))
        guard
          synchronization.acts.allSatisfy({ act in
            synchronizationNodeIDs.contains(act.speakerId)
              && act.recipientIds.allSatisfy(synchronizationNodeIDs.contains)
          })
        else {
          throw OperatorMemoryError.invalidFixture(
            "\(scenario.id): unknown synchronization participant"
          )
        }
        let participantIDs = Set(
          synchronization.acts.flatMap { [$0.speakerId] + $0.recipientIds }
        )
        for node in synchronization.nodes
        where node.kind == .llmBacked && !participantIDs.contains(node.id) {
          throw OperatorMemoryError.invalidFixture(
            "\(scenario.id): LLM-backed node \(node.id) does not participate"
          )
        }
      }
    }
  }

  static func validate(_ profile: OperatorProfile) throws {
    guard !profile.id.isEmpty, profile.version > 0 else {
      throw OperatorMemoryError.invalidFixture("invalid operator identity")
    }
    guard !reservedExplicitOperatorIDPrefixes.contains(where: profile.id.hasPrefix) else {
      throw OperatorMemoryError.invalidFixture(
        "\(profile.id): reserved explicit operator id namespace"
      )
    }
    guard (0...1_000_000).contains(profile.confidencePpm) else {
      throw OperatorMemoryError.invalidFixture("\(profile.id): confidence outside ppm range")
    }
    guard profile.storageCostBits >= 0 else {
      throw OperatorMemoryError.invalidFixture("\(profile.id): negative storage cost")
    }
    guard profile.recognitionPatterns.allSatisfy({ !$0.isEmpty && $0.utf8.count <= 4_096 }),
      Set(profile.recognitionPatterns).count == profile.recognitionPatterns.count,
      profile.positiveExamples.count <= 128,
      profile.negativeExamples.count <= 128
    else {
      throw OperatorMemoryError.invalidFixture("\(profile.id): invalid operator examples")
    }
  }

  private static func requireUnique(_ values: [String], label: String) throws {
    guard Set(values).count == values.count else {
      throw OperatorMemoryError.invalidFixture("duplicate \(label)")
    }
  }

  private static func validateGraph(
    _ edges: [GraphEdgeFixture],
    operators: [OperatorProfile],
    scenarioID: String
  ) throws {
    try requireUnique(edges.map(\.id), label: "\(scenarioID) graph edge id")
    let profiles = Dictionary(uniqueKeysWithValues: operators.map { ($0.id, $0) })
    for edge in edges {
      guard let from = profiles[edge.fromId], let to = profiles[edge.toId] else {
        throw OperatorMemoryError.invalidFixture("\(scenarioID): dangling graph edge \(edge.id)")
      }
      let allowed: Bool
      switch edge.relation {
      case .abstracts:
        allowed = from.stratum.rank < to.stratum.rank
      case .generates:
        allowed = from.stratum.rank > to.stratum.rank
      case .translatesVia:
        allowed = from.stratum == .semantic || to.stratum == .semantic
      case .recognizes:
        allowed = from.stratum.rank >= to.stratum.rank
      case .projectsTo, .executesAs:
        allowed = from.stratum.rank < to.stratum.rank
      case .composes, .specializes:
        allowed = from.stratum == to.stratum
      case .conflicts:
        allowed = from.id != to.id
      case .verifies:
        allowed = false
      }
      guard allowed else {
        throw OperatorMemoryError.invalidFixture(
          "\(scenarioID): invalid \(edge.relation.rawValue) strata in \(edge.id)"
        )
      }
    }
  }

  private static func isSHA256(_ value: String) -> Bool {
    RecordedLLMProposalAdapter.isSHA256(value)
  }
}

public enum RecordedLLMProposalAdapter {
  private static let maximumEnvelopeBytes = 262_144

  public static func decode(data: Data) throws -> RecordedLLMEnvelope {
    guard data.count <= maximumEnvelopeBytes else {
      throw OperatorMemoryError.resourceTooLarge(data.count)
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let envelope = try decoder.decode(RecordedLLMEnvelope.self, from: data)
    try validate(envelope, maximumProposals: 64)
    return envelope
  }

  static func validate(
    _ envelope: RecordedLLMEnvelope,
    maximumProposals: Int
  ) throws {
    guard envelope.schemaVersion == 1 else {
      throw OperatorMemoryError.unsupportedSchema(envelope.schemaVersion)
    }
    guard !envelope.adapterId.isEmpty, !envelope.model.isEmpty else {
      throw OperatorMemoryError.invalidRecordedEnvelope("missing adapter identity")
    }
    guard !envelope.promptText.isEmpty else {
      throw OperatorMemoryError.invalidRecordedEnvelope("missing recorded prompt")
    }
    guard isSHA256(envelope.promptHash), isSHA256(envelope.responseHash) else {
      throw OperatorMemoryError.invalidRecordedEnvelope("invalid recorded hash")
    }
    guard envelope.proposals.count <= maximumProposals else {
      throw OperatorMemoryError.invalidRecordedEnvelope("proposal limit exceeded")
    }
    guard envelope.proposals.allSatisfy({ $0.origin == .llm }) else {
      throw OperatorMemoryError.invalidRecordedEnvelope("non-LLM proposal in LLM envelope")
    }
    guard Set(envelope.proposals.map(\.id)).count == envelope.proposals.count else {
      throw OperatorMemoryError.invalidRecordedEnvelope("duplicate proposal id")
    }
    if let prefix = reservedExplicitOperatorIDPrefixes.first(where: { prefix in
      envelope.proposals.contains { $0.id.hasPrefix(prefix) }
    }) {
      throw OperatorMemoryError.invalidRecordedEnvelope(
        "reserved proposal id namespace: \(prefix)"
      )
    }
    for profile in envelope.proposals {
      do {
        try ScenarioFixtureLoader.validate(profile)
      } catch {
        throw OperatorMemoryError.invalidRecordedEnvelope("invalid proposal \(profile.id)")
      }
    }
    guard envelope.promptHash == sha256Digest(Data(envelope.promptText.utf8)) else {
      throw OperatorMemoryError.invalidRecordedEnvelope("prompt hash mismatch")
    }
    guard let encodedProposals = try? canonicalJSONData(envelope.proposals),
      envelope.responseHash == sha256Digest(encodedProposals)
    else {
      throw OperatorMemoryError.invalidRecordedEnvelope("response hash mismatch")
    }
  }

  static func isSHA256(_ value: String) -> Bool {
    guard value.count == 71, value.hasPrefix("sha256:") else { return false }
    return value.dropFirst(7).allSatisfy { character in
      character.isNumber || ("a"..."f").contains(String(character))
    }
  }
}
