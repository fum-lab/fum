import Foundation
import Darwin
import CryptoKit
import НаблюдениеДоступности
import КонтейнерНаблюдений

enum ПрофильДоступности {
    static func выполнить(корень: URL, повторы: Int, выход: URL, исходники: URL) throws {
        guard try FileManager.default.contentsOfDirectory(atPath: корень.path).isEmpty else { throw ОшибкаКоманды.некорректныйПрофиль }
        var измерения: [String: [UInt64]] = [:]
        let началоВыбора = DispatchTime.now().uptimeNanoseconds
        let (компилятор, метод) = try выбратьКомпилятор()
        let хэшКомпилятора = SHA256.hash(data: try Data(contentsOf: компилятор.resolvingSymlinksInPath())).map { String(format: "%02x", $0) }.joined()
        измерения["выбор-компилятора"] = [DispatchTime.now().uptimeNanoseconds - началоВыбора]
        let началоВерсии = DispatchTime.now().uptimeNanoseconds
        let версия = try прочитатьВерсию(компилятор)
        измерения["версия-компилятора"] = [DispatchTime.now().uptimeNanoseconds - началоВерсии]
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
        #if DEBUG
        let сборка = "Debug"
        #else
        let сборка = "Release"
        #endif
        let профиль: [String: Any] = ["схема": "fum.профиль-доступности.2", "сборка": сборка, "повторов": повторы,
            "время": ISO8601DateFormatter().string(from: Date()), "компилятор": версия,
            "выбор_компилятора": метод, "хэш_компилятора": хэшКомпилятора,
            "система": ProcessInfo.processInfo.operatingSystemVersionString, "системный_вызов": "AXIsProcessTrusted()", "подставная_функция": false,
            "граница": "Выбор и SHA-256 исполняемого файла измерены один раз; запуск и чтение swift --version измерены отдельно один раз, до AX. Запись включает JSON и fsync файла и каталога; API включает монотонное измерение. Воспроизведение включает открытие, сканирование, проверку пары и закрытие. Создание корня и файла исключено. Кэш ОС не очищался; сырые наблюдения и пути не публикуются.",
            "этапы": этапы, "алгоритм_хэширования": "SHA-256", "хэши_исходников": хэши]
        try JSONSerialization.data(withJSONObject: профиль, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]).write(to: выход, options: [.withoutOverwriting])
    }

    private static func допустимыйКомпилятор(_ путь: String) -> URL? {
        guard путь.hasPrefix("/") else { return nil }
        let файл = URL(fileURLWithPath: путь)
        let физический = файл.resolvingSymlinksInPath()
        guard FileManager.default.isExecutableFile(atPath: файл.path),
            let свойства = try? физический.resourceValues(forKeys: [.isRegularFileKey]), свойства.isRegularFile == true else { return nil }
        return файл
    }

    private static func выбратьКомпилятор() throws -> (URL, String) {
        let среда = ProcessInfo.processInfo.environment
        if let путь = среда["ФУМ_КОМПИЛЯТОР"] {
            guard let файл = допустимыйКомпилятор(путь) else { throw ОшибкаВыбораКомпилятора.неверноеНазначениеКомпилятора }
            return (файл, "ФУМ_КОМПИЛЯТОР")
        }
        guard let поиск = среда["PATH"] else { throw ОшибкаВыбораКомпилятора.компиляторОтсутствует }
        var кандидаты: [String: URL] = [:]
        for путь in поиск.components(separatedBy: ":") {
            guard путь.hasPrefix("/") else { throw ОшибкаВыбораКомпилятора.неверныйПутьПоиска }
            if let файл = допустимыйКомпилятор(URL(fileURLWithPath: путь, isDirectory: true).appendingPathComponent("swift").path) {
                кандидаты[файл.resolvingSymlinksInPath().path] = файл
            }
        }
        guard !кандидаты.isEmpty else { throw ОшибкаВыбораКомпилятора.компиляторОтсутствует }
        guard кандидаты.count == 1, let файл = кандидаты.values.first else { throw ОшибкаВыбораКомпилятора.компиляторНеоднозначен }
        return (файл, "PATH")
    }

    private static func прочитатьВерсию(_ компилятор: URL) throws -> String {
        let процесс = Process(), канал = Pipe()
        процесс.executableURL = компилятор
        процесс.arguments = ["--version"]
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.nullDevice
        let дескриптор = канал.fileHandleForReading.fileDescriptor
        guard fcntl(дескриптор, F_SETFL, O_NONBLOCK) == 0 else { throw ОшибкаВыбораКомпилятора.невернаяВерсияКомпилятора }
        defer { try? канал.fileHandleForReading.close(); try? канал.fileHandleForWriting.close() }
        do { try процесс.run() } catch { throw ОшибкаВыбораКомпилятора.невернаяВерсияКомпилятора }
        try канал.fileHandleForWriting.close()
        let предел = DispatchTime.now().uptimeNanoseconds + 10_000_000_000
        var версия = Data(), буфер = [UInt8](repeating: 0, count: 1024)
        var отказ = false
        repeat {
            while true {
                let число = read(дескриптор, &буфер, буфер.count)
                if число > 0 {
                    версия.append(contentsOf: буфер.prefix(число))
                    if версия.count > 8192 { отказ = true; break }
                } else if число == 0 || errno == EAGAIN { break }
                else if errno != EINTR { отказ = true; break }
            }
            if отказ || DispatchTime.now().uptimeNanoseconds >= предел { отказ = true; break }
            if процесс.isRunning { Thread.sleep(forTimeInterval: 0.001) }
        } while процесс.isRunning
        if отказ && процесс.isRunning { kill(процесс.processIdentifier, SIGKILL) }
        процесс.waitUntilExit()
        // После завершения дочитывается ограниченный остаток трубы.
        while !отказ {
            let число = read(дескриптор, &буфер, буфер.count)
            if число <= 0 { break }
            версия.append(contentsOf: буфер.prefix(число))
            if версия.count > 8192 { отказ = true }
        }
        let текст = String(decoding: версия, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !отказ, процесс.terminationReason == .exit, процесс.terminationStatus == 0,
            текст.hasPrefix("Swift version ") || текст.hasPrefix("Apple Swift version ") else {
            throw ОшибкаВыбораКомпилятора.невернаяВерсияКомпилятора
        }
        return текст
    }
}

private enum ОшибкаВыбораКомпилятора: Error {
    case неверноеНазначениеКомпилятора, неверныйПутьПоиска, компиляторОтсутствует, компиляторНеоднозначен, невернаяВерсияКомпилятора
}
