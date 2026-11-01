import CryptoKit
import Foundation

/// Происхождение выбранных значений; ни один случай не удостоверяет модель провайдера.
public enum ИсточникВыбораМодели: String, Codable, Equatable, Sendable {
    case дочернийВызовSpawnAgent = "collaboration.spawn_agent"
    case корневыеNativeClientMetadata = "native-codex-client-thread-metadata"
    case метаданныеДочернегоКлиента = "native-codex-child-client-metadata"
}

/// Ожидание выбирает непосредственный родитель/host независимо от receipt.
/// UUID связывают наблюдение с этапом; сами по себе они не доказывают родство.
public struct КонтекстОбычногоРебёнка: Codable, Equatable, Sendable {
    public var корневойUUID: String
    public var сессия: String
    public var непосредственныйРодитель: String
    public var этап: String
    public var попытка: String
    public var запрошено: ПараметрыВыбораAPI?
    public var наблюдённыйACK: String

    public init(корневойUUID: String, сессия: String, непосредственныйРодитель: String,
                этап: String, попытка: String, запрошено: ПараметрыВыбораAPI? = nil,
                наблюдённыйACK: String = "UNKNOWN") {
        self.корневойUUID = корневойUUID; self.сессия = сессия
        self.непосредственныйРодитель = непосредственныйРодитель; self.этап = этап
        self.попытка = попытка; self.запрошено = запрошено; self.наблюдённыйACK = наблюдённыйACK
    }
}

public struct ПараметрыВыбораAPI: Codable, Equatable, Sendable {
    public let model: String
    public let reasoningEffort: String

    public init(model: String, reasoningEffort: String) {
        self.model = model
        self.reasoningEffort = reasoningEffort
    }
}

public enum СтатусИдентификатораAPI: String, Codable, Equatable, Sendable {
    case доступен
    case недоступен
}

public enum ВидИдентификатораAPI: String, Codable, Equatable, Sendable {
    case идентификаторВызова
    case идентификаторNativeThreadMetadata
}

public struct ИдентичностьAPI: Codable, Equatable, Sendable {
    public let статус: СтатусИдентификатораAPI
    public let вид: ВидИдентификатораAPI
    public let значение: String?

    public init(статус: СтатусИдентификатораAPI, вид: ВидИдентификатораAPI, значение: String?) {
        self.статус = статус
        self.вид = вид
        self.значение = значение
    }
}

public enum НеизвестныйСтатусСведений: String, Codable, Equatable, Sendable {
    case неизвестно
}

public struct СнимокNativeThreadMetadata: Codable, Equatable, Sendable {
    public let threadUUID: String
    public let agentPath: String
    public let attachedThreadParentIDRaw: String
    public let модель: String
    public let усилие: String
    public let lineageСтатус: НеизвестныйСтатусСведений

    public init(
        threadUUID: String,
        agentPath: String,
        attachedThreadParentIDRaw: String,
        модель: String,
        усилие: String,
        lineageСтатус: НеизвестныйСтатусСведений
    ) {
        self.threadUUID = threadUUID
        self.agentPath = agentPath
        self.attachedThreadParentIDRaw = attachedThreadParentIDRaw
        self.модель = модель
        self.усилие = усилие
        self.lineageСтатус = lineageСтатус
    }
}

/// Локально сохранённая typed-проекция выбранных model/effort с точным источником.
/// Хэши закрепляют байты проекции, но не аутентифицируют клиент или backend.
public struct СвидетельствоВыбораМодели: Codable, Equatable, Sendable {
    public let схема: String
    public let источник: ИсточникВыбораМодели
    public let rootUUID: String
    public let sessionIdentity: ИдентичностьAPI
    public let requestIdentity: ИдентичностьAPI
    public let responseIdentity: ИдентичностьAPI
    public let nativeThread: СнимокNativeThreadMetadata?
    public let requestedSelection: ПараметрыВыбораAPI?
    public let selectedValue: ПараметрыВыбораAPI
    public let nativeSelectionSourceSHA256: String?
    public let backendModel: НеизвестныйСтатусСведений
    public let nativeTurnContext: НеизвестныйСтатусСведений
    public let дочернийКонтекст: КонтекстОбычногоРебёнка?

    private enum CodingKeys: String, CodingKey {
        case схема, источник, rootUUID, sessionIdentity, childIdentity, requestIdentity, responseIdentity
        case nativeThread, requestedSelection, requested, selectedValue, acceptedSelection
        case nativeSelectionSourceSHA256, backendModel, nativeTurnContext
        case дочернийКонтекст
    }

    public init(
        схема: String = "fum.model-selection-receipt.1",
        источник: ИсточникВыбораМодели,
        rootUUID: String,
        sessionIdentity: ИдентичностьAPI,
        requestIdentity: ИдентичностьAPI,
        responseIdentity: ИдентичностьAPI,
        nativeThread: СнимокNativeThreadMetadata?,
        requestedSelection: ПараметрыВыбораAPI?,
        selectedValue: ПараметрыВыбораAPI,
        nativeSelectionSourceSHA256: String? = nil,
        backendModel: НеизвестныйСтатусСведений,
        nativeTurnContext: НеизвестныйСтатусСведений,
        дочернийКонтекст: КонтекстОбычногоРебёнка? = nil
    ) {
        self.схема = схема
        self.источник = источник
        self.rootUUID = rootUUID
        self.sessionIdentity = sessionIdentity
        self.requestIdentity = requestIdentity
        self.responseIdentity = responseIdentity
        self.nativeThread = nativeThread
        self.requestedSelection = requestedSelection
        self.selectedValue = selectedValue
        self.nativeSelectionSourceSHA256 = nativeSelectionSourceSHA256
        self.backendModel = backendModel
        self.nativeTurnContext = nativeTurnContext
        self.дочернийКонтекст = дочернийКонтекст
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schema = try container.decode(String.self, forKey: .схема)
        let source = try container.decode(ИсточникВыбораМодели.self, forKey: .источник)
        let rootUUID = try container.decode(String.self, forKey: .rootUUID)
        let requestIdentity = try container.decode(ИдентичностьAPI.self, forKey: .requestIdentity)
        let responseIdentity = try container.decode(ИдентичностьAPI.self, forKey: .responseIdentity)
        let nativeThread = try container.decodeIfPresent(СнимокNativeThreadMetadata.self, forKey: .nativeThread)
        let backendModel = try container.decode(НеизвестныйСтатусСведений.self, forKey: .backendModel)
        let nativeTurnContext = try container.decode(НеизвестныйСтатусСведений.self, forKey: .nativeTurnContext)
        if schema == "fum.api-selection-receipt.1" {
            self.init(
                схема: schema,
                источник: source,
                rootUUID: rootUUID,
                sessionIdentity: try container.decode(ИдентичностьAPI.self, forKey: .childIdentity),
                requestIdentity: requestIdentity,
                responseIdentity: responseIdentity,
                nativeThread: nativeThread,
                requestedSelection: try container.decode(ПараметрыВыбораAPI.self, forKey: .requested),
                selectedValue: try container.decode(ПараметрыВыбораAPI.self, forKey: .acceptedSelection),
                backendModel: backendModel,
                nativeTurnContext: nativeTurnContext,
                дочернийКонтекст: try container.decodeIfPresent(КонтекстОбычногоРебёнка.self, forKey: .дочернийКонтекст)
            )
        } else {
            self.init(
                схема: schema,
                источник: source,
                rootUUID: rootUUID,
                sessionIdentity: try container.decode(ИдентичностьAPI.self, forKey: .sessionIdentity),
                requestIdentity: requestIdentity,
                responseIdentity: responseIdentity,
                nativeThread: nativeThread,
                requestedSelection: try container.decodeIfPresent(ПараметрыВыбораAPI.self, forKey: .requestedSelection),
                selectedValue: try container.decode(ПараметрыВыбораAPI.self, forKey: .selectedValue),
                nativeSelectionSourceSHA256: try container.decodeIfPresent(String.self, forKey: .nativeSelectionSourceSHA256),
                backendModel: backendModel,
                nativeTurnContext: nativeTurnContext,
                дочернийКонтекст: try container.decodeIfPresent(КонтекстОбычногоРебёнка.self, forKey: .дочернийКонтекст)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(схема, forKey: .схема)
        try container.encode(источник, forKey: .источник)
        try container.encode(rootUUID, forKey: .rootUUID)
        try container.encode(requestIdentity, forKey: .requestIdentity)
        try container.encode(responseIdentity, forKey: .responseIdentity)
        try container.encode(backendModel, forKey: .backendModel)
        try container.encode(nativeTurnContext, forKey: .nativeTurnContext)
        try container.encodeIfPresent(дочернийКонтекст, forKey: .дочернийКонтекст)
        if схема == "fum.api-selection-receipt.1" {
            try container.encode(sessionIdentity, forKey: .childIdentity)
            try container.encode(nativeThread, forKey: .nativeThread)
            try container.encode(requestedSelection, forKey: .requested)
            try container.encode(selectedValue, forKey: .acceptedSelection)
        } else {
            try container.encode(sessionIdentity, forKey: .sessionIdentity)
            try container.encodeIfPresent(nativeThread, forKey: .nativeThread)
            try container.encodeIfPresent(requestedSelection, forKey: .requestedSelection)
            try container.encode(selectedValue, forKey: .selectedValue)
            try container.encodeIfPresent(nativeSelectionSourceSHA256, forKey: .nativeSelectionSourceSHA256)
        }
    }
}

public struct КвитанцияВыбораМодели: Codable, Equatable, Sendable {
    public let свидетельство: СвидетельствоВыбораМодели
    /// Base64 канонических JSON-байтов локальной проекции, не исходный wire payload.
    public let canonicalBytesBase64: String
    public let sha256: String

    public init(свидетельство: СвидетельствоВыбораМодели, canonicalBytesBase64: String, sha256: String) {
        self.свидетельство = свидетельство
        self.canonicalBytesBase64 = canonicalBytesBase64
        self.sha256 = sha256
    }
}

/// Независимо закреплённая ожиданием consumer копия receipt и его канонических байтов.
/// Совпадение хэша показывает целостность согласованной проекции, не подлинность источника.
public struct ОжидаемаяКвитанцияВыбораМодели: Codable, Equatable, Sendable {
    public let свидетельство: СвидетельствоВыбораМодели
    public let canonicalBytesBase64: String
    public let sha256: String

    public init(свидетельство: СвидетельствоВыбораМодели, canonicalBytesBase64: String, sha256: String) {
        self.свидетельство = свидетельство
        self.canonicalBytesBase64 = canonicalBytesBase64
        self.sha256 = sha256
    }
}

public struct ОжидаемаяИдентичностьGit: Codable, Equatable, Sendable {
    public let квитанцияВыбораМодели: КвитанцияВыбораМодели?
    public let ожидаемаяКвитанцияВыбораМодели: ОжидаемаяКвитанцияВыбораМодели?
    public let родитель: String

    private enum CodingKeys: String, CodingKey {
        case квитанцияВыбораМодели = "квитанцияВыбораAPI"
        case ожидаемаяКвитанцияВыбораМодели = "ожидаемаяКвитанцияВыбораAPI"
        case родитель
    }

    public init(
        квитанцияВыбораМодели: КвитанцияВыбораМодели?,
        ожидаемаяКвитанцияВыбораМодели: ОжидаемаяКвитанцияВыбораМодели?,
        родитель: String
    ) {
        self.квитанцияВыбораМодели = квитанцияВыбораМодели
        self.ожидаемаяКвитанцияВыбораМодели = ожидаемаяКвитанцияВыбораМодели
        self.родитель = родитель
    }
}

/// Независимо выбранное ожидаемое состояние для read-only проверки Git после эффекта.
/// `удалённыйOID == nil` означает, что ветка должна отсутствовать в origin.
public struct ОжидаемоеПостЭффектноеСостояниеGit: Codable, Equatable, Sendable {
    public let схема: String
    public let oidКоммита: String
    public let реф: String
    public let адресOrigin: String
    public let oidДерева: String
    public let oidРодителя: String
    public let удалённыйOID: String?

    public init(
        oidКоммита: String,
        реф: String,
        адресOrigin: String,
        oidДерева: String,
        oidРодителя: String,
        удалённыйOID: String?
    ) {
        self.схема = "fum.git-post-effect-expectation.1"
        self.oidКоммита = oidКоммита
        self.реф = реф
        self.адресOrigin = адресOrigin
        self.oidДерева = oidДерева
        self.oidРодителя = oidРодителя
        self.удалённыйOID = удалённыйOID
    }
}

public enum ОшибкаВыбораNativeClient: String, Error, Equatable, Sendable {
    case некорректныйJSONИсточника = "native-client-source-json-invalid"
    case ожидаласьОднаСтрока = "native-client-source-must-have-one-row"
    case невернаяСессия = "native-client-source-thread-mismatch"
    case отсутствуетМодель = "native-client-source-model-missing"
    case отсутствуетУсилие = "native-client-source-effort-missing"
    case дрейфВыбора = "native-client-selected-value-drift"
}

public struct ПараНезависимыхКвитанцийВыбораМодели: Codable, Equatable, Sendable {
    public let фактическая: КвитанцияВыбораМодели
    public let ожидаемая: ОжидаемаяКвитанцияВыбораМодели

    public init(фактическая: КвитанцияВыбораМодели, ожидаемая: ОжидаемаяКвитанцияВыбораМодели) {
        self.фактическая = фактическая
        self.ожидаемая = ожидаемая
    }
}

public struct ПубличнаяПроекцияRootNativeClient: Codable, Equatable, Sendable {
    public let схема: String
    public let источник: ИсточникВыбораМодели
    public let корневойUUID: String
    public let последнееПодтверждённоеВыбранноеЗначениеКлиента: ПараметрыВыбораAPI
    public let идентичностьЗапросаAPI: СтатусИдентификатораAPI
    public let идентичностьОтветаAPI: СтатусИдентификатораAPI
    public let фактическаяМодельПровайдера: НеизвестныйСтатусСведений
    public let контекстNativeХода: НеизвестныйСтатусСведений
    public let хэшПроекцииИсточника: String
    public let хэшНезависимойОжидаемойПроекции: String
    public let хэшКвитанции: String
    public let хэшНезависимойОжидаемойКвитанции: String

    public init(пара: ПараНезависимыхКвитанцийВыбораМодели) {
        схема = "fum.root-native-client-selection-projection.1"
        источник = пара.фактическая.свидетельство.источник
        корневойUUID = пара.фактическая.свидетельство.rootUUID
        последнееПодтверждённоеВыбранноеЗначениеКлиента = пара.фактическая.свидетельство.selectedValue
        идентичностьЗапросаAPI = пара.фактическая.свидетельство.requestIdentity.статус
        идентичностьОтветаAPI = пара.фактическая.свидетельство.responseIdentity.статус
        фактическаяМодельПровайдера = пара.фактическая.свидетельство.backendModel
        контекстNativeХода = пара.фактическая.свидетельство.nativeTurnContext
        хэшПроекцииИсточника = пара.фактическая.свидетельство.nativeSelectionSourceSHA256 ?? ""
        хэшНезависимойОжидаемойПроекции = пара.ожидаемая.свидетельство.nativeSelectionSourceSHA256 ?? ""
        хэшКвитанции = пара.фактическая.sha256
        хэшНезависимойОжидаемойКвитанции = пара.ожидаемая.sha256
    }
}

/// Ограниченный адаптер одной строки native-client metadata для корневой сессии.
/// Принимает только отдельно прочитанные source и expected JSON строки; ключи БД и raw bytes остаются у caller.
public enum АдаптерRootNativeClientMetadata {
    private struct СтрокаСессии: Decodable {
        let id: String
        let model: String?
        let reasoning_effort: String?
    }

    public static func построитьКвитанции(
        источникJSON: Data,
        независимоеОжиданиеJSON: Data,
        expectedRootUUID: String
    ) throws -> ПараНезависимыхКвитанцийВыбораМодели {
        let источник = try прочитатьСтроку(источникJSON, expectedRootUUID: expectedRootUUID)
        let ожидание = try прочитатьСтроку(независимоеОжиданиеJSON, expectedRootUUID: expectedRootUUID)
        let фактическоеСвидетельство = try свидетельство(для: источник, исходныеБайты: источникJSON, rootUUID: expectedRootUUID)
        let ожидаемоеСвидетельство = try свидетельство(для: ожидание, исходныеБайты: независимоеОжиданиеJSON, rootUUID: expectedRootUUID)
        return ПараНезависимыхКвитанцийВыбораМодели(
            фактическая: try ГенераторМетаданныхКоммита.квитанция(для: фактическоеСвидетельство),
            ожидаемая: try ГенераторМетаданныхКоммита.ожидание(для: ожидаемоеСвидетельство)
        )
    }

    public static func проверитьДрейф(
        текущееJSON: Data,
        ожидаемая: СвидетельствоВыбораМодели
    ) throws {
        guard ожидаемая.источник == .корневыеNativeClientMetadata,
              let sessionUUID = ожидаемая.sessionIdentity.значение,
              let selectionHash = ожидаемая.nativeSelectionSourceSHA256,
              selectionHash.count == 64 else {
            throw ОшибкаВыбораNativeClient.некорректныйJSONИсточника
        }
        let текущаяСтрока = try прочитатьСтроку(текущееJSON, expectedRootUUID: sessionUUID)
        let модель = try обязательноеЗначение(текущаяСтрока.model, отсутствует: .отсутствуетМодель)
        let усилие = try обязательноеЗначение(текущаяСтрока.reasoning_effort, отсутствует: .отсутствуетУсилие)
        guard ожидаемая.selectedValue == ПараметрыВыбораAPI(model: модель, reasoningEffort: усилие) else {
            throw ОшибкаВыбораNativeClient.дрейфВыбора
        }
    }

    /// Версионное расширение для ordinary child. Оба чтения и независимый
    /// контекст выбирает вызывающий parent, а не предлагаемая квитанция.
    public static func построитьКвитанцииОбычногоРебёнка(
        источникJSON: Data, независимоеОжиданиеJSON: Data,
        ожидаемыйКонтекст: КонтекстОбычногоРебёнка
    ) throws -> ПараНезависимыхКвитанцийВыбораМодели {
        func построить(_ данные: Data) throws -> СвидетельствоВыбораМодели {
            let строка = try прочитатьСтроку(данные, expectedRootUUID: ожидаемыйКонтекст.сессия)
            let недоступно = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
            return СвидетельствоВыбораМодели(
                схема: "fum.model-selection-receipt.2", источник: .метаданныеДочернегоКлиента,
                rootUUID: ожидаемыйКонтекст.корневойUUID,
                sessionIdentity: ИдентичностьAPI(статус: .доступен, вид: .идентификаторNativeThreadMetadata, значение: строка.id),
                requestIdentity: недоступно, responseIdentity: недоступно, nativeThread: nil,
                requestedSelection: ожидаемыйКонтекст.запрошено,
                selectedValue: ПараметрыВыбораAPI(model: try обязательноеЗначение(строка.model, отсутствует: .отсутствуетМодель),
                    reasoningEffort: try обязательноеЗначение(строка.reasoning_effort, отсутствует: .отсутствуетУсилие)),
                nativeSelectionSourceSHA256: ГенераторМетаданныхКоммита.sha256Hex(данные), backendModel: .неизвестно,
                nativeTurnContext: .неизвестно, дочернийКонтекст: ожидаемыйКонтекст)
        }
        let факт = try построить(источникJSON), ожидание = try построить(независимоеОжиданиеJSON)
        let пара = ПараНезависимыхКвитанцийВыбораМодели(фактическая: try ГенераторМетаданныхКоммита.квитанция(для: факт),
            ожидаемая: try ГенераторМетаданныхКоммита.ожидание(для: ожидание))
        guard ГенераторМетаданныхКоммита.проверитьReceipt(пара.фактическая, ожидаемый: пара.ожидаемая,
            expectedRootUUID: ожидаемыйКонтекст.корневойUUID, ожидаемыйДочернийКонтекст: ожидаемыйКонтекст).isEmpty else {
            throw ОшибкаВыбораNativeClient.дрейфВыбора
        }
        return пара
    }

    private static func прочитатьСтроку(_ data: Data, expectedRootUUID: String) throws -> СтрокаСессии {
        guard let строки = try? JSONDecoder().decode([СтрокаСессии].self, from: data) else {
            throw ОшибкаВыбораNativeClient.некорректныйJSONИсточника
        }
        guard строки.count == 1, let строка = строки.first else {
            throw ОшибкаВыбораNativeClient.ожидаласьОднаСтрока
        }
        guard строка.id == expectedRootUUID else {
            throw ОшибкаВыбораNativeClient.невернаяСессия
        }
        _ = try обязательноеЗначение(строка.model, отсутствует: .отсутствуетМодель)
        _ = try обязательноеЗначение(строка.reasoning_effort, отсутствует: .отсутствуетУсилие)
        return строка
    }

    private static func свидетельство(
        для строка: СтрокаСессии,
        исходныеБайты: Data,
        rootUUID: String
    ) throws -> СвидетельствоВыбораМодели {
        let модель = try обязательноеЗначение(строка.model, отсутствует: .отсутствуетМодель)
        let усилие = try обязательноеЗначение(строка.reasoning_effort, отсутствует: .отсутствуетУсилие)
        let недоступно = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
        return СвидетельствоВыбораМодели(
            источник: .корневыеNativeClientMetadata,
            rootUUID: rootUUID,
            sessionIdentity: ИдентичностьAPI(
                статус: .доступен,
                вид: .идентификаторNativeThreadMetadata,
                значение: строка.id
            ),
            requestIdentity: недоступно,
            responseIdentity: недоступно,
            nativeThread: nil,
            requestedSelection: nil,
            selectedValue: ПараметрыВыбораAPI(model: модель, reasoningEffort: усилие),
            nativeSelectionSourceSHA256: ГенераторМетаданныхКоммита.sha256Hex(исходныеБайты),
            backendModel: .неизвестно,
            nativeTurnContext: .неизвестно
        )
    }

    private static func обязательноеЗначение(
        _ value: String?,
        отсутствует error: ОшибкаВыбораNativeClient
    ) throws -> String {
        guard let value, !value.isEmpty else { throw error }
        return value
    }
}

public struct ПланСообщенияКоммита: Codable, Equatable, Sendable {
    public let исходныйЗапрос: String
    public let заголовок: String
    public let описание: String

    public init(исходныйЗапрос: String, заголовок: String, описание: String) {
        self.исходныйЗапрос = исходныйЗапрос
        self.заголовок = заголовок
        self.описание = описание
    }
}

public struct ИдентификаторGit: Codable, Equatable, Sendable {
    public let имя: String
    public let почта: String

    public init(имя: String, почта: String) {
        self.имя = имя
        self.почта = почта
    }
}

public struct ВыходГенератораGitMetadata: Codable, Equatable, Sendable {
    public let environment: [String: String]
    public let message: String

    public init(environment: [String: String], message: String) {
        self.environment = environment
        self.message = message
    }
}

public struct ВходСлучаяГенератораFUMA: Codable, Equatable, Sendable {
    public let id: String
    public let acceptedSelection: ПараметрыВыбораAPI
    public let rootUUID: String
    public let title: String
    public let description: String
    public let rawRequest: String

    public init(
        id: String,
        acceptedSelection: ПараметрыВыбораAPI,
        rootUUID: String,
        title: String,
        description: String,
        rawRequest: String
    ) {
        self.id = id
        self.acceptedSelection = acceptedSelection
        self.rootUUID = rootUUID
        self.title = title
        self.description = description
        self.rawRequest = rawRequest
    }
}

public struct ПакетВходаГенератораFUMA: Codable, Equatable, Sendable {
    public let cases: [ВходСлучаяГенератораFUMA]

    public init(cases: [ВходСлучаяГенератораFUMA]) {
        self.cases = cases
    }
}

public struct ВыходСлучаяГенератораFUMA: Codable, Equatable, Sendable {
    public let id: String
    public let environment: [String: String]
    public let message: String

    public init(id: String, environment: [String: String], message: String) {
        self.id = id
        self.environment = environment
        self.message = message
    }
}

public struct ПакетВыходаГенератораFUMA: Codable, Equatable, Sendable {
    public let cases: [ВыходСлучаяГенератораFUMA]

    public init(cases: [ВыходСлучаяГенератораFUMA]) {
        self.cases = cases
    }
}

public struct РезультатГенерацииМетаданныхКоммита: Codable, Equatable, Sendable {
    public let выборМодели: СвидетельствоВыбораМодели
    public let автор: ИдентификаторGit
    public let коммитер: ИдентификаторGit
    public let окружение: [String: String]
    public let сообщение: String
    public let ошибки: [String]
}

public struct РезультатПодготовкиОкруженияКоммита: Codable, Equatable, Sendable {
    public let выходFUMA: ВыходГенератораGitMetadata?
    public let ошибки: [String]
}

/// Родители задаются намерением, а не наличием MERGE_HEAD или словами сообщения.
/// Этот DTO описывает результат; разрешение на эффект host передаёт отдельно.
public struct НамерениеСозданияКоммитаGit: Codable, Equatable, Sendable {
    public enum Вид: String, Codable, Equatable, Sendable { case контрольнаяТочка, слияние }
    public let вид: Вид
    public let реф: String
    public let родители: [String]
    public let дерево: String

    public init(вид: Вид, реф: String, родители: [String], дерево: String) {
        self.вид = вид; self.реф = реф; self.родители = родители; self.дерево = дерево
    }

    public func проверить() -> [String] {
        func полныйOID(_ значение: String) -> Bool {
            значение.utf8.count == 40 && значение.utf8.allSatisfy {
                (48...57).contains($0) || (97...102).contains($0)
            } && значение != String(repeating: "0", count: 40)
        }
        var ошибки: [String] = []
        if родители.count != (вид == .слияние ? 2 : 1) ||
            Set(родители).count != родители.count || !родители.allSatisfy(полныйOID) {
            ошибки.append("намерение-неверные-родители")
        }
        if !полныйOID(дерево) { ошибки.append("намерение-неверное-дерево") }
        if !реф.hasPrefix("refs/heads/") || реф.utf8.contains(0) ||
            реф.contains("\n") || реф.contains("\r") {
            ошибки.append("намерение-неверный-реф")
        }
        return ошибки
    }
}

/// Метаданные отдельно разрешённого незавершённого сохранения исходников.
/// Этот вход не удостоверяет полномочия, прохождение профиля или выбор модели.
public struct ЗапросМетаданныхИсходников: Codable, Equatable, Sendable {
    public let схема: String
    public let корневойUUID: String
    public let писатель: String
    public let рабочееДерево: String
    public let реф: String
    public let родитель: String
    public let дерево: String
    public let статусВыбора: String
    public let основаниеSHA256: String
    public let план: ПланСообщенияКоммита

    public func проверить() -> [String] {
        var ошибки = ГенераторМетаданныхКоммита.проверитьЗаголовок(план.заголовок)
        if схема != "fum.source-checkpoint-metadata-request.1" || статусВыбора != "UNKNOWN" {
            ошибки.append("неверный-явный-режим-исходников")
        }
        if UUID(uuidString: корневойUUID) == nil || UUID(uuidString: писатель) == nil {
            ошибки.append("неверный-uuid-исходников")
        }
        if !рабочееДерево.hasPrefix("/") || !реф.hasPrefix("refs/heads/") {
            ошибки.append("нет-адресной-границы-исходников")
        }
        for (значение, длина) in [(родитель, 40), (дерево, 40), (основаниеSHA256, 64)] {
            if значение.utf8.count != длина || !значение.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) {
                ошибки.append("неверный-pin-исходников")
            }
        }
        if план.описание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            план.исходныйЗапрос.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибки.append("нет-содержания-сообщения-исходников")
        }
        return ошибки
    }

    /// Совместимый DTO используется только как транспорт к прежнему форматтеру FUMA.
    /// UNKNOWN не является accepted selection; квитанция из этих значений не создаётся.
    public var входФорматтера: ПакетВходаГенератораFUMA {
        ПакетВходаГенератораFUMA(cases: [ВходСлучаяГенератораFUMA(
            id: "source-checkpoint-UNKNOWN",
            acceptedSelection: ПараметрыВыбораAPI(model: "UNKNOWN", reasoningEffort: "UNKNOWN"),
            rootUUID: корневойUUID, title: план.заголовок,
            description: план.описание, rawRequest: план.исходныйЗапрос)])
    }

    public func проверитьВыход(_ выход: ВыходГенератораGitMetadata) -> [String] {
        let эталон = ГенераторМетаданныхКоммита.referenceOutput(for: входФорматтера).cases[0]
        return проверить() + (выход.environment == эталон.environment && выход.message == эталон.message
            ? [] : ["исходники-fuma-output-не-совпадает"])
    }
}

/// Намеренно иной DTO: его нельзя декодировать как подтверждённый результат с выборМодели.
public struct МетаданныеИсходников: Codable, Equatable, Sendable {
    public let схема: String
    public let запрос: ЗапросМетаданныхИсходников
    public let автор: ИдентификаторGit
    public let коммитер: ИдентификаторGit
    public let выход: ВыходГенератораGitMetadata
    public let ошибки: [String]

    public static func подготовить(запрос: ЗапросМетаданныхИсходников,
                                  выход: ВыходГенератораGitMetadata,
                                  авторGit: String, коммитерGit: String) -> Self {
        var ошибки = запрос.проверитьВыход(выход)
        let эталон = ГенераторМетаданныхКоммита.referenceOutput(for: запрос.входФорматтера).cases[0]
        let автор = ГенераторМетаданныхКоммита.разобратьGitIdent(авторGit)
        let коммитер = ГенераторМетаданныхКоммита.разобратьGitIdent(коммитерGit)
        if автор?.имя != эталон.environment["GIT_AUTHOR_NAME"] || автор == nil || коммитер == nil {
            ошибки.append("исходники-git-var-не-совпадает")
        }
        return Self(схема: "fum.source-checkpoint-metadata.1", запрос: запрос,
                    автор: автор ?? ИдентификаторGit(имя: "", почта: ""),
                    коммитер: коммитер ?? ИдентификаторGit(имя: "", почта: ""),
                    выход: выход, ошибки: ошибки)
    }
}

public enum ГенераторМетаданныхКоммита {
    private static let неизвестныеТокены: Set<String> = ["unknown", "unavailable", "unset", "null"]
    private static let русскиеБуквы = CharacterSet(charactersIn: "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя")

    public static func проверитьReceipt(
        _ receipt: КвитанцияВыбораМодели?,
        ожидаемый: ОжидаемаяКвитанцияВыбораМодели?,
        expectedRootUUID: String? = nil,
        ожидаемыйДочернийКонтекст: КонтекстОбычногоРебёнка? = nil
    ) -> [String] {
        guard let receipt else { return ["нет-квитанции-api-selection"] }
        guard let ожидаемый else { return ["нет-ожидаемой-квитанции-api-selection"] }
        var ошибки = проверитьСвидетельство(receipt.свидетельство, expectedRootUUID: expectedRootUUID, ожидаемыйДочернийКонтекст: ожидаемыйДочернийКонтекст)
        ошибки.append(contentsOf: проверитьСвидетельство(ожидаемый.свидетельство, expectedRootUUID: expectedRootUUID, ожидаемыйДочернийКонтекст: ожидаемыйДочернийКонтекст))
        do {
            let actualData = try canonicalBytes(receipt.свидетельство)
            let expectedData = try canonicalBytes(ожидаемый.свидетельство)
            let actualBase64 = actualData.base64EncodedString()
            let expectedBase64 = expectedData.base64EncodedString()
            let actualHash = sha256(actualData)
            let expectedHash = sha256(expectedData)
            if receipt.свидетельство != ожидаемый.свидетельство {
                ошибки.append("api-selection-не-совпадает-с-независимым-ожиданием")
            }
            if receipt.canonicalBytesBase64 != actualBase64 || receipt.canonicalBytesBase64 != expectedBase64 {
                ошибки.append("api-selection-canonical-bytes-не-совпадают")
            }
            if receipt.sha256 != actualHash || receipt.sha256 != ожидаемый.sha256 || ожидаемый.sha256 != expectedHash {
                ошибки.append("api-selection-sha256-не-совпадает-с-независимым-ожиданием")
            }
            if ожидаемый.canonicalBytesBase64 != expectedBase64 {
                ошибки.append("ожидаемые-api-selection-bytes-некорректны")
            }
        } catch {
            ошибки.append("api-selection-canonical-encoding-failed")
        }
        return ошибки
    }

    public static func квитанция(для свидетельства: СвидетельствоВыбораМодели) throws -> КвитанцияВыбораМодели {
        let bytes = try canonicalBytes(свидетельства)
        return КвитанцияВыбораМодели(
            свидетельство: свидетельства,
            canonicalBytesBase64: bytes.base64EncodedString(),
            sha256: sha256(bytes)
        )
    }

    public static func ожидание(для свидетельства: СвидетельствоВыбораМодели) throws -> ОжидаемаяКвитанцияВыбораМодели {
        let bytes = try canonicalBytes(свидетельства)
        return ОжидаемаяКвитанцияВыбораМодели(
            свидетельство: свидетельства,
            canonicalBytesBase64: bytes.base64EncodedString(),
            sha256: sha256(bytes)
        )
    }

    public static func проверитьСвидетельствоВыбораМодели(
        _ свидетельство: СвидетельствоВыбораМодели,
        expectedRootUUID: String? = nil,
        ожидаемыйДочернийКонтекст: КонтекстОбычногоРебёнка? = nil
    ) -> [String] {
        проверитьСвидетельство(свидетельство, expectedRootUUID: expectedRootUUID, ожидаемыйДочернийКонтекст: ожидаемыйДочернийКонтекст)
    }

    public static func подготовитьОкружение(
        ожидаемаяИдентичность: ОжидаемаяИдентичностьGit,
        expectedRootUUID: String,
        выходFUMA: ВыходГенератораGitMetadata,
        ожидаемыйДочернийКонтекст: КонтекстОбычногоРебёнка? = nil
    ) -> РезультатПодготовкиОкруженияКоммита {
        var ошибки = проверитьReceipt(
            ожидаемаяИдентичность.квитанцияВыбораМодели,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: expectedRootUUID,
            ожидаемыйДочернийКонтекст: ожидаемыйДочернийКонтекст
        )
        guard let свидетельство = ожидаемаяИдентичность.квитанцияВыбораМодели?.свидетельство else {
            return РезультатПодготовкиОкруженияКоммита(выходFUMA: nil, ошибки: ошибки)
        }
        let expectedAuthorName = имяАвтораДляФорматирования(свидетельство.selectedValue)
        if выходFUMA.environment != ["GIT_AUTHOR_NAME": expectedAuthorName] {
            ошибки.append("fuma-environment-не-совпадает-с-accepted-selection")
        }
        return РезультатПодготовкиОкруженияКоммита(
            выходFUMA: ошибки.isEmpty ? выходFUMA : nil,
            ошибки: ошибки
        )
    }

    public static func проверитьЗаголовок(_ заголовок: String) -> [String] {
        let trimmed = заголовок.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed == заголовок, !заголовок.contains("\n"), !заголовок.contains("\r") else {
            return ["некорректный-однострочный-заголовок-коммита"]
        }
        let числоРусскихБукв = заголовок.unicodeScalars.filter(русскиеБуквы.contains).count
        if числоРусскихБукв < 2 { return ["заголовок-без-русской-темы"] }
        return []
    }

    /// Эталон для сверки с исполненным FUMA definition. Производственное формирование текста выполняет FUMA.

    /// Formatting only, not selection authentication. Receipt validation remains mandatory.
    /// Unknown/invalid selection cannot be rendered as a confirmed model/effort author.
    private static func имяАвтораДляФорматирования(_ выбор: ПараметрыВыбораAPI) -> String {
        guard безопасныйТокен(выбор.model), безопасныйТокен(выбор.reasoningEffort) else {
            return "FUM Codex (выбор UNKNOWN)"
        }
        return "FUM Codex [\(выбор.model); effort=\(выбор.reasoningEffort)]"
    }

    public static func referenceOutput(
        свидетельство: СвидетельствоВыбораМодели,
        план: ПланСообщенияКоммита
    ) -> ВыходГенератораGitMetadata {
        let authorName = имяАвтораДляФорматирования(свидетельство.selectedValue)
        let message = "\(план.заголовок)\n\n\(план.описание)\n\nИсходный запрос:\n\(план.исходныйЗапрос)\n\nCodex-Thread-ID: \(свидетельство.rootUUID)\n"
        return ВыходГенератораGitMetadata(environment: ["GIT_AUTHOR_NAME": authorName], message: message)
    }

    public static func referenceOutput(for input: ПакетВходаГенератораFUMA) -> ПакетВыходаГенератораFUMA {
        ПакетВыходаГенератораFUMA(cases: input.cases.map { item in
            let authorName = имяАвтораДляФорматирования(item.acceptedSelection)
            let message = "\(item.title)\n\n\(item.description)\n\nИсходный запрос:\n\(item.rawRequest)\n\nCodex-Thread-ID: \(item.rootUUID)\n"
            return ВыходСлучаяГенератораFUMA(
                id: item.id,
                environment: ["GIT_AUTHOR_NAME": authorName],
                message: message
            )
        })
    }

    public static func сгенерироватьЭталон(
        ожидаемаяИдентичность: ОжидаемаяИдентичностьGit,
        expectedRootUUID: String,
        authorGitVar: String,
        committerGitVar: String,
        план: ПланСообщенияКоммита,
        выходFUMA: ВыходГенератораGitMetadata,
        ожидаемыйДочернийКонтекст: КонтекстОбычногоРебёнка? = nil
    ) -> РезультатГенерацииМетаданныхКоммита {
        let свидетельство = ожидаемаяИдентичность.квитанцияВыбораМодели?.свидетельство
            ?? emptyWitness(rootUUID: expectedRootUUID)
        var ошибки = проверитьReceipt(
            ожидаемаяИдентичность.квитанцияВыбораМодели,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: expectedRootUUID,
            ожидаемыйДочернийКонтекст: ожидаемыйДочернийКонтекст
        )
        ошибки.append(contentsOf: проверитьЗаголовок(план.заголовок))
        if план.описание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибки.append("пустое-описание-сообщения-коммита")
        }
        if план.исходныйЗапрос.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибки.append("пустой-исходный-запрос-сообщения-коммита")
        }
        let reference = referenceOutput(свидетельство: свидетельство, план: план)
        if outputBytes(выходFUMA) != outputBytes(reference) {
            ошибки.append("fuma-output-не-совпадает-с-swift-reference")
        }

        let author = parseGitIdent(authorGitVar) ?? ИдентификаторGit(имя: "", почта: "")
        let committer = parseGitIdent(committerGitVar) ?? ИдентификаторGit(имя: "", почта: "")
        if parseGitIdent(authorGitVar) == nil { ошибки.append("неразбираемый-git-author-ident") }
        if parseGitIdent(committerGitVar) == nil { ошибки.append("неразбираемый-git-committer-ident") }
        if author.имя != выходFUMA.environment["GIT_AUTHOR_NAME"] {
            ошибки.append("автор-git-var-не-совпадает-с-fuma-environment")
        }
        return РезультатГенерацииМетаданныхКоммита(
            выборМодели: свидетельство,
            автор: author,
            коммитер: committer,
            окружение: выходFUMA.environment,
            сообщение: выходFUMA.message,
            ошибки: ошибки
        )
    }

    public static func разобратьGitIdent(_ строка: String) -> ИдентификаторGit? {
        parseGitIdent(строка)
    }

    public static func bytesForOutput(_ output: ВыходГенератораGitMetadata) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(output)
    }

    public static func bytesForOutput(_ output: ПакетВыходаГенератораFUMA) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(output)
    }

    private static func outputBytes(_ output: ВыходГенератораGitMetadata) -> Data {
        (try? bytesForOutput(output)) ?? Data()
    }

    private static func canonicalBytes(_ witness: СвидетельствоВыбораМодели) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(witness)
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256Hex(_ data: Data) -> String {
        sha256(data)
    }

    private static func проверитьСвидетельство(
        _ свидетельство: СвидетельствоВыбораМодели,
        expectedRootUUID: String?,
        ожидаемыйДочернийКонтекст: КонтекстОбычногоРебёнка?
    ) -> [String] {
        var ошибки: [String] = []
        let currentSchema = свидетельство.схема == "fum.model-selection-receipt.1"
        let legacyChildSchema = свидетельство.схема == "fum.api-selection-receipt.1"
            && свидетельство.источник == .дочернийВызовSpawnAgent
        let обычнаяСхема = свидетельство.схема == "fum.model-selection-receipt.2"
            && свидетельство.источник == .метаданныеДочернегоКлиента
        if ожидаемыйДочернийКонтекст != nil && !обычнаяСхема {
            ошибки.append("ordinary-context-requires-versioned-child-profile")
        }
        if !currentSchema && !legacyChildSchema && !обычнаяСхема { ошибки.append("unsupported-model-selection-receipt-schema") }
        if !обычнаяСхема && свидетельство.дочернийКонтекст != nil { ошибки.append("ordinary-context-in-legacy-profile") }
        if !безопасныйТокен(свидетельство.selectedValue.model) { ошибки.append("selected-model-invalid") }
        if !безопасныйТокен(свидетельство.selectedValue.reasoningEffort) { ошибки.append("selected-effort-invalid") }
        if свидетельство.sessionIdentity.статус != .доступен
            || свидетельство.sessionIdentity.вид != .идентификаторNativeThreadMetadata
            || свидетельство.sessionIdentity.значение == nil {
            ошибки.append("native-session-identity-invalid")
        }
        switch свидетельство.источник {
        case .метаданныеДочернегоКлиента:
            guard обычнаяСхема, let контекст = свидетельство.дочернийКонтекст,
                  let ожидание = ожидаемыйДочернийКонтекст, контекст == ожидание,
                  expectedRootUUID == ожидание.корневойUUID else {
                ошибки.append("ordinary-child-requires-independent-context"); break
            }
            if !каноническийUUID(контекст.корневойUUID) || !каноническийUUID(контекст.сессия) ||
                !каноническийUUID(контекст.непосредственныйРодитель) || контекст.сессия == контекст.корневойUUID ||
                контекст.сессия == контекст.непосредственныйРодитель || контекст.этап.isEmpty || контекст.попытка.isEmpty ||
                контекст.корневойUUID != свидетельство.rootUUID || контекст.сессия != свидетельство.sessionIdentity.значение ||
                контекст.запрошено != свидетельство.requestedSelection ||
                !["UNKNOWN", "accepted", "rejected"].contains(контекст.наблюдённыйACK) {
                ошибки.append("ordinary-child-context-invalid")
            }
            if let запрошено = контекст.запрошено,
                !безопасныйТокен(запрошено.model) || !безопасныйТокен(запрошено.reasoningEffort) {
                ошибки.append("ordinary-child-request-invalid")
            }
            if свидетельство.nativeThread != nil || свидетельство.nativeSelectionSourceSHA256?.count != 64 ||
                свидетельство.nativeSelectionSourceSHA256?.allSatisfy({ "0123456789abcdef".contains($0) }) != true {
                ошибки.append("ordinary-child-source-invalid")
            }
        case .дочернийВызовSpawnAgent:
            guard let requested = свидетельство.requestedSelection,
                  let nativeThread = свидетельство.nativeThread else {
                ошибки.append("child-profile-requires-requested-and-native-thread-metadata")
                break
            }
            if !безопасныйТокен(requested.model) { ошибки.append("requested-model-invalid") }
            if !безопасныйТокен(requested.reasoningEffort) { ошибки.append("requested-effort-invalid") }
            if requested != свидетельство.selectedValue {
                ошибки.append("child-request-and-selected-value-differ")
            }
            if nativeThread.модель != свидетельство.selectedValue.model
                || nativeThread.усилие != свидетельство.selectedValue.reasoningEffort {
                ошибки.append("child-selected-value-does-not-match-native-metadata")
            }
            if nativeThread.threadUUID != свидетельство.sessionIdentity.значение {
                ошибки.append("child-session-identity-does-not-match-native-metadata")
            }
            if nativeThread.agentPath.isEmpty { ошибки.append("child-native-agent-path-empty") }
            if nativeThread.attachedThreadParentIDRaw != ""
                || nativeThread.lineageСтатус != .неизвестно {
                ошибки.append("child-parent-lineage-must-remain-unknown")
            }
            if !каноническийUUID(nativeThread.threadUUID) { ошибки.append("invalid-child-native-thread-uuid") }
            if свидетельство.nativeSelectionSourceSHA256 != nil {
                ошибки.append("child-profile-must-not-claim-native-client-source-hash")
            }
        case .корневыеNativeClientMetadata:
            if свидетельство.requestedSelection != nil {
                ошибки.append("root-profile-must-not-claim-api-requested-selection")
            }
            if свидетельство.nativeThread != nil {
                ошибки.append("root-profile-must-use-bounded-selection-row-only")
            }
            if свидетельство.sessionIdentity.значение != свидетельство.rootUUID {
                ошибки.append("root-native-session-does-not-match-root-uuid")
            }
            guard let sourceHash = свидетельство.nativeSelectionSourceSHA256,
                  sourceHash.count == 64,
                  sourceHash.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
                ошибки.append("root-native-selection-source-hash-invalid")
                break
            }
        }
        if свидетельство.responseIdentity.статус != .недоступен
            || свидетельство.responseIdentity.вид != .идентификаторВызова
            || свидетельство.responseIdentity.значение != nil {
            ошибки.append("api-response-identity-должен-оставаться-unavailable")
        }
        if свидетельство.requestIdentity.статус != .недоступен
            || свидетельство.requestIdentity.вид != .идентификаторВызова
            || свидетельство.requestIdentity.значение != nil {
            ошибки.append("request-identity-должен-быть-явно-unavailable")
        }
        if свидетельство.backendModel != .неизвестно { ошибки.append("backend-model-нельзя-выводить-из-api-selection") }
        if свидетельство.nativeTurnContext != .неизвестно { ошибки.append("native-turn-context-нельзя-выводить-из-api-selection") }
        if !каноническийUUID(свидетельство.rootUUID) { ошибки.append("некорректный-root-uuid") }
        if let expectedRootUUID, свидетельство.rootUUID != expectedRootUUID {
            ошибки.append("receipt-root-uuid-не-совпадает-с-ожиданием")
        }
        return ошибки
    }

    private static func emptyWitness(rootUUID: String) -> СвидетельствоВыбораМодели {
        let unavailable = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
        let unknownParams = ПараметрыВыбораAPI(model: "unknown", reasoningEffort: "unknown")
        return СвидетельствоВыбораМодели(
            источник: .дочернийВызовSpawnAgent,
            rootUUID: rootUUID,
            sessionIdentity: unavailable,
            requestIdentity: unavailable,
            responseIdentity: unavailable,
            nativeThread: nil,
            requestedSelection: unknownParams,
            selectedValue: unknownParams,
            backendModel: .неизвестно,
            nativeTurnContext: .неизвестно
        )
    }

    private static func parseGitIdent(_ string: String) -> ИдентификаторGit? {
        guard let leftBracket = string.range(of: " <", options: .backwards),
              let rightBracket = string[leftBracket.upperBound...].firstIndex(of: ">") else { return nil }
        let name = String(string[..<leftBracket.lowerBound])
        let email = String(string[leftBracket.upperBound..<rightBracket])
        guard !name.isEmpty, !email.isEmpty else { return nil }
        return ИдентификаторGit(имя: name, почта: email)
    }

    private static func каноническийUUID(_ value: String) -> Bool {
        guard let uuid = UUID(uuidString: value) else { return false }
        return value == uuid.uuidString.lowercased()
    }

    private static func безопасныйТокен(_ value: String) -> Bool {
        let bytes = Array(value.utf8)
        guard (1...128).contains(bytes.count), bytes.first.map(letterOrDigitASCII) == true,
              bytes.allSatisfy({ letterOrDigitASCII($0) || $0 == 46 || $0 == 95 || $0 == 45 }) else {
            return false
        }
        return !неизвестныеТокены.contains(value.lowercased())
    }

    private static func letterOrDigitASCII(_ byte: UInt8) -> Bool {
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
    }
}

// Допуск не меняет wire DTO форматтера. Решение хоста не декодируется из запроса.
enum ПрофильУправляемогоВызова: String, Codable, Sendable { case исходники, подтверждённый, проверка, неизвестно }
enum ОперацияУправляемогоВызова: String, Codable, Sendable {
    case исходники, квитанцияКлиента, проверкаГенератора, проверкаКлиента, метаданные, сыройКоммитСлияния, сыройКоммит, постЭффект, запрещено
}
enum РольВходаУправления: String, Codable, Hashable, Sendable {
    case запрос, метаданные, состояние, фикстура, источник, ожидание, текущее, стандартныйВвод
    case проверяющий, исполнительГит, определение, оператор, кореньЗапуска, квитанция, публичнаяПроекция, временныйКорень, черновик, публичноеТело
}
struct ПинУправляемогоВхода: Codable, Equatable, Sendable {
    let роль: РольВходаУправления
    let путь: String
    let устройство: UInt64
    let узел: UInt64
    let владелец: UInt32
    let режимДоступа: UInt32
    let байтов: Int
    let хэш: String
    let каталог: Bool
    let новыйЛист: String?
}
struct ОсноваВременнойОбласти: Codable, Equatable, Sendable {
    let источник: String
    let наблюдавшийПроцесс: Int32
    let область: String
    let адресФонда: String
    let физическийКорень: String
    let владелец: UInt32
}
struct ИдентичностьИсходникаДопуска: Codable, Equatable, Sendable { let байтов: Int; let хэш: String }
enum РольИсходникаДопуска: String, Codable, Sendable { case полный, полныйФУМА, диапазонНативного }
struct ДиапазонИсполненногоИсходника: Codable, Equatable, Sendable {
    let каноническийПуть: String
    let роль: РольИсходникаДопуска
    let скомпилированныйПуть: String
    let полный: ИдентичностьИсходникаДопуска
    let смещение: Int
    let длина: Int
    let результат: ИдентичностьИсходникаДопуска
    let исключённыйПрефикс: String
}
struct ВыборДереваИсходников: Codable, Equatable, Sendable {
    let корень: ПинУправляемогоВхода
    let коммит: String
    let дерево: String
    let блоб: String
}
struct ЧленПоставкиИсходников: Codable, Equatable, Sendable {
    let манифест: ПинУправляемогоВхода
    let файл: ПинУправляемогоВхода
}
struct МанифестЧленаПоставки: Codable, Equatable, Sendable {
    let схема: String
    let каноническийПуть: String
    let режим: String
    let идентичность: ИдентичностьИсходникаДопуска
}
struct ПокрытиеИсполненногоИсходника: Codable, Equatable, Sendable {
    let путь: String
    let роль: РольИсходникаДопуска
    let режим: String
    let исполненный: ИдентичностьИсходникаДопуска
    let требуемый: ИдентичностьИсходникаДопуска
    let скомпилированный: ПинУправляемогоВхода
    let дерево: ВыборДереваИсходников?
    let поставка: ЧленПоставкиИсходников?
    let диапазон: ДиапазонИсполненногоИсходника?
}
struct ЗапросДопускаУправляемогоВызова: Codable, Equatable, Sendable {
    let схема: String
    let профиль: ПрофильУправляемогоВызова
    let операция: ОперацияУправляемогоВызова
    let корневойUUID: String
    let писатель: String
    let область: String
    let попытка: String
    let аргументы: [String]
    let версияГит: String
    let кодПолитикиГит: String
    let хэшПроверяющего: String
    let пины: [ПинУправляемогоВхода]
    let хэшВхода: String
    let хэшПубличногоТела: String?
    let политикаТела: String
    let временнаяОснова: ОсноваВременнойОбласти?
    let покрытие: [ПокрытиеИсполненногоИсходника]
    let пределБайт: Int
    let окружение: [String: String]
    func каноническиеБайты() throws -> Data {
        let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try кодировщик.encode(self)
    }
    func каноническийХэш() throws -> String { ГенераторМетаданныхКоммита.sha256Hex(try каноническиеБайты()) }
    func сОперацией(_ описание: СпецификацияУправляемойОперации, значения: [РольВходаУправления: String], корневойUUID: String) throws -> Self {
        Self(схема: схема, профиль: описание.профиль, операция: описание.операция, корневойUUID: self.корневойUUID,
            писатель: писатель, область: область, попытка: попытка, аргументы: try описание.аргументы(значения, корневойUUID: корневойUUID),
            версияГит: версияГит, кодПолитикиГит: кодПолитикиГит, хэшПроверяющего: хэшПроверяющего, пины: пины, хэшВхода: хэшВхода,
            хэшПубличногоТела: хэшПубличногоТела, политикаТела: политикаТела, временнаяОснова: временнаяОснова,
            покрытие: покрытие, пределБайт: пределБайт, окружение: окружение)
    }
}
struct РешениеХостаУправляемогоВызова: Equatable, Sendable {
    enum Статус: Equatable, Sendable { case разрешено, неизвестно, запрещено }
    let статус: Статус
    let хэшЗапроса: String
    let операция: ОперацияУправляемогоВызова
    let писатель: String
    let область: String
    let разрешённыеДиапазоны: [ДиапазонИсполненногоИсходника]
    let допускЧтенияГит: НезависимыйДопускЧтенияГит?
}
enum ОтказУправляемогоДопуска: Error, Equatable { case неизвестно(String), отказ(String), публикация(String), стопПередЗапуском }

// Единственный источник формы argv, профиля, ролей и тестовой матрицы.
struct СпецификацияУправляемойОперации: Sendable {
    enum Поле: Sendable { case флаг(String), вход(РольВходаУправления), выход(РольВходаУправления), корневойUUID }
    let имя: String
    let операция: ОперацияУправляемогоВызова
    let профиль: ПрофильУправляемогоВызова
    let поля: [Поле]
    let стандартныйВвод: Bool
    func аргументы(_ значения: [РольВходаУправления: String], корневойUUID: String) throws -> [String] {
        try поля.map { поле in
            switch поле {
            case let .флаг(текст): return текст
            case .корневойUUID: return корневойUUID
            case let .вход(роль), let .выход(роль):
                guard let путь = значения[роль] else { throw ОтказУправляемогоДопуска.отказ("нет-значения-роли") }; return путь
            }
        }
    }
    func соответствует(_ аргументы: [String]) -> Bool {
        guard аргументы.count == поля.count else { return false }
        return zip(поля, аргументы).allSatisfy { поле, аргумент in
            if case let .флаг(текст) = поле { return текст == аргумент }
            return !аргумент.isEmpty && !аргумент.hasPrefix("--")
        }
    }
    static let все: [Self] = [
        Self(имя: "исходники-генерация", операция: .исходники, профиль: .исходники, поля: [.флаг("--сгенерировать-метаданные-коммита"), .вход(.запрос), .флаг("--исходники-UNKNOWN")], стандартныйВвод: false),
        Self(имя: "исходники-перед-коммитом", операция: .исходники, профиль: .исходники, поля: [.флаг("--проверить-перед-коммитом"), .вход(.запрос), .вход(.метаданные), .флаг("--исходники-UNKNOWN")], стандартныйВвод: false),
        Self(имя: "исходники-сырой-коммит", операция: .исходники, профиль: .исходники, поля: [.флаг("--проверить-сырой-коммит-исходников"), .вход(.запрос), .вход(.метаданные)], стандартныйВвод: true),
        Self(имя: "квитанция-клиента", операция: .квитанцияКлиента, профиль: .проверка, поля: [.флаг("--сохранить-квитанцию-root-native-client"), .вход(.источник), .вход(.ожидание), .вход(.текущее), .корневойUUID, .выход(.квитанция), .выход(.публичнаяПроекция)], стандартныйВвод: false),
        Self(имя: "проверка-генератора", операция: .проверкаГенератора, профиль: .проверка, поля: [.флаг("--проверить-fuma-генератор"), .вход(.определение), .вход(.фикстура), .вход(.оператор), .вход(.кореньЗапуска)], стандартныйВвод: false),
        Self(имя: "проверка-клиента", операция: .проверкаКлиента, профиль: .проверка, поля: [.флаг("--проверить-fuma-root-native-client"), .вход(.определение), .вход(.фикстура), .вход(.оператор), .вход(.кореньЗапуска), .вход(.источник), .вход(.ожидание), .вход(.текущее), .корневойUUID, .выход(.квитанция)], стандартныйВвод: false),
        Self(имя: "подтверждённая-генерация", операция: .метаданные, профиль: .подтверждённый, поля: [.флаг("--сгенерировать-метаданные-коммита"), .вход(.состояние)], стандартныйВвод: false),
        Self(имя: "подтверждённый-перед-коммитом", операция: .метаданные, профиль: .подтверждённый, поля: [.флаг("--проверить-перед-коммитом"), .вход(.состояние)], стандартныйВвод: false),
        Self(имя: "сырой-коммит-слияния", операция: .сыройКоммитСлияния, профиль: .подтверждённый, поля: [.флаг("--проверить-сырой-merge-коммит"), .вход(.состояние), .вход(.ожидание)], стандартныйВвод: true),
        Self(имя: "сырой-коммит", операция: .сыройКоммит, профиль: .подтверждённый, поля: [.флаг("--проверить-сырой-коммит"), .вход(.состояние)], стандартныйВвод: true),
        Self(имя: "пост-эффект", операция: .постЭффект, профиль: .подтверждённый, поля: [.флаг("--проверить-пост-эффектный-git"), .вход(.состояние), .вход(.ожидание)], стандартныйВвод: false)
    ]
    static func выбрать(_ аргументы: [String]) -> Self? { все.first { $0.соответствует(аргументы) } }
}

enum ПолитикаУправляемогоДопуска {
    static func хэшВерный(_ строка: String) -> Bool { строка.utf8.count == 64 && строка.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) } }
    static func предел(_ роль: РольВходаУправления, запрошенный: Int) -> Int {
        [.оператор, .проверяющий, .исполнительГит].contains(роль) ? 512 * 1_048_576 : запрошенный
    }
    static func проверить(_ запрос: ЗапросДопускаУправляемогоВызова?, _ решение: РешениеХостаУправляемогоВызова?, операция: ОперацияУправляемогоВызова) throws {
        // ADMISSION_POLICY_BEGIN
        guard let запрос, let решение, решение.статус == .разрешено else { throw ОтказУправляемогоДопуска.неизвестно("нет-независимого-решения") }
        guard запрос.схема == "fum.управляемый-допуск.3", let описание = СпецификацияУправляемойОперации.выбрать(запрос.аргументы),
              описание.операция == операция, описание.профиль == запрос.профиль, запрос.операция == операция,
              решение.операция == операция, решение.хэшЗапроса == (try запрос.каноническийХэш()),
              решение.писатель == запрос.писатель, решение.область == запрос.область,
              UUID(uuidString: запрос.корневойUUID) != nil, UUID(uuidString: запрос.писатель) != nil, UUID(uuidString: запрос.область) != nil,
              запрос.попытка.range(of: "^[a-z0-9][a-z0-9-]{0,127}$", options: .regularExpression) != nil,
              (1...16_777_216).contains(запрос.пределБайт), хэшВерный(запрос.хэшВхода),
              Set(запрос.пины.map(\.роль)).count == запрос.пины.count, !запрос.пины.isEmpty else { throw ОтказУправляемогоДопуска.отказ("связь-запроса") }
        for пин in запрос.пины {
            guard пин.байтов >= 0, пин.байтов <= предел(пин.роль, запрошенный: запрос.пределБайт), хэшВерный(пин.хэш),
                  (пин.путь == "stdin" ? пин.роль == .стандартныйВвод : пин.путь.hasPrefix("/") && !пин.путь.contains("\0")),
                  пин.новыйЛист.map({ пин.каталог && !$0.isEmpty && !$0.contains("/") && ![".", ".."].contains($0) }) ?? true else {
                throw ОтказУправляемогоДопуска.отказ("пин-роли")
            }
        }
        guard запрос.версияГит.hasPrefix("git version "), !запрос.версияГит.contains("\n"),
              запрос.пины.contains(where: { $0.роль == .проверяющий && $0.хэш == запрос.хэшПроверяющего }),
              запрос.пины.contains(where: { $0.роль == .исполнительГит && $0.путь == "/usr/bin/git" && !$0.каталог && $0.режимДоступа & 0o111 != 0 }) else { throw ОтказУправляемогоДопуска.отказ("пины-инструментов") }
        let ключи: Set<String> = ["CODEX_THREAD_ID", "PATH", "HOME", "TMPDIR", "LANG", "LC_ALL", "GIT_CONFIG_NOSYSTEM", "GIT_CONFIG_SYSTEM", "GIT_CONFIG_GLOBAL", "KOORDINACIYA_FUMA_DEFINITION", "KOORDINACIYA_FUMA_OPERATOR", "KOORDINACIYA_FUMA_RUN_ROOT", "GIT_NO_LAZY_FETCH", "GIT_OPTIONAL_LOCKS", "GIT_NO_REPLACE_OBJECTS", "GIT_TERMINAL_PROMPT", "GIT_ALLOW_PROTOCOL", "GIT_ASKPASS", "SSH_ASKPASS", "GIT_COMMON_DIR"]
        guard Set(запрос.окружение.keys).isSubset(of: ключи), запрос.окружение.values.allSatisfy({ !$0.contains("\0") }), !запрос.покрытие.isEmpty else { throw ОтказУправляемогоДопуска.отказ("окружение-или-пустое-покрытие") }
        try ПолитикаБезэффектногоЧтенияГит.проверить(запрос, решение: решение)
        try ЧистаяПроверкаФактическогоВызова.ролиЗапроса(запрос)
        // ADMISSION_POLICY_END
    }
    static func проверитьПубличноеТело(_ байты: Data, хэш: String, политика: String) throws {
        // PUBLICATION_POLICY_BEGIN
        guard ГенераторМетаданныхКоммита.sha256Hex(байты) == хэш else { throw ОтказУправляемогоДопуска.отказ("хэш-публичного-тела") }
        let закреплённые = ["ec315e079dfeffa49dd5a72203b705d23b6bf0d6610577abfdc352c646d28c33", "e32c6564ece67963600ef6b1ec8ba5b15ca6d86c4d7a6810474caff8374fb6b0"]
        let объект = try JSONSerialization.jsonObject(with: байты, options: [.fragmentsAllowed])
        if политика == "canonical-typed-test" {
            let канон = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
            guard канон == байты else { throw ОтказУправляемогоДопуска.неизвестно("неподдержанный-JSON-формат") }
        } else if политика != "exact-selected-bodies" || !закреплённые.contains(хэш) { throw ОтказУправляемогоДопуска.неизвестно("неподдержанная-JSON-политика") }
        func ключПути(_ ключ: String) throws -> String {
            // Bracket notation uses JSON string escaping, including quotes and backslashes.
            let байтыКлюча = try JSONSerialization.data(withJSONObject: ключ, options: [.fragmentsAllowed, .withoutEscapingSlashes])
            return "[" + String(decoding: байтыКлюча, as: UTF8.self) + "]"
        }
        func обход(_ значение: Any, _ путь: String) throws {
            if let строка = значение as? String {
                if ["/Users/", "/home/", "/private/var/", "file:///Users/", "C:\\Users\\"].contains(where: { строка.contains($0) }) { throw ОтказУправляемогоДопуска.публикация(путь) }
            } else if let массив = значение as? [Any] {
                for (номер, элемент) in массив.enumerated() { try обход(элемент, путь + "[\(номер)]") }
            } else if let словарь = значение as? [String: Any] {
                for ключ in словарь.keys.sorted() { try обход(словарь[ключ]!, путь + ключПути(ключ)) }
            }
        }
        try обход(объект, "$")
        // PUBLICATION_POLICY_END
    }
}

// Не Codable. Парсерный факт не повышается до semantic no-fetch admission.
// Production provider отсутствует; TESTING выбирает отдельные синтетические доказательства.
struct НезависимыйДопускЧтенияГит: Equatable, Sendable {
    enum Уровень: Equatable, Sendable { case толькоРаспознаваниеФлагов, независимоПровереннаяСемантика }
    let инструмент: ПинУправляемогоВхода
    let версия: String
    let уровень: Уровень
    let хэшПарсерногоДоказательства: String
    let хэшСемантическогоДоказательства: String?
    var физическийКонтекст: ФизическийКонтекстГит? = nil
}

// Отдельный non-Codable результат host preflight, не DATA locator и не .git text.
// Production issuer/provider отсутствует: вне TESTING нет фабрики выдачи.
struct КортежФизическогоГит: Equatable, Sendable {
    let коммит: String
    let дерево: String
    let блоб: String
    let путь: String
}
struct ФизическийКонтекстГит: Equatable, Sendable {
    let издатель: String
    let писатель: String
    let область: String
    let хэшЗапроса: String
    let корень: ПинУправляемогоВхода
    let рабочееДерево: ПинУправляемогоВхода
    let админ: ПинУправляемогоВхода
    let общийАдмин: ПинУправляемогоВхода
    let кортежи: [КортежФизическогоГит]
    let внеРепозитория: [ПинУправляемогоВхода]
    private init(издатель: String, писатель: String, область: String, хэшЗапроса: String,
        корень: ПинУправляемогоВхода, рабочееДерево: ПинУправляемогоВхода,
        админ: ПинУправляемогоВхода, общийАдмин: ПинУправляемогоВхода,
        кортежи: [КортежФизическогоГит], внеРепозитория: [ПинУправляемогоВхода]) {
        self.издатель = издатель; self.писатель = писатель; self.область = область; self.хэшЗапроса = хэшЗапроса
        self.корень = корень; self.рабочееДерево = рабочееДерево; self.админ = админ; self.общийАдмин = общийАдмин
        self.кортежи = кортежи; self.внеРепозитория = внеРепозитория
    }
    var доверенныйИздатель: Bool {
        #if TESTING
        return издатель == "synthetic-physical-Git-test-issuer-v1"
        #else
        return false
        #endif
    }
    var явныйАдрес: [String] { ["--git-dir=" + админ.путь, "--work-tree=" + рабочееДерево.путь] }
    var пины: [ПинУправляемогоВхода] { [корень, рабочееДерево, админ, общийАдмин] + внеРепозитория }
    #if TESTING
    static func проверочный(издатель: String = "synthetic-physical-Git-test-issuer-v1", писатель: String,
        область: String, хэшЗапроса: String, корень: ПинУправляемогоВхода, рабочееДерево: ПинУправляемогоВхода,
        админ: ПинУправляемогоВхода, общийАдмин: ПинУправляемогоВхода,
        кортежи: [КортежФизическогоГит], внеРепозитория: [ПинУправляемогоВхода]) -> Self {
        Self(издатель: издатель, писатель: писатель, область: область, хэшЗапроса: хэшЗапроса,
            корень: корень, рабочееДерево: рабочееДерево, админ: админ, общийАдмин: общийАдмин,
            кортежи: кортежи, внеРепозитория: внеРепозитория)
    }
    #endif
}

struct ПодготовленнаяКомандаЧтенияГит {
    let аргументы: [String]
    let окружение: [String: String]
}
enum ПолитикаБезэффектногоЧтенияГит {
    static let код = "fum.git-read.no-fetch-no-locks.1"
    static let флаги = ["--no-optional-locks", "--no-lazy-fetch", "--no-replace-objects", "--literal-pathspecs"]
    static let обязательноеОкружение = [
        "PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C", "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_SYSTEM": "/dev/null", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_NO_LAZY_FETCH": "1",
        "GIT_OPTIONAL_LOCKS": "0", "GIT_NO_REPLACE_OBJECTS": "1", "GIT_TERMINAL_PROMPT": "0",
        "GIT_ALLOW_PROTOCOL": "", "GIT_ASKPASS": "/usr/bin/false", "SSH_ASKPASS": "/usr/bin/false"
    ]
    static func проверить(_ запрос: ЗапросДопускаУправляемогоВызова, решение: РешениеХостаУправляемогоВызова) throws {
        // GIT_POLICY_BEGIN
        guard решение.статус == .разрешено, решение.хэшЗапроса == (try запрос.каноническийХэш()),
              решение.операция == запрос.операция, решение.писатель == запрос.писатель, решение.область == запрос.область else {
            throw ОтказУправляемогоДопуска.неизвестно("нет-связанного-допуска-чтения-гит")
        }
        guard запрос.кодПолитикиГит == код,
              обязательноеОкружение.allSatisfy({ запрос.окружение[$0.key] == $0.value }) else { throw ОтказУправляемогоДопуска.отказ("неполная-политика-чтения-гит") }
        guard let допуск = решение.допускЧтенияГит else { throw ОтказУправляемогоДопуска.неизвестно("нет-независимого-допуска-гит") }
        guard запрос.пины.first(where: { $0.роль == .исполнительГит }) == допуск.инструмент,
              допуск.инструмент.путь == "/usr/bin/git", допуск.версия == запрос.версияГит,
              ПолитикаУправляемогоДопуска.хэшВерный(допуск.хэшПарсерногоДоказательства),
              допуск.хэшПарсерногоДоказательства != String(repeating: "0", count: 64) else { throw ОтказУправляемогоДопуска.отказ("связь-инструмента-и-допуска-гит") }
        guard допуск.уровень == .независимоПровереннаяСемантика,
              let семантическийХэш = допуск.хэшСемантическогоДоказательства,
              ПолитикаУправляемогоДопуска.хэшВерный(семантическийХэш), семантическийХэш != String(repeating: "0", count: 64),
              семантическийХэш != допуск.хэшПарсерногоДоказательства else { throw ОтказУправляемогоДопуска.неизвестно("семантика-no-fetch-не-доказана") }
        // GIT_POLICY_END
    }

    static func физическийКонтекст(_ запрос: ЗапросДопускаУправляемогоВызова, решение: РешениеХостаУправляемогоВызова) throws -> ФизическийКонтекстГит {
        guard let контекст = решение.допускЧтенияГит?.физическийКонтекст else {
            throw ОтказУправляемогоДопуска.неизвестно("нет-выданного-физического-контекста-гит")
        }
        // PHYSICAL_GIT_BINDING_BEGIN
        guard контекст.доверенныйИздатель, контекст.писатель == запрос.писатель, контекст.область == запрос.область,
              контекст.хэшЗапроса == (try запрос.каноническийХэш()), контекст.корень == контекст.рабочееДерево,
              запрос.окружение["GIT_COMMON_DIR"] == контекст.общийАдмин.путь,
              контекст.админ.путь != контекст.корень.путь, контекст.общийАдмин.путь != контекст.корень.путь,
              контекст.пины.allSatisfy({ пин in
                  пин.каталог && пин.новыйЛист == nil && пин.владелец == контекст.корень.владелец &&
                  пин.устройство > 0 && пин.узел > 0 && пин.путь.hasPrefix("/") &&
                  !пин.путь.contains("\0") && !пин.путь.contains("\n") && !пин.путь.contains("\r") &&
                  !пин.путь.split(separator: "/", omittingEmptySubsequences: false).dropFirst().contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
              }) else { throw ОтказУправляемогоДопуска.отказ("связь-физического-контекста-гит") }
        for строка in запрос.покрытие {
            if let дерево = строка.дерево {
                let кортеж = КортежФизическогоГит(коммит: дерево.коммит, дерево: дерево.дерево, блоб: дерево.блоб, путь: строка.путь)
                guard дерево.корень == контекст.корень, контекст.кортежи.contains(кортеж) else {
                    throw ОтказУправляемогоДопуска.отказ("чужой-корень-или-кортеж-гит")
                }
            }
        }
        // PHYSICAL_GIT_BINDING_END
        return контекст
    }
    static func рабочийКаталогКоманды(_ аргументы: [String]) throws -> String {
        guard Array(аргументы.prefix(4)) == флаги, аргументы.count >= 7,
              аргументы[4].hasPrefix("--git-dir=/"), аргументы[5].hasPrefix("--work-tree=/") else {
            throw ОтказУправляемогоДопуска.отказ("нет-явного-адреса-команды-гит")
        }
        return String(аргументы[5].dropFirst("--work-tree=".count))
    }
    static func командаРазрешена(_ аргументы: [String], запрос: ЗапросДопускаУправляемогоВызова,
        контекст: ФизическийКонтекстГит) -> Bool {
        guard Array(аргументы.prefix(2)) == контекст.явныйАдрес else { return false }
        let команда = Array(аргументы.dropFirst(2))
        if [["--version"], ["rev-parse", "HEAD"], ["rev-parse", "--show-toplevel"], ["rev-parse", "--path-format=absolute", "--show-toplevel"],
            ["symbolic-ref", "HEAD"], ["var", "GIT_AUTHOR_IDENT"], ["var", "GIT_COMMITTER_IDENT"]].contains(команда) { return true }
        func объект(_ строка: String) -> Bool { строка.utf8.count == 40 && строка.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) } }
        for кортеж in контекст.кортежи {
            guard запрос.покрытие.contains(where: { строка in
                guard let дерево = строка.дерево else { return false }
                return дерево.корень == контекст.корень && дерево.коммит == кортеж.коммит &&
                    дерево.дерево == кортеж.дерево && дерево.блоб == кортеж.блоб && строка.путь == кортеж.путь
            }) else { continue }
            if объект(кортеж.коммит), команда == ["rev-parse", "--verify", кортеж.коммит + "^{commit}"] || команда == ["rev-parse", "--verify", кортеж.коммит + "^{tree}"] { return true }
            if объект(кортеж.блоб), команда == ["cat-file", "blob", кортеж.блоб] { return true }
            if объект(кортеж.дерево), команда == ["ls-tree", "--full-tree", "--full-name", "-z", кортеж.дерево, "--", кортеж.путь] { return true }
        }
        return false
    }
    static func подготовить(_ запрос: ЗапросДопускаУправляемогоВызова, решение: РешениеХостаУправляемогоВызова,
                            аргументы: [String], окружение: [String: String]) throws -> ПодготовленнаяКомандаЧтенияГит {
        try проверить(запрос, решение: решение)
        // GIT_COMMAND_BEGIN
        let контекст = try физическийКонтекст(запрос, решение: решение)
        guard командаРазрешена(аргументы, запрос: запрос, контекст: контекст) else { throw ОтказУправляемогоДопуска.отказ("команда-вне-контура-чтения-гит") }
        let ключи = Set(запрос.окружение.keys).union(["GIT_AUTHOR_NAME", "GIT_AUTHOR_EMAIL", "GIT_AUTHOR_DATE", "GIT_COMMITTER_NAME", "GIT_COMMITTER_EMAIL", "GIT_COMMITTER_DATE"])
        guard Set(окружение.keys).isSubset(of: ключи), окружение.values.allSatisfy({ !$0.contains("\0") }),
              обязательноеОкружение.allSatisfy({ окружение[$0.key] == $0.value }),
              окружение["GIT_COMMON_DIR"] == контекст.общийАдмин.путь,
              !аргументы.contains(where: { $0.contains("\0") }) else { throw ОтказУправляемогоДопуска.отказ("окружение-команды-чтения-гит") }
        // GIT_COMMAND_END
        return ПодготовленнаяКомандаЧтенияГит(аргументы: флаги + аргументы, окружение: окружение)
    }
}

// Только значения и hash; здесь нет URL resolution, stat, чтения или Git.
enum ЧистаяПроверкаФактическогоВызова {
    static func ролиЗапроса(_ запрос: ЗапросДопускаУправляемогоВызова) throws {
        guard let описание = СпецификацияУправляемойОперации.выбрать(запрос.аргументы) else { throw ОтказУправляемогоДопуска.отказ("форма-запроса") }
        for (номер, поле) in описание.поля.enumerated() {
            let аргумент = запрос.аргументы[номер]
            switch поле {
            case let .вход(роль):
                guard запрос.пины.contains(where: { $0.роль == роль && $0.путь == аргумент }) else { throw ОтказУправляемогоДопуска.отказ("роль-входа-запроса") }
            case let .выход(роль):
                guard аргумент.hasPrefix("/"), let косая = аргумент.lastIndex(of: "/") else { throw ОтказУправляемогоДопуска.отказ("роль-выхода-запроса") }
                let родитель = косая == аргумент.startIndex ? "/" : String(аргумент[..<косая])
                let лист = String(аргумент[аргумент.index(after: косая)...])
                guard запрос.пины.contains(where: { $0.роль == роль && $0.путь == родитель && $0.новыйЛист == лист }) else { throw ОтказУправляемогоДопуска.отказ("роль-выхода-запроса") }
            case .корневойUUID:
                guard аргумент == запрос.корневойUUID else { throw ОтказУправляемогоДопуска.отказ("корневой-UUID-запроса") }
            case .флаг: break
            }
        }
        if описание.стандартныйВвод && !запрос.пины.contains(where: { $0.роль == .стандартныйВвод && $0.путь == "stdin" }) { throw ОтказУправляемогоДопуска.отказ("нет-роли-stdin") }
    }
    static func вход(_ аргументы: [String], запрос: ЗапросДопускаУправляемогоВызова?, решение: РешениеХостаУправляемогоВызова?) throws -> ОперацияУправляемогоВызова {
        try ПолитикаУправляемогоДопуска.проверить(запрос, решение, операция: запрос?.операция ?? .запрещено)
        let допущеннаяОперация = запрос?.операция ?? .запрещено
        // ACTUAL_ENTRY_BEGIN
        guard let запрос, let описание = СпецификацияУправляемойОперации.выбрать(аргументы),
              запрос.аргументы == аргументы, описание.операция == запрос.операция, описание.профиль == запрос.профиль else {
            throw ОтказУправляемогоДопуска.отказ("фактические-argv-не-допущены")
        }
        // ACTUAL_ENTRY_END
        return допущеннаяОперация
    }
    static func исполнитель(запрос: ЗапросДопускаУправляемогоВызова?, решение: РешениеХостаУправляемогоВызова?,
                            определение: String, оператор: String, кореньЗапуска: String) throws {
        try ПолитикаУправляемогоДопуска.проверить(запрос, решение, операция: запрос?.операция ?? .запрещено)
        // ACTUAL_RUNNER_BEGIN
        guard let запрос,
              let пинОпределения = запрос.пины.first(where: { $0.роль == .определение }), пинОпределения.путь == определение, !пинОпределения.каталог,
              let пинОператора = запрос.пины.first(where: { $0.роль == .оператор }), пинОператора.путь == оператор, !пинОператора.каталог, пинОператора.режимДоступа & 0o111 != 0,
              let пинКорня = запрос.пины.first(where: { $0.роль == .кореньЗапуска }), пинКорня.путь == кореньЗапуска, пинКорня.каталог, пинКорня.режимДоступа == 0o700 else {
            throw ОтказУправляемогоДопуска.отказ("фактические-параметры-исполнителя-не-допущены")
        }
        // ACTUAL_RUNNER_END
    }
}


// Native saved configuration is observational data, never backend attestation or authority.

struct ПривязкаНативногоЧата: Equatable, Sendable {
    // Supplied separately by trusted ROOT/native transport caller, never decoded from profile JSON.
    // This value records that boundary; it does not authenticate itself or grant authority.
    let нативныйЧатUUID: String
    let исполнительныйТактUUID: String?
    let источникПривязки: String
}

struct ПрофильНативнойКонфигурации: Codable, Equatable, Sendable {
    struct База: Codable, Equatable, Sendable {
        let путь: String
        let устройство: UInt64
        let узел: UInt64
        let владелец: UInt32
        let режим: UInt32
    }
    let схема: String
    let нативныйЧатUUID: String
    let инструмент: ПинУправляемогоВхода
    let база: База
    let поколениеИзвестнойСмены: String
    let запрошено: ПараметрыВыбораAPI?
}
struct СырыеБайтыНативнойКонфигурации {
    let строка: Data
    let отпечаток: String
    let наблюденоМс: Int64
}
struct НаблюдениеНативнойКонфигурации: Encodable, Equatable, Sendable {
    let схема = "fum.native-own-model-configuration.observation.1"
    let нативныйЧатUUID: String
    let поставщик: String
    let значение: ПараметрыВыбораAPI
    let запрошено: ПараметрыВыбораAPI?
    let совпадаетСЗапрошенным: Bool?
    let обновленоСек: Int64
    let обновленоМс: Int64
    let наблюденоМс: Int64
    let наблюденоUTC: String
    let отпечатокИсточника: String
    let поколениеИзвестнойСмены: String
    let режимИсточника: String
    let backend = "UNKNOWN"
    let исполнительныйТактUUID: String?
    let источникПривязки: String
    let наблюдённыйENVThreadID: String?
    let связьENVСЧатом: String
    // Row revision time does not date a model change. Caller event generation is separate.
    func совпадаетСКонтекстом(сессия: String, поколениеИзвестнойСмены: String) -> Bool {
        self.нативныйЧатUUID == сессия && self.поколениеИзвестнойСмены == поколениеИзвестнойСмены
    }
    fileprivate init(сессия: String, поставщик: String, значение: ПараметрыВыбораAPI, запрошено: ПараметрыВыбораAPI?,
        обновленоСек: Int64, обновленоМс: Int64, наблюденоМс: Int64, отпечаток: String, поколение: String, режим: String, привязка: ПривязкаНативногоЧата, ENVThreadID: String?) {
        self.нативныйЧатUUID = сессия; self.поставщик = поставщик; self.значение = значение; self.запрошено = запрошено
        совпадаетСЗапрошенным = запрошено.map { $0 == значение }
        self.обновленоСек = обновленоСек; self.обновленоМс = обновленоМс; self.наблюденоМс = наблюденоМс
        let формат = ISO8601DateFormatter(); формат.timeZone = TimeZone(secondsFromGMT: 0)
        наблюденоUTC = формат.string(from: Date(timeIntervalSince1970: Double(наблюденоМс) / 1000))
        отпечатокИсточника = отпечаток; поколениеИзвестнойСмены = поколение; режимИсточника = режим
        исполнительныйТактUUID = привязка.исполнительныйТактUUID; источникПривязки = привязка.источникПривязки
        наблюдённыйENVThreadID = ENVThreadID.map { String($0.prefix(128)) }
        связьENVСЧатом = ENVThreadID == сессия ? "ENV_VALUE_MATCHES_CHAT_UUID_TURN_SEMANTICS_UNKNOWN" : "UNKNOWN_DIFFERENT_OR_MISSING_ENV_ID"
    }
}
enum ПровайдерНативнойКонфигурации {
    static let поля: Set<String> = ["id", "model_provider", "model", "reasoning_effort", "updated_at", "updated_at_ms"]
    static let пределВывода = 16_384
    static let таймаутВызоваМс = 5_000
    static let окружение = ["PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C", "HOME": "/dev/null"]
    static func каноническийUUID(_ значение: String) throws -> String {
        guard let идентификатор = UUID(uuidString: значение), идентификатор.uuidString.lowercased() == значение else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-invalid-own-UUID")
        }
        return значение
    }

    static func сверитьПривязку(_ запрошенныйЧат: String, назначение: ПривязкаНативногоЧата,
        наблюдённыйENVThreadID: String?) throws -> String {
        _ = try каноническийUUID(назначение.нативныйЧатUUID)
        if let такт = назначение.исполнительныйТактUUID { _ = try каноническийUUID(такт) }
        guard запрошенныйЧат == назначение.нативныйЧатUUID,
              !назначение.источникПривязки.isEmpty, назначение.источникПривязки.utf8.count <= 256 else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-profile-not-trusted-native-chat-assignment")
        }
        return наблюдённыйENVThreadID == назначение.нативныйЧатUUID
            ? "ENV_VALUE_MATCHES_CHAT_UUID_TURN_SEMANTICS_UNKNOWN" : "UNKNOWN_DIFFERENT_OR_MISSING_ENV_ID"
    }

    static func сформироватьЗапрос(_ сессия: String) throws -> String {
        let идентификатор = try каноническийUUID(сессия)
        return "SELECT id, model_provider, model, reasoning_effort, updated_at, updated_at_ms FROM threads WHERE id = '"+ идентификатор +"' LIMIT 2;"
    }
    static func аргументы(_ текстЗапроса: String, база: String) -> [String] {
        ["-batch", "-bail", "-init", "/dev/null", "-readonly", "-nofollow", "-json", база, текстЗапроса]
    }
    private static func токен(_ значение: String) -> Bool {
        let байты = Array(значение.utf8)
        return (1...128).contains(байты.count) && байты.first.map({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) == true && байты.allSatisfy {
            (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || [45, 46, 95].contains($0)
        } && !["unknown", "unavailable", "null", "unset"].contains(значение.lowercased())
    }
    private static func целое(_ значение: Any?) -> Int64? {
        guard let число = значение as? NSNumber, ["q", "i", "s", "l", "Q", "I", "S", "L"].contains(String(cString: число.objCType)) else { return nil }
        return Int64(число.stringValue)
    }
    private static func разобрать(_ байты: Data, сессия: String, поколение: String, запрошено: ПараметрыВыбораAPI?,
        наблюденоМс: Int64, отпечаток: String, режим: String, привязка: ПривязкаНативногоЧата, ENVThreadID: String?) throws -> НаблюдениеНативнойКонфигурации {
        _ = try каноническийUUID(сессия)
        guard !байты.isEmpty, байты.count <= пределВывода,
              let строки = try JSONSerialization.jsonObject(with: байты) as? [[String: Any]], строки.count == 1,
              let строка = строки.first, let идентификатор = строка["id"] as? String, let поставщик = строка["model_provider"] as? String,
              let модель = строка["model"] as? String, let усилие = строка["reasoning_effort"] as? String,
              let секунды = целое(строка["updated_at"]), let миллисекунды = целое(строка["updated_at_ms"]) else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-row-missing-ambiguous-or-invalid-types")
        }
        // NATIVE_MODEL_ROW_GUARD_BEGIN
        guard Set(строка.keys) == поля, идентификатор == сессия, UUID(uuidString: идентификатор)?.uuidString.lowercased() == идентификатор,
              токен(поставщик), токен(модель), токен(усилие),
              ["none", "minimal", "low", "medium", "high", "xhigh", "max", "ultra"].contains(усилие),
              секунды > 0, миллисекунды > 0, миллисекунды / 1000 == секунды, миллисекунды <= наблюденоМс,
              !поколение.isEmpty, поколение.utf8.count <= 128 else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-own-binding-values-or-row-revision")
        }
        // NATIVE_MODEL_ROW_GUARD_END
        return НаблюдениеНативнойКонфигурации(сессия: идентификатор, поставщик: поставщик,
            значение: ПараметрыВыбораAPI(model: модель, reasoningEffort: усилие), запрошено: запрошено,
            обновленоСек: секунды, обновленоМс: миллисекунды, наблюденоМс: наблюденоМс, отпечаток: отпечаток, поколение: поколение, режим: режим, привязка: привязка, ENVThreadID: ENVThreadID)
    }
    /// Real callable provider point. Fresh native read on every call, no cached receipt/JSON fallback.
    /// The profile describes exact RO inputs, and is not an authority/checker receipt.
    static func наблюдатьДляНовогоДопуска(_ профиль: ПрофильНативнойКонфигурации, привязка: ПривязкаНативногоЧата) throws -> НаблюдениеНативнойКонфигурации {
        let сырьё = try ШвыУправляемогоВызова.прочитатьСобственнуюНативнуюКонфигурацию(профиль, привязка: привязка)
        return try разобрать(сырьё.строка, сессия: привязка.нативныйЧатUUID, поколение: профиль.поколениеИзвестнойСмены,
            запрошено: профиль.запрошено, наблюденоМс: сырьё.наблюденоМс, отпечаток: сырьё.отпечаток, режим: "NATIVE_SQLITE_READONLY", привязка: привязка, ENVThreadID: ProcessInfo.processInfo.environment["CODEX_THREAD_ID"])
    }
    /// Сохранённое наблюдение не создаёт независимое ожидание самому себе.
    /// ROOT/caller отдельно выбирает полный expected receipt после собственной
    /// сверки retained observation. Этот чистый мост не читает native БД повторно.
    static func квитанцияОбычногоРебёнка(_ наблюдение: НаблюдениеНативнойКонфигурации,
        ожидаемыйКонтекст: КонтекстОбычногоРебёнка,
        ожидаемаяКвитанция: ОжидаемаяКвитанцияВыбораМодели,
        ожидаемоеПоколение: String) throws -> КвитанцияВыбораМодели {
        guard наблюдение.совпадаетСКонтекстом(сессия: ожидаемыйКонтекст.сессия,
                  поколениеИзвестнойСмены: ожидаемоеПоколение),
              ожидаемаяКвитанция.свидетельство.дочернийКонтекст == ожидаемыйКонтекст,
              ожидаемаяКвитанция.свидетельство.selectedValue == наблюдение.значение,
              ожидаемаяКвитанция.свидетельство.nativeSelectionSourceSHA256 == наблюдение.отпечатокИсточника else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-independent-expectation-mismatch")
        }
        let недоступно = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
        let свидетельство = СвидетельствоВыбораМодели(
            схема: "fum.model-selection-receipt.2", источник: .метаданныеДочернегоКлиента,
            rootUUID: ожидаемыйКонтекст.корневойUUID,
            sessionIdentity: ИдентичностьAPI(статус: .доступен, вид: .идентификаторNativeThreadMetadata,
                значение: наблюдение.нативныйЧатUUID),
            requestIdentity: недоступно, responseIdentity: недоступно, nativeThread: nil,
            requestedSelection: ожидаемыйКонтекст.запрошено, selectedValue: наблюдение.значение,
            nativeSelectionSourceSHA256: наблюдение.отпечатокИсточника,
            backendModel: .неизвестно, nativeTurnContext: .неизвестно,
            дочернийКонтекст: ожидаемыйКонтекст)
        let квитанция = try ГенераторМетаданныхКоммита.квитанция(для: свидетельство)
        guard ГенераторМетаданныхКоммита.проверитьReceipt(квитанция, ожидаемый: ожидаемаяКвитанция,
            expectedRootUUID: ожидаемыйКонтекст.корневойUUID,
            ожидаемыйДочернийКонтекст: ожидаемыйКонтекст).isEmpty else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-independent-receipt-invalid")
        }
        return квитанция
    }

    #if TESTING
    static func разобратьПроверочное(_ байты: Data, сессия: String, поколение: String = "test-generation-1",
        запрошено: ПараметрыВыбораAPI? = nil, наблюденоМс: Int64 = 1_800_000_000_000) throws -> НаблюдениеНативнойКонфигурации {
        try разобрать(байты, сессия: сессия, поколение: поколение, запрошено: запрошено,
            наблюденоМс: наблюденоМс, отпечаток: ГенераторМетаданныхКоммита.sha256Hex(байты), режим: "TESTING_SYNTHETIC_NOT_NATIVE",
            привязка: ПривязкаНативногоЧата(нативныйЧатUUID: сессия, исполнительныйТактUUID: nil, источникПривязки: "TESTING_SYNTHETIC_BINDING"), ENVThreadID: nil)
    }
    #endif
}
