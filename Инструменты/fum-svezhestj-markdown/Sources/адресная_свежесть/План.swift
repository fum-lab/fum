import Foundation

public struct вход_файла {
    public let путь: Data; public let исходные: Data; public let отпечаток: String; public let при_отсутствии: String
    public init(путь Путь: Data, исходные Исходные: Data, отпечаток Отпечаток: String, при_отсутствии При_отсутствии: String) { self.путь=Путь; self.исходные=Исходные; self.отпечаток=Отпечаток; self.при_отсутствии=При_отсутствии }
}
public struct план_файла { public let путь: Data; public let исходные: Data; public let результат: Data }
public func составить_план(_ Входы: [вход_файла], сейчас Сейчас: String) throws -> [план_файла] {
    guard !Входы.isEmpty, Входы.count<=1000, Set(Входы.map(\.путь)).count == Входы.count else { throw ошибка.неподдержано }
    var Планы: [план_файла]=[]
    var Общий_размер=0
    for Файл in Входы {
        guard Файл.исходные.count <= 8_388_608-Общий_размер else { throw ошибка.неподдержано }; Общий_размер += Файл.исходные.count
        let Путь=[UInt8](Файл.путь); guard !Путь.isEmpty, Путь.count<=4096, Путь.first != 47, Путь.last != 47, !Путь.contains(0), !Путь.contains(92), !Путь.contains(13), !Путь.contains(10), let Название=String(data:Файл.путь,encoding:.utf8), Data(Название.utf8)==Файл.путь, Путь.suffix(3).elementsEqual(Array(".md".utf8)) else { throw ошибка.неподдержано }
        let Части=Путь.split(separator:47,omittingEmptySubsequences:false)
        guard Части.allSatisfy({ !$0.isEmpty && !$0.elementsEqual([46]) && !$0.elementsEqual([46,46]) && !$0.map({ (65...90).contains($0) ? $0+32 : $0 }).elementsEqual([46,103,105,116]) }), Файл.путь != Data("Индексы/markdown-файлы-по-времени-редактирования.md".utf8) else { throw ошибка.неподдержано }
        let Результат=try предпросмотр(Файл.исходные,ожидаемый:Файл.отпечаток,при_отсутствии:Файл.при_отсутствии,сейчас:Сейчас)
        Планы.append(план_файла(путь:Файл.путь,исходные:Файл.исходные,результат:Результат))
    }
    return Планы
}
