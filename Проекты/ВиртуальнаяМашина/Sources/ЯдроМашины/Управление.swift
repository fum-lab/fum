import Foundation

public struct ЖизненныйЦикл {
    public private(set) var фаза = "запускается"
    public init() {}
    public mutating func перейти(_ новая: String) throws {
        let переходы: [String: Set<String>] = [
            "запускается": ["работает", "ошибка", "останавливается"],
            "работает": ["проверка готовности", "останавливается", "остановлена", "ошибка"],
            "проверка готовности": ["готова", "работает", "останавливается", "остановлена", "ошибка"],
            "готова": ["проверка готовности", "останавливается", "остановлена", "ошибка"],
            "останавливается": ["остановлена", "ошибка"]]
        guard переходы[фаза]?.contains(новая) == true else { throw ОшибкаМашины("Недопустимый переход VM: \(фаза) → \(новая).") }
        фаза = новая
    }
}
public struct ЗапускМашины: Codable {
    public var схема = "fum.запуск-машины.1"
    public var машина: String
    public var план: String
    public var запуск = UUID().uuidString.lowercased()
    public var токен = UUID().uuidString.lowercased() + UUID().uuidString.lowercased()
    public var портДоступаКГостю: UInt16
    public var портУправления: UInt16
    public var фаза = "запускается"
    public var причина: String?
    enum CodingKeys: String, CodingKey {
        case схема = "схема"
        case машина = "машина"
        case план = "план"
        case запуск = "запуск"
        case токен = "токен"
        case портДоступаКГостю = "портSSH"
        case портУправления = "портУправления"
        case фаза = "фаза"
        case причина = "причина"
    }

    public init(машина: String, план: String, портДоступаКГостю: UInt16, портУправления: UInt16) {
        self.машина = машина; self.план = план; self.портДоступаКГостю = портДоступаКГостю; self.портУправления = портУправления
    }
    public func проверить(токен: String, запуск: String) throws {
        guard схема == "fum.запуск-машины.1", self.токен == токен, self.запуск == запуск else {
            throw ОшибкаМашины("Команда принадлежит другому запуску VM.")
        }
    }
}
