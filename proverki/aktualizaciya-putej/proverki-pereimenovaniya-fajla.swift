import Foundation
import Darwin
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

// Открытая конечная Git-фикстура; расположение задаёт запускающая сторона.
@Test func однофайловыйПланЧерезСуществующуюКоманду() async throws {
    let адрес = try #require(ProcessInfo.processInfo.environment["ФУМ_ФИКСТУРА_ПЕРЕИМЕНОВАНИЯ"])
    let корень = URL(fileURLWithPath: адрес)
    let прежде = try Data(contentsOf: корень.appendingPathComponent("index.md"))
    let результат = try await КомандаПутей.выполнить([
        "план-файла", "--repo-root", адрес,
        "--source", "docs/old.md", "--destination", "docs/new.md"
    ])
    let план = try #require(JSONSerialization.jsonObject(with: результат) as? [String: Any])
    #expect(план["updated_links"] as? Int == 1)
    #expect(план["destination"] as? String == "docs/new.md")
    #expect(try Data(contentsOf: корень.appendingPathComponent("index.md")) == прежде)
    #expect(FileManager.default.fileExists(atPath: корень.appendingPathComponent("docs/old.md").path))
    #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("docs/new.md").path))
}

private final class ФикстураПереименования {
    let корень: URL
    init(_ файлы: [String: Data] = [:], толькоЗаданные: Bool = false) throws {
        let созданный = FileManager.default.temporaryDirectory.appendingPathComponent("fum-single-file-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: созданный, withIntermediateDirectories: true)
        корень = созданный.resolvingSymlinksInPath().standardizedFileURL
        let стандартные = толькоЗаданные ? [:] : ["docs/old.md": "# Старый\n", "index.md": "[Ссылка](docs/old.md)\n", "archive/.keep": "", "foreign.txt": "принято\n"]
        for (путь, текст) in стандартные {
            try записать(путь, Data(текст.utf8))
        }
        for (путь, байты) in файлы { try записать(путь, байты) }
        _ = try гит(["init", "-q"])
        try коммит()
    }
    deinit { try? FileManager.default.removeItem(at: корень) }
    func записать(_ путь: String, _ байты: Data) throws {
        // URL-based Foundation write на macOS создаёт NFD-компоненты.
        // Открытая fixture должна сохранять заданные UTF8 имена, как git checkout.
        var каталог = корень.path
        for часть in путь.split(separator: "/").dropLast() {
            каталог += "/" + часть
            guard mkdir(каталог, 0o700) == 0 || errno == EEXIST else { throw ОшибкаПутей.отказ("Не создан родитель fixture") }
        }
        let дескриптор = open(корень.path + "/" + путь, O_WRONLY | O_CREAT | O_TRUNC | O_NOFOLLOW, 0o644)
        guard дескриптор >= 0 else { throw ОшибкаПутей.отказ("Не открыта fixture") }
        defer { close(дескриптор) }
        try байты.withUnsafeBytes { буфер in
            var смещение = 0
            while смещение < буфер.count {
                let число = Darwin.write(дескриптор, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
                guard число > 0 else { throw ОшибкаПутей.отказ("Не записана fixture") }
                смещение += число
            }
        }
    }
    func читать(_ путь: String) throws -> Data { try Data(contentsOf: корень.appendingPathComponent(путь)) }
    @discardableResult func гит(_ аргументы: [String]) throws -> Data { try ПереименованиеФайла.гит(корень, аргументы) }
    func коммит() throws {
        try гит(["add", "--", "."])
        try гит(["-c", "user.name=FUM Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "Открытая конечная фикстура"])
    }
    func план(_ исходный: String = "docs/old.md", _ целевой: String = "archive/new.md") throws -> ПланПереименованияФайла {
        try ПереименованиеФайла.построить(корень: корень, исходный: исходный, целевой: целевой)
    }
    func подпись() throws -> Data {
        let индекс = URL(fileURLWithPath: String(decoding: try гит(["rev-parse", "--path-format=absolute", "--git-path", "index"]), as: UTF8.self).trimmingCharacters(in: .newlines))
        return try гит(["rev-parse", "HEAD"]) + гит(["ls-files", "--stage", "-z"]) + Data(contentsOf: индекс)
            + гит(["status", "--porcelain=v1", "-z", "--untracked-files=all"])
    }
}

private func ожидатьОтказ<Значение>(_ причина: String, _ действие: () throws -> Значение) {
    do { _ = try действие(); Issue.record("Ожидался предметный отказ: \(причина)") }
    catch { #expect(String(describing: error).contains(причина)) }
}

@Test func точныеЦелиВсеФормыИДетерминированныйПлан() throws {
    let текст = """
    [inline](docs/old.md?view=1#top "Title")
    ![image](docs/old.md)
    [angle](<docs/old.md> 'Title')
    [percent](docs/%6Fld.md#part)
    [multiline](
      docs/old.md#top
      "Title"
    )
    [ref][id]
    [id]:
      docs/old.md#ref
    > [quoted]: docs/old.md#quote
    - [listed]: docs/old.md#list
    [other](other/old.md)
    """
    let фикстура = try ФикстураПереименования(["index.md": Data(текст.utf8), "other/old.md": Data("# Другой\n".utf8)])
    let до = try фикстура.подпись(), исходник = try фикстура.читать("index.md")
    let план = try фикстура.план("docs/old.md", "archive/new file.md")
    #expect(try план.представление("plan") == фикстура.план("docs/old.md", "archive/new file.md").представление("plan"))
    #expect(план.правки.reduce(0) { $0 + $1.числоСсылок } == 8)
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == исходник)
    try ПереименованиеФайла.применить(план)
    let после = String(decoding: try фикстура.читать("index.md"), as: UTF8.self)
    #expect(после.contains("archive/new%20file.md?view=1#top \"Title\""))
    #expect(после.contains("<archive/new file.md>"))
    #expect(после.contains("> [quoted]: archive/new%20file.md#quote"))
    #expect(после.contains("- [listed]: archive/new%20file.md#list"))
    #expect(после.contains("[other](other/old.md)"))
}

@Test func исходящиеНаСебяИЧистыйФрагмент() throws {
    let фикстура = try ФикстураПереименования([
        "docs/old.md": Data("[other](target.md)\n[self](old.md#self)\n[fragment](#part)\n![image](image.png)\n".utf8),
        "docs/target.md": Data("# Цель\n".utf8), "docs/image.png": Data([1, 2, 3])])
    try ПереименованиеФайла.применить(фикстура.план())
    #expect(String(decoding: try фикстура.читать("archive/new.md"), as: UTF8.self) ==
        "[other](../docs/target.md)\n[self](new.md#self)\n[fragment](#part)\n![image](../docs/image.png)\n")
}

@Test func прозаКодКонтейнерыИНесвязанныеВикиСохранены() throws {
    let неизменяемое = """
    docs/old.md — обычная проза
    [external](https://example.invalid/docs/old.md)
    `[inline code](docs/old.md)`
        [indented code](docs/old.md)
    ```markdown
    [code](docs/old.md)
    ```
    > ```markdown
    > [quoted code](docs/old.md)
    > ```
    - ```markdown
      [listed code](docs/old.md)
      ```
    <!-- [comment](docs/old.md) -->
    [[other/old]] [[unrelated]]
    """
    let фикстура = try ФикстураПереименования(["index.md": Data(("[live](docs/old.md)\n" + неизменяемое).utf8)])
    let план = try фикстура.план()
    #expect(план.правки.reduce(0) { $0 + $1.числоСсылок } == 1)
    try ПереименованиеФайла.применить(план)
    #expect(String(decoding: try фикстура.читать("index.md"), as: UTF8.self) == "[live](archive/new.md)\n" + неизменяемое)
}

@Test(arguments: ["[[old]]", "[[docs/old.md#part|Метка]]", "[[docs/%6Fld]]"])
func значимыеВикиБлокируют(_ ссылка: String) throws {
    let фикстура = try ФикстураПереименования(["index.md": Data(ссылка.utf8)])
    let до = try фикстура.подпись()
    ожидатьОтказ("wiki-ссылка-на-переносимый-файл") { try фикстура.план() }
    #expect(try фикстура.подпись() == до)
}

@Test(arguments: [false, true]) func сырыеИПерекрёстныеДословныеСсылкиБлокируют(_ ссылкаЧерезОпределение: Bool) throws {
    let путь = ссылкаЧерезОпределение ? "Журнал/2026-10-29_12-00-00_MSK_fixture/запрос.md" : "Источники/raw.md"
    let текст = ссылкаЧерезОпределение
        ? "# Запрос\n\n## Текст запроса\n\n[use][id]\n\n## Производное\n\n[id]: ../../docs/old.md\n"
        : "[live](../docs/old.md)\n"
    let фикстура = try ФикстураПереименования([путь: Data(текст.utf8)])
    let до = try фикстура.подпись()
    ожидатьОтказ("защищённая-живая-ссылка") { try фикстура.план() }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать(путь) == Data(текст.utf8))
}

@Test func точнаяДословнаяЗонаИНеканоническийЖурналРазличаются() throws {
    let путь = "Журнал/2026-10-29_12-00-00_MSK_fixture/запрос.md"
    let фикстура = try ФикстураПереименования([путь: Data("## Текст запроса\n[live](../../docs/old.md)\n".utf8)])
    ожидатьОтказ("защищённая-живая-ссылка") { try фикстура.план() }
    try фикстура.записать(путь, Data("## Текст запроса\n`[code](../../docs/old.md)`\n## Производное\n[derived](../../docs/old.md)\n".utf8))
    try фикстура.записать("Журнал/not-session/запрос.md", Data("## Текст запроса\n[derived](../../docs/old.md)\n".utf8))
    try ПереименованиеФайла.применить(фикстура.план())
    #expect(String(decoding: try фикстура.читать(путь), as: UTF8.self).contains("`[code](../../docs/old.md)`"))
    #expect(String(decoding: try фикстура.читать("Журнал/not-session/запрос.md"), as: UTF8.self).contains("../../archive/new.md"))
}

@Test(arguments: ["docs/OLD.md", "missing/new.md", "../outside.md", "/absolute.md", "docs//new.md", "docs/./new.md", "Источники/new.md", "Планирование/карточки-шагов/new.md"])
func опасныеНазначенияОтвергнуты(_ назначение: String) throws {
    let фикстура = try ФикстураПереименования()
    let причина: String
    if назначение == "docs/OLD.md" { причина = "case/NFC-only" }
    else if назначение == "missing/new.md" { причина = "регистр/NFC пути" }
    else if назначение.hasPrefix("Источники/") || назначение.hasPrefix("Планирование/") { причина = "Защищённый или доменный" }
    else { причина = "Небезопасный относительный путь" }
    ожидатьОтказ(причина) { try фикстура.план("docs/old.md", назначение) }
}

@Test func коллизииРегистраНормализацииИАлиасыОтвергнуты() throws {
    let фикстура = try ФикстураПереименования(["archive/New.md": Data("занято".utf8), "archive/é.md": Data("NFC".utf8)])
    ожидатьОтказ("Назначение занято") { try фикстура.план("docs/old.md", "archive/new.md") }
    ожидатьОтказ("Назначение занято") { try фикстура.план("docs/old.md", "archive/e\u{301}.md") }
    ожидатьОтказ("регистр/NFC пути") { try фикстура.план("docs/Old.md", "archive/other.md") }
    let алиасная = try ФикстураПереименования()
    try FileManager.default.createSymbolicLink(atPath: алиасная.корень.appendingPathComponent("alias").path, withDestinationPath: "docs")
    ожидатьОтказ("Символический") { try алиасная.план("docs/old.md", "alias/new.md") }
    try алиасная.записать("index.md", Data("[alias](alias/old.md)\n".utf8))
    ожидатьОтказ("входящая-case-NFC-symlink") { try алиасная.план("docs/old.md", "archive/other.md") }
}

@Test(arguments: ["missing.md", "Old.md", "%QQ.md", "%2Foutside.md", "%2e%2e/outside.md", "file:///tmp/outside.md", "/outside.md", "../../../outside.md", "bad%FF.md"])
func недоказуемыеИсходящиеОтвергнуты(_ адрес: String) throws {
    let фикстура = try ФикстураПереименования(["docs/old.md": Data("[link](\(адрес))\n".utf8)])
    let причины = ["%QQ.md": "неверное-percent", "%2Foutside.md": "закодированный-разделитель", "%2e%2e/outside.md": "закодированный-точечный",
        "file:///tmp/outside.md": "абсолютный-file", "/outside.md": "абсолютный-или", "../../../outside.md": "выход-за-корень", "bad%FF.md": "неверный-UTF8"]
    ожидатьОтказ(причины[адрес] ?? "сломанная-исходящая") { try фикстура.план() }
}

@Test func невернаяКодировкаИГрязныйИсточник() throws {
    let фикстура = try ФикстураПереименования(["bad.md": Data([0xFF])])
    ожидатьОтказ("не-UTF8-Markdown") { try фикстура.план() }
    try FileManager.default.removeItem(at: фикстура.корень.appendingPathComponent("bad.md"))
    try фикстура.записать("docs/old.md", Data("грязный".utf8))
    ожидатьОтказ("Источник грязный") { try фикстура.план() }
    ожидатьОтказ("обычным файлом") { try фикстура.план("docs", "archive/new.md") }
    try фикстура.записать("payload.bin", Data([0, 1, 2, 255])); try фикстура.коммит()
    try ПереименованиеФайла.применить(фикстура.план("payload.bin", "archive/payload.bin"))
    #expect(try фикстура.читать("archive/payload.bin") == Data([0, 1, 2, 255]))
}

@Test(arguments: ["source", "mode", "HEAD", "index", "raw-index", "inventory", "parent"])
func поздниеБарьерыОстанавливаютДоПереноса(_ вид: String) throws {
    let фикстура = try ФикстураПереименования(), план = try фикстура.план()
    switch вид {
    case "source": try фикстура.записать("docs/old.md", Data("дрейф".utf8))
    case "mode": #expect(chmod(фикстура.корень.appendingPathComponent("docs/old.md").path, 0o755) == 0)
    case "HEAD": try фикстура.гит(["-c", "user.name=FUM Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-qm", "Дрейф"])
    case "index": try фикстура.записать("foreign.txt", Data("staged".utf8)); try фикстура.гит(["add", "--", "foreign.txt"])
    case "raw-index": var байты = план.индекс; байты[байты.count - 1] ^= 1; try байты.write(to: план.адресИндекса)
    case "inventory": try фикстура.записать("extra.md", Data("# Новый\n".utf8))
    default:
        try FileManager.default.moveItem(at: фикстура.корень.appendingPathComponent("archive"), to: фикстура.корень.appendingPathComponent("kept"))
        try FileManager.default.createDirectory(at: фикстура.корень.appendingPathComponent("archive"), withIntermediateDirectories: false)
    }
    let причины = ["source": "Дрейф файла", "mode": "Дрейф файла", "HEAD": "Дрейф HEAD", "index": "Дрейф точных байтов", "raw-index": "Дрейф точных байтов", "inventory": "Дрейф Markdown-инвентаря", "parent": "Дрейф identity родителя"]
    ожидатьОтказ(try #require(причины[вид])) { try ПереименованиеФайла.применить(план) }
    #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent("docs/old.md").path))
    #expect(!FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent("archive/new.md").path))
}

@Test func профильТрёхОдинаковыхКонечныхФикстур() throws {
    func наносекунды(_ начало: ContinuousClock.Instant) -> Int64 {
        let части = начало.duration(to: .now).components
        return части.seconds * 1_000_000_000 + части.attoseconds / 1_000_000_000
    }
    var наблюдения: [[String: Any]] = []
    for _ in 0..<3 {
        let начало = ContinuousClock.now, фикстура = try ФикстураПереименования()
        let подготовка = наносекунды(начало), началоПлана = ContinuousClock.now
        let план = try фикстура.план(), построение = наносекунды(началоПлана)
        let началоПрименения = ContinuousClock.now
        try ПереименованиеФайла.применить(план)
        let применение = наносекунды(началоПрименения)
        #expect(try фикстура.читать("index.md") == Data("[Ссылка](archive/new.md)\n".utf8))
        наблюдения.append(["подготовка_нс": подготовка, "план_нс": построение, "применение_нс": применение,
            "вход_sha256": хэшПутей(Data("# Старый\n[Ссылка](docs/old.md)\n".utf8))])
    }
    if let адрес = ProcessInfo.processInfo.environment["ФУМ_ПРОФИЛЬ_ПЕРЕИМЕНОВАНИЯ"] {
        try (JSONSerialization.data(withJSONObject: наблюдения, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) + Data([10])).write(to: URL(fileURLWithPath: адрес), options: .withoutOverwriting)
    }
}

@Test func времяИндексаНеВходитВДетерминированныйПлан() throws {
    let фикстура = try ФикстураПереименования(), первый = try фикстура.план()
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: первый.адресИндекса.path)
    #expect(try первый.представление("plan") == фикстура.план().представление("plan"))
    try ПереименованиеФайла.сверить(первый)
}

@Test func откатВторойУстановкиСохраняетПереносыСтрокРежимИЧужуюГрязь() throws {
    let исходник = Data("[target](target.md)\r\n".utf8)
    let фикстура = try ФикстураПереименования(["docs/old.md": исходник, "docs/target.md": Data("# Цель\n".utf8)])
    #expect(chmod(фикстура.корень.appendingPathComponent("docs/old.md").path, 0o755) == 0)
    try фикстура.коммит()
    try фикстура.записать("foreign.txt", Data("staged".utf8)); try фикстура.гит(["add", "--", "foreign.txt"])
    try фикстура.записать("foreign.txt", Data("unstaged".utf8))
    let план = try фикстура.план(), до = try фикстура.подпись()
    #expect(план.правки.count == 2)
    do {
        try ПереименованиеФайла.применить(план, передУстановкой: { if $0 == 2 { throw ОшибкаПутей.отказ("Внедрённый отказ второй установки") } })
        Issue.record("Ожидался отказ")
    } catch { #expect(String(describing: error).contains("откат проверен")) }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("docs/old.md") == исходник)
    #expect(try фикстура.читать("foreign.txt") == Data("unstaged".utf8))
    #expect(try СостояниеФайлаПереименования(фикстура.корень.appendingPathComponent("docs/old.md")).режим & 0o777 == 0o755)
}

@Test func неполныйОткатСохраняетРезервИГоворитОбОтказе() throws {
    let фикстура = try ФикстураПереименования(["docs/old.md": Data("[target](target.md)\n".utf8), "docs/target.md": Data("# Цель\n".utf8)])
    do {
        try ПереименованиеФайла.применить(фикстура.план(), передУстановкой: { if $0 == 2 { throw ОшибкаПутей.отказ("install") } }, передВосстановлением: { _ in throw ОшибкаПутей.отказ("restore") })
        Issue.record("Ожидался неполный откат")
    } catch { #expect(String(describing: error).contains("Неполный откат")); #expect(String(describing: error).contains("Резервная копия сохранена")) }
    let перечислитель = try #require(FileManager.default.enumerator(at: фикстура.корень, includingPropertiesForKeys: nil))
    #expect(перечислитель.allObjects.compactMap { $0 as? URL }.contains { $0.lastPathComponent.hasPrefix(".fum-rename-backup-") })
}

@Test func повторПараметраНеРазрешаетДваПереноса() async throws {
    let фикстура = try ФикстураПереименования()
    await #expect(throws: (any Error).self) {
        try await КомандаПутей.выполнить(["план-файла", "--repo-root", фикстура.корень.path, "--source", "docs/old.md", "--source", "index.md", "--destination", "archive/new.md"])
    }
}

@Test func вложеннаяКартинкаВПодписиНеПропускаетсяМолча() throws {
    let фикстура = try ФикстураПереименования(["index.md": Data("[![badge](docs/old.md)](https://example.invalid)\n".utf8)])
    let до = try фикстура.подпись()
    ожидатьОтказ("one-file-вложенная-подпись") { try фикстура.план() }
    #expect(try фикстура.подпись() == до)
}

@Test func кодВЗащищённойПодписиНеСкрываетИспользованиеСсылкиПоМетке() throws {
    let путь = "Журнал/2026-10-29_12-00-00_MSK_fixture/запрос.md"
    let текст = "## Текст запроса\n[use `code`][id]\n## Производное\n[id]: ../../docs/old.md\n"
    let фикстура = try ФикстураПереименования([путь: Data(текст.utf8)])
    let до = try фикстура.подпись()
    ожидатьОтказ("защищённая-живая-ссылка") { try фикстура.план() }
    #expect(try фикстура.читать(путь) == Data(текст.utf8))
    #expect(try фикстура.подпись() == до)
}

@Test func кодВоВстроеннойПодписиНеПропускаетЖивуюСсылку() throws {
    let фикстура = try ФикстураПереименования(["index.md": Data("[see `code`](docs/old.md)\n".utf8)])
    ожидатьОтказ("one-file-код-в-подписи") { try фикстура.план() }
}

@Test func защищённаяВложеннаяПодписьСсылкиПоМеткеБлокируется() throws {
    let путь = "Журнал/2026-10-29_12-00-00_MSK_fixture/запрос.md"
    let текст = "## Текст запроса\n[![badge][id]](https://example.invalid)\n## Производное\n[id]: ../../docs/old.md\n"
    let фикстура = try ФикстураПереименования([путь: Data(текст.utf8)])
    ожидатьОтказ("one-file-вложенная-подпись") { try фикстура.план() }
    #expect(try фикстура.читать(путь) == Data(текст.utf8))
}

@Test(arguments: [false, true]) func неизвестныйИсходПереносаСохраняетИндексИНамерение(_ толькоИндекс: Bool) throws {
    let фикстура = try ФикстураПереименования(), план = try фикстура.план()
    ожидатьОтказ("UNKNOWN: неподтверждённый эффект git mv") {
        try ПереименованиеФайла.применить(план, переносДляПроверки: {
            if толькоИндекс {
                try фикстура.записать("foreign.txt", Data("частичная запись индекса".utf8))
                try фикстура.гит(["add", "--", "foreign.txt"])
            } else { try фикстура.гит(["mv", "--", "docs/old.md", "archive/new.md"]) }
            throw ОшибкаПутей.отказ("Внедрена потеря подтверждения реального эффекта")
        })
    }
    let имена = try FileManager.default.contentsOfDirectory(atPath: фикстура.корень.path)
    let резерв = try #require(имена.first { $0.hasPrefix(".fum-rename-index-") })
    #expect(try фикстура.читать(резерв) == план.индекс)
    #expect(имена.contains { $0.hasPrefix(".fum-rename-intent-") })
    #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent("docs/old.md").path) == толькоИндекс)
    #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent("archive/new.md").path) == !толькоИндекс)
    #expect(try Data(contentsOf: план.адресИндекса) != план.индекс)
}

@Test(arguments: [false, true]) func типИРежимИндексаПроверяютсяБезСледованияСсылке(_ символический: Bool) throws {
    let фикстура = try ФикстураПереименования(), первый = try фикстура.план()
    try фикстура.записать("saved-index.bin", первый.индекс)
    let план = try фикстура.план()
    if символический {
        try FileManager.default.removeItem(at: план.адресИндекса)
        try FileManager.default.createSymbolicLink(at: план.адресИндекса, withDestinationURL: фикстура.корень.appendingPathComponent("saved-index.bin"))
    } else { #expect(chmod(план.адресИндекса.path, план.режимИндекса ^ 0o044) == 0) }
    ожидатьОтказ("Дрейф типа или режима индекса") { try ПереименованиеФайла.сверить(план, статус: false) }
}

@Test func неуспешнаяСверкаОткатаНеУничтожаетРезервы() throws {
    let фикстура = try ФикстураПереименования(["docs/old.md": Data("[target](target.md)\n".utf8), "docs/target.md": Data("# Цель\n".utf8), "other.md": Data("# Независимый\n".utf8)])
    let план = try фикстура.план()
    ожидатьОтказ("Неполный откат") {
        try ПереименованиеФайла.применить(план,
            передУстановкой: { if $0 == 2 { throw ОшибкаПутей.отказ("install") } },
            передВосстановлением: { _ in try фикстура.записать("other.md", Data("Наблюдаемый внешний дрейф\n".utf8)) })
    }
    let перечислитель = try #require(FileManager.default.enumerator(at: фикстура.корень, includingPropertiesForKeys: nil))
    let резервы = перечислитель.allObjects.compactMap { $0 as? URL }.filter { $0.lastPathComponent.hasPrefix(".fum-rename-backup-") }
    #expect(резервы.count == 2)
    #expect(try Data(contentsOf: план.адресИндекса) == план.индекс)
    #expect(try фикстура.читать("other.md") == Data("Наблюдаемый внешний дрейф\n".utf8))
}

@Test func бюджетыПроверяютсяДоОткрытияНечитаемогоФайла() throws {
    let большой = try ФикстураПереименования(["docs/old.md": Data(repeating: 65, count: 256)])
    let адрес = большой.корень.appendingPathComponent("docs/old.md")
    #expect(chmod(адрес.path, 0) == 0)
    defer { _ = chmod(адрес.path, 0o644) }
    ожидатьОтказ("Превышен предел чтения до загрузки байтов") {
        try ПереименованиеФайла.построить(корень: большой.корень, исходный: "docs/old.md", целевой: "archive/new.md", пределФайла: 128)
    }
    let суммарный = try ФикстураПереименования(["a.md": Data(repeating: 65, count: 64)])
    let второй = суммарный.корень.appendingPathComponent("a.md")
    #expect(chmod(второй.path, 0) == 0)
    defer { _ = chmod(второй.path, 0o644) }
    ожидатьОтказ("Превышен предел чтения до загрузки байтов") {
        try ПереименованиеФайла.построить(корень: суммарный.корень, исходный: "docs/old.md", целевой: "archive/new.md", пределФайла: 128, пределВсехБайтов: 40)
    }
}

@Test func кириллическийИсточникПереноситсяВЯвноеИмяСДефисами() throws {
    let исходный = "docs/СтарыйФайл.md", целевой = "docs/staryij-fajl.md"
    let фикстура = try ФикстураПереименования([исходный: Data("[self](СтарыйФайл.md#part)\n".utf8), "index.md": Data("[ссылка](docs/СтарыйФайл.md)\n".utf8)])
    try ПереименованиеФайла.применить(фикстура.план(исходный, целевой))
    #expect(try фикстура.читать(целевой) == Data("[self](staryij-fajl.md#part)\n".utf8))
    #expect(try фикстура.читать("index.md") == Data("[ссылка](docs/staryij-fajl.md)\n".utf8))
}

@Test func независимыеПроходыНеЗаимствуютПрежнийСоставКаталога() throws {
    let фикстура = try ФикстураПереименования(), первый = try фикстура.план()
    try фикстура.записать("extra.md", Data("# Новый вход\n".utf8))
    let второй = try фикстура.план()
    #expect(второй.файлы.contains { $0.путь == "extra.md" })
    ожидатьОтказ("Дрейф Markdown-инвентаря") { try ПереименованиеФайла.применить(первый) }
    try фикстура.записать("archive/NEW.md", Data("коллизия\n".utf8))
    ожидатьОтказ("Назначение занято") { try ПереименованиеФайла.применить(второй) }
}

@Test func конечныйРесурсныйНаборСохраняетВсеДокументыИПлан() throws {
    var файлы = ["docs/old.md": Data("# old\n".utf8), "index.md": Data("[link](docs/old.md)\n".utf8)]
    for номер in 0..<250 {
        let имя = "docs/doc-" + String(format: "%04d", номер) + "-" + String(repeating: "x", count: 80) + ".md"
        файлы[имя] = Data("# Открытая конечная fixture\n".utf8)
    }
    let фикстура = try ФикстураПереименования(файлы, толькоЗаданные: true), прежде = try фикстура.подпись()
    let план = try фикстура.план("docs/old.md", "docs/new.md")
    #expect(план.файлы.count == 252)
    #expect(план.правки.count == 1)
    #expect(план.правки[0].байты == Data("[link](docs/new.md)\n".utf8))
    #expect(try фикстура.подпись() == прежде)
}

@Test func несвязанныеКодовыеПодписиПроверяютсяИСохраняются() throws {
    let текст = "[live](docs/old.md)\n[`metadata`](metadata.json)\n[`remote`](https://example.invalid)\n"
    let фикстура = try ФикстураПереименования(["index.md": Data(текст.utf8), "metadata.json": Data("{}\n".utf8)])
    let план = try фикстура.план()
    #expect(план.правки.count == 1)
    #expect(план.правки[0].числоСсылок == 1)
    #expect(план.правки[0].байты == Data(текст.replacingOccurrences(of: "(docs/old.md)", with: "(archive/new.md)").utf8))
}

@Test(arguments: [false, true]) func внешняяЦельНеСкрываетВложеннуюСсылкуПодКодовойПодписью(_ поМетке: Bool) throws {
    let путь = поМетке ? "Журнал/2026-10-29_12-00-00_MSK_fixture/запрос.md" : "index.md"
    let текст = поМетке
        ? "## Текст запроса\n[prefix `code` ![badge][id]](https://example.invalid)\n## Производное\n[id]: ../../docs/old.md\n"
        : "[prefix `code` ![badge](docs/old.md)](https://example.invalid)\n"
    let фикстура = try ФикстураПереименования([путь: Data(текст.utf8)])
    ожидатьОтказ("one-file-вложенная-подпись") { try фикстура.план() }
    #expect(try фикстура.читать(путь) == Data(текст.utf8))
}

@Test(arguments: [false, true]) func игнорируемыйАлиасПроверяетсяТакжеНаПозднейГранице(_ поздний: Bool) throws {
    let текст = Data("[live](docs/old.md)\n[alias](hidden/old.md)\n".utf8)
    let фикстура = try ФикстураПереименования([".gitignore": Data("hidden\n".utf8), "index.md": текст])
    let адрес = фикстура.корень.appendingPathComponent("hidden")
    if поздний {
        try FileManager.default.createDirectory(at: адрес, withIntermediateDirectories: false)
        let план = try фикстура.план()
        try FileManager.default.removeItem(at: адрес)
        try FileManager.default.createSymbolicLink(atPath: адрес.path, withDestinationPath: "docs")
        ожидатьОтказ("Символический компонент цели") { try ПереименованиеФайла.применить(план) }
    } else {
        try FileManager.default.createSymbolicLink(atPath: адрес.path, withDestinationPath: "docs")
        ожидатьОтказ("Символический компонент цели") { try фикстура.план() }
    }
    #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent("docs/old.md").path))
    #expect(try фикстура.читать("index.md") == текст)
}

@Test func отсутствующаяКодоваяЦельПереносимогоДокументаОтвергнута() throws {
    let текст = Data("[`meta`](missing.json)\n".utf8)
    let фикстура = try ФикстураПереименования(["docs/old.md": текст])
    ожидатьОтказ("сломанная-исходящая-или-case-NFC-symlink-цель") {
        try фикстура.план("docs/old.md", "docs/new.md")
    }
    #expect(try фикстура.читать("docs/old.md") == текст)
}

@Test func отсутствующаяНесвязаннаяКодоваяЦельСохраняется() throws {
    let текст = "[live](docs/old.md)\n[`meta`](missing.json)\n"
    let фикстура = try ФикстураПереименования(["index.md": Data(текст.utf8)])
    let план = try фикстура.план("docs/old.md", "docs/new.md")
    #expect(план.правки.count == 1)
    #expect(план.правки[0].байты == Data(текст.replacingOccurrences(of: "(docs/old.md)", with: "(docs/new.md)").utf8))
}

@Test(arguments: [false, true]) func голыеПробелыВАдресеЗакрытоОтвергнуты(_ значимая: Bool) throws {
    let исходный = значимая ? "docs/old file.md" : "docs/old.md"
    let адрес = значимая ? исходный : "other directory/target.md"
    let текст = Data("[target](\(адрес))\n".utf8)
    let фикстура = try ФикстураПереименования([исходный: Data("# old\n".utf8), "index.md": текст])
    ожидатьОтказ("неполная-встроенная-ссылка") {
        try фикстура.план(исходный, "docs/new.md")
    }
    #expect(try фикстура.читать("index.md") == текст)
}
