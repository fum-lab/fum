import Foundation
import Darwin
import Testing
@testable import УстановкаStop

@Suite("Конечная ROOT-аренда рабочего издателя", .serialized)
struct ПроверкиПоддержанияТекущегоСтоп {
    private enum Инъекция: Error { case отказ }
    private struct Фикстура {
        let кореньФикстуры: URL
        let начальноеВремяФикстуры: Int64
        let хэшЗаголовкаФикстуры: String
        let хэшТекущегоФикстуры: String
        let текущийЗамокФикстуры: СсылкаЗамкаStop
        let замокИздателяФикстуры: СсылкаЗамкаStop
        let снимокФикстуры: Data
        var запросФикстуры: URL { кореньФикстуры.appendingPathComponent("request.json") }
        var current: URL { кореньФикстуры.appendingPathComponent("current.json") }
        var input: URL { кореньФикстуры.appendingPathComponent("current.json.producer-input.json") }
        var файлВеткиФикстуры: URL { кореньФикстуры.appendingPathComponent("git/refs/heads/fum/synthetic/master") }
        init(headPolicy: String = "strict") throws {
            кореньФикстуры = URL(fileURLWithPath: "/private/tmp/fum-maintainer-" + UUID().uuidString.lowercased())
            начальноеВремяФикстуры = Int64(Date().timeIntervalSince1970)
            try FileManager.default.createDirectory(at: кореньФикстуры, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            let path = кореньФикстуры.path, common = path + "/git", gitDir = common + "/worktrees/synthetic"
            let w = path + "/W", ref = "refs/heads/fum/synthetic/master"
            for dir in [gitDir, common + "/refs/heads/fum/synthetic", w] {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700])
            }
            for (file, text) in [(w + "/.git", "gitdir: \(gitDir)\n"),
                (gitDir + "/gitdir", "\(w)/.git\n"), (gitDir + "/commondir", "../..\n"),
                (gitDir + "/HEAD", "ref: \(ref)\n"),
                (common + "/" + ref, String(repeating: "b", count: 40) + "\n")] {
                try Self.записатьФикстуру(Data(text.utf8), URL(fileURLWithPath: file))
            }
            let путьТекущегоФикстуры = path + "/current.json"
            let адресЗамкаФикстуры = URL(fileURLWithPath: путьТекущегоФикстуры + ".lock")
            let адресЗамкаИздателяФикстуры = URL(fileURLWithPath: путьТекущегоФикстуры + ".producer.lock")
            try Self.записатьФикстуру(Data(), адресЗамкаФикстуры); try Self.записатьФикстуру(Data(), адресЗамкаИздателяФикстуры)
            func закрепитьЗамокФикстуры(_ url: URL) throws -> СсылкаЗамкаStop {
                var s = Darwin.stat()
                guard lstat(url.path, &s) == 0 else { throw Инъекция.отказ }
                return СсылкаЗамкаStop(path: url.path, device: Int64(s.st_dev), inode: UInt64(s.st_ino))
            }
            текущийЗамокФикстуры = try закрепитьЗамокФикстуры(адресЗамкаФикстуры); замокИздателяФикстуры = try закрепитьЗамокФикстуры(адресЗамкаИздателяФикстуры)
            let id = "00000000-0000-4000-8000-000000000001"
            let h: [String: Any] = ["схема": "fum.stop-заголовок.2", "задача": id,
                "узел": "synthetic", "область": "test", "поколение": "generation1",
                "cwd": w, "дерево": w, "ref": ref, "gitDir": gitDir,
                "commonGitDir": common, "backend": "files", "objectFormat": "sha1",
                "исходники": String(repeating: "a", count: 40), "состояние": путьТекущегоФикстуры,
                "каталогКвитанций": path, "максимальныйВозрастСекунд": 900]
            let header = try Self.сериализоватьФикстуру(h); хэшЗаголовкаФикстуры = АтомарныеБайтыStop.sha256(header)
            let адресЗаголовкаФикстуры = кореньФикстуры.appendingPathComponent("header.json")
            try Self.записатьФикстуру(header, адресЗаголовкаФикстуры, mode: 0o400)
            let условияФикстуры: [String: Bool] = ["свояОбласть": true, "естьПолномочия": true,
                "неизвестныйОпасныйЭффект": false, "естьНакопленноеПродвижение": true,
                "можноБезопасноПродолжать": true, "доступнаНезависимаяРабота": true,
                "локальнаяИсправимаяПроблема": false, "остановкаЗадачи": false,
                "естьБезопасныйСледующийШаг": true]
            let текущийСнимокФикстуры: [String: Any] = ["схема": "fum.текущие-обязательства-stop.2",
                "заголовокSHA256": хэшЗаголовкаФикстуры, "задача": id, "узел": "synthetic",
                "область": "test", "поколение": "generation1", "cwd": w, "дерево": w,
                "ref": ref, "HEAD": String(repeating: "b", count: 40), "выпущен": начальноеВремяФикстуры,
                "действуетДо": начальноеВремяФикстуры + 900,
                "управление": ["действие": "продолжать", "основание": "Синтетическое поручение ROOT"],
                "пункты": [["id": "unverified", "область": "test", "состояние": "блокирован",
                    "уровень": "исходники", "основание": "Непроверенный остаток остаётся UNKNOWN"]],
                "неизвестныеНамерения": ["unverified"],
                "наблюдения": ["схема": "fum.stop-наблюдения.1", "задача": id, "узел": "synthetic",
                    "следующаяРабота": "Проверить новый вход ROOT", "условия": условияФикстуры]]
            снимокФикстуры = try Self.сериализоватьФикстуру(текущийСнимокФикстуры); хэшТекущегоФикстуры = АтомарныеБайтыStop.sha256(снимокФикстуры)
            let адресСнимкаФикстуры = кореньФикстуры.appendingPathComponent("payload.json")
            try Self.записатьФикстуру(снимокФикстуры, адресСнимкаФикстуры)
            try Self.записатьФикстуру(снимокФикстуры, URL(fileURLWithPath: путьТекущегоФикстуры))
            let арендаФикстуры: [String: Any] = ["schema": "fum.stop-maintainer-input.1", "root": id,
                "node": "synthetic", "scope": "test", "generation": "generation1",
                "headerSHA256": хэшЗаголовкаФикстуры, "revision": 1, "approvedAt": начальноеВремяФикстуры,
                "validUntil": начальноеВремяФикстуры + 7200, "action": "обновлять", "reason": "Разрешённая конечная аренда",
                "payload": ["path": адресСнимкаФикстуры.path, "bytes": снимокФикстуры.count, "sha256": хэшТекущегоФикстуры, "mode": 0o600]]
            try Self.записатьФикстуру(try Self.сериализоватьФикстуру(арендаФикстуры), кореньФикстуры.appendingPathComponent("current.json.producer-input.json"))
            let запросПланаФикстуры: [String: Any] = ["schema": "fum.stop-maintainer-request.1",
                "runID": UUID().uuidString.lowercased(),
                "header": ["path": адресЗаголовкаФикстуры.path, "bytes": header.count, "sha256": хэшЗаголовкаФикстуры, "mode": 0o400],
                "current": ["path": путьТекущегоФикстуры, "maxBytes": 32768, "mode": 0o600,
                    "lock": ["path": текущийЗамокФикстуры.path, "device": текущийЗамокФикстуры.device, "inode": текущийЗамокФикстуры.inode]],
                "singleton": ["path": замокИздателяФикстуры.path, "device": замокИздателяФикстуры.device, "inode": замокИздателяФикстуры.inode],
                "input": ["path": путьТекущегоФикстуры + ".producer-input.json", "mode": 0o600, "maxBytes": 65536],
                "initialCurrentSHA256": хэшТекущегоФикстуры, "requiredUnknownID": "unverified",
                "intervalSeconds": 30, "ttlSeconds": 600, "maxTicks": 100,
                "maxRunSeconds": 7200, "headPolicy": headPolicy]
            try Self.записатьФикстуру(try Self.сериализоватьФикстуру(запросПланаФикстуры), кореньФикстуры.appendingPathComponent("request.json"))
        }
        static func сериализоватьФикстуру(_ value: [String: Any]) throws -> Data {
            try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .withoutEscapingSlashes])
        }
        static func записатьФикстуру(_ data: Data, _ path: URL, mode: Int = 0o600) throws {
            try data.write(to: path)
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)
        }
        static func прочитатьОбъектФикстуры(_ path: URL) throws -> [String: Any] {
            guard let value = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as? [String: Any]
            else { throw Инъекция.отказ }
            return value
        }
        func изменитьВходФикстуры(_ action: (inout [String: Any]) -> Void) throws {
            var value = try Self.прочитатьОбъектФикстуры(input); action(&value)
            _ = try АтомарныеБайтыStop.заменить(input.path,
                ожидаемыйSHA256: АтомарныеБайтыStop.sha256(Data(contentsOf: input)), новыми: Self.сериализоватьФикстуру(value))
        }
        func шагФикстуры(_ state: СостояниеИздателяСтоп, _ now: Int64,
            points: ТочкиАтомарнойЗаменыStop = ТочкиАтомарнойЗаменыStop(),
            времяПередRename: Int64? = nil) throws -> ИтогПоддержанияСтоп {
            try УстановщикStop.шагПоддержания(запросФикстуры.path,
                хэш: АтомарныеБайтыStop.sha256(Data(contentsOf: запросФикстуры)),
                состояние: state, сейчас: now, точки: points,
                часыПередRename: { времяПередRename ?? now })
        }
        func очиститьФикстуру() {
            do { try FileManager.default.removeItem(at: кореньФикстуры) }
            catch { Issue.record("Собственная fixture издателя не удалена: \(error)") }
        }
    }

    @Test func транспортПосле900НеПродлеваетПодтверждениеИсточника() throws {
        let f = try Фикстура(); defer { f.очиститьФикстуру() }
        let state = СостояниеИздателяСтоп(), input = try Data(contentsOf: f.input)
        #expect(try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1).статус == "UPDATED")
        #expect(try f.шагФикстуры(state, f.начальноеВремяФикстуры + 901).статус == "UPDATED")
        let current = try Фикстура.прочитатьОбъектФикстуры(f.current)
        #expect(current["выпущен"] as? Int64 == f.начальноеВремяФикстуры + 901)
        #expect(current["действуетДо"] as? Int64 == f.начальноеВремяФикстуры + 1501)
        let maintenance = try #require(current["поддержание"] as? [String: Any])
        #expect(maintenance["подтвержденоВ"] as? Int64 == f.начальноеВремяФикстуры)
        #expect(maintenance["подтвержденоДо"] as? Int64 == f.начальноеВремяФикстуры + 7200)
        #expect(current["неизвестныеНамерения"] as? [String] == ["unverified"])
        #expect(try Data(contentsOf: f.input) == input)
        #expect(try Фикстура.прочитатьОбъектФикстуры(f.кореньФикстуры.appendingPathComponent("payload.json"))["выпущен"] as? Int64 == f.начальноеВремяФикстуры)
    }

    @Test func истечениеИсточникаИСкачокЧасовНеВыдумываютУсловия() throws {
        for backwards in [false, true] {
            let f = try Фикстура(); defer { f.очиститьФикстуру() }
            let state = СостояниеИздателяСтоп()
            _ = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1)
            let before = try Data(contentsOf: f.current)
            let r = try f.шагФикстуры(state, backwards ? f.начальноеВремяФикстуры : f.начальноеВремяФикстуры + 7201)
            #expect(r.статус == (backwards ? "CLOCK_REGRESSION" : "SOURCE_EXPIRED"))
            #expect(state.завершён)
            #expect(try Data(contentsOf: f.current) == before)
        }
        for случай in ["lease", "transport", "clock"] {
            let фикстура = try Фикстура(); defer { фикстура.очиститьФикстуру() }
            if случай == "lease" {
                try фикстура.изменитьВходФикстуры { $0["validUntil"] = фикстура.начальноеВремяФикстуры + 3 }
            }
            let состояние = СостояниеИздателяСтоп()
            let прежде = try Data(contentsOf: фикстура.current)
            let позднееВремя = случай == "lease" ? фикстура.начальноеВремяФикстуры + 3
                : (случай == "transport" ? фикстура.начальноеВремяФикстуры + 602 : фикстура.начальноеВремяФикстуры)
            let итог = try фикстура.шагФикстуры(состояние, фикстура.начальноеВремяФикстуры + 1, времяПередRename: позднееВремя)
            #expect(итог.статус == "FAILED")
            #expect(состояние.ошибка == (случай == "clock" ? "MclockBeforeRename" : "MleaseBeforeRename"))
            #expect(try Data(contentsOf: фикстура.current) == прежде)
        }
    }

    @Test func явныйКонтрольСохраняетсяБезГитИТехническаяОстановкаНеЧеловеческая() throws {
        for action in ["ручная-пауза", "пауза", "остановить-издатель"] {
            let f = try Фикстура(); defer { f.очиститьФикстуру() }
            let state = СостояниеИздателяСтоп()
            _ = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1)
            var current = try Фикстура.прочитатьОбъектФикстуры(f.current)
            if action == "ручная-пауза" {
                current["управление"] = ["действие": "пауза", "основание": "Явная fixture-команда"]
                let bytes = try Фикстура.сериализоватьФикстуру(current)
                _ = try АтомарныеБайтыStop.заменить(f.current.path,
                    ожидаемыйSHA256: АтомарныеБайтыStop.sha256(Data(contentsOf: f.current)), новыми: bytes)
            } else {
                try f.изменитьВходФикстуры { $0["revision"] = 2; $0["action"] = action }
            }
            try FileManager.default.removeItem(at: f.файлВеткиФикстуры)
            let before = try Data(contentsOf: f.current)
            let r = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 2)
            #expect(state.завершён)
            if action == "пауза" {
                #expect(r.статус == "ROOT_CONTROL_PUBLISHED")
                let seen = try Фикстура.прочитатьОбъектФикстуры(f.current)
                #expect((seen["управление"] as? [String: Any])?["действие"] as? String == "пауза")
            } else {
                #expect(r.статус == (action == "ручная-пауза" ? "ROOT_CONTROL" : "SERVICE_STOPPED"))
                #expect(try Data(contentsOf: f.current) == before)
            }
        }
    }

    @Test func занятыйИздательИРучнаяПубликацияНеСоздаютПовторнойЗаписи() throws {
        let f = try Фикстура(); defer { f.очиститьФикстуру() }
        let state = СостояниеИздателяСтоп(), other = СостояниеИздателяСтоп()
        _ = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1)
        let first = try Data(contentsOf: f.current)
        #expect(try f.шагФикстуры(other, f.начальноеВремяФикстуры + 2).статус == "SINGLETON_BUSY")
        let before = try FileManager.default.contentsOfDirectory(atPath: f.кореньФикстуры.path).sorted()
        try ЗамокТекущегоStop.выполнить(f.текущийЗамокФикстуры) { _ in
            let busy = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 2)
            #expect(busy.статус == "CURRENT_BUSY")
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: f.кореньФикстуры.path).sorted() == before)
        #expect(try Data(contentsOf: f.current) == first)
        #expect(try f.шагФикстуры(state, f.начальноеВремяФикстуры + 3).статус == "UPDATED")
        var manual = try Фикстура.прочитатьОбъектФикстуры(f.current); manual["ручнаяПубликация"] = true
        let manualBytes = try Фикстура.сериализоватьФикстуру(manual)
        _ = try АтомарныеБайтыStop.заменить(f.current.path,
            ожидаемыйSHA256: АтомарныеБайтыStop.sha256(Data(contentsOf: f.current)), новыми: manualBytes)
        #expect(try f.шагФикстуры(state, f.начальноеВремяФикстуры + 4).статус == "MANUAL_TAKEOVER")
        #expect(try Data(contentsOf: f.current) == manualBytes)
    }

    @Test func послеЗаменыНеизвестныйИсходИНовыйЭкземплярТолькоЧитают() throws {
        let f = try Фикстура(); defer { f.очиститьФикстуру() }
        let state = СостояниеИздателяСтоп()
        var points = ТочкиАтомарнойЗаменыStop()
        points.синхронизацияКаталога = { _ in throw Инъекция.отказ }
        #expect(try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1, points: points).статус == "UNKNOWN")
        let after = try АтомарныеБайтыStop.прочитать(f.current.path)
        #expect(after.sha256 != f.хэшТекущегоФикстуры)
        _ = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 2)
        #expect(try Data(contentsOf: f.current) == after.данные)
        let restarted = СостояниеИздателяСтоп()
        let recovery = try f.шагФикстуры(restarted, f.начальноеВремяФикстуры + 3)
        #expect(recovery.статус == "RECOVERY_REQUIRED")
        #expect(recovery.наблюдаемыйSHA256 == after.sha256)
        #expect(try Data(contentsOf: f.current) == after.данные)
    }

    @Test func ревизииИПолитикаВершиныСохраняютНеизвестныйИсход() throws {
        for kind in ["new", "same", "rollback", "head-strict", "head-observed"] {
            let f = try Фикстура(headPolicy: kind == "head-observed" ? "observe-with-unknown" : "strict")
            defer { f.очиститьФикстуру() }
            let state = СостояниеИздателяСтоп()
            _ = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 1)
            let before = try Data(contentsOf: f.current)
            if kind.hasPrefix("head-") {
                try Фикстура.записатьФикстуру(Data((String(repeating: "c", count: 40) + "\n").utf8), f.файлВеткиФикстуры)
            } else {
                try f.изменитьВходФикстуры {
                    $0["reason"] = "Новая явная ревизия"
                    if kind == "new" { $0["revision"] = 2; $0["approvedAt"] = f.начальноеВремяФикстуры + 2 }
                    if kind == "rollback" { $0["revision"] = 0 }
                }
            }
            let r = try f.шагФикстуры(state, f.начальноеВремяФикстуры + 2)
            switch kind {
            case "new": #expect(r.статус == "UPDATED"); #expect(state.ревизия == 2)
            case "same": #expect(r.статус == "INPUT_REVISION_REUSED"); #expect(try Data(contentsOf: f.current) == before)
            case "rollback": #expect(r.статус == "INPUT_REVISION_ROLLBACK"); #expect(try Data(contentsOf: f.current) == before)
            case "head-strict": #expect(r.статус == "HEAD_CHANGED"); #expect(try Data(contentsOf: f.current) == before)
            default:
                #expect(r.статус == "UPDATED")
                let seen = try Фикстура.прочитатьОбъектФикстуры(f.current)
                #expect(seen["HEAD"] as? String == String(repeating: "c", count: 40))
                #expect((seen["неизвестныеНамерения"] as? [String])?.contains("root-head-after-approved-input") == true)
                #expect((seen["поддержание"] as? [String: Any])?["исходныйHEAD"] as? String == String(repeating: "b", count: 40))
            }
        }
    }

    @Test func входПубликуетсяПодОбщимЗамкомИПринимаетЯвнуюОстановкуБезГит() throws {
        let фикстура = try Фикстура(); defer { фикстура.очиститьФикстуру() }
        var номер = 0
        func подготовить(_ изменить: (inout [String: Any]) -> Void) throws -> ([String], Data) {
            номер += 1
            let прежний = try Data(contentsOf: фикстура.input)
            var вход = try Фикстура.прочитатьОбъектФикстуры(фикстура.input); изменить(&вход)
            let новыеБайты = try Фикстура.сериализоватьФикстуру(вход)
            let кандидат = фикстура.кореньФикстуры.appendingPathComponent("input-candidate-\(номер).json")
            let план = фикстура.кореньФикстуры.appendingPathComponent("input-plan-\(номер).json")
            let запрос = try Data(contentsOf: фикстура.запросФикстуры)
            try Фикстура.записатьФикстуру(новыеБайты, кандидат)
            let объект: [String: Any] = ["schema": "fum.stop-maintainer-input-publication.1",
                "request": ["path": фикстура.запросФикстуры.path, "bytes": запрос.count,
                    "sha256": АтомарныеБайтыStop.sha256(запрос), "mode": 0o600],
                "candidate": ["path": кандидат.path, "bytes": новыеБайты.count,
                    "sha256": АтомарныеБайтыStop.sha256(новыеБайты), "mode": 0o600],
                "initiallyAbsent": false, "expectedSHA256": АтомарныеБайтыStop.sha256(прежний)]
            let байтыПлана = try Фикстура.сериализоватьФикстуру(объект)
            try Фикстура.записатьФикстуру(байтыПлана, план)
            return (["--передать-вход-издателя", "--план", план.path,
                "--хэш-плана", АтомарныеБайтыStop.sha256(байтыПлана)], новыеБайты)
        }
        let (аргументы, кандидат) = try подготовить { $0["revision"] = 2 }
        let исходный = try Data(contentsOf: фикстура.input)
        #expect(УстановщикStop.команда(аргументы + ["--проверить"]) == 0)
        #expect(try Data(contentsOf: фикстура.input) == исходный)
        let применить = аргументы + ["--применить", АтомарныеБайтыStop.sha256(кандидат)]
        let составДо = try FileManager.default.contentsOfDirectory(atPath: фикстура.кореньФикстуры.path).sorted()
        try ЗамокТекущегоStop.выполнить(фикстура.текущийЗамокФикстуры) { _ in
            #expect(УстановщикStop.команда(применить) != 0)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: фикстура.кореньФикстуры.path).sorted() == составДо)
        #expect(try Data(contentsOf: фикстура.input) == исходный)
        #expect(УстановщикStop.команда(применить) == 0)
        #expect(try Data(contentsOf: фикстура.input) == кандидат)
        #expect(УстановщикStop.команда(применить) != 0)
        let (откат, _) = try подготовить { $0["revision"] = 1 }
        #expect(УстановщикStop.команда(откат + ["--проверить"]) != 0)
        #expect(try Data(contentsOf: фикстура.input) == кандидат)
        let (остановить, байтыОстановки) = try подготовить {
            $0["revision"] = 3; $0["action"] = "стоп"; $0.removeValue(forKey: "payload")
            $0["approvedAt"] = 0; $0["validUntil"] = 0
        }
        try FileManager.default.removeItem(at: фикстура.файлВеткиФикстуры)
        #expect(УстановщикStop.команда(остановить + ["--проверить"]) == 0)
        #expect(УстановщикStop.команда(остановить + ["--применить",
            АтомарныеБайтыStop.sha256(байтыОстановки)]) == 0)
        let итог = try фикстура.шагФикстуры(СостояниеИздателяСтоп(), фикстура.начальноеВремяФикстуры + 2)
        #expect(итог.статус == "ROOT_CONTROL_PUBLISHED")
        let снимок = try Фикстура.прочитатьОбъектФикстуры(фикстура.current)
        #expect((снимок["управление"] as? [String: Any])?["действие"] as? String == "стоп")
        #expect(снимок["HEAD"] == nil)
    }

    @Test func неверныйТекстИЧислаВместоЛогическогоНеПеревыпускаются() throws {
        for случай in ["пробелы", "длинный", "управляющий", "ноль", "единица"] {
            let фикстура = try Фикстура(); defer { фикстура.очиститьФикстуру() }
            let путь = фикстура.кореньФикстуры.appendingPathComponent("payload.json")
            var снимок = try Фикстура.прочитатьОбъектФикстуры(путь)
            var наблюдения = try #require(снимок["наблюдения"] as? [String: Any])
            switch случай {
            case "пробелы": наблюдения["следующаяРабота"] = " "
            case "длинный": наблюдения["следующаяРабота"] = String(repeating: "я", count: 2049)
            case "управляющий": наблюдения["следующаяРабота"] = "работа\u{0001}"
            default:
                var условия = try #require(наблюдения["условия"] as? [String: Any])
                условия["естьПолномочия"] = случай == "ноль" ? 0 : 1
                наблюдения["условия"] = условия
            }
            снимок["наблюдения"] = наблюдения
            let байты = try Фикстура.сериализоватьФикстуру(снимок)
            try Фикстура.записатьФикстуру(байты, путь)
            try фикстура.изменитьВходФикстуры {
                $0["payload"] = ["path": путь.path, "bytes": байты.count,
                    "sha256": АтомарныеБайтыStop.sha256(байты), "mode": 0o600]
            }
            let до = try Data(contentsOf: фикстура.current)
            let состояние = СостояниеИздателяСтоп()
            #expect(try фикстура.шагФикстуры(состояние, фикстура.начальноеВремяФикстуры + 1).статус == "FAILED")
            #expect(try Data(contentsOf: фикстура.current) == до)
            #expect(try !FileManager.default.contentsOfDirectory(atPath: фикстура.кореньФикстуры.path)
                .contains(where: { $0.contains(".attempt.json") }))
        }
    }

    @Test func дрейфПередЗаменойИСбойКвитанцииСохраняютГраницуЭффекта() throws {
        for случай in ["current", "input", "header", "request", "singleton", "lock", "head", "outcome"] {
            let фикстура = try Фикстура(headPolicy: "observe-with-unknown"); defer { фикстура.очиститьФикстуру() }
            let состояние = СостояниеИздателяСтоп()
            let исходный = try Data(contentsOf: фикстура.current)
            var ожидаемый = исходный
            let хэшЗапроса = try АтомарныеБайтыStop.sha256(Data(contentsOf: фикстура.запросФикстуры))
            let квитанция = фикстура.кореньФикстуры.appendingPathComponent(
                ".fum-stop-maintainer-" + хэшЗапроса + ".tick-00000001.outcome.json")
            let чужаяКвитанция = Data("{\"preserve\":true}\n".utf8)
            var точки = ТочкиАтомарнойЗаменыStop()
            точки.передRename = {
                switch случай {
                case "current":
                    var объект = try Фикстура.прочитатьОбъектФикстуры(фикстура.current)
                    объект["управление"] = ["действие": "стоп", "основание": "Поздний явный ROOT STOP"]
                    ожидаемый = try Фикстура.сериализоватьФикстуру(объект)
                    _ = try АтомарныеБайтыStop.заменить(фикстура.current.path,
                        ожидаемыйSHA256: фикстура.хэшТекущегоФикстуры, новыми: ожидаемый)
                case "input":
                    try фикстура.изменитьВходФикстуры { $0["revision"] = 2; $0["action"] = "пауза" }
                case "header", "request":
                    let путь = случай == "header" ? фикстура.кореньФикстуры.appendingPathComponent("header.json") : фикстура.запросФикстуры
                    var байты = try Data(contentsOf: путь); байты.append(32)
                    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: путь.path)
                    try Фикстура.записатьФикстуру(байты, путь, mode: случай == "header" ? 0o400 : 0o600)
                case "singleton", "lock":
                    let путь = случай == "singleton" ? фикстура.замокИздателяФикстуры.path : фикстура.текущийЗамокФикстуры.path
                    let замена = фикстура.кореньФикстуры.appendingPathComponent("replacement-lock")
                    try Фикстура.записатьФикстуру(Data(), замена)
                    #expect(Darwin.rename(замена.path, путь) == 0)
                case "head":
                    try Фикстура.записатьФикстуру(Data((String(repeating: "c", count: 40) + "\n").utf8), фикстура.файлВеткиФикстуры)
                default: try Фикстура.записатьФикстуру(чужаяКвитанция, квитанция)
                }
            }
            let итог = try фикстура.шагФикстуры(состояние, фикстура.начальноеВремяФикстуры + 1, points: точки)
            if случай == "outcome" {
                #expect(итог.статус == "UNKNOWN")
                #expect(состояние.завершён)
                let после = try Data(contentsOf: фикстура.current)
                #expect(после != исходный)
                #expect(try Data(contentsOf: квитанция) == чужаяКвитанция)
                _ = try фикстура.шагФикстуры(состояние, фикстура.начальноеВремяФикстуры + 2)
                #expect(try Data(contentsOf: фикстура.current) == после)
            } else if случай == "head" {
                #expect(итог.статус == "HEAD_RECHECK")
                #expect(!состояние.завершён)
                #expect(try Data(contentsOf: фикстура.current) == исходный)
                #expect(try фикстура.шагФикстуры(состояние, фикстура.начальноеВремяФикстуры + 2).статус == "UPDATED")
            } else {
                #expect(итог.статус == "FAILED")
                #expect(состояние.завершён)
                #expect(try Data(contentsOf: фикстура.current) == ожидаемый)
            }
        }
    }
}

@Suite("Кооперативный publisher и устойчивая попытка", .serialized)
struct ПроверкиПротоколаПубликацииStop {
    private enum Инъекция: Error { case отказ }
    private struct Фикстура {
        let root: URL
        var lock: URL { root.appendingPathComponent("current.json.lock") }
        var config: URL { root.appendingPathComponent("hooks.json") }
        init() throws {
            root = URL(fileURLWithPath: "/private/tmp/fum-stop-protocol-" + UUID().uuidString.lowercased())
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            try Self.write(Data(), lock)
        }
        static func write(_ data: Data, _ path: URL, mode: Int = 0o600) throws {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
            }
            try data.write(to: path)
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)
        }
        static func json(_ o: [String: Any]) throws -> Data {
            try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys, .withoutEscapingSlashes])
        }
        func pin() throws -> СсылкаЗамкаStop {
            var s = Darwin.stat()
            guard lstat(lock.path, &s) == 0 else { throw Инъекция.отказ }
            return СсылкаЗамкаStop(path: lock.path, device: Int64(s.st_dev), inode: UInt64(s.st_ino))
        }
        func cleanup() {
            do { try FileManager.default.removeItem(at: root) }
            catch { Issue.record("Собственная fixture не удалена: \(error)") }
        }
    }
    private func refused(_ body: () throws -> Void) {
        do { try body(); Issue.record("Ожидался отказ до эффекта") } catch { }
    }

    @Test func busyНеДаётЭффектаИОсвобождаетсяПослеУспехаИОшибки() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let pin = try f.pin()
        var effects = 0
        try ЗамокТекущегоStop.выполнить(pin) { check in
            try check()
            refused { try ЗамокТекущегоStop.выполнить(pin) { _ in effects += 1 } }
        }
        #expect(effects == 0)
        refused { try ЗамокТекущегоStop.выполнить(pin) { _ in throw Инъекция.отказ } }
        try ЗамокТекущегоStop.выполнить(pin) { check in try check(); effects += 1 }
        #expect(effects == 1)
    }

    @Test func preflightВидитПубликациюПередЗамкомИЧитаетТолькоПодЗамком() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let pin = try f.pin(), path = f.root.appendingPathComponent("current.json")
        let old = Data("old-HEAD/continue".utf8), new = Data("new-HEAD/pause".utf8)
        try Фикстура.write(old, path)
        var unlockedReads = 0
        let seen = try УстановщикStop.предварительнаяПроверка(pin, передЗамком: {
            try ЗамокТекущегоStop.выполнить(pin) { _ in
                _ = try АтомарныеБайтыStop.заменить(path.path,
                    ожидаемыйSHA256: АтомарныеБайтыStop.sha256(old), новыми: new)
            }
        }, наблюдать: {
            // Независимый open FD того же inode не должен получить flock.
            do { try ЗамокТекущегоStop.выполнить(pin) { _ in unlockedReads += 1 } }
            catch { }
            return try АтомарныеБайтыStop.прочитать(path.path).данные
        })
        #expect(seen == new)
        #expect(unlockedReads == 0)
        #expect(try Data(contentsOf: path) == new)
        try ЗамокТекущегоStop.выполнить(pin) { check in try check() }
    }

    @Test func ссылкиПраваРазмерИПодменаInodeОтклоняются() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let original = try f.pin()
        let link = f.root.appendingPathComponent("hard")
        try FileManager.default.linkItem(at: f.lock, to: link)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("hardlink принят") } }
        try FileManager.default.removeItem(at: link)
        for mode in [0o644, 0o400] {
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: f.lock.path)
            refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("mode принят") } }
        }
        try Фикстура.write(Data([1]), f.lock)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("size принят") } }
        try Фикстура.write(Data(), f.lock)
        let pin = try f.pin()
        try ЗамокТекущегоStop.выполнить(pin) { check in
            let replacement = f.root.appendingPathComponent("new-lock")
            try Фикстура.write(Data(), replacement)
            #expect(Darwin.rename(replacement.path, f.lock.path) == 0)
            refused { try check() }
        }
        refused { _ = try ЗамокТекущегоStop.выполнить(pin) { _ in Issue.record("old inode принят") } }
        try FileManager.default.removeItem(at: f.lock)
        try FileManager.default.createSymbolicLink(at: f.lock, withDestinationURL: link)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("symlink принят") } }
    }

    @Test func другойPlanPathHEADИВремяНеОбходятIntentБезOutcome() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let sha = String(repeating: "a", count: 64), candidate = String(repeating: "b", count: 64)
        let first = try УстановщикStop.receiptPaths(config: f.config.path, oldSHA: sha, candidateSHA: candidate)
        #expect(first.intent.hasPrefix(f.root.path + "/.fum-stop-install-"))
        try УстановщикStop.receipt(first.intent,
            ["planPath": f.root.path + "/one/plan.json", "HEAD": "old", "time": 1])
        let second = try УстановщикStop.receiptPaths(config: f.config.path, oldSHA: sha, candidateSHA: candidate)
        #expect(first.intent == second.intent && first.key == second.key)
        refused { try УстановщикStop.receipt(second.intent,
            ["planPath": f.root.path + "/two/plan.json", "HEAD": "new", "time": 2]) }
        #expect(!FileManager.default.fileExists(atPath: first.outcome))
        let saved = try Data(contentsOf: URL(fileURLWithPath: first.intent))
        #expect(saved.range(of: Data("old".utf8)) != nil)
    }

    @Test func частичныйIntentИUNKNOWNНеУдаляютсяИНеПовторяются() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        for (index, partial) in [true, false].enumerated() {
            let p = try УстановщикStop.receiptPaths(config: f.config.path,
                oldSHA: String(repeating: "a", count: 64), candidateSHA: String(repeating: String(index), count: 64))
            if partial { try Фикстура.write(Data("{".utf8), URL(fileURLWithPath: p.intent)) }
            else {
                try УстановщикStop.receipt(p.intent, ["status": "INTENT"])
                try УстановщикStop.receipt(p.outcome, ["status": "UNKNOWN"])
            }
            let before = try Data(contentsOf: URL(fileURLWithPath: p.intent))
            var effects = 0
            do { try УстановщикStop.receipt(p.intent, ["status": "INTENT"]); effects += 1 } catch { }
            #expect(effects == 0)
            #expect(try Data(contentsOf: URL(fileURLWithPath: p.intent)) == before)
        }
    }

    @Test func первоеСозданиеАтомарноИСохраняетПоявившуюсяЦель() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let target = f.root.appendingPathComponent("current.json")
        let data = Data("first".utf8), foreign = Data("foreign".utf8)
        let r = try АтомарныеБайтыStop.создатьЕслиОтсутствует(target.path, новыми: data)
        #expect(r.данные == data)
        refused { _ = try АтомарныеБайтыStop.создатьЕслиОтсутствует(target.path, новыми: foreign) }
        #expect(try Data(contentsOf: target) == data)
        try FileManager.default.removeItem(at: target)
        var points = ТочкиАтомарнойЗаменыStop()
        points.передRename = { try Фикстура.write(foreign, target) }
        refused { _ = try АтомарныеБайтыStop.записать(target.path,
            ожидаемыйSHA256: nil, новыми: data, точки: points) }
        #expect(try Data(contentsOf: target) == foreign)
    }

    @Test func publisherCLIПроверяетСоздаётИЗаменяетПодТемЖеЗамком() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let root = f.root.path, common = root + "/git", gitDir = common + "/worktrees/synthetic"
        let w = root + "/W", ref = "refs/heads/fum/synthetic/master"
        for p in [gitDir, common + "/refs/heads/fum/synthetic", w] {
            try FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
        }
        for (path, text) in [(w + "/.git", "gitdir: \(gitDir)\n"),
            (gitDir + "/gitdir", "\(w)/.git\n"), (gitDir + "/commondir", "../..\n"),
            (gitDir + "/HEAD", "ref: \(ref)\n"), (common + "/" + ref, String(repeating: "b", count: 40) + "\n")] {
            try Фикстура.write(Data(text.utf8), URL(fileURLWithPath: path))
        }
        let current = root + "/current.json", source = String(repeating: "a", count: 40)
        let headerURL = f.root.appendingPathComponent("header.json")
        let header: [String: Any] = ["схема": "fum.stop-заголовок.2",
            "задача": "00000000-0000-4000-8000-000000000001", "узел": "synthetic",
            "область": "test", "поколение": "generation1", "cwd": w, "дерево": w,
            "ref": ref, "gitDir": gitDir, "commonGitDir": common, "backend": "files",
            "objectFormat": "sha1", "исходники": source, "состояние": current,
            "каталогКвитанций": root, "максимальныйВозрастСекунд": 900]
        let headerData = try Фикстура.json(header)
        try Фикстура.write(headerData, headerURL, mode: 0o400)
        let headerSHA = АтомарныеБайтыStop.sha256(headerData)
        var snapshot: [String: Any] = ["схема": "fum.текущие-обязательства-stop.2",
            "заголовокSHA256": headerSHA, "задача": header["задача"]!, "узел": "synthetic",
            "область": "test", "поколение": "generation1",
            "управление": ["действие": "стоп", "основание": "Синтетическая проверка"]]
        let pin = try f.pin()
        let candidateURL = f.root.appendingPathComponent("candidate.json")
        let planURL = f.root.appendingPathComponent("plan.json")
        func run(_ initiallyAbsent: Bool, expected: String?, check: Bool) throws -> Int32 {
            let bytes = try Фикстура.json(snapshot)
            try Фикстура.write(bytes, candidateURL)
            var plan: [String: Any] = ["schema": "fum.stop-current-publication.1", "source": source,
                "header": ["path": headerURL.path, "bytes": headerData.count, "sha256": headerSHA, "mode": 0o400],
                "candidate": ["path": candidateURL.path, "bytes": bytes.count, "sha256": АтомарныеБайтыStop.sha256(bytes), "mode": 0o600],
                "current": ["path": current, "mode": 0o600, "maxBytes": 32768,
                    "lock": ["path": pin.path, "device": pin.device, "inode": pin.inode]],
                "initiallyAbsent": initiallyAbsent]
            if let expected { plan["expectedSHA256"] = expected }
            let data = try Фикстура.json(plan); try Фикстура.write(data, planURL)
            var argv = ["--опубликовать-текущий", "--план", planURL.path,
                "--хэш-плана", АтомарныеБайтыStop.sha256(data)]
            argv += check ? ["--проверить"] : ["--применить", АтомарныеБайтыStop.sha256(bytes)]
            return УстановщикStop.команда(argv)
        }
        // Доверенный минимальный STOP и пауза должны публиковаться даже при
        // недоступных Git-метаданных и без срока рабочего снимка.
        try FileManager.default.removeItem(atPath: common + "/" + ref)
        #expect(try run(true, expected: nil, check: true) == 0)
        #expect(!FileManager.default.fileExists(atPath: current))
        #expect(try run(true, expected: nil, check: false) == 0)
        let first = try АтомарныеБайтыStop.прочитать(current)
        #expect(first.данные == (try Фикстура.json(snapshot)))
        #expect(try run(true, expected: nil, check: false) != 0)
        snapshot["управление"] = ["действие": "пауза", "основание": "Следующий синтетический снимок"]
        #expect(try run(false, expected: first.sha256, check: false) == 0)
        #expect(try АтомарныеБайтыStop.прочитать(current).данные == Фикстура.json(snapshot))
        #expect(try run(false, expected: first.sha256, check: false) != 0)
        let finalSHA = try АтомарныеБайтыStop.sha256(Фикстура.json(snapshot))
        try ЗамокТекущегоStop.выполнить(pin) { _ in
            let busyCode = try run(false, expected: finalSHA, check: true)
            #expect(busyCode != 0)
        }
    }
}

@Suite("Атомарные байты Stop: собственные filesystem fixtures", .serialized)
struct ПроверкиАтомарныхБайтовStop {
    private enum Инъекция: Error { case отказ }
    private struct Фикстура {
        let корень: URL
        let цель: URL
        let чужой: URL
        let старые = Data("{\"FUMStop\":\"old\",\"GitKrakenStop\":{\"keep\":true}}\n".utf8)
        let новые = Data("{\"FUMStop\":\"new\",\"GitKrakenStop\":{\"keep\":true}}\n".utf8)
        let чужие = Data("{\"foreign\":\"оставить побайтно\"}\n".utf8)
        init() throws {
            корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
                .appendingPathComponent("fum-atomic-stop-\(UUID().uuidString.lowercased())")
            цель = корень.appendingPathComponent("hooks.json")
            чужой = корень.appendingPathComponent("foreign.json")
            try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            try Self.записать(старые, цель)
            try Self.записать(чужие, чужой)
        }
        static func записать(_ d: Data, _ p: URL, режим: Int = 0o600) throws {
            if FileManager.default.fileExists(atPath: p.path) {
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: p.path)
            }
            try d.write(to: p)
            try FileManager.default.setAttributes([.posixPermissions: режим], ofItemAtPath: p.path)
        }
        func очистить() {
            do { try FileManager.default.removeItem(at: корень) }
            catch { Issue.record("Собственная fixture не удалена: \(error)") }
        }
        var старыйSHA: String { АтомарныеБайтыStop.sha256(старые) }
        func заменить(_ точки: ТочкиАтомарнойЗаменыStop = ТочкиАтомарнойЗаменыStop())
            throws -> СнимокБайтовStop {
            try АтомарныеБайтыStop.заменить(цель.path, ожидаемыйSHA256: старыйSHA,
                новыми: новые, точки: точки)
        }
        func безВременных() throws -> Bool {
            try FileManager.default.contentsOfDirectory(atPath: корень.path)
                .allSatisfy { !$0.hasPrefix(".fum-stop-") }
        }
    }

    private func отказ(_ граница: ГраницаОтказаStop,
                       _ действие: () throws -> Void) -> ОтказАтомарнойЗаменыStop? {
        do { try действие(); Issue.record("Ожидался типизированный отказ"); return nil }
        catch let e as ОтказАтомарнойЗаменыStop {
            #expect(e.граница == граница)
            #expect(!e.фаза.isEmpty)
            return e
        } catch { Issue.record("Неверный тип ошибки: \(error)"); return nil }
    }

    @Test func точныеБайтыРежимИЧужойJSONНеМеняется() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let r = try ф.заменить()
        #expect(r.данные == ф.новые)
        #expect(r.sha256 == АтомарныеБайтыStop.sha256(ф.новые))
        #expect(r.отпечаток.режим & 0o7777 == 0o600)
        #expect(r.отпечаток.ссылки == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try Data(contentsOf: ф.чужой) == ф.чужие)
        #expect(try ф.безВременных())
    }

    @Test func неверныйОжидаемыйSHAНеПишет() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let e = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.заменить(ф.цель.path,
                ожидаемыйSHA256: String(repeating: "0", count: 64), новыми: ф.новые)
        }
        #expect(e?.фаза == "ожидаемый-SHA")
        #expect(e?.наблюдаемыйSHA256 == ф.старыйSHA)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func ссылкиНаЦельИРодителяОтклоняются() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let ссылка = ф.корень.appendingPathComponent("link.json")
        try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: ф.цель)
        let настоящий = ф.корень.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: настоящий, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вложенный = настоящий.appendingPathComponent("hooks.json")
        try Фикстура.записать(ф.старые, вложенный)
        let alias = ф.корень.appendingPathComponent("alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: настоящий)
        for p in [ссылка, alias.appendingPathComponent("hooks.json")] {
            _ = отказ(.доRename) {
                _ = try АтомарныеБайтыStop.заменить(p.path,
                    ожидаемыйSHA256: ф.старыйSHA, новыми: ф.новые)
            }
        }
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try Data(contentsOf: вложенный) == ф.старые)
    }

    @Test func hardlinkПраваИРазмерОтклоняются() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let link = ф.корень.appendingPathComponent("hard.json")
        try FileManager.default.linkItem(at: ф.цель, to: link)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        try FileManager.default.removeItem(at: link)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: ф.цель.path)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        let большие = Data(repeating: 0x61, count: 1_048_577)
        try Фикстура.записать(большие, ф.цель)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        #expect(try Data(contentsOf: ф.цель) == большие)
        #expect(try ф.безВременных())
    }

    @Test func driftПередRenameСохраняетВнешнееИзменение() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let изменённые = Data("{\"external\":\"новое значение\"}\n".utf8)
        var т = ТочкиАтомарнойЗаменыStop()
        т.передRename = { try Фикстура.записать(изменённые, ф.цель) }
        let e = отказ(.доRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "сверка-старого")
        #expect(e?.наблюдаемыйSHA256 == АтомарныеБайтыStop.sha256(изменённые))
        #expect(try Data(contentsOf: ф.цель) == изменённые)
        #expect(try ф.безВременных())
    }

    @Test func отказКонтроляНепосредственноПередRenameСохраняетСтарое() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var точки = ТочкиАтомарнойЗаменыStop()
        точки.передRename = { throw Инъекция.отказ }
        let e = отказ(.доRename) { _ = try ф.заменить(точки) }
        #expect(e?.фаза == "перед-rename")
        #expect(e?.наблюдаемыйSHA256 == ф.старыйSHA)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func отказFsyncФайлаДоRenameСохраняетСтарое() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var число = 0
        var т = ТочкиАтомарнойЗаменыStop()
        т.синхронизацияФайла = { _ in число += 1; throw Инъекция.отказ }
        let e = отказ(.доRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "fsync-файла")
        #expect(число == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func отказFsyncКаталогаПослеRenameЭтоUNKNOWNБезПовтора() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var число = 0
        var т = ТочкиАтомарнойЗаменыStop()
        т.синхронизацияКаталога = { _ in число += 1; throw Инъекция.отказ }
        let e = отказ(.послеRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "fsync-каталога")
        #expect(e?.наблюдаемыйSHA256 == АтомарныеБайтыStop.sha256(ф.новые))
        #expect(число == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try Data(contentsOf: ф.чужой) == ф.чужие)
        #expect(try ф.безВременных())
    }

    @Test func отказЧтенияПослеRenameНеВозвращаетПрежнийSHA() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var точки = ТочкиАтомарнойЗаменыStop()
        точки.синхронизацияКаталога = { _ in
            try FileManager.default.setAttributes([.posixPermissions: 0o400],
                ofItemAtPath: ф.цель.path)
            throw Инъекция.отказ
        }
        let e = отказ(.послеRename) { _ = try ф.заменить(точки) }
        #expect(e?.фаза == "fsync-каталога")
        #expect(e?.наблюдаемыйSHA256 == nil)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try ф.безВременных())
    }

    @Test func общийReaderТочныеРежимыMetadataPolicyИПредел() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        for режим in [mode_t(0o400), mode_t(0o500)] {
            try FileManager.default.setAttributes(
                [.posixPermissions: Int(режим)], ofItemAtPath: ф.цель.path)
            let r = try АтомарныеБайтыStop.прочитать(ф.цель.path, ожидаемыйРежим: режим)
            #expect(r.данные == ф.старые)
            #expect(r.sha256 == ф.старыйSHA)
            #expect(r.отпечаток.режим & 0o7777 == режим)
            _ = отказ(.доRename) { _ = try АтомарныеБайтыStop.прочитать(ф.цель.path) }
        }
        try Фикстура.записать(ф.старые, ф.цель, режим: 0o644)
        #expect(try АтомарныеБайтыStop.прочитать(
            ф.цель.path, ожидаемыйРежим: nil).данные == ф.старые)
        _ = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.прочитать(
                ф.цель.path, ожидаемыйРежим: nil, предел: ф.старые.count - 1)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o664], ofItemAtPath: ф.цель.path)
        _ = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.прочитать(ф.цель.path, ожидаемыйРежим: nil)
        }
    }
}

@Suite("Точная граница команды Stop", .serialized)
struct ПроверкиДельтыКомандыStop {
    private struct Фикстура {
        let old: Data
        let candidate: Data
        let offset: Int
        let length: Int
        let oldSHA: String
        let command: String

        static func json(_ object: Any) throws -> Data {
            try JSONSerialization.data(withJSONObject: object,
                options: [.sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
        }

        init() throws {
            let oldCommand = "exec '/synthetic-old/fuma' 'stop'"
            let newCommand = "exec /usr/bin/env -i 'PATH=' '/synthetic-new/fuma' 'stop'"
            let foreign: [String: Any] = ["type": "command", "command": "keep-foreign", "timeout": 90]
            let target: [String: Any] = ["type": "command", "command": oldCommand, "timeout": 90]
            let stops: [[String: Any]] = [["hooks": [foreign]], ["hooks": [target]]]
            let object: [String: Any] = ["hooks": ["Stop": stops], "keep": "Ёж"]
            let bytes = try Self.json(object)
            let token = try Self.json(oldCommand)
            let range = try #require(bytes.range(of: token))
            let replacement = try Self.json(newCommand)
            var changed = bytes
            changed.replaceSubrange(range, with: replacement)
            old = bytes; candidate = changed
            offset = range.lowerBound; length = token.count
            oldSHA = АтомарныеБайтыStop.sha256(Data(oldCommand.utf8))
            command = newCommand
        }

        func проверить(_ bytes: Data? = nil, offset: Int? = nil, length: Int? = nil,
                       sha: String? = nil, command: String? = nil) throws {
            try УстановщикStop.проверитьДельту(old: old, candidate: bytes ?? candidate,
                offset: offset ?? self.offset, length: length ?? self.length,
                oldCommandSHA256: sha ?? oldSHA, newCommand: command ?? self.command)
        }
    }

    @Test func разрешенаТолькоОднаКомандаСПобайтнымСохранениемОстального() throws {
        let ф = try Фикстура()
        try ф.проверить()
        #expect(ф.candidate.prefix(ф.offset) == ф.old.prefix(ф.offset))
        let tail = ф.old.count - ф.offset - ф.length
        #expect(ф.candidate.suffix(tail) == ф.old.suffix(tail))
        let object = try #require(try JSONSerialization.jsonObject(with: ф.candidate) as? [String: Any])
        #expect(object["keep"] as? String == "Ёж")
    }

    @Test func чужаяДельтаНеверныеГраницыХэшИКомандаОтвергаются() throws {
        let ф = try Фикстура()
        var before = ф.candidate; before[0] = 0x5b
        var after = ф.candidate; after.append(10)
        let cases: [() throws -> Void] = [
            { try ф.проверить(before) },
            { try ф.проверить(after) },
            { try ф.проверить(offset: ф.offset + 1) },
            { try ф.проверить(length: 0) },
            { try ф.проверить(sha: String(repeating: "0", count: 64)) },
            { try ф.проверить(command: "unexpected-command") }
        ]
        for действие in cases {
            do { try действие(); Issue.record("Недопустимая дельта принята") }
            catch { }
        }
    }

    @Test func чистоеОкружениеИАпострофФормируютсяКакТочныеАргументы() {
        let value = УстановщикStop.command(["/private/tmp/a'b/fuma", "stop"])
        #expect(value == "exec /usr/bin/env -i 'PATH=' '/private/tmp/a'\"'\"'b/fuma' 'stop'")
    }
}
