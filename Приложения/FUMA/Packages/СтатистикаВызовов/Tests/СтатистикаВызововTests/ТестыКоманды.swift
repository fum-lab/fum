import Foundation
import XCTest
@testable import СтатистикаВызовов

final class ТестыКоманды: XCTestCase {
    func выполнить(_ аргументы: [String]) throws -> (Int32, Data, Data) {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/debug/статистика-вызовов")
        процесс.arguments = аргументы
        let вывод = Pipe(); let ошибки = Pipe()
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        try процесс.run()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        return (процесс.terminationStatus, данные, диагностика)
    }
    func test_ТриПроцессаИРазметкаИзТогоЖеОтчёта() throws {
        let временный = try временныйКаталог()
        defer { try? FileManager.default.removeItem(at: временный) }
        guard let физический = realpath(временный.path, nil) else { throw ОшибкаСтатистики.формат }
        defer { free(физический) }
        let база = URL(fileURLWithPath: String(cString: физический))
        let вход = база.appendingPathComponent("публичный.jsonl")
        let корень = база.appendingPathComponent("данные")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
        try (метаданные() + вызов() + результат() + результат(NSNull())).write(to: вход)
        let общие = ["--выход", корень.path, "--задача", задачаФикстуры]
        let первый = try выполнить(["импорт", "--вход", вход.path] + общие)
        XCTAssertEqual(первый.0, 0)
        let отчёт = try JSONDecoder().decode(ОтчётСтатистики.self, from: первый.1)
        XCTAssertEqual(отчёт.прямыхВызовов, 1)
        XCTAssertEqual(отчёт.несопряжённыхРезультатов, 1)
        let повтор = try выполнить(["импорт", "--вход", вход.path] + общие)
        XCTAssertEqual(повтор.1, первый.1)
        try FileManager.default.removeItem(at: вход)
        let восстановленный = try выполнить(["отчёт"] + общие)
        XCTAssertEqual(восстановленный.1, первый.1)
        let разметка = try выполнить(["отчёт", "--формат", "markdown"] + общие)
        XCTAssertEqual(разметка.0, 0)
        let текст = String(decoding: разметка.1, as: UTF8.self)
        XCTAssertTrue(текст.contains("functions.exec"))
        XCTAssertTrue(текст.contains("не доказывает"))
        XCTAssertFalse(текст.contains("ПРИВАТНЫЙ_ВЫВОД"))
    }
    func test_КомандаБезЯвногоВходаИОшибкиНеВыдаютАргументы() throws {
        for аргументы in [[], ["импорт"], ["неизвестно", "НЕ_ПЕЧАТАТЬ_АРГУМЕНТ"], ["отчёт", "--выход", "/НЕ_ПЕЧАТАТЬ_АРГУМЕНТ"]] {
            let ответ = try выполнить(аргументы)
            XCTAssertEqual(ответ.0, 2)
            XCTAssertTrue(ответ.1.isEmpty)
            XCTAssertFalse(String(decoding: ответ.2, as: UTF8.self).contains("НЕ_ПЕЧАТАТЬ_АРГУМЕНТ"))
        }
    }
}
