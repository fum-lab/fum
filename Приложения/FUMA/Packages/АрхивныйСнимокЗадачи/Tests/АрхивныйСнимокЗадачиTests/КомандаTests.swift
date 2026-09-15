import XCTest
import Foundation
import АрхивныйСнимокЗадачи

final class КомандаTests: XCTestCase {
    func запустить(_ имя: String, _ аргументы: [String]) throws -> (Int32, Data, Data) {
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let процесс = Process(); let выход = Pipe(); let ошибки = Pipe()
        процесс.executableURL = пакет.appendingPathComponent(".build/debug/" + имя)
        процесс.arguments = аргументы; процесс.standardOutput = выход; процесс.standardError = ошибки
        try процесс.run()
        let данные = выход.fileHandleForReading.readDataToEndOfFile()
        let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        return (процесс.terminationStatus, данные, диагностика)
    }
    func testКомандаJSONMarkdownИReplayБезИсходника() throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст()])
        let (код, json, _) = try запустить("архивный-снимок", ["импорт", пример.источник.path, пример.архив.path, uuidФикстуры])
        XCTAssertEqual(код, 0)
        let результат = try JSONDecoder().decode(РезультатАрхива.self, from: json)
        XCTAssertEqual(результат.архив.граница.строки, 2)
        try FileManager.default.removeItem(at: пример.источник)
        let (replayКод, replay, _) = try запустить("архивный-снимок", ["replay", пример.архив.path, uuidФикстуры])
        XCTAssertEqual(replayКод, 0); XCTAssertEqual(replay, json)
        let (markdownКод, markdown, _) = try запустить("архивный-снимок", ["replay", пример.архив.path, uuidФикстуры, "--markdown"])
        XCTAssertEqual(markdownКод, 0)
        XCTAssertTrue(String(decoding: markdown, as: UTF8.self).contains("по состоянию прочитанного префикса"))
        XCTAssertTrue(String(decoding: markdown, as: UTF8.self).contains("неизвестны"))
        let (отказ, пусто, диагностика) = try запустить("архивный-снимок", ["импорт", пример.источник.path + "SECRET_PATH", пример.архив.path, uuidФикстуры])
        XCTAssertEqual(отказ, 2); XCTAssertTrue(пусто.isEmpty)
        XCTAssertFalse(String(decoding: диагностика, as: UTF8.self).contains("SECRET_PATH"))
    }
    func testПрофильПроверяетРавенствоНаМалойСинтетике() throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let (код, данные, _) = try запустить("профиль-архивного-снимка", [пример.корень.appendingPathComponent("профиль").path, "1000000"])
        XCTAssertEqual(код, 0)
        let отчёт = try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        XCTAssertEqual(отчёт["одинаковыйРезультат"] as? Bool, true)
        XCTAssertEqual(отчёт["байты"] as? Int, 1_000_000)
        XCTAssertEqual((отчёт["измерения"] as? [Any])?.count, 4)
    }
    func testПрофильСлужебныхОболочекПроходитНовыеТипы() throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let (код, данные, _) = try запустить("профиль-архивного-снимка", [пример.корень.appendingPathComponent("служебный-профиль").path, "1000000", "--служебные-оболочки"])
        XCTAssertEqual(код, 0)
        guard код == 0 else { return }
        let отчёт = try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        XCTAssertEqual(отчёт["одинаковыйРезультат"] as? Bool, true)
        XCTAssertTrue((отчёт["источник"] as? String)?.contains("служебные оболочки") == true)
        XCTAssertEqual(отчёт["максимальнаяСтрока"] as? Int, 262_144)
        let измерения = try XCTUnwrap(отчёт["измерения"] as? [[String: Any]])
        let стадии = try XCTUnwrap(измерения.first?["стадии"] as? [String: Any])
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(стадии["разобраноСтрок"] as? Int), 5)
    }

}
