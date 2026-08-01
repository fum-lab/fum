import Darwin
import FUMDistributedEpisodeMemory
import FUMVerifiableMultiAgentContour
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMWorkPackageProbe [fixture [имя] | stdin | --list | episode <команда> | memory <команда> | --help]

    Без аргументов анализирует положительную фикстуру ready.
    fixture [имя] анализирует встроенную фикстуру; без имени выбирается ready.
    stdin принимает один JSON-пакет версии 1 из стандартного ввода.
    --list печатает имена встроенных фикстур.

    episode fixture [имя] проверяет встроенный паспорт; без имени выбирается valid.
    episode stdin принимает JSON-паспорт эпизода версии 1.
    episode --list печатает имена фикстур паспорта.

    memory bootstrap <каталог> публикует пустое подтверждённое поколение стенда.
    memory continue <каталог> <primary|adversarial> добавляет один вклад к CURRENT.
    memory show <каталог> повторно проигрывает и печатает CURRENT.

    Код завершения: 0 для ready/valid и успешной команды памяти, 3 для split_required/invalid или отказа памяти, 2 для синтаксической ошибки команды.
    """
  )
}

private func runMemoryCommand(_ arguments: [String]) -> Never {
  guard arguments.count >= 2 else {
    fputs("Неполная команда общей памяти. Используйте --help.\n", stderr)
    exit(2)
  }
  let rootURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
  let store = SharedEpisodeMemoryStore(rootURL: rootURL)

  do {
    let stored: StoredSharedEpisodeGeneration
    switch arguments[0] {
    case "bootstrap" where arguments.count == 2:
      stored = try store.commit(
        SharedEpisodeMemoryReducer.foundation(seed: SharedEpisodeMemoryFixtures.seed())
      )
    case "continue" where arguments.count == 3:
      guard let fixture = SharedEpisodeContributionFixture(rawValue: arguments[2]) else {
        fputs("Неизвестный вклад стенда.\n", stderr)
        exit(2)
      }
      let current = try store.loadCurrent()
      guard let current else {
        fputs("Память стенда ещё не имеет CURRENT.\n", stderr)
        exit(3)
      }
      let contribution = try SharedEpisodeMemoryFixtures.contribution(
        named: fixture,
        parentGenerationSHA256: current.generationSHA256
      )
      stored = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: current.generation,
          contribution: contribution
        )
      )
    case "show" where arguments.count == 2:
      guard let current = try store.loadCurrent() else {
        fputs("Память стенда ещё не имеет CURRENT.\n", stderr)
        exit(3)
      }
      stored = current
    default:
      fputs("Неизвестная команда общей памяти. Используйте --help.\n", stderr)
      exit(2)
    }
    writeLine(try stored.generation.canonicalJSONData(), to: .standardOutput)
    exit(0)
  } catch {
    fputs("Общая память отклонила команду: \(error)\n", stderr)
    exit(3)
  }
}

private func readBoundedStandardInput(maximumBytes: Int) -> Data {
  var input = Data()
  let readLimit = maximumBytes + 1

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

private func runEpisodeCommand(_ arguments: [String]) -> Never {
  let input: Data
  do {
    if arguments.count == 2, arguments[0] == "fixture" {
      input = try EpisodePassportFixtures.load(named: arguments[1])
    } else {
      switch arguments {
      case [], ["fixture"]:
        input = try EpisodePassportFixtures.load(named: "valid")
      case ["stdin"]:
        input = readBoundedStandardInput(
          maximumBytes: EpisodePassportPreflight.maximumEnvelopeBytes
        )
      case ["--list"]:
        print(EpisodePassportFixtures.identifiers.joined(separator: "\n"))
        exit(0)
      default:
        fputs("Неизвестная команда паспорта. Используйте --help.\n", stderr)
        exit(2)
      }
    }
  } catch {
    fputs("Не удалось загрузить фикстуру паспорта: \(error)\n", stderr)
    exit(2)
  }

  let report = EpisodePassportPreflight.analyze(input)
  do {
    writeLine(try report.canonicalJSONData(), to: .standardOutput)
  } catch {
    fputs("Не удалось закодировать отчёт паспорта.\n", stderr)
    exit(2)
  }

  exit(report.decision == .valid ? 0 : 3)
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.first == "memory" {
  runMemoryCommand(Array(arguments.dropFirst()))
}
if arguments.first == "episode" {
  runEpisodeCommand(Array(arguments.dropFirst()))
}
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
      input = readBoundedStandardInput(maximumBytes: WorkPackagePreflight.maximumEnvelopeBytes)
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
