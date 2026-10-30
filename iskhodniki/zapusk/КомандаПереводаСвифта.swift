import Foundation
import Darwin

enum КомандаПереводаСвифта {
    static func план(_ аргументы: [String]) throws -> Data {
        if аргументы.count == 5, Array(аргументы.prefix(4)) == ["язык", "перевод", "лексемы", "--файл"] {
            return try представить(ПереводСвифта.лексемы(прочитать(аргументы[4], предел: 4_194_304)))
        }
        if аргументы.count == 7, Array(аргументы.prefix(4)) == ["язык", "перевод", "лексемы", "--файл"],
           аргументы[5] == "--до-байта", let конец = Int(аргументы[6]), String(конец) == аргументы[6] {
            return try представить(ПереводСвифта.лексемы(прочитать(аргументы[4], предел: 4_194_304), конец: конец))
        }
        guard аргументы.count == 7, Array(аргументы.prefix(4)) == ["язык", "перевод", "план", "--корень"],
              аргументы[5] == "--карта", аргументы[4].hasPrefix("/"),
              !аргументы[4].hasSuffix("/") else { throw ОтказПереводаСвифта.вход }
        let карта = try прочитать(аргументы[6], предел: 1_048_576)
        let вход = try ПереводСвифта.разобрать(карта)
        var исходники: [String: Data] = [:]
        for файл in вход.файлы {
            исходники[файл.путь] = try прочитать(аргументы[4] + "/" + файл.путь, предел: 4_194_304)
        }
        let план = try ПереводСвифта.план(карта, исходники: исходники)
        // Читающий повтор выявляет наблюдаемый дрейф; файловый эффект отсутствует.
        guard try прочитать(аргументы[6], предел: 1_048_576) == карта else { throw ОтказПереводаСвифта.хэш }
        for файл in вход.файлы {
            guard try прочитать(аргументы[4] + "/" + файл.путь, предел: 4_194_304) == исходники[файл.путь] else {
                throw ОтказПереводаСвифта.хэш
            }
        }
        return try представить(план)
    }

    private static func представить<Значение: Encodable>(_ значение: Значение) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var ответ = try кодировщик.encode(значение)
        ответ.append(10)
        return ответ
    }

    private static func прочитать(_ путь: String, предел: Int) throws -> Data {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard части.count > 1, части.first == "", !путь.utf8.contains(0),
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ОтказПереводаСвифта.путь
        }
        var каталог = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard каталог >= 0 else { throw ОтказПереводаСвифта.путь }
        defer { _ = Darwin.close(каталог) }
        for часть in части.dropFirst().dropLast() {
            let следующий = Darwin.openat(каталог, String(часть), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОтказПереводаСвифта.путь }
            _ = Darwin.close(каталог); каталог = следующий
        }
        guard let имя = части.last else { throw ОтказПереводаСвифта.путь }
        let файл = Darwin.openat(каталог, String(имя), O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОтказПереводаСвифта.путь }
        defer { _ = Darwin.close(файл) }
        var сведения = Darwin.stat()
        guard Darwin.fstat(файл, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG,
              сведения.st_size >= 0, сведения.st_size <= предел else { throw ОтказПереводаСвифта.вход }
        var байты = Data()
        var буфер = [UInt8](repeating: 0, count: 8192)
        while true {
            let запрос = min(буфер.count, предел + 1 - байты.count)
            let число = буфер.withUnsafeMutableBytes { Darwin.read(файл, $0.baseAddress, запрос) }
            if число < 0 {
                if errno == EINTR { continue }
                throw ОтказПереводаСвифта.вход
            }
            if число == 0 { return байты }
            байты.append(contentsOf: буфер.prefix(число))
            guard байты.count <= предел else { throw ОтказПереводаСвифта.вход }
        }
    }
}
