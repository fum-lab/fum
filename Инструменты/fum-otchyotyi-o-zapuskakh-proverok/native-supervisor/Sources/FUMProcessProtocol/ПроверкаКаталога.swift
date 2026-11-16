#if canImport(Darwin)
import Darwin

/// Проверяет только открытый объект в момент вызова. Путь, предки и custody не подтверждаются.
public func подтвердитьОткрытыйКаталог(_ опора: ОпораЗаимствованногоКаталога) -> Bool {
    guard getuid() == geteuid(), опора.владелец == getuid() else { return false }
    let флаги = fcntl(опора.дескриптор, F_GETFL)
    let флагиДескриптора = fcntl(опора.дескриптор, F_GETFD)
    guard флаги >= 0, флаги & O_ACCMODE == O_RDONLY, флагиДескриптора >= 0 else { return false }
    var метка = stat()
    guard fstat(опора.дескриптор, &метка) == 0 else { return false }
    return метка.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR) &&
        метка.st_mode & 0o7777 == опора.режим && метка.st_uid == опора.владелец &&
        UInt64(exactly: метка.st_dev) == опора.устройство && метка.st_ino == опора.инод
}
#endif
