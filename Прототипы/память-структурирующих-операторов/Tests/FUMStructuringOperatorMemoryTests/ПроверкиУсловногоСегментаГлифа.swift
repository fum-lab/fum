import Foundation
import Testing
import FUMStructuringOperatorMemory

private func каталогУсловногоСегмента() -> URL {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  return корень.appendingPathComponent("fuma/packages/geometriya-glifa")
}

private func объектУсловногоСегмента(_ имя: String) throws -> [String: Any] {
  let данные = try Data(contentsOf: каталогУсловногоСегмента().appendingPathComponent(имя))
  return try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
}

private func текстУсловногоСегмента(_ объект: [String: Any]) throws -> String {
  let данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func замыканиеУсловногоСегментаСовпадаетСИсходнымиГрафами() throws {
  let замыкание = try объектУсловногоСегмента("условный-сегмент.json")
  let определения = try #require(замыкание["определения"] as? [[String: Any]])
  #expect(определения.count == 2)
  for (имя, файл) in [
    ("условная-середина", "середина-контрольных-точек.json"),
    ("квадратичная-точка", "квадратичная-точка.json")
  ] {
    let совпадения = определения.filter { $0["идентификатор"] as? String == имя }
    #expect(совпадения.count == 1)
    let встроенное = try #require(совпадения.first)
    #expect(встроенное["версия"] as? Int == 1)
    let граф = try #require(встроенное["граф"] as? [String: Any])
    let исходник = try объектУсловногоСегмента(файл)
    let шаги = try #require(исходник["шаги"] as? [[String: Any]])
    #expect(шаги.count == 1)
    let шаг = try #require(шаги.first)
    let аргументы = try #require(шаг["аргументы"] as? [String: Any])
    let исходныйГраф = try #require(аргументы["граф"] as? [String: Any])
    #expect(NSDictionary(dictionary: граф) == NSDictionary(dictionary: исходныйГраф))
  }
}

@Test func условныйСегментСохраняетНеопределённостьИПорядокПрименений() throws {
  let пакет = каталогУсловногоСегмента()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: пакет.appendingPathComponent("условный-сегмент.json")))
  let фикстура = try объектУсловногоСегмента("фикстура-условного-сегмента.1.json")
  #expect(фикстура["схема"] as? String == "fum.фикстура-условного-сегмента.1")
  let случаи = try #require(фикстура["случаи"] as? [[String: Any]])
  #expect(случаи.count == 3)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["условная-полуцелая", "отрицательная-полуцелая", "неприменимо"]))
  for случай in случаи {
    let вход = try #require(случай["вход"] as? [String: Any])
    let ожидается = try #require(случай["ожидается"] as? [String: Any])
    let ожидаемыеПрименения = try #require(случай["применения"] as? [String])
    let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(текстУсловногоСегмента(вход)))
    guard case .текст(let текст) = наблюдение.результат else {
      Issue.record("Ожидался JSON-текст условной геометрии")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(NSDictionary(dictionary: результат) == NSDictionary(dictionary: ожидается))
    #expect(наблюдение.версияСчётчика == 2)
    #expect(наблюдение.пропущеноПрименений == 0)
    let применения = try #require(наблюдение.применения)
    #expect(применения.map(\.определение) == ожидаемыеПрименения)
  }
}

@Test func условныйСегментНеСкрываетНекорректныйВход() throws {
  let пакет = каталогУсловногоСегмента()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: пакет.appendingPathComponent("условный-сегмент.json")))
  let фикстура = try объектУсловногоСегмента("фикстура-условного-сегмента.1.json")
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 3)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["неверный-второй-флаг", "неверный-параметр-при-неприменимости", "нет-координаты-начала"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let код = try #require(случай["ожидаемыйКод"] as? String)
    let вход = try #require(случай["вход"] as? [String: Any])
    do {
      _ = try AutomationExecutor.выполнить(определение, вход: .текст(текстУсловногоСегмента(вход)))
      Issue.record("Ожидался отказ для случая: \(имя)")
    } catch let ошибка as ОшибкаИсполнения {
      #expect(ошибка.код == код)
    } catch let ошибка {
      Issue.record("Неожиданный тип ошибки для случая \(имя): \(ошибка)")
    }
  }
}
