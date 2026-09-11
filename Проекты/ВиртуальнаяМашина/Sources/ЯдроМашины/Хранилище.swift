import Foundation
import Darwin

public struct ПаспортМашины: Codable {
    public var схема = "fum.паспорт-машины.1"
    public var идентификатор: String
    public var план: ПланМашины
}

public final class ЧтениеХранилища {
    public private(set) var паспорт: ПаспортМашины!
    private var каталог: Int32 = -1
    public init(_ путь: String) throws {
        каталог = try открытьКаталог(путь)
        do {
            var сведения = stat()
            guard fstat(каталог, &сведения) == 0, сведения.st_uid == getuid(), сведения.st_mode & 0o077 == 0 else {
                throw ОшибкаМашины("Каталог VM не является личным.")
            }
            паспорт = try JSONDecoder().decode(ПаспортМашины.self, from: прочитать("паспорт.json"))
            try паспорт.план.проверить()
            guard паспорт.схема == "fum.паспорт-машины.1", UUID(uuidString: паспорт.идентификатор) != nil,
                  паспорт.план.каталог == путь else { throw ОшибкаМашины("Паспорт не соответствует каталогу VM.") }
        } catch { close(каталог); каталог = -1; throw error }
    }
    deinit { if каталог >= 0 { close(каталог) } }
    public func прочитать(_ имя: String) throws -> Data {
        try проверитьИмя(имя)
        let файл = openat(каталог, имя, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаМашины("Метаданные VM ещё недоступны: \(имя).") }
        defer { close(файл) }
        try проверитьОбычный(файл)
        let поток = FileHandle(fileDescriptor: файл, closeOnDealloc: false)
        let байты = try поток.read(upToCount: 4 * 1024 * 1024 + 1) ?? Data()
        guard байты.count <= 4 * 1024 * 1024 else { throw ОшибкаМашины("Метаданные превысили 4 MiB.") }
        return байты
    }
}

private func проверитьИмя(_ имя: String) throws {
    guard !имя.isEmpty, имя != ".", имя != "..", !имя.contains("/"), !имя.contains("\0") else {
        throw ОшибкаМашины("Имя артефакта выходит из личного каталога.")
    }
}

// Каждый компонент открывается относительно уже проверенного дескриптора.
// Это сохраняет границу даже при переименовании предка другим процессом.
public func открытьКаталог(_ путь: String, создатьРодителей: Bool = false) throws -> Int32 {
    guard путь.hasPrefix("/"), !путь.contains("\0") else { throw ОшибкаМашины("Нужен абсолютный путь.") }
    var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаМашины("Не удалось открыть корень файловой системы.") }
    do {
        for часть in путь.split(separator: "/").map(String.init) {
            try проверитьИмя(часть)
            var следующий = openat(дескриптор, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            if следующий < 0, errno == ENOENT, создатьРодителей {
                guard mkdirat(дескриптор, часть, 0o700) == 0 || errno == EEXIST else {
                    throw ОшибкаМашины("Не удалось создать родительский каталог VM.")
                }
                следующий = openat(дескриптор, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            guard следующий >= 0 else { throw ОшибкаМашины("Компонент пути «\(часть)» отсутствует, недоступен или содержит символическую ссылку (errno \(errno)).") }
            close(дескриптор); дескриптор = следующий
        }
        return дескриптор
    } catch { close(дескриптор); throw error }
}

private func проверитьОбычный(_ дескриптор: Int32) throws {
    var сведения = stat()
    guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
          сведения.st_uid == getuid(), сведения.st_nlink == 1, сведения.st_mode & 0o077 == 0 else {
        throw ОшибкаМашины("Артефакт должен быть обычным личным файлом без жёстких ссылок и доступа группы/остальных.")
    }
}

public final class Хранилище {
    public let путь: String
    public private(set) var паспорт: ПаспортМашины!
    public private(set) var дескриптор: Int32 = -1
    private var замок: Int32 = -1

    public init(план: ПланМашины, создать: Bool) throws {
        try план.проверить()
        путь = план.каталог
        let адрес = URL(fileURLWithPath: путь)
        // Поиск .git идёт до существующего предка, включая потенциально отсутствующую цель.
        var предок = адрес
        while предок.path != "/" {
            if FileManager.default.fileExists(atPath: предок.appendingPathComponent(".git").path) {
                throw ОшибкаМашины("Образы и ключи VM запрещено создавать внутри Git checkout.")
            }
            предок.deleteLastPathComponent()
        }
        let родитель = try открытьКаталог(адрес.deletingLastPathComponent().path, создатьРодителей: создать)
        defer { close(родитель) }
        let имя = адрес.lastPathComponent
        var сведения = stat()
        let существует = fstatat(родитель, имя, &сведения, AT_SYMLINK_NOFOLLOW) == 0
        if !существует {
            guard errno == ENOENT, создать else { throw ОшибкаМашины("VM ещё не подготовлена.") }
            let временное = ".создание-" + UUID().uuidString.lowercased()
            guard mkdirat(родитель, временное, 0o700) == 0 else { throw ОшибкаМашины("Не удалось начать создание VM.") }
            let каталог = openat(родитель, временное, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard каталог >= 0 else { throw ОшибкаМашины("Не удалось открыть каталог создания.") }
            defer { close(каталог) }
            let новый = ПаспортМашины(идентификатор: UUID().uuidString.lowercased(), план: план)
            try Self.записатьВ(каталог, имя: "паспорт.json", байты: кодировать(новый))
            guard renameatx_np(родитель, временное, родитель, имя, UInt32(RENAME_EXCL)) == 0 else {
                throw ОшибкаМашины("Цель занята или создание прервано. Собственный staging сохранён.")
            }
            guard fsync(родитель) == 0 else { throw ОшибкаМашины("Не удалось долговечно установить каталог VM.") }
        }
        дескриптор = openat(родитель, имя, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard дескриптор >= 0 else { throw ОшибкаМашины("Цель не является обычным каталогом VM.") }
        guard fstat(дескриптор, &сведения) == 0, сведения.st_uid == getuid(), сведения.st_mode & 0o077 == 0 else {
            close(дескриптор); дескриптор = -1
            throw ОшибкаМашины("Личный каталог VM должен принадлежать пользователю и иметь права 0700.")
        }
        do {
            паспорт = try JSONDecoder().decode(ПаспортМашины.self, from: прочитать("паспорт.json"))
            guard паспорт.схема == "fum.паспорт-машины.1", UUID(uuidString: паспорт.идентификатор) != nil,
                  паспорт.план == план else {
                throw ОшибкаМашины("Каталог принадлежит другому плану. Сохраните прежнюю VM и выберите новую цель.")
            }
            замок = openat(дескриптор, "замок", O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0o600)
            guard замок >= 0 else { throw ОшибкаМашины("Не удалось открыть постоянный замок VM.") }
            try проверитьОбычный(замок)
            guard flock(замок, LOCK_EX | LOCK_NB) == 0 else { throw ОшибкаМашины("VM занята другим исполнителем или запущена.") }
        } catch {
            if замок >= 0 { close(замок); замок = -1 }
            close(дескриптор); дескриптор = -1
            throw error
        }
    }
    deinit { if замок >= 0 { close(замок) }; if дескриптор >= 0 { close(дескриптор) } }

    func именаАртефактов() throws -> [String] {
        // Отдельное open file description: dup разделил бы курсор каталога с владельцем.
        let копия = openat(дескриптор, ".", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard копия >= 0 else { throw ОшибкаМашины("Не удалось прочитать каталог артефактов.") }
        guard let поток = fdopendir(копия) else { close(копия); throw ОшибкаМашины("Не удалось открыть перечисление артефактов.") }
        defer { closedir(поток) }
        var имена: [String] = []
        while true {
            errno = 0
            guard let запись = readdir(поток) else {
                guard errno == 0 else { throw ОшибкаМашины("Перечисление артефактов прервано.") }
                break
            }
            let имя = withUnsafePointer(to: запись.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(запись.pointee.d_namlen) + 1) { String(cString: $0) }
            }
            if имя == "." || имя == ".." { continue }
            guard имена.count < 65_536 else { throw ОшибкаМашины("В каталоге слишком много артефактов.") }
            имена.append(имя)
        }
        return имена.sorted()
    }
    public func есть(_ имя: String) throws -> Bool {
        try проверитьИмя(имя)
        var сведения = stat()
        if fstatat(дескриптор, имя, &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
            let файл = try открытьФайл(имя)
            close(файл)
            return true
        }
        guard errno == ENOENT else { throw ОшибкаМашины("Ошибка чтения состояния артефакта.") }
        return false
    }
    public func открытьФайл(_ имя: String, запись: Bool = false) throws -> Int32 {
        try проверитьИмя(имя)
        let файл = openat(дескриптор, имя, (запись ? O_RDWR : O_RDONLY) | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаМашины("Отсутствует или небезопасен артефакт: \(имя).") }
        do { try проверитьОбычный(файл); return файл } catch { close(файл); throw error }
    }
    public func записать(_ имя: String, байты: Data) throws {
        guard имя != "замок", имя != "паспорт.json" else {
            throw ОшибкаМашины("Паспорт и постоянный замок нельзя заменять.")
        }
        if try есть(имя) { /* Есть только безопасный обычный файл; замена атомарна. */ }
        try Self.записатьВ(дескриптор, имя: имя, байты: байты)
    }
    private static func записатьВ(_ каталог: Int32, имя: String, байты: Data) throws {
        try проверитьИмя(имя)
        let временное = ".запись-" + UUID().uuidString.lowercased()
        let файл = openat(каталог, временное, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard файл >= 0 else { throw ОшибкаМашины("Не удалось создать артефакт.") }
        defer { close(файл) }
        try байты.withUnsafeBytes { буфер in
            var записано = 0
            while записано < буфер.count {
                let число = Darwin.write(файл, буфер.baseAddress!.advanced(by: записано), буфер.count - записано)
                if число < 0, errno == EINTR { continue }
                guard число > 0 else { throw ОшибкаМашины("Запись артефакта прервана; повторите этап после проверки места.") }
                записано += число
            }
        }
        guard fsync(файл) == 0, renameat(каталог, временное, каталог, имя) == 0, fsync(каталог) == 0 else {
            throw ОшибкаМашины("Не удалось долговечно установить артефакт.")
        }
    }
    public func прочитать(_ имя: String) throws -> Data {
        let файл = try открытьФайл(имя)
        let поток = FileHandle(fileDescriptor: файл, closeOnDealloc: true)
        let предел = 4 * 1024 * 1024
        var сведения = stat()
        guard fstat(файл, &сведения) == 0, сведения.st_size <= предел else {
            throw ОшибкаМашины("Размер метаданных превышает 4 MiB.")
        }
        let байты = try поток.read(upToCount: предел + 1) ?? Data()
        guard байты.count <= предел else { throw ОшибкаМашины("Метаданные выросли за допустимую границу.") }
        return байты
    }
}
