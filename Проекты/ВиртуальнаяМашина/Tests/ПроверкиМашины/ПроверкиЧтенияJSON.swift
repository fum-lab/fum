import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиЧтенияВходногоФайла: XCTestCase {
    let предел = 4 * 1024 * 1024

    func вКаталоге(_ действие: (URL) throws -> Void) throws {
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: каталог) }
        try действие(каталог)
    }

    func системные() -> ОперацииВходногоФайла {
        ОперацииВходногоФайла(открыть: { Darwin.open($0, $1) },
            свойства: { Darwin.fstat($0, $1) }, читать: { Darwin.read($0, $1, $2) },
            закрыть: { Darwin.close($0) })
    }

    func test_ПубличныйФайлСЧитаемымиПравамиИСсылкамиПринимается() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("профиль.json")
            try Data("{\"текст\":\"байты ё\"}".utf8).write(to: файл)
            XCTAssertEqual(chmod(файл.path, 0o644), 0)
            let жёсткая = каталог.appendingPathComponent("жёсткая.json")
            let символическая = каталог.appendingPathComponent("символическая.json")
            XCTAssertEqual(link(файл.path, жёсткая.path), 0)
            XCTAssertEqual(symlink(файл.path, символическая.path), 0)
            for адрес in [файл, жёсткая, символическая] {
                XCTAssertEqual(try ЧтениеВходногоФайла.прочитать([String: String].self, адрес.path), ["текст": "байты ё"])
            }
        }
    }

    func test_РовноЧетыреМиБПринимаютсяСледующийБайтОтклоняется() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("предел.json")
            var байты = Data("\"ё\"".utf8)
            байты.append(Data(repeating: 32, count: предел - байты.count))
            try байты.write(to: файл)
            XCTAssertEqual(try ЧтениеВходногоФайла.прочитать(String.self, файл.path), "ё")
            байты.append(32); try байты.write(to: файл)
            XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(String.self, файл.path)) { ошибка in
                XCTAssertTrue(String(describing: ошибка).contains("4 MiB"))
            }
        }
    }

    func test_ПустойПовреждённыйИЛишнийДокументНеДекодируются() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("повреждённый.json")
            for байты in [Data(), Data("{".utf8), Data("{} {}".utf8), Data([0xff]), Data("[]".utf8)] {
                try байты.write(to: файл)
                XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать([String: String].self, файл.path)) { ошибка in
                    XCTAssertTrue(ошибка is DecodingError)
                }
            }
        }
    }

    func test_КаталогКаналУстройствоИОтсутствующийПутьОтклоняются() throws {
        try вКаталоге { каталог in
            let канал = каталог.appendingPathComponent("канал")
            let файл = каталог.appendingPathComponent("существующий.json")
            try Data("7".utf8).write(to: файл)
            XCTAssertEqual(mkfifo(канал.path, 0o600), 0)
            for путь in [каталог.path, "/dev/null", каталог.appendingPathComponent("нет").path, файл.path + "\0хвост"] {
                XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(Int.self, путь)) { ошибка in
                    XCTAssertTrue(ошибка is ОшибкаМашины)
                }
            }
            var каналОперации = системные(), каналЧтения = 0, каналЗакрытия = 0
            каналОперации.открыть = { путь, флаги in
                XCTAssertNotEqual(флаги & O_NONBLOCK, 0)
                // При регрессии флага тест отказывает, но сам не зависает на FIFO.
                return Darwin.open(путь, флаги | O_NONBLOCK)
            }
            каналОперации.читать = { номер, буфер, размер in
                каналЧтения += 1; return Darwin.read(номер, буфер, размер)
            }
            каналОперации.закрыть = { номер in каналЗакрытия += 1; return Darwin.close(номер) }
            XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(Int.self, канал.path, операции: каналОперации))
            XCTAssertEqual(каналЧтения, 0); XCTAssertEqual(каналЗакрытия, 1)
            // Валидный JSON не должен маскировать пропущенную проверку типа файла.
            for вид in [mode_t(S_IFIFO), mode_t(S_IFCHR)] {
                var операции = системные(), чтения = 0, закрытия = 0
                операции.свойства = { номер, сведения in
                    let код = Darwin.fstat(номер, сведения)
                    сведения.pointee.st_mode = вид | 0o644
                    return код
                }
                операции.читать = { номер, буфер, размер in
                    чтения += 1; return Darwin.read(номер, буфер, размер)
                }
                операции.закрыть = { номер in закрытия += 1; return Darwin.close(номер) }
                XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(Int.self, файл.path, операции: операции))
                XCTAssertEqual(чтения, 0); XCTAssertEqual(закрытия, 1)
            }
        }
    }

    func test_ОдинВызовОткрытияСФлагамиПроверяетТотЖеДескрипторИЗакрываетЕго() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("открытый.json")
            try Data("7".utf8).write(to: файл)
            var операции = системные(), открытия = 0, закрытия = 0, проверенные: [Int32] = []
            var дескриптор: Int32 = -1
            операции.открыть = { путь, флаги in
                открытия += 1
                XCTAssertEqual(путь, NSString(string: "~/открытая-фикстура.json").expandingTildeInPath)
                XCTAssertEqual(флаги, O_RDONLY | O_NONBLOCK | O_CLOEXEC)
                дескриптор = Darwin.open(файл.path, флаги)
                XCTAssertNotEqual(fcntl(дескриптор, F_GETFD) & FD_CLOEXEC, 0)
                XCTAssertNotEqual(fcntl(дескриптор, F_GETFL) & O_NONBLOCK, 0)
                return дескриптор
            }
            операции.свойства = { номер, сведения in проверенные.append(номер); return Darwin.fstat(номер, сведения) }
            операции.читать = { номер, буфер, размер in
                XCTAssertEqual(номер, дескриптор); return Darwin.read(номер, буфер, размер)
            }
            операции.закрыть = { номер in закрытия += 1; XCTAssertEqual(номер, дескриптор); return Darwin.close(номер) }
            XCTAssertEqual(try ЧтениеВходногоФайла.прочитать(Int.self, "~/открытая-фикстура.json", операции: операции), 7)
            XCTAssertEqual(открытия, 1); XCTAssertEqual(проверенные, [дескриптор]); XCTAssertEqual(закрытия, 1)
            XCTAssertEqual(fcntl(дескриптор, F_GETFD), -1); XCTAssertEqual(errno, EBADF)
        }
    }

    func test_РостПослеПроверкиСвойствОграниченФактическимиПрочитаннымиБайтами() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("растущий.json")
            try Data("0".utf8).write(to: файл)
            var операции = системные(), прочитано = 0, закрытия = 0
            операции.свойства = { номер, сведения in
                let код = Darwin.fstat(номер, сведения)
                XCTAssertEqual(сведения.pointee.st_size, 1)
                do {
                    let запись = try FileHandle(forWritingTo: файл)
                    defer { try? запись.close() }
                    try запись.seekToEnd(); try запись.write(contentsOf: Data(repeating: 32, count: self.предел))
                } catch { XCTFail("Не удалось вырастить открытую фикстуру: \(error)") }
                return код
            }
            операции.читать = { номер, буфер, размер in
                XCTAssertLessThanOrEqual(размер, self.предел + 1 - прочитано)
                let число = Darwin.read(номер, буфер, размер)
                if число > 0 { прочитано += число }
                return число
            }
            операции.закрыть = { номер in закрытия += 1; return Darwin.close(номер) }
            XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(Int.self, файл.path, операции: операции)) { ошибка in
                XCTAssertTrue(String(describing: ошибка).contains("4 MiB"))
            }
            XCTAssertEqual(прочитано, предел + 1); XCTAssertEqual(закрытия, 1)
        }
    }

    func test_ЗаменаПутиПослеПроверкиСвойствНеМеняетУжеОткрытыйФайл() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("вход.json")
            try Data("\"прежний ё\"".utf8).write(to: файл)
            var операции = системные(), открытия = 0
            операции.открыть = { путь, флаги in открытия += 1; return Darwin.open(путь, флаги) }
            операции.свойства = { номер, сведения in
                let код = Darwin.fstat(номер, сведения)
                do {
                    try FileManager.default.moveItem(at: файл, to: каталог.appendingPathComponent("прежний.json"))
                    try Data("\"подмена\"".utf8).write(to: файл)
                } catch { XCTFail("Не удалось заменить путь фикстуры: \(error)") }
                return код
            }
            XCTAssertEqual(try ЧтениеВходногоФайла.прочитать(String.self, файл.path, операции: операции), "прежний ё")
            XCTAssertEqual(открытия, 1)
            XCTAssertEqual(try String(contentsOf: файл, encoding: .utf8), "\"подмена\"")
        }
    }

    func test_КороткиеЧтенияИПрерываниеПродолжаютсяДоКонцаФайла() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("части.json")
            let байты = Data("\"несколько ё\"".utf8); try байты.write(to: файл)
            var операции = системные(), вызовы = 0, конец = false
            операции.читать = { номер, буфер, размер in
                вызовы += 1
                if вызовы == 1 { errno = EINTR; return -1 }
                let число = Darwin.read(номер, буфер, min(2, размер))
                if число == 0 { конец = true }
                return число
            }
            XCTAssertEqual(try ЧтениеВходногоФайла.прочитать(String.self, файл.path, операции: операции), "несколько ё")
            XCTAssertTrue(конец); XCTAssertGreaterThan(вызовы, байты.count / 2)
        }
    }

    func test_ОтказыОткрытияСвойствЧтенияИДекодированияНеОставляютДескриптор() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("ошибка.json")
            for отказ in ["открытие", "свойства", "чтение", "частичное чтение", "декодирование"] {
                try Data((отказ == "декодирование" ? "{" : "7").utf8).write(to: файл)
                var операции = системные(), открытия = 0, свойства = 0, чтения = 0, закрытия = 0
                var дескриптор: Int32 = -1
                операции.открыть = { путь, флаги in
                    открытия += 1
                    if отказ == "открытие" { errno = ENOENT; return -1 }
                    дескриптор = Darwin.open(путь, флаги); return дескриптор
                }
                операции.свойства = { номер, сведения in
                    свойства += 1
                    let код = Darwin.fstat(номер, сведения)
                    if отказ == "свойства" { errno = EIO; return -1 }
                    return код
                }
                операции.читать = { номер, буфер, размер in
                    чтения += 1
                    if отказ == "чтение" || отказ == "частичное чтение" && чтения > 1 { errno = EIO; return -1 }
                    return Darwin.read(номер, буфер, размер)
                }
                операции.закрыть = { номер in закрытия += 1; return Darwin.close(номер) }
                XCTAssertThrowsError(try ЧтениеВходногоФайла.прочитать(Int.self, файл.path, операции: операции)) { ошибка in
                    if отказ == "декодирование" { XCTAssertTrue(ошибка is DecodingError) }
                    else { XCTAssertTrue(ошибка is ОшибкаМашины) }
                }
                XCTAssertEqual(открытия, 1); XCTAssertEqual(свойства, отказ == "открытие" ? 0 : 1)
                if отказ == "открытие" || отказ == "свойства" { XCTAssertEqual(чтения, 0) }
                else { XCTAssertGreaterThan(чтения, 0) }
                if отказ == "частичное чтение" { XCTAssertEqual(чтения, 2) }
                XCTAssertEqual(закрытия, отказ == "открытие" ? 0 : 1, отказ)
                if дескриптор >= 0 {
                    XCTAssertEqual(fcntl(дескриптор, F_GETFD), -1, отказ); XCTAssertEqual(errno, EBADF, отказ)
                }
            }
        }
    }

    func test_ПрофильТрёхОдинаковыхЧтенийОткрытойФикстуры() throws {
        try вКаталоге { каталог in
            let файл = каталог.appendingPathComponent("профиль.json")
            let текст = String(repeating: "я", count: 512 * 1024)
            let байты = try JSONEncoder().encode(текст); try байты.write(to: файл)
            var замеры: [UInt64] = []
            for _ in 0..<3 {
                let начало = DispatchTime.now().uptimeNanoseconds
                let прочитанный = try ЧтениеВходногоФайла.прочитать(String.self, файл.path)
                замеры.append(DispatchTime.now().uptimeNanoseconds - начало)
                XCTAssertEqual(прочитанный, текст)
            }
            let профиль: [String: Any] = ["схема": "fum.профиль-чтения-входного-json.1", "вход_sha256": хэш(байты),
                "вход_байт": байты.count, "повторы_нс": замеры, "медиана_нс": замеры.sorted()[1], "предкритерий_нс": 100_000_000]
            print("ПРОФИЛЬ_ЧТЕНИЯ " + String(decoding: try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys]), as: UTF8.self))
            XCTAssertLessThan(замеры.sorted()[1], 100_000_000)
        }
    }
}
