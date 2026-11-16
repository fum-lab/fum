import Foundation
import Darwin
@_silgen_name("kevent")
private func системныйKevent(_ queue: Int32, _ changes: UnsafePointer<kevent>?, _ changeCount: Int32, _ events: UnsafeMutablePointer<kevent>?, _ eventCount: Int32, _ timeout: UnsafePointer<timespec>?) -> Int32
import CryptoKit
import СистемныеВызовы

// Проверочная цель сравнивает начальный envp без вывода его содержимого.
private func ключСовпадает(_ запись: UnsafeMutablePointer<CChar>, _ ключ: String) -> Bool {
    var смещение = 0
    for байт in ключ.utf8 {
        if запись[смещение] != CChar(bitPattern: байт) { return false }
        смещение += 1
    }
    return запись[смещение] == 61
}

private func значениеСовпадает(_ запись: UnsafeMutablePointer<CChar>, _ значение: String) -> Bool {
    var смещение = 0
    for байт in значение.utf8 {
        if запись[смещение] != CChar(bitPattern: байт) { return false }
        смещение += 1
    }
    return запись[смещение] == 0
}

private func значениеСовпадаетСАргументом(
    _ запись: UnsafeMutablePointer<CChar>, _ аргумент: UnsafeMutablePointer<CChar>
) -> Bool {
    var смещение = 0
    while смещение < 1024 {
        if запись[смещение] != аргумент[смещение] { return false }
        if запись[смещение] == 0 { return true }
        смещение += 1
    }
    return false
}

private func корректныйИдентификатор(_ аргумент: UnsafeMutablePointer<CChar>) -> Bool {
    for индекс in 0..<36 {
        let байт = Int(аргумент[индекс])
        if байт == 0 { return false }
        if [8, 13, 18, 23].contains(индекс) {
            if байт != 45 { return false }
        } else if !(48...57).contains(байт) && !(97...102).contains(байт) {
            return false
        }
    }
    return аргумент[36] == 0
}

@_cdecl("ФУМПроверкаНачальнойСреды_main")
public func проверитьНачальнуюСреду(
    _ количество: Int32,
    _ аргументы: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ среда: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    if количество >= 2, let аргументы, let первый = аргументы[1] {
        let режим = String(cString: первый)
        if режим == "--проверить-shim" || режим == "--shim-target" {
            проверитьNoSignalShim()
        }
        if режим == "--проверить-owner-env" || режим == "--проверить-owner-group" {
            проверитьNoSignalOwnerEnv()
        }
        if ["--проверить-owner", "--owner-target", "--owner-target-fail", "--owner-target-wait"].contains(режим) {
            if #available(macOS 13.0, *) { проверитьNoSignalOwner() }
            return 40
        }
        if режим == "--witness8-descendant" {
            signal(SIGTERM, SIG_IGN)
            let line = "DESC \(getpid()) \(getpgrp())\n"
            guard line.utf8CString.withUnsafeBytes({ Darwin.write(STDOUT_FILENO, $0.baseAddress, $0.count-1) }) == line.utf8.count else { return 49 }
            while true { Darwin.pause() }
        }
        if ["--witness8-target", "--witness9-target", "--проверить-witness9", "--проверить-witness9-eof", "--проверить-witness9-alias", "--проверить-witness9-owner", "--проверить-witness8", "--witness8-target-overflow", "--проверить-witness8-overflow", "--witness8-target-timeout", "--проверить-witness8-timeout", "--witness8-target-descendant", "--проверить-witness8-descendant", "--проверить-witness8-descendant-exit"].contains(режим) {
            var args = [String]()
            for индекс in 0..<Int(количество) {
                guard let часть = аргументы[индекс] else { return 40 }
                args.append(String(cString: часть))
            }
            return режим.hasPrefix("--witness8-target") || режим == "--witness9-target" ? цельПрофиля(args) : профильWitness8(args)
        }
    }
    guard (количество == 2 || количество == 3), let аргументы, let идентификатор = аргументы[1],
          корректныйИдентификатор(идентификатор), let среда else { return 40 }
    var ключи = ["PATH", "LC_ALL", "GIT_OPTIONAL_LOCKS", "GIT_NO_LAZY_FETCH",
                 "GIT_NO_REPLACE_OBJECTS", "GIT_CONFIG_NOSYSTEM", "GIT_CONFIG_GLOBAL",
                 "GIT_ATTR_NOSYSTEM", "FUM_CHECK_RUN_ID"]
    let опорныйПуть = количество == 3 ? аргументы[2] : nil
    if количество == 3 {
        guard опорныйПуть != nil else { return 40 }
        ключи.append("TMPDIR")
    }
    let значения = ["/bin:/usr/bin", "C", "0", "1", "1", "1", "/dev/null", "1"]
    var проверено = Array(repeating: false, count: ключи.count)
    var индекс = 0
    while let запись = среда[индекс] {
        var совпадение: Int?
        for номер in ключи.indices {
            if ключСовпадает(запись, ключи[номер]) { совпадение = номер; break }
        }
        guard let совпадение, !проверено[совпадение] else { return 30 }
        проверено[совпадение] = true
        let значение = запись.advanced(by: ключи[совпадение].utf8.count + 1)
        let верно: Bool
        if совпадение == 8 {
            верно = значениеСовпадаетСАргументом(значение, идентификатор)
        } else if совпадение == 9, let опорныйПуть {
            верно = значениеСовпадаетСАргументом(значение, опорныйПуть)
        } else {
            верно = значениеСовпадает(значение, значения[совпадение])
        }
        guard верно else { return совпадение == 8 ? 33 : 32 }
        индекс += 1
        if индекс > ключи.count { return 30 }
    }
    return проверено.contains(false) ? 31 : 0
}

// Самостоятельный профиль синтетического транспорта .8; production-допуск не проверяет.
@discardableResult
private func сообщениеПрофиля(_ текст: String) -> Bool {
    let байты = Array((текст + "\n").utf8)
    return байты.withUnsafeBytes { область in
        Darwin.write(STDERR_FILENO, область.baseAddress, область.count) == область.count
    }
}

private func удержатьНеизвестныйПрофиль(_ причина: String, pid: pid_t, каталог: String,
                                       меткаКаталога: (UInt64, UInt64)?, полученные: [UInt8] = []) -> Never {
    let цифры = Array("0123456789abcdef".utf8)
    let hex = String(decoding: полученные.flatMap { [цифры[Int($0 >> 4)], цифры[Int($0 & 15)]] }, as: UTF8.self)
    let запись = "UNKNOWN: \(причина); pid=\(pid); fixture=\(каталог); frames=\(hex)"
    var подтверждена = false
    let каталогFD = меткаКаталога == nil ? -1 : каталог.withCString {
        Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    }
    if let меткаКаталога, каталогFD >= 0 {
        var открытая = stat(), именованная = stat()
        let кодИмени = каталог.withCString { Darwin.lstat($0, &именованная) }
        if Darwin.fstat(каталогFD, &открытая) == 0, кодИмени == 0,
           открытая.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
           именованная.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
           открытая.st_mode & 0o7777 == 0o700, именованная.st_mode & 0o7777 == 0o700,
           открытая.st_uid == getuid(), открытая.st_uid == именованная.st_uid,
           UInt64(exactly: открытая.st_dev) == меткаКаталога.0, открытая.st_ino == меткаКаталога.1,
           открытая.st_dev == именованная.st_dev, открытая.st_ino == именованная.st_ino {
            let fd = Darwin.openat(каталогFD, "UNKNOWN.DATA",
                                  O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            if fd >= 0 {
                let байты = Array((запись + "\n").utf8)
                let записано = байты.withUnsafeBytes { Darwin.write(fd, $0.baseAddress, $0.count) }
                let файлСинхронизирован = записано == байты.count && Darwin.fsync(fd) == 0
                let файлЗакрыт = Darwin.close(fd) == 0
                if файлСинхронизирован && файлЗакрыт { подтверждена = Darwin.fsync(каталогFD) == 0 }
            }
        }
        if Darwin.close(каталогFD) != 0 { подтверждена = false }
    }
    сообщениеПрофиля(запись + (подтверждена ? "; receipt=fsynced" : "; receipt=UNKNOWN"))
    while true { withExtendedLifetime(полученные) { _ = Darwin.sleep(60) } }
}

private func часыПрофиля() -> Int64? {
    var время = timespec()
    guard clock_gettime(CLOCK_UPTIME_RAW, &время) == 0, время.tv_sec >= 0 else { return nil }
    let (секунды, переполнение) = Int64(время.tv_sec).multipliedReportingOverflow(by: 1000)
    guard !переполнение else { return nil }
    let (значение, переполнение2) = секунды.addingReportingOverflow(Int64(время.tv_nsec) / 1_000_000)
    return переполнение2 ? nil : значение
}

private func обновитьСрокПрофиля(_ предыдущие: inout Int64, до: Int64) -> Int64? {
    guard let сейчас = часыПрофиля(), сейчас >= предыдущие, сейчас < до else { return nil }
    предыдущие = сейчас
    return сейчас
}

private func читатьПрофиль(_ fd: Int32, число: Int, до: Int64, сохранённые: inout [UInt8],
                           последниеЧасы: inout Int64) -> [UInt8]? {
    var результат = [UInt8]()
    while результат.count < число {
        guard let сейчас = обновитьСрокПрофиля(&последниеЧасы, до: до) else { return nil }
        var событие = pollfd(fd: fd, events: Int16(POLLIN | POLLHUP), revents: 0)
        let код = Darwin.poll(&событие, 1, Int32(min(до - сейчас, 100)))
        guard код >= 0 else { return nil }
        if код == 0 { continue }
        guard событие.revents & Int16(POLLIN | POLLHUP) != 0 else { return nil }
        var буфер = [UInt8](repeating: 0, count: число - результат.count)
        let принято = буфер.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress, $0.count) }
        guard принято > 0 else { return nil }
        результат.append(contentsOf: буфер.prefix(принято))
        сохранённые.append(contentsOf: буфер.prefix(принято))
    }
    return результат
}

private func конецПрофиля(_ fd: Int32, до: Int64, сохранённые: inout [UInt8],
                          последниеЧасы: inout Int64) -> Bool {
    while let сейчас = обновитьСрокПрофиля(&последниеЧасы, до: до) {
        var событие = pollfd(fd: fd, events: Int16(POLLIN | POLLHUP), revents: 0)
        let код = Darwin.poll(&событие, 1, Int32(min(до - сейчас, 100)))
        guard код >= 0 else { return false }
        if код == 0 { continue }
        guard событие.revents & Int16(POLLIN | POLLHUP) != 0 else { return false }
        var байт: UInt8 = 0
        let принято = Darwin.read(fd, &байт, 1)
        if принято == 1 { сохранённые.append(байт) }
        return принято == 0
    }
    return false
}

private func ждатьПрофиль(_ pid: pid_t, до: Int64, последниеЧасы: inout Int64) -> Int32? {
    while обновитьСрокПрофиля(&последниеЧасы, до: до) != nil {
        var статус: Int32 = 0
        let ответ = Darwin.waitpid(pid, &статус, WNOHANG)
        if ответ == pid { return статус }
        if ответ != 0 { return nil }
        _ = Darwin.usleep(10_000)
    }
    return nil
}

private func командаПрофиля(_ fd: Int32, _ байт: UInt8) -> Bool {
    var копия = байт
    return Darwin.write(fd, &копия, 1) == 1
}

private func словоПрофиля(_ байты: [UInt8], _ начало: Int) -> UInt32 {
    байты[начало..<(начало + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
}

private func цельПрофиля(_ args: [String]) -> Int32 {
    guard args.count == 9 else { return 40 }
    // Только собственный каталог фикстуры; запись предшествует проверке B.
    let prefix = "/private/tmp/fum-witness8-swift."
    let suffix = "/target.DATA"
    guard args[2].hasPrefix(prefix), args[2].hasSuffix(suffix) else { return 41 }
    let каталог = String(args[2].dropLast(suffix.count))
    let хвост = каталог.dropFirst(prefix.count)
    guard хвост.utf8.count == 8, хвост.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
    }) else { return 41 }
    let каталогFD = каталог.withCString { Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC) }
    var меткаКаталога = stat()
    guard каталогFD > 2, Darwin.fstat(каталогFD, &меткаКаталога) == 0,
          меткаКаталога.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
          меткаКаталога.st_mode & 0o7777 == 0o700, меткаКаталога.st_uid == getuid() else { return 41 }
    let marker = Darwin.openat(каталогFD, "target.DATA", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard marker >= 0 else { return 41 }
    var байт: UInt8 = 1
    guard Darwin.write(marker, &байт, 1) == 1, Darwin.close(marker) == 0,
          Darwin.close(каталогFD) == 0 else { return 42 }
    guard let fd = Int32(args[3]), let dev = UInt64(args[4]), let ino = UInt64(args[5]),
          let чужойFD = Int32(args[6]), let чужойDev = UInt64(args[7]), let чужойIno = UInt64(args[8]),
          fd > 2, чужойFD > 2, fd != чужойFD,
          let получено = getenv(args[1] == "--witness9-target" ? "FUM_BORROWED_DIRECTORY_FD" : "FUM_BORROWED_ADMISSION_FD"),
          String(cString: получено) == args[3] else { return 43 }
    var опора = stat()
    guard Darwin.fstat(fd, &опора) == 0, UInt64(exactly: опора.st_dev) == dev, опора.st_ino == ino else { return 44 }
    var чужой = stat()
    let ответ = Darwin.fstat(чужойFD, &чужой)
    if ответ == 0 {
        guard UInt64(exactly: чужой.st_dev) != чужойDev || чужой.st_ino != чужойIno else { return 45 }
    } else if errno != EBADF { return 46 }
    let flags = Darwin.fcntl(fd, F_GETFD)
    guard flags >= 0, flags & FD_CLOEXEC == 0,
          Darwin.fcntl(fd, F_SETFD, flags | FD_CLOEXEC) == 0 else { return 47 }
    let итог = Darwin.fcntl(fd, F_GETFD)
    guard итог >= 0, итог & FD_CLOEXEC != 0 else { return 47 }
    if args[1] == "--witness8-target-descendant" {
        signal(SIGTERM, SIG_IGN)
        var child: pid_t = 0
        var argv = [strdup(args[0]), strdup("--witness8-descendant"), nil]
        var env: [UnsafeMutablePointer<CChar>?] = [nil]
        guard posix_spawn(&child, args[0], nil, nil, &argv, &env) == 0, child > 1 else { return 49 }
        while true { Darwin.pause() }
    }
    if args[1] == "--witness8-target-timeout" { while true { Darwin.pause() } }
    if args[1] == "--witness8-target-overflow" {
        let block = [UInt8](repeating: 65, count: 1024)
        while true {
            let out = block.withUnsafeBytes { Darwin.write(STDOUT_FILENO, $0.baseAddress, $0.count) }
            let err = block.withUnsafeBytes { Darwin.write(STDERR_FILENO, $0.baseAddress, $0.count) }
            if out <= 0 || err <= 0 { return 48 }
        }
    }
    let o: [UInt8] = [79, 85, 84, 10], e: [UInt8] = [69, 82, 82, 10]
    guard o.withUnsafeBytes({ Darwin.write(STDOUT_FILENO, $0.baseAddress, $0.count) }) == 4, e.withUnsafeBytes({ Darwin.write(STDERR_FILENO, $0.baseAddress, $0.count) }) == 4 else { return 48 }
    return 0
}

private func запуститьСлучайПрофиля(_ helper: String, _ witness: String, _ anchor: String,
                                    корректнаяОпора: Bool, переполнение: Bool, таймаут: Bool, потомок: Bool,
                                    наблюдатьВыход: Bool, каталогВместоФайла: Bool, закрытьДопуск: Bool,
                                    общаяОпора: Bool, квитанции: Int32?) -> Bool {
    var шаблон = Array("/private/tmp/fum-witness8-swift.XXXXXXXX".utf8CString)
    guard let указатель = mkdtemp(&шаблон) else { сообщениеПрофиля("FAIL mkdtemp"); return false }
    let каталог = String(cString: указатель)
    var dirFD: Int32 = -1, bFD: Int32 = -1, чужойFD: Int32 = -1, очередьВыхода: Int32 = -1
    var control = [Int32](repeating: -1, count: 2), status = [Int32](repeating: -1, count: 2)
    var output = [Int32](repeating: -1, count: 2), errors = [Int32](repeating: -1, count: 2)
    var pid: pid_t = 0
    var bВзят = false, terminal = false
    var меткаКаталога: (UInt64, UInt64)?
    var полученные = [UInt8]()
    func неизвестно(_ причина: String) -> Never {
        удержатьНеизвестныйПрофиль(причина, pid: terminal ? 0 : pid, каталог: каталог,
                                   меткаКаталога: меткаКаталога, полученные: полученные)
    }
    func закрыть(_ fd: inout Int32, _ имя: String) {
        let номер = fd
        fd = -1
        if номер >= 0, Darwin.close(номер) != 0 { неизвестно("close \(имя), fd=\(номер)") }
    }
    func освободить() {
        закрыть(&очередьВыхода, "exit kqueue")
        закрыть(&output[0], "output reader")
        закрыть(&output[1], "output writer")
        закрыть(&errors[0], "errors reader")
        закрыть(&errors[1], "errors writer")
        закрыть(&control[0], "control reader")
        закрыть(&control[1], "control writer")
        закрыть(&status[0], "status reader")
        закрыть(&status[1], "status writer")
        закрыть(&dirFD, "dir")
        закрыть(&чужойFD, "чужой FD")
        if bВзят {
            bВзят = false
            guard СистемныеВызовы.fum_flock(bFD, LOCK_UN) == 0 else { неизвестно("unlock B, fd=\(bFD)") }
        }
        закрыть(&bFD, "B")
    }
    func отказ(_ текст: String) -> Bool {
        if pid > 1 && !terminal { неизвестно(текст) }
        освободить()
        сообщениеПрофиля("FAIL: \(текст); fixture=\(каталог)")
        return false
    }
    let имяB = каталог + "/опора.DATA"
    let имяЧужого = каталог + "/чужой.DATA"
    let маркер = каталог + "/target.DATA"
    dirFD = каталог.withCString { Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC) }
    guard dirFD > 2 else { return отказ("открытие каталога") }
    var исходнаяМетка = stat()
    guard Darwin.fstat(dirFD, &исходнаяМетка) == 0,
          исходнаяМетка.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
          исходнаяМетка.st_mode & 0o7777 == 0o700, исходнаяМетка.st_uid == getuid(),
          let исходноеDev = UInt64(exactly: исходнаяМетка.st_dev), исходнаяМетка.st_ino > 0 else {
        неизвестно("не получена исходная метка каталога")
    }
    меткаКаталога = (исходноеDev, исходнаяМетка.st_ino)
    if каталогВместоФайла {
        guard имяB.withCString({ Darwin.mkdir($0, 0o700) }) == 0 else { return отказ("создание каталога B") }
        bFD = общаяОпора ? Darwin.dup(dirFD) : имяB.withCString { Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC) }
    } else {
        bFD = имяB.withCString { Darwin.open($0, O_RDONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600) }
    }
    guard bFD > 2 else { return отказ("создание B") }
    чужойFD = имяЧужого.withCString { Darwin.open($0, O_RDONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600) }
    guard чужойFD > 2 else { return отказ("создание постороннего FD") }
    var каталогStat = stat(), bStat = stat(), чужойStat = stat()
    guard Darwin.fstat(dirFD, &каталогStat) == 0, Darwin.fstat(bFD, &bStat) == 0,
          Darwin.fstat(чужойFD, &чужойStat) == 0,
          let dirDev = UInt64(exactly: каталогStat.st_dev), let bDev = UInt64(exactly: bStat.st_dev),
          let чужойDev = UInt64(exactly: чужойStat.st_dev) else { return отказ("опоры") }
    guard dirDev == исходноеDev, каталогStat.st_ino == исходнаяМетка.st_ino else {
        неизвестно("изменилась открытая опора каталога")
    }
    if СистемныеВызовы.fum_flock(bFD, LOCK_EX | LOCK_NB) != 0 {
        if errno == EWOULDBLOCK { return отказ("B занят") }
        неизвестно("flock B, fd=\(bFD)")
    }
    bВзят = true
    guard Darwin.pipe(&output) == 0, Darwin.pipe(&errors) == 0, Darwin.pipe(&control) == 0, Darwin.pipe(&status) == 0,
          Set(output + errors + control + status + [dirFD, bFD, чужойFD]).count == 11,
          (output + errors + control + status).allSatisfy({ $0 > 2 }) else { return отказ("pipe") }
    guard let старт = часыПрофиля() else { return отказ("часы") }
    var последниеЧасы = старт
    let (крайЗапуска, переполнение1) = старт.addingReportingOverflow(10_000)
    let (крайОпыта, переполнение2) = старт.addingReportingOverflow(20_000)
    guard !переполнение1, !переполнение2 else { return отказ("переполнение срока") }
    let id = "00112233-4455-4677-8899-aabbccddeeff"
    let idБайты: [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x46, 0x77,
                            0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]
    if let квитанции {
        var меткаКвитанций = stat()
        guard Darwin.fstat(квитанции, &меткаКвитанций) == 0,
              меткаКвитанций.st_dev != каталогStat.st_dev || меткаКвитанций.st_ino != каталогStat.st_ino,
              меткаКвитанций.st_dev != bStat.st_dev || меткаКвитанций.st_ino != bStat.st_ino,
              записатьКвитанциюВладельца(квитанции, "intent.DATA", "run=\(id) phase=before-spawn\n") else {
            return отказ("intent владельца")
        }
    }
    let inoB = корректнаяОпора || общаяОпора ? bStat.st_ino : (bStat.st_ino == 1 ? 2 : bStat.st_ino - 1)
    var argv = [witness, каталогВместоФайла ? "fum-run-witness.9" : "fum-run-witness.8", id, anchor,
                String(status[1]), "5000", "none", String(крайЗапуска), "5000",
                "--опора-старого-замка", каталог, String(dirFD), String(dirDev), String(каталогStat.st_ino),
                String(каталогStat.st_uid), String(каталогStat.st_mode & 0o7777),
                каталогВместоФайла ? "--опора-каталога" : "--опора-допуска", имяB, String(bFD), String(bDev), String(inoB),
                String(bStat.st_uid), String(bStat.st_mode & 0o7777), "--", helper,
                каталогВместоФайла ? "--witness9-target" : (потомок ? "--witness8-target-descendant" : (таймаут ? "--witness8-target-timeout" : (переполнение ? "--witness8-target-overflow" : "--witness8-target"))), маркер, String(bFD), String(bDev), String(bStat.st_ino),
                String(чужойFD), String(чужойDev), String(чужойStat.st_ino)]
    if таймаут { argv.insert(потомок ? "1500" : "250", at: 9) }
    var pointers: [UnsafeMutablePointer<CChar>?] = []
    defer { for указатель in pointers { free(указатель) } }
    for значение in argv {
        guard let указатель = strdup(значение) else { return отказ("память argv") }
        pointers.append(указатель)
    }
    pointers.append(nil)
    var actions: posix_spawn_file_actions_t?
    var attr: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&actions) == 0 else { return отказ("spawn actions init") }
    defer { _ = posix_spawn_file_actions_destroy(&actions) }
    guard posix_spawnattr_init(&attr) == 0 else { return отказ("spawn attributes init") }
    defer { _ = posix_spawnattr_destroy(&attr) }
    guard posix_spawn_file_actions_adddup2(&actions, control[0], STDIN_FILENO) == 0,
          posix_spawn_file_actions_adddup2(&actions, output[1], STDOUT_FILENO) == 0,
          posix_spawn_file_actions_adddup2(&actions, errors[1], STDERR_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, status[1]) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, dirFD) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, bFD) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, чужойFD) == 0,
          posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETSID)) == 0 else {
        return отказ("spawn actions")
    }
    var среда: [UnsafeMutablePointer<CChar>?] = [nil]
    let код = witness.withCString { путь in
        pointers.withUnsafeMutableBufferPointer { указатели in
            среда.withUnsafeMutableBufferPointer { env in
                posix_spawn(&pid, путь, &actions, &attr, указатели.baseAddress, env.baseAddress)
            }
        }
    }
    if код != 0 {
        pid = 0  // На Darwin ненулевой результат posix_spawn не создаёт ребёнка.
        return отказ("posix_spawn вернул \(код); POSIX_SPAWN_SETSID не обходится")
    }
    guard pid > 1 else { неизвестно("нет PID после spawn") }
    if let квитанции {
        guard записатьКвитанциюВладельца(квитанции, "owner.DATA",
            "run=\(id) witness=\(pid) phase=before-gate\n") else { неизвестно("owner receipt") }
    }
    сообщениеПрофиля("START: pid=\(pid); fixture=\(каталог)")
    закрыть(&control[0], "control reader")
    закрыть(&status[1], "status writer")
    закрыть(&output[1], "output writer")
    закрыть(&errors[1], "errors writer")
    var цельУспешна = true
    var итогПереполнения: String?
    if корректнаяОпора {
        guard let fua = читатьПрофиль(status[0], число: 24, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы),
              Array(fua.prefix(4)) == [0x46, 0x55, 0x41, 0x31], Array(fua[4..<20]) == idБайты else { неизвестно("FUA") }
        let anchorPID = словоПрофиля(fua, 20)
        guard let anchorЧисло = pid_t(exactly: anchorPID), anchorЧисло > 1, anchorЧисло != pid,
              Darwin.getpgid(pid) == pid, Darwin.getsid(pid) == pid,
              Darwin.getpgid(anchorЧисло) == anchorЧисло, Darwin.getsid(anchorЧисло) == pid else {
            неизвестно("SID/PGID свидетеля или якоря")
        }
        if закрытьДопуск {
            закрыть(&control[1], "gate EOF")
            guard конецПрофиля(status[0], до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы),
                  let сырой = ждатьПрофиль(pid, до: крайОпыта, последниеЧасы: &последниеЧасы) else { неизвестно("EOF/reap") }
            terminal = true
            var меткаМаркера = stat()
            let кодМаркера = маркер.withCString { Darwin.lstat($0, &меткаМаркера) }
            let ошибкаМаркера = errno
            guard сырой == (125 << 8), кодМаркера == -1, ошибкаМаркера == ENOENT else { return отказ("EOF outcome") }
            let кадры = полученные.map { String(format: "%02x", $0) }.joined()
            guard сообщениеПрофиля("EOF witness=\(pid) waitpid=\(pid) raw=\(сырой) marker_rc=\(кодМаркера) errno=\(ошибкаМаркера) frames=\(кадры)") else { неизвестно("EOF output") }
            освободить()
            guard имяЧужого.withCString({ Darwin.unlink($0) }) == 0,
                  имяB.withCString({ Darwin.rmdir($0) }) == 0,
                  каталог.withCString({ Darwin.rmdir($0) }) == 0 else { неизвестно("EOF cleanup") }
            return true
        }
        guard обновитьСрокПрофиля(&последниеЧасы, до: крайЗапуска) != nil else { неизвестно("срок перед G") }
        guard командаПрофиля(control[1], 0x47) else { неизвестно("G") }
        guard let fus = читатьПрофиль(status[0], число: таймаут ? 36 : 28, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы),
              Array(fus.prefix(4)) == [0x46, 0x55, 0x53, таймаут ? 0x32 : 0x31], Array(fus[4..<20]) == idБайты,
              словоПрофиля(fus, 20) == anchorPID else { неизвестно("FUS") }
        let targetPID = словоПрофиля(fus, 24)
        var стартЦели: Int64?
        if таймаут {
            let raw = fus[28..<36].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            guard let start = Int64(exactly: raw), let now = часыПрофиля(), start > 0, start <= now else { неизвестно("FUS time") }
            стартЦели = start
        }
        guard targetPID > 1, targetPID != anchorPID, targetPID != UInt32(pid) else { неизвестно("PID цели") }
        if переполнение || таймаут {
            // Изолированная fixture: контроль остаётся живым, пока не собраны кадр и EOF.
            var saved = [[UInt8]](repeating: [], count: 3)
            let fds = [status[0], output[0], errors[0]], limits = [37, 4096, 4096]
            var eof = [false, false, false], sent = false, exceeded = false, total = [0, 0, 0]
            var descendant: pid_t?
            while !eof.allSatisfy({ $0 }) {
                guard let now = обновитьСрокПрофиля(&последниеЧасы, до: крайОпыта) else { неизвестно("poll deadline") }
                var pollfds = (0..<3).map { pollfd(fd: eof[$0] ? -1 : fds[$0], events: Int16(POLLIN | POLLHUP), revents: 0) }
                let ready = Darwin.poll(&pollfds, 3, Int32(min(крайОпыта-now,100)))
                guard ready >= 0 else { неизвестно("poll errno=\(errno)") }
                if ready == 0 { continue }
                for i in 0..<3 where !eof[i] && pollfds[i].revents != 0 {
                    guard pollfds[i].revents & Int16(POLLERR | POLLNVAL) == 0 else { неизвестно("poll channel") }
                    var chunk = [UInt8](repeating: 0, count: 1024)
                    let count = Darwin.read(fds[i], &chunk, chunk.count)
                    guard count >= 0 else { неизвестно("read errno=\(errno)") }
                    if count == 0 { eof[i] = true; continue }
                    let (sum, overflowCount) = total[i].addingReportingOverflow(count)
                    guard !overflowCount else { неизвестно("counter overflow") }
                    total[i] = sum
                    let room = max(0, limits[i] - saved[i].count)
                    saved[i].append(contentsOf: chunk.prefix(min(count, room)))
                    if i == 0 { полученные.append(contentsOf: chunk.prefix(min(count, room))) }
                    if i == 1 && потомок && descendant == nil, let line = String(bytes: saved[1], encoding: .utf8), line.hasSuffix("\n") {
                        let pieces = line.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
                        guard pieces.count == 3, pieces[0] == "DESC", let child = pid_t(pieces[1]), let group = pid_t(pieces[2]), child > 1, child != pid_t(targetPID), group == pid_t(anchorPID), Darwin.getpgid(child) == group, Darwin.kill(child, 0) == 0 else { неизвестно("descendant identity") }
                        if наблюдатьВыход {
                            очередьВыхода = Darwin.kqueue()
                            guard очередьВыхода > 2 else { неизвестно("kqueue errno=\(errno)") }
                            var change = kevent()
                            change.ident = UInt(child); change.filter = Int16(EVFILT_PROC)
                            change.flags = UInt16(EV_ADD | EV_ENABLE | EV_ONESHOT); change.fflags = UInt32(NOTE_EXIT)
                            var instant = timespec(tv_sec: 0, tv_nsec: 0)
                            guard системныйKevent(очередьВыхода, &change, 1, nil, 0, &instant) == 0,
                                  Darwin.getpgid(child) == group, Darwin.kill(child, 0) == 0 else { неизвестно("exit registration") }
                        }
                        descendant = child
                    }
                    if count > room {
                        if i == 0 { неизвестно("status overflow") }
                        exceeded = true
                        if !sent { guard командаПрофиля(control[1], 0x45) else { неизвестно("interrupt E") }; sent = true }
                    }
                }
            }
            let fui = saved[0]
            guard (таймаут ? (!exceeded && !sent) : (exceeded && sent)), fui.count == 37, Array(fui.prefix(4)) == [0x46,0x55,таймаут ? 0x44 : 0x49,0x31],
                  Array(fui[4..<20]) == idБайты, словоПрофиля(fui,20) == anchorPID,
                  словоПрофиля(fui,24) == targetPID, словоПрофиля(fui,28) == UInt32(потомок ? SIGKILL : SIGTERM),
                  словоПрофиля(fui,32) == UInt32(SIGKILL), fui[36] == (таймаут ? 1 : 0x45) else { неизвестно("FUI") }
            цельУспешна = true
            var exitEvent = ""
            if наблюдатьВыход {
                guard let child = descendant, очередьВыхода > 2 else { неизвестно("exit watch absent") }
                var event = kevent(), instant = timespec(tv_sec: 0, tv_nsec: 0)
                guard системныйKevent(очередьВыхода, nil, 0, &event, 1, &instant) == 1,
                      event.ident == UInt(child), event.filter == Int16(EVFILT_PROC),
                      event.fflags & UInt32(NOTE_EXIT) != 0, event.flags & UInt16(EV_ERROR) == 0 else { неизвестно("exit event") }
                exitEvent = "; exit_pid=\(event.ident); exit_fflags=\(event.fflags); identity_rc=0; register_rc=0"
            }
            var timing = ""
            if таймаут {
                guard let start = стартЦели, let now = часыПрофиля(), now >= start, now - start >= (потомок ? 1500 : 250), !потомок || descendant != nil else { неизвестно("timeout duration") }
                timing = "; elapsed_ms=\(now-start); FUS=\(fus.map { String(format: "%02x", $0) }.joined()); descendant=\(descendant ?? 0)"
            }
            let hex = fui.map { String(format: "%02x", $0) }.joined()
            let hashes = saved.map { SHA256.hash(data: Data($0)).map { String(format: "%02x", $0) }.joined() }
            let prefixes = saved[1...2].map { $0.map { String(format: "%02x", $0) }.joined() }
            итогПереполнения = "PROVISIONAL \(таймаут ? "timeout" : "overflow E"); captured=\(saved[1].count),\(saved[2].count); total=\(total[1]),\(total[2]); sha256=\(hashes[1]),\(hashes[2]); FRAME=\(hex)\(timing)\(exitEvent); status_frames=\(полученные.map { String(format: "%02x", $0) }.joined()); stdout=\(prefixes[0]); stderr=\(prefixes[1])"
        } else {
            guard let fup = читатьПрофиль(status[0], число: 32, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы),
                  Array(fup.prefix(4)) == [0x46, 0x55, 0x50, 0x32], Array(fup[4..<20]) == idБайты else { неизвестно("FUP") }
            let targetStatus = словоПрофиля(fup, 20)
            guard let out = читатьПрофиль(output[0], число: 4, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы), out == [79,85,84,10], let err = читатьПрофиль(errors[0], число: 4, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы), err == [69,82,82,10] else { неизвестно("streams") }
            цельУспешна = targetStatus == 0
            guard обновитьСрокПрофиля(&последниеЧасы, до: крайОпыта) != nil else { неизвестно("срок перед C") }
            guard командаПрофиля(control[1], 0x43) else { неизвестно("C") }
            guard let fud = читатьПрофиль(status[0], число: 37, до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы),
                  Array(fud.prefix(4)) == [0x46, 0x55, 0x44, 0x31], Array(fud[4..<20]) == idБайты,
                  словоПрофиля(fud, 20) == anchorPID, словоПрофиля(fud, 24) == targetPID,
                  словоПрофиля(fud, 28) == targetStatus, словоПрофиля(fud, 32) == 9, fud[36] == 0 else { неизвестно("FUD") }
        }
    }
    guard конецПрофиля(status[0], до: крайОпыта, сохранённые: &полученные, последниеЧасы: &последниеЧасы), let завершение = ждатьПрофиль(pid, до: крайОпыта, последниеЧасы: &последниеЧасы) else {
        неизвестно("EOF или waitpid")
    }
    terminal = true
    let ожидаемыйСтатус: Int32 = корректнаяОпора ? 0 : (125 << 8)
    guard завершение == ожидаемыйСтатус else { return отказ("неожиданный terminal \(завершение)") }
    var маркерStat = stat()
    let маркерКод = маркер.withCString { Darwin.lstat($0, &маркерStat) }
    if корректнаяОпора {
        guard цельУспешна, маркерКод == 0, маркерStat.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG) else {
            return отказ("цель или её marker")
        }
    } else {
        guard маркерКод == -1, errno == ENOENT else { return отказ("цель запущена при неверной опоре") }
    }
    if общаяОпора {
        guard сообщениеПрофиля("alias witness=\(pid) waitpid=\(pid) raw=\(завершение) marker_rc=\(маркерКод) errno=\(errno) dirFD=\(dirFD) borrowedFD=\(bFD) dev=\(dirDev) inode=\(каталогStat.st_ino)") else { неизвестно("alias output") }
    }
    освободить()
    // Удаление имён допустимо лишь в собственном synthetic namespace без других писателей.
    if корректнаяОпора {
        guard маркер.withCString({ Darwin.unlink($0) }) == 0 else { неизвестно("unlink marker") }
    }
    guard имяЧужого.withCString({ Darwin.unlink($0) }) == 0 else { неизвестно("unlink чужой файл") }
    guard имяB.withCString({ каталогВместоФайла ? Darwin.rmdir($0) : Darwin.unlink($0) }) == 0 else { неизвестно("удаление B") }
    guard каталог.withCString({ Darwin.rmdir($0) }) == 0 else { неизвестно("rmdir fixture") }
    if let квитанции {
        guard записатьКвитанциюВладельца(квитанции, "terminal.DATA",
            "run=\(id) witness=\(pid) waitpid=\(pid) raw=\(завершение) outcome=PRE-CLOSE\n") else { неизвестно("terminal receipt") }
    }
    if let итогПереполнения { guard сообщениеПрофиля(итогПереполнения) else { неизвестно("печать результата") } }
    return сообщениеПрофиля("PROVISIONAL witness\(каталогВместоФайла ? "9" : "8") \(общаяОпора ? "alias" : (корректнаяОпора ? "B" : "неверный inode"))")
}

private func каталогФизическогоИсполняемогоФайла(_ путь: String, имя: String) -> String? {
    guard путь.hasPrefix("/"), путь.utf8.count < 1024,
          let разделитель = путь.lastIndex(of: "/"),
          String(путь[путь.index(after: разделитель)...]) == имя else { return nil }
    var метка = stat()
    guard путь.withCString({ Darwin.lstat($0, &метка) }) == 0,
          метка.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG),
          путь.withCString({ Darwin.access($0, X_OK) }) == 0 else { return nil }
    let физический = путь.withCString { вход in
        var buffer = [CChar](repeating: 0, count: 1024)
        return buffer.withUnsafeMutableBufferPointer { область in
            guard let начало = область.baseAddress, realpath(вход, начало) != nil else { return false }
            return strcmp(вход, начало) == 0
        }
    }
    return физический ? String(путь[..<разделитель]) : nil
}

private func профильWitness8(_ args: [String]) -> Int32 {
    var вывод = stat()
    let флагиВывода = Darwin.fcntl(STDERR_FILENO, F_GETFL)
    guard Darwin.fstat(STDERR_FILENO, &вывод) == 0,
          вывод.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG), вывод.st_nlink == 1,
          вывод.st_uid == getuid(), getuid() == geteuid(), флагиВывода >= 0,
          [O_WRONLY, O_RDWR].contains(флагиВывода & O_ACCMODE) else { return 40 }
    let сКвитанцией = args.count == 5 && args[1] == "--проверить-witness9-owner"
    guard (args.count == 4 || сКвитанцией),
          let каталог = каталогФизическогоИсполняемогоФайла(args[0], имя: "фум-проверка-начальной-среды"),
          каталогФизическогоИсполняемогоФайла(args[2], имя: "fum-anchor-witness") == каталог,
          каталогФизическогоИсполняемогоФайла(args[3], имя: "fum-process-anchor") == каталог else { return 40 }
    var игнорировать = sigaction()
    игнорировать.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&игнорировать.sa_mask) == 0, sigaction(SIGPIPE, &игнорировать, nil) == 0 else { return 40 }
    _ = Darwin.umask(0o077)
    let переполнение = args[1] == "--проверить-witness8-overflow"
    let наблюдатьВыход = args[1] == "--проверить-witness8-descendant-exit"
    let потомок = args[1] == "--проверить-witness8-descendant" || наблюдатьВыход
    let таймаут = args[1] == "--проверить-witness8-timeout" || потомок
    let закрытьДопуск = args[1] == "--проверить-witness9-eof"
    let общаяОпора = args[1] == "--проверить-witness9-alias"
    let каталогВместоФайла = args[1] == "--проверить-witness9" || закрытьДопуск || общаяОпора || сКвитанцией
    let квитанции = сКвитанцией ? args[4].withCString { Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC) } : -1
    if сКвитанцией && квитанции <= 2 { return 40 }
    defer { if квитанции >= 0 { _ = Darwin.close(квитанции) } }
    if общаяОпора {
        return запуститьСлучайПрофиля(args[0], args[2], args[3], корректнаяОпора: false, переполнение: false, таймаут: false, потомок: false, наблюдатьВыход: false, каталогВместоФайла: true, закрытьДопуск: false, общаяОпора: true, квитанции: nil) ? 0 : 1
    }
    guard запуститьСлучайПрофиля(args[0], args[2], args[3], корректнаяОпора: true, переполнение: переполнение, таймаут: таймаут, потомок: потомок, наблюдатьВыход: наблюдатьВыход, каталогВместоФайла: каталогВместоФайла, закрытьДопуск: закрытьДопуск, общаяОпора: false, квитанции: сКвитанцией ? квитанции : nil) else { return 1 }
    if !закрытьДопуск && !сКвитанцией {
        guard запуститьСлучайПрофиля(args[0], args[2], args[3], корректнаяОпора: false, переполнение: переполнение, таймаут: таймаут, потомок: потомок, наблюдатьВыход: наблюдатьВыход, каталогВместоФайла: каталогВместоФайла, закрытьДопуск: false, общаяОпора: false, квитанции: nil) else { return 1 }
    }
    return 0
}
