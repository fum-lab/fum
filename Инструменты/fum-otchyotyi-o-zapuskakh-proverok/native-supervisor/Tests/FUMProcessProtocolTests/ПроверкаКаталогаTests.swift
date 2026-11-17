#if canImport(Darwin)
import Darwin
import Foundation
import Testing
@testable import FUMProcessProtocol

@Test func опорыПомощникаПроверяютРеальныеТипы() throws {
    let база = NSTemporaryDirectory() + "fum-helper-fds-" + UUID().uuidString
    try FileManager.default.createDirectory(atPath: база, withIntermediateDirectories: false,
                                            attributes: [.posixPermissions: 0o700])
    var каталогFD: [Int32] = []
    defer { for fd in каталогFD { _ = close(fd) } }
    var опоры: [ОпораЗаимствованногоКаталога] = []
    for (номер, имя) in ["root", "lock", "receipts"].enumerated() {
        let путь = база + "/" + имя
        try FileManager.default.createDirectory(atPath: путь, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        let fd = open(путь, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw ОшибкаПротокола.неверныеАргументы }
        каталогFD.append(fd)
        var метка = stat()
        guard fstat(fd, &метка) == 0, let устройство = UInt64(exactly: метка.st_dev) else {
            throw ОшибкаПротокола.неверныеАргументы
        }
        let область: ОбластьЗаимствованногоКаталога = номер == 0 ? .рабочееДерево : .приватныеКвитанции
        опоры.append(try #require(ОпораЗаимствованногоКаталога(путь, String(fd), String(устройство),
            String(метка.st_ino), String(метка.st_uid), String(метка.st_mode & 0o7777),
            область: область, занятыеДескрипторы: [])))
    }
    var канал: [Int32] = [-1, -1]
    guard pipe(&канал) == 0 else { throw ОшибкаПротокола.неверныеАргументы }
    defer { _ = close(канал[0]); _ = close(канал[1]) }
    #expect(fcntl(канал[0], F_SETFD, FD_CLOEXEC) == 0)
    #expect(fcntl(канал[1], F_SETFD, FD_CLOEXEC) == 0)
    let номера = try #require(ДескрипторыСинтетическогоПомощника(String(канал[0]), String(каталогFD[0]),
        String(каталогFD[1]), String(каталогFD[2]), занятые: []))
    #expect(подтвердитьОпорыСинтетическогоПомощника(номера, корень: опоры[0], замок: опоры[1], квитанции: опоры[2]))
    let лишний = open("/dev/null", O_RDONLY | O_CLOEXEC)
    guard лишний > 2 else { throw ОшибкаПротокола.неверныеАргументы }
    defer { _ = close(лишний) }
    let вызов = Array("fixture-nonce\n".utf8)
    let записано = вызов.withUnsafeBytes { write(канал[1], $0.baseAddress, $0.count) }
    guard записано == вызов.count else { throw ОшибкаПротокола.неверныеАргументы }
    var действия: posix_spawn_file_actions_t?, настройки: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&действия) == 0 else { throw ОшибкаПротокола.неверныеАргументы }
    defer { _ = posix_spawn_file_actions_destroy(&действия) }
    guard posix_spawnattr_init(&настройки) == 0 else { throw ОшибкаПротокола.неверныеАргументы }
    defer { _ = posix_spawnattr_destroy(&настройки) }
    guard posix_spawn_file_actions_addopen(&действия, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_addopen(&действия, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addopen(&действия, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawnattr_setflags(&настройки, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0,
          подготовитьПередачуОпорПомощника(номера, корень: опоры[0], замок: опоры[1],
                                            квитанции: опоры[2], действия: &действия) else {
        throw ОшибкаПротокола.неверныеАргументы
    }
    let программа = "IFS= read -r x < /dev/fd/\(канал[0]); [ \"$x\" = fixture-nonce ] && " +
        каталогFD.map { "[ -d /dev/fd/\($0) ]" }.joined(separator: " && ") + " && [ ! -e /dev/fd/\(лишний) ]"
    let argv = ["/bin/sh", "-c", программа].map { strdup($0) } + [nil]
    defer { for часть in argv { free(часть) } }
    var среда: [UnsafeMutablePointer<CChar>?] = [nil]
    var pid: pid_t = 0
    let старт = argv.withUnsafeBufferPointer { a in среда.withUnsafeMutableBufferPointer { e in
        posix_spawn(&pid, "/bin/sh", &действия, &настройки, UnsafeMutablePointer(mutating: a.baseAddress), e.baseAddress)
    } }
    guard старт == 0, pid > 1 else { throw ОшибкаПротокола.неверныеАргументы }
    var сырой: Int32 = 0
    var собран = false
    for _ in 0..<500 {
        let итог = waitpid(pid, &сырой, WNOHANG)
        if итог == pid { собран = true; break }
        if итог < 0 { break }
        usleep(10_000)
    }
    if !собран {
        // Не закрывать fixture и не повторять при неизвестном состоянии ребёнка.
        while true { _ = pause() }
    }
    print("fixture-child=\(pid) raw=\(сырой)")
    #expect(сырой == 0)
    let запись = try #require(ДескрипторыСинтетическогоПомощника(String(канал[1]), String(каталогFD[0]),
        String(каталогFD[1]), String(каталогFD[2]), занятые: []))
    #expect(!подтвердитьОпорыСинтетическогоПомощника(запись, корень: опоры[0], замок: опоры[1], квитанции: опоры[2]))
    let закрытый = dup(канал[0])
    guard закрытый > 2 else { throw ОшибкаПротокола.неверныеАргументы }
    #expect(close(закрытый) == 0)
    let закрытые = try #require(ДескрипторыСинтетическогоПомощника(String(закрытый), String(каталогFD[0]),
        String(каталогFD[1]), String(каталогFD[2]), занятые: []))
    #expect(!подтвердитьОпорыСинтетическогоПомощника(закрытые, корень: опоры[0], замок: опоры[1], квитанции: опоры[2]))
    #expect(fcntl(канал[0], F_SETFD, 0) == 0)
    #expect(!подтвердитьОпорыСинтетическогоПомощника(номера, корень: опоры[0], замок: опоры[1], квитанции: опоры[2]))
}

@Test func открытыйКаталогПроверяетТипИМетки() throws {
    let путь = NSTemporaryDirectory() + "fum-directory-fd-" + UUID().uuidString
    try FileManager.default.createDirectory(atPath: путь, withIntermediateDirectories: false,
                                            attributes: [.posixPermissions: 0o700])
    defer { try? FileManager.default.removeItem(atPath: путь) }
    let каталог = open(путь, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    #expect(каталог >= 0)
    guard каталог >= 0 else { return }
    defer { _ = close(каталог) }
    var метка = stat()
    #expect(fstat(каталог, &метка) == 0)
    let устройство = try #require(UInt64(exactly: метка.st_dev))
    func опора(_ fd: Int32, _ инод: UInt64, _ режим: UInt16) throws -> ОпораЗаимствованногоКаталога {
        try #require(ОпораЗаимствованногоКаталога(путь, String(fd), String(устройство), String(инод),
            String(метка.st_uid), String(режим), область: .рабочееДерево, занятыеДескрипторы: []))
    }
    let верная = try опора(каталог, метка.st_ino, метка.st_mode & 0o7777)
    #expect(подтвердитьОткрытыйКаталог(верная))
    let чужоеУстройство = try #require(ОпораЗаимствованногоКаталога(путь, String(каталог), String(устройство ^ 1),
        String(метка.st_ino), String(метка.st_uid), String(метка.st_mode & 0o7777),
        область: .рабочееДерево, занятыеДескрипторы: []))
    let чужойВладелец = try #require(ОпораЗаимствованногоКаталога(путь, String(каталог), String(устройство),
        String(метка.st_ino), String(метка.st_uid ^ 1), String(метка.st_mode & 0o7777),
        область: .рабочееДерево, занятыеДескрипторы: []))
    #expect(!подтвердитьОткрытыйКаталог(чужоеУстройство))
    #expect(!подтвердитьОткрытыйКаталог(чужойВладелец))
    #expect(!подтвердитьОткрытыйКаталог(try опора(каталог, метка.st_ino ^ 1, метка.st_mode & 0o7777)))
    #expect(!подтвердитьОткрытыйКаталог(try опора(каталог, метка.st_ino, (метка.st_mode & 0o7777) ^ 1)))
    let файл = open(путь + "/файл", O_CREAT | O_EXCL | O_RDONLY | O_CLOEXEC, 0o600)
    #expect(файл >= 0)
    guard файл >= 0 else { return }
    defer { _ = close(файл) }
    var меткаФайла = stat()
    #expect(fstat(файл, &меткаФайла) == 0)
    #expect(!подтвердитьОткрытыйКаталог(try опора(файл, меткаФайла.st_ino, меткаФайла.st_mode & 0o7777)))
    let копия = dup(каталог)
    #expect(копия >= 0)
    guard копия >= 0 else { return }
    defer { _ = close(копия) }
    #expect(подтвердитьОткрытыйКаталог(try опора(копия, метка.st_ino, метка.st_mode & 0o7777)))
    let закрытый = dup(каталог)
    #expect(закрытый >= 0)
    guard закрытый >= 0 else { return }
    let закрытаяОпора = try опора(закрытый, метка.st_ino, метка.st_mode & 0o7777)
    #expect(close(закрытый) == 0)
    #expect(!подтвердитьОткрытыйКаталог(закрытаяОпора))
}
#endif
