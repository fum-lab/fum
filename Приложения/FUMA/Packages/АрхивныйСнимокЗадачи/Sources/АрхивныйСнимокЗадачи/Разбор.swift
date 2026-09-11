import Foundation

/// Проверяет неоднозначность ДО Foundation: повторные декодированные ключи,
/// глубину и число узлов. Не хранит значения строк диалога.
struct ПроверкаJSON {
    let байты: [UInt8]
    let бюджет: БюджетАрхива
    var позиция = 0
    var узлы = 0

    mutating func пробелы() {
        while позиция < байты.count && [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
    }
    mutating func символ(_ ожидаемый: UInt8) throws {
        пробелы()
        guard позиция < байты.count, байты[позиция] == ожидаемый else { throw ОшибкаАрхива.формат }
        позиция += 1
    }
    mutating func строка(_ ключ: Bool) throws -> String? {
        пробелы()
        let начало = позиция
        try символ(34)
        var закрыта = false
        while позиция < байты.count {
            let байт = байты[позиция]; позиция += 1
            if байт == 34 { закрыта = true; break }
            guard байт >= 32 else { throw ОшибкаАрхива.формат }
            if байт == 92 {
                guard позиция < байты.count else { throw ОшибкаАрхива.формат }
                позиция += 1
            }
        }
        guard закрыта else { throw ОшибкаАрхива.формат }
        if ключ {
            guard позиция - начало <= 4096 else { throw ОшибкаАрхива.предел }
            do { return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция])) }
            catch { throw ОшибкаАрхива.формат }
        }
        return nil
    }
    mutating func значение(_ глубина: Int) throws {
        узлы += 1
        guard глубина <= бюджет.глубина, узлы <= бюджет.узлыСтроки else { throw ОшибкаАрхива.предел }
        пробелы()
        guard позиция < байты.count else { throw ОшибкаАрхива.формат }
        switch байты[позиция] {
        case 123:
            позиция += 1; пробелы()
            var ключи = Set<String>()
            if позиция < байты.count, байты[позиция] == 125 { позиция += 1; return }
            while true {
                guard let ключ = try строка(true), ключи.insert(ключ).inserted else { throw ОшибкаАрхива.формат }
                guard ключи.count <= 4096 else { throw ОшибкаАрхива.предел }
                try символ(58); пробелы()
                let началоЗначения = позиция
                try значение(глубина + 1)
                if глубина == 1, ключ == "ordinal" {
                    // Проверяем исходную лексему до NSNumber: без Bool, Double и потери точности.
                    let цифры = байты[началоЗначения..<позиция]
                    guard !цифры.isEmpty, цифры.count <= 19,
                          цифры.count == 1 || цифры.first != 48,
                          цифры.allSatisfy({ (48...57).contains($0) }),
                          Int64(String(decoding: цифры, as: UTF8.self)) != nil else {
                        throw ОшибкаАрхива.формат
                    }
                }
                пробелы()
                guard позиция < байты.count else { throw ОшибкаАрхива.формат }
                if байты[позиция] == 125 { позиция += 1; break }
                try символ(44)
            }
        case 91:
            позиция += 1; пробелы()
            if позиция < байты.count, байты[позиция] == 93 { позиция += 1; return }
            while true {
                try значение(глубина + 1); пробелы()
                guard позиция < байты.count else { throw ОшибкаАрхива.формат }
                if байты[позиция] == 93 { позиция += 1; break }
                try символ(44)
            }
        case 34: _ = try строка(false)
        default:
            let начало = позиция
            while позиция < байты.count && ![9, 10, 13, 32, 44, 93, 125].contains(байты[позиция]) { позиция += 1 }
            guard позиция > начало else { throw ОшибкаАрхива.формат }
        }
    }
    mutating func проверить() throws {
        try значение(1); пробелы()
        guard позиция == байты.count else { throw ОшибкаАрхива.формат }
    }
}

func объектJSON(_ данные: Data, _ бюджет: БюджетАрхива) throws -> [String: Any] {
    guard String(data: данные, encoding: .utf8) != nil else { throw ОшибкаАрхива.формат }
    var проверка = ПроверкаJSON(байты: Array(данные), бюджет: бюджет)
    try проверка.проверить()
    do {
        guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any] else {
            throw ОшибкаАрхива.формат
        }
        return объект
    } catch let ошибка as ОшибкаАрхива { throw ошибка }
    catch { throw ОшибкаАрхива.формат }
}

func строковоеПоле(_ объект: [String: Any], _ имя: String, предел: Int = 1024) throws -> String? {
    guard let значение = объект[имя] else { return nil }
    guard let строка = значение as? String, !строка.isEmpty, строка.utf8.count <= предел,
          !строка.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }) else {
        throw ОшибкаАрхива.формат
    }
    return строка
}

struct ВыборФактов {
    var sessionMeta: ИдентичностьСессии?
    var каталогRuntime: ФактСтроки?
    var последнийХод: ФактСтроки?
    var модельХода: ФактСтроки?

    mutating func принять(_ данные: Data, позиция: ПозицияСтроки, uuid: String, бюджет: БюджетАрхива) throws {
        try autoreleasepool {
            let объект = try объектJSON(данные, бюджет)
            guard Set(объект.keys).isSubset(of: ["type", "timestamp", "payload", "ordinal", "metadata"]),
                  let тип = try строковоеПоле(объект, "type", предел: 128),
                  let поля = объект["payload"] as? [String: Any] else { throw ОшибкаАрхива.формат }
            _ = try строковоеПоле(объект, "timestamp", предел: 128)
            if let metadata = объект["metadata"], !(metadata is [String: Any]) { throw ОшибкаАрхива.формат }
            guard ["session_meta", "turn_context", "event_msg", "response_item", "compacted",
                   "world_state", "token_usage_record", "inter_agent_communication_metadata"].contains(тип) else {
                throw ОшибкаАрхива.формат
            }
            if тип == "session_meta" {
                guard sessionMeta == nil, позиция.номер == 1 else { throw ОшибкаАрхива.повторнаяИдентичность }
                guard let записанный = try строковоеПоле(поля, "id", предел: 36) else { throw ОшибкаАрхива.формат }
                try проверитьUUID(записанный)
                guard записанный == uuid else { throw ОшибкаАрхива.чужаяСессия }
                sessionMeta = ИдентичностьСессии(uuid: записанный, позиция: позиция)
                if let каталог = try строковоеПоле(поля, "cwd") { каталогRuntime = ФактСтроки(значение: каталог, позиция: позиция) }
            } else {
                guard sessionMeta != nil else { throw ОшибкаАрхива.формат }
            }
            // ordinal/metadata и три служебных типа входят только в байтовое происхождение.
            // Их payload не задаёт ход, модель, cwd, полномочия или живой статус.
            // Только turn_context и event_msg имеют поддержанную связь с ходом.
            // Любой явно указанный ход event_msg сменяет контекст, но не доказывает статус.
            if тип == "turn_context" || тип == "event_msg" {
                let ход = try строковоеПоле(поля, "turn_id", предел: 128)
                if тип == "turn_context", ход == nil { throw ОшибкаАрхива.формат }
                if let ход {
                    if последнийХод?.значение.utf8.elementsEqual(ход.utf8) != true { модельХода = nil }
                    последнийХод = ФактСтроки(значение: ход, позиция: позиция)
                }
                if тип == "turn_context" {
                    // Отсутствие model в новом turn_context не восполняется даже в том же ходе.
                    модельХода = try строковоеПоле(поля, "model", предел: 128).map { ФактСтроки(значение: $0, позиция: позиция) }
                    if let каталог = try строковоеПоле(поля, "cwd") { каталогRuntime = ФактСтроки(значение: каталог, позиция: позиция) }
                }
            }
        }
    }
}
