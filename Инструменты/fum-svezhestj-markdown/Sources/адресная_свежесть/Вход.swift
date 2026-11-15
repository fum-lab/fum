import Foundation

public struct вход_запуска { public let сейчас: String; public let файлы: [вход_файла] }
public func разобрать_вход(_ данные: Data) throws -> вход_запуска {
    guard данные.count < 8_388_608 else { throw ошибка.неподдержано }
    let строки=данные.split(separator:10,omittingEmptySubsequences:false)
    guard строки.count>=4, строки[0].elementsEqual(Data("fum.адресная-свежесть.1".utf8)), строки.last?.isEmpty == true else { throw ошибка.неподдержано }
    func текст(_ позиция:Int) throws -> String {
        guard позиция<строки.count, строки[позиция].allSatisfy({$0>=32 && $0<127}), let значение=String(data:Data(строки[позиция]),encoding:.ascii) else { throw ошибка.неподдержано }; return значение
    }
    func декодировать(_ позиция:Int) throws -> Data {
        let код=try текст(позиция); guard let результат=Data(base64Encoded:код), результат.base64EncodedString()==код else { throw ошибка.неподдержано }; return результат
    }
    let сейчас=try текст(1), строка_числа=try текст(2)
    guard let число=Int(строка_числа), число>0, число<=1000, String(число)==строка_числа, строки.count==4+число*4 else { throw ошибка.неподдержано }
    var файлы:[вход_файла]=[]
    for номер in 0..<число {
        let позиция=3+номер*4
        let путь=try декодировать(позиция), тело=try декодировать(позиция+1), хэш=try текст(позиция+2), время=try текст(позиция+3)
        guard хэш.utf8.count==64, хэш.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else { throw ошибка.неподдержано }
        файлы.append(вход_файла(путь:путь,исходные:тело,отпечаток:хэш,при_отсутствии:время))
    }
    return вход_запуска(сейчас:сейчас,файлы:файлы)
}
