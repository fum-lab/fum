import CryptoKit
import Foundation
import XCTest
@testable import ЛокальныйТоррент

enum ОракулМетаданных {
    static func шестнадцатеричный(_ данные: Data) -> String {
        данные.map { String(format: "%02x", $0) }.joined()
    }
    static func пример(имя: String = "a", содержимое: Data = Data("abc".utf8),
                       длина: Int = 16384) throws -> (СозданныеМетаданныеТоррента, Data) {
        var хэшиПервойВерсии = Data()
        for позиция in stride(from: 0, to: содержимое.count, by: длина) {
            хэшиПервойВерсии += Data(Insecure.SHA1.hash(data: содержимое[позиция..<min(позиция + длина, содержимое.count)]))
        }
        var листья = stride(from: 0, to: содержимое.count, by: 16384).map { позиция in
            Data(SHA256.hash(data: содержимое[позиция..<min(позиция + 16384, содержимое.count)]))
        }
        let нуль = Data(repeating: 0, count: 32)
        var числоЛистьев = 1
        while числоЛистьев < листья.count { числоЛистьев *= 2 }
        листья += Array(repeating: нуль, count: числоЛистьев - листья.count)
        var слой = Data()
        var уровень = листья
        var блоков = 1
        while уровень.count > 1 {
            if блоков == длина / 16384 { слой = уровень.prefix((содержимое.count - 1) / длина + 1).reduce(Data(), +) }
            уровень = stride(from: 0, to: уровень.count, by: 2).map { Data(SHA256.hash(data: уровень[$0] + уровень[$0 + 1])) }
            блоков *= 2
        }
        let корень = уровень[0]
        let имяБайт = Data(имя.utf8)
        var информация = Data("d9:file treed\(имяБайт.count):".utf8) + имяБайт
        информация += Data("d0:d6:lengthi\(содержимое.count)e11:pieces root32:".utf8) + корень
        информация += Data("eee6:lengthi\(содержимое.count)e12:meta versioni2e4:name\(имяБайт.count):".utf8) + имяБайт
        информация += Data("12:piece lengthi\(длина)e6:pieces\(хэшиПервойВерсии.count):".utf8) + хэшиПервойВерсии + Data("e".utf8)
        let данные = Data("d4:info".utf8) + информация + Data("12:piece layersd".utf8)
            + (слой.isEmpty ? Data() : Data("32:".utf8) + корень + Data("\(слой.count):".utf8) + слой) + Data("ee".utf8)
        return (try СозданныеМетаданныеТоррента(бенкодированныеДанные: данные,
            хэшиИнформации: ХэшиИнформацииТоррента(
                хэшВерсии1: шестнадцатеричный(Data(Insecure.SHA1.hash(data: информация))),
                хэшВерсии2: шестнадцатеричный(Data(SHA256.hash(data: информация))))), информация)
    }
}

final class ПроверкаМетаданныхТесты: XCTestCase {
    func сИнформацией(_ информация: Data) throws -> СозданныеМетаданныеТоррента {
        try СозданныеМетаданныеТоррента(бенкодированныеДанные: Data("d4:info".utf8) + информация + Data("12:piece layersdee".utf8),
            хэшиИнформации: ХэшиИнформацииТоррента(
                хэшВерсии1: ОракулМетаданных.шестнадцатеричный(Data(Insecure.SHA1.hash(data: информация))),
                хэшВерсии2: ОракулМетаданных.шестнадцатеричный(Data(SHA256.hash(data: информация)))))
    }
    func test_НеПринимаетСимволическуюСсылкуПервойВерсииИНулевойКорень() throws {
        let (_, информация) = try ОракулМетаданных.пример()
        let ссылка = Data("d4:attr1:l".utf8) + информация.dropFirst()
        XCTAssertThrowsError(try проверить(сИнформацией(ссылка)))
        var нулевойКорень = информация
        let начало = try XCTUnwrap(нулевойКорень.range(of: Data("11:pieces root32:".utf8))).upperBound
        нулевойКорень.replaceSubrange(начало..<(начало + 32), with: Data(repeating: 0, count: 32))
        XCTAssertThrowsError(try проверить(сИнформацией(нулевойКорень)))
    }
    func проверить(_ метаданные: СозданныеМетаданныеТоррента, размер: UInt64 = 3,
                   длина: Int = 16384, максимум: UInt64 = 1048576) throws {
        try ПроверкаМетаданныхТоррента.проверить(метаданные, имя: "a", размер: размер,
            ограничения: ОграниченияПодготовкиТоррента(максимумБайтФайла: 1048576,
                длинаЧастиБайт: длина, максимумБайтМетаданных: максимум))
    }
    func замена(_ метаданные: СозданныеМетаданныеТоррента, _ данные: Data) throws -> СозданныеМетаданныеТоррента {
        try СозданныеМетаданныеТоррента(бенкодированныеДанные: данные, хэшиИнформации: метаданные.хэшиИнформации)
    }
    func test_ТочныйБуквальныйГибридныйОракул() throws {
        let (метаданные, информация) = try ОракулМетаданных.пример()
        let хэшПервойВерсии = Data([0xa9,0x99,0x3e,0x36,0x47,0x06,0x81,0x6a,0xba,0x3e,0x25,0x71,0x78,0x50,0xc2,0x6c,0x9c,0xd0,0xd8,0x9d])
        let корень = Data([0xba,0x78,0x16,0xbf,0x8f,0x01,0xcf,0xea,0x41,0x41,0x40,0xde,0x5d,0xae,0x22,0x23,
                           0xb0,0x03,0x61,0xa3,0x96,0x17,0x7a,0x9c,0xb4,0x10,0xff,0x61,0xf2,0x00,0x15,0xad])
        let буквальнаяИнформация = Data("d9:file treed1:ad0:d6:lengthi3e11:pieces root32:".utf8) + корень
            + Data("eee6:lengthi3e12:meta versioni2e4:name1:a12:piece lengthi16384e6:pieces20:".utf8) + хэшПервойВерсии + Data("e".utf8)
        XCTAssertEqual(информация, буквальнаяИнформация)
        XCTAssertEqual(метаданные.бенкодированныеДанные, Data("d4:info".utf8) + буквальнаяИнформация + Data("12:piece layersdee".utf8))
        XCTAssertEqual(информация.count, 175)
        XCTAssertEqual(метаданные.бенкодированныеДанные.count, 200)
        XCTAssertEqual(метаданные.бенкодированныеДанные.subdata(in: 7..<182), информация)
        try проверить(метаданные, максимум: 200)
        XCTAssertThrowsError(try проверить(метаданные, максимум: 199))
        try проверить(ОракулМетаданных.пример(длина: 32768).0, длина: 32768)
    }

    func test_КаноничностьДоПроверкиПравильныхХэшейПовреждённыхБайтов() throws {
        let (_, информация) = try ОракулМетаданных.пример()
        var неканонические = информация
        неканонические.replaceSubrange(try XCTUnwrap(неканонические.range(of: Data("i3e".utf8))), with: Data("i03e".utf8))
        XCTAssertThrowsError(try проверить(сИнформацией(неканонические)))
    }

    func test_ТочныеБюджетыИОграничениеКлючаДоКопии() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        for (число, допустимо) in [(229, true), (230, false)] {
            let данные = Data(("d1:al" + String(repeating: "i0e", count: число) + "e").utf8) + метаданные.бенкодированныеДанные.dropFirst()
            if допустимо { try проверить(замена(метаданные, данные)) }
            else { XCTAssertThrowsError(try проверить(замена(метаданные, данные))) }
        }
        for (длина, допустимо) in [(1024, true), (1025, false)] {
            let данные = Data(("d\(длина):" + String(repeating: "a", count: длина) + "i0e").utf8) + метаданные.бенкодированныеДанные.dropFirst()
            if допустимо { try проверить(замена(метаданные, данные)) }
            else { XCTAssertThrowsError(try проверить(замена(метаданные, данные))) }
        }
        var разбор = РазборБенкода(байты: Array(("d1025:" + String(repeating: "a", count: 1025) + "i0ee").utf8))
        XCTAssertThrowsError(try разбор.узел(глубина: 0))
        XCTAssertEqual(разбор.позиция, 6, "отказ до чтения и копирования тела ключа")
    }

    func test_СлойОбязателенИБайтовоПолон() throws {
        let (малые, информация) = try ОракулМетаданных.пример()
        XCTAssertThrowsError(try проверить(замена(малые, Data("d4:info".utf8) + информация + Data("e".utf8))))
        let содержимое = Data(repeating: 65, count: 16384) + Data(repeating: 66, count: 16384) + Data([67])
        let (метаданные, сведения) = try ОракулМетаданных.пример(содержимое: содержимое)
        let начало = сведения.count + 7 + Data("12:piece layersd32:".utf8).count
        let корень = метаданные.бенкодированныеДанные.subdata(in: начало..<(начало + 32))
        let слой = метаданные.бенкодированныеДанные.subdata(in: (начало + 35)..<(начало + 131))
        let префикс = Data("d4:info".utf8) + сведения + Data("12:piece layersd32:".utf8)
        var перестановка = слой; перестановка.replaceSubrange(0..<32, with: слой[32..<64]); перестановка.replaceSubrange(32..<64, with: слой[0..<32])
        for (ключ, хэши) in [(корень, Data(слой.dropLast())), (корень, слой + Data([0])),
                             (Data(repeating: 1, count: 32), слой), (корень, перестановка)] {
            let данные = префикс + ключ + Data("\(хэши.count):".utf8) + хэши + Data("ee".utf8)
            XCTAssertThrowsError(try проверить(замена(метаданные, данные), размер: UInt64(содержимое.count)))
        }
    }
    func test_ПроверяетДваНезависимыхСлояСНеполнойПоследнейЧастью() throws {
        let первый = Data(repeating: 65, count: 16384) + Data(repeating: 66, count: 16384) + Data([67])
        let второй = Data(repeating: 65, count: 16384) + Data(repeating: 66, count: 16384)
            + Data(repeating: 67, count: 16384) + Data(repeating: 68, count: 16384) + Data([69])
        for (данные, длина) in [(первый, 16384), (второй, 32768)] {
            let (метаданные, информация) = try ОракулМетаданных.пример(содержимое: данные, длина: длина)
            XCTAssertEqual(информация.count, 223); XCTAssertEqual(метаданные.бенкодированныеДанные.count, 382)
            try проверить(метаданные, размер: UInt64(данные.count), длина: длина)
            var повреждённые = метаданные.бенкодированныеДанные
            повреждённые[повреждённые.count - 3] ^= 1
            XCTAssertThrowsError(try проверить(замена(метаданные, повреждённые), размер: UInt64(данные.count), длина: длина))
            let неполные = Data("d4:info".utf8) + информация + Data("12:piece layersdee".utf8)
            XCTAssertThrowsError(try проверить(замена(метаданные, неполные), размер: UInt64(данные.count), длина: длина))
        }
    }
    func test_НеХэшируетПоляВнеИнформации() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        let данные = Data("d10:created by1:x".utf8) + метаданные.бенкодированныеДанные.dropFirst()
        try проверить(замена(метаданные, данные))
    }
    func test_ОтклоняетХвостУсечениеИНеканоническиеЧисла() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        var неканонические = метаданные.бенкодированныеДанные
        let диапазон = try XCTUnwrap(неканонические.range(of: Data("i3e".utf8)))
        неканонические.replaceSubrange(диапазон, with: Data("i03e".utf8))
        for данные in [метаданные.бенкодированныеДанные + Data("e".utf8),
                       Data(метаданные.бенкодированныеДанные.dropLast()), неканонические,
                       Data("d1:ai-0e4:info".utf8) + метаданные.бенкодированныеДанные.dropFirst(7),
                       Data("d1:a03:abc4:info".utf8) + метаданные.бенкодированныеДанные.dropFirst(7),
                       Data("d1:a999999999999999999999:abc4:info".utf8) + метаданные.бенкодированныеДанные.dropFirst(7)] {
            XCTAssertThrowsError(try проверить(замена(метаданные, данные)))
        }
    }
    func test_ОтклоняетДубликатИПорядокТакжеВнеИнформации() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        for префикс in ["d1:ai1e1:ai2e", "d1:bi1e1:ai2e", "di1ei2e"] {
            let данные = Data(префикс.utf8) + метаданные.бенкодированныеДанные.dropFirst()
            XCTAssertThrowsError(try проверить(замена(метаданные, данные)))
        }
    }
    func test_ОтклоняетЧужойЗаявленныйХэшИЛожнуюИдентичность() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        let неверные = try СозданныеМетаданныеТоррента(бенкодированныеДанные: метаданные.бенкодированныеДанные,
            хэшиИнформации: ХэшиИнформацииТоррента(хэшВерсии1: String(repeating: "0", count: 40), хэшВерсии2: String(repeating: "0", count: 64)))
        XCTAssertThrowsError(try проверить(неверные))
        XCTAssertThrowsError(try проверить(метаданные, размер: 4))
        XCTAssertThrowsError(try проверить(метаданные, длина: 32768))
    }
    func test_ОграничиваетГлубинуЧислоУзловИДлинуКлюча() throws {
        let (метаданные, _) = try ОракулМетаданных.пример()
        let остаток = метаданные.бенкодированныеДанные.dropFirst()
        for префикс in ["d1:a" + String(repeating: "l", count: 9) + String(repeating: "e", count: 9),
                        "d1:al" + String(repeating: "i0e", count: 300) + "e",
                        "d1025:" + String(repeating: "a", count: 1025) + "i0e"] {
            XCTAssertThrowsError(try проверить(замена(метаданные, Data(префикс.utf8) + остаток)))
        }
    }
}
