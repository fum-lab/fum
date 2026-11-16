import Darwin
import FUMProcessProtocol

// Наблюдение bytes/identity при двух fstat не устанавливает custody или защиту от ABA.
func прочитатьОкружение(_ fd: Int32) -> ЯвноеОкружение? {
    let flags = fcntl(fd, F_GETFL)
    var до = stat(), после = stat()
    guard flags >= 0, flags & O_ACCMODE == O_RDONLY, fstat(fd, &до) == 0,
          до.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG), до.st_uid == getuid(),
          до.st_mode & 0o7777 == 0o600, до.st_nlink == 1,
          до.st_size >= 0, до.st_size <= 65_536 else { return nil }
    var bytes = [UInt8](repeating: 0, count: Int(до.st_size)), offset = 0
    while offset < bytes.count {
        let remaining = bytes.count - offset
        let n = bytes.withUnsafeMutableBytes { pread(fd, $0.baseAddress!.advanced(by: offset), remaining, off_t(offset)) }
        if n < 0 && errno == EINTR { continue }
        guard n > 0 else { return nil }
        offset += n
    }
    var extra: UInt8 = 0
    guard pread(fd, &extra, 1, off_t(offset)) == 0, fstat(fd, &после) == 0,
          до.st_dev == после.st_dev, до.st_ino == после.st_ino, до.st_mode == после.st_mode,
          до.st_uid == после.st_uid, до.st_gid == после.st_gid, до.st_nlink == после.st_nlink,
          до.st_size == после.st_size, до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
          до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
          до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec,
          до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec else { return nil }
    return ЯвноеОкружение(bytes)
}

// Environment имеет byte framing, а не политику доверия; её устанавливает caller.
func выполнитьШлюзСОкружением(_ args: [String]) -> Int32 {
    guard args.count >= 12, args[1] == "fum-nosignal-shim.2",
          let gate = Int32(args[8]), gate > 2, String(gate) == args[8],
          let envFD = Int32(args[9]), envFD > 2, String(envFD) == args[9], envFD != gate,
          args[10] == "--", let root = ОпораЗаимствованногоКаталога(args[2], args[3], args[4], args[5], args[6], args[7],
              область: .рабочееДерево, занятыеДескрипторы: [gate, envFD]),
          args[11].hasPrefix("/"), !args[11].split(separator: "/").contains("..") else { return 125 }
    var gateStat = stat()
    let gateFlags = fcntl(gate, F_GETFL), gateFDFlags = fcntl(gate, F_GETFD)
    guard fstat(gate, &gateStat) == 0, gateStat.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          gateFlags >= 0, gateFlags & O_ACCMODE == O_RDONLY, gateFDFlags >= 0,
          fcntl(gate, F_SETFD, gateFDFlags | FD_CLOEXEC) == 0, подтвердитьОткрытыйКаталог(root) else { return 125 }
    var command: UInt8 = 0
    var count: Int
    repeat { count = read(gate, &command, 1) } while count == -1 && errno == EINTR
    guard count == 1, command == 0x47, let environment = прочитатьОкружение(envFD),
          подтвердитьОткрытыйКаталог(root) else { return 125 }
    // Закрываем все три независимо и не запускаем target при любой ошибке.
    let gateClose = close(gate), envClose = close(envFD), rootClose = close(root.дескриптор)
    guard gateClose == 0, envClose == 0, rootClose == 0 else { return 125 }
    let argv = args.dropFirst(11).map { strdup($0) } + [nil]
    var env: [UnsafeMutablePointer<CChar>?] = []
    defer { for p in argv { free(p) }; for p in env { free(p) } }
    guard argv.dropLast().allSatisfy({ $0 != nil }) else { return 125 }
    for entry in environment.записи {
        guard let raw = malloc(entry.count + 1) else { return 125 }
        let pointer = raw.assumingMemoryBound(to: UInt8.self)
        for (index, byte) in entry.enumerated() { pointer[index] = byte }
        pointer[entry.count] = 0
        env.append(raw.assumingMemoryBound(to: CChar.self))
    }
    env.append(nil)
    _ = argv.withUnsafeBufferPointer { a in env.withUnsafeBufferPointer { e in
        execve(args[11], UnsafeMutablePointer(mutating: a.baseAddress), UnsafeMutablePointer(mutating: e.baseAddress))
    } }
    return 125
}
