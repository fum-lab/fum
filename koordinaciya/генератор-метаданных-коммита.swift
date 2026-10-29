import CryptoKit
import Foundation

/// Происхождение выбранных значений; ни один случай не удостоверяет модель провайдера.
public enum ИсточникВыбораМодели: String, Codable, Equatable, Sendable {
    case дочернийВызовSpawnAgent = "collaboration.spawn_agent"
    case корневыеNativeClientMetadata = "native-codex-client-thread-metadata"
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

    private enum CodingKeys: String, CodingKey {
        case схема, источник, rootUUID, sessionIdentity, childIdentity, requestIdentity, responseIdentity
        case nativeThread, requestedSelection, requested, selectedValue, acceptedSelection
        case nativeSelectionSourceSHA256, backendModel, nativeTurnContext
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
        nativeTurnContext: НеизвестныйСтатусСведений
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
                nativeTurnContext: nativeTurnContext
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
                nativeTurnContext: nativeTurnContext
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

public enum ГенераторМетаданныхКоммита {
    private static let неизвестныеТокены: Set<String> = ["unknown", "unavailable", "unset", "null"]
    private static let русскиеБуквы = CharacterSet(charactersIn: "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя")

    public static func проверитьReceipt(
        _ receipt: КвитанцияВыбораМодели?,
        ожидаемый: ОжидаемаяКвитанцияВыбораМодели?,
        expectedRootUUID: String? = nil
    ) -> [String] {
        guard let receipt else { return ["нет-квитанции-api-selection"] }
        guard let ожидаемый else { return ["нет-ожидаемой-квитанции-api-selection"] }
        var ошибки = проверитьСвидетельство(receipt.свидетельство, expectedRootUUID: expectedRootUUID)
        ошибки.append(contentsOf: проверитьСвидетельство(ожидаемый.свидетельство, expectedRootUUID: expectedRootUUID))
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
        expectedRootUUID: String? = nil
    ) -> [String] {
        проверитьСвидетельство(свидетельство, expectedRootUUID: expectedRootUUID)
    }

    public static func подготовитьОкружение(
        ожидаемаяИдентичность: ОжидаемаяИдентичностьGit,
        expectedRootUUID: String,
        выходFUMA: ВыходГенератораGitMetadata
    ) -> РезультатПодготовкиОкруженияКоммита {
        var ошибки = проверитьReceipt(
            ожидаемаяИдентичность.квитанцияВыбораМодели,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: expectedRootUUID
        )
        guard let свидетельство = ожидаемаяИдентичность.квитанцияВыбораМодели?.свидетельство else {
            return РезультатПодготовкиОкруженияКоммита(выходFUMA: nil, ошибки: ошибки)
        }
        let expectedAuthorName = "FUM Codex [\(свидетельство.selectedValue.model); effort=\(свидетельство.selectedValue.reasoningEffort)]"
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
    public static func referenceOutput(
        свидетельство: СвидетельствоВыбораМодели,
        план: ПланСообщенияКоммита
    ) -> ВыходГенератораGitMetadata {
        let authorName = "FUM Codex [\(свидетельство.selectedValue.model); effort=\(свидетельство.selectedValue.reasoningEffort)]"
        let message = "\(план.заголовок)\n\n\(план.описание)\n\nИсходный запрос:\n\(план.исходныйЗапрос)\n\nCodex-Thread-ID: \(свидетельство.rootUUID)\n"
        return ВыходГенератораGitMetadata(environment: ["GIT_AUTHOR_NAME": authorName], message: message)
    }

    public static func referenceOutput(for input: ПакетВходаГенератораFUMA) -> ПакетВыходаГенератораFUMA {
        ПакетВыходаГенератораFUMA(cases: input.cases.map { item in
            let authorName = "FUM Codex [\(item.acceptedSelection.model); effort=\(item.acceptedSelection.reasoningEffort)]"
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
        выходFUMA: ВыходГенератораGitMetadata
    ) -> РезультатГенерацииМетаданныхКоммита {
        let свидетельство = ожидаемаяИдентичность.квитанцияВыбораМодели?.свидетельство
            ?? emptyWitness(rootUUID: expectedRootUUID)
        var ошибки = проверитьReceipt(
            ожидаемаяИдентичность.квитанцияВыбораМодели,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: expectedRootUUID
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
        expectedRootUUID: String?
    ) -> [String] {
        var ошибки: [String] = []
        let currentSchema = свидетельство.схема == "fum.model-selection-receipt.1"
        let legacyChildSchema = свидетельство.схема == "fum.api-selection-receipt.1"
            && свидетельство.источник == .дочернийВызовSpawnAgent
        if !currentSchema && !legacyChildSchema { ошибки.append("unsupported-model-selection-receipt-schema") }
        if !безопасныйТокен(свидетельство.selectedValue.model) { ошибки.append("selected-model-invalid") }
        if !безопасныйТокен(свидетельство.selectedValue.reasoningEffort) { ошибки.append("selected-effort-invalid") }
        if свидетельство.sessionIdentity.статус != .доступен
            || свидетельство.sessionIdentity.вид != .идентификаторNativeThreadMetadata
            || свидетельство.sessionIdentity.значение == nil {
            ошибки.append("native-session-identity-invalid")
        }
        switch свидетельство.источник {
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
