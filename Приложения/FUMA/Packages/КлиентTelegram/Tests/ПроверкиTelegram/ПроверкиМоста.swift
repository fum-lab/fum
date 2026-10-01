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

@Test func несовместимаяБиблиотекаОсвобождаетсяПослеРазрешенияСимволов() throws {
    let каталог = try создатьПриватныйКаталог()
    defer { try? FileManager.default.removeItem(at: каталог) }
    let исходник = каталог.appendingPathComponent("tdjson.c")
    let библиотека = каталог.appendingPathComponent("libtdjson.dylib")
    try "int unrelated(void) { return 1; }\n".write(to: исходник, atomically: true, encoding: .utf8)
    try собратьДинамическуюБиблиотеку(исходник, в: библиотека)

    var ошибка: ОшибкаКлиента?
    do { _ = try МостБиблиотеки(библиотека: библиотека.path, привязка: привязкаФикстуры(библиотека, исходник)) }
    catch let найденная as ОшибкаКлиента { ошибка = найденная }
    #expect(ошибка == .отсутствуетСимвол("td_create_client_id"))

    try """
    #include <stdint.h>
    int32_t td_create_client_id(void) { return 1; }
    void td_send(int32_t client_id, const char *request) { (void)client_id; (void)request; }
    const char *td_receive(double timeout) { (void)timeout; return 0; }
    """.write(to: исходник, atomically: true, encoding: .utf8)
    try собратьДинамическуюБиблиотеку(исходник, в: библиотека)
    let выбранная = try привязкаФикстуры(библиотека, исходник)
    let мост = try МостБиблиотеки(библиотека: библиотека.path, привязка: выбранная)
    #expect(throws: ОшибкаКлиента.self) { try мост.отправить(клиент: 1, запрос: Data([0xff])) }
    #expect(throws: ОшибкаКлиента.self) { try мост.отправить(клиент: 1, запрос: Data([123, 0, 125])) }
    #expect(throws: ОшибкаКлиента.self) { try мост.отправить(клиент: 0, запрос: Data("{}".utf8)) }
    try мост.отправить(клиент: 1, запрос: Data(" {\"ё\":\"\\u0451\"}\n".utf8))
    // Другие байты receipt при том же dylib не подменяют удерживаемую привязку.
    var поля = try JSONSerialization.jsonObject(with: выбранная.сыраяКвитанция) as! [String: Any]
    поля["исходникSha256"] = String(repeating: "a", count: 64)
    let изменено = try JSONSerialization.data(withJSONObject: поля, options: [.sortedKeys])
    let новая = try ПривязкаБиблиотеки.проверить(библиотека: библиотека, сыраяКвитанция: изменено, ожидаемыйШа256: хэшОбмена(изменено))
    #expect(throws: ОшибкаКлиента.self) { try МостБиблиотеки(библиотека: библиотека.path, привязка: новая) }
    // Подмена on-disk файла при старой квитанции отвергается до повторного dlopen.
    try Data("changed-file".utf8).write(to: библиотека, options: [.atomic])
    #expect(throws: ОшибкаКлиента.self) { try МостБиблиотеки(библиотека: библиотека.path, привязка: выбранная) }
}

private func привязкаФикстуры(_ библиотека: URL, _ исходник: URL) throws -> ПривязкаБиблиотеки {
    let данные = try Data(contentsOf: библиотека)
    let сырьё = try JSONSerialization.data(withJSONObject: [
        "схема": "fum.синтетическая-c-библиотека.1", "исход": "успех",
        "исходникSha256": хэшОбмена(try Data(contentsOf: исходник)), "компиляторSha256": String(repeating: "0", count: 64),
        "библиотекаSha256": хэшОбмена(данные), "библиотекаBytes": данные.count,
        "архитектуры": ["arm64"], "символы": ["td_create_client_id", "td_send", "td_receive"]
    ], options: [.sortedKeys])
    return try ПривязкаБиблиотеки.проверить(библиотека: библиотека, сыраяКвитанция: сырьё, ожидаемыйШа256: хэшОбмена(сырьё))
}

@Test func невернаяКвитанцияНеОткрываетБиблиотеку() throws {
    let отсутствующая = URL(fileURLWithPath: "/не-открывать/libtdjson.dylib")
    for сырьё in [Data("{\"схема\":\"a\",\"схема\":\"b\"}".utf8), Data("{\"схема\":\"a\",\"\\u0441хема\":\"b\"}".utf8), Data("{\"схема\":\"fum.сборка-tdlib.1\",\"исход\":\"успех\"}".utf8)] {
        #expect(throws: (any Error).self) { try ПривязкаБиблиотеки.проверить(библиотека: отсутствующая, сыраяКвитанция: сырьё, ожидаемыйШа256: хэшОбмена(сырьё)) }
    }
    #expect(throws: (any Error).self) { try ПривязкаБиблиотеки.проверить(библиотека: отсутствующая, сыраяКвитанция: Data("{}".utf8), ожидаемыйШа256: String(repeating: "0", count: 64)) }
}

@Test func формаКвитанцииСборщикаПроверяетсяНаОткрытыхБайтахБезЗагрузкиБиблиотеки() throws {
    let корень = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: корень) }
    let библиотека = корень.appendingPathComponent("открытая-фикстура.bin")
    let байты = Data("Открытая фикстура проверяет только receipt и SHA, не является TDLib".utf8)
    try байты.write(to: библиотека)
    let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let профиль = try JSONSerialization.jsonObject(with: Data(contentsOf: пакет.appendingPathComponent("Профили/2026-09-30-сборка-tdlib.json"))) as! [String: Any]
    let хост = профиль["хост"] as! [String: Any]
    var среда = хост
    среда.removeValue(forKey: "система"); среда["macOS"] = среда.removeValue(forKey: "версия")
    среда["xcode"] = "Xcode 27.0"; среда["cmake"] = "cmake version 4.4.3"
    var инструменты = хост["sha256Инструментов"] as! [String: String]
    инструменты["zlibTbd"] = среда.removeValue(forKey: "zlibTbdSha256") as? String
    среда["sha256Инструментов"] = инструменты
    let зависимость = профиль["зависимость"] as! [String: Any]
    let проход: [String: Any] = ["проход": 1, "коммит": зависимость["коммит"]!, "дерево": зависимость["дерево"]!,
        "архивSha256": String(repeating: "a", count: 64), "настройкаСекунд": 0.5, "сборкаСекунд": 0.5, "установкаСекунд": 0.5,
        "библиотекаSha256": хэшОбмена(байты), "библиотекаBytes": байты.count,
        "архитектуры": ["arm64"], "символы": ["td_create_client_id", "td_send", "td_receive"], "зависимости": ["system/libSystem.B.dylib"]]
    var второй = проход; второй["проход"] = 2
    let поля: [String: Any] = ["схема": "fum.сборка-tdlib.1", "исход": "успех", "коммит": зависимость["коммит"]!,
        "профиль": среда, "повторений": 2, "библиотекаSha256": хэшОбмена(байты), "байтыСовпали": true, "проходы": [проход, второй]]
    func проверить(_ объект: [String: Any]) throws -> ПривязкаБиблиотеки {
        let сырьё = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
        return try ПривязкаБиблиотеки.проверить(библиотека: библиотека, сыраяКвитанция: сырьё, ожидаемыйШа256: хэшОбмена(сырьё))
    }
    #expect(try проверить(поля).библиотекаШа256 == хэшОбмена(байты))
    for (имя, значение) in [("повторений", true as Any), ("коммит", "wrong" as Any), ("байтыСовпали", 1 as Any), ("лишнее", "unknown" as Any)] {
        var неверное = поля; неверное[имя] = значение
        #expect(throws: (any Error).self) { try проверить(неверное) }
    }
    var неверныйПроход = второй; неверныйПроход["библиотекаBytes"] = байты.count + 1
    var неверное = поля; неверное["проходы"] = [проход, неверныйПроход]
    #expect(throws: (any Error).self) { try проверить(неверное) }
    var невернаяСреда = среда; невернаяСреда["cmake"] = "cmake version 4.4.30"
    неверное = поля; неверное["профиль"] = невернаяСреда
    #expect(throws: (any Error).self) { try проверить(неверное) }
    #expect(throws: (any Error).self) { try МостБиблиотеки(библиотека: "относительный.dylib", привязка: .синтетическийТранспорт) }
}

private func собратьДинамическуюБиблиотеку(_ исходник: URL, в библиотека: URL) throws {
    let компилятор = Process()
    компилятор.executableURL = URL(fileURLWithPath: "/usr/bin/clang")
    компилятор.arguments = ["-dynamiclib", "-o", библиотека.path, исходник.path]
    try компилятор.run()
    компилятор.waitUntilExit()
    guard компилятор.terminationStatus == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
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
    try await проверитьОтменуСЧтениемСостояния()
    try await проверитьАварийныеВеткиПриёма()
    try await проверитьПрофильСинтетическогоПотока()
    try await сыройАрхивУжеСуществуетВнутриНижнейОтправки()
    try await проверитьОтказВходящегоАрхиваДоОчереди()
    try await проверитьХвостСАрхивом()
    // Последняя старая проверка намеренно сохраняет аварийное владение процесса.
    try await проверитьСредуКлиента()
}

private final class НаблюдательОтмены: @unchecked Sendable {
    private let замок = NSLock()
    private var цикл: ЦиклПриёма?
    private var вызовы = 0
    func связать(_ цикл: ЦиклПриёма) { замок.withLock { self.цикл = цикл } }
    func отменить() {
        let текущий = замок.withLock { вызовы += 1; return цикл }
        _ = текущий?.причинаОстановки
    }
    var количество: Int { замок.withLock { вызовы } }
}

private func проверитьОтменуСЧтениемСостояния() async throws {
    let барьер = БарьерОбработчика()
    let наблюдатель = НаблюдательОтмены()
    let цикл = try ЦиклПриёма(транспорт: ТранспортПримера(), ёмкость: 2, пределБайтов: 256) { данные in
        try await withTaskCancellationHandler {
            try await барьер.принять(данные)
        } onCancel: { наблюдатель.отменить() }
    }
    наблюдатель.связать(цикл)
    try цикл.запустить()
    for _ in 0..<100 {
        if await барьер.начат { break }
        try await Task.sleep(for: .milliseconds(5))
    }
    #expect(await барьер.начат)
    await цикл.остановить(отменитьОбработку: true)
    #expect(наблюдатель.количество == 1)
    #expect(try цикл.незавершённые.first.map { try ЗначениеДанных.прочитать($0)["@extra"]?.строка } == "0")
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
