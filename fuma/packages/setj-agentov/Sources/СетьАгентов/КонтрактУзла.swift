import Foundation

public enum Знание<Value>: Codable, Equatable, Sendable where Value: Codable & Equatable & Sendable {
    case известно(Value)
    case неизвестно(причина: String)

    private enum Ключи: String, CodingKey { case состояние, значение, причина }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Ключи.self)
        switch try container.decode(String.self, forKey: .состояние) {
        case "известно":
            self = .известно(try container.decode(Value.self, forKey: .значение))
        case "неизвестно":
            let причина = try container.decode(String.self, forKey: .причина)
            guard !причина.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .причина, in: container, debugDescription: "Причина UNKNOWN не может быть пустой")
            }
            self = .неизвестно(причина: причина)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .состояние, in: container, debugDescription: "Неизвестное состояние знания")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Ключи.self)
        switch self {
        case .известно(let значение):
            try container.encode("известно", forKey: .состояние)
            try container.encode(значение, forKey: .значение)
        case .неизвестно(let причина):
            guard !причина.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw EncodingError.invalidValue(
                    причина, .init(codingPath: encoder.codingPath, debugDescription: "Причина UNKNOWN не может быть пустой"))
            }
            try container.encode("неизвестно", forKey: .состояние)
            try container.encode(причина, forKey: .причина)
        }
    }
}

public enum ДействиеУзла: String, Codable, CaseIterable, Sendable {
    case start, resume, drain, checkpoint
}

public enum ФазаУзла: String, Codable, Sendable {
    case остановлен, готов, работает, приостанавливается, завершает
}

public struct СостояниеУзла: Codable, Equatable, Sendable {
    public let фаза: Знание<ФазаУзла>
    public let версия: Знание<UInt64>
    public let параллелизм: Знание<Int>
    public let активныеРаботы: Знание<Int>
    public let последнийПереход: Знание<Date>

    public init(фаза: Знание<ФазаУзла>, версия: Знание<UInt64>, параллелизм: Знание<Int>,
        активныеРаботы: Знание<Int>, последнийПереход: Знание<Date>) {
        self.фаза = фаза
        self.версия = версия
        self.параллелизм = параллелизм
        self.активныеРаботы = активныеРаботы
        self.последнийПереход = последнийПереход
    }
}

public struct БюджетРесурсовУзла: Codable, Equatable, Sendable {
    public let свободныйCPUMilliCores: Знание<UInt64>
    public let свободнаяПамятьБайт: Знание<UInt64>
    public let максимумПараллелизма: Знание<Int>

    public init(свободныйCPUMilliCores: Знание<UInt64>, свободнаяПамятьБайт: Знание<UInt64>,
        максимумПараллелизма: Знание<Int>) {
        self.свободныйCPUMilliCores = свободныйCPUMilliCores
        self.свободнаяПамятьБайт = свободнаяПамятьБайт
        self.максимумПараллелизма = максимумПараллелизма
    }
}

public struct СигналыРаботыУзла: Codable, Equatable, Sendable {
    public let независимыеГотовыеЗадачи: Знание<Int>
    public let полезныеПринятыеРезультаты: Знание<Int>
    public let сбои: Знание<Int>
    public let повторнаяРабота: Знание<Int>
    public let p95ЗадержкиМиллисекунды: Знание<UInt64>
    public let затратыЕдиниц: Знание<UInt64>
    public let нетРаботыС: Знание<Date>

    public init(независимыеГотовыеЗадачи: Знание<Int>, полезныеПринятыеРезультаты: Знание<Int>,
        сбои: Знание<Int>, повторнаяРабота: Знание<Int>, p95ЗадержкиМиллисекунды: Знание<UInt64>,
        затратыЕдиниц: Знание<UInt64>, нетРаботыС: Знание<Date>) {
        self.независимыеГотовыеЗадачи = независимыеГотовыеЗадачи
        self.полезныеПринятыеРезультаты = полезныеПринятыеРезультаты
        self.сбои = сбои
        self.повторнаяРабота = повторнаяРабота
        self.p95ЗадержкиМиллисекунды = p95ЗадержкиМиллисекунды
        self.затратыЕдиниц = затратыЕдиниц
        self.нетРаботыС = нетРаботыС
    }
}

public struct КонтекстПорученияУзла: Codable, Equatable, Sendable {
    public let id: UUID
    public let владелецРодителя: String
    public let владелец: String
    public let цель: String
    public let разрешённыеПути: [String]
    public let исходнаяСсылка: String
    public let исходныйКоммит: String
    public let исходноеДерево: String
    public let путьМанифеста: String
    public let sha256Манифеста: Знание<String>
    public let ожидаемыйRemote: String
    public let ожидаемыйOIDRemote: Знание<String>
    public let обязательныеПути: [String]
    public let свидетельствоГранта: Знание<String>
    public let грантДействуетДо: Date
    public let ожидаемаяВерсияСостояния: Знание<UInt64>

    public init(id: UUID, владелецРодителя: String, владелец: String, цель: String,
        разрешённыеПути: [String], исходнаяСсылка: String, исходныйКоммит: String, исходноеДерево: String,
        путьМанифеста: String, sha256Манифеста: Знание<String>, ожидаемыйRemote: String,
        ожидаемыйOIDRemote: Знание<String>, обязательныеПути: [String], свидетельствоГранта: Знание<String>,
        грантДействуетДо: Date, ожидаемаяВерсияСостояния: Знание<UInt64>) {
        self.id = id
        self.владелецРодителя = владелецРодителя
        self.владелец = владелец
        self.цель = цель
        self.разрешённыеПути = разрешённыеПути
        self.исходнаяСсылка = исходнаяСсылка
        self.исходныйКоммит = исходныйКоммит
        self.исходноеДерево = исходноеДерево
        self.путьМанифеста = путьМанифеста
        self.sha256Манифеста = sha256Манифеста
        self.ожидаемыйRemote = ожидаемыйRemote
        self.ожидаемыйOIDRemote = ожидаемыйOIDRemote
        self.обязательныеПути = обязательныеПути
        self.свидетельствоГранта = свидетельствоГранта
        self.грантДействуетДо = грантДействуетДо
        self.ожидаемаяВерсияСостояния = ожидаемаяВерсияСостояния
    }
}

public struct НаблюдениеУзла: Codable, Equatable, Sendable {
    public let id: UUID
    public let наблюдалосьВ: Date
    public let свежоДо: Date
    public let источник: String
    public let версияИсточника: String
    public let возможности: Знание<[ДействиеУзла]>
    public let состояние: СостояниеУзла
    public let бюджетРесурсов: БюджетРесурсовУзла
    public let сигналыРаботы: СигналыРаботыУзла
    public let поручение: Знание<КонтекстПорученияУзла>
    public let свидетельствоЕдинственногоПисателя: Знание<String>

    public init(id: UUID, наблюдалосьВ: Date, свежоДо: Date, источник: String, версияИсточника: String,
        возможности: Знание<[ДействиеУзла]>, состояние: СостояниеУзла, бюджетРесурсов: БюджетРесурсовУзла,
        сигналыРаботы: СигналыРаботыУзла, поручение: Знание<КонтекстПорученияУзла>,
        свидетельствоЕдинственногоПисателя: Знание<String>) {
        self.id = id
        self.наблюдалосьВ = наблюдалосьВ
        self.свежоДо = свежоДо
        self.источник = источник
        self.версияИсточника = версияИсточника
        self.возможности = возможности
        self.состояние = состояние
        self.бюджетРесурсов = бюджетРесурсов
        self.сигналыРаботы = сигналыРаботы
        self.поручение = поручение
        self.свидетельствоЕдинственногоПисателя = свидетельствоЕдинственногоПисателя
    }
}

public enum СтатусИсходаКоманды: String, Codable, Sendable {
    case accepted, queued, running, completed, failed, unknown
}

public struct ИсходКоманды: Codable, Equatable, Sendable {
    public let idКоманды: UUID
    public let владелец: String
    public let наблюдалосьВ: Date
    public let ожидаемаяВерсияСостояния: Знание<UInt64>
    public let наблюдаемаяВерсияСостояния: Знание<UInt64>
    public let арендаДействуетДо: Знание<Date>
    public let статус: СтатусИсходаКоманды
    public let наблюдаемыйPID: Знание<Int32>
    public let кодЗавершения: Знание<Int32>
    public let свидетельствоИлиКвитанция: Знание<String>
    public let полезныеРезультаты: Знание<Int>
    public let задержкаМиллисекунды: Знание<UInt64>
    public let затратыЕдиниц: Знание<UInt64>
    public let лимиты: Знание<String>
    public let сбои: Знание<[String]>
    public let причина: Знание<String>

    public init(idКоманды: UUID, владелец: String, наблюдалосьВ: Date, ожидаемаяВерсияСостояния: Знание<UInt64>,
        наблюдаемаяВерсияСостояния: Знание<UInt64>, арендаДействуетДо: Знание<Date>,
        статус: СтатусИсходаКоманды, наблюдаемыйPID: Знание<Int32>, кодЗавершения: Знание<Int32>,
        свидетельствоИлиКвитанция: Знание<String>, полезныеРезультаты: Знание<Int>,
        задержкаМиллисекунды: Знание<UInt64>, затратыЕдиниц: Знание<UInt64>,
        лимиты: Знание<String>, сбои: Знание<[String]>, причина: Знание<String>) {
        self.idКоманды = idКоманды
        self.владелец = владелец
        self.наблюдалосьВ = наблюдалосьВ
        self.ожидаемаяВерсияСостояния = ожидаемаяВерсияСостояния
        self.наблюдаемаяВерсияСостояния = наблюдаемаяВерсияСостояния
        self.арендаДействуетДо = арендаДействуетДо
        self.статус = статус
        self.наблюдаемыйPID = наблюдаемыйPID
        self.кодЗавершения = кодЗавершения
        self.свидетельствоИлиКвитанция = свидетельствоИлиКвитанция
        self.полезныеРезультаты = полезныеРезультаты
        self.задержкаМиллисекунды = задержкаМиллисекунды
        self.затратыЕдиниц = затратыЕдиниц
        self.лимиты = лимиты
        self.сбои = сбои
        self.причина = причина
    }

    public var эффектЗавершён: Bool {
        статусТерминален(статус)
    }

    /// UNKNOWN не разрешает повтор: рост версии сам по себе не доказывает завершение прежнего эффекта.
    public func допускаетНовуюКоманду(сВерсиейНаблюдения версия: UInt64) -> Bool {
        switch статус {
        case .accepted, .queued, .running, .unknown:
            return false
        case .completed, .failed:
            guard case .известно(let прежняя) = ожидаемаяВерсияСостояния else { return false }
            return версия > прежняя
        }
    }
}

private func статусТерминален(_ статус: СтатусИсходаКоманды) -> Bool {
    switch статус {
    case .accepted, .queued, .running, .unknown: false
    case .completed, .failed: true
    }
}
