import Foundation
import XCTest
@testable import СтатистикаВызовов

@MainActor
final class ТестыПрофиля: XCTestCase {
    func testРабочаяБольшаяСтрокаПринимаетсяБезСохраненияСодержимого() throws {
        let размер = 3_326_896
        let пустая = try строка("event_msg", ["public_fixture": ""])
        let большая = try строка("event_msg", ["public_fixture": String(repeating: "x", count: размер - пустая.count)])
        XCTAssertEqual(большая.count, размер)
        let отчёт = try сводка(метаданные() + большая + вызов())
        XCTAssertEqual(отчёт.прямыхВызовов, 1)
        XCTAssertLessThan(try кодироватьСтатистику(отчёт).count, 10_000)
    }
    func testНебезопасныйПрофильНеСоздаётФикстуру() async throws {
        let (база, корень, _) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let ссылка = база.appendingPathComponent("ссылка")
        try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: корень)
        do { _ = try await профильСтатистики(корень: ссылка, большой: false); XCTFail("символическая ссылка") } catch {}
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: корень.path).isEmpty)
    }
    func testМалыйПрофильФиксируетРеальныйПолныйПовтор() async throws {
        let (база, корень, _) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let п = try await профильСтатистики(корень: корень, большой: false)
        XCTAssertEqual(п.вызовов, 32)
        XCTAssertEqual(п.инструментов, 32)
        XCTAssertEqual(п.событий, 64)
        XCTAssertEqual(п.повторПрочиталБайт, п.входБайт)
        XCTAssertGreaterThan(п.пакетБайт, 0)
        XCTAssertGreaterThan(п.пикРезидентнойПамятиПослеБайт, 0)
        XCTAssertEqual(п.замеры.map(\.этап), ["импорт", "повтор-префикса", "отчёт-в-памяти", "кодирование-JSON", "replay-контейнера"])
        XCTAssertTrue(п.замеры.allSatisfy { $0.наносекунды > 0 })
        let до = try FileManager.default.contentsOfDirectory(atPath: корень.path).sorted()
        do { _ = try await профильСтатистики(корень: корень, большой: false); XCTFail("не перезаписывать") } catch {}
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: корень.path).sorted(), до)
    }
}
