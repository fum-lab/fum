import Foundation
import XCTest
@testable import ЯдроМашины

final class ПроверкиПлана: XCTestCase {
    let хорошие = Ресурсы(архитектура: "arm64", виртуализация: true, процессоры: 10,
                         памятьБайт: 64 << 30, свободноБайт: 100 << 30)
    func test_НедостатокРесурсовИЧужойХост() {
        var плохие = хорошие
        плохие.архитектура = "x86_64"
        XCTAssertThrowsError(try плохие.проверить(Профиль()))
        плохие = хорошие; плохие.виртуализация = false
        XCTAssertThrowsError(try плохие.проверить(Профиль()))
        плохие = хорошие; плохие.памятьБайт = 8 << 30
        XCTAssertThrowsError(try плохие.проверить(Профиль()))
        плохие = хорошие; плохие.процессоры = 4
        XCTAssertThrowsError(try плохие.проверить(Профиль()))
        плохие = хорошие; плохие.свободноБайт = 31 << 30
        XCTAssertThrowsError(try плохие.проверить(Профиль()))
    }
    func test_ПланДетерминированИНеСоздаётКаталог() throws {
        let цель = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let первый = try ПланМашины.создать(профиль: Профиль(), каталог: цель, ресурсы: хорошие)
        XCTAssertEqual(первый, try ПланМашины.создать(профиль: Профиль(), каталог: цель, ресурсы: хорошие))
        XCTAssertEqual(первый.отпечаток.count, 64)
        XCTAssertFalse(FileManager.default.fileExists(atPath: цель))
    }
    func test_ИзменениеПланаОтклоняется() throws {
        var план = try ПланМашины.создать(профиль: Профиль(), каталог: "/private/tmp/машина", ресурсы: хорошие)
        план.профиль.дискГиБ = 64
        XCTAssertThrowsError(try план.проверить())
        план = try ПланМашины.создать(профиль: Профиль(), каталог: "/private/tmp/машина", ресурсы: хорошие)
        план.каталог += "-чужая"
        XCTAssertThrowsError(try план.проверить())
    }
    func test_ПересчитанныйХэшНеРазрешаетНедопустимыйПуть() throws {
        for путь in ["относительный", "/", "/private/tmp/../машина", "/private/tmp/\0"] {
            var план = try ПланМашины.создать(профиль: Профиль(), каталог: "/private/tmp/машина", ресурсы: хорошие)
            план.каталог = путь; план.отпечаток = ""
            план.отпечаток = хэш(try кодировать(план))
            XCTAssertThrowsError(try план.проверить())
        }
    }
}
