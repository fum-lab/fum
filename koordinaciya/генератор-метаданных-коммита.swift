import CryptoKit
import Foundation

/// Ограниченный источник выбора для дочерних вызовов collaboration.spawn_agent.
/// Это не свидетельство модели провайдера или native turn_context.
public enum ИсточникВыбораAPI: String, Codable, Equatable, Sendable {
    case дочернийSpawnAgent = "collaboration.spawn_agent"
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

/// Локально сохранённая typed-проекция выбранных API-параметров и native metadata.
/// Канонические байты и SHA-256 закрепляют содержимое, но не аутентифицируют API/backend.
public struct СвидетельствоВыбораAPI: Codable, Equatable, Sendable {
    public let схема: String
    public let источник: ИсточникВыбораAPI
    public let rootUUID: String
    public let childIdentity: ИдентичностьAPI
    public let requestIdentity: ИдентичностьAPI
    public let responseIdentity: ИдентичностьAPI
    public let nativeThread: СнимокNativeThreadMetadata
    public let requested: ПараметрыВыбораAPI
    public let acceptedSelection: ПараметрыВыбораAPI
    public let backendModel: НеизвестныйСтатусСведений
    public let nativeTurnContext: НеизвестныйСтатусСведений

    public init(
        схема: String = "fum.api-selection-receipt.1",
        источник: ИсточникВыбораAPI,
        rootUUID: String,
        childIdentity: ИдентичностьAPI,
        requestIdentity: ИдентичностьAPI,
        responseIdentity: ИдентичностьAPI,
        nativeThread: СнимокNativeThreadMetadata,
        requested: ПараметрыВыбораAPI,
        acceptedSelection: ПараметрыВыбораAPI,
        backendModel: НеизвестныйСтатусСведений,
        nativeTurnContext: НеизвестныйСтатусСведений
    ) {
        self.схема = схема
        self.источник = источник
        self.rootUUID = rootUUID
        self.childIdentity = childIdentity
        self.requestIdentity = requestIdentity
        self.responseIdentity = responseIdentity
        self.nativeThread = nativeThread
        self.requested = requested
        self.acceptedSelection = acceptedSelection
        self.backendModel = backendModel
        self.nativeTurnContext = nativeTurnContext
    }
}

public struct КвитанцияВыбораAPI: Codable, Equatable, Sendable {
    public let свидетельство: СвидетельствоВыбораAPI
    /// Base64 канонических JSON-байтов локальной проекции, не исходный wire payload.
    public let canonicalBytesBase64: String
    public let sha256: String

    public init(свидетельство: СвидетельствоВыбораAPI, canonicalBytesBase64: String, sha256: String) {
        self.свидетельство = свидетельство
        self.canonicalBytesBase64 = canonicalBytesBase64
        self.sha256 = sha256
    }
}

/// Независимо закреплённая ожиданием consumer копия receipt и его канонических байтов.
/// Совпадение хэша показывает целостность согласованной проекции, не подлинность источника.
public struct ОжидаемаяКвитанцияВыбораAPI: Codable, Equatable, Sendable {
    public let свидетельство: СвидетельствоВыбораAPI
    public let canonicalBytesBase64: String
    public let sha256: String

    public init(свидетельство: СвидетельствоВыбораAPI, canonicalBytesBase64: String, sha256: String) {
        self.свидетельство = свидетельство
        self.canonicalBytesBase64 = canonicalBytesBase64
        self.sha256 = sha256
    }
}

public struct ОжидаемаяИдентичностьGit: Codable, Equatable, Sendable {
    public let квитанцияВыбораAPI: КвитанцияВыбораAPI?
    public let ожидаемаяКвитанцияВыбораAPI: ОжидаемаяКвитанцияВыбораAPI?
    public let родитель: String

    public init(
        квитанцияВыбораAPI: КвитанцияВыбораAPI?,
        ожидаемаяКвитанцияВыбораAPI: ОжидаемаяКвитанцияВыбораAPI?,
        родитель: String
    ) {
        self.квитанцияВыбораAPI = квитанцияВыбораAPI
        self.ожидаемаяКвитанцияВыбораAPI = ожидаемаяКвитанцияВыбораAPI
        self.родитель = родитель
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
    public let выборAPI: СвидетельствоВыбораAPI
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
        _ receipt: КвитанцияВыбораAPI?,
        ожидаемый: ОжидаемаяКвитанцияВыбораAPI?,
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

    public static func квитанция(для свидетельства: СвидетельствоВыбораAPI) throws -> КвитанцияВыбораAPI {
        let bytes = try canonicalBytes(свидетельства)
        return КвитанцияВыбораAPI(
            свидетельство: свидетельства,
            canonicalBytesBase64: bytes.base64EncodedString(),
            sha256: sha256(bytes)
        )
    }

    public static func ожидание(для свидетельства: СвидетельствоВыбораAPI) throws -> ОжидаемаяКвитанцияВыбораAPI {
        let bytes = try canonicalBytes(свидетельства)
        return ОжидаемаяКвитанцияВыбораAPI(
            свидетельство: свидетельства,
            canonicalBytesBase64: bytes.base64EncodedString(),
            sha256: sha256(bytes)
        )
    }

    public static func проверитьСвидетельствоВыбораAPI(
        _ свидетельство: СвидетельствоВыбораAPI,
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
            ожидаемаяИдентичность.квитанцияВыбораAPI,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораAPI,
            expectedRootUUID: expectedRootUUID
        )
        guard let свидетельство = ожидаемаяИдентичность.квитанцияВыбораAPI?.свидетельство else {
            return РезультатПодготовкиОкруженияКоммита(выходFUMA: nil, ошибки: ошибки)
        }
        let expectedAuthorName = "FUM Codex [\(свидетельство.acceptedSelection.model); effort=\(свидетельство.acceptedSelection.reasoningEffort)]"
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
        свидетельство: СвидетельствоВыбораAPI,
        план: ПланСообщенияКоммита
    ) -> ВыходГенератораGitMetadata {
        let authorName = "FUM Codex [\(свидетельство.acceptedSelection.model); effort=\(свидетельство.acceptedSelection.reasoningEffort)]"
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
        let свидетельство = ожидаемаяИдентичность.квитанцияВыбораAPI?.свидетельство
            ?? emptyWitness(rootUUID: expectedRootUUID)
        var ошибки = проверитьReceipt(
            ожидаемаяИдентичность.квитанцияВыбораAPI,
            ожидаемый: ожидаемаяИдентичность.ожидаемаяКвитанцияВыбораAPI,
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
            выборAPI: свидетельство,
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

    private static func canonicalBytes(_ witness: СвидетельствоВыбораAPI) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(witness)
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func проверитьСвидетельство(
        _ свидетельство: СвидетельствоВыбораAPI,
        expectedRootUUID: String?
    ) -> [String] {
        var ошибки: [String] = []
        if свидетельство.схема != "fum.api-selection-receipt.1" { ошибки.append("неподдержанная-api-selection-схема") }
        if !безопасныйТокен(свидетельство.requested.model) { ошибки.append("некорректный-requested-model") }
        if !безопасныйТокен(свидетельство.requested.reasoningEffort) { ошибки.append("некорректный-requested-effort") }
        if !безопасныйТокен(свидетельство.acceptedSelection.model) { ошибки.append("некорректный-accepted-model") }
        if !безопасныйТокен(свидетельство.acceptedSelection.reasoningEffort) { ошибки.append("некорректный-accepted-effort") }
        if свидетельство.requested != свидетельство.acceptedSelection {
            ошибки.append("requested-и-accepted-selection-расходятся-для-этого-профиля")
        }
        if свидетельство.nativeThread.модель != свидетельство.acceptedSelection.model
            || свидетельство.nativeThread.усилие != свидетельство.acceptedSelection.reasoningEffort {
            ошибки.append("accepted-selection-не-связан-с-native-thread-metadata")
        }
        if свидетельство.nativeThread.threadUUID != свидетельство.childIdentity.значение {
            ошибки.append("child-identity-не-связан-с-native-thread")
        }
        if свидетельство.nativeThread.agentPath.isEmpty {
            ошибки.append("native-thread-agent-path-пуст")
        }
        if свидетельство.nativeThread.attachedThreadParentIDRaw != ""
            || свидетельство.nativeThread.lineageСтатус != .неизвестно {
            ошибки.append("parent-field-не-сохранён-как-unknown-lineage")
        }
        if свидетельство.childIdentity.статус != .доступен
            || свидетельство.childIdentity.вид != .идентификаторNativeThreadMetadata
            || свидетельство.childIdentity.значение != свидетельство.nativeThread.threadUUID {
            ошибки.append("некорректная-child-thread-identity")
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
        if !каноническийUUID(свидетельство.nativeThread.threadUUID) { ошибки.append("некорректный-native-thread-uuid") }
        if let expectedRootUUID, свидетельство.rootUUID != expectedRootUUID {
            ошибки.append("receipt-root-uuid-не-совпадает-с-ожиданием")
        }
        return ошибки
    }

    private static func emptyWitness(rootUUID: String) -> СвидетельствоВыбораAPI {
        let unavailable = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
        let unknownParams = ПараметрыВыбораAPI(model: "unknown", reasoningEffort: "unknown")
        return СвидетельствоВыбораAPI(
            источник: .дочернийSpawnAgent,
            rootUUID: rootUUID,
            childIdentity: unavailable,
            requestIdentity: unavailable,
            responseIdentity: unavailable,
            nativeThread: СнимокNativeThreadMetadata(
                threadUUID: "", agentPath: "", attachedThreadParentIDRaw: "", модель: "unknown",
                усилие: "unknown", lineageСтатус: .неизвестно),
            requested: unknownParams,
            acceptedSelection: unknownParams,
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
