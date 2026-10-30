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
        кодировщик.dateEncodingStrategy = .custom { дата, кодировщик in
            let формат = ISO8601DateFormatter()
            формат.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var контейнер = кодировщик.singleValueContainer()
            try контейнер.encode(формат.string(from: дата))
        }
        var данные = try кодировщик.encode(self)
        данные.append(0x0a)
        return данные
    }

    public static func декодировать(_ данные: Data) throws -> Self {
        let декодировщик = JSONDecoder()
        декодировщик.dateDecodingStrategy = .custom { декодировщик in
            let контейнер = try декодировщик.singleValueContainer()
            let строка = try контейнер.decode(String.self)
            let дробныйФормат = ISO8601DateFormatter()
            дробныйФормат.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let дата = дробныйФормат.date(from: строка) { return дата }
            let обычныйФормат = ISO8601DateFormatter()
            обычныйФормат.formatOptions = [.withInternetDateTime]
            if let дата = обычныйФормат.date(from: строка) { return дата }
            throw DecodingError.dataCorruptedError(in: контейнер, debugDescription: "Некорректная метка времени наблюдения")
        }
        return try декодировщик.decode(Self.self, from: данные)
    }
}

public enum НаблюдательМодельногоРантайма {
    public static func состояние(желательное: String?, выбранное: String?, подтверждённое: String?,
                                 время: Date?, срокСекунд: TimeInterval, сейчас: Date) -> СостояниеНаблюдения {
        guard let время, время.timeIntervalSince1970.isFinite, сейчас.timeIntervalSince1970.isFinite,
              срокСекунд.isFinite, срокСекунд >= 0 else { return .неизвестно }
        let разница = сейчас.timeIntervalSince(время)
        guard разница.isFinite else { return .неизвестно }
        if разница < 0 { return .неизвестно }
        if разница > срокСекунд { return .устарело }
        guard let выбранное else { return .неизвестно }
        if let желательное, желательное != выбранное { return .конфликт }
        guard let подтверждённое else { return .неизвестно }
        if подтверждённое != выбранное { return .конфликт }
        return .актуально
    }
}
