import Foundation

public enum ОтказКаталогаВосстановления: Error, Sendable { case объём }

private struct КлючОбъекта: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

func контейнерЗакрытыхКлючей<Ключ: CodingKey & CaseIterable>(
    _ декодировщик: any Decoder,
    ключи: Ключ.Type
) throws -> KeyedDecodingContainer<Ключ> where Ключ.AllCases.Element == Ключ {
    let сыройКонтейнер = try декодировщик.container(keyedBy: КлючОбъекта.self)
    let фактические = Set(сыройКонтейнер.allKeys.map(\.stringValue))
    let ожидаемые = Set(Ключ.allCases.map(\.stringValue))
    guard фактические == ожидаемые else {
        throw DecodingError.dataCorrupted(.init(
            codingPath: декодировщик.codingPath,
            debugDescription: "Набор ключей объекта не совпадает со схемой."
        ))
    }
    return try декодировщик.container(keyedBy: Ключ.self)
}

public enum СостояниеНаличия: String, Codable, Sendable {
    case есть = "есть", нет = "нет", неизвестно = "неизвестно"
}
public enum СостояниеВладельца: String, Codable, Sendable {
    case свой = "свой", чужой = "чужой", неизвестно = "неизвестно"
}
public enum СостояниеСеанса: String, Codable, Sendable {
    case активен = "active", готов = "ready", приостановлен = "paused"
    case отменён = "cancelled", завершённыйЭтап = "completedACT"
    case новыйРазрешённыйЭтап = "new-authorized-stage"
    case запускНеизвестен = "unknownLaunch", ожидаетСоставителя = "pendingComposer"
    case неизвестно = "unknown"
}
public enum РольУзлаКаталога: String, Codable, Sendable {
    case обычная = "обычная", постоянная = "постоянная"
}
public enum ФазаНаблюденияРепозитория: String, Codable, Sendable {
    case доЭффекта = "до-эффекта", послеЧтенияРепозитория = "после-чтения-репозитория", неизвестна = "неизвестна"
}
public enum ЧистотаОтслеживаемыхФайлов: String, Codable, Sendable {
    case чисто = "чисто", грязно = "грязно", неизвестно = "неизвестно"
}
public enum СостояниеДругихРабочихДеревьев: String, Codable, Sendable {
    case нет = "нет", есть = "есть", неизвестно = "неизвестно"
}

public struct ИсточникДопускаКаталога: Codable, Sendable {
    public let коммит, дерево, путь, объект, хэш: String
    public init(коммит: String, дерево: String, путь: String, объект: String, хэш: String) {
        self.коммит = коммит; self.дерево = дерево; self.путь = путь; self.объект = объект; self.хэш = хэш
    }
    private enum CodingKeys: String, CodingKey, CaseIterable { case коммит, дерево, путь, объект, хэш }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        коммит = try контейнер.decode(String.self, forKey: .коммит); дерево = try контейнер.decode(String.self, forKey: .дерево)
        путь = try контейнер.decode(String.self, forKey: .путь); объект = try контейнер.decode(String.self, forKey: .объект)
        хэш = try контейнер.decode(String.self, forKey: .хэш)
    }
}

public struct РазрешённыйЭтапКаталога: Codable, Sendable {
    public let узел, этап, поручение: String
    public init(узел: String, этап: String, поручение: String) {
        self.узел = узел; self.этап = этап; self.поручение = поручение
    }
    private enum CodingKeys: String, CodingKey, CaseIterable { case узел, этап, поручение }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        узел = try контейнер.decode(String.self, forKey: .узел)
        этап = try контейнер.decode(String.self, forKey: .этап)
        поручение = try контейнер.decode(String.self, forKey: .поручение)
    }
}

public struct ДопускКаталогаВосстановления: Codable, Sendable {
    public let идентификатор, координатор, корневаяЗадача: String
    public let выбранныеДети: [String]
    public let разрешённыеНовыеЭтапы: [РазрешённыйЭтапКаталога]
    public init(идентификатор: String, координатор: String, корневаяЗадача: String,
                выбранныеДети: [String], разрешённыеНовыеЭтапы: [РазрешённыйЭтапКаталога]) {
        self.идентификатор = идентификатор; self.координатор = координатор
        self.корневаяЗадача = корневаяЗадача; self.выбранныеДети = выбранныеДети
        self.разрешённыеНовыеЭтапы = разрешённыеНовыеЭтапы
    }
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case идентификатор, координатор, корневаяЗадача, выбранныеДети, разрешённыеНовыеЭтапы
    }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        идентификатор = try контейнер.decode(String.self, forKey: .идентификатор)
        координатор = try контейнер.decode(String.self, forKey: .координатор)
        корневаяЗадача = try контейнер.decode(String.self, forKey: .корневаяЗадача)
        выбранныеДети = try контейнер.decode([String].self, forKey: .выбранныеДети)
        разрешённыеНовыеЭтапы = try контейнер.decode([РазрешённыйЭтапКаталога].self, forKey: .разрешённыеНовыеЭтапы)
    }
}

public struct УзелКаталогаВосстановления: Codable, Sendable {
    public let идентификатор, родитель, ветка, коммит, дерево: String
    public let целевойПуть, репозиторийИсточника: String
    public let роль: РольУзлаКаталога
    public init(идентификатор: String, родитель: String, ветка: String, коммит: String, дерево: String,
                целевойПуть: String, репозиторийИсточника: String, роль: РольУзлаКаталога) {
        self.идентификатор = идентификатор; self.родитель = родитель; self.ветка = ветка
        self.коммит = коммит; self.дерево = дерево; self.целевойПуть = целевойПуть
        self.репозиторийИсточника = репозиторийИсточника; self.роль = роль
    }
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case идентификатор, родитель, ветка, коммит, дерево, целевойПуть, репозиторийИсточника, роль
    }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        идентификатор = try контейнер.decode(String.self, forKey: .идентификатор)
        родитель = try контейнер.decode(String.self, forKey: .родитель); ветка = try контейнер.decode(String.self, forKey: .ветка)
        коммит = try контейнер.decode(String.self, forKey: .коммит); дерево = try контейнер.decode(String.self, forKey: .дерево)
        целевойПуть = try контейнер.decode(String.self, forKey: .целевойПуть)
        репозиторийИсточника = try контейнер.decode(String.self, forKey: .репозиторийИсточника)
        роль = try контейнер.decode(РольУзлаКаталога.self, forKey: .роль)
    }
}

public struct ЗапросВосстановленияКаталога: Codable, Sendable {
    public static let схема = "fuma.каталог-восстановления.1"
    public let схемаДанных: String
    public let версия: Int
    public let допуск: ДопускКаталогаВосстановления
    public let источник: ИсточникДопускаКаталога
    public let узлы: [УзелКаталогаВосстановления]
    public init(схемаДанных: String = ЗапросВосстановленияКаталога.схема, версия: Int = 1,
                допуск: ДопускКаталогаВосстановления, источник: ИсточникДопускаКаталога,
                узлы: [УзелКаталогаВосстановления]) {
        self.схемаДанных = схемаДанных; self.версия = версия; self.допуск = допуск
        self.источник = источник; self.узлы = узлы
    }
    private enum CodingKeys: String, CodingKey, CaseIterable { case схемаДанных, версия, допуск, источник, узлы }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        схемаДанных = try контейнер.decode(String.self, forKey: .схемаДанных)
        версия = try контейнер.decode(Int.self, forKey: .версия)
        допуск = try контейнер.decode(ДопускКаталогаВосстановления.self, forKey: .допуск)
        источник = try контейнер.decode(ИсточникДопускаКаталога.self, forKey: .источник)
        узлы = try контейнер.decode([УзелКаталогаВосстановления].self, forKey: .узлы)
    }
}

public struct НаблюдениеСеансаКаталога: Codable, Sendable {
    public let узел: String
    public let источник, время, версия, наблюдаемыйУзел, этап: String?
    public let состояние: СостояниеСеанса
    public let владелец: СостояниеВладельца
    public init(узел: String, источник: String?, время: String?, версия: String?,
                наблюдаемыйУзел: String?, состояние: СостояниеСеанса,
                владелец: СостояниеВладельца, этап: String?) {
        self.узел = узел; self.источник = источник; self.время = время; self.версия = версия
        self.наблюдаемыйУзел = наблюдаемыйУзел; self.состояние = состояние
        self.владелец = владелец; self.этап = этап
    }
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case узел, источник, время, версия, наблюдаемыйУзел, состояние, владелец, этап
    }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        узел = try контейнер.decode(String.self, forKey: .узел)
        источник = try контейнер.decodeIfPresent(String.self, forKey: .источник); время = try контейнер.decodeIfPresent(String.self, forKey: .время)
        версия = try контейнер.decodeIfPresent(String.self, forKey: .версия)
        наблюдаемыйУзел = try контейнер.decodeIfPresent(String.self, forKey: .наблюдаемыйУзел)
        состояние = try контейнер.decode(СостояниеСеанса.self, forKey: .состояние)
        владелец = try контейнер.decode(СостояниеВладельца.self, forKey: .владелец)
        этап = try контейнер.decodeIfPresent(String.self, forKey: .этап)
    }
    public func encode(to кодировщик: any Encoder) throws {
        var контейнер = кодировщик.container(keyedBy: CodingKeys.self)
        try контейнер.encode(узел, forKey: .узел); try контейнер.encode(источник as String?, forKey: .источник)
        try контейнер.encode(время as String?, forKey: .время); try контейнер.encode(версия as String?, forKey: .версия)
        try контейнер.encode(наблюдаемыйУзел as String?, forKey: .наблюдаемыйУзел)
        try контейнер.encode(состояние, forKey: .состояние); try контейнер.encode(владелец, forKey: .владелец)
        try контейнер.encode(этап as String?, forKey: .этап)
    }
}

public struct НаблюдениеРепозиторияКаталога: Codable, Sendable {
    public let узел: String
    public let фаза: ФазаНаблюденияРепозитория
    public let репозиторий: String
    public let физическийПуть, владелецРегистрации, ветка, коммит, дерево: String?
    public let состояниеФизическогоПути, регистрация, наличиеВетки: СостояниеНаличия
    public let отслеживаемыеФайлы: ЧистотаОтслеживаемыхФайлов
    public let веткаИсточника, коммитИсточника, деревоИсточника: String?
    public let другиеРабочиеДеревья: СостояниеДругихРабочихДеревьев
    public let неотслеживаемыеФайлы, игнорируемыеФайлы: СостояниеНаличия
    public init(узел: String, фаза: ФазаНаблюденияРепозитория, репозиторий: String, физическийПуть: String?,
                состояниеФизическогоПути: СостояниеНаличия, регистрация: СостояниеНаличия,
                владелецРегистрации: String?, наличиеВетки: СостояниеНаличия, ветка: String?,
                коммит: String?, дерево: String?, отслеживаемыеФайлы: ЧистотаОтслеживаемыхФайлов,
                веткаИсточника: String?, коммитИсточника: String?, деревоИсточника: String?,
                другиеРабочиеДеревья: СостояниеДругихРабочихДеревьев,
                неотслеживаемыеФайлы: СостояниеНаличия, игнорируемыеФайлы: СостояниеНаличия) {
        self.узел = узел; self.фаза = фаза; self.репозиторий = репозиторий
        self.физическийПуть = физическийПуть; self.состояниеФизическогоПути = состояниеФизическогоПути
        self.регистрация = регистрация; self.владелецРегистрации = владелецРегистрации
        self.наличиеВетки = наличиеВетки; self.ветка = ветка; self.коммит = коммит; self.дерево = дерево
        self.отслеживаемыеФайлы = отслеживаемыеФайлы; self.веткаИсточника = веткаИсточника
        self.коммитИсточника = коммитИсточника; self.деревоИсточника = деревоИсточника
        self.другиеРабочиеДеревья = другиеРабочиеДеревья
        self.неотслеживаемыеФайлы = неотслеживаемыеФайлы; self.игнорируемыеФайлы = игнорируемыеФайлы
    }
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case узел, фаза, репозиторий, физическийПуть, состояниеФизическогоПути, регистрация
        case владелецРегистрации, наличиеВетки, ветка, коммит, дерево, отслеживаемыеФайлы
        case веткаИсточника, коммитИсточника, деревоИсточника, другиеРабочиеДеревья
        case неотслеживаемыеФайлы, игнорируемыеФайлы
    }
    public init(from декодировщик: any Decoder) throws {
        let контейнер = try контейнерЗакрытыхКлючей(декодировщик, ключи: CodingKeys.self)
        узел = try контейнер.decode(String.self, forKey: .узел); фаза = try контейнер.decode(ФазаНаблюденияРепозитория.self, forKey: .фаза)
        репозиторий = try контейнер.decode(String.self, forKey: .репозиторий)
        физическийПуть = try контейнер.decodeIfPresent(String.self, forKey: .физическийПуть)
        состояниеФизическогоПути = try контейнер.decode(СостояниеНаличия.self, forKey: .состояниеФизическогоПути)
        регистрация = try контейнер.decode(СостояниеНаличия.self, forKey: .регистрация)
        владелецРегистрации = try контейнер.decodeIfPresent(String.self, forKey: .владелецРегистрации)
        наличиеВетки = try контейнер.decode(СостояниеНаличия.self, forKey: .наличиеВетки)
        ветка = try контейнер.decodeIfPresent(String.self, forKey: .ветка); коммит = try контейнер.decodeIfPresent(String.self, forKey: .коммит)
        дерево = try контейнер.decodeIfPresent(String.self, forKey: .дерево)
        отслеживаемыеФайлы = try контейнер.decode(ЧистотаОтслеживаемыхФайлов.self, forKey: .отслеживаемыеФайлы)
        веткаИсточника = try контейнер.decodeIfPresent(String.self, forKey: .веткаИсточника)
        коммитИсточника = try контейнер.decodeIfPresent(String.self, forKey: .коммитИсточника)
        деревоИсточника = try контейнер.decodeIfPresent(String.self, forKey: .деревоИсточника)
        другиеРабочиеДеревья = try контейнер.decode(СостояниеДругихРабочихДеревьев.self, forKey: .другиеРабочиеДеревья)
        неотслеживаемыеФайлы = try контейнер.decode(СостояниеНаличия.self, forKey: .неотслеживаемыеФайлы)
        игнорируемыеФайлы = try контейнер.decode(СостояниеНаличия.self, forKey: .игнорируемыеФайлы)
    }
    public func encode(to кодировщик: any Encoder) throws {
        var контейнер = кодировщик.container(keyedBy: CodingKeys.self)
        try контейнер.encode(узел, forKey: .узел); try контейнер.encode(фаза, forKey: .фаза)
        try контейнер.encode(репозиторий, forKey: .репозиторий)
        try контейнер.encode(физическийПуть as String?, forKey: .физическийПуть)
        try контейнер.encode(состояниеФизическогоПути, forKey: .состояниеФизическогоПути)
        try контейнер.encode(регистрация, forKey: .регистрация)
        try контейнер.encode(владелецРегистрации as String?, forKey: .владелецРегистрации)
        try контейнер.encode(наличиеВетки, forKey: .наличиеВетки)
        try контейнер.encode(ветка as String?, forKey: .ветка); try контейнер.encode(коммит as String?, forKey: .коммит)
        try контейнер.encode(дерево as String?, forKey: .дерево)
        try контейнер.encode(отслеживаемыеФайлы, forKey: .отслеживаемыеФайлы)
        try контейнер.encode(веткаИсточника as String?, forKey: .веткаИсточника)
        try контейнер.encode(коммитИсточника as String?, forKey: .коммитИсточника)
        try контейнер.encode(деревоИсточника as String?, forKey: .деревоИсточника)
        try контейнер.encode(другиеРабочиеДеревья, forKey: .другиеРабочиеДеревья)
        try контейнер.encode(неотслеживаемыеФайлы, forKey: .неотслеживаемыеФайлы)
        try контейнер.encode(игнорируемыеФайлы, forKey: .игнорируемыеФайлы)
    }
}
