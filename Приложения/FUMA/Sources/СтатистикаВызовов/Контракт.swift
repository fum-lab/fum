import Foundation

public let контрактСтатистики = "fum.codex-jsonl-вызовы.1"
public enum ОшибкаСтатистики: Error, Equatable {
    case идентичность, формат, предел, изменённыйПрефикс, конфликтВызова
    case повреждение, закрыто, неопределённаяЗапись, небезопасныйПуть, система(Int32)
}
public enum БюджетСтатистики {
    public static let блок = 65_536
    public static let строка = 4_194_304
    public static let вход = 268_435_456
    public static let строки = 100_000
    public static let события = 8192
    public static let пакеты = 256
    public static let пакет = 8_388_608
    public static let глубина = 16
    public static let ключи = 8192
}
public struct ГраницаПрефикса: Codable, Equatable, Sendable {
    public let байт: Int
    public let строк: Int
    public let sha256: String
}
public struct ПроисхождениеСтроки: Codable, Equatable, Sendable {
    public let строка: Int
    public let начало: Int
    public let конец: Int
    public let sha256: String
    public let контракт: String
}
public enum НаправлениеСобытия: String, Codable, Sendable { case вызов, результат }
public enum СемействоСобытия: String, Codable, Sendable { case функция = "function", произвольный = "custom" }
public enum КачествоВремени: String, Codable, Sendable { case известно, отсутствует, неверно }
public struct НаблюдённыйМомент: Codable, Equatable, Sendable {
    public let качество: КачествоВремени
    public let наносекундыОтЭпохи: Int64?
}
public struct СобытиеВызова: Codable, Equatable, Sendable {
    public let направление: НаправлениеСобытия
    public let семейство: СемействоСобытия
    public let идентификатор: String?
    public let инструмент: String?
    public let момент: НаблюдённыйМомент
    public let происхождение: ПроисхождениеСтроки
}
public struct ПрочитанныйПрефикс: Sendable {
    public let граница: ГраницаПрефикса?
    public let события: [СобытиеВызова]
    public let хвостБайт: Int
    public let прочитаноБайт: Int
}
public enum СвязьРезультата: String, Codable, Sendable {
    case сопряжён, отсутствует, несовместимоеСемейство
}
public struct СостояниеВызова: Codable, Equatable, Sendable {
    public let вызов: СобытиеВызова
    public let результат: СобытиеВызова?
    public let связь: СвязьРезультата
    public let задержкаНаносекунды: Int64?
}
public struct ИтогИнструмента: Codable, Equatable, Sendable {
    public let инструмент: String?
    public let прямыхВызовов: Int
    public let вызововБезИдентичности: Int
    public let сопряжённыхРезультатов: Int
    public let безРезультата: Int
    public let неоднозначныхСвязей: Int
    public let неизвестныхЗадержек: Int
    public let задержкиНаносекунды: [Int64]
}
public struct ОтчётСтатистики: Codable, Equatable, Sendable {
    public let контракт: String
    public let задача: String
    public let граница: ГраницаПрефикса?
    public let прямыхВызовов: Int
    public let сопряжённыхРезультатов: Int
    public let несопряжённыхРезультатов: Int
    public let дубликатов: Int
    public let наблюдения: [СобытиеВызова]
    public let вызовы: [СостояниеВызова]
    public let вызовыБезИдентичности: [СобытиеВызова]
    public let результатыБезПары: [СобытиеВызова]
    public let инструменты: [ИтогИнструмента]
}
public func кодироватьСтатистику<Значение: Encodable>(_ значение: Значение) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(значение)
}
