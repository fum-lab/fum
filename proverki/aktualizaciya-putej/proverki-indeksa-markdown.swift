import Foundation
import Testing
#if !ФУМ_АДРЕСНЫЙ_ТЕСТ
@testable import АктуализацияПутей
#endif

@Suite("Производный Markdown-индекс слияния")
struct ПроверкиИндексаMarkdown {
    let время = "2026-10-28 20:00:00 MSK"

    @Test("Полный состав, обратная сортировка, точная самоссылка")
    func составИПорядок() throws {
        let строки = [СтрокаИндексаMarkdown(путь: "а.md", время: время),
                      СтрокаИндексаMarkdown(путь: "я.md", время: время)]
        let байты = try ИндексMarkdownСлияния.построить(строки, время: время)
        let текст = String(decoding: байты, as: UTF8.self)
        #expect(текст.hasPrefix("# Markdown-файлы по времени редактирования\n"))
        #expect(текст.components(separatedBy: "[\(ИндексMarkdownСлияния.путь)](markdown-файлы-по-времени-редактирования.md)").count == 2)
        let я = try #require(текст.range(of: "[я.md](../я.md)"))
        let а = try #require(текст.range(of: "[а.md](../а.md)"))
        #expect(я.lowerBound < а.lowerBound)
        #expect(текст.hasSuffix("<!-- FUM-MD-RECENCY:END -->\n"))
    }

    @Test("Повтор на следующий день сохраняет байты и дату индекса")
    func идемпотентность() throws {
        let строки = [СтрокаИндексаMarkdown(путь: "заметка.md", время: время)]
        let первый = try ИндексMarkdownСлияния.построить(строки, время: время)
        #expect(!первый.isEmpty)
        let второй = try ИндексMarkdownСлияния.построить(строки,
            время: "2026-10-29 20:00:00 MSK", прежний: первый)
        #expect(первый == второй)
    }

    @Test("Выравнивание считает Unicode scalars, не graphemes")
    func ширинаТаблицы() throws {
        let строки = [СтрокаИндексаMarkdown(путь: "е\u{0301}.md", время: время),
                      СтрокаИндексаMarkdown(путь: "ёж.md", время: время)]
        let текст = String(decoding: try ИндексMarkdownСлияния.построить(строки, время: время), as: UTF8.self)
        let таблица = текст.split(separator: "\n").filter { $0.hasPrefix("| ") }
        #expect(таблица.count == 5)
        #expect(Set(таблица.map { $0.unicodeScalars.count }).count == 1)
    }

    @Test("Повторы и неправильные даты закрывают построение")
    func отказы() {
        let строка = СтрокаИндексаMarkdown(путь: "заметка.md", время: время)
        #expect(throws: ОтказИндексаMarkdown.self) {
            try ИндексMarkdownСлияния.построить([строка, строка], время: время)
        }
        #expect(throws: ОтказИндексаMarkdown.self) {
            try ИндексMarkdownСлияния.построить([СтрокаИндексаMarkdown(путь: "../снаружи.md", время: время)], время: время)
        }
        #expect(throws: ОтказИндексаMarkdown.self) {
            try ИндексMarkdownСлияния.построить([строка], время: "2026-02-30 10:00:00 MSK")
        }
    }

    @Test("Метка внутри незамкнутой ограды и повреждённый блок отвергаются")
    func оградыМетаданных() throws {
        let тело = "```\nдословное\n"
        let ложная = тело + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: \(время) -->\n<!-- content-sha256: sha256:\(ИндексMarkdownСлияния.хэш(Data(тело.utf8))) -->\n<!-- FUM-MD-RECENCY:END -->\n"
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.времяДокумента(Data(ложная.utf8), путь: "заметка.md")
        }
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.времяДокумента(Data("<!-- FUM-MD-RECENCY:BEGIN -->\n".utf8), путь: "заметка.md")
        }
        let архив = "# Архив\n\n## Диалог\n<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->\n```\nнезакрытая дословная ограда\n<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->\n"
        #expect(try ВосстановлениеИндексаMarkdown.времяДокумента(ФикстураИндексаMarkdown.документ(архив), путь: "Источники/URL/https/chatgpt.com/share/id/диалог.md") == время)
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.времяДокумента(ФикстураИндексаMarkdown.документ(архив), путь: "заметка.md")
        }
    }

    @Test("Полный Git-инвентарь, исключение проекции и адресный fallback")
    func полныйСоставИПробел() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        #expect(план.файлы.map(\.путь) == ["gap.md", "заметка.md"])
        #expect(план.общая_свежесть == "не-пройдена")
        #expect(String(decoding: план.результат, as: UTF8.self).contains("[gap.md](../gap.md)"))
        var неверный = фикстура.вход
        неверный.пробел.sha256 = String(repeating: "0", count: 64)
        #expect(throws: (any Error).self) { try ВосстановлениеИндексаMarkdown.построить(неверный) }
        try фикстура.сохранить("новый.md", ФикстураИндексаMarkdown.документ("новый\n"))
        let дополненный = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        #expect(дополненный.файлы.count == 3)
        try фикстура.сохранить("второй-пробел.md", Data("без метки\n".utf8))
        #expect(throws: (any Error).self) { try ВосстановлениеИндексаMarkdown.построить(фикстура.вход) }
    }

    @Test("Symlink и дрейф входов закрывают применение до записи индекса")
    func отказДоЗаписи() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        let до = try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь))
        try фикстура.сохранить("новый.md", ФикстураИндексаMarkdown.документ("новый\n"))
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: фикстура.квитанции)
        }
        #expect(try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь)) == до)
        try FileManager.default.removeItem(at: фикстура.адрес("новый.md"))
        try фикстура.сохранить("заметка.md", ФикстураИндексаMarkdown.документ("другие байты\n"))
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: фикстура.квитанции)
        }
        #expect(try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь)) == до)
        try FileManager.default.createSymbolicLink(at: фикстура.адрес("ссылка.md"), withDestinationURL: фикстура.адрес("заметка.md"))
        #expect(throws: (any Error).self) { try ВосстановлениеИндексаMarkdown.построить(фикстура.вход) }
    }

    @Test("Применение пишет только индекс, сохраняет MD, stages и привязку")
    func применениеИСохранность() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        let всеMD = try (план.файлы.map(\.путь) + ["Proyekcii/копия.md"]).map { ($0, try Data(contentsOf: фикстура.адрес($0))) }
        try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: фикстура.квитанции)
        #expect(try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь)) == план.результат)
        for (путь, байты) in всеMD { #expect(try Data(contentsOf: фикстура.адрес(путь)) == байты) }
        #expect(try ВосстановлениеИндексаMarkdown.гит(фикстура.корень.path, ["ls-files", "--stage", "-z"]) == план.стадии)
        #expect(FileManager.default.fileExists(atPath: фикстура.квитанции.appendingPathComponent("apply-outcome.json").path))
    }

    #if ФУМ_АДРЕСНЫЙ_ТЕСТ
    @Test("Остановка до rename доказывает no-effect и запрещает повтор прежнего intent")
    func остановкаДоЗамены() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        let планФайл = фикстура.квитанции.appendingPathComponent("plan.json")
        try ВосстановлениеИндексаMarkdown.кодировать(план).write(to: планФайл)
        let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        процесс.arguments = ["фикстура-стоп-до-rename", планФайл.path, фикстура.квитанции.path]
        процесс.standardOutput = FileHandle.nullDevice; процесс.standardError = FileHandle.nullDevice
        try процесс.run(); процесс.waitUntilExit()
        #expect(процесс.terminationReason == .exit && процесс.terminationStatus == 2)
        let исход = try ВосстановлениеИндексаMarkdown.кодировать(["pid": Int(процесс.processIdentifier), "status": Int(процесс.terminationStatus)])
        var исходОбъект = try #require(JSONSerialization.jsonObject(with: исход) as? [String: Any])
        исходОбъект["reason"] = "exit"
        let байтыИсхода = try JSONSerialization.data(withJSONObject: исходОбъект, options: [.prettyPrinted, .sortedKeys])
        try (байтыИсхода + Data([10])).write(to: фикстура.квитанции.appendingPathComponent("execution-outcome.json"))
        let целевой = try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь))
        #expect(ИндексMarkdownСлияния.хэш(целевой) == план.вход.конфликт_sha256)
        let итог = try Data(contentsOf: фикстура.квитанции.appendingPathComponent("terminal.json"))
        let объект = try #require(JSONSerialization.jsonObject(with: итог) as? [String: Any])
        #expect(объект["классификация"] as? String == "нет-целевого-эффекта")
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: фикстура.квитанции)
        }
        let староеНамерение = try Data(contentsOf: фикстура.квитанции.appendingPathComponent("apply-intent.json"))
        let разрешение = try фикстура.разрешениеРемонта(план, предыдущийПроцесс: процесс.processIdentifier)
        let новыйКаталог = фикстура.квитанции.deletingLastPathComponent().appendingPathComponent("repair")
        try FileManager.default.createDirectory(at: новыйКаталог, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        var подменаПроцесса = разрешение
        подменаПроцесса.предыдущий_исход_процесса_файл = "terminal.json"
        подменаПроцесса.предыдущий_исход_процесса_sha256 = ИндексMarkdownСлияния.хэш(итог)
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.ремонт(план, разрешение: подменаПроцесса, каталогКвитанции: новыйКаталог)
        }
        #expect(ИндексMarkdownСлияния.хэш(try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь))) == план.вход.конфликт_sha256)
        try ВосстановлениеИндексаMarkdown.ремонт(план, разрешение: разрешение, каталогКвитанции: новыйКаталог)
        #expect(try Data(contentsOf: фикстура.адрес(ИндексMarkdownСлияния.путь)) == план.результат)
        #expect(try Data(contentsOf: фикстура.квитанции.appendingPathComponent("apply-intent.json")) == староеНамерение)
        #expect(try Data(contentsOf: фикстура.квитанции.appendingPathComponent("terminal.json")) == итог)
        let новоеНамерение = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: новыйКаталог.appendingPathComponent("apply-intent.json"))) as? [String: Any])
        #expect(новоеНамерение["связь_ремонта_sha256"] as? String == ИндексMarkdownСлияния.хэш(try Data(contentsOf: новыйКаталог.appendingPathComponent("repair-link.json"))))
        let кодКорень = try #require(новоеНамерение["корень_кода"] as? String)
        let исходники = try #require(новоеНамерение["исходники_sha256"] as? [String: String])
        #expect(Set(исходники.keys) == Set(["indeks-markdown.swift", "vosstanovleniye-indeksa.swift", "kontrolj-vosstanovleniya.swift"].map { "iskhodniki/aktualizaciya-putej/" + $0 }))
        for (путь, хэш) in исходники { #expect(ИндексMarkdownСлияния.хэш(try ВосстановлениеИндексаMarkdown.прочитать(кодКорень, путь)) == хэш) }
        let фазы = try FileManager.default.contentsOfDirectory(at: новыйКаталог, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("полный-план-успех") }
        #expect(фазы.count == 3)
        for фаза in фазы {
            let объект = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: фаза)) as? [String: Any])
            #expect((объект["длительность_нс"] as? NSNumber)?.uint64Value ?? 0 > 0)
            #expect(объект["план_sha256"] as? String == разрешение.план_sha256)
        }
    }

    #endif

    @Test("Остановка с дрейфом исходника остаётся unknown")
    func неизвестныйИсходПриДрейфе() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        #expect(throws: (any Error).self) {
            try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: фикстура.квитанции, передЗаменой: {
                try фикстура.сохранить("заметка.md", ФикстураИндексаMarkdown.документ("дрейф\n"))
                throw ОтказИндексаMarkdown.вход("остановка-после-дрейфа")
            })
        }
        let итог = try Data(contentsOf: фикстура.квитанции.appendingPathComponent("terminal.json"))
        let объект = try #require(JSONSerialization.jsonObject(with: итог) as? [String: Any])
        #expect(объект["классификация"] as? String == "неизвестно")
    }

    #if ФУМ_АДРЕСНЫЙ_ТЕСТ
    @Test("Неблокирующий контроллер ограничивает живой дочерний процесс")
    func срокКонтроллера() async throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        let каталог = фикстура.квитанции
        let файлПлана = каталог.appendingPathComponent("plan.json")
        try ВосстановлениеИндексаMarkdown.кодировать(план).write(to: файлПлана)
        let исход = try await КонтроллерВосстановленияИндекса.выполнить(исполнитель: URL(fileURLWithPath: CommandLine.arguments[0]),
            аргументы: ["фикстура-зависнуть-до-rename", файлПлана.path, каталог.path], каталог: каталог, план: план, пределСекунд: 5)
        #expect(исход.предел_достигнут)
        #expect(исход.сигнал == 15 || исход.сигнал == 9)
        #expect(исход.длительность_нс < 7_000_000_000)
        #expect(исход.классификация == "нет-целевого-эффекта")
        #expect(try ВосстановлениеИндексаMarkdown.сверитьИсходноеСостояние(план))
        let фазы = try FileManager.default.contentsOfDirectory(atPath: каталог.path)
        #expect(фазы.contains { $0.contains("граница-до-rename-достигнута") })
        #expect(!фазы.contains { $0.contains("целевая-замена-начало") })
        #expect(FileManager.default.fileExists(atPath: каталог.appendingPathComponent("controller-outcome.json").path))
    }

    @Test("Ошибка post-timeout readback сохраняет durable unknown")
    func ошибкаСверкиКонтроллера() async throws {
        let фикстура = try ФикстураИндексаMarkdown()
        let план = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        let файлПлана = фикстура.квитанции.appendingPathComponent("plan.json")
        try ВосстановлениеИндексаMarkdown.кодировать(план).write(to: файлПлана)
        let исход = try await КонтроллерВосстановленияИндекса.выполнить(исполнитель: URL(fileURLWithPath: CommandLine.arguments[0]),
            аргументы: ["фикстура-ошибка-сверки-до-rename", файлПлана.path, фикстура.квитанции.path], каталог: фикстура.квитанции, план: план, пределСекунд: 5)
        #expect(исход.предел_достигнут && исход.классификация == "неизвестно")
        #expect(исход.ошибка_сверки != nil)
        #expect(FileManager.default.fileExists(atPath: фикстура.квитанции.appendingPathComponent("controller-outcome.json").path))
    }

    #endif

    @Test("Живой прежний PID закрывает новый effect")
    func живойПрежнийПроцесс() throws {
        let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: "/bin/sleep"); процесс.arguments = ["20"]
        try процесс.run(); defer { процесс.terminate(); процесс.waitUntilExit() }
        let пустое = РазрешениеРемонтаИндекса(допуск_файл: "", допуск_sha256: "", предыдущий_каталог: "", предыдущий_терминал_файл: "",
            предыдущий_терминал_sha256: "", предыдущий_намерение_sha256: "", предыдущий_исход_процесса_файл: "", предыдущий_исход_процесса_sha256: "",
            план_sha256: "", исполнитель_sha256: "", исходники_sha256: [:], предыдущий_процесс: процесс.processIdentifier,
            предыдущий_исполнитель: "/bin/sleep", предыдущий_исполнитель_sha256: ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: "/bin/sleep"))))
        #expect(throws: (any Error).self) { try ВосстановлениеИндексаMarkdown.сверитьОтсутствиеПроизводителя(пустое) }
    }

    @Test("Каждая привязка и происхождение fallback проверяются отдельно")
    func дрейфПривязок() throws {
        let фикстура = try ФикстураИндексаMarkdown()
        for номер in 0..<11 {
            var вход = фикстура.вход
            switch номер {
            case 0: вход.коммит = String(repeating: "0", count: 40)
            case 1: вход.ветка += "-другая"
            case 2: вход.слияние = String(repeating: "0", count: 40)
            case 3: вход.индекс_sha256 = "иной"
            case 4: вход.конфликт_sha256 = "иной"
            case 5: вход.пробел.родитель = "иной"
            case 6: вход.пробел.объект = "иной"
            case 7: вход.пробел.коммит = "иной"
            case 8: вход.пробел.дата = "2020-01-01T00:00:00Z"
            case 9: вход.пробел.путь = "заметка.md"
            default: вход.пробел.sha256 = "иной"
            }
            #expect(throws: (any Error).self) { try ВосстановлениеИндексаMarkdown.построить(вход) }
        }
        let первый = try ВосстановлениеИндексаMarkdown.построить(фикстура.вход)
        #expect(try ВосстановлениеИндексаMarkdown.построить(фикстура.вход) == первый)
    }

    @Test("Полный адресный корпус 5002 MD остаётся побайтно неизменным",
          .enabled(if: ProcessInfo.processInfo.environment["ФУМ_ВХОД_ИНДЕКСА"] != nil))
    func адресныйКорпус() throws {
        let путь = try #require(ProcessInfo.processInfo.environment["ФУМ_ВХОД_ИНДЕКСА"])
        let вход = try JSONDecoder().decode(ВходВосстановленияИндекса.self, from: Data(contentsOf: URL(fileURLWithPath: путь)))
        let до = try ВосстановлениеИндексаMarkdown.гит(вход.корень, ["status", "--porcelain=v1", "-z", "--untracked-files=all"])
        let пути = try ВосстановлениеИндексаMarkdown.инвентарь(вход.корень)
        let хэшиДо = try пути.map { try ИндексMarkdownСлияния.хэш(ВосстановлениеИндексаMarkdown.прочитать(вход.корень, $0)) }
        let первый = try ВосстановлениеИндексаMarkdown.построить(вход)
        #expect(первый.файлы.count + 1 == 5002)
        #expect(Set(первый.файлы.map { Data($0.путь.utf8) }).count == 5001)
        #expect(первый.файлы.allSatisfy { !$0.путь.hasPrefix("Proyekcii/") })
        #expect(первый.общая_свежесть == "не-пройдена")
        #expect(try ВосстановлениеИндексаMarkdown.построить(вход) == первый)
        #expect(try пути.map { try ИндексMarkdownСлияния.хэш(ВосстановлениеИндексаMarkdown.прочитать(вход.корень, $0)) } == хэшиДо)
        #expect(try ВосстановлениеИндексаMarkdown.гит(вход.корень, ["status", "--porcelain=v1", "-z", "--untracked-files=all"]) == до)
    }
}

final class ФикстураИндексаMarkdown {
    let корень: URL
    let квитанции: URL
    var вход: ВходВосстановленияИндекса

    static func документ(_ тело: String) -> Data {
        Data((тело + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: 2026-10-28 20:00:00 MSK -->\n<!-- content-sha256: sha256:\(ИндексMarkdownСлияния.хэш(Data(тело.utf8))) -->\n<!-- FUM-MD-RECENCY:END -->\n").utf8)
    }

    func адрес(_ путь: String) -> URL { корень.appendingPathComponent(путь) }
    func сохранить(_ путь: String, _ байты: Data) throws {
        let файл = адрес(путь)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try байты.write(to: файл)
    }

    func разрешениеРемонта(_ план: ПланВосстановленияИндекса, предыдущийПроцесс: Int32) throws -> РазрешениеРемонтаИндекса {
        let допускФайл = квитанции.deletingLastPathComponent().appendingPathComponent("root-authority.json")
        let байты = try ВосстановлениеИндексаMarkdown.кодировать(["разрешено_новых_производственных_попыток": 1])
        try байты.write(to: допускФайл, options: .withoutOverwriting)
        let код = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        var исходники: [String: String] = [:]
        for имя in ["indeks-markdown.swift", "vosstanovleniye-indeksa.swift", "kontrolj-vosstanovleniya.swift"] {
            let путь = "code/" + имя
            let данные = try Data(contentsOf: код.appendingPathComponent("iskhodniki/aktualizaciya-putej/" + имя))
            try сохранить(путь, данные); исходники[путь] = ИндексMarkdownСлияния.хэш(данные)
        }
        let терминал = try Data(contentsOf: квитанции.appendingPathComponent("terminal.json"))
        let процесс = try Data(contentsOf: квитанции.appendingPathComponent("execution-outcome.json"))
        return РазрешениеРемонтаИндекса(допуск_файл: допускФайл.path, допуск_sha256: ИндексMarkdownСлияния.хэш(байты),
            предыдущий_каталог: квитанции.path, предыдущий_терминал_файл: "terminal.json",
            предыдущий_терминал_sha256: ИндексMarkdownСлияния.хэш(терминал),
            предыдущий_намерение_sha256: ИндексMarkdownСлияния.хэш(try Data(contentsOf: квитанции.appendingPathComponent("apply-intent.json"))),
            предыдущий_исход_процесса_файл: "execution-outcome.json", предыдущий_исход_процесса_sha256: ИндексMarkdownСлияния.хэш(процесс),
            план_sha256: ИндексMarkdownСлияния.хэш(try ВосстановлениеИндексаMarkdown.кодировать(план)),
            исполнитель_sha256: ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[0]))),
            исходники_sha256: исходники, предыдущий_процесс: предыдущийПроцесс,
            предыдущий_исполнитель: CommandLine.arguments[0],
            предыдущий_исполнитель_sha256: ИндексMarkdownСлияния.хэш(try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[0]))))
    }

    init() throws {
        let основа = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("fum-index-test-" + UUID().uuidString)
        корень = основа.appendingPathComponent("repo")
        квитанции = основа.appendingPathComponent("receipts")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: квитанции, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        вход = .init(корень: корень.path, ветка: "refs/heads/left", коммит: "", слияние: "", индекс_sha256: "", конфликт_sha256: "", время: "2026-10-28 20:00:00 MSK", пробел: .init(путь: "gap.md", родитель: "", объект: "", sha256: "", коммит: "", дата: ""))
        func гит(_ аргументы: [String], код: Int32 = 0) throws -> Data {
            let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            процесс.arguments = ["-C", корень.path, "-c", "user.name=Фикстура", "-c", "user.email=fixture@invalid", "-c", "commit.gpgsign=false"] + аргументы
            let канал = Pipe(); процесс.standardOutput = канал; процесс.standardError = FileHandle.nullDevice
            try процесс.run(); let данные = канал.fileHandleForReading.readDataToEndOfFile(); процесс.waitUntilExit()
            guard процесс.terminationStatus == код else { throw ОтказИндексаMarkdown.вход("фикстурный-Git") }; return данные
        }
        _ = try гит(["init", "-b", "left"])
        try сохранить("заметка.md", Self.документ("Заметка\n"))
        try сохранить("gap.md", Data("Исторический исходник без метки\n".utf8))
        try сохранить("Proyekcii/копия.md", Data("производная копия без метки\n".utf8))
        try сохранить(".build/кэш.md", Data("кэш без метки\n".utf8))
        try сохранить(".gitignore", Data(".build/\n".utf8))
        try сохранить(ИндексMarkdownСлияния.путь, Data("base\n".utf8))
        _ = try гит(["add", "."]); _ = try гит(["commit", "-m", "основа"])
        _ = try гит(["branch", "right"])
        try сохранить(ИндексMarkdownСлияния.путь, Data("left\n".utf8))
        _ = try гит(["commit", "-am", "левый"])
        _ = try гит(["checkout", "right"])
        try сохранить(ИндексMarkdownСлияния.путь, Data("right\n".utf8))
        _ = try гит(["commit", "-am", "правый"])
        _ = try гит(["checkout", "left"])
        _ = try гит(["merge", "--no-ff", "--no-commit", "right"], код: 1)
        вход.коммит = try ВосстановлениеИндексаMarkdown.строкаГит(корень.path, ["rev-parse", "HEAD"])
        вход.слияние = try ВосстановлениеИндексаMarkdown.строкаГит(корень.path, ["rev-parse", "MERGE_HEAD"])
        вход.индекс_sha256 = ИндексMarkdownСлияния.хэш(try ВосстановлениеИндексаMarkdown.гит(корень.path, ["ls-files", "--stage", "-z"]))
        вход.конфликт_sha256 = ИндексMarkdownСлияния.хэш(try Data(contentsOf: адрес(ИндексMarkdownСлияния.путь)))
        вход.пробел.родитель = вход.слияние
        вход.пробел.объект = try ВосстановлениеИндексаMarkdown.строкаГит(корень.path, ["rev-parse", вход.слияние + ":gap.md"])
        вход.пробел.sha256 = ИндексMarkdownСлияния.хэш(try Data(contentsOf: адрес("gap.md")))
        вход.пробел.коммит = try ВосстановлениеИндексаMarkdown.строкаГит(корень.path, ["log", "-1", "--format=%H", вход.слияние, "--", "gap.md"])
        вход.пробел.дата = try ВосстановлениеИндексаMarkdown.строкаГит(корень.path, ["log", "-1", "--format=%cI", вход.слияние, "--", "gap.md"])
    }
}

#if ФУМ_АДРЕСНЫЙ_ТЕСТ
@main
struct ЗапускПроверокИндексаMarkdown {
    static func main() async {
        if CommandLine.arguments.count == 4, ["фикстура-стоп-до-rename", "фикстура-зависнуть-до-rename", "фикстура-ошибка-сверки-до-rename"].contains(CommandLine.arguments[1]) {
            do {
                let план = try JSONDecoder().decode(ПланВосстановленияИндекса.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
                try ВосстановлениеИндексаMarkdown.применить(план, каталогКвитанции: URL(fileURLWithPath: CommandLine.arguments[3]),
                    передЗаменой: {
                        if CommandLine.arguments[1] == "фикстура-стоп-до-rename" { throw ОтказИндексаMarkdown.вход("контрольная-остановка") }
                        if CommandLine.arguments[1] == "фикстура-ошибка-сверки-до-rename" { try FileManager.default.removeItem(at: URL(fileURLWithPath: план.вход.корень).appendingPathComponent("заметка.md")) }
                        _ = raise(SIGSTOP)
                    })
                exit(0)
            } catch { exit(2) }
        }
        let код: CInt = await Testing.__swiftPMEntryPoint()
        exit(код)
    }
}
#endif
