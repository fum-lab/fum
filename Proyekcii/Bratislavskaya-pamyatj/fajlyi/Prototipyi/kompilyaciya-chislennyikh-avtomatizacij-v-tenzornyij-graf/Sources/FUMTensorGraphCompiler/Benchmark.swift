import Dispatch
import Foundation

public struct BenchmarkPlan: Codable, Equatable, Sendable {
  public let tensorElements: Int
  public let warmupIterations: Int
  public let sampleCount: Int
  public let iterationsPerSample: Int

  enum CodingKeys: String, CodingKey {
    case tensorElements = "tensor_elements"
    case warmupIterations = "warmup_iterations"
    case sampleCount = "sample_count"
    case iterationsPerSample = "iterations_per_sample"
  }

  public init(
    tensorElements: Int,
    warmupIterations: Int,
    sampleCount: Int,
    iterationsPerSample: Int
  ) {
    self.tensorElements = tensorElements
    self.warmupIterations = warmupIterations
    self.sampleCount = sampleCount
    self.iterationsPerSample = iterationsPerSample
  }

  public static let standard = BenchmarkPlan(
    tensorElements: 16_384,
    warmupIterations: 3,
    sampleCount: 9,
    iterationsPerSample: 32
  )
}

public enum BenchmarkBuildConfiguration: String, Codable, Equatable, Sendable {
  case debug
  case release
}

public enum AccelerationClaim: String, Codable, Equatable, Sendable {
  case notMeasured = "not_measured_no_target_provider"
}

public struct BenchmarkMeasurement: Codable, Equatable, Sendable {
  public let samplesNanoseconds: [UInt64]
  public let medianNanoseconds: UInt64
  public let p95Nanoseconds: UInt64
  public let checksum: Double

  enum CodingKeys: String, CodingKey {
    case samplesNanoseconds = "samples_nanoseconds"
    case medianNanoseconds = "median_nanoseconds"
    case p95Nanoseconds = "p95_nanoseconds"
    case checksum
  }

  public init(
    samplesNanoseconds: [UInt64],
    medianNanoseconds: UInt64,
    p95Nanoseconds: UInt64,
    checksum: Double
  ) {
    self.samplesNanoseconds = samplesNanoseconds
    self.medianNanoseconds = medianNanoseconds
    self.p95Nanoseconds = p95Nanoseconds
    self.checksum = checksum
  }
}

public struct BenchmarkReport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let benchmarkID: String
  public let buildConfiguration: BenchmarkBuildConfiguration
  public let plan: BenchmarkPlan
  public let directCPU: BenchmarkMeasurement
  public let graphCPU: BenchmarkMeasurement
  public let outputsEquivalent: Bool
  public let accelerationClaim: AccelerationClaim

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case benchmarkID = "benchmark_id"
    case buildConfiguration = "build_configuration"
    case plan
    case directCPU = "direct_cpu"
    case graphCPU = "graph_cpu"
    case outputsEquivalent = "outputs_equivalent"
    case accelerationClaim = "acceleration_claim"
  }

  public init(
    schemaVersion: Int,
    benchmarkID: String,
    buildConfiguration: BenchmarkBuildConfiguration,
    plan: BenchmarkPlan,
    directCPU: BenchmarkMeasurement,
    graphCPU: BenchmarkMeasurement,
    outputsEquivalent: Bool,
    accelerationClaim: AccelerationClaim
  ) {
    self.schemaVersion = schemaVersion
    self.benchmarkID = benchmarkID
    self.buildConfiguration = buildConfiguration
    self.plan = plan
    self.directCPU = directCPU
    self.graphCPU = graphCPU
    self.outputsEquivalent = outputsEquivalent
    self.accelerationClaim = accelerationClaim
  }
}

public enum BenchmarkRunner {
  private static let maximumTensorElements = 1_048_576
  private static let maximumWarmupIterations = 100
  private static let maximumSampleCount = 100
  private static let maximumIterationsPerSample = 10_000
  private static let maximumWorkElements = 100_000_000

  public static func run(plan: BenchmarkPlan = .standard) throws -> BenchmarkReport {
    guard plan.tensorElements > 0,
      plan.warmupIterations >= 0,
      plan.sampleCount > 0,
      plan.iterationsPerSample > 0
    else {
      throw TensorGraphError.invalidBenchmarkPlan
    }
    guard plan.tensorElements <= maximumTensorElements else {
      throw TensorGraphError.benchmarkLimitExceeded("tensor_elements")
    }
    guard plan.warmupIterations <= maximumWarmupIterations else {
      throw TensorGraphError.benchmarkLimitExceeded("warmup_iterations")
    }
    guard plan.sampleCount <= maximumSampleCount else {
      throw TensorGraphError.benchmarkLimitExceeded("sample_count")
    }
    guard plan.iterationsPerSample <= maximumIterationsPerSample else {
      throw TensorGraphError.benchmarkLimitExceeded("iterations_per_sample")
    }
    let measured = plan.sampleCount.multipliedReportingOverflow(
      by: plan.iterationsPerSample
    )
    guard !measured.overflow else {
      throw TensorGraphError.benchmarkLimitExceeded("total_work_elements")
    }
    let executions = measured.partialValue.addingReportingOverflow(
      plan.warmupIterations
    )
    guard !executions.overflow else {
      throw TensorGraphError.benchmarkLimitExceeded("total_work_elements")
    }
    let work = plan.tensorElements.multipliedReportingOverflow(
      by: executions.partialValue
    )
    guard !work.overflow, work.partialValue <= maximumWorkElements else {
      throw TensorGraphError.benchmarkLimitExceeded("total_work_elements")
    }

    let scenario = BenchmarkScenarioFactory.makeScenario(elementCount: plan.tensorElements)
    let graph = try TensorGraphCompiler.compile(scenario.function)
    let arguments = try ScenarioArguments.bind(scenario.arguments, to: graph.inputs)
    guard let left = arguments["left"],
      let right = arguments["right"],
      let bias = arguments["bias"]
    else {
      throw TensorGraphError.fixtureMismatch
    }

    let direct = try measure(plan: plan) {
      try DirectCPUReference.mulAdd(left: left, right: right, bias: bias)
    }
    let executed = try measure(plan: plan) {
      try TypedGraphExecutor.execute(graph, arguments: arguments)
    }
    let directOutput = try DirectCPUReference.mulAdd(left: left, right: right, bias: bias)
    let graphOutput = try TypedGraphExecutor.execute(graph, arguments: arguments)
    let comparison = try TensorComparison.compare(directOutput, graphOutput)

    return BenchmarkReport(
      schemaVersion: 1,
      benchmarkID: "mul_add.f32.static_shape.v1",
      buildConfiguration: buildConfiguration(),
      plan: plan,
      directCPU: direct,
      graphCPU: executed,
      outputsEquivalent: comparison.equivalent,
      accelerationClaim: .notMeasured
    )
  }

  private static func measure(
    plan: BenchmarkPlan,
    operation: () throws -> TensorValue
  ) throws -> BenchmarkMeasurement {
    for _ in 0..<plan.warmupIterations {
      _ = try operation()
    }

    var samples: [UInt64] = []
    var totalChecksum = 0.0
    samples.reserveCapacity(plan.sampleCount)
    for sampleIndex in 0..<plan.sampleCount {
      let start = DispatchTime.now().uptimeNanoseconds
      var sampleChecksum = 0.0
      for iteration in 0..<plan.iterationsPerSample {
        let output = try operation()
        let index = (sampleIndex + iteration) % output.values.count
        sampleChecksum += Double(output.values[index])
      }
      let elapsed = DispatchTime.now().uptimeNanoseconds - start
      samples.append(elapsed)
      totalChecksum += sampleChecksum
    }

    let sorted = samples.sorted()
    let median = sorted[sorted.count / 2]
    let p95Index = min(sorted.count - 1, (sorted.count * 95 + 99) / 100 - 1)
    return BenchmarkMeasurement(
      samplesNanoseconds: samples,
      medianNanoseconds: median,
      p95Nanoseconds: sorted[p95Index],
      checksum: totalChecksum
    )
  }

  private static func buildConfiguration() -> BenchmarkBuildConfiguration {
    #if DEBUG
      .debug
    #else
      .release
    #endif
  }
}
