import Foundation

public enum КомандаПакетаПутей: Sendable, Equatable {
    case построить(корень: URL, вход: URL)
    case сверить(корень: URL, план: URL, sha256: String)
    case применить(корень: URL, план: URL, sha256: String)
}

public enum ОшибкаАргументовПакетаПутей: Error, Sendable, Equatable {
    case неверныеАргументы
}

public enum РазборПакетаПутей {
    public static func разобрать(_ аргументы: [String]) throws -> КомандаПакетаПутей {
        guard let действие = аргументы.first else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }
        let допустимые: Set<String>
        switch действие {
        case "построить": допустимые = ["--корень", "--вход"]
        case "сверить", "применить": допустимые = ["--корень", "--план", "--sha256"]
        default: throw ОшибкаАргументовПакетаПутей.неверныеАргументы
        }

        let пары = Array(аргументы.dropFirst())
        guard пары.count.isMultiple(of: 2) else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }
        var значения: [String: String] = [:]
        for номер in stride(from: 0, to: пары.count, by: 2) {
            let ключ = пары[номер]
            let значение = пары[номер + 1]
            guard допустимые.contains(ключ), значения[ключ] == nil,
                  !значение.isEmpty, !значение.hasPrefix("--"),
                  !значение.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
            else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }
            значения[ключ] = значение
        }

        guard let корень = значения["--корень"], let адресКорня = абсолютныйАдрес(корень, каталог: true)
        else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }

        switch действие {
        case "построить":
            guard let путьВхода = значения["--вход"], let адресВхода = абсолютныйАдрес(путьВхода),
                  значения.count == 2 else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }
            return .построить(корень: адресКорня, вход: адресВхода)
        case "сверить", "применить":
            guard let путьПлана = значения["--план"], let адресПлана = абсолютныйАдрес(путьПлана),
                  let sha256 = значения["--sha256"], корректныйSHA256(sha256),
                  значения.count == 3 else { throw ОшибкаАргументовПакетаПутей.неверныеАргументы }
            if действие == "сверить" {
                return .сверить(корень: адресКорня, план: адресПлана, sha256: sha256)
            }
            return .применить(корень: адресКорня, план: адресПлана, sha256: sha256)
        default:
            throw ОшибкаАргументовПакетаПутей.неверныеАргументы
        }
    }

    private static func абсолютныйАдрес(_ путь: String, каталог: Bool = false) -> URL? {
        guard путь.hasPrefix("/"), !путь.utf8.contains(0) else { return nil }
        return URL(fileURLWithPath: путь, isDirectory: каталог)
    }

    private static func корректныйSHA256(_ значение: String) -> Bool {
        значение.utf8.count == 64 && значение.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}
