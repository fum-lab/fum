import Foundation
import Darwin

// Каталог, его неподменяемость и единственный писатель подтверждаются вызывающим отдельно.
public final class владелец_дескрипторов {
    public init() {}
    public private(set) var дескрипторы: [Int32] = []
    func добавить(_ Дескриптор:Int32) { дескрипторы.append(Дескриптор) }
}
public struct привязанный_файл { let план: план_файла; let дескриптор: Int32; let метка: метка_файла }
public func закрыть_один(_ Дескриптор:Int32) -> Bool { Darwin.close(Дескриптор) == 0 }
public func сверить(_ Файл: привязанный_файл) -> Bool {
    if case .без_изменения = записать_по_дескриптору(Файл.дескриптор,метка:Файл.метка,исходные:Файл.план.исходные,новые:Файл.план.исходные) { return true }; return false
}
public func выполнить(_ Файл: привязанный_файл) -> исход_записи {
    записать_по_дескриптору(Файл.дескриптор,метка:Файл.метка,исходные:Файл.план.исходные,новые:Файл.план.результат)
}
public func привязать(_ Планы: [план_файла], корень Корень: Int32, владелец Владелец: владелец_дескрипторов) throws -> [привязанный_файл] {
    var Метка_корня=stat(); guard !Планы.isEmpty, Планы.count<=1000, fstat(Корень,&Метка_корня)==0, Метка_корня.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) else { throw ошибка.неподдержано }
    let Индексы=openat(Корень,"Индексы",O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC); guard Индексы>=0 else { throw ошибка.неподдержано }; Владелец.добавить(Индексы)
    var Запрещённый=stat(); guard fstatat(Индексы,"markdown-файлы-по-времени-редактирования.md",&Запрещённый,AT_SYMLINK_NOFOLLOW)==0, Запрещённый.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), Запрещённый.st_nlink==1 else { throw ошибка.неподдержано }
    var Результат:[привязанный_файл]=[], Метки:Set<String>=[]
    for План in Планы {
        let Части=[UInt8](План.путь).split(separator:47,omittingEmptySubsequences:false)
        guard !Части.isEmpty else { throw ошибка.неподдержано }
        var Текущий=Корень
        for Часть in Части.dropLast() {
            guard let Имя=String(bytes:Часть,encoding:.utf8) else { throw ошибка.неподдержано }
            let Дескриптор=openat(Текущий,Имя,O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC); guard Дескриптор>=0 else { throw ошибка.неподдержано }; Владелец.добавить(Дескриптор); Текущий=Дескриптор
        }
        guard let Имя=String(bytes:Части.last!,encoding:.utf8) else { throw ошибка.неподдержано }
        var До_открытия=stat(); guard fstatat(Текущий,Имя,&До_открытия,AT_SYMLINK_NOFOLLOW)==0, До_открытия.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), До_открытия.st_nlink==1, !(До_открытия.st_dev==Запрещённый.st_dev && До_открытия.st_ino==Запрещённый.st_ino) else { throw ошибка.неподдержано }
        let Режим = План.исходные == План.результат ? O_RDONLY : O_RDWR
        let Дескриптор=openat(Текущий,Имя,Режим | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC); guard Дескриптор>=0 else { throw ошибка.неподдержано }; Владелец.добавить(Дескриптор)
        var Метка=stat(); guard fstat(Дескриптор,&Метка)==0, Метка.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG), Метка.st_nlink==1, Метка.st_dev==До_открытия.st_dev, Метка.st_ino==До_открытия.st_ino else { throw ошибка.неподдержано }
        guard Метки.insert("\(Метка.st_dev):\(Метка.st_ino)").inserted else { throw ошибка.неподдержано }
        Результат.append(привязанный_файл(план:План,дескриптор:Дескриптор,метка:метка_файла(устройство:Метка.st_dev,индекс:Метка.st_ino)))
    }
    return Результат
}
