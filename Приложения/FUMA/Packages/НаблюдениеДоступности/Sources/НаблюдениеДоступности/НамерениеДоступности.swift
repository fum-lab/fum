import Foundation
import КонтейнерНаблюдений

public struct НамерениеДоступности: Codable, Equatable, Sendable {
    public let версияСхемы: Int
    public let идентификаторПопытки: String
    public let операция: String
    public let оператор: String
    public let версияГрафа: String
    public let время: String
    public let процесс: Int32

    public init(попытка: UUID, оператор: String, версияГрафа: String, время: String, процесс: Int32) {
        версияСхемы = 1
        идентификаторПопытки = попытка.uuidString.lowercased()
        операция = "AXIsProcessTrusted()"
        self.оператор = оператор
        self.версияГрафа = версияГрафа
        self.время = время
        self.процесс = процесс
    }

    public var идентификаторНамерения: String { "доступность/\(идентификаторПопытки)/намерение" }
    public var идентификаторОтвета: String { "доступность/\(идентификаторПопытки)/ответ" }

    func данные() throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys]
        return try кодировщик.encode(self)
    }

    func описание(ответ: Bool) throws -> ОписаниеНаблюдения {
        ОписаниеНаблюдения(идентификатор: ответ ? идентификаторОтвета : идентификаторНамерения,
            тип: ответ ? "ответ-доступности" : "намерение-доступности", версияСхемы: 1,
            источник: операция, время: время, спецификация: try данные())
    }

    func проверить() throws {
        guard версияСхемы == 1, операция == "AXIsProcessTrusted()" else {
            throw ОшибкаНаблюденияДоступности.неподдерживаемаяСхема
        }
        guard let попытка = UUID(uuidString: идентификаторПопытки),
              попытка.uuidString.lowercased() == идентификаторПопытки else {
            throw ОшибкаНаблюденияДоступности.неверныйИдентификатор
        }
        guard !оператор.isEmpty, !версияГрафа.isEmpty, !время.isEmpty, процесс > 0 else {
            throw ОшибкаНаблюденияДоступности.неполноеПроисхождение
        }
    }
}
