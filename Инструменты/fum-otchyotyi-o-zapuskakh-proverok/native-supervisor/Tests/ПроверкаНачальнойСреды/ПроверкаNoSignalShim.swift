import Darwin
import Foundation
func проверитьNoSignalShim() -> Never {
let a = CommandLine.arguments
if a.count == 2 && a[1] == "--shim-target" {
    guard let text = getenv("FUM_BORROWED_DIRECTORY_FD"), let fd = Int32(String(cString: text)), fd > 2 else { exit(81) }
    var st = stat()
    guard fstat(fd, &st) == 0, st.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR) else { exit(82) }
    let marker = openat(fd, "target.DATA", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard marker >= 0, close(marker) == 0 else { exit(83) }
    exit(0)
}
guard a.count == 5, ["go", "eof", "wrong"].contains(a[2]),
      a[4].hasPrefix("/private/tmp/fum-nosignal-shim."),
      a[4].dropFirst("/private/tmp/fum-nosignal-shim.".count).utf8.count == 8,
      a[4].dropFirst("/private/tmp/fum-nosignal-shim.".count).utf8.allSatisfy({
          (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0)
      }) else { exit(90) }
let root = open(a[4], O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
var st = stat(), gate = [Int32](repeating: -1, count: 2)
guard root > 2, fstat(root, &st) == 0, st.st_uid == getuid(), st.st_mode & 0o7777 == 0o700, pipe(&gate) == 0,
      Set([root,gate[0],gate[1]]).count == 3, gate.allSatisfy({ $0 > 2 }) else { exit(91) }
var actions: posix_spawn_file_actions_t?, attrs: posix_spawnattr_t?
guard posix_spawn_file_actions_init(&actions) == 0, posix_spawnattr_init(&attrs) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, root) == 0,
      posix_spawn_file_actions_addinherit_np(&actions, gate[0]) == 0,
      posix_spawnattr_setflags(&attrs, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { exit(92) }
let inode = a[2] == "wrong" ? st.st_ino ^ 1 : st.st_ino
let values = [a[3], "fum-nosignal-shim.1", a[4], String(root), String(st.st_dev), String(inode), String(st.st_uid), String(st.st_mode & 0o7777), String(gate[0]), "--", a[0], "--shim-target"]
let argv = values.map { strdup($0) } + [nil]
var env: [UnsafeMutablePointer<CChar>?] = [nil]
var pid: pid_t = 0
let rc = argv.withUnsafeBufferPointer { p in env.withUnsafeMutableBufferPointer { e in posix_spawn(&pid, a[3], &actions, &attrs, UnsafeMutablePointer(mutating:p.baseAddress), e.baseAddress) } }
for p in argv { free(p) }
guard rc == 0, pid > 1 else { exit(93) }
_ = signal(SIGPIPE, SIG_IGN)
guard close(gate[0]) == 0 else { exit(94) }
if a[2] == "go" { var byte: UInt8 = 0x47; guard write(gate[1], &byte, 1) == 1 else { exit(95) } }
guard close(gate[1]) == 0 else { exit(96) }
let deadline = clock_gettime_nsec_np(CLOCK_UPTIME_RAW) + 3_000_000_000
var raw: Int32 = -1, result: pid_t = 0
repeat { result = waitpid(pid, &raw, WNOHANG); if result == 0 { usleep(10_000) } } while result == 0 && clock_gettime_nsec_np(CLOCK_UPTIME_RAW) < deadline
guard result == pid else { fputs("UNKNOWN pid=\(pid) wait=\(result) errno=\(errno)\n", stderr); exit(97) }
var marker = stat(); let markerRC = fstatat(root, "target.DATA", &marker, AT_SYMLINK_NOFOLLOW); let markerErrno = errno
let expected = a[2] == "go" ? Int32(0) : Int32(125 << 8)
let ok = raw == expected && (a[2] == "go" ? markerRC == 0 : (markerRC == -1 && markerErrno == ENOENT))
let x = posix_spawn_file_actions_destroy(&actions), y = posix_spawnattr_destroy(&attrs), z = close(root)
print("mode=\(a[2]) child=\(pid) waitpid=\(result) raw=\(raw) marker_rc=\(markerRC) marker_errno=\(markerErrno) cleanup=\(x),\(y),\(z)")
exit(ok && x == 0 && y == 0 && z == 0 ? 0 : 98)

}
