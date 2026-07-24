import CryptoKit
import Foundation

public enum CanonicalJSON {
  public static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }
}

public enum ContentDigest {
  public static func sha256(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }

  public static func sha256(_ text: String) -> String {
    sha256(Data(text.utf8))
  }
}

public enum TargetAvailability: String, Codable, Equatable, Sendable {
  case available
  case unavailable
  case notConfigured = "not_configured"
}

public enum TargetOperationStatus: String, Codable, Equatable, Sendable {
  case notPerformed = "not_performed"
}

public enum ExecutionBackend: String, Codable, Equatable, Sendable {
  case stableHLO = "stablehlo_target"
  case cpuReference = "cpu_reference"
}

public enum CPUFallback: String, Codable, Equatable, Sendable {
  case targetProviderNotConfigured = "target_provider_not_configured"
}

public struct CompilerContractTrace: Codable, Equatable, Sendable {
  public let name: String
  public let contractVersion: Int
  public let sourceDSL: String
  public let sourceDSLVersion: Int

  enum CodingKeys: String, CodingKey {
    case name
    case contractVersion = "contract_version"
    case sourceDSL = "source_dsl"
    case sourceDSLVersion = "source_dsl_version"
  }

  public init(
    name: String,
    contractVersion: Int,
    sourceDSL: String,
    sourceDSLVersion: Int
  ) {
    self.name = name
    self.contractVersion = contractVersion
    self.sourceDSL = sourceDSL
    self.sourceDSLVersion = sourceDSLVersion
  }
}

public struct RuntimeContractTrace: Codable, Equatable, Sendable {
  public let name: String
  public let contractVersion: Int
  public let version: String

  enum CodingKeys: String, CodingKey {
    case name
    case contractVersion = "contract_version"
    case version
  }

  public init(name: String, contractVersion: Int, version: String) {
    self.name = name
    self.contractVersion = contractVersion
    self.version = version
  }
}

public struct TargetTrace: Codable, Equatable, Sendable {
  public let format: String
  public let exporter: String
  public let provider: String
  public let validator: String
  public let validatorAvailability: TargetAvailability
  public let validationStatus: TargetOperationStatus
  public let runtimeAvailability: TargetAvailability
  public let executionStatus: TargetOperationStatus

  enum CodingKeys: String, CodingKey {
    case format
    case exporter
    case provider
    case validator
    case validatorAvailability = "validator_availability"
    case validationStatus = "validation_status"
    case runtimeAvailability = "runtime_availability"
    case executionStatus = "execution_status"
  }

  public init(
    format: String,
    exporter: String,
    provider: String,
    validator: String,
    validatorAvailability: TargetAvailability,
    validationStatus: TargetOperationStatus,
    runtimeAvailability: TargetAvailability,
    executionStatus: TargetOperationStatus
  ) {
    self.format = format
    self.exporter = exporter
    self.provider = provider
    self.validator = validator
    self.validatorAvailability = validatorAvailability
    self.validationStatus = validationStatus
    self.runtimeAvailability = runtimeAvailability
    self.executionStatus = executionStatus
  }
}

public struct ExecutionTrace: Codable, Equatable, Sendable {
  public let requestedBackend: ExecutionBackend
  public let selectedBackend: ExecutionBackend
  public let fallback: CPUFallback
  public let runtime: RuntimeContractTrace

  enum CodingKeys: String, CodingKey {
    case requestedBackend = "requested_backend"
    case selectedBackend = "selected_backend"
    case fallback
    case runtime
  }

  public init(
    requestedBackend: ExecutionBackend,
    selectedBackend: ExecutionBackend,
    fallback: CPUFallback,
    runtime: RuntimeContractTrace
  ) {
    self.requestedBackend = requestedBackend
    self.selectedBackend = selectedBackend
    self.fallback = fallback
    self.runtime = runtime
  }
}

public struct FixtureVerificationReport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let scenarioID: String
  public let sourceSHA256: String
  public let irSHA256: String
  public let compiler: CompilerContractTrace
  public let environment: EnvironmentTrace
  public let directCPU: TensorValue
  public let graphCPU: TensorValue
  public let comparison: TensorComparisonReport
  public let target: TargetTrace
  public let execution: ExecutionTrace

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case scenarioID = "scenario_id"
    case sourceSHA256 = "source_sha256"
    case irSHA256 = "ir_sha256"
    case compiler
    case environment
    case directCPU = "direct_cpu"
    case graphCPU = "graph_cpu"
    case comparison
    case target
    case execution
  }

  public init(
    schemaVersion: Int,
    scenarioID: String,
    sourceSHA256: String,
    irSHA256: String,
    compiler: CompilerContractTrace,
    environment: EnvironmentTrace,
    directCPU: TensorValue,
    graphCPU: TensorValue,
    comparison: TensorComparisonReport,
    target: TargetTrace,
    execution: ExecutionTrace
  ) {
    self.schemaVersion = schemaVersion
    self.scenarioID = scenarioID
    self.sourceSHA256 = sourceSHA256
    self.irSHA256 = irSHA256
    self.compiler = compiler
    self.environment = environment
    self.directCPU = directCPU
    self.graphCPU = graphCPU
    self.comparison = comparison
    self.target = target
    self.execution = execution
  }
}

public enum FixtureVerifier {
  public static func verify() throws -> FixtureVerificationReport {
    let resourceSource = try FixtureResources.scenarioData()
    let scenario = try ScenarioJSON.decode(resourceSource)
    let source = try ScenarioJSON.encodeCanonical(scenario)
    let resourceWithoutFinalNewline =
      resourceSource.last == 0x0A ? Data(resourceSource.dropLast()) : resourceSource
    guard resourceWithoutFinalNewline == source else {
      throw TensorGraphError.fixtureMismatch
    }
    let graph = try TensorGraphCompiler.compile(scenario.function)
    let ir = StableHLOExporter.export(graph)
    guard ir == (try FixtureResources.expectedStableHLO()) else {
      throw TensorGraphError.fixtureMismatch
    }
    let arguments = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    guard let left = arguments["left"],
      let right = arguments["right"],
      let bias = arguments["bias"]
    else {
      throw TensorGraphError.fixtureMismatch
    }
    let direct = try DirectCPUReference.mulAdd(left: left, right: right, bias: bias)
    let graphOutput = try TypedGraphExecutor.execute(graph, arguments: arguments)
    let comparison = try TensorComparison.compare(direct, graphOutput)
    guard comparison.equivalent else {
      throw TensorGraphError.fixtureMismatch
    }

    return FixtureVerificationReport(
      schemaVersion: 1,
      scenarioID: scenario.scenarioID,
      sourceSHA256: ContentDigest.sha256(source),
      irSHA256: ContentDigest.sha256(ir),
      compiler: CompilerContractTrace(
        name: "FUMTensorGraphCompiler",
        contractVersion: 1,
        sourceDSL: "fum_numeric_ssa_like_json",
        sourceDSLVersion: 1
      ),
      environment: EnvironmentTrace.current(),
      directCPU: direct,
      graphCPU: graphOutput,
      comparison: comparison,
      target: TargetTrace(
        format: "stablehlo_mlir_text_candidate",
        exporter: "FUMTensorGraphCompiler/1",
        provider: "not_configured",
        validator: "stablehlo-opt",
        validatorAvailability: executableOnPATH("stablehlo-opt") ? .available : .unavailable,
        validationStatus: .notPerformed,
        runtimeAvailability: .notConfigured,
        executionStatus: .notPerformed
      ),
      execution: ExecutionTrace(
        requestedBackend: .stableHLO,
        selectedBackend: .cpuReference,
        fallback: .targetProviderNotConfigured,
        runtime: RuntimeContractTrace(
          name: "FUMTensorGraphCPU",
          contractVersion: 1,
          version: "FUMTensorGraphCPU/1"
        )
      )
    )
  }

  private static func executableOnPATH(_ name: String) -> Bool {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
      return false
    }
    return path.split(separator: ":").contains { component in
      guard component.hasPrefix("/") else { return false }
      let candidate = URL(fileURLWithPath: String(component)).appendingPathComponent(name)
      return FileManager.default.isExecutableFile(atPath: candidate.path)
    }
  }
}

public struct EnvironmentTrace: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let operatingSystem: String
  public let operatingSystemVersion: String
  public let architecture: String
  public let processorCount: Int
  public let activeProcessorCount: Int
  public let physicalMemoryBytes: UInt64
  public let swiftCompilerObservation: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case operatingSystem = "operating_system"
    case operatingSystemVersion = "operating_system_version"
    case architecture
    case processorCount = "processor_count"
    case activeProcessorCount = "active_processor_count"
    case physicalMemoryBytes = "physical_memory_bytes"
    case swiftCompilerObservation = "swift_compiler_observation"
  }

  public init(
    schemaVersion: Int,
    operatingSystem: String,
    operatingSystemVersion: String,
    architecture: String,
    processorCount: Int,
    activeProcessorCount: Int,
    physicalMemoryBytes: UInt64,
    swiftCompilerObservation: String
  ) {
    self.schemaVersion = schemaVersion
    self.operatingSystem = operatingSystem
    self.operatingSystemVersion = operatingSystemVersion
    self.architecture = architecture
    self.processorCount = processorCount
    self.activeProcessorCount = activeProcessorCount
    self.physicalMemoryBytes = physicalMemoryBytes
    self.swiftCompilerObservation = swiftCompilerObservation
  }

  public static func current() -> EnvironmentTrace {
    let process = ProcessInfo.processInfo
    let version = process.operatingSystemVersion
    let versionText =
      "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    return EnvironmentTrace(
      schemaVersion: 1,
      operatingSystem: "macOS",
      operatingSystemVersion: versionText,
      architecture: currentArchitecture(),
      processorCount: process.processorCount,
      activeProcessorCount: process.activeProcessorCount,
      physicalMemoryBytes: process.physicalMemory,
      swiftCompilerObservation: compilerObservation()
    )
  }

  private static func currentArchitecture() -> String {
    #if arch(arm64)
      "arm64"
    #elseif arch(x86_64)
      "x86_64"
    #else
      "other"
    #endif
  }

  private static func compilerObservation() -> String {
    #if compiler(>=6.4)
      "compiler_6_4_or_newer"
    #elseif compiler(>=6.3)
      "compiler_6_3"
    #elseif compiler(>=6.2)
      "compiler_6_2"
    #elseif compiler(>=6.1)
      "compiler_6_1"
    #else
      "compiler_6_0"
    #endif
  }
}
