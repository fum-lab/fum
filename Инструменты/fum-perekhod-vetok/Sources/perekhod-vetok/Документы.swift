import Foundation
import CryptoKit

public enum ОшибкаПерехода: Error, CustomStringConvertible, Sendable {
    case отказ(String)
    public var description: String { switch self { case .отказ(let текст): текст } }
}
func требовать(_ условие: @autoclosure () throws -> Bool, _ текст: String) throws {
    if try !условие() { throw ОшибкаПерехода.отказ(текст) }
}
func хэш(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
func кодировать<Значение: Encodable>(_ значение: Значение) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(значение)
}
func декодировать<Значение: Decodable>(_ тип: Значение.Type, _ данные: Data) throws -> Значение {
    try JSONDecoder().decode(тип, from: данные)
}

public struct Ресурс: Codable, Equatable, Sendable {
    public let путь: String
    public let хэш: String
}
public struct ВыбранныйКорень: Codable, Equatable, Sendable {
    public let схема: String
    public let координатор: String
    public let ветка: String
    public let коммит: String
    public let основание: Ресурс
}
public struct Репозиторий: Codable, Equatable, Sendable {
    public let номерХостинга: Int64
    public let полноеИмя: String
    public let адресСервера: String
    public let общийКаталогГит: String
}
public struct ЗаданиеПерехода: Codable, Equatable, Sendable {
    public let схема: String
    public let операция: String
    public let репозиторий: Репозиторий
    public let владелец: String
    public let чат: String
    public let исходникДиалога: String
    public let рабочееДерево: String
    public let прежняяВетка: String
    public let ожидаемыйКоммит: String
    public let названияНаправления: [String]
    public let исполняемыйГит: Ресурс
    public let преобразователь: Ресурс
    public let ресурсы: [Ресурс]
    public let каталогПротокола: String
    public let каталогСырья: String
}
public struct План: Codable, Equatable, Sendable {
    public let схема: String
    public let задание: ЗаданиеПерехода
    public let выборКорня: ВыбранныйКорень
    public let хэшВыбораКорня: String
    public let новаяВетка: String
    public let названиеЧата: String
    public let прежнийУдалённыйОбъект: String?
    public let идентичностьОбщегоКаталога: String
    public let хэшНативногоНачала: String
    public func байты() throws -> Data { try кодировать(self) }
    public func отпечаток() throws -> String { try хэш(байты()) }
}
public struct СохранённыйИсход: Codable, Equatable, Sendable {
    let схема: String
    let фаза: String
    let хэшПлана: String
    let код: Int32
    let объект: String
    let пояснение: String
}
public struct ВнешнееДействие: Codable, Equatable, Sendable {
    public let схема: String
    public let операция: String
    public let хэшПлана: String
    public let владелец: String
    public let чат: String
    public let вид: String
    public let ожидаемаяВетка: String
    public let ожидаемыйКоммит: String
    public let новоеНазвание: String?
    public let пояснение: String
}
public struct РезультатПерехода: Codable, Equatable, Sendable {
    public let схема: String
    public let фаза: String
    public let коммит: String
    public let кореньВключён: Bool
    public let слияниеПодготовлено: Bool
    public let конфликты: [String]
    public let действиеКоординатора: ВнешнееДействие?
    public let атомарностьЧатаИГит: Bool
}

public enum ИменаПерехода {
    public static func ключКоллизии(_ имя: String) -> String {
        имя.precomposedStringWithCanonicalMapping.folding(
            options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
    public static func компонент(_ имя: String) throws -> String {
        try требовать(Array(имя.utf8) == Array(имя.precomposedStringWithCanonicalMapping.utf8),
                       "имя должно быть NFC")
        let нормальное = имя.folding(options: [.caseInsensitive],
                                    locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: " ", with: "-")
        try требовать(!нормальное.isEmpty && нормальное.utf8.allSatisfy {
            ($0 >= 97 && $0 <= 122) || ($0 >= 48 && $0 <= 57) || $0 == 45
        }, "имя не представимо разрешённым ASCII")
        try требовать(!нормальное.hasPrefix("-") && !нормальное.hasSuffix("-")
                       && !нормальное.contains("--"), "неверный разделитель имени")
        return нормальное
    }
    public static func проверитьВетку(_ ветка: String) throws {
        try требовать(ветка.hasPrefix("refs/heads/"), "нужен полный ref ветки")
        let части = ветка.dropFirst("refs/heads/".count).split(separator: "/", omittingEmptySubsequences: false)
        try требовать(!части.isEmpty, "пустая ветка")
        for часть in части {
            let строка = String(часть)
            try требовать(try компонент(строка) == строка, "новый ref должен быть ASCII lowercase")
        }
    }
    public static func проверитьКоллизии(_ новая: String, существующие: [String],
                                         исключая: Set<String> = []) throws {
        let ключ = ключКоллизии(новая)
        for имя in существующие where !исключая.contains(имя) {
            let другой = ключКоллизии(имя)
            try требовать(ключ != другой && !ключ.hasPrefix(другой + "/")
                           && !другой.hasPrefix(ключ + "/"), "коллизия регистра/NFC или D/F: " + имя)
        }
    }
}
