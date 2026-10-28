import Foundation

enum ПроверкаЗакрытогоJSON {
    static func проверитьБезПовторов(_ данные: Data) throws {
        do {
            var разбор = try РазборJSON(данные)
            try разбор.проверить()
        } catch let отказ as ОтказМаршрутаПравил {
            throw отказ
        } catch {
            throw ОтказМаршрутаПравил(.инвентарь, "Некорректный закрытый JSON: \(error)")
        }
    }
}

private struct РазборJSON {
    private let байты: [UInt8]
    private var позиция = 0
    private var узлов = 0

    init(_ данные: Data) throws {
        guard данные.count <= 4_194_304,
              String(data: данные, encoding: .utf8) != nil else {
            throw ОтказМаршрутаПравил(.инвентарь, "Инвентарь превышает предел или не UTF-8")
        }
        байты = Array(данные)
    }

    mutating func проверить() throws {
        try значение(глубина: 0)
        пробелы()
        guard позиция == байты.count else { throw ошибка("Лишние байты после JSON") }
    }

    private mutating func значение(глубина: Int) throws {
        guard глубина <= 64, узлов < 100_000 else {
            throw ошибка("Превышен предел структуры JSON")
        }
        узлов += 1
        пробелы()
        guard позиция < байты.count else { throw ошибка("Неожиданный конец JSON") }
        switch байты[позиция] {
        case 123: try объект(глубина: глубина)
        case 91: try массив(глубина: глубина)
        case 34: _ = try строка()
        case 45, 48...57: try число()
        case 116: try литерал("true")
        case 102: try литерал("false")
        case 110: try литерал("null")
        default: throw ошибка("Неизвестное JSON-значение")
        }
    }

    private mutating func объект(глубина: Int) throws {
        guard принять(123) else { throw ошибка("Ожидался объект") }
        пробелы()
        if принять(125) { return }
        var ключи: Set<String> = []
        while true {
            пробелы()
            let ключ = try строка()
            guard ключи.insert(ключ).inserted else {
                throw ОтказМаршрутаПравил(.инвентарь, "Повтор ключа JSON \(ключ)")
            }
            пробелы()
            guard принять(58) else { throw ошибка("После ключа требуется двоеточие") }
            try значение(глубина: глубина + 1)
            пробелы()
            if принять(125) { return }
            guard принять(44) else { throw ошибка("Ожидалась запятая объекта") }
        }
    }

    private mutating func массив(глубина: Int) throws {
        guard принять(91) else { throw ошибка("Ожидался массив") }
        пробелы()
        if принять(93) { return }
        while true {
            try значение(глубина: глубина + 1)
            пробелы()
            if принять(93) { return }
            guard принять(44) else { throw ошибка("Ожидалась запятая массива") }
        }
    }

    private mutating func строка() throws -> String {
        let начало = позиция
        guard принять(34) else { throw ошибка("Ожидалась строка") }
        while позиция < байты.count {
            let байт = байты[позиция]
            позиция += 1
            if байт == 34 {
                do {
                    return try JSONDecoder().decode(
                        String.self, from: Data(байты[начало..<позиция]))
                } catch {
                    throw self.ошибка("Некорректная JSON-строка")
                }
            }
            guard байт >= 32 else { throw ошибка("Управляющий байт в JSON-строке") }
            if байт == 92 {
                guard позиция < байты.count else { throw ошибка("Оборванное экранирование") }
                let escaped = байты[позиция]
                позиция += 1
                guard [34, 47, 92, 98, 102, 110, 114, 116, 117].contains(escaped) else {
                    throw ошибка("Неизвестное экранирование JSON")
                }
                if escaped == 117 {
                    guard позиция + 4 <= байты.count,
                          байты[позиция..<(позиция + 4)].allSatisfy({
                              (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
                          }) else { throw ошибка("Некорректное Unicode-экранирование") }
                    позиция += 4
                }
            }
        }
        throw ошибка("Оборванная JSON-строка")
    }

    private mutating func число() throws {
        _ = принять(45)
        guard позиция < байты.count else { throw ошибка("Оборванное число") }
        if !принять(48) {
            guard (49...57).contains(байты[позиция]) else { throw ошибка("Некорректное число") }
            позиция += 1
            while позиция < байты.count, (48...57).contains(байты[позиция]) { позиция += 1 }
        }
        if принять(46) {
            let начало = позиция
            while позиция < байты.count, (48...57).contains(байты[позиция]) { позиция += 1 }
            guard позиция > начало else { throw ошибка("Пустая дробная часть") }
        }
        if позиция < байты.count, байты[позиция] == 69 || байты[позиция] == 101 {
            позиция += 1
            if позиция < байты.count, байты[позиция] == 43 || байты[позиция] == 45 {
                позиция += 1
            }
            let начало = позиция
            while позиция < байты.count, (48...57).contains(байты[позиция]) { позиция += 1 }
            guard позиция > начало else { throw ошибка("Пустая экспонента") }
        }
    }

    private mutating func литерал(_ значение: String) throws {
        let ожидаемые = Array(значение.utf8)
        guard байты[позиция...].starts(with: ожидаемые) else {
            throw ошибка("Некорректный JSON-литерал")
        }
        позиция += ожидаемые.count
    }

    private mutating func пробелы() {
        while позиция < байты.count, [9, 10, 13, 32].contains(байты[позиция]) {
            позиция += 1
        }
    }

    private mutating func принять(_ байт: UInt8) -> Bool {
        guard позиция < байты.count, байты[позиция] == байт else { return false }
        позиция += 1
        return true
    }

    private func ошибка(_ пояснение: String) -> ОтказМаршрутаПравил {
        ОтказМаршрутаПравил(.инвентарь, "\(пояснение), байт \(позиция)")
    }
}
