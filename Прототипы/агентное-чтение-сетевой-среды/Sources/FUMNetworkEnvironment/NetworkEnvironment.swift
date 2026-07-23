import CryptoKit
import Foundation

public enum CalculatorKind: String, Codable, Equatable, Sendable {
  case identity
  case add
  case multiply
}

public struct Calculator: Codable, Equatable, Sendable {
  public let kind: CalculatorKind
  public let operand: Int

  public init(kind: CalculatorKind, operand: Int) {
    self.kind = kind
    self.operand = operand
  }

  public func apply(to input: Int) throws -> Int {
    switch kind {
    case .identity:
      input
    case .add:
      try checkedAdd(input, operand)
    case .multiply:
      try checkedMultiply(input, operand)
    }
  }
}

public struct NetworkEdge: Codable, Equatable, Sendable {
  public let signal: String
  public let targetNodeID: String

  public init(signal: String, targetNodeID: String) {
    self.signal = signal
    self.targetNodeID = targetNodeID
  }
}

public struct CalculatorNode: Codable, Equatable, Sendable {
  public let id: String
  public let calculator: Calculator
  public let edges: [NetworkEdge]

  public init(id: String, calculator: Calculator, edges: [NetworkEdge]) {
    self.id = id
    self.calculator = calculator
    self.edges = edges.sorted { left, right in
      if left.signal != right.signal {
        return left.signal < right.signal
      }
      return left.targetNodeID < right.targetNodeID
    }
  }
}

public struct CalculatorNetwork: Codable, Equatable, Sendable {
  public let entryNodeID: String
  public let nodes: [CalculatorNode]

  public init(entryNodeID: String, nodes: [CalculatorNode]) throws {
    var identifiers = Set<String>()
    for node in nodes {
      guard identifiers.insert(node.id).inserted else {
        throw NetworkEnvironmentError.duplicateNodeID(node.id)
      }
    }
    guard identifiers.contains(entryNodeID) else {
      throw NetworkEnvironmentError.missingEntryNode(entryNodeID)
    }
    for node in nodes {
      for edge in node.edges where !identifiers.contains(edge.targetNodeID) {
        throw NetworkEnvironmentError.missingTargetNode(edge.targetNodeID)
      }
    }

    self.entryNodeID = entryNodeID
    self.nodes = nodes.sorted { $0.id < $1.id }
  }

  public func node(id: String) throws -> CalculatorNode {
    guard let node = nodes.first(where: { $0.id == id }) else {
      throw NetworkEnvironmentError.missingTargetNode(id)
    }
    return node
  }

  public func sha256() throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let digest = SHA256.hash(data: try encoder.encode(self))
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }
}

public struct InterpretationSettings: Codable, Equatable, Sendable {
  public let signalWeights: [String: Int]
  public let stepLimit: Int

  public init(signalWeights: [String: Int], stepLimit: Int) {
    self.signalWeights = signalWeights
    self.stepLimit = stepLimit
  }

  fileprivate func weight(for signal: String) -> Int {
    signalWeights[signal, default: 0]
  }
}

public struct ParameterMutation: Codable, Equatable, Sendable {
  public let signal: String
  public let delta: Int

  public init(signal: String, delta: Int) {
    self.signal = signal
    self.delta = delta
  }
}

public struct InterpreterAgent: Codable, Equatable, Sendable {
  public let id: String
  public let parentID: String?
  public let generation: Int
  public let settings: InterpretationSettings
  public let mutations: [ParameterMutation]

  public init(
    id: String,
    parentID: String?,
    generation: Int,
    settings: InterpretationSettings,
    mutations: [ParameterMutation]
  ) {
    self.id = id
    self.parentID = parentID
    self.generation = generation
    self.settings = settings
    self.mutations = mutations
  }

  public static func root(id: String, settings: InterpretationSettings) -> InterpreterAgent {
    InterpreterAgent(
      id: id,
      parentID: nil,
      generation: 0,
      settings: settings,
      mutations: []
    )
  }

  public func inheriting(id childID: String, mutation: ParameterMutation) throws
    -> InterpreterAgent
  {
    guard mutation.delta != 0 else {
      throw NetworkEnvironmentError.zeroMutation
    }
    var weights = settings.signalWeights
    weights[mutation.signal] = try checkedAdd(weights[mutation.signal, default: 0], mutation.delta)
    return InterpreterAgent(
      id: childID,
      parentID: id,
      generation: try checkedAdd(generation, 1),
      settings: InterpretationSettings(signalWeights: weights, stepLimit: settings.stepLimit),
      mutations: mutations + [mutation]
    )
  }
}

public struct EvaluationCase: Codable, Equatable, Sendable {
  public let id: String
  public let input: Int
  public let target: Int

  public init(id: String, input: Int, target: Int) {
    self.id = id
    self.input = input
    self.target = target
  }
}

public enum TraceStopReason: String, Codable, Equatable, Sendable {
  case terminalNode = "terminal_node"
  case stepLimit = "step_limit"
}

public struct MovementStep: Codable, Equatable, Sendable {
  public let index: Int
  public let nodeID: String
  public let input: Int
  public let output: Int
  public let chosenSignal: String?
  public let targetNodeID: String?

  public init(
    index: Int,
    nodeID: String,
    input: Int,
    output: Int,
    chosenSignal: String?,
    targetNodeID: String?
  ) {
    self.index = index
    self.nodeID = nodeID
    self.input = input
    self.output = output
    self.chosenSignal = chosenSignal
    self.targetNodeID = targetNodeID
  }
}

public struct MovementTrace: Codable, Equatable, Sendable {
  public let caseID: String
  public let input: Int
  public let target: Int
  public let output: Int
  public let absoluteError: Int
  public let stopReason: TraceStopReason
  public let steps: [MovementStep]

  public init(
    caseID: String,
    input: Int,
    target: Int,
    output: Int,
    absoluteError: Int,
    stopReason: TraceStopReason,
    steps: [MovementStep]
  ) {
    self.caseID = caseID
    self.input = input
    self.target = target
    self.output = output
    self.absoluteError = absoluteError
    self.stopReason = stopReason
    self.steps = steps
  }
}

public struct UtilityPolicy: Codable, Equatable, Sendable {
  public let taskRewardBase: Int
  public let errorPenalty: Int
  public let nodeVisitCost: Int
  public let mutationCost: Int

  public init(
    taskRewardBase: Int,
    errorPenalty: Int,
    nodeVisitCost: Int,
    mutationCost: Int
  ) {
    self.taskRewardBase = taskRewardBase
    self.errorPenalty = errorPenalty
    self.nodeVisitCost = nodeVisitCost
    self.mutationCost = mutationCost
  }
}

public struct AgentMetrics: Codable, Equatable, Sendable {
  public let totalError: Int
  public let exactCases: Int
  public let qualityGatePassed: Bool
  public let nodeVisits: Int
  public let taskReward: Int
  public let resourceCost: Int
  public let mutationCost: Int
  public let economicUtility: Int

  public init(
    totalError: Int,
    exactCases: Int,
    qualityGatePassed: Bool,
    nodeVisits: Int,
    taskReward: Int,
    resourceCost: Int,
    mutationCost: Int,
    economicUtility: Int
  ) {
    self.totalError = totalError
    self.exactCases = exactCases
    self.qualityGatePassed = qualityGatePassed
    self.nodeVisits = nodeVisits
    self.taskReward = taskReward
    self.resourceCost = resourceCost
    self.mutationCost = mutationCost
    self.economicUtility = economicUtility
  }
}

public struct AgentEvaluation: Codable, Equatable, Sendable {
  public let agent: InterpreterAgent
  public let traces: [MovementTrace]
  public let metrics: AgentMetrics

  public init(agent: InterpreterAgent, traces: [MovementTrace], metrics: AgentMetrics) {
    self.agent = agent
    self.traces = traces
    self.metrics = metrics
  }
}

public struct PopulationBudget: Codable, Equatable, Sendable {
  public let maxAgents: Int
  public let maxBirths: Int
  public let maxGenerations: Int
  public let maxNodeVisits: Int
  public let maxTraceSteps: Int
  public let maxGraphWrites: Int

  public init(
    maxAgents: Int,
    maxBirths: Int,
    maxGenerations: Int,
    maxNodeVisits: Int,
    maxTraceSteps: Int,
    maxGraphWrites: Int
  ) {
    self.maxAgents = maxAgents
    self.maxBirths = maxBirths
    self.maxGenerations = maxGenerations
    self.maxNodeVisits = maxNodeVisits
    self.maxTraceSteps = maxTraceSteps
    self.maxGraphWrites = maxGraphWrites
  }
}

public struct BudgetUsage: Codable, Equatable, Sendable {
  public let evaluatedAgents: Int
  public let births: Int
  public let nodeVisits: Int
  public let traceSteps: Int
  public let graphWrites: Int

  public init(
    evaluatedAgents: Int,
    births: Int,
    nodeVisits: Int,
    traceSteps: Int,
    graphWrites: Int
  ) {
    self.evaluatedAgents = evaluatedAgents
    self.births = births
    self.nodeVisits = nodeVisits
    self.traceSteps = traceSteps
    self.graphWrites = graphWrites
  }
}

public struct MutationPlan: Codable, Equatable, Sendable {
  public let childID: String
  public let parentID: String
  public let mutation: ParameterMutation

  public init(childID: String, parentID: String, mutation: ParameterMutation) {
    self.childID = childID
    self.parentID = parentID
    self.mutation = mutation
  }
}

public struct GenerationTrace: Codable, Equatable, Sendable {
  public let generation: Int
  public let scheduledAgentIDs: [String]
  public let evaluatedAgentIDs: [String]
  public let spawnedAgentIDs: [String]
  public let skippedAgentIDs: [String]

  public init(
    generation: Int,
    scheduledAgentIDs: [String],
    evaluatedAgentIDs: [String],
    spawnedAgentIDs: [String],
    skippedAgentIDs: [String]
  ) {
    self.generation = generation
    self.scheduledAgentIDs = scheduledAgentIDs
    self.evaluatedAgentIDs = evaluatedAgentIDs
    self.spawnedAgentIDs = spawnedAgentIDs
    self.skippedAgentIDs = skippedAgentIDs
  }

  enum CodingKeys: String, CodingKey {
    case generation
    case scheduledAgentIDs = "scheduled_agent_ids"
    case evaluatedAgentIDs = "evaluated_agent_ids"
    case spawnedAgentIDs = "spawned_agent_ids"
    case skippedAgentIDs = "skipped_agent_ids"
  }
}

public struct RuntimeSelectionReport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let networkSHA256Before: String
  public let networkSHA256After: String
  public let baseMapUnchanged: Bool
  public let selectionCriteria: [String]
  public let budget: PopulationBudget
  public let usage: BudgetUsage
  public let generations: [GenerationTrace]
  public let evaluations: [AgentEvaluation]
  public let skippedAgentIDs: [String]
  public let winnerAgentID: String

  public init(
    schemaVersion: Int,
    networkSHA256Before: String,
    networkSHA256After: String,
    baseMapUnchanged: Bool,
    selectionCriteria: [String],
    budget: PopulationBudget,
    usage: BudgetUsage,
    generations: [GenerationTrace],
    evaluations: [AgentEvaluation],
    skippedAgentIDs: [String],
    winnerAgentID: String
  ) {
    self.schemaVersion = schemaVersion
    self.networkSHA256Before = networkSHA256Before
    self.networkSHA256After = networkSHA256After
    self.baseMapUnchanged = baseMapUnchanged
    self.selectionCriteria = selectionCriteria
    self.budget = budget
    self.usage = usage
    self.generations = generations
    self.evaluations = evaluations
    self.skippedAgentIDs = skippedAgentIDs
    self.winnerAgentID = winnerAgentID
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case networkSHA256Before
    case networkSHA256After
    case baseMapUnchanged
    case selectionCriteria
    case budget
    case usage
    case generations
    case evaluations
    case skippedAgentIDs = "skipped_agent_ids"
    case winnerAgentID
  }
}

public enum NetworkEnvironmentError: Error, Equatable, Sendable {
  case arithmeticOverflow
  case duplicateAgentID(String)
  case duplicateNodeID(String)
  case emptyCases
  case invalidBudget
  case missingEntryNode(String)
  case missingTargetNode(String)
  case noEvaluatedAgents
  case nonPositiveStepLimit
  case unknownParentID(String)
  case zeroMutation
}

public enum AgentRuntime {
  public static func evaluate(
    agent: InterpreterAgent,
    network: CalculatorNetwork,
    cases: [EvaluationCase],
    utilityPolicy: UtilityPolicy
  ) throws -> AgentEvaluation {
    guard agent.settings.stepLimit > 0 else {
      throw NetworkEnvironmentError.nonPositiveStepLimit
    }
    guard !cases.isEmpty else {
      throw NetworkEnvironmentError.emptyCases
    }

    let traces = try cases.map { evaluationCase in
      try trace(agent: agent, network: network, evaluationCase: evaluationCase)
    }
    let totalError = try traces.reduce(0) { partial, trace in
      try checkedAdd(partial, trace.absoluteError)
    }
    let exactCases = traces.filter { $0.absoluteError == 0 }.count
    let nodeVisits = traces.reduce(0) { $0 + $1.steps.count }
    let errorCost = try checkedMultiply(totalError, utilityPolicy.errorPenalty)
    let taskReward = try checkedSubtract(utilityPolicy.taskRewardBase, errorCost)
    let resourceCost = try checkedMultiply(nodeVisits, utilityPolicy.nodeVisitCost)
    let mutationCost = try checkedMultiply(agent.mutations.count, utilityPolicy.mutationCost)
    let economicUtility = try checkedSubtract(
      try checkedSubtract(taskReward, resourceCost),
      mutationCost
    )
    let metrics = AgentMetrics(
      totalError: totalError,
      exactCases: exactCases,
      qualityGatePassed: exactCases == cases.count,
      nodeVisits: nodeVisits,
      taskReward: taskReward,
      resourceCost: resourceCost,
      mutationCost: mutationCost,
      economicUtility: economicUtility
    )
    return AgentEvaluation(agent: agent, traces: traces, metrics: metrics)
  }

  private static func trace(
    agent: InterpreterAgent,
    network: CalculatorNetwork,
    evaluationCase: EvaluationCase
  ) throws -> MovementTrace {
    var currentNodeID = network.entryNodeID
    var value = evaluationCase.input
    var steps: [MovementStep] = []
    var stopReason = TraceStopReason.stepLimit

    for index in 0..<agent.settings.stepLimit {
      let node = try network.node(id: currentNodeID)
      let input = value
      value = try node.calculator.apply(to: input)

      let selectedEdge: NetworkEdge?
      if node.edges.isEmpty {
        selectedEdge = nil
        stopReason = .terminalNode
      } else if index + 1 == agent.settings.stepLimit {
        selectedEdge = nil
        stopReason = .stepLimit
      } else {
        selectedEdge = selectEdge(node.edges, settings: agent.settings)
      }

      steps.append(
        MovementStep(
          index: index,
          nodeID: node.id,
          input: input,
          output: value,
          chosenSignal: selectedEdge?.signal,
          targetNodeID: selectedEdge?.targetNodeID
        )
      )
      guard let selectedEdge else {
        break
      }
      currentNodeID = selectedEdge.targetNodeID
    }

    return MovementTrace(
      caseID: evaluationCase.id,
      input: evaluationCase.input,
      target: evaluationCase.target,
      output: value,
      absoluteError: try checkedAbsoluteDifference(value, evaluationCase.target),
      stopReason: stopReason,
      steps: steps
    )
  }

  private static func selectEdge(
    _ edges: [NetworkEdge],
    settings: InterpretationSettings
  ) -> NetworkEdge? {
    edges.sorted { left, right in
      let leftWeight = settings.weight(for: left.signal)
      let rightWeight = settings.weight(for: right.signal)
      if leftWeight != rightWeight {
        return leftWeight > rightWeight
      }
      if left.targetNodeID != right.targetNodeID {
        return left.targetNodeID < right.targetNodeID
      }
      return left.signal < right.signal
    }.first
  }
}

public enum RuntimeSelector {
  public static func run(
    network: CalculatorNetwork,
    cases: [EvaluationCase],
    initialAgents: [InterpreterAgent],
    mutationPlans: [MutationPlan],
    budget: PopulationBudget,
    utilityPolicy: UtilityPolicy
  ) throws -> RuntimeSelectionReport {
    try validate(budget: budget)
    guard !cases.isEmpty else {
      throw NetworkEnvironmentError.emptyCases
    }

    let beforeHash = try network.sha256()
    var knownAgentIDs = Set<String>()
    for agent in initialAgents {
      guard knownAgentIDs.insert(agent.id).inserted else {
        throw NetworkEnvironmentError.duplicateAgentID(agent.id)
      }
    }

    var scheduled = initialAgents.sorted { $0.id < $1.id }
    var evaluations: [AgentEvaluation] = []
    var generationTraces: [GenerationTrace] = []
    var skippedAgentIDs: [String] = []
    var births = 0
    var nodeVisits = 0
    var traceSteps = 0
    var generation = 0

    while !scheduled.isEmpty, generation <= budget.maxGenerations {
      let scheduledIDs = scheduled.map(\.id)
      var evaluatedIDs: [String] = []
      var generationSkippedIDs: [String] = []

      for agent in scheduled {
        let maximumVisits = try checkedMultiply(cases.count, agent.settings.stepLimit)
        let nextMaximumVisits = try checkedAdd(nodeVisits, maximumVisits)
        let nextMaximumTraceSteps = try checkedAdd(traceSteps, maximumVisits)
        guard evaluations.count < budget.maxAgents,
          nextMaximumVisits <= budget.maxNodeVisits,
          nextMaximumTraceSteps <= budget.maxTraceSteps
        else {
          generationSkippedIDs.append(agent.id)
          skippedAgentIDs.append(agent.id)
          continue
        }

        let evaluation = try AgentRuntime.evaluate(
          agent: agent,
          network: network,
          cases: cases,
          utilityPolicy: utilityPolicy
        )
        evaluations.append(evaluation)
        evaluatedIDs.append(agent.id)
        nodeVisits = try checkedAdd(nodeVisits, evaluation.metrics.nodeVisits)
        traceSteps = try checkedAdd(traceSteps, evaluation.metrics.nodeVisits)
      }

      var children: [InterpreterAgent] = []
      var spawnedIDs: [String] = []
      if generation < budget.maxGenerations {
        let evaluatedSet = Set(evaluatedIDs)
        for plan in mutationPlans where evaluatedSet.contains(plan.parentID) {
          guard evaluations.count + children.count < budget.maxAgents,
            births < budget.maxBirths
          else {
            generationSkippedIDs.append(plan.childID)
            skippedAgentIDs.append(plan.childID)
            continue
          }
          guard knownAgentIDs.insert(plan.childID).inserted else {
            throw NetworkEnvironmentError.duplicateAgentID(plan.childID)
          }
          guard let parent = scheduled.first(where: { $0.id == plan.parentID }) else {
            throw NetworkEnvironmentError.unknownParentID(plan.parentID)
          }
          let child = try parent.inheriting(id: plan.childID, mutation: plan.mutation)
          children.append(child)
          spawnedIDs.append(child.id)
          births = try checkedAdd(births, 1)
        }
      }

      generationTraces.append(
        GenerationTrace(
          generation: generation,
          scheduledAgentIDs: scheduledIDs,
          evaluatedAgentIDs: evaluatedIDs,
          spawnedAgentIDs: spawnedIDs,
          skippedAgentIDs: generationSkippedIDs
        )
      )
      scheduled = children.sorted { $0.id < $1.id }
      generation = try checkedAdd(generation, 1)
    }

    guard let winner = select(evaluations) else {
      throw NetworkEnvironmentError.noEvaluatedAgents
    }
    let afterHash = try network.sha256()
    let usage = BudgetUsage(
      evaluatedAgents: evaluations.count,
      births: births,
      nodeVisits: nodeVisits,
      traceSteps: traceSteps,
      graphWrites: 0
    )
    return RuntimeSelectionReport(
      schemaVersion: 1,
      networkSHA256Before: beforeHash,
      networkSHA256After: afterHash,
      baseMapUnchanged: beforeHash == afterHash,
      selectionCriteria: [
        "quality_gate",
        "total_error",
        "economic_utility",
        "node_visits",
        "agent_id",
      ],
      budget: budget,
      usage: usage,
      generations: generationTraces,
      evaluations: evaluations,
      skippedAgentIDs: skippedAgentIDs,
      winnerAgentID: winner.agent.id
    )
  }

  private static func select(_ evaluations: [AgentEvaluation]) -> AgentEvaluation? {
    evaluations.sorted { left, right in
      if left.metrics.qualityGatePassed != right.metrics.qualityGatePassed {
        return left.metrics.qualityGatePassed && !right.metrics.qualityGatePassed
      }
      if left.metrics.totalError != right.metrics.totalError {
        return left.metrics.totalError < right.metrics.totalError
      }
      if left.metrics.economicUtility != right.metrics.economicUtility {
        return left.metrics.economicUtility > right.metrics.economicUtility
      }
      if left.metrics.nodeVisits != right.metrics.nodeVisits {
        return left.metrics.nodeVisits < right.metrics.nodeVisits
      }
      return left.agent.id < right.agent.id
    }.first
  }

  private static func validate(budget: PopulationBudget) throws {
    guard budget.maxAgents > 0,
      budget.maxBirths >= 0,
      budget.maxGenerations >= 0,
      budget.maxNodeVisits > 0,
      budget.maxTraceSteps > 0,
      budget.maxGraphWrites == 0
    else {
      throw NetworkEnvironmentError.invalidBudget
    }
  }
}

public enum NetworkReadingFixture {
  public static let cases = [
    EvaluationCase(id: "case.two", input: 2, target: 3),
    EvaluationCase(id: "case.four", input: 4, target: 7),
  ]

  public static let initialAgents = [
    InterpreterAgent.root(
      id: "agent.additive",
      settings: InterpretationSettings(
        signalWeights: ["finish": 10, "growth": 0, "refine": 0, "shortcut": 10],
        stepLimit: 3
      )
    ),
    InterpreterAgent.root(
      id: "agent.resource-saver",
      settings: InterpretationSettings(
        signalWeights: ["finish": 10, "growth": 10, "refine": 0, "shortcut": 0],
        stepLimit: 1
      )
    ),
    InterpreterAgent.root(
      id: "agent.scaling",
      settings: InterpretationSettings(
        signalWeights: ["finish": 10, "growth": 10, "refine": 0, "shortcut": 0],
        stepLimit: 3
      )
    ),
  ]

  public static let mutationPlans = [
    MutationPlan(
      childID: "agent.scaling.refined",
      parentID: "agent.scaling",
      mutation: ParameterMutation(signal: "refine", delta: 20)
    )
  ]

  public static let budget = PopulationBudget(
    maxAgents: 4,
    maxBirths: 1,
    maxGenerations: 1,
    maxNodeVisits: 20,
    maxTraceSteps: 20,
    maxGraphWrites: 0
  )

  public static let utilityPolicy = UtilityPolicy(
    taskRewardBase: 100,
    errorPenalty: 10,
    nodeVisitCost: 20,
    mutationCost: 5
  )

  public static func network() throws -> CalculatorNetwork {
    try CalculatorNetwork(
      entryNodeID: "entry",
      nodes: [
        CalculatorNode(
          id: "entry",
          calculator: Calculator(kind: .identity, operand: 0),
          edges: [
            NetworkEdge(signal: "growth", targetNodeID: "double"),
            NetworkEdge(signal: "shortcut", targetNodeID: "add-three"),
          ]
        ),
        CalculatorNode(
          id: "double",
          calculator: Calculator(kind: .multiply, operand: 2),
          edges: [
            NetworkEdge(signal: "finish", targetNodeID: "terminal"),
            NetworkEdge(signal: "refine", targetNodeID: "subtract-one"),
          ]
        ),
        CalculatorNode(
          id: "add-three",
          calculator: Calculator(kind: .add, operand: 3),
          edges: [
            NetworkEdge(signal: "finish", targetNodeID: "terminal"),
            NetworkEdge(signal: "refine", targetNodeID: "subtract-one"),
          ]
        ),
        CalculatorNode(
          id: "subtract-one",
          calculator: Calculator(kind: .add, operand: -1),
          edges: []
        ),
        CalculatorNode(
          id: "terminal",
          calculator: Calculator(kind: .identity, operand: 0),
          edges: []
        ),
      ]
    )
  }

  public static func run() throws -> RuntimeSelectionReport {
    try run(network: network())
  }

  public static func run(network: CalculatorNetwork) throws -> RuntimeSelectionReport {
    try RuntimeSelector.run(
      network: network,
      cases: cases,
      initialAgents: initialAgents,
      mutationPlans: mutationPlans,
      budget: budget,
      utilityPolicy: utilityPolicy
    )
  }
}

private func checkedAdd(_ left: Int, _ right: Int) throws -> Int {
  let result = left.addingReportingOverflow(right)
  guard !result.overflow else {
    throw NetworkEnvironmentError.arithmeticOverflow
  }
  return result.partialValue
}

private func checkedSubtract(_ left: Int, _ right: Int) throws -> Int {
  let result = left.subtractingReportingOverflow(right)
  guard !result.overflow else {
    throw NetworkEnvironmentError.arithmeticOverflow
  }
  return result.partialValue
}

private func checkedMultiply(_ left: Int, _ right: Int) throws -> Int {
  let result = left.multipliedReportingOverflow(by: right)
  guard !result.overflow else {
    throw NetworkEnvironmentError.arithmeticOverflow
  }
  return result.partialValue
}

private func checkedAbsoluteDifference(_ left: Int, _ right: Int) throws -> Int {
  let difference = try checkedSubtract(left, right)
  guard difference != Int.min else {
    throw NetworkEnvironmentError.arithmeticOverflow
  }
  return Swift.abs(difference)
}
