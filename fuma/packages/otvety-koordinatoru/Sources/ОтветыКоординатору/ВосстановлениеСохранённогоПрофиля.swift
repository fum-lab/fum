import CryptoKit
import Foundation

/// Снимок контекста, который должен быть заново получен после восстановления.
/// Значения из самого сохранённого профиля не могут заменить этот источник.
public struct КонтекстВосстановленияПрофиля: Equatable, Sendable {
    public let физическийW: String
    public let исполнитель: String
    public let наблюдённыйHEAD: String
    public let полныйRef: String
    public let assignmentPin: String
    public let sha256Исходника: String
    public let байтовИсходника: Int
    public let версияСостояния: UInt64
    public let арендаДействуетДо: Date
    public let момент: Date

    init(физическийW: String, исполнитель: String, наблюдённыйHEAD: String,
        полныйRef: String, assignmentPin: String, sha256Исходника: String,
        байтовИсходника: Int, версияСостояния: UInt64, арендаДействуетДо: Date, момент: Date) {
        self.физическийW = физическийW
        self.исполнитель = исполнитель
        self.наблюдённыйHEAD = наблюдённыйHEAD
        self.полныйRef = полныйRef
        self.assignmentPin = assignmentPin
        self.sha256Исходника = sha256Исходника
        self.байтовИсходника = байтовИсходника
        self.версияСостояния = версияСостояния
        self.арендаДействуетДо = арендаДействуетДо
        self.момент = момент
    }
}

public enum СтатусВосстановленияПрофиля: String, Codable, Sendable {
    case восстановленДляПодготовки
    case неизвестно
}

public enum ИсключённаяПроцедураПрофиля: String, Codable, Sendable {
    case python
    case legacyRouter
    case legacyJournalDispatch
    case произвольныйShellИлиProcess
    case новыйRunnerИлиChecker
    case compilerTestRuntimeИлиSourceWriteStart
}

public enum ЗапрошеннаяПроцедураПрофиля: Sendable {
    case обычноеРедактированиеJSONЧерезИнтерпретатор
    case legacyRouter
    case произвольныйShellИлиProcess
}

public enum РешениеПоПроцедуреПрофиля: Equatable, Sendable {
    case исключена
    case неизвестно
}

public enum ОшибкаСохранённогоПрофиля: Error, Equatable {
    case hashЗакреплённогоСнимкаНеСовпадает
    case контекстНеСовпадает
}

/// Проверенный снимок остаётся данными. Он не выдаёт разрешение на запуск эффекта.
public struct ВосстановленныйПрофиль: Equatable, Sendable {
    public let сырыеБайты: Data
    public let sha256: String
    public let идентификатор: String
    public let версия: String
    public let физическийW: String
    public let исполнитель: String
    public let наблюдённыйHEAD: String
    public let полныйRef: String
    public let assignmentPin: String
    public let sha256Исходника: String
    public let байтовИсходника: Int
    public let версияСостояния: UInt64
    public let арендаДействуетДо: Date
    public let разрешённыеПути: [String]
    public let исключения: Set<ИсключённаяПроцедураПрофиля>
    public let проверяющийИзвестен: Bool

    /// Профиль задаёт исключения, но не выдаёт общий допуск к запуску процедур.
    public func оценить(_ процедура: ЗапрошеннаяПроцедураПрофиля) -> РешениеПоПроцедуреПрофиля {
        switch процедура {
        case .обычноеРедактированиеJSONЧерезИнтерпретатор:
            return исключения.contains(.python) ? .исключена : .неизвестно
        case .legacyRouter:
            return исключения.contains(.legacyRouter) ? .исключена : .неизвестно
        case .произвольныйShellИлиProcess:
            return исключения.contains(.произвольныйShellИлиProcess) ? .исключена : .неизвестно
        }
    }

    init(сырыеБайты: Data, sha256: String, идентификатор: String, версия: String,
        физическийW: String, исполнитель: String, наблюдённыйHEAD: String, полныйRef: String,
        assignmentPin: String, sha256Исходника: String, байтовИсходника: Int,
        версияСостояния: UInt64, арендаДействуетДо: Date,
        разрешённыеПути: [String], исключения: Set<ИсключённаяПроцедураПрофиля>,
        проверяющийИзвестен: Bool) {
        self.сырыеБайты = сырыеБайты
        self.sha256 = sha256
        self.идентификатор = идентификатор
        self.версия = версия
        self.физическийW = физическийW
        self.исполнитель = исполнитель
        self.наблюдённыйHEAD = наблюдённыйHEAD
        self.полныйRef = полныйRef
        self.assignmentPin = assignmentPin
        self.sha256Исходника = sha256Исходника
        self.байтовИсходника = байтовИсходника
        self.версияСостояния = версияСостояния
        self.арендаДействуетДо = арендаДействуетДо
        self.разрешённыеПути = разрешённыеПути
        self.исключения = исключения
        self.проверяющийИзвестен = проверяющийИзвестен
    }
}

public struct РезультатВосстановленияПрофиля: Equatable, Sendable {
    public let статус: СтатусВосстановленияПрофиля
    public let профиль: ВосстановленныйПрофиль?
    public let причины: [String]
    /// Всегда пусто при восстановлении: этот компонент не запускает процедуры.
    public let выбранныеПроцедуры: [String]

    fileprivate init(статус: СтатусВосстановленияПрофиля, профиль: ВосстановленныйПрофиль?,
        причины: [String]) {
        self.статус = статус
        self.профиль = профиль
        self.причины = причины
        self.выбранныеПроцедуры = []
    }
}

/// Точный JSON-снимок остаётся opaque bytes; decoded fields используются лишь для fail-closed проверки.
public enum ВосстановлениеСохранённогоПрофиля {
    /// Внешне закреплённая идентичность raw-профиля; hash от вызывающего сам по себе не полномочие.
    public static let sha256ЗакреплённогоСнимка = "7ca601a82f218611d23541e972cc247cee39871630ecd81536827d1d6207ca7f"
    private static let sha256ИсходногоПреобразуемогоSource = "3ddf1dd07f4f413a0b4f1dde766b2ed84a94044dfaeee5983ed6ced7a671a367"
    private static let размерИсходногоПреобразуемогоSource = 39_565
    private static let разрешённыеПути = [
        "fuma/packages/otvety-koordinatoru/Package.swift",
        "fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ОператорШтатныхОтветов.swift",
        "fuma/packages/otvety-koordinatoru/Tests/ПроверкиОтветовКоординатору/ПроверкиОператораШтатныхОтветов.swift",
        "fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ВосстановлениеСохранённогоПрофиля.swift",
        "fuma/packages/otvety-koordinatoru/Tests/ПроверкиОтветовКоординатору/ПроверкиВосстановленияПрофиля.swift"
    ]
    private static let точныеИсключения = [
        "Python в любой форме, включая оболочку-обёртку",
        "legacy Python router независимо от текущего лимита",
        "legacy Journal start/global dispatch/FIFO/pool/CAS",
        "произвольный unadmitted shell/Process fallback",
        "новый Node/Python runner или checker",
        "compiler/test/runtime/sourceWriteCommand START без отдельного exactR M/argv/slot допуска"
    ]
    static let исключённыеПроцедурыПрофиля: Set<ИсключённаяПроцедураПрофиля> = [
        .python, .legacyRouter, .legacyJournalDispatch,
        .произвольныйShellИлиProcess, .новыйRunnerИлиChecker,
        .compilerTestRuntimeИлиSourceWriteStart
    ]

    private struct Снимок: Decodable {
        struct Граница: Decodable {
            struct Source: Decodable { let path: String; let bytes: Int; let sha256: String }
            let физическийW: String
            let наблюдённыйHEAD: String
            let полныйRef: String
            let область: String
            let путиЗаписи: [String]
            let фактическийПреобразуемыйSource: Source
        }
        struct Исключения: Decodable { let команды: [String] }
        struct Checker: Decodable { let статус: String }
        struct Разрешено: Decodable { let sourceOnly: Bool; let проверяющий: Checker }
        let схема: String
        let версия: String
        let идентификатор: String
        let родитель: String
        let исполнитель: String
        let граница: Граница
        let исключения: Исключения
        let разрешеноСейчас: Разрешено
    }

    /// Возвращает durable payload с исходными байтами профиля и снимком assignment-контекста.
    /// Фактическое custody-хранение выполняет только согласованный адаптер.
    public static func сохранитьТочныйСнимок(_ байты: Data,
        контекст: КонтекстВосстановленияПрофиля) throws -> Data {
        guard хэш(байты) == sha256ЗакреплённогоСнимка else {
            throw ОшибкаСохранённогоПрофиля.hashЗакреплённогоСнимкаНеСовпадает
        }
        guard контекст.assignmentPin == "01a17797-519b-73c1-bcc8-fd295cdfe9b0",
              контекст.арендаДействуетДо > контекст.момент else {
            throw ОшибкаСохранённогоПрофиля.контекстНеСовпадает
        }
        // Контейнер хранит актуальные pin состояния и исходные байты профиля без изменений.
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let контейнер = try кодировщик.encode(Конверт(байты: байты, sha256: хэш(байты),
            версия: "routine-delivery-profile.1", контекст: контекст))
        guard восстановить(контейнер, ожидаемыйSHA256: sha256ЗакреплённогоСнимка,
            текущийКонтекст: контекст).профиль != nil else {
            throw ОшибкаСохранённогоПрофиля.контекстНеСовпадает
        }
        return контейнер
    }

    public static func восстановить(_ конвертБайты: Data?, ожидаемыйSHA256: String,
        текущийКонтекст: КонтекстВосстановленияПрофиля) -> РезультатВосстановленияПрофиля {
        guard let конвертБайты, !конвертБайты.isEmpty,
              let конверт = try? JSONDecoder().decode(Конверт.self, from: конвертБайты),
              !конверт.байты.isEmpty,
              конверт.схема == "fum.снимок-восстановления-профиля.1",
              конверт.sha256Профиля == хэш(конверт.байты),
              конверт.sha256Профиля == ожидаемыйSHA256,
              конверт.версияПрофиля == "routine-delivery-profile.1",
              конверт.контекст.физическийW == текущийКонтекст.физическийW,
              конверт.контекст.исполнитель == текущийКонтекст.исполнитель,
              конверт.контекст.наблюдённыйHEAD == текущийКонтекст.наблюдённыйHEAD,
              конверт.контекст.полныйRef == текущийКонтекст.полныйRef,
              конверт.контекст.assignmentPin == текущийКонтекст.assignmentPin,
              конверт.контекст.sha256Исходника == текущийКонтекст.sha256Исходника,
              конверт.контекст.байтовИсходника == текущийКонтекст.байтовИсходника,
              конверт.контекст.версияСостояния == текущийКонтекст.версияСостояния,
              конверт.контекст.арендаДействуетДо == текущийКонтекст.арендаДействуетДо else {
            return неизвестно("сохранённый профиль отсутствует или повреждён")
        }
        let сыройSHA = хэш(конверт.байты)
        guard сыройSHA == ожидаемыйSHA256,
              ожидаемыйSHA256 == sha256ЗакреплённогоСнимка,
              let снимок = try? JSONDecoder().decode(Снимок.self, from: конверт.байты),
              снимок.схема == "fum.сохранённый-профиль-программы.1",
              снимок.версия == "routine-delivery-profile.1",
              снимок.родитель == текущийКонтекст.assignmentPin,
              снимок.граница.физическийW == текущийКонтекст.физическийW,
              снимок.исполнитель == текущийКонтекст.исполнитель,
              снимок.граница.наблюдённыйHEAD == текущийКонтекст.наблюдённыйHEAD,
              снимок.граница.полныйRef == текущийКонтекст.полныйRef,
              снимок.граница.фактическийПреобразуемыйSource.path
                == "fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ОператорШтатныхОтветов.swift",
              снимок.граница.путиЗаписи == разрешённыеПути,
              снимок.граница.путиЗаписи.contains(снимок.граница.фактическийПреобразуемыйSource.path),
              снимок.граница.фактическийПреобразуемыйSource.bytes == размерИсходногоПреобразуемогоSource,
              снимок.граница.фактическийПреобразуемыйSource.sha256 == sha256ИсходногоПреобразуемогоSource,
              снимок.граница.путиЗаписи.contains("fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ВосстановлениеСохранённогоПрофиля.swift"),
              снимок.граница.путиЗаписи.contains("fuma/packages/otvety-koordinatoru/Tests/ПроверкиОтветовКоординатору/ПроверкиВосстановленияПрофиля.swift"),
              снимок.разрешеноСейчас.sourceOnly,
              снимок.разрешеноСейчас.проверяющий.статус == "UNKNOWN_NOT_BUILT_FOR_THIS_PROFILE",
              снимок.исключения.команды == точныеИсключения,
              !текущийКонтекст.assignmentPin.isEmpty,
              текущийКонтекст.арендаДействуетДо > текущийКонтекст.момент,
              корректныйSHA(текущийКонтекст.sha256Исходника),
              текущийКонтекст.байтовИсходника > 0 else {
            return неизвестно("профиль не совпадает с текущими pin, схемой, исключениями или границей")
        }
        let профиль = ВосстановленныйПрофиль(сырыеБайты: конверт.байты, sha256: сыройSHA,
            идентификатор: снимок.идентификатор, версия: снимок.версия,
            физическийW: снимок.граница.физическийW, исполнитель: снимок.исполнитель,
            наблюдённыйHEAD: снимок.граница.наблюдённыйHEAD, полныйRef: снимок.граница.полныйRef,
            assignmentPin: снимок.родитель, sha256Исходника: текущийКонтекст.sha256Исходника,
            байтовИсходника: текущийКонтекст.байтовИсходника,
            версияСостояния: текущийКонтекст.версияСостояния,
            арендаДействуетДо: текущийКонтекст.арендаДействуетДо,
            разрешённыеПути: снимок.граница.путиЗаписи,
            исключения: исключённыеПроцедурыПрофиля, проверяющийИзвестен: false)
        return РезультатВосстановленияПрофиля(статус: .восстановленДляПодготовки, профиль: профиль,
            причины: ["точные raw bytes и отрицательные исключения восстановлены; checker остаётся UNKNOWN"])
    }

    private static func неизвестно(_ причина: String) -> РезультатВосстановленияПрофиля {
        РезультатВосстановленияПрофиля(статус: .неизвестно, профиль: nil, причины: [причина])
    }

    static func хэш(_ байты: Data) -> String {
        SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
    }

    private static func корректныйSHA(_ значение: String) -> Bool {
        значение.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil
    }
}

private struct Конверт: Codable {
    let схема: String
    let байты: Data
    let sha256Профиля: String
    let версияПрофиля: String
    let контекст: СохранённыйКонтекст

    init(байты: Data, sha256: String, версия: String, контекст: КонтекстВосстановленияПрофиля) {
        self.схема = "fum.снимок-восстановления-профиля.1"
        self.байты = байты
        self.sha256Профиля = sha256
        self.версияПрофиля = версия
        self.контекст = СохранённыйКонтекст(контекст)
    }
}

private struct СохранённыйКонтекст: Codable {
    let физическийW: String
    let исполнитель: String
    let наблюдённыйHEAD: String
    let полныйRef: String
    let assignmentPin: String
    let sha256Исходника: String
    let байтовИсходника: Int
    let версияСостояния: UInt64
    let арендаДействуетДо: Date

    init(_ контекст: КонтекстВосстановленияПрофиля) {
        self.физическийW = контекст.физическийW
        self.исполнитель = контекст.исполнитель
        self.наблюдённыйHEAD = контекст.наблюдённыйHEAD
        self.полныйRef = контекст.полныйRef
        self.assignmentPin = контекст.assignmentPin
        self.sha256Исходника = контекст.sha256Исходника
        self.байтовИсходника = контекст.байтовИсходника
        self.версияСостояния = контекст.версияСостояния
        self.арендаДействуетДо = контекст.арендаДействуетДо
    }
}
