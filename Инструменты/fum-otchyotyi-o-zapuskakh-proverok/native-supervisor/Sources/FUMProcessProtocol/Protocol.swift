public struct ИдентификаторЗапуска: Equatable, Sendable {
    public let текст: String
    public let байты: [UInt8]

    public init?(_ текст: String) {
        let вход = Array(текст.utf8)
        guard вход.count == 36 else { return nil }
        var результат: [UInt8] = []
        результат.reserveCapacity(16)
        var старшая: UInt8?
        for (номер, байт) in вход.enumerated() {
            if номер == 8 || номер == 13 || номер == 18 || номер == 23 {
                guard байт == 0x2d else { return nil }
                continue
            }
            let тетрада: UInt8
            switch байт {
            case 0x30...0x39: тетрада = байт - 0x30
            case 0x61...0x66: тетрада = байт - 0x61 + 10
            default: return nil
            }
            if let первая = старшая {
                результат.append((первая << 4) | тетрада)
                старшая = nil
            } else {
                старшая = тетрада
            }
        }
        guard старшая == nil, результат.count == 16 else { return nil }
        self.текст = текст
        self.байты = результат
    }
}

public enum ОшибкаПротокола: Error, Equatable, Sendable {
    case невернаяДлина
    case неверныйМаркер
    case неожиданныйИдентификаторЗапуска
    case неверныйСтатус
    case неверныеАргументы
}

public enum КомандаДопускаНаблюдателя: Equatable, Sendable {
    case запустить
    case отклонить
}

public enum КомандаПрерыванияНаблюдателя: UInt8, Sendable {
    case прервать = 0x49
    case завершить = 0x45
}

public func разрешенаПопыткаЗапуска(предыдущее: Int64, текущее: Int64?, срок: Int64) -> Bool {
    guard let текущее else { return false }
    return предыдущее >= 0 && текущее >= предыдущее && текущее < срок
}

public enum РежимСрокаНаблюдателя: Equatable, Sendable {
    case ограниченный(крайЗапуска: Int64, крайОстановки: Int64)
    case безТаймаута(крайПодготовки: Int64, бюджетОчистки: Int64)
    case сТаймаутом(крайПодготовки: Int64, бюджетОчистки: Int64, длительностьЦели: Int64)

    public var крайПодготовки: Int64 {
        switch self {
        case let .ограниченный(край, _), let .безТаймаута(край, _), let .сТаймаутом(край, _, _):
            return край
        }
    }

    public init?(версия: String, край: String, второйПараметр: String, сейчас: Int64,
                 длительностьЦели: String? = nil) {
        guard сейчас >= 0, let крайЧисло = Int64(край), String(крайЧисло) == край,
              let второй = Int64(второйПараметр), String(второй) == второйПараметр,
              крайЧисло > сейчас else { return nil }
        if let длительностьЦели {
            guard версия == "fum-run-witness.6", (1000...30000).contains(второй),
                  let длительность = Int64(длительностьЦели), String(длительность) == длительностьЦели,
                  длительность > 0, длительность <= Int64.max - крайЧисло - второй - 1 else { return nil }
            self = .сТаймаутом(крайПодготовки: крайЧисло, бюджетОчистки: второй, длительностьЦели: длительность)
        } else if версия == "fum-run-witness.5" || версия == "fum-run-witness.6" {
            guard (1000...30000).contains(второй) else { return nil }
            self = .безТаймаута(крайПодготовки: крайЧисло, бюджетОчистки: второй)
        } else if ["fum-run-witness.1", "fum-run-witness.2", "fum-run-witness.3",
                   "fum-run-witness.4"].contains(версия) {
            guard второй > крайЧисло, (1000...30000).contains(второй - крайЧисло) else { return nil }
            self = .ограниченный(крайЗапуска: крайЧисло, крайОстановки: второй)
        } else {
            return nil
        }
    }
}

public func разобратьКомандуДопуска(_ версия: String, _ байт: UInt8) throws -> КомандаДопускаНаблюдателя {
    guard ["fum-run-witness.1", "fum-run-witness.2", "fum-run-witness.3", "fum-run-witness.4",
           "fum-run-witness.5", "fum-run-witness.6"].contains(версия) else {
        throw ОшибкаПротокола.неверныеАргументы
    }
    if байт == 0x47 { return .запустить }
    if байт == 0x41 && (версия == "fum-run-witness.3" || версия == "fum-run-witness.6") {
        return .отклонить
    }
    throw ОшибкаПротокола.неверныеАргументы
}

public enum ПолитикаСредыЦели: Equatable, Sendable {
    case legacy
    case isolatedGit
}

public struct ПараметрыЗапуска: Sendable {
    public let runID: ИдентификаторЗапуска
    public let statusFD: Int32
    public let signalMask: [Int32]
    public let includeRunID: Bool
    public let observationsPath: String?
    public let environmentPolicy: ПолитикаСредыЦели
    // Index in arguments excluding the supervisor executable itself.
    public let targetIndex: Int

    public init(arguments: [String], разрешитьИмяИсполнителя: Bool = false,
                разрешитьПрофильСреды: Bool = false) throws {
        guard arguments.count >= 8, ["fum-supervisor.3", "fum-supervisor.4"].contains(arguments[0]),
              !arguments.contains(where: { $0.contains("\0") }),
              let id = ИдентификаторЗапуска(arguments[1]),
              let fd = Int32(arguments[2]), fd > 2, String(fd) == arguments[2],
              arguments[4] == "run" || arguments[4] == "projection" else {
            throw ОшибкаПротокола.неверныеАргументы
        }
        let policy: ПолитикаСредыЦели = arguments[0] == "fum-supervisor.4" ? .isolatedGit : .legacy
        if разрешитьИмяИсполнителя && policy != .isolatedGit {
            throw ОшибкаПротокола.неверныеАргументы
        }
        if policy == .isolatedGit && !разрешитьПрофильСреды &&
            (arguments[4] != "run" || arguments[5] != "none") {
            throw ОшибкаПротокола.неверныеАргументы
        }
        var mask: [Int32] = []
        if arguments[3] != "none" {
            let components = arguments[3].split(separator: ",", omittingEmptySubsequences: false)
            guard !components.isEmpty, components.count <= 29 else { throw ОшибкаПротокола.неверныеАргументы }
            var previous: Int32 = 0
            for component in components {
                guard let number = Int32(component), String(number) == component,
                      number > previous, number < 32, number != 9, number != 17 else {
                    throw ОшибкаПротокола.неверныеАргументы
                }
                mask.append(number)
                previous = number
            }
        }
        let includeID = arguments[4] == "run"
        let path: String?
        let target: Int
        switch arguments[5] {
        case "none":
            path = nil
            target = 7
        case "path":
            guard includeID, arguments.count >= 9 else { throw ОшибкаПротокола.неверныеАргументы }
            path = arguments[6]
            guard let path, path.hasPrefix("/"),
                  !path.split(separator: "/").contains("..") else { throw ОшибкаПротокола.неверныеАргументы }
            target = 8
        default: throw ОшибкаПротокола.неверныеАргументы
        }
        guard arguments.indices.contains(target), arguments[target - 1] == "--" else {
            throw ОшибкаПротокола.неверныеАргументы
        }
        let исполнитель = arguments[target]
        let абсолютный = исполнитель.hasPrefix("/") && !исполнитель.split(separator: "/").contains("..")
        let имя = разрешитьИмяИсполнителя && !исполнитель.isEmpty && исполнитель != "." &&
            исполнитель != ".." && !исполнитель.contains("/")
        guard абсолютный || имя else { throw ОшибкаПротокола.неверныеАргументы }
        for argument in arguments.dropFirst(target + 1) {
            let option = String(argument.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)[0])
            if option.hasPrefix("--"), option != "--",
               ("--источник-проверок".hasPrefix(option) || option.hasPrefix("--источник-проверок")) {
                throw ОшибкаПротокола.неверныеАргументы
            }
        }
        runID = id
        statusFD = fd
        signalMask = mask
        includeRunID = includeID
        observationsPath = path
        environmentPolicy = policy
        targetIndex = target
    }

    public var targetEnvironment: [String] {
        var result = ["PATH=/bin:/usr/bin", "LC_ALL=C", "GIT_OPTIONAL_LOCKS=0",
                      "GIT_NO_LAZY_FETCH=1", "GIT_NO_REPLACE_OBJECTS=1"]
        if environmentPolicy == .isolatedGit {
            result += ["GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null", "GIT_ATTR_NOSYSTEM=1"]
        }
        if includeRunID { result.append("FUM_CHECK_RUN_ID=" + runID.текст) }
        if let observationsPath { result.append("FUM_CHECK_RUN_OBSERVATIONS_PATH=" + observationsPath) }
        return result
    }

    public static func legacySupervisor(arguments: [String]) throws -> ПараметрыЗапуска {
        let spec = try ПараметрыЗапуска(arguments: arguments)
        guard spec.environmentPolicy == .legacy else { throw ОшибкаПротокола.неверныеАргументы }
        return spec
    }
}

public struct ЗначениеВремени: Comparable, Sendable {
    public let seconds: Int64
    public let nanoseconds: Int64

    public init(seconds: Int64, nanoseconds: Int64) throws {
        guard seconds >= 0, (0..<1_000_000_000).contains(nanoseconds) else {
            throw ОшибкаПротокола.неверныйСтатус
        }
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }

    public static func < (left: ЗначениеВремени, right: ЗначениеВремени) -> Bool {
        left.seconds < right.seconds ||
            (left.seconds == right.seconds && left.nanoseconds < right.nanoseconds)
    }
}

public struct ПредельныйСрокОжидания: Sendable {
    private let start: ЗначениеВремени
    private let end: ЗначениеВремени

    public init(start: ЗначениеВремени) throws {
        self.start = start
        let nanos = start.nanoseconds + 500_000_000
        // start.nanoseconds < 1_000_000_000, поэтому перенос равен только 0 или 1.
        let перенос: Int64 = nanos >= 1_000_000_000 ? 1 : 0
        let (seconds, overflow) = start.seconds.addingReportingOverflow(перенос)
        guard !overflow else { throw ОшибкаПротокола.неверныйСтатус }
        end = try ЗначениеВремени(seconds: seconds, nanoseconds: nanos % 1_000_000_000)
    }

    public func remaining(at now: ЗначениеВремени) throws -> ЗначениеВремени? {
        guard now >= start else { throw ОшибкаПротокола.неверныйСтатус }
        guard now < end else { return nil }
        var seconds = end.seconds - now.seconds
        var nanos = end.nanoseconds - now.nanoseconds
        if nanos < 0 { seconds -= 1; nanos += 1_000_000_000 }
        return try ЗначениеВремени(seconds: seconds, nanoseconds: nanos)
    }
}

public enum РезультатСигнала: Equatable, Sendable {
    case success
    case failure(Int32)
}

public enum РезультатОжидания: Equatable, Sendable {
    case completed
    case recheck
    case failure(Int32)
}

public enum ИсходПопыткиОстановкиГруппы: Equatable, Sendable {
    case identity
    case term(Int32)
    case sleep(Int32)
    case killReturned(РезультатСигнала)
}

/// Вызывающий обеспечивает конечный срок и монотонность времени в sleep.
/// Проверка перед сигналом уменьшает риск, но не устраняет гонку идентификатора группы.
public func попытатьсяОстановитьГруппу(
    isLeader: () -> Bool,
    term: () -> РезультатСигнала,
    sleep: () -> РезультатОжидания,
    kill: () -> РезультатСигнала
) -> ИсходПопыткиОстановкиГруппы {
    guard isLeader() else { return .identity }
    if case let .failure(error) = term() { return .term(error) }
    while true {
        switch sleep() {
        case .recheck: continue
        case .failure(let error): return .sleep(error)
        case .completed:
            guard isLeader() else { return .identity }
            return .killReturned(kill())
        }
    }
}

public struct КадрНеизвестногоИсхода: Equatable, Sendable {
    public let runID: [UInt8]
    public let failure: ИсходПопыткиОстановкиГруппы

    public init(runID: [UInt8], failure: ИсходПопыткиОстановкиГруппы) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        switch failure {
        case .term(let code), .sleep(let code), .killReturned(.failure(let code)):
            guard code > 0 else { throw ОшибкаПротокола.неверныйСтатус }
        case .identity, .killReturned(.success): break
        }
        self.runID = runID
        self.failure = failure
    }

    public func encoded() -> [UInt8] {
        let stage: UInt32
        let error: UInt32
        switch failure {
        case .identity: (stage, error) = (1, 0)
        case .term(let code): (stage, error) = (2, UInt32(bitPattern: code))
        case .sleep(let code): (stage, error) = (3, UInt32(bitPattern: code))
        case .killReturned(let result):
            stage = 4
            switch result {
            case .success: error = 0
            case .failure(let code): error = UInt32(bitPattern: code)
            }
        }
        func networkBytes(_ value: UInt32) -> [UInt8] {
            [UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
             UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
        }
        return [0x46, 0x55, 0x45, 0x31] + runID + networkBytes(stage) + networkBytes(error)
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8]) throws -> КадрНеизвестногоИсхода {
        guard bytes.count == 28, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x45, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let runID = Array(bytes[4..<20])
        guard runID == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let stage = bytes[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let rawError = bytes[24..<28].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let error = Int32(bitPattern: rawError)
        let failure: ИсходПопыткиОстановкиГруппы
        switch (stage, error) {
        case (1, 0): failure = .identity
        case (2, let code) where code > 0: failure = .term(code)
        case (3, let code) where code > 0: failure = .sleep(code)
        case (4, 0): failure = .killReturned(.success)
        case (4, let code) where code > 0: failure = .killReturned(.failure(code))
        default: throw ОшибкаПротокола.неверныйСтатус
        }
        return try КадрНеизвестногоИсхода(runID: runID, failure: failure)
    }
}

public struct КадрНачалаЦели: Equatable, Sendable {
    public let runID: [UInt8]
    public let anchorPID: Int32
    public let targetPID: Int32

    public init(runID: [UInt8], anchorPID: Int32, targetPID: Int32) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard anchorPID > 1, targetPID > 1, anchorPID != targetPID else { throw ОшибкаПротокола.неверныеАргументы }
        self.runID = runID
        self.anchorPID = anchorPID
        self.targetPID = targetPID
    }

    public func encoded() -> [UInt8] {
        func word(_ value: UInt32) -> [UInt8] {
            [UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
             UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
        }
        return [0x46, 0x55, 0x53, 0x31] + runID + word(UInt32(anchorPID)) + word(UInt32(targetPID))
    }

    public func байтыСоВременемНачала(_ время: Int64) throws -> [UInt8] {
        guard время >= 0 else { throw ОшибкаПротокола.неверныеАргументы }
        var байты = encoded()
        байты[3] = 0x32
        let отметка = UInt64(время)
        байты += (0..<8).reversed().map { UInt8(truncatingIfNeeded: отметка >> ($0 * 8)) }
        return байты
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8], anchorPID: Int32) throws -> КадрНачалаЦели {
        guard bytes.count == 28, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x53, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let id = Array(bytes[4..<20])
        guard id == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let anchor = Int32(bitPattern: bytes[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
        let target = Int32(bitPattern: bytes[24..<28].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
        guard anchor == anchorPID else { throw ОшибкаПротокола.неверныйСтатус }
        return try КадрНачалаЦели(runID: id, anchorPID: anchor, targetPID: target)
    }
}

public struct КадрОчисткиЦели: Equatable, Sendable {
    public let runID: [UInt8]
    public let anchorPID: Int32
    public let targetPID: Int32
    public let targetStatus: Int32
    public let timedOut: Bool
    public let прерывание: КомандаПрерыванияНаблюдателя?

    public init(runID: [UInt8], anchorPID: Int32, targetPID: Int32, targetStatus: Int32, timedOut: Bool,
                прерывание: КомандаПрерыванияНаблюдателя? = nil) throws {
        guard anchorPID > 1, targetPID > 1, anchorPID != targetPID, !timedOut || прерывание == nil else {
            throw ОшибкаПротокола.неверныеАргументы
        }
        _ = try КадрСтатуса(runID: runID, rawStatus: targetStatus)
        self.runID = runID
        self.anchorPID = anchorPID
        self.targetPID = targetPID
        self.targetStatus = targetStatus
        self.timedOut = timedOut
        self.прерывание = прерывание
    }

    // Получатель отдельно проверяет выход witness, EOF, срок и совпадение статуса
    // с ранее полученным кадром: сам декодер связь двух кадров не устанавливает.
    public func encoded() -> [UInt8] {
        func word(_ value: UInt32) -> [UInt8] {
            [UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
             UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
        }
        let тип: UInt8 = прерывание == nil ? 0x44 : 0x49
        let исход = прерывание?.rawValue ?? (timedOut ? 1 : 0)
        return [0x46, 0x55, тип, 0x31] + runID + word(UInt32(anchorPID)) + word(UInt32(targetPID)) +
            word(UInt32(bitPattern: targetStatus)) + [0, 0, 0, 9] + [исход]
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8], anchorPID: Int32,
                              targetPID: Int32,
                              прерывание: КомандаПрерыванияНаблюдателя? = nil) throws -> КадрОчисткиЦели {
        guard bytes.count == 37, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        let тип: UInt8 = прерывание == nil ? 0x44 : 0x49
        guard bytes[0..<4].elementsEqual([0x46, 0x55, тип, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let id = Array(bytes[4..<20])
        guard id == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        func readWord(_ range: Range<Int>) -> Int32 {
            Int32(bitPattern: bytes[range].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
        }
        let исход = bytes[36]
        guard readWord(20..<24) == anchorPID, readWord(24..<28) == targetPID, readWord(32..<36) == 9,
              прерывание.map({ исход == $0.rawValue }) ?? (исход <= 1) else { throw ОшибкаПротокола.неверныйСтатус }
        return try КадрОчисткиЦели(runID: id, anchorPID: anchorPID, targetPID: targetPID,
                                      targetStatus: readWord(28..<32), timedOut: исход == 1, прерывание: прерывание)
    }
}

public struct КадрОчисткиЯкоря: Equatable, Sendable {
    public let runID: [UInt8]
    public let anchorPID: Int32

    public init(runID: [UInt8], anchorPID: Int32) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard anchorPID > 1 else { throw ОшибкаПротокола.неверныеАргументы }
        self.runID = runID
        self.anchorPID = anchorPID
    }

    // FUC1 is provisional until the same witness exits 0 and its status pipe reaches EOF.
    // It records only that witness's TERM, KILL, wait and ESRCH observations.
    public func encoded() -> [UInt8] {
        let value = UInt32(anchorPID)
        return [0x46, 0x55, 0x43, 0x31] + runID +
            [UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
             UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value), 0, 0, 0, 9]
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8], expectedPID: Int32) throws -> КадрОчисткиЯкоря {
        guard bytes.count == 28, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x43, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let id = Array(bytes[4..<20])
        guard id == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let value = bytes[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let pid = Int32(bitPattern: value)
        guard pid == expectedPID, bytes[24..<28].elementsEqual([0, 0, 0, 9]) else {
            throw ОшибкаПротокола.неверныйСтатус
        }
        return try КадрОчисткиЯкоря(runID: id, anchorPID: pid)
    }
}

public struct КадрГотовностиЯкоря: Equatable, Sendable {
    public let runID: [UInt8]
    public let pid: Int32

    public init(runID: [UInt8], pid: Int32) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard pid > 1 else { throw ОшибкаПротокола.неверныеАргументы }
        self.runID = runID
        self.pid = pid
    }

    public func кадрОтказаЗапуска(код: Int32) throws -> [UInt8] {
        guard код > 0 else { throw ОшибкаПротокола.неверныеАргументы }
        var bytes = encoded()
        bytes[2] = 0x46
        let ошибка = UInt32(код)
        bytes += (0..<4).reversed().map { UInt8(truncatingIfNeeded: ошибка >> ($0 * 8)) }
        return bytes
    }

    public func encoded() -> [UInt8] {
        let value = UInt32(pid)
        return [0x46, 0x55, 0x41, 0x31] + runID +
            [UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
             UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8]) throws -> КадрГотовностиЯкоря {
        guard bytes.count == 24, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x41, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let id = Array(bytes[4..<20])
        guard id == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let value = bytes[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        return try КадрГотовностиЯкоря(runID: id, pid: Int32(bitPattern: value))
    }
}

public struct КадрГотовности: Equatable, Sendable {
    public let runID: [UInt8]

    public init(runID: [UInt8]) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        self.runID = runID
    }

    public func encoded() -> [UInt8] {
        [0x46, 0x55, 0x52, 0x31] + runID
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8]) throws -> КадрГотовности {
        guard bytes.count == 20, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x52, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let runID = Array(bytes[4..<20])
        guard runID == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        return try КадрГотовности(runID: runID)
    }
}

public struct КадрСтатуса: Equatable, Sendable {
    public let runID: [UInt8]
    public let rawStatus: Int32

    public init(runID: [UInt8], rawStatus: Int32) throws {
        guard runID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        let exited = rawStatus >= 0 && rawStatus <= 0xffff && rawStatus & 0xff == 0
        let signal = rawStatus & 0x7f
        let signaled = rawStatus > 0 && rawStatus <= 0xff && signal > 0 && signal < 32
        guard exited || signaled else { throw ОшибкаПротокола.неверныйСтатус }
        self.runID = runID
        self.rawStatus = rawStatus
    }

    public func encoded() -> [UInt8] {
        let status = UInt32(bitPattern: rawStatus)
        return [0x46, 0x55, 0x50, 0x31] + runID + [
            UInt8(truncatingIfNeeded: status >> 24),
            UInt8(truncatingIfNeeded: status >> 16),
            UInt8(truncatingIfNeeded: status >> 8),
            UInt8(truncatingIfNeeded: status),
        ]
    }

    public static func decode(_ bytes: [UInt8], expectedRunID: [UInt8]) throws -> КадрСтатуса {
        guard bytes.count == 24, expectedRunID.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard bytes[0..<4].elementsEqual([0x46, 0x55, 0x50, 0x31]) else { throw ОшибкаПротокола.неверныйМаркер }
        let runID = Array(bytes[4..<20])
        guard runID == expectedRunID else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let status = bytes[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        return try КадрСтатуса(runID: runID, rawStatus: Int32(bitPattern: status))
    }
}

public struct КадрСтатусаБессрочнойЦели: Equatable, Sendable {
    public let идентификатор: [UInt8]
    public let статус: Int32
    public let время: Int64

    public init(идентификатор: [UInt8], статус: Int32, время: Int64) throws {
        _ = try КадрСтатуса(runID: идентификатор, rawStatus: статус)
        guard время >= 0 else { throw ОшибкаПротокола.неверныеАргументы }
        self.идентификатор = идентификатор
        self.статус = статус
        self.время = время
    }

    public func байты() -> [UInt8] {
        let код = UInt32(bitPattern: статус)
        let отметка = UInt64(время)
        let кодБайты = (0..<4).reversed().map { UInt8(truncatingIfNeeded: код >> ($0 * 8)) }
        let времяБайты = (0..<8).reversed().map { UInt8(truncatingIfNeeded: отметка >> ($0 * 8)) }
        return [0x46, 0x55, 0x50, 0x32] + идентификатор + кодБайты + времяБайты
    }

    public static func разобрать(_ байты: [UInt8], идентификатор: [UInt8]) throws -> КадрСтатусаБессрочнойЦели {
        guard байты.count == 32, идентификатор.count == 16 else { throw ОшибкаПротокола.невернаяДлина }
        guard байты[0..<4].elementsEqual([0x46, 0x55, 0x50, 0x32]) else { throw ОшибкаПротокола.неверныйМаркер }
        let полученный = Array(байты[4..<20])
        guard полученный == идентификатор else { throw ОшибкаПротокола.неожиданныйИдентификаторЗапуска }
        let код = байты[20..<24].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let отметка = байты[24..<32].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        guard let время = Int64(exactly: отметка) else { throw ОшибкаПротокола.неверныйСтатус }
        return try КадрСтатусаБессрочнойЦели(идентификатор: полученный,
                                              статус: Int32(bitPattern: код), время: время)
    }
}
