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

private func hold(_ версия: String) -> Never {
    // .6 closes the anchor's control writer on failure. Its EOF watchdog
    // attempts group cleanup. Exit 125 leaves the outcome unconfirmed.
    if версия == "fum-run-witness.6" || версия == "fum-run-witness.7" || версия == "fum-run-witness.8" { exit(125) }
    var mask = sigset_t()
    _ = sigfillset(&mask)
    _ = pthread_sigmask(SIG_SETMASK, &mask, nil)
    while true {
        _ = sigsuspend(&mask)
        var задержка = timespec(tv_sec: 1, tv_nsec: 0)
        _ = nanosleep(&задержка, nil)
    }
}

private func nowMilliseconds() -> Int64? {
    var value = timespec()
    // Python time.monotonic() on macOS uses mach_absolute_time, equivalent to UPTIME_RAW.
    guard clock_gettime(CLOCK_UPTIME_RAW, &value) == 0, value.tv_sec >= 0 else { return nil }
    let (seconds, overflow) = Int64(value.tv_sec).multipliedReportingOverflow(by: 1000)
    guard !overflow else { return nil }
    let миллисекунды = Int64(value.tv_nsec).quotientAndRemainder(dividingBy: 1_000_000).quotient
    let (result, overflow2) = seconds.addingReportingOverflow(миллисекунды)
    return overflow2 ? nil : result
}

private func deadline(_ milliseconds: Int64) -> Int64? {
    guard let now = nowMilliseconds() else { return nil }
    let (end, overflow) = now.addingReportingOverflow(milliseconds)
    return overflow ? nil : end
}

private func readExact(_ fd: Int32, count: Int, until end: Int64) -> [UInt8]? {
    var bytes = [UInt8]()
    var previous: Int64?
    while bytes.count < count {
        guard let now = nowMilliseconds(), now < end, previous.map({ now >= $0 }) ?? true else { return nil }
        previous = now
        var item = pollfd(fd: fd, events: Int16(POLLIN | POLLHUP), revents: 0)
        let wait = Int32(min(end - now, 100))
        let result = poll(&item, 1, wait)
        if result < 0 && errno == EINTR { continue }
        guard result >= 0 else { return nil }
        if result == 0 { continue }
        guard item.revents & Int16(POLLIN | POLLHUP) != 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: count - bytes.count)
        let length = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
        if length < 0 && (errno == EINTR || errno == EAGAIN) { continue }
        guard length > 0 else { return nil }
        bytes.append(contentsOf: buffer.prefix(length))
    }
    return bytes
}

private func send(_ bytes: [UInt8], to fd: Int32) -> Bool {
    bytes.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) == $0.count }
}

private func targetSignalSettings(_ numbers: [Int32]) -> (sigset_t, sigset_t)? {
    var childAction = sigaction()
    guard MemoryLayout.size(ofValue: childAction.__sigaction_u.__sa_handler) == MemoryLayout<UInt>.size,
          MemoryLayout.size(ofValue: SIG_DFL) == MemoryLayout<UInt>.size,
          MemoryLayout.size(ofValue: SIG_IGN) == MemoryLayout<UInt>.size,
          sigaction(SIGCHLD, nil, &childAction) == 0,
          childAction.sa_flags & Int32(SA_SIGINFO | SA_NOCLDWAIT) == 0,
          unsafeBitCast(childAction.__sigaction_u.__sa_handler, to: UInt.self)
              == unsafeBitCast(SIG_DFL, to: UInt.self) else { return nil }
    var mask = sigset_t()
    var defaults = sigset_t()
    guard sigemptyset(&mask) == 0, sigemptyset(&defaults) == 0,
          sigaddset(&defaults, SIGPIPE) == 0, sigaddset(&defaults, SIGXFSZ) == 0 else { return nil }
    for number in numbers where sigaddset(&mask, number) != 0 { return nil }
    let ignored = unsafeBitCast(SIG_IGN, to: UInt.self)
    for number in [SIGINT, SIGTERM] {
        var old = sigaction()
        guard sigaction(number, nil, &old) == 0 else { return nil }
        let wasIgnored = old.sa_flags & Int32(SA_SIGINFO) == 0 &&
            unsafeBitCast(old.__sigaction_u.__sa_handler, to: UInt.self) == ignored
        if !wasIgnored && sigaddset(&defaults, number) != 0 { return nil }
    }
    return (mask, defaults)
}

// Проверяет существующую опору, но не устанавливает доверие к вызывающему
// или к коду цели. Пространство имён должно оставаться согласованным.
private func подтвердитьОпору(_ опора: ОпораКаталогаПрежнегоЗамка) -> Bool {
    guard getuid() == geteuid() else { return false }
    let флаги = флагиФайла(опора.дескриптор, F_GETFL)
    let дескрипторныеФлаги = флагиФайла(опора.дескриптор, F_GETFD)
    guard флаги >= 0, флаги & O_ACCMODE == O_RDONLY,
          дескрипторныеФлаги >= 0, дескрипторныеФлаги & FD_CLOEXEC != 0 else { return false }
    func соответствует(_ метка: stat) -> Bool {
        let допустимыйРежим = (опора.режим == 0o700 && опора.владелец == getuid()) ||
            (опора.режим == 0o1777 && опора.владелец == 0)
        return допустимыйРежим && метка.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR) &&
            метка.st_mode & 0o7777 == опора.режим && метка.st_uid == опора.владелец &&
            UInt64(exactly: метка.st_dev) == опора.устройство && метка.st_ino == опора.инод
    }
    func сверитьМетки() -> Bool {
        var открытая = stat()
        var именованная = stat()
        let кодИмени = опора.путь.withCString { lstat($0, &именованная) }
        return fstat(опора.дескриптор, &открытая) == 0 && кодИмени == 0 &&
            соответствует(открытая) && соответствует(именованная)
    }
    guard сверитьМетки() else { return false }
    let физический = опора.путь.withCString { вход in
        var буфер = [CChar](repeating: 0, count: 1024)
        return буфер.withUnsafeMutableBufferPointer { область in
            guard let указатель = область.baseAddress, realpath(вход, указатель) != nil else { return false }
            return strcmp(вход, указатель) == 0
        }
    }
    return физический && сверитьМетки()
}

// Это проверка наблюдаемой опоры; она не устанавливает, кто владеет flock,
// и не доказывает тождество open-file-description или доверие к цели.
private func подтвердитьОпоруДопуска(_ опора: ОпораЗаимствованногоДопуска) -> Bool {
    guard getuid() == geteuid(), опора.владелец == getuid() else { return false }
    let флаги = флагиФайла(опора.дескриптор, F_GETFL)
    let дескрипторныеФлаги = флагиФайла(опора.дескриптор, F_GETFD)
    guard флаги >= 0, флаги & O_ACCMODE == O_RDONLY,
          дескрипторныеФлаги >= 0, дескрипторныеФлаги & FD_CLOEXEC != 0 else { return false }
    func соответствует(_ метка: stat) -> Bool {
        метка.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG) && метка.st_nlink == 1 &&
            метка.st_mode & 0o7777 == опора.режим && метка.st_uid == опора.владелец &&
            UInt64(exactly: метка.st_dev) == опора.устройство && метка.st_ino == опора.инод
    }
    func сверитьМетки() -> Bool {
        var открытая = stat()
        var именованная = stat()
        let кодИмени = опора.путь.withCString { lstat($0, &именованная) }
        return fstat(опора.дескриптор, &открытая) == 0 && кодИмени == 0 &&
            соответствует(открытая) && соответствует(именованная)
    }
    guard сверитьМетки() else { return false }
    let физический = опора.путь.withCString { вход in
        var буфер = [CChar](repeating: 0, count: 1024)
        return буфер.withUnsafeMutableBufferPointer { область in
            guard let указатель = область.baseAddress, realpath(вход, указатель) != nil else { return false }
            return strcmp(вход, указатель) == 0
        }
    }
    return физический && сверитьМетки()
}

private func run() -> Int32 {
    let args = CommandLine.arguments
    let raw = CommandLine.unsafeArgv
    for (index, arg) in args.enumerated() {
        guard let p = raw[index] else { return 125 }
        let bytes = UnsafeBufferPointer(start: UnsafeRawPointer(p).assumingMemoryBound(to: UInt8.self), count: strlen(p))
        guard arg.utf8.elementsEqual(bytes) else { return 125 }
    }
    guard raw[args.count] == nil, args.count >= 6 else { return 125 }
    let версия = args[1]
    let передаётДопуск = версия == "fum-run-witness.8"
    let передаётОпору = версия == "fum-run-witness.7" || передаётДопуск
    let версияПоведения = передаётОпору ? "fum-run-witness.6" : версия
    let targetMode = ["fum-run-witness.1", "fum-run-witness.2", "fum-run-witness.3",
                      "fum-run-witness.4", "fum-run-witness.5", "fum-run-witness.6",
                      "fum-run-witness.7", "fum-run-witness.8"].contains(версия)
    let разрешитьИмя = ["fum-run-witness.4", "fum-run-witness.5", "fum-run-witness.6"].contains(версия)
    guard targetMode || версия == "fum-anchor-witness.1",
          let id = ИдентификаторЗапуска(args[2]),
          args[3].hasPrefix("/"), args[3] != "/", !args[3].split(separator: "/").contains(".."),
          let statusFD = Int32(args[4]), statusFD > 2, String(statusFD) == args[4],
          let budget = Int64(args[5]), (1000...30000).contains(budget), String(budget) == args[5],
          getpid() > 1, getpid() == getpgrp(), getsid(0) == getpid() else { return 125 }
    var targetSpec: ПараметрыЗапуска?
    var опораПрежнегоЗамка: ОпораКаталогаПрежнегоЗамка?
    var опораДопуска: ОпораЗаимствованногоДопуска?
    var индексЦели = 10
    var длительностьЦели: String?
    if targetMode {
        guard args.count >= 11 else { return 125 }
        let штатныйПрофиль = версияПоведения == "fum-run-witness.6"
        var профильСреды = ["run", "none"]
        var разделитель = 9
        if штатныйПрофиль {
            if !args[разделитель].hasPrefix("--") {
                длительностьЦели = args[разделитель]
                разделитель += 1
            }
            switch args[разделитель] {
            case "--наблюдения":
                guard args.indices.contains(разделитель + 1) else { return 125 }
                профильСреды = ["run", "path", args[разделитель + 1]]
                разделитель += 2
            case "--без-наблюдений":
                профильСреды = ["projection", "none"]
                разделитель += 1
            default: break
            }
        }
        if передаётОпору {
            guard профильСреды == ["run", "none"], args.indices.contains(разделитель + 6),
                  args[разделитель] == "--опора-старого-замка",
                  let опора = ОпораКаталогаПрежнегоЗамка(args[разделитель + 1], args[разделитель + 2],
                      args[разделитель + 3], args[разделитель + 4], args[разделитель + 5],
                      args[разделитель + 6], дескрипторСтатуса: statusFD) else { return 125 }
            if !передаётДопуск {
                let флаги = флагиФайла(опора.дескриптор, F_GETFD)
                guard флаги >= 0, флагиФайла(опора.дескриптор, F_SETFD, флаги | FD_CLOEXEC) == 0,
                      подтвердитьОпору(опора) else { return 125 }
            }
            опораПрежнегоЗамка = опора
            разделитель += 7
        }
        if передаётДопуск {
            guard let каталог = опораПрежнегоЗамка, args.indices.contains(разделитель + 6),
                  args[разделитель] == "--опора-допуска",
                  let опора = ОпораЗаимствованногоДопуска(args[разделитель + 1], args[разделитель + 2],
                      args[разделитель + 3], args[разделитель + 4], args[разделитель + 5],
                      args[разделитель + 6], дескрипторСтатуса: statusFD,
                      дескрипторКаталога: каталог.дескриптор) else { return 125 }
            // Обе опоры разобраны и проверены на коллизию до изменения флагов.
            let флагиКаталога = флагиФайла(каталог.дескриптор, F_GETFD)
            let флагиДопуска = флагиФайла(опора.дескриптор, F_GETFD)
            guard флагиКаталога >= 0, флагиДопуска >= 0,
                  флагиФайла(каталог.дескриптор, F_SETFD, флагиКаталога | FD_CLOEXEC) == 0,
                  флагиФайла(опора.дескриптор, F_SETFD, флагиДопуска | FD_CLOEXEC) == 0,
                  подтвердитьОпору(каталог), подтвердитьОпоруДопуска(опора) else { return 125 }
            опораДопуска = опора
            разделитель += 7
        }
        индексЦели = разделитель + 1
        guard args.count > индексЦели, args[разделитель] == "--" else { return 125 }
        let policyVersion = версия == "fum-run-witness.1" ? "fum-supervisor.3" : "fum-supervisor.4"
        let normalized = [policyVersion, args[2], args[4], args[6]] + профильСреды + ["--"] +
            Array(args.dropFirst(индексЦели))
        guard let spec = try? ПараметрыЗапуска(arguments: normalized,
                                         разрешитьИмяИсполнителя: разрешитьИмя,
                                         разрешитьПрофильСреды: штатныйПрофиль) else { return 125 }
        targetSpec = spec
    } else if args.count != 6 { return 125 }
    var targetSettings: (sigset_t, sigset_t)?
    if let spec = targetSpec {
        guard let settings = targetSignalSettings(spec.signalMask) else { return 125 }
        targetSettings = settings
    }
    var режимСрока: РежимСрокаНаблюдателя?
    if targetMode {
        guard let now = nowMilliseconds(),
              let режим = РежимСрокаНаблюдателя(версия: версияПоведения, край: args[7],
                                                 второйПараметр: args[8], сейчас: now,
                                                 длительностьЦели: длительностьЦели) else { return 125 }
        режимСрока = режим
    }

    var statusInfo = stat()
    var inputInfo = stat()
    let statusFlags = флагиФайла(statusFD, F_GETFL)
    let inputFlags = флагиФайла(STDIN_FILENO, F_GETFL)
    guard fstat(statusFD, &statusInfo) == 0, fstat(STDIN_FILENO, &inputInfo) == 0,
          statusInfo.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          inputInfo.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          statusInfo.st_dev != inputInfo.st_dev || statusInfo.st_ino != inputInfo.st_ino,
          statusFlags >= 0, statusFlags & O_ACCMODE == O_WRONLY,
          inputFlags >= 0, inputFlags & O_ACCMODE == O_RDONLY, inputFlags & O_NONBLOCK == 0,
          флагиФайла(statusFD, F_SETFL, statusFlags | O_NONBLOCK) == 0 else { return 125 }
    var ignored = sigaction()
    ignored.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&ignored.sa_mask) == 0, sigaction(SIGPIPE, &ignored, nil) == 0 else { return 125 }

    var control = [Int32](repeating: -1, count: 2)
    var ready = [Int32](repeating: -1, count: 2)
    guard pipe(&control) == 0, pipe(&ready) == 0,
          control.allSatisfy({ $0 > 2 }), ready.allSatisfy({ $0 > 2 }),
          Set(control + ready + [statusFD]).count == 5 else { return 125 }
    if let опораДопуска, let каталог = опораПрежнегоЗамка {
        guard Set(control + ready + [statusFD, каталог.дескриптор, опораДопуска.дескриптор]).count == 7 else { return 125 }
    }
    for fd in control + ready {
        let flags = флагиФайла(fd, F_GETFD)
        guard flags >= 0, флагиФайла(fd, F_SETFD, flags | FD_CLOEXEC) == 0 else { return 125 }
    }
    let writeFlags = флагиФайла(ready[1], F_GETFL)
    guard writeFlags >= 0, флагиФайла(ready[1], F_SETFL, writeFlags | O_NONBLOCK) == 0 else { return 125 }

    var actions: posix_spawn_file_actions_t?
    var attributes: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&actions) == 0 else { return 125 }
    defer { posix_spawn_file_actions_destroy(&actions) }
    guard posix_spawnattr_init(&attributes) == 0 else { return 125 }
    defer { posix_spawnattr_destroy(&attributes) }
    guard posix_spawn_file_actions_adddup2(&actions, control[0], STDIN_FILENO) == 0,
          posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, ready[1]) == 0,
          posix_spawnattr_setpgroup(&attributes, 0) == 0,
          posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { return 125 }

    let values = [args[3], "fum-anchor.1", args[2], String(getpid()), String(ready[1])]
    var pointers: [UnsafeMutablePointer<CChar>?] = []
    defer { for pointer in pointers { free(pointer) } }
    for value in values {
        guard let pointer = strdup(value) else { return 125 }
        pointers.append(pointer)
    }
    pointers.append(nil)
    var environment: [UnsafeMutablePointer<CChar>?] = [nil]
    let крайПодготовкиЯкоря: Int64?
    if версияПоведения == "fum-run-witness.6" {
        guard let край = режимСрока?.крайПодготовки,
              let сейчас = nowMilliseconds(), сейчас < край else { return 125 }
        крайПодготовкиЯкоря = край
    } else {
        крайПодготовкиЯкоря = nil
    }
    var anchor: pid_t = 0
    let spawnResult = pointers.withUnsafeMutableBufferPointer { argv in
        environment.withUnsafeMutableBufferPointer { env in
            posix_spawn(&anchor, argv[0], &actions, &attributes, argv.baseAddress, env.baseAddress)
        }
    }
    guard spawnResult == 0, anchor > 1 else { hold(версия) }
    guard close(control[0]) == 0, close(ready[1]) == 0 else { hold(версия) }
    let runID = id.байты
    guard let срокГотовности = deadline(budget) else { hold(версия) }
    let startDeadline = min(срокГотовности, крайПодготовкиЯкоря ?? срокГотовности)
    guard let bytes = readExact(ready[0], count: 24, until: startDeadline),
          let received = try? КадрГотовностиЯкоря.decode(bytes, expectedRunID: runID), received.pid == anchor else { hold(версия) }
    var eofItem = pollfd(fd: ready[0], events: Int16(POLLIN | POLLHUP), revents: 0)
    guard let now = nowMilliseconds(), now < startDeadline,
          poll(&eofItem, 1, Int32(min(startDeadline - now, Int64(Int32.max)))) > 0 else { hold(версия) }
    var one: UInt8 = 0
    guard read(ready[0], &one, 1) == 0, close(ready[0]) == 0 else { hold(версия) }
    if let крайПодготовкиЯкоря {
        guard let сейчас = nowMilliseconds(), сейчас < крайПодготовкиЯкоря else { hold(версия) }
    }
    var initialStatus: Int32 = 0
    guard getpgid(anchor) == anchor, getsid(anchor) == getpid(), anchor != getpgrp(),
          waitpid(anchor, &initialStatus, WNOHANG) == 0, send(received.encoded(), to: statusFD) else { hold(версия) }
    // Best-effort transfer to the anchor's EOF watchdog.
    func abandonToAnchor() -> Never {
        _ = close(control[1])
        hold(версия)
    }

    var target: pid_t = 0
    var targetStatus: Int32?
    var targetStopDeadline: Int64?
    var timedOut = false
    var истёкШтатныйСрок = false
    var прерывание: КомандаПрерыванияНаблюдателя?
    if let spec = targetSpec, var settings = targetSettings, let режим = режимСрока {
        let runDeadline: Int64
        let stop: Int64?
        let бюджетОчистки: Int64?
        let длительность: Int64?
        switch режим {
        case let .ограниченный(крайЗапуска, крайОстановки):
            runDeadline = крайЗапуска
            stop = крайОстановки
            бюджетОчистки = nil
            длительность = nil
        case let .безТаймаута(крайПодготовки, бюджет):
            runDeadline = крайПодготовки
            stop = nil
            бюджетОчистки = бюджет
            длительность = nil
        case let .сТаймаутом(крайПодготовки, бюджет, миллисекунды):
            runDeadline = крайПодготовки
            stop = nil
            бюджетОчистки = бюджет
            длительность = миллисекунды
        }
        guard let goDeadline = deadline(budget),
              let команда = readExact(STDIN_FILENO, count: 1, until: min(goDeadline, runDeadline)),
              let командаДопуска = try? разобратьКомандуДопуска(версияПоведения, команда[0]) else {
            abandonToAnchor()
        }
        guard let beforeSpawn = nowMilliseconds(), beforeSpawn < runDeadline else { abandonToAnchor() }
        targetStopDeadline = stop
        запускЦели: if командаДопуска == .запустить {
            var targetActions: posix_spawn_file_actions_t?
            var targetAttributes: posix_spawnattr_t?
            guard posix_spawn_file_actions_init(&targetActions) == 0 else { abandonToAnchor() }
            defer { posix_spawn_file_actions_destroy(&targetActions) }
            guard posix_spawnattr_init(&targetAttributes) == 0 else { abandonToAnchor() }
            defer { posix_spawnattr_destroy(&targetAttributes) }
            guard posix_spawn_file_actions_addopen(&targetActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
                  posix_spawn_file_actions_addinherit_np(&targetActions, STDOUT_FILENO) == 0,
                  posix_spawn_file_actions_addinherit_np(&targetActions, STDERR_FILENO) == 0,
                  posix_spawnattr_setpgroup(&targetAttributes, anchor) == 0,
                  posix_spawnattr_setsigmask(&targetAttributes, &settings.0) == 0,
                  posix_spawnattr_setsigdefault(&targetAttributes, &settings.1) == 0,
                  posix_spawnattr_setflags(&targetAttributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGMASK |
                      POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { abandonToAnchor() }
            if let опораДопуска {
                guard posix_spawn_file_actions_addinherit_np(&targetActions, опораДопуска.дескриптор) == 0 else {
                    abandonToAnchor()
                }
            }
            let targetEnvironment = spec.targetEnvironment + (опораПрежнегоЗамка.map { ["TMPDIR=" + $0.путь] } ?? []) +
                (опораДопуска.map { [$0.переменнаяЦели] } ?? [])
            var envPointers: [UnsafeMutablePointer<CChar>?] = []
            defer { for pointer in envPointers { free(pointer) } }
            for entry in targetEnvironment {
                guard let pointer = strdup(entry) else { abandonToAnchor() }
                envPointers.append(pointer)
            }
            envPointers.append(nil)
            guard getpgid(anchor) == anchor, getsid(anchor) == getpid(),
                  waitpid(anchor, &initialStatus, WNOHANG) == 0 else { abandonToAnchor() }
            guard let immediatelyBeforeSpawn = nowMilliseconds(), immediatelyBeforeSpawn >= beforeSpawn,
                  immediatelyBeforeSpawn < runDeadline else {
                abandonToAnchor()
            }
            let targetArgv = CommandLine.unsafeArgv.advanced(by: индексЦели)
            let имяЦели = args[индексЦели]
            let путиЦели = разрешитьИмя && !имяЦели.hasPrefix("/")
                ? ["/bin/" + имяЦели, "/usr/bin/" + имяЦели] : [имяЦели]
            var targetSpawn: Int32 = ENOENT
            var времяПоследнейПопытки = immediatelyBeforeSpawn
            for путьЦели in путиЦели {
                guard let времяПопытки = nowMilliseconds(),
                      разрешенаПопыткаЗапуска(предыдущее: времяПоследнейПопытки,
                                             текущее: времяПопытки, срок: runDeadline) else {
                    abandonToAnchor()
                }
                времяПоследнейПопытки = времяПопытки
                func запуститьПоПути() -> Int32 {
                    путьЦели.withCString { путь in
                        envPointers.withUnsafeMutableBufferPointer { env in
                            posix_spawn(&target, путь, &targetActions, &targetAttributes, targetArgv, env.baseAddress)
                        }
                    }
                }
                if let опораПрежнегоЗамка {
                    guard let попытка = запуститьПослеПроверкиОпоры(
                        предыдущее: времяПоследнейПопытки, срок: runDeadline,
                        подтвердить: { подтвердитьОпору(опораПрежнегоЗамка) && (опораДопуска.map { подтвердитьОпоруДопуска($0) } ?? true) },
                        часы: { nowMilliseconds() }, запуск: { запуститьПоПути() }
                    ) else { abandonToAnchor() }
                    времяПоследнейПопытки = попытка.время
                    targetSpawn = попытка.результат
                } else {
                    targetSpawn = запуститьПоПути()
                }
                // На Darwin ненулевой posix_spawn не создаёт ребёнка; следующий
                // явный каталог проверяется только после такого исхода.
                if targetSpawn == 0 { break }
            }
            guard let immediatelyAfterSpawn = nowMilliseconds(), immediatelyAfterSpawn >= времяПоследнейПопытки,
                  immediatelyAfterSpawn < runDeadline else {
                abandonToAnchor()
            }
            if targetSpawn != 0 {
                guard версияПоведения == "fum-run-witness.6", let бюджетОчистки else { abandonToAnchor() }
                let (край, переполнение) = immediatelyAfterSpawn.addingReportingOverflow(бюджетОчистки)
                guard !переполнение,
                      let отказ = try? received.кадрОтказаЗапуска(код: targetSpawn),
                      send(отказ, to: statusFD) else { abandonToAnchor() }
                target = 0
                targetStopDeadline = край
                break запускЦели
            }
            guard target > 1 else { abandonToAnchor() }
            var earlyStatus: Int32 = 0
            let early = waitpid(target, &earlyStatus, WNOHANG)
            if early == target {
                targetStatus = earlyStatus
            } else if early == 0 {
                if getpgid(target) != anchor {
                    let result = waitpid(target, &earlyStatus, WNOHANG)
                    guard result == target else { abandonToAnchor() }
                    targetStatus = earlyStatus
                }
            } else { abandonToAnchor() }
            let срокЦели: (работа: Int64, очистка: Int64)?
            if let длительность, let бюджетОчистки {
                // Начало округлено вниз. Дополнительная миллисекунда сохраняет заданную длительность.
                let край = immediatelyAfterSpawn + длительность + 1
                срокЦели = (край, край + бюджетОчистки)
            } else {
                срокЦели = nil
            }
            var времяСтатуса: Int64?
            if срокЦели != nil, targetStatus != nil {
                guard let время = nowMilliseconds(), время >= immediatelyAfterSpawn else { abandonToAnchor() }
                времяСтатуса = время
            }
            guard let started = try? КадрНачалаЦели(runID: runID, anchorPID: anchor, targetPID: target),
                  let байтыНачала = try? (срокЦели == nil ? started.encoded()
                      : started.байтыСоВременемНачала(immediatelyAfterSpawn)),
                  send(байтыНачала, to: statusFD) else { abandonToAnchor() }

            var statusSent = false
            var previousTargetClock = immediatelyAfterSpawn
            var крайОтветаПослеСтатуса: Int64?
            while true {
                guard let current = nowMilliseconds(), current >= previousTargetClock,
                      stop.map({ current < $0 }) ?? true,
                      крайОтветаПослеСтатуса.map({ current < $0 }) ?? true else { abandonToAnchor() }
                previousTargetClock = current
                if targetStatus == nil {
                    var observed: Int32 = 0
                    let result = waitpid(target, &observed, WNOHANG)
                    if result < 0 && errno != EINTR { abandonToAnchor() }
                    if result == target {
                        targetStatus = observed
                        if срокЦели != nil {
                            guard let время = nowMilliseconds(), время >= current else { abandonToAnchor() }
                            времяСтатуса = время
                        }
                    }
                }
                if !statusSent, let срокЦели, (времяСтатуса ?? current) >= срокЦели.работа {
                    истёкШтатныйСрок = true
                    timedOut = true
                    targetStopDeadline = срокЦели.очистка
                    break
                }
                if let observed = targetStatus, !statusSent {
                    let время = времяСтатуса ?? current
                    let байтыСтатуса: [UInt8]
                    if бюджетОчистки != nil {
                        guard let frame = try? КадрСтатусаБессрочнойЦели(
                            идентификатор: runID, статус: observed, время: время) else { abandonToAnchor() }
                        байтыСтатуса = frame.байты()
                    } else {
                        guard let frame = try? КадрСтатуса(runID: runID, rawStatus: observed) else { abandonToAnchor() }
                        байтыСтатуса = frame.encoded()
                    }
                    guard send(байтыСтатуса, to: statusFD) else { abandonToAnchor() }
                    statusSent = true
                    if let бюджетОчистки {
                        let (край, переполнение) = время.addingReportingOverflow(бюджетОчистки)
                        guard !переполнение, current < край else { abandonToAnchor() }
                        крайОтветаПослеСтатуса = край
                    }
                }
                var input = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
                let ближайшийКрай = stop ?? крайОтветаПослеСтатуса ?? срокЦели?.работа
                let ожидание = ближайшийКрай.map({ Int32(min($0 - current, 10)) }) ?? 10
                let available = poll(&input, 1, ожидание)
                if available < 0 && errno == EINTR { continue }
                guard available >= 0 else { abandonToAnchor() }
                if available == 0 { continue }
                guard input.revents & Int16(POLLIN | POLLHUP) != 0 else { abandonToAnchor() }
                var command: UInt8 = 0
                let commandLength = read(STDIN_FILENO, &command, 1)
                if commandLength == 0 {
                    // Anchor owns best-effort group cleanup when its control writer closes.
                    // No terminal receipt is claimed: the witness remains in HOLD.
                    abandonToAnchor()
                }
                if commandLength < 0 && (errno == EINTR || errno == EAGAIN) { continue }
                guard commandLength == 1, let commandTime = nowMilliseconds(),
                      commandTime >= previousTargetClock, stop.map({ commandTime < $0 }) ?? true,
                      крайОтветаПослеСтатуса.map({ commandTime < $0 }) ?? true else { abandonToAnchor() }
                previousTargetClock = commandTime
                if command == 0x43, targetStatus != nil,
                   бюджетОчистки != nil || commandTime < runDeadline {
                    if let бюджетОчистки {
                        let (край, переполнение) = commandTime.addingReportingOverflow(бюджетОчистки)
                        guard !переполнение else { abandonToAnchor() }
                        targetStopDeadline = край
                    }
                    break
                }
                if command == 0x54, бюджетОчистки == nil, commandTime >= runDeadline {
                    timedOut = true
                    break
                }
                if версияПоведения == "fum-run-witness.6", let бюджетОчистки,
                   let командаПрерывания = КомандаПрерыванияНаблюдателя(rawValue: command) {
                    if !statusSent, let срокЦели, commandTime >= срокЦели.работа {
                        истёкШтатныйСрок = true
                        timedOut = true
                        targetStopDeadline = срокЦели.очистка
                        break
                    }
                    let (край, переполнение) = commandTime.addingReportingOverflow(бюджетОчистки)
                    guard !переполнение else { abandonToAnchor() }
                    targetStopDeadline = край
                    прерывание = командаПрерывания
                    break
                }
                abandonToAnchor()
            }
        } else if let бюджетОчистки {
            let (край, переполнение) = beforeSpawn.addingReportingOverflow(бюджетОчистки)
            guard !переполнение else { abandonToAnchor() }
            targetStopDeadline = край
        }
    } else {
        guard let commandDeadline = deadline(budget),
              let command = readExact(STDIN_FILENO, count: 1, until: commandDeadline), command == [0x43] else {
            _ = close(control[1])
            hold(версия)
        }
    }
    guard let stopDeadline = targetStopDeadline ?? deadline(budget),
          let beforeTerm = nowMilliseconds(), stopDeadline > beforeTerm,
          stopDeadline - beforeTerm >= 600 else { abandonToAnchor() }
    let сигналОстановки = прерывание == .прервать ? SIGINT : SIGTERM
    guard getpgid(anchor) == anchor,
          getsid(anchor) == getpid(), waitpid(anchor, &initialStatus, WNOHANG) == 0,
          killpg(anchor, сигналОстановки) == 0 else { hold(версия) }
    guard let start = nowMilliseconds() else { hold(версия) }
    var previous = start
    while true {
        guard let current = nowMilliseconds(), current >= previous, current < stopDeadline else { hold(версия) }
        previous = current
        // Время округлено вниз до миллисекунд. Разность в 501 гарантирует 500 мс ожидания.
        if current - start > 500 { break }
        var duration = timespec(tv_sec: 0, tv_nsec: 10_000_000)
        if nanosleep(&duration, nil) != 0 && errno != EINTR { hold(версия) }
    }
    guard getpgid(anchor) == anchor, getsid(anchor) == getpid(),
          waitpid(anchor, &initialStatus, WNOHANG) == 0, killpg(anchor, SIGKILL) == 0 else { hold(версия) }
    var rawStatus: Int32 = 0
    while true {
        guard let now = nowMilliseconds(), now >= previous, now < stopDeadline else { hold(версия) }
        previous = now
        let result = waitpid(anchor, &rawStatus, WNOHANG)
        if result == anchor { break }
        if result < 0 && errno != EINTR { hold(версия) }
        var duration = timespec(tv_sec: 0, tv_nsec: 10_000_000)
        if nanosleep(&duration, nil) != 0 && errno != EINTR { hold(версия) }
    }
    if target > 1 && targetStatus == nil {
        while true {
            guard let now = nowMilliseconds(), now >= previous, now < stopDeadline else { hold(версия) }
            previous = now
            var observed: Int32 = 0
            let result = waitpid(target, &observed, WNOHANG)
            if result == target {
                targetStatus = observed
                if прерывание == nil && !истёкШтатныйСрок {
                    guard let frame = try? КадрСтатуса(runID: runID, rawStatus: observed),
                          send(frame.encoded(), to: statusFD) else { hold(версия) }
                }
                break
            }
            if result < 0 && errno != EINTR { hold(версия) }
            var duration = timespec(tv_sec: 0, tv_nsec: 10_000_000)
            if nanosleep(&duration, nil) != 0 && errno != EINTR { hold(версия) }
        }
    }
    guard rawStatus == SIGKILL else { hold(версия) }
    while true {
        guard let now = nowMilliseconds(), now >= previous, now < stopDeadline else { hold(версия) }
        previous = now
        let ответ = killpg(anchor, 0)
        let код = errno
        if ответ == -1 && код == ESRCH { break }
        guard ответ == 0 || (ответ == -1 && (код == EPERM || код == EINTR)) else { hold(версия) }
        var задержка = timespec(tv_sec: 0, tv_nsec: 10_000_000)
        if nanosleep(&задержка, nil) != 0 && errno != EINTR { hold(версия) }
    }
    guard close(control[1]) == 0,
          let now = nowMilliseconds(), now >= previous, now < stopDeadline else { hold(версия) }
    let finish: [UInt8]
    if target > 1 {
        guard let status = targetStatus,
              let frame = try? КадрОчисткиЦели(runID: runID, anchorPID: anchor, targetPID: target,
                                                   targetStatus: status, timedOut: timedOut,
                                                   прерывание: прерывание) else { hold(версия) }
        finish = frame.encoded()
    } else {
        guard let frame = try? КадрОчисткиЯкоря(runID: runID, anchorPID: anchor) else { hold(версия) }
        finish = frame.encoded()
    }
    if let опораПрежнегоЗамка {
        guard close(опораПрежнегоЗамка.дескриптор) == 0 else { hold(версия) }
    }
    if let опораДопуска {
        // Закрываем только копию свидетеля; LOCK_UN общего описания недопустим.
        guard close(опораДопуска.дескриптор) == 0 else { hold(версия) }
    }
    guard send(finish, to: statusFD),
          let afterSend = nowMilliseconds(), afterSend >= now, afterSend < stopDeadline else { hold(версия) }
    return 0
}

exit(run())
