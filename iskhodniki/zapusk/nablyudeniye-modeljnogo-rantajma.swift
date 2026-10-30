import Foundation

public enum ПроисхождениеМодели: String, Codable, Sendable {
    case запросFUMA
    case выборКлиента
    case подтверждениеBackend
}

public enum СостояниеНаблюдения: String, Codable, Sendable {
    case актуально
    case устарело
    case неизвестно
    case конфликт
}

public struct ПолеМодели: Codable, Equatable, Sendable {
    public let значение: String?
    public let источник: String
    public let время: Date?
    public let состояние: СостояниеНаблюдения

    public init(значение: String?, источник: String, время: Date?, состояние: СостояниеНаблюдения) {
        self.значение = значение
        self.источник = источник
        self.время = время
        self.состояние = состояние
    }
}

public struct СнимокМодельногоРантайма: Codable, Equatable, Sendable {
    public let идентификаторНаблюдателя: String
    public let идентификаторRuntime: String
    public let модельFUMA: ПолеМодели
    public let модельКлиента: ПолеМодели
    public let модельBackend: ПолеМодели
    public let усилиеFUMA: ПолеМодели
    public let усилиеКлиента: ПолеМодели
    public let усилиеBackend: ПолеМодели

    public init(идентификаторНаблюдателя: String, идентификаторRuntime: String,
                модельFUMA: ПолеМодели, модельКлиента: ПолеМодели, модельBackend: ПолеМодели,
                усилиеFUMA: ПолеМодели, усилиеКлиента: ПолеМодели, усилиеBackend: ПолеМодели) {
        self.идентификаторНаблюдателя = идентификаторНаблюдателя
        self.идентификаторRuntime = идентификаторRuntime
        self.модельFUMA = модельFUMA
        self.модельКлиента = модельКлиента
        self.модельBackend = модельBackend
        self.усилиеFUMA = усилиеFUMA
        self.усилиеКлиента = усилиеКлиента
        self.усилиеBackend = усилиеBackend
    }

    public func кодировать() throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        кодировщик.dateEncodingStrategy = .iso8601
        var данные = try кодировщик.encode(self)
        данные.append(0x0a)
        return данные
    }

    public static func декодировать(_ данные: Data) throws -> Self {
        let декодировщик = JSONDecoder()
        декодировщик.dateDecodingStrategy = .iso8601
        return try декодировщик.decode(Self.self, from: данные)
    }
}

public enum НаблюдательМодельногоРантайма {
    public static func состояние(желательное: String?, выбранное: String?, подтверждённое: String?,
                                 время: Date?, срокСекунд: TimeInterval, сейчас: Date) -> СостояниеНаблюдения {
        guard let время, let срокСекунд = срокСекунд.isFinite ? срокСекунд : nil,
              срокСекунд >= 0, сейчас.timeIntervalSince(время) <= срокСекунд else { return .устарело }
        guard let выбранное else { return .неизвестно }
        if let подтверждённое, подтверждённое != выбранное { return .конфликт }
        if let желательное, желательное != выбранное { return .конфликт }
        return .актуально
    }
}
