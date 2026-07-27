import Darwin
import FUMVerifiableMultiAgentContour
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMWorkPackageProbe [fixture [имя] | stdin | --list | --help]

    Без аргументов анализирует положительную фикстуру ready.
    fixture [имя] анализирует встроенную фикстуру; без имени выбирается ready.
    stdin принимает один JSON-пакет версии 1 из стандартного ввода.
    --list печатает имена встроенных фикстур.

    Код завершения: 0 для ready, 3 для split_required, 2 для ошибки команды.
    """
  )
}

private func readBoundedStandardInput() -> Data {
  var input = Data()
  let readLimit = WorkPackagePreflight.maximumEnvelopeBytes + 1

  while input.count < readLimit {
    let chunk = FileHandle.standardInput.readData(
      ofLength: min(64 * 1_024, readLimit - input.count)
    )
    guard !chunk.isEmpty else { break }
    input.append(chunk)
  }
  return input
}

private func writeLine(_ data: Data, to handle: FileHandle) {
  handle.write(data)
  handle.write(Data("\n".utf8))
}

let arguments = Array(CommandLine.arguments.dropFirst())
let input: Data
let workspaceRoot: URL

do {
  if arguments.count == 2, arguments[0] == "fixture" {
    input = try WorkPackageFixtures.load(named: arguments[1])
    workspaceRoot = try WorkPackageFixtures.workspaceRoot()
  } else {
    switch arguments {
    case [], ["fixture"]:
      input = try WorkPackageFixtures.load(named: "ready")
      workspaceRoot = try WorkPackageFixtures.workspaceRoot()
    case ["stdin"]:
      input = readBoundedStandardInput()
      workspaceRoot = URL(
        fileURLWithPath: FileManager.default.currentDirectoryPath,
        isDirectory: true
      )
    case ["--list"]:
      print(WorkPackageFixtures.identifiers.joined(separator: "\n"))
      exit(0)
    case ["--help"], ["-h"]:
      printUsage()
      exit(0)
    default:
      fputs("Неизвестная команда. Используйте --help.\n", stderr)
      exit(2)
    }
  }
} catch {
  fputs("Не удалось загрузить фикстуру: \(error)\n", stderr)
  exit(2)
}

let report = WorkPackagePreflight.analyze(input, workspaceRoot: workspaceRoot)
do {
  writeLine(try report.canonicalJSONData(), to: .standardOutput)
} catch {
  fputs("Не удалось закодировать отчёт предпускового анализа.\n", stderr)
  exit(2)
}

exit(report.decision == .ready ? 0 : 3)
