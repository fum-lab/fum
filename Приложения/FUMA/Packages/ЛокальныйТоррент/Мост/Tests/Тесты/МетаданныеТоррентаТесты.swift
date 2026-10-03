import CryptoKit
import Darwin
import Foundation
import XCTest
import МостЛибторрента
import ПробыМоста

final class МетаданныеТоррентаТесты: XCTestCase {
    func test_НулевыеВходыИБезопасныеНулевыеПолучатели() throws {
        var выход: OpaquePointer?
        XCTAssertEqual(создать_полную_фикстуру_метаданных(nil, &выход).код, 1)
        XCTAssertNil(выход)
        XCTAssertEqual(создать_полную_фикстуру_метаданных(nil, nil).код, 1)
        var длина = 77
        XCTAssertNil(байты_метаданных_торрента(nil, &длина)); XCTAssertEqual(длина, 0)
        XCTAssertNil(байты_метаданных_торрента(nil, nil))
        XCTAssertNil(хэш_первой_версии_торрента(nil))
        XCTAssertNil(хэш_второй_версии_торрента(nil))
        уничтожить_метаданные_торрента(nil)
    }
    func test_ВладениеРезультатомИОтказыНеПубликуютЧастичныйВыход() throws {
        let папка = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: папка, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: папка) }
        let файл = папка.appendingPathComponent("a"); let данные = Data("abc".utf8)
        try данные.write(to: файл)
        let исходник = Darwin.open(файл.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        let каталог = Darwin.open(папка.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        XCTAssertGreaterThanOrEqual(исходник, 0); XCTAssertGreaterThanOrEqual(каталог, 0)
        defer { Darwin.close(исходник); Darwin.close(каталог) }
        let хэш = Array(SHA256.hash(data: данные))
        for случай in [Int32(0), 1, 2, 3, 4, 5, 6, 7, 8] {
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            var выход: OpaquePointer?
            let результат = хэш.withUnsafeBufferPointer { адресХэша in
                "a".withCString { имя in
                    var вход = ВходМостаТоррента(исходник: исходник, каталог: каталог, имя: имя,
                        длина_имени: 1, размер: 3, максимум_файла: 3, длина_части: случай == 7 ? 32768 : 16384,
                        максимум_метаданных: случай == 6 ? 1 : 200, хэш: адресХэша.baseAddress,
                        длина_хэша: 32, операция: операция, проверка_отмены: nil, контекст: nil)
                    if случай == 7 { return создать_полную_фикстуру_метаданных(&вход, &выход) }
                    return создать_фикстуру_метаданных_с_отказом(&вход, &выход, случай)
                }
            }
            defer { уничтожить_метаданные_торрента(выход) }
            if случай == 0 {
                XCTAssertEqual(результат.код, 0); XCTAssertNotNil(выход)
                let прежний = выход
                XCTAssertEqual(создать_полную_фикстуру_метаданных(nil, &выход).код, 1)
                XCTAssertEqual(выход, прежний)
                var длина = 0; let байты = байты_метаданных_торрента(выход, &длина)
                let копия = Data(bytes: try XCTUnwrap(байты), count: длина)
                XCTAssertEqual(копия, Data("de".utf8))
                XCTAssertEqual(String(cString: try XCTUnwrap(хэш_первой_версии_торрента(выход))), String(repeating: "a", count: 40))
                уничтожить_метаданные_торрента(выход); выход = nil
                XCTAssertEqual(копия, Data("de".utf8), "копия Swift переживает owner")
            } else {
                XCTAssertEqual(результат.код, случай == 2 ? 3 : (случай == 3 ? 2 : 1)); XCTAssertNil(выход)
                if случай == 8 {
                    var сообщение = результат.сообщение
                    XCTAssertTrue(withUnsafeBytes(of: &сообщение) {
                        String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
                    }.contains("неизвестное исключение"))
                }
            }
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: папка.path), ["a"])
        }
    }
    func test_БюджетПроизводителяСохраняетОбщийКонтрактФикстур() throws {
        let папка = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: папка, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: папка) }
        let файл = папка.appendingPathComponent("a"); let данные = Data("abc".utf8)
        try данные.write(to: файл)
        let исходник = Darwin.open(файл.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        let каталог = Darwin.open(папка.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        XCTAssertGreaterThanOrEqual(исходник, 0); XCTAssertGreaterThanOrEqual(каталог, 0)
        defer { Darwin.close(исходник); Darwin.close(каталог) }
        let хэш = Array(SHA256.hash(data: данные))
        for (лимит, производственный) in [(UInt64(2), false), (199, true), (200, true)] {
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            var выход: OpaquePointer?
            defer { уничтожить_метаданные_торрента(выход) }
            let ответ = хэш.withUnsafeBufferPointer { адресХэша in
                "a".withCString { имя in
                    var вход = ВходМостаТоррента(исходник: исходник, каталог: каталог, имя: имя,
                        длина_имени: 1, размер: 3, максимум_файла: 3, длина_части: 16384,
                        максимум_метаданных: лимит, хэш: адресХэша.baseAddress, длина_хэша: 32,
                        операция: операция, проверка_отмены: nil, контекст: nil)
                    if производственный { return создать_метаданные_торрента(&вход, &выход) }
                    return создать_фикстуру_метаданных(&вход, &выход)
                }
            }
            if лимит == 199 { XCTAssertEqual(ответ.код, 1); XCTAssertNil(выход) }
            else {
                XCTAssertEqual(ответ.код, 0)
                var длина = 0
                XCTAssertNotNil(байты_метаданных_торрента(try XCTUnwrap(выход), &длина))
                XCTAssertEqual(длина, Int(лимит))
            }
            XCTAssertEqual(Darwin.lseek(исходник, 0, SEEK_CUR), 0)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: папка.path), ["a"])
        }
        var длина = 7
        XCTAssertNil(прямые_байты_либторрента(nil, &длина)); XCTAssertEqual(длина, 0)
        XCTAssertNil(прямой_хэш_первой_версии(nil)); XCTAssertNil(прямой_хэш_второй_версии(nil))
        уничтожить_прямые_метаданные(nil)
    }

}
