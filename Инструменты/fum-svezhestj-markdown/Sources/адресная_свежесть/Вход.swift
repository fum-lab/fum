import Foundation

public struct вход_запуска { public let сейчас: String; public let файлы: [вход_файла] }
public func разобрать_вход(_ Данные: Data) throws -> вход_запуска {
    guard Данные.count < 8_388_608 else { throw ошибка.неподдержано }
    let Строки=Данные.split(separator:10,omittingEmptySubsequences:false)
    guard Строки.count>=4, Строки[0].elementsEqual(Data("fum.адресная-свежесть.1".utf8)), Строки.last?.isEmpty == true else { throw ошибка.неподдержано }
    func текст(_ Позиция:Int) throws -> String {
        guard Позиция<Строки.count, Строки[Позиция].allSatisfy({$0>=32 && $0<127}), let Значение=String(data:Data(Строки[Позиция]),encoding:.ascii) else { throw ошибка.неподдержано }; return Значение
    }
    func декодировать(_ Позиция:Int) throws -> Data {
        let Код=try текст(Позиция); guard let Результат=Data(base64Encoded:Код), Результат.base64EncodedString()==Код else { throw ошибка.неподдержано }; return Результат
    }
    let Сейчас=try текст(1), Строка_числа=try текст(2)
    guard let Число=Int(Строка_числа), Число>0, Число<=1000, String(Число)==Строка_числа, Строки.count==4+Число*4 else { throw ошибка.неподдержано }
    var Файлы:[вход_файла]=[]
    for Номер in 0..<Число {
        let Позиция=3+Номер*4
        let Путь=try декодировать(Позиция), Тело=try декодировать(Позиция+1), Хэш=try текст(Позиция+2), Время=try текст(Позиция+3)
        guard Хэш.utf8.count==64, Хэш.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else { throw ошибка.неподдержано }
        Файлы.append(вход_файла(путь:Путь,исходные:Тело,отпечаток:Хэш,при_отсутствии:Время))
    }
    return вход_запуска(сейчас:Сейчас,файлы:Файлы)
}
