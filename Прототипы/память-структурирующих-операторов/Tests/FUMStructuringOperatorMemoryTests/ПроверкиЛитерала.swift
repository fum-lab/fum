import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

@Test func кодированиеЛитералаСохраняетКаждыйСкалярВASCIIФорме() throws {
  let scalarValues: [UInt32] = [0, 0x451, 0x65, 0x308, 0x22, 0x5C, 0x1F642, 0x10FFFF]
  let scalars = scalarValues.compactMap(Unicode.Scalar.init)
  #expect(scalars.count == scalarValues.count)
  let input = String(String.UnicodeScalarView(scalars))
  let actual = try КодированиеЛитералаSwift.кодировать(
    input, пределИсходныхБайтов: 128, пределJSON: 256, операция: {})
  let expected = #""\u{0}\u{451}\u{65}\u{308}\u{22}\u{5c}\u{1f642}\u{10ffff}""#
  #expect(Array(actual.utf8) == Array(expected.utf8))
  #expect(actual.unicodeScalars.map(\.value) == expected.unicodeScalars.map(\.value))
  let jsonSize = try каноническиеДанные(УзелОпределения.строка(actual)).count
  do {
    _ = try КодированиеЛитералаSwift.кодировать(
      input, пределИсходныхБайтов: 128, пределJSON: jsonSize - 1, операция: {})
    Issue.record("Ожидался отказ на байт ниже фактического JSON-размера")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "предел-результата")
  }
}

@Test func кодированиеЛитералаПроверяетОбаРазмерныхБюджета() throws {
  let пустой = try КодированиеЛитералаSwift.кодировать(
    "", пределИсходныхБайтов: 2, пределJSON: 6, операция: {})
  #expect(Array(пустой.utf8) == Array("\"\"".utf8))

  let один = try КодированиеЛитералаSwift.кодировать(
    "a", пределИсходныхБайтов: 8, пределJSON: 13, операция: {})
  #expect(Array(один.utf8) == Array(#""\u{61}""#.utf8))
  #expect(try каноническиеДанные(УзелОпределения.строка(один)).count == 13)

  do {
    _ = try КодированиеЛитералаSwift.кодировать(
      "a", пределИсходныхБайтов: 7, пределJSON: 13, операция: {})
    Issue.record("Ожидался отказ на байт ниже размера исходника")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "предел-результата")
  }

  do {
    _ = try КодированиеЛитералаSwift.кодировать(
      "a", пределИсходныхБайтов: 8, пределJSON: 12, операция: {})
    Issue.record("Ожидался отказ на байт ниже размера JSON")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "предел-результата")
  }
}

@Test func кодированиеЛитералаОтказываетДляНеСтрокиИРаботаетВГрафе() throws {
  let input = #"{"текст":"ёe\u0301\"\\🙂"}"#
  let output = try выполнитьГрафСЛитералом(input)
  let source = #""\u{451}\u{65}\u{301}\u{22}\u{5c}\u{1f642}""#
  let expectedJSON = String(decoding: try каноническиеДанные(УзелОпределения.строка(source)), as: UTF8.self)
  #expect(output.результат == .текст(expectedJSON))

  do {
    _ = try выполнитьГрафСЛитералом("{}", выражение: #"["литерал-свифт",17]"#)
    Issue.record("Ожидался типизированный отказ для целого")
  } catch let ошибка as ОшибкаИсполнения {
    #expect(ошибка.код == "тип-JSON")
  }
}

private func выполнитьГрафСЛитералом(
  _ input: String,
  выражение: String = #"["литерал-свифт",["путь",["переменная","вход"],"текст"]]"#
) throws -> НаблюдениеОператора {
  let source = """
    {"схема":"fum.определение-оператора.1","идентификатор":"литерал","версия":1,
    "правила":[],"шаги":[{"идентификатор":"литерал","оператор":"вычислить-JSON",
    "аргументы":{"граф":{"схема":"fuma.граф-JSON.1","числа":"целые64-без-дробей",
    "переменные":[],"результат":\(выражение)}}}]}
    """
  return try AutomationExecutor.выполнить(
    ОпределениеОператора.разобрать(Data(source.utf8)), вход: .текст(input))
}
