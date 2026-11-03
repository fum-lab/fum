import Foundation
import Darwin

// Синхронный системный адаптер: повтор EINTR не меняет абсолютный срок.
func дождатьсяМонотонногоСрока(_ срок: UInt64) -> Bool {
    var предыдущее = DispatchTime.now().uptimeNanoseconds
    while предыдущее < срок {
        let остаток = срок - предыдущее
        var пауза = timespec(tv_sec: Int(остаток / 1_000_000_000), tv_nsec: Int(остаток % 1_000_000_000))
        let код = nanosleep(&пауза, nil)
        let ошибка = errno
        let сейчас = DispatchTime.now().uptimeNanoseconds
        guard сейчас >= предыдущее, код == 0 || ошибка == EINTR else { return false }
        предыдущее = сейчас
    }
    return true
}

struct ОтветGit: Sendable {
    let код: Int32
    let выход: Data
    let ошибки: Data
}

/// Только локальный Git: argv и окружение не проходят через shell.
func ограниченныйПроцесс(
    _ исполняемый: String, _ аргументы: [String], среда: [String: String], вход: Data = Data(),
    предел: Int = 8_192, начало: UInt64 = DispatchTime.now().uptimeNanoseconds
) throws -> ОтветGit {
    guard предел >= 0, предел <= 4_194_304, вход.count <= 8_192,
          исполняемый.hasPrefix("/"), !([исполняемый] + аргументы).contains(where: { $0.contains("\0") }) else { throw ОтказЦелостности("предел", 2) }
    var каналы = [[Int32](repeating: -1, count: 2), [Int32](repeating: -1, count: 2), [Int32](repeating: -1, count: 2)]
    for номер in 0..<3 {
        guard pipe(&каналы[номер]) == 0 else {
            for пара in каналы { for д in пара where д >= 0 { Darwin.close(д) } }
            throw ОтказЦелостности("ввод-вывод", 2)
        }
    }
    defer { for пара in каналы { for д in пара where д >= 0 { Darwin.close(д) } } }
    for пара in каналы { for д in пара { guard fcntl(д, F_SETFD, FD_CLOEXEC) == 0 else { throw ОтказЦелостности("ввод-вывод", 2) } } }
    for д in [каналы[0][0], каналы[1][0]] {
        guard fcntl(д, F_SETFL, O_NONBLOCK) == 0 else { throw ОтказЦелостности("ввод-вывод", 2) }
    }
    // EPIPE остаётся обычной ошибкой, не сигналом всему проверяющему процессу.
    guard fcntl(каналы[2][1], F_SETNOSIGPIPE, 1) == 0 else { throw ОтказЦелостности("ввод-вывод", 2) }
    var действия: posix_spawn_file_actions_t?
    var атрибуты: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&действия) == 0 else { throw ОтказЦелостности("процесс", 2) }
    defer { posix_spawn_file_actions_destroy(&действия) }
    guard posix_spawnattr_init(&атрибуты) == 0 else { throw ОтказЦелостности("процесс", 2) }
    defer { posix_spawnattr_destroy(&атрибуты) }
    guard posix_spawn_file_actions_adddup2(&действия, каналы[2][0], STDIN_FILENO) == 0,
          posix_spawn_file_actions_adddup2(&действия, каналы[0][1], STDOUT_FILENO) == 0,
          posix_spawn_file_actions_adddup2(&действия, каналы[1][1], STDERR_FILENO) == 0,
          posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP)) == 0,
          posix_spawnattr_setpgroup(&атрибуты, 0) == 0 else { throw ОтказЦелостности("процесс", 2) }
    for пара in каналы { for д in пара where д > 2 {
        guard posix_spawn_file_actions_addclose(&действия, д) == 0 else { throw ОтказЦелостности("процесс", 2) }
    } }
    let указатели = ([исполняемый] + аргументы).map { strdup($0) }
    let окружение = среда.keys.sorted().map { strdup($0 + "=" + среда[$0]!) }
    defer { for у in указатели + окружение { free(у) } }
    guard (указатели + окружение).allSatisfy({ $0 != nil }) else { throw ОтказЦелостности("предел", 2) }
    var а = указатели + [nil], о = окружение + [nil]
    var ребёнок: pid_t = 0
    let ответ = а.withUnsafeMutableBufferPointer { аа in о.withUnsafeMutableBufferPointer { оо in
        исполняемый.withCString { posix_spawn(&ребёнок, $0, &действия, &атрибуты, аа.baseAddress, оо.baseAddress) }
    } }
    guard ответ == 0, ребёнок > 0 else { throw ОтказЦелостности("процесс", 2) }
    var якорь = true
    var собран = false
    func сигнал(_ номер: Int32) throws {
        guard якорь, !собран else { throw ОтказЦелостности("процесс", 2) }
        let код = Darwin.kill(-ребёнок, номер)
        let ошибка = errno
        guard код == 0 || ошибка == ESRCH else { throw ОтказЦелостности("процесс", 2) }
    }
    func собратьПослеОтказа() -> Bool {
        if якорь && !собран {
            try? сигнал(SIGKILL)
            let пределОжидания = DispatchTime.now().uptimeNanoseconds + 500_000_000
            while DispatchTime.now().uptimeNanoseconds < пределОжидания {
                var сведения = siginfo_t()
                let код = waitid(P_PID, id_t(ребёнок), &сведения, WEXITED | WNOHANG | WNOWAIT)
                if код == 0 && сведения.si_pid == ребёнок {
                    var статус: Int32 = 0
                    while true {
                        let итог = waitpid(ребёнок, &статус, 0)
                        if итог == ребёнок { собран = true; якорь = false; break }
                        if errno == ECHILD { якорь = false }
                        if errno != EINTR { return false }
                    }
                    break
                }
                if код != 0 && errno != EINTR { return false }
                let сейчас = DispatchTime.now().uptimeNanoseconds
                guard сейчас < пределОжидания else { break }
                guard дождатьсяМонотонногоСрока(min(пределОжидания, сейчас + 10_000_000)) else { return false }
            }
        }
        guard собран else { return false }
        let пределЗакрытияГруппы = DispatchTime.now().uptimeNanoseconds + 500_000_000
        while DispatchTime.now().uptimeNanoseconds < пределЗакрытияГруппы {
            let код = Darwin.kill(-ребёнок, 0), ошибка = errno
            if код == -1 && ошибка == ESRCH { return true }
            let сейчас = DispatchTime.now().uptimeNanoseconds
            guard сейчас < пределЗакрытияГруппы else { break }
            guard дождатьсяМонотонногоСрока(min(пределЗакрытияГруппы, сейчас + 10_000_000)) else { return false }
        }
        return false
    }
    do {
    for номер in 0..<2 { Darwin.close(каналы[номер][1]); каналы[номер][1] = -1 }
    Darwin.close(каналы[2][0]); каналы[2][0] = -1
    if !вход.isEmpty {
        let записано = вход.withUnsafeBytes { Darwin.write(каналы[2][1], $0.baseAddress, $0.count) }
        guard записано == вход.count else { throw ОтказЦелостности("ввод-вывод", 2) }
    }
    Darwin.close(каналы[2][1]); каналы[2][1] = -1
    var данные = [Data(), Data()]
    let пределы = [предел, 4_096]
    var концы = [false, false]
    var завершение: UInt64?
    var остановка: UInt64?
    var отказ = false
    var убит = false
    while true {
        let сейчас = DispatchTime.now().uptimeNanoseconds
        guard сейчас >= начало else { throw ОтказЦелостности("предел", 2) }
        if завершение == nil {
            var сведения = siginfo_t()
            let код = waitid(P_PID, id_t(ребёнок), &сведения, WEXITED | WNOHANG | WNOWAIT)
            if код != 0 {
                if errno == EINTR { continue }
                if errno == ECHILD { якорь = false }
                throw ОтказЦелостности("процесс", 2)
            }
            if сведения.si_pid == ребёнок { завершение = сейчас }
        }
        if сейчас - начало > 27_000_000_000 { отказ = true }
        if завершение != nil && концы.allSatisfy({ $0 }) { break }
        if let завершение, сейчас - завершение > 500_000_000 { отказ = true }
        if отказ && остановка == nil { try сигнал(SIGTERM); остановка = сейчас }
        if let остановка, сейчас - остановка > 200_000_000 && !убит { try сигнал(SIGKILL); убит = true }
        if let остановка, сейчас - остановка > 1_000_000_000 { throw ОтказЦелостности("предел", 2) }
        var события = (0..<2).map { pollfd(fd: концы[$0] ? -1 : каналы[$0][0], events: Int16(POLLIN | POLLHUP), revents: 0) }
        let код = события.withUnsafeMutableBufferPointer { poll($0.baseAddress, 2, 10) }
        if код < 0 { if errno == EINTR { continue }; throw ОтказЦелостности("ввод-вывод", 2) }
        for номер in 0..<2 where !концы[номер] && события[номер].revents != 0 {
            var буфер = [UInt8](repeating: 0, count: 16_384)
            let сколько = буфер.withUnsafeMutableBytes { Darwin.read(каналы[номер][0], $0.baseAddress, $0.count) }
            if сколько == 0 { концы[номер] = true }
            else if сколько > 0 {
                let остаток = max(0, пределы[номер] - данные[номер].count)
                данные[номер].append(contentsOf: буфер.prefix(min(остаток, сколько)))
                if сколько > остаток { отказ = true }
            } else if errno != EAGAIN && errno != EINTR { throw ОтказЦелостности("ввод-вывод", 2) }
        }
    }
    var статус: Int32 = 0
    while waitpid(ребёнок, &статус, 0) != ребёнок {
        if errno == ECHILD { якорь = false; throw ОтказЦелостности("неизвестное-владение", 2) }
        if errno != EINTR { throw ОтказЦелостности("процесс", 2) }
    }
    собран = true; якорь = false
    var закрыта = false
    let пределЗакрытияГруппы = DispatchTime.now().uptimeNanoseconds + 500_000_000
    while DispatchTime.now().uptimeNanoseconds < пределЗакрытияГруппы {
        let код = Darwin.kill(-ребёнок, 0), ошибка = errno
        if код == -1 && ошибка == ESRCH { закрыта = true; break }
        let сейчас = DispatchTime.now().uptimeNanoseconds
        guard сейчас < пределЗакрытияГруппы else { break }
        guard дождатьсяМонотонногоСрока(min(пределЗакрытияГруппы, сейчас + 10_000_000)) else { throw ОтказЦелостности("неизвестное-владение", 2) }
    }
    guard закрыта else { throw ОтказЦелостности("неизвестное-владение", 2) }
    guard !отказ else { throw ОтказЦелостности("предел", 2) }
    guard статус & 0x7f == 0 else { throw ОтказЦелостности("процесс", 2) }
    return .init(код: (статус >> 8) & 0xff, выход: данные[0], ошибки: данные[1])
    } catch {
        guard собратьПослеОтказа() else { throw ОтказЦелостности("неизвестное-владение", 2) }
        throw error
    }
}

func ограниченныйGit(
    _ аргументы: [String], корень: URL, вход: Data = Data(),
    предел: Int = 8_192, начало: UInt64 = DispatchTime.now().uptimeNanoseconds
) throws -> ОтветGit {
    let опции = ["-C", корень.path, "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false",
                 "-c", "gc.auto=0", "-c", "maintenance.auto=false", "-c", "submodule.recurse=false"]
    let среда = ["PATH": "/usr/bin:/bin", "LC_ALL": "C", "LANG": "C", "TZ": "UTC",
                 "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
                 "GIT_NO_REPLACE_OBJECTS": "1", "GIT_OPTIONAL_LOCKS": "0", "GIT_NO_LAZY_FETCH": "1",
                 "GIT_TERMINAL_PROMPT": "0"]
    return try ограниченныйПроцесс("/usr/bin/git", опции + аргументы, среда: среда, вход: вход, предел: предел, начало: начало)
}

final class ПроверкаОбъектов {
    let корень: URL
    let формат: String
    let начало = DispatchTime.now().uptimeNanoseconds
    private var кэш: [String: Data] = [:]
    private var деревья: [String: [Data: ЗаписьДерева]] = [:]
    private var метаданные = 0
    private var прочитаноБлобов = 0
    private(set) var прочитано = 0
    private(set) var вызовыGit = 0

    struct ЗаписьДерева {
        let режим: String
        let объект: String
    }
    init(корень: URL, формат: String) throws {
        self.корень = корень
        self.формат = формат
        let ответ = try git(["rev-parse", "--show-object-format"], предел: 128)
        guard ответ == Data((формат + "\n").utf8) else { throw ОтказЦелостности("формат-объектов") }
    }
    private func git(_ аргументы: [String], вход: Data = Data(), предел: Int) throws -> Data {
        вызовыGit += 1
        let ответ = try ограниченныйGit(аргументы, корень: корень, вход: вход, предел: предел, начало: начало)
        guard ответ.код == 0 else { throw ОтказЦелостности("объект-недоступен", 2) }
        return ответ.выход
    }
    private func объект(_ идентификаторОбъекта: String, тип: String, предел: Int, ожидаемый: Int? = nil) throws -> Data {
        if let тело = кэш[тип + ":" + идентификаторОбъекта] {
            guard ожидаемый == nil || ожидаемый == тело.count else { throw ОтказЦелостности("размер") }
            return тело
        }
        guard кэш.count < ПределыЦелостности.объекты else { throw ОтказЦелостности("предел", 2) }
        let заголовок = try git(["cat-file", "--batch-check"], вход: Data((идентификаторОбъекта + "\n").utf8), предел: 128)
        let части = String(decoding: заголовок, as: UTF8.self).split(separator: " ", omittingEmptySubsequences: false)
        guard части.count == 3, части[0] == идентификаторОбъекта, части[1] == тип,
              let размер = Int(части[2].dropLast()), размер >= 0,
              части[2].last == "\n" else { throw ОтказЦелостности("объект-недоступен", 2) }
        guard размер <= предел, тип == "blob" || размер <= ПределыЦелостности.метаданные - метаданные else { throw ОтказЦелостности("предел", 2) }
        guard ожидаемый == nil || ожидаемый == размер else { throw ОтказЦелостности("размер") }
        if тип == "blob" {
            guard размер <= ПределыЦелостности.сумма - прочитаноБлобов else { throw ОтказЦелостности("предел", 2) }
            прочитаноБлобов += размер
        }
        let тело = try git(["cat-file", тип, идентификаторОбъекта], предел: размер)
        guard тело.count == размер, хэшОбъекта(тип, тело, формат) == идентификаторОбъекта else { throw ОтказЦелостности("объект") }
        прочитано += тело.count
        if тип != "blob" {
            guard размер <= ПределыЦелостности.метаданные - метаданные else { throw ОтказЦелостности("предел", 2) }
            метаданные += размер
        }
        кэш[тип + ":" + идентификаторОбъекта] = тело
        return тело
    }
    private func проверитьПин(_ пин: ПинGit) throws {
        let тело = try объект(пин.коммит, тип: "commit", предел: ПределыЦелостности.объектМетаданных)
        guard let конец = тело.firstIndex(of: 10),
              тело.prefix(upTo: конец) == Data(("tree " + пин.дерево).utf8) else { throw ОтказЦелостности("дерево-коммита") }
        _ = try дерево(пин.дерево)
    }
    private func дерево(_ идентификаторОбъекта: String) throws -> [Data: ЗаписьДерева] {
        if let записи = деревья[идентификаторОбъекта] { return записи }
        let тело = try объект(идентификаторОбъекта, тип: "tree", предел: ПределыЦелостности.объектМетаданных)
        let байты = Array(тело)
        let длинаOID = формат == "sha1" ? 20 : 32
        var позиция = 0
        var записи: [Data: ЗаписьДерева] = [:]
        while позиция < байты.count {
            guard записи.count < 4_096, let пробел = байты[позиция...].firstIndex(of: 32),
                  let нуль = байты[(пробел + 1)...].firstIndex(of: 0),
                  нуль > пробел + 1, нуль + 1 + длинаOID <= байты.count else { throw ОтказЦелостности("дерево", 2) }
            let режим = String(decoding: байты[позиция..<пробел], as: UTF8.self)
            let имя = Data(байты[(пробел + 1)..<нуль])
            guard !имя.contains(47), имя != Data(".".utf8), имя != Data("..".utf8),
                  записи[имя] == nil else { throw ОтказЦелостности("дерево", 2) }
            let объект = байты[(нуль + 1)..<(нуль + 1 + длинаOID)].map { String(format: "%02x", $0) }.joined()
            записи[имя] = .init(режим: режим, объект: объект)
            позиция = нуль + 1 + длинаOID
        }
        деревья[идентификаторОбъекта] = записи
        return записи
    }
    private func найти(_ путь: String, в идентификаторОбъекта: String) throws -> ЗаписьДерева {
        let части = путь.split(separator: "/")
        var текущий = идентификаторОбъекта
        for номер in части.indices {
            guard let запись = try дерево(текущий)[Data(части[номер].utf8)] else { throw ОтказЦелостности("путь-отсутствует") }
            if номер == части.count - 1 {
                guard ["100644", "100755"].contains(запись.режим) else { throw ОтказЦелостности("тип-пути", 2) }
                return запись
            }
            guard запись.режим == "40000" else { throw ОтказЦелостности("тип-пути", 2) }
            текущий = запись.объект
        }
        throw ОтказЦелостности("путь-отсутствует")
    }
    private func изменения(_ старое: String?, _ новое: String?, _ префикс: String, _ глубина: Int, _ итог: inout Set<String>) throws {
        if старое == новое { return }
        guard глубина <= ПределыЦелостности.компоненты else { throw ОтказЦелостности("предел", 2) }
        let а = try старое.map { try дерево($0) } ?? [:]
        let б = try новое.map { try дерево($0) } ?? [:]
        for имя in Set(а.keys).union(б.keys) {
            let слева = а[имя], справа = б[имя]
            if слева?.режим == справа?.режим && слева?.объект == справа?.объект { continue }
            guard let текст = String(data: имя, encoding: .utf8) else { throw ОтказЦелостности("тип-изменения", 2) }
            let путь = префикс + текст
            guard допустимыйПуть(путь), let справа else { throw ОтказЦелостности("тип-изменения", 2) }
            if let слева, (слева.режим == "40000") != (справа.режим == "40000") {
                throw ОтказЦелостности("тип-изменения", 2)
            }
            if справа.режим == "40000" {
                try изменения(слева?.объект, справа.объект, путь + "/", глубина + 1, &итог)
            } else {
                guard ["100644", "100755"].contains(справа.режим),
                      слева == nil || ["100644", "100755"].contains(слева!.режим),
                      итог.count < ПределыЦелостности.файлы else { throw ОтказЦелостности("тип-изменения", 2) }
                итог.insert(путь)
            }
        }
    }
    func проверить(_ манифест: МанифестЦелостности) throws -> Int {
        guard манифест.источник.формат == формат else { throw ОтказЦелостности("формат-объектов") }
        try проверитьПин(манифест.источник)
        if let база = манифест.база {
            try проверитьПин(база)
            var состав = Set<String>()
            try изменения(база.дерево, манифест.источник.дерево, "", 0, &состав)
            guard состав == Set(манифест.файлы.map(\.путь)) else { throw ОтказЦелостности("состав") }
        }
        var логические = 0
        for файл in манифест.файлы {
            let запись = try найти(файл.путь, в: манифест.источник.дерево)
            guard запись.режим == файл.режим else { throw ОтказЦелостности("режим") }
            guard запись.объект == файл.объект else { throw ОтказЦелостности("объект") }
            let тело = try объект(файл.объект, тип: "blob", предел: ПределыЦелостности.файл, ожидаемый: Int(файл.байты))
            guard тело.count == файл.байты else { throw ОтказЦелостности("размер") }
            guard хэшБайтов(тело) == файл.хэш else { throw ОтказЦелостности("хэш") }
            логические += тело.count
        }
        return логические
    }
}
