import Foundation
import Darwin

extension ФайловыеОперации {
    public static let системные = ФайловыеОперации(запись: { дескриптор, буфер in
        let число = Darwin.write(дескриптор, буфер.baseAddress, буфер.count)
        if число < 0 { throw ОшибкаКонтейнера.система(errno) }
        return число
    }, синхронизация: { дескриптор in
        if fsync(дескриптор) != 0 { throw ОшибкаКонтейнера.система(errno) }
    })
}

func повторПриСигнале<Значение>(_ действие: () throws -> Значение) throws -> Значение {
    while true {
        do { return try действие() }
        catch ОшибкаКонтейнера.система(let код) where код == EINTR { continue }
    }
}

func открытьКорень(_ путь: URL) throws -> Int32 {
    guard путь.isFileURL, путь.path.hasPrefix("/"), !путь.path.utf8.contains(0),
          !(путь.absoluteString.removingPercentEncoding?.utf8.contains(0) ?? true),
          !путь.pathComponents.contains("..") else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    do {
        for компонент in путь.pathComponents.dropFirst() {
            guard компонент != ".", !компонент.isEmpty else { throw ОшибкаКонтейнера.небезопасныйПуть }
            let следующий = openat(дескриптор, компонент, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОшибкаКонтейнера.система(errno) }
            Darwin.close(дескриптор); дескриптор = следующий
        }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0,
              сведения.st_uid == geteuid(), сведения.st_mode & 0o022 == 0 else {
            throw ОшибкаКонтейнера.небезопасныйПуть
        }
        return дескриптор
    } catch { Darwin.close(дескриптор); throw error }
}

func размерФайла(_ дескриптор: Int32) throws -> Int {
    var сведения = stat()
    guard fstat(дескриптор, &сведения) == 0 else { throw ОшибкаКонтейнера.система(errno) }
    guard сведения.st_mode & S_IFMT == S_IFREG, сведения.st_nlink == 1,
          сведения.st_uid == geteuid(), сведения.st_mode & 0o022 == 0 else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    guard сведения.st_size >= 0, сведения.st_size <= Пределы.сегмент else { throw ОшибкаКонтейнера.предел }
    return Int(сведения.st_size)
}

func прочитать(_ дескриптор: Int32, _ смещение: Int, _ длина: Int) throws -> Data {
    guard длина >= 0, длина <= Пределы.фрагмент, смещение >= 0,
          смещение <= Пределы.сегмент - длина else { throw ОшибкаКонтейнера.предел }
    var данные = Data(count: длина)
    try данные.withUnsafeMutableBytes { (буфер: UnsafeMutableRawBufferPointer) in
        var прочитано = 0
        while прочитано < длина {
            let число = pread(дескриптор, буфер.baseAddress!.advanced(by: прочитано), длина - прочитано, off_t(смещение + прочитано))
            if число < 0 {
                if errno == EINTR { continue }
                throw ОшибкаКонтейнера.система(errno)
            }
            guard число > 0 else { throw ОшибкаКонтейнера.повреждение }
            прочитано += число
        }
    }
    return данные
}
