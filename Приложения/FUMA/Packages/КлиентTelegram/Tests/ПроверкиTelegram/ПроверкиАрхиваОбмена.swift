import Foundation
import Testing
import КонтейнерНаблюдений
@testable import КлиентTelegram

private final class НаблюдательСыройОтправки: ТранспортБиблиотеки, @unchecked Sendable {
    let корень: URL
    private let замок = NSLock()
    private var вход: [Data] = []
    init(_ корень: URL) { self.корень = корень }
    func создатьКлиента() -> Int32 { 1 }
    func отправить(клиент: Int32, запрос: Data) throws {
        // Проверяется внутри нижнего send, до закрытия и записи аварийного хвоста.
        let путь = корень.appendingPathComponent("обмен/сегмент.fumobs")
        #expect(FileManager.default.fileExists(atPath: путь.path))
        #expect(try ЗначениеДанных.прочитать(запрос)["@extra"]?.строка != nil)
        let тип = try ЗначениеДанных.прочитать(запрос).тип
        if тип == "close" {
            замок.withLock { вход.append(Data("{\"@type\":\"updateAuthorizationState\",\"@client_id\":1,\"authorization_state\":{\"@type\":\"authorizationStateClosed\"}}".utf8)) }
        }
    }
    func принять(таймАут: Double) throws -> Data? {
        if let байты = замок.withLock({ вход.isEmpty ? nil : вход.removeFirst() }) { return байты }
        Thread.sleep(forTimeInterval: min(таймАут, 0.01))
        return nil
    }
}

func сыройАрхивУжеСуществуетВнутриНижнейОтправки() async throws {
    let корень = try создатьПриватныйКаталог()
    defer { try? FileManager.default.removeItem(at: корень) }
    let среда = try await СредаКлиента.начать(транспорт: НаблюдательСыройОтправки(корень),
        корень: корень, ключ: Data(repeating: 19, count: 32))
    _ = try await среда.добавитьКлиента()
    let итог = try await среда.закрыть()
    #expect(итог.всеЗакрыты && !итог.требуетсяРазбор)
    let архив = try АрхивОбмена.прочитать(корень: корень, ключ: Data(repeating: 19, count: 32), привязка: .синтетическийТранспорт)
    #expect(архив.filter { $0.направление == .исходящееНамерение }.count == 2)
    #expect(архив.filter { $0.направление == .входящиеБайты }.count == 1)
}

private final class БайтовыйТранспортАрхива: ТранспортБиблиотеки, @unchecked Sendable {
    private let замок = NSLock()
    private var вход: [Data]
    private var отправки: [Data] = []
    private var приёмы = 0
    var передОтправкой: (@Sendable (Data) throws -> Void)?
    init(_ вход: [Data] = []) { self.вход = вход }
    func создатьКлиента() -> Int32 { 1 }
    func отправить(клиент: Int32, запрос: Data) throws {
        try передОтправкой?(запрос)
        замок.withLock { отправки.append(запрос) }
    }
    func принять(таймАут: Double) throws -> Data? { замок.withLock { приёмы += 1; return вход.isEmpty ? nil : вход.removeFirst() } }
    var количествоОтправок: Int { замок.withLock { отправки.count } }
    var количествоПриёмов: Int { замок.withLock { приёмы } }
}

private final class ОтказОперацииАрхива: @unchecked Sendable {
    private let замок = NSLock()
    private var включён = false
    func включить() { замок.withLock { включён = true } }
    func проверить() throws { if замок.withLock({ включён }) { throw ОшибкаКлиента.требуетсяРазбор } }
}

@Test func архивСохраняетТочныеДублиДоНижнейОтправкиИЛюбыеВходящиеБайты() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let ключ = Data(repeating: 21, count: 32)
    let архив = try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт)
    let запрос = Data(" {\"@type\":\"getAuthorizationState\",\"@extra\":\"literal-ё\"} \n".utf8)
    let вход = [Data([0xff, 0, 0xfe]), Data("{malformed".utf8), Data("{\"@extra\":\"unknown\"}".utf8), Data("{\"@type\":\"error\",\"code\":401}".utf8), Data("{\"@client_id\":9999}".utf8), запрос, запрос]
    let низ = БайтовыйТранспортАрхива(вход)
    низ.передОтправкой = { данные in
        let сохранённые = try архив.снимок().filter { $0.направление == .исходящееНамерение }
        #expect(сохранённые.last?.байты == данные)
    }
    let транспорт = АрхивирующийТранспорт(низ, архив: архив)
    try транспорт.отправить(клиент: 7, запрос: запрос)
    try транспорт.отправить(клиент: 7, запрос: запрос)
    for данные in вход { #expect(try транспорт.принять(таймАут: 0.1) == данные) }
    let снимок = try архив.снимок()
    #expect(снимок.filter { $0.вид == "кадр" }.map(\.байты) == [запрос, запрос] + вход)
    #expect(снимок.map(\.порядок) == Array(0..<снимок.count))
    try архив.закончитьПоколение()
    #expect(throws: (any Error).self) { try архив.сохранить(запрос, направление: .исходящееНамерение, клиент: 7) }
    #expect(throws: (any Error).self) { try архив.закончитьПоколение() }
    архив.закрыть()
    #expect(try АрхивОбмена.прочитать(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт).filter { $0.вид == "кадр" }.map(\.байты) == [запрос, запрос] + вход)
    let шифротекст = try Data(contentsOf: корень.appendingPathComponent("обмен/сегмент.fumobs"))
    #expect(шифротекст.range(of: запрос) == nil)
    #expect(throws: (any Error).self) { try АрхивОбмена.прочитать(корень: корень, ключ: Data(repeating: 22, count: 32), привязка: .синтетическийТранспорт) }
    let восстановленный = try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт)
    #expect(низ.количествоОтправок == 2)
    восстановленный.закрыть()
}

@Test(arguments: [false, true]) func отказЗаписиИСинхронизацииБлокируетНижнююОтправку(_ запись: Bool) throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let отказ = ОтказОперацииАрхива(); var операции = ФайловыеОперации.системные
    if запись { операции.запись = { дескриптор, данные in try отказ.проверить(); return try ФайловыеОперации.системные.запись(дескриптор, данные) } }
    else { операции.синхронизация = { дескриптор in try отказ.проверить(); try ФайловыеОперации.системные.синхронизация(дескриптор) } }
    let архив = try АрхивОбмена(корень: корень, ключ: Data(repeating: 23, count: 32), привязка: .синтетическийТранспорт, операции: операции)
    defer { архив.закрыть() }
    let низ = БайтовыйТранспортАрхива(), транспорт = АрхивирующийТранспорт(низ, архив: архив)
    отказ.включить()
    #expect(throws: (any Error).self) { try транспорт.отправить(клиент: 1, запрос: Data("{}".utf8)) }
    #expect(низ.количествоОтправок == 0)
    #expect(throws: (any Error).self) { try транспорт.отправить(клиент: 1, запрос: Data("{}".utf8)) }
}

func проверитьОтказВходящегоАрхиваДоОчереди() async throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let отказ = ОтказОперацииАрхива(); var операции = ФайловыеОперации.системные
    операции.синхронизация = { дескриптор in try отказ.проверить(); try ФайловыеОперации.системные.синхронизация(дескриптор) }
    let архив = try АрхивОбмена(корень: корень, ключ: Data(repeating: 24, count: 32), привязка: .синтетическийТранспорт, операции: операции)
    defer { архив.закрыть() }
    let низ = БайтовыйТранспортАрхива([Data("{malformed".utf8), Data("{}".utf8)])
    let цикл = try ЦиклПриёма(транспорт: АрхивирующийТранспорт(низ, архив: архив)) { _ in Issue.record("Кадр не должен достигать обработчика") }
    отказ.включить(); try цикл.запустить()
    for _ in 0..<100 { if цикл.причинаОстановки != nil { break }; try await Task.sleep(for: .milliseconds(5)) }
    await цикл.остановить()
    #expect(низ.количествоПриёмов == 1)
    #expect(цикл.причинаОстановки != nil)
}

@Test(arguments: [false, true]) func частичныйИПовреждённыйАрхивНеПереписываются(_ повреждение: Bool) throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let ключ = Data(repeating: 25, count: 32)
    let архив = try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт)
    try архив.сохранить(Data([0xff, 1]), направление: .входящиеБайты); архив.закрыть()
    let файл = корень.appendingPathComponent("обмен/сегмент.fumobs")
    var байты = try Data(contentsOf: файл)
    if повреждение { байты[байты.count / 2] ^= 1 } else { байты.append(Data([1, 2, 3])) }
    try байты.write(to: файл)
    #expect(throws: (any Error).self) { try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт) }
    #expect(try Data(contentsOf: файл) == байты)
}

@Test func другаяПривязкаНеМеняетСуществующийАрхив() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let ключ = Data(repeating: 26, count: 32)
    let архив = try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт); архив.закрыть()
    let файл = корень.appendingPathComponent("обмен/сегмент.fumobs"), до = try Data(contentsOf: файл)
    let другая = ПривязкаБиблиотеки(происхождение: "другая-синтетика", библиотекаШа256: nil, размерБиблиотеки: nil, квитанцияШа256: хэшОбмена(Data()), сыраяКвитанция: Data())
    #expect(throws: (any Error).self) { try АрхивОбмена(корень: корень, ключ: ключ, привязка: другая) }
    #expect(try Data(contentsOf: файл) == до)
}

@Test func повторПослеОтказаСинхронизацииРодителяНеСоздаётСегментДоБарьера() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    var операции = ФайловыеОперации.системные
    операции.синхронизация = { _ in throw ОшибкаКлиента.требуетсяРазбор }
    for _ in 0..<2 {
        #expect(throws: (any Error).self) { try АрхивОбмена(корень: корень, ключ: Data(repeating: 28, count: 32), привязка: .синтетическийТранспорт, операции: операции) }
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("обмен/сегмент.fumobs").path))
    }
    let успешный = try АрхивОбмена(корень: корень, ключ: Data(repeating: 28, count: 32), привязка: .синтетическийТранспорт)
    успешный.закрыть()
}

private final class ТранспортНескопированногоОтвета: ТранспортБиблиотеки, Sendable {
    func создатьКлиента() -> Int32 { 1 }
    func отправить(клиент: Int32, запрос: Data) throws {}
    func принять(таймАут: Double) throws -> Data? { throw ОшибкаКлиента.превышенПредел }
}
@Test func нескопированномуОтветуСоответствуетРазрывБезВыдуманныхБайтов() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let архив = try АрхивОбмена(корень: корень, ключ: Data(repeating: 29, count: 32), привязка: .синтетическийТранспорт)
    defer { архив.закрыть() }
    let транспорт = АрхивирующийТранспорт(ТранспортНескопированногоОтвета(), архив: архив)
    #expect(throws: ОшибкаКлиента.превышенПредел) { try транспорт.принять(таймАут: 0.1) }
    let снимок = try архив.снимок()
    #expect(снимок.last?.вид == "разрыв" && снимок.last?.байты == nil && снимок.last?.разрыв != nil)
}

@Test func прежнийСегментБезПривязкиНеПолучаетЕёЗаднимЧислом() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let обмен = корень.appendingPathComponent("обмен")
    try FileManager.default.createDirectory(at: обмен, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    let пустой = try Сегмент(кореньДанных: обмен, запись: true); пустой.закрыть()
    let путь = обмен.appendingPathComponent("сегмент.fumobs"), до = try Data(contentsOf: путь)
    #expect(throws: (any Error).self) { try АрхивОбмена(корень: корень, ключ: Data(repeating: 30, count: 32), привязка: .синтетическийТранспорт) }
    #expect(try Data(contentsOf: путь) == до)
}

@Test func конкурентныйПустойСегментНеПолучаетПривязкуЗаднимЧислом() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let обмен = корень.appendingPathComponent("обмен")
    let путь = обмен.appendingPathComponent("сегмент.fumobs")
    var снимокКонкурента = Data()
    #expect(throws: ОшибкаКлиента.требуетсяРазбор) {
        let архив = try АрхивОбмена(корень: корень, ключ: Data(repeating: 31, count: 32), привязка: .синтетическийТранспорт,
            передОткрытиемСегмента: {
                // Другой владелец успел создать и синхронизировать сигнатуру,
                // затем остановился до первой привязки и освободил flock.
                let конкурент = try Сегмент(кореньДанных: обмен, запись: true)
                конкурент.закрыть()
                снимокКонкурента = try Data(contentsOf: путь)
            })
        архив.закрыть()
    }
    #expect(!снимокКонкурента.isEmpty)
    #expect(try Data(contentsOf: путь) == снимокКонкурента)
}

func проверитьХвостСАрхивом() async throws {
    for отмена in [false, true] {
        let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
        let архив = try АрхивОбмена(корень: корень, ключ: Data(repeating: 27, count: 32), привязка: .синтетическийТранспорт)
        defer { архив.закрыть() }
        let кадры = отмена ? [Data([1]), Data([2]), Data([3]), Data([4])] : [Data([1]), Data(repeating: 2, count: 9), Data([3])]
        let низ = БайтовыйТранспортАрхива(кадры)
        let цикл = try ЦиклПриёма(транспорт: АрхивирующийТранспорт(низ, архив: архив), ёмкость: 2, пределБайтов: 8) { _ in
            if отмена { try await Task.sleep(for: .seconds(5)) }
        }
        try цикл.запустить()
        for _ in 0..<200 {
            if отмена ? низ.количествоПриёмов >= 4 : цикл.причинаОстановки != nil { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        await цикл.остановить(отменитьОбработку: отмена)
        let записанные = try архив.снимок().filter { $0.вид == "кадр" }.compactMap(\.байты)
        #expect(записанные == (отмена ? кадры : Array(кадры.prefix(2))))
        #expect(отмена || цикл.причинаОстановки == .превышенПредел)
    }
}
