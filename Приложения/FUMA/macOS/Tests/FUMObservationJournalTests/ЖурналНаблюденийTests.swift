import Foundation
import XCTest
@testable import FUMObservationJournal

final class ЖурналНаблюденийTests: XCTestCase {
    func testДобавляетПолныеJSONLСтрокиИПовторяетИхПослеЧтения() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-observation-journal-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let путь = root.appendingPathComponent("nested/events.jsonl")
        let журнал = ЖурналНаблюдений()
        try журнал.добавитьJSONСтроку(["type": "status", "value": 1], в: путь)
        try журнал.добавитьJSONСтроку(Data("{\"type\":\"focus\"}".utf8), в: путь)

        let строки = try String(contentsOf: путь, encoding: .utf8).split(separator: "\n")
        XCTAssertEqual(строки.count, 2)
        XCTAssertEqual(строки[0], "{\"type\":\"status\",\"value\":1}")
        XCTAssertEqual(строки[1], "{\"type\":\"focus\"}")
    }

    func testОтклоняетОтносительныйПутьДоОткрытия() {
        XCTAssertThrowsError(try ЖурналНаблюдений().добавитьJSONСтроку(["type": "status"], в: URL(string: "events.jsonl")!)) { error in
            XCTAssertEqual(error as? ОшибкаЖурналаНаблюдений, .небезопасныйПуть)
        }
    }

    func testСохраняетСхемуИИсточникВОднойПолнойСтроке() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-observation-provenance-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let путь = root.appendingPathComponent("events.jsonl")
        try ЖурналНаблюдений().добавитьJSONСтроку([
            "schema": "fum.observation-event.1",
            "source": "fum-ax-vision-sense",
            "type": "state_initialized"
        ], в: путь)

        let строка = try String(contentsOf: путь, encoding: .utf8)
        XCTAssertEqual(
            строка,
            "{\"schema\":\"fum.observation-event.1\",\"source\":\"fum-ax-vision-sense\",\"type\":\"state_initialized\"}\n"
        )
    }
}
