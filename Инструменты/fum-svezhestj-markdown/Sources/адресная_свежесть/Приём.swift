import Foundation
import Darwin

// Каталог, его неподменяемость и единственный писатель подтверждаются вызывающим отдельно.
public final class владелец_дескрипторов {
    public init() {}
    public private(set) var дескрипторы: [Int32] = []
    func добавить(_ дескриптор:Int32) { дескрипторы.append(дескриптор) }
}
public struct привязанный_файл { let план: план_файла; let дескриптор: Int32; let метка: метка_файла }
public func закрыть_один(_ дескриптор:Int32) -> Bool { Darwin.close(дескриптор) == 0 }
public func сверить(_ файл: привязанный_файл) -> Bool {
    if case .без_изменения = записать_по_дескриптору(файл.дескриптор,метка:файл.метка,исходные:файл.план.исходные,новые:файл.план.исходные) { return true }; return false
}
public func выполнить(_ файл: привязанный_файл) -> исход_записи {
    записать_по_дескриптору(файл.дескриптор,метка:файл.метка,исходные:файл.план.исходные,новые:файл.план.результат)
}
public func привязать(_ планы: [план_файла], корень: Int32, владелец: владелец_дескрипторов) throws -> [привязанный_файл] {
    var метка_корня=stat(); guard !планы.isEmpty, планы.count<=1000, fstat(корень,&метка_корня)==0, метка_корня.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) else { throw ошибка.неподдержано }
    let индексы=openat(корень,"Индексы",O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC); guard индексы>=0 else { throw ошибка.неподдержано }; владелец.добавить(индексы)
    var запрещённый=stat(); guard fstatat(индексы,"markdown-файлы-по-времени-редактирования.md",&запрещённый,AT_SYMLINK_NOFOLLOW)==0, запрещённый.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), запрещённый.st_nlink==1 else { throw ошибка.неподдержано }
    var результат:[привязанный_файл]=[], метки:Set<String>=[]
    for план in планы {
        let части=[UInt8](план.путь).split(separator:47,omittingEmptySubsequences:false)
        guard !части.isEmpty else { throw ошибка.неподдержано }
        var текущий=корень
        for часть in части.dropLast() {
            guard let имя=String(bytes:часть,encoding:.utf8) else { throw ошибка.неподдержано }
            let дескриптор=openat(текущий,имя,O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC); guard дескриптор>=0 else { throw ошибка.неподдержано }; владелец.добавить(дескриптор); текущий=дескриптор
        }
        guard let имя=String(bytes:части.last!,encoding:.utf8) else { throw ошибка.неподдержано }
        var до_открытия=stat(); guard fstatat(текущий,имя,&до_открытия,AT_SYMLINK_NOFOLLOW)==0, до_открытия.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), до_открытия.st_nlink==1, !(до_открытия.st_dev==запрещённый.st_dev && до_открытия.st_ino==запрещённый.st_ino) else { throw ошибка.неподдержано }
        let режим = план.исходные == план.результат ? O_RDONLY : O_RDWR
        let дескриптор=openat(текущий,имя,режим | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC); guard дескриптор>=0 else { throw ошибка.неподдержано }; владелец.добавить(дескриптор)
        var метка=stat(); guard fstat(дескриптор,&метка)==0, метка.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), метка.st_nlink==1, метка.st_dev==до_открытия.st_dev, метка.st_ino==до_открытия.st_ino else { throw ошибка.неподдержано }
        guard метки.insert("\(метка.st_dev):\(метка.st_ino)").inserted else { throw ошибка.неподдержано }
        результат.append(привязанный_файл(план:план,дескриптор:дескриптор,метка:метка_файла(устройство:метка.st_dev,индекс:метка.st_ino)))
    }
    return результат
}
