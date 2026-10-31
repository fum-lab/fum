import Foundation
import CryptoKit
import Darwin

struct ЗапросЗахвата: Codable {
    let попытка: String
    var бюджетХранилища: БюджетХранилища? = nil
    let исполняемый: String
    let хэшИсполняемого: String
    let аргументы: [String]
    let вывод: String
    let ошибки: String
    let намерение: String
    let процесс: String
    let исход: String
    let наблюдениеОчистки: String
    let секунд: Double
    let пределВывода: Int
    let пределОшибок: Int
}


enum МетрикаРасхода: String, Codable {
    case логическиеБайты = "logicalBytes"
    case выделенныеФайловойСистемойБайты = "filesystemReportedAllocatedBytes"
}

struct БюджетХранилища: Codable {
    let корень: String
    let метрика: МетрикаРасхода
    let пределБайт: UInt64
    let пределОбъектов: Int
    let пределГлубины: Int
    let секунд: Double
}

enum ОшибкаРасхода: Error {
    case запрещено(String)
    case неизвестно(String)
}

struct ЗаписьРасхода: Equatable {
    let ключ: String
    let режим: mode_t
    let размер: UInt64
    let выделено: UInt64
    let ссылки: UInt64
    let изменение: String
    let статус: String
    let поколение: UInt32
}

func сложитьРасход(_ первый: UInt64, _ второй: UInt64) throws -> UInt64 {
    let (значение, переполнение) = первый.addingReportingOverflow(второй)
    guard !переполнение else { throw ОшибкаРасхода.неизвестно("Переполнение суммы") }
    return значение
}

func записьРасхода(_ сведения: stat) throws -> ЗаписьРасхода {
    guard сведения.st_size >= 0, сведения.st_blocks >= 0 else { throw ОшибкаРасхода.неизвестно("Отрицательная metadata") }
    let (выделено, переполнение) = UInt64(сведения.st_blocks).multipliedReportingOverflow(by: 512)
    guard !переполнение else { throw ОшибкаРасхода.неизвестно("Переполнение st_blocks") }
    return ЗаписьРасхода(ключ: "\(сведения.st_dev):\(сведения.st_ino)", режим: сведения.st_mode,
        размер: UInt64(сведения.st_size), выделено: выделено, ссылки: UInt64(сведения.st_nlink),
        изменение: "\(сведения.st_mtimespec.tv_sec):\(сведения.st_mtimespec.tv_nsec)",
        статус: "\(сведения.st_ctimespec.tv_sec):\(сведения.st_ctimespec.tv_nsec)", поколение: сведения.st_gen)
}

func открытьКореньРасхода(_ корень: String) throws -> Int32 {
    guard корень.hasPrefix("/"), корень != "/", URL(fileURLWithPath: корень).standardizedFileURL.path == корень else {
        throw ОшибкаРасхода.запрещено("Нужен ограниченный абсолютный root")
    }
    var дескриптор = open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаРасхода.неизвестно("Нет root FD") }
    do {
        for часть in корень.split(separator: "/") {
            let следующий = openat(дескриптор, String(часть), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОшибкаРасхода.запрещено("Компонент root недоступен или символический") }
            close(дескриптор); дескриптор = следующий
        }
        return дескриптор
    } catch { close(дескриптор); throw error }
}

func снятьРасход(_ бюджет: БюджетХранилища, срок: UInt64) throws -> [String: ЗаписьРасхода] {
    let корень = try открытьКореньРасхода(бюджет.корень)
    defer { close(корень) }
    var исходный = stat()
    guard fstat(корень, &исходный) == 0, исходный.st_uid == geteuid() else { throw ОшибкаРасхода.неизвестно("Нет root stat") }
    var записи: [String: ЗаписьРасхода] = [:]
    var каталоги = Set<String>()
    func обойти(_ дескриптор: Int32, _ имя: String, _ глубина: Int) throws {
        guard DispatchTime.now().uptimeNanoseconds < срок, глубина <= бюджет.пределГлубины,
              записи.count < бюджет.пределОбъектов else { throw ОшибкаРасхода.неизвестно("Предел обхода") }
        var до = stat()
        guard fstat(дескриптор, &до) == 0, до.st_dev == исходный.st_dev else { throw ОшибкаРасхода.неизвестно("Дрейф или иная FS") }
        let запись = try записьРасхода(до)
        guard до.st_mode & S_IFMT == S_IFDIR || до.st_mode & S_IFMT == S_IFREG else {
            throw ОшибкаРасхода.неизвестно("Неизвестный тип объекта")
        }
        записи[имя] = запись
        if до.st_mode & S_IFMT == S_IFDIR {
            guard каталоги.insert(запись.ключ).inserted else { throw ОшибкаРасхода.неизвестно("Повтор каталога") }
            let копия = dup(дескриптор)
            guard копия >= 0 else { throw ОшибкаРасхода.неизвестно("Нет duplicate FD") }
            guard let каталог = fdopendir(копия) else { close(копия); throw ОшибкаРасхода.неизвестно("Нет DIR") }
            defer { closedir(каталог) }
            rewinddir(каталог)
            while true {
                errno = 0
                guard let записьИмени = readdir(каталог) else {
                    guard errno == 0 else { throw ОшибкаРасхода.неизвестно("Ошибка readdir") }
                    break
                }
                let длина = Int(записьИмени.pointee.d_namlen)
                guard длина > 0 && длина <= 255 else { throw ОшибкаРасхода.неизвестно("Неизвестное имя") }
                let байты = withUnsafeBytes(of: записьИмени.pointee.d_name) { Data($0.prefix(длина)) }
                guard let часть = String(data: байты, encoding: .utf8), !часть.contains("/") else {
                    throw ОшибкаРасхода.неизвестно("Имя не UTF-8")
                }
                if часть == "." || часть == ".." { continue }
                var поИмени = stat()
                guard fstatat(дескриптор, часть, &поИмени, AT_SYMLINK_NOFOLLOW) == 0 else { throw ОшибкаРасхода.неизвестно("Нет named stat") }
                if поИмени.st_mode & S_IFMT == S_IFLNK { throw ОшибкаРасхода.запрещено("Symlink/outside не обходится") }
                guard поИмени.st_mode & S_IFMT == S_IFDIR || поИмени.st_mode & S_IFMT == S_IFREG else {
                    throw ОшибкаРасхода.неизвестно("Неизвестный тип")
                }
                let потомок = openat(дескриптор, часть, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
                guard потомок >= 0 else { throw ОшибкаРасхода.неизвестно("Нет child FD") }
                do {
                    var открытый = stat()
                    guard fstat(потомок, &открытый) == 0,
                          try записьРасхода(открытый) == записьРасхода(поИмени) else { throw ОшибкаРасхода.неизвестно("Дрейф openat") }
                    try обойти(потомок, имя + "/" + часть, глубина + 1)
                    var послеИмени = stat()
                    guard fstatat(дескриптор, часть, &послеИмени, AT_SYMLINK_NOFOLLOW) == 0,
                          try записьРасхода(послеИмени) == записьРасхода(поИмени) else { throw ОшибкаРасхода.неизвестно("Дрейф named entry") }
                    close(потомок)
                } catch { close(потомок); throw error }
            }
        }
        var после = stat()
        guard fstat(дескриптор, &после) == 0, try записьРасхода(после) == запись else { throw ОшибкаРасхода.неизвестно("Дрейф FD") }
    }
    try обойти(корень, ".", 0)
    return записи
}

func измеритьБюджетХранилища(_ бюджет: БюджетХранилища, междуНаблюдениями: (() throws -> Void)? = nil) -> [String: Any] {
    do {
        guard бюджет.пределОбъектов > 0, бюджет.пределОбъектов <= 10000,
              бюджет.пределГлубины >= 0, бюджет.пределГлубины <= 32,
              бюджет.секунд > 0, бюджет.секунд <= 5 else { throw ОшибкаРасхода.неизвестно("Неприменимый предел") }
        let срок = DispatchTime.now().uptimeNanoseconds + UInt64(бюджет.секунд * 1_000_000_000)
        let первый = try снятьРасход(бюджет, срок: срок)
        try междуНаблюдениями?()
        let второй = try снятьРасход(бюджет, срок: срок)
        guard первый == второй else { throw ОшибкаРасхода.неизвестно("Нестабильный snapshot") }
        var уникальные: [String: ЗаписьРасхода] = [:]
        for запись in второй.values {
            if let прежняя = уникальные[запись.ключ], прежняя != запись { throw ОшибкаРасхода.неизвестно("Неустойчивый hardlink") }
            уникальные[запись.ключ] = запись
        }
        var логические: UInt64 = 0, выделенные: UInt64 = 0, логическиеФайлы: UInt64 = 0, выделенныеФайлы: UInt64 = 0
        for запись in уникальные.values {
            логические = try сложитьРасход(логические, запись.размер)
            выделенные = try сложитьРасход(выделенные, запись.выделено)
            if запись.режим & S_IFMT == S_IFREG {
                логическиеФайлы = try сложитьРасход(логическиеФайлы, запись.размер)
                выделенныеФайлы = try сложитьРасход(выделенныеФайлы, запись.выделено)
            }
        }
        guard DispatchTime.now().uptimeNanoseconds < срок else { throw ОшибкаРасхода.неизвестно("Истёк срок наблюдения") }
        let выбранные = бюджет.метрика == .логическиеБайты ? логические : выделенные
        return ["состояние": выбранные <= бюджет.пределБайт ? "разрешён" : "превышен",
            "наблюдение": "подтверждено-в-ограниченной-выборке", "метрика": бюджет.метрика.rawValue,
            "пределБайт": бюджет.пределБайт, "логическиеБайты": логические,
            "выделенныеФайловойСистемойБайты": выделенные, "логическиеБайтыФайлов": логическиеФайлы,
            "выделенныеФайловойСистемойБайтыФайлов": выделенныеФайлы,
            "уникальныхОбъектов": уникальные.count, "записейПутей": второй.count,
            "эксклюзивныеФизическиеБайты": "неизвестно", "КлоныИСжатие": "не определялись",
            "граница": "Сумма st_size либо st_blocks*512 уникальных(dev,ino) файлов и каталогов; две совпавшие выборки, не атомарный снимок. APFS/COW/clones/compression могут разделять блоки; exclusive occupied не выводится."]
    } catch {
        let состояние: String
        if let ошибка = error as? ОшибкаРасхода, case .запрещено = ошибка { состояние = "отказ" } else { состояние = "неизвестно" }
        return ["состояние": состояние, "наблюдение": "неизвестно", "метрика": бюджет.метрика.rawValue,
                "причина": String(describing: error), "эксклюзивныеФизическиеБайты": "неизвестно"]
    }
}

enum ОшибкаЗахвата: Error { case отказ(String) }

struct СнимокФайла: Equatable {
    let устройство: dev_t, узел: ino_t, режим: mode_t, ссылки: nlink_t, размер: off_t
    let изменениеСекунд: Int, изменениеНаносекунд: Int, статусСекунд: Int, статусНаносекунд: Int
    init(_ сведения: stat) {
        устройство = сведения.st_dev; узел = сведения.st_ino; режим = сведения.st_mode
        ссылки = сведения.st_nlink; размер = сведения.st_size
        изменениеСекунд = сведения.st_mtimespec.tv_sec; изменениеНаносекунд = сведения.st_mtimespec.tv_nsec
        статусСекунд = сведения.st_ctimespec.tv_sec; статусНаносекунд = сведения.st_ctimespec.tv_nsec
    }
    func тотЖеОбъект(_ другой: СнимокФайла) -> Bool {
        устройство == другой.устройство && узел == другой.узел && режим == другой.режим && ссылки == другой.ссылки
    }
}

func снимок(_ дескриптор: Int32) throws -> СнимокФайла {
    var сведения = stat()
    guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
          сведения.st_nlink == 1 else { throw ОшибкаЗахвата.отказ("Необычный файл") }
    return СнимокФайла(сведения)
}

func прочитатьДескриптор(_ дескриптор: Int32, путь: String, предел: Int) throws -> Data {
    let до = try снимок(дескриптор)
    guard до.размер >= 0, до.размер <= предел else { throw ОшибкаЗахвата.отказ("Предел файла") }
    func проверитьИмя() throws {
        var сведения = stat()
        guard lstat(путь, &сведения) == 0, СнимокФайла(сведения) == до else {
            throw ОшибкаЗахвата.отказ("Изменена запись имени")
        }
    }
    try проверитьИмя()
    var данные = Data(), буфер = [UInt8](repeating: 0, count: 16384)
    while данные.count < до.размер {
        let число = pread(дескриптор, &буфер, min(буфер.count, Int(до.размер) - данные.count), off_t(данные.count))
        if число < 0 && errno == EINTR { continue }
        guard число > 0 else { throw ОшибкаЗахвата.отказ("Потеря pread") }
        данные.append(contentsOf: буфер.prefix(число))
    }
    guard try снимок(дескриптор) == до else { throw ОшибкаЗахвата.отказ("Файл изменился при чтении") }
    try проверитьИмя()
    return данные
}

func прочитатьФайл(_ путь: String, предел: Int) throws -> Data {
    try безопасныйПуть(путь)
    let дескриптор = open(путь, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаЗахвата.отказ("Нет входного файла") }
    defer { close(дескриптор) }
    return try прочитатьДескриптор(дескриптор, путь: путь, предел: предел)
}

func закреплённыйЗапрос(_ путь: String, ожидаемыйХэш: String) throws -> (ЗапросЗахвата, String) {
    let данные = try прочитатьФайл(путь, предел: 1048576)
    guard ожидаемыйХэш.count == 64, хэш(данные) == ожидаемыйХэш else { throw ОшибкаЗахвата.отказ("SHA запроса не совпал") }
    return (try JSONDecoder().decode(ЗапросЗахвата.self, from: данные), ожидаемыйХэш)
}

func сверитьПоток(_ дескриптор: Int32, путь: String, тождество: СнимокФайла, объём: Int, ожидаемыйХэш: String, предел: Int) -> Bool {
    do {
        guard тождество.тотЖеОбъект(try снимок(дескриптор)) else { return false }
        let данные = try прочитатьДескриптор(дескриптор, путь: путь, предел: предел)
        return данные.count == объём && хэш(данные) == ожидаемыйХэш
    } catch { return false }
}

func хэш(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

func безопасныйПуть(_ путь: String) throws {
    guard путь.hasPrefix("/"), URL(fileURLWithPath: путь).standardizedFileURL.path == путь else {
        throw ОшибкаЗахвата.отказ("Нужен точный абсолютный путь")
    }
    var текущий = ""
    for часть in путь.split(separator: "/") {
        текущий += "/" + String(часть)
        var сведения = stat()
        if lstat(текущий, &сведения) == 0 {
            if сведения.st_mode & S_IFMT == S_IFLNK { throw ОшибкаЗахвата.отказ("Символическая ссылка") }
        } else if errno != ENOENT { throw ОшибкаЗахвата.отказ("Неизвестный компонент пути") }
    }
}

func записатьВсё(_ дескриптор: Int32, _ данные: Data) throws {
    try данные.withUnsafeBytes { буфер in
        var смещение = 0
        while смещение < буфер.count {
            let число = Darwin.write(дескриптор, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
            if число < 0 && errno == EINTR { continue }
            guard число > 0 else { throw ОшибкаЗахвата.отказ("Потеря записи") }
            смещение += число
        }
    }
    guard fsync(дескриптор) == 0 else { throw ОшибкаЗахвата.отказ("Нет fsync") }
}

func синхронизироватьКаталог(_ путь: String) throws {
    let дескриптор = open(URL(fileURLWithPath: путь).deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY)
    guard дескриптор >= 0 else { throw ОшибкаЗахвата.отказ("Нет каталога") }
    defer { close(дескриптор) }
    guard fsync(дескриптор) == 0 else { throw ОшибкаЗахвата.отказ("Нет fsync каталога") }
}

func новыйФайл(_ путь: String) throws -> Int32 {
    try безопасныйПуть(путь)
    let дескриптор = open(путь, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard дескриптор >= 0 else { throw ОшибкаЗахвата.отказ("Цель существует или недоступна: \(путь)") }
    try синхронизироватьКаталог(путь)
    return дескриптор
}

func сохранить(_ путь: String, _ объект: [String: Any]) throws {
    let данные = try JSONSerialization.data(withJSONObject: объект, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) + Data([10])
    let дескриптор = try новыйФайл(путь)
    defer { close(дескриптор) }
    try записатьВсё(дескриптор, данные)
    try синхронизироватьКаталог(путь)
}

func захватить(_ запрос: ЗапросЗахвата, хэшЗапроса: String) throws -> [String: Any] {
    guard запрос.секунд > 0, запрос.секунд <= 120, запрос.пределВывода > 0,
          запрос.пределВывода <= 67108864, запрос.пределОшибок > 0,
          запрос.пределОшибок <= 1048576 else { throw ОшибкаЗахвата.отказ("Некорректный бюджет") }
    let пути = [запрос.вывод, запрос.ошибки, запрос.намерение, запрос.процесс, запрос.исход, запрос.наблюдениеОчистки]
    guard Set(пути).count == пути.count else { throw ОшибкаЗахвата.отказ("Совпавшие цели") }
    for путь in пути {
        try безопасныйПуть(путь)
        var сведения = stat()
        guard lstat(путь, &сведения) != 0 && errno == ENOENT else { throw ОшибкаЗахвата.отказ("Существующая цель") }
    }
    try безопасныйПуть(запрос.исполняемый)
    guard хэш(try прочитатьФайл(запрос.исполняемый, предел: 268435456)) == запрос.хэшИсполняемого else {
        throw ОшибкаЗахвата.отказ("Изменён исполняемый файл")
    }
    let начало = Date().timeIntervalSince1970
    let предел = DispatchTime.now().uptimeNanoseconds + UInt64(запрос.секунд * 1_000_000_000)
    try сохранить(запрос.намерение, ["схема": "fum.намерение-захвата.1", "попытка": запрос.попытка,
        "супервизорPID": getpid(), "супервизорPGID": getpgrp(), "хэшЗапроса": хэшЗапроса,
        "исполняемый": запрос.исполняемый, "хэшИсполняемого": запрос.хэшИсполняемого,
        "аргументы": запрос.аргументы, "начало": начало, "вывод": запрос.вывод, "ошибки": запрос.ошибки,
        "секунд": запрос.секунд, "пределВывода": запрос.пределВывода, "пределОшибок": запрос.пределОшибок,
        "метрикаХранилища": запрос.бюджетХранилища?.метрика.rawValue ?? "отключено-не-проверено"])
    if let бюджет = запрос.бюджетХранилища {
        let наблюдение = измеритьБюджетХранилища(бюджет)
        if наблюдение["состояние"] as? String != "разрешён" {
            let состояние = наблюдение["состояние"] as? String == "превышен" ? "бюджет-превышен" : "неизвестно"
            let исход: [String: Any] = ["схема": "fum.исход-захвата.1", "состояние": состояние,
                "ребёнокЗапущен": false, "наблюдениеХранилища": наблюдение, "попытка": запрос.попытка]
            try сохранить(запрос.исход, исход)
            return исход
        }
    }
    let выход = try новыйФайл(запрос.вывод)
    defer { close(выход) }
    let ошибки = try новыйФайл(запрос.ошибки)
    defer { close(ошибки) }
    let тождества = try [снимок(выход), снимок(ошибки)]
    var трубаВывода: [Int32] = [0, 0], трубаОшибок: [Int32] = [0, 0]
    guard pipe(&трубаВывода) == 0, pipe(&трубаОшибок) == 0 else { throw ОшибкаЗахвата.отказ("Нет pipe") }
    defer { close(трубаВывода[0]); close(трубаОшибок[0]) }
    var действия: posix_spawn_file_actions_t? = nil
    var атрибуты: posix_spawnattr_t? = nil
    guard posix_spawn_file_actions_init(&действия) == 0, posix_spawnattr_init(&атрибуты) == 0 else {
        throw ОшибкаЗахвата.отказ("Нет spawn attributes")
    }
    defer { posix_spawn_file_actions_destroy(&действия); posix_spawnattr_destroy(&атрибуты) }
    guard posix_spawn_file_actions_addopen(&действия, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_adddup2(&действия, трубаВывода[1], STDOUT_FILENO) == 0,
          posix_spawn_file_actions_adddup2(&действия, трубаОшибок[1], STDERR_FILENO) == 0,
          posix_spawnattr_setpgroup(&атрибуты, 0) == 0 else { throw ОшибкаЗахвата.отказ("Нет spawn actions") }
    var пустая = sigset_t(), блокировка = sigset_t(), прежняя = sigset_t()
    sigemptyset(&пустая); sigemptyset(&блокировка)
    sigaddset(&блокировка, SIGTERM); sigaddset(&блокировка, SIGINT)
    guard pthread_sigmask(SIG_BLOCK, &блокировка, &прежняя) == 0 else { throw ОшибкаЗахвата.отказ("Нет signal mask") }
    defer { pthread_sigmask(SIG_SETMASK, &прежняя, nil) }
    guard posix_spawnattr_setsigmask(&атрибуты, &пустая) == 0,
          posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { throw ОшибкаЗахвата.отказ("Нет spawn flags") }
    let строки = ([запрос.исполняемый] + запрос.аргументы).map { strdup($0) }
    let именаСреды = ["HOME", "PATH", "TMPDIR", "LANG", "LC_ALL", "GH_TOKEN", "GITHUB_TOKEN", "GH_CONFIG_DIR"]
    let окружение = ProcessInfo.processInfo.environment
    let среда = именаСреды.compactMap { имя in окружение[имя].map { strdup(имя + "=" + $0) } }
    defer { for строка in строки { free(строка) }; for строка in среда { free(строка) } }
    var аргументы = строки + [nil], переменные = среда + [nil]
    var ребёнок: pid_t = 0
    let кодЗапуска = posix_spawn(&ребёнок, запрос.исполняемый, &действия, &атрибуты, &аргументы, &переменные)
    close(трубаВывода[1]); close(трубаОшибок[1])
    guard кодЗапуска == 0 else {
        let исход: [String: Any] = ["состояние": "не-запущен", "кодЗапуска": кодЗапуска, "попытка": запрос.попытка]
        try сохранить(запрос.исход, исход); return исход
    }
    // Пока ребёнок не reap, его PID не может быть переиспользован.
    var собран = false
    defer {
        if !собран {
            if getpgid(ребёнок) == ребёнок { kill(-ребёнок, SIGKILL) }
            kill(ребёнок, SIGKILL)
            var сведения = siginfo_t(), статус: Int32 = 0
            if waitid(P_PID, id_t(ребёнок), &сведения, WEXITED | WNOHANG | WNOWAIT) == 0 && сведения.si_pid == ребёнок {
                _ = waitpid(ребёнок, &статус, WNOHANG)
            }
        }
    }
    do {
    errno = 0
    let начальнаяГруппа = getpgid(ребёнок)
    let ошибкаНачальнойГруппы = начальнаяГруппа == -1 ? errno : 0
    try сохранить(запрос.процесс, ["схема": "fum.процесс-захвата.1", "попытка": запрос.попытка,
        "PID": ребёнок, "PGID": ребёнок, "наблюдённыйPGID": начальнаяГруппа, "ошибкаPGID": ошибкаНачальнойГруппы, "супервизорPID": getpid(), "время": Date().timeIntervalSince1970])
    for труба in [трубаВывода[0], трубаОшибок[0]] {
        guard fcntl(труба, F_SETFL, O_NONBLOCK) == 0 else { throw ОшибкаЗахвата.отказ("Нет nonblocking pipe") }
    }
    var открыты = [true, true], объёмы = [0, 0], статус: Int32 = 0
    var хэши = [SHA256(), SHA256()]
    var завершениеНаблюдалось = false
    var причина = "завершён", потеря = false, остановлен = false
    var границаДренирования: UInt64 = .max
    var буфер = [UInt8](repeating: 0, count: 16384)
    while !собран {
        var сведения = siginfo_t()
        let наблюдение = waitid(P_PID, id_t(ребёнок), &сведения, WEXITED | WNOHANG | WNOWAIT)
        let ошибкаWaitid = наблюдение == 0 ? 0 : errno
        guard наблюдение == 0 || ошибкаWaitid == EINTR else { throw ОшибкаЗахвата.отказ("Потерян waitid anchor") }
        if наблюдение == 0 && сведения.si_pid == ребёнок { завершениеНаблюдалось = true }
        var ожидающие = sigset_t(); sigpending(&ожидающие)
        if sigismember(&ожидающие, SIGTERM) == 1 || sigismember(&ожидающие, SIGINT) == 1 { причина = "прерван" }
        if DispatchTime.now().uptimeNanoseconds >= предел && причина == "завершён" { причина = "таймаут" }
        if (причина != "завершён" || завершениеНаблюдалось) && !остановлен {
            errno = 0
            let группаПередCleanup = getpgid(ребёнок)
            let ошибкаГруппы = группаПередCleanup == -1 ? errno : 0
            try сохранить(запрос.наблюдениеОчистки, [
                "схема": "fum.наблюдение-cleanup.1", "PID": ребёнок,
                "начальнаяГруппа": начальнаяГруппа, "ошибкаНачальнойГруппы": ошибкаНачальнойГруппы,
                "возвратОжидания": наблюдение, "ошибкаОжидания": ошибкаWaitid, "идентификаторОжидания": сведения.si_pid,
                "причинаОжидания": сведения.si_code, "статусОжидания": сведения.si_status,
                "возвратГруппы": группаПередCleanup, "ошибкаГруппы": ошибкаГруппы,
                "якорьПодтверждён": завершениеНаблюдалось, "собран": собран,
                "фаза": "перед-очисткой-и-сбором", "причина": причина])
            guard группаПередCleanup == ребёнок else { throw ОшибкаЗахвата.отказ("Не подтверждена группа") }
            kill(-ребёнок, SIGKILL); остановлен = true
            границаДренирования = DispatchTime.now().uptimeNanoseconds + 2_000_000_000
        }
        var опрос = [pollfd(fd: открыты[0] ? трубаВывода[0] : -1, events: Int16(POLLIN), revents: 0),
                     pollfd(fd: открыты[1] ? трубаОшибок[0] : -1, events: Int16(POLLIN), revents: 0)]
        _ = poll(&опрос, 2, 20)
        for номер in 0..<2 where открыты[номер] {
            let прочитано = Darwin.read(номер == 0 ? трубаВывода[0] : трубаОшибок[0], &буфер, буфер.count)
            if прочитано == 0 { открыты[номер] = false }
            if прочитано < 0 && errno != EAGAIN && errno != EINTR { потеря = true; причина = "потеря-ввода-вывода"; открыты[номер] = false }
            if прочитано > 0 {
                let лимит = номер == 0 ? запрос.пределВывода : запрос.пределОшибок
                let сохранять = min(прочитано, max(0, лимит - объёмы[номер]))
                let часть = Data(буфер.prefix(сохранять))
                do { try записатьВсё(номер == 0 ? выход : ошибки, часть); хэши[номер].update(data: часть); объёмы[номер] += сохранять }
                catch { потеря = true; причина = "потеря-ввода-вывода" }
                if сохранять < прочитано { причина = номер == 0 ? "предел-вывода" : "предел-ошибок" }
            }
        }
        if остановлен && открыты.contains(true) && DispatchTime.now().uptimeNanoseconds >= границаДренирования {
            потеря = true; открыты = [false, false]
        }
        if остановлен && !завершениеНаблюдалось && DispatchTime.now().uptimeNanoseconds >= границаДренирования {
            потеря = true; break
        }
        if !открыты.contains(true) && завершениеНаблюдалось && остановлен {
            let результат = waitpid(ребёнок, &статус, WNOHANG)
            if результат == ребёнок { собран = true }
            else if результат < 0 { throw ОшибкаЗахвата.отказ("Потерян waitpid") }
        }
    }
    for путь in [запрос.вывод, запрос.ошибки] { try синхронизироватьКаталог(путь) }
    // После reap разрешено только наблюдение отсутствия, никаких сигналов группе.
    var группаОтсутствует = false
    let пределОтсутствия = DispatchTime.now().uptimeNanoseconds + 500_000_000
    while собран && DispatchTime.now().uptimeNanoseconds < пределОтсутствия {
        if kill(-ребёнок, 0) == -1 && errno == ESRCH { группаОтсутствует = true; break }
        usleep(10000)
    }
    if !группаОтсутствует { потеря = true }
    let ожидаемыеХэши = хэши.map { $0.finalize().map { String(format: "%02x", $0) }.joined() }
    var чтениеСовпало = true
    for номер in 0..<2 {
        if !сверитьПоток(номер == 0 ? выход : ошибки, путь: номер == 0 ? запрос.вывод : запрос.ошибки,
            тождество: тождества[номер], объём: объёмы[номер], ожидаемыйХэш: ожидаемыеХэши[номер],
            предел: номер == 0 ? запрос.пределВывода : запрос.пределОшибок) { чтениеСовпало = false }
    }
    if !чтениеСовпало { потеря = true }
    let сигнал = статус & 0x7f
    let итог: [String: Any] = ["схема": "fum.исход-захвата.1", "попытка": запрос.попытка,
        "состояние": потеря ? "неизвестно" : причина, "причина": причина, "начало": начало, "конец": Date().timeIntervalSince1970,
        "PID": ребёнок, "PGID": ребёнок, "собран": собран, "статусWaitpid": собран ? статус : -1,
        "код": собран && сигнал == 0 ? Int((статус >> 8) & 255) : -1, "сигнал": собран ? Int(сигнал) : -1,
        "байтВывода": объёмы[0], "хэшВывода": ожидаемыеХэши[0], "байтОшибок": объёмы[1],
        "хэшОшибок": ожидаемыеХэши[1], "хэшЗапроса": хэшЗапроса,
        "чтениеСовпало": чтениеСовпало, "группаОтсутствует": группаОтсутствует, "завершениеWNOWAIT": завершениеНаблюдалось]
    try сохранить(запрос.исход, итог)
    return итог
    } catch {
        // Существующий частичный/терминальный outcome никогда не заменяется.
        try? сохранить(запрос.исход, ["схема": "fum.исход-захвата.1",
            "состояние": "неизвестно", "попытка": запрос.попытка,
            "PID": ребёнок, "PGID": ребёнок, "исходПодтверждён": false,
            "причина": String(describing: error), "источник": "исключение-наблюдателя"])
        throw error
    }
}

#if !ПРОВЕРКИ
@main struct ВходЗахвата {
    static func main() {
        do {
            guard CommandLine.arguments.count == 3 else { throw ОшибкаЗахвата.отказ("Нужны JSON-запрос и ожидаемый SHA256") }
            let (запрос, закреплённыйХэш) = try закреплённыйЗапрос(CommandLine.arguments[1], ожидаемыйХэш: CommandLine.arguments[2])
            let итог = try захватить(запрос, хэшЗапроса: закреплённыйХэш)
            print(String(decoding: try JSONSerialization.data(withJSONObject: итог, options: [.sortedKeys]), as: UTF8.self))
            if итог["ребёнокЗапущен"] as? Bool == false { exit(2) }
        } catch { FileHandle.standardError.write(Data("Захват отказал: \(error)\n".utf8)); exit(2) }
    }
}
#endif
