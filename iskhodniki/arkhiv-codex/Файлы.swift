import Foundation
import Darwin
import КонтейнерНаблюдений

func открытьПриватныйКаталог(_ путь: URL, закрытие: (Int32) throws -> Void = системноеЗакрытие) throws -> Int32 {
    guard путь.isFileURL, путь.path.hasPrefix("/"), !путь.path.utf8.contains(0) else {
        throw ОшибкаАрхиваКодекса.небезопасныйПуть
    }
    var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    do {
        for компонент in путь.pathComponents.dropFirst() {
            var сведения = stat()
            if fstatat(дескриптор, ".git", &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
                throw ОшибкаАрхиваКодекса.небезопасныйПуть
            }
            guard компонент != "..", компонент != "." else { throw ОшибкаАрхиваКодекса.небезопасныйПуть }
            let новый = openat(дескриптор, компонент, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard новый >= 0 else { throw ОшибкаКонтейнера.система(errno) }
            let старый = дескриптор; дескриптор = новый
            try закрытие(старый)
        }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_uid == geteuid(),
              сведения.st_mode & 0o022 == 0 else { throw ОшибкаАрхиваКодекса.небезопасныйПуть }
        if fstatat(дескриптор, ".git", &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
            throw ОшибкаАрхиваКодекса.небезопасныйПуть
        }
        return дескриптор
    } catch { _ = Darwin.close(дескриптор); throw error }
}

func пустойКаталог(_ путь: URL) throws -> Bool {
    let дескриптор = try открытьПриватныйКаталог(путь)
    guard let поток = fdopendir(дескриптор) else { _ = Darwin.close(дескриптор); throw ОшибкаКонтейнера.система(errno) }
    var пусто = true
    var ошибка: (any Error)?
    while true {
        errno = 0
        guard let запись = readdir(поток) else {
            if errno != 0 { ошибка = ОшибкаКонтейнера.система(errno) }
            break
        }
        let имя = withUnsafePointer(to: &запись.pointee.d_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(запись.pointee.d_namlen) + 1) { String(cString: $0) }
        }
        if имя != "." && имя != ".." { пусто = false; break }
    }
    if closedir(поток) != 0 { ошибка = ошибка ?? ОшибкаКонтейнера.система(errno) }
    if let ошибка { throw ошибка }
    return пусто
}

/// Не накапливает имена сегментов и не выбирает историю по mtime.
func посчитатьСегменты(_ дескриптор: Int32) throws -> Int {
    let копия = dup(дескриптор)
    guard копия >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    guard let поток = fdopendir(копия) else { _ = Darwin.close(копия); throw ОшибкаКонтейнера.система(errno) }
    var количество = 0, максимум = -1
    var ошибка: (any Error)?
    while true {
        errno = 0
        guard let запись = readdir(поток) else {
            if errno != 0 { ошибка = ОшибкаКонтейнера.система(errno) }
            break
        }
        let имя = withUnsafePointer(to: &запись.pointee.d_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(запись.pointee.d_namlen) + 1) { String(cString: $0) }
        }
        if имя == "." || имя == ".." { continue }
        guard let номер = Int(имя), номер >= 0, номер < Int(Int32.max),
              имя == String(format: "%08d", номер) else { ошибка = ОшибкаАрхиваКодекса.повреждение; break }
        количество += 1; максимум = max(максимум, номер)
    }
    if closedir(поток) != 0 { ошибка = ошибка ?? ОшибкаКонтейнера.система(errno) }
    if let ошибка { throw ошибка }
    guard количество == максимум + 1 else { throw ОшибкаАрхиваКодекса.повреждение }
    return количество
}
