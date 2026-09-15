import Foundation
import CryptoKit
import СнимокАгентскойЗадачи
import КонтейнерНаблюдений

public enum ОшибкаАрхива: Error, Equatable {
    case неверныйUUID, чужаяСессия, повторнаяИдентичность, формат, предел
    case подменаПрефикса, источникИзменился, небезопасныйИсточник
    case повреждениеАрхива, неполныйКонтейнер, закрыт, неопределённаяЗапись
    case система(Int32)
}

public struct БюджетАрхива: Sendable {
    public var байты = 256 * 1024 * 1024
    public var строка = 8 * 1024 * 1024
    public var строки = 1_000_000
    public var глубина = 32
    public var узлыСтроки = 65_536
    public var записи = 1024
    public init() {}
}

public struct ПозицияСтроки: Codable, Equatable, Sendable {
    public let номер: Int
    public let начало: Int
    public let конец: Int
    /// SHA-256 исходных байтов строки вместе с LF.
    public let sha256: String
}
public struct ГраницаПрефикса: Codable, Equatable, Sendable {
    public let байты: Int
    public let строки: Int
    public let sha256: String
}
public struct ФактСтроки: Codable, Equatable, Sendable {
    public let значение: String
    public let позиция: ПозицияСтроки
}
public struct ИдентичностьСессии: Codable, Equatable, Sendable {
    public let uuid: String
    public let позиция: ПозицияСтроки
}
public struct АрхивноеНаблюдение: Codable, Equatable, Sendable {
    public let версияАдаптера: Int
    public let ожидаемыйUUID: String
    public let sessionMeta: ИдентичностьСессии
    public let граница: ГраницаПрефикса
    public let предыдущийSHA: String?
    public let каталогRuntime: ФактСтроки?
    public let последнийХод: ФактСтроки?
    public let модельХода: ФактСтроки?
    public let наблюдения: [Наблюдение]
    public let shaСнимка: String
    public let охват: String
}
public struct РезультатАрхива: Codable, Equatable, Sendable {
    public let архив: АрхивноеНаблюдение
    public let снимок: Снимок
}
public struct ПрофильАрхива: Codable, Sendable {
    public var чтениеИХэширование: UInt64 = 0
    public var разбор: UInt64 = 0
    public var редукция: UInt64 = 0
    public var запись: UInt64 = 0
    public var fsync: UInt64 = 0
    public var replay: UInt64 = 0
    public var повтор: UInt64 = 0
    public var пикБуфераСтроки = 0
    public var разобраноСтрок = 0
}

func хэшАрхива(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
func проверитьUUID(_ строка: String) throws {
    guard let значение = UUID(uuidString: строка), значение.uuidString.lowercased() == строка else {
        throw ОшибкаАрхива.неверныйUUID
    }
}
