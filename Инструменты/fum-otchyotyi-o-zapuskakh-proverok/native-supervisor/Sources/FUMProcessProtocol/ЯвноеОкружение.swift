/// Точное байтовое окружение POSIX: записи KEY=VALUE завершаются NUL.
/// Содержимое не выводится; источником и удержанием FD владеет вызывающий.
public struct ЯвноеОкружение: Equatable, Sendable {
    public let записи: [[UInt8]]

    public init?(_ байты: [UInt8]) {
        guard байты.count <= 65_536 else { return nil }
        if байты.isEmpty { записи = []; return }
        guard байты.last == 0 else { return nil }
        var результат: [[UInt8]] = []
        var имена = Set<[UInt8]>()
        var начало = 0
        for (индекс, байт) in байты.enumerated() where байт == 0 {
            guard индекс > начало, результат.count < 256 else { return nil }
            let запись = Array(байты[начало..<индекс])
            guard let равно = запись.firstIndex(of: 61), равно > 0 else { return nil }
            let имя = Array(запись[..<равно])
            guard имена.insert(имя).inserted else { return nil }
            результат.append(запись)
            начало = индекс + 1
        }
        guard начало == байты.count else { return nil }
        записи = результат
    }
}
