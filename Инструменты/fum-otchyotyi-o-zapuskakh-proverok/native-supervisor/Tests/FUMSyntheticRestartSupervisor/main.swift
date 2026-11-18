#if canImport(Darwin)
import CryptoKit
import Darwin
import Foundation

private enum ОшибкаSupervisor: Error { case отказ }

private func hold() -> Never { while true { _ = pause() } }

private func hash(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func readPinned(_ path: String, limit: Int) throws -> Data {
    var before = stat()
    guard lstat(path, &before) == 0, (before.st_mode & S_IFMT) == S_IFREG, before.st_nlink == 1,
          before.st_uid == geteuid(), before.st_size >= 0, before.st_size <= limit else { throw ОшибкаSupervisor.отказ }
    let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
    guard fd > 2 else { throw ОшибкаSupervisor.отказ }
    defer { _ = close(fd) }
    var start = stat()
    guard fstat(fd, &start) == 0, start.st_dev == before.st_dev, start.st_ino == before.st_ino,
          start.st_size == before.st_size else { throw ОшибкаSupervisor.отказ }
    var data = Data(count: Int(before.st_size)), offset = 0
    while offset < data.count {
        let remaining = data.count - offset
        let n = data.withUnsafeMutableBytes { read(fd, $0.baseAddress!.advanced(by: offset), remaining) }
        guard n > 0 else { throw ОшибкаSupervisor.отказ }
        offset += n
    }
    var after = stat(), named = stat()
    guard fstat(fd, &after) == 0, lstat(path, &named) == 0, after.st_dev == before.st_dev,
          after.st_ino == before.st_ino, after.st_size == before.st_size,
          after.st_mtimespec.tv_sec == before.st_mtimespec.tv_sec, after.st_mtimespec.tv_nsec == before.st_mtimespec.tv_nsec,
          after.st_ctimespec.tv_sec == before.st_ctimespec.tv_sec, after.st_ctimespec.tv_nsec == before.st_ctimespec.tv_nsec,
          named.st_dev == before.st_dev, named.st_ino == before.st_ino else { throw ОшибкаSupervisor.отказ }
    return data
}

private struct ReceiptAttempt {
    let name: String
    var fd: Int32
    var phase: String
}
@MainActor private enum ReceiptRegistry { static var attempts: [ReceiptAttempt] = [] }

@MainActor private func receipt(_ dir: Int32, _ name: String, _ data: Data) throws {
    guard data.count <= 16_384 else { throw ОшибкаSupervisor.отказ }
    let fd = openat(dir, name, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard fd > 2 else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts.append(ReceiptAttempt(name: name, fd: fd, phase: "write"))
    let attempt = ReceiptRegistry.attempts.count - 1
    var position = 0
    while position < data.count {
        let n = data.withUnsafeBytes { write(fd, $0.baseAddress!.advanced(by: position), data.count - position) }
        guard n > 0 else { throw ОшибкаSupervisor.отказ }
        position += n
    }
    guard fsync(fd) == 0 else { throw ОшибкаSupervisor.отказ }
    var mark = stat()
    guard fstat(fd, &mark) == 0, mark.st_size == data.count else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts[attempt].phase = "close-started"
    guard close(fd) == 0 else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts[attempt].phase = "closed"
    guard fsync(dir) == 0 else { throw ОшибкаSupervisor.отказ }
    let check = openat(dir, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
    guard check > 2 else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts.append(ReceiptAttempt(name: name, fd: check, phase: "readback"))
    let readAttempt = ReceiptRegistry.attempts.count - 1
    var bytes = [UInt8](repeating: 0, count: data.count + 1), now = stat(), named = stat()
    let n = bytes.withUnsafeMutableBytes { read(check, $0.baseAddress, $0.count) }
    guard fstat(check, &now) == 0, fstatat(dir, name, &named, AT_SYMLINK_NOFOLLOW) == 0,
          now.st_dev == mark.st_dev, now.st_ino == mark.st_ino,
          named.st_dev == mark.st_dev, named.st_ino == mark.st_ino,
          n == data.count, Data(bytes.prefix(n)) == data else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts[readAttempt].phase = "close-started"
    guard close(check) == 0 else { throw ОшибкаSupervisor.отказ }
    ReceiptRegistry.attempts[readAttempt].phase = "closed"
}

private func ownerReadback(_ text: String) throws -> Data {
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    guard let first = lines.first(where: { $0.hasPrefix("synthetic-fixture=") }),
          let last = lines.first(where: { $0.hasPrefix("synthetic-owner-reap ") }),
          text.hasSuffix("\n") else { throw ОшибкаSupervisor.отказ }
    let base = String(first.dropFirst("synthetic-fixture=".count))
    guard base.hasPrefix("/private/tmp/fum-swift-restart-"),
          URL(fileURLWithPath: base).resolvingSymlinksInPath().path == base,
          last.contains(" raw=18688 peer=256 control=0 eof=true fixture=" + base) else { throw ОшибкаSupervisor.отказ }
    let names = ["PREFLIGHT", "PARENT-INTENT", "OWNER-ARGV", "OWNER-START", "CHILD-PREFLIGHT", "GO-INTENT",
                 "FRAME", "OWNER-REAP", "READBACK", "CONTROL-INTENT", "CONTROL-ARGV", "CONTROL-START",
                 "CONTROL-FRAME", "CONTROL-REAP", "PEER-ARGV", "PEER-ENV", "PEER-START", "PEER-STDOUT",
                 "PEER-STDERR", "PEER-REAP", "OBSERVATION"]
    var hashes: [String: String] = [:]
    for name in names { hashes[name] = hash(try readPinned(base + "/" + name, limit: 4096)) }
    guard let ownerWait = String(data: try readPinned(base + "/OWNER-REAP", limit: 4096), encoding: .utf8),
          ownerWait.contains(" raw=18688 eof=true"),
          let controlWait = String(data: try readPinned(base + "/CONTROL-REAP", limit: 4096), encoding: .utf8),
          controlWait.contains(" raw=0 eof=true"),
          let peerWait = String(data: try readPinned(base + "/PEER-REAP", limit: 4096), encoding: .utf8),
          peerWait.contains(" raw=256 eof=true") else { throw ОшибкаSupervisor.отказ }
    return try JSONSerialization.data(withJSONObject: ["owner_fixture": base, "sha256": hashes], options: [.sortedKeys])
}

@MainActor private func run() throws {
    guard unsafeBitCast(signal(SIGPIPE, SIG_IGN), to: Int.self) != -1 else { throw ОшибкаSupervisor.отказ }
    let args = CommandLine.arguments
    guard args.count == 7, getuid() == geteuid(), getuid() != 0 else { throw ОшибкаSupervisor.отказ }
    let owner = args[1], ownerSHA = args[2], source = args[3], sourceSHA = args[4], test = args[5], testSHA = args[6]
    for (path, digest, limit) in [(owner, ownerSHA, 64 * 1024 * 1024), (source, sourceSHA, 16 * 1024 * 1024),
                                   (test, testSHA, 16 * 1024 * 1024)] {
        guard path.hasPrefix("/Users/Shared/FUM-private-501/"), digest.count == 64,
              path == URL(fileURLWithPath: path).resolvingSymlinksInPath().path,
              hash(try readPinned(path, limit: limit)) == digest else { throw ОшибкаSupervisor.отказ }
    }
    var template = Array("/private/tmp/fum-restart-supervisor-XXXXXXXX\0".utf8CString)
    guard let value = mkdtemp(&template) else { throw ОшибкаSupervisor.отказ }
    let base = String(cString: value)
    let dir = open(base, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    guard dir > 2 else { throw ОшибкаSupervisor.отказ }
    let runID = UUID().uuidString.lowercased()
    let preflight = Data("run=\(runID) uid=\(getuid()) euid=\(geteuid()) owner=\(owner) sha=\(ownerSHA) source=\(source) sha=\(sourceSHA) test=\(test) sha=\(testSHA) env=empty\n".utf8)
var streams = [Data(), Data()], eof = [false, false], truncated = [false, false]
var raw: Int32 = 0, reaped = false, pid: pid_t = 0
var reason = "setup-error"
func retainUnknown() -> Never {
    // Each receipt is attempted independently; no pipe is read or closed here.
    try? receipt(dir, "OWNER-STDOUT-PARTIAL", streams[0])
    try? receipt(dir, "OWNER-STDERR-PARTIAL", streams[1])
    if reaped { try? receipt(dir, "OWNER-REAP-PARTIAL", Data("run=\(runID) pid=\(pid) raw=\(raw)\n".utf8)) }
    let state = "run=\(runID) stdout_eof=\(eof[0]) stderr_eof=\(eof[1]) stdout_truncated=\(truncated[0]) stderr_truncated=\(truncated[1]) reaped=\(reaped) reason=\(reason) terminal=false\n"
    try? receipt(dir, "OWNER-STREAM-STATE", Data(state.utf8))
    try? receipt(dir, "HOLD", Data("run=\(runID) pid=\(pid) state=UNKNOWN reason=\(reason)\n".utf8))
    let marker = Data("supervisor-HOLD run=\(runID) pid=\(pid) receipt=\(base) reason=\(reason)\n".utf8)
    _ = marker.withUnsafeBytes { write(STDOUT_FILENO, $0.baseAddress, $0.count) }
    hold()
}
do {
    reason = "preflight-error"
    try receipt(dir, "PREFLIGHT", preflight)
    reason = "intent-error"
    try receipt(dir, "INTENT", Data("fum.synthetic-supervisor-intent.1 run=\(runID) state=UNKNOWN\n".utf8))
    let announce = Data("supervisor-fixture=\(base) run=\(runID)\n".utf8)
        guard announce.withUnsafeBytes({ write(STDOUT_FILENO, $0.baseAddress, $0.count) }) == announce.count else { retainUnknown() }
        var out: [Int32] = [-1, -1], err: [Int32] = [-1, -1]
        guard pipe(&out) == 0, pipe(&err) == 0 else { retainUnknown() }
        for fd in out + err { if fcntl(fd, F_SETFD, FD_CLOEXEC) != 0 { retainUnknown() } }
        var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&actions) == 0, posix_spawnattr_init(&attrs) == 0,
              posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0) == 0,
              posix_spawn_file_actions_adddup2(&actions, out[1], 1) == 0,
              posix_spawn_file_actions_adddup2(&actions, err[1], 2) == 0,
              posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { retainUnknown() }
        let arguments = [owner]
        try receipt(dir, "ARGV", try JSONSerialization.data(withJSONObject: arguments))
        let argv = arguments.map { strdup($0) } + [nil]
        var env: [UnsafeMutablePointer<CChar>?] = [nil]
        let status = argv.withUnsafeBufferPointer { a in env.withUnsafeMutableBufferPointer { e in
            posix_spawn(&pid, owner, &actions, &attrs, UnsafeMutablePointer(mutating: a.baseAddress), e.baseAddress)
        } }
        guard status == 0, pid > 1 else { retainUnknown() }
        try receipt(dir, "START", Data("run=\(runID) pid=\(pid)\n".utf8))
        if close(out[1]) != 0 || close(err[1]) != 0 { retainUnknown() }
        for fd in [out[0], err[0]] { if fcntl(fd, F_SETFL, O_NONBLOCK) != 0 { retainUnknown() } }
        reason = "capture-error"
        for _ in 0..<3000 {
            for (i, fd) in [out[0], err[0]].enumerated() where !eof[i] {
                var bytes = [UInt8](repeating: 0, count: 16_385 - streams[i].count)
                let n = bytes.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
                if n > 0 { let remaining = 16_384 - streams[i].count; streams[i].append(contentsOf: bytes.prefix(min(n, remaining))); if n > remaining { truncated[i] = true; reason = "stream-overflow"; retainUnknown() } }
                else if n == 0 { eof[i] = true }
                else if errno != EAGAIN && errno != EINTR { reason = "stream-read-error"; retainUnknown() }
            }
            let wait = waitpid(pid, &raw, WNOHANG)
            if wait == pid { reaped = true } else if wait < 0 { reason = "wait-error"; retainUnknown() }
            if reaped { break }
            if let text = String(data: streams[0], encoding: .utf8), text.contains("synthetic-owner-reap "), text.hasSuffix("\n") {
                reason = "owner-readback-or-receipt-error"
                let readback = try ownerReadback(text)
                try receipt(dir, "OWNER-READBACK", readback)
                try receipt(dir, "OWNER-STDOUT", streams[0])
                try receipt(dir, "OWNER-STDERR", streams[1])
                try receipt(dir, "HOLD", Data("run=\(runID) pid=\(pid) state=UNKNOWN reason=owner-marker-not-reap\n".utf8))
                let marker = Data("supervisor-HOLD run=\(runID) pid=\(pid) receipt=\(base)\n".utf8)
                _ = marker.withUnsafeBytes { write(STDOUT_FILENO, $0.baseAddress, $0.count) }
                hold()
            }
            usleep(10_000)
            }
            reason = reaped ? "owner-exited" : "timeout"
            retainUnknown()
    } catch { retainUnknown() }
}

do { try run() } catch {
    let message = Data("synthetic supervisor отказ до intent\n".utf8)
    _ = message.withUnsafeBytes { write(STDERR_FILENO, $0.baseAddress, $0.count) }
    exit(1)
}
#endif
