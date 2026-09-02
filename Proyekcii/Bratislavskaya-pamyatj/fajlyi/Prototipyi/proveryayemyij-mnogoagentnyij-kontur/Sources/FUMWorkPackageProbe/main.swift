import Darwin
import FUMDistributedEpisodeMemory
import FUMVerifiableMultiAgentContour
import Foundation

private func printUsage() {
  print(
    """
    Использование: FUMWorkPackageProbe [fixture [имя] | stdin | --list | episode <команда> | composition <команда> | fork <команда> | memory <команда> | live <команда> | acceptance <команда> | --help]

    Без аргументов анализирует положительную фикстуру ready.
    fixture [имя] анализирует встроенную фикстуру; без имени выбирается ready.
    stdin принимает один JSON-пакет версии 1 из стандартного ввода.
    --list печатает имена встроенных фикстур.

    episode fixture [имя] проверяет встроенный паспорт; без имени выбирается valid.
    episode stdin принимает JSON-паспорт эпизода версии 1.
    episode --list печатает имена фикстур паспорта.

    composition fixture [имя] проверяет репозиторную композицию; без имени выбирается valid.
    composition acceptance запускает автономную сквозную приёмку репозиторной композиции без сети и секретов.
    composition --list печатает имена фикстур репозиторной композиции.

    fork fixture [имя] запускает автономный сценарий долговечного fork-подузла; без имени выбирается roundtrip.
    fork --list печатает имена сценариев fork-подузла.

    цепочка присоединиться <checkout> <задача> создаёт ожидающий FIFO-билет продолжения.
    цепочка продолжение <checkout> <управление> <задача> ожидает передачу и выполняет один шаг в том же процессе.
    цепочка сессия <checkout> <управление> <задача> <режим> выполняет один возобновляемый шаг.

    memory bootstrap <каталог> публикует пустое подтверждённое поколение стенда.
    memory continue <каталог> <primary|adversarial> добавляет вклад через резервацию и settlement.
    memory verify <каталог> <фикстура> добавляет проверку через резервацию и settlement.
    memory show <каталог> повторно проигрывает и печатает CURRENT.

    live canonicalize <запрос.json> печатает канонические байты валидного запроса архива.
    live archive <запрос.json> <каталог-поколений> --repo-root <корень> публикует хэшированные артефакты живого прогона.
    live show <каталог-поколений> повторно читает и печатает подтверждённый CURRENT живого прогона.
    live --list печатает команды архива живого прогона.

    acceptance --list печатает имена автономных приёмочных сценариев.
    acceptance all --repo-root <каталог> запускает все сценарии без сети и секретов.

    Код завершения: 0 для ready/valid и успешной команды памяти, 3 для split_required/invalid или проверяемого отказа, 2 для ошибки команды либо фикстуры.
    """
  )
}

private func runLiveCommand(_ arguments: [String]) -> Never {
  if arguments == ["--list"] {
    print("canonicalize\narchive\nshow")
    exit(0)
  }

  do {
    let reportData: Data
    let writesExactCanonicalBytes: Bool
    if arguments.count == 2, arguments[0] == "canonicalize" {
      let requestURL = URL(fileURLWithPath: arguments[1], isDirectory: false)
      let requestData = try LiveDistributedRunArchive.readRequestFile(at: requestURL)
      reportData = try LiveDistributedRunArchive.canonicalizeRequest(requestData)
      writesExactCanonicalBytes = true
    } else if arguments.count == 5,
      arguments[0] == "archive",
      arguments[3] == "--repo-root"
    {
      let requestURL = URL(fileURLWithPath: arguments[1], isDirectory: false)
      let storeRoot = URL(fileURLWithPath: arguments[2], isDirectory: true)
      let repositoryRoot = URL(fileURLWithPath: arguments[4], isDirectory: true)
      let requestData = try LiveDistributedRunArchive.readRequestFile(at: requestURL)
      let publication = try LiveDistributedRunArchive.archivePublication(
        requestData: requestData,
        repositoryRoot: repositoryRoot,
        storeRoot: storeRoot
      )
      reportData = publication.reportData
      writesExactCanonicalBytes = false
    } else if arguments.count == 2, arguments[0] == "show" {
      let store = LiveDistributedRunArchiveStore(
        rootURL: URL(fileURLWithPath: arguments[1], isDirectory: true)
      )
      guard let current = try store.loadCurrent() else {
        fputs("Архив живого прогона ещё не имеет CURRENT.\n", stderr)
        exit(3)
      }
      reportData = try LiveDistributedRunArchiveReport(
        state: "replayed",
        generationSHA256: current.generationSHA256,
        generation: current.generation
      ).canonicalJSONData()
      writesExactCanonicalBytes = false
    } else {
      fputs("Неизвестная команда архива живого прогона. Используйте --help.\n", stderr)
      exit(2)
    }
    if writesExactCanonicalBytes {
      FileHandle.standardOutput.write(reportData)
    } else {
      writeLine(reportData, to: .standardOutput)
    }
    exit(0)
  } catch {
    fputs("Архив живого прогона отклонил команду: \(error)\n", stderr)
    exit(3)
  }
}

private func runAcceptanceCommand(_ arguments: [String]) -> Never {
  if arguments == ["--list"] {
    print(DistributedEpisodeAcceptance.scenarioIdentifiers.joined(separator: "\n"))
    exit(0)
  }

  if arguments.count == 3,
    arguments[0] == "all",
    arguments[1] == "--repo-root"
  {
    do {
      let report = try DistributedEpisodeAcceptance.runAll(
        repositoryRoot: URL(fileURLWithPath: arguments[2], isDirectory: true),
        probeExecutable: URL(
          fileURLWithPath: CommandLine.arguments[0],
          isDirectory: false
        ).standardizedFileURL
      )
      writeLine(try report.canonicalJSONData(), to: .standardOutput)
      exit(0)
    } catch {
      fputs("\(error)\n", stderr)
      exit(3)
    }
  }

  if arguments.count == 3, arguments[0] == "__stage" {
    do {
      try DistributedEpisodeAcceptance.runStage(
        named: arguments[1],
        storeRoot: URL(fileURLWithPath: arguments[2], isDirectory: true)
      )
      exit(0)
    } catch {
      fputs("\(error)\n", stderr)
      exit(3)
    }
  }

  fputs("Неизвестная команда автономной приёмки. Используйте --help.\n", stderr)
  exit(2)
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
      let ordinal = current.generation.eventJournal.entries.count + 1
      let roundID = "round.memory.contribution.\(ordinal)"
      let reservedBudget = try SharedEpisodeControlKernel.meteredUsage(
        for: contribution,
        executors: current.generation.state.controlState.usedExecutorIDs.contains(
          contribution.provenance.executorID
        ) ? 0 : 1,
        rounds: current.generation.state.controlState.usedRoundIDs.contains(roundID)
          ? 0 : 1
      )
      let reservation = SharedEpisodeActionReservation(
        permitID: "permit.memory.contribution.\(ordinal)",
        actionID: "action.memory.contribution.\(ordinal)",
        parentGenerationSHA256: current.generationSHA256,
        phase: .productive,
        kind: .contribution,
        executorID: contribution.provenance.executorID,
        roundID: roundID,
        continuationID: nil,
        distinguishingCheckID: nil,
        reserved: reservedBudget
      )
      let reserved = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: current.generation,
          control: .actionReserved(reservation)
        )
      )
      stored = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: reserved.generation,
          control: .contribution(
            contribution.rebinding(
              parentGenerationSHA256: reserved.generationSHA256
            ),
            SharedEpisodeActionSettlement(
              permitID: reservation.permitID,
              actionID: reservation.actionID,
              actual: reservedBudget
            )
          )
        )
      )
    case "verify" where arguments.count == 3:
      guard let fixture = SharedEpisodeVerificationFixture(rawValue: arguments[2]) else {
        fputs("Неизвестная проверка стенда.\n", stderr)
        exit(2)
      }
      let current = try store.loadCurrent()
      guard let current else {
        fputs("Память стенда ещё не имеет CURRENT.\n", stderr)
        exit(3)
      }
      let verification = try SharedEpisodeMemoryFixtures.verification(
        named: fixture,
        parentGenerationSHA256: current.generationSHA256
      )
      let ordinal = current.generation.eventJournal.entries.count + 1
      let roundID = "round.memory.verification.\(ordinal)"
      let reservedBudget = try SharedEpisodeControlKernel.meteredUsage(
        for: verification,
        executors: current.generation.state.controlState.usedExecutorIDs.contains(
          verification.provenance.executorID
        ) ? 0 : 1,
        rounds: current.generation.state.controlState.usedRoundIDs.contains(roundID)
          ? 0 : 1
      )
      let reservation = SharedEpisodeActionReservation(
        permitID: "permit.memory.verification.\(ordinal)",
        actionID: "action.memory.verification.\(ordinal)",
        parentGenerationSHA256: current.generationSHA256,
        phase: .verification,
        kind: .verification,
        executorID: verification.provenance.executorID,
        roundID: roundID,
        continuationID: nil,
        distinguishingCheckID: nil,
        reserved: reservedBudget
      )
      let reserved = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: current.generation,
          control: .actionReserved(reservation)
        )
      )
      stored = try store.commit(
        SharedEpisodeMemoryReducer.continuation(
          from: reserved.generation,
          control: .verification(
            verification.rebinding(
              parentGenerationSHA256: reserved.generationSHA256
            ),
            SharedEpisodeActionSettlement(
              permitID: reservation.permitID,
              actionID: reservation.actionID,
              actual: reservedBudget
            )
          )
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

private func runCompositionCommand(_ arguments: [String]) -> Never {
  if arguments == ["--list"] {
    print(RepositoryCompositionFixtures.identifiers.joined(separator: "\n"))
    exit(0)
  }

  if arguments == ["acceptance"] {
    do {
      let отчёт = try СквознаяПриёмкаРепозиторнойКомпозиции.выполнить()
      writeLine(try отчёт.каноническиеДанные(), to: .standardOutput)
      exit(отчёт.решение == .принято ? 0 : 3)
    } catch {
      fputs("Сквозная приёмка репозиторной композиции завершилась ошибкой: \(error)\n", stderr)
      exit(2)
    }
  }

  let identifier: String
  if arguments == ["fixture"] {
    identifier = "valid"
  } else if arguments.count == 2, arguments[0] == "fixture" {
    identifier = arguments[1]
  } else {
    fputs("Неизвестная команда репозиторной композиции. Используйте --help.\n", stderr)
    exit(2)
  }

  do {
    let result: (reportData: Data, isValid: Bool) =
      try RepositoryCompositionFixtures.withFixture(named: identifier) { fixture in
        let report = RepositoryCompositionPreflight.analyze(
          fixture.passportData,
          context: fixture.context
        )
        return (try report.canonicalJSONData(), report.decision == .valid)
      }
    writeLine(result.reportData, to: .standardOutput)
    exit(result.isValid ? 0 : 3)
  } catch {
    fputs("Не удалось проверить репозиторную композицию: \(error)\n", stderr)
    exit(2)
  }
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

private func runForkCommand(_ arguments: [String]) -> Never {
  if arguments == ["--list"] {
    print(DurableForkSubnodeFixtures.identifiers.joined(separator: "\n"))
    exit(0)
  }
  let identifier: String
  if arguments == [] || arguments == ["fixture"] {
    identifier = "roundtrip"
  } else if arguments.count == 2, arguments[0] == "fixture" {
    identifier = arguments[1]
  } else {
    fputs("Неизвестная команда fork-подузла. Используйте --help.\n", stderr)
    exit(2)
  }
  do {
    let report = try DurableForkSubnodeFixtures.run(named: identifier)
    writeLine(try report.canonicalJSONData(), to: .standardOutput)
    exit(report.decision == .passed ? 0 : 3)
  } catch {
    fputs("Сценарий fork-подузла отклонён: \(error)\n", stderr)
    exit(2)
  }
}

private func выполнитьКомандуКонечнойЦепочки(_ аргументы: [String]) -> Never {
  do {
    if аргументы.count == 3, аргументы[0] == "присоединиться" {
      let данные = try КомандыВозобновляемойКонечнойЦепочки.присоединиться(
        кореньЧекаута: URL(fileURLWithPath: аргументы[1], isDirectory: true),
        идентификаторЗадачи: аргументы[2]
      )
      writeLine(данные, to: .standardOutput)
      exit(0)
    }

    if аргументы.count == 4, аргументы[0] == "продолжение" {
      let отчёт = try КомандыВозобновляемойКонечнойЦепочки.выполнитьПродолжение(
        кореньЧекаута: URL(fileURLWithPath: аргументы[1], isDirectory: true),
        кореньУправления: URL(fileURLWithPath: аргументы[2], isDirectory: true),
        идентификаторЗадачи: аргументы[3],
        исполняемыйФайлПробника: URL(
          fileURLWithPath: CommandLine.arguments[0],
          isDirectory: false
        ).standardizedFileURL
      )
      writeLine(try отчёт.каноническиеДанные(), to: .standardOutput)
      exit(0)
    }

    if аргументы.count == 5, аргументы[0] == "сессия",
      let режим = РежимСессииВозобновляемойЦепочки(rawValue: аргументы[4])
    {
      let отчёт = try КомандыВозобновляемойКонечнойЦепочки.выполнитьСессию(
        кореньЧекаута: URL(fileURLWithPath: аргументы[1], isDirectory: true),
        кореньУправления: URL(fileURLWithPath: аргументы[2], isDirectory: true),
        идентификаторЗадачи: аргументы[3],
        исполняемыйФайлПробника: URL(
          fileURLWithPath: CommandLine.arguments[0],
          isDirectory: false
        ).standardizedFileURL,
        режим: режим
      )
      writeLine(try отчёт.каноническиеДанные(), to: .standardOutput)
      exit(0)
    }
  } catch {
    let пояснение =
      (error as? ОшибкаВозобновляемогоИсполненияКонечнойЦепочки)?
      .пояснение() ?? String(describing: error)
    fputs("Возобновляемая конечная цепочка отклонила команду: \(пояснение)\n", stderr)
    exit(3)
  }

  fputs("Неизвестная команда конечной цепочки. Используйте --help.\n", stderr)
  exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.first == "цепочка" {
  выполнитьКомандуКонечнойЦепочки(Array(arguments.dropFirst()))
}
if arguments.first == "composition" {
  runCompositionCommand(Array(arguments.dropFirst()))
}
if arguments.first == "acceptance" {
  runAcceptanceCommand(Array(arguments.dropFirst()))
}
if arguments.first == "memory" {
  runMemoryCommand(Array(arguments.dropFirst()))
}
if arguments.first == "live" {
  runLiveCommand(Array(arguments.dropFirst()))
}
if arguments.first == "episode" {
  runEpisodeCommand(Array(arguments.dropFirst()))
}
if arguments.first == "fork" {
  runForkCommand(Array(arguments.dropFirst()))
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
