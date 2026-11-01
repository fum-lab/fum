import Foundation
import CryptoKit

public enum СостояниеШагаЖизненногоЦикла: String, Codable, Equatable, Sendable {
    case разрешён
    case вОчереди
    case ожидаетПредусловие
    case выполняется
    case завершён
    case неизвестен
}

public struct ШагЖизненногоЦикла: Codable, Equatable, Sendable {
    public let id: String
    public let состояние: СостояниеШагаЖизненногоЦикла
    public let требуемыйSourceCommit: String

    public init(id: String, состояние: СостояниеШагаЖизненногоЦикла, требуемыйSourceCommit: String) {
        self.id = id
        self.состояние = состояние
        self.требуемыйSourceCommit = требуемыйSourceCommit
    }
}

public struct СвойРабочийСписокУзла: Codable, Equatable, Sendable {
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let sourceTree: String
    public let версияСостояния: UInt64
    public let шаги: [ШагЖизненногоЦикла]

    public init(дескриптор: ДескрипторЖизненногоЦиклаУзла, шаги: [ШагЖизненногоЦикла]) throws {
        try дескриптор.проверитьСвязность()
        корневаяЗадачаUUID = дескриптор.корневаяЗадачаUUID
        nativeChatUUID = дескриптор.nativeChatUUID
        executionTurn = дескриптор.executionTurn
        логическийУзел = дескриптор.логическийУзел
        полныйRef = дескриптор.полныйRef
        физическийWorktree = дескриптор.физическийWorktree
        sourceCommit = дескриптор.текущееСостояние.sourceCommit
        sourceTree = дескриптор.текущееСостояние.sourceTree
        версияСостояния = дескриптор.текущееСостояние.версияСостояния
        self.шаги = шаги
        guard !шаги.isEmpty, шаги.allSatisfy({ !$0.id.isEmpty }),
              Set(шаги.map(\.id)).count == шаги.count,
              шаги.allSatisfy({ $0.требуемыйSourceCommit == дескриптор.текущееСостояние.sourceCommit })
        else { throw ОшибкаЖизненногоЦикла.идентичность }
    }

    /// Возвращает шаг, явно указанный checkpoint; если checkpoint отсутствует — первый разрешённый.
    public func следующийШаг(после checkpoint: КонтрольнаяТочкаЖизненногоЦикла?) throws -> ШагЖизненногоЦикла {
        try проверитьСобственнуюЦелостность()
        if let checkpoint {
            guard checkpoint.корневаяЗадачаUUID == корневаяЗадачаUUID else {
                throw ОшибкаЖизненногоЦикла.чужойКорень
            }
            guard checkpoint.nativeChatUUID == nativeChatUUID else {
                throw ОшибкаЖизненногоЦикла.другойЧат
            }
            guard checkpoint.executionTurn == executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
            guard checkpoint.логическийУзел == логическийУзел else { throw ОшибкаЖизненногоЦикла.чужойУзел }
            guard checkpoint.полныйRef == полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
            guard checkpoint.физическийWorktree == физическийWorktree else {
                throw ОшибкаЖизненногоЦикла.другойWorktree
            }
            guard checkpoint.sourceCommit == sourceCommit, checkpoint.sourceTree == sourceTree else {
                throw ОшибкаЖизненногоЦикла.другойSource
            }
            guard checkpoint.версияСостояния == версияСостояния else {
                throw ОшибкаЖизненногоЦикла.другаяВерсияСостояния
            }
        }
        let id = checkpoint?.следующийРазрешённыйШагID
        let шаг: ШагЖизненногоЦикла?
        if let id {
            шаг = шаги.first(where: { $0.id == id })
        } else {
            шаг = шаги.first(where: { $0.состояние == .разрешён })
        }
        guard let шаг, шаг.состояние == .разрешён else {
            throw ОшибкаЖизненногоЦикла.нетИзвестногоСледующегоШага
        }
        guard шаг.требуемыйSourceCommit == sourceCommit else { throw ОшибкаЖизненногоЦикла.другойSource }
        return шаг
    }

    /// Подтверждает точный сохранённый список без выбора следующего шага.
    /// Реализации хранилища и автоматического повтора здесь нет; повтор использует тот же operation ID.
    public func подтвердитьСписокПослеСохранения(
        _ сообщение: ВходящееСообщениеЖизненногоЦикла,
        дескриптор: ДескрипторЖизненногоЦиклаУзла,
        сохранитьИПереоткрыть: СохранитьИПереоткрытьЖизненныйЦикл
    ) async throws -> ПодтверждениеПереоткрытияРабочегоСписка {
        try дескриптор.проверитьСвязность()
        try проверитьАдрес(дескриптора: дескриптор)
        let запрос = try ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла(
            дескриптор: дескриптор, рабочийСписок: self, сообщение: сообщение)
        let квитанция = try await сохранитьИПереоткрыть(запрос)
        guard квитанция.operationID == запрос.operationID else {
            throw ОшибкаЖизненногоЦикла.несовпадениеOperationID
        }
        guard квитанция.sha256Запроса == запрос.sha256КаноническихБайтов,
              квитанция.байтыПовторногоЧтения == запрос.каноническиеБайты,
              квитанция.sha256ПовторногоЧтения == Self.sha256(квитанция.байтыПовторногоЧтения)
        else { throw ОшибкаЖизненногоЦикла.несовпадениеПовторногоЧтения }
        try квитанция.переоткрытыйРабочийСписок.проверитьАдрес(дескриптора: дескриптор)
        guard квитанция.переоткрытыйРабочийСписок == self else {
            throw ОшибкаЖизненногоЦикла.несовпадениеРабочегоСпискаПереоткрытия
        }
        return ПодтверждениеПереоткрытияРабочегоСписка(
            operationID: запрос.operationID, messageID: сообщение.messageID,
            sha256СохранённогоСообщения: запрос.sha256КаноническихБайтов,
            рабочийСписок: квитанция.переоткрытыйРабочийСписок)
    }

    /// Совместимый API: подтверждает readback, затем обязательно выбирает разрешённый шаг.
    public func вернутьСписокПослеСохранения(
        _ сообщение: ВходящееСообщениеЖизненногоЦикла,
        дескриптор: ДескрипторЖизненногоЦиклаУзла,
        сохранитьИПереоткрыть: СохранитьИПереоткрытьЖизненныйЦикл
    ) async throws -> РезультатПереоткрытияРабочегоСписка {
        let подтверждение = try await подтвердитьСписокПослеСохранения(
            сообщение, дескриптор: дескриптор, сохранитьИПереоткрыть: сохранитьИПереоткрыть)
        let следующий = try подтверждение.рабочийСписок.следующийШаг(после: дескриптор.checkpoint)
        return РезультатПереоткрытияРабочегоСписка(
            operationID: подтверждение.operationID, messageID: подтверждение.messageID,
            sha256СохранённогоСообщения: подтверждение.sha256СохранённогоСообщения,
            рабочийСписок: подтверждение.рабочийСписок, следующийРазрешённыйШаг: следующий)
    }

    fileprivate func проверитьАдрес(дескриптора д: ДескрипторЖизненногоЦиклаУзла) throws {
        try проверитьСобственнуюЦелостность()
        guard корневаяЗадачаUUID == д.корневаяЗадачаUUID else { throw ОшибкаЖизненногоЦикла.чужойКорень }
        guard nativeChatUUID == д.nativeChatUUID else { throw ОшибкаЖизненногоЦикла.другойЧат }
        guard executionTurn == д.executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
        guard логическийУзел == д.логическийУзел else { throw ОшибкаЖизненногоЦикла.чужойУзел }
        guard полныйRef == д.полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
        guard физическийWorktree == д.физическийWorktree else { throw ОшибкаЖизненногоЦикла.другойWorktree }
        guard sourceCommit == д.текущееСостояние.sourceCommit,
              sourceTree == д.текущееСостояние.sourceTree
        else { throw ОшибкаЖизненногоЦикла.другойSource }
        guard версияСостояния == д.текущееСостояние.версияСостояния else {
            throw ОшибкаЖизненногоЦикла.другаяВерсияСостояния
        }
    }

    private func проверитьСобственнуюЦелостность() throws {
        guard UUID(uuidString: корневаяЗадачаUUID) != nil,
              UUID(uuidString: nativeChatUUID) != nil,
              UUID(uuidString: executionTurn) != nil,
              !логическийУзел.isEmpty, полныйRef.hasPrefix("refs/heads/"),
              физическийWorktree.hasPrefix("/"), Self.похожНаOID(sourceCommit),
              Self.похожНаOID(sourceTree), !шаги.isEmpty,
              шаги.allSatisfy({ !$0.id.isEmpty }),
              Set(шаги.map(\.id)).count == шаги.count
        else { throw ОшибкаЖизненногоЦикла.идентичность }
        guard шаги.allSatisfy({ $0.требуемыйSourceCommit == sourceCommit }) else {
            throw ОшибкаЖизненногоЦикла.другойSource
        }
    }

    fileprivate static func sha256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private static func похожНаOID(_ значение: String) -> Bool {
        значение.count == 40 && значение.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}

public struct ВходящееСообщениеЖизненногоЦикла: Equatable, Sendable {
    public let messageID: String
    public let исходныеБайты: Data

    public init(messageID: String, исходныеБайты: Data) {
        self.messageID = messageID
        self.исходныеБайты = исходныеБайты
    }
}

public struct ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла: Sendable, Equatable {
    public let operationID: String
    public let messageID: String
    public let каноническиеБайты: Data
    public let sha256КаноническихБайтов: String

    public init(
        дескриптор: ДескрипторЖизненногоЦиклаУзла,
        рабочийСписок: СвойРабочийСписокУзла,
        сообщение: ВходящееСообщениеЖизненногоЦикла
    ) throws {
        guard !сообщение.messageID.isEmpty, !сообщение.messageID.utf8.contains(0) else {
            throw ОшибкаЖизненногоЦикла.идентичность
        }
        try дескриптор.проверитьСвязность()
        try рабочийСписок.проверитьАдрес(дескриптора: дескриптор)
        operationID = try Self.stableOperationID(
            rootUUID: дескриптор.корневаяЗадачаUUID,
            nativeChatUUID: дескриптор.nativeChatUUID,
            messageID: сообщение.messageID)
        self.messageID = сообщение.messageID
        var кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var байты = try кодировщик.encode(СохранённыйКонвертЖизненногоЦикла(
            схема: "fum.lifecycle-message-persist.1", operationID: operationID,
            дескриптор: дескриптор, рабочийСписок: рабочийСписок,
            messageID: сообщение.messageID, исходныеБайты: сообщение.исходныеБайты))
        байты.append(0x0a)
        каноническиеБайты = байты
        sha256КаноническихБайтов = СвойРабочийСписокУзла.sha256(байты)
    }

    private static func stableOperationID(rootUUID: String, nativeChatUUID: String, messageID: String) throws -> String {
        struct Идентичность: Encodable {
            let rootUUID: String
            let nativeChatUUID: String
            let messageID: String
        }
        var кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let bytes = try кодировщик.encode(Идентичность(
            rootUUID: rootUUID, nativeChatUUID: nativeChatUUID, messageID: messageID))
        return "fum.lifecycle.message.v1." + СвойРабочийСписокУзла.sha256(bytes)
    }

    /// Разбирает только точный канонический конверт, прочитанный из сохранённых байтов.
    public static func декодироватьСохранённыйКонверт(
        _ байты: Data
    ) throws -> СохранённыйКонвертЖизненногоЦикла {
        let конверт = try JSONDecoder().decode(СохранённыйКонвертЖизненногоЦикла.self, from: байты)
        guard конверт.схема == "fum.lifecycle-message-persist.1" else {
            throw ОшибкаЖизненногоЦикла.схема
        }
        let запрос = try Self(
            дескриптор: конверт.дескриптор,
            рабочийСписок: конверт.рабочийСписок,
            сообщение: ВходящееСообщениеЖизненногоЦикла(
                messageID: конверт.messageID, исходныеБайты: конверт.исходныеБайты))
        guard запрос.operationID == конверт.operationID,
              запрос.каноническиеБайты == байты else {
            throw ОшибкаЖизненногоЦикла.несовпадениеПовторногоЧтения
        }
        return конверт
    }
}

public struct СохранённыйКонвертЖизненногоЦикла: Codable, Equatable, Sendable {
    public let схема: String
    public let operationID: String
    public let дескриптор: ДескрипторЖизненногоЦиклаУзла
    public let рабочийСписок: СвойРабочийСписокУзла
    public let messageID: String
    public let исходныеБайты: Data
}

/// Квитанция адаптера после долговечной записи, закрытия/повторного открытия и точного чтения байтов.
public struct КвитанцияПереоткрытияВходящегоСообщения: Equatable, Sendable {
    public let operationID: String
    public let sha256Запроса: String
    public let байтыПовторногоЧтения: Data
    public let sha256ПовторногоЧтения: String
    public let переоткрытыйРабочийСписок: СвойРабочийСписокУзла

    public init(
        operationID: String, sha256Запроса: String,
        байтыПовторногоЧтения: Data, sha256ПовторногоЧтения: String,
        переоткрытыйРабочийСписок: СвойРабочийСписокУзла
    ) {
        self.operationID = operationID
        self.sha256Запроса = sha256Запроса
        self.байтыПовторногоЧтения = байтыПовторногоЧтения
        self.sha256ПовторногоЧтения = sha256ПовторногоЧтения
        self.переоткрытыйРабочийСписок = переоткрытыйРабочийСписок
    }
}

/// Адаптер должен идемпотентно записать запрос, открыть существующее хранилище и вернуть байты readback.
public typealias СохранитьИПереоткрытьЖизненныйЦикл = @Sendable (
    ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла
) async throws -> КвитанцияПереоткрытияВходящегоСообщения

public struct ПодтверждениеПереоткрытияРабочегоСписка: Equatable, Sendable {
    public let operationID: String
    public let messageID: String
    public let sha256СохранённогоСообщения: String
    public let рабочийСписок: СвойРабочийСписокУзла
}

public struct РезультатПереоткрытияРабочегоСписка: Equatable, Sendable {
    public let operationID: String
    public let messageID: String
    public let sha256СохранённогоСообщения: String
    public let рабочийСписок: СвойРабочийСписокУзла
    public let следующийРазрешённыйШаг: ШагЖизненногоЦикла
}

public enum СостояниеРезультатаДочернегоУзла: String, Codable, Equatable, Sendable {
    case accepted
    case queued
    case prerequisite
    case running
    case completed
    case failed
    case unknown
}

public struct СвидетельствоРезультатаДочернегоУзла: Codable, Equatable, Sendable {
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let sourceTree: String
    public let версияСостояния: UInt64
    public let состояние: СостояниеРезультатаДочернегоУзла
    public let результатИзвестен: Bool

    init(
        корневаяЗадачаUUID: String, nativeChatUUID: String, executionTurn: String,
        логическийУзел: String, полныйRef: String, физическийWorktree: String,
        sourceCommit: String, sourceTree: String, версияСостояния: UInt64,
        состояние: СостояниеРезультатаДочернегоУзла, результатИзвестен: Bool
    ) {
        self.корневаяЗадачаUUID = корневаяЗадачаUUID
        self.nativeChatUUID = nativeChatUUID
        self.executionTurn = executionTurn
        self.логическийУзел = логическийУзел
        self.полныйRef = полныйRef
        self.физическийWorktree = физическийWorktree
        self.sourceCommit = sourceCommit
        self.sourceTree = sourceTree
        self.версияСостояния = версияСостояния
        self.состояние = состояние
        self.результатИзвестен = результатИзвестен
    }
}

public enum РешениеРодителяЖизненногоЦикла: Equatable, Sendable {
    case принятьИзвестныйРезультат(следующийШагID: String?)
    case ждатьНовогоНаблюдения
    case наблюдатьUnknownБезПовтора
}

public enum ПереходЖизненногоЦикла {
    /// Принимает только свидетельство, адресованное тому же узлу и source pin.
    /// Статусы очереди и предусловия не завершают работу; unknown требует наблюдения без replay.
    public static func решитьРезультатРодителю(
        _ результат: СвидетельствоРезультатаДочернегоУзла,
        дескриптор: ДескрипторЖизненногоЦиклаУзла,
        рабочийСписок: СвойРабочийСписокУзла
    ) throws -> РешениеРодителяЖизненногоЦикла {
        try дескриптор.проверитьСвязность()
        guard рабочийСписок.корневаяЗадачаUUID == дескриптор.корневаяЗадачаUUID else {
            throw ОшибкаЖизненногоЦикла.чужойКорень
        }
        guard рабочийСписок.nativeChatUUID == дескриптор.nativeChatUUID else {
            throw ОшибкаЖизненногоЦикла.другойЧат
        }
        guard рабочийСписок.executionTurn == дескриптор.executionTurn else {
            throw ОшибкаЖизненногоЦикла.другойХод
        }
        guard рабочийСписок.логическийУзел == дескриптор.логическийУзел else {
            throw ОшибкаЖизненногоЦикла.чужойУзел
        }
        guard рабочийСписок.полныйRef == дескриптор.полныйRef else {
            throw ОшибкаЖизненногоЦикла.другойRef
        }
        guard рабочийСписок.физическийWorktree == дескриптор.физическийWorktree else {
            throw ОшибкаЖизненногоЦикла.другойWorktree
        }
        guard рабочийСписок.sourceCommit == дескриптор.текущееСостояние.sourceCommit,
              рабочийСписок.sourceTree == дескриптор.текущееСостояние.sourceTree
        else { throw ОшибкаЖизненногоЦикла.другойSource }
        guard рабочийСписок.версияСостояния == дескриптор.текущееСостояние.версияСостояния else {
            throw ОшибкаЖизненногоЦикла.другаяВерсияСостояния
        }
        guard результат.корневаяЗадачаUUID == дескриптор.корневаяЗадачаUUID else {
            throw ОшибкаЖизненногоЦикла.чужойКорень
        }
        guard результат.nativeChatUUID == дескриптор.nativeChatUUID else {
            throw ОшибкаЖизненногоЦикла.другойЧат
        }
        guard результат.executionTurn == дескриптор.executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
        guard результат.логическийУзел == дескриптор.логическийУзел else {
            throw ОшибкаЖизненногоЦикла.чужойУзел
        }
        guard результат.полныйRef == дескриптор.полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
        guard результат.физическийWorktree == дескриптор.физическийWorktree else {
            throw ОшибкаЖизненногоЦикла.другойWorktree
        }
        guard результат.sourceCommit == дескриптор.текущееСостояние.sourceCommit,
              результат.sourceTree == дескриптор.текущееСостояние.sourceTree
        else {
            throw ОшибкаЖизненногоЦикла.другойSource
        }
        guard результат.версияСостояния == дескриптор.текущееСостояние.версияСостояния else {
            throw ОшибкаЖизненногоЦикла.другаяВерсияСостояния
        }
        guard результат.результатИзвестен else { return .наблюдатьUnknownБезПовтора }
        switch результат.состояние {
        case .queued, .prerequisite, .running, .accepted:
            return .ждатьНовогоНаблюдения
        case .unknown:
            return .наблюдатьUnknownБезПовтора
        case .completed, .failed:
            let следующий = try рабочийСписок.следующийШаг(после: дескриптор.checkpoint)
            return .принятьИзвестныйРезультат(следующийШагID: следующий.id)
        }
    }
}
