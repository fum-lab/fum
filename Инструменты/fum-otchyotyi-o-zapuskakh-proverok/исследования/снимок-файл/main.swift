import Foundation
import Darwin
func stop(_ message: String) -> Never { print("HOLD \(message)"); exit(2) }
func identity(_ a: stat, _ b: stat) -> Bool { a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_mode == b.st_mode }
func same(_ a: stat, _ b: stat) -> Bool { identity(a,b) && a.st_size == b.st_size && a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec && a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec }
guard CommandLine.arguments.count == 3 else { stop("arguments") }
let base = CommandLine.arguments[1], mode = CommandLine.arguments[2]
let root = open(base, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
guard root >= 0 else { stop("root") }
let src = openat(root, "source", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
let dst = openat(root, "destination", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
guard src >= 0 && dst >= 0 else { stop("directories") }
var sourceDir = stat(), destDir = stat(), now = stat(), byName = stat()
guard fstat(src, &sourceDir) == 0 && fstat(dst, &destDir) == 0 else { stop("directories stat") }
func dirsOK() -> Bool { fstat(src, &now) == 0 && identity(sourceDir, now) && fstatat(root, "source", &byName, AT_SYMLINK_NOFOLLOW) == 0 && identity(sourceDir, byName) && fstat(dst, &now) == 0 && identity(destDir, now) && fstatat(root, "destination", &byName, AT_SYMLINK_NOFOLLOW) == 0 && identity(destDir, byName) }
let input = openat(src, "file", O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
var before = stat(), after = stat(), path = stat()
guard input >= 0 && fstat(input, &before) == 0 && (before.st_mode & S_IFMT) == S_IFREG && before.st_size >= 0 && before.st_size <= 65536 else { stop("source") }
var bytes = [UInt8](repeating: 0, count: Int(before.st_size)); var nread = 0
while nread < bytes.count { let n = bytes.withUnsafeMutableBytes { read(input, $0.baseAddress!.advanced(by: nread), $0.count - nread) }; guard n > 0 else { stop("read") }; nread += n }
if mode == "replace-file" { guard renameat(src, "replacement", src, "file") == 0 else { stop("fixture file") } }
if mode == "replace-dir" { guard renameat(root, "source", root, "old-source") == 0 && renameat(root, "replacement-dir", root, "source") == 0 else { stop("fixture dir") } }
guard dirsOK(), fstat(input, &after) == 0, fstatat(src, "file", &path, AT_SYMLINK_NOFOLLOW) == 0, same(before, after), same(before, path) else { stop("source changed") }
let out = openat(dst, "copy", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
guard out >= 0 else { stop("destination open") }
var wrote = 0
while wrote < bytes.count { let n = bytes.withUnsafeBytes { write(out, $0.baseAddress!.advanced(by: wrote), $0.count - wrote) }; guard n > 0 else { stop("write") }; wrote += n }
guard fsync(out) == 0 && close(out) == 0 else { stop("fsync") }
let check = openat(dst, "copy", O_RDONLY | O_NOFOLLOW | O_CLOEXEC); guard check >= 0 else { stop("readback open") }
var copied = [UInt8](repeating: 0, count: bytes.count); var used = 0
while used < copied.count { let n = copied.withUnsafeMutableBytes { read(check, $0.baseAddress!.advanced(by: used), $0.count - used) }; guard n > 0 else { stop("readback") }; used += n }
var extra: UInt8 = 0
guard read(check, &extra, 1) == 0 && copied == bytes && dirsOK() && fstat(input, &after) == 0 && fstatat(src, "file", &path, AT_SYMLINK_NOFOLLOW) == 0 && same(before, after) && same(before, path) && fsync(dst) == 0 else { stop("postcheck") }
print("PASS copied bytes=\(bytes.count)")
