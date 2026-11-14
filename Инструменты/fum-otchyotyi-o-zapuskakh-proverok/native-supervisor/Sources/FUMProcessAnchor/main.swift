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
