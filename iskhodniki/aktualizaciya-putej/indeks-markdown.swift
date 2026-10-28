import Foundation
import CryptoKit

struct СтрокаИндексаMarkdown: Codable, Equatable, Sendable {
    var путь: String
    var время: String
}

enum ОтказИндексаMarkdown: Error, Equatable {
    case вход(String)
}

// Узкое производное представление; не является проверкой свежести исходных MD.
enum ИндексMarkdownСлияния {
    static let путь = "Индексы/markdown-файлы-по-времени-редактирования.md"

    static func построить(_ строки: [СтрокаИндексаMarkdown], время: String,
                           прежний: Data = Data()) throws -> Data {
        let формат = форматВремени()
        try проверитьВремя(время, формат: формат)
        var встреченные = Set<Data>()
        for строка in строки {
            let части = строка.путь.split(separator: "/", omittingEmptySubsequences: false)
            guard !части.isEmpty, части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
                  !строка.путь.contains(where: { $0 == "\n" || $0 == "\r" || $0 == "\0" || $0 == "|" }),
                  строка.путь != путь,
                  встреченные.insert(Data(строка.путь.utf8)).inserted else {
                throw ОтказИндексаMarkdown.вход("повтор-или-небезопасный-путь")
            }
            try проверитьВремя(строка.время, формат: формат)
        }
        if let старая = try метаданные(прежний, формат: формат) {
            let тело = телоИндекса(строки, время: старая.время)
            if старая.содержание == тело, старая.sha256 == хэш(Data(тело.utf8)) { return прежний }
        }
        let тело = телоИндекса(строки, время: время)
        return Data((тело + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: \(время) -->\n<!-- content-sha256: sha256:\(хэш(Data(тело.utf8))) -->\n<!-- FUM-MD-RECENCY:END -->\n").utf8)
    }

    static func хэш(_ байты: Data) -> String {
        SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
    }

    static func форматВремени() -> DateFormatter {
        let формат = DateFormatter()
        формат.locale = Locale(identifier: "en_US_POSIX")
        формат.timeZone = TimeZone(identifier: "Europe/Moscow")
        формат.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"
        формат.isLenient = false
        return формат
    }

    static func проверитьВремя(_ время: String, формат: DateFormatter? = nil) throws {
        let формат = формат ?? форматВремени()
        guard let дата = формат.date(from: время), формат.string(from: дата) == время else {
            throw ОтказИндексаMarkdown.вход("неверная-дата")
        }
    }

    static func метаданные(_ байты: Data, маска: String? = nil, формат: DateFormatter? = nil) throws -> (содержание: String, время: String, sha256: String)? {
        guard let текст = String(data: байты, encoding: .utf8) else { return nil }
        let выражение = try NSRegularExpression(pattern: #"(?:\A|\n)<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: ([^>]+) -->\n<!-- content-sha256: sha256:([0-9a-f]{64}) -->\n<!-- FUM-MD-RECENCY:END -->\n?\z"#)
        guard let совпадение = выражение.firstMatch(in: маска ?? текст, range: NSRange(текст.startIndex..., in: текст)),
              let блок = Range(совпадение.range, in: текст),
              let дата = Range(совпадение.range(at: 1), in: текст),
              let хэш = Range(совпадение.range(at: 2), in: текст) else { return nil }
        let время = String(текст[дата])
        try проверитьВремя(время, формат: формат)
        var содержание = String(текст[..<блок.lowerBound])
        if !содержание.hasSuffix("\n") { содержание += "\n" }
        return (содержание, время, String(текст[хэш]))
    }

    private static func телоИндекса(_ строки: [СтрокаИндексаMarkdown], время: String) -> String {
        let все = (строки + [СтрокаИндексаMarkdown(путь: путь, время: время)]).sorted {
            if $0.время != $1.время { return $0.время > $1.время }
            return $1.путь.utf8.lexicographicallyPrecedes($0.путь.utf8)
        }
        let заголовки = ["Файл", "Последнее содержательное редактирование"]
        let ячейки = все.map { строка in
            let ссылка = строка.путь.hasPrefix("Индексы/")
                ? String(строка.путь.dropFirst("Индексы/".count)) : "../" + строка.путь
            return ["[\(строка.путь)](\(ссылка))", строка.время]
        }
        let ширины = заголовки.indices.map { номер in
            ([3, заголовки[номер].unicodeScalars.count] + ячейки.map { $0[номер].unicodeScalars.count }).max()!
        }
        func строка(_ значения: [String]) -> String {
            "| " + значения.enumerated().map { номер, значение in
                значение + String(repeating: " ", count: ширины[номер] - значение.unicodeScalars.count)
            }.joined(separator: " | ") + " |"
        }
        let таблица = [строка(заголовки), строка(ширины.map { String(repeating: "-", count: $0) })] + ячейки.map(строка)
        return ([
            "# Markdown-файлы по времени редактирования", "",
            "Этот индекс строится локальной автоматизацией `fum-svezhestj-markdown`. Он перечисляет все Markdown-файлы [памяти FUM](../Глоссарий/память-FUM.md) от свежих к более старым по метке последнего содержательного редактирования.", "",
            "Служебная метка `FUM-MD-RECENCY` хранится в конце каждого `.md`-файла и не учитывается при расчёте хэша содержательного текста.",
            "В каноническом `Журнал/<сессия>/отчёт.md` единственный управляемый блок `FUM-CHECK-RUNS` тоже не изменяет метку свежести.", ""
        ] + таблица).joined(separator: "\n") + "\n"
    }
}
