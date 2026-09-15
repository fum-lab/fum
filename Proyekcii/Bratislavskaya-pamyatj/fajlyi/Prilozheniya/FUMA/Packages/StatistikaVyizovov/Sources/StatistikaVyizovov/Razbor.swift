import Foundation
import CryptoKit

func проверитьЗадачу(_ задача: String) throws {
    guard задача.utf8.count == 36, let значение = UUID(uuidString: задача),
          Array(значение.uuidString.lowercased().utf8) == Array(задача.utf8) else {
        throw ОшибкаСтатистики.идентичность
    }
}
func хэшБайтов(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
func текстХэша(_ значение: SHA256.Digest) -> String {
    значение.map { String(format: "%02x", $0) }.joined()
}
func допустимыйТокен(_ значение: Any?) -> String? {
    guard let текст = значение as? String, !текст.isEmpty, текст.utf8.count <= 256,
          текст.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) ||
              (48...57).contains($0) || [95, 46, 58, 47, 45].contains($0) }) else { return nil }
    return текст
}
func наблюдённоеВремя(_ значение: Any?) -> НаблюдённыйМомент {
    guard let значение, !(значение is NSNull) else {
        return НаблюдённыйМомент(качество: .отсутствует, наносекундыОтЭпохи: nil)
    }
    let неверно = НаблюдённыйМомент(качество: .неверно, наносекундыОтЭпохи: nil)
    guard let текст = значение as? String, (20...30).contains(текст.utf8.count) else { return неверно }
    let байты = Array(текст.utf8)
    guard байты[4] == 45, байты[7] == 45, байты[10] == 84, байты[13] == 58,
          байты[16] == 58, байты.last == 90 else { return неверно }
    func число(_ от: Int, _ до: Int) -> Int? {
        let часть = байты[от..<до]
        guard часть.allSatisfy({ (48...57).contains($0) }) else { return nil }
        return часть.reduce(0) { $0 * 10 + Int($1 - 48) }
    }
    guard let год = число(0, 4), (1970...2100).contains(год), let месяц = число(5, 7),
          let день = число(8, 10), let час = число(11, 13), let минута = число(14, 16),
          let секунда = число(17, 19), (1...12).contains(месяц), (1...31).contains(день),
          (0...23).contains(час), (0...59).contains(минута), (0...59).contains(секунда) else { return неверно }
    var доля = 0
    if байты.count != 20 {
        guard байты.count >= 22, байты[19] == 46, let значениеДоли = число(20, байты.count - 1) else { return неверно }
        доля = значениеДоли
        for _ in (байты.count - 21)..<9 { доля *= 10 }
    }
    var календарь = Calendar(identifier: .gregorian)
    календарь.timeZone = TimeZone(secondsFromGMT: 0)!
    let компоненты = DateComponents(year: год, month: месяц, day: день, hour: час, minute: минута, second: секунда)
    guard let дата = календарь.date(from: компоненты) else { return неверно }
    let обратно = календарь.dateComponents([.year, .month, .day, .hour, .minute, .second], from: дата)
    guard обратно.year == год, обратно.month == месяц, обратно.day == день,
          обратно.hour == час, обратно.minute == минута, обратно.second == секунда else { return неверно }
    let эпоха = Int64(дата.timeIntervalSince1970) * 1_000_000_000 + Int64(доля)
    return НаблюдённыйМомент(качество: .известно, наносекундыОтЭпохи: эпоха)
}

/// До Foundation ограничивает глубину и ключи и отклоняет дубли после JSON-unescape.
/// Значения аргументов не извлекаются этим проходом; полный синтаксис проверит Foundation.
struct ПроверкаКлючей {
    let байты: [UInt8]
    var пределКлючей = БюджетСтатистики.ключи
    var позиция = 0
    var числоКлючей = 0
    mutating func пробелы() {
        while позиция < байты.count, [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
    }
    mutating func строка() throws -> Range<Int> {
        guard позиция < байты.count, байты[позиция] == 34 else { throw ОшибкаСтатистики.формат }
        let начало = позиция
        позиция += 1
        while позиция < байты.count {
            let байт = байты[позиция]
            позиция += 1
            if байт == 34 { return начало..<позиция }
            if байт == 92 { позиция += 1 }
        }
        throw ОшибкаСтатистики.формат
    }
    mutating func значение(_ глубина: Int = 0) throws {
        guard глубина <= БюджетСтатистики.глубина else { throw ОшибкаСтатистики.предел }
        пробелы()
        guard позиция < байты.count else { throw ОшибкаСтатистики.формат }
        if байты[позиция] == 34 { _ = try строка(); return }
        if байты[позиция] == 123 {
            позиция += 1
            var ключи: Set<String> = []
            пробелы()
            if позиция < байты.count, байты[позиция] == 125 { позиция += 1; return }
            while true {
                пробелы()
                let диапазон = try строка()
                guard диапазон.count <= 4096 else { throw ОшибкаСтатистики.предел }
                числоКлючей += 1
                guard числоКлючей <= пределКлючей else { throw ОшибкаСтатистики.предел }
                let ключ: String
                do { ключ = try JSONDecoder().decode(String.self, from: Data(байты[диапазон])) }
                catch { throw ОшибкаСтатистики.формат }
                guard ключи.insert(ключ).inserted else { throw ОшибкаСтатистики.формат }
                пробелы()
                guard позиция < байты.count, байты[позиция] == 58 else { throw ОшибкаСтатистики.формат }
                позиция += 1
                try значение(глубина + 1)
                пробелы()
                guard позиция < байты.count else { throw ОшибкаСтатистики.формат }
                if байты[позиция] == 125 { позиция += 1; return }
                guard байты[позиция] == 44 else { throw ОшибкаСтатистики.формат }
                позиция += 1
            }
        }
        if байты[позиция] == 91 {
            позиция += 1
            пробелы()
            if позиция < байты.count, байты[позиция] == 93 { позиция += 1; return }
            while true {
                try значение(глубина + 1)
                пробелы()
                guard позиция < байты.count else { throw ОшибкаСтатистики.формат }
                if байты[позиция] == 93 { позиция += 1; return }
                guard байты[позиция] == 44 else { throw ОшибкаСтатистики.формат }
                позиция += 1
            }
        }
        let начало = позиция
        while позиция < байты.count, ![9, 10, 13, 32, 44, 93, 125].contains(байты[позиция]) { позиция += 1 }
        guard позиция > начало else { throw ОшибкаСтатистики.формат }
    }
}
func объектСтроки(_ данные: Data) throws -> [String: Any] {
    guard данные.count <= БюджетСтатистики.строка, String(data: данные, encoding: .utf8) != nil else {
        throw ОшибкаСтатистики.формат
    }
    var проверка = ПроверкаКлючей(байты: Array(данные))
    try проверка.значение()
    проверка.пробелы()
    guard проверка.позиция == данные.count else { throw ОшибкаСтатистики.формат }
    do {
        guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any] else {
            throw ОшибкаСтатистики.формат
        }
        return объект
    } catch { throw ОшибкаСтатистики.формат }
}
func событиеСтроки(_ объект: [String: Any], происхождение: ПроисхождениеСтроки) throws -> СобытиеВызова? {
    guard let тип = объект["type"] as? String else { throw ОшибкаСтатистики.формат }
    guard тип == "response_item" else { return nil }
    guard let данные = объект["payload"] as? [String: Any] else { throw ОшибкаСтатистики.формат }
    let направление: НаправлениеСобытия
    let семейство: СемействоСобытия
    switch данные["type"] as? String {
    case "function_call": направление = .вызов; семейство = .функция
    case "custom_tool_call": направление = .вызов; семейство = .произвольный
    case "function_call_output": направление = .результат; семейство = .функция
    case "custom_tool_call_output": направление = .результат; семейство = .произвольный
    default: return nil
    }
    return СобытиеВызова(направление: направление, семейство: семейство,
        идентификатор: допустимыйТокен(данные["call_id"]),
        инструмент: направление == .вызов ? допустимыйТокен(данные["name"]) : nil,
        момент: наблюдённоеВремя(объект["timestamp"]), происхождение: происхождение)
}
