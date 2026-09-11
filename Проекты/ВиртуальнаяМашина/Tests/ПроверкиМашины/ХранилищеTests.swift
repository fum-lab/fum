import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиХранилища: XCTestCase {
    var родитель: URL!
    override func setUpWithError() throws {
        let физический = realpath(FileManager.default.temporaryDirectory.path, nil)!
        defer { free(физический) }
        родитель = URL(fileURLWithPath: String(cString: физический)).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: родитель, withIntermediateDirectories: false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: родитель) }
    func план(_ имя: String = "Машина с ё и пробелом") throws -> ПланМашины {
        try ПланМашины.создать(профиль: Профиль(), каталог: родитель.appendingPathComponent(имя).path,
                              ресурсы: Ресурсы(архитектура: "arm64", виртуализация: true, процессоры: 10,
                                               памятьБайт: 64 << 30, свободноБайт: 100 << 30))
    }
    func test_НеизвестныйКаталогНеПрисваивается() throws {
        let план = try план()
        try FileManager.default.createDirectory(atPath: план.каталог, withIntermediateDirectories: false)
        XCTAssertThrowsError(try Хранилище(план: план, создать: true))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: план.каталог), [])
    }
    func test_СимволическаяСсылкаНеПринимается() throws {
        let план = try план()
        try FileManager.default.createSymbolicLink(atPath: план.каталог, withDestinationPath: родитель.path)
        XCTAssertThrowsError(try Хранилище(план: план, создать: true))
    }
    func test_ОдинПисательИПовторПослеОсвобождения() throws {
        let план = try план()
        var первое: Хранилище? = try Хранилище(план: план, создать: true)
        try первое!.записать("данные", байты: Data("сохранённый результат".utf8))
        XCTAssertThrowsError(try Хранилище(план: план, создать: false))
        первое = nil
        let второе = try Хранилище(план: план, создать: false)
        XCTAssertEqual(try второе.прочитать("данные"), Data("сохранённый результат".utf8))
    }
    func test_ИзменённыйПрофильНеПерезаписываетМашину() throws {
        let исходный = try план()
        var первое: Хранилище? = try Хранилище(план: исходный, создать: true)
        try первое!.записать("диск", байты: Data([1,2,3])); первое = nil
        var профиль = Профиль(); профиль.памятьГиБ = 16
        let новый = try ПланМашины.создать(профиль: профиль, каталог: исходный.каталог,
            ресурсы: Ресурсы(архитектура: "arm64", виртуализация: true, процессоры: 10, памятьБайт: 64 << 30, свободноБайт: 100 << 30))
        XCTAssertThrowsError(try Хранилище(план: новый, создать: true))
    }
    func test_ВыходИзКаталогаИЖёсткаяСсылкаОтклоняются() throws {
        let план = try план()
        let хранилище = try Хранилище(план: план, создать: true)
        XCTAssertThrowsError(try хранилище.записать("../чужое", байты: Data([1])))
        try хранилище.записать("данные", байты: Data([1]))
        // Подмена артефакта моделируется только внутри собственного временного каталога теста.
        if FileManager.default.fileExists(atPath: план.каталог + "/данные") {
            try FileManager.default.linkItem(atPath: план.каталог + "/данные", toPath: план.каталог + "/ссылка")
            XCTAssertThrowsError(try хранилище.прочитать("ссылка"))
        }
    }
    func test_ПостоянныйЗамокНельзяЗаменить() throws {
        let исходный = try план()
        let хранилище = try Хранилище(план: исходный, создать: true)
        XCTAssertThrowsError(try хранилище.записать("замок", байты: Data()))
        XCTAssertThrowsError(try хранилище.записать("паспорт.json", байты: Data()))
        XCTAssertThrowsError(try Хранилище(план: исходный, создать: false))
    }
    func test_РазмерМетаданныхОграничен() throws {
        let исходный = try план()
        let хранилище = try Хранилище(план: исходный, создать: true)
        try хранилище.записать("большой-файл", байты: Data(repeating: 0, count: 4 * 1024 * 1024 + 1))
        XCTAssertThrowsError(try хранилище.прочитать("большой-файл"))
    }
    func test_ИменованныйКаналОтклоняетсяБезОжидания() throws {
        let исходный = try план()
        let хранилище = try Хранилище(план: исходный, создать: true)
        XCTAssertEqual(mkfifo(исходный.каталог + "/канал", 0o600), 0)
        XCTAssertThrowsError(try хранилище.прочитать("канал"))
    }
    func test_ПустоеИЧужоеСвидетельствоПодписиНеПринимается() throws {
        let хранилище = try Хранилище(план: план(), создать: true)
        let подготовка = ПодготовкаУбунту(хранилище)
        XCTAssertFalse(try подготовка.подписьПодтверждена())
        try хранилище.записать("подпись-проверена.json", байты: Data("{}".utf8))
        XCTAssertFalse(try подготовка.подписьПодтверждена())
        try хранилище.записать("подпись-проверена.json", байты: кодировать(["план": "чужой", "образ": хранилище.паспорт.план.хэшОбраза]))
        XCTAssertFalse(try подготовка.подписьПодтверждена())
    }
    func test_УправляющийСимволВПутиОтклоняется() {
        XCTAssertThrowsError(try план("машина\nHost чужой"))
    }
    func test_ЧтениеНеОсвобождаетЗамокРаботающейМашины() throws {
        let план = try план()
        let писатель = try Хранилище(план: план, создать: true)
        try писатель.записать("состояние.json", байты: Data("жив".utf8))
        let читатель = try ЧтениеХранилища(план.каталог)
        XCTAssertEqual(try читатель.прочитать("состояние.json"), Data("жив".utf8))
        XCTAssertEqual(читатель.паспорт.идентификатор, писатель.паспорт.идентификатор)
        XCTAssertThrowsError(try Хранилище(план: план, создать: false))
    }
}
