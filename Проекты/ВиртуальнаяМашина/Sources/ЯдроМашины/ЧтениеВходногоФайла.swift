import Foundation
import Darwin

// Внутренняя граница системных вызовов для воспроизводимой проверки роста и замены файла.
struct ОперацииВходногоФайла {
    var открыть: (String, Int32) -> Int32
    var свойства: (Int32, UnsafeMutablePointer<stat>) -> Int32
    var читать: (Int32, UnsafeMutableRawPointer, Int) -> Int
    var закрыть: (Int32) -> Int32
}

public enum ЧтениеВходногоФайла {
    public static func прочитать<Значение: Decodable>(_ тип: Значение.Type, _ путь: String) throws -> Значение {
        try прочитать(тип, путь, операции: ОперацииВходногоФайла(
            открыть: { Darwin.open($0, $1) }, свойства: { Darwin.fstat($0, $1) },
            читать: { Darwin.read($0, $1, $2) }, закрыть: { Darwin.close($0) }))
    }

    static func прочитать<Значение: Decodable>(_ тип: Значение.Type, _ путь: String,
                                               операции: ОперацииВходногоФайла) throws -> Значение {
        guard !путь.contains("\0") else { throw ОшибкаМашины("Путь входного JSON содержит NUL.") }
        let адрес = NSString(string: путь).expandingTildeInPath
        let файл = операции.открыть(адрес, O_RDONLY | O_NONBLOCK | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаМашины("Не удалось открыть входной JSON (errno \(errno)).") }
        defer { _ = операции.закрыть(файл) }
        var сведения = stat()
        guard операции.свойства(файл, &сведения) == 0 else {
            throw ОшибкаМашины("Не удалось проверить входной JSON (errno \(errno)).")
        }
        guard сведения.st_mode & S_IFMT == S_IFREG else { throw ОшибкаМашины("Входной JSON должен быть обычным файлом.") }
        let предел = 4 * 1024 * 1024
        guard сведения.st_size >= 0, сведения.st_size <= off_t(предел) else {
            throw ОшибкаМашины("Входной JSON превышает 4 MiB.")
        }
        var байты = Data(), буфер = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let размер = min(буфер.count, предел + 1 - байты.count)
            let число = буфер.withUnsafeMutableBytes { память in
                операции.читать(файл, память.baseAddress!, размер)
            }
            if число < 0 {
                if errno == EINTR { continue }
                throw ОшибкаМашины("Не удалось прочитать входной JSON (errno \(errno)).")
            }
            if число == 0 { break }
            guard число <= размер else { throw ОшибкаМашины("Чтение входного JSON вернуло неверное число байтов.") }
            байты.append(contentsOf: буфер.prefix(число))
            guard байты.count <= предел else { throw ОшибкаМашины("Входной JSON превышает 4 MiB.") }
        }
        return try JSONDecoder().decode(тип, from: байты)
    }
}
