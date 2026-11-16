import Darwin
import FUMProcessProtocol

// Это проверка текущих имён, не защита от alias, ABA или вложенности в общий Git-dir.
private func разнестиИменаКаталогов(_ rootPath: String, _ root: stat, _ receiptFD: Int32, _ receipt: stat) -> Bool {
    var bytes = [CChar](repeating: 0, count: 1024)
    guard fcntl(receiptFD, F_GETPATH, &bytes) == 0,
          let rootReal = rootPath.withCString({ realpath($0, nil) }) else { return false }
    defer { free(rootReal) }
    guard let end = bytes.firstIndex(of: 0) else { return false }
    let rawPath = bytes[..<end].map { UInt8(bitPattern: $0) }
    let receiptPath = String(decoding: rawPath, as: UTF8.self)
    guard receiptPath.utf8.elementsEqual(rawPath) else { return false }
    guard let receiptReal = receiptPath.withCString({ realpath($0, nil) }) else { return false }
    defer { free(receiptReal) }
    let rootName = String(cString: rootReal), receiptName = String(cString: receiptReal)
    var rootNamed = stat(), receiptNamed = stat()
    guard rootName == rootPath, receiptName == receiptPath,
          rootPath.withCString({ lstat($0, &rootNamed) }) == 0,
          receiptPath.withCString({ lstat($0, &receiptNamed) }) == 0,
          rootNamed.st_dev == root.st_dev, rootNamed.st_ino == root.st_ino,
          receiptNamed.st_dev == receipt.st_dev, receiptNamed.st_ino == receipt.st_ino,
          receiptName != rootName, !receiptName.hasPrefix(rootName + "/") else { return false }
    return true
}

// Экспериментальный owner: файлы квитанции частные, ошибка или частичная запись — UNKNOWN.
private func сохранитьСобытие(_ dir: Int32, _ name: String, _ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard !bytes.isEmpty, bytes.count <= 512 else { return false }
    let fd = name.withCString { openat(dir, $0, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600) }
    guard fd > 2 else { if fd >= 0 { _ = close(fd) }; return false }
    var ok = true, offset = 0
    while offset < bytes.count {
        let n = bytes.withUnsafeBytes { write(fd, $0.baseAddress!.advanced(by: offset), bytes.count - offset) }
        if n <= 0 { ok = false; break }
        offset += n
    }
    var before = stat(), after = stat(), named = stat()
    var copy = [UInt8](repeating: 0, count: bytes.count)
    if fstat(fd, &before) != 0 || before.st_mode & UInt16(S_IFMT) != UInt16(S_IFREG) ||
        before.st_mode & 0o7777 != 0o600 || before.st_uid != getuid() || before.st_nlink != 1 ||
        before.st_size != Int64(bytes.count) || fsync(fd) != 0 { ok = false }
    let n = copy.withUnsafeMutableBytes { pread(fd, $0.baseAddress, bytes.count, 0) }
    if n != bytes.count || copy != bytes || fstat(fd, &after) != 0 ||
        name.withCString({ fstatat(dir, $0, &named, AT_SYMLINK_NOFOLLOW) }) != 0 ||
        before.st_dev != after.st_dev || before.st_ino != after.st_ino ||
        before.st_dev != named.st_dev || before.st_ino != named.st_ino ||
        before.st_mode != after.st_mode || before.st_mode != named.st_mode ||
        before.st_uid != after.st_uid || before.st_uid != named.st_uid ||
        after.st_nlink != 1 || named.st_nlink != 1 ||
        after.st_size != before.st_size || named.st_size != before.st_size { ok = false }
    if close(fd) != 0 { ok = false }
    if fsync(dir) != 0 { ok = false }
    return ok
}

// Only the direct parent may call this mode. It never sends a signal.
func выполнитьВладельцаБезСигналов(_ args: [String]) -> Int32 {
    guard args.count >= 14, ["fum-nosignal-owner.1", "fum-nosignal-owner.2"].contains(args[1]) else { return 125 }
    let сОкружением = args[1] == "fum-nosignal-owner.2"
    let разделитель = сОкружением ? 13 : 12
    guard args.indices.contains(разделитель + 1),
          let run = ИдентификаторЗапуска(args[2]), let deadline = Int64(args[3]), String(deadline) == args[3],
          let statusFD = Int32(args[4]), statusFD > 2, String(statusFD) == args[4],
          let receiptFD = Int32(args[11]), receiptFD > 2, String(receiptFD) == args[11],
          args[разделитель] == "--", args[0].hasPrefix("/"), args[разделитель + 1].hasPrefix("/") else { return 125 }
    var envFD: Int32?, ожидаемаяСреда: ЯвноеОкружение?, меткаСреды: stat?
    if сОкружением {
        var метка = stat()
        guard let число = Int32(args[12]), число > 2, String(число) == args[12],
              число != statusFD, число != receiptFD, fstat(число, &метка) == 0,
              let среда = прочитатьОкружение(число) else { return 125 }
        envFD = число
        ожидаемаяСреда = среда
        меткаСреды = метка
    }
    guard
          let root = ОпораЗаимствованногоКаталога(args[5], args[6], args[7], args[8], args[9], args[10],
              область: .рабочееДерево, занятыеДескрипторы: [statusFD, receiptFD] + (envFD.map { [$0] } ?? [])),
          statusFD != receiptFD, getuid() == geteuid(), подтвердитьОткрытыйКаталог(root),
          let start = монотонныеМиллисекундыНаблюдателя(), start < deadline, deadline - start <= 30_000 else { return 125 }
    func средаСовпадает() -> Bool {
        guard let envFD else { return true }
        guard let исходная = меткаСреды else { return false }
        var до = stat(), после = stat()
        func совпадает(_ метка: stat) -> Bool {
            метка.st_dev == исходная.st_dev && метка.st_ino == исходная.st_ino &&
                метка.st_mode == исходная.st_mode && метка.st_uid == исходная.st_uid &&
                метка.st_gid == исходная.st_gid && метка.st_nlink == исходная.st_nlink &&
                метка.st_size == исходная.st_size && метка.st_mtimespec.tv_sec == исходная.st_mtimespec.tv_sec &&
                метка.st_mtimespec.tv_nsec == исходная.st_mtimespec.tv_nsec &&
                метка.st_ctimespec.tv_sec == исходная.st_ctimespec.tv_sec &&
                метка.st_ctimespec.tv_nsec == исходная.st_ctimespec.tv_nsec
        }
        return fstat(envFD, &до) == 0 && совпадает(до) && прочитатьОкружение(envFD) == ожидаемаяСреда &&
            fstat(envFD, &после) == 0 && совпадает(после)
    }
    var status = stat(), receipt = stat(), rootInfo = stat(), input = stat(), action = sigaction()
    let statusFlags = fcntl(statusFD, F_GETFL), inputFlags = fcntl(STDIN_FILENO, F_GETFL)
    guard fstat(statusFD, &status) == 0, status.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          statusFlags >= 0, statusFlags & O_ACCMODE == O_WRONLY,
          fcntl(statusFD, F_SETFL, statusFlags | O_NONBLOCK) == 0,
          fstat(STDIN_FILENO, &input) == 0, input.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          inputFlags >= 0, inputFlags & O_ACCMODE == O_RDONLY,
          fstat(receiptFD, &receipt) == 0, receipt.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
          receipt.st_uid == getuid(), receipt.st_mode & 0o7777 == 0o700,
          fstat(root.дескриптор, &rootInfo) == 0,
          receipt.st_dev != rootInfo.st_dev || receipt.st_ino != rootInfo.st_ino,
          разнестиИменаКаталогов(args[5], rootInfo, receiptFD, receipt),
          sigaction(SIGCHLD, nil, &action) == 0,
          action.sa_flags & Int32(SA_SIGINFO | SA_NOCLDWAIT) == 0,
          unsafeBitCast(action.__sigaction_u.__sa_handler, to: UInt.self) == unsafeBitCast(SIG_DFL, to: UInt.self),
          сохранитьСобытие(receiptFD, "intent.DATA", "run=\(run.текст) phase=before-spawn\n") else { return 125 }
    var ignorePipe = sigaction()
    ignorePipe.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&ignorePipe.sa_mask) == 0, sigaction(SIGPIPE, &ignorePipe, nil) == 0 else {
        _ = сохранитьСобытие(receiptFD, "unknown.DATA", "run=\(run.текст) phase=before-spawn reason=sigpipe\n")
        return 125
    }
    func send(_ value: String) -> Bool {
        let bytes = Array(value.utf8)
        return bytes.withUnsafeBytes { write(statusFD, $0.baseAddress, bytes.count) == bytes.count }
    }
    func unknownBeforeSpawn(_ reason: String) -> Int32 {
        if сохранитьСобытие(receiptFD, "unknown.DATA", "run=\(run.текст) phase=before-spawn reason=\(reason)\n") {
            _ = send("UNKNOWN \(run.текст)\n")
        }
        return 125
    }
    guard send("READY \(run.текст)\n") else { return unknownBeforeSpawn("status") }
    var ready = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
    var previous = start, gateReady = false
    while !gateReady {
        guard let now = монотонныеМиллисекундыНаблюдателя(), now >= previous, now < deadline else {
            return unknownBeforeSpawn("gate-deadline-or-clock")
        }
        previous = now
        ready.revents = 0
        let polled = poll(&ready, 1, Int32(min(deadline - now, 1000)))
        if polled < 0 && errno == EINTR { continue }
        guard polled >= 0, ready.revents & Int16(POLLHUP | POLLERR | POLLNVAL) == 0 else {
            return unknownBeforeSpawn("gate-connection")
        }
        gateReady = ready.revents & Int16(POLLIN) != 0
    }
    var command: UInt8 = 0
    guard read(STDIN_FILENO, &command, 1) == 1, command == 0x47,
          let beforeSpawn = монотонныеМиллисекундыНаблюдателя(), beforeSpawn >= previous, beforeSpawn < deadline,
          подтвердитьОткрытыйКаталог(root) else { return unknownBeforeSpawn("command-or-root") }
    var gate = [Int32](repeating: -1, count: 2)
    guard pipe(&gate) == 0 else { return unknownBeforeSpawn("pipe") }
    let занятые = [statusFD, receiptFD, root.дескриптор] + (envFD.map { [$0] } ?? [])
    guard gate.allSatisfy({ $0 > 2 }), Set(gate + занятые).count == gate.count + занятые.count else {
        let r = close(gate[0]), w = close(gate[1])
        return unknownBeforeSpawn("pipe-collision-close-\(r)-\(w)")
    }
    var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?, defaults = sigset_t()
    guard posix_spawn_file_actions_init(&actions) == 0 else {
        let r = close(gate[0]), w = close(gate[1])
        return unknownBeforeSpawn("actions-init-close-\(r)-\(w)")
    }
    guard posix_spawnattr_init(&attrs) == 0 else {
        let a = posix_spawn_file_actions_destroy(&actions), r = close(gate[0]), w = close(gate[1])
        return unknownBeforeSpawn("attrs-init-cleanup-\(a)-\(r)-\(w)")
    }
    func cleanupBeforeSpawn(_ reason: String) -> Int32 {
        let a = posix_spawn_file_actions_destroy(&actions), b = posix_spawnattr_destroy(&attrs)
        let r = close(gate[0]), w = close(gate[1])
        return unknownBeforeSpawn("\(reason)-cleanup-\(a)-\(b)-\(r)-\(w)")
    }
    guard sigemptyset(&defaults) == 0, sigaddset(&defaults, SIGPIPE) == 0, sigaddset(&defaults, SIGXFSZ) == 0,
          posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDOUT_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDERR_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, root.дескриптор) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, gate[0]) == 0,
          posix_spawnattr_setsigdefault(&attrs, &defaults) == 0,
          posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETSID | POSIX_SPAWN_SETSIGDEF)) == 0 else { return cleanupBeforeSpawn("spawn-setup") }
    if let envFD, posix_spawn_file_actions_addinherit_np(&actions, envFD) != 0 { return cleanupBeforeSpawn("env-inherit") }
    let shimArgs = [args[0], сОкружением ? "fum-nosignal-shim.2" : "fum-nosignal-shim.1", args[5], args[6], args[7], args[8], args[9], args[10], String(gate[0])] +
        (envFD.map { [String($0)] } ?? []) + ["--"] + Array(args.dropFirst(разделитель + 1))
    let argv = shimArgs.map { strdup($0) } + [nil]
    var env: [UnsafeMutablePointer<CChar>?] = [nil]
    defer { for p in argv { free(p) } }
    guard argv.dropLast().allSatisfy({ $0 != nil }) else { return cleanupBeforeSpawn("arguments") }
    var peerBeforeSpawn = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
    guard let spawnTime = монотонныеМиллисекундыНаблюдателя(), spawnTime >= beforeSpawn,
          spawnTime < deadline, подтвердитьОткрытыйКаталог(root), средаСовпадает(),
          let afterSpawnChecks = монотонныеМиллисекундыНаблюдателя(), afterSpawnChecks >= spawnTime, afterSpawnChecks < deadline,
          poll(&peerBeforeSpawn, 1, 0) == 0 else {
        return cleanupBeforeSpawn("deadline-or-peer-before-spawn")
    }
    var child: pid_t = 0
    let spawn = argv.withUnsafeBufferPointer { a in env.withUnsafeMutableBufferPointer { e in
        posix_spawn(&child, args[0], &actions, &attrs, UnsafeMutablePointer(mutating: a.baseAddress), e.baseAddress)
    } }
    let actionCleanup = posix_spawn_file_actions_destroy(&actions)
    let attributeCleanup = posix_spawnattr_destroy(&attrs)
    let gateReadClose = close(gate[0])
    guard spawn == 0 else {
        _ = close(gate[1])
        return unknownBeforeSpawn("spawn")
    }
    guard child > 1, let наблюдение = ОграниченноеНаблюдениеБезСигналов(pid: child, начало: beforeSpawn, край: deadline) else {
        _ = close(gate[1])
        _ = сохранитьСобытие(receiptFD, "unknown.DATA", "run=\(run.текст) child=\(child) outcome=UNKNOWN reason=ownership\n")
        // Неизвестный после успешного spawn PID не даёт права на сигнал или повтор.
        while true { usleep(100_000) }
    }
    var причина: String?
    if actionCleanup != 0 || attributeCleanup != 0 || gateReadClose != 0 { причина = "spawn-cleanup" }
    if !сохранитьСобытие(receiptFD, "owner.DATA", "run=\(run.текст) child=\(child) phase=before-gate\n"), причина == nil { причина = "owner-receipt" }
    if причина == nil {
        var peerBeforeGate = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
        if let beforeRelease = монотонныеМиллисекундыНаблюдателя(), beforeRelease >= beforeSpawn,
           beforeRelease < deadline, подтвердитьОткрытыйКаталог(root), средаСовпадает(),
           let afterReleaseChecks = монотонныеМиллисекундыНаблюдателя(), afterReleaseChecks >= beforeRelease, afterReleaseChecks < deadline,
           poll(&peerBeforeGate, 1, 0) == 0 {
            var go: UInt8 = 0x47
            if write(gate[1], &go, 1) != 1 { причина = "gate-write" }
        } else { причина = "before-gate" }
    }
    if close(gate[1]) != 0 && причина == nil { причина = "gate-close" }
    var recordedUnknown = false
    var сырой: Int32?
    while сырой == nil {
        if причина == nil {
            switch наблюдение.опросить(часы: монотонныеМиллисекундыНаблюдателя) {
            case .нетРезультата: break
            case let .собран(pid, raw): if pid == child { сырой = raw } else { причина = "wait-identity" }
            case let .неизвестно(ошибка):
                switch ошибка {
                case .срок: причина = "deadline"
                case .часы: причина = "clock"
                case .внешняя: причина = "external"
                case let .wait(code): причина = "wait-\(code)"
                }
            }
            var peer = pollfd(fd: STDIN_FILENO, events: Int16(POLLHUP | POLLIN), revents: 0)
            if (poll(&peer, 1, 0) < 0 || peer.revents & Int16(POLLIN | POLLHUP | POLLERR | POLLNVAL) != 0), причина == nil { причина = "peer" }
        }
        if let причина {
            if !recordedUnknown {
                recordedUnknown = true
                let observed = монотонныеМиллисекундыНаблюдателя().map { String($0) } ?? "UNKNOWN"
                if сохранитьСобытие(receiptFD, "unknown.DATA", "run=\(run.текст) child=\(child) outcome=UNKNOWN reason=\(причина) observed_ms=\(observed) deadline_ms=\(deadline)\n") {
                    _ = send("UNKNOWN \(run.текст) \(причина) \(observed) \(deadline)\n")
                }
            }
            if сырой != nil { continue }
            if let result = наблюдение.добратьПослеНеизвестного() {
                switch result {
                case let .собран(pid, raw): if pid == child { сырой = raw }
                case .неизвестно: return 125
                case .нетРезультата: break
                }
            } else {
                // Прерывание связи до наступления срока сохраняет child за owner.
                switch наблюдение.отметитьВнешнююНеопределённость() {
                case .неизвестно: break
                default: return 125
                }
            }
        }
        if сырой == nil { usleep(10_000) }
    }
    guard let raw = сырой else { return 125 }
    if причина != nil {
        _ = сохранитьСобытие(receiptFD, "reap.DATA", "run=\(run.текст) child=\(child) waitpid=\(child) raw=\(raw) outcome=UNKNOWN\n")
        return 125
    }
    func неизвестноПослеСбора(_ причина: String) -> Int32 {
        let observed = монотонныеМиллисекундыНаблюдателя().map { String($0) } ?? "UNKNOWN"
        if сохранитьСобытие(receiptFD, "unknown.DATA", "run=\(run.текст) child=\(child) outcome=UNKNOWN reason=\(причина) observed_ms=\(observed) deadline_ms=\(deadline)\n") {
            _ = send("UNKNOWN \(run.текст) \(причина) \(observed) \(deadline)\n")
        }
        _ = сохранитьСобытие(receiptFD, "reap.DATA", "run=\(run.текст) child=\(child) waitpid=\(child) raw=\(raw) outcome=UNKNOWN\n")
        return 125
    }
    guard let beforeFinal = монотонныеМиллисекундыНаблюдателя(), beforeFinal >= наблюдение.последнееВремя,
          beforeFinal < deadline else {
        return неизвестноПослеСбора("deadline-after-wait")
    }
    guard подтвердитьОткрытыйКаталог(root), средаСовпадает() else { return неизвестноПослеСбора("source-after-wait") }
    guard let afterFinal = монотонныеМиллисекундыНаблюдателя(), afterFinal >= beforeFinal, afterFinal < deadline else {
        return неизвестноПослеСбора("clock-or-deadline-after-source")
    }
    guard сохранитьСобытие(receiptFD, "terminal.DATA", "run=\(run.текст) child=\(child) waitpid=\(child) raw=\(raw) outcome=PRE-CLOSE\n") else {
        return неизвестноПослеСбора("terminal-receipt")
    }
    guard let afterReceipt = монотонныеМиллисекундыНаблюдателя(), afterReceipt >= afterFinal, afterReceipt < deadline else {
        return неизвестноПослеСбора("clock-or-deadline-after-receipt")
    }
    guard send("DONE \(run.текст) \(raw)\n") else { return неизвестноПослеСбора("terminal-frame") }
    return 0
}
