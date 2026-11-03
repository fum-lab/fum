import Foundation
import CryptoKit
import Darwin

enum ОшибкаСвежести: Error, Equatable {
    case параметры, путь, типФайла, предел, кодировка, вводВывод
    case повреждённаяМетка, незакрытаяОграда, неподдерживаемыйДокумент
    case git, неизвестныйGit(Int32), неизвестнаяЗапись, неизвестнаяОчистка(String)

    var неизвестно: Bool {
        switch self {
        case .неизвестныйGit, .неизвестнаяЗапись, .неизвестнаяОчистка: true
        default: false
        }
    }
}

struct РезультатСвежести {
    let данные: Data
    let хэш: String
    let время: String
    let изменено: Bool
}

enum СвежестьMarkdown {
    static let предел = 1_048_576
    static let начало = "<!-- FUM-MD-RECENCY:BEGIN -->"
    static let конец = "<!-- FUM-MD-RECENCY:END -->"

    static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    static func обновить(_ исходник: Data, сейчас: Date) throws -> РезультатСвежести {
        guard исходник.count <= предел else { throw ОшибкаСвежести.предел }
        let строка = String(decoding: исходник, as: UTF8.self)
        guard Data(строка.utf8) == исходник else { throw ОшибкаСвежести.кодировка }
        let LF = строка.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let (тело, прежняя) = try разобратьСодержание(LF)
        let хэшТела = хэш(Data(тело.utf8))
        let время: String
        if let прежняя, прежняя.хэш == хэшТела {
            время = прежняя.время
        } else {
            время = try форматтер().string(from: сейчас)
            guard try корректноеВремя(время) else { throw ОшибкаСвежести.вводВывод }
        }
        let итог = тело + "\n" + начало + "\n<!-- last-content-edit: " + время
            + " -->\n<!-- content-sha256: sha256:" + хэшТела + " -->\n" + конец + "\n"
        let данные = Data(итог.utf8)
        guard данные.count <= предел else { throw ОшибкаСвежести.предел }
        return РезультатСвежести(данные: данные, хэш: хэшТела, время: время, изменено: данные != исходник)
    }

    struct Метка {
        let время: String
        let хэш: String
    }

    static func форматтер() throws -> DateFormatter {
        guard let зона = TimeZone(identifier: "Europe/Moscow") else { throw ОшибкаСвежести.вводВывод }
        let ф = DateFormatter()
        ф.locale = Locale(identifier: "en_US_POSIX")
        ф.calendar = Calendar(identifier: .gregorian)
        ф.timeZone = зона
        ф.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"
        ф.isLenient = false
        return ф
    }

    static func корректноеВремя(_ значение: String) throws -> Bool {
        guard значение.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} MSK$"#, options: .regularExpression) != nil else { return false }
        let ф = try форматтер()
        guard let дата = ф.date(from: значение) else { return false }
        return ф.string(from: дата) == значение
    }

    static func ограда(_ строка: String) -> (UInt8, Int, String)? {
        let байты = Array(строка.utf8)
        var i = 0
        while i < байты.count && байты[i] == 32 { i += 1 }
        guard i <= 3, i < байты.count, байты[i] == 96 || байты[i] == 126 else { return nil }
        let знак = байты[i]
        let начало = i
        while i < байты.count && байты[i] == знак { i += 1 }
        guard i - начало >= 3 else { return nil }
        return (знак, i - начало, String(decoding: байты[i...], as: UTF8.self))
    }

    static func разобратьСодержание(_ текст: String) throws -> (String, Метка?) {
        var строки = текст.components(separatedBy: "\n")
        if строки.last == "" { строки.removeLast() }
        var снаружи = [Bool](repeating: true, count: строки.count)
        var открытая: (UInt8, Int)?
        for i in строки.indices {
            снаружи[i] = открытая == nil
            if let (знак, длина, хвост) = ограда(строки[i]) {
                if let текущая = открытая {
                    if знак == текущая.0 && длина >= текущая.1 && хвост.utf8.allSatisfy({ $0 == 32 || $0 == 9 }) {
                        открытая = nil
                    }
                    снаружи[i] = false
                } else if знак != 96 || !хвост.contains("`") {
                    открытая = (знак, длина)
                    снаружи[i] = false
                }
            }
        }
        guard открытая == nil else { throw ОшибкаСвежести.незакрытаяОграда }
        let кандидат = строки.indices.last(where: { снаружи[$0] && строки[$0].contains(начало) })
        guard let i = кандидат else {
            guard !строки.indices.contains(where: { снаружи[$0] && строки[$0].contains("<!-- FUM-MD-RECENCY:") }) else { throw ОшибкаСвежести.повреждённаяМетка }
            return (текст.hasSuffix("\n") ? текст : текст + "\n", nil)
        }
        guard i + 4 == строки.count, (i..<(i + 4)).allSatisfy({ снаружи[$0] }),
              строки[i] == начало, строки[i + 3] == конец else { throw ОшибкаСвежести.повреждённаяМетка }
        let префиксВремени = "<!-- last-content-edit: "
        let префиксХэша = "<!-- content-sha256: sha256:"
        let суффикс = " -->"
        guard строки[i + 1].hasPrefix(префиксВремени), строки[i + 1].hasSuffix(суффикс),
              строки[i + 2].hasPrefix(префиксХэша), строки[i + 2].hasSuffix(суффикс) else { throw ОшибкаСвежести.повреждённаяМетка }
        let время = String(строки[i + 1].dropFirst(префиксВремени.count).dropLast(суффикс.count))
        let хэш = String(строки[i + 2].dropFirst(префиксХэша.count).dropLast(суффикс.count))
        guard try корректноеВремя(время), хэш.utf8.count == 64,
              хэш.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else { throw ОшибкаСвежести.повреждённаяМетка }
        let тело = строки[..<i].joined(separator: "\n")
        return (тело.hasSuffix("\n") ? тело : тело + "\n", Метка(время: время, хэш: хэш))
    }
}

func монотонноеВремя() throws -> UInt64 {
    var значение = timespec()
    guard clock_gettime(CLOCK_MONOTONIC, &значение) == 0,
          значение.tv_sec >= 0, значение.tv_nsec >= 0 else { throw ОшибкаСвежести.вводВывод }
    return UInt64(значение.tv_sec) * 1_000_000_000 + UInt64(значение.tv_nsec)
}

struct ИсходGitСвежести {
    let данные: Data
    let PID: Int32
    let наносекунды: UInt64
}

enum GitСвежести {
    // Синхронный ограниченный POSIX-адаптер. CLI использует только ls-files;
    // init/add вызываются исключительно собственной открытой тестовой фикстурой.
    static func выполнить(корень: String, аргументы: [String]) throws -> ИсходGitСвежести {
        var труба: [Int32] = [-1, -1]
        guard pipe(&труба) == 0 else { throw ОшибкаСвежести.вводВывод }
        defer { for д in труба where д >= 0 { Darwin.close(д) } }
        for д in труба { guard fcntl(д, F_SETFD, FD_CLOEXEC) == 0 else { throw ОшибкаСвежести.вводВывод } }
        guard fcntl(труба[0], F_SETFL, O_NONBLOCK) == 0 else { throw ОшибкаСвежести.вводВывод }
        let пусто = Darwin.open("/dev/null", O_RDWR | O_CLOEXEC)
        guard пусто >= 0 else { throw ОшибкаСвежести.вводВывод }
        defer { Darwin.close(пусто) }
        var действия: posix_spawn_file_actions_t?
        var атрибуты: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&действия) == 0 else { throw ОшибкаСвежести.вводВывод }
        defer { posix_spawn_file_actions_destroy(&действия) }
        guard posix_spawnattr_init(&атрибуты) == 0 else { throw ОшибкаСвежести.вводВывод }
        defer { posix_spawnattr_destroy(&атрибуты) }
        guard posix_spawn_file_actions_adddup2(&действия, пусто, STDIN_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&действия, труба[1], STDOUT_FILENO) == 0,
              posix_spawn_file_actions_adddup2(&действия, пусто, STDERR_FILENO) == 0,
              posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP)) == 0,
              posix_spawnattr_setpgroup(&атрибуты, 0) == 0 else { throw ОшибкаСвежести.вводВывод }
        for д in труба + [пусто] where д > 2 {
            guard posix_spawn_file_actions_addclose(&действия, д) == 0 else { throw ОшибкаСвежести.вводВывод }
        }
        let команда = ["/usr/bin/git", "--literal-pathspecs", "-C", корень,
                       "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false",
                       "-c", "core.untrackedCache=false"] + аргументы
        let среда = ["PATH=/usr/bin:/bin", "LC_ALL=C", "GIT_CONFIG_NOSYSTEM=1",
                     "GIT_CONFIG_GLOBAL=/dev/null", "GIT_OPTIONAL_LOCKS=0", "GIT_TERMINAL_PROMPT=0"]
        guard !(команда + среда).contains(where: { $0.contains("\0") }) else { throw ОшибкаСвежести.параметры }
        var argv = команда.map { strdup($0) } + [nil]
        var envp = среда.map { strdup($0) } + [nil]
        defer { for указатель in argv + envp { free(указатель) } }
        guard argv.dropLast().allSatisfy({ $0 != nil }), envp.dropLast().allSatisfy({ $0 != nil }) else { throw ОшибкаСвежести.предел }
        var PID: pid_t = 0
        let начало = try монотонноеВремя()
        let код = argv.withUnsafeMutableBufferPointer { а in
            envp.withUnsafeMutableBufferPointer { с in
                posix_spawn(&PID, "/usr/bin/git", &действия, &атрибуты, а.baseAddress, с.baseAddress)
            }
        }
        guard код == 0, PID > 0 else { throw ОшибкаСвежести.git }
        func времяПослеЗапуска() throws -> UInt64 {
            do { return try монотонноеВремя() }
            catch { throw ОшибкаСвежести.неизвестныйGit(PID) }
        }
        Darwin.close(труба[1]); труба[1] = -1
        guard getpgid(PID) == PID else { throw ОшибкаСвежести.неизвестныйGit(PID) }
        var данные = Data()
        var EOF = false
        var завершён = false
        var крайОчистки: UInt64?
        var остановка: UInt64?
        var убийствоПослано = false
        var отказ = false
        while true {
            let сейчас = try времяПослеЗапуска()
            guard сейчас >= начало else { throw ОшибкаСвежести.неизвестныйGit(PID) }
            if !завершён {
                var сведения = siginfo_t()
                let ожидание = waitid(P_PID, id_t(PID), &сведения, WEXITED | WNOHANG | WNOWAIT)
                if ожидание == 0 {
                    завершён = сведения.si_pid == PID
                    if завершён && крайОчистки == nil { крайОчистки = сейчас + 1_000_000_000 }
                } else if errno != EINTR { throw ОшибкаСвежести.неизвестныйGit(PID) }
            }
            if let крайОчистки, сейчас >= крайОчистки { throw ОшибкаСвежести.неизвестныйGit(PID) }
            if завершён && EOF { break }
            if сейчас - начало >= 2_000_000_000 || данные.count > 8192 {
                отказ = true
                if остановка == nil {
                    if Darwin.kill(-PID, SIGTERM) != 0 && errno != ESRCH { throw ОшибкаСвежести.неизвестныйGit(PID) }
                    остановка = сейчас
                    if крайОчистки == nil { крайОчистки = сейчас + 1_000_000_000 }
                }
            }
            if let остановка, сейчас - остановка >= 200_000_000, !убийствоПослано {
                if Darwin.kill(-PID, SIGKILL) != 0 && errno != ESRCH { throw ОшибкаСвежести.неизвестныйGit(PID) }
                убийствоПослано = true
            }
            var событие = pollfd(fd: EOF ? -1 : труба[0], events: Int16(POLLIN | POLLHUP), revents: 0)
            let опрос = poll(&событие, 1, 10)
            if опрос < 0 && errno != EINTR { throw ОшибкаСвежести.неизвестныйGit(PID) }
            if !EOF && событие.revents != 0 {
                var буфер = [UInt8](repeating: 0, count: max(1, min(4096, 8193 - данные.count)))
                let размер = буфер.withUnsafeMutableBytes { Darwin.read(труба[0], $0.baseAddress, $0.count) }
                if размер > 0 { данные.append(contentsOf: буфер.prefix(размер)) }
                else if размер == 0 { EOF = true }
                else if errno != EAGAIN && errno != EINTR { throw ОшибкаСвежести.неизвестныйGit(PID) }
            }
        }
        var статус: Int32 = 0
        while true {
            guard let крайОчистки, try времяПослеЗапуска() < крайОчистки else { throw ОшибкаСвежести.неизвестныйGit(PID) }
            let ответ = waitpid(PID, &статус, WNOHANG)
            if ответ == PID { break }
            if ответ < 0 && errno != EINTR { throw ОшибкаСвежести.неизвестныйGit(PID) }
            _ = poll(nil, 0, 1)
        }
        // После reap нет сигналов, кроме read-only signal0.
        errno = 0
        guard Darwin.kill(-PID, 0) == -1 && errno == ESRCH else { throw ОшибкаСвежести.неизвестныйGit(PID) }
        guard !отказ, статус & 0x7f == 0, (статус >> 8) & 0xff == 0 else { throw ОшибкаСвежести.git }
        return ИсходGitСвежести(данные: данные, PID: PID, наносекунды: try времяПослеЗапуска() - начало)
    }
}

enum ЗапросСвежести {
    static func разобрать(_ аргументы: [String], ввод: Data?) throws -> (String, String, Bool) {
        if аргументы == ["--stdin"] || аргументы == ["--stdin", "--проверить"] {
            guard let ввод, ввод.count <= 8192, String(data: ввод, encoding: .utf8) != nil else { throw ОшибкаСвежести.параметры }
            let значения = try плоскийJSON(ввод)
            guard Set(значения.keys) == Set(["корень", "путь"]), let корень = значения["корень"], let путь = значения["путь"] else { throw ОшибкаСвежести.параметры }
            return (корень, путь, аргументы.count == 2)
        }
        guard (аргументы.count == 4 || аргументы.count == 5), аргументы[0] == "--корень",
              аргументы[2] == "--путь", аргументы.count == 4 || аргументы[4] == "--проверить",
              ввод == nil else { throw ОшибкаСвежести.параметры }
        return (аргументы[1], аргументы[3], аргументы.count == 5)
    }

    // Только объект строка→строка; дубликаты и лишние вложенные формы закрыты.
    private static func плоскийJSON(_ данные: Data) throws -> [String: String] {
        let байты = Array(данные)
        var i = 0
        func пробелы() { while i < байты.count && [9, 10, 13, 32].contains(байты[i]) { i += 1 } }
        func строка() throws -> String {
            guard i < байты.count, байты[i] == 34 else { throw ОшибкаСвежести.параметры }
            let начало = i
            i += 1
            var экранирован = false
            while i < байты.count {
                let b = байты[i]
                i += 1
                if экранирован { экранирован = false; continue }
                if b == 92 { экранирован = true; continue }
                if b == 34 { return try JSONDecoder().decode(String.self, from: Data(байты[начало..<i])) }
                guard b >= 32 else { throw ОшибкаСвежести.параметры }
            }
            throw ОшибкаСвежести.параметры
        }
        пробелы()
        guard i < байты.count, байты[i] == 123 else { throw ОшибкаСвежести.параметры }
        i += 1; пробелы()
        var результат: [String: String] = [:]
        while i < байты.count && байты[i] != 125 {
            let ключ = try строка(); пробелы()
            guard результат[ключ] == nil, i < байты.count, байты[i] == 58 else { throw ОшибкаСвежести.параметры }
            i += 1; пробелы()
            результат[ключ] = try строка(); пробелы()
            if i < байты.count && байты[i] == 44 {
                i += 1; пробелы()
                guard i < байты.count, байты[i] != 125 else { throw ОшибкаСвежести.параметры }
            } else { break }
        }
        guard i < байты.count, байты[i] == 125 else { throw ОшибкаСвежести.параметры }
        i += 1; пробелы()
        guard i == байты.count else { throw ОшибкаСвежести.параметры }
        return результат
    }
}

enum ФайлСвежести {
    static func физическийПуть(_ путь: String) throws -> String {
        guard путь.utf8.count <= 4096, путь.hasPrefix("/"), !путь.contains("\0"),
              let адрес = realpath(путь, nil) else { throw ОшибкаСвежести.путь }
        defer { free(адрес) }
        let результат = String(cString: адрес)
        guard результат == путь else { throw ОшибкаСвежести.путь }
        return результат
    }

    static func части(_ путь: String) throws -> [String] {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard путь.utf8.count <= 4096, путь.lowercased().hasSuffix(".md"),
              !путь.contains("\0"), !части.isEmpty,
              !части.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) else { throw ОшибкаСвежести.путь }
        let закрытые = Set([".git", ".build", ".swiftpm", "__pycache__", "node_modules"])
        guard !части.contains(where: { закрытые.contains($0) }), части.first != "Proyekcii",
              путь != "Индексы/markdown-файлы-по-времени-редактирования.md" else { throw ОшибкаСвежести.путь }
        if части.count == 3 && части[0] == "Журнал" && части[2] == "отчёт.md" { throw ОшибкаСвежести.неподдерживаемыйДокумент }
        if части.starts(with: ["Источники", "URL", "https", "chatgpt.com", "share"]) { throw ОшибкаСвежести.неподдерживаемыйДокумент }
        if части.count >= 2 && части[0] == ".obsidian" && ["plugins", "themes", "cache"].contains(части[1]) { throw ОшибкаСвежести.путь }
        return части
    }

    static func родитель(_ корень: Int32, _ части: [String]) throws -> Int32 {
        var д = fcntl(корень, F_DUPFD_CLOEXEC, 0)
        guard д >= 0 else { throw ОшибкаСвежести.вводВывод }
        do {
            for часть in части.dropLast() {
                let следующий = openat(д, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                guard следующий >= 0 else { throw ОшибкаСвежести.путь }
                Darwin.close(д); д = следующий
            }
            return д
        } catch { Darwin.close(д); throw error }
    }

    static func теЖе(_ a: Darwin.stat, _ b: Darwin.stat) -> Bool {
        a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_mode == b.st_mode && a.st_uid == b.st_uid
            && a.st_size == b.st_size && a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec
            && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec && a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec
            && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec
    }

    static func прочитать(_ д: Int32) throws -> (Data, Darwin.stat) {
        var до = Darwin.stat()
        guard fstat(д, &до) == 0 else { throw ОшибкаСвежести.вводВывод }
        guard до.st_mode & S_IFMT == S_IFREG else { throw ОшибкаСвежести.типФайла }
        guard до.st_size >= 0, до.st_size <= СвежестьMarkdown.предел else { throw ОшибкаСвежести.предел }
        var данные = Data()
        while данные.count <= СвежестьMarkdown.предел {
            var буфер = [UInt8](repeating: 0, count: min(16384, СвежестьMarkdown.предел + 1 - данные.count))
            let n = буфер.withUnsafeMutableBytes { Darwin.read(д, $0.baseAddress, $0.count) }
            if n > 0 { данные.append(contentsOf: буфер.prefix(n)) }
            else if n == 0 { break }
            else if errno != EINTR { throw ОшибкаСвежести.вводВывод }
        }
        var после = Darwin.stat()
        guard fstat(д, &после) == 0, теЖе(до, после), данные.count == Int(до.st_size),
              данные.count <= СвежестьMarkdown.предел else { throw ОшибкаСвежести.вводВывод }
        guard String(data: данные, encoding: .utf8) != nil else { throw ОшибкаСвежести.кодировка }
        return (данные, после)
    }

    static func записать(_ данные: Data, корень: String, корневой: Int32, родительский: Int32,
                         части: [String], снимок: Darwin.stat) throws {
        guard данные.count <= СвежестьMarkdown.предел, let имя = части.last else { throw ОшибкаСвежести.предел }
        let временное = ".fum-md-recency-" + UUID().uuidString.lowercased() + ".tmp"
        let д = openat(родительский, временное, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard д >= 0 else { throw ОшибкаСвежести.вводВывод }
        defer { Darwin.close(д) }
        var собственный = Darwin.stat()
        guard fstat(д, &собственный) == 0 else { throw ОшибкаСвежести.неизвестнаяОчистка(временное) }
        var переименован = false
        do {
            var сдвиг = 0
            let крайЗаписи = try монотонноеВремя() + 5_000_000_000
            try данные.withUnsafeBytes { буфер in
                while сдвиг < буфер.count {
                    guard try монотонноеВремя() < крайЗаписи else { throw ОшибкаСвежести.вводВывод }
                    let n = Darwin.write(д, буфер.baseAddress!.advanced(by: сдвиг), буфер.count - сдвиг)
                    if n > 0 { сдвиг += n }
                    else if n == 0 || errno != EINTR { throw ОшибкаСвежести.вводВывод }
                }
            }
            guard fchmod(д, снимок.st_mode & 0o777) == 0, fsync(д) == 0 else { throw ОшибкаСвежести.вводВывод }
            guard try физическийПуть(корень) == корень else { throw ОшибкаСвежести.путь }
            let новыйКорень = Darwin.open(корень, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard новыйКорень >= 0 else { throw ОшибкаСвежести.путь }
            defer { Darwin.close(новыйКорень) }
            var а = Darwin.stat(), б = Darwin.stat()
            guard fstat(корневой, &а) == 0, fstat(новыйКорень, &б) == 0,
                  а.st_dev == б.st_dev, а.st_ino == б.st_ino else { throw ОшибкаСвежести.путь }
            let новыйРодитель = try родитель(новыйКорень, части)
            defer { Darwin.close(новыйРодитель) }
            // Это revalidation перед атомарной заменой, не kernel CAS.
            // Вызывающий владелец удерживает исключительное владение pathname
            // на всём интервале; flock не блокирует внешний несотрудничающий редактор.
            guard fstat(родительский, &а) == 0, fstat(новыйРодитель, &б) == 0,
                  а.st_dev == б.st_dev, а.st_ino == б.st_ino,
                  fstatat(новыйРодитель, имя, &б, AT_SYMLINK_NOFOLLOW) == 0,
                  теЖе(снимок, б) else { throw ОшибкаСвежести.путь }
            guard fstat(д, &а) == 0, а.st_mode & S_IFMT == S_IFREG, а.st_nlink == 1,
                  fstatat(новыйРодитель, временное, &б, AT_SYMLINK_NOFOLLOW) == 0,
                  теЖе(а, б), а.st_dev == собственный.st_dev, а.st_ino == собственный.st_ino else { throw ОшибкаСвежести.путь }
            guard renameat(родительский, временное, родительский, имя) == 0 else { throw ОшибкаСвежести.вводВывод }
            переименован = true
            guard fsync(родительский) == 0 else { throw ОшибкаСвежести.неизвестнаяЗапись }
            let проверка = openat(родительский, имя, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
            guard проверка >= 0 else { throw ОшибкаСвежести.неизвестнаяЗапись }
            defer { Darwin.close(проверка) }
            guard let подтверждение = try? прочитать(проверка), подтверждение.0 == данные else { throw ОшибкаСвежести.неизвестнаяЗапись }
        } catch {
            if !переименован {
                var найден = Darwin.stat()
                if fstatat(родительский, временное, &найден, AT_SYMLINK_NOFOLLOW) == 0 {
                    guard найден.st_dev == собственный.st_dev, найден.st_ino == собственный.st_ino,
                          unlinkat(родительский, временное, 0) == 0 else { throw ОшибкаСвежести.неизвестнаяОчистка(временное) }
                } else if errno != ENOENT {
                    throw ОшибкаСвежести.неизвестнаяОчистка(временное)
                }
            }
            throw error
        }
    }
}

struct ВыходКомандыСвежести {
    let код: Int32
    let JSON: Data
    let записан: Bool
}

enum КомандаСвежести {
    static func выполнить(аргументы: [String], ввод: Data?, сейчас: Date) throws -> ВыходКомандыСвежести {
        let (корень, путь, проверка) = try ЗапросСвежести.разобрать(аргументы, ввод: ввод)
        let физический = try ФайлСвежести.физическийПуть(корень)
        let части = try ФайлСвежести.части(путь)
        let корневой = Darwin.open(физический, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard корневой >= 0 else { throw ОшибкаСвежести.путь }
        defer { Darwin.close(корневой) }
        let родитель = try ФайлСвежести.родитель(корневой, части)
        defer { Darwin.close(родитель) }
        let файл = openat(родитель, части.last!, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаСвежести.путь }
        defer { Darwin.close(файл) }
        guard flock(файл, LOCK_EX | LOCK_NB) == 0 else { throw ОшибкаСвежести.вводВывод }
        defer { flock(файл, LOCK_UN) }
        let (данные, снимок) = try ФайлСвежести.прочитать(файл)
        let git = try GitСвежести.выполнить(корень: физический, аргументы: ["ls-files", "--stage", "-z", "--", путь])
        guard let запись = String(data: git.данные, encoding: .utf8), запись.hasSuffix("\0") else { throw ОшибкаСвежести.git }
        let записи = запись.split(separator: "\0", omittingEmptySubsequences: true)
        guard записи.count == 1 else { throw ОшибкаСвежести.git }
        let поля = записи[0].split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        guard поля.count == 2, String(поля[1]) == путь else { throw ОшибкаСвежести.git }
        let метаданные = поля[0].split(separator: " ")
        guard метаданные.count == 3, ["100644", "100755"].contains(String(метаданные[0])), метаданные[2] == "0" else { throw ОшибкаСвежести.git }
        let результат = try СвежестьMarkdown.обновить(данные, сейчас: сейчас)
        let код: Int32 = проверка && результат.изменено ? 1 : 0
        let объект: [String: Any] = [
            "схема": "fum.свежесть-одного-markdown.1", "код": код, "путь": путь,
            "режим": проверка ? "проверить" : "обновить", "изменение_требуется": результат.изменено,
            "записан": результат.изменено && !проверка, "хэш_содержания": результат.хэш,
            "время": результат.время, "вход_байты": данные.count, "выход_байты": результат.данные.count,
            "вход_sha256": СвежестьMarkdown.хэш(данные), "выход_sha256": СвежестьMarkdown.хэш(результат.данные),
            "Git_PID": git.PID, "Git_PGID": git.PID, "Git_наносекунды": git.наносекунды,
            "Git_вызовы": 1, "Git_группа_закрыта": true, "полномочия": "предоставляет вызывающий владелец W"
        ]
        var JSON = try JSONSerialization.data(withJSONObject: объект, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        JSON.append(10)
        guard JSON.count <= 16384 else { throw ОшибкаСвежести.предел }
        if результат.изменено && !проверка {
            try ФайлСвежести.записать(результат.данные, корень: физический, корневой: корневой,
                                     родительский: родитель, части: части, снимок: снимок)
        }
        return ВыходКомандыСвежести(код: код, JSON: JSON, записан: результат.изменено && !проверка)
    }

    static func вводСтандартный() throws -> Data {
        let флаги = fcntl(STDIN_FILENO, F_GETFL)
        guard флаги >= 0, fcntl(STDIN_FILENO, F_SETFL, флаги | O_NONBLOCK) == 0 else { throw ОшибкаСвежести.вводВывод }
        defer { _ = fcntl(STDIN_FILENO, F_SETFL, флаги) }
        let край = try монотонноеВремя() + 5_000_000_000
        var данные = Data()
        while try монотонноеВремя() < край {
            var событие = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
            let ответ = poll(&событие, 1, 10)
            if ответ < 0 { if errno == EINTR { continue }; throw ОшибкаСвежести.вводВывод }
            if событие.revents != 0 {
                var буфер = [UInt8](repeating: 0, count: max(1, min(4096, 8193 - данные.count)))
                let n = буфер.withUnsafeMutableBytes { Darwin.read(STDIN_FILENO, $0.baseAddress, $0.count) }
                if n > 0 { данные.append(contentsOf: буфер.prefix(n)) }
                else if n == 0 { return данные }
                else if errno != EAGAIN && errno != EINTR { throw ОшибкаСвежести.вводВывод }
                guard данные.count <= 8192 else { throw ОшибкаСвежести.предел }
            }
        }
        throw ОшибкаСвежести.предел
    }
}

#if FUM_RECENCY_CLI
@main
struct ОбновитьСвежестьMarkdown {
    static func main() {
        var записьБыла = false
        do {
            let аргументы = Array(CommandLine.arguments.dropFirst())
            let ввод = аргументы.first == "--stdin" ? try КомандаСвежести.вводСтандартный() : nil
            let результат = try КомандаСвежести.выполнить(аргументы: аргументы, ввод: ввод, сейчас: Date())
            записьБыла = результат.записан
            try FileHandle.standardOutput.write(contentsOf: результат.JSON)
            exit(результат.код)
        } catch {
            let код: Int32 = записьБыла || (error as? ОшибкаСвежести)?.неизвестно == true ? 3 : 2
            let объект: [String: Any] = ["схема": "fum.свежесть-одного-markdown.1", "код": код,
                "состояние": код == 3 ? "неизвестный-эффект" : "отказ",
                "причина": String(describing: error)]
            if var JSON = try? JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys]), JSON.count < 16384 {
                JSON.append(10)
                try? FileHandle.standardOutput.write(contentsOf: JSON)
            }
            exit(код)
        }
    }
}
#endif
