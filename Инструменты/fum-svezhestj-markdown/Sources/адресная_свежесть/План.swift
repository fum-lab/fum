import Foundation

public struct вход_файла {
    public let путь: Data; public let исходные: Data; public let отпечаток: String; public let при_отсутствии: String
    public init(путь: Data, исходные: Data, отпечаток: String, при_отсутствии: String) { self.путь=путь; self.исходные=исходные; self.отпечаток=отпечаток; self.при_отсутствии=при_отсутствии }
}
public struct план_файла { public let путь: Data; public let исходные: Data; public let результат: Data }
public func составить_план(_ входы: [вход_файла], сейчас: String) throws -> [план_файла] {
    guard !входы.isEmpty, входы.count<=1000, Set(входы.map(\.путь)).count == входы.count else { throw ошибка.неподдержано }
    var планы: [план_файла]=[]
    var общий_размер=0
    for файл in входы {
        guard файл.исходные.count <= 8_388_608-общий_размер else { throw ошибка.неподдержано }; общий_размер += файл.исходные.count
        let путь=[UInt8](файл.путь); guard !путь.isEmpty, путь.count<=4096, путь.first != 47, путь.last != 47, !путь.contains(0), !путь.contains(92), !путь.contains(13), !путь.contains(10), let название=String(data:файл.путь,encoding:.utf8), Data(название.utf8)==файл.путь, путь.suffix(3).elementsEqual(Array(".md".utf8)) else { throw ошибка.неподдержано }
        let части=путь.split(separator:47,omittingEmptySubsequences:false)
        guard части.allSatisfy({ !$0.isEmpty && !$0.elementsEqual([46]) && !$0.elementsEqual([46,46]) && !$0.map({ (65...90).contains($0) ? $0+32 : $0 }).elementsEqual([46,103,105,116]) }), файл.путь != Data("Индексы/markdown-файлы-по-времени-редактирования.md".utf8) else { throw ошибка.неподдержано }
        let результат=try предпросмотр(файл.исходные,ожидаемый:файл.отпечаток,при_отсутствии:файл.при_отсутствии,сейчас:сейчас)
        планы.append(план_файла(путь:файл.путь,исходные:файл.исходные,результат:результат))
    }
    return планы
}
