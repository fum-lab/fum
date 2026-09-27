import Foundation
import XCTest

@testable import FUMStructuringOperatorMemory

final class ПроверкиРасчётовFUMA: XCTestCase {
  private var каталог: URL {
    var корень = URL(fileURLWithPath: #filePath)
    for _ in 0..<5 { корень.deleteLastPathComponent() }
    return корень.appendingPathComponent("Описания/пакет-FUMA")
  }

  private func рассчитать(_ имя: String, вход: Data? = nil) throws -> [String: Any] {
    let определение = try ОпределениеОператора.разобрать(Data(contentsOf: каталог.appendingPathComponent("оператор-" + имя + ".json")))
    let данные = try вход ?? Data(contentsOf: каталог.appendingPathComponent("вход-" + имя + ".json"))
    let результат = try AutomationExecutor.выполнить(определение,
      вход: .текст(String(decoding: данные, as: UTF8.self)),
      пределы: .init(байтовВхода: 262144, байтовРезультата: 1048576, операций: 16777216))
    guard case .текст(let текст) = результат.результат else { throw NSError(domain: "расчёт", code: 1) }
    return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
  }

  func test_АвтономностьИМассаВЦелыхЕдиницах() throws {
    let результат = try рассчитать("рюкзака")
    let строки = try XCTUnwrap(результат["варианты"] as? [[String: Any]])
    XCTAssertEqual(строки.count, 3)
    XCTAssertEqual(строки.compactMap { $0["масса_г"] as? Int }, [8100, 10600, 15600])
    let времена = try строки.map { строка in
      try XCTUnwrap(строка["нагрузки"] as? [[String: Any]]).compactMap { $0["секунд"] as? Int }
    }
    XCTAssertEqual(времена, [[6000, 3272, 1777], [12000, 6545, 3555], [24000, 13090, 7111]])
  }

  func test_НевозможнаяЭффективностьНеСтановитсяАвтономностью() throws {
    let исходник = try Data(contentsOf: каталог.appendingPathComponent("вход-рюкзака.json"))
    var вход = try XCTUnwrap(JSONSerialization.jsonObject(with: исходник) as? [String: Any])
    var допущения = try XCTUnwrap(вход["допущения"] as? [String: Any])
    допущения["доступно_процентов"] = 101
    вход["допущения"] = допущения
    XCTAssertThrowsError(try рассчитать("рюкзака", вход: JSONSerialization.data(withJSONObject: вход)))
  }
}
