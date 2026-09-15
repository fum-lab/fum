import XCTest
import Foundation
import СнимокАгентскойЗадачи
import КонтейнерНаблюдений
@testable import АрхивныйСнимокЗадачи

final class РевьюTests: XCTestCase, @unchecked Sendable {
    func testНулевойБайтПутиНеСокращаетЯвныйИсточник() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета()])
        let архив = try пример.открыть()
        let ложный = URL(fileURLWithPath: пример.источник.path + "\0чужой")
        do { _ = try await архив.импортировать(ложный); XCTFail("прочитан другой путь") } catch {}
        let число = await архив.числоЗаписей(); XCTAssertEqual(число, 0)
        await архив.закрыть()
    }
    func testВосстановлениеНеМеняетЧужойАрхив() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета()])
        let архив = try пример.открыть(); _ = try await архив.импортировать(пример.источник); await архив.закрыть()
        let путь = пример.архив.appendingPathComponent("сегмент.fumobs")
        let файл = try FileHandle(forWritingTo: путь)
        try файл.seekToEnd(); try файл.write(contentsOf: Data("OBS1".utf8)); try файл.close()
        let до = try Data(contentsOf: путь)
        XCTAssertThrowsError(try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidЧужой, запись: true, восстановитьХвост: true))
        XCTAssertEqual(try Data(contentsOf: путь), до)
    }
    func testРазныеБайтыИдентичностиХодаНеПереносятМодель() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст("é"), "{\"type\":\"event_msg\",\"payload\":{\"turn_id\":\"e\\u0301\"}}"])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник)
        XCTAssertNil(результат.архив.модельХода)
        XCTAssertTrue(результат.снимок.неизвестныеПоля.contains(.наблюдённаяМодель))
        await архив.закрыть()
    }
    func testReplayПроверяетХодДажеБезМодели() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст(модель: nil)])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник); await архив.закрыть()
        let отдельный = try Фикстура(); defer { отдельный.убрать() }
        var объект = try XCTUnwrap(JSONSerialization.jsonObject(with: каноническийJSON(результат.архив)) as? [String: Any])
        var ход = try XCTUnwrap(объект["последнийХод"] as? [String: Any]); ход["значение"] = ""
        объект["последнийХод"] = ход
        let данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
        let контейнер = try Сегмент(кореньДанных: отдельный.архив, запись: true)
        _ = try контейнер.добавить(описаниеАрхива(результат.архив), данные: данные); контейнер.закрыть()
        XCTAssertThrowsError(try отдельный.открыть())
    }
}
