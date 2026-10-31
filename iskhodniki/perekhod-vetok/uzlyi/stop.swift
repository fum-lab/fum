import УстановкаStop
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
/// Только наблюдение: оба current и их ancestry подтверждаются прежним nofollow IO.
struct СнимокРазделенияСостоянийStop {
    fileprivate let прежнее: ФайлФайловойСсылки
    fileprivate let новое: НаблюдениеФайловойСсылки
    func подтвердить() throws {
        try ЧитательФайловойСсылки.подтвердить(прежнее)
        switch новое {
        case .файл(let файл): try ЧитательФайловойСсылки.подтвердить(файл)
        case .отсутствие(let отсутствие): try ЧитательФайловойСсылки.подтвердить(отсутствие)
        }
    }
}
enum ЧитательФайловойСсылки {
    static let пределУпакованных = 1_048_576

    static func проверитьРазделениеСостояний(состояниеV2: String, состояниеV3: String,
        допускаетсяОтсутствиеV3: Bool = false) throws -> СнимокРазделенияСостоянийStop {
        guard состояниеV2 != состояниеV3,
              case .файл(let прежнее) = try наблюдать(состояниеV2, предел: 32_768),
              прежнее.сведения.st_mode & 0o7777 == 0o600,
              прежнее.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true
        else { throw ОтказФайловойСсылки.метаданные }
        let новое = try наблюдать(состояниеV3, предел: 32_768)
        switch новое {
        case .файл(let файл):
            guard файл.сведения.st_mode & 0o7777 == 0o600,
                  файл.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true,
                  прежнее.сведения.st_dev != файл.сведения.st_dev
                    || прежнее.сведения.st_ino != файл.сведения.st_ino
            else { throw ОтказФайловойСсылки.неоднозначность }
        case .отсутствие(let отсутствие):
            // Разрешено отсутствие только конечного V3 basename, не ancestry.
            guard допускаетсяОтсутствиеV3,
                  отсутствие.отсутствующийКомпонент.utf8.elementsEqual(состояниеV3.utf8),
                  отсутствие.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true
            else { throw ОтказФайловойСсылки.отсутствие }
        }
        // наблюдать уже требует regular/uid/nlink1 и O_NOFOLLOW по всей цепочке.
        let снимок = СнимокРазделенияСостоянийStop(прежнее: прежнее, новое: новое)
        try снимок.подтвердить()
        return снимок
    }
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

    /// Точная чистая Swift/FUMA-проекция для будущего ROOT issuer; файловых эффектов нет.
    public static func основаниеСнимкаV3(_ данные: Data) throws -> String {
        try ТекущиеОбязательстваStop.основаниеСнимкаV3(данные)
    }

    public static func выполнить(_ аргументы: [String]) -> Data {
        if выбранЧетвёртыйПрофиль(аргументы) {
            return выполнитьЧетвёртыйПрофиль(аргументы,
                прочитать: { try прочитатьСтандартныйВвод() }, диагностика: .унаследованныйСтандартныйПотокОшибок)
        }
        let третийПрофиль = выбранТретийПрофиль(аргументы)
        do {
            return выполнить(аргументы, ввод: try прочитатьСтандартныйВвод())
        } catch {
            if третийПрофиль {
                // Событие не прочитано: принадлежность неизвестна, управление не применено.
                return КонечноеПродолжениеStop.пауза("отказ-чтения-ввода-V3; управление не применено", неизвестно: true)
            }
            return ОбработчикStop.ответ(событие: Data(),
                наблюдения: { throw ОтказКомандыStop.ввод },
                ожидаемаяЗадача: "", ожидаемыйУзел: "",
                ожидаемыйРабочийКаталог: "")
        }
    }

    public static func выполнить(_ аргументы: [String], ввод: Data) -> Data {
        if выбранЧетвёртыйПрофиль(аргументы) {
            return выполнитьЧетвёртыйПрофиль(аргументы,
                прочитать: { ввод }, диагностика: .унаследованныйСтандартныйПотокОшибок)
        }
        // V3 выбирается явно; ошибка V3 не переходит в прежний C1/V2.
        if выбранТретийПрофиль(аргументы) {
            guard let параметры = ТекущиеОбязательстваStop.Параметры(аргументы) else {
                return КонечноеПродолжениеStop.пауза("неверные-параметры-V3; управление не применено", неизвестно: true)
            }
            return ТекущиеОбязательстваStop.ответ(параметры, событие: ввод)
        }
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

    private static func выбранТретийПрофиль(_ аргументы: [String]) -> Bool {
        аргументы.indices.dropLast().contains(where: {
            аргументы[$0] == "--профиль-наблюдений" && аргументы[$0 + 1] == ТекущиеОбязательстваStop.схемаV3
        })
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
    static let схемаV3 = "fum.текущие-обязательства-stop.3"

    struct Параметры {
        let задача: String
        let узел: String
        let cwd: String
        let состояние: String
        let заголовок: String
        let хэш: String
        let версия3: Bool

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
                  let профиль = пары["--профиль-наблюдений"],
                  [ТекущиеОбязательстваStop.схема, ТекущиеОбязательстваStop.схемаV3].contains(профиль),
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
            self.версия3 = профиль == ТекущиеОбязательстваStop.схемаV3
        }
    }

    private struct Заголовок: Decodable {
        let схема, задача, узел, область, поколение, cwd, дерево, ref: String
        let gitDir, commonGitDir, backend, objectFormat, исходники: String
        let состояние, каталогКвитанций: String
        let максимальныйВозрастСекунд: Int64
        let редакцияОт, редакцияДо: UInt64?
        let допускПродолжения: КонечноеПродолжениеStop.Допуск?
        let состояниеV2: String?
    }
    private struct Управление: Codable {
        let действие, основание: String
    }
    private struct Конверт: Decodable {
        let схема, заголовокSHA256, задача, узел, область, поколение: String
        let управление: Управление
        let редакция: UInt64?
        let эпохаПродолжения, операцияПродолжения: String?
    }
    private struct Ссылка: Codable {
        let путь, sha256: String
    }
    private struct Пункт: Codable {
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
    private struct ПроектноеОснование: Encodable {
        let схема = "fum.stop-проектное-основание.1"
        let cwd, дерево, ref, HEAD: String
        let пункты: [Пункт]
        let неизвестныеНамерения: [String]
        let наблюдения: НаблюденияStop
        let диспозиция: Ссылка?
    }
    static func основаниеСнимкаV3(_ данные: Data) throws -> String {
        let s = try decode(Снимок.self, данные)
        let p = ПроектноеОснование(cwd: s.cwd, дерево: s.дерево, ref: s.ref, HEAD: s.HEAD,
            пункты: s.пункты, неизвестныеНамерения: s.неизвестныеНамерения,
            наблюдения: s.наблюдения, диспозиция: s.диспозиция)
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return sha256(try e.encode(p))
        // Header SHA/time/revision/epoch/operation не входят: нет hash-цикла или progress по одному timestamp.
    }
    private struct Доказательство: Codable {
        let id, уровень: String
        let доставка, интеграция: String?
        let цепочка: [String]?
        let квитанцияNative: Ссылка?
    }
    private struct Диспозиция: Codable {
        let схема, задача, узел, область, поколение, HEAD, исход: String
        let пункты: [Доказательство]
        let основание, ответственный, условиеВозврата: String
        let блокерSHA256: String?
        let остаток: [String]?
    }
    private struct ПробаNative: Codable {
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
        var разделения: [СнимокРазделенияСостоянийStop] = []

        mutating func разделитьСостояния(_ прежнее: String, _ новое: String) throws {
            разделения.append(try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
                состояниеV2: прежнее, состояниеV3: новое))
        }

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
            for разделение in разделения { try разделение.подтвердить() }
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
        else {
            return п.версия3
                ? КонечноеПродолжениеStop.пауза("неверный целевой вход", неизвестно: true)
                : ОбработчикStop.блокировать("неверный целевой вход; проверь Native-поля и cwd")
        }
        var контекстV3: КонечноеПродолжениеStop.Контекст?
        var допускV3: КонечноеПродолжениеStop.Допуск?
        var заголовокV3: Заголовок?
        var чтение = Чтение()
        do {
            let headerData = try чтение.взять(п.заголовок, режим: 0o400, предел: 32_768)
            guard sha256(headerData) == п.хэш else { throw Отказ.заголовок }
            let h = try decode(Заголовок.self, headerData)
            try проверитьЗаголовок(h, п)
            if п.версия3 {
                guard let прежнее = h.состояниеV2 else { throw Отказ.заголовок }
                try чтение.разделитьСостояния(прежнее, h.состояние)
                заголовокV3 = h
            }
            let данные = try чтение.взять(h.состояние, режим: 0o600, предел: 32_768)
            let конверт = try decode(Конверт.self, данные)
            guard конверт.схема == (п.версия3 ? схемаV3 : схема), конверт.заголовокSHA256 == п.хэш,
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
            if п.версия3 {
                guard let допуск = h.допускПродолжения,
                      let редакция = конверт.редакция, let от = h.редакцияОт, let до = h.редакцияДо,
                      от <= редакция, редакция <= до,
                      конверт.эпохаПродолжения == допуск.эпоха,
                      конверт.операцияПродолжения == допуск.операция
                else { throw Отказ.снимок }
                допускV3 = допуск
                контекстV3 = .init(задача: h.задача, узел: h.узел, область: h.область,
                    поколение: h.поколение, исходники: h.исходники, заголовокSHA256: п.хэш,
                    наблюдениеSHA256: try основаниеСнимкаV3(данные), полныйСнимокSHA256: sha256(данные), редакция: редакция,
                    ход: вход.turnID, сейчас: Int64(Date().timeIntervalSince1970))
            }
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
            if п.версия3, let допуск = допускV3, let контекст = контекстV3 {
                let решение = try СамостоятельностьУзла.решить(условия)
                let самостоятельное = [ДействиеУзла.действоватьСамостоятельно,
                    .исправлятьСамостоятельно, .сообщитьИПродолжитьНезависимое].contains(решение.действие)
                let допустимШаг = самостоятельное && безопасныйШаг && условия.свояОбласть
                    && условия.естьПолномочия && !условия.неизвестныйОпасныйЭффект
                    && s.неизвестныеНамерения.isEmpty
                    && активные.contains { $0.id == допуск.пункт && $0.состояние == "доступен" }
                return КонечноеПродолжениеStop.ответ(допуск, контекст,
                    повод: допустимШаг ? .безопасныйШаг(s.наблюдения.следующаяРабота) : .нетШага,
                    проверитьПрогресс: { try проверитьПрогрессV3(допуск, h, &чтение) },
                    захват: { байты in
                        try КонечноеПродолжениеStop.захватить(допуск, байты,
                            подтвердить: { try чтение.подтвердить() })
                    })
            }
            if !безопасныйШаг,
               let пункт = активные.first(where: { ["ожидает-ребёнка", "доставлен"].contains($0.состояние) }) {
                return ОбработчикStop.блокировать("текущий пункт \(пункт.id): \(пункт.состояние); \(пункт.основание); дождись адресного результата или интеграции, не повторяй доставку и неизвестный эффект")
            }
            // stop_hook_active сообщает о предыдущем продолжении, но не даёт допуска.
            _ = вход.stopHookActive
            return обычныйОтвет
        } catch {
            if п.версия3 {
                // Только точный stale допускает один отдельно выданный repair token.
                if let отказ = error as? Отказ, отказ == .устаревшийСнимок,
                   let допуск = допускV3, let контекст = контекстV3, let h = заголовокV3 {
                    return КонечноеПродолжениеStop.ответ(допуск, контекст, повод: .устаревший,
                        проверитьПрогресс: { try проверитьПрогрессV3(допуск, h, &чтение) },
                        захват: { байты in try КонечноеПродолжениеStop.захватить(допуск, байты,
                            подтвердить: { try чтение.подтвердить() }) })
                }
                return КонечноеПродолжениеStop.пауза("текущий остаток не подтверждён: \(error)", неизвестно: true)
            }
            return ОбработчикStop.блокировать("текущий остаток не подтверждён (\(error)); восстанови проверенный снимок или сообщи ROOT о препятствии, неизвестный эффект не повторяй")
        }
    }

    private static func проверитьЗаголовок(_ h: Заголовок, _ п: Параметры) throws {
        guard h.схема == (п.версия3 ? "fum.stop-заголовок.3" : "fum.stop-заголовок.2"), h.задача == п.задача,
              h.узел == п.узел, h.cwd == п.cwd, h.состояние == п.состояние,
              токен(h.область), токен(h.поколение), ref(h.ref),
              [h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
               h.каталогКвитанций].allSatisfy(абсолютный),
              h.backend == "files", h.objectFormat == "sha1", hex(h.исходники, 40),
              (1...3600).contains(h.максимальныйВозрастСекунд)
        else { throw Отказ.заголовок }
        if п.версия3 {
            guard let от = h.редакцияОт, let до = h.редакцияДо, от <= до, до - от <= 128,
                  let состояниеV2 = h.состояниеV2, абсолютный(состояниеV2), состояниеV2 != h.состояние,
                  let d = h.допускПродолжения,
                  абсолютный(d.каталогЗахватов),
                  d.каталогЗахватов != h.дерево, !d.каталогЗахватов.hasPrefix(h.дерево + "/"),
                  d.каталогЗахватов != h.commonGitDir, !d.каталогЗахватов.hasPrefix(h.commonGitDir + "/")
            else { throw Отказ.заголовок }
        }
    }

    private static func проверитьПрогрессV3(_ d: КонечноеПродолжениеStop.Допуск,
        _ h: Заголовок, _ чтение: inout Чтение) throws {
        guard d.номер > 0, d.предыдущаяОперация != nil,
              let ссылка = d.прогресс, токен(ссылка.путь), !ссылка.путь.contains("/"), hex(ссылка.sha256, 64)
        else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let данные = try чтение.взять(h.каталогКвитанций + "/" + ссылка.путь, режим: 0o400, предел: 16_384)
        guard sha256(данные) == ссылка.sha256 else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let p = try decode(КонечноеПродолжениеStop.Прогресс.self, данные)
        let имя = try КонечноеПродолжениеStop.имяЗахвата(d.эпоха, номер: d.номер - 1)
        let прежний = try чтение.взять(d.каталогЗахватов + "/" + имя, режим: 0o400, предел: 16_384)
        let claim = try decode(КонечноеПродолжениеStop.Квитанция.self, прежний)
        try КонечноеПродолжениеStop.проверитьПрогресс(p, прежнийSHA256: sha256(прежний), claim, d)
        guard токен(p.результат.путь), !p.результат.путь.contains("/"), hex(p.результат.sha256, 64)
        else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let результат = try чтение.взять(h.каталогКвитанций + "/" + p.результат.путь,
            режим: 0o400, предел: 32_768)
        guard sha256(результат) == p.результат.sha256 else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        try чтение.подтвердить()
    }

    private static func проверитьСнимок(_ s: Снимок, _ h: Заголовок,
        проверятьСрок: Bool = true, допускаетсяОстановка: Bool = false) throws {
        guard s.cwd == h.cwd, s.дерево == h.дерево, s.ref == h.ref, hex(s.HEAD, 40),
              (1...128).contains(s.пункты.count), s.неизвестныеНамерения.count <= 128,
              s.неизвестныеНамерения.allSatisfy(токен),
              Set(s.неизвестныеНамерения).count == s.неизвестныеНамерения.count,
              s.наблюдения.схема == НаблюденияStop.текущаяСхема,
              s.наблюдения.задача == h.задача, s.наблюдения.узел == h.узел,
              (допускаетсяОстановка || !s.наблюдения.условия.остановкаЗадачи),
              s.наблюдения.следующаяРабота.isEmpty || текст(s.наблюдения.следующаяРабота)
        else { throw Отказ.снимок }
        if проверятьСрок {
            let сейчас = Int64(Date().timeIntervalSince1970)
            guard s.выпущен >= 0, s.выпущен <= сейчас,
                  сейчас - s.выпущен <= h.максимальныйВозрастСекунд,
                  s.действуетДо >= сейчас, s.действуетДо >= s.выпущен,
                  s.действуетДо - s.выпущен <= h.максимальныйВозрастСекунд
            else { throw Отказ.устаревшийСнимок }
        } else {
            guard s.выпущен >= 0, s.действуетДо >= s.выпущен,
                  s.действуетДо - s.выпущен <= h.максимальныйВозрастСекунд
            else { throw Отказ.снимок }
        }
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

// V3 ограничивает управляющий сигнал отдельным ROOT-issued epoch/ordinal claim.
// Header SHA приходит из принятого Native config. Структура JSON/uid не доказывают полномочий ROOT.
enum КонечноеПродолжениеStop {
    struct Ссылка: Codable, Sendable { let путь, sha256: String }
    struct Допуск: Codable, Sendable {
        let схема, задача, узел, область, поколение, исходники: String
        let эпоха, операция, вид, пункт, следующаяРабота: String
        let корневойДопускSHA256, наблюдениеSHA256: String
        let редакция, номер: UInt64
        let выдан, действуетДо: Int64
        let каталогЗахватов: String
        let устройствоКаталога, inodeКаталога: UInt64
        let предыдущаяОперация: String?
        let прогресс: Ссылка?
    }
    struct Контекст {
        let задача, узел, область, поколение, исходники: String
        let заголовокSHA256, наблюдениеSHA256, полныйСнимокSHA256: String
        let редакция: UInt64
        let ход: String
        let сейчас: Int64
    }
    struct Квитанция: Codable, Sendable {
        let схема, задача, узел, область, поколение, исходники, эпоха, операция: String
        let корневойДопускSHA256, заголовокSHA256, наблюдениеSHA256, полныйСнимокSHA256, ход: String
        let редакция, номер: UInt64
        let вид, пункт, следующаяРабота: String
    }
    struct Прогресс: Codable {
        let схема, задача, узел, область, поколение, исходники, эпоха: String
        let предыдущаяОперация, следующаяОперация, предыдущийЗахватSHA256: String
        let предыдущееНаблюдениеSHA256, новоеНаблюдениеSHA256, корневойДопускSHA256: String
        let исход: String
        let результат: Ссылка
    }
    enum Повод { case безопасныйШаг(String), устаревший, нетШага }
    enum Захват { case создан, ужеЗанят }
    enum Отказ: Error { case допуск, прогресс, каталог, запись, синхронизация, дрейф, срок }
    struct ТочкиЗахвата {
        var послеСоздания: () throws -> Void = {}
        var передСинхронизацией: () throws -> Void = {}
        var передПодтверждением: () throws -> Void = {}
    }

    static func пауза(_ причина: String, неизвестно: Bool) -> Data {
        let состояние = неизвестно ? "UNKNOWN" : "BLOCKED"
        return json([
            "continue": false,
            "stopReason": "FUM Stop V3: техническая пауза; задача не завершена; \(состояние): \(причина). Остаток и следующий допуск — у ROOT.",
            "systemMessage": "Автоматическое продолжение не выдано. Это не task-complete и не указание пользователя STOP. Не повторяй неизвестный эффект."
        ])
    }

    static func ответ(_ d: Допуск, _ c: Контекст, повод: Повод,
        проверитьПрогресс: () throws -> Void,
        захват: (Data) throws -> Захват) -> Data {
        do {
            try проверитьДопуск(d, c)
            switch повод {
            case .безопасныйШаг(let шаг):
                guard d.вид == "безопасный-шаг", шаг == d.следующаяРабота, текст(шаг)
                else { return пауза("нет точного допущенного безопасного шага", неизвестно: false) }
            case .устаревший:
                guard d.вид == "обновить-просроченный-снимок", текст(d.следующаяРабота)
                else { return пауза("stale не разрешает повтор без отдельного repair допуска", неизвестно: true) }
            case .нетШага:
                return пауза("безопасная следующая работа не доказана", неизвестно: false)
            }
            if d.номер == 0 {
                guard d.предыдущаяОперация == nil, d.прогресс == nil else { throw Отказ.прогресс }
            } else {
                guard let p = d.предыдущаяОперация, uuid(p), p != d.операция, d.прогресс != nil
                else { throw Отказ.прогресс }
                try проверитьПрогресс()
            }
            let claim = Квитанция(схема: "fum.stop-захват-продолжения.1", задача: c.задача,
                узел: c.узел, область: c.область, поколение: c.поколение, исходники: c.исходники,
                эпоха: d.эпоха, операция: d.операция, корневойДопускSHA256: d.корневойДопускSHA256,
                заголовокSHA256: c.заголовокSHA256, наблюдениеSHA256: c.наблюдениеSHA256,
                полныйСнимокSHA256: c.полныйСнимокSHA256, ход: c.ход, редакция: c.редакция, номер: d.номер,
                вид: d.вид, пункт: d.пункт, следующаяРабота: d.следующаяРабота)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            var bytes = try encoder.encode(claim); bytes.append(10)
            guard bytes.count <= 16_384 else { throw Отказ.допуск }
            switch try захват(bytes) {
            case .ужеЗанят:
                return пауза("operation token уже claimed; изменение turn/active/timestamp не перевыдаёт бюджет", неизвестно: true)
            case .создан:
                // Durable claim доказывает только резервирование, а не доставку prompt или исполнение шага.
                return json(["decision": "block", "reason":
                    "FUM Stop V3: один сигнал по операции \(d.операция). \(d.следующаяРабота). Не расширяй допуск; представь точный исход ROOT. Повтор без принятого прогресса не разрешён."])
            }
        } catch {
            // Claim может уже существовать: ничего не удалять и не переоткрывать.
            return пауза("допуск/claim не подтверждён: \(error)", неизвестно: true)
        }
    }

    private static func проверитьДопуск(_ d: Допуск, _ c: Контекст) throws {
        guard d.схема == "fum.stop-допуск-продолжения.1", d.задача == c.задача,
              d.узел == c.узел, d.область == c.область, d.поколение == c.поколение,
              d.исходники == c.исходники, hex(d.исходники, 40),
              uuid(d.эпоха), uuid(d.операция), d.номер <= 128,
              hex(d.корневойДопускSHA256, 64), hex(c.заголовокSHA256, 64),
              hex(d.наблюдениеSHA256, 64), d.наблюдениеSHA256 == c.наблюдениеSHA256,
              hex(c.полныйСнимокSHA256, 64),
              d.редакция == c.редакция,
              d.выдан >= 0, d.выдан <= c.сейчас, c.сейчас <= d.действуетДо,
              d.действуетДо >= d.выдан, d.действуетДо - d.выдан <= 3600,
              текст(d.пункт), текст(c.ход), d.устройствоКаталога > 0, d.inodeКаталога > 0
        else { throw Отказ.допуск }
    }

    static func проверитьПрогресс(_ p: Прогресс, прежнийSHA256: String,
        _ claim: Квитанция, _ d: Допуск) throws {
        guard p.схема == "fum.stop-принятый-прогресс.1", p.исход == "шаг-выполнен-и-принят",
              p.задача == d.задача, p.узел == d.узел, p.область == d.область,
              p.поколение == d.поколение, p.исходники == d.исходники, p.эпоха == d.эпоха,
              p.предыдущаяОперация == d.предыдущаяОперация, p.следующаяОперация == d.операция,
              p.предыдущийЗахватSHA256 == прежнийSHA256, hex(прежнийSHA256, 64),
              p.корневойДопускSHA256 == d.корневойДопускSHA256,
              d.корневойДопускSHA256 != claim.корневойДопускSHA256,
              p.предыдущееНаблюдениеSHA256 == claim.наблюдениеSHA256,
              p.новоеНаблюдениеSHA256 == d.наблюдениеSHA256,
              p.предыдущееНаблюдениеSHA256 != p.новоеНаблюдениеSHA256,
              claim.схема == "fum.stop-захват-продолжения.1", claim.задача == d.задача,
              claim.узел == d.узел, claim.область == d.область, claim.поколение == d.поколение,
              claim.исходники == d.исходники, claim.эпоха == d.эпоха,
              claim.операция == d.предыдущаяОперация, claim.номер < 128, claim.номер + 1 == d.номер,
              hex(p.результат.sha256, 64)
        else { throw Отказ.прогресс }
        // Результат и receipt читаются/пинятся reader; правдивость progress принимает ROOT до нового header pin.
    }

    static func имяЗахвата(_ эпоха: String, номер: UInt64) throws -> String {
        guard uuid(эпоха), номер <= 128 else { throw Отказ.допуск }
        // Operation UUID/новый header SHA не переоткрывают уже занятый ordinal epoch.
        return эпоха + "." + String(номер) + ".claim"
    }

    static func захватить(_ d: Допуск, _ bytes: Data,
        точки: ТочкиЗахвата = .init(), подтвердить: () throws -> Void) throws -> Захват {
        guard !bytes.isEmpty, bytes.count <= 16_384 else { throw Отказ.запись }
        let имя = try имяЗахвата(d.эпоха, номер: d.номер)
        let parent = try КомандаStop.открытьБезСсылок(d.каталогЗахватов)
        defer { Darwin.close(parent) }
        func проверитьКаталог() throws {
            var st = stat()
            guard fstat(parent, &st) == 0, st.st_mode & S_IFMT == S_IFDIR,
                  st.st_uid == geteuid(), st.st_mode & 0o777 == 0o700,
                  UInt64(st.st_dev) == d.устройствоКаталога, UInt64(st.st_ino) == d.inodeКаталога
            else { throw Отказ.каталог }
            let named = try КомандаStop.открытьБезСсылок(d.каталогЗахватов)
            defer { Darwin.close(named) }
            var n = stat()
            guard fstat(named, &n) == 0, n.st_dev == st.st_dev, n.st_ino == st.st_ino,
                  n.st_mode == st.st_mode, n.st_uid == st.st_uid else { throw Отказ.дрейф }
        }
        try проверитьКаталог(); try подтвердить()
        let now = Int64(Date().timeIntervalSince1970)
        guard now >= d.выдан, now <= d.действуетДо else { throw Отказ.срок }
        let fd = openat(parent, имя, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        if fd < 0 {
            if errno == EEXIST { return .ужеЗанят }
            throw Отказ.запись
        }
        defer { Darwin.close(fd) }
        // После O_EXCL нет unlink/rollback: любой последующий сбой сохраняет UNKNOWN и расход token.
        try точки.послеСоздания()
        try bytes.withUnsafeBytes { (data: UnsafeRawBufferPointer) in
            guard let base = data.baseAddress else { throw Отказ.запись }
            var offset = 0
            while offset < data.count {
                let n = Darwin.write(fd, base.advanced(by: offset), data.count - offset)
                if n < 0 && errno == EINTR { continue }
                guard n > 0 else { throw Отказ.запись }
                offset += n
            }
        }
        guard fchmod(fd, 0o400) == 0 else { throw Отказ.запись }
        try точки.передСинхронизацией()
        guard fsync(fd) == 0, fsync(parent) == 0 else { throw Отказ.синхронизация }
        try точки.передПодтверждением()
        try проверитьКаталог(); try подтвердить()
        let end = Int64(Date().timeIntervalSince1970)
        guard end >= d.выдан, end <= d.действуетДо else { throw Отказ.срок }
        var st = stat(), named = stat()
        guard fstat(fd, &st) == 0, fstatat(parent, имя, &named, AT_SYMLINK_NOFOLLOW) == 0,
              st.st_dev == named.st_dev, st.st_ino == named.st_ino,
              st.st_mode & S_IFMT == S_IFREG, named.st_mode == st.st_mode,
              st.st_uid == geteuid(), named.st_uid == st.st_uid,
              st.st_nlink == 1, named.st_nlink == 1, st.st_mode & 0o777 == 0o400,
              st.st_size == Int64(bytes.count), named.st_size == st.st_size
        else { throw Отказ.дрейф }
        var readback = Data(), buffer = [UInt8](repeating: 0, count: min(bytes.count + 1, 16_385))
        while readback.count <= bytes.count {
            let n = buffer.withUnsafeMutableBytes { data in
                Darwin.pread(fd, data.baseAddress, min(data.count, bytes.count + 1 - readback.count), off_t(readback.count))
            }
            if n < 0 && errno == EINTR { continue }
            guard n >= 0 else { throw Отказ.дрейф }
            if n == 0 { break }
            readback.append(contentsOf: buffer.prefix(n))
        }
        var after = stat()
        guard readback == bytes, fstat(fd, &after) == 0,
              after.st_dev == st.st_dev, after.st_ino == st.st_ino,
              after.st_size == st.st_size, after.st_mode == st.st_mode,
              after.st_mtimespec.tv_sec == st.st_mtimespec.tv_sec,
              after.st_mtimespec.tv_nsec == st.st_mtimespec.tv_nsec,
              after.st_ctimespec.tv_sec == st.st_ctimespec.tv_sec,
              after.st_ctimespec.tv_nsec == st.st_ctimespec.tv_nsec
        else { throw Отказ.дрейф }
        return .создан
    }

    private static func uuid(_ s: String) -> Bool { UUID(uuidString: s)?.uuidString.lowercased() == s }
    private static func hex(_ s: String, _ n: Int) -> Bool {
        s.utf8.count == n && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
    private static func текст(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && s.utf8.count <= 2048
            && !s.unicodeScalars.contains { $0.value < 0x20 && $0.value != 10 }
    }
    private static func json(_ value: [String: Any]) -> Data {
        var data = (try? JSONSerialization.data(withJSONObject: value,
            options: [.sortedKeys, .withoutEscapingSlashes]))
            ?? Data("{\"continue\":false,\"stopReason\":\"FUM Stop V3: UNKNOWN; задача не завершена\"}".utf8)
        data.append(10); return data
    }
}


public enum ИсходДиагностическойЗаписиStopV4: Sendable, Equatable {
    case доставлено, частично(Int), недоступно
}
public struct НаблюдениеВызоваStopV4: Encodable, Sendable {
    public enum Фаза: String, Encodable, Sendable { case вход, выход }
    public enum Исход: String, Encodable, Sendable {
        case обработчикВызван = "обработчик-вызван"
        case отказЧтенияВвода = "отказ-чтения-ввода"
        case отказСхемы = "отказ-json-схемы"
        case чужоеСобытие = "чужое-событие"
        case отказПараметров = "отказ-параметров"
        case отказЯкоря = "отказ-якоря"
        case отказДопуска = "отказ-подписанного-допуска"
        case пауза
        case захватСоздан = "захват-создан"
        case захватЗанят = "захват-занят"
        case неизвестно = "UNKNOWN"
    }
    public enum Якорь: String, Encodable, Sendable {
        case неПроверен = "не-проверен", проверен, отклонён
    }
    public enum Захват: String, Encodable, Sendable {
        case неНачат = "не-начат", созданДолговечно = "создан-долговечно", занят, неизвестно = "UNKNOWN"
    }
    public let схема = "fum.stop-наблюдение-вызова.1"
    public let вызов: String
    public let процесс: Int32
    public let профиль = 4
    public let фаза: Фаза
    public let исход: Исход
    public let якорь: Якорь
    public let захват: Захват
    public init(вызов: String, процесс: Int32, фаза: Фаза, исход: Исход, якорь: Якорь, захват: Захват) {
        self.вызов = вызов; self.процесс = процесс; self.фаза = фаза
        self.исход = исход; self.якорь = якорь; self.захват = захват
    }
}

/// Боевой приёмник использует фиксированную стратегию. Произвольной тестовой функции строгий срок не обещается.
public struct ПриёмникДиагностикиStopV4: Sendable {
    private let передача: @Sendable (Data) -> ИсходДиагностическойЗаписиStopV4
    public init(_ передача: @escaping @Sendable (Data) -> ИсходДиагностическойЗаписиStopV4) {
        self.передача = передача
    }
    public func передать(_ наблюдение: НаблюдениеВызоваStopV4) -> ИсходДиагностическойЗаписиStopV4 {
        guard UUID(uuidString: наблюдение.вызов)?.uuidString.lowercased() == наблюдение.вызов,
              наблюдение.процесс > 0 else { return .недоступно }
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard var данные = try? кодировщик.encode(наблюдение) else { return .недоступно }
        данные.append(10)
        guard данные.count <= 512 else { return .недоступно }
        return передача(данные)
    }
    public static var унаследованныйСтандартныйПотокОшибок: Self { дескриптор(STDERR_FILENO) }

    /// Заимствованное описание открытого файла остаётся у одного владельца на всём интервале проверки и записи.
    /// Управляемые флаги, обработка сигналов и исходный дескриптор не меняются.
    /// Сырые F_GETFL могут отражать историю записи ядра; приёмник не настраивает заимствованный OFD.
    public static func дескриптор(_ исходный: Int32) -> Self {
        Self { данные in
            guard !данные.isEmpty, данные.count <= 512 else { return .недоступно }
            let копия = fcntl(исходный, F_DUPFD_CLOEXEC, 3)
            guard копия >= 0 else { return .недоступно }
            defer { _ = Darwin.close(копия) }
            var сведения = stat()
            guard fstat(копия, &сведения) == 0 else { return .недоступно }
            let вид = сведения.st_mode & S_IFMT
            let результат: Int
            if вид == S_IFSOCK {
                let флаги = fcntl(копия, F_GETFL)
                guard флаги >= 0, флаги & O_NONBLOCK != 0 else { return .недоступно }
                результат = данные.withUnsafeBytes {
                    Darwin.send(копия, $0.baseAddress, $0.count, Int32(MSG_DONTWAIT | MSG_NOSIGNAL))
                }
            } else if вид == S_IFIFO {
                let флаги = fcntl(копия, F_GETFL)
                guard флаги >= 0, флаги & O_NONBLOCK != 0, fcntl(копия, F_GETNOSIGPIPE) == 1
                else { return .недоступно }
                результат = данные.withUnsafeBytes { Darwin.write(копия, $0.baseAddress, $0.count) }
            } else {
                return .недоступно
            }
            if результат == данные.count { return .доставлено }
            if результат > 0 { return .частично(результат) }
            // EINTR/EAGAIN/EPIPE/unsupported — один исход, без fallback/write/retry.
            return .недоступно
        }
    }
}

extension КомандаStop {
    private static func выбранЧетвёртыйПрофиль(_ аргументы: [String]) -> Bool {
        аргументы.indices.dropLast().contains {
            аргументы[$0] == "--профиль-наблюдений"
                && аргументы[$0 + 1] == "fum.текущие-обязательства-stop.4"
        }
    }
    public static func выполнить(_ аргументы: [String], ввод: Data,
        диагностикаV4: ПриёмникДиагностикиStopV4) -> Data {
        guard выбранЧетвёртыйПрофиль(аргументы) else { return выполнить(аргументы, ввод: ввод) }
        return выполнитьЧетвёртыйПрофиль(аргументы, прочитать: { ввод }, диагностика: диагностикаV4)
    }
    static func выполнитьЧетвёртыйПрофиль(_ аргументы: [String], прочитать: () throws -> Data,
        диагностика: ПриёмникДиагностикиStopV4,
        передЧтениемЯкоря: () throws -> Void = {},
        точкиСинхронизации: КорневойДопускStopV4.ТочкиСинхронизации = .init(),
        точкиЗахвата: КонечноеПродолжениеStop.ТочкиЗахвата = .init()) -> Data {
        let вызов = UUID().uuidString.lowercased()
        let процесс = getpid()
        var исход = НаблюдениеВызоваStopV4.Исход.неизвестно
        var якорь = НаблюдениеВызоваStopV4.Якорь.неПроверен
        var захват = НаблюдениеВызоваStopV4.Захват.неНачат
        _ = диагностика.передать(.init(вызов: вызов, процесс: процесс, фаза: .вход,
            исход: .обработчикВызван, якорь: якорь, захват: захват))
        defer {
            _ = диагностика.передать(.init(вызов: вызов, процесс: процесс, фаза: .выход,
                исход: исход, якорь: якорь, захват: захват))
        }
        guard let параметры = ТекущиеОбязательстваStop.ПараметрыV4(аргументы) else {
            исход = .отказПараметров
            return ТекущиеОбязательстваStop.паузаV4("неверные-параметры-V4", неизвестно: true)
        }
        let данные: Data
        do { данные = try прочитать() }
        catch {
            исход = .отказЧтенияВвода
            return ТекущиеОбязательстваStop.паузаV4("отказ-чтения-ввода-V4", неизвестно: true)
        }
        return ТекущиеОбязательстваStop.ответV4(параметры, событие: данные,
            передЧтениемЯкоря: передЧтениемЯкоря, точкиСинхронизации: точкиСинхронизации,
            точкиЗахвата: точкиЗахвата) {
            исход = $0; якорь = $1; захват = $2
        }
    }
}


extension ТекущиеОбязательстваStop {
    typealias Корневой = КорневойДопускStopV4
    struct ПараметрыV4 {
        let задача, узел, рабочийКаталог, состояние, заголовок, хэшЗаголовка: String
        init?(_ аргументы: [String]) {
            guard аргументы.count == 16 else { return nil }
            let ключи: Set<String> = ["--идентификатор-обработчика", "--codex-thread-id",
                "--идентификатор-узла", "--ожидаемый-cwd", "--состояние",
                "--профиль-наблюдений", "--заголовок", "--хэш-заголовка"]
            var пары: [String: String] = [:]
            for номер in stride(from: 0, to: аргументы.count, by: 2) {
                guard ключи.contains(аргументы[номер]), пары[аргументы[номер]] == nil else { return nil }
                пары[аргументы[номер]] = аргументы[номер + 1]
            }
            guard пары["--идентификатор-обработчика"] == "fum.stop-handler.1",
                  пары["--профиль-наблюдений"] == "fum.текущие-обязательства-stop.4",
                  let задача = пары["--codex-thread-id"], Корневой.идентификатор(задача),
                  let узел = пары["--идентификатор-узла"], Корневой.токен(узел),
                  let рабочийКаталог = пары["--ожидаемый-cwd"], Корневой.абсолютныйПуть(рабочийКаталог),
                  let состояние = пары["--состояние"], Корневой.абсолютныйПуть(состояние),
                  let заголовок = пары["--заголовок"], Корневой.абсолютныйПуть(заголовок),
                  let хэш = пары["--хэш-заголовка"], Корневой.шестнадцатеричный(хэш, длина: 64)
            else { return nil }
            self.задача = задача; self.узел = узел; self.рабочийКаталог = рабочийКаталог
            self.состояние = состояние; self.заголовок = заголовок; self.хэшЗаголовка = хэш
        }
    }
    private struct СнимокV4: Codable {
        let схема, заголовокSHA256, задача, узел, область, поколение: String
        let рабочийКаталог, дерево, ссылка, голова: String
        enum CodingKeys: String, CodingKey {
            case схема, заголовокSHA256, задача, узел, область, поколение, дерево
            case рабочийКаталог = "cwd", ссылка = "ref", голова = "HEAD"
            case выпущен, действуетДо, пункты, неизвестныеНамерения, наблюдения, диспозиция
            case управление, редакция, эпохаПродолжения, операцияПродолжения
        }
        let выпущен, действуетДо: Int64
        let пункты: [Пункт]
        let неизвестныеНамерения: [String]
        let наблюдения: НаблюденияStop
        let диспозиция: Ссылка?
        let управление: Управление
        let редакция: UInt64
        let эпохаПродолжения, операцияПродолжения: String
        var прежний: Снимок {
            Снимок(cwd: рабочийКаталог, дерево: дерево, ref: ссылка, HEAD: голова, выпущен: выпущен,
                действуетДо: действуетДо, пункты: пункты, неизвестныеНамерения: неизвестныеНамерения,
                наблюдения: наблюдения, диспозиция: диспозиция)
        }
    }
    private struct КвитанцияV4: Codable {
        let схема, задача, узел, область, поколение, исходники, эпоха, операция: String
        let корневойДопускSHA256, заголовокSHA256, наблюдениеSHA256, полныйСнимокSHA256, ход: String
        let редакция, номер: UInt64
        let вид, пункт, следующаяРабота, подписанныйДопускSHA256: String
        var прежнееПредставление: КонечноеПродолжениеStop.Квитанция {
            .init(схема: "fum.stop-захват-продолжения.1", задача: задача, узел: узел, область: область,
                поколение: поколение, исходники: исходники, эпоха: эпоха, операция: операция,
                корневойДопускSHA256: корневойДопускSHA256, заголовокSHA256: заголовокSHA256,
                наблюдениеSHA256: наблюдениеSHA256, полныйСнимокSHA256: полныйСнимокSHA256,
                ход: ход, редакция: редакция, номер: номер, вид: вид, пункт: пункт, следующаяРабота: следующаяРабота)
        }
    }
    static func паузаV4(_ причина: String, неизвестно: Bool) -> Data {
        let статус = неизвестно ? "UNKNOWN" : "BLOCKED"
        var данные = (try? JSONSerialization.data(withJSONObject: [
            "continue": false,
            "stopReason": "FUM Stop V4: техническая пауза; задача не завершена; \(статус): \(причина). Остаток и следующий допуск — у ROOT.",
            "systemMessage": "Автоматическое продолжение не выдано. Это не task-complete и не указание пользователя STOP. Не повторяй неизвестный эффект."
        ], options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data(#"{"continue":false,"stopReason":"FUM Stop V4: UNKNOWN"}"#.utf8)
        данные.append(10)
        return данные
    }
    private static func прежнийЗаголовокV4(_ заголовок: Корневой.Заголовок,
        нагрузка: Корневой.Нагрузка) -> Заголовок {
        .init(схема: "fum.stop-заголовок.3", задача: заголовок.задача, узел: заголовок.узел,
            область: заголовок.область, поколение: заголовок.поколение,
            cwd: заголовок.рабочийКаталог, дерево: заголовок.дерево, ref: заголовок.ссылка,
            gitDir: заголовок.каталогХранилища, commonGitDir: заголовок.общийКаталогХранилища,
            backend: заголовок.типХранилища, objectFormat: заголовок.форматОбъектов,
            исходники: заголовок.исходники, состояние: заголовок.состояние,
            каталогКвитанций: заголовок.каталогКвитанций.путь,
            максимальныйВозрастСекунд: заголовок.максимальныйВозрастСекунд,
            редакцияОт: нагрузка.редакция, редакцияДо: нагрузка.редакция,
            допускПродолжения: nil, состояниеV2: заголовок.состояниеV2)
    }
    private static func проверитьСнимокV4(_ данные: Data, заголовок: Корневой.Заголовок,
        нагрузка: Корневой.Нагрузка, дляИстории: Bool = false) throws -> СнимокV4 {
        let снимок = try Корневой.разобрать(СнимокV4.self, из: данные, предел: 32_768)
        guard снимок.схема == "fum.текущие-обязательства-stop.4",
              снимок.заголовокSHA256 == нагрузка.хэшЗаголовка,
              снимок.задача == заголовок.задача, снимок.узел == заголовок.узел,
              снимок.область == заголовок.область, снимок.поколение == заголовок.поколение,
              снимок.редакция == нагрузка.редакция,
              снимок.эпохаПродолжения == нагрузка.эпоха,
              снимок.операцияПродолжения == нагрузка.операция,
              снимок.голова == нагрузка.голова,
              sha256(данные) == нагрузка.хэшСнимка,
              try основаниеСнимкаV3(данные) == нагрузка.хэшНаблюдения,
              ["продолжать", "стоп", "пауза"].contains(снимок.управление.действие),
              текст(снимок.управление.основание) else { throw Отказ.снимок }
        let ремонт = нагрузка.вид == "обновить-просроченный-снимок"
            && снимок.управление.действие == "продолжать"
        try проверитьСнимок(снимок.прежний, прежнийЗаголовокV4(заголовок, нагрузка: нагрузка),
            проверятьСрок: !дляИстории && !ремонт,
            допускаетсяОстановка: дляИстории || снимок.управление.действие != "продолжать")
        if !дляИстории {
            let сейчас = Int64(Date().timeIntervalSince1970)
            try Корневой.проверитьСвежесть(нагрузка, голова: снимок.голова, сейчас: сейчас)
            if ремонт {
                guard снимок.выпущен <= сейчас,
                      сейчас > снимок.действуетДо
                        || сейчас - снимок.выпущен > заголовок.максимальныйВозрастСекунд
                else { throw Отказ.снимок }
            }
        }
        return снимок
    }
    private static func допускV4(_ нагрузка: Корневой.Нагрузка, _ заголовок: Корневой.Заголовок)
        -> КонечноеПродолжениеStop.Допуск {
        .init(схема: "fum.stop-допуск-продолжения.1", задача: заголовок.задача, узел: заголовок.узел,
            область: заголовок.область, поколение: заголовок.поколение, исходники: заголовок.исходники,
            эпоха: нагрузка.эпоха, операция: нагрузка.операция, вид: нагрузка.вид,
            пункт: нагрузка.пункт, следующаяРабота: нагрузка.следующаяРабота,
            корневойДопускSHA256: нагрузка.хэшКорневогоДопуска,
            наблюдениеSHA256: нагрузка.хэшНаблюдения, редакция: нагрузка.редакция, номер: нагрузка.номер,
            выдан: нагрузка.выдан, действуетДо: нагрузка.действуетДо,
            каталогЗахватов: заголовок.каталогЗахватов.путь,
            устройствоКаталога: заголовок.каталогЗахватов.устройство,
            inodeКаталога: заголовок.каталогЗахватов.индексныйУзел,
            предыдущаяОперация: нагрузка.предыдущаяОперация,
            прогресс: нагрузка.прогресс.map { .init(путь: $0.путь, sha256: $0.хэш) })
    }
    private static func проверитьПрогрессV4(_ допуск: КонечноеПродолжениеStop.Допуск,
        _ заголовок: Корневой.Заголовок, история: [Корневой.ПодтверждённыйКонверт],
        чтение: inout Чтение) throws {
        guard допуск.номер > 0, let ссылка = допуск.прогресс,
              Корневой.имяКвитанции(ссылка.путь), Корневой.шестнадцатеричный(ссылка.sha256, длина: 64)
        else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let данные = try чтение.взять(заголовок.каталогКвитанций.путь + "/" + ссылка.путь,
            режим: 0o400, предел: 16_384)
        guard sha256(данные) == ссылка.sha256 else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let прогресс = try Корневой.разобрать(КонечноеПродолжениеStop.Прогресс.self, из: данные, предел: 16_384)
        let имя = try КонечноеПродолжениеStop.имяЗахвата(допуск.эпоха, номер: допуск.номер - 1)
        let прежниеДанные = try чтение.взять(заголовок.каталогЗахватов.путь + "/" + имя,
            режим: 0o400, предел: 16_384)
        let квитанция = try Корневой.разобрать(КвитанцияV4.self, из: прежниеДанные, предел: 16_384)
        guard квитанция.схема == "fum.stop-захват-продолжения.2",
              let запись = история.first(where: { $0.хэш == квитанция.подписанныйДопускSHA256 }),
              let последняяЗапись = история.last,
              запись.нагрузка.публикация < последняяЗапись.нагрузка.публикация,
              квитанция.задача == запись.нагрузка.задача,
              квитанция.узел == запись.нагрузка.узел,
              квитанция.область == запись.нагрузка.область,
              квитанция.поколение == запись.нагрузка.поколение,
              квитанция.исходники == запись.нагрузка.исходники,
              квитанция.эпоха == запись.нагрузка.эпоха,
              квитанция.корневойДопускSHA256 == запись.нагрузка.хэшКорневогоДопуска,
              квитанция.редакция == запись.нагрузка.редакция,
              квитанция.вид == запись.нагрузка.вид,
              квитанция.пункт.utf8.elementsEqual(запись.нагрузка.пункт.utf8),
              квитанция.следующаяРабота.utf8.elementsEqual(запись.нагрузка.следующаяРабота.utf8),
              текст(квитанция.ход),
              запись.нагрузка.номер == квитанция.номер,
              запись.нагрузка.операция == квитанция.операция,
              запись.нагрузка.хэшЗаголовка == квитанция.заголовокSHA256,
              запись.нагрузка.хэшНаблюдения == квитанция.наблюдениеSHA256,
              запись.нагрузка.хэшСнимка == квитанция.полныйСнимокSHA256
        else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        try КонечноеПродолжениеStop.проверитьПрогресс(прогресс, прежнийSHA256: sha256(прежниеДанные),
            квитанция.прежнееПредставление, допуск)
        guard Корневой.имяКвитанции(прогресс.результат.путь),
              Корневой.шестнадцатеричный(прогресс.результат.sha256, длина: 64)
        else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        let результат = try чтение.взять(заголовок.каталогКвитанций.путь + "/" + прогресс.результат.путь,
            режим: 0o400, предел: 32_768)
        guard sha256(результат) == прогресс.результат.sha256 else { throw КонечноеПродолжениеStop.Отказ.прогресс }
        try чтение.подтвердить()
    }
}


extension ТекущиеОбязательстваStop {
    static func ответV4(_ параметры: ПараметрыV4, событие: Data,
        передЧтениемЯкоря: () throws -> Void = {},
        точкиСинхронизации: Корневой.ТочкиСинхронизации = .init(),
        точкиЗахвата: КонечноеПродолжениеStop.ТочкиЗахвата = .init(),
        наблюдать: @escaping (НаблюдениеВызоваStopV4.Исход,
            НаблюдениеВызоваStopV4.Якорь, НаблюдениеВызоваStopV4.Захват) -> Void) -> Data {
        var якорь = НаблюдениеВызоваStopV4.Якорь.неПроверен
        var захват = НаблюдениеВызоваStopV4.Захват.неНачат
        var фаза = НаблюдениеВызоваStopV4.Исход.отказЯкоря
        func сообщить(_ исход: НаблюдениеВызоваStopV4.Исход) { наблюдать(исход, якорь, захват) }
        guard событие.count <= 65_536, (try? ЗакрытыйJSON.проверить(событие)) != nil,
              let идентичность = try? JSONDecoder().decode(ИдентичностьСобытияStop.self, from: событие)
        else {
            сообщить(.отказСхемы)
            return паузаV4("неверный-или-неполный-вход", неизвестно: true)
        }
        guard идентичность.sessionID == параметры.задача, идентичность.hookEventName == "Stop"
        else { сообщить(.чужоеСобытие); return Data("{}\n".utf8) }
        guard let вход = try? JSONDecoder().decode(СобытиеStop.self, from: событие),
              вход.cwd.utf8.elementsEqual(параметры.рабочийКаталог.utf8), текст(вход.turnID)
        else {
            сообщить(.отказСхемы)
            return паузаV4("неверный-целевой-вход-V4", неизвестно: true)
        }
        do {
            try передЧтениемЯкоря()
            var чтениеЯкоря = Корневой.Чтение()
            let байтыЗаголовка = try чтениеЯкоря.взять(параметры.заголовок, режим: 0o400, предел: 32_768)
            guard sha256(байтыЗаголовка) == параметры.хэшЗаголовка else { throw Отказ.заголовок }
            let заголовок = try Корневой.разобрать(Корневой.Заголовок.self,
                из: байтыЗаголовка, предел: 32_768)
            try Корневой.проверитьЗаголовок(заголовок)
            guard заголовок.задача == параметры.задача, заголовок.узел == параметры.узел,
                  заголовок.рабочийКаталог.utf8.elementsEqual(параметры.рабочийКаталог.utf8),
                  заголовок.состояние.utf8.elementsEqual(параметры.состояние.utf8)
            else { throw Отказ.заголовок }
            return try ЗамокТекущегоStop.выполнить(заголовок.замок) { проверитьЗамок in
                try проверитьЗамок()
                try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: параметры.заголовок)
                якорь = .проверен; фаза = .отказДопуска
                var чтение = чтениеЯкоря
                let состояние = try Корневой.прочитатьСостояние(заголовок,
                    хэшЗаголовка: параметры.хэшЗаголовка, путьЗаголовка: параметры.заголовок,
                    чтение: &чтение, проверитьЗамок: проверитьЗамок)
                let запись = состояние.последняя
                let нагрузка = запись.нагрузка
                let снимок = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
                let прежнийЗаголовок = прежнийЗаголовокV4(заголовок, нагрузка: нагрузка)
                var проектноеЧтение = Чтение()
                try проверитьGit(прежнийЗаголовок, HEAD: снимок.голова, чтение: &проектноеЧтение)

                if снимок.управление.действие != "продолжать" {
                    try чтение.подтвердить(); try проектноеЧтение.подтвердить(); try проверитьЗамок()
                    _ = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
                    сообщить(.пауза)
                    return паузаV4("подписанное-управление-ROOT", неизвестно: false)
                }
                let условия = снимок.наблюдения.условия
                let ремонт = нагрузка.вид == "обновить-просроченный-снимок"
                if !ремонт, try принятаТерминальнаяДиспозицияV4(снимок, заголовок: прежнийЗаголовок, чтение: &проектноеЧтение) {
                    try чтение.подтвердить(); try проектноеЧтение.подтвердить(); try проверитьЗамок()
                    _ = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
                    сообщить(.пауза)
                    return Data("{}\n".utf8)
                }
                let решение = try СамостоятельностьУзла.решить(условия)
                let самостоятельное = [ДействиеУзла.действоватьСамостоятельно,
                    .исправлятьСамостоятельно, .сообщитьИПродолжитьНезависимое].contains(решение.действие)
                let активные = снимок.пункты.filter {
                    $0.область == заголовок.область && !["закрыт", "неактивен"].contains($0.состояние)
                }
                let безопасно = условия.свояОбласть && условия.естьПолномочия
                    && !условия.неизвестныйОпасныйЭффект && !условия.остановкаЗадачи
                    && снимок.неизвестныеНамерения.isEmpty
                let обычныйШаг = самостоятельное && безопасно
                    && снимок.наблюдения.следующаяРабота.utf8.elementsEqual(нагрузка.следующаяРабота.utf8)
                    && активные.contains { $0.id == нагрузка.пункт && $0.состояние == "доступен" }
                guard безопасно && (ремонт || обычныйШаг) else {
                    try чтение.подтвердить(); try проектноеЧтение.подтвердить(); try проверитьЗамок()
                    сообщить(.пауза)
                    return паузаV4("нет-допущенного-безопасного-шага", неизвестно: false)
                }
                let допуск = допускV4(нагрузка, заголовок)
                let контекст = КонечноеПродолжениеStop.Контекст(задача: заголовок.задача,
                    узел: заголовок.узел, область: заголовок.область, поколение: заголовок.поколение,
                    исходники: заголовок.исходники, заголовокSHA256: параметры.хэшЗаголовка,
                    наблюдениеSHA256: нагрузка.хэшНаблюдения, полныйСнимокSHA256: нагрузка.хэшСнимка,
                    редакция: нагрузка.редакция, ход: вход.turnID, сейчас: Int64(Date().timeIntervalSince1970))
                try КонечноеПродолжениеStop.проверитьДопускV4(допуск, контекст)
                if допуск.номер > 0 {
                    try проверитьПрогрессV4(допуск, заголовок, история: состояние.записи, чтение: &проектноеЧтение)
                }
                func подтвердить() throws {
                    try проверитьЗамок()
                    try чтение.подтвердить(); try проектноеЧтение.подтвердить()
                    try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: параметры.заголовок)
                    _ = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
                    try проверитьЗамок()
                }
                try подтвердить()
                try состояние.согласовать(чтение: чтение, точки: точкиСинхронизации, проверить: подтвердить)
                let квитанция = КвитанцияV4(схема: "fum.stop-захват-продолжения.2",
                    задача: контекст.задача, узел: контекст.узел, область: контекст.область,
                    поколение: контекст.поколение, исходники: контекст.исходники,
                    эпоха: допуск.эпоха, операция: допуск.операция,
                    корневойДопускSHA256: допуск.корневойДопускSHA256,
                    заголовокSHA256: контекст.заголовокSHA256, наблюдениеSHA256: контекст.наблюдениеSHA256,
                    полныйСнимокSHA256: контекст.полныйСнимокSHA256, ход: контекст.ход,
                    редакция: контекст.редакция, номер: допуск.номер, вид: допуск.вид,
                    пункт: допуск.пункт, следующаяРабота: допуск.следующаяРабота,
                    подписанныйДопускSHA256: запись.хэш)
                let байты = try Корневой.кодировать(квитанция)
                var точки = точкиЗахвата
                let послеСоздания = точки.послеСоздания
                точки.послеСоздания = {
                    захват = .неизвестно
                    сообщить(.неизвестно)
                    try послеСоздания()
                }
                switch try КонечноеПродолжениеStop.захватить(допуск, байты, точки: точки, подтвердить: подтвердить) {
                case .ужеЗанят:
                    захват = .занят; сообщить(.захватЗанят)
                    return паузаV4("operation-token-уже-claimed", неизвестно: true)
                case .создан:
                    захват = .созданДолговечно; сообщить(.захватСоздан)
                    var ответ = try JSONSerialization.data(withJSONObject: ["decision": "block", "reason":
                        "FUM Stop V4: один сигнал по операции \(допуск.операция). \(допуск.следующаяРабота). Не расширяй допуск; представь точный исход ROOT. Повтор без принятого прогресса не разрешён."],
                        options: [.sortedKeys, .withoutEscapingSlashes])
                    ответ.append(10)
                    return ответ
                }
            }
        } catch {
            if якорь == .неПроверен { якорь = .отклонён }
            сообщить(захват == .неНачат ? фаза : .неизвестно)
            return паузаV4("якорь-допуск-снимок-Git-прогресс-claim-не-подтверждён", неизвестно: true)
        }
    }
}

extension КонечноеПродолжениеStop {
    static func проверитьДопускV4(_ допуск: Допуск, _ контекст: Контекст) throws {
        try проверитьДопуск(допуск, контекст)
    }
}


private extension ТекущиеОбязательстваStop {
    private static func квитанцияV4(_ ссылка: Ссылка, _ заголовок: Заголовок,
        чтение: inout Чтение) throws -> Data {
        guard Корневой.имяКвитанции(ссылка.путь), hex(ссылка.sha256, 64) else { throw Отказ.квитанция }
        let данные = try чтение.взять(заголовок.каталогКвитанций + "/" + ссылка.путь,
            режим: 0o400, предел: 32_768)
        guard sha256(данные) == ссылка.sha256 else { throw Отказ.квитанция }
        return данные
    }

    static func проверитьСтруктуруЦепочкиV4(_ цепочка: [String], голова: String) throws {
        guard (1...8).contains(цепочка.count) else { throw Отказ.доказательствоИнтеграции }
        var допустимые: Set<String> = [голова]
        for строка in цепочка {
            guard строка.utf8.count <= 10_924, let данные = Data(base64Encoded: строка),
                  !данные.isEmpty, данные.count <= 8192, данные.base64EncodedString() == строка,
                  let текстКоммита = String(data: данные, encoding: .utf8),
                  let граница = текстКоммита.range(of: "\n\n")
            else { throw Отказ.доказательствоИнтеграции }
            var объект = Data("commit \(данные.count)\0".utf8); объект.append(данные)
            let идентификатор = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
            let строки = текстКоммита[..<граница.lowerBound].split(separator: "\n", omittingEmptySubsequences: false)
            guard допустимые.contains(идентификатор), let дерево = строки.first,
                  дерево.hasPrefix("tree "), hex(String(дерево.dropFirst(5)), 40)
            else { throw Отказ.доказательствоИнтеграции }
            let родители = строки.filter { $0.hasPrefix("parent ") }.map { String($0.dropFirst(7)) }
            guard родители.allSatisfy({ hex($0, 40) }), Set(родители).count == родители.count
            else { throw Отказ.доказательствоИнтеграции }
            допустимые = Set(родители)
        }
    }

    private static func проверитьДоказательствоV4(_ доказательство: Доказательство, голова: String,
        заголовок: Заголовок, чтение: inout Чтение) throws {
        guard токен(доказательство.id), ["исходники", "native"].contains(доказательство.уровень),
              доказательство.доставка.map({ hex($0, 40) }) ?? true,
              доказательство.интеграция.map({ hex($0, 40) }) ?? true
        else { throw Отказ.квитанция }
        if let цепочка = доказательство.цепочка {
            try проверитьСтруктуруЦепочкиV4(цепочка, голова: голова)
        }
        if доказательство.уровень == "исходники" {
            guard доказательство.доставка != nil, доказательство.интеграция != nil,
                  let цепочка = доказательство.цепочка, (1...8).contains(цепочка.count)
            else { throw Отказ.квитанция }
            for строка in цепочка {
                guard let байты = Data(base64Encoded: строка), !байты.isEmpty, байты.count <= 8192,
                      байты.base64EncodedString() == строка else { throw Отказ.квитанция }
            }
            try проверитьИнтеграцию(доказательство, HEAD: голова)
        }
        if доказательство.уровень == "native" || доказательство.квитанцияNative != nil {
            guard let ссылка = доказательство.квитанцияNative else { throw Отказ.квитанция }
            let байты = try квитанцияV4(ссылка, заголовок, чтение: &чтение)
            let проба = try Корневой.разобрать(ПробаNative.self, из: байты, предел: 32_768)
            guard проба.схема == "fum.native-stop-проба.1", проба.задача == заголовок.задача,
                  проба.область == заголовок.область, проба.поколение == заголовок.поколение,
                  проба.HEAD == голова, проба.решение == "block",
                  hex(проба.бинарникSHA256, 64), hex(проба.определениеХукаSHA256, 64),
                  hex(проба.наблюдениеSHA256, 64) else { throw Отказ.квитанция }
        }
    }
    /// Принятая blocked-return не утверждает завершения проекта или Native activation.
    private static func принятаТерминальнаяДиспозицияV4(_ снимок: СнимокV4, заголовок: Заголовок,
        чтение: inout Чтение) throws -> Bool {
        let текущие = снимок.пункты.filter { $0.область == заголовок.область }
        guard !текущие.isEmpty else { throw Отказ.остаток }
        let активные = текущие.filter { !["закрыт", "неактивен"].contains($0.состояние) }
        let условия = снимок.наблюдения.условия
        let безопасныйШаг = условия.естьБезопасныйСледующийШаг || условия.доступнаНезависимаяРабота
            || условия.локальнаяИсправимаяПроблема || !снимок.наблюдения.следующаяРабота.isEmpty
        let закрыто = активные.isEmpty && снимок.неизвестныеНамерения.isEmpty && !безопасныйШаг
            && !условия.неизвестныйОпасныйЭффект && условия.свояОбласть && условия.естьПолномочия
        let возможенВозврат = !активные.isEmpty && активные.allSatisfy { $0.состояние == "блокирован" }
            && !безопасныйШаг && снимок.диспозиция != nil
        guard закрыто || возможенВозврат else { return false }
        guard let ссылка = снимок.диспозиция else { throw Отказ.квитанция }
        let данные = try квитанцияV4(ссылка, заголовок, чтение: &чтение)
        let диспозиция = try Корневой.разобрать(Диспозиция.self, из: данные, предел: 32_768)
        guard диспозиция.схема == "fum.stop-диспозиция.2",
              диспозиция.задача == заголовок.задача, диспозиция.узел == заголовок.узел,
              диспозиция.область == заголовок.область, диспозиция.поколение == заголовок.поколение,
              диспозиция.HEAD == снимок.голова, текст(диспозиция.основание),
              диспозиция.ответственный == заголовок.задача, текст(диспозиция.условиеВозврата),
              диспозиция.пункты.count == текущие.count,
              Set(диспозиция.пункты.map(\.id)) == Set(текущие.map(\.id)),
              текущие.allSatisfy({ пункт in
                  диспозиция.пункты.contains { $0.id == пункт.id && $0.уровень == пункт.уровень }
              }),
              диспозиция.блокерSHA256.map({ hex($0, 64) }) ?? true
        else { throw Отказ.квитанция }
        // Условия уровня действуют до обеих терминальных ветвей, включая все присутствующие optional proof.
        for доказательство in диспозиция.пункты {
            try проверитьДоказательствоV4(доказательство, голова: снимок.голова,
                заголовок: заголовок, чтение: &чтение)
        }
        if возможенВозврат && диспозиция.исход == "blocked-return" {
            let остаток = активные.map(\.id) + снимок.неизвестныеНамерения
            guard !остаток.isEmpty, диспозиция.остаток?.sorted() == остаток.sorted(),
                  диспозиция.блокерSHA256.map({ hex($0, 64) }) == true else { throw Отказ.квитанция }
            try чтение.подтвердить()
            return true
        }
        guard закрыто, диспозиция.исход == "bounded-complete", (диспозиция.остаток ?? []).isEmpty
        else { throw Отказ.квитанция }
        try чтение.подтвердить()
        return true
    }
}


public struct ОтказПубликацииStopV4: Error, Sendable {
    public let фаза: String
    public let возможенЭффект: Bool
    public let исходКвитанции: String
}
public extension КомандаStop {
    /// Внешний ROOT отдельно принимает exact header SHA. План сам не является разрешением.
    static func проверитьПубликациюV4(_ план: Data, ожидаемыйЗаголовокSHA256: String) throws -> Data {
        try ТекущиеОбязательстваStop.публикацияV4(план, ожидаемыйЗаголовокSHA256: ожидаемыйЗаголовокSHA256,
            применить: false, точки: .init())
    }
    static func опубликоватьДопускV4(_ план: Data, ожидаемыйЗаголовокSHA256: String,
        точки: КорневойДопускStopV4.ТочкиПубликации = .init()) throws -> Data {
        try ТекущиеОбязательстваStop.публикацияV4(план, ожидаемыйЗаголовокSHA256: ожидаемыйЗаголовокSHA256,
            применить: true, точки: точки)
    }
}
extension ТекущиеОбязательстваStop {
    private struct ПланПубликацииV4: Codable {
        let схема, заголовокПуть, заголовокSHA256: String
        let кандидатПуть, кандидатSHA256, снимокПуть, снимокSHA256: String
        let указательОтсутствует: Bool
        let ожидаемыйУказательSHA256: String?
        let намерениеПуть, исходПуть: String
        enum CodingKeys: String, CodingKey {
            case схема, заголовокПуть, заголовокSHA256
            case кандидатПуть = "candidateEnvelopeПуть", кандидатSHA256 = "candidateEnvelopeSHA256"
            case снимокПуть = "snapshotCandidateПуть", снимокSHA256 = "snapshotCandidateSHA256"
            case указательОтсутствует = "initiallyAbsent", ожидаемыйУказательSHA256 = "expectedPointerSHA256"
            case намерениеПуть = "operationIntentПуть", исходПуть = "operationOutcomeПуть"
        }
    }
    private struct КвитанцияПубликацииV4: Codable {
        let схема, исход, операция, заголовокSHA256, допускSHA256, снимокSHA256, планSHA256, фаза: String
        let публикация: UInt64
        let предыдущийДопускSHA256: String?
    }
    static func публикацияV4(_ данныеПлана: Data, ожидаемыйЗаголовокSHA256: String,
        применить: Bool, точки: Корневой.ТочкиПубликации) throws -> Data {
        let план = try Корневой.разобрать(ПланПубликацииV4.self, из: данныеПлана, предел: 16_384)
        guard план.схема == "fum.stop-план-публикации-root-допуска.1",
              hex(ожидаемыйЗаголовокSHA256, 64), план.заголовокSHA256 == ожидаемыйЗаголовокSHA256,
              [план.заголовокПуть, план.кандидатПуть, план.снимокПуть, план.намерениеПуть, план.исходПуть]
                .allSatisfy(Корневой.абсолютныйПуть),
              hex(план.кандидатSHA256, 64), hex(план.снимокSHA256, 64)
        else { throw Корневой.Отказ.формат }
        var входноеЧтение = Корневой.Чтение()
        let данныеЗаголовка = try входноеЧтение.взять(план.заголовокПуть, режим: 0o400, предел: 32_768)
        guard sha256(данныеЗаголовка) == ожидаемыйЗаголовокSHA256 else { throw Отказ.заголовок }
        let заголовок = try Корневой.разобрать(Корневой.Заголовок.self, из: данныеЗаголовка, предел: 32_768)
        try Корневой.проверитьЗаголовок(заголовок)
        return try ЗамокТекущегоStop.выполнить(заголовок.замок) { проверитьЗамок in
            try проверитьЗамок()
            try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: план.заголовокПуть)
            try входноеЧтение.разделитьПрежниеСостояния(заголовок, наблюдатьУказатель: false)
            let базовыйКаталогКвитанций = заголовок.каталогКвитанций.путь + "/"
            guard план.кандидатПуть.hasPrefix(базовыйКаталогКвитанций),
                  план.кандидатПуть.hasSuffix(".candidate-grant.json") else { throw Корневой.Отказ.идентичность }
            let имяКандидата = String(план.кандидатПуть.dropFirst(базовыйКаталогКвитанций.count))
            let операцияИзИмени = String(имяКандидата.dropLast(".candidate-grant.json".count))
            guard Корневой.идентификатор(операцияИзИмени),
                  план.снимокПуть == базовыйКаталогКвитанций + операцияИзИмени + ".candidate-snapshot.json"
            else { throw Корневой.Отказ.идентичность }
            let данныеКандидата = try входноеЧтение.взять(план.кандидатПуть, режим: 0o400, предел: 65_536)
            guard sha256(данныеКандидата) == план.кандидатSHA256 else { throw Корневой.Отказ.идентичность }
            let кандидат = try Корневой.проверитьКонверт(данныеКандидата,
                заголовок: заголовок, хэшЗаголовка: ожидаемыйЗаголовокSHA256)
            let нагрузка = кандидат.нагрузка
            let данныеСнимка = try входноеЧтение.взять(план.снимокПуть, режим: 0o400, предел: 32_768)
            guard sha256(данныеСнимка) == план.снимокSHA256,
                  план.снимокSHA256 == нагрузка.хэшСнимка else { throw Корневой.Отказ.идентичность }
            let каталогКвитанций = заголовок.каталогКвитанций.путь
            // Все входы и новые audit names замкнуты на уже закреплённый каталог, без нового logdir.
            guard план.кандидатПуть == каталогКвитанций + "/\(нагрузка.операция).candidate-grant.json",
                  план.снимокПуть == каталогКвитанций + "/\(нагрузка.операция).candidate-snapshot.json",
                  план.намерениеПуть == каталогКвитанций + "/\(нагрузка.операция).\(нагрузка.публикация).intent.json",
                  план.исходПуть == каталогКвитанций + "/\(нагрузка.операция).\(нагрузка.публикация).outcome.json"
            else { throw Корневой.Отказ.идентичность }
            let снимок = try проверитьСнимокV4(данныеСнимка, заголовок: заголовок, нагрузка: нагрузка)
            let старыйЗаголовок = прежнийЗаголовокV4(заголовок, нагрузка: нагрузка)
            var проектноеЧтение = Чтение()
            try проверитьGit(старыйЗаголовок, HEAD: снимок.голова, чтение: &проектноеЧтение)
            var предыдущееЧтение = Корневой.Чтение()
            let имена = try предыдущееЧтение.перечислить(заголовок.каталогПринятыхДопусков)
            let предыдущее: Корневой.Состояние?
            if имена.isEmpty {
                guard план.указательОтсутствует, план.ожидаемыйУказательSHA256 == nil,
                      try Корневой.прочитатьНеобязательное(заголовок.состояние,
                        режим: 0o600, предел: 65_536) == nil,
                      нагрузка.публикация == 0, нагрузка.предыдущийДопуск == nil
                else { throw Корневой.Отказ.цепь }
                предыдущее = nil
            } else {
                guard !план.указательОтсутствует, let ожидаемый = план.ожидаемыйУказательSHA256,
                      hex(ожидаемый, 64) else { throw Корневой.Отказ.цепь }
                let состояние = try Корневой.прочитатьСостояние(заголовок,
                    хэшЗаголовка: ожидаемыйЗаголовокSHA256, путьЗаголовка: план.заголовокПуть,
                    чтение: &предыдущееЧтение, проверитьЗамок: проверитьЗамок)
                let прежняя = состояние.последняя
                guard прежняя.хэш == ожидаемый, прежняя.нагрузка.публикация < 128,
                      нагрузка.публикация == прежняя.нагрузка.публикация + 1,
                      нагрузка.предыдущийДопуск == прежняя.хэш else { throw Корневой.Отказ.цепь }
                _ = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок,
                    нагрузка: прежняя.нагрузка, дляИстории: true)
                предыдущее = состояние
            }
            let история = (предыдущее?.записи ?? []) + [кандидат]
            if нагрузка.номер > 0 {
                try проверитьПрогрессV4(допускV4(нагрузка, заголовок), заголовок,
                    история: история, чтение: &проектноеЧтение)
            }
            let путьСнимка = заголовок.каталогСнимков.путь + "/" + нагрузка.имяСнимка
            let прежнийСнимок = try Корневой.прочитатьНеобязательное(путьСнимка, режим: 0o400, предел: 32_768)
            if let прежнийСнимок {
                guard прежнийСнимок.данные == данныеСнимка else { throw Корневой.Отказ.файл }
                _ = try входноеЧтение.взять(путьСнимка, режим: 0o400, предел: 32_768)
            }
            guard try Корневой.прочитатьНеобязательное(план.намерениеПуть, режим: 0o600, предел: 65_536) == nil,
                  try Корневой.прочитатьНеобязательное(план.исходПуть, режим: 0o600, предел: 65_536) == nil
            else { throw Корневой.Отказ.публикация }
            func проверитьВходы() throws {
                try проверитьЗамок()
                try входноеЧтение.подтвердить(); try проектноеЧтение.подтвердить()
                try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: план.заголовокПуть)
                _ = try проверитьСнимокV4(данныеСнимка, заголовок: заголовок, нагрузка: нагрузка)
                try проверитьЗамок()
            }
            try проверитьВходы()
            let хэшПлана = sha256(данныеПлана)
            func квитанция(_ схема: String, _ исход: String, _ фаза: String) throws -> Data {
                try Корневой.кодировать(КвитанцияПубликацииV4(схема: схема, исход: исход,
                    операция: нагрузка.операция, заголовокSHA256: ожидаемыйЗаголовокSHA256,
                    допускSHA256: кандидат.хэш, снимокSHA256: нагрузка.хэшСнимка,
                    планSHA256: хэшПлана, фаза: фаза, публикация: нагрузка.публикация,
                    предыдущийДопускSHA256: нагрузка.предыдущийДопуск))
            }
            if !применить {
                return try квитанция("fum.stop-проверка-публикации.4", "ПРОВЕРЕНО_БЕЗ_ЗАПИСИ", "до-эффекта")
            }
            var фаза = "намерение", возможенЭффект = false, намерениеПодтверждено = false
            var исходПопытался = false
            func отметить(_ событие: String) throws {
                фаза = событие
                try точки.событие(событие)
            }
            func проверитьАудит() throws {
                try проверитьЗамок()
                try Корневой.проверитьКаталог(заголовок.каталогКвитанций)
            }
            do {
                возможенЭффект = true
                _ = try АтомарныеБайтыStop.создатьЗаписьV4(план.намерениеПуть,
                    данные: квитанция("fum.stop-намерение-публикации.4", "НАМЕРЕНИЕ", фаза),
                    режим: 0o600, вид: "намерение", проверить: проверитьВходы, отметить: отметить)
                намерениеПодтверждено = true
                if let предыдущее {
                    try предыдущее.согласовать(чтение: предыдущееЧтение,
                        точки: точки.синхронизация, проверить: {
                            try проверитьВходы(); try предыдущееЧтение.подтвердить()
                        })
                } else {
                    guard try предыдущееЧтение.перечислить(заголовок.каталогПринятыхДопусков).isEmpty,
                          try Корневой.прочитатьНеобязательное(заголовок.состояние,
                            режим: 0o600, предел: 65_536) == nil else { throw Корневой.Отказ.цепь }
                }
                try проверитьВходы()
                if прежнийСнимок == nil {
                    _ = try АтомарныеБайтыStop.создатьЗаписьV4(путьСнимка, данные: данныеСнимка,
                        режим: 0o400, вид: "снимок", проверить: проверитьВходы, отметить: отметить)
                }
                let путьЗаписи = заголовок.каталогПринятыхДопусков.путь + "/\(нагрузка.публикация).допуск.json"
                _ = try АтомарныеБайтыStop.создатьЗаписьV4(путьЗаписи, данные: данныеКандидата,
                    режим: 0o400, вид: "допуск", проверить: проверитьВходы, отметить: отметить)
                _ = try АтомарныеБайтыStop.заменитьУказательV4(заголовок.состояние,
                    ожидаемыйSHA256: план.ожидаемыйУказательSHA256, новыми: данныеКандидата,
                    проверить: проверитьВходы, отметить: отметить)
                let путьЗавершения = заголовок.каталогПринятыхДопусков.путь + "/\(нагрузка.публикация).завершение.json"
                let маркер = try Корневой.кодироватьЗавершение(кандидат, хэшЗаголовка: ожидаемыйЗаголовокSHA256)
                _ = try АтомарныеБайтыStop.создатьЗаписьV4(путьЗавершения, данные: маркер,
                    режим: 0o400, вид: "завершение", проверить: проверитьВходы, отметить: отметить)
                var итоговоеЧтение = Корневой.Чтение()
                let итог = try Корневой.прочитатьСостояние(заголовок,
                    хэшЗаголовка: ожидаемыйЗаголовокSHA256, путьЗаголовка: план.заголовокПуть,
                    чтение: &итоговоеЧтение, проверитьЗамок: проверитьЗамок)
                guard итог.последняя.хэш == кандидат.хэш, итог.снимок == данныеСнимка
                else { throw Корневой.Отказ.публикация }
                try проверитьВходы(); try итоговоеЧтение.подтвердить()
                var сохранённыйИсход: СнимокБайтовStop?
                func проверитьУспех() throws {
                    try проверитьВходы(); try итоговоеЧтение.подтвердить(); try проверитьЗамок()
                    if let сохранённыйИсход {
                        let повтор = try АтомарныеБайтыStop.прочитать(план.исходПуть, ожидаемыйРежим: 0o600, предел: 65_536)
                        guard повтор.данные == сохранённыйИсход.данные, повтор.отпечаток == сохранённыйИсход.отпечаток
                        else { throw Корневой.Отказ.публикация }
                    }
                }
                let данныеИсхода = try квитанция("fum.stop-исход-публикации.4", "ПОДГОТОВЛЕННЫЙ_ИСХОД", "до-финальной-проверки")
                try проверитьУспех()
                исходПопытался = true
                сохранённыйИсход = try АтомарныеБайтыStop.создатьЗаписьV4(план.исходПуть, данные: данныеИсхода,
                    режим: 0o600, вид: "исход", проверить: проверитьУспех, отметить: отметить)
                try проверитьУспех()
                return try квитанция("fum.stop-терминал-публикации.4", "ОПУБЛИКОВАНО", "после-финальной-проверки")
            } catch {
                var квитанцияИсхода = исходПопытался ? "UNKNOWN_ПОСЛЕ_ПОПЫТКИ" : "НЕ_СОЗДАНА"
                if намерениеПодтверждено && !исходПопытался {
                    do {
                        try проверитьАудит()
                        guard try Корневой.прочитатьНеобязательное(план.исходПуть,
                            режим: 0o600, предел: 65_536) == nil else { throw Корневой.Отказ.публикация }
                        let неизвестно = try квитанция("fum.stop-исход-публикации.4", "UNKNOWN", фаза)
                        исходПопытался = true
                        _ = try АтомарныеБайтыStop.создатьЗаписьV4(план.исходПуть, данные: неизвестно,
                            режим: 0o600, вид: "исход-UNKNOWN", проверить: проверитьАудит, отметить: { _ in })
                        квитанцияИсхода = "UNKNOWN_СОХРАНЁН"
                    } catch { квитанцияИсхода = "UNKNOWN_НЕДОСТУПНА" }
                }
                throw ОтказПубликацииStopV4(фаза: фаза, возможенЭффект: возможенЭффект,
                    исходКвитанции: квитанцияИсхода)
            }
        }
    }
}
