import Foundation
import CryptoKit
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

private enum СбойЗапуска: Error { case параметры, предел, исход, вход, квитанция, группа, ожидание
    case узел(Int) }
private struct ИсходПроцесса {
    let код: Int32
    let сигнал: Int32?
    let процесс: Int32
    let группа: Int32
    let времяИстекло: Bool
    let выводПревышен: Bool
    let остановленПоСроку: Bool
    let посланныеСигналы: [Int32]
    let наносекунды: UInt64
    let потокВыхода: URL
    let потокОшибок: URL
}

@MainActor
@main
struct ЗапускПроверок {
    static func main() {
        do {
            началоКонтроллера = DispatchTime.now().uptimeNanoseconds
            try выполнить()
        }
        catch {
            try? закрытьПопытку(2)
            let причина = (error as? СбойЗапуска).map { String(describing: $0) } ?? "внешняя"
            let данные = Data("{\"состояние\":\"отказ-контроллера\",\"причина\":\"\(причина)\"}\n".utf8)
            try? FileHandle.standardOutput.write(contentsOf: данные)
            exit(2)
        }
    }


    private static var текущаяПопытка: URL?
    private static var операцииЗакрыты = true
    private static var началоКонтроллера: UInt64 = 0

    private static func имена(_ путь: URL, предел: Int = 128) throws -> [String] {
        guard let каталог = opendir(путь.path) else { throw СбойЗапуска.вход }
        defer { closedir(каталог) }
        var результат: [String] = []
        while let запись = readdir(каталог) {
            let длина = Int(запись.pointee.d_namlen) + 1
            let имя = withUnsafePointer(to: &запись.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: длина) { String(cString: $0) }
            }
            if имя == "." || имя == ".." { continue }
            guard результат.count < предел else { throw СбойЗапуска.предел }
            результат.append(имя)
        }
        return результат
    }

    private static func ограниченно(_ путь: URL, _ предел: Int) throws -> Data {
        guard предел >= 0 else { throw СбойЗапуска.предел }
        let дескриптор = Darwin.open(путь.path, O_RDONLY | O_NOFOLLOW)
        guard дескриптор >= 0 else { throw СбойЗапуска.вход }
        let файл = FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
        defer { try? файл.close() }
        var до = Darwin.stat()
        guard fstat(дескриптор, &до) == 0, (до.st_mode & S_IFMT) == S_IFREG,
              до.st_nlink == 1, до.st_size >= 0, до.st_size <= предел else { throw СбойЗапуска.предел }
        var данные = Data()
        while данные.count <= предел {
            let часть = try файл.read(upToCount: min(65_536, предел + 1 - данные.count)) ?? Data()
            if часть.isEmpty { break }
            данные.append(часть)
        }
        var после = Darwin.stat()
        guard данные.count <= предел, fstat(дескриптор, &после) == 0,
              до.st_dev == после.st_dev, до.st_ino == после.st_ino, до.st_size == после.st_size,
              до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
              до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec,
              до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec,
              данные.count == Int(до.st_size) else { throw СбойЗапуска.вход }
        return данные
    }

    private static func исключительно(_ данные: Data, _ путь: URL) throws {
        let дескриптор = Darwin.open(путь.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard дескриптор >= 0 else { throw СбойЗапуска.узел(81) }
        let файл = FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
        defer { try? файл.close() }
        try файл.write(contentsOf: данные)
        try файл.synchronize()
        let родитель = Darwin.open(путь.deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard родитель >= 0 else { throw СбойЗапуска.узел(87) }
        defer { Darwin.close(родитель) }
        guard fsync(родитель) == 0 else { throw СбойЗапуска.узел(89) }
    }

    private static func закрытьПопытку(_ код: Int32) throws {
        guard let каталог = текущаяПопытка else { return }
        guard операцииЗакрыты else { throw СбойЗапуска.узел(94) }
        var данные = try JSONSerialization.data(withJSONObject: [
            "схема": "fum.исход-контура-проверок.2", "состояние": "завершено",
            "код": код, "группа_закрыта": true, "вне_группы": "неизвестно"
        ], options: [.prettyPrinted, .sortedKeys])
        данные.append(10)
        try исключительно(данные, каталог.appendingPathComponent("исход.json"))
        текущаяПопытка = nil
    }

    private static func владение(_ сборка: URL, _ корень: URL) throws -> Int32 {
        guard сборка.path == сборка.resolvingSymlinksInPath().path,
              корень.path == корень.resolvingSymlinksInPath().path,
              !сборка.path.hasPrefix(корень.path + "/"), сборка.path != корень.path else { throw СбойЗапуска.вход }
        var путь = сборка
        while путь.path != "/" {
            var сведения = Darwin.stat()
            guard lstat(путь.path, &сведения) == 0, (сведения.st_mode & S_IFMT) == S_IFDIR,
                  !FileManager.default.fileExists(atPath: путь.appendingPathComponent(".git").path) else { throw СбойЗапуска.вход }
            путь.deleteLastPathComponent()
        }
        var сведения = Darwin.stat()
        guard lstat(сборка.path, &сведения) == 0, сведения.st_uid == getuid(),
              сведения.st_mode & 0o077 == 0 else { throw СбойЗапуска.вход }
        let маркер = сборка.appendingPathComponent("владелец.json")
        let новый = !FileManager.default.fileExists(atPath: маркер.path)
        if новый { guard try имена(сборка).isEmpty else { throw СбойЗапуска.вход } }
        let аренда = сборка.appendingPathComponent("аренда")
        let флаги = O_RDWR | O_NOFOLLOW | O_CLOEXEC | (новый ? O_CREAT | O_EXCL : 0)
        let дескриптор = Darwin.open(аренда.path, флаги, 0o600)
        guard дескриптор >= 0, flock(дескриптор, LOCK_EX | LOCK_NB) == 0 else { throw СбойЗапуска.вход }
        do {
            if новый {
                var данные = try JSONSerialization.data(withJSONObject: [
                    "схема": "fum.владелец-контура-проверок.1", "корень": корень.path, "пользователь": getuid()
                ], options: [.prettyPrinted, .sortedKeys])
                данные.append(10)
                try исключительно(данные, маркер)
            } else {
                let данные = try ограниченно(маркер, 4096)
                guard let документ = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
                      документ["схема"] as? String == "fum.владелец-контура-проверок.1",
                      документ["корень"] as? String == корень.path,
                      (документ["пользователь"] as? NSNumber)?.uint32Value == getuid() else { throw СбойЗапуска.вход }
                for имя in try имена(сборка) where UUID(uuidString: имя)?.uuidString.lowercased() == имя {
                    let исход = try ограниченно(сборка.appendingPathComponent(имя).appendingPathComponent("исход.json"), 4096)
                    guard let документ = try JSONSerialization.jsonObject(with: исход) as? [String: Any],
                          документ["схема"] as? String == "fum.исход-контура-проверок.2",
                          документ["состояние"] as? String == "завершено",
                          документ["группа_закрыта"] as? Bool == true else { throw СбойЗапуска.узел(143) }
                }
            }
        } catch { Darwin.close(дескриптор); throw error }
        return дескриптор
    }

    private static func записать(_ данные: Data, _ путь: URL) throws {
        try данные.write(to: путь, options: .atomic)
    }

    private static func исход(
        _ исполняемыйФайл: String, _ аргументыПроцесса: [String], _ рабочийКаталог: URL,
        _ окружение: [String: String], _ каталог: URL, _ имя: String, режимFIFO: Bool = false
    ) throws -> ИсходПроцесса {
        guard FileManager.default.currentDirectoryPath == рабочийКаталог.path,
              !([исполняемыйФайл] + аргументыПроцесса).contains(where: { $0.contains("\0") }) else { throw СбойЗапуска.параметры }
        let пределПроцесса: UInt64 = режимFIFO ? 500_000_000 : 150_000_000_000
        let пределОчистки: UInt64 = режимFIFO ? 1_000_000_000 : 2_000_000_000
        let пределыВывода = режимFIFO ? [8192, 2048] : [1_048_576, 1_048_576]
        let выход = каталог.appendingPathComponent(имя + ".stdout")
        let ошибки = каталог.appendingPathComponent(имя + ".stderr")
        func открыть(_ путь: URL) throws -> FileHandle {
            let дескриптор = Darwin.open(путь.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            guard дескриптор >= 0 else { throw СбойЗапуска.узел(164) }
            return FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
        }
        let потокВыхода = try открыть(выход), потокОшибок = try открыть(ошибки)
        defer { try? потокВыхода.close(); try? потокОшибок.close() }
        var первый: [Int32] = [-1, -1], второй: [Int32] = [-1, -1]
        guard pipe(&первый) == 0 else { throw СбойЗапуска.узел(170) }
        guard pipe(&второй) == 0 else { Darwin.close(первый[0]); Darwin.close(первый[1]); throw СбойЗапуска.узел(171) }
        defer { for дескриптор in первый + второй where дескриптор >= 0 { Darwin.close(дескриптор) } }
        let вход = Darwin.open("/dev/null", O_RDONLY | O_CLOEXEC)
        guard вход >= 0 else { throw СбойЗапуска.узел(174) }
        defer { Darwin.close(вход) }
        for дескриптор in первый + второй {
            guard fcntl(дескриптор, F_SETFD, FD_CLOEXEC) == 0 else { throw СбойЗапуска.узел(177) }
        }
        for дескриптор in [первый[0], второй[0]] {
            guard fcntl(дескриптор, F_SETFL, O_NONBLOCK) == 0 else { throw СбойЗапуска.узел(180) }
        }
        var действия: posix_spawn_file_actions_t?
        var атрибуты: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&действия) == 0 else { throw СбойЗапуска.узел(184) }
        defer { posix_spawn_file_actions_destroy(&действия) }
        guard posix_spawnattr_init(&атрибуты) == 0 else { throw СбойЗапуска.узел(186) }
        defer { posix_spawnattr_destroy(&атрибуты) }
        guard posix_spawn_file_actions_adddup2(&действия, вход, STDIN_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&действия, первый[1], STDOUT_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&действия, второй[1], STDERR_FILENO) == 0,
              posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP)) == 0,
              posix_spawnattr_setpgroup(&атрибуты, 0) == 0 else { throw СбойЗапуска.узел(192) }
        for дескриптор in первый + второй + [вход] where дескриптор > 2 {
            guard posix_spawn_file_actions_addclose(&действия, дескриптор) == 0 else { throw СбойЗапуска.узел(194) }
        }
        var указатели = ([исполняемыйФайл] + аргументыПроцесса).map { strdup($0) } + [nil]
        var переменные = окружение.keys.sorted().map { strdup($0 + "=" + окружение[$0]!) } + [nil]
        defer { for адрес in указатели + переменные { free(адрес) } }
        guard указатели.dropLast().allSatisfy({ $0 != nil }), переменные.dropLast().allSatisfy({ $0 != nil }) else { throw СбойЗапуска.предел }
        var дочерний: pid_t = 0
        let начало = DispatchTime.now().uptimeNanoseconds
        let ответ = указатели.withUnsafeMutableBufferPointer { указателиАргументов in
            переменные.withUnsafeMutableBufferPointer { указателиОкружения in
                исполняемыйФайл.withCString { posix_spawn(&дочерний, $0, &действия, &атрибуты, указателиАргументов.baseAddress, указателиОкружения.baseAddress) }
            }
        }
        guard ответ == 0, дочерний > 0 else { throw СбойЗапуска.узел(207) }
        // Только успешный spawn с SETPGROUP создаёт право сигналить эту PGID.
        операцииЗакрыты = false
        guard getpgid(дочерний) == дочерний else { throw СбойЗапуска.узел(210) }
        var якорь = true
        var собран = false
        var посланныеСигналы: [Int32] = []
        func сигнал(_ номер: Int32) throws {
            guard якорь, !собран else { throw СбойЗапуска.узел(214) }
            let ответСигнала = Darwin.kill(-дочерний, номер)
            if ответСигнала != 0 {
                if errno != ESRCH { throw СбойЗапуска.узел(215) }
            } else { посланныеСигналы.append(номер) }
        }
        defer {
            // Ошибка FIFO сохраняет UNKNOWN, без второго цикла сигналов после срока.
            if !режимFIFO && якорь && !собран {
                try? сигнал(SIGKILL)
                var статус: Int32 = 0
                if waitpid(дочерний, &статус, WNOHANG) == дочерний { собран = true }
            }
        }
        var наблюдение = try JSONSerialization.data(withJSONObject: [
            "PID": дочерний, "PGID": getpgid(дочерний), "родитель": getpid(),
            "граница": "только созданная PGID; escaped descendants UNKNOWN"
        ], options: [.prettyPrinted, .sortedKeys])
        наблюдение.append(10)
        try исключительно(наблюдение, каталог.appendingPathComponent(имя + ".процесс.json"))
        Darwin.close(первый[1]); первый[1] = -1
        Darwin.close(второй[1]); второй[1] = -1
        var конец = [false, false]
        var размеры = [0, 0]
        let каналы = [первый[0], второй[0]]
        let файлы = [потокВыхода, потокОшибок]
        var завершился = false
        var завершение: UInt64?
        var остановка: UInt64?
        var убийство = false
        var превышено = false
        var времяИстекло = false
        var выводПревышен = false
        var остановленПоСроку = false
        var крайОчисткиFIFO: UInt64?
        while true {
            let сейчас = DispatchTime.now().uptimeNanoseconds
            var подтверждёнЖивойЛидер = false
            if !завершился {
                var сведения = siginfo_t()
                let ожидание = waitid(P_PID, id_t(дочерний), &сведения, WEXITED | WNOHANG | WNOWAIT)
                if ожидание != 0 {
                    let ошибкаОжидания = errno
                    if ошибкаОжидания == EINTR {
                        if !режимFIFO { continue }
                    } else {
                        if ошибкаОжидания == ECHILD || режимFIFO { якорь = false }
                        throw СбойЗапуска.ожидание
                    }
                } else {
                    завершился = сведения.si_pid == дочерний
                    подтверждёнЖивойЛидер = сведения.si_pid == 0
                    if завершился {
                        завершение = сейчас
                        if режимFIFO && крайОчисткиFIFO == nil { крайОчисткиFIFO = сейчас + пределОчистки }
                    }
                }
            }
            guard сейчас >= начало && сейчас >= началоКонтроллера else { throw СбойЗапуска.предел }
            if режимFIFO {
                if !завершился && сейчас - начало >= пределПроцесса {
                    превышено = true
                    времяИстекло = true
                }
                if let крайОчисткиFIFO, сейчас >= крайОчисткиFIFO { throw СбойЗапуска.узел(258) }
            } else if сейчас - начало > пределПроцесса || сейчас - началоКонтроллера > 170_000_000_000 {
                превышено = true
                времяИстекло = true
            }
            if завершился && конец.allSatisfy({ $0 }) { break }
            if превышено && остановка == nil {
                try сигнал(SIGTERM)
                остановка = сейчас
                if режимFIFO {
                    if крайОчисткиFIFO == nil { крайОчисткиFIFO = сейчас + пределОчистки }
                    остановленПоСроку = времяИстекло && подтверждёнЖивойЛидер && !завершился && !выводПревышен && посланныеСигналы.contains(SIGTERM)
                }
            }
            if let остановка, сейчас - остановка > 200_000_000 && !убийство { try сигнал(SIGKILL); убийство = true }
            if let остановка, сейчас - остановка > пределОчистки { throw СбойЗапуска.узел(258) }
            var события = каналы.enumerated().map { pollfd(fd: конец[$0.offset] ? -1 : $0.element, events: Int16(POLLIN | POLLHUP), revents: 0) }
            let результат = события.withUnsafeMutableBufferPointer { poll($0.baseAddress, nfds_t($0.count), 20) }
            if результат < 0 { if errno == EINTR { continue }; throw СбойЗапуска.узел(262) }
            for индекс in 0..<2 where !конец[индекс] && события[индекс].revents != 0 {
                let остаток = max(1, пределыВывода[индекс] + 1 - размеры[индекс])
                var буфер = [UInt8](repeating: 0, count: min(65_536, остаток))
                let прочитано = буфер.withUnsafeMutableBytes { Darwin.read(каналы[индекс], $0.baseAddress, $0.count) }
                if прочитано > 0 {
                    let сохранить = min(прочитано, max(0, пределыВывода[индекс] - размеры[индекс]))
                    размеры[индекс] += прочитано
                    if сохранить > 0 { try файлы[индекс].write(contentsOf: Data(буфер.prefix(сохранить))) }
                    if размеры[индекс] > пределыВывода[индекс] { превышено = true; выводПревышен = true }
                } else if прочитано == 0 { конец[индекс] = true }
                else if errno != EAGAIN && errno != EINTR { throw СбойЗапуска.узел(274) }
            }
            if let завершение, сейчас - завершение > 500_000_000, !конец.allSatisfy({ $0 }), остановка == nil {
                try сигнал(SIGTERM); остановка = сейчас
                if режимFIFO && крайОчисткиFIFO == nil { крайОчисткиFIFO = сейчас + пределОчистки }
            }
        }
        // Нормальный выход и EOF не требуют сигналов. WNOWAIT удерживает leader до reap.
        var статус: Int32 = 0
        while true {
            if режимFIFO {
                guard let крайОчисткиFIFO, DispatchTime.now().uptimeNanoseconds < крайОчисткиFIFO else { throw СбойЗапуска.узел(284) }
            }
            let ответСбора = waitpid(дочерний, &статус, режимFIFO ? WNOHANG : 0)
            if ответСбора == дочерний { break }
            if ответСбора < 0 {
                if errno == ECHILD { якорь = false }
                if errno != EINTR { throw СбойЗапуска.узел(284) }
            } else if режимFIFO {
                guard let крайОчисткиFIFO else { throw СбойЗапуска.узел(284) }
                let сейчас = DispatchTime.now().uptimeNanoseconds
                guard сейчас < крайОчисткиFIFO,
                      дождатьсяМонотонногоСрока(min(крайОчисткиFIFO, сейчас + 2_000_000)) else { throw СбойЗапуска.узел(284) }
            }
        }
        собран = true
        якорь = false
        // Signal 0 — только RO проверка существования; при новой/оставшейся группе UNKNOWN.
        var группыНет = false
        let теперьЗакрытия = DispatchTime.now().uptimeNanoseconds
        let обычныйПределЗакрытия = теперьЗакрытия + 1_000_000_000
        guard !режимFIFO || крайОчисткиFIFO != nil else { throw СбойЗапуска.группа }
        let пределЗакрытияГруппы = режимFIFO ? (крайОчисткиFIFO ?? теперьЗакрытия) : обычныйПределЗакрытия
        while DispatchTime.now().uptimeNanoseconds < пределЗакрытияГруппы {
            errno = 0
            if Darwin.kill(-дочерний, 0) == -1 && errno == ESRCH { группыНет = true; break }
            let сейчас = DispatchTime.now().uptimeNanoseconds
            guard сейчас < пределЗакрытияГруппы else { break }
            guard дождатьсяМонотонногоСрока(min(пределЗакрытияГруппы, сейчас + 20_000_000)) else { throw СбойЗапуска.группа }
        }
        операцииЗакрыты = группыНет
        guard группыНет else { throw СбойЗапуска.группа }
        guard !превышено || режимFIFO else { throw СбойЗапуска.предел }
        let номерСигнала = статус & 0x7f
        return .init(код: номерСигнала == 0 ? (статус >> 8) & 0xff : -1,
                     сигнал: номерСигнала == 0 ? nil : номерСигнала,
                     процесс: дочерний, группа: дочерний, времяИстекло: времяИстекло, выводПревышен: выводПревышен,
                      остановленПоСроку: остановленПоСроку, посланныеСигналы: посланныеСигналы,
                     наносекунды: DispatchTime.now().uptimeNanoseconds - начало,
                     потокВыхода: выход, потокОшибок: ошибки)
    }


    // Закрытая native-проверка FIFO; старый SwiftTesting-контур не запускается.
    private static func проверитьВходFIFO(_ корень: URL, _ сборка: URL, _ режим: String) throws {
        let аренда = try владение(сборка, корень)
        defer { flock(аренда, LOCK_UN); Darwin.close(аренда) }
        let среда = ProcessInfo.processInfo.environment
        guard let программа = среда["ФУМ_ПРОВЕРЯЮЩИЙ"], программа.hasPrefix("/"),
              let ожидаемыйХэш = среда["ФУМ_ХЭШ_ПРОВЕРЯЮЩЕГО"], ожидаемыйХэш.utf8.count == 64 else { throw СбойЗапуска.параметры }
        let бинарник = try ограниченно(URL(fileURLWithPath: программа), 4_194_304)
        let хэшБинарника = SHA256.hash(data: бинарник).map { String(format: "%02x", $0) }.joined()
        guard хэшБинарника == ожидаемыйХэш else { throw СбойЗапуска.вход }
        let вход = сборка.appendingPathComponent("input.fifo")
        let привязка = сборка.appendingPathComponent("fifo-binding.json")
        if режим == "fifo-red" {
            guard mkfifo(вход.path, 0o600) == 0 else { throw СбойЗапуска.вход }
        }
        var сведения = Darwin.stat()
        guard lstat(вход.path, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFIFO,
              сведения.st_uid == getuid(), сведения.st_mode & 0o777 == 0o600, сведения.st_size == 0 else { throw СбойЗапуска.вход }
        let устройство = Int64(сведения.st_dev), номерУзла = UInt64(сведения.st_ino)
        if режим == "fifo-red" {
            var байты = try JSONSerialization.data(withJSONObject: ["устройство": устройство, "inode": номерУзла, "писатель_открыт": false], options: [.prettyPrinted, .sortedKeys])
            байты.append(10)
            try исключительно(байты, привязка)
        } else {
            let байты = try ограниченно(привязка, 4096)
            guard let объект = try JSONSerialization.jsonObject(with: байты) as? [String: Any],
                  (объект["устройство"] as? NSNumber)?.int64Value == устройство,
                  (объект["inode"] as? NSNumber)?.uint64Value == номерУзла,
                  объект["писатель_открыт"] as? Bool == false else { throw СбойЗапуска.вход }
        }
        let каталог = сборка.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        текущаяПопытка = каталог
        try исключительно(Data("{\"схема\":\"fum.намерение-контура-проверок.1\"}\n".utf8), каталог.appendingPathComponent("намерение.json"))
        let ответ = try исход(программа, ["--корень", корень.path, "--манифест", вход.path], корень,
                             ["PATH": "/usr/bin:/bin", "LC_ALL": "C"], каталог, "fifo", режимFIFO: true)
        let вывод = try ограниченно(ответ.потокВыхода, 8192)
        let ошибки = try ограниченно(ответ.потокОшибок, 2048)
        var после = Darwin.stat()
        guard lstat(вход.path, &после) == 0, Int64(после.st_dev) == устройство, UInt64(после.st_ino) == номерУзла,
              после.st_mode & S_IFMT == S_IFIFO, после.st_size == 0 else { throw СбойЗапуска.вход }
        let результат = (try? JSONSerialization.jsonObject(with: вывод)) as? [String: Any]
        let профиль = (try? JSONSerialization.jsonObject(with: ошибки)) as? [String: Any]
        let типОтклонён = ответ.код == 2 && ответ.сигнал == nil && ответ.посланныеСигналы.isEmpty && !ответ.времяИстекло && !ответ.выводПревышен
            && (результат?["код"] as? Int) == 2 && (результат?["причина"] as? String) == "тип-входа"
            && (результат?["целостность"] as? Bool) == false && (профиль?["вызовы_Git"] as? Int) == 0
        let красный = ответ.остановленПоСроку && ответ.времяИстекло && !ответ.выводПревышен
            && ответ.сигнал.map { ответ.посланныеСигналы.contains($0) } == true
            && (ответ.сигнал == SIGTERM || ответ.сигнал == SIGKILL) && вывод.isEmpty && ошибки.isEmpty
        let успех = режим == "fifo-red" ? красный : типОтклонён
        var наблюдение: [String: Any] = [
            "схема": "fum.native-проверка-типа-входа.1", "режим": режим, "успех": успех,
            "PID": ответ.процесс, "PGID": ответ.группа, "родитель": getpid(),
            "код_CLI": ответ.код, "таймаут": ответ.времяИстекло, "превышен_вывод": ответ.выводПревышен,
            "собран": true, "группа_закрыта": операцииЗакрыты,
            "устройство": устройство, "inode": номерУзла, "FIFO_размер": после.st_size, "писатель_открыт": false,
            "бинарник_sha256": хэшБинарника, "наносекунды": ответ.наносекунды,
            "stdout_sha256": SHA256.hash(data: вывод).map { String(format: "%02x", $0) }.joined(),
            "stderr_sha256": SHA256.hash(data: ошибки).map { String(format: "%02x", $0) }.joined(),
            "stdout_байты": вывод.count, "stderr_байты": ошибки.count,
            "RED_подтверждён": красный, "тип_отклонён": типОтклонён,
            "остановлен_по_сроку": ответ.остановленПоСроку, "посланные_сигналы": ответ.посланныеСигналы,
            "дедлайн_мс": 500, "grace_мс": 200, "cleanup_мс": 1000,
            "граница": "Только собственная созданная PGID; escaped descendants UNKNOWN; native-контур не является SwiftTesting @Test"
        ]
        if let сигнал = ответ.сигнал { наблюдение["сигнал"] = сигнал }
        if let код = результат?["код"] as? Int { наблюдение["результат_код"] = код }
        if let причина = результат?["причина"] as? String { наблюдение["причина"] = причина }
        if let целостность = результат?["целостность"] as? Bool { наблюдение["целостность"] = целостность }
        if let вызовы = профиль?["вызовы_Git"] as? Int { наблюдение["вызовы_Git"] = вызовы }
        var байты = try JSONSerialization.data(withJSONObject: наблюдение, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        байты.append(10)
        try исключительно(байты, каталог.appendingPathComponent("fifo-case.json"))
        try вывести(наблюдение)
        try закрытьПопытку(успех ? 0 : 1)
        exit(успех ? 0 : 1)
    }

    private static func выполнить() throws {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        guard аргументы.count == 6, аргументы[0] == "--корень",
              аргументы[2] == "--сборка", аргументы[4] == "--режим" else { throw СбойЗапуска.параметры }
        let корень = URL(fileURLWithPath: аргументы[1]).standardizedFileURL
        let сборка = URL(fileURLWithPath: аргументы[3]).standardizedFileURL
        let режим = аргументы[5]
        guard ["проба", "красный", "проверки", "fifo-red", "fifo-green"].contains(режим) else { throw СбойЗапуска.параметры }
        if режим == "fifo-red" || режим == "fifo-green" {
            try проверитьВходFIFO(корень, сборка, режим)
            return
        }
        let файлы = FileManager.default
        let аренда = try владение(сборка, корень)
        defer { flock(аренда, LOCK_UN); Darwin.close(аренда) }
        let контур = сборка.appendingPathComponent("harness")
        let библиотека = контур.appendingPathComponent("Sources/Целостность")
        let проверки = контур.appendingPathComponent("Tests/Испытания")
        let запуск = сборка.appendingPathComponent(UUID().uuidString.lowercased())
        try файлы.createDirectory(at: запуск, withIntermediateDirectories: false)
        текущаяПопытка = запуск
        try исключительно(Data("{\"схема\":\"fum.намерение-контура-проверок.1\"}\n".utf8), запуск.appendingPathComponent("намерение.json"))
        for путь in [библиотека, проверки] { try файлы.createDirectory(at: путь, withIntermediateDirectories: true) }
        let каталогИсходников = "iskhodniki/perekhod-vetok/proverka-celostnosti-iskhodnikov/"
        let каталогПроверок = "proverki/perekhod-vetok/proverka-celostnosti-iskhodnikov/"
        let копии: [(String, URL)] = [
            (каталогИсходников + "Манифест.swift", библиотека.appendingPathComponent("Манифест.swift")),
            (каталогИсходников + "ЧтениеОбъектов.swift", библиотека.appendingPathComponent("ЧтениеОбъектов.swift")),
            (каталогПроверок + "Проверки.swift", проверки.appendingPathComponent("Проверки.swift")),
            (каталогПроверок + "состав-14.json", проверки.appendingPathComponent("состав-14.json")),
            (каталогПроверок + "состав-48.json", проверки.appendingPathComponent("состав-48.json"))
        ]
        var сумма = 0
        var пины: [[String: Any]] = []
        for (путь, цель) in копии {
            let источник = корень.appendingPathComponent(путь)
            let данные = try ограниченно(источник, min(262_144, 262_144 - сумма))
            сумма += данные.count
            guard сумма <= 262_144 else { throw СбойЗапуска.предел }
            try записать(данные, цель)
            guard try ограниченно(цель, 262_144) == данные else { throw СбойЗапуска.вход }
            let хэш = SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
            пины.append(["путь": путь, "байты": данные.count, "хэш": хэш])
        }
        let пакет = """
        // swift-tools-version: 6.0
        import PackageDescription
        let настройки: [SwiftSetting] = [.swiftLanguageMode(.v6), .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]
        let package = Package(name: "ПроверкиЦелостности", platforms: [.macOS(.v14)], targets: [
            .target(name: "Целостность", swiftSettings: настройки),
            .testTarget(name: "Испытания", dependencies: ["Целостность"], resources: [.copy("состав-14.json"), .copy("состав-48.json")], swiftSettings: настройки)
        ], swiftLanguageModes: [.v6])
        """
        сумма += пакет.utf8.count
        guard сумма <= 262_144 else { throw СбойЗапуска.предел }
        try записать(Data((пакет + "\n").utf8), контур.appendingPathComponent("Package.swift"))
        let входноеОкружение = ProcessInfo.processInfo.environment
        guard let комплект = входноеОкружение["ФУМ_КОМПЛЕКТ"], let разработчик = входноеОкружение["ФУМ_РАЗРАБОТЧИК"],
              комплект.hasPrefix("/"), разработчик.hasPrefix("/") else { throw СбойЗапуска.параметры }
        let временное = сборка.appendingPathComponent("tmp")
        try файлы.createDirectory(at: временное, withIntermediateDirectories: true)
        var среда = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LC_ALL": "C",
                     "SDKROOT": комплект, "DEVELOPER_DIR": разработчик, "TMPDIR": временное.path + "/"]
        среда["CLANG_MODULE_CACHE_PATH"] = сборка.appendingPathComponent("модули-clang").path
        среда["SWIFT_MODULECACHE_PATH"] = сборка.appendingPathComponent("модули-swift").path
        let общие = [
            "swift", "test", "--package-path", контур.path, "--scratch-path", сборка.appendingPathComponent("build").path,
            "--cache-path", сборка.appendingPathComponent("cache").path,
            "--config-path", сборка.appendingPathComponent("configuration").path,
            "--security-path", сборка.appendingPathComponent("security").path,
            "--jobs", "1"
        ]
        var аргументыСборки = общие
        аргументыСборки[1] = "build"
        let сборочныйИсход = try исход("/usr/bin/xcrun", аргументыСборки + ["--build-tests"], корень, среда, запуск, "00-build")
        var результаты: [[String: Any]] = [["вызов": "сборка-тестов", "код": сборочныйИсход.код, "наносекунды": сборочныйИсход.наносекунды]]
        guard сборочныйИсход.код == 0 else {
            try вывести(["режим": режим, "успех": false, "этап": "сборка", "результаты": результаты, "пины": пины])
            try закрытьПопытку(2)
            exit(2)
        }
        let полные = ["json", "дубли", "пути", "целые", "положительные", "форматы", "git", "состав", "ссылки", "лимиты", "окружение", "неизменность", "профиль"]
        let планы: [(String, [String], String, Set<String>)] = режим == "проба"
            ? [("pass", ["--filter", "ПробаСвязности"], "успех", ["проба"]), ("fail", ["--filter", "ПробаСвязности"], "отказ", ["проба"]),
               ("none", ["--filter", "НетТакогоНабора"], "успех", [])]
            : [(режим, режим == "красный" ? ["--filter", "дублиКлючей"] : ["--filter", "ПроверкиЦелостности"], "успех",
                режим == "красный" ? ["дубли"] : Set(полные))]
        var итог = true
        for (имя, фильтр, проба, ожидаемые) in планы {
            let квитанции = запуск.appendingPathComponent("cases-" + имя)
            try файлы.createDirectory(at: квитанции, withIntermediateDirectories: true)
            var средаВызова = среда
            средаВызова["ФУМ_КВИТАНЦИИ"] = квитанции.path
            средаВызова["ФУМ_ПРОБА"] = проба
            средаВызова["ФУМ_СБОРКА"] = сборка.path
            средаВызова["ФУМ_ПРОВЕРЯЮЩИЙ"] = сборка.deletingLastPathComponent().appendingPathComponent("bin/checker").path
            let ответ = try исход("/usr/bin/xcrun", общие + ["--skip-build"] + фильтр, корень, средаВызова, запуск, имя)
            let имена = try имена(квитанции)
            var фактические = Set<String>()
            for имяФайла in имена {
                guard имена.count <= 128, имяФайла.hasSuffix(".json") else { throw СбойЗапуска.квитанция }
                let данные = try ограниченно(квитанции.appendingPathComponent(имяФайла), 4096)
                guard данные.count <= 4096,
                      let документ = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
                      документ["схема"] as? String == "fum.квитанция-проверки.1",
                      документ["состояние"] as? String == "завершён",
                      let случай = документ["случай"] as? String,
                      фактические.insert(случай).inserted else { throw СбойЗапуска.квитанция }
            }
            let проверено = ответ.код == 0 && !ожидаемые.isEmpty && фактические == ожидаемые
            if режим == "проба" {
                if имя == "pass" { итог = итог && проверено }
                else if имя == "fail" { итог = итог && ответ.код == 1 && фактические == ожидаемые }
                else { итог = итог && ответ.код == 0 && !проверено && фактические.isEmpty }
            } else { итог = итог && проверено }
            результаты.append(["вызов": имя, "код": ответ.код, "наносекунды": ответ.наносекунды,
                               "ожидалось": ожидаемые.count, "получено": фактические.count,
                               "ожидаемый_код": режим == "проба" && имя == "fail" ? 1 : 0,
                               "фактический_сигнал": ответ.сигнал.map { NSNumber(value: $0) } ?? NSNull(),
                               "ожидаемые_случаи": ожидаемые.sorted(), "фактические_случаи": фактические.sorted(),
                               "положительный_GREEN": проверено,
                               "сценарий_подтверждён": режим == "проба" ? (имя == "pass" ? проверено : имя == "fail" ? (ответ.код == 1 && фактические == ожидаемые) : (ответ.код == 0 && фактические.isEmpty)) : проверено])
        }
        try вывести(["режим": режим, "успех": итог, "результаты": результаты, "пины": пины])
        try закрытьПопытку(итог ? 0 : 1)
        exit(итог ? 0 : 1)
    }

    private static func вывести(_ объект: [String: Any]) throws {
        var данные = try JSONSerialization.data(withJSONObject: объект, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        данные.append(10)
        guard данные.count <= 8192 else { throw СбойЗапуска.предел }
        try FileHandle.standardOutput.write(contentsOf: данные)
    }
}
