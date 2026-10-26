import Foundation
import Darwin
import ОсноваЗапуска

enum ИнъекцияЗаписи: String, CaseIterable, Sendable {
    case нет, короткиеЗаписи, передСозданием, послеСоздания, послеЧасти,
         синхронизацияФайла, синхронизацияКаталога, публикация
}

struct РезультатЗаписи: Codable, Equatable, Sendable {
    enum Вид: String, Codable, Sendable { case установлена, наблюдена }
    var вид: Вид
    var путь: String
    var хэшСодержания: String
    enum CodingKeys: String, CodingKey {
        case вид = "вид"
        case путь = "путь"
        case хэшСодержания = "содержаниеSHA256"
    }
}

extension ГраницаЦели {
    static func наблюдать(корень: String, область: String) throws -> СнимокЦели {
        let (дескриптор, снимок) = try открыть(корень: корень, область: область)
        defer { _ = Darwin.close(дескриптор) }
        return снимок
    }

    static func ключ(_ имя: String) -> Data {
        Data(имя.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .precomposedStringWithCanonicalMapping.utf8)
    }

    static func проверитьИмя(_ имя: String, в дескриптор: Int32, обязательно: Bool) throws {
        let копия = dup(дескриптор)
        guard копия >= 0, let каталог = fdopendir(копия) else {
            if копия >= 0 { _ = Darwin.close(копия) }
            throw ОтказЖурнала.путь
        }
        defer { closedir(каталог) }
        rewinddir(каталог)
        var найдено = false
        errno = 0
        while let запись = readdir(каталог) {
            var знаки = запись.pointee.d_name
            let сосед = withUnsafePointer(to: &знаки) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(запись.pointee.d_namlen) + 1) { String(validatingCString: $0) }
            }
            guard let сосед else { throw ОтказЖурнала.путь }
            if ключ(сосед) == ключ(имя) {
                guard Data(сосед.utf8) == Data(имя.utf8), !найдено else { throw ОтказЖурнала.коллизия }
                найдено = true
            }
            errno = 0
        }
        guard errno == 0, !обязательно || найдено else { throw ОтказЖурнала.путь }
    }

    static func узел(_ дескриптор: Int32) throws -> String {
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFDIR else { throw ОтказЖурнала.путь }
        return "\(сведения.st_dev):\(сведения.st_ino):\(сведения.st_mode):\(сведения.st_uid)"
    }

    static func открыть(корень: String, область: String) throws -> (Int32, СнимокЦели) {
        try проверитьОбласть(область)
        let части = корень.split(separator: "/", omittingEmptySubsequences: false)
        guard корень.hasPrefix("/"), !корень.utf8.contains(0), части.count > 1,
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { throw ОтказЖурнала.путь }
        var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard дескриптор >= 0 else { throw ОтказЖурнала.путь }
        do {
            var узлы = [try узел(дескриптор)]
            for часть in части.dropFirst().map(String.init) + область.split(separator: "/").map(String.init) + ["zhurnal"] {
                try проверитьИмя(часть, в: дескриптор, обязательно: true)
                let следующий = openat(дескриптор, часть, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
                guard следующий >= 0 else { throw ОтказЖурнала.путь }
                _ = Darwin.close(дескриптор)
                дескриптор = следующий
                узлы.append(try узел(дескриптор))
            }
            return (дескриптор, СнимокЦели(хэшКорня: хэш(Data(корень.utf8)), область: область, узлы: узлы))
        } catch {
            _ = Darwin.close(дескриптор)
            throw error
        }
    }
}

enum ФайловыйАдаптер {
    static func применить(_ план: ПланЗаписи, вход: Data, оператор: Data, корень: String,
                         инъекция: ИнъекцияЗаписи = .нет,
                         профиль: ((ЗамерЗаписи) -> Void)? = nil) throws -> РезультатЗаписи {
        guard план.схема == "fum.план-локальной-записи.1",
              план.хэшВхода == хэш(вход), план.хэшОператора == хэш(оператор),
              план.цель.хэшКорня == хэш(Data(корень.utf8)) else { throw ОтказЖурнала.дрейф }
        let пересчитанный = try ПланировщикЗаписи.построить(вход, оператор: оператор, цель: план.цель)
        guard try ПредставлениеЗапуска.байты(пересчитанный) == ПредставлениеЗапуска.байты(план)
        else { throw ОтказЖурнала.дрейф }
        let началоУстановки = ContinuousClock.now
        let (каталог, снимок) = try ГраницаЦели.открыть(корень: корень, область: план.цель.область)
        defer { _ = Darwin.close(каталог) }
        guard снимок == план.цель else { throw ОтказЖурнала.дрейф }
        guard flock(каталог, LOCK_EX | LOCK_NB) == 0 else { throw ОтказЖурнала.занято }
        defer { _ = flock(каталог, LOCK_UN) }
        guard try ГраницаЦели.наблюдать(корень: корень, область: план.цель.область) == план.цель
        else { throw ОтказЖурнала.дрейф }
        let имя = план.идентификатор + ".json"
        try ГраницаЦели.проверитьИмя(имя, в: каталог, обязательно: false)
        var сведения = stat()
        if fstatat(каталог, имя, &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
            guard сведения.st_mode & S_IFMT == S_IFREG else { throw ОтказЖурнала.путь }
            try проверитьСуществующий(имя, в: каталог, байты: план.байты)
            return РезультатЗаписи(вид: .наблюдена, путь: план.путь, хэшСодержания: план.хэшСодержания)
        }
        guard errno == ENOENT else { throw ОтказЖурнала.путь }
        if инъекция == .передСозданием { throw ОтказЖурнала.файловыйЭффект }
        let файл = openat(каталог, имя, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o644)
        guard файл >= 0 else { throw ОтказЖурнала.файловыйЭффект }
        defer { _ = Darwin.close(файл) }
        if инъекция == .послеСоздания { throw ОтказЖурнала.файловыйЭффект }
        try план.байты.withUnsafeBytes { указатель in
            guard let адрес = указатель.baseAddress else { throw ОтказЖурнала.вход }
            var позиция = 0
            let граница = инъекция == .послеЧасти ? max(1, указатель.count / 2) : указатель.count
            while позиция < граница {
                let запрошено = граница - позиция
                let фактическийПредел = инъекция == .короткиеЗаписи ? min(7, запрошено) : запрошено
                let записано = Darwin.write(файл, адрес.advanced(by: позиция), фактическийПредел)
                if записано < 0 && errno == EINTR { continue }
                guard записано > 0 else { throw ОтказЖурнала.файловыйЭффект }
                позиция += записано
            }
        }
        if [.послеЧасти, .синхронизацияФайла].contains(инъекция) { throw ОтказЖурнала.файловыйЭффект }
        guard fsync(файл) == 0 else { throw ОтказЖурнала.файловыйЭффект }
        if инъекция == .синхронизацияКаталога { throw ОтказЖурнала.файловыйЭффект }
        guard fsync(каталог) == 0 else { throw ОтказЖурнала.файловыйЭффект }
        if инъекция == .публикация { throw ОтказЖурнала.файловыйЭффект }
        try проверитьСуществующий(имя, в: каталог, байты: план.байты)
        профиль?(ЗамерЗаписи(стадия: "проверка-цели-установка-fsync-и-readback", наносекунды: наносекунды(началоУстановки)))
        return РезультатЗаписи(вид: .установлена, путь: план.путь, хэшСодержания: план.хэшСодержания)
    }

    private static func проверитьСуществующий(_ имя: String, в каталог: Int32, байты: Data) throws {
        let файл = openat(каталог, имя, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОтказЖурнала.путь }
        defer { _ = Darwin.close(файл) }
        var до = stat()
        guard fstat(файл, &до) == 0, до.st_mode & S_IFMT == S_IFREG, до.st_nlink == 1,
              до.st_uid == geteuid() else { throw ОтказЖурнала.путь }
        guard до.st_size == байты.count else { throw ОтказЖурнала.конфликт }
        var данные = Data()
        var буфер = [UInt8](repeating: 0, count: 8192)
        while true {
            let прочитано = Darwin.read(файл, &буфер, буфер.count)
            if прочитано < 0 && errno == EINTR { continue }
            guard прочитано >= 0 else { throw ОтказЖурнала.файловыйЭффект }
            if прочитано == 0 { break }
            данные.append(contentsOf: буфер.prefix(прочитано))
            guard данные.count <= байты.count else { throw ОтказЖурнала.конфликт }
        }
        var после = stat()
        var адрес = stat()
        guard fstat(файл, &после) == 0, fstatat(каталог, имя, &адрес, AT_SYMLINK_NOFOLLOW) == 0,
              до.st_dev == после.st_dev, до.st_ino == после.st_ino, до.st_size == после.st_size,
              до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec, до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec, до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec,
              адрес.st_ino == до.st_ino, адрес.st_dev == до.st_dev,
              адрес.st_mode & S_IFMT == S_IFREG, адрес.st_nlink == 1 else { throw ОтказЖурнала.дрейф }
        guard данные == байты else { throw ОтказЖурнала.конфликт }
    }
}
