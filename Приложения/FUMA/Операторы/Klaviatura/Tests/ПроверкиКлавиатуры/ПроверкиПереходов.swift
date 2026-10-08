import Foundation
import XCTest
import FUMStructuringOperatorMemory
import ЭталонКлавиатуры

final class ПроверкиПереходов: XCTestCase {
  private var корень: URL!

  override func setUpWithError() throws {
    guard let значение = ProcessInfo.processInfo.environment["КЛАВИАТУРА_КОРЕНЬ_ПАКЕТА"],
          !значение.isEmpty else {
      throw NSError(domain: "Klaviatura.корень", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "КЛАВИАТУРА: отсутствует корень пакета"])
    }
    do {
      guard значение.hasPrefix("/") else { throw CocoaError(.fileReadInvalidFileName) }
      var текущий = URL(fileURLWithPath: "/", isDirectory: true)
      for часть in значение.split(separator: "/", omittingEmptySubsequences: false).dropFirst() {
        guard !часть.isEmpty, часть != ".", часть != ".." else { throw CocoaError(.fileReadInvalidFileName) }
        текущий.appendPathComponent(String(часть), isDirectory: true)
        guard try FileManager.default.attributesOfItem(atPath: текущий.path)[.type] as? FileAttributeType == .typeDirectory
        else { throw CocoaError(.fileReadInvalidFileName) }
      }
      var файлы = ["Package.swift", "определение.json", "Фикстуры/переходы.json"]
      if ProcessInfo.processInfo.environment["KLAVIATURA_RED"] == "1" {
        файлы.append("Фикстуры/определение-RED.json")
      }
      for имя in файлы {
        let части = имя.split(separator: "/")
        var файл = текущий
        for (номер, часть) in части.enumerated() {
          файл.appendPathComponent(String(часть))
          let тип = try FileManager.default.attributesOfItem(atPath: файл.path)[.type] as? FileAttributeType
          guard тип == (номер == части.count - 1 ? .typeRegular : .typeDirectory)
          else { throw CocoaError(.fileReadInvalidFileName) }
        }
      }
      корень = текущий
    } catch {
      throw NSError(domain: "Klaviatura.корень", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "КЛАВИАТУРА: неверный корень пакета"])
    }
  }
  func testПервыйТекстНастоящимИнтерпретатором() throws {
    let путь = ProcessInfo.processInfo.environment["KLAVIATURA_RED"] == "1" ? "Фикстуры/определение-RED.json" : "определение.json"
    let определение = try ОпределениеОператора.разобрать(Data(contentsOf: корень.appendingPathComponent(путь)))
    let фикстуры = try JSONSerialization.jsonObject(with: Data(contentsOf: корень.appendingPathComponent("Фикстуры/переходы.json"))) as! [String: Any]
    let случай = (фикстуры["случаи"] as! [[String: Any]])[0]
    let наблюдение = try выполнитьПереход(определение, JSONSerialization.data(withJSONObject: случай["вход"]!))
    XCTAssertEqual(try разобратьРезультат(наблюдение), случай["ожидание"] as! NSDictionary)
  }

  func testВсеФикстурыИНезависимыйЭталон() throws {
    let определение = try ОпределениеОператора.разобрать(Data(contentsOf: корень.appendingPathComponent("определение.json")))
    let фикстуры = try JSONSerialization.jsonObject(with: Data(contentsOf: корень.appendingPathComponent("Фикстуры/переходы.json"))) as! [String: Any]
    var случаи = фикстуры["случаи"] as! [[String: Any]]
    for последовательность in фикстуры["последовательности"] as! [[String: Any]] {
      let шаги = последовательность["шаги"] as! [[String: Any]]
      var прежнее: NSDictionary?
      for шаг in шаги {
        let вход = шаг["вход"] as! [String: Any]
        if let прежнее { XCTAssertEqual(вход["модификаторы"] as! NSDictionary, прежнее) }
        прежнее = (шаг["ожидание"] as! [String: Any])["модификаторы"] as? NSDictionary
      }
      случаи += шаги
    }
    XCTAssertEqual(случаи.count, 274)
    for случай in случаи {
      let данные = try JSONSerialization.data(withJSONObject: случай["вход"]!, options: [.sortedKeys])
      let событие = try JSONDecoder().decode(СобытиеКлавиатуры.self, from: данные)
      let ожидание = случай["ожидание"] as! NSDictionary
      XCTAssertEqual(try эталонныйПереход(событие), ожидание, String(describing: случай["имя"]))
      let первое = try выполнитьПереход(определение, данные)
      XCTAssertEqual(try разобратьРезультат(первое), ожидание, String(describing: случай["имя"]))
      XCTAssertEqual(первое, try выполнитьПереход(определение, данные))
      XCTAssertEqual(первое.шаги.map(\.идентификатор), ["переход-раскладки"])
      XCTAssertTrue(первое.трасса.isEmpty)
      XCTAssertNotNil(первое.шаги.first?.хэшВхода.range(of: "^sha256:[0-9a-f]{64}$", options: .regularExpression))
      XCTAssertNotNil(первое.шаги.first?.хэшВыхода.range(of: "^sha256:[0-9a-f]{64}$", options: .regularExpression))
    }
  }

  func testНеверныеТипыВхода() throws {
    XCTAssertThrowsError(try JSONDecoder().decode(СобытиеКлавиатуры.self, from: Data("{\"клавиша\":\"12\"}".utf8)))
    XCTAssertThrowsError(try JSONDecoder().decode(СобытиеКлавиатуры.self, from: Data("{\"клавиша\":12,\"фаза\":\"нажатие\",\"повтор\":0,\"модификаторы\":{}}".utf8)))
    let определение = try ОпределениеОператора.разобрать(Data(contentsOf: корень.appendingPathComponent("определение.json")))
    let фикстуры = try JSONSerialization.jsonObject(with: Data(contentsOf: корень.appendingPathComponent("Фикстуры/переходы.json"))) as! [String: Any]
    let первый = (фикстуры["случаи"] as! [[String: Any]])[0]["вход"] as! [String: Any]
    for поле in поляСостояния {
      var испорченный = первый
      var состояние = испорченный["модификаторы"] as! [String: Any]
      состояние["сдвиг_слева"] = true
      состояние[поле] = "не логическое"
      испорченный["модификаторы"] = состояние
      XCTAssertThrowsError(try выполнитьПереход(определение, JSONSerialization.data(withJSONObject: испорченный)))
    }
    var лишнее = первый
    var состояние = лишнее["модификаторы"] as! [String: Any]
    состояние["лишний"] = false
    лишнее["модификаторы"] = состояние
    XCTAssertThrowsError(try выполнитьПереход(определение, JSONSerialization.data(withJSONObject: лишнее)))
    let событие = try JSONDecoder().decode(СобытиеКлавиатуры.self, from: JSONSerialization.data(withJSONObject: лишнее))
    XCTAssertThrowsError(try эталонныйПереход(событие))
    for (поле, значение) in [("клавиша", "12"), ("фаза", 12), ("повтор", "false")] as [(String, Any)] {
      var неверный = первый
      неверный[поле] = значение
      XCTAssertThrowsError(try выполнитьПереход(определение, JSONSerialization.data(withJSONObject: неверный)))
    }
    var верхнееЛишнее = первый
    верхнееЛишнее["лишний"] = false
    XCTAssertThrowsError(try выполнитьПереход(определение, JSONSerialization.data(withJSONObject: верхнееЛишнее)))
  }
}
