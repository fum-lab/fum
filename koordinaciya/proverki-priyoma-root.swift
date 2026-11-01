import Foundation
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
