import Darwin

@_silgen_name("_NSGetEnviron")
private func адресОкружения() -> UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?>

private func закрытНомер(_ текст: String) -> Bool {
    guard let fd = Int32(текст), fd > 2 else { return false }
    errno = 0
    return fcntl(fd, F_GETFD) == -1 && errno == EBADF
}

private func удержатьEnvНеизвестно(_ pid: pid_t, _ фаза: Int32) -> Never {
    let строка = Array("UNKNOWN child=\(pid) phase=\(фаза)\n".utf8)
    _ = строка.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, строка.count) }
    _ = fsync(STDERR_FILENO)
    while true { usleep(100_000) }
}

// Доступен только по явному тестовому режиму и использует собственный private каталог.
func проверитьЯвноеОкружение() -> Never {
    let args = CommandLine.arguments
    if args.count == 6 && args[1] == "--env-target" {
        guard закрытНомер(args[3]), закрытНомер(args[4]), let env = адресОкружения().pointee else { exit(81) }
        if args[2] == "normal" {
            guard let первый = env[0], let второй = env[1], env[2] == nil else { exit(82) }
            let ожидаемый: [UInt8] = [65, 61, 255, 61, 120, 0]
            guard strlen(первый) == ожидаемый.count - 1,
                  ожидаемый.enumerated().allSatisfy({ UInt8(bitPattern: первый[$0.offset]) == $0.element }),
                  strcmp(второй, "B=") == 0 else { exit(82) }
        } else if args[2] == "empty" {
            guard env[0] == nil else { exit(83) }
        } else { exit(84) }
        let marker = open(args[5], O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard marker > 2 else { exit(85) }
        let строка = Array("pid=\(getpid())\n".utf8)
        let длина = строка.withUnsafeBytes { write(marker, $0.baseAddress, строка.count) }
        let закрытие = close(marker)
        guard длина == строка.count, закрытие == 0 else { exit(86) }
        exit(0)
    }
    guard args.count == 5, args[1] == "--проверить-env", ["normal", "empty", "duplicate", "malformed", "eof"].contains(args[2]),
          args[4].hasPrefix("/private/tmp/fum-envcase."), args[4].dropFirst("/private/tmp/fum-envcase.".count).utf8.count == 8,
          args[4].dropFirst("/private/tmp/fum-envcase.".count).utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else { exit(90) }
    let root = open(args[4], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    var метка = stat()
    guard root > 2, fstat(root, &метка) == 0, метка.st_uid == getuid(), метка.st_mode & 0o7777 == 0o700 else { exit(91) }
    let envWrite = openat(root, "env.DATA", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard envWrite > 2 else { exit(92) }
    let байты: [UInt8]
    switch args[2] {
    case "empty": байты = []
    case "duplicate": байты = [65, 61, 49, 0, 65, 61, 50, 0]
    case "malformed": байты = [66, 65, 68, 0]
    default: байты = [65, 61, 255, 61, 120, 0, 66, 61, 0]
    }
    let записано = байты.isEmpty ? 0 : байты.withUnsafeBytes { write(envWrite, $0.baseAddress, байты.count) }
    let synced = fsync(envWrite), envWriteClosed = close(envWrite)
    guard записано == байты.count, synced == 0, envWriteClosed == 0 else { exit(93) }
    let envFD = openat(root, "env.DATA", O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
    var gate = [Int32](repeating: -1, count: 2)
    guard envFD > 2, pipe(&gate) == 0, gate.allSatisfy({ $0 > 2 }), Set([root, envFD] + gate).count == 4 else { exit(94) }
    var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&actions) == 0, posix_spawnattr_init(&attrs) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, root) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, envFD) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, gate[0]) == 0,
          posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDOUT_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&actions, STDERR_FILENO) == 0,
          posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { exit(95) }
    let marker = args[4] + "/target.DATA"
    let values = [args[3], "fum-nosignal-shim.2", args[4], String(root), String(метка.st_dev), String(метка.st_ino),
                  String(метка.st_uid), String(метка.st_mode & 0o7777), String(gate[0]), String(envFD), "--",
                  args[0], "--env-target", args[2], String(root), String(envFD), marker]
    let argv = values.map { strdup($0) } + [nil]
    var пустаяСреда: [UnsafeMutablePointer<CChar>?] = [nil], pid: pid_t = 0
    let код = argv.withUnsafeBufferPointer { a in пустаяСреда.withUnsafeMutableBufferPointer { e in
        posix_spawn(&pid, args[3], &actions, &attrs, UnsafeMutablePointer(mutating: a.baseAddress), e.baseAddress)
    } }
    for p in argv { free(p) }
    guard код == 0, pid > 1 else { exit(96) }
    let start = Array("START child=\(pid)\n".utf8)
    _ = start.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, start.count) }
    _ = fsync(STDERR_FILENO)
    _ = signal(SIGPIPE, SIG_IGN)
    guard close(gate[0]) == 0 else { удержатьEnvНеизвестно(pid, 1) }
    if args[2] != "eof" {
        var go: UInt8 = 0x47
        guard write(gate[1], &go, 1) == 1 else { удержатьEnvНеизвестно(pid, 2) }
    }
    guard close(gate[1]) == 0 else { удержатьEnvНеизвестно(pid, 3) }
    let конец = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 5_000_000_000
    var raw: Int32 = -1, got: pid_t = 0
    repeat { got = waitpid(pid, &raw, WNOHANG); if got == 0 { usleep(10_000) } }
    while got == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < конец
    guard got == pid else { удержатьEnvНеизвестно(pid, 4) }
    var меткаМаркера = stat()
    errno = 0
    let markerRC = fstatat(root, "target.DATA", &меткаМаркера, AT_SYMLINK_NOFOLLOW), markerErrno = errno
    let успешный = args[2] == "normal" || args[2] == "empty"
    let ожидался: Int32 = успешный ? 0 : (125 << 8)
    var ok = raw == ожидался && (успешный ? (markerRC == 0 && меткаМаркера.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG)) : (markerRC == -1 && markerErrno == ENOENT))
    if успешный {
        let fd = openat(root, "target.DATA", O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        var bytes = [UInt8](repeating: 0, count: 40)
        let n = fd > 2 ? bytes.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) } : -1
        let closed = fd > 2 ? close(fd) : -1
        let expected = Array("pid=\(pid)\n".utf8)
        if n != expected.count || Array(bytes.prefix(max(0, n))) != expected || closed != 0 { ok = false }
    }
    let a = posix_spawn_file_actions_destroy(&actions), b = posix_spawnattr_destroy(&attrs)
    let c = close(root), d = close(envFD)
    print("mode=\(args[2]) child=\(pid) waitpid=\(got) raw=\(raw) marker_rc=\(markerRC) marker_errno=\(markerErrno) close=\(a),\(b),\(c),\(d)")
    exit(ok && a == 0 && b == 0 && c == 0 && d == 0 ? 0 : 98)
}

проверитьЯвноеОкружение()
