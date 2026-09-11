import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиМанифестаГотовности: XCTestCase {
    let родитель = "12345678-1234-4234-8234-123456789abc"
    let проверка = "22345678-1234-4234-8234-123456789abc"
    let исходник = "# Открытый исходник с ё\nimport json, os\n"
    let счётчик = "# Открытый счётчик\n"
    func создать(_ машина: String = "32345678-1234-4234-8234-123456789abc", _ план: String = String(repeating: "a", count: 64)) throws -> МанифестГотовностиГостя {
        let запуск = ЗапускМашины(машина: машина, план: план, портДоступаКГостю: 45678, портУправления: 45679)
        return try МанифестГотовностиГостя.создать(запуск: запуск, родитель: родитель, проверка: проверка,
            коммит: Профиль().коммит, ожидаемыеДанные: "", исходник: исходник, счётчик: счётчик)
    }
    func test_МанифестСвязываетТочныеИсходникиЗапросИОтправку() throws {
        let манифест = try создать()
        XCTAssertNoThrow(try манифест.проверить())
        XCTAssertEqual(манифест.исходник, Data(исходник.utf8))
        XCTAssertEqual(манифест.счётчик, Data(счётчик.utf8))
        XCTAssertEqual(манифест.контекст.исходник, хэш(try кодировать([
            "готовность.py": Data(исходник.utf8), "проверить-набор.py": Data(счётчик.utf8)])))
        let тело = try XCTUnwrap(JSONSerialization.jsonObject(with: манифест.данные) as? [String: String])
        XCTAssertEqual(тело["родитель"], родитель); XCTAssertEqual(тело["проверка"], проверка)
        XCTAssertEqual(тело["счётчик"], счётчик); XCTAssertEqual(тело["исходник"], манифест.контекст.исходник)
        let шестнадцатеричные = манифест.данные.map { String(format: "%02x", $0) }.joined()
        let ожидаемый = исходник + "\nos.umask(0o077)\nprint(json.dumps(подтвердить_готовность(json.loads(bytes.fromhex(\"" + шестнадцатеричные + "\").decode())), ensure_ascii=False, sort_keys=True))\n"
        XCTAssertEqual(манифест.вход, Data(ожидаемый.utf8))
        let экспорт = try манифест.входЭкспорта()
        XCTAssertTrue(экспорт.starts(with: Data(исходник.utf8)))
        XCTAssertTrue(String(decoding: экспорт, as: UTF8.self).contains("экспортировать_измерения"))
        let программа = try РесурсыГостя.текст("готовность.py"), измеритель = try РесурсыГостя.текст("проверить-набор.py")
        var запуск = ЗапускМашины(машина: "32345678-1234-4234-8234-123456789abc", план: String(repeating: "a", count: 64),
            портДоступаКГостю: 45678, портУправления: 45679)
        запуск.запуск = "42345678-1234-4234-8234-123456789abc"
        var интервалы: [UInt64] = [], отправка = Data()
        for _ in 0..<3 {
            let начало = DispatchTime.now().uptimeNanoseconds
            let полный = try МанифестГотовностиГостя.создать(запуск: запуск, родитель: родитель, проверка: проверка,
                коммит: Профиль().коммит, ожидаемыеДанные: "", исходник: программа, счётчик: измеритель)
            try полный.проверить(); _ = try полный.входЭкспорта()
            интервалы.append(DispatchTime.now().uptimeNanoseconds - начало)
            if !отправка.isEmpty { XCTAssertEqual(отправка, полный.вход) }
            отправка = полный.вход
        }
        let профиль: [String: Any] = ["схема": "fum.профиль-манифеста.1",
            "исходник_sha256": try МанифестГотовностиГостя.исходныйОтпечаток(исходник: Data(программа.utf8), счётчик: Data(измеритель.utf8)),
            "вход_sha256": хэш(отправка), "интервалы_нс": интервалы, "медиана_нс": интервалы.sorted()[1], "предкритерий_нс": 250_000_000]
        print("ПРОФИЛЬ_МАНИФЕСТА " + String(decoding: try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys]), as: UTF8.self))
    }
    func test_ПодменаБайтовИКонтекстаОтклоняетсяПослеЧтения() throws {
        let запуск = ЗапускМашины(машина: "32345678-1234-4234-8234-123456789abc", план: String(repeating: "a", count: 64),
            портДоступаКГостю: 45678, портУправления: 45679)
        let первый = try МанифестГотовностиГостя.создать(запуск: запуск, родитель: родитель, проверка: проверка,
            коммит: Профиль().коммит, ожидаемыеДанные: "", исходник: "# a\n", счётчик: "# b\n# c\n")
        let второй = try МанифестГотовностиГостя.создать(запуск: запуск, родитель: родитель, проверка: проверка,
            коммит: Профиль().коммит, ожидаемыеДанные: "", исходник: "# a\n# b\n", счётчик: "# c\n")
        XCTAssertNotEqual(первый.контекст.исходник, второй.контекст.исходник)
        let манифест = try создать()
        let исходные = try XCTUnwrap(JSONSerialization.jsonObject(with: кодировать(манифест)) as? [String: Any])
        for поле in ["вход", "исходник", "счётчик", "данные", "контекст"] {
            var тело = исходные
            if поле == "контекст" {
                var контекст = try XCTUnwrap(тело[поле] as? [String: Any]); контекст["проверка"] = родитель; тело[поле] = контекст
            } else { тело[поле] = Data("Подменённые байты".utf8).base64EncodedString() }
            let изменённый = try JSONDecoder().decode(МанифестГотовностиГостя.self, from: JSONSerialization.data(withJSONObject: тело))
            XCTAssertThrowsError(try изменённый.проверить())
            XCTAssertThrowsError(try изменённый.входЭкспорта())
        }
    }
    func test_СохранениеПовтораНеМеняетПрежнееСвидетельство() throws {
        let физический = try XCTUnwrap(realpath(FileManager.default.temporaryDirectory.path, nil))
        defer { free(физический) }
        let родитель = URL(fileURLWithPath: String(cString: физический)).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: родитель, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: родитель) }
        let план = try ПланМашины.создать(профиль: Профиль(), каталог: родитель.appendingPathComponent("машина").path,
            ресурсы: Ресурсы(архитектура: "arm64", виртуализация: true, процессоры: 10, памятьБайт: 64 << 30, свободноБайт: 100 << 30))
        let хранилище = try Хранилище(план: план, создать: true)
        let манифест = try создать(хранилище.паспорт.идентификатор, план.отпечаток)
        try манифест.сохранить(хранилище)
        let имя = "запрос-готовности-" + проверка + ".json"
        let первые = try хранилище.прочитать(имя)
        let файл = try хранилище.открытьФайл(имя); defer { close(файл) }
        var сведения = stat(); XCTAssertEqual(fstat(файл, &сведения), 0)
        try манифест.сохранить(хранилище)
        let повторный = try хранилище.открытьФайл(имя); defer { close(повторный) }
        var повтор = stat(); XCTAssertEqual(fstat(повторный, &повтор), 0)
        XCTAssertEqual(сведения.st_ino, повтор.st_ino)
        XCTAssertEqual(первые, try хранилище.прочитать(имя))
        let иной = try создать(хранилище.паспорт.идентификатор, план.отпечаток) // Та же проверка, новый UUID запуска VM.
        XCTAssertThrowsError(try иной.сохранить(хранилище))
        XCTAssertEqual(первые, try хранилище.прочитать(имя))
        XCTAssertThrowsError(try создать().сохранить(хранилище))
    }
}
