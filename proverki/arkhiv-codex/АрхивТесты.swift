import Foundation
import Testing
@testable import АрхивКодекса
import КонтейнерНаблюдений
import Darwin
import CryptoKit

@Suite(.serialized)
struct ПроверкиАрхиваКодекса {
    @Test func русскиеСвойстваСохраняютКлючиПервойСхемы() throws {
        let прежние: [String: Any] = ["версия": 1, "вид": "raw", "сессия": "сессия", "поколение": "поколение",
            "начало": 0, "конец": 2, "границаLF": 2, "обработано": 0,
            "хэшRAW": "хэш", "предыдущаяКвитанция": "предыдущая"]
        let исходные = try JSONSerialization.data(withJSONObject: прежние, options: [.sortedKeys, .withoutEscapingSlashes])
        let значение = try JSONDecoder().decode(МетаданныеПорции.self, from: исходные)
        #expect(значение.границаХранимыхСтрок == 2)
        #expect(значение.хэшБайтов == "хэш")
        #expect(try кодироватьМетаданные(значение) == исходные)
    }

    func каталог() throws -> URL {
        let путь = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        guard let физический = realpath(путь.path, nil) else { throw ОшибкаКонтейнера.система(errno) }
        defer { free(физический) }
        return URL(fileURLWithPath: String(cString: физический))
    }
    func байты(_ архив: АрхивКодекса) throws -> Data {
        var данные = Data()
        try архив.восстановить { данные.append($0) }
        return данные
    }
    @Test func исходныеБайтыИДваКурсора() throws {
        let корень = try каталог()
        defer { try? FileManager.default.removeItem(at: корень) }
        let архив = try АрхивКодекса(корень: корень, сессия: UUID(), поколение: UUID())
        let байты = Data("{\"n\":1.5e-2}\nне JSON\nхвост".utf8)
        try архив.принять(байты, смещение: 0)
        var восстановлено = Data()
        try архив.восстановить { восстановлено.append($0) }
        #expect(восстановлено == байты)
        #expect(архив.сохранено == UInt64(байты.count))
        #expect(архив.границаСтрок == UInt64(байты.count - Data("хвост".utf8).count))
        #expect(архив.обработано == 0)
        try архив.завершить()
    }

    @Test func порцииКодировкиХвостПустотаИПовтор() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, пределПорции: 7)
        try архив.принять(Data(), смещение: 0)
        #expect(архив.сохранено == 0)
        let данные = Data([0xff, 0, 10]) + Data("я\n{\"v\":1e10}\nхвост".utf8)
        for смещение in stride(from: 0, to: данные.count, by: 1) {
            try архив.принять(данные.subdata(in: смещение..<(смещение + 1)), смещение: UInt64(смещение))
        }
        #expect(try байты(архив) == данные)
        let размер = архив.сохранено
        try архив.принять(данные.prefix(7), смещение: 0)
        let подложка = Data([42, 42]) + данные.prefix(7)
        let срез = подложка.dropFirst(2)
        #expect(срез.startIndex == 2)
        try архив.принять(срез, смещение: 0)
        #expect(архив.сохранено == размер)
        #expect(throws: ОшибкаАрхиваКодекса.источникИзменён) { try архив.принять(Data([1]), смещение: 0) }
        #expect(throws: ОшибкаАрхиваКодекса.источникИзменён) { try архив.принять(Data([1]), смещение: размер + 1) }
        #expect(throws: ОшибкаКонтейнера.система(EIO)) {
            try архив.проецировать { _ in throw ОшибкаКонтейнера.система(EIO) }
        }
        #expect(архив.обработано == 0)
        var проекция = Data()
        try архив.проецировать { проекция.append($0) }
        #expect(проекция == данные.prefix(Int(архив.границаСтрок)))
        #expect(архив.обработано == архив.границаСтрок)
        try архив.проецировать { _ in Issue.record("Подтверждённая проекция повторена") }
        try архив.завершить()
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(новый.сохранено == размер)
        #expect(новый.обработано == UInt64(проекция.count))
        #expect(try байты(новый) == данные)
        try новый.завершить()
    }

    @Test func подтверждениеСессииТолькоПоМетаданным() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID()
        let архив = try АрхивКодекса(корень: путь.appendingPathComponent("архив"), сессия: сессия, поколение: поколение)
        let ложные = Data("{\"type\":\"unknown\",\"payload\":{\"id\":\"\(сессия)\"}}\n{\"x\":{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(сессия)\"}}}\n".utf8)
        try архив.принять(ложные, смещение: 0)
        #expect(архив.подтверждённаяСессия == nil)
        let длинная = Data("{\"type\":\"session_meta\",\"pad\":\"".utf8) + Data(repeating: 120, count: 70_000) + Data("\",\"payload\":{\"id\":\"\(сессия)\"}}\n".utf8)
        try архив.принять(длинная, смещение: архив.сохранено)
        #expect(архив.подтверждённаяСессия == nil)
        let настоящая = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(сессия)\"}}\n".utf8)
        for байт in настоящая { try архив.принять(Data([байт]), смещение: архив.сохранено) }
        #expect(архив.подтверждённаяСессия == сессия.uuidString.lowercased())
        try архив.завершить()
        let новый = try АрхивКодекса(корень: путь.appendingPathComponent("архив"), сессия: сессия, поколение: поколение)
        #expect(новый.подтверждённаяСессия == сессия.uuidString.lowercased())
        #expect(try байты(новый) == ложные + длинная + настоящая)
        try новый.завершить()
    }

    @Test func конфликтСессииСохраняетИсходныеБайты() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        let данные = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(UUID())\"}}\n".utf8)
        #expect(throws: ОшибкаАрхиваКодекса.сессияНеСовпала) { try архив.принять(данные, смещение: 0) }
        try архив.завершить()
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(try байты(новый) == данные)
        try новый.завершить()
    }

    @Test func одинПроходПрефиксаИПодменаПриПрежнихМетаданных() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let файл = путь.appendingPathComponent("вход.jsonl")
        let архив = try АрхивКодекса(корень: путь.appendingPathComponent("архив"), сессия: UUID(), поколение: UUID(), пределПорции: 11)
        let исходные = Data("12.345e9\nнеизвестное\nхвост".utf8)
        try исходные.write(to: файл)
        let первый = try архив.импортировать(файл)
        #expect(первый.прочитаноПрефикса == 0 && первый.прочитаноДобавки == исходные.count)
        let добавка = Data("\nдобавка\n".utf8)
        try (исходные + добавка).write(to: файл)
        let второй = try архив.импортировать(файл)
        #expect(второй.прочитаноПрефикса == исходные.count && второй.прочитаноДобавки == добавка.count)
        let третий = try архив.импортировать(файл)
        #expect(третий.прочитаноВсего == исходные.count + добавка.count && третий.прочитаноДобавки == 0)
        let атрибуты = try FileManager.default.attributesOfItem(atPath: файл.path)
        var подмена = исходные + добавка; подмена[0] = 57
        let запись = try FileHandle(forWritingTo: файл)
        try запись.write(contentsOf: подмена); try запись.close()
        try FileManager.default.setAttributes([.modificationDate: атрибуты[.modificationDate]!], ofItemAtPath: файл.path)
        #expect(throws: ОшибкаАрхиваКодекса.источникИзменён) { _ = try архив.импортировать(файл) }
        #expect(try байты(архив) == исходные + добавка)
        try архив.завершить()
    }

    @Test(arguments: [false, true]) func отказДоИПослеСинхронизации(после: Bool) throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { дескриптор in
            var сведения = stat(); _ = fstat(дескриптор, &сведения)
            if сведения.st_mode & S_IFMT == S_IFREG && сведения.st_size > 3000 {
                if после { try ФайловыеОперации.системные.синхронизация(дескриптор) }
                throw ОшибкаКонтейнера.система(EIO)
            }
            try ФайловыеОперации.системные.синхронизация(дескриптор)
        })
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, операции: операции)
        let данные = Data(repeating: 127, count: 4096)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.принять(данные, смещение: 0) }
        #expect(архив.сохранено == 0)
        #expect(throws: ОшибкаАрхиваКодекса.закрыт) { try архив.принять(данные, смещение: 0) }
        try архив.завершить()
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(try байты(новый) == данные)
        try новый.принять(данные, смещение: 0)
        #expect(новый.сохранено == данные.count)
        try новый.завершить()
    }

    @Test func частичнаяЗаписьТребуетЯвногоВосстановления() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let операции = ФайловыеОперации(запись: { дескриптор, буфер in
            if буфер.count == 4096 {
                _ = Darwin.write(дескриптор, буфер.baseAddress, 2000)
                throw ОшибкаКонтейнера.система(EIO)
            }
            return try ФайловыеОперации.системные.запись(дескриптор, буфер)
        }, синхронизация: ФайловыеОперации.системные.синхронизация)
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, операции: операции)
        let данные = Data(repeating: 55, count: 4096)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.принять(данные, смещение: 0) }
        try архив.завершить()
        #expect(throws: ОшибкаКонтейнера.неполныйХвост) { _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение) }
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, восстановитьХвост: true)
        #expect(новый.сохранено == 0)
        try новый.принять(данные, смещение: 0)
        #expect(try байты(новый) == данные)
        try новый.завершить()
    }

    @Test(arguments: ["до-ротации", "после-ротации"]) func отказРотации(этап: String) throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, порцийВСегменте: 2,
            граница: { if $0 == этап { throw ОшибкаКонтейнера.система(EIO) } })
        try архив.принять(Data([1]), смещение: 0)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.принять(Data([2]), смещение: 1) }
        try архив.завершить()
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(try байты(новый) == Data([1]))
        try новый.принять(Data([2]), смещение: 1)
        #expect(try байты(новый) == Data([1, 2]))
        try новый.завершить()
    }

    @Test func отказЗавершенияНаблюдаемИОсвобождаетЗамок() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: ФайловыеОперации.системные.синхронизация, закрытие: { дескриптор in
                try системноеЗакрытие(дескриптор)
                throw ОшибкаКонтейнера.система(EIO)
            })
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, операции: операции)
        try архив.принять(Data([1]), смещение: 0)
        #expect(throws: ОшибкаКонтейнера.занят) { _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение) }
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.завершить() }
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.завершить() }
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(try байты(новый) == Data([1]))
        try новый.завершить()
    }

    @Test func повторныйВходИзПроекцииЗапрещён() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let архив = try АрхивКодекса(корень: путь.appendingPathComponent("архив"), сессия: UUID(), поколение: UUID())
        try архив.принять(Data("a\n".utf8), смещение: 0)
        try архив.проецировать { _ in
            #expect(throws: ОшибкаАрхиваКодекса.закрыт) { try архив.принять(Data("b\n".utf8), смещение: 2) }
            #expect(throws: ОшибкаАрхиваКодекса.закрыт) { try архив.завершить() }
        }
        #expect(архив.обработано == 2)
        #expect(архив.сохранено == 2)
        try архив.завершить()
    }

    @Test func отказЗавершенияВнутриРотации() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: ФайловыеОперации.системные.синхронизация, закрытие: { дескриптор in
                try системноеЗакрытие(дескриптор); throw ОшибкаКонтейнера.система(EIO)
            })
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение,
            порцийВСегменте: 2, операции: операции)
        try архив.принять(Data([1]), смещение: 0)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.принять(Data([2]), смещение: 1) }
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.завершить() }
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(try байты(новый) == Data([1]))
        try новый.принять(Data([2]), смещение: 1)
        #expect(try байты(новый) == Data([1, 2]))
        try новый.завершить()
    }

    @Test func синхронизацияРодителяПовторяетсяПослеОтказа() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        var метка = stat(); #expect(lstat(путь.path, &метка) == 0)
        let номерУзла = метка.st_ino, устройство = метка.st_dev
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { дескриптор in
            var сведения = stat(); _ = fstat(дескриптор, &сведения)
            if сведения.st_ino == номерУзла && сведения.st_dev == устройство { throw ОшибкаКонтейнера.система(EIO) }
            try ФайловыеОперации.системные.синхронизация(дескриптор)
        })
        let корень = путь.appendingPathComponent("архив"), сессия = UUID(), поколение = UUID()
        for _ in 0..<2 {
            #expect(throws: ОшибкаКонтейнера.система(EIO)) {
                _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, операции: операции)
            }
            #expect(FileManager.default.fileExists(atPath: корень.path))
        }
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение)
        #expect(новый.сохранено == 0)
        try новый.завершить()
    }

    @Test func приватныйКореньНеПринимает0755() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let корень = путь.appendingPathComponent("архив")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o755])
        #expect(throws: ОшибкаАрхиваКодекса.небезопасныйПуть) {
            _ = try АрхивКодекса(корень: корень, сессия: UUID(), поколение: UUID())
        }
        let режим = try FileManager.default.attributesOfItem(atPath: корень.path)[.posixPermissions] as? NSNumber
        #expect(режим?.intValue == 0o755)
    }

    @Test func отказКаталогаРотацииТребуетЯвногоВосстановления() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let корень = путь.appendingPathComponent("архив")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        var метка = stat(); #expect(lstat(корень.path, &метка) == 0)
        let номерУзла = метка.st_ino, устройство = метка.st_dev
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { дескриптор in
            var сведения = stat(), следующий = stat(); _ = fstat(дескриптор, &сведения)
            if сведения.st_ino == номерУзла && сведения.st_dev == устройство,
               fstatat(дескриптор, "00000001", &следующий, AT_SYMLINK_NOFOLLOW) == 0 { throw ОшибкаКонтейнера.система(EIO) }
            try ФайловыеОперации.системные.синхронизация(дескриптор)
        })
        let сессия = UUID(), поколение = UUID()
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение,
            порцийВСегменте: 2, операции: операции)
        try архив.принять(Data([1]), смещение: 0)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) { try архив.принять(Data([2]), смещение: 1) }
        try архив.завершить()
        #expect(throws: (any Error).self) { _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение) }
        let новый = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, восстановитьХвост: true)
        #expect(try байты(новый) == Data([1]))
        try новый.принять(Data([2]), смещение: 1)
        #expect(try байты(новый) == Data([1, 2]))
        try новый.завершить()
    }

    @Test func ошибочноеЗавершениеНеЗакрываетПовторноИспользованныйДескриптор() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        var замена: Int32 = -1
        #expect(throws: ОшибкаКонтейнера.система(EINTR)) {
            _ = try открытьПриватныйКаталог(путь, закрытие: { дескриптор in
                try системноеЗакрытие(дескриптор)
                замена = Darwin.open("/dev/null", O_RDONLY | O_CLOEXEC)
                throw ОшибкаКонтейнера.система(EINTR)
            })
        }
        defer { if замена >= 0 { _ = Darwin.close(замена) } }
        #expect(замена >= 0 && fcntl(замена, F_GETFD) >= 0)
    }

    @Test func подменаЦепиИПоколенияЗакрыта() throws {
        let путь = try каталог(); defer { try? FileManager.default.removeItem(at: путь) }
        let сессия = UUID(), поколение = UUID(), корень = путь.appendingPathComponent("архив")
        let архив = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение, порцийВСегменте: 2)
        for номер in 0..<3 { try архив.принять(Data([UInt8(номер)]), смещение: UInt64(номер)) }
        #expect(архив.числоСегментов == 3)
        try архив.завершить()
        #expect(throws: (any Error).self) { _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: UUID()) }
        let первый = корень.appendingPathComponent("00000000"), второй = корень.appendingPathComponent("00000001")
        let временный = путь.appendingPathComponent("перестановка")
        try FileManager.default.moveItem(at: первый, to: временный)
        try FileManager.default.moveItem(at: второй, to: первый)
        try FileManager.default.moveItem(at: временный, to: второй)
        #expect(throws: (any Error).self) { _ = try АрхивКодекса(корень: корень, сессия: сессия, поколение: поколение) }
    }
}
