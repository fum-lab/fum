import Foundation
import CryptoKit

public struct Вложение: Codable, Equatable, Sendable {
    public let имя: String
    public let данные: Data
    public init(имя: String, данные: Data) { self.имя = имя; self.данные = данные }
    public var хэш: String { отпечаток(данные) }
}

public enum ДействиеКанала: Codable, Equatable, Sendable {
    case текст(String), документ(Вложение, String?), альбом([Вложение], String?)
    case изменитьТекст(Int64, String), изменитьПодпись(Int64, String?), изменитьМедиа(Int64, Вложение, String?)
    case неподдерживаемое(String)
    public var сообщение: Int64? {
        switch self {
        case .изменитьТекст(let номер, _), .изменитьПодпись(let номер, _), .изменитьМедиа(let номер, _, _): номер
        default: nil
        }
    }
    public var вложения: [Вложение] {
        switch self {
        case .документ(let файл, _), .изменитьМедиа(_, let файл, _): [файл]
        case .альбом(let файлы, _): файлы
        default: []
        }
    }
}

public struct Черновик: Codable, Equatable, Sendable {
    public let идентификатор: UUID
    public let аккаунт: Int64
    public let канал: Int64
    public let действие: ДействиеКанала
    public let цель: String
    public var тема: ЗначениеДанных?
    public init(идентификатор: UUID = UUID(), аккаунт: Int64, канал: Int64, действие: ДействиеКанала,
                цель: String, тема: ЗначениеДанных? = nil) {
        self.идентификатор = идентификатор; self.аккаунт = аккаунт; self.канал = канал
        self.действие = действие; self.цель = цель; self.тема = тема
    }
    public func отпечатокСодержимого() throws -> String { try отпечаток(кодироватьЛокально(self)) }
}

/// Конкретное разрешение связано с неизменяемыми байтами черновика, аккаунтом и адресатом.
public struct РазрешениеДействия: Codable, Equatable, Sendable {
    public let черновик: UUID
    public let отпечатокЧерновика: String
    public let основание: String
    public init(черновик: Черновик, основание: String) throws {
        guard !основание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              основание.utf8.count <= 4096 else { throw ОшибкаКлиента.доступЗапрещён("Нужно точное основание разрешения") }
        self.черновик = черновик.идентификатор
        self.отпечатокЧерновика = try черновик.отпечатокСодержимого()
        self.основание = основание
    }
    func проверить(_ значение: Черновик) throws {
        guard !основание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, основание.utf8.count <= 4096,
              черновик == значение.идентификатор, try отпечатокЧерновика == значение.отпечатокСодержимого() else {
            throw ОшибкаКлиента.доступЗапрещён("Разрешение относится к другому содержимому")
        }
    }
}

/// Снимок актуального допуска создаёт только ядро по ответам этого client_id.
struct ДопускКанала: Sendable {
    var аккаунт: Int64
    var канал: Int64
    var готов: Bool
    var подтверждёнАккаунт: Bool
    var каналПодтверждён: Bool
    var можетПисать: Bool
    var цельПравки: Int64?
    var можетПравить: Bool
    var можетЗаменятьМедиа: Bool
    var типМедиа: String?
}

func отпечаток(_ данные: Data) -> String { SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined() }
func кодироватьЛокально<Тип: Encodable>(_ значение: Тип) throws -> Data {
    let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(значение)
}

enum Сериализатор {
    static func проверитьСодержимое(_ черновик: Черновик) throws {
        try проверитьИдентификатор(черновик.аккаунт, положительный: true)
        try проверитьИдентификатор(черновик.канал)
        guard черновик.канал < 0, !черновик.цель.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              черновик.цель.utf8.count <= 4096 else { throw ОшибкаКлиента.неверныеДанные("Канал и цель действия") }
        guard черновик.тема == nil || черновик.тема == .пусто else { throw ОшибкаКлиента.неподдерживаемоеДействие }
        if let номер = черновик.действие.сообщение { try проверитьИдентификатор(номер, положительный: true) }
        func проверитьТекст(_ текст: String?, подпись: Bool) throws {
            guard let текст else { return }
            guard !текст.contains("\0"), текст.utf16.count <= (подпись ? 1024 : 4096),
                  подпись || !текст.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ОшибкаКлиента.неверныеДанные("Пустой текст или превышен предел UTF-16")
            }
        }
        switch черновик.действие {
        case .текст(let текст), .изменитьТекст(_, let текст): try проверитьТекст(текст, подпись: false)
        case .документ(_, let подпись), .изменитьПодпись(_, let подпись), .изменитьМедиа(_, _, let подпись):
            try проверитьТекст(подпись, подпись: true)
        case .альбом(let файлы, let подпись):
            guard (2...10).contains(файлы.count) else { throw ОшибкаКлиента.неверныеДанные("Альбом требует 2–10 документов") }
            try проверитьТекст(подпись, подпись: true)
        case .неподдерживаемое: throw ОшибкаКлиента.неподдерживаемоеДействие
        }
        var всего = 0
        for файл in черновик.действие.вложения {
            guard !файл.имя.isEmpty, файл.имя != ".", файл.имя != "..", файл.имя.utf8.count <= 240,
                  !файл.имя.contains("/"), !файл.имя.contains("\\"), !файл.имя.contains("\0"),
                  !файл.данные.isEmpty, файл.данные.count <= 16 * 1024 * 1024 - всего else {
                throw ОшибкаКлиента.неверныеДанные("Имя, байты вложения или суммарный предел 16 МиБ")
            }
            всего += файл.данные.count
        }
    }

    static func подготовить(_ черновик: Черновик, допуск: ДопускКанала, каталог: String) throws -> ЗначениеДанных {
        try проверитьСодержимое(черновик)
        guard допуск.готов, допуск.подтверждёнАккаунт, допуск.каналПодтверждён,
              допуск.аккаунт == черновик.аккаунт, допуск.канал == черновик.канал else {
            throw ОшибкаКлиента.доступЗапрещён("Ready, точный аккаунт и подтверждённый канал")
        }
        guard каталог.hasPrefix("/"), каталог != "/" else { throw ОшибкаКлиента.неверныеДанные("Приватный каталог вложений") }
        if let сообщение = черновик.действие.сообщение {
            guard допуск.цельПравки == сообщение else { throw ОшибкаКлиента.доступЗапрещён("Нет свойств точного сообщения") }
            if case .изменитьМедиа = черновик.действие {
                guard допуск.можетЗаменятьМедиа, допуск.типМедиа == "messageDocument" else {
                    throw ОшибкаКлиента.доступЗапрещён("Замена документа требует can_edit_media и совместимого типа")
                }
            } else {
                guard допуск.можетПравить else { throw ОшибкаКлиента.доступЗапрещён("Нет can_be_edited") }
                if case .изменитьТекст = черновик.действие {
                    guard допуск.типМедиа == "messageText" else { throw ОшибкаКлиента.неподдерживаемоеДействие }
                } else {
                    guard допуск.типМедиа == "messageDocument" else { throw ОшибкаКлиента.неподдерживаемоеДействие }
                }
            }
        } else {
            guard допуск.можетПисать else { throw ОшибкаКлиента.доступЗапрещён("Нет can_post_messages") }
        }
        func формат(_ текст: String?) -> ЗначениеДанных {
            guard let текст else { return .пусто }
            return .типа("formattedText", ["text": .текст(текст), "entities": .массив([])])
        }
        func текст(_ значение: String) -> ЗначениеДанных {
            .типа("inputMessageText", ["text": формат(значение), "link_preview_options": .пусто, "clear_draft": .флаг(false)])
        }
        func документ(_ файл: Вложение, _ подпись: String?) -> ЗначениеДанных {
            .типа("inputMessageDocument", ["document": .типа("inputDocument", [
                "document": .типа("inputFileLocal", ["path": .текст(каталог + "/" + файл.хэш + "/" + файл.имя)]),
                "thumbnail": .пусто, "disable_content_type_detection": .флаг(true)]), "caption": формат(подпись)])
        }
        var поля: [String: ЗначениеДанных] = ["chat_id": .число(черновик.канал)]
        if let номер = черновик.действие.сообщение { поля["message_id"] = .число(номер) }
        else { поля["topic_id"] = .пусто; поля["reply_to"] = .пусто; поля["options"] = .пусто }
        поля["reply_markup"] = .пусто
        let тип: String
        switch черновик.действие {
        case .текст(let значение): тип = "sendMessage"; поля["input_message_content"] = текст(значение)
        case .документ(let файл, let подпись): тип = "sendMessage"; поля["input_message_content"] = документ(файл, подпись)
        case .альбом(let файлы, let подпись):
            тип = "sendMessageAlbum"; поля.removeValue(forKey: "reply_markup")
            поля["input_message_contents"] = .массив(файлы.map { документ($0, подпись) })
        case .изменитьТекст(_, let значение): тип = "editMessageText"; поля["input_message_content"] = текст(значение)
        case .изменитьПодпись(_, let подпись):
            тип = "editMessageCaption"; поля["caption"] = формат(подпись); поля["show_caption_above_media"] = .флаг(false)
        case .изменитьМедиа(_, let файл, let подпись): тип = "editMessageMedia"; поля["input_message_content"] = документ(файл, подпись)
        case .неподдерживаемое: throw ОшибкаКлиента.неподдерживаемоеДействие
        }
        return .типа(тип, поля)
    }
}
