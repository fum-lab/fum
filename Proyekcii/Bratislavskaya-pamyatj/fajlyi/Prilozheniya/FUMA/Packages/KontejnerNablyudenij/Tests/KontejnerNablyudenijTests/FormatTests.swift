import Foundation
import CryptoKit
import Darwin
import Testing
@testable import КонтейнерНаблюдений

// Независимый производитель заведомо неверных, но правильно хэшированных кадров.
struct НаборКадров {
    var байты = Data("FUMOBS01".utf8)
    var предыдущий = Data(SHA256.hash(data: Data("FUMOBS01".utf8)))
    var номер: UInt64 = 0

    mutating func кадр(_ вид: UInt8, _ заголовок: Data, _ данные: Data = Data(), номерКадра: UInt64? = nil) {
        var префикс = Data([79, 66, 83, 49, вид, 0, 0, 0])
        for значение in [UInt32(заголовок.count), UInt32(данные.count)] {
            var сетевой = значение.bigEndian
            withUnsafeBytes(of: &сетевой) { префикс.append(contentsOf: $0) }
        }
        var сетевойНомер = (номерКадра ?? номер).bigEndian
        withUnsafeBytes(of: &сетевойНомер) { префикс.append(contentsOf: $0) }
        var хэшКадра = SHA256()
        for часть in [предыдущий, префикс, заголовок, данные] { хэшКадра.update(data: часть) }
        предыдущий = Data(хэшКадра.finalize())
        байты.append(префикс); байты.append(contentsOf: SHA256.hash(data: префикс))
        байты.append(заголовок); байты.append(данные); байты.append(предыдущий)
        номер += 1
    }

    mutating func начало(_ имя: String = "один") throws {
        try кадр(1, кодировать(ОписаниеНаблюдения(идентификатор: имя, тип: "байты", спецификация: Data([1]))))
    }

    mutating func конец(_ данные: Data = Data(), количество: Int = 0) throws {
        try кадр(3, кодировать(Фиксация(размер: UInt64(данные.count), фрагменты: количество,
            хэш: Data(SHA256.hash(data: данные)).map { String(format: "%02x", $0) }.joined())))
    }
}

@Suite(.serialized)
struct ФорматTests {
    func отклонить(_ байты: Data, _ ошибка: ОшибкаКонтейнера = .повреждение) throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        try байты.write(to: файл)
        #expect(throws: ошибка) { try Сегмент(кореньДанных: путь, запись: true) }
        #expect(try Data(contentsOf: файл) == байты)
    }

    @Test func семантическиНеверныеКадрыСПравильнымХэшем() throws {
        var безНачала = НаборКадров(); try безНачала.конец()
        try отклонить(безНачала.байты)
        var вложенный = НаборКадров(); try вложенный.начало(); try вложенный.начало("два")
        try отклонить(вложенный.байты)
        var повтор = НаборКадров(); try повтор.начало(); try повтор.конец(); try повтор.начало()
        try отклонить(повтор.байты)
        for описание in [Фрагмент(номер: 1, смещение: 0), Фрагмент(номер: 0, смещение: 1)] {
            var набор = НаборКадров(); try набор.начало()
            try набор.кадр(2, кодировать(описание), Data([7]))
            try отклонить(набор.байты)
        }
        var неверныйНомер = НаборКадров()
        try неверныйНомер.кадр(1, кодировать(ОписаниеНаблюдения(идентификатор: "номер", тип: "байты")), номерКадра: 7)
        try отклонить(неверныйНомер.байты)
        for фиксация in [Фиксация(размер: 1, фрагменты: 0, хэш: строкаХэша(хэш(Data()))),
                         Фиксация(размер: 0, фрагменты: 1, хэш: строкаХэша(хэш(Data()))),
                         Фиксация(размер: 0, фрагменты: 0, хэш: "неверный")] {
            var набор = НаборКадров(); try набор.начало()
            try набор.кадр(3, кодировать(фиксация))
            try отклонить(набор.байты)
        }
        let заголовок = try кодировать(ОписаниеНаблюдения(идентификатор: "json", тип: "байты"))
        for лишнее in [Data("{\"лишнее\":1,".utf8) + заголовок.dropFirst(),
                        Data("{\"тип\":\"байты\",".utf8) + заголовок.dropFirst()] {
            var набор = НаборКадров(); набор.кадр(1, лишнее)
            try отклонить(набор.байты)
        }
        var неизвестный = НаборКадров(); неизвестный.кадр(255, Data("{}".utf8))
        try отклонить(неизвестный.байты)
    }

    @Test func длиныПроверяютсяДоЧтенияPayload() throws {
        for длина in [UInt32(Пределы.заголовок + 1), UInt32.max] {
            var префикс = Data([79, 66, 83, 49, 1, 0, 0, 0])
            var число = длина.bigEndian
            withUnsafeBytes(of: &число) { префикс.append(contentsOf: $0) }
            префикс.append(Data(repeating: 0, count: 12))
            let байты = Data("FUMOBS01".utf8) + префикс + Data(SHA256.hash(data: префикс))
            try отклонить(байты, .предел) // На диске вообще нет огромного заголовка.
        }
        var начало = НаборКадров(); try начало.начало()
        var префикс = Data([79, 66, 83, 49, 2, 0, 0, 0, 0, 0, 0, 2])
        var длина = UInt32.max.bigEndian
        withUnsafeBytes(of: &длина) { префикс.append(contentsOf: $0) }
        префикс.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
        try отклонить(начало.байты + префикс + Data(SHA256.hash(data: префикс)), .предел)
    }

    @Test func совокупныеЛимитыЗаписейИФрагментов() throws {
        var записи = НаборКадров()
        for номер in 0..<Пределы.записи { try записи.начало(String(номер)); try записи.конец() }
        try записи.начало("сверх-предела")
        try отклонить(записи.байты, .предел)
        var фрагменты = НаборКадров(); try фрагменты.начало()
        for номер in 0...Пределы.фрагменты {
            try фрагменты.кадр(2, кодировать(Фрагмент(номер: номер, смещение: UInt64(номер))), Data([7]))
        }
        try отклонить(фрагменты.байты, .предел)
    }

    @Test func лимитыSparseФайловИСпецификацииДоВыделенияПамяти() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let дескриптор = open(файл.path, O_CREAT | O_EXCL | O_RDWR | O_CLOEXEC, 0o600)
        defer { _ = close(дескриптор) }
        #expect(ftruncate(дескриптор, off_t(Пределы.сегмент) + 1) == 0)
        #expect(throws: ОшибкаКонтейнера.предел) { try Сегмент(кореньДанных: путь, запись: true) }
        #expect(ftruncate(дескриптор, off_t(Пределы.объект) + 1) == 0)
        #expect(throws: ОшибкаКонтейнера.предел) { try прочитатьВход(файл.path) }
        #expect(ftruncate(дескриптор, 65_537) == 0)
        #expect(throws: ОшибкаКонтейнера.предел) { try прочитатьВход(файл.path, предел: 65_536) }
        #expect(throws: ОшибкаКонтейнера.предел) { try прочитатьВход(файл.path, предел: Int.max) }
        #expect(throws: ОшибкаКонтейнера.предел) { try прочитатьВход(файл.path, предел: -1) }
    }

    @Test func совокупныйПределОбъектаДоЧтенияСледующегоФрагмента() throws {
        var набор = НаборКадров(); try набор.начало()
        let мегабайт = Data(repeating: 13, count: Пределы.фрагмент)
        for номер in 0..<64 {
            try набор.кадр(2, кодировать(Фрагмент(номер: номер, смещение: UInt64(номер * Пределы.фрагмент))), мегабайт)
        }
        // Только префикс следующего кадра; payload вообще не материализован.
        var префикс = Data([79, 66, 83, 49, 2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1])
        префикс.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 65])
        набор.байты.append(префикс); набор.байты.append(contentsOf: SHA256.hash(data: префикс))
        try отклонить(набор.байты, .предел)
    }

    @Test func небезопасныеФайлыИПути() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let цель = путь.appendingPathComponent("цель")
        try Data("FUMOBS01".utf8).write(to: цель)
        #expect(symlink("цель", файл.path) == 0)
        #expect(throws: (any Error).self) { try Сегмент(кореньДанных: путь, запись: true) }
        #expect(unlink(файл.path) == 0)
        #expect(link(цель.path, файл.path) == 0)
        #expect(throws: ОшибкаКонтейнера.небезопасныйПуть) { try Сегмент(кореньДанных: путь, запись: true) }
        #expect(unlink(файл.path) == 0)
        #expect(mkfifo(файл.path, 0o600) == 0)
        #expect(throws: ОшибкаКонтейнера.небезопасныйПуть) { try Сегмент(кореньДанных: путь, запись: true) }
        let ссылка = путь.appendingPathComponent("ссылка")
        #expect(symlink(путь.path, ссылка.path) == 0)
        #expect(throws: (any Error).self) { try Сегмент(кореньДанных: ссылка, запись: true) }
        #expect(chmod(путь.path, 0o777) == 0)
        #expect(throws: ОшибкаКонтейнера.небезопасныйПуть) { try Сегмент(кореньДанных: путь, запись: true) }
        #expect(chmod(путь.path, 0o700) == 0)
    }
}
