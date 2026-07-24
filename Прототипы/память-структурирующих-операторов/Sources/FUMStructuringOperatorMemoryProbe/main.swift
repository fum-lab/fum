import FUMStructuringOperatorMemory
import Foundation

@main
struct FUMStructuringOperatorMemoryProbe {
  static func main() {
    do {
      let suite = try ScenarioFixtureLoader.loadBundledSuite()
      let arguments = Array(CommandLine.arguments.dropFirst())
      switch arguments.first {
      case nil:
        let reports = try StructuringOperatorEngine().runAll(in: suite)
        try printCanonical(reports)
        if reports.contains(where: { !$0.passed }) { exit(EXIT_FAILURE) }
      case "--list":
        for scenario in suite.scenarios {
          print("\(scenario.id)\t\(scenario.description)")
        }
      case "fixture":
        guard arguments.count == 2 else {
          throw OperatorMemoryError.invalidFixture("fixture requires one scenario id")
        }
        let report = try StructuringOperatorEngine().run(
          scenarioID: arguments[1],
          in: suite
        )
        try printCanonical(report)
        if !report.passed { exit(EXIT_FAILURE) }
      case "--help", "-h":
        print(
          """
          Usage:
            FUMStructuringOperatorMemoryProbe
            FUMStructuringOperatorMemoryProbe --list
            FUMStructuringOperatorMemoryProbe fixture <scenario-id>
            FUMStructuringOperatorMemoryProbe --help

          The default run is local, deterministic, fixture-only, and performs no external effects.
          """)
      default:
        throw OperatorMemoryError.invalidFixture("unknown command")
      }
    } catch {
      FileHandle.standardError.write(Data("error: \(error)\n".utf8))
      exit(EXIT_FAILURE)
    }
  }

  private static func printCanonical<T: Encodable>(_ value: T) throws {
    let data = try canonicalJSONData(value)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
  }
}
