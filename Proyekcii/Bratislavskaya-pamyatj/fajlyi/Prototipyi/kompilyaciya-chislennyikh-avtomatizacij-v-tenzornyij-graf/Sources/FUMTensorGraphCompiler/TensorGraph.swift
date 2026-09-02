import Foundation

public enum TensorGraphError: Error, Equatable, Sendable {
  case unsupportedSchemaVersion(Int)
  case invalidIdentifier(String)
  case invalidShape([Int])
  case shapeElementCountOverflow([Int])
  case emptyInputs
  case emptyOperations
  case duplicateValueName(String)
  case unknownValueReference(String)
  case operandTypeMismatch(operation: String, left: String, right: String)
  case unknownOutput(String)
  case duplicateArgument(String)
  case unexpectedArgument(String)
  case missingArgument(String)
  case argumentElementCount(argument: String, expected: Int, actual: Int)
  case valueElementCount(value: String, expected: Int, actual: Int)
  case nonFiniteValue(argument: String, index: Int)
  case nonFiniteResult(operation: String, index: Int)
  case directReferenceTypeMismatch
  case malformedTypedGraph
  case comparisonTypeMismatch
  case invalidComparisonTolerance
  case invalidBenchmarkPlan
  case benchmarkLimitExceeded(String)
  case fixtureMismatch
}

public struct TypedGraphValue: Equatable, Sendable {
  public let name: String
  public let type: TensorType
}

public struct TypedGraphOperation: Equatable, Sendable {
  public let result: String
  public let operation: TensorOperationKind
  public let left: String
  public let right: String
  public let type: TensorType
}

public struct TypedTensorGraph: Equatable, Sendable {
  public let functionName: String
  public let inputs: [TypedGraphValue]
  public let operations: [TypedGraphOperation]
  public let output: TypedGraphValue
}

public enum TensorGraphCompiler {
  private static let maximumRank = 8
  private static let maximumElements = 16_777_216

  public static func compile(_ function: NumericalFunction) throws -> TypedTensorGraph {
    guard isIdentifier(function.name) else {
      throw TensorGraphError.invalidIdentifier(function.name)
    }
    guard !function.inputs.isEmpty else {
      throw TensorGraphError.emptyInputs
    }
    guard !function.operations.isEmpty else {
      throw TensorGraphError.emptyOperations
    }

    var values: [String: TensorType] = [:]
    var typedInputs: [TypedGraphValue] = []
    for input in function.inputs {
      try validateIdentifier(input.name)
      try validate(type: input.type)
      guard values[input.name] == nil else {
        throw TensorGraphError.duplicateValueName(input.name)
      }
      values[input.name] = input.type
      typedInputs.append(TypedGraphValue(name: input.name, type: input.type))
    }

    var typedOperations: [TypedGraphOperation] = []
    for operation in function.operations {
      try validateIdentifier(operation.result)
      guard values[operation.result] == nil else {
        throw TensorGraphError.duplicateValueName(operation.result)
      }
      guard let leftType = values[operation.left] else {
        throw TensorGraphError.unknownValueReference(operation.left)
      }
      guard let rightType = values[operation.right] else {
        throw TensorGraphError.unknownValueReference(operation.right)
      }
      guard leftType == rightType else {
        throw TensorGraphError.operandTypeMismatch(
          operation: operation.result,
          left: operation.left,
          right: operation.right
        )
      }
      let typed = TypedGraphOperation(
        result: operation.result,
        operation: operation.operation,
        left: operation.left,
        right: operation.right,
        type: leftType
      )
      typedOperations.append(typed)
      values[operation.result] = leftType
    }

    guard let outputType = values[function.output] else {
      throw TensorGraphError.unknownOutput(function.output)
    }
    return TypedTensorGraph(
      functionName: function.name,
      inputs: typedInputs,
      operations: typedOperations,
      output: TypedGraphValue(name: function.output, type: outputType)
    )
  }

  public static func elementCount(of type: TensorType) throws -> Int {
    try validate(type: type)
    var count = 1
    for dimension in type.shape {
      let result = count.multipliedReportingOverflow(by: dimension)
      guard !result.overflow, result.partialValue <= maximumElements else {
        throw TensorGraphError.shapeElementCountOverflow(type.shape)
      }
      count = result.partialValue
    }
    return count
  }

  private static func validate(type: TensorType) throws {
    guard type.element == .f32,
      !type.shape.isEmpty,
      type.shape.count <= maximumRank,
      type.shape.allSatisfy({ $0 > 0 })
    else {
      throw TensorGraphError.invalidShape(type.shape)
    }
    _ = try elementCountWithoutRecursiveValidation(of: type)
  }

  private static func elementCountWithoutRecursiveValidation(of type: TensorType) throws -> Int {
    var count = 1
    for dimension in type.shape {
      let result = count.multipliedReportingOverflow(by: dimension)
      guard !result.overflow, result.partialValue <= maximumElements else {
        throw TensorGraphError.shapeElementCountOverflow(type.shape)
      }
      count = result.partialValue
    }
    return count
  }

  private static func validateIdentifier(_ value: String) throws {
    guard isIdentifier(value) else {
      throw TensorGraphError.invalidIdentifier(value)
    }
  }

  private static func isIdentifier(_ value: String) -> Bool {
    guard let first = value.utf8.first,
      (Character("a").asciiValue!...Character("z").asciiValue!).contains(first)
    else {
      return false
    }
    return value.utf8.dropFirst().allSatisfy { byte in
      (Character("a").asciiValue!...Character("z").asciiValue!).contains(byte)
        || (Character("0").asciiValue!...Character("9").asciiValue!).contains(byte)
        || byte == Character("_").asciiValue!
    }
  }
}

public struct TensorValue: Codable, Equatable, Sendable {
  public let type: TensorType
  public let values: [Float]

  public init(type: TensorType, values: [Float]) {
    self.type = type
    self.values = values
  }
}

enum TensorValueValidation {
  static func validate(_ value: TensorValue, name: String) throws {
    let expectedCount = try TensorGraphCompiler.elementCount(of: value.type)
    guard value.values.count == expectedCount else {
      throw TensorGraphError.valueElementCount(
        value: name,
        expected: expectedCount,
        actual: value.values.count
      )
    }
    for (index, element) in value.values.enumerated() where !element.isFinite {
      throw TensorGraphError.nonFiniteValue(argument: name, index: index)
    }
  }
}

public enum ScenarioArguments {
  public static func bind(
    _ arguments: [TensorArgument],
    to inputs: [TypedGraphValue]
  ) throws -> [String: TensorValue] {
    let expectedNames = Set(inputs.map(\.name))
    var bound: [String: TensorValue] = [:]
    for argument in arguments {
      guard bound[argument.name] == nil else {
        throw TensorGraphError.duplicateArgument(argument.name)
      }
      guard expectedNames.contains(argument.name) else {
        throw TensorGraphError.unexpectedArgument(argument.name)
      }
      guard let input = inputs.first(where: { $0.name == argument.name }) else {
        throw TensorGraphError.unexpectedArgument(argument.name)
      }
      let expectedCount = try TensorGraphCompiler.elementCount(of: input.type)
      guard argument.values.count == expectedCount else {
        throw TensorGraphError.argumentElementCount(
          argument: argument.name,
          expected: expectedCount,
          actual: argument.values.count
        )
      }
      for (index, value) in argument.values.enumerated() where !value.isFinite {
        throw TensorGraphError.nonFiniteValue(argument: argument.name, index: index)
      }
      let tensor = TensorValue(type: input.type, values: argument.values)
      try TensorValueValidation.validate(tensor, name: argument.name)
      bound[argument.name] = tensor
    }
    for input in inputs where bound[input.name] == nil {
      throw TensorGraphError.missingArgument(input.name)
    }
    return bound
  }
}

public enum DirectCPUReference {
  public static func mulAdd(
    left: TensorValue,
    right: TensorValue,
    bias: TensorValue
  ) throws -> TensorValue {
    guard left.type == right.type, left.type == bias.type else {
      throw TensorGraphError.directReferenceTypeMismatch
    }
    try TensorValueValidation.validate(left, name: "left")
    try TensorValueValidation.validate(right, name: "right")
    try TensorValueValidation.validate(bias, name: "bias")
    var output: [Float] = []
    output.reserveCapacity(left.values.count)
    for index in left.values.indices {
      let value = left.values[index] * right.values[index] + bias.values[index]
      guard value.isFinite else {
        throw TensorGraphError.nonFiniteResult(operation: "direct_mul_add", index: index)
      }
      output.append(value)
    }
    return TensorValue(type: left.type, values: output)
  }
}

public enum TypedGraphExecutor {
  public static func execute(
    _ graph: TypedTensorGraph,
    arguments: [String: TensorValue]
  ) throws -> TensorValue {
    try validate(graph)
    var values = arguments
    let inputNames = Set(graph.inputs.map(\.name))
    if let unexpected = Set(arguments.keys).subtracting(inputNames).sorted().first {
      throw TensorGraphError.unexpectedArgument(unexpected)
    }
    for input in graph.inputs {
      guard let argument = arguments[input.name] else {
        throw TensorGraphError.missingArgument(input.name)
      }
      guard argument.type == input.type else {
        throw TensorGraphError.directReferenceTypeMismatch
      }
      try TensorValueValidation.validate(argument, name: input.name)
    }

    for operation in graph.operations {
      guard let left = values[operation.left] else {
        throw TensorGraphError.unknownValueReference(operation.left)
      }
      guard let right = values[operation.right] else {
        throw TensorGraphError.unknownValueReference(operation.right)
      }
      try TensorValueValidation.validate(left, name: operation.left)
      try TensorValueValidation.validate(right, name: operation.right)
      var result: [Float] = []
      result.reserveCapacity(left.values.count)
      for index in left.values.indices {
        let value: Float
        switch operation.operation {
        case .add:
          value = left.values[index] + right.values[index]
        case .multiply:
          value = left.values[index] * right.values[index]
        }
        guard value.isFinite else {
          throw TensorGraphError.nonFiniteResult(operation: operation.result, index: index)
        }
        result.append(value)
      }
      values[operation.result] = TensorValue(type: operation.type, values: result)
    }
    guard let output = values[graph.output.name] else {
      throw TensorGraphError.unknownOutput(graph.output.name)
    }
    try TensorValueValidation.validate(output, name: graph.output.name)
    return output
  }

  private static func validate(_ graph: TypedTensorGraph) throws {
    let function = NumericalFunction(
      name: graph.functionName,
      inputs: graph.inputs.map { TensorInput(name: $0.name, type: $0.type) },
      operations: graph.operations.map {
        TensorOperation(
          result: $0.result,
          operation: $0.operation,
          left: $0.left,
          right: $0.right
        )
      },
      output: graph.output.name
    )
    guard try TensorGraphCompiler.compile(function) == graph else {
      throw TensorGraphError.malformedTypedGraph
    }
  }
}

public struct TensorComparisonReport: Codable, Equatable, Sendable {
  public let equivalent: Bool
  public let maximumAbsoluteDifference: Float
  public let absoluteTolerance: Float
  public let relativeTolerance: Float

  enum CodingKeys: String, CodingKey {
    case equivalent
    case maximumAbsoluteDifference = "maximum_absolute_difference"
    case absoluteTolerance = "absolute_tolerance"
    case relativeTolerance = "relative_tolerance"
  }

  public init(
    equivalent: Bool,
    maximumAbsoluteDifference: Float,
    absoluteTolerance: Float,
    relativeTolerance: Float
  ) {
    self.equivalent = equivalent
    self.maximumAbsoluteDifference = maximumAbsoluteDifference
    self.absoluteTolerance = absoluteTolerance
    self.relativeTolerance = relativeTolerance
  }
}

public enum TensorComparison {
  public static func compare(
    _ left: TensorValue,
    _ right: TensorValue,
    absoluteTolerance: Float = 0.000_001,
    relativeTolerance: Float = 0.000_001
  ) throws -> TensorComparisonReport {
    guard absoluteTolerance.isFinite,
      relativeTolerance.isFinite,
      absoluteTolerance >= 0,
      relativeTolerance >= 0
    else {
      throw TensorGraphError.invalidComparisonTolerance
    }
    guard left.type == right.type else {
      throw TensorGraphError.comparisonTypeMismatch
    }
    try TensorValueValidation.validate(left, name: "comparison_left")
    try TensorValueValidation.validate(right, name: "comparison_right")
    var maximumDifference: Float = 0
    var equivalent = true
    for index in left.values.indices {
      let difference = abs(left.values[index] - right.values[index])
      maximumDifference = max(maximumDifference, difference)
      let scale = max(abs(left.values[index]), abs(right.values[index]))
      if difference > absoluteTolerance + relativeTolerance * scale {
        equivalent = false
      }
    }
    return TensorComparisonReport(
      equivalent: equivalent,
      maximumAbsoluteDifference: maximumDifference,
      absoluteTolerance: absoluteTolerance,
      relativeTolerance: relativeTolerance
    )
  }
}
