import Foundation
import Darwin
import Testing
@testable import ПереходВеток

enum ОтказФикстурногоИнструмента: Error {
    case отказ(String)
}
func дождаться(_ процесс: Process) async throws {
    let срок = ContinuousClock.now.advanced(by: .seconds(10))
    while процесс.isRunning && ContinuousClock.now < срок {
        try await Task.sleep(for: .milliseconds(10))
    }
    if процесс.isRunning {
        kill(процесс.processIdentifier, SIGKILL)
        throw ОшибкаПерехода.отказ("срок ожидания отдельного процесса истёк")
    }
}

/// Настоящие локальные refs и bare origin; ответ преобразователя — явная фикстура протокола.
struct Фикстура {
    let каталог: URL
    let дерево: URL
    let сервер: URL
    let выбор: Ресурс
    let задание: ЗаданиеПерехода

    init() throws {
        guard let физический = realpath(FileManager.default.temporaryDirectory.path, nil) else {
            throw ОшибкаПерехода.отказ("не удалось разрешить временный каталог")
        }
        defer { free(физический) }
        let основание = URL(fileURLWithPath: String(cString: физический))
        каталог = основание.appendingPathComponent("fum-transition-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        let дерево = каталог.appendingPathComponent("worktree")
        let сервер = каталог.appendingPathComponent("server.git")
        self.дерево = дерево
        self.сервер = сервер
        let сырьё = каталог.appendingPathComponent("raw")
        try FileManager.default.createDirectory(at: сырьё, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        let команды = try Команды(рабочийКаталог: каталог.path, сырьё: сырьё.path)
        func гит(_ аргументы: [String], вДереве: Bool = false) throws -> String {
            let ответ = try команды.выполнить("/usr/bin/git", (вДереве ? ["-C", дерево.path] : []) + аргументы)
            try требовать(ответ.код == 0, String(decoding: ответ.ошибки, as: UTF8.self))
            return String(decoding: ответ.вывод, as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        _ = try гит(["init", "--bare", сервер.path])
        _ = try гит(["init", "-b", "codex/old", дерево.path])
        _ = try гит(["config", "user.name", "Фикстура перехода"], вДереве: true)
        _ = try гит(["config", "user.email", "fixture@example.invalid"], вДереве: true)
        try Data("исходная строка\n".utf8).write(to: дерево.appendingPathComponent("файл.txt"))
        _ = try гит(["add", "файл.txt"], вДереве: true)
        _ = try гит(["commit", "-m", "Исходное состояние"], вДереве: true)
        let коммит = try гит(["rev-parse", "HEAD"], вДереве: true)
        _ = try гит(["branch", "fum-lab/fum/master"], вДереве: true)
        _ = try гит(["remote", "add", "origin", сервер.path], вДереве: true)
        _ = try гит(["push", "origin", "refs/heads/codex/old", "refs/heads/fum-lab/fum/master"], вДереве: true)
        let владелец = UUID().uuidString.lowercased()
        let нативный = каталог.appendingPathComponent("native.jsonl")
        let мета: [String: Any] = ["type": "session_meta", "payload": ["id": владелец, "cwd": дерево.path]]
        try Файлы.записатьНовый(нативный, JSONSerialization.data(withJSONObject: мета) + Data([10]))
        let преобразователь = каталог.appendingPathComponent("converter")
        try Файлы.записатьНовый(преобразователь, Data("#!/bin/sh\nprintf '[\"fuma\",\"kliyenttelegram\"]\\n'\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: преобразователь.path)
        let источник = каталог.appendingPathComponent("basis.json")
        try Файлы.записатьНовый(источник, Data("явно выбранное основание фикстуры".utf8))
        let корень = ВыбранныйКорень(схема: "fum.выбор-корня-перехода.1", координатор: владелец,
            ветка: "refs/heads/fum-lab/fum/master", коммит: коммит,
            основание: Ресурс(путь: источник.path, хэш: хэш(try Data(contentsOf: источник))))
        let путьВыбора = каталог.appendingPathComponent("root.json")
        let данные = try кодировать(корень)
        try Файлы.записатьНовый(путьВыбора, данные)
        выбор = Ресурс(путь: путьВыбора.path, хэш: хэш(данные))
        задание = ЗаданиеПерехода(схема: "fum.задание-перехода-ветки.1", операция: UUID().uuidString.lowercased(),
            репозиторий: Репозиторий(номерХостинга: 1, полноеИмя: "fum-lab/fum", адресСервера: сервер.path,
                общийКаталогГит: дерево.appendingPathComponent(".git").path),
            владелец: владелец, чат: владелец, исходникДиалога: нативный.path, рабочееДерево: дерево.path,
            прежняяВетка: "refs/heads/codex/old", ожидаемыйКоммит: коммит,
            названияНаправления: ["фума", "клиенттелеграм"],
            исполняемыйГит: Ресурс(путь: "/Library/Developer/CommandLineTools/usr/bin/git",
                хэш: хэш(try Data(contentsOf: URL(fileURLWithPath: "/Library/Developer/CommandLineTools/usr/bin/git")))),
            преобразователь: Ресурс(путь: преобразователь.path, хэш: хэш(try Data(contentsOf: преобразователь))),
            ресурсы: [], каталогПротокола: каталог.appendingPathComponent("operation").path, каталогСырья: сырьё.path)
    }
    func гит(_ аргументы: [String]) throws -> String { try Гит(задание).прочитать(аргументы) }
    func план() throws -> План { try Планировщик.построить(задание, выбор: выбор) }
    func выполнить(_ план: План, остановка: String? = nil, сверка: Bool = false,
                   режим: String? = nil) async throws -> РезультатПерехода {
        let действие = режим ?? (сверка ? "сверить" : "переименовать")
        let данные = try await ответ(план, окно: остановка.map { "ошибка:" + $0 } ?? "без-остановки", действие: действие)
        return try декодировать(РезультатПерехода.self, данные)
    }
    func подготовить(_ план: План) async throws {
        let данные = try await ответ(план, окно: "без-остановки", действие: "подготовить-протокол")
        let запись = try декодировать([String: String].self, данные)
        try требовать(запись == ["схема": "fum.подготовка-фикстурного-протокола.1", "состояние": "готов"],
                       "неверный ответ подготовки фикстуры")
    }
    func ответ(_ план: План, окно: String, действие: String) async throws -> Data {
        let номер = UUID().uuidString.lowercased()
        let выход = каталог.appendingPathComponent(номер + "-reply.json")
        let ошибки = каталог.appendingPathComponent(номер + "-error.json")
        let процесс = try процесс(план, окно: окно, действие: действие, выход: выход, ошибки: ошибки)
        defer {
            try? (процесс.standardOutput as? FileHandle)?.close()
            try? (процесс.standardError as? FileHandle)?.close()
        }
        try await дождаться(процесс)
        let данные = try Data(contentsOf: выход)
        if процесс.terminationReason == .exit && процесс.terminationStatus == 0 { return данные }
        let отказ = try? декодировать([String: String].self, Data(contentsOf: ошибки))
        if процесс.terminationReason == .exit && процесс.terminationStatus == 2 &&
            отказ?["схема"] == "fum.ошибка-фикстурного-исполнителя.1", let сообщение = отказ?["сообщение"] {
            throw ОтказФикстурногоИнструмента.отказ(сообщение)
        }
        throw ОшибкаПерехода.отказ("авария процесса или нарушение транспорта; это не предметный отказ")
    }
    func процесс(_ план: План, окно: String, действие: String = "переименовать",
                 выход: URL? = nil, ошибки: URL? = nil, неисправность: String? = nil) throws -> Process {
        let номер = UUID().uuidString.lowercased()
        let вход = каталог.appendingPathComponent(номер + "-plan.json")
        let ресурс = каталог.appendingPathComponent(номер + "-resource.json")
        try Файлы.записатьНовый(вход, план.байты())
        if неисправность == "json" { try Data("{".utf8).write(to: вход) }
        try Файлы.записатьНовый(ресурс, кодировать(выбор))
        guard let исполняемый = ProcessInfo.processInfo.environment["ФУМ_ИСПОЛНИТЕЛЬ_ФИКСТУРЫ"] else {
            throw ОшибкаПерехода.отказ("для process-fixture требуется ФУМ_ИСПОЛНИТЕЛЬ_ФИКСТУРЫ; команда в SKILL.md")
        }
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: исполняемый)
        процесс.arguments = [вход.path, ресурс.path, окно, каталог.appendingPathComponent("stopped").path, действие]
        if неисправность == "argv" { процесс.arguments?.append("лишний") }
        var среда = ProcessInfo.processInfo.environment
        среда["CODEX_THREAD_ID"] = задание.владелец
        процесс.environment = среда
        if let выход {
            try Файлы.записатьНовый(выход, Data())
            процесс.standardOutput = try FileHandle(forWritingTo: выход)
        } else { процесс.standardOutput = FileHandle.nullDevice }
        if let ошибки {
            try Файлы.записатьНовый(ошибки, Data())
            процесс.standardError = try FileHandle(forWritingTo: ошибки)
        } else { процесс.standardError = FileHandle.nullDevice }
        try процесс.run()
        return процесс
    }
    func настоящийКлиБезВладельца(_ план: План, ошибки: URL) throws -> Process {
        guard let исполнитель = ProcessInfo.processInfo.environment["ФУМ_ИСПОЛНИТЕЛЬ_ФИКСТУРЫ"] else {
            throw ОшибкаПерехода.отказ("нет адреса фикстурного исполнителя")
        }
        let вход = каталог.appendingPathComponent(UUID().uuidString.lowercased() + "-cli-plan.json")
        try Файлы.записатьНовый(вход, план.байты())
        try Файлы.записатьНовый(ошибки, Data())
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: исполнитель).deletingLastPathComponent().appendingPathComponent("переход-веток")
        процесс.arguments = ["переименовать", "--план", вход.path, "--хэш-плана", try план.отпечаток(),
                            "--выбор-корня", выбор.путь, "--хэш-выбора", выбор.хэш]
        var среда = ProcessInfo.processInfo.environment
        среда.removeValue(forKey: "CODEX_THREAD_ID")
        процесс.environment = среда
        процесс.standardOutput = FileHandle.nullDevice
        процесс.standardError = try FileHandle(forWritingTo: ошибки)
        try процесс.run()
        return процесс
    }
}

@Suite(.serialized) struct ПроверкиНастоящегоГит {
    @Test func синтетическийВладелецНезависимОтСредыРодителя() async throws {
        let исходнаяСреда = ProcessInfo.processInfo.environment["CODEX_THREAD_ID"]
        let ф = try Фикстура(); let п = try ф.план()
        #expect(ф.задание.владелец != исходнаяСреда)
        _ = try await ф.выполнить(п)
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.новаяВетка)
        #expect(ProcessInfo.processInfo.environment["CODEX_THREAD_ID"] == исходнаяСреда)
    }
    @Test func настоящийКлиБезИдентификатораОтказываетДоЭффекта() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        let индекс = try ф.гит(["rev-parse", "--path-format=absolute", "--git-path", "index"])
        let до = try Data(contentsOf: URL(fileURLWithPath: индекс))
        let ошибки = ф.каталог.appendingPathComponent("production-cli-error.txt")
        let процесс = try ф.настоящийКлиБезВладельца(п, ошибки: ошибки)
        defer { try? (процесс.standardError as? FileHandle)?.close() }
        try await дождаться(процесс)
        #expect(процесс.terminationReason == .exit && процесс.terminationStatus == 2)
        #expect(String(decoding: try Data(contentsOf: ошибки), as: UTF8.self).contains("чужой UUID среды"))
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
        #expect(try ф.гит(["rev-parse", "HEAD"]) == п.задание.ожидаемыйКоммит)
        #expect(try Data(contentsOf: URL(fileURLWithPath: индекс)) == до)
        #expect(!FileManager.default.fileExists(atPath: п.задание.каталогПротокола))
        #expect(!FileManager.default.fileExists(atPath: ф.дерево.appendingPathComponent(".git/fum-perekhod-vetok.lock").path))
    }
    @Test(arguments: ["argv", "json"])
    func неисправностьТранспортаНеВыдаётсяЗаОтказИнструмента(_ вид: String) async throws {
        let ф = try Фикстура(); let п = try ф.план()
        let ошибки = ф.каталог.appendingPathComponent("transport-error.json")
        let процесс = try ф.процесс(п, окно: "без-остановки", ошибки: ошибки, неисправность: вид)
        defer { try? (процесс.standardError as? FileHandle)?.close() }
        try await дождаться(процесс)
        #expect(процесс.terminationReason == .exit && процесс.terminationStatus == 3)
        let запись = try декодировать([String: String].self, Data(contentsOf: ошибки))
        #expect(запись["схема"] == "fum.ошибка-транспорта-фикстуры.1")
        #expect(!FileManager.default.fileExists(atPath: п.задание.каталогПротокола))
        #expect(!FileManager.default.fileExists(atPath: ф.дерево.appendingPathComponent(".git/fum-perekhod-vetok.lock").path))
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
    }
    @Test func планНеМеняетГитАПовторНеПовторяетПереименование() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == ф.задание.прежняяВетка)
        let первый = try await ф.выполнить(п)
        #expect(первый.фаза == "локальная-ветка-переименована")
        #expect(первый.кореньВключён && !первый.слияниеПодготовлено)
        let журнал = try ф.гит(["reflog", "show", "--format=%H %gs", п.новаяВетка])
        _ = try await ф.выполнить(п)
        #expect(try ф.гит(["reflog", "show", "--format=%H %gs", п.новаяВетка]) == журнал)
        #expect(try ф.гит(["ls-remote", "--refs", "origin", ф.задание.прежняяВетка]).hasPrefix(п.задание.ожидаемыйКоммит))
        #expect(try ф.гит(["ls-remote", "--refs", "origin", п.новаяВетка]).isEmpty)
    }
    @Test(arguments: ["01-переименование:после-намерения", "01-переименование:после-команды"])
    func прерываниеИПродолжение(_ остановка: String) async throws {
        let ф = try Фикстура(); let п = try ф.план()
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п, остановка: остановка) }
        _ = try await ф.выполнить(п)
        let строки = try ф.гит(["reflog", "show", "--format=%gs", п.новаяВетка]).components(separatedBy: "\n")
        #expect(строки.filter { $0.contains("Branch: renamed") }.count == 1)
    }
    @Test func сверкаРазличаетСостояниеДоИПослеЭффекта() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        #expect(try await ф.выполнить(п, сверка: true).фаза == "до-переименования")
        #expect(!FileManager.default.fileExists(atPath: п.задание.каталогПротокола))
        #expect(!FileManager.default.fileExists(atPath: ф.дерево.appendingPathComponent(".git/fum-perekhod-vetok.lock").path))
        _ = try await ф.выполнить(п)
        #expect(try await ф.выполнить(п, сверка: true).фаза == "локальная-ветка-переименована")
    }
    @Test func переданныйНоНеВыполненныйЭффектНеПовторяется() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        try await ф.подготовить(п)
        for (вид, схема) in [("намерение", "fum.намерение-перехода.1"), ("передача", "fum.передача-эффекта.1")] {
            let путь = URL(fileURLWithPath: п.задание.каталогПротокола).appendingPathComponent("01-переименование-" + вид + ".json")
            try Файлы.записатьНовый(путь, кодировать(СохранённыйИсход(схема: схема, фаза: "01-переименование",
                хэшПлана: п.отпечаток(), код: 0, объект: п.задание.ожидаемыйКоммит, пояснение: "фикстура unknown outcome")))
        }
        #expect(try await ф.выполнить(п, сверка: true).фаза == "неизвестный-исход")
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
    }
    @Test func дрейфУдалённойСтаройВеткиОтказываетДоПереименования() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        // Удаление только локальной одноразовой bare-фикстуры моделирует внешний дрейф.
        let команды = try Команды(рабочийКаталог: ф.сервер.path, сырьё: п.задание.каталогСырья)
        let ответ = try команды.выполнить("/usr/bin/git", ["update-ref", "-d", п.задание.прежняяВетка])
        #expect(ответ.код == 0)
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
    }
    @Test(arguments: ["01-переименование:после-намерения", "01-переименование:после-команды"])
    func настоящийСбойИПовторВДругомПроцессе(_ окно: String) async throws {
        let ф = try Фикстура(); let п = try ф.план()
        let процесс = try ф.процесс(п, окно: окно)
        let срок = ContinuousClock.now.advanced(by: .seconds(10))
        let маркер = ф.каталог.appendingPathComponent("stopped")
        while !FileManager.default.fileExists(atPath: маркер.path) && процесс.isRunning && ContinuousClock.now < срок {
            try await Task.sleep(for: .milliseconds(10))
        }
        let остановлен = FileManager.default.fileExists(atPath: маркер.path)
        #expect(остановлен)
        kill(процесс.processIdentifier, SIGKILL)
        try await дождаться(процесс)
        #expect(процесс.terminationReason == .uncaughtSignal)
        let повтор = try ф.процесс(п, окно: "без-остановки")
        try await дождаться(повтор)
        #expect(повтор.terminationStatus == 0)
        #expect(повтор.processIdentifier != процесс.processIdentifier)
        let строки = try ф.гит(["reflog", "show", "--format=%gs", п.новаяВетка]).components(separatedBy: "\n")
        #expect(строки.filter { $0.contains("Branch: renamed") }.count == 1)
    }
    @Test func незарождённоеЧужоеДеревоНеРазрешаетНовуюСсылку() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        let чужой = ф.каталог.appendingPathComponent("other-worktree")
        _ = try ф.гит(["worktree", "add", "--detach", чужой.path, п.задание.ожидаемыйКоммит])
        _ = try ф.гит(["-C", чужой.path, "symbolic-ref", "HEAD", п.новаяВетка])
        let голова = try ф.гит(["-C", чужой.path, "symbolic-ref", "HEAD"])
        let индекс = try ф.гит(["-C", чужой.path, "rev-parse", "--path-format=absolute", "--git-path", "index"])
        let байтыИндекса = try Data(contentsOf: URL(fileURLWithPath: индекс))
        #expect(throws: (any Error).self) { try ф.план() }
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
        #expect(!FileManager.default.fileExists(atPath: URL(fileURLWithPath: п.задание.каталогПротокола).appendingPathComponent("01-переименование-намерение.json").path))
        #expect(try ф.гит(["-C", чужой.path, "symbolic-ref", "HEAD"]) == голова)
        #expect(try Data(contentsOf: URL(fileURLWithPath: индекс)) == байтыИндекса)
    }
    @Test func читающийАкторНеПолучаетПравоПереименования() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        try await ф.подготовить(п)
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п, режим: "переименовать-читающим") }
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
    }
    @Test(arguments: ["чужая-схема", "чужой-план", "ненулевой-код", "обрыв"])
    func подменённыйИсходНеПринимается(_ вид: String) async throws {
        let ф = try Фикстура(); let п = try ф.план()
        _ = try await ф.выполнить(п)
        let путь = URL(fileURLWithPath: п.задание.каталогПротокола).appendingPathComponent("01-переименование-исход.json")
        let данные = вид == "обрыв" ? Data("{".utf8) : try кодировать(СохранённыйИсход(
            схема: вид == "чужая-схема" ? "чужая" : "fum.исход-перехода.1", фаза: "01-переименование",
            хэшПлана: вид == "чужой-план" ? "чужой" : п.отпечаток(), код: вид == "ненулевой-код" ? 9 : 0,
            объект: п.задание.ожидаемыйКоммит, пояснение: "отрицательная фикстура"))
        try данные.write(to: путь)
        let журнал = try ф.гит(["reflog", "show", "--format=%gs", п.новаяВетка])
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
        #expect(try ф.гит(["reflog", "show", "--format=%gs", п.новаяВетка]) == журнал)
    }
    @Test func возвращённаяСтараяСсылкаОтклоняетПовтор() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        _ = try await ф.выполнить(п)
        _ = try ф.гит(["branch", "codex/old", п.задание.ожидаемыйКоммит])
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
    }
    @Test func новаяВеткаБезСвоегоНамеренияОтклоняется() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        _ = try ф.гит(["branch", "-m", String(п.новаяВетка.dropFirst(11))])
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
    }
    @Test func существующаяЦельНаТомЖеКоммитеОтклоняется() async throws {
        let ф = try Фикстура(); let п = try ф.план()
        _ = try ф.гит(["branch", String(п.новаяВетка.dropFirst(11))])
        #expect(throws: (any Error).self) { try ф.план() }
        await #expect(throws: ОтказФикстурногоИнструмента.self) { try await ф.выполнить(п) }
        #expect(try ф.гит(["symbolic-ref", "HEAD"]) == п.задание.прежняяВетка)
    }
    @Test(.enabled(if: ProcessInfo.processInfo.environment["ФУМ_ПРОФИЛЬ_ПЕРЕХОДА"] == "1"))
    func профильПланаПереименованияИПовтора() async throws {
        var образцы: [[String: UInt64]] = []
        for _ in 0..<3 {
            let ф = try Фикстура()
            let начало = DispatchTime.now().uptimeNanoseconds
            let п = try ф.план()
            let послеПлана = DispatchTime.now().uptimeNanoseconds
            _ = try await ф.выполнить(п)
            let послеЭффекта = DispatchTime.now().uptimeNanoseconds
            _ = try await ф.выполнить(п)
            let послеПовтора = DispatchTime.now().uptimeNanoseconds
            образцы.append(["план_нс": послеПлана - начало, "rename_нс": послеЭффекта - послеПлана,
                             "повтор_нс": послеПовтора - послеЭффекта])
        }
        let результат: [String: Any] = ["схема": "fum.профиль-перехода-ветки.1", "подготовка_исключена": true,
            "образцы": образцы, "сравнение_оптимизации": NSNull()]
        print(String(decoding: try JSONSerialization.data(withJSONObject: результат, options: [.sortedKeys]), as: UTF8.self))
    }
}
