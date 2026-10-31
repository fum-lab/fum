import Foundation
import CryptoKit
import Darwin

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

public enum ГраницаОтказаStop: String, Sendable { case доRename, послеRename }
public struct ОтказАтомарнойЗаменыStop: Error, Sendable {
    public let граница: ГраницаОтказаStop
    public let фаза: String
    public let наблюдаемыйSHA256: String?
    public let оставленныйВременныйФайл: String?
    public let причина: String
}
public struct ОтпечатокФайлаStop: Equatable, Sendable {
    public let устройство: Int64, inode: UInt64, размер: Int64
    public let режим: mode_t
    public let владелец: uid_t
    public let ссылки: UInt64
    public let mtimeСек: Int64, mtimeНс: Int64, ctimeСек: Int64, ctimeНс: Int64
    init(_ s: Darwin.stat) {
        устройство = Int64(s.st_dev); inode = UInt64(s.st_ino); размер = Int64(s.st_size)
        режим = s.st_mode; владелец = s.st_uid; ссылки = UInt64(s.st_nlink)
        mtimeСек = Int64(s.st_mtimespec.tv_sec); mtimeНс = Int64(s.st_mtimespec.tv_nsec)
        ctimeСек = Int64(s.st_ctimespec.tv_sec); ctimeНс = Int64(s.st_ctimespec.tv_nsec)
    }
}
public struct СнимокБайтовStop: Sendable {
    public let данные: Data
    public let sha256: String
    public let отпечаток: ОтпечатокФайлаStop
}
private enum СбойБайтовStop: Error { case проверка, система(Int32), срок }
struct ТочкиАтомарнойЗаменыStop {
    var передRename: (() throws -> Void)? = nil
    var синхронизацияФайла: (Int32) throws -> Void = {
        guard Darwin.fsync($0) == 0 else { throw СбойБайтовStop.система(errno) }
    }
    var синхронизацияКаталога: (Int32) throws -> Void = {
        guard Darwin.fsync($0) == 0 else { throw СбойБайтовStop.система(errno) }
    }
}

/// Только байты; JSON, ROOT identity и разрешённый config проверяет вызывающий.
/// Нужен единственный писатель pathname весь интервал. Это не kernel CAS.
/// nil ожидаемыйРежим: metadata policy без специальных битов/group/world write.
public enum АтомарныеБайтыStop {
    private static let пределЗамены = 1_048_576
    public static func sha256(_ d: Data) -> String {
        SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined()
    }
    private static func нужно(_ b: Bool) throws {
        guard b else { throw СбойБайтовStop.проверка }
    }
    private static func время() throws -> UInt64 {
        var t = timespec()
        try нужно(clock_gettime(CLOCK_MONOTONIC, &t) == 0 && t.tv_sec >= 0
                  && t.tv_nsec >= 0 && t.tv_nsec < 1_000_000_000)
        return UInt64(t.tv_sec) * 1_000_000_000 + UInt64(t.tv_nsec)
    }
    fileprivate static func родитель(_ путь: String) throws -> (Int32, String) {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        try нужно(путь.utf8.count <= 4096 && !путь.utf8.contains(0)
                  && части.count >= 2 && части.first == ""
                  && части.dropFirst().allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." })
        var fd = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        try нужно(fd >= 0)
        do {
            for часть in части.dropFirst().dropLast() {
                let next = openat(fd, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                try нужно(next >= 0)
                Darwin.close(fd); fd = next
            }
            var s = Darwin.stat()
            try нужно(fstat(fd, &s) == 0 && s.st_mode & S_IFMT == S_IFDIR
                      && s.st_uid == geteuid() && s.st_mode & 0o022 == 0)
            return (fd, части.last!)
        } catch { Darwin.close(fd); throw error }
    }
    private static func открыть(_ p: Int32, _ имя: String) throws -> Int32 {
        let fd = openat(p, имя, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        try нужно(fd >= 0)
        return fd
    }
    private static func годен(_ s: Darwin.stat, _ режим: mode_t?, _ предел: Int) -> Bool {
        s.st_mode & S_IFMT == S_IFREG && s.st_uid == geteuid() && s.st_nlink == 1
            && s.st_size >= 0 && s.st_size <= предел
            && (режим.map { s.st_mode & 0o7777 == $0 }
                ?? (s.st_mode & 0o7022 == 0))
    }
    private static func снять(_ fd: Int32, _ p: Int32, _ имя: String,
                              _ режим: mode_t?, _ предел: Int) throws -> СнимокБайтовStop {
        try нужно(предел >= 0 && предел <= 67_108_864)
        var a = Darwin.stat(), b = Darwin.stat(), named = Darwin.stat()
        try нужно(fstat(fd, &a) == 0 && годен(a, режим, предел))
        let край = try время() + 5_000_000_000
        var d = Data()
        while d.count <= предел {
            guard try время() < край else { throw СбойБайтовStop.срок }
            var buf = [UInt8](repeating: 0, count: min(16_384, предел + 1 - d.count))
            let n = buf.withUnsafeMutableBytes {
                Darwin.pread(fd, $0.baseAddress, $0.count, off_t(d.count))
            }
            if n > 0 { d.append(contentsOf: buf.prefix(n)) }
            else if n == 0 { break }
            else if errno != EINTR { throw СбойБайтовStop.система(errno) }
        }
        try нужно(fstat(fd, &b) == 0 && годен(b, режим, предел)
                  && ОтпечатокФайлаStop(a) == ОтпечатокФайлаStop(b)
                  && d.count == Int(b.st_size) && d.count <= предел
                  && fstatat(p, имя, &named, AT_SYMLINK_NOFOLLOW) == 0
                  && ОтпечатокФайлаStop(b) == ОтпечатокФайлаStop(named))
        return СнимокБайтовStop(данные: d, sha256: sha256(d), отпечаток: ОтпечатокФайлаStop(b))
    }
    private static func снятьИмя(_ p: Int32, _ имя: String) throws -> СнимокБайтовStop {
        let fd = try открыть(p, имя); defer { Darwin.close(fd) }
        return try снять(fd, p, имя, 0o600, пределЗамены)
    }
    public static func прочитать(_ путь: String, ожидаемыйРежим: mode_t? = 0o600,
                                  предел: Int = 1_048_576) throws -> СнимокБайтовStop {
        do {
            let (p, имя) = try родитель(путь); defer { Darwin.close(p) }
            let fd = try открыть(p, имя); defer { Darwin.close(fd) }
            return try снять(fd, p, имя, ожидаемыйРежим, предел)
        } catch {
            throw ОтказАтомарнойЗаменыStop(граница: .доRename, фаза: "чтение",
                наблюдаемыйSHA256: nil, оставленныйВременныйФайл: nil,
                причина: String(describing: error))
        }
    }
    public static func заменить(_ путь: String, ожидаемыйSHA256: String,
                                 новыми данные: Data) throws -> СнимокБайтовStop {
        try заменить(путь, ожидаемыйSHA256: ожидаемыйSHA256, новыми: данные,
                     точки: ТочкиАтомарнойЗаменыStop())
    }
    static func заменить(_ путь: String, ожидаемыйSHA256: String, новыми данные: Data,
                          точки: ТочкиАтомарнойЗаменыStop) throws -> СнимокБайтовStop {
        try записать(путь, ожидаемыйSHA256: ожидаемыйSHA256, новыми: данные, точки: точки)
    }
    /// Только первое создание: RENAME_EXCL сохраняет любой появившийся target.
    public static func создатьЕслиОтсутствует(_ путь: String,
        новыми данные: Data) throws -> СнимокБайтовStop {
        try записать(путь, ожидаемыйSHA256: nil, новыми: данные, точки: ТочкиАтомарнойЗаменыStop())
    }
    static func записать(_ путь: String, ожидаемыйSHA256: String?, новыми данные: Data,
        точки: ТочкиАтомарнойЗаменыStop) throws -> СнимокБайтовStop {
        var p: Int32 = -1, oldFD: Int32 = -1, tempFD: Int32 = -1
        var имя = "", temp = "", фаза = "вход"
        var renamed = false
        var наблюдаемый: String?
        defer {
            for fd in [oldFD, tempFD, p] where fd >= 0 { Darwin.close(fd) }
        }
        do {
            try нужно(данные.count <= пределЗамены && (ожидаемыйSHA256.map {
                $0.utf8.count == 64 && $0.utf8.allSatisfy {
                          (48...57).contains($0) || (97...102).contains($0)
                }
            } ?? true))
            (p, имя) = try родитель(путь)
            var old: СнимокБайтовStop?
            if let ожидаемыйSHA256 {
                oldFD = try открыть(p, имя)
                фаза = "чтение-старого"
                let snapshot = try снять(oldFD, p, имя, 0o600, пределЗамены)
                old = snapshot; наблюдаемый = snapshot.sha256
                фаза = "ожидаемый-SHA"
                try нужно(snapshot.sha256 == ожидаемыйSHA256)
            } else {
                фаза = "ожидаемое-отсутствие"
                var named = Darwin.stat()
                try нужно(fstatat(p, имя, &named, AT_SYMLINK_NOFOLLOW) != 0 && errno == ENOENT)
            }
            фаза = "создание-временного"
            temp = ".fum-stop-" + UUID().uuidString.lowercased() + ".tmp"
            tempFD = openat(p, temp, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            try нужно(tempFD >= 0)
            try нужно(fchmod(tempFD, 0o600) == 0)
            фаза = "запись-временного"
            let край = try время() + 5_000_000_000
            try данные.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
                var offset = 0
                while offset < buf.count {
                    guard try время() < край else { throw СбойБайтовStop.срок }
                    let n = Darwin.write(tempFD, buf.baseAddress!.advanced(by: offset), buf.count - offset)
                    if n > 0 { offset += n }
                    else if n == 0 || errno != EINTR { throw СбойБайтовStop.система(errno) }
                }
            }
            фаза = "fsync-файла"
            try точки.синхронизацияФайла(tempFD)
            фаза = "перед-rename"
            try точки.передRename?()
            фаза = "сверка-родителя"
            let (againP, againName) = try родитель(путь); defer { Darwin.close(againP) }
            var a = Darwin.stat(), b = Darwin.stat()
            try нужно(имя == againName && fstat(p, &a) == 0 && fstat(againP, &b) == 0
                      && a.st_dev == b.st_dev && a.st_ino == b.st_ino)
            фаза = "сверка-старого"
            if let old {
                let again = try снять(oldFD, p, имя, 0o600, пределЗамены)
                наблюдаемый = again.sha256
                try нужно(again.отпечаток == old.отпечаток && again.данные == old.данные
                          && again.sha256 == ожидаемыйSHA256)
            } else {
                var named = Darwin.stat()
                try нужно(fstatat(p, имя, &named, AT_SYMLINK_NOFOLLOW) != 0 && errno == ENOENT)
            }
            фаза = "сверка-временного"
            let prepared = try снять(tempFD, p, temp, 0o600, пределЗамены)
            try нужно(prepared.данные == данные)
            фаза = "rename"
            let moved = ожидаемыйSHA256 == nil
                ? renameatx_np(p, temp, p, имя, UInt32(RENAME_EXCL))
                : renameat(p, temp, p, имя)
            guard moved == 0 else { throw СбойБайтовStop.система(errno) }
            renamed = true
            наблюдаемый = nil // Старое наблюдение не описывает состояние после эффекта.
            фаза = "fsync-каталога"
            try точки.синхронизацияКаталога(p)
            фаза = "readback"
            let result = try снятьИмя(p, имя)
            наблюдаемый = result.sha256
            try нужно(result.данные == данные
                      && result.отпечаток.устройство == prepared.отпечаток.устройство
                      && result.отпечаток.inode == prepared.отпечаток.inode)
            return result
        } catch {
            let причина = String(describing: error)
            if p >= 0, !имя.isEmpty, let seen = try? снятьИмя(p, имя) {
                наблюдаемый = seen.sha256
            }
            var оставлен: String?
            if !renamed && tempFD >= 0 {
                var own = Darwin.stat(), named = Darwin.stat()
                let найден = fstatat(p, temp, &named, AT_SYMLINK_NOFOLLOW)
                let отсутствует = найден != 0 && errno == ENOENT
                let наш = fstat(tempFD, &own) == 0 && own.st_uid == geteuid()
                    && own.st_mode & S_IFMT == S_IFREG && own.st_nlink == 1
                    && найден == 0 && named.st_dev == own.st_dev && named.st_ino == own.st_ino
                if !отсутствует && !(наш && unlinkat(p, temp, 0) == 0) {
                    оставлен = (путь as NSString).deletingLastPathComponent + "/" + temp
                }
            }
            throw ОтказАтомарнойЗаменыStop(
                граница: renamed ? .послеRename : .доRename, фаза: фаза,
                наблюдаемыйSHA256: наблюдаемый, оставленныйВременныйФайл: оставлен,
                причина: причина)
        }
    }
}

/// Один неизменяемый inode для всех кооперативных писателей current.
/// Создаёт и закрепляет ROOT до вызова; файл никогда не заменяется и не удаляется.
public struct СсылкаЗамкаStop: Codable, Sendable {
    public let path: String
    public let device: Int64
    public let inode: UInt64
    public init(path: String, device: Int64, inode: UInt64) {
        self.path = path; self.device = device; self.inode = inode
    }
}
public enum ЗамокТекущегоStop {
    /// Действие синхронное. Замок удерживается до выхода, в том числе при ошибке.
    /// Каждый publisher обязан брать тот же замок на весь replacement/readback.
    /// flock не защищает от писателя, который нарушает этот протокол.
    public static func выполнить<T>(_ pin: СсылкаЗамкаStop,
        _ действие: (_ проверить: () throws -> Void) throws -> T) throws -> T {
        guard pin.device > 0, pin.inode > 0 else { throw E("L0") }
        let (dir, name) = try АтомарныеБайтыStop.родитель(pin.path)
        defer { _ = Darwin.close(dir) }
        var parent = Darwin.stat()
        guard fstat(dir, &parent) == 0, parent.st_mode & 0o7777 == 0o700 else {
            throw E("L1", pin.path)
        }
        let fd = openat(dir, name, O_RDWR | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw E("L2", pin.path) }
        defer { _ = Darwin.close(fd) }
        func проверить() throws {
            let (again, againName) = try АтомарныеБайтыStop.родитель(pin.path)
            defer { _ = Darwin.close(again) }
            var a = Darwin.stat(), named = Darwin.stat(), p = Darwin.stat()
            guard againName == name, fstat(again, &p) == 0,
                p.st_dev == parent.st_dev, p.st_ino == parent.st_ino,
                p.st_mode & 0o7777 == 0o700,
                fstat(fd, &a) == 0, fstatat(dir, name, &named, AT_SYMLINK_NOFOLLOW) == 0,
                a.st_mode & S_IFMT == S_IFREG, a.st_mode & 0o7777 == 0o600,
                a.st_uid == geteuid(), a.st_nlink == 1, a.st_size == 0,
                Int64(a.st_dev) == pin.device, UInt64(a.st_ino) == pin.inode,
                ОтпечатокФайлаStop(a) == ОтпечатокФайлаStop(named) else {
                throw E("L3", pin.path)
            }
        }
        try проверить()
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw E("Lbusy", pin.path) }
        // close освобождает flock и при thrown body; named inode проверяется после захвата.
        try проверить()
        return try действие(проверить)
    }
}

// --применить не доказывает ROOT authority, custody или Native trust.
// Повторные чтения point-in-time: это не CAS и не доказательство custody.
// Коды: P/path-plan, F/file, D/delta, A/argv, E/env, H/header, S/stage, G/git, C/current, R/receipt.
private struct E: Error, CustomStringConvertible {
let description: String
init(_ code: String, _ path: String? = nil) {
 description = path.map { "\(code):\($0)" } ?? code
}
}
private enum M { case check, apply(String) }
private struct Pin: Decodable { let path: String; let bytes: Int; let sha256: String; let mode: UInt32 }
private struct Old: Decodable {
let path: String; let bytes: Int; let sha256, commandSHA256: String
let tokenOffset, tokenBytes: Int; let mode: UInt32
}
private struct Cmd: Decodable { let argv, launcherArgv: [String]; let text: String }
private struct Env: Decodable {
let clear: Bool; let only: [String: String]; let resourceBundleOverridesAbsent: Bool
}
private struct Sys: Decodable {
let path: String; let bytes: Int; let sha256: String
let uid: UInt32; let nlink: UInt64; let mode: UInt32
}
private struct MPin: Decodable {
let path: String; let bytes: Int; let sha256: String; let mode: UInt32
let files: Int; let resourceMode: UInt32
}
private struct CPin: Decodable {
let path: String; let maxBytes: Int; let mode: UInt32; let lock: СсылкаЗамкаStop
}
private struct Publication: Decodable {
let schema, source: String
let header, candidate: Pin
let current: CPin
let initiallyAbsent: Bool
let expectedSHA256: String?
}
private struct Plan: Decodable {
let schema, profile, source, sourceOriginC3, sourceTree: String
let header, candidate, handler: Pin; let old: Old; let command: Cmd
let environment: Env; let systemEnv: Sys; let stageManifest: MPin; let current: CPin
}
private struct H: Decodable {
let схема, задача, узел, область, поколение, cwd, дерево, ref: String
let gitDir, commonGitDir, backend, objectFormat, исходники: String
let состояние, каталогКвитанций: String; let максимальныйВозрастСекунд: Int64
}
private struct Control: Decodable { let действие, основание: String }
private struct Envelope: Decodable {
let схема, заголовокSHA256, задача, узел, область, поколение: String
let управление: Control
}
private struct Meta: Decodable { let cwd, дерево, ref, HEAD: String; let выпущен, действуетДо: Int64 }
private struct SF: Decodable {
    let path: String
    let bytes: Int
    let sha256: String
    enum CodingKeys: String, CodingKey {
        case path = "путь"
        case bytes = "байтов"
        case sha256
    }
}
private struct Manifest: Decodable {
    let files: [SF]
    enum CodingKeys: String, CodingKey { case files = "файлы" }
}
private struct Cur { let sha, action: String }
private struct Art { let h: H; let candidate: Data; let command: String }
private struct Ctx {
let planPath, planSHA, config, parent: String
let p: Plan; let current: Cur?; let head: String
let привязкаСсылки: СнимокФайловойСсылки
}
struct RPaths { let intent, outcome, key: String }
public enum УстановщикStop {
private typealias AB = АтомарныеБайтыStop
private typealias Stamp = ОтпечатокФайлаStop
private static func need(_ b: Bool, _ code: String, _ path: String? = nil) throws {
 guard b else { throw E(code, path) }
}
private static func hex(_ s: String, _ n: Int) -> Bool {
 s.utf8.count == n && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
}
private static func uuid(_ s: String) -> Bool { UUID(uuidString: s)?.uuidString.lowercased() == s }
private static func token(_ s: String) -> Bool {
 !s.isEmpty && s.utf8.count <= 512
 && !s.unicodeScalars.contains { $0.value < 0x21 || $0.value == 0x7f }
}
private static func text(_ s: String) -> Bool {
 !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && s.utf8.count <= 2_048
 && !s.unicodeScalars.contains { $0.value < 0x20 && $0.value != 10 }
}
private static func abs(_ s: String) -> Bool {
 s.hasPrefix("/") && s.utf8.count <= 4_096 && !s.utf8.contains(0)
 && s.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
  .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
}
private static func rel(_ s: String) -> Bool {
 !s.isEmpty && !s.hasPrefix("/") && !s.contains("\\")
 && s.split(separator: "/", omittingEmptySubsequences: false)
  .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
}
private static func ref(_ s: String) -> Bool {
 s.hasPrefix("refs/heads/") && token(s) && !s.contains("..") && !s.contains("@{")
 && !s.contains(where: { "~^:?*[\\".contains($0) })
 && s.split(separator: "/", omittingEmptySubsequences: false)
  .allSatisfy { !$0.isEmpty && !$0.hasPrefix(".")
  && !$0.hasSuffix(".") && !$0.hasSuffix(".lock") }
}
private static func parent(_ s: String) throws -> String {
 try need(abs(s), "P0", s)
 guard let i = s.lastIndex(of: "/"), i != s.startIndex else { throw E("P1", s) }
 return String(s[..<i])
}
private static func dec<T: Decodable>(_ t: T.Type, _ d: Data) throws -> T {
 try JSONDecoder().decode(t, from: d)
}
private static func read(_ p: Pin, _ mode: mode_t, _ limit: Int) throws -> СнимокБайтовStop {
 try need(abs(p.path) && p.mode == UInt32(mode) && p.bytes >= 0
 && p.bytes <= limit && hex(p.sha256, 64), "F0", p.path)
 let s = try AB.прочитать(p.path, ожидаемыйРежим: mode, предел: p.bytes)
 try need(s.данные.count == p.bytes && s.sha256 == p.sha256, "F1", p.path)
 return s
}
private static func plan(_ path: String, _ sha: String) throws -> Plan {
 try need(abs(path) && hex(sha, 64), "P2", path)
 let s = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
 try need(s.sha256 == sha, "P3", path)
 let p = try dec(Plan.self, s.данные)
 try need(p.schema == "fum.stop-installer-plan.3"
 && p.profile == "fum.native-stop.install.1"
 && hex(p.source, 40) && hex(p.sourceOriginC3, 40) && hex(p.sourceTree, 40),
 "P4", path)
 return p
}
private static func quote(_ s: String) -> String {
 "'" + s.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
}
static func command(_ a: [String]) -> String {
 "exec /usr/bin/env -i 'PATH=' " + a.map(quote).joined(separator: " ")
}
private static func slot(_ d: Data) throws -> String {
 let root = try JSONSerialization.jsonObject(with: d) as? [String: Any]
 let stop = (root?["hooks"] as? [String: Any])?["Stop"] as? [[String: Any]]
 let hooks = stop?[safe: 1]?["hooks"] as? [[String: Any]]
 guard let value = hooks?[safe: 0]?["command"] as? String else { throw E("D0") }
 return value
}
public static func проверитьДельту(old: Data, candidate: Data, offset: Int, length: Int,
 oldCommandSHA256: String, newCommand: String) throws {
 try need(offset >= 0 && length > 1 && offset <= old.count
 && length <= old.count - offset && hex(oldCommandSHA256, 64), "D1")
 let suffix = old.count - offset - length
 try need(candidate.count >= offset + suffix + 2
 && candidate.prefix(offset) == old.prefix(offset)
 && candidate.suffix(suffix) == old.suffix(suffix), "D2")
 let a = old.subdata(in: offset..<(offset + length))
 let n = candidate.count - offset - suffix
 let b = candidate.subdata(in: offset..<(offset + n))
 guard let oldValue = try JSONSerialization.jsonObject(with: a, options: .fragmentsAllowed) as? String,
 let newValue = try JSONSerialization.jsonObject(with: b, options: .fragmentsAllowed) as? String
 else { throw E("D3") }
 try need(newValue == newCommand && AB.sha256(Data(oldValue.utf8)) == oldCommandSHA256,
 "D4")
 let oldSlot = try slot(old)
 let newSlot = try slot(candidate)
 try need(oldSlot == oldValue && newSlot == newCommand, "D5")
}
private static func args(_ a: [String]) throws -> (String, String, M) {
 try need(a.count == 5 || a.count == 6, "A0")
 try need(a[0] == "--план" && a[2] == "--хэш-плана"
 && abs(a[1]) && hex(a[3], 64), "A1")
 if a.count == 5 {
 try need(a[4] == "--проверить", "A2")
 return (a[1], a[3], .check)
 }
 try need(a[4] == "--применить" && hex(a[5], 64), "A3")
 return (a[1], a[3], .apply(a[5]))
}
private static func now() throws -> UInt64 {
 var t = timespec()
 try need(clock_gettime(CLOCK_MONOTONIC, &t) == 0 && t.tv_sec >= 0
 && t.tv_nsec >= 0 && t.tv_nsec < 1_000_000_000, "T0")
 return UInt64(t.tv_sec) * 1_000_000_000 + UInt64(t.tv_nsec)
}
private static func deadline() throws -> UInt64 {
 let n = try now()
 try need(n <= UInt64.max - 5_000_000_000, "T1")
 return n + 5_000_000_000
}
private static func sys(_ f: Sys) throws {
 try need(f.path == "/usr/bin/env" && f.uid == 0 && f.nlink == 1
 && f.mode == 0o755 && f.bytes >= 0 && f.bytes <= 1_048_576
 && hex(f.sha256, 64), "E0", f.path)
 for path in ["/usr", "/usr/bin", "/usr/bin/env"] {
 var s = Darwin.stat()
 try need(lstat(path, &s) == 0 && s.st_mode & S_IFMT != S_IFLNK, "E1", path)
 }
 let fd = Darwin.open(f.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
 try need(fd >= 0, "E2", f.path)
 defer { _ = Darwin.close(fd) }
 var a = Darwin.stat(), b = Darwin.stat(), named = Darwin.stat()
 try need(fstat(fd, &a) == 0 && a.st_mode & S_IFMT == S_IFREG
 && a.st_uid == 0 && a.st_nlink == 1 && a.st_mode & 0o7777 == 0o755
 && a.st_size == off_t(f.bytes), "E3", f.path)
 let end = try deadline()
 var data = Data(), offset = 0
 while offset <= f.bytes {
 try need(try now() < end, "E4", f.path)
 var buffer = [UInt8](repeating: 0, count: min(16_384, f.bytes + 1 - offset))
 let n = buffer.withUnsafeMutableBytes { pread(fd, $0.baseAddress, $0.count, off_t(offset)) }
 if n > 0 { data.append(contentsOf: buffer.prefix(n)); offset += n } else if n == 0 { break } else if errno != EINTR { throw E("E5", f.path) }
 }
 try need(data.count == f.bytes && fstat(fd, &b) == 0 && lstat(f.path, &named) == 0
 && Stamp(a) == Stamp(b) && Stamp(b) == Stamp(named)
 && AB.sha256(data) == f.sha256, "E6", f.path)
}
private static func header(_ h: H, _ p: Plan) throws -> String {
 try need(h.схема == "fum.stop-заголовок.2" && uuid(h.задача)
 && token(h.узел) && token(h.область) && token(h.поколение) && ref(h.ref)
 && h.backend == "files" && h.objectFormat == "sha1"
 && h.исходники == p.source && hex(h.исходники, 40)
 && (1...3_600).contains(h.максимальныйВозрастСекунд), "H0")
 try need([h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
 h.каталогКвитанций].allSatisfy(abs), "H1")
 try need(p.current.path == h.состояние && p.current.mode == 0o600
 && p.current.maxBytes > 0 && p.current.maxBytes <= 32_768
 && p.current.lock.path == h.состояние + ".lock"
 && p.current.lock.device > 0 && p.current.lock.inode > 0, "C0")
 try need(p.command.argv.count == 18 && p.command.argv[0] == p.handler.path
 && p.command.argv[1] == "stop", "A4")
 let expected = ["--идентификатор-обработчика", "fum.stop-handler.1",
 "--codex-thread-id", h.задача, "--идентификатор-узла", h.узел,
 "--ожидаемый-cwd", h.cwd, "--состояние", h.состояние,
 "--профиль-наблюдений", "fum.текущие-обязательства-stop.2",
 "--заголовок", p.header.path, "--хэш-заголовка", p.header.sha256]
 let value = command(p.command.argv)
 try need(Array(p.command.argv.dropFirst(2)) == expected && p.command.text == value
 && p.command.launcherArgv == ["/usr/bin/env", "-i", "PATH="] + p.command.argv
 && p.environment.clear && p.environment.only == ["PATH": ""]
 && p.environment.resourceBundleOverridesAbsent, "A5")
 return value
}
private static func stage(_ p: Plan) throws {
 let pin = p.stageManifest
 try need(abs(pin.path) && pin.mode == 0o600 && pin.files == 23
 && pin.resourceMode == 0o400 && pin.bytes >= 0 && pin.bytes <= 1_048_576
 && hex(pin.sha256, 64), "S0", pin.path)
 let raw = try AB.прочитать(pin.path, ожидаемыйРежим: 0o600, предел: pin.bytes)
 try need(raw.данные.count == pin.bytes && raw.sha256 == pin.sha256,
 "S1", pin.path)
 let m = try dec(Manifest.self, raw.данные), root = try parent(pin.path)
 try need(m.files.count == 23 && Set(m.files.map(\.path)).count == 23, "S2")
 var found = false
 for f in m.files {
 try need(rel(f.path) && f.bytes >= 0 && f.bytes <= 16_777_216
  && hex(f.sha256, 64), "S3", f.path)
 let mode: mode_t = f.path == "fuma" ? 0o500 : 0o400
 let path = root + "/" + f.path
 let s = try AB.прочитать(path, ожидаемыйРежим: mode, предел: f.bytes)
 try need(s.данные.count == f.bytes && s.sha256 == f.sha256, "S4", path)
 if f.path == "fuma" {
  found = true
  try need(path == p.handler.path && f.bytes == p.handler.bytes
  && f.sha256 == p.handler.sha256 && p.handler.mode == 0o500, "S5", path)
 }
 }
 try need(found, "S6")
}
private static func artifacts(_ p: Plan) throws -> Art {
 let raw = try read(p.header, 0o400, 32_768)
 let h = try dec(H.self, raw.данные)
 let cmd = try header(h, p)
 let candidate = try read(p.candidate, 0o600, 1_048_576)
 try stage(p)
 return Art(h: h, candidate: candidate.данные, command: cmd)
}
private static func снимокПривязкиСсылки(_ h: H) throws -> СнимокФайловойСсылки {
 let prefix = h.commonGitDir + "/worktrees/"
 try need(h.gitDir.hasPrefix(prefix)
 && !h.gitDir.dropFirst(prefix.count).contains("/"), "G0")
 let привязка = try ЧитательФайловойСсылки.прочитать(общийКаталог: h.commonGitDir,
  ссылка: h.ref, связанныеФайлы: [h.дерево + "/.git", h.gitDir + "/gitdir",
   h.gitDir + "/commondir", h.gitDir + "/HEAD"])
 try need(привязка.данные(h.дерево + "/.git") == Data("gitdir: \(h.gitDir)\n".utf8)
 && привязка.данные(h.gitDir + "/gitdir") == Data("\(h.дерево)/.git\n".utf8)
 && привязка.данные(h.gitDir + "/commondir") == Data("../..\n".utf8)
 && привязка.данные(h.gitDir + "/HEAD") == Data("ref: \(h.ref)\n".utf8), "G1")
 try привязка.подтвердить()
 return привязка
}
private static func current(_ p: Plan, _ h: H, _ headerSHA: String,
 _ head: String) throws -> Cur? {
 try current(p.current, h, headerSHA, head)
}
private static func current(_ pin: CPin, _ h: H, _ headerSHA: String,
 _ head: String) throws -> Cur? {
 var st = Darwin.stat()
 if lstat(pin.path, &st) != 0 {
 if errno == ENOENT { return nil }
 throw E("C1", pin.path)
 }
 let raw = try AB.прочитать(pin.path, ожидаемыйРежим: 0o600, предел: pin.maxBytes)
 return try currentBytes(raw.данные, raw.sha256, h, headerSHA, head)
}
private static func currentBytes(_ bytes: Data, _ sha: String, _ h: H,
 _ headerSHA: String, _ head: String) throws -> Cur {
 let e = try dec(Envelope.self, bytes)
 try need(e.схема == "fum.текущие-обязательства-stop.2"
 && e.заголовокSHA256 == headerSHA && e.задача == h.задача
 && e.узел == h.узел && e.область == h.область && e.поколение == h.поколение
 && text(e.управление.основание)
 && ["продолжать", "стоп", "пауза"].contains(e.управление.действие),
 "C2", h.состояние)
 let state = Cur(sha: sha, action: e.управление.действие)
 if state.action != "продолжать" { return state }
 let m = try dec(Meta.self, bytes)
 try need(m.cwd == h.cwd && m.дерево == h.дерево && m.ref == h.ref
 && m.HEAD == head && hex(m.HEAD, 40), "C3", h.состояние)
 let clock = Int64(Date().timeIntervalSince1970), age = h.максимальныйВозрастСекунд
 try need(m.выпущен >= 0 && m.выпущен <= clock && clock - m.выпущен <= age
 && m.действуетДо >= clock && m.действуетДо >= m.выпущен
 && m.действуетДо - m.выпущен <= age, "C4", h.состояние)
 return state
}
private static func config(_ p: Plan, _ path: String) throws {
 try need(p.old.path == path && p.old.mode == 0o600 && p.old.bytes >= 0
 && p.old.bytes <= 1_048_576 && hex(p.old.sha256, 64)
 && hex(p.old.commandSHA256, 64), "F2", path)
}
private static func load(_ argv: [String]) throws -> (Ctx, M) {
 let (planPath, planSHA, mode) = try args(argv)
 let p = try plan(planPath, planSHA)
 guard let pw = getpwuid(geteuid()), let home = pw.pointee.pw_dir else {
 throw E("U0")
 }
 let path = String(cString: home) + "/.codex/hooks.json"
 try config(p, path)
 if case .apply(let sha) = mode { try need(sha == p.candidate.sha256, "A6") }
 let a = try artifacts(p)
 try sys(p.systemEnv)
 let old = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: p.old.bytes)
 try need(old.данные.count == p.old.bytes && old.sha256 == p.old.sha256,
 "F3", path)
 try проверитьДельту(old: old.данные, candidate: a.candidate,
 offset: p.old.tokenOffset, length: p.old.tokenBytes,
 oldCommandSHA256: p.old.commandSHA256, newCommand: a.command)
 let привязкаСсылки = try снимокПривязкиСсылки(a.h)
 let head = привязкаСсылки.идентификаторОбъекта
 let cur = try current(p, a.h, p.header.sha256, head)
 try привязкаСсылки.подтвердить()
 return (Ctx(planPath: planPath, planSHA: planSHA, config: path,
 parent: try parent(planPath), p: p, current: cur, head: head, привязкаСсылки: привязкаСсылки), mode)
}
private static func directory(_ path: String) throws -> Int32 {
 try need(abs(path), "R0", path)
 let parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
 var fd = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
 try need(fd >= 0, "R1", path)
 do {
 for part in parts.dropFirst() {
  let next = openat(fd, part, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
  try need(next >= 0, "R2", path)
  _ = Darwin.close(fd); fd = next
 }
 var s = Darwin.stat()
 try need(fstat(fd, &s) == 0 && s.st_uid == geteuid()
  && s.st_mode & S_IFMT == S_IFDIR && s.st_mode & 0o7777 == 0o700,
  "R3", path)
 return fd
 } catch { _ = Darwin.close(fd); throw error }
}
static func receiptPaths(config: String, oldSHA: String, candidateSHA: String,
 publication: Bool = false) throws -> RPaths {
 try need(hex(oldSHA, 64) && hex(candidateSHA, 64), "Rkey")
 let dir = try parent(config)
 let domain = publication ? "publish" : "install"
 let key = AB.sha256(Data(("fum.stop-" + domain + "-operation.1\u{0}" + config
  + "\u{0}" + oldSHA + "\u{0}" + candidateSHA).utf8))
 let stem = dir + "/.fum-stop-" + domain + "-" + key
 return RPaths(intent: stem + ".intent.json", outcome: stem + ".outcome.json", key: key)
}
// Общая точка preflight для обоих CLI. Тестовая точка моделирует публикацию
// между первоначальным выбором lock pin и захватом стабильного inode.
static func предварительнаяПроверка<T>(_ pin: СсылкаЗамкаStop,
 передЗамком: (() throws -> Void)? = nil, наблюдать: () throws -> T) throws -> T {
 try передЗамком?()
 return try ЗамокТекущегоStop.выполнить(pin) { check in
  try check()
  return try наблюдать()
 }
}
// Этот адрес не зависит от planPath, HEAD, времени или UUID попытки.
// Любой оставшийся intent (включая частичный) блокирует повтор. Очистки здесь нет.
static func receipt(_ path: String, _ object: [String: Any]) throws {
 var data = try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
 data.append(10)
 try need(data.count <= 32_768, "R4", path)
 let p = try parent(path), name = String(path.dropFirst(p.count + 1))
 try need(rel(name) && !name.contains("/"), "R5", path)
 let (dir, checkedName) = try AB.родитель(path)
 defer { _ = Darwin.close(dir) }
 try need(checkedName == name, "R5", path)
 let fd = openat(dir, name, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
 if fd < 0 && errno == EEXIST { throw E("Rexists", path) }
 try need(fd >= 0, "R6", path)
 defer { _ = Darwin.close(fd) }
 try need(fchmod(fd, 0o600) == 0, "R7", path)
 let end = try deadline()
 try data.withUnsafeBytes { raw in
 var offset = 0
 while offset < raw.count {
  try need(try now() < end, "R8", path)
  let n = Darwin.write(fd, raw.baseAddress!.advanced(by: offset), raw.count - offset)
  if n > 0 { offset += n } else if n == 0 || errno != EINTR { throw E("R9", path) }
 }
 }
 try need(fsync(fd) == 0 && fsync(dir) == 0, "R10", path)
}
private static func emit(_ o: [String: Any]) {
 guard var data = try? JSONSerialization.data(withJSONObject: o, options: .sortedKeys)
 else { return }
 data.append(10)
 try? FileHandle.standardOutput.write(contentsOf: data)
}
private static func base(_ c: Ctx) -> [String: Any] {
 var o: [String: Any] = [
 "planSHA256": c.planSHA, "candidateSHA256": c.p.candidate.sha256,
 "rootHEAD": c.head, "externalApprovalRequired": true
 ]
 o["worklistCompleteness"] = "ROOT_REQUIRED"
 o["acceptedSourceAncestry"] = "ROOT_REQUIRED"
 o["activationAuthorized"] = false
 if let cur = c.current {
 o["currentSHA256"] = cur.sha
 o["currentAction"] = cur.action
 }
 return o
}
private static func apply(_ c: Ctx) -> Int32 {
 var common = base(c)
 guard let initial = c.current else {
 common["status"] = "NOT_READY"; common["phase"] = "current-missing"
 emit(common); return 3
 }
 guard initial.action == "продолжать" else {
 common["status"] = "BLOCKED"; common["phase"] = "root-control-\(initial.action)"
 emit(common); return 3
 }
 let paths: RPaths
 do { paths = try receiptPaths(config: c.config, oldSHA: c.p.old.sha256,
  candidateSHA: c.p.candidate.sha256) } catch {
  common["status"] = "FAILED"; common["phase"] = "operation-key"
  common["error"] = String(describing: error); emit(common); return 2
 }
 common["operationKey"] = paths.key
 common["intentReceipt"] = paths.intent
 common["outcomeReceipt"] = paths.outcome
 var intent = common
 intent["status"] = "INTENT"; intent["phase"] = "before-effect"
 do { try receipt(paths.intent, intent) } catch {
 var failed = common
 let exists = (error as? E)?.description.hasPrefix("Rexists:") == true
 failed["status"] = exists ? "BLOCKED" : "FAILED"
 failed["phase"] = exists ? "operation-already-reserved" : "intent-receipt"
 failed["automaticRetry"] = false
 failed["error"] = String(describing: error)
 emit(failed); return 2
 }
 var status = "FAILED", phase = "artifact-recheck", boundary = "beforeRename"
 var observed: String?, errorText: String?, temporaryPath: String?
 var code: Int32 = 2
 do {
 let p = try plan(c.planPath, c.planSHA)
 try config(p, c.config)
 let a = try artifacts(p)
 try sys(p.systemEnv)
 phase = "current-lock"
 let result = try ЗамокТекущегоStop.выполнить(p.current.lock) { проверитьЗамок in
  phase = "root-recheck"
  try c.привязкаСсылки.подтвердить()
  let промежуточнаяПривязка = try снимокПривязкиСсылки(a.h)
  let head = промежуточнаяПривязка.идентификаторОбъекта
  let cur = try current(p, a.h, p.header.sha256, head)
  try need(head == c.head && cur?.sha == initial.sha
   && cur?.action == "продолжать", "C5")
  phase = "atomic"
  return try withoutActuallyEscaping(проверитьЗамок) { check in
   var points = ТочкиАтомарнойЗаменыStop()
   points.передRename = {
    try check()
    let конечнаяПривязка = try снимокПривязкиСсылки(a.h)
    let latestHead = конечнаяПривязка.идентификаторОбъекта
    let latest = try current(p, a.h, p.header.sha256, latestHead)
    try c.привязкаСсылки.подтвердить()
    try промежуточнаяПривязка.подтвердить()
    try конечнаяПривязка.подтвердить()
    try need(latestHead == c.head && latest?.sha == initial.sha
     && latest?.action == "продолжать", "C6")
   }
   return try AB.заменить(c.config, ожидаемыйSHA256: p.old.sha256,
    новыми: a.candidate, точки: points)
  }
 }
 status = "APPLIED"; phase = "readback"; boundary = "afterRename"
 observed = result.sha256; code = 0
 } catch let f as ОтказАтомарнойЗаменыStop {
 phase = f.фаза; observed = f.наблюдаемыйSHA256; errorText = f.причина
 temporaryPath = f.оставленныйВременныйФайл
 switch f.граница {
 case .доRename: boundary = "beforeRename"
 case .послеRename: status = "UNKNOWN"; boundary = "afterRename"; code = 4
 }
 if temporaryPath != nil { status = "UNKNOWN"; code = 4 }
 } catch {
 errorText = String(describing: error)
 if phase == "atomic" {
  status = "UNKNOWN"; boundary = "unknown-after-call"; code = 4
 }
 }
 var outcome = common
 outcome["status"] = status; outcome["phase"] = phase; outcome["boundary"] = boundary
 outcome["automaticRetry"] = false; outcome["automaticRollback"] = false
 if let observed { outcome["observedConfigSHA256"] = observed }
 if let errorText { outcome["error"] = errorText }
 if let temporaryPath {
 outcome["temporaryPath"] = temporaryPath
 outcome["temporaryCleanupState"] = "UNKNOWN"
 }
 do { try receipt(paths.outcome, outcome); emit(outcome) } catch {
 var unknown = outcome
 unknown["status"] = "UNKNOWN"; unknown["phase"] = "outcome-receipt"
 unknown["effectStatus"] = status
 unknown["receiptError"] = String(describing: error)
 emit(unknown); return 5
 }
 return code
}
// Вызываемый ROOT publisher. Это единственный предусмотренный здесь писатель current.
// Передача pinned плана не доказывает полномочий или полноты worklist.
private static func publicationInputs(_ path: String, _ sha: String)
 throws -> (Publication, H, Data, СнимокФайловойСсылки) {
 try need(abs(path) && hex(sha, 64), "Ppub0")
 let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
 try need(raw.sha256 == sha, "Ppub1", path)
 let p = try dec(Publication.self, raw.данные)
 try need(p.schema == "fum.stop-current-publication.1" && hex(p.source, 40)
  && (p.initiallyAbsent ? p.expectedSHA256 == nil : hex(p.expectedSHA256 ?? "", 64)),
  "Ppub2", path)
 let h = try dec(H.self, read(p.header, 0o400, 32_768).данные)
 try need(h.схема == "fum.stop-заголовок.2" && uuid(h.задача)
  && token(h.узел) && token(h.область) && token(h.поколение) && ref(h.ref)
  && h.backend == "files" && h.objectFormat == "sha1" && h.исходники == p.source
  && (1...3_600).contains(h.максимальныйВозрастСекунд)
  && [h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
      h.каталогКвитанций].allSatisfy(abs), "Hpub0")
 try need(p.current.path == h.состояние && p.current.mode == 0o600
  && p.current.maxBytes > 0 && p.current.maxBytes <= 32_768
  && p.current.lock.path == p.current.path + ".lock"
  && p.current.lock.device > 0 && p.current.lock.inode > 0
  && p.candidate.path != p.current.path, "Cpub0")
 let candidate = try read(p.candidate, 0o600, p.current.maxBytes).данные
 let привязкаСсылки = try снимокПривязкиСсылки(h)
 let head = привязкаСсылки.идентификаторОбъекта
 _ = try currentBytes(candidate, p.candidate.sha256, h, p.header.sha256, head)
 if p.initiallyAbsent {
  var st = Darwin.stat()
  try need(lstat(p.current.path, &st) != 0 && errno == ENOENT, "Cpub1")
 } else {
  let old = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600,
   предел: p.current.maxBytes)
  try need(old.sha256 == p.expectedSHA256, "Cpub2")
 }
 try привязкаСсылки.подтвердить()
 return (p, h, candidate, привязкаСсылки)
}
private static func publish(_ argv: [String]) throws -> Int32 {
 let (path, sha, mode) = try args(argv)
 let (p, _, _, исходнаяПривязка) = try publicationInputs(path, sha)
 let head = исходнаяПривязка.идентификаторОбъекта
 if case .apply(let value) = mode { try need(value == p.candidate.sha256, "Apub") }
 var common: [String: Any] = ["operation": "publish-current", "planSHA256": sha,
  "rootHEAD": head, "candidateSHA256": p.candidate.sha256,
  "worklistCompleteness": "ROOT_REQUIRED", "acceptedSourceAncestry": "ROOT_REQUIRED",
  "authorityChecked": false, "automaticRetry": false, "automaticRollback": false]
 if case .check = mode {
  let (_, _, _, свежаяПривязка) = try предварительнаяПроверка(p.current.lock) {
   try исходнаяПривязка.подтвердить()
   let результат = try publicationInputs(path, sha)
   try исходнаяПривязка.подтвердить()
   try результат.3.подтвердить()
   return результат
  }
  common["rootHEAD"] = свежаяПривязка.идентификаторОбъекта
  common["status"] = "METADATA_CHECKED"; common["metadataChecked"] = true
  common["writes"] = 0; emit(common); return 0
 }
 let oldKey = p.expectedSHA256 ?? AB.sha256(Data("ABSENT".utf8))
 let paths = try receiptPaths(config: p.current.path, oldSHA: oldKey,
  candidateSHA: p.candidate.sha256, publication: true)
 common["operationKey"] = paths.key
 common["intentReceipt"] = paths.intent; common["outcomeReceipt"] = paths.outcome
 var intent = common; intent["status"] = "INTENT"; intent["phase"] = "before-effect"
 do { try receipt(paths.intent, intent) } catch {
  common["status"] = "BLOCKED"; common["phase"] = "intent-receipt"
  common["error"] = String(describing: error); emit(common); return 2
 }
 var status = "FAILED", phase = "current-lock", boundary = "beforeRename"
 var observed: String?, errorText: String?, temporary: String?
 var code: Int32 = 2
 do {
  let result = try ЗамокТекущегоStop.выполнить(p.current.lock) { check in
   try исходнаяПривязка.подтвердить()
   let (fresh, _, candidate, свежаяПривязка) = try publicationInputs(path, sha)
   try need(свежаяПривязка.идентификаторОбъекта == head, "Gpub")
   phase = "atomic"
   return try withoutActuallyEscaping(check) { verify in
    var points = ТочкиАтомарнойЗаменыStop()
    points.передRename = {
     try verify()
     let (_, _, _, конечнаяПривязка) = try publicationInputs(path, sha)
     try исходнаяПривязка.подтвердить()
     try свежаяПривязка.подтвердить()
     try конечнаяПривязка.подтвердить()
     try need(конечнаяПривязка.идентификаторОбъекта == head, "Gpub2")
    }
    return try AB.записать(fresh.current.path, ожидаемыйSHA256: fresh.expectedSHA256,
     новыми: candidate, точки: points)
   }
  }
  observed = result.sha256; status = "PUBLISHED"; phase = "readback"
  boundary = "afterRename"; code = 0
 } catch let f as ОтказАтомарнойЗаменыStop {
  phase = f.фаза; observed = f.наблюдаемыйSHA256; errorText = f.причина
  temporary = f.оставленныйВременныйФайл
  if f.граница == .послеRename { status = "UNKNOWN"; boundary = "afterRename"; code = 4 }
  if temporary != nil { status = "UNKNOWN"; code = 4 }
 } catch {
  errorText = String(describing: error)
  if phase == "atomic" { status = "UNKNOWN"; boundary = "unknown-after-call"; code = 4 }
 }
 common["status"] = status; common["phase"] = phase; common["boundary"] = boundary
 if let observed { common["observedCurrentSHA256"] = observed }
 if let errorText { common["error"] = errorText }
 if let temporary { common["temporaryPath"] = temporary }
 do { try receipt(paths.outcome, common); emit(common) } catch {
  common["status"] = "UNKNOWN"; common["phase"] = "outcome-receipt"
  common["effectStatus"] = status; common["receiptError"] = String(describing: error)
  emit(common); return 5
 }
 return code
}
public static func команда(_ args: [String]) -> Int32 {
 do {
 if args.first == "--опубликовать-текущий" { return try publish(Array(args.dropFirst())) }
 let (c, mode) = try load(args)
 switch mode {
 case .check:
  let (fresh, _) = try предварительнаяПроверка(c.p.current.lock) {
   try c.привязкаСсылки.подтвердить()
   let результат = try load(args)
   try c.привязкаСсылки.подтвердить()
   try результат.0.привязкаСсылки.подтвердить()
   return результат
  }
  var o = base(fresh)
  let checked = fresh.current?.action == "продолжать"
  o["status"] = fresh.current == nil ? "UNKNOWN" : (checked ? "METADATA_CHECKED" : "BLOCKED")
  o["metadataChecked"] = checked; o["writes"] = 0
  emit(o); return checked ? 0 : 3
 case .apply:
  return apply(c)
 }
 } catch {
 emit(["status": "FAILED", "writes": 0, "error": String(describing: error)])
 return 2
 }
}
}
private extension Array {
subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
