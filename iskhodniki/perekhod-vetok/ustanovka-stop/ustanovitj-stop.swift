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
        точки: ТочкиАтомарнойЗаменыStop, сохранятьВременный: Bool = false,
        проверить: () throws -> Void = {}, отметить: (String) throws -> Void = { _ in }) throws -> СнимокБайтовStop {
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
            try проверить(); try отметить(фаза)
                let snapshot = try снять(oldFD, p, имя, 0o600, пределЗамены)
                old = snapshot; наблюдаемый = snapshot.sha256
                фаза = "ожидаемый-SHA"
            try проверить(); try отметить(фаза)
                try нужно(snapshot.sha256 == ожидаемыйSHA256)
            } else {
                фаза = "ожидаемое-отсутствие"
            try проверить(); try отметить(фаза)
                var named = Darwin.stat()
                try нужно(fstatat(p, имя, &named, AT_SYMLINK_NOFOLLOW) != 0 && errno == ENOENT)
            }
            фаза = "создание-временного"
            try проверить(); try отметить(фаза)
            temp = ".fum-stop-" + UUID().uuidString.lowercased() + ".tmp"
            tempFD = openat(p, temp, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            try нужно(tempFD >= 0)
            try нужно(fchmod(tempFD, 0o600) == 0)
            фаза = "запись-временного"
            try проверить(); try отметить(фаза)
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
            try проверить(); try отметить(фаза)
            try точки.синхронизацияФайла(tempFD)
            фаза = "перед-rename"
            try проверить(); try отметить(фаза)
            try точки.передRename?()
            фаза = "сверка-родителя"
            try проверить(); try отметить(фаза)
            let (againP, againName) = try родитель(путь); defer { Darwin.close(againP) }
            var a = Darwin.stat(), b = Darwin.stat()
            try нужно(имя == againName && fstat(p, &a) == 0 && fstat(againP, &b) == 0
                      && a.st_dev == b.st_dev && a.st_ino == b.st_ino)
            фаза = "сверка-старого"
            try проверить(); try отметить(фаза)
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
            try проверить(); try отметить(фаза)
            let prepared = try снять(tempFD, p, temp, 0o600, пределЗамены)
            try нужно(prepared.данные == данные)
            фаза = "rename"
            try проверить(); try отметить(фаза)
            let moved = ожидаемыйSHA256 == nil
                ? renameatx_np(p, temp, p, имя, UInt32(RENAME_EXCL))
                : renameat(p, temp, p, имя)
            guard moved == 0 else { throw СбойБайтовStop.система(errno) }
            renamed = true
            наблюдаемый = nil // Старое наблюдение не описывает состояние после эффекта.
            try отметить("после-rename"); try проверить()
            фаза = "fsync-каталога"
            try проверить(); try отметить(фаза)
            try точки.синхронизацияКаталога(p)
            фаза = "readback"
            try проверить(); try отметить(фаза)
            let result = try снятьИмя(p, имя)
            наблюдаемый = result.sha256
            try нужно(result.данные == данные
                      && result.отпечаток.устройство == prepared.отпечаток.устройство
                      && result.отпечаток.inode == prepared.отпечаток.inode)
            try отметить("после-readback"); try проверить()
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
                if !отсутствует && (сохранятьВременный || !(наш && unlinkat(p, temp, 0) == 0)) {
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
        let удержанныйЗамок = try УдерживаемыйЗамокСтоп.открыть(pin)
        defer { удержанныйЗамок.закрыть() }
        return try действие(удержанныйЗамок.проверить)
    }
}
fileprivate final class УдерживаемыйЗамокСтоп {
    private var fd: Int32
    private var dir: Int32
    private let pin: СсылкаЗамкаStop
    private let name: String
    private let устройствоРодителя: dev_t
    private let номерУзлаРодителя: ino_t
    private init(fd: Int32, dir: Int32, pin: СсылкаЗамкаStop, name: String, parent: Darwin.stat) {
        self.fd = fd; self.dir = dir; self.pin = pin; self.name = name
        устройствоРодителя = parent.st_dev; номерУзлаРодителя = parent.st_ino
    }
    static func открыть(_ pin: СсылкаЗамкаStop) throws -> УдерживаемыйЗамокСтоп {
        guard pin.device > 0, pin.inode > 0 else { throw E("L0") }
        let (dir, name) = try АтомарныеБайтыStop.родитель(pin.path)
        var parent = Darwin.stat()
        guard fstat(dir, &parent) == 0, parent.st_mode & 0o7777 == 0o700 else {
            _ = Darwin.close(dir)
            throw E("L1", pin.path)
        }
        let fd = openat(dir, name, O_RDWR | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { _ = Darwin.close(dir); throw E("L2", pin.path) }
        let новыйУдержанныйЗамок = УдерживаемыйЗамокСтоп(fd: fd, dir: dir, pin: pin, name: name, parent: parent)
        do {
            try новыйУдержанныйЗамок.проверить()
            guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw E("Lbusy", pin.path) }
            try новыйУдержанныйЗамок.проверить()
            return новыйУдержанныйЗамок
        } catch { новыйУдержанныйЗамок.закрыть(); throw error }
    }
    func проверить() throws {
            guard fd >= 0, dir >= 0 else { throw E("Lclosed", pin.path) }
            let (again, againName) = try АтомарныеБайтыStop.родитель(pin.path)
            defer { _ = Darwin.close(again) }
            var a = Darwin.stat(), named = Darwin.stat(), p = Darwin.stat()
            guard againName == name, fstat(again, &p) == 0,
                p.st_dev == устройствоРодителя, p.st_ino == номерУзлаРодителя,
                p.st_mode & 0o7777 == 0o700,
                fstat(fd, &a) == 0, fstatat(dir, name, &named, AT_SYMLINK_NOFOLLOW) == 0,
                a.st_mode & S_IFMT == S_IFREG, a.st_mode & 0o7777 == 0o600,
                a.st_uid == geteuid(), a.st_nlink == 1, a.st_size == 0,
                Int64(a.st_dev) == pin.device, UInt64(a.st_ino) == pin.inode,
                ОтпечатокФайлаStop(a) == ОтпечатокФайлаStop(named) else {
                throw E("L3", pin.path)
            }
    }
    func закрыть() {
        if fd >= 0 { _ = Darwin.close(fd); fd = -1 }
        if dir >= 0 { _ = Darwin.close(dir); dir = -1 }
    }
    deinit { закрыть() }
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
private struct Pin: Codable { let path: String; let bytes: Int; let sha256: String; let mode: UInt32 }
private struct Old: Codable {
let path: String; let bytes: Int; let sha256, commandSHA256: String
let tokenOffset, tokenBytes: Int; let mode: UInt32
}
private struct Cmd: Codable { let argv, launcherArgv: [String]; let text: String }
private struct Env: Codable {
let clear: Bool; let only: [String: String]; let resourceBundleOverridesAbsent: Bool
}
private struct Sys: Codable {
let path: String; let bytes: Int; let sha256: String
let uid: UInt32; let nlink: UInt64; let mode: UInt32
}
private struct MPin: Codable {
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
// Отдельный closed-wire вход. Legacy Plan намеренно остаётся Decodable.
private struct ПривязкаТекущегоV4: Codable {
 let путь: String; let пределБайт: Int; let режим: UInt32
 let замок: СсылкаЗамкаStop; let ожидаемыйSHA256: String
 enum CodingKeys: String, CodingKey {
  case путь = "path", пределБайт = "maxBytes", режим = "mode"
  case замок = "lock", ожидаемыйSHA256 = "expectedSHA256"
 }
}
private struct ПланУстановкиV4: Codable {
 let схема, профиль, исходники, исходнаяБазаC3, деревоИсходников: String
 let заголовок, кандидат, обработчик: Pin; let прежнийКонфиг: Old; let команда: Cmd
 let окружение: Env; let системноеОкружение: Sys; let манифестСтадии: MPin
 let текущее: ПривязкаТекущегоV4
 enum CodingKeys: String, CodingKey {
  case схема = "schema", профиль = "profile", исходники = "source"
  case исходнаяБазаC3 = "sourceOriginC3", деревоИсходников = "sourceTree"
  case заголовок = "header", кандидат = "candidate", обработчик = "handler"
  case прежнийКонфиг = "old", команда = "command", окружение = "environment"
  case системноеОкружение = "systemEnv", манифестСтадии = "stageManifest", текущее = "current"
 }
}
private struct АртефактыУстановкиV4 {
 let заголовок: КорневойДопускStopV4.Заголовок; let кандидат: Data; let команда: String
}
private struct КонтекстУстановкиV4 {
 let путьПлана, хэшПлана, путьКонфига: String; let план: ПланУстановкиV4
 let факты: ОбщаяПубликацияДопускаStopV4.ФактыУстановки?
}
private enum ПолитикаВременногоФайлаКонфигурацииStop {
 case прежняяОчистка, сохранитьДляРазбора
}
private struct ПодготовленныйЭффектКонфигурацииStop {
 let замок: СсылкаЗамкаStop; let кандидат: Data
 let политикаВременного: ПолитикаВременногоФайлаКонфигурацииStop
 let проверить: (_ замок: () throws -> Void) throws -> Void
 let передRename: (_ замок: () throws -> Void) throws -> Void
}
// Internal только для существующих тестовых targets. Production CLI не принимает host override.
struct ХостКонфигурацииStop {
 let домашнийКаталог: String
 var путьКонфига: String { домашнийКаталог + "/.codex/hooks.json" }
 static func текущий() throws -> Self {
  guard let pw = getpwuid(geteuid()), let home = pw.pointee.pw_dir else { throw E("U0") }
  return Self(домашнийКаталог: String(cString: home))
 }
}
struct ТочкиКонфигурацииStop {
 var послеНачальнойПроверки: (() throws -> Void)? = nil
 var послеНамерения: (() throws -> Void)? = nil
 var передRename: (() throws -> Void)? = nil
 var синхронизацияКаталога: ((Int32) throws -> Void)? = nil
}
struct РезультатКонфигурацииStop {
 let код: Int32; let вывод: [String: Any]
}
private struct H: Decodable {
let схема, задача, узел, область, поколение, cwd, дерево, ref: String
let gitDir, commonGitDir, backend, objectFormat, исходники: String
let состояние, каталогКвитанций: String; let максимальныйВозрастСекунд: Int64
let состояниеV2: String?
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
private static func выбранПланУстановкиV4(_ path: String, _ sha: String) throws -> Bool {
 struct ВерсияПлана: Decodable {
  let схема, профиль: String
  enum CodingKeys: String, CodingKey { case схема = "schema", профиль = "profile" }
 }
 try need(abs(path) && hex(sha, 64), "P2", path)
 let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
 try need(raw.sha256 == sha, "P3", path)
 let tag = try dec(ВерсияПлана.self, raw.данные)
 if tag.схема == "fum.stop-installer-plan.4" && tag.профиль == "fum.native-stop.install.4" { return true }
 try need(tag.схема == "fum.stop-installer-plan.3" && tag.профиль == "fum.native-stop.install.1", "P4", path)
 return false
}
private static func прочитатьПланУстановкиV4(_ path: String, _ sha: String) throws -> ПланУстановкиV4 {
 try need(abs(path) && hex(sha, 64), "P2", path)
 let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
 try need(raw.sha256 == sha, "P3", path)
 let p = try КорневойДопускStopV4.разобрать(ПланУстановкиV4.self, из: raw.данные, предел: 65_536)
 try need(p.схема == "fum.stop-installer-plan.4" && p.профиль == "fum.native-stop.install.4"
  && hex(p.исходники, 40) && hex(p.исходнаяБазаC3, 40) && hex(p.деревоИсходников, 40), "P4", path)
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
 try need(["fum.stop-заголовок.2", "fum.stop-заголовок.3"].contains(h.схема) && uuid(h.задача)
 && token(h.узел) && token(h.область) && token(h.поколение) && ref(h.ref)
 && h.backend == "files" && h.objectFormat == "sha1"
 && h.исходники == p.source && hex(h.исходники, 40)
 && (1...3_600).contains(h.максимальныйВозрастСекунд), "H0")
 try need([h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
 h.каталогКвитанций].allSatisfy(abs), "H1")
 if h.схема == "fum.stop-заголовок.3" {
  try need(h.состояниеV2.map { abs($0) && $0 != h.состояние } == true, "HversionedState")
  guard let прежнее = h.состояниеV2 else { throw E("HversionedState") }
  try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
   состояниеV2: прежнее, состояниеV3: h.состояние,
   допускаетсяОтсутствиеV3: true).подтвердить()
 }
 try need(p.current.path == h.состояние && p.current.mode == 0o600
 && p.current.maxBytes > 0 && p.current.maxBytes <= 32_768
 && p.current.lock.path == h.состояние + ".lock"
 && p.current.lock.device > 0 && p.current.lock.inode > 0, "C0")
 try need(p.command.argv.count == 18 && p.command.argv[0] == p.handler.path
 && p.command.argv[1] == "stop", "A4")
 let профильНаблюдений = h.схема == "fum.stop-заголовок.3"
  ? "fum.текущие-обязательства-stop.3" : "fum.текущие-обязательства-stop.2"
 let expected = ["--идентификатор-обработчика", "fum.stop-handler.1",
 "--codex-thread-id", h.задача, "--идентификатор-узла", h.узел,
 "--ожидаемый-cwd", h.cwd, "--состояние", h.состояние,
 "--профиль-наблюдений", профильНаблюдений,
 "--заголовок", p.header.path, "--хэш-заголовка", p.header.sha256]
 let value = command(p.command.argv)
 try need(Array(p.command.argv.dropFirst(2)) == expected && p.command.text == value
 && p.command.launcherArgv == ["/usr/bin/env", "-i", "PATH="] + p.command.argv
 && p.environment.clear && p.environment.only == ["PATH": ""]
 && p.environment.resourceBundleOverridesAbsent, "A5")
 return value
}
private static func stage(_ p: Plan) throws {
 try stage(p.stageManifest, handler: p.handler)
}
private static func stage(_ pin: MPin, handler: Pin) throws {
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
  try need(path == handler.path && f.bytes == handler.bytes
  && f.sha256 == handler.sha256 && handler.mode == 0o500, "S5", path)
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
 _ headerSHA: String, _ head: String, clock: Int64? = nil) throws -> Cur {
 let e = try dec(Envelope.self, bytes)
 let версияСнимка = h.схема == "fum.stop-заголовок.3"
  ? "fum.текущие-обязательства-stop.3" : "fum.текущие-обязательства-stop.2"
 try need(e.схема == версияСнимка
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
 let clock = clock ?? Int64(Date().timeIntervalSince1970), age = h.максимальныйВозрастСекунд
 try need(m.выпущен >= 0 && m.выпущен <= clock && clock - m.выпущен <= age
 && m.действуетДо >= clock && m.действуетДо >= m.выпущен
 && m.действуетДо - m.выпущен <= age, "C4", h.состояние)
 return state
}
private static func config(_ p: Plan, _ path: String) throws {
 try config(p.old, path)
}
private static func config(_ old: Old, _ path: String) throws {
 try need(old.path == path && old.mode == 0o600 && old.bytes >= 0
 && old.bytes <= 1_048_576 && hex(old.sha256, 64)
 && hex(old.commandSHA256, 64), "F2", path)
}
private static func load(_ argv: [String], host: ХостКонфигурацииStop? = nil) throws -> (Ctx, M) {
 let (planPath, planSHA, mode) = try args(argv)
 let p = try plan(planPath, planSHA)
 let path = try (host ?? ХостКонфигурацииStop.текущий()).путьКонфига
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
private static func проверитьАртефактыУстановкиV4(_ p: ПланУстановкиV4) throws -> АртефактыУстановкиV4 {
 let raw = try read(p.заголовок, 0o400, 32_768)
 let h = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
  из: raw.данные, предел: 32_768)
 try КорневойДопускStopV4.проверитьЗаголовок(h)
 try need(h.исходники == p.исходники && p.текущее.путь == h.состояние
  && p.текущее.режим == 0o600 && p.текущее.пределБайт > 0 && p.текущее.пределБайт <= 65_536
  && hex(p.текущее.ожидаемыйSHA256, 64) && p.текущее.замок.path == h.замок.path
  && p.текущее.замок.device == h.замок.device && p.текущее.замок.inode == h.замок.inode, "C0V4")
 let expected = [p.обработчик.path, "stop", "--идентификатор-обработчика", "fum.stop-handler.1",
  "--codex-thread-id", h.задача, "--идентификатор-узла", h.узел,
  "--ожидаемый-cwd", h.рабочийКаталог, "--состояние", h.состояние,
  "--профиль-наблюдений", "fum.текущие-обязательства-stop.4",
  "--заголовок", p.заголовок.path, "--хэш-заголовка", p.заголовок.sha256]
 let cmd = command(expected)
 try need(p.команда.argv == expected && p.команда.text == cmd
  && p.команда.launcherArgv == ["/usr/bin/env", "-i", "PATH="] + expected
  && p.окружение.clear && p.окружение.only == ["PATH": ""]
  && p.окружение.resourceBundleOverridesAbsent, "A5V4")
 let candidate = try read(p.кандидат, 0o600, 1_048_576)
 try stage(p.манифестСтадии, handler: p.обработчик)
 return АртефактыУстановкиV4(заголовок: h, кандидат: candidate.данные, команда: cmd)
}
private static func прочитатьУстановкуV4ПодЗамком(_ argv: [String], host: ХостКонфигурацииStop,
 lock: СсылкаЗамкаStop, check: () throws -> Void) throws -> (КонтекстУстановкиV4, АртефактыУстановкиV4) {
 try check()
 let (path, sha, mode) = try args(argv)
 let p = try прочитатьПланУстановкиV4(path, sha)
 try need(p.текущее.замок.path == lock.path && p.текущее.замок.device == lock.device
  && p.текущее.замок.inode == lock.inode, "LplanV4")
 try config(p.прежнийКонфиг, host.путьКонфига)
 if case .apply(let candidateSHA) = mode { try need(candidateSHA == p.кандидат.sha256, "A6") }
 let a = try проверитьАртефактыУстановкиV4(p)
 try sys(p.системноеОкружение)
 let old = try AB.прочитать(host.путьКонфига, ожидаемыйРежим: 0o600, предел: p.прежнийКонфиг.bytes)
 try need(old.данные.count == p.прежнийКонфиг.bytes && old.sha256 == p.прежнийКонфиг.sha256, "F3", host.путьКонфига)
 try проверитьДельту(old: old.данные, candidate: a.кандидат,
  offset: p.прежнийКонфиг.tokenOffset, length: p.прежнийКонфиг.tokenBytes,
  oldCommandSHA256: p.прежнийКонфиг.commandSHA256, newCommand: a.команда)
 let facts = try ОбщаяПубликацияДопускаStopV4.проверитьДляУстановки(a.заголовок,
  путьЗаголовка: p.заголовок.path, хэшЗаголовка: p.заголовок.sha256,
  ожидаемыйХэшТекущего: p.текущее.ожидаемыйSHA256, пределТекущего: p.текущее.пределБайт,
  проверитьЗамок: check)
 try check()
 return (КонтекстУстановкиV4(путьПлана: path, хэшПлана: sha, путьКонфига: host.путьКонфига, план: p, факты: facts), a)
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
private static func apply(_ c: Ctx, points: ТочкиКонфигурацииStop,
 emit: ([String: Any]) -> Void) -> Int32 {
 применитьКонфигурацию(common: base(c), configPath: c.config, oldSHA: c.p.old.sha256,
  candidateSHA: c.p.candidate.sha256, initialCurrent: c.current, points: points, emit: emit) {
  let p = try plan(c.planPath, c.planSHA)
  try config(p, c.config)
  let a = try artifacts(p)
  try sys(p.systemEnv)
  var промежуточнаяПривязка: СнимокФайловойСсылки?
  return ПодготовленныйЭффектКонфигурацииStop(замок: p.current.lock, кандидат: a.candidate,
   политикаВременного: .прежняяОчистка,
   проверить: { _ in
    try c.привязкаСсылки.подтвердить()
    let привязка = try снимокПривязкиСсылки(a.h)
    let cur = try current(p, a.h, p.header.sha256, привязка.идентификаторОбъекта)
    try need(привязка.идентификаторОбъекта == c.head && cur?.sha == c.current?.sha
     && cur?.action == "продолжать", "C5")
    промежуточнаяПривязка = привязка
   }, передRename: { _ in
    guard let промежуточнаяПривязка else { throw E("C5") }
    let конечнаяПривязка = try снимокПривязкиСсылки(a.h)
    let head = конечнаяПривязка.идентификаторОбъекта
    let cur = try current(p, a.h, p.header.sha256, head)
    try c.привязкаСсылки.подтвердить()
    try промежуточнаяПривязка.подтвердить()
    try конечнаяПривязка.подтвердить()
    try need(head == c.head && cur?.sha == c.current?.sha
     && cur?.action == "продолжать", "C6")
   })
 }
}
private static func применитьКонфигурацию(common initialOutput: [String: Any], configPath: String,
 oldSHA: String, candidateSHA: String, initialCurrent: Cur?, points hooks: ТочкиКонфигурацииStop,
 emit: ([String: Any]) -> Void,
 prepare: () throws -> ПодготовленныйЭффектКонфигурацииStop) -> Int32 {
 var common = initialOutput
 guard let initial = initialCurrent else {
 common["status"] = "NOT_READY"; common["phase"] = "current-missing"
 emit(common); return 3
 }
 guard initial.action == "продолжать" else {
 common["status"] = "BLOCKED"; common["phase"] = "root-control-\(initial.action)"
 emit(common); return 3
 }
 let paths: RPaths
 do { paths = try receiptPaths(config: configPath, oldSHA: oldSHA,
  candidateSHA: candidateSHA) } catch {
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
 try hooks.послеНамерения?()
 let prepared = try prepare()
 phase = "current-lock"
 let result = try ЗамокТекущегоStop.выполнить(prepared.замок) { проверитьЗамок in
  phase = "root-recheck"
  try проверитьЗамок()
  try prepared.проверить(проверитьЗамок)
  phase = "atomic"
  return try withoutActuallyEscaping(проверитьЗамок) { check in
   var points = ТочкиАтомарнойЗаменыStop()
   points.передRename = {
    try check()
    try hooks.передRename?()
    try prepared.передRename(check)
    try check()
   }
   if let sync = hooks.синхронизацияКаталога { points.синхронизацияКаталога = sync }
   switch prepared.политикаВременного {
   case .прежняяОчистка:
    // Прежний путь2/3 и его доказанная own-temp cleanup семантика неизменны.
    return try AB.заменить(configPath, ожидаемыйSHA256: oldSHA,
     новыми: prepared.кандидат, точки: points)
   case .сохранитьДляРазбора:
    // Только новая V4 операция явно opt-in: pre-rename temp не удаляется.
    return try AB.записать(configPath, ожидаемыйSHA256: oldSHA,
     новыми: prepared.кандидат, точки: points, сохранятьВременный: true)
   }
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
 throws -> (Publication, H, Data, СнимокФайловойСсылки?) {
 try need(abs(path) && hex(sha, 64), "Ppub0")
 let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
 try need(raw.sha256 == sha, "Ppub1", path)
 let p = try dec(Publication.self, raw.данные)
 try need(p.schema == "fum.stop-current-publication.1" && hex(p.source, 40)
  && (p.initiallyAbsent ? p.expectedSHA256 == nil : hex(p.expectedSHA256 ?? "", 64)),
  "Ppub2", path)
 let h = try dec(H.self, read(p.header, 0o400, 32_768).данные)
 try need(["fum.stop-заголовок.2", "fum.stop-заголовок.3"].contains(h.схема) && uuid(h.задача)
  && token(h.узел) && token(h.область) && token(h.поколение) && ref(h.ref)
  && h.backend == "files" && h.objectFormat == "sha1" && h.исходники == p.source
  && (1...3_600).contains(h.максимальныйВозрастСекунд)
  && [h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние,
      h.каталогКвитанций].allSatisfy(abs), "Hpub0")
 let разделение: СнимокРазделенияСостоянийStop?
 if h.схема == "fum.stop-заголовок.3" {
  guard let прежнее = h.состояниеV2, abs(прежнее), прежнее != h.состояние
  else { throw E("HpubVersionedState") }
  разделение = try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
   состояниеV2: прежнее, состояниеV3: h.состояние,
   допускаетсяОтсутствиеV3: p.initiallyAbsent)
 } else { разделение = nil }
 try need(p.current.path == h.состояние && p.current.mode == 0o600
  && p.current.maxBytes > 0 && p.current.maxBytes <= 32_768
  && p.current.lock.path == p.current.path + ".lock"
  && p.current.lock.device > 0 && p.current.lock.inode > 0
  && p.candidate.path != p.current.path, "Cpub0")
 let candidate = try read(p.candidate, 0o600, p.current.maxBytes).данные
 let конверт = try проверитьСвязанныйКонверт(candidate, h, p.header.sha256)
 let привязкаСсылки: СнимокФайловойСсылки?
 if конверт.управление.действие == "продолжать" {
  let снимок = try снимокПривязкиСсылки(h)
  _ = try currentBytes(candidate, p.candidate.sha256, h, p.header.sha256, снимок.идентификаторОбъекта)
  привязкаСсылки = снимок
 } else { привязкаСсылки = nil } // Явный доверенный STOP/пауза не зависит от Git и возраста worklist.
 if p.initiallyAbsent {
  var st = Darwin.stat()
  try need(lstat(p.current.path, &st) != 0 && errno == ENOENT, "Cpub1")
 } else {
  let old = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600,
   предел: p.current.maxBytes)
  try need(old.sha256 == p.expectedSHA256, "Cpub2")
 }
 try привязкаСсылки?.подтвердить()
 try разделение?.подтвердить()
 return (p, h, candidate, привязкаСсылки)
}
private static func publish(_ argv: [String]) throws -> Int32 {
 let (path, sha, mode) = try args(argv)
 let (p, _, _, исходнаяПривязка) = try publicationInputs(path, sha)
 let head = исходнаяПривязка?.идентификаторОбъекта
 if case .apply(let value) = mode { try need(value == p.candidate.sha256, "Apub") }
 var common: [String: Any] = ["operation": "publish-current", "planSHA256": sha,
  "candidateSHA256": p.candidate.sha256,
  "worklistCompleteness": "ROOT_REQUIRED", "acceptedSourceAncestry": "ROOT_REQUIRED",
  "authorityChecked": false, "automaticRetry": false, "automaticRollback": false]
 if let head { common["rootHEAD"] = head }
 if case .check = mode {
  let (_, _, _, свежаяПривязка) = try предварительнаяПроверка(p.current.lock) {
   try исходнаяПривязка?.подтвердить()
   let результат = try publicationInputs(path, sha)
   try исходнаяПривязка?.подтвердить()
   try результат.3?.подтвердить()
   return результат
  }
  if let свежаяВершина = свежаяПривязка?.идентификаторОбъекта {
   common["rootHEAD"] = свежаяВершина
  } else { common.removeValue(forKey: "rootHEAD") }
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
   try исходнаяПривязка?.подтвердить()
   let (fresh, _, candidate, свежаяПривязка) = try publicationInputs(path, sha)
   try need(свежаяПривязка?.идентификаторОбъекта == head, "Gpub")
   phase = "atomic"
   return try withoutActuallyEscaping(check) { verify in
    var points = ТочкиАтомарнойЗаменыStop()
    points.передRename = {
     try verify()
     let (_, _, _, конечнаяПривязка) = try publicationInputs(path, sha)
     try исходнаяПривязка?.подтвердить()
     try свежаяПривязка?.подтвердить()
     try конечнаяПривязка?.подтвердить()
     try need(конечнаяПривязка?.идентификаторОбъекта == head, "Gpub2")
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
private static func основаниеВыводаУстановкиV4(_ c: КонтекстУстановкиV4) -> [String: Any] {
 var o: [String: Any] = ["planSHA256": c.хэшПлана, "candidateSHA256": c.план.кандидат.sha256,
  "externalApprovalRequired": true, "worklistCompleteness": "ROOT_REQUIRED",
  "acceptedSourceAncestry": "ROOT_REQUIRED", "activationAuthorized": false]
 if let f = c.факты {
  o["rootHEAD"] = f.голова; o["currentSHA256"] = f.хэшТекущего; o["currentAction"] = f.управление
 }
 return o
}
private static func выполнитьУстановкуV4(_ argv: [String], host: ХостКонфигурацииStop,
 points: ТочкиКонфигурацииStop, emit: ([String: Any]) -> Void) throws -> Int32 {
 let (path, sha, mode) = try args(argv)
 let p = try прочитатьПланУстановкиV4(path, sha)
 try config(p.прежнийКонфиг, host.путьКонфига)
 let selection = try проверитьАртефактыУстановкиV4(p)
 let lock = selection.заголовок.замок
 let (c, _) = try ЗамокТекущегоStop.выполнить(lock) { check in
  try прочитатьУстановкуV4ПодЗамком(argv, host: host, lock: lock, check: check)
 }
 switch mode {
 case .check:
  var o = основаниеВыводаУстановкиV4(c)
  let ready = c.факты?.управление == "продолжать"
  o["status"] = c.факты == nil ? "UNKNOWN" : (ready ? "METADATA_CHECKED" : "BLOCKED")
  o["metadataChecked"] = ready; o["writes"] = 0
  emit(o); return ready ? 0 : 3
 case .apply:
  try points.послеНачальнойПроверки?()
  let cur = c.факты.map { Cur(sha: $0.хэшТекущего, action: $0.управление) }
  return применитьКонфигурацию(common: основаниеВыводаУстановкиV4(c), configPath: c.путьКонфига, oldSHA: c.план.прежнийКонфиг.sha256,
   candidateSHA: c.план.кандидат.sha256, initialCurrent: cur, points: points, emit: emit) {
   let freshPlan = try прочитатьПланУстановкиV4(c.путьПлана, c.хэшПлана)
   try config(freshPlan.прежнийКонфиг, c.путьКонфига)
   let a = try проверитьАртефактыУстановкиV4(freshPlan)
   try sys(freshPlan.системноеОкружение)
   var middle: ОбщаяПубликацияДопускаStopV4.ФактыУстановки?
   return ПодготовленныйЭффектКонфигурацииStop(замок: freshPlan.текущее.замок, кандидат: a.кандидат,
    политикаВременного: .сохранитьДляРазбора,
    проверить: { check in
     try c.факты?.подтвердить()
     let (fresh, _) = try прочитатьУстановкуV4ПодЗамком(argv, host: host, lock: lock, check: check)
     guard let f = fresh.факты, let initial = c.факты,
       f.голова == initial.голова, f.хэшТекущего == initial.хэшТекущего,
       f.управление == "продолжать" else { throw E("C5V4") }
     middle = f
    }, передRename: { check in
     try c.факты?.подтвердить()
     guard let middle else { throw E("C5V4") }
     try middle.подтвердить()
     let (fresh, _) = try прочитатьУстановкуV4ПодЗамком(argv, host: host, lock: lock, check: check)
     guard let f = fresh.факты, let initial = c.факты,
       f.голова == initial.голова, f.хэшТекущего == initial.хэшТекущего,
       f.управление == "продолжать" else { throw E("C6V4") }
     try f.подтвердить(); try check()
    })
  }
 }
}
private static func выполнитьКомандуКонфигурации(_ argv: [String], host: ХостКонфигурацииStop?,
 points: ТочкиКонфигурацииStop, emit: ([String: Any]) -> Void) -> Int32 {
 do {
  let (path, sha, _) = try args(argv)
  if try выбранПланУстановкиV4(path, sha) {
   return try выполнитьУстановкуV4(argv, host: host ?? ХостКонфигурацииStop.текущий(),
    points: points, emit: emit)
  }
  let (c, mode) = try load(argv, host: host)
  switch mode {
  case .check:
   let (fresh, _) = try предварительнаяПроверка(c.p.current.lock) {
    try c.привязкаСсылки.подтвердить()
    let result = try load(argv, host: host)
    try c.привязкаСсылки.подтвердить()
    try result.0.привязкаСсылки.подтвердить()
    return result
   }
   var o = base(fresh)
   let checked = fresh.current?.action == "продолжать"
   o["status"] = fresh.current == nil ? "UNKNOWN" : (checked ? "METADATA_CHECKED" : "BLOCKED")
   o["metadataChecked"] = checked; o["writes"] = 0
   emit(o); return checked ? 0 : 3
  case .apply:
   try points.послеНачальнойПроверки?()
   return apply(c, points: points, emit: emit)
  }
 } catch {
  emit(["status": "FAILED", "writes": 0, "error": String(describing: error)])
  return 2
 }
}
// Та же orchestration, без публичного CLI override и без обращения к Native config.
static func конфигурацияВКонтексте(_ argv: [String], host: ХостКонфигурацииStop,
 точки: ТочкиКонфигурацииStop = ТочкиКонфигурацииStop()) -> РезультатКонфигурацииStop {
 var output: [String: Any] = [:]
 let code = выполнитьКомандуКонфигурации(argv, host: host, points: точки) { output = $0 }
 return РезультатКонфигурацииStop(код: code, вывод: output)
}
public static func команда(_ args: [String]) -> Int32 {
 do {
 if args.first == "--передать-вход-издателя" { return try опубликоватьВходИздателя(Array(args.dropFirst())) }
 if args.first == "--опубликовать-допуск-v4" { return ОбщаяПубликацияДопускаStopV4.выполнитьКоманду(Array(args.dropFirst())) }
 if args.first == "--опубликовать-текущий" { return try publish(Array(args.dropFirst())) }
 return выполнитьКомандуКонфигурации(args, host: nil, points: ТочкиКонфигурацииStop(), emit: emit)
 } catch {
 emit(["status": "FAILED", "writes": 0, "error": String(describing: error)])
 return 2
 }
}
}
private extension Array {
subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}


// Стабильный якорь и отдельный подписанный допуск V4.
// Эти чистые типы не устанавливают доверие Native и не выдают claim.
public enum КорневойДопускStopV4 {
    public enum Отказ: Error, Sendable {
        case формат, идентичность, подпись, срок, файл, цепь, синхронизация, публикация
    }
    public struct Каталог: Codable, Sendable {
        public let путь: String
        public let устройство: UInt64
        public let индексныйУзел: UInt64
    }
    public struct Ссылка: Codable, Sendable {
        public let путь, хэш: String
        enum CodingKeys: String, CodingKey { case путь; case хэш = "sha256" }
    }
    public struct Заголовок: Codable, Sendable {
        public let схема, корень, задача, узел, область, поколение: String
        public let рабочийКаталог, дерево, ссылка, каталогХранилища, общийКаталогХранилища: String
        public let типХранилища, форматОбъектов, исходники: String
        public let состояние, состояниеV2, состояниеV3: String
        public let ключКорня, хэшКлючаКорня, хэшПринятияКлюча, эпоха: String
        public let максимальныйВозрастСекунд, максимальныйСрокСекунд: Int64
        public let максимальныйНомер, максимальнаяПубликация: UInt64
        public let каталогСнимков, каталогПринятыхДопусков, каталогЗахватов, каталогКвитанций: Каталог
        public let замок: СсылкаЗамкаStop
        enum CodingKeys: String, CodingKey {
            case схема, корень, задача, узел, область, поколение, дерево, исходники
            case рабочийКаталог = "cwd", ссылка = "ref", каталогХранилища = "gitDir"
            case общийКаталогХранилища = "commonGitDir", типХранилища = "backend"
            case форматОбъектов = "objectFormat"
            case состояние, состояниеV2, состояниеV3, эпоха, максимальныйВозрастСекунд
            case ключКорня = "ключROOTBase64", хэшКлючаКорня = "ключROOTSHA256"
            case хэшПринятияКлюча = "принятиеКлючаSHA256"
            case максимальныйСрокСекунд = "максимальныйLeaseСекунд"
            case максимальныйНомер, максимальнаяПубликация
            case каталогСнимков, каталогПринятыхДопусков, каталогЗахватов, каталогКвитанций, замок
        }
    }
    public struct Нагрузка: Codable, Sendable {
        public let схема, корень, хэшПринятияКлюча, хэшЗаголовка: String
        public let задача, узел, область, поколение, исходники, голова: String
        public let хэшНаблюдения, хэшСнимка, имяСнимка, эпоха, операция: String
        public let хэшКорневогоДопуска, вид, пункт, следующаяРабота: String
        public let публикация, номер, редакция: UInt64
        public let выдан, действуетДо: Int64
        public let предыдущийДопуск, предыдущаяОперация: String?
        public let прогресс: Ссылка?
        enum CodingKeys: String, CodingKey {
            case схема, корень, задача, узел, область, поколение, исходники
            case хэшПринятияКлюча = "принятиеКлючаSHA256", хэшЗаголовка = "заголовокSHA256"
            case голова = "HEAD", хэшНаблюдения = "наблюдениеSHA256"
            case хэшСнимка = "снимокSHA256", имяСнимка = "снимокИмя"
            case эпоха, операция, вид, пункт, следующаяРабота, публикация, номер, редакция, выдан, действуетДо
            case хэшКорневогоДопуска = "корневойДопускSHA256"
            case предыдущийДопуск = "предыдущийДопускSHA256", предыдущаяОперация, прогресс
        }
    }
    public struct Конверт: Codable, Sendable {
        public let схема, хэшКлючаКорня, закодированнаяНагрузка, подпись: String
        enum CodingKeys: String, CodingKey {
            case схема
            case хэшКлючаКорня = "ключROOTSHA256"
            case закодированнаяНагрузка = "полезнаяНагрузкаBase64"
            case подпись = "подписьBase64"
        }
    }
    public struct Завершение: Codable, Sendable {
        public let схема, хэшЗаголовка, хэшДопуска, хэшСнимка, хэшУказателя: String
        public let публикация: UInt64
        enum CodingKeys: String, CodingKey {
            case схема, публикация
            case хэшЗаголовка = "заголовокSHA256", хэшДопуска = "допускSHA256"
            case хэшСнимка = "снимокSHA256", хэшУказателя = "указательSHA256"
        }
    }
    public struct ПодтверждённыйКонверт: Sendable {
        public let данные, данныеНагрузки: Data
        public let хэш: String
        public let нагрузка: Нагрузка
    }

    public static func кодировать<T: Encodable>(_ значение: T) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение)
        данные.append(10)
        return данные
    }
    /// Полный typed roundtrip запрещает unknown/duplicate/null-optional и неканонические числа.
    public static func разобрать<T: Codable>(_ тип: T.Type, из данные: Data, предел: Int) throws -> T {
        guard данные.count > 1, данные.count <= предел, данные.last == 10 else { throw Отказ.формат }
        let значение = try JSONDecoder().decode(тип, from: данные)
        guard try кодировать(значение) == данные else { throw Отказ.формат }
        return значение
    }
    public static func шестнадцатеричный(_ строка: String, длина: Int) -> Bool {
        строка.utf8.count == длина
            && строка.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
    public static func идентификатор(_ строка: String) -> Bool {
        UUID(uuidString: строка)?.uuidString.lowercased() == строка
    }
    public static func токен(_ строка: String) -> Bool {
        !строка.isEmpty && строка.utf8.count <= 512
            && !строка.unicodeScalars.contains { $0.value < 0x21 || $0.value == 0x7f }
    }
    public static func текст(_ строка: String) -> Bool {
        !строка.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && строка.utf8.count <= 2048
            && !строка.unicodeScalars.contains { $0.value < 0x20 && $0.value != 10 }
    }
    public static func абсолютныйПуть(_ строка: String) -> Bool {
        строка.hasPrefix("/") && строка.utf8.count <= 4096 && !строка.utf8.contains(0)
            && строка.split(separator: "/", omittingEmptySubsequences: false).dropFirst()
                .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
    public static func имяКвитанции(_ строка: String) -> Bool {
        токен(строка) && строка != "." && строка != ".."
            && !строка.contains("/") && !строка.contains("\\") && строка.hasSuffix(".json")
    }
    private static func байтыBase64(_ строка: String, предел: Int) throws -> Data {
        guard строка.utf8.count <= предел * 2, let данные = Data(base64Encoded: строка),
              данные.count <= предел, данные.base64EncodedString() == строка else { throw Отказ.формат }
        return данные
    }
    public static func проверитьЗаголовок(_ заголовок: Заголовок) throws {
        guard заголовок.схема == "fum.stop-заголовок.4",
              идентификатор(заголовок.корень), идентификатор(заголовок.задача),
              идентификатор(заголовок.эпоха),
              [заголовок.узел, заголовок.область, заголовок.поколение].allSatisfy(токен),
              заголовок.типХранилища == "files", заголовок.форматОбъектов == "sha1",
              шестнадцатеричный(заголовок.исходники, длина: 40),
              шестнадцатеричный(заголовок.хэшПринятияКлюча, длина: 64),
              (1...3600).contains(заголовок.максимальныйВозрастСекунд),
              (1...3600).contains(заголовок.максимальныйСрокСекунд),
              заголовок.максимальныйНомер == 128, заголовок.максимальнаяПубликация == 128,
              [заголовок.рабочийКаталог, заголовок.дерево, заголовок.каталогХранилища,
               заголовок.общийКаталогХранилища, заголовок.состояние, заголовок.состояниеV2,
               заголовок.состояниеV3, заголовок.замок.path].allSatisfy(абсолютныйПуть),
              заголовок.ссылка.hasPrefix("refs/heads/"), токен(заголовок.ссылка),
              !заголовок.ссылка.contains(".."), !заголовок.ссылка.contains("@{"),
              !заголовок.ссылка.contains(where: { "~^:?*[\\".contains($0) }),
              заголовок.ссылка.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({
                  !$0.isEmpty && !$0.hasPrefix(".") && !$0.hasSuffix(".") && !$0.hasSuffix(".lock")
              }) else { throw Отказ.идентичность }
        for каталог in [заголовок.каталогСнимков, заголовок.каталогПринятыхДопусков,
                        заголовок.каталогЗахватов, заголовок.каталогКвитанций] {
            guard абсолютныйПуть(каталог.путь), каталог.устройство > 0, каталог.индексныйУзел > 0
            else { throw Отказ.идентичность }
        }
        let ключ = try байтыBase64(заголовок.ключКорня, предел: 32)
        guard ключ.count == 32, АтомарныеБайтыStop.sha256(ключ) == заголовок.хэшКлючаКорня
        else { throw Отказ.идентичность }
    }
    /// Здесь нет сравнения с нынешним HEAD/now: этот путь также проверяет исторические записи.
    public static func проверитьКонверт(_ данные: Data, заголовок: Заголовок,
        хэшЗаголовка: String) throws -> ПодтверждённыйКонверт {
        try проверитьЗаголовок(заголовок)
        guard шестнадцатеричный(хэшЗаголовка, длина: 64) else { throw Отказ.идентичность }
        let конверт = try разобрать(Конверт.self, из: данные, предел: 65_536)
        guard конверт.схема == "fum.stop-подписанный-root-допуск.1",
              конверт.хэшКлючаКорня == заголовок.хэшКлючаКорня else { throw Отказ.идентичность }
        let нагрузкаБайты = try байтыBase64(конверт.закодированнаяНагрузка, предел: 32_768)
        let подпись = try байтыBase64(конверт.подпись, предел: 64)
        guard подпись.count == 64 else { throw Отказ.подпись }
        let ключ = try Curve25519.Signing.PublicKey(
            rawRepresentation: байтыBase64(заголовок.ключКорня, предел: 32))
        var сообщение = Data("FUM-STOP-ROOT-GRANT-v1".utf8)
        сообщение.append(0); сообщение.append(нагрузкаБайты)
        guard ключ.isValidSignature(подпись, for: сообщение) else { throw Отказ.подпись }
        let нагрузка = try разобрать(Нагрузка.self, из: нагрузкаБайты, предел: 32_768)
        guard нагрузка.схема == "fum.stop-root-допуск.1",
              нагрузка.корень == заголовок.корень, нагрузка.задача == заголовок.задача,
              нагрузка.узел == заголовок.узел, нагрузка.область == заголовок.область,
              нагрузка.поколение == заголовок.поколение, нагрузка.исходники == заголовок.исходники,
              нагрузка.хэшПринятияКлюча == заголовок.хэшПринятияКлюча,
              нагрузка.хэшЗаголовка == хэшЗаголовка, нагрузка.эпоха == заголовок.эпоха,
              идентификатор(нагрузка.операция), нагрузка.номер <= заголовок.максимальныйНомер,
              нагрузка.публикация <= заголовок.максимальнаяПубликация,
              шестнадцатеричный(нагрузка.голова, длина: 40),
              [нагрузка.хэшНаблюдения, нагрузка.хэшСнимка, нагрузка.хэшКорневогоДопуска]
                .allSatisfy({ шестнадцатеричный($0, длина: 64) }),
              нагрузка.имяСнимка == нагрузка.хэшСнимка + ".json",
              ["безопасный-шаг", "обновить-просроченный-снимок"].contains(нагрузка.вид),
              токен(нагрузка.пункт), текст(нагрузка.следующаяРабота),
              нагрузка.выдан >= 0, нагрузка.действуетДо >= нагрузка.выдан,
              нагрузка.действуетДо - нагрузка.выдан <= заголовок.максимальныйСрокСекунд
        else { throw Отказ.идентичность }
        if нагрузка.публикация == 0 {
            guard нагрузка.предыдущийДопуск == nil else { throw Отказ.цепь }
        } else {
            guard let прежний = нагрузка.предыдущийДопуск,
                  шестнадцатеричный(прежний, длина: 64) else { throw Отказ.цепь }
        }
        if нагрузка.номер == 0 {
            guard нагрузка.предыдущаяОперация == nil, нагрузка.прогресс == nil else { throw Отказ.цепь }
        } else {
            guard let прежняя = нагрузка.предыдущаяОперация, идентификатор(прежняя),
                  прежняя != нагрузка.операция, let прогресс = нагрузка.прогресс,
                  имяКвитанции(прогресс.путь), шестнадцатеричный(прогресс.хэш, длина: 64)
            else { throw Отказ.цепь }
        }
        return ПодтверждённыйКонверт(данные: данные, данныеНагрузки: нагрузкаБайты,
            хэш: АтомарныеБайтыStop.sha256(данные), нагрузка: нагрузка)
    }
    public static func проверитьСвежесть(_ нагрузка: Нагрузка, голова: String, сейчас: Int64) throws {
        guard нагрузка.голова == голова, нагрузка.выдан <= сейчас, сейчас <= нагрузка.действуетДо
        else { throw Отказ.срок }
    }
    public static func кодироватьЗавершение(_ запись: ПодтверждённыйКонверт,
        хэшЗаголовка: String) throws -> Data {
        try кодировать(Завершение(схема: "fum.stop-завершение-публикации.1",
            хэшЗаголовка: хэшЗаголовка, хэшДопуска: запись.хэш,
            хэшСнимка: запись.нагрузка.хэшСнимка, хэшУказателя: запись.хэш,
            публикация: запись.нагрузка.публикация))
    }
    public static func проверитьЗавершение(_ данные: Data, запись: ПодтверждённыйКонверт,
        хэшЗаголовка: String) throws {
        _ = try разобрать(Завершение.self, из: данные, предел: 2048)
        guard try кодироватьЗавершение(запись, хэшЗаголовка: хэшЗаголовка) == данные
        else { throw Отказ.цепь }
    }
}


fileprivate extension ЧитательФайловойСсылки {
    static func наблюдатьРазделениеV4(_ путь: String, предел: Int = 32_768) throws -> НаблюдениеФайловойСсылки {
        guard предел == 32_768 || предел == 65_536 else { throw ОтказФайловойСсылки.метаданные }
        return try наблюдать(путь, предел: предел)
    }
}

public extension КорневойДопускStopV4 {
    struct ТочкиСинхронизации: Sendable {
        public var перед: @Sendable (String) throws -> Void
        public var после: @Sendable (String) throws -> Void
        public init(перед: @escaping @Sendable (String) throws -> Void = { _ in },
                    после: @escaping @Sendable (String) throws -> Void = { _ in }) {
            self.перед = перед; self.после = после
        }
    }
    struct СписокКаталога {
        public let имена: [Data]
        fileprivate let отпечаток: ОтпечатокФайлаStop
        fileprivate let привязка: Каталог
    }
    /// Синхронный локальный контекст. FD и borrowed lock-check наружу не сохраняются.
    struct Чтение {
        private struct Файл {
            let снимок: СнимокБайтовStop
            let режим: mode_t
            let предел: Int
        }
        private var файлы: [String: Файл] = [:]
        private var каталоги: [String: СписокКаталога] = [:]
        private var прежниеСостояния: [НаблюдениеФайловойСсылки] = []
        public init() {}

        public mutating func взять(_ путь: String, режим: mode_t, предел: Int) throws -> Data {
            let снимок = try АтомарныеБайтыStop.прочитать(путь, ожидаемыйРежим: режим, предел: предел)
            if let прежний = файлы[путь] {
                guard прежний.снимок.данные == снимок.данные,
                      прежний.снимок.отпечаток == снимок.отпечаток,
                      прежний.режим == режим, прежний.предел == предел else { throw Отказ.файл }
            } else {
                файлы[путь] = Файл(снимок: снимок, режим: режим, предел: предел)
            }
            return снимок.данные
        }
        public mutating func перечислить(_ привязка: Каталог) throws -> [Data] {
            let список = try КорневойДопускStopV4.прочитатьСписок(привязка)
            if let прежний = каталоги[привязка.путь] {
                guard прежний.имена == список.имена, прежний.отпечаток == список.отпечаток
                else { throw Отказ.файл }
            } else { каталоги[привязка.путь] = список }
            return список.имена
        }
        public mutating func разделитьПрежниеСостояния(_ заголовок: Заголовок,
            наблюдатьУказатель: Bool = true) throws {
            let всеПути = [заголовок.состояниеV2, заголовок.состояниеV3, заголовок.состояние]
            guard Set(всеПути).count == 3 else { throw Отказ.идентичность }
            let пути = наблюдатьУказатель ? всеПути : Array(всеПути.prefix(2))
            var занятые = Set<String>()
            for путь in пути {
                let наблюдение = try ЧитательФайловойСсылки.наблюдатьРазделениеV4(
                    путь, предел: путь == заголовок.состояние ? 65_536 : 32_768)
                switch наблюдение {
                case .файл(let файл):
                    guard файл.сведения.st_mode & 0o7777 == 0o600,
                          файл.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true,
                          занятые.insert("\(файл.сведения.st_dev):\(файл.сведения.st_ino)").inserted
                    else { throw Отказ.идентичность }
                case .отсутствие(let отсутствие):
                    guard отсутствие.отсутствующийКомпонент.utf8.elementsEqual(путь.utf8),
                          отсутствие.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true
                    else { throw Отказ.идентичность }
                }
                прежниеСостояния.append(наблюдение)
            }
        }
        public func подтвердить() throws {
            for (путь, файл) in файлы {
                let после = try АтомарныеБайтыStop.прочитать(
                    путь, ожидаемыйРежим: файл.режим, предел: файл.предел)
                guard после.данные == файл.снимок.данные,
                      после.отпечаток == файл.снимок.отпечаток else { throw Отказ.файл }
            }
            for список in каталоги.values {
                let после = try КорневойДопускStopV4.прочитатьСписок(список.привязка)
                guard после.имена == список.имена, после.отпечаток == список.отпечаток
                else { throw Отказ.файл }
            }
            for наблюдение in прежниеСостояния {
                switch наблюдение {
                case .файл(let файл): try ЧитательФайловойСсылки.подтвердить(файл)
                case .отсутствие(let отсутствие): try ЧитательФайловойСсылки.подтвердить(отсутствие)
                }
            }
        }
        public func синхронизировать(_ путь: String, фаза: String,
            точки: ТочкиСинхронизации, проверить: () throws -> Void) throws {
            guard let файл = файлы[путь] else { throw Отказ.синхронизация }
            let (родитель, имя) = try АтомарныеБайтыStop.родитель(путь)
            defer { _ = Darwin.close(родитель) }
            let дескриптор = openat(родитель, имя, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
            guard дескриптор >= 0 else { throw Отказ.синхронизация }
            defer { _ = Darwin.close(дескриптор) }
            var до = stat(), именованный = stat(), каталогДо = stat()
            guard fstat(дескриптор, &до) == 0,
                  ОтпечатокФайлаStop(до) == файл.снимок.отпечаток,
                  fstatat(родитель, имя, &именованный, AT_SYMLINK_NOFOLLOW) == 0,
                  ОтпечатокФайлаStop(именованный) == файл.снимок.отпечаток,
                  fstat(родитель, &каталогДо) == 0,
                  каталогДо.st_uid == geteuid(), каталогДо.st_mode & 0o7777 == 0o700
            else { throw Отказ.синхронизация }
            try проверить()
            try точки.перед(фаза + "-файл")
            guard Darwin.fsync(дескриптор) == 0 else { throw Отказ.синхронизация }
            try точки.после(фаза + "-файл")
            try проверить()
            try точки.перед(фаза + "-каталог")
            guard Darwin.fsync(родитель) == 0 else { throw Отказ.синхронизация }
            try точки.после(фаза + "-каталог")
            try проверить()
            let (повторныйРодитель, повторноеИмя) = try АтомарныеБайтыStop.родитель(путь)
            defer { _ = Darwin.close(повторныйРодитель) }
            var после = stat(), каталогПосле = stat()
            guard повторноеИмя == имя, fstat(повторныйРодитель, &каталогПосле) == 0,
                  каталогПосле.st_dev == каталогДо.st_dev, каталогПосле.st_ino == каталогДо.st_ino,
                  каталогПосле.st_uid == каталогДо.st_uid, каталогПосле.st_mode == каталогДо.st_mode,
                  fstat(дескриптор, &после) == 0,
                  ОтпечатокФайлаStop(после) == файл.снимок.отпечаток
            else { throw Отказ.синхронизация }
            let прочитанный = try АтомарныеБайтыStop.прочитать(
                путь, ожидаемыйРежим: файл.режим, предел: файл.предел)
            guard прочитанный.данные == файл.снимок.данные,
                  прочитанный.отпечаток == файл.снимок.отпечаток else { throw Отказ.синхронизация }
            try проверить()
        }
    }

    fileprivate static func открытьКаталогV4(_ путь: String) throws -> Int32 {
        let (родитель, имя) = try АтомарныеБайтыStop.родитель(путь)
        defer { _ = Darwin.close(родитель) }
        let дескриптор = openat(родитель, имя, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard дескриптор >= 0 else { throw Отказ.файл }
        return дескриптор
    }
    static func проверитьКаталог(_ привязка: Каталог) throws {
        let дескриптор = try открытьКаталогV4(привязка.путь)
        defer { _ = Darwin.close(дескриптор) }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFDIR,
              сведения.st_uid == geteuid(), сведения.st_mode & 0o7777 == 0o700,
              сведения.st_dev > 0, UInt64(сведения.st_dev) == привязка.устройство,
              UInt64(сведения.st_ino) == привязка.индексныйУзел else { throw Отказ.идентичность }
    }
    fileprivate static func прочитатьСписок(_ привязка: Каталог) throws -> СписокКаталога {
        try проверитьКаталог(привязка)
        let дескриптор = try открытьКаталогV4(привязка.путь)
        defer { _ = Darwin.close(дескриптор) }
        var до = stat(), после = stat()
        guard fstat(дескриптор, &до) == 0,
              до.st_dev > 0, UInt64(до.st_dev) == привязка.устройство, UInt64(до.st_ino) == привязка.индексныйУзел,
              до.st_uid == geteuid(), до.st_mode & 0o7777 == 0o700 else { throw Отказ.файл }
        let копия = fcntl(дескриптор, F_DUPFD_CLOEXEC, 3)
        guard копия >= 0 else { throw Отказ.файл }
        guard let поток = fdopendir(копия) else { _ = Darwin.close(копия); throw Отказ.файл }
        defer { _ = closedir(поток) }
        var имена: [Data] = []
        while true {
            errno = 0
            guard let запись = readdir(поток) else {
                guard errno == 0 else { throw Отказ.файл }
                break
            }
            let длина = Int(запись.pointee.d_namlen)
            let байты = withUnsafeBytes(of: &запись.pointee.d_name) { Data($0.prefix(длина)) }
            guard длина > 0, байты.count == длина, let имя = String(data: байты, encoding: .utf8)
            else { throw Отказ.файл }
            if имя == "." || имя == ".." { continue }
            guard имена.count < 258 else { throw Отказ.цепь }
            имена.append(байты)
        }
        guard fstat(дескриптор, &после) == 0,
              ОтпечатокФайлаStop(до) == ОтпечатокФайлаStop(после) else { throw Отказ.файл }
        let повторный = try открытьКаталогV4(привязка.путь)
        defer { _ = Darwin.close(повторный) }
        var именованный = stat()
        guard fstat(повторный, &именованный) == 0,
              ОтпечатокФайлаStop(именованный) == ОтпечатокФайлаStop(до) else { throw Отказ.файл }
        return СписокКаталога(имена: имена.sorted { $0.lexicographicallyPrecedes($1) },
            отпечаток: ОтпечатокФайлаStop(до), привязка: привязка)
    }
}


public extension КорневойДопускStopV4 {
    struct Состояние {
        public let записи: [ПодтверждённыйКонверт]
        public let снимок: Data
        public let путьСнимка, путьЗаписи, путьЗавершения, путьУказателя: String
        public var последняя: ПодтверждённыйКонверт { записи[записи.count - 1] }

        /// Только existing objects; исход предыдущего издателя не переписывается.
        public func согласовать(чтение: Чтение, точки: ТочкиСинхронизации,
            проверить: () throws -> Void) throws {
            for (путь, фаза) in [(путьСнимка, "снимок"), (путьЗаписи, "допуск"),
                                  (путьУказателя, "указатель"), (путьЗавершения, "завершение")] {
                try чтение.синхронизировать(путь, фаза: фаза, точки: точки, проверить: проверить)
            }
            try чтение.подтвердить()
            try проверить()
        }
    }

    static func прочитатьСостояние(_ заголовок: Заголовок, хэшЗаголовка: String,
        путьЗаголовка: String, чтение: inout Чтение,
        проверитьЗамок: () throws -> Void) throws -> Состояние {
        try проверитьЗамок()
        let исходныйЗаголовок = try чтение.взять(путьЗаголовка, режим: 0o400, предел: 32_768)
        guard АтомарныеБайтыStop.sha256(исходныйЗаголовок) == хэшЗаголовка,
              try кодировать(заголовок) == исходныйЗаголовок else { throw Отказ.идентичность }
        try проверитьЗаголовок(заголовок)
        try проверитьФизическиеГраницы(заголовок, путьЗаголовка: путьЗаголовка)
        try чтение.разделитьПрежниеСостояния(заголовок)
        let имена = try чтение.перечислить(заголовок.каталогПринятыхДопусков)
        guard !имена.isEmpty else { throw Отказ.цепь }
        var номераЗаписей = Set<UInt64>(), номераЗавершений = Set<UInt64>()
        for байты in имена {
            guard let имя = String(data: байты, encoding: .utf8), Data(имя.utf8) == байты
            else { throw Отказ.цепь }
            let окончание: String
            let завершение: Bool
            if имя.hasSuffix(".допуск.json") { окончание = ".допуск.json"; завершение = false }
            else if имя.hasSuffix(".завершение.json") { окончание = ".завершение.json"; завершение = true }
            else { throw Отказ.цепь }
            let начало = String(имя.dropLast(окончание.count))
            guard let номер = UInt64(начало), String(номер) == начало,
                  номер <= заголовок.максимальнаяПубликация else { throw Отказ.цепь }
            if завершение {
                guard номераЗавершений.insert(номер).inserted else { throw Отказ.цепь }
            } else {
                guard номераЗаписей.insert(номер).inserted else { throw Отказ.цепь }
            }
        }
        guard let последнийНомер = номераЗаписей.max(),
              номераЗаписей == Set(UInt64(0)...последнийНомер),
              номераЗавершений == номераЗаписей else { throw Отказ.цепь }
        var записи: [ПодтверждённыйКонверт] = []
        for номер in UInt64(0)...последнийНомер {
            try проверитьЗамок()
            let путь = заголовок.каталогПринятыхДопусков.путь + "/\(номер).допуск.json"
            let данные = try чтение.взять(путь, режим: 0o400, предел: 65_536)
            let запись = try проверитьКонверт(данные, заголовок: заголовок, хэшЗаголовка: хэшЗаголовка)
            guard запись.нагрузка.публикация == номер,
                  запись.нагрузка.предыдущийДопуск == записи.last?.хэш else { throw Отказ.цепь }
            let маркер = try чтение.взять(
                заголовок.каталогПринятыхДопусков.путь + "/\(номер).завершение.json",
                режим: 0o400, предел: 2048)
            // Каждый marker проверяется по своему record, без now/current HEAD для истории.
            try проверитьЗавершение(маркер, запись: запись, хэшЗаголовка: хэшЗаголовка)
            записи.append(запись)
        }
        guard let последняя = записи.last else { throw Отказ.цепь }
        let указатель = try чтение.взять(заголовок.состояние, режим: 0o600, предел: 65_536)
        guard указатель == последняя.данные else { throw Отказ.цепь }
        let путьСнимка = заголовок.каталогСнимков.путь + "/" + последняя.нагрузка.имяСнимка
        let снимок = try чтение.взять(путьСнимка, режим: 0o400, предел: 32_768)
        guard АтомарныеБайтыStop.sha256(снимок) == последняя.нагрузка.хэшСнимка
        else { throw Отказ.идентичность }
        try чтение.подтвердить()
        try проверитьФизическиеГраницы(заголовок, путьЗаголовка: путьЗаголовка)
        try проверитьЗамок()
        return Состояние(записи: записи, снимок: снимок, путьСнимка: путьСнимка,
            путьЗаписи: заголовок.каталогПринятыхДопусков.путь + "/\(последнийНомер).допуск.json",
            путьЗавершения: заголовок.каталогПринятыхДопусков.путь + "/\(последнийНомер).завершение.json",
            путьУказателя: заголовок.состояние)
    }

    static func проверитьФизическиеГраницы(_ заголовок: Заголовок, путьЗаголовка: String) throws {
        let приватные = [заголовок.каталогСнимков, заголовок.каталогПринятыхДопусков,
                         заголовок.каталогЗахватов, заголовок.каталогКвитанций]
        var занятые = Set<String>()
        for каталог in приватные {
            try проверитьКаталог(каталог)
            guard занятые.insert("\(каталог.устройство):\(каталог.индексныйУзел)").inserted
            else { throw Отказ.идентичность }
        }
        var хранилища = Set<String>()
        for путь in [заголовок.дерево, заголовок.каталогХранилища, заголовок.общийКаталогХранилища] {
            let дескриптор = try открытьКаталогV4(путь)
            defer { _ = Darwin.close(дескриптор) }
            var сведения = stat()
            guard fstat(дескриптор, &сведения) == 0,
                  сведения.st_mode & S_IFMT == S_IFDIR, сведения.st_uid == geteuid(),
                  сведения.st_mode & 0o022 == 0 else { throw Отказ.идентичность }
            хранилища.insert("\(сведения.st_dev):\(сведения.st_ino)")
        }
        for каталог in приватные {
            try проверитьПредковВнеХранилищ(каталог.путь, каталог: true, хранилища: хранилища)
        }
        for путь in [путьЗаголовка, заголовок.состояние, заголовок.замок.path,
                     заголовок.состояниеV2, заголовок.состояниеV3] {
            try проверитьПредковВнеХранилищ(путь, каталог: false, хранилища: хранилища)
        }
        for (путь, режим, предел) in [(путьЗаголовка, mode_t(0o400), 32_768),
                                      (заголовок.замок.path, mode_t(0o600), 0)] {
            let файл = try АтомарныеБайтыStop.прочитать(путь, ожидаемыйРежим: режим, предел: предел)
            guard занятые.insert("\(файл.отпечаток.устройство):\(файл.отпечаток.inode)").inserted
            else { throw Отказ.идентичность }
        }
        for путь in [заголовок.состояниеV2, заголовок.состояниеV3, заголовок.состояние] {
            let наблюдение = try ЧитательФайловойСсылки.наблюдатьРазделениеV4(
                путь, предел: путь == заголовок.состояние ? 65_536 : 32_768)
            switch наблюдение {
            case .файл(let файл):
                guard файл.сведения.st_mode & 0o7777 == 0o600,
                      занятые.insert("\(файл.сведения.st_dev):\(файл.сведения.st_ino)").inserted
                else { throw Отказ.идентичность }
            case .отсутствие(let отсутствие):
                guard отсутствие.отсутствующийКомпонент.utf8.elementsEqual(путь.utf8),
                      отсутствие.каталоги.last.map({ $0.сведения.st_mode & 0o7777 == 0o700 }) == true
                else { throw Отказ.идентичность }
            }
        }
    }
    fileprivate static func проверитьПредковВнеХранилищ(
        _ путь: String, каталог: Bool, хранилища: Set<String>) throws {
        guard абсолютныйПуть(путь) else { throw Отказ.идентичность }
        let части = путь.split(separator: "/").map(String.init)
        let каталоги = каталог ? части : Array(части.dropLast())
        var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard дескриптор >= 0 else { throw Отказ.файл }
        defer { _ = Darwin.close(дескриптор) }
        for часть in каталоги {
            let следующий = openat(дескриптор, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw Отказ.файл }
            _ = Darwin.close(дескриптор); дескриптор = следующий
            var сведения = stat()
            guard fstat(дескриптор, &сведения) == 0,
                  !хранилища.contains("\(сведения.st_dev):\(сведения.st_ino)")
            else { throw Отказ.идентичность }
        }
    }
}


public extension АтомарныеБайтыStop {
    /// Единственное V4 применение: проверка вызывающего обязательна; временный файл не удаляется при отказе.
    static func заменитьУказательV4(_ путь: String, ожидаемыйSHA256: String?,
        новыми данные: Data, проверить: () throws -> Void,
        отметить: (String) throws -> Void) throws -> СнимокБайтовStop {
        try записать(путь, ожидаемыйSHA256: ожидаемыйSHA256, новыми: данные,
            точки: ТочкиАтомарнойЗаменыStop(), сохранятьВременный: true,
            проверить: проверить, отметить: отметить)
    }
    /// После O_EXCL нет удаления, исправления или повторной записи.
    static func создатьЗаписьV4(_ путь: String, данные: Data, режим: mode_t,
        вид: String, проверить: () throws -> Void,
        отметить: (String) throws -> Void) throws -> СнимокБайтовStop {
        guard !данные.isEmpty, данные.count <= 65_536, режим == 0o400 || режим == 0o600
        else { throw КорневойДопускStopV4.Отказ.формат }
        let (родитель, имя) = try АтомарныеБайтыStop.родитель(путь)
        defer { _ = Darwin.close(родитель) }
        var каталог = stat()
        guard fstat(родитель, &каталог) == 0, каталог.st_mode & 0o7777 == 0o700,
              каталог.st_uid == geteuid() else { throw КорневойДопускStopV4.Отказ.файл }
        try проверить(); try отметить(вид + "-перед-созданием")
        let дескриптор = openat(родитель, имя, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard дескриптор >= 0 else { throw КорневойДопускStopV4.Отказ.публикация }
        defer { _ = Darwin.close(дескриптор) }
        try отметить(вид + "-после-создания"); try проверить()
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
              сведения.st_uid == geteuid(), сведения.st_nlink == 1, сведения.st_size == 0,
              fchmod(дескриптор, 0o600) == 0 else { throw КорневойДопускStopV4.Отказ.файл }
        try проверить(); try отметить(вид + "-перед-записью")
        let записано = данные.withUnsafeBytes { Darwin.write(дескриптор, $0.baseAddress, $0.count) }
        guard записано == данные.count, fchmod(дескриптор, режим) == 0
        else { throw КорневойДопускStopV4.Отказ.публикация }
        try отметить(вид + "-после-записи"); try проверить()
        try проверить(); try отметить(вид + "-перед-fsync-файла")
        guard fsync(дескриптор) == 0 else { throw КорневойДопускStopV4.Отказ.синхронизация }
        try отметить(вид + "-после-fsync-файла"); try проверить()
        try проверить(); try отметить(вид + "-перед-fsync-каталога")
        guard fsync(родитель) == 0 else { throw КорневойДопускStopV4.Отказ.синхронизация }
        try отметить(вид + "-после-fsync-каталога"); try проверить()
        try проверить(); try отметить(вид + "-перед-readback")
        let результат = try прочитать(путь, ожидаемыйРежим: режим, предел: 65_536)
        var после = stat()
        guard fstat(дескриптор, &после) == 0,
              ОтпечатокФайлаStop(после) == результат.отпечаток, результат.данные == данные
        else { throw КорневойДопускStopV4.Отказ.файл }
        let (повторныйРодитель, повторноеИмя) = try АтомарныеБайтыStop.родитель(путь)
        defer { _ = Darwin.close(повторныйРодитель) }
        var именованныйКаталог = stat()
        guard повторноеИмя == имя, fstat(повторныйРодитель, &именованныйКаталог) == 0,
              именованныйКаталог.st_dev == каталог.st_dev, именованныйКаталог.st_ino == каталог.st_ino,
              именованныйКаталог.st_uid == каталог.st_uid, именованныйКаталог.st_mode == каталог.st_mode
        else { throw КорневойДопускStopV4.Отказ.файл }
        try отметить(вид + "-после-readback"); try проверить()
        return результат
    }
}


public extension КорневойДопускStopV4 {
    struct ТочкиПубликации: Sendable {
        public var событие: @Sendable (String) throws -> Void
        public var синхронизация: ТочкиСинхронизации
        public init(событие: @escaping @Sendable (String) throws -> Void = { _ in },
                    синхронизация: ТочкиСинхронизации = .init()) {
            self.событие = событие; self.синхронизация = синхронизация
        }
    }
    static func прочитатьНеобязательное(_ путь: String, режим: mode_t,
        предел: Int) throws -> СнимокБайтовStop? {
        let (родитель, имя) = try АтомарныеБайтыStop.родитель(путь)
        defer { _ = Darwin.close(родитель) }
        var каталог = stat(), сведения = stat()
        guard fstat(родитель, &каталог) == 0, каталог.st_uid == geteuid(),
              каталог.st_mode & 0o7777 == 0o700 else { throw Отказ.файл }
        if fstatat(родитель, имя, &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
            return try АтомарныеБайтыStop.прочитать(путь, ожидаемыйРежим: режим, предел: предел)
        }
        guard errno == ENOENT else { throw Отказ.файл }
        let (повторныйРодитель, повторноеИмя) = try АтомарныеБайтыStop.родитель(путь)
        defer { _ = Darwin.close(повторныйРодитель) }
        var после = stat()
        guard повторноеИмя == имя, fstat(повторныйРодитель, &после) == 0,
              после.st_dev == каталог.st_dev, после.st_ino == каталог.st_ino,
              после.st_uid == каталог.st_uid, после.st_mode == каталог.st_mode,
              fstatat(повторныйРодитель, имя, &сведения, AT_SYMLINK_NOFOLLOW) != 0,
              errno == ENOENT else { throw Отказ.файл }
        return nil
    }
}


public extension КорневойДопускStopV4 {
    enum ОтказПродолженияПубликации: Error, Sendable {
        case допуск, прогресс, каталог, запись, синхронизация, дрейф, срок
    }
    struct ОтказПубликации: Error, Sendable {
        public let фаза: String
        public let возможенЭффект: Bool
        public let исходКвитанции: String
    }
}
public extension УстановщикStop {
    /// Тот же V4 publisher, который потребляет существующая команда installer.
    static func проверитьПубликациюV4(_ план: Data, ожидаемыйЗаголовокSHA256: String) throws -> Data {
        try ОбщаяПубликацияДопускаStopV4.передатьПроверку {
            try ОбщаяПубликацияДопускаStopV4.публикацияV4(план,
                ожидаемыйЗаголовокSHA256: ожидаемыйЗаголовокSHA256, применить: false, точки: .init())
        }
    }
    static func опубликоватьДопускV4(_ план: Data, ожидаемыйЗаголовокSHA256: String,
        точки: КорневойДопускStopV4.ТочкиПубликации = .init()) throws -> Data {
        try ОбщаяПубликацияДопускаStopV4.передатьПроверку {
            try ОбщаяПубликацияДопускаStopV4.публикацияV4(план,
                ожидаемыйЗаголовокSHA256: ожидаемыйЗаголовокSHA256, применить: true, точки: точки)
        }
    }
}


// V4 publisher общий для существующего installer CLI и верхних публичных API.
// Legacy callback проверки остаются в верхнем модуле; здесь полный publisher dependency closure.
private enum ОбщаяПубликацияДопускаStopV4 {
    typealias Корневой = КорневойДопускStopV4
    struct ФактыУстановки {
        let хэшТекущего, хэшСнимка, голова, управление, эпоха, операция: String
        let редакция: UInt64
        let подтвердить: () throws -> Void
    }
    // Единственный read-only вход установки: caller уже держит точный lock inode.
    // Не вызывает publisher, consumer policy/claim или согласовать/fsync repair.
    static func проверитьДляУстановки(_ заголовок: Корневой.Заголовок,
        путьЗаголовка: String, хэшЗаголовка: String, ожидаемыйХэшТекущего: String,
        пределТекущего: Int, проверитьЗамок: () throws -> Void) throws -> ФактыУстановки? {
        try проверитьЗамок()
        try Корневой.проверитьЗаголовок(заголовок)
        try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: путьЗаголовка)
        guard let raw = try Корневой.прочитатьНеобязательное(заголовок.состояние,
            режим: 0o600, предел: пределТекущего) else {
            try проверитьЗамок(); return nil
        }
        guard raw.sha256 == ожидаемыйХэшТекущего else { throw Корневой.Отказ.идентичность }
        var якорноеЧтение = Корневой.Чтение()
        let состояние = try Корневой.прочитатьСостояние(заголовок,
            хэшЗаголовка: хэшЗаголовка, путьЗаголовка: путьЗаголовка,
            чтение: &якорноеЧтение, проверитьЗамок: проверитьЗамок)
        let запись = состояние.последняя, нагрузка = запись.нагрузка
        guard запись.хэш == ожидаемыйХэшТекущего else { throw Корневой.Отказ.идентичность }
        let снимок = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
        var проектноеЧтение = Чтение()
        try проверитьGit(прежнийЗаголовокV4(заголовок, нагрузка: нагрузка),
            HEAD: снимок.голова, чтение: &проектноеЧтение)
        if нагрузка.номер > 0 {
            try проверитьПрогрессV4(допускV4(нагрузка, заголовок), заголовок,
                история: состояние.записи, чтение: &проектноеЧтение)
        }
        let якорь = якорноеЧтение, проект = проектноеЧтение
        let подтвердить: () throws -> Void = {
            try якорь.подтвердить(); try проект.подтвердить()
            try Корневой.проверитьФизическиеГраницы(заголовок, путьЗаголовка: путьЗаголовка)
            _ = try проверитьСнимокV4(состояние.снимок, заголовок: заголовок, нагрузка: нагрузка)
        }
        try подтвердить(); try проверитьЗамок()
        return ФактыУстановки(хэшТекущего: запись.хэш, хэшСнимка: нагрузка.хэшСнимка,
            голова: снимок.голова, управление: снимок.управление.действие,
            эпоха: нагрузка.эпоха, операция: нагрузка.операция, редакция: нагрузка.редакция,
            подтвердить: подтвердить)
    }

    static func передатьПроверку<T>(_ действие: () throws -> T) throws -> T {
        do { return try действие() }
        catch let ошибка as КонечноеПродолжениеStop.Отказ {
            switch ошибка {
            case .допуск: throw Корневой.ОтказПродолженияПубликации.допуск
            case .прогресс: throw Корневой.ОтказПродолженияПубликации.прогресс
            case .каталог: throw Корневой.ОтказПродолженияПубликации.каталог
            case .запись: throw Корневой.ОтказПродолженияПубликации.запись
            case .синхронизация: throw Корневой.ОтказПродолженияПубликации.синхронизация
            case .дрейф: throw Корневой.ОтказПродолженияПубликации.дрейф
            case .срок: throw Корневой.ОтказПродолженияПубликации.срок
            }
        }
    }
struct УсловияСамостоятельности: Codable, Sendable {
    var свояОбласть: Bool
    var естьПолномочия: Bool
    var неизвестныйОпасныйЭффект: Bool
    var естьНакопленноеПродвижение: Bool
    var можноБезопасноПродолжать: Bool
    var доступнаНезависимаяРабота: Bool
    var локальнаяИсправимаяПроблема: Bool
    var остановкаЗадачи: Bool
    var естьБезопасныйСледующийШаг: Bool

    init(свояОбласть: Bool, естьПолномочия: Bool, неизвестныйОпасныйЭффект: Bool,
                естьНакопленноеПродвижение: Bool, можноБезопасноПродолжать: Bool,
                доступнаНезависимаяРабота: Bool, локальнаяИсправимаяПроблема: Bool,
                остановкаЗадачи: Bool, естьБезопасныйСледующийШаг: Bool) {
        self.свояОбласть = свояОбласть
        self.естьПолномочия = естьПолномочия
        self.неизвестныйОпасныйЭффект = неизвестныйОпасныйЭффект
        self.естьНакопленноеПродвижение = естьНакопленноеПродвижение
        self.можноБезопасноПродолжать = можноБезопасноПродолжать
        self.доступнаНезависимаяРабота = доступнаНезависимаяРабота
        self.локальнаяИсправимаяПроблема = локальнаяИсправимаяПроблема
        self.остановкаЗадачи = остановкаЗадачи
        self.естьБезопасныйСледующийШаг = естьБезопасныйСледующийШаг
    }
}

struct НаблюденияStop: Codable, Sendable {
    static let текущаяСхема = "fum.stop-наблюдения.1"

    let схема: String
    let задача: String
    let узел: String
    let следующаяРабота: String
    let условия: УсловияСамостоятельности

    init(задача: String, узел: String, следующаяРабота: String,
                условия: УсловияСамостоятельности) {
        схема = Self.текущаяСхема
        self.задача = задача
        self.узел = узел
        self.следующаяРабота = следующаяРабота
        self.условия = условия
    }
}

enum ОтказКомандыStop: String, Error {
    case параметры, неабсолютныйПуть, неканоническийПуть, компонентОтсутствует
    case символическаяСсылка, открытиеСостояния, чтениеСостояния, метаданныеСостояния
    case превышенПределСостояния, дрейфСостояния, ввод
}

    static func открытьБезСсылок(_ путь: String) throws -> Int32 {
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
            let fd = try ОбщаяПубликацияДопускаStopV4.открытьБезСсылок(путь)
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
            let именованный = try ОбщаяПубликацияДопускаStopV4.открытьБезСсылок(путь)
            defer { _ = Darwin.close(именованный) }
            var имя = stat()
            guard fstat(именованный, &имя) == 0, равны(после, имя)
            else { throw Отказ.дрейфФайла }
            return Файл(путь: путь, режим: режим, предел: предел,
                        данные: данные, метаданные: после)
        }
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

    private enum КонечноеПродолжениеStop {
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
    enum Отказ: Error { case допуск, прогресс, каталог, запись, синхронизация, дрейф, срок }
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
    private static func uuid(_ s: String) -> Bool { UUID(uuidString: s)?.uuidString.lowercased() == s }
    private static func hex(_ s: String, _ n: Int) -> Bool {
        s.utf8.count == n && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
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

    /// Весь V4 вход сохраняет исходную closed-wire границу: используем уже существующий строгий codec.
    private static func decode<T: Decodable>(_ тип: T.Type, _ данные: Data) throws -> T {
        _ = try Корневой.разобрать(СнимокV4.self, из: данные, предел: 32_768)
        return try JSONDecoder().decode(тип, from: данные)
    }

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
        применить: Bool, точки: Корневой.ТочкиПубликации,
        контрольПлана: () throws -> Void = {}) throws -> Data {
        try контрольПлана()
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
                try контрольПлана()
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
                throw Корневой.ОтказПубликации(фаза: фаза, возможенЭффект: возможенЭффект,
                    исходКвитанции: квитанцияИсхода)
            }
        }
    }

    private struct ОшибкаCLI: Encodable {
        let схема = "fum.stop-cli-публикация.4"
        let исход, код, фаза: String
        let возможенЭффект: Bool
        let исходКвитанции: String
    }
    private static func вывестиОтказCLI(_ код: String, фаза: String = "до-эффекта",
        возможенЭффект: Bool = false, исходКвитанции: String = "НЕ_СОЗДАНА") -> Int32 {
        let ошибка = ОшибкаCLI(исход: возможенЭффект ? "UNKNOWN" : "FAILED",
            код: код, фаза: фаза, возможенЭффект: возможенЭффект, исходКвитанции: исходКвитанции)
        do {
            let данные = try Корневой.кодировать(ошибка)
            try FileHandle.standardOutput.write(contentsOf: данные)
            return возможенЭффект ? 5 : 2
        } catch { return 5 }
    }
    static func выполнитьКоманду(_ args: [String]) -> Int32 {
        do {
            guard args.count == 7, ["--проверить", "--применить"].contains(args[6])
            else { throw ОтказКомандыStop.параметры }
            let разрешённые: Set<String> = ["--план", "--план-sha256", "--заголовок-sha256"]
            var значения: [String: String] = [:]
            for i in stride(from: 0, to: 6, by: 2) {
                let ключ = args[i], значение = args[i + 1]
                guard разрешённые.contains(ключ), значения[ключ] == nil,
                      !значение.isEmpty, !значение.hasPrefix("--"), !значение.utf8.contains(0)
                else { throw ОтказКомандыStop.параметры }
                значения[ключ] = значение
            }
            guard значения.count == 3,
                  let путь = значения["--план"], Корневой.абсолютныйПуть(путь),
                  let хэшПлана = значения["--план-sha256"], hex(хэшПлана, 64),
                  let хэшЗаголовка = значения["--заголовок-sha256"], hex(хэшЗаголовка, 64)
            else { throw ОтказКомандыStop.параметры }
            var чтениеПлана = Чтение()
            let данные = try чтениеПлана.взять(путь, режим: 0o400, предел: 16_384)
            guard sha256(данные) == хэшПлана else { return вывестиОтказCLI("план-sha256") }
            let закреплённыйПлан = чтениеПлана
            let итог = try публикацияV4(данные, ожидаемыйЗаголовокSHA256: хэшЗаголовка,
                применить: args[6] == "--применить", точки: .init(),
                контрольПлана: { try закреплённыйПлан.подтвердить() })
            do { try FileHandle.standardOutput.write(contentsOf: итог) }
            catch { return 5 } // После попытки вывода не повторяем публикацию или stdout.
            return 0
        } catch let ошибка as Корневой.ОтказПубликации {
            return вывестиОтказCLI("публикация", фаза: ошибка.фаза,
                возможенЭффект: ошибка.возможенЭффект, исходКвитанции: ошибка.исходКвитанции)
        } catch let ошибка as Отказ {
            return вывестиОтказCLI(ошибка.rawValue)
        } catch let ошибка as ОтказКомандыStop {
            return вывестиОтказCLI(ошибка.rawValue)
        } catch let ошибка as ОтказФайловойСсылки {
            return вывестиОтказCLI(ошибка.rawValue)
        } catch let ошибка as Корневой.Отказ {
            switch ошибка {
            case .формат: return вывестиОтказCLI("формат")
            case .идентичность: return вывестиОтказCLI("идентичность")
            case .подпись: return вывестиОтказCLI("подпись")
            case .срок: return вывестиОтказCLI("срок")
            case .файл: return вывестиОтказCLI("файл")
            case .цепь: return вывестиОтказCLI("цепь")
            case .синхронизация: return вывестиОтказCLI("синхронизация")
            case .публикация: return вывестиОтказCLI("публикация")
            }
        } catch let ошибка as КонечноеПродолжениеStop.Отказ {
            switch ошибка {
            case .допуск: return вывестиОтказCLI("допуск")
            case .прогресс: return вывестиОтказCLI("прогресс")
            case .каталог: return вывестиОтказCLI("каталог")
            case .запись: return вывестиОтказCLI("запись")
            case .синхронизация: return вывестиОтказCLI("синхронизация")
            case .дрейф: return вывестиОтказCLI("дрейф")
            case .срок: return вывестиОтказCLI("срок")
            }
        } catch { return вывестиОтказCLI("проверка") }
    }

}

// Lifecycle рабочего издателя не создаёт финальную диспозицию и не продлевает
// подтверждение содержания. ROOT выдаёт отдельную конечную аренду входа.
final class СостояниеИздателяСтоп {
    var последнийХэш: String?
    var ревизия: Int64 = 0
    var завершён = false
    var ошибка: String?
    fileprivate var замок: УдерживаемыйЗамокСтоп?
    fileprivate var хэшЗапросаИздателя: String?
    fileprivate var хэшВходаИздателя: String?
    fileprivate var последниеЧасы: Int64?
    fileprivate var времяНачала: Int64?
    fileprivate var намерениеСохранено = false
    fileprivate var номерШага = 0
    fileprivate var конечныйСтатус: String?
    fileprivate var конечныйХэш: String?
}
struct ИтогПоддержанияСтоп: Sendable {
    let статус: String
    let наблюдаемыйSHA256: String?
}
private struct ЗапросИздателяСтоп: Decodable {
    let schema, runID: String
    let header: Pin
    let current: CPin
    let singleton: СсылкаЗамкаStop
    let input: ПутьВходаИздателяСтоп
    let initialCurrentSHA256, requiredUnknownID, headPolicy: String
    let intervalSeconds, ttlSeconds, maxTicks, maxRunSeconds: Int
}
private struct ПутьВходаИздателяСтоп: Decodable {
    let path: String
    let mode: UInt32
    let maxBytes: Int
}
private struct ВходИздателяСтоп: Decodable {
    let schema, root, node, scope, generation, headerSHA256: String
    let revision, approvedAt, validUntil: Int64
    let action, reason: String
    let payload: Pin?
}
private struct ПубликацияВходаИздателяСтоп: Decodable {
    let schema: String
    let request, candidate: Pin
    let initiallyAbsent: Bool
    let expectedSHA256: String?
}
private struct УсловияВходаИздателяСтоп: Decodable {
    let свояОбласть, естьПолномочия, неизвестныйОпасныйЭффект: Bool
    let естьНакопленноеПродвижение, можноБезопасноПродолжать, доступнаНезависимаяРабота: Bool
    let локальнаяИсправимаяПроблема, остановкаЗадачи, естьБезопасныйСледующийШаг: Bool
}
extension УстановщикStop {
    private static func завершитьИздателя(_ state: СостояниеИздателяСтоп, _ status: String,
        _ sha: String? = nil) -> ИтогПоддержанияСтоп {
        state.завершён = true; state.конечныйСтатус = status; state.конечныйХэш = sha
        state.замок?.закрыть(); state.замок = nil
        return ИтогПоддержанияСтоп(статус: status, наблюдаемыйSHA256: sha)
    }
    private static func прочитатьЗапросИздателя(_ path: String, _ sha: String) throws -> (ЗапросИздателяСтоп, H) {
        try need(abs(path) && hex(sha, 64), "MR0")
        let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
        try need(raw.sha256 == sha, "MR1", path)
        let p = try dec(ЗапросИздателяСтоп.self, raw.данные)
        let h = try dec(H.self, read(p.header, 0o400, 32_768).данные)
        try need(p.schema == "fum.stop-maintainer-request.1" && uuid(p.runID)
            && token(p.requiredUnknownID) && ["strict", "observe-with-unknown"].contains(p.headPolicy)
            && (1...300).contains(p.intervalSeconds) && p.ttlSeconds >= p.intervalSeconds * 2
            && p.ttlSeconds <= h.максимальныйВозрастСекунд
            && (1...1_000_000).contains(p.maxTicks) && (1...86_400).contains(p.maxRunSeconds), "MR2")
        try need(h.схема == "fum.stop-заголовок.2" && uuid(h.задача) && token(h.узел)
            && token(h.область) && token(h.поколение) && ref(h.ref) && hex(h.исходники, 40)
            && h.backend == "files" && h.objectFormat == "sha1"
            && (1...3600).contains(h.максимальныйВозрастСекунд)
            && [h.cwd, h.дерево, h.gitDir, h.commonGitDir, h.состояние, h.каталогКвитанций].allSatisfy(abs), "MH0")
        try need(p.current.path == h.состояние && p.current.mode == 0o600
            && (1...32_768).contains(p.current.maxBytes)
            && p.current.lock.path == h.состояние + ".lock"
            && p.singleton.path == h.состояние + ".producer.lock"
            && p.input.path == h.состояние + ".producer-input.json" && p.input.mode == 0o600
            && (1...65_536).contains(p.input.maxBytes) && hex(p.initialCurrentSHA256, 64), "MR3")
        return (p, h)
    }
    private static func проверитьСвязанныйКонверт(_ bytes: Data, _ h: H, _ headerSHA: String) throws -> Envelope {
        let схемаКонверта: String
        switch h.схема {
        case "fum.stop-заголовок.2": схемаКонверта = "fum.текущие-обязательства-stop.2"
        case "fum.stop-заголовок.3": схемаКонверта = "fum.текущие-обязательства-stop.3"
        default: throw E("ME0")
        }
        let e = try dec(Envelope.self, bytes)
        try need(e.схема == схемаКонверта && e.заголовокSHA256 == headerSHA
            && e.задача == h.задача && e.узел == h.узел && e.область == h.область
            && e.поколение == h.поколение && text(e.управление.основание)
            && ["продолжать", "стоп", "пауза"].contains(e.управление.действие), "ME0")
        return e
    }
    private static func прочитатьВходИздателя(_ p: ЗапросИздателяСтоп, _ h: H)
        throws -> (ВходИздателяСтоп, СнимокБайтовStop) {
        let raw = try AB.прочитать(p.input.path, ожидаемыйРежим: 0o600, предел: p.input.maxBytes)
        return (try декодироватьВходИздателя(raw.данные, p, h), raw)
    }
    private static func декодироватьВходИздателя(_ bytes: Data, _ p: ЗапросИздателяСтоп, _ h: H) throws -> ВходИздателяСтоп {
        let v = try dec(ВходИздателяСтоп.self, bytes)
        try need(v.schema == "fum.stop-maintainer-input.1" && v.root == h.задача
            && v.node == h.узел && v.scope == h.область && v.generation == h.поколение
            && v.headerSHA256 == p.header.sha256 && v.revision >= 0 && text(v.reason)
            && ["обновлять", "остановить-издатель", "стоп", "пауза"].contains(v.action), "MI0")
        return v
    }
    private static func сформироватьРабочийСнимок(_ p: ЗапросИздателяСтоп, _ h: H,
        _ v: ВходИздателяСтоп, inputSHA: String, requestSHA: String, head: String, now: Int64) throws -> Data {
        guard let pin = v.payload else { throw E("MIpayload") }
        let raw = try read(pin, 0o600, p.current.maxBytes)
        let e = try проверитьСвязанныйКонверт(raw.данные, h, p.header.sha256)
        let m = try dec(Meta.self, raw.данные)
        try need(e.управление.действие == "продолжать" && m.cwd == h.cwd && m.дерево == h.дерево
            && m.ref == h.ref && hex(m.HEAD, 40), "MIpayloadMeta")
        guard var object = try JSONSerialization.jsonObject(with: raw.данные) as? [String: Any],
            let points = object["пункты"] as? [[String: Any]], (1...127).contains(points.count),
            var unknown = object["неизвестныеНамерения"] as? [String], unknown.count <= 127,
            Set(unknown).count == unknown.count, unknown.allSatisfy(token),
            unknown.contains(p.requiredUnknownID),
            points.contains(where: { $0["id"] as? String == p.requiredUnknownID
                && $0["область"] as? String == h.область && $0["состояние"] as? String == "блокирован" }),
            object["диспозиция"] == nil,
            let observations = object["наблюдения"] as? [String: Any],
            observations["схема"] as? String == "fum.stop-наблюдения.1",
            observations["задача"] as? String == h.задача, observations["узел"] as? String == h.узел,
            let следующаяРабота = observations["следующаяРабота"] as? String,
            следующаяРабота.isEmpty || text(следующаяРабота),
            let conditions = observations["условия"] as? [String: Any]
        else { throw E("MIworkingOnly") }
        // JSONDecoder Bool отвергает числовые 0/1, которые NSNumber может
        // неявно представить как Bool при чтении JSONSerialization.
        let проверенныеУсловия = try dec(УсловияВходаИздателяСтоп.self,
            JSONSerialization.data(withJSONObject: conditions))
        try need(!проверенныеУсловия.остановкаЗадачи, "MIworkingOnly")
        var ids: Set<String> = []
        for point in points {
            guard let id = point["id"] as? String, token(id), ids.insert(id).inserted,
                let scope = point["область"] as? String, token(scope),
                let state = point["состояние"] as? String,
                ["доступен", "ожидает-ребёнка", "доставлен", "закрыт", "блокирован", "неактивен"].contains(state),
                let level = point["уровень"] as? String, ["исходники", "native"].contains(level),
                let basis = point["основание"] as? String, text(basis),
                scope == h.область || ["закрыт", "неактивен"].contains(state)
            else { throw E("MIpoint") }
        }
        if head != m.HEAD {
            try need(p.headPolicy == "observe-with-unknown", "MHEAD")
            if !unknown.contains("root-head-after-approved-input") { unknown.append("root-head-after-approved-input") }
        }
        object["HEAD"] = head; object["выпущен"] = now
        object["действуетДо"] = min(now + Int64(p.ttlSeconds), v.validUntil)
        object["неизвестныеНамерения"] = unknown
        object["поддержание"] = ["ревизия": v.revision, "входSHA256": inputSHA,
            "requestSHA256": requestSHA, "исходныйPayloadSHA256": pin.sha256,
            "подтвержденоВ": v.approvedAt, "подтвержденоДо": v.validUntil,
            "исходныйHEAD": m.HEAD, "наблюдавшийсяHEAD": head,
            "полнота": "UNKNOWN"] as [String: Any]
        var bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
        bytes.append(10)
        try need(bytes.count <= p.current.maxBytes, "Msize")
        _ = try currentBytes(bytes, AB.sha256(bytes), h, p.header.sha256, head, clock: now)
        return bytes
    }
    private static func прочитатьПубликациюВхода(_ path: String, _ sha: String)
        throws -> (ПубликацияВходаИздателяСтоп, ЗапросИздателяСтоп, H, СнимокБайтовStop, ВходИздателяСтоп) {
        try need(abs(path) && hex(sha, 64), "MP0")
        let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
        try need(raw.sha256 == sha, "MP1")
        let plan = try dec(ПубликацияВходаИздателяСтоп.self, raw.данные)
        try need(plan.schema == "fum.stop-maintainer-input-publication.1"
            && (plan.initiallyAbsent ? plan.expectedSHA256 == nil : hex(plan.expectedSHA256 ?? "", 64)), "MP2")
        _ = try read(plan.request, 0o600, 65_536)
        let (p, h) = try прочитатьЗапросИздателя(plan.request.path, plan.request.sha256)
        let candidate = try read(plan.candidate, 0o600, p.input.maxBytes)
        let v = try декодироватьВходИздателя(candidate.данные, p, h)
        if v.action == "обновлять" {
            let now = Int64(Date().timeIntervalSince1970)
            try need(v.revision >= 1 && v.approvedAt >= 0 && v.approvedAt <= now
                && v.approvedAt <= Int64.max - 86_400 && v.validUntil > now
                && v.validUntil - v.approvedAt <= 86_400, "MPlease")
            guard let pin = v.payload else { throw E("MPpayload") }
            let payload = try read(pin, 0o600, p.current.maxBytes)
            let meta = try dec(Meta.self, payload.данные)
            _ = try сформироватьРабочийСнимок(p, h, v, inputSHA: candidate.sha256,
                requestSHA: plan.request.sha256, head: meta.HEAD, now: now)
        }
        return (plan, p, h, candidate, v)
    }
    private static func опубликоватьВходИздателя(_ argv: [String]) throws -> Int32 {
        let (path, sha, mode) = try args(argv)
        let (_, initial, _, _, _) = try прочитатьПубликациюВхода(path, sha)
        return try ЗамокТекущегоStop.выполнить(initial.current.lock) { check in
            let (plan, p, _, candidate, v) = try прочитатьПубликациюВхода(path, sha)
            if case .apply(let value) = mode { try need(value == candidate.sha256, "MPcandidate") }
            if plan.initiallyAbsent {
                var s = Darwin.stat()
                try need(lstat(p.input.path, &s) != 0 && errno == ENOENT, "MPabsent")
            } else {
                let old = try AB.прочитать(p.input.path, ожидаемыйРежим: 0o600, предел: p.input.maxBytes)
                try need(old.sha256 == plan.expectedSHA256, "MPold")
                let прежняяРевизияВхода = try dec(ВходИздателяСтоп.self, old.данные)
                try need(v.revision > прежняяРевизияВхода.revision, "MPrev")
            }
            var common: [String: Any] = ["operation": "publish-maintainer-input", "planSHA256": sha,
                "requestSHA256": plan.request.sha256, "candidateSHA256": candidate.sha256,
                "revision": v.revision, "authorityChecked": false, "worklistCompleteness": "UNKNOWN",
                "automaticRetry": false, "automaticRollback": false]
            if case .check = mode {
                common["status"] = "METADATA_CHECKED"; common["writes"] = 0; emit(common); return 0
            }
            // Обычный busy уже обработан до резервирования стабильного намерения.
            let путиКвитанцийИздателя = try receiptPaths(config: p.input.path,
                oldSHA: plan.expectedSHA256 ?? AB.sha256(Data("ABSENT".utf8)),
                candidateSHA: candidate.sha256, publication: true)
            common["intentReceipt"] = путиКвитанцийИздателя.intent; common["outcomeReceipt"] = путиКвитанцийИздателя.outcome
            var intent = common; intent["status"] = "INTENT"
            try receipt(путиКвитанцийИздателя.intent, intent)
            var code: Int32 = 2
            do {
                let result = try withoutActuallyEscaping(check) { verify in
                    var points = ТочкиАтомарнойЗаменыStop()
                    points.передRename = { try verify(); _ = try прочитатьПубликациюВхода(path, sha) }
                    return try AB.записать(p.input.path, ожидаемыйSHA256: plan.expectedSHA256,
                        новыми: candidate.данные, точки: points)
                }
                common["status"] = "INPUT_PUBLISHED"; common["boundary"] = "afterRename"
                common["observedInputSHA256"] = result.sha256; code = 0
            } catch let e as ОтказАтомарнойЗаменыStop {
                let unknown = e.граница == .послеRename || e.оставленныйВременныйФайл != nil
                common["status"] = unknown ? "UNKNOWN" : "FAILED"
                common["boundary"] = e.граница.rawValue; common["phase"] = e.фаза
                common["error"] = e.причина; code = unknown ? 4 : 2
                if let seen = e.наблюдаемыйSHA256 { common["observedInputSHA256"] = seen }
            } catch { common["status"] = "UNKNOWN"; common["error"] = String(describing: error); code = 4 }
            do { try receipt(путиКвитанцийИздателя.outcome, common) } catch {
                common["status"] = "UNKNOWN"; common["receiptError"] = String(describing: error); code = 5
            }
            emit(common); return code
        }
    }
    static func шагПоддержания(_ путь: String, хэш: String,
        состояние: СостояниеИздателяСтоп, сейчас: Int64,
        точки: ТочкиАтомарнойЗаменыStop = ТочкиАтомарнойЗаменыStop(),
        часыПередRename: @escaping () throws -> Int64 = { Int64(Date().timeIntervalSince1970) }) throws -> ИтогПоддержанияСтоп {
        let state = состояние
        if state.завершён { return ИтогПоддержанияСтоп(статус: state.конечныйСтатус ?? "STOPPED", наблюдаемыйSHA256: state.конечныйХэш) }
        do {
            let (p, h) = try прочитатьЗапросИздателя(путь, хэш)
            try need(сейчас >= 0 && сейчас <= Int64.max - 86_400, "Mclock")
            if let requestSHA = state.хэшЗапросаИздателя, requestSHA != хэш { return завершитьИздателя(state, "REQUEST_CHANGED") }
            if state.замок == nil {
                do { state.замок = try УдерживаемыйЗамокСтоп.открыть(p.singleton) }
                catch let e as E where e.description.hasPrefix("Lbusy:") { return завершитьИздателя(state, "SINGLETON_BUSY") }
            }
            state.хэшЗапросаИздателя = хэш
            if state.времяНачала == nil { state.времяНачала = сейчас }
            return try ЗамокТекущегоStop.выполнить(p.current.lock) { checkLock in
                try state.замок?.проверить(); _ = try прочитатьЗапросИздателя(путь, хэш)
                let old = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600, предел: p.current.maxBytes)
                let прежнийКонверт = try проверитьСвязанныйКонверт(old.данные, h, p.header.sha256)
                if прежнийКонверт.управление.действие != "продолжать" { return завершитьИздателя(state, "ROOT_CONTROL", old.sha256) }
                let основаПопыткиИздателя = try parent(p.current.path) + "/.fum-stop-maintainer-" + хэш
                let путьПопыткиИздателя = основаПопыткиИздателя + ".attempt.json"
                if !state.намерениеСохранено {
                    var s = Darwin.stat()
                    if lstat(путьПопыткиИздателя, &s) == 0 { return завершитьИздателя(state, "RECOVERY_REQUIRED", old.sha256) }
                    try need(errno == ENOENT, "Mattempt")
                }
                if old.sha256 != (state.последнийХэш ?? p.initialCurrentSHA256) {
                    return завершитьИздателя(state, "MANUAL_TAKEOVER", old.sha256)
                }
                let (input, inputRaw) = try прочитатьВходИздателя(p, h)
                if input.action == "остановить-издатель" { return завершитьИздателя(state, "SERVICE_STOPPED", old.sha256) }
                if input.action == "обновлять" {
                    if let prior = state.последниеЧасы, сейчас < prior { return завершитьИздателя(state, "CLOCK_REGRESSION", old.sha256) }
                    if input.revision < state.ревизия { return завершитьИздателя(state, "INPUT_REVISION_ROLLBACK", old.sha256) }
                    if let prior = state.хэшВходаИздателя, input.revision == state.ревизия && prior != inputRaw.sha256 {
                        return завершитьИздателя(state, "INPUT_REVISION_REUSED", old.sha256)
                    }
                    try need(input.revision >= 1 && input.approvedAt >= 0 && input.approvedAt <= сейчас
                        && input.approvedAt <= Int64.max - 86_400
                        && input.validUntil >= input.approvedAt && input.validUntil - input.approvedAt <= 86_400, "MIlease")
                    if input.validUntil <= сейчас { return завершитьИздателя(state, "SOURCE_EXPIRED", old.sha256) }
                    if state.номерШага >= p.maxTicks || сейчас - (state.времяНачала ?? сейчас) >= Int64(p.maxRunSeconds) {
                        return завершитьИздателя(state, "RUN_LIMIT", old.sha256)
                    }
                }
                state.последниеЧасы = сейчас
                let candidate: Data
                var observedHead: String?
                let исходнаяПривязка: СнимокФайловойСсылки?
                if ["стоп", "пауза"].contains(input.action) {
                    исходнаяПривязка = nil
                    let object: [String: Any] = ["схема": "fum.текущие-обязательства-stop.2",
                        "заголовокSHA256": p.header.sha256, "задача": h.задача, "узел": h.узел,
                        "область": h.область, "поколение": h.поколение,
                        "управление": ["действие": input.action, "основание": input.reason]]
                    var bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
                    bytes.append(10); candidate = bytes
                } else {
                    let снимок = try снимокПривязкиСсылки(h)
                    исходнаяПривязка = снимок
                    let head = снимок.идентификаторОбъекта; observedHead = head
                    if p.headPolicy == "strict", let pin = input.payload {
                        let raw = try read(pin, 0o600, p.current.maxBytes)
                        let meta = try dec(Meta.self, raw.данные)
                        if head != meta.HEAD { return завершитьИздателя(state, "HEAD_CHANGED", old.sha256) }
                    }
                    candidate = try сформироватьРабочийСнимок(p, h, input, inputSHA: inputRaw.sha256,
                        requestSHA: хэш, head: head, now: сейчас)
                }
                if candidate == old.данные {
                    state.ревизия = input.revision; state.хэшВходаИздателя = inputRaw.sha256
                    state.последнийХэш = old.sha256
                    return ИтогПоддержанияСтоп(статус: "NO_CHANGE", наблюдаемыйSHA256: old.sha256)
                }
                if !state.намерениеСохранено {
                    try receipt(путьПопыткиИздателя, ["schema": "fum.stop-maintainer-attempt.1", "requestSHA256": хэш,
                        "runID": p.runID, "root": h.задача, "inputSHA256": inputRaw.sha256,
                        "expectedCurrentSHA256": old.sha256, "status": "INTENT", "automaticRetry": false])
                    state.намерениеСохранено = true
                }
                state.номерШага += 1
                let основаКвитанцииШага = основаПопыткиИздателя + ".tick-" + String(format: "%08d", state.номерШага)
                let путьНамеренияШага = основаКвитанцииШага + ".intent.json", outcomePath = основаКвитанцииШага + ".outcome.json"
                var outcome: [String: Any] = ["requestSHA256": хэш, "inputSHA256": inputRaw.sha256,
                    "revision": input.revision, "tick": state.номерШага, "expectedCurrentSHA256": old.sha256,
                    "candidateSHA256": AB.sha256(candidate), "automaticRetry": false, "automaticRollback": false]
                var intent = outcome; intent["status"] = "INTENT"
                try receipt(путьНамеренияШага, intent)
                var observed: String?, status = "FAILED", terminal = false
                do {
                    let result = try withoutActuallyEscaping(checkLock) { verify in
                        var points = точки
                        let проверкаВызывающего = points.передRename
                        points.передRename = {
                            try проверкаВызывающего?(); try verify(); try state.замок?.проверить()
                            _ = try прочитатьЗапросИздателя(путь, хэш)
                            let (_, latestInput) = try прочитатьВходИздателя(p, h)
                            try need(latestInput.sha256 == inputRaw.sha256, "MIchanged")
                            let latestCurrent = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600, предел: p.current.maxBytes)
                            try need(latestCurrent.sha256 == old.sha256, "MCchanged")
                            if let observedHead {
                                let конечнаяПривязка = try снимокПривязкиСсылки(h)
                                try need(конечнаяПривязка.идентификаторОбъекта == observedHead, "MGchanged")
                                try исходнаяПривязка?.подтвердить()
                                try конечнаяПривязка.подтвердить()
                                let проверенноеВремя = try часыПередRename()
                                try need(проверенноеВремя >= сейчас && проверенноеВремя <= Int64.max - 86_400,
                                    "MclockBeforeRename")
                                let метаданные = try dec(Meta.self, candidate)
                                try need(input.validUntil > проверенноеВремя && метаданные.действуетДо > проверенноеВремя,
                                    "MleaseBeforeRename")
                                _ = try currentBytes(candidate, AB.sha256(candidate), h,
                                    p.header.sha256, observedHead, clock: проверенноеВремя)
                            }
                        }
                        try исходнаяПривязка?.подтвердить()
                        return try AB.заменить(p.current.path, ожидаемыйSHA256: old.sha256, новыми: candidate, точки: points)
                    }
                    observed = result.sha256; status = "UPDATED"
                } catch let e as ОтказАтомарнойЗаменыStop {
                    observed = e.наблюдаемыйSHA256
                    terminal = true
                    status = e.граница == .послеRename || e.оставленныйВременныйФайл != nil ? "UNKNOWN" : "FAILED"
                    state.ошибка = e.причина
                    if e.граница == .доRename && e.оставленныйВременныйФайл == nil
                        && e.фаза == "перед-rename" && e.причина == "MGchanged"
                        && p.headPolicy == "observe-with-unknown" {
                        // Проверенный отказ до эффекта: следующий tick — новый снимок
                        // разрешённого ref, а не повтор неизвестной операции.
                        status = "HEAD_RECHECK"; terminal = false
                    }
                    outcome["phase"] = e.фаза; outcome["error"] = e.причина
                    if let path = e.оставленныйВременныйФайл { outcome["temporaryPath"] = path }
                } catch {
                    terminal = true; status = "UNKNOWN"; outcome["error"] = String(describing: error)
                }
                outcome["status"] = status
                if let observed { outcome["observedCurrentSHA256"] = observed }
                do { try receipt(outcomePath, outcome) } catch {
                    return завершитьИздателя(state, "UNKNOWN", observed)
                }
                if terminal { return завершитьИздателя(state, status, observed) }
                if status == "HEAD_RECHECK" {
                    return ИтогПоддержанияСтоп(статус: status, наблюдаемыйSHA256: old.sha256)
                }
                state.последнийХэш = observed; state.ревизия = input.revision; state.хэшВходаИздателя = inputRaw.sha256
                if ["стоп", "пауза"].contains(input.action) { return завершитьИздателя(state, "ROOT_CONTROL_PUBLISHED", observed) }
                return ИтогПоддержанияСтоп(статус: "UPDATED", наблюдаемыйSHA256: observed)
            }
        } catch let e as E where e.description.hasPrefix("Lbusy:") {
            return ИтогПоддержанияСтоп(статус: "CURRENT_BUSY", наблюдаемыйSHA256: state.последнийХэш)
        } catch {
            state.ошибка = String(describing: error)
            return завершитьИздателя(state, "FAILED", state.последнийХэш)
        }
    }
    public static func поддерживатьТекущий(_ аргументы: [String]) async -> Int32 {
        let state = СостояниеИздателяСтоп()
        do {
            try need(аргументы.count == 4 && аргументы[0] == "--план"
                && аргументы[2] == "--хэш-плана", "MA0")
            let path = аргументы[1], sha = аргументы[3]
            let (p, _) = try прочитатьЗапросИздателя(path, sha)
            let clock = ContinuousClock(), began = clock.now
            var busySince: ContinuousClock.Instant?
            emit(["status": "STARTING", "requestSHA256": sha,
                "authorityChecked": false, "worklistCompleteness": "UNKNOWN"])
            while !state.завершён {
                if Task.isCancelled { _ = завершитьИздателя(state, "SERVICE_CANCELLED", state.последнийХэш); break }
                if began.duration(to: clock.now).components.seconds >= Int64(p.maxRunSeconds) {
                    _ = завершитьИздателя(state, "RUN_LIMIT", state.последнийХэш); break
                }
                let now = Int64(Date().timeIntervalSince1970)
                let result = try шагПоддержания(path, хэш: sha, состояние: state, сейчас: now)
                if result.статус == "CURRENT_BUSY" {
                    if busySince == nil { busySince = clock.now }
                    if let busySince, busySince.duration(to: clock.now).components.seconds >= Int64(min(5, p.intervalSeconds)) {
                        _ = завершитьИздателя(state, "CURRENT_BUSY_TIMEOUT", state.последнийХэш); break
                    }
                    try await Task.sleep(for: .milliseconds(100))
                    continue
                }
                busySince = nil
                if state.номерШага >= p.maxTicks, !state.завершён {
                    _ = завершитьИздателя(state, "RUN_LIMIT", state.последнийХэш)
                }
                if !state.завершён { try await Task.sleep(for: .seconds(p.intervalSeconds)) }
            }
            var outcome: [String: Any] = ["status": state.конечныйСтатус ?? "STOPPED", "requestSHA256": sha,
                "ticks": state.номерШага, "revision": state.ревизия, "automaticRetry": false,
                "worklistCompleteness": "UNKNOWN", "sourceLeaseRenewedByTimer": false]
            if let seen = state.конечныйХэш ?? state.последнийХэш { outcome["observedCurrentSHA256"] = seen }
            if let error = state.ошибка { outcome["error"] = error }
            emit(outcome)
            return ["SERVICE_STOPPED", "SERVICE_CANCELLED", "ROOT_CONTROL", "ROOT_CONTROL_PUBLISHED",
                "MANUAL_TAKEOVER", "RUN_LIMIT"].contains(state.конечныйСтатус ?? "") ? 0 : 3
        } catch {
            _ = завершитьИздателя(state, "UNKNOWN", state.последнийХэш)
            emit(["status": "UNKNOWN", "error": String(describing: error), "automaticRetry": false])
            return 4
        }
    }
}
