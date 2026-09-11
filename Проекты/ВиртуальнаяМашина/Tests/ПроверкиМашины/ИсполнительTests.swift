import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиИсполнителя: XCTestCase {
    func test_АргументыНеИнтерпретируютсяОболочкой() throws {
        let текст = "путь с ё $(не-команда); `не-команда`"
        let результат = try Исполнитель.выполнить("/usr/bin/printf", ["%s", текст])
        XCTAssertEqual(результат.вывод, текст)
        XCTAssertEqual(результат.код, 0)
    }
    func test_НеуспехНеСкрывается() throws {
        XCTAssertEqual(try Исполнитель.выполнить("/usr/bin/false", []).код, 1)
        XCTAssertThrowsError(try Исполнитель.выполнить("/несуществующая-команда", []))
    }
    func test_ОжиданиеОграничено() {
        XCTAssertThrowsError(try Исполнитель.выполнить("/bin/sleep", ["5"], предел: 0.1))
    }
    func test_ВходПередаётсяБуквально() throws {
        let вход = Data("данные с ё\nвторая строка".utf8)
        XCTAssertEqual(try Исполнитель.выполнить("/bin/cat", [], вход: вход).вывод, String(decoding: вход, as: UTF8.self))
    }
    func test_ТаймАутОстанавливаетПотомка() throws {
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: каталог) }
        let файл = каталог.appendingPathComponent("результат")
        // Путь передан позиционным argv; оболочка нужна только для контролируемой фикстуры потомка.
        XCTAssertThrowsError(try Исполнитель.выполнить("/bin/sh", ["-c", "(trap '' TERM; sleep 0.5; printf late > \"$1\") & wait", "sh", файл.path], предел: 0.1))
        usleep(700_000)
        XCTAssertFalse(FileManager.default.fileExists(atPath: файл.path))
    }
    func test_ПовторныйИмпортНеУдваиваетСчётчики() throws {
        let корень = СобытиеМашины(идентификатор: UUID().uuidString, родитель: nil, операция: "подготовка", длительностьНс: 100, исход: "успех")
        let ребёнок = СобытиеМашины(идентификатор: UUID().uuidString, родитель: корень.идентификатор, операция: "процесс", длительностьНс: 80, исход: "успех")
        let события = try объединитьСобытия([корень, ребёнок, корень, ребёнок])
        XCTAssertEqual(события.count, 2)
        XCTAssertEqual(события.filter { $0.родитель == nil }.compactMap(\.длительностьНс).reduce(0,+), 100)
        var подмена = корень; подмена.исход = "ошибка"
        XCTAssertThrowsError(try объединитьСобытия([корень, подмена]))
    }
}
