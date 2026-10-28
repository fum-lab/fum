import Foundation
import Darwin
import Testing
import ИсполнениеОператора
import НаблюдательРепозитория

@Suite("Наблюдение Git из FUMA")
struct ПроверкаНаблюденияРепозитория {
    @Test("снимок через CLI сохраняет ref, индекс и рабочие файлы; отказы типизированы")
    func снимокИОтказы() throws {
        let временныйПуть = FileManager.default.temporaryDirectory
            .appendingPathComponent("fuma-git-fixture-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: временныйПуть, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let физическийУказатель = try #require(realpath(временныйПуть.path, nil))
        let временная = URL(fileURLWithPath: String(cString: физическийУказатель), isDirectory: true)
        free(физическийУказатель)
        let корень = временная.appendingPathComponent("репозиторий", isDirectory: true)
        let дом = временная.appendingPathComponent("дом", isDirectory: true)
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        try FileManager.default.createDirectory(at: дом, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: временная) }

        try выполнитьКомандуФикстуры(в: корень, дом: дом, ["init", "--quiet", "--initial-branch=main"])
        try Data("основа\n".utf8).write(to: корень.appendingPathComponent("отслеживаемый.txt"))
        try выполнитьКомандуФикстуры(в: корень, дом: дом,
            ["-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "add", "--", "отслеживаемый.txt"])
        try выполнитьКомандуФикстуры(в: корень, дом: дом,
            ["-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--quiet", "-m", "fixture"])
        try Data("изменение\n".utf8).write(to: корень.appendingPathComponent("отслеживаемый.txt"))
        let новыйПуть = корень.appendingPathComponent("вложенный/новый.txt")
        try FileManager.default.createDirectory(at: новыйПуть.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try Data("новый\n".utf8).write(to: новыйПуть)

        let коммитДо = try выполнитьЧтение(в: корень, дом: дом, ["rev-parse", "--verify", "HEAD^{commit}"])
        let ссылкаДо = try выполнитьЧтение(в: корень, дом: дом, ["rev-parse", "--symbolic-full-name", "HEAD"])
        let статусДо = try выполнитьДанныеЧтения(в: корень, дом: дом,
            ["status", "--porcelain=v2", "-z", "--untracked-files=all", "--ignore-submodules=all"])
        let индексДо = try Data(contentsOf: корень.appendingPathComponent(".git/index"))
        let файлСсылкиДо = try Data(contentsOf: корень.appendingPathComponent(".git/refs/heads/main"))
        let отслеживаемыйДо = try Data(contentsOf: корень.appendingPathComponent("отслеживаемый.txt"))
        let новыйДо = try Data(contentsOf: новыйПуть)

        #expect(КомандноеИсполнениеОператора.выбран(аргументы: ["--наблюдать-репозиторий", корень.path]))
        let началоПервогоЧтения = ContinuousClock.now
        let ответ = try КомандноеИсполнениеОператора.выполнить(
            аргументы: ["--наблюдать-репозиторий", корень.path])
        let длительностьПервогоЧтения = началоПервогоЧтения.duration(to: .now)
        let снимок = try JSONDecoder().decode(СнимокРепозитория.self, from: ответ)
        #expect(снимок.схема == "fuma.снимок-репозитория.1")
        #expect(снимок.коммит == коммитДо.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect(снимок.ссылка == ссылкаДо.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect(снимок.изменённыеПути == ["отслеживаемый.txt"])
        #expect(снимок.неотслеживаемыеПути == ["вложенный/новый.txt"])
        let началоПовтора = ContinuousClock.now
        #expect(try КомандноеИсполнениеОператора.выполнить(
            аргументы: ["--наблюдать-репозиторий", корень.path]) == ответ)
        let длительностьПовтора = началоПовтора.duration(to: .now)
        print("Профиль фикстуры, два наблюдения: первое \(длительностьПервогоЧтения), повтор \(длительностьПовтора)")

        #expect(try выполнитьЧтение(в: корень, дом: дом, ["rev-parse", "--verify", "HEAD^{commit}"]) == коммитДо)
        #expect(try выполнитьЧтение(в: корень, дом: дом, ["rev-parse", "--symbolic-full-name", "HEAD"]) == ссылкаДо)
        #expect(try выполнитьДанныеЧтения(в: корень, дом: дом,
            ["status", "--porcelain=v2", "-z", "--untracked-files=all", "--ignore-submodules=all"]) == статусДо)
        #expect(try Data(contentsOf: корень.appendingPathComponent(".git/index")) == индексДо)
        #expect(try Data(contentsOf: корень.appendingPathComponent(".git/refs/heads/main")) == файлСсылкиДо)
        #expect(try Data(contentsOf: корень.appendingPathComponent("отслеживаемый.txt")) == отслеживаемыйДо)
        #expect(try Data(contentsOf: новыйПуть) == новыйДо)

        #expect(throws: ОшибкаНаблюдателяРепозитория.аргументы) {
            _ = try КомандноеИсполнениеОператора.выполнить(
                аргументы: ["--наблюдать-репозиторий", корень.path, "--commit", "HEAD"])
        }
        #expect(throws: ОшибкаНаблюдателяРепозитория.неРепозиторий) {
            _ = try НаблюдательРепозитория.наблюдать(корень: дом)
        }
    }

    private func выполнитьКомандуФикстуры(в корень: URL, дом: URL, _ аргументы: [String]) throws {
        _ = try выполнитьДанныеЧтения(в: корень, дом: дом, аргументы)
    }

    private func выполнитьЧтение(в корень: URL, дом: URL, _ аргументы: [String]) throws -> String {
        let данные = try выполнитьДанныеЧтения(в: корень, дом: дом, аргументы)
        guard let строка = String(data: данные, encoding: .utf8) else {
            throw ОшибкаНаблюдателяРепозитория.кодировка
        }
        return строка
    }

    private func выполнитьДанныеЧтения(в корень: URL, дом: URL, _ аргументы: [String]) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["-C", корень.path] + аргументы
        процесс.environment = [
            "HOME": дом.path,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_OPTIONAL_LOCKS": "0",
            "GIT_TERMINAL_PROMPT": "0"
        ]
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = канал
        try процесс.run()
        let данные = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else {
            throw ОшибкаНаблюдателяРепозитория.отказСистемнойКоманды
        }
        return данные
    }
}
