import Foundation

struct СтрокаJSONМиграции: Equatable, Sendable {
    var указатель: String
    var диапазон: Range<Int>
    var значение: String
}

struct РазборJSONМиграции: Sendable {
    var строки: [СтрокаJSONМиграции]
    var ключиОбъектов: [Data: Set<Data>]
}

enum ОтказJSONМиграции: Error, Equatable { case условие(String) }

struct СтатистикаJSONПроекции: Equatable, Sendable {
    var байты: Int
    var узлы: Int
    var объекты: Int
    var глубина: Int
}

enum СинтаксисБольшогоМанифестаПроекции {
    static func проверить(_ данные: Data, приЗакрытииОбъекта: @escaping (String, Set<Data>) throws -> Void = { _, _ in }) throws -> СтатистикаJSONПроекции {
        guard данные.count <= 33_554_432 else { throw ОтказJSONМиграции.условие("предел-байтов-большого-манифеста") }
        var сканер = СканерСтрокJSONМиграции(байты: Array(данные), пределУзлов: 2_000_000, сохранятьДанные: false, наблюдатьКлючи: приЗакрытииОбъекта)
        try сканер.значение("", глубина: 0); сканер.пробелы()
        guard сканер.позиция == сканер.байты.count else { throw ОтказJSONМиграции.условие("остаток-JSON") }
        return .init(байты: данные.count, узлы: сканер.числоУзлов, объекты: сканер.числоОбъектов, глубина: сканер.максимальнаяГлубина)
    }
}

enum ТокеныJSONМиграции {
    static func разобрать(_ данные: Data) throws -> РазборJSONМиграции {
        guard данные.count <= 4_194_304 else { throw ОтказJSONМиграции.условие("предел-байтов") }
        var сканер = СканерСтрокJSONМиграции(байты: Array(данные))
        try сканер.значение("", глубина: 0); сканер.пробелы()
        guard сканер.позиция == сканер.байты.count else { throw ОтказJSONМиграции.условие("остаток-JSON") }
        return .init(строки: сканер.строки, ключиОбъектов: сканер.ключиОбъектов)
    }
}

// Отдельный ограниченный профиль для lossless-правок. ЗакрытыйJSON памяти
// сохраняет свой прежний лимит. Лексическая основа сверена с существующим
// JSONDuplicateKeyDetector из WorkPackageContract.swift (fd31afa3e42e4b49a97086e8cb066a5af3665f6fc9f6dfa2817b64b5701707dd).
private struct СканерСтрокJSONМиграции {
    let байты: [UInt8]
    var позиция = 0
    var числоУзлов = 0
    var строки: [СтрокаJSONМиграции] = []
    var ключиОбъектов: [Data: Set<Data>] = [:]
    var пределУзлов = 100_000
    var сохранятьДанные = true
    var наблюдатьКлючи: ((String, Set<Data>) throws -> Void)? = nil
    var числоОбъектов = 0
    var максимальнаяГлубина = 0

    mutating func пробелы() {
        while позиция < байты.count && [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
    }
    mutating func принять(_ знак: UInt8) -> Bool {
        guard позиция < байты.count, байты[позиция] == знак else { return false }
        позиция += 1; return true
    }
    mutating func требовать(_ знак: UInt8) throws {
        guard принять(знак) else { throw ОтказJSONМиграции.условие("неверный-JSON") }
    }
    func указатель(_ родитель: String, _ ключ: String) -> String {
        родитель + "/" + ключ.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
    }
    mutating func строка() throws -> (String, Range<Int>) {
        let начало = позиция
        try требовать(34)
        while позиция < байты.count {
            let знак = байты[позиция]; позиция += 1
            if знак == 34 {
                let диапазон = начало..<позиция
                guard let значение = try? JSONDecoder().decode(String.self, from: Data(байты[диапазон])) else { throw ОтказJSONМиграции.условие("неверная-строка-JSON") }
                return (значение, диапазон)
            }
            guard знак >= 32 else { throw ОтказJSONМиграции.условие("управляющий-знак-JSON") }
            if знак == 92 {
                guard позиция < байты.count else { throw ОтказJSONМиграции.условие("оборванная-строка-JSON") }
                позиция += 1
            }
        }
        throw ОтказJSONМиграции.условие("незакрытая-строка-JSON")
    }
    mutating func значение(_ путь: String, глубина: Int) throws {
        guard глубина <= 64, числоУзлов < пределУзлов else { throw ОтказJSONМиграции.условие("предел-структуры") }
        максимальнаяГлубина = max(максимальнаяГлубина, глубина)
        числоУзлов += 1; пробелы()
        guard позиция < байты.count else { throw ОтказJSONМиграции.условие("оборванный-JSON") }
        switch байты[позиция] {
        case 123:
            позиция += 1; пробелы(); var ключи: Set<Data> = []
            if принять(125) { try закончитьОбъект(путь, ключи); return }
            while true {
                пробелы(); let (ключ, _) = try строка()
                guard ключи.insert(Data(ключ.utf8)).inserted else { throw ОтказJSONМиграции.условие("повтор-поля: " + указатель(путь, ключ)) }
                пробелы(); try требовать(58); try значение(указатель(путь, ключ), глубина: глубина + 1); пробелы()
                if принять(125) { break }; try требовать(44)
            }
            try закончитьОбъект(путь, ключи)
        case 91:
            позиция += 1; пробелы(); if принять(93) { return }
            var номер = 0
            while true {
                try значение(путь + "/\(номер)", глубина: глубина + 1); номер += 1; пробелы()
                if принять(93) { break }; try требовать(44)
            }
        case 34:
            let (значение, диапазон) = try строка()
            if сохранятьДанные { строки.append(.init(указатель: путь, диапазон: диапазон, значение: значение)) }
        default:
            let начало = позиция
            while позиция < байты.count && ![9, 10, 13, 32, 44, 93, 125].contains(байты[позиция]) { позиция += 1 }
            guard позиция > начало,
                  (try? JSONSerialization.jsonObject(with: Data(байты[начало..<позиция]), options: [.fragmentsAllowed])) != nil else {
                throw ОтказJSONМиграции.условие("неверное-значение-JSON")
            }
        }
    }

    mutating func закончитьОбъект(_ путь: String, _ ключи: Set<Data>) throws {
        числоОбъектов += 1
        if сохранятьДанные { ключиОбъектов[Data(путь.utf8)] = ключи }
        try наблюдатьКлючи?(путь, ключи)
    }
}
