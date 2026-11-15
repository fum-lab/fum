import Foundation
import Darwin

// Синтетический срез: вызывающий удерживает дескриптор и обеспечивает единственного писателя.
public enum исход_записи { case завершено, без_изменения, отказ_до_записи, неизвестно }
public struct метка_файла { public let устройство: dev_t; public let индекс: ino_t; public init(устройство: dev_t, индекс: ino_t) { self.устройство=устройство; self.индекс=индекс } }
func тестово_записать(_ дескриптор: Int32, метка: метка_файла, исходные: Data, новые: Data,
                             _писать: (Int32, UnsafeRawPointer, Int, off_t) -> Int = { Darwin.pwrite($0,$1,$2,$3) }) -> исход_записи {
    guard исходные.count<=4_194_304, новые.count<=4_194_304 else { return .отказ_до_записи }
    var до=stat(); guard fstat(дескриптор,&до)==0, до.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), до.st_nlink==1, до.st_dev==метка.устройство, до.st_ino==метка.индекс, до.st_size==off_t(исходные.count) else { return .отказ_до_записи }
    var прочитано=Data(count:исходные.count); var смещение=0
    while смещение<прочитано.count {
        let оставлено=прочитано.count-смещение
        let количество=прочитано.withUnsafeMutableBytes { Darwin.pread(дескриптор,$0.baseAddress!.advanced(by:смещение),оставлено,off_t(смещение)) }
        guard количество>0 else { return .отказ_до_записи }; смещение += количество
    }
    var после=stat(); guard прочитано==исходные, fstat(дескриптор,&после)==0, после.st_dev==до.st_dev, после.st_ino==до.st_ino, после.st_size==до.st_size, после.st_mtimespec.tv_sec==до.st_mtimespec.tv_sec, после.st_mtimespec.tv_nsec==до.st_mtimespec.tv_nsec, после.st_ctimespec.tv_sec==до.st_ctimespec.tv_sec, после.st_ctimespec.tv_nsec==до.st_ctimespec.tv_nsec else { return .отказ_до_записи }
    if новые==исходные { return .без_изменения }
    смещение=0
    while смещение<новые.count {
        let количество=новые.withUnsafeBytes { _писать(дескриптор,$0.baseAddress!.advanced(by:смещение),новые.count-смещение,off_t(смещение)) }
        guard количество>0 && количество<=новые.count-смещение else { return .неизвестно }; смещение += количество
    }
    guard ftruncate(дескриптор,off_t(новые.count))==0, fsync(дескриптор)==0 else { return .неизвестно }
    var итог=stat(); guard fstat(дескриптор,&итог)==0, итог.st_dev==до.st_dev, итог.st_ino==до.st_ino, итог.st_nlink==1, итог.st_size==off_t(новые.count) else { return .неизвестно }
    var проверка=Data(count:новые.count); смещение=0
    while смещение<проверка.count {
        let осталось=проверка.count-смещение
        let количество=проверка.withUnsafeMutableBytes { Darwin.pread(дескриптор,$0.baseAddress!.advanced(by:смещение),осталось,off_t(смещение)) }
        guard количество>0 else { return .неизвестно }; смещение += количество
    }
    var лишний: UInt8=0
    guard pread(дескриптор,&лишний,1,off_t(новые.count))==0 else { return .неизвестно }
    var окончательно=stat()
    guard проверка==новые, fstat(дескриптор,&окончательно)==0, окончательно.st_dev==итог.st_dev, окончательно.st_ino==итог.st_ino, окончательно.st_size==итог.st_size, окончательно.st_nlink==итог.st_nlink, окончательно.st_mtimespec.tv_sec==итог.st_mtimespec.tv_sec, окончательно.st_mtimespec.tv_nsec==итог.st_mtimespec.tv_nsec, окончательно.st_ctimespec.tv_sec==итог.st_ctimespec.tv_sec, окончательно.st_ctimespec.tv_nsec==итог.st_ctimespec.tv_nsec else { return .неизвестно }
    return .завершено
}
func записать_по_дескриптору(_ дескриптор: Int32, метка: метка_файла, исходные: Data, новые: Data) -> исход_записи {
    тестово_записать(дескриптор,метка:метка,исходные:исходные,новые:новые)
}
