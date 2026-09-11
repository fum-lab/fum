import Foundation
import Darwin
import КонтейнерНаблюдений

struct ИдентичностьКаталога: Equatable, Sendable {
    let устройство: Int32
    let файл: UInt64
}

/// Каждый компонент открывается относительно уже открытого родителя без перехода по ссылкам.
func сПриватнымКаталогом<Результат>(_ путь: URL, _ действие: (Int32, ИдентичностьКаталога) throws -> Результат) throws -> Результат {
    guard путь.isFileURL, путь.path.hasPrefix("/"), путь.path != "/", !путь.path.utf8.contains(0),
          !(путь.absoluteString.removingPercentEncoding?.utf8.contains(0) ?? true),
          !путь.pathComponents.contains("..") else { throw ОшибкаКлиента.доступЗапрещён("Неканонический приватный путь") }
    var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКлиента.доступЗапрещён("Корень пути недоступен") }
    defer { Darwin.close(дескриптор) }
    for компонент in путь.pathComponents.dropFirst() {
        guard компонент != ".", !компонент.isEmpty else { throw ОшибкаКлиента.доступЗапрещён("Неканонический компонент пути") }
        let следующий = openat(дескриптор, компонент, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard следующий >= 0 else { throw ОшибкаКлиента.доступЗапрещён("Каталог отсутствует или содержит ссылку") }
        Darwin.close(дескриптор); дескриптор = следующий
    }
    return try действие(дескриптор, проверитьПриватныйКаталог(дескриптор))
}

func проверитьПриватныйКаталог(_ дескриптор: Int32) throws -> ИдентичностьКаталога {
    var сведения = stat()
    guard fstat(дескриптор, &сведения) == 0, сведения.st_uid == geteuid(),
          сведения.st_mode & S_IFMT == S_IFDIR, сведения.st_mode & 0o7777 == 0o700 else {
        throw ОшибкаКлиента.доступЗапрещён("Нужен собственный приватный каталог 0700")
    }
    try проверитьОтсутствиеРасширенногоДоступа(дескриптор)
    return ИдентичностьКаталога(устройство: сведения.st_dev, файл: сведения.st_ino)
}

func идентичностьПриватногоКаталога(_ путь: URL) throws -> ИдентичностьКаталога {
    try сПриватнымКаталогом(путь) { _, идентичность in идентичность }
}

func проверитьОтсутствиеРасширенногоДоступа(_ дескриптор: Int32) throws {
    do { try проверитьОтсутствиеРасширенныхПрав(дескриптор) }
    catch {
        throw ОшибкаКлиента.доступЗапрещён("ACL присутствует или его отсутствие не доказано")
    }
}

/// Отдельный вход ключа: ровно 32 сырых байта, собственный файл 0600 без ссылок и ACL.
/// Публикуемый ключ нельзя менять на месте; fd и повторная сверка не заменяют согласование писателей.
public func прочитатьПриватныйКлюч(каталог: URL, имяФайла: String) throws -> Data {
    guard !имяФайла.isEmpty, имяФайла != ".", имяФайла != "..",
          !имяФайла.contains("/"), !имяФайла.utf8.contains(0) else {
        throw ОшибкаКлиента.доступЗапрещён("Имя ключа должно быть одним компонентом")
    }
    return try сПриватнымКаталогом(каталог) { родитель, _ in
        let файл = openat(родитель, имяФайла, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаКлиента.доступЗапрещён("Файл ключа недоступен") }
        defer { Darwin.close(файл) }
        func проверить() throws -> stat {
            var сведения = stat()
            guard fstat(файл, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
                  сведения.st_uid == geteuid(), сведения.st_nlink == 1,
                  сведения.st_mode & 0o7777 == 0o600, сведения.st_size == 32 else {
                throw ОшибкаКлиента.доступЗапрещён("Нужен собственный файл ключа 0600 длиной 32 байта")
            }
            try проверитьОтсутствиеРасширенногоДоступа(файл)
            return сведения
        }
        let до = try проверить()
        var данные = Data(count: 32)
        try данные.withUnsafeMutableBytes { байты in
            var смещение = 0
            while смещение < байты.count {
                let число = pread(файл, байты.baseAddress!.advanced(by: смещение), байты.count - смещение, off_t(смещение))
                if число < 0, errno == EINTR { continue }
                guard число > 0 else { throw ОшибкаКлиента.требуетсяРазбор }
                смещение += число
            }
        }
        var лишний: UInt8 = 0
        var число: Int
        repeat { число = pread(файл, &лишний, 1, 32) } while число < 0 && errno == EINTR
        guard число == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
        let после = try проверить()
        var имя = stat()
        guard fstatat(родитель, имяФайла, &имя, AT_SYMLINK_NOFOLLOW) == 0,
              имя.st_dev == после.st_dev, имя.st_ino == после.st_ino,
              до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
              до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec,
              до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec else { throw ОшибкаКлиента.требуетсяРазбор }
        return данные
    }
}
