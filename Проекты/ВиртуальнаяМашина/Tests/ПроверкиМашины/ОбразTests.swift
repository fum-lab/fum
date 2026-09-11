import XCTest
@testable import ЯдроМашины

final class ПроверкиОбраза: XCTestCase {
    func test_ПодменаИДубликатТаблицыОтклоняются() throws {
        let план = try ПланМашины.создать(профиль: Профиль(), каталог: "/private/tmp/машина",
            ресурсы: Ресурсы(архитектура: "arm64", виртуализация: true, процессоры: 10, памятьБайт: 64 << 30, свободноБайт: 100 << 30))
        let строка = план.хэшОбраза + " *ubuntu-24.04-server-cloudimg-arm64.img\n"
        XCTAssertNoThrow(try ПроверкаОбраза.таблица(строка, план: план))
        XCTAssertThrowsError(try ПроверкаОбраза.таблица(строка + строка, план: план))
        XCTAssertThrowsError(try ПроверкаОбраза.таблица(строка.replacingOccurrences(of: план.хэшОбраза, with: String(repeating: "0", count: 64)), план: план))
        XCTAssertThrowsError(try ПроверкаОбраза.таблица("", план: план))
    }
    func test_ПодписьПроверяетсяПоМашинномуСтатусуИПолномуКлючу() {
        let ключ = "D2EB44626FDDC30B513D5BB71A5D6C4C7DB87C81"
        let строка = "[GNUPG:] VALIDSIG \(ключ) 2026-08-26 1780000000 0 4 0 1 8 00 \(ключ)\n"
        XCTAssertNoThrow(try ПроверкаОбраза.подпись(строка, код: 0, ключ: ключ))
        XCTAssertThrowsError(try ПроверкаОбраза.подпись("Good signature", код: 0, ключ: ключ))
        XCTAssertThrowsError(try ПроверкаОбраза.подпись(строка, код: 1, ключ: ключ))
        XCTAssertThrowsError(try ПроверкаОбраза.подпись(строка, код: 0, ключ: String(repeating: "0", count: 40)))
        XCTAssertThrowsError(try ПроверкаОбраза.подпись(строка + "[GNUPG:] BADSIG x\n", код: 0, ключ: ключ))
    }
    func test_ОтпечатокКлючаНеБерётсяИзПроизвольногоИдентификатораПользователя() {
        let ключ = "D2EB44626FDDC30B513D5BB71A5D6C4C7DB87C81"
        let строка = "pub:-:4096:1:x:0:::-:::sc::::::23::0:\nfpr:::::::::\(ключ):\n"
        XCTAssertNoThrow(try ПроверкаОбраза.ключ(строка, ожидаемый: ключ))
        XCTAssertThrowsError(try ПроверкаОбраза.ключ("uid:::::::::\(ключ):\n", ожидаемый: ключ))
        XCTAssertThrowsError(try ПроверкаОбраза.ключ(строка + строка, ожидаемый: ключ))
    }
    func test_РазмерОбразаНеМожетБытьБулевымДробнымИлиВнешним() throws {
        XCTAssertEqual(try виртуальныйРазмерОбраза(Data("{\"format\":\"qcow2\",\"virtual-size\":4294967296}".utf8), предел: 32 << 30), 4 << 30)
        for текст in ["{\"format\":\"qcow2\",\"virtual-size\":true}", "{\"format\":\"qcow2\",\"virtual-size\":1.5}", "{\"format\":\"qcow2\",\"virtual-size\":1024,\"backing-filename\":\"чужое\"}"] {
            XCTAssertThrowsError(try виртуальныйРазмерОбраза(Data(текст.utf8), предел: 32 << 30))
        }
    }
}
