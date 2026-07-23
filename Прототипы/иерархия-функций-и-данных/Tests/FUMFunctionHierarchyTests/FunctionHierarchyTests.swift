import XCTest

@testable import FUMFunctionHierarchy

final class FunctionHierarchyTests: XCTestCase {
  func testApplyIsPureAndDeterministic() throws {
    let initial = snapshot(data: [1, 2, 3], multiplier: 2)

    let first = try HierarchyCycle.apply(initial)
    let second = try HierarchyCycle.apply(initial)

    XCTAssertEqual(first, second)
    XCTAssertEqual(first.outputs, [2, 4, 6])
    XCTAssertEqual(first.operationCost, 6)
    XCTAssertEqual(initial, snapshot(data: [1, 2, 3], multiplier: 2))
  }

  func testTraceRecordsErrorCostBenefitAndUtility() throws {
    let result = try runCycle(
      initial: snapshot(data: [1, 2, 3], multiplier: 2),
      expected: [3, 6, 9],
      updatedData: [1, 2, 4],
      updatedParameters: FunctionParameters(multiplier: 3, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [4, 5], expected: [12, 15])]
    )

    let parameterTrace = try XCTUnwrap(
      result.trace.candidates.first { $0.action == .changeParameters }
    )
    XCTAssertEqual(parameterTrace.totalError, 0)
    XCTAssertEqual(parameterTrace.applicationCost, 6)
    XCTAssertEqual(parameterTrace.cost, CostBreakdown(change: 2, instability: 1, complexity: 0))
    XCTAssertEqual(parameterTrace.benefit, 6)
    XCTAssertEqual(parameterTrace.utility, 3)
    XCTAssertEqual(
      result.trace.stages,
      [.apply, .evaluate, .change, .stabilize]
    )
  }

  func testKeepsExactLayerWhenNoChangeHasPositiveUtility() throws {
    let initial = snapshot(data: [1, 2, 3], multiplier: 2, revision: 7)
    let result = try runCycle(
      initial: initial,
      expected: [2, 4, 6],
      updatedData: [1, 2, 4],
      updatedParameters: FunctionParameters(multiplier: 3, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [4], expected: [8])]
    )

    XCTAssertEqual(result.trace.selectedAction, .keep)
    XCTAssertEqual(result.trace.outcome, .kept)
    XCTAssertEqual(result.finalSnapshot, initial)
    XCTAssertNil(result.trace.verification)
  }

  func testChoosesDataUpdateForAnIsolatedInputCorrection() throws {
    let initial = snapshot(data: [1, 2, 30], multiplier: 2)
    let result = try runCycle(
      initial: initial,
      expected: [2, 4, 6],
      updatedData: [1, 2, 3],
      updatedParameters: FunctionParameters(multiplier: 1, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [4], expected: [8])]
    )

    XCTAssertEqual(result.trace.selectedAction, .updateData)
    XCTAssertEqual(result.trace.outcome, .stabilized)
    XCTAssertEqual(result.finalSnapshot.data, [1, 2, 3])
    XCTAssertEqual(result.finalSnapshot.parameters, initial.parameters)
    XCTAssertEqual(result.finalSnapshot.body, initial.body)
    XCTAssertEqual(result.finalSnapshot.revision, 2)
  }

  func testChoosesParameterChangeForAReusableScaleCorrection() throws {
    let initial = snapshot(data: [1, 2, 3], multiplier: 2)
    let result = try runCycle(
      initial: initial,
      expected: [3, 6, 9],
      updatedData: [1, 2, 4],
      updatedParameters: FunctionParameters(multiplier: 3, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [4, 5], expected: [12, 15])]
    )

    XCTAssertEqual(result.trace.selectedAction, .changeParameters)
    XCTAssertEqual(result.trace.outcome, .stabilized)
    XCTAssertEqual(result.finalSnapshot.data, initial.data)
    XCTAssertEqual(result.finalSnapshot.parameters.multiplier, 3)
    XCTAssertEqual(result.finalSnapshot.body, .affine)
  }

  func testChoosesBodyReplacementOnlyWhenItsDeeperCostIsCovered() throws {
    let initial = snapshot(data: [2, 4, 6], multiplier: 1)
    let result = try runCycle(
      initial: initial,
      expected: [4, 16, 36],
      updatedData: [2, 4, 5],
      updatedParameters: FunctionParameters(multiplier: 2, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [3, 5], expected: [9, 25])]
    )

    XCTAssertEqual(result.trace.selectedAction, .replaceBody)
    XCTAssertEqual(result.trace.outcome, .stabilized)
    XCTAssertEqual(result.finalSnapshot.data, initial.data)
    XCTAssertEqual(result.finalSnapshot.parameters, initial.parameters)
    XCTAssertEqual(result.finalSnapshot.body, .quadratic)
  }

  func testEconomyCanPreferParametersOverLowerRawBodyError() throws {
    let result = try runCycle(
      initial: snapshot(data: [2, 3], multiplier: 1),
      expected: [4, 8],
      updatedData: [2, 4],
      updatedParameters: FunctionParameters(multiplier: 2, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [4], expected: [8])]
    )

    let parameterTrace = try XCTUnwrap(
      result.trace.candidates.first { $0.action == .changeParameters }
    )
    let bodyTrace = try XCTUnwrap(
      result.trace.candidates.first { $0.action == .replaceBody }
    )
    XCTAssertLessThan(bodyTrace.totalError, parameterTrace.totalError)
    XCTAssertGreaterThan(parameterTrace.utility, bodyTrace.utility)
    XCTAssertEqual(result.trace.selectedAction, .changeParameters)
  }

  func testRollsBackSelectedBodyWhenIndependentVerificationRegresses() throws {
    let initial = snapshot(data: [2, 4, 6], multiplier: 1, revision: 9)
    let result = try runCycle(
      initial: initial,
      expected: [4, 16, 36],
      updatedData: [2, 4, 5],
      updatedParameters: FunctionParameters(multiplier: 2, bias: 0),
      replacementBody: .quadratic,
      verification: [VerificationCase(data: [5, 7], expected: [5, 7])]
    )

    XCTAssertEqual(result.trace.selectedAction, .replaceBody)
    XCTAssertEqual(result.trace.outcome, .rolledBack)
    XCTAssertEqual(result.finalSnapshot, initial)
    XCTAssertEqual(result.trace.verification?.passed, false)
    XCTAssertEqual(result.trace.verification?.baselineError, 0)
    XCTAssertEqual(result.trace.verification?.selectedError, 62)
  }

  func testRejectsCandidateThatChangesMoreThanItsDeclaredLayer() {
    let initial = snapshot(data: [1, 2], multiplier: 1)
    let candidate = HierarchyCandidate(
      id: "tampered-parameters",
      action: .changeParameters,
      snapshot: LayerSnapshot(
        data: [9, 9],
        parameters: FunctionParameters(multiplier: 2, bias: 0),
        body: .quadratic,
        revision: 1
      )
    )

    XCTAssertThrowsError(try CandidateGenerator.validate(candidate, relativeTo: initial)) { error in
      XCTAssertEqual(error as? HierarchyError, .nonAtomicCandidate)
    }
  }

  func testTieIsDeterministicAndPrefersTheFasterChangingLayer() throws {
    let arguments = (
      initial: snapshot(data: [1], multiplier: 1),
      expected: [10],
      updatedData: [3],
      updatedParameters: FunctionParameters(multiplier: 5, bias: 0),
      replacementBody: FunctionBody.quadratic,
      verification: [VerificationCase(data: [2], expected: [2])]
    )

    let first = try runCycle(
      initial: arguments.initial,
      expected: arguments.expected,
      updatedData: arguments.updatedData,
      updatedParameters: arguments.updatedParameters,
      replacementBody: arguments.replacementBody,
      verification: arguments.verification
    )
    let second = try runCycle(
      initial: arguments.initial,
      expected: arguments.expected,
      updatedData: arguments.updatedData,
      updatedParameters: arguments.updatedParameters,
      replacementBody: arguments.replacementBody,
      verification: arguments.verification
    )

    let dataUtility = first.trace.candidates.first { $0.action == .updateData }?.utility
    let parameterUtility = first.trace.candidates.first {
      $0.action == .changeParameters
    }?.utility
    XCTAssertEqual(dataUtility, parameterUtility)
    XCTAssertEqual(first.trace.selectedAction, .updateData)
    XCTAssertEqual(first, second)
  }

  func testRejectsMismatchedObjectiveLength() {
    XCTAssertThrowsError(
      try HierarchyCycle.evaluate(
        snapshot(data: [1, 2], multiplier: 1),
        expected: [1]
      )
    ) { error in
      XCTAssertEqual(error as? HierarchyError, .objectiveCountMismatch)
    }
  }

  func testRejectsArithmeticOverflow() {
    XCTAssertThrowsError(
      try HierarchyCycle.apply(snapshot(data: [Int.max], multiplier: 2))
    ) { error in
      XCTAssertEqual(error as? HierarchyError, .arithmeticOverflow)
    }
  }

  private func runCycle(
    initial: LayerSnapshot,
    expected: [Int],
    updatedData: [Int],
    updatedParameters: FunctionParameters,
    replacementBody: FunctionBody,
    verification: [VerificationCase]
  ) throws -> CycleResult {
    try HierarchyCycle.run(
      initial: initial,
      expected: expected,
      candidates: CandidateSpace(
        updatedData: updatedData,
        updatedParameters: updatedParameters,
        replacementBody: replacementBody
      ),
      verification: verification,
      policy: .fixture
    )
  }

  private func snapshot(
    data: [Int],
    multiplier: Int,
    bias: Int = 0,
    body: FunctionBody = .affine,
    revision: Int = 1
  ) -> LayerSnapshot {
    LayerSnapshot(
      data: data,
      parameters: FunctionParameters(multiplier: multiplier, bias: bias),
      body: body,
      revision: revision
    )
  }
}
