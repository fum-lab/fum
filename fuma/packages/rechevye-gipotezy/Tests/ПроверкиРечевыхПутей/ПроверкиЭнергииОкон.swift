import Foundation
import Testing
import FUMStructuringOperatorMemory

private func материалыЭнергииОкон() throws -> (ОпределениеОператора, [String: Any]) {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: корень.appendingPathComponent("энергия-окон.json")))
  let данные = try Data(contentsOf: корень.appendingPathComponent("фикстура-энергии-окон.1.json"))
  let фикстура = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  #expect(фикстура["схема"] as? String == "fum.синтетическая-энергия-окон.1")
  return (определение, фикстура)
}

private func текстВходаЭнергии(_ случай: [String: Any]) throws -> String {
  let вход = try #require(случай["вход"] as? [String: Any])
  let данные = try JSONSerialization.data(withJSONObject: вход, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func синтетическаяЭнергияОконСохраняетПорядокИГраницы() throws {
  let (определение, фикстура) = try материалыЭнергииОкон()
  let случаи = try #require(фикстура["случаи"] as? [[String: Any]])
  #expect(случаи.count == 4)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["тишина-и-период", "перекрытие-и-повтор", "граница-значений", "разные-окна-одинаковая-энергия"]))
  for случай in случаи {
    let ожидается = try #require(случай["ожидается"] as? [String: Any])
    let вход = try текстВходаЭнергии(случай)
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    guard case .текст(let текст) = исполнение.результат else {
      Issue.record("Ожидался JSON-текст с окнами")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(NSDictionary(dictionary: результат) == NSDictionary(dictionary: ожидается))
    let повтор = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    #expect(повтор.результат == исполнение.результат)
  }
}

@Test func синтетическаяЭнергияОтклоняетНедопустимыеОкна() throws {
  let (определение, фикстура) = try материалыЭнергииОкон()
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 7)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["короткий-сигнал", "окно-за-концом", "нет-окон", "значение-за-пределом",
      "отрицательное-начало", "слишком-много-окон", "нулевая-частота"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let ожидаемыйКод = try #require(случай["ожидаемыйКод"] as? String)
    let вход = try текстВходаЭнергии(случай)
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
