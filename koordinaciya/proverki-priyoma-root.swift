import Foundation
import CryptoKit
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import RootAcceptance

private final class ФлагПриёма { var значение = false }
private func отказПриёма(_ f: () throws -> Void) -> Bool { do { try f(); return false } catch { return true } }
private final class ФикстураПриёмаROOT {
    let dir: URL
    let W: URL
    let remote: URL
    let grant: URL
    let ref: String
    let L: String
    let M: String
    let tree: String
    let native: String
    var среда: СредаПриёмаROOT
    static func команда(_ executable: String, _ args: [String], cwd: URL, logs: URL, env: [String: String] = [:], input: Data? = nil) throws -> (Int32, Data) {
        let d = logs.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let out = d.appendingPathComponent("stdout"), err = d.appendingPathComponent("stderr")
        try Data().write(to: out); try Data().write(to: err)
        let oh = try FileHandle(forWritingTo: out), eh = try FileHandle(forWritingTo: err)
        defer { try? oh.close(); try? eh.close() }
        let p = Process(); p.executableURL = URL(fileURLWithPath: executable); p.arguments = args; p.currentDirectoryURL = cwd
        p.environment = АдаптерВыполненияКомандGit.окружениеИзолированногоGit().merging(env) { _, b in b }
        p.standardOutput = oh; p.standardError = eh
        let pipe = Pipe(); p.standardInput = pipe; try p.run()
        if let input { try pipe.fileHandleForWriting.write(contentsOf: input) }; try pipe.fileHandleForWriting.close(); p.waitUntilExit()
        try oh.synchronize(); try eh.synchronize()
        let b = try Data(contentsOf: out)
        try байтыПриёмаROOT(ПроцессПриёмаROOT(executable: executable, argv: args, cwd: cwd.path, exit: p.terminationStatus, signal: p.terminationReason == .uncaughtSignal, stdoutSHA256: хэшПриёмаROOT(b), stderrSHA256: хэшПриёмаROOT(try Data(contentsOf: err)))).write(to: d.appendingPathComponent("process.json"))
        return (p.terminationStatus, b)
    }
    func git(_ args: [String]) throws -> String {
        let r = try Self.команда("/usr/bin/git", ["-C", W.path] + args, cwd: dir, logs: dir.appendingPathComponent("setup"))
        guard r.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture git") }
        return String(decoding: r.1, as: UTF8.self).trimmingCharacters(in: .newlines)
    }
    init() throws {
        let e = ProcessInfo.processInfo.environment
        let config = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: e["ROOT_FIXTURE_CONFIG"]!))) as! [String: Any]
        dir = URL(fileURLWithPath: e["ROOT_FIXTURE_ROOT"]!).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        W = dir.appendingPathComponent("tree with spaces;")
        remote = dir.appendingPathComponent("remote.git")
        grant = dir.appendingPathComponent("grant.json")
        native = e["CODEX_THREAD_ID"]!
        ref = "refs/heads/codex/root-acceptance-" + UUID().uuidString.lowercased()
        let setup = dir.appendingPathComponent("setup")
        let bare = try Self.команда("/usr/bin/git", ["init", "--bare", remote.path], cwd: dir, logs: setup)
        let initGit = try Self.команда("/usr/bin/git", ["init", "--initial-branch", String(ref.dropFirst("refs/heads/".count)), W.path], cwd: dir, logs: setup)
        guard bare.0 == 0 && initGit.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture init") }
        // Инициализация полей завершается до вызова instance git.
        let working = W, fixtureDir = dir
        func g(_ args: [String]) throws -> String {
            let r = try Self.команда("/usr/bin/git", ["-C", working.path] + args, cwd: fixtureDir, logs: setup)
            guard r.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture setup") }
            return String(decoding: r.1, as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        _ = try g(["config", "user.name", "FUM"]); _ = try g(["config", "user.email", "fum@local"])
        _ = try g(["config", "commit.gpgSign", "false"])
        try Data("base\n".utf8).write(to: W.appendingPathComponent("base.txt"))
        _ = try g(["add", "--", "base.txt"]); _ = try g(["commit", "-m", "Synthetic fixture base"])
        let base = try g(["rev-parse", "HEAD"])
        let name = "путь с пробелом;$(echo nope).txt"
        try Data("incoming\n".utf8).write(to: W.appendingPathComponent(name))
        _ = try g(["add", "--", name]); _ = try g(["commit", "-m", "Synthetic incoming source"])
        M = try g(["rev-parse", "HEAD"])
        _ = try g(["reset", "--hard", base])
        try Data("own branch\n".utf8).write(to: W.appendingPathComponent("own.txt"))
        _ = try g(["add", "--", "own.txt"]); _ = try g(["commit", "-m", "Synthetic own divergent source"])
        L = try g(["rev-parse", "HEAD"])
        tree = try g(["merge-tree", "--write-tree", L, M])
        _ = try g(["remote", "add", "origin", remote.absoluteString])
        _ = try g(["push", "origin", L + ":" + ref])
        let stateFile = dir.appendingPathComponent("metadata-state.json")
        var state = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: config["template"] as! String))) as! [String: Any]
        // Конечная fixture проецирует только поля существующего Decodable-контракта;
        // закрытые отчёты/истории не копируются в каждый metadata input.
        let fields: Set<String> = ["схема", "корневойUUID", "принятаяОснова", "собственныйСтарт", "модельУзла", "корневойWorktree", "задачи", "переходыСостояния", "поставки", "переходыАвтоматизации", "планСамообновления"]
        state = state.filter { fields.contains($0.key) }
        for key in ["задачи", "переходыСостояния", "поставки", "переходыАвтоматизации"] { state[key] = [Any]() }
        var plan = state["планСамообновления"] as! [String: Any]
        plan["источники"] = [Any]() // fixture metadata API, не общая приёмка/self-update
        var identity = plan["идентичностьСледующегоКоммита"] as! [String: Any]
        identity["родитель"] = L; plan["идентичностьСледующегоКоммита"] = identity; plan["собственныйРеф"] = ref
        state["планСамообновления"] = plan
        try JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]).write(to: stateFile)
        var variables = config["environment"] as! [String: String]
        for k in ["KOORDINACIYA_FUMA_RUN_ROOT", "FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"] {
            let p = dir.appendingPathComponent(k)
            try FileManager.default.createDirectory(at: p, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]); variables[k] = p.path
        }
        let segment = dir.appendingPathComponent("segment"), logs = dir.appendingPathComponent("processes")
        for d in [segment, logs] { try FileManager.default.createDirectory(at: d, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
        среда = СредаПриёмаROOT(metadataCLI: config["metadataCLI"] as! String, metadataState: stateFile.path, программа: config["program"] as! String, переменные: variables, segment: segment, logs: logs)
        var pins = try JSONDecoder().decode([PinПриёмаROOT].self, from: JSONSerialization.data(withJSONObject: config["pins"]!))
        pins.append(PinПриёмаROOT(путь: stateFile.path, sha256: хэшПриёмаROOT(try Data(contentsOf: stateFile))))
        let p = ПоручениеПриёмаROOT(схема: "fum.root-acceptance-program.1", идентификатор: "fixture-" + UUID().uuidString, ROOT: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", писатель: native, W: W.path, ref: ref, origin: remote.absoluteString, L: L, M: M, дерево: tree, пути: [name], pins: pins)
        try байтыПриёмаROOT(p).write(to: grant)
    }
    func контекст(_ variables: [String: String]? = nil, stop: @escaping () -> Bool = { false }, revoked: @escaping () -> Bool = { false }, actor: String? = nil) throws -> ПодготовленныйКонтекстПриёмаROOT {
        let s = СредаПриёмаROOT(metadataCLI: среда.metadataCLI, metadataState: среда.metadataState, программа: среда.программа, переменные: variables ?? среда.переменные, segment: среда.segment, logs: среда.logs)
        return try .дляЛокальнойФикстуры(поручение: grant, ожидаемыйSHA256: хэшПриёмаROOT(try Data(contentsOf: grant)), среда: s, native: { actor ?? self.native }, stop: stop, revoked: revoked)
    }
    func завершить(_ r: ПрограммаПриёмаROOT) throws -> ИсходПриёмаROOT {
        var result = ИсходПриёмаROOT(стадия: "prepare", commit: nil, повтор: false)
        for _ in 0..<8 { result = try r.выполнить(); if result.стадия == "delivered" || result.стадия == "held" { return result } }
        throw ОшибкаПриёмаROOT.отказ("fixture step budget")
    }
    func число(_ verb: String) throws -> Int {
        let files = FileManager.default.enumerator(at: среда.logs, includingPropertiesForKeys: nil)!
        var n = 0
        for case let f as URL in files where f.lastPathComponent == "process.json" {
            let r = try JSONDecoder().decode(ПроцессПриёмаROOT.self, from: Data(contentsOf: f))
            var i = 0
            while i + 1 < r.argv.count && ["-c", "-C"].contains(r.argv[i]) { i += 2 }
            if r.executable == "/usr/bin/git" && i < r.argv.count && r.argv[i] == verb { n += 1 }
        }
        return n
    }
}

@Suite(.serialized) struct ПроверкиПрограммыПриёмаROOT {

    @Test(arguments: 0..<6) func НеизвестныйВыборНеСоздаётТипизированногоАвтора(_ номер: Int) throws {
        let модель = номер == 0 ? "UNKNOWN" : (номер == 2 ? "" : (номер == 4 ? "gpt-test\nforged" : "gpt-test"))
        let усилие = номер == 1 ? "UNKNOWN" : (номер == 3 ? "" : (номер == 5 ? "max forged" : "high"))
        let вход = ПакетВходаГенератораFUMA(cases: [ВходСлучаяГенератораFUMA(id: "unknown-selection-test",
            acceptedSelection: ПараметрыВыбораAPI(model: модель, reasoningEffort: усилие),
            rootUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", title: "Проверить автора",
            description: "Синтетический вход, не наблюдение реальной модели.", rawRequest: "Фикстура")])
        let выход = try #require(ГенераторМетаданныхКоммита.referenceOutput(for: вход).cases.first)
        #expect(выход.environment == ["GIT_AUTHOR_NAME": "FUM Codex (выбор UNKNOWN)"])
    }
    @Test func ИзвестныйВыборСохраняетЯвноеИмяАвтора() throws {
        let вход = ПакетВходаГенератораFUMA(cases: [ВходСлучаяГенератораFUMA(id: "known-selection-test",
            acceptedSelection: ПараметрыВыбораAPI(model: "gpt-test", reasoningEffort: "high"),
            rootUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", title: "Проверить автора",
            description: "Только проверка форматирования; receipt/authority не подтверждены.", rawRequest: "Фикстура")])
        let выход = try #require(ГенераторМетаданныхКоммита.referenceOutput(for: вход).cases.first)
        #expect(выход.environment == ["GIT_AUTHOR_NAME": "FUM Codex [gpt-test; effort=high]"])
    }
    @Test func ЯвныйАвторПобеждаетСохранённыйLocalAuthorNameБезКоммитов() throws {
        // Existing finite process seam; no full ROOT fixture, commit, index, remote or history.
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent("author-precedence-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let репозиторий = каталог.appendingPathComponent("repository"), логи = каталог.appendingPathComponent("logs")
        let изоляция = ["PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C",
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_SYSTEM": "/dev/null", "GIT_CONFIG_GLOBAL": "/dev/null"]
        let начало = try ФикстураПриёмаROOT.команда("/usr/bin/env",
            ["-i"] + изоляция.keys.sorted().map { $0 + "=" + изоляция[$0]! } + ["/usr/bin/git", "init", репозиторий.path],
            cwd: каталог, logs: логи)
        #expect(начало.0 == 0)
        let адрес = ["--no-optional-locks", "--no-lazy-fetch", "--no-replace-objects", "--literal-pathspecs",
            "--git-dir=" + репозиторий.appendingPathComponent(".git").path, "--work-tree=" + репозиторий.path]

        func гит(_ аргументы: [String], _ окружение: [String: String] = [:]) throws -> String {
            let среда = изоляция.merging(окружение) { _, новое in новое }
            let исход = try ФикстураПриёмаROOT.команда("/usr/bin/env",
                ["-i"] + среда.keys.sorted().map { $0 + "=" + среда[$0]! } + ["/usr/bin/git"] + адрес + аргументы,
                cwd: репозиторий, logs: логи)
            guard исход.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("author-precedence-fixture") }
            return String(decoding: исход.1, as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        _ = try гит(["config", "--local", "author.name", "FUM Писатель"])
        _ = try гит(["config", "--local", "user.name", "FUM"])
        _ = try гит(["config", "--local", "user.email", "fixture-config@invalid"])
        let прежний = ГенераторМетаданныхКоммита.разобратьGitIdent(try гит(["var", "GIT_AUTHOR_IDENT"]))
        let толькоUser = ГенераторМетаданныхКоммита.разобратьGitIdent(try гит(["-c", "user.name=Different user", "var", "GIT_AUTHOR_IDENT"]))
        #expect(прежний?.имя == "FUM Писатель")
        #expect(толькоUser?.имя == "FUM Писатель")
        let вход = ПакетВходаГенератораFUMA(cases: [ВходСлучаяГенератораFUMA(id: "author-test",
            acceptedSelection: ПараметрыВыбораAPI(model: "gpt-test", reasoningEffort: "high"),
            rootUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", title: "Проверить приоритет автора",
            description: "Синтетическая selection/почта; не live identity исполнителя.", rawRequest: "Фикстура")])
        let выход = try #require(ГенераторМетаданныхКоммита.referenceOutput(for: вход).cases.first)
        // Email is explicit synthetic fixture identity, never inferred from an actual actor.
        let явное = выход.environment.merging(["GIT_AUTHOR_EMAIL": "fixture-explicit@invalid"]) { _, новое in новое }
        let автор = ГенераторМетаданныхКоммита.разобратьGitIdent(try гит(["var", "GIT_AUTHOR_IDENT"], явное))
        #expect(автор == ИдентификаторGit(имя: "FUM Codex [gpt-test; effort=high]", почта: "fixture-explicit@invalid"))
        #expect(try гит(["config", "--local", "--get-all", "author.name"]) == "FUM Писатель")
        #expect(try гит(["config", "--local", "--get", "user.name"]) == "FUM")
        #expect(try гит(["config", "--local", "--get", "user.email"]) == "fixture-config@invalid")
    }
    @Test func исходникиUNKNOWNНеСоздаютПодтверждённыйВыбор() throws {
        let запрос = ЗапросМетаданныхИсходников(схема: "fum.source-checkpoint-metadata-request.1",
            корневойUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
            писатель: "01a192d0-6f09-7950-9251-b27101106bfc", рабочееДерево: "/fixture",
            реф: "refs/heads/fixture", родитель: String(repeating: "1", count: 40),
            дерево: String(repeating: "2", count: 40), статусВыбора: "UNKNOWN",
            основаниеSHA256: String(repeating: "3", count: 64),
            план: ПланСообщенияКоммита(исходныйЗапрос: "Фикстура исходников", заголовок: "Сохранить исходники",
                описание: "Проверки и выбор модели UNKNOWN"))
        let эталон = ГенераторМетаданныхКоммита.referenceOutput(for: запрос.входФорматтера).cases[0]
        let метаданные = МетаданныеИсходников.подготовить(запрос: запрос,
            выход: ВыходГенератораGitMetadata(environment: эталон.environment, message: эталон.message),
            авторGit: "\(эталон.environment["GIT_AUTHOR_NAME"]!) <fixture@local> 0 +0000",
            коммитерGit: "FUM Писатель <fixture@local> 0 +0000")
        #expect(метаданные.ошибки.isEmpty)
        let данные = try JSONEncoder().encode(метаданные)
        #expect(отказПриёма { _ = try JSONDecoder().decode(РезультатГенерацииМетаданныхКоммита.self, from: данные) })
        let сырой = Data(("tree \(запрос.дерево)\nparent \(запрос.родитель)\n" +
            "author \(метаданные.автор.имя) <fixture@local> 0 +0000\n" +
            "committer FUM Писатель <fixture@local> 0 +0000\n\n" + эталон.message).utf8)
        #expect(ОценщикИдентичностиGit.проверитьСырыеИсходники(сырой, метаданные: метаданные).isEmpty)
        let подмена = Data(String(decoding: сырой, as: UTF8.self).replacingOccurrences(
            of: "committer FUM Писатель", with: "committer Другой").utf8)
        #expect(ОценщикИдентичностиGit.проверитьСырыеИсходники(подмена, метаданные: метаданные).contains("сырой-committer-не-совпадает"))
    }
    @Test func типизированныйАвторПобеждаетЛокальноеИмяПисателя() throws {
        let фикстура = try ФикстураПриёмаROOT()
        _ = try фикстура.git(["config", "--local", "author.name", "FUM Писатель"])
        _ = try фикстура.git(["config", "--local", "user.name", "FUM Писатель"])
        let программа = try ПрограммаПриёмаROOT(фикстура.контекст())
        defer { программа.закрыть() }
        let исход = try фикстура.завершить(программа)
        let метаданные = try #require(программа.подготовленныеМетаданные)
        let коммит = try #require(исход.commit)
        let сырой = try фикстура.git(["cat-file", "commit", коммит])
        let строки = сырой.components(separatedBy: "\n\n")[0].components(separatedBy: "\n")
        let автор = строки.first { $0.hasPrefix("author ") }.map { String($0.dropFirst(7)) } ?? ""
        let коммитер = строки.first { $0.hasPrefix("committer ") }.map { String($0.dropFirst(10)) } ?? ""
        #expect(ГенераторМетаданныхКоммита.разобратьGitIdent(автор) == метаданные.автор)
        #expect(метаданные.автор.имя != "FUM Писатель")
        #expect(ГенераторМетаданныхКоммита.разобратьGitIdent(коммитер) == метаданные.коммитер)
        #expect(строки.filter { $0.hasPrefix("parent ") } == ["parent " + фикстура.L, "parent " + фикстура.M])
        #expect(try фикстура.число("commit") == 1)
    }
    @Test func ПодменаCheckpointНеПодтверждаетДоставку() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст()
        let segment = try Сегмент(кореньДанных: f.среда.segment, запись: true)
        let intent: [String: Any] = ["context":c.хэш,"номер":0,"вид":"intent","стадия":"prepare","следующая":"exact"]
        let a = try segment.добавить(ОписаниеНаблюдения(идентификатор:"forged-0",тип:"root-acceptance"),данные:JSONSerialization.data(withJSONObject:intent,options:[.sortedKeys]))
        let outcome: [String: Any] = ["context":c.хэш,"номер":1,"предыдущая":a.хэш,"вид":"outcome","стадия":"prepare","следующая":"delivered","commit":f.L]
        _ = try segment.добавить(ОписаниеНаблюдения(идентификатор:"forged-1",тип:"root-acceptance"),данные:JSONSerialization.data(withJSONObject:outcome,options:[.sortedKeys]))
        segment.закрыть()
        #expect(отказПриёма { _ = try ПрограммаПриёмаROOT(c) })
        #expect(try f.число("merge") == 0)
        #expect(try f.число("push") == 0)
    }
    @Test func TerminalReceiptТребуетСвежийRemote() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        let done = try f.завершить(r); r.закрыть()
        let changed = try ФикстураПриёмаROOT.команда("/usr/bin/git",["--git-dir",f.remote.path,"update-ref",f.ref,f.L,done.commit!],cwd:f.dir,logs:f.dir.appendingPathComponent("remote-change"))
        #expect(changed.0 == 0)
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("push") == 1)
    }
    @Test func обязательноеОкружениеПроверяетсяДоЭффекта() throws {
        let f = try ФикстураПриёмаROOT()
        for k in ["KOORDINACIYA_FUMA_DEFINITION", "KOORDINACIYA_FUMA_OPERATOR", "KOORDINACIYA_FUMA_RUN_ROOT"] {
            var env = f.среда.переменные; env.removeValue(forKey: k)
            #expect(отказПриёма { _ = try f.контекст(env) })
        }
        #expect(try f.git(["rev-parse", "HEAD"]) == f.L)
        #expect(try f.число("merge") == 0)
        let original = try Data(contentsOf: f.grant)
        let selected = f.среда.переменные["KOORDINACIYA_FUMA_OPERATOR"]!
        let alias = f.dir.appendingPathComponent("operator-alias")
        try FileManager.default.createSymbolicLink(atPath: alias.path, withDestinationPath: selected)
        var aliasGrant = try JSONSerialization.jsonObject(with: original) as! [String: Any]
        aliasGrant["pins"] = (aliasGrant["pins"] as! [[String: String]]).map { pin in
            pin["путь"] == selected ? ["путь": alias.path, "sha256": pin["sha256"]!] : pin
        }
        try JSONSerialization.data(withJSONObject: aliasGrant).write(to: f.grant)
        var aliasEnv = f.среда.переменные; aliasEnv["KOORDINACIYA_FUMA_OPERATOR"] = alias.path
        #expect(отказПриёма { _ = try f.контекст(aliasEnv) })
        try original.write(to: f.grant)
        var wrong = try JSONSerialization.jsonObject(with: Data(contentsOf: f.grant)) as! [String: Any]
        wrong["ROOT"] = UUID().uuidString
        try JSONSerialization.data(withJSONObject: wrong).write(to: f.grant)
        let r = try ПрограммаПриёмаROOT(f.контекст())
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("merge") == 0)
    }
    @Test func реальнаяЦепочкаСМетасимволамиИДубликат() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        let result = try f.завершить(r)
        #expect(result.стадия == "delivered")
        #expect(try f.git(["show", "HEAD:путь с пробелом;$(echo nope).txt"]) == "incoming")
        #expect(try f.git(["show", "HEAD:own.txt"]) == "own branch")
        #expect(try f.git(["rev-list", "--parents", "-n", "1", "HEAD"]) == result.commit! + " " + f.L + " " + f.M)
        #expect(c.окружение["PATH"] == ProcessInfo.processInfo.environment["PATH"])
        r.закрыть(); let reopened = try ПрограммаПриёмаROOT(c)
        #expect(try reopened.выполнить().повтор)
        #expect(try f.число("push") == 1)
    }
    @Test func чужиеCustodyRefИЗанятыйИндексУдерживаются() throws {
        let f = try ФикстураПриёмаROOT()
        #expect(отказПриёма { _ = try f.контекст(actor: UUID().uuidString) })
        let c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        _ = try r.выполнить()
        try Data("local".utf8).write(to: f.W.appendingPathComponent("local.txt")); _ = try f.git(["add", "--", "local.txt"])
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("merge") == 0)
        r.закрыть()
        var p = try JSONSerialization.jsonObject(with: Data(contentsOf: f.grant)) as! [String: Any]
        p["W"] = f.dir.appendingPathComponent("foreign").path
        try JSONSerialization.data(withJSONObject: p).write(to: f.grant)
        #expect(отказПриёма { _ = try f.контекст() })
        let f2 = try ФикстураПриёмаROOT(), r2 = try ПрограммаПриёмаROOT(f2.контекст())
        let hook = f2.W.appendingPathComponent(".git/hooks/pre-commit")
        try Data("#!/bin/sh\nexit 42\n".utf8).write(to: hook)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: hook.path)
        #expect(отказПриёма { _ = try r2.выполнить() })
        try FileManager.default.removeItem(at: hook)
        _ = try f2.git(["config", "merge.external.driver", "/usr/bin/false"])
        #expect(отказПриёма { _ = try r2.выполнить() })
        _ = try f2.git(["config", "--unset", "merge.external.driver"])
        _ = try r2.выполнить(); _ = try f2.git(["checkout", "-b", "codex/foreign-fixture"])
        #expect(отказПриёма { _ = try r2.выполнить() })
        #expect(try f2.число("merge") == 0)
    }
    @Test func неправильныеДеревоИПорядокРодителейОтклоняются() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        let done = try f.завершить(r); r.закрыть()
        let raw = try ФикстураПриёмаROOT.команда("/usr/bin/git", ["-C", f.W.path, "cat-file", "commit", done.commit!], cwd: f.dir, logs: f.dir.appendingPathComponent("negative"))
        for (parents, tree) in [([f.M,f.L],f.tree),([f.L,f.M],String(repeating:"0",count:40))] {
            let file = f.dir.appendingPathComponent(UUID().uuidString + ".expected.json")
            try JSONSerialization.data(withJSONObject: ["schema":"fum.raw-merge-commit-expectation.1","expectedParents":parents,"expectedTree":tree]).write(to:file)
            let bad = try ФикстураПриёмаROOT.команда(f.среда.metadataCLI,["--проверить-сырой-merge-коммит",f.среда.metadataState,file.path],cwd:f.W,logs:f.dir.appendingPathComponent("negative"),env:c.окружение,input:raw.1)
            #expect(bad.0 != 0)
        }
    }
    @Test func известныйCommitПриRawFAILНеПубликуется() throws {
        let f = try ФикстураПриёмаROOT(), r = try ПрограммаПриёмаROOT(f.контекст())
        for _ in 0..<3 { _ = try r.выполнить() }
        let C = try f.git(["rev-parse","HEAD"]); #expect(C != f.L)
        r.failpoint = .raw
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("push") == 0)
        #expect(try r.выполнить().стадия == "held")
    }
    @Test func неизвестныйCommitВосстанавливаетсяЧтением() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        _ = try r.выполнить(); _ = try r.выполнить(); r.failpoint = .ответCommit
        #expect(отказПриёма { _ = try r.выполнить() }); r.закрыть()
        let reopened = try ПрограммаПриёмаROOT(c), result = try reopened.выполнить()
        #expect(result.повтор && result.стадия == "raw")
        #expect(try f.число("commit") == 1)
        let C = result.commit!
        let raw = try ФикстураПриёмаROOT.команда("/usr/bin/git", ["-C",f.W.path,"cat-file","commit",C],cwd:f.dir,logs:f.dir.appendingPathComponent("alternate"))
        // Тот же message/tree/parents/identity, другой raw OID из-за добавленного header.
        let text = String(decoding: raw.1, as: UTF8.self)
        let changed = Data(text.replacingCharacters(in: text.range(of: "\n\n")!, with: "\nencoding UTF-8\n\n").utf8)
        let alternate = try ФикстураПриёмаROOT.команда("/usr/bin/git",["-C",f.W.path,"hash-object","-w","-t","commit","--stdin"],cwd:f.dir,logs:f.dir.appendingPathComponent("alternate"),input:changed)
        let D = String(decoding:alternate.1,as:UTF8.self).trimmingCharacters(in:.newlines)
        _ = try f.git(["update-ref",f.ref,D,C])
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("push") == 0)
        _ = try f.git(["update-ref",f.ref,C,D])
        // Отказ exact C известен, но его raw-stage outcome уже held: не переигрываем этап.
        #expect(try reopened.выполнить().стадия == "held")
        #expect(try f.число("merge") == 1)
    }
    @Test func неизвестныйPushНеПовторяетсяПослеReadback() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        for _ in 0..<4 { _ = try r.выполнить() }; r.failpoint = .ответPush
        #expect(отказПриёма { _ = try r.выполнить() }); r.закрыть()
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(try reopened.выполнить().повтор)
        #expect(try f.число("push") == 1)
        #expect(try f.завершить(reopened).стадия == "delivered")
        #expect(try f.число("push") == 1)
    }
    @Test func потерянныйMERGE_HEADДаётИзвестныйОтказДоКоммита() throws {
        let фикстура = try ФикстураПриёмаROOT(), контекст = try фикстура.контекст()
        let программа = try ПрограммаПриёмаROOT(контекст), удалён = ФлагПриёма()
        defer { программа.закрыть() }
        let путь = try фикстура.git(["rev-parse", "--path-format=absolute", "--git-path", "MERGE_HEAD"])
        _ = try программа.выполнить(); _ = try программа.выполнить()
        программа.послеMerge = {
            do {
                try FileManager.default.removeItem(atPath: путь)
                удалён.значение = true
            } catch { удалён.значение = false }
        }
        var известныйОтказ = false
        do { _ = try программа.выполнить() }
        catch ОшибкаПриёмаROOT.отказ(_) { известныйОтказ = true }
        catch { известныйОтказ = false }
        #expect(удалён.значение)
        #expect(известныйОтказ)
        #expect(try фикстура.git(["rev-parse", "HEAD"]) == фикстура.L)
        #expect(try фикстура.число("merge") == 1)
        #expect(try фикстура.число("commit") == 0)
        #expect(try фикстура.число("push") == 0)
        программа.закрыть()
        let восстановленная = try ПрограммаПриёмаROOT(контекст)
        defer { восстановленная.закрыть() }
        #expect(try восстановленная.выполнить().стадия == "held")
        #expect(try фикстура.число("merge") == 1)
        #expect(try фикстура.число("commit") == 0)
        #expect(try фикстура.число("push") == 0)
    }
    @Test func короткаяНастройкаOIDНеМеняетЧтениеИНамерение() throws {
        let фикстура = try ФикстураПриёмаROOT()
        _ = try фикстура.git(["config", "core.abbrev", "7"]) // Только новая private fixture.
        let программа = try ПрограммаПриёмаROOT(фикстура.контекст())
        defer { программа.закрыть() }
        let итог = try фикстура.завершить(программа)
        #expect(итог.стадия == "delivered")
        #expect(try фикстура.число("merge") == 1)
        #expect(try фикстура.число("commit") == 1)
        #expect(try фикстура.число("push") == 1)
        let чтение = FileManager.default.enumerator(at: фикстура.среда.logs, includingPropertiesForKeys: nil)!
        var сырыеЧтения: [ПроцессПриёмаROOT] = []
        while let файл = чтение.nextObject() as? URL {
            if файл.lastPathComponent == "process.json" {
                let процесс = try JSONDecoder().decode(ПроцессПриёмаROOT.self, from: Data(contentsOf: файл))
                if процесс.executable == "/usr/bin/git" && процесс.argv.contains("--raw") {
                    сырыеЧтения.append(процесс)
                }
            }
        }
        #expect(сырыеЧтения.count >= 2)
        #expect(сырыеЧтения.allSatisfy { $0.argv.contains("--no-abbrev") && $0.exit == 0 })
    }

    @Test func STOPОтзывИНеПодтверждённыйIntent() throws {
        let f = try ФикстураПриёмаROOT(), stop = ФлагПриёма(), revoke = ФлагПриёма()
        stop.значение = true
        let c = try f.контекст(stop: { stop.значение }, revoked: { revoke.значение }), r = try ПрограммаПриёмаROOT(c)
        #expect(try r.выполнить().стадия == "held")
        stop.значение = false; revoke.значение = true
        #expect(try r.выполнить().стадия == "held")
        revoke.значение = false; r.failpoint = .intent
        #expect(отказПриёма { _ = try r.выполнить() })
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("merge") == 0)
        #expect(try f.число("push") == 0)
        let f2 = try ФикстураПриёмаROOT(), stopped = ФлагПриёма()
        let r2 = try ПрограммаПриёмаROOT(f2.контекст(stop: { stopped.значение }))
        _ = try r2.выполнить(); _ = try r2.выполнить()
        r2.послеMerge = { stopped.значение = true }
        #expect(отказПриёма { _ = try r2.выполнить() })
        #expect(try f2.число("merge") == 1)
        #expect(try f2.число("commit") == 0)
        #expect(try f2.число("push") == 0)
    }
}


// Только узкие seams; ни ФикстураПриёмаROOT, ни фиктивный ответ FUMA не используются.
private final class ФайловаяМодельДопуска {
    struct Узел {
        var байты: Data
        let каталог: Bool
        var номер: UInt64
        let режим: UInt32
    }
    var узлы: [String: Узел] = [:]
    var чтения: [String] = [], статы: [String] = [], команды: [[String]] = []
    var окруженияКоманд: [[String: String]] = []
    var каталогиКоманд: [String] = []
    init() {
        for имя in ["репозиторий", "Git-admin", "Git-common", "DATA"] {
            добавить(ПроверкиУправляемогоДопуска.путь(имя), каталог: true)
        }
    }
    var записи: [String] = [], запуски = 0, следующийУзел: UInt64 = 10
    var послеСтата: ((ПинУправляемогоВхода) -> Void)?
    var послеЗаписи: ((String) -> Void)?
    var послеКаталога: ((String) -> Void)?
    var ответыГит: ([String]) throws -> Data = { _ in throw ОтказУправляемогоДопуска.неизвестно("ответ-гит-не-задан") }
    func добавить(_ путь: String, байты: Data = Data(), каталог: Bool = false, режим: UInt32? = nil) {
        следующийУзел += 1; узлы[путь] = Узел(байты: байты, каталог: каталог, номер: следующийУзел, режим: режим ?? (каталог ? 0o700 : 0o600))
    }
    func пин(_ роль: РольВходаУправления, _ путь: String, лист: String? = nil) -> ПинУправляемогоВхода {
        let узел = узлы[путь]!
        return ПинУправляемогоВхода(роль: роль, путь: путь, устройство: 1, узел: узел.номер, владелец: getuid(), режимДоступа: узел.режим,
            байтов: узел.каталог ? 0 : узел.байты.count, хэш: ГенераторМетаданныхКоммита.sha256Hex(узел.байты), каталог: узел.каталог, новыйЛист: лист)
    }
    func швы() -> ШвыУправляемогоВызова {
        var швы = ШвыУправляемогоВызова()
        швы.стат = { [self] ожидаемый in
            статы.append(ожидаемый.путь)
            guard URL(fileURLWithPath: ожидаемый.путь).standardizedFileURL.path == ожидаемый.путь || ожидаемый.путь == "stdin",
                  let узел = узлы[ожидаемый.путь], ожидаемый.новыйЛист.map({ узлы[ожидаемый.путь + "/" + $0] == nil }) ?? true else { throw ОтказУправляемогоДопуска.отказ("модель-отсутствует-или-лист-занят") }
            let факт = ПинУправляемогоВхода(роль: ожидаемый.роль, путь: ожидаемый.путь, устройство: 1, узел: узел.номер,
                владелец: getuid(), режимДоступа: узел.режим, байтов: узел.каталог ? ожидаемый.байтов : узел.байты.count,
                хэш: ожидаемый.хэш, каталог: узел.каталог, новыйЛист: ожидаемый.новыйЛист)
            послеСтата?(ожидаемый); return факт
        }
        швы.читать = { [self] пин, предел in
            чтения.append(пин.путь)
            guard let узел = узлы[пин.путь], узел.номер == пин.узел, узел.байты.count <= предел else { throw ОтказУправляемогоДопуска.отказ("модель-чтения") }
            return узел.байты
        }
        швы.создатьКаталог = { [self] путь in
            guard узлы[путь] == nil else { throw ОтказУправляемогоДопуска.отказ("модель-существует") }
            добавить(путь, каталог: true); записи.append(путь); послеКаталога?(путь)
        }
        швы.создатьФайл = { [self] путь in
            guard узлы[путь] == nil else { throw ОтказУправляемогоДопуска.отказ("модель-существует") }
            добавить(путь); записи.append(путь); послеЗаписи?(путь)
        }
        швы.записать = { [self] байты, путь in
            guard узлы[путь] == nil else { throw ОтказУправляемогоДопуска.отказ("модель-существует") }
            добавить(путь, байты: байты); записи.append(путь); послеЗаписи?(путь)
        }
        швы.внутриГит = { [self] аргументы, окружение in команды.append(аргументы); окруженияКоманд.append(окружение); каталогиКоманд.append(try ПолитикаБезэффектногоЧтенияГит.рабочийКаталогКоманды(аргументы)); return false }
        швы.гит = { [self] аргументы, окружение in
            команды.append(аргументы); окруженияКоманд.append(окружение); каталогиКоманд.append(try ПолитикаБезэффектногоЧтенияГит.рабочийКаталогКоманды(аргументы))
            if аргументы == ПолитикаБезэффектногоЧтенияГит.флаги + ПроверкиУправляемогоДопуска.адресГит() + ["--version"] { return "git version synthetic" }
            throw ОтказУправляемогоДопуска.стопПередЗапуском
        }
        швы.байтыГит = { [self] аргументы, окружение, предел in
            команды.append(аргументы); окруженияКоманд.append(окружение); каталогиКоманд.append(try ПолитикаБезэффектногоЧтенияГит.рабочийКаталогКоманды(аргументы)); let байты = try ответыГит(аргументы)
            guard байты.count <= предел else { throw ОтказУправляемогоДопуска.отказ("модель-предела-гит") }; return байты
        }
        швы.запуститьФУМА = { [self] _, _, _ in запуски += 1; throw ОтказУправляемогоДопуска.стопПередЗапуском }
        return швы
    }
}

// Адресный исторический input, выбранный parent. Actual paths приходят только из
// SHA-bound private DATA через exact env role; их литералов в Swift нет.
private struct ФайлИсторическогоВхода: Decodable {
    let путь: String
    let байтов: Int
    let хэш: String
    enum CodingKeys: String, CodingKey { case путь = "path", байтов = "bytes", хэш = "sha256" }
    func прочитать() throws -> Data {
        var сведения = stat()
        guard lstat(путь, &сведения) == 0, (сведения.st_mode & S_IFMT) == S_IFREG,
              сведения.st_nlink == 1, сведения.st_uid == getuid(), Int(сведения.st_size) == байтов,
              байтов >= 0, байтов <= 1_048_576 else { throw ОтказУправляемогоДопуска.отказ("пин-исторического-входа") }
        let пин = ПинУправляемогоВхода(роль: .источник, путь: путь, устройство: UInt64(сведения.st_dev), узел: UInt64(сведения.st_ino),
            владелец: UInt32(сведения.st_uid), режимДоступа: UInt32(сведения.st_mode & 0o777), байтов: байтов, хэш: хэш, каталог: false, новыйЛист: nil)
        let швы = ШвыУправляемогоВызова()
        guard try швы.стат(пин) == пин else { throw ОтказУправляемогоДопуска.отказ("дрейф-исторического-пина") }
        let байты = try швы.читать(пин, байтов)
        guard байты.count == байтов, ГенераторМетаданныхКоммита.sha256Hex(байты) == хэш,
              try швы.стат(пин) == пин else { throw ОтказУправляемогоДопуска.отказ("байты-исторического-входа") }
        return байты
    }
}
private struct ИсторическийНативныйВход: Decodable {
    let схема: String
    let каноническийПуть: String
    let режим: String
    let коммит: String
    let блоб: String
    let полный: ФайлИсторическогоВхода
    let скомпилированный: ФайлИсторическогоВхода
    let манифестКомпилятора: ФайлИсторическогоВхода
    let квитанцияВыполнения: ФайлИсторическогоВхода
    enum CodingKeys: String, CodingKey {
        case схема = "schema", каноническийПуть = "canonicalPath", режим = "canonicalMode", коммит = "sourceCommit", блоб = "gitBlob"
        case полный = "full", скомпилированный = "compiled", манифестКомпилятора = "compilerManifest", квитанцияВыполнения = "selectedRuntimeCustody"
    }
    static func прочитать() throws -> (вход: Self, полный: Data, скомпилированный: Data) {
        guard let путь = ProcessInfo.processInfo.environment["MANAGED_NATIVE_FIXTURE_INPUT"] else { throw ОтказУправляемогоДопуска.неизвестно("нет-адресного-нативного-входа") }
        let закрепление = ФайлИсторическогоВхода(путь: путь, байтов: 2440, хэш: "ad052093e568f96e4119df47b3c20c2f7e87cc0499c5d92f51c703ba199c1c3c")
        let вход = try JSONDecoder().decode(Self.self, from: закрепление.прочитать())
        guard вход.схема == "fum.tools.managed-admission.native-exact-range-input.1",
              вход.каноническийПуть == "iskhodniki/perekhod-vetok/proverki/proverki-stop.swift", вход.режим == "100644",
              вход.коммит == "2d079e22238137dd0ae922921ec3c77023a54564", вход.блоб == "94deb79473ca244621b58159e3a3a667505ace86" else { throw ОтказУправляемогоДопуска.отказ("происхождение-нативного-входа") }
        let полный = try вход.полный.прочитать(), скомпилированный = try вход.скомпилированный.прочитать()
        _ = try вход.манифестКомпилятора.прочитать(); _ = try вход.квитанцияВыполнения.прочитать()
        var объект = Data("blob \(полный.count)\0".utf8); объект.append(полный)
        let блоб = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
        guard полный.count == 335614, ГенераторМетаданныхКоммита.sha256Hex(полный) == "490d03e31508a5354dc5163a749e24c5b454e00232f034fa0f400603da3a02ea",
              скомпилированный.count == 239178, ГенераторМетаданныхКоммита.sha256Hex(скомпилированный) == "a963c44811f7f3f4eb4552870fb46a59f37026e1db6d574b9d1ffd703b6a0f3d",
              полный.dropFirst(96436) == скомпилированный, блоб == вход.блоб,
              ГенераторМетаданныхКоммита.sha256Hex(полный.prefix(96436)) == "db86116ab740f23fabc2a9ebc33cf51e3c7595b6b0f3ce3a337bb815e59c83d6" else { throw ОтказУправляемогоДопуска.отказ("реальный-исторический-диапазон") }
        return (вход, полный, скомпилированный)
    }
}

@Suite("Частный допуск: ревизия 0006", .serialized)
struct ПроверкиУправляемогоДопуска {
    static let область = "01a192d0-6f09-7950-9251-b27101106bfc"
    static let корень = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    static let писатель = "01a17797-519b-73c1-bcc8-fd295cdfe9b0"
    static let нулевойХэш = String(repeating: "0", count: 64)
    static func хэш(_ байты: Data) -> String { ГенераторМетаданныхКоммита.sha256Hex(байты) }
    static func кодировать<T: Encodable>(_ значение: T) throws -> Data {
        let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]; return try кодировщик.encode(значение)
    }
    static func путь(_ имя: String) -> String {
        КонтекстУправляемогоДопуска.наблюдатьВременнуюОснову(область: область).физическийКорень + "/" + область + "/" + имя
    }
    static func ошибка(_ действие: () throws -> Void) -> ОтказУправляемогоДопуска? {
        do { try действие(); return nil } catch let отказ as ОтказУправляемогоДопуска { return отказ }
        catch { return .неизвестно("иной-тип-ошибки") }
    }
    static func изменить(_ запрос: ЗапросДопускаУправляемогоВызова, _ правка: (inout [String: Any]) -> Void) throws -> ЗапросДопускаУправляемогоВызова {
        var словарь = try JSONSerialization.jsonObject(with: запрос.каноническиеБайты()) as! [String: Any]
        правка(&словарь); return try JSONDecoder().decode(ЗапросДопускаУправляемогоВызова.self, from: JSONSerialization.data(withJSONObject: словарь))
    }
    static func решение(_ запрос: ЗапросДопускаУправляемогоВызова, статус: РешениеХостаУправляемогоВызова.Статус = .разрешено,
                        хэш: String? = nil, диапазоны: [ДиапазонИсполненногоИсходника] = []) throws -> РешениеХостаУправляемогоВызова {
        // Синтетическое non-Decodable test-only свидетельство; это не реальный semantic proof установленного Git.
        let инструмент = запрос.пины.first(where: { $0.роль == .исполнительГит })!
        var допуск = НезависимыйДопускЧтенияГит(инструмент: инструмент, версия: запрос.версияГит, уровень: .независимоПровереннаяСемантика,
            хэшПарсерногоДоказательства: String(repeating: "1", count: 64), хэшСемантическогоДоказательства: String(repeating: "2", count: 64))
        допуск.физическийКонтекст = try физическийДопуск(запрос)
        return РешениеХостаУправляемогоВызова(статус: статус, хэшЗапроса: try хэш ?? запрос.каноническийХэш(), операция: запрос.операция,
            писатель: запрос.писатель, область: запрос.область, разрешённыеДиапазоны: диапазоны, допускЧтенияГит: допуск)
    }

    // Synthetic independent test issuer uses fixed model identities, not a production provider.
    static func физическийДопуск(_ запрос: ЗапросДопускаУправляемогоВызова, случай: Int = -1) throws -> ФизическийКонтекстГит {
        func пин(_ имя: String, _ узел: UInt64) -> ПинУправляемогоВхода {
            ПинУправляемогоВхода(роль: .источник, путь: путь(имя), устройство: 1, узел: узел, владелец: getuid(),
                режимДоступа: 0o700, байтов: 0, хэш: хэш(Data()), каталог: true, новыйЛист: nil)
        }
        let корень = пин(случай == 5 ? "DATA" : "репозиторий", случай == 5 ? 14 : 11)
        let объект = Data("blob 2\0{}".utf8)
        let блоб = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
        let кортеж = КортежФизическогоГит(коммит: String(repeating: случай == 11 ? "c" : "a", count: 40), дерево: String(repeating: случай == 12 ? "c" : "b", count: 40),
            блоб: случай == 13 ? String(repeating: "c", count: 40) : блоб, путь: случай == 10 ? "foreign.swift" : "koordinaciya/координатор.swift")
        let вне = запрос.пины.filter { [.кореньЗапуска, .квитанция, .публичнаяПроекция].contains($0.роль) }.map {
            ПинУправляемогоВхода(роль: $0.роль, путь: $0.путь, устройство: $0.устройство, узел: $0.узел, владелец: $0.владелец,
                режимДоступа: $0.режимДоступа, байтов: $0.байтов, хэш: $0.хэш, каталог: $0.каталог, новыйЛист: nil)
        }
        let хэшЗапроса = try запрос.каноническийХэш()
        return .проверочный(издатель: случай == 1 ? "DATA-claim" : "synthetic-physical-Git-test-issuer-v1",
            писатель: случай == 2 ? корень.путь : запрос.писатель, область: случай == 3 ? "foreign" : запрос.область,
            хэшЗапроса: случай == 4 ? нулевойХэш : хэшЗапроса, корень: корень,
            рабочееДерево: случай == 8 ? пин("репозиторий", 99) : корень,
            админ: пин("Git-admin", случай == 6 ? 99 : 12), общийАдмин: пин("Git-common", случай == 7 ? 99 : 13),
            кортежи: [кортеж], внеРепозитория: вне)
    }
    static func адресГит() -> [String] { ["--git-dir=" + путь("Git-admin"), "--work-tree=" + путь("репозиторий")] }

    private static func подготовить(_ модель: ФайловаяМодельДопуска, номер: Int = 4) throws -> ЗапросДопускаУправляемогоВызова {
        let основа = КонтекстУправляемогоДопуска.наблюдатьВременнуюОснову(область: область)
        модель.добавить(основа.физическийКорень, каталог: true)
        let данные = Data("{}".utf8), пакет = try кодировать(ПакетВходаГенератораFUMA(cases: []))
        var пины: [ПинУправляемогоВхода] = [модель.пин(.временныйКорень, основа.физическийКорень)]
        let роли: [РольВходаУправления] = [.проверяющий, .исполнительГит, .определение, .оператор, .фикстура, .запрос, .метаданные, .состояние, .источник, .ожидание, .текущее, .стандартныйВвод]
        var значения: [РольВходаУправления: String] = [:]
        for роль in роли {
            let адрес = роль == .исполнительГит ? "/usr/bin/git" : (роль == .стандартныйВвод ? "stdin" : путь(роль.rawValue))
            модель.добавить(адрес, байты: роль == .фикстура ? пакет : данные, режим: [.оператор, .исполнительГит, .проверяющий].contains(роль) ? 0o700 : 0o600)
            пины.append(модель.пин(роль, адрес)); значения[роль] = адрес
        }
        for роль in [РольВходаУправления.кореньЗапуска, .квитанция, .публичнаяПроекция] {
            let адрес = путь(роль.rawValue), лист = роль == .кореньЗапуска ? "запуск" : "данные.json"
            модель.добавить(адрес, каталог: true); пины.append(модель.пин(роль, адрес, лист: лист))
            значения[роль] = роль == .кореньЗапуска ? адрес : адрес + "/" + лист
        }
        модель.добавить(путь("полный-исходник"), байты: данные); модель.добавить(путь("скомпилированный"), байты: данные)
        let идентичность = ИдентичностьИсходникаДопуска(байтов: данные.count, хэш: хэш(данные))
        let манифест = МанифестЧленаПоставки(схема: "fum.source-supply-member.1", каноническийПуть: "koordinaciya/координатор.swift", режим: "100644", идентичность: идентичность)
        модель.добавить(путь("манифест"), байты: try кодировать(манифест))
        let строка = ПокрытиеИсполненногоИсходника(путь: манифест.каноническийПуть, роль: .полный, режим: манифест.режим,
            исполненный: идентичность, требуемый: идентичность, скомпилированный: модель.пин(.источник, путь("скомпилированный")), дерево: nil,
            поставка: ЧленПоставкиИсходников(манифест: модель.пин(.источник, путь("манифест")), файл: модель.пин(.источник, путь("полный-исходник"))), диапазон: nil)
        let описание = СпецификацияУправляемойОперации.все[номер]
        let основаЗапроса = ЗапросДопускаУправляемогоВызова(схема: "fum.управляемый-допуск.3", профиль: описание.профиль, операция: описание.операция,
            корневойUUID: корень, писатель: писатель, область: область, попытка: "revision-0003", аргументы: [], версияГит: "git version synthetic", кодПолитикиГит: ПолитикаБезэффектногоЧтенияГит.код,
            хэшПроверяющего: хэш(данные), пины: пины, хэшВхода: хэш(пакет), хэшПубличногоТела: nil, политикаТела: "canonical-typed-test",
            временнаяОснова: основа, покрытие: [строка], пределБайт: 1_048_576, окружение: ПолитикаБезэффектногоЧтенияГит.обязательноеОкружение.merging(["GIT_COMMON_DIR": Self.путь("Git-common")]) { _, новое in новое })
        return try основаЗапроса.сОперацией(описание, значения: значения, корневойUUID: корень)
    }
    private static func запуск(_ запрос: ЗапросДопускаУправляемогоВызова?, _ решение: РешениеХостаУправляемогоВызова?, _ модель: ФайловаяМодельДопуска,
                       контекст: КонтекстУправляемогоДопуска? = nil) throws {
        _ = try ИсполнительГенератораFUMA.выполнить(input: ПакетВходаГенератораFUMA(cases: []), definitionPath: путь("определение"),
            operatorPath: путь("оператор"), privateRunRoot: путь("кореньЗапуска"), запросДопуска: запрос, решениеХоста: решение,
            швы: модель.швы(), подготовленныйКонтекст: контекст)
    }
    @Test(arguments: 0..<8) func источникХостаНеБерётMПолномочиеИОбластьИзКандидата(_ случай: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель, номер: случай == 6 ? 4 : 0)
        let решение = try Self.решение(запрос)
        let контекст = try КонтекстУправляемогоДопуска(запрос, решение, запрос.операция, модель.швы())
        let основа = String(repeating: "a", count: 40), основание = String(repeating: "b", count: 64)
        let пути = ["koordinaciya/fixture.swift"]
        let хост = УправляемыйИсточникСохраняющегоПриёмаROOT(принятоеM: основа, основаниеSHA256: основание,
            пути: пути, ожидаемыйУдалённыйOID: "ABSENT", контекст: контекст)
        let поручение = ПоручениеПриёмаROOT(схема: случай == 7 ? "fum.root-acceptance-program.1" : "fum.root-acceptance-program.2",
            идентификатор: "synthetic-source-host", ROOT: запрос.корневойUUID, писатель: запрос.писатель,
            W: Self.путь("репозиторий"), ref: "refs/heads/fixture", origin: "https://github.com/fum-lab/fum.git",
            L: String(repeating: "1", count: 40), M: String(repeating: "2", count: 40),
            дерево: String(repeating: "3", count: 40), пути: случай == 2 ? ["foreign.swift"] : пути, pins: [],
            принятоеM: случай == 1 ? String(repeating: "c", count: 40) : основа,
            основаниеИсходниковSHA256: случай == 3 ? String(repeating: "d", count: 64) : основание,
            разрешённыйЭффект: случай == 4 ? "full-profile" : "сохранение-исходников-слиянием",
            ожидаемыйУдалённыйOID: случай == 5 ? основа : "ABSENT")
        let среда = СредаПриёмаROOT(metadataCLI: "", metadataState: запрос.аргументы[1],
            программа: "", переменные: [:], segment: URL(fileURLWithPath: "/fixture/segment"),
            logs: URL(fileURLWithPath: "/fixture/logs"))
        #expect(отказПриёма { try хост.проверить(поручение, среда: среда) } == (случай != 0))
        #expect(модель.запуски == 0 && модель.записи.isEmpty)
    }

    @Test(arguments: СпецификацияУправляемойОперации.все.indices) func МатрицаОперацийБезДопуска(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель, номер: номер)
        #expect(Self.ошибка { _ = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(запрос.аргументы, швы: модель.швы()) } == .неизвестно("нет-независимого-решения"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: СпецификацияУправляемойОперации.все.indices) func МатрицаФормИРолей(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель, номер: номер)
        let контекст = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
        try контекст.проверитьРолиВетви(запрос.аргументы)
        #expect(СпецификацияУправляемойОперации.выбрать(запрос.аргументы)?.имя == СпецификацияУправляемойОперации.все[номер].имя)
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: [1, 2, 7]) func ТочныеРегрессииФормы(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель, номер: номер)
        let ожидаемые: [String]
        switch номер {
        case 1: ожидаемые = ["--проверить-перед-коммитом", Self.путь("запрос"), Self.путь("метаданные"), "--исходники-UNKNOWN"]
        case 2: ожидаемые = ["--проверить-сырой-коммит-исходников", Self.путь("запрос"), Self.путь("метаданные")]
        default: ожидаемые = ["--проверить-перед-коммитом", Self.путь("состояние")]
        }
        #expect(запрос.аргументы == ожидаемые)
    }
    @Test(arguments: 0..<4) func НезависимоеРешениеХоста(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let декодированный = try JSONDecoder().decode(ЗапросДопускаУправляемогоВызова.self, from: запрос.каноническиеБайты())
        let допуск = try номер == 0 || номер == 2 ? nil : Self.решение(запрос, статус: номер == 1 ? .неизвестно : .разрешено, хэш: номер == 3 ? Self.нулевойХэш : nil)
        #expect(Self.ошибка { try Self.запуск(номер == 2 ? декодированный : запрос, допуск, модель) } != nil)
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<8) func СвязиПрофиляРолейПинов(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let запрос = try Self.изменить(исходный) { словарь in
            if номер == 0 { словарь["профиль"] = "исходники" }
            if номер == 1 { словарь["операция"] = "сыройКоммит" }
            if номер == 2 { словарь["область"] = "invalid" }
            if номер == 3 { словарь["попытка"] = "../escape" }
            var пины = словарь["пины"] as! [[String: Any]]
            let индекс = пины.firstIndex { ($0["роль"] as? String) == "определение" }!
            if номер == 4 { пины.remove(at: индекс) }
            if номер == 5 { пины[индекс]["путь"] = Self.путь("alias/../определение") }
            if номер == 6 { пины[индекс]["узел"] = 9999 }
            if номер == 7 { пины.append(пины[индекс]) }
            словарь["пины"] = пины
        }
        #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } != nil)
        #expect(модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<4) func ПрямойИсполнительДоГит(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let допуск = try номер == 0 ? nil : Self.решение(запрос, статус: номер == 1 ? .неизвестно : (номер == 2 ? .запрещено : .разрешено), хэш: номер == 3 ? Self.нулевойХэш : nil)
        #expect(Self.ошибка { try Self.запуск(запрос, допуск, модель) } != nil)
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test func ДрейфБайтовПослеДопуска() throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        модель.узлы[Self.путь("определение")]!.байты = Data("[]".utf8)
        #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .отказ("дрейф-входных-байтов"))
        #expect(модель.чтения.contains(Self.путь("определение")) && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<5) func ВременнаяОсноваПроцесса(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let запрос = try Self.изменить(исходный) { словарь in
            var основа = словарь["временнаяОснова"] as! [String: Any]
            if номер == 0 { основа["источник"] = "TMPDIR" }
            if номер == 1 { основа["наблюдавшийПроцесс"] = Int(getpid()) + 1 }
            if номер == 2 { основа["владелец"] = Int(getuid()) + 1 }
            if номер == 3 { основа["область"] = Self.корень }
            if номер == 4 { основа["физическийКорень"] = "/tmp" }
            словарь["временнаяОснова"] = основа
        }
        #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .неизвестно("временная-основа-процесса"))
        #expect(модель.чтения.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<2) func ПоздняяПодменаУзла(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        if номер == 0 { модель.послеКаталога = { _ in модель.узлы[Self.путь("оператор")]!.номер += 1 } }
        else { модель.узлы[Self.путь("оператор")]!.номер += 1 }
        #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .отказ("дрейф-пина"))
        #expect(модель.запуски == 0)
        if номер == 0 { #expect(!модель.записи.isEmpty && !модель.команды.isEmpty) }
        else { #expect(модель.записи.isEmpty && модель.команды.isEmpty) }
    }
    @Test(arguments: 0..<5) func ОбщаяПоследовательностьКвитанцииИИсполнителя(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель, номер: 5)
        let запрос = try номер == 1 ? Self.изменить(исходный) { $0["хэшВхода"] = Self.нулевойХэш } : исходный
        let путьКвитанции = Self.путь("квитанция/данные.json")
        if номер == 2 { модель.добавить(путьКвитанции, байты: Data("preexisting".utf8)) }
        var номерКвитанции: UInt64?
        модель.послеЗаписи = { путь in
            if путь == путьКвитанции {
                номерКвитанции = модель.узлы[путь]!.номер
                if номер == 4 { модель.узлы[Self.путь("полный-исходник")]!.байты = Data("[]".utf8) }
            }
        }
        if номер == 3 { модель.послеСтата = { пин in
            if пин.путь == путьКвитанции && пин.устройство == 0 { модель.узлы[пин.путь]!.номер += 1 }
        } }
        let отказ = Self.ошибка {
            let контекст = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
            _ = try ПодготовленнаяПоследовательностьКлиента.выполнить(контекст: контекст, пакет: ПакетВходаГенератораFUMA(cases: []),
                квитанция: Data("{\"synthetic\":true}".utf8), путьКвитанции: путьКвитанции,
                определение: Self.путь("определение"), оператор: Self.путь("оператор"), кореньЗапуска: Self.путь("кореньЗапуска"))
        }
        if номер == 0 {
            #expect(отказ == .стопПередЗапуском && модель.запуски == 1)
            #expect(модель.записи.first == путьКвитанции && модель.узлы[путьКвитанции]?.номер == номерКвитанции)
            #expect(модель.статы.filter { $0 == путьКвитанции }.count >= 2)
        } else {
            #expect(отказ != nil && модель.запуски == 0)
            if номер == 1 || номер == 2 { #expect(модель.записи.isEmpty) }
            if номер == 4 { #expect(модель.записи == [путьКвитанции]) }
        }
    }
    @Test(arguments: 0..<2) func СвязьПодготовленногоКонтекста(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let контекст = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
        let иной = try Self.изменить(запрос) { $0["попытка"] = "another" }
        let отказ = Self.ошибка { try Self.запуск(номер == 0 ? иной : запрос, Self.решение(иной), модель, контекст: контекст) }
        #expect(отказ == .отказ(номер == 0 ? "подмена-подготовленного-контекста" : "связь-запроса")); #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<3) func ПределыРолейИнструмента(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(); var запрос = try Self.подготовить(модель)
        if номер == 0 {
            модель.узлы[Self.путь("оператор")]!.байты = Data(repeating: 65, count: 2_262_400)
            let пин = модель.пин(.оператор, Self.путь("оператор"))
            запрос = try Self.изменить(запрос) { словарь in
                var пины = словарь["пины"] as! [[String: Any]]; let номер = пины.firstIndex { ($0["роль"] as? String) == "оператор" }!
                пины[номер] = try! JSONSerialization.jsonObject(with: Self.кодировать(пин)) as! [String: Any]; словарь["пины"] = пины
            }
            #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .стопПередЗапуском)
            #expect(модель.запуски == 1)
        } else {
            запрос = try Self.изменить(запрос) { словарь in
                var пины = словарь["пины"] as! [[String: Any]], пин = пины[номер]
                пин["байтов"] = номер == 1 ? 512 * 1_048_576 + 1 : 1_048_577
                if номер == 1 { пин["роль"] = "оператор"; пины.removeAll { ($0["роль"] as? String) == "оператор" } }
                else { пин["роль"] = "фикстура"; пины.removeAll { ($0["роль"] as? String) == "фикстура" } }
                пины.append(пин); словарь["пины"] = пины
            }
            #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .отказ("пин-роли"))
            #expect(модель.чтения.isEmpty && модель.записи.isEmpty && модель.запуски == 0)
        }
    }
    @Test(arguments: 0..<10) func РеальнаяПоставкаИДрейф(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        var запрос = исходный
        if номер < 6 {
            запрос = try Self.изменить(исходный) { словарь in
                var строки = словарь["покрытие"] as! [[String: Any]], строка = строки[0]
                if номер == 0 { строка.removeValue(forKey: "поставка") }
                if номер == 1 { строка["путь"] = "../outside.swift" }
                if номер == 2 { строка["режим"] = "100755" }
                if номер == 3 { строка["требуемый"] = ["байтов": 22229, "хэш": "65a8baad449fd72e21774e8bb6083cc1cddfdda4417a33d919ecd521ffe347c3"] }
                if номер == 4 { строка["роль"] = "полныйФУМА" }
                if номер == 5 { строка["исполненный"] = ["байтов": 2, "хэш": Self.нулевойХэш] }
                строки[0] = строка; словарь["покрытие"] = строки
            }
        }
        if номер == 6 { модель.узлы[Self.путь("полный-исходник")]!.байты = Data("[]".utf8) }
        if номер == 7 { модель.узлы[Self.путь("скомпилированный")]!.байты = Data("[]".utf8) }
        if номер == 8 { модель.узлы[Self.путь("манифест")]!.байты = Data("[]".utf8) }
        if номер == 9 {
            let контекст = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
            модель.узлы[Self.путь("полный-исходник")]!.байты = Data("[]".utf8)
            #expect(Self.ошибка { try контекст.сверитьФайлы() } == .отказ("дрейф-байтов-исходника"))
        } else {
            #expect(Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы()) } != nil)
        }
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    private static func подготовитьДерево(_ модель: ФайловаяМодельДопуска, номер: Int = 0, вложенныйКорень: Bool = false,
                                        неверныйКорень: Bool = false, неверноеПолноеИмя: Bool = false, безНуля: Bool = false,
                                        отсутствующийОбъект: Bool = false) throws -> ЗапросДопускаУправляемогоВызова {
        let исходный = try Self.подготовить(модель)
        let данные = Data("{}".utf8), коммит = String(repeating: "a", count: 40), дерево = String(repeating: "b", count: 40)
        var объект = Data("blob \(данные.count)\0".utf8); объект.append(данные)
        let блоб = Insecure.SHA1.hash(data: объект).map { String(format: "%02x", $0) }.joined()
        let адресКорня = вложенныйКорень ? Self.путь("репозиторий/подкаталог") : Self.путь("репозиторий")
        if вложенныйКорень { модель.добавить(адресКорня, каталог: true) }
        let выбор = ВыборДереваИсходников(корень: модель.пин(.источник, адресКорня), коммит: коммит, дерево: дерево, блоб: блоб)
        let запрос = try Self.изменить(исходный) { словарь in
            var строки = словарь["покрытие"] as! [[String: Any]], строка = строки[0]
            строка.removeValue(forKey: "поставка"); строка["дерево"] = try! JSONSerialization.jsonObject(with: Self.кодировать(выбор))
            строки[0] = строка; словарь["покрытие"] = строки
        }
        модель.ответыГит = { аргументы in
            let команда = Array(аргументы.dropFirst(ПолитикаБезэффектногоЧтенияГит.флаги.count + 2))
            if команда == ["rev-parse", "--path-format=absolute", "--show-toplevel"] { return Data(((неверныйКорень ? Self.путь("другой-репозиторий") : Self.путь("репозиторий")) + "\n").utf8) }
            if команда == ["--version"] { return Data("git version synthetic\n".utf8) }
            if команда == ["rev-parse", "--verify", коммит + "^{commit}"] { return Data(((номер == 1 ? дерево : коммит) + "\n").utf8) }
            if команда == ["rev-parse", "--verify", коммит + "^{tree}"] { return Data(((номер == 2 ? коммит : дерево) + "\n").utf8) }
            if команда.first == "ls-tree" {
                let режим = номер == 3 ? "100755" : "100644", путь = номер == 4 ? "other.swift" : (неверноеПолноеИмя ? "подкаталог/koordinaciya/координатор.swift" : "koordinaciya/координатор.swift")
                return Data((режим + " blob " + (номер == 5 ? коммит : блоб) + "\t" + путь + (безНуля ? "" : "\0")).utf8)
            }
            if команда == ["cat-file", "blob", блоб] {
                if отсутствующийОбъект { throw ОтказУправляемогоДопуска.отказ("выбранный-объект-недоступен") }
                return номер == 6 ? Data("[]".utf8) : данные
            }
            throw ОтказУправляемогоДопуска.неизвестно("неожиданная-команда-модели")
        }
        if номер == 7 { модель.узлы[Self.путь("репозиторий")]!.номер += 1 }
        return запрос
    }
    @Test(arguments: 0..<8) func ВыбранныйКоммитДеревоБлоб(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель, номер: номер)
        let отказ = Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы()) }
        #expect((отказ == nil) == (номер == 0))
        #expect(модель.записи.isEmpty && модель.запуски == 0)
        if номер == 0 { #expect(модель.команды.contains { $0.contains("cat-file") }) }
    }
    @Test(arguments: 0..<9) func ТочныйНативныйДиапазонИПривязки(_ номер: Int) throws {
        // Это исторический selected15 input, не текущая Native config revision2.
        let закреплённый = try ИсторическийНативныйВход.прочитать()
        let полные = закреплённый.полный, фрагмент = закреплённый.скомпилированный
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let путь = закреплённый.вход.каноническийПуть, идентичность = ИдентичностьИсходникаДопуска(байтов: полные.count, хэш: Self.хэш(полные))
        let исполненный = ИдентичностьИсходникаДопуска(байтов: фрагмент.count, хэш: Self.хэш(фрагмент))
        модель.добавить(закреплённый.вход.полный.путь, байты: полные); модель.добавить(закреплённый.вход.скомпилированный.путь, байты: фрагмент)
        let манифест = МанифестЧленаПоставки(схема: "fum.source-supply-member.1", каноническийПуть: путь, режим: "100644", идентичность: идентичность)
        модель.узлы[Self.путь("манифест")]!.байты = try Self.кодировать(манифест)
        let разрешённый = ДиапазонИсполненногоИсходника(каноническийПуть: путь, роль: .диапазонНативного, скомпилированныйПуть: закреплённый.вход.скомпилированный.путь,
            полный: идентичность, смещение: 96436, длина: 239178, результат: исполненный, исключённыйПрефикс: "db86116ab740f23fabc2a9ebc33cf51e3c7595b6b0f3ce3a337bb815e59c83d6")
        let предложенный = ДиапазонИсполненногоИсходника(каноническийПуть: номер == 1 ? "other.swift" : путь,
            роль: номер == 2 ? .полныйФУМА : .диапазонНативного, скомпилированныйПуть: номер == 3 ? Self.путь("other") : закреплённый.вход.скомпилированный.путь,
            полный: номер == 4 ? исполненный : идентичность, смещение: номер == 5 ? 96435 : 96436,
            длина: номер == 6 ? 239179 : 239178, результат: номер == 7 ? идентичность : исполненный,
            исключённыйПрефикс: номер == 8 ? Self.нулевойХэш : разрешённый.исключённыйПрефикс)
        let строка = ПокрытиеИсполненногоИсходника(путь: путь, роль: .диапазонНативного, режим: "100644", исполненный: исполненный, требуемый: идентичность,
            скомпилированный: модель.пин(.источник, закреплённый.вход.скомпилированный.путь), дерево: nil,
            поставка: ЧленПоставкиИсходников(манифест: модель.пин(.источник, Self.путь("манифест")), файл: модель.пин(.источник, закреплённый.вход.полный.путь)), диапазон: предложенный)
        let запрос = try Self.изменить(исходный) { $0["покрытие"] = try! JSONSerialization.jsonObject(with: Self.кодировать([строка])) }
        let отказ = Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос, диапазоны: [разрешённый]), запрос.операция, модель.швы()) }
        #expect((отказ == nil) == (номер == 0))
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<8) func ТочныеОтказыСканераИПути(_ номер: Int) throws {
        let байты: Data, ожидаемый: ОтказУправляемогоДопуска?
        var политика = "canonical-typed-test", подменаХэша = false
        switch номер {
        case 0:
            байты = try Self.кодировать(["a": [["b": "phrase /home/synthetic value"]]])
            ожидаемый = .публикация("$[\"a\"][0][\"b\"]")
        case 1:
            байты = Data("{\"v\":\"\\u002fhome\\u002fsynthetic\"}".utf8)
            ожидаемый = .неизвестно("неподдержанный-JSON-формат") // Unsupported escaped raw body is not scanner success.
        case 2:
            let декодированный = try JSONDecoder().decode([String: String].self, from: Data("{\"v\":\"\\u002fhome\\u002fsynthetic\"}".utf8))
            байты = try Self.кодировать(декодированный); ожидаемый = .публикация("$[\"v\"]")
        case 3:
            байты = try Self.кодировать(["a.b[\"q\"]": "/home/synthetic"])
            ожидаемый = .публикация("$[\"a.b[\\\"q\\\"]\"]")
        case 4:
            байты = try Self.кодировать(["a\\b": "/home/synthetic"]); ожидаемый = .публикация("$[\"a\\\\b\"]")
        case 5:
            байты = try Self.кодировать(["privatePath": "raw private words"]); ожидаемый = nil
        case 6:
            байты = try Self.кодировать(["safe": "value"]); подменаХэша = true; ожидаемый = .отказ("хэш-публичного-тела")
        default:
            байты = try Self.кодировать(["safe": "value"]); политика = "unsupported"; ожидаемый = .неизвестно("неподдержанная-JSON-политика")
        }
        #expect(Self.ошибка { try ПолитикаУправляемогоДопуска.проверитьПубличноеТело(байты, хэш: подменаХэша ? Self.нулевойХэш : Self.хэш(байты), политика: политика) } == ожидаемый)
    }
    @Test(arguments: [false, true]) func ЗакреплённыеПубличныеТела(_ положительное: Bool) throws {
        guard let каталог = ProcessInfo.processInfo.environment["MANAGED_PUBLICATION_FIXTURES"] else { throw ОтказУправляемогоДопуска.неизвестно("нет-фикстур-публикации") }
        let имя = положительное ? "positive-selected-public-body.bin" : "negative-selected-public-body.bin"
        let хэш = положительное ? "e32c6564ece67963600ef6b1ec8ba5b15ca6d86c4d7a6810474caff8374fb6b0" : "ec315e079dfeffa49dd5a72203b705d23b6bf0d6610577abfdc352c646d28c33"
        let байты = try Data(contentsOf: URL(fileURLWithPath: каталог).appendingPathComponent(имя))
        guard байты.count == (положительное ? 6141 : 5207), Self.хэш(байты) == хэш else { throw ОтказУправляемогоДопуска.отказ("пин-публичной-фикстуры") }
        let ожидаемый: ОтказУправляемогоДопуска? = положительное ? nil : .публикация("$[\"эпизоды\"][0][\"события\"][1]")
        #expect(Self.ошибка { try ПолитикаУправляемогоДопуска.проверитьПубличноеТело(байты, хэш: хэш, политика: "exact-selected-bodies") } == ожидаемый)
    }
    @Test(arguments: 0..<2) func КонечныйПакетИПубличнаяЗапись(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель, номер: 3)
        let запрос = try Self.изменить(исходный) { $0["хэшПубличногоТела"] = Self.нулевойХэш }
        let контекст = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
        _ = try контекст.прочитать(Self.путь("источник"), роль: .источник)
        let чтенийБыло = модель.чтения.count
        let отказ = Self.ошибка {
            if номер == 0 { try контекст.проверитьПакет(Data("wrong".utf8)) }
            else { try контекст.записать(Data("{}".utf8), в: Self.путь("публичнаяПроекция/данные.json"), роль: .публичнаяПроекция, публично: true) }
        }
        #expect(отказ == .отказ(номер == 0 ? "хэш-конечного-пакета" : "хэш-публичного-тела"))
        #expect(модель.чтения.count >= чтенийБыло && модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test func СовместимостьПроводногоФормата() throws {
        let случай = ВходСлучаяГенератораFUMA(id: "wire", acceptedSelection: ПараметрыВыбораAPI(model: "synthetic", reasoningEffort: "low"),
            rootUUID: Self.корень, title: "title", description: "description", rawRequest: " bytes\r\n")
        let словарь = try JSONSerialization.jsonObject(with: Self.кодировать(случай)) as! [String: Any]
        #expect(Set(словарь.keys) == Set(["id", "acceptedSelection", "rootUUID", "title", "description", "rawRequest"]))
        #expect(словарь["rawRequest"] as? String == " bytes\r\n")
    }
    @Test func НастоящийОбработчикГенератораДоСтопа() throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let отказ = Self.ошибка { _ = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(запрос.аргументы, запросДопуска: запрос, решениеХоста: Self.решение(запрос), швы: модель.швы()) }
        // The production handler maps the sentinel to its command refusal, but the counted seam proves ordering.
        #expect(отказ == .отказ("managed-command") && модель.запуски == 1)
        #expect(модель.записи.count == 5)
    }
    @Test(arguments: 0..<4) func ТолькоПолныйФайлФУМА(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let полный = Data("full-file".utf8), скомпилированный = номер == 3 ? Data("file".utf8) : полный
        let путь = "Приложения/FUMA/Packages/КомпозицияНаблюдений/Tests/КомпозицияНаблюденийTests/ПроверкиЛокальнойОчереди.swift"
        модель.узлы[Self.путь("полный-исходник")]!.байты = полный
        модель.узлы[Self.путь("скомпилированный")]!.байты = скомпилированный
        let требуемый = ИдентичностьИсходникаДопуска(байтов: полный.count, хэш: Self.хэш(полный))
        let исполненный = ИдентичностьИсходникаДопуска(байтов: скомпилированный.count, хэш: Self.хэш(скомпилированный))
        let манифест = МанифестЧленаПоставки(схема: "fum.source-supply-member.1", каноническийПуть: путь, режим: "100644", идентичность: требуемый)
        модель.узлы[Self.путь("манифест")]!.байты = try Self.кодировать(манифест)
        let диапазон = ДиапазонИсполненногоИсходника(каноническийПуть: путь, роль: .полныйФУМА, скомпилированныйПуть: Self.путь("скомпилированный"),
            полный: требуемый, смещение: 0, длина: полный.count, результат: исполненный, исключённыйПрефикс: Self.хэш(Data()))
        let строка = ПокрытиеИсполненногоИсходника(путь: путь, роль: номер == 2 ? .полный : .полныйФУМА, режим: "100644", исполненный: исполненный,
            требуемый: требуемый, скомпилированный: модель.пин(.источник, Self.путь("скомпилированный")), дерево: nil,
            поставка: ЧленПоставкиИсходников(манифест: модель.пин(.источник, Self.путь("манифест")), файл: модель.пин(.источник, Self.путь("полный-исходник"))), диапазон: номер == 1 ? диапазон : nil)
        let запрос = try Self.изменить(исходный) { $0["покрытие"] = try! JSONSerialization.jsonObject(with: Self.кодировать([строка])) }
        let отказ = Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос, диапазоны: [диапазон]), запрос.операция, модель.швы()) }
        #expect((отказ == nil) == (номер == 0))
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }

    @Test(arguments: 0..<7) func ФактическиеАргументыДоВсехЭффектов(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель, номер: номер == 3 ? 7 : (номер == 4 ? 1 : (номер == 5 ? 2 : 4)))
        var фактические = запрос.аргументы
        if номер == 0 { фактические[1] = Self.путь("другое-определение") }
        if номер == 1 { фактические[0] = "--проверить-fuma-root-native-client" }
        if номер == 2 || номер == 3 { фактические.append("extra") }
        if номер == 4 { фактические[2] = Self.путь("другие-метаданные") }
        if номер == 5 { фактические[0] = "--проверить-сырой-коммит" }
        if номер == 6 { фактические = [] }
        #expect(!запрос.покрытие.isEmpty)
        let отказ = Self.ошибка { _ = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(фактические, запросДопуска: запрос, решениеХоста: Self.решение(запрос), швы: модель.швы()) }
        #expect(отказ == .отказ("фактические-argv-не-допущены"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<6) func ФактическиеПараметрыИсполнителяДоВсехЭффектов(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let определение = номер == 0 ? Self.путь("другое-определение") : (номер == 4 ? "" : Self.путь("определение"))
        let оператор = номер == 1 ? Self.путь("другой-оператор") : (номер == 3 ? "оператор" : Self.путь("оператор"))
        let кореньЗапуска = номер == 2 ? Self.путь("другой-корень") : (номер == 5 ? Self.путь("alias/../кореньЗапуска") : Self.путь("кореньЗапуска"))
        #expect(!запрос.покрытие.isEmpty)
        let отказ = Self.ошибка {
            _ = try ИсполнительГенератораFUMA.выполнить(input: ПакетВходаГенератораFUMA(cases: []), definitionPath: определение,
                operatorPath: оператор, privateRunRoot: кореньЗапуска, запросДопуска: запрос, решениеХоста: Self.решение(запрос), швы: модель.швы())
        }
        #expect(отказ == .отказ("фактические-параметры-исполнителя-не-допущены"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test func ПодготовленныйКонтекстБезНовыхЭффектов() throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель), допуск = try Self.решение(запрос)
        let контекст = try КонтекстУправляемогоДопуска(запрос, допуск, запрос.операция, модель.швы())
        let чтений = модель.чтения.count, статов = модель.статы.count
        let отказ = Self.ошибка {
            _ = try ИсполнительГенератораFUMA.выполнить(input: ПакетВходаГенератораFUMA(cases: []), definitionPath: Self.путь("wrong"),
                operatorPath: Self.путь("оператор"), privateRunRoot: Self.путь("кореньЗапуска"), запросДопуска: запрос, решениеХоста: допуск,
                швы: модель.швы(), подготовленныйКонтекст: контекст)
        }
        #expect(отказ == .отказ("фактические-параметры-исполнителя-не-допущены"))
        #expect(модель.чтения.count == чтений && модель.статы.count == статов && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<10) func ДопускИПолитикаГитДоВсехЭффектов(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let запрос = try Self.изменить(исходный) { словарь in
            if номер == 0 { словарь["кодПолитикиГит"] = "unsupported" }
            var окружение = словарь["окружение"] as! [String: String]
            if номер == 1 { окружение.removeValue(forKey: "GIT_NO_LAZY_FETCH") }
            if номер == 2 { окружение["GIT_OPTIONAL_LOCKS"] = "1" }
            if номер == 9 { окружение["GIT_CONFIG_COUNT"] = "1" }
            словарь["окружение"] = окружение
        }
        let исходныйДопуск = try Self.решение(запрос), прежний = исходныйДопуск.допускЧтенияГит!
        let инойИнструмент = модель.пин(.проверяющий, Self.путь("проверяющий"))
        let способность: НезависимыйДопускЧтенияГит? = номер == 3 ? nil : НезависимыйДопускЧтенияГит(
            инструмент: номер == 5 ? инойИнструмент : прежний.инструмент, версия: номер == 6 ? "git version wrong" : прежний.версия,
            уровень: номер == 4 ? .толькоРаспознаваниеФлагов : .независимоПровереннаяСемантика,
            хэшПарсерногоДоказательства: прежний.хэшПарсерногоДоказательства,
            хэшСемантическогоДоказательства: номер == 7 ? прежний.хэшПарсерногоДоказательства : (номер == 8 ? nil : прежний.хэшСемантическогоДоказательства))
        let допуск = РешениеХостаУправляемогоВызова(статус: .разрешено, хэшЗапроса: исходныйДопуск.хэшЗапроса, операция: запрос.операция,
            писатель: запрос.писатель, область: запрос.область, разрешённыеДиапазоны: [], допускЧтенияГит: способность)
        #expect(Self.ошибка { try Self.запуск(запрос, допуск, модель) } != nil)
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: [false, true]) func ФлагиИОкружениеКаждогоГитВызова(_ дерево: Bool) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try дерево ? Self.подготовитьДерево(модель) : Self.подготовить(модель)
        if дерево { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы()) }
        else { #expect(Self.ошибка { try Self.запуск(запрос, Self.решение(запрос), модель) } == .стопПередЗапуском) }
        #expect(!модель.команды.isEmpty && модель.команды.count == модель.окруженияКоманд.count)
        for (аргументы, окружение) in zip(модель.команды, модель.окруженияКоманд) {
            #expect(Array(аргументы.prefix(4)) == ["--no-optional-locks", "--no-lazy-fetch", "--no-replace-objects", "--literal-pathspecs"])
            #expect(окружение == запрос.окружение)
        }
    }

    @Test(arguments: 0..<14) func ФизическийДопускДоПервогоГитВОбработчике(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель)
        let прежнее = try Self.решение(запрос)
        var способность = прежнее.допускЧтенияГит!
        let физический = try Self.физическийДопуск(запрос, случай: номер)
        способность.физическийКонтекст = номер == 0 ? nil : физический
        let допуск = РешениеХостаУправляемогоВызова(статус: прежнее.статус, хэшЗапроса: прежнее.хэшЗапроса, операция: прежнее.операция,
            писатель: прежнее.писатель, область: прежнее.область, разрешённыеДиапазоны: [], допускЧтенияГит: способность)
        if номер == 9 {
            var статовКорня = 0
            модель.послеСтата = { пин in
                if пин.путь == Self.путь("репозиторий") {
                    статовКорня += 1
                    if статовКорня == 2 { модель.узлы[пин.путь]!.номер += 1 }
                }
            }
        }
        let отказ = Self.ошибка {
            _ = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(запрос.аргументы, запросДопуска: запрос,
                решениеХоста: допуск, швы: модель.швы())
        }
        #expect(отказ != nil)
        #expect(модель.команды == [])
        #expect(модель.окруженияКоманд == [] && модель.каталогиКоманд == [])
        #expect(модель.записи == [] && модель.запуски == 0)
    }
    @Test func ПолныйУпорядоченныйСледФизическогоГит() throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель)
        _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы())
        let выбор = запрос.покрытие[0].дерево!
        let адрес = ПолитикаБезэффектногоЧтенияГит.флаги + Self.адресГит()
        let ожидаемые = [
            ["--version"], ["rev-parse", "--path-format=absolute", "--show-toplevel"],
            ["rev-parse", "--verify", выбор.коммит + "^{commit}"], ["rev-parse", "--verify", выбор.коммит + "^{tree}"],
            ["ls-tree", "--full-tree", "--full-name", "-z", выбор.дерево, "--", запрос.покрытие[0].путь],
            ["cat-file", "blob", выбор.блоб]
        ].map { адрес + $0 }
        #expect(модель.команды == ожидаемые)
        #expect(модель.окруженияКоманд == Array(repeating: запрос.окружение, count: ожидаемые.count))
        #expect(модель.каталогиКоманд == Array(repeating: Self.путь("репозиторий"), count: ожидаемые.count))
        #expect(модель.записи == [] && модель.запуски == 0)
    }
    @Test(arguments: 0..<3) func НетБезадресныхКомандИПоискаРодителя(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель)
        let аргументы = номер == 0 ? ["--version"] : ["-C", Self.путь(номер == 1 ? "DATA" : "репозиторий"), "--version"]
        let отказ = Self.ошибка {
            _ = try ПолитикаБезэффектногоЧтенияГит.подготовить(запрос, решение: Self.решение(запрос),
                аргументы: аргументы, окружение: запрос.окружение)
        }
        #expect(отказ == .отказ("команда-вне-контура-чтения-гит"))
        #expect(модель.команды == [] && модель.записи == [] && модель.запуски == 0)
    }

    @Test(arguments: [false, true]) func ОбщийАдминТолькоИзПереданногоОкружения(_ отсутствует: Bool) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель)
        var окружение = запрос.окружение
        if отсутствует { окружение.removeValue(forKey: "GIT_COMMON_DIR") }
        else { окружение["GIT_COMMON_DIR"] = Self.путь("DATA") }
        let отказ = Self.ошибка {
            _ = try ПолитикаБезэффектногоЧтенияГит.подготовить(запрос, решение: Self.решение(запрос),
                аргументы: Self.адресГит() + ["--version"], окружение: окружение)
        }
        #expect(отказ == .отказ("окружение-команды-чтения-гит"))
        #expect(модель.команды == [] && модель.записи == [] && модель.запуски == 0)
    }

    @Test func ОтсутствующийОбъектБезПовтораИПолучения() throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель, отсутствующийОбъект: true)
        let отказ = Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы()) }
        #expect(отказ == .отказ("выбранный-объект-недоступен"))
        #expect(модель.команды.filter { $0.contains("cat-file") }.count == 1)
        #expect(!модель.команды.contains { $0.contains("fetch") || $0.contains("clone") })
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: 0..<5) func ФизическийКореньИПолныеИмена(_ номер: Int) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовитьДерево(модель, вложенныйКорень: номер == 0,
            неверныйКорень: номер == 1, неверноеПолноеИмя: номер == 2, безНуля: номер == 3)
        let отказ = Self.ошибка { _ = try КонтекстУправляемогоДопуска(запрос, Self.решение(запрос), запрос.операция, модель.швы()) }
        if номер < 2 {
            #expect(отказ == .отказ(номер == 0 ? "чужой-корень-или-кортеж-гит" : "источник-не-физический-корень-репозитория"))
            #expect(!модель.команды.contains { $0.contains("ls-tree") || $0.contains("cat-file") })
        } else if номер < 4 { #expect(отказ == .отказ("выбранная-запись-дерева")) }
        else { #expect(отказ == nil) }
        #expect(модель.записи.isEmpty && модель.запуски == 0)
    }
    @Test func ПарсерныйФактНеСемантическийДопуск() throws {
        let модель = ФайловаяМодельДопуска(), исходный = try Self.подготовить(модель)
        let запрос = try Self.изменить(исходный) { словарь in
            словарь["версияГит"] = "git version 2.54.0 (Apple Git-157)"
            var пины = словарь["пины"] as! [[String: Any]], пин = пины.first { ($0["роль"] as? String) == "исполнительГит" }!
            пин["байтов"] = 200560; пин["хэш"] = "34129c71a01a74f7f3b2443521519b2e5447553fa187f5fcafaaf8c42cc192e2"
            пины.removeAll { ($0["роль"] as? String) == "исполнительГит" }; пины.append(пин); словарь["пины"] = пины
        }
        let способность = НезависимыйДопускЧтенияГит(инструмент: запрос.пины.first { $0.роль == .исполнительГит }!, версия: запрос.версияГит,
            уровень: .толькоРаспознаваниеФлагов, хэшПарсерногоДоказательства: "916fe6dafcaec28ad9ab4b647c1498e93241d3c8057d57bb72b680ec2729778d", хэшСемантическогоДоказательства: nil)
        let допуск = РешениеХостаУправляемогоВызова(статус: .разрешено, хэшЗапроса: try запрос.каноническийХэш(), операция: запрос.операция,
            писатель: запрос.писатель, область: запрос.область, разрешённыеДиапазоны: [], допускЧтенияГит: способность)
        #expect(Self.ошибка { try Self.запуск(запрос, допуск, модель) } == .неизвестно("семантика-no-fetch-не-доказана"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }

    @Test(arguments: [false, true]) func НетРешенияПриНеверномФактическомВызове(_ исполнитель: Bool) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let отказ = Self.ошибка {
            if исполнитель {
                _ = try ИсполнительГенератораFUMA.выполнить(input: ПакетВходаГенератораFUMA(cases: []), definitionPath: "wrong",
                    operatorPath: "wrong", privateRunRoot: "wrong", запросДопуска: запрос, решениеХоста: nil, швы: модель.швы())
            } else { _ = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(["wrong"], запросДопуска: запрос, решениеХоста: nil, швы: модель.швы()) }
        }
        #expect(отказ == .неизвестно("нет-независимого-решения"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }
    @Test(arguments: [false, true]) func ПодменаОкруженияКомандыБезВызова(_ отсутствует: Bool) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        var окружение = запрос.окружение
        if отсутствует { окружение.removeValue(forKey: "GIT_NO_LAZY_FETCH") } else { окружение["GIT_OPTIONAL_LOCKS"] = "1" }
        let отказ = Self.ошибка { _ = try ПолитикаБезэффектногоЧтенияГит.подготовить(запрос, решение: Self.решение(запрос), аргументы: Self.адресГит() + ["--version"], окружение: окружение) }
        #expect(отказ == .отказ("окружение-команды-чтения-гит"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }

    @Test(arguments: [false, true]) func ПолитикаНеДопускаетКомандуЗаписи(_ получение: Bool) throws {
        let модель = ФайловаяМодельДопуска(), запрос = try Self.подготовить(модель)
        let аргументы = получение ? ["fetch", "origin"] : ["config", "--global", "test.value", "changed"]
        let отказ = Self.ошибка { _ = try ПолитикаБезэффектногоЧтенияГит.подготовить(запрос, решение: Self.решение(запрос), аргументы: аргументы, окружение: запрос.окружение) }
        #expect(отказ == .отказ("команда-вне-контура-чтения-гит"))
        #expect(модель.чтения.isEmpty && модель.статы.isEmpty && модель.записи.isEmpty && модель.команды.isEmpty && модель.запуски == 0)
    }

    private static func захватДанных(вывод: Data, ошибки: Data, пределВывода: Int, пределОшибок: Int, сначалаОшибки: Bool = false) throws ->
        (вывод: Data, ошибки: Data, каналы: [Int], размеры: [Int], ожидания: [[Int]]) {
        var остатки = [вывод, ошибки], выбранные: [Int] = [], каналы: [Int] = [], размеры: [Int] = [], ожидания: [[Int]] = []
        let результат = try ШвыУправляемогоВызова.ограниченноПрочитатьОбаКанала(пределВывода: пределВывода, пределОшибок: пределОшибок,
            ожидать: { открытые in
                ожидания.append(открытые)
                выбранные = сначалаОшибки && открытые.contains(1) ? [1] : открытые
                return выбранные
            }, прочитать: { канал, размер in
                guard выбранные.contains(канал) else { throw ОтказУправляемогоДопуска.отказ("чтение-неготового-канала") }
                каналы.append(канал); размеры.append(размер)
                let порция = Data(остатки[канал].prefix(размер)); остатки[канал].removeFirst(порция.count)
                return порция
            })
        return (результат.вывод, результат.ошибки, каналы, размеры, ожидания)
    }
    @Test(arguments: 0..<8) func ГраницыЗахватаДвухКаналов(_ номер: Int) throws {
        let вывод: Data, ошибки: Data, пределВывода: Int, пределОшибок: Int, ожидаемый: ОтказУправляемогоДопуска?
        switch номер {
        case 0: вывод = Data("abcd".utf8); ошибки = Data("xyz".utf8); пределВывода = 4; пределОшибок = 3; ожидаемый = nil
        case 1: вывод = Data("abcde".utf8); ошибки = Data("xy".utf8); пределВывода = 4; пределОшибок = 3; ожидаемый = .отказ("переполнение-стандартного-вывода-гит")
        case 2: вывод = Data("abc".utf8); ошибки = Data("xyzw".utf8); пределВывода = 4; пределОшибок = 3; ожидаемый = .отказ("переполнение-стандартных-ошибок-гит")
        case 3: вывод = Data(); ошибки = Data(); пределВывода = 0; пределОшибок = 0; ожидаемый = nil
        case 4: вывод = Data([1]); ошибки = Data(); пределВывода = 0; пределОшибок = 0; ожидаемый = .отказ("переполнение-стандартного-вывода-гит")
        case 5: вывод = Data(); ошибки = Data([1]); пределВывода = 0; пределОшибок = 0; ожидаемый = .отказ("переполнение-стандартных-ошибок-гит")
        case 6: вывод = Data([0, 255, 10]); ошибки = Data([255, 0]); пределВывода = 4; пределОшибок = 3; ожидаемый = nil
        default: вывод = Data("OK".utf8); ошибки = Data("overflow".utf8); пределВывода = 4; пределОшибок = 3; ожидаемый = .отказ("переполнение-стандартных-ошибок-гит")
        }
        var разобрано = false, итогВывода: Data?, итогОшибок: Data?
        let отказ = Self.ошибка {
            let результат = try Self.захватДанных(вывод: вывод, ошибки: ошибки, пределВывода: пределВывода, пределОшибок: пределОшибок)
            итогВывода = результат.вывод; итогОшибок = результат.ошибки; разобрано = true
        }
        #expect(отказ == ожидаемый)
        if ожидаемый == nil { #expect(разобрано && итогВывода == вывод && итогОшибок == ошибки) }
        else { #expect(!разобрано && итогВывода == nil && итогОшибок == nil) }
    }
    @Test(arguments: [false, true]) func ГотовностьОшибокНеЖдётКонцаВывода(_ сначалаОшибки: Bool) throws {
        let вывод = Data("later".utf8), ошибки = Data(repeating: 65, count: 65_536)
        let результат = try Self.захватДанных(вывод: вывод, ошибки: ошибки, пределВывода: 5, пределОшибок: 65_536, сначалаОшибки: сначалаОшибки)
        #expect(результат.вывод == вывод && результат.ошибки == ошибки)
        #expect(результат.ожидания.first == [0, 1])
        #expect(результат.каналы.contains(0) && результат.каналы.contains(1))
        if сначалаОшибки { #expect(Array(результат.каналы.prefix(2)) == [1, 1] && результат.размеры[1] == 1) }
        else { #expect(результат.каналы.first == 0) }
    }
    @Test(arguments: 0..<3) func НетРазбораПослеОтказаКанала(_ номер: Int) throws {
        var разобрано = false
        let отказ = Self.ошибка {
            _ = try ШвыУправляемогоВызова.ограниченноПрочитатьОбаКанала(пределВывода: 1, пределОшибок: 1,
                ожидать: { _ in номер == 1 ? [2] : [0, 1] }, прочитать: { канал, размер in
                    if номер == 2 { return Data(repeating: 1, count: размер + 1) }
                    if канал == 0 { return Data([1]) }
                    throw ОтказУправляемогоДопуска.отказ("диагностический-отказ-чтения")
                })
            разобрано = true
        }
        let ожидаемый: ОтказУправляемогоДопуска = номер == 0 ? .отказ("диагностический-отказ-чтения") :
            (номер == 1 ? .неизвестно("неизвестный-канал-захвата-гит") : .неизвестно("нарушен-контракт-чтения-гит"))
        #expect(отказ == ожидаемый)
        #expect(!разобрано)
    }

}


@Suite("Нативная конфигурация: конечный provider", .serialized)
struct ПроверкиНативногоПровайдера {
    static let сессия = "01a192d0-6f09-7950-9251-b27101106bfc"
    static func строка() -> [String: Any] {
        ["id": сессия, "model_provider": "openai", "model": "gpt-test", "reasoning_effort": "high",
         "updated_at": 1_700_000_000, "updated_at_ms": Int64(1_700_000_000_123)]
    }
    @Test(arguments: 0..<18) func МатрицаСтрокиБезНативногоЧтения(_ номер: Int) throws {
        var строка = Self.строка()
        if номер == 3 { строка["model"] = NSNull() }
        if номер == 4 { строка["id"] = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb" }
        if номер == 5 { строка["reasoning_effort"] = "banana" }
        if номер == 6 { строка["model"] = "UNKNOWN" }
        if номер == 7 { строка["updated_at_ms"] = NSNull() }
        if номер == 8 { строка["updated_at"] = 1_700_000_000.5 }
        if номер == 9 { строка["updated_at"] = true }
        if номер == 10 { строка["updated_at_ms"] = Int64(1_700_000_002_123) }
        if номер == 11 { строка["updated_at"] = 1_900_000_000; строка["updated_at_ms"] = Int64(1_900_000_000_123) }
        if номер == 12 { строка["unexpected"] = "synthetic-not-RAW" }
        if номер == 14 { строка["model_provider"] = "" }
        if номер == 16 { строка.removeValue(forKey: "model") }
        if номер == 17 { строка["model"] = "gpt-test\nforged" }
        let строки = номер == 1 ? [] : (номер == 2 ? [строка, строка] : [строка])
        let байтыJSON = try JSONSerialization.data(withJSONObject: строки, options: [.sortedKeys])
        let байты = номер == 13 ? Data([0xff]) : байтыJSON
        var наблюдение: НаблюдениеНативнойКонфигурации?, отказ = false
        do {
            наблюдение = try ПровайдерНативнойКонфигурации.разобратьПроверочное(байты, сессия: Self.сессия,
                запрошено: номер == 15 ? ПараметрыВыбораAPI(model: "different-requested", reasoningEffort: "low") : nil)
        } catch { отказ = true }
        #expect(отказ == (номер != 0 && номер != 15))
        if номер == 0 || номер == 15 {
            let значение = try #require(наблюдение)
            #expect(значение.значение == ПараметрыВыбораAPI(model: "gpt-test", reasoningEffort: "high"))
            #expect(значение.backend == "UNKNOWN" && значение.режимИсточника == "TESTING_SYNTHETIC_NOT_NATIVE")
            #expect(значение.совпадаетСЗапрошенным == (номер == 15 ? false : nil))
        }
    }
    @Test(arguments: 0..<3) func ПланТолькоИндексСобственногоИдентификатора(_ номер: Int) throws {
        let описание = номер == 0 ? "SEARCH threads USING INDEX sqlite_autoindex_threads_1 (id=?)" :
            (номер == 1 ? "SCAN threads" : "SEARCH other_table USING INDEX foreign_index (id=?)")
        let байты = try JSONSerialization.data(withJSONObject: [["id": 3, "parent": 0, "notused": 0, "detail": описание]])
        var отказ = false
        do { try ПровайдерНативнойКонфигурации.проверитьПлан(байты) } catch { отказ = true }
        #expect(отказ == (номер != 0))
    }
    @Test(arguments: [false, true]) func ИзвестнаяСменаИнвалидируетСтароеНаблюдение(_ смена: Bool) throws {
        let байты = try JSONSerialization.data(withJSONObject: [Self.строка()])
        let наблюдение = try ПровайдерНативнойКонфигурации.разобратьПроверочное(байты, сессия: Self.сессия, поколение: "generation-1")
        #expect(наблюдение.совпадаетСКонтекстом(сессия: Self.сессия, поколениеИзвестнойСмены: смена ? "generation-2" : "generation-1") == !смена)
        #expect(наблюдение.обновленоМс == 1_700_000_000_123)
        // This row revision is not asserted to be the time of a model change.
    }
    @Test(arguments: 0..<4) func ДедлайнИОтказБезЧастичногоНаблюдения(_ номер: Int) throws {
        if номер == 0 {
            #expect(try ШвыУправляемогоВызова.остатокВремениНативногоЧтения(10, теперь: 9) == 1000)
        } else if номер < 3 {
            var отказ = false
            do { _ = try ШвыУправляемогоВызова.остатокВремениНативногоЧтения(номер == 1 ? 10 : .nan, теперь: 10) } catch { отказ = true }
            #expect(отказ)
        } else {
            var чтений = 0, возвращено = false
            let отказ = ПроверкиУправляемогоДопуска.ошибка {
                _ = try ШвыУправляемогоВызова.ограниченноПрочитатьОбаКанала(пределВывода: 16, пределОшибок: 16,
                    ожидать: { _ in
                        if чтений == 0 { return [0] }
                        throw ОтказУправляемогоДопуска.неизвестно("native-model-timeout")
                    }, прочитать: { _, _ in чтений += 1; return Data([1]) })
                возвращено = true
            }
            #expect(отказ == .неизвестно("native-model-timeout"))
            #expect(!возвращено && чтений == 1)
        }
    }
    @Test(arguments: 0..<5) func ФиксированныйЗапросБезПроизвольногоSQL(_ номер: Int) throws {
        let значение = номер == 0 ? Self.сессия : (номер == 1 ? "" : (номер == 2 ? "invalid" :
            (номер == 3 ? Self.сессия.uppercased() : Self.сессия + "'; SELECT * FROM threads;")))
        var запрос: String?, отказ = false
        do { запрос = try ПровайдерНативнойКонфигурации.сформироватьЗапрос(значение) } catch { отказ = true }
        #expect(отказ == (номер != 0))
        if номер == 0 {
            let текстЗапроса = try #require(запрос)
            #expect(текстЗапроса == "SELECT id, model_provider, model, reasoning_effort, updated_at, updated_at_ms FROM threads WHERE id = '" + Self.сессия + "' LIMIT 2;")
            #expect(ПровайдерНативнойКонфигурации.аргументы(текстЗапроса, база: "/fixture/state_5.sqlite") ==
                ["-batch", "-bail", "-init", "/dev/null", "-readonly", "-nofollow", "-json", "/fixture/state_5.sqlite", текстЗапроса])
            #expect(ПровайдерНативнойКонфигурации.окружение == ["PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C", "HOME": "/dev/null"])
        }
    }


    @Test(arguments: 0..<3) func ПривязкаНеПереходитНаИдентификаторТакта(_ номер: Int) throws {
        let другойТакт = "01a196da-0000-7000-8000-000000000001"
        let назначение = ПривязкаНативногоЧата(нативныйЧатUUID: Self.сессия, исполнительныйТактUUID: nil,
            источникПривязки: "TESTING_SEPARATE_NATIVE_ASSIGNMENT_NOT_JSON")
        var отказ = false, связь: String?
        do {
            связь = try ПровайдерНативнойКонфигурации.сверитьПривязку(номер == 2 ? другойТакт : Self.сессия,
                назначение: назначение, наблюдённыйENVThreadID: номер == 0 ? Self.сессия : другойТакт)
        } catch { отказ = true }
        #expect(отказ == (номер == 2))
        if номер < 2 {
            #expect(связь == (номер == 0 ? "ENV_VALUE_MATCHES_CHAT_UUID_TURN_SEMANTICS_UNKNOWN" : "UNKNOWN_DIFFERENT_OR_MISSING_ENV_ID"))
            #expect(try ПровайдерНативнойКонфигурации.сформироватьЗапрос(назначение.нативныйЧатUUID) ==
                "SELECT id, model_provider, model, reasoning_effort, updated_at, updated_at_ms FROM threads WHERE id = '" + Self.сессия + "' LIMIT 2;")
            #expect(назначение.исполнительныйТактUUID == nil)
        }
    }

    // Separate addressed observation point, excluded from the pure selected35 contour.
    // Missing profile means disabled/UNKNOWN, never native-read success.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["NATIVE_MODEL_PROFILE"] != nil))
    func АдресноеНативноеНаблюдениеИзROПрофиля() throws {
        let среда = ProcessInfo.processInfo.environment
        guard let путь = среда["NATIVE_MODEL_PROFILE"], let строкаБайт = среда["NATIVE_MODEL_PROFILE_BYTES"],
              let байтов = Int(строкаБайт), let хэш = среда["NATIVE_MODEL_PROFILE_SHA256"],
              (1...16_384).contains(байтов), ПолитикаУправляемогоДопуска.хэшВерный(хэш) else {
            throw ОтказУправляемогоДопуска.неизвестно("native-model-addressed-profile-missing")
        }
        let байты = try ФайлИсторическогоВхода(путь: путь, байтов: байтов, хэш: хэш).прочитать()
        let профиль = try JSONDecoder().decode(ПрофильНативнойКонфигурации.self, from: байты)
        // This expected subject comes from the trusted ROOT/native assignment, never JSON or ambient turn ID.
        let привязка = ПривязкаНативногоЧата(нативныйЧатUUID: "01a192d0-6f09-7950-9251-b27101106bfc",
            исполнительныйТактUUID: nil, источникПривязки: "ROOT/native transport assignment for stable actor 01a192d0-6f09-7950-9251-b27101106bfc")
        let наблюдение = try ПровайдерНативнойКонфигурации.наблюдатьДляНовогоДопуска(профиль, привязка: привязка)
        let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        print("FUM_NATIVE_MODEL_OBSERVATION " + String(decoding: try кодировщик.encode(наблюдение), as: UTF8.self))
        #expect(наблюдение.режимИсточника == "NATIVE_SQLITE_READONLY")
        #expect(наблюдение.backend == "UNKNOWN")
    }
}

// Только чистые проверки нового контракта и того же raw reader; процессов здесь нет.
@Suite("Точное намерение коммита и полный raw OID")
struct ПроверкиТочногоНамеренияИRawOID {
    @Test func чтениеСырогоСоставаТребуетПолныеOID() throws {
        let старыйOID = String(repeating: "a", count: 40), новыйOID = String(repeating: "b", count: 40)
        let аргументы = try НаблюдательРабочегоДереваGit.аргументыСырогоСостава(основа: старыйOID, цель: новыйOID)
        #expect(аргументы == ["diff", "--raw", "--no-abbrev", "--no-renames", "-z", старыйOID, новыйOID, "--"])
        let полный = Data((":100644 100644 " + старыйOID + " " + новыйOID + " M\0koordinaciya/fixture.swift\0").utf8)
        let строки = try НаблюдательРабочегоДереваGit.разобратьСыройСостав(полный)
        #expect(строки.count == 1 && строки[0].старыйOID == старыйOID && строки[0].новыйOID == новыйOID)
        let короткий = Data((":100644 100644 " + String(старыйOID.prefix(7)) + " " + новыйOID + " M\0koordinaciya/fixture.swift\0").utf8)
        #expect(отказПриёма { _ = try НаблюдательРабочегоДереваGit.разобратьСыройСостав(короткий) })
    }

    @Test func одиночныйРодительНеУдовлетворяетНамерениюСлияния() throws {
        let первыйРодитель = String(repeating: "1", count: 40), второйРодитель = String(repeating: "2", count: 40)
        let дерево = String(repeating: "3", count: 40), корень = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
        let запрос = ЗапросМетаданныхИсходников(схема: "fum.source-checkpoint-metadata-request.1",
            корневойUUID: корень, писатель: корень, рабочееДерево: "/fixture",
            реф: "refs/heads/fixture", родитель: первыйРодитель, дерево: дерево, статусВыбора: "UNKNOWN",
            основаниеSHA256: String(repeating: "4", count: 64),
            план: ПланСообщенияКоммита(исходныйЗапрос: "Фикстура точного слияния",
                заголовок: "Сохранить точное слияние", описание: "Проверки и профиль UNKNOWN"))
        let выход = ГенераторМетаданныхКоммита.referenceOutput(for: запрос.входФорматтера).cases[0]
        let автор = выход.environment["GIT_AUTHOR_NAME"]!
        let метаданные = МетаданныеИсходников.подготовить(запрос: запрос,
            выход: ВыходГенератораGitMetadata(environment: выход.environment, message: выход.message),
            авторGit: автор + " <fixture@local> 0 +0000", коммитерGit: "FUM <fixture@local> 0 +0000")
        let намерение = НамерениеСозданияКоммитаGit(вид: .слияние, реф: запрос.реф, родители: [первыйРодитель, второйРодитель], дерево: дерево)
        #expect(намерение.проверить().isEmpty)
        func сыройКоммит(_ родители: [String]) -> Data {
            Data(("tree " + дерево + "\n" + родители.map { "parent " + $0 + "\n" }.joined() +
                "author " + автор + " <fixture@local> 0 +0000\ncommitter FUM <fixture@local> 0 +0000\n\n" + выход.message).utf8)
        }
        #expect(ОценщикИдентичностиGit.проверитьСырыеИсходники(сыройКоммит([первыйРодитель, второйРодитель]), метаданные: метаданные, намерение: намерение).isEmpty)
        for родители in [[первыйРодитель], [второйРодитель, первыйРодитель]] {
            #expect(ОценщикИдентичностиGit.проверитьСырыеИсходники(сыройКоммит(родители), метаданные: метаданные, намерение: намерение)
                .contains("сырой-parent-не-совпадает-с-намерением"))
        }
    }
}
