import Darwin
import Foundation

public enum ОшибкаЖурналаНаблюдений: Error, Equatable, Sendable {
    case небезопасныйПуть
    case невалидныйJSON
    case открытие(Int32)
    case запись(Int32)
    case синхронизация(Int32)
}

/// Один писатель долговечного JSONL-файла наблюдений.
///
/// Вызов дописывает целую строку, синхронизирует файл и затем его каталог.
/// Блокировки намеренно не скрываются: владелец дерева обязан обеспечить один
/// писатель для конкретного файла памяти.
public struct ЖурналНаблюдений: Sendable {
    public init() {}

    public func добавитьJSONСтроку(_ payload: [String: Any], в путь: URL) throws {
        guard JSONSerialization.isValidJSONObject(payload) else {
            throw ОшибкаЖурналаНаблюдений.невалидныйJSON
        }
        let данные = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try добавитьJSONСтроку(данные, в: путь)
    }

    public func добавитьJSONСтроку(_ данные: Data, в путь: URL) throws {
        guard путь.isFileURL, путь.path.hasPrefix("/"), !путь.path.utf8.contains(0),
              !путь.pathComponents.contains("..") else {
            throw ОшибкаЖурналаНаблюдений.небезопасныйПуть
        }

        var строка = данные
        if строка.last != 0x0A {
            строка.append(0x0A)
        }

        do {
            try FileManager.default.createDirectory(
                at: путь.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw ОшибкаЖурналаНаблюдений.открытие(Int32((error as NSError).code))
        }

        let дескриптор = Darwin.open(
            путь.path,
            O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC | O_NOFOLLOW,
            S_IRUSR | S_IWUSR
        )
        guard дескриптор >= 0 else {
            throw ОшибкаЖурналаНаблюдений.открытие(errno)
        }
        defer { Darwin.close(дескриптор) }

        try строка.withUnsafeBytes { буфер in
            guard let адрес = буфер.baseAddress else { return }
            var смещение = 0
            while смещение < буфер.count {
                let число = Darwin.write(дескриптор, адрес.advanced(by: смещение), буфер.count - смещение)
                if число < 0 {
                    if errno == EINTR { continue }
                    throw ОшибкаЖурналаНаблюдений.запись(errno)
                }
                guard число > 0 else {
                    throw ОшибкаЖурналаНаблюдений.запись(EIO)
                }
                смещение += число
            }
        }

        guard fsync(дескриптор) == 0 else {
            throw ОшибкаЖурналаНаблюдений.синхронизация(errno)
        }
        try синхронизироватьКаталог(путь.deletingLastPathComponent())
    }

    private func синхронизироватьКаталог(_ путь: URL) throws {
        let дескриптор = Darwin.open(путь.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard дескриптор >= 0 else {
            throw ОшибкаЖурналаНаблюдений.открытие(errno)
        }
        defer { Darwin.close(дескриптор) }
        guard fsync(дескриптор) == 0 else {
            throw ОшибкаЖурналаНаблюдений.синхронизация(errno)
        }
    }
}
