import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
import FUMStructuringOperatorMemory
@testable import ИсполнениеОператора

@Suite("Явный сохранённый приём JSONL")
struct ПроверкиВосстановленияПриёма {
    @Test("Приём не исполняет рамки и закрепляет ровно четыре части")
    func принятьБезИсполнения() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        let данные = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        let ответ = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        #expect(ответ["схема"] as? String == "fuma.результат-приёма-JSONL.1")
        let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: false, создать: false)
        defer { сегмент.закрыть() }
        #expect(сегмент.записи.count == 5)
        #expect(сегмент.записи.last?.описание.идентификатор == среда.приём + "/манифест-JSONL")
        #expect(!сегмент.записи.contains { $0.описание.тип.hasPrefix("исполнение-") })
        let сохранённый = try #require(сегмент.записи.last)
        let манифест = try #require(JSONSerialization.jsonObject(with:
            сегмент.извлечь(сохранённый.описание.идентификатор)) as? [String: Any])
        #expect(манифест["схема"] as? String == "fuma.приём-JSONL.1")
        #expect(манифест["приём"] as? String == среда.приём)
        let части = ["сыройВход", "исходноеОпределение", "сохранённыйПрофиль", "замыкание"]
        for (номер, часть) in части.enumerated() {
            let ссылка = try #require(манифест[часть])
            let байты = try JSONSerialization.data(withJSONObject: ссылка)
            let квитанция = try JSONDecoder().decode(Квитанция.self, from: байты)
            #expect(квитанция == сегмент.записи[номер])
        }
    }

    @Test("Новый запуск использует выбранный приём после удаления внешних файлов")
    func исполнитьПослеОстановки() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        try FileManager.default.removeItem(at: среда.вход)
        try FileManager.default.removeItem(at: среда.определение)
        let запуск = UUID().uuidString.lowercased()
        let данные = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.исполнение(запуск))
        let ответ = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        #expect(ответ["схема"] as? String == "fuma.результат-принятого-JSONL.1")
        let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: false, создать: false)
        defer { сегмент.закрыть() }
        #expect(сегмент.записи.count == 6)
        #expect(сегмент.записи.last?.описание.идентификатор == запуск)
        let внешняяЗапись = try #require(ответ["запись"] as? [String: Any])
        let ссылка = try #require(внешняяЗапись["манифест"])
        let квитанцияПриёма = try JSONDecoder().decode(Квитанция.self, from:
            JSONSerialization.data(withJSONObject: ссылка))
        #expect(квитанцияПриёма == сегмент.записи[4])
        #expect(внешняяЗапись["повторРезультата"] == nil)
        let запись = try JSONDecoder().decode(ЗаписьСреза.self, from:
            JSONSerialization.data(withJSONObject: try #require(внешняяЗапись["запись"])))
        #expect(запись.рамки.count == 1)
        let перваяРамка = try #require(запись.рамки.first)
        let наблюдение = try #require(JSONSerialization.jsonObject(with:
            перваяРамка.наблюдение) as? [String: Any])
        let результат = try #require(наблюдение["результат"] as? [String: Any])
        #expect(результат["значение"] as? String == "\"ёж\"\n")
    }

    @Test("Отсутствующий манифест не заменяется последними частями")
    func неполныйПриёмЗакрываетВход() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: true)
        let определение = try Data(contentsOf: среда.определение)
        try ПриёмБайтов.сохранить(вход: Data(contentsOf: среда.вход), определение: определение,
            приём: среда.приём, источник: "неизвестно", тип: "JSONL",
            время: "2026-10-25T07:26:09Z", повторЗаписи: nil, сегмент: сегмент)
        let части = [
            ("профиль-JSONL", try кодироватьСтрокуСреза(ПрофильСреза.текущий)),
            ("замыкание-JSONL", try ОпределениеОператора.разобрать(определение).данные())
        ]
        for (часть, байты) in части {
            _ = try сегмент.добавить(ОписаниеНаблюдения(
                идентификатор: среда.приём + "/" + часть, тип: часть, источник: "FUMA",
                время: "2026-10-25T07:26:09Z", спецификация: Data("fuma.исполнение-JSONL.1".utf8)), данные: байты)
        }
        #expect(сегмент.записи.count == 4)
        сегмент.закрыть()
        let до = try Data(contentsOf: среда.журнал.appendingPathComponent("сегмент.fumobs"))
        do {
            _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.исполнение(UUID().uuidString.lowercased()))
            Issue.record("Неполный приём ошибочно исполнен")
        } catch let ошибка as ОшибкаКомандногоИсполнения {
            #expect(ошибка == .записьПовтора)
        }
        #expect(try Data(contentsOf: среда.журнал.appendingPathComponent("сегмент.fumobs")) == до)
    }

    @Test("Поздний приём не подменяет явно выбранный манифест")
    func выбратьТочныйПриём() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        try Data("\"ДРУГОЙ ВХОД\"\n".utf8).write(to: среда.вход)
        var второйПриём = среда.аргументыПриёма
        второйПриём[1] = UUID().uuidString.lowercased()
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: второйПриём)
        let новыеБайты = try КомандноеИсполнениеОператора.выполнить(
            аргументы: среда.исполнение(UUID().uuidString.lowercased()))
        let новыйОтвет = try #require(JSONSerialization.jsonObject(with: новыеБайты) as? [String: Any])
        let новый = try #require(новыйОтвет["запись"] as? [String: Any])
        let новоеВычисление = try JSONDecoder().decode(ЗаписьСреза.self,
            from: JSONSerialization.data(withJSONObject: try #require(новый["запись"])))
        #expect(новоеВычисление.сыройВход.описание.идентификатор == среда.приём + "/вход-оператора")
        #expect(новоеВычисление.сыройХвост.хэшДиапазона == хэшБайтовСреза(Data("хвост".utf8)))
        let квитанция = try JSONDecoder().decode(Квитанция.self,
            from: JSONSerialization.data(withJSONObject: try #require(новыйОтвет["квитанция"])))
        let повторБайты = try КомандноеИсполнениеОператора.выполнить(аргументы:
            ["--повторить-JSONL", квитанция.описание.идентификатор, "--журнал", среда.журнал.path])
        let повторОтвет = try #require(JSONSerialization.jsonObject(with: повторБайты) as? [String: Any])
        let повтор = try #require(повторОтвет["запись"] as? [String: Any])
        let родитель = try JSONDecoder().decode(Квитанция.self,
            from: JSONSerialization.data(withJSONObject: try #require(повтор["повторРезультата"])))
        let повторноеВычисление = try JSONDecoder().decode(ЗаписьСреза.self,
            from: JSONSerialization.data(withJSONObject: try #require(повтор["запись"])))
        #expect(родитель == квитанция)
        #expect(повторноеВычисление == новоеВычисление)
    }

    @Test("Полный бюджет сохраняет частичный результат и допускает его replay", arguments: [10_000, 12_000, 16_000])
    func бюджетПолнойФормы(предел: Int) throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        var профиль = ПрофильСреза.текущий
        профиль.результат = предел
        let строка = "\"" + String(repeating: "Ё", count: 750) + "\"\n"
        _ = try ИсполнениеСреза.принять(приём: среда.приём,
            вход: Data(String(repeating: строка, count: 8).utf8),
            определение: Data(contentsOf: среда.определение), каталог: среда.журнал, пределы: профиль)
        let исполнение = UUID().uuidString.lowercased()
        let байты = try ИсполнениеСреза.исполнитьПринятый(
            приём: среда.приём, исполнение: исполнение, каталог: среда.журнал)
        let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: байты)
        #expect(байты.count <= предел)
        #expect(ответ.запись.запись.рамки.count < 8)
        #expect(ответ.запись.запись.отказ != nil)
        let повторБайты = try ИсполнениеСреза.повторить(исполнение, каталог: среда.журнал)
        let повтор = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: повторБайты)
        #expect(повторБайты.count <= предел)
        #expect(повтор.запись.запись == ответ.запись.запись)
        #expect(повтор.запись.повторРезультата == ответ.квитанция)
    }

    @Test("Неверный дальний предок не скрывается за корректным родителем")
    func проверитьВсюЦепь() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        let байты = try КомандноеИсполнениеОператора.выполнить(
            аргументы: среда.исполнение(UUID().uuidString.lowercased()))
        let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from: байты)
        let отсутствующая = try квитанцияСАдресом(ответ.квитанция, UUID().uuidString.lowercased())
        let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: true, создать: false)
        let родитель = try добавитьРезультат(ответ.запись, предок: отсутствующая,
            адрес: UUID().uuidString.lowercased(), сегмент: сегмент)
        let потомок = try добавитьРезультат(ответ.запись, предок: родитель,
            адрес: UUID().uuidString.lowercased(), сегмент: сегмент)
        сегмент.закрыть()
        let файл = среда.журнал.appendingPathComponent("сегмент.fumobs")
        let до = try Data(contentsOf: файл)
        do {
            _ = try ИсполнениеСреза.повторить(потомок.описание.идентификатор, каталог: среда.журнал)
            Issue.record("Принят результат с отсутствующим дальним предком")
        } catch let ошибка as ОшибкаКомандногоИсполнения {
            #expect(ошибка == .записьПовтора)
        }
        #expect(try Data(contentsOf: файл) == до)
    }

    @Test("Reader нового формата требует UUID результата")
    func проверитьАдресРезультата() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        let ответ = try JSONDecoder().decode(ОтветПринятогоСреза.self, from:
            КомандноеИсполнениеОператора.выполнить(аргументы: среда.исполнение(UUID().uuidString.lowercased())))
        let сегмент = try Сегмент(кореньДанных: среда.журнал, запись: true, создать: false)
        _ = try добавитьРезультат(ответ.запись, предок: nil, адрес: "не-UUID", сегмент: сегмент)
        сегмент.закрыть()
        #expect(throws: (any Error).self) {
            try ИсполнениеСреза.повторить("не-UUID", каталог: среда.журнал)
        }
    }

    @Test("Отказ fsync манифеста не возвращает подтверждение и не повторяет приём")
    func отказСинхронизацииМанифеста() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        let файл = среда.журнал.appendingPathComponent("сегмент.fumobs")
        let маркер = Data("\"тип\":\"манифест-JSONL\"".utf8)
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: { дескриптор in
                if try Data(contentsOf: файл).range(of: маркер) != nil {
                    throw ОшибкаКонтейнера.система(EIO)
                }
                try ФайловыеОперации.системные.синхронизация(дескриптор)
            })
        do {
            _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма, операции: операции)
            Issue.record("Выдано подтверждение после отказа fsync")
        } catch let ошибка as ОшибкаКонтейнера {
            #expect(ошибка == .система(EIO))
        }
        let до = try Data(contentsOf: файл)
        do {
            _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
            Issue.record("Неизвестный исход приёма ошибочно повторён")
        } catch let ошибка as ОшибкаКонтейнера {
            #expect(ошибка == .конфликтИдентификатора)
        }
        #expect(try Data(contentsOf: файл) == до)
    }

    @Test("Неполный хвост контейнера не восстанавливается автоматически")
    func запретитьЗаписьПоверхХвоста() throws {
        let среда = try СредаПриёма()
        defer { среда.удалить() }
        _ = try КомандноеИсполнениеОператора.выполнить(аргументы: среда.аргументыПриёма)
        let файл = среда.журнал.appendingPathComponent("сегмент.fumobs")
        let запись = try FileHandle(forWritingTo: файл)
        _ = try запись.seekToEnd()
        try запись.write(contentsOf: Data([0xff]))
        try запись.synchronize()
        try запись.close()
        let до = try Data(contentsOf: файл)
        do {
            _ = try КомандноеИсполнениеОператора.выполнить(
                аргументы: среда.исполнение(UUID().uuidString.lowercased()))
            Issue.record("Исполнение принято поверх неполного хвоста")
        } catch let ошибка as ОшибкаКонтейнера {
            #expect(ошибка == .неполныйХвост)
        }
        #expect(try Data(contentsOf: файл) == до)
    }

    private func квитанцияСАдресом(_ исходная: Квитанция, _ адрес: String) throws -> Квитанция {
        let байты = try JSONEncoder().encode(исходная)
        var объект = try #require(JSONSerialization.jsonObject(with: байты) as? [String: Any])
        var описание = try #require(объект["описание"] as? [String: Any])
        описание["идентификатор"] = адрес
        объект["описание"] = описание
        return try JSONDecoder().decode(Квитанция.self, from: JSONSerialization.data(withJSONObject: объект))
    }

    private func добавитьРезультат(_ исходная: ЗаписьПринятогоСреза, предок: Квитанция?,
                                  адрес: String, сегмент: Сегмент) throws -> Квитанция {
        let запись = ЗаписьПринятогоСреза(схема: исходная.схема, манифест: исходная.манифест,
            повторРезультата: предок, запись: исходная.запись)
        return try сегмент.добавить(ОписаниеНаблюдения(идентификатор: адрес,
            тип: "исполнение-принятого-JSONL", источник: "FUMA", время: "2026-10-25T07:26:09Z",
            спецификация: кодироватьСтрокуСреза(запись.запись.профиль)), данные: кодироватьСтрокуСреза(запись))
    }
}

private struct СредаПриёма {
    let корень: URL
    let журнал: URL
    let вход: URL
    let определение: URL
    let приём = UUID().uuidString.lowercased()

    init() throws {
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        guard let физический = realpath(временный.path, nil) else { throw ОшибкаКонтейнера.система(errno) }
        defer { free(физический) }
        корень = URL(fileURLWithPath: String(cString: физический), isDirectory: true)
        журнал = корень.appendingPathComponent("журнал")
        вход = корень.appendingPathComponent("вход.jsonl")
        определение = корень.appendingPathComponent("оператор.json")
        try FileManager.default.createDirectory(at: журнал, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        try Data("\"ЁЖ\"\nхвост".utf8).write(to: вход)
        try Data(#"{"схема":"fum.определение-оператора.2","идентификатор":"приём-CLI","версия":1,"определения":[],"правила":[],"шаги":[{"идентификатор":"регистр","оператор":"нижний-регистр","аргументы":{}}]}"#.utf8).write(to: определение)
    }

    var аргументыПриёма: [String] {
        ["--принять-JSONL", приём, "--вход", вход.path, "--определение", определение.path, "--журнал", журнал.path]
    }

    func исполнение(_ запуск: String) -> [String] {
        ["--исполнить-приём-JSONL", приём, "--исполнение", запуск, "--журнал", журнал.path]
    }

    func удалить() { try? FileManager.default.removeItem(at: корень) }
}
