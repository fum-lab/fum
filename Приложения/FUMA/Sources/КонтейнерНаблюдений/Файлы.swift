import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Android)
import Android
#else
import Glibc
#endif

extension ФайловыеОперации {
    public static let системные = ФайловыеОперации(запись: { дескриптор, буфер in
        let число = write(дескриптор, буфер.baseAddress, буфер.count)
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
    // Android разрешает проход через /data, но не чтение списка его файлов.
    // O_PATH нужен только предкам; конечный каталог читается и синхронизируется.
    #if os(Android)
    let доступПредка = O_PATH
    #else
    let доступПредка = O_RDONLY
    #endif
    var дескриптор = open("/", доступПредка | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    do {
        let компоненты = Array(путь.pathComponents.dropFirst())
        for (номер, компонент) in компоненты.enumerated() {
            guard компонент != ".", !компонент.isEmpty else { throw ОшибкаКонтейнера.небезопасныйПуть }
            let доступ = номер == компоненты.count - 1 ? O_RDONLY : доступПредка
            let следующий = openat(дескриптор, компонент, доступ | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОшибкаКонтейнера.система(errno) }
            close(дескриптор); дескриптор = следующий
        }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0,
              сведения.st_uid == geteuid(), сведения.st_mode & 0o022 == 0 else {
            throw ОшибкаКонтейнера.небезопасныйПуть
        }
        return дескриптор
    } catch { close(дескриптор); throw error }
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
