import Foundation
import Darwin
import CryptoKit
import FUMStructuringOperatorMemory

// Ограниченный снимок файлового хранилища. Внешний формат Git сохраняется; подпроцессов нет.
enum ОтказФайловойСсылки: String, Error { case путь, метаданные, формат, отсутствие, неоднозначность, дрейф }
enum ИсточникФайловойСсылки: String { case обычныйФайл = "обычный-файл", упакованныйФайл = "упакованный-файл" }
fileprivate struct КаталогФайловойСсылки { let путь: String; let сведения: stat }
fileprivate struct ФайлФайловойСсылки {
    let путь: String; let предел: Int; let данные: Data; let сведения: stat
    let каталоги: [КаталогФайловойСсылки]
}
fileprivate struct ОтсутствиеФайловойСсылки {
    let путь: String; let отсутствующийКомпонент: String; let каталоги: [КаталогФайловойСсылки]
}
fileprivate enum НаблюдениеФайловойСсылки {
    case файл(ФайлФайловойСсылки), отсутствие(ОтсутствиеФайловойСсылки)
}
struct СнимокФайловойСсылки {
    let идентификаторОбъекта: String
    let источник: ИсточникФайловойСсылки
    fileprivate let файлы: [ФайлФайловойСсылки]
    fileprivate let отсутствия: [ОтсутствиеФайловойСсылки]
    func данные(_ путь: String) -> Data? {
        файлы.first { $0.путь.utf8.elementsEqual(путь.utf8) }?.данные
    }
    func подтвердить() throws {
        for файл in файлы { try ЧитательФайловойСсылки.подтвердить(файл) }
        // Конечная граница упакованного выбора повторно доказывает отсутствие отдельной ссылки.
        for отсутствие in отсутствия { try ЧитательФайловойСсылки.подтвердить(отсутствие) }
    }
}
enum ЧитательФайловойСсылки {
    static let пределУпакованных = 1_048_576
    private static func имя(_ строка: String) -> Bool {
        строка.hasPrefix("refs/") && строка.utf8.count <= 4_000
            && !строка.contains("..") && !строка.contains("@{")
            && !строка.unicodeScalars.contains { $0.value <= 0x20 || $0.value == 0x7f }
            && !строка.contains { "~^:?*[\\".contains($0) }
            && строка.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
                !$0.isEmpty && !$0.hasPrefix(".") && !$0.hasSuffix(".") && !$0.hasSuffix(".lock")
            }
    }
    private static func объект(_ байты: Data) -> String? {
        guard байты.count == 40, байты.contains(where: { $0 != 48 }),
              байты.allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) })
        else { return nil }
        return String(decoding: байты, as: UTF8.self).lowercased()
    }
    static func разобратьУпакованные(_ данные: Data, ссылка: String) throws -> String {
        guard данные.count <= пределУпакованных, данные.last == 10, !данные.contains(0), имя(ссылка)
        else { throw ОтказФайловойСсылки.формат }
        var упорядочены = false, можноСнятие = false
        var имена = Set<Data>(), прежнееИмя: Data?, выбранный: String?
        var позиция = 0, физическихСтрок = 0, записей = 0
        while позиция < данные.count {
            физическихСтрок += 1
            guard физическихСтрок <= 32_769 else { throw ОтказФайловойСсылки.формат }
            let начало = позиция
            while позиция < данные.count, данные[позиция] != 10 {
                позиция += 1
                guard позиция - начало <= 4_096 else { throw ОтказФайловойСсылки.формат }
            }
            guard позиция < данные.count, позиция > начало else { throw ОтказФайловойСсылки.формат }
            let конец = позиция
            позиция += 1
            let первыйБайт = данные[начало]
            if физическихСтрок == 1, первыйБайт == 35 {
                let префикс = "# pack-refs with: "
                guard let текст = String(data: данные.subdata(in: начало..<конец), encoding: .utf8),
                      текст.hasPrefix(префикс) else { throw ОтказФайловойСсылки.формат }
                упорядочены = текст.dropFirst(префикс.count).split(separator: " ").contains("sorted")
                continue
            }
            // Лимиты проверены до создания очередных Data; весь файл не разбивается на массив строк.
            if первыйБайт != 94 {
                записей += 1
                guard записей <= 16_384 else { throw ОтказФайловойСсылки.формат }
            }
            let строка = данные.subdata(in: начало..<конец)
            if первыйБайт == 94 {
                guard можноСнятие, объект(Data(строка.dropFirst())) != nil else { throw ОтказФайловойСсылки.формат }
                можноСнятие = false
                continue
            }
            guard строка.count >= 43, let идентификатор = объект(Data(строка.prefix(40))),
                  [UInt8(9), 11, 12, 13, 32].contains(строка[40])
            else { throw ОтказФайловойСсылки.формат }
            let имяБайтами = Data(строка.dropFirst(41))
            guard let имяСтрокой = String(data: имяБайтами, encoding: .utf8), имя(имяСтрокой)
            else { throw ОтказФайловойСсылки.формат }
            guard имена.insert(имяБайтами).inserted else { throw ОтказФайловойСсылки.неоднозначность }
            if упорядочены, let прежнееИмя {
                guard прежнееИмя.lexicographicallyPrecedes(имяБайтами) else { throw ОтказФайловойСсылки.формат }
            }
            прежнееИмя = имяБайтами; можноСнятие = true
            if имяБайтами.elementsEqual(ссылка.utf8) { выбранный = идентификатор }
        }
        guard let выбранный else { throw ОтказФайловойСсылки.отсутствие }
        return выбранный
    }
    static func прочитать(общийКаталог: String, ссылка: String,
        связанныеФайлы: [String] = []) throws -> СнимокФайловойСсылки {
        guard ссылка.hasPrefix("refs/heads/"), имя(ссылка) else { throw ОтказФайловойСсылки.путь }
        var файлы: [ФайлФайловойСсылки] = [], отсутствия: [ОтсутствиеФайловойСсылки] = []
        // Маркер reftable не разрешает чтение оставшегося packed-refs.
        switch try наблюдать(общийКаталог + "/reftable", предел: 4_096) {
        case .файл: throw ОтказФайловойСсылки.формат
        case .отсутствие(let свидетельство): отсутствия.append(свидетельство)
        }
        for путь in связанныеФайлы {
            guard case .файл(let файл) = try наблюдать(путь, предел: 4_096)
            else { throw ОтказФайловойСсылки.отсутствие }
            файлы.append(файл)
        }
        let источник: ИсточникФайловойСсылки, идентификатор: String
        switch try наблюдать(общийКаталог + "/" + ссылка, предел: 4_096) {
        case .файл(let файл):
            guard файл.данные.count == 41, файл.данные.last == 10,
                  let значение = объект(Data(файл.данные.dropLast())) else { throw ОтказФайловойСсылки.формат }
            файлы.append(файл); источник = .обычныйФайл; идентификатор = значение
        case .отсутствие(let свидетельство):
            отсутствия.append(свидетельство)
            guard case .файл(let файл) = try наблюдать(общийКаталог + "/packed-refs", предел: пределУпакованных)
            else { throw ОтказФайловойСсылки.отсутствие }
            идентификатор = try разобратьУпакованные(файл.данные, ссылка: ссылка)
            файлы.append(файл); источник = .упакованныйФайл
        }
        let снимок = СнимокФайловойСсылки(идентификаторОбъекта: идентификатор,
            источник: источник, файлы: файлы, отсутствия: отсутствия)
        try снимок.подтвердить()
        return снимок
    }
    private static func время() throws -> UInt64 {
        var момент = timespec()
        guard clock_gettime(CLOCK_MONOTONIC, &момент) == 0, момент.tv_sec >= 0,
              момент.tv_nsec >= 0, момент.tv_nsec < 1_000_000_000 else { throw ОтказФайловойСсылки.метаданные }
        return UInt64(момент.tv_sec) * 1_000_000_000 + UInt64(момент.tv_nsec)
    }
    private static func равны(_ а: stat, _ б: stat) -> Bool {
        а.st_dev == б.st_dev && а.st_ino == б.st_ino && а.st_uid == б.st_uid
            && а.st_nlink == б.st_nlink && а.st_mode == б.st_mode && а.st_size == б.st_size
            && а.st_mtimespec.tv_sec == б.st_mtimespec.tv_sec && а.st_mtimespec.tv_nsec == б.st_mtimespec.tv_nsec
            && а.st_ctimespec.tv_sec == б.st_ctimespec.tv_sec && а.st_ctimespec.tv_nsec == б.st_ctimespec.tv_nsec
    }
    private static func теЖеКаталоги(_ а: [КаталогФайловойСсылки], _ б: [КаталогФайловойСсылки]) -> Bool {
        а.count == б.count && zip(а, б).allSatisfy { пара in
            пара.0.путь.utf8.elementsEqual(пара.1.путь.utf8) && пара.0.сведения.st_dev == пара.1.сведения.st_dev
                && пара.0.сведения.st_ino == пара.1.сведения.st_ino && пара.0.сведения.st_mode == пара.1.сведения.st_mode
                && пара.0.сведения.st_uid == пара.1.сведения.st_uid
        }
    }
    fileprivate static func подтвердить(_ файл: ФайлФайловойСсылки) throws {
        guard case .файл(let свежий) = try наблюдать(файл.путь, предел: файл.предел),
              файл.данные == свежий.данные, равны(файл.сведения, свежий.сведения),
              теЖеКаталоги(файл.каталоги, свежий.каталоги) else { throw ОтказФайловойСсылки.дрейф }
    }
    fileprivate static func подтвердить(_ отсутствие: ОтсутствиеФайловойСсылки) throws {
        guard case .отсутствие(let свежее) = try наблюдать(отсутствие.путь, предел: 4_096),
              отсутствие.отсутствующийКомпонент.utf8.elementsEqual(свежее.отсутствующийКомпонент.utf8),
              теЖеКаталоги(отсутствие.каталоги, свежее.каталоги) else { throw ОтказФайловойСсылки.дрейф }
    }
    private static func наблюдать(_ путь: String, предел: Int) throws -> НаблюдениеФайловойСсылки {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard путь.utf8.count <= 4_096, части.count >= 2, части.first == "",
              !путь.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7f }),
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ОтказФайловойСсылки.путь }
        var каталог = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard каталог >= 0 else { throw ОтказФайловойСсылки.метаданные }
        defer { Darwin.close(каталог) }
        var каталоги: [КаталогФайловойСсылки] = [], префикс = ""
        for номер in 1..<части.count {
            var сведения = stat()
            guard fstat(каталог, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFDIR
            else { throw ОтказФайловойСсылки.метаданные }
            каталоги.append(КаталогФайловойСсылки(путь: префикс.isEmpty ? "/" : префикс, сведения: сведения))
            префикс += "/" + части[номер]
            let последний = номер == части.count - 1
            if последний {
                guard сведения.st_uid == geteuid(), сведения.st_mode & 0o022 == 0
                else { throw ОтказФайловойСсылки.метаданные }
            }
            let флаги = последний ? O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
                : O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
            let следующий = openat(каталог, части[номер], флаги)
            if следующий < 0 {
                guard errno == ENOENT else { throw ОтказФайловойСсылки.метаданные }
                guard сведения.st_uid == geteuid(), сведения.st_mode & 0o022 == 0
                else { throw ОтказФайловойСсылки.метаданные }
                return .отсутствие(ОтсутствиеФайловойСсылки(путь: путь,
                    отсутствующийКомпонент: префикс, каталоги: каталоги))
            }
            if !последний { Darwin.close(каталог); каталог = следующий; continue }
            defer { Darwin.close(следующий) }
            var до = stat(), после = stat(), имя = stat()
            guard fstat(следующий, &до) == 0, до.st_mode & S_IFMT == S_IFREG,
                  до.st_uid == geteuid(), до.st_nlink == 1, до.st_mode & 0o7022 == 0,
                  до.st_size >= 0, до.st_size <= Int64(предел) else { throw ОтказФайловойСсылки.метаданные }
            let край = try время() + 5_000_000_000
            var данные = Data(), буфер = [UInt8](repeating: 0, count: 16_384)
            while данные.count <= предел {
                guard try время() < край else { throw ОтказФайловойСсылки.метаданные }
                let прочитано = буфер.withUnsafeMutableBytes {
                    Darwin.pread(следующий, $0.baseAddress, min($0.count, предел + 1 - данные.count), off_t(данные.count))
                }
                if прочитано < 0 && errno == EINTR { continue }
                guard прочитано >= 0 else { throw ОтказФайловойСсылки.метаданные }
                if прочитано == 0 { break }
                данные.append(contentsOf: буфер.prefix(прочитано))
            }
            guard fstat(следующий, &после) == 0, равны(до, после), данные.count == Int(до.st_size), данные.count <= предел,
                  fstatat(каталог, части[номер], &имя, AT_SYMLINK_NOFOLLOW) == 0, равны(после, имя)
            else { throw ОтказФайловойСсылки.дрейф }
            return .файл(ФайлФайловойСсылки(путь: путь, предел: предел,
                данные: данные, сведения: после, каталоги: каталоги))
        }
        throw ОтказФайловойСсылки.путь
    }
}

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
        else { return блокировать("неверный целевой вход; проверь совместимость Native-полей и привязку cwd") }
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

    fileprivate static func блокировать(_ причина: String) -> Data {
        jsonОтвет(["decision": "block", "reason": "FUM Stop: \(причина)."])
    }

    fileprivate static func остановитьПользователем() -> Data {
        jsonОтвет(["continue": false, "stopReason": "FUM Stop: задача остановлена пользователем."])
    }

    private static func jsonОтвет(_ значение: [String: Any]) -> Data {
        var данные = (try? JSONSerialization.data(withJSONObject: значение,
            options: [.sortedKeys, .withoutEscapingSlashes]))
            ?? Data("{\"decision\":\"block\",\"reason\":\"FUM Stop: ошибка кодирования ответа.\"}\n".utf8)
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
        if аргументы.contains("--профиль-наблюдений"),
           let параметры = ТекущиеОбязательстваStop.Параметры(аргументы) {
            return ТекущиеОбязательстваStop.ответ(параметры, событие: ввод)
        }
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

    fileprivate static func открытьБезСсылок(_ путь: String) throws -> Int32 {
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

// Адресный снимок публикует владелец ROOT. Этот reader ничего не записывает,
// не запускает Git и не восстанавливает всю историю задач из булевых признаков.
private enum ТекущиеОбязательстваStop {
    static let схема = "fum.текущие-обязательства-stop.2"

    struct Параметры {
        let задача: String
        let узел: String
        let cwd: String
        let состояние: String
        let заголовок: String
        let хэш: String

        init?(_ argv: [String]) {
            guard argv.count == 16 else { return nil }
            let ключи: Set<String> = ["--идентификатор-обработчика", "--codex-thread-id",
                "--идентификатор-узла", "--ожидаемый-cwd", "--состояние",
                "--профиль-наблюдений", "--заголовок", "--хэш-заголовка"]
            var пары: [String: String] = [:]
            for i in stride(from: 0, to: argv.count, by: 2) {
                guard ключи.contains(argv[i]), пары[argv[i]] == nil else { return nil }
                пары[argv[i]] = argv[i + 1]
            }
            guard пары["--идентификатор-обработчика"] == "fum.stop-handler.1",
                  пары["--профиль-наблюдений"] == ТекущиеОбязательстваStop.схема,
                  let задача = пары["--codex-thread-id"],
                  UUID(uuidString: задача)?.uuidString.lowercased() == задача,
                  let узел = пары["--идентификатор-узла"], токен(узел),
                  let cwd = пары["--ожидаемый-cwd"], абсолютный(cwd),
                  let состояние = пары["--состояние"], абсолютный(состояние),
                  let заголовок = пары["--заголовок"], абсолютный(заголовок),
                  let хэш = пары["--хэш-заголовка"], hex(хэш, 64)
            else { return nil }
            self.задача = задача; self.узел = узел; self.cwd = cwd
            self.состояние = состояние; self.заголовок = заголовок; self.хэш = хэш
        }
    }

    private struct Заголовок: Decodable {
        let схема, задача, узел, область, поколение, cwd, дерево, ref: String
        let gitDir, commonGitDir, backend, objectFormat, исходники: String
        let состояние, каталогКвитанций: String
        let максимальныйВозрастСекунд: Int64
    }
    private struct Управление: Decodable {
        let действие, основание: String
    }
    private struct Конверт: Decodable {
        let схема, заголовокSHA256, задача, узел, область, поколение: String
        let управление: Управление
    }
    private struct Ссылка: Decodable {
        let путь, sha256: String
    }
    private struct Пункт: Decodable {
        let id, область, состояние, уровень, основание: String
    }
    private struct Снимок: Decodable {
        let cwd, дерево, ref, HEAD: String
        let выпущен, действуетДо: Int64
        let пункты: [Пункт]
        let неизвестныеНамерения: [String]
        let наблюдения: НаблюденияStop
        let диспозиция: Ссылка?
    }
    private struct Доказательство: Decodable {
        let id, уровень: String
        let доставка, интеграция: String?
        let цепочка: [String]?
        let квитанцияNative: Ссылка?
    }
    private struct Диспозиция: Decodable {
        let схема, задача, узел, область, поколение, HEAD, исход: String
        let пункты: [Доказательство]
        let основание, ответственный, условиеВозврата: String
        let блокерSHA256: String?
        let остаток: [String]?
    }
    private struct ПробаNative: Decodable {
        let схема, задача, область, поколение, HEAD, решение: String
        let бинарникSHA256, определениеХукаSHA256, наблюдениеSHA256: String
    }
    private enum Отказ: String, Error {
        case заголовок, снимок, устаревшийСнимок, привязкаGit, дрейфФайла
        case файл, квитанция, остаток, доказательствоИнтеграции
    }

    private struct Файл {
        let путь: String
        let режим: mode_t?
        let предел: Int
        let данные: Data
        let метаданные: stat
    }
    private struct Чтение {
        var файлы: [Файл] = []
        var ссылки: [СнимокФайловойСсылки] = []

        mutating func взятьСсылку(общийКаталог: String, ссылка: String) throws -> String {
            let снимок = try ЧитательФайловойСсылки.прочитать(общийКаталог: общийКаталог, ссылка: ссылка)
            ссылки.append(снимок)
            return снимок.идентификаторОбъекта
        }

        mutating func взять(_ путь: String, режим: mode_t?, предел: Int) throws -> Data {
            let файл = try Self.прочитать(путь, режим: режим, предел: предел)
            файлы.append(файл)
            return файл.данные
        }

        func подтвердить() throws {
            for файл in файлы {
                let после = try Self.прочитать(файл.путь, режим: файл.режим, предел: файл.предел)
                guard файл.данные == после.данные,
                      Self.равны(файл.метаданные, после.метаданные)
                else { throw Отказ.дрейфФайла }
            }
            for ссылка in ссылки { try ссылка.подтвердить() }
        }

        private static func равны(_ a: stat, _ b: stat) -> Bool {
            a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_uid == b.st_uid
                && a.st_nlink == b.st_nlink && a.st_mode == b.st_mode
                && a.st_size == b.st_size
                && a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec
                && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec
                && a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec
                && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec
        }

        private static func прочитать(_ путь: String, режим: mode_t?, предел: Int) throws -> Файл {
            let fd = try КомандаStop.открытьБезСсылок(путь)
            defer { _ = Darwin.close(fd) }
            var до = stat()
            guard fstat(fd, &до) == 0, до.st_mode & S_IFMT == S_IFREG,
                  до.st_uid == geteuid(), до.st_nlink == 1,
                  до.st_mode & 0o022 == 0,
                  режим.map({ до.st_mode & 0o777 == $0 }) ?? true,
                  до.st_size >= 0, до.st_size <= предел
            else { throw Отказ.файл }
            var данные = Data()
            var буфер = [UInt8](repeating: 0, count: min(4096, предел + 1))
            while данные.count <= предел {
                let n = буфер.withUnsafeMutableBytes {
                    Darwin.read(fd, $0.baseAddress, min($0.count, предел + 1 - данные.count))
                }
                if n < 0 && errno == EINTR { continue }
                guard n >= 0 else { throw Отказ.файл }
                if n == 0 { break }
                данные.append(contentsOf: буфер.prefix(n))
            }
            var после = stat()
            guard fstat(fd, &после) == 0, равны(до, после),
                  данные.count <= предел, данные.count == Int(до.st_size)
            else { throw Отказ.дрейфФайла }
            // Повторное открытие проверяет, что имя по-прежнему указывает на этот inode.
            let именованный = try КомандаStop.открытьБезСсылок(путь)
            defer { _ = Darwin.close(именованный) }
            var имя = stat()
            guard fstat(именованный, &имя) == 0, равны(после, имя)
            else { throw Отказ.дрейфФайла }
            return Файл(путь: путь, режим: режим, предел: предел,
                        данные: данные, метаданные: после)
        }
    }

    static func ответ(_ п: Параметры, событие: Data) -> Data {
        guard событие.count <= 65_536, (try? ЗакрытыйJSON.проверить(событие)) != nil,
              let identity = try? JSONDecoder().decode(ИдентичностьСобытияStop.self, from: событие)
        else { return ОбработчикStop.диагностика("неверный-или-неполный-вход") }
        // Чужой Native не должен даже открывать заголовок/снимок выбранного ROOT.
        guard identity.sessionID == п.задача, identity.hookEventName == "Stop"
        else { return пусто() }
        guard let вход = try? JSONDecoder().decode(СобытиеStop.self, from: событие),
              вход.cwd == п.cwd, текст(вход.turnID)
        else { return ОбработчикStop.блокировать("неверный целевой вход; проверь Native-поля и cwd") }
        do {
            var чтение = Чтение()
            let headerData = try чтение.взять(п.заголовок, режим: 0o400, предел: 32_768)
            guard sha256(headerData) == п.хэш else { throw Отказ.заголовок }
            let h = try decode(Заголовок.self, headerData)
            try проверитьЗаголовок(h, п)
            let данные = try чтение.взять(h.состояние, режим: 0o600, предел: 32_768)
            let конверт = try decode(Конверт.self, данные)
            guard конверт.схема == схема, конверт.заголовокSHA256 == п.хэш,
                  конверт.задача == h.задача, конверт.узел == h.узел,
                  конверт.область == h.область, конверт.поколение == h.поколение,
                  текст(конверт.управление.основание)
            else { throw Отказ.снимок }
            // Явное человеческое управление не зависит от свежести рабочего остатка.
            if ["стоп", "пауза"].contains(конверт.управление.действие) {
                try чтение.подтвердить()
                return ОбработчикStop.остановитьПользователем()
            }
            guard конверт.управление.действие == "продолжать" else { throw Отказ.снимок }
            let s = try decode(Снимок.self, данные)
            try проверитьСнимок(s, h)
            try проверитьGit(h, HEAD: s.HEAD, чтение: &чтение)
            let текущие = s.пункты.filter { $0.область == h.область }
            guard !текущие.isEmpty else { throw Отказ.остаток }
            let активные = текущие.filter { !["закрыт", "неактивен"].contains($0.состояние) }
            let условия = s.наблюдения.условия
            let безопасныйШаг = условия.естьБезопасныйСледующийШаг
                || условия.доступнаНезависимаяРабота || условия.локальнаяИсправимаяПроблема
                || !s.наблюдения.следующаяРабота.isEmpty
            if активные.isEmpty && s.неизвестныеНамерения.isEmpty && !безопасныйШаг
                && !условия.неизвестныйОпасныйЭффект && условия.свояОбласть && условия.естьПолномочия {
                try проверитьДиспозицию(s, h, текущие, чтение: &чтение)
                try чтение.подтвердить()
                return пусто()
            }
            if let ссылка = s.диспозиция,
               активные.allSatisfy({ $0.состояние == "блокирован" }), !безопасныйШаг {
                let d = try диспозиция(ссылка, h, s, чтение: &чтение)
                if d.исход == "blocked-return" {
                    let остаток = активные.map(\.id) + s.неизвестныеНамерения
                    guard !остаток.isEmpty, (d.остаток ?? []).sorted() == остаток.sorted(),
                          d.пункты.count == текущие.count,
                          Set(d.пункты.map(\.id)) == Set(текущие.map(\.id)),
                          текущие.allSatisfy({ p in d.пункты.contains { $0.id == p.id && $0.уровень == p.уровень } }),
                          d.блокерSHA256.map({ hex($0, 64) }) == true
                    else { throw Отказ.квитанция }
                    try чтение.подтвердить()
                    return пусто()
                }
            }
            // Политика самостоятельности остаётся прежней. V2 добавляет границы,
            // а не альтернативную таблицу полномочий или скрытый цикл повторов.
            let наблюдения = try JSONEncoder().encode(s.наблюдения)
            let обычныйОтвет = ОбработчикStop.ответ(событие: событие,
                наблюдения: { наблюдения }, ожидаемаяЗадача: п.задача,
                ожидаемыйУзел: п.узел, ожидаемыйРабочийКаталог: п.cwd)
            try чтение.подтвердить()
            if !безопасныйШаг,
               let пункт = активные.first(where: { ["ожидает-ребёнка", "доставлен"].contains($0.состояние) }) {
                return ОбработчикStop.блокировать("текущий пункт \(пункт.id): \(пункт.состояние); \(пункт.основание); дождись адресного результата или интеграции, не повторяй доставку и неизвестный эффект")
            }
            // stop_hook_active сообщает о предыдущем продолжении, но не даёт допуска.
            _ = вход.stopHookActive
            return обычныйОтвет
        } catch {
            return ОбработчикStop.блокировать("текущий остаток не подтверждён (\(error)); восстанови проверенный снимок или сообщи ROOT о препятствии, неизвестный эффект не повторяй")
        }
    }

    private static func проверитьЗаголовок(_ h: Заголовок, _ п: Параметры) throws {
        guard h.схема == "fum.stop-заголовок.2", h.задача == п.задача,
              h.узел == п.узел, h.cwd == п.cwd, h.состояние == п.состояние,
              токен(h.область), токен(h.поколение), ref(h.ref),
              [h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
               h.каталогКвитанций].allSatisfy(абсолютный),
              h.backend == "files", h.objectFormat == "sha1", hex(h.исходники, 40),
              (1...3600).contains(h.максимальныйВозрастСекунд)
        else { throw Отказ.заголовок }
    }

    private static func проверитьСнимок(_ s: Снимок, _ h: Заголовок) throws {
        guard s.cwd == h.cwd, s.дерево == h.дерево, s.ref == h.ref, hex(s.HEAD, 40),
              (1...128).contains(s.пункты.count), s.неизвестныеНамерения.count <= 128,
              s.неизвестныеНамерения.allSatisfy(токен),
              Set(s.неизвестныеНамерения).count == s.неизвестныеНамерения.count,
              s.наблюдения.схема == НаблюденияStop.текущаяСхема,
              s.наблюдения.задача == h.задача, s.наблюдения.узел == h.узел,
              !s.наблюдения.условия.остановкаЗадачи,
              s.наблюдения.следующаяРабота.isEmpty || текст(s.наблюдения.следующаяРабота)
        else { throw Отказ.снимок }
        let сейчас = Int64(Date().timeIntervalSince1970)
        guard s.выпущен >= 0, s.выпущен <= сейчас,
              сейчас - s.выпущен <= h.максимальныйВозрастСекунд,
              s.действуетДо >= сейчас, s.действуетДо >= s.выпущен,
              s.действуетДо - s.выпущен <= h.максимальныйВозрастСекунд
        else { throw Отказ.устаревшийСнимок }
        var ids: Set<String> = []
        for p in s.пункты {
            guard токен(p.id), ids.insert(p.id).inserted, токен(p.область), текст(p.основание),
                  ["исходники", "native"].contains(p.уровень),
                  ["доступен", "ожидает-ребёнка", "доставлен", "закрыт", "блокирован", "неактивен"].contains(p.состояние),
                  p.область == h.область || ["закрыт", "неактивен"].contains(p.состояние)
            else { throw Отказ.остаток }
        }
    }

    private static func проверитьGit(_ h: Заголовок, HEAD: String, чтение: inout Чтение) throws {
        let dotGit = try чтение.взять(h.дерево + "/.git", режим: nil, предел: 4096)
        let backlink = try чтение.взять(h.gitDir + "/gitdir", режим: nil, предел: 4096)
        let common = try чтение.взять(h.gitDir + "/commondir", режим: nil, предел: 4096)
        let head = try чтение.взять(h.gitDir + "/HEAD", режим: nil, предел: 4096)
        // Упакованная ссылка выбирается только после безопасно наблюдённого ENOENT.
        // Снимок и отсутствие отдельной ссылки подтверждаются конечной границей чтения.
        let oid = try чтение.взятьСсылку(общийКаталог: h.commonGitDir, ссылка: h.ref)
        guard dotGit == Data("gitdir: \(h.gitDir)\n".utf8),
              backlink == Data("\(h.дерево)/.git\n".utf8),
              head == Data("ref: \(h.ref)\n".utf8), oid == HEAD,
              let строка = String(data: common, encoding: .utf8), строка.hasSuffix("\n"),
              !строка.dropLast().contains("\n")
        else { throw Отказ.привязкаGit }
        let raw = String(строка.dropLast())
        // Foundation может переписать физический /private/tmp в /tmp.
        // Разрешаем только точный абсолютный путь либо ведущие ../ и затем
        // обычные компоненты. Не схлопываем непроверенное symlink/.. в середине.
        let resolved: String
        if raw.hasPrefix("/") {
            guard абсолютный(raw) else { throw Отказ.привязкаGit }
            resolved = raw
        } else {
            guard raw.utf8.count <= 4096 else { throw Отказ.привязкаGit }
            var части = h.gitDir.split(separator: "/").map(String.init)
            var добавляли = false
            for часть in raw.split(separator: "/", omittingEmptySubsequences: false) {
                if часть == ".." && !добавляли {
                    guard !части.isEmpty else { throw Отказ.привязкаGit }
                    части.removeLast()
                } else {
                    guard токен(String(часть)), часть != ".", часть != ".."
                    else { throw Отказ.привязкаGit }
                    добавляли = true; части.append(String(часть))
                }
            }
            resolved = "/" + части.joined(separator: "/")
        }
        guard resolved == h.commonGitDir else { throw Отказ.привязкаGit }
    }

    private static func диспозиция(_ ссылка: Ссылка, _ h: Заголовок, _ s: Снимок,
                                   чтение: inout Чтение) throws -> Диспозиция {
        let данные = try квитанция(ссылка, h, чтение: &чтение)
        let d = try decode(Диспозиция.self, данные)
        guard d.схема == "fum.stop-диспозиция.2", d.задача == h.задача,
              d.узел == h.узел, d.область == h.область, d.поколение == h.поколение,
              d.HEAD == s.HEAD, текст(d.основание), d.ответственный == h.задача,
              текст(d.условиеВозврата), d.пункты.count <= 128
        else { throw Отказ.квитанция }
        return d
    }

    private static func проверитьДиспозицию(_ s: Снимок, _ h: Заголовок, _ текущие: [Пункт],
                                           чтение: inout Чтение) throws {
        guard let ссылка = s.диспозиция else { throw Отказ.квитанция }
        let d = try диспозиция(ссылка, h, s, чтение: &чтение)
        guard d.исход == "bounded-complete", (d.остаток ?? []).isEmpty,
              текущие.allSatisfy({ ["закрыт", "неактивен"].contains($0.состояние) }),
              d.пункты.count == текущие.count,
              Set(d.пункты.map(\.id)) == Set(текущие.map(\.id))
        else { throw Отказ.квитанция }
        for p in текущие {
            guard let proof = d.пункты.first(where: { $0.id == p.id }), proof.уровень == p.уровень
            else { throw Отказ.квитанция }
            if p.уровень == "исходники" {
                try проверитьИнтеграцию(proof, HEAD: s.HEAD)
            } else {
                guard let ссылка = proof.квитанцияNative else { throw Отказ.квитанция }
                let n = try decode(ПробаNative.self, квитанция(ссылка, h, чтение: &чтение))
                guard n.схема == "fum.native-stop-проба.1", n.задача == h.задача,
                      n.область == h.область, n.поколение == h.поколение, n.HEAD == s.HEAD,
                      n.решение == "block", hex(n.бинарникSHA256, 64),
                      hex(n.определениеХукаSHA256, 64), hex(n.наблюдениеSHA256, 64)
                else { throw Отказ.квитанция }
            }
        }
    }

    private static func проверитьИнтеграцию(_ p: Доказательство, HEAD: String) throws {
        guard let S = p.доставка, hex(S, 40), let M = p.интеграция, hex(M, 40),
              let цепочка = p.цепочка, (1...8).contains(цепочка.count)
        else { throw Отказ.доказательствоИнтеграции }
        var допустимые: Set<String> = [HEAD]
        var последний = ""
        var последниеРодители: [String] = []
        for encoded in цепочка {
            guard encoded.utf8.count <= 10_924, let raw = Data(base64Encoded: encoded),
                  !raw.isEmpty, raw.count <= 8192, let text = String(data: raw, encoding: .utf8),
                  let граница = text.range(of: "\n\n")
            else { throw Отказ.доказательствоИнтеграции }
            var object = Data("commit \(raw.count)\0".utf8); object.append(raw)
            let oid = Insecure.SHA1.hash(data: object).map { String(format: "%02x", $0) }.joined()
            let lines = text[..<граница.lowerBound].split(separator: "\n", omittingEmptySubsequences: false)
            guard допустимые.contains(oid), let tree = lines.first,
                  tree.hasPrefix("tree "), hex(String(tree.dropFirst(5)), 40)
            else { throw Отказ.доказательствоИнтеграции }
            let родители = lines.filter { $0.hasPrefix("parent ") }.map { String($0.dropFirst(7)) }
            guard родители.allSatisfy({ hex($0, 40) }), Set(родители).count == родители.count
            else { throw Отказ.доказательствоИнтеграции }
            допустимые = Set(родители); последний = oid; последниеРодители = родители
        }
        guard последний == M, последниеРодители.count == 2, допустимые.contains(S)
        else { throw Отказ.доказательствоИнтеграции }
    }

    private static func квитанция(_ ссылка: Ссылка, _ h: Заголовок,
                                 чтение: inout Чтение) throws -> Data {
        guard токен(ссылка.путь), !ссылка.путь.contains("/"),
              !ссылка.путь.contains("\\"), ссылка.путь != ".", ссылка.путь != "..",
              ссылка.путь.hasSuffix(".json"), hex(ссылка.sha256, 64)
        else { throw Отказ.квитанция }
        let data = try чтение.взять(h.каталогКвитанций + "/" + ссылка.путь,
                                  режим: 0o600, предел: 32_768)
        guard sha256(data) == ссылка.sha256 else { throw Отказ.квитанция }
        return data
    }

    private static func decode<T: Decodable>(_ тип: T.Type, _ данные: Data) throws -> T {
        try ЗакрытыйJSON.проверить(данные)
        return try JSONDecoder().decode(тип, from: данные)
    }
    private static func hex(_ s: String, _ count: Int) -> Bool {
        s.utf8.count == count && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
    private static func токен(_ s: String) -> Bool {
        !s.isEmpty && s.utf8.count <= 512 && !s.unicodeScalars.contains { $0.value < 0x21 || $0.value == 0x7f }
    }
    private static func текст(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && s.utf8.count <= 2048
            && !s.unicodeScalars.contains { $0.value < 0x20 && $0.value != 10 }
    }
    private static func абсолютный(_ s: String) -> Bool {
        s.hasPrefix("/") && s.utf8.count <= 4096 && !s.utf8.contains(0)
            && s.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
                .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
    private static func ref(_ s: String) -> Bool {
        s.hasPrefix("refs/heads/") && токен(s) && !s.contains("..") && !s.contains("@{")
            && !s.contains(where: { "~^:?*[\\".contains($0) })
            && s.split(separator: "/", omittingEmptySubsequences: false)
                .allSatisfy { !$0.isEmpty && !$0.hasPrefix(".") && !$0.hasSuffix(".") && !$0.hasSuffix(".lock") }
    }
    private static func sha256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
    private static func пусто() -> Data { Data("{}\n".utf8) }
}
