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
    @Test func упакованнаяСсылкаПроходитПолныйОбработчик() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let снимок = try ф.завершённый()
        let обычный = ф.commonGitDir.appendingPathComponent(Фикстура.ref)
        let упакованный = ф.commonGitDir.appendingPathComponent("packed-refs")
        try FileManager.default.removeItem(at: обычный)
        try Фикстура.сохранить(Data(("# pack-refs with: peeled fully-peeled sorted \n"
            + ф.HEAD + " " + Фикстура.ref + "\n").utf8), в: упакованный, права: 0o644)
        #expect(try ф.ответ(снимок).isEmpty)
        try Фикстура.сохранить(Data((String(repeating: "e", count: 40) + " " + Фикстура.ref + "\n").utf8),
            в: упакованный, права: 0o644)
        try Фикстура.сохранить(Data((ф.HEAD + "\n").utf8), в: обычный, права: 0o644)
        #expect(try ф.ответ(снимок).isEmpty)
        try Фикстура.сохранить(Data("повреждено\n".utf8), в: обычный, права: 0o644)
        let ответ = try ф.ответ(снимок)
        #expect(ответ["decision"] as? String == "block")
        #expect((ответ["reason"] as? String)?.contains("формат") == true)
    }

}


@Suite("Файловые ссылки: общий конечный корпус", .serialized)
struct ПроверкиФайловыхСсылок {
    private struct Случай: Decodable {
        let имя: String
        let обычный: String?
        let упакованные: String?
        let типОбычного: String?
        let типУпакованного: String?
        let праваОбычного: Int?
        let праваКаталогаОбычного: Int?
        let праваУпакованного: Int?
        let увеличитьУпакованный: Int?
        let залитьУпакованныйПереносами: Int?
        let числоУпакованныхЗаписей: Int?
        let таблицыСсылок: Bool?
        let родительОбычногоСсылка: Bool?
        let результат: String?
        let источник: String?
        let изменение: String?
        let ошибка: String?
    }
    private struct Корпус: Decodable {
        let схема: String
        let ссылка: String
        let объект: String
        let другойОбъект: String
        let случаи: [Случай]
    }
    private static func сохранить(_ данные: Data, _ путь: URL, права: Int = 0o644) throws {
        try FileManager.default.createDirectory(at: путь.deletingLastPathComponent(),
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try данные.write(to: путь)
        try FileManager.default.setAttributes([.posixPermissions: права], ofItemAtPath: путь.path)
    }
    private static func узел(_ тип: String, данные: Data, путь: URL, права: Int) throws {
        guard тип != "нет" else { return }
        let родитель = путь.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: родитель,
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        switch тип {
        case "обычный": try сохранить(данные, путь, права: права)
        case "ссылка":
            let цель = родитель.appendingPathComponent("цель-" + UUID().uuidString)
            try сохранить(данные, цель)
            try FileManager.default.createSymbolicLink(at: путь, withDestinationURL: цель)
        case "оборванная-ссылка":
            try FileManager.default.createSymbolicLink(at: путь,
                withDestinationURL: родитель.appendingPathComponent("нет-цели"))
        case "каталог":
            try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        case "канал":
            guard Darwin.mkfifo(путь.path, 0o600) == 0 else { throw ОтказФайловойСсылки.метаданные }
        case "жёсткая-ссылка":
            try сохранить(данные, путь)
            try FileManager.default.linkItem(at: путь,
                to: родитель.appendingPathComponent("другая-связь-" + UUID().uuidString))
        default: throw ОтказФайловойСсылки.формат
        }
    }
    private static func заменить(_ данные: Data, _ путь: URL) throws {
        let новый = путь.deletingLastPathComponent().appendingPathComponent("замена-" + UUID().uuidString)
        try сохранить(данные, новый)
        guard Darwin.rename(новый.path, путь.path) == 0 else { throw ОтказФайловойСсылки.метаданные }
    }
    @Test func общийКорпусИКонечныеПодтверждения() throws {
        let среда = ProcessInfo.processInfo.environment
        let путьКорпуса = try #require(среда["ФУМ_ВЕКТОРЫ_ССЫЛОК"])
        let ожидаемыйХэш = try #require(среда["ФУМ_ХЭШ_ВЕКТОРОВ_ССЫЛОК"])
        let родитель = URL(fileURLWithPath: try #require(среда["ФУМ_ФИКСТУРЫ_ССЫЛОК"]))
        let данные = try Data(contentsOf: URL(fileURLWithPath: путьКорпуса))
        let хэш = SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
        try #require(хэш == ожидаемыйХэш)
        let корпус = try JSONDecoder().decode(Корпус.self, from: данные)
        try #require(корпус.схема == "фум.векторы-файловых-ссылок.1")
        try #require(корпус.случаи.count == 54)
        var проверено = 0
        for случай in корпус.случаи {
            let корень = родитель.appendingPathComponent(UUID().uuidString.lowercased())
            let общий = корень.appendingPathComponent("общее")
            try FileManager.default.createDirectory(at: общий, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
            let обычный = общий.appendingPathComponent(корпус.ссылка)
            let упакованный = общий.appendingPathComponent("packed-refs")
            let привязка = корень.appendingPathComponent("HEAD")
            let исходнаяПривязка = Data(("ref: " + корпус.ссылка + "\n").utf8)
            try Self.сохранить(исходнаяПривязка, привязка)
            let указательДерева = корень.appendingPathComponent(".git")
            let обратнаяСсылка = корень.appendingPathComponent("gitdir")
            let общийУказатель = корень.appendingPathComponent("commondir")
            for путь in [указательДерева, обратнаяСсылка, общийУказатель] {
                try Self.сохранить(Data("Синтетическая привязка\n".utf8), путь)
            }
            if случай.родительОбычногоСсылка == true {
                try FileManager.default.createSymbolicLink(at: общий.appendingPathComponent("refs"),
                    withDestinationURL: корень.appendingPathComponent("нет-каталога"))
            }
            try Self.узел(случай.типОбычного ?? (случай.обычный == nil ? "нет" : "обычный"),
                данные: Data((случай.обычный ?? "").utf8), путь: обычный, права: случай.праваОбычного ?? 0o644)
            var данныеУпакованного = Data((случай.упакованные ?? "").utf8)
            if let размер = случай.увеличитьУпакованный {
                try #require(размер == ЧитательФайловойСсылки.пределУпакованных + 1)
                данныеУпакованного = Data(repeating: 48, count: размер)
            }
            if let размер = случай.залитьУпакованныйПереносами {
                try #require(размер == ЧитательФайловойСсылки.пределУпакованных)
                данныеУпакованного = Data(repeating: 10, count: размер)
            }
            if let записей = случай.числоУпакованныхЗаписей {
                try #require(записей == 16_385)
                for номер in 1..<записей {
                    данныеУпакованного.append(Data((корпус.объект + " refs/x" + String(номер) + "\n").utf8))
                }
                try #require(данныеУпакованного.count <= ЧитательФайловойСсылки.пределУпакованных)
            }
            try Self.узел(случай.типУпакованного ?? (случай.упакованные == nil ? "нет" : "обычный"),
                данные: данныеУпакованного, путь: упакованный, права: случай.праваУпакованного ?? 0o644)
            if случай.таблицыСсылок == true {
                try FileManager.default.createDirectory(at: общий.appendingPathComponent("reftable"),
                    withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            }
            if let праваКаталога = случай.праваКаталогаОбычного {
                let каталог = обычный.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700])
                try FileManager.default.setAttributes([.posixPermissions: праваКаталога], ofItemAtPath: каталог.path)
            }
            var наблюдаемаяОшибка: String?
            do {
                let снимок = try ЧитательФайловойСсылки.прочитать(общийКаталог: общий.path,
                    ссылка: корпус.ссылка, связанныеФайлы: [привязка.path, указательДерева.path, обратнаяСсылка.path, общийУказатель.path])
                #expect(снимок.идентификаторОбъекта == случай.результат)
                #expect(снимок.источник.rawValue == случай.источник)
                if let изменение = случай.изменение {
                    switch изменение {
                    case "создать-обычный": try Self.сохранить(Data((корпус.объект + "\n").utf8), обычный)
                    case "создать-другой-обычный": try Self.сохранить(Data((корпус.другойОбъект + "\n").utf8), обычный)
                    case "изменить-обычный": try Self.сохранить(Data((корпус.другойОбъект + "\n").utf8), обычный)
                    case "изменить-упакованный":
                        try Self.сохранить(данныеУпакованного + Data((корпус.другойОбъект + " refs/tags/новая\n").utf8), упакованный)
                    case "заменить-упакованный": try Self.заменить(данныеУпакованного, упакованный)
                    case "изменить-привязку": try Self.сохранить(Data("ref: refs/heads/другая\n".utf8), привязка)
                    case "заменить-привязку": try Self.заменить(исходнаяПривязка, привязка)
                    case "изменить-указатель-дерева": try Self.сохранить(Data("Другая привязка\n".utf8), указательДерева)
                    case "изменить-обратную-ссылку": try Self.сохранить(Data("Другая привязка\n".utf8), обратнаяСсылка)
                    case "изменить-общий-указатель": try Self.сохранить(Data("Другая привязка\n".utf8), общийУказатель)
                    case "создать-каталог-ссылок":
                        try FileManager.default.createDirectory(at: общий.appendingPathComponent("refs"),
                            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
                    default: throw ОтказФайловойСсылки.формат
                    }
                }
                try снимок.подтвердить()
            } catch let отказ as ОтказФайловойСсылки {
                наблюдаемаяОшибка = отказ.rawValue
            } catch {
                Issue.record("Непредусмотренная ошибка случая \(случай.имя): \(error)")
            }
            if наблюдаемаяОшибка != случай.ошибка {
                Issue.record("Случай \(случай.имя): получено \(наблюдаемаяОшибка ?? "успех"), ожидалось \(случай.ошибка ?? "успех")")
            }
            #expect(наблюдаемаяОшибка == случай.ошибка)
            проверено += 1
        }
        #expect(проверено == 54)
    }
}

// Предложение V3; эти тесты не запускались. Реальный Native callback — отдельная проверка ROOT.
@Suite("Конечные продолжения V3", .serialized)
struct ПроверкиКонечныхПродолженийStop {
    // Только отдельный адресный запуск: stdin — общий дескриптор процесса.
    // Он остаётся занят дескриптором только для записи, а не закрывается для переиспользования.
    private func ответПриОтказеЧтенияВвода(_ аргументы: [String]) throws -> Data {
        let прежний = Darwin.dup(STDIN_FILENO)
        try #require(прежний >= 0)
        defer { _ = Darwin.close(прежний) }
        let толькоЗапись = Darwin.open("/dev/null", O_WRONLY | O_CLOEXEC | O_NOFOLLOW)
        try #require(толькоЗапись >= 0)
        defer { _ = Darwin.close(толькоЗапись) }
        try #require(Darwin.dup2(толькоЗапись, STDIN_FILENO) == STDIN_FILENO)
        defer { #expect(Darwin.dup2(прежний, STDIN_FILENO) == STDIN_FILENO) }
        // Настоящий одноаргументный вход: poll/read отказывает до Data-перегрузки.
        return КомандаStop.выполнить(аргументы)
    }

    @Test func отказЧтенияОбычногоВходаТретьейВерсииЯвноПриостанавливает() throws {
        let аргументы = ["--профиль-наблюдений", "fum.текущие-обязательства-stop.3"]
        let данные = try ответПриОтказеЧтенияВвода(аргументы)
        try пауза(данные)
        let ответ = try объект(данные)
        #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
        #expect((ответ["stopReason"] as? String)?.contains("отказ-чтения-ввода-V3") == true)
    }

    @Test func отказЧтенияОбычногоВходаПрежнейВерсииСохраняетДиагностику() throws {
        let ответ = try объектОтвета(ответПриОтказеЧтенияВвода([]))
        #expect(ответ["systemMessage"] is String)
        #expect(ответ["continue"] == nil)
        #expect(ответ["stopReason"] == nil)
        #expect(ответ["decision"] == nil)
    }

    @Test func неверныеАргументыТретьейВерсииЯвноПриостанавливают() throws {
        for аргументы in [
            ["--профиль-наблюдений", "fum.текущие-обязательства-stop.3"],
            ["--профиль-наблюдений", "fum.текущие-обязательства-stop.3", "--лишний", "значение"]
        ] {
            try пауза(КомандаStop.выполнить(аргументы, ввод: Data()))
        }
    }

    @Test func неверныеАргументыТретьейВерсииНеВыдаютЧужоеСобытиеЗаЗавершение() throws {
        let чужое = try событиеStop(задача: "00000000-0000-4000-8000-000000000480")
        let аргументы = ["--профиль-наблюдений", "fum.текущие-обязательства-stop.3"]
        // Неверные argv не доказывают адресность события: только техническая пауза UNKNOWN.
        let данные = КомандаStop.выполнить(аргументы, ввод: чужое)
        try пауза(данные)
        let ответ = try объект(данные)
        #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
        #expect((ответ["stopReason"] as? String)?.contains("управление не применено") == true)
    }

    @Test(arguments: ["разные", "жёсткая-ссылка", "символическая-ссылка",
        "родитель-ссылка", "родитель-доступен-группе"])
    func физическоеРазделениеСохраняетПрежниеБайты(_ вид: String) throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-state-separation-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let прежнее = корень.appendingPathComponent("current-v2.json")
        let каталог = корень.appendingPathComponent("v3", isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        var новое = каталог.appendingPathComponent("current-v3.json")
        let байты = Data("Прежний V2 current сохраняется побайтно\n".utf8)
        try байты.write(to: прежнее)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: прежнее.path)
        switch вид {
        case "жёсткая-ссылка": try FileManager.default.linkItem(at: прежнее, to: новое)
        case "символическая-ссылка":
            try FileManager.default.createSymbolicLink(at: новое, withDestinationURL: прежнее)
        default:
            try Data("Отдельный V3 current\n".utf8).write(to: новое)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: новое.path)
            if вид == "родитель-ссылка" {
                let ссылка = корень.appendingPathComponent("v3-alias", isDirectory: true)
                try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: каталог)
                новое = ссылка.appendingPathComponent("current-v3.json")
            } else if вид == "родитель-доступен-группе" {
                try FileManager.default.setAttributes([.posixPermissions: 0o770], ofItemAtPath: каталог.path)
            }
        }
        var до = stat(); try #require(lstat(прежнее.path, &до) == 0)
        if вид == "разные" {
            try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
                состояниеV2: прежнее.path, состояниеV3: новое.path).подтвердить()
        } else {
            #expect(throws: (any Error).self) {
                _ = try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
                    состояниеV2: прежнее.path, состояниеV3: новое.path)
            }
        }
        var после = stat(); try #require(lstat(прежнее.path, &после) == 0)
        #expect(try Data(contentsOf: прежнее) == байты)
        #expect(до.st_dev == после.st_dev && до.st_ino == после.st_ino
            && до.st_nlink == после.st_nlink && до.st_mode == после.st_mode
            && до.st_size == после.st_size
            && до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec
            && до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec
            && до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec
            && до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec)
    }

    @Test func отсутствиеНовогоСостоянияПодтверждаетсяДоПубликации() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-state-absence-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let прежнее = корень.appendingPathComponent("current-v2.json")
        let новое = корень.appendingPathComponent("current-v3.json")
        let байты = Data("Прежний current\n".utf8)
        try байты.write(to: прежнее)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: прежнее.path)
        #expect(throws: (any Error).self) {
            _ = try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
                состояниеV2: прежнее.path, состояниеV3: новое.path)
        }
        let снимок = try ЧитательФайловойСсылки.проверитьРазделениеСостояний(
            состояниеV2: прежнее.path, состояниеV3: новое.path, допускаетсяОтсутствиеV3: true)
        try снимок.подтвердить()
        try Data("Позднее создание\n".utf8).write(to: новое)
        #expect(throws: (any Error).self) { try снимок.подтвердить() }
        #expect(try Data(contentsOf: прежнее) == байты)
    }

    private let эпоха = "00000000-0000-4000-8000-000000000301"
    private let операция = "00000000-0000-4000-8000-000000000302"
    private let новаяОперация = "00000000-0000-4000-8000-000000000303"

    private func поля() -> [String: Any] {
        ["схема": "fum.stop-допуск-продолжения.1", "задача": задачаStop,
         "узел": узелStop, "область": "fixture-v3", "поколение": "fixture-epoch",
         "исходники": String(repeating: "a", count: 40), "эпоха": эпоха,
         "операция": операция, "вид": "безопасный-шаг", "пункт": "item-1",
         "следующаяРабота": "Проверить один адресный результат",
         "корневойДопускSHA256": String(repeating: "c", count: 64),
         "наблюдениеSHA256": String(repeating: "a", count: 64),
         "редакция": 7, "номер": 0, "выдан": 0, "действуетДо": 200,
         "каталогЗахватов": "/private/tmp/не-используется-чистыми-тестами",
         "устройствоКаталога": 1, "inodeКаталога": 2]
    }
    private func допуск(_ p: [String: Any]) throws -> КонечноеПродолжениеStop.Допуск {
        try JSONDecoder().decode(КонечноеПродолжениеStop.Допуск.self,
            from: JSONSerialization.data(withJSONObject: p))
    }
    private func контекст(ход: String = "turn-1", hash: String? = nil) -> КонечноеПродолжениеStop.Контекст {
        .init(задача: задачаStop, узел: узелStop, область: "fixture-v3", поколение: "fixture-epoch",
            исходники: String(repeating: "a", count: 40), заголовокSHA256: String(repeating: "b", count: 64),
            наблюдениеSHA256: hash ?? String(repeating: "a", count: 64),
            полныйСнимокSHA256: String(repeating: "f", count: 64), редакция: 7, ход: ход, сейчас: 100)
    }
    private func объект(_ bytes: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    }
    private func пауза(_ bytes: Data) throws {
        let p = try объект(bytes)
        #expect(p["continue"] as? Bool == false)
        #expect(p["decision"] == nil)
        #expect((p["stopReason"] as? String)?.contains("задача не завершена") == true)
    }

    @Test func одинСигналИПовторДругогоTurnНеПеревыдаётToken() throws {
        let d = try допуск(поля()); var занят = false; var emissions = 0
        for ход in ["turn-1", "turn-2"] {
            let data = КонечноеПродолжениеStop.ответ(d, контекст(ход: ход),
                повод: .безопасныйШаг(d.следующаяРабота), проверитьПрогресс: { Issue.record("номер0 не читает progress") },
                захват: { _ in
                    if занят { return .ужеЗанят }; занят = true; return .создан
                })
            if try объект(data)["decision"] as? String == "block" { emissions += 1 }
            else { try пауза(data) }
        }
        #expect(emissions == 1)
    }

    @Test func новыйOperationИHashНеПереоткрываютEpochOrdinal() throws {
        var p = поля(); let first = try допуск(p)
        p["операция"] = новаяОперация; p["наблюдениеSHA256"] = String(repeating: "d", count: 64)
        let next = try допуск(p)
        #expect(try КонечноеПродолжениеStop.имяЗахвата(first.эпоха, номер: first.номер)
            == КонечноеПродолжениеStop.имяЗахвата(next.эпоха, номер: next.номер))
        let data = КонечноеПродолжениеStop.ответ(next,
            контекст(ход: "new-turn", hash: String(repeating: "d", count: 64)),
            повод: .безопасныйШаг(next.следующаяРабота), проверитьПрогресс: {}, захват: { _ in .ужеЗанят })
        try пауза(data)
    }

    @Test func неизвестныйClaimНеВыпускаетСигнал() throws {
        let d = try допуск(поля()); var claims = 0
        let first = КонечноеПродолжениеStop.ответ(d, контекст(), повод: .безопасныйШаг(d.следующаяРабота),
            проверитьПрогресс: {}, захват: { _ in claims += 1; throw КонечноеПродолжениеStop.Отказ.синхронизация })
        try пауза(first)
        let next = КонечноеПродолжениеStop.ответ(d, контекст(ход: "retry"),
            повод: .безопасныйШаг(d.следующаяРабота), проверитьПрогресс: {}, захват: { _ in .ужеЗанят })
        try пауза(next); #expect(claims == 1)
    }

    @Test func staleТребуетОтдельногоRepairВида() throws {
        var p = поля(); let d = try допуск(p); var claims = 0
        try пауза(КонечноеПродолжениеStop.ответ(d, контекст(), повод: .устаревший,
            проверитьПрогресс: {}, захват: { _ in claims += 1; return .создан }))
        #expect(claims == 0)
        p["вид"] = "обновить-просроченный-снимок"; let repair = try допуск(p)
        let result = КонечноеПродолжениеStop.ответ(repair, контекст(), повод: .устаревший,
            проверитьПрогресс: {}, захват: { _ in claims += 1; return .создан })
        #expect(try объект(result)["decision"] as? String == "block"); #expect(claims == 1)
    }

    @Test func следующаяОперацияБезПринятогоProgressНеПолучаетClaim() throws {
        var p = поля(); p["номер"] = 1; p["операция"] = новаяОперация; p["предыдущаяОперация"] = операция
        p["прогресс"] = ["путь": "progress.json", "sha256": String(repeating: "e", count: 64)]
        let d = try допуск(p); var claims = 0
        let result = КонечноеПродолжениеStop.ответ(d, контекст(), повод: .безопасныйШаг(d.следующаяРабота),
            проверитьПрогресс: { throw КонечноеПродолжениеStop.Отказ.прогресс },
            захват: { _ in claims += 1; return .создан })
        try пауза(result); #expect(claims == 0)
    }

    @Test func границыВерсииСрокаSourceИРедакцииДоПобочногоЭффекта() throws {
        let повреждения: [(String, Any)] = [("схема", "fum.stop-допуск-продолжения.2"),
            ("номер", 129), ("выдан", 101), ("действуетДо", 99), ("редакция", 8),
            ("исходники", String(repeating: "f", count: 40))]
        for (key, value) in повреждения {
            var p = поля(); p[key] = value; let d = try допуск(p); var claims = 0
            try пауза(КонечноеПродолжениеStop.ответ(d, контекст(), повод: .безопасныйШаг(d.следующаяРабота),
                проверитьПрогресс: {}, захват: { _ in claims += 1; return .создан }))
            #expect(claims == 0)
        }
    }

    @Test func progressСвязываетClaimНовыйRootGrantИИсходШага() throws {
        let initial = try допуск(поля()); var rawClaim = Data()
        _ = КонечноеПродолжениеStop.ответ(initial, контекст(), повод: .безопасныйШаг(initial.следующаяРабота),
            проверитьПрогресс: {}, захват: { bytes in rawClaim = bytes; return .создан })
        let claim = try JSONDecoder().decode(КонечноеПродолжениеStop.Квитанция.self, from: rawClaim)
        let hash = SHA256.hash(data: rawClaim).map { String(format: "%02x", $0) }.joined()
        var p = поля(); p["номер"] = 1; p["операция"] = новаяОперация; p["предыдущаяОперация"] = операция
        p["корневойДопускSHA256"] = String(repeating: "e", count: 64)
        p["наблюдениеSHA256"] = String(repeating: "d", count: 64)
        p["прогресс"] = ["путь": "progress.json", "sha256": String(repeating: "f", count: 64)]
        let d = try допуск(p)
        var receipt: [String: Any] = ["схема": "fum.stop-принятый-прогресс.1",
            "задача": d.задача, "узел": d.узел, "область": d.область, "поколение": d.поколение,
            "исходники": d.исходники, "эпоха": d.эпоха, "предыдущаяОперация": операция,
            "следующаяОперация": новаяОперация, "предыдущийЗахватSHA256": hash,
            "предыдущееНаблюдениеSHA256": claim.наблюдениеSHA256,
            "новоеНаблюдениеSHA256": d.наблюдениеSHA256, "корневойДопускSHA256": d.корневойДопускSHA256,
            "исход": "шаг-выполнен-и-принят",
            "результат": ["путь": "operation-result.json", "sha256": String(repeating: "b", count: 64)]]
        func decode() throws -> КонечноеПродолжениеStop.Прогресс {
            try JSONDecoder().decode(КонечноеПродолжениеStop.Прогресс.self,
                from: JSONSerialization.data(withJSONObject: receipt))
        }
        try КонечноеПродолжениеStop.проверитьПрогресс(decode(), прежнийSHA256: hash, claim, d)
        receipt["исход"] = "прогресс-не-принят"
        #expect(throws: (any Error).self) {
            try КонечноеПродолжениеStop.проверитьПрогресс(decode(), прежнийSHA256: hash, claim, d)
        }
    }

    @Test func проекцияНеЗависитОтHeaderTimeRevisionИОперации() throws {
        let observations = НаблюденияStop(задача: задачаStop, узел: узелStop,
            следующаяРабота: "Один проверенный шаг", условия: обычныеУсловияStop())
        var state: [String: Any] = ["cwd": рабочийКаталогStop, "дерево": рабочийКаталогStop,
            "ref": "refs/heads/fixture", "HEAD": String(repeating: "a", count: 40),
            "выпущен": 1, "действуетДо": 2, "редакция": 1,
            "заголовокSHA256": String(repeating: "a", count: 64),
            "эпохаПродолжения": эпоха, "операцияПродолжения": операция,
            "пункты": [["id": "item-1", "область": "fixture-v3", "состояние": "доступен",
                "уровень": "исходники", "основание": "Синтетический проверочный шаг"]],
            "неизвестныеНамерения": [],
            "наблюдения": try JSONSerialization.jsonObject(with: JSONEncoder().encode(observations))]
        func basis() throws -> String {
            try КомандаStop.основаниеСнимкаV3(JSONSerialization.data(withJSONObject: state))
        }
        let first = try basis()
        state["заголовокSHA256"] = String(repeating: "b", count: 64)
        state["выпущен"] = 100; state["действуетДо"] = 200; state["редакция"] = 2
        state["операцияПродолжения"] = новаяОперация
        #expect(try basis() == first)
        state["HEAD"] = String(repeating: "c", count: 40)
        #expect(try basis() != first)
    }

    @Test func crashПослеExclusiveCreateСохраняетЗанятыйSlot() throws {
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-v3-claim-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: parent) }
        let resolved = try #require(parent.path.withCString { Darwin.realpath($0, nil) })
        defer { Darwin.free(resolved) }
        // Строка realpath сохраняется без повторного преобразования URL перед nofollow-reader.
        let physicalParent = String(cString: resolved)
        var st = stat(); try #require(lstat(physicalParent, &st) == 0)
        var p = поля(); let now = Int64(Date().timeIntervalSince1970)
        p["каталогЗахватов"] = physicalParent; p["устройствоКаталога"] = UInt64(st.st_dev)
        p["inodeКаталога"] = UInt64(st.st_ino); p["выдан"] = now - 1; p["действуетДо"] = now + 60
        let d = try допуск(p); var points = КонечноеПродолжениеStop.ТочкиЗахвата()
        enum ВнедрённыйОтказ: Error { case послеСоздания }
        var достигнутаТочкаСоздания = false
        var пойманВнедрённыйОтказ = false
        points.послеСоздания = {
            достигнутаТочкаСоздания = true
            throw ВнедрённыйОтказ.послеСоздания
        }
        do {
            _ = try КонечноеПродолжениеStop.захватить(d, Data("claim\n".utf8), точки: points, подтвердить: {})
            Issue.record("Ожидался внедрённый отказ после создания claim")
        } catch ВнедрённыйОтказ.послеСоздания {
            пойманВнедрённыйОтказ = true
        } catch {
            Issue.record("Получен иной отказ вместо инъекции после создания claim: \(error)")
            throw error
        }
        try #require(достигнутаТочкаСоздания)
        try #require(пойманВнедрённыйОтказ)
        let path = physicalParent + "/"
            + (try КонечноеПродолжениеStop.имяЗахвата(d.эпоха, номер: 0))
        let before = try #require(FileManager.default.contents(atPath: path))
        let again = try КонечноеПродолжениеStop.захватить(d, Data("different\n".utf8), подтвердить: {})
        if case .создан = again { Issue.record("partial claim нельзя переоткрывать") }
        #expect(FileManager.default.contents(atPath: path) == before)
    }
}

import Foundation
import Darwin
import CryptoKit
import Testing
import МатериализацияУзлов
import FUMStructuringOperatorMemory

private enum ОшибкаЯкорногоСтенда: Error { case метаданные, запись }

private struct СинтетическийЯкорь: Sendable {
    static let корневойUUID = "00000000-0000-4000-8000-000000000478"
    static let задача = "00000000-0000-4000-8000-000000000479"
    static let узел = "fum-lab/fum/master"
    static let область = "isolated-stable-anchor"
    static let поколение = "isolated-anchor-generation-1"
    static let исходники = String(repeating: "6", count: 40)
    static let эпоха = "00000000-0000-4000-8000-000000000531"
    static let операция = "00000000-0000-4000-8000-000000000532"
    static let шаг = "Проверить один адресный синтетический результат"
    let корень: URL
    let нативныйКаталог: URL
    let дерево: URL
    let заголовок: URL
    let указатель: URL
    let захваты: URL
    let староеV2: URL
    let староеV3: URL
    let хэшЗаголовка: String
    let хэшДопуска: String
    let хэшСнимка: String
    let голова: String
    let исходныйДопуск, исходныйСнимок: Data

    static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
    static func кодироватьОбъект(_ объект: Any) throws -> Data {
        let промежуточные = try JSONSerialization.data(withJSONObject: объект,
            options: [.withoutEscapingSlashes])
        let значение = try JSONDecoder().decode(ЗначениеJSONЯкорногоСтенда.self, from: промежуточные)
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение)
        данные.append(10)
        return данные
    }
    static func сохранить(_ данные: Data, _ путь: URL, права: Int) throws {
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: права], ofItemAtPath: путь.path)
        let файл = try FileHandle(forReadingFrom: путь)
        defer { try? файл.close() }
        guard Darwin.fsync(файл.fileDescriptor) == 0 else { throw ОшибкаЯкорногоСтенда.запись }
        let родитель = Darwin.open(путь.deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard родитель >= 0 else { throw ОшибкаЯкорногоСтенда.запись }
        defer { Darwin.close(родитель) }
        guard Darwin.fsync(родитель) == 0 else { throw ОшибкаЯкорногоСтенда.запись }
    }
    static func привязка(_ путь: URL) throws -> [String: Any] {
        var сведения = stat()
        guard lstat(путь.path, &сведения) == 0,
              сведения.st_mode & S_IFMT == S_IFDIR,
              сведения.st_uid == geteuid(), сведения.st_mode & 0o777 == 0o700
        else { throw ОшибкаЯкорногоСтенда.метаданные }
        return ["путь": путь.path, "устройство": UInt64(сведения.st_dev),
            "индексныйУзел": UInt64(сведения.st_ino)]
    }

    init(основание: URL, публиковатьНачальный: Bool = true, срокПервогоLeaseСекунд: Int64 = 300) throws {
        корень = основание.appendingPathComponent(UUID().uuidString.lowercased())
        нативныйКаталог = корень.appendingPathComponent("native")
        дерево = корень.appendingPathComponent("writing")
        заголовок = корень.appendingPathComponent("anchor-v4.json")
        указатель = корень.appendingPathComponent("root-grant.json")
        захваты = корень.appendingPathComponent("claims")
        староеV2 = корень.appendingPathComponent("legacy-v2.json")
        староеV3 = корень.appendingPathComponent("legacy-v3.json")
        let каталогХранилища = корень.appendingPathComponent("git")
        let общийКаталогХранилища = корень.appendingPathComponent("common")
        let снимки = корень.appendingPathComponent("snapshots")
        let принятые = корень.appendingPathComponent("adoptions")
        let квитанции = корень.appendingPathComponent("receipts")
        for каталог in [корень, нативныйКаталог, дерево, каталогХранилища, общийКаталогХранилища,
            общийКаталогХранилища.appendingPathComponent("refs"),
            общийКаталогХранилища.appendingPathComponent("refs/heads"),
            общийКаталогХранилища.appendingPathComponent("refs/heads/fum-lab"),
            общийКаталогХранилища.appendingPathComponent("refs/heads/fum-lab/fum"),
            снимки, принятые, квитанции, захваты] {
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        let сыройКоммит = Data(("tree " + String(repeating: "1", count: 40)
            + "\nparent " + String(repeating: "2", count: 40)
            + "\nauthor Unit <unit@example.invalid> 1700000000 +0000"
            + "\ncommitter Unit <unit@example.invalid> 1700000000 +0000\n\nsynthetic anchor\n").utf8)
        var объект = Data("commit \(сыройКоммит.count)\0".utf8)
        объект.append(сыройКоммит)
        голова = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
        for (путь, строка) in [
            (дерево.appendingPathComponent(".git"), "gitdir: \(каталогХранилища.path)\n"),
            (каталогХранилища.appendingPathComponent("gitdir"), "\(дерево.path)/.git\n"),
            (каталогХранилища.appendingPathComponent("commondir"), "\(общийКаталогХранилища.path)\n"),
            (каталогХранилища.appendingPathComponent("HEAD"), "ref: refs/heads/fum-lab/fum/master\n"),
            (общийКаталогХранилища.appendingPathComponent("refs/heads/fum-lab/fum/master"), "\(голова)\n")] {
            try Self.сохранить(Data(строка.utf8), путь, права: 0o644)
        }
        try Self.сохранить(Data("retained synthetic V2\n".utf8), староеV2, права: 0o600)
        try Self.сохранить(Data("retained synthetic V3\n".utf8), староеV3, права: 0o600)
        let замок = корень.appendingPathComponent("root-grant.json.lock")
        try Self.сохранить(Data(), замок, права: 0o600)
        var сведенияЗамка = stat()
        guard lstat(замок.path, &сведенияЗамка) == 0 else { throw ОшибкаЯкорногоСтенда.метаданные }
        // Только тестовый известный ключ; это никогда не ROOT production key.
        let закрытыйКлюч = try Curve25519.Signing.PrivateKey(rawRepresentation: Data(repeating: 0x42, count: 32))
        let открытыйКлюч = закрытыйКлюч.publicKey.rawRepresentation
        let ключSHA = Self.хэш(открытыйКлюч)
        let принятиеКлюча = try Self.кодироватьОбъект([
            "схема": "fum.принятие-корневого-ключа.1", "корень": Self.корневойUUID,
            "задача": Self.задача, "узел": Self.узел, "область": Self.область,
            "поколение": Self.поколение, "исходники": Self.исходники,
            "ключROOTBase64": открытыйКлюч.base64EncodedString(), "ключROOTSHA256": ключSHA,
            "эпоха": Self.эпоха, "пределПолномочий": "synthetic test-only finite grant"])
        let принятиеSHA = Self.хэш(принятиеКлюча)
        try Self.сохранить(принятиеКлюча, корень.appendingPathComponent("key-adoption.json"), права: 0o400)
        let данныеЗаголовка = try Self.кодироватьОбъект([
            "схема": "fum.stop-заголовок.4", "корень": Self.корневойUUID,
            "задача": Self.задача, "узел": Self.узел, "область": Self.область,
            "поколение": Self.поколение, "cwd": нативныйКаталог.path, "дерево": дерево.path,
            "ref": "refs/heads/fum-lab/fum/master", "gitDir": каталогХранилища.path,
            "commonGitDir": общийКаталогХранилища.path, "backend": "files", "objectFormat": "sha1",
            "исходники": Self.исходники, "состояние": указатель.path,
            "состояниеV2": староеV2.path, "состояниеV3": староеV3.path,
            "каталогСнимков": Self.привязка(снимки),
            "каталогПринятыхДопусков": Self.привязка(принятые),
            "каталогЗахватов": Self.привязка(захваты),
            "каталогКвитанций": Self.привязка(квитанции),
            "замок": ["path": замок.path, "device": Int64(сведенияЗамка.st_dev),
                "inode": UInt64(сведенияЗамка.st_ino)],
            "ключROOTBase64": открытыйКлюч.base64EncodedString(), "ключROOTSHA256": ключSHA,
            "принятиеКлючаSHA256": принятиеSHA, "эпоха": Self.эпоха,
            "максимальныйВозрастСекунд": 900, "максимальныйLeaseСекунд": 3600,
            "максимальныйНомер": 128, "максимальнаяПубликация": 128] as [String: Any])
        хэшЗаголовка = Self.хэш(данныеЗаголовка)
        try Self.сохранить(данныеЗаголовка, заголовок, права: 0o400)
        let сейчас = Int64(Date().timeIntervalSince1970)
        let условия = УсловияСамостоятельности(свояОбласть: true, естьПолномочия: true,
            неизвестныйОпасныйЭффект: false, естьНакопленноеПродвижение: true,
            можноБезопасноПродолжать: true, доступнаНезависимаяРабота: true,
            локальнаяИсправимаяПроблема: false, остановкаЗадачи: false,
            естьБезопасныйСледующийШаг: true)
        let наблюдения = НаблюденияStop(задача: Self.задача, узел: Self.узел,
            следующаяРабота: Self.шаг, условия: условия)
        let объектНаблюдений = try JSONSerialization.jsonObject(with: JSONEncoder().encode(наблюдения))
        let снимок = try Self.кодироватьОбъект([
            "схема": "fum.текущие-обязательства-stop.4", "редакция": 7,
            "эпохаПродолжения": Self.эпоха, "операцияПродолжения": Self.операция,
            "заголовокSHA256": хэшЗаголовка, "задача": Self.задача, "узел": Self.узел,
            "область": Self.область, "поколение": Self.поколение,
            "cwd": нативныйКаталог.path, "дерево": дерево.path, "ref": "refs/heads/fum-lab/fum/master",
            "HEAD": голова, "выпущен": сейчас - 5, "действуетДо": сейчас + 600,
            "управление": ["действие": "продолжать", "основание": "Synthetic signed fixture"],
            "пункты": [["id": "repair-stop-unit", "область": Self.область,
                "состояние": "доступен", "уровень": "исходники", "основание": "Synthetic current item"]],
            "неизвестныеНамерения": [], "наблюдения": объектНаблюдений] as [String: Any])
        хэшСнимка = Self.хэш(снимок)
        исходныйСнимок = снимок
        let проектSHA = try КомандаStop.основаниеСнимкаV3(снимок)
        if публиковатьНачальный {
            try Self.сохранить(снимок, снимки.appendingPathComponent(хэшСнимка + ".json"), права: 0o400)
        }
        let корневоеРешение = try Self.кодироватьОбъект(["схема": "fum.synthetic-root-decision.1",
            "корень": Self.корневойUUID, "задача": Self.задача, "HEAD": голова,
            "наблюдениеSHA256": проектSHA, "публикация": 0, "номер": 0] as [String: Any])
        try Self.сохранить(корневоеРешение, корень.appendingPathComponent("root-decision.json"), права: 0o400)
        let нагрузка = try Self.кодироватьОбъект([
            "схема": "fum.stop-root-допуск.1", "корень": Self.корневойUUID,
            "принятиеКлючаSHA256": принятиеSHA, "заголовокSHA256": хэшЗаголовка,
            "задача": Self.задача, "узел": Self.узел, "область": Self.область,
            "поколение": Self.поколение, "исходники": Self.исходники,
            "публикация": 0, "HEAD": голова, "наблюдениеSHA256": проектSHA,
            "снимокSHA256": хэшСнимка, "снимокИмя": хэшСнимка + ".json",
            "эпоха": Self.эпоха, "операция": Self.операция, "номер": 0, "редакция": 7,
            "выдан": сейчас - 5, "действуетДо": сейчас + срокПервогоLeaseСекунд,
            "корневойДопускSHA256": Self.хэш(корневоеРешение), "вид": "безопасный-шаг",
            "пункт": "repair-stop-unit", "следующаяРабота": Self.шаг] as [String: Any])
        var сообщение = Data("FUM-STOP-ROOT-GRANT-v1".utf8)
        сообщение.append(0)
        сообщение.append(нагрузка)
        let подпись = try закрытыйКлюч.signature(for: сообщение)
        let допуск = try Self.кодироватьОбъект(["схема": "fum.stop-подписанный-root-допуск.1",
            "ключROOTSHA256": ключSHA, "полезнаяНагрузкаBase64": нагрузка.base64EncodedString(),
            "подписьBase64": подпись.base64EncodedString()])
        хэшДопуска = Self.хэш(допуск)
        исходныйДопуск = допуск
        if публиковатьНачальный {
            try Self.сохранить(допуск, принятые.appendingPathComponent("0.допуск.json"), права: 0o400)
            try Self.сохранить(допуск, указатель, права: 0o600)
        }
        // Терминальный признак создаётся лишь после сохранённого указателя.
        let завершение = try Self.кодироватьОбъект([
            "схема": "fum.stop-завершение-публикации.1",
            "заголовокSHA256": хэшЗаголовка, "публикация": 0,
            "допускSHA256": хэшДопуска, "снимокSHA256": хэшСнимка,
            "указательSHA256": хэшДопуска] as [String: Any])
        if публиковатьНачальный {
            try Self.сохранить(завершение,
                принятые.appendingPathComponent("0.завершение.json"), права: 0o400)
        }
    }
    var аргументы: [String] {
        ["--идентификатор-обработчика", "fum.stop-handler.1",
         "--codex-thread-id", Self.задача, "--идентификатор-узла", Self.узел,
         "--ожидаемый-cwd", нативныйКаталог.path, "--состояние", указатель.path,
         "--профиль-наблюдений", "fum.текущие-обязательства-stop.4",
         "--заголовок", заголовок.path, "--хэш-заголовка", хэшЗаголовка]
    }
    func событие() throws -> Data {
        try Self.кодироватьОбъект(["session_id": Self.задача, "hook_event_name": "Stop",
            "cwd": нативныйКаталог.path, "turn_id": "anchor-v4-turn-1", "stop_hook_active": false])
    }
}

@Suite("Стабильный якорь и подписанный ROOT-допуск", .serialized)
struct ПроверкиСтабильногоЯкоря {
    @Test("K01: подписанный начальный допуск даёт один захват через стабильную команду")
    func первоеПродолжениеСПостояннойКомандой() throws {
        let значение = ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"]
        let путь = try #require(значение)
        let ф = try СинтетическийЯкорь(основание: URL(fileURLWithPath: путь))
        let заголовокДо = try Data(contentsOf: ф.заголовок)
        let командаДо = ф.аргументы
        let v2До = try Data(contentsOf: ф.староеV2)
        let v3До = try Data(contentsOf: ф.староеV3)
        let маркер = ф.корень.appendingPathComponent("adoptions/0.завершение.json")
        let маркерДо = try Data(contentsOf: маркер)
        let указательДо = try Data(contentsOf: ф.указатель)
        let ответ = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        try СинтетическийЯкорь.сохранить(ответ,
            ф.корень.appendingPathComponent("actual-response.raw"), права: 0o600)
        let ожидаемый = try СинтетическийЯкорь.кодироватьОбъект(["decision": "block", "reason":
            "FUM Stop V4: один сигнал по операции \(СинтетическийЯкорь.операция). \(СинтетическийЯкорь.шаг). Не расширяй допуск; представь точный исход ROOT. Повтор без принятого прогресса не разрешён."])
        #expect(ответ == ожидаемый)
        let имя = СинтетическийЯкорь.эпоха + ".0.claim"
        let имена = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
        #expect(имена == [имя])
        let естьЗахват = FileManager.default.fileExists(atPath: ф.захваты.appendingPathComponent(имя).path)
        if естьЗахват {
            let захват = try Data(contentsOf: ф.захваты.appendingPathComponent(имя))
            let данные = try JSONSerialization.jsonObject(with: захват) as? [String: Any]
            let объект = try #require(данные)
            #expect(объект["схема"] as? String == "fum.stop-захват-продолжения.2")
            #expect(объект["подписанныйДопускSHA256"] as? String == ф.хэшДопуска)
            #expect(объект["заголовокSHA256"] as? String == ф.хэшЗаголовка)
            #expect(объект["полныйСнимокSHA256"] as? String == ф.хэшСнимка)
            var сведения = stat()
            let прочитан = lstat(ф.захваты.appendingPathComponent(имя).path, &сведения)
            #expect(прочитан == 0 && сведения.st_mode & S_IFMT == S_IFREG
                && сведения.st_mode & 0o777 == 0o400 && сведения.st_uid == geteuid()
                && сведения.st_nlink == 1)
        }
        #expect(try Data(contentsOf: ф.заголовок) == заголовокДо)
        #expect(ф.аргументы == командаДо)
        #expect(try Data(contentsOf: ф.староеV2) == v2До)
        #expect(try Data(contentsOf: ф.староеV3) == v3До)
        #expect(try Data(contentsOf: маркер) == маркерДо)
        #expect(try Data(contentsOf: ф.указатель) == указательДо)
    }
}

private indirect enum ЗначениеJSONЯкорногоСтенда: Codable {
    case объект([String: ЗначениеJSONЯкорногоСтенда])
    case массив([ЗначениеJSONЯкорногоСтенда])
    case строка(String), булево(Bool), целое(Int64), большоеЦелое(UInt64), пусто
    init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .пусто }
        else if let v = try? c.decode([String: Self].self) { self = .объект(v) }
        else if let v = try? c.decode([Self].self) { self = .массив(v) }
        else if let v = try? c.decode(String.self) { self = .строка(v) }
        else if let v = try? c.decode(Bool.self) { self = .булево(v) }
        else if let v = try? c.decode(Int64.self) { self = .целое(v) }
        else if let v = try? c.decode(UInt64.self) { self = .большоеЦелое(v) }
        else { throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported test JSON value") }
    }
    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .объект(let v): try c.encode(v)
        case .массив(let v): try c.encode(v)
        case .строка(let v): try c.encode(v)
        case .булево(let v): try c.encode(v)
        case .целое(let v): try c.encode(v)
        case .большоеЦелое(let v): try c.encode(v)
        case .пусто: try c.encodeNil()
        }
    }
}

import УстановкаStop

private extension СинтетическийЯкорь {
    static func новаяФикстура() throws -> Self {
        let путь = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        return try Self(основание: URL(fileURLWithPath: путь))
    }
    static func объект(_ данные: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
    }
    static func подписатьТестовуюНагрузку(_ данные: Data, ключSHA: String) throws -> Data {
        let ключ = try Curve25519.Signing.PrivateKey(rawRepresentation: Data(repeating: 0x42, count: 32))
        var сообщение = Data("FUM-STOP-ROOT-GRANT-v1".utf8)
        сообщение.append(0); сообщение.append(данные)
        return try кодироватьОбъект(["схема": "fum.stop-подписанный-root-допуск.1",
            "ключROOTSHA256": ключSHA, "полезнаяНагрузкаBase64": данные.base64EncodedString(),
            "подписьBase64": ключ.signature(for: сообщение).base64EncodedString()])
    }
    static func отказ(_ действие: () throws -> Void) -> Bool {
        do { try действие(); return false } catch { return true }
    }
    static func ответБлокирует(_ данные: Data) throws -> Bool {
        try объект(данные)["decision"] as? String == "block"
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K02 negative: смена HEAD без нового подписанного допуска не даёт захват")
    func сменаHEADБезДопускаНеПродолжает() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        let команда = ф.аргументы, заголовок = try Data(contentsOf: ф.заголовок)
        let ref = ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master")
        try СинтетическийЯкорь.сохранить(try Data(contentsOf: ref),
            ф.корень.appendingPathComponent("retained-before-head.raw"), права: 0o400)
        try Data((String(repeating: "b", count: 40) + "\n").utf8).write(to: ref)
        let ответ = КомандаStop.выполнить(команда, ввод: try ф.событие())
        #expect(try !СинтетическийЯкорь.ответБлокирует(ответ))
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
        #expect(ф.аргументы == команда)
        #expect(try Data(contentsOf: ф.заголовок) == заголовок)
    }
    @Test("K07: повтор того же epoch.ordinal не выдаёт второй захват")
    func повторТогоЖеНомераНеДаётВторойЗахват() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        let первый = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let первыйБлокирует = try СинтетическийЯкорь.ответБлокирует(первый)
        try #require(первыйБлокирует)
        let файл = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
        let до = try Data(contentsOf: файл)
        let второй = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        #expect(try !СинтетическийЯкорь.ответБлокирует(второй))
        #expect(try Data(contentsOf: файл) == до)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path) == [файл.lastPathComponent])
    }
    @Test("K16 pure: предел ровно 128 и signed identity/key не заменяются")
    func чистыеГраницыЗаголовкаИПодписаннойИдентичности() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        let байты = try Data(contentsOf: ф.заголовок)
        let заголовок = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: байты, предел: 32_768)
        try КорневойДопускStopV4.проверитьЗаголовок(заголовок)
        for ключ in ["максимальныйНомер", "максимальнаяПубликация"] {
            for значение in [0, 127, 129] {
                var объект = try СинтетическийЯкорь.объект(байты); объект[ключ] = значение
                let изменённый = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
                    из: СинтетическийЯкорь.кодироватьОбъект(объект), предел: 32_768)
                #expect(СинтетическийЯкорь.отказ { try КорневойДопускStopV4.проверитьЗаголовок(изменённый) })
            }
        }
        let конверт = try Data(contentsOf: ф.указатель)
        let исходный = try КорневойДопускStopV4.проверитьКонверт(конверт,
            заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
        for (ключ, значение) in [("исходники", String(repeating: "a", count: 40)),
            ("эпоха", "00000000-0000-4000-8000-000000000999"), ("область", "another-scope")] {
            var нагрузка = try СинтетическийЯкорь.объект(исходный.данныеНагрузки)
            нагрузка[ключ] = значение
            let подписанный = try СинтетическийЯкорь.подписатьТестовуюНагрузку(
                СинтетическийЯкорь.кодироватьОбъект(нагрузка), ключSHA: заголовок.хэшКлючаКорня)
            #expect(СинтетическийЯкорь.отказ {
                _ = try КорневойДопускStopV4.проверитьКонверт(подписанный,
                    заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
            })
        }
        var повреждённый = try СинтетическийЯкорь.объект(конверт)
        повреждённый["подписьBase64"] = Data(repeating: 0, count: 64).base64EncodedString()
        #expect(СинтетическийЯкорь.отказ {
            _ = try КорневойДопускStopV4.проверитьКонверт(
                СинтетическийЯкорь.кодироватьОбъект(повреждённый),
                заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
        })
    }
    @Test("K18 pure: duplicate/unknown/null/fraction/trailing/base64 проверяются после действительной подписи")
    func закрытыеWireВекторыСДействительнойТестовойПодписью() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        let заголовокБайты = try Data(contentsOf: ф.заголовок)
        let заголовок = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: заголовокБайты, предел: 32_768)
        let допуск = try Data(contentsOf: ф.указатель)
        let исходный = try КорневойДопускStopV4.проверитьКонверт(допуск,
            заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
        #expect(исходный.нагрузка.предыдущийДопуск == nil)
        #expect(исходный.нагрузка.предыдущаяОперация == nil && исходный.нагрузка.прогресс == nil)
        var unknown = try СинтетическийЯкорь.объект(исходный.данныеНагрузки)
        unknown["необъявленныйКлюч"] = "known-test-only"
        var null = try СинтетическийЯкорь.объект(исходный.данныеНагрузки)
        null["предыдущийДопускSHA256"] = NSNull()
        let текст = try #require(String(data: исходный.данныеНагрузки, encoding: .utf8))
        let номер = "\"номер\":0"
        try #require(текст.components(separatedBy: номер).count == 2)
        let duplicate = текст.replacingOccurrences(of: номер, with: номер + "," + номер)
        let fraction = текст.replacingOccurrences(of: "\"редакция\":7", with: "\"редакция\":7.0")
        try #require(fraction != текст)
        let сырые = [try СинтетическийЯкорь.кодироватьОбъект(unknown),
            try СинтетическийЯкорь.кодироватьОбъект(null), Data(duplicate.utf8),
            Data(fraction.utf8), исходный.данныеНагрузки + Data(" \n".utf8)]
        for нагрузка in сырые {
            let подписанный = try СинтетическийЯкорь.подписатьТестовуюНагрузку(
                нагрузка, ключSHA: заголовок.хэшКлючаКорня)
            #expect(СинтетическийЯкорь.отказ {
                _ = try КорневойДопускStopV4.проверитьКонверт(подписанный,
                    заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
            })
        }
        var base64 = try СинтетическийЯкорь.объект(допуск)
        let значение = try #require(base64["полезнаяНагрузкаBase64"] as? String)
        base64["полезнаяНагрузкаBase64"] = значение + "\n"
        #expect(СинтетическийЯкорь.отказ {
            _ = try КорневойДопускStopV4.проверитьКонверт(
                СинтетическийЯкорь.кодироватьОбъект(base64),
                заголовок: заголовок, хэшЗаголовка: ф.хэшЗаголовка)
        })
        var каталог = try СинтетическийЯкорь.объект(заголовокБайты)
        var вложенный = try #require(каталог["каталогСнимков"] as? [String: Any])
        вложенный["индексныйУзел"] = UInt64.max
        каталог["каталогСнимков"] = вложенный
        let широкий = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: СинтетическийЯкорь.кодироватьОбъект(каталог), предел: 32_768)
        #expect(широкий.каталогСнимков.индексныйУзел == UInt64.max)
        // Это только UInt64 wire decode; физическое соответствие каталогов не заявлено.
    }
}

@testable import МатериализацияУзлов
private enum НамеренныйОтказЧтенияV4: Error { case ввод }
extension ПроверкиСтабильногоЯкоря {
    @Test("K15: Native guards не доходят до выбранного заголовка; entry/exit ровно один раз")
    func входныеGuardsИОднократнаяДиагностика() throws {
        for вариант in 0..<5 {
            let ф = try СинтетическийЯкорь.новаяФикстура()
            let заголовокДо = try Data(contentsOf: ф.заголовок)
            let указательДо = try Data(contentsOf: ф.указатель)
            let путь = ф.корень.appendingPathComponent("injected-metadata-only.jsonl").path
            let fd = open(путь, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            try #require(fd >= 0)
            defer { _ = Darwin.close(fd) }
            let приёмник = ПриёмникДиагностикиStopV4 { данные in
                let n = данные.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
                if n == данные.count { return .доставлено }
                return n > 0 ? .частично(n) : .недоступно
            }
            var аргументы = ф.аргументы
            var событие = try СинтетическийЯкорь.объект(ф.событие())
            if вариант == 1 { событие["session_id"] = "00000000-0000-4000-8000-000000000777" }
            if вариант == 2 { событие["cwd"] = "/synthetic-other-cwd" }
            if вариант == 3 { аргументы += ["--профиль-наблюдений", "fum.текущие-обязательства-stop.3"] }
            let данные = вариант == 0 ? Data("{".utf8) : try СинтетическийЯкорь.кодироватьОбъект(событие)
            var чтенийВвода = 0, выбранныхЧтений = 0
            let ответ = КомандаStop.выполнитьЧетвёртыйПрофиль(аргументы, прочитать: {
                чтенийВвода += 1
                if вариант == 4 { throw НамеренныйОтказЧтенияV4.ввод }
                return данные
            }, диагностика: приёмник, передЧтениемЯкоря: { выбранныхЧтений += 1 })
            #expect(выбранныхЧтений == 0)
            #expect(чтенийВвода == (вариант == 3 ? 0 : 1))
            #expect(try !СинтетическийЯкорь.ответБлокирует(ответ))
            try #require(fsync(fd) == 0 && lseek(fd, 0, SEEK_SET) == 0)
            var буфер = [UInt8](repeating: 0, count: 1025)
            let число = буфер.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress, $0.count) }
            try #require(число > 0 && число <= 1024)
            let строки = Data(буфер.prefix(число)).split(separator: 10)
            try #require(строки.count == 2)
            let записи = try строки.map { try СинтетическийЯкорь.объект(Data($0)) }
            #expect(записи[0]["фаза"] as? String == "вход")
            #expect(записи[1]["фаза"] as? String == "выход")
            #expect(записи[0]["вызов"] as? String == записи[1]["вызов"] as? String)
            let ключи = Set(["схема", "вызов", "процесс", "профиль", "фаза", "исход", "якорь", "захват"])
            for запись in записи {
                #expect(Set(запись.keys) == ключи)
                #expect(запись["профиль"] as? Int == 4)
                #expect(запись["якорь"] as? String == "не-проверен")
                #expect(запись["захват"] as? String == "не-начат")
            }
            #expect(try Data(contentsOf: ф.заголовок) == заголовокДо)
            #expect(try Data(contentsOf: ф.указатель) == указательДо)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
            // Это injected test sink; доставка default Native stderr этим не доказывается.
        }
    }
    @Test("K15: public exact V4 pair выбирает один wrapper при mixed/duplicate argv")
    func смешанныеПараметрыНеУдваиваютEntryExit() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        let путь = ф.корень.appendingPathComponent("public-wrapper-metadata-only.jsonl").path
        let fd = open(путь, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        try #require(fd >= 0)
        defer { _ = Darwin.close(fd) }
        let приёмник = ПриёмникДиагностикиStopV4 { данные in
            let n = данные.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
            return n == данные.count ? .доставлено : .недоступно
        }
        let ответ = КомандаStop.выполнить(ф.аргументы + ["--профиль-наблюдений",
            "fum.текущие-обязательства-stop.3"], ввод: try ф.событие(), диагностикаV4: приёмник)
        #expect(try !СинтетическийЯкорь.ответБлокирует(ответ))
        try #require(fsync(fd) == 0 && lseek(fd, 0, SEEK_SET) == 0)
        var буфер = [UInt8](repeating: 0, count: 1025)
        let n = буфер.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress, $0.count) }
        try #require(n > 0 && n <= 1024)
        #expect(Data(буфер.prefix(n)).split(separator: 10).count == 2)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
    }
}

private struct СинтетическийВыпускЯкоря: Sendable {
    let снимок, сохранённыйСнимок, нагрузка, конверт, маркер: Data
    let публикация, номер: UInt64
    let операция, снимокSHA, конвертSHA, проектSHA, решениеSHA: String
    init(_ ф: СинтетическийЯкорь, публикация: UInt64 = 0, номер: UInt64 = 0,
        операция: String = СинтетическийЯкорь.операция, предыдущий: Data? = nil,
        предыдущаяОперация: String? = nil, прогресс: [String: Any]? = nil,
        изменитьСнимок: (inout [String: Any]) throws -> Void = { _ in },
        изменитьWire: (Data) throws -> Data = { $0 },
        изменитьСохранённое: (Data) throws -> Data = { $0 },
        изменитьНагрузку: (inout [String: Any]) throws -> Void = { _ in },
        изменитьWireНагрузки: (Data) throws -> Data = { $0 },
        изменитьКонверт: (Data) throws -> Data = { $0 },
        байтКлюча: UInt8 = 0x42) throws {
        self.публикация = публикация; self.номер = номер; self.операция = операция
        var s = try СинтетическийЯкорь.объект(ф.исходныйСнимок)
        let сейчас = Int64(Date().timeIntervalSince1970)
        s["выпущен"] = сейчас - 5; s["действуетДо"] = сейчас + 600
        s["операцияПродолжения"] = операция
        try изменитьСнимок(&s)
        let канонический = try СинтетическийЯкорь.кодироватьОбъект(s)
        проектSHA = try КомандаStop.основаниеСнимкаV3(канонический)
        снимок = try изменитьWire(канонический)
        сохранённыйСнимок = try изменитьСохранённое(снимок)
        снимокSHA = СинтетическийЯкорь.хэш(снимок)
        let e = try СинтетическийЯкорь.объект(ф.исходныйДопуск)
        let encoded = try #require(e["полезнаяНагрузкаBase64"] as? String)
        let bytes = try #require(Data(base64Encoded: encoded))
        var p = try СинтетическийЯкорь.объект(bytes)
        p["публикация"] = публикация; p["номер"] = номер; p["операция"] = операция
        p["выдан"] = сейчас - 5; p["действуетДо"] = сейчас + 300
        p["HEAD"] = s["HEAD"]; p["редакция"] = s["редакция"]
        p["снимокSHA256"] = снимокSHA; p["снимокИмя"] = снимокSHA + ".json"
        p["наблюдениеSHA256"] = проектSHA
        if let n = s["наблюдения"] as? [String: Any] { p["следующаяРабота"] = n["следующаяРабота"] }
        if let предыдущий { p["предыдущийДопускSHA256"] = СинтетическийЯкорь.хэш(предыдущий) }
        else { p.removeValue(forKey: "предыдущийДопускSHA256") }
        if let предыдущаяОперация { p["предыдущаяОперация"] = предыдущаяОперация }
        else { p.removeValue(forKey: "предыдущаяОперация") }
        if let прогресс { p["прогресс"] = прогресс } else { p.removeValue(forKey: "прогресс") }
        if публикация > 0 {
            p["корневойДопускSHA256"] = СинтетическийЯкорь.хэш(Data(
                ("synthetic-independent-root-decision:" + операция + ":" + String(публикация) + ":" + проектSHA).utf8))
        }
        try изменитьНагрузку(&p)
        решениеSHA = try #require(p["корневойДопускSHA256"] as? String)
        нагрузка = try изменитьWireНагрузки(СинтетическийЯкорь.кодироватьОбъект(p))
        let ключ = try Curve25519.Signing.PrivateKey(rawRepresentation: Data(repeating: байтКлюча, count: 32))
        let ключSHA = try #require(e["ключROOTSHA256"] as? String)
        var сообщение = Data("FUM-STOP-ROOT-GRANT-v1".utf8)
        сообщение.append(0); сообщение.append(нагрузка)
        let каноническийКонверт = try СинтетическийЯкорь.кодироватьОбъект([
            "схема": "fum.stop-подписанный-root-допуск.1", "ключROOTSHA256": ключSHA,
            "полезнаяНагрузкаBase64": нагрузка.base64EncodedString(),
            "подписьBase64": ключ.signature(for: сообщение).base64EncodedString()])
        конверт = try изменитьКонверт(каноническийКонверт)
        конвертSHA = СинтетическийЯкорь.хэш(конверт)
        маркер = try СинтетическийЯкорь.кодироватьОбъект([
            "схема": "fum.stop-завершение-публикации.1", "заголовокSHA256": ф.хэшЗаголовка,
            "публикация": публикация, "допускSHA256": конвертSHA,
            "снимокSHA256": снимокSHA, "указательSHA256": конвертSHA] as [String: Any])
    }
    func сохранитьКандидат(_ ф: СинтетическийЯкорь, ожидаемый: String?) throws -> Data {
        let dir = ф.корень.appendingPathComponent("receipts")
        let candidate = dir.appendingPathComponent(операция + ".candidate-grant.json")
        let snapshot = dir.appendingPathComponent(операция + ".candidate-snapshot.json")
        try СинтетическийЯкорь.сохранить(конверт, candidate, права: 0o400)
        try СинтетическийЯкорь.сохранить(снимок, snapshot, права: 0o400)
        var plan: [String: Any] = [
            "схема": "fum.stop-план-публикации-root-допуска.1",
            "заголовокПуть": ф.заголовок.path, "заголовокSHA256": ф.хэшЗаголовка,
            "candidateEnvelopeПуть": candidate.path, "candidateEnvelopeSHA256": конвертSHA,
            "snapshotCandidateПуть": snapshot.path, "snapshotCandidateSHA256": снимокSHA,
            "initiallyAbsent": ожидаемый == nil,
            "operationIntentПуть": dir.appendingPathComponent(операция + "." + String(публикация) + ".intent.json").path,
            "operationOutcomeПуть": dir.appendingPathComponent(операция + "." + String(публикация) + ".outcome.json").path]
        if let ожидаемый { plan["expectedPointerSHA256"] = ожидаемый }
        return try СинтетическийЯкорь.кодироватьОбъект(plan)
    }
    /// Только первоначальная синтетическая установка bad/valid объектов в пустой fixture для guard tests.
    /// Положительные publisher tests используют public API вместо этой функции.
    func установитьНачальныйСинтетическийНабор(_ ф: СинтетическийЯкорь) throws {
        try #require(публикация == 0)
        try СинтетическийЯкорь.сохранить(сохранённыйСнимок,
            ф.корень.appendingPathComponent("snapshots/" + снимокSHA + ".json"), права: 0o400)
        try СинтетическийЯкорь.сохранить(конверт,
            ф.корень.appendingPathComponent("adoptions/0.допуск.json"), права: 0o400)
        try СинтетическийЯкорь.сохранить(конверт, ф.указатель, права: 0o600)
        try СинтетическийЯкорь.сохранить(маркер,
            ф.корень.appendingPathComponent("adoptions/0.завершение.json"), права: 0o400)
    }
}

private enum ОтказПубликационнойПробыV4: Error { case намеренный, запись }
private extension СинтетическийЯкорь {
    static func незапубликованнаяФикстура() throws -> Self {
        let путь = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        return try Self(основание: URL(fileURLWithPath: путь), публиковатьНачальный: false)
    }
    static func отсутствует(_ путь: URL) -> Bool {
        var s = stat()
        return lstat(путь.path, &s) == -1 && errno == ENOENT
    }
    func путьИсхода(_ выпуск: СинтетическийВыпускЯкоря) -> URL {
        корень.appendingPathComponent("receipts/" + выпуск.операция + "." + String(выпуск.публикация) + ".outcome.json")
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K12 positive genesis: public check без записи, apply даёт отдельный terminal после prepared outcome")
    func первоначальнаяПубликацияЧерезPublicAPI() throws {
        let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
        let выпуск = try СинтетическийВыпускЯкоря(ф)
        let план = try выпуск.сохранитьКандидат(ф, ожидаемый: nil)
        let header = try Data(contentsOf: ф.заголовок)
        let legacy2 = try Data(contentsOf: ф.староеV2), legacy3 = try Data(contentsOf: ф.староеV3)
        let проверка = try КомандаStop.проверитьПубликациюV4(план, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        #expect(try СинтетическийЯкорь.объект(проверка)["исход"] as? String == "ПРОВЕРЕНО_БЕЗ_ЗАПИСИ")
        #expect(СинтетическийЯкорь.отсутствует(ф.указатель))
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("adoptions").path).isEmpty)
        let terminal = try КомандаStop.опубликоватьДопускV4(план, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        let итог = try СинтетическийЯкорь.объект(terminal)
        #expect(итог["схема"] as? String == "fum.stop-терминал-публикации.4")
        #expect(итог["исход"] as? String == "ОПУБЛИКОВАНО")
        let outcome = try Data(contentsOf: ф.путьИсхода(выпуск))
        #expect(try СинтетическийЯкорь.объект(outcome)["исход"] as? String == "ПОДГОТОВЛЕННЫЙ_ИСХОД")
        #expect(try Data(contentsOf: ф.указатель) == выпуск.конверт)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.допуск.json")) == выпуск.конверт)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json")) == выпуск.маркер)
        let ответ = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        #expect(try СинтетическийЯкорь.ответБлокирует(ответ))
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).count == 1)
        #expect(try Data(contentsOf: ф.заголовок) == header)
        #expect(try Data(contentsOf: ф.староеV2) == legacy2)
        #expect(try Data(contentsOf: ф.староеV3) == legacy3)
        #expect(try Data(contentsOf: ф.путьИсхода(выпуск)) == outcome)
    }
    @Test("K12: после durable record до pointer сохраняется GN2a без callback repair, genesis и update")
    func отказПослеRecordНеПубликуетИНеЧинитУказатель() throws {
        for update in [false, true] {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            let zero = try СинтетическийВыпускЯкоря(ф)
            if update {
                let p0 = try zero.сохранитьКандидат(ф, ожидаемый: nil)
                _ = try КомандаStop.опубликоватьДопускV4(p0, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
            }
            let выпуск = try update
                ? СинтетическийВыпускЯкоря(ф, публикация: 1, операция: UUID().uuidString.lowercased(), предыдущий: zero.конверт)
                : zero
            let plan = try выпуск.сохранитьКандидат(ф, ожидаемый: update ? zero.конвертSHA : nil)
            var отказ: ОтказПубликацииStopV4?
            do {
                _ = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка,
                    точки: .init(событие: { if $0 == "допуск-после-readback" { throw ОтказПубликационнойПробыV4.намеренный } }))
                Issue.record("После инъекции record не должен возвращаться publisher success")
            } catch let e as ОтказПубликацииStopV4 { отказ = e }
            let e = try #require(отказ)
            #expect(e.возможенЭффект)
            #expect(e.исходКвитанции == "UNKNOWN_СОХРАНЁН")
            let record = ф.корень.appendingPathComponent("adoptions/" + String(выпуск.публикация) + ".допуск.json")
            let marker = ф.корень.appendingPathComponent("adoptions/" + String(выпуск.публикация) + ".завершение.json")
            #expect(try Data(contentsOf: record) == выпуск.конверт)
            #expect(СинтетическийЯкорь.отсутствует(marker))
            if update { #expect(try Data(contentsOf: ф.указатель) == zero.конверт) }
            else { #expect(СинтетическийЯкорь.отсутствует(ф.указатель)) }
            let outcome = try Data(contentsOf: ф.путьИсхода(выпуск))
            let ответ = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
            #expect(try !СинтетическийЯкорь.ответБлокирует(ответ))
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
            #expect(try Data(contentsOf: record) == выпуск.конверт)
            #expect(СинтетическийЯкорь.отсутствует(marker))
            #expect(try Data(contentsOf: ф.путьИсхода(выпуск)) == outcome)
        }
    }
    @Test("K13 final fence: HEAD drift around each outcome effect yields UNKNOWN and preserves prepared bytes")
    func дрейфHEADПриСохраненииИсходаНеДаётSuccess() throws {
        let фазы = ["исход-после-создания", "исход-после-записи", "исход-после-fsync-файла",
            "исход-после-fsync-каталога", "исход-после-readback"]
        for фаза in фазы {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            let выпуск = try СинтетическийВыпускЯкоря(ф)
            let план = try выпуск.сохранитьКандидат(ф, ожидаемый: nil)
            let ref = ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master")
            try СинтетическийЯкорь.сохранить(try Data(contentsOf: ref),
                ф.корень.appendingPathComponent("retained-before-outcome-head.raw"), права: 0o400)
            var отказ: ОтказПубликацииStopV4?
            do {
                _ = try КомандаStop.опубликоватьДопускV4(план, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка,
                    точки: .init(событие: { событие in
                        if событие == фаза { try Data((String(repeating: "b", count: 40) + "\n").utf8).write(to: ref) }
                    }))
                Issue.record("HEAD drift после outcome эффекта не должен вернуть success")
            } catch let e as ОтказПубликацииStopV4 { отказ = e }
            let e = try #require(отказ)
            #expect(e.возможенЭффект)
            #expect(e.исходКвитанции == "UNKNOWN_ПОСЛЕ_ПОПЫТКИ")
            let сохранено = try Data(contentsOf: ф.путьИсхода(выпуск))
            if фаза == "исход-после-создания" { #expect(сохранено.isEmpty) }
            else { #expect(try СинтетическийЯкорь.объект(сохранено)["исход"] as? String == "ПОДГОТОВЛЕННЫЙ_ИСХОД") }
            #expect(try Data(contentsOf: ф.указатель) == выпуск.конверт)
            #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json")) == выпуск.маркер)
            let ответ = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
            #expect(try !СинтетическийЯкорь.ответБлокирует(ответ))
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
            #expect(try Data(contentsOf: ф.путьИсхода(выпуск)) == сохранено)
        }
    }
    @Test("K13: complete-visible UNKNOWN требует восемь sync; каждое hook failure не выдаёт claim, independent callback разрешён")
    func восемьСинхронизацийДоClaimПослеНеизвестногоPublisher() throws {
        let фазы = ["снимок-файл", "снимок-каталог", "допуск-файл", "допуск-каталог",
            "указатель-файл", "указатель-каталог", "завершение-файл", "завершение-каталог"]
        for сбой in фазы {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            let выпуск = try СинтетическийВыпускЯкоря(ф)
            let план = try выпуск.сохранитьКандидат(ф, ожидаемый: nil)
            var отказ: ОтказПубликацииStopV4?
            do {
                _ = try КомандаStop.опубликоватьДопускV4(план, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка,
                    точки: .init(событие: { if $0 == "завершение-после-readback" { throw ОтказПубликационнойПробыV4.намеренный } }))
                Issue.record("Инъекция после marker должна сохранить publisher UNKNOWN")
            } catch let e as ОтказПубликацииStopV4 { отказ = e }
            let e = try #require(отказ)
            #expect(e.исходКвитанции == "UNKNOWN_СОХРАНЁН")
            let старыйИсход = try Data(contentsOf: ф.путьИсхода(выпуск))
            let событие = try ф.событие()
            let отказCallback = КомандаStop.выполнитьЧетвёртыйПрофиль(ф.аргументы,
                прочитать: { событие }, диагностика: .init { _ in .недоступно },
                точкиСинхронизации: .init(перед: { if $0 == сбой { throw ОтказПубликационнойПробыV4.намеренный } }))
            #expect(try !СинтетическийЯкорь.ответБлокирует(отказCallback))
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
            #expect(try Data(contentsOf: ф.путьИсхода(выпуск)) == старыйИсход)
            let trace = ф.корень.appendingPathComponent("independent-sync-phases.txt")
            let fd = open(trace.path, O_RDWR | O_APPEND | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            try #require(fd >= 0)
            defer { _ = Darwin.close(fd) }
            // Новый независимый callback заранее допущен контрактом GN2b; прежний UNKNOWN не переписывается.
            let принят = КомандаStop.выполнитьЧетвёртыйПрофиль(ф.аргументы,
                прочитать: { событие }, диагностика: .init { _ in .недоступно },
                точкиСинхронизации: .init(перед: { фаза in
                    let d = Data((фаза + "\n").utf8)
                    let n = d.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
                    guard n == d.count else { throw ОтказПубликационнойПробыV4.запись }
                }))
            #expect(try СинтетическийЯкорь.ответБлокирует(принят))
            try #require(fsync(fd) == 0)
            let observed = try String(contentsOf: trace, encoding: .utf8).split(separator: "\n").map(String.init)
            #expect(observed == фазы)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).count == 1)
            #expect(try Data(contentsOf: ф.путьИсхода(выпуск)) == старыйИсход)
            // Hook throw доказывает остановку на границе; это не инъекция errno реального fsync.
        }
    }
}

private extension СинтетическийЯкорь {
    func сохранитьПрогрессПослеClaim(_ прежнийClaim: Data, прежняяНагрузка: [String: Any],
        следующий: СинтетическийВыпускЯкоря) throws -> [String: Any] {
        let dir = корень.appendingPathComponent("receipts")
        let результатИмя = следующий.операция + ".result.json"
        let результат = try Self.кодироватьОбъект(["схема": "fum.synthetic-result.1",
            "исход": "Точный синтетический результат принят тестовым ROOT", "операция": следующий.операция])
        try Self.сохранить(результат, dir.appendingPathComponent(результатИмя), права: 0o400)
        let oldOperation = try #require(прежняяНагрузка["операция"] as? String)
        let oldProject = try #require(прежняяНагрузка["наблюдениеSHA256"] as? String)
        let прогресс = try Self.кодироватьОбъект([
            "схема": "fum.stop-принятый-прогресс.1", "исход": "шаг-выполнен-и-принят",
            "задача": Self.задача, "узел": Self.узел, "область": Self.область,
            "поколение": Self.поколение, "исходники": Self.исходники, "эпоха": Self.эпоха,
            "предыдущаяОперация": oldOperation, "следующаяОперация": следующий.операция,
            "предыдущийЗахватSHA256": Self.хэш(прежнийClaim),
            "предыдущееНаблюдениеSHA256": oldProject, "новоеНаблюдениеSHA256": следующий.проектSHA,
            "корневойДопускSHA256": следующий.решениеSHA,
            "результат": ["путь": результатИмя, "sha256": Self.хэш(результат)]] as [String: Any])
        let имя = следующий.операция + ".progress.json"
        try Self.сохранить(прогресс, dir.appendingPathComponent(имя), права: 0o400)
        return ["путь": имя, "sha256": Self.хэш(прогресс)]
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K03: actual claim0, expired old lease и HEAD A→B с новым signed progress дают claim1 под тем же header")
    func истёкшаяИсторияДопускаетНовыйHEADПослеПрогресса() async throws {
        let основание = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        let ф = try СинтетическийЯкорь(основание: URL(fileURLWithPath: основание),
            срокПервогоLeaseСекунд: 2)
        let header = try Data(contentsOf: ф.заголовок), argv = ф.аргументы
        let oldEnvelope = try Data(contentsOf: ф.указатель)
        let oldMarker = try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json"))
        let object = try СинтетическийЯкорь.объект(oldEnvelope)
        let encoded = try #require(object["полезнаяНагрузкаBase64"] as? String)
        let rawPayload = try #require(Data(base64Encoded: encoded))
        let oldPayload = try СинтетическийЯкорь.объект(rawPayload)
        let expiry = try #require(oldPayload["действуетДо"] as? Int64)
        let ответ0 = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let первыйПринят = try СинтетическийЯкорь.ответБлокирует(ответ0)
        try #require(первыйПринят)
        let claim0Path = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
        let claim0 = try Data(contentsOf: claim0Path)
        // Это необходимая граница реального lease, а не задержка ради RSS/продолжительности.
        let доГраницы = Double(expiry) + 1.05 - Date().timeIntervalSince1970
        try #require(доГраницы <= 4)
        if доГраницы > 0 { try await Task.sleep(nanoseconds: UInt64(доГраницы * 1_000_000_000)) }
        try #require(Int64(Date().timeIntervalSince1970) > expiry)
        let ref = ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master")
        try СинтетическийЯкорь.сохранить(try Data(contentsOf: ref),
            ф.корень.appendingPathComponent("retained-head-A.raw"), права: 0o400)
        let B = String(repeating: "b", count: 40)
        try Data((B + "\n").utf8).write(to: ref)
        let operation = UUID().uuidString.lowercased()
        let mutate: (inout [String: Any]) throws -> Void = { s in
            s["HEAD"] = B; s["редакция"] = 8
            var n = try #require(s["наблюдения"] as? [String: Any])
            n["следующаяРабота"] = "Проверить следующий синтетический результат B"
            s["наблюдения"] = n
        }
        let preview = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
            операция: operation, предыдущий: oldEnvelope, предыдущаяОперация: СинтетическийЯкорь.операция,
            изменитьСнимок: mutate)
        let progressRef = try ф.сохранитьПрогрессПослеClaim(claim0,
            прежняяНагрузка: oldPayload, следующий: preview)
        let следующий = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
            операция: operation, предыдущий: oldEnvelope, предыдущаяОперация: СинтетическийЯкорь.операция,
            прогресс: progressRef, изменитьСнимок: mutate)
        #expect(следующий.проектSHA == preview.проектSHA)
        #expect(следующий.решениеSHA == preview.решениеSHA)
        let plan = try следующий.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(oldEnvelope))
        let terminal = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        #expect(try СинтетическийЯкорь.объект(terminal)["исход"] as? String == "ОПУБЛИКОВАНО")
        let ответ1 = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        #expect(try СинтетическийЯкорь.ответБлокирует(ответ1))
        let имена = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).sorted()
        #expect(имена == [СинтетическийЯкорь.эпоха + ".0.claim", СинтетическийЯкорь.эпоха + ".1.claim"])
        let claim1 = try Data(contentsOf: ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".1.claim"))
        #expect(try СинтетическийЯкорь.объект(claim1)["подписанныйДопускSHA256"] as? String == следующий.конвертSHA)
        #expect(try Data(contentsOf: claim0Path) == claim0)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.допуск.json")) == oldEnvelope)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json")) == oldMarker)
        #expect(try Data(contentsOf: ф.заголовок) == header)
        #expect(ф.аргументы == argv)
    }
}

private extension СинтетическийЯкорь {
    func сохранитьНазваниеПроверки(_ имя: String) throws {
        try Self.сохранить(Self.кодироватьОбъект(["схема": "fum.synthetic-case.1", "проверка": имя]),
            корень.appendingPathComponent("fixture-case.json"), права: 0o400)
    }
    func проверитьНачальныйСинтетическийНабор(_ выпуск: СинтетическийВыпускЯкоря,
        блокирует: Bool) throws -> [String: Any] {
        try выпуск.установитьНачальныйСинтетическийНабор(self)
        let ответ = КомандаStop.выполнить(аргументы, ввод: try событие())
        #expect(try Self.ответБлокирует(ответ) == блокирует)
        let names = try FileManager.default.contentsOfDirectory(atPath: захваты.path)
        #expect(names.count == (блокирует ? 1 : 0))
        try Self.сохранить(ответ, корень.appendingPathComponent("guard-response.raw"), права: 0o600)
        return try Self.объект(ответ)
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K04: control исключён из project hash, но tamper raw snapshot отвергается полным SHA")
    func полныйХэшЗащищаетУправлениеОтПодмены() throws {
        let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
        try ф.сохранитьНазваниеПроверки("K04-control-tamper-after-signed-hash")
        let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьСохранённое: { raw in
            var s = try СинтетическийЯкорь.объект(raw)
            s["управление"] = ["действие": "стоп", "основание": "Synthetic unsigned control tamper"]
            return try СинтетическийЯкорь.кодироватьОбъект(s)
        })
        #expect(try КомандаStop.основаниеСнимкаV3(выпуск.сохранённыйСнимок) == выпуск.проектSHA)
        #expect(СинтетическийЯкорь.хэш(выпуск.сохранённыйСнимок) != выпуск.снимокSHA)
        let ответ = try ф.проверитьНачальныйСинтетическийНабор(выпуск, блокирует: false)
        #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
    }
    @Test("K05: wrong signer и duplicate/unknown envelope/payload имеют согласованные ledger links, claim не выдают")
    func подписьИЗакрытыеКонвертыОтклоняютсяДоЗахвата() throws {
        let positive = try СинтетическийЯкорь.незапубликованнаяФикстура()
        try positive.сохранитьНазваниеПроверки("K05-positive-signed-control")
        _ = try positive.проверитьНачальныйСинтетическийНабор(СинтетическийВыпускЯкоря(positive), блокирует: true)
        for вариант in 0..<5 {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            try ф.сохранитьНазваниеПроверки("K05-negative-" + String(вариант))
            let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьWireНагрузки: { raw in
                if вариант == 1 {
                    var p = try СинтетическийЯкорь.объект(raw); p["необъявленноеПоле"] = true
                    return try СинтетическийЯкорь.кодироватьОбъект(p)
                }
                if вариант == 2 {
                    let t = try #require(String(data: raw, encoding: .utf8)), key = "\"номер\":0"
                    try #require(t.components(separatedBy: key).count == 2)
                    return Data(t.replacingOccurrences(of: key, with: key + "," + key).utf8)
                }
                return raw
            }, изменитьКонверт: { raw in
                if вариант == 3 {
                    var p = try СинтетическийЯкорь.объект(raw); p["необъявленноеПоле"] = true
                    return try СинтетическийЯкорь.кодироватьОбъект(p)
                }
                if вариант == 4 {
                    let t = try #require(String(data: raw, encoding: .utf8))
                    let key = "\"схема\":\"fum.stop-подписанный-root-допуск.1\""
                    try #require(t.components(separatedBy: key).count == 2)
                    return Data(t.replacingOccurrences(of: key, with: key + "," + key).utf8)
                }
                return raw
            }, байтКлюча: вариант == 0 ? 0x43 : 0x42)
            let ответ = try ф.проверитьНачальныйСинтетическийНабор(выпуск, блокирует: false)
            #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
        }
    }
    @Test("K06: fresh signed snapshot не заменяет expired/future/overlong Root lease")
    func свежийСнимокНеЗаменяетКорневойСрок() throws {
        for вариант in 0..<3 {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            try ф.сохранитьНазваниеПроверки("K06-lease-" + String(вариант))
            let now = Int64(Date().timeIntervalSince1970)
            let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьНагрузку: { p in
                if вариант == 0 { p["выдан"] = now - 60; p["действуетДо"] = now - 1 }
                if вариант == 1 { p["выдан"] = now + 30; p["действуетДо"] = now + 90 }
                if вариант == 2 { p["выдан"] = now - 5; p["действуетДо"] = now + 3600 }
            })
            let ответ = try ф.проверитьНачальныйСинтетическийНабор(выпуск, блокирует: false)
            #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
        }
    }
    @Test("K17: full signed pause проверяет current lease/Git/mandatory stamps до применения управления")
    func подписаннаяПаузаНеОбходитПолныйВход() throws {
        for вариант in 0..<6 {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            try ф.сохранитьНазваниеПроверки("K17-pause-" + String(вариант))
            let now = Int64(Date().timeIntervalSince1970)
            let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьСнимок: { s in
                s["управление"] = ["действие": "пауза", "основание": "Synthetic signed ROOT pause"]
                var n = try #require(s["наблюдения"] as? [String: Any])
                var u = try #require(n["условия"] as? [String: Any])
                u["остановкаЗадачи"] = true; n["условия"] = u; s["наблюдения"] = n
                if вариант == 5 { s["выпущен"] = now - 1000; s["действуетДо"] = now - 500 }
            }, изменитьWire: { raw in
                var s = try СинтетическийЯкорь.объект(raw)
                if вариант == 1 { s.removeValue(forKey: "редакция") }
                if вариант == 2 { s.removeValue(forKey: "эпохаПродолжения") }
                if вариант == 3 { s.removeValue(forKey: "операцияПродолжения") }
                return try СинтетическийЯкорь.кодироватьОбъект(s)
            }, изменитьНагрузку: { p in
                if вариант == 4 { p["выдан"] = now - 60; p["действуетДо"] = now - 1 }
            })
            let ответ = try ф.проверитьНачальныйСинтетическийНабор(выпуск, блокирует: false)
            let причина = try #require(ответ["stopReason"] as? String)
            #expect(причина.contains(вариант == 0 ? "BLOCKED: подписанное-управление-ROOT" : "UNKNOWN"))
        }
        let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
        try ф.сохранитьНазваниеПроверки("K17-pause-current-Git-mismatch")
        let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьСнимок: { s in
            s["управление"] = ["действие": "пауза", "основание": "Synthetic signed ROOT pause"]
        })
        try выпуск.установитьНачальныйСинтетическийНабор(ф)
        try Data((String(repeating: "b", count: 40) + "\n").utf8).write(
            to: ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master"))
        let ответ = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        #expect((try СинтетическийЯкорь.объект(ответ)["stopReason"] as? String)?.contains("UNKNOWN") == true)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
    }
    @Test("K18 snapshot: correctly signed raw nested/optional/number/duplicate mutations reach production codec")
    func закрытыеВложенныеСнимкиСПодписаннымПолнымХэшем() throws {
        let positive = try СинтетическийЯкорь.незапубликованнаяФикстура()
        try positive.сохранитьНазваниеПроверки("K18-snapshot-positive-control")
        _ = try positive.проверитьНачальныйСинтетическийНабор(СинтетическийВыпускЯкоря(positive), блокирует: true)
        for вариант in 0..<12 {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            try ф.сохранитьНазваниеПроверки("K18-snapshot-negative-" + String(вариант))
            let выпуск = try СинтетическийВыпускЯкоря(ф, изменитьWire: { raw in
                let t = try #require(String(data: raw, encoding: .utf8)), key = "\"редакция\":7"
                if вариант == 6 {
                    try #require(t.components(separatedBy: key).count == 2)
                    return Data(t.replacingOccurrences(of: key, with: key + "," + key).utf8)
                }
                if вариант == 7 { return Data(t.replacingOccurrences(of: key, with: "\"редакция\":7.0").utf8) }
                if вариант == 8 { return raw + Data(" \n".utf8) }
                var s = try СинтетическийЯкорь.объект(raw)
                if вариант == 0 { s["необъявлено"] = true }
                if вариант == 1 {
                    var u = try #require(s["управление"] as? [String: Any]); u["необъявлено"] = true; s["управление"] = u
                }
                if вариант == 2 {
                    var p = try #require(s["пункты"] as? [[String: Any]]); p[0]["необъявлено"] = true; s["пункты"] = p
                }
                if вариант == 3 {
                    var n = try #require(s["наблюдения"] as? [String: Any]); n["необъявлено"] = true; s["наблюдения"] = n
                }
                if вариант == 4 || вариант == 10 {
                    var n = try #require(s["наблюдения"] as? [String: Any])
                    var u = try #require(n["условия"] as? [String: Any])
                    if вариант == 4 { u["необъявлено"] = true } else { u.removeValue(forKey: "свояОбласть") }
                    n["условия"] = u; s["наблюдения"] = n
                }
                if вариант == 5 { s["диспозиция"] = NSNull() }
                if вариант == 9 { s.removeValue(forKey: "эпохаПродолжения") }
                if вариант == 11 {
                    var u = try #require(s["управление"] as? [String: Any]); u["основание"] = NSNull(); s["управление"] = u
                }
                return try СинтетическийЯкорь.кодироватьОбъект(s)
            })
            let ответ = try ф.проверитьНачальныйСинтетическийНабор(выпуск, блокирует: false)
            #expect((ответ["stopReason"] as? String)?.contains("UNKNOWN") == true)
        }
    }
}
    private struct ФикстураНаследияStop {
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
            try СинтетическийЯкорь.кодироватьОбъект(объект)
        }

        static func сохранить(_ данные: Data, в путь: URL, права: Int) throws {
            try СинтетическийЯкорь.сохранить(данные, путь, права: права)
        }

        init(основание: URL) throws {
            корень = основание.appendingPathComponent("legacy-v2-\(UUID().uuidString.lowercased())")
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


        var аргументы: [String] {
            ["--идентификатор-обработчика", "fum.stop-handler.1",
             "--codex-thread-id", Self.задача, "--идентификатор-узла", Self.узел,
             "--ожидаемый-cwd", nativeCWD.path, "--состояние", состояние.path,
             "--профиль-наблюдений", "fum.текущие-обязательства-stop.2",
             "--заголовок", заголовок.path, "--хэш-заголовка", хэшЗаголовка]
        }

        func событие(задача: String = ФикстураНаследияStop.задача) -> [String: Any] {
            ["session_id": задача, "hook_event_name": "Stop",
             "cwd": nativeCWD.path, "turn_id": "unit-turn-479",
             "stop_hook_active": false]
        }

        func пункт(_ состояние: String, область: String = ФикстураНаследияStop.область,
                   id: String = ФикстураНаследияStop.пункт, уровень: String = "исходники") -> [String: Any] {
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

        func завершённый(областьКвитанции: String = ФикстураНаследияStop.область) throws -> [String: Any] {
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
import Dispatch

private extension ПроверкиСтабильногоЯкоря {
    static func начатьТранспортныеМетки(_ имя: String) throws -> URL {
        let parent = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        let root = URL(fileURLWithPath: parent).appendingPathComponent("transport-stages-" + имя + "-" + UUID().uuidString.lowercased())
        try #require(mkdir(root.path, 0o700) == 0)
        return root
    }
    static func отметитьТранспортныйЭтап(_ root: URL, _ имя: String) throws {
        let data = try СинтетическийЯкорь.кодироватьОбъект([
            "схема": "fum.synthetic-os-step.1", "этап": имя, "PID": getpid(), "PPID": getppid(), "PGID": getpgrp(),
            "монотонноеВремяНс": DispatchTime.now().uptimeNanoseconds,
            "назначение": "Наличие метки не доказывает прохождения assertions или следующих эффектов"] as [String: Any])
        try СинтетическийЯкорь.сохранить(data, root.appendingPathComponent(имя + ".json"), права: 0o400)
    }
}

private extension ПроверкиСтабильногоЯкоря {
    static func транспортноеНаблюдение() -> НаблюдениеВызоваStopV4 {
        .init(вызов: UUID().uuidString.lowercased(), процесс: getpid(), фаза: .вход,
            исход: .обработчикВызван, якорь: .неПроверен, захват: .неНачат)
    }
    static func сохранитьТранспортнуюПробу(_ имя: String, _ данные: [String: Any]) throws {
        let parent = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        let root = URL(fileURLWithPath: parent).appendingPathComponent("transport-" + UUID().uuidString.lowercased())
        try #require(mkdir(root.path, 0o700) == 0)
        var object = данные
        object["схема"] = "fum.synthetic-os-transport.1"; object["проверка"] = имя
        object["NativeFD2Проверен"] = false
        try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект(object),
            root.appendingPathComponent("result.json"), права: 0o400)
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K18 OS: blocking socket пропускается до send, owned NONBLOCK доставляет wholeJSON и переживает closed peer")
    func собственныйSocketИЗакрытыйPeer() throws {
        let stages = try Self.начатьТранспортныеМетки("socket")
        try Self.отметитьТранспортныйЭтап(stages, "00-enter")
        var pair = [Int32](repeating: -1, count: 2)
        try #require(socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0)
        let writer = pair[0], reader = pair[1]
        var readerOpen = true
        defer { _ = Darwin.close(writer); if readerOpen { _ = Darwin.close(reader) } }
        let blockingFlags = fcntl(writer, F_GETFL), fdFlags = fcntl(writer, F_GETFD)
        try #require(blockingFlags >= 0 && blockingFlags & O_NONBLOCK == 0 && fdFlags >= 0)
        let readerBefore = fcntl(reader, F_GETFL)
        try #require(readerBefore >= 0 && fcntl(reader, F_SETFL, readerBefore | O_NONBLOCK) == 0)
        let readerReady = fcntl(reader, F_GETFL)
        try #require(readerReady >= 0 && readerReady & O_NONBLOCK != 0)
        let sink = ПриёмникДиагностикиStopV4.дескриптор(writer)
        try Self.отметитьТранспортныйЭтап(stages, "00a-before-blocking-socket-sink")
        let unsafeStart = DispatchTime.now().uptimeNanoseconds
        let unsafe = sink.передать(Self.транспортноеНаблюдение())
        let unsafeNS = DispatchTime.now().uptimeNanoseconds - unsafeStart
        try Self.отметитьТранспортныйЭтап(stages, "00b-after-blocking-socket-sink")
        // Пустой собственный reader уже NONBLOCK. Старый V10 выдаёт небольшую запись;
        // nonfatal assertions сохраняют RED и позволяют измерить следующий безопасный путь.
        var unsafeBuffer = [UInt8](repeating: 0, count: 513)
        let unsafeRead = unsafeBuffer.withUnsafeMutableBytes { Darwin.read(reader, $0.baseAddress, $0.count) }
        let unsafeErrno = errno
        let unsafeBytes = unsafeRead > 0 ? unsafeRead : 0
        #expect(unsafe == .недоступно)
        #expect(unsafeRead == -1 && (unsafeErrno == EAGAIN || unsafeErrno == EWOULDBLOCK))
        let afterUnsafeFlags = fcntl(writer, F_GETFL), afterUnsafeFDFlags = fcntl(writer, F_GETFD)
        #expect(afterUnsafeFlags == blockingFlags && afterUnsafeFDFlags == fdFlags)
        // Только фикстура меняет собственный OFD до production baseline; никаких restore.
        try #require(fcntl(writer, F_SETFL, afterUnsafeFlags | O_NONBLOCK) == 0)
        let flags = fcntl(writer, F_GETFL)
        try #require(flags >= 0 && flags & O_NONBLOCK != 0)
        try #require(fcntl(writer, F_GETFD) == fdFlags)
        try Self.отметитьТранспортныйЭтап(stages, "00c-own-nonblock-ready")
        try Self.отметитьТранспортныйЭтап(stages, "01-before-sink-delivery")
        let safeStart = DispatchTime.now().uptimeNanoseconds
        let result = sink.передать(Self.транспортноеНаблюдение())
        let safeNS = DispatchTime.now().uptimeNanoseconds - safeStart
        try Self.отметитьТранспортныйЭтап(stages, "02-after-sink-delivery")
        #expect(result == .доставлено)
        #expect(fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags)
        var buffer = [UInt8](repeating: 0, count: 513)
        let n = buffer.withUnsafeMutableBytes { Darwin.read(reader, $0.baseAddress, $0.count) }
        try #require(n > 0 && n <= 512)
        let bytes = Data(buffer.prefix(n))
        #expect(bytes.last == 10)
        let record = try СинтетическийЯкорь.объект(bytes)
        #expect(Set(record.keys) == Set(["схема","вызов","процесс","профиль","фаза","исход","якорь","захват"]))
        var extra: UInt8 = 0
        let extraRead = Darwin.read(reader, &extra, 1)
        let extraErrno = errno
        #expect(extraRead == -1 && (extraErrno == EAGAIN || extraErrno == EWOULDBLOCK))
        let closeResult = Darwin.close(reader); readerOpen = false
        try #require(closeResult == 0)
        try Self.отметитьТранспортныйЭтап(stages, "03-before-closed-peer-sink")
        let closedStart = DispatchTime.now().uptimeNanoseconds
        let closed = sink.передать(Self.транспортноеНаблюдение())
        let closedNS = DispatchTime.now().uptimeNanoseconds - closedStart
        try Self.отметитьТранспортныйЭтап(stages, "04-after-closed-peer-sink")
        #expect(closed == .недоступно)
        #expect(fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags)
        try Self.сохранитьТранспортнуюПробу("socket-blocking-guard-nonblock-wholeJSON-and-closed-peer",
            ["blockingИсход": String(describing: unsafe), "blockingReadReturn": unsafeRead,
             "blockingReadErrno": unsafeErrno, "blockingДоставленоБайт": unsafeBytes,
             "blockingПолученоBase64": Data(unsafeBuffer.prefix(unsafeBytes)).base64EncodedString(),
             "blockingНс": String(unsafeNS), "safeНс": String(safeNS), "closedPeerНс": String(closedNS),
             "rawBlockingFlags": blockingFlags, "rawAfterBlockingFlags": afterUnsafeFlags,
             "rawBeforeNonblockSetup": afterUnsafeFlags, "rawAfterNonblockSetup": flags,
             "readerДо": readerBefore, "readerNONBLOCK": readerReady,
             "доставленоБайт": n, "closedPeer": String(describing: closed),
             "флагиДо": flags, "флагиПосле": fcntl(writer, F_GETFL),
             "fdФлагиДо": fdFlags, "fdФлагиПосле": fcntl(writer, F_GETFD),
             "флагиСохранены": fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags,
             "extraReadReturn": extraRead, "extraReadErrno": extraErrno,
             "SIGPIPEПроцессВыжил": true, "signalDisposition": "UNKNOWN_UNCHANGED_BY_TEST",
             "полученныйJSON": record, "полученоBase64": bytes.base64EncodedString()])
    }
    @Test("K18 OS: full owned NONBLOCK socket возвращает unavailable без retry/fallback и изменения production flags")
    func заполненныйСобственныйSocket() throws {
        let stages = try Self.начатьТранспортныеМетки("full-socket")
        try Self.отметитьТранспортныйЭтап(stages, "00-enter")
        var pair = [Int32](repeating: -1, count: 2)
        try #require(socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0)
        let writer = pair[0], reader = pair[1]
        defer { _ = Darwin.close(writer); _ = Darwin.close(reader) }
        let setupBefore = fcntl(writer, F_GETFL), fdFlags = fcntl(writer, F_GETFD)
        try #require(setupBefore >= 0 && fdFlags >= 0)
        try #require(fcntl(writer, F_SETFL, setupBefore | O_NONBLOCK) == 0)
        let setupAfter = fcntl(writer, F_GETFL)
        try #require(setupAfter >= 0 && setupAfter & O_NONBLOCK != 0)
        try #require(setupAfter == setupBefore | O_NONBLOCK && fcntl(writer, F_GETFD) == fdFlags)
        try Self.сохранитьТранспортнуюПробу("full-socket-owned-nonblock-setup",
            ["rawДоSetup": setupBefore, "rawПослеSetup": setupAfter,
             "fdДо": fdFlags, "fdПослеSetup": fcntl(writer, F_GETFD),
             "NONBLOCKПрочитанДоFill": setupAfter & O_NONBLOCK != 0,
             "PID": getpid(), "PPID": getppid(), "PGID": getpgrp()])
        let fill = [UInt8](repeating: 0x61, count: 4096)
        var reached = false, largeCalls = 0, smallCalls = 0
        var largeBytes = 0, smallBytes = 0, largeErrno: Int32 = 0, smallErrno: Int32 = 0
        try Self.отметитьТранспортныйЭтап(stages, "01-before-large-fill")
        for _ in 0..<512 {
            largeCalls += 1
            let n = fill.withUnsafeBytes { Darwin.send(writer, $0.baseAddress, $0.count, Int32(MSG_DONTWAIT | MSG_NOSIGNAL)) }
            let e = errno
            if n < 0 { largeErrno = e; try #require(e == EAGAIN || e == EWOULDBLOCK); break }
            try #require(n > 0)
            largeBytes += n
        }
        try Self.отметитьТранспортныйЭтап(stages, "02-after-large-before-small-fill")
        for _ in 0..<4096 {
            smallCalls += 1
            var byte: UInt8 = 0x62
            let n = withUnsafePointer(to: &byte) { Darwin.send(writer, $0, 1, Int32(MSG_DONTWAIT | MSG_NOSIGNAL)) }
            let e = errno
            if n < 0 { smallErrno = e; try #require(e == EAGAIN || e == EWOULDBLOCK); reached = true; break }
            try #require(n == 1)
            smallBytes += n
        }
        try Self.отметитьТранспортныйЭтап(stages, "03-after-small-fill")
        try #require(reached && largeBytes + smallBytes > 0)
        let flags = fcntl(writer, F_GETFL)
        try #require(flags >= 0 && flags & O_NONBLOCK != 0 && fcntl(writer, F_GETFD) == fdFlags)
        try Self.сохранитьТранспортнуюПробу("full-socket-positive-fill-before-production",
            ["rawДоSetup": setupBefore, "rawПослеSetup": setupAfter, "rawProductionBaseline": flags,
             "largeFillCalls": largeCalls, "smallFillCalls": smallCalls,
             "largeFillBytes": largeBytes, "smallFillBytes": smallBytes,
             "всегоПоложительноЗаписано": largeBytes + smallBytes,
             "largeFillErrno": largeErrno, "smallFillErrno": smallErrno,
             "singleByteEAGAINObserved": reached])
        try Self.отметитьТранспортныйЭтап(stages, "04-before-full-socket-sink")
        let start = DispatchTime.now().uptimeNanoseconds
        let result = ПриёмникДиагностикиStopV4.дескриптор(writer).передать(Self.транспортноеНаблюдение())
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        try Self.отметитьТранспортныйЭтап(stages, "05-after-full-socket-sink")
        #expect(result == .недоступно)
        #expect(fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags)
        try Self.сохранитьТранспортнуюПробу("full-socket",
            ["исход": String(describing: result), "productionНс": String(elapsed),
             "largeFillCalls": largeCalls, "smallFillCalls": smallCalls,
             "largeFillBytes": largeBytes, "smallFillBytes": smallBytes,
             "singleByteEAGAINObserved": reached,
             "rawДоSetup": setupBefore, "rawПослеSetup": setupAfter,
             "флагиДо": flags, "флагиПосле": fcntl(writer, F_GETFL),
             "fdФлагиДо": fdFlags, "fdФлагиПосле": fcntl(writer, F_GETFD),
             "флагиСохранены": fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags])
    }
    @Test("K18 OS: blocking/unsafe FIFO пропускается, owned NONBLOCK+NOSIGPIPE FIFO доставляет и переживает closed peer")
    func собственныйFIFOСЯвнымиБезопаснымиФлагами() throws {
        let stages = try Self.начатьТранспортныеМетки("fifo")
        try Self.отметитьТранспортныйЭтап(stages, "00-enter")
        var pair = [Int32](repeating: -1, count: 2)
        try #require(pipe(&pair) == 0)
        let reader = pair[0], writer = pair[1]
        var readerOpen = true
        defer { _ = Darwin.close(writer); if readerOpen { _ = Darwin.close(reader) } }
        let flags = fcntl(writer, F_GETFL), fdFlags = fcntl(writer, F_GETFD)
        let oldReaderFlags = fcntl(reader, F_GETFL)
        try #require(fcntl(reader, F_SETFL, oldReaderFlags | O_NONBLOCK) == 0)
        let sink = ПриёмникДиагностикиStopV4.дескриптор(writer)
        try Self.отметитьТранспортныйЭтап(stages, "01-before-unsafe-sink")
        let unsafe = sink.передать(Self.транспортноеНаблюдение())
        try Self.отметитьТранспортныйЭтап(stages, "02-after-unsafe-sink")
        #expect(unsafe == .недоступно)
        #expect(fcntl(writer, F_GETFL) == flags && fcntl(writer, F_GETFD) == fdFlags)
        var empty: UInt8 = 0
        try Self.отметитьТранспортныйЭтап(stages, "03-before-empty-nonblock-read")
        let e = Darwin.read(reader, &empty, 1)
        let readErrno = errno
        try Self.отметитьТранспортныйЭтап(stages, "04-after-empty-nonblock-read")
        #expect(e == -1 && (readErrno == EAGAIN || readErrno == EWOULDBLOCK))
        try #require(fcntl(writer, F_SETFL, flags | O_NONBLOCK) == 0)
        try #require(fcntl(writer, F_SETNOSIGPIPE, 1) == 0)
        let safeFlags = fcntl(writer, F_GETFL)
        try #require(safeFlags >= 0 && safeFlags & O_NONBLOCK != 0 && fcntl(writer, F_GETNOSIGPIPE) == 1)
        try Self.отметитьТранспортныйЭтап(stages, "05-own-safe-flags-set")
        try Self.отметитьТранспортныйЭтап(stages, "06-before-safe-sink")
        let delivered = sink.передать(Self.транспортноеНаблюдение())
        try Self.отметитьТранспортныйЭтап(stages, "07-after-safe-sink")
        #expect(delivered == .доставлено)
        var buffer = [UInt8](repeating: 0, count: 513)
        try Self.отметитьТранспортныйЭтап(stages, "08-before-safe-read")
        let n = buffer.withUnsafeMutableBytes { Darwin.read(reader, $0.baseAddress, $0.count) }
        try Self.отметитьТранспортныйЭтап(stages, "09-after-safe-read")
        try #require(n > 0 && n <= 512)
        #expect(Data(buffer.prefix(n)).last == 10)
        let writeHistoryBit: Int32 = 0x00010000
        // Только equality либо точное монотонное добавление известного публичному XNU бита.
        // Это квалифицированная проверка наблюдаемого перехода, а не подтверждение ABI ядра13432.
        func управляемыеФлагиСохранены(_ после: Int32) -> Bool {
            после == safeFlags || (safeFlags & writeHistoryBit == 0 && после == safeFlags | writeHistoryBit)
        }
        let afterWriteFlags = fcntl(writer, F_GETFL)
        #expect(управляемыеФлагиСохранены(afterWriteFlags) && afterWriteFlags & O_NONBLOCK != 0
            && fcntl(writer, F_GETFD) == fdFlags && fcntl(writer, F_GETNOSIGPIPE) == 1)
        let c = Darwin.close(reader); readerOpen = false
        try #require(c == 0)
        try Self.отметитьТранспортныйЭтап(stages, "03-before-closed-peer-sink")
        let closed = sink.передать(Self.транспортноеНаблюдение())
        try Self.отметитьТранспортныйЭтап(stages, "04-after-closed-peer-sink")
        #expect(closed == .недоступно)
        let afterClosedFlags = fcntl(writer, F_GETFL)
        #expect(afterClosedFlags == afterWriteFlags && afterClosedFlags & O_NONBLOCK != 0
            && fcntl(writer, F_GETFD) == fdFlags && fcntl(writer, F_GETNOSIGPIPE) == 1)
        try Self.сохранитьТранспортнуюПробу("fifo-safe-unsafe-and-closed-peer",
            ["unsafe": String(describing: unsafe), "unsafeEmptyReadReturn": e, "unsafeEmptyReadErrno": readErrno, "доставленоБайт": n,
             "closedPeer": String(describing: closed), "SIGPIPEПроцессВыжил": true,
             "флагиДо": safeFlags, "флагиПослеЗаписи": afterWriteFlags, "флагиПосле": afterClosedFlags,
             "rawДельтаПослеЗаписи": safeFlags ^ afterWriteFlags, "rawДельтаПослеClosedPeer": afterWriteFlags ^ afterClosedFlags,
             "rawСуммарнаяДельта": safeFlags ^ afterClosedFlags,
             "rawФлагиРавны": safeFlags == afterClosedFlags, "битИсторииЗаписи": writeHistoryBit,
             "fdФлагиДо": fdFlags, "fdФлагиПосле": fcntl(writer, F_GETFD),
             "NOSIGPIPEПосле": fcntl(writer, F_GETNOSIGPIPE),
             "управляемыеФлагиСохранены": управляемыеФлагиСохранены(afterWriteFlags) && afterClosedFlags == afterWriteFlags
                && fcntl(writer, F_GETFD) == fdFlags && fcntl(writer, F_GETNOSIGPIPE) == 1,
             "полученоBase64": Data(buffer.prefix(n)).base64EncodedString(),
             "трактовкаИстории": "Публичный XNU: FWASWRITTEN0x10000; соответствие установленному13432 не подтверждено",
             "signalDisposition": "UNKNOWN_UNCHANGED_BY_TEST", "soleOFDcustody": true])
    }
}

extension ПроверкиСтабильногоЯкоря {
    @Test("K15 valid legacy: реальные V2 bounded-complete и V3 continuation сохраняют literal output и diagnosticsV4 attempts0")
    func допустимыеПрофилиV2V3НеВызываютДиагностикуV4() throws {
        let stages = try Self.начатьТранспортныеМетки("legacy")
        try Self.отметитьТранспортныйЭтап(stages, "00-enter")
        let parent = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        let ф = try ФикстураНаследияStop(основание: URL(fileURLWithPath: parent))
        let snapshot2 = try ф.завершённый()
        let bytes2 = try ФикстураНаследияStop.json(snapshot2)
        try ФикстураНаследияStop.сохранить(bytes2, в: ф.состояние, права: 0o600)
        let audit = ф.корень.appendingPathComponent("v4-attempts.jsonl")
        let fd = open(audit.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        try #require(fd >= 0)
        defer { _ = Darwin.close(fd) }
        let diagnostics = ПриёмникДиагностикиStopV4 { bytes in
            Issue.record("V4 diagnostics вызвана для valid legacy профиля")
            let n = bytes.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
            return n == bytes.count ? .доставлено : .недоступно
        }
        let event = try ФикстураНаследияStop.json(ф.событие())
        try Self.отметитьТранспортныйЭтап(stages, "01-before-valid-v2")
        let response2 = КомандаStop.выполнить(ф.аргументы, ввод: event, диагностикаV4: diagnostics)
        try Self.отметитьТранспортныйЭтап(stages, "02-after-valid-v2")
        #expect(response2 == Data("{}\n".utf8))
        #expect(try Data(contentsOf: audit).isEmpty)
        let header2 = try Data(contentsOf: ф.заголовок)
        let current3 = ф.корень.appendingPathComponent("current-v3.json")
        let header3 = ф.корень.appendingPathComponent("header-v3.json")
        let claims3 = ф.корень.appendingPathComponent("claims-v3")
        try #require(mkdir(claims3.path, 0o700) == 0)
        var info = stat()
        try #require(lstat(claims3.path, &info) == 0 && info.st_mode & S_IFMT == S_IFDIR
            && info.st_mode & 0o7777 == 0o700 && info.st_uid == geteuid() && info.st_dev > 0 && info.st_ino > 0)
        let epoch = "00000000-0000-4000-8000-000000000301"
        let operation = "00000000-0000-4000-8000-000000000302"
        let step = "Проверить один адресный результат"
        var s3 = ф.снимок()
        s3["схема"] = "fum.текущие-обязательства-stop.3"
        s3["редакция"] = 7; s3["эпохаПродолжения"] = epoch; s3["операцияПродолжения"] = operation
        var observations = try #require(s3["наблюдения"] as? [String: Any])
        observations["следующаяРабота"] = step; s3["наблюдения"] = observations
        // Existing projection исключает headerSHA/lease/stamps: project вычислен до final header3.
        let project = try КомандаStop.основаниеСнимкаV3(ФикстураНаследияStop.json(s3))
        let now = Int64(Date().timeIntervalSince1970)
        let grant: [String: Any] = [
            "схема": "fum.stop-допуск-продолжения.1", "задача": ФикстураНаследияStop.задача,
            "узел": ФикстураНаследияStop.узел, "область": ФикстураНаследияStop.область,
            "поколение": ФикстураНаследияStop.поколение, "исходники": ФикстураНаследияStop.доставка,
            "эпоха": epoch, "операция": operation, "вид": "безопасный-шаг",
            "пункт": ФикстураНаследияStop.пункт, "следующаяРабота": step,
            "корневойДопускSHA256": String(repeating: "c", count: 64), "наблюдениеSHA256": project,
            "редакция": 7, "номер": 0, "выдан": now - 5, "действуетДо": now + 300,
            "каталогЗахватов": claims3.path, "устройствоКаталога": UInt64(info.st_dev),
            "inodeКаталога": UInt64(info.st_ino)]
        var h3 = try СинтетическийЯкорь.объект(header2)
        h3["схема"] = "fum.stop-заголовок.3"; h3["состояние"] = current3.path
        h3["состояниеV2"] = ф.состояние.path; h3["редакцияОт"] = 7; h3["редакцияДо"] = 7
        h3["допускПродолжения"] = grant
        let h3raw = try ФикстураНаследияStop.json(h3), h3hash = ФикстураНаследияStop.sha256(h3raw)
        try ФикстураНаследияStop.сохранить(h3raw, в: header3, права: 0o400)
        s3["заголовокSHA256"] = h3hash
        let s3raw = try ФикстураНаследияStop.json(s3)
        #expect(try КомандаStop.основаниеСнимкаV3(s3raw) == project)
        try ФикстураНаследияStop.сохранить(s3raw, в: current3, права: 0o600)
        var args3 = ф.аргументы
        for (key, value) in [("--профиль-наблюдений", "fum.текущие-обязательства-stop.3"),
            ("--состояние", current3.path), ("--заголовок", header3.path), ("--хэш-заголовка", h3hash)] {
            let i = try #require(args3.firstIndex(of: key)); args3[i + 1] = value
        }
        try Self.отметитьТранспортныйЭтап(stages, "03-before-valid-v3")
        let response3 = КомандаStop.выполнить(args3, ввод: event, диагностикаV4: diagnostics)
        try Self.отметитьТранспортныйЭтап(stages, "04-after-valid-v3")
        let expected = try ФикстураНаследияStop.json(["decision": "block", "reason":
            "FUM Stop V3: один сигнал по операции \(operation). \(step). Не расширяй допуск; представь точный исход ROOT. Повтор без принятого прогресса не разрешён."])
        #expect(response3 == expected)
        #expect(try Data(contentsOf: audit).isEmpty)
        let claim = try Data(contentsOf: claims3.appendingPathComponent(epoch + ".0.claim"))
        #expect(try СинтетическийЯкорь.объект(claim)["схема"] as? String == "fum.stop-захват-продолжения.1")
        #expect(try FileManager.default.contentsOfDirectory(atPath: claims3.path) == [epoch + ".0.claim"])
        var st = stat()
        #expect(lstat(claims3.appendingPathComponent(epoch + ".0.claim").path, &st) == 0
            && st.st_mode & 0o7777 == 0o400 && st.st_nlink == 1)
        #expect(try Data(contentsOf: ф.состояние) == bytes2)
        #expect(try Data(contentsOf: ф.заголовок) == header2)
        try ФикстураНаследияStop.сохранить(response2, в: ф.корень.appendingPathComponent("actual-v2-response.raw"), права: 0o600)
        try ФикстураНаследияStop.сохранить(response3, в: ф.корень.appendingPathComponent("actual-v3-response.raw"), права: 0o600)
        try Self.отметитьТранспортныйЭтап(stages, "05-after-assertions-and-retained-outputs")
        // Это полные valid synthetic legacy controls, а не V2/V3 text sentinels; Native host не вызывался.
    }
}

import Dispatch

private enum ОтказПараллельнойПробы: Error { case ожидание, запись }
private struct ИсходПараллельнойПробы: Sendable {
    let роль: String
    let данные: Data
    let ошибка: String
    let завершеноНс: UInt64
}
private func ожидатьРазрешениеПараллельнойПробы(_ fd: Int32) throws {
    var p = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
    guard Darwin.poll(&p, 1, 5000) == 1, p.revents & Int16(POLLIN) != 0
    else { throw ОтказПараллельнойПробы.ожидание }
    var byte: UInt8 = 0
    guard Darwin.read(fd, &byte, 1) == 1, byte == 1 else { throw ОтказПараллельнойПробы.ожидание }
}
private func отпуститьПараллельнуюПробу(_ fd: Int32) -> Bool {
    var byte: UInt8 = 1
    return withUnsafePointer(to: &byte) {
        Darwin.send(fd, $0, 1, Int32(MSG_DONTWAIT | MSG_NOSIGNAL)) == 1
    }
}
private func подтверждёнВходПараллельнойПробы(_ stream: AsyncStream<Bool>) async -> Bool {
    await withTaskGroup(of: Bool.self) { group in
        group.addTask { var iterator = stream.makeAsyncIterator(); return await iterator.next() ?? false }
        group.addTask {
            do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { return false }
            return false
        }
        let value = await group.next() ?? false
        group.cancelAll()
        return value
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K10: подтверждённый overlap двух callback, second UNKNOWN пока first held, затем единственный claim")
    func дваОдновременныхCallbackИспользуютОдинЗамок() async throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K10-two-overlapping-callbacks")
        let args = ф.аргументы, event = try ф.событие()
        var pair = [Int32](repeating: -1, count: 2)
        try #require(socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0)
        let waitFD = pair[0], releaseFD = pair[1]
        defer { _ = Darwin.close(waitFD); _ = Darwin.close(releaseFD) }
        let handshake = AsyncStream<Bool>.makeStream()
        let stream = handshake.stream, entered = handshake.continuation
        try await withThrowingTaskGroup(of: ИсходПараллельнойПробы.self) { group in
            var released = false
            defer { if !released { _ = отпуститьПараллельнуюПробу(releaseFD) } }
            group.addTask {
                defer { entered.finish() }
                let response = КомандаStop.выполнитьЧетвёртыйПрофиль(args, прочитать: { event },
                    диагностика: .init { _ in .недоступно },
                    точкиСинхронизации: .init(перед: { phase in
                        if phase == "снимок-файл" {
                            entered.yield(true); entered.finish()
                            try ожидатьРазрешениеПараллельнойПробы(waitFD)
                        }
                    }))
                return .init(роль: "first", данные: response, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
            }
            let ready = await подтверждёнВходПараллельнойПробы(stream)
            try #require(ready)
            let enteredNS = DispatchTime.now().uptimeNanoseconds
            let before = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
            try #require(before.isEmpty)
            group.addTask {
                let response = КомандаStop.выполнить(args, ввод: event)
                return .init(роль: "second", данные: response, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
            }
            let secondOptional = try await group.next()
            let second = try #require(secondOptional)
            try #require(second.роль == "second")
            let secondBlocks = try СинтетическийЯкорь.ответБлокирует(second.данные)
            try #require(!secondBlocks)
            let secondObject = try СинтетическийЯкорь.объект(second.данные)
            try #require((secondObject["stopReason"] as? String)?.contains("UNKNOWN") == true)
            let during = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
            try #require(during.isEmpty)
            let releaseNS = DispatchTime.now().uptimeNanoseconds
            released = true
            try #require(отпуститьПараллельнуюПробу(releaseFD))
            let firstOptional = try await group.next()
            let first = try #require(firstOptional)
            try #require(first.роль == "first")
            let firstBlocks = try СинтетическийЯкорь.ответБлокирует(first.данные)
            try #require(firstBlocks)
            let claims = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
            try #require(claims == [СинтетическийЯкорь.эпоха + ".0.claim"])
            let order = enteredNS <= second.завершеноНс && second.завершеноНс < releaseNS
                && releaseNS <= first.завершеноНс
            try #require(order)
            try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект([
                "схема": "fum.synthetic-overlap.1", "enteredNS": enteredNS,
                "secondFinishedNS": second.завершеноНс, "releaseNS": releaseNS,
                "firstFinishedNS": first.завершеноНс, "claimsBeforeRelease": 0, "claimsAfter": 1,
                "firstBlock": true, "secondUnknown": true, "barrierDeadlineMS": 5000] as [String: Any]),
                ф.корень.appendingPathComponent("overlap-proof.json"), права: 0o400)
        }
    }
    @Test("K11: publisher+publisher+callback overlap lock; stale expectedR0 CAS отдельно после winnerR1")
    func дваИздателяИCallbackПроверяютЗамокИОтдельныйCAS() async throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K11-publishers-callback-overlap-and-separate-stale-CAS")
        let old = try Data(contentsOf: ф.указатель)
        let a = try СинтетическийВыпускЯкоря(ф, публикация: 1,
            операция: UUID().uuidString.lowercased(), предыдущий: old)
        let b = try СинтетическийВыпускЯкоря(ф, публикация: 1,
            операция: UUID().uuidString.lowercased(), предыдущий: old)
        let planA = try a.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
        let planB = try b.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
        let args = ф.аргументы, event = try ф.событие(), headerSHA = ф.хэшЗаголовка
        let initialLedger = try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("adoptions").path).sorted()
        let initialReceipts = try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("receipts").path).sorted()
        var pair = [Int32](repeating: -1, count: 2)
        try #require(socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0)
        let waitFD = pair[0], releaseFD = pair[1]
        defer { _ = Darwin.close(waitFD); _ = Darwin.close(releaseFD) }
        let handshake = AsyncStream<Bool>.makeStream()
        let stream = handshake.stream, entered = handshake.continuation
        try await withThrowingTaskGroup(of: ИсходПараллельнойПробы.self) { group in
            var released = false
            defer { if !released { _ = отпуститьПараллельнуюПробу(releaseFD) } }
            group.addTask {
                defer { entered.finish() }
                do {
                    let terminal = try КомандаStop.опубликоватьДопускV4(planA, ожидаемыйЗаголовокSHA256: headerSHA,
                        точки: .init(событие: { phase in
                            if phase == "намерение-перед-созданием" {
                                entered.yield(true); entered.finish()
                                try ожидатьРазрешениеПараллельнойПробы(waitFD)
                            }
                        }))
                    return .init(роль: "P1", данные: terminal, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
                } catch {
                    return .init(роль: "P1", данные: Data(), ошибка: "error", завершеноНс: DispatchTime.now().uptimeNanoseconds)
                }
            }
            let ready = await подтверждёнВходПараллельнойПробы(stream)
            try #require(ready)
            let enteredNS = DispatchTime.now().uptimeNanoseconds
            group.addTask {
                do {
                    let terminal = try КомандаStop.опубликоватьДопускV4(planB, ожидаемыйЗаголовокSHA256: headerSHA)
                    return .init(роль: "P2", данные: terminal, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
                } catch {
                    let kind = String(describing: error).hasPrefix("Lbusy:") ? "Lbusy" : "other"
                    return .init(роль: "P2", данные: Data(), ошибка: kind, завершеноНс: DispatchTime.now().uptimeNanoseconds)
                }
            }
            let secondOptional = try await group.next()
            let second = try #require(secondOptional)
            try #require(second.роль == "P2" && second.ошибка == "Lbusy")
            group.addTask {
                let response = КомандаStop.выполнить(args, ввод: event)
                return .init(роль: "callback", данные: response, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
            }
            let callbackOptional = try await group.next()
            let callback = try #require(callbackOptional)
            try #require(callback.роль == "callback")
            let callbackObject = try СинтетическийЯкорь.объект(callback.данные)
            try #require((callbackObject["stopReason"] as? String)?.contains("UNKNOWN") == true)
            let beforeReleaseClaims = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
            try #require(beforeReleaseClaims.isEmpty)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("adoptions").path).sorted() == initialLedger)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("receipts").path).sorted() == initialReceipts)
            let releaseNS = DispatchTime.now().uptimeNanoseconds
            released = true
            try #require(отпуститьПараллельнуюПробу(releaseFD))
            let winnerOptional = try await group.next()
            let winner = try #require(winnerOptional)
            try #require(winner.роль == "P1" && winner.ошибка.isEmpty)
            let terminal = try СинтетическийЯкорь.объект(winner.данные)
            try #require(terminal["исход"] as? String == "ОПУБЛИКОВАНО")
            #expect(try Data(contentsOf: ф.указатель) == a.конверт)
            let bPayload = try СинтетическийЯкорь.объект(b.нагрузка)
            let headB = try #require(bPayload["HEAD"] as? String)
            let issuedB = try #require(bPayload["выдан"] as? Int64)
            let expiresB = try #require(bPayload["действуетДо"] as? Int64)
            let now = Int64(Date().timeIntervalSince1970)
            try #require(issuedB <= now && now <= expiresB)
            let gitRef = ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master")
            let actualGit = try String(contentsOf: gitRef, encoding: .utf8)
            try #require(actualGit == headB + "\n")
            // Новый отдельный negative call: прежний busy до эффекта, теперь намеренно stale expectedR0.
            var casRejected = false
            do {
                _ = try КомандаStop.опубликоватьДопускV4(planB, ожидаемыйЗаголовокSHA256: headerSHA)
                Issue.record("Проигравший expectedR0 plan не должен пройти после winnerR1")
            } catch КорневойДопускStopV4.Отказ.цепь { casRejected = true }
            try #require(casRejected)
            let bIntent = ф.корень.appendingPathComponent("receipts/" + b.операция + ".1.intent.json")
            try #require(СинтетическийЯкорь.отсутствует(bIntent))
            try #require(СинтетическийЯкорь.отсутствует(ф.путьИсхода(b)))
            let response = КомандаStop.выполнить(args, ввод: event)
            let blocks = try СинтетическийЯкорь.ответБлокирует(response)
            try #require(blocks)
            let claims = try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path)
            try #require(claims == [СинтетическийЯкорь.эпоха + ".0.claim"])
            let order = enteredNS <= second.завершеноНс && second.завершеноНс < callback.завершеноНс
                && callback.завершеноНс < releaseNS && releaseNS <= winner.завершеноНс
            try #require(order)
            try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект([
                "схема": "fum.synthetic-overlap-and-CAS.1", "enteredNS": enteredNS,
                "P2BusyFinishedNS": second.завершеноНс, "callbackFinishedNS": callback.завершеноНс,
                "releaseNS": releaseNS, "P1PublishedNS": winner.завершеноНс,
                "beforeReleaseClaims": 0, "afterClaims": 1, "sameCurrentHEAD": headB,
                "P2LeaseFreshAtCAS": true, "P2CASChainRejectedBeforeIntent": casRejected,
                "barrierDeadlineMS": 5000] as [String: Any]),
                ф.корень.appendingPathComponent("overlap-and-CAS-proof.json"), права: 0o400)
        }
    }
}

extension ПроверкиСтабильногоЯкоря {
    @Test("K08: rollback pointer к ещё свежему R0 при полной R1M1 не даёт unused ordinal0")
    func откатУказателяНаПредыдущийДопускНеВыдаётЗахват() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K08-pointer-rollback-with-unused-ordinal")
        let old = try Data(contentsOf: ф.указатель), headerRaw = try Data(contentsOf: ф.заголовок)
        let next = try СинтетическийВыпускЯкоря(ф, публикация: 1,
            операция: UUID().uuidString.lowercased(), предыдущий: old)
        let plan = try next.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
        _ = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        let marker1 = try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/1.завершение.json"))
        let header = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: headerRaw, предел: 32_768)
        // Контролируемая атака только на mutable pointer собственной synthetic fixture; оригиналы R0/R1 сохранены.
        _ = try ЗамокТекущегоStop.выполнить(header.замок) { check in
            try АтомарныеБайтыStop.заменитьУказательV4(ф.указатель.path,
                ожидаемыйSHA256: next.конвертSHA, новыми: old, проверить: check, отметить: { _ in })
        }
        let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let obj = try СинтетическийЯкорь.объект(response)
        #expect((obj["stopReason"] as? String)?.contains("UNKNOWN") == true)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
        #expect(try Data(contentsOf: ф.указатель) == old)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/1.допуск.json")) == next.конверт)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/1.завершение.json")) == marker1)
        #expect(try Data(contentsOf: ф.заголовок) == headerRaw)
        try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("rollback-response.raw"), права: 0o600)
    }
    @Test("K07 variants: иной turn/active и valid новая publication/op/revision не переоткрывают epoch.ordinal")
    func новыеTurnИПубликацияНеПереоткрываютПотраченныйНомер() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K07-turn-active-and-new-valid-publication-same-ordinal")
        let first = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let firstBlocks = try СинтетическийЯкорь.ответБлокирует(first)
        try #require(firstBlocks)
        let claimPath = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
        let claim = try Data(contentsOf: claimPath), old = try Data(contentsOf: ф.указатель)
        var event = try СинтетическийЯкорь.объект(ф.событие())
        event["turn_id"] = "another-v4-turn"; event["stop_hook_active"] = true
        let rawEvent = try СинтетическийЯкорь.кодироватьОбъект(event)
        let replay = КомандаStop.выполнить(ф.аргументы, ввод: rawEvent)
        #expect(try !СинтетическийЯкорь.ответБлокирует(replay))
        #expect(try Data(contentsOf: claimPath) == claim)
        let next = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 0,
            операция: UUID().uuidString.lowercased(), предыдущий: old, изменитьСнимок: { s in
                s["редакция"] = 8
                var n = try #require(s["наблюдения"] as? [String: Any])
                n["следующаяРабота"] = "Новый подписанный шаг при уже потраченном ordinal"
                s["наблюдения"] = n
            })
        let plan = try next.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
        let published = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        #expect(try СинтетическийЯкорь.объект(published)["исход"] as? String == "ОПУБЛИКОВАНО")
        let response = КомандаStop.выполнить(ф.аргументы, ввод: rawEvent)
        #expect(try !СинтетическийЯкорь.ответБлокирует(response))
        #expect(try Data(contentsOf: claimPath) == claim)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path) == [claimPath.lastPathComponent])
        #expect(try Data(contentsOf: ф.указатель) == next.конверт)
        try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("new-publication-spent-response.raw"), права: 0o600)
    }
    @Test("K14: symlink/hardlink/directory/lock inode/directory pin attacks сохраняют оригиналы и не дают claim")
    func физическиеПодменыНеПроходятЗакреплённыеГраницы() throws {
        for row in 0..<5 {
            let ф = try СинтетическийЯкорь.новаяФикстура()
            try ф.сохранитьНазваниеПроверки("K14-physical-" + String(row))
            let originalPaths = [ф.заголовок,
                ф.корень.appendingPathComponent("snapshots/" + ф.хэшСнимка + ".json"),
                ф.указатель, ф.корень.appendingPathComponent("root-grant.json.lock"), ф.захваты]
            let retainedPaths = [ф.корень.appendingPathComponent("retained-original-header.json"),
                ф.корень.appendingPathComponent("retained-extra-snapshot-hardlink.json"),
                ф.корень.appendingPathComponent("retained-original-pointer.json"),
                ф.корень.appendingPathComponent("retained-original-lock"),
                ф.корень.appendingPathComponent("retained-original-claim-directory")]
            let originalPath = originalPaths[row], retainedPath = retainedPaths[row]
            var before = stat()
            try #require(lstat(originalPath.path, &before) == 0)
            let originalBytes: Data
            let originalNames: [String]
            if row == 4 {
                originalBytes = Data()
                originalNames = try FileManager.default.contentsOfDirectory(atPath: originalPath.path).sorted()
            } else { originalBytes = try Data(contentsOf: originalPath); originalNames = [] }
            if row == 0 {
                let retained = ф.корень.appendingPathComponent("retained-original-header.json")
                try FileManager.default.moveItem(at: ф.заголовок, to: retained)
                try FileManager.default.createSymbolicLink(at: ф.заголовок, withDestinationURL: retained)
            }
            if row == 1 {
                let snapshot = ф.корень.appendingPathComponent("snapshots/" + ф.хэшСнимка + ".json")
                try FileManager.default.linkItem(at: snapshot,
                    to: ф.корень.appendingPathComponent("retained-extra-snapshot-hardlink.json"))
            }
            if row == 2 {
                try FileManager.default.moveItem(at: ф.указатель,
                    to: ф.корень.appendingPathComponent("retained-original-pointer.json"))
                try #require(mkdir(ф.указатель.path, 0o700) == 0)
            }
            if row == 3 {
                let lock = ф.корень.appendingPathComponent("root-grant.json.lock")
                try FileManager.default.moveItem(at: lock,
                    to: ф.корень.appendingPathComponent("retained-original-lock"))
                try СинтетическийЯкорь.сохранить(Data(), lock, права: 0o600)
            }
            if row == 4 {
                try FileManager.default.moveItem(at: ф.захваты,
                    to: ф.корень.appendingPathComponent("retained-original-claim-directory"))
                try #require(mkdir(ф.захваты.path, 0o700) == 0)
            }
            let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
            let object = try СинтетическийЯкорь.объект(response)
            #expect((object["stopReason"] as? String)?.contains("UNKNOWN") == true)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
            try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("physical-response.raw"), права: 0o600)
            var after = stat()
            try #require(lstat(retainedPath.path, &after) == 0)
            #expect(after.st_dev == before.st_dev && after.st_ino == before.st_ino)
            #expect(after.st_mode == before.st_mode && after.st_uid == before.st_uid)
            #expect(after.st_size == before.st_size)
            #expect(after.st_nlink == (row == 1 ? before.st_nlink + 1 : before.st_nlink))
            #expect(after.st_mtimespec.tv_sec == before.st_mtimespec.tv_sec
                && after.st_mtimespec.tv_nsec == before.st_mtimespec.tv_nsec)
            if row == 4 {
                #expect(try FileManager.default.contentsOfDirectory(atPath: retainedPath.path).sorted() == originalNames)
            } else { #expect(try Data(contentsOf: retainedPath) == originalBytes) }
            if row == 1 {
                var linked = stat()
                try #require(lstat(originalPath.path, &linked) == 0)
                #expect(linked.st_dev == before.st_dev && linked.st_ino == before.st_ino && linked.st_nlink == 2)
                #expect(try Data(contentsOf: originalPath) == originalBytes)
            }
            var proof: [String: Any] = ["схема": "fum.synthetic-physical-original-preservation.1", "row": row,
                "beforeDev": UInt64(before.st_dev), "afterDev": UInt64(after.st_dev),
                "beforeInode": UInt64(before.st_ino), "afterInode": UInt64(after.st_ino),
                "beforeMode": UInt64(before.st_mode), "afterMode": UInt64(after.st_mode),
                "beforeUID": UInt64(before.st_uid), "afterUID": UInt64(after.st_uid),
                "beforeNlink": UInt64(before.st_nlink), "afterNlink": UInt64(after.st_nlink),
                "ctime": "Expected to change by controlled rename/link; not claimed unchanged"]
            if row == 4 { proof["retainedNames"] = originalNames }
            else { proof["retainedBytesSHA256"] = СинтетическийЯкорь.хэш(originalBytes) }
            try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект(proof),
                ф.корень.appendingPathComponent("physical-preservation-proof.json"), права: 0o400)
            // Все перемещённые/связанные original objects оставлены; cleanup/rollback отсутствуют.
        }
    }
    @Test("K14/K15 after O_EXCL: partial/spent token и metadata UNKNOWN сохраняются без retry/удаления")
    func отказПослеExclusiveCreateСохраняетПотраченныйНомер() throws {
        for row in 0..<3 {
            let ф = try СинтетическийЯкорь.новаяФикстура()
            try ф.сохранитьНазваниеПроверки("K14-post-exclusive-" + String(row))
            let audit = ф.корень.appendingPathComponent("post-exclusive-metadata.jsonl")
            let fd = open(audit.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            try #require(fd >= 0)
            defer { _ = Darwin.close(fd) }
            let diagnostics = ПриёмникДиагностикиStopV4 { data in
                let n = data.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
                return n == data.count ? .доставлено : .недоступно
            }
            var points = КонечноеПродолжениеStop.ТочкиЗахвата()
            if row == 0 { points.послеСоздания = { throw ОтказПубликационнойПробыV4.намеренный } }
            if row == 1 { points.передСинхронизацией = { throw ОтказПубликационнойПробыV4.намеренный } }
            if row == 2 { points.передПодтверждением = { throw ОтказПубликационнойПробыV4.намеренный } }
            let event = try ф.событие()
            let response = КомандаStop.выполнитьЧетвёртыйПрофиль(ф.аргументы,
                прочитать: { event }, диагностика: diagnostics, точкиЗахвата: points)
            #expect(try !СинтетическийЯкорь.ответБлокирует(response))
            let token = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
            let bytes = try Data(contentsOf: token)
            var s = stat()
            try #require(lstat(token.path, &s) == 0)
            #expect(s.st_mode & S_IFMT == S_IFREG && s.st_uid == geteuid() && s.st_nlink == 1)
            #expect(s.st_mode & 0o7777 == (row == 0 ? 0o600 : 0o400))
            #expect(row == 0 ? bytes.isEmpty : !bytes.isEmpty)
            try #require(fsync(fd) == 0)
            let entries = try Data(contentsOf: audit).split(separator: 10).map {
                try СинтетическийЯкорь.объект(Data($0))
            }
            try #require(entries.count == 2)
            #expect(entries[1]["фаза"] as? String == "выход")
            #expect(entries[1]["захват"] as? String == "UNKNOWN")
            #expect(entries[1]["исход"] as? String == "UNKNOWN")
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path) == [token.lastPathComponent])
            try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("post-exclusive-response.raw"), права: 0o600)
            // Не повторяем callback/publisher/claim: сохранившийся token расходует ordinal даже при UNKNOWN.
        }
    }
}

private extension СинтетическийВыпускЯкоря {
    /// Только отрицательный стенд: publisher обязан отказать; затем атакующий подставляет полный R1/M1
    /// для независимой проверки callback. Это не успешная публикация и не квитанция исполнения.
    func установитьОтрицательныйНаборПослеОтказа(_ ф: СинтетическийЯкорь, прежний: Data) throws {
        try #require(публикация == 1)
        let h = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: Data(contentsOf: ф.заголовок), предел: 32_768)
        _ = try ЗамокТекущегоStop.выполнить(h.замок) { check in
            try check()
            try СинтетическийЯкорь.сохранить(сохранённыйСнимок,
                ф.корень.appendingPathComponent("snapshots/" + снимокSHA + ".json"), права: 0o400)
            try СинтетическийЯкорь.сохранить(конверт,
                ф.корень.appendingPathComponent("adoptions/1.допуск.json"), права: 0o400)
            _ = try АтомарныеБайтыStop.заменитьУказательV4(ф.указатель.path,
                ожидаемыйSHA256: СинтетическийЯкорь.хэш(прежний), новыми: конверт,
                проверить: check, отметить: { _ in })
            try СинтетическийЯкорь.сохранить(маркер,
                ф.корень.appendingPathComponent("adoptions/1.завершение.json"), права: 0o400)
            try check()
        }
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K09: signed missing/forged progress и неверный result SHA отвергаются publisher и callback")
    func неподтверждённыйПрогрессНеДаётСледующийНомер() throws {
        for row in 0..<4 {
            let ф = try СинтетическийЯкорь.новаяФикстура()
            try ф.сохранитьНазваниеПроверки("K09-progress-attack-" + String(row))
            let old = try Data(contentsOf: ф.указатель)
            let oldEnvelope = try СинтетическийЯкорь.объект(old)
            let encodedPayload = try #require(oldEnvelope["полезнаяНагрузкаBase64"] as? String)
            let payloadBytes = try #require(Data(base64Encoded: encodedPayload))
            let oldPayload = try СинтетическийЯкорь.объект(payloadBytes)
            let first = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
            let blocks = try СинтетическийЯкорь.ответБлокирует(first)
            try #require(blocks)
            let c0URL = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
            let c0 = try Data(contentsOf: c0URL)
            let op = UUID().uuidString.lowercased()
            let mutate: (inout [String: Any]) throws -> Void = { s in
                s["редакция"] = 8
                var n = try #require(s["наблюдения"] as? [String: Any])
                n["следующаяРабота"] = "Следующий подписанный шаг с отдельным принятым прогрессом"
                s["наблюдения"] = n
            }
            let preview = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
                операция: op, предыдущий: old, предыдущаяОперация: СинтетическийЯкорь.операция,
                изменитьСнимок: mutate)
            var progress: [String: Any]? = nil
            if row > 0 {
                let base = try ф.сохранитьПрогрессПослеClaim(c0, прежняяНагрузка: oldPayload, следующий: preview)
                if row == 3 {
                    progress = ["путь": op + ".absent-progress.json", "sha256": String(repeating: "f", count: 64)]
                } else {
                    let baseName = try #require(base["путь"] as? String)
                    var forged = try СинтетическийЯкорь.объект(Data(contentsOf:
                        ф.корень.appendingPathComponent("receipts/" + baseName)))
                    if row == 1 { forged["предыдущийЗахватSHA256"] = String(repeating: "f", count: 64) }
                    if row == 2 {
                        var result = try #require(forged["результат"] as? [String: Any])
                        result["sha256"] = String(repeating: "f", count: 64); forged["результат"] = result
                    }
                    let raw = try СинтетическийЯкорь.кодироватьОбъект(forged)
                    let name = op + ".forged-progress.json"
                    try СинтетическийЯкорь.сохранить(raw,
                        ф.корень.appendingPathComponent("receipts/" + name), права: 0o400)
                    progress = ["путь": name, "sha256": СинтетическийЯкорь.хэш(raw)]
                }
            }
            let next = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
                операция: op, предыдущий: old, предыдущаяОперация: СинтетическийЯкорь.операция,
                прогресс: progress, изменитьСнимок: mutate)
            let plan = try next.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
            var rejected = false
            do { _ = try КомандаStop.проверитьПубликациюV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка) }
            catch КорневойДопускStopV4.Отказ.цепь where row == 0 { rejected = true }
            catch КонечноеПродолжениеStop.Отказ.прогресс where row == 1 || row == 2 { rejected = true }
            catch where row == 3 { rejected = true }
            try #require(rejected)
            try #require(СинтетическийЯкорь.отсутствует(ф.корень.appendingPathComponent("receipts/" + op + ".1.intent.json")))
            try #require(try Data(contentsOf: ф.указатель) == old)
            try next.установитьОтрицательныйНаборПослеОтказа(ф, прежний: old)
            let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
            let object = try СинтетическийЯкорь.объект(response)
            #expect((object["stopReason"] as? String)?.contains("UNKNOWN") == true)
            #expect(try Data(contentsOf: c0URL) == c0)
            #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path) == [c0URL.lastPathComponent])
            try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("progress-attack-response.raw"), права: 0o600)
        }
    }
    @Test("K09 historical binding: forged claim decision не обходит сравнение с authenticated R0")
    func полныйПрежнийЗахватСвязанСПодписаннойИсторией() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K09-forged-prior-root-decision-full-history-binding")
        let old = try Data(contentsOf: ф.указатель)
        let envelope = try СинтетическийЯкорь.объект(old)
        let encoded = try #require(envelope["полезнаяНагрузкаBase64"] as? String)
        let payloadBytes = try #require(Data(base64Encoded: encoded))
        let oldPayload = try СинтетическийЯкорь.объект(payloadBytes)
        let actualD0 = try #require(oldPayload["корневойДопускSHA256"] as? String)
        let first = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let blocks = try СинтетическийЯкорь.ответБлокирует(first)
        try #require(blocks)
        let c0URL = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
        let original = try Data(contentsOf: c0URL)
        var forgedObject = try СинтетическийЯкорь.объект(original)
        let fake = String(repeating: actualD0 == String(repeating: "f", count: 64) ? "e" : "f", count: 64)
        forgedObject["корневойДопускSHA256"] = fake
        let forged = try СинтетическийЯкорь.кодироватьОбъект(forgedObject)
        try FileManager.default.moveItem(at: c0URL, to: ф.корень.appendingPathComponent("retained-authentic-claim0.json"))
        try СинтетическийЯкорь.сохранить(forged, c0URL, права: 0o400)
        let op = UUID().uuidString.lowercased()
        let mutate: (inout [String: Any]) throws -> Void = { s in
            s["редакция"] = 8
            var n = try #require(s["наблюдения"] as? [String: Any])
            n["следующаяРабота"] = "Атака с reused actualD0 и forged priorD"
            s["наблюдения"] = n
        }
        let decision: (inout [String: Any]) throws -> Void = { $0["корневойДопускSHA256"] = actualD0 }
        let preview = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
            операция: op, предыдущий: old, предыдущаяОперация: СинтетическийЯкорь.операция,
            изменитьСнимок: mutate, изменитьНагрузку: decision)
        let progress = try ф.сохранитьПрогрессПослеClaim(forged, прежняяНагрузка: oldPayload, следующий: preview)
        let next = try СинтетическийВыпускЯкоря(ф, публикация: 1, номер: 1,
            операция: op, предыдущий: old, предыдущаяОперация: СинтетическийЯкорь.операция,
            прогресс: progress, изменитьСнимок: mutate, изменитьНагрузку: decision)
        let plan = try next.сохранитьКандидат(ф, ожидаемый: СинтетическийЯкорь.хэш(old))
        var rejected = false
        do { _ = try КомандаStop.проверитьПубликациюV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка) }
        catch КонечноеПродолжениеStop.Отказ.прогресс { rejected = true }
        try #require(rejected && actualD0 != fake && next.решениеSHA == actualD0)
        try next.установитьОтрицательныйНаборПослеОтказа(ф, прежний: old)
        let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let object = try СинтетическийЯкорь.объект(response)
        #expect((object["stopReason"] as? String)?.contains("UNKNOWN") == true)
        #expect(try Data(contentsOf: c0URL) == forged)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("retained-authentic-claim0.json")) == original)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path) == [c0URL.lastPathComponent])
        try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("historical-binding-response.raw"), права: 0o600)
    }
}

extension ПроверкиСтабильногоЯкоря {
    @Test("K13 actual lease: expiry во время каждого outcome effect возвращает UNKNOWN и сохраняет prepared bytes")
    func истечениеLeaseПриСохраненииИсходаНеДаётSuccess() async throws {
        let phases = ["исход-после-создания", "исход-после-записи", "исход-после-fsync-файла",
            "исход-после-fsync-каталога", "исход-после-readback"]
        for phase in phases {
            let ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
            try ф.сохранитьНазваниеПроверки("K13-lease-outcome-" + phase)
            let now = Int64(Date().timeIntervalSince1970), expiry = now + 2
            let release = try СинтетическийВыпускЯкоря(ф, изменитьНагрузку: { p in
                p["выдан"] = now - 5; p["действуетДо"] = expiry
            })
            let plan = try release.сохранитьКандидат(ф, ожидаемый: nil), headerSHA = ф.хэшЗаголовка
            var pair = [Int32](repeating: -1, count: 2)
            try #require(socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0)
            let waitFD = pair[0], releaseFD = pair[1]
            defer { _ = Darwin.close(waitFD); _ = Darwin.close(releaseFD) }
            let handshake = AsyncStream<Bool>.makeStream()
            let stream = handshake.stream, entered = handshake.continuation
            let acknowledgement = AsyncStream<Bool>.makeStream()
            let ackStream = acknowledgement.stream, ack = acknowledgement.continuation
            try await withThrowingTaskGroup(of: ИсходПараллельнойПробы.self) { group in
                var released = false
                defer { if !released { _ = отпуститьПараллельнуюПробу(releaseFD) } }
                group.addTask {
                    defer { entered.finish(); ack.finish() }
                    do {
                        let terminal = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: headerSHA,
                            точки: .init(событие: { event in
                                if event == phase {
                                    entered.yield(true); entered.finish()
                                    try ожидатьРазрешениеПараллельнойПробы(waitFD)
                                    ack.yield(true); ack.finish()
                                }
                            }))
                        return .init(роль: "unexpected-success", данные: terminal, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
                    } catch let e as ОтказПубликацииStopV4 {
                        let raw = try СинтетическийЯкорь.кодироватьОбъект([
                            "фаза": e.фаза, "возможенЭффект": e.возможенЭффект,
                            "исходКвитанции": e.исходКвитанции] as [String: Any])
                        return .init(роль: "known-publication-refusal", данные: raw, ошибка: "", завершеноНс: DispatchTime.now().uptimeNanoseconds)
                    }
                }
                let ready = await подтверждёнВходПараллельнойПробы(stream)
                try #require(ready)
                let nowAtFence = Int64(Date().timeIntervalSince1970)
                try #require(nowAtFence <= expiry)
                let waitStart = DispatchTime.now().uptimeNanoseconds
                // Только фактическое истечение signed lease. Не искусственная пауза ради RSS/времени.
                let remaining = Double(expiry) + 1.05 - Date().timeIntervalSince1970
                try #require(remaining > 0 && remaining <= 4)
                try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                let afterExpiry = Int64(Date().timeIntervalSince1970)
                try #require(afterExpiry > expiry)
                let releaseNS = DispatchTime.now().uptimeNanoseconds
                released = true
                try #require(отпуститьПараллельнуюПробу(releaseFD))
                let normalHookReturn = await подтверждёнВходПараллельнойПробы(ackStream)
                try #require(normalHookReturn)
                let acknowledgementNS = DispatchTime.now().uptimeNanoseconds
                let optional = try await group.next()
                let outcome = try #require(optional)
                try #require(outcome.роль == "known-publication-refusal")
                try #require(releaseNS <= outcome.завершеноНс)
                let object = try СинтетическийЯкорь.объект(outcome.данные)
                #expect(object["возможенЭффект"] as? Bool == true)
                #expect(object["исходКвитанции"] as? String == "UNKNOWN_ПОСЛЕ_ПОПЫТКИ")
                let saved = try Data(contentsOf: ф.путьИсхода(release))
                if phase == "исход-после-создания" { #expect(saved.isEmpty) }
                else { #expect(try СинтетическийЯкорь.объект(saved)["исход"] as? String == "ПОДГОТОВЛЕННЫЙ_ИСХОД") }
                #expect(try Data(contentsOf: ф.указатель) == release.конверт)
                #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json")) == release.маркер)
                let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
                let responseObject = try СинтетическийЯкорь.объект(response)
                #expect((responseObject["stopReason"] as? String)?.contains("UNKNOWN") == true)
                #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
                #expect(try Data(contentsOf: ф.путьИсхода(release)) == saved)
                try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("lease-outcome-response.raw"), права: 0o600)
                try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект([
                    "схема": "fum.synthetic-lease-expiry-at-outcome.1", "точка": phase,
                    "leaseExpiry": expiry, "nowAtFence": nowAtFence, "observedAfterExpiry": afterExpiry,
                    "waitStartNS": waitStart, "releaseNS": releaseNS, "acknowledgementNS": acknowledgementNS,
                    "hookWaitReturnedNormally": normalHookReturn,
                    "publicationReturnedNS": outcome.завершеноНс,
                    "maximumSemanticWaitSecondsPerRow": 4,
                    "publisherRefusal": object, "PID": getpid(), "PGID": getpgrp()] as [String: Any]),
                    ф.корень.appendingPathComponent("lease-outcome-proof.json"), права: 0o400)
            }
        }
    }
}

private extension СинтетическийЯкорь {
    /// Unit fixture: подписанные R/M1...127 создаёт стенд, не public publisher.
    /// Квитанций исторического исполнения/публикации этим не утверждаем.
    func посеятьСинтетическуюИсториюДо127(последнийНомер127: Bool) throws -> СинтетическийВыпускЯкоря {
        let original = try Data(contentsOf: указатель)
        let h = try КорневойДопускStopV4.разобрать(КорневойДопускStopV4.Заголовок.self,
            из: Data(contentsOf: заголовок), предел: 32_768)
        let final = try ЗамокТекущегоStop.выполнить(h.замок) { check in
            var previous = original
            var previousOperation = Self.операция
            var last: СинтетическийВыпускЯкоря?
            for index in UInt64(1)...UInt64(127) {
                try check()
                let high = последнийНомер127 && index == 127
                let op = UUID().uuidString.lowercased()
                let release = try СинтетическийВыпускЯкоря(self, публикация: index, номер: high ? 127 : 0,
                    операция: op, предыдущий: previous,
                    предыдущаяОперация: high ? previousOperation : nil,
                    прогресс: high ? ["путь": "seed-only-unused-historical-progress.json", "sha256": String(repeating: "f", count: 64)] : nil)
                try Self.сохранить(release.сохранённыйСнимок,
                    корень.appendingPathComponent("snapshots/" + release.снимокSHA + ".json"), права: 0o400)
                try Self.сохранить(release.конверт,
                    корень.appendingPathComponent("adoptions/" + String(index) + ".допуск.json"), права: 0o400)
                try Self.сохранить(release.маркер,
                    корень.appendingPathComponent("adoptions/" + String(index) + ".завершение.json"), права: 0o400)
                previous = release.конверт; previousOperation = release.операция; last = release
            }
            let final = try #require(last)
            _ = try АтомарныеБайтыStop.заменитьУказательV4(указатель.path,
                ожидаемыйSHA256: Self.хэш(original), новыми: final.конверт, проверить: check, отметить: { _ in })
            return final
        }
        try Self.сохранить(Self.кодироватьОбъект([
            "схема": "fum.synthetic-history-seed-origin.1", "records": 128, "markers": 128,
            "seededPublications": "0...127", "publicPublisherCallsForSeed": 0,
            "historicalExecutionEvidence": "NOT_PROVED_UNIT_FIXTURE_ONLY",
            "lastOrdinal": последнийНомер127 ? 127 : 0,
            "historicalProgressLinkAt127": последнийНомер127 ? "Typed signed seed only; historical progress file not read by history authentication" : "OMITTED",
            "seededClaim127": последнийНомер127] as [String: Any]),
            корень.appendingPathComponent("history-seed-origin.json"), права: 0o400)
        return final
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K16: полная signed R0M0...R127M127, actual publisher128/claim0 и overflow129 reject")
    func полнаяИсторияПроверяетПубликацию128ИОтказ129() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K16-full0to128-publication-limit-with-unit-seed")
        let header = try Data(contentsOf: ф.заголовок), r0 = try Data(contentsOf: ф.указатель)
        let m0 = try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json"))
        let last = try ф.посеятьСинтетическуюИсториюДо127(последнийНомер127: false)
        let release = try СинтетическийВыпускЯкоря(ф, публикация: 128,
            операция: UUID().uuidString.lowercased(), предыдущий: last.конверт)
        let plan = try release.сохранитьКандидат(ф, ожидаемый: last.конвертSHA)
        _ = try КомандаStop.проверитьПубликациюV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        try #require(try Data(contentsOf: ф.указатель) == last.конверт)
        let published = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        let terminal = try СинтетическийЯкорь.объект(published)
        try #require(terminal["исход"] as? String == "ОПУБЛИКОВАНО")
        let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let blocks = try СинтетическийЯкорь.ответБлокирует(response)
        try #require(blocks)
        let claim = try Data(contentsOf: ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim"))
        #expect(try СинтетическийЯкорь.объект(claim)["подписанныйДопускSHA256"] as? String == release.конвертSHA)
        let names = try FileManager.default.contentsOfDirectory(atPath: ф.корень.appendingPathComponent("adoptions").path)
        let expected = Set((0...128).flatMap { [String($0) + ".допуск.json", String($0) + ".завершение.json"] })
        #expect(Set(names) == expected && names.count == 258)
        let overflow = try СинтетическийВыпускЯкоря(ф, публикация: 129,
            операция: UUID().uuidString.lowercased(), предыдущий: release.конверт)
        let overflowPlan = try overflow.сохранитьКандидат(ф, ожидаемый: release.конвертSHA)
        var rejected = false
        do { _ = try КомандаStop.проверитьПубликациюV4(overflowPlan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка) }
        catch КорневойДопускStopV4.Отказ.идентичность { rejected = true }
        try #require(rejected)
        #expect(try Data(contentsOf: ф.указатель) == release.конверт)
        #expect(СинтетическийЯкорь.отсутствует(ф.корень.appendingPathComponent("adoptions/129.допуск.json")))
        #expect(СинтетическийЯкорь.отсутствует(ф.корень.appendingPathComponent("receipts/" + overflow.операция + ".129.intent.json")))
        #expect(try Data(contentsOf: ф.заголовок) == header)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.допуск.json")) == r0)
        #expect(try Data(contentsOf: ф.корень.appendingPathComponent("adoptions/0.завершение.json")) == m0)
        try СинтетическийЯкорь.сохранить(published, ф.корень.appendingPathComponent("actual-publication128-terminal.json"), права: 0o600)
        try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("actual-publication128-claim0-response.raw"), права: 0o600)
    }
    @Test("K16 ordinal128: unit seed priorclaim127 bound to R127, actual public128/progress→claim128, no actual1...127 mint claim")
    func последнийНомер128ТребуетПолныйПрежнийЗахват() throws {
        let ф = try СинтетическийЯкорь.новаяФикстура()
        try ф.сохранитьНазваниеПроверки("K16-actual-claim128-with-explicit-unit-prior127")
        let initial = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let initialBlocks = try СинтетическийЯкорь.ответБлокирует(initial)
        try #require(initialBlocks)
        let actual0URL = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".0.claim")
        let actual0 = try Data(contentsOf: actual0URL)
        let last = try ф.посеятьСинтетическуюИсториюДо127(последнийНомер127: true)
        let p127 = try СинтетическийЯкорь.объект(last.нагрузка)
        var prior = try СинтетическийЯкорь.объект(actual0)
        for key in ["задача", "узел", "область", "поколение", "исходники", "эпоха", "операция",
            "корневойДопускSHA256", "заголовокSHA256", "наблюдениеSHA256", "редакция", "номер", "вид", "пункт", "следующаяРабота"] {
            guard let value = p127[key] else { throw ОтказПубликационнойПробыV4.намеренный }
            prior[key] = value
        }
        prior["полныйСнимокSHA256"] = last.снимокSHA
        prior["подписанныйДопускSHA256"] = last.конвертSHA
        let seeded127 = try СинтетическийЯкорь.кодироватьОбъект(prior)
        try СинтетическийЯкорь.сохранить(seeded127,
            ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".127.claim"), права: 0o400)
        let op = UUID().uuidString.lowercased()
        let mutate: (inout [String: Any]) throws -> Void = { s in
            s["редакция"] = 8
            var n = try #require(s["наблюдения"] as? [String: Any])
            n["следующаяРабота"] = "Последний допустимый ordinal128 после принятого progress"
            s["наблюдения"] = n
        }
        let preview = try СинтетическийВыпускЯкоря(ф, публикация: 128, номер: 128,
            операция: op, предыдущий: last.конверт, предыдущаяОперация: last.операция, изменитьСнимок: mutate)
        let progress = try ф.сохранитьПрогрессПослеClaim(seeded127, прежняяНагрузка: p127, следующий: preview)
        let next = try СинтетическийВыпускЯкоря(ф, публикация: 128, номер: 128,
            операция: op, предыдущий: last.конверт, предыдущаяОперация: last.операция,
            прогресс: progress, изменитьСнимок: mutate)
        let plan = try next.сохранитьКандидат(ф, ожидаемый: last.конвертSHA)
        _ = try КомандаStop.проверитьПубликациюV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        let published = try КомандаStop.опубликоватьДопускV4(plan, ожидаемыйЗаголовокSHA256: ф.хэшЗаголовка)
        let terminal = try СинтетическийЯкорь.объект(published)
        try #require(terminal["исход"] as? String == "ОПУБЛИКОВАНО")
        let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        let blocks = try СинтетическийЯкорь.ответБлокирует(response)
        try #require(blocks)
        let actual128URL = ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".128.claim")
        let claim128 = try Data(contentsOf: actual128URL)
        let c128 = try СинтетическийЯкорь.объект(claim128)
        #expect(c128["подписанныйДопускSHA256"] as? String == next.конвертSHA)
        #expect(c128["номер"] as? UInt64 == 128)
        #expect(try Data(contentsOf: actual0URL) == actual0)
        #expect(try Data(contentsOf: ф.захваты.appendingPathComponent(СинтетическийЯкорь.эпоха + ".127.claim")) == seeded127)
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).sorted() == [0,127,128].map { СинтетическийЯкорь.эпоха + "." + String($0) + ".claim" }.sorted())
        try СинтетическийЯкорь.сохранить(СинтетическийЯкорь.кодироватьОбъект([
            "схема": "fum.synthetic-ordinal128-origin.1", "actualMintedOrdinals": [0,128],
            "unitSeededPriorOrdinal": 127, "actualMint1through127": "NOT_PROVED",
            "actualPublication128": terminal, "actualClaim128SHA256": СинтетическийЯкорь.хэш(claim128),
            "seededClaim127SHA256": СинтетическийЯкорь.хэш(seeded127)] as [String: Any]),
            ф.корень.appendingPathComponent("ordinal128-origin-and-result.json"), права: 0o400)
        try СинтетическийЯкорь.сохранить(response, ф.корень.appendingPathComponent("actual-ordinal128-response.raw"), права: 0o600)
    }
}

private struct ТерминальнаяФикстураЯкоря: Sendable {
    let ф: СинтетическийЯкорь
    let выпуск: СинтетическийВыпускЯкоря
    let диспозицияПуть, nativeПуть: URL
    let диспозиция, native: Data
    init(уровень: String = "исходники", blocked: Bool = false,
        optionalNative: Bool = false, одиночноеПолеИсходников: Bool = false,
        режимДиспозиции: mode_t = 0o400, режимNative: mode_t = 0o400,
        изменитьДиспозицию: (inout [String: Any]) throws -> Void = { _ in },
        изменитьWireДиспозиции: (Data) throws -> Data = { $0 },
        изменитьNative: (inout [String: Any]) throws -> Void = { _ in },
        изменитьWireNative: (Data) throws -> Data = { $0 }) throws {
        ф = try СинтетическийЯкорь.незапубликованнаяФикстура()
        let rawCommit = Data(("tree " + String(repeating: "7", count: 40) + "\nparent " + СинтетическийЯкорь.исходники
            + "\nparent " + String(repeating: "8", count: 40)
            + "\nauthor Synthetic Unit <unit@example.invalid> 0 +0000\ncommitter Synthetic Unit <unit@example.invalid> 0 +0000\n\nSynthetic unit merge\n").utf8)
        var object = Data("commit \(rawCommit.count)\0".utf8); object.append(rawCommit)
        let head = Insecure.SHA1.hash(data: object).map { String(format: "%02x", $0) }.joined()
        let ref = ф.корень.appendingPathComponent("common/refs/heads/fum-lab/fum/master")
        try СинтетическийЯкорь.сохранить(Data(contentsOf: ref),
            ф.корень.appendingPathComponent("retained-before-terminal-unit-head.raw"), права: 0o400)
        try Data((head + "\n").utf8).write(to: ref)
        let actualRef = try String(contentsOf: ref, encoding: .utf8)
        try #require(actualRef == head + "\n")
        var n: [String: Any] = ["схема": "fum.native-stop-проба.1", "задача": СинтетическийЯкорь.задача,
            "область": СинтетическийЯкорь.область, "поколение": СинтетическийЯкорь.поколение,
            "HEAD": head, "решение": "block", "бинарникSHA256": String(repeating: "a", count: 64),
            "определениеХукаSHA256": String(repeating: "b", count: 64), "наблюдениеSHA256": String(repeating: "c", count: 64)]
        try изменитьNative(&n)
        native = try изменитьWireNative(СинтетическийЯкорь.кодироватьОбъект(n))
        nativeПуть = ф.корень.appendingPathComponent("receipts/terminal-native-unit.json")
        try СинтетическийЯкорь.сохранить(native, nativeПуть, права: Int(режимNative))
        var proof: [String: Any] = ["id": "repair-stop-unit", "уровень": уровень]
        if уровень == "исходники" {
            proof["доставка"] = СинтетическийЯкорь.исходники; proof["интеграция"] = head
            proof["цепочка"] = [rawCommit.base64EncodedString()]
        } else if одиночноеПолеИсходников { proof["доставка"] = СинтетическийЯкорь.исходники }
        if optionalNative || уровень == "native" {
            proof["квитанцияNative"] = ["путь": nativeПуть.lastPathComponent, "sha256": СинтетическийЯкорь.хэш(native)]
        }
        var d: [String: Any] = ["схема": "fum.stop-диспозиция.2", "задача": СинтетическийЯкорь.задача,
            "узел": СинтетическийЯкорь.узел, "область": СинтетическийЯкорь.область,
            "поколение": СинтетическийЯкорь.поколение, "HEAD": head,
            "исход": blocked ? "blocked-return" : "bounded-complete", "пункты": [proof],
            "основание": "Точная синтетическая терминальная диспозиция принята unit ROOT",
            "ответственный": СинтетическийЯкорь.задача, "условиеВозврата": "Новый адресный unit допуск ROOT",
            "остаток": blocked ? ["repair-stop-unit"] : []]
        if blocked { d["блокерSHA256"] = String(repeating: "d", count: 64) }
        try изменитьДиспозицию(&d)
        диспозиция = try изменитьWireДиспозиции(СинтетическийЯкорь.кодироватьОбъект(d))
        диспозицияПуть = ф.корень.appendingPathComponent("receipts/terminal-disposition-unit.json")
        try СинтетическийЯкорь.сохранить(диспозиция, диспозицияПуть, права: Int(режимДиспозиции))
        let dispositionHash = СинтетическийЯкорь.хэш(диспозиция)
        let decision = try СинтетическийЯкорь.кодироватьОбъект([
            "схема": "fum.synthetic-terminal-root-decision.1", "HEAD": head,
            "задача": СинтетическийЯкорь.задача, "диспозицияSHA256": dispositionHash])
        try СинтетическийЯкорь.сохранить(decision,
            ф.корень.appendingPathComponent("terminal-root-decision-unit.json"), права: 0o400)
        let decisionHash = СинтетическийЯкорь.хэш(decision), dispositionName = диспозицияПуть.lastPathComponent
        выпуск = try СинтетическийВыпускЯкоря(ф, изменитьСнимок: { s in
            s["HEAD"] = head
            s["пункты"] = [["id": "repair-stop-unit", "область": СинтетическийЯкорь.область,
                "состояние": blocked ? "блокирован" : "закрыт", "уровень": уровень,
                "основание": "Synthetic closed/blocked item with exact proof"]]
            s["диспозиция"] = ["путь": dispositionName, "sha256": dispositionHash]
            var observations = try #require(s["наблюдения"] as? [String: Any])
            observations["следующаяРабота"] = ""
            var conditions = try #require(observations["условия"] as? [String: Any])
            for key in ["естьБезопасныйСледующийШаг", "доступнаНезависимаяРабота", "локальнаяИсправимаяПроблема",
                "можноБезопасноПродолжать", "естьНакопленноеПродвижение"] { conditions[key] = false }
            conditions["неизвестныйОпасныйЭффект"] = false
            conditions["свояОбласть"] = true; conditions["естьПолномочия"] = true
            observations["условия"] = conditions; s["наблюдения"] = observations
        }, изменитьНагрузку: { p in
            // Положительный terminal grant остаётся синтаксически полным; ordinary work branch не используется.
            p["следующаяРабота"] = СинтетическийЯкорь.шаг; p["корневойДопускSHA256"] = decisionHash
        })
        try выпуск.установитьНачальныйСинтетическийНабор(ф)
    }
    func проверить(_ имя: String, принят: Bool) throws {
        try ф.сохранитьНазваниеПроверки(имя)
        let response = КомандаStop.выполнить(ф.аргументы, ввод: try ф.событие())
        if принят { #expect(response == Data("{}\n".utf8)) }
        else {
            let object = try СинтетическийЯкорь.объект(response)
            #expect((object["stopReason"] as? String)?.contains("UNKNOWN") == true)
            #expect(response != Data("{}\n".utf8))
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: ф.захваты.path).isEmpty)
        #expect(try Data(contentsOf: диспозицияПуть) == диспозиция)
        #expect(try Data(contentsOf: nativeПуть) == native)
        try СинтетическийЯкорь.сохранить(response,
            ф.корень.appendingPathComponent("terminal-receipt-response.raw"), права: 0o600)
        // Это private signed unit fixtures; реальные ROOT receipts/Native callback не вызываются.
    }
}
extension ПроверкиСтабильногоЯкоря {
    @Test("K18 positive terminal: source proof, optionalnative, native+singleoptional sourcefield и полный blocked-return реально читают receipts0400")
    func допустимыеТерминальныеКвитанцииV4ПроходятПолнуюВетвь() throws {
        for row in 0..<4 {
            let f = try ТерминальнаяФикстураЯкоря(уровень: row == 2 ? "native" : "исходники",
                blocked: row == 3, optionalNative: row > 0, одиночноеПолеИсходников: row == 2)
            try f.проверить("K18-terminal-positive-" + String(row), принят: true)
        }
    }
    @Test("K18 closed receipts: outer/native unknown duplicate null trailing mode chain/hash и blocked-return proof gates не обходятся")
    func закрытыеТерминальныеКвитанцииНеПринимаютПодмены() throws {
        for row in 0..<22 {
            let nativeLevel = row == 14 || row == 15
            let blocked = row == 16 || row == 17
            let f = try ТерминальнаяФикстураЯкоря(уровень: nativeLevel ? "native" : "исходники",
                blocked: blocked, optionalNative: true, одиночноеПолеИсходников: row == 14,
                режимДиспозиции: row == 6 ? 0o600 : 0o400, режимNative: row == 10 ? 0o600 : 0o400,
                изменитьДиспозицию: { d in
                    if row == 0 { d["необъявленныйКлюч"] = "unit" }
                    if row == 1 { d["остаток"] = NSNull() }
                    var proofs = try #require(d["пункты"] as? [[String: Any]])
                    if row == 2 { proofs[0]["квитанцияNative"] = NSNull() }
                    if row == 3 { proofs[0]["необъявленныйКлюч"] = "unit" }
                    if row == 11 {
                        var link = try #require(proofs[0]["квитанцияNative"] as? [String: Any])
                        link["sha256"] = String(repeating: "f", count: 64); proofs[0]["квитанцияNative"] = link
                    }
                    if row == 12 {
                        let chain = try #require(proofs[0]["цепочка"] as? [String])
                        proofs[0]["цепочка"] = [chain[0] + "\n"]
                    }
                    if row == 13 { proofs[0]["интеграция"] = NSNull() }
                    if row == 14 { proofs[0]["доставка"] = "invalid-delivery-hex" }
                    if row == 15 { proofs[0]["цепочка"] = [Data("not-a-commit".utf8).base64EncodedString()] }
                    if row == 16 { proofs[0].removeValue(forKey: "цепочка") }
                    if row == 19 {
                        let chain = try #require(proofs[0]["цепочка"] as? [String])
                        proofs[0]["цепочка"] = Array(repeating: chain[0], count: 9)
                    }
                    if row == 20 { proofs[0]["цепочка"] = NSNull() }
                    if row == 21 { proofs[0]["квитанцияNative"] = ["путь": "../outside.json", "sha256": String(repeating: "f", count: 64)] }
                    d["пункты"] = proofs
                }, изменитьWireДиспозиции: { raw in
                    if row == 5 { return raw + Data(" \n".utf8) }
                    if row == 4 {
                        let text = try #require(String(data: raw, encoding: .utf8)), needle = "\"исход\":\"bounded-complete\""
                        try #require(text.components(separatedBy: needle).count == 2)
                        return Data(text.replacingOccurrences(of: needle, with: needle + "," + needle).utf8)
                    }
                    return raw
                }, изменитьNative: { n in
                    if row == 7 || row == 17 { n["необъявленныйКлюч"] = "unit" }
                    if row == 8 { n["наблюдениеSHA256"] = NSNull() }
                    if row == 9 { n["HEAD"] = String(repeating: "f", count: 40) }
                }, изменитьWireNative: { raw in
                    if row == 18 {
                        let text = try #require(String(data: raw, encoding: .utf8)), needle = "\"решение\":\"block\""
                        try #require(text.components(separatedBy: needle).count == 2)
                        return Data(text.replacingOccurrences(of: needle, with: needle + "," + needle).utf8)
                    }
                    return raw
                })
            try f.проверить("K18-terminal-negative-" + String(row), принят: false)
        }
    }
}


import Foundation
import Darwin
import Testing
import УстановкаStop

private enum СбойПослеRenameV4: Error { case намеренный }
struct ПроверкиАтомарнойГраницыV4 {
    @Test func послеRenameНеСохраняетсяСтароеНаблюдение() throws {
        let родитель = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        var сведения = stat()
        #expect(lstat(родитель, &сведения) == 0)
        #expect(сведения.st_mode & S_IFMT == S_IFDIR)
        #expect(сведения.st_mode & 0o7777 == 0o700 && сведения.st_uid == geteuid())
        let корень = родитель + "/atomic-" + UUID().uuidString.lowercased()
        try #require(mkdir(корень, 0o700) == 0)
        let путь = корень + "/pointer.json"
        let старые = Data("retained-before-rename\n".utf8)
        let новые = Data("retained-after-rename\n".utf8)
        _ = try АтомарныеБайтыStop.создатьЕслиОтсутствует(путь, новыми: старые)
        var удержанный: Int32 = -1
        defer { if удержанный >= 0 { _ = Darwin.close(удержанный) } }
        var отказ: ОтказАтомарнойЗаменыStop?
        do {
            _ = try АтомарныеБайтыStop.заменитьУказательV4(путь,
                ожидаемыйSHA256: АтомарныеБайтыStop.sha256(старые), новыми: новые,
                проверить: {}, отметить: { фаза in
                    if фаза == "после-rename" {
                        удержанный = open(путь, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                        try #require(удержанный >= 0)
                        try #require(fchmod(удержанный, 0) == 0)
                        throw СбойПослеRenameV4.намеренный
                    }
                })
            Issue.record("После намеренного отказа не должен возвращаться успех")
        } catch let ошибка as ОтказАтомарнойЗаменыStop { отказ = ошибка }
        let известный = try #require(отказ)
        #expect(известный.граница == .послеRename)
        #expect(известный.наблюдаемыйSHA256 == nil)
        #expect(известный.оставленныйВременныйФайл == nil)
        try #require(удержанный >= 0)
        var буфер = [UInt8](repeating: 0, count: новые.count + 1)
        let число = буфер.withUnsafeMutableBytes { Darwin.read(удержанный, $0.baseAddress, $0.count) }
        #expect(число == новые.count)
        #expect(Data(буфер.prefix(число >= 0 ? число : 0)) == новые)
        var поИмени = stat(), поFD = stat()
        try #require(lstat(путь, &поИмени) == 0 && fstat(удержанный, &поFD) == 0)
        #expect(поИмени.st_ino == поFD.st_ino && поИмени.st_dev == поFD.st_dev)
        #expect(поИмени.st_mode & 0o7777 == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: корень) == ["pointer.json"])
        // Режим 000 и новые байты сохраняются как свидетельство, без восстановления или удаления.
    }
}
