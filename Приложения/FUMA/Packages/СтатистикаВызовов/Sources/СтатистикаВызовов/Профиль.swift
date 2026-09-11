import Foundation
import Darwin

public struct ЗамерСтатистики: Codable, Sendable {
    public let этап: String
    public let наносекунды: UInt64
}
public struct ПрофильСтатистики: Codable, Sendable {
    public let размер: String
    public let вызовов: Int
    public let инструментов: Int
    public let событий: Int
    public let входБайт: Int
    public let входСтрок: Int
    public let максимальнаяСинтетическаяСтрокаБайт: Int
    public let повторПрочиталБайт: Int
    public let пакетБайт: Int
    public let отчётБайт: Int
    public let пикРезидентнойПамятиДоБайт: Int64
    public let пикРезидентнойПамятиПослеБайт: Int64
    public let замеры: [ЗамерСтатистики]
}
public func профильСтатистики(корень: URL, большой: Bool, рабочий: Bool = false) async throws -> ПрофильСтатистики {
    try проверитьВыходВнеРепозитория(корень)
    try проверитьПустойКаталогПрофиля(корень)
    let вызовов = большой || рабочий ? 2048 : 32
    let задача = "11111111-1111-4111-8111-111111111111"
    let вход = корень.appendingPathComponent("публичная-фикстура.jsonl")
    let максимальнаяСтрока = try создатьФикстуруПрофиля(вход, задача: задача, вызовов: вызовов, большой: большой, рабочий: рабочий)
    let данные = корень.appendingPathComponent("контейнер")
    try FileManager.default.createDirectory(at: данные, withIntermediateDirectories: false)
    var замеры: [ЗамерСтатистики] = []
    let памятьДо = try пикРезидентнойПамяти()
    var начало = DispatchTime.now().uptimeNanoseconds
    let х = try ХранилищеСтатистики(корень: данные, задача: задача, запись: true)
    let импорт: РезультатИмпорта
    let повтор: РезультатИмпорта
    let кодированныйОтчёт: Data
    do {
        импорт = try await х.импортировать(вход)
        замеры.append(ЗамерСтатистики(этап: "импорт", наносекунды: DispatchTime.now().uptimeNanoseconds - начало))
        начало = DispatchTime.now().uptimeNanoseconds
        повтор = try await х.импортировать(вход)
        замеры.append(ЗамерСтатистики(этап: "повтор-префикса", наносекунды: DispatchTime.now().uptimeNanoseconds - начало))
        начало = DispatchTime.now().uptimeNanoseconds
        let отчёт = try await х.получить()
        замеры.append(ЗамерСтатистики(этап: "отчёт-в-памяти", наносекунды: DispatchTime.now().uptimeNanoseconds - начало))
        начало = DispatchTime.now().uptimeNanoseconds
        кодированныйОтчёт = try кодироватьСтатистику(отчёт)
        замеры.append(ЗамерСтатистики(этап: "кодирование-JSON", наносекунды: DispatchTime.now().uptimeNanoseconds - начало))
        guard отчёт == импорт.отчёт, повтор.отчёт == отчёт else { throw ОшибкаСтатистики.повреждение }
    } catch { await х.закрыть(); throw error }
    await х.закрыть()
    начало = DispatchTime.now().uptimeNanoseconds
    let ч = try ХранилищеСтатистики(корень: данные, задача: задача, запись: false)
    let восстановленный: ОтчётСтатистики
    do { восстановленный = try await ч.получить() }
    catch { await ч.закрыть(); throw error }
    await ч.закрыть()
    замеры.append(ЗамерСтатистики(этап: "replay-контейнера", наносекунды: DispatchTime.now().uptimeNanoseconds - начало))
    guard восстановленный == импорт.отчёт, восстановленный.прямыхВызовов == вызовов,
          восстановленный.сопряжённыхРезультатов == вызовов else { throw ОшибкаСтатистики.повреждение }
    return ПрофильСтатистики(размер: рабочий ? "рабочий" : (большой ? "большой" : "малый"), вызовов: вызовов,
        инструментов: восстановленный.инструменты.count, событий: восстановленный.наблюдения.count,
        входБайт: импорт.прочитаноБайт, входСтрок: импорт.отчёт.граница!.строк,
        максимальнаяСинтетическаяСтрокаБайт: максимальнаяСтрока, повторПрочиталБайт: повтор.прочитаноБайт,
        пакетБайт: импорт.байтПакета, отчётБайт: кодированныйОтчёт.count,
        пикРезидентнойПамятиДоБайт: памятьДо, пикРезидентнойПамятиПослеБайт: try пикРезидентнойПамяти(), замеры: замеры)
}

private func пикРезидентнойПамяти() throws -> Int64 {
    var сведения = rusage()
    guard getrusage(RUSAGE_SELF, &сведения) == 0 else { throw ОшибкаСтатистики.система(errno) }
    return Int64(сведения.ru_maxrss)
}
private func создатьФикстуруПрофиля(_ путь: URL, задача: String, вызовов: Int, большой: Bool, рабочий: Bool) throws -> Int {
    func строка(_ тип: String, _ содержимое: [String: Any], _ время: String) throws -> Data {
        try autoreleasepool {
            try JSONSerialization.data(withJSONObject: ["type": тип, "payload": содержимое, "timestamp": время],
                options: [.sortedKeys, .withoutEscapingSlashes]) + Data([10])
        }
    }
    let первая = try строка("session_meta", ["id": задача], "2026-09-09T12:00:00Z")
    var максимум = первая.count
    try первая.write(to: путь, options: .withoutOverwriting)
    let файл = try FileHandle(forWritingTo: путь)
    defer { try? файл.close() }
    try файл.seekToEnd()
    func записать(_ данные: Data) throws {
        try файл.write(contentsOf: данные)
        максимум = max(максимум, данные.count)
    }
    if большой && !рабочий {
        let игнорируемая = try строка("event_msg", ["public_fixture": String(repeating: "x", count: 524_288)],
                                     "2026-09-09T12:00:00Z")
        for _ in 0..<16 { try записать(игнорируемая) }
    }
    for номер in 0..<вызовов {
        let ключ = "call_" + String(номер)
        try записать(строка("response_item", ["type": "function_call", "call_id": ключ,
            "name": "public.tool_" + String(номер), "arguments": "public-fixture"], "2026-09-09T12:00:00Z"))
        try записать(строка("response_item", ["type": "function_call_output", "call_id": ключ,
            "output": "public-fixture"], "2026-09-09T12:00:00.100Z"))
    }
    if рабочий {
        let пустая = try строка("event_msg", ["public_fixture": ""], "2026-09-09T12:00:00Z")
        var осталось = 105_356_966 - Int(try файл.offset())
        let строкОсталось = 16_609 - (вызовов * 2 + 1)
        for номер in 0..<строкОсталось {
            let размер = min(3_326_896, осталось - (строкОсталось - номер - 1) * пустая.count)
            guard размер >= пустая.count else { throw ОшибкаСтатистики.формат }
            let данные = try строка("event_msg", ["public_fixture": String(repeating: "x", count: размер - пустая.count)],
                                   "2026-09-09T12:00:00Z")
            guard данные.count == размер else { throw ОшибкаСтатистики.формат }
            try записать(данные); осталось -= данные.count
        }
        guard осталось == 0 else { throw ОшибкаСтатистики.формат }
    }
    try файл.synchronize()
    return максимум
}
