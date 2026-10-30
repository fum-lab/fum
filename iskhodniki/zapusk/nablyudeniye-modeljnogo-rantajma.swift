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
            var контейнер = кодировщик.singleValueContainer()
            try контейнер.encode(Self.строкаДаты(дата))
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
            if let дата = датаИзСтрокиUTC(строка) { return дата }
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

    private static func строкаДаты(_ дата: Date) throws -> String {
        let интервал = дата.timeIntervalSince1970
        guard интервал.isFinite else {
            throw EncodingError.invalidValue(дата, .init(codingPath: [], debugDescription: "Невозможно кодировать нечисловую дату"))
        }
        var секунды = floor(интервал)
        var наносекунды = Int(((интервал - секунды) * 1_000_000_000).rounded())
        if наносекунды == 1_000_000_000 {
            секунды += 1
            наносекунды = 0
        }
        let формат = ISO8601DateFormatter()
        формат.formatOptions = [.withInternetDateTime]
        let основа = формат.string(from: Date(timeIntervalSince1970: секунды))
        guard наносекунды > 0 else { return основа }
        let дробь = String(format: "%09d", locale: Locale(identifier: "en_US_POSIX"), наносекунды)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return String(основа.dropLast()) + "." + дробь + "Z"
    }

    private static func датаИзСтрокиUTC(_ строка: String) -> Date? {
        guard строка.hasSuffix("Z"), let точка = строка.lastIndex(of: ".") else { return nil }
        let цифрыНачало = строка.index(after: точка)
        let цифрыКонец = строка.index(before: строка.endIndex)
        let цифры = строка[цифрыНачало..<цифрыКонец]
        guard (1...9).contains(цифры.count), цифры.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        let основа = String(строка[..<точка]) + "Z"
        let формат = ISO8601DateFormatter()
        формат.formatOptions = [.withInternetDateTime]
        guard let целаяДата = формат.date(from: основа), let доля = Double("0." + цифры) else { return nil }
        return Date(timeIntervalSince1970: целаяДата.timeIntervalSince1970 + доля)
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
