import Foundation
import CryptoKit
import Darwin
import XCTest
import МостЛибторрента
import ПробыМоста

final class СнимокФайлаТесты: XCTestCase {
    func test_СохраняетПозднийМаркерИНеБлокируетсяНаКанале() throws {
        for случай in [Int32(8), 9] {
            try сФайлом { исходник, папка, данные, _ in
                var операция: OpaquePointer?
                XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
                defer { уничтожить_операцию_торрента(операция) }
                let часы = ContinuousClock(); let начало = часы.now
                let (результат, наблюдение) = проба(исходник, папка, данные: данные, операция: операция, случай: случай)
                XCTAssertEqual(результат.код, 1)
                XCTAssertEqual(наблюдение.подмена_сохранена, 1)
                XCTAssertEqual(наблюдение.писатель_закрыт, 1)
                XCTAssertLessThan(начало.duration(to: часы.now), .seconds(1))
            }
        }
    }
    func сФайлом(_ действие: (Int32, Int32, Data, URL) throws -> Void) throws {
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: каталог) }
        let папкаСнимка = каталог.appendingPathComponent("снимки")
        try FileManager.default.createDirectory(at: папкаСнимка, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let адресИсходника = каталог.appendingPathComponent("исходник")
        let данные = Data((0..<(1024 * 1024 + 37)).map { UInt8(truncatingIfNeeded: $0) })
        try данные.write(to: адресИсходника)
        try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: адресИсходника.path)
        let исходник = Darwin.open(адресИсходника.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        let папка = Darwin.open(папкаСнимка.path, O_RDONLY | O_CLOEXEC | O_DIRECTORY | O_NOFOLLOW)
        guard исходник >= 0, папка >= 0 else {
            if исходник >= 0 { Darwin.close(исходник) }
            if папка >= 0 { Darwin.close(папка) }
            XCTFail("не удалось открыть фикстуру")
            return
        }
        defer { Darwin.close(исходник); Darwin.close(папка) }
        XCTAssertEqual(Darwin.lseek(исходник, 7, SEEK_SET), 7)
        let первоначальныеФлаги = Darwin.fcntl(исходник, F_GETFL)
        let первоначальныеФлагиДескриптора = Darwin.fcntl(исходник, F_GETFD)
        let флагиПапки = Darwin.fcntl(папка, F_GETFL)
        let флагиДескриптораПапки = Darwin.fcntl(папка, F_GETFD)
        var исходникДо = stat()
        var папкаДо = stat()
        XCTAssertEqual(Darwin.fstat(исходник, &исходникДо), 0)
        XCTAssertEqual(Darwin.fstat(папка, &папкаДо), 0)
        try действие(исходник, папка, данные, папкаСнимка)
        XCTAssertGreaterThanOrEqual(Darwin.fcntl(исходник, F_GETFD), 0)
        XCTAssertEqual(Darwin.fcntl(исходник, F_GETFL), первоначальныеФлаги)
        XCTAssertEqual(Darwin.fcntl(исходник, F_GETFD), первоначальныеФлагиДескриптора)
        XCTAssertEqual(Darwin.fcntl(папка, F_GETFL), флагиПапки)
        XCTAssertEqual(Darwin.fcntl(папка, F_GETFD), флагиДескриптораПапки)
        var исходникПосле = stat()
        var папкаПосле = stat()
        XCTAssertEqual(Darwin.fstat(исходник, &исходникПосле), 0)
        XCTAssertEqual(Darwin.fstat(папка, &папкаПосле), 0)
        XCTAssertEqual(исходникПосле.st_dev, исходникДо.st_dev)
        XCTAssertEqual(исходникПосле.st_ino, исходникДо.st_ino)
        XCTAssertEqual(исходникПосле.st_mode, исходникДо.st_mode)
        XCTAssertEqual(папкаПосле.st_dev, папкаДо.st_dev)
        XCTAssertEqual(папкаПосле.st_ino, папкаДо.st_ino)
        XCTAssertEqual(папкаПосле.st_mode, папкаДо.st_mode)
        XCTAssertEqual(Darwin.lseek(исходник, 0, SEEK_CUR), 7)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: папкаСнимка.path), [])
    }

    func проба(_ исходник: Int32, _ папка: Int32, данные: Data, операция: OpaquePointer?,
               максимум: UInt64? = nil, ожидаемыйРазмер: UInt64? = nil,
               неверныйХэш: Bool = false, случай: Int32 = 0) -> (РезультатГраницыМоста, НаблюдениеСнимкаФайла) {
        var хэш = Array(SHA256.hash(data: данные))
        if неверныйХэш { хэш[0] ^= 0xff }
        var наблюдение = НаблюдениеСнимкаФайла()
        let имя = "проба.bin"
        let результат = хэш.withUnsafeBufferPointer { адресХэша in
            имя.withCString { адресИмени in
                выполнить_пробу_снимка_с_ошибкой(исходник, папка, адресИмени, имя.utf8.count,
                    ожидаемыйРазмер ?? UInt64(данные.count), максимум ?? UInt64(данные.count),
                    адресХэша.baseAddress, операция, &наблюдение, случай)
            }
        }
        return (результат, наблюдение)
    }

    func test_КороткиеНастоящиеОперацииИПрерывания() throws {
        try сФайлом { исходник, папка, данные, _ in
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            let (результат, наблюдение) = проба(исходник, папка, данные: данные, операция: операция, случай: 1)
            XCTAssertEqual(результат.код, 0)
            XCTAssertGreaterThan(наблюдение.вызовов_чтения, 100)
            XCTAssertGreaterThan(наблюдение.вызовов_записи, 100)
            XCTAssertEqual(наблюдение.проб_хвоста, 1)
            XCTAssertEqual(наблюдение.писатель_закрыт, 1)
        }
    }

    func test_ОшибкаНосителяИПодменаГотовыхБайтовЗакрываютСнимок() throws {
        for случай in [Int32(2), 3, 4, 5] {
            try сФайлом { исходник, папка, данные, _ in
                var операция: OpaquePointer?
                XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
                defer { уничтожить_операцию_торрента(операция) }
                let (результат, наблюдение) = проба(исходник, папка, данные: данные, операция: операция, случай: случай)
                XCTAssertEqual(результат.код, 1, "случай \(случай)")
                XCTAssertEqual(наблюдение.писатель_закрыт, 1)
                XCTAssertGreaterThan(наблюдение.вызовов_чтения, 0)
            }
        }
    }

    func test_ОтменаПослеЗаписиИВПрерваннойПробеХвоста() throws {
        for случай in [Int32(6), 7] {
            try сФайлом { исходник, папка, данные, адрес in
                var операция: OpaquePointer?
                XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
                defer { уничтожить_операцию_торрента(операция) }
                let (результат, наблюдение) = проба(исходник, папка, данные: данные, операция: операция, случай: случай)
                XCTAssertEqual(результат.код, 2)
                XCTAssertEqual(наблюдение.проб_хвоста, случай == 7 ? 1 : 0)
                XCTAssertEqual(наблюдение.писатель_закрыт, 1)
                XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: адрес.path), [])
                var новая: OpaquePointer?
                XCTAssertEqual(создать_операцию_торрента(&новая).код, 0)
                defer { уничтожить_операцию_торрента(новая) }
                XCTAssertEqual(проба(исходник, папка, данные: данные, операция: новая).0.код, 0)
            }
        }
    }

    func test_СоздаётПолныйСнимокИСохраняетИсходныйДескриптор() throws {
        try сФайлом { исходник, папка, данные, _ in
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            let (результат, наблюдение) = проба(исходник, папка, данные: данные, операция: операция)
            XCTAssertEqual(результат.код, 0)
            XCTAssertEqual(наблюдение.байтов, UInt64(данные.count))
            XCTAssertEqual(наблюдение.права_файла, 0o400)
            XCTAssertEqual(наблюдение.права_каталога, 0o700)
            XCTAssertEqual(наблюдение.позиция_сохранена, 1)
            XCTAssertEqual(наблюдение.флаги_сохранены, 1)
            XCTAssertEqual(наблюдение.снимок_независим, 1)
            XCTAssertEqual(наблюдение.каталог_дочерний, 1)
            XCTAssertEqual(наблюдение.файл_принадлежит_каталогу, 1)
            XCTAssertEqual(наблюдение.только_чтение, 1)
            XCTAssertEqual(наблюдение.каталог_закрывается_при_исполнении, 1)
            var хэш = наблюдение.хэш
            XCTAssertEqual(withUnsafeBytes(of: &хэш) { Array($0) }, Array(SHA256.hash(data: данные)))
        }
    }

    func test_ОтклоняетНеверныйХэшИУдаляетСнимок() throws {
        try сФайлом { исходник, папка, данные, _ in
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            XCTAssertEqual(проба(исходник, папка, данные: данные,
                операция: операция, неверныйХэш: true).0.код, 1)
        }
    }

    func test_ОтклоняетРазмерИЛимитИУдаляетСнимок() throws {
        try сФайлом { исходник, папка, данные, адресПапки in
            var операция: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
            defer { уничтожить_операцию_торрента(операция) }
            XCTAssertEqual(проба(исходник, папка, данные: данные,
                операция: операция, максимум: UInt64(данные.count - 1)).0.код, 1)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: адресПапки.path), [])
            XCTAssertEqual(проба(исходник, папка, данные: данные,
                операция: операция, ожидаемыйРазмер: UInt64(данные.count - 1)).0.код, 1)
        }
    }

    func test_РазличаетОтменуСнимкаИСвежуюПопытку() throws {
        try сФайлом { исходник, папка, данные, адресПапки in
            var отменённая: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&отменённая).код, 0)
            defer { уничтожить_операцию_торрента(отменённая) }
            отменить_операцию_торрента(отменённая)
            XCTAssertEqual(проба(исходник, папка, данные: данные, операция: отменённая).0.код, 2)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: адресПапки.path), [])
            var новая: OpaquePointer?
            XCTAssertEqual(создать_операцию_торрента(&новая).код, 0)
            defer { уничтожить_операцию_торрента(новая) }
            XCTAssertEqual(проба(исходник, папка, данные: данные, операция: новая).0.код, 0)
        }
    }
}
