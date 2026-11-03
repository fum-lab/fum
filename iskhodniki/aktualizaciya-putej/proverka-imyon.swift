import Foundation

struct ТранслитераторПутей: Sendable {
    func отобразить(_ записи: [ЗаписьСнимкаПутей]) async throws -> [ОтображениеПути] {
        try await ШтатноеОтображениеПутей.отобразить(записи)
    }
}

enum ИменаПутей {
    static func компоненты(_ путь: String, сохранятьПустые: Bool = false) -> [String] {
        путь.utf8.split(separator: 47, omittingEmptySubsequences: !сохранятьПустые).map { String(decoding: $0, as: UTF8.self) }
    }
    static func имеетПрефикс(_ путь: String, _ префикс: String) -> Bool { путь.utf8.starts(with: префикс.utf8) }
    static func проверитьПуть(_ путь: String) throws {
        guard !путь.isEmpty, путь.utf8.count <= 1024 else { throw ОшибкаПутей.отказ("Небезопасный относительный путь") }
        let части = компоненты(путь, сохранятьПустые: true)
        guard
              !путь.utf8.contains(92),
              !путь.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git"
                  && $0.utf8.count <= 255 }) else {
            throw ОшибкаПутей.отказ("Небезопасный относительный путь")
        }
    }

    // Сегментация исходного Unicode-имени предшествует LinguisticKit.
    // Не угадываем смысл XMLHTTP, IPv6 и других составных сокращений.
    static func разбить(_ имя: String) -> String {
        let знаки = Array(имя)
        var результат = ""
        for номер in знаки.indices {
            let знак = знаки[номер]
            if номер > 0, знак.isUppercase {
                let прежний = знаки[номер - 1]
                let следующаяСтрочная = номер + 1 < знаки.count && знаки[номер + 1].isLowercase
                if прежний.isLowercase || прежний.isNumber || (прежний.isUppercase && следующаяСтрочная) {
                    результат.append("-")
                }
            }
            результат.append(знак)
        }
        return результат
    }

    static func нормализовать(_ транслитерация: String) throws -> String {
        // В том числе K: сначала ASCII, затем lowercase; никакой NFKC.
        guard транслитерация.utf8.allSatisfy({ $0 < 128 }) else {
            throw ОшибкаПутей.отказ("Результат LinguisticKit не является ASCII")
        }
        let результат = транслитерация.lowercased()
            .replacingOccurrences(of: "[ _-]+", with: "-", options: .regularExpression)
        guard !результат.isEmpty,
              результат.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0)
                  || [45, 46].contains($0) }), результат != ".", результат != "..",
              результат.utf8.count <= 255 else {
            throw ОшибкаПутей.отказ("Недопустимое lowercase kebab-имя")
        }
        return результат
    }

    static func ключКоллизии(_ путь: String) -> Data {
        Data(путь.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .precomposedStringWithCanonicalMapping.utf8)
    }

    static func вложен(_ путь: String, в родитель: String) -> Bool {
        Data(путь.utf8) == Data(родитель.utf8) || путь.utf8.starts(with: (родитель + "/").utf8)
    }

    static func исключение(_ путь: String) -> ИсключениеИмени? {
        let части = компоненты(путь)
        guard let имя = части.last else { return nil }
        if Data(имя.utf8) == Data("Package.swift".utf8) {
            return ИсключениеИмени(путь: путь, имя: имя, причина: "точное имя манифеста SwiftPM",
                источник: "https://docs.swift.org/latest/documentation/packagedescription/")
        }
        if Data(имя.utf8) == Data("AGENTS.md".utf8) {
            return ИсключениеИмени(путь: путь, имя: имя, причина: "корневой вход инструкций агента",
                источник: "AGENTS.md")
        }
        if части.count == 3, Data(части[0].utf8) == Data("Инструменты".utf8), Data(имя.utf8) == Data("SKILL.md".utf8) {
            return ИсключениеИмени(путь: путь, имя: имя, причина: "точное обнаружение локального навыка",
                источник: "Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py")
        }
        return nil
    }
}
