import FUMReproducibleMemoryPopulation
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMMemoryPopulationProbe [fixture | stdin | --help]

    Без аргументов или с fixture выполняет встроенный версионированный набор событий.
    stdin читает набор событий версии 1 из стандартного ввода.
    """
  )
}

private func readBoundedStandardInput() -> Data {
  let limit = MemoryPopulationEngine.maximumInputBytes + 1
  var data = Data()
  while data.count < limit {
    let chunk = FileHandle.standardInput.readData(ofLength: min(65_536, limit - data.count))
    guard !chunk.isEmpty else { break }
    data.append(chunk)
  }
  return data
}

private func writeLine(_ data: Data, to handle: FileHandle) {
  handle.write(data)
  handle.write(Data("\n".utf8))
}

let arguments = Array(CommandLine.arguments.dropFirst())
let input: Data

do {
  switch arguments {
  case [], ["fixture"]:
    input = try MemoryPopulationFixtures.loadBootstrapV1()
  case ["stdin"]:
    input = readBoundedStandardInput()
  case ["--help"], ["-h"]:
    printUsage()
    exit(EXIT_SUCCESS)
  default:
    throw MemoryPopulationError.invalidInput("Неизвестная команда. Используйте --help.")
  }

  let artifact = try MemoryPopulationEngine().run(input)
  writeLine(try CanonicalMemoryJSON.encode(artifact), to: .standardOutput)
} catch let error as MemoryPopulationError {
  FileHandle.standardError.write(Data("Ошибка: \(error)\n".utf8))
  exit(EXIT_FAILURE)
} catch {
  FileHandle.standardError.write(
    Data("Ошибка: внутренняя ошибка чтения или кодирования данных.\n".utf8)
  )
  exit(EXIT_FAILURE)
}
