import Foundation

public enum TensorElementType: String, Codable, Equatable, Sendable {
  case f32
}

public struct TensorType: Codable, Equatable, Sendable {
  public let element: TensorElementType
  public let shape: [Int]

  public init(element: TensorElementType, shape: [Int]) {
    self.element = element
    self.shape = shape
  }

  public static func f32(shape: [Int]) -> TensorType {
    TensorType(element: .f32, shape: shape)
  }
}

public struct TensorInput: Codable, Equatable, Sendable {
  public let name: String
  public let type: TensorType

  public init(name: String, type: TensorType) {
    self.name = name
    self.type = type
  }
}

public enum TensorOperationKind: String, Codable, Equatable, Sendable {
  case add
  case multiply
}

public struct TensorOperation: Codable, Equatable, Sendable {
  public let result: String
  public let operation: TensorOperationKind
  public let left: String
  public let right: String

  public init(
    result: String,
    operation: TensorOperationKind,
    left: String,
    right: String
  ) {
    self.result = result
    self.operation = operation
    self.left = left
    self.right = right
  }

  enum CodingKeys: String, CodingKey {
    case result
    case operation = "op"
    case left
    case right
  }
}

public struct NumericalFunction: Codable, Equatable, Sendable {
  public let name: String
  public let inputs: [TensorInput]
  public let operations: [TensorOperation]
  public let output: String

  public init(
    name: String,
    inputs: [TensorInput],
    operations: [TensorOperation],
    output: String
  ) {
    self.name = name
    self.inputs = inputs
    self.operations = operations
    self.output = output
  }
}

public struct TensorArgument: Codable, Equatable, Sendable {
  public let name: String
  public let values: [Float]

  public init(name: String, values: [Float]) {
    self.name = name
    self.values = values
  }
}

public struct NumericalScenario: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let scenarioID: String
  public let function: NumericalFunction
  public let arguments: [TensorArgument]

  public init(
    schemaVersion: Int,
    scenarioID: String,
    function: NumericalFunction,
    arguments: [TensorArgument]
  ) {
    self.schemaVersion = schemaVersion
    self.scenarioID = scenarioID
    self.function = function
    self.arguments = arguments
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case scenarioID = "scenario_id"
    case function
    case arguments
  }
}

public enum ScenarioJSONError: Error, Equatable, Sendable {
  case invalidJSON
  case expectedObject(String)
  case unknownField(String)
}

public enum ScenarioJSON {
  public static func decode(_ data: Data) throws -> NumericalScenario {
    let raw: Any
    do {
      raw = try JSONSerialization.jsonObject(with: data)
    } catch {
      throw ScenarioJSONError.invalidJSON
    }
    try validateStructure(raw)

    let scenario: NumericalScenario
    do {
      scenario = try JSONDecoder().decode(NumericalScenario.self, from: data)
    } catch {
      throw ScenarioJSONError.invalidJSON
    }
    guard scenario.schemaVersion == 1 else {
      throw TensorGraphError.unsupportedSchemaVersion(scenario.schemaVersion)
    }
    let graph = try TensorGraphCompiler.compile(scenario.function)
    _ = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    return scenario
  }

  public static func encodeCanonical(_ scenario: NumericalScenario) throws -> Data {
    guard scenario.schemaVersion == 1 else {
      throw TensorGraphError.unsupportedSchemaVersion(scenario.schemaVersion)
    }
    let graph = try TensorGraphCompiler.compile(scenario.function)
    _ = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    return try CanonicalJSON.encode(scenario)
  }

  private static func validateStructure(_ raw: Any) throws {
    let scenario = try requireObject(raw, path: "scenario")
    try requireExactKeys(
      scenario,
      expected: ["schema_version", "scenario_id", "function", "arguments"],
      path: "scenario"
    )

    let function = try requireObject(scenario["function"], path: "scenario.function")
    try requireExactKeys(
      function,
      expected: ["name", "inputs", "operations", "output"],
      path: "scenario.function"
    )

    guard let inputs = function["inputs"] as? [Any] else {
      throw ScenarioJSONError.invalidJSON
    }
    for (index, rawInput) in inputs.enumerated() {
      let path = "scenario.function.inputs[\(index)]"
      let input = try requireObject(rawInput, path: path)
      try requireExactKeys(input, expected: ["name", "type"], path: path)
      let typePath = "\(path).type"
      let type = try requireObject(input["type"], path: typePath)
      try requireExactKeys(type, expected: ["element", "shape"], path: typePath)
    }

    guard let operations = function["operations"] as? [Any] else {
      throw ScenarioJSONError.invalidJSON
    }
    for (index, rawOperation) in operations.enumerated() {
      let path = "scenario.function.operations[\(index)]"
      let operation = try requireObject(rawOperation, path: path)
      try requireExactKeys(
        operation,
        expected: ["result", "op", "left", "right"],
        path: path
      )
    }

    guard let arguments = scenario["arguments"] as? [Any] else {
      throw ScenarioJSONError.invalidJSON
    }
    for (index, rawArgument) in arguments.enumerated() {
      let path = "scenario.arguments[\(index)]"
      let argument = try requireObject(rawArgument, path: path)
      try requireExactKeys(argument, expected: ["name", "values"], path: path)
    }
  }

  private static func requireObject(_ raw: Any?, path: String) throws -> [String: Any] {
    guard let object = raw as? [String: Any] else {
      throw ScenarioJSONError.expectedObject(path)
    }
    return object
  }

  private static func requireExactKeys(
    _ object: [String: Any],
    expected: Set<String>,
    path: String
  ) throws {
    if let unknown = Set(object.keys).subtracting(expected).sorted().first {
      throw ScenarioJSONError.unknownField("\(path).\(unknown)")
    }
  }
}

public enum FixtureResourceError: Error, Equatable, Sendable {
  case missing(String)
  case unreadable(String)
}

public enum FixtureResources {
  public static func scenarioData() throws -> Data {
    try data(name: "mul_add", fileExtension: "json")
  }

  public static func scenarioText() throws -> String {
    let value = String(decoding: try scenarioData(), as: UTF8.self)
    return value.hasSuffix("\n") ? String(value.dropLast()) : value
  }

  public static func scenario() throws -> NumericalScenario {
    try ScenarioJSON.decode(scenarioData())
  }

  public static func expectedStableHLO() throws -> String {
    let data = try data(name: "mul_add.expected", fileExtension: "mlir")
    guard let value = String(data: data, encoding: .utf8) else {
      throw FixtureResourceError.unreadable("mul_add.expected.mlir")
    }
    return value
  }

  private static func data(name: String, fileExtension: String) throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: name,
        withExtension: fileExtension,
        subdirectory: "Фикстуры"
      )
    else {
      throw FixtureResourceError.missing("\(name).\(fileExtension)")
    }
    do {
      return try Data(contentsOf: url)
    } catch {
      throw FixtureResourceError.unreadable("\(name).\(fileExtension)")
    }
  }
}

enum BenchmarkScenarioFactory {
  static func makeScenario(elementCount: Int) -> NumericalScenario {
    let type = TensorType.f32(shape: [elementCount])
    let values = benchmarkValues(elementCount: elementCount)
    return NumericalScenario(
      schemaVersion: 1,
      scenarioID: "benchmark.mul_add.v1",
      function: NumericalFunction(
        name: "mul_add",
        inputs: [
          TensorInput(name: "left", type: type),
          TensorInput(name: "right", type: type),
          TensorInput(name: "bias", type: type),
        ],
        operations: [
          TensorOperation(
            result: "product",
            operation: .multiply,
            left: "left",
            right: "right"
          ),
          TensorOperation(
            result: "output",
            operation: .add,
            left: "product",
            right: "bias"
          ),
        ],
        output: "output"
      ),
      arguments: [
        TensorArgument(name: "left", values: values.0),
        TensorArgument(name: "right", values: values.1),
        TensorArgument(name: "bias", values: values.2),
      ]
    )
  }

  private static func benchmarkValues(elementCount: Int) -> ([Float], [Float], [Float]) {
    var left: [Float] = []
    var right: [Float] = []
    var bias: [Float] = []
    left.reserveCapacity(elementCount)
    right.reserveCapacity(elementCount)
    bias.reserveCapacity(elementCount)
    for index in 0..<elementCount {
      left.append(Float(index % 31 + 1) / 32)
      right.append(Float(index % 17 + 1) / 16)
      bias.append(Float(index % 7 - 3) / 64)
    }
    return (left, right, bias)
  }
}
