import Foundation

enum ОрфографияОбъявлений {
    // Конечные формы, не общий словарь русской орфографии; неоднозначное «все» исключено.
    static let обязательнаяЁ: Set<String> = [
        "отчет", "отчета", "отчеты", "отчетов", "отчету", "отчетом",
        "учет", "учета", "учету", "учетом", "расчет", "расчета", "расчеты",
        "счетчик", "счетчика", "счетчики", "еще", "сохраненный", "подтвержденный",
        "незавершенный", "завершенный", "определенный",
    ]

    static func причина(_ имя: String) -> String? {
        let нормальное = имя.precomposedStringWithCanonicalMapping
        guard нормальное.unicodeScalars.allSatisfy({
            $0 == "_" || (0x0410...0x044f).contains($0.value)
                || $0 == "Ё" || $0 == "ё" || (0x30...0x39).contains($0.value)
        }) else { return "нерусский-алфавит" }
        let строчное = нормальное.lowercased()
        if ["отчет", "расчет", "счетчик"].contains(where: строчное.contains)
            || обязательнаяЁ.contains(where: строчное.hasSuffix) { return "обязательная-ё" }
        if ["сохраненный", "подтвержденный", "незавершенный", "завершенный", "определенный", "еще"]
            .contains(where: строчное.hasPrefix) { return "обязательная-ё" }
        var часть = ""
        var части: [String] = []
        let символы = Array(нормальное.unicodeScalars)
        for номер in символы.indices {
            let символ = символы[номер]
            if символ == "_" || (0x30...0x39).contains(символ.value) {
                if !часть.isEmpty { части.append(часть.lowercased()); часть = "" }
            } else {
                let прописная = CharacterSet.uppercaseLetters.contains(символ)
                let предыдущаяСтрочная = номер > 0 && CharacterSet.lowercaseLetters.contains(символы[номер - 1])
                let следующаяСтрочная = номер + 1 < символы.count
                    && CharacterSet.lowercaseLetters.contains(символы[номер + 1])
                if прописная, !часть.isEmpty, предыдущаяСтрочная || следующаяСтрочная {
                    части.append(часть.lowercased()); часть = ""
                }
                часть.unicodeScalars.append(символ)
            }
        }
        if !часть.isEmpty { части.append(часть.lowercased()) }
        return части.contains(where: обязательнаяЁ.contains) ? "обязательная-ё" : nil
    }
}
