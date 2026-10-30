import XCTest
@testable import FUMStructuringOperatorMemory

final class ПроверкиSFNT: XCTestCase {
  func test_РазбираетЗаголовокИDirectoryСИсходнымиДиапазонами() throws {
    let данные: [UInt8] = [
      0, 1, 0, 0, 0, 1, 0, 16, 0, 1, 0, 0,
      0x6e, 0x61, 0x6d, 0x65, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 4,
      1, 2, 3, 4,
    ]
    let заголовок = try ОператорРазбораSFNT.выполнить(данные)
    XCTAssertEqual(заголовок.версия.значение, 0x00010000)
    XCTAssertEqual(заголовок.версия.диапазонИсходныхБайтов, 0..<4)
    XCTAssertEqual(заголовок.числоТаблиц.значение, 1)
    XCTAssertEqual(заголовок.таблицы.first?.тег, "name")
    XCTAssertEqual(заголовок.таблицы.first?.смещение.диапазонИсходныхБайтов, 20..<24)
  }

  func test_РазбираетЗакреплённуюSynthaxФикстуру() throws {
    var каталог = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    while каталог.path != "/" && !FileManager.default.fileExists(
      atPath: каталог.appending(path: "Приложения/FUMA/Операторы/Шрифт/Ресурсы/Synthax-Regular.ttf").path
    ) {
      каталог.deleteLastPathComponent()
    }
    let путь = каталог.appending(path: "Приложения/FUMA/Операторы/Шрифт/Ресурсы/Synthax-Regular.ttf")
    XCTAssertTrue(FileManager.default.fileExists(atPath: путь.path))
    let заголовок = try ОператорРазбораSFNT.выполнить(Array(try Data(contentsOf: путь)))
    XCTAssertEqual(заголовок.версия.значение, 0x00010000)
    XCTAssertEqual(заголовок.числоТаблиц.значение, UInt64(заголовок.таблицы.count))
    XCTAssertTrue(заголовок.таблицы.contains { $0.тег == "cmap" })
    XCTAssertTrue(заголовок.таблицы.contains { $0.тег == "glyf" })
  }

  func test_ОтклоняетНекорректнуюПодписьЧислоТаблицИДиапазон() {
    XCTAssertThrowsError(try ОператорРазбораSFNT.выполнить([0, 0, 0, 0])) {
      XCTAssertEqual($0 as? ОшибкаSFNT, .невернаяПодпись)
    }
    XCTAssertThrowsError(try ОператорРазбораSFNT.выполнить([0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])) {
      XCTAssertEqual($0 as? ОшибкаSFNT, .недопустимоеЧислоТаблиц(значение: 0))
    }
    var данные: [UInt8] = [
      0, 1, 0, 0, 0, 1, 0, 16, 0, 1, 0, 0,
      0x6e, 0x61, 0x6d, 0x65, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 8,
    ]
    XCTAssertThrowsError(try ОператорРазбораSFNT.выполнить(данные)) {
      XCTAssertEqual($0 as? ОшибкаSFNT, .переполнениеТаблицы(тег: "name", смещение: 28, длина: 8))
    }
    данные[23] = 12
    XCTAssertThrowsError(try ОператорРазбораSFNT.выполнить(данные)) {
      XCTAssertEqual($0 as? ОшибкаSFNT, .таблицаВЗаголовке(тег: "name"))
    }
  }
}
