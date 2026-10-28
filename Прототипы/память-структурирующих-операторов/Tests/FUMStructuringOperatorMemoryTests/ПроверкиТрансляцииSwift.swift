import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

@Test func трансляторОтклоняетНеподдержаннуюОперацию() throws {
  let граф = try графДляТрансляции(.массив([.строка("умножить"), .целое(2), .целое(3)]))
  do {
    _ = try ТрансляторГрафаSwift.перевести(
      граф, пределИсходника: ПределыИсполнения().байтовРезультата)
    Issue.record("Ожидался типизированный отказ для неподдержанной операции")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "aot-операция")
  }
}

@Test func трансляторСтабиленИОграничиваетИсходник() throws {
  let граф = try графСоединения(["a", "ё"], разделитель: "|")
  let предел = ПределыИсполнения().байтовРезультата
  let исходник = try ТрансляторГрафаSwift.перевести(граф, пределИсходника: предел)
  let повтор = try ТрансляторГрафаSwift.перевести(граф, пределИсходника: предел)
  #expect(Array(исходник.utf8) == Array(повтор.utf8))

  let точныйПредел = исходник.utf8.count
  #expect(try ТрансляторГрафаSwift.перевести(граф, пределИсходника: точныйПредел) == исходник)
  do {
    _ = try ТрансляторГрафаSwift.перевести(граф, пределИсходника: точныйПредел - 1)
    Issue.record("Ожидался отказ на байт ниже размера исходника")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "предел-исходника-aot")
  }
}

@Test func переведённыйИсходникПобайтноСовпадаетСИнтерпретатором() throws {
  let строки = ["A", "ё", "е\u{0301}", "\"\\", "🙂", "\u{0}"]
  let граф = try графСоединения(строки, разделитель: String(repeating: "x", count: 48))
  let пределПоУмолчанию = ПределыИсполнения().байтовРезультата
  let результатИнтерпретатора = try граф.вычислить("{}", пределБайтов: пределПоУмолчанию, операция: {})
  let ожидаемыеБайты = Data(результатИнтерпретатора.utf8)
  #expect(try граф.вычислить(
    "{}", пределБайтов: ожидаемыеБайты.count, операция: {}) == результатИнтерпретатора)
  do {
    _ = try граф.вычислить("{}", пределБайтов: ожидаемыеБайты.count - 1, операция: {})
    Issue.record("Интерпретатор должен отказать на байт ниже JSON-результата")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "предел-результата")
  }
  let исходник = try ТрансляторГрафаSwift.перевести(
    граф, пределИсходника: пределПоУмолчанию)

  let каталог = FileManager.default.temporaryDirectory
    .appendingPathComponent("fum-aot-join-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
  defer { try? FileManager.default.removeItem(at: каталог) }

  let файлИсходника = каталог.appendingPathComponent("generated.swift")
  let исполняемыйФайл = каталог.appendingPathComponent("generated")
  try Data(исходник.utf8).write(to: файлИсходника, options: .atomic)
  let сборка = try запустить(
    URL(fileURLWithPath: "/usr/bin/env"),
    аргументы: [
      "swiftc", "-parse-as-library", "-swift-version", "6", "-strict-concurrency=complete",
      "-warnings-as-errors",
      файлИсходника.path, "-o", исполняемыйФайл.path,
    ])
  guard сборка.код == 0 else {
    let текстОшибкиСборки = String(decoding: сборка.выводОшибок, as: UTF8.self)
    Issue.record("swiftc завершился кодом \(сборка.код): \(текстОшибкиСборки)")
    return
  }

  let точныйПредел = ожидаемыеБайты.count
  let исполнение = try запустить(URL(fileURLWithPath: исполняемыйФайл.path), аргументы: [String(точныйПредел)])
  #expect(исполнение.код == 0)
  #expect(Array(исполнение.вывод) == Array(ожидаемыеБайты))

  let наБайтНиже = try запустить(
    URL(fileURLWithPath: исполняемыйФайл.path), аргументы: [String(точныйПредел - 1)])
  #expect(наБайтНиже.код != 0)
  #expect(наБайтНиже.вывод.isEmpty)
}

private func графСоединения(_ строки: [String], разделитель: String) throws -> ГрафJSON {
  let элементы = [.строка("массив")] + строки.map { УзелОпределения.строка($0) }
  return try графДляТрансляции(.массив([
    .строка("соединить-строки"), .массив(элементы), .строка(разделитель),
  ]))
}

private func графДляТрансляции(_ результат: УзелОпределения) throws -> ГрафJSON {
  try ГрафJSON(.объект([
    "схема": .строка("fuma.граф-JSON.1"),
    "числа": .строка("целые64-без-дробей"),
    "переменные": .массив([]),
    "результат": результат,
  ]))
}

private struct РезультатПроцесса {
  let код: Int32
  let вывод: Data
  let выводОшибок: Data
}

private func запустить(_ цельИсполняемогоФайла: URL, аргументы: [String]) throws -> РезультатПроцесса {
  let процесс = Process()
  процесс.executableURL = цельИсполняемогоФайла
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
    выводОшибок: каналОшибок.fileHandleForReading.readDataToEndOfFile())
}
