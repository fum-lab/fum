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

@Test func bootstrapЗапускаетсяПриПустомSubmodule() throws {
    let fm = FileManager.default
    let временный = fm.temporaryDirectory
        .appendingPathComponent("fum-empty-bootstrap-\(UUID().uuidString)", isDirectory: true)
    defer { try? fm.removeItem(at: временный) }
    try fm.createDirectory(at: временный, withIntermediateDirectories: true)
    let файлТеста = URL(fileURLWithPath: #filePath)
    let кореньИсходников = файлТеста.deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    try fm.copyItem(
        at: кореньИсходников.appendingPathComponent("Package.swift"),
        to: временный.appendingPathComponent("Package.swift"))
    let каталогSwift = временный.appendingPathComponent(
        "Инструменты/fum-proverka-git-zavisimostej/swift", isDirectory: true)
    try fm.createDirectory(at: каталогSwift, withIntermediateDirectories: true)
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
    try fm.createDirectory(
        at: временный.appendingPathComponent("Зависимости/LinguisticKit", isDirectory: true),
        withIntermediateDirectories: true)

    let процесс = Process()
    let вывод = Pipe()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    процесс.arguments = [
        "run", "--package-path", временный.path,
        "--scratch-path", временный.appendingPathComponent(".scratch").path,
        "bootstrap-zavisimosti",
    ]
    процесс.standardOutput = вывод
    процесс.standardError = вывод
    try процесс.run()
    let данные = вывод.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    let текст = String(decoding: данные, as: UTF8.self)
    try ожидать(процесс.terminationStatus == 1, "CLI без аргументов должен отказать")
    try ожидать(
        текст.contains("Нужна команда plan, apply или readback"),
        "Bootstrap не дошёл до собственного CLI из пустого submodule: \(текст)")
}
