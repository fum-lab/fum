import Foundation

public struct ОтветКомандыЯзыка: Sendable {
    public let данные: Data
    public let код: Int32
}

public enum КомандаЯзыковогоДопуска {
    public static func перехватить(_ аргументы: [String]) -> ОтветКомандыЯзыка? {
        guard аргументы.first == "язык" else { return nil }
        do {
            guard аргументы.count == 4, аргументы[1] == "индекс", аргументы[2] == "--корень" else {
                throw ОтказЧитателяЯзыка.формат
            }
            let результат = try ПроверкаЯзыковогоИндекса.проверить(корень: аргументы[3])
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var данные = try кодировщик.encode(результат)
            данные.append(10)
            return .init(данные: данные, код: результат.нарушения.isEmpty ? 0 : 1)
        } catch {
            struct Отказ: Encodable {
                let схема = "fum.отказ-языкового-допуска.1"
                let причина: String
                let исход = "допуск-закрыт"
            }
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var данные = (try? кодировщик.encode(Отказ(причина: String(describing: error)))) ?? Data("{}".utf8)
            данные.append(10)
            return .init(данные: данные, код: 2)
        }
    }
}
