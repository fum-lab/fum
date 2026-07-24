import Darwin
import FUMTensorGraphCompiler
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMTensorGraphProbe [verify | export | benchmark | trace | --help]

    Без аргументов или с verify проверяет детерминированную фикстуру mul_add.
    export печатает текстовый кандидат StableHLO/MLIR.
    benchmark сравнивает direct CPU и typed-graph CPU без заявления об ускорении.
    trace печатает обезличенный профиль локальной среды.
    """
  )
}

private func writeJSON<Value: Encodable>(_ value: Value) throws {
  FileHandle.standardOutput.write(try CanonicalJSON.encode(value))
  FileHandle.standardOutput.write(Data("\n".utf8))
}

private func run() throws {
  switch Array(CommandLine.arguments.dropFirst()) {
  case [], ["verify"], ["fixture"]:
    try writeJSON(FixtureVerifier.verify())
  case ["export"]:
    let graph = try TensorGraphCompiler.compile(FixtureResources.scenario().function)
    FileHandle.standardOutput.write(Data(StableHLOExporter.export(graph).utf8))
  case ["benchmark"]:
    try writeJSON(BenchmarkRunner.run())
  case ["trace"]:
    try writeJSON(EnvironmentTrace.current())
  case ["--help"], ["-h"]:
    printUsage()
  default:
    fputs("Неизвестная команда. Используйте --help.\n", stderr)
    exit(2)
  }
}

do {
  try run()
} catch {
  fputs("Проверка компиляции в тензорный граф завершилась ошибкой.\n", stderr)
  exit(2)
}
