import Foundation
import Darwin
import CryptoKit

private func повреждённыйКадр() -> Data {
    Data([0x7b, 0x22, 0xff]) + Data("FUM/повреждённый-кадр/0222".utf8)
}

private func хэшХвоста(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

private final class ТранспортСквозногоХвоста: ТранспортБиблиотеки, @unchecked Sendable {
    private let условие = NSCondition()
    private var очередь: [Data] = []
    private var счётчикСозданных = 0
    private var счётчикОтправок = 0
    private var счётчикПриёмов = 0
    private var повреждённыйВыдан = false
    let разрешён: Bool
    init(разрешён: Bool) { self.разрешён = разрешён }
    var счётчики: (Int, Int, Int) { условие.withLock { (счётчикСозданных, счётчикОтправок, счётчикПриёмов) } }
    var байтыСкопированы = false

    func создатьКлиента() -> Int32 {
        условие.withLock { счётчикСозданных += 1; return разрешён ? 1 : 0 }
    }
    func отправить(клиент: Int32, запрос: Data) throws {
        try условие.withLock {
            счётчикОтправок += 1
            guard разрешён, клиент == 1 else { throw ОшибкаКлиента.неподдерживаемоеДействие }
            let данные = try ЗначениеДанных.прочитать(запрос)
            if данные.тип == "close" { return }
            guard данные.тип == "getAuthorizationState", let корреляция = данные["@extra"] else {
                throw ОшибкаКлиента.неподдерживаемоеДействие
            }
            очередь.append(try ЗначениеДанных.типа("authorizationStateWaitTdlibParameters", [
                "@client_id": .число(1), "@extra": корреляция
            ]).байты())
            условие.broadcast()
        }
    }
    func выдатьПовреждённыйКадр() throws {
        try условие.withLock {
            guard !повреждённыйВыдан else { throw ОшибкаКлиента.требуетсяРазбор }
            повреждённыйВыдан = true
            очередь.append(повреждённыйКадр()); условие.broadcast()
        }
    }
    func принять(таймАут: Double) throws -> Data? {
        try условие.withLock {
            счётчикПриёмов += 1
            guard разрешён else { throw ОшибкаКлиента.неподдерживаемоеДействие }
            let предел = Date(timeIntervalSinceNow: таймАут)
            while очередь.isEmpty {
                guard условие.wait(until: предел) else { return nil }
            }
            let данные = очередь.removeFirst()
            var завершённые = данные; завершённые.append(0)
            let копия = try завершённые.withUnsafeBytes { байты in
                try скопироватьОтвет(байты.baseAddress!.assumingMemoryBound(to: CChar.self), предел: 4096)
            }
            if данные == повреждённыйКадр() { байтыСкопированы = копия == данные }
            return копия
        }
    }
    var точнаяКопия: Bool { условие.withLock { байтыСкопированы } }
}

private struct РезультатСквозногоХвоста: Encodable {
    let схема = "fum.сквозной-хвост.1"
    let фаза: String
    let процесс = getpid()
    let фикстураШа256 = хэшХвоста(повреждённыйКадр())
    let байтыСохранены: Bool
    var закрытие: ИтогЗакрытия?
    var повторЗакрытияСовпадает: Bool?
    var разрывов: Int?
    var неприменённыхКадров: Int?
    var чужойКлючОтклонён: Bool?
    var разрывВхода: Bool?
    var создано: Int?
    var отправлено: Int?
    var приёмов: Int?
    var сообщений: Int?
    var сегментНеИзменён: Bool?
}

private func прочитатьСегментХвоста(_ корень: URL) throws -> Data {
    try сПриватнымКаталогом(корень) { каталог, _ in
        let файл = openat(каталог, "сегмент.fumobs", O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаКлиента.требуетсяРазбор }
        defer { Darwin.close(файл) }
        var до = stat()
        guard fstat(файл, &до) == 0, до.st_mode & S_IFMT == S_IFREG, до.st_uid == geteuid(),
              до.st_mode & 0o7777 == 0o600, до.st_nlink == 1, (1...65536).contains(до.st_size) else {
            throw ОшибкаКлиента.требуетсяРазбор
        }
        try проверитьОтсутствиеРасширенногоДоступа(файл)
        var данные = Data(count: Int(до.st_size))
        try данные.withUnsafeMutableBytes { байты in
            var смещение = 0
            while смещение < байты.count {
                let число = pread(файл, байты.baseAddress!.advanced(by: смещение), байты.count - смещение, off_t(смещение))
                if число < 0, errno == EINTR { continue }
                guard число > 0 else { throw ОшибкаКлиента.требуетсяРазбор }
                смещение += число
            }
        }
        var после = stat(), имя = stat()
        guard fstat(файл, &после) == 0, fstatat(каталог, "сегмент.fumobs", &имя, AT_SYMLINK_NOFOLLOW) == 0,
              до.st_size == после.st_size, до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
              до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
              до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec, до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec,
              имя.st_dev == после.st_dev, имя.st_ino == после.st_ino else { throw ОшибкаКлиента.требуетсяРазбор }
        return данные
    }
}

private func проверитьЗаписиХвоста(корень: URL, ключ: Data) throws {
    let журнал = try ЛокальныйЖурнал(корень: корень, ключ: ключ); defer { журнал.закрыть() }
    let записи = try журнал.восстановить()
    guard записи.count == 2, case .разрыв = записи[0], case .неприменённые(let хвост) = записи[1],
          хвост == [повреждённыйКадр()] else { throw ОшибкаКлиента.требуетсяРазбор }
}

/// Два закрытых синтетических режима. Карантин аварийного фасада заканчивается только вместе с процессом.
package func проверитьСквознойХвост(каталог: URL, подготовка: Bool) async throws -> Data {
    let ключ = try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ")
    let корень = каталог.appendingPathComponent("журнал", isDirectory: true)
    _ = try идентичностьПриватногоКаталога(корень)
    if подготовка {
        guard try FileManager.default.contentsOfDirectory(atPath: корень.path).isEmpty else {
            throw ОшибкаКлиента.неверныеДанные("Подготовке нужен пустой приватный журнал")
        }
        let транспорт = ТранспортСквозногоХвоста(разрешён: true)
        let среда = try await СредаКлиента.начать(транспорт: транспорт, корень: корень, ключ: ключ)
        do {
            let клиент = try await среда.добавитьКлиента()
            _ = try await среда.дождатьсяНачальногоОтвета(клиент, таймАут: 2)
            try транспорт.выдатьПовреждённыйКадр()
            let предел = ContinuousClock.now + .seconds(2)
            while !(await среда.ядро.разрывВхода), ContinuousClock.now < предел {
                try await Task.sleep(for: .milliseconds(1))
            }
            guard await среда.ядро.разрывВхода else { throw ОшибкаКлиента.требуетсяРазбор }
            let первый = try await среда.закрыть(таймАут: 2)
            let второй = try await среда.закрыть(таймАут: 2)
            guard первый == второй, первый.потокиЗавершены, !первый.всеЗакрыты, первый.требуетсяРазбор,
                  первый.неприменённыхКадров == 1, транспорт.точнаяКопия else { throw ОшибкаКлиента.требуетсяРазбор }
            try проверитьЗаписиХвоста(корень: корень, ключ: ключ)
            return try кодироватьЛокально(РезультатСквозногоХвоста(фаза: "подготовить", байтыСохранены: true,
                закрытие: первый, повторЗакрытияСовпадает: true))
        } catch { _ = try? await среда.закрыть(таймАут: 2); throw error }
    }
    // Наличие и ограниченный размер проверяются до инициализации: отсутствующий журнал нельзя создать при чтении.
    let до = try прочитатьСегментХвоста(корень)
    try проверитьЗаписиХвоста(корень: корень, ключ: ключ)
    var чужойКлюч = ключ; чужойКлюч[0] ^= 1
    let чужойЖурнал = try ЛокальныйЖурнал(корень: корень, ключ: чужойКлюч)
    var чужойОтклонён = false
    do { _ = try чужойЖурнал.восстановить() } catch { чужойОтклонён = true }
    чужойЖурнал.закрыть()
    guard чужойОтклонён else { throw ОшибкаКлиента.требуетсяРазбор }
    let транспорт = ТранспортСквозногоХвоста(разрешён: false)
    let ядро = try ЯдроКлиента(транспорт: транспорт, корень: корень, ключ: ключ)
    let разрыв = await ядро.разрывВхода
    let модель = await ядро.получитьМодельСообщений()
    await ядро.закрытьЖурнал()
    let после = try прочитатьСегментХвоста(корень)
    let счётчики = транспорт.счётчики
    guard разрыв, модель.история.isEmpty, счётчики == (0, 0, 0), до == после else { throw ОшибкаКлиента.требуетсяРазбор }
    return try кодироватьЛокально(РезультатСквозногоХвоста(фаза: "восстановить", байтыСохранены: true,
        разрывов: 1, неприменённыхКадров: 1, чужойКлючОтклонён: true, разрывВхода: разрыв,
        создано: счётчики.0, отправлено: счётчики.1, приёмов: счётчики.2, сообщений: модель.история.count, сегментНеИзменён: true))
}
