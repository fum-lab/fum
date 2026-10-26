import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import АктуализацияПутей

@Suite("Пакет девяти путей")
struct ПроверкиПакета {
    private func разрешающийВход() -> ВходРешенияПакета {
        ВходРешенияПакета(ограды: ОградыПакета(план_совпадает: true, снимок_совпадает: true,
            индекс_совпадает: true, пути_разрешены: true), число_переносов: 9, состояние_намерения: "сохранено")
    }

    @Test("Долговечное намерение и все ограды различают решение существующего FUMA")
    func структурирующееРешение() throws {
        let результат = try ПравилаПакета.выполнить(разрешающийВход())
        #expect(результат.решение.допустить_применение)
        #expect(результат.решение.применение == "не-выполнено")
        #expect(результат.решение.причина == nil)
        let наблюдение = try #require(JSONSerialization.jsonObject(with: результат.наблюдение) as? [String: Any])
        #expect(наблюдение["схема"] as? String == "fum.наблюдение-оператора.2")
        let применения = try #require(наблюдение["применения"] as? [[String: Any]])
        #expect(применения.count == 1)
        #expect(применения.first?["определение"] as? String == "все-ограды-разрешают")
    }

    @Test("Число, схема, намерение и каждая отдельная ограда закрывают применение")
    func структурирующиеОтказы() throws {
        for номер in 0..<7 {
            var вход = разрешающийВход()
            let причина: String
            switch номер {
            case 0: вход.схема = "неизвестно"; причина = "неверная-схема-входа"
            case 1: вход.число_переносов = 8; причина = "не-девять-переносов"
            case 2: вход.состояние_намерения = "неизвестно"; причина = "намерение-не-сохранено"
            case 3: вход.ограды.план_совпадает = false; причина = "ограды-не-пройдены"
            case 4: вход.ограды.снимок_совпадает = false; причина = "ограды-не-пройдены"
            case 5: вход.ограды.индекс_совпадает = false; причина = "ограды-не-пройдены"
            default: вход.ограды.пути_разрешены = false; причина = "ограды-не-пройдены"
            }
            let решение = try ПравилаПакета.выполнить(вход).решение
            #expect(!решение.допустить_применение)
            #expect(решение.причина == причина)
        }
    }

    @Test("Один план связывает девять blob, полный Markdown и пять правок")
    func конечныйПакетныйПлан() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        #expect(план.переносы.count == 9)
        #expect(план.правки.count == 5)
        #expect(план.документы.count == 7)
        #expect(план.документы.contains { $0.путь == "заметка.md" })
        #expect(план.переносы.map(\.целевой) == ФикстураПакета.пути.map { $0.1 })
        for перенос in план.переносы {
            #expect(перенос.режим == "100644")
            #expect(try фикстура.гит(["rev-parse", "HEAD:" + перенос.исходный]) == Data((перенос.объект + "\n").utf8))
        }
    }

    @Test("Каноническое равенство String не подменяет exact UTF-8 плана")
    func байтоваяСвязностьПлана() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        var подмена = план
        подмена.переносы[4].исходный = подмена.переносы[4].исходный.decomposedStringWithCanonicalMapping
        #expect(подмена.переносы[4].исходный == план.переносы[4].исходный)
        #expect(Data(подмена.переносы[4].исходный.utf8) != Data(план.переносы[4].исходный.utf8))
        let изменённые = try байтыПлана(подмена)
        #expect(throws: ОтказПакета.условие("дрейф-снимка")) {
            try ПакетПутей.сверить(сохранённые: изменённые, ожидаемыйХэш: хэшПутей(изменённые), текущий: план)
        }
        let сохранённые = try байтыПлана(план)
        try ПакетПутей.сверить(сохранённые: сохранённые, ожидаемыйХэш: хэшПутей(сохранённые), текущий: план)
    }

    @Test("Разбор не прячет активные ссылки и не меняет protected reference")
    func оградыРазбораMarkdown() throws {
        let пары = ФикстураПакета.пути.map { ОтображениеПути(исходный: $0.0, целевой: $0.1) }
        func разрешить(_ текст: String, путь: String) throws -> [ИзменениеСсылокПакета] {
            let данные = Data(текст.utf8)
            return try РешательСсылокПакета.разрешить(документы: [ДокументСсылокПакета(
                путь: путь, байты: данные, sha256: хэшПутей(данные))], ожидаемыеПути: [путь],
                пары: пары, разрешённыеДокументы: ПакетПутей.разрешённыеДокументы, проверитьАдрес: { _ in })
        }
        let живойПуть = "iskhodniki/zapusk/README.md"
        let ссылка = "[Архив](../arkhiv-codex/README.md)"
        #expect(try разрешить("```example```\n\n" + ссылка + "\n", путь: живойПуть).count == 1)
        #expect(try разрешить("Перед `x\n\n" + ссылка + "\n\nПосле `.\n", путь: живойПуть).count == 1)
        let закодированный = "../arkhiv-codex/README.md".unicodeScalars.map { "&#x" + String($0.value, radix: 16) + ";" }.joined()
        #expect(throws: ОтказСсылокПакета.self) {
            try разрешить("<a\nhref=\n\"" + закодированный + "\"\n>x\n</a>\n", путь: живойПуть)
        }
        let путьЗапроса = "Журнал/2026-10-26_01-48-08_MSK_включить-принятую-основу-в-архив-codex/запрос.md"
        #expect(throws: ОтказСсылокПакета.self) {
            try разрешить("## Текст запроса\n[сырьё][r]\n\n## Повлиял на файлы\n[r]: ../../iskhodniki/arkhiv-codex/README.md\n", путь: путьЗапроса)
        }
    }

    @Test("Открытый FD не заменяет позднюю проверку имени каталога")
    func именнаяСвязьКаталога() throws {
        let фикстура = try ФикстураПакета()
        let исходный = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/komanda")
        let запасной = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/запасной")
        let временный = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/временный")
        try FileManager.default.createDirectory(at: запасной, withIntermediateDirectories: false)
        try Data("другой inode\n".utf8).write(to: запасной.appendingPathComponent("Команда.swift"))
        let читатель = try ЧитательПакета(фикстура.корень)
        _ = try читатель.прочитать(ФикстураПакета.пути[0].0)
        try FileManager.default.moveItem(at: исходный, to: временный)
        try FileManager.default.moveItem(at: запасной, to: исходный)
        try FileManager.default.moveItem(at: временный, to: запасной)
        #expect(throws: ОтказПакета.self) { try читатель.снимокКаталогов() }
    }

    @Test("Apply переносит всю партию; Package и Markdown остаются вне индекса")
    func переносПартииИСтадирование() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let квитанция = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        #expect(квитанция.исход == "завершено")
        #expect(квитанция.подтверждённый_префикс == 14)
        for перенос in план.переносы {
            #expect(!FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(перенос.исходный).path))
            let данные = try Data(contentsOf: фикстура.корень.appendingPathComponent(перенос.целевой))
            #expect(хэшПутей(данные) == перенос.sha256)
            #expect(try фикстура.гит(["rev-parse", ":" + перенос.целевой]) == Data((перенос.объект + "\n").utf8))
        }
        let неиндексированные = Set(try фикстура.гит(["diff", "--name-only", "-z"]).split(separator: 0).map { Data($0) })
        #expect(неиндексированные == Set(план.правки.map { Data($0.путь.utf8) }))
        for правка in план.правки {
            #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent(правка.путь)) == правка.после)
            #expect(try ЧитательПакета(фикстура.корень).прочитать(правка.путь).0.режим == правка.режим)
        }
        #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent("Источники/native.jsonl")) == фикстура.сырые)
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        let повтор = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        #expect(повтор == квитанция)
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
    }

    @Test("Receipt не принимает дырку подтверждений и невозможный частичный исход")
    func невозможнаяКвитанция() async throws {
        for дырка in [false, true] {
            let фикстура = try ФикстураПакета()
            let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
            let байты = try байтыПлана(план)
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план,
                байты: байты, основаДляПроверки: фикстура.хранилище, создать: true))
            if дырка {
                try журнал.записать("шаг-2-намерение", Data())
                try журнал.записать("шаг-2-подтверждение", Data())
            }
            let ложная = КвитанцияПакета(план_sha256: хэшПутей(байты),
                исход: дырка ? "неизвестно" : "частичный", подтверждённый_префикс: 0,
                наблюдённый_префикс: nil, причина: "проверка")
            try журнал.записать("итог", байтыПлана(ложная))
            #expect(throws: ОтказПакета.self) { try журнал.квитанция() }
        }
    }

    @Test("Перехваченный отказ откатывает доказанный префикс, сохраняя forward ack", arguments: [3, 11])
    func проверенныйОткат(шаг: Int) async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let квитанция = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище,
            неисправность: { этап, номер in
                if этап == "после-эффекта", номер == шаг { throw ОтказПакета.условие("введённый-отказ") }
            })
        #expect(квитанция.исход == "откат-проверен")
        #expect(квитанция.подтверждённый_префикс == шаг - 1)
        #expect(квитанция.наблюдённый_префикс == 0)
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == план.индекс)
        for правка in план.правки {
            #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent(правка.путь)) == правка.прежде)
        }
        for перенос in план.переносы {
            #expect(try хэшПутей(Data(contentsOf: фикстура.корень.appendingPathComponent(перенос.исходный))) == перенос.sha256)
            #expect(!FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(перенос.целевой).path))
        }
    }

    @Test("Неполный откат сохраняет наблюдённый префикс и больше не исполняется")
    func частичныйОткат() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let квитанция = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище,
            неисправность: { этап, номер in
                if (этап == "после-эффекта" && номер == 4) || (этап == "до-отката" && номер == 3) {
                    throw ОтказПакета.условие("введённый-отказ")
                }
            })
        #expect(квитанция.исход == "частичный")
        #expect(квитанция.подтверждённый_префикс == 3)
        #expect(квитанция.наблюдённый_префикс == 3)
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        let повтор = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище,
            неисправность: { _, _ in Issue.record("Повтор receipt запустил эффект") })
        #expect(повтор == квитанция)
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
    }

    @Test("Отказ после успешного Git-примитива сохраняет unknown и не повторяет эффект")
    func неизвестныйПереход() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let корень = фикстура.корень
        let квитанция = try await ПакетПутей.применить(корень: корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище,
            неисправность: { этап, номер in
                if этап == "после-примитива", номер == 3 {
                    throw ОтказПакета.условие("неизвестная-долговечность-примитива")
                }
            })
        #expect(квитанция.исход == "неизвестно")
        #expect(квитанция.подтверждённый_префикс == 2)
        #expect(квитанция.наблюдённый_префикс == nil)
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent(план.переносы[2].исходный).path))
        #expect(try фикстура.гит(["rev-parse", ":" + план.переносы[2].целевой]) == Data((план.переносы[2].объект + "\n").utf8))
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        let повтор = try await ПакетПутей.применить(корень: корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        #expect(повтор == квитанция)
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
    }

    @Test("Дрейф после durable intent останавливает первый rename", arguments: ["HEAD", "ref", "source", "index", "Markdown"])
    func оградаПослеНамерения(вид: String) async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план), корень = фикстура.корень
        let перенос = план.переносы[0]
        let квитанция = try await ПакетПутей.применить(корень: корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище,
            неисправность: { этап, номер in
                guard этап == "после-намерения", номер == 1 else { return }
                switch вид {
                case "HEAD":
                    _ = try ЧитательПакета.гит(корень, ["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid",
                        "-c", "commit.gpgSign=false", "commit", "--allow-empty", "-m", "Внешний дрейф"])
                case "source":
                    try Data("внешний дрейф\n".utf8).write(to: корень.appendingPathComponent(перенос.исходный))
                case "ref":
                    _ = try ЧитательПакета.гит(корень, ["branch", "-m", "codex/другая"])
                case "Markdown":
                    try Data("# Новая неигнорируемая заметка\n".utf8).write(to: корень.appendingPathComponent("новая.md"))
                default:
                    try Data("внешний дрейф\n".utf8).write(to: корень.appendingPathComponent("Источники/native.jsonl"))
                    _ = try ЧитательПакета.гит(корень, ["add", "--", "Источники/native.jsonl"])
                }
            })
        #expect(квитанция.исход == "неизвестно")
        #expect(квитанция.подтверждённый_префикс == 0)
        #expect(FileManager.default.fileExists(atPath: корень.appendingPathComponent(перенос.исходный).path))
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent(перенос.целевой).path))
        if вид != "index" { #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == план.индекс) }
    }

    @Test("Batch отвергает грязный source, casefold-назначение, symlink и hardlink",
        arguments: ["dirty", "casefold", "symlink", "hardlink"])
    func исходныеОграды(вид: String) async throws {
        let фикстура = try ФикстураПакета(), корень = фикстура.корень
        let вход = try фикстура.поручение()
        let исходник = корень.appendingPathComponent(ФикстураПакета.пути[0].0)
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        switch вид {
        case "dirty": try Data("другие байты\n".utf8).write(to: исходник)
        case "casefold":
            try Data().write(to: корень.appendingPathComponent("iskhodniki/arkhiv-codex/komanda/KOMANDA.swift"))
        case "symlink":
            try FileManager.default.removeItem(at: исходник)
            try FileManager.default.createSymbolicLink(at: исходник,
                withDestinationURL: корень.appendingPathComponent("Источники/native.jsonl"))
        default: try FileManager.default.linkItem(at: исходник, to: корень.appendingPathComponent("hardlink"))
        }
        await #expect(throws: ОтказПакета.self) { try await ПакетПутей.построить(корень: корень, вход: вход) }
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
        #expect(!FileManager.default.fileExists(atPath: фикстура.хранилище.path))
    }

    @Test("Публичный фасад принимает Data и отвергает неподписанное применение")
    func публичнаяГраница() async throws {
        let фикстура = try ФикстураПакета()
        let данные = try await ПакетноеПрименениеПутей.построить(корень: фикстура.корень,
            поручение: байтыПлана(фикстура.поручение()))
        let план = try JSONDecoder().decode(ПланПакета.self, from: данные)
        #expect(план.переносы.count == 9)
        try await ПакетноеПрименениеПутей.сверить(корень: фикстура.корень, план: данные, sha256: хэшПутей(данные))
        await #expect(throws: ОтказПакета.условие("SHA-плана-не-совпал")) {
            try await ПакетноеПрименениеПутей.применить(корень: фикстура.корень, план: данные, sha256: "невыбранный")
        }
        var прежний = план; прежний.применение_разрешено = false
        let прежниеБайты = try байтыПлана(прежний)
        await #expect(throws: ОтказПакета.условие("неверный-план-применения")) {
            try await ПакетПутей.применить(корень: фикстура.корень, план: прежниеБайты,
                ожидаемыйХэш: хэшПутей(прежниеБайты), хранилищеДляПроверки: фикстура.хранилище)
        }
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == план.индекс)
    }

    @Test("Постоянный слот не обходится новым UUID плана")
    func постоянныйСлотИНеизвестноеНамерение() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        do {
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план, байты: байты,
                основаДляПроверки: фикстура.хранилище, создать: true))
            #expect(журнал.новый)
            try журнал.записать("шаг-1-намерение", Data("подтверждение ещё отсутствует".utf8))
        }
        do {
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план, байты: байты,
                основаДляПроверки: фикстура.хранилище, создать: false))
            #expect(!журнал.новый)
            #expect(try журнал.есть("шаг-1-намерение"))
            #expect(try журнал.подтверждённыйПрефикс == 0)
            #expect(try журнал.квитанция() == nil)
        }
        var другой = план
        другой.поручение.корневая_задача = UUID().uuidString.lowercased()
        let другиеБайты = try байтыПлана(другой)
        #expect(throws: ОтказПакета.условие("слот-занят-другим-планом")) {
            try ЖурналПакета.открыть(корень: фикстура.корень, план: другой, байты: другиеБайты,
                основаДляПроверки: фикстура.хранилище, создать: true)
        }
    }

    @Test("Потеря ожидаемого segment не превращается в пустое новое хранилище")
    func потеряДолговечногоСегмента() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        do {
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план, байты: байты,
                основаДляПроверки: фикстура.хранилище, создать: true))
            #expect(журнал.новый)
        }
        let сегмент = фикстура.хранилище.appendingPathComponent(план.пространство).appendingPathComponent("сегмент.fumobs")
        try FileManager.default.removeItem(at: сегмент)
        #expect(throws: ОтказПакета.условие("хранилище-ожидалось-но-потеряно")) {
            try ЖурналПакета.открыть(корень: фикстура.корень, план: план, байты: байты,
                основаДляПроверки: фикстура.хранилище, создать: true)
        }
        #expect(!FileManager.default.fileExists(atPath: сегмент.path))
    }

    @Test("Недоверенный namespace и несвязанные байты не создают другой слот")
    func подменаПространства() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        var другой = план
        другой.пространство = String(repeating: "0", count: 64)
        let чужиеБайты = try байтыПлана(другой)
        for объект in [план, другой] {
            #expect(throws: ОтказПакета.условие("не-подтверждён-приватный-namespace")) {
                try ЖурналПакета.открыть(корень: фикстура.корень, план: объект, байты: чужиеБайты,
                    основаДляПроверки: фикстура.хранилище, создать: true)
            }
        }
        #expect(!FileManager.default.fileExists(atPath: фикстура.хранилище.path))
    }

    @Test("После failed sync instance закрыт; reopen повторяет sync перед чтением")
    func неизвестнаяДолговечностьAppend() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let сбой = ПереключательСинхронизации()
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { fd in
            if сбой.отказывать { throw ОшибкаКонтейнера.система(EIO) }
            try ФайловыеОперации.системные.синхронизация(fd)
        })
        do {
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план,
                байты: байты, основаДляПроверки: фикстура.хранилище, создать: true, операции: операции))
            сбой.установить(true)
            #expect(throws: ОшибкаКонтейнера.система(EIO)) { try журнал.записать("пробная", Data([1, 2, 3])) }
            #expect(throws: ОтказПакета.self) { try журнал.записать("другая", Data()) }
            #expect(throws: ОтказПакета.self) { try журнал.есть("пробная") }
            #expect(throws: ОтказПакета.self) { try журнал.прочитать("пробная") }
            #expect(throws: ОтказПакета.self) { try журнал.подтверждённыйПрефикс }
            #expect(throws: ОтказПакета.self) { try журнал.квитанция() }
        }
        #expect(throws: ОшибкаКонтейнера.система(EIO)) {
            try ЖурналПакета.открыть(корень: фикстура.корень, план: план, байты: байты,
                основаДляПроверки: фикстура.хранилище, создать: false, операции: операции)
        }
        сбой.установить(false)
        let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план,
            байты: байты, основаДляПроверки: фикстура.хранилище, создать: false, операции: операции))
        #expect(try журнал.прочитать("пробная") == Data([1, 2, 3]))
    }

    @Test("Pending и повреждённый хвост не запускают новую операцию")
    func незавершённыйЖурнал() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        do {
            let журнал = try #require(try ЖурналПакета.открыть(корень: фикстура.корень, план: план,
                байты: байты, основаДляПроверки: фикстура.хранилище, создать: true))
            try журнал.записать("шаг-1-намерение", Data())
        }
        await #expect(throws: ОтказПакета.условие("существует-незавершённое-намерение-эффект-не-повторён")) {
            try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
                ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        }
        let сегмент = фикстура.хранилище.appendingPathComponent(план.пространство + "/сегмент.fumobs")
        let файл = try FileHandle(forWritingTo: сегмент)
        try файл.seekToEnd(); try файл.write(contentsOf: Data([255])); try файл.synchronize(); try файл.close()
        await #expect(throws: ОтказПакета.условие("неполный-хвост-журнала")) {
            try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
                ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        }
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == план.индекс)
    }

    @Test("Позднее изменение untracked Markdown останавливает партию до первого эффекта")
    func позднийДрейфMarkdown() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        try фикстура.записать("заметка.md", "изменено\n")
        let байты = try байтыПлана(план)
        await #expect(throws: ОтказПакета.условие("дрейф-снимка")) {
            try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
                ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        }
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
        #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(ФикстураПакета.пути[0].0).path))
    }

    @Test("Адресный профиль одного dry-run и отдельно сверенного apply",
        .enabled(if: ProcessInfo.processInfo.environment["FUM_BATCH_PROFILE_OUT"] != nil))
    func адресныйПрофиль() async throws {
        let фикстура = try ФикстураПакета()
        for номер in 0..<200 { try фикстура.записать("документы/заметка-\(номер).md", "# Несвязанная заметка \(номер)\n") }
        let имена = try await ТранслитераторПутей().отобразить([ЗаписьСнимкаПутей(путь: "Профиль.json")])
        let имя = try #require(имена.first?.целевой)
        let профиль = ПрофильПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение(), профиль: профиль)
        let байты = try байтыПлана(план)
        let квитанция = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище, профиль: профиль)
        let замеры = профиль.снимок()
        try #require(квитанция.исход == "завершено" && квитанция.подтверждённый_префикс == 14)
        try #require(замеры.filter { $0.этап == "разрешение-всего-Markdown" }.count == 2)
        try #require(замеры.filter { $0.этап == "прямой-эффект" }.count == 14)
        struct Профиль: Encodable {
            var схема = "fum.профиль-пакета-девяти-путей.1"
            var имя_результата: String
            var документов: Int
            var глобальных_планов = 2
            var разборов_всего_Markdown = 2
            var план_sha256: String
            var квитанция: КвитанцияПакета
            var замеры: [ЗамерПакета]
            var условия = "Одна синтетическая fixture, n=1. Подготовка и сериализация результата исключены; алгоритм имён прогрет получением имени профиля. Два глобальных плана: dry-run и повторная сверка apply; не девять отдельных планов. Монотонные вложенные интервалы не складываются. Без baseline и утверждения об ускорении; не профиль ROOT/live RAW."
        }
        let данные = try байтыПлана(Профиль(имя_результата: имя, документов: план.документы.count,
            план_sha256: хэшПутей(байты), квитанция: квитанция, замеры: замеры))
        let адрес = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["FUM_BATCH_PROFILE_OUT"]))
        let родитель = адрес.deletingLastPathComponent()
        try #require(try Data(ЧитательПакета.физический(родитель).path.utf8) == Data(родитель.path.utf8))
        var текущий = родитель.path
        while true {
            try #require(!FileManager.default.fileExists(atPath: текущий + "/.git"))
            if текущий == "/" { break }
            let следующий = (текущий as NSString).deletingLastPathComponent
            try #require(следующий.utf8.count < текущий.utf8.count)
            текущий = следующий
        }
        let дескриптор = open(адрес.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        try #require(дескриптор >= 0)
        defer { close(дескриптор) }
        try FileHandle(fileDescriptor: дескриптор, closeOnDealloc: false).write(contentsOf: данные)
        try #require(fsync(дескриптор) == 0)
        let каталог = open(родитель.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        try #require(каталог >= 0)
        defer { close(каталог) }
        try #require(fsync(каталог) == 0)
    }

    @Test("Несвязанные legacy адреса не блокируют конечные девять путей")
    func несвязанныйНеподдержанныйMarkdown() throws {
        let пары = ФикстураПакета.пути.map { ОтображениеПути(исходный: $0.0, целевой: $0.1) }
        let адрес = "other.txt".unicodeScalars.map { "&#x" + String($0.value, radix: 16) + ";" }.joined()
        for текст in ["[Чужое](other%GG.txt)\n", "<a\nhref=\n\"" + адрес + "\"\n>x\n</a>\n"] {
            let путь = "iskhodniki/zapusk/README.md", данные = Data(текст.utf8)
            do {
                let изменения = try РешательСсылокПакета.разрешить(документы: [ДокументСсылокПакета(
                    путь: путь, байты: данные, sha256: хэшПутей(данные))], ожидаемыеПути: [путь], пары: пары,
                    разрешённыеДокументы: ПакетПутей.разрешённыеДокументы, проверитьАдрес: { _ in })
                #expect(изменения.isEmpty)
            } catch { Issue.record("Несвязанный legacy адрес ошибочно закрыл batch: \(error)") }
        }
    }

    @Test("Полный ref сравнивается по исходным UTF8, даже при NFC-равенстве")
    func байтоваяПривязкаRef() async throws {
        let фикстура = try ФикстураПакета()
        _ = try фикстура.гит(["branch", "-m", "codex/йота"])
        var вход = try фикстура.поручение()
        let исходный = вход.ветка
        вход.ветка = исходный.decomposedStringWithCanonicalMapping
        #expect(вход.ветка == исходный)
        #expect(Data(вход.ветка.utf8) != Data(исходный.utf8))
        let подмена = вход
        await #expect(throws: ОтказПакета.условие("дрейф-адреса")) {
            try await ПакетПутей.построить(корень: фикстура.корень, вход: подмена)
        }
    }
}

// Только тестовый переключатель. Всё изменяемое состояние защищено одним NSLock.
private final class ПереключательСинхронизации: @unchecked Sendable {
    private let замок = NSLock()
    private var значение = false
    var отказывать: Bool { замок.withLock { значение } }
    func установить(_ новое: Bool) { замок.withLock { значение = новое } }
}

private final class ФикстураПакета {
    static let пути = [
        ("iskhodniki/arkhiv-codex/komanda/Команда.swift", "iskhodniki/arkhiv-codex/komanda/komanda.swift"),
        ("iskhodniki/arkhiv-codex/Архив.swift", "iskhodniki/arkhiv-codex/arkhiv.swift"),
        ("iskhodniki/arkhiv-codex/Источник.swift", "iskhodniki/arkhiv-codex/istochnik.swift"),
        ("iskhodniki/arkhiv-codex/Порция.swift", "iskhodniki/arkhiv-codex/porciya.swift"),
        ("iskhodniki/arkhiv-codex/Файлы.swift", "iskhodniki/arkhiv-codex/fajlyi.swift"),
        ("proverki/arkhiv-codex/АрхивТесты.swift", "proverki/arkhiv-codex/arkhiv-testyi.swift"),
        ("proverki/arkhiv-codex/ПроцессыИПрофиль.swift", "proverki/arkhiv-codex/processyi-i-profilj.swift"),
        ("proverki/arkhiv-codex/СовместимостьЗапуска.swift", "proverki/arkhiv-codex/sovmestimostj-zapuska.swift"),
        ("iskhodniki/arkhiv-codex/README.md", "iskhodniki/arkhiv-codex/rukovodstvo.md")
    ]
    let родитель: URL
    let корень: URL
    let хранилище: URL
    let сырые = Data([0, 1, 2, 255, 10, 13, 0])

    init() throws {
        родитель = try ЧитательПакета.физический(FileManager.default.temporaryDirectory)
            .appendingPathComponent("fum-batch-" + UUID().uuidString)
        корень = родитель.appendingPathComponent("worktree")
        хранилище = родитель.appendingPathComponent("runtime")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        _ = try гит(["init", "--initial-branch=codex/batch-fixture"])
        for (путь, _) in Self.пути { try записать(путь, "синтетические байты \(путь)\n") }
        try записать("iskhodniki/arkhiv-codex/README.md", "# Архив\n\n[Другое](../другое.md)\n")
        try записать("Package.swift", """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(name: "Фикстура", targets: [
            .target(name: "АрхивКодекса", dependencies: [],
                path: "iskhodniki/arkhiv-codex", exclude: ["README.md", "zhurnal"])
        ])

        """)
        try записать("iskhodniki/zapusk/README.md", "# Запуск\n\n[Архив](../arkhiv-codex/README.md)\n")
        try записать("Журнал/2026-10-26_00-11-30_MSK_сохранить-многосегментный-raw-codex/отчёт.md",
            "# Отчёт\n\n## Источники\n\n[Архив](../../iskhodniki/arkhiv-codex/README.md)\n")
        try записать("Журнал/2026-10-26_01-48-08_MSK_включить-принятую-основу-в-архив-codex/запрос.md",
            "# Запрос\n\n## Текст запроса\n\n```text\n[Дословно](../../iskhodniki/arkhiv-codex/README.md)\n```\n\n## Повлиял на файлы\n\n[Архив](../../iskhodniki/arkhiv-codex/README.md)\n")
        try записать("Сбои/FUM-СБОЙ-0241-декомпозиция-имени-профиля.md",
            "# Сбой\n\n[Профиль](../proverki/arkhiv-codex/ПроцессыИПрофиль.swift)\n")
        try записать("Источники/сырой.md", "```text\n[Дословно](../iskhodniki/arkhiv-codex/README.md)\n```\n")
        try сырые.write(to: корень.appendingPathComponent("Источники/native.jsonl"))
        _ = try гит(["add", "--all", "--", "."])
        _ = try гит(["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgSign=false", "commit", "-m", "Фикстура"])
        try записать("заметка.md", "# Новая неигнорируемая заметка\n")
    }

    deinit { try? FileManager.default.removeItem(at: родитель) }

    func записать(_ путь: String, _ текст: String) throws {
        let файл = корень.appendingPathComponent(путь)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(текст.utf8).write(to: файл)
    }

    func гит(_ аргументы: [String]) throws -> Data {
        do { return try ЧитательПакета.гит(корень, аргументы) }
        catch { throw ОтказПакета.условие("отказ-фикстуры: " + аргументы.joined(separator: " ")) }
    }

    func поручение() throws -> ПоручениеПакета {
        func строка(_ аргументы: [String]) throws -> String {
            String(decoding: try гит(аргументы), as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        return try ПоручениеПакета(корневая_задача: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
            владелец: ProcessInfo.processInfo.environment["CODEX_THREAD_ID"]!,
            коммит: строка(["rev-parse", "HEAD"]), дерево: строка(["rev-parse", "HEAD^{tree}"]),
            ветка: строка(["symbolic-ref", "HEAD"]), время_свежести: "2026-10-26 04:31:22 MSK")
    }
}
