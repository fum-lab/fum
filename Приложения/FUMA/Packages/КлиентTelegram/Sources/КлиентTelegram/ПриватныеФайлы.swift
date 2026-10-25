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

func проверитьОтсутствиеРасширенныхПрав(_ дескриптор: Int32) throws {
    guard let безопасность = filesec_init() else { throw ОшибкаКлиента.доступЗапрещён("Не удалось проверить ACL") }
    defer { filesec_free(безопасность) }
    var сведения = stat()
    var естьРежим: Int32 = 0
    var режим: mode_t = 0
    var естьСписок: Int32 = 0
    guard fstatx_np(дескриптор, &сведения, безопасность) == 0,
          filesec_query_property(безопасность, FILESEC_MODE, &естьРежим) == 0, естьРежим != 0,
          filesec_get_property(безопасность, FILESEC_MODE, &режим) == 0, режим == сведения.st_mode,
          filesec_query_property(безопасность, FILESEC_ACL, &естьСписок) == 0, естьСписок == 0 else {
        throw ОшибкаКлиента.доступЗапрещён("ACL присутствует или его отсутствие не доказано")
    }
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

func проверитьПриватностьСегмента(корень: URL, отсутствиеРазрешено: Bool = false) throws {
    try сПриватнымКаталогом(корень) { родитель, _ in
        let имя = "сегмент.fumobs"
        let файл = openat(родитель, имя, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else {
            if отсутствиеРазрешено && errno == ENOENT { return }
            throw ОшибкаКлиента.доступЗапрещён("Сегмент журнала недоступен")
        }
        defer { Darwin.close(файл) }
        var сведения = stat(), имяНаДиске = stat()
        guard fstat(файл, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
              сведения.st_uid == geteuid(), сведения.st_nlink == 1, сведения.st_mode & 0o7777 == 0o600,
              fstatat(родитель, имя, &имяНаДиске, AT_SYMLINK_NOFOLLOW) == 0,
              имяНаДиске.st_dev == сведения.st_dev, имяНаДиске.st_ino == сведения.st_ino else {
            throw ОшибкаКлиента.доступЗапрещён("Нужен собственный файл сегмента 0600 без ссылок")
        }
        try проверитьОтсутствиеРасширенногоДоступа(файл)
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
