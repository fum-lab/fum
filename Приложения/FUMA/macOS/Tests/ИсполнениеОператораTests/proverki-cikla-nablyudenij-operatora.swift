import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

@Suite("Операторный цикл наблюдений", .serialized)
struct ПроверкиОператорногоЦикла {
    private func команда(_ бинарник: URL, _ аргументы: [String], каталог: URL) throws -> (Int32, Data, Data) {
        let процесс = Process()
        let идентификатор = UUID().uuidString.lowercased()
        let путьВывода = каталог.appendingPathComponent("вывод-" + идентификатор)
        let путьОшибок = каталог.appendingPathComponent("ошибки-" + идентификатор)
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil,
                attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil,
                attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer {
            try? FileManager.default.removeItem(at: путьВывода)
            try? FileManager.default.removeItem(at: путьОшибок)
        }
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        процесс.executableURL = бинарник
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = каталог
        var окружение = ["PATH": "/usr/bin:/bin", "HOME": каталог.path,
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_AUTHOR_NAME": "FUM Проверка", "GIT_AUTHOR_EMAIL": "fum-test@example.invalid",
            "GIT_COMMITTER_NAME": "FUM Проверка", "GIT_COMMITTER_EMAIL": "fum-test@example.invalid"]
        if let временныйКаталог = ProcessInfo.processInfo.environment["TMPDIR"] {
            окружение["TMPDIR"] = временныйКаталог
        }
        процесс.environment = окружение
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        try процесс.run()
        процесс.waitUntilExit()
        let данные = try Data(contentsOf: путьВывода)
        let диагностика = try Data(contentsOf: путьОшибок)
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
        try #require(команда(git, ["init", "--quiet"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["symbolic-ref", "HEAD", "refs/heads/проверка"], каталог: репозиторий).0 == 0)
        try Data("проверка\n".utf8).write(to: репозиторий.appendingPathComponent("tracked.txt"))
        try #require(команда(git, ["add", "tracked.txt"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "--quiet", "-m", "проверка"], каталог: репозиторий).0 == 0)
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let определение = корень.appendingPathComponent("оператор.json")
        try FileManager.default.copyItem(at: пакет.appendingPathComponent("Операторы/svodka-plana-nablyudenij-sostoyaniya.json"), to: определение)
        let аргументы = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", определение.path, "--журнал", история.path]
        let первый = try команда(бинарник, аргументы, каталог: корень)
        #expect(первый.0 == 0, "\(String(decoding: первый.2, as: UTF8.self))")
        let ответ = try JSONDecoder().decode(ОтветСреза.self, from: первый.1)
        #expect(ответ.схема == "fuma.результат-JSONL.1")
        #expect(ответ.запись.отказ == nil)
        #expect(ответ.запись.рамки.count == 1)
        #expect(ответ.запись.исполненныйПрефикс.строки == 1)
        let рамка = try #require(ответ.запись.рамки.first)
        let наблюдение = try объект(рамка.наблюдение)
        let результат = try #require(наблюдение["результат"] as? [String: Any])
        let значение = try #require(результат["значение"] as? String)
        let сводка = try объект(Data(значение.utf8))
        #expect(сводка["схема"] as? String == "fuma.сводка-плана-наблюдений-состояния.1")
        #expect(сводка["атомарностьМеждуНаблюдениямиГарантирована"] as? Bool == false)
        let сводкаФайлов = try #require(сводка["файловаяСистема"] as? [String: Any])
        #expect(сводкаФайлов["числоЗаписей"] as? Int == 1)
        let сводкаРепозитория = try #require(сводка["репозиторий"] as? [String: Any])
        #expect(сводкаРепозитория["ссылка"] as? String == "refs/heads/проверка")
        #expect(сводкаРепозитория["числоИзменённыхПутей"] as? Int == 0)
        #expect(сводкаРепозитория["числоНеотслеживаемыхПутей"] as? Int == 0)
        #expect(сводкаРепозитория["чист"] as? Bool == true)
        let сегмент = try Сегмент(кореньДанных: история, запись: false, создать: false)
        let план = try #require(сегмент.записи.first { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" })
        let вход = ответ.запись.сыройВход
        #expect(вход.описание.тип == "сырые-байты/вход-оператора")
        let байтыПлана = try сегмент.извлечь(план.описание.идентификатор)
        #expect(try байтыПлана == сегмент.извлечь(вход.описание.идентификатор))
        #expect(план.хэш == вход.хэш)
        #expect(план.размер == вход.размер)
        #expect(ответ.запись.исполненныйПрефикс.байты == байтыПлана.count)
        #expect(ответ.запись.неИсполненныйСуффикс.начало == байтыПлана.count)
        let планОбъект = try объект(байтыПлана)
        let планРепозитория = try #require(планОбъект["репозиторий"] as? [String: Any])
        #expect((сводкаРепозитория["коммит"] as? String) == (планРепозитория["коммит"] as? String))
        сегмент.закрыть()
        try FileManager.default.removeItem(at: определение)
        try Data("изменено\n".utf8).write(to: файлы.appendingPathComponent("пример.txt"))
        try Data("неотслеживаемое\n".utf8).write(to: репозиторий.appendingPathComponent("новое.txt"))
        let повтор = try команда(бинарник, ["--повторить-JSONL", ответ.квитанция.описание.идентификатор, "--журнал", история.path], каталог: корень)
        #expect(повтор.0 == 0, "\(String(decoding: повтор.2, as: UTF8.self))")
        let ответПовтора = try JSONDecoder().decode(ОтветСреза.self, from: повтор.1)
        #expect(ответПовтора.запись == ответ.запись)
        #expect(ответПовтора.квитанция.описание.идентификатор != ответ.квитанция.описание.идентификатор)
        let читатель = try Сегмент(кореньДанных: история, запись: false, создать: false)
        defer { читатель.закрыть() }
        #expect(читатель.записи.filter { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" }.count == 1)
        читатель.закрыть()

        // Определение корректно, но отсутствующее поле вызывает отказ уже после записи плана.
        let историяОтказа = корень.appendingPathComponent("история-отказа")
        try FileManager.default.createDirectory(at: историяОтказа, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let программаОтказа = корень.appendingPathComponent("отказ.json")
        let текстОтказа = #"{"схема":"fum.определение-оператора.1","идентификатор":"отказ-пути","версия":1,"правила":[],"шаги":[{"идентификатор":"нет-поля","оператор":"вычислить-JSON","аргументы":{"граф":{"схема":"fuma.граф-JSON.1","числа":"целые64-без-дробей","переменные":[],"результат":["путь",["переменная","вход"],"отсутствующее-поле"]}}}]}"#
        try Data(текстОтказа.utf8).write(to: программаОтказа)
        let аргументыОтказа = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", программаОтказа.path, "--журнал", историяОтказа.path]
        let частичный = try команда(бинарник, аргументыОтказа, каталог: корень)
        #expect(частичный.0 != 0)
        let частичныйЧитатель = try Сегмент(кореньДанных: историяОтказа, запись: false, создать: false)
        defer { частичныйЧитатель.закрыть() }
        #expect(частичныйЧитатель.записи.filter { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" }.count == 1)
        let частичноеИсполнение = try #require(частичныйЧитатель.записи.first { $0.описание.тип == "исполнение-JSONL" })
        let записьОтказа = try JSONDecoder().decode(ЗаписьСреза.self,
            from: частичныйЧитатель.извлечь(частичноеИсполнение.описание.идентификатор))
        #expect(записьОтказа.отказ?.стадия == "исполнение")
        #expect(записьОтказа.рамки.isEmpty)
    }

    @Test("Допустимая программа запускает реальный selector")
    func допустимыйСелектор() throws {
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
        let git = URL(fileURLWithPath: "/usr/bin/git")
        try #require(команда(git, ["init", "--quiet"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["symbolic-ref", "HEAD", "refs/heads/проверка"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "--allow-empty", "--quiet", "-m", "проверка"], каталог: репозиторий).0 == 0)
        let определение = корень.appendingPathComponent("оператор.json")
        let текст = #"{"схема":"fum.определение-оператора.1","идентификатор":"тождество","версия":1,"правила":[],"шаги":[]}"#
        try Data(текст.utf8).write(to: определение)
        let аргументы = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", определение.path, "--журнал", история.path]
        let исход = try команда(бинарник, аргументы, каталог: корень)
        #expect(исход.0 == 0, "\(String(decoding: исход.2, as: UTF8.self))")
        let ответ = try JSONDecoder().decode(ОтветСреза.self, from: исход.1)
        #expect(ответ.запись.отказ == nil)
        #expect(ответ.запись.рамки.count == 1)
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
        let указатель = try #require(realpath(каталог.path, nil))
        defer { free(указатель) }
        let физический = String(cString: указатель)
        let невернаяПрограмма = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", физический,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", физический,
            "--определение", физический + "/отсутствует.json", "--журнал", физический]
        let отказ = try команда(бинарник, невернаяПрограмма, каталог: каталог)
        #expect(отказ.0 != 0)
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
        let повторныйПараметр = невернаяПрограмма + ["--журнал", физический]
        let смешанныеРежимы = невернаяПрограмма + ["--повторить-JSONL", "неизвестно"]
        for аргументы in [повторныйПараметр, смешанныеРежимы] {
            #expect(try команда(бинарник, аргументы, каталог: каталог).0 != 0)
            #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
        }
        let неверноеОпределение = URL(fileURLWithPath: физический).appendingPathComponent("неверное.json")
        try Data("{неверный JSON".utf8).write(to: неверноеОпределение)
        var неверныйJSON = невернаяПрограмма
        неверныйJSON[неверныйJSON.count - 3] = неверноеОпределение.path
        #expect(try команда(бинарник, неверныйJSON, каталог: каталог).0 != 0)
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
        let валидноеОпределение = URL(fileURLWithPath: физический).appendingPathComponent("валидное.json")
        let валидныйТекст = #"{"схема":"fum.определение-оператора.1","идентификатор":"тождество","версия":1,"правила":[],"шаги":[]}"#
        try Data(валидныйТекст.utf8).write(to: валидноеОпределение)
        var неприватныйЖурнал = неверныйJSON
        неприватныйЖурнал[неприватныйЖурнал.count - 3] = валидноеОпределение.path
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: физический)
        #expect(try команда(бинарник, неприватныйЖурнал, каталог: каталог).0 != 0)
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
    }
}
