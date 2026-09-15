import Foundation
import Darwin
import Testing
@testable import КонтейнерНаблюдений

struct СегментTests {
    func корень() throws -> URL {
        let путь = FileManager.default.temporaryDirectory.appendingPathComponent("контейнер-тест-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false)
        guard let физический = realpath(путь.path, nil) else { throw ОшибкаКонтейнера.система(errno) }
        defer { free(физический) }
        return URL(fileURLWithPath: String(cString: физический))
    }

    @Test func произвольныеБайтыИНеизвестныйТип() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let данные = Data((0...255).map(UInt8.init)) + Data("\nFUMOBS01\n{}\u{0}".utf8)
        let описание = ОписаниеНаблюдения(идентификатор: "неизвестный-1", тип: "будущий/тип")
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        let квитанция = try писатель.добавить(описание, данные: данные)
        писатель.закрыть()
        let читатель = try Сегмент(кореньДанных: путь, запись: false)
        #expect(читатель.записи == [квитанция])
        #expect(try читатель.извлечь(описание.идентификатор) == данные)
    }

    @Test func короткаяЗаписьИДедупликация() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let операции = ФайловыеОперации(запись: { дескриптор, буфер in
            let число = Darwin.write(дескриптор, буфер.baseAddress, min(7, буфер.count))
            if число < 0 { throw ОшибкаКонтейнера.система(errno) }; return число
        }, синхронизация: { дескриптор in
            if fsync(дескриптор) != 0 { throw ОшибкаКонтейнера.система(errno) }
        })
        let писатель = try Сегмент(кореньДанных: путь, запись: true, операции: операции)
        let описание = ОписаниеНаблюдения(идентификатор: "повтор", тип: "байты")
        let данные = Data(repeating: 19, count: 3073)
        let первая = try писатель.добавить(описание, данные: данные)
        #expect(try писатель.добавить(описание, данные: данные) == первая)
        #expect(писатель.записи.count == 1)
        #expect(throws: ОшибкаКонтейнера.конфликтИдентификатора) {
            try писатель.добавить(описание, данные: Data([42]))
        }
        #expect(try писатель.извлечь("повтор") == данные)
    }

    @Test func отказСинхронизацииНеДаётПодтверждение() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let подготовка = try Сегмент(кореньДанных: путь, запись: true); подготовка.закрыть()
        let операции = ФайловыеОперации(запись: { дескриптор, буфер in
            let число = Darwin.write(дескриптор, буфер.baseAddress, буфер.count)
            if число < 0 { throw ОшибкаКонтейнера.система(errno) }; return число
        }, синхронизация: { _ in throw ОшибкаКонтейнера.система(EIO) })
        let писатель = try Сегмент(кореньДанных: путь, запись: true, операции: операции)
        #expect(throws: ОшибкаКонтейнера.система(EIO)) {
            try писатель.добавить(ОписаниеНаблюдения(идентификатор: "неясный", тип: "байты"), данные: Data([1]))
        }
    }

    @Test func заполненныйНосительНеДаётПодтверждение() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let подготовка = try Сегмент(кореньДанных: путь, запись: true); подготовка.закрыть()
        let операции = ФайловыеОперации(запись: { _, _ in throw ОшибкаКонтейнера.система(ENOSPC) },
                                      синхронизация: { _ in })
        let писатель = try Сегмент(кореньДанных: путь, запись: true, операции: операции)
        #expect(throws: ОшибкаКонтейнера.система(ENOSPC)) {
            try писатель.добавить(ОписаниеНаблюдения(идентификатор: "места-нет", тип: "байты"), данные: Data([1]))
        }
    }

    @Test func усечениеВторойГруппыНаКаждомБайте() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "первая", тип: "байты"), данные: Data([1, 2]))
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let первыйРазмер = try Data(contentsOf: файл).count
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "вторая", тип: "байты"), данные: Data([3, 4]))
        писатель.закрыть()
        let полныеБайты = try Data(contentsOf: файл)
        for граница in (первыйРазмер + 1)..<полныеБайты.count {
            let обрезанные = полныеБайты.prefix(граница)
            try обрезанные.write(to: файл)
            let читатель = try Сегмент(кореньДанных: путь, запись: false)
            #expect(читатель.естьХвост)
            #expect(читатель.записи.count == 1)
            #expect(try читатель.извлечь("первая") == Data([1, 2]))
            читатель.закрыть()
            #expect(try Data(contentsOf: файл) == обрезанные)
        }
        let восстановитель = try Сегмент(кореньДанных: путь, запись: true)
        #expect(throws: ОшибкаКонтейнера.неполныйХвост) {
            try восстановитель.добавить(ОписаниеНаблюдения(идентификатор: "третья", тип: "байты"), данные: Data())
        }
        try восстановитель.восстановитьХвост()
        #expect(try Data(contentsOf: файл).count == первыйРазмер)
        _ = try восстановитель.добавить(ОписаниеНаблюдения(идентификатор: "третья", тип: "байты"), данные: Data([5]))
        #expect(восстановитель.записи.count == 2)
    }

    @Test func повреждениеПолнойГруппыНеОбрезается() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "целостность", тип: "байты"), данные: Data([1, 2, 3]))
        писатель.закрыть()
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let исходные = try Data(contentsOf: файл)
        for смещение in исходные.indices {
            var испорченные = исходные; испорченные[смещение] ^= 1
            try испорченные.write(to: файл)
            #expect(throws: (any Error).self) { try Сегмент(кореньДанных: путь, запись: true) }
            #expect(try Data(contentsOf: файл) == испорченные)
        }
    }

    @Test func отдельныйПроцессВоспроизводитБайты() throws {
        let путь = try корень(); defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("вход.bin")
        let данные = Data((0...255).map(UInt8.init))
        try данные.write(to: вход)
        let каталог = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/debug")
        func запустить(_ имя: String, _ аргументы: [String]) throws -> Data {
            let процесс = Process(); let канал = Pipe()
            процесс.executableURL = каталог.appendingPathComponent(имя)
            процесс.arguments = аргументы; процесс.standardOutput = канал
            try процесс.run()
            let ответ = канал.fileHandleForReading.readDataToEndOfFile()
            процесс.waitUntilExit(); #expect(процесс.terminationStatus == 0)
            return ответ
        }
        let ответ = try запустить("писатель-контейнера", ["добавить", путь.path, "процесс", "будущий/тип", вход.path])
        #expect(!ответ.isEmpty)
        let извлечённые = try запустить("читатель-контейнера", ["извлечь", путь.path, "процесс"])
        #expect(извлечённые == данные)
    }
}
