import Foundation
import Darwin

// Синтетический срез: вызывающий удерживает дескриптор и обеспечивает единственного писателя.
public enum исход_записи { case завершено, без_изменения, отказ_до_записи, неизвестно }
public struct метка_файла { public let устройство: dev_t; public let индекс: ino_t; public init(устройство Устройство: dev_t, индекс Индекс: ino_t) { self.устройство=Устройство; self.индекс=Индекс } }
func тестово_записать(_ Дескриптор: Int32, метка Метка: метка_файла, исходные Исходные: Data, новые Новые: Data,
                             _писать Писать: (Int32, UnsafeRawPointer, Int, off_t) -> Int = { Darwin.pwrite($0,$1,$2,$3) }) -> исход_записи {
    guard Исходные.count<=4_194_304, Новые.count<=4_194_304 else { return .отказ_до_записи }
    var До=stat(); guard fstat(Дескриптор,&До)==0, До.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), До.st_nlink==1, До.st_dev==Метка.устройство, До.st_ino==Метка.индекс, До.st_size==off_t(Исходные.count) else { return .отказ_до_записи }
    var Прочитано=Data(count:Исходные.count); var Смещение=0
    while Смещение<Прочитано.count {
        let Оставлено=Прочитано.count-Смещение
        let Количество=Прочитано.withUnsafeMutableBytes { Darwin.pread(Дескриптор,$0.baseAddress!.advanced(by:Смещение),Оставлено,off_t(Смещение)) }
        guard Количество>0 else { return .отказ_до_записи }; Смещение += Количество
    }
    var После=stat(); guard Прочитано==Исходные, fstat(Дескриптор,&После)==0, После.st_dev==До.st_dev, После.st_ino==До.st_ino, После.st_size==До.st_size, После.st_mtimespec.tv_sec==До.st_mtimespec.tv_sec, После.st_mtimespec.tv_nsec==До.st_mtimespec.tv_nsec, После.st_ctimespec.tv_sec==До.st_ctimespec.tv_sec, После.st_ctimespec.tv_nsec==До.st_ctimespec.tv_nsec else { return .отказ_до_записи }
    if Новые==Исходные { return .без_изменения }
    Смещение=0
    while Смещение<Новые.count {
        let Количество=Новые.withUnsafeBytes { Писать(Дескриптор,$0.baseAddress!.advanced(by:Смещение),Новые.count-Смещение,off_t(Смещение)) }
        guard Количество>0 && Количество<=Новые.count-Смещение else { return .неизвестно }; Смещение += Количество
    }
    guard ftruncate(Дескриптор,off_t(Новые.count))==0, fsync(Дескриптор)==0 else { return .неизвестно }
    var Итог=stat(); guard fstat(Дескриптор,&Итог)==0, Итог.st_dev==До.st_dev, Итог.st_ino==До.st_ino, Итог.st_nlink==1, Итог.st_size==off_t(Новые.count) else { return .неизвестно }
    var Проверка=Data(count:Новые.count); Смещение=0
    while Смещение<Проверка.count {
        let Осталось=Проверка.count-Смещение
        let Количество=Проверка.withUnsafeMutableBytes { Darwin.pread(Дескриптор,$0.baseAddress!.advanced(by:Смещение),Осталось,off_t(Смещение)) }
        guard Количество>0 else { return .неизвестно }; Смещение += Количество
    }
    var Лишний: UInt8=0
    guard pread(Дескриптор,&Лишний,1,off_t(Новые.count))==0 else { return .неизвестно }
    var Окончательно=stat()
    guard Проверка==Новые, fstat(Дескриптор,&Окончательно)==0, Окончательно.st_dev==Итог.st_dev, Окончательно.st_ino==Итог.st_ino, Окончательно.st_size==Итог.st_size, Окончательно.st_nlink==Итог.st_nlink, Окончательно.st_mtimespec.tv_sec==Итог.st_mtimespec.tv_sec, Окончательно.st_mtimespec.tv_nsec==Итог.st_mtimespec.tv_nsec, Окончательно.st_ctimespec.tv_sec==Итог.st_ctimespec.tv_sec, Окончательно.st_ctimespec.tv_nsec==Итог.st_ctimespec.tv_nsec else { return .неизвестно }
    return .завершено
}
func записать_по_дескриптору(_ Дескриптор: Int32, метка Метка: метка_файла, исходные Исходные: Data, новые Новые: Data) -> исход_записи {
    тестово_записать(Дескриптор,метка:Метка,исходные:Исходные,новые:Новые)
}
