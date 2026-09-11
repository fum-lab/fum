import Foundation

public struct ОписаниеНаблюдения: Codable, Equatable, Sendable {
    public let идентификатор: String
    public let тип: String
    public let версияСхемы: Int
    public let источник: String
    public let время: String
    public let спецификация: Data

    public init(идентификатор: String, тип: String, версияСхемы: Int = 1,
                источник: String = "синтетический", время: String = "2026-01-01T00:00:00Z",
                спецификация: Data = Data("произвольные исходные байты".utf8)) {
        self.идентификатор = идентификатор
        self.тип = тип
        self.версияСхемы = версияСхемы
        self.источник = источник
        self.время = время
        self.спецификация = спецификация
    }
}

public struct Квитанция: Codable, Equatable, Sendable {
    public let описание: ОписаниеНаблюдения
    public let размер: UInt64
    public let хэш: String
}

public enum ОшибкаКонтейнера: Error, Equatable {
    case система(Int32)
    case повреждение
    case предел
    case неполныйХвост
    case конфликтИдентификатора
    case нетЗаписи
    case закрыт
    case толькоЧтение
    case занят
    case небезопасныйПуть
}

public struct ФайловыеОперации: Sendable {
    public var запись: @Sendable (Int32, UnsafeRawBufferPointer) throws -> Int
    public var синхронизация: @Sendable (Int32) throws -> Void
    public init(запись: @escaping @Sendable (Int32, UnsafeRawBufferPointer) throws -> Int,
                синхронизация: @escaping @Sendable (Int32) throws -> Void) {
        self.запись = запись
        self.синхронизация = синхронизация
    }
}

public struct МеткаПрофиля: Codable, Sendable {
    public let этап: String
    public let наносекунды: UInt64
    public let исход: String
    public let глубина: Int
}

public enum Пределы {
    public static let заголовок = 131_072
    public static let фрагмент = 1_048_576
    public static let объект: UInt64 = 67_108_864
    public static let сегмент = 268_435_456
    public static let записи = 4096
    public static let фрагменты = 16_384
}
