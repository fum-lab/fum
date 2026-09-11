import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиИсточникаНаблюдателя: XCTestCase {
    private var корень: URL!
    private var программа: URL { корень.appendingPathComponent("машина") }
    private var снимок: URL { корень.appendingPathComponent("снимок-python.json") }
    private var поставка: URL { корень.appendingPathComponent("поставка.json") }
    private var ресурс: URL!
    private let имяПакета = "ВиртуальнаяМашина_ЯдроМашины.bundle"
    private let имяИсходника = "Sources/ЯдроМашины/Ресурсы/наблюдатель.py"
    private var питон: [String: Any] {
        ["путь": "/открытая-фикстура/python", "реализация": "cpython", "версия": "3.14.7 открытая фикстура",
         "sha256": String(repeating: "a", count: 64), "возможности": ["waitid", "WNOWAIT"]]
    }
    override func setUpWithError() throws {
        let физический = realpath(FileManager.default.temporaryDirectory.path, nil)!
        defer { free(физический) }
        корень = URL(fileURLWithPath: String(cString: физический)).appendingPathComponent("источник-" + UUID().uuidString + " ё")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        try Data("открытые байты бинарника; не исполняются".utf8).write(to: программа)
        XCTAssertEqual(chmod(программа.path, 0o700), 0)
        try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": питон])
        try подготовитьПакет(вложенный: false)
    }
    override func tearDownWithError() throws {
        if let корень { try FileManager.default.removeItem(at: корень) }
    }
    private func упаковать(_ значение: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: значение, options: [.sortedKeys])
    }
    private func запись(_ адрес: URL) throws -> [String: Any] {
        let данные = try Data(contentsOf: адрес)
        var сведения = stat(); XCTAssertEqual(lstat(адрес.path, &сведения), 0)
        return ["sha256": хэш(данные), "размер": данные.count, "права": Int(сведения.st_mode & 0o777)]
    }
    private func записатьСнимок(_ значение: Any) throws { try упаковать(значение).write(to: снимок) }
    private func подготовитьПакет(вложенный: Bool) throws {
        let папка = корень.appendingPathComponent(имяПакета + (вложенный ? "/Contents/Resources" : ""))
        try FileManager.default.createDirectory(at: папка, withIntermediateDirectories: true)
        ресурс = папка.appendingPathComponent("наблюдатель.py")
        try Data("# Открытая фикстура; Python не запускается.\n".utf8).write(to: ресурс)
        try сохранитьПоставку()
    }
    private func телоПоставки() throws -> [String: Any] {
        let имяРесурса = String(ресурс.path.dropFirst(корень.path.count + 1))
        return ["схема": "fum.поставка-VM.1", "вход": ["python": питон,
            "исходники": [имяИсходника: try запись(ресурс)], "упаковщик": String(repeating: "b", count: 64),
            "свифт": "/открытая-фикстура/swift", "версия": "открытая версия Swift", "система": "xcode",
            "платформа": "darwin", "набор_разработчика": ["путь": "/открытая-фикстура/SDK", "версия": "27.0"],
            "выбор_среды": ["DEVELOPER_DIR": NSNull(), "SDKROOT": NSNull()]],
            "файлы": ["машина": try запись(программа), имяРесурса: try запись(ресурс)], "профиль": []]
    }
    private func сохранитьПоставку(_ изменение: ((inout [String: Any]) -> Void)? = nil) throws {
        var тело = try телоПоставки(); изменение?(&тело); try упаковать(тело).write(to: поставка)
    }
    private func проверитьПитон(_ данные: Data) throws {
        let объект = try JSONSerialization.jsonObject(with: данные) as? NSDictionary
        XCTAssertEqual(объект, питон as NSDictionary)
    }
    private func прочитать(_ явный: String? = nil,
                           проверяющий: ((Data) throws -> Void)? = nil) throws -> ИсточникНаблюдателя {
        try ИсточникНаблюдателя.прочитать(исполняемыйФайл: программа, ресурс: ресурс,
            явныйСнимок: явный, проверитьПитон: проверяющий ?? проверитьПитон)
    }
    private func отклонитьДоПитона(_ явный: String? = nil) {
        var вызовов = 0
        XCTAssertThrowsError(try прочитать(явный) { _ in вызовов += 1 })
        XCTAssertEqual(вызовов, 0)
    }
    func test_ПоставкаСвязанаСФактическимиБайтамиВОбоихРазмещениях() throws {
        for вложенный in [false, true] {
            try подготовитьПакет(вложенный: вложенный)
            let до = try Data(contentsOf: поставка)
            var вызовов = 0
            var переданныеБайты: Data?
            let ответ = try прочитать("/неиспользуемый-снимок") { данные in
                вызовов += 1; переданныеБайты = данные; try self.проверитьПитон(данные)
            }
            XCTAssertEqual(вызовов, 1)
            XCTAssertEqual(ответ.наблюдатель, try Data(contentsOf: ресурс))
            try проверитьПитон(ответ.питон)
            XCTAssertEqual(ответ.питон, переданныеБайты)
            XCTAssertEqual(ответ.происхождение.count, 64)
            XCTAssertEqual(try Data(contentsOf: поставка), до)
        }
    }
    func test_РазработкаТребуетПолнуюЯвнуюОболочку() throws {
        try FileManager.default.removeItem(at: поставка)
        отклонитьДоПитона()
        let ответ = try прочитать(снимок.path)
        try проверитьПитон(ответ.питон)
        XCTAssertEqual(ответ.наблюдатель, try Data(contentsOf: ресурс))
        XCTAssertEqual(ответ.происхождение.count, 64)
        for значение in [питон, ["схема": "иная", "python": питон],
                         ["схема": "fum.python-наблюдателя.1", "python": питон, "лишнее": true]] as [[String: Any]] {
            try записатьСнимок(значение); отклонитьДоПитона(снимок.path)
        }
        for ключ in питон.keys {
            var неполный = питон; неполный.removeValue(forKey: ключ)
            try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": неполный])
            отклонитьДоПитона(снимок.path)
        }
        var лишний = питон; лишний["лишнее"] = true
        try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": лишний]); отклонитьДоПитона(снимок.path)
        let неверные: [(String, Any)] = [("путь", true), ("реализация", NSNull()),
                                        ("версия", 13), ("sha256", [String]()), ("возможности", [true])]
        for (ключ, значение) in неверные {
            var неверный = питон; неверный[ключ] = значение
            try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": неверный])
            отклонитьДоПитона(снимок.path)
        }
    }
    func test_ПовреждённаяПоставкаНеОбходитсяСнимком() throws {
        for данные in [Data(), Data([0xff]), Data("{".utf8), try упаковать(["схема": "иная"])] {
            try данные.write(to: поставка); отклонитьДоПитона(снимок.path)
        }
        try FileManager.default.removeItem(at: поставка)
        try FileManager.default.createSymbolicLink(at: поставка, withDestinationURL: снимок)
        отклонитьДоПитона(снимок.path)
        try FileManager.default.removeItem(at: поставка)
        try FileManager.default.createDirectory(at: поставка, withIntermediateDirectories: false)
        отклонитьДоПитона(снимок.path)
    }
    func test_БинарникРесурсИТаблицыДолжныСовпадать() throws {
        let бинарник = try Data(contentsOf: программа), наблюдатель = try Data(contentsOf: ресурс)
        try Data("другие байты".utf8).write(to: программа); отклонитьДоПитона()
        try бинарник.write(to: программа); XCTAssertEqual(chmod(программа.path, 0o700), 0)
        try Data("# другой ресурс".utf8).write(to: ресурс); отклонитьДоПитона()
        try наблюдатель.write(to: ресурс)
        for ключ in ["sha256", "размер", "права"] {
            try сохранитьПоставку { тело in
                var файлы = тело["файлы"] as! [String: [String: Any]]
                файлы["машина"]![ключ] = ключ == "sha256" ? String(repeating: "0", count: 64) as Any : true
                тело["файлы"] = файлы
            }
            отклонитьДоПитона()
        }
        // Значение true не становится допустимым размером даже при фактическом одном байте.
        try Data([65]).write(to: программа); XCTAssertEqual(chmod(программа.path, 0o700), 0)
        try сохранитьПоставку(); _ = try прочитать()
        try сохранитьПоставку { тело in
            var файлы = тело["файлы"] as! [String: [String: Any]]
            файлы["машина"]!["размер"] = true; тело["файлы"] = файлы
        }
        отклонитьДоПитона()
        try бинарник.write(to: программа); XCTAssertEqual(chmod(программа.path, 0o700), 0)
        try сохранитьПоставку { тело in
            var файлы = тело["файлы"] as! [String: [String: Any]]
            let имя = String(self.ресурс.path.dropFirst(self.корень.path.count + 1))
            файлы[имя]!["sha256"] = String(repeating: "0", count: 64)
            тело["файлы"] = файлы
        }
        отклонитьДоПитона()
        try сохранитьПоставку { тело in
            var вход = тело["вход"] as! [String: Any]
            var исходники = вход["исходники"] as! [String: [String: Any]]
            исходники[self.имяИсходника]!["sha256"] = String(repeating: "0", count: 64)
            вход["исходники"] = исходники
            тело["вход"] = вход
        }
        отклонитьДоПитона()
        try сохранитьПоставку()
        let прежний = ресурс!
        ресурс = корень.appendingPathComponent("посторонний.py"); try наблюдатель.write(to: ресурс)
        try сохранитьПоставку()
        отклонитьДоПитона(); ресурс = прежний
    }
    func test_ГраницыЧтенияИСсылки() throws {
        try Data(repeating: 65, count: 256 * 1024).write(to: ресурс); try сохранитьПоставку()
        XCTAssertEqual(try прочитать().наблюдатель.count, 256 * 1024)
        try Data(repeating: 65, count: 256 * 1024 + 1).write(to: ресурс); try сохранитьПоставку()
        отклонитьДоПитона()
        try подготовитьПакет(вложенный: false)
        let цель = корень.appendingPathComponent("копия.py")
        try FileManager.default.moveItem(at: ресурс, to: цель)
        try FileManager.default.createSymbolicLink(at: ресурс, withDestinationURL: цель)
        отклонитьДоПитона()
        try FileManager.default.removeItem(at: ресурс); try FileManager.default.moveItem(at: цель, to: ресурс)
        let тело = try упаковать(телоПоставки())
        var полный = тело + Data(repeating: 32, count: 4 * 1024 * 1024 - тело.count)
        try полный.write(to: поставка); _ = try прочитать()
        полный.append(32); try полный.write(to: поставка); отклонитьДоПитона(снимок.path)
        try FileManager.default.removeItem(at: поставка)
        let оболочка = try упаковать(["схема": "fum.python-наблюдателя.1", "python": питон])
        полный = оболочка + Data(repeating: 32, count: 64 * 1024 - оболочка.count)
        try полный.write(to: снимок); _ = try прочитать(снимок.path)
        полный.append(32); try полный.write(to: снимок); отклонитьДоПитона(снимок.path)
        try FileManager.default.removeItem(at: снимок)
        try оболочка.write(to: цель)
        try FileManager.default.createSymbolicLink(at: снимок, withDestinationURL: цель)
        отклонитьДоПитона(снимок.path)
    }
    func test_ГраницаПроверяющегоСохраняетИсходИБайты() throws {
        enum Отказ: Error { case изменился }
        var вызовов = 0
        let до = try Data(contentsOf: поставка)
        XCTAssertThrowsError(try прочитать { данные in
            вызовов += 1; try self.проверитьПитон(данные); throw Отказ.изменился
        }) { ошибка in
            guard case Отказ.изменился = ошибка else { return XCTFail("Подменён исход проверки Python") }
        }
        XCTAssertEqual(вызовов, 1); XCTAssertEqual(try Data(contentsOf: поставка), до)
        let принятый = try прочитать()
        var переданныеБайты: Data?
        let после = try прочитать { данные in
            переданныеБайты = данные; try self.проверитьПитон(данные)
            try Data("изменено самой открытой фикстурой".utf8).write(to: self.поставка)
            try Data("# ресурс изменён самой фикстурой\n".utf8).write(to: self.ресурс)
        }
        XCTAssertEqual(после.питон, переданныеБайты)
        XCTAssertEqual(после.питон, принятый.питон)
        XCTAssertEqual(после.наблюдатель, принятый.наблюдатель)
        XCTAssertEqual(после.происхождение, принятый.происхождение)
    }
    func test_ПроисхождениеСвязываетВсеТриИсточника() throws {
        for разработка in [false, true] {
            try Data("исходные открытые байты бинарника".utf8).write(to: программа)
            XCTAssertEqual(chmod(программа.path, 0o700), 0); try подготовитьПакет(вложенный: false)
            try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": питон])
            if разработка { try FileManager.default.removeItem(at: поставка) }
            let явный = разработка ? снимок.path : nil
            var результаты = [try прочитать(явный).происхождение]
            try Data("новые открытые байты бинарника".utf8).write(to: программа)
            XCTAssertEqual(chmod(программа.path, 0o700), 0)
            if !разработка { try сохранитьПоставку() }
            результаты.append(try прочитать(явный).происхождение)
            try Data("# новые открытые байты наблюдателя\n".utf8).write(to: ресурс)
            if !разработка { try сохранитьПоставку() }
            результаты.append(try прочитать(явный).происхождение)
            var другой = питон; другой["sha256"] = String(repeating: "c", count: 64)
            if разработка {
                try записатьСнимок(["схема": "fum.python-наблюдателя.1", "python": другой])
            } else {
                try сохранитьПоставку { тело in
                    var вход = тело["вход"] as! [String: Any]; вход["python"] = другой; тело["вход"] = вход
                }
            }
            результаты.append(try прочитать(явный, проверяющий: { данные in
                XCTAssertEqual(try JSONSerialization.jsonObject(with: данные) as? NSDictionary, другой as NSDictionary)
            }).происхождение)
            XCTAssertEqual(Set(результаты).count, 4)
        }
    }
    func test_ТриОдинаковыхЧтения() throws {
        var интервалы: [UInt64] = [], результаты: [String] = []
        let до = try Data(contentsOf: поставка)
        for _ in 0..<3 {
            let начало = DispatchTime.now().uptimeNanoseconds
            let ответ = try прочитать()
            интервалы.append(DispatchTime.now().uptimeNanoseconds - начало)
            результаты.append(ответ.происхождение)
        }
        XCTAssertEqual(Set(результаты).count, 1); XCTAssertEqual(try Data(contentsOf: поставка), до)
        let медиана = интервалы.sorted()[1]; XCTAssertLessThan(медиана, 100_000_000)
        let профиль: [String: Any] = ["схема": "fum.профиль-выбора-наблюдателя.1", "интервалы_нс": интервалы,
            "медиана_нс": медиана, "предкритерий_нс": 100_000_000, "вход_sha256": хэш(до),
            "граница": "Открытые малые файлы поставки и подставная проверка Python; процессы не запускаются."]
        print("ПРОФИЛЬ_ИСТОЧНИКА=" + String(decoding: try упаковать(профиль), as: UTF8.self))
    }
}
