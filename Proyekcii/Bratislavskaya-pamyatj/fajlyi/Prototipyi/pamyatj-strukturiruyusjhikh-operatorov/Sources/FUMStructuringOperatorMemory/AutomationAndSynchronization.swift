import Foundation

enum AutomationExecutor {
  private struct TracePayload: Encodable {
    let operatorID: String
    let input: String
    let output: String
    let effects: [String]
    let steps: [AutomationStepTrace]
    let passed: Bool
  }

  static func run(_ fixture: AutomationFixture) throws -> AutomationTrace {
    guard fixture.steps.count <= 32 else {
      throw OperatorMemoryError.automationFailed("step limit exceeded")
    }
    var current = fixture.input
    var traces: [AutomationStepTrace] = []
    traces.reserveCapacity(fixture.steps.count)

    for step in fixture.steps {
      let inputHash = sha256Digest(Data(current.utf8))
      switch step.kind {
      case .trim:
        current = current.trimmingCharacters(in: .whitespacesAndNewlines)
      case .lowercase:
        current = current.lowercased()
      case .collapseWhitespace:
        current = current.split(whereSeparator: \.isWhitespace).joined(separator: " ")
      case .replace:
        guard let argument = step.argument,
          let separator = argument.range(of: "=>")
        else {
          throw OperatorMemoryError.automationFailed("replace requires old=>new")
        }
        current = current.replacingOccurrences(
          of: String(argument[..<separator.lowerBound]),
          with: String(argument[separator.upperBound...])
        )
      case .prefix:
        guard let argument = step.argument else {
          throw OperatorMemoryError.automationFailed("prefix requires argument")
        }
        current = argument + current
      }
      traces.append(
        AutomationStepTrace(
          stepID: step.id,
          kind: step.kind,
          inputHash: inputHash,
          outputHash: sha256Digest(Data(current.utf8))
        )
      )
    }

    let effects = fixture.effects.sorted()
    let passed = current == fixture.expectedOutput && effects.isEmpty
    let traceHash = sha256Digest(
      try canonicalJSONData(
        TracePayload(
          operatorID: fixture.operatorId,
          input: fixture.input,
          output: current,
          effects: effects,
          steps: traces,
          passed: passed
        )
      )
    )

    return AutomationTrace(
      operatorID: fixture.operatorId,
      input: fixture.input,
      output: current,
      effects: effects,
      steps: traces,
      traceHash: traceHash,
      passed: passed
    )
  }
}

enum SynchronizationReducer {
  private struct NodeState: Sendable {
    let id: String
    let kind: NodeKind
    var facts: [String: KnowledgeFact]
    var factHistory: [KnowledgeFact]
  }

  private struct ConfirmationEvidence: Sendable {
    let factKey: String
    let factValue: String
    let factTime: String
    let participantIDs: Set<String>
  }

  static func run(_ fixture: SynchronizationFixture) throws -> SynchronizationTrace {
    guard fixture.nodes.count <= 32, fixture.acts.count <= 128 else {
      throw OperatorMemoryError.invalidFixture("synchronization limit exceeded")
    }
    let nodeIDs = fixture.nodes.map(\.id)
    guard Set(nodeIDs).count == nodeIDs.count else {
      throw OperatorMemoryError.invalidFixture("duplicate synchronization node")
    }
    var states = Dictionary(
      uniqueKeysWithValues: fixture.nodes.map { node in
        (
          node.id,
          NodeState(
            id: node.id,
            kind: node.kind,
            facts: Dictionary(uniqueKeysWithValues: node.initialFacts.map { ($0.key, $0) }),
            factHistory: node.initialFacts
          )
        )
      }
    )
    var divergences: [String] = []
    var confirmations: [ConfirmationEvidence] = []
    var actionExecuted = false
    var allBindings: [RoleBinding] = []

    let acts = fixture.acts.sorted { left, right in
      if left.sequence != right.sequence { return left.sequence < right.sequence }
      return left.id < right.id
    }
    guard acts.map(\.sequence) == fixture.acts.map(\.sequence) else {
      throw OperatorMemoryError.invalidFixture("speech acts are not ordered")
    }
    let participatingNodeIDs = Set(acts.flatMap { [$0.speakerId] + $0.recipientIds })

    for act in acts {
      guard states[act.speakerId] != nil,
        act.recipientIds.allSatisfy({ states[$0] != nil })
      else {
        throw OperatorMemoryError.invalidFixture("unknown speech-act participant")
      }
      allBindings.append(contentsOf: act.roleBindings)

      switch act.type {
      case .question:
        break
      case .divergence:
        let value = act.fact.map { "\($0.key)=\($0.value)" } ?? "unspecified"
        divergences.append("\(act.id):\(value)")
      case .confirmation:
        let participantIDs = Set([act.speakerId] + act.recipientIds)
        if let fact = act.fact,
          act.authorized,
          fixture.requiredFactKeys.contains(fact.key),
          participantIDs.count == act.recipientIds.count + 1,
          hasConsistent(
            fact: fact,
            participantIDs: participantIDs,
            states: states
          )
        {
          update(fact: fact, for: Array(participantIDs), states: &states)
          confirmations.append(
            ConfirmationEvidence(
              factKey: fact.key,
              factValue: fact.value,
              factTime: fact.time,
              participantIDs: participantIDs
            )
          )
        }
      case .jointAction:
        let participantIDs = Set([act.speakerId] + act.recipientIds)
        let hasRelevantConfirmation = confirmations.contains { confirmation in
          participantIDs.isSubset(of: confirmation.participantIDs)
            && fixture.requiredFactKeys.contains(confirmation.factKey)
            && statesAreConsistent(with: confirmation, states: states)
        }
        actionExecuted =
          act.authorized
          && hasRelevantConfirmation
          && divergences.isEmpty
          && hasCompatibleFacts(
            fixture.requiredFactKeys,
            participantIDs: participantIDs,
            states: states
          )
      case .statement, .clarification, .correction, .paraphrase:
        if let fact = act.fact {
          update(fact: fact, for: [act.speakerId] + act.recipientIds, states: &states)
        }
      }
    }

    let snapshots = states.values.map { state in
      NodeKnowledgeSnapshot(
        nodeID: state.id,
        kind: state.kind,
        facts: state.facts.values.sorted(by: factOrder),
        factHistory: state.factHistory
      )
    }.sorted { $0.nodeID < $1.nodeID }

    return SynchronizationTrace(
      nodeSnapshots: snapshots,
      actTypes: acts.map(\.type),
      roleBindings: allBindings,
      divergences: divergences,
      actionExecuted: actionExecuted,
      containsLLMBackedNode: fixture.nodes.contains {
        $0.kind == .llmBacked && participatingNodeIDs.contains($0.id)
      },
      simulationOnly: true,
      externalEffects: []
    )
  }

  private static func update(
    fact: KnowledgeFact,
    for nodeIDs: [String],
    states: inout [String: NodeState]
  ) {
    for nodeID in Set(nodeIDs) {
      guard var state = states[nodeID] else { continue }
      state.facts[fact.key] = fact
      state.factHistory.append(fact)
      states[nodeID] = state
    }
  }

  private static func hasCompatibleFacts(
    _ requiredKeys: [String],
    participantIDs: Set<String>,
    states: [String: NodeState]
  ) -> Bool {
    for key in requiredKeys {
      let facts = participantIDs.compactMap { states[$0]?.facts[key] }
      guard let reference = facts.first,
        facts.count == participantIDs.count,
        facts.allSatisfy({ fact in
          fact.value == reference.value && fact.time == reference.time
        })
      else { return false }
    }
    return true
  }

  private static func hasConsistent(
    fact: KnowledgeFact,
    participantIDs: Set<String>,
    states: [String: NodeState]
  ) -> Bool {
    participantIDs.allSatisfy { nodeID in
      guard let current = states[nodeID]?.facts[fact.key] else { return false }
      return current.value == fact.value && current.time == fact.time
    }
  }

  private static func statesAreConsistent(
    with confirmation: ConfirmationEvidence,
    states: [String: NodeState]
  ) -> Bool {
    confirmation.participantIDs.allSatisfy { nodeID in
      guard let current = states[nodeID]?.facts[confirmation.factKey] else { return false }
      return current.value == confirmation.factValue && current.time == confirmation.factTime
    }
  }

  private static func factOrder(_ left: KnowledgeFact, _ right: KnowledgeFact) -> Bool {
    if left.key != right.key { return left.key < right.key }
    if left.value != right.value { return left.value < right.value }
    return left.source < right.source
  }
}
