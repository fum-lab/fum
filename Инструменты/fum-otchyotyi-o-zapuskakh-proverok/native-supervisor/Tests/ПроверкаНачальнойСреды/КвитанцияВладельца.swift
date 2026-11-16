import Darwin

// Только собственная синтетическая fixture; частичный эффект остаётся UNKNOWN.
func записатьКвитанциюВладельца(_ каталог: Int32, _ имя: String, _ текст: String) -> Bool {
    let байты = Array(текст.utf8)
    guard каталог > 2, !имя.isEmpty, !имя.contains("/"), байты.count > 0, байты.count <= 512 else { return false }
    var родитель = stat()
    guard fstat(каталог, &родитель) == 0, родитель.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
          родитель.st_uid == getuid(), родитель.st_mode & 0o7777 == 0o700 else { return false }
    let fd = имя.withCString { openat(каталог, $0, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600) }
    guard fd > 2 else { if fd >= 0 { _ = close(fd) }; return false }
    var успех = true
    var смещение = 0
    while смещение < байты.count {
        let результат = байты.withUnsafeBytes { write(fd, $0.baseAddress!.advanced(by: смещение), байты.count - смещение) }
        if результат <= 0 { успех = false; break }
        смещение += результат
    }
    var первая = stat(), последняя = stat(), именованная = stat(), прочитано = [UInt8](repeating: 0, count: байты.count)
    if fstat(fd, &первая) != 0 || первая.st_mode & UInt16(S_IFMT) != UInt16(S_IFREG) ||
       первая.st_mode & 0o7777 != 0o600 || первая.st_uid != getuid() || первая.st_nlink != 1 ||
       первая.st_size != Int64(байты.count) || fsync(fd) != 0 { успех = false }
    let длина = прочитано.withUnsafeMutableBytes { pread(fd, $0.baseAddress, байты.count, 0) }
    if длина != байты.count || прочитано != байты || fstat(fd, &последняя) != 0 ||
       имя.withCString({ fstatat(каталог, $0, &именованная, AT_SYMLINK_NOFOLLOW) }) != 0 ||
       первая.st_dev != последняя.st_dev || первая.st_ino != последняя.st_ino ||
       первая.st_dev != именованная.st_dev || первая.st_ino != именованная.st_ino ||
       последняя.st_mode != первая.st_mode || именованная.st_mode != первая.st_mode ||
       последняя.st_uid != первая.st_uid || именованная.st_uid != первая.st_uid ||
       последняя.st_nlink != 1 || именованная.st_nlink != 1 || последняя.st_size != первая.st_size ||
       именованная.st_size != первая.st_size { успех = false }
    if close(fd) != 0 { успех = false }
    if fsync(каталог) != 0 { успех = false }
    return успех
}
