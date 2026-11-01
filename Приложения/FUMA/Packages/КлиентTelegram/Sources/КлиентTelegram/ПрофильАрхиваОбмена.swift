import Foundation
import Darwin
import КонтейнерНаблюдений

private final class МетрикиАрхива: @unchecked Sendable {
    private let замок = NSLock()
    private var метки: [String: [UInt64]] = [:]
    private var начала: [Int: UInt64] = [:]
    func добавить(_ этап: String, _ время: UInt64) { замок.withLock { метки[этап, default: []].append(время) } }
    func очистить() { замок.withLock { метки.removeAll() } }
    func начатьКадр(_ номер: Int) { замок.withLock { начала[номер] = DispatchTime.now().uptimeNanoseconds } }
    func закончитьКадр(_ номер: Int) throws {
        try замок.withLock {
            guard let начало = начала.removeValue(forKey: номер) else { throw ОшибкаКлиента.требуетсяРазбор }
            метки["полный-кадр", default: []].append(DispatchTime.now().uptimeNanoseconds - начало)
        }
    }
    func сводка() -> [String: [String: UInt64]] {
        замок.withLock { метки.mapValues { ряд in
            let сорт = ряд.sorted()
            return ["число": UInt64(ряд.count), "суммаНаносекунд": ряд.reduce(0, +),
                "p50Наносекунд": сорт[(сорт.count - 1) / 2], "p95Наносекунд": сорт[(сорт.count - 1) * 95 / 100]]
        } }
    }
}

private final class ТранспортПрофиляАрхива: ТранспортБиблиотеки, @unchecked Sendable {
    private let замок = NSLock()
    private let кадры: [Data]
    private var номер = 0
    private let метрики: МетрикиАрхива
    init(_ кадры: [Data], метрики: МетрикиАрхива) { self.кадры = кадры; self.метрики = метрики }
    func создатьКлиента() -> Int32 { 1 }
    func отправить(клиент: Int32, запрос: Data) throws {}
    func принять(таймАут: Double) throws -> Data? {
        let кадр: Data? = замок.withLock {
            guard номер < кадры.count else { return nil }
            метрики.начатьКадр(номер)
            defer { номер += 1 }; return кадры[номер]
        }
        if кадр == nil { Thread.sleep(forTimeInterval: таймАут) }
        return кадр
    }
}

private actor ПолучательПрофиляАрхива {
    private(set) var количество = 0
    let метрики: МетрикиАрхива
    init(_ метрики: МетрикиАрхива) { self.метрики = метрики }
    func применить(_ байты: Data) throws {
        guard let номер = try ЗначениеДанных.прочитать(байты)["n"]?.целое else { throw ОшибкаКлиента.требуетсяРазбор }
        try метрики.закончитьКадр(Int(номер)); количество += 1
    }
}

private struct ИзмерениеАрхива: Encodable {
    let схема = "fum.профиль-сырого-обмена.1"
    let происхождение = "синтетический-транспорт"
    let прогрев: Int
    let входящих: Int
    let исходящих: Int
    let размерКадра: Int
    let потокНаносекунд: UInt64
    let исходящиеНаносекунд: UInt64
    let процессорСекунд: Double
    let памятьБайт: UInt64
    let пиковаяПамятьБайт: UInt64
    let метрики: [String: [String: UInt64]]
    let сохранённыеШа256: String
    let привязка: String
    let граница: String
}

private func кадрПрофиляАрхива(_ номер: Int) -> Data {
    var данные = Data("{\"@type\":\"fixture\",\"n\":\(номер),\"text\":\"ё\"}".utf8)
    данные.append(Data(repeating: 32, count: 4096 - данные.count))
    return данные
}
private func процессорАрхива() throws -> Double {
    var время = rusage()
    guard getrusage(RUSAGE_SELF, &время) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    return Double(время.ru_utime.tv_sec + время.ru_stime.tv_sec) + Double(время.ru_utime.tv_usec + время.ru_stime.tv_usec) / 1e6
}
private func памятьАрхива() throws -> UInt64 {
    var сведения = rusage_info_v2()
    let код = withUnsafeMutablePointer(to: &сведения) { $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(getpid(), RUSAGE_INFO_V2, $0) } }
    guard код == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    return сведения.ri_resident_size
}

/// Подготовка фикстур исключена; полный интервал включает wrapper, AES, write/fsync
/// и очередь/actor/разбор JSON. Настоящий C ABI измеряется отдельно fake-C runner.
public func измеритьАрхивОбмена(корень: URL, ключ: Data, количество: Int = 1000) async throws -> Data {
    guard (1...2048).contains(количество) else { throw ОшибкаКлиента.превышенПредел }
    let кадры = (0..<(32 + количество)).map(кадрПрофиляАрхива)
    let метрики = МетрикиАрхива(); var операции = ФайловыеОперации.системные
    операции.запись = { дескриптор, данные in
        let начало = DispatchTime.now().uptimeNanoseconds
        defer { метрики.добавить("запись", DispatchTime.now().uptimeNanoseconds - начало) }
        return try ФайловыеОперации.системные.запись(дескриптор, данные)
    }
    операции.синхронизация = { дескриптор in
        let начало = DispatchTime.now().uptimeNanoseconds
        defer { метрики.добавить("fsync", DispatchTime.now().uptimeNanoseconds - начало) }
        try ФайловыеОперации.системные.синхронизация(дескриптор)
    }
    let архив = try АрхивОбмена(корень: корень, ключ: ключ, привязка: .синтетическийТранспорт,
        операции: операции, наблюдать: { метрики.добавить($0, $1) })
    defer { архив.закрыть() }
    let транспорт = АрхивирующийТранспорт(ТранспортПрофиляАрхива(кадры, метрики: метрики), архив: архив)
    for номер in 0..<32 { _ = try транспорт.принять(таймАут: 0.1); try метрики.закончитьКадр(номер) }
    метрики.очистить()
    let получатель = ПолучательПрофиляАрхива(метрики)
    let цикл = try ЦиклПриёма(транспорт: транспорт) { try await получатель.применить($0) }
    let процессорДо = try процессорАрхива(), начало = DispatchTime.now().uptimeNanoseconds
    try цикл.запустить()
    let предел = ContinuousClock.now + .seconds(45)
    while await получатель.количество < количество, цикл.причинаОстановки == nil, ContinuousClock.now < предел {
        try await Task.sleep(for: .milliseconds(1))
    }
    await цикл.остановить()
    guard await получатель.количество == количество, цикл.причинаОстановки == nil, цикл.незавершённые.isEmpty else { throw ОшибкаКлиента.требуетсяРазбор }
    let поток = DispatchTime.now().uptimeNanoseconds - начало
    let началоИсходящих = DispatchTime.now().uptimeNanoseconds
    for номер in 0..<16 { try транспорт.отправить(клиент: 1, запрос: кадрПрофиляАрхива(номер)) }
    let исходящие = DispatchTime.now().uptimeNanoseconds - началоИсходящих
    let процессор = try процессорАрхива() - процессорДо, память = try памятьАрхива(), сводка = метрики.сводка()
    var сведения = rusage()
    guard getrusage(RUSAGE_SELF, &сведения) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    let записи = try архив.снимок().filter { $0.вид == "кадр" }
    guard записи.compactMap(\.байты) == кадры + (0..<16).map(кадрПрофиляАрхива) else { throw ОшибкаКлиента.требуетсяРазбор }
    try архив.закончитьПоколение()
    return try кодироватьЛокально(ИзмерениеАрхива(прогрев: 32, входящих: количество, исходящих: 16,
        размерКадра: 4096, потокНаносекунд: поток, исходящиеНаносекунд: исходящие, процессорСекунд: процессор,
        памятьБайт: память, пиковаяПамятьБайт: UInt64(сведения.ru_maxrss), метрики: сводка, сохранённыеШа256: хэшОбмена(записи.compactMap(\.байты).reduce(into: Data()) { $0.append($1) }),
        привязка: ПривязкаБиблиотеки.синтетическийТранспорт.идентификатор,
        граница: "32 прогревочных, затем входящий поток через wrapper/очередь/actor/JSON и 16 исходящих; связывание/подготовка вне таймера; поток включает ожидание/соединение потоков и опрос счётчика; полный-кадр измеряется от получения фикстуры до завершения actor; RSS текущий/пиковый всего процесса; C ABI не включён; файловый кэш ОС не очищался"))
}

private struct СводкаКадра: Codable {
    let порядок: Int
    let поколение: UUID
    let направление: НаправлениеОбмена
    let байтыШа256: String
    let размер: Int
}
private struct СводкаАрхива: Encodable {
    let схема = "fum.сводка-сырого-архива.1"
    let привязка: String
    let происхождение: String
    let кадры: [СводкаКадра]
    let сохранённыеШа256: String
    let поколений: Int
    let разрывов: Int
}
public func сверитьСыройАрхив(корень: URL, ключ: Data, привязка: ПривязкаБиблиотеки? = nil) throws -> Data {
    let выбранная = привязка ?? .синтетическийТранспорт
    let записи = try АрхивОбмена.прочитать(корень: корень, ключ: ключ, привязка: выбранная)
    let кадры = записи.filter { $0.вид == "кадр" }
    return try кодироватьЛокально(СводкаАрхива(привязка: выбранная.идентификатор, происхождение: выбранная.происхождение,
        кадры: кадры.map { СводкаКадра(порядок: $0.порядок, поколение: $0.поколение, направление: $0.направление!, байтыШа256: хэшОбмена($0.байты!), размер: $0.байты!.count) },
        сохранённыеШа256: хэшОбмена(кадры.compactMap(\.байты).reduce(into: Data()) { $0.append($1) }),
        поколений: записи.filter { $0.вид == "поколение" }.count,
        разрывов: записи.filter { $0.вид == "разрыв" }.count))
}
