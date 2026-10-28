import Foundation
import Darwin
import FUMStructuringOperatorMemory

public struct НаблюденияStop: Codable, Sendable {
    public static let текущаяСхема = "fum.stop-наблюдения.1"

    public let схема: String
    public let задача: String
    public let узел: String
    public let следующаяРабота: String
    public let условия: УсловияСамостоятельности

    public init(задача: String, узел: String, следующаяРабота: String,
                условия: УсловияСамостоятельности) {
        схема = Self.текущаяСхема
        self.задача = задача
        self.узел = узел
        self.следующаяРабота = следующаяРабота
        self.условия = условия
    }
}

private struct СобытиеStop: Decodable {
    let sessionID: String
    let hookEventName: String
    let cwd: String
    let turnID: String
    let stopHookActive: Bool

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case hookEventName = "hook_event_name"
        case cwd
        case turnID = "turn_id"
        case stopHookActive = "stop_hook_active"
    }
}

private struct ИдентичностьСобытияStop: Decodable {
    let sessionID: String
    let hookEventName: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case hookEventName = "hook_event_name"
    }
}

public enum ОбработчикStop {
    private static let пределБайтов = 65_536

    public static func ответ(
        событие: Data,
        наблюдения: () throws -> Data,
        ожидаемаяЗадача: String,
        ожидаемыйУзел: String,
        ожидаемыйРабочийКаталог: String
    ) -> Data {
        guard событие.count <= пределБайтов,
              (try? ЗакрытыйJSON.проверить(событие)) != nil,
              let идентичность = try? JSONDecoder().decode(ИдентичностьСобытияStop.self, from: событие)
        else { return диагностика("неверный-или-неполный-вход") }

        guard идентичность.sessionID == ожидаемаяЗадача,
              идентичность.hookEventName == "Stop" else { return пустойОтвет() }

        guard let вход = try? JSONDecoder().decode(СобытиеStop.self, from: событие),
              вход.sessionID == ожидаемаяЗадача,
              вход.hookEventName == "Stop",
              вход.cwd == ожидаемыйРабочийКаталог,
              !вход.turnID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return остановить("неверный целевой вход") }
        _ = вход.stopHookActive

        let данныеНаблюдений: Data
        do {
            данныеНаблюдений = try наблюдения()
        } catch {
            return блокировать("наблюдения недоступны; восстанови проверенное состояние до завершения")
        }
        guard данныеНаблюдений.count <= пределБайтов,
              (try? ЗакрытыйJSON.проверить(данныеНаблюдений)) != nil,
              let снимок = try? JSONDecoder().decode(НаблюденияStop.self, from: данныеНаблюдений),
              снимок.схема == НаблюденияStop.текущаяСхема,
              снимок.задача == ожидаемаяЗадача,
              снимок.узел == ожидаемыйУзел
        else { return блокировать("наблюдения повреждены; восстанови проверенное состояние до завершения") }

        let решение: РешениеСамостоятельности
        do {
            решение = try СамостоятельностьУзла.решить(снимок.условия)
        } catch {
            return блокировать("политика самостоятельности недоступна; завершение не подтверждено")
        }

        switch решение.действие {
        case .остановиться:
            return остановитьПользователем()
        case .сообщитьИПродолжитьНезависимое:
            guard допустимыйТекст(снимок.следующаяРабота) else {
                return блокировать("независимая работа заявлена без допустимого следующего шага")
            }
            let основание = текст(решение.основание)
            return блокировать("\(основание); сообщи о препятствии и продолжи только независимую работу: \(снимок.следующаяРабота)")
        case .сообщитьРодителю:
            let основание = текст(решение.основание)
            return блокировать("\(основание); сообщи родителю, завершение не подтверждено")
        case .исправлятьСамостоятельно:
            guard допустимыйТекст(снимок.следующаяРабота) else {
                return блокировать("локальное исправление заявлено без допустимого следующего шага")
            }
            return блокировать("исправь локальную проблему и продолжи: \(снимок.следующаяРабота)")
        case .действоватьСамостоятельно:
            guard допустимыйТекст(снимок.следующаяРабота) else {
                return блокировать("доступная работа заявлена без допустимого следующего шага")
            }
            return блокировать("работа не завершена; следующая работа: \(снимок.следующаяРабота)")
        }
    }

    private static func допустимыйТекст(_ значение: String) -> Bool {
        !значение.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && значение.utf8.count <= 2_048
            && !значение.unicodeScalars.contains { $0.value < 0x20 && $0.value != 0x0a }
    }

    private static func текст(_ основание: ОснованиеОбращения?) -> String {
        switch основание {
        case .неизвестныйОпасныйЭффект: "неизвестный опасный эффект"
        case .чужаяОбласть: "чужая область"
        case .нужныПолномочия: "нужны полномочия"
        case .безопасноеПродолжениеНевозможно: "безопасное продолжение невозможно"
        case .нетБезопасногоСледующегоШага: "нет безопасного следующего шага"
        case nil: "основание продолжения не подтверждено"
        }
    }

    private static func пустойОтвет() -> Data { Data("{}\n".utf8) }

    static func диагностика(_ код: String) -> Data {
        jsonОтвет(["systemMessage": "FUM Stop: \(код); принадлежность события не доказана, управление не применено."])
    }

    private static func блокировать(_ причина: String) -> Data {
        jsonОтвет(["decision": "block", "reason": "FUM Stop: \(причина)."])
    }

    private static func остановить(_ код: String) -> Data {
        jsonОтвет(["continue": false,
                   "stopReason": "FUM Stop: \(код). Завершённость обязательств не подтверждена."])
    }

    private static func остановитьПользователем() -> Data {
        jsonОтвет(["continue": false, "stopReason": "FUM Stop: задача остановлена пользователем."])
    }

    private static func jsonОтвет(_ значение: [String: Any]) -> Data {
        var данные = (try? JSONSerialization.data(withJSONObject: значение,
            options: [.sortedKeys, .withoutEscapingSlashes]))
            ?? Data("{\"continue\":false,\"stopReason\":\"FUM Stop: ошибка кодирования ответа.\"}\n".utf8)
        if данные.last != 0x0a { данные.append(0x0a) }
        return данные
    }
}

public enum КомандаStop {
    private static let идентификатор = "fum.stop-handler.1"

    public static func выполнить(_ аргументы: [String]) -> Data {
        do {
            return выполнить(аргументы, ввод: try прочитатьСтандартныйВвод())
        } catch {
            return ОбработчикStop.ответ(событие: Data(),
                наблюдения: { throw ОтказКомандыStop.ввод },
                ожидаемаяЗадача: "", ожидаемыйУзел: "",
                ожидаемыйРабочийКаталог: "")
        }
    }

    public static func выполнить(_ аргументы: [String], ввод: Data) -> Data {
        guard let параметры = разобрать(аргументы) else {
            guard let задача = задачаИзАргументов(аргументы) else {
                return ОбработчикStop.диагностика("ошибка параметров")
            }
            return ОбработчикStop.ответ(событие: ввод,
                наблюдения: { throw ОтказКомандыStop.параметры },
                ожидаемаяЗадача: задача,
                ожидаемыйУзел: "",
                ожидаемыйРабочийКаталог: "")
        }
        return ОбработчикStop.ответ(событие: ввод,
            наблюдения: { try прочитатьОбычныйФайл(параметры.состояние) },
            ожидаемаяЗадача: параметры.задача,
            ожидаемыйУзел: параметры.узел,
            ожидаемыйРабочийКаталог: параметры.cwd)
    }

    private struct Параметры {
        let задача: String
        let узел: String
        let cwd: String
        let состояние: String
    }

    private static func разобрать(_ аргументы: [String]) -> Параметры? {
        guard аргументы.count == 10 else { return nil }
        var значения: [String: String] = [:]
        var индекс = 0
        while индекс < аргументы.count {
            let ключ = аргументы[индекс]
            guard ["--идентификатор-обработчика", "--codex-thread-id",
                   "--идентификатор-узла", "--ожидаемый-cwd", "--состояние"].contains(ключ),
                  значения[ключ] == nil else { return nil }
            значения[ключ] = аргументы[индекс + 1]
            индекс += 2
        }
        guard значения["--идентификатор-обработчика"] == идентификатор,
              let задача = значения["--codex-thread-id"],
              UUID(uuidString: задача)?.uuidString.lowercased() == задача,
              let узел = значения["--идентификатор-узла"], допустимыйИдентификаторУзла(узел),
              let cwd = значения["--ожидаемый-cwd"], (cwd as NSString).isAbsolutePath,
              let состояние = значения["--состояние"], (состояние as NSString).isAbsolutePath
        else { return nil }
        return Параметры(задача: задача, узел: узел, cwd: cwd, состояние: состояние)
    }

    private static func допустимыйИдентификаторУзла(_ значение: String) -> Bool {
        !значение.isEmpty && значение.utf8.count <= 512
            && !значение.unicodeScalars.contains { $0.value < 0x21 || $0.value == 0x7f }
    }

    private static func задачаИзАргументов(_ аргументы: [String]) -> String? {
        var значения: [String] = []
        for индекс in аргументы.indices where аргументы[индекс] == "--codex-thread-id" {
            guard аргументы.indices.contains(индекс + 1) else { return nil }
            значения.append(аргументы[индекс + 1])
        }
        guard значения.count == 1, let задача = значения.first,
              UUID(uuidString: задача)?.uuidString.lowercased() == задача else { return nil }
        return задача
    }

    private static func прочитатьСтандартныйВвод() throws -> Data {
        let предел = 65_536
        let конец = ProcessInfo.processInfo.systemUptime + 1.0
        var данные = Data()
        while true {
            let остаток = конец - ProcessInfo.processInfo.systemUptime
            guard остаток > 0 else { throw ОтказКомандыStop.ввод }
            var описание = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
            let миллисекунды = Int32(max(1, min(1_000, Int(остаток * 1_000))))
            guard Darwin.poll(&описание, 1, миллисекунды) > 0,
                  описание.revents & Int16(POLLERR | POLLNVAL) == 0
            else { throw ОтказКомандыStop.ввод }
            var буфер = [UInt8](repeating: 0, count: min(8_192, предел + 1 - данные.count))
            let прочитано = буфер.withUnsafeMutableBytes { память in
                Darwin.read(STDIN_FILENO, память.baseAddress, память.count)
            }
            guard прочитано >= 0 else { throw ОтказКомандыStop.ввод }
            if прочитано == 0 { return данные }
            данные.append(contentsOf: буфер.prefix(Int(прочитано)))
            guard данные.count <= предел else { throw ОтказКомандыStop.ввод }
        }
    }

    static func прочитатьОбычныйФайл(_ путь: String) throws -> Data {
        try прочитатьОбычныйФайл(путь, послеПредварительнойПроверки: { _ in })
    }

    static func прочитатьОбычныйФайл(
        _ путь: String,
        послеПредварительнойПроверки: (Int32) throws -> Void
    ) throws -> Data {
        let дескриптор = try открытьБезСсылок(путь)
        defer { _ = Darwin.close(дескриптор) }
        var до = stat()
        guard fstat(дескриптор, &до) == 0, (до.st_mode & S_IFMT) == S_IFREG,
              до.st_uid == geteuid(), до.st_nlink == 1, до.st_mode & 0o777 == 0o600,
              до.st_size >= 0, до.st_size <= 65_536 else {
            throw ОтказКомандыStop.метаданныеСостояния
        }
        try послеПредварительнойПроверки(дескриптор)
        let данные = try прочитатьНеБольше(дескриптор, предел: 65_536)
        var после = stat()
        guard fstat(дескриптор, &после) == 0,
              до.st_dev == после.st_dev, до.st_ino == после.st_ino,
              до.st_size == после.st_size,
              до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
              до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              данные.count == Int(до.st_size)
        else { throw ОтказКомандыStop.дрейфСостояния }
        return данные
    }

    private static func прочитатьНеБольше(_ дескриптор: Int32, предел: Int) throws -> Data {
        var данные = Data(count: предел + 1)
        var всегоПрочитано = 0
        while всегоПрочитано < данные.count {
            let прочитано = данные.withUnsafeMutableBytes { память -> Int in
                guard let начало = память.baseAddress else { return -1 }
                var результат: Int
                repeat {
                    результат = Darwin.read(
                        дескриптор,
                        начало.advanced(by: всегоПрочитано),
                        память.count - всегоПрочитано
                    )
                } while результат < 0 && errno == EINTR
                return результат
            }
            guard прочитано >= 0 else { throw ОтказКомандыStop.чтениеСостояния }
            if прочитано == 0 { break }
            всегоПрочитано += прочитано
        }
        guard всегоПрочитано <= предел else {
            throw ОтказКомандыStop.превышенПределСостояния
        }
        данные.removeSubrange(всегоПрочитано..<данные.count)
        return данные
    }

    private static func открытьБезСсылок(_ путь: String) throws -> Int32 {
        guard (путь as NSString).isAbsolutePath else { throw ОтказКомандыStop.неабсолютныйПуть }
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard части.first?.isEmpty == true, части.count > 1,
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ОтказКомандыStop.неканоническийПуть
        }
        var каталог = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard каталог >= 0 else { throw ОтказКомандыStop.компонентОтсутствует }
        defer { _ = Darwin.close(каталог) }
        for часть in части.dropFirst().dropLast() {
            let следующий = String(часть).withCString {
                Darwin.openat(каталог, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            guard следующий >= 0 else {
                throw errno == ELOOP ? ОтказКомандыStop.символическаяСсылка
                    : ОтказКомандыStop.компонентОтсутствует
            }
            _ = Darwin.close(каталог)
            каталог = следующий
        }
        guard let имя = части.last else { throw ОтказКомандыStop.неканоническийПуть }
        let файл = String(имя).withCString {
            Darwin.openat(каталог, $0, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        }
        guard файл >= 0 else {
            throw errno == ELOOP ? ОтказКомандыStop.символическаяСсылка
                : ОтказКомандыStop.открытиеСостояния
        }
        return файл
    }
}

enum ОтказКомандыStop: String, Error {
    case параметры, неабсолютныйПуть, неканоническийПуть, компонентОтсутствует
    case символическаяСсылка, открытиеСостояния, чтениеСостояния, метаданныеСостояния
    case превышенПределСостояния, дрейфСостояния, ввод
}
