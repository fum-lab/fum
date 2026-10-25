import Foundation
import Darwin

enum Файлы {
    static func внеГит(_ строка: String) throws {
        _ = try физический(строка)
        var текущий = строка
        while true {
            let папка = URL(fileURLWithPath: текущий)
            let обычный = существует(папка.appendingPathComponent(".git"))
            let голый = ["HEAD", "objects", "config"].allSatisfy { существует(папка.appendingPathComponent($0)) }
            try требовать(!обычный && !голый, "приватные данные находятся в Git-предке")
            if текущий == "/" { break }
            let конец = текущий.lastIndex(of: "/")!
            текущий = конец == текущий.startIndex ? "/" : String(текущий[..<конец])
        }
    }
    static func физический(_ строка: String) throws -> URL {
        let адрес = URL(fileURLWithPath: строка)
        let части = строка.split(separator: "/", omittingEmptySubsequences: false)
        try требовать(строка.hasPrefix("/") && !строка.contains("\0") &&
                       (строка == "/" || части.dropFirst().allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }),
                       "нефизический путь: " + строка)
        var текущий = строка
        while текущий != "/" {
            var сведения = stat()
            if lstat(текущий, &сведения) == 0 {
                try требовать((сведения.st_mode & S_IFMT) != S_IFLNK, "symlink в пути: " + текущий)
            }
            let конец = текущий.lastIndex(of: "/")!
            текущий = конец == текущий.startIndex ? "/" : String(текущий[..<конец])
        }
        return адрес
    }
    static func прочитать(_ строка: String, приватный: Bool = false) throws -> Data {
        let адрес = try физический(строка)
        var сведения = stat()
        try требовать(lstat(адрес.path, &сведения) == 0 &&
                       (сведения.st_mode & S_IFMT) == S_IFREG && сведения.st_nlink == 1,
                       "нужен обычный файл nlink1")
        try требовать(сведения.st_uid == getuid() || !приватный && сведения.st_uid == 0,
                       "чужой владелец файла")
        if приватный {
            var родитель = stat()
            try требовать((сведения.st_mode & 0o777) == 0o600 &&
                           lstat(адрес.deletingLastPathComponent().path, &родитель) == 0 &&
                           (родитель.st_mode & 0o777) == 0o700, "неприватный вход")
        }
        let данные = try Data(contentsOf: адрес)
        var после = stat()
        try требовать(lstat(адрес.path, &после) == 0 && сведения.st_dev == после.st_dev &&
                       сведения.st_ino == после.st_ino && сведения.st_size == после.st_size &&
                       сведения.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec &&
                       сведения.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec, "файл изменился при чтении")
        return данные
    }
    static func ресурс(_ описание: Ресурс) throws -> Data {
        let данные = try прочитать(описание.путь)
        try требовать(хэш(данные) == описание.хэш, "подменён ресурс: " + описание.путь)
        return данные
    }
    static func приватныйКаталог(_ строка: String, создать: Bool = false) throws -> URL {
        let адрес = try физический(строка)
        if создать && !FileManager.default.fileExists(atPath: строка) {
            try требовать(mkdir(строка, 0o700) == 0, "не удалось создать приватный каталог")
            try синхронизировать(адрес.deletingLastPathComponent())
        }
        var сведения = stat()
        try требовать(lstat(строка, &сведения) == 0 && (сведения.st_mode & S_IFMT) == S_IFDIR &&
                       сведения.st_uid == getuid() && (сведения.st_mode & 0o777) == 0o700,
                       "нужен собственный каталог0700")
        return адрес
    }
    static func синхронизировать(_ каталог: URL) throws {
        let дескриптор = open(каталог.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        try требовать(дескриптор >= 0, "не удалось открыть каталог для fsync")
        defer { close(дескриптор) }
        try требовать(fsync(дескриптор) == 0, "ошибка fsync каталога")
    }
    static func записатьНовый(_ адрес: URL, _ данные: Data) throws {
        _ = try приватныйКаталог(адрес.deletingLastPathComponent().path)
        let дескриптор = open(адрес.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        try требовать(дескриптор >= 0, "файл уже существует/недоступен: " + адрес.path)
        defer { close(дескриптор) }
        try данные.withUnsafeBytes { буфер in
            var записано = 0
            while записано < буфер.count {
                let число = write(дескриптор, буфер.baseAddress!.advanced(by: записано), буфер.count - записано)
                if число < 0 && errno == EINTR { continue }
                try требовать(число > 0, "ошибка записи")
                записано += число
            }
        }
        try требовать(fsync(дескриптор) == 0, "ошибка fsync файла")
        try синхронизировать(адрес.deletingLastPathComponent())
    }
    static func существует(_ адрес: URL) -> Bool {
        var сведения = stat()
        return lstat(адрес.path, &сведения) == 0
    }
}

struct ОтветКоманды: Sendable {
    let код: Int32
    let вывод: Data
    let ошибки: Data
    let процесс: Int32
}

final class Команды {
    let рабочийКаталог: URL
    let сырьё: URL
    init(рабочийКаталог: String, сырьё: String) throws {
        self.рабочийКаталог = try Файлы.физический(рабочийКаталог)
        self.сырьё = try Файлы.приватныйКаталог(сырьё)
    }
    func выполнить(_ программа: String, _ аргументы: [String], вход: Data? = nil) throws -> ОтветКоманды {
        let номер = UUID().uuidString.lowercased()
        let выход = сырьё.appendingPathComponent(номер + "-stdout.raw")
        let ошибка = сырьё.appendingPathComponent(номер + "-stderr.raw")
        try Файлы.записатьНовый(выход, Data())
        try Файлы.записатьНовый(ошибка, Data())
        let исходящий = try FileHandle(forWritingTo: выход)
        let ошибочный = try FileHandle(forWritingTo: ошибка)
        defer { try? исходящий.close(); try? ошибочный.close() }
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: программа)
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = рабочийКаталог
        var окружение = ProcessInfo.processInfo.environment
        for ключ in ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR",
                     "GIT_CONFIG_PARAMETERS", "GIT_CONFIG_COUNT", "GIT_OBJECT_DIRECTORY",
                     "GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_REPLACE_REF_BASE", "GIT_NAMESPACE"] {
            try требовать(окружение[ключ] == nil, "перенаправление Git-среды: " + ключ)
        }
        try требовать((окружение["PATH"] ?? "").split(separator: ":", omittingEmptySubsequences: false)
            .allSatisfy { !$0.isEmpty && $0.hasPrefix("/") }, "небезопасный PATH")
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        процесс.environment = окружение
        процесс.standardOutput = исходящий; процесс.standardError = ошибочный
        var входящий: FileHandle?
        if let вход {
            let путь = сырьё.appendingPathComponent(номер + "-stdin.raw")
            try Файлы.записатьНовый(путь, вход)
            входящий = try FileHandle(forReadingFrom: путь)
            процесс.standardInput = входящий
        } else { процесс.standardInput = FileHandle.nullDevice }
        defer { try? входящий?.close() }
        try процесс.run()
        let идентификатор = процесс.processIdentifier
        процесс.waitUntilExit()
        try исходящий.synchronize(); try ошибочный.synchronize()
        return ОтветКоманды(код: процесс.terminationStatus,
                            вывод: try Data(contentsOf: выход),
                            ошибки: try Data(contentsOf: ошибка), процесс: идентификатор)
    }
}

final class Гит {
    let ресурс: Ресурс
    let команды: Команды
    init(_ задание: ЗаданиеПерехода) throws {
        try Файлы.внеГит(задание.каталогСырья)
        try Файлы.внеГит(задание.каталогПротокола)
        try требовать(задание.каталогСырья != задание.каталогПротокола &&
                       !задание.каталогСырья.hasPrefix(задание.каталогПротокола + "/") &&
                       !задание.каталогПротокола.hasPrefix(задание.каталогСырья + "/"), "сырьё и протокол пересекаются")
        ресурс = задание.исполняемыйГит
        команды = try Команды(рабочийКаталог: задание.рабочееДерево, сырьё: задание.каталогСырья)
    }
    func вызвать(_ аргументы: [String]) throws -> ОтветКоманды {
        _ = try Файлы.ресурс(ресурс)
        return try команды.выполнить(ресурс.путь,
            ["--no-pager", "--no-replace-objects", "--no-optional-locks", "--no-lazy-fetch",
             "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null", "-c", "protocol.ext.allow=never",
             "-c", "gc.auto=0", "-c", "maintenance.auto=false"] + аргументы)
    }
    func прочитать(_ аргументы: [String]) throws -> String {
        let ответ = try вызвать(аргументы)
        try требовать(ответ.код == 0, String(data: ответ.ошибки, encoding: .utf8) ?? "ошибка Git")
        return String(decoding: ответ.вывод, as: UTF8.self).trimmingCharacters(in: .newlines)
    }
    func ссылки() throws -> [String: String] {
        try Self.разобрать(прочитать(["for-each-ref", "--format=%(objectname)\t%(refname)"]), разделитель: "\t")
    }
    func сервер() throws -> [String: String] {
        try Self.разобрать(прочитать(["ls-remote", "--refs", "origin"]), разделитель: "\t")
    }
    static func разобрать(_ текст: String, разделитель: Character) throws -> [String: String] {
        var результат: [String: String] = [:]
        for строка in текст.split(separator: "\n") {
            let части = строка.split(separator: разделитель, maxSplits: 1).map(String.init)
            try требовать(части.count == 2 && результат[части[1]] == nil, "неоднозначный ref")
            результат[части[1]] = части[0]
        }
        return результат
    }
}
