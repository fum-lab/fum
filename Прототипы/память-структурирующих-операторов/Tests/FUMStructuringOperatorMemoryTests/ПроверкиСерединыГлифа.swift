import Foundation
import Testing
import FUMStructuringOperatorMemory

private func каталогГеометрииГлифа() -> URL {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
  return корень.appendingPathComponent("fuma/packages/geometriya-glifa")
}

private func материалыСередины() throws -> (ОпределениеОператора, [String: Any]) {
  let пакет = каталогГеометрииГлифа()
  let определение = try ОпределениеОператора.разобрать(
    Data(contentsOf: пакет.appendingPathComponent("середина-контрольных-точек.json")))
  let данные = try Data(contentsOf: пакет.appendingPathComponent("фикстура-середины.1.json"))
  let фикстура = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  #expect(фикстура["схема"] as? String == "fum.фикстура-середины-контрольных-точек.1")
  return (определение, фикстура)
}

private func текстОбъектаСередины(_ объект: [String: Any]) throws -> String {
  let данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
  return try #require(String(data: данные, encoding: .utf8))
}

@Test func серединаКонтрольныхТочекБезОкругления() throws {
  let (определение, фикстура) = try материалыСередины()
  let случаи = try #require(фикстура["случаи"] as? [[String: Any]])
  #expect(случаи.count == 6)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["полуцелая-середина", "обратный-порядок", "границы", "первая-на-кривой", "вторая-на-кривой", "обе-на-кривой"]))
  for случай in случаи {
    let вход = try #require(случай["вход"] as? [String: Any])
    let ожидается = try #require(случай["ожидается"] as? [String: Any])
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(текстОбъектаСередины(вход)))
    guard case .текст(let текст) = исполнение.результат else {
      Issue.record("Ожидался JSON-текст середины")
      continue
    }
    let результат = try #require(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
    #expect(NSDictionary(dictionary: результат) == NSDictionary(dictionary: ожидается))
  }
}

@Test func некорректнаяКонтрольнаяТочкаНеСкрываетсяЗаНеприменимостью() throws {
  let (определение, фикстура) = try материалыСередины()
  let случаи = try #require(фикстура["отказы"] as? [[String: Any]])
  #expect(случаи.count == 4)
  #expect(Set(случаи.compactMap { $0["имя"] as? String }) ==
    Set(["второй-флаг-не-логический", "вторая-координата-за-пределом", "нет-второго-флага", "строка-вместо-координаты"]))
  for случай in случаи {
    let имя = try #require(случай["имя"] as? String)
    let ожидаемыйКод = try #require(случай["ожидаемыйКод"] as? String)
    let вход = try #require(случай["вход"] as? [String: Any])
    do {
      _ = try AutomationExecutor.выполнить(определение, вход: .текст(текстОбъектаСередины(вход)))
      Issue.record("Ожидался отказ для случая: \(имя)")
    } catch let ошибка as ОшибкаИсполнения {
      #expect(ошибка.код == ожидаемыйКод)
    } catch let ошибка {
      Issue.record("Неожиданный тип ошибки для случая \(имя): \(ошибка)")
    }
  }
}

@Test func переданнаяСерединаМожетБытьКонцомУсловногоКвадратичногоСегмента() throws {
  let (середина, _) = try материалыСередины()
  let входСередины: [String: Any] = [
    "первая": ["икс": 0, "игрек": 0, "наКривой": false],
    "вторая": ["икс": 1, "игрек": 1, "наКривой": false]
  ]
  let наблюдение = try AutomationExecutor.выполнить(середина, вход: .текст(текстОбъектаСередины(входСередины)))
  guard case .текст(let текстСередины) = наблюдение.результат else {
    Issue.record("Ожидался JSON-текст середины")
    return
  }
  let конец = try #require(JSONSerialization.jsonObject(with: Data(текстСередины.utf8)) as? [String: Any])
  #expect(конец["статус"] as? String == "условная-точка")
  #expect(конец["соседство"] as? String == "неизвестно")
  let пакет = каталогГеометрииГлифа()
  let кривая = try ОпределениеОператора.разобрать(
    Data(contentsOf: пакет.appendingPathComponent("квадратичная-точка.json")))
  let входКривой: [String: Any] = [
    "начало": ["иксДважды": 0, "игрекДважды": 0],
    "управление": ["иксДважды": 0, "игрекДважды": 0],
    "конец": конец,
    "параметрИз256": 128
  ]
  let вычисление = try AutomationExecutor.выполнить(кривая, вход: .текст(текстОбъектаСередины(входКривой)))
  guard case .текст(let текстКривой) = вычисление.результат else {
    Issue.record("Ожидался JSON-текст точки кривой")
    return
  }
  let точка = try #require(JSONSerialization.jsonObject(with: Data(текстКривой.utf8)) as? [String: Any])
  let ожидается: [String: Any] = [
    "параметрИз256": 128, "числительИкс": 16384,
    "числительИгрек": 16384, "знаменатель": 131072
  ]
  #expect(NSDictionary(dictionary: точка) == NSDictionary(dictionary: ожидается))
}
