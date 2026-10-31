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
