import Foundation
import Darwin
import CryptoKit

struct ПинНаблюденияГруппы: Codable, Sendable {
    let путь: String
    let sha256: String
}

struct ПределыНаблюденияГруппы: Codable, Sendable {
    let миллисекунды: UInt64
    let очисткаМиллисекунд: UInt64
    let памятьБайт: UInt64
    let выводБайт: Int
    let членов: Int
}

struct ЗапросНаблюденияГруппы: Codable, Sendable {
    let схема: String
    let поколение: String
    let программа: String
    let программаSHA256: String
    let аргументы: [String]
    let рабочийКаталог: String
    let каталогИсходов: String
    let исходники: [ПинНаблюденияГруппы]
    let пределы: ПределыНаблюденияГруппы
}

struct ЧленНаблюдаемойГруппы: Codable, Sendable {
    let PID: Int32
    let PGID: Int32
    let началоСекунд: UInt64?
    let началоМикросекунд: UInt64?
    let RSS: UInt64?
}

struct КвитанцияНаблюденияГруппы: Encodable, Sendable {
    let схема = "fum.наблюдатель-группы-процессов.1"
    let поколение: String
    let запросSHA256: String
    let программаSHA256: String
    let статус: String
    let причина: String?
    let PID: Int32?
    let PGID: Int32?
    let кодВыхода: Int32?
    let сигналВыхода: Int32?
    let длительностьNS: UInt64
    let сэмплов: Int
    let наибольшийСоставГруппы: Int
    let пикНаблюдённогоRSS: UInt64
    let посланныеСигналы: [Int32]
    let группаОтсутствует: Bool
    let оставшиеся: [ЧленНаблюдаемойГруппы]
    let неизвестное: [String]
    let stdoutБайт: Int
    let stderrБайт: Int
    let полученоБайт: UInt64
    let stdoutSHA256: String
    let stderrSHA256: String
    let программаСохранена: Bool
    let исходникиСохранены: Bool
    let наибольшийСоставЗомбиНеЛидеров: Int
    let перваяОшибкаСэмпла: [String: Int64]?
    let попыткиСигналов: [[String: Int64]]
    let граница = "observed PGID; sampled RSS, not peak; no descendant/kernel containment or exactly-once guarantee"
}

enum ОшибкаНаблюденияГруппы: Error, CustomStringConvertible {
    case отказ(String)
    var description: String {
        switch self { case .отказ(let причина): return причина }
    }
}

enum НаблюдательГруппыПроцессов {
    static func хэш(_ байты: Data) -> String {
        SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
    }

    private static func требовать(_ условие: Bool, _ причина: String) throws {
        guard условие else { throw ОшибкаНаблюденияГруппы.отказ(причина) }
    }
    private static func проверитьПрефиксы(_ путь: String, каталог: Bool = false) throws -> stat {
        let части = путь.split(separator: "/")
        try требовать(путь.hasPrefix("/") && !путь.utf8.contains(0)
            && !части.isEmpty && "/" + части.joined(separator: "/") == путь
            && !части.contains(where: { $0 == "." || $0 == ".." }), "path")
        var текущий = "", последний = stat()
        for (номер, часть) in части.enumerated() {
            текущий += "/" + часть
            try требовать(lstat(текущий, &последний) == 0 && последний.st_mode & S_IFMT != S_IFLNK, "path-node")
            if номер + 1 < части.count || каталог {
                try требовать(последний.st_mode & S_IFMT == S_IFDIR, "path-directory")
            }
        }
        return последний
    }
    private static func прочитать(_ путь: String, предел: Int = 67_108_864) throws -> Data {
        let до = try проверитьПрефиксы(путь)
        try требовать(до.st_mode & S_IFMT == S_IFREG && до.st_nlink == 1
            && до.st_uid == getuid() && до.st_size >= 0 && до.st_size <= предел, "regular-owned-file")
        let fd = Darwin.open(путь, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        try требовать(fd >= 0, "file-open")
        defer { Darwin.close(fd) }
        var открытый = stat()
        try требовать(fstat(fd, &открытый) == 0 && до.st_dev == открытый.st_dev
            && до.st_ino == открытый.st_ino && до.st_mode == открытый.st_mode, "file-drift")
        var данные = Data()
        while true {
            var буфер = [UInt8](repeating: 0, count: min(16_384, max(1, предел - данные.count + 1)))
            let n = буфер.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress, $0.count) }
            if n == 0 { break }
            if n < 0 { if errno == EINTR { continue }; throw ОшибкаНаблюденияГруппы.отказ("file-read") }
            try требовать(n <= предел - данные.count, "file-budget")
            данные.append(contentsOf: буфер.prefix(n))
        }
        var после = stat()
        try требовать(fstat(fd, &после) == 0 && после.st_dev == до.st_dev && после.st_ino == до.st_ino
            && после.st_size == до.st_size && после.st_mode == до.st_mode
            && после.st_mtimespec.tv_sec == до.st_mtimespec.tv_sec
            && после.st_mtimespec.tv_nsec == до.st_mtimespec.tv_nsec
            && данные.count == до.st_size, "file-drift")
        return данные
    }
    static func прочитатьЗапрос(_ путь: String) throws -> Data {
        try прочитать(путь, предел: 131_072)
    }
    private static func записать(_ fd: Int32, _ данные: Data) throws {
        try данные.withUnsafeBytes { буфер in
            var смещение = 0
            while смещение < буфер.count {
                let n = Darwin.write(fd, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
                if n < 0 && errno == EINTR { continue }
                try требовать(n > 0, "artifact-write")
                смещение += n
            }
        }
        try требовать(fsync(fd) == 0, "artifact-sync")
    }
    private static func создать(_ каталог: Int32, _ имя: String) throws -> Int32 {
        let fd = openat(каталог, имя, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        if fd < 0 && errno == EEXIST && имя == "attempt.json" {
            throw ОшибкаНаблюденияГруппы.отказ("attempt-exists")
        }
        try требовать(fd >= 0, "artifact-create")
        return fd
    }
    private static func JSON<T: Encodable>(_ значение: T) throws -> Data {
        let кодер = JSONEncoder(); кодер.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try кодер.encode(значение) + Data([10])
    }
    private struct Сэмпл {
        var члены: [ЧленНаблюдаемойГруппы] = []
        var RSS: UInt64 = 0
        var число = 0
        var неизвестное: String?
        var диагностика: [String: Int64]?
        var зомбиНеЛидеров = 0
    }
    private static func группа(_ PGID: pid_t, предел: Int, лидерЗавершён: Bool) -> Сэмпл {
        var PID = [pid_t](repeating: 0, count: предел + 1)
        errno = 0
        // libproc возвращает число PID; размер входного буфера задаётся в байтах.
        let n = PID.withUnsafeMutableBytes { proc_listpgrppids(PGID, $0.baseAddress, Int32($0.count)) }
        let ошибка = errno
        let диагностикаСписка: [String: Int64] = ["PGID": Int64(PGID),
            "listКод": Int64(n), "listErrno": Int64(ошибка), "пределЧленов": Int64(предел)]
        if n < 0 || (n == 0 && ошибка != 0) {
            return .init(неизвестное: "group-list", диагностика: диагностикаСписка)
        }
        if n > предел {
            return .init(число: Int(n), неизвестное: "group-capacity", диагностика: диагностикаСписка)
        }
        if n == 0 {
            errno = 0
            let код = Darwin.kill(-PGID, 0), e = errno
            var диагностика = диагностикаСписка
            диагностика["kill0Код"] = Int64(код); диагностика["kill0Errno"] = Int64(e)
            return код == -1 && e == ESRCH ? .init()
                : .init(неизвестное: "group-list-empty", диагностика: диагностика)
        }
        var итог = Сэмпл(число: Int(n))
        let список = Array(PID.prefix(Int(n)))
        if Set(список).count != список.count || список.contains(where: { $0 <= 1 }) {
            return .init(число: Int(n), неизвестное: "group-pids", диагностика: диагностикаСписка)
        }
        var чтенияЛидера: [String: Int64] = [:]
        func завершённыйЛидер() -> Bool {
            var сведения = siginfo_t()
            errno = 0
            let код = waitid(P_PID, id_t(PGID), &сведения, WEXITED | WNOHANG | WNOWAIT)
            let ошибка = errno
            let номер = чтенияЛидера["waitCount", default: 0] + 1
            чтенияЛидера["waitCount"] = номер
            чтенияЛидера["wait\(номер)PID"] = Int64(PGID)
            чтенияЛидера["wait\(номер)Код"] = Int64(код)
            чтенияЛидера["wait\(номер)Errno"] = Int64(ошибка)
            чтенияЛидера["wait\(номер)SiPID"] = Int64(сведения.si_pid)
            return код == 0 && сведения.si_pid == PGID
        }
        for p in список {
            чтенияЛидера = [:]
            if p == PGID && (лидерЗавершён || завершённыйЛидер()) {
                итог.члены.append(.init(PID: p, PGID: PGID, началоСекунд: nil, началоМикросекунд: nil, RSS: nil))
                continue // WNOWAIT удерживает идентичность лидера; задача уже завершена.
            }
            var all = proc_taskallinfo()
            let размерAll = Int32(MemoryLayout<proc_taskallinfo>.stride)
            errno = 0
            let кодAll = proc_pidinfo(p, PROC_PIDTASKALLINFO, 0, &all, размерAll)
            let ошибкаAll = errno
            let полный = кодAll == размерAll
            var диагностика = диагностикаСписка
            диагностика.merge(["PID": Int64(p), "PGID": Int64(PGID),
                "TASKALLКод": Int64(кодAll), "TASKALLErrno": Int64(ошибкаAll),
                "TASKALLРазмер": Int64(размерAll)]) { _, новое in новое }
            var b = all.pbsd
            func сохранитьBSD() {
                диагностика["BSDPID"] = Int64(b.pbi_pid); диагностика["BSDPGID"] = Int64(b.pbi_pgid)
                диагностика["BSDСтатус"] = Int64(b.pbi_status); диагностика["BSDUID"] = Int64(b.pbi_uid)
                диагностика["BSDНачалоСекунд"] = Int64(b.pbi_start_tvsec)
                диагностика["BSDНачалоМикросекунд"] = Int64(b.pbi_start_tvusec)
            }
            func неуспех(_ причина: String) -> Сэмпл {
                диагностика.merge(чтенияЛидера) { _, новое in новое }
                итог.неизвестное = причина; итог.диагностика = диагностика
                return итог
            }
            if полный { сохранитьBSD() }
            else {
                let размерBSD = Int32(MemoryLayout<proc_bsdinfo>.stride)
                errno = 0
                // Ненулевой arg разрешает BSD-identity уже завершённого процесса.
                let кодBSD = proc_pidinfo(p, PROC_PIDTBSDINFO, 1, &b, размерBSD)
                let ошибкаBSD = errno
                диагностика["BSDКод"] = Int64(кодBSD); диагностика["BSDErrno"] = Int64(ошибкаBSD)
                диагностика["BSDРазмер"] = Int64(размерBSD)
                if кодBSD == размерBSD {
                    сохранитьBSD()
                } else {
                    if p == PGID && завершённыйЛидер() {
                        итог.члены.append(.init(PID: p, PGID: PGID, началоСекунд: nil, началоМикросекунд: nil, RSS: nil))
                        continue
                    }
                    errno = 0
                    let код = Darwin.kill(p, 0), e = errno
                    диагностика["kill0Код"] = Int64(код); диагностика["kill0Errno"] = Int64(e)
                    if код == -1 && e == ESRCH { continue }
                    return неуспех("member-identity")
                }
            }
            if b.pbi_pid != UInt32(p) || b.pbi_pgid != UInt32(PGID) {
                return неуспех("member-group-drift")
            }
            var RSS: UInt64?
            if b.pbi_status != UInt32(SZOMB) {
                if !полный { return неуспех("member-rss") }
                RSS = all.ptinfo.pti_resident_size
                let сумма = итог.RSS.addingReportingOverflow(all.ptinfo.pti_resident_size)
                if сумма.overflow { return неуспех("rss-overflow") }
                итог.RSS = сумма.partialValue
            }
            if p != PGID && b.pbi_status == UInt32(SZOMB) { итог.зомбиНеЛидеров += 1 }
            итог.члены.append(.init(PID: p, PGID: PGID, началоСекунд: b.pbi_start_tvsec,
                началоМикросекунд: b.pbi_start_tvusec, RSS: RSS))
        }
        return итог
    }

    static func выполнить(_ данные: Data) throws -> КвитанцияНаблюденияГруппы {
        let начало = DispatchTime.now().uptimeNanoseconds
        try требовать(данные.count <= 131_072, "request-budget")
        let запрос = try JSONDecoder().decode(ЗапросНаблюденияГруппы.self, from: данные)
        let п = запрос.пределы
        try требовать(запрос.схема == "fum.запрос-наблюдения-группы.1"
            && UUID(uuidString: запрос.поколение) != nil, "request-schema")
        try требовать((500...180_000).contains(п.миллисекунды)
            && (400...1_000).contains(п.очисткаМиллисекунд) && п.очисткаМиллисекунд < п.миллисекунды
            && (1...536_870_912).contains(п.памятьБайт) && (1...65_536).contains(п.выводБайт)
            && (1...32).contains(п.членов) && запрос.исходники.count <= 64, "limits")
        try требовать(запрос.аргументы.count <= 128
            && запрос.аргументы.reduce(0, { $0 + $1.utf8.count }) <= 65_536
            && !запрос.аргументы.contains(where: { $0.utf8.contains(0) }), "argv")
        _ = try проверитьПрефиксы(запрос.рабочийКаталог, каталог: true)
        let каталог = try проверитьПрефиксы(запрос.каталогИсходов, каталог: true)
        try требовать(каталог.st_uid == getuid() && каталог.st_mode & 0o077 == 0, "private-output-directory")
        let программа = try проверитьПрефиксы(запрос.программа)
        try требовать(программа.st_mode & 0o111 != 0
            && программа.st_mode & mode_t(S_ISUID | S_ISGID) == 0, "executable-mode")
        try требовать(хэш(try прочитать(запрос.программа)) == запрос.программаSHA256, "executable-pin")
        for pin in запрос.исходники {
            try требовать(хэш(try прочитать(pin.путь, предел: 8_388_608)) == pin.sha256, "source-pin")
        }
        let dir = Darwin.open(запрос.каталогИсходов, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        try требовать(dir >= 0, "output-directory-open")
        defer { Darwin.close(dir) }
        var открытыйКаталог = stat()
        try требовать(fstat(dir, &открытыйКаталог) == 0 && открытыйКаталог.st_dev == каталог.st_dev
            && открытыйКаталог.st_ino == каталог.st_ino, "output-directory-drift")
        let имена = try FileManager.default.contentsOfDirectory(atPath: запрос.каталогИсходов)
        if имена.contains("attempt.json") { throw ОшибкаНаблюденияГруппы.отказ("attempt-exists") }
        try требовать(имена.isEmpty, "output-not-empty")
        let метка = try создать(dir, "attempt.json")
        do {
            try записать(метка, JSON(["схема": "fum.намерение-наблюдения-группы.1",
                "поколение": запрос.поколение, "запросSHA256": хэш(данные),
                "программаSHA256": запрос.программаSHA256]))
            try требовать(fsync(dir) == 0, "intent-directory-sync")
        } catch { Darwin.close(метка); throw error }
        Darwin.close(метка)
        let out = try создать(dir, "stdout.bin")
        defer { Darwin.close(out) }
        let err = try создать(dir, "stderr.bin")
        defer { Darwin.close(err) }
        var каналы = [[Int32](repeating: -1, count: 2), [Int32](repeating: -1, count: 2)]
        defer { for пара in каналы { for fd in пара where fd >= 0 { Darwin.close(fd) } } }
        for i in 0..<2 {
            try требовать(pipe(&каналы[i]) == 0, "pipe")
            for fd in каналы[i] { try требовать(fcntl(fd, F_SETFD, FD_CLOEXEC) == 0, "pipe-cloexec") }
            try требовать(fcntl(каналы[i][0], F_SETFL, O_NONBLOCK) == 0, "pipe-nonblock")
        }
        var действия: posix_spawn_file_actions_t?
        var атрибуты: posix_spawnattr_t?
        try требовать(posix_spawn_file_actions_init(&действия) == 0, "spawn-actions")
        defer { posix_spawn_file_actions_destroy(&действия) }
        try требовать(posix_spawnattr_init(&атрибуты) == 0, "spawn-attributes")
        defer { posix_spawnattr_destroy(&атрибуты) }
        try требовать(posix_spawn_file_actions_addopen(&действия, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0
            && posix_spawn_file_actions_adddup2(&действия, каналы[0][1], STDOUT_FILENO) == 0
            && posix_spawn_file_actions_adddup2(&действия, каналы[1][1], STDERR_FILENO) == 0, "spawn-streams")
        if #available(macOS 26.0, *) {
            try требовать(posix_spawn_file_actions_addchdir(&действия, запрос.рабочийКаталог) == 0, "spawn-cwd")
        } else {
            try требовать(posix_spawn_file_actions_addchdir_np(&действия, запрос.рабочийКаталог) == 0, "spawn-cwd")
        }
        for пара in каналы { for fd in пара where fd > 2 {
            try требовать(posix_spawn_file_actions_addclose(&действия, fd) == 0, "spawn-close")
        } }
        var маска = sigset_t(), умолчания = sigset_t()
        _ = sigemptyset(&маска); _ = sigemptyset(&умолчания)
        for s in [SIGALRM, SIGTERM, SIGINT, SIGPIPE] { _ = sigaddset(&умолчания, s) }
        try требовать(posix_spawnattr_setpgroup(&атрибуты, 0) == 0
            && posix_spawnattr_setsigmask(&атрибуты, &маска) == 0
            && posix_spawnattr_setsigdefault(&атрибуты, &умолчания) == 0
            && posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF)) == 0, "spawn-group")
        let строки = ([запрос.программа] + запрос.аргументы).map { strdup($0) }
        let значенияСреды: [String] = ["PATH=/usr/bin:/bin", "LC_ALL=C", "GIT_OPTIONAL_LOCKS=0"]
        let среда = значенияСреды.map { strdup($0) }
        defer { for p in строки + среда { free(p) } }
        try требовать((строки + среда).allSatisfy({ $0 != nil }), "spawn-allocation")
        var argv = строки + [nil], envp = среда + [nil], PID: pid_t = 0
        let край = начало + п.миллисекунды * 1_000_000
        let крайРаботы = край - п.очисткаМиллисекунд * 1_000_000
        try требовать(DispatchTime.now().uptimeNanoseconds < крайРаботы, "preflight-time-budget")
        let запуск = argv.withUnsafeMutableBufferPointer { a in envp.withUnsafeMutableBufferPointer { e in
            posix_spawn(&PID, запрос.программа, &действия, &атрибуты, a.baseAddress, e.baseAddress)
        } }
        // Не адресуем PGID 0/1 даже при нарушенном контракте системного ответа.
        try требовать(запуск != 0 || PID > 1, "spawn-PID-UNKNOWN")
        for i in 0..<2 { Darwin.close(каналы[i][1]); каналы[i][1] = -1 }
        var причина: String? = запуск == 0 ? nil : "spawn-failed-\(запуск)"
        var неизвестное: [String] = []
        var буферы = [Data(), Data()], EOF = [false, false]
        var получено: UInt64 = 0, сэмплов = 0, состав = 0, пик: UInt64 = 0
        var сигналы: [Int32] = [], оставшиеся: [ЧленНаблюдаемойГруппы] = []
        var завершён = false, собран = false, якорь = запуск == 0
        var составИзвестен = false, KILLПодтверждён = false
        var статус: Int32?, остановка: UInt64?, последнийСэмпл: UInt64 = 0
        var наибольшийСоставЗомбиНеЛидеров = 0
        var перваяОшибкаСэмпла: [String: Int64]?
        var попыткиСигналов: [[String: Int64]] = []
        func неизвестно(_ код: String) {
            if !неизвестное.contains(код) { неизвестное.append(код) }
            if причина == nil { причина = "observation-failed" }
        }
        func послать(_ сигнал: Int32) {
            guard якорь && !собран else { неизвестно("lost-leader-anchor"); return }
            сигналы.append(сигнал)
            errno = 0
            let код = Darwin.kill(-PID, сигнал), e = errno
            if попыткиСигналов.count < 2 {
                попыткиСигналов.append(["PID": Int64(PID), "PGID": Int64(PID), "сигнал": Int64(сигнал), "код": Int64(код), "errno": Int64(e),
                    "NS": Int64(DispatchTime.now().uptimeNanoseconds - начало),
                    "якорь": якорь ? 1 : 0, "собран": собран ? 1 : 0, "завершён": завершён ? 1 : 0])
            }
            if код != 0 && e != ESRCH { неизвестно("signal-\(сигнал)-errno-\(e)") }
            if сигнал == SIGKILL && (код == 0 || e == ESRCH) { KILLПодтверждён = true }
        }
        if запуск == 0 {
            // Добавочная запись сохраняет известный PID после запуска. Любая её
            // ошибка защёлкивает UNKNOWN и ведёт к очистке, а не бросает ребёнка.
            do {
                let fd = try создать(dir, "spawn.json")
                defer { Darwin.close(fd) }
                struct Запуск: Encodable {
                    let поколение: String
                    let PID: Int32
                    let PGID: Int32
                    let запросSHA256: String
                    let программаSHA256: String
                }
                try записать(fd, JSON(Запуск(поколение: запрос.поколение, PID: PID, PGID: PID,
                    запросSHA256: хэш(данные), программаSHA256: запрос.программаSHA256)))
                try требовать(fsync(dir) == 0, "spawn-directory-sync")
            } catch { неизвестно("spawn-record") }
            while true {
                let сейчас = DispatchTime.now().uptimeNanoseconds
                if сейчас >= край { неизвестно("cleanup-time-budget"); break }
                if !завершён && якорь {
                    var сведения = siginfo_t()
                    let код = waitid(P_PID, id_t(PID), &сведения, WEXITED | WNOHANG | WNOWAIT), e = errno
                    if код == 0 { завершён = сведения.si_pid == PID }
                    else if e != EINTR {
                        if e == ECHILD { якорь = false }
                        неизвестно("leader-wait"); break
                    }
                }
                if !KILLПодтверждён && (сейчас - последнийСэмпл >= 20_000_000 || завершён) {
                    let с = группа(PID, предел: п.членов, лидерЗавершён: завершён)
                    последнийСэмпл = сейчас; сэмплов += 1
                    if перваяОшибкаСэмпла == nil, var диагностика = с.диагностика {
                        диагностика["NS"] = Int64(DispatchTime.now().uptimeNanoseconds - начало)
                        диагностика["номерСэмпла"] = Int64(сэмплов); диагностика["watcherUID"] = Int64(getuid())
                        диагностика["watcherEUID"] = Int64(geteuid()); перваяОшибкаСэмпла = диагностика
                    }
                    наибольшийСоставЗомбиНеЛидеров = max(наибольшийСоставЗомбиНеЛидеров, с.зомбиНеЛидеров)
                    состав = max(состав, с.число); пик = max(пик, с.RSS)
                    составИзвестен = с.неизвестное == nil
                    if составИзвестен { оставшиеся = с.члены }
                    if let код = с.неизвестное { неизвестно(код) }
                    if с.RSS > п.памятьБайт && причина == nil { причина = "memory-budget" }
                    if завершён && с.члены.contains(where: { $0.PID != PID }) && причина == nil {
                        причина = "leader-exited-with-members"
                    }
                }
                if сейчас >= крайРаботы && причина == nil { причина = "time-budget" }
                if причина != nil && остановка == nil {
                    остановка = сейчас; послать(SIGTERM)
                }
                if let остановка, сейчас - остановка >= 200_000_000 && !сигналы.contains(SIGKILL) {
                    послать(SIGKILL)
                }
                var события = (0..<2).map { pollfd(fd: EOF[$0] ? -1 : каналы[$0][0],
                    events: Int16(POLLIN | POLLHUP), revents: 0) }
                let кодОпроса = события.withUnsafeMutableBufferPointer { poll($0.baseAddress, 2, 10) }
                if кодОпроса < 0 && errno != EINTR { неизвестно("stream-poll") }
                for i in 0..<2 where !EOF[i] && события[i].revents != 0 {
                    var блок = [UInt8](repeating: 0, count: 4_096)
                    let n = блок.withUnsafeMutableBytes { Darwin.read(каналы[i][0], $0.baseAddress, $0.count) }
                    if n == 0 { EOF[i] = true }
                    else if n > 0 {
                        let сумма = получено.addingReportingOverflow(UInt64(n))
                        if сумма.overflow { неизвестно("output-count-overflow") }
                        else { получено = сумма.partialValue }
                        let остаток = max(0, п.выводБайт - буферы[0].count - буферы[1].count)
                        буферы[i].append(contentsOf: блок.prefix(min(n, остаток)))
                        if n > остаток && причина == nil { причина = "output-budget" }
                    } else if errno != EINTR && errno != EAGAIN { неизвестно("stream-read") }
                }
                if завершён && EOF.allSatisfy({ $0 }) {
                    // Неизвестный состав не разрешает потерять PGID-якорь до
                    // подтверждённой эскалации. Absence проверяется после reap.
                    if (составИзвестен && !оставшиеся.contains(where: { $0.PID != PID }))
                        || KILLПодтверждён { break }
                }
            }
            if якорь {
                if !завершён {
                    var сведения = siginfo_t()
                    if waitid(P_PID, id_t(PID), &сведения, WEXITED | WNOHANG | WNOWAIT) == 0 {
                        завершён = сведения.si_pid == PID
                    }
                }
                // Ни одного сигнала PGID после успешного reap.
                if завершён {
                    while true {
                        var s: Int32 = 0
                        let n = waitpid(PID, &s, WNOHANG), e = errno
                        if n == PID { статус = s; собран = true; якорь = false; break }
                        if n < 0 && e == EINTR && DispatchTime.now().uptimeNanoseconds < край { continue }
                        неизвестно("leader-reap"); break
                    }
                } else { неизвестно("leader-still-running") }
            }
        } else { EOF = [true, true] }
        var отсутствует = запуск != 0
        if собран {
            while DispatchTime.now().uptimeNanoseconds < край {
                errno = 0
                let n = Darwin.kill(-PID, 0), e = errno
                if n == -1 && e == ESRCH { отсутствует = true; оставшиеся = []; break }
                if n != 0 && e != ESRCH { неизвестно("group-absence"); break }
                _ = poll(nil, 0, 10)
            }
        }
        if !отсутствует {
            неизвестно("group-leftovers")
            if собран { неизвестно("post-reap-members-unverified") }
        }
        if !EOF[0] { неизвестно("stdout-not-EOF") }
        if !EOF[1] { неизвестно("stderr-not-EOF") }
        let программаСохранена = (try? хэш(прочитать(запрос.программа))) == запрос.программаSHA256
        let исходникиСохранены = запрос.исходники.allSatisfy { (try? хэш(прочитать($0.путь, предел: 8_388_608))) == $0.sha256 }
        if !программаСохранена { неизвестно("executable-drift") }
        if !исходникиСохранены { неизвестно("source-drift") }
        let сигнал = статус.map { $0 & 0x7f }.flatMap { $0 == 0 ? nil : $0 }
        let код = статус.flatMap { $0 & 0x7f == 0 ? ($0 >> 8) & 0xff : nil }
        let состояние = !неизвестное.isEmpty ? "UNKNOWN"
            : (причина != nil ? (запуск == 0 ? "stopped" : "failed") : (код == 0 ? "completed" : "failed"))
        let итог = КвитанцияНаблюденияГруппы(поколение: запрос.поколение, запросSHA256: хэш(данные),
            программаSHA256: запрос.программаSHA256, статус: состояние, причина: причина,
            PID: запуск == 0 ? PID : nil, PGID: запуск == 0 ? PID : nil,
            кодВыхода: код, сигналВыхода: сигнал, длительностьNS: DispatchTime.now().uptimeNanoseconds - начало,
            сэмплов: сэмплов, наибольшийСоставГруппы: состав, пикНаблюдённогоRSS: пик,
            посланныеСигналы: сигналы, группаОтсутствует: отсутствует, оставшиеся: оставшиеся,
            неизвестное: неизвестное, stdoutБайт: буферы[0].count, stderrБайт: буферы[1].count,
            полученоБайт: получено, stdoutSHA256: хэш(буферы[0]), stderrSHA256: хэш(буферы[1]),
            программаСохранена: программаСохранена, исходникиСохранены: исходникиСохранены,
            наибольшийСоставЗомбиНеЛидеров: наибольшийСоставЗомбиНеЛидеров,
            перваяОшибкаСэмпла: перваяОшибкаСэмпла, попыткиСигналов: попыткиСигналов)
        try записать(out, буферы[0]); try записать(err, буферы[1])
        let квитанция = try JSON(итог)
        try требовать(квитанция.count <= 16_384, "receipt-budget")
        let fd = try создать(dir, "result.json")
        defer { Darwin.close(fd) }
        try записать(fd, квитанция)
        try требовать(fsync(dir) == 0, "result-directory-sync")
        return итог
    }
}

#if ФУМ_КОМАНДА_НАБЛЮДАТЕЛЯ
@main struct КомандаНаблюденияГруппы {
    static func main() {
        do {
            let аргументы = Array(CommandLine.arguments.dropFirst())
            guard аргументы.count == 2 && аргументы[0] == "--запрос" else {
                throw ОшибкаНаблюденияГруппы.отказ("нужен-один-параметр-запрос")
            }
            let данные = try НаблюдательГруппыПроцессов.прочитатьЗапрос(аргументы[1])
            let итог = try НаблюдательГруппыПроцессов.выполнить(данные)
            let кодер = JSONEncoder(); кодер.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            try FileHandle.standardOutput.write(contentsOf: кодер.encode(итог) + Data([10]))
            exit(итог.статус == "completed" ? 0 : (итог.статус == "UNKNOWN" ? 3 : 2))
        } catch {
            try? FileHandle.standardError.write(contentsOf: Data(("Отказ наблюдения: \(error)\n").utf8))
            exit(3)
        }
    }
}
#endif
