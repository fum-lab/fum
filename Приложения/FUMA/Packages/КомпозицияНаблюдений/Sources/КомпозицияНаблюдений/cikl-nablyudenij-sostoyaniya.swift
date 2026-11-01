import Foundation
import Darwin
import CryptoKit
import АрхивныйСнимокЗадачи
import КонтейнерНаблюдений

public enum ОшибкаЦиклаНаблюденийСостояния: Error, Equatable, Sendable {
    case историяВнутриРепозитория
    case неОднаЗавершённаяРамка
    case несовпадениеПовторногоЧтения
    case несовпадениеСохранённогоКонтекста
    case фазаУжеИсполняется
    case эксклюзивныйЗахватНедоступен
}

public struct РезультатЦиклаНаблюденийСостояния: Equatable, Sendable {
    public let план: ПланНаблюденийСостояния
    public let повторноПрочитанныйПлан: ПланНаблюденийСостояния
    public let каноническиеБайты: Data
    public let курсор: КурсорРамокJSONL
    public let квитанция: Квитанция
}

public struct ЦиклНаблюденийСостояния<
    Поставщик: ПоставщикНаблюденийСостояния
>: Sendable {
    private let компоновщик: КомпоновщикНаблюденийСостояния<Поставщик>

    public init(поставщик: Поставщик) {
        компоновщик = КомпоновщикНаблюденийСостояния(поставщик: поставщик)
    }

    public func выполнить(
        кореньФайловойСистемы: URL,
        источникФайловойСистемы: String,
        кореньРепозитория: URL,
        кореньИстории: URL,
        времяИстории: String
    ) async throws -> РезультатЦиклаНаблюденийСостояния {
        let план = try await компоновщик.построить(
            кореньФайловойСистемы: кореньФайловойСистемы,
            источникФайловойСистемы: источникФайловойСистемы,
            кореньРепозитория: кореньРепозитория)

        let физическийКореньИстории = try разрешитьФизическийКаталог(кореньИстории)
        let физическийКореньРепозитория = try разрешитьФизическийКаталог(
            URL(
                fileURLWithPath: план.репозиторий.физическийКорень,
                isDirectory: true))
        guard !физическийКореньИстории.pathComponents.starts(
            with: физическийКореньРепозитория.pathComponents)
        else {
            throw ОшибкаЦиклаНаблюденийСостояния.историяВнутриРепозитория
        }

        let каноническиеБайты = try план.каноническаяСтрокаJSONL()
        let курсор = try проверитьОднуРамкуJSONL(каноническиеБайты)

        let сохранённое: (квитанция: Квитанция, идентификатор: String) = try {
            let писатель = try Сегмент(
                кореньДанных: физическийКореньИстории,
                запись: true,
                создать: true)
            defer { писатель.закрыть() }

            let существующие = Set(писатель.записи.map(\.описание.идентификатор))
            var номер = писатель.записи.count + 1
            var идентификатор = "план-наблюдений-состояния-\(номер)"
            while существующие.contains(идентификатор) {
                номер += 1
                идентификатор = "план-наблюдений-состояния-\(номер)"
            }
            let описание = ОписаниеНаблюдения(
                идентификатор: идентификатор,
                тип: "fuma.план-наблюдений-состояния.jsonl.1",
                версияСхемы: 1,
                источник: "КомпозицияНаблюдений",
                время: времяИстории,
                спецификация: Data(план.схема.utf8))
            let квитанция = try писатель.добавить(
                описание,
                данные: каноническиеБайты)
            return (квитанция, идентификатор)
        }()

        let повторноПрочитанное: (байты: Data, квитанция: Квитанция) = try {
            let читатель = try Сегмент(
                кореньДанных: физическийКореньИстории,
                запись: false,
                создать: false)
            defer { читатель.закрыть() }
            guard let квитанция = читатель.записи.first(where: {
                $0.описание.идентификатор == сохранённое.идентификатор
            }) else {
                throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеПовторногоЧтения
            }
            return (
                try читатель.извлечь(сохранённое.идентификатор),
                квитанция)
        }()

        let повторныйКурсор = try проверитьОднуРамкуJSONL(
            повторноПрочитанное.байты)
        let повторноПрочитанныйПлан = try JSONDecoder().decode(
            ПланНаблюденийСостояния.self,
            from: повторноПрочитанное.байты)
        guard повторноПрочитанное.байты == каноническиеБайты,
              повторноПрочитанное.квитанция == сохранённое.квитанция,
              повторныйКурсор == курсор,
              повторноПрочитанныйПлан == план,
              сохранённое.квитанция.размер == UInt64(каноническиеБайты.count),
              сохранённое.квитанция.хэш == курсор.префикс.sha256,
              try повторноПрочитанныйПлан.каноническаяСтрокаJSONL()
                == повторноПрочитанное.байты else {
            throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеПовторногоЧтения
        }

        return РезультатЦиклаНаблюденийСостояния(
            план: план,
            повторноПрочитанныйПлан: повторноПрочитанныйПлан,
            каноническиеБайты: каноническиеБайты,
            курсор: курсор,
            квитанция: сохранённое.квитанция)
    }
}

/// Временная граница FUMA к будущему Tools-owned apply API. Реализация порта
/// обязана сохранить намерение через callback и дождаться его успешного
/// readback до возможного эффекта. Она возвращает `применено` только после
/// наблюдения результата, сверенного с pinned intent. Этот протокол сам ничего
/// не применяет и не является подтверждением live filesystem effect. Для
/// `безИзменений` порт предъявляет post-readback witness с целевым и наблюдённым
/// digest. FUMA проверяет форму, привязку к intent и их равенство, но не может
/// удостоверить полноту инвентаризации или происхождение digest; это гарантия
/// доверенного Tools-порта, пока неизвестная реализация не подключена.
public protocol ФазаНормализацииКорнейСостояния: Sendable {
    func выполнить(
        контекст: КонтекстФазыНормализации,
        сохранитьНамерение: @escaping СохранитьНамерениеФазы
    ) async throws -> ИсходФазыНормализации
}

public typealias СохранитьНамерениеФазы = @Sendable (Data) async throws -> Квитанция

public struct КонтекстФазыНормализации: Equatable, Sendable {
    public let идентификаторОперации: String
    /// Канонические байты назначений, owner/ref и явного отображения от Tools.
    public let назначение: Data
    /// Канонические байты полного pinned checkpoint, включая оба снимка.
    public let контрольнаяТочка: Data
    public let время: String
    /// Digest ожидаемой итоговой инвентаризации для проверки post-readback NO_OP.
    public let хэшОжидаемогоСнимка: String?

    public init(идентификаторОперации: String, назначение: Data,
                контрольнаяТочка: Data, время: String,
                хэшОжидаемогоСнимка: String? = nil) {
        self.идентификаторОперации = идентификаторОперации
        self.назначение = назначение
        self.контрольнаяТочка = контрольнаяТочка
        self.время = время
        self.хэшОжидаемогоСнимка = хэшОжидаемогоСнимка
    }
}

public enum ИсходФазыНормализации: Equatable, Sendable {
    case применено(свидетельство: Data)
    case безИзменений(свидетельство: Data)
    case конфликт(причина: String, свидетельство: Data?)
    case неизвестно(причина: String, свидетельство: Data?)
}

public struct РезультатЦиклаНаблюденийСФазой: Equatable, Sendable {
    public let исходФазы: ИсходФазыНормализации
    public let квитанцияНамерения: Квитанция?
    public let квитанцияТерминала: Квитанция
    /// Новый filesystem/repository plan строится только после readback
    /// известного терминального результата.
    public let планПослеИсхода: ПланНаблюденийСостояния?
}

private struct ЗаписьФазы: Codable, Equatable, Sendable {
    let схема: String
    let операция: String
    let время: String?
    let назначение: Data
    let контрольнаяТочка: Data
    let хэшОжидаемогоСнимка: String?
    let хэшНамерения: String?
    let вид: String
    let причина: String?
    let свидетельство: Data?
}

private struct СвидетельствоNoOp: Codable, Equatable {
    let схема: String
    let операция: String
    let видНаблюдения: String
    let идентификаторНаблюдения: String
    let хэшНамерения: String
    let хэшЦелевогоСнимка: String
    let хэшНаблюдённогоСнимка: String
}

/// Advisory lock for cooperating FUMA invocations. Held for the whole phase
/// transaction; a contending caller fails closed before reading or applying.
private final class ЗахватФазыНормализации: @unchecked Sendable {
    private let descriptor: Int32

    init(корень: URL, операция: String) throws {
        let path = корень.appendingPathComponent(".fuma-phase-claim-\(операция)").path
        let fd = open(path, O_CREAT | O_RDWR | O_NOFOLLOW, mode_t(S_IRUSR | S_IWUSR))
        guard fd >= 0 else { throw ОшибкаЦиклаНаблюденийСостояния.эксклюзивныйЗахватНедоступен }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_uid == getuid(), (info.st_mode & mode_t(0o077)) == 0 else {
            close(fd)
            throw ОшибкаЦиклаНаблюденийСостояния.эксклюзивныйЗахватНедоступен
        }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            let busy = errno == EWOULDBLOCK || errno == EAGAIN
            close(fd)
            throw busy ? ОшибкаЦиклаНаблюденийСостояния.фазаУжеИсполняется
                        : ОшибкаЦиклаНаблюденийСостояния.эксклюзивныйЗахватНедоступен
        }
        descriptor = fd
    }

    deinit {
        _ = flock(descriptor, LOCK_UN)
        close(descriptor)
    }
}

private actor ЖурналФазыНормализации {
    private let корень: URL

    init(корень: URL) { self.корень = корень }

    func прочитать(_ идентификатор: String) throws -> (ЗаписьФазы, Квитанция)? {
        let сегмент = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { сегмент.закрыть() }
        guard let квитанция = сегмент.записи.first(where: {
            $0.описание.идентификатор == идентификатор
        }) else { return nil }
        let данные = try сегмент.извлечь(идентификатор)
        let запись = try JSONDecoder().decode(ЗаписьФазы.self, from: данные)
        guard try Self.каноническиеБайты(запись) == данные,
              квитанция.размер == UInt64(данные.count),
              квитанция.хэш == Self.sha256(данные) else {
            throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеПовторногоЧтения
        }
        return (запись, квитанция)
    }

    func сохранитьИПрочитать(_ запись: ЗаписьФазы, id: String,
                              тип: String, время: String) throws -> Квитанция {
        let байты = try Self.каноническиеБайты(запись)
        let описание = ОписаниеНаблюдения(
            идентификатор: id, тип: тип, версияСхемы: 1,
            источник: "КомпозицияНаблюдений", время: время,
            спецификация: Data("fuma.фаза-нормализации-корня.1".utf8))
        let писатель = try Сегмент(кореньДанных: корень, запись: true, создать: false)
        let квитанция = try писатель.добавить(описание, данные: байты)
        писатель.закрыть()

        let читатель = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { читатель.закрыть() }
        guard let прочитаннаяКвитанция = читатель.записи.first(where: {
            $0.описание.идентификатор == id
        }) else { throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеПовторногоЧтения }
        let прочитанныеБайты = try читатель.извлечь(id)
        guard прочитанныеБайты == байты, прочитаннаяКвитанция == квитанция,
              прочитаннаяКвитанция.хэш == Self.sha256(байты) else {
            throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеПовторногоЧтения
        }
        return прочитаннаяКвитанция
    }

    static func каноническиеБайты(_ запись: ЗаписьФазы) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var bytes = try encoder.encode(запись)
        bytes.append(10)
        return bytes
    }

    static func sha256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
}

public extension ЦиклНаблюденийСостояния {
    /// Исполняет одну injected фазу как source seam. Состояние Tools API
    /// намеренно opaque; фактическое применение и запуск общего runtime здесь
    /// не утверждаются.
    func выполнитьФазуНормализации(
        контекст: КонтекстФазыНормализации,
        фаза: some ФазаНормализацииКорнейСостояния,
        кореньФайловойСистемы: URL,
        источникФайловойСистемы: String,
        кореньРепозитория: URL,
        кореньИстории: URL,
        времяИстории: String
    ) async throws -> РезультатЦиклаНаблюденийСФазой {
        guard Self.допустима(контекст) else {
            throw ОшибкаЦиклаНаблюденийСостояния.неОднаЗавершённаяРамка
        }
        let history = try разрешитьФизическийКаталог(кореньИстории)
        let repo = try разрешитьФизическийКаталог(кореньРепозитория)
        guard !history.pathComponents.starts(with: repo.pathComponents) else {
            throw ОшибкаЦиклаНаблюденийСостояния.историяВнутриРепозитория
        }

        let journal = ЖурналФазыНормализации(корень: history)
        let claim = try ЗахватФазыНормализации(
            корень: history, операция: контекст.идентификаторОперации)
        defer { withExtendedLifetime(claim) {} }
        let initialize = try Сегмент(кореньДанных: history, запись: true, создать: true)
        initialize.закрыть()
        let intentID = "фаза-нормализации-намерение-\(контекст.идентификаторОперации)"
        let terminalID = "фаза-нормализации-исход-\(контекст.идентификаторОперации)"
        if let terminal = try await journal.прочитать(terminalID) {
            guard Self.совпадает(terminal.0, context: контекст),
                  terminal.0.схема == "fuma.фаза-нормализации.1",
                  ["applied", "no-op", "conflict", "unknown"].contains(terminal.0.вид),
                  let intent = try await journal.прочитать(intentID),
                  Self.провереноНамерение(intent.0, context: контекст),
                  terminal.0.хэшНамерения == ЖурналФазыНормализации.sha256(
                    try ЖурналФазыНормализации.каноническиеБайты(intent.0)) else {
                return РезультатЦиклаНаблюденийСФазой(
                    исходФазы: .неизвестно(причина: "неподтверждённый-журнал-фазы", свидетельство: nil),
                    квитанцияНамерения: nil, квитанцияТерминала: terminal.1, планПослеИсхода: nil)
            }
            let outcome = Self.нормализованныйИсход(
                Self.исход(terminal.0), context: контекст,
                intentHash: terminal.0.хэшНамерения ?? "")
            let known = Self.известен(outcome)
            let plan = known ? try await компоновщик.построить(
                кореньФайловойСистемы: кореньФайловойСистемы,
                источникФайловойСистемы: источникФайловойСистемы,
                кореньРепозитория: кореньРепозитория) : nil
            return .init(исходФазы: outcome, квитанцияНамерения: intent.1,
                         квитанцияТерминала: terminal.1, планПослеИсхода: plan)
        }

        if let orphanIntent = try await journal.прочитать(intentID) {
            let validIntent = Self.провереноНамерение(orphanIntent.0, context: контекст)
            guard validIntent || Self.legacyНамерениеСовпадает(orphanIntent.0, context: контекст) else {
                throw ОшибкаЦиклаНаблюденийСостояния.несовпадениеСохранённогоКонтекста
            }
            let unknown = ЗаписьФазы(схема: "fuma.фаза-нормализации.1",
                операция: контекст.идентификаторОперации, время: контекст.время,
                назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: ЖурналФазыНормализации.sha256(
                    try ЖурналФазыНормализации.каноническиеБайты(orphanIntent.0)),
                вид: "unknown", причина: validIntent ? "намерение-есть-терминал-отсутствует"
                    : "legacy-или-несогласованное-намерение",
                свидетельство: nil)
            let terminal = try await journal.сохранитьИПрочитать(
                unknown, id: terminalID, тип: "fuma.исход-фазы-нормализации.1", время: контекст.время)
            return .init(исходФазы: .неизвестно(причина: unknown.причина ?? "legacy-unknown", свидетельство: nil), квитанцияНамерения: orphanIntent.1,
                         квитанцияТерминала: terminal, планПослеИсхода: nil)
        }

        let saveIntent: СохранитьНамерениеФазы = { bytes in
            guard bytes.count <= Int(Пределы.объект) else { throw ОшибкаКонтейнера.предел }
            let record = ЗаписьФазы(схема: "fuma.фаза-нормализации-намерение.1",
                операция: контекст.идентификаторОперации, время: контекст.время,
                назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: ЖурналФазыНормализации.sha256(bytes),
                вид: "intent", причина: nil, свидетельство: bytes)
            return try await journal.сохранитьИПрочитать(
                record, id: intentID, тип: "fuma.намерение-фазы-нормализации.1", время: контекст.время)
        }

        let reported: ИсходФазыНормализации
        do { reported = try await фаза.выполнить(контекст: контекст, сохранитьНамерение: saveIntent) }
        catch {
            let intent = try? await journal.прочитать(intentID)
            let unknown = ЗаписьФазы(схема: "fuma.фаза-нормализации.1",
                операция: контекст.идентификаторОперации, время: контекст.время,
                назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: intent.map { ЖурналФазыНормализации.sha256((try? ЖурналФазыНормализации.каноническиеБайты($0.0)) ?? Data()) },
                вид: "unknown", причина: "исключение-фазы-после-возможного-эффекта",
                свидетельство: nil)
            let receipt = try await journal.сохранитьИПрочитать(
                unknown, id: terminalID, тип: "fuma.исход-фазы-нормализации.1", время: контекст.время)
            return .init(исходФазы: Self.исход(unknown), квитанцияНамерения: intent?.1,
                         квитанцияТерминала: receipt, планПослеИсхода: nil)
        }

        guard let intent = try await journal.прочитать(intentID),
              Self.провереноНамерение(intent.0, context: контекст) else {
            let unknown = ЗаписьФазы(схема: "fuma.фаза-нормализации.1",
                операция: контекст.идентификаторОперации, время: контекст.время,
                назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка, хэшНамерения: nil,
                вид: "unknown", причина: "фаза-не-предъявила-readback-intent",
                свидетельство: nil)
            let receipt = try await journal.сохранитьИПрочитать(
                unknown, id: terminalID, тип: "fuma.исход-фазы-нормализации.1", время: контекст.время)
            return .init(исходФазы: Self.исход(unknown), квитанцияНамерения: nil,
                         квитанцияТерминала: receipt, планПослеИсхода: nil)
        }

        let intentHash = ЖурналФазыНормализации.sha256(
            try ЖурналФазыНормализации.каноническиеБайты(intent.0))
        let terminalOutcome = Self.нормализованныйИсход(
            reported, context: контекст, intentHash: intentHash)
        let terminalRecord = Self.запись(terminalOutcome, контекст: контекст, intentHash: intentHash)
        let terminal = try await journal.сохранитьИПрочитать(
            terminalRecord, id: terminalID, тип: "fuma.исход-фазы-нормализации.1", время: контекст.время)
        guard let readback = try await journal.прочитать(terminalID),
              readback.1 == terminal,
              Self.совпадает(readback.0, context: контекст),
              readback.0.схема == "fuma.фаза-нормализации.1",
              readback.0.хэшНамерения == intentHash,
              readback.0 == terminalRecord else {
            return .init(исходФазы: .неизвестно(причина: "терминальный-readback-не-совпадает", свидетельство: nil),
                         квитанцияНамерения: intent.1, квитанцияТерминала: terminal, планПослеИсхода: nil)
        }
        let known = Self.известен(terminalOutcome)
        let plan = known ? try await компоновщик.построить(
            кореньФайловойСистемы: кореньФайловойСистемы,
            источникФайловойСистемы: источникФайловойСистемы,
            кореньРепозитория: кореньРепозитория) : nil
        return .init(исходФазы: terminalOutcome, квитанцияНамерения: intent.1,
                     квитанцияТерминала: terminal, планПослеИсхода: plan)
    }

    private static func допустима(_ context: КонтекстФазыНормализации) -> Bool {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        return !context.идентификаторОперации.isEmpty
            && context.идентификаторОперации.utf8.count <= 80
            && context.идентификаторОперации.unicodeScalars.allSatisfy { allowed.contains($0) }
            && !context.назначение.isEmpty && context.назначение.count <= 65_536
            && !context.контрольнаяТочка.isEmpty && context.контрольнаяТочка.count <= 65_536
            && !context.время.isEmpty && context.время.utf8.count <= 128
            && (context.хэшОжидаемогоСнимка == nil
                || Self.этоSHA256(context.хэшОжидаемогоСнимка!))
    }

    private static func совпадает(_ record: ЗаписьФазы,
                                  context: КонтекстФазыНормализации) -> Bool {
        record.операция == context.идентификаторОперации
            && record.время == context.время
            && record.назначение == context.назначение
            && record.контрольнаяТочка == context.контрольнаяТочка
            && record.хэшОжидаемогоСнимка == context.хэшОжидаемогоСнимка
    }

    private static func провереноНамерение(
        _ record: ЗаписьФазы,
        context: КонтекстФазыНормализации
    ) -> Bool {
        guard совпадает(record, context: context),
              record.схема == "fuma.фаза-нормализации-намерение.1",
              record.вид == "intent",
              let witness = record.свидетельство else { return false }
        return record.хэшНамерения == ЖурналФазыНормализации.sha256(witness)
    }

    private static func legacyНамерениеСовпадает(
        _ record: ЗаписьФазы,
        context: КонтекстФазыНормализации
    ) -> Bool {
        guard record.время == nil || record.хэшОжидаемогоСнимка == nil,
              (record.время == nil || record.время == context.время),
              (record.хэшОжидаемогоСнимка == nil
                || record.хэшОжидаемогоСнимка == context.хэшОжидаемогоСнимка),
              record.схема == "fuma.фаза-нормализации-намерение.1",
              record.операция == context.идентификаторОперации,
              record.назначение == context.назначение,
              record.контрольнаяТочка == context.контрольнаяТочка,
              record.вид == "intent",
              let witness = record.свидетельство else { return false }
        return record.хэшНамерения == ЖурналФазыНормализации.sha256(witness)
    }

    private static func запись(_ outcome: ИсходФазыНормализации,
                               контекст: КонтекстФазыНормализации,
                               intentHash: String) -> ЗаписьФазы {
        switch outcome {
        case let .применено(witness):
            return .init(схема: "fuma.фаза-нормализации.1", операция: контекст.идентификаторОперации,
                время: контекст.время, назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: intentHash, вид: "applied", причина: nil, свидетельство: witness)
        case let .безИзменений(witness):
            return .init(схема: "fuma.фаза-нормализации.1", операция: контекст.идентификаторОперации,
                время: контекст.время, назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: intentHash, вид: "no-op", причина: nil, свидетельство: witness)
        case let .конфликт(reason, witness):
            return .init(схема: "fuma.фаза-нормализации.1", операция: контекст.идентификаторОперации,
                время: контекст.время, назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: intentHash, вид: "conflict", причина: reason, свидетельство: witness)
        case let .неизвестно(reason, witness):
            return .init(схема: "fuma.фаза-нормализации.1", операция: контекст.идентификаторОперации,
                время: контекст.время, назначение: контекст.назначение,
                контрольнаяТочка: контекст.контрольнаяТочка,
                хэшОжидаемогоСнимка: контекст.хэшОжидаемогоСнимка,
                хэшНамерения: intentHash, вид: "unknown", причина: reason, свидетельство: witness)
        }
    }

    private static func исход(_ record: ЗаписьФазы) -> ИсходФазыНормализации {
        switch record.вид {
        case "applied": .применено(свидетельство: record.свидетельство ?? Data())
        case "no-op": .безИзменений(свидетельство: record.свидетельство ?? Data())
        case "conflict": .конфликт(причина: record.причина ?? "сохранённый-конфликт", свидетельство: record.свидетельство)
        default: .неизвестно(причина: record.причина ?? "сохранённый-unknown", свидетельство: record.свидетельство)
        }
    }

    private static func известен(_ result: ИсходФазыНормализации) -> Bool {
        switch result {
        case let .применено(witness), let .безИзменений(witness): return !witness.isEmpty
        case .конфликт, .неизвестно: return false
        }
    }

    private static func нормализованныйИсход(
        _ result: ИсходФазыНормализации,
        context: КонтекстФазыНормализации,
        intentHash: String
    ) -> ИсходФазыНормализации {
        if case let .применено(witness) = result, witness.isEmpty {
            return .неизвестно(причина: "фаза-не-предъявила-свидетельство-наблюдения", свидетельство: nil)
        }
        if case let .безИзменений(witness) = result {
            guard let expected = context.хэшОжидаемогоСнимка,
                  let proof = try? JSONDecoder().decode(СвидетельствоNoOp.self, from: witness),
                  let canonical = try? Self.каноническиеБайты(proof), canonical == witness,
                  proof.схема == "fuma.свидетельство-no-op.1",
                  proof.операция == context.идентификаторОперации,
                  proof.видНаблюдения == "post-effect-readback",
                  !proof.идентификаторНаблюдения.isEmpty,
                  proof.хэшНамерения == intentHash,
                  proof.хэшЦелевогоСнимка == expected,
                  proof.хэшНаблюдённогоСнимка == expected else {
                return .неизвестно(причина: "no-op-не-сверен-с-закреплённой-целью-и-post-readback",
                                   свидетельство: nil)
            }
        }
        return result
    }

    private static func этоSHA256(_ value: String) -> Bool {
        value.utf8.count == 64 && value.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func каноническиеБайты<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var bytes = try encoder.encode(value)
        bytes.append(10)
        return bytes
    }
}

public extension ЦиклНаблюденийСостояния
where Поставщик == СистемныйПоставщикНаблюденийСостояния {
    init() {
        self.init(поставщик: СистемныйПоставщикНаблюденийСостояния())
    }
}

private func проверитьОднуРамкуJSONL(
    _ данные: Data
) throws -> КурсорРамокJSONL {
    let исход = try сверитьРамкиJSONL(
        БайтовыйСрезJSONL(начало: 0, данные: данные))
    guard case let .продолжение(завершённыеЗаписи, неполныйХвост, курсор) = исход,
          завершённыеЗаписи.count == 1,
          неполныйХвост == nil,
          завершённыеЗаписи[0].данные == данные else {
        throw ОшибкаЦиклаНаблюденийСостояния.неОднаЗавершённаяРамка
    }
    return курсор
}

private func разрешитьФизическийКаталог(_ адрес: URL) throws -> URL {
    guard адрес.isFileURL,
          адрес.path.hasPrefix("/"),
          !адрес.path.utf8.contains(0) else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    guard let физический = realpath(адрес.path, nil) else {
        throw ОшибкаКонтейнера.система(errno)
    }
    defer { free(физический) }
    return URL(
        fileURLWithPath: String(cString: физический),
        isDirectory: true)
}
