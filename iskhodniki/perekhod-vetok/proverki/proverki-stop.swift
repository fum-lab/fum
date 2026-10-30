import Foundation
import CryptoKit
import Darwin
import Testing
import FUMStructuringOperatorMemory
@testable import МатериализацияУзлов

private let задачаStop = "00000000-0000-4000-8000-000000000479"
private let рабочийКаталогStop = "/tmp/fum-stop-tests"
private let узелStop = "fum-lab/fum/master"

private func обычныеУсловияStop() -> УсловияСамостоятельности {
    УсловияСамостоятельности(свояОбласть: true, естьПолномочия: true,
        неизвестныйОпасныйЭффект: false, естьНакопленноеПродвижение: true,
        можноБезопасноПродолжать: true, доступнаНезависимаяРабота: true,
        локальнаяИсправимаяПроблема: false, остановкаЗадачи: false,
        естьБезопасныйСледующийШаг: true)
}

private func событиеStop(задача: String = задачаStop, cwd: String = рабочийКаталогStop) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "session_id": задача,
        "hook_event_name": "Stop",
        "cwd": cwd,
        "turn_id": "ход-1",
        "stop_hook_active": false
    ], options: [.sortedKeys])
}

private func наблюденияStop(_ условия: УсловияСамостоятельности,
                            следующаяРабота: String = "продолжить независимый срез") throws -> Data {
    try JSONEncoder().encode(НаблюденияStop(задача: задачаStop, узел: узелStop,
        следующаяРабота: следующаяРабота, условия: условия))
}

private func объектОтвета(_ данные: Data) throws -> [String: Any] {
    try #require(данные.last == 0x0a)
    return try #require(try JSONSerialization.jsonObject(with: данные) as? [String: Any])
}

@Suite("FUMA Stop: приоритет и независимое продолжение")
struct ПроверкиStop {
    @Test("Неизвестный эффект A не запрещает доказанную независимую работу B")
    func неизвестныйЭффектСохраняетНезависимоеПродолжение() throws {
        var условия = обычныеУсловияStop()
        условия.неизвестныйОпасныйЭффект = true
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(условия) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect((ответ["reason"] as? String)?.contains("неизвестный опасный эффект") == true)
        #expect((ответ["reason"] as? String)?.contains("независим") == true)
    }

    @Test("Явный STOP человека выше неизвестного эффекта и независимой работы")
    func остановкаЧеловекаИмеетПриоритет() throws {
        var условия = обычныеУсловияStop()
        условия.неизвестныйОпасныйЭффект = true
        условия.остановкаЗадачи = true
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(условия, следующаяРабота: "") },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["continue"] as? Bool == false)
        #expect((ответ["stopReason"] as? String)?.contains("остановлена пользователем") == true)
        #expect(ответ["decision"] == nil)
    }

    @Test("Ошибка argv не принимает идентичность из native события")
    func ошибкаПараметровСохраняетГраницуЗадачи() throws {
        let чужаяЗадача = "00000000-0000-4000-8000-000000000480"
        let аргументы = ["--codex-thread-id", задачаStop, "--неизвестный-флаг", "значение"]
        let чужой = try объектОтвета(КомандаStop.выполнить(аргументы,
            ввод: try событиеStop(задача: чужаяЗадача)))
        #expect(чужой.isEmpty)

        let целевой = try объектОтвета(КомандаStop.выполнить(аргументы,
            ввод: try событиеStop()))
        #expect(целевой["decision"] as? String == "block")
        #expect(целевой["continue"] == nil)
        #expect((целевой["reason"] as? String)?.contains("неверный целевой вход") == true)

        let неоднозначный = try объектОтвета(КомандаStop.выполнить(
            ["--codex-thread-id", задачаStop, "--codex-thread-id", чужаяЗадача],
            ввод: try событиеStop()))
        #expect(неоднозначный["systemMessage"] != nil)
    }

    @Test("Безопасная доступная работа блокирует преждевременный final")
    func доступнаяРаботаБлокируетFinal() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect((ответ["reason"] as? String)?.contains("продолжить независимый срез") == true)
    }

    @Test("Чужое событие не читает локальные наблюдения")
    func чужоеСобытиеНеЧитаетНаблюдения() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(задача: "00000000-0000-4000-8000-000000000480"),
            наблюдения: { throw CocoaError(.fileNoSuchFile) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ.isEmpty)
    }

    @Test("Ошибка целевых наблюдений остаётся fail-closed")
    func ошибкаНаблюденийНеОткрываетFinal() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { Data("{".utf8) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect(ответ.isEmpty == false)
    }

    @Test("Повторное поле native Stop и наблюдений отклоняется")
    func повторныеПоляОтклоняются() throws {
        let повторСобытия = Data("""
        {"session_id":"\(задачаStop)","session_id":"\(задачаStop)","hook_event_name":"Stop","cwd":"\(рабочийКаталогStop)","turn_id":"ход-1","stop_hook_active":false}
        """.utf8)
        let ответСобытия = try объектОтвета(ОбработчикStop.ответ(
            событие: повторСобытия,
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответСобытия["systemMessage"] != nil)

        let корректные = try наблюденияStop(обычныеУсловияStop())
        let текст = try #require(String(data: корректные, encoding: .utf8))
        let повторНаблюдений = Data(текст.replacingOccurrences(
            of: "\"остановкаЗадачи\":false",
            with: "\"остановкаЗадачи\":false,\"остановкаЗадачи\":true").utf8)
        let ответНаблюдений = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { повторНаблюдений },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответНаблюдений["decision"] as? String == "block")
        #expect(ответНаблюдений.isEmpty == false)
    }

    @Test("Дополнительное дробное native-поле не меняет решение")
    func полныйСинтаксисЧислаВДополнительномПоле() throws {
        let событие = Data("""
        {"session_id":"\(задачаStop)","hook_event_name":"Stop","cwd":"\(рабочийКаталогStop)","turn_id":"ход-1","stop_hook_active":false,"native_metric":1.25e+3}
        """.utf8)
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: событие,
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
    }

    @Test("Приватный обычный файл наблюдений читается без следования ссылкам")
    func обычныйФайлНаблюдений() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        let данные = try наблюденияStop(обычныеУсловияStop())
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)
        #expect(try КомандаStop.прочитатьОбычныйФайл(путь.path) == данные)

        try FileManager.default.setAttributes([.posixPermissions: 0o644],
            ofItemAtPath: путь.path)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(путь.path)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        let жёсткаяСсылка = корень.appendingPathComponent("hardlink.json")
        try FileManager.default.linkItem(at: путь, to: жёсткаяСсылка)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(путь.path)
        }
        try FileManager.default.removeItem(at: жёсткаяСсылка)

        let символическаяСсылка = корень.appendingPathComponent("symlink.json")
        try FileManager.default.createSymbolicLink(at: символическаяСсылка,
            withDestinationURL: путь)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(символическаяСсылка.path)
        }
    }

    @Test("Рост файла после предварительной проверки ограничивает чтение")
    func ростПослеПредварительнойПроверкиОграничен() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-growth-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        try Data([0x7b]).write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        var контрольныйДескриптор: Int32 = -1
        defer {
            if контрольныйДескриптор >= 0 {
                _ = Darwin.close(контрольныйДескриптор)
            }
        }
        #expect(throws: ОтказКомандыStop.превышенПределСостояния) {
            try КомандаStop.прочитатьОбычныйФайл(
                путь.path,
                послеПредварительнойПроверки: { дескриптор in
                    контрольныйДескриптор = Darwin.dup(дескриптор)
                    guard контрольныйДескриптор >= 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                    let писатель = Darwin.open(путь.path, O_WRONLY | O_CLOEXEC)
                    guard писатель >= 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                    defer { _ = Darwin.close(писатель) }
                    guard Darwin.ftruncate(писатель, 131_072) == 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                }
            )
        }
        #expect(Darwin.lseek(контрольныйДескриптор, 0, SEEK_CUR) == 65_537)
    }

    @Test("Файл ровно на границе 65 536 байт принимается")
    func файлНаГраницеПринимается() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-limit-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        let данные = Data(repeating: 0x20, count: 65_536)
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        #expect(try КомандаStop.прочитатьОбычныйФайл(путь.path) == данные)
    }
}

@Suite("Профиль Stop")
struct ПрофильStop {
    private struct РезультатПрофиля: Encodable {
        let схема = "fum.профиль-stop.1"
        let повторовВРаунде: Int
        let строгийJSONНаносекундыНаВызов: [UInt64]
        let полныйОтветНаносекундыНаВызов: [UInt64]
        let медианаСтрогогоJSON: UInt64
        let медианаПолногоОтвета: UInt64
    }

    @Test("Строгий JSON и полный FUMA-ответ измеряются раздельно")
    func измерить() throws {
        let повторов = 200
        let раундов = 5
        let событие = try событиеStop()
        let наблюдения = try наблюденияStop(обычныеУсловияStop())
        let часы = ContinuousClock()
        var json: [UInt64] = []
        var ответы: [UInt64] = []

        for _ in 0..<раундов {
            var начало = часы.now
            for _ in 0..<повторов {
                try ЗакрытыйJSON.проверить(событие)
                try ЗакрытыйJSON.проверить(наблюдения)
            }
            json.append(наносекунды(начало.duration(to: часы.now)) / UInt64(повторов))

            начало = часы.now
            for _ in 0..<повторов {
                let ответ = ОбработчикStop.ответ(событие: событие,
                    наблюдения: { наблюдения }, ожидаемаяЗадача: задачаStop,
                    ожидаемыйУзел: узелStop,
                    ожидаемыйРабочийКаталог: рабочийКаталогStop)
                #expect(ответ.last == 0x0a)
            }
            ответы.append(наносекунды(начало.duration(to: часы.now)) / UInt64(повторов))
        }

        let результат = РезультатПрофиля(повторовВРаунде: повторов,
            строгийJSONНаносекундыНаВызов: json,
            полныйОтветНаносекундыНаВызов: ответы,
            медианаСтрогогоJSON: json.sorted()[раундов / 2],
            медианаПолногоОтвета: ответы.sorted()[раундов / 2])
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(результат)
        данные.append(0x0a)
        if let путь = ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_STOP"] {
            try данные.write(to: URL(fileURLWithPath: путь), options: [.withoutOverwriting])
        }
        print(String(decoding: данные, as: UTF8.self), terminator: "")
    }

    private func наносекунды(_ длительность: Duration) -> UInt64 {
        let части = длительность.components
        return UInt64(части.seconds) * 1_000_000_000
            + UInt64(части.attoseconds / 1_000_000_000)
    }
}


@Suite(.serialized)
struct ПроверкиТекущихОбязательствStop {
    private struct Фикстура {
        static let задача = "00000000-0000-4000-8000-000000000479"
        static let чужаяЗадача = "00000000-0000-4000-8000-000000000480"
        static let узел = "fum-lab/fum/master"
        static let ref = "refs/heads/fum-lab/fum/master"
        static let область = "unit-stop-assignment"
        static let поколение = "unit-generation-1"
        static let пункт = "repair-stop-unit"
        static let доставка = String(repeating: "2", count: 40)

        let корень: URL
        let nativeCWD: URL
        let дерево: URL
        let gitDir: URL
        let commonGitDir: URL
        let состояние: URL
        let заголовок: URL
        let квитанции: URL
        let HEAD: String
        let rawCommit: Data
        let хэшЗаголовка: String
        let сейчас: Int64

        static func sha256(_ данные: Data) -> String {
            SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
        }

        static func json(_ объект: Any) throws -> Data {
            var данные = try JSONSerialization.data(
                withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
            данные.append(10)
            return данные
        }

        static func сохранить(_ данные: Data, в путь: URL, права: Int) throws {
            try данные.write(to: путь)
            try FileManager.default.setAttributes(
                [.posixPermissions: права], ofItemAtPath: путь.path)
        }

        init() throws {
            корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
                .appendingPathComponent("fum-stop-v2-\(UUID().uuidString.lowercased())")
            nativeCWD = корень.appendingPathComponent("native")
            дерево = корень.appendingPathComponent("writing")
            gitDir = корень.appendingPathComponent("git")
            commonGitDir = корень.appendingPathComponent("common")
            состояние = корень.appendingPathComponent("current.json")
            заголовок = корень.appendingPathComponent("header.json")
            квитанции = корень.appendingPathComponent("receipts")
            сейчас = Int64(Date().timeIntervalSince1970)

            for каталог in [
                корень, nativeCWD, дерево, gitDir, commonGitDir, квитанции,
                commonGitDir.appendingPathComponent("refs"),
                commonGitDir.appendingPathComponent("refs/heads"),
                commonGitDir.appendingPathComponent("refs/heads/fum-lab"),
                commonGitDir.appendingPathComponent("refs/heads/fum-lab/fum")
            ] {
                try FileManager.default.createDirectory(
                    at: каталог, withIntermediateDirectories: false,
                    attributes: [.posixPermissions: 0o700])
            }

            rawCommit = Data(("""
            tree \(String(repeating: "1", count: 40))
            parent \(String(repeating: "3", count: 40))
            parent \(Self.доставка)
            author Unit <unit@example.invalid> 1700000000 +0000
            committer Unit <unit@example.invalid> 1700000000 +0000

            synthetic bounded Stop fixture

            """).utf8)
            var объект = Data("commit \(rawCommit.count)\0".utf8)
            объект.append(rawCommit)
            HEAD = Insecure.SHA1.hash(data: объект)
                .map { String(format: "%02x", $0) }.joined()

            let метаданные: [(URL, String)] = [
                (дерево.appendingPathComponent(".git"), "gitdir: \(gitDir.path)\n"),
                (gitDir.appendingPathComponent("gitdir"), "\(дерево.path)/.git\n"),
                (gitDir.appendingPathComponent("commondir"), "\(commonGitDir.path)\n"),
                (gitDir.appendingPathComponent("HEAD"), "ref: \(Self.ref)\n"),
                (commonGitDir.appendingPathComponent(Self.ref), "\(HEAD)\n")
            ]
            for (путь, текст) in метаданные {
                try Self.сохранить(Data(текст.utf8), в: путь, права: 0o644)
            }
            let данные = try Self.json([
                "схема": "fum.stop-заголовок.2", "задача": Self.задача,
                "узел": Self.узел, "область": Self.область,
                "поколение": Self.поколение, "cwd": nativeCWD.path,
                "дерево": дерево.path, "ref": Self.ref,
                "gitDir": gitDir.path, "commonGitDir": commonGitDir.path,
                "backend": "files", "objectFormat": "sha1",
                "исходники": Self.доставка, "состояние": состояние.path,
                "каталогКвитанций": квитанции.path, "максимальныйВозрастСекунд": 900
            ] as [String: Any])
            хэшЗаголовка = Self.sha256(данные)
            try Self.сохранить(данные, в: заголовок, права: 0o400)
        }

        func очистить() {
            do { try FileManager.default.removeItem(at: корень) }
            catch { Issue.record("Не удалена собственная Stop-фикстура: \(error)") }
        }

        var аргументы: [String] {
            ["--идентификатор-обработчика", "fum.stop-handler.1",
             "--codex-thread-id", Self.задача, "--идентификатор-узла", Self.узел,
             "--ожидаемый-cwd", nativeCWD.path, "--состояние", состояние.path,
             "--профиль-наблюдений", "fum.текущие-обязательства-stop.2",
             "--заголовок", заголовок.path, "--хэш-заголовка", хэшЗаголовка]
        }

        func событие(задача: String = Фикстура.задача) -> [String: Any] {
            ["session_id": задача, "hook_event_name": "Stop",
             "cwd": nativeCWD.path, "turn_id": "unit-turn-479",
             "stop_hook_active": false]
        }

        func пункт(_ состояние: String, область: String = Фикстура.область,
                   id: String = Фикстура.пункт, уровень: String = "исходники") -> [String: Any] {
            ["id": id, "область": область, "состояние": состояние,
             "уровень": уровень, "основание": "Синтетическое текущее обязательство"]
        }

        func снимок(_ статус: String = "доступен", следующийШаг: Bool = true)
            -> [String: Any] {
            let условия: [String: Any] = [
                "свояОбласть": true, "естьПолномочия": true,
                "неизвестныйОпасныйЭффект": false, "естьНакопленноеПродвижение": true,
                "можноБезопасноПродолжать": true,
                "доступнаНезависимаяРабота": следующийШаг,
                "локальнаяИсправимаяПроблема": false, "остановкаЗадачи": false,
                "естьБезопасныйСледующийШаг": следующийШаг
            ]
            return [
                "схема": "fum.текущие-обязательства-stop.2",
                "заголовокSHA256": хэшЗаголовка, "задача": Self.задача,
                "узел": Self.узел, "область": Self.область,
                "поколение": Self.поколение, "cwd": nativeCWD.path,
                "дерево": дерево.path, "ref": Self.ref, "HEAD": HEAD,
                "выпущен": сейчас - 5, "действуетДо": сейчас + 600,
                "управление": ["действие": "продолжать", "основание": "Текущий допуск"],
                "пункты": [пункт(статус)], "неизвестныеНамерения": [],
                "наблюдения": [
                    "схема": "fum.stop-наблюдения.1", "задача": Self.задача,
                    "узел": Self.узел, "условия": условия,
                    "следующаяРабота": следующийШаг
                        ? "выполнить текущий безопасный шаг" : ""
                ]
            ]
        }

        func завершённый(областьКвитанции: String = Фикстура.область) throws -> [String: Any] {
            let имя = "receipt-\(UUID().uuidString.lowercased()).json"
            let данные = try Self.json([
                "схема": "fum.stop-диспозиция.2", "задача": Self.задача,
                "узел": Self.узел, "область": областьКвитанции,
                "поколение": Self.поколение, "HEAD": HEAD,
                "исход": "bounded-complete",
                "пункты": [["id": Self.пункт, "уровень": "исходники",
                    "доставка": Self.доставка, "интеграция": HEAD,
                    "цепочка": [rawCommit.base64EncodedString()]]],
                "основание": "ROOT принял текущий bounded assignment",
                "ответственный": Self.задача,
                "условиеВозврата": "Новый адресный допуск ROOT", "остаток": []
            ] as [String: Any])
            try Self.сохранить(данные, в: квитанции.appendingPathComponent(имя), права: 0o600)
            var результат = снимок("закрыт", следующийШаг: false)
            результат["диспозиция"] = ["путь": имя, "sha256": Self.sha256(данные)]
            return результат
        }

        func ответ(_ снимок: [String: Any], событие: [String: Any]? = nil)
            throws -> [String: Any] {
            try Self.сохранить(try Self.json(снимок), в: состояние, права: 0o600)
            return try разобрать(КомандаStop.выполнить(
                аргументы, ввод: Self.json(событие ?? self.событие())))
        }

        func разобрать(_ данные: Data) throws -> [String: Any] {
            #expect(данные.last == 10)
            return try #require(try JSONSerialization.jsonObject(with: данные) as? [String: Any])
        }
    }

    private func блок(_ ответ: [String: Any]) {
        #expect(ответ["decision"] as? String == "block")
        #expect(ответ["continue"] == nil)
    }

    @Test func целевойВходБезTurnНеОстанавливаетЗадачу() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var событие = ф.событие(); событие.removeValue(forKey: "turn_id")
        блок(try ф.ответ(ф.завершённый(), событие: событие))
    }

    @Test func nativeCWDОтличаетсяОтWritingWИДоступнаяРаботаБлокирует() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        #expect(ф.nativeCWD.path != ф.дерево.path)
        let ответ = try ф.ответ(ф.снимок())
        блок(ответ)
        #expect((ответ["reason"] as? String)?.contains("текущий безопасный шаг") == true)
    }

    @Test func ожидающийИДоставленныйРебёнокНеЗакрываютAssignment() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        for статус in ["ожидает-ребёнка", "доставлен"] {
            var снимок = try ф.завершённый()
            снимок["пункты"] = [ф.пункт(статус)]
            блок(try ф.ответ(снимок))
        }
    }

    @Test func staleИНесовпадающийHEADНеДаютRelease() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var stale = try ф.завершённый()
        stale["выпущен"] = ф.сейчас - 1800; stale["действуетДо"] = ф.сейчас - 900
        блок(try ф.ответ(stale))
        var другойHEAD = try ф.завершённый()
        другойHEAD["HEAD"] = String(repeating: "e", count: 40)
        блок(try ф.ответ(другойHEAD))
    }

    @Test func человеческиеSTOPИПаузаВышеStaleИНеполногоSnapshot() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        for действие in ["стоп", "пауза"] {
            var снимок = ф.снимок()
            снимок["управление"] = ["действие": действие, "основание": "Явное указание человека"]
            снимок["выпущен"] = ф.сейчас - 1800; снимок["действуетДо"] = ф.сейчас - 900
            for ключ in ["HEAD", "пункты", "наблюдения"] { снимок.removeValue(forKey: ключ) }
            let ответ = try ф.ответ(снимок)
            #expect(ответ["continue"] as? Bool == false)
            #expect(ответ["decision"] == nil)
            #expect((ответ["stopReason"] as? String)?.contains("пользовател") == true)
        }
    }

    @Test func чужоеСобытиеНеЧитаетОтсутствующийSnapshot() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        #expect(!FileManager.default.fileExists(atPath: ф.состояние.path))
        let ответ = try ф.разобрать(КомандаStop.выполнить(
            ф.аргументы, ввод: Фикстура.json(ф.событие(задача: Фикстура.чужаяЗадача))))
        #expect(ответ.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: ф.состояние.path))
    }

    @Test func доказанныйBoundedCompleteИгнорируетЗакрытуюЧужуюИсторию() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var снимок = try ф.завершённый()
        снимок["пункты"] = [ф.пункт("закрыт"),
            ф.пункт("закрыт", область: "historical-scope", id: "old-child", уровень: "native")]
        #expect(try ф.ответ(снимок).isEmpty)
    }

    @Test func boolЧужаяКвитанцияИUnknownIntentНеЯвляютсяCompleted() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var bool = ф.снимок("закрыт", следующийШаг: false); bool["всёГотово"] = true
        блок(try ф.ответ(bool))
        блок(try ф.ответ(ф.завершённый(областьКвитанции: "foreign-scope")))
        var unknown = try ф.завершённый(); unknown["неизвестныеНамерения"] = ["intent-1"]
        блок(try ф.ответ(unknown))
    }

    private func изменитьКвитанциюV2(
        _ ф: Фикстура, _ снимок: inout [String: Any],
        _ изменить: (inout [String: Any]) throws -> Void
    ) throws {
        let ссылка = try #require(снимок["диспозиция"] as? [String: String])
        let имя = try #require(ссылка["путь"])
        let путь = ф.квитанции.appendingPathComponent(имя)
        var объект = try #require(
            try JSONSerialization.jsonObject(with: Data(contentsOf: путь)) as? [String: Any])
        try изменить(&объект)
        let данные = try Фикстура.json(объект)
        try Фикстура.сохранить(данные, в: путь, права: 0o600)
        снимок["диспозиция"] = ["путь": имя, "sha256": Фикстура.sha256(данные)]
    }

    @Test func фактическиеHEADRefИBacklinkНеПодменяютсяСнимкомV2() throws {
        for случай in ["HEAD", "ref", "backlink", "relative-common", "relative-up-two"] {
            let ф = try Фикстура(); defer { ф.очистить() }
            let снимок = try ф.завершённый()
            #expect(try ф.ответ(снимок).isEmpty)
            if случай == "relative-up-two" {
                let каталог = ф.commonGitDir.appendingPathComponent("worktrees")
                let git = каталог.appendingPathComponent("writer")
                for dir in [каталог, git] {
                    try FileManager.default.createDirectory(at: dir,
                        withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
                }
                let файлы: [(URL, String)] = [
                    (ф.дерево.appendingPathComponent(".git"), "gitdir: \(git.path)\n"),
                    (git.appendingPathComponent("gitdir"), "\(ф.дерево.path)/.git\n"),
                    (git.appendingPathComponent("commondir"), "../..\n"),
                    (git.appendingPathComponent("HEAD"), "ref: \(Фикстура.ref)\n")
                ]
                for (путь, текст) in файлы {
                    try Фикстура.сохранить(Data(текст.utf8), в: путь, права: 0o644)
                }
                var header = try #require(try JSONSerialization.jsonObject(
                    with: Data(contentsOf: ф.заголовок)) as? [String: Any])
                header["gitDir"] = git.path
                let bytes = try Фикстура.json(header)
                let hash = Фикстура.sha256(bytes)
                try FileManager.default.setAttributes([.posixPermissions: 0o600],
                    ofItemAtPath: ф.заголовок.path)
                try Фикстура.сохранить(bytes, в: ф.заголовок, права: 0o400)
                var args = ф.аргументы; args[15] = hash
                var state = снимок; state["заголовокSHA256"] = hash
                try Фикстура.сохранить(Фикстура.json(state), в: ф.состояние, права: 0o600)
                let input = try Фикстура.json(ф.событие())
                let ответ = try ф.разобрать(КомандаStop.выполнить(args, ввод: input))
                #expect(ответ.isEmpty)
                let moved = ф.commonGitDir.appendingPathComponent("owned-worktrees")
                try FileManager.default.moveItem(at: каталог, to: moved)
                try FileManager.default.createSymbolicLink(at: каталог, withDestinationURL: moved)
                блок(try ф.разобрать(КомандаStop.выполнить(args, ввод: input)))
                continue
            }
            if случай == "relative-common" {
                let путь = ф.gitDir.appendingPathComponent("commondir")
                try Фикстура.сохранить(Data("../common\n".utf8), в: путь, права: 0o644)
                #expect(try ф.ответ(снимок).isEmpty)
                try Фикстура.сохранить(Data("../common/../common\n".utf8), в: путь, права: 0o644)
                блок(try ф.ответ(снимок))
                continue
            }
            let путь: URL, текст: String
            switch случай {
            case "HEAD":
                путь = ф.commonGitDir.appendingPathComponent(Фикстура.ref)
                текст = String(repeating: "e", count: 40) + "\n"
            case "ref":
                путь = ф.gitDir.appendingPathComponent("HEAD")
                текст = "ref: refs/heads/other\n"
            default:
                путь = ф.gitDir.appendingPathComponent("gitdir")
                текст = ф.nativeCWD.appendingPathComponent(".git").path + "\n"
            }
            try Фикстура.сохранить(Data(текст.utf8), в: путь, права: 0o644)
            блок(try ф.ответ(снимок))
        }
    }

    @Test func праваРазмерИСимволическаяСсылкаSnapshotПроверяютсяV2() throws {
        for случай in ["права", "размер", "ссылка"] {
            let ф = try Фикстура(); defer { ф.очистить() }
            let снимок = try ф.завершённый()
            #expect(try ф.ответ(снимок).isEmpty)
            switch случай {
            case "права":
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o644], ofItemAtPath: ф.состояние.path)
            case "размер":
                var данные = try Фикстура.json(снимок)
                try #require(данные.count <= 32_768)
                данные.append(Data(repeating: 0x20, count: 32_768 - данные.count))
                try Фикстура.сохранить(данные, в: ф.состояние, права: 0o600)
                let граничный = try ф.разобрать(КомандаStop.выполнить(
                    ф.аргументы, ввод: Фикстура.json(ф.событие())))
                #expect(граничный.isEmpty)
                данные.append(0x20)
                try Фикстура.сохранить(данные, в: ф.состояние, права: 0o600)
            default:
                let цель = ф.корень.appendingPathComponent("owned-state-target.json")
                try Фикстура.сохранить(
                    Фикстура.json(снимок), в: цель, права: 0o600)
                try FileManager.default.removeItem(at: ф.состояние)
                try FileManager.default.createSymbolicLink(
                    at: ф.состояние, withDestinationURL: цель)
            }
            // ф.ответ переписал бы файл и права, поэтому вызываем reader напрямую.
            блок(try ф.разобрать(КомандаStop.выполнить(
                ф.аргументы, ввод: Фикстура.json(ф.событие()))))
        }
    }

    @Test func SHAЦепочкаRawИIDsДиспозицииПроверяютсяНезависимоV2() throws {
        for случай in ["sha", "raw-chain", "ids", "single-parent"] {
            let ф = try Фикстура(); defer { ф.очистить() }
            var снимок = try ф.завершённый()
            #expect(try ф.ответ(снимок).isEmpty)
            if случай == "sha" {
                var ссылка = try #require(снимок["диспозиция"] as? [String: String])
                let прежний = try #require(ссылка["sha256"])
                ссылка["sha256"] = (прежний.first == "0" ? "1" : "0")
                    + String(прежний.dropFirst())
                снимок["диспозиция"] = ссылка
            } else if случай == "single-parent" {
                // Оставляем доставку родителем, пересчитываем настоящий Git OID
                // и согласуем HEAD/ref/receipt: отказ должен быть именно по M.
                let текст = String(decoding: ф.rawCommit, as: UTF8.self)
                    .replacingOccurrences(
                        of: "parent " + String(repeating: "3", count: 40) + "\n", with: "")
                let raw = Data(текст.utf8)
                var объект = Data("commit \(raw.count)\0".utf8)
                объект.append(raw)
                let oid = Insecure.SHA1.hash(data: объект)
                    .map { String(format: "%02x", $0) }.joined()
                try Фикстура.сохранить(
                    Data((oid + "\n").utf8),
                    в: ф.commonGitDir.appendingPathComponent(Фикстура.ref), права: 0o644)
                снимок["HEAD"] = oid
                try изменитьКвитанциюV2(ф, &снимок) { d in
                    d["HEAD"] = oid
                    d["пункты"] = [[
                        "id": Фикстура.пункт, "уровень": "исходники",
                        "доставка": Фикстура.доставка, "интеграция": oid,
                        "цепочка": [raw.base64EncodedString()]
                    ]] as [[String: Any]]
                }
            } else {
                try изменитьКвитанциюV2(ф, &снимок) { d in
                    var пункты = try #require(d["пункты"] as? [[String: Any]])
                    try #require(пункты.count == 1)
                    if случай == "raw-chain" {
                        var raw = ф.rawCommit
                        raw.append(0x78)
                        пункты[0]["цепочка"] = [raw.base64EncodedString()]
                    } else {
                        пункты[0]["id"] = "other-assignment"
                    }
                    d["пункты"] = пункты
                }
            }
            блок(try ф.ответ(снимок))
        }
    }

    @Test func закрытыйNativeТребуетКвитанциюИСинтетическиВернаяПринимаетсяV2() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var снимок = try ф.завершённый()
        #expect(try ф.ответ(снимок).isEmpty)
        снимок["пункты"] = [ф.пункт("закрыт", уровень: "native")]
        try изменитьКвитанциюV2(ф, &снимок) { d in
            d["пункты"] = [["id": Фикстура.пункт, "уровень": "native"]]
        }
        блок(try ф.ответ(снимок))

        let имя = "synthetic-native-\(UUID().uuidString.lowercased()).json"
        let native = try Фикстура.json([
            "схема": "fum.native-stop-проба.1", "задача": Фикстура.задача,
            "область": Фикстура.область, "поколение": Фикстура.поколение,
            "HEAD": ф.HEAD, "решение": "block",
            "бинарникSHA256": String(repeating: "a", count: 64),
            "определениеХукаSHA256": String(repeating: "b", count: 64),
            "наблюдениеSHA256": String(repeating: "c", count: 64)
        ])
        try Фикстура.сохранить(
            native, в: ф.квитанции.appendingPathComponent(имя), права: 0o600)
        try изменитьКвитанциюV2(ф, &снимок) { d in
            d["пункты"] = [[
                "id": Фикстура.пункт, "уровень": "native",
                "квитанцияNative": ["путь": имя, "sha256": Фикстура.sha256(native)]
            ]] as [[String: Any]]
        }
        #expect(try ф.ответ(снимок).isEmpty)

        for ключ in ["схема", "задача", "область", "поколение", "HEAD", "решение",
                     "бинарникSHA256", "определениеХукаSHA256", "наблюдениеSHA256", "link-sha"] {
            var объект = try #require(try JSONSerialization.jsonObject(with: native) as? [String: Any])
            if ключ != "link-sha" { объект[ключ] = "неверное-значение" }
            let данные = try Фикстура.json(объект)
            try Фикстура.сохранить(данные, в: ф.квитанции.appendingPathComponent(имя), права: 0o600)
            try изменитьКвитанциюV2(ф, &снимок) { d in
                d["пункты"] = [["id": Фикстура.пункт, "уровень": "native",
                    "квитанцияNative": ["путь": имя, "sha256": ключ == "link-sha"
                        ? String(repeating: "0", count: 64) : Фикстура.sha256(данные)]]]
            }
            блок(try ф.ответ(снимок))
        }
    }

    @Test func неизвестноеНамерениеИАктивнаяЧужаяОбластьНеСкрываютсяИсториейV2() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var исторический = try ф.завершённый()
        исторический["пункты"] = [ф.пункт("закрыт"),
            ф.пункт("закрыт", область: "foreign-scope", id: "foreign-item")]
        #expect(try ф.ответ(исторический).isEmpty)

        for случай in ["unknown-dangerous", "foreign-ownership", "no-authority", "nextWork"] {
            var кандидат = исторический
            var наблюдения = try #require(кандидат["наблюдения"] as? [String: Any])
            var условия = try #require(наблюдения["условия"] as? [String: Any])
            switch случай {
            case "unknown-dangerous": условия["неизвестныйОпасныйЭффект"] = true
            case "foreign-ownership": условия["свояОбласть"] = false
            case "no-authority": условия["естьПолномочия"] = false
            default: наблюдения["следующаяРабота"] = "Доступен следующий адресный шаг"
            }
            наблюдения["условия"] = условия
            кандидат["наблюдения"] = наблюдения
            блок(try ф.ответ(кандидат))
        }

        var неизвестный = исторический
        неизвестный["неизвестныеНамерения"] = ["foreign-intent"]
        блок(try ф.ответ(неизвестный))

        var активный = исторический
        активный["пункты"] = [ф.пункт("закрыт"),
            ф.пункт("доступен", область: "foreign-scope", id: "foreign-item")]
        блок(try ф.ответ(активный))
    }

    @Test func stopHookActiveНеДаётОбходаАктивномуОбязательствуV2() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        for статус in ["доступен", "ожидает-ребёнка", "доставлен"] {
            let снимок = ф.снимок(статус)
            let обычный = try ф.ответ(снимок)
            блок(обычный)
            var событие = ф.событие()
            событие["stop_hook_active"] = true
            let повторный = try ф.ответ(снимок, событие: событие)
            блок(повторный)
            #expect((повторный["reason"] as? String) == (обычный["reason"] as? String))
        }
    }

    @Test func blockedReturnТребуетНедоступностиРаботыИВладельцаОстаткаV2() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var заблокированный = try ф.завершённый()
        #expect(try ф.ответ(заблокированный).isEmpty)
        заблокированный["пункты"] = [ф.пункт("блокирован")]
        try изменитьКвитанциюV2(ф, &заблокированный) { d in
            d["исход"] = "blocked-return"
            d["остаток"] = [Фикстура.пункт]
            d["блокерSHA256"] = String(repeating: "d", count: 64)
        }
        #expect(try ф.ответ(заблокированный).isEmpty)

        var доступный = ф.снимок("доступен")
        доступный["диспозиция"] = заблокированный["диспозиция"]
        блок(try ф.ответ(доступный))

        var неизвестный = заблокированный
        неизвестный["неизвестныеНамерения"] = ["intent-owned"]
        try изменитьКвитанциюV2(ф, &неизвестный) { d in
            d["остаток"] = [Фикстура.пункт, "intent-owned"]
        }
        #expect(try ф.ответ(неизвестный).isEmpty)

        var коллизия = неизвестный
        коллизия["неизвестныеНамерения"] = [Фикстура.пункт, "intent-owned"]
        try изменитьКвитанциюV2(ф, &коллизия) { d in
            d["остаток"] = [Фикстура.пункт, Фикстура.пункт, "intent-owned"]
        }
        #expect(try ф.ответ(коллизия).isEmpty)
        try изменитьКвитанциюV2(ф, &коллизия) { d in
            d["остаток"] = [Фикстура.пункт, "intent-owned", "intent-owned"]
        }
        блок(try ф.ответ(коллизия))
        try изменитьКвитанциюV2(ф, &неизвестный) { d in
            d["остаток"] = [Фикстура.пункт, "intent-owned"]
            d.removeValue(forKey: "ответственный")
        }
        блок(try ф.ответ(неизвестный))
    }

    @Test func boolОстановкиНеЗаменяетЯвноеЧеловеческоеУправлениеV2() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var снимок = ф.снимок()
        var наблюдения = try #require(снимок["наблюдения"] as? [String: Any])
        var условия = try #require(наблюдения["условия"] as? [String: Any])
        условия["остановкаЗадачи"] = true
        наблюдения["условия"] = условия
        снимок["наблюдения"] = наблюдения
        блок(try ф.ответ(снимок))
        for действие in ["стоп", "пауза"] {
            var явный = снимок
            явный["управление"] = [
                "действие": действие, "основание": "Явное указание человека"]
            let ответ = try ф.ответ(явный)
            #expect(ответ["continue"] as? Bool == false)
            #expect(ответ["decision"] == nil)
            #expect(ответ["stopReason"] != nil)
        }
    }
}
