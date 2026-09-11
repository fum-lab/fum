import FUMStructuringOperatorMemory
import Foundation

@main
struct FUMStructuringOperatorMemoryProbe {
  static func main() {
    do {
      let arguments = Array(CommandLine.arguments.dropFirst())
      if arguments.first == "исполнить" {
        try исполнить(Array(arguments.dropFirst()))
        return
      }
      let suite = try ScenarioFixtureLoader.loadBundledSuite()
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
            FUMStructuringOperatorMemoryProbe исполнить --определение <JSON> --вход байты|текст|скаляры [--профиль]

          The default run is local, deterministic, fixture-only, and performs no external effects.
          Чистое исполнение читает отдельный конечный stdin. Результат JSON — stdout;
          при --профиль длительности стадий JSONL — stderr. Ошибка не выдаёт частичный результат.
          """)
      default:
        throw OperatorMemoryError.invalidFixture("unknown command")
      }
    } catch let отказ as ОшибкаИсполнения {
      if let данные = try? каноническиеДанные(отказ) {
        FileHandle.standardError.write(данные + Data("\n".utf8))
      }
      exit(EXIT_FAILURE)
    } catch {
      FileHandle.standardError.write(Data("error: \(error)\n".utf8))
      exit(EXIT_FAILURE)
    }
  }

  private static func исполнить(_ аргументы: [String]) throws {
    let параметры = try ПараметрыИсполнения.разобрать(аргументы)
    let начало = DispatchTime.now().uptimeNanoseconds
    let данные = try КонечныйВвод.определение(параметры.путьОпределения)
    let входныеДанные = try КонечныйВвод.прочитать(.standardInput, предел: 262_144)
    var замеры = [ЗамерИсполнения]()
    // Отдельный замер загрузки не включает проверку определения и исполнение.
    let длительностьЗагрузки = DispatchTime.now().uptimeNanoseconds - начало
    if параметры.профиль {
      let запись = ЗамерИсполнения(
        стадия: "загрузка", наносекунды: длительностьЗагрузки, исход: "успешно")
      FileHandle.standardError.write(try каноническиеДанные(запись) + Data("\n".utf8))
    }
    let началоРазбора = DispatchTime.now().uptimeNanoseconds
    let определение = try ОпределениеОператора.разобрать(данные)
    let вход = try параметры.значение(входныеДанные)
    if параметры.профиль {
      let запись = ЗамерИсполнения(
        стадия: "разбор",
        наносекунды: DispatchTime.now().uptimeNanoseconds - началоРазбора,
        исход: "успешно")
      FileHandle.standardError.write(try каноническиеДанные(запись) + Data("\n".utf8))
    }
    defer {
      if параметры.профиль {
        for замер in замеры {
          if let данные = try? каноническиеДанные(замер) {
            FileHandle.standardError.write(данные + Data("\n".utf8))
          }
        }
      }
    }
    let наблюдение = try AutomationExecutor.выполнить(определение, вход: вход) { замеры.append($0) }
    FileHandle.standardOutput.write(try каноническиеДанные(наблюдение) + Data("\n".utf8))
  }

  private static func printCanonical<T: Encodable>(_ value: T) throws {
    let data = try canonicalJSONData(value)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
  }
}
