import Foundation
import Testing
@testable import КлиентTelegram

final class ЗаписывающийТранспорт: ТранспортБиблиотеки, @unchecked Sendable {
    private let замок = NSLock()
    private var следующий: Int32 = 1
    private var записи: [(Int32, ЗначениеДанных)] = []
    var отправленные: [(Int32, ЗначениеДанных)] { замок.withLock { записи } }
    func создатьКлиента() -> Int32 { замок.withLock { defer { следующий += 1 }; return следующий } }
    func отправить(клиент: Int32, запрос: Data) throws {
        let объект = try ЗначениеДанных.прочитать(запрос)
        замок.withLock { записи.append((клиент, объект)) }
    }
    func принять(таймАут: Double) throws -> Data? { Thread.sleep(forTimeInterval: таймАут); return nil }
}

func доставить(_ событие: ЗначениеДанных, клиент: Int32, ядро: ЯдроКлиента, запрос: ЗначениеДанных? = nil) async throws {
    var объект = try событие.добавив("@client_id", .число(Int64(клиент)))
    if let корреляция = запрос?["@extra"] { объект = try объект.добавив("@extra", корреляция) }
    try await ядро.принять(объект.байты())
}

@Test func клиентыКорреляцияАвторизацияЧтениеИЛокальныйПредпросмотр() async throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let транспорт = ЗаписывающийТранспорт()
    let ядро = try ЯдроКлиента(транспорт: транспорт, корень: каталог, ключ: Data(repeating: 1, count: 32))
    let первый = try await ядро.добавитьКлиента(аккаунт: 17)
    let второй = try await ядро.добавитьКлиента(аккаунт: 18)
    #expect(первый != второй)
    let начальный = транспорт.отправленные[0].1
    try await доставить(.типа("authorizationStateWaitTdlibParameters"), клиент: первый, ядро: ядро, запрос: начальный)
    #expect(try await ядро.состояние(первый).авторизация == .параметры)
    #expect(try await ядро.состояние(второй).авторизация == .неизвестно)
    await #expect(throws: ОшибкаКлиента.self) { try await ядро.загрузитьЧаты(первый) }
    let черновик = Черновик(аккаунт: 17, канал: -100001, действие: .текст("Только местный preview"), цель: "Открытый сценарий")
    let до = транспорт.отправленные.count
    try await ядро.сохранитьЧерновик(черновик)
    #expect(try await ядро.предпросмотр(черновик.идентификатор) == черновик)
    #expect(транспорт.отправленные.count == до)
    try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateReady")]), клиент: первый, ядро: ядро)
    #expect(транспорт.отправленные.last?.1.тип == "getMe")
    try await доставить(.типа("user", ["id": .число(17)]), клиент: первый, ядро: ядро, запрос: транспорт.отправленные.last!.1)
    _ = try await ядро.загрузитьЧаты(первый)
    let история = try await ядро.прочитатьИсторию(первый, чат: -100001, от: 0, смещение: 0, предел: 100, толькоМестная: true)
    #expect(транспорт.отправленные.last?.1["only_local"]?.логическое == true)
    #expect(транспорт.отправленные.last?.1["@extra"]?.строка == история)
    await #expect(throws: ОшибкаКлиента.self) { try await ядро.прочитатьИсторию(первый, чат: -100001, от: 0, смещение: 0, предел: 101, толькоМестная: true) }
    try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateLoggingOut")]), клиент: первый, ядро: ядро)
    await #expect(throws: ОшибкаКлиента.self) { try await ядро.загрузитьЧаты(первый) }
    try await ядро.начатьЗакрытие()
    try await доставить(.типа("ok"), клиент: первый, ядро: ядро, запрос: транспорт.отправленные.suffix(2).first!.1)
    #expect(await ядро.всеЗакрыты == false)
    for клиент in [первый, второй] {
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateClosed")]), клиент: клиент, ядро: ядро)
    }
    #expect(await ядро.всеЗакрыты)
    await ядро.закрытьЖурнал()
}
