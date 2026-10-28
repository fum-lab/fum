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
