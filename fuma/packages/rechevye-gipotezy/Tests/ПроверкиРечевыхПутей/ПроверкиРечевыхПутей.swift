import Foundation
import XCTest
import FUMStructuringOperatorMemory
import РечевыеПути

final class ПроверкиРечевыхПутей: XCTestCase {
  func test_СинтетическиеПутиИОтказы() throws {
    let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let определение = try ОпределениеОператора.разобрать(
      Data(contentsOf: корень.appendingPathComponent("определение.json")))
    let данные = try Data(contentsOf: корень.appendingPathComponent("фикстуры.json"))
    let оболочка = try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
    XCTAssertEqual(оболочка["схема"] as? String, ГраницаРечевыхПутей.схемаФикстуры)
    let случаи = try XCTUnwrap(оболочка["случаи"] as? [[String: Any]])
    XCTAssertEqual(случаи.count, 9)
    for случай in случаи {
      let имя = try XCTUnwrap(случай["имя"] as? String)
      let вход = try XCTUnwrap(случай["вход"] as? [String: Any])
      let входныеДанные = try JSONSerialization.data(withJSONObject: вход, options: [.sortedKeys])
      let входнойТекст = try XCTUnwrap(String(data: входныеДанные, encoding: .utf8))
      if let код = случай["ожидаемаяОшибка"] as? String {
        XCTAssertThrowsError(try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст)), имя) {
          XCTAssertEqual(($0 as? ОшибкаИсполнения)?.код, код, имя)
        }
      } else {
        let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
        guard case .текст(let текст) = наблюдение.результат else {
          XCTFail("Ожидался JSON-текст: \(имя)")
          continue
        }
        let результат = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any])
        let ожидаемый = try XCTUnwrap(случай["ожидаемый"] as? [String: Any])
        XCTAssertEqual(NSDictionary(dictionary: результат), NSDictionary(dictionary: ожидаемый), имя)
        let повтор = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
        XCTAssertEqual(повтор.результат, наблюдение.результат, имя)
      }
    }
  }
}
