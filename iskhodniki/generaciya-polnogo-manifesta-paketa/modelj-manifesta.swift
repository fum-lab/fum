import Foundation
import CryptoKit

struct ОшибкаМанифеста: Error, CustomStringConvertible, Sendable {
    var код: String
    var description: String { код }
}

func требоватьМанифест(_ условие: Bool, _ код: String) throws {
    guard условие else { throw ОшибкаМанифеста(код: код) }
}

func хэшМанифеста(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

enum ВидЦелиПакета: String, Codable, Sendable { case обычная, исполняемая, проверочная }
enum ВидПродуктаПакета: String, Codable, Sendable { case исполняемый, библиотека, статическая, динамическая }
enum ПлатформаПакета: String, Codable, Sendable {
    case макОС = "macOS", айОС = "iOS", тиВиОС = "tvOS", часыОС = "watchOS", вижнОС = "visionOS", макКатализатор = "macCatalyst"
}
struct УсловиеПлатформы: Codable, Equatable, Sendable {
    var платформа: ПлатформаПакета
    var версия: String
}
struct ПродуктПакета: Codable, Equatable, Sendable {
    var имя: String
    var вид: ВидПродуктаПакета
    var цели: [String]
}
struct ЛокальныйПакет: Codable, Equatable, Sendable {
    var имя: String
    var путь: String
    // Объявленный интерфейс, а не исполнение внешнего Package.swift.
    var продукты: [String]
}
struct ЗависимостьЦелиПакета: Codable, Equatable, Sendable {
    var цель: String? = nil
    var продукт: String? = nil
    var пакет: String? = nil
}
enum ВидРесурсаПакета: String, Codable, Sendable { case обработать, копировать }
struct РесурсПакета: Codable, Equatable, Sendable {
    var вид: ВидРесурсаПакета
    var путь: String
}
struct ЦельПакета: Codable, Equatable, Sendable {
    var имя: String
    var вид: ВидЦелиПакета
    var путь: String
    var зависимости: [ЗависимостьЦелиПакета] = []
    var исключения: [String] = []
    var исходники: [String]? = nil
    var ресурсы: [РесурсПакета] = []
    var определения: [String] = []
}
struct ОписаниеПакета: Codable, Equatable, Sendable {
    var схема = "fum.описание-пакета.1"
    var имя: String
    var платформы: [УсловиеПлатформы]
    var продукты: [ПродуктПакета]
    var зависимости: [ЛокальныйПакет] = []
    var цели: [ЦельПакета]

    func байты() throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try кодировщик.encode(self) + Data([10])
    }

    static func прочитать(_ данные: Data) throws -> ОписаниеПакета {
        try СтрогоеОписаниеМанифеста.проверить(данные)
        // Закрытая форма: неизвестные поля не превращаются в Swift-выражения.
        func поля(_ объект: Any, _ допустимые: Set<String>) throws -> [String: Any] {
            guard let словарь = объект as? [String: Any] else { throw ОшибкаМанифеста(код: "не-объект") }
            try требоватьМанифест(Set(словарь.keys).isSubset(of: допустимые), "неизвестное-поле")
            return словарь
        }
        let верх = try поля(JSONSerialization.jsonObject(with: данные), ["схема", "имя", "платформы", "продукты", "зависимости", "цели"])
        for объект in верх["платформы"] as? [Any] ?? [] { _ = try поля(объект, ["платформа", "версия"]) }
        for объект in верх["продукты"] as? [Any] ?? [] { _ = try поля(объект, ["имя", "вид", "цели"]) }
        for объект in верх["зависимости"] as? [Any] ?? [] { _ = try поля(объект, ["имя", "путь", "продукты"]) }
        for объект in верх["цели"] as? [Any] ?? [] {
            let цель = try поля(объект, ["имя", "вид", "путь", "зависимости", "исключения", "исходники", "ресурсы", "определения"])
            for зависимость in цель["зависимости"] as? [Any] ?? [] { _ = try поля(зависимость, ["цель", "продукт", "пакет"]) }
            for ресурс in цель["ресурсы"] as? [Any] ?? [] { _ = try поля(ресурс, ["вид", "путь"]) }
        }
        let результат = try JSONDecoder().decode(Self.self, from: данные)
        try требоватьМанифест(результат.схема == "fum.описание-пакета.1", "неизвестная-схема")
        return результат
    }
}

enum СтрогоеОписаниеМанифеста {
    // До Dictionary: различает повторные и escaped-написания ключей каждого объекта.
    private struct Читатель {
        var байты: [UInt8]
        var позиция = 0
        mutating func пробелы() { while позиция < байты.count && [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 } }
        mutating func символ(_ ожидаемый: UInt8) throws {
            пробелы()
            try требоватьМанифест(позиция < байты.count && байты[позиция] == ожидаемый, "неверная-структура-json")
            позиция += 1
        }
        mutating func строка() throws -> String {
            пробелы(); let начало = позиция; try символ(34)
            while позиция < байты.count {
                if байты[позиция] == 92 { позиция += 2; continue }
                if байты[позиция] == 34 {
                    позиция += 1
                    return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция]))
                }
                позиция += 1
            }
            throw ОшибкаМанифеста(код: "незакрытая-json-строка")
        }
        mutating func значение(_ глубина: Int) throws {
            пробелы()
            try требоватьМанифест(глубина <= 128 && позиция < байты.count, "предел-json")
            let первый = байты[позиция]
            if первый == 34 { _ = try строка(); return }
            if первый == 123 || первый == 91 {
                позиция += 1; пробелы()
                let конец: UInt8 = первый == 123 ? 125 : 93
                var ключи = Set<String>()
                if позиция < байты.count && байты[позиция] == конец { позиция += 1; return }
                while true {
                    if первый == 123 {
                        let ключ = try строка()
                        try требоватьМанифест(ключи.insert(ключ).inserted, "повтор-json-ключа")
                        try символ(58)
                    }
                    try значение(глубина + 1); пробелы()
                    try требоватьМанифест(позиция < байты.count, "незакрытый-json")
                    if байты[позиция] == конец { позиция += 1; return }
                    try символ(44)
                }
            }
            let начало = позиция
            while позиция < байты.count && ![9, 10, 13, 32, 44, 93, 125].contains(байты[позиция]) { позиция += 1 }
            try требоватьМанифест(позиция > начало, "пустое-json-значение")
        }
    }
    static func проверить(_ данные: Data) throws {
        try требоватьМанифест(данные.count <= 4 * 1024 * 1024, "предел-json")
        var чтение = Читатель(байты: Array(данные))
        try чтение.значение(0); чтение.пробелы()
        try требоватьМанифест(чтение.позиция == чтение.байты.count, "хвост-json")
        _ = try JSONSerialization.jsonObject(with: данные, options: [.fragmentsAllowed])
    }
}

struct РезультатМанифеста: Sendable {
    var байты: Data
    var описание: ОписаниеПакета
    var хэшПрежнегоМанифеста: String
    var хэшНовогоМанифеста: String
    var хэшИспользованнойКарты: String?
    var текстРазницы: String
}
