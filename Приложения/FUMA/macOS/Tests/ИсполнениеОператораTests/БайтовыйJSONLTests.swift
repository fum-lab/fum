import FUMStructuringOperatorMemory
import Foundation
import XCTest
import АрхивныйСнимокЗадачи
import КонтейнерНаблюдений

@testable import ИсполнениеОператора

extension ПроверкиИсполнения {
  private struct ОтветБайтовойПроверки: Decodable {
    let схема: String
    let квитанция: Квитанция
    let наблюдение: НаблюдениеБайтовойПроверки
  }

  private struct НаблюдениеБайтовойПроверки: Decodable {
    struct Результат: Decodable {
      let тип: String
      let значение: String
    }
    let типВхода: String
    let результат: Результат
    let хэшНаблюдения: String
  }

  private func программаЖурналаДляБайтовойПроверки() throws -> Data {
    let путь = try XCTUnwrap(ProcessInfo.processInfo.environment["ФУМА_ПРОГРАММА_ЖУРНАЛА"])
    let данные = try Data(contentsOf: URL(fileURLWithPath: путь))
    XCTAssertEqual(
      хэшБайтовСреза(данные), "6bb83002feb375d36b96c25d6b7a34820e3482188ddb2c6ac11c4deb21fa61f7")
    return данные
  }

  private func программыБайтовойПроверки() throws -> (Data, Data) {
    let текстоваяПрограмма = try программаЖурналаДляБайтовойПроверки()
    var байтоваяПрограмма = try объект(текстоваяПрограмма)
    let декодер = try объект(РесурсыОпределений.прочитать("UTF-8-в-UTF-32LE"))
    let шагиДекодера = try XCTUnwrap(декодер["шаги"] as? [[String: Any]])
    let декодирование = try XCTUnwrap(шагиДекодера.first)
    let прежниеШаги = try XCTUnwrap(байтоваяПрограмма["шаги"] as? [[String: Any]])
    байтоваяПрограмма["идентификатор"] = "байтовые-сообщения-журнала-Codex"
    байтоваяПрограмма["правила"] = try XCTUnwrap(декодер["правила"] as? [[String: Any]])
    let соединение: [String: Any] = [
      "идентификатор": "соединить-скаляры", "оператор": "скаляры-в-текст",
      "аргументы": ["версия": 1],
    ]
    байтоваяПрограмма["шаги"] = [декодирование, соединение] + прежниеШаги
    let байтовоеОпределение = try JSONSerialization.data(
      withJSONObject: байтоваяПрограмма, options: [.sortedKeys])
    return (текстоваяПрограмма, байтовоеОпределение)
  }

  private struct ПроводПринятыхБайтов: Codable, Equatable {
    struct Профиль: Codable, Equatable {
      let схема: String
      let байтовВхода: Int
      let байтовРезультата: Int
      let операций: Int
      let записейТрассы: Int
    }
    let исходноеОпределение: Data
    let определение: Data
    let вход: Data
    let типВхода: String
    let профиль: Профиль
  }

  func testБайтоваяПроекцияТрёхРамокИспользуетПрежниеГраницы() throws {
    let (текстовая, байтовая) = try программыБайтовойПроверки()
    let строки = [
      #"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Ё🙂e\u0301\n"},{"type":"output_image"},{"type":"input_text","text":""}]}}"#,
      #"{"type":"response_item","payload":{"type":"reasoning"}}"#,
      #"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"повтор\nЁ"}]}}"#,
    ]
    let поток = Data((строки.joined(separator: "\n") + "\n").utf8)
    let выделенные = try выделитьРамкиПотока(поток)
    XCTAssertEqual(выделенные.рамки.count, 3)
    XCTAssertEqual(выделенные.сыройХвост, Data())
    XCTAssertEqual(выделенные.префикс.байты, поток.count)
    let ожидаемые = [
      Data((#"[{"роль":"assistant","части":["Ё🙂e"# + "\u{0301}" + #"\n",null,""]}]"#).utf8),
      Data("[]".utf8), Data(#"[{"роль":"user","части":["повтор\nЁ"]}]"#.utf8),
    ]
    for (номер, рамка) in выделенные.рамки.enumerated() {
      XCTAssertEqual(рамка.данные, Data((строки[номер] + "\n").utf8))
      XCTAssertEqual(рамка.позиция.номер, номер + 1)
      XCTAssertEqual(рамка.позиция.sha256, хэшБайтовСреза(рамка.данные))
      let а = try AutomationExecutor.выполнить(
        ОпределениеОператора.разобрать(текстовая),
        вход: .текст(try XCTUnwrap(String(data: рамка.данные, encoding: .utf8))))
      let б = try AutomationExecutor.выполнить(
        ОпределениеОператора.разобрать(байтовая), вход: .байты(Array(рамка.данные)))
      guard case .текст(let текстА) = а.результат,
        case .текст(let текстБ) = б.результат
      else {
        return XCTFail("Обе проекции должны вернуть текст")
      }
      XCTAssertEqual(Data(текстА.utf8), ожидаемые[номер])
      XCTAssertEqual(Data(текстБ.utf8), ожидаемые[номер])
    }
  }

  func testБайтоваяПроекцияСовпадаетСТекстовойИПовторяетсяБезФайлов() throws {
    let (текстоваяПрограмма, байтовоеОпределение) = try программыБайтовойПроверки()
    let байтоваяПрограмма = try объект(байтовоеОпределение)
    let входныеБайты = Data(
      #"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Ё🙂e\u0301\n"},{"type":"output_image"},{"type":"input_text","text":""}]}}"#
        .utf8)
    let ожидание = #"[{"роль":"assistant","части":["Ё🙂e"# + "\u{0301}" + #"\n",null,""]}]"#

    try сКаталогом { каталог, _ in
      let вход = каталог.appendingPathComponent("вход.txt")
      let текстовыйФайл = каталог.appendingPathComponent("определение.json")
      let определения = каталог.appendingPathComponent("определения")
      try FileManager.default.createDirectory(
        at: определения, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
      let байтовыйФайл = определения.appendingPathComponent("байтовая-программа.json")
      try текстоваяПрограмма.write(to: текстовыйФайл)
      try байтовоеОпределение.write(to: байтовыйФайл)
      try входныеБайты.write(to: вход)
      let дочерние = try XCTUnwrap(байтоваяПрограмма["определения"] as? [[String: Any]])
      for (номер, дочернее) in дочерние.enumerated() {
        try JSONSerialization.data(withJSONObject: дочернее, options: [.sortedKeys])
          .write(to: определения.appendingPathComponent("дочернее-\(номер).json"))
      }
      func исполнить(_ тип: String, определение: URL) throws -> ОтветБайтовойПроверки {
        let данные = try КомандноеИсполнениеОператора.выполнить(аргументы: [
          "--выполнить-оператор", "--определение", определение.path,
          "--вход", вход.path, "--тип-входа", тип, "--журнал", каталог.path,
        ])
        return try JSONDecoder().decode(ОтветБайтовойПроверки.self, from: данные)
      }
      let текстовый = try исполнить("текст", определение: текстовыйФайл)
      XCTAssertEqual(текстовый.наблюдение.типВхода, "текст")
      XCTAssertEqual(текстовый.наблюдение.результат.тип, "текст")
      XCTAssertEqual(Data(текстовый.наблюдение.результат.значение.utf8), Data(ожидание.utf8))
      let байтовый = try исполнить("байты", определение: байтовыйФайл)
      XCTAssertEqual(байтовый.наблюдение.типВхода, "байты")
      XCTAssertEqual(байтовый.наблюдение.результат.тип, "текст")
      XCTAssertEqual(Data(байтовый.наблюдение.результат.значение.utf8), Data(ожидание.utf8))
      try FileManager.default.removeItem(at: вход)
      try FileManager.default.removeItem(at: текстовыйФайл)
      try FileManager.default.removeItem(at: определения)
      XCTAssertFalse(FileManager.default.fileExists(atPath: вход.path))
      XCTAssertFalse(FileManager.default.fileExists(atPath: текстовыйФайл.path))
      XCTAssertFalse(FileManager.default.fileExists(atPath: определения.path))
      var пары: [(ОтветБайтовойПроверки, ОтветБайтовойПроверки)] = []
      for первый in [текстовый, байтовый] {
        let данные = try КомандноеИсполнениеОператора.выполнить(аргументы: [
          "--повторить-оператор", первый.квитанция.описание.идентификатор, "--журнал", каталог.path,
        ])
        let повтор = try JSONDecoder().decode(ОтветБайтовойПроверки.self, from: данные)
        XCTAssertEqual(первый.схема, "fuma.результат-исполнения.1")
        XCTAssertEqual(повтор.схема, первый.схема)
        XCTAssertEqual(повтор.наблюдение.типВхода, первый.наблюдение.типВхода)
        XCTAssertEqual(повтор.наблюдение.результат.тип, "текст")
        XCTAssertEqual(повтор.наблюдение.хэшНаблюдения, первый.наблюдение.хэшНаблюдения)
        XCTAssertEqual(Data(повтор.наблюдение.результат.значение.utf8), Data(ожидание.utf8))
        XCTAssertNotEqual(
          повтор.квитанция.описание.идентификатор, первый.квитанция.описание.идентификатор)
        XCTAssertEqual(повтор.квитанция.хэш, первый.квитанция.хэш)
        пары.append((первый, повтор))
      }
      let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
      defer { сегмент.закрыть() }
      XCTAssertEqual(сегмент.записи.filter { $0.описание.тип == "исполнение-оператора" }.count, 4)
      for (номер, пара) in пары.enumerated() {
        let (первый, повтор) = пара
        let пакет = try объект(сегмент.извлечь(первый.квитанция.описание.идентификатор))
        let поля = try XCTUnwrap(пакет["принятыеДанные"] as? [String: Any])
        XCTAssertEqual(
          Set(поля.keys),
          Set(["исходноеОпределение", "определение", "вход", "типВхода", "профиль"]))
        let данные = try JSONSerialization.data(withJSONObject: поля, options: [.sortedKeys])
        let принятые = try JSONDecoder().decode(ПроводПринятыхБайтов.self, from: данные)
        let повторПровода = try JSONDecoder().decode(
          ПроводПринятыхБайтов.self, from: JSONEncoder().encode(принятые))
        XCTAssertEqual(повторПровода, принятые)
        let оригинал = номер == 0 ? текстоваяПрограмма : байтовоеОпределение
        XCTAssertEqual(принятые.исходноеОпределение, оригинал)
        let восстановленнаяМодель = try ОпределениеОператора.разобрать(
          повторПровода.исходноеОпределение)
        XCTAssertEqual(try восстановленнаяМодель.данные(), повторПровода.определение)
        XCTAssertEqual(
          try ОпределениеОператора.разобрать(повторПровода.определение).данные(),
          повторПровода.определение)
        XCTAssertEqual(принятые.определение, try ОпределениеОператора.разобрать(оригинал).данные())
        XCTAssertEqual(принятые.вход, входныеБайты)
        XCTAssertEqual(принятые.типВхода, номер == 0 ? "текст" : "байты")
        XCTAssertEqual(
          try сегмент.извлечь(первый.квитанция.описание.идентификатор),
          try сегмент.извлечь(повтор.квитанция.описание.идентификатор))
      }
      let сырыеВходы = сегмент.записи.filter { $0.описание.тип == "сырые-байты/вход-оператора" }
      XCTAssertEqual(сырыеВходы.count, 4)
      for запись in сырыеВходы {
        XCTAssertEqual(try сегмент.извлечь(запись.описание.идентификатор), входныеБайты)
      }
    }
  }
}
