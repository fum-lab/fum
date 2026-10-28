import Foundation
import Darwin
import CryptoKit

struct ПробелСвежестиИндекса: Codable, Equatable {
    var путь: String
    var родитель: String
    var объект: String
    var sha256: String
    var коммит: String
    var дата: String
}

struct ВходВосстановленияИндекса: Codable, Equatable {
    var корень: String
    var ветка: String
    var коммит: String
    var слияние: String
    var индекс_sha256: String
    var конфликт_sha256: String
    var время: String
    var пробел: ПробелСвежестиИндекса
}

struct ФайлВосстановленияИндекса: Codable, Equatable {
    var путь: String
    var sha256: String
}

struct ПланВосстановленияИндекса: Codable, Equatable {
    var схема = "fum.восстановление-производного-md-индекса.1"
    var вход: ВходВосстановленияИндекса
    var файлы: [ФайлВосстановленияИндекса]
    var стадии: Data
    var результат: Data
    var унаследованный_пробел: ПробелСвежестиИндекса
    var общая_свежесть = "не-пройдена"
}

struct МеткаХодаИндекса: Codable {
    var попытка: String
    var процесс: Int32
    var начало_процесса_монотонно_нс: String
    var монотонно_нс: String
    var длительность_нс: UInt64
    var фаза: String
    var состояние: String
    var план_sha256: String
    var исполнитель_sha256: String
    var корень_кода: String
    var исходники_sha256: [String: String]
}

struct РазрешениеРемонтаИндекса: Codable {
    var допуск_файл: String
    var допуск_sha256: String
    var предыдущий_каталог: String
    var предыдущий_терминал_файл: String
    var предыдущий_терминал_sha256: String
    var предыдущий_намерение_sha256: String
    var предыдущий_исход_процесса_файл: String
    var предыдущий_исход_процесса_sha256: String
    var план_sha256: String
    var исполнитель_sha256: String
    var исходники_sha256: [String: String]
    var предыдущий_процесс: Int32
    var предыдущий_исполнитель: String
    var предыдущий_исполнитель_sha256: String
}

struct НамерениеВосстановленияИндекса: Codable {
    var план_sha256: String
    var временный_файл: String
    var попытка: String
    var исполнитель_sha256: String
    var корень_кода: String
    var исходники_sha256: [String: String]
    var связь_ремонта_sha256: String?
}

final class ХодВосстановленияИндекса {
    let каталог: URL
    let попытка = UUID().uuidString
    let начало = DispatchTime.now().uptimeNanoseconds
    let план: String
    let исполнитель: String
    let кореньКода: String
    let исходники: [String: String]
    private var номер = 0
    private let бюджет: UInt64

    init(каталог: URL, план: String, бюджетСекунд: UInt64 = 330) throws {
        guard бюджетСекунд > 0, бюджетСекунд <= 360 else { throw ОтказИндексаMarkdown.вход("бюджет-1-360-секунд") }
        self.каталог = каталог; self.план = план; бюджет = бюджетСекунд * 1_000_000_000
        исполнитель = ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[0])))
        let код = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        кореньКода = код.path
        guard код.resolvingSymlinksInPath().path == код.path else { throw ОтказИндексаMarkdown.вход("нефизический-корень-кода") }
        var найденные: [String: String] = [:]
        for имя in ["indeks-markdown.swift", "vosstanovleniye-indeksa.swift", "kontrolj-vosstanovleniya.swift"] {
            let путь = "iskhodniki/aktualizaciya-putej/" + имя
            найденные[путь] = ИндексMarkdownСлияния.хэш(try ВосстановлениеИндексаMarkdown.прочитать(код.path, путь))
        }
        исходники = найденные
    }

    func проверитьБюджет() throws {
        guard DispatchTime.now().uptimeNanoseconds - начало < бюджет else { throw ОтказИндексаMarkdown.вход("исчерпан-бюджет-до-новой-фазы") }
    }

    func отметить(_ фаза: String, _ состояние: String, длительность: UInt64 = 0) throws {
        номер += 1
        let метка = МеткаХодаИндекса(попытка: попытка, процесс: getpid(), начало_процесса_монотонно_нс: String(начало),
            монотонно_нс: String(DispatchTime.now().uptimeNanoseconds), длительность_нс: длительность,
            фаза: фаза, состояние: состояние, план_sha256: план, исполнитель_sha256: исполнитель, корень_кода: кореньКода, исходники_sha256: исходники)
        let имя = String(format: "%03d", номер) + "-" + фаза + "-" + состояние + ".json"
        try ВосстановлениеИндексаMarkdown.сохранитьКвитанцию(каталог.appendingPathComponent(имя), байты: ВосстановлениеИндексаMarkdown.кодировать(метка))
        try FileHandle.standardError.write(contentsOf: Data("индекс: \(фаза): \(состояние); \(длительность / 1_000_000)мс\n".utf8))
    }

    func фаза<T>(_ имя: String, _ действие: () throws -> T) throws -> T {
        try проверитьБюджет(); let началоФазы = DispatchTime.now().uptimeNanoseconds
        try отметить(имя, "начало")
        do {
            let результат = try действие()
            try отметить(имя, "успех", длительность: DispatchTime.now().uptimeNanoseconds - началоФазы)
            return результат
        } catch {
            try? отметить(имя, "отказ", длительность: DispatchTime.now().uptimeNanoseconds - началоФазы)
            throw error
        }
    }

    func завершить(_ классификация: String) throws {
        try отметить("терминал", классификация)
        try ВосстановлениеИндексаMarkdown.сохранитьКвитанцию(каталог.appendingPathComponent("terminal.json"),
            байты: ВосстановлениеИндексаMarkdown.кодировать([
                "классификация": классификация, "попытка": попытка, "план_sha256": план,
                "исполнитель_sha256": исполнитель, "монотонная_эпоха": String(начало)
            ]))
    }
}

// Адресный адаптер восстановления производного индекса при незавершённом merge.
// Не меняет исходные Markdown, Git-index или refs и не заменяет общий recency gate.
enum ВосстановлениеИндексаMarkdown {
    static func гит(_ корень: String, _ аргументы: [String]) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["--no-optional-locks", "--no-replace-objects", "--literal-pathspecs", "-c", "core.fsmonitor=false", "-C", корень] + аргументы
        var среда = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        среда["GIT_OPTIONAL_LOCKS"] = "0"
        среда["GIT_NO_LAZY_FETCH"] = "1"
        процесс.environment = среда
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.standardError
        try процесс.run()
        let байты = try канал.fileHandleForReading.readToEnd() ?? Data()
        процесс.waitUntilExit()
        guard процесс.terminationReason == .exit, процесс.terminationStatus == 0 else {
            throw ОтказИндексаMarkdown.вход("Git-отказ: " + (аргументы.first ?? ""))
        }
        return байты
    }

    static func строкаГит(_ корень: String, _ аргументы: [String]) throws -> String {
        guard let строка = String(data: try гит(корень, аргументы), encoding: .utf8) else {
            throw ОтказИндексаMarkdown.вход("не-UTF8-Git")
        }
        return строка.trimmingCharacters(in: .newlines)
    }

    static func открытьКаталог(_ корень: String, _ путь: String) throws -> Int32 {
        guard URL(fileURLWithPath: корень).resolvingSymlinksInPath().path == корень else {
            throw ОтказИндексаMarkdown.вход("нефизический-корень")
        }
        var дескриптор = open(корень, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard дескриптор >= 0 else { throw ОтказИндексаMarkdown.вход("нет-корня") }
        do {
            if !путь.isEmpty {
                for часть in путь.split(separator: "/", omittingEmptySubsequences: false) {
                    guard !часть.isEmpty, часть != ".", часть != ".." else { throw ОтказИндексаMarkdown.вход("небезопасный-путь") }
                    let следующий = openat(дескриптор, String(часть), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                    guard следующий >= 0 else { throw ОтказИндексаMarkdown.вход("не-обычный-каталог") }
                    close(дескриптор); дескриптор = следующий
                }
            }
            return дескриптор
        } catch { close(дескриптор); throw error }
    }

    static func прочитать(_ корень: String, _ путь: String) throws -> Data {
        let родитель = try открытьКаталог(корень, (путь as NSString).deletingLastPathComponent)
        defer { close(родитель) }
        let файл = openat(родитель, (путь as NSString).lastPathComponent, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОтказИндексаMarkdown.вход("не-обычный-файл: " + путь) }
        defer { close(файл) }
        var до = stat(), после = stat()
        guard fstat(файл, &до) == 0, до.st_mode & S_IFMT == S_IFREG, до.st_nlink == 1,
              до.st_uid == getuid(), до.st_size <= 67_108_864 else { throw ОтказИндексаMarkdown.вход("тип-режим-размер") }
        let байты = try FileHandle(fileDescriptor: файл, closeOnDealloc: false).readToEnd() ?? Data()
        guard fstat(файл, &после) == 0, до.st_dev == после.st_dev, до.st_ino == после.st_ino,
              до.st_size == после.st_size, байты.count == до.st_size,
              до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec, до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec, до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec else {
            throw ОтказИндексаMarkdown.вход("дрейф-чтения")
        }
        return байты
    }

    static func инвентарь(_ корень: String) throws -> [String] {
        let байты = try гит(корень, ["ls-files", "--cached", "--others", "--exclude-standard", "-z"])
        let исключённые: Set<String> = [".git", ".build", ".swiftpm", ".cache", "cache", "caches", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"]
        var пути: [Data: String] = [:]
        for элемент in байты.split(separator: 0) {
            guard let путь = String(data: элемент, encoding: .utf8) else { throw ОтказИндексаMarkdown.вход("не-UTF8-путь") }
            guard (путь as NSString).pathExtension == "md" else { continue }
            let части = путь.split(separator: "/").dropLast().map(String.init)
            if части.first == "Proyekcii" { continue }
            let нижние = части.map { $0.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX")) }
            if нижние.contains(where: { исключённые.contains($0) || ["-cache", "_cache", ".cache"].contains(where: $0.hasSuffix) }) { continue }
            if нижние.count >= 2, нижние[0] == ".obsidian", ["plugins", "themes"].contains(нижние[1]) { continue }
            пути[Data(путь.utf8)] = путь
        }
        return пути.keys.sorted { $0.lexicographicallyPrecedes($1) }.map { пути[$0]! }
    }

    static func времяДокумента(_ байты: Data, путь: String, формат: DateFormatter? = nil) throws -> String? {
        guard let исходный = String(data: байты, encoding: .utf8) else { throw ОтказИндексаMarkdown.вход("не-UTF8-MD") }
        let текст = исходный.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let маска = try маскироватьЦитаты(текст, путь: путь)
        guard let метка = try ИндексMarkdownСлияния.метаданные(Data(текст.utf8), маска: маска, формат: формат) else {
            guard !маска.contains("FUM-MD-RECENCY:BEGIN"), !маска.contains("FUM-MD-RECENCY:END") else { throw ОтказИндексаMarkdown.вход("повреждённая-метка") }
            return nil
        }
        var допустимые = [ИндексMarkdownСлияния.хэш(Data(метка.содержание.utf8))]
        let части = путь.split(separator: "/")
        if части.count == 3, части[0] == "Журнал", части[2] == "отчёт.md" {
            let начал = метка.содержание.components(separatedBy: "<!-- FUM-CHECK-RUNS:BEGIN ").count - 1
            let концов = метка.содержание.components(separatedBy: "<!-- FUM-CHECK-RUNS:END -->").count - 1
            if начал != 0 || концов != 0 {
                let выражение = try NSRegularExpression(pattern: #"(?ms)^<!-- FUM-CHECK-RUNS:BEGIN (?:состояние=открыт; каталог=материалы/запуски-проверок|состояние=закрыт; снимок=материалы/запуски-проверок/снимок\.json; sha256=sha256:[0-9a-f]{64}) -->\n.*?\n<!-- FUM-CHECK-RUNS:END -->$"#)
                let совпадения = выражение.matches(in: метка.содержание, range: NSRange(метка.содержание.startIndex..., in: метка.содержание))
                guard начал == 1, концов == 1, совпадения.count == 1 else { throw ОтказИндексаMarkdown.вход("повреждённый-блок-проверок") }
                let стабильное = выражение.stringByReplacingMatches(in: метка.содержание, range: NSRange(метка.содержание.startIndex..., in: метка.содержание), withTemplate: "<!-- FUM-CHECK-RUNS:MANAGED -->")
                допустимые.append(ИндексMarkdownСлияния.хэш(Data(стабильное.utf8)))
            }
        }
        guard допустимые.contains(метка.sha256) else { throw ОтказИндексаMarkdown.вход("устаревшая-метка: " + путь) }
        return метка.время
    }

    static func построить(_ вход: ВходВосстановленияИндекса) throws -> ПланВосстановленияИндекса {
        guard try строкаГит(вход.корень, ["rev-parse", "HEAD"]) == вход.коммит,
              try строкаГит(вход.корень, ["symbolic-ref", "HEAD"]) == вход.ветка,
              try строкаГит(вход.корень, ["rev-parse", "--verify", "MERGE_HEAD"]) == вход.слияние else {
            throw ОтказИндексаMarkdown.вход("дрейф-привязки")
        }
        let стадии = try гит(вход.корень, ["ls-files", "--stage", "-z"])
        guard ИндексMarkdownСлияния.хэш(стадии) == вход.индекс_sha256 else { throw ОтказИндексаMarkdown.вход("дрейф-индекса") }
        let прежний = try прочитать(вход.корень, ИндексMarkdownСлияния.путь)
        guard ИндексMarkdownСлияния.хэш(прежний) == вход.конфликт_sha256 else { throw ОтказИндексаMarkdown.вход("дрейф-конфликта") }
        let пробел = вход.пробел
        guard пробел.родитель == вход.слияние,
              try строкаГит(вход.корень, ["rev-parse", пробел.родитель + ":" + пробел.путь]) == пробел.объект,
              try строкаГит(вход.корень, ["log", "-1", "--format=%H", пробел.родитель, "--", пробел.путь]) == пробел.коммит,
              try строкаГит(вход.корень, ["log", "-1", "--format=%cI", пробел.родитель, "--", пробел.путь]) == пробел.дата else {
            throw ОтказИндексаMarkdown.вход("не-подтверждён-пробел")
        }
        let формат = ISO8601DateFormatter()
        guard let дата = формат.date(from: пробел.дата) else { throw ОтказИндексаMarkdown.вход("дата-происхождения") }
        let московский = DateFormatter(); московский.locale = Locale(identifier: "en_US_POSIX")
        московский.timeZone = TimeZone(identifier: "Europe/Moscow"); московский.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"
        var файлы: [ФайлВосстановленияИндекса] = [], строки: [СтрокаИндексаMarkdown] = []
        let форматМетки = ИндексMarkdownСлияния.форматВремени()
        var найденПробел = false
        for путь in try инвентарь(вход.корень) where путь != ИндексMarkdownСлияния.путь {
            let байты = try прочитать(вход.корень, путь)
            файлы.append(ФайлВосстановленияИндекса(путь: путь, sha256: ИндексMarkdownСлияния.хэш(байты)))
            if let время = try времяДокумента(байты, путь: путь, формат: форматМетки) { строки.append(.init(путь: путь, время: время)) }
            else {
                var объект = Data("blob \(байты.count)\0".utf8); объект.append(байты)
                let хэш = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
                guard путь == пробел.путь, хэш == пробел.объект,
                      ИндексMarkdownСлияния.хэш(байты) == пробел.sha256, !найденПробел else { throw ОтказИндексаMarkdown.вход("неразрешённая-отсутствующая-метка: " + путь) }
                найденПробел = true
                строки.append(.init(путь: путь, время: московский.string(from: дата)))
            }
        }
        guard найденПробел else { throw ОтказИндексаMarkdown.вход("пробел-исчез-или-изменён") }
        return ПланВосстановленияИндекса(вход: вход, файлы: файлы, стадии: стадии,
            результат: try ИндексMarkdownСлияния.построить(строки, время: вход.время), унаследованный_пробел: пробел)
    }

    static func применить(_ план: ПланВосстановленияИндекса, каталогКвитанции: URL,
                          передЗаменой: (() throws -> Void)? = nil) throws {
        try сверитьКаталогКвитанций(каталогКвитанции, корень: план.вход.корень)
        guard !FileManager.default.fileExists(atPath: каталогКвитанции.appendingPathComponent("apply-intent.json").path) else {
            throw ОтказИндексаMarkdown.вход("намерение-уже-существует-проверь-исход-без-повтора")
        }
        let ход = try ХодВосстановленияИндекса(каталог: каталогКвитанции, план: ИндексMarkdownСлияния.хэш(кодировать(план)))
        do {
            try выполнитьПрименение(план, каталогКвитанции: каталогКвитанции, ход: ход, передЗаменой: передЗаменой)
            try ход.завершить("выполнено")
        } catch {
            let безЭффекта = (try? сверитьИсходноеСостояние(план)) ?? false
            try? ход.завершить(безЭффекта ? "нет-целевого-эффекта" : "неизвестно")
            throw error
        }
    }

    static func сверитьКаталогКвитанций(_ каталогКвитанции: URL, корень: String) throws {
        let приватный = каталогКвитанции.path
        guard !приватный.hasPrefix(корень + "/"), приватный != корень,
              каталогКвитанции.resolvingSymlinksInPath().path == приватный else { throw ОтказИндексаMarkdown.вход("квитанции-вне-checkout") }
        var каталогСостояние = stat()
        guard lstat(приватный, &каталогСостояние) == 0, каталогСостояние.st_mode & S_IFMT == S_IFDIR,
              каталогСостояние.st_mode & 0o777 == 0o700, каталогСостояние.st_uid == getuid() else {
            throw ОтказИндексаMarkdown.вход("квитанции-требуют-своего-приватного-0700")
        }
        var предок = каталогКвитанции
        while true {
            guard !FileManager.default.fileExists(atPath: предок.appendingPathComponent(".git").path) else { throw ОтказИндексаMarkdown.вход("квитанции-в-Git") }
            if предок.path == "/" { break }; предок.deleteLastPathComponent()
        }
    }

    private static func выполнитьПрименение(_ план: ПланВосстановленияИндекса, каталогКвитанции: URL,
        ход: ХодВосстановленияИндекса, передЗаменой: (() throws -> Void)?) throws {
        guard try ход.фаза("сверка-1-полный-план", { try построить(план.вход) == план }) else { throw ОтказИндексаMarkdown.вход("дрейф-плана") }
        let родитель = try открытьКаталог(план.вход.корень, "Индексы")
        defer { close(родитель) }
        func сверитьРодителя() throws {
            let текущий = try открытьКаталог(план.вход.корень, "Индексы")
            defer { close(текущий) }
            var старый = stat(), новый = stat()
            guard fstat(родитель, &старый) == 0, fstat(текущий, &новый) == 0,
                  старый.st_dev == новый.st_dev, старый.st_ino == новый.st_ino else { throw ОтказИндексаMarkdown.вход("дрейф-каталога-индекса") }
        }
        let имя = (ИндексMarkdownСлияния.путь as NSString).lastPathComponent
        var исходноеСостояние = stat()
        guard fstatat(родитель, имя, &исходноеСостояние, AT_SYMLINK_NOFOLLOW) == 0,
              исходноеСостояние.st_mode & S_IFMT == S_IFREG else { throw ОтказИндексаMarkdown.вход("не-обычный-индекс") }
        let временное = ".fum-md-index-" + UUID().uuidString
        let намерение = каталогКвитанции.appendingPathComponent("apply-intent.json")
        let связь = каталогКвитанции.appendingPathComponent("repair-link.json")
        let хэшСвязи = FileManager.default.fileExists(atPath: связь.path) ? ИндексMarkdownСлияния.хэш(try прочитать(каталогКвитанции.path, связь.lastPathComponent)) : nil
        try сохранитьКвитанцию(намерение, байты: кодировать(НамерениеВосстановленияИндекса(
            план_sha256: ход.план, временный_файл: временное, попытка: ход.попытка,
            исполнитель_sha256: ход.исполнитель, корень_кода: ход.кореньКода, исходники_sha256: ход.исходники, связь_ремонта_sha256: хэшСвязи)))
        let началоПодготовки = DispatchTime.now().uptimeNanoseconds
        try ход.отметить("подготовка-индекса", "начало")
        let файл = openat(родитель, временное, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o644)
        guard файл >= 0 else { throw ОтказИндексаMarkdown.вход("не-создан-временный") }
        defer { close(файл) } // Намерение и собственный temp сохраняются при терминальном отказе.
        try план.результат.withUnsafeBytes { байты in
            var смещение = 0
            while смещение < байты.count {
                let записано = write(файл, байты.baseAddress!.advanced(by: смещение), байты.count - смещение)
                if записано < 0, errno == EINTR { continue }
                guard записано > 0 else { throw ОтказИндексаMarkdown.вход("неполная-запись") }
                смещение += записано
            }
        }
        guard fchmod(файл, исходноеСостояние.st_mode & 0o7777) == 0,
              fsync(файл) == 0 else { throw ОтказИндексаMarkdown.вход("не-сохранён-временный-индекс") }
        try ход.отметить("подготовка-индекса", "успех", длительность: DispatchTime.now().uptimeNanoseconds - началоПодготовки)
        guard try ход.фаза("сверка-2-полный-план", { try построить(план.вход) == план }) else { throw ОтказИндексаMarkdown.вход("дрейф-перед-эффектом") }
        var передЗаписью = stat()
        guard fstatat(родитель, имя, &передЗаписью, AT_SYMLINK_NOFOLLOW) == 0,
              передЗаписью.st_dev == исходноеСостояние.st_dev, передЗаписью.st_ino == исходноеСостояние.st_ino,
              try ход.фаза("сверка-3-полный-план", { try построить(план.вход) == план }) else { throw ОтказИндексаMarkdown.вход("дрейф-после-намерения") }
        try сверитьРодителя()
        try ход.отметить("граница-до-rename", "достигнута")
        try передЗаменой?()
        try ход.проверитьБюджет()
        guard try сверитьИсходноеСостояние(план) else { throw ОтказИндексаMarkdown.вход("дрейф-на-границе-эффекта") }
        try сверитьРодителя()
        try ход.проверитьБюджет()
        let началоЗамены = DispatchTime.now().uptimeNanoseconds
        try ход.отметить("целевая-замена", "начало")
        guard renameat(родитель, временное, родитель, имя) == 0 else { throw ОтказИндексаMarkdown.вход("не-выполнен-rename") }
        try ход.отметить("целевая-замена", "успех", длительность: DispatchTime.now().uptimeNanoseconds - началоЗамены)
        let началоСверки = DispatchTime.now().uptimeNanoseconds
        try ход.отметить("сверка-результата", "начало")
        try сверитьРодителя()
        guard fsync(родитель) == 0, try прочитать(план.вход.корень, ИндексMarkdownСлияния.путь) == план.результат,
              try гит(план.вход.корень, ["ls-files", "--stage", "-z"]) == план.стадии else { throw ОтказИндексаMarkdown.вход("исход-требует-readback") }
        for файл in план.файлы {
            guard ИндексMarkdownСлияния.хэш(try прочитать(план.вход.корень, файл.путь)) == файл.sha256 else { throw ОтказИндексаMarkdown.вход("дрейф-исходного-MD") }
        }
        guard try инвентарь(план.вход.корень) == (план.файлы.map(\.путь) + [ИндексMarkdownСлияния.путь]).sorted(by: { $0.utf8.lexicographicallyPrecedes($1.utf8) }),
              try строкаГит(план.вход.корень, ["rev-parse", "HEAD"]) == план.вход.коммит,
              try строкаГит(план.вход.корень, ["symbolic-ref", "HEAD"]) == план.вход.ветка,
              try строкаГит(план.вход.корень, ["rev-parse", "MERGE_HEAD"]) == план.вход.слияние else { throw ОтказИндексаMarkdown.вход("дрейф-заключительной-привязки") }
        try сохранитьКвитанцию(каталогКвитанции.appendingPathComponent("apply-outcome.json"),
            байты: кодировать(["исход": "индекс-восстановлен", "общая_свежесть": "не-пройдена"]))
        try ход.отметить("сверка-результата", "успех", длительность: DispatchTime.now().uptimeNanoseconds - началоСверки)
    }

    static func сверитьИсходноеСостояние(_ план: ПланВосстановленияИндекса) throws -> Bool {
        guard try строкаГит(план.вход.корень, ["rev-parse", "HEAD"]) == план.вход.коммит,
              try строкаГит(план.вход.корень, ["symbolic-ref", "HEAD"]) == план.вход.ветка,
              try строкаГит(план.вход.корень, ["rev-parse", "MERGE_HEAD"]) == план.вход.слияние,
              try гит(план.вход.корень, ["ls-files", "--stage", "-z"]) == план.стадии,
              ИндексMarkdownСлияния.хэш(try прочитать(план.вход.корень, ИндексMarkdownСлияния.путь)) == план.вход.конфликт_sha256,
              try инвентарь(план.вход.корень) == (план.файлы.map(\.путь) + [ИндексMarkdownСлияния.путь]).sorted(by: { $0.utf8.lexicographicallyPrecedes($1.utf8) }) else { return false }
        for файл in план.файлы {
            guard ИндексMarkdownСлияния.хэш(try прочитать(план.вход.корень, файл.путь)) == файл.sha256 else { return false }
        }
        return true
    }

    static func ремонт(_ план: ПланВосстановленияИндекса, разрешение: РазрешениеРемонтаИндекса,
                       каталогКвитанции: URL) throws {
        try сверитьКаталогКвитанций(каталогКвитанции, корень: план.вход.корень)
        let старый = URL(fileURLWithPath: разрешение.предыдущий_каталог)
        guard старый.resolvingSymlinksInPath().path == старый.path,
              !старый.path.hasPrefix(план.вход.корень + "/"), старый.path != каталогКвитанции.path,
              разрешение.план_sha256 == ИндексMarkdownСлияния.хэш(try кодировать(план)),
              разрешение.исполнитель_sha256 == ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[0]))),
              !разрешение.исходники_sha256.isEmpty else { throw ОтказИндексаMarkdown.вход("неверная-привязка-ремонта") }
        for (путь, хэш) in разрешение.исходники_sha256 {
            guard ИндексMarkdownСлияния.хэш(try прочитать(план.вход.корень, путь)) == хэш else { throw ОтказИндексаMarkdown.вход("дрейф-кода-ремонта") }
        }
        func старыйФайл(_ имя: String, _ хэш: String) throws -> Data {
            guard !имя.isEmpty, (имя as NSString).lastPathComponent == имя else { throw ОтказИндексаMarkdown.вход("неверное-имя-доказательства") }
            let байты = try прочитать(старый.path, имя)
            guard ИндексMarkdownСлияния.хэш(байты) == хэш else { throw ОтказИндексаMarkdown.вход("дрейф-доказательства-ремонта") }
            return байты
        }
        let терминал = try разобратьОбъект(старыйФайл(разрешение.предыдущий_терминал_файл, разрешение.предыдущий_терминал_sha256))
        let процесс = try разобратьОбъект(старыйФайл(разрешение.предыдущий_исход_процесса_файл, разрешение.предыдущий_исход_процесса_sha256))
        let timeout = процесс["signal"] as? String == "SIGTERM" && (процесс["error"] as? String)?.contains("ETIMEDOUT") == true
        let остановка = процесс["status"] as? Int == 2 && процесс["reason"] as? String == "exit" && процесс["pid"] as? Int32 == разрешение.предыдущий_процесс
        guard timeout || остановка,
              (терминал["pid_\(разрешение.предыдущий_процесс)_present"] as? Bool == false || остановка),
              процесс["status"] is NSNull || остановка else { throw ОтказИндексаMarkdown.вход("не-терминальный-исход-прежнего-процесса") }
        let отсутствие = try сверитьОтсутствиеПроизводителя(разрешение)
        try сохранитьКвитанцию(каталогКвитанции.appendingPathComponent("no-old-producer-before-claim.json"), байты: кодировать(отсутствие))
        guard терминал["классификация"] as? String == "нет-целевого-эффекта"
                || терминал["classification"] as? String == "terminated-no-target-effect-readback-confirmed",
              !FileManager.default.fileExists(atPath: старый.appendingPathComponent("apply-outcome.json").path) else { throw ОтказИндексаMarkdown.вход("прежний-исход-не-доказывает-no-effect") }
        let намерение = try разобратьОбъект(старыйФайл("apply-intent.json", разрешение.предыдущий_намерение_sha256))
        guard намерение["план_sha256"] as? String == разрешение.план_sha256,
              let временное = намерение["временный_файл"] as? String,
              временное.hasPrefix(".fum-md-index-"), (временное as NSString).lastPathComponent == временное,
              try прочитать(план.вход.корень, "Индексы/" + временное) == план.результат,
              try сверитьИсходноеСостояние(план) else { throw ОтказИндексаMarkdown.вход("не-подтверждено-no-effect-сейчас") }
        let адресДопуска = URL(fileURLWithPath: разрешение.допуск_файл)
        guard адресДопуска.resolvingSymlinksInPath().path == адресДопуска.path,
              !адресДопуска.path.hasPrefix(план.вход.корень + "/") else { throw ОтказИндексаMarkdown.вход("допуск-вне-checkout") }
        let байтыДопуска = try прочитать(адресДопуска.deletingLastPathComponent().path, адресДопуска.lastPathComponent)
        let допуск = try разобратьОбъект(байтыДопуска)
        guard ИндексMarkdownСлияния.хэш(байтыДопуска) == разрешение.допуск_sha256,
              допуск["разрешено_новых_производственных_попыток"] as? Int == 1 else { throw ОтказИндексаMarkdown.вход("нет-точного-допуска-на-одну-попытку") }
        // Один durable claim на независимо выбранный ROOT-допуск. Новый каталог не обходит его.
        try сохранитьКвитанцию(адресДопуска.deletingLastPathComponent().appendingPathComponent("one-effect-claim.json"),
            байты: кодировать(разрешение))
        try сохранитьКвитанцию(каталогКвитанции.appendingPathComponent("repair-link.json"), байты: кодировать(разрешение))
        try применить(план, каталогКвитанции: каталогКвитанции, передЗаменой: {
            let отсутствие = try сверитьОтсутствиеПроизводителя(разрешение)
            try сохранитьКвитанцию(каталогКвитанции.appendingPathComponent("no-old-producer-before-rename.json"), байты: кодировать(отсутствие))
        })
    }

    @discardableResult
    static func сверитьОтсутствиеПроизводителя(_ разрешение: РазрешениеРемонтаИндекса) throws -> [String: String] {
        guard разрешение.предыдущий_процесс > 1, разрешение.предыдущий_процесс != getpid(),
              kill(разрешение.предыдущий_процесс, 0) == -1, errno == ESRCH,
              ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: разрешение.предыдущий_исполнитель))) == разрешение.предыдущий_исполнитель_sha256 else {
            throw ОтказИндексаMarkdown.вход("старый-процесс-жив-или-не-проверен")
        }
        let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: "/bin/ps")
        процесс.arguments = ["-axo", "pid=,command="]
        let канал = Pipe(); процесс.standardOutput = канал; процесс.standardError = FileHandle.standardError
        try процесс.run(); let байты = канал.fileHandleForReading.readDataToEndOfFile(); процесс.waitUntilExit()
        guard процесс.terminationStatus == 0, let текст = String(data: байты, encoding: .utf8) else { throw ОтказИндексаMarkdown.вход("не-проверены-старые-производители") }
        for строка in текст.split(separator: "\n") {
            let части = строка.trimmingCharacters(in: .whitespaces).split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" })
            guard части.count == 2 else { continue }
            if String(части[1]).hasPrefix(разрешение.предыдущий_исполнитель + " применить ") { throw ОтказИндексаMarkdown.вход("обнаружен-старый-производитель") }
        }
        return ["прежний_процесс": String(разрешение.предыдущий_процесс), "проверка_PID": "ESRCH",
            "прежний_исполнитель": разрешение.предыдущий_исполнитель,
            "прежний_исполнитель_sha256": разрешение.предыдущий_исполнитель_sha256,
            "старые_производители_по_ps": "отсутствуют", "монотонно_нс": String(DispatchTime.now().uptimeNanoseconds)]
    }

    private static func разобратьОбъект(_ байты: Data) throws -> [String: Any] {
        guard let объект = try JSONSerialization.jsonObject(with: байты) as? [String: Any] else { throw ОтказИндексаMarkdown.вход("не-JSON-объект-доказательства") }
        return объект
    }

    static func сохранитьКвитанцию(_ адрес: URL, байты: Data) throws {
        let родитель = try открытьКаталог(адрес.deletingLastPathComponent().path, "")
        defer { close(родитель) }
        let файл = openat(родитель, адрес.lastPathComponent, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard файл >= 0 else { throw ОтказИндексаMarkdown.вход("квитанция-существует-или-недоступна") }
        defer { close(файл) }
        try байты.withUnsafeBytes { буфер in
            var смещение = 0
            while смещение < буфер.count {
                let число = write(файл, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
                if число < 0, errno == EINTR { continue }
                guard число > 0 else { throw ОтказИндексаMarkdown.вход("неполная-квитанция") }
                смещение += число
            }
        }
        guard fsync(файл) == 0, fsync(родитель) == 0 else { throw ОтказИндексаMarkdown.вход("не-сохранена-квитанция") }
    }

    // Перенос точной маски двух канонических recency-helper: ограды и SHARE-VERBATIM.
    // UTF-16-маска сохраняет NSRange в исходной строке; сами исходные байты не меняются.
    static func маскироватьЦитаты(_ текст: String, путь: String) throws -> String {
        var единицы = Array(текст.utf16)
        func скрыть(_ диапазон: NSRange) {
            for номер in диапазон.location..<(диапазон.location + диапазон.length) where единицы[номер] != 10 && единицы[номер] != 13 { единицы[номер] = 32 }
        }
        let части = путь.split(separator: "/").map(String.init)
        if части.count == 7, Array(части.prefix(5)) == ["Источники", "URL", "https", "chatgpt.com", "share"], путь.lowercased().hasSuffix(".md") {
            let маркеры = try NSRegularExpression(pattern: #"(?m)^<!-- FUM-CHATGPT-SHARE-VERBATIM:(BEGIN|END) -->$"#)
            let найденные = маркеры.matches(in: текст, range: NSRange(текст.startIndex..., in: текст))
            if найденные.count == 2,
               (текст as NSString).substring(with: найденные[0].range(at: 1)) == "BEGIN",
               (текст as NSString).substring(with: найденные[1].range(at: 1)) == "END" {
                let перед = (текст as NSString).substring(to: найденные[0].range.location).split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                if перед.last == "## Диалог" { скрыть(NSRange(location: найденные[0].range.location, length: NSMaxRange(найденные[1].range) - найденные[0].range.location)) }
            }
        }
        let доОград = String(decoding: единицы, as: UTF16.self)
        if !доОград.contains("```"), !доОград.contains("~~~") { return доОград }
        let строки = try NSRegularExpression(pattern: #"[^\n]*(?:\n|\z)"#)
        let выражение = try NSRegularExpression(pattern: #"\A {0,3}(`{3,}|~{3,})([^\r\n]*)(?:\r?\n|\z)\z"#)
        var ограда: (знак: Character, длина: Int)?
        for совпадение in строки.matches(in: доОград, range: NSRange(доОград.startIndex..., in: доОград)) where совпадение.range.length > 0 {
            let строка = (доОград as NSString).substring(with: совпадение.range)
            var скрытая = ограда != nil
            if let метка = выражение.firstMatch(in: строка, range: NSRange(строка.startIndex..., in: строка)) {
                let знаки = (строка as NSString).substring(with: метка.range(at: 1))
                let хвост = (строка as NSString).substring(with: метка.range(at: 2))
                if ограда == nil {
                    if знаки.first != "`" || !хвост.contains("`") { ограда = (знаки.first!, знаки.count); скрытая = true }
                } else if знаки.first == ограда!.знак, знаки.count >= ограда!.длина, хвост.trimmingCharacters(in: CharacterSet(charactersIn: " \t")).isEmpty { ограда = nil }
            }
            if скрытая { скрыть(совпадение.range) }
        }
        guard ограда == nil else { throw ОтказИндексаMarkdown.вход("незамкнутая-ограда") }
        return String(decoding: единицы, as: UTF16.self)
    }

    static func кодировать<T: Encodable>(_ значение: T) throws -> Data {
        let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение); данные.append(10); return данные
    }
}

#if ФУМ_ВОССТАНОВЛЕНИЕ_ИНДЕКСА
@main
struct КомандаВосстановленияИндекса {
    static func main() async {
        do {
            let аргументы = CommandLine.arguments
            guard (4...6).contains(аргументы.count) else { throw ОтказИндексаMarkdown.вход("план вход.json каталог | применить план.json sha256 каталог | ремонт план.json sha256 разрешение.json каталог") }
            if аргументы[1] == "план", аргументы.count == 4 {
                let вход = try JSONDecoder().decode(ВходВосстановленияИндекса.self, from: Data(contentsOf: URL(fileURLWithPath: аргументы[2])))
                let план = try ВосстановлениеИндексаMarkdown.построить(вход)
                let каталог = URL(fileURLWithPath: аргументы[3])
                let байты = try ВосстановлениеИндексаMarkdown.кодировать(план)
                try байты.write(to: каталог.appendingPathComponent("plan.json"), options: .withoutOverwriting)
                try план.результат.write(to: каталог.appendingPathComponent("index.md"), options: .withoutOverwriting)
                print("план: \(ИндексMarkdownСлияния.хэш(байты)); Markdown: \(план.файлы.count + 1); общая свежесть: не-пройдена")
            } else if аргументы[1] == "профиль", аргументы.count == 5 {
                let байты = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                guard ИндексMarkdownСлияния.хэш(байты) == аргументы[3] else { throw ОтказИндексаMarkdown.вход("SHA-профиля") }
                let план = try JSONDecoder().decode(ПланВосстановленияИндекса.self, from: байты)
                let каталог = URL(fileURLWithPath: аргументы[4])
                try ВосстановлениеИндексаMarkdown.сверитьКаталогКвитанций(каталог, корень: план.вход.корень)
                let ход = try ХодВосстановленияИндекса(каталог: каталог, план: аргументы[3])
                for номер in 1...3 {
                    guard try ход.фаза("сверка-\(номер)-полный-план", { try ВосстановлениеИндексаMarkdown.построить(план.вход) == план }) else { throw ОтказИндексаMarkdown.вход("дрейф-профиля") }
                }
                try ход.завершить("только-чтение")
            } else if аргументы[1] == "применить", аргументы.count == 5 {
                let байты = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                guard ИндексMarkdownСлияния.хэш(байты) == аргументы[3] else { throw ОтказИндексаMarkdown.вход("SHA-плана") }
                let план = try JSONDecoder().decode(ПланВосстановленияИндекса.self, from: байты)
                try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: URL(fileURLWithPath: аргументы[4]))
                print("восстановлен только производный индекс; общая свежесть не пройдена")
            } else if аргументы[1] == "ремонт", аргументы.count == 6 {
                let байты = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                guard ИндексMarkdownСлияния.хэш(байты) == аргументы[3] else { throw ОтказИндексаMarkdown.вход("SHA-плана-ремонта") }
                let план = try JSONDecoder().decode(ПланВосстановленияИндекса.self, from: байты)
                let разрешение = try JSONDecoder().decode(РазрешениеРемонтаИндекса.self, from: Data(contentsOf: URL(fileURLWithPath: аргументы[4])))
                try ВосстановлениеИндексаMarkdown.ремонт(план, разрешение: разрешение, каталогКвитанции: URL(fileURLWithPath: аргументы[5]))
                print("выполнен один адресный ремонт индекса; прежние доказательства сохранены")
            } else if аргументы[1] == "контролировать", аргументы.count == 6 {
                let байты = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                guard ИндексMarkdownСлияния.хэш(байты) == аргументы[3] else { throw ОтказИндексаMarkdown.вход("SHA-контроля") }
                let план = try JSONDecoder().decode(ПланВосстановленияИндекса.self, from: байты)
                let разрешение = try JSONDecoder().decode(РазрешениеРемонтаИндекса.self, from: Data(contentsOf: URL(fileURLWithPath: аргументы[4])))
                try ВосстановлениеИндексаMarkdown.сверитьОтсутствиеПроизводителя(разрешение)
                let исход = try await КонтроллерВосстановленияИндекса.выполнить(исполнитель: URL(fileURLWithPath: аргументы[0]),
                    аргументы: ["ремонт"] + Array(аргументы.dropFirst(2)), каталог: URL(fileURLWithPath: аргументы[5]), план: план)
                guard исход.код == 0, !исход.предел_достигнут else { throw ОтказИндексаMarkdown.вход("контроллер-зафиксировал-отказ-или-timeout") }
            } else { throw ОтказИндексаMarkdown.вход("неверная-команда") }
        } catch { fputs("\(error)\n", stderr); exit(2) }
    }
}
#endif
