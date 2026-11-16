import Darwin
import Foundation

private let идентификатор = "00112233-4455-4677-8899-aabbccddeeff"
private let байтыЗапуска: [UInt8] = [0x00,0x11,0x22,0x33,0x44,0x55,0x46,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff]
private func удерживать(_ причина: String, _ номерУдержания: pid_t = 0) -> Never {
    let сообщение = "HOLD reason=" + причина + " pid=" + String(номерУдержания) + " errno=" + String(errno) + "\n"
    _ = сообщение.utf8CString.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, $0.count - 1) }
    _ = fsync(STDERR_FILENO)
    while true { usleep(100_000) }
}
private func отметить(_ имя: String, _ номерОтметки: pid_t) {
    let сообщение = имя + " pid=" + String(номерОтметки) + " owner=" + String(getpid()) + "\n"
    guard сообщение.utf8CString.withUnsafeBytes({ write(STDERR_FILENO, $0.baseAddress, $0.count - 1) }) == сообщение.utf8.count,
          fsync(STDERR_FILENO) == 0 else { удерживать("note", номерОтметки) }
}
private func срок() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }
private func прибавитьСрок(_ базовый: UInt64, _ добавка: UInt64) -> UInt64 {
    let (итог, переполнение) = базовый.addingReportingOverflow(добавка)
    guard базовый > 0, !переполнение else { удерживать("clock-overflow") }
    return итог
}
private func собрать(_ номерСбора: pid_t, _ край: UInt64) -> Int32 {
    var сыройСтатус: Int32 = 0
    while срок() < край {
        let итог = waitpid(номерСбора, &сыройСтатус, WNOHANG)
        if итог == номерСбора {
            let сообщение = "REAP pid=" + String(номерСбора) + " raw=" + String(сыройСтатус) + "\n"
            guard сообщение.utf8CString.withUnsafeBytes({ write(STDERR_FILENO, $0.baseAddress, $0.count - 1) }) == сообщение.utf8.count,
                  fsync(STDERR_FILENO) == 0 else { удерживать("reap-note-raw-" + String(сыройСтатус), номерСбора) }
            return сыройСтатус
        }
        if итог < 0 && errno != EINTR { удерживать("wait", номерСбора) }
        usleep(10_000)
    }
    удерживать("wait-deadline", номерСбора)
}
private func запустить(_ путь: String, _ значения: [String], _ вход: Int32?, _ сохранить: [Int32],
                       _ группа: pid_t?, _ новаяСессия: Bool, _ маскаЯкоря: Bool) -> pid_t {
    var действия: posix_spawn_file_actions_t?, настройки: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&действия) == 0 else { удерживать("actions-init") }
    guard posix_spawnattr_init(&настройки) == 0 else { удерживать("attr-init") }
    if let вход { guard posix_spawn_file_actions_adddup2(&действия, вход, STDIN_FILENO) == 0 else { удерживать("stdin-action") } }
    for наследуемыйДескриптор in сохранить { guard posix_spawn_file_actions_addinherit_np(&действия, наследуемыйДескриптор) == 0 else { удерживать("fd-action") } }
    var флаги = Int16(POSIX_SPAWN_CLOEXEC_DEFAULT), маска = sigset_t()
    guard sigemptyset(&маска) == 0 else { удерживать("mask-empty") }
    if маскаЯкоря {
        guard sigaddset(&маска, SIGINT) == 0, sigaddset(&маска, SIGTERM) == 0,
              posix_spawnattr_setsigmask(&настройки, &маска) == 0 else { удерживать("anchor-mask") }
        флаги |= Int16(POSIX_SPAWN_SETSIGMASK)
    }
    if let группа {
        guard posix_spawnattr_setpgroup(&настройки, группа) == 0 else { удерживать("group-attr") }
        флаги |= Int16(POSIX_SPAWN_SETPGROUP)
    }
    if новаяСессия { флаги |= Int16(POSIX_SPAWN_SETSID) }
    guard posix_spawnattr_setflags(&настройки, флаги) == 0 else { удерживать("flags") }
    let указатели = значения.map { strdup($0) } + [nil]
    guard указатели.dropLast().allSatisfy({ $0 != nil }) else { удерживать("argv") }
    var среда: [UnsafeMutablePointer<CChar>?] = [nil]
    var номерЗапуска: pid_t = 0
    let результат = указатели.withUnsafeBufferPointer { список in
        среда.withUnsafeMutableBufferPointer { окружение in
            posix_spawn(&номерЗапуска, путь, &действия, &настройки, UnsafeMutablePointer(mutating: список.baseAddress), окружение.baseAddress)
        }
    }
    for указатель in указатели { free(указатель) }
    if результат == 0 && номерЗапуска > 1 { отметить("SPAWN", номерЗапуска) }
    let первый = posix_spawn_file_actions_destroy(&действия), второй = posix_spawnattr_destroy(&настройки)
    guard результат == 0, номерЗапуска > 1, первый == 0, второй == 0 else { удерживать("spawn-or-cleanup", номерЗапуска) }
    return номерЗапуска
}
private func точнаяЗапись(_ дескрипторЗаписи: Int32, _ байты: [UInt8]) {
    guard байты.withUnsafeBytes({ write(дескрипторЗаписи, $0.baseAddress, $0.count) }) == байты.count else { удерживать("write") }
}
private func кадр(_ дескрипторКадра: Int32, _ ожидаемый: [UInt8], _ край: UInt64) {
    var результат = [UInt8](repeating: 0, count: ожидаемый.count)
    var смещениеКадра = 0
    while смещениеКадра < результат.count && срок() < край {
        var опрос = pollfd(fd: дескрипторКадра, events: Int16(POLLIN), revents: 0)
        let код = poll(&опрос, 1, 100)
        if код < 0 && errno == EINTR { continue }
        guard код >= 0, опрос.revents & Int16(POLLERR | POLLNVAL) == 0 else { удерживать("ready-poll") }
        if код == 0 { continue }
        let длина = результат.withUnsafeMutableBytes { read(дескрипторКадра, $0.baseAddress!.advanced(by: смещениеКадра), $0.count - смещениеКадра) }
        if длина < 0 && errno == EINTR { continue }
        guard длина > 0 else { удерживать("ready-read") }
        смещениеКадра += длина
    }
    guard результат == ожидаемый else { удерживать("ready-frame") }
    var лишний: UInt8 = 0
    while срок() < край {
        let длина = read(дескрипторКадра, &лишний, 1)
        if длина == 0 { return }
        if длина > 0 { удерживать("ready-extra") }
        if errno == EINTR { continue }
        guard errno == EAGAIN else { удерживать("ready-eof") }
        var опрос = pollfd(fd: дескрипторКадра, events: Int16(POLLIN | POLLHUP), revents: 0)
        if poll(&опрос, 1, 100) < 0 && errno != EINTR { удерживать("ready-eof-poll") }
    }
    удерживать("ready-eof-deadline")
}
private func цель(_ аргументы: [String]) -> Never {
    guard аргументы.count == 3, let дескрипторЦели = Int32(аргументы[2]), дескрипторЦели > 2 else { exit(90) }
    var байт: UInt8 = 0
    let длина = read(дескрипторЦели, &байт, 1)
    if длина == 0 { exit(61) }
    exit(62)
}
private func исполнитьПроверку(_ аргументы: [String]) -> Never {
    guard аргументы.count == 4, ["eof", "wrong", "trailing", "deadline"].contains(аргументы[2]),
          аргументы[3].hasPrefix("/"), getpid() == getpgrp(), getsid(0) == getpid() else { exit(91) }
    let край = прибавитьСрок(срок(), 15_000_000_000)
    var допуск = [Int32](repeating: -1, count: 2), управление = допуск, готовность = допуск
    guard pipe(&допуск) == 0, pipe(&управление) == 0, pipe(&готовность) == 0,
          Set(допуск + управление + готовность).count == 6,
          (допуск + управление + готовность).allSatisfy({ $0 > 2 }) else { удерживать("pipes") }
    let флагиЗаписи = fcntl(готовность[1], F_GETFL), флагиЧтения = fcntl(готовность[0], F_GETFL)
    guard флагиЗаписи >= 0, флагиЧтения >= 0,
          fcntl(готовность[1], F_SETFL, флагиЗаписи | O_NONBLOCK) == 0,
          fcntl(готовность[0], F_SETFL, флагиЧтения | O_NONBLOCK) == 0 else { удерживать("nonblock") }
    let процессЦели = запустить(аргументы[0], [аргументы[0], "--якорь-цель", String(допуск[0])], nil, [допуск[0]], 0, false, false)
    guard close(допуск[0]) == 0, getpgid(процессЦели) == процессЦели, getsid(процессЦели) == getpid() else { удерживать("target-bind", процессЦели) }
    let времяЯкоря = прибавитьСрок(срок().quotientAndRemainder(dividingBy: 1_000_000).quotient, аргументы[2] == "deadline" ? 1500 : 10_000)
    let процессЯкоря = запустить(аргументы[3], [аргументы[3], "fum-anchor.2", идентификатор, String(getpid()), String(готовность[1]), String(процессЦели), String(времяЯкоря)], управление[0], [готовность[1]], процессЦели, false, true)
    guard close(управление[0]) == 0, close(готовность[1]) == 0 else { удерживать("anchor-close", процессЯкоря) }
    let число = UInt32(процессЯкоря)
    кадр(готовность[0], [0x46,0x55,0x41,0x31] + байтыЗапуска + [UInt8(truncatingIfNeeded: число >> 24),UInt8(truncatingIfNeeded: число >> 16),UInt8(truncatingIfNeeded: число >> 8),UInt8(truncatingIfNeeded: число)], край)
    guard close(готовность[0]) == 0, getpgid(процессЦели) == процессЦели, getpgid(процессЯкоря) == процессЦели else { удерживать("gate-bind", процессЯкоря) }
    if аргументы[2] == "wrong" { var неверно = байтыЗапуска; неверно[15] ^= 1; точнаяЗапись(управление[1], [0x58] + неверно) }
    if аргументы[2] == "trailing" { точнаяЗапись(управление[1], [0x58] + байтыЗапуска + [1]) }
    if аргументы[2] == "deadline" {
        let исходСрока = собрать(процессЯкоря, край)
        guard исходСрока == 125 << 8, срок().quotientAndRemainder(dividingBy: 1_000_000).quotient >= времяЯкоря else { удерживать("anchor-deadline", процессЯкоря) }
    }
    guard close(управление[1]) == 0 else { удерживать("control-close", процессЯкоря) }
    let сыройЯкоря = аргументы[2] == "deadline" ? Int32(125 << 8) : собрать(процессЯкоря, край)
    guard close(допуск[1]) == 0 else { удерживать("target-close", процессЦели) }
    let сыройЦели = собрать(процессЦели, край)
    guard сыройЯкоря == 125 << 8, сыройЦели == 61 << 8 else { удерживать("unexpected-raw", процессЦели) }
    print("mode=" + аргументы[2] + " target=" + String(процессЦели) + " target_raw=" + String(сыройЦели) + " anchor=" + String(процессЯкоря) + " anchor_raw=" + String(сыройЯкоря))
    exit(0)
}
@main struct Проверка {
    static func main() {
        let аргументыКоманды = CommandLine.arguments
        if аргументыКоманды.count > 1 && аргументыКоманды[1] == "--якорь-цель" { цель(аргументыКоманды) }
        guard аргументыКоманды.count == 4, аргументыКоманды[1] == "--проверить-якорь", аргументыКоманды[0].hasPrefix("/") else { exit(90) }
        var меткаВывода = stat()
        var меткаОшибок = stat()
        var действие = sigaction()
        var игнорировать = sigaction()
        игнорировать.__sigaction_u.__sa_handler = SIG_IGN
        guard fstat(STDOUT_FILENO, &меткаВывода) == 0, fstat(STDERR_FILENO, &меткаОшибок) == 0,
              меткаВывода.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG), меткаОшибок.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG),
              меткаВывода.st_uid == getuid(), меткаОшибок.st_uid == getuid(), меткаВывода.st_nlink == 1, меткаОшибок.st_nlink == 1,
              меткаВывода.st_mode & 0o7777 == 0o600, меткаОшибок.st_mode & 0o7777 == 0o600,
              меткаВывода.st_dev != меткаОшибок.st_dev || меткаВывода.st_ino != меткаОшибок.st_ino,
              sigaction(SIGCHLD, nil, &действие) == 0, действие.sa_flags & Int32(SA_NOCLDWAIT | SA_SIGINFO) == 0,
              unsafeBitCast(действие.__sigaction_u.__sa_handler, to: UInt.self) == unsafeBitCast(SIG_DFL, to: UInt.self),
              sigemptyset(&игнорировать.sa_mask) == 0, sigaction(SIGPIPE, &игнорировать, nil) == 0 else { exit(91) }
        guard setsid() == getpid() else { exit(92) }
        исполнитьПроверку(аргументыКоманды)
    }
}
