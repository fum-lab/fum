import Foundation

/// JSON TDLib сохраняет различие int53 (число) и int64 (строка).
public indirect enum ЗначениеДанных: Codable, Equatable, Sendable {
    case объект([String: ЗначениеДанных]), массив([ЗначениеДанных])
    case текст(String), число(Int64), дробь(Double), флаг(Bool), пусто

    public init(from средствоДекодирования: any Decoder) throws {
        let контейнер = try средствоДекодирования.singleValueContainer()
        if контейнер.decodeNil() { self = .пусто }
        else if let значение = try? контейнер.decode(Bool.self) { self = .флаг(значение) }
        else if let значение = try? контейнер.decode(Int64.self) { self = .число(значение) }
        else if let значение = try? контейнер.decode(Double.self) { self = .дробь(значение) }
        else if let значение = try? контейнер.decode(String.self) { self = .текст(значение) }
        else if let значение = try? контейнер.decode([ЗначениеДанных].self) { self = .массив(значение) }
        else { self = .объект(try контейнер.decode([String: ЗначениеДанных].self)) }
    }
    public func encode(to средствоКодирования: any Encoder) throws {
        var контейнер = средствоКодирования.singleValueContainer()
        switch self {
        case .объект(let значение): try контейнер.encode(значение)
        case .массив(let значение): try контейнер.encode(значение)
        case .текст(let значение): try контейнер.encode(значение)
        case .число(let значение): try контейнер.encode(значение)
        case .дробь(let значение): try контейнер.encode(значение)
        case .флаг(let значение): try контейнер.encode(значение)
        case .пусто: try контейнер.encodeNil()
        }
    }
    public subscript(_ ключ: String) -> ЗначениеДанных? {
        if case .объект(let поля) = self { return поля[ключ] }; return nil
    }
    public var строка: String? { if case .текст(let значение) = self { return значение }; return nil }
    public var целое: Int64? { if case .число(let значение) = self { return значение }; return nil }
    public var логическое: Bool? { if case .флаг(let значение) = self { return значение }; return nil }
    public var элементы: [ЗначениеДанных]? { if case .массив(let значение) = self { return значение }; return nil }
    public var поля: [String: ЗначениеДанных]? { if case .объект(let значение) = self { return значение }; return nil }
    public var тип: String? { self["@type"]?.строка }
    public static func типа(_ тип: String, _ поля: [String: ЗначениеДанных] = [:]) -> ЗначениеДанных {
        var результат = поля; результат["@type"] = .текст(тип); return .объект(результат)
    }
    public func добавив(_ ключ: String, _ значение: ЗначениеДанных) throws -> ЗначениеДанных {
        guard var поля else { throw ОшибкаКлиента.неверныеДанные("Ожидался объект") }
        поля[ключ] = значение; return .объект(поля)
    }
    public static func прочитать(_ данные: Data, предел: Int = 8 * 1024 * 1024) throws -> ЗначениеДанных {
        guard !данные.isEmpty, данные.count <= предел else { throw ОшибкаКлиента.превышенПредел }
        let значение: ЗначениеДанных
        do { значение = try JSONDecoder().decode(Self.self, from: данные) }
        catch { throw ОшибкаКлиента.неверныеДанные("Некорректный JSON") }
        guard значение.поля != nil else { throw ОшибкаКлиента.неверныеДанные("Ожидался объект TDLib") }
        return значение
    }
    public func байты() throws -> Data {
        let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try кодировщик.encode(self)
    }
}

func проверитьИдентификатор(_ число: Int64, положительный: Bool = false) throws {
    guard число != 0, число >= -9_007_199_254_740_991, число <= 9_007_199_254_740_991,
          !положительный || число > 0 else { throw ОшибкаКлиента.неверныеДанные("Идентификатор int53") }
}
