import Foundation

public enum ИсходДоступности: String, Codable, Sendable {
    case доверен
    case недоверен
}

public struct ОтветДоступности: Codable, Equatable, Sendable {
    public let версияСхемы: Int
    public let намерение: НамерениеДоступности
    public let исход: ИсходДоступности
    public let длительностьНаносекунды: UInt64
    public var доверен: Bool { исход == .доверен }

    public init(намерение: НамерениеДоступности, доверен: Bool, длительностьНаносекунды: UInt64) {
        версияСхемы = 1
        self.намерение = намерение
        исход = доверен ? .доверен : .недоверен
        self.длительностьНаносекунды = длительностьНаносекунды
    }

    func данные() throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys]
        return try кодировщик.encode(self)
    }
}
