import Foundation
import Darwin

struct ИсходКонтроляИндекса: Codable, Sendable {
    var процесс: Int32
    var код: Int32?
    var сигнал: Int32?
    var предел_достигнут: Bool
    var длительность_нс: UInt64
    var классификация: String
    var ошибка_сверки: String?
}

@MainActor
private final class ДочернийПроцессИндекса {
    let процесс = Process()
    var продолжение: CheckedContinuation<(Int32, Int32, Bool), any Error>?

    func запустить(_ исполнитель: URL, _ аргументы: [String], вывод: FileHandle, ошибки: FileHandle) async throws -> (Int32, Int32, Bool) {
        процесс.executableURL = исполнитель; процесс.arguments = аргументы
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        return try await withCheckedThrowingContinuation { продолжение in
            self.продолжение = продолжение
            процесс.terminationHandler = { [weak self] завершённый in
                let данные = (завершённый.processIdentifier, завершённый.terminationStatus, завершённый.terminationReason == .uncaughtSignal)
                Task { @MainActor [weak self] in
                    self?.продолжение?.resume(returning: данные); self?.продолжение = nil
                }
            }
            do { try процесс.run() }
            catch { self.продолжение = nil; продолжение.resume(throwing: error) }
        }
    }

    func остановить(жёстко: Bool) {
        guard процесс.isRunning else { return }
        if жёстко { _ = kill(процесс.processIdentifier, SIGKILL) }
        else { процесс.terminate() }
    }
}

enum КонтроллерВосстановленияИндекса {
    private enum Событие: Sendable {
        case процесс(Int32, Int32, Bool)
        case мягкийПредел
        case жёсткийПредел
        case ошибка(String)
        case отмена
    }

    // Ожидание процесса и deadlines — структурированные async-задачи. Потоки идут
    // сразу в отдельные файлы; родитель не блокируется чтением Pipe/waitUntilExit.
    @MainActor
    static func выполнить(исполнитель: URL, аргументы: [String], каталог: URL,
                          план: ПланВосстановленияИндекса?, пределСекунд: UInt64 = 350) async throws -> ИсходКонтроляИндекса {
        guard пределСекунд >= 2, пределСекунд <= 350 else { throw ОтказИндексаMarkdown.вход("предел-контроллера-2-350") }
        if let план { try ВосстановлениеИндексаMarkdown.сверитьКаталогКвитанций(каталог, корень: план.вход.корень) }
        let начало = DispatchTime.now().uptimeNanoseconds
        for имя in ["controller.stdout.bin", "controller.stderr.bin"] {
            try ВосстановлениеИндексаMarkdown.сохранитьКвитанцию(каталог.appendingPathComponent(имя), байты: Data())
        }
        func открыть(_ имя: String) throws -> FileHandle {
            let дескриптор = open(каталог.appendingPathComponent(имя).path, O_WRONLY | O_NOFOLLOW | O_CLOEXEC)
            guard дескриптор >= 0 else { throw ОтказИндексаMarkdown.вход("не-открыт-поток-контроллера") }
            return FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
        }
        let вывод = try открыть("controller.stdout.bin"), ошибки = try открыть("controller.stderr.bin")
        defer { try? вывод.close(); try? ошибки.close() }
        try ВосстановлениеИндексаMarkdown.сохранитьКвитанцию(каталог.appendingPathComponent("controller-intent.json"),
            байты: ВосстановлениеИндексаMarkdown.кодировать([
                "исполнитель": исполнитель.path, "исполнитель_sha256": ИндексMarkdownСлияния.хэш(try Data(contentsOf: исполнитель)),
                "аргументы": аргументы.joined(separator: "\n"), "жёсткий_предел_секунд": String(пределСекунд),
                "монотонная_эпоха": String(начало), "план_sha256": try план.map { try ИндексMarkdownСлияния.хэш(ВосстановлениеИндексаMarkdown.кодировать($0)) } ?? "проверочная-фикстура"
            ]))
        let дочерний = ДочернийПроцессИндекса()
        var предел = false
        let статус: (Int32, Int32, Bool) = try await withThrowingTaskGroup(of: Событие.self) { группа in
            группа.addTask {
                do {
                    let ответ = try await дочерний.запустить(исполнитель, аргументы, вывод: вывод, ошибки: ошибки)
                    return .процесс(ответ.0, ответ.1, ответ.2)
                } catch { return .ошибка(String(describing: error)) }
            }
            группа.addTask {
                do { try await Task.sleep(for: .seconds(пределСекунд > 10 ? пределСекунд - 10 : пределСекунд - 1)); return .мягкийПредел }
                catch { return .отмена }
            }
            группа.addTask {
                do { try await Task.sleep(for: .seconds(пределСекунд)); return .жёсткийПредел }
                catch { return .отмена }
            }
            while let событие = try await группа.next() {
                switch событие {
                case .процесс(let номер, let код, let сигнал): группа.cancelAll(); return (номер, код, сигнал)
                case .ошибка(let описание): группа.cancelAll(); throw ОтказИндексаMarkdown.вход(описание)
                case .мягкийПредел, .жёсткийПредел:
                    предел = true
                    дочерний.остановить(жёстко: { if case .жёсткийПредел = событие { true } else { false } }())
                case .отмена: break
                }
            }
            throw ОтказИндексаMarkdown.вход("нет-терминального-исхода-процесса")
        }
        try вывод.synchronize(); try ошибки.synchronize()
        var безЭффекта: Bool?, ошибкаСверки: String?
        do { безЭффекта = try план.map { try ВосстановлениеИндексаMarkdown.сверитьИсходноеСостояние($0) } }
        catch { ошибкаСверки = String(describing: error) }
        let исход = ИсходКонтроляИндекса(процесс: статус.0, код: статус.2 ? nil : статус.1, сигнал: статус.2 ? статус.1 : nil,
            предел_достигнут: предел, длительность_нс: DispatchTime.now().uptimeNanoseconds - начало,
            классификация: ошибкаСверки != nil ? "неизвестно" : (безЭффекта == true ? "нет-целевого-эффекта" : (!предел && !статус.2 && статус.1 == 0 ? "успех-процесса-требуется-независимая-сверка" : "неизвестно")), ошибка_сверки: ошибкаСверки)
        try ВосстановлениеИндексаMarkdown.сохранитьКвитанцию(каталог.appendingPathComponent("controller-outcome.json"), байты: ВосстановлениеИндексаMarkdown.кодировать(исход))
        return исход
    }
}
