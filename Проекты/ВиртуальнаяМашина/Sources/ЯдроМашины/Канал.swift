import Foundation
import Darwin
import CryptoKit

public enum Канал {
    private static func ожидать(_ файл: Int32, событие: Int32, до: UInt64) throws {
        while true {
            let сейчас = DispatchTime.now().uptimeNanoseconds
            guard сейчас < до else { throw ОшибкаМашины("Общий срок управляющей операции истёк.") }
            var запись = pollfd(fd: файл, events: Int16(событие), revents: 0)
            let код = poll(&запись, 1, Int32(min((до - сейчас) / 1_000_000 + 1, UInt64(Int32.max))))
            if код < 0 && errno == EINTR { continue }
            guard код > 0, запись.revents & Int16(POLLNVAL) == 0 else { throw ОшибкаМашины("Управляющий канал недоступен или превысил общий срок.") }
            return
        }
    }
    public static func настроить(_ файл: Int32, ожидание: Int = 5) {
        let флаги = fcntl(файл, F_GETFL)
        if флаги >= 0 { _ = fcntl(файл, F_SETFL, флаги & ~O_NONBLOCK) }
        var единица: Int32 = 1
        setsockopt(файл, SOL_SOCKET, SO_NOSIGPIPE, &единица, socklen_t(MemoryLayout.size(ofValue: единица)))
        var время = timeval(tv_sec: ожидание, tv_usec: 0)
        setsockopt(файл, SOL_SOCKET, SO_RCVTIMEO, &время, socklen_t(MemoryLayout.size(ofValue: время)))
        setsockopt(файл, SOL_SOCKET, SO_SNDTIMEO, &время, socklen_t(MemoryLayout.size(ofValue: время)))
        _ = fcntl(файл, F_SETFD, FD_CLOEXEC)
    }
    public static func адрес(_ порт: UInt16) -> sockaddr_in {
        var адрес = sockaddr_in()
        адрес.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        адрес.sin_family = sa_family_t(AF_INET)
        адрес.sin_port = порт.bigEndian
        адрес.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        return адрес
    }
    public static func соединиться(_ порт: UInt16) throws -> Int32 {
        guard порт > 0 else { throw ОшибкаМашины("Неверный порт управления.") }
        let файл = socket(AF_INET, SOCK_STREAM, 0)
        guard файл >= 0 else { throw ОшибкаМашины("Не удалось открыть управляющий канал.") }
        настроить(файл)
        guard fcntl(файл, F_SETFL, O_NONBLOCK) == 0 else { close(файл); throw ОшибкаМашины("Не удалось ограничить соединение по времени.") }
        var цель = адрес(порт)
        let код = withUnsafePointer(to: &цель) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.connect(файл, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        do {
            if код != 0 {
                guard errno == EINPROGRESS else { throw ОшибкаМашины("Процесс VM недоступен; сохранённый PID не используется для управления.") }
                try ожидать(файл, событие: POLLOUT, до: DispatchTime.now().uptimeNanoseconds + 5_000_000_000)
                var ошибка: Int32 = 0, длина = socklen_t(MemoryLayout<Int32>.size)
                guard getsockopt(файл, SOL_SOCKET, SO_ERROR, &ошибка, &длина) == 0, ошибка == 0 else { throw ОшибкаМашины("Соединение с процессом VM отклонено.") }
            }
            настроить(файл)
        } catch { close(файл); throw error }
        return файл
    }
    public static func записать(_ файл: Int32, _ данные: Data, до: UInt64? = nil) throws {
        try данные.withUnsafeBytes { буфер in
            var смещение = 0
            while смещение < буфер.count {
                if let до { try ожидать(файл, событие: POLLOUT, до: до) }
                let число = до == nil ? Darwin.write(файл, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
                    : Darwin.send(файл, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение, MSG_DONTWAIT)
                if число < 0 && errno == EINTR { continue }
                if число < 0 && errno == EAGAIN && до != nil { continue }
                guard число > 0 else { throw ОшибкаМашины("Запись в канал прервана или превысила ожидание.") }
                смещение += число
            }
        }
    }
    private static func прочитать(_ файл: Int32, _ размер: Int, до: UInt64) throws -> Data {
        var данные = Data(count: размер)
        try данные.withUnsafeMutableBytes { буфер in
            var смещение = 0
            while смещение < размер {
                try ожидать(файл, событие: POLLIN, до: до)
                let число = Darwin.recv(файл, буфер.baseAddress!.advanced(by: смещение), размер - смещение, MSG_DONTWAIT)
                if число < 0 && errno == EINTR { continue }
                if число < 0 && errno == EAGAIN { continue }
                guard число > 0 else { throw ОшибкаМашины("Управляющий кадр оборван или превысил ожидание.") }
                смещение += число
            }
        }
        return данные
    }
    public static func отправить(_ файл: Int32, _ данные: Data) throws {
        guard !данные.isEmpty, данные.count <= 65536 else { throw ОшибкаМашины("Управляющий кадр пуст или превышает 64 KiB.") }
        var размер = UInt32(данные.count).bigEndian
        let до = DispatchTime.now().uptimeNanoseconds + 5_000_000_000
        try записать(файл, withUnsafeBytes(of: &размер) { Data($0) }, до: до)
        try записать(файл, данные, до: до)
    }
    public static func получить(_ файл: Int32, предел: TimeInterval = 5) throws -> Data {
        guard предел > 0, предел <= 60, предел.isFinite else { throw ОшибкаМашины("Неверный общий срок кадра.") }
        let до = DispatchTime.now().uptimeNanoseconds + UInt64(предел * 1e9)
        let заголовок = try прочитать(файл, 4, до: до)
        let размер = заголовок.reduce(0) { ($0 << 8) | Int($1) }
        guard размер > 0 && размер <= 65536 else { throw ОшибкаМашины("Недопустимый размер управляющего кадра.") }
        return try прочитать(файл, размер, до: до)
    }
}

public final class Приёмник {
    public let порт: UInt16
    private let источник: DispatchSourceRead
    public init(_ обработать: @escaping (Int32) -> Void) throws {
        let файл = socket(AF_INET, SOCK_STREAM, 0)
        guard файл >= 0 else { throw ОшибкаМашины("Не удалось создать локальный приёмник.") }
        Канал.настроить(файл)
        var адрес = Канал.адрес(0)
        let код = withUnsafePointer(to: &адрес) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(файл, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard код == 0 && listen(файл, 16) == 0 else { close(файл); throw ОшибкаМашины("Не удалось занять собственный loopback-порт.") }
        var длина = socklen_t(MemoryLayout<sockaddr_in>.size)
        let чтение = withUnsafeMutablePointer(to: &адрес) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(файл, $0, &длина) }
        }
        guard чтение == 0 else { close(файл); throw ОшибкаМашины("Не удалось определить собственный порт.") }
        порт = UInt16(bigEndian: адрес.sin_port)
        _ = fcntl(файл, F_SETFL, O_NONBLOCK)
        источник = DispatchSource.makeReadSource(fileDescriptor: файл, queue: .main)
        источник.setEventHandler {
            for _ in 0..<16 {
                let клиент = accept(файл, nil, nil)
                if клиент < 0 { break }
                Канал.настроить(клиент)
                обработать(клиент)
            }
        }
        источник.setCancelHandler { close(файл) }
        источник.resume()
    }
    deinit { источник.cancel() }
}

// Секрет не передаётся по loopback: MAC связывает кадр и свежий запрос.
public enum ПодлинностьКанала {
    public static func подписать(_ данные: Data, ключ: String) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: данные, using: SymmetricKey(data: Data(ключ.utf8))))
    }
    public static func проверить(_ данные: Data, подпись: Data, ключ: String) throws {
        guard HMAC<SHA256>.isValidAuthenticationCode(подпись, authenticating: данные, using: SymmetricKey(data: Data(ключ.utf8))) else {
            throw ОшибкаМашины("Подлинность управляющего кадра не подтверждена.")
        }
    }
}

public struct КомандаМашине: Codable {
    var операция: String
    var запуск: String
    var одноразовое = UUID().uuidString.lowercased()
}
private struct ПодписанныйКадр: Codable { var данные: Data; var подпись: Data }

public enum УправлениеМашиной {
    public static func обратиться(_ запись: ЗапускМашины, операция: String) throws -> ЗапускМашины {
        let файл = try Канал.соединиться(запись.портУправления); defer { close(файл) }
        let команда = КомандаМашине(операция: операция, запуск: запись.запуск)
        let данные = try кодировать(команда)
        try Канал.отправить(файл, кодировать(ПодписанныйКадр(данные: данные, подпись: ПодлинностьКанала.подписать(данные, ключ: запись.токен))))
        let ответ = try JSONDecoder().decode(ПодписанныйКадр.self, from: Канал.получить(файл))
        try ПодлинностьКанала.проверить(Data(команда.одноразовое.utf8) + ответ.данные, подпись: ответ.подпись, ключ: запись.токен)
        let состояние = try JSONDecoder().decode(ЗапускМашины.self, from: ответ.данные)
        guard состояние.машина == запись.машина, состояние.план == запись.план, состояние.запуск == запись.запуск else {
            throw ОшибкаМашины("Ответ принадлежит другому запуску.")
        }
        return состояние
    }
    public static func принять(_ файл: Int32, запись: ЗапускМашины) throws -> КомандаМашине {
        let кадр = try JSONDecoder().decode(ПодписанныйКадр.self, from: Канал.получить(файл))
        try ПодлинностьКанала.проверить(кадр.данные, подпись: кадр.подпись, ключ: запись.токен)
        let команда = try JSONDecoder().decode(КомандаМашине.self, from: кадр.данные)
        guard команда.запуск == запись.запуск, UUID(uuidString: команда.одноразовое) != nil else { throw ОшибкаМашины("Устаревшая команда VM.") }
        return команда
    }
    public static func ответить(_ файл: Int32, команда: КомандаМашине, запись: ЗапускМашины) throws {
        var открытая = запись; открытая.токен = ""
        let данные = try кодировать(открытая)
        try Канал.отправить(файл, кодировать(ПодписанныйКадр(данные: данные,
            подпись: ПодлинностьКанала.подписать(Data(команда.одноразовое.utf8) + данные, ключ: запись.токен))))
    }
}
