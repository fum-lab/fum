import Foundation
import Darwin
import XCTest
import КонтейнерНаблюдений
@testable import СтатистикаВызовов

@MainActor
final class ТестыОтказовХранения: XCTestCase {
    func testКрайнееСмещениеПроверяетсяДоАрифметики() throws {
        let вход = try сФайлом(метаданные() + вызов()) { try прочитатьПрефикс($0, задача: задачаФикстуры) }
        let исходный = вход.события[0]
        let событие = СобытиеВызова(направление: исходный.направление, семейство: исходный.семейство,
            идентификатор: исходный.идентификатор, инструмент: исходный.инструмент, момент: исходный.момент,
            происхождение: ПроисхождениеСтроки(строка: 2, начало: исходный.происхождение.начало,
                конец: Int.min, sha256: исходный.происхождение.sha256, контракт: контрактСтатистики))
        let пакет = ПакетСтатистики(версия: 1, контракт: контрактСтатистики, задача: задачаФикстуры,
            порядок: 1, до: nil, после: вход.граница!, события: [событие])
        XCTAssertThrowsError(try проверитьПакет(пакет, задача: задачаФикстуры, до: nil, порядок: 1,
                                               учёт: УчётВызовов(задача: задачаФикстуры)))
    }
    func testНевозможнаяРазницаСтрокИБайтовОтклоняется() throws {
        let вход = try сФайлом(метаданные() + вызов()) { try прочитатьПрефикс($0, задача: задачаФикстуры) }
        let а = ПакетСтатистики(версия: 1, контракт: контрактСтатистики, задача: задачаФикстуры,
            порядок: 1, до: nil, после: вход.граница!, события: вход.события)
        let б = ПакетСтатистики(версия: 1, контракт: контрактСтатистики, задача: задачаФикстуры,
            порядок: 2, до: а.после,
            после: ГраницаПрефикса(байт: а.после.байт + 1, строк: 300, sha256: а.после.sha256), события: [])
        let (база, корень, _) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let контейнер = try Сегмент(кореньДанных: корень, запись: true)
        for пакет in [а, б] { _ = try контейнер.добавить(описаниеПакета(пакет), данные: кодироватьСтатистику(пакет)) }
        контейнер.закрыть()
        XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: false))
    }
    func test_ПереносВыходаВРепозиторийСПодменойПутиНеДаётЗаписи() async throws {
        let (база, корень, вход) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let пустой = try Сегмент(кореньДанных: корень, запись: true); пустой.закрыть()
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        let репо = база.appendingPathComponent("репо")
        try FileManager.default.createDirectory(at: репо, withIntermediateDirectories: false)
        try Data("публичный gitdir".utf8).write(to: репо.appendingPathComponent(".git"))
        let перенесённый = репо.appendingPathComponent("данные")
        try FileManager.default.moveItem(at: корень, to: перенесённый)
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
        let файл = перенесённый.appendingPathComponent("сегмент.fumobs")
        let до = try Data(contentsOf: файл)
        try (метаданные() + вызов()).write(to: вход)
        do { _ = try await х.импортировать(вход); XCTFail("подмена namespace") } catch {}
        XCTAssertEqual(try Data(contentsOf: файл), до)
        await х.закрыть()
    }
    func testКороткаяЗаписьСОтказомНеПубликуетЧастичнуюГруппу() async throws {
        for предел in [17, 450, 900] {
            let (база, корень, вход) = try ТестыХранения().окружение()
            defer { try? FileManager.default.removeItem(at: база) }
            let пустой = try Сегмент(кореньДанных: корень, запись: true); пустой.закрыть()
            try (метаданные() + вызов() + результат()).write(to: вход)
            let операции = ФайловыеОперации(запись: { дескриптор, буфер in
                let позиция = lseek(дескриптор, 0, SEEK_CUR)
                if позиция >= предел { throw ОшибкаКонтейнера.система(EIO) }
                let длина = min(7, буфер.count, предел - Int(позиция))
                let число = Darwin.write(дескриптор, буфер.baseAddress, длина)
                if число < 0 { throw ОшибкаКонтейнера.система(errno) }
                return число
            }, синхронизация: ФайловыеОперации.системные.синхронизация)
            let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true, операции: операции)
            do { _ = try await х.импортировать(вход); XCTFail("короткая запись") }
            catch { XCTAssertEqual(error as? ОшибкаКонтейнера, .система(EIO)) }
            do { _ = try await х.получить(); XCTFail("нет публикации") } catch {}
            await х.закрыть()
            let файл = корень.appendingPathComponent("сегмент.fumobs")
            let послеОтказа = try Data(contentsOf: файл)
            XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true))
            XCTAssertEqual(try Data(contentsOf: файл), послеОтказа)
        }
    }
    func testПодменённыеКонвертыОтклоняютсяБезРемонта() throws {
        let префикс = try сФайлом(метаданные() + вызов()) { try прочитатьПрефикс($0, задача: задачаФикстуры) }
        let правильный = ПакетСтатистики(версия: 1, контракт: контрактСтатистики, задача: задачаФикстуры,
            порядок: 1, до: nil, после: префикс.граница!, события: префикс.события)
        let изменения: [(inout [String: Any]) -> Void] = [
            { $0["версия"] = 2 }, { $0["контракт"] = "другой" },
            { $0["задача"] = "22222222-2222-4222-8222-222222222222" },
            { $0["порядок"] = 2 }, { $0["до"] = $0["после"] }, { $0["лишнее"] = "значение" },
            { var п = $0["после"] as! [String: Any]; п["байт"] = 1; $0["после"] = п },
            { var события = $0["события"] as! [[String: Any]]
              var п = события[0]["происхождение"] as! [String: Any]; п["начало"] = 0
              события[0]["происхождение"] = п; $0["события"] = события },
            { var события = $0["события"] as! [[String: Any]]
              события[0]["момент"] = ["качество": "неверно", "наносекундыОтЭпохи": 1]; $0["события"] = события }
        ]
        for изменить in изменения {
            let (база, корень, _) = try ТестыХранения().окружение()
            defer { try? FileManager.default.removeItem(at: база) }
            var объект = try JSONSerialization.jsonObject(with: кодироватьСтатистику(правильный)) as! [String: Any]
            изменить(&объект)
            let данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
            let декодированный = try JSONDecoder().decode(ПакетСтатистики.self, from: данные)
            let контейнер = try Сегмент(кореньДанных: корень, запись: true)
            _ = try контейнер.добавить(описаниеПакета(декодированный), данные: данные)
            контейнер.закрыть()
            let файл = корень.appendingPathComponent("сегмент.fumobs")
            let до = try Data(contentsOf: файл)
            XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: false))
            XCTAssertEqual(try Data(contentsOf: файл), до)
        }
    }
    func testРазмерКвитанцииОтклоняетсяДоИзвлечения() throws {
        let (база, корень, _) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let контейнер = try Сегмент(кореньДанных: корень, запись: true)
        _ = try контейнер.добавить(ОписаниеНаблюдения(идентификатор: "public", тип: "публичная-фикстура"),
            данные: Data(repeating: 32, count: БюджетСтатистики.пакет + 1))
        контейнер.закрыть()
        XCTAssertThrowsError(try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: false)) {
            XCTAssertEqual($0 as? ОшибкаСтатистики, .предел)
        }
    }
    func testПределГруппИПовторПоследней() async throws {
        let (база, корень, вход) = try ТестыХранения().окружение()
        defer { try? FileManager.default.removeItem(at: база) }
        let х = try ХранилищеСтатистики(корень: корень, задача: задачаФикстуры, запись: true)
        var данные = try метаданные()
        for _ in 0..<БюджетСтатистики.пакеты {
            try данные.write(to: вход)
            _ = try await х.импортировать(вход)
            данные.append(try строка("event_msg", [:]))
        }
        let до = try await х.получить()
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let байты = try Data(contentsOf: файл)
        _ = try await х.импортировать(вход)
        try данные.write(to: вход)
        do { _ = try await х.импортировать(вход); XCTFail("предел") }
        catch { XCTAssertEqual(error as? ОшибкаСтатистики, .предел) }
        let после = try await х.получить()
        XCTAssertEqual(после, до)
        XCTAssertEqual(try Data(contentsOf: файл), байты)
        await х.закрыть()
    }
    func testЛимитыСтрокиГлубиныКлючейИВхода() throws {
        let длинная = try строка("event_msg", ["public_fixture": String(repeating: "x", count: БюджетСтатистики.строка)])
        let глубина = Data(("{\"type\":\"event_msg\",\"payload\":" + String(repeating: "[", count: 20) + "0" +
            String(repeating: "]", count: 20) + "}\n").utf8)
        let ключи = Dictionary(uniqueKeysWithValues: (0...БюджетСтатистики.ключи).map { ("k" + String($0), 0) })
        for данные in [Data(длинная.dropLast()), длинная, глубина, try строка("event_msg", ключи)] {
            try сФайлом(метаданные() + данные) {
                XCTAssertThrowsError(try прочитатьПрефикс($0, задача: задачаФикстуры)) {
                    XCTAssertEqual($0 as? ОшибкаСтатистики, .предел)
                }
            }
        }
        try сФайлом(метаданные()) { путь in
            let файл = try FileHandle(forWritingTo: путь)
            try файл.truncate(atOffset: UInt64(БюджетСтатистики.вход + 1)); try файл.close()
            XCTAssertThrowsError(try прочитатьПрефикс(путь, задача: задачаФикстуры)) {
                XCTAssertEqual($0 as? ОшибкаСтатистики, .предел)
            }
        }
        let событие = try сводка(метаданные() + вызов()).наблюдения[0]
        var учёт = try УчётВызовов(задача: задачаФикстуры)
        XCTAssertThrowsError(try учёт.принять(Array(repeating: событие, count: БюджетСтатистики.события + 1)))
        XCTAssertTrue(учёт.отчёт().наблюдения.isEmpty)
    }
}
