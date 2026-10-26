import Foundation
import CryptoKit

enum ОшибкаПутей: Error, CustomStringConvertible {
    case отказ(String)
    var description: String {
        switch self { case .отказ(let причина): причина }
    }
}

func хэшПутей(_ байты: Data) -> String {
    SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
}

func байтыПлана<Значение: Encodable>(_ значение: Значение) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(значение) + Data([10])
}

func порядокПутей(_ левый: String, _ правый: String) -> Bool {
    левый.utf8.lexicographicallyPrecedes(правый.utf8)
}

struct ЗаписьСнимкаПутей: Codable, Equatable, Sendable {
    var путь: String
    var тип: String = "файл"
    var режим: String = "100644"
    var объект: String? = nil
    var sha256: String? = nil
    var путь_индекса: String? = nil
    var режим_индекса: String? = nil
}

struct СнимокПутей: Codable, Equatable, Sendable {
    var коммит: String
    var дерево: String
    var ветка: String
    var индекс_sha256: String
    var индекс_изменён: Bool
    var записи: [ЗаписьСнимкаПутей]
    var пространство_sha256: String = ""

    func подпись() throws -> String {
        var копия = self
        копия.записи.sort { порядокПутей($0.путь, $1.путь) }
        return try хэшПутей(байтыПлана(копия))
    }
}

struct ЗанятыйПуть: Codable, Equatable, Sendable {
    var путь: String
    var владелец: String
}

struct КонтекстПутей: Codable, Equatable, Sendable {
    var корень: String
    var владелец: String
    var писатель: String
    var целевая_ветка: String
    var ветки: [String] = []
    var занятые_пути: [ЗанятыйПуть] = []
}

struct ОтображениеПути: Codable, Equatable, Sendable {
    var исходный: String
    var целевой: String
}

struct ИсключениеИмени: Codable, Equatable, Sendable {
    var путь: String
    var имя: String
    var причина: String
    var источник: String
}

struct ПрепятствиеПути: Codable, Hashable, Sendable {
    var код: String
    var пути: [String]
}

struct СсылкаПути: Codable, Equatable, Sendable {
    var файл: String
    var строка: Int
    var вид: String
    var состояние: String
}

struct ПланПутей: Codable, Equatable, Sendable {
    var схема = "fum.план-актуализации-путей.1"
    var корень: String
    var владелец: String
    var ветка: String
    var писатель: String
    var выбранные_области: [String] = []
    var снимок: СнимокПутей
    var снимок_sha256: String
    var отображение_sha256: String
    var вход_sha256: String = ""
    var алгоритм = "fum.пути.unicode-boundary.Cyrl-Latn.ru.ascii-lower-kebab.1"
    var ревизия = "837e2ce107b97ee7b9d3344c9fe99142281fe393"
    var реестр_имён = "Инструменты/реестр-названий-автоматизаций.json"
    var политика_границ_sha256 = "5a52f1134876854e29db243cbfc6eebc86cc916a4d354ba73a0fc7516109bcd4"
    var отображения: [ОтображениеПути]
    var исключения: [ИсключениеИмени]
    var препятствия: [ПрепятствиеПути]
    var ссылки: [СсылкаПути] = []
    var охват_ссылок = "кандидаты выбранной области; внешние ссылки и применение не проверены"
    var применение_разрешено = false
    var программа = ["инвентаризация", "отображение", "дешёвая проверка", "diff/план",
                     "проверяемое применение — не реализовано", "обновление ссылок — не реализовано",
                     "сверка сохранённого плана"]
}

enum АнализСсылокПутей {
    static func собрать(_ тексты: [Data: Data]) -> [СсылкаПути] {
        var итог: [СсылкаПути] = []
        for ключ in тексты.keys.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            let файл = String(decoding: ключ, as: UTF8.self)
            guard let текст = String(data: тексты[ключ]!, encoding: .utf8) else {
                итог.append(СсылкаПути(файл: файл, строка: 0, вид: "двоичный/неUTF8", состояние: "не проверено")); continue
            }
            let защищённый = файл.hasPrefix("Источники/") || файл.hasPrefix("Журнал/") || файл.hasSuffix(".jsonl")
            if защищённый {
                итог.append(СсылкаПути(файл: файл, строка: 0, вид: "история/источник", состояние: "историческое/дословное — сохранено")); continue
            }
            let расширение = (файл as NSString).pathExtension.lowercased()
            let код = ["swift", "py", "sh", "c", "h", "js", "cjs"].contains(расширение)
            let конфигурация = ["json", "toml", "yaml", "yml", "plist", "pbxproj"].contains(расширение)
            var ограда = false
            for (номер, строка) in текст.components(separatedBy: "\n").enumerated() {
                let начало = строка.trimmingCharacters(in: .whitespaces)
                if начало.hasPrefix("```") || начало.hasPrefix("~~~") { ограда.toggle(); continue }
                if ограда || начало.hasPrefix(">") || строка.hasPrefix("    ") { continue }
                if расширение == "md", строка.range(of: #"\[[^\]]*\]\([^)]*\)|^\s*\[[^\]]+\]:"#, options: .regularExpression) != nil {
                    итог.append(СсылкаПути(файл: файл, строка: номер + 1, вид: "Markdown", состояние: "кандидат"))
                } else if (код || конфигурация), строка.range(of: #"["'][^"']*(?:/|[\p{L}\p{N}_-]+\.[\p{L}]{1,12})[^"']*["']"#, options: .regularExpression) != nil {
                    итог.append(СсылкаПути(файл: файл, строка: номер + 1, вид: код ? "код" : "конфигурация", состояние: "не проверено — нужен синтаксический адаптер"))
                }
            }
        }
        return итог
    }
}

struct ПолитикаГраницПутей: Decodable, Sendable {
    struct Структура: Decodable, Sendable {
        var имена_каталогов: [String]
        var окончания_каталогов: [String]
        var пути: [String]
    }
    var схема: String
    var исключённые_префиксы: [String]
    var структурные_исключения: Структура

    static func принятая(код: URL? = nil) throws -> ПолитикаГраницПутей {
        let корень = код ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let путь = корень.appendingPathComponent("Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json")
        guard путь.resolvingSymlinksInPath().path == путь.path else { throw ОшибкаПутей.отказ("Ссылка в пути принятой политики") }
        let данные = try Data(contentsOf: путь)
        guard хэшПутей(данные) == "5a52f1134876854e29db243cbfc6eebc86cc916a4d354ba73a0fc7516109bcd4" else {
            throw ОшибкаПутей.отказ("Изменена выбранная политика границ")
        }
        let итог = try JSONDecoder().decode(ПолитикаГраницПутей.self, from: данные)
        guard итог.схема == "fum.политика-братиславской-проекции.2" else { throw ОшибкаПутей.отказ("Неизвестная политика") }
        return итог
    }

    func граница(_ путь: String, каталог: Bool) -> Bool {
        if (исключённые_префиксы + структурные_исключения.пути).contains(where: { ИменаПутей.вложен(путь, в: $0) }) { return true }
        let имя = путь.split(separator: "/").last.map(String.init) ?? ""
        return каталог && (структурные_исключения.имена_каталогов.contains(имя)
            || структурные_исключения.окончания_каталогов.contains(where: { имя.hasSuffix($0) }))
    }
}
