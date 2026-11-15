import Foundation
import CryptoKit

public enum ошибка: Error { case неподдержано, неверный_отпечаток, время }
private func отпечаток(_ данные: Data) -> String { SHA256.hash(data:данные).map { String(format:"%02x",$0) }.joined() }
private func допустимое_время(_ строка:String) -> Bool {
    let формат=DateFormatter(); формат.locale=Locale(identifier:"en_US_POSIX"); формат.timeZone=TimeZone(secondsFromGMT:10800); формат.dateFormat="yyyy-MM-dd HH:mm:ss 'MSK'"; формат.isLenient=false
    guard let значение=формат.date(from:строка) else { return false }; return формат.string(from:значение)==строка
}
public func предпросмотр(_ исходные: Data, ожидаемый: String, при_отсутствии: String, сейчас: String) throws -> Data {
    guard отпечаток(исходные)==ожидаемый else { throw ошибка.неверный_отпечаток }
    guard допустимое_время(при_отсутствии), допустимое_время(сейчас) else { throw ошибка.время }
    guard исходные.count <= 4_194_304, let текст=String(data:исходные,encoding:.utf8), !исходные.contains(0), !исходные.contains(13), ["```", "~~~", "FUM-CHECK-RUNS", "FUM-ARCHIVE"].allSatisfy({ исходные.range(of:Data($0.utf8)) == nil }) else { throw ошибка.неподдержано }
    let шаблон = #"\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: ([^>]+) -->\n<!-- content-sha256: sha256:([0-9a-f]{64}) -->\n<!-- FUM-MD-RECENCY:END -->\n?\z"#
    let выражение=try NSRegularExpression(pattern:шаблон); let диапазон=NSRange(текст.startIndex...,in:текст)
    let совпадение=выражение.firstMatch(in:текст,range:диапазон)
    var содержание=текст; var время=при_отсутствии
    if let совпадение {
        guard let целиком=Range(совпадение.range,in:текст), let метка=Range(совпадение.range(at:1),in:текст), let хэш=Range(совпадение.range(at:2),in:текст) else { throw ошибка.неподдержано }
        let прежнее=String(текст[метка]); guard допустимое_время(прежнее) else { throw ошибка.время }
        содержание=String(текст[..<целиком.lowerBound]); if !содержание.hasSuffix("\n") { содержание += "\n" }
        время=отпечаток(Data(содержание.utf8)) == String(текст[хэш]) ? прежнее : сейчас
    } else if исходные.range(of:Data("FUM-MD-RECENCY".utf8)) != nil { throw ошибка.неподдержано }
    guard Data(содержание.utf8).range(of:Data("<!--".utf8)) == nil else { throw ошибка.неподдержано }
    if !содержание.hasSuffix("\n") { содержание += "\n" }
    let хэш=отпечаток(Data(содержание.utf8))
    return Data((содержание + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: " + время + " -->\n<!-- content-sha256: sha256:" + хэш + " -->\n<!-- FUM-MD-RECENCY:END -->\n").utf8)
}
