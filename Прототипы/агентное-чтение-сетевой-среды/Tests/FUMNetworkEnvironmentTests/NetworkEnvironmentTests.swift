import XCTest

@testable import FUMNetworkEnvironment

final class NetworkEnvironmentTests: XCTestCase {
  func testFixtureSelectsExactMutatedAgentBeforeCheaperResourceSaver() throws {
    let report = try NetworkReadingFixture.run()
    let winner = try XCTUnwrap(
      report.evaluations.first { $0.agent.id == report.winnerAgentID }
    )
    let saver = try XCTUnwrap(
      report.evaluations.first { $0.agent.id == "agent.resource-saver" }
    )

    XCTAssertEqual(report.winnerAgentID, "agent.scaling.refined")
    XCTAssertTrue(winner.metrics.qualityGatePassed)
    XCTAssertEqual(winner.metrics.totalError, 0)
    XCTAssertFalse(saver.metrics.qualityGatePassed)
    XCTAssertGreaterThan(saver.metrics.economicUtility, winner.metrics.economicUtility)
    XCTAssertEqual(
      report.selectionCriteria,
      ["quality_gate", "total_error", "economic_utility", "node_visits", "agent_id"]
    )
  }

  func testMovementTraceRecordsEveryCalculatorAndTransition() throws {
    let report = try NetworkReadingFixture.run()
    let winner = try XCTUnwrap(
      report.evaluations.first { $0.agent.id == report.winnerAgentID }
    )
    let firstCase = try XCTUnwrap(winner.traces.first { $0.caseID == "case.two" })

    XCTAssertEqual(firstCase.output, 3)
    XCTAssertEqual(firstCase.absoluteError, 0)
    XCTAssertEqual(firstCase.stopReason, .terminalNode)
    XCTAssertEqual(firstCase.steps.map(\.nodeID), ["entry", "double", "subtract-one"])
    XCTAssertEqual(firstCase.steps.map(\.input), [2, 2, 4])
    XCTAssertEqual(firstCase.steps.map(\.output), [2, 4, 3])
    XCTAssertEqual(firstCase.steps.compactMap(\.chosenSignal), ["growth", "refine"])
  }

  func testMutationInheritsSettingsAndChangesOneWeight() throws {
    let report = try NetworkReadingFixture.run()
    let parent = try XCTUnwrap(
      report.evaluations.first { $0.agent.id == "agent.scaling" }
    )
    let child = try XCTUnwrap(
      report.evaluations.first { $0.agent.id == "agent.scaling.refined" }
    )

    XCTAssertEqual(child.agent.parentID, parent.agent.id)
    XCTAssertEqual(child.agent.generation, parent.agent.generation + 1)
    XCTAssertEqual(child.agent.mutations, [ParameterMutation(signal: "refine", delta: 20)])
    XCTAssertEqual(child.agent.settings.stepLimit, parent.agent.settings.stepLimit)
    XCTAssertEqual(child.agent.settings.signalWeights["growth"], 10)
    XCTAssertEqual(child.agent.settings.signalWeights["finish"], 10)
    XCTAssertEqual(child.agent.settings.signalWeights["refine"], 20)
    XCTAssertEqual(parent.agent.settings.signalWeights["refine"], 0)
  }

  func testPopulationAndTraceBudgetsAreNeverExceeded() throws {
    let report = try NetworkReadingFixture.run()

    XCTAssertEqual(report.budget.maxAgents, 4)
    XCTAssertEqual(report.budget.maxBirths, 1)
    XCTAssertEqual(report.usage.evaluatedAgents, 4)
    XCTAssertEqual(report.usage.births, 1)
    XCTAssertEqual(report.usage.nodeVisits, 20)
    XCTAssertEqual(report.usage.traceSteps, 20)
    XCTAssertEqual(report.usage.graphWrites, 0)
    XCTAssertLessThanOrEqual(report.usage.evaluatedAgents, report.budget.maxAgents)
    XCTAssertLessThanOrEqual(report.usage.births, report.budget.maxBirths)
    XCTAssertLessThanOrEqual(report.usage.nodeVisits, report.budget.maxNodeVisits)
    XCTAssertLessThanOrEqual(report.usage.traceSteps, report.budget.maxTraceSteps)
    XCTAssertLessThanOrEqual(report.usage.graphWrites, report.budget.maxGraphWrites)
  }

  func testBaseNetworkMapRemainsByteStableAcrossSelection() throws {
    let network = try NetworkReadingFixture.network()
    let before = try network.sha256()
    let report = try NetworkReadingFixture.run(network: network)

    XCTAssertTrue(report.baseMapUnchanged)
    XCTAssertEqual(report.networkSHA256Before, before)
    XCTAssertEqual(report.networkSHA256After, before)
    XCTAssertEqual(try network.sha256(), before)
  }

  func testFixtureIsDeterministic() throws {
    XCTAssertEqual(try NetworkReadingFixture.run(), try NetworkReadingFixture.run())
  }

  func testPopulationLimitPreventsAdditionalBirth() throws {
    let network = try NetworkReadingFixture.network()
    let extraMutation = MutationPlan(
      childID: "agent.additive.refined",
      parentID: "agent.additive",
      mutation: ParameterMutation(signal: "refine", delta: 20)
    )
    let report = try RuntimeSelector.run(
      network: network,
      cases: NetworkReadingFixture.cases,
      initialAgents: NetworkReadingFixture.initialAgents,
      mutationPlans: NetworkReadingFixture.mutationPlans + [extraMutation],
      budget: NetworkReadingFixture.budget,
      utilityPolicy: NetworkReadingFixture.utilityPolicy
    )

    XCTAssertEqual(report.usage.evaluatedAgents, 4)
    XCTAssertEqual(report.usage.births, 1)
    XCTAssertEqual(report.skippedAgentIDs, ["agent.additive.refined"])
    XCTAssertFalse(report.evaluations.contains { $0.agent.id == "agent.additive.refined" })
  }

  func testRejectsNetworkWithMissingEdgeTarget() {
    XCTAssertThrowsError(
      try CalculatorNetwork(
        entryNodeID: "entry",
        nodes: [
          CalculatorNode(
            id: "entry",
            calculator: Calculator(kind: .identity, operand: 0),
            edges: [NetworkEdge(signal: "missing", targetNodeID: "absent")]
          )
        ]
      )
    ) { error in
      XCTAssertEqual(error as? NetworkEnvironmentError, .missingTargetNode("absent"))
    }
  }

  func testRejectsArithmeticOverflow() throws {
    let network = try CalculatorNetwork(
      entryNodeID: "overflow",
      nodes: [
        CalculatorNode(
          id: "overflow",
          calculator: Calculator(kind: .multiply, operand: 2),
          edges: []
        )
      ]
    )
    let agent = InterpreterAgent.root(
      id: "agent.overflow",
      settings: InterpretationSettings(signalWeights: [:], stepLimit: 1)
    )

    XCTAssertThrowsError(
      try AgentRuntime.evaluate(
        agent: agent,
        network: network,
        cases: [EvaluationCase(id: "overflow", input: Int.max, target: 0)],
        utilityPolicy: NetworkReadingFixture.utilityPolicy
      )
    ) { error in
      XCTAssertEqual(error as? NetworkEnvironmentError, .arithmeticOverflow)
    }
  }
}
