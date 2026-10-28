import Foundation
import FUMStructuringOperatorMemory

public struct ОтказМаршрутаПравил: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Категория: String, Sendable {
        case отсутствуетМаршрутизатор
        case отсутствуетИнвентарь
        case отсутствуетТема
        case неверныйРегистр
        case несовпадениеХэша
        case символическаяСсылка
        case выходЗаCheckout
        case неизвестныйТриггер
        case маркер
        case покрытие
        case инвентарь
        case фикстураМаршрутизации
        case исходныйСнимок
    }

    public let категория: Категория
    public let пояснение: String

    public init(_ категория: Категория, _ пояснение: String) {
        self.категория = категория
        self.пояснение = пояснение
    }

    public var description: String { "\(категория.rawValue): \(пояснение)" }
}

public enum ИсточникСнимкаПравил: Sendable {
    case git
    case данные(Data)
}

public struct РезультатМаршрутаПравил: Codable, Equatable, Sendable {
    public let схема: String
    public let пути: [String]

    init(пути: [String]) {
        схема = "fum.маршрут-правил-агентов.1"
        self.пути = пути
    }
}

struct ИнвентарьПравил: Decodable, Sendable {
    let схема: String
    let исходныйСнимок: ИсходныйСнимок
    let темы: [ТемаПравил]
    let служебныеПути: [String]
    let маршруты: [МаршрутПравил]
    let фикстуры: [ФикстураМаршрутизации]
    let исходныеЕдиницы: [ИсходнаяЕдиница]
    let правила: [ЗарегистрированноеПравило]

    enum CodingKeys: String, CodingKey {
        case схема
        case исходныйСнимок = "исходный_снимок"
        case темы
        case служебныеПути = "служебные_пути_изменения_правил"
        case маршруты
        case фикстуры = "фикстуры_маршрутизации"
        case исходныеЕдиницы = "исходные_единицы"
        case правила
    }
}

struct ИсходныйСнимок: Decodable, Sendable {
    let commit: String
    let blob: String
    let sha256: String
    let строк: Int
    let unicodeСимволов: Int
    let байтов: Int

    enum CodingKeys: String, CodingKey {
        case commit, blob, sha256, строк, байтов
        case unicodeСимволов = "unicode_символов"
    }
}

struct ТемаПравил: Decodable, Sendable {
    let идентификатор: String
    let путь: String
    let полномочия: Bool
    let sha256Содержания: String

    enum CodingKeys: String, CodingKey {
        case идентификатор, путь, полномочия
        case sha256Содержания = "sha256_содержания"
    }
}

struct МаршрутПравил: Codable, Equatable, Sendable {
    let идентификатор: String
    let пути: [String]
}

struct ФикстураМаршрутизации: Codable, Equatable, Sendable {
    let идентификатор: String
    let триггеры: [String]
    let ожидаемыеПути: [String]

    enum CodingKeys: String, CodingKey {
        case идентификатор, триггеры
        case ожидаемыеПути = "ожидаемые_пути"
    }
}

struct ИсходнаяЕдиница: Decodable, Sendable {
    let идентификатор: String
    let номерСтроки: Int
    let началоБайта: Int
    let конецБайта: Int
    let sha256: String
    let класс: String
    let требуетПравило: Bool?

    enum CodingKeys: String, CodingKey {
        case идентификатор, sha256, класс
        case номерСтроки = "номер_строки"
        case началоБайта = "начало_байта"
        case конецБайта = "конец_байта"
        case требуетПравило = "требует_правило"
    }
}

struct ЗарегистрированноеПравило: Decodable, Sendable {
    let идентификатор: String
    let статус: String
    let приоритет: String
    let области: [String]
    let триггеры: [String]
    let семантическийКлюч: String
    let назначение: НазначениеПравила
    let источники: [String]
    let новоеОснование: String?

    enum CodingKeys: String, CodingKey {
        case идентификатор, статус, приоритет, области, триггеры, назначение, источники
        case семантическийКлюч = "семантический_ключ"
        case новоеОснование = "новое_основание"
    }
}

struct НазначениеПравила: Decodable, Sendable {
    let путь: String
    let якорь: String
}

struct ПроекцияМаршрутизации: Codable, Equatable, Sendable {
    let схема: String
    let маршруты: [МаршрутПравил]
    let фикстуры: [ФикстураМаршрутизации]
}

func хэшSHA256(_ данные: Data) -> String {
    sha256Digest(данные)
}

func корректныйSHA256(_ значение: String) -> Bool {
    let байты = Array(значение.utf8)
    guard байты.count == 71, байты.starts(with: Array("sha256:".utf8)) else { return false }
    return байты.dropFirst(7).allSatisfy {
        (48...57).contains($0) || (97...102).contains($0)
    }
}

func полныйGitOID(_ значение: String) -> Bool {
    let байты = Array(значение.utf8)
    return байты.count == 40 && байты.allSatisfy {
        (48...57).contains($0) || (97...102).contains($0)
    }
}
