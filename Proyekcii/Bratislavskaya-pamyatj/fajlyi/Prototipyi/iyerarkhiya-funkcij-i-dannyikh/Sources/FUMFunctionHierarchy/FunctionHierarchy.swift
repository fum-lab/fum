public enum FunctionBody: String, Codable, Equatable, Sendable {
  case affine
  case quadratic

  fileprivate var complexity: Int {
    switch self {
    case .affine:
      1
    case .quadratic:
      2
    }
  }
}

public struct FunctionParameters: Codable, Equatable, Sendable {
  public let multiplier: Int
  public let bias: Int

  public init(multiplier: Int, bias: Int) {
    self.multiplier = multiplier
    self.bias = bias
  }
}

public struct LayerSnapshot: Codable, Equatable, Sendable {
  public let data: [Int]
  public let parameters: FunctionParameters
  public let body: FunctionBody
  public let revision: Int

  public init(
    data: [Int],
    parameters: FunctionParameters,
    body: FunctionBody,
    revision: Int
  ) {
    self.data = data
    self.parameters = parameters
    self.body = body
    self.revision = revision
  }
}

public struct ApplicationTrace: Codable, Equatable, Sendable {
  public let outputs: [Int]
  public let operationCost: Int

  public init(outputs: [Int], operationCost: Int) {
    self.outputs = outputs
    self.operationCost = operationCost
  }
}

public struct ObjectiveEvaluation: Codable, Equatable, Sendable {
  public let application: ApplicationTrace
  public let totalError: Int

  public init(application: ApplicationTrace, totalError: Int) {
    self.application = application
    self.totalError = totalError
  }
}

public enum ChangeAction: String, Codable, CaseIterable, Equatable, Sendable {
  case keep
  case updateData = "update_data"
  case changeParameters = "change_parameters"
  case replaceBody = "replace_body"

  fileprivate var stabilityRank: Int {
    switch self {
    case .keep:
      0
    case .updateData:
      1
    case .changeParameters:
      2
    case .replaceBody:
      3
    }
  }
}

public struct CandidateSpace: Codable, Equatable, Sendable {
  public let updatedData: [Int]
  public let updatedParameters: FunctionParameters
  public let replacementBody: FunctionBody

  public init(
    updatedData: [Int],
    updatedParameters: FunctionParameters,
    replacementBody: FunctionBody
  ) {
    self.updatedData = updatedData
    self.updatedParameters = updatedParameters
    self.replacementBody = replacementBody
  }
}

public struct HierarchyCandidate: Codable, Equatable, Sendable {
  public let id: String
  public let action: ChangeAction
  public let snapshot: LayerSnapshot

  public init(id: String, action: ChangeAction, snapshot: LayerSnapshot) {
    self.id = id
    self.action = action
    self.snapshot = snapshot
  }
}

public struct ChangeCostPolicy: Codable, Equatable, Sendable {
  public let dataChange: Int
  public let parameterChange: Int
  public let parameterInstability: Int
  public let bodyChange: Int
  public let bodyInstability: Int

  public init(
    dataChange: Int,
    parameterChange: Int,
    parameterInstability: Int,
    bodyChange: Int,
    bodyInstability: Int
  ) {
    self.dataChange = dataChange
    self.parameterChange = parameterChange
    self.parameterInstability = parameterInstability
    self.bodyChange = bodyChange
    self.bodyInstability = bodyInstability
  }

  public static let fixture = ChangeCostPolicy(
    dataChange: 1,
    parameterChange: 2,
    parameterInstability: 1,
    bodyChange: 4,
    bodyInstability: 2
  )
}

public struct CostBreakdown: Codable, Equatable, Sendable {
  public let change: Int
  public let instability: Int
  public let complexity: Int

  public var total: Int {
    change + instability + complexity
  }

  public init(change: Int, instability: Int, complexity: Int) {
    self.change = change
    self.instability = instability
    self.complexity = complexity
  }
}

public struct CandidateEvaluation: Codable, Equatable, Sendable {
  public let candidate: HierarchyCandidate
  public let outputs: [Int]
  public let totalError: Int
  public let applicationCost: Int
  public let cost: CostBreakdown
  public let benefit: Int
  public let utility: Int

  public init(
    candidate: HierarchyCandidate,
    outputs: [Int],
    totalError: Int,
    applicationCost: Int,
    cost: CostBreakdown,
    benefit: Int,
    utility: Int
  ) {
    self.candidate = candidate
    self.outputs = outputs
    self.totalError = totalError
    self.applicationCost = applicationCost
    self.cost = cost
    self.benefit = benefit
    self.utility = utility
  }

  public var action: ChangeAction {
    candidate.action
  }
}

public struct VerificationCase: Codable, Equatable, Sendable {
  public let data: [Int]
  public let expected: [Int]

  public init(data: [Int], expected: [Int]) {
    self.data = data
    self.expected = expected
  }
}

public struct VerificationTrace: Codable, Equatable, Sendable {
  public let baselineError: Int
  public let selectedError: Int
  public let passed: Bool
  public let reason: String

  public init(
    baselineError: Int,
    selectedError: Int,
    passed: Bool,
    reason: String
  ) {
    self.baselineError = baselineError
    self.selectedError = selectedError
    self.passed = passed
    self.reason = reason
  }
}

public enum CycleStage: String, Codable, Equatable, Sendable {
  case apply
  case evaluate
  case change
  case stabilize
}

public enum CycleOutcome: String, Codable, Equatable, Sendable {
  case kept
  case stabilized
  case rolledBack = "rolled_back"
}

public struct CycleTrace: Codable, Equatable, Sendable {
  public let stages: [CycleStage]
  public let baseline: CandidateEvaluation
  public let candidates: [CandidateEvaluation]
  public let selectedCandidateID: String
  public let selectedAction: ChangeAction
  public let verification: VerificationTrace?
  public let outcome: CycleOutcome

  public init(
    stages: [CycleStage],
    baseline: CandidateEvaluation,
    candidates: [CandidateEvaluation],
    selectedCandidateID: String,
    selectedAction: ChangeAction,
    verification: VerificationTrace?,
    outcome: CycleOutcome
  ) {
    self.stages = stages
    self.baseline = baseline
    self.candidates = candidates
    self.selectedCandidateID = selectedCandidateID
    self.selectedAction = selectedAction
    self.verification = verification
    self.outcome = outcome
  }
}

public struct CycleResult: Codable, Equatable, Sendable {
  public let initialSnapshot: LayerSnapshot
  public let finalSnapshot: LayerSnapshot
  public let trace: CycleTrace

  public init(
    initialSnapshot: LayerSnapshot,
    finalSnapshot: LayerSnapshot,
    trace: CycleTrace
  ) {
    self.initialSnapshot = initialSnapshot
    self.finalSnapshot = finalSnapshot
    self.trace = trace
  }
}

public enum HierarchyError: Error, Equatable, Sendable {
  case arithmeticOverflow
  case emptyObjective
  case objectiveCountMismatch
  case nonAtomicCandidate
  case verificationRequired
}

public enum CandidateGenerator {
  public static func generate(
    initial: LayerSnapshot,
    space: CandidateSpace
  ) throws -> [HierarchyCandidate] {
    let candidates = [
      HierarchyCandidate(id: "candidate.keep", action: .keep, snapshot: initial),
      HierarchyCandidate(
        id: "candidate.data",
        action: .updateData,
        snapshot: LayerSnapshot(
          data: space.updatedData,
          parameters: initial.parameters,
          body: initial.body,
          revision: initial.revision
        )
      ),
      HierarchyCandidate(
        id: "candidate.parameters",
        action: .changeParameters,
        snapshot: LayerSnapshot(
          data: initial.data,
          parameters: space.updatedParameters,
          body: initial.body,
          revision: initial.revision
        )
      ),
      HierarchyCandidate(
        id: "candidate.body",
        action: .replaceBody,
        snapshot: LayerSnapshot(
          data: initial.data,
          parameters: initial.parameters,
          body: space.replacementBody,
          revision: initial.revision
        )
      ),
    ]

    for candidate in candidates {
      try validate(candidate, relativeTo: initial)
    }
    return candidates
  }

  public static func validate(
    _ candidate: HierarchyCandidate,
    relativeTo initial: LayerSnapshot
  ) throws {
    let dataChanged = candidate.snapshot.data != initial.data
    let parametersChanged = candidate.snapshot.parameters != initial.parameters
    let bodyChanged = candidate.snapshot.body != initial.body
    let revisionChanged = candidate.snapshot.revision != initial.revision

    let valid: Bool
    switch candidate.action {
    case .keep:
      valid = !dataChanged && !parametersChanged && !bodyChanged && !revisionChanged
    case .updateData:
      valid = dataChanged && !parametersChanged && !bodyChanged && !revisionChanged
    case .changeParameters:
      valid = !dataChanged && parametersChanged && !bodyChanged && !revisionChanged
    case .replaceBody:
      valid = !dataChanged && !parametersChanged && bodyChanged && !revisionChanged
    }

    guard valid else {
      throw HierarchyError.nonAtomicCandidate
    }
  }
}

public enum MetaSelector {
  public static func select(_ candidates: [CandidateEvaluation]) -> CandidateEvaluation {
    candidates.sorted { left, right in
      if left.utility != right.utility {
        return left.utility > right.utility
      }
      if left.action.stabilityRank != right.action.stabilityRank {
        return left.action.stabilityRank < right.action.stabilityRank
      }
      return left.candidate.id < right.candidate.id
    }.first!
  }
}

public enum HierarchyCycle {
  public static func apply(_ snapshot: LayerSnapshot) throws -> ApplicationTrace {
    var outputs: [Int] = []
    outputs.reserveCapacity(snapshot.data.count)
    var operationCost = 0

    for input in snapshot.data {
      let output: Int
      let itemCost: Int
      switch snapshot.body {
      case .affine:
        let multiplied = try safeMultiply(input, snapshot.parameters.multiplier)
        output = try safeAdd(multiplied, snapshot.parameters.bias)
        itemCost = 2
      case .quadratic:
        let squared = try safeMultiply(input, input)
        let multiplied = try safeMultiply(squared, snapshot.parameters.multiplier)
        output = try safeAdd(multiplied, snapshot.parameters.bias)
        itemCost = 3
      }
      outputs.append(output)
      operationCost = try safeAdd(operationCost, itemCost)
    }

    return ApplicationTrace(outputs: outputs, operationCost: operationCost)
  }

  public static func evaluate(
    _ snapshot: LayerSnapshot,
    expected: [Int]
  ) throws -> ObjectiveEvaluation {
    guard !expected.isEmpty else {
      throw HierarchyError.emptyObjective
    }
    guard snapshot.data.count == expected.count else {
      throw HierarchyError.objectiveCountMismatch
    }

    let application = try apply(snapshot)
    var totalError = 0
    for (output, target) in zip(application.outputs, expected) {
      totalError = try safeAdd(totalError, try absoluteDifference(output, target))
    }
    return ObjectiveEvaluation(application: application, totalError: totalError)
  }

  public static func run(
    initial: LayerSnapshot,
    expected: [Int],
    candidates candidateSpace: CandidateSpace,
    verification: [VerificationCase],
    policy: ChangeCostPolicy
  ) throws -> CycleResult {
    guard !verification.isEmpty else {
      throw HierarchyError.verificationRequired
    }

    let baselineObjective = try evaluate(initial, expected: expected)
    let baselineCandidate = HierarchyCandidate(
      id: "baseline",
      action: .keep,
      snapshot: initial
    )
    let zeroCost = CostBreakdown(change: 0, instability: 0, complexity: 0)
    let baselineTrace = CandidateEvaluation(
      candidate: baselineCandidate,
      outputs: baselineObjective.application.outputs,
      totalError: baselineObjective.totalError,
      applicationCost: baselineObjective.application.operationCost,
      cost: zeroCost,
      benefit: 0,
      utility: 0
    )

    let generated = try CandidateGenerator.generate(initial: initial, space: candidateSpace)
    let evaluated = try generated.map { candidate in
      try evaluateCandidate(
        candidate,
        expected: expected,
        baselineError: baselineObjective.totalError,
        initial: initial,
        policy: policy
      )
    }
    let selected = MetaSelector.select(evaluated)

    let verificationTrace: VerificationTrace?
    let finalSnapshot: LayerSnapshot
    let outcome: CycleOutcome

    if selected.action == .keep || selected.utility <= 0 {
      verificationTrace = nil
      finalSnapshot = initial
      outcome = .kept
    } else {
      let checked = try verify(
        selected: selected.candidate.snapshot,
        against: initial,
        cases: verification
      )
      verificationTrace = checked
      if checked.passed {
        finalSnapshot = LayerSnapshot(
          data: selected.candidate.snapshot.data,
          parameters: selected.candidate.snapshot.parameters,
          body: selected.candidate.snapshot.body,
          revision: try safeAdd(initial.revision, 1)
        )
        outcome = .stabilized
      } else {
        finalSnapshot = initial
        outcome = .rolledBack
      }
    }

    let trace = CycleTrace(
      stages: [.apply, .evaluate, .change, .stabilize],
      baseline: baselineTrace,
      candidates: evaluated,
      selectedCandidateID: selected.candidate.id,
      selectedAction: selected.action,
      verification: verificationTrace,
      outcome: outcome
    )
    return CycleResult(
      initialSnapshot: initial,
      finalSnapshot: finalSnapshot,
      trace: trace
    )
  }

  private static func evaluateCandidate(
    _ candidate: HierarchyCandidate,
    expected: [Int],
    baselineError: Int,
    initial: LayerSnapshot,
    policy: ChangeCostPolicy
  ) throws -> CandidateEvaluation {
    try CandidateGenerator.validate(candidate, relativeTo: initial)
    let objective = try evaluate(candidate.snapshot, expected: expected)
    let cost = cost(for: candidate, relativeTo: initial, policy: policy)
    let benefit = try safeSubtract(baselineError, objective.totalError)
    let utility = try safeSubtract(benefit, cost.total)
    return CandidateEvaluation(
      candidate: candidate,
      outputs: objective.application.outputs,
      totalError: objective.totalError,
      applicationCost: objective.application.operationCost,
      cost: cost,
      benefit: benefit,
      utility: utility
    )
  }

  private static func cost(
    for candidate: HierarchyCandidate,
    relativeTo initial: LayerSnapshot,
    policy: ChangeCostPolicy
  ) -> CostBreakdown {
    switch candidate.action {
    case .keep:
      CostBreakdown(change: 0, instability: 0, complexity: 0)
    case .updateData:
      CostBreakdown(change: policy.dataChange, instability: 0, complexity: 0)
    case .changeParameters:
      CostBreakdown(
        change: policy.parameterChange,
        instability: policy.parameterInstability,
        complexity: 0
      )
    case .replaceBody:
      CostBreakdown(
        change: policy.bodyChange,
        instability: policy.bodyInstability,
        complexity: max(0, candidate.snapshot.body.complexity - initial.body.complexity)
      )
    }
  }

  private static func verify(
    selected: LayerSnapshot,
    against initial: LayerSnapshot,
    cases: [VerificationCase]
  ) throws -> VerificationTrace {
    var baselineError = 0
    var selectedError = 0

    for verificationCase in cases {
      let baselineSnapshot = LayerSnapshot(
        data: verificationCase.data,
        parameters: initial.parameters,
        body: initial.body,
        revision: initial.revision
      )
      let selectedSnapshot = LayerSnapshot(
        data: verificationCase.data,
        parameters: selected.parameters,
        body: selected.body,
        revision: selected.revision
      )
      let baselineEvaluation = try evaluate(
        baselineSnapshot,
        expected: verificationCase.expected
      )
      let selectedEvaluation = try evaluate(
        selectedSnapshot,
        expected: verificationCase.expected
      )
      baselineError = try safeAdd(baselineError, baselineEvaluation.totalError)
      selectedError = try safeAdd(selectedError, selectedEvaluation.totalError)
    }

    let passed = selectedError <= baselineError
    return VerificationTrace(
      baselineError: baselineError,
      selectedError: selectedError,
      passed: passed,
      reason: passed ? "no_verification_regression" : "verification_regression"
    )
  }

  private static func safeAdd(_ left: Int, _ right: Int) throws -> Int {
    let result = left.addingReportingOverflow(right)
    guard !result.overflow else {
      throw HierarchyError.arithmeticOverflow
    }
    return result.partialValue
  }

  private static func safeSubtract(_ left: Int, _ right: Int) throws -> Int {
    let result = left.subtractingReportingOverflow(right)
    guard !result.overflow else {
      throw HierarchyError.arithmeticOverflow
    }
    return result.partialValue
  }

  private static func safeMultiply(_ left: Int, _ right: Int) throws -> Int {
    let result = left.multipliedReportingOverflow(by: right)
    guard !result.overflow else {
      throw HierarchyError.arithmeticOverflow
    }
    return result.partialValue
  }

  private static func absoluteDifference(_ left: Int, _ right: Int) throws -> Int {
    let difference = try safeSubtract(left, right)
    guard difference != Int.min else {
      throw HierarchyError.arithmeticOverflow
    }
    return Swift.abs(difference)
  }
}
