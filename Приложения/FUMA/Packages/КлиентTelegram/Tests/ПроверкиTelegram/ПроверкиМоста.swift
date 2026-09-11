import Foundation
import Testing
@testable import КлиентTelegram

@Test func копияПереживаетИзменениеВозвращённогоБуфера() throws {
    let буфер = UnsafeMutablePointer<CChar>.allocate(capacity: 8)
    defer { буфер.deallocate() }
    for (номер, байт) in "{\"n\":1}".utf8.enumerated() { буфер[номер] = CChar(байт) }
    буфер[7] = 0
    let копия = try скопироватьОтвет(буфер, предел: 1024)
    буфер[5] = 50
    #expect(String(data: копия, encoding: .utf8) == "{\"n\":1}")
}

@Test func слишкомБольшойОтветИОтсутствующаяБиблиотекаОтклоняются() throws {
    #expect(throws: ОшибкаКлиента.self) {
        try "12345".withCString { try скопироватьОтвет($0, предел: 4) }
    }
    #expect(throws: ОшибкаКлиента.self) {
        try МостБиблиотеки(библиотека: "/несуществующий/tdjson.dylib")
    }
}

@Test func очередьОграничиваетКоличествоИБайтыБезПотери() throws {
    let очередь = try ОчередьОбновлений(ёмкость: 2, пределБайтов: 5)
    #expect(очередь.положить(Data([1, 2]), ожидать: false) == .принято)
    #expect(очередь.положить(Data([3, 4, 5]), ожидать: false) == .принято)
    #expect(очередь.положить(Data([6]), ожидать: false) == .перегрузка)
    #expect(очередь.извлечь() == Data([1, 2]))
    очередь.закрыть()
    #expect(очередь.извлечь() == Data([3, 4, 5]))
    #expect(очередь.извлечь() == nil)
    #expect(очередь.пикБайтов == 5)
    #expect(очередь.пикКоличество == 2)
}

private actor ПриёмникПримера {
    var события: [Data] = []
    func добавить(_ данные: Data) async throws {
        try await Task.sleep(for: .milliseconds(1))
        события.append(данные)
    }
}

private final class ТранспортПримера: ТранспортБиблиотеки, @unchecked Sendable {
    private let замок = NSLock()
    private var следующий = 1
    private var номер = 0
    private(set) var вызовов = 0
    func создатьКлиента() -> Int32 { замок.withLock { defer { следующий += 1 }; return Int32(следующий) } }
    func отправить(клиент: Int32, запрос: Data) throws {}
    func принять(таймАут: Double) throws -> Data? {
        #expect(таймАут > 0 && таймАут.isFinite)
        let событие: String? = замок.withLock {
            вызовов += 1
            guard номер < 20 else { return nil }
            defer { номер += 1 }
            return "{\"@client_id\":\(номер % 2 + 1),\"@extra\":\"\(номер)\"}"
        }
        if let событие { return try событие.withCString { try скопироватьОтвет($0, предел: 1024) } }
        Thread.sleep(forTimeInterval: таймАут)
        return nil
    }
}

@Test func одинПриёмникПорядокОбратноеДавлениеИОтмена() async throws {
    let транспорт = ТранспортПримера()
    let получатель = ПриёмникПримера()
    let цикл = try ЦиклПриёма(транспорт: транспорт, ёмкость: 2, пределБайтов: 256) {
        try await получатель.добавить($0)
    }
    try цикл.запустить()
    let второй = try ЦиклПриёма(транспорт: транспорт, ёмкость: 2, пределБайтов: 256) { _ in }
    #expect(throws: ОшибкаКлиента.ужеЕстьПриёмник) { try второй.запустить() }
    for _ in 0..<200 {
        if await получатель.события.count == 20 { break }
        try await Task.sleep(for: .milliseconds(5))
    }
    await цикл.остановить()
    let события = await получатель.события
    #expect(события.count == 20)
    for (номер, данные) in события.enumerated() {
        #expect(String(data: данные, encoding: .utf8) == "{\"@client_id\":\(номер % 2 + 1),\"@extra\":\"\(номер)\"}")
    }
    #expect(цикл.пикКоличество <= 2)
    #expect(цикл.незавершённые.isEmpty)
    #expect(транспорт.вызовов < 40)
    try await проверитьАктивнуюОтменуИПовторноеВладение()
}

private actor БарьерОбработчика {
    var начат = false
    func принять(_ данные: Data) async throws {
        начат = true
        try await Task.sleep(for: .seconds(5))
    }
}

private func проверитьАктивнуюОтменуИПовторноеВладение() async throws {
    let транспорт = ТранспортПримера()
    let барьер = БарьерОбработчика()
    let цикл = try ЦиклПриёма(транспорт: транспорт, ёмкость: 2, пределБайтов: 256) { try await барьер.принять($0) }
    try цикл.запустить()
    for _ in 0..<100 {
        if await барьер.начат { break }
        try await Task.sleep(for: .milliseconds(5))
    }
    let начало = ContinuousClock.now
    await цикл.остановить(отменитьОбработку: true)
    #expect(ContinuousClock.now - начало < .seconds(1))
    #expect(!цикл.незавершённые.isEmpty)
    for (номер, данные) in цикл.незавершённые.enumerated() {
        #expect(try ЗначениеДанных.прочитать(данные)["@extra"]?.строка == String(номер))
    }
    let следующий = try ЦиклПриёма(транспорт: ТранспортПримера()) { _ in }
    await следующий.остановить()
    #expect(throws: ОшибкаКлиента.закрыт) { try следующий.запустить() }
    let новый = try ЦиклПриёма(транспорт: ТранспортПримера()) { _ in }
    try новый.запустить()
    await новый.остановить()
    #expect(throws: ОшибкаКлиента.превышенПредел) {
        try "x".withCString { try скопироватьОтвет($0, предел: Int.max) }
    }
}
