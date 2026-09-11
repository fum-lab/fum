import Foundation
import Darwin
import CryptoKit

/// Изолированная байтовая граница: LF, бюджеты и SHA. Семантика JSONL находится снаружи.
func прочитатьПрефикс(_ источник: URL, бюджет: БюджетАрхива,
                      прежняя: ГраницаПрефикса?,
                      принять: (Data, ПозицияСтроки) throws -> Void) throws -> (ГраницаПрефикса, Int) {
    guard источник.isFileURL, !источник.path.utf8.contains(0),
          источник.standardizedFileURL.path == источник.resolvingSymlinksInPath().standardizedFileURL.path else {
        throw ОшибкаАрхива.небезопасныйИсточник
    }
    let дескриптор = open(источник.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
    guard дескриптор >= 0 else { throw ОшибкаАрхива.система(errno) }
    defer { _ = close(дескриптор) }
    var исходный = stat()
    guard fstat(дескриптор, &исходный) == 0 else { throw ОшибкаАрхива.система(errno) }
    guard исходный.st_mode & S_IFMT == S_IFREG else { throw ОшибкаАрхива.небезопасныйИсточник }
    guard исходный.st_size <= бюджет.байты else { throw ОшибкаАрхива.предел }
    if let прежняя, исходный.st_size < прежняя.байты { throw ОшибкаАрхива.подменаПрефикса }
    var буфер = [UInt8](repeating: 0, count: 256 * 1024)
    var строка = Data()
    var счётчик = SHA256()
    var байты = 0
    var прочитано = 0
    var строки = 0
    var пик = 0
    var проверен = прежняя == nil
    while true {
        let число = read(дескриптор, &буфер, буфер.count)
        if число < 0 && errno == EINTR { continue }
        guard число >= 0 else { throw ОшибкаАрхива.система(errno) }
        if число == 0 { break }
        guard число <= бюджет.байты - прочитано else { throw ОшибкаАрхива.предел }
        прочитано += число
        var начало = 0
        for место in 0..<число where буфер[место] == 10 {
            guard место + 1 - начало <= бюджет.строка - строка.count else { throw ОшибкаАрхива.предел }
            строка.append(contentsOf: буфер[начало...место])
            пик = max(пик, строка.count)
            строки += 1
            guard строки <= бюджет.строки else { throw ОшибкаАрхива.предел }
            let конец = байты + строка.count
            счётчик.update(data: строка)
            if let прежняя, !проверен, конец >= прежняя.байты {
                guard конец == прежняя.байты, строки == прежняя.строки,
                      счётчик.finalize().map({ String(format: "%02x", $0) }).joined() == прежняя.sha256 else {
                    throw ОшибкаАрхива.подменаПрефикса
                }
                проверен = true
            }
            let позиция = ПозицияСтроки(номер: строки, начало: байты, конец: конец, sha256: хэшАрхива(строка))
            try принять(строка, позиция)
            байты = конец
            строка.removeAll(keepingCapacity: true)
            начало = место + 1
        }
        if начало < число {
            guard число - начало <= бюджет.строка - строка.count else { throw ОшибкаАрхива.предел }
            строка.append(contentsOf: буфер[начало..<число]); пик = max(пик, строка.count)
        }
    }
    guard проверен else { throw ОшибкаАрхива.подменаПрефикса }
    var конечный = stat(); var путь = stat()
    guard fstat(дескриптор, &конечный) == 0, lstat(источник.path, &путь) == 0 else { throw ОшибкаАрхива.источникИзменился }
    guard исходный.st_dev == путь.st_dev, исходный.st_ino == путь.st_ino,
          исходный.st_size == конечный.st_size, прочитано == исходный.st_size,
          исходный.st_mtimespec.tv_sec == конечный.st_mtimespec.tv_sec,
          исходный.st_mtimespec.tv_nsec == конечный.st_mtimespec.tv_nsec,
          исходный.st_ctimespec.tv_sec == конечный.st_ctimespec.tv_sec,
          исходный.st_ctimespec.tv_nsec == конечный.st_ctimespec.tv_nsec else { throw ОшибкаАрхива.источникИзменился }
    return (ГраницаПрефикса(байты: байты, строки: строки,
        sha256: счётчик.finalize().map { String(format: "%02x", $0) }.joined()), пик)
}
