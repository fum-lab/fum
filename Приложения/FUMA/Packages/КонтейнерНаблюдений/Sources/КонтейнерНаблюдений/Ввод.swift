import Foundation
import Darwin

/// Явный обычный входной файл; размер проверяется до выделения памяти.
public func прочитатьВход(_ путь: String, предел: Int = Int(Пределы.объект)) throws -> Data {
    guard предел >= 0, предел <= Пределы.объект else { throw ОшибкаКонтейнера.предел }
    guard путь.hasPrefix("/"), !путь.utf8.contains(0) else { throw ОшибкаКонтейнера.небезопасныйПуть }
    let дескриптор = Darwin.open(путь, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
    guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
    defer { _ = Darwin.close(дескриптор) }
    let размер = try размерФайла(дескриптор)
    guard размер <= предел else { throw ОшибкаКонтейнера.предел }
    var данные = Data()
    данные.reserveCapacity(размер)
    var смещение = 0
    while смещение < размер {
        let длина = min(Пределы.фрагмент, размер - смещение)
        данные.append(try прочитать(дескриптор, смещение, длина))
        смещение += длина
    }
    guard try размерФайла(дескриптор) == размер else { throw ОшибкаКонтейнера.повреждение }
    return данные
}

public func вывестиJSON<Значение: Encodable>(_ значение: Значение) throws {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var данные = try кодировщик.encode(значение); данные.append(10)
    try FileHandle.standardOutput.write(contentsOf: данные)
}
