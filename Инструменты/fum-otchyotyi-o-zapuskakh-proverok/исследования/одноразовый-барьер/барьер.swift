import CryptoKit
import Darwin
import Foundation

// Только исследовательская фикстура. Единый выдаватель, неизменность пространства имён,
// единственный писатель и отсутствие асинхронного повторного входа — внешние
// предпосылки. Неизвестный эффект не разрешает автоматическое освобождение.
struct МеткаКаталога: Equatable {
    let устройство: dev_t
    let номерОбъекта: ino_t
    let владелец: uid_t
    let права: mode_t

    init(_ сведения: stat) throws {
        guard сведения.st_mode & mode_t(S_IFMT) == mode_t(S_IFDIR) else {
            throw ОшибкаБарьера("not-directory")
        }
        устройство = сведения.st_dev
        номерОбъекта = сведения.st_ino
        владелец = сведения.st_uid
        права = сведения.st_mode & 0o7777
    }
}

struct ОшибкаБарьера: Error, Equatable {
    let фаза: String
    let номер: Int32?
    init(_ фаза: String, _ номер: Int32? = nil) {
        self.фаза = фаза
        self.номер = номер
    }
}

struct ОпорыФикстуры {
    let дескрипторОснования: Int32
    let дескрипторРепозитория: Int32
    let дескрипторСессии: Int32
    let дескрипторКорняРезерва: Int32
    let основание: МеткаКаталога
    let репозиторий: МеткаКаталога
    let сессия: МеткаКаталога
    let кореньРезерва: МеткаКаталога

    static func метка(_ дескрипторМетки: Int32) throws -> МеткаКаталога {
        var сведения = stat()
        guard fstat(дескрипторМетки, &сведения) == 0 else { throw ОшибкаБарьера("fstat", errno) }
        return try МеткаКаталога(сведения)
    }

    static func дочернийКаталог(_ дескрипторРодителя: Int32, _ имя: String) throws -> МеткаКаталога {
        var сведения = stat()
        let результат = имя.withCString { fstatat(дескрипторРодителя, $0, &сведения, AT_SYMLINK_NOFOLLOW) }
        guard результат == 0 else { throw ОшибкаБарьера("fstatat-directory", errno) }
        return try МеткаКаталога(сведения)
    }

    init(дескрипторОснования: Int32, дескрипторРепозитория: Int32, дескрипторСессии: Int32, дескрипторКорняРезерва: Int32) throws {
        let дескрипторы = [дескрипторОснования, дескрипторРепозитория, дескрипторСессии, дескрипторКорняРезерва]
        guard Set(дескрипторы).count == дескрипторы.count, дескрипторы.allSatisfy({ $0 >= 0 }) else {
            throw ОшибкаБарьера("descriptor-alias")
        }
        self.дескрипторОснования = дескрипторОснования
        self.дескрипторРепозитория = дескрипторРепозитория
        self.дескрипторСессии = дескрипторСессии
        self.дескрипторКорняРезерва = дескрипторКорняРезерва
        основание = try Self.метка(дескрипторОснования)
        репозиторий = try Self.метка(дескрипторРепозитория)
        сессия = try Self.метка(дескрипторСессии)
        кореньРезерва = try Self.метка(дескрипторКорняРезерва)
        guard Set([основание.номерОбъекта, репозиторий.номерОбъекта, сессия.номерОбъекта, кореньРезерва.номерОбъекта]).count == 4,
              [основание, репозиторий, сессия, кореньРезерва].allSatisfy({ $0.владелец == geteuid() && $0.права == 0o700 }) else {
            throw ОшибкаБарьера("fixture-owner-mode")
        }
        try сверить()
    }

    func сверить() throws {
        let дескрипторы = [дескрипторОснования, дескрипторРепозитория, дескрипторСессии, дескрипторКорняРезерва]
        for дескрипторПроверки in дескрипторы {
            let флаги = fcntl(дескрипторПроверки, F_GETFD)
            guard флаги >= 0 else { throw ОшибкаБарьера("fd-flags", errno) }
            guard флаги & FD_CLOEXEC != 0 else { throw ОшибкаБарьера("fd-cloexec") }
        }
        guard try Self.метка(дескрипторОснования) == основание,
              try Self.метка(дескрипторРепозитория) == репозиторий,
              try Self.метка(дескрипторСессии) == сессия,
              try Self.метка(дескрипторКорняРезерва) == кореньРезерва,
              try Self.дочернийКаталог(дескрипторОснования, "repo") == репозиторий,
              try Self.дочернийКаталог(дескрипторРепозитория, "session") == сессия,
              try Self.дочернийКаталог(дескрипторОснования, "reservations") == кореньРезерва else {
            throw ОшибкаБарьера("fixture-drift")
        }
    }

    var имяРезерва: String {
        let материал = [String(geteuid()), String(репозиторий.устройство), String(репозиторий.номерОбъекта),
                        String(сессия.устройство), String(сессия.номерОбъекта)].joined(separator: ":")
        let хэш = SHA256.hash(data: Data(материал.utf8)).map { String(format: "%02x", $0) }.joined()
        return "fum-v6-life-" + хэш
    }
}

enum СостояниеБарьера: Equatable { case готов, выполняется, допущен, отказано, закрыт, неизвестно }
enum ИсходБарьера: Equatable { case допущен, отказано, закрыт, неизвестно, отклонён }
enum ИсходНаблюдения: Equatable { case занято, отказано, неизвестно, отклонён }
enum МестоОтказа: String {
    case безОтказа = "none"
    case передСозданием = "beforeCreate"
    case послеСоздания = "afterCreate"
    case послеЗаписи = "afterWrite"
    case послеСинхронизацииФайла = "afterFileSync"
    case послеСинхронизацииКаталога = "afterRootSync"
    case послеОсвобождения = "afterUnlock"
    case послеЗакрытия = "afterClose"
}

// Владелец фикстуры выдаёт допуск один раз. Это не промышленный выдаватель;
// единственность его создания и выдачи остаётся внешней предпосылкой модели.
final class ВыдавательФикстуры {
    private var выдан = false
    func выдать(_ опоры: ОпорыФикстуры, отказ: МестоОтказа = .безОтказа,
               передОсвобождением: (() throws -> Void)? = nil) throws -> БарьерФикстуры {
        guard !выдан else { throw ОшибкаБарьера("permit-already-issued") }
        выдан = true
        return БарьерФикстуры(опоры, отказ: отказ, передОсвобождением: передОсвобождением)
    }
}

final class БарьерФикстуры {
    private let опоры: ОпорыФикстуры
    private let отказ: МестоОтказа
    private let передОсвобождением: (() throws -> Void)?
    private let номерПроцессаВладельца = getpid()
    private let потокВладельца = pthread_self()
    private(set) var состояние: СостояниеБарьера = .готов
    private(set) var перваяПричина: ОшибкаБарьера?
    private(set) var событияБарьера: [String] = []
    private(set) var дескрипторМаркера: Int32 = -1
    private(set) var фазаЗамка = "not-started"
    private(set) var фазаЗакрытия = "not-started"

    fileprivate init(_ опоры: ОпорыФикстуры, отказ: МестоОтказа, передОсвобождением: (() throws -> Void)?) {
        self.опоры = опоры
        self.отказ = отказ
        self.передОсвобождением = передОсвобождением
    }

    private func тотЖеВладелец() -> Bool {
        getpid() == номерПроцессаВладельца && pthread_equal(pthread_self(), потокВладельца) != 0
    }

    private func вызватьОтказ(_ текущая: МестоОтказа) throws {
        if отказ == текущая { throw ОшибкаБарьера("injected-" + текущая.rawValue) }
    }

    private func захватить() throws -> Bool {
        фазаЗамка = "lock-started"
        событияБарьера.append("lock")
        if flock(опоры.дескрипторСессии, LOCK_EX | LOCK_NB) == 0 {
            фазаЗамка = "held"
            return true
        }
        let номер = errno
        if номер == EWOULDBLOCK || номер == EAGAIN {
            фазаЗамка = "not-held"
            return false
        }
        фазаЗамка = "unknown"
        throw ОшибкаБарьера("lock", номер)
    }

    private func освободить() throws {
        фазаЗамка = "unlock-started"
        событияБарьера.append("unlock")
        guard flock(опоры.дескрипторСессии, LOCK_UN) == 0 else {
            фазаЗамка = "unknown"
            throw ОшибкаБарьера("unlock", errno)
        }
        try вызватьОтказ(.послеОсвобождения)
        фазаЗамка = "released"
    }

    private func сверитьМаркер() throws {
        var данныеДескриптора = stat()
        var данныеИмени = stat()
        guard fstat(дескрипторМаркера, &данныеДескриптора) == 0 else { throw ОшибкаБарьера("fstat-marker", errno) }
        let результат = опоры.имяРезерва.withCString {
            fstatat(опоры.дескрипторКорняРезерва, $0, &данныеИмени, AT_SYMLINK_NOFOLLOW)
        }
        guard результат == 0 else { throw ОшибкаБарьера("fstatat-marker", errno) }
        guard данныеДескриптора.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG),
              данныеДескриптора.st_uid == geteuid(), данныеДескриптора.st_mode & 0o7777 == 0o600,
              данныеДескриптора.st_nlink == 1, данныеДескриптора.st_size == 7,
              данныеИмени.st_dev == данныеДескриптора.st_dev, данныеИмени.st_ino == данныеДескриптора.st_ino,
              данныеИмени.st_mode == данныеДескриптора.st_mode, данныеИмени.st_uid == данныеДескриптора.st_uid,
              данныеИмени.st_nlink == данныеДескриптора.st_nlink, данныеИмени.st_size == данныеДескриптора.st_size else {
            throw ОшибкаБарьера("marker-drift")
        }
        var байты = [UInt8](repeating: 0, count: 7)
        let прочитаноИзМаркера = байты.withUnsafeMutableBytes { pread(дескрипторМаркера, $0.baseAddress, 7, 0) }
        let номер: Int32? = прочитаноИзМаркера < 0 ? errno : nil
        guard прочитаноИзМаркера == 7, байты == Array("ACTIVE\n".utf8) else {
            throw ОшибкаБарьера("marker-readback", номер)
        }
    }

    @discardableResult func начать() -> ИсходБарьера {
        guard тотЖеВладелец(), состояние == .готов else { return .отклонён }
        состояние = .выполняется
        do {
            try опоры.сверить()
            guard try захватить() else {
                состояние = .отказано
                return .отказано
            }
            try опоры.сверить()
            try вызватьОтказ(.передСозданием)
            событияБарьера.append("create")
            let дескрипторСоздания = опоры.имяРезерва.withCString {
                openat(опоры.дескрипторКорняРезерва, $0,
                       O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            }
            if дескрипторСоздания < 0 {
                let номер = errno
                if номер == EEXIST {
                    try освободить()
                    состояние = .отказано
                    return .отказано
                }
                throw ОшибкаБарьера("create", номер)
            }
            дескрипторМаркера = дескрипторСоздания
            try вызватьОтказ(.послеСоздания)
            var байты = Array("ACTIVE\n".utf8)
            событияБарьера.append("write")
            let записаноВМаркер = байты.withUnsafeMutableBytes { write(дескрипторСоздания, $0.baseAddress, $0.count) }
            guard записаноВМаркер == байты.count else { throw ОшибкаБарьера("write", записаноВМаркер < 0 ? errno : nil) }
            try вызватьОтказ(.послеЗаписи)
            событияБарьера.append("fsync-marker")
            guard fsync(дескрипторСоздания) == 0 else { throw ОшибкаБарьера("fsync-marker", errno) }
            try вызватьОтказ(.послеСинхронизацииФайла)
            событияБарьера.append("fsync-root")
            guard fsync(опоры.дескрипторКорняРезерва) == 0 else { throw ОшибкаБарьера("fsync-root", errno) }
            try вызватьОтказ(.послеСинхронизацииКаталога)
            try опоры.сверить()
            try сверитьМаркер()
            if let передОсвобождением {
                событияБарьера.append("before-unlock")
                try передОсвобождением()
            }
            guard тотЖеВладелец(), состояние == .выполняется, фазаЗамка == "held" else {
                throw ОшибкаБарьера("unknown-after-hook")
            }
            try опоры.сверить()
            try сверитьМаркер()
            try освободить()
            состояние = .допущен
            return .допущен
        } catch {
            состояние = .неизвестно
            if перваяПричина == nil { перваяПричина = (error as? ОшибкаБарьера) ?? ОшибкаБарьера("unexpected") }
            return .неизвестно
        }
    }

    @discardableResult func закончить() -> ИсходБарьера {
        guard тотЖеВладелец(), состояние == .допущен, дескрипторМаркера >= 0 else { return .отклонён }
        do {
            try опоры.сверить()
            try сверитьМаркер()
            фазаЗакрытия = "close-started"
            событияБарьера.append("close")
            guard Darwin.close(дескрипторМаркера) == 0 else { throw ОшибкаБарьера("close", errno) }
            try вызватьОтказ(.послеЗакрытия)
            фазаЗакрытия = "closed"
            состояние = .закрыт
            return .закрыт
        } catch {
            состояние = .неизвестно
            if перваяПричина == nil { перваяПричина = (error as? ОшибкаБарьера) ?? ОшибкаБарьера("unexpected") }
            return .неизвестно
        }
    }
}

// Наблюдатель не имеет допуска. Отсутствие неизвестно, любой объект запрещает
// вход. Только занятый замок можно проверять повторно в пределах общего срока.
final class НаблюдательФикстуры {
    private let опоры: ОпорыФикстуры
    private let номерПроцессаВладельца = getpid()
    private let потокВладельца = pthread_self()
    private(set) var исход: ИсходНаблюдения?
    private(set) var фазаЗамка = "not-started"
    private(set) var перваяПричина: ОшибкаБарьера?
    private(set) var событияНаблюдателя: [String] = []
    private(set) var дескрипторНеожиданногоМаркера: Int32 = -1

    init(_ опоры: ОпорыФикстуры) { self.опоры = опоры }

    func проверить() -> ИсходНаблюдения {
        guard getpid() == номерПроцессаВладельца, pthread_equal(pthread_self(), потокВладельца) != 0 else { return .отклонён }
        if let исход, исход != .занято { return .отклонён }
        do {
            try опоры.сверить()
            фазаЗамка = "lock-started"
            событияНаблюдателя.append("lock")
            guard flock(опоры.дескрипторСессии, LOCK_EX | LOCK_NB) == 0 else {
                let номер = errno
                if номер == EWOULDBLOCK || номер == EAGAIN {
                    фазаЗамка = "not-held"
                    исход = .занято
                    return .занято
                }
                фазаЗамка = "unknown"
                throw ОшибкаБарьера("lock", номер)
            }
            фазаЗамка = "held"
            try опоры.сверить()
            var сведения = stat()
            событияНаблюдателя.append("observe")
            let результат = опоры.имяРезерва.withCString {
                fstatat(опоры.дескрипторКорняРезерва, $0, &сведения, AT_SYMLINK_NOFOLLOW)
            }
            let номер = результат == 0 ? 0 : errno
            guard результат == 0 || номер == ENOENT else { throw ОшибкаБарьера("observe", номер) }
            if результат == 0 {
                событияНаблюдателя.append("verify-excl")
                let дескрипторСтолкновения = опоры.имяРезерва.withCString {
                    openat(опоры.дескрипторКорняРезерва, $0,
                           O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
                }
                if дескрипторСтолкновения >= 0 {
                    дескрипторНеожиданногоМаркера = дескрипторСтолкновения
                    throw ОшибкаБарьера("unexpected-create")
                }
                let ошибкаСоздания = errno
                guard ошибкаСоздания == EEXIST else { throw ОшибкаБарьера("verify-excl", ошибкаСоздания) }
            }
            фазаЗамка = "unlock-started"
            событияНаблюдателя.append("unlock")
            guard flock(опоры.дескрипторСессии, LOCK_UN) == 0 else { throw ОшибкаБарьера("unlock", errno) }
            фазаЗамка = "released"
            исход = результат == 0 ? .отказано : .неизвестно
            if результат != 0 { перваяПричина = ОшибкаБарьера("marker-missing", номер) }
            return исход!
        } catch {
            if перваяПричина == nil { перваяПричина = (error as? ОшибкаБарьера) ?? ОшибкаБарьера("unexpected") }
            исход = .неизвестно
            return .неизвестно
        }
    }
}
