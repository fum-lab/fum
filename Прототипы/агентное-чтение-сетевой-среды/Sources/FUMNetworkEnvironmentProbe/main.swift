import Darwin
import FUMNetworkEnvironment
import Foundation

private enum ProbeError: Error {
  case unexpectedReport
}

private func runFixture() throws -> RuntimeSelectionReport {
  let report = try NetworkReadingFixture.run()
  guard report.winnerAgentID == "agent.scaling.refined",
    report.baseMapUnchanged,
    report.usage.evaluatedAgents <= report.budget.maxAgents,
    report.usage.births <= report.budget.maxBirths,
    report.usage.nodeVisits <= report.budget.maxNodeVisits,
    report.usage.traceSteps <= report.budget.maxTraceSteps,
    report.usage.graphWrites == 0
  else {
    throw ProbeError.unexpectedReport
  }
  return report
}

private func printUsage() {
  print(
    """
    Использование: FUMNetworkEnvironmentProbe [fixture | --help]

    Без аргументов или с fixture выполняет детерминированный runtime-отбор
    четырёх агентов на неизменяемой карте арифметических вычислителей.
    """
  )
}

switch Array(CommandLine.arguments.dropFirst()) {
case [], ["fixture"]:
  do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let data = try encoder.encode(runFixture())
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
  } catch {
    fputs("Фикстура агентного чтения сетевой среды завершилась ошибкой.\n", stderr)
    exit(2)
  }
case ["--help"], ["-h"]:
  printUsage()
default:
  fputs("Неизвестная команда. Используйте --help.\n", stderr)
  exit(2)
}
