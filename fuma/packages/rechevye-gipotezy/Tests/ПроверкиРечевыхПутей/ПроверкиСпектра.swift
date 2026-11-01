import Foundation
import Testing
import FUMStructuringOperatorMemory

private func материалыСпектра() throws -> (ОпределениеОператора, [String: Any]) {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: корень.appendingPathComponent("спектр-четырёх-отсчётов.json")))
  let данные = try Data(contentsOf: корень.appendingPathComponent("фикстура-спектра.1.json"))
  let фикстура = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  #expect(фикстура["схема"] as? String == "fum.синтетические-признаки-окна.1")
  return (определение, фикстура)
}

private func текстВходаСпектра(_ случай: [String: Any]) throws -> String {
  let вход = try #require(случай["вход"] as? [String: Any])
  let данные = try JSONSerialization.data(withJSONObject: вход, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func синтетическийСпектрИСопоставление() throws {
  let (определение, фикстура) = try материалыСпектра()
  let случаи = try #require(фикстура["наблюдения"] as? [[String: Any]])
  let таблица = try #require(фикстура["учебнаяТаблица"] as? [[String: Any]])
  #expect(случаи.count == 5)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["тишина", "импульс", "косинус", "синус", "удвоенная-амплитуда"]))

  for случай in случаи {
    let ожидаемоеНаблюдение = try #require(случай["ожидается"] as? [String: Any])
    let энергия = try #require(ожидаемоеНаблюдение["суммаКвадратов"] as? Int)
    let мощность = try #require(ожидаемоеНаблюдение["мощностьК1"] as? Int)
    let строки = таблица.filter { ($0["пара"] as? [Int]) == [энергия, мощность] }
    let остальные = таблица.filter { ($0["пара"] as? String) == "остальные" }
    #expect(строки.count <= 1)
    #expect(остальные.count == 1)
    let строка = try #require(строки.first ?? остальные.first)
    let ожидаемоеСопоставление = try #require(строка["ожидается"] as? [String: Any])

    let входнойТекст = try текстВходаСпектра(случай)
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
    guard case .текст(let текст) = исполнение.результат else {
      Issue.record("Ожидался JSON-текст с результатом обеих стадий")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(Set(результат.keys) == Set(["наблюдение", "сопоставление"]))
    let наблюдение = try #require(результат["наблюдение"] as? [String: Any])
    let сопоставление = try #require(результат["сопоставление"] as? [String: Any])
    #expect(NSDictionary(dictionary: наблюдение) == NSDictionary(dictionary: ожидаемоеНаблюдение))
    #expect(NSDictionary(dictionary: сопоставление) == NSDictionary(dictionary: ожидаемоеСопоставление))
    let повтор = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
    #expect(повтор.результат == исполнение.результат)
  }
}

@Test func некорректноеСинтетическоеОкноОтклоняется() throws {
  let (определение, фикстура) = try материалыСпектра()
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 2)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["неполное-окно", "отсчёт-за-пределом"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let код = try #require(случай["ожидаемыйКод"] as? String)
    let входнойТекст = try текстВходаСпектра(случай)
    do {
      _ = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
      Issue.record("Ожидался отказ для случая: \(имя)")
    } catch let ошибка as ОшибкаИсполнения {
      #expect(ошибка.код == код)
    } catch let ошибка {
      Issue.record("Неожиданный тип ошибки для случая \(имя): \(ошибка)")
    }
  }
}
