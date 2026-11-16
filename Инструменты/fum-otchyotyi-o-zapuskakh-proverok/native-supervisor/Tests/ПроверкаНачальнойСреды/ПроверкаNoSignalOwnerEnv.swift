import Darwin
import Foundation
func проверитьNoSignalOwnerEnv() -> Never {
let исходные = CommandLine.arguments
let группа = исходные.count > 1 && исходные[1] == "--проверить-owner-group"
let a = исходные.count > 1 && (исходные[1] == "--проверить-owner-env" || группа) ? [исходные[0]] + Array(исходные.dropFirst(2)) : исходные
guard a.count == 6, ["normal", "empty", "duplicate", "malformed", "changed"].contains(a[1]), a[4].hasSuffix("/root"), a[2].hasPrefix("/"), a[3].hasPrefix("/") else { exit(90) }
let base = String(a[4].dropLast(5)), prefix = "/private/tmp/fum-owner2env."
guard base.hasPrefix(prefix), a[5] == base + "/receipt", base.dropFirst(prefix.count).utf8.count == 8,
      base.dropFirst(prefix.count).utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else { exit(90) }
let root = open(a[4], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
let receipt = open(a[5], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
var rootStat = stat(), receiptStat = stat(), control = [Int32](repeating:-1,count:2), status = [Int32](repeating:-1,count:2)
guard root > 2, receipt > 2, fstat(root, &rootStat) == 0, fstat(receipt, &receiptStat) == 0,
      rootStat.st_uid == getuid(), receiptStat.st_uid == getuid(), rootStat.st_mode & 0o7777 == 0o700,
      receiptStat.st_mode & 0o7777 == 0o700 else { exit(91) }
let запаснойReceipt = openat(receipt, ".", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
var запаснойStat = stat()
guard запаснойReceipt > 2, запаснойReceipt != receipt, fstat(запаснойReceipt, &запаснойStat) == 0,
      запаснойStat.st_dev == receiptStat.st_dev, запаснойStat.st_ino == receiptStat.st_ino else { exit(91) }
let envWrite = openat(receipt, "env.DATA", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
guard envWrite > 2 else { exit(92) }
let envBytes: [UInt8] = a[1] == "empty" ? [] : (a[1] == "duplicate" ? [65,61,49,0,65,61,50,0] : (a[1] == "malformed" ? [66,65,68,0] : [65,61,255,61,120,0,66,61,0]))
let wrote = envBytes.isEmpty ? 0 : envBytes.withUnsafeBytes { write(envWrite, $0.baseAddress, envBytes.count) }
let synced = fsync(envWrite), envWriteClosed = close(envWrite)
guard wrote == envBytes.count, synced == 0, envWriteClosed == 0 else { exit(93) }
let envFD = openat(receipt, "env.DATA", O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
guard envFD > 2, pipe(&control) == 0, pipe(&status) == 0,
      Set([root,receipt,envFD]+control+status).count == 7, (control+status).allSatisfy({ $0 > 2 }) else { exit(94) }
var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?
guard posix_spawn_file_actions_init(&actions) == 0, posix_spawnattr_init(&attrs) == 0,
      posix_spawn_file_actions_adddup2(&actions, control[0], STDIN_FILENO) == 0,
      posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
      posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, root) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, receipt) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, envFD) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, status[1]) == 0,
      posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { exit(95) }
let run = "00112233-4455-4677-8899-aabbccddeeff"
let limit = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) / 1_000_000 + 5_000
let values = [a[2], группа ? "fum-nosignal-owner.4" : "fum-nosignal-owner.2", run, String(limit), String(status[1]), a[4], String(root), String(rootStat.st_dev), String(rootStat.st_ino), String(rootStat.st_uid), String(rootStat.st_mode & 0o7777), String(receipt), String(envFD)] + (группа ? ["0"] : []) + ["--", a[3], "--env-target", a[1], String(root), String(envFD), a[4] + "/target.DATA"]
let argv = values.map { strdup($0) } + [nil]
var env: [UnsafeMutablePointer<CChar>?] = [nil]; var pid: pid_t = 0
let spawned = argv.withUnsafeBufferPointer { p in env.withUnsafeMutableBufferPointer { e in posix_spawn(&pid, a[2], &actions, &attrs, UnsafeMutablePointer(mutating:p.baseAddress), e.baseAddress) } }
for p in argv { free(p) }
guard spawned == 0, pid > 1 else { exit(96) }
let started = Array("START owner=\(pid)\n".utf8); _ = started.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, started.count) }; _ = fsync(STDERR_FILENO)
var собранныйСтатус: Int32?
var последнийКадр: [UInt8] = []
func unknown(_ phase: Int32) -> Never {
    let line = Array("UNKNOWN owner=\(pid) phase=\(phase)\n".utf8); _ = line.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, line.count) }; _ = fsync(STDERR_FILENO)
    func часы() -> UInt64? {
        var момент = timespec()
        guard clock_gettime(CLOCK_UPTIME_RAW, &момент) == 0, момент.tv_sec >= 0,
              (0..<1_000_000_000).contains(момент.tv_nsec) else { return nil }
        let (секунды, ошибка) = UInt64(момент.tv_sec).multipliedReportingOverflow(by: 1_000_000_000)
        let (наносекунды, переполнение) = секунды.addingReportingOverflow(UInt64(момент.tv_nsec))
        return ошибка || переполнение ? nil : наносекунды
    }
    if let начало = часы() {
        let (край, переполнение) = начало.addingReportingOverflow(5_000_000_000)
        var предыдущее = начало
        while !переполнение && собранныйСтатус == nil {
            guard let сейчас = часы(), сейчас >= предыдущее, сейчас < край else { break }
            предыдущее = сейчас
            var raw: Int32 = 0
            let результат = waitpid(pid, &raw, WNOHANG)
            if результат == pid { собранныйСтатус = raw; break }
            if результат < 0 && errno != EINTR { break }
            usleep(10_000)
        }
    }
    if let raw = собранныйСтатус {
        let кадр = последнийКадр.count <= 128 ? последнийКадр.map { String(format: "%02x", $0) }.joined() : "OVERLIMIT"
        let записано = записатьКвитанциюВладельца(запаснойReceipt, "driver-unknown.DATA",
            "run=\(run) owner=\(pid) waitpid=\(pid) raw=\(raw) phase=\(phase) frame_hex=\(кадр) outcome=UNKNOWN\n")
        let итог = Array("UNKNOWN-REAP owner=\(pid) raw=\(raw) receipt=\(записано ? 1 : 0)\n".utf8)
        _ = итог.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, итог.count) }
        _ = fsync(STDERR_FILENO)
        exit(125)
    }
    let hold = Array("UNKNOWN-HOLD owner=\(pid)\n".utf8)
    _ = hold.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, hold.count) }
    _ = fsync(STDERR_FILENO)
    while true { usleep(100_000) }
}
func закрытьЗапасной() {
    guard close(запаснойReceipt) == 0 else {
        let message = Array("UNKNOWN owner=\(pid) phase=backup-close\n".utf8)
        _ = message.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, message.count) }
        exit(125)
    }
}
_ = signal(SIGPIPE, SIG_IGN)
guard close(control[0]) == 0, close(status[1]) == 0 else { unknown(97) }
func line(_ fd: Int32) -> String? {
    let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 6_000_000_000; var bytes = [UInt8]()
    while bytes.count < 256 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end {
        var p = pollfd(fd:fd, events:Int16(POLLIN | POLLHUP), revents:0); let n = poll(&p,1,100)
        if n < 0 { return nil }; if n == 0 { continue }
        var b: UInt8 = 0; guard read(fd,&b,1) == 1 else { последнийКадр = bytes; return nil }; bytes.append(b)
        последнийКадр = bytes
        if b == 10 { return String(bytes:bytes,encoding:.utf8) }
    }
    return nil
}
func file(_ dir: Int32, _ name: String) -> String? {
    let fd = name.withCString { openat(dir,$0,O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC) }
    guard fd > 2 else { return nil }
    var st = stat(), bytes = [UInt8](repeating:0,count:512)
    guard fstat(fd,&st) == 0, st.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG),
          st.st_uid == getuid(), st.st_nlink == 1, st.st_size > 0, st.st_size <= 512 else { _ = close(fd); return nil }
    let n = bytes.withUnsafeMutableBytes { pread(fd,$0.baseAddress,Int(st.st_size),0) }; let c = close(fd)
    guard n == st.st_size, c == 0 else { return nil }; return String(bytes:bytes.prefix(n),encoding:.utf8)
}
if a[1] == "duplicate" || a[1] == "malformed" {
    guard line(status[0]) == nil else { unknown(110) }
    let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 5_000_000_000
    var raw: Int32 = -1, waited: pid_t = 0
    repeat { waited = waitpid(pid,&raw,WNOHANG); if waited == 0 { usleep(10_000) } } while waited == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end
    guard waited == pid else { unknown(111) }
    собранныйСтатус = raw
    var info = stat(); errno = 0
    let intentRC = fstatat(receipt,"intent.DATA",&info,AT_SYMLINK_NOFOLLOW), intentErrno = errno
    errno = 0
    let markerRC = fstatat(root,"target.DATA",&info,AT_SYMLINK_NOFOLLOW), markerErrno = errno
    let c = close(control[1]), s = close(status[0]), r = close(root), e = close(envFD), q = close(receipt)
    let x = posix_spawn_file_actions_destroy(&actions), y = posix_spawnattr_destroy(&attrs)
    guard raw == 125 << 8, intentRC == -1, intentErrno == ENOENT, markerRC == -1, markerErrno == ENOENT,
          [c,s,r,e,q,x,y].allSatisfy({ $0 == 0 }) else { unknown(112) }
    закрытьЗапасной()
    print("mode=\(a[1]) owner=\(pid) waitpid=\(waited) raw=\(raw) intent_rc=\(intentRC) intent_errno=\(intentErrno) marker_rc=\(markerRC) marker_errno=\(markerErrno) cleanup=\(c),\(s),\(r),\(e),\(q),\(x),\(y)")
    exit(0)
}
guard line(status[0]) == "READY \(run)\n" else { unknown(98) }
if a[1] == "changed" {
    let изменение = openat(receipt, "env.DATA", O_WRONLY | O_NOFOLLOW | O_CLOEXEC)
    guard изменение > 2 else { unknown(113) }
    var байт: UInt8 = 90
    let длина = pwrite(изменение, &байт, 1, 0), sync = fsync(изменение), закрытие = close(изменение)
    guard длина == 1, sync == 0, закрытие == 0 else { unknown(114) }
}
var go: UInt8 = 0x47
guard write(control[1],&go,1) == 1 else { unknown(99) }
if a[1] == "changed" {
    guard line(status[0]) == "UNKNOWN \(run)\n",
          file(receipt,"intent.DATA") == "run=\(run) phase=before-spawn\n",
          file(receipt,"unknown.DATA") == "run=\(run) phase=before-spawn reason=deadline-or-peer-before-spawn-cleanup-0-0-0-0\n" else { unknown(115) }
    let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 5_000_000_000
    var raw: Int32 = -1, waited: pid_t = 0
    repeat { waited = waitpid(pid,&raw,WNOHANG); if waited == 0 { usleep(10_000) } } while waited == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end
    guard waited == pid else { unknown(116) }
    собранныйСтатус = raw
    var info = stat(); errno = 0
    let ownerRC = fstatat(receipt,"owner.DATA",&info,AT_SYMLINK_NOFOLLOW), ownerErrno = errno
    errno = 0
    let markerRC = fstatat(root,"target.DATA",&info,AT_SYMLINK_NOFOLLOW), markerErrno = errno
    let c = close(control[1]), s = close(status[0]), r = close(root), e = close(envFD), q = close(receipt)
    let x = posix_spawn_file_actions_destroy(&actions), y = posix_spawnattr_destroy(&attrs)
    guard raw == 125 << 8, ownerRC == -1, ownerErrno == ENOENT, markerRC == -1, markerErrno == ENOENT,
          [c,s,r,e,q,x,y].allSatisfy({ $0 == 0 }) else { unknown(117) }
    закрытьЗапасной()
    print("mode=changed owner=\(pid) waitpid=\(waited) raw=\(raw) owner_rc=\(ownerRC) owner_errno=\(ownerErrno) marker_rc=\(markerRC) marker_errno=\(markerErrno) cleanup=\(c),\(s),\(r),\(e),\(q),\(x),\(y)")
    exit(0)
}
guard line(status[0]) == "DONE \(run) 0\n" else { unknown(99) }
guard file(receipt,"intent.DATA") == "run=\(run) phase=before-spawn\n", let owner = file(receipt,"owner.DATA") else { unknown(100) }
let fields = owner.split(whereSeparator: { $0.isWhitespace })
guard fields.count == (группа ? 4 : 3), fields[0] == Substring("run=\(run)"), fields[1].hasPrefix("child="),
      let child = Int32(fields[1].dropFirst(6)), child > 1,
      (группа ? fields[2] == Substring("pgid=\(child)") && fields[3] == "phase=before-gate" : fields[2] == "phase=before-gate"),
      file(receipt,"terminal.DATA") == (группа
        ? "run=\(run) child=\(child) pgid=\(child) waitpid=\(child) raw=0 group=ESRCH reuse=UNKNOWN outcome=PRE-CLOSE\n"
        : "run=\(run) child=\(child) waitpid=\(child) raw=0 outcome=PRE-CLOSE\n"),
      file(root,"target.DATA") == "pid=\(child)\n" else { unknown(101) }
var absent = stat(); errno = 0
let unknownRC = fstatat(receipt,"unknown.DATA",&absent,AT_SYMLINK_NOFOLLOW), unknownErrno = errno
guard unknownRC == -1, unknownErrno == ENOENT else { unknown(102) }
let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 5_000_000_000; var raw: Int32 = -1, waited: pid_t = 0
repeat { waited = waitpid(pid,&raw,WNOHANG); if waited == 0 { usleep(10_000) } } while waited == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end
guard waited == pid else { unknown(103) }
собранныйСтатус = raw
var unknownAfter = stat(); errno = 0
let afterRC = fstatat(receipt, "unknown.DATA", &unknownAfter, AT_SYMLINK_NOFOLLOW), afterErrno = errno
guard afterRC == -1, afterErrno == ENOENT else { unknown(105) }
let c = close(control[1]), s = close(status[0]), r = close(root), e = close(envFD), q = close(receipt)
let x = posix_spawn_file_actions_destroy(&actions), y = posix_spawnattr_destroy(&attrs)
guard raw == 0, [c,s,r,e,q,x,y].allSatisfy({ $0 == 0 }) else { unknown(104) }
закрытьЗапасной()
print("mode=\(a[1]) owner=\(pid) child=\(child) waitpid=\(waited) raw=\(raw) unknown_rc=\(unknownRC) errno=\(unknownErrno) unknown_after=\(afterRC) after_errno=\(afterErrno) cleanup=\(c),\(s),\(r),\(e),\(q),\(x),\(y)")
exit(0)

}
