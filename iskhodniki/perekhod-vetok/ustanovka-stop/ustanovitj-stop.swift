import Foundation
import CryptoKit
import Darwin

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
        let held = try УдерживаемыйЗамокStop.открыть(pin)
        defer { held.закрыть() }
        return try действие(held.проверить)
    }
}
fileprivate final class УдерживаемыйЗамокStop {
    private var fd: Int32
    private var dir: Int32
    private let pin: СсылкаЗамкаStop
    private let name: String
    private let parentDevice: dev_t
    private let parentInode: ino_t
    private init(fd: Int32, dir: Int32, pin: СсылкаЗамкаStop, name: String, parent: Darwin.stat) {
        self.fd = fd; self.dir = dir; self.pin = pin; self.name = name
        parentDevice = parent.st_dev; parentInode = parent.st_ino
    }
    static func открыть(_ pin: СсылкаЗамкаStop) throws -> УдерживаемыйЗамокStop {
        guard pin.device > 0, pin.inode > 0 else { throw E("L0") }
        let (dir, name) = try АтомарныеБайтыStop.родитель(pin.path)
        var parent = Darwin.stat()
        guard fstat(dir, &parent) == 0, parent.st_mode & 0o7777 == 0o700 else {
            _ = Darwin.close(dir)
            throw E("L1", pin.path)
        }
        let fd = openat(dir, name, O_RDWR | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { _ = Darwin.close(dir); throw E("L2", pin.path) }
        let held = УдерживаемыйЗамокStop(fd: fd, dir: dir, pin: pin, name: name, parent: parent)
        do {
            try held.проверить()
            guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw E("Lbusy", pin.path) }
            try held.проверить()
            return held
        } catch { held.закрыть(); throw error }
    }
    func проверить() throws {
            guard fd >= 0, dir >= 0 else { throw E("Lclosed", pin.path) }
            let (again, againName) = try АтомарныеБайтыStop.родитель(pin.path)
            defer { _ = Darwin.close(again) }
            var a = Darwin.stat(), named = Darwin.stat(), p = Darwin.stat()
            guard againName == name, fstat(again, &p) == 0,
                p.st_dev == parentDevice, p.st_ino == parentInode,
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
private static func git(_ h: H) throws -> String {
 let prefix = h.commonGitDir + "/worktrees/"
 try need(h.gitDir.hasPrefix(prefix)
 && !h.gitDir.dropFirst(prefix.count).contains("/"), "G0")
 func bytes(_ path: String) throws -> Data {
 try AB.прочитать(path, ожидаемыйРежим: nil, предел: 4_096).данные
 }
 let dot = try bytes(h.дерево + "/.git")
 let backlink = try bytes(h.gitDir + "/gitdir")
 let common = try bytes(h.gitDir + "/commondir")
 let selected = try bytes(h.gitDir + "/HEAD")
 try need(dot == Data("gitdir: \(h.gitDir)\n".utf8)
 && backlink == Data("\(h.дерево)/.git\n".utf8)
 && common == Data("../..\n".utf8)
 && selected == Data("ref: \(h.ref)\n".utf8), "G1")
 let data = try bytes(h.commonGitDir + "/" + h.ref)
 guard data.count == 41, data.last == 10 else { throw E("G2") }
 let head = String(decoding: data.dropLast(), as: UTF8.self)
 try need(hex(head, 40), "G3")
 return head
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
 let clock = clock ?? Int64(Date().timeIntervalSince1970), age = h.максимальныйВозрастСекунд
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
 let head = try git(a.h)
 let cur = try current(p, a.h, p.header.sha256, head)
 return (Ctx(planPath: planPath, planSHA: planSHA, config: path,
 parent: try parent(planPath), p: p, current: cur, head: head), mode)
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
  let head = try git(a.h)
  let cur = try current(p, a.h, p.header.sha256, head)
  try need(head == c.head && cur?.sha == initial.sha
   && cur?.action == "продолжать", "C5")
  phase = "atomic"
  return try withoutActuallyEscaping(проверитьЗамок) { check in
   var points = ТочкиАтомарнойЗаменыStop()
   points.передRename = {
    try check()
    let latestHead = try git(a.h)
    let latest = try current(p, a.h, p.header.sha256, latestHead)
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
 throws -> (Publication, H, Data, String?) {
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
 let envelope = try boundEnvelope(candidate, h, p.header.sha256)
 let head: String?
 if envelope.управление.действие == "продолжать" {
  let observed = try git(h)
  _ = try currentBytes(candidate, p.candidate.sha256, h, p.header.sha256, observed)
  head = observed
 } else { head = nil } // Явный доверенный STOP/пауза не зависит от Git и возраста worklist.
 if p.initiallyAbsent {
  var st = Darwin.stat()
  try need(lstat(p.current.path, &st) != 0 && errno == ENOENT, "Cpub1")
 } else {
  let old = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600,
   предел: p.current.maxBytes)
  try need(old.sha256 == p.expectedSHA256, "Cpub2")
 }
 return (p, h, candidate, head)
}
private static func publish(_ argv: [String]) throws -> Int32 {
 let (path, sha, mode) = try args(argv)
 let (p, _, _, head) = try publicationInputs(path, sha)
 if case .apply(let value) = mode { try need(value == p.candidate.sha256, "Apub") }
 var common: [String: Any] = ["operation": "publish-current", "planSHA256": sha,
  "candidateSHA256": p.candidate.sha256,
  "worklistCompleteness": "ROOT_REQUIRED", "acceptedSourceAncestry": "ROOT_REQUIRED",
  "authorityChecked": false, "automaticRetry": false, "automaticRollback": false]
 if let head { common["rootHEAD"] = head }
 if case .check = mode {
  let (_, _, _, freshHead) = try предварительнаяПроверка(p.current.lock) {
   try publicationInputs(path, sha)
  }
  if let freshHead { common["rootHEAD"] = freshHead } else { common.removeValue(forKey: "rootHEAD") }
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
   let (fresh, h, candidate, freshHead) = try publicationInputs(path, sha)
   try need(freshHead == head, "Gpub")
   phase = "atomic"
   return try withoutActuallyEscaping(check) { verify in
    var points = ТочкиАтомарнойЗаменыStop()
    points.передRename = {
     try verify()
     let (_, _, _, latestHead) = try publicationInputs(path, sha)
     try need(latestHead == head, "Gpub2")
     if let head { try need(try git(h) == head, "Gpub3") }
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
 if args.first == "--передать-вход-издателя" { return try publishMaintainerInput(Array(args.dropFirst())) }
 if args.first == "--опубликовать-текущий" { return try publish(Array(args.dropFirst())) }
 let (c, mode) = try load(args)
 switch mode {
 case .check:
  let (fresh, _) = try предварительнаяПроверка(c.p.current.lock) { try load(args) }
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

// Lifecycle рабочего издателя не создаёт финальную диспозицию и не продлевает
// подтверждение содержания. ROOT выдаёт отдельную конечную аренду входа.
final class СостояниеИздателяStop {
    var последнийSHA256: String?
    var ревизия: Int64 = 0
    var завершён = false
    var ошибка: String?
    fileprivate var замок: УдерживаемыйЗамокStop?
    fileprivate var requestSHA: String?
    fileprivate var inputSHA: String?
    fileprivate var lastClock: Int64?
    fileprivate var startedAt: Int64?
    fileprivate var reserved = false
    fileprivate var tick = 0
    fileprivate var terminal: String?
    fileprivate var terminalSHA: String?
}
struct ИтогПоддержанияStop: Sendable {
    let статус: String
    let наблюдаемыйSHA256: String?
}
private struct MaintainerRequest: Decodable {
    let schema, runID: String
    let header: Pin
    let current: CPin
    let singleton: СсылкаЗамкаStop
    let input: MaintainerInputPath
    let initialCurrentSHA256, requiredUnknownID, headPolicy: String
    let intervalSeconds, ttlSeconds, maxTicks, maxRunSeconds: Int
}
private struct MaintainerInputPath: Decodable {
    let path: String
    let mode: UInt32
    let maxBytes: Int
}
private struct MaintainerInput: Decodable {
    let schema, root, node, scope, generation, headerSHA256: String
    let revision, approvedAt, validUntil: Int64
    let action, reason: String
    let payload: Pin?
}
private struct MaintainerInputPublication: Decodable {
    let schema: String
    let request, candidate: Pin
    let initiallyAbsent: Bool
    let expectedSHA256: String?
}
private struct УсловияВходаИздателяStop: Decodable {
    let свояОбласть, естьПолномочия, неизвестныйОпасныйЭффект: Bool
    let естьНакопленноеПродвижение, можноБезопасноПродолжать, доступнаНезависимаяРабота: Bool
    let локальнаяИсправимаяПроблема, остановкаЗадачи, естьБезопасныйСледующийШаг: Bool
}
extension УстановщикStop {
    private static func finishMaintainer(_ state: СостояниеИздателяStop, _ status: String,
        _ sha: String? = nil) -> ИтогПоддержанияStop {
        state.завершён = true; state.terminal = status; state.terminalSHA = sha
        state.замок?.закрыть(); state.замок = nil
        return ИтогПоддержанияStop(статус: status, наблюдаемыйSHA256: sha)
    }
    private static func maintainerRequest(_ path: String, _ sha: String) throws -> (MaintainerRequest, H) {
        try need(abs(path) && hex(sha, 64), "MR0")
        let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
        try need(raw.sha256 == sha, "MR1", path)
        let p = try dec(MaintainerRequest.self, raw.данные)
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
    private static func boundEnvelope(_ bytes: Data, _ h: H, _ headerSHA: String) throws -> Envelope {
        let e = try dec(Envelope.self, bytes)
        try need(e.схема == "fum.текущие-обязательства-stop.2" && e.заголовокSHA256 == headerSHA
            && e.задача == h.задача && e.узел == h.узел && e.область == h.область
            && e.поколение == h.поколение && text(e.управление.основание)
            && ["продолжать", "стоп", "пауза"].contains(e.управление.действие), "ME0")
        return e
    }
    private static func maintainerInput(_ p: MaintainerRequest, _ h: H)
        throws -> (MaintainerInput, СнимокБайтовStop) {
        let raw = try AB.прочитать(p.input.path, ожидаемыйРежим: 0o600, предел: p.input.maxBytes)
        return (try decodeMaintainerInput(raw.данные, p, h), raw)
    }
    private static func decodeMaintainerInput(_ bytes: Data, _ p: MaintainerRequest, _ h: H) throws -> MaintainerInput {
        let v = try dec(MaintainerInput.self, bytes)
        try need(v.schema == "fum.stop-maintainer-input.1" && v.root == h.задача
            && v.node == h.узел && v.scope == h.область && v.generation == h.поколение
            && v.headerSHA256 == p.header.sha256 && v.revision >= 0 && text(v.reason)
            && ["обновлять", "остановить-издатель", "стоп", "пауза"].contains(v.action), "MI0")
        return v
    }
    private static func maintainerPayload(_ p: MaintainerRequest, _ h: H,
        _ v: MaintainerInput, inputSHA: String, requestSHA: String, head: String, now: Int64) throws -> Data {
        guard let pin = v.payload else { throw E("MIpayload") }
        let raw = try read(pin, 0o600, p.current.maxBytes)
        let e = try boundEnvelope(raw.данные, h, p.header.sha256)
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
        let проверенныеУсловия = try dec(УсловияВходаИздателяStop.self,
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
    private static func inputPublication(_ path: String, _ sha: String)
        throws -> (MaintainerInputPublication, MaintainerRequest, H, СнимокБайтовStop, MaintainerInput) {
        try need(abs(path) && hex(sha, 64), "MP0")
        let raw = try AB.прочитать(path, ожидаемыйРежим: 0o600, предел: 65_536)
        try need(raw.sha256 == sha, "MP1")
        let plan = try dec(MaintainerInputPublication.self, raw.данные)
        try need(plan.schema == "fum.stop-maintainer-input-publication.1"
            && (plan.initiallyAbsent ? plan.expectedSHA256 == nil : hex(plan.expectedSHA256 ?? "", 64)), "MP2")
        _ = try read(plan.request, 0o600, 65_536)
        let (p, h) = try maintainerRequest(plan.request.path, plan.request.sha256)
        let candidate = try read(plan.candidate, 0o600, p.input.maxBytes)
        let v = try decodeMaintainerInput(candidate.данные, p, h)
        if v.action == "обновлять" {
            let now = Int64(Date().timeIntervalSince1970)
            try need(v.revision >= 1 && v.approvedAt >= 0 && v.approvedAt <= now
                && v.approvedAt <= Int64.max - 86_400 && v.validUntil > now
                && v.validUntil - v.approvedAt <= 86_400, "MPlease")
            guard let pin = v.payload else { throw E("MPpayload") }
            let payload = try read(pin, 0o600, p.current.maxBytes)
            let meta = try dec(Meta.self, payload.данные)
            _ = try maintainerPayload(p, h, v, inputSHA: candidate.sha256,
                requestSHA: plan.request.sha256, head: meta.HEAD, now: now)
        }
        return (plan, p, h, candidate, v)
    }
    private static func publishMaintainerInput(_ argv: [String]) throws -> Int32 {
        let (path, sha, mode) = try args(argv)
        let (_, initial, _, _, _) = try inputPublication(path, sha)
        return try ЗамокТекущегоStop.выполнить(initial.current.lock) { check in
            let (plan, p, _, candidate, v) = try inputPublication(path, sha)
            if case .apply(let value) = mode { try need(value == candidate.sha256, "MPcandidate") }
            if plan.initiallyAbsent {
                var s = Darwin.stat()
                try need(lstat(p.input.path, &s) != 0 && errno == ENOENT, "MPabsent")
            } else {
                let old = try AB.прочитать(p.input.path, ожидаемыйРежим: 0o600, предел: p.input.maxBytes)
                try need(old.sha256 == plan.expectedSHA256, "MPold")
                let oldVersion = try dec(MaintainerInput.self, old.данные)
                try need(v.revision > oldVersion.revision, "MPrev")
            }
            var common: [String: Any] = ["operation": "publish-maintainer-input", "planSHA256": sha,
                "requestSHA256": plan.request.sha256, "candidateSHA256": candidate.sha256,
                "revision": v.revision, "authorityChecked": false, "worklistCompleteness": "UNKNOWN",
                "automaticRetry": false, "automaticRollback": false]
            if case .check = mode {
                common["status"] = "METADATA_CHECKED"; common["writes"] = 0; emit(common); return 0
            }
            // Обычный busy уже обработан до резервирования стабильного намерения.
            let paths = try receiptPaths(config: p.input.path,
                oldSHA: plan.expectedSHA256 ?? AB.sha256(Data("ABSENT".utf8)),
                candidateSHA: candidate.sha256, publication: true)
            common["intentReceipt"] = paths.intent; common["outcomeReceipt"] = paths.outcome
            var intent = common; intent["status"] = "INTENT"
            try receipt(paths.intent, intent)
            var code: Int32 = 2
            do {
                let result = try withoutActuallyEscaping(check) { verify in
                    var points = ТочкиАтомарнойЗаменыStop()
                    points.передRename = { try verify(); _ = try inputPublication(path, sha) }
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
            do { try receipt(paths.outcome, common) } catch {
                common["status"] = "UNKNOWN"; common["receiptError"] = String(describing: error); code = 5
            }
            emit(common); return code
        }
    }
    static func шагПоддержания(_ путь: String, хэш: String,
        состояние: СостояниеИздателяStop, сейчас: Int64,
        точки: ТочкиАтомарнойЗаменыStop = ТочкиАтомарнойЗаменыStop(),
        часыПередRename: @escaping () throws -> Int64 = { Int64(Date().timeIntervalSince1970) }) throws -> ИтогПоддержанияStop {
        let state = состояние
        if state.завершён { return ИтогПоддержанияStop(статус: state.terminal ?? "STOPPED", наблюдаемыйSHA256: state.terminalSHA) }
        do {
            let (p, h) = try maintainerRequest(путь, хэш)
            try need(сейчас >= 0 && сейчас <= Int64.max - 86_400, "Mclock")
            if let requestSHA = state.requestSHA, requestSHA != хэш { return finishMaintainer(state, "REQUEST_CHANGED") }
            if state.замок == nil {
                do { state.замок = try УдерживаемыйЗамокStop.открыть(p.singleton) }
                catch let e as E where e.description.hasPrefix("Lbusy:") { return finishMaintainer(state, "SINGLETON_BUSY") }
            }
            state.requestSHA = хэш
            if state.startedAt == nil { state.startedAt = сейчас }
            return try ЗамокТекущегоStop.выполнить(p.current.lock) { checkLock in
                try state.замок?.проверить(); _ = try maintainerRequest(путь, хэш)
                let old = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600, предел: p.current.maxBytes)
                let oldEnvelope = try boundEnvelope(old.данные, h, p.header.sha256)
                if oldEnvelope.управление.действие != "продолжать" { return finishMaintainer(state, "ROOT_CONTROL", old.sha256) }
                let stem = try parent(p.current.path) + "/.fum-stop-maintainer-" + хэш
                let attempt = stem + ".attempt.json"
                if !state.reserved {
                    var s = Darwin.stat()
                    if lstat(attempt, &s) == 0 { return finishMaintainer(state, "RECOVERY_REQUIRED", old.sha256) }
                    try need(errno == ENOENT, "Mattempt")
                }
                if old.sha256 != (state.последнийSHA256 ?? p.initialCurrentSHA256) {
                    return finishMaintainer(state, "MANUAL_TAKEOVER", old.sha256)
                }
                let (input, inputRaw) = try maintainerInput(p, h)
                if input.action == "остановить-издатель" { return finishMaintainer(state, "SERVICE_STOPPED", old.sha256) }
                if input.action == "обновлять" {
                    if let prior = state.lastClock, сейчас < prior { return finishMaintainer(state, "CLOCK_REGRESSION", old.sha256) }
                    if input.revision < state.ревизия { return finishMaintainer(state, "INPUT_REVISION_ROLLBACK", old.sha256) }
                    if let prior = state.inputSHA, input.revision == state.ревизия && prior != inputRaw.sha256 {
                        return finishMaintainer(state, "INPUT_REVISION_REUSED", old.sha256)
                    }
                    try need(input.revision >= 1 && input.approvedAt >= 0 && input.approvedAt <= сейчас
                        && input.approvedAt <= Int64.max - 86_400
                        && input.validUntil >= input.approvedAt && input.validUntil - input.approvedAt <= 86_400, "MIlease")
                    if input.validUntil <= сейчас { return finishMaintainer(state, "SOURCE_EXPIRED", old.sha256) }
                    if state.tick >= p.maxTicks || сейчас - (state.startedAt ?? сейчас) >= Int64(p.maxRunSeconds) {
                        return finishMaintainer(state, "RUN_LIMIT", old.sha256)
                    }
                }
                state.lastClock = сейчас
                let candidate: Data
                var observedHead: String?
                if ["стоп", "пауза"].contains(input.action) {
                    let object: [String: Any] = ["схема": "fum.текущие-обязательства-stop.2",
                        "заголовокSHA256": p.header.sha256, "задача": h.задача, "узел": h.узел,
                        "область": h.область, "поколение": h.поколение,
                        "управление": ["действие": input.action, "основание": input.reason]]
                    var bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
                    bytes.append(10); candidate = bytes
                } else {
                    let head = try git(h); observedHead = head
                    if p.headPolicy == "strict", let pin = input.payload {
                        let raw = try read(pin, 0o600, p.current.maxBytes)
                        let meta = try dec(Meta.self, raw.данные)
                        if head != meta.HEAD { return finishMaintainer(state, "HEAD_CHANGED", old.sha256) }
                    }
                    candidate = try maintainerPayload(p, h, input, inputSHA: inputRaw.sha256,
                        requestSHA: хэш, head: head, now: сейчас)
                }
                if candidate == old.данные {
                    state.ревизия = input.revision; state.inputSHA = inputRaw.sha256
                    state.последнийSHA256 = old.sha256
                    return ИтогПоддержанияStop(статус: "NO_CHANGE", наблюдаемыйSHA256: old.sha256)
                }
                if !state.reserved {
                    try receipt(attempt, ["schema": "fum.stop-maintainer-attempt.1", "requestSHA256": хэш,
                        "runID": p.runID, "root": h.задача, "inputSHA256": inputRaw.sha256,
                        "expectedCurrentSHA256": old.sha256, "status": "INTENT", "automaticRetry": false])
                    state.reserved = true
                }
                state.tick += 1
                let tickStem = stem + ".tick-" + String(format: "%08d", state.tick)
                let intentPath = tickStem + ".intent.json", outcomePath = tickStem + ".outcome.json"
                var outcome: [String: Any] = ["requestSHA256": хэш, "inputSHA256": inputRaw.sha256,
                    "revision": input.revision, "tick": state.tick, "expectedCurrentSHA256": old.sha256,
                    "candidateSHA256": AB.sha256(candidate), "automaticRetry": false, "automaticRollback": false]
                var intent = outcome; intent["status"] = "INTENT"
                try receipt(intentPath, intent)
                var observed: String?, status = "FAILED", terminal = false
                do {
                    let result = try withoutActuallyEscaping(checkLock) { verify in
                        var points = точки
                        let caller = points.передRename
                        points.передRename = {
                            try caller?(); try verify(); try state.замок?.проверить()
                            _ = try maintainerRequest(путь, хэш)
                            let (_, latestInput) = try maintainerInput(p, h)
                            try need(latestInput.sha256 == inputRaw.sha256, "MIchanged")
                            let latestCurrent = try AB.прочитать(p.current.path, ожидаемыйРежим: 0o600, предел: p.current.maxBytes)
                            try need(latestCurrent.sha256 == old.sha256, "MCchanged")
                            if let observedHead {
                                try need(try git(h) == observedHead, "MGchanged")
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
                    return finishMaintainer(state, "UNKNOWN", observed)
                }
                if terminal { return finishMaintainer(state, status, observed) }
                if status == "HEAD_RECHECK" {
                    return ИтогПоддержанияStop(статус: status, наблюдаемыйSHA256: old.sha256)
                }
                state.последнийSHA256 = observed; state.ревизия = input.revision; state.inputSHA = inputRaw.sha256
                if ["стоп", "пауза"].contains(input.action) { return finishMaintainer(state, "ROOT_CONTROL_PUBLISHED", observed) }
                return ИтогПоддержанияStop(статус: "UPDATED", наблюдаемыйSHA256: observed)
            }
        } catch let e as E where e.description.hasPrefix("Lbusy:") {
            return ИтогПоддержанияStop(статус: "CURRENT_BUSY", наблюдаемыйSHA256: state.последнийSHA256)
        } catch {
            state.ошибка = String(describing: error)
            return finishMaintainer(state, "FAILED", state.последнийSHA256)
        }
    }
    public static func поддерживатьТекущий(_ аргументы: [String]) async -> Int32 {
        let state = СостояниеИздателяStop()
        do {
            try need(аргументы.count == 4 && аргументы[0] == "--план"
                && аргументы[2] == "--хэш-плана", "MA0")
            let path = аргументы[1], sha = аргументы[3]
            let (p, _) = try maintainerRequest(path, sha)
            let clock = ContinuousClock(), began = clock.now
            var busySince: ContinuousClock.Instant?
            emit(["status": "STARTING", "requestSHA256": sha,
                "authorityChecked": false, "worklistCompleteness": "UNKNOWN"])
            while !state.завершён {
                if Task.isCancelled { _ = finishMaintainer(state, "SERVICE_CANCELLED", state.последнийSHA256); break }
                if began.duration(to: clock.now).components.seconds >= Int64(p.maxRunSeconds) {
                    _ = finishMaintainer(state, "RUN_LIMIT", state.последнийSHA256); break
                }
                let now = Int64(Date().timeIntervalSince1970)
                let result = try шагПоддержания(path, хэш: sha, состояние: state, сейчас: now)
                if result.статус == "CURRENT_BUSY" {
                    if busySince == nil { busySince = clock.now }
                    if let busySince, busySince.duration(to: clock.now).components.seconds >= Int64(min(5, p.intervalSeconds)) {
                        _ = finishMaintainer(state, "CURRENT_BUSY_TIMEOUT", state.последнийSHA256); break
                    }
                    try await Task.sleep(for: .milliseconds(100))
                    continue
                }
                busySince = nil
                if state.tick >= p.maxTicks, !state.завершён {
                    _ = finishMaintainer(state, "RUN_LIMIT", state.последнийSHA256)
                }
                if !state.завершён { try await Task.sleep(for: .seconds(p.intervalSeconds)) }
            }
            var outcome: [String: Any] = ["status": state.terminal ?? "STOPPED", "requestSHA256": sha,
                "ticks": state.tick, "revision": state.ревизия, "automaticRetry": false,
                "worklistCompleteness": "UNKNOWN", "sourceLeaseRenewedByTimer": false]
            if let seen = state.terminalSHA ?? state.последнийSHA256 { outcome["observedCurrentSHA256"] = seen }
            if let error = state.ошибка { outcome["error"] = error }
            emit(outcome)
            return ["SERVICE_STOPPED", "SERVICE_CANCELLED", "ROOT_CONTROL", "ROOT_CONTROL_PUBLISHED",
                "MANUAL_TAKEOVER", "RUN_LIMIT"].contains(state.terminal ?? "") ? 0 : 3
        } catch {
            _ = finishMaintainer(state, "UNKNOWN", state.последнийSHA256)
            emit(["status": "UNKNOWN", "error": String(describing: error), "automaticRetry": false])
            return 4
        }
    }
}
