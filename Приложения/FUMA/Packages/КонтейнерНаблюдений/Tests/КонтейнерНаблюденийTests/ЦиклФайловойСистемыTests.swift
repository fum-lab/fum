import Foundation
import Darwin
import Testing
@testable import КонтейнерНаблюдений

@Test func циклФайловойСистемыСохраняетСнимокИПроисхождение() throws {
    let кореньВременных = FileManager.default.temporaryDirectory
    let источник = кореньВременных.appendingPathComponent("fs-first-source-\(UUID().uuidString)", isDirectory: true)
    let назначение = кореньВременных.appendingPathComponent("fs-first-destination-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: источник, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: назначение, withIntermediateDirectories: false)
    defer {
        try? FileManager.default.removeItem(at: источник)
        try? FileManager.default.removeItem(at: назначение)
    }
    #expect(chmod(источник.path, 0o700) == 0)
    #expect(chmod(назначение.path, 0o700) == 0)

    let файл = источник.appendingPathComponent("текст.txt")
    let ссылка = источник.appendingPathComponent("ссылка.txt")
    let исходныеБайты = Data("начало\n".utf8)
    let новыеБайты = Data("сохранённый текст ё🙂\n".utf8)
    try исходныеБайты.write(to: файл)
    #expect(chmod(файл.path, 0o600) == 0)
    #expect(symlink("текст.txt", ссылка.path) == 0)

    let первое = try НаблюдениеФайловойСистемы.наблюдать(
        корень: источник, источник: "fixture:fs-first-sensor")
    #expect(первое.границаСогласованности == .объектыПровереныПоОтдельностиОбщаяАтомарностьНеДоказана)
    #expect(первое.записи.count == 2)
    #expect(первое.записи.first(where: { $0.путь == "текст.txt" })?.хэш != nil)

    let дескриптор = open(файл.path, O_WRONLY | O_TRUNC | O_NOFOLLOW | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    defer { if дескриптор >= 0 { _ = Darwin.close(дескриптор) } }
    try новыеБайты.withUnsafeBytes { буфер in
        var смещение = 0
        while смещение < буфер.count {
            let число = Darwin.write(дескриптор, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
            if число < 0 && errno == EINTR { continue }
            guard число > 0 else { throw ОшибкаКонтейнера.система(errno) }
            смещение += число
        }
    }
    #expect(fsync(дескриптор) == 0)

    let второе = try НаблюдениеФайловойСистемы.наблюдать(
        корень: источник, источник: "fixture:fs-first-sensor", предшественник: первое)
    #expect(второе.предшественник == первое.идентификатор)
    let изменения = try НаблюдениеФайловойСистемы.сравнить(прежний: первое, новый: второе)
    #expect(изменения.map(\.путь) == ["текст.txt"])
    #expect(изменения.first?.вид == .изменён)

    let запись = try #require(второе.записи.first(where: { $0.путь == "текст.txt" }))
    #expect(запись.содержимое == новыеБайты)
    #expect(запись.режим == 0o600)
    let записьСсылки = try #require(второе.записи.first(where: { $0.путь == "ссылка.txt" }))
    #expect(записьСсылки.тип == .ссылка)
    #expect(записьСсылки.цельСсылки == "текст.txt")

    let план = try НаблюдениеФайловойСистемы.составитьПлан(из: второе)
    let результат = try НаблюдениеФайловойСистемы.перенести(по: план, в: назначение)
    #expect(результат.идентификаторСнимкаИсточника == второе.идентификатор)
    #expect(результат.хэшСнимкаПриёмника == второе.идентификатор)
    #expect(результат.количествоЗаписей == 2)

    let проверка = try НаблюдениеФайловойСистемы.проверитьСохранение(
        результата: результат, источник: источник, назначение: назначение, номерПовтора: 1)
    #expect(проверка.проверкаПовтора == 1)
    let повтор = try НаблюдениеФайловойСистемы.проверитьСохранение(
        результата: проверка, источник: источник, назначение: назначение, номерПовтора: 2)
    #expect(повтор.проверкаПовтора == 2)
    #expect(повтор.идентификаторСнимкаИсточника == результат.идентификаторСнимкаИсточника)
}

private final class ПоставщикСРостомПриОткрытии: ПоставщикСистемныхВызововФайловойСистемы {
    private let изменяемыйФайл: URL
    private(set) var ростВыполнен = false

    init(изменяемыйФайл: URL) {
        self.изменяемыйФайл = изменяемыйФайл
    }

    func fstat(_ дескриптор: Int32, _ сведения: UnsafeMutablePointer<stat>) -> Int32 {
        Darwin.fstat(дескриптор, сведения)
    }

    func fstatat(
        _ каталог: Int32,
        _ имя: String,
        _ сведения: UnsafeMutablePointer<stat>,
        _ флаги: Int32
    ) -> Int32 {
        имя.withCString { Darwin.fstatat(каталог, $0, сведения, флаги) }
    }

    func openat(_ каталог: Int32, _ имя: String, _ флаги: Int32) -> Int32 {
        let дескриптор = имя.withCString { Darwin.openat(каталог, $0, флаги) }
        guard имя == изменяемыйФайл.lastPathComponent, !ростВыполнен else { return дескриптор }
        let писатель = Darwin.open(изменяемыйФайл.path, O_WRONLY | O_APPEND | O_CLOEXEC | O_NOFOLLOW)
        guard писатель >= 0 else { return дескриптор }
        defer { _ = Darwin.close(писатель) }
        let добавка = Data("\nдетерминированный-рост\n".utf8)
        let результат = добавка.withUnsafeBytes { буфер in
            Darwin.write(писатель, буфер.baseAddress!, буфер.count)
        }
        ростВыполнен = результат == добавка.count
        return дескриптор
    }
}

@Test func наблюдательОтклоняетРостТогоЖеОбъектаМеждуПоискомИЧтением() throws {
    let источник = FileManager.default.temporaryDirectory
        .appendingPathComponent("fs-race-source-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: источник, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: источник) }
    #expect(chmod(источник.path, 0o700) == 0)

    let файл = источник.appendingPathComponent("рост.txt")
    try Data("исходные байты".utf8).write(to: файл)
    #expect(chmod(файл.path, 0o600) == 0)
    let поставщик = ПоставщикСРостомПриОткрытии(изменяемыйФайл: файл)

    #expect(throws: ОшибкаНаблюденияФайловойСистемы.источникИзменился) {
        try НаблюдениеФайловойСистемы.наблюдать(
            корень: источник,
            источник: "fixture:fs-race-same-inode",
            через: поставщик)
    }
    #expect(поставщик.ростВыполнен)
    #expect(try Data(contentsOf: файл).count > Data("исходные байты".utf8).count)
}

@Test func отказЧтенияПослеПереносаВозвращаетСвидетельствоИЗапрещаетПовтор() throws {
    let хранилище = FileManager.default.temporaryDirectory
    let источник = хранилище.appendingPathComponent("fs-unknown-source-\(UUID().uuidString)", isDirectory: true)
    let назначение = хранилище.appendingPathComponent("fs-unknown-destination-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: источник, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: назначение, withIntermediateDirectories: false)
    defer {
        try? FileManager.default.removeItem(at: источник)
        try? FileManager.default.removeItem(at: назначение)
    }
    #expect(chmod(источник.path, 0o700) == 0)
    #expect(chmod(назначение.path, 0o700) == 0)
    let исходноеСодержимое = Data("передача с неопределённым readback ё🙂\n".utf8)
    let исходныйФайл = источник.appendingPathComponent("свидетельство.txt")
    try исходноеСодержимое.write(to: исходныйФайл)
    #expect(chmod(исходныйФайл.path, 0o600) == 0)

    let снимок = try НаблюдениеФайловойСистемы.наблюдать(
        корень: источник, источник: "fixture:fs-unknown-readback")
    let план = try НаблюдениеФайловойСистемы.составитьПлан(из: снимок)
    do {
        _ = try НаблюдениеФайловойСистемы.перенести(
            по: план,
            в: назначение,
            прочитатьНазначение: { _, _ in
                throw ОшибкаНаблюденияФайловойСистемы.система(EIO)
            })
        Issue.record("После записи ожидался типизированный неизвестный исход.")
    } catch let ошибка as ОшибкаНаблюденияФайловойСистемы {
        guard case .неизвестныйИсходПереноса(let свидетельство) = ошибка else {
            Issue.record("Неизвестный исход переноса вернулся без намерения и данных для сверки: \(ошибка).")
            return
        }
        #expect(свидетельство.источник == план.источник)
        #expect(свидетельство.идентификаторСнимкаИсточника == план.идентификаторСнимка)
        #expect(свидетельство.хэшПлана == план.хэшПлана)
        #expect(свидетельство.назначение.standardizedFileURL.path == назначение.standardizedFileURL.path)
        #expect(свидетельство.стадия == .чтениеНазначения)
        #expect(свидетельство.фактическийИдентификаторСнимкаНазначения == nil)
        #expect(свидетельство.фактическиеЗаписиНазначения == nil)
        #expect(свидетельство.ожидаемыеЗаписи.map(\.путь) == ["свидетельство.txt"])
        #expect(свидетельство.ожидаемыеЗаписи.first?.тип == .файл)
        #expect(свидетельство.ожидаемыеЗаписи.first?.владелец == UInt32(geteuid()))
        #expect(свидетельство.ожидаемыеЗаписи.first?.режим == 0o600)
        #expect(свидетельство.ожидаемыеЗаписи.first?.размер == UInt64(исходноеСодержимое.count))
        #expect(свидетельство.ожидаемыеЗаписи.first?.хэш == план.записи.first?.хэш)
        #expect(!свидетельство.причина.isEmpty)
    }

    #expect(try Data(contentsOf: назначение.appendingPathComponent("свидетельство.txt")) == исходноеСодержимое)
    #expect(throws: ОшибкаНаблюденияФайловойСистемы.повторПереносаЗапрещён) {
        try НаблюдениеФайловойСистемы.перенести(по: план, в: назначение)
    }
    #expect(try Data(contentsOf: назначение.appendingPathComponent("свидетельство.txt")) == исходноеСодержимое)
}
