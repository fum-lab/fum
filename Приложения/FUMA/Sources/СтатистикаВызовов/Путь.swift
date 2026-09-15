import Foundation
import Darwin

func проверитьПустойКаталогПрофиля(_ путь: URL) throws {
    // Физический проход без symlink до первой записи синтетической фикстуры.
    var дескриптор = open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаСтатистики.система(errno) }
    defer { _ = close(дескриптор) }
    for часть in путь.pathComponents.dropFirst() {
        guard часть != ".", часть != "..", !часть.isEmpty else { throw ОшибкаСтатистики.небезопасныйПуть }
        let следующий = openat(дескриптор, часть, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard следующий >= 0 else { throw ОшибкаСтатистики.система(errno) }
        _ = close(дескриптор); дескриптор = следующий
    }
    var сведения = stat()
    guard fstat(дескриптор, &сведения) == 0, сведения.st_uid == geteuid(),
          сведения.st_mode & 0o022 == 0 else { throw ОшибкаСтатистики.небезопасныйПуть }
    let копия = dup(дескриптор)
    guard копия >= 0 else { throw ОшибкаСтатистики.система(errno) }
    guard let каталог = fdopendir(копия) else { _ = close(копия); throw ОшибкаСтатистики.система(errno) }
    defer { _ = closedir(каталог) }
    while true {
        errno = 0
        guard let запись = readdir(каталог) else {
            if errno != 0 { throw ОшибкаСтатистики.система(errno) }
            break
        }
        let имя = withUnsafePointer(to: &запись.pointee.d_name) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        guard имя == "." || имя == ".." else { throw ОшибкаСтатистики.небезопасныйПуть }
    }
}

struct ИдентичностьФайла: Equatable, Sendable {
    let устройство: Int32
    let узел: UInt64
}
func идентичностьФайла(_ путь: URL, каталог: Bool) throws -> ИдентичностьФайла {
    var сведения = stat()
    guard lstat(путь.path, &сведения) == 0 else { throw ОшибкаСтатистики.система(errno) }
    guard сведения.st_mode & S_IFMT == (каталог ? S_IFDIR : S_IFREG) else { throw ОшибкаСтатистики.небезопасныйПуть }
    return ИдентичностьФайла(устройство: сведения.st_dev, узел: сведения.st_ino)
}

func существуетБезСледования(_ путь: URL) throws -> Bool {
    var сведения = stat()
    if lstat(путь.path, &сведения) == 0 { return true }
    if errno == ENOENT { return false }
    throw ОшибкаСтатистики.система(errno)
}
func проверитьВыходВнеРепозитория(_ корень: URL) throws {
    guard корень.isFileURL, корень.path.hasPrefix("/"), !корень.pathComponents.contains(".."),
          !корень.path.utf8.contains(0), !корень.absoluteString.lowercased().contains("%00") else {
        throw ОшибкаСтатистики.небезопасныйПуть
    }
    guard let физический = realpath(корень.path, nil) else { throw ОшибкаСтатистики.система(errno) }
    defer { free(физический) }
    var путь = URL(fileURLWithPath: String(cString: физический))
    while true {
        if try существуетБезСледования(путь.appendingPathComponent(".git")) {
            throw ОшибкаСтатистики.небезопасныйПуть
        }
        if try существуетБезСледования(путь.appendingPathComponent("HEAD")),
           try существуетБезСледования(путь.appendingPathComponent("objects")),
           try существуетБезСледования(путь.appendingPathComponent("refs")) { throw ОшибкаСтатистики.небезопасныйПуть }
        if путь.path == "/" { break }
        путь.deleteLastPathComponent()
    }
}
