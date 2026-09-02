import Darwin
import FUMFunctionHierarchy
import Foundation

private struct Scenario: Sendable {
  let name: String
  let initial: LayerSnapshot
  let expected: [Int]
  let candidates: CandidateSpace
  let verification: [VerificationCase]
  let expectedAction: ChangeAction
  let expectedOutcome: CycleOutcome
}

private struct ScenarioReport: Codable, Equatable, Sendable {
  let name: String
  let result: CycleResult
}

private struct FixtureReport: Codable, Equatable, Sendable {
  let schemaVersion: Int
  let scenarios: [ScenarioReport]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case scenarios
  }
}

private enum ProbeError: Error {
  case unexpectedDecision
}

private func snapshot(
  data: [Int],
  multiplier: Int,
  body: FunctionBody = .affine,
  revision: Int = 1
) -> LayerSnapshot {
  LayerSnapshot(
    data: data,
    parameters: FunctionParameters(multiplier: multiplier, bias: 0),
    body: body,
    revision: revision
  )
}

private let scenarios = [
  Scenario(
    name: "keep",
    initial: snapshot(data: [1, 2, 3], multiplier: 2),
    expected: [2, 4, 6],
    candidates: CandidateSpace(
      updatedData: [1, 2, 4],
      updatedParameters: FunctionParameters(multiplier: 3, bias: 0),
      replacementBody: .quadratic
    ),
    verification: [VerificationCase(data: [4], expected: [8])],
    expectedAction: .keep,
    expectedOutcome: .kept
  ),
  Scenario(
    name: "update-data",
    initial: snapshot(data: [1, 2, 30], multiplier: 2),
    expected: [2, 4, 6],
    candidates: CandidateSpace(
      updatedData: [1, 2, 3],
      updatedParameters: FunctionParameters(multiplier: 1, bias: 0),
      replacementBody: .quadratic
    ),
    verification: [VerificationCase(data: [4], expected: [8])],
    expectedAction: .updateData,
    expectedOutcome: .stabilized
  ),
  Scenario(
    name: "change-parameters",
    initial: snapshot(data: [1, 2, 3], multiplier: 2),
    expected: [3, 6, 9],
    candidates: CandidateSpace(
      updatedData: [1, 2, 4],
      updatedParameters: FunctionParameters(multiplier: 3, bias: 0),
      replacementBody: .quadratic
    ),
    verification: [VerificationCase(data: [4, 5], expected: [12, 15])],
    expectedAction: .changeParameters,
    expectedOutcome: .stabilized
  ),
  Scenario(
    name: "replace-body",
    initial: snapshot(data: [2, 4, 6], multiplier: 1),
    expected: [4, 16, 36],
    candidates: CandidateSpace(
      updatedData: [2, 4, 5],
      updatedParameters: FunctionParameters(multiplier: 2, bias: 0),
      replacementBody: .quadratic
    ),
    verification: [VerificationCase(data: [3, 5], expected: [9, 25])],
    expectedAction: .replaceBody,
    expectedOutcome: .stabilized
  ),
  Scenario(
    name: "rollback",
    initial: snapshot(data: [2, 4, 6], multiplier: 1, revision: 9),
    expected: [4, 16, 36],
    candidates: CandidateSpace(
      updatedData: [2, 4, 5],
      updatedParameters: FunctionParameters(multiplier: 2, bias: 0),
      replacementBody: .quadratic
    ),
    verification: [VerificationCase(data: [5, 7], expected: [5, 7])],
    expectedAction: .replaceBody,
    expectedOutcome: .rolledBack
  ),
]

private func runFixture() throws -> FixtureReport {
  let reports = try scenarios.map { scenario in
    let result = try HierarchyCycle.run(
      initial: scenario.initial,
      expected: scenario.expected,
      candidates: scenario.candidates,
      verification: scenario.verification,
      policy: .fixture
    )
    guard result.trace.selectedAction == scenario.expectedAction,
      result.trace.outcome == scenario.expectedOutcome
    else {
      throw ProbeError.unexpectedDecision
    }
    return ScenarioReport(name: scenario.name, result: result)
  }
  return FixtureReport(schemaVersion: 1, scenarios: reports)
}

private func printUsage() {
  print(
    """
    Использование: FUMFunctionHierarchyProbe [fixture | --help]

    Без аргументов или с fixture выполняет пять детерминированных сценариев:
    keep, update-data, change-parameters, replace-body и rollback.
    """
  )
}

switch Array(CommandLine.arguments.dropFirst()) {
case [], ["fixture"]:
  do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(runFixture())
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
  } catch {
    fputs("Фикстура иерархии функций и данных завершилась ошибкой.\n", stderr)
    exit(2)
  }
case ["--help"], ["-h"]:
  printUsage()
default:
  fputs("Неизвестная команда. Используйте --help.\n", stderr)
  exit(2)
}
