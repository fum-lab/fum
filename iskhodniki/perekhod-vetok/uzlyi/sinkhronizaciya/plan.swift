import CryptoKit
import Foundation

public enum РешениеСинхронизации: String, Codable, Equatable, Sendable {
    case readOnlyNoOp
    case заблокировано
}

public enum ЭффектПереименованияЧата: String, Codable, Equatable, Sendable {
    case требуетсяДействиеВладельца
}

public struct ПереходПутиСинхронизации: Codable, Equatable, Sendable {
    public let исходный: String
    public let целевой: String
    public let вид: ВидПути

    public init(исходный: String, целевой: String, вид: ВидПути) {
        self.исходный = исходный
        self.целевой = целевой
        self.вид = вид
    }
}

public struct ПереименованиеЧатаСинхронизации: Codable, Equatable, Sendable {
    public let threadID: String
    public let староеИмя: String?
    public let новоеИмя: String
    public let выполнено: Bool
    public let эффект: ЭффектПереименованияЧата

    public init(threadID: String, староеИмя: String?, новоеИмя: String) {
        self.threadID = threadID
        self.староеИмя = староеИмя
        self.новоеИмя = новоеИмя
        выполнено = false
        эффект = .требуетсяДействиеВладельца
    }
}

fileprivate struct СодержимоеПланаСинхронизации: Codable, Equatable, Sendable {
    let корневаяЗадача: String
    let писатель: String
    let снимок: СнимокGitСинхронизации
    let узлы: [УзелИнвентаря]
    let переходыПутей: [ПереходПутиСинхронизации]
    let строкВнеОбласти: Int
    let источникКарты: ИсточникСинхронизации
    let пожелания: [ПожеланиеАгентаСинхронизации]
    let решение: РешениеСинхронизации
    let причинаБлокировки: String?
    let переименованияЧатов: [ПереименованиеЧатаСинхронизации]
}

public struct ПланСинхронизации: Codable, Equatable, Sendable {
    public let идентификатор: String
    fileprivate let содержимое: СодержимоеПланаСинхронизации

    fileprivate init(идентификатор: String, содержимое: СодержимоеПланаСинхронизации) {
        self.идентификатор = идентификатор
        self.содержимое = содержимое
    }

    public var корневаяЗадача: String { содержимое.корневаяЗадача }
    public var писатель: String { содержимое.писатель }
    public var снимок: СнимокGitСинхронизации { содержимое.снимок }
    public var узлы: [УзелИнвентаря] { содержимое.узлы }
    public var переходыПутей: [ПереходПутиСинхронизации] { содержимое.переходыПутей }
    public var строкВнеОбласти: Int { содержимое.строкВнеОбласти }
    public var источникКарты: ИсточникСинхронизации { содержимое.источникКарты }
    public var пожелания: [ПожеланиеАгентаСинхронизации] { содержимое.пожелания }
    public var решение: РешениеСинхронизации { содержимое.решение }
    public var причинаБлокировки: String? { содержимое.причинаБлокировки }
    public var переименованияЧатов: [ПереименованиеЧатаСинхронизации] {
        содержимое.переименованияЧатов
    }

    public func байты() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(10)
        return data
    }

    func целостен() -> Bool {
        guard let data = try? JSONEncoder.синхронизации().encode(содержимое) else { return false }
        return Self.хэш(data) == идентификатор
    }

    fileprivate static func хэш(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public enum ОшибкаСинхронизации: Error, Equatable, Sendable {
    case запрещённоеСостояние
    case дрейф
    case повреждённыйПлан
}

public enum ПланировщикСинхронизации {
    public static func построить(
        _ inventory: ПакетныйИнвентарьСинхронизации
    ) throws -> ПланСинхронизации {
        try ВалидаторИнвентаря.проверить(inventory)

        let rows = inventory.картаИмен.карта
            .filter { целеваяСтрокаВОбласти($0.целевой) }
            .sorted(by: порядокСтрок)
        let nodes = inventory.узлы
            .filter { $0.роль == .ответственность }
            .map(нормализоватьИсточники)
            .sorted(by: порядокУзлов)
        let wishes = inventory.пожелания.sorted(by: порядокПожеланий)
        let renames = nodes.compactMap { node -> ПереименованиеЧатаСинхронизации? in
            guard let name = node.желаемоеИмяЧата, let threadID = node.threadID else { return nil }
            return ПереименованиеЧатаСинхронизации(
                threadID: threadID, староеИмя: node.имяЧата, новоеИмя: name)
        }
        let blockingReason = причинаБлокировки(inventory, nodes: nodes)
        let content = СодержимоеПланаСинхронизации(
            корневаяЗадача: inventory.снимок.корневаяЗадача,
            писатель: inventory.снимок.писатель,
            снимок: inventory.снимок,
            узлы: nodes,
            переходыПутей: rows.map {
                ПереходПутиСинхронизации(исходный: $0.исходный, целевой: $0.целевой, вид: $0.вид)
            },
            строкВнеОбласти: inventory.картаИмен.карта.count - rows.count,
            источникКарты: inventory.картаИмен.источник,
            пожелания: wishes,
            решение: blockingReason == nil ? .readOnlyNoOp : .заблокировано,
            причинаБлокировки: blockingReason,
            переименованияЧатов: renames)
        let bytes = try JSONEncoder.синхронизации().encode(content)
        return ПланСинхронизации(идентификатор: ПланСинхронизации.хэш(bytes), содержимое: content)
    }

    private static func целеваяСтрокаВОбласти(_ target: String) -> Bool {
        target.hasPrefix("iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/")
            || target.hasPrefix("iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/")
            || target == "iskhodniki/perekhod-vetok/zhurnal/sinkhronizaciya"
    }

    private static func порядокСтрок(
        _ left: ОтображениеИмен, _ right: ОтображениеИмен
    ) -> Bool {
        if left.исходный != right.исходный { return left.исходный < right.исходный }
        if left.целевой != right.целевой { return left.целевой < right.целевой }
        return left.вид.rawValue < right.вид.rawValue
    }

    private static func порядокУзлов(_ left: УзелИнвентаря, _ right: УзелИнвентаря) -> Bool {
        let lhs = [left.логическийАдрес, left.роль.rawValue, left.владелец ?? "",
                   left.ref ?? "", left.задача ?? "", left.threadID ?? ""]
        let rhs = [right.логическийАдрес, right.роль.rawValue, right.владелец ?? "",
                   right.ref ?? "", right.задача ?? "", right.threadID ?? ""]
        return lhs.lexicographicallyPrecedes(rhs)
    }

    private static func порядокПожеланий(
        _ left: ПожеланиеАгентаСинхронизации, _ right: ПожеланиеАгентаСинхронизации
    ) -> Bool {
        let lhs = [left.владелецЗадачи ?? "", left.владелецRef, left.желаемыйРезультат]
        let rhs = [right.владелецЗадачи ?? "", right.владелецRef, right.желаемыйРезультат]
        return lhs.lexicographicallyPrecedes(rhs)
    }

    private static func нормализоватьИсточники(_ node: УзелИнвентаря) -> УзелИнвентаря {
        var value = node
        value.источники.sort {
            [$0.коммит, $0.путь, $0.blob, $0.sha256].lexicographicallyPrecedes(
                [$1.коммит, $1.путь, $1.blob, $1.sha256])
        }
        return value
    }

    private static func причинаБлокировки(
        _ inventory: ПакетныйИнвентарьСинхронизации, nodes: [УзелИнвентаря]
    ) -> String? {
        let snapshot = inventory.снимок
        if snapshot.остановка { return "остановка" }
        if snapshot.пауза { return "приостановлено" }
        if snapshot.активность { return "активность" }
        if snapshot.состояние != .чистое { return snapshot.состояние.rawValue }
        if nodes.contains(where: { $0.состояние != .чистое }) { return "состояние-узла" }
        if inventory.рабочиеДеревья.contains(where: {
            $0.владелец == snapshot.писатель && $0.состояние != .чистое
        }) { return "рабочее-дерево" }
        return nil
    }
}

public enum ИсходКвитанцииСинхронизации: String, Codable, Equatable, Sendable {
    case наблюдена
}

public enum ПобочныйЭффектСинхронизации: String, Codable, Equatable, Sendable {
    case нет
}

public struct КвитанцияСинхронизации: Codable, Equatable, Sendable {
    public let план: String
    public let побочныйЭффект: ПобочныйЭффектСинхронизации
    public let исход: ИсходКвитанцииСинхронизации

    public init(план: String) {
        self.план = план
        побочныйЭффект = .нет
        исход = .наблюдена
    }
}

public enum АдаптерСинхронизации {
    public static func применить(
        _ plan: ПланСинхронизации,
        текущее inventory: ПакетныйИнвентарьСинхронизации
    ) throws -> КвитанцияСинхронизации {
        guard plan.целостен() else { throw ОшибкаСинхронизации.повреждённыйПлан }
        guard plan.снимок == inventory.снимок else { throw ОшибкаСинхронизации.дрейф }
        guard plan.решение == .readOnlyNoOp else {
            throw ОшибкаСинхронизации.запрещённоеСостояние
        }
        let current: ПланСинхронизации
        do {
            current = try ПланировщикСинхронизации.построить(inventory)
        } catch {
            throw ОшибкаСинхронизации.дрейф
        }
        guard current.идентификатор == plan.идентификатор else {
            throw ОшибкаСинхронизации.дрейф
        }
        return КвитанцияСинхронизации(план: plan.идентификатор)
    }
}

private extension JSONEncoder {
    static func синхронизации() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
