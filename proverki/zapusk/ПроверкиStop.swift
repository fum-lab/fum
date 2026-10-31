import Foundation
import CryptoKit
import Testing
import МатериализацияУзлов

@Suite("Команда fuma stop", .serialized,
       .disabled(if: ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_STOP"] != nil,
                 "Старая CLI suite исключена из адресного профиля V2"))
struct ПроверкиКомандыStop {
    private let задача = "00000000-0000-4000-8000-000000000479"
    private let узел = "fum-lab/fum/master"

    private func событие(cwd: String, задача: String? = nil) throws -> Data {
        var данные = try JSONSerialization.data(withJSONObject: [
            "session_id": задача ?? self.задача,
            "hook_event_name": "Stop",
            "cwd": cwd,
            "turn_id": "ход-e2e",
            "stop_hook_active": false
        ], options: [.sortedKeys])
        данные.append(0x0a)
        return данные
    }

    private func условия(неизвестный: Bool, остановка: Bool) -> УсловияСамостоятельности {
        УсловияСамостоятельности(свояОбласть: true, естьПолномочия: true,
            неизвестныйОпасныйЭффект: неизвестный, естьНакопленноеПродвижение: true,
            можноБезопасноПродолжать: true, доступнаНезависимаяРабота: true,
            локальнаяИсправимаяПроблема: false, остановкаЗадачи: остановка,
            естьБезопасныйСледующийШаг: true)
    }

    private func сохранитьНаблюдения(_ наблюдения: НаблюденияStop, в путь: URL) throws {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(наблюдения)
        данные.append(0x0a)
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)
    }

    private func аргументы(cwd: String, состояние: URL) -> [String] {
        ["stop", "--идентификатор-обработчика", "fum.stop-handler.1",
         "--codex-thread-id", задача, "--идентификатор-узла", узел,
         "--ожидаемый-cwd", cwd,
         "--состояние", состояние.path]
    }

    @Test("Реальный binary различает unknown+independent и human STOP без Python/PATH")
    func процессныйКонтракт() async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let пустойPATH = среда.корень.appendingPathComponent("empty-path")
        try FileManager.default.createDirectory(at: пустойPATH,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let окружение = ["PATH": пустойPATH.path]

        let неизвестность = среда.корень.appendingPathComponent("unknown.json")
        try сохранитьНаблюдения(НаблюденияStop(задача: задача, узел: узел,
            следующаяРабота: "выполнить независимую работу B",
            условия: условия(неизвестный: true, остановка: false)), в: неизвестность)
        let первый = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: неизвестность),
            ввод: try событие(cwd: среда.корень.path), окружение: окружение)
        #expect(первый.код == 0)
        #expect(первый.ошибки.isEmpty)
        let первыйОтвет = try #require(try JSONSerialization.jsonObject(with: первый.вывод) as? [String: Any])
        #expect(первыйОтвет["decision"] as? String == "block")
        #expect((первыйОтвет["reason"] as? String)?.contains("неизвестный опасный эффект") == true)
        #expect((первыйОтвет["reason"] as? String)?.contains("работу B") == true)

        let остановка = среда.корень.appendingPathComponent("stop.json")
        try сохранитьНаблюдения(НаблюденияStop(задача: задача, узел: узел,
            следующаяРабота: "не должна исполняться",
            условия: условия(неизвестный: true, остановка: true)), в: остановка)
        let второй = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: остановка),
            ввод: try событие(cwd: среда.корень.path), окружение: окружение)
        #expect(второй.код == 0)
        #expect(второй.ошибки.isEmpty)
        let второйОтвет = try #require(try JSONSerialization.jsonObject(with: второй.вывод) as? [String: Any])
        #expect(второйОтвет["continue"] as? Bool == false)
        #expect((второйОтвет["stopReason"] as? String)?.contains("остановлена пользователем") == true)

        let отсутствует = среда.корень.appendingPathComponent("missing.json")
        let чужой = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: отсутствует),
            ввод: try событие(cwd: среда.корень.path,
                задача: "00000000-0000-4000-8000-000000000480"), окружение: окружение)
        #expect(чужой.код == 0)
        #expect(чужой.вывод == Data("{}\n".utf8))
        #expect(чужой.ошибки.isEmpty)
        #expect(первый.процесс != второй.процесс)
        #expect(второй.процесс != чужой.процесс)
        _ = try await процессы.проверенныйХэш()
    }
}


// Дополнение к существующему файлу; запускать только эту suite.
// Один тест, ровно девять вызовов существующего CLI process helper.
// UUID, Git metadata, snapshots и receipts ниже полностью синтетические.
@Suite("Текущие обязательства Stop V2 через CLI", .serialized)
struct ПроверкиТекущихОбязательствStopCLI {
    private func подготовитьБинарникСРесурсами() throws {
        let env = ProcessInfo.processInfo.environment
        let источник = URL(fileURLWithPath: try #require(env["ФУМА_ПРОДУКТЫ_STOP"]))
        let бинарник = URL(fileURLWithPath: try #require(env["ФУМА_БИНАРНИК_ЗАПУСКА"]))
        let каталог = бинарник.deletingLastPathComponent()
        let fm = FileManager.default
        #expect(!fm.fileExists(atPath: каталог.path))
        try fm.createDirectory(at: каталог, withIntermediateDirectories: false,
                               attributes: [.posixPermissions: 0o700])
        let имена = ["fuma", "FUMA_МатериализацияУзлов.bundle",
                     "FUMA_FUMStructuringOperatorMemory.bundle", "FUMA_ЖурналУзла.bundle"]
        for имя in имена {
            try fm.copyItem(at: источник.appendingPathComponent(имя),
                            to: каталог.appendingPathComponent(имя))
        }
        var файлы: [[String: Any]] = []
        let перечислитель = try #require(fm.enumerator(at: каталог,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]))
        for case let путь as URL in перечислитель {
            let свойства = try путь.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            try #require(свойства.isSymbolicLink != true)
            if свойства.isRegularFile == true {
                let относительный = String(путь.path.dropFirst(каталог.path.count + 1))
                let данные = try Data(contentsOf: путь)
                let оригинал = try Data(contentsOf: источник.appendingPathComponent(относительный))
                try #require(данные == оригинал)
                файлы.append(["путь": относительный, "байтов": данные.count,
                              "sha256": Фикстура.sha256(данные)])
                try fm.setAttributes([.posixPermissions: относительный == "fuma" ? 0o500 : 0o400],
                                     ofItemAtPath: путь.path)
            }
        }
        try #require(файлы.contains { $0["путь"] as? String == "fuma" })
        let манифест = try Фикстура.json([
            "схема": "fum.stop-cli-staging.1", "файлы": файлы,
            "граница": "Отдельная копия production binary и трёх resource bundles; hooks/current не изменяются"
        ])
        try Фикстура.сохранить(манифест,
            в: каталог.appendingPathComponent("stage-manifest.json"), права: 0o600)
    }

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

        init(основание: URL) throws {
            корень = основание
                .appendingPathComponent("fum-stop-v2-e2e-\(UUID().uuidString.lowercased())")
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

    }

    @Test("Девять CLI children: target guards, текущий остаток, STOP и bounded release",
          .enabled(if: ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_STOP"] == "v2-full"))
    func девятьЗакрытыхСлучаевCLI() async throws {
        try подготовитьБинарникСРесурсами()
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let пустойPATH = среда.корень.appendingPathComponent("empty-path")
        try FileManager.default.createDirectory(
            at: пустойPATH, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let окружение = ["PATH": пустойPATH.path]
        var числоДетей = 0

        for номер in 1...9 {
            let ф = try Фикстура(основание: среда.корень)
            defer { ф.очистить() }
            #expect(ф.nativeCWD.path != ф.дерево.path)
            var событие = ф.событие()
            var снимок: [String: Any]?
            var ожидаетсяПустойОтвет = false
            var ожидаетсяSTOP = false
            var ожидаетсяСледующийШаг = false

            switch номер {
            case 1:
                // Иначе этот snapshot имеет доказанный bounded-complete.
                событие.removeValue(forKey: "turn_id")
                снимок = try ф.завершённый()
            case 2:
                снимок = ф.снимок()
                ожидаетсяСледующийШаг = true
            case 3:
                var значение = try ф.завершённый()
                значение["пункты"] = [ф.пункт("ожидает-ребёнка")]
                снимок = значение
            case 4:
                var значение = try ф.завершённый()
                значение["пункты"] = [ф.пункт("доставлен")]
                снимок = значение
            case 5:
                var значение = try ф.завершённый()
                значение["выпущен"] = ф.сейчас - 1800
                значение["действуетДо"] = ф.сейчас - 900
                снимок = значение
            case 6:
                var значение = ф.снимок()
                значение["управление"] = [
                    "действие": "стоп", "основание": "Явное указание человека"]
                значение["выпущен"] = ф.сейчас - 1800
                значение["действуетДо"] = ф.сейчас - 900
                for ключ in ["HEAD", "пункты", "наблюдения"] {
                    значение.removeValue(forKey: ключ)
                }
                снимок = значение
                ожидаетсяSTOP = true
            case 7:
                // Snapshot намеренно не создаётся.
                событие = ф.событие(задача: Фикстура.чужаяЗадача)
                #expect(!FileManager.default.fileExists(atPath: ф.состояние.path))
                ожидаетсяПустойОтвет = true
            case 8:
                var значение = try ф.завершённый()
                значение["пункты"] = [
                    ф.пункт("закрыт"),
                    ф.пункт("закрыт", область: "historical-scope",
                            id: "old-child", уровень: "native")
                ]
                снимок = значение
                ожидаетсяПустойОтвет = true
            case 9:
                // Только wrong-scope receipt: unknown-intent не создаёт десятый child.
                снимок = try ф.завершённый(областьКвитанции: "foreign-scope")
            default:
                Issue.record("Неожиданный номер закрытого CLI случая")
                return
            }

            if let снимок {
                let байты = try Фикстура.json(снимок)
                #expect(байты.count <= 32_768)
                try Фикстура.сохранить(байты, в: ф.состояние, права: 0o600)
            }
            let ввод = try Фикстура.json(событие)
            let аргументы = ["stop"] + ф.аргументы
            #expect(ф.аргументы.count == 16)
            let наблюдение = try await процессы.запустить(
                аргументы, ввод: ввод, окружение: окружение)
            числоДетей += 1
            #expect(наблюдение.процесс > 1)
            #expect(наблюдение.код == 0)
            #expect(наблюдение.ошибки.isEmpty)
            #expect(наблюдение.вывод.last == 10)
            #expect(наблюдение.вывод.count <= 65_536)
            let ответ = try #require(
                try JSONSerialization.jsonObject(with: наблюдение.вывод) as? [String: Any])

            if ожидаетсяПустойОтвет {
                #expect(ответ.isEmpty)
                #expect(наблюдение.вывод == Data("{}\n".utf8))
            } else if ожидаетсяSTOP {
                #expect(ответ["continue"] as? Bool == false)
                #expect(ответ["decision"] == nil)
                #expect((ответ["stopReason"] as? String)?.contains("пользовател") == true)
            } else {
                #expect(ответ["decision"] as? String == "block")
                #expect(ответ["continue"] == nil)
                if ожидаетсяСледующийШаг {
                    #expect((ответ["reason"] as? String)?
                        .contains("текущий безопасный шаг") == true)
                }
            }
            if номер == 7 {
                #expect(!FileManager.default.fileExists(atPath: ф.состояние.path))
            }
        }
        #expect(числоДетей == 9)
        #expect(!FileManager.default.fileExists(atPath: среда.хранилище.path))
        _ = try await процессы.проверенныйХэш()
    }

    @Test("Физический /private/tmp и final staged artifact: один CLI child",
          .enabled(if: ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_STOP"] == "resolver-only"))
    func физическийCommonDirЧерезОдинCLI() async throws {
        try подготовитьБинарникСРесурсами()
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let ф = try Фикстура(основание: URL(fileURLWithPath: "/private/tmp", isDirectory: true))
        defer { ф.очистить() }
        try Фикстура.сохранить(Фикстура.json(ф.завершённый()), в: ф.состояние, права: 0o600)
        let пустойPATH = среда.корень.appendingPathComponent("empty-path")
        try FileManager.default.createDirectory(at: пустойPATH,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let наблюдение = try await процессы.запустить(["stop"] + ф.аргументы,
            ввод: Фикстура.json(ф.событие()), окружение: ["PATH": пустойPATH.path])
        #expect(наблюдение.код == 0)
        #expect(наблюдение.ошибки.isEmpty)
        #expect(наблюдение.вывод == Data("{}\n".utf8))
        _ = try await процессы.проверенныйХэш()
    }
}
