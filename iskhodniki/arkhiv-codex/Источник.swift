import Foundation
import Darwin
import КонтейнерНаблюдений

/// Прямой ограниченный read не удерживает autoreleased NSData всего импорта.
private final class ИсточникБайтов {
    private var дескриптор: Int32
    init(_ путь: URL) throws {
        дескриптор = Darwin.open(путь.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        guard дескриптор >= 0 else { throw ОшибкаКонтейнера.система(errno) }
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0, сведения.st_mode & S_IFMT == S_IFREG else {
            _ = Darwin.close(дескриптор); дескриптор = -1
            throw ОшибкаАрхиваКодекса.небезопасныйПуть
        }
    }
    deinit { if дескриптор >= 0 { _ = Darwin.close(дескриптор) } }
    func прочитать(_ предел: Int) throws -> Data {
        var данные = Data(count: предел)
        let число = try данные.withUnsafeMutableBytes { буфер in
            var число: Int
            repeat { число = Darwin.read(дескриптор, буфер.baseAddress, буфер.count) } while число < 0 && errno == EINTR
            guard число >= 0 else { throw ОшибкаКонтейнера.система(errno) }
            return число
        }
        данные.removeSubrange(число..<данные.count)
        return данные
    }
    func завершить() throws { let прежний = дескриптор; дескриптор = -1; try системноеЗакрытие(прежний) }
}

public struct СчётчикИмпорта: Equatable, Sendable {
    public let прочитаноПрефикса: UInt64
    public let прочитаноДобавки: UInt64
    public var прочитаноВсего: UInt64 { прочитаноПрефикса + прочитаноДобавки }
}

extension АрхивКодекса {
    /// Одна общая точная сверка старых байтов, затем приём добавки из того же fd.
    /// Наблюдение изменяемого файла не является атомарным snapshot живого писателя.
    public func импортировать(_ источник: URL) throws -> СчётчикИмпорта {
        try начатьОперацию(); defer { закончитьОперацию() }
        let файл = try ИсточникБайтов(источник)
        do {
            var префикс: UInt64 = 0, добавка: UInt64 = 0
            try обойтиИсходныеБайты { прежние in
                var данные = Data()
                while данные.count < прежние.count {
                    let часть = try файл.прочитать(прежние.count - данные.count)
                    префикс += UInt64(часть.count)
                    guard !часть.isEmpty else { throw ОшибкаАрхиваКодекса.источникИзменён }
                    данные.append(часть)
                }
                guard данные == прежние else { throw ОшибкаАрхиваКодекса.источникИзменён }
            }
            try подтвердитьСессию()
            while true {
                let данные = try файл.прочитать(пределПорции)
                if данные.isEmpty { break }
                добавка += UInt64(данные.count)
                try принятьЧасть(данные, смещение: сохранено)
            }
            try файл.завершить()
            return СчётчикИмпорта(прочитаноПрефикса: префикс, прочитаноДобавки: добавка)
        } catch { throw error }
    }
}
