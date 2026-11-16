import Darwin
import Foundation
@available(macOS 13.0, *)
func проверитьNoSignalOwner() -> Never {
let исходные = CommandLine.arguments
let a = исходные.count > 1 && исходные[1] == "--проверить-owner" ? [исходные[0]] + Array(исходные.dropFirst(2)) : исходные
if a.count == 2 && ["--owner-target", "--owner-target-fail", "--owner-target-wait"].contains(a[1]) {
    guard let value = getenv("FUM_BORROWED_DIRECTORY_FD"), let fd = Int32(String(cString:value)), fd > 2 else { exit(81) }
    var st = stat(); guard fstat(fd, &st) == 0, st.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR) else { exit(82) }
    let marker = openat(fd, "target.DATA", O_CREAT | O_EXCL | O_WRONLY | O_NOFOLLOW, 0o600)
    guard marker >= 0, close(marker) == 0 else { exit(83) }
    if a[1] == "--owner-target-wait" {
        let fifo = openat(fd, "release", O_RDONLY | O_NOFOLLOW)
        guard fifo > 2 else { exit(84) }
        var byte: UInt8 = 0
        guard read(fifo, &byte, 1) == 1, byte == 0x52, close(fifo) == 0 else { exit(85) }
    }
    exit(a[1] == "--owner-target-fail" ? 7 : 0)
}
guard a.count == 5, ["success", "nonzero", "timeout", "loss"].contains(a[1]), a[3].hasSuffix("/root") else { exit(90) }
let base = String(a[3].dropLast(5)), prefix = "/private/tmp/fum-nosignal-owner."
guard base.hasPrefix(prefix), a[4] == base + "/receipt",
      base.dropFirst(prefix.count).utf8.count == 8,
      base.dropFirst(prefix.count).utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else { exit(90) }
let root = open(a[3], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
let receipt = open(a[4], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
var st = stat(), receiptStat = stat(), control = [Int32](repeating:-1,count:2), status = [Int32](repeating:-1,count:2)
guard root > 2, receipt > 2, fstat(root, &st) == 0, fstat(receipt, &receiptStat) == 0,
      st.st_uid == getuid(), receiptStat.st_uid == getuid(),
      st.st_mode & 0o7777 == 0o700, receiptStat.st_mode & 0o7777 == 0o700,
      pipe(&control) == 0, pipe(&status) == 0,
      Set([root,receipt]+control+status).count == 6, (control+status).allSatisfy({ $0 > 2 }) else { exit(91) }
var release: Int32 = -1
if a[1] == "timeout" || a[1] == "loss" {
    guard mkfifoat(root, "release", 0o600) == 0 else { exit(92) }
    release = openat(root, "release", O_RDWR | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
    guard release > 2 else { exit(92) }
}
var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?
guard posix_spawn_file_actions_init(&actions) == 0, posix_spawnattr_init(&attrs) == 0,
      posix_spawn_file_actions_adddup2(&actions, control[0], STDIN_FILENO) == 0,
      posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
      posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, root) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, receipt) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, status[1]) == 0,
      posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { exit(93) }
let run = "00112233-4455-4677-8899-aabbccddeeff"
let limit = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) / 1_000_000 + (a[1] == "timeout" ? 700 : 5_000)
let targetMode = a[1] == "success" ? "--owner-target" : (a[1] == "nonzero" ? "--owner-target-fail" : "--owner-target-wait")
let values = [a[2], "fum-nosignal-owner.1", run, String(limit), String(status[1]), a[3], String(root), String(st.st_dev), String(st.st_ino), String(st.st_uid), String(st.st_mode & 0o7777), String(receipt), "--", a[0], targetMode]
let argv = values.map { strdup($0) } + [nil]
var env: [UnsafeMutablePointer<CChar>?] = [nil]; var pid: pid_t = 0
let spawn = argv.withUnsafeBufferPointer { p in env.withUnsafeMutableBufferPointer { e in posix_spawn(&pid, a[2], &actions, &attrs, UnsafeMutablePointer(mutating:p.baseAddress), e.baseAddress) } }
for p in argv { free(p) }
guard spawn == 0, pid > 1 else { exit(94) }
let started = Array("START owner=\(pid)\n".utf8)
_ = started.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, started.count) }
_ = fsync(STDERR_FILENO)
func unknown(_ code: Int32) -> Never {
    let line = Array("UNKNOWN owner=\(pid) phase=\(code)\n".utf8)
    _ = line.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, line.count) }
    _ = fsync(STDERR_FILENO)
    while true { usleep(100_000) }
}
_ = signal(SIGPIPE, SIG_IGN)
guard close(control[0]) == 0, close(status[1]) == 0 else { unknown(95) }
func line(_ fd: Int32, seconds: UInt64) -> String? {
    let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + seconds * 1_000_000_000
    var bytes = [UInt8]()
    while bytes.count < 256 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end {
        var p = pollfd(fd:fd, events:Int16(POLLIN | POLLHUP), revents:0)
        let n = poll(&p, 1, 100)
        if n < 0 { return nil }; if n == 0 { continue }
        var ch: UInt8 = 0; guard read(fd, &ch, 1) == 1 else { return nil }
        bytes.append(ch); if ch == 10 { return String(bytes:bytes, encoding:.utf8) }
    }
    return nil
}
guard line(status[0], seconds: 5) == "READY \(run)\n" else { unknown(96) }
var go: UInt8 = 0x47; guard write(control[1], &go, 1) == 1 else { unknown(97) }
if a[1] == "loss" {
    let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 3_000_000_000
    var marker = stat(); var found = false
    while clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end {
        if fstatat(root, "target.DATA", &marker, AT_SYMLINK_NOFOLLOW) == 0 { found = true; break }
        usleep(10_000)
    }
    guard found, close(control[1]) == 0 else { unknown(98) }
}
func receiptBytes(_ name: String) -> String? {
    let fd = name.withCString { openat(receipt, $0, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC) }
    guard fd > 2 else { return nil }
    var info = stat(), data = [UInt8](repeating: 0, count: 512)
    guard fstat(fd, &info) == 0, info.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG),
          info.st_uid == getuid(), info.st_mode & 0o7777 == 0o600, info.st_nlink == 1,
          info.st_size > 0, info.st_size <= 512 else { _ = close(fd); return nil }
    let count = data.withUnsafeMutableBytes { pread(fd, $0.baseAddress, Int(info.st_size), 0) }
    let closed = close(fd)
    guard count == info.st_size, closed == 0 else { return nil }
    return String(bytes: data.prefix(count), encoding: .utf8)
}
guard let frame = line(status[0], seconds: 6) else { unknown(99) }
let observedMS = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) / 1_000_000
if a[1] == "loss" && observedMS >= limit { unknown(105) }
var targetMarker = stat()
guard fstatat(root, "target.DATA", &targetMarker, AT_SYMLINK_NOFOLLOW) == 0,
      targetMarker.st_mode & UInt16(S_IFMT) == UInt16(S_IFREG), targetMarker.st_size == 0 else { unknown(106) }
guard receiptBytes("intent.DATA") == "run=\(run) phase=before-spawn\n",
      let ownerRecord = receiptBytes("owner.DATA") else { unknown(107) }
let ownerFields = ownerRecord.split(whereSeparator: { $0.isWhitespace })
guard ownerFields.count == 3, ownerFields[0] == Substring("run=\(run)"),
      ownerFields[1].hasPrefix("child="), let child = Int32(ownerFields[1].dropFirst(6)), child > 1,
      ownerFields[2] == "phase=before-gate" else { unknown(108) }
if a[1] == "success" || a[1] == "nonzero" {
    let targetRaw = a[1] == "success" ? 0 : (7 << 8)
    // DONE описывает сбор raw, а не успешность target.
    guard frame == "DONE \(run) \(targetRaw)\n",
          receiptBytes("terminal.DATA") == "run=\(run) child=\(child) waitpid=\(child) raw=\(targetRaw) outcome=PRE-CLOSE\n" else { unknown(100) }
}
else {
    let fields = frame.split(whereSeparator: { $0.isWhitespace })
    let expectedReason = a[1] == "timeout" ? "deadline" : "peer"
    guard fields.count == 5, fields[0] == "UNKNOWN", fields[1] == Substring(run),
          fields[2] == Substring(expectedReason), let recorded = UInt64(fields[3]),
          fields[4] == Substring(String(limit)),
          (a[1] == "timeout" ? recorded >= limit : recorded < limit),
          receiptBytes("unknown.DATA") == "run=\(run) child=\(child) outcome=UNKNOWN reason=\(expectedReason) observed_ms=\(recorded) deadline_ms=\(limit)\n" else { unknown(101) }
    var byte: UInt8 = 0x52; guard write(release, &byte, 1) == 1, close(release) == 0 else { unknown(102) }
}
let end = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 5_000_000_000
var raw: Int32 = -1, waited: pid_t = 0
repeat { waited = waitpid(pid, &raw, WNOHANG); if waited == 0 { usleep(10_000) } } while waited == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < end
guard waited == pid else { unknown(103) }
let expected: Int32 = a[1] == "success" || a[1] == "nonzero" ? 0 : 125 << 8
if a[1] == "timeout" || a[1] == "loss" {
    guard receiptBytes("reap.DATA") == "run=\(run) child=\(child) waitpid=\(child) raw=0 outcome=UNKNOWN\n" else { unknown(109) }
}
let c = a[1] == "loss" ? Int32(0) : close(control[1]); let s = close(status[0]), r = close(root), q = close(receipt)
let x = posix_spawn_file_actions_destroy(&actions), y = posix_spawnattr_destroy(&attrs)
print("mode=\(a[1]) owner=\(pid) child=\(child) waitpid=\(waited) raw=\(raw) frame=\(frame.trimmingCharacters(in:.newlines)) observed_ms=\(observedMS) deadline_ms=\(limit) marker_rc=0 marker_size=0 cleanup=\(c),\(s),\(r),\(q),\(x),\(y)")
exit(raw == expected && [c,s,r,q,x,y].allSatisfy({ $0 == 0 }) ? 0 : 104)

}
