import CryptoKit
import Darwin
import Foundation
import Testing
import АрхивныйСнимокЗадачи
import КонтейнерНаблюдений

@Test func повторПослеНеяснойСинхронизацииВосстанавливаетПолныеБайты() throws {
    let адресФикстуры = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        .appendingPathComponent("Примеры/записанный-префикс.jsonl")
    let исходныйФайл = try Data(contentsOf: адресФикстуры)
    #expect(исходныйФайл.count == 480)
    #expect(хэш(исходныйФайл) == "72ee2e79981f0524c0fb9874ff7d7f64c4e57344999e23dd31b5129dae2abb16")
    #expect(исходныйФайл.last == 0x0a)

    let данные = Data(исходныйФайл.dropLast())
    #expect(данные.count == 479)

    let разбор = try выделитьРамкиПотока(данные)
    #expect(разбор.рамки.map(\.данные.count) == [104, 129])
    #expect(разбор.рамки.map(\.позиция.начало) == [0, 104])
    #expect(разбор.рамки.map(\.позиция.конец) == [104, 233])
    #expect(разбор.префикс.байты == 233)
    #expect(разбор.префикс.строки == 2)
    #expect(разбор.сыройХвост.count == 246)
    #expect(разбор.сыройХвост == Data(данные.suffix(246)))
    #expect(разбор.префикс.sha256 == хэш(Data(данные.prefix(233))))

    let временныйКаталог = FileManager.default.temporaryDirectory
        .appendingPathComponent("сохранённый-срез-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: временныйКаталог, withIntermediateDirectories: false)
    guard let физическийПуть = realpath(временныйКаталог.path, nil) else {
        throw ОшибкаКонтейнера.система(errno)
    }
    defer { free(физическийПуть) }
    let корень = URL(fileURLWithPath: String(cString: физическийПуть), isDirectory: true)
    defer { try? FileManager.default.removeItem(at: корень) }

    let подготовка = try Сегмент(кореньДанных: корень, запись: true)
    подготовка.закрыть()

    let описание = ОписаниеНаблюдения(
        идентификатор: "37e5a4e0-a477-4bd8-8574-4f78558e0a31",
        тип: "сохранение-префикса",
        версияСхемы: 1,
        источник: "Примеры/записанный-префикс.jsonl",
        время: "2026-10-26T18:20:52Z",
        спецификация: Data("размер=479;префикс=233;строки=2;хвост=246".utf8)
    )
    let маркерОтказа = UUID().uuidString
    let операции = ФайловыеОперации(
        запись: ФайловыеОперации.системные.запись,
        синхронизация: { дескриптор in
            try ФайловыеОперации.системные.синхронизация(дескриптор)
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(EIO),
                userInfo: ["маркерОтказа": маркерОтказа]
            )
        }
    )
    let писатель = try Сегмент(кореньДанных: корень, запись: true, создать: false, операции: операции)
    #expect {
        try писатель.добавить(описание, данные: данные)
    } throws: { ошибка in
        let ошибкаПроверки = ошибка as NSError
        return ошибкаПроверки.domain == NSPOSIXErrorDomain
            && ошибкаПроверки.code == Int(EIO)
            && ошибкаПроверки.userInfo["маркерОтказа"] as? String == маркерОтказа
    }
    #expect(писатель.записи.isEmpty)
    писатель.закрыть()

    let файлСегмента = корень.appendingPathComponent("сегмент.fumobs")
    let восстановленный = try Сегмент(кореньДанных: корень, запись: true, создать: false)
    defer { восстановленный.закрыть() }
    #expect(!восстановленный.естьХвост)
    #expect(восстановленный.записи.map(\.описание.идентификатор) == [описание.идентификатор])

    let восстановленныеДанные = try восстановленный.извлечь(описание.идентификатор)
    #expect(восстановленныеДанные == данные)
    #expect(хэш(восстановленныеДанные) == хэш(данные))

    let исходнаяКвитанция = try #require(восстановленный.записи.first)
    #expect(исходнаяКвитанция.описание == описание)
    #expect(исходнаяКвитанция.размер == UInt64(данные.count))
    #expect(исходнаяКвитанция.хэш == хэш(данные))

    let байтыДоПовтора = try Data(contentsOf: файлСегмента)
    let повторнаяКвитанция = try восстановленный.добавить(описание, данные: данные)
    #expect(повторнаяКвитанция == исходнаяКвитанция)
    #expect(восстановленный.записи == [исходнаяКвитанция])
    #expect(try Data(contentsOf: файлСегмента) == байтыДоПовтора)

    let другиеДанные = Data(данные.dropLast())
    #expect(throws: ОшибкаКонтейнера.конфликтИдентификатора) {
        try восстановленный.добавить(описание, данные: другиеДанные)
    }
    #expect(try Data(contentsOf: файлСегмента) == байтыДоПовтора)
    #expect(восстановленный.записи == [исходнаяКвитанция])
    #expect(try восстановленный.извлечь(описание.идентификатор) == данные)
}

private func хэш(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
