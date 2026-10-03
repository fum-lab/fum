import Foundation
import Darwin
import CryptoKit
import НаблюдениеДоступности
import КонтейнерНаблюдений

enum ПрофильДоступности {
    static func выполнить(корень: URL, повторы: Int, выход: URL, исходники: URL) throws {
        guard try FileManager.default.contentsOfDirectory(atPath: корень.path).isEmpty else { throw ОшибкаКоманды.некорректныйПрофиль }
        var измерения: [String: [UInt64]] = [:]
        for _ in 0..<повторы {
            let каталог = корень.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let намерение = НамерениеДоступности(попытка: UUID(), оператор: "профиль-доступности", версияГрафа: "неподключён",
                время: ISO8601DateFormatter().string(from: Date()), процесс: getpid())
            let сегмент = try Сегмент(кореньДанных: каталог, запись: true)
            let наблюдатель = НаблюдательДоступности(сегмент: сегмент)
            let сохранённое: СостояниеДоступности
            do { сохранённое = try наблюдатель.наблюдать(намерение) }
            catch { сегмент.закрыть(); throw error }
            сегмент.закрыть()
            guard наблюдатель.профиль.count == 3,
                  case .ответ(let ответ, .новаяФиксация) = сохранённое else { throw ОшибкаКоманды.некорректныйПрофиль }
            for метка in наблюдатель.профиль {
                guard метка.исход == "успешно", метка.глубина == 0 else { throw ОшибкаКоманды.некорректныйПрофиль }
                измерения[метка.этап, default: []].append(метка.наносекунды)
            }
            let файл = каталог.appendingPathComponent("сегмент.fumobs")
            let до = try Data(contentsOf: файл)
            let начало = DispatchTime.now().uptimeNanoseconds
            let повтор = try ВоспроизведениеДоступности.прочитать(кореньДанных: каталог, попытка: намерение.идентификаторПопытки)
            let длительность = DispatchTime.now().uptimeNanoseconds - начало
            guard повтор == .ответ(ответ, основание: .историческоеЧтение),
                  try Data(contentsOf: файл) == до else { throw ОшибкаКоманды.некорректныйПрофиль }
            измерения["воспроизведение", default: []].append(длительность)
        }
        let этапы = измерения.mapValues { числа -> [String: Any] in
            let ряд = числа.sorted()
            return ["число": ряд.count, "минимум_наносекунды": ряд[0], "медиана_наносекунды": ряд[(ряд.count - 1) / 2],
                "процентиль95_наносекунды": ряд[Int(ceil(Double(ряд.count) * 0.95)) - 1], "максимум_наносекунды": ряд[ряд.count - 1],
                "измерения_наносекунды": числа, "исход": "успешно", "глубина": 0]
        }
        let пути = ["Package.swift", "Sources/НаблюдениеДоступности/НамерениеДоступности.swift", "Sources/НаблюдениеДоступности/ОтветДоступности.swift",
            "Sources/НаблюдениеДоступности/СостояниеДоступности.swift", "Sources/НаблюдениеДоступности/ОшибкаНаблюденияДоступности.swift",
            "Sources/НаблюдениеДоступности/НаблюдательДоступности.swift", "Sources/НаблюдениеДоступности/ВоспроизведениеДоступности.swift",
            "Sources/КомандаДоступности/Команда.swift", "Sources/КомандаДоступности/ПрофильДоступности.swift",
            "Tests/НаблюдениеДоступностиTests/НаблюдениеTests.swift", "Tests/НаблюдениеДоступностиTests/ВоспроизведениеTests.swift"]
        var хэши: [String: String] = [:]
        for путь in пути {
            let байты = try Data(contentsOf: исходники.appendingPathComponent(путь))
            хэши[путь] = SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
        }
        let процесс = Process(), канал = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        процесс.arguments = ["--version"]
        процесс.standardOutput = канал
        try процесс.run()
        let версия = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else { throw ОшибкаКоманды.некорректныйПрофиль }
        #if DEBUG
        let сборка = "Debug"
        #else
        let сборка = "Release"
        #endif
        let профиль: [String: Any] = ["схема": "fum.профиль-доступности.1", "сборка": сборка, "повторов": повторы,
            "время": ISO8601DateFormatter().string(from: Date()), "компилятор": String(decoding: версия, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
            "система": ProcessInfo.processInfo.operatingSystemVersionString, "системный_вызов": "AXIsProcessTrusted()", "подставная_функция": false,
            "граница": "Запись включает JSON и fsync файла и каталога; API включает монотонное измерение. Воспроизведение включает открытие, сканирование, проверку пары и закрытие. Создание корня, файла и запуск swift --version исключены. Кэш ОС не очищался; сырые наблюдения и пути не публикуются.",
            "этапы": этапы, "алгоритм_хэширования": "SHA-256", "хэши_исходников": хэши]
        try JSONSerialization.data(withJSONObject: профиль, options: [.prettyPrinted, .sortedKeys]).write(to: выход, options: [.withoutOverwriting])
    }
}
