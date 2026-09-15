import Foundation
import Darwin
import XCTest
@testable import СнимокАгентскойЗадачи
import КонтейнерНаблюдений

@MainActor func ожидаетсяОтказ(_ действие: () async throws -> Void) async {
    do { try await действие(); XCTFail("Ожидался явный отказ") }
    catch {}
}

@MainActor final class ОтказыХраненияTests: XCTestCase {
    func testСтарыйПовторНеОткатываетХэшСледующегоПерехода() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let входы = [запись(1, .время), запись(2, .время), запись(3, .время)]
        let хранилище = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        for вход in [входы[0], входы[1], входы[0], входы[2]] { _ = try await хранилище.принять(вход) }
        await хранилище.закрыть()
        let новое = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: false)
        let восстановленный = try await новое.получить()
        await новое.закрыть()
        let контейнер = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { контейнер.закрыть() }
        var эталон = try Редуктор(задача: задачаПримера)
        for вход in входы {
            let (следующий, запись) = try следующийПереход(вход, эталон) // Оба хэша вычисляются без кэша.
            XCTAssertEqual(try контейнер.извлечь(вход.идентификатор), try каноническийJSON(запись))
            эталон = следующий
        }
        XCTAssertEqual(try каноническийJSON(восстановленный), try каноническийJSON(эталон.снимок))
    }
    func testРасширениеNFCИдентичностиОтклоняетсяДоСозданияФайла() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let исходная = String(repeating: "x" + String(UnicodeScalar(0x0344)!), count: 42)
        XCTAssertEqual(исходная.utf8.count, 126)
        XCTAssertEqual(исходная.precomposedStringWithCanonicalMapping.utf8.count, 210)
        let задача = Задача(поставщик: "стенд", хост: "стенд", идентификатор: исходная)
        XCTAssertThrowsError(try ХранилищеСнимка(корень: корень, задача: задача, запись: true))
        XCTAssertFalse(FileManager.default.fileExists(atPath: корень.appendingPathComponent("сегмент.fumobs").path))
    }
    func testИсходныйUnicodePayloadСохраняетсяБайтовоАПовторСДругимиБайтамиОтклоняется() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let исходныйТекст = "исходный приём".decomposedStringWithCanonicalMapping
        let вход = Наблюдение(идентификатор: "unicode-1", задача: задачаПримера,
            источник: Источник(.журнал), такт: 1, исходныйФакт: исходныйТекст,
            факт: .значение(поле: .текущаяРабота, контекст: "", текст: исходныйТекст))
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let исходныеБайты = try кодировщик.encode(вход)
        XCTAssertEqual(try каноническийJSON(вход), исходныеБайты)
        let писатель = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        _ = try await писатель.принять(вход)
        await писатель.закрыть()
        let читатель = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let восстановленный = try await читатель.получить()
        XCTAssertEqual(try кодировщик.encode(восстановленный.наблюдения[0]), исходныеБайты)
        let другой = Наблюдение(идентификатор: вход.идентификатор, задача: вход.задача,
            источник: вход.источник, такт: 1, исходныйФакт: исходныйТекст.precomposedStringWithCanonicalMapping,
            факт: .значение(поле: .текущаяРабота, контекст: "", текст: исходныйТекст.precomposedStringWithCanonicalMapping))
        XCTAssertEqual(вход, другой) // Swift Equatable не доказывает совпадение UTF-8.
        XCTAssertNotEqual(try кодировщик.encode(вход), try кодировщик.encode(другой))
        await ожидаетсяОтказ { _ = try await читатель.принять(другой) }
        await читатель.закрыть()
        let контейнер = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { контейнер.закрыть() }
        let запись = try JSONDecoder().decode(СохранённоеНаблюдение.self, from: контейнер.извлечь(вход.идентификатор))
        XCTAssertEqual(try кодировщик.encode(запись.наблюдение), исходныеБайты)
    }
    func testReadOnlyОтказНеОтравляетЧтение() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let писатель = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let вход = запись(1, .время)
        let до = try await писатель.принять(вход)
        await писатель.закрыть()
        let читатель = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: false)
        await ожидаетсяОтказ { _ = try await читатель.принять(вход) }
        let после = try await читатель.получить()
        await читатель.закрыть()
        XCTAssertEqual(до, после)
    }
    func testЧужойIDИНеверныйВводНеМеняютБайты() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let хранилище = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let вход = запись(1, .время)
        _ = try await хранилище.принять(вход)
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let до = try Data(contentsOf: файл)
        await ожидаетсяОтказ { _ = try await хранилище.принять(изменить(вход, версия: 2)) }
        await ожидаетсяОтказ { _ = try await хранилище.принять(изменить(вход, факт: .отказ(причина: "другие байты"))) }
        let чужая = Задача(поставщик: задачаПримера.поставщик, хост: "чужой", идентификатор: задачаПримера.идентификатор)
        await ожидаетсяОтказ { _ = try await хранилище.принять(изменить(вход, задача: чужая)) }
        let сценарий = Сценарий(задача: задачаПримера, наблюдения: [
            запись(2, .время), изменить(запись(3, .время), версия: 2)
        ])
        await ожидаетсяОтказ { _ = try await хранилище.проиграть(сценарий) }
        await хранилище.закрыть()
        XCTAssertEqual(try Data(contentsOf: файл), до)
        XCTAssertThrowsError(try ХранилищеСнимка(корень: корень, задача: чужая, запись: false))
        XCTAssertEqual(try Data(contentsOf: файл), до)
    }
    func testFsyncНеоднозначностьПовторяетИсходныйПереход() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let пустой = try Сегмент(кореньДанных: корень, запись: true)
        пустой.закрыть()
        let сбой = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
                                   синхронизация: { _ in throw ОшибкаКонтейнера.система(EIO) })
        let вход = запись(1, .команда(операция: "оп", фаза: .отправлена, эффект: "открыта", корректирует: nil), канал: .команда)
        let первое = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true, операции: сбой)
        await ожидаетсяОтказ { _ = try await первое.принять(вход) }
        await ожидаетсяОтказ { _ = try await первое.получить() }
        await первое.закрыть()
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let видимыеБайты = try Data(contentsOf: файл)
        let повторСоСбоем = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true, операции: сбой)
        let восстановленный = try await повторСоСбоем.получить()
        XCTAssertEqual(восстановленный.наблюдения.count, 1)
        XCTAssertNil(восстановленный.операции.first?.подтверждение)
        await ожидаетсяОтказ { _ = try await повторСоСбоем.принять(вход) }
        await повторСоСбоем.закрыть()
        let успешный = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let итог = try await успешный.принять(вход)
        await успешный.закрыть()
        XCTAssertEqual(итог, восстановленный)
        XCTAssertEqual(try Data(contentsOf: файл), видимыеБайты)
    }
    func testПовреждениеИНеполныйХвостНеВосстанавливаютсяМолча() async throws {
        for неполный in [false, true] {
            let корень = try временныйКорень()
            defer { try? FileManager.default.removeItem(at: корень) }
            let хранилище = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
            _ = try await хранилище.принять(запись(1, .время))
            await хранилище.закрыть()
            let файл = корень.appendingPathComponent("сегмент.fumobs")
            var байты = try Data(contentsOf: файл)
            if неполный { байты.removeLast(8) } else { байты[байты.count - 1] ^= 1 }
            try байты.write(to: файл)
            XCTAssertThrowsError(try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true))
            XCTAssertEqual(try Data(contentsOf: файл), байты)
        }
    }
    func testВерсияИПодложныйПереходВКорректномКонтейнереОтклоняются() throws {
        for версия in [1, 2] {
            let корень = try временныйКорень()
            defer { try? FileManager.default.removeItem(at: корень) }
            let вход = запись(1, .время)
            let (_, правильная) = try следующийПереход(вход, Редуктор(задача: задачаПримера))
            let запись = СохранённоеНаблюдение(версия: версия, наблюдение: вход,
                переход: Переход(порядок: 1, до: правильная.переход.до, после: String(repeating: "0", count: 64)))
            let контейнер = try Сегмент(кореньДанных: корень, запись: true)
            _ = try контейнер.добавить(описаниеЗаписи(вход), данные: каноническийJSON(запись))
            контейнер.закрыть()
            XCTAssertThrowsError(try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: false))
        }
    }
    func testКонкурентныеПовторыСериализуютсяАктором() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let хранилище = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let вход = запись(1, .время)
        try await withThrowingTaskGroup(of: Снимок.self) { группа in
            for _ in 0..<16 { группа.addTask { try await хранилище.принять(вход) } }
            for try await снимок in группа { XCTAssertEqual(снимок.наблюдения.count, 1) }
        }
        await хранилище.закрыть()
        let контейнер = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { контейнер.закрыть() }
        XCTAssertEqual(контейнер.записи.count, 1)
    }
}
