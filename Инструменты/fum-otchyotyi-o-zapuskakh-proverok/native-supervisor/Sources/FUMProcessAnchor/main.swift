import СистемныеВызовы
import signal_h
import errno_h
import time_h
import FUMProcessProtocol

// Опытная привязка к двум экспортированным Swift-перегрузкам Darwin.fcntl.
// Совместимость с другими версиями SDK требует отдельной проверки.
@_silgen_name("$s6Darwin5fcntlys5Int32VAD_ADtF")
private func флагиФайла(_ дескриптор: Int32, _ команда: Int32) -> Int32
@_silgen_name("$s6Darwin5fcntlys5Int32VAD_A2DtF")
private func флагиФайла(_ дескриптор: Int32, _ команда: Int32, _ значение: Int32) -> Int32

// The anchor is experimental. Its only authority is its own process group.
private func hold() -> Never {
    var mask = sigset_t()
    _ = sigfillset(&mask)
    _ = pthread_sigmask(SIG_SETMASK, &mask, nil)
    while true {
        _ = sigsuspend(&mask)
        var задержка = timespec(tv_sec: 1, tv_nsec: 0)
        _ = nanosleep(&задержка, nil)
    }
}

private func stopOwnGroup(session: pid_t) -> Never {
    var deadline: ПредельныйСрокОжидания?
    var previous: ЗначениеВремени?
    _ = попытатьсяОстановитьГруппу(
        isLeader: { getpid() > 1 && getpid() == getpgrp() && getsid(0) == session },
        term: {
            guard killpg(0, SIGTERM) == 0 else { return .failure(errno) }
            return .success
        },
        sleep: {
            var clock = timespec()
            guard clock_gettime(CLOCK_MONOTONIC, &clock) == 0,
                  let now = try? ЗначениеВремени(seconds: Int64(clock.tv_sec), nanoseconds: Int64(clock.tv_nsec)),
                  previous.map({ now >= $0 }) ?? true else { return .failure(EINVAL) }
            previous = now
            if deadline == nil { deadline = try? ПредельныйСрокОжидания(start: now) }
            guard let deadline else { return .failure(EOVERFLOW) }
            let remaining: ЗначениеВремени?
            do { remaining = try deadline.remaining(at: now) }
            catch { return .failure(EINVAL) }
            guard let remaining else { return .completed }
            var duration = timespec(tv_sec: Int(remaining.seconds), tv_nsec: Int(remaining.nanoseconds))
            if nanosleep(&duration, nil) == 0 { return .recheck }
            return errno == EINTR ? .recheck : .failure(errno)
        },
        kill: {
            guard getpid() == getpgrp(), getsid(0) == session else { return .failure(EINVAL) }
            guard killpg(0, SIGKILL) == 0 else { return .failure(errno) }
            return .success
        }
    )
    hold()
}

// Член группы цели не является её лидером. Только явное завершение закрывает якорь.
private func выполнитьЯкорьГруппыЦели(_ аргументыЯкоря: [String]) -> Int32 {
    guard аргументыЯкоря.count == 7, let идентификаторЯкоря = ИдентификаторЗапуска(аргументыЯкоря[2]),
          let владелецЯкоря = Int32(аргументыЯкоря[3]), владелецЯкоря > 1, String(владелецЯкоря) == аргументыЯкоря[3],
          let дескрипторГотовности = Int32(аргументыЯкоря[4]), дескрипторГотовности > 2, String(дескрипторГотовности) == аргументыЯкоря[4],
          let группаЦели = Int32(аргументыЯкоря[5]), группаЦели > 1, String(группаЦели) == аргументыЯкоря[5],
          getpid() > 1, getpid() != группаЦели, getpgrp() == группаЦели,
          getppid() == владелецЯкоря, getsid(0) == владелецЯкоря, getsid(владелецЯкоря) == владелецЯкоря else { return 125 }
    let крайРаботы: Int64?
    if аргументыЯкоря[6] == "none" {
        крайРаботы = nil
    } else {
        guard let заданныйКрай = Int64(аргументыЯкоря[6]), String(заданныйКрай) == аргументыЯкоря[6] else { return 125 }
        крайРаботы = заданныйКрай
    }
    var меткаУправления = stat()
    var меткаГотовности = stat()
    let флагиУправления = флагиФайла(STDIN_FILENO, F_GETFL)
    let флагиГотовности = флагиФайла(дескрипторГотовности, F_GETFL)
    guard fstat(STDIN_FILENO, &меткаУправления) == 0, fstat(дескрипторГотовности, &меткаГотовности) == 0,
          меткаУправления.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          меткаГотовности.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          меткаУправления.st_dev != меткаГотовности.st_dev || меткаУправления.st_ino != меткаГотовности.st_ino,
          флагиУправления >= 0, флагиУправления & O_ACCMODE == O_RDONLY,
          флагиГотовности >= 0, флагиГотовности & O_ACCMODE == O_WRONLY,
          флагиГотовности & O_NONBLOCK != 0 else { return 125 }
    let флагиДескриптораУправления = флагиФайла(STDIN_FILENO, F_GETFD)
    let флагиДескриптораГотовности = флагиФайла(дескрипторГотовности, F_GETFD)
    guard флагиДескриптораУправления >= 0, флагиДескриптораГотовности >= 0,
          флагиФайла(STDIN_FILENO, F_SETFD, флагиДескриптораУправления | FD_CLOEXEC) == 0,
          флагиФайла(дескрипторГотовности, F_SETFD, флагиДескриптораГотовности | FD_CLOEXEC) == 0,
          флагиФайла(STDIN_FILENO, F_SETFL, флагиУправления | O_NONBLOCK) == 0 else { return 125 }
    var входнаяМаска = sigset_t()
    guard pthread_sigmask(SIG_BLOCK, nil, &входнаяМаска) == 0,
          sigismember(&входнаяМаска, SIGINT) == 1, sigismember(&входнаяМаска, SIGTERM) == 1 else { return 125 }
    func часыЯкоря() -> Int64? {
        монотонныеМиллисекундыНаблюдателя()
    }
    guard let началоЯкоря = часыЯкоря(), крайРаботы.map({ началоЯкоря < $0 }) ?? true else { return 125 }
    var предыдущееВремяЯкоря = началоЯкоря
    func ждатьГотовностьЯкоря(_ ожидаемыйДескриптор: Int32, _ ожидаемыеСобытия: Int16) -> Bool {
        while true {
            guard let текущееВремяОпроса = часыЯкоря(), текущееВремяОпроса >= предыдущееВремяЯкоря, крайРаботы.map({ текущееВремяОпроса < $0 }) ?? true else { return false }
            предыдущееВремяЯкоря = текущееВремяОпроса
            var опросЯкоря = pollfd(fd: ожидаемыйДескриптор, events: ожидаемыеСобытия, revents: 0)
            let результатОпроса = poll(&опросЯкоря, 1, Int32(крайРаботы.map({ min($0 - текущееВремяОпроса, 1000) }) ?? 1000))
            if результатОпроса < 0 && errno == EINTR { continue }
            guard результатОпроса >= 0, опросЯкоря.revents & Int16(POLLERR | POLLNVAL) == 0 else { return false }
            if опросЯкоря.revents & ожидаемыеСобытия != 0 { return true }
            if опросЯкоря.revents & Int16(POLLHUP) != 0 { return false }
        }
    }
    var игнорируемоеДействие = sigaction()
    игнорируемоеДействие.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&игнорируемоеДействие.sa_mask) == 0,
          sigaction(SIGINT, &игнорируемоеДействие, nil) == 0,
          sigaction(SIGTERM, &игнорируемоеДействие, nil) == 0,
          sigaction(SIGPIPE, &игнорируемоеДействие, nil) == 0 else { return 125 }
    var пустаяМаска = sigset_t()
    guard sigemptyset(&пустаяМаска) == 0, pthread_sigmask(SIG_SETMASK, &пустаяМаска, nil) == 0,
          getppid() == владелецЯкоря, getpgrp() == группаЦели, getsid(0) == владелецЯкоря,
          let кадрГотовности = try? КадрГотовностиЯкоря(runID: идентификаторЯкоря.байты, pid: getpid()) else { return 125 }
    let байтыГотовности = кадрГотовности.encoded()
    guard ждатьГотовностьЯкоря(дескрипторГотовности, Int16(POLLOUT)),
          байтыГотовности.withUnsafeBytes({ write(дескрипторГотовности, $0.baseAddress, $0.count) }) == байтыГотовности.count,
          let времяПослеГотовности = часыЯкоря(), времяПослеГотовности >= предыдущееВремяЯкоря, крайРаботы.map({ времяПослеГотовности < $0 }) ?? true,
          close(дескрипторГотовности) == 0 else { return 125 }
    предыдущееВремяЯкоря = времяПослеГотовности
    var командаЯкоря = [UInt8](repeating: 0, count: 17)
    var смещениеКоманды = 0
    while смещениеКоманды < командаЯкоря.count {
        guard ждатьГотовностьЯкоря(STDIN_FILENO, Int16(POLLIN)) else { return 125 }
        let длинаЧастиКоманды = командаЯкоря.withUnsafeMutableBytes {
            read(STDIN_FILENO, $0.baseAddress!.advanced(by: смещениеКоманды), $0.count - смещениеКоманды)
        }
        if длинаЧастиКоманды < 0 && (errno == EINTR || errno == EAGAIN) { continue }
        guard длинаЧастиКоманды > 0 else { return 125 }
        guard let времяПослеЧтения = часыЯкоря(), времяПослеЧтения >= предыдущееВремяЯкоря, крайРаботы.map({ времяПослеЧтения < $0 }) ?? true else { return 125 }
        предыдущееВремяЯкоря = времяПослеЧтения
        смещениеКоманды += длинаЧастиКоманды
    }
    // Владелец закрывает единственный writer после кадра: лишние байты — отказ.
    var лишнийБайт: UInt8 = 0
    while true {
        guard let времяПроверкиХвоста = часыЯкоря(), времяПроверкиХвоста >= предыдущееВремяЯкоря, крайРаботы.map({ времяПроверкиХвоста < $0 }) ?? true else { return 125 }
        предыдущееВремяЯкоря = времяПроверкиХвоста
        let длинаЛишнегоХвоста = read(STDIN_FILENO, &лишнийБайт, 1)
        if длинаЛишнегоХвоста == 0 { break }
        if длинаЛишнегоХвоста > 0 { return 125 }
        if errno == EINTR { continue }
        guard errno == EAGAIN, ждатьГотовностьЯкоря(STDIN_FILENO, Int16(POLLIN | POLLHUP)) else { return 125 }
    }
    guard командаЯкоря[0] == 0x58, Array(командаЯкоря.dropFirst()) == идентификаторЯкоря.байты,
          getppid() == владелецЯкоря, getpgrp() == группаЦели, getsid(0) == владелецЯкоря,
          close(STDIN_FILENO) == 0, let времяЗавершения = часыЯкоря(), времяЗавершения >= предыдущееВремяЯкоря,
          крайРаботы.map({ времяЗавершения < $0 }) ?? true else { return 125 }
    return 0
}

private func run() -> Int32 {
    let args = CommandLine.arguments
    let raw = CommandLine.unsafeArgv
    for (index, argument) in args.enumerated() {
        guard let pointer = raw[index] else { return 125 }
        let bytes = UnsafeBufferPointer(
            start: UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self), count: strlen(pointer))
        guard argument.utf8.elementsEqual(bytes) else { return 125 }
    }
    guard raw[args.count] == nil else { return 125 }
    if args.count > 1 && args[1] == "fum-anchor.2" { return выполнитьЯкорьГруппыЦели(args) }
    guard args.count == 5, args[1] == "fum-anchor.1",
          let id = ИдентификаторЗапуска(args[2]),
          let parent = Int32(args[3]), parent > 1, String(parent) == args[3],
          let readyFD = Int32(args[4]), readyFD > 2, String(readyFD) == args[4],
          getpid() > 1, getpid() == getpgrp(), getppid() == parent,
          getsid(0) == parent, getsid(parent) == parent else { return 125 }

    var controlInfo = stat()
    var readyInfo = stat()
    let controlFlags = флагиФайла(STDIN_FILENO, F_GETFL)
    let readyFlags = флагиФайла(readyFD, F_GETFL)
    let controlDescriptorFlags = флагиФайла(STDIN_FILENO, F_GETFD)
    let readyDescriptorFlags = флагиФайла(readyFD, F_GETFD)
    guard fstat(STDIN_FILENO, &controlInfo) == 0, fstat(readyFD, &readyInfo) == 0,
          controlInfo.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          readyInfo.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          controlInfo.st_dev != readyInfo.st_dev || controlInfo.st_ino != readyInfo.st_ino,
          controlFlags >= 0, controlFlags & O_ACCMODE == O_RDONLY, controlFlags & O_NONBLOCK == 0,
          readyFlags >= 0, readyFlags & O_ACCMODE == O_WRONLY, readyFlags & O_NONBLOCK != 0,
          controlDescriptorFlags >= 0, readyDescriptorFlags >= 0,
          флагиФайла(STDIN_FILENO, F_SETFD, controlDescriptorFlags | FD_CLOEXEC) == 0,
          флагиФайла(readyFD, F_SETFD, readyDescriptorFlags | FD_CLOEXEC) == 0 else { return 125 }

    var ignored = sigaction()
    ignored.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&ignored.sa_mask) == 0,
          sigaction(SIGINT, &ignored, nil) == 0,
          sigaction(SIGTERM, &ignored, nil) == 0,
          sigaction(SIGPIPE, &ignored, nil) == 0 else { return 125 }
    var empty = sigset_t()
    guard sigemptyset(&empty) == 0, pthread_sigmask(SIG_SETMASK, &empty, nil) == 0,
          getppid() == parent, getpid() == getpgrp(), getsid(0) == parent else { return 125 }

    let runID = id.байты
    guard let ready = try? КадрГотовностиЯкоря(runID: runID, pid: getpid()) else { return 125 }
    let bytes = ready.encoded()
    let written = bytes.withUnsafeBytes { buffer in
        write(readyFD, buffer.baseAddress, buffer.count)
    }
    guard written == bytes.count else { stopOwnGroup(session: parent) }
    guard close(readyFD) == 0 else { stopOwnGroup(session: parent) }
    var byte: UInt8 = 0
    while true {
        let count = read(STDIN_FILENO, &byte, 1)
        if count < 0 && errno == EINTR { continue }
        // EOF or an unexpected command both revoke the group anchor.
        stopOwnGroup(session: parent)
    }
}

exit(run())
