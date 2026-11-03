import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

@Suite("CLI: процессы и малый профиль", .serialized)
struct ПроверкиПроцессовКоманды {
    @Test("Отмена ожидания завершает собственный дочерний процесс")
    func отменаОжиданияПроцесса() async throws {
        let среда = try СредаКоманды()
        let процессы = try ПроцессыКоманды(бинарник: URL(fileURLWithPath: "/bin/sleep"), каталог: среда.корень)
        try await withThrowingTaskGroup(of: Bool.self) { группа in
            группа.addTask {
                do {
                    _ = try await процессы.запустить(["1"], имя: "отменяемое-ожидание")
                    return false
                } catch is CancellationError {
                    return true
                }
            }
            группа.addTask {
                try await Task.sleep(for: .milliseconds(50))
                return false
            }
            _ = try await группа.next()
            группа.cancelAll()
            let отменено = try await группа.next()
            #expect(отменено == true)
        }
    }

    @Test("Новое исполнение после SIGKILL уже вычислявшего процесса")
    func прерванноеИсполнение() async throws {
        let среда = try СредаКоманды()
        let процессы = try ПроцессыКоманды(бинарник: среда.бинарник, каталог: среда.корень)
        let приём = UUID().uuidString.lowercased()
        let прерванное = UUID().uuidString.lowercased()
        let новое = UUID().uuidString.lowercased()
        let метка = UUID().uuidString.lowercased()
        let первый = try await процессы.запустить(среда.принять(приём), имя: "приём-для-прерывания")
        #expect(первый.код == 0)
        let принято = try JSONDecoder().decode(ОтветПриёмаСреза.self, from: первый.данные)
        try FileManager.default.removeItem(at: среда.вход)
        try FileManager.default.removeItem(at: среда.определение)
        let файл = среда.журнал.appendingPathComponent("сегмент.fumobs")
        let префикс = try Data(contentsOf: файл)
        let окружение = ProcessInfo.processInfo.environment
        let загрузчик = URL(fileURLWithPath: try #require(окружение["ФУМА_ЗАГРУЗЧИК_ТЕСТОВ"]))
        let пакет = URL(fileURLWithPath: try #require(окружение["ФУМА_ПАКЕТ_ТЕСТОВ"]))
        let прерываемый = try ПроцессыКоманды(бинарник: загрузчик, каталог: среда.корень,
            закреплённыеВходы: [пакет])
        let граница = среда.корень.appendingPathComponent("граница-прерывания.json")
        var средаРебёнка: [String: String] = [:]
        for ключ in ["PATH", "HOME", "TMPDIR", "LANG", "LC_ALL", "__CF_USER_TEXT_ENCODING",
                     "DYLD_LIBRARY_PATH", "DYLD_FRAMEWORK_PATH"] {
            средаРебёнка[ключ] = окружение[ключ]
        }
        средаРебёнка["ФУМА_ПРЕРЫВАЕМЫЙ_ПРОЦЕСС"] = "1"
        средаРебёнка["ФУМА_ЖУРНАЛ_ПРОЦЕССА"] = среда.журнал.path
        средаРебёнка["ФУМА_ПРИЁМ_ПРОЦЕССА"] = приём
        средаРебёнка["ФУМА_ИСПОЛНЕНИЕ_ПРОЦЕССА"] = прерванное
        средаРебёнка["ФУМА_ГРАНИЦА_ПРОЦЕССА"] = граница.path
        средаРебёнка["ФУМА_МЕТКА_ПРОЦЕССА"] = метка
        let идентификатор = try await прерываемый.начатьУправляемыйПроцесс(
            ["--test-bundle-path", пакет.path, "--testing-library", "swift-testing",
             "--filter", "точкаОстановаПослеРамки"], среда: средаРебёнка)
        do {
            let часы = ContinuousClock()
            let предел = часы.now.advanced(by: .seconds(15))
            while true {
                if FileManager.default.fileExists(atPath: граница.path),
                   await прерываемый.остановленСигналом() { break }
                guard часы.now < предел, await прерываемый.выполняется() else {
                    throw ОшибкаУправляемогоПроцесса.неДостигнутаГраница
                }
                try await Task.sleep(for: .milliseconds(10))
            }
            let байтыГраницы = try Data(contentsOf: граница)
            let завершение = try await прерываемый.прерватьИПрочитать()
            let наблюдение = try #require(завершение)
            let свидетельство = try JSONDecoder().decode(ГраницаПрерывания.self, from: байтыГраницы)
            #expect(try кодироватьСтрокуСреза(свидетельство) == байтыГраницы)
            #expect(свидетельство.схема == "fuma.граница-прерывания.1")
            #expect(свидетельство.метка == метка)
            #expect(свидетельство.процесс == идентификатор)
            #expect(свидетельство.приём == приём)
            #expect(свидетельство.исполнение == прерванное)
            #expect(свидетельство.вычисленоРамок == 3)
            #expect(наблюдение.сигнал)
            #expect(наблюдение.код == SIGKILL)
            #expect(try Data(contentsOf: файл) == префикс)
            let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: false, создать: false)
            let квитанции = сегмент.записи
            сегмент.закрыть()
            #expect(квитанции.count == 5)
            #expect(!квитанции.contains { $0.описание.идентификатор == прерванное })
            let продолжение = try await процессы.запустить(среда.исполнить(приём, новое), имя: "после-прерывания")
            #expect(продолжение.код == 0)
            #expect(продолжение.идентификаторПроцесса != идентификатор)
            let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: продолжение.данные)
            #expect(ответ.запись.манифест == принято.квитанция)
            #expect(ответ.запись.повторРезультата == nil)
            #expect(ответ.квитанция.описание.идентификатор == новое)
            #expect(ответ.запись.запись.рамки.count == 7)
            #expect(ответ.запись.запись.отказ == nil)
            #expect(try Data(contentsOf: файл).starts(with: префикс))
        } catch {
            _ = try await прерываемый.прерватьИПрочитать()
            throw error
        }
    }

    @Test("Вспомогательная управляемая граница",
          .enabled(if: ProcessInfo.processInfo.environment["ФУМА_ПРЕРЫВАЕМЫЙ_ПРОЦЕСС"] == "1"))
    func точкаОстановаПослеРамки() throws {
        let среда = ProcessInfo.processInfo.environment
        let журнал = try #require(среда["ФУМА_ЖУРНАЛ_ПРОЦЕССА"])
        let приём = try #require(среда["ФУМА_ПРИЁМ_ПРОЦЕССА"])
        let исполнение = try #require(среда["ФУМА_ИСПОЛНЕНИЕ_ПРОЦЕССА"])
        let метка = try #require(среда["ФУМА_МЕТКА_ПРОЦЕССА"])
        let граница = URL(fileURLWithPath: try #require(среда["ФУМА_ГРАНИЦА_ПРОЦЕССА"]))
        var вычислено = 0
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы:
            ["--исполнить-приём-JSONL", приём, "--исполнение", исполнение, "--журнал", журнал],
            профиль: { замер in
                guard замер.стадия == "исполнение", замер.глубина == 0, замер.исход == "успешно" else { return }
                вычислено += 1
                guard вычислено == 3 else { return }
                do {
                    let свидетельство = ГраницаПрерывания(схема: "fuma.граница-прерывания.1",
                        метка: метка, процесс: ProcessInfo.processInfo.processIdentifier,
                        приём: приём, исполнение: исполнение, вычисленоРамок: вычислено)
                    let временный = граница.appendingPathExtension("tmp")
                    try кодироватьСтрокуСреза(свидетельство).write(to: временный, options: [.withoutOverwriting])
                    let файл = try FileHandle(forWritingTo: временный)
                    try файл.synchronize()
                    try файл.close()
                    try FileManager.default.moveItem(at: временный, to: граница)
                    _ = raise(SIGSTOP)
                    Darwin._exit(125)
                } catch {
                    try? FileHandle.standardError.write(contentsOf: Data((String(describing: error) + "\n").utf8))
                    Darwin._exit(126)
                }
            })
        Issue.record("Исполнение завершилось без управляемой остановки")
    }

    @Test("Изменение выбранного бинарника запрещает запуск и измерение")
    func подменаБинарника() async throws {
        let среда = try СредаКоманды()
        let копия = среда.корень.appendingPathComponent("копия-команды")
        try Data(contentsOf: среда.бинарник).write(to: копия, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: копия.path)
        let процессы = try ПроцессыКоманды(бинарник: копия, каталог: среда.корень)
        try Data("бинарник изменён после выбора".utf8).write(to: копия)
        do {
            _ = try await процессы.запустить(["--неизвестная-команда"], имя: "запрещённый-вызов")
            Issue.record("Запуск разрешён после изменения бинарника")
        } catch let ошибка as ОшибкаФиксацииБинарника {
            #expect(ошибка == .изменённыйБинарник)
        }
        let созданВывод = FileManager.default.fileExists(atPath:
            среда.корень.appendingPathComponent("запрещённый-вызов.вывод.raw").path)
        #expect(!созданВывод)
    }

    @Test("Подтверждённый приём переживает завершение первого процесса")
    func новыйПроцессИсполняетПриём() async throws {
        let среда = try СредаКоманды()
        let процессы = try ПроцессыКоманды(бинарник: среда.бинарник, каталог: среда.корень)
        let приём = UUID().uuidString.lowercased()
        let исполнение = UUID().uuidString.lowercased()
        let первый = try await процессы.запустить(среда.принять(приём), имя: "приём")
        #expect(первый.код == 0)
        let принято = try JSONDecoder().decode(ОтветПриёмаСреза.self, from: первый.данные)
        #expect(принято.манифест.сыройВход.хэш == хэшБайтовСреза(среда.исходник))
        let файл = среда.журнал.appendingPathComponent("сегмент.fumobs")
        let префикс = try Data(contentsOf: файл)
        try FileManager.default.removeItem(at: среда.вход)
        try FileManager.default.removeItem(at: среда.определение)
        let второй = try await процессы.запустить(среда.исполнить(приём, исполнение), имя: "новое-исполнение")
        #expect(второй.код == 0)
        #expect(второй.идентификаторПроцесса != первый.идентификаторПроцесса)
        let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: второй.данные)
        #expect(ответ.запись.манифест == принято.квитанция)
        #expect(ответ.запись.повторРезультата == nil)
        #expect(ответ.квитанция.описание.идентификатор == исполнение)
        #expect(ответ.запись.запись.отказ == nil)
        #expect(ответ.запись.запись.рамки.map(\.позиция.номер) == Array(1...7))
        #expect(ответ.запись.запись.сыройХвост.начало == 780)
        #expect(ответ.запись.запись.сыройХвост.конец == 782)
        let эталон = try #require(JSONSerialization.jsonObject(with: среда.эталон) as? [String: Any])
        let рамки = try #require(эталон["рамки"] as? [[String: Any]])
        for (фактическая, ожидаемая) in zip(ответ.запись.запись.рамки, рамки) {
            let наблюдение = try #require(JSONSerialization.jsonObject(with: фактическая.наблюдение) as? [String: Any])
            let результат = try #require(наблюдение["результат"] as? [String: Any])
            let значение = try #require(результат["значение"] as? String)
            let объект = try JSONSerialization.jsonObject(with: Data(значение.utf8))
            let ожидание = try #require(ожидаемая["ожидание"])
            let фактическиеБайты = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
            let ожидаемыеБайты = try JSONSerialization.data(withJSONObject: ожидание, options: [.sortedKeys])
            #expect(фактическиеБайты == ожидаемыеБайты)
            #expect(фактическая.позиция.sha256 == ожидаемая["sha256"] as? String)
        }
        let после = try Data(contentsOf: файл)
        #expect(после.starts(with: префикс))
        let третий = try await процессы.запустить(["--повторить-JSONL", исполнение,
            "--журнал", среда.журнал.path, "--профиль"], имя: "повтор-готового")
        #expect(третий.код == 0)
        #expect(третий.идентификаторПроцесса != второй.идентификаторПроцесса)
        let повтор = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: третий.данные)
        #expect(повтор.запись.повторРезультата == ответ.квитанция)
        #expect(повтор.запись.запись == ответ.запись.запись)
        #expect(try Data(contentsOf: файл).starts(with: после))
    }

    @Test("Три профильных образца отделяют приём от нового исполнения")
    func малыйПрофиль() async throws {
        struct Образец: Encodable {
            let приём: НаблюдениеПроцесса
            let исполнение: НаблюдениеПроцесса
        }
        struct Профиль: Encodable {
            let схема = "fuma.профиль-процессов-команды.2"
            let хэшБинарникаДо: String
            let хэшБинарникаПосле: String
            let хэшИсходника: String
            let хэшОпределения: String
            let граница = "Новый процесс: Process.run до waitUntilExit; без сборки, подготовки входа, чтения pin и синхронизации RAW вызывающей стороны. Кэш ОС не очищался; чтение pin влияет на его состояние."
            let образцы: [Образец]
        }
        let среда = try СредаКоманды()
        let процессы = try ПроцессыКоманды(бинарник: среда.бинарник, каталог: среда.корень)
        let хэшДо = try await процессы.проверитьФиксацию()
        var образцы: [Образец] = []
        for номер in 0..<3 {
            if номер > 0 { try среда.записатьВходы() }
            let приём = UUID().uuidString.lowercased()
            let первое = try await процессы.запустить(среда.принять(приём), имя: "приём-\(номер)")
            #expect(первое.код == 0)
            try FileManager.default.removeItem(at: среда.вход)
            try FileManager.default.removeItem(at: среда.определение)
            let второе = try await процессы.запустить(среда.исполнить(приём, UUID().uuidString.lowercased()), имя: "исполнение-\(номер)")
            #expect(второе.код == 0)
            let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: второе.данные)
            #expect(ответ.запись.запись.рамки.count == 7)
            #expect(ответ.запись.запись.отказ == nil)
            образцы.append(Образец(приём: первое, исполнение: второе))
        }
        let хэшПосле = try await процессы.проверитьФиксацию()
        let профиль = Профиль(хэшБинарникаДо: хэшДо, хэшБинарникаПосле: хэшПосле,
            хэшИсходника: хэшБайтовСреза(среда.исходник), хэшОпределения: хэшБайтовСреза(среда.программа), образцы: образцы)
        let данные = try кодироватьСтрокуСреза(профиль)
        try данные.write(to: среда.корень.appendingPathComponent("профиль.json"), options: [.withoutOverwriting])
    }
}

private struct ГраницаПрерывания: Codable, Sendable {
    let схема: String
    let метка: String
    let процесс: Int32
    let приём: String
    let исполнение: String
    let вычисленоРамок: Int
}

private enum ОшибкаУправляемогоПроцесса: Error {
    case неДостигнутаГраница, ужеЗапущен, неУдалосьПрервать, превышеноВремя
}

private struct НаблюдениеПрерывания: Encodable, Sendable {
    let процесс: Int32
    let код: Int32
    let сигнал: Bool
    let данные: Data
    let диагностика: Data
}

private struct НаблюдениеПроцесса: Codable, Sendable {
    let идентификаторПроцесса: Int32
    let код: Int32
    let наносекунды: UInt64
    let данные: Data
    let диагностика: Data
}

private enum ОшибкаФиксацииБинарника: Error, Equatable {
    case изменённыйБинарник
}

private actor ПроцессыКоманды {
    let бинарник: URL
    let каталог: URL
    private let хэшБинарника: String
    private let хэшиВходов: [URL: String]
    private struct АктивныйПроцесс {
        let процесс: Process
        let вывод: FileHandle
        let ошибки: FileHandle
        let путьВывода: URL
        let путьОшибок: URL
    }
    private var активный: АктивныйПроцесс?

    init(бинарник: URL, каталог: URL, закреплённыеВходы: [URL] = []) throws {
        self.бинарник = бинарник
        self.каталог = каталог
        хэшБинарника = хэшБайтовСреза(try Data(contentsOf: бинарник))
        var хэши: [URL: String] = [:]
        for вход in закреплённыеВходы { хэши[вход] = хэшБайтовСреза(try Data(contentsOf: вход)) }
        хэшиВходов = хэши
    }

    func проверитьФиксацию() throws -> String {
        guard хэшБайтовСреза(try Data(contentsOf: бинарник)) == хэшБинарника
        else { throw ОшибкаФиксацииБинарника.изменённыйБинарник }
        for (вход, хэш) in хэшиВходов {
            guard хэшБайтовСреза(try Data(contentsOf: вход)) == хэш
            else { throw ОшибкаФиксацииБинарника.изменённыйБинарник }
        }
        return хэшБинарника
    }

    func начатьУправляемыйПроцесс(_ аргументы: [String], среда: [String: String]) throws -> Int32 {
        guard активный == nil else { throw ОшибкаУправляемогоПроцесса.ужеЗапущен }
        _ = try проверитьФиксацию()
        let путьВывода = каталог.appendingPathComponent("прерываемый-процесс.вывод.raw")
        let путьОшибок = каталог.appendingPathComponent("прерываемый-процесс.ошибки.raw")
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil, attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil, attributes: [.posixPermissions: 0o600])
        else { throw ОшибкаКомандногоИсполнения.аргументы }
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        let процесс = Process()
        процесс.executableURL = бинарник
        процесс.arguments = аргументы
        процесс.environment = среда
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        do { try процесс.run() }
        catch {
            if процесс.isRunning {
                _ = Darwin.kill(процесс.processIdentifier, SIGKILL)
                процесс.waitUntilExit()
            }
            try? вывод.close()
            try? ошибки.close()
            throw error
        }
        активный = АктивныйПроцесс(процесс: процесс, вывод: вывод, ошибки: ошибки,
            путьВывода: путьВывода, путьОшибок: путьОшибок)
        return процесс.processIdentifier
    }

    func выполняется() -> Bool { активный?.процесс.isRunning ?? false }

    func остановленСигналом() -> Bool {
        guard let активный else { return false }
        var сведения = siginfo_t()
        let код = waitid(P_PID, id_t(активный.процесс.processIdentifier), &сведения,
            WSTOPPED | WNOWAIT | WNOHANG)
        return код == 0 && сведения.si_pid == активный.процесс.processIdentifier
            && сведения.si_code == CLD_STOPPED && сведения.si_status == SIGSTOP
    }

    func прерватьИПрочитать() throws -> НаблюдениеПрерывания? {
        guard let активный else { return nil }
        let процесс = активный.процесс
        if процесс.isRunning {
            guard процесс.processIdentifier > 1,
                  Darwin.kill(процесс.processIdentifier, SIGKILL) == 0 || errno == ESRCH
            else { throw ОшибкаУправляемогоПроцесса.неУдалосьПрервать }
        }
        процесс.waitUntilExit()
        defer {
            try? активный.вывод.close()
            try? активный.ошибки.close()
            self.активный = nil
        }
        try активный.вывод.synchronize()
        try активный.ошибки.synchronize()
        let наблюдение = НаблюдениеПрерывания(процесс: процесс.processIdentifier,
            код: процесс.terminationStatus, сигнал: процесс.terminationReason == .uncaughtSignal,
            данные: try Data(contentsOf: активный.путьВывода), диагностика: try Data(contentsOf: активный.путьОшибок))
        try кодироватьСтрокуСреза(наблюдение).write(to: каталог.appendingPathComponent("прерывание.json"), options: [.withoutOverwriting])
        _ = try проверитьФиксацию()
        return наблюдение
    }

    func запустить(_ аргументы: [String], имя: String) async throws -> НаблюдениеПроцесса {
        try Task.checkCancellation()
        _ = try проверитьФиксацию()
        let путьВывода = каталог.appendingPathComponent(имя + ".вывод.raw")
        let путьОшибок = каталог.appendingPathComponent(имя + ".ошибки.raw")
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil, attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil, attributes: [.posixPermissions: 0o600])
        else { throw ОшибкаКомандногоИсполнения.аргументы }
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        let процесс = Process()
        процесс.executableURL = бинарник
        процесс.arguments = аргументы
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        let часы = ContinuousClock()
        let начало = часы.now
        var запущен = false
        do {
            try процесс.run()
            запущен = true
            let предел = начало.advanced(by: .seconds(60))
            while процесс.isRunning {
                try Task.checkCancellation()
                guard часы.now < предел else { throw ОшибкаУправляемогоПроцесса.превышеноВремя }
                try await Task.sleep(for: .milliseconds(5))
            }
            try Task.checkCancellation()
            процесс.waitUntilExit()
        } catch {
            if запущен {
                if процесс.isRunning {
                    guard процесс.processIdentifier > 1,
                          Darwin.kill(процесс.processIdentifier, SIGKILL) == 0 || errno == ESRCH
                    else { throw ОшибкаУправляемогоПроцесса.неУдалосьПрервать }
                }
                процесс.waitUntilExit()
            }
            throw error
        }
        let длительность = начало.duration(to: часы.now).components
        _ = try проверитьФиксацию()
        try вывод.synchronize()
        try ошибки.synchronize()
        let наблюдение = НаблюдениеПроцесса(идентификаторПроцесса: процесс.processIdentifier, код: процесс.terminationStatus,
            наносекунды: UInt64(длительность.seconds) * 1_000_000_000 + UInt64(длительность.attoseconds / 1_000_000_000),
            данные: try Data(contentsOf: путьВывода), диагностика: try Data(contentsOf: путьОшибок))
        try кодироватьСтрокуСреза(наблюдение).write(to: каталог.appendingPathComponent(имя + ".json"), options: [.withoutOverwriting])
        return наблюдение
    }
}

private struct СредаКоманды {
    let корень: URL
    let журнал: URL
    let вход: URL
    let определение: URL
    let бинарник: URL
    let исходник: Data
    let программа: Data
    let эталон: Data

    init() throws {
        let среда = ProcessInfo.processInfo.environment
        бинарник = URL(fileURLWithPath: try #require(среда["ФУМА_КОМАНДА_ОПЕРАТОРА"]))
        исходник = try Data(contentsOf: URL(fileURLWithPath: try #require(среда["ФУМА_СЫРАЯ_ФИКСТУРА_ЖУРНАЛА"])))
        программа = try Data(contentsOf: URL(fileURLWithPath: try #require(среда["ФУМА_ПРОГРАММА_ЖУРНАЛА"])))
        эталон = try Data(contentsOf: URL(fileURLWithPath: try #require(среда["ФУМА_ЭТАЛОН_ЖУРНАЛА"])))
        let свидетельства = URL(fileURLWithPath: try #require(среда["ФУМА_СВИДЕТЕЛЬСТВА_КОМАНДЫ"]))
        корень = свидетельства.appendingPathComponent(UUID().uuidString.lowercased())
        журнал = корень.appendingPathComponent("журнал")
        вход = корень.appendingPathComponent("вход.jsonl")
        определение = корень.appendingPathComponent("определение.json")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try FileManager.default.createDirectory(at: журнал, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try записатьВходы()
    }

    func записатьВходы() throws {
        try исходник.write(to: вход, options: [.withoutOverwriting])
        try программа.write(to: определение, options: [.withoutOverwriting])
    }

    func принять(_ приём: String) -> [String] {
        ["--принять-JSONL", приём, "--вход", вход.path, "--определение", определение.path,
            "--журнал", журнал.path, "--профиль"]
    }

    func исполнить(_ приём: String, _ исполнение: String) -> [String] {
        ["--исполнить-приём-JSONL", приём, "--исполнение", исполнение,
            "--журнал", журнал.path, "--профиль"]
    }
}
