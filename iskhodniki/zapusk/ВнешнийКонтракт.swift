import Foundation

/// Версионное представление происхождения: упорядоченная пара URL и SHA256.
struct ИсточникВнешнегоКонтракта: Codable, Sendable {
    let адрес: String
    let хэш: String

    init(адрес: String, хэш: String) {
        self.адрес = адрес
        self.хэш = хэш
    }

    func encode(to кодировщик: any Encoder) throws {
        var контейнер = кодировщик.singleValueContainer()
        try контейнер.encode([адрес, хэш])
    }

    init(from декодировщик: any Decoder) throws {
        let контейнер = try декодировщик.singleValueContainer()
        let значения = try контейнер.decode([String].self)
        guard значения.count == 2 else { throw ОтказЧитателяЯзыка.политика }
        адрес = значения[0]
        хэш = значения[1]
    }
}
