import XCTest
import Foundation
import Darwin
import CryptoKit
import СнимокАгентскойЗадачи
import КонтейнерНаблюдений
@testable import АрхивныйСнимокЗадачи

let uuidФикстуры = "11111111-1111-4111-8111-111111111111"
let uuidЧужой = "22222222-2222-4222-8222-222222222222"
let ходПервый = "33333333-3333-4333-8333-333333333333"
let ходВторой = "44444444-4444-4444-8444-444444444444"

struct Фикстура {
    let корень: URL
    let источник: URL
    let архив: URL
    init() throws {
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        корень = пакет.appendingPathComponent(".build/фикстуры/" + UUID().uuidString)
        источник = корень.appendingPathComponent("источник.jsonl")
        архив = корень.appendingPathComponent("архив")
        try FileManager.default.createDirectory(at: архив, withIntermediateDirectories: true)
    }
    func убрать() { try? FileManager.default.removeItem(at: корень) }
    func записать(_ строки: [String], хвост: Data = Data()) throws {
        var данные = Data((строки.joined(separator: "\n") + "\n").utf8)
        данные.append(хвост)
        try данные.write(to: источник)
    }
    func открыть(_ бюджет: БюджетАрхива = .init()) throws -> АрхивЗадачи {
        try АрхивЗадачи(корень: архив, ожидаемыйUUID: uuidФикстуры, запись: true, бюджет: бюджет)
    }
    var размер: Int { (try? Data(contentsOf: архив.appendingPathComponent("сегмент.fumobs")).count) ?? 0 }
}
func мета(_ uuid: String = uuidФикстуры) -> String {
    "{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(uuid)\",\"cwd\":\"/synthetic/work\",\"instructions\":\"SECRET_META\"}}"
}
func контекст(_ ход: String = ходПервый, модель: String? = "model-one") -> String {
    let поле = модель.map { ",\"model\":\"\($0)\"" } ?? ""
    return "{\"type\":\"turn_context\",\"payload\":{\"turn_id\":\"\(ход)\"\(поле)}}"
}

final class АрхивTests: XCTestCase, @unchecked Sendable {
    func testИдентичностьИМинимальныеФактыБезСкрытогоТекста() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст()])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник)
        XCTAssertEqual(результат.архив.ожидаемыйUUID, uuidФикстуры)
        XCTAssertEqual(результат.архив.sessionMeta.позиция.номер, 1)
        XCTAssertEqual(результат.архив.граница.строки, 2)
        XCTAssertEqual(результат.архив.граница.байты, try Data(contentsOf: пример.источник).count)
        XCTAssertEqual(результат.снимок.значение(.каталогRuntime).кандидаты.first?.значение, "/synthetic/work")
        XCTAssertEqual(результат.снимок.значение(.наблюдённаяМодель, ходПервый).кандидаты.first?.значение, "model-one")
        XCTAssertEqual(результат.снимок.наблюдения.count, 3)
        XCTAssertEqual(результат.архив.охват, "по состоянию прочитанного префикса")
        let байты = try каноническийJSON(результат)
        XCTAssertFalse(String(decoding: байты, as: UTF8.self).contains("SECRET_META"))
        XCTAssertFalse(String(decoding: байты, as: UTF8.self).contains("синтетический"))
        XCTAssertEqual(результат.архив.shaСнимка, хэшАрхива(try каноническийJSON(результат.снимок)))
        await архив.закрыть()
    }

    func testЧужойПовторныйИНеканоническийUUID() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        XCTAssertThrowsError(try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: "не-uuid", запись: true))
        for (строки, ошибка) in [([мета(uuidЧужой)], ОшибкаАрхива.чужаяСессия),
                                  ([мета(), мета()], .повторнаяИдентичность)] {
            try пример.записать(строки)
            let архив = try пример.открыть()
            do { _ = try await архив.импортировать(пример.источник); XCTFail("ожидался отказ") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, ошибка) }
            let количество = await архив.числоЗаписей(); XCTAssertEqual(количество, 0)
            await архив.закрыть()
        }
    }

    func testНезавершённыеJSONИUTF8НеВходятВКурсор() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let архив = try пример.открыть()
        for хвост in [Data("{\"type\":".utf8), Data([0xF0, 0x9F]), Data(контекст().utf8)] {
            try пример.записать([мета()], хвост: хвост)
            let результат = try await архив.импортировать(пример.источник)
            XCTAssertEqual(результат.архив.граница.строки, 1)
            XCTAssertEqual(результат.архив.граница.байты, мета().utf8.count + 1)
        }
        let количество = await архив.числоЗаписей(); XCTAssertEqual(количество, 1)
        await архив.закрыть()
    }

    func testПовторRestartReplayБезИсточникаИДополнение() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст()])
        let архив = try пример.открыть()
        let первый = try await архив.импортировать(пример.источник)
        let размер = пример.размер
        let повтор = try await архив.импортировать(пример.источник)
        XCTAssertEqual(первый, повтор); XCTAssertEqual(пример.размер, размер)
        await архив.закрыть()
        try FileManager.default.removeItem(at: пример.источник)
        let восстановленный = try пример.открыть()
        let replay = try await восстановленный.получить(); XCTAssertEqual(replay, первый)
        do { _ = try await восстановленный.импортировать(пример.источник); XCTFail("источник обязателен") } catch {}
        try пример.записать([мета(), контекст()])
        let повторПосле = try await восстановленный.импортировать(пример.источник)
        XCTAssertEqual(повторПосле, первый); XCTAssertEqual(пример.размер, размер)
        try пример.записать([мета(), контекст(), "{\"type\":\"event_msg\",\"payload\":{\"type\":\"token_count\"}}"])
        let новый = try await восстановленный.импортировать(пример.источник)
        XCTAssertNotEqual(новый.архив.граница, первый.архив.граница)
        let количество = await восстановленный.числоЗаписей(); XCTAssertEqual(количество, 2)
        await восстановленный.закрыть()
    }

    func testПодменаПринятогоПрефиксаЗакрываетПродолжение() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст()])
        let архив = try пример.открыть()
        let первый = try await архив.импортировать(пример.источник)
        for строки in [[мета(), контекст(модель: "model-two")], [мета()]] {
            try пример.записать(строки)
            do { _ = try await архив.импортировать(пример.источник); XCTFail("подмена принята") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .подменаПрефикса) }
            let снимок = try await архив.получить(); XCTAssertEqual(снимок, первый)
        }
        await архив.закрыть()
    }

    func testМодельНеПереноситсяНаДругойХод() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let архив = try пример.открыть()
        try пример.записать([мета(), контекст(), контекст(ходВторой, модель: nil)])
        let результат = try await архив.импортировать(пример.источник)
        XCTAssertEqual(результат.архив.последнийХод?.значение, ходВторой)
        XCTAssertNil(результат.архив.модельХода)
        XCTAssertTrue(результат.снимок.неизвестныеПоля.contains(.наблюдённаяМодель))
        XCTAssertEqual(результат.снимок.значение(.наблюдённаяМодель, ходПервый).знание, .неизвестно)
        await архив.закрыть()
    }

    func testFinalHookPromptEOFНеДоказываютЖизненныйЦикл() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета(), контекст(),
            "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"assistant\",\"phase\":\"final_answer\",\"content\":[{\"text\":\"SECRET_DIALOG\"}]}}",
            "{\"type\":\"event_msg\",\"payload\":{\"type\":\"HookPrompt\",\"text\":\"SECRET_HOOK\"}}",
            "{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\",\"turn_id\":\"\(ходПервый)\"}}"])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник)
        for поле: Поле in [.текущаяРабота, .ожидание, .назначенныйWorktree, .каталогКоманды] {
            XCTAssertEqual(результат.снимок.значение(поле).знание, .неизвестно)
        }
        XCTAssertTrue(результат.снимок.операции.isEmpty)
        XCTAssertFalse(String(decoding: try каноническийJSON(результат), as: UTF8.self).contains("SECRET_"))
        await архив.закрыть()
    }

    func testНеоднозначныйФорматДублиКлючейИПовреждённаяПолнаяСтрока() async throws {
        let строки = [
            "{\"type\":\"event_msg\",\"type\":\"session_meta\",\"payload\":{}}",
            "{\"type\":\"event_msg\",\"payload\":{\"a\":1,\"\\u0061\":2}}",
            "{\"type\":\"future_format\",\"payload\":{}}",
            "{\"type\":\"turn_context\",\"payload\":{\"model\":\"unbound\"}}",
            "{\"type\":\"turn_context\",\"payload\":{\"turn_id\":\"\(ходПервый)\",\"model\":null}}",
            "{\"type\":\"event_msg\",\"payload\":{\"type\":\"x\"}",
            "[]", ""]
        for строка in строки {
            let пример = try Фикстура(); defer { пример.убрать() }
            try пример.записать([мета(), строка])
            let архив = try пример.открыть()
            do { _ = try await архив.импортировать(пример.источник); XCTFail("неоднозначность принята") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .формат) }
            await архив.закрыть()
        }
    }

    func testБюджетыИСтрокаБольшеТрёхМегабайт() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let большая = "{\"type\":\"response_item\",\"payload\":{\"text\":\"" + String(repeating: "z", count: 3_326_896) + "\"}}"
        try пример.записать([мета(), большая])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник)
        XCTAssertEqual(результат.архив.граница.строки, 2)
        await архив.закрыть()
        for вид in 0..<4 {
            let малый = try Фикстура(); defer { малый.убрать() }
            try малый.записать([мета(), большая])
            var бюджет = БюджетАрхива()
            if вид == 0 { бюджет.строка = 1_048_576 }
            if вид == 1 { бюджет.байты = 1024 }
            if вид == 2 { бюджет.строки = 1 }
            if вид == 3 { бюджет.узлыСтроки = 2 }
            let ограниченный = try малый.открыть(бюджет)
            do { _ = try await ограниченный.импортировать(малый.источник); XCTFail("предел не соблюдён") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .предел) }
            await ограниченный.закрыть()
        }
    }

    func testОшибкиЗаписиИFsyncНеПодтверждаютКурсор() async throws {
        for сбой in 0..<3 {
            let пример = try Фикстура(); defer { пример.убрать() }
            try пример.записать([мета()])
            let пустой = try пример.открыть(); await пустой.закрыть()
            let операции = ФайловыеОперации(запись: { дескриптор, байты in
                if сбой == 0 { throw ОшибкаКонтейнера.система(ENOSPC) }
                return try ФайловыеОперации.системные.запись(дескриптор, байты)
            }, синхронизация: { дескриптор in
                if сбой == 1 { throw ОшибкаКонтейнера.система(EIO) }
                try ФайловыеОперации.системные.синхронизация(дескриптор)
                if сбой == 2 { throw ОшибкаКонтейнера.система(EIO) }
            })
            let архив = try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidФикстуры, запись: true, операции: операции)
            do { _ = try await архив.импортировать(пример.источник); XCTFail("I/O-ошибка потеряна") } catch {}
            do { _ = try await архив.получить(); XCTFail("неопределённый экземпляр доступен") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .неопределённаяЗапись) }
            await архив.закрыть()
            let восстановленный = try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidФикстуры, запись: true, восстановитьХвост: true)
            let результат = try await восстановленный.импортировать(пример.источник)
            XCTAssertEqual(результат.архив.граница.строки, 1)
            let число = await восстановленный.числоЗаписей(); XCTAssertEqual(число, 1)
            await восстановленный.закрыть()
        }
    }
}
