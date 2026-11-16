import Darwin

enum ОшибкаСбораПотоков: Error {
    case неверныйВход
    case системная([[UInt8]]), срок([[UInt8]]), переполнение([[UInt8]])
}

// Экспериментальная функция не владеет дескрипторами и не управляет процессами.
func собратьПотоки(_ дескрипторы: [Int32], пределы: [Int], край: UInt64) throws -> [[UInt8]] {
    guard !дескрипторы.isEmpty, дескрипторы.count <= 3, дескрипторы.count == пределы.count,
          Set(дескрипторы).count == дескрипторы.count,
          дескрипторы.allSatisfy({ $0 >= 0 }), пределы.allSatisfy({ $0 >= 0 && $0 <= 131_072 }), край > 0 else {
        throw ОшибкаСбораПотоков.неверныйВход
    }
    var опрос = [pollfd](), закрыты = [Bool](repeating: false, count: дескрипторы.count)
    var результат = [[UInt8]](repeating: [], count: дескрипторы.count)
    for дескриптор in дескрипторы {
        let флаги = fcntl(дескриптор, F_GETFL)
        guard флаги >= 0, флаги & O_NONBLOCK != 0 else { throw ОшибкаСбораПотоков.неверныйВход }
        опрос.append(pollfd(fd: дескриптор, events: Int16(POLLIN | POLLHUP), revents: 0))
    }
    var предыдущее: UInt64 = 0
    func проверитьСрок() throws {
        let время = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        guard время > 0, время >= предыдущее, время < край else { throw ОшибкаСбораПотоков.срок(результат) }
        предыдущее = время
    }
    while закрыты.contains(false) {
        try проверитьСрок()
        let код = опрос.withUnsafeMutableBufferPointer { poll($0.baseAddress, nfds_t($0.count), 100) }
        if код < 0 && errno == EINTR { continue }
        guard код >= 0 else { throw ОшибкаСбораПотоков.системная(результат) }
        try проверитьСрок()
        for номер in опрос.indices where !закрыты[номер] && опрос[номер].revents != 0 {
            guard опрос[номер].revents & Int16(POLLERR | POLLNVAL) == 0 else { throw ОшибкаСбораПотоков.системная(результат) }
            let доступно = пределы[номер] - результат[номер].count
            var буфер = [UInt8](repeating: 0, count: min(4096, доступно + 1))
            let длина = буфер.withUnsafeMutableBytes { read(дескрипторы[номер], $0.baseAddress, $0.count) }
            if длина < 0 && (errno == EINTR || errno == EAGAIN) { continue }
            guard длина >= 0 else { throw ОшибкаСбораПотоков.системная(результат) }
            результат[номер].append(contentsOf: буфер.prefix(длина))
            try проверитьСрок()
            if длина == 0 { закрыты[номер] = true; опрос[номер].fd = -1; continue }
            guard длина <= доступно else { throw ОшибкаСбораПотоков.переполнение(результат) }
        }
    }
    return результат
}
