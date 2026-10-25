import Foundation
import Testing
@testable import КонтейнерНаблюдений

struct КаталогПроцессовTests {
    @Test func новыйЧитательПеречисляетТочныеГруппыБезЗаписи() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        let описание = ОписаниеНаблюдения(идентификатор: "начало-цикла", тип: "fum-каталог-цикла",
            источник: "фикстура", время: "2026-10-09T00:00:00Z", спецификация: Data([0, 255]))
        let квитанция = try писатель.добавить(описание, данные: Data("начало".utf8))
        писатель.закрыть()
        let файл = путь.appendingPathComponent("сегмент.fumobs"), до = try Data(contentsOf: файл)
        let ответ = try ПроцессыTests().выполнить("читатель-контейнера", ["перечень", путь.path])
        try #require(ответ.0 == 0)
        let перечень = try #require(JSONSerialization.jsonObject(with: ответ.1) as? [String: Any])
        #expect(перечень["схема"] as? String == "fum.перечень-контейнера.1")
        #expect(перечень["неполный_хвост"] as? Bool == false)
        let записи = try #require(перечень["записи"] as? [[String: Any]])
        let восстановленные = try JSONDecoder().decode([Квитанция].self, from: JSONSerialization.data(withJSONObject: записи))
        #expect(восстановленные == [квитанция])
        #expect(try Data(contentsOf: файл) == до)
        #expect(try ПроцессыTests().выполнить("читатель-контейнера", ["извлечь", путь.path, описание.идентификатор]).1 == Data("начало".utf8))
    }

    @Test func неполныйХвостЯвенАПовреждениеНеПустота() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "один", тип: "фикстура",
            источник: "тест", время: "2026-10-09T00:00:00Z"), данные: Data([1, 2, 3]))
        писатель.закрыть()
        let файл = путь.appendingPathComponent("сегмент.fumobs"), до = try Data(contentsOf: файл)
        let поток = try FileHandle(forWritingTo: файл)
        try поток.seekToEnd(); try поток.write(contentsOf: Data([0x46])); try поток.close()
        let сХвостом = try Data(contentsOf: файл)
        let ответ = try ПроцессыTests().выполнить("читатель-контейнера", ["перечень", путь.path])
        try #require(ответ.0 == 0)
        let перечень = try #require(JSONSerialization.jsonObject(with: ответ.1) as? [String: Any])
        #expect(перечень["неполный_хвост"] as? Bool == true)
        #expect((перечень["записи"] as? [Any])?.count == 1)
        #expect(try Data(contentsOf: файл) == сХвостом)
        var повреждённые = до; повреждённые[0] ^= 0xff
        try повреждённые.write(to: файл)
        let отказ = try ПроцессыTests().выполнить("читатель-контейнера", ["перечень", путь.path])
        #expect(отказ.0 != 0); #expect(отказ.1.isEmpty)
        #expect(try Data(contentsOf: файл) == повреждённые)
    }

    @Test func отсутствующийСегментНеСоздаётсяКакПустойУспех() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let ответ = try ПроцессыTests().выполнить("читатель-контейнера", ["перечень", путь.path])
        #expect(ответ.0 != 0); #expect(ответ.1.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: путь.appendingPathComponent("сегмент.fumobs").path))
    }
}
