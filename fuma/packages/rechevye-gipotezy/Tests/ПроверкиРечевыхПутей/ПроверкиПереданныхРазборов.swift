import Foundation
import Testing
import FUMStructuringOperatorMemory

private func материалыРазборов() throws -> (ОпределениеОператора, [String: Any]) {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: корень.appendingPathComponent("сопоставление-переданных-разборов.json")))
  let данные = try Data(contentsOf: корень.appendingPathComponent("фикстура-переданных-разборов.1.json"))
  let фикстура = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  #expect(фикстура["схема"] as? String == "fum.фикстура-переданных-разборов.1")
  return (определение, фикстура)
}

private func текстВходаРазборов(_ случай: [String: Any]) throws -> String {
  let вход = try #require(случай["вход"] as? [String: Any])
  let данные = try JSONSerialization.data(withJSONObject: вход, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func сохраняютсяВсеПереданныеРазборыИНеизвестнаяПолнота() throws {
  let (определение, фикстура) = try материалыРазборов()
  let случаи = try #require(фикстура["случаи"] as? [[String: Any]])
  #expect(случаи.count == 4)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["две-альтернативы", "без-анализа", "ё-и-е", "разные-скаляры"]))
  for случай in случаи {
    let ожидается = try #require(случай["ожидается"] as? [String: Any])
    let вход = try текстВходаРазборов(случай)
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    guard case .текст(let текст) = исполнение.результат else {
      Issue.record("Ожидался JSON-текст с переданными разборами")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(NSDictionary(dictionary: результат) == NSDictionary(dictionary: ожидается))
    let полученные = try #require(результат["альтернативы"] as? [[String: Any]])
    let ожидаемые = try #require(ожидается["альтернативы"] as? [[String: Any]])
    #expect(полученные.count == ожидаемые.count)
    for (полученный, ожидаемый) in zip(полученные, ожидаемые) {
      let полученныйРазбор = try #require(полученный["разбор"] as? [String: Any])
      let ожидаемыйРазбор = try #require(ожидаемый["разбор"] as? [String: Any])
      let форма = try #require(полученныйРазбор["форма"] as? String)
      let ожидаемаяФорма = try #require(ожидаемыйРазбор["форма"] as? String)
      #expect(Data(форма.utf8) == Data(ожидаемаяФорма.utf8))
    }
  }
}

@Test func некорректныеПереданныеРазборыНеСтановятсяОтрицательнымСовпадением() throws {
  let (определение, фикстура) = try материалыРазборов()
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 4)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["нет-формы", "пустой-кандидат", "пустая-форма", "нестроковая-форма"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let ожидаемыйКод = try #require(случай["ожидаемыйКод"] as? String)
    let вход = try текстВходаРазборов(случай)
    do {
      _ = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
      Issue.record("Ожидался отказ для случая: \(имя)")
    } catch let ошибка as ОшибкаИсполнения {
      #expect(ошибка.код == ожидаемыйКод)
    } catch let ошибка {
      Issue.record("Неожиданный тип ошибки для случая \(имя): \(ошибка)")
    }
  }
}
