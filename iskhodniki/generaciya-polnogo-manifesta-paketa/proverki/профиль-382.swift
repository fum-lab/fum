import Foundation
import ГенерацияМанифеста

@main enum ПрофильФасада382 {
    static func main() throws {
        let окружение = ProcessInfo.processInfo.environment
        let корень = URL(fileURLWithPath: окружение["ФУМ_КАТАЛОГ_ФИКСТУР"]!).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: корень) }
        try Data("// Фикстура профиля\n".utf8).write(to: корень.appendingPathComponent("src/a.swift"))
        let данные = try Data(contentsOf: URL(fileURLWithPath: окружение["ФУМ_ОПИСАНИЕ_382"]!))
        let часы = ContinuousClock()
        var измерения: [Double] = []
        var размер = 0
        for _ in 0..<10 {
            let начало = часы.now
            let ответ = try ФасадГенератораМанифеста.породить(описание: данные, корень: корень).get()
            let длительность = начало.duration(to: часы.now).components
            измерения.append(Double(длительность.seconds) * 1_000 + Double(длительность.attoseconds) / 1e15)
            размер = ответ.манифест.count
        }
        let результат: [String: Any] = ["схема": "fum.профиль-фасада-382.1", "вызовов": 10,
            "миллисекунды": измерения, "байтов_манифеста": размер,
            "граница": "Полный синхронный фасад: JSON, проверка файлов, генерация, хэши и diff с пустым прежним входом. Подготовка фикстуры и компиляция вне таймера. Оптимизации, сравнения и вывода о bottleneck нет."]
        var вывод = try JSONSerialization.data(withJSONObject: результат, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        вывод.append(0x0a)
        FileHandle.standardOutput.write(вывод)
    }
}
