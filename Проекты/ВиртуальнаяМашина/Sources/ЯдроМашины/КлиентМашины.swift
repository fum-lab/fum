import Foundation
import Darwin

public final class КлиентМашины {
    public let читатель: ЧтениеХранилища
    public init(_ каталог: String) throws { читатель = try ЧтениеХранилища(каталог) }
    public func запись() throws -> ЗапускМашины {
        let запись = try JSONDecoder().decode(ЗапускМашины.self, from: читатель.прочитать("запуск.json"))
        guard запись.машина == читатель.паспорт.идентификатор, запись.план == читатель.паспорт.план.отпечаток,
              UUID(uuidString: запись.запуск) != nil, запись.токен.count == 72 else { throw ОшибкаМашины("Неверные метаданные процесса VM.") }
        return запись
    }
    public func состояние() throws -> ЗапускМашины { try УправлениеМашиной.обратиться(запись(), операция: "состояние") }
    public func начать(_ исполняемыйФайл: String) throws -> ЗапускМашины {
        if let живой = try? состояние() { return живой }
        let прежний = try? запись().запуск
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: исполняемыйФайл)
        процесс.arguments = ["служить", "--каталог", читатель.паспорт.план.каталог]
        процесс.standardInput = FileHandle.nullDevice
        // Уникальный собственный лог: фоновый процесс не удерживает stdout вызывающей команды.
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent("fum-vm-launch-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let имя = "служба.log"
        guard let физический = realpath(временный.path, nil) else { throw ОшибкаМашины("Не удалось открыть личный каталог запуска.") }
        defer { free(физический) }
        let путьЛога = String(cString: физический) + "/" + имя
        let каталог = try открытьКаталог(String(cString: физический)); defer { close(каталог) }
        let файл = openat(каталог, имя, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard файл >= 0 else { throw ОшибкаМашины("Не удалось создать лог запуска.") }
        let лог = FileHandle(fileDescriptor: файл, closeOnDealloc: true)
        процесс.standardOutput = лог; процесс.standardError = лог
        try процесс.run()
        let начало = DispatchTime.now().uptimeNanoseconds
        while DispatchTime.now().uptimeNanoseconds - начало < 180_000_000_000 {
            if let живой = try? состояние(), живой.запуск != прежний, живой.фаза != "запускается" { return живой }
            if !процесс.isRunning { throw ОшибкаМашины("Служба завершилась до загрузки VM, код \(процесс.terminationStatus); диагностика: \(путьЛога).") }
            usleep(200_000)
        }
        throw ОшибкаМашины("Запуск не подтверждён за 180 с. Служба и диск сохранены; проверьте состояние и \(путьЛога).")
    }
    public func готовность() throws -> ЗапускМашины {
        let запись = try запись()
        _ = try УправлениеМашиной.обратиться(запись, операция: "готовность")
        let начало = DispatchTime.now().uptimeNanoseconds
        while DispatchTime.now().uptimeNanoseconds - начало < 1_200_000_000_000 {
            let текущее = try УправлениеМашиной.обратиться(запись, операция: "состояние")
            if текущее.фаза == "готова" { return текущее }
            if текущее.фаза == "работает", let причина = текущее.причина { throw ОшибкаМашины(причина) }
            guard текущее.фаза == "проверка готовности" else { throw ОшибкаМашины("VM изменила состояние во время проверки: \(текущее.фаза).") }
            sleep(2)
        }
        throw ОшибкаМашины("Готовность не подтверждена за 1200 с; VM сохранена для диагностики.")
    }
    public func остановить() throws -> ЗапускМашины {
        let запись = try запись()
        if запись.фаза == "остановлена" {
            // Терминальная запись принимается только вместе с освобождённым реальным замком.
            _ = try Хранилище(план: читатель.паспорт.план, создать: false)
            return запись
        }
        _ = try УправлениеМашиной.обратиться(запись, операция: "остановить")
        let начало = DispatchTime.now().uptimeNanoseconds
        while DispatchTime.now().uptimeNanoseconds - начало < 120_000_000_000 {
            let сохранённая = try self.запись()
            guard сохранённая.запуск == запись.запуск else { throw ОшибкаМашины("Во время остановки появился другой запуск.") }
            if сохранённая.фаза == "остановлена", (try? Хранилище(план: читатель.паспорт.план, создать: false)) != nil { return сохранённая }
            if сохранённая.фаза == "ошибка" { throw ОшибкаМашины(сохранённая.причина ?? "VM завершилась с ошибкой.") }
            usleep(200_000)
        }
        throw ОшибкаМашины("Штатная остановка не завершилась за 120 с. Процесс и замок сохранены; принудительное выключение не выполняется.")
    }
    public func ssh(_ команда: String?) throws -> Never {
        let живой = try состояние()
        let аргументы = ["/usr/bin/ssh", "-F", читатель.паспорт.план.каталог + "/идентичность/ssh_config", "-p", String(живой.портSSH), "fum"] + (команда.map { [$0] } ?? [])
        let указатели = аргументы.map { strdup($0)! }
        defer { указатели.forEach { free($0) } }
        var массив = указатели.map(Optional.some) + [nil]
        _ = массив.withUnsafeMutableBufferPointer { execv("/usr/bin/ssh", $0.baseAddress!) }
        throw ОшибкаМашины("Не удалось выполнить SSH.")
    }
}
