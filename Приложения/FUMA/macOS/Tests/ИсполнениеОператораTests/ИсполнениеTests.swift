import XCTest
import Foundation
import Darwin
import FUMStructuringOperatorMemory
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

final class ПроверкиИсполнения: XCTestCase {
    func сКаталогом(_ действие: (URL, [String]) throws -> Void) throws {
        let временный = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let физический = try XCTUnwrap(realpath(временный.path, nil))
        defer { free(физический) }
        let каталог = URL(fileURLWithPath: String(cString: физический))
        defer { try? FileManager.default.removeItem(at: каталог) }
        let определение = каталог.appendingPathComponent("определение.json")
        let вход = каталог.appendingPathComponent("вход.txt")
        try РесурсыОпределений.прочитать("нормализация").write(to: определение)
        try Data("  ПРИВЕТ\n  ЁЖ  ".utf8).write(to: вход)
        let аргументы = ["--выполнить-оператор", "--определение", определение.path,
            "--вход", вход.path, "--тип-входа", "текст", "--журнал", каталог.path]
        try действие(каталог, аргументы)
    }

    func объект(_ данные: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
    }

    func testНакоплениеИПовторИзПринятыхДанных() throws {
        try сКаталогом { каталог, аргументы in
            let первый = try объект(КомандноеИсполнениеОператора.выполнить(аргументы: аргументы))
            let квитанция = try XCTUnwrap(первый["квитанция"] as? [String: Any])
            let описание = try XCTUnwrap(квитанция["описание"] as? [String: Any])
            let идентификатор = try XCTUnwrap(описание["идентификатор"] as? String)
            let наблюдение = try XCTUnwrap(первый["наблюдение"] as? [String: Any])
            let результат = try XCTUnwrap(наблюдение["результат"] as? [String: Any])
            XCTAssertEqual(результат["значение"] as? String, "привет ёж")
            try FileManager.default.removeItem(at: каталог.appendingPathComponent("вход.txt"))
            try FileManager.default.removeItem(at: каталог.appendingPathComponent("определение.json"))
            let второй = try объект(КомандноеИсполнениеОператора.выполнить(аргументы:
                ["--повторить-оператор", идентификатор, "--журнал", каталог.path]))
            let повтор = try XCTUnwrap(второй["наблюдение"] as? [String: Any])
            XCTAssertEqual(наблюдение["хэшНаблюдения"] as? String, повтор["хэшНаблюдения"] as? String)
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            let исполнения = сегмент.записи.filter { $0.описание.тип == "исполнение-оператора" }
            XCTAssertEqual(исполнения.count, 2)
            XCTAssertNotEqual(исполнения[0].описание.идентификатор, исполнения[1].описание.идентификатор)
            XCTAssertEqual(try сегмент.извлечь(идентификатор),
                try сегмент.извлечь(исполнения[1].описание.идентификатор))
            let сырые = сегмент.записи.filter { $0.описание.тип.hasPrefix("сырые-байты/") }
            XCTAssertEqual(сырые.count, 4)
            for запись in сырые.suffix(2) {
                let сведения = try объект(запись.описание.спецификация)
                XCTAssertEqual(сведения["приём"] as? String, исполнения[1].описание.идентификатор)
                XCTAssertEqual(сведения["повторЗаписи"] as? String, идентификатор)
            }
        }
    }

    func testНеизвестныйОператорСохраняетИсходникиБезИсполнения() throws {
        try сКаталогом { каталог, аргументы in
            let файл = каталог.appendingPathComponent("определение.json")
            let текст = try String(contentsOf: файл, encoding: .utf8)
            try текст.replacingOccurrences(of: "нижний-регистр", with: "несуществующий").write(
                to: файл, atomically: true, encoding: .utf8)
            XCTAssertThrowsError(try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы)) {
                XCTAssertTrue($0 is ОшибкаИсполнения)
            }
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            XCTAssertEqual(сегмент.записи.map(\.описание.тип), ["сырые-байты/вход-оператора", "сырые-байты/определение-оператора"])
            XCTAssertEqual(try сегмент.извлечь(сегмент.записи[1].описание.идентификатор), try Data(contentsOf: файл))
        }
    }

    func testОтказЗаписиСохраняетПрежнийПрефикс() throws {
        try сКаталогом { каталог, аргументы in
            _ = try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы)
            let файл = каталог.appendingPathComponent("сегмент.fumobs")
            let прежде = try Data(contentsOf: файл)
            let операции = ФайловыеОперации(запись: { _, _ in throw ОшибкаКонтейнера.система(ENOSPC) },
                синхронизация: ФайловыеОперации.системные.синхронизация)
            XCTAssertThrowsError(try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы, операции: операции))
            XCTAssertEqual(try Data(contentsOf: файл), прежде)
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            XCTAssertEqual(сегмент.записи.filter { $0.описание.тип == "исполнение-оператора" }.count, 1)
        }
    }

    func testОтказСинхронизацииНеВыдаётКвитанциюИНеЗатираетИсторию() throws {
        try сКаталогом { каталог, аргументы in
            _ = try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы)
            let файл = каталог.appendingPathComponent("сегмент.fumobs")
            let прежде = try Data(contentsOf: файл)
            let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
                синхронизация: { _ in throw ОшибкаКонтейнера.система(EIO) })
            XCTAssertThrowsError(try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы, операции: операции))
            XCTAssertEqual(try Data(contentsOf: файл).prefix(прежде.count), прежде)
        }
    }
}
