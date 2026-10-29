import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений

@Suite("Операторный цикл наблюдений", .serialized)
struct ПроверкиОператорногоЦикла {
    private func команда(_ бинарник: URL, _ аргументы: [String], каталог: URL) throws -> (Int32, Data, Data) {
        let процесс = Process()
        let вывод = Pipe()
        let ошибки = Pipe()
        процесс.executableURL = бинарник
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = каталог
        процесс.environment = ["PATH": "/usr/bin:/bin", "HOME": каталог.path,
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_AUTHOR_NAME": "FUM Проверка", "GIT_AUTHOR_EMAIL": "fum-test@example.invalid",
            "GIT_COMMITTER_NAME": "FUM Проверка", "GIT_COMMITTER_EMAIL": "fum-test@example.invalid"]
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        try процесс.run()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        return (процесс.terminationStatus, данные, диагностика)
    }

    private func объект(_ данные: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
    }

    @Test("План исполняется и повторяется из нативной истории")
    func исполнениеИПовтор() throws {
        let бинарник = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["ФУМА_КОМАНДА_ОПЕРАТОРА"]))
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let указатель = try #require(realpath(временный.path, nil))
        defer { free(указатель); try? FileManager.default.removeItem(at: временный) }
        let корень = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
        let файлы = корень.appendingPathComponent("файлы")
        let репозиторий = корень.appendingPathComponent("репозиторий")
        let история = корень.appendingPathComponent("история")
        for каталог in [файлы, репозиторий, история] {
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        try Data("состояние\n".utf8).write(to: файлы.appendingPathComponent("пример.txt"))
        let git = URL(fileURLWithPath: "/usr/bin/git")
        #expect(try команда(git, ["init", "--quiet"], каталог: репозиторий).0 == 0)
        #expect(try команда(git, ["symbolic-ref", "HEAD", "refs/heads/проверка"], каталог: репозиторий).0 == 0)
        try Data("проверка\n".utf8).write(to: репозиторий.appendingPathComponent("tracked.txt"))
        #expect(try команда(git, ["add", "tracked.txt"], каталог: репозиторий).0 == 0)
        #expect(try команда(git, ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "--quiet", "-m", "проверка"], каталог: репозиторий).0 == 0)
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let определение = корень.appendingPathComponent("оператор.json")
        try FileManager.default.copyItem(at: пакет.appendingPathComponent("Операторы/svodka-plana-nablyudenij-sostoyaniya.json"), to: определение)
        let аргументы = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", определение.path, "--журнал", история.path]
        let первый = try команда(бинарник, аргументы, каталог: корень)
        #expect(первый.0 == 0, "\(String(decoding: первый.2, as: UTF8.self))")
        let ответ = try объект(первый.1)
        let квитанция = try #require(ответ["квитанция"] as? [String: Any])
        let описание = try #require(квитанция["описание"] as? [String: Any])
        let идентификатор = try #require(описание["идентификатор"] as? String)
        let запись = try #require(ответ["запись"] as? [String: Any])
        #expect(запись["отказ"] == nil)
        let сегмент = try Сегмент(кореньДанных: история, запись: false, создать: false)
        let план = try #require(сегмент.записи.first { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" })
        let вход = try #require(сегмент.записи.first { $0.описание.тип == "сырые-байты/вход-оператора" })
        #expect(try сегмент.извлечь(план.описание.идентификатор) == сегмент.извлечь(вход.описание.идентификатор))
        #expect(план.хэш == вход.хэш)
        #expect(план.размер == вход.размер)
        сегмент.закрыть()
        try FileManager.default.removeItem(at: определение)
        let повтор = try команда(бинарник, ["--повторить-JSONL", идентификатор, "--журнал", история.path], каталог: корень)
        #expect(повтор.0 == 0, "\(String(decoding: повтор.2, as: UTF8.self))")
        let ответПовтора = try объект(повтор.1)
        #expect((ответПовтора["запись"] as? NSDictionary) == (запись as NSDictionary))
        let читатель = try Сегмент(кореньДанных: история, запись: false, создать: false)
        defer { читатель.закрыть() }
        #expect(читатель.записи.filter { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" }.count == 1)
    }

    @Test("Неверные аргументы не создают историю")
    func отказДоНаблюдения() throws {
        let бинарник = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["ФУМА_КОМАНДА_ОПЕРАТОРА"]))
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: каталог) }
        let результат = try команда(бинарник, ["--исполнить-цикл-наблюдений", "--журнал", каталог.path], каталог: каталог)
        #expect(результат.0 != 0)
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
    }
}
