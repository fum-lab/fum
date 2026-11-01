import Foundation
import Testing
import FUMStructuringOperatorMemory

private func материалыКвадратичнойТочки() throws -> (ОпределениеОператора, [String: Any]) {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  let пакет = корень.appendingPathComponent("fuma/packages/geometriya-glifa")
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: пакет.appendingPathComponent("квадратичная-точка.json")))
  let данные = try Data(contentsOf: пакет.appendingPathComponent("фикстура-квадратичной-точки.1.json"))
  let фикстура = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  #expect(фикстура["схема"] as? String == "fum.фикстура-квадратичной-точки.1")
  return (определение, фикстура)
}

private func текстВходаТочки(_ случай: [String: Any]) throws -> String {
  let вход = try #require(случай["вход"] as? [String: Any])
  let данные = try JSONSerialization.data(withJSONObject: вход, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func квадратичнаяТочкаСохраняетТочныеДробныеКоординаты() throws {
  let (определение, фикстура) = try материалыКвадратичнойТочки()
  let случаи = try #require(фикстура["случаи"] as? [[String: Any]])
  #expect(случаи.count == 8)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["начало", "четверть", "середина", "конец", "отрицательная-половина", "нижняя-граница-координат", "нечётные-удвоенные-координаты", "верхняя-граница-координат"]))
  for случай in случаи {
    let ожидается = try #require(случай["ожидается"] as? [String: Any])
    let вход = try текстВходаТочки(случай)
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(вход))
    guard case .текст(let текст) = исполнение.результат else {
      Issue.record("Ожидался JSON-текст с точной точкой")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(NSDictionary(dictionary: результат) == NSDictionary(dictionary: ожидается))
  }
}

@Test func квадратичнаяТочкаОтклоняетНедопустимыйВход() throws {
  let (определение, фикстура) = try материалыКвадратичнойТочки()
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 4)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["параметр-меньше-нуля", "параметр-больше-единицы", "недопустимая-невесомая-точка", "ниже-границы-координат"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let ожидаемыйКод = try #require(случай["ожидаемыйКод"] as? String)
    let вход = try текстВходаТочки(случай)
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
