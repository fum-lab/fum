import Foundation
import Testing
@testable import КлиентTelegram

private final class ТранспортЗакрытия: ТранспортБиблиотеки, @unchecked Sendable {
    private let условие = NSCondition()
    private var следующий: Int32 = 1
    private var очередь: [Data] = []
    private var записи: [ЗначениеДанных] = []
    let завершать: Bool
    init(завершать: Bool = true) { self.завершать = завершать }
    var отправленные: [ЗначениеДанных] { условие.withLock { записи } }
    var создано: Int { условие.withLock { Int(следующий - 1) } }
    func создатьКлиента() -> Int32 { условие.withLock { defer { следующий += 1 }; return следующий } }
    func отправить(клиент: Int32, запрос: Data) throws {
        let данные = try ЗначениеДанных.прочитать(запрос)
        try условие.withLock {
            записи.append(данные)
            func добавить(_ ответ: ЗначениеДанных, корреляция: Bool) throws {
                var ответ = try ответ.добавив("@client_id", .число(Int64(клиент)))
                if корреляция { ответ = try ответ.добавив("@extra", данные["@extra"]!) }
                очередь.append(try ответ.байты())
            }
            if данные.тип == "getAuthorizationState" {
                try добавить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateWaitTdlibParameters")]), корреляция: false)
                try добавить(.типа("authorizationStateWaitTdlibParameters"), корреляция: true)
            } else if данные.тип == "close" {
                try добавить(.типа("ok"), корреляция: true)
                try добавить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateClosing")]), корреляция: false)
                if завершать { try добавить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateClosed")]), корреляция: false) }
            } else { throw ОшибкаКлиента.неподдерживаемоеДействие }
            условие.broadcast()
        }
    }
    func принять(таймАут: Double) throws -> Data? {
        условие.lock(); defer { условие.unlock() }
        if очередь.isEmpty { _ = условие.wait(until: Date().addingTimeInterval(таймАут)) }
        guard !очередь.isEmpty else { return nil }
        let строка = String(decoding: очередь.removeFirst(), as: UTF8.self)
        return try строка.withCString { try скопироватьОтвет($0, предел: 4096) }
    }
}

/// Один вызов из общей последовательной проверки lease, чтобы тесты не конкурировали за процесс.
func проверитьСредуКлиента() async throws {
    for _ in 0..<2 {
        let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
        let другойКаталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: другойКаталог) }
        let транспорт = ТранспортЗакрытия()
        let среда = try await СредаКлиента.начать(транспорт: транспорт, корень: каталог, ключ: Data(repeating: 1, count: 32))
        let другой = ТранспортЗакрытия()
        await #expect(throws: ОшибкаКлиента.ужеЕстьПриёмник) {
            try await СредаКлиента.начать(транспорт: другой, корень: другойКаталог, ключ: Data(repeating: 2, count: 32))
        }
        #expect(другой.создано == 0)
        let клиент = try await среда.добавитьКлиента()
        let ответ = try await среда.дождатьсяНачальногоОтвета(клиент, таймАут: 1)
        #expect(ответ.клиент == клиент && ответ.корреляция == транспорт.отправленные[0]["@extra"]?.строка)
        #expect(ответ.тип == "authorizationStateWaitTdlibParameters")
        async let первый = среда.закрыть(таймАут: 1)
        async let второй = среда.закрыть(таймАут: 1)
        let итоги = try await (первый, второй)
        #expect(итоги.0 == итоги.1 && итоги.0.всеЗакрыты && !итоги.0.требуетсяРазбор)
        #expect(транспорт.отправленные.map(\.тип) == ["getAuthorizationState", "close"])
    }
    // Последняя граница: аварийное владение сохраняется до завершения процесса теста.
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let ключ = Data(repeating: 3, count: 32)
    let среда = try await СредаКлиента.начать(транспорт: ТранспортЗакрытия(завершать: false), корень: каталог, ключ: ключ)
    _ = try await среда.добавитьКлиента()
    let итог = try await среда.закрыть(таймАут: 0.05)
    #expect(!итог.всеЗакрыты && итог.требуетсяРазбор)
    let журнал = try ЛокальныйЖурнал(корень: каталог, ключ: ключ); defer { журнал.закрыть() }
    #expect(try журнал.восстановить().contains { if case .разрыв = $0 { true } else { false } })
    let следующий = try ЦиклПриёма(транспорт: ТранспортЗакрытия()) { _ in }
    #expect(throws: ОшибкаКлиента.ужеЕстьПриёмник) { try следующий.запустить() }
}
