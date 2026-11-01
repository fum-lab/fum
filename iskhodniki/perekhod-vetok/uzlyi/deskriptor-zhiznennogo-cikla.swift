import Foundation

public enum ОшибкаЖизненногоЦикла: Error, Equatable, Sendable {
    case схема
    case идентичность
    case чужойКорень
    case чужойУзел
    case другойЧат
    case другойХод
    case другойRef
    case другойWorktree
    case другойSource
    case другаяВерсияСостояния
    case повреждённыйCheckpoint
    case неподдержаннаяПолномочность
    case нетИзвестногоСледующегоШага
    case несовпадениеOperationID
    case несовпадениеПовторногоЧтения
}

public struct СостояниеУзлаЖизненногоЦикла: Codable, Equatable, Sendable {
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let sourceTree: String
    public let версияСостояния: UInt64

    public init(
        корневаяЗадачаUUID: String, nativeChatUUID: String, executionTurn: String,
        логическийУзел: String, полныйRef: String, физическийWorktree: String,
        sourceCommit: String, sourceTree: String, версияСостояния: UInt64
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
    }
}

public struct КонтрольнаяТочкаЖизненногоЦикла: Codable, Equatable, Sendable {
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let sourceTree: String
    public let версияСостояния: UInt64
    public let завершённыйШагID: String?
    public let следующийРазрешённыйШагID: String

    public init(
        корневаяЗадачаUUID: String, nativeChatUUID: String, executionTurn: String,
        логическийУзел: String, полныйRef: String,
        физическийWorktree: String, sourceCommit: String, sourceTree: String,
        версияСостояния: UInt64, завершённыйШагID: String?, следующийРазрешённыйШагID: String
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
        self.завершённыйШагID = завершённыйШагID
        self.следующийРазрешённыйШагID = следующийРазрешённыйШагID
    }
}

public struct ГраницаПолномочийЖизненногоЦикла: Codable, Equatable, Sendable {
    public let разрешённыеПути: [String]
    public let можетЗапускатьCallback: Bool
    public let можетПубликовать: Bool
    public let можетАктивироватьRuntime: Bool
    public let unknownТребуетНовогоНаблюдения: Bool

    public init(
        разрешённыеПути: [String], можетЗапускатьCallback: Bool = false,
        можетПубликовать: Bool = false, можетАктивироватьRuntime: Bool = false,
        unknownТребуетНовогоНаблюдения: Bool = true
    ) {
        self.разрешённыеПути = разрешённыеПути
        self.можетЗапускатьCallback = можетЗапускатьCallback
        self.можетПубликовать = можетПубликовать
        self.можетАктивироватьRuntime = можетАктивироватьRuntime
        self.unknownТребуетНовогоНаблюдения = unknownТребуетНовогоНаблюдения
    }
}

/// Адресные параметры для будущего Native callback. Значение не запускает callback.
public struct ПараметрыNativeВызоваЖизненногоЦикла: Codable, Equatable, Sendable {
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let sourceCommit: String
    public let checkpointStateVersion: UInt64?
}

/// Адресные параметры для будущего publisher. Значение не публикует и не даёт полномочий.
public struct ПараметрыПубликацииЖизненногоЦикла: Codable, Equatable, Sendable {
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let ожидаемыйSourceCommit: String
    public let разрешённыеПути: [String]
}

public struct ДескрипторЖизненногоЦиклаУзла: Codable, Equatable, Sendable {
    public static let схема = "fum.descriptor-node-lifecycle.1"

    public let схемаВерсии: String
    public let корневаяЗадачаUUID: String
    public let nativeChatUUID: String
    public let executionTurn: String
    public let логическийУзел: String
    public let полныйRef: String
    public let физическийWorktree: String
    public let текущееСостояние: СостояниеУзлаЖизненногоЦикла
    public let checkpoint: КонтрольнаяТочкаЖизненногоЦикла?
    public let версияПроисхождения: String
    public let границаПолномочий: ГраницаПолномочийЖизненногоЦикла

    public init(
        корневаяЗадачаUUID: String, nativeChatUUID: String, executionTurn: String,
        логическийУзел: String, полныйRef: String, физическийWorktree: String,
        текущееСостояние: СостояниеУзлаЖизненногоЦикла,
        checkpoint: КонтрольнаяТочкаЖизненногоЦикла?, версияПроисхождения: String,
        границаПолномочий: ГраницаПолномочийЖизненногоЦикла
    ) {
        схемаВерсии = Self.схема
        self.корневаяЗадачаUUID = корневаяЗадачаUUID
        self.nativeChatUUID = nativeChatUUID
        self.executionTurn = executionTurn
        self.логическийУзел = логическийУзел
        self.полныйRef = полныйRef
        self.физическийWorktree = физическийWorktree
        self.текущееСостояние = текущееСостояние
        self.checkpoint = checkpoint
        self.версияПроисхождения = версияПроисхождения
        self.границаПолномочий = границаПолномочий
    }

    public func проверитьСвязность() throws {
        guard схемаВерсии == Self.схема else { throw ОшибкаЖизненногоЦикла.схема }
        guard UUID(uuidString: корневаяЗадачаUUID) != nil,
              UUID(uuidString: nativeChatUUID) != nil,
              UUID(uuidString: executionTurn) != nil,
              !логическийУзел.isEmpty, полныйRef.hasPrefix("refs/heads/"),
              физическийWorktree.hasPrefix("/"), !версияПроисхождения.isEmpty,
              Self.похожНаOID(текущееСостояние.sourceCommit),
              Self.похожНаOID(текущееСостояние.sourceTree)
        else { throw ОшибкаЖизненногоЦикла.идентичность }
        try проверить(текущееСостояние)
        guard границаПолномочий.unknownТребуетНовогоНаблюдения,
              !границаПолномочий.можетЗапускатьCallback,
              !границаПолномочий.можетПубликовать,
              !границаПолномочий.можетАктивироватьRuntime,
              !границаПолномочий.разрешённыеПути.isEmpty
        else { throw ОшибкаЖизненногоЦикла.неподдержаннаяПолномочность }
        if let checkpoint { try проверить(checkpoint) }
    }

    public func проверить(_ состояние: СостояниеУзлаЖизненногоЦикла) throws {
        guard состояние.корневаяЗадачаUUID == корневаяЗадачаUUID else {
            throw ОшибкаЖизненногоЦикла.чужойКорень
        }
        guard состояние.nativeChatUUID == nativeChatUUID else { throw ОшибкаЖизненногоЦикла.другойЧат }
        guard состояние.executionTurn == executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
        guard состояние.логическийУзел == логическийУзел else { throw ОшибкаЖизненногоЦикла.чужойУзел }
        guard состояние.полныйRef == полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
        guard состояние.физическийWorktree == физическийWorktree else {
            throw ОшибкаЖизненногоЦикла.другойWorktree
        }
        guard Self.похожНаOID(состояние.sourceCommit), Self.похожНаOID(состояние.sourceTree) else {
            throw ОшибкаЖизненногоЦикла.другойSource
        }
        guard состояние.sourceCommit == текущееСостояние.sourceCommit,
              состояние.sourceTree == текущееСостояние.sourceTree
        else { throw ОшибкаЖизненногоЦикла.другойSource }
        guard состояние.версияСостояния == текущееСостояние.версияСостояния else {
            throw ОшибкаЖизненногоЦикла.другаяВерсияСостояния
        }
    }

    public func параметрыNativeВызова() throws -> ПараметрыNativeВызоваЖизненногоЦикла {
        try проверитьСвязность()
        return ПараметрыNativeВызоваЖизненногоЦикла(
            nativeChatUUID: nativeChatUUID, executionTurn: executionTurn,
            логическийУзел: логическийУзел, полныйRef: полныйRef,
            физическийWorktree: физическийWorktree,
            sourceCommit: текущееСостояние.sourceCommit,
            checkpointStateVersion: checkpoint?.версияСостояния)
    }

    public func параметрыПубликации() throws -> ПараметрыПубликацииЖизненногоЦикла {
        try проверитьСвязность()
        return ПараметрыПубликацииЖизненногоЦикла(
            nativeChatUUID: nativeChatUUID, executionTurn: executionTurn,
            логическийУзел: логическийУзел, полныйRef: полныйRef,
            физическийWorktree: физическийWorktree,
            ожидаемыйSourceCommit: текущееСостояние.sourceCommit,
            разрешённыеПути: границаПолномочий.разрешённыеПути)
    }

    private static func похожНаOID(_ значение: String) -> Bool {
        значение.count == 40 && значение.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private func проверить(_ checkpoint: КонтрольнаяТочкаЖизненногоЦикла) throws {
        guard checkpoint.корневаяЗадачаUUID == корневаяЗадачаUUID else {
            throw ОшибкаЖизненногоЦикла.чужойКорень
        }
        guard checkpoint.nativeChatUUID == nativeChatUUID else { throw ОшибкаЖизненногоЦикла.другойЧат }
        guard checkpoint.executionTurn == executionTurn else { throw ОшибкаЖизненногоЦикла.другойХод }
        guard checkpoint.логическийУзел == логическийУзел else { throw ОшибкаЖизненногоЦикла.чужойУзел }
        guard checkpoint.полныйRef == полныйRef else { throw ОшибкаЖизненногоЦикла.другойRef }
        guard checkpoint.физическийWorktree == физическийWorktree else {
            throw ОшибкаЖизненногоЦикла.другойWorktree
        }
        guard checkpoint.sourceCommit == текущееСостояние.sourceCommit,
              checkpoint.sourceTree == текущееСостояние.sourceTree,
              checkpoint.версияСостояния == текущееСостояние.версияСостояния,
              !checkpoint.следующийРазрешённыйШагID.isEmpty
        else { throw ОшибкаЖизненногоЦикла.повреждённыйCheckpoint }
    }
}
