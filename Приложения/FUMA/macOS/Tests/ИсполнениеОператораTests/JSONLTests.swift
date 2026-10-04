import Foundation
import XCTest
import Darwin
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

final class ПроверкиИсполненияСреза: XCTestCase {
    func test_КомандаСрезаВыбираетСуществующийИсполнитель() {
        XCTAssertTrue(КомандноеИсполнениеОператора.выбран(аргументы: ["--исполнить-JSONL"]))
        XCTAssertTrue(КомандноеИсполнениеОператора.выбран(аргументы: ["--повторить-JSONL", "сохранённая-запись"]))
    }

    func test_СрезСохраняетРамкиБайтыИОбщееИсполнение() throws {
        try сКаталогом { каталог in
            let исходные = Data("\"ПРИВЕТ\"\n\"ЁЖ\"\nхвост".utf8)
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from:
                ИсполнениеСреза.исполнить(вход: исходные, определение: определение(шагов: 2), каталог: каталог))
            XCTAssertEqual(ответ.схема, "fuma.результат-JSONL.1")
            XCTAssertEqual(ответ.запись.схема, "fuma.исполнение-JSONL.1")
            XCTAssertEqual(ответ.запись.рамки.map { $0.позиция.номер }, [1, 2])
            XCTAssertEqual(ответ.запись.учтеноОпераций, 4)
            XCTAssertEqual(ответ.запись.рамки.map(\.выполненоОпераций), [2, 2])
            XCTAssertEqual(ответ.запись.записейТрассы, 4)
            XCTAssertEqual(ответ.запись.сыройВход.размер, UInt64(исходные.count))
            XCTAssertEqual(ответ.запись.сыройВход.хэш, хэшБайтовСреза(исходные))
            XCTAssertEqual(ответ.запись.неИсполненныйСуффикс.начало, ответ.запись.границаСтрок.байты)
            XCTAssertEqual(ответ.запись.сыройХвост.хэшДиапазона, хэшБайтовСреза(Data("хвост".utf8)))
            XCTAssertNil(ответ.запись.отказ)
            XCTAssertTrue(ответ.запись.трассаПолна)
            XCTAssertEqual(try значениеНаблюдения(ответ.запись.рамки[0].наблюдение), "\"привет\"\n")
            XCTAssertEqual(try значениеНаблюдения(ответ.запись.рамки[1].наблюдение), "\"ёж\"\n")
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            XCTAssertEqual(try сегмент.извлечь(ответ.запись.сыройВход.описание.идентификатор), исходные)
            XCTAssertLessThanOrEqual(try сегмент.извлечь(ответ.квитанция.описание.идентификатор).count, 1_048_576)
        }
    }

    func test_СыройВходПрофильИОпределениеСохраняютсяДоРазбора() throws {
        try сКаталогом { каталог in
            let вход = Data([0xff, 0x0a, 0xf0, 0x9f])
            let неверное = Data("не определение".utf8)
            XCTAssertThrowsError(try ИсполнениеСреза.исполнить(вход: вход, определение: неверное, каталог: каталог))
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            XCTAssertEqual(сегмент.записи.count, 3)
            XCTAssertEqual(сегмент.записи.prefix(2).map(\.описание.тип),
                ["сырые-байты/вход-оператора", "сырые-байты/определение-оператора"])
            XCTAssertEqual(try сегмент.извлечь(сегмент.записи[0].описание.идентификатор), вход)
            XCTAssertEqual(try сегмент.извлечь(сегмент.записи[1].описание.идентификатор), неверное)
            XCTAssertEqual(сегмент.записи[2].описание.тип, "профиль-JSONL")
        }
    }

    func test_НевернаяРамкаОстанавливаетПотокИСохраняетПолныйСуффикс() throws {
        let неверные = [Data([0xff, 0x0a]), Data("\n".utf8), Data("{\"а\":1,\"\\u0430\":2}\n".utf8),
            Data("1.0\n".utf8), Data("1e0\n".utf8), Data("9223372036854775808\n".utf8),
            Data((String(repeating: "[", count: 17) + "0" + String(repeating: "]", count: 17) + "\n").utf8),
            Data(("[" + Array(repeating: "0", count: 8192).joined(separator: ",") + "]\n").utf8)]
        for неверная in неверные {
            try сКаталогом { каталог in
                let первая = Data("\"ABC\"\n".utf8)
                let последняя = Data("\"НЕ ИСПОЛНЯТЬ\"\nхвост".utf8)
                let вход = первая + неверная + последняя
                let ответ = try JSONDecoder().decode(ОтветСреза.self, from:
                    ИсполнениеСреза.исполнить(вход: вход, определение: определение(шагов: 2), каталог: каталог))
                XCTAssertEqual(ответ.запись.рамки.count, 1)
                XCTAssertEqual(ответ.запись.границаСтрок.строки, 3)
                XCTAssertEqual(ответ.запись.исполненныйПрефикс.байты, первая.count)
                XCTAssertEqual(ответ.запись.исполненныйПрефикс.строки, 1)
                XCTAssertEqual(ответ.запись.отказ?.позиция.номер, 2)
                XCTAssertEqual(ответ.запись.отказ?.стадия, "декодирование")
                XCTAssertEqual(ответ.запись.отказ?.учтеноОпераций, 0)
                XCTAssertEqual(ответ.запись.неИсполненныйСуффикс.начало, первая.count)
                XCTAssertEqual(ответ.запись.неИсполненныйСуффикс.хэшДиапазона, хэшБайтовСреза(неверная + последняя))
            }
        }
    }

    func test_ОбщийБюджетОперацийНеОбнуляетсяМеждуРамками() throws {
        for остаток in [2, 3] {
            try сКаталогом { каталог in
                var профиль = ПрофильСреза.текущий
                профиль.операции = остаток
                let вход = Data("\"ABC\"\n\"DEF\"\n\"НЕ ИСПОЛНЯТЬ\"\n".utf8)
                let ответ = try JSONDecoder().decode(ОтветСреза.self, from:
                    ИсполнениеСреза.исполнить(вход: вход, определение: определение(шагов: 2), каталог: каталог, пределы: профиль))
                XCTAssertEqual(ответ.запись.рамки.count, 1)
                XCTAssertEqual(ответ.запись.учтеноОпераций, остаток)
                XCTAssertEqual(ответ.запись.отказ?.позиция.номер, 2)
                XCTAssertEqual(ответ.запись.отказ?.выделеноОпераций, остаток - 2)
                XCTAssertEqual(ответ.запись.отказ?.выполненоОпераций, остаток == 2 ? 0 : nil)
                XCTAssertEqual(ответ.запись.отказ?.учтеноОпераций, остаток - 2)
                XCTAssertEqual(ответ.запись.отказ?.стадия, остаток == 2 ? "бюджет" : "исполнение")
            }
        }
    }

    func test_ОбщаяТрассаВключаетШаги() throws {
        try сКаталогом { каталог in
            let вход = Data(Array(repeating: "\"ABC\"\n", count: 9).joined().utf8)
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from:
                ИсполнениеСреза.исполнить(вход: вход, определение: определение(шагов: 32), каталог: каталог))
            XCTAssertEqual(ответ.запись.рамки.count, 8)
            XCTAssertEqual(ответ.запись.записейТрассы, 256)
            XCTAssertEqual(ответ.запись.учтеноОпераций, 256)
            XCTAssertEqual(ответ.запись.отказ?.позиция.номер, 9)
            XCTAssertEqual(ответ.запись.отказ?.стадия, "бюджет")
            XCTAssertEqual(ответ.запись.отказ?.учтеноОпераций, 0)
        }
    }

    func test_ПределОхватываетВесьКодированныйОтвет() throws {
        let вход = Data(("\"" + String(repeating: "A", count: 1000) + "\"\n").utf8)
        var размерСреза = 0
        try сКаталогом { каталог in
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                вход: вход, определение: определение(шагов: 1), каталог: каталог))
            XCTAssertNil(ответ.запись.отказ)
            размерСреза = try кодироватьСтрокуСреза(ответ.запись).count
        }
        for суффикс in [Data(), Data("\nхвост".utf8)] {
            try сКаталогом { каталог in
                var профиль = ПрофильСреза.текущий
                профиль.результат = размерСреза + 100
                let ответ = try ИсполнениеСреза.исполнить(вход: вход + суффикс,
                    определение: определение(шагов: 1), каталог: каталог, пределы: профиль)
                XCTAssertLessThanOrEqual(ответ.count, профиль.результат)
                XCTAssertNotNil(try JSONDecoder().decode(ОтветСреза.self, from: ответ).запись.отказ)
            }
        }
    }

    func test_НативнаяПрограммаВыбираетСообщенияЛенивоИСохраняетЧасти() throws {
        let программа = try нативнаяПрограмма()
        let строки = [
            #"{"type":"event_msg"}"#,
            #"{"type":"response_item","payload":{"type":"reasoning"}}"#,
            #"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"повтор\nЁ"}]}}"#,
            #"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"цитата: повтор\nЁ"},{"type":"output_image"},{"type":"input_text","text":"вторая часть"}]}}"#,
            #"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"повтор\nЁ"}]}}"#]
        try сКаталогом { каталог in
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                вход: Data((строки.joined(separator: "\n") + "\nхвост").utf8), определение: программа, каталог: каталог))
            XCTAssertNil(ответ.запись.отказ)
            XCTAssertEqual(ответ.запись.рамки.count, 5)
            let значения = try ответ.запись.рамки.map { try значениеНаблюдения($0.наблюдение) }
            XCTAssertEqual(значения[0], "[]")
            XCTAssertEqual(значения[1], "[]")
            let пользователь = #"[{"роль":"user","части":["повтор\nЁ"]}]"#
            XCTAssertEqual(значения[2], пользователь)
            XCTAssertEqual(значения[3], #"[{"роль":"assistant","части":["цитата: повтор\nЁ",null,"вторая часть"]}]"#)
            XCTAssertEqual(значения[4], пользователь)
            XCTAssertEqual(ответ.запись.рамки[2].позиция.номер, 3)
            XCTAssertEqual(ответ.запись.сыройХвост.хэшДиапазона, хэшБайтовСреза(Data("хвост".utf8)))
        }
    }

    func test_ПовторСрезаБольшеСтарогоЛимита() throws {
        try сКаталогом { каталог in
            let строка = "\"" + String(repeating: "A", count: 100_000) + "\"\n"
            let вход = Data((String(repeating: строка, count: 3) + "хвост").utf8)
            XCTAssertGreaterThan(вход.count, 262_144)
            let первый = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                вход: вход, определение: определение(шагов: 1), каталог: каталог))
            let повтор = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.повторить(
                первый.квитанция.описание.идентификатор, каталог: каталог))
            XCTAssertEqual(повтор.запись, первый.запись)
            XCTAssertNotEqual(повтор.квитанция.описание.идентификатор, первый.квитанция.описание.идентификатор)
        }
    }

    func test_ОтказВторогоСырогоОбъектаПредшествуетРазбору() throws {
        try сКаталогом { каталог in
            var стадии: [String] = []
            let маркер = Data("\"тип\":\"сырые-байты/определение-оператора\"".utf8)
            let операции = ФайловыеОперации(запись: { дескриптор, буфер in
                if Data(буфер).range(of: маркер) != nil { throw ОшибкаКонтейнера.система(ENOSPC) }
                return try ФайловыеОперации.системные.запись(дескриптор, буфер)
            }, синхронизация: ФайловыеОперации.системные.синхронизация)
            let вход = Data([0xff, 10])
            XCTAssertThrowsError(try ИсполнениеСреза.исполнить(вход: вход, определение: Data([0xff]),
                каталог: каталог, операции: операции, профиль: { стадии.append($0.стадия) })) {
                XCTAssertEqual($0 as? ОшибкаКонтейнера, .система(ENOSPC))
            }
            XCTAssertFalse(стадии.contains("декодирование-определения"))
            XCTAssertFalse(стадии.contains("исполнение"))
            let сегмент = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { сегмент.закрыть() }
            XCTAssertEqual(сегмент.записи.count, 1)
            XCTAssertTrue(сегмент.естьХвост)
            XCTAssertEqual(try сегмент.извлечь(сегмент.записи[0].описание.идентификатор), вход)
        }
    }

    func test_ДопустимыеГраницыФорматаНеСужены() throws {
        let строки = ["-9223372036854775808\n", "9223372036854775807\n", "-0\n", "true\n", "null\n",
            "\"\\ud83d\\ude00\"\r\n",
            String(repeating: "[", count: 16) + "0" + String(repeating: "]", count: 16) + "\n",
            "[" + Array(repeating: "0", count: 8191).joined(separator: ",") + "]\n"]
        for строка in строки {
            try сКаталогом { каталог in
                let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                    вход: Data(строка.utf8), определение: определение(шагов: 0), каталог: каталог))
                XCTAssertNil(ответ.запись.отказ)
                XCTAssertEqual(ответ.запись.рамки.count, 1)
                XCTAssertEqual(ответ.запись.учтеноОпераций, 0)
                XCTAssertEqual(try значениеНаблюдения(ответ.запись.рамки[0].наблюдение), строка)
            }
        }
    }

    func test_НевернаяВыбраннаяФормаОтказываетВИнтерпретаторе() throws {
        let программа = try нативнаяПрограмма()
        let сообщения = [#"{"type":"message"}"#,
            #"{"type":"message","role":1,"content":[]}"#,
            #"{"type":"message","role":"user","content":null}"#,
            #"{"type":"message","role":"user","content":[{"type":"input_text","text":1}]}"#,
            #"{"type":"message","role":"user","content":[null]}"#,
            #"{"type":"message","role":"user","content":[{}]}"#]
        for сообщение in сообщения {
            try сКаталогом { каталог in
                let первая = Data("{\"type\":\"event_msg\"}\n".utf8)
                let отказ = Data(("{\"type\":\"response_item\",\"payload\":" + сообщение + "}\n").utf8)
                let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                    вход: первая + отказ + первая, определение: программа, каталог: каталог))
                XCTAssertEqual(ответ.запись.рамки.count, 1)
                XCTAssertEqual(ответ.запись.отказ?.стадия, "исполнение")
                XCTAssertNil(ответ.запись.отказ?.выполненоОпераций)
                XCTAssertEqual(ответ.запись.учтеноОпераций, 16_777_216)
                XCTAssertFalse(ответ.запись.трассаПолна)
                XCTAssertEqual(ответ.запись.неИсполненныйСуффикс.хэшДиапазона, хэшБайтовСреза(отказ + первая))
            }
        }
    }

    func test_ОбщаяТрассаПримененийИЧестноеУсечение() throws {
        let программа = try нативнаяПрограмма()
        let строка = #"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"Ё"},{"type":"output_image","text":17}]}}"# + "\n"
        try сКаталогом { каталог in
            var профиль = ПрофильСреза.текущий
            профиль.трасса = 2
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                вход: Data(строка.utf8), определение: программа, каталог: каталог, пределы: профиль))
            XCTAssertNil(ответ.запись.отказ)
            XCTAssertEqual(ответ.запись.записейТрассы, 2)
            XCTAssertFalse(ответ.запись.трассаПолна)
            XCTAssertEqual(try значениеНаблюдения(ответ.запись.рамки[0].наблюдение), #"[{"роль":"user","части":["Ё",null]}]"#)
        }
        try сКаталогом { каталог in
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                вход: Data(String(repeating: строка, count: 65).utf8), определение: программа, каталог: каталог))
            XCTAssertEqual(ответ.запись.рамки.count, 64)
            XCTAssertEqual(ответ.запись.записейТрассы, 256)
            XCTAssertEqual(ответ.запись.отказ?.позиция.номер, 65)
            XCTAssertEqual(ответ.запись.отказ?.стадия, "бюджет")
            XCTAssertEqual(ответ.запись.отказ?.учтеноОпераций, 0)
        }
    }

    func test_ЗаменаПрограммыМеняетПроекциюНаТомЖеИсполнителе() throws {
        let исходное = try нативнаяПрограмма()
        var изменённое = try XCTUnwrap(JSONSerialization.jsonObject(with: исходное) as? [String: Any])
        изменённое["версия"] = 2
        var шаги = try XCTUnwrap(изменённое["шаги"] as? [[String: Any]])
        шаги[0]["аргументы"] = ["граф": ["схема": "fuma.граф-JSON.2", "числа": "целые64-без-дробей",
            "переменные": [], "результат": ["массив"]]]
        изменённое["шаги"] = шаги
        let второе = try JSONSerialization.data(withJSONObject: изменённое, options: [.sortedKeys])
        let вход = Data((#"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"Ё"}]}}"# + "\n").utf8)
        try сКаталогом { каталог in
            let первый = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(вход: вход, определение: исходное, каталог: каталог))
            let второй = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(вход: вход, определение: второе, каталог: каталог))
            XCTAssertEqual(try значениеНаблюдения(первый.запись.рамки[0].наблюдение), #"[{"роль":"user","части":["Ё"]}]"#)
            XCTAssertEqual(try значениеНаблюдения(второй.запись.рамки[0].наблюдение), "[]")
            XCTAssertNotEqual(первый.запись.замыкание.хэш, второй.запись.замыкание.хэш)
            for ответ in [первый, второй] {
                let повтор = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.повторить(ответ.квитанция.описание.идентификатор, каталог: каталог))
                XCTAssertEqual(повтор.запись, ответ.запись)
            }
        }
    }

    func test_ПодменаСсылкиПрофиляИУчётаЗакрытоОтказывает() throws {
        for случай in ["ссылка", "профиль", "учёт", "позиция", "хэш"] {
            try сКаталогом { каталог in
                let ответ = try JSONDecoder().decode(ОтветСреза.self, from: ИсполнениеСреза.исполнить(
                    вход: Data("\"ABC\"\n".utf8), определение: определение(шагов: 1), каталог: каталог))
                var объект = try XCTUnwrap(JSONSerialization.jsonObject(with: кодироватьСтрокуСреза(ответ.запись)) as? [String: Any])
                switch случай {
                case "ссылка":
                    var ссылка = объект["сыройВход"] as! [String: Any]
                    ссылка["хэш"] = String(repeating: "0", count: 64)
                    объект["сыройВход"] = ссылка
                case "профиль":
                    var профиль = объект["профиль"] as! [String: Any]
                    профиль["схема"] = "неизвестная"
                    объект["профиль"] = профиль
                case "учёт": объект["учтеноОпераций"] = 0
                default:
                    var рамки = объект["рамки"] as! [[String: Any]]
                    if случай == "хэш" { рамки[0]["sha256Наблюдения"] = String(repeating: "0", count: 64) }
                    else {
                        var позиция = рамки[0]["позиция"] as! [String: Any]
                        позиция["начало"] = 1
                        рамки[0]["позиция"] = позиция
                    }
                    объект["рамки"] = рамки
                }
                let изменённая = try JSONDecoder().decode(ЗаписьСреза.self, from: JSONSerialization.data(withJSONObject: объект))
                let сегмент = try Сегмент(кореньДанных: каталог, запись: true, создать: false)
                let идентификатор = UUID().uuidString.lowercased()
                _ = try сегмент.добавить(ОписаниеНаблюдения(идентификатор: идентификатор,
                    тип: "исполнение-JSONL", источник: "FUMA"), данные: кодироватьСтрокуСреза(изменённая))
                сегмент.закрыть()
                XCTAssertThrowsError(try ИсполнениеСреза.повторить(идентификатор, каталог: каталог))
                let чтение = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
                defer { чтение.закрыть() }
                XCTAssertEqual(чтение.записи.count, 6)
            }
        }
    }

    func test_ОтказПоследнейСинхронизацииНеВыдаётОтвет() throws {
        final class Состояние: @unchecked Sendable {
            var готово = false
        }
        try сКаталогом { каталог in
            let состояние = Состояние()
            let маркер = Data("\"тип\":\"исполнение-JSONL\"".utf8)
            let операции = ФайловыеОперации(запись: { дескриптор, буфер in
                if Data(буфер).range(of: маркер) != nil { состояние.готово = true }
                return try ФайловыеОперации.системные.запись(дескриптор, буфер)
            }, синхронизация: { дескриптор in
                if состояние.готово { throw ОшибкаКонтейнера.система(EIO) }
                try ФайловыеОперации.системные.синхронизация(дескриптор)
            })
            XCTAssertThrowsError(try ИсполнениеСреза.исполнить(вход: Data("\"ABC\"\n".utf8),
                определение: определение(шагов: 1), каталог: каталог, операции: операции)) {
                XCTAssertEqual($0 as? ОшибкаКонтейнера, .система(EIO))
            }
            XCTAssertTrue(состояние.готово)
            let чтение = try Сегмент(кореньДанных: каталог, запись: false, создать: false)
            defer { чтение.закрыть() }
            XCTAssertEqual(чтение.записи.prefix(4).map(\.описание.тип), ["сырые-байты/вход-оператора",
                "сырые-байты/определение-оператора", "профиль-JSONL", "замыкание-JSONL"])
        }
    }

    private func нативнаяПрограмма() throws -> Data {
        try прочитатьПроверочныйВход(ключ: "ФУМА_ПРОГРАММА_ЖУРНАЛА",
            хэш: "6bb83002feb375d36b96c25d6b7a34820e3482188ddb2c6ac11c4deb21fa61f7")
    }

    private func прочитатьПроверочныйВход(ключ: String, хэш: String) throws -> Data {
        let ошибка = NSError(domain: "FUMA.ПроверочныйВход", code: 1)
        let предел: Int
        switch ключ {
        case "ФУМА_ПРОГРАММА_ЖУРНАЛА": предел = 65_536
        case "ФУМА_СЫРАЯ_ФИКСТУРА_ЖУРНАЛА": предел = 1_048_576
        default: throw ошибка
        }
        guard let путь = ProcessInfo.processInfo.environment[ключ],
              !путь.isEmpty, путь.hasPrefix("/"), !путь.contains("\0") else { throw ошибка }
        let файл = URL(fileURLWithPath: путь)
        guard файл.path == путь, файл.standardizedFileURL.path == путь,
              файл.resolvingSymlinksInPath().path == путь else { throw ошибка }
        var предок = URL(fileURLWithPath: "/", isDirectory: true)
        for часть in файл.pathComponents.dropFirst() {
            предок.appendPathComponent(часть)
            let сведения = try FileManager.default.attributesOfItem(atPath: предок.path)
            guard сведения[.type] as? FileAttributeType != .typeSymbolicLink else { throw ошибка }
        }
        let сведения = try FileManager.default.attributesOfItem(atPath: путь)
        guard сведения[.type] as? FileAttributeType == .typeRegular,
              let размер = сведения[.size] as? NSNumber,
              размер.intValue > 0, размер.intValue <= предел else { throw ошибка }
        let дескриптор = try FileHandle(forReadingFrom: файл)
        defer { дескриптор.closeFile() }
        guard let данные = try дескриптор.read(upToCount: предел + 1),
              !данные.isEmpty, данные.count <= предел,
              хэшБайтовСреза(данные) == хэш else { throw ошибка }
        return данные
    }

    func test_СыраяФикстураСохраняетОригинальныеГраницыИПовторы() throws {
        let исходные = try прочитатьПроверочныйВход(ключ: "ФУМА_СЫРАЯ_ФИКСТУРА_ЖУРНАЛА",
            хэш: "5fd0dc50d932b62c15ccea0bb4e56974834bfc80e65a54d1fb63a65e320cc646")
        let программа = try нативнаяПрограмма()
        XCTAssertEqual(исходные.count, 782)
        XCTAssertEqual(Data(исходные.suffix(2)), Data([0xf0, 0x9f]))
        try сКаталогом { каталог in
            let ответ = try JSONDecoder().decode(ОтветСреза.self, from:
                ИсполнениеСреза.исполнить(вход: исходные, определение: программа, каталог: каталог))
            XCTAssertNil(ответ.запись.отказ)
            XCTAssertEqual(ответ.запись.рамки.map(\.позиция.начало), [0, 97, 131, 288, 344, 574, 729])
            XCTAssertEqual(ответ.запись.рамки.map(\.позиция.конец), [97, 131, 288, 344, 574, 729, 780])
            XCTAssertEqual(ответ.запись.границаСтрок.байты, 780)
            XCTAssertEqual(ответ.запись.сыройХвост.начало, 780)
            XCTAssertEqual(ответ.запись.сыройХвост.конец, 782)
            XCTAssertEqual(ответ.запись.сыройХвост.хэшДиапазона,
                "3c1c36c746e9b9106e77cfc2ede3374d38a883e23fbcd3b20023e326008c5434")
            let пользователь = #"[{"роль":"user","части":["Повтор\nЁж\u2028конец"]}]"#
            let ожидания = ["[]", "[]", пользователь, "[]",
                #"[{"роль":"assistant","части":["Цитата: Повтор\nЁж\u2028конец",null,""]}]"#,
                пользователь, "[]"]
            XCTAssertEqual(ответ.запись.рамки.count, ожидания.count)
            for (рамка, ожидание) in zip(ответ.запись.рамки, ожидания) {
                let значение = try значениеНаблюдения(рамка.наблюдение)
                XCTAssertEqual(try JSONSerialization.jsonObject(with: Data(значение.utf8)) as? NSArray,
                    try JSONSerialization.jsonObject(with: Data(ожидание.utf8)) as? NSArray)
            }
        }
    }

    private func определение(шагов: Int) throws -> Data {
        let шаги = (0..<шагов).map { ["идентификатор": "шаг-\($0)", "оператор": "нижний-регистр", "аргументы": [:]] as [String: Any] }
        return try JSONSerialization.data(withJSONObject: ["схема": "fum.определение-оператора.2",
            "идентификатор": "проверка-JSONL", "версия": 1, "определения": [], "правила": [], "шаги": шаги], options: [.sortedKeys])
    }

    private func значениеНаблюдения(_ данные: Data) throws -> String {
        let объект = try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        let результат = try XCTUnwrap(объект["результат"] as? [String: Any])
        return try XCTUnwrap(результат["значение"] as? String)
    }

    private func сКаталогом(_ действие: (URL) throws -> Void) throws {
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let физический = try XCTUnwrap(realpath(временный.path, nil))
        defer { free(физический); try? FileManager.default.removeItem(at: временный) }
        try действие(URL(fileURLWithPath: String(cString: физический)))
    }
}
