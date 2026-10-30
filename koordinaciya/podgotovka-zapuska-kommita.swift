import CryptoKit
import Foundation
import Darwin

enum ОшибкаПроизводителяПодготовкиКоммита: Error, Equatable, Sendable {
    case аргументы, источник, каноническийJSON, схема, контекст, модель, состояние, путь
    case ужеСуществует
    case неизвестныйИсход(String)
}

struct СодержимоеСообщенияПроизводителяКоммита: Codable, Sendable {
    let тема: String
    let задача: String
    let изменения: String
    let проверки: String
    let граница: String
    enum CodingKeys: String, CodingKey {
        case тема = "title", задача = "request", изменения = "changes"
        case проверки = "checks", граница = "boundary"
    }
}

struct ДанныеВходаПроизводителяКоммита: Codable, Sendable {
    let схема: String
    let контекст: КонтекстЗапускаКодекс
    let сообщение: СодержимоеСообщенияПроизводителяКоммита
    let личность: ИдентичностьЗапускаКоммитаКодекс
    let среда: СредаГенератораЗапускаКодекс
    let программаROOT: ПинФайлаЗапускаКодекс
    let квитанцияМодели: ПинФайлаЗапускаКодекс
    let ожиданиеМодели: ПинФайлаЗапускаКодекс
    let идентификаторСнимка: String
    let наблюденоВМиллисекундах: Int64
    let профильИсточника: String
    let приватныйРодитель: String
    enum CodingKeys: String, CodingKey {
        case схема = "schema", контекст = "context", сообщение = "message"
        case личность = "identity", среда = "runtime", программаROOT = "rootProgram"
        case квитанцияМодели = "modelReceipt", ожиданиеМодели = "modelExpectation"
        case идентификаторСнимка = "snapshotUUID"
        case наблюденоВМиллисекундах = "observedAtMilliseconds"
        case профильИсточника = "sourceProfile", приватныйРодитель = "privateParent"
    }
}

// Host выбирает вход/SHA и оба UUID отдельно. JSON не декодируется в этот тип.
struct ДоверенныйВходПроизводителяКоммита: Sendable {
    fileprivate let вход: ДанныеВходаПроизводителяКоммита
    fileprivate let документ: ДокументПодготовкиКодекс
    fileprivate let хэшВхода: String
    fileprivate let квитанция: КвитанцияВыбораМодели
    fileprivate let ожидание: ОжидаемаяКвитанцияВыбораМодели
    fileprivate let документы: [String: Data]
    fileprivate init(вход: ДанныеВходаПроизводителяКоммита,
        документ: ДокументПодготовкиКодекс, хэшВхода: String,
        квитанция: КвитанцияВыбораМодели, ожидание: ОжидаемаяКвитанцияВыбораМодели,
        документы: [String: Data]) {
        self.вход = вход; self.документ = документ; self.хэшВхода = хэшВхода
        self.квитанция = квитанция; self.ожидание = ожидание; self.документы = документы
    }
}

struct НепринятыйПакетПодготовкиКоммита: Sendable {
    let каталогВыхода: String
    let файлы: [String: Data]
    let предложение: Data
    let селектор: ПинФайлаЗапускаКодекс
    let манифест: ПинФайлаЗапускаКодекс
    let входнойПин: ПинФайлаЗапускаКодекс
    let внешниеПины: [ПинФайлаЗапускаКодекс]
    fileprivate let приватныйРодитель: String
    fileprivate let корень: String
    fileprivate let этап: String
    fileprivate init(каталогВыхода: String, файлы: [String: Data], предложение: Data,
        селектор: ПинФайлаЗапускаКодекс, манифест: ПинФайлаЗапускаКодекс,
        входнойПин: ПинФайлаЗапускаКодекс, внешниеПины: [ПинФайлаЗапускаКодекс],
        приватныйРодитель: String, корень: String, этап: String) {
        self.каталогВыхода = каталогВыхода; self.файлы = файлы; self.предложение = предложение
        self.селектор = селектор; self.манифест = манифест; self.входнойПин = входнойПин
        self.внешниеПины = внешниеПины; self.приватныйРодитель = приватныйРодитель
        self.корень = корень; self.этап = этап
    }
}

struct КвитанцияСохраненияПакетаПодготовки: Codable, Sendable {
    let схема: String
    let каталогВыхода: String
    let селектор: ПинФайлаЗапускаКодекс
    let манифест: ПинФайлаЗапускаКодекс
    let принятоROOT: Bool
    let источникМоделиАутентифицирован: Bool
    enum CodingKeys: String, CodingKey {
        case схема = "schema", каталогВыхода = "outputDirectory"
        case селектор = "selector", манифест = "manifest"
        case принятоROOT = "rootAdmitted"
        case источникМоделиАутентифицирован = "providerAuthenticated"
    }
    fileprivate init(_ пакет: НепринятыйПакетПодготовкиКоммита) {
        схема = "fum.codex-commit-producer-published-proposal.1"
        каталогВыхода = пакет.каталогВыхода; селектор = пакет.селектор; манифест = пакет.манифест
        принятоROOT = false; источникМоделиАутентифицирован = false
    }
}

private enum КанонПроизводителяКоммита {
    static func байты<T: Encodable>(_ значение: T) throws -> Data {
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try e.encode(значение)
    }
    static func прочитать<T: Codable>(_ тип: T.Type, _ данные: Data, предел: Int = 65_536) throws -> T {
        do {
            guard данные.count <= предел else { throw ОшибкаПроизводителяПодготовкиКоммита.каноническийJSON }
            let json = try JSONSerialization.jsonObject(with: данные)
            guard json is [String: Any],
                  try JSONSerialization.data(withJSONObject: json,
                    options: [.sortedKeys, .withoutEscapingSlashes]) == данные else {
                throw ОшибкаПроизводителяПодготовкиКоммита.каноническийJSON
            }
            let результат = try JSONDecoder().decode(тип, from: данные)
            guard try байты(результат) == данные else { throw ОшибкаПроизводителяПодготовкиКоммита.каноническийJSON }
            return результат
        } catch { throw ОшибкаПроизводителяПодготовкиКоммита.каноническийJSON }
    }
    static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
    static func буквально(_ а: String, _ б: String) -> Bool { а.utf8.elementsEqual(б.utf8) }
    static func uuid(_ s: String) -> Bool { UUID(uuidString: s)?.uuidString.lowercased() == s }
    static func sha(_ s: String) -> Bool {
        s.utf8.count == 64 && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
    static func путь(_ s: String) -> Bool {
        let parts = s.split(separator: "/", omittingEmptySubsequences: false)
        return s.hasPrefix("/") && s.utf8.count <= 4096 && parts.count > 1
            && !s.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
            && parts.dropFirst().allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
    static func родитель(_ s: String) -> String {
        guard let slash = s.lastIndex(of: "/"), slash != s.startIndex else { return "/" }
        return String(s[..<slash])
    }
    static func лист(_ s: String) -> String {
        guard let slash = s.lastIndex(of: "/") else { return s }
        return String(s[s.index(after: slash)...])
    }
    static func пересекаются(_ a: String, _ b: String) -> Bool {
        a == b || a.hasPrefix(b + "/") || b.hasPrefix(a + "/")
    }
    static func ссылки(_ вход: ДанныеВходаПроизводителяКоммита) -> [ПинФайлаЗапускаКодекс] {
        [вход.квитанцияМодели, вход.ожиданиеМодели, вход.среда.исполняемыйФайлМетаданных,
         вход.среда.состояниеМетаданных, вход.среда.определение, вход.среда.оператор, вход.программаROOT]
    }
    static func проверитьСсылки(_ refs: [ПинФайлаЗапускаКодекс]) throws {
        for r in refs {
            guard путь(r.путь), sha(r.хэш) else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        }
        for i in refs.indices {
            for j in refs.indices where j > i {
                let a = refs[i], b = refs[j]
                if a.путь == b.путь {
                    guard буквально(a.путь, b.путь), a.хэш == b.хэш else {
                        throw ОшибкаПроизводителяПодготовкиКоммита.источник
                    }
                } else if пересекаются(a.путь, b.путь) {
                    throw ОшибкаПроизводителяПодготовкиКоммита.источник
                }
            }
        }
    }
    static func данные(_ ref: ПинФайлаЗапускаКодекс, из документы: [String: Data], предел: Int) throws -> Data {
        guard !документы.keys.contains(where: { $0 == ref.путь && !буквально($0, ref.путь) }),
              let value = документы.first(where: { буквально($0.key, ref.путь) })?.value,
              value.count <= предел, хэш(value) == ref.хэш else {
            throw ОшибкаПроизводителяПодготовкиКоммита.источник
        }
        return value
    }
}

enum ЧитательВходаПроизводителяКоммита {
    static func проверить(данныеВхода: Data, путь: String, sha256: String,
        доверенныйROOT: String, доверенныйЭтап: String, документы: [String: Data]
    ) throws -> ДоверенныйВходПроизводителяКоммита {
        typealias K = КанонПроизводителяКоммита
        guard K.путь(путь), K.sha(sha256), K.хэш(данныеВхода) == sha256,
              K.uuid(доверенныйROOT), K.uuid(доверенныйЭтап),
              K.буквально(доверенныйROOT, доверенныйЭтап) else {
            throw ОшибкаПроизводителяПодготовкиКоммита.контекст
        }
        let input = try K.прочитать(ДанныеВходаПроизводителяКоммита.self, данныеВхода)
        guard input.схема == "fum.codex-commit-producer-input.1",
              input.профильИсточника == "verified-client-selection-only" else {
            throw ОшибкаПроизводителяПодготовкиКоммита.схема
        }
        guard K.буквально(input.контекст.идентификаторКорневойЗадачи, доверенныйROOT),
              K.буквально(input.контекст.идентификаторЭтапа, доверенныйЭтап),
              K.uuid(input.идентификаторСнимка), input.наблюденоВМиллисекундах > 0,
              K.путь(input.приватныйРодитель), K.буквально(K.родитель(путь), input.приватныйРодитель),
              !K.буквально(input.квитанцияМодели.путь, input.ожиданиеМодели.путь) else {
            throw ОшибкаПроизводителяПодготовкиКоммита.контекст
        }
        let pins = K.ссылки(input) + [ПинФайлаЗапускаКодекс(путь: путь, хэш: sha256)]
        try K.проверитьСсылки(pins)
        let actualBytes = try K.данные(input.квитанцияМодели, из: документы, предел: 65_536)
        let expectedBytes = try K.данные(input.ожиданиеМодели, из: документы, предел: 65_536)
        let receipt = try K.прочитать(КвитанцияВыбораМодели.self, actualBytes)
        let expected = try K.прочитать(ОжидаемаяКвитанцияВыбораМодели.self, expectedBytes)
        guard receipt.свидетельство.источник == .корневыеNativeClientMetadata,
              K.буквально(receipt.свидетельство.sessionIdentity.значение ?? "", доверенныйЭтап),
              ГенераторМетаданныхКоммита.проверитьReceipt(receipt, ожидаемый: expected,
                expectedRootUUID: доверенныйROOT).isEmpty else {
            throw ОшибкаПроизводителяПодготовкиКоммита.модель
        }
        for pin in K.ссылки(input) {
            let binary = pin == input.среда.исполняемыйФайлМетаданных || pin == input.среда.оператор
            _ = try K.данные(pin, из: документы, предел: binary ? 64 * 1_048_576 : 1_048_576)
        }
        let stateBytes = try K.данные(input.среда.состояниеМетаданных, из: документы, предел: 1_048_576)
        // Старые закреплённые state bytes не переписываются и не превращаются в полномочие.
        let state = try JSONDecoder().decode(СостояниеКоординации.self, from: stateBytes)
        guard let plan = state.планСамообновления,
              K.буквально(state.корневойUUID, доверенныйROOT),
              K.буквально(plan.собственныйРеф, input.контекст.полныйRef),
              plan.идентичностьСледующегоКоммита.родитель == input.контекст.исходныйOID,
              K.буквально(plan.сообщениеСледующегоКоммита.заголовок, input.сообщение.тема),
              K.буквально(plan.сообщениеСледующегоКоммита.исходныйЗапрос, input.сообщение.задача),
              let actualState = plan.идентичностьСледующегоКоммита.квитанцияВыбораМодели,
              let expectedState = plan.идентичностьСледующегоКоммита.ожидаемаяКвитанцияВыбораМодели,
              try K.байты(actualState) == K.байты(receipt),
              try K.байты(expectedState) == K.байты(expected) else {
            throw ОшибкаПроизводителяПодготовкиКоммита.состояние
        }
        return ДоверенныйВходПроизводителяКоммита(вход: input,
            документ: ДокументПодготовкиКодекс(путь: путь, данные: данныеВхода), хэшВхода: sha256,
            квитанция: receipt, ожидание: expected, документы: документы)
    }

    static func загрузить(путь: String, sha256: String, доверенныйROOT: String,
        доверенныйЭтап: String) throws -> ДоверенныйВходПроизводителяКоммита {
        typealias K = КанонПроизводителяКоммита
        let bytes = try ЧитательПодготовкиЗапускаКодекс.файл(путь)
        guard K.sha(sha256), K.хэш(bytes) == sha256 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        let input = try K.прочитать(ДанныеВходаПроизводителяКоммита.self, bytes)
        // Независимые host UUID проверяются до обхода внешних ссылок.
        guard K.uuid(доверенныйROOT), K.uuid(доверенныйЭтап),
              K.буквально(доверенныйROOT, доверенныйЭтап),
              K.буквально(input.контекст.идентификаторКорневойЗадачи, доверенныйROOT),
              K.буквально(input.контекст.идентификаторЭтапа, доверенныйЭтап) else {
            throw ОшибкаПроизводителяПодготовкиКоммита.контекст
        }
        try K.проверитьСсылки(K.ссылки(input) + [ПинФайлаЗапускаКодекс(путь: путь, хэш: sha256)])
        var docs: [String: Data] = [:]
        for pin in K.ссылки(input) {
            let binary = pin == input.среда.исполняемыйФайлМетаданных || pin == input.среда.оператор
            docs[pin.путь] = try ЧитательПодготовкиЗапускаКодекс.файл(pin.путь,
                предел: binary ? 64 * 1_048_576 : 1_048_576)
        }
        let result = try проверить(данныеВхода: bytes, путь: путь, sha256: sha256,
            доверенныйROOT: доверенныйROOT, доверенныйЭтап: доверенныйЭтап, документы: docs)
        let parent = try ФайлыПроизводителяКоммита.частныйКаталог(input.приватныйРодитель)
        Darwin.close(parent)
        for directory in [input.среда.кореньЗапуска, input.среда.кореньRuntime, input.среда.кореньПамяти] {
            guard !K.пересекаются(directory, input.контекст.физическийКорень) else {
                throw ОшибкаПроизводителяПодготовкиКоммита.путь
            }
            let fd = try ФайлыПроизводителяКоммита.частныйКаталог(directory); Darwin.close(fd)
        }
        for executable in [input.среда.исполняемыйФайлМетаданных, input.среда.оператор] {
            var st = stat()
            guard lstat(executable.путь, &st) == 0, st.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG),
                  st.st_uid == getuid(), st.st_nlink == 1, st.st_mode & 0o100 != 0 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
        }
        return result
    }
}

private struct ПредложениеПакетаПроизводителяКоммита: Encodable {
    let schema = "fum.codex-commit-producer-bundle-proposal.1"
    let sourceScope = "verified-client-selection-only"
    let rootRAWRead = false
    let nativeJSONLRead = false
    let providerAuthenticated = false
    let rootAdmitted = false
    let productionSwitch = false
    let context: КонтекстЗапускаКодекс
    let input: ПинФайлаЗапускаКодекс
    let selector: ПинФайлаЗапускаКодекс
    let files: [ПинФайлаЗапускаКодекс]
}

enum ПроизводительПодготовкиЗапускаКодекс {
    static let именаФайлов = ["snapshot.json", "selection.json", "identity.json", "message.json",
        "message.txt", "preparation.json", "selector.json"]
    static func собрать(вход: ДоверенныйВходПроизводителяКоммита, каталогВыхода: String,
        закреплённыеДокументы: [String: Data]) throws -> НепринятыйПакетПодготовкиКоммита {
        typealias K = КанонПроизводителяКоммита
        let i = вход.вход
        guard K.путь(каталогВыхода), K.буквально(K.родитель(каталогВыхода), i.приватныйРодитель),
              K.лист(каталогВыхода).utf8.count <= 128,
              K.лист(каталогВыхода).utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0)
                || (97...122).contains($0) || $0 == 45 || $0 == 95 || $0 == 46 }),
              !K.лист(каталогВыхода).hasPrefix("."),
              !K.пересекаются(каталогВыхода, i.контекст.физическийКорень) else {
            throw ОшибкаПроизводителяПодготовкиКоммита.путь
        }
        for protected in K.ссылки(i).map(\.путь) + [вход.документ.путь,
            i.среда.кореньЗапуска, i.среда.кореньRuntime, i.среда.кореньПамяти] {
            guard !K.пересекаются(каталогВыхода, protected) else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        }
        for pin in K.ссылки(i) { _ = try K.данные(pin, из: закреплённыеДокументы, предел: 64 * 1_048_576) }
        let choice = вход.квитанция.свидетельство.selectedValue
        let message = СообщениеКоммитаКодекс(тема: i.сообщение.тема, задача: i.сообщение.задача,
            изменения: i.сообщение.изменения, проверки: i.сообщение.проверки,
            граница: i.сообщение.граница, модель: choice.model, усилие: choice.reasoningEffort,
            идентификаторКорневойЗадачи: i.контекст.идентификаторКорневойЗадачи)
        let context = i.контекст
        guard context.родители.count == 1 || context.родители.count == 2 else {
            throw ОшибкаПроизводителяПодготовкиКоммита.контекст
        }
        let stage = try ВалидаторЛичностиИСообщенияКодекс.сформироватьЭтап(
            идентификаторКорневойЗадачи: context.идентификаторКорневойЗадачи,
            идентификаторЭтапа: context.идентификаторЭтапа,
            операция: context.родители.count == 1 ? "ordinary" : "merge",
            исходнаяСсылка: context.полныйRef, исходныйИдентификаторОбъекта: context.исходныйOID,
            исходноеДерево: context.исходноеДерево,
            входящийИдентификаторОбъекта: context.родители.count == 2 ? context.родители[1] : nil,
            сообщение: message)
        // Полнота относится только к предоставленному bounded selection, не к ROOT RAW/JSONL.
        let snapshot = СнимокИдентичностиКодекс(идентификаторСнимка: i.идентификаторСнимка,
            модель: choice.model, усилие: choice.reasoningEffort,
            наблюденоВМиллисекундах: i.наблюденоВМиллисекундах,
            полнота: true, неполныйХвост: 0, пропусков: 0, этап: stage)
        let source = try ВалидаторЛичностиИСообщенияКодекс.закодироватьСнимок(snapshot)
        let selection = try ВалидаторЛичностиИСообщенияКодекс.выбратьИсточник(данныеСнимка: source,
            идентификаторСнимка: i.идентификаторСнимка, этап: stage)
        let binding = try ВалидаторЛичностиИСообщенияКодекс.проверитьВыбранныйИсточник(
            данныеСнимка: source, данныеВыбора: selection, ожидаемыйЭтап: stage)
        let identity = try ВалидаторЛичностиИСообщенияКодекс.ожиданиеИдентичности(по: binding)
        let body = try ВалидаторЛичностиИСообщенияКодекс.закодироватьСообщение(message)
        let verified = try ВалидаторЛичностиИСообщенияКодекс.проверить(связывание: binding,
            данныеОжидаемойИдентичности: identity, данныеСообщения: body)
        var files = ["snapshot.json": source, "selection.json": selection,
            "identity.json": identity, "message.json": body,
            "message.txt": Data(verified.телоСообщенияДляПроверкиСырогоКоммита.utf8)]
        func pin(_ name: String) throws -> ПинФайлаЗапускаКодекс {
            guard let data = files[name] else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            return ПинФайлаЗапускаКодекс(путь: каталогВыхода + "/" + name, хэш: K.хэш(data))
        }
        let documentRefs = ДокументыЛичностиЗапускаКодекс(снимок: try pin("snapshot.json"),
            выборИсточника: try pin("selection.json"), личность: try pin("identity.json"),
            сообщение: try pin("message.json"), файлСообщения: try pin("message.txt"))
        files["preparation.json"] = try K.байты(ПодготовкаЗапускаКоммитаКодекс(
            схема: "fum.codex-commit-run-preparation.1", контекст: context,
            документы: documentRefs, личность: i.личность, среда: i.среда))
        files["selector.json"] = try K.байты(СелекторПодготовкиЗапускаКодекс(
            схема: "fum.codex-commit-run-selector.1", подготовка: try pin("preparation.json")))
        let selector = try pin("selector.json")
        var all = закреплённыеДокументы
        for name in именаФайлов { all[каталогВыхода + "/" + name] = files[name]! }
        _ = try ФабрикаПодтверждённогоЗапускаКодекс.подготовить(
            выбор: ДокументПодготовкиКодекс(путь: selector.путь, данные: files["selector.json"]!),
            ожидаемыйSHA256Выбора: selector.хэш, документы: all)
        let inputPin = ПинФайлаЗапускаКодекс(путь: вход.документ.путь, хэш: вход.хэшВхода)
        let external = [inputPin] + K.ссылки(i)
        let outputPins = try именаФайлов.map { try pin($0) }
        let proposal = try K.байты(ПредложениеПакетаПроизводителяКоммита(
            context: context, input: inputPin, selector: selector, files: external + outputPins))
        return НепринятыйПакетПодготовкиКоммита(каталогВыхода: каталогВыхода, файлы: files,
            предложение: proposal, селектор: selector,
            манифест: ПинФайлаЗапускаКодекс(путь: каталогВыхода + "/manifest-proposal.json", хэш: K.хэш(proposal)),
            входнойПин: inputPin, внешниеПины: external, приватныйРодитель: i.приватныйРодитель,
            корень: context.идентификаторКорневойЗадачи, этап: context.идентификаторЭтапа)
    }
}

struct ОперацииСозданияПриватногоПакета: Sendable {
    let послеЗаписи: @Sendable (String) throws -> Void
    static let системные = Self(послеЗаписи: { _ in })
}

private enum ФайлыПроизводителяКоммита {
    static func частныйКаталог(_ path: String) throws -> Int32 {
        guard КанонПроизводителяКоммита.путь(path) else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        var fd = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard fd >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        do {
            for part in path.split(separator: "/") {
                let next = Darwin.openat(fd, String(part), O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
                guard next >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
                Darwin.close(fd); fd = next
            }
            var st = stat()
            guard fstat(fd, &st) == 0, st.st_uid == getuid(),
                  st.st_mode & mode_t(S_IFMT) == mode_t(S_IFDIR), st.st_mode & 0o077 == 0 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.путь
            }
            return fd
        } catch { Darwin.close(fd); throw error }
    }
    static func сохранить(_ name: String, data: Data, directory: Int32) throws {
        let fd = Darwin.openat(directory, name, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        defer { Darwin.close(fd) }
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_uid == getuid(), before.st_nlink == 1,
              before.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG), before.st_mode & 0o777 == 0o600 else {
            throw ОшибкаПроизводителяПодготовкиКоммита.источник
        }
        var offset = 0
        try data.withUnsafeBytes { raw in
            while offset < raw.count {
                let n = Darwin.write(fd, raw.baseAddress!.advanced(by: offset), raw.count - offset)
                if n < 0 && errno == EINTR { continue }
                guard n > 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
                offset += n
            }
        }
        guard fsync(fd) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        try сверить(name, ожидаемые: data, directory: directory)
    }
    static func сверить(_ name: String, ожидаемые: Data, directory: Int32) throws {
        let fd = Darwin.openat(directory, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        defer { Darwin.close(fd) }
        var a = stat(), b = stat(), named = stat()
        guard fstat(fd, &a) == 0, a.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG),
              a.st_uid == getuid(), a.st_nlink == 1, a.st_mode & 0o777 == 0o600,
              a.st_size == off_t(ожидаемые.count) else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
        var observed = Data(), buffer = [UInt8](repeating: 0, count: 65_536)
        while observed.count <= ожидаемые.count {
            let n = buffer.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress!, min($0.count, ожидаемые.count + 1 - observed.count)) }
            if n < 0 && errno == EINTR { continue }
            guard n >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            if n == 0 { break }
            observed.append(contentsOf: buffer.prefix(n))
        }
        guard fstat(fd, &b) == 0, fstatat(directory, name, &named, AT_SYMLINK_NOFOLLOW) == 0,
              a.st_dev == b.st_dev, a.st_ino == b.st_ino, a.st_size == b.st_size,
              a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec, a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec,
              a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec, a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec,
              b.st_dev == named.st_dev, b.st_ino == named.st_ino, b.st_mode == named.st_mode,
              b.st_uid == named.st_uid, b.st_nlink == named.st_nlink, b.st_size == named.st_size,
              observed == ожидаемые else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
    }
}

enum ПисательПакетаПодготовкиКоммита {
    static func сохранить(_ пакет: НепринятыйПакетПодготовкиКоммита,
        операции: ОперацииСозданияПриватногоПакета = .системные
    ) throws -> КвитанцияСохраненияПакетаПодготовки {
        typealias K = КанонПроизводителяКоммита
        let parent = try ФайлыПроизводителяКоммита.частныйКаталог(пакет.приватныйРодитель)
        defer { Darwin.close(parent) }
        var parentInfo = stat(); guard fstat(parent, &parentInfo) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        let leaf = K.лист(пакет.каталогВыхода)
        var existing = stat()
        if fstatat(parent, leaf, &existing, AT_SYMLINK_NOFOLLOW) == 0 { throw ОшибкаПроизводителяПодготовкиКоммита.ужеСуществует }
        guard errno == ENOENT else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        for pin in пакет.внешниеПины {
            guard K.хэш(try ЧитательПодготовкиЗапускаКодекс.файл(pin.путь, предел: 64 * 1_048_576)) == pin.хэш else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
        }
        let stage = "." + leaf + ".building-" + UUID().uuidString.lowercased()
        guard Darwin.mkdirat(parent, stage, 0o700) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
        let retained = пакет.приватныйРодитель + "/" + stage
        var published = false
        do {
            let fd = Darwin.openat(parent, stage, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard fd >= 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            defer { Darwin.close(fd) }
            var openedStage = stat()
            guard fstat(fd, &openedStage) == 0, openedStage.st_uid == getuid(),
                  openedStage.st_mode & mode_t(S_IFMT) == mode_t(S_IFDIR),
                  openedStage.st_mode & 0o777 == 0o700 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
            func write(_ name: String, _ data: Data) throws {
                try ФайлыПроизводителяКоммита.сохранить(name, data: data, directory: fd)
                try операции.послеЗаписи(name)
            }
            let intent = try JSONSerialization.data(withJSONObject: [
                "schema": "fum.codex-commit-producer-intent.1", "rootUUID": пакет.корень,
                "stageUUID": пакет.этап, "inputSHA256": пакет.входнойПин.хэш,
                "outputDirectory": пакет.каталогВыхода, "rootAdmitted": false,
            ], options: [.sortedKeys, .withoutEscapingSlashes])
            try write("producer-intent.json", intent)
            guard fsync(fd) == 0, fsync(parent) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            for name in ПроизводительПодготовкиЗапускаКодекс.именаФайлов { try write(name, пакет.файлы[name]!) }
            for pin in пакет.внешниеПины {
                guard K.хэш(try ЧитательПодготовкиЗапускаКодекс.файл(pin.путь, предел: 64 * 1_048_576)) == pin.хэш else {
                    throw ОшибкаПроизводителяПодготовкиКоммита.источник
                }
            }
            try write("manifest-proposal.json", пакет.предложение)
            let outcome = try JSONSerialization.data(withJSONObject: [
                "schema": "fum.codex-commit-producer-sealed-outcome.1", "state": "sealed-before-publish",
                "inputSHA256": пакет.входнойПин.хэш, "selectorSHA256": пакет.селектор.хэш,
                "manifestSHA256": пакет.манифест.хэш, "rootAdmitted": false,
                "providerAuthenticated": false,
            ], options: [.sortedKeys, .withoutEscapingSlashes])
            try write("producer-outcome.json", outcome)
            guard fsync(fd) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            let currentParent = try ФайлыПроизводителяКоммита.частныйКаталог(пакет.приватныйРодитель)
            var currentInfo = stat(); let sameParent = fstat(currentParent, &currentInfo) == 0
                && currentInfo.st_dev == parentInfo.st_dev && currentInfo.st_ino == parentInfo.st_ino
            Darwin.close(currentParent)
            guard sameParent else { throw ОшибкаПроизводителяПодготовкиКоммита.путь }
            for name in ПроизводительПодготовкиЗапускаКодекс.именаФайлов {
                try ФайлыПроизводителяКоммита.сверить(name, ожидаемые: пакет.файлы[name]!, directory: fd)
            }
            try ФайлыПроизводителяКоммита.сверить("manifest-proposal.json", ожидаемые: пакет.предложение, directory: fd)
            try ФайлыПроизводителяКоммита.сверить("producer-intent.json", ожидаемые: intent, directory: fd)
            try ФайлыПроизводителяКоммита.сверить("producer-outcome.json", ожидаемые: outcome, directory: fd)
            var namedStage = stat(), heldStage = stat()
            guard fstatat(parent, stage, &namedStage, AT_SYMLINK_NOFOLLOW) == 0,
                  fstat(fd, &heldStage) == 0, namedStage.st_dev == heldStage.st_dev,
                  namedStage.st_ino == heldStage.st_ino, namedStage.st_uid == getuid(),
                  namedStage.st_mode & 0o777 == 0o700 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
            guard Darwin.renameatx_np(parent, stage, parent, leaf, UInt32(RENAME_EXCL)) == 0 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
            published = true
            guard fsync(parent) == 0 else { throw ОшибкаПроизводителяПодготовкиКоммита.источник }
            var finalInfo = stat(), heldInfo = stat()
            guard fstatat(parent, leaf, &finalInfo, AT_SYMLINK_NOFOLLOW) == 0, fstat(fd, &heldInfo) == 0,
                  finalInfo.st_dev == heldInfo.st_dev, finalInfo.st_ino == heldInfo.st_ino,
                  finalInfo.st_uid == getuid(), finalInfo.st_mode & 0o777 == 0o700 else {
                throw ОшибкаПроизводителяПодготовкиКоммита.источник
            }
            try ФайлыПроизводителяКоммита.сверить("manifest-proposal.json", ожидаемые: пакет.предложение, directory: fd)
            return КвитанцияСохраненияПакетаПодготовки(пакет)
        } catch {
            // После mkdir неизвестный/частичный исход удерживается; ни очистки, ни автоматического повтора.
            throw ОшибкаПроизводителяПодготовкиКоммита.неизвестныйИсход(published ? пакет.каталогВыхода : retained)
        }
    }
}

struct ОтветПроизводителяПодготовкиКоммита {
    let данные: Data
    let код: Int32
}

enum КомандаПодготовкиЗапускаКоммитаV1 {
    static let команда = "--подготовить-запуск-коммита-v1"
    static let командыКоординатора = ["--проверить-перед-коммитом", "--сгенерировать-метаданные-коммита",
        "--проверить-сырой-merge-коммит", "--проверить-сырой-коммит", "--проверить-пост-эффектный-git"]
    static func перехватить(_ аргументы: [String]) -> ОтветПроизводителяПодготовкиКоммита? {
        guard аргументы.first == команда else { return nil }
        do {
            if аргументы == [команда, "--версия"] {
                let data = try JSONSerialization.data(withJSONObject: [
                    "schema": "fum.codex-commit-producer-interface.1", "producerVersion": 1,
                    "commands": командыКоординатора, "ambientFallback": false, "productionSwitch": false,
                ], options: [.sortedKeys, .withoutEscapingSlashes])
                return ОтветПроизводителяПодготовкиКоммита(данные: data + Data([10]), код: 0)
            }
            guard аргументы.count == 10, аргументы[2] == "--sha256", аргументы[4] == "--root-uuid",
                  аргументы[6] == "--stage-uuid", аргументы[8] == "--output" else {
                throw ОшибкаПроизводителяПодготовкиКоммита.аргументы
            }
            let input = try ЧитательВходаПроизводителяКоммита.загрузить(путь: аргументы[1], sha256: аргументы[3],
                доверенныйROOT: аргументы[5], доверенныйЭтап: аргументы[7])
            let bundle = try ПроизводительПодготовкиЗапускаКодекс.собрать(вход: input,
                каталогВыхода: аргументы[9], закреплённыеДокументы: input.документы)
            let result = try ПисательПакетаПодготовкиКоммита.сохранить(bundle)
            return ОтветПроизводителяПодготовкиКоммита(данные: try КанонПроизводителяКоммита.байты(result) + Data([10]), код: 0)
        } catch {
            let reason: String
            let unknown: Bool
            var retained: String? = nil
            if let e = error as? ОшибкаПроизводителяПодготовкиКоммита {
                switch e {
                case .аргументы: reason = "arguments"; unknown = false
                case .источник: reason = "source"; unknown = false
                case .каноническийJSON: reason = "canonical-json"; unknown = false
                case .схема: reason = "schema"; unknown = false
                case .контекст: reason = "context"; unknown = false
                case .модель: reason = "model-selection"; unknown = false
                case .состояние: reason = "metadata-state"; unknown = false
                case .путь: reason = "path"; unknown = false
                case .ужеСуществует: reason = "output-exists"; unknown = true
                case .неизвестныйИсход(let path): reason = "outcome-unknown"; unknown = true; retained = path
                }
            } else if let e = error as? ОтказПодготовкиЗапускаКодекс {
                reason = e.rawValue; unknown = false
            } else if let e = error as? ОтказПроверкиПубликации {
                reason = e.rawValue; unknown = false
            } else { reason = "input-refused"; unknown = false }
            var value: [String: Any] = ["schema": "fum.codex-commit-producer-refusal.1",
                "state": unknown ? "UNKNOWN" : "refused", "reason": reason,
                "rootAdmitted": false, "providerAuthenticated": false, "productionSwitch": false]
            if let retained { value["retainedDirectory"] = retained }
            let data = (try? JSONSerialization.data(withJSONObject: value,
                options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data("{}".utf8)
            return ОтветПроизводителяПодготовкиКоммита(данные: data + Data([10]), код: unknown ? 3 : 2)
        }
    }
}
