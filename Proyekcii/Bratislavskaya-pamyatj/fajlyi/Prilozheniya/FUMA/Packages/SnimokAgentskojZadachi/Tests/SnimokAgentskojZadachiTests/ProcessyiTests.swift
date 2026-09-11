import Foundation
import XCTest
@testable import СнимокАгентскойЗадачи

func командаCLI(_ аргументы: [String]) throws -> (Int32, Data) {
    let тестовыйПакет = Bundle(for: ПроцессыTests.self).bundleURL
    let исполняемый = тестовыйПакет.deletingLastPathComponent().appendingPathComponent("снимок-задачи")
    let процесс = Process()
    процесс.executableURL = исполняемый
    процесс.arguments = аргументы
    let вывод = Pipe()
    процесс.standardOutput = вывод
    процесс.standardError = FileHandle.standardError
    try процесс.run()
    let данные = вывод.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    return (процесс.terminationStatus, данные)
}

final class ПроцессыTests: XCTestCase {
    func testCLIПримерВерсионированИВоспроизводим() throws {
        let (код, данные) = try командаCLI(["пример"])
        XCTAssertEqual(код, 0)
        XCTAssertEqual(данные, try каноническийJSON(примерСценария()) + Data([10]))
        let кореньПакета = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(данные, try Data(contentsOf: кореньПакета.appendingPathComponent("Примеры/пять-сценариев.json")))
    }
    func testНовыйПроцессЧитаетКонтейнерБезИсходногоВвода() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let пример = примерСценария()
        let сценарий = Сценарий(задача: пример.задача, наблюдения: пример.наблюдения.map {
            изменить($0, исходныйФакт: $0.исходныйФакт.decomposedStringWithCanonicalMapping)
        })
        let вход = корень.appendingPathComponent("вход.json")
        try каноническийJSON(сценарий).write(to: вход)
        let (код, первый) = try командаCLI(["собрать", вход.path, корень.path, "json"])
        XCTAssertEqual(код, 0)
        try FileManager.default.removeItem(at: вход)
        let (кодВосстановления, второй) = try командаCLI(["восстановить", корень.path,
            сценарий.задача.поставщик, сценарий.задача.хост, сценарий.задача.идентификатор, "json"])
        XCTAssertEqual(кодВосстановления, 0)
        XCTAssertEqual(первый, второй)
        let снимок = try JSONDecoder().decode(Снимок.self, from: второй)
        XCTAssertEqual(снимок.наблюдения, сценарий.наблюдения)
        XCTAssertEqual(try каноническийJSON(снимок.наблюдения), try каноническийJSON(сценарий.наблюдения))
        XCTAssertEqual(снимок.последняяПодтверждённаяКорректировка, "исправление-1")
        XCTAssertNil(снимок.операции.last?.подтверждение)
        XCTAssertEqual(снимок.значение(.текущаяРабота).знание, .противоречие)
        XCTAssertTrue(снимок.значение(.текущаяРабота).кандидаты.allSatisfy(\.устарело))
        XCTAssertEqual(снимок.проигнорированы, ["пример-17"])
        let (кодMarkdown, markdown) = try командаCLI(["восстановить", корень.path,
            сценарий.задача.поставщик, сценарий.задача.хост, сценарий.задача.идентификатор, "markdown"])
        XCTAssertEqual(кодMarkdown, 0)
        XCTAssertEqual(markdown, Data(try читаемыйMarkdown(снимок).utf8))
        XCTAssertTrue(String(decoding: markdown, as: UTF8.self).contains("НЕ ПОДТВЕРЖДЁН"))
    }
    func testНеполныйВводНеСоздаётСегмент() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let вход = корень.appendingPathComponent("неполный.json")
        try каноническийJSON(примерСценария()).dropLast().write(to: вход)
        let (код, вывод) = try командаCLI(["собрать", вход.path, корень.path, "json"])
        XCTAssertNotEqual(код, 0)
        XCTAssertTrue(вывод.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: корень.appendingPathComponent("сегмент.fumobs").path))
    }
}
