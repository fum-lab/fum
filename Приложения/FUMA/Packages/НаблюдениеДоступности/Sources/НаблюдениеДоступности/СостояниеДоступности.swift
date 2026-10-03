import Foundation

public enum ОснованиеОтвета: String, Codable, Sendable {
    case новаяФиксация
    case историческоеЧтение
}

public enum СостояниеДоступности: Equatable, Sendable {
    case ответ(ОтветДоступности, основание: ОснованиеОтвета)
    case неизвестно(НамерениеДоступности)
    case отсутствует
}

public struct МеткаДоступности: Codable, Sendable {
    public let этап: String
    public let наносекунды: UInt64
    public let исход: String
    public let глубина: Int
}
