import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

// Рецепт из корня Git FUM; все package-зависимости — локальные пути того же коммита.
// Сначала зафиксировать `git rev-parse HEAD` и версию `swift --version`.
// SCRATCH — существующий приватный каталог вне checkout, объём которого ограничен.
// swift build --package-path Приложения/FUMA/macOS --scratch-path "$SCRATCH" --jobs 1 --product fum-оператор -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors -Xswiftc -enable-actor-data-race-checks
// env 'ФУМА_ПРОВЕРКА_ОПЕРАТОРА=1' "ФУМА_КОМАНДА_ОПЕРАТОРА=$SCRATCH/debug/fum-оператор" swift test --package-path Приложения/FUMA/macOS --scratch-path "$SCRATCH" --jobs 1 --disable-xctest --enable-swift-testing --filter ПроверкиОператорногоЦикла -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors -Xswiftc -enable-actor-data-race-checks
// Фикстура создаёт временные FS, Git с refs/heads/проверка и внешний 0700 Segment.
// Ожидаются одна завершённая рамка и сводка Git без учёта подмодулей; replay читает сохранённый вход,
// даже если FS/Git изменены. Отказ графа после цикла оставляет план и отказ исполнения.

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
        #expect(сводкаРепозитория["чистБезУчётаПодмодулей"] as? Bool == true)
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
        #expect((сводка["схемаПлана"] as? String) == (планОбъект["схема"] as? String))
        #expect((сводка["порядок"] as? [String]) == ["файловая-система", "репозиторий"])
        let планФайлов = try #require(планОбъект["файловаяСистема"] as? [String: Any])
        #expect((сводкаФайлов["идентификатор"] as? String) == (планФайлов["идентификатор"] as? String))
        #expect((сводкаФайлов["источник"] as? String) == "проверка")
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
        let ответОтказа = try JSONDecoder().decode(ОтветСреза.self, from: частичный.1)
        #expect(ответОтказа.квитанция == частичноеИсполнение)
        #expect(ответОтказа.запись == записьОтказа)
        #expect(записьОтказа.отказ?.стадия == "исполнение")
        #expect(записьОтказа.рамки.isEmpty)
        let планОтказа = try #require(частичныйЧитатель.записи.first { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" })
        let сыройОтказ = записьОтказа.сыройВход
        #expect(планОтказа.хэш == сыройОтказ.хэш)
        #expect(планОтказа.размер == сыройОтказ.размер)
        #expect(try частичныйЧитатель.извлечь(планОтказа.описание.идентификатор) == частичныйЧитатель.извлечь(сыройОтказ.описание.идентификатор))
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
        let корень = URL(fileURLWithPath: физический, isDirectory: true)
        let файлы = корень.appendingPathComponent("файлы")
        let репозиторий = корень.appendingPathComponent("репозиторий")
        let история = корень.appendingPathComponent("история")
        for путь in [файлы, репозиторий, история] {
            try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        let git = URL(fileURLWithPath: "/usr/bin/git")
        try #require(команда(git, ["init", "--quiet"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["symbolic-ref", "HEAD", "refs/heads/проверка"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "--allow-empty", "--quiet", "-m", "проверка"], каталог: репозиторий).0 == 0)
        let файлСегмента = история.appendingPathComponent("сегмент.fumobs")
        let невернаяПрограмма = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", физический + "/отсутствует.json", "--журнал", история.path]
        let отказ = try команда(бинарник, невернаяПрограмма, каталог: каталог)
        #expect(отказ.0 != 0)
        #expect(!FileManager.default.fileExists(atPath: файлСегмента.path))
        let валидноеОпределение = URL(fileURLWithPath: физический).appendingPathComponent("валидное.json")
        let валидныйТекст = #"{"схема":"fum.определение-оператора.1","идентификатор":"тождество","версия":1,"правила":[],"шаги":[]}"#
        try Data(валидныйТекст.utf8).write(to: валидноеОпределение)
        var допустимыеАргументы = невернаяПрограмма
        допустимыеАргументы[допустимыеАргументы.count - 3] = валидноеОпределение.path
        let повторныйПараметр = допустимыеАргументы + ["--журнал", история.path]
        let смешанныеРежимы = допустимыеАргументы + ["--повторить-JSONL", "неизвестно"]
        for аргументы in [повторныйПараметр, смешанныеРежимы] {
            #expect(try команда(бинарник, аргументы, каталог: каталог).0 != 0)
            #expect(!FileManager.default.fileExists(atPath: файлСегмента.path))
        }
        let неверноеОпределение = URL(fileURLWithPath: физический).appendingPathComponent("неверное.json")
        try Data("{неверный JSON".utf8).write(to: неверноеОпределение)
        var неверныйJSON = невернаяПрограмма
        неверныйJSON[неверныйJSON.count - 3] = неверноеОпределение.path
        #expect(try команда(бинарник, неверныйJSON, каталог: каталог).0 != 0)
        #expect(!FileManager.default.fileExists(atPath: файлСегмента.path))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: история.path)
        #expect(try команда(бинарник, допустимыеАргументы, каталог: каталог).0 != 0)
        #expect(!FileManager.default.fileExists(atPath: файлСегмента.path))
    }

    @Test("История не размещается в отдельном Git-каталоге")
    func отказИсторииВМетаданныхGit() throws {
        let бинарник = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["ФУМА_КОМАНДА_ОПЕРАТОРА"]))
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let указатель = try #require(realpath(временный.path, nil))
        defer { free(указатель); try? FileManager.default.removeItem(at: временный) }
        let корень = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
        let файлы = корень.appendingPathComponent("файлы")
        let репозиторий = корень.appendingPathComponent("репозиторий")
        let метаданные = корень.appendingPathComponent("метаданные")
        for каталог in [файлы, репозиторий] {
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        let git = URL(fileURLWithPath: "/usr/bin/git")
        try #require(команда(git, ["init", "--quiet", "--separate-git-dir", метаданные.path], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["symbolic-ref", "HEAD", "refs/heads/проверка"], каталог: репозиторий).0 == 0)
        try #require(команда(git, ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "--allow-empty", "--quiet", "-m", "проверка"], каталог: репозиторий).0 == 0)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: метаданные.path)
        let определение = корень.appendingPathComponent("оператор.json")
        let текст = #"{"схема":"fum.определение-оператора.1","идентификатор":"тождество","версия":1,"правила":[],"шаги":[]}"#
        try Data(текст.utf8).write(to: определение)
        let аргументы = ["--исполнить-цикл-наблюдений", "--корень-файловой-системы", файлы.path,
            "--источник-файловой-системы", "проверка", "--корень-репозитория", репозиторий.path,
            "--определение", определение.path, "--журнал", метаданные.path]
        let отдельнаяИстория = корень.appendingPathComponent("история")
        try FileManager.default.createDirectory(at: отдельнаяИстория, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        var контрольныеАргументы = аргументы
        контрольныеАргументы[контрольныеАргументы.count - 1] = отдельнаяИстория.path
        let контроль = try команда(бинарник, контрольныеАргументы, каталог: корень)
        try #require(контроль.0 == 0, "\(String(decoding: контроль.2, as: UTF8.self))")
        let ответ = try JSONDecoder().decode(ОтветСреза.self, from: контроль.1)
        #expect(ответ.запись.отказ == nil)
        #expect(ответ.запись.рамки.count == 1)
        let читатель = try Сегмент(кореньДанных: отдельнаяИстория, запись: false, создать: false)
        defer { читатель.закрыть() }
        #expect(читатель.записи.filter { $0.описание.тип == "fuma.план-наблюдений-состояния.jsonl.1" }.count == 1)
        читатель.закрыть()
        let исход = try команда(бинарник, аргументы, каталог: корень)
        #expect(исход.0 != 0)
        #expect(String(decoding: исход.2, as: UTF8.self).contains("приватныйКаталог"))
        #expect(!FileManager.default.fileExists(atPath: метаданные.appendingPathComponent("сегмент.fumobs").path))
    }
}
