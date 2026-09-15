import Dispatch
import Foundation

/// Синтетический профиль общей конфигурации; не запускает приложение и не читает пользовательские данные.
@main enum ПрофильПутей {
    static func main() throws {
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let среда = ["FUM_RUNTIME_ROOT": временный.appendingPathComponent("run").path,
                     "FUM_MEMORY_ROOT": временный.appendingPathComponent("memory").path]
        let повторения = 1000
        var образцы: [[String: Any]] = []
        for _ in 0..<5 {
            let начало = DispatchTime.now().uptimeNanoseconds
            for _ in 0..<повторения {
                let пути = try ПутиПриложения(среда: среда, домашнийКаталог: временный)
                precondition(пути.память.lastPathComponent == "memory")
            }
            let середина = DispatchTime.now().uptimeNanoseconds
            for _ in 0..<повторения {
                do {
                    _ = try ПутиПриложения(среда: ["FUM_RUNTIME_ROOT": "relative"], домашнийКаталог: временный)
                    preconditionFailure("Относительный путь принят")
                } catch ОшибкаПутей.относительныйКаталог {}
            }
            let границаПоиска = DispatchTime.now().uptimeNanoseconds
            for _ in 0..<повторения {
                precondition(ПутиПриложения.исполняемыйФайл("missing", среда: ["PATH": временный.path]) == nil)
            }
            let конец = DispatchTime.now().uptimeNanoseconds
            образцы.append(["проверка_абсолютных_каталогов_нс": середина - начало,
                            "отказ_относительного_пути_нс": границаПоиска - середина,
                            "поиск_отсутствующей_команды_нс": конец - границаПоиска])
        }
        precondition(!FileManager.default.fileExists(atPath: временный.path))
        let отчёт: [String: Any] = ["схема": "fum.профиль-путей.1", "повторения_стадии": повторения,
            "образцы": образцы, "данные": "Несуществующие временные каталоги; файлы не создаются."]
        let байты = try JSONSerialization.data(withJSONObject: отчёт, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(байты)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
