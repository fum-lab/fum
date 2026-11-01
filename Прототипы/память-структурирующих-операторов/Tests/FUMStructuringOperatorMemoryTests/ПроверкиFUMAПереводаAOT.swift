import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

@Test func определениеПорождаетКонтрольныйИсходник() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = try Data(contentsOf: пути.вход)
  let текстВхода = String(decoding: вход, as: UTF8.self)
  let наблюдение = try AutomationExecutor.выполнить(
    определение, вход: .текст(текстВхода))
  let повтор = try AutomationExecutor.выполнить(
    определение, вход: .текст(текстВхода))
  #expect(наблюдение == повтор)

  guard case .текст(let текстРезультата) = наблюдение.результат else {
    Issue.record("FUMA-определение должно вернуть JSON-строку исходника")
    return
  }
  let исходник = try JSONDecoder().decode(String.self, from: Data(текстРезультата.utf8))
  let ожидание = String(decoding: try Data(contentsOf: пути.ожидаемыйИсходник), as: UTF8.self)
  #expect(Array(исходник.utf8) == Array(ожидание.utf8))
}

@Test(
  .disabled(
    "Исполнение AOT не допущено: компилятор не закреплён, а исполнитель Process/pipe не ограничивает ожидание и чтение вывода."
  )
)
func сгенерированныйИсходникКомпилируетсяИПобайтноСовпадаетСИнтерпретатором() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let данныеВхода = try Data(contentsOf: пути.вход)
  let вход = String(decoding: данныеВхода, as: UTF8.self)
  let наблюдение = try AutomationExecutor.выполнить(
    определение, вход: .текст(вход))
  guard case .текст(let текстРезультата) = наблюдение.результат else {
    Issue.record("FUMA-определение должно вернуть JSON-строку исходника")
    return
  }
  let исходник = try JSONDecoder().decode(String.self, from: Data(текстРезультата.utf8))
  var разборГрафа = try РазборОпределения(данныеВхода, входJSON: true)
  let граф = try ГрафJSON(разборГрафа.разобрать())
  let результатИнтерпретатора = try граф.вычислить(
    вход, пределБайтов: ПределыИсполнения().байтовРезультата, операция: {})
  let интерпретатор = Data(результатИнтерпретатора.utf8)

  let каталог = FileManager.default.temporaryDirectory
    .appendingPathComponent("fum-fuma-aot-join-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
  defer { try? FileManager.default.removeItem(at: каталог) }

  let файлИсходника = каталог.appendingPathComponent("generated.swift")
  let исполняемыйФайл = каталог.appendingPathComponent("generated")
  try Data(исходник.utf8).write(to: файлИсходника, options: .atomic)

  let сборка = try выполнитьПроцесс(
    URL(fileURLWithPath: "/usr/bin/env"),
    аргументы: [
      "swiftc", "-parse-as-library", "-swift-version", "6",
      "-strict-concurrency=complete", "-warnings-as-errors",
      файлИсходника.path, "-o", исполняемыйФайл.path,
    ])
  guard сборка.код == 0 else {
    Issue.record(
      "swiftc завершился кодом \(сборка.код): \(String(decoding: сборка.ошибки, as: UTF8.self))")
    return
  }

  let запуск = try выполнитьПроцесс(URL(fileURLWithPath: исполняемыйФайл.path), аргументы: [])
  #expect(запуск.код == 0)
  #expect(Array(запуск.вывод) == Array(интерпретатор))
}

@Test func определениеОтказываетПриПеременныхГрафа() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(decoding: try Data(contentsOf: пути.неподдержанныеПеременные), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался typed refusal для переменных графа")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

@Test func определениеОтказываетПриДополнительномКорневомАргументе() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(
    decoding: try Data(contentsOf: пути.неподдержанныйЛишнийАргумент), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался отказ для дополнительного корневого аргумента")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

@Test func определениеОтказываетПриСтрокеВместоМассиваПеременных() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(decoding: try Data(contentsOf: пути.неподдержаннаяСтрокаПеременных), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался отказ для строки вместо массива переменных")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

@Test func определениеОтказываетПриСлишкомДлинномМассивеОперандов() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(decoding: try Data(contentsOf: пути.неподдержанныйБольшойМассив), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался отказ для массива операндов больше 64 значений")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

@Test func определениеОтказываетПриДополнительномПолеВхода() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(decoding: try Data(contentsOf: пути.неподдержанноеДополнительноеПоле), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался отказ для дополнительного поля корневого объекта")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

@Test func определениеОтказываетПриСовпаденииЛитералаСМаркеромМассива() throws {
  let пути = ПутиПримераТрансляции()
  let определение = try ОпределениеОператора.разобрать(Data(contentsOf: пути.определение))
  let вход = String(decoding: try Data(contentsOf: пути.неподдержанныйМаркер), as: UTF8.self)

  do {
    _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    Issue.record("Ожидался typed refusal для зарезервированного маркера массива")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "диапазон-JSON")
  }
}

private struct ПутиПримераТрансляции {
  private let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()

  var определение: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Определения/aot-join-strings-swift.json")
  }

  var вход: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.input.json")
  }

  var ожидаемыйИсходник: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.expected.swift")
  }

  var неподдержанныеПеременные: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-variables.json")
  }

  var неподдержанныйМаркер: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-marker.json")
  }

  var неподдержанныйЛишнийАргумент: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-extra-argument.json")
  }

  var неподдержаннаяСтрокаПеременных: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-variables-string.json")
  }

  var неподдержанныйБольшойМассив: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-too-many.json")
  }

  var неподдержанноеДополнительноеПоле: URL {
    корень.appendingPathComponent(
      "Sources/FUMStructuringOperatorMemory/Фикстуры/aot-join-strings-swift.unsupported-extra-field.json")
  }
}

private struct РезультатПроцесса {
  let код: Int32
  let вывод: Data
  let ошибки: Data
}

private func выполнитьПроцесс(
  _ исполняемыйФайл: URL, аргументы: [String]
) throws -> РезультатПроцесса {
  let процесс = Process()
  процесс.executableURL = исполняемыйФайл
  процесс.arguments = аргументы
  let каналВывода = Pipe()
  let каналОшибок = Pipe()
  процесс.standardOutput = каналВывода
  процесс.standardError = каналОшибок
  try процесс.run()
  процесс.waitUntilExit()
  return РезультатПроцесса(
    код: процесс.terminationStatus,
    вывод: каналВывода.fileHandleForReading.readDataToEndOfFile(),
    ошибки: каналОшибок.fileHandleForReading.readDataToEndOfFile())
}
