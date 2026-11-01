import Foundation
import Darwin
import CryptoKit
import КлиентTelegram

private struct ПамятьПроцесса: Encodable {
    let текущая: UInt64
    let пиковая: UInt64
}
private struct ПростойПроцесса: Encodable {
    let длительностьСекунд: Double
    let процессорноеВремяСекунд: Double
    let загрузкаОдногоЯдраПроцентов: Double
    let памятьБайт: [ПамятьПроцесса]
}
private struct ОтчётЗапуска: Encodable {
    let схема = "fum.автономный-запуск-телеграма.1"
    var библиотекаЗагружена = false
    var загрузкаСекунд: Double?
    var связываниеСекунд: Double?
    var привязка: String?
    var начальныйОтвет: НачальныйОтвет?
    var ожиданиеОтветаСекунд: Double?
    var закрытие: ИтогЗакрытия?
    var закрытиеСекунд: Double?
    var простой: ПростойПроцесса?
    var ошибка: String?
}

private func длительностьСекунд(с начала: ContinuousClock.Instant) -> Double {
    let компоненты = начала.duration(to: .now).components
    return Double(компоненты.seconds) + Double(компоненты.attoseconds) / 1e18
}

private func процессорноеВремя() throws -> Double {
    var сведения = rusage()
    guard getrusage(RUSAGE_SELF, &сведения) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    return Double(сведения.ru_utime.tv_sec + сведения.ru_stime.tv_sec)
        + Double(сведения.ru_utime.tv_usec + сведения.ru_stime.tv_usec) / 1_000_000
}
private func памятьПроцесса() throws -> ПамятьПроцесса {
    var сведения = mach_task_basic_info_data_t()
    let ёмкость = MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<integer_t>.size
    var количество = mach_msg_type_number_t(ёмкость)
    let результат = withUnsafeMutablePointer(to: &сведения) { указатель in
        указатель.withMemoryRebound(to: integer_t.self, capacity: ёмкость) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &количество)
        }
    }
    guard результат == KERN_SUCCESS, количество == ёмкость else { throw ОшибкаКлиента.требуетсяРазбор }
    return ПамятьПроцесса(текущая: сведения.resident_size, пиковая: сведения.resident_size_max)
}
private func измеритьПростой(_ секунд: Int) async throws -> ПростойПроцесса {
    // Прогрев не входит в CPU/wall; RSS включает весь процесс и собственный сбор метрик.
    try await Task.sleep(for: .seconds(2))
    var память = [try памятьПроцесса()]
    let процессорДо = try процессорноеВремя()
    let начало = ContinuousClock.now
    for _ in 0..<секунд {
        try await Task.sleep(for: .seconds(1))
        память.append(try памятьПроцесса())
    }
    let длительность = ContinuousClock.now - начало
    let компоненты = длительность.components
    let фактическоеВремя = Double(компоненты.seconds) + Double(компоненты.attoseconds) / 1e18
    let процессор = try процессорноеВремя() - процессорДо
    return ПростойПроцесса(длительностьСекунд: фактическоеВремя, процессорноеВремяСекунд: процессор,
        загрузкаОдногоЯдраПроцентов: 100 * процессор / фактическоеВремя, памятьБайт: память)
}

private func подготовитьПриватныйПрофиль() throws -> (корень: URL, журнал: URL, ключ: Data) {
    let временный = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("fum-telegram-\(UUID().uuidString)")
    guard mkdir(временный.path, 0o700) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    var готов = false
    defer { if !готов { try? FileManager.default.removeItem(at: временный) } }
    guard let указатель = realpath(временный.path, nil) else { throw ОшибкаКлиента.требуетсяРазбор }
    let корень = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
    free(указатель)
    let родитель = open(корень.deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    guard родитель >= 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    defer { Darwin.close(родитель) }
    guard fsync(родитель) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    let журнал = корень.appendingPathComponent("журнал", isDirectory: true)
    guard mkdir(журнал.path, 0o700) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    let ключ = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    let файл = open(корень.appendingPathComponent("ключ").path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard файл >= 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    defer { Darwin.close(файл) }
    try ключ.withUnsafeBytes { байты in
        var смещение = 0
        while смещение < байты.count {
            let записано = Darwin.write(файл, байты.baseAddress!.advanced(by: смещение), байты.count - смещение)
            if записано < 0, errno == EINTR { continue }
            guard записано > 0 else { throw ОшибкаКлиента.требуетсяРазбор }
            смещение += записано
        }
    }
    guard fsync(файл) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    let каталог = open(корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    guard каталог >= 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    defer { Darwin.close(каталог) }
    guard fsync(каталог) == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
    готов = true
    return (корень, журнал, ключ)
}

private func запустить() async -> Int32 {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    if аргументы == ["--help"] {
        print("""
        Автономная проверка TDLib без аккаунта:
          проверить-telegram --библиотека <физический-путь> --квитанция <физический-путь> --sha256-квитанции <независимый-SHA> [--простой-секунд 1..30]
        Создаёт клиента, проверяет ответ getAuthorizationState, измеряет простой и ждёт close → Closed.
        Простой по умолчанию: 15 секунд после 2 секунд прогрева. Результат — JSON, успех — код 0.
        Телефон, параметры приложения, bot-token и вход в аккаунт для этого запуска не используются.
        Синтетический поток через продукционное ядро без TDLib:
          проверить-telegram --профиль поток [--кадров 1..2048]
          проверить-telegram --профиль отмена [--повторов 1..100]
          проверить-telegram --профиль архив [--кадров 1..2048]
          проверить-telegram --проверить-архив <приватный-каталог> [--библиотека <путь> --квитанция <путь> --sha256-квитанции <SHA>]
        Сырой архив шифруется, сохраняется при успешном запуске и никогда не переотправляется при проверке.
        По умолчанию 1000 кадров после 32 кадров прогрева либо 30 отмен после 5 прогревов. Результат — JSON профиля.
        Сквозной хвост в двух процессах с заранее подготовленными каталогом журнала и ключом:
          проверить-telegram --сквозной-хвост подготовить|восстановить --каталог <приватный-каталог>
        Профиль восстановления незавершённых попыток:
          проверить-telegram --профиль-восстановления подготовить|восстановить --каталог <приватный-каталог> --попыток 16|256
        Пути библиотеки и приватного каталога должны быть абсолютными.
        При ошибке возвращает код 2; приватный каталог незавершённого запуска указан в stderr.
        """)
        return 0
    }
    var отчёт = ОтчётЗапуска()
    var среда: СредаКлиента?
    var приватныйКорень: URL?
    do {
        if аргументы.first == "--проверить-архив" {
            guard [2, 8].contains(аргументы.count), аргументы[1].hasPrefix("/") else { throw ОшибкаКлиента.неверныеДанные("Проверка архива") }
            let каталог = URL(fileURLWithPath: аргументы[1], isDirectory: true)
            let привязка: ПривязкаБиблиотеки?
            if аргументы.count == 8 {
                guard аргументы[2] == "--библиотека", аргументы[4] == "--квитанция", аргументы[6] == "--sha256-квитанции" else { throw ОшибкаКлиента.неверныеДанные("Привязка архива") }
                привязка = try ПривязкаБиблиотеки.проверить(библиотека: URL(fileURLWithPath: аргументы[3]), квитанция: URL(fileURLWithPath: аргументы[5]), ожидаемыйШа256: аргументы[7])
            } else { привязка = nil }
            let ключ = try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ")
            var результат = try сверитьСыройАрхив(корень: каталог.appendingPathComponent("журнал"), ключ: ключ, привязка: привязка)
            результат.append(10); try FileHandle.standardOutput.write(contentsOf: результат)
            return 0
        }
        if аргументы.first == "--профиль-восстановления" {
            guard аргументы.count == 6, ["подготовить", "восстановить"].contains(аргументы[1]),
                  аргументы[2] == "--каталог", аргументы[3].hasPrefix("/"), аргументы[4] == "--попыток",
                  let количество = Int(аргументы[5]), [16, 256].contains(количество) else {
                throw ОшибкаКлиента.неверныеДанные("Фазы профиля восстановления")
            }
            let каталог = URL(fileURLWithPath: аргументы[3], isDirectory: true)
            var этоКаталог: ObjCBool = false
            if FileManager.default.fileExists(atPath: каталог.path, isDirectory: &этоКаталог), этоКаталог.boolValue {
                приватныйКорень = каталог
            }
            var результат = try await измеритьВосстановление(каталог: каталог, количество: количество, подготовка: аргументы[1] == "подготовить")
            результат.append(10)
            try FileHandle.standardOutput.write(contentsOf: результат)
            return 0
        }
        if аргументы.first == "--сквозной-хвост" {
            guard аргументы.count == 4, ["подготовить", "восстановить"].contains(аргументы[1]),
                  аргументы[2] == "--каталог", аргументы[3].hasPrefix("/") else {
                throw ОшибкаКлиента.неверныеДанные("Фазы сквозной проверки хвоста")
            }
            let каталог = URL(fileURLWithPath: аргументы[3], isDirectory: true)
            var этоКаталог: ObjCBool = false
            if FileManager.default.fileExists(atPath: каталог.path, isDirectory: &этоКаталог), этоКаталог.boolValue {
                приватныйКорень = каталог
            }
            var результат = try await проверитьСквознойХвост(каталог: каталог, подготовка: аргументы[1] == "подготовить")
            результат.append(10)
            try FileHandle.standardOutput.write(contentsOf: результат)
            return 0
        }
        if аргументы.first == "--профиль" {
            guard аргументы.count == 2 || аргументы.count == 4, ["поток", "отмена", "архив"].contains(аргументы[1]) else {
                throw ОшибкаКлиента.неверныеДанные("Сценарий синтетического профиля")
            }
            let архив = аргументы[1] == "архив"
            let поток = аргументы[1] == "поток" || архив
            let предел = поток ? 2048 : 100
            let имяПараметра = поток ? "--кадров" : "--повторов"
            var количество = поток ? 1000 : 30
            if аргументы.count == 4 {
                guard аргументы[2] == имяПараметра, let значение = Int(аргументы[3]), (1...предел).contains(значение) else {
                    throw ОшибкаКлиента.неверныеДанные("Количество синтетических кадров")
                }
                количество = значение
            }
            let профиль = try подготовитьПриватныйПрофиль()
            приватныйКорень = профиль.корень
            if архив {
                var результат = try await измеритьАрхивОбмена(корень: профиль.журнал, ключ: профиль.ключ, количество: количество)
                try FileHandle.standardError.write(contentsOf: Data("Приватный архив сохранён: \(профиль.корень.path)\n".utf8))
                результат.append(10); try FileHandle.standardOutput.write(contentsOf: результат)
                return 0
            }
            var результат = поток
                ? try await измеритьСинтетическийПоток(корень: профиль.журнал, ключ: профиль.ключ, количество: количество)
                : try await измеритьСинтетическуюОтмену(количество: количество)
            try FileManager.default.removeItem(at: профиль.корень)
            приватныйКорень = nil
            результат.append(10)
            try FileHandle.standardOutput.write(contentsOf: результат)
            return 0
        }
        guard аргументы.count == 6 || аргументы.count == 8,
              аргументы[0] == "--библиотека", аргументы[1].hasPrefix("/"),
              аргументы[2] == "--квитанция", аргументы[3].hasPrefix("/"), аргументы[4] == "--sha256-квитанции" else {
            throw ОшибкаКлиента.неверныеДанные("Флаги автономного запуска")
        }
        var секунд = 15
        if аргументы.count == 8 {
            guard аргументы[6] == "--простой-секунд", let значение = Int(аргументы[7]), (1...30).contains(значение) else {
                throw ОшибкаКлиента.неверныеДанные("Длительность простоя")
            }
            секунд = значение
        }
        let началоСвязывания = ContinuousClock.now
        let привязка = try ПривязкаБиблиотеки.проверить(библиотека: URL(fileURLWithPath: аргументы[1]), квитанция: URL(fileURLWithPath: аргументы[3]), ожидаемыйШа256: аргументы[5])
        отчёт.связываниеСекунд = длительностьСекунд(с: началоСвязывания)
        отчёт.привязка = привязка.идентификатор
        let профиль = try подготовитьПриватныйПрофиль()
        приватныйКорень = профиль.корень
        let началоЗагрузки = ContinuousClock.now
        let открытая: СредаКлиента
        do {
            открытая = try await СредаКлиента.открыть(библиотека: аргументы[1], квитанция: URL(fileURLWithPath: аргументы[3]), ожидаемыйШа256: аргументы[5], корень: профиль.журнал, ключ: профиль.ключ)
            отчёт.загрузкаСекунд = длительностьСекунд(с: началоЗагрузки)
        } catch {
            отчёт.загрузкаСекунд = длительностьСекунд(с: началоЗагрузки)
            throw error
        }
        среда = открытая
        отчёт.библиотекаЗагружена = true
        let клиент = try await открытая.добавитьКлиента()
        let началоОжидания = ContinuousClock.now
        let начальный: НачальныйОтвет
        do {
            начальный = try await открытая.дождатьсяНачальногоОтвета(клиент)
            отчёт.ожиданиеОтветаСекунд = длительностьСекунд(с: началоОжидания)
        } catch {
            отчёт.ожиданиеОтветаСекунд = длительностьСекунд(с: началоОжидания)
            throw error
        }
        отчёт.начальныйОтвет = начальный
        guard начальный.клиент == клиент, начальный.тип == "authorizationStateWaitTdlibParameters" else {
            throw ОшибкаКлиента.требуетсяРазбор
        }
        отчёт.простой = try await измеритьПростой(секунд)
        let началоЗакрытия = ContinuousClock.now
        let закрытие: ИтогЗакрытия
        do {
            закрытие = try await открытая.закрыть()
            отчёт.закрытиеСекунд = длительностьСекунд(с: началоЗакрытия)
        } catch {
            отчёт.закрытиеСекунд = длительностьСекунд(с: началоЗакрытия)
            throw error
        }
        отчёт.закрытие = закрытие
        guard закрытие.всеЗакрыты, закрытие.потокиЗавершены, !закрытие.требуетсяРазбор,
              закрытие.неприменённыхКадров == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
        try FileHandle.standardError.write(contentsOf: Data("Приватный архив сохранён: \(профиль.корень.path)\n".utf8))
        приватныйКорень = nil
    } catch {
        if let среда, отчёт.закрытие == nil {
            let началоЗакрытия = ContinuousClock.now
            отчёт.закрытие = try? await среда.закрыть()
            if отчёт.закрытиеСекунд == nil { отчёт.закрытиеСекунд = длительностьСекунд(с: началоЗакрытия) }
        }
        switch error {
        case ОшибкаКлиента.библиотекаНедоступна, ОшибкаКлиента.отсутствуетСимвол:
            отчёт.ошибка = "библиотека_недоступна"
        case ОшибкаКлиента.неверныеДанные:
            отчёт.ошибка = "неверные_входы"
        default: отчёт.ошибка = "требуется_разбор"
        }
        if let приватныйКорень {
            try? FileHandle.standardError.write(contentsOf: Data("Приватные данные для разбора: \(приватныйКорень.path)\n".utf8))
        }
    }
    do {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .prettyPrinted]
        var байты = try кодировщик.encode(отчёт); байты.append(10)
        try FileHandle.standardOutput.write(contentsOf: байты)
    } catch { return 2 }
    return отчёт.ошибка == nil ? 0 : 2
}

exit(await запустить())
