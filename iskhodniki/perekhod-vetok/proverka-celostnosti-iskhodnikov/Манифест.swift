import Foundation
import CryptoKit

struct ОтказЦелостности: Error, Sendable {
    let причина: String
    let выход: Int32
    let доказано: Bool
    init(_ причина: String, _ выход: Int32 = 1, доказано: Bool = false) {
        self.причина = причина
        self.выход = выход
        self.доказано = доказано
    }
}

enum ПределыЦелостности {
    static let манифест = 262_144
    static let файлы = 256
    static let файл = 4_194_304
    static let сумма = 16_777_216
    static let метаданные = 8_388_608
    static let объектМетаданных = 1_048_576
    static let объекты = 4_096
    static let глубина = 8
    static let путь = 1_024
    static let компоненты = 32
    static let вывод = 8_192
    static let профиль = 2_048
}

func хэшБайтов(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

func хэшОбъекта(_ тип: String, _ тело: Data, _ формат: String) -> String {
    let заголовок = Data("\(тип) \(тело.count)\0".utf8)
    if формат == "sha1" {
        var хэш = Insecure.SHA1()
        хэш.update(data: заголовок)
        хэш.update(data: тело)
        return хэш.finalize().map { String(format: "%02x", $0) }.joined()
    }
    var хэш = SHA256()
    хэш.update(data: заголовок)
    хэш.update(data: тело)
    return хэш.finalize().map { String(format: "%02x", $0) }.joined()
}

func шестнадцатеричный(_ строка: String, _ длина: Int) -> Bool {
    строка.utf8.count == длина && строка.utf8.allSatisfy {
        (48...57).contains($0) || (97...102).contains($0)
    }
}

func допустимыйПуть(_ путь: String) -> Bool {
    guard !путь.isEmpty, путь.utf8.count <= ПределыЦелостности.путь,
          !путь.hasPrefix("/"), !путь.contains("\\"),
          путь.utf8.elementsEqual(путь.precomposedStringWithCanonicalMapping.utf8),
          путь.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else { return false }
    let байты = Array(путь.utf8)
    if байты.count >= 2 && ((65...90).contains(байты[0]) || (97...122).contains(байты[0])) && байты[1] == 58 {
        return false
    }
    let части = путь.split(separator: "/", omittingEmptySubsequences: false)
    return части.count <= ПределыЦелостности.компоненты &&
        части.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." && $0.lowercased() != ".git" }
}

private func допустимаяСсылка(_ ссылка: String) -> Bool {
    let запрещено = CharacterSet(charactersIn: " ~^:?*[\\")
    return ссылка.hasPrefix("refs/") && ссылка.utf8.count <= 1_024 &&
        !ссылка.contains("..") && !ссылка.contains("@{") && !ссылка.hasSuffix(".") &&
        ссылка.utf8.elementsEqual(ссылка.precomposedStringWithCanonicalMapping.utf8) &&
        ссылка.unicodeScalars.allSatisfy { !запрещено.contains($0) && !CharacterSet.controlCharacters.contains($0) } &&
        ссылка.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
            !$0.isEmpty && !$0.hasPrefix(".") && !$0.hasSuffix(".lock")
        }
}

private indirect enum ЗначениеJSON: Sendable {
    case объект([String: ЗначениеJSON]), массив([ЗначениеJSON])
    case строка(String), число(String), логическое(Bool), пусто

    func объект(_ ключи: Set<String>) throws -> [String: ЗначениеJSON] {
        guard case let .объект(поля) = self else { throw ОтказЦелостности("формат") }
        guard Set(поля.keys) == ключи else { throw ОтказЦелостности("ключи") }
        return поля
    }
    func строка() throws -> String {
        guard case let .строка(значение) = self else { throw ОтказЦелостности("формат") }
        return значение
    }
    func целое() throws -> UInt64 {
        guard case let .число(текст) = self,
              текст.range(of: "^(0|[1-9][0-9]*)$", options: .regularExpression) != nil,
              let число = UInt64(текст) else { throw ОтказЦелостности("число") }
        return число
    }
}

private struct РазборJSON {
    let байты: [UInt8]
    var позиция = 0
    var узлы = 0

    mutating func пробелы() {
        while позиция < байты.count && [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
    }
    mutating func принять(_ байт: UInt8) -> Bool {
        пробелы()
        if позиция < байты.count && байты[позиция] == байт { позиция += 1; return true }
        return false
    }
    mutating func строка() throws -> String {
        пробелы()
        let начало = позиция
        guard позиция < байты.count && байты[позиция] == 34 else { throw ОтказЦелостности("формат") }
        позиция += 1
        var экранирование = false
        var закрыто = false
        while позиция < байты.count {
            let байт = байты[позиция]
            guard байт >= 32, позиция - начало <= 8_192 else { throw ОтказЦелостности("предел", 2) }
            позиция += 1
            if экранирование { экранирование = false }
            else if байт == 92 { экранирование = true }
            else if байт == 34 { закрыто = true; break }
        }
        guard закрыто, !экранирование else { throw ОтказЦелостности("формат") }
        let значение: String
        do { значение = try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция])) }
        catch { throw ОтказЦелостности("формат") }
        guard значение.utf8.count <= 4_096 else { throw ОтказЦелостности("предел", 2) }
        return значение
    }
    mutating func значение(_ глубина: Int) throws -> ЗначениеJSON {
        guard глубина <= ПределыЦелостности.глубина, узлы < 8_192 else { throw ОтказЦелостности("предел", 2) }
        узлы += 1
        пробелы()
        guard позиция < байты.count else { throw ОтказЦелостности("формат") }
        switch байты[позиция] {
        case 123:
            позиция += 1
            var поля: [String: ЗначениеJSON] = [:]
            if принять(125) { return .объект(поля) }
            while true {
                guard поля.count < 16 else { throw ОтказЦелостности("предел", 2) }
                let ключ = try строка()
                guard ключ.utf8.elementsEqual(ключ.precomposedStringWithCanonicalMapping.utf8),
                      поля[ключ] == nil else { throw ОтказЦелостности("ключи") }
                guard принять(58) else { throw ОтказЦелостности("формат") }
                поля[ключ] = try значение(глубина + 1)
                if принять(125) { return .объект(поля) }
                guard принять(44) else { throw ОтказЦелостности("формат") }
            }
        case 91:
            позиция += 1
            var элементы: [ЗначениеJSON] = []
            if принять(93) { return .массив(элементы) }
            while true {
                guard элементы.count < ПределыЦелостности.файлы else { throw ОтказЦелостности("предел", 2) }
                элементы.append(try значение(глубина + 1))
                if принять(93) { return .массив(элементы) }
                guard принять(44) else { throw ОтказЦелостности("формат") }
            }
        case 34: return .строка(try строка())
        case 116: try литерал("true"); return .логическое(true)
        case 102: try литерал("false"); return .логическое(false)
        case 110: try литерал("null"); return .пусто
        default:
            let начало = позиция
            while позиция < байты.count && Array("-0123456789.eE+".utf8).contains(байты[позиция]) { позиция += 1 }
            let текст = String(decoding: байты[начало..<позиция], as: UTF8.self)
            guard текст.range(of: "^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?$", options: .regularExpression) != nil else {
                throw ОтказЦелостности("формат")
            }
            return .число(текст)
        }
    }
    mutating func литерал(_ текст: String) throws {
        let образец = Array(текст.utf8)
        guard позиция + образец.count <= байты.count,
              байты[позиция..<(позиция + образец.count)].elementsEqual(образец) else { throw ОтказЦелостности("формат") }
        позиция += образец.count
    }
}

struct ПинGit: Sendable {
    let формат: String
    let коммит: String
    let дерево: String
    let ссылка: String
    var словарь: [String: Any] {
        ["формат_объектов": формат, "коммит": коммит, "дерево": дерево, "ссылка": ссылка]
    }
    fileprivate init(_ узел: ЗначениеJSON) throws {
        let поля = try узел.объект(["формат_объектов", "коммит", "дерево", "ссылка"])
        формат = try поля["формат_объектов"]!.строка()
        guard ["sha1", "sha256"].contains(формат) else { throw ОтказЦелостности("формат-объектов") }
        коммит = try поля["коммит"]!.строка()
        дерево = try поля["дерево"]!.строка()
        ссылка = try поля["ссылка"]!.строка()
        guard шестнадцатеричный(коммит, формат == "sha1" ? 40 : 64),
              шестнадцатеричный(дерево, формат == "sha1" ? 40 : 64),
              допустимаяСсылка(ссылка) else { throw ОтказЦелостности("пин") }
    }
}

struct ФайлМанифеста: Sendable {
    let путь: String
    let режим: String
    let объект: String
    let байты: UInt64
    let хэш: String
}

struct МанифестЦелостности: Sendable {
    let идентификатор: String
    let источник: ПинGit
    let покрытие: String
    let база: ПинGit?
    let файлы: [ФайлМанифеста]

    static func прочитать(_ данные: Data) throws -> Self {
        guard данные.count <= ПределыЦелостности.манифест else { throw ОтказЦелостности("предел", 2) }
        guard !данные.isEmpty, данные.last == 10, !данные.starts(with: [239, 187, 191]),
              String(data: данные, encoding: .utf8) != nil else { throw ОтказЦелостности("формат") }
        var разбор = РазборJSON(байты: Array(данные))
        let корень = try разбор.значение(1)
        разбор.пробелы()
        guard разбор.позиция == разбор.байты.count else { throw ОтказЦелостности("формат") }
        let поля = try корень.объект(["схема", "идентификатор", "источник", "покрытие", "база", "число_файлов", "файлы"])
        guard try поля["схема"]!.строка() == "fum.манифест-целостности-исходников.1" else { throw ОтказЦелостности("схема") }
        let идентификатор = try поля["идентификатор"]!.строка()
        guard UUID(uuidString: идентификатор)?.uuidString.lowercased() == идентификатор else { throw ОтказЦелостности("идентификатор") }
        let источник = try ПинGit(поля["источник"]!)
        let покрытие = try поля["покрытие"]!.строка()
        guard ["подмножество", "точный_состав_изменений"].contains(покрытие) else { throw ОтказЦелостности("покрытие") }
        let база: ПинGit?
        if case .пусто = поля["база"]! { база = nil } else { база = try ПинGit(поля["база"]!) }
        guard (покрытие == "подмножество" && база == nil) ||
              (покрытие == "точный_состав_изменений" && база?.формат == источник.формат) else { throw ОтказЦелостности("база") }
        guard case let .массив(массив) = поля["файлы"]!,
              try поля["число_файлов"]!.целое() == UInt64(массив.count),
              покрытие != "подмножество" || !массив.isEmpty else { throw ОтказЦелостности("состав") }
        var файлы: [ФайлМанифеста] = []
        var пути = Set<String>()
        var сумма: UInt64 = 0
        for узел in массив {
            let п = try узел.объект(["путь", "режим", "объект", "байты", "хэш"])
            let путь = try п["путь"]!.строка()
            guard допустимыйПуть(путь), пути.insert(путь).inserted else { throw ОтказЦелостности("путь") }
            let режим = try п["режим"]!.строка()
            guard ["100644", "100755"].contains(режим) else { throw ОтказЦелостности("режим") }
            let объект = try п["объект"]!.строка(), хэш = try п["хэш"]!.строка()
            guard шестнадцатеричный(объект, источник.формат == "sha1" ? 40 : 64),
                  шестнадцатеричный(хэш, 64) else { throw ОтказЦелостности("хэш-формат") }
            let байты = try п["байты"]!.целое()
            let (следующая, переполнение) = сумма.addingReportingOverflow(байты)
            guard !переполнение, байты <= UInt64(ПределыЦелостности.файл),
                  следующая <= UInt64(ПределыЦелостности.сумма) else { throw ОтказЦелостности("предел", 2) }
            сумма = следующая
            файлы.append(.init(путь: путь, режим: режим, объект: объект, байты: байты, хэш: хэш))
        }
        for путь in пути {
            let части = путь.split(separator: "/")
            if части.count > 1 {
                for число in 1..<части.count where пути.contains(части.prefix(число).joined(separator: "/")) {
                    throw ОтказЦелостности("путь")
                }
            }
        }
        return .init(идентификатор: идентификатор, источник: источник, покрытие: покрытие, база: база, файлы: файлы)
    }
}

func проверитьJSON(_ данные: Data) throws {
    _ = try МанифестЦелостности.прочитать(данные)
}
