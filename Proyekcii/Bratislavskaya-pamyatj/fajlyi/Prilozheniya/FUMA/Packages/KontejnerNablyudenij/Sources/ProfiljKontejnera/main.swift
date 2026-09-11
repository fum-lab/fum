import КонтейнерНаблюдений
import Foundation
import CryptoKit
import Darwin

struct ИтогЭтапа: Codable {
    let этап: String
    let глубина: Int
    let вызовы: Int
    let наносекунды: UInt64
}

struct Измерение: Encodable {
    let схема = "fum.метрики-контейнера.1"
    let режим: String
    let записей: Int
    let байт: Int
    let длительность_наносекунды: UInt64
    let память_пик_байт: Int64
    let подтверждения_наносекунды: [UInt64]
    let этапы: [ИтогЭтапа]
    let хэш_до: String?
    let хэш_после: String?
}

func этапы(_ метки: [МеткаПрофиля]) -> [ИтогЭтапа] {
    let группы = Dictionary(grouping: метки) { $0.этап }
    return группы.keys.sorted().map { имя in
        let группа = группы[имя]!
        return ИтогЭтапа(этап: имя, глубина: группа[0].глубина, вызовы: группа.count,
            наносекунды: группа.reduce(0) { $0 + $1.наносекунды })
    }
}

func пикПамяти() throws -> Int64 {
    var сведения = rusage()
    guard getrusage(RUSAGE_SELF, &сведения) == 0 else { throw ОшибкаКонтейнера.система(errno) }
    return Int64(сведения.ru_maxrss) // Darwin возвращает байты, не Linux KiB.
}

func хэшФайла(_ файл: URL) throws -> String {
    let поток = try FileHandle(forReadingFrom: файл)
    defer { try? поток.close() }
    var счётчик = SHA256()
    // FileHandle может вернуть autoreleased NSData: освобождаем каждый фрагмент,
    // чтобы диагностический hash не удерживал два полных прохода файла в памяти.
    while try autoreleasepool(invoking: {
        guard let часть = try поток.read(upToCount: 1_048_576), !часть.isEmpty else { return false }
        счётчик.update(data: часть)
        return true
    }) {}
    return Data(счётчик.finalize()).map { String(format: "%02x", $0) }.joined()
}

do {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    guard аргументы.count >= 2, аргументы[1].hasPrefix("/") else { throw ОшибкаКонтейнера.небезопасныйПуть }
    let корень = URL(fileURLWithPath: аргументы[1], isDirectory: true)
    if аргументы[0] == "записать", аргументы.count == 4 {
        guard let количество = Int(аргументы[2]), let размер = Int(аргументы[3]),
              количество > 0, количество <= 512, размер > 0, размер <= 1_048_576,
              количество <= 134_217_728 / размер else { throw ОшибкаКонтейнера.предел }
        let писатель = try Сегмент(кореньДанных: корень, запись: true, профилировать: true)
        defer { писатель.закрыть() }
        guard писатель.записи.isEmpty, !писатель.естьХвост else { throw ОшибкаКонтейнера.повреждение }
        var данные = Data(count: размер)
        данные.withUnsafeMutableBytes { (буфер: UnsafeMutableRawBufferPointer) in
            for номер in 0..<размер { буфер[номер] = UInt8(truncatingIfNeeded: номер * 131) }
        }
        писатель.очиститьПрофиль()
        var задержки: [UInt64] = []
        let начало = DispatchTime.now().uptimeNanoseconds
        for номер in 0..<количество {
            let началоЗаписи = DispatchTime.now().uptimeNanoseconds
            _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "профиль-\(номер)", тип: "синтетика/байты",
                спецификация: Data("байт[i] = (i * 131) mod 256".utf8)), данные: данные)
            задержки.append(DispatchTime.now().uptimeNanoseconds - началоЗаписи)
        }
        let длительность = DispatchTime.now().uptimeNanoseconds - начало
        try вывестиJSON(Измерение(режим: "запись", записей: количество, байт: количество * размер,
            длительность_наносекунды: длительность, память_пик_байт: пикПамяти(),
            подтверждения_наносекунды: задержки, этапы: этапы(писатель.профиль),
            хэш_до: nil, хэш_после: nil))
    } else if аргументы[0] == "восстановить", аргументы.count == 2 {
        // Полный hash до/после нужен для доказательства неизменности чистого сегмента.
        // Он не входит в измеряемое восстановление, RSS включает также его буферы.
        let файл = корень.appendingPathComponent("сегмент.fumobs")
        let начало = DispatchTime.now().uptimeNanoseconds
        let восстановитель = try Сегмент(кореньДанных: корень, запись: true, создать: false, профилировать: true)
        defer { восстановитель.закрыть() }
        guard !восстановитель.естьХвост else { throw ОшибкаКонтейнера.неполныйХвост }
        let открытие = DispatchTime.now().uptimeNanoseconds - начало
        let до = try хэшФайла(файл)
        let началоВосстановления = DispatchTime.now().uptimeNanoseconds
        try восстановитель.восстановитьХвост()
        let длительность = открытие + DispatchTime.now().uptimeNanoseconds - началоВосстановления
        let после = try хэшФайла(файл)
        guard до == после else { throw ОшибкаКонтейнера.повреждение }
        try вывестиJSON(Измерение(режим: "восстановление", записей: восстановитель.записи.count,
            байт: восстановитель.записи.reduce(0) { $0 + Int($1.размер) },
            длительность_наносекунды: длительность, память_пик_байт: пикПамяти(),
            подтверждения_наносекунды: [], этапы: этапы(восстановитель.профиль),
            хэш_до: до, хэш_после: после))
    } else {
        throw ОшибкаКонтейнера.повреждение
    }
} catch {
    try? FileHandle.standardError.write(contentsOf: Data("Профиль: \(error)\n".utf8))
    exit(1)
}
