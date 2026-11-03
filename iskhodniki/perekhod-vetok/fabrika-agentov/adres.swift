import Foundation
import CryptoKit

public struct АдресУзла: Codable, Equatable, Sendable {
    public var репозиторий: String
    public var ветка: String
    public var путьПамяти: String

    func канонический() -> АдресУзла {
        АдресУзла(репозиторий: репозиторий.precomposedStringWithCanonicalMapping,
            ветка: ветка.precomposedStringWithCanonicalMapping, путьПамяти: путьПамяти.precomposedStringWithCanonicalMapping)
    }

    public func ключВладения() throws -> String {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return SHA256.hash(data: try кодировщик.encode(канонический())).map { String(format: "%02x", $0) }.joined()
    }
}

/// Независимое назначение среды; этот тип сам не доказывает его происхождение или уникальность.
public struct НазначениеПространства: Codable, Equatable, Sendable {
    public let адрес: АдресУзла
    public let хост: String
    public let физическийКорень: String
    public let устройство: UInt64
    public let inode: UInt64
}

public struct ЭкземплярУзла: Codable, Equatable, Sendable {
    public var хост: String
    public var воплощение: String
    public var задача: String
    public var родитель: String
    public var модель: String
    public var усилие: String
    public var рабочееДерево: String
    public var идентификаторПамяти: String?
    public var кореньПамяти: String?

    func канонический() -> ЭкземплярУзла {
        ЭкземплярУзла(хост: хост.precomposedStringWithCanonicalMapping,
            воплощение: воплощение.precomposedStringWithCanonicalMapping,
            задача: задача.precomposedStringWithCanonicalMapping,
            родитель: родитель.precomposedStringWithCanonicalMapping,
            модель: модель.precomposedStringWithCanonicalMapping,
            усилие: усилие.precomposedStringWithCanonicalMapping,
            рабочееДерево: рабочееДерево.precomposedStringWithCanonicalMapping,
            идентификаторПамяти: идентификаторПамяти?.precomposedStringWithCanonicalMapping,
            кореньПамяти: кореньПамяти?.precomposedStringWithCanonicalMapping)
    }
}

public enum ВидДействияФабрики: String, Codable, CaseIterable, Sendable {
    case запуск, возобновление, созданиеРебёнка
}
