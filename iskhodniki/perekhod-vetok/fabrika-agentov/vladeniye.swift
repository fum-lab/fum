import Darwin
import Foundation

public enum ОшибкаВладения: Error, Equatable {
    case недоступно, занято, неверныйФайл, освобождено, используется, неверноеНазначение
}

public enum ДоступКВладению: Equatable, Sendable {
    case неизвестно
}

/// Локальный кооперативный lock. Независимый владелец среды предоставляет единственное
/// назначение и гарантирует стабильность его предков; локальный flock не является lease.
public actor ЛокальноеВладение {
    private var дескриптор: Int32
    private let каталог: Int32
    private let ключ: String
    private let исполнитель: ЭкземплярУзла
    public let назначение: НазначениеПространства
    private let устройство: dev_t
    private let inode: ino_t
    private var выполняется = 0
    public let токен: UUID

    /// До реализации доверенного источника ни одно предъявленное назначение не
    /// преобразуется публичным интерфейсом в владение узлом.
    public static func запросить(адрес: АдресУзла, исполнитель: ЭкземплярУзла,
                                 каталог: String, назначение: НазначениеПространства?) -> ДоступКВладению {
        .неизвестно
    }

    init(адрес: АдресУзла, исполнитель: ЭкземплярУзла, каталог путь: String,
                назначение: НазначениеПространства?) throws {
        guard let назначение, назначение.адрес == адрес, назначение.хост == исполнитель.хост,
              !исполнитель.воплощение.isEmpty, путь == назначение.физическийКорень,
              путь.hasPrefix("/"), URL(fileURLWithPath: путь).resolvingSymlinksInPath().standardizedFileURL.path == путь
        else { throw ОшибкаВладения.неверноеНазначение }
        let ключ = try адрес.ключВладения()
        let корень = open(путь, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard корень >= 0 else { throw ОшибкаВладения.неверноеНазначение }
        var сведенияКаталога = stat()
        guard fstat(корень, &сведенияКаталога) == 0,
              (сведенияКаталога.st_mode & mode_t(S_IFMT)) == mode_t(S_IFDIR),
              сведенияКаталога.st_uid == geteuid(), (сведенияКаталога.st_mode & 0o022) == 0,
              UInt64(bitPattern: Int64(сведенияКаталога.st_dev)) == назначение.устройство,
              UInt64(сведенияКаталога.st_ino) == назначение.inode else {
            close(корень)
            throw ОшибкаВладения.неверноеНазначение
        }
        let файл = openat(корень, ключ, O_RDWR | O_CLOEXEC | O_NOFOLLOW)
        guard файл >= 0 else { close(корень); throw ОшибкаВладения.недоступно }
        var сведения = stat()
        guard fstat(файл, &сведения) == 0,
              (сведения.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG),
              сведения.st_uid == geteuid(), сведения.st_nlink == 1,
              (сведения.st_mode & 0o077) == 0 else {
            close(файл); close(корень)
            throw ОшибкаВладения.неверныйФайл
        }
        guard flock(файл, LOCK_EX | LOCK_NB) == 0 else {
            let причина = errno
            close(файл); close(корень)
            throw причина == EWOULDBLOCK ? ОшибкаВладения.занято : ОшибкаВладения.недоступно
        }
        дескриптор = файл
        каталог = корень
        self.ключ = ключ
        self.исполнитель = исполнитель
        self.назначение = назначение
        устройство = сведения.st_dev
        inode = сведения.st_ino
        токен = UUID()
    }

    public func соответствует(адрес: АдресУзла, исполнитель: ЭкземплярУзла,
                              назначение: НазначениеПространства?, токен: UUID) -> Bool {
        назначение == self.назначение && адрес == self.назначение.адрес &&
        исполнитель == self.исполнитель && проверить(токен: токен)
    }

    public func проверить(токен: UUID) -> Bool {
        guard дескриптор >= 0, self.токен == токен, fcntl(дескриптор, F_GETFD) >= 0 else { return false }
        var родитель = stat()
        var открытыйРодитель = stat()
        var сведения = stat()
        guard lstat(назначение.физическийКорень, &родитель) == 0, fstat(каталог, &открытыйРодитель) == 0,
              (родитель.st_mode & mode_t(S_IFMT)) == mode_t(S_IFDIR),
              родитель.st_dev == открытыйРодитель.st_dev, родитель.st_ino == открытыйРодитель.st_ino,
              UInt64(bitPattern: Int64(родитель.st_dev)) == назначение.устройство,
              UInt64(родитель.st_ino) == назначение.inode,
              fstatat(каталог, ключ, &сведения, AT_SYMLINK_NOFOLLOW) == 0,
              (сведения.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG), сведения.st_nlink == 1 else { return false }
        return сведения.st_dev == устройство && сведения.st_ino == inode
    }

    public func освободить(токен: UUID) throws {
        guard проверить(токен: токен) else { throw ОшибкаВладения.освобождено }
        guard выполняется == 0 else { throw ОшибкаВладения.используется }
        guard flock(дескриптор, LOCK_UN) == 0 else { throw ОшибкаВладения.недоступно }
        close(дескриптор)
        дескриптор = -1
    }

    func сВладением<Результат: Sendable>(токен: UUID, операция: @Sendable () async -> Результат) async -> Результат? {
        guard проверить(токен: токен) else { return nil }
        выполняется += 1
        defer { выполняется -= 1 }
        let результат = await операция()
        guard проверить(токен: токен) else { return nil }
        return результат
    }

    deinit {
        if дескриптор >= 0 { close(дескриптор) }
        close(каталог)
    }
}
