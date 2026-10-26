import Foundation
import CryptoKit

enum ОтказЖурнала: String, Error, Codable, Sendable {
    case вход, публикация, путь, коллизия, дрейф, конфликт, занято, файловыйЭффект, неРеализовано
}

struct ЭкземплярЗаписи: Codable, Equatable, Sendable {
    var корень: String
    var писатель: String
    var стадия: String
    var номер: Int
}

struct ОригиналСообщения: Swift.Codable, Swift.Equatable, Swift.Sendable {
    var хэш: String
    var байтов: Int
    var источник: String
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case хэш = "sha256"
        case байтов = "байтов"
        case источник = "источник"
    }
}

struct СообщениеЗаписи: Codable, Equatable, Sendable {
    enum Роль: String, Codable, Sendable { case человек, агент }
    enum Вид: String, Codable, Sendable { case буквальное, производное }
    var роль: Роль
    var вид: Вид
    var текст: String
    var происхождение: String
    var оригинал: ОригиналСообщения?
}

struct ПроверкаЗаписи: Codable, Equatable, Sendable {
    enum Исход: String, Codable, Sendable { case успешно, неуспешно, прервано, неизвестно, неПроверено }
    var название: String
    var исход: Исход
    var код: Int?
    var наносекунды: Int64?
    var свидетельство: String
}

struct ДоставкаЗаписи: Codable, Equatable, Sendable {
    var вид: String
    var идентификатор: String
    var свидетельство: String
}

struct ВходЗаписи: Codable, Equatable, Sendable {
    var схема = "fum.вход-локальной-записи.1"
    var экземпляр: ЭкземплярЗаписи
    var время: String
    var область: String
    var публичная: Bool
    var происхождение: [String]
    var сообщения: [СообщениеЗаписи]
    var решения: [String]
    var проверки: [ПроверкаЗаписи]
    var исход: String
    var остаток: [String]
    var доставка: [ДоставкаЗаписи]

    func проверить() throws {
        guard схема == "fum.вход-локальной-записи.1", экземпляр.номер > 0,
              UUID(uuidString: экземпляр.корень)?.uuidString.lowercased() == экземпляр.корень,
              UUID(uuidString: экземпляр.писатель)?.uuidString.lowercased() == экземпляр.писатель,
              !экземпляр.стадия.isEmpty, экземпляр.стадия.utf8.count <= 128,
              !экземпляр.стадия.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              !происхождение.isEmpty, !исход.isEmpty else { throw ОтказЖурнала.вход }
        let формат = ISO8601DateFormatter()
        формат.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let полный = формат.date(from: время)
        формат.formatOptions = [.withInternetDateTime]
        guard полный != nil || формат.date(from: время) != nil else { throw ОтказЖурнала.вход }
        try ГраницаЦели.проверитьОбласть(область)
        for сообщение in сообщения {
            guard !сообщение.происхождение.isEmpty else { throw ОтказЖурнала.вход }
            if сообщение.вид == .производное {
                guard let оригинал = сообщение.оригинал, оригинал.байтов >= 0,
                      оригинал.хэш.count == 64,
                      оригинал.хэш.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
                      !оригинал.источник.isEmpty else { throw ОтказЖурнала.вход }
            } else if сообщение.оригинал != nil { throw ОтказЖурнала.вход }
        }
        for проверка in проверки {
            guard !проверка.название.isEmpty, !проверка.свидетельство.isEmpty,
                  проверка.наносекунды.map({ $0 >= 0 }) ?? true else { throw ОтказЖурнала.вход }
            switch проверка.исход {
            case .успешно: guard проверка.код == 0, проверка.наносекунды != nil else { throw ОтказЖурнала.вход }
            case .неуспешно: guard let код = проверка.код, код != 0, проверка.наносекунды != nil else { throw ОтказЖурнала.вход }
            case .неПроверено: guard проверка.код == nil, проверка.наносекунды == nil else { throw ОтказЖурнала.вход }
            case .прервано, .неизвестно: break
            }
        }
        guard публичная else { throw ОтказЖурнала.публикация }
        let значение = try JSONSerialization.jsonObject(with: JSONEncoder().encode(self))
        try ПубличноеПредставление.проверитьЗначения(значение)
    }
}

enum ПубличноеПредставление {
    // Конечная защита входа этого среза; policy и historical fence не являются входом допуска.
    static func проверить(_ данные: Data) throws {
        let текст = String(decoding: данные, as: UTF8.self)
        var проверяемый = текст.replacingOccurrences(of: "<область>/zhurnal", with: "〈шаблон〉")
        let веб = try NSRegularExpression(pattern: #"https?://[^\s<>\"\\]+"#)
        for совпадение in веб.matches(in: проверяемый, range: NSRange(проверяемый.startIndex..., in: проверяемый)).reversed() {
            guard let диапазон = Range(совпадение.range, in: проверяемый),
                  let адрес = URLComponents(string: String(проверяемый[диапазон])),
                  let сервер = адрес.host, !сервер.isEmpty else { continue }
            проверяемый.replaceSubrange(диапазон, with: "〈веб-источник〉")
        }
        let шаблонПути = #"(?<![\p{L}\p{N}._/\-])/[^\s<>\"\\]+"#
        let шаблонДиска = #"(?i:\b[a-z]:[\\/])"#
        let шаблонФайловогоАдреса = #"(?i:file://)"#
        let шаблонДомашнейФормы = #"(?i:~[/\\])"#
        let шаблонСетевогоПути = #"\\\\[^\\\s]+\\"#
        let выражение = try NSRegularExpression(pattern: [шаблонПути, шаблонДиска,
            шаблонФайловогоАдреса, шаблонДомашнейФормы, шаблонСетевогоПути].joined(separator: "|"))
        guard выражение.firstMatch(in: проверяемый, range: NSRange(проверяемый.startIndex..., in: проверяемый)) == nil
        else { throw ОтказЖурнала.публикация }
    }

    static func проверитьЗначения(_ значение: Any) throws {
        switch значение {
        case let строка as String: try проверить(Data(строка.utf8))
        case let массив as [Any]: for элемент in массив { try проверитьЗначения(элемент) }
        case let объект as [String: Any]:
            for (ключ, элемент) in объект { try проверить(Data(ключ.utf8)); try проверитьЗначения(элемент) }
        default: break
        }
    }

    static func представить(_ оригинал: Data, источник: String, точноеВхождение: String,
                           замена: String) throws -> СообщениеЗаписи {
        guard let текст = String(data: оригинал, encoding: .utf8), !точноеВхождение.isEmpty,
              текст.components(separatedBy: точноеВхождение).count == 2 else { throw ОтказЖурнала.вход }
        let производное = текст.replacingOccurrences(of: точноеВхождение, with: замена)
        try проверить(Data(производное.utf8))
        return СообщениеЗаписи(роль: .агент, вид: .производное, текст: производное,
            происхождение: "Точное производное представление; не дословная цитата",
            оригинал: ОригиналСообщения(хэш: хэш(оригинал), байтов: оригинал.count, источник: источник))
    }
}

func хэш(_ данные: Data) -> String { SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined() }
