import Foundation
import КонтейнерНаблюдений

public enum СостояниеЗапуска: String, Codable, Sendable {
    case ожидаетПодключенияАдаптера = "ожидает подключения адаптера"
    case отказ
}

public enum ИзменениеИстории: String, Codable, Sendable {
    case добавлено
    case точныйПовтор
}

public enum КодОтказаЗапуска: String, Codable, Sendable {
    case аргументы, небезопасныйПуть, внутриGit, неполныйХвост
    case повреждениеИстории, конфликтИдентификатора, несовместимаяЗапись
    case хранилищеЗанято, предел, системнаяОшибка, внутренняя
}

public enum СостояниеЗаписиСобытия: String, Codable, Sendable {
    case неНачата, исходНеизвестен, подтверждена
}

public struct ОтказЗапуска: Error, Codable, Sendable {
    public let код: КодОтказаЗапуска
    public let сообщение: String
    public let системныйКод: Int32?
    public let записьСобытия: СостояниеЗаписиСобытия
    public let принятаяКвитанция: Квитанция?

    public init(код: КодОтказаЗапуска, сообщение: String, системныйКод: Int32? = nil,
                записьСобытия: СостояниеЗаписиСобытия = .неНачата,
                принятаяКвитанция: Квитанция? = nil) {
        self.код = код
        self.сообщение = сообщение
        self.системныйКод = системныйКод
        self.записьСобытия = записьСобытия
        self.принятаяКвитанция = принятаяКвитанция
    }
}

public struct ПараметрыЗапуска: Sendable {
    public let хранилище: String
    public let событие: String?
    public let намерение: String
    public let профиль: Bool
}

public struct НачальноеНамерение: Codable, Equatable, Sendable {
    public let версияСхемы: Int
    public let намерение: String
    public let подключённыеАдаптеры: [String]
}

public struct РезультатЦикла: Codable, Sendable {
    public let квитанция: Квитанция
    public let наблюдение: НачальноеНамерение
    public let изменение: ИзменениеИстории
    public let принятоЗаписей: Int
    public let провереноПослеПереоткрытия: Bool
    public let полезныйЦиклНаносекунды: UInt64?
}

public struct ОтветЗапуска: Codable, Sendable {
    public let версияСхемы: Int
    public let состояние: СостояниеЗапуска
    public let результат: РезультатЦикла?
    public let ошибка: ОтказЗапуска?

    public init(результат: РезультатЦикла) {
        версияСхемы = 1
        состояние = .ожидаетПодключенияАдаптера
        self.результат = результат
        ошибка = nil
    }

    public init(ошибка: ОтказЗапуска) {
        версияСхемы = 1
        состояние = .отказ
        результат = nil
        self.ошибка = ошибка
    }
}

public enum ПредставлениеЗапуска {
    public static func байты<Значение: Encodable>(_ значение: Значение, читаемо: Bool = false) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        if читаемо { кодировщик.outputFormatting.insert(.prettyPrinted) }
        var данные = try кодировщик.encode(значение)
        данные.append(0x0a)
        return данные
    }
}
