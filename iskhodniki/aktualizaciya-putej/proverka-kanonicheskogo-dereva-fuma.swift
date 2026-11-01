import CryptoKit
import Foundation

public struct ЗаписьФайлаКаноническогоДереваFUMA: Codable, Equatable, Sendable {
    public let путь: String
    public let режимGit: String
    public let sha256: String

    public init(путь: String, режимGit: String, sha256: String) {
        self.путь = путь
        self.режимGit = режимGit
        self.sha256 = sha256
    }
}

public enum ОшибкаКаноническогоДереваFUMA: Error, Equatable, Sendable {
    case нетКорня
    case небезопасныйПуть(String)
    case необычныйТип(String)
    case неожиданныйРежим(String)
    case несовпадениеСостава
    case несовпадениеДерева
    case несовпадениеСпискаПутей
    case старыйКореньСуществует
}

/// Сверяет `fuma/` с переданными значениями, не подтверждая их происхождение.
/// Успех сам по себе не доказывает право объявить NO_OP.
public enum ПроверкаКаноническогоДереваFUMA {
    public static let путьМаркера = "fuma/manifest-path-format.v2.json"
    public static let путьСписка = "fuma/manifest-path-format.v2.paths"

    public static func снятьСостав(кореньРепозитория: URL) throws -> [ЗаписьФайлаКаноническогоДереваFUMA] {
        let кореньFUMA = кореньРепозитория.appendingPathComponent("fuma", isDirectory: true)
        var записи: [ЗаписьФайлаКаноническогоДереваFUMA] = []
        try пройтиКаталог(кореньFUMA, корень: кореньРепозитория, записи: &записи)
        return записи.sorted { порядок($0.путь, $1.путь) }
    }

    public static func хэшДерева(_ записи: [ЗаписьФайлаКаноническогоДереваFUMA]) throws -> String {
        let упорядоченные = записи.sorted { порядок($0.путь, $1.путь) }
        var увиденные: Set<String> = []
        var вход = Data()
        for запись in упорядоченные {
            try проверитьПуть(запись.путь)
            guard запись.путь.hasPrefix("fuma/"),
                  запись.режимGit == "100644" || запись.режимGit == "100755",
                  запись.sha256.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil,
                  запись.путь != путьМаркера, запись.путь != путьСписка,
                  увиденные.insert(запись.путь).inserted else {
                throw ОшибкаКаноническогоДереваFUMA.небезопасныйПуть(запись.путь)
            }
            поле(запись.путь, в: &вход)
            поле(запись.режимGit, в: &вход)
            поле(запись.sha256, в: &вход)
        }
        return SHA256.hash(data: вход).map { String(format: "%02x", $0) }.joined()
    }

    public static func списокПутей(
        версия: String,
        исходныйКоммит: String,
        деревоИсточника: String,
        хэшВыходногоДерева: String,
        записи: [ЗаписьФайлаКаноническогоДереваFUMA]
    ) throws -> Data {
        // Текстовая версия списка использует LF как разделитель и не может
        // однозначно представить LF внутри поля. Хэш дерева остаётся байтовым.
        guard [версия, исходныйКоммит, деревоИсточника, хэшВыходногоДерева]
                .allSatisfy({ !$0.utf8.contains(10) }),
              записи.allSatisfy({ !$0.путь.utf8.contains(10) }) else {
            throw ОшибкаКаноническогоДереваFUMA.несовпадениеСпискаПутей
        }
        let хэшДерева = try хэшДерева(записи)
        guard хэшДерева == хэшВыходногоДерева else {
            throw ОшибкаКаноническогоДереваFUMA.несовпадениеДерева
        }
        let заголовки = [
            "schema=fum.fuma.path-format-path-set.v2",
            "version=" + версия,
            "sourceCommit=" + исходныйКоммит,
            "sourceTree=" + деревоИсточника,
            "outputTreeSHA256=" + хэшВыходногоДерева
        ]
        let элементы = записи.sorted { порядок($0.путь, $1.путь) }.map {
            $0.режимGit + " " + $0.sha256 + " " + $0.путь
        }
        return Data((заголовки + элементы).joined(separator: "\n").appending("\n").utf8)
    }

    public static func проверить(
        кореньРепозитория: URL,
        исходныйКорень: String,
        версия: String,
        исходныйКоммит: String,
        деревоИсточника: String,
        хэшВыходногоДерева: String,
        ожидаемыеЗаписи: [ЗаписьФайлаКаноническогоДереваFUMA],
        байтыСпискаПутей: Data
    ) throws {
        guard !существуетВключаяСсылку(кореньРепозитория.appendingPathComponent(исходныйКорень)) else {
            throw ОшибкаКаноническогоДереваFUMA.старыйКореньСуществует
        }
        let ожидаемые = ожидаемыеЗаписи.sorted { порядок($0.путь, $1.путь) }
        let фактические = try снятьСостав(кореньРепозитория: кореньРепозитория)
        guard фактические == ожидаемые else {
            throw ОшибкаКаноническогоДереваFUMA.несовпадениеСостава
        }
        guard try хэшДерева(фактические) == хэшВыходногоДерева else {
            throw ОшибкаКаноническогоДереваFUMA.несовпадениеДерева
        }
        let ожидаемыйСписок = try списокПутей(
            версия: версия,
            исходныйКоммит: исходныйКоммит,
            деревоИсточника: деревоИсточника,
            хэшВыходногоДерева: хэшВыходногоДерева,
            записи: ожидаемые)
        guard байтыСпискаПутей == ожидаемыйСписок else {
            throw ОшибкаКаноническогоДереваFUMA.несовпадениеСпискаПутей
        }
    }

    private static func пройтиКаталог(
        _ каталог: URL,
        корень: URL,
        записи: inout [ЗаписьФайлаКаноническогоДереваFUMA]
    ) throws {
        let атрибуты = try FileManager.default.attributesOfItem(atPath: каталог.path)
        guard let тип = атрибуты[.type] as? FileAttributeType else {
            throw ОшибкаКаноническогоДереваFUMA.необычныйТип(каталог.path)
        }
        guard тип == .typeDirectory else {
            throw ОшибкаКаноническогоДереваFUMA.необычныйТип(каталог.path)
        }
        let дети = try FileManager.default.contentsOfDirectory(
            at: каталог, includingPropertiesForKeys: nil, options: [])
            .sorted { порядок($0.lastPathComponent, $1.lastPathComponent) }
        for ребёнок in дети {
            let атрибутыРебёнка = try FileManager.default.attributesOfItem(atPath: ребёнок.path)
            guard let типРебёнка = атрибутыРебёнка[.type] as? FileAttributeType else {
                throw ОшибкаКаноническогоДереваFUMA.необычныйТип(ребёнок.path)
            }
            if типРебёнка == .typeDirectory {
                try пройтиКаталог(ребёнок, корень: корень, записи: &записи)
                continue
            }
            guard типРебёнка == .typeRegular else {
                throw ОшибкаКаноническогоДереваFUMA.необычныйТип(ребёнок.path)
            }
            let путьРепозитория = try относительныйПуть(ребёнок, от: корень)
            if путьРепозитория == путьМаркера || путьРепозитория == путьСписка { continue }
            guard let режимЧислом = атрибутыРебёнка[.posixPermissions] as? NSNumber else {
                throw ОшибкаКаноническогоДереваFUMA.неожиданныйРежим(путьРепозитория)
            }
            let режим = try режимGit(режимЧислом.intValue, путь: путьРепозитория)
            let данные = try Data(contentsOf: ребёнок, options: [.mappedIfSafe])
            записи.append(.init(путь: путьРепозитория, режимGit: режим, sha256: хэш(данные)))
        }
    }

    private static func режимGit(_ права: Int, путь: String) throws -> String {
        switch права {
        case 0o644: "100644"
        case 0o755: "100755"
        default: throw ОшибкаКаноническогоДереваFUMA.неожиданныйРежим(путь)
        }
    }

    private static func существуетВключаяСсылку(_ путь: URL) -> Bool {
        (try? FileManager.default.attributesOfItem(atPath: путь.path)) != nil
    }

    private static func относительныйПуть(_ url: URL, от корня: URL) throws -> String {
        let префикс = корня.standardizedFileURL.path + "/"
        let полныйПуть = url.standardizedFileURL.path
        guard полныйПуть.hasPrefix(префикс) else {
            throw ОшибкаКаноническогоДереваFUMA.небезопасныйПуть(полныйПуть)
        }
        return String(полныйПуть.dropFirst(префикс.count))
    }

    private static func проверитьПуть(_ путь: String) throws {
        guard !путь.isEmpty, путь.utf8.count <= 1024,
              !путь.utf8.contains(92), !путь.hasPrefix("/"),
              путь.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({
                  !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git"
              }) else {
            throw ОшибкаКаноническогоДереваFUMA.небезопасныйПуть(путь)
        }
    }

    private static func поле(_ строка: String, в данные: inout Data) {
        let байты = Data(строка.utf8)
        var длина = UInt64(байты.count).bigEndian
        withUnsafeBytes(of: &длина) { данные.append(contentsOf: $0) }
        данные.append(байты)
    }

    private static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private static func порядок(_ левый: String, _ правый: String) -> Bool {
        Data(левый.utf8).lexicographicallyPrecedes(Data(правый.utf8))
    }
}
