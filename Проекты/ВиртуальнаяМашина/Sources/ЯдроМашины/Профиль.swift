import Foundation
import CryptoKit

public struct ОшибкаМашины: Error, CustomStringConvertible {
    public let description: String
    public init(_ сообщение: String) { description = сообщение }
}

public func кодировать<T: Encodable>(_ значение: T) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
    var байты = try кодировщик.encode(значение)
    байты.append(10)
    return байты
}

public func хэш(_ байты: Data) -> String {
    SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
}

public struct Профиль: Codable, Equatable {
    public var схема = "fum.профиль-машины.1"
    public var адаптер = "ubuntu-noble-arm64-vz"
    public var процессоры = 4
    public var памятьГиБ = 8
    public var дискГиБ = 32
    public var коммит = "4dd5a7f33913b17f705e512be1826314da89a4c4"
    public init() {}
    public func проверить() throws {
        guard схема == "fum.профиль-машины.1", адаптер == "ubuntu-noble-arm64-vz" else {
            throw ОшибкаМашины("Неизвестные схема профиля или адаптер.")
        }
        guard (2...16).contains(процессоры), (4...32).contains(памятьГиБ), (16...256).contains(дискГиБ) else {
            throw ОшибкаМашины("Профиль требует 2–16 CPU, 4–32 GiB RAM и 16–256 GiB диска.")
        }
        guard коммит.utf8.count == 40, коммит.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
            throw ОшибкаМашины("Нужен полный опубликованный OID коммита FUM, а не ветка.")
        }
    }
    public var отпечаток: String { get throws { хэш(try кодировать(self)) } }
}
