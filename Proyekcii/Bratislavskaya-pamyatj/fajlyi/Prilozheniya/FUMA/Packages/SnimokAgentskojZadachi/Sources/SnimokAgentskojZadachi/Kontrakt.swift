import Foundation

public enum ОшибкаСнимка: Error, Equatable {
    case версия, предел, неверныйВвод, чужаяЗадача, конфликтИдентификатора
    case неверныйПереход, неподтверждаемыйЭффект, закрыт, неполныйКонтейнер
}

public struct Задача: Codable, Equatable, Hashable, Sendable {
    public let поставщик: String
    public let хост: String
    public let идентификатор: String
    public init(поставщик: String, хост: String, идентификатор: String) {
        self.поставщик = поставщик
        self.хост = хост
        self.идентификатор = идентификатор
    }
    /// Явный ключ сравнения задачи. Исходная задача внутри наблюдения не меняется.
    public var нормализованнаяИдентичность: Задача {
        Задача(поставщик: поставщик.precomposedStringWithCanonicalMapping,
               хост: хост.precomposedStringWithCanonicalMapping,
               идентификатор: идентификатор.precomposedStringWithCanonicalMapping)
    }
}

public enum Канал: String, Codable, Sendable {
    case api, журнал, интерфейс, команда, настройка
}
public enum Охват: String, Codable, Sendable {
    case полный, частичный, точечный
}
public struct Источник: Codable, Equatable, Hashable, Sendable {
    public let канал: Канал
    public let экземпляр: String
    public init(_ канал: Канал, _ экземпляр: String = "синтетический") {
        self.канал = канал
        self.экземпляр = экземпляр
    }
}
public enum Поле: String, Codable, CaseIterable, Sendable {
    case существует, желаемаяМодель, наблюдённаяМодель
    case каталогRuntime, каталогКоманды, назначенныйWorktree, ветка
    case текущаяРабота, ожидание
}
public enum ФазаКоманды: String, Codable, Sendable {
    case намерение, отправлена, принята
}
public enum Факт: Codable, Equatable, Sendable {
    case значение(поле: Поле, контекст: String, текст: String)
    case список(задачи: [Задача])
    case отказ(причина: String)
    case расхождение(ожидалось: String, наблюдалось: String)
    case команда(операция: String, фаза: ФазаКоманды, эффект: String, корректирует: String?)
    case эффект(операция: String, текст: String)
    case время
}
public struct Наблюдение: Codable, Equatable, Sendable {
    public let версия: Int
    public let идентификатор: String
    public let задача: Задача
    public let источник: Источник
    public let такт: Int64
    public let годноДо: Int64
    public let охват: Охват
    public let область: String
    public let исходныйФакт: String
    public let заменяет: [String]
    public let факт: Факт
    public init(версия: Int = 1, идентификатор: String, задача: Задача,
                источник: Источник, такт: Int64, годноДо: Int64 = 100,
                охват: Охват = .точечный, область: String = "синтетическая-задача",
                исходныйФакт: String = "Синтетическая запись сценария",
                заменяет: [String] = [], факт: Факт) {
        self.версия = версия
        self.идентификатор = идентификатор
        self.задача = задача
        self.источник = источник
        self.такт = такт
        self.годноДо = годноДо
        self.охват = охват
        self.область = область
        self.исходныйФакт = исходныйФакт
        self.заменяет = заменяет
        self.факт = факт
    }
}
public enum Знание: String, Codable, Sendable {
    case неизвестно, согласовано, противоречие
}
public struct Кандидат: Codable, Equatable, Sendable {
    public let значение: String
    public let свидетельство: String
    public let устарело: Bool
}
public struct ЗначениеПоля: Codable, Equatable, Sendable {
    public let поле: Поле
    public let контекст: String
    public let знание: Знание
    public let кандидаты: [Кандидат]
}
public struct НедоступныйКанал: Codable, Equatable, Sendable {
    public let источник: Источник
    public let причина: String
    public let свидетельство: String
}
public struct Операция: Codable, Equatable, Sendable {
    public let идентификатор: String
    public var фаза: ФазаКоманды
    public let ожидаемыйЭффект: String
    public let корректирует: String?
    public var свидетельстваКоманды: [String]
    public var подтверждение: String?
}
public struct Снимок: Codable, Equatable, Sendable {
    public let версия: Int
    public let задача: Задача
    public let такт: Int64
    public let поля: [ЗначениеПоля]
    public let неизвестныеПоля: [Поле]
    public let недоступныеКаналы: [НедоступныйКанал]
    public let разрывыОхвата: [String]
    public let проигнорированы: [String]
    public let операции: [Операция]
    public let последняяПодтверждённаяКорректировка: String?
    public let наблюдения: [Наблюдение]
    public func значение(_ поле: Поле, _ контекст: String = "") -> ЗначениеПоля {
        поля.first { $0.поле == поле && $0.контекст == контекст }
            ?? ЗначениеПоля(поле: поле, контекст: контекст, знание: .неизвестно, кандидаты: [])
    }
}
public struct Сценарий: Codable, Equatable, Sendable {
    public let версия: Int
    public let задача: Задача
    public let наблюдения: [Наблюдение]
    public init(версия: Int = 1, задача: Задача, наблюдения: [Наблюдение]) {
        self.версия = версия
        self.задача = задача
        self.наблюдения = наблюдения
    }
}
public func каноническийJSON<Значение: Encodable>(_ значение: Значение) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    // Строки payload не нормализуются: NFC/NFD — разные исходные UTF-8-байты.
    return try кодировщик.encode(значение)
}
