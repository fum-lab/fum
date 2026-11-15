import Foundation
import CryptoKit

public enum ошибка: Error { case неподдержано, неверный_отпечаток, время }
private func отпечаток(_ Данные: Data) -> String { SHA256.hash(data:Данные).map { String(format:"%02x",$0) }.joined() }
private func допустимое_время(_ Строка:String) -> Bool {
    let Формат=DateFormatter(); Формат.locale=Locale(identifier:"en_US_POSIX"); Формат.timeZone=TimeZone(secondsFromGMT:10800); Формат.dateFormat="yyyy-MM-dd HH:mm:ss 'MSK'"; Формат.isLenient=false
    guard let Значение=Формат.date(from:Строка) else { return false }; return Формат.string(from:Значение)==Строка
}
public func предпросмотр(_ Исходные: Data, ожидаемый Ожидаемый: String, при_отсутствии При_отсутствии: String, сейчас Сейчас: String) throws -> Data {
    guard отпечаток(Исходные)==Ожидаемый else { throw ошибка.неверный_отпечаток }
    guard допустимое_время(При_отсутствии), допустимое_время(Сейчас) else { throw ошибка.время }
    guard Исходные.count <= 4_194_304, let Текст=String(data:Исходные,encoding:.utf8), !Исходные.contains(0), !Исходные.contains(13), ["```", "~~~", "FUM-CHECK-RUNS", "FUM-ARCHIVE"].allSatisfy({ Исходные.range(of:Data($0.utf8)) == nil }) else { throw ошибка.неподдержано }
    let Шаблон = #"\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: ([^>]+) -->\n<!-- content-sha256: sha256:([0-9a-f]{64}) -->\n<!-- FUM-MD-RECENCY:END -->\n?\z"#
    let Выражение=try NSRegularExpression(pattern:Шаблон); let Диапазон=NSRange(Текст.startIndex...,in:Текст)
    let Совпадение=Выражение.firstMatch(in:Текст,range:Диапазон)
    var Содержание=Текст; var Время=При_отсутствии
    if let Совпадение {
        guard let Целиком=Range(Совпадение.range,in:Текст), let Метка=Range(Совпадение.range(at:1),in:Текст), let Хэш=Range(Совпадение.range(at:2),in:Текст) else { throw ошибка.неподдержано }
        let Прежнее=String(Текст[Метка]); guard допустимое_время(Прежнее) else { throw ошибка.время }
        Содержание=String(Текст[..<Целиком.lowerBound]); if !Содержание.hasSuffix("\n") { Содержание += "\n" }
        Время=отпечаток(Data(Содержание.utf8)) == String(Текст[Хэш]) ? Прежнее : Сейчас
    } else if Исходные.range(of:Data("FUM-MD-RECENCY".utf8)) != nil { throw ошибка.неподдержано }
    guard Data(Содержание.utf8).range(of:Data("<!--".utf8)) == nil else { throw ошибка.неподдержано }
    if !Содержание.hasSuffix("\n") { Содержание += "\n" }
    let Хэш=отпечаток(Data(Содержание.utf8))
    return Data((Содержание + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: " + Время + " -->\n<!-- content-sha256: sha256:" + Хэш + " -->\n<!-- FUM-MD-RECENCY:END -->\n").utf8)
}
