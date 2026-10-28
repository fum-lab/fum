import Foundation

struct СвидетельствоВыбораМодели: Codable, Equatable {
    let источникAPI: String
    let запрошеннаяМодель: String
    let запрошенноеУсилие: String
    let наблюдаемаяМодель: String
    let наблюдаемоеУсилие: String
    let видНаблюдения: String
    let источникНаблюдения: String
    let корневойUUID: String
}

struct ОжидаемаяИдентичностьGit: Codable, Equatable {
    let свидетельство: СвидетельствоВыбораМодели
    let родитель: String
}

struct ПланСообщенияКоммита: Codable, Equatable {
    let исходныйЗапрос: String
    let заголовок: String
    let описание: String
}

struct ИдентификаторGit: Codable, Equatable {
    let имя: String
    let почта: String
}

struct РезультатГенерацииМетаданныхКоммита: Codable, Equatable {
    let выборМодели: СвидетельствоВыбораМодели
    let автор: ИдентификаторGit
    let коммитер: ИдентификаторGit
    let окружение: [String: String]
    let сообщение: String
    let ошибки: [String]
}

enum ГенераторМетаданныхКоммита {
    private static let неизвестныеТокены: Set<String> = ["unknown", "unavailable", "unset", "null"]
    private static let русскиеБуквы = CharacterSet(charactersIn: "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя")
    private static let стопСловаЗаголовка: Set<String> = ["общий", "общая", "общие", "новый", "новая", "новое", "точный", "точная", "свой", "для", "при", "после", "перед", "между", "этот", "эта", "это", "в", "во", "на", "и", "по", "с", "к"]

    static func имяАвтора(_ свидетельство: СвидетельствоВыбораМодели) -> String {
        "FUM Codex [\(свидетельство.наблюдаемаяМодель); effort=\(свидетельство.наблюдаемоеУсилие)]"
    }

    static func проверитьНаблюдение(_ свидетельство: СвидетельствоВыбораМодели) -> [String] {
        var ошибки: [String] = []
        if свидетельство.источникAPI != "collaboration.spawn_agent" {
            ошибки.append("неподтверждённый-источник-выбора-модели")
        }
        if !безопасныйТокен(свидетельство.запрошеннаяМодель) {
            ошибки.append("некорректная-запрошенная-модель")
        }
        if !безопасныйТокен(свидетельство.запрошенноеУсилие) {
            ошибки.append("некорректное-запрошенное-усилие")
        }
        if !безопасныйТокен(свидетельство.наблюдаемаяМодель) {
            ошибки.append("некорректная-наблюдаемая-модель")
        }
        if !безопасныйТокен(свидетельство.наблюдаемоеУсилие) {
            ошибки.append("некорректное-наблюдаемое-усилие")
        }
        if свидетельство.видНаблюдения != "accepted-api-selection" {
            ошибки.append("неподтверждённый-вид-наблюдения-модели")
        }
        if свидетельство.источникНаблюдения.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибки.append("нет-источника-наблюдения-модели")
        }
        if UUID(uuidString: свидетельство.корневойUUID) == nil {
            ошибки.append("некорректный-корневой-uuid-идентичности")
        } else if свидетельство.корневойUUID != UUID(uuidString: свидетельство.корневойUUID)?.uuidString.lowercased() {
            ошибки.append("корневой-uuid-не-каноничен")
        }
        return ошибки
    }

    static func проверитьЗаголовок(_ заголовок: String) -> [String] {
        let trimmed = заголовок.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed == заголовок, !заголовок.contains("\n"), !заголовок.contains("\r") else {
            return ["некорректный-однострочный-заголовок-коммита"]
        }

        let слова = заголовок.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let действие = слова.first, естьРусскаяЛексика(действие) else {
            return ["заголовок-без-русского-действия"]
        }
        let окончанияИнфинитива = ["ться", "тись", "чься", "ть", "ти", "чь"]
        guard окончанияИнфинитива.contains(where: действие.lowercased().hasSuffix) else {
            return ["заголовок-без-русского-действия"]
        }

        let естьТема = слова.dropFirst().contains { слово in
            let буквы = слово.unicodeScalars.filter(русскиеБуквы.contains)
            let нормализованноеСлово = слово.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return буквы.count >= 4 && !стопСловаЗаголовка.contains(нормализованноеСлово)
        }
        if !естьТема { return ["заголовок-без-русской-смысловой-темы"] }
        return []
    }

    static func сгенерировать(
        свидетельство: СвидетельствоВыбораМодели,
        авторGitVar: String,
        коммитерGitVar: String,
        планСообщения: ПланСообщенияКоммита
    ) -> РезультатГенерацииМетаданныхКоммита {
        var ошибки = проверитьНаблюдение(свидетельство)
        ошибки.append(contentsOf: проверитьЗаголовок(планСообщения.заголовок))

        let описание = планСообщения.описание.trimmingCharacters(in: .whitespacesAndNewlines)
        let исходныйЗапрос = планСообщения.исходныйЗапрос.trimmingCharacters(in: .whitespacesAndNewlines)
        if описание.isEmpty { ошибки.append("пустое-описание-сообщения-коммита") }
        if исходныйЗапрос.isEmpty { ошибки.append("пустой-исходный-запрос-сообщения-коммита") }
        if описание.contains("Codex-Thread-ID:") || исходныйЗапрос.contains("Codex-Thread-ID:") {
            ошибки.append("вход-содержит-зарезервированный-root-trailer")
        }

        let автор = разобратьGitIdent(авторGitVar) ?? ИдентификаторGit(имя: "", почта: "")
        let коммитер = разобратьGitIdent(коммитерGitVar) ?? ИдентификаторGit(имя: "", почта: "")
        if разобратьGitIdent(авторGitVar) == nil { ошибки.append("неразбираемый-git-author-ident") }
        if разобратьGitIdent(коммитерGitVar) == nil { ошибки.append("неразбираемый-git-committer-ident") }

        let ожидаемоеИмяАвтора = имяАвтора(свидетельство)
        if автор.имя != ожидаемоеИмяАвтора {
            ошибки.append("автор-git-var-не-совпадает-с-observed-моделью")
        }
        let сообщение = "\(планСообщения.заголовок)\n\n\(описание)\n\nИсходный запрос: \(исходныйЗапрос)\n\nCodex-Thread-ID: \(свидетельство.корневойUUID)\n"
        return РезультатГенерацииМетаданныхКоммита(
            выборМодели: свидетельство,
            автор: автор,
            коммитер: коммитер,
            окружение: ["GIT_AUTHOR_NAME": ожидаемоеИмяАвтора],
            сообщение: сообщение,
            ошибки: ошибки
        )
    }

    static func разобратьGitIdent(_ строка: String) -> ИдентификаторGit? {
        guard let леваяСкобка = строка.range(of: " <", options: .backwards),
              let праваяСкобка = строка[леваяСкобка.upperBound...].firstIndex(of: ">") else { return nil }
        let имя = String(строка[..<леваяСкобка.lowerBound])
        let почта = String(строка[леваяСкобка.upperBound..<праваяСкобка])
        guard !имя.isEmpty, !почта.isEmpty else { return nil }
        return ИдентификаторGit(имя: имя, почта: почта)
    }

    private static func безопасныйТокен(_ значение: String) -> Bool {
        let байты = Array(значение.utf8)
        guard (1...128).contains(байты.count), байты.first.map(букваИлиЦифраASCII) == true,
              байты.allSatisfy({ букваИлиЦифраASCII($0) || $0 == 46 || $0 == 95 || $0 == 45 }) else {
            return false
        }
        return !неизвестныеТокены.contains(значение.lowercased())
    }

    private static func букваИлиЦифраASCII(_ байт: UInt8) -> Bool {
        (48...57).contains(байт) || (65...90).contains(байт) || (97...122).contains(байт)
    }

    private static func естьРусскаяЛексика(_ слово: String) -> Bool {
        слово.unicodeScalars.contains(where: русскиеБуквы.contains)
    }
}
