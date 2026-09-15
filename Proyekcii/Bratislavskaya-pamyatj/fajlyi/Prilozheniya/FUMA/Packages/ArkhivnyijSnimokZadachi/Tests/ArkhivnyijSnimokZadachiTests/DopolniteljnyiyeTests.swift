import XCTest
import Foundation
import Darwin
import СнимокАгентскойЗадачи
import КонтейнерНаблюдений
@testable import АрхивныйСнимокЗадачи

final class ДополнительныеTests: XCTestCase, @unchecked Sendable {
    func testАварияДоИПослеДолговечногоПодтверждения() async throws {
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for режим in ["середина-записи", "после-fsync"] {
            let пример = try Фикстура(); defer { пример.убрать() }
            let процесс = Process()
            процесс.executableURL = пакет.appendingPathComponent(".build/debug/АварийнаяФикстура")
            процесс.arguments = [пример.корень.path, режим]
            try процесс.run(); процесс.waitUntilExit()
            XCTAssertEqual(процесс.terminationReason, .uncaughtSignal)
            XCTAssertEqual(процесс.terminationStatus, SIGKILL)
            if режим == "середина-записи" {
                XCTAssertThrowsError(try пример.открыть()) { XCTAssertEqual($0 as? ОшибкаАрхива, .неполныйКонтейнер) }
            }
            let архив = try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidФикстуры, запись: true, восстановитьХвост: true)
            let до = await архив.числоЗаписей()
            XCTAssertEqual(до, режим == "после-fsync" ? 1 : 0)
            let результат = try await архив.импортировать(пример.источник)
            XCTAssertEqual(результат.архив.граница.строки, 1)
            let размер = пример.размер
            _ = try await архив.импортировать(пример.источник)
            XCTAssertEqual(размер, пример.размер)
            let после = await архив.числоЗаписей(); XCTAssertEqual(после, 1)
            await архив.закрыть()
        }
    }
    func testОтказFsyncКаталогаИНулевойWrite() async throws {
        for режим in 0..<2 {
            let пример = try Фикстура(); defer { пример.убрать() }
            try пример.записать([мета()])
            let пустой = try пример.открыть(); await пустой.закрыть()
            let операции = ФайловыеОперации(запись: { дескриптор, байты in
                if режим == 0 { return 0 }
                return try ФайловыеОперации.системные.запись(дескриптор, байты)
            }, синхронизация: { дескриптор in
                var состояние = stat(); _ = fstat(дескриптор, &состояние)
                if режим == 1, состояние.st_mode & S_IFMT == S_IFDIR { throw ОшибкаКонтейнера.система(EIO) }
                try ФайловыеОперации.системные.синхронизация(дескриптор)
            })
            let архив = try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidФикстуры, запись: true, операции: операции)
            do { _ = try await архив.импортировать(пример.источник); XCTFail("отказ потерян") } catch {}
            do { _ = try await архив.получить(); XCTFail("курсор подтверждён") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .неопределённаяЗапись) }
            await архив.закрыть()
        }
    }
    func testПолныйРазборРавенПродолжениюИПовторНеРазбираетПринятыеСтроки() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        let архив = try пример.открыть()
        try пример.записать([мета(), контекст()]); _ = try await архив.импортировать(пример.источник)
        try пример.записать([мета(), контекст(), контекст(ходВторой, модель: "model-two")])
        let быстрый = try await архив.импортировать(пример.источник)
        let профиль = await архив.профиль(); XCTAssertEqual(профиль.разобраноСтрок, 1)
        let полный = try await архив.импортировать(пример.источник, полныйРазбор: true)
        XCTAssertEqual(быстрый, полный)
        let полныйПрофиль = await архив.профиль(); XCTAssertEqual(полныйПрофиль.разобраноСтрок, 3)
        _ = try await архив.импортировать(пример.источник)
        let повтор = await архив.профиль(); XCTAssertEqual(повтор.разобраноСтрок, 0)
        await архив.закрыть()
    }
    func testГлубинаХвостИКоличествоАрхивныхЗаписейОграничены() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        var бюджет = БюджетАрхива(); бюджет.записи = 1
        let архив = try пример.открыть(бюджет)
        try пример.записать([мета()]); _ = try await архив.импортировать(пример.источник)
        try пример.записать([мета(), контекст()])
        do { _ = try await архив.импортировать(пример.источник); XCTFail("записей больше бюджета") }
        catch { XCTAssertEqual(error as? ОшибкаАрхива, .предел) }
        await архив.закрыть()
        for хвост in [false, true] {
            let новый = try Фикстура(); defer { новый.убрать() }
            var лимит = БюджетАрхива(); лимит.строка = 1024; лимит.глубина = 3
            if хвост { try новый.записать([мета()], хвост: Data(repeating: 65, count: 1025)) }
            else { try новый.записать([мета(), "{\"type\":\"event_msg\",\"payload\":{\"a\":[[[1]]]}}"] ) }
            let ограниченный = try новый.открыть(лимит)
            do { _ = try await ограниченный.импортировать(новый.источник); XCTFail("бюджет не сработал") }
            catch { XCTAssertEqual(error as? ОшибкаАрхива, .предел) }
            await ограниченный.закрыть()
        }
    }
    func testReplayОтклоняетЧужойUUIDИСогласованноУпакованныйНеверныйСнимок() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета()])
        let архив = try пример.открыть()
        let результат = try await архив.импортировать(пример.источник); await архив.закрыть()
        XCTAssertThrowsError(try АрхивЗадачи(корень: пример.архив, ожидаемыйUUID: uuidЧужой, запись: false))
        let другой = try Фикстура(); defer { другой.убрать() }
        let сегмент = try Сегмент(кореньДанных: другой.архив, запись: true)
        let сырой = try каноническийJSON(результат.архив)
        var объект = try XCTUnwrap(JSONSerialization.jsonObject(with: сырой) as? [String: Any])
        объект["shaСнимка"] = String(repeating: "0", count: 64)
        let испорченный = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
        _ = try сегмент.добавить(описаниеАрхива(результат.архив), данные: испорченный); сегмент.закрыть()
        XCTAssertThrowsError(try другой.открыть())
    }
    func testПолнаяСтрокаСПовреждённымUTF8Отклонена() async throws {
        let пример = try Фикстура(); defer { пример.убрать() }
        try пример.записать([мета()], хвост: Data([0xF0, 0x9F, 10]))
        let архив = try пример.открыть()
        do { _ = try await архив.импортировать(пример.источник); XCTFail("некорректный UTF-8 принят") }
        catch { XCTAssertEqual(error as? ОшибкаАрхива, .формат) }
        await архив.закрыть()
    }
}
