import Darwin
import Foundation
import Testing
@testable import BootstrapЗависимости

private enum ОшибкаФикстуры: Error {
    case команда(String)
    case ожидание(String)
}

private struct ФикстураBootstrap {
    let временныйКорень: URL
    let корень: URL
    let origin: URL
    let upstream: URL
    let gitlink: String

    init() throws {
        let fm = FileManager.default
        временныйКорень = fm.temporaryDirectory
            .appendingPathComponent("fum-bootstrap-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: временныйКорень, withIntermediateDirectories: true)
        origin = временныйКорень.appendingPathComponent("origin.git", isDirectory: true)
        upstream = временныйКорень.appendingPathComponent("upstream.git", isDirectory: true)
        let seed = временныйКорень.appendingPathComponent("seed", isDirectory: true)
        let superproject = временныйКорень.appendingPathComponent("super", isDirectory: true)
        корень = временныйКорень.appendingPathComponent("linked", isDirectory: true)

        try Self.git(["init", "--bare", origin.path], в: временныйКорень)
        try Self.git(["init", "--bare", upstream.path], в: временныйКорень)
        try Self.git(["init", seed.path], в: временныйКорень)
        try Data("fixture\n".utf8).write(to: seed.appendingPathComponent("README.md"))
        try Self.git(["add", "README.md"], в: seed)
        try Self.git([
            "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
            "commit", "-m", "fixture",
        ], в: seed)
        gitlink = try Self.gitТекст(["rev-parse", "HEAD"], в: seed)
        try Self.git(["push", origin.path, "HEAD:refs/heads/master"], в: seed)
        try Self.git(["push", upstream.path, "HEAD:refs/heads/master"], в: seed)

        try Self.git(["init", superproject.path], в: временныйКорень)
        let modules = """
        [submodule "Зависимости/LinguisticKit"]
        \tpath = Зависимости/LinguisticKit
        \turl = \(origin.path)
        \tfumUpstream = \(upstream.path)
        """ + "\n"
        try Data(modules.utf8).write(to: superproject.appendingPathComponent(".gitmodules"))
        try Self.git(["add", ".gitmodules"], в: superproject)
        try Self.git([
            "update-index", "--add", "--cacheinfo",
            "160000,\(gitlink),Зависимости/LinguisticKit",
        ], в: superproject)
        try Self.git([
            "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
            "commit", "-m", "super",
        ], в: superproject)
        try Self.git(["worktree", "add", "--detach", корень.path, "HEAD"], в: superproject)
        let каталогЗависимостей = корень.appendingPathComponent("Зависимости", isDirectory: true)
        if !fm.fileExists(atPath: каталогЗависимостей.path) {
            try fm.createDirectory(at: каталогЗависимостей, withIntermediateDirectories: false)
        }
    }

    func удалить() {
        try? FileManager.default.removeItem(at: временныйКорень)
    }

    static func git(_ аргументы: [String], в каталог: URL) throws {
        _ = try gitДанные(аргументы, в: каталог)
    }

    static func gitТекст(_ аргументы: [String], в каталог: URL) throws -> String {
        String(decoding: try gitДанные(аргументы, в: каталог), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func gitДанные(_ аргументы: [String], в каталог: URL) throws -> Data {
        let процесс = Process()
        let вывод = Pipe()
        let ошибки = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = каталог
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        try процесс.run()
        процесс.waitUntilExit()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        let пояснение = String(
            decoding: ошибки.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard процесс.terminationStatus == 0 else {
            throw ОшибкаФикстуры.команда("git \(аргументы.joined(separator: " ")): \(пояснение)")
        }
        return данные
    }
}

private func ожидать(_ условие: @autoclosure () -> Bool, _ пояснение: String) throws {
    guard условие() else { throw ОшибкаФикстуры.ожидание(пояснение) }
}

private func ожидатьОтказ(_ действие: () throws -> Void) throws {
    do {
        try действие()
    } catch is ОтказBootstrapЗависимости {
        return
    }
    throw ОшибкаФикстуры.ожидание("Ожидался закрытый отказ bootstrap")
}

private func состояниеOutcome(_ путь: URL) throws -> СостояниеBootstrapЗависимости {
    let данные = try Data(contentsOf: путь)
    return try JSONDecoder().decode(ИсходBootstrapЗависимости.self, from: данные).состояние
}

private func обычныеФайлы(_ корень: URL) throws -> [(dev_t, ino_t, nlink_t)] {
    var результат: [(dev_t, ino_t, nlink_t)] = []
    let перечислитель = FileManager.default.enumerator(
        at: корень,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: [.skipsPackageDescendants])
    while let путь = перечислитель?.nextObject() as? URL {
        var сведения = stat()
        guard lstat(путь.path, &сведения) == 0 else {
            throw ОшибкаФикстуры.ожидание("Узел исчез при проверке inode")
        }
        if (сведения.st_mode & S_IFMT) == S_IFREG {
            результат.append((сведения.st_dev, сведения.st_ino, сведения.st_nlink))
        }
    }
    return результат
}

@Test func успешныйЦиклBootstrap() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    try ожидать(план.gitlinkOID == фикстура.gitlink, "План потерял exact gitlink")
    try ожидать(план.состояние == .отсутствует, "Свежая зависимость не должна быть готовой")
    try ожидать(
        план.adminGitDir.hasPrefix(план.gitDir + "/"),
        "Admin Gitdir зависимости вышел за adminDir linked worktree")
    try ожидать(
        !план.adminGitDir.hasPrefix(план.commonGitDir + "/modules/"),
        "Bootstrap выбрал общий modules")

    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    var этапы: [ЭтапДолговечностиBootstrap] = []
    let результат = try BootstrapЗависимости.применить(
        план: план, квитанция: квитанция,
        наблюдатель: { этапы.append($0) })
    try ожидать(результат.состояние == .готова, "Apply не завершился готовым состоянием")
    try ожидать(этапы == [
        .намерениеСинхронизировано,
        .материализацияСинхронизирована,
        .исходСинхронизирован,
    ], "Порядок durable intent/materialization/outcome нарушен")
    let прочитано = try BootstrapЗависимости.проверитьПослеПрименения(
        план: план, квитанция: квитанция)
    try ожидать(прочитано == результат, "Readback не совпал с outcome")
    let повторныйПлан = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    try ожидать(повторныйПлан.состояние == .готова, "Готовый клон не распознан")
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(план: повторныйПлан, квитанция: квитанция)
    }

    let зависимость = фикстура.корень.appendingPathComponent("Зависимости/LinguisticKit")
    let head = try ФикстураBootstrap.gitТекст(["rev-parse", "HEAD"], в: зависимость)
    try ожидать(
        head == фикстура.gitlink,
        "HEAD зависимости не равен pin")
    let symbolic = Process()
    symbolic.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    symbolic.arguments = ["symbolic-ref", "-q", "HEAD"]
    symbolic.currentDirectoryURL = зависимость
    symbolic.standardOutput = Pipe()
    symbolic.standardError = Pipe()
    try symbolic.run()
    symbolic.waitUntilExit()
    try ожидать(symbolic.terminationStatus == 1, "HEAD зависимости не detached")
    var сведенияКаталога = stat()
    let каталогКвитанций = квитанция.deletingLastPathComponent()
    try ожидать(
        lstat(каталогКвитанций.path, &сведенияКаталога) == 0
            && (сведенияКаталога.st_mode & 0o777) == 0o700,
        "Каталог bootstrap должен иметь приватный режим 0700")
    try ожидать(
        сведенияКаталога.st_uid == geteuid(),
        "Каталог bootstrap должен принадлежать euid")
    var сведенияOutcome = stat()
    try ожидать(
        lstat(квитанция.path, &сведенияOutcome) == 0
            && (сведенияOutcome.st_mode & 0o777) == 0o600
            && сведенияOutcome.st_uid == geteuid()
            && сведенияOutcome.st_nlink == 1,
        "Outcome должен быть приватным single-link файлом владельца")
    var сведенияAdmin = stat()
    try ожидать(
        lstat(план.adminGitDir, &сведенияAdmin) == 0
            && (сведенияAdmin.st_mode & 0o777) == 0o700
            && сведенияAdmin.st_uid == geteuid(),
        "Admin Gitdir должен быть приватным каталогом владельца")
}

@Test func локальныйOriginНеДелитInodeСAdminClone() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    _ = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)

    let originObjects = try обычныеФайлы(
        фикстура.origin.appendingPathComponent("objects", isDirectory: true))
    let adminFiles = try обычныеФайлы(URL(fileURLWithPath: план.adminGitDir, isDirectory: true))
    let originInodes = Set(originObjects.map { "\($0.0):\($0.1)" })
    try ожидать(
        adminFiles.allSatisfy { $0.2 == 1 },
        "Каждый обычный файл admin clone должен иметь единственную hardlink-ссылку")
    try ожидать(
        adminFiles.allSatisfy { !originInodes.contains("\($0.0):\($0.1)") },
        "Admin clone разделяет inode с локальным origin")
}

@Test func exactDigestОтклоняетИзменённыеTrackedБайты() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    _ = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)
    let readme = фикстура.корень
        .appendingPathComponent("Зависимости/LinguisticKit/README.md")
    try Data("tampered\n".utf8).write(to: readme)
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.проверитьПослеПрименения(
            план: план, квитанция: квитанция)
    }
}

@Test func exactDigestОтклоняетИзменённыйИндекс() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    _ = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)
    try Data().write(
        to: URL(fileURLWithPath: план.adminGitDir, isDirectory: true)
            .appendingPathComponent("index"))
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.проверитьПослеПрименения(
            план: план, квитанция: квитанция)
    }
}

@Test func mutationПослеDurableCallbackНеДаётГотовыйOutcome() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    let readme = фикстура.корень
        .appendingPathComponent("Зависимости/LinguisticKit/README.md")
    var ошибкаCallback: Error?
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план,
            квитанция: квитанция,
            наблюдатель: { этап in
                guard этап == .материализацияСинхронизирована else { return }
                do {
                    try Data("callback-tamper\n".utf8).write(to: readme)
                } catch {
                    ошибкаCallback = error
                }
            })
    }
    try ожидать(ошибкаCallback == nil, "Callback-фикстура не смогла изменить tracked файл")
    let итоговоеСостояние = try состояниеOutcome(квитанция)
    try ожидать(
        итоговоеСостояние == .намерение,
        "Mutation после durable callback не должна подтверждать готовый outcome")
}

@Test func mutationМеждуFsyncИPostDigestНеДаётГотовыйOutcome() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    let readme = фикстура.корень
        .appendingPathComponent("Зависимости/LinguisticKit/README.md")
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план,
            квитанция: квитанция,
            наблюдатель: { _ in },
            послеFsyncПередDigest: {
                try Data("post-fsync-tamper\n".utf8).write(to: readme)
            })
    }
    let итоговоеСостояние = try состояниеOutcome(квитанция)
    try ожидать(
        итоговоеСостояние == .намерение,
        "Mutation между fsync и post-digest не должна подтверждать готовый outcome")
}

@Test func толькоКаноническийOutcomeПоддерживаетApplyИReadback() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let каталог = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap", isDirectory: true)
    let неканонический = каталог.appendingPathComponent("other.json")
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план, квитанция: неканонический)
    }
    try ожидать(
        !FileManager.default.fileExists(atPath: неканонический.path),
        "Неканонический outcome не должен создаваться")
    let канонический = каталог.appendingPathComponent("outcome.json")
    _ = try BootstrapЗависимости.применить(
        план: план, квитанция: канонический)
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.проверитьПослеПрименения(
            план: план, квитанция: неканонический)
    }
}

@Test func гонкаЗаменыРодителяЗависимостиНеВыводитGitЭффектНаружу() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let fm = FileManager.default
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    let зависимости = фикстура.корень.appendingPathComponent("Зависимости", isDirectory: true)
    let удержанный = фикстура.корень.appendingPathComponent("Зависимости-held", isDirectory: true)
    let внешний = фикстура.временныйКорень.appendingPathComponent("outside-dependency", isDirectory: true)
    try fm.createDirectory(at: внешний, withIntermediateDirectories: false)

    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план,
            квитанция: квитанция,
            наблюдатель: { _ in },
            передGitЭффектом: {
                try fm.moveItem(at: зависимости, to: удержанный)
                try fm.createSymbolicLink(
                    atPath: зависимости.path, withDestinationPath: внешний.path)
            })
    }
    let внешнееСодержимое = try fm.contentsOfDirectory(atPath: внешний.path)
    let итоговоеСостояние = try состояниеOutcome(квитанция)
    try ожидать(
        внешнееСодержимое.isEmpty,
        "Гонка родителя зависимости оставила Git-эффект снаружи")
    try ожидать(
        итоговоеСостояние != .готова,
        "Outcome гонки родителя зависимости ошибочно готов")
}

@Test func гонкаЗаменыРодителяBootstrapНеВыводитGitЭффектНаружу() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let fm = FileManager.default
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    let каталог = квитанция.deletingLastPathComponent()
    let удержанный = каталог.deletingLastPathComponent()
        .appendingPathComponent("dependency-bootstrap-held", isDirectory: true)
    let внешний = фикстура.временныйКорень.appendingPathComponent("outside-bootstrap", isDirectory: true)
    try fm.createDirectory(at: внешний, withIntermediateDirectories: false)

    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план,
            квитанция: квитанция,
            наблюдатель: { _ in },
            передGitЭффектом: {
                try fm.moveItem(at: каталог, to: удержанный)
                try fm.createSymbolicLink(atPath: каталог.path, withDestinationPath: внешний.path)
            })
    }
    let внешнееСодержимое = try fm.contentsOfDirectory(atPath: внешний.path)
    let удержанныйOutcome = удержанный.appendingPathComponent("outcome.json")
    let итоговоеСостояние = try состояниеOutcome(удержанныйOutcome)
    try ожидать(
        внешнееСодержимое.isEmpty,
        "Гонка родителя bootstrap оставила Git-эффект снаружи")
    try ожидать(
        итоговоеСостояние == .намерение,
        "При неизвестном исходе гонки исходный intent должен сохраниться")
}

@Test func гонкаЗаменыПроверенногоGitdirНеДаётГотовыйOutcome() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let fm = FileManager.default
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    let имяAdmin = URL(fileURLWithPath: план.adminGitDir).lastPathComponent
    let staging = квитанция.deletingLastPathComponent()
        .appendingPathComponent(".staging-\(имяAdmin)", isDirectory: true)

    try ожидатьОтказ {
        _ = try BootstrapЗависимости.применить(
            план: план,
            квитанция: квитанция,
            наблюдатель: { _ in },
            передРазделениемGit: {
                let dotGit = staging.appendingPathComponent(".git", isDirectory: true)
                let исходный = staging.appendingPathComponent(".git-original", isDirectory: true)
                try fm.moveItem(at: dotGit, to: исходный)
                try fm.copyItem(at: исходный, to: dotGit)
            })
    }
    let итоговоеСостояние = try состояниеOutcome(квитанция)
    try ожидать(
        итоговоеСостояние == .намерение,
        "Подмена уже проверенного .git не должна подтверждать готовый outcome")
}

@Test func дрейфМанифестаОтклоняется() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let modules = фикстура.корень.appendingPathComponent(".gitmodules")
    var данные = try Data(contentsOf: modules)
    данные.append(Data("# drift\n".utf8))
    try данные.write(to: modules)
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.построитьПлан(
            корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    }
}

@Test func symlinkЗависимостиОтклоняется() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let зависимость = фикстура.корень.appendingPathComponent("Зависимости/LinguisticKit")
    if FileManager.default.fileExists(atPath: зависимость.path) {
        try FileManager.default.removeItem(at: зависимость)
    }
    try FileManager.default.createSymbolicLink(
        atPath: зависимость.path, withDestinationPath: фикстура.origin.path)
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.построитьПлан(
            корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    }
}

@Test func symlinkРодителяBootstrapНеВыводитЗаписьНаружу() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let внешний = фикстура.временныйКорень.appendingPathComponent("outside", isDirectory: true)
    try FileManager.default.createDirectory(at: внешний, withIntermediateDirectories: false)
    let каталогBootstrap = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap", isDirectory: true)
    try FileManager.default.createSymbolicLink(
        atPath: каталогBootstrap.path, withDestinationPath: внешний.path)
    let планURL = каталогBootstrap.appendingPathComponent("plan.json")
    try ожидатьОтказ {
        try BootstrapЗависимости.записатьПлан(план, в: планURL)
    }
    try ожидать(
        !FileManager.default.fileExists(atPath: внешний.appendingPathComponent("plan.json").path),
        "Отказ не должен оставлять файл за физической границей")
}

@Test func публичныйРежимКаталогаBootstrapОтклоняется() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let каталогBootstrap = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap", isDirectory: true)
    try FileManager.default.createDirectory(at: каталогBootstrap, withIntermediateDirectories: false)
    try ожидать(chmod(каталогBootstrap.path, 0o755) == 0, "Не удалось задать mode фикстуры")
    try ожидатьОтказ {
        try BootstrapЗависимости.записатьПлан(
            план, в: каталогBootstrap.appendingPathComponent("plan.json"))
    }
}

@Test func планЗаписываетсяИЧитаетсяКакПриватныйФайл() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let путьПлана = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/plan.json")
    try BootstrapЗависимости.записатьПлан(план, в: путьПлана)
    var сведения = stat()
    try ожидать(
        lstat(путьПлана.path, &сведения) == 0
            && (сведения.st_mode & 0o777) == 0o600
            && сведения.st_uid == geteuid()
            && сведения.st_nlink == 1,
        "План должен быть приватным single-link файлом владельца")
    let прочитанныйПлан = try BootstrapЗависимости.прочитатьПлан(путьПлана)
    try ожидать(прочитанныйПлан == план, "Приватный readback плана не совпал с записью")
}

@Test func чужойВладелецПриватногоФайлаОтклоняется() throws {
    var сведения = stat()
    сведения.st_mode = mode_t(S_IFREG) | mode_t(0o600)
    сведения.st_uid = geteuid() &+ 1
    сведения.st_nlink = 1
    try ожидатьОтказ {
        try ПроверкаПриватногоУзла.файл(сведения)
    }
}

@Test func hardlinkOutcomeОтклоняетсяReadback() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    _ = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)
    let дополнительнаяСсылка = квитанция.deletingLastPathComponent()
        .appendingPathComponent("outcome-hardlink.json")
    try ожидать(
        link(квитанция.path, дополнительнаяСсылка.path) == 0,
        "Не удалось создать hardlink-фикстуру")
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.проверитьПослеПрименения(
            план: план, квитанция: квитанция)
    }
}

@Test func публичныйРежимOutcomeОтклоняетсяReadback() throws {
    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let квитанция = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap/outcome.json")
    _ = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)
    try ожидать(chmod(квитанция.path, 0o644) == 0, "Не удалось изменить mode фикстуры")
    try ожидатьОтказ {
        _ = try BootstrapЗависимости.проверитьПослеПрименения(
            план: план, квитанция: квитанция)
    }
}

@Test func bootstrapЗапускаетсяПриЧастичноМатериализованномSubmodule() throws {
    let fm = FileManager.default
    let файлТеста = URL(fileURLWithPath: #filePath)
    let кореньИсходников = файлТеста.deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let вложенныйManifest = файлТеста.deletingLastPathComponent().appendingPathComponent("Package.swift")
    let использоватьВложенный = fm.fileExists(atPath: вложенныйManifest.path)
    let manifestИсточник = использоватьВложенный
        ? вложенныйManifest : кореньИсходников.appendingPathComponent("Package.swift")

    let фикстура = try ФикстураBootstrap()
    defer { фикстура.удалить() }
    let план = try BootstrapЗависимости.построитьПлан(
        корень: фикстура.корень, путь: "Зависимости/LinguisticKit")
    let приватныйКаталог = URL(fileURLWithPath: план.gitDir, isDirectory: true)
        .appendingPathComponent("dependency-bootstrap", isDirectory: true)
    let путьПлана = приватныйКаталог.appendingPathComponent("plan.json")
    let путьOutcome = приватныйКаталог.appendingPathComponent("outcome.json")
    try BootstrapЗависимости.записатьПлан(план, в: путьПлана)
    let intent = ИсходBootstrapЗависимости(
        схема: "fum.bootstrap-git-zavisimosti-outcome.2",
        хэшПлана: "sha256:" + String(repeating: "0", count: 64),
        состояние: .намерение,
        путь: план.путь,
        gitlinkOID: план.gitlinkOID,
        adminGitDir: план.adminGitDir,
        хэшМатериализации: nil,
        пояснение: nil)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: false)
    try граница.записатьЭксклюзивно(try encoder.encode(intent), имя: "outcome.json")

    let состояния: [(String, String?)] = [
        ("empty", nil),
        ("invalid", "// swift-tools-version: 6.0\nimport PackageDescription\nlet package =\n"),
        ("valid-partial", "// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: \"LinguisticKit\")\n"),
        (
            "valid-missing-path",
            "// swift-tools-version: 6.0\nimport PackageDescription\n"
                + "let package = Package(name: \"LinguisticKit\", "
                + "products: [.library(name: \"LinguisticKit.static\", targets: [\"Missing\"])], "
                + "targets: [.target(name: \"Missing\", path: \"Sources/Missing\")])\n"
        ),
    ]
    for (имяСостояния, содержимоеManifest) in состояния {
        let временный = fm.temporaryDirectory
            .appendingPathComponent("fum-partial-bootstrap-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: временный) }
        let каталогSwift = временный.appendingPathComponent(
            "Инструменты/fum-proverka-git-zavisimostej/swift", isDirectory: true)
        try fm.createDirectory(at: каталогSwift, withIntermediateDirectories: true)
        let пакет = использоватьВложенный ? каталогSwift : временный
        try fm.copyItem(at: manifestИсточник, to: пакет.appendingPathComponent("Package.swift"))
        for имя in [
            "bootstrap-zavisimosti.swift",
            "bezopasnaya-granica-bootstrap.swift",
            "komanda-bootstrap-zavisimosti.swift",
            "proverki-bootstrap-zavisimosti.swift",
        ] {
            try fm.copyItem(
                at: файлТеста.deletingLastPathComponent().appendingPathComponent(имя),
                to: каталогSwift.appendingPathComponent(имя))
        }
        let dependency = временный.appendingPathComponent(
            "Зависимости/LinguisticKit", isDirectory: true)
        try fm.createDirectory(at: dependency, withIntermediateDirectories: true)
        if let содержимоеManifest {
            try Data(содержимоеManifest.utf8).write(
                to: dependency.appendingPathComponent("Package.swift"))
        }

        let процесс = Process()
        let вывод = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        процесс.arguments = [
            "run", "--package-path", пакет.path,
            "--scratch-path", временный.appendingPathComponent(".scratch").path,
            "bootstrap-zavisimosti", "readback",
            "--plan", путьПлана.path,
            "--outcome", путьOutcome.path,
        ]
        процесс.standardOutput = вывод
        процесс.standardError = вывод
        try процесс.run()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        let текст = String(decoding: данные, as: UTF8.self)
        try ожидать(процесс.terminationStatus == 1, "Readback intent должен отказать")
        try ожидать(
            текст.contains("Outcome не подтверждает успешное применение точного плана"),
            "Bootstrap не дошёл до readback CLI для \(имяСостояния): \(текст)")
    }
}
