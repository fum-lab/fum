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

private func writeAll(_ fd: Int32, _ bytes: [UInt8]) -> Bool {
    bytes.withUnsafeBytes { buffer in
        guard let base = buffer.baseAddress else { return bytes.isEmpty }
        var offset = 0
        while offset < buffer.count {
            let count = write(fd, base.advanced(by: offset), buffer.count - offset)
            if count < 0 && errno == EINTR { continue }
            guard count > 0 else { return false }
            offset += count
        }
        return true
    }
}

private func receiveByte() -> UInt8? {
    var byte: UInt8 = 0
    while true {
        let count = read(STDIN_FILENO, &byte, 1)
        if count < 0 && errno == EINTR { continue }
        return count == 1 ? byte : nil
    }
}

private func exactArguments() -> [String]? {
    let arguments = CommandLine.arguments
    let raw = CommandLine.unsafeArgv
    guard !arguments.isEmpty else { return nil }
    for (index, argument) in arguments.enumerated() {
        guard let pointer = raw[index] else { return nil }
        let bytes = UnsafeBufferPointer(
            start: UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            count: strlen(pointer))
        guard argument.utf8.elementsEqual(bytes) else { return nil }
    }
    guard raw[arguments.count] == nil else { return nil }
    return arguments
}

private func prepareSignals() -> (sigset_t, sigset_t)? {
    // The supervisor must remain alive when it sends TERM to its own group.
    // Caught dispositions reset on exec; preserve ignored INT/TERM for the target.
    // Python Popen(restore_signals=True) resets PIPE and XFSZ to their defaults.
    var oldMask = sigset_t()
    var empty = sigset_t()
    guard sigemptyset(&empty) == 0,
          pthread_sigmask(SIG_BLOCK, &empty, &oldMask) == 0 else { return nil }

    var childAction = sigaction()
    guard sigaction(SIGCHLD, nil, &childAction) == 0,
          childAction.sa_flags & Int32(SA_SIGINFO | SA_NOCLDWAIT) == 0,
          MemoryLayout.size(ofValue: childAction.__sigaction_u.__sa_handler) == MemoryLayout<UInt>.size,
          MemoryLayout.size(ofValue: SIG_DFL) == MemoryLayout<UInt>.size,
          unsafeBitCast(childAction.__sigaction_u.__sa_handler, to: UInt.self)
              == unsafeBitCast(SIG_DFL, to: UInt.self) else { return nil }

    var defaults = sigset_t()
    guard sigemptyset(&defaults) == 0,
          sigaddset(&defaults, SIGPIPE) == 0,
          sigaddset(&defaults, SIGXFSZ) == 0,
          MemoryLayout.size(ofValue: SIG_IGN) == MemoryLayout<UInt>.size else { return nil }
    let ignoredBits = unsafeBitCast(SIG_IGN, to: UInt.self)
    for number in [SIGINT, SIGTERM, SIGPIPE] {
        var old = sigaction()
        guard sigaction(number, nil, &old) == 0 else { return nil }
        let wasIgnored = old.sa_flags & Int32(SA_SIGINFO) == 0 &&
            unsafeBitCast(old.__sigaction_u.__sa_handler, to: UInt.self) == ignoredBits
        if number != SIGPIPE && !wasIgnored && sigaddset(&defaults, number) != 0 { return nil }
        var ignored = sigaction()
        ignored.__sigaction_u.__sa_handler = SIG_IGN
        guard sigemptyset(&ignored.sa_mask) == 0,
              sigaction(number, &ignored, nil) == 0 else { return nil }
    }
    return (oldMask, defaults)
}

private func stopOwnGroup(statusFD: Int32, runBytes: [UInt8], holdMask: sigset_t,
                          maySendUnknown: Bool = true) -> Never {
    // A failure leaves the anchor alive; the owner must retain it as UNKNOWN.
    var deadline: ПредельныйСрокОжидания?
    var previous: ЗначениеВремени?
    let failure = попытатьсяОстановитьГруппу(
        isLeader: { getpid() == getpgrp() && getsid(0) == getpid() },
        term: {
            if killpg(0, SIGTERM) == 0 { return .success }
            return .failure(errno)
        },
        sleep: {
            var sample = timespec()
            guard clock_gettime(CLOCK_MONOTONIC, &sample) == 0 else {
                let error = errno
                return .failure(error == 0 ? EIO : error)
            }
            guard let now = try? ЗначениеВремени(seconds: Int64(sample.tv_sec), nanoseconds: Int64(sample.tv_nsec)),
                  previous.map({ now >= $0 }) ?? true else { return .failure(EINVAL) }
            previous = now
            if deadline == nil {
                guard let created = try? ПредельныйСрокОжидания(start: now) else { return .failure(EOVERFLOW) }
                deadline = created
            }
            guard let activeDeadline = deadline else { return .failure(EINVAL) }
            let duration: ЗначениеВремени?
            do { duration = try activeDeadline.remaining(at: now) }
            catch { return .failure(EINVAL) }
            guard let duration else { return .completed }
            var remaining = timespec(tv_sec: Int(duration.seconds), tv_nsec: Int(duration.nanoseconds))
            var next = timespec()
            if nanosleep(&remaining, &next) == 0 { return .recheck }
            let error = errno
            if error == EINTR { return .recheck }
            return .failure(error)
        },
        kill: {
            if killpg(0, SIGKILL) == 0 { return .success }
            return .failure(errno)
        }
    )
    if maySendUnknown, let frame = try? КадрНеизвестногоИсхода(runID: runBytes, failure: failure) {
        _ = writeAll(statusFD, frame.encoded())
    }
    var mask = holdMask
    while true {
        let result = sigsuspend(&mask)
        if result == -1 && errno == EINTR { continue }
        // Best effort: sigsuspend restored the old mask before this fallback.
        // A masking failure still remains UNKNOWN to the owner.
        _ = pthread_sigmask(SIG_BLOCK, &mask, nil)
        var задержка = timespec(tv_sec: 1, tv_nsec: 0)
        _ = nanosleep(&задержка, nil)
    }
}

private func run() -> Int32 {
    guard let arguments = exactArguments(),
          let spec = try? ПараметрыЗапуска.legacySupervisor(arguments: Array(arguments.dropFirst())),
          getpid() == getpgrp(), getsid(0) == getpid() else { return 125 }

    let statusFD = spec.statusFD
    let runBytes = spec.runID.байты
    var statusInfo = stat()
    guard fstat(statusFD, &statusInfo) == 0,
          statusInfo.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO) else { return 125 }
    let flags = флагиФайла(statusFD, F_GETFD)
    guard flags >= 0, флагиФайла(statusFD, F_SETFD, flags | FD_CLOEXEC) == 0 else { return 125 }
    let pipeFlags = флагиФайла(statusFD, F_GETFL)
    guard pipeFlags >= 0, pipeFlags & O_ACCMODE == O_WRONLY,
          флагиФайла(statusFD, F_SETFL, pipeFlags | O_NONBLOCK) == 0 else { return 125 }

    var holdMask = sigset_t()
    guard sigfillset(&holdMask) == 0,
          var (_, defaults) = prepareSignals() else { return 125 }
    var targetMask = sigset_t()
    guard sigemptyset(&targetMask) == 0 else { return 125 }
    for number in spec.signalMask {
        guard sigaddset(&targetMask, number) == 0 else { return 125 }
    }
    guard let ready = try? КадрГотовности(runID: runBytes),
          writeAll(statusFD, ready.encoded()), receiveByte() == 0x47 else { return 125 }

    var actions: posix_spawn_file_actions_t?
    var attributes: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&actions) == 0 else { return 125 }
    defer { posix_spawn_file_actions_destroy(&actions) }
    guard posix_spawnattr_init(&attributes) == 0 else { return 125 }
    defer { posix_spawnattr_destroy(&attributes) }
    guard posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDOUT_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDERR_FILENO) == 0,
          posix_spawnattr_setsigmask(&attributes, &targetMask) == 0,
          posix_spawnattr_setsigdefault(&attributes, &defaults) == 0,
          posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { return 125 }

    let environment = spec.targetEnvironment
    var pointers: [UnsafeMutablePointer<CChar>?] = []
    defer { for pointer in pointers { free(pointer) } }
    for entry in environment {
        guard let pointer = strdup(entry) else { return 125 }
        pointers.append(pointer)
    }
    pointers.append(nil)
    var child: pid_t = 0
    let targetArgv = CommandLine.unsafeArgv.advanced(by: spec.targetIndex + 1)
    let spawnResult = pointers.withUnsafeMutableBufferPointer { environment in
        posix_spawn(&child, targetArgv.pointee, &actions, &attributes, targetArgv, environment.baseAddress)
    }
    guard spawnResult == 0, child > 1 else { return 125 }
    var rawStatus: Int32 = 0
    var statusSent = false
    while true {
        if !statusSent {
            let result = waitpid(child, &rawStatus, WNOHANG)
            if result < 0 && errno != EINTR { stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask) }
            if result == child {
                guard let frame = try? КадрСтатуса(runID: runBytes, rawStatus: rawStatus) else {
                    stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask)
                }
                guard writeAll(statusFD, frame.encoded()) else {
                    // The stream may already contain a partial status frame.
                    stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask, maySendUnknown: false)
                }
                statusSent = true
            }
        }
        var control = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
        let ready = poll(&control, 1, 10)
        if ready < 0 && errno == EINTR { continue }
        guard ready >= 0 else { stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask) }
        if ready > 0 {
            guard control.revents & Int16(POLLIN | POLLHUP) != 0 else { stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask) }
            guard let command = receiveByte() else { stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask) }
            if command == 0x54 || command == 0x43 { stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask) }
            stopOwnGroup(statusFD: statusFD, runBytes: runBytes, holdMask: holdMask)
        }
    }
}

exit(run())
