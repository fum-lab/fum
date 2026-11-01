import Foundation

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
        guard !шаги.isEmpty, Set(шаги.map(\.id)).count == шаги.count,
              шаги.allSatisfy({ $0.требуемыйSourceCommit == дескриптор.текущееСостояние.sourceCommit })
        else { throw ОшибкаЖизненногоЦикла.идентичность }
    }

    /// Возвращает шаг, явно указанный checkpoint; если checkpoint отсутствует — первый разрешённый.
    public func следующийШаг(после checkpoint: КонтрольнаяТочкаЖизненногоЦикла?) throws -> ШагЖизненногоЦикла {
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
        return шаг
    }

    public func вернутьСписокПослеСохранения(
        _ сообщение: СохраненноеВходящееСообщениеЖизненногоЦикла
    ) throws -> [ШагЖизненногоЦикла] {
        guard сообщение.nativeChatUUID == nativeChatUUID else { throw ОшибкаЖизненногоЦикла.другойЧат }
        guard сообщение.executionTurn == executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
        guard сообщение.корневаяЗадачаUUID == корневаяЗадачаUUID else {
            throw ОшибкаЖизненногоЦикла.чужойКорень
        }
        guard сообщение.логическийУзел == логическийУзел else { throw ОшибкаЖизненногоЦикла.чужойУзел }
        guard сообщение.полныйRef == полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
        guard сообщение.физическийWorktree == физическийWorktree else {
            throw ОшибкаЖизненногоЦикла.другойWorktree
        }
        guard сообщение.sourceCommit == sourceCommit, сообщение.sourceTree == sourceTree,
              сообщение.версияСостояния == версияСостояния
        else { throw ОшибкаЖизненногоЦикла.другойSource }
        guard сообщение.состояние == .сохранено, !сообщение.messageID.isEmpty else {
            throw ОшибкаЖизненногоЦикла.идентичность
        }
        return шаги
    }
}

public enum СостояниеВходящегоСообщенияЖизненногоЦикла: String, Codable, Equatable, Sendable {
    case получено
    case сохранено
}

public struct СохраненноеВходящееСообщениеЖизненногоЦикла: Codable, Equatable, Sendable {
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let sourceTree: String
    public let версияСостояния: UInt64
    public let messageID: String
    public let состояние: СостояниеВходящегоСообщенияЖизненногоЦикла

    init(
        корневаяЗадачаUUID: String, nativeChatUUID: String, executionTurn: String,
        логическийУзел: String, полныйRef: String, физическийWorktree: String,
        sourceCommit: String, sourceTree: String, версияСостояния: UInt64, messageID: String,
        состояние: СостояниеВходящегоСообщенияЖизненногоЦикла
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
        self.messageID = messageID
        self.состояние = состояние
    }
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
