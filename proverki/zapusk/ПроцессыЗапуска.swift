import Foundation
import Darwin
import CryptoKit
import Testing

struct СредаПроверкиЗапуска: Sendable {
    let корень: URL
    let хранилище: URL
    let бинарник: URL

    init() throws {
        let среда = ProcessInfo.processInfo.environment
        бинарник = URL(fileURLWithPath: try #require(среда["ФУМА_БИНАРНИК_ЗАПУСКА"]))
        let основание = URL(fileURLWithPath: try #require(среда["ФУМА_СВИДЕТЕЛЬСТВА_ЗАПУСКА"]))
        корень = основание.appendingPathComponent(UUID().uuidString.lowercased())
        хранилище = корень.appendingPathComponent("zapusk")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
    }

    func аргументы(_ событие: String) -> [String] {
        ["--хранилище", хранилище.path, "--событие", событие, "--профиль"]
    }
}

struct НаблюдениеПроцессаЗапуска: Codable, Sendable {
    let процесс: Int32
    let код: Int32
    let наносекунды: UInt64
    let вывод: Data
    let ошибки: Data
}

enum ОшибкаПроцессаЗапуска: Error { case бинарникИзменён, времяИстекло, завершение }

actor ПроцессыЗапуска {
    private let среда: СредаПроверкиЗапуска
    private let хэш: Data
    private var номер = 0

    init(среда: СредаПроверкиЗапуска) throws {
        self.среда = среда
        хэш = Data(SHA256.hash(data: try Data(contentsOf: среда.бинарник)))
    }

    func проверенныйХэш() throws -> String {
        guard Data(SHA256.hash(data: try Data(contentsOf: среда.бинарник))) == хэш
        else { throw ОшибкаПроцессаЗапуска.бинарникИзменён }
        return хэш.map { String(format: "%02x", $0) }.joined()
    }

    func запустить(
        _ аргументы: [String],
        закрытыйВывод: Bool = false,
        ввод: Data? = nil,
        окружение: [String: String]? = nil
    ) async throws -> НаблюдениеПроцессаЗапуска {
        try Task.checkCancellation()
        _ = try проверенныйХэш()
        номер += 1
        let номерЗапуска = номер
        let путьВывода = среда.корень.appendingPathComponent("\(номерЗапуска)-вывод.raw")
        let путьОшибок = среда.корень.appendingPathComponent("\(номерЗапуска)-ошибки.raw")
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil,
                attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil,
                attributes: [.posixPermissions: 0o600]) else { throw ОшибкаПроцессаЗапуска.завершение }
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        let процесс = Process()
        процесс.executableURL = среда.бинарник
        процесс.arguments = аргументы
        if let окружение { процесс.environment = окружение }
        let закрытыйКанал = закрытыйВывод ? Pipe() : nil
        if let закрытыйКанал {
            try закрытыйКанал.fileHandleForReading.close()
            процесс.standardOutput = закрытыйКанал.fileHandleForWriting
        } else {
            процесс.standardOutput = вывод
        }
        defer { try? закрытыйКанал?.fileHandleForWriting.close() }
        процесс.standardError = ошибки
        let каналВвода = ввод.map { _ in Pipe() }
        if let каналВвода { процесс.standardInput = каналВвода }
        defer { try? каналВвода?.fileHandleForWriting.close() }
        let часы = ContinuousClock()
        let начало = часы.now
        var запущен = false
        do {
            try процесс.run()
            запущен = true
            if let ввод, let каналВвода {
                try каналВвода.fileHandleForWriting.write(contentsOf: ввод)
                try каналВвода.fileHandleForWriting.close()
            }
            let предел = начало.advanced(by: .seconds(60))
            while процесс.isRunning {
                try Task.checkCancellation()
                guard часы.now < предел else { throw ОшибкаПроцессаЗапуска.времяИстекло }
                try await Task.sleep(for: .milliseconds(5))
            }
            try Task.checkCancellation()
        } catch let ошибка {
            if запущен {
                if процесс.isRunning {
                    guard процесс.processIdentifier > 1,
                        Darwin.kill(процесс.processIdentifier, SIGKILL) == 0 || errno == ESRCH
                    else { throw ОшибкаПроцессаЗапуска.завершение }
                }
                let пределЗавершения = часы.now.advanced(by: .seconds(5))
                while процесс.isRunning {
                    guard часы.now < пределЗавершения else { throw ОшибкаПроцессаЗапуска.завершение }
                    await Task.yield()
                }
            }
            throw ошибка
        }
        let интервал = начало.duration(to: часы.now).components
        _ = try проверенныйХэш()
        try вывод.synchronize()
        try ошибки.synchronize()
        let наблюдение = НаблюдениеПроцессаЗапуска(процесс: процесс.processIdentifier,
            код: процесс.terminationStatus,
            наносекунды: UInt64(интервал.seconds) * 1_000_000_000 + UInt64(интервал.attoseconds / 1_000_000_000),
            вывод: try Data(contentsOf: путьВывода), ошибки: try Data(contentsOf: путьОшибок))
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(наблюдение)
        данные.append(0x0a)
        try данные.write(to: среда.корень.appendingPathComponent("\(номерЗапуска)-процесс.json"),
            options: [.withoutOverwriting])
        return наблюдение
    }
}

// Открытая синтетическая фикстура C1; provider @Suite не запускается.
private struct ФикстураПроверкиПубликации {
    let данныеСнимка: Data
    let данныеВыбора: Data
    let данныеЭтапа: Data
    let данныеСообщения: Data
    let сырыеБайтыКоммита: Data
    let идентификаторШаОдин: String
    let идентификаторШаДва: String
    let ожидаемоеТело: Data
}

private func кодироватьОбъект(_ объект: Any) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: объект,
        options: [.sortedKeys, .withoutEscapingSlashes])
}

private func шестнадцатеричныйХэш<Хэш: Sequence>(_ хэш: Хэш) -> String
where Хэш.Element == UInt8 {
    хэш.map { String(format: "%02x", $0) }.joined()
}

private func идентификаторыКоммита(_ байты: Data) -> (String, String) {
    var объект = Data("commit \(байты.count)\0".utf8)
    объект.append(байты)
    return (
        шестнадцатеричныйХэш(Insecure.SHA1.hash(data: объект)),
        шестнадцатеричныйХэш(SHA256.hash(data: объект)))
}

private func создатьФикстуруПроверкиПубликации() throws -> ФикстураПроверкиПубликации {
    let идентификаторКорневойЗадачи = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    let идентификаторЭтапа = "01a179c7-c248-71b3-8400-85efc981ec65"
    let идентификаторСнимка = "01a177f5-1f11-7543-a68f-fe7e73ff5345"
    let модель = "gpt-5.6-sol"
    let усилие = "ultra"
    let тема = "#"
    let задача = String(repeating: "line preserved  \n", count: 1_771)
        + "tail value  \n"
    let изменения = "x"
    let проверки = "x"
    let граница = "x"
    let исходныйИдентификатор = String(repeating: "a", count: 40)
    let исходноеДерево = "069b2ddf36e9f39781ba682b3881d0f0f435ac13"

    let сообщение: [String: Any] = [
        "схема": "fum.codex-commit-body.2",
        "тема": тема,
        "задача": задача,
        "изменения": изменения,
        "проверки": проверки,
        "граница": граница,
        "модель": модель,
        "усилие": усилие,
        "rootUUID": идентификаторКорневойЗадачи,
    ]
    let этап: [String: Any] = [
        "схема": "fum.codex-stage-content.2",
        "rootUUID": идентификаторКорневойЗадачи,
        "stageUUID": идентификаторЭтапа,
        "операция": "ordinary",
        "исходныйRef": "refs/heads/codex/pure-author-check",
        "исходныйOID": исходныйИдентификатор,
        "исходноеДерево": исходноеДерево,
        "входящийOID": NSNull(),
        "тема": тема,
        "задача": задача,
        "изменения": изменения,
        "проверки": проверки,
        "граница": граница,
    ]
    let снимок: [String: Any] = [
        "схема": "fum.codex-stage-model-snapshot.2",
        "источник": "native-stage-snapshot",
        "snapshotUUID": идентификаторСнимка,
        "модель": модель,
        "усилие": усилие,
        "наблюденоВМиллисекундах": 1_700_000_000_000 as Int64,
        "полнота": true,
        "неполныйХвост": 0,
        "пропусков": 0,
        "этап": этап,
    ]
    let данныеСнимка = try кодироватьОбъект(снимок)
    let хэшСнимка = шестнадцатеричныйХэш(SHA256.hash(data: данныеСнимка))
    let выбор: [String: Any] = [
        "схема": "fum.codex-stage-source-selection.2",
        "snapshotUUID": идентификаторСнимка,
        "snapshotSHA256": хэшСнимка,
        "этап": этап,
    ]
    let ожидаемоеТело = Data(
        ("\(тема)\n\n\(задача)\n\nИзменения: \(изменения)\n"
            + "Проверки: \(проверки)\nГраница: \(граница)\n"
            + "Модель: \(модель)\nУсилие: \(усилие)\n\n"
            + "Codex-Thread-ID: \(идентификаторКорневойЗадачи)\n").utf8)
    var сырыеБайтыКоммита = Data(
        ("tree \(исходноеДерево)\n"
            + "author FUM Codex [\(модель); effort=\(усилие)] <fixture@local> 1 +0000\n"
            + "committer FUM Codex [\(модель); effort=\(усилие)] "
            + "<fixture+12345@local> 1 +0000\n"
            + "encoding UTF-8\n\n").utf8)
    сырыеБайтыКоммита.append(ожидаемоеТело)
    let идентификаторы = идентификаторыКоммита(сырыеБайтыКоммита)
    return ФикстураПроверкиПубликации(
        данныеСнимка: данныеСнимка,
        данныеВыбора: try кодироватьОбъект(выбор),
        данныеЭтапа: try кодироватьОбъект(этап),
        данныеСообщения: try кодироватьОбъект(сообщение),
        сырыеБайтыКоммита: сырыеБайтыКоммита,
        идентификаторШаОдин: идентификаторы.0,
        идентификаторШаДва: идентификаторы.1,
        ожидаемоеТело: ожидаемоеТело)
}

private struct ФайлыКомандыАвторства {
    let среда: СредаПроверкиЗапуска
    let фикстура: ФикстураПроверкиПубликации

    init() throws {
        среда = try СредаПроверкиЗапуска()
        фикстура = try создатьФикстуруПроверкиПубликации()
        for (имя, данные) in [
            ("снимок.json", фикстура.данныеСнимка),
            ("выбор.json", фикстура.данныеВыбора),
            ("этап.json", фикстура.данныеЭтапа),
            ("сообщение.json", фикстура.данныеСообщения),
            ("коммит.raw", фикстура.сырыеБайтыКоммита),
        ] {
            try данные.write(to: путь(имя), options: [.withoutOverwriting])
        }
    }

    func путь(_ имя: String) -> URL { среда.корень.appendingPathComponent(имя) }

    func аргументы(_ объект: String? = nil) -> [String] {
        ["авторство", "проверить", "--снимок", путь("снимок.json").path,
         "--выбор-источника", путь("выбор.json").path,
         "--ожидаемый-этап", путь("этап.json").path,
         "--сообщение", путь("сообщение.json").path,
         "--сырой-коммит", путь("коммит.raw").path,
         "--объект", объект ?? фикстура.идентификаторШаОдин]
    }
}

private func прочитатьОтветАвторства(_ наблюдение: НаблюдениеПроцессаЗапуска) throws -> [String: Any] {
    #expect(наблюдение.ошибки.isEmpty)
    return try #require(JSONSerialization.jsonObject(with: наблюдение.вывод) as? [String: Any])
}

@Suite("Корневой вход проверки авторства", .serialized)
struct ПроверкиКорневогоВходаАвторства {
    @Test func последнийАбзацСодержитОдинТрейлерИдентификатораПотока() throws {
        let фикстура = try создатьФикстуруПроверкиПубликации()
        let разделитель = try #require(фикстура.сырыеБайтыКоммита.range(of: Data([0x0a, 0x0a])))
        let тело = String(decoding: фикстура.сырыеБайтыКоммита[разделитель.upperBound...], as: UTF8.self)
        let ожидаемыйTrailer = "Codex-Thread-ID: 01a07d3d-d376-7ad2-aafc-67e4c25a67eb"

        #expect(тело.hasSuffix("\n"))
        let безКонечногоПеревода = String(тело.dropLast())
        let абзацы = безКонечногоПеревода.components(separatedBy: "\n\n")
        #expect(абзацы.last == ожидаемыйTrailer)

        let trailerСтроки = безКонечногоПеревода
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("Codex-Thread-ID:") }
        #expect(trailerСтроки == [ожидаемыйTrailer])
    }

    @Test func точныеФайлыИДваИдентификатора() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        #expect(файлы.фикстура.сырыеБайтыКоммита.count == 30_495)
        #expect(файлы.фикстура.ожидаемоеТело.count == 30_286)
        for объект in [файлы.фикстура.идентификаторШаОдин, файлы.фикстура.идентификаторШаДва] {
            let наблюдение = try await процессы.запустить(файлы.аргументы(объект))
            #expect(наблюдение.код == 0)
            let ответ = try прочитатьОтветАвторства(наблюдение)
            #expect(ответ["схема"] as? String == "fum.codex-raw-commit-author-body-check.2")
            #expect(ответ["oid"] as? String == объект)
            #expect(ответ["sha256СырогоКоммита"] as? String
                == "df74cb6fb20668828655f1aa92e21c0f8a6829537c3ac77e37363055a09fe808")
            #expect(ответ["точныеБайтыПроверены"] as? Bool == true)
            #expect(ответ["источникМоделиАутентифицирован"] as? Bool == false)
            #expect(ответ["побочныйЭффект"] as? String == "нет")
        }
        #expect(!FileManager.default.fileExists(atPath: файлы.среда.хранилище.path))
    }

    @Test func отказыНеПопадаютВОбычныйЗапуск() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        let другойАвтор = Data(String(decoding: файлы.фикстура.сырыеБайтыКоммита, as: UTF8.self)
            .replacingOccurrences(of: "author FUM Codex", with: "author Другой Codex").utf8)
        var другоеТело = файлы.фикстура.сырыеБайтыКоммита
        другоеТело.append(0x0a)
        for (байты, объект, причина) in [
            (другойАвтор, идентификаторыКоммита(другойАвтор).0, "author"),
            (другоеТело, идентификаторыКоммита(другоеТело).0, "body"),
            (файлы.фикстура.сырыеБайтыКоммита, String(repeating: "0", count: 40), "oid-mismatch"),
        ] {
            try байты.write(to: файлы.путь("коммит.raw"))
            let наблюдение = try await процессы.запустить(файлы.аргументы(объект))
            #expect(наблюдение.код == 1)
            let ответ = try прочитатьОтветАвторства(наблюдение)
            #expect(ответ["схема"] as? String == "fum.отказ-команды-авторства.1")
            #expect(ответ["код"] as? String == причина)
            #expect(ответ["источникМоделиАутентифицирован"] as? Bool == false)
        }
        #expect(!FileManager.default.fileExists(atPath: файлы.среда.хранилище.path))
    }

    @Test func аргументыОтклоняютсяДоЧтения() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        var отсутствующие = файлы.аргументы()
        отсутствующие[3] = файлы.путь("не-существует.json").path
        var чужойГлагол = отсутствующие
        чужойГлагол[1] = "push"
        var чужойФлаг = отсутствующие
        чужойФлаг[4] = "--применить"
        var повтор = отсутствующие
        повтор[4] = "--снимок"
        for аргументы in [чужойГлагол, чужойФлаг, повтор,
                          Array(отсутствующие.dropLast(2)), отсутствующие + ["лишнее"]] {
            let наблюдение = try await процессы.запустить(аргументы)
            #expect(наблюдение.код == 2)
            let ответ = try прочитатьОтветАвторства(наблюдение)
            #expect(ответ["код"] as? String == "аргументы")
        }
        let прежнийОтказ = try await процессы.запустить(["пакет-путей", "неизвестно"])
        #expect(прежнийОтказ.код == 2)
        #expect(прежнийОтказ.вывод.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: файлы.среда.хранилище.path))
    }

    @Test func пределыПрименяютсяДоПолногоЧтения() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        var этап = файлы.фикстура.данныеЭтапа
        этап.append(Data(repeating: 0x20, count: 65_536 - этап.count))
        try этап.write(to: файлы.путь("этап.json"))
        let наГранице = try await процессы.запустить(файлы.аргументы())
        #expect(наГранице.код == 0)
        этап.append(0x20)
        try этап.write(to: файлы.путь("этап.json"))
        let заГраницей = try await процессы.запустить(файлы.аргументы())
        #expect(заГраницей.код == 2)
        #expect(try прочитатьОтветАвторства(заГраницей)["код"] as? String == "предел")
        try файлы.фикстура.данныеЭтапа.write(to: файлы.путь("этап.json"))
        let исходные = файлы.фикстура.сырыеБайтыКоммита
        let конецПервойСтроки = try #require(исходные.firstIndex(of: 0x0a)) + 1
        let дополнение = 1_048_576 - исходные.count
        var граничныйКоммит = Data(исходные.prefix(конецПервойСтроки))
        граничныйКоммит.append(Data(("extra " + String(repeating: "a", count: дополнение - 7) + "\n").utf8))
        граничныйКоммит.append(исходные.dropFirst(конецПервойСтроки))
        #expect(граничныйКоммит.count == 1_048_576)
        try граничныйКоммит.write(to: файлы.путь("коммит.raw"))
        let сыройНаГранице = try await процессы.запустить(
            файлы.аргументы(идентификаторыКоммита(граничныйКоммит).0))
        #expect(сыройНаГранице.код == 0)
        try Data(repeating: 0x41, count: 1_048_577).write(to: файлы.путь("коммит.raw"))
        let большойКоммит = try await процессы.запустить(файлы.аргументы())
        #expect(большойКоммит.код == 2)
        #expect(try прочитатьОтветАвторства(большойКоммит)["код"] as? String == "предел")
    }

    @Test func закрытыйВыводВозвращаетКодДва() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        let наблюдение = try await процессы.запустить(файлы.аргументы(), закрытыйВывод: true)
        #expect(наблюдение.код == 2)
        #expect(наблюдение.вывод.isEmpty)
    }

    @Test func специальныеПутиНеОжидаютПотока() async throws {
        let файлы = try ФайлыКомандыАвторства()
        let процессы = try ПроцессыЗапуска(среда: файлы.среда)
        let ссылка = файлы.путь("ссылка.json")
        try FileManager.default.createSymbolicLink(at: ссылка,
            withDestinationURL: файлы.путь("снимок.json"))
        let каталогСсылки = файлы.путь("каталог-ссылка")
        try FileManager.default.createSymbolicLink(at: каталогСсылки,
            withDestinationURL: файлы.среда.корень)
        let канал = файлы.путь("канал")
        #expect(Darwin.mkfifo(канал.path, mode_t(0o600)) == 0)
        for путь in [ссылка.path, файлы.среда.корень.path, канал.path,
                     каталогСсылки.appendingPathComponent("снимок.json").path] {
            var аргументы = файлы.аргументы()
            аргументы[3] = путь
            let наблюдение = try await процессы.запустить(аргументы)
            #expect(наблюдение.код == 2)
            #expect(try прочитатьОтветАвторства(наблюдение)["код"] as? String == "файл")
        }
    }
}
