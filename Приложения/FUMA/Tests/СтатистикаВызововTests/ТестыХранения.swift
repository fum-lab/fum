import Foundation
import XCTest
import КонтейнерНаблюдений
@testable import СтатистикаВызовов

@MainActor
final class ТестыХранения: XCTestCase {
    func окружение() throws -> (URL, URL, URL) {
        let временный = try временныйКаталог()
        guard let физический = realpath(временный.path, nil) else { throw ОшибкаКонтейнера.система(errno) }
        defer { free(физический) }
        let база = URL(fileURLWithPath: String(cString: физический))
        let корень = база.appendingPathComponent("данные")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
        return (база, корень, база.appendingPathComponent("источник.jsonl"))
    }
    func testПараМеждуГруппамиИПовторПослеЗакрытия() async throws {
        let (база, корень, вход) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let префикс = try метаданные() + вызов()
        try префикс.write(to: вход)
        let первый = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let а = try await первый.импортировать(вход)
        XCTAssertEqual(а.отчёт.прямыхВызовов, 1)
        await первый.закрыть()
        try (префикс + результат()).write(to: вход)
        let второй = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let б = try await второй.импортировать(вход)
        XCTAssertEqual(б.отчёт.сопряжённыхРезультатов, 1)
        XCTAssertEqual(б.отчёт.вызовы[0].задержкаНаносекунды, 250_000_000)
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let байты = try Data(contentsOf: файл)
        let повтор = try await второй.импортировать(вход)
        XCTAssertEqual(повтор.новыхСобытий, 0)
        XCTAssertEqual(повтор.отчёт, б.отчёт)
        XCTAssertEqual(try Data(contentsOf: файл), байты)
        await второй.закрыть()
        try FileManager.default.removeItem(at: вход)
        let читатель = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: false)
        let восстановленный = try await читатель.получить()
        XCTAssertEqual(восстановленный, б.отчёт)
        await читатель.закрыть()
    }
    func test_ПустаяГруппаИНедописанныйХвостПродвигаютТолькоЗавершённыеСтроки() async throws {
        let (база, корень, вход) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let завершено = try метаданные() + строка("event_msg", ["text": "публичная фикстура"])
        let хвост = try вызов()
        try (завершено + хвост.dropLast()).write(to: вход)
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let а = try await х.импортировать(вход)
        XCTAssertEqual(а.отчёт.граница?.байт, завершено.count)
        XCTAssertEqual(а.новыхСобытий, 0)
        XCTAssertEqual(а.хвостБайт, хвост.count - 1)
        try (завершено + хвост).write(to: вход)
        let б = try await х.импортировать(вход)
        XCTAssertEqual(б.новыхСобытий, 1)
        await х.закрыть()
    }
    func test_НевернаяИдентичностьИФорматНеСоздаютСегмент() async throws {
        let (база, корень, вход) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        for данные in [try метаданные("22222222-2222-4222-8222-222222222222"), try метаданные() + Data("{bad}\n".utf8)] {
            try данные.write(to: вход)
            do { _ = try await х.импортировать(вход); XCTFail("ожидался отказ") } catch {}
            XCTAssertFalse(FileManager.default.fileExists(atPath: корень.appendingPathComponent("сегмент.fumobs").path))
        }
        await х.закрыть()
    }
    func testКонфликтВКонцеНовойГруппыНеМеняетБайтыИУчёт() async throws {
        let (база, корень, вход) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let начало = try метаданные() + вызов()
        try начало.write(to: вход)
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let до = try await х.импортировать(вход).отчёт
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let байты = try Data(contentsOf: файл)
        try (начало + вызов("call_b") + вызов(аргументы: "изменены")).write(to: вход)
        do { _ = try await х.импортировать(вход); XCTFail("ожидался конфликт") } catch {}
        let после = try await х.получить()
        XCTAssertEqual(после, до)
        XCTAssertEqual(try Data(contentsOf: файл), байты)
        await х.закрыть()
    }
    func test_ОтказСинхронизацииНеДаётПодтвержденияИПовторСноваСинхронизирует() async throws {
        for каталог in [false, true] {
            let (база, корень, вход) = try окружение()
            defer { try? FileManager.default.removeItem(at: база) }
            let пустой = try Сегмент(кореньДанных: корень, запись: true)
            пустой.закрыть()
            try (метаданные() + вызов() + результат()).write(to: вход)
            let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { дескриптор in
                var сведения = stat()
                guard fstat(дескриптор, &сведения) == 0 else { throw ОшибкаКонтейнера.система(EIO) }
                if (сведения.st_mode & S_IFMT == S_IFDIR) == каталог { throw ОшибкаКонтейнера.система(EIO) }
                try ФайловыеОперации.системные.синхронизация(дескриптор)
            })
            let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true, операции: операции)
            do { _ = try await х.импортировать(вход); XCTFail("ожидался EIO") }
            catch { XCTAssertEqual(error as? ОшибкаКонтейнера, .система(EIO)) }
            do { _ = try await х.получить(); XCTFail("неопределённый экземпляр") } catch {}
            await х.закрыть()
            let файл = корень.appendingPathComponent("сегмент.fumobs")
            let байты = try Data(contentsOf: файл)
            let повтор = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true, операции: операции)
            let видимый = try await повтор.получить()
            XCTAssertEqual(видимый.сопряжённыхРезультатов, 1)
            do { _ = try await повтор.импортировать(вход); XCTFail("повтор обязан fsync") }
            catch { XCTAssertEqual(error as? ОшибкаКонтейнера, .система(EIO)) }
            await повтор.закрыть()
            let успех = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
            let итог = try await успех.импортировать(вход)
            XCTAssertEqual(итог.отчёт, видимый)
            XCTAssertEqual(try Data(contentsOf: файл), байты)
            await успех.закрыть()
        }
    }
    func test_ВыходВРепозиторийОтклоняетсяДоСозданияСегмента() throws {
        let (база, корень, _) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        try Data("gitdir: публичная фикстура".utf8).write(to: база.appendingPathComponent(".git"))
        XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true))
        XCTAssertFalse(FileManager.default.fileExists(atPath: корень.appendingPathComponent("сегмент.fumobs").path))
    }
    func test_РежимЧтенияНеОтравляетЧтениеИПисательЗанят() async throws {
        let (база, корень, вход) = try окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        try (метаданные() + вызов()).write(to: вход)
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let до = try await х.импортировать(вход).отчёт
        XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true))
        await х.закрыть()
        let ч = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: false)
        do { _ = try await ч.импортировать(вход); XCTFail("read-only") }
        catch { XCTAssertEqual(error as? ОшибкаКонтейнера, .толькоЧтение) }
        let после = try await ч.получить()
        XCTAssertEqual(после, до)
        await ч.закрыть()
    }
}
