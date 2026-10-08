import XCTest
import Foundation
import Darwin
import КонтейнерНаблюдений
@testable import НаблюдениеДоступности

final class ТестыНаблюдения: XCTestCase {
    func test_ПрофильОтклоняетОтсутствующийКомпиляторДоНаблюдения() throws {
        try проверитьВыбор(ожидаемаяОшибка: "компиляторОтсутствует") { корень in
            ["PATH": корень.path]
        }
    }

    func test_ПрофильОтклоняетДваРазныхКомпилятора() throws {
        try проверитьВыбор(ожидаемаяОшибка: "компиляторНеоднозначен") { корень in
            let первый = try создатьКомпилятор(корень: корень, имя: "первый")
            let второй = try создатьКомпилятор(корень: корень, имя: "второй")
            return ["PATH": первый.deletingLastPathComponent().path + ":" + второй.deletingLastPathComponent().path]
        }
    }

    func test_НеверноеЯвноеНазначениеНеПереходитКПоиску() throws {
        for назначение in ["", "относительный", "отсутствующий", "каталог", "неисполняемый"] {
            try проверитьВыбор(ожидаемаяОшибка: "неверноеНазначениеКомпилятора") { корень in
                let рабочий = try создатьКомпилятор(корень: корень, имя: "рабочий")
                let вход = корень.appendingPathComponent(назначение)
                if назначение == "каталог" { try FileManager.default.createDirectory(at: вход, withIntermediateDirectories: false) }
                if назначение == "неисполняемый" { try Data().write(to: вход); try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: вход.path) }
                return ["PATH": рабочий.deletingLastPathComponent().path,
                    "ФУМ_КОМПИЛЯТОР": ["отсутствующий", "каталог", "неисполняемый"].contains(назначение) ? вход.path : назначение]
            }
        }
    }

    func test_КомпонентыПоискаПроверяютсяПослеПервогоКандидата() throws {
        let домашнееСокращение = String(UnicodeScalar(0x007E))
        for хвост in ["", "относительный", домашнееСокращение] {
            try проверитьВыбор(ожидаемаяОшибка: "неверныйПутьПоиска") { корень in
                let рабочий = try создатьКомпилятор(корень: корень, имя: "рабочий")
                return ["PATH": рабочий.deletingLastPathComponent().path + ":" + хвост]
            }
        }
    }

    func test_ВерсияКомпилятораТребуетУспехаИТекста() throws {
        for (текст, код) in [("", 0), ("Swift version fixture", 3), ("посторонняя программа", 0)] {
            try проверитьВыбор(ожидаемаяОшибка: "невернаяВерсияКомпилятора") { корень in
                let файл = try создатьКомпилятор(корень: корень, имя: "отказ", текст: текст, код: код)
                return ["ФУМ_КОМПИЛЯТОР": файл.path]
            }
        }
    }

    func test_ДваПутиКОдномуКомпиляторуДаютОдноНазначение() throws {
        try проверитьВыбор(метод: "PATH") { корень in
            let файл = try создатьКомпилятор(корень: корень, имя: "первый")
            let второй = корень.appendingPathComponent("второй", isDirectory: true)
            try FileManager.default.createDirectory(at: второй, withIntermediateDirectories: false)
            try FileManager.default.createSymbolicLink(at: второй.appendingPathComponent("swift"), withDestinationURL: файл)
            return ["PATH": файл.deletingLastPathComponent().path + ":" + второй.path]
        }
    }

    func test_ЯвноеНазначениеНастоящегоКомпилятораНеЗависитОтПоиска() throws {
        try проверитьВыбор(метод: "ФУМ_КОМПИЛЯТОР") { _ in
            ["ФУМ_КОМПИЛЯТОР": try обязательнаяСреда("ФУМ_КОМПИЛЯТОР"), "PATH": "непроверяемый-при-явном-назначении"]
        }
    }

    private func обязательнаяСреда(_ имя: String) throws -> String {
        try XCTUnwrap(ProcessInfo.processInfo.environment[имя].flatMap { $0.hasPrefix("/") ? $0 : nil },
            "Тест требует объявленный проверенный вход \(имя)")
    }

    private func создатьКомпилятор(корень: URL, имя: String, текст: String = "Swift version fixture", код: Int = 0) throws -> URL {
        let каталог = корень.appendingPathComponent(имя, isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        let файл = каталог.appendingPathComponent("swift")
        let оболочка = try обязательнаяСреда("SHELL")
        try Data(("#!" + оболочка + "\nprintf '%s\\n' '" + текст + "'\nexit " + String(код) + "\n").utf8).write(to: файл)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: файл.path)
        return файл
    }

    private func проверитьВыбор(ожидаемаяОшибка: String? = nil, метод: String? = nil,
        среда: (URL) throws -> [String: String]) throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let данные = корень.appendingPathComponent("данные", isDirectory: true)
        try FileManager.default.createDirectory(at: данные, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let выход = корень.appendingPathComponent("профиль.json")
        let поток = корень.appendingPathComponent("поток")
        XCTAssertTrue(FileManager.default.createFile(atPath: поток.path, contents: nil, attributes: [.posixPermissions: 0o600]))
        let канал = try FileHandle(forWritingTo: поток)
        defer { try? канал.close() }
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: try обязательнаяСреда("ФУМ_КОМАНДА_ДОСТУПНОСТИ"))
        процесс.arguments = ["профиль", "--каталог", данные.path, "--повторов", "1", "--выход", выход.path,
            "--корень-исходников", try обязательнаяСреда("ФУМ_ИСХОДНИКИ_ДОСТУПНОСТИ")]
        var окружение = ProcessInfo.processInfo.environment
        окружение.removeValue(forKey: "ФУМ_КОМПИЛЯТОР")
        окружение.merge(try среда(корень)) { _, новое in новое }
        процесс.environment = окружение
        процесс.standardOutput = канал
        процесс.standardError = канал
        try процесс.run()
        let предел = DispatchTime.now().uptimeNanoseconds + 15_000_000_000
        while процесс.isRunning && DispatchTime.now().uptimeNanoseconds < предел { Thread.sleep(forTimeInterval: 0.01) }
        if процесс.isRunning { kill(процесс.processIdentifier, SIGKILL); XCTFail("CLI превысила предел теста") }
        процесс.waitUntilExit()
        if let ошибка = ожидаемаяОшибка {
            XCTAssertEqual(процесс.terminationStatus, 2)
            XCTAssertTrue(try String(contentsOf: поток, encoding: .utf8).contains(ошибка))
            XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: данные.path).isEmpty)
            XCTAssertFalse(FileManager.default.fileExists(atPath: выход.path))
        } else {
            let сообщение = try String(contentsOf: поток, encoding: .utf8)
            XCTAssertEqual(процесс.terminationStatus, 0, сообщение)
            let профиль = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: выход)) as? [String: Any])
            XCTAssertEqual(профиль["выбор_компилятора"] as? String, метод)
            if метод == "PATH" { XCTAssertEqual(профиль["компилятор"] as? String, "Swift version fixture") }
            let этапы = try XCTUnwrap(профиль["этапы"] as? [String: [String: Any]])
            XCTAssertEqual(этапы["выбор-компилятора"]?["число"] as? Int, 1)
            XCTAssertEqual(этапы["версия-компилятора"]?["число"] as? Int, 1)
        }
    }

    func test_ПовторПоПопыткеСохраняетПервичноеПроисхождение() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let попытка = UUID()
        let первый = try Сегмент(кореньДанных: корень, запись: true)
        var вызовы = 0
        let состояние = try НаблюдательДоступности(сегмент: первый, вызов: { вызовы += 1; return true })
            .наблюдать(попытка: попытка, оператор: "оператор", версияГрафа: "граф-1")
        guard case .ответ = состояние else { первый.закрыть(); return XCTFail("Первый вход должен сохранить ответ") }
        первый.закрыть()
        let второй = try Сегмент(кореньДанных: корень, запись: true, создать: false)
        defer { второй.закрыть() }
        let повтор = НаблюдательДоступности(сегмент: второй) { XCTFail("Повтор другого процесса не вызывает API"); return false }
        XCTAssertEqual(try повтор.наблюдать(попытка: попытка, оператор: "оператор", версияГрафа: "граф-1"), состояние)
        XCTAssertThrowsError(try повтор.наблюдать(попытка: попытка, оператор: "другой", версияГрафа: "граф-1"))
        XCTAssertThrowsError(try повтор.наблюдать(попытка: попытка, оператор: "оператор", версияГрафа: "граф-2"))
        XCTAssertEqual(вызовы, 1)
    }

    func test_ОбаОтветаСохраняютсяПослеНамерения() throws {
        for доверен in [false, true] {
            let корень = try временныйКорень()
            defer { try? FileManager.default.removeItem(at: корень) }
            let намерение = примерНамерения()
            var вызовы = 0
            let сегмент = try Сегмент(кореньДанных: корень, запись: true)
            let наблюдатель = НаблюдательДоступности(сегмент: сегмент) {
                вызовы += 1
                XCTAssertEqual(сегмент.записи.map(\.описание.идентификатор), [намерение.идентификаторНамерения])
                return доверен
            }
            let состояние = try наблюдатель.наблюдать(намерение)
            guard case let .ответ(ответ, основание) = состояние else {
                XCTFail("После API и двух подтверждений нужен ответ"); сегмент.закрыть(); continue
            }
            XCTAssertEqual(ответ.доверен, доверен)
            XCTAssertEqual(ответ.намерение, намерение)
            XCTAssertEqual(основание, .новаяФиксация)
            XCTAssertEqual(вызовы, 1)
            XCTAssertEqual(сегмент.записи.count, 2)
            XCTAssertEqual(наблюдатель.профиль.map(\.этап), ["запись-намерения", "системный-вызов", "запись-ответа"])
            сегмент.закрыть()
        }
    }

    func test_ПовторПодтверждаетПрежнийОтветБезСистемногоВызова() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let сегмент = try Сегмент(кореньДанных: корень, запись: true)
        defer { сегмент.закрыть() }
        var вызовы = 0
        let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { вызовы += 1; return вызовы == 1 }
        let намерение = примерНамерения()
        let первый = try наблюдатель.наблюдать(намерение)
        let повтор = try наблюдатель.наблюдать(намерение)
        XCTAssertEqual(повтор, первый)
        XCTAssertEqual(вызовы, 1)
        XCTAssertEqual(сегмент.записи.count, 2)
    }

    func test_ОтказНамеренияЗапрещаетСистемныйВызов() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let исходный = try Сегмент(кореньДанных: корень, запись: true)
        исходный.закрыть()
        let отказ = ПереключательОтказа()
        отказ.включить()
        let операции = ФайловыеОперации(запись: { дескриптор, байты in
            if отказ.активен { throw ОшибкаКонтейнера.система(EIO) }
            return try ФайловыеОперации.системные.запись(дескриптор, байты)
        }, синхронизация: ФайловыеОперации.системные.синхронизация)
        let сегмент = try Сегмент(кореньДанных: корень, запись: true, создать: false, операции: операции)
        defer { сегмент.закрыть() }
        var вызовы = 0
        let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { вызовы += 1; return false }
        XCTAssertThrowsError(try наблюдатель.наблюдать(примерНамерения()))
        XCTAssertEqual(вызовы, 0)
        XCTAssertEqual(наблюдатель.профиль.last?.исход, "неуспешно")
    }

    func test_ОтказОтветаОставляетНеизвестностьБезПовторногоВызова() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let отказ = ПереключательОтказа()
        let операции = ФайловыеОперации(запись: { дескриптор, байты in
            if отказ.активен { throw ОшибкаКонтейнера.система(EIO) }
            return try ФайловыеОперации.системные.запись(дескриптор, байты)
        }, синхронизация: ФайловыеОперации.системные.синхронизация)
        let сегмент = try Сегмент(кореньДанных: корень, запись: true, операции: операции)
        let намерение = примерНамерения()
        var вызовы = 0
        let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { вызовы += 1; отказ.включить(); return false }
        XCTAssertThrowsError(try наблюдатель.наблюдать(намерение))
        XCTAssertEqual(вызовы, 1)
        XCTAssertThrowsError(try наблюдатель.наблюдать(намерение))
        XCTAssertEqual(вызовы, 1)
        сегмент.закрыть()
        XCTAssertEqual(try ВоспроизведениеДоступности.прочитать(кореньДанных: корень, попытка: намерение.идентификаторПопытки), .неизвестно(намерение))
        XCTAssertEqual(наблюдатель.профиль.last?.исход, "неуспешно")
    }

    func test_ОтказСинхронизацииНеВыдаётНовуюФиксацию() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let отказ = ПереключательОтказа()
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { дескриптор in
            if отказ.активен { throw ОшибкаКонтейнера.система(EIO) }
            try ФайловыеОперации.системные.синхронизация(дескриптор)
        })
        let намерение = примерНамерения()
        let сегмент = try Сегмент(кореньДанных: корень, запись: true, операции: операции)
        let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { отказ.включить(); return true }
        XCTAssertThrowsError(try наблюдатель.наблюдать(намерение))
        сегмент.закрыть()
        let байтыДо = try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs"))
        guard case let .ответ(ответ, основание) = try ВоспроизведениеДоступности.прочитать(кореньДанных: корень, попытка: намерение.идентификаторПопытки) else {
            return XCTFail("Полный видимый commit после отказа fsync остаётся историческим")
        }
        XCTAssertTrue(ответ.доверен)
        XCTAssertEqual(основание, .историческоеЧтение)
        XCTAssertEqual(try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs")), байтыДо)
    }

    func test_ОтказыСинхронизацииНамеренияИОтветаПослеНовогоОткрытия() throws {
        // 1/2 — файл/каталог намерения; 3/4 — файл/каталог ответа.
        for номер in 1...4 {
            let корень = try временныйКорень()
            defer { try? FileManager.default.removeItem(at: корень) }
            let пустой = try Сегмент(кореньДанных: корень, запись: true)
            пустой.закрыть()
            let счётчик = СчётчикСинхронизаций(отказ: номер)
            let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
                синхронизация: { try счётчик.синхронизировать($0) })
            let сегмент = try Сегмент(кореньДанных: корень, запись: true, создать: false, операции: операции)
            let намерение = примерНамерения()
            var вызовы = 0
            let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { вызовы += 1; return true }
            XCTAssertThrowsError(try наблюдатель.наблюдать(намерение))
            XCTAssertEqual(вызовы, номер <= 2 ? 0 : 1)
            XCTAssertEqual(счётчик.число, номер)
            сегмент.закрыть()
            let история = try ВоспроизведениеДоступности.прочитать(кореньДанных: корень, попытка: намерение.идентификаторПопытки)
            if номер <= 2 {
                XCTAssertEqual(история, .неизвестно(намерение))
                let новый = try Сегмент(кореньДанных: корень, запись: true, создать: false)
                let повтор = НаблюдательДоступности(сегмент: новый) { XCTFail("Неизвестную попытку нельзя повторить"); return false }
                XCTAssertEqual(try повтор.наблюдать(намерение), .неизвестно(намерение))
                новый.закрыть()
            } else {
                guard case .ответ(_, .историческоеЧтение) = история else { return XCTFail("Нужен только исторический ответ") }
            }
        }
    }

    func test_ПовторСинхронизируетОбеЗаписиИОтказНеВыдаётОтвет() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let пустой = try Сегмент(кореньДанных: корень, запись: true)
        пустой.закрыть()
        let счётчик = СчётчикСинхронизаций(отказ: 9)
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: { try счётчик.синхронизировать($0) })
        let сегмент = try Сегмент(кореньДанных: корень, запись: true, создать: false, операции: операции)
        let намерение = примерНамерения()
        var вызовы = 0
        let наблюдатель = НаблюдательДоступности(сегмент: сегмент) { вызовы += 1; return true }
        let первый = try наблюдатель.наблюдать(намерение)
        XCTAssertEqual(счётчик.число, 4)
        let файл = корень.appendingPathComponent("сегмент.fumobs"), до = try Data(contentsOf: файл)
        XCTAssertEqual(try наблюдатель.наблюдать(намерение), первый)
        XCTAssertEqual(счётчик.число, 8)
        XCTAssertThrowsError(try наблюдатель.наблюдать(намерение))
        XCTAssertEqual(счётчик.число, 9)
        XCTAssertEqual(вызовы, 1)
        сегмент.закрыть()
        XCTAssertEqual(try Data(contentsOf: файл), до)
        guard case .ответ(_, .историческоеЧтение) = try ВоспроизведениеДоступности.прочитать(кореньДанных: корень, попытка: намерение.идентификаторПопытки) else {
            return XCTFail("Отказ повторного fsync не меняет историческую пару")
        }
    }
}

func временныйКорень() throws -> URL {
    // Явный физический путь исключает символьные компоненты системного TMPDIR.
    let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    return корень
}

func примерНамерения(попытка: UUID = UUID(), время: String = "2026-10-03T13:32:00Z") -> НамерениеДоступности {
    НамерениеДоступности(попытка: попытка, оператор: "проверка-доступности", версияГрафа: "неподключён", время: время, процесс: 1)
}

final class ПереключательОтказа: @unchecked Sendable {
    private let замок = NSLock()
    private var значение = false
    var активен: Bool { замок.lock(); defer { замок.unlock() }; return значение }
    func включить() { замок.lock(); defer { замок.unlock() }; значение = true }
}

final class СчётчикСинхронизаций: @unchecked Sendable {
    private let замок = NSLock()
    private var значение = 0
    private let отказ: Int
    init(отказ: Int) { self.отказ = отказ }
    var число: Int { замок.lock(); defer { замок.unlock() }; return значение }
    func синхронизировать(_ дескриптор: Int32) throws {
        замок.lock(); значение += 1; let неуспешно = значение == отказ; замок.unlock()
        if неуспешно { throw ОшибкаКонтейнера.система(EIO) }
        try ФайловыеОперации.системные.синхронизация(дескриптор)
    }
}
