import Foundation
import XCTest

@testable import FUMTensorGraphCompiler

final class TensorGraphCompilerTests: XCTestCase {
  func testCanonicalFixtureCompilesToExactStableHLOCandidate() throws {
    let scenario = try ScenarioJSON.decode(FixtureResources.scenarioData())
    let graph = try TensorGraphCompiler.compile(scenario.function)

    let ir = StableHLOExporter.export(graph)

    XCTAssertEqual(ir, try FixtureResources.expectedStableHLO())
    XCTAssertEqual(graph.operations.map(\.result), ["product", "output"])
    XCTAssertEqual(graph.output.type, TensorType.f32(shape: [4]))
  }

  func testDirectCPUReferenceAndTypedGraphExecutorAgree() throws {
    let scenario = try ScenarioJSON.decode(FixtureResources.scenarioData())
    let graph = try TensorGraphCompiler.compile(scenario.function)
    let arguments = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)

    let direct = try DirectCPUReference.mulAdd(
      left: try XCTUnwrap(arguments["left"]),
      right: try XCTUnwrap(arguments["right"]),
      bias: try XCTUnwrap(arguments["bias"])
    )
    let executed = try TypedGraphExecutor.execute(graph, arguments: arguments)
    let comparison = try TensorComparison.compare(direct, executed)

    XCTAssertEqual(direct.values, [3, 7, 13, 21])
    XCTAssertEqual(executed.values, direct.values)
    XCTAssertTrue(comparison.equivalent)
    XCTAssertEqual(comparison.maximumAbsoluteDifference, 0)
  }

  func testCompilerRejectsForwardSSAReference() throws {
    let type = TensorType.f32(shape: [4])
    let function = NumericalFunction(
      name: "forward_reference",
      inputs: [TensorInput(name: "left", type: type), TensorInput(name: "right", type: type)],
      operations: [
        TensorOperation(result: "output", operation: .add, left: "future", right: "left"),
        TensorOperation(result: "future", operation: .multiply, left: "left", right: "right"),
      ],
      output: "output"
    )

    XCTAssertThrowsError(try TensorGraphCompiler.compile(function)) { error in
      XCTAssertEqual(error as? TensorGraphError, .unknownValueReference("future"))
    }
  }

  func testCompilerRejectsDuplicateSSAName() throws {
    let type = TensorType.f32(shape: [4])
    let function = NumericalFunction(
      name: "duplicate_name",
      inputs: [TensorInput(name: "left", type: type), TensorInput(name: "right", type: type)],
      operations: [
        TensorOperation(result: "left", operation: .multiply, left: "left", right: "right")
      ],
      output: "left"
    )

    XCTAssertThrowsError(try TensorGraphCompiler.compile(function)) { error in
      XCTAssertEqual(error as? TensorGraphError, .duplicateValueName("left"))
    }
  }

  func testCompilerRejectsStaticShapeMismatch() throws {
    let function = NumericalFunction(
      name: "shape_mismatch",
      inputs: [
        TensorInput(name: "left", type: .f32(shape: [4])),
        TensorInput(name: "right", type: .f32(shape: [2, 2])),
      ],
      operations: [
        TensorOperation(result: "output", operation: .multiply, left: "left", right: "right")
      ],
      output: "output"
    )

    XCTAssertThrowsError(try TensorGraphCompiler.compile(function)) { error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .operandTypeMismatch(operation: "output", left: "left", right: "right")
      )
    }
  }

  func testArgumentsRejectNonFiniteValue() throws {
    let scenario = try FixtureResources.scenario()
    let graph = try TensorGraphCompiler.compile(scenario.function)
    let arguments = scenario.arguments.map { argument in
      argument.name == "left"
        ? TensorArgument(name: argument.name, values: [.infinity, 2, 3, 4])
        : argument
    }

    XCTAssertThrowsError(try ScenarioArguments.bind(arguments, to: graph.inputs)) { error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .nonFiniteValue(argument: "left", index: 0)
      )
    }
  }

  func testStrictScenarioJSONRejectsUnknownField() throws {
    let changed = try FixtureResources.scenarioText().replacingOccurrences(
      of: "\"scenario_id\":\"fixture.mul_add.v1\"",
      with: "\"scenario_id\":\"fixture.mul_add.v1\",\"unknown\":true"
    )

    XCTAssertThrowsError(try ScenarioJSON.decode(Data(changed.utf8))) { error in
      XCTAssertEqual(error as? ScenarioJSONError, .unknownField("scenario.unknown"))
    }
  }

  func testCanonicalJSONEncodingIsByteStable() throws {
    let resource = try FixtureResources.scenarioData()
    let decoded = try ScenarioJSON.decode(resource)
    let first = try ScenarioJSON.encodeCanonical(decoded)
    let second = try ScenarioJSON.encodeCanonical(decoded)

    XCTAssertEqual(first, second)
    XCTAssertEqual(first + Data("\n".utf8), resource)
  }

  func testVerificationRecordsDigestsUnavailableTargetAndCPUFallback() throws {
    let report = try FixtureVerifier.verify()

    XCTAssertTrue(report.comparison.equivalent)
    XCTAssertTrue(report.sourceSHA256.hasPrefix("sha256:"))
    XCTAssertTrue(report.irSHA256.hasPrefix("sha256:"))
    XCTAssertEqual(report.sourceSHA256.count, 71)
    XCTAssertEqual(report.irSHA256.count, 71)
    XCTAssertEqual(report.compiler.name, "FUMTensorGraphCompiler")
    XCTAssertEqual(report.compiler.contractVersion, 1)
    XCTAssertEqual(report.environment.schemaVersion, 1)
    XCTAssertEqual(report.comparison.absoluteTolerance, 0.000_001)
    XCTAssertEqual(report.comparison.relativeTolerance, 0.000_001)
    XCTAssertEqual(report.target.provider, "not_configured")
    XCTAssertEqual(report.target.validationStatus, .notPerformed)
    XCTAssertEqual(report.target.runtimeAvailability, .notConfigured)
    XCTAssertEqual(report.target.executionStatus, .notPerformed)
    XCTAssertEqual(report.execution.requestedBackend, .stableHLO)
    XCTAssertEqual(report.execution.selectedBackend, .cpuReference)
    XCTAssertEqual(report.execution.fallback, .targetProviderNotConfigured)
    XCTAssertEqual(report.execution.runtime.name, "FUMTensorGraphCPU")
    XCTAssertEqual(report.execution.runtime.contractVersion, 1)
    XCTAssertEqual(report.execution.runtime.version, "FUMTensorGraphCPU/1")
  }

  func testEnvironmentTraceIsSanitizedAndDoesNotNeedMachineIdentity() throws {
    let trace = EnvironmentTrace.current()
    let data = try CanonicalJSON.encode(trace)
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )

    XCTAssertEqual(trace.schemaVersion, 1)
    XCTAssertEqual(trace.operatingSystem, "macOS")
    XCTAssertFalse(trace.architecture.isEmpty)
    XCTAssertGreaterThan(trace.processorCount, 0)
    XCTAssertGreaterThan(trace.activeProcessorCount, 0)
    XCTAssertGreaterThan(trace.physicalMemoryBytes, 0)
    XCTAssertFalse(trace.swiftCompilerObservation.isEmpty)
    XCTAssertEqual(
      Set(object.keys),
      [
        "active_processor_count", "architecture", "operating_system",
        "operating_system_version", "physical_memory_bytes", "processor_count",
        "schema_version", "swift_compiler_observation",
      ]
    )
  }

  func testBenchmarkReportsSamplesAndEqualChecksumsWithoutSpeedAssertion() throws {
    let report = try BenchmarkRunner.run(
      plan: BenchmarkPlan(
        tensorElements: 32,
        warmupIterations: 1,
        sampleCount: 3,
        iterationsPerSample: 2
      )
    )

    XCTAssertEqual(report.schemaVersion, 1)
    XCTAssertEqual(report.directCPU.samplesNanoseconds.count, 3)
    XCTAssertEqual(report.graphCPU.samplesNanoseconds.count, 3)
    XCTAssertGreaterThan(report.directCPU.medianNanoseconds, 0)
    XCTAssertGreaterThan(report.graphCPU.p95Nanoseconds, 0)
    XCTAssertEqual(report.directCPU.checksum, report.graphCPU.checksum, accuracy: 0.000_001)
    XCTAssertTrue(report.outputsEquivalent)
    XCTAssertEqual(report.accelerationClaim, .notMeasured)
  }

  func testDirectCPURejectsUndersizedLeftTensorWithoutIndexingTrap() throws {
    let type = TensorType.f32(shape: [4])
    let left = TensorValue(type: type, values: [1])
    let right = TensorValue(type: type, values: [1, 2, 3, 4])
    let bias = TensorValue(type: type, values: [0, 0, 0, 0])

    XCTAssertThrowsError(try DirectCPUReference.mulAdd(left: left, right: right, bias: bias)) {
      error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .valueElementCount(value: "left", expected: 4, actual: 1)
      )
    }
  }

  func testDirectCPURejectsShortRightTensorWithoutIndexingTrap() throws {
    let type = TensorType.f32(shape: [4])
    let left = TensorValue(type: type, values: [1, 2, 3, 4])
    let right = TensorValue(type: type, values: [1, 2])
    let bias = TensorValue(type: type, values: [0, 0, 0, 0])

    XCTAssertThrowsError(try DirectCPUReference.mulAdd(left: left, right: right, bias: bias)) {
      error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .valueElementCount(value: "right", expected: 4, actual: 2)
      )
    }
  }

  func testTypedGraphExecutorRejectsNonFinitePublicValue() throws {
    let scenario = try FixtureResources.scenario()
    let graph = try TensorGraphCompiler.compile(scenario.function)
    var arguments = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    arguments["left"] = TensorValue(
      type: .f32(shape: [4]),
      values: [.nan, 2, 3, 4]
    )

    XCTAssertThrowsError(try TypedGraphExecutor.execute(graph, arguments: arguments)) { error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .nonFiniteValue(argument: "left", index: 0)
      )
    }
  }

  func testTypedGraphExecutorRejectsShortRightPublicValue() throws {
    let scenario = try FixtureResources.scenario()
    let graph = try TensorGraphCompiler.compile(scenario.function)
    var arguments = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    arguments["right"] = TensorValue(type: .f32(shape: [4]), values: [1, 2])

    XCTAssertThrowsError(try TypedGraphExecutor.execute(graph, arguments: arguments)) { error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .valueElementCount(value: "right", expected: 4, actual: 2)
      )
    }
  }

  func testBenchmarkRejectsHugePlanBeforeAllocatingTensorValues() {
    let plan = BenchmarkPlan(
      tensorElements: .max,
      warmupIterations: 1,
      sampleCount: 1,
      iterationsPerSample: 1
    )

    XCTAssertThrowsError(try BenchmarkRunner.run(plan: plan)) { error in
      XCTAssertEqual(
        error as? TensorGraphError,
        .benchmarkLimitExceeded("tensor_elements")
      )
    }
  }
}
