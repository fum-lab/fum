#if canImport(Darwin)
import Darwin
import Foundation
import Testing
@testable import FUMProcessProtocol

@Test func открытыйКаталогПроверяетТипИМетки() throws {
    let путь = NSTemporaryDirectory() + "fum-directory-fd-" + UUID().uuidString
    try FileManager.default.createDirectory(atPath: путь, withIntermediateDirectories: false,
                                            attributes: [.posixPermissions: 0o700])
    defer { try? FileManager.default.removeItem(atPath: путь) }
    let каталог = open(путь, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    #expect(каталог >= 0)
    guard каталог >= 0 else { return }
    defer { _ = close(каталог) }
    var метка = stat()
    #expect(fstat(каталог, &метка) == 0)
    let устройство = try #require(UInt64(exactly: метка.st_dev))
    func опора(_ fd: Int32, _ инод: UInt64, _ режим: UInt16) throws -> ОпораЗаимствованногоКаталога {
        try #require(ОпораЗаимствованногоКаталога(путь, String(fd), String(устройство), String(инод),
            String(метка.st_uid), String(режим), область: .рабочееДерево, занятыеДескрипторы: []))
    }
    let верная = try опора(каталог, метка.st_ino, метка.st_mode & 0o7777)
    #expect(подтвердитьОткрытыйКаталог(верная))
    let чужоеУстройство = try #require(ОпораЗаимствованногоКаталога(путь, String(каталог), String(устройство ^ 1),
        String(метка.st_ino), String(метка.st_uid), String(метка.st_mode & 0o7777),
        область: .рабочееДерево, занятыеДескрипторы: []))
    let чужойВладелец = try #require(ОпораЗаимствованногоКаталога(путь, String(каталог), String(устройство),
        String(метка.st_ino), String(метка.st_uid ^ 1), String(метка.st_mode & 0o7777),
        область: .рабочееДерево, занятыеДескрипторы: []))
    #expect(!подтвердитьОткрытыйКаталог(чужоеУстройство))
    #expect(!подтвердитьОткрытыйКаталог(чужойВладелец))
    #expect(!подтвердитьОткрытыйКаталог(try опора(каталог, метка.st_ino ^ 1, метка.st_mode & 0o7777)))
    #expect(!подтвердитьОткрытыйКаталог(try опора(каталог, метка.st_ino, (метка.st_mode & 0o7777) ^ 1)))
    let файл = open(путь + "/файл", O_CREAT | O_EXCL | O_RDONLY | O_CLOEXEC, 0o600)
    #expect(файл >= 0)
    guard файл >= 0 else { return }
    defer { _ = close(файл) }
    var меткаФайла = stat()
    #expect(fstat(файл, &меткаФайла) == 0)
    #expect(!подтвердитьОткрытыйКаталог(try опора(файл, меткаФайла.st_ino, меткаФайла.st_mode & 0o7777)))
    let копия = dup(каталог)
    #expect(копия >= 0)
    guard копия >= 0 else { return }
    defer { _ = close(копия) }
    #expect(подтвердитьОткрытыйКаталог(try опора(копия, метка.st_ino, метка.st_mode & 0o7777)))
    let закрытый = dup(каталог)
    #expect(закрытый >= 0)
    guard закрытый >= 0 else { return }
    let закрытаяОпора = try опора(закрытый, метка.st_ino, метка.st_mode & 0o7777)
    #expect(close(закрытый) == 0)
    #expect(!подтвердитьОткрытыйКаталог(закрытаяОпора))
}
#endif
