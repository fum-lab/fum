import Foundation
import CryptoKit

public struct ЗаписьПроверки: Codable, Equatable, Sendable {
    public enum Исход: String, Codable, Sendable {
        case выполнено
        case неЗапускалось = "не запускалось"
        case неизвестно
        case отказ
    }

    public let исход: Исход
    public let основание: String

    public init(исход: Исход, основание: String) {
        self.исход = исход
        self.основание = основание
    }
}

public struct ГрантПрофиля: Codable, Equatable, Sendable {
    public let корневойUUID: String
    public let основаниеSHA256: String
    public let область: [String]
    public let писателей: Int
    public let остановкаСохранена: Bool

    public init(корневойUUID: String, основаниеSHA256: String, область: [String], писателей: Int, остановкаСохранена: Bool) {
        self.корневойUUID = корневойUUID
        self.основаниеSHA256 = основаниеSHA256
        self.область = область
        self.писателей = писателей
        self.остановкаСохранена = остановкаСохранена
    }
}

public struct GitОснова: Codable, Equatable, Sendable {
    public let commit: String
    public let tree: String
    public let ref: String
    public let кореньWorktreeSHA256: String

    public init(commit: String, tree: String, ref: String, кореньWorktreeSHA256: String) {
        self.commit = commit
        self.tree = tree
        self.ref = ref
        self.кореньWorktreeSHA256 = кореньWorktreeSHA256
    }
}

public struct КоррекцияПроисхождения: Codable, Equatable, Sendable {
    public let ошибочныйКоммит: String
    public let ошибочноВыбранныйNativeUUID: String
    public let собственнаяМодель: String
    public let собственноеУсилие: String
    public let проекцияАвтора: String
    public let строкаSHA256: String
    public let байтыВнеGit: String
    public let историческийBackend: String

    public init(
        ошибочныйКоммит: String,
        ошибочноВыбранныйNativeUUID: String,
        собственнаяМодель: String,
        собственноеУсилие: String,
        проекцияАвтора: String,
        строкаSHA256: String,
        байтыВнеGit: String,
        историческийBackend: String
    ) {
        self.ошибочныйКоммит = ошибочныйКоммит
        self.ошибочноВыбранныйNativeUUID = ошибочноВыбранныйNativeUUID
        self.собственнаяМодель = собственнаяМодель
        self.собственноеУсилие = собственноеУсилие
        self.проекцияАвтора = проекцияАвтора
        self.строкаSHA256 = строкаSHA256
        self.байтыВнеGit = байтыВнеGit
        self.историческийBackend = историческийBackend
    }
}

public struct ПрофильСнимка: Codable, Equatable, Sendable {
    public let схема: String
    public let собственныйNativeUUID: String
    public let грант: ГрантПрофиля
    public let основа: GitОснова
    public let автор: String
    public let модель: String
    public let коррекцияПроисхождения: КоррекцияПроисхождения
    public let проверки: [String: ЗаписьПроверки]
    public let неизвестныйОстаток: [String]

    private enum CodingKeys: String, CodingKey {
        case схема
        case собственныйNativeUUID = "sourceOwnNativeUUID"
        case грант
        case основа
        case автор
        case модель
        case коррекцияПроисхождения
        case проверки
        case неизвестныйОстаток
    }

    public init(
        схема: String,
        собственныйNativeUUID: String,
        грант: ГрантПрофиля,
        основа: GitОснова,
        автор: String,
        модель: String,
        коррекцияПроисхождения: КоррекцияПроисхождения,
        проверки: [String: ЗаписьПроверки],
        неизвестныйОстаток: [String]
    ) {
        self.схема = схема
        self.собственныйNativeUUID = собственныйNativeUUID
        self.грант = грант
        self.основа = основа
        self.автор = автор
        self.модель = модель
        self.коррекцияПроисхождения = коррекцияПроисхождения
        self.проверки = проверки
        self.неизвестныйОстаток = неизвестныйОстаток
    }
}

public struct ОшибкаПрофиля: Error, Equatable, Sendable {
    public let причина: String

    public init(_ причина: String) { self.причина = причина }
}

/// Checks internal consistency of this task-scoped checkpoint only. It does not verify independent grant or live Git authority.
public enum ПроверкаСохраняющегоПрофиля {
    public static let схема = "fum.preserving-checkpoint.2"
    private static let исправляемыйКоммит = "f51640731bba74b4150ce1abbce84b120a41d77f"

    // This exact allowlist is local to the explicit task grant, not a repository-wide FUM admission policy.
    private static let областьПоУмолчанию: Set<String> = [
        "AGENTS.md",
        "Правила/агентов/журнал-и-происхождение.md",
        "Правила/агентов/проверки-коммит-и-публикация.md",
        "Правила/агентов/инвентарь-правил.json",
        "Инструменты/fum-dekompoziciya-pravil-agentov/SKILL.md",
        "Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py",
        "Инструменты/fum-dekompoziciya-pravil-agentov/tests/фикстуры/профили-продолжения.json",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Источник.md",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Профиль.json",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Package.swift",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Sources/ПрофильСохраняющейКонтрольнойТочки/Проверка.swift",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Sources/ПроверитьПрофиль/main.swift",
        "Инструменты/fum-dekompoziciya-pravil-agentov/ПрофильСохраняющейКонтрольнойТочки/Tests/ПрофильСохраняющейКонтрольнойТочкиTests/ПроверкаTests.swift"
    ]

    private static let обязательныеПроверки: Set<String> = [
        "native_swift_positive", "native_swift_negative", "legacy_python", "root_jsonl", "publication"
    ]

    public static func проверить(
        _ данные: Data,
        источник: Data,
        собственныйNativeUUID: String,
        собственнаяСтрока: Data,
        кореньWorktree: String
    ) throws -> ПрофильСнимка {
        let decoder = JSONDecoder()
        let профиль: ПрофильСнимка
        do {
            профиль = try decoder.decode(ПрофильСнимка.self, from: данные)
        } catch {
            throw ОшибкаПрофиля("повреждённый JSON профиля: \(error)")
        }

        guard профиль.схема == схема else { throw ОшибкаПрофиля("неизвестная схема") }
        guard Self.верныйUUID(профиль.грант.корневойUUID) else { throw ОшибкаПрофиля("неверный UUID корневой задачи") }
        guard Self.верныйUUID(профиль.собственныйNativeUUID), Self.верныйUUID(собственныйNativeUUID)
        else { throw ОшибкаПрофиля("неверный собственный native UUID") }
        guard профиль.собственныйNativeUUID == собственныйNativeUUID
        else { throw ОшибкаПрофиля("собственный native UUID профиля не совпадает с вызовом") }
        guard профиль.собственныйNativeUUID != профиль.грант.корневойUUID
        else { throw ОшибкаПрофиля("корневой UUID подменил собственный native UUID источника") }

        let строка = try Self.разобратьСобственнуюСтроку(собственнаяСтрока)
        guard строка.uuid == профиль.собственныйNativeUUID
        else { throw ОшибкаПрофиля("собственная SQLite-строка относится к другой задаче") }
        guard строка.кореньWorktree == кореньWorktree
        else { throw ОшибкаПрофиля("собственная SQLite-строка относится к другому worktree") }

        let коррекция = профиль.коррекцияПроисхождения
        guard коррекция.ошибочныйКоммит == Self.исправляемыйКоммит,
              коррекция.ошибочноВыбранныйNativeUUID == профиль.грант.корневойUUID,
              коррекция.собственнаяМодель == строка.модель,
              коррекция.собственноеУсилие == строка.усилие,
              коррекция.проекцияАвтора == "FUM Codex [\(строка.модель); effort=\(строка.усилие)]",
              коррекция.строкаSHA256 == Self.sha256(собственнаяСтрока),
              Self.безопасныйПуть(коррекция.байтыВнеGit),
              коррекция.историческийBackend == "неизвестно"
        else { throw ОшибкаПрофиля("коррекция происхождения не связана с собственной SQLite-строкой") }
        guard профиль.модель == строка.модель, профиль.автор == коррекция.проекцияАвтора
        else { throw ОшибкаПрофиля("модель или автор не выведены из собственной SQLite-строки") }

        guard профиль.грант.основаниеSHA256 == Self.sha256(источник) else { throw ОшибкаПрофиля("источник гранта не совпадает с хэшем") }
        guard !профиль.грант.область.isEmpty,
              Set(профиль.грант.область).count == профиль.грант.область.count,
              Set(профиль.грант.область).isSubset(of: Self.областьПоУмолчанию),
              профиль.грант.область.allSatisfy(Self.безопасныйПуть)
        else { throw ОшибкаПрофиля("область гранта расширена или неоднозначна") }
        guard профиль.грант.писателей == 1 else { throw ОшибкаПрофиля("профиль допускает не одного писателя") }
        guard профиль.грант.остановкаСохранена else { throw ОшибкаПрофиля("граница STOP не подтверждена") }
        guard Self.oid(профиль.основа.commit), Self.oid(профиль.основа.tree),
              профиль.основа.ref.hasPrefix("refs/heads/codex/"),
              профиль.основа.кореньWorktreeSHA256 == Self.sha256(Data(кореньWorktree.utf8))
        else { throw ОшибкаПрофиля("Git-основа неполная или неадресная") }
        guard Set(профиль.проверки.keys) == Self.обязательныеПроверки else { throw ОшибкаПрофиля("состав проверок не совпадает с профилем") }
        guard профиль.проверки["native_swift_positive"]?.исход == .выполнено,
              профиль.проверки["native_swift_negative"]?.исход == .выполнено
        else { throw ОшибкаПрофиля("нужны положительный и отрицательный нативные случаи") }
        guard профиль.проверки["legacy_python"]?.исход == .неЗапускалось,
              профиль.проверки["root_jsonl"]?.исход == .неЗапускалось
        else { throw ОшибкаПрофиля("исключённые проверки должны оставаться незапущенными") }
        guard !профиль.неизвестныйОстаток.isEmpty else { throw ОшибкаПрофиля("неизвестный исход нельзя сводить к полной приёмке") }
        return профиль
    }

    private static func разобратьСобственнуюСтроку(
        _ данные: Data
    ) throws -> (uuid: String, модель: String, усилие: String, кореньWorktree: String) {
        guard данные.last == 0x0A,
              !данные.dropLast().contains(0x0A),
              !данные.contains(0x0D),
              let строка = String(data: Data(данные.dropLast()), encoding: .utf8)
        else { throw ОшибкаПрофиля("собственная SQLite-строка должна быть одной UTF-8 TSV-строкой с конечным LF") }

        let поля = строка.split(separator: "\t", omittingEmptySubsequences: false)
        guard поля.count == 4, поля.allSatisfy({ !$0.isEmpty })
        else { throw ОшибкаПрофиля("собственная SQLite-строка должна содержать UUID, модель, effort и cwd") }

        return (String(поля[0]), String(поля[1]), String(поля[2]), String(поля[3]))
    }

    private static func безопасныйПуть(_ путь: String) -> Bool {
        !путь.hasPrefix("/") && !путь.contains("..") && !путь.contains("*")
    }

    private static func oid(_ значение: String) -> Bool {
        значение.count == 40 && значение.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    private static func верныйUUID(_ значение: String) -> Bool {
        UUID(uuidString: значение)?.uuidString.lowercased() == значение.lowercased()
    }

    private static func sha256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
}
