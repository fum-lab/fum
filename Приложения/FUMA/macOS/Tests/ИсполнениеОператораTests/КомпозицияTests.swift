import Darwin
import Foundation
import XCTest
import КонтейнерНаблюдений

@testable import ИсполнениеОператора

final class ПроверкиКомпозицииАдаптера: XCTestCase {
  let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()

  func сКаталогом(_ действие: (URL) throws -> Void) throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: временный, withIntermediateDirectories: false,
      attributes: [.posixPermissions: 0o700])
    let путь = try XCTUnwrap(realpath(временный.path, nil))
    defer {
      free(путь)
      try? FileManager.default.removeItem(at: временный)
    }
    try действие(URL(fileURLWithPath: String(cString: путь)))
  }

  func объект(_ данные: Data) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
  }

  func идентификатор(_ ответ: [String: Any]) throws -> String {
    let квитанция = try XCTUnwrap(ответ["квитанция"] as? [String: Any])
    let описание = try XCTUnwrap(квитанция["описание"] as? [String: Any])
    return try XCTUnwrap(описание["идентификатор"] as? String)
  }

  func test_ПрежняяЗаписьV1ПовторяетсяНовымАдаптером() throws {
    let данные = try Data(
      contentsOf: корень.appendingPathComponent(
        "Прототипы/память-структурирующих-операторов/Проверки/композиция/запись-v1.json"))
    let эталон = try XCTUnwrap(объект(данные)["наблюдение"] as? NSDictionary)
    try сКаталогом { каталог in
      let сегмент = try Сегмент(кореньДанных: каталог, запись: true)
      let описание = ОписаниеНаблюдения(
        идентификатор: UUID().uuidString.lowercased(),
        тип: "исполнение-оператора", источник: "FUMA", время: "2026-09-30T20:47:32Z")
      let квитанция = try сегмент.добавить(описание, данные: данные)
      сегмент.закрыть()
      let повтор = try объект(
        КомандноеИсполнениеОператора.выполнить(аргументы: [
          "--повторить-оператор", квитанция.описание.идентификатор, "--журнал", каталог.path,
        ]))
      XCTAssertEqual(повтор["наблюдение"] as? NSDictionary, эталон)
      XCTAssertEqual(
        эталон["хэшНаблюдения"] as? String,
        "sha256:b220e79abaa1ff5d92452b2dc71fa08b0ce3756edca373214911ed9fb04a0e81")
    }
  }

  func test_КомпозицияПовторяетсяПослеУдаленияВсехИсходныхОпределений() throws {
    try сКаталогом { каталог in
      let источник = корень.appendingPathComponent(
        "Прототипы/память-структурирующих-операторов/Проверки/композиция/определение.json")
      let полное = try Data(contentsOf: источник)
      let разобранное = try объект(полное)
      let исходники = каталог.appendingPathComponent("определения")
      try FileManager.default.createDirectory(at: исходники, withIntermediateDirectories: false)
      for (номер, определение) in (разобранное["определения"] as! [[String: Any]]).enumerated() {
        try JSONSerialization.data(withJSONObject: определение).write(
          to:
            исходники.appendingPathComponent("чистое-\(номер).json"))
      }
      let определение = исходники.appendingPathComponent("композиция.json")
      try полное.write(to: определение)
      let вход = каталог.appendingPathComponent("вход.json")
      try Data("{}".utf8).write(to: вход)
      let первый = try объект(
        КомандноеИсполнениеОператора.выполнить(аргументы: [
          "--выполнить-оператор", "--определение", определение.path, "--вход", вход.path,
          "--тип-входа", "текст", "--журнал", каталог.path,
        ]))
      try FileManager.default.removeItem(at: исходники)
      try FileManager.default.removeItem(at: вход)
      // Первый синхронный исполнитель уже закрыл сегмент. Повтор открывает память заново.
      let второй = try объект(
        КомандноеИсполнениеОператора.выполнить(аргументы: [
          "--повторить-оператор", try идентификатор(первый), "--журнал", каталог.path,
        ]))
      XCTAssertEqual(первый["наблюдение"] as? NSDictionary, второй["наблюдение"] as? NSDictionary)
      let наблюдение = первый["наблюдение"] as! [String: Any]
      XCTAssertEqual(
        (наблюдение["результат"] as! [String: Any])["значение"] as? String,
        "{\"пара\":[6,8],\"три\":[2,4,6]}")
    }
  }
}
