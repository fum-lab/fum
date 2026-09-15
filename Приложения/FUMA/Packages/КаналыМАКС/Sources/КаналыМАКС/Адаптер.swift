import Foundation

public enum ОшибкаВхода: Error, Equatable {
    case пустойТекст, длинныйТекст, неверныйАдрес, неверноеВремя, неизвестнаяПубликация, повторИдентификатора
}

/// Описание HTTP-запроса без секрета. Авторизацию добавляет будущий платформенный транспорт.
public struct ПодготовленныйЗапрос: Sendable {
    public let адрес: URL
    public let метод: String
    public let заголовки: [String: String]
    public let тело: Data
    public let требуетАвторизации = true

    public static func публикация(канал: Int64, текст: String) throws -> Self {
        guard !текст.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ОшибкаВхода.пустойТекст }
        guard текст.unicodeScalars.count <= 4000 else { throw ОшибкаВхода.длинныйТекст }
        return try собрать(путь: "/messages", параметры: [URLQueryItem(name: "chat_id", value: String(канал))], тело: ["text": текст, "notify": true])
    }

    public static func подписка(адрес: String) throws -> Self {
        guard let компоненты = URLComponents(string: адрес), компоненты.scheme == "https",
              let хост = компоненты.host, !хост.isEmpty, компоненты.port == nil,
              компоненты.user == nil, компоненты.password == nil, компоненты.fragment == nil,
              компоненты.url != nil else { throw ОшибкаВхода.неверныйАдрес }
        return try собрать(путь: "/subscriptions", параметры: [], тело: [
            "url": адрес, "update_types": ["bot_added", "bot_removed", "chat_title_changed"]
        ])
    }

    private static func собрать(путь: String, параметры: [URLQueryItem], тело: [String: Any]) throws -> Self {
        var компоненты = URLComponents()
        компоненты.scheme = "https"
        компоненты.host = "platform-api2.max.ru"
        компоненты.path = путь
        if !параметры.isEmpty { компоненты.queryItems = параметры }
        guard let адрес = компоненты.url else { throw ОшибкаВхода.неверныйАдрес }
        return Self(адрес: адрес, метод: "POST", заголовки: ["Content-Type": "application/json"],
                    тело: try JSONSerialization.data(withJSONObject: тело, options: [.sortedKeys]))
    }
}

public enum ОтветТранспорта: Sendable {
    case ответ(код: Int, тело: Data)
    /// Тайм-аут, разрыв связи или иной исход, при котором принятие сервером неизвестно.
    case неизвестно
}

public protocol ТранспортКаналов: Sendable {
    func выполнить(_ запрос: ПодготовленныйЗапрос) async -> ОтветТранспорта
}

public enum СостояниеПубликации: Equatable, Sendable {
    case подготовлено, отправлено, подтверждено(String), неизвестно, отказАвторизации, отклонено(Int)
}

/// Скользящее окно в одну секунду; время задаёт один монотонный источник вызывающего слоя.
/// Экземпляр общий для одного бота, включая все его каналы и прочие вызовы API.
public struct ОграничительЧастоты: Sendable {
    private var принятые: [(время: Double, канал: Int64?)] = []
    private var последнееВремя: Double = 0
    public init() {}

    public mutating func допустить(канал: Int64?, время: Double) throws -> Bool {
        guard время.isFinite, время >= последнееВремя, время >= 0 else { throw ОшибкаВхода.неверноеВремя }
        последнееВремя = время
        принятые.removeAll { время - $0.время >= 1 }
        guard принятые.count < 30 else { return false }
        if let канал, принятые.filter({ $0.канал == канал }).count >= 2 { return false }
        принятые.append((время, канал))
        return true
    }
}

public actor АдаптерКаналов {
    private struct Публикация {
        let канал: Int64
        let запрос: ПодготовленныйЗапрос
        var история: [СостояниеПубликации]
    }
    private let транспорт: any ТранспортКаналов
    private var публикации: [String: Публикация] = [:]
    private var ограничитель = ОграничительЧастоты()

    public init(транспорт: any ТранспортКаналов) { self.транспорт = транспорт }

    public func подготовить(идентификатор: String, канал: Int64, текст: String) throws {
        guard !идентификатор.isEmpty, публикации[идентификатор] == nil else { throw ОшибкаВхода.повторИдентификатора }
        публикации[идентификатор] = try Публикация(канал: канал,
            запрос: .публикация(канал: канал, текст: текст), история: [.подготовлено])
    }

    public func история(_ идентификатор: String) -> [СостояниеПубликации] { публикации[идентификатор]?.история ?? [] }

    /// Один вызов транспорта на идентификатор, включая повторный вход во время await.
    /// Отправлено означает передачу транспорту, а не доставку серверу или читателю канала.
    public func отправить(_ идентификатор: String, время: Double) async throws -> СостояниеПубликации {
        guard let публикация = публикации[идентификатор], let состояние = публикация.история.last else {
            throw ОшибкаВхода.неизвестнаяПубликация
        }
        guard состояние == .подготовлено else { return состояние }
        guard try ограничитель.допустить(канал: публикация.канал, время: время) else { return .подготовлено }
        публикации[идентификатор]?.история.append(.отправлено)
        let ответ = await транспорт.выполнить(публикация.запрос)
        let итог = Self.разобрать(ответ, канал: публикация.канал)
        публикации[идентификатор]?.история.append(итог)
        return итог
    }

    private static func разобрать(_ ответ: ОтветТранспорта, канал: Int64) -> СостояниеПубликации {
        switch ответ {
        case .неизвестно: return .неизвестно
        case let .ответ(код, тело):
            if код == 401 || код == 403 { return .отказАвторизации }
            if (400..<500).contains(код) { return .отклонено(код) }
            guard код == 200,
                  let ответ = try? JSONDecoder().decode(Подтверждение.self, from: тело),
                  ответ.сообщение.получатель.канал == канал,
                  !ответ.сообщение.тело.идентификатор.isEmpty else { return .неизвестно }
            return .подтверждено(ответ.сообщение.тело.идентификатор)
        }
    }
}

private struct Подтверждение: Decodable {
    let сообщение: Сообщение
    enum CodingKeys: String, CodingKey { case сообщение = "message" }
    struct Сообщение: Decodable {
        let получатель: Получатель
        let тело: Тело
        enum CodingKeys: String, CodingKey { case получатель = "recipient", тело = "body" }
    }
    struct Получатель: Decodable {
        let канал: Int64
        enum CodingKeys: String, CodingKey { case канал = "chat_id" }
    }
    struct Тело: Decodable {
        let идентификатор: String
        enum CodingKeys: String, CodingKey { case идентификатор = "mid" }
    }
}

public struct СобытиеКанала: Decodable, Sendable {
    public let тип: String
    public let время: Int64
    public let канал: Int64?
    public let этоКанал: Bool?
    public let название: String?
    enum CodingKeys: String, CodingKey {
        case тип = "update_type", время = "timestamp", канал = "chat_id", этоКанал = "is_channel", название = "title"
    }
}

public struct СостояниеКанала: Sendable {
    public var подключён: Bool
    public var название: String?
    public var время: Int64
    public let правоПубликацииПодтверждено = false
}

public enum ИсходСобытия: Equatable {
    case применено, повтор, пропущено, устарело, неизвестныйТип(String)
}

/// Локальная ограниченная дедупликация по каноническим байтам всего JSON.
/// После вытеснения или перезапуска повтор может вернуться; внешних эффектов обработчик не создаёт.
public struct РеестрКаналов {
    public private(set) var каналы: [Int64: СостояниеКанала] = [:]
    private let ёмкость: Int
    private var очередь: [Data] = []
    private var известные: Set<Data> = []
    public init(ёмкость: Int = 1024) { self.ёмкость = max(1, ёмкость) }

    public mutating func принять(_ данные: Data) throws -> ИсходСобытия {
        let событие = try JSONDecoder().decode(СобытиеКанала.self, from: данные)
        let объект = try JSONSerialization.jsonObject(with: данные)
        let ключ = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
        if известные.contains(ключ) { return .повтор }
        let исход = try применить(событие)
        if очередь.count == ёмкость { известные.remove(очередь.removeFirst()) }
        очередь.append(ключ)
        известные.insert(ключ)
        return исход
    }

    private mutating func применить(_ событие: СобытиеКанала) throws -> ИсходСобытия {
        guard ["bot_added", "bot_removed", "chat_title_changed"].contains(событие.тип) else {
            return .неизвестныйТип(событие.тип)
        }
        guard let канал = событие.канал, событие.время >= 0 else { throw ОшибкаВхода.неверноеВремя }
        if let прежний = каналы[канал], событие.время < прежний.время { return .устарело }
        switch событие.тип {
        case "bot_added":
            guard let этоКанал = событие.этоКанал else { throw ОшибкаВхода.неверныйАдрес }
            guard этоКанал else { return .пропущено }
            каналы[канал] = СостояниеКанала(подключён: true, название: каналы[канал]?.название, время: событие.время)
        case "bot_removed":
            guard каналы[канал] != nil else { return .пропущено }
            каналы[канал]?.подключён = false
            каналы[канал]?.время = событие.время
        default:
            guard let название = событие.название else { throw ОшибкаВхода.пустойТекст }
            guard каналы[канал] != nil else { return .пропущено }
            каналы[канал]?.название = название
            каналы[канал]?.время = событие.время
        }
        return .применено
    }
}
