import CryptoKit
import Foundation

public struct ОтказСинхронизации: Error, Equatable, Sendable {
    public let код: String
    public let пояснение: String

    public init(код: String, пояснение: String) {
        self.код = код
        self.пояснение = пояснение
    }

    public func представление() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = (try? encoder.encode(ОтветОтказа(схема: "fum.отказ-синхронизации.1", код: код,
            пояснение: пояснение))) ?? Data("{\"код\":\"отказ\"}".utf8)
        data.append(10)
        return data
    }
}

private struct ОтветОтказа: Encodable {
    let схема: String
    let код: String
    let пояснение: String
}

public enum КомандаСинхронизации {
    public static let справка = """
    Использование:
      swift run fuma синхронизация inventory --вход <inventory.json>
      swift run fuma синхронизация plan --вход <inventory.json>
      swift run fuma синхронизация apply --вход <inventory.json> --план <plan.json>
      swift run fuma синхронизация no-op --вход <inventory.json> --план <plan.json>

    Вход — один явный typed snapshot. Команда не сканирует рабочее дерево и не изменяет Git,
    файлы или чаты. apply/no-op возвращают только квитанцию read-only no-op.
    """

    public static func выполнить(_ arguments: [String]) async throws -> Data {
        guard let operation = arguments.first else {
            throw ОтказСинхронизации(код: "аргументы", пояснение: справка)
        }

        do {
            switch operation {
            case "помощь", "--help", "-h":
                guard arguments.count == 1 else {
                    throw ОтказСинхронизации(код: "аргументы", пояснение: "Справка не принимает параметры.")
                }
                return Data((справка + "\n").utf8)
            case "inventory":
                let inputPath = try аргументВхода(arguments, ожидаемоеЧисло: 3)
                let inventory = try разобратьИнвентарь(из: inputPath)
                try ВалидаторИнвентаря.проверить(inventory)
                return try кодировать(inventory)
            case "plan":
                let inputPath = try аргументВхода(arguments, ожидаемоеЧисло: 3)
                let inventory = try разобратьИнвентарь(из: inputPath)
                return try ПланировщикСинхронизации.построить(inventory).байты()
            case "apply", "no-op":
                let paths = try аргументыПлана(arguments)
                let inventory = try разобратьИнвентарь(из: paths.вход)
                let planData = try Data(contentsOf: URL(fileURLWithPath: paths.план))
                let plan = try JSONDecoder().decode(ПланСинхронизации.self, from: planData)
                let receipt = try АдаптерСинхронизации.применить(plan, текущее: inventory)
                return try кодировать(receipt)
            default:
                throw ОтказСинхронизации(код: "аргументы", пояснение: "Неизвестная операция.\n\(справка)")
            }
        } catch let отказ as ОтказСинхронизации {
            throw отказ
        } catch ОшибкаИнвентаря.коллизия {
            throw ОтказСинхронизации(код: "коллизия", пояснение: "Инвентарь содержит конфликтующие пути.")
        } catch ОшибкаИнвентаря.источник {
            throw ОтказСинхронизации(код: "источник", пояснение: "Источник или карта не совпали с выбранной ревизией.")
        } catch ОшибкаИнвентаря.путь {
            throw ОтказСинхронизации(код: "путь", пояснение: "Инвентарь содержит недопустимый путь.")
        } catch ОшибкаИнвентаря.предел {
            throw ОтказСинхронизации(код: "предел", пояснение: "Инвентарь превышает конечный предел.")
        } catch is ОшибкаИнвентаря {
            throw ОтказСинхронизации(код: "инвентарь", пояснение: "Git snapshot не прошёл проверку.")
        } catch ОшибкаСинхронизации.дрейф {
            throw ОтказСинхронизации(код: "дрейф", пояснение: "Текущий snapshot отличается от плана.")
        } catch ОшибкаСинхронизации.запрещённоеСостояние {
            throw ОтказСинхронизации(код: "состояние", пояснение: "План заблокирован состоянием инвентаря.")
        } catch ОшибкаСинхронизации.повреждённыйПлан {
            throw ОтказСинхронизации(код: "план", пояснение: "Идентификатор плана не совпадает с его содержимым.")
        } catch {
            throw ОтказСинхронизации(код: "вход", пояснение: "Входные данные не удалось разобрать.")
        }
    }
}

public enum ФазаНамеренияRef: String, Codable, Equatable, Sendable {
    case подготовлено
    case эффектНаблюдён
    case завершено
}

public struct НамерениеСозданияСобственногоRef: Codable, Equatable, Sendable {
    public let идентификатор: String
    public let план: String
    public let владелец: String
    public let исходныйRef: String
    public let целевойRef: String
    public let oid: String

    fileprivate init(
        идентификатор: String, план: String, владелец: String,
        исходныйRef: String, целевойRef: String, oid: String
    ) {
        self.идентификатор = идентификатор
        self.план = план
        self.владелец = владелец
        self.исходныйRef = исходныйRef
        self.целевойRef = целевойRef
        self.oid = oid
    }
}

public struct КвитанцияСозданияСобственногоRef: Codable, Equatable, Sendable {
    public let намерение: String
    public let ref: String
    public let oid: String

    fileprivate init(намерение: String, ref: String, oid: String) {
        self.намерение = намерение
        self.ref = ref
        self.oid = oid
    }
}

public enum ОтказСозданияСобственногоRef: Error, Equatable, Sendable {
    case план
    case чужойRef
    case целевойRefЗанят
    case дрейфПослеЭффекта
    case намерениеИзменено
    case прерваноПослеЭффекта
}

fileprivate struct ЗаписьНамеренияRef: Sendable {
    let намерение: НамерениеСозданияСобственногоRef
    var фаза: ФазаНамеренияRef
    var квитанция: КвитанцияСозданияСобственногоRef?
}

/// Модель bounded ref store для проверки повторного чтения после частичного эффекта.
/// Она не запускает Git и не представляет собой установленный файловый backend.
public struct СостояниеRefСинхронизации: Sendable {
    public private(set) var refs: [String: String]
    public private(set) var эффектов: Int
    fileprivate var намерения: [String: ЗаписьНамеренияRef]

    public init(refs: [String: String] = [:]) {
        self.refs = refs
        эффектов = 0
        намерения = [:]
    }

    fileprivate mutating func создатьRefЕслиСвободен(_ ref: String, oid: String) -> Bool {
        guard refs[ref] == nil else { return false }
        refs[ref] = oid
        эффектов += 1
        return true
    }

    public func фаза(намерение: String) -> ФазаНамеренияRef? {
        намерения[намерение]?.фаза
    }
}

private struct СодержимоеНамеренияRef: Encodable {
    let план: String
    let владелец: String
    let исходныйRef: String
    let целевойRef: String
    let oid: String
}

public enum АдаптерСобственногоRef {
    public static func подготовить(
        план: ПланСинхронизации, целевойRef: String
    ) throws -> НамерениеСозданияСобственногоRef {
        guard план.целостен(), план.решение == .readOnlyNoOp,
              допустимыйЦелевойRef(целевойRef, исходныйRef: план.снимок.ref)
        else { throw ОтказСозданияСобственногоRef.план }
        let содержимое = СодержимоеНамеренияRef(
            план: план.идентификатор, владелец: план.писатель,
            исходныйRef: план.снимок.ref, целевойRef: целевойRef,
            oid: план.снимок.head)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let bytes = try encoder.encode(содержимое)
        let identifier = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        return НамерениеСозданияСобственногоRef(
            идентификатор: identifier, план: план.идентификатор,
            владелец: план.писатель, исходныйRef: план.снимок.ref,
            целевойRef: целевойRef, oid: план.снимок.head)
    }

    public static func применить(
        _ intent: НамерениеСозданияСобственногоRef,
        к state: inout СостояниеRefСинхронизации,
        прерватьПослеЭффекта: Bool = false
    ) throws -> КвитанцияСозданияСобственногоRef {
        guard допустимыйЦелевойRef(intent.целевойRef, исходныйRef: intent.исходныйRef),
              целостноеНамерение(intent)
        else { throw ОтказСозданияСобственногоRef.намерениеИзменено }

        var entry: ЗаписьНамеренияRef
        if let previous = state.намерения[intent.идентификатор] {
            guard previous.намерение == intent else {
                throw ОтказСозданияСобственногоRef.намерениеИзменено
            }
            entry = previous
            if entry.фаза == .завершено {
                guard state.refs[intent.целевойRef] == intent.oid,
                      let receipt = entry.квитанция
                else { throw ОтказСозданияСобственногоRef.дрейфПослеЭффекта }
                return receipt
            }
        } else {
            entry = ЗаписьНамеренияRef(намерение: intent, фаза: .подготовлено, квитанция: nil)
            state.намерения[intent.идентификатор] = entry
        }

        switch entry.фаза {
        case .подготовлено:
            guard state.создатьRefЕслиСвободен(intent.целевойRef, oid: intent.oid) else {
                throw ОтказСозданияСобственногоRef.целевойRefЗанят
            }
            entry.фаза = .эффектНаблюдён
            state.намерения[intent.идентификатор] = entry
            if прерватьПослеЭффекта {
                throw ОтказСозданияСобственногоRef.прерваноПослеЭффекта
            }
        case .эффектНаблюдён:
            guard state.refs[intent.целевойRef] == intent.oid else {
                throw ОтказСозданияСобственногоRef.дрейфПослеЭффекта
            }
        case .завершено:
            throw ОтказСозданияСобственногоRef.дрейфПослеЭффекта
        }

        let receipt = КвитанцияСозданияСобственногоRef(
            намерение: intent.идентификатор, ref: intent.целевойRef, oid: intent.oid)
        entry.фаза = .завершено
        entry.квитанция = receipt
        state.намерения[intent.идентификатор] = entry
        return receipt
    }

    private static func целостноеНамерение(_ intent: НамерениеСозданияСобственногоRef) -> Bool {
        let content = СодержимоеНамеренияRef(
            план: intent.план, владелец: intent.владелец,
            исходныйRef: intent.исходныйRef, целевойRef: intent.целевойRef, oid: intent.oid)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(content) else { return false }
        let expected = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return expected == intent.идентификатор
    }

    private static func допустимыйЦелевойRef(_ target: String, исходныйRef: String) -> Bool {
        let suffix = "/master"
        guard исходныйRef.hasPrefix("refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/"),
              исходныйRef.hasSuffix(suffix), target.hasPrefix("refs/heads/"),
              target != исходныйRef, !target.contains("\\"),
              !target.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
        else { return false }
        let namespace = String(исходныйRef.dropLast(suffix.count))
        guard target.hasPrefix(namespace + "/") else { return false }
        return target.split(separator: "/", omittingEmptySubsequences: false)
            .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
}

private extension КомандаСинхронизации {
    private static func аргументВхода(_ arguments: [String], ожидаемоеЧисло: Int) throws -> String {
        guard arguments.count == ожидаемоеЧисло,
              arguments[1] == "--вход", !arguments[2].isEmpty
        else { throw ОтказСинхронизации(код: "аргументы", пояснение: "Ожидаются --вход и один путь.") }
        return arguments[2]
    }

    private static func аргументыПлана(_ arguments: [String]) throws -> (вход: String, план: String) {
        guard arguments.count == 5, arguments[1] == "--вход", arguments[3] == "--план",
              !arguments[2].isEmpty, !arguments[4].isEmpty
        else {
            throw ОтказСинхронизации(
                код: "аргументы", пояснение: "Ожидаются --вход и --план с непустыми путями.")
        }
        return (arguments[2], arguments[4])
    }

    private static func разобратьИнвентарь(из path: String) throws -> ПакетныйИнвентарьСинхронизации {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(ПакетныйИнвентарьСинхронизации.self, from: data)
    }

    private static func кодировать<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(10)
        return data
    }
}
