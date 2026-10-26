import Foundation
import CryptoKit
import Darwin

public struct ОтказКомандыКаталога: Error, Sendable {
    public let код: String
    public init(код: String) { self.код = код }

    public func представление() throws -> Data {
        struct Ответ: Encodable {
            let схема = "fuma.отказ-команды-восстановления.1"
            let состояние = "blocked"
            let код: String
            let новыхЭффектов = 0
        }
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(Ответ(код: код))
        данные.append(10)
        return данные
    }
}

public enum КомандаКаталогаВосстановления {
    public static let справка = """
    swift run fuma vosstanovitj-uzel план --вход <JSON>
    swift run fuma vosstanovitj-uzel применить --вход <тот-же-JSON> --план <сохранённый-план>
    Вызов без аргументов или «помощь» показывает справку.
    План ограничен выбранными непосредственными детьми. Готовый узел не запускается повторно.
    Адаптер сессий ещё не подключён: применение возвращает закрытый отказ без новых эффектов.
    """

    public static func выполнить(_ аргументы: [String]) async throws -> Data {
        do { return try исполнить(аргументы) }
        catch let отказ as ОтказКомандыКаталога { throw отказ }
        catch { throw ОтказКомандыКаталога(код: "вход") }
    }

    private static func исполнить(_ аргументы: [String]) throws -> Data {
        if аргументы.isEmpty || аргументы == ["помощь"] || аргументы == ["--помощь"] {
            return Data((справка + "\n").utf8)
        }
        guard let действие = аргументы.first, ["план", "применить"].contains(действие),
              (аргументы.count - 1).isMultiple(of: 2) else { throw ОтказКомандыКаталога(код: "аргументы") }
        var поля: [String: String] = [:]
        for номер in stride(from: 1, to: аргументы.count, by: 2) {
            let ключ = аргументы[номер]
            guard ["--вход", "--план"].contains(ключ), поля[ключ] == nil,
                  !аргументы[номер + 1].isEmpty else { throw ОтказКомандыКаталога(код: "аргументы") }
            поля[ключ] = аргументы[номер + 1]
        }
        guard let путь = поля["--вход"], (действие == "план") == (поля["--план"] == nil)
        else { throw ОтказКомандыКаталога(код: "аргументы") }
        let вход = try прочитатьОграниченно(путь, предел: 131_072)
        let запрос = try JSONDecoder().decode(ЗапросВосстановленияКаталога.self, from: вход)
        guard запрос.схемаДанных == ЗапросВосстановленияКаталога.схема, запрос.версия == 1,
              !запрос.допуск.выбранныеДети.isEmpty, запрос.допуск.выбранныеДети.count <= 64,
              запрос.узлы.count <= 64, запрос.допуск.разрешённыеНовыеЭтапы.count <= 128
        else { throw ОтказКомандыКаталога(код: "область") }
        if действие == "план" {
            let план = try ПланировщикКаталогаВосстановления.построить(запрос,
                сеансы: [], наблюденияРепозитория: [], исходныеБайты: вход)
            return try форматировать(план)
        }
        guard let путьПлана = поля["--план"] else { throw ОтказКомандыКаталога(код: "аргументы") }
        let байтыПлана = try прочитатьОграниченно(путьПлана, предел: 1_048_576)
        let план = try JSONDecoder().decode(ПланКаталогаВосстановления.self, from: байтыПлана)
        let хэшВхода = SHA256.hash(data: вход).map { String(format: "%02x", $0) }.joined()
        guard план.схема == "fuma.план-восстановления-каталога.1", план.версия == 1,
              план.хэшВхода == хэшВхода, план.проверитьИдентификатор(),
              try форматировать(план.запрос) == форматировать(запрос)
        else { throw ОтказКомандыКаталога(код: "план-не-совпадает") }
        // JSON не может подключить доверенный host или получить тестовую способность.
        throw ОтказКомандыКаталога(код: "адаптер-сеансов-недоступен")
    }

    private static func форматировать<Значение: Encodable>(_ значение: Значение) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение)
        данные.append(10)
        return данные
    }

    private static func прочитатьОграниченно(_ путь: String, предел: Int) throws -> Data {
        let адрес = URL(fileURLWithPath: путь).standardizedFileURL
        guard путь.hasPrefix("/"), адрес.path == путь, адрес.resolvingSymlinksInPath().path == путь
        else { throw ОтказКомандыКаталога(код: "путь") }
        let дескриптор = путь.withCString { Darwin.open($0, O_RDONLY | O_CLOEXEC | O_NOFOLLOW) }
        guard дескриптор >= 0 else { throw ОтказКомандыКаталога(код: "чтение") }
        let файл = FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
        defer { try? файл.close() }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG
        else { throw ОтказКомандыКаталога(код: "файл") }
        var данные = Data()
        while данные.count <= предел {
            guard let часть = try файл.read(upToCount: предел + 1 - данные.count), !часть.isEmpty else { break }
            данные.append(часть)
        }
        guard данные.count <= предел else { throw ОтказКомандыКаталога(код: "размер") }
        return данные
    }
}
