import Foundation

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

private func проверитьУспешныйЦикл() throws {
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
    let результат = try BootstrapЗависимости.применить(план: план, квитанция: квитанция)
    try ожидать(результат.состояние == .готова, "Apply не завершился готовым состоянием")
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
}

private func проверитьДрейфМанифеста() throws {
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

private func проверитьSymlink() throws {
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

@main
private enum ПроверкиBootstrapЗависимости {
    static func main() throws {
        try проверитьУспешныйЦикл()
        try проверитьДрейфМанифеста()
        try проверитьSymlink()
        print("bootstrap-dependency-tests=ok cases=3")
    }
}
