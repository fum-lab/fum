import Foundation
import Darwin
import КонтейнерНаблюдений

// Один постоянный слот на физическое worktree. UUID запуска не выбирает новое место.
// Пара marker/segment различает новую операцию и потерю уже ожидаемого хранилища.
final class ЖурналПакета {
    let новый: Bool
    let хэшПлана: String
    private let сегмент: Сегмент
    private let пространство: String
    private let время: String
    private(set) var доступен = true

    private init(сегмент: Сегмент, новый: Bool, хэшПлана: String, пространство: String, время: String) {
        self.сегмент = сегмент; self.новый = новый; self.хэшПлана = хэшПлана
        self.пространство = пространство; self.время = время
    }

    deinit { сегмент.закрыть() }

    static func открыть(корень: URL, план: ПланПакета, байты: Data, основаДляПроверки: URL? = nil,
        создать: Bool, операции: ФайловыеОперации = .системные) throws -> ЖурналПакета? {
        guard байты.count <= 67_108_864 else { throw ОтказПакета.условие("предел-долговечного-плана") }
        guard try байтыПлана(план) == байты,
              план.пространство.utf8.count == 64,
              план.пространство.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              try ПакетПутей.пространство(корень) == план.пространство else {
            throw ОтказПакета.условие("не-подтверждён-приватный-namespace")
        }
        let основа: URL
        if let проверочная = основаДляПроверки { основа = проверочная }
        else {
            guard let поддержка = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw ОтказПакета.условие("нет-устойчивого-хранилища")
            }
            основа = try ЧитательПакета.физический(поддержка).appendingPathComponent("FUM/aktualizaciya-putej")
        }
        try проверитьПриватность(основа)
        let хэш = хэшПутей(байты)
        let каталог = основа.appendingPathComponent(план.пространство)
        let маркер = основа.appendingPathComponent(план.пространство + ".json")
        let естьКаталог = FileManager.default.fileExists(atPath: каталог.path)
        let естьМаркер = FileManager.default.fileExists(atPath: маркер.path)
        if !естьКаталог && !естьМаркер && !создать { return nil }
        struct Маркер: Codable {
            var схема = "fum.постоянный-слот-пакета-девяти-путей.1"
            var пространство: String
            var план_sha256: String
        }
        let данныеМаркера = try байтыПлана(Маркер(пространство: план.пространство, план_sha256: хэш))
        let новый = !естьКаталог && !естьМаркер
        if новый {
            try создатьПриватныйКаталог(основа)
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            try синхронизироватьКаталог(основа)
        } else {
            guard естьКаталог && естьМаркер else { throw ОтказПакета.условие("хранилище-ожидалось-но-потеряно") }
            let сохранённый = try прочитатьПриватныйФайл(маркер)
            guard сохранённый == данныеМаркера else { throw ОтказПакета.условие("слот-занят-другим-планом") }
            guard FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path) else {
                throw ОтказПакета.условие("хранилище-ожидалось-но-потеряно")
            }
        }
        try проверитьКаталог(каталог)
        let сегмент = try Сегмент(кореньДанных: каталог, запись: true, создать: новый, операции: операции)
        do {
            guard !сегмент.естьХвост else { throw ОтказПакета.условие("неполный-хвост-журнала") }
            if новый { try записатьПриватныйФайл(данныеМаркера, маркер) }
            else {
                guard try прочитатьПриватныйФайл(маркер) == данныеМаркера else {
                    throw ОтказПакета.условие("маркер-изменился-до-владения")
                }
            }
            let журнал = ЖурналПакета(сегмент: сегмент, новый: новый, хэшПлана: хэш,
                пространство: план.пространство, время: план.поручение.время_свежести)
            if новый { try журнал.записать("план", байты) }
            else {
                guard try журнал.прочитать("план") == байты else { throw ОтказПакета.условие("потерян-долговечный-план") }
                // Читаемый commit мог остаться после failed fsync прежнего instance.
                // Duplicate append контейнера повторно синхронизирует весь segment и каталог.
                try журнал.записать("план", байты)
            }
            return журнал
        } catch { сегмент.закрыть(); throw error }
    }

    private func проверитьДоступ() throws {
        guard доступен else { throw ОтказПакета.условие("журнал-недоступен-после-отказа") }
    }

    func есть(_ идентификатор: String) throws -> Bool {
        try проверитьДоступ()
        return сегмент.записи.contains { Data($0.описание.идентификатор.utf8) == Data(идентификатор.utf8) }
    }

    func прочитать(_ идентификатор: String) throws -> Data? {
        guard try есть(идентификатор) else { return nil }
        return try сегмент.извлечь(идентификатор)
    }

    func записать(_ идентификатор: String, _ данные: Data) throws {
        try проверитьДоступ()
        do {
            _ = try сегмент.добавить(ОписаниеНаблюдения(идентификатор: идентификатор,
                тип: "fum.пакет-девяти-путей.1", источник: пространство, время: время,
                спецификация: Data(хэшПлана.utf8)), данные: данные)
        } catch { доступен = false; throw error }
    }

    func квитанция() throws -> КвитанцияПакета? {
        guard let данные = try прочитать("итог") else { return nil }
        let квитанция = try JSONDecoder().decode(КвитанцияПакета.self, from: данные)
        let префикс = try подтверждённыйПрефикс
        let исходы = ["завершено", "откат-проверен", "частичный", "неизвестно"].map { Data($0.utf8) }
        guard try байтыПлана(квитанция) == данные, квитанция.план_sha256 == хэшПлана,
              Data(квитанция.схема.utf8) == Data("fum.квитанция-пакета-девяти-путей.1".utf8),
              исходы.contains(Data(квитанция.исход.utf8)),
              (0...14).contains(квитанция.подтверждённый_префикс),
              квитанция.подтверждённый_префикс == префикс,
              квитанция.наблюдённый_префикс.map({ (0...14).contains($0) }) ?? true else {
            throw ОтказПакета.условие("неверная-квитанция-пакета")
        }
        if квитанция.исход == "частичный" {
            guard let наблюдённый = квитанция.наблюдённый_префикс, (1...13).contains(наблюдённый),
                  наблюдённый <= квитанция.подтверждённый_префикс + 1 else {
                throw ОтказПакета.условие("неверный-частичный-префикс")
            }
        }
        if квитанция.исход == "неизвестно", квитанция.наблюдённый_префикс != nil {
            throw ОтказПакета.условие("неизвестность-не-является-наблюдённым-префиксом")
        }
        if квитанция.исход == "завершено" {
            guard квитанция.подтверждённый_префикс == 14, квитанция.наблюдённый_префикс == 14,
                  квитанция.причина == nil else { throw ОтказПакета.условие("неполное-завершение-пакета") }
        } else {
            guard !(квитанция.причина ?? "").isEmpty else { throw ОтказПакета.условие("нет-причины-незавершения") }
            if квитанция.исход == "откат-проверен", квитанция.наблюдённый_префикс != 0 {
                throw ОтказПакета.условие("не-подтверждён-откат")
            }
        }
        return квитанция
    }

    var подтверждённыйПрефикс: Int {
        get throws {
            try проверитьДоступ()
            var число = 0, естьДырка = false
            for номер in 1...14 {
                if try есть("шаг-\(номер)-подтверждение") {
                    guard !естьДырка, try есть("шаг-\(номер)-намерение") else {
                        throw ОтказПакета.условие("дырка-или-подтверждение-без-намерения")
                    }
                    число = номер
                } else { естьДырка = true }
            }
            if число < 13 {
                for номер in (число + 2)...14 {
                    guard try !есть("шаг-\(номер)-намерение") else {
                        throw ОтказПакета.условие("намерение-после-неподтверждённого-шага")
                    }
                }
            }
            return число
        }
    }

    private static func проверитьПриватность(_ адрес: URL) throws {
        guard !адрес.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
              try Data(адрес.path.utf8) == Data(ЧитательПакета.физический(адрес).path.utf8) else {
            throw ОтказПакета.условие("нефизическое-хранилище")
        }
        var путь = адрес.path
        for _ in 0...(путь.utf8.count + 1) {
            var атрибуты = stat()
            let проверяемый = путь == "/" ? "/.git" : путь + "/.git"
            if lstat(проверяемый, &атрибуты) == 0 { throw ОтказПакета.условие("runtime-внутри-Git") }
            guard errno == ENOENT || errno == ENOTDIR else { throw ОтказПакета.условие("предки-runtime-не-подтверждены") }
            if путь == "/" { return }
            let родитель = (путь as NSString).deletingLastPathComponent
            guard !родитель.isEmpty, родитель.utf8.count < путь.utf8.count else {
                throw ОтказПакета.условие("предок-runtime-не-сокращается")
            }
            путь = родитель
        }
        throw ОтказПакета.условие("предел-обхода-runtime")
    }

    private static func проверитьКаталог(_ адрес: URL) throws {
        var атрибуты = stat()
        guard lstat(адрес.path, &атрибуты) == 0, атрибуты.st_mode & S_IFMT == S_IFDIR,
              атрибуты.st_uid == getuid(), атрибуты.st_mode & 0o777 == 0o700 else {
            throw ОтказПакета.условие("не-приватный-каталог-журнала")
        }
    }

    private static func создатьПриватныйКаталог(_ адрес: URL) throws {
        if FileManager.default.fileExists(atPath: адрес.path) {
            try проверитьКаталог(адрес); return
        }
        let родитель = адрес.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: родитель.path) { try создатьПриватныйКаталог(родитель) }
        try FileManager.default.createDirectory(at: адрес, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        try синхронизироватьКаталог(родитель)
    }

    private static func синхронизироватьКаталог(_ адрес: URL) throws {
        let дескриптор = open(адрес.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard дескриптор >= 0 else { throw ОтказПакета.условие("каталог-журнала-не-открыт") }
        defer { close(дескриптор) }
        guard fsync(дескриптор) == 0 else { throw ОтказПакета.условие("каталог-журнала-не-синхронизирован") }
    }

    private static func прочитатьПриватныйФайл(_ адрес: URL) throws -> Data {
        let дескриптор = open(адрес.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
        guard дескриптор >= 0 else { throw ОтказПакета.условие("маркер-не-открыт") }
        defer { close(дескриптор) }
        var атрибуты = stat()
        guard fstat(дескриптор, &атрибуты) == 0, атрибуты.st_mode & S_IFMT == S_IFREG,
              атрибуты.st_nlink == 1, атрибуты.st_uid == getuid(), атрибуты.st_mode & 0o777 == 0o600,
              атрибуты.st_size <= 4096 else { throw ОтказПакета.условие("неверный-маркер-журнала") }
        return try FileHandle(fileDescriptor: дескриптор, closeOnDealloc: false).readToEnd() ?? Data()
    }

    private static func записатьПриватныйФайл(_ данные: Data, _ адрес: URL) throws {
        let дескриптор = open(адрес.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard дескриптор >= 0 else { throw ОтказПакета.условие("маркер-уже-существует-или-недоступен") }
        defer { close(дескриптор) }
        try FileHandle(fileDescriptor: дескриптор, closeOnDealloc: false).write(contentsOf: данные)
        guard fsync(дескриптор) == 0 else { throw ОтказПакета.условие("маркер-не-синхронизирован") }
        try синхронизироватьКаталог(адрес.deletingLastPathComponent())
    }
}
