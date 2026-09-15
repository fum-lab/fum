import Foundation
import Testing
@testable import КаналыМАКС

private actor ТранспортСценария: ТранспортКаналов {
    var вызовы = 0
    let исход: ОтветТранспорта
    init(_ исход: ОтветТранспорта) { self.исход = исход }
    func выполнить(_ запрос: ПодготовленныйЗапрос) async -> ОтветТранспорта {
        вызовы += 1
        return исход
    }
}

@Test func подготовкаПубликацииБезСекрета() throws {
    let запрос = try ПодготовленныйЗапрос.публикация(канал: 42, текст: "Привет")
    #expect(запрос.адрес.absoluteString == "https://platform-api2.max.ru/messages?chat_id=42")
    #expect(запрос.метод == "POST")
    #expect(запрос.требуетАвторизации)
    #expect(запрос.заголовки["Authorization"] == nil)
    let тело = try #require(JSONSerialization.jsonObject(with: запрос.тело) as? [String: Any])
    #expect(тело["text"] as? String == "Привет")
    #expect(тело["notify"] as? Bool == true)
    #expect(throws: ОшибкаВхода.self) { try ПодготовленныйЗапрос.публикация(канал: 42, текст: "") }
    #expect(throws: ОшибкаВхода.self) { try ПодготовленныйЗапрос.публикация(канал: 42, текст: String(repeating: "я", count: 4001)) }
}

@Test func ограниченияПодписки() throws {
    let запрос = try ПодготовленныйЗапрос.подписка(адрес: "https://example.com/events")
    #expect(запрос.адрес.path == "/subscriptions")
    for адрес in ["http://example.com", "https://example.com:443/a", "https://user:pass@example.com", "https://example.com/#x"] {
        #expect(throws: ОшибкаВхода.self) { try ПодготовленныйЗапрос.подписка(адрес: адрес) }
    }
}

@Test func неизвестныйИсходНеПовторяется() async throws {
    let транспорт = ТранспортСценария(.неизвестно)
    let адаптер = АдаптерКаналов(транспорт: транспорт)
    try await адаптер.подготовить(идентификатор: "пост", канал: 42, текст: "Пост")
    #expect(await адаптер.история("пост") == [.подготовлено])
    #expect(try await адаптер.отправить("пост", время: 0) == .неизвестно)
    #expect(await адаптер.история("пост") == [.подготовлено, .отправлено, .неизвестно])
    #expect(try await адаптер.отправить("пост", время: 2) == .неизвестно)
    #expect(await транспорт.вызовы == 1)
}

@Test func подтверждениеИАвторизация() async throws {
    let байты = Data(#"{"message":{"recipient":{"chat_id":42},"body":{"mid":"m-1"}}}"#.utf8)
    for (ответ, ожидаемый) in [
        (ОтветТранспорта.ответ(код: 200, тело: байты), СостояниеПубликации.подтверждено("m-1")),
        (.ответ(код: 401, тело: Data()), .отказАвторизации),
        (.ответ(код: 403, тело: Data()), .отказАвторизации),
        (.ответ(код: 500, тело: Data()), .неизвестно),
        (.ответ(код: 200, тело: Data("{}".utf8)), .неизвестно),
        (.ответ(код: 429, тело: Data()), .отклонено(429))
    ] {
        let транспорт = ТранспортСценария(ответ)
        let адаптер = АдаптерКаналов(транспорт: транспорт)
        try await адаптер.подготовить(идентификатор: "пост", канал: 42, текст: "Пост")
        #expect(try await адаптер.отправить("пост", время: 0) == ожидаемый)
        _ = try await адаптер.отправить("пост", время: 10)
        #expect(await транспорт.вызовы == 1)
    }
}

@Test func скользящиеЛимитыИОбратноеВремя() throws {
    var лимит = ОграничительЧастоты()
    #expect(try лимит.допустить(канал: 42, время: 0))
    #expect(try лимит.допустить(канал: 42, время: 0))
    #expect(try !лимит.допустить(канал: 42, время: 0.999))
    #expect(try лимит.допустить(канал: 42, время: 1))
    #expect(throws: ОшибкаВхода.self) { try лимит.допустить(канал: 42, время: 0) }
    #expect(throws: ОшибкаВхода.self) { try лимит.допустить(канал: 42, время: .nan) }
    var общий = ОграничительЧастоты()
    for канал in 0..<30 { #expect(try общий.допустить(канал: Int64(канал), время: 0)) }
    #expect(try !общий.допустить(канал: 99, время: 0))
    #expect(try общий.допустить(канал: 99, время: 1))
}

@Test func событияКаналаИДедупликация() throws {
    var реестр = РеестрКаналов(ёмкость: 3)
    let добавление = Data(#"{"update_type":"bot_added","timestamp":1,"chat_id":42,"is_channel":true,"user":{"user_id":7}}"#.utf8)
    #expect(try реестр.принять(добавление) == .применено)
    #expect(try реестр.принять(добавление) == .повтор)
    #expect(реестр.каналы[42]?.подключён == true)
    #expect(реестр.каналы[42]?.правоПубликацииПодтверждено == false)
    let изменение = Data(#"{"update_type":"chat_title_changed","timestamp":2,"chat_id":42,"title":"FUM","user":{"user_id":7}}"#.utf8)
    #expect(try реестр.принять(изменение) == .применено)
    #expect(реестр.каналы[42]?.название == "FUM")
    #expect(try реестр.принять(Data(#"{"update_type":"bot_removed","timestamp":3,"chat_id":42,"user":{"user_id":7}}"#.utf8)) == .применено)
    #expect(реестр.каналы[42]?.подключён == false)
    #expect(try реестр.принять(добавление) == .повтор)
}

@Test func группаНеСтановитсяКаналомИНеизвестныйТипСохраняется() throws {
    var реестр = РеестрКаналов(ёмкость: 2)
    #expect(try реестр.принять(Data(#"{"update_type":"bot_added","timestamp":1,"chat_id":5,"is_channel":false}"#.utf8)) == .пропущено)
    #expect(реестр.каналы.isEmpty)
    #expect(try реестр.принять(Data(#"{"update_type":"future_event","timestamp":2}"#.utf8)) == .неизвестныйТип("future_event"))
    #expect(throws: (any Error).self) { try реестр.принять(Data(#"{"update_type":"bot_added","timestamp":1,"chat_id":42}"#.utf8)) }
}

private actor ЗадержанныйТранспорт: ТранспортКаналов {
    var вызовы = 0
    var продолжение: CheckedContinuation<ОтветТранспорта, Never>?
    func выполнить(_ запрос: ПодготовленныйЗапрос) async -> ОтветТранспорта {
        вызовы += 1
        return await withCheckedContinuation { продолжение = $0 }
    }
    func завершить() { продолжение?.resume(returning: .неизвестно); продолжение = nil }
}

@Test func повторВоВремяОтправки() async throws {
    let транспорт = ЗадержанныйТранспорт()
    let адаптер = АдаптерКаналов(транспорт: транспорт)
    try await адаптер.подготовить(идентификатор: "один", канал: 1, текст: "Пост")
    let задача = Task { try await адаптер.отправить("один", время: 0) }
    while await транспорт.вызовы == 0 { await Task.yield() }
    #expect(try await адаптер.отправить("один", время: 1) == .отправлено)
    await транспорт.завершить()
    #expect(try await задача.value == .неизвестно)
    #expect(await транспорт.вызовы == 1)
}

@Test func лимитОставляетЗапросПодготовленным() async throws {
    let транспорт = ТранспортСценария(.неизвестно)
    let адаптер = АдаптерКаналов(транспорт: транспорт)
    for номер in 0..<3 {
        try await адаптер.подготовить(идентификатор: String(номер), канал: 1, текст: "Пост")
        _ = try await адаптер.отправить(String(номер), время: 0)
    }
    #expect(await адаптер.история("2") == [.подготовлено])
    #expect(await транспорт.вызовы == 2)
    #expect(try await адаптер.отправить("2", время: 1) == .неизвестно)
    #expect(await транспорт.вызовы == 3)
}

@Test func чужоеПодтверждениеНеПринимается() async throws {
    let транспорт = ТранспортСценария(.ответ(код: 200, тело: Data(#"{"message":{"recipient":{"chat_id":99},"body":{"mid":"m"}}}"#.utf8)))
    let адаптер = АдаптерКаналов(транспорт: транспорт)
    try await адаптер.подготовить(идентификатор: "один", канал: 42, текст: "Пост")
    #expect(try await адаптер.отправить("один", время: 0) == .неизвестно)
}

@Test func перестановкаПолейИУстаревшееСобытие() throws {
    var реестр = РеестрКаналов(ёмкость: 1)
    _ = try реестр.принять(Data(#"{"update_type":"bot_added","timestamp":5,"chat_id":42,"is_channel":true}"#.utf8))
    #expect(try реестр.принять(Data(#"{ "is_channel":true,"chat_id":42,"timestamp":5,"update_type":"bot_added" }"#.utf8)) == .повтор)
    _ = try реестр.принять(Data(#"{"update_type":"bot_removed","timestamp":6,"chat_id":42}"#.utf8))
    #expect(try реестр.принять(Data(#"{"update_type":"bot_added","timestamp":5,"chat_id":42,"is_channel":true}"#.utf8)) == .устарело)
    #expect(реестр.каналы[42]?.подключён == false)
}

@Test func профильОбработки() throws {
    guard let путь = ProcessInfo.processInfo.environment["FUM_MAX_PROFILE"] else { return }
    let начало = ProcessInfo.processInfo.systemUptime
    var лимит = ОграничительЧастоты()
    var принято = 0
    for номер in 0..<100_000 {
        if try лимит.допустить(канал: Int64(номер % 100), время: Double(номер) / 1000) { принято += 1 }
    }
    let конецЛимита = ProcessInfo.processInfo.systemUptime
    var реестр = РеестрКаналов()
    let событие = Data(#"{"update_type":"bot_added","timestamp":1,"chat_id":42,"is_channel":true}"#.utf8)
    var повторы = 0
    for _ in 0..<10_000 { if try реестр.принять(событие) == .повтор { повторы += 1 } }
    let конец = ProcessInfo.processInfo.systemUptime
    #expect(принято == 3000)
    #expect(повторы == 9999)
    let отчёт: [String: Any] = ["схема": "fum.профиль-каналов-макс.1", "входы_лимита": 100_000,
        "входы_событий": 10_000, "принято": принято, "повторы": повторы,
        "лимит_секунды": конецЛимита - начало, "события_секунды": конец - конецЛимита,
        "сборка_включена": false, "вложенные_интервалы": false]
    try JSONSerialization.data(withJSONObject: отчёт, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: путь))
}
