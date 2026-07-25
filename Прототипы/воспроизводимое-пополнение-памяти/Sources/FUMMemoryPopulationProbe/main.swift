import FUMReproducibleMemoryPopulation
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMMemoryPopulationProbe [fixture | stdin | bootstrap <каталог> | continue <каталог> | show <каталог> | --help]

    Без аргументов или с fixture выполняет встроенный версионированный набор событий.
    stdin читает набор событий версии 1 из стандартного ввода.
    bootstrap <каталог> атомарно подтверждает базовое поколение в новом хранилище.
    continue <каталог> восстанавливает CURRENT и подтверждает продолжение.
    show <каталог> проверяет и печатает последнее подтверждённое поколение.
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

do {
  let output: Data
  switch arguments {
  case [], ["fixture"]:
    let input = try MemoryPopulationFixtures.loadBootstrapV1()
    output = try CanonicalMemoryJSON.encode(MemoryPopulationEngine().run(input))
  case ["stdin"]:
    output = try CanonicalMemoryJSON.encode(
      MemoryPopulationEngine().run(readBoundedStandardInput())
    )
  case let values where values.count == 2 && values[0] == "bootstrap":
    let path = values[1]
    let store = MemoryGenerationStore(
      rootURL: URL(fileURLWithPath: path, isDirectory: true)
    )
    let generation = try MemoryPopulationEngine().generation(
      from: MemoryPopulationFixtures.loadBootstrapBaseV1()
    )
    output = try CanonicalMemoryJSON.encode(store.commit(generation))
  case let values where values.count == 2 && values[0] == "continue":
    let path = values[1]
    let store = MemoryGenerationStore(
      rootURL: URL(fileURLWithPath: path, isDirectory: true)
    )
    guard let current = try store.loadCurrent() else {
      throw MemoryPopulationError.generationStore(
        "Подтверждённое поколение CURRENT не найдено."
      )
    }
    let generation = try MemoryPopulationEngine().generation(
      from: MemoryPopulationFixtures.loadBootstrapContinuationV1(),
      continuingFrom: current
    )
    output = try CanonicalMemoryJSON.encode(store.commit(generation))
  case let values where values.count == 2 && values[0] == "show":
    let path = values[1]
    let store = MemoryGenerationStore(
      rootURL: URL(fileURLWithPath: path, isDirectory: true)
    )
    guard let current = try store.loadCurrent() else {
      throw MemoryPopulationError.generationStore(
        "Подтверждённое поколение CURRENT не найдено."
      )
    }
    output = try CanonicalMemoryJSON.encode(current)
  case ["--help"], ["-h"]:
    printUsage()
    exit(EXIT_SUCCESS)
  default:
    throw MemoryPopulationError.invalidInput("Неизвестная команда. Используйте --help.")
  }

  writeLine(output, to: .standardOutput)
} catch let error as MemoryPopulationError {
  FileHandle.standardError.write(Data("Ошибка: \(error)\n".utf8))
  exit(EXIT_FAILURE)
} catch {
  FileHandle.standardError.write(
    Data("Ошибка: внутренняя ошибка чтения или кодирования данных.\n".utf8)
  )
  exit(EXIT_FAILURE)
}
