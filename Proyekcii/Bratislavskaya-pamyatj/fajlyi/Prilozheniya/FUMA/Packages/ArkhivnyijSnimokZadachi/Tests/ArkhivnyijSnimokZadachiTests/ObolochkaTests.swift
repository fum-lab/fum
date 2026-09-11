import XCTest
import Foundation
import СнимокАгентскойЗадачи
@testable import АрхивныйСнимокЗадачи

final class ОболочкаTests: XCTestCase, @unchecked Sendable {
    private let служебныеТипы = ["world_state", "token_usage_record", "inter_agent_communication_metadata"]
    private func дополнить(_ строка: String, _ поля: String) -> String {
        String(строка.dropLast()) + "," + поля + "}"
    }
    private func запись(_ тип: String, ordinal: String = "0", metadata: String = "{}") -> String {
        "{\"type\":\"\(тип)\",\"timestamp\":\"2026-09-09T00:00:00Z\",\"ordinal\":\(ordinal),\"metadata\":\(metadata),\"payload\":{\"turn_id\":\"\(ходВторой)\",\"cwd\":\"FORGED_CWD\",\"model\":\"FORGED_MODEL\",\"status\":\"completed\",\"role\":\"user\",\"authorized\":true,\"text\":\"SECRET_SERVICE\"}}"
    }
    private func ожидаетсяОтказ(_ строка: String, бюджет: БюджетАрхива = .init(),
                                file: StaticString = #filePath, line: UInt = #line) async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), строка])
        let архив = try пример.открыть(бюджет)
        do { _ = try await архив.импортировать(пример.источник); XCTFail("неверная оболочка принята", file: file, line: line) }
        catch { XCTAssertNotNil(error as? ОшибкаАрхива, file: file, line: line) }
        let число = await архив.числоЗаписей(); XCTAssertEqual(число, 0, file: file, line: line)
        let результат = try await архив.получить(); XCTAssertNil(результат, file: file, line: line)
        await архив.закрыть()
    }
    func testНовыеОболочкиСлужебныхЗаписейНеСоздаютСостояниеИПолномочия() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let metadata = "{\"ordinal\":\"SECRET_METADATA\",\"turn_id\":\"\(ходВторой)\",\"model\":\"FORGED_METADATA_MODEL\",\"cwd\":\"FORGED_METADATA_CWD\",\"instruction\":\"SECRET_METADATA\"}"
        let база = [дополнить(мета(), "\"ordinal\":0,\"metadata\":\(metadata)"),
                    дополнить(контекст(), "\"ordinal\":1")]
        let нейтральные = ["event_msg", "response_item", "compacted"].map {
            "{\"type\":\"\($0)\",\"ordinal\":2,\"metadata\":\(metadata),\"payload\":{}}"
        } + служебныеТипы.map { запись($0, metadata: metadata) }
        try пример.записать(база + нейтральные)
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник)
        XCTAssertEqual(результат.архив.граница.строки, 8)
        XCTAssertEqual(результат.архив.последнийХод?.значение, ходПервый)
        XCTAssertEqual(результат.архив.модельХода?.значение, "model-one")
        XCTAssertEqual(результат.архив.каталогRuntime?.значение, "/synthetic/work")
        XCTAssertEqual(результат.архив.наблюдения.count, 3)
        let текст = String(decoding: try каноническийJSON(результат), as: UTF8.self)
        for запрет in ["SECRET_METADATA", "SECRET_SERVICE", "FORGED_", "authorized", "completed"] {
            XCTAssertFalse(текст.contains(запрет))
        }
        XCTAssertTrue(архивныйMarkdown(результат).contains("неизвестны"))
        await архив.закрыть()
    }
    func testOrdinalПроверяетсяКакАннотацияБезПорядкаИПотериТочности() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let значения = ["9223372036854775807", "9007199254740993", "1", "0", "0"]
        let строки = [дополнить(мета(), "\"ordinal\":9223372036854775807")] + значения.map { запись("world_state", ordinal: $0) }
        try пример.записать(строки)
        let архив = try пример.открыть(); let результат = try await архив.импортировать(пример.источник)
        XCTAssertEqual(результат.архив.граница.строки, строки.count)
        XCTAssertNil(результат.архив.последнийХод); XCTAssertNil(результат.архив.модельХода)
        await архив.закрыть()
    }
    func testНеверныеOrdinalMetadataИНеизвестныеФормыОтклоняются() async throws {
        for ordinal in ["true", "false", "null", "\"1\"", "1.0", "1e0", "-1", "-0", "+1", "01", "9223372036854775808", "18446744073709551615", String(repeating: "9", count: 1000)] {
            try await ожидаетсяОтказ(запись("world_state", ordinal: ordinal))
        }
        for metadata in ["null", "[]", "true", "1", "\"object\""] {
            try await ожидаетсяОтказ(запись("world_state", metadata: metadata))
        }
        for тип in ["future_runtime_type", "World_state", "world_state_v2"] { try await ожидаетсяОтказ(запись(тип)) }
        try await ожидаетсяОтказ(дополнить(запись("world_state"), "\"future_envelope_key\":{}"))
        try await ожидаетсяОтказ(дополнить(запись("world_state"), "\"ordi\\u006eal\":1"))
        for payload in ["null", "[]", "1", "\"payload\""] {
            try await ожидаетсяОтказ("{\"type\":\"world_state\",\"ordinal\":0,\"payload\":\(payload)}")
        }
        try await ожидаетсяОтказ("{\"type\":\"world_state\",\"ordinal\":0}")
    }
    func testБюджетыСохраняютсяВНовыхОбъектах() async throws {
        var глубина = БюджетАрхива(); глубина.глубина = 4
        try await ожидаетсяОтказ(запись("world_state", metadata: "{\"nested\":{\"nested\":{\"nested\":{}}}}"), бюджет: глубина)
        var узлы = БюджетАрхива(); узлы.узлыСтроки = 20
        try await ожидаетсяОтказ(запись("world_state", metadata: "{\"items\":[" + Array(repeating: "0", count: 40).joined(separator: ",") + "]}"), бюджет: узлы)
        try await ожидаетсяОтказ(запись("world_state", metadata: "{\"same\":0,\"sa\\u006de\":1}"))
    }
    func testСтарыйАрхивДополняетсяБезПереписыванияИВосстанавливаетсяБезИсточника() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let старые = [мета(), контекст()]
        try пример.записать(старые)
        let начальный = try пример.открыть(); let первый = try await начальный.импортировать(пример.источник)
        await начальный.закрыть()
        let сегмент = пример.архив.appendingPathComponent("сегмент.fumobs")
        let прежниеБайты = try Data(contentsOf: сегмент)
        let архив = try пример.открыть()
        let повтор = try await архив.импортировать(пример.источник)
        XCTAssertEqual(try каноническийJSON(повтор), try каноническийJSON(первый))
        XCTAssertEqual(try Data(contentsOf: сегмент), прежниеБайты)
        let новые = служебныеТипы.map { запись($0) }
        try пример.записать(старые + новые)
        let продолжение = try await архив.импортировать(пример.источник)
        let полный = try await архив.импортировать(пример.источник, полныйРазбор: true)
        XCTAssertEqual(try каноническийJSON(продолжение), try каноническийJSON(полный))
        XCTAssertEqual(продолжение.архив.модельХода, первый.архив.модельХода)
        XCTAssertTrue(try Data(contentsOf: сегмент).starts(with: прежниеБайты))
        let число = await архив.числоЗаписей(); XCTAssertEqual(число, 2)
        await архив.закрыть(); try FileManager.default.removeItem(at: пример.источник)
        let replay = try пример.открыть(); let восстановленный = try await replay.получить()
        XCTAssertEqual(try каноническийJSON(XCTUnwrap(восстановленный)), try каноническийJSON(продолжение))
        await replay.закрыть()
    }
}
