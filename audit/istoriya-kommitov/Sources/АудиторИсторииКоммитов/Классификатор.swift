public struct ПодписьМодели: Sendable, Equatable {
    public let модель: String
    public let усилие: String

    public init(модель: String, усилие: String) {
        self.модель = модель
        self.усилие = усилие
    }
}

public enum ИтогСовпаденияФорматаИмениАвтора: String, Codable, Sendable {
    case совпадаетСФорматом = "имя совпадает с форматом"
    case неСовпадаетСФорматом = "имя не совпадает с форматом"
    case правилоФорматаНеНайдено = "правило формата не найдено"
}

public enum СтатусНативногоПодтвержденияАвтора: String, Codable, Sendable {
    case неПроверено = "подтверждение по нативной записи не проверено"
}

public enum СигналТемы: String, Codable, Sendable {
    case естьКириллица = "есть кириллица"
    case толькоЛатиница = "только латиница"
    case смешанныйИлиБезБукв = "смешанный или без букв"
}

public enum Классификатор {
    public static func извлечьПодписьМодели(_ имя: String) -> ПодписьМодели? {
        let начало = "FUM Codex ["
        guard имя.hasPrefix(начало), имя.hasSuffix("]") else { return nil }
        let содержимое = имя.dropFirst(начало.count).dropLast()
        guard let разделитель = содержимое.range(of: "; effort=") else { return nil }
        let модель = String(содержимое[..<разделитель.lowerBound])
        let усилие = String(содержимое[разделитель.upperBound...])
        guard !модель.isEmpty, !усилие.isEmpty,
              !модель.contains(where: { $0 == "[" || $0 == "]" || $0 == ";" }),
              !усилие.contains(where: { $0 == "[" || $0 == "]" || $0 == ";" }) else {
            return nil
        }
        return ПодписьМодели(модель: модель, усилие: усилие)
    }

    public static func авторСоответствуетФорматуCodex(_ имя: String) -> Bool {
        извлечьПодписьМодели(имя) != nil
    }

    public static func итогСовпаденияФорматаИмениАвтора(
        _ имя: String, правилоАктивно: Bool
    ) -> ИтогСовпаденияФорматаИмениАвтора {
        guard правилоАктивно else { return .правилоФорматаНеНайдено }
        return авторСоответствуетФорматуCodex(имя) ? .совпадаетСФорматом : .неСовпадаетСФорматом
    }

    public static func сигналТемы(_ тема: String) -> СигналТемы {
        var кириллица = false
        var латиница = false
        for scalar in тема.unicodeScalars {
            let код = scalar.value
            if (0x0400...0x052F).contains(код) { кириллица = true }
            if (0x0041...0x005A).contains(код) || (0x0061...0x007A).contains(код) {
                латиница = true
            }
        }
        if кириллица && !латиница { return .естьКириллица }
        if !кириллица && латиница { return .толькоЛатиница }
        return .смешанныйИлиБезБукв
    }

    public static func корректныйOID(_ значение: String) -> Bool {
        guard значение.utf8.count == 40 || значение.utf8.count == 64 else { return false }
        return значение.utf8.allSatisfy { байт in
            (0x30...0x39).contains(байт) || (0x41...0x46).contains(байт) ||
                (0x61...0x66).contains(байт)
        }
    }
}
