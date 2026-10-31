import Foundation
import Darwin
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif
#if (ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ) || (ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ) || (ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ && ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ)
#error("Профили свежести, наблюдения и префиксов взаимоисключающие")
#endif

#if !ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ
// Прежний String.range oracle закрепляет ASCII grammar и ICU terminal-$.
// Производственный байтовый проход не используется для вычисления ожидания.
private func прежнийПрефиксКонтейнера(_ текст: String) -> Int {
    let байты = Array(текст.utf8)
    var курсор = 0
    while курсор < байты.count {
        let остаток = String(decoding: байты[курсор...], as: UTF8.self)
        guard let диапазон = остаток.range(of: #"^[ ]{0,3}(?:>[ \t]?|(?:[-+*]|[0-9]{1,9}[.)])(?:[ \t]+|$))"#, options: .regularExpression) else { return курсор }
        let длина = остаток[диапазон].utf8.count
        if длина == 0 { return курсор }
        курсор += длина
    }
    return курсор
}

@Test(arguments: [
    "", "x", " ", "   ", ">x", " >x", "  >x", "   >x", "    >x", "\t>x",
    ">", ">\tx", ">\t\tx", ">  x", ">    >x", ">     >x", ">>x",
    "-", "  *", "-x", "->x", ". x", "1.. x", "- \tx", "* >x", "1. x",
    "123456789) x", "000000001. x", "1234567890) x", "0) x", "1.\tx",
    ">ё", ">🙂", ">\u{00A0}x", "\u{00A0}>x", "-\u{00A0}x", "١. x",
    ">\u{0301}x", "1. \u{0301}x", "-\r", "1.\r", "-\u{0085}", "1.\u{0085}",
    "-\u{2028}", "1.\u{2028}", "-\u{2029}", "1.\u{2029}", "-\u{000B}", "-\u{000C}"
]) func префиксКонтейнераСовпадаетСПрежнейГрамматикой(_ текст: String) {
    let начало = Data("ёж".utf8).count
    let байты = Array(("ёж" + текст + "конец за диапазоном").utf8)
    let диапазон = начало..<(начало + текст.utf8.count)
    var работа = 0
    let итог = ПрефиксКонтейнераОдногоФайла.начало(байты, диапазон: диапазон,
        потратить: { работа += $0; return true },
        текст: { String(decoding: байты[$0], as: UTF8.self) })
    #expect(итог == начало + прежнийПрефиксКонтейнера(текст))
    #expect(диапазон.lowerBound...диапазон.upperBound ~= итог)
    #expect(работа <= 8 * текст.utf8.count + 32)
}

@Test(arguments: ["", " ", "   ", "    ", "\t", ">", ">>", "> ", ">    >", ">     >", "-", "- ", "*\t", "1. ", "123456789) ", "1234567890) ", "\u{00A0}>", ">\u{0301}"])
func префиксКонтейнераСохраняетМаскиИБудущиеБайты(_ префикс: String) throws {
    let адрес = "[target](docs/old.md)\n", новый = "[target](archive/new.md)\n"
    let маркер = префикс + "~~~"
    let байтыМаркера = Array(маркер.utf8)
    let начало = прежнийПрефиксКонтейнера(маркер)
    let хвост = String(decoding: байтыМаркера[начало...], as: UTF8.self)
    let ограда = хвост.range(of: #"^[ ]{0,3}~{3,}[ \t]*$"#, options: .regularExpression) != nil
    let исходный = маркер + "\n" + адрес + маркер + "\n" + адрес
    let ожидаемый = маркер + "\n" + (ограда ? адрес : новый) + маркер + "\n" + новый
    let байтыИсточника = Data("# Source\n".utf8), байтыИндекса = Data(исходный.utf8)
    let разбор = try СсылкиОдногоФайла.переписать(документы: [
        .init(путь: "docs/old.md", байты: байтыИсточника, sha256: хэшПутей(байтыИсточника)),
        .init(путь: "index.md", байты: байтыИндекса, sha256: хэшПутей(байтыИндекса))
    ], исходный: "docs/old.md", целевой: "archive/new.md", пути: ["docs/old.md", "index.md"])
    let правка = try #require(разбор.правки.first { $0.исходный == "index.md" })
    #expect(правка.байты == Data(ожидаемый.utf8))
    #expect(правка.числоСсылок == (ограда ? 1 : 2))
}

@Test(arguments: [32, 64, 128])
func однофайловыйРазборНеСтроитОбщиеМаски(_ размер: Int) throws {
    let код = String(repeating: "`[hidden](docs/old.md)`\n", count: размер)
    let источник = Data("# Source\n".utf8)
    let вход = Data((код + "[target](docs/old.md)\n").utf8)
    let наблюдение = try НаблюдениеОднофайловогоПлана { _ in }
    let разбор = try СсылкиОдногоФайла.переписать(документы: [
        .init(путь: "docs/old.md", байты: источник, sha256: хэшПутей(источник)),
        .init(путь: "index.md", байты: вход, sha256: хэшПутей(вход))
    ], исходный: "docs/old.md", целевой: "archive/new.md", пути: ["docs/old.md", "index.md"], наблюдение: наблюдение)
    let правка = try #require(разбор.правки.first { $0.исходный == "index.md" })
    #expect(правка.байты == Data((код + "[target](archive/new.md)\n").utf8))
    #expect(правка.числоСсылок == 1)
    #expect(наблюдение.счётчик(.строкиОбщихМасок) == 0)
    #expect(наблюдение.счётчик(.работа) <= UInt64(64 * (источник.count + вход.count) + 1024))
    #expect(наблюдение.счётчик(.байтыДекодирования) <= UInt64(8 * (источник.count + вход.count) + 1024))
    try наблюдение.проверить()
}

@Test(arguments: [false, true])
func однофайловыйРазборСохраняетОтказПереднейЧасти(_ замкнута: Bool) throws {
    let текст = "+++\ntitle = 'sample'\n" + (замкнута ? "+++\n" : "") + "[target](docs/old.md)\n"
    let источник = Data("# Source\n".utf8), вход = Data(текст.utf8)
    do {
        let разбор = try СсылкиОдногоФайла.переписать(документы: [
            .init(путь: "docs/old.md", байты: источник, sha256: хэшПутей(источник)),
            .init(путь: "index.md", байты: вход, sha256: хэшПутей(вход))
        ], исходный: "docs/old.md", целевой: "archive/new.md", пути: ["docs/old.md", "index.md"])
        #expect(замкнута)
        let правка = try #require(разбор.правки.first { $0.исходный == "index.md" })
        #expect(правка.байты == Data(текст.replacingOccurrences(of: "docs/old.md", with: "archive/new.md").utf8))
    } catch {
        #expect(!замкнута)
        #expect(String(describing: error).contains("незамкнутая-передняя-часть"))
    }
}

@Test(arguments: ["index.md", "Источники/raw.md"])
func однофайловыйРазборОтвергаетНезамкнутуюЗащищённуюПереднююЧасть(_ путь: String) throws {
    let источник = Data("# Source\n".utf8), вход = Data("+++\ntitle = 'sample'\n".utf8)
    do {
        _ = try СсылкиОдногоФайла.переписать(документы: [
            .init(путь: "docs/old.md", байты: источник, sha256: хэшПутей(источник)),
            .init(путь: путь, байты: вход, sha256: хэшПутей(вход))
        ], исходный: "docs/old.md", целевой: "archive/new.md", пути: ["docs/old.md", путь])
        Issue.record("Ожидался отказ незамкнутой передней части")
    } catch {
        #expect(String(describing: error).contains("незамкнутая-передняя-часть"))
    }
}

@Test(arguments: [32, 64, 128])
func префиксКонтейнераОграниченЛинейнымОбъёмомДекодирования(_ глубина: Int) throws {
    let текст = String(repeating: "> ", count: глубина) + "[target](docs/old.md)\n"
    let байтыИсточника = Data("# Source\n".utf8), байтыИндекса = Data("[target](docs/old.md)\n".utf8), байтыИзмерения = Data(текст.utf8)
    let наблюдение = try НаблюдениеОднофайловогоПлана { _ in }
    let разбор = try СсылкиОдногоФайла.переписать(документы: [
        .init(путь: "docs/old.md", байты: байтыИсточника, sha256: хэшПутей(байтыИсточника)),
        .init(путь: "index.md", байты: байтыИндекса, sha256: хэшПутей(байтыИндекса)),
        .init(путь: "measure.md", байты: байтыИзмерения, sha256: хэшПутей(байтыИзмерения))
    ], исходный: "docs/old.md", целевой: "archive/new.md", пути: ["docs/old.md", "index.md", "measure.md"], наблюдение: наблюдение)
    #expect(разбор.правки.count == 2)
    #expect(разбор.правки.first { $0.исходный == "index.md" }?.байты == Data("[target](archive/new.md)\n".utf8))
    #expect(разбор.правки.first { $0.исходный == "measure.md" }?.байты == Data((String(repeating: "> ", count: глубина) + "[target](archive/new.md)\n").utf8))
    #expect(наблюдение.счётчик(.байтыДекодирования) <= UInt64(20 * байтыИзмерения.count + 1024))
    try наблюдение.проверить()
}
#endif

// Открытая конечная Git-фикстура; расположение задаёт запускающая сторона.
#if !ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ
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
#endif

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

#if !ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ
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

@Test func историческиеПробелыВходящейСсылкиПрименены() throws {
    let исходный = "docs/old file.md"
    let текст = Data("[target](docs/old file.md?view=1#top)\n".utf8)
    let фикстура = try ФикстураПереименования([исходный: Data("# old\n".utf8), "index.md": текст])
    let до = try фикстура.подпись()
    let план = try фикстура.план(исходный, "archive/new.md")
    #expect(try фикстура.подпись() == до)
    #expect(план.правки.count == 1)
    #expect(план.правки[0].числоСсылок == 1)
    try ПереименованиеФайла.применить(план)
    #expect(try фикстура.читать("index.md") == Data("[target](archive/new.md?view=1#top)\n".utf8))
    #expect(try фикстура.читать("archive/new.md") == Data("# old\n".utf8))
    #expect(!FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(исходный).path))
}

@Test func историческиеПробелыИсходящейСсылкиПрименены() throws {
    let текст = Data("[target](../../other directory/target.md?view=1#top)\n".utf8)
    let фикстура = try ФикстураПереименования([
        "docs/deep/old.md": текст,
        "other directory/target.md": Data("# Target\n".utf8)
    ])
    let план = try фикстура.план("docs/deep/old.md", "archive/new.md")
    try ПереименованиеФайла.применить(план)
    #expect(try фикстура.читать("archive/new.md") == Data("[target](../other%20directory/target.md?view=1#top)\n".utf8))
    #expect(try фикстура.читать("other directory/target.md") == Data("# Target\n".utf8))
}

@Test func историческиеПробелыТочногоБлокераСохранены() throws {
    let строка = Data("- [Вопрос и ответ](../../Вопросы и ответы/2026-09-15_16-09-02_MSK_уточнить-оболочку-API-и-стоимость-IPC.md), [индекс ответов](../../Вопросы и ответы/README.md).\n".utf8)
    #expect(строка.count == 240)
    #expect(хэшПутей(строка) == "caf67ebd0a418a71a9807601ce8ab0ac99af9d363c211a0a8fad69b2484f87eb")
    let текст = Data("# Открытая фикстура\n\n## Текст запроса\n\nНеизменяемый оригинал.\n\n## Производное\n\n".utf8) + строка
    let документ = "Журнал/2026-09-15_16-09-02_MSK_уточнить-оболочку-API-и-стоимость-IPC/запрос.md"
    let фикстура = try ФикстураПереименования([
        документ: текст,
        "Вопросы и ответы/2026-09-15_16-09-02_MSK_уточнить-оболочку-API-и-стоимость-IPC.md": Data("# Ответ\n".utf8),
        "Вопросы и ответы/README.md": Data("# Индекс\n".utf8)
    ])
    let до = try фикстура.подпись()
    let план = try фикстура.план()
    #expect(try фикстура.подпись() == до)
    #expect(!план.правки.contains { $0.исходный == документ })
    try ПереименованиеФайла.применить(план)
    #expect(try фикстура.читать(документ) == текст)
}

@Test(arguments: [
    "docs/old file.md \"Title\"", "docs/old file.md 'Title'",
    "docs/old file.md (Title)", "docs/old\tfile.md",
    "docs/old file.md\nTitle", " docs/old file.md", "docs/old file.md ",
    "docs/old file.md<tail>", "docs/old.md?label=two words", "docs/old.md#two words",
    "docs/old file.md?label=two words", "docs/old file.md#two words"
]) func историческиеПробелыНеоднозначнойФормыОтвергнуты(_ адрес: String) throws {
    let текст = Data("[target](\(адрес))\n".utf8)
    let фикстура = try ФикстураПереименования(["docs/old file.md": Data("# old\n".utf8), "index.md": текст])
    let до = try фикстура.подпись()
    ожидатьОтказ("неполная-встроенная-ссылка") {
        try фикстура.план("docs/old file.md", "archive/new.md")
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == текст)
}

@Test(arguments: ["docs/Old file.md", "missing directory/target.md"])
func историческиеПробелыНеточнойЦелиОтвергнуты(_ адрес: String) throws {
    let текст = Data("[target](\(адрес))\n".utf8)
    let фикстура = try ФикстураПереименования(["docs/old file.md": Data("# old\n".utf8), "index.md": текст])
    let до = try фикстура.подпись()
    ожидатьОтказ("сломанная-исходящая-или-case-NFC-symlink-цель") {
        try фикстура.план("docs/old file.md", "archive/new.md")
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == текст)
}

@Test func историческиеПробелыЗащищённойСсылкиОтвергнуты() throws {
    let текст = Data("[target](../docs/old file.md)\n".utf8)
    let фикстура = try ФикстураПереименования([
        "docs/old file.md": Data("# old\n".utf8), "Источники/raw.md": текст
    ])
    let до = try фикстура.подпись()
    ожидатьОтказ("защищённая-живая-ссылка-блокирует-перенос") {
        try фикстура.план("docs/old file.md", "archive/new.md")
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("Источники/raw.md") == текст)
}

@Test func историческиеПробелыСимволическойЦелиОтвергнуты() throws {
    let текст = Data("[target](alias directory/target.md)\n".utf8)
    let фикстура = try ФикстураПереименования([
        "real directory/target.md": Data("# Target\n".utf8), "index.md": текст
    ])
    try FileManager.default.createSymbolicLink(atPath: фикстура.корень.path + "/alias directory", withDestinationPath: "real directory")
    try фикстура.коммит()
    let до = try фикстура.подпись()
    ожидатьОтказ("сломанная-исходящая-или-case-NFC-symlink-цель") { try фикстура.план() }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == текст)
}

@Test(arguments: ["docs/old file.md", "other directory/target.md"])
func историческиеПробелыОпределенияНеПропущены(_ адрес: String) throws {
    let текст = Data("[ref][id]\n[id]: \(адрес)\n".utf8)
    let фикстура = try ФикстураПереименования([
        "docs/old file.md": Data("# old\n".utf8),
        "other directory/target.md": Data("# Target\n".utf8), "index.md": текст
    ])
    let до = try фикстура.подпись()
    ожидатьОтказ("one-file-неподдержанное-reference-определение") {
        try фикстура.план("docs/old file.md", "archive/new.md")
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == текст)
}

@Test(arguments: [false, true]) func историческиеПробелыПодКодовойПодписью(_ значимая: Bool) throws {
    let исходный = значимая ? "docs/old file.md" : "docs/old.md"
    let адрес = значимая ? исходный : "other directory/target.md"
    let текст = Data("[`meta`](\(адрес))\n".utf8)
    let фикстура = try ФикстураПереименования([
        исходный: Data("# old\n".utf8), "index.md": текст,
        "other directory/target.md": Data("# Target\n".utf8)
    ])
    let до = try фикстура.подпись()
    if значимая {
        ожидатьОтказ("one-file-код-в-подписи") { try фикстура.план(исходный, "archive/new.md") }
        #expect(try фикстура.подпись() == до)
    } else {
        let план = try фикстура.план(исходный, "archive/new.md")
        #expect(try фикстура.подпись() == до)
        try ПереименованиеФайла.применить(план)
    }
    #expect(try фикстура.читать("index.md") == текст)
}

#endif

#if !ФУМ_ПРОВЕРКИ_НАБЛЮДЕНИЯ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ
private func байтыФикстурыСвежести(_ тело: String, время: String, перевод: String = "\n") -> Data {
    let текст = тело + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: \(время) -->\n<!-- content-sha256: sha256:\(хэшПутей(Data(тело.utf8))) -->\n<!-- FUM-MD-RECENCY:END -->\n"
    return Data(текст.replacingOccurrences(of: "\n", with: перевод).utf8)
}

@Test(arguments: ["\n", "\r\n"]) func свежестьВызывающегоДокументаВходитВТотЖеПланИПрименение(_ перевод: String) throws {
    let время = "2026-10-30 12:34:56 MSK"
    let прежде = байтыФикстурыСвежести("[target](docs/old.md)\n", время: "2020-01-01 00:00:00 MSK", перевод: перевод)
    if перевод == "\r\n" {
        #expect(прежде.contains(13))
        #expect(прежде.filter { $0 == 13 }.count == прежде.filter { $0 == 10 }.count)
    }
    let источник = байтыФикстурыСвежести("# Old\n", время: "2020-01-01 00:00:00 MSK", перевод: перевод)
    let ожидание = байтыФикстурыСвежести("[target](archive/new.md)\n", время: время, перевод: перевод)
    let фикстура = try ФикстураПереименования(["docs/old.md": источник, "index.md": прежде])
    let до = try фикстура.подпись()
    let план = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: время)
    let повтор = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: время)
    #expect(try план.представление("plan") == повтор.представление("plan"))
    #expect(план.правки.count == 1)
    #expect(план.правки[0].байты == ожидание)
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == прежде)
    try ПереименованиеФайла.применить(план)
    #expect(try фикстура.читать("index.md") == ожидание)
    #expect(try фикстура.читать("archive/new.md") == источник)
}

@Test func свежестьТребуетЯвноеВремяПриСуществующихМетках() throws {
    let прежде = байтыФикстурыСвежести("[target](docs/old.md)\n", время: "2020-01-01 00:00:00 MSK")
    let фикстура = try ФикстураПереименования(["index.md": прежде])
    let до = try фикстура.подпись()
    ожидатьОтказ("Нужно явное время свежести") { try фикстура.план() }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == прежде)
}

@Test(arguments: ["2026-02-30 12:34:56 MSK", "2026-10-30 12:34:56 UTC", "2026-10-30 12:34:56 MSK\n", "2026-1-30 12:34:56 MSK"])
func свежестьОтвергаетНеверноеВремя(_ время: String) throws {
    let фикстура = try ФикстураПереименования()
    let до = try фикстура.подпись()
    ожидатьОтказ("Неверное время свежести MSK") {
        try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: время)
    }
    #expect(try фикстура.подпись() == до)
}

@Test func свежестьОтвергаетНеполнуюСтруктуру() throws {
    let прежде = Data("[target](docs/old.md)\n\n<!-- FUM-MD-RECENCY:BEGIN -->\n".utf8)
    let фикстура = try ФикстураПереименования(["index.md": прежде])
    let до = try фикстура.подпись()
    ожидатьОтказ("Повреждённая структура свежести") {
        try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: "2026-10-30 12:34:56 MSK")
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == прежде)
}

@Test func свежестьОтвергаетСмешанныеПереводыСтрок() throws {
    let полный = String(decoding: байтыФикстурыСвежести("[target](docs/old.md)\n", время: "2020-01-01 00:00:00 MSK"), as: UTF8.self)
    let прежде = Data(полный.replacingOccurrences(of: "(docs/old.md)\n", with: "(docs/old.md)\r\n").utf8)
    #expect(прежде.filter { $0 == 13 }.count == 1)
    #expect(прежде.filter { $0 == 10 }.count > 1)
    let фикстура = try ФикстураПереименования(["index.md": прежде])
    let до = try фикстура.подпись()
    ожидатьОтказ("Смешанные переводы строк свежести") {
        try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: "2026-10-30 12:34:56 MSK")
    }
    #expect(try фикстура.подпись() == до)
}

@Test(arguments: [false, true]) func свежестьУчитываетсяВКонечныхБюджетах(_ общий: Bool) throws {
    let фикстура = try ФикстураПереименования([
        "docs/old.md": Data("# Old\n".utf8), "index.md": Data("[target](docs/old.md)\n".utf8)
    ], толькоЗаданные: true)
    let до = try фикстура.подпись()
    ожидатьОтказ(общий ? "Превышен общий бюджет итоговой свежести" : "Превышен бюджет итоговой правки") {
        try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "docs/new.md",
            пределФайла: общий ? 8_388_608 : 64, пределВсехБайтов: общий ? 64 : 268_435_456, времяСвежести: "2026-10-30 12:34:56 MSK")
    }
    #expect(try фикстура.подпись() == до)
}

@Test func свежестьВосстанавливаетсяПриЧастичнойУстановке() throws {
    let прежде = байтыФикстурыСвежести("[target](docs/old.md)\n", время: "2020-01-01 00:00:00 MSK")
    let фикстура = try ФикстураПереименования(["index.md": прежде, "second.md": прежде])
    let до = try фикстура.подпись()
    let план = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", времяСвежести: "2026-10-30 12:34:56 MSK")
    ожидатьОтказ("откат проверен") {
        try ПереименованиеФайла.применить(план, передУстановкой: { номер in
            if номер == 2 { throw ОшибкаПутей.отказ("Отказ второй установки свежести") }
        })
    }
    #expect(try фикстура.подпись() == до)
    #expect(try фикстура.читать("index.md") == прежде)
    #expect(try фикстура.читать("second.md") == прежде)
}

@Test func свежестьЧерезСуществующуюКоманду() async throws {
    let время = "2026-10-30 12:34:56 MSK"
    let прежде = байтыФикстурыСвежести("[target](docs/old.md)\n", время: "2020-01-01 00:00:00 MSK")
    let фикстура = try ФикстураПереименования(["index.md": прежде])
    let результат = try await КомандаПутей.выполнить([
        "применить-файл", "--repo-root", фикстура.корень.path,
        "--source", "docs/old.md", "--destination", "archive/new.md", "--время-свежести", время
    ])
    let ответ = try #require(JSONSerialization.jsonObject(with: результат) as? [String: Any])
    #expect(ответ["время_свежести"] as? String == время)
    #expect(try фикстура.читать("index.md") == байтыФикстурыСвежести("[target](archive/new.md)\n", время: время))
}
#endif

#if !ФУМ_ПРОВЕРКИ_СВЕЖЕСТИ_ПЕРЕИМЕНОВАНИЯ && !ФУМ_ПРОВЕРКИ_ПРЕФИКСОВ_ПЕРЕИМЕНОВАНИЯ
@Test func наблюдениеНеМеняетПланИПоказываетНезависимыеПроходы() throws {
    let секрет = "Не переносить текст наблюдением."
    let фикстура = try ФикстураПереименования(["index.md": Data("[target](docs/old.md)\n\(секрет)\n".utf8)])
    let до = try фикстура.подпись()
    let обычный = try фикстура.план()
    var кадры: [Data] = []
    let наблюдение = try НаблюдениеОднофайловогоПлана(часы: { 0 }) { кадры.append($0) }
    let план = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", наблюдение: наблюдение)
    #expect(try обычный.представление("plan") == план.представление("plan"))
    #expect(обычный.правки.map(\.байты) == план.правки.map(\.байты))
    #expect(try фикстура.подпись() == до)
    #expect(наблюдение.счётчик(.полныеИнвентари) == 2)
    #expect(наблюдение.счётчик(.файлыПрочитаны) == 4)
    #expect(наблюдение.числоКадров <= 128)
    #expect(наблюдение.числоБайтов <= 65_536)
    #expect(кадры.allSatisfy { $0.count <= 1536 && $0.last == 10 })
    #expect(!кадры.contains { String(decoding: $0, as: UTF8.self).contains(секрет) })
    let фазы = try кадры.map { кадр -> String in
        let объект = try #require(JSONSerialization.jsonObject(with: кадр) as? [String: Any])
        return try #require(объект["фаза"] as? String)
    }
    #expect(фазы == ["вход", "источник", "инвентарь", "чтение", "разбор", "префиксы", "свежесть", "сверка", "готово"])
    for номер in [1, 3, 4, 7] {
        let объект = try #require(JSONSerialization.jsonObject(with: кадры[номер]) as? [String: Any])
        #expect(объект["документ"] is [String: Any])
    }
}

@Test(arguments: [
    "[live](docs/old.md)\n", "[live](<docs/old.md> 'Title')\n",
    "[live][id]\n[id]: docs/old.md\n",
    "```\n[hidden](docs/old.md)\n```\n[live](docs/old.md)\n",
    "[`meta`](other.md)\n[live](docs/old.md)\n",
    "[![badge](docs/old.md)](https://example.invalid)\n",
    "[ref][id]\n[id]: docs/old file.md\n"
]) func наблюдениеСохраняетБайтыИПредметныеОтказы(_ текст: String) throws {
    let фикстура = try ФикстураПереименования(["index.md": Data(текст.utf8), "other.md": Data("# Other\n".utf8)])
    let до = try фикстура.подпись()
    var ошибкаБез: String?
    var байтыБез: Data?
    var правкиБез: [Data]?
    do {
        let план = try фикстура.план()
        байтыБез = try план.представление("plan"); правкиБез = план.правки.map(\.байты)
    }
    catch { ошибкаБез = String(describing: error) }
    let наблюдение = try НаблюдениеОднофайловогоПлана { _ in }
    var ошибкаС: String?
    var байтыС: Data?
    var правкиС: [Data]?
    do {
        let план = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", наблюдение: наблюдение)
        байтыС = try план.представление("plan"); правкиС = план.правки.map(\.байты)
    } catch { ошибкаС = String(describing: error) }
    #expect(ошибкаБез == ошибкаС)
    #expect(байтыБез == байтыС)
    #expect(правкиБез == правкиС)
    #expect(try фикстура.подпись() == до)
}

@Test func наблюдениеЗакрытоОстанавливаетсяПоЧислуКадров() throws {
    let фикстура = try ФикстураПереименования()
    let до = try фикстура.подпись()
    var кадры: [Data] = []
    let наблюдение = try НаблюдениеОднофайловогоПлана(пределКадров: 1) { кадры.append($0) }
    ожидатьОтказ("предел-кадров-наблюдения") {
        try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", наблюдение: наблюдение)
    }
    #expect(кадры.count == 1)
    #expect(try фикстура.подпись() == до)
}

@Test func наблюдениеЗакрытоОстанавливаетсяПоБайтамИОшибкеВывода() throws {
    var выдано = 0
    let малый = try НаблюдениеОднофайловогоПлана(пределБайтов: 1) { _ in выдано += 1 }
    ожидатьОтказ("предел-байтов-наблюдения") { try малый.этап(.вход) }
    #expect(выдано == 0)
    let сломанный = try НаблюдениеОднофайловогоПлана { _ in throw ОшибкаПутей.отказ("Открытый отказ фикстуры") }
    ожидатьОтказ("ошибка-вывода-наблюдения") { try сломанный.этап(.вход) }
    let переполненный = try НаблюдениеОднофайловогоПлана { _ in }
    #expect(переполненный.учесть(.работа, Int.max))
    #expect(переполненный.учесть(.работа, Int.max))
    #expect(!переполненный.учесть(.работа, Int.max))
    ожидатьОтказ("переполнение-счётчика-наблюдения") { try переполненный.проверить() }
    let длинныйПуть = String(repeating: "ё", count: 100) + ".md"
    var кадр = Data()
    let длинный = try НаблюдениеОднофайловогоПлана { кадр = $0 }
    try длинный.этап(.источник, путь: длинныйПуть)
    let объект = try #require(JSONSerialization.jsonObject(with: кадр) as? [String: Any])
    let документ = try #require(объект["документ"] as? [String: Any])
    #expect(документ["путь"] == nil)
    #expect(документ["хэшПути"] as? String == хэшПутей(Data(длинныйПуть.utf8)))
}

@Test func наблюдениеОбновляетДокументБезКадраНаКаждыйДокумент() throws {
    var время: UInt64 = 0
    var кадры: [Data] = []
    let наблюдение = try НаблюдениеОднофайловогоПлана(часы: { время }) { кадры.append($0) }
    try наблюдение.этап(.разбор)
    for номер in 1...5004 {
        наблюдение.установитьДокумент(номер: номер, всего: 5004, путь: "docs/\(номер).md")
        наблюдение.учесть(.работа)
    }
    #expect(кадры.count == 1)
    время = 6_000_000_000
    наблюдение.установитьУчасток("токены", курсор: 77)
    #expect(кадры.count == 2)
    let объект = try #require(JSONSerialization.jsonObject(with: кадры[1]) as? [String: Any])
    let документ = try #require(объект["документ"] as? [String: Any])
    #expect(документ["номер"] as? Int == 5004)
    #expect(объект["курсорUTF8"] as? Int == 77)
    #expect(наблюдение.счётчик(.работа) == 5004)
    try наблюдение.проверить()
}

@Test func наблюдениеОтвергаетсяДляПрименения() async throws {
    let фикстура = try ФикстураПереименования()
    let до = try фикстура.подпись()
    do {
        _ = try await КомандаПутей.выполнить(["применить-файл", "--source", "docs/old.md", "--destination", "archive/new.md", "--repo-root", фикстура.корень.path, "--наблюдение"])
        Issue.record("Ожидался отказ диагностического apply")
    } catch { #expect(String(describing: error).contains("Наблюдение разрешено только для RO-плана")) }
    #expect(try фикстура.подпись() == до)
}

struct НагрузкаНаблюдения: Sendable {
    let семейство: String
    let размер: Int
}

@Test(arguments: [
    НагрузкаНаблюдения(семейство: "код", размер: 32), НагрузкаНаблюдения(семейство: "код", размер: 64), НагрузкаНаблюдения(семейство: "код", размер: 128),
    НагрузкаНаблюдения(семейство: "контейнер", размер: 32), НагрузкаНаблюдения(семейство: "контейнер", размер: 64), НагрузкаНаблюдения(семейство: "контейнер", размер: 128),
    НагрузкаНаблюдения(семейство: "скобки", размер: 32), НагрузкаНаблюдения(семейство: "скобки", размер: 64), НагрузкаНаблюдения(семейство: "скобки", размер: 128)
]) func наблюдениеСчитаетРаботуНаДевятиМалыхВходах(_ вход: НагрузкаНаблюдения) throws {
    let текст: String
    switch вход.семейство {
    case "код": текст = String(repeating: "a `b`\n", count: вход.размер)
    case "контейнер": текст = String(repeating: "> ", count: вход.размер) + "[target](docs/old.md)\n"
    default: текст = String(repeating: "[", count: вход.размер) + String(repeating: "\\", count: вход.размер) + "\n"
    }
    let фикстура = try ФикстураПереименования(["measure.md": Data(текст.utf8)])
    let до = try фикстура.подпись()
    let без = try фикстура.план()
    let наблюдение = try НаблюдениеОднофайловогоПлана { _ in }
    let с = try ПереименованиеФайла.построить(корень: фикстура.корень, исходный: "docs/old.md", целевой: "archive/new.md", наблюдение: наблюдение)
    #expect(try без.представление("plan") == с.представление("plan"))
    #expect(наблюдение.счётчик(.работа) > 0)
    #expect(наблюдение.счётчик(.строкиОбщихМасок) == 0)
    #expect(try фикстура.подпись() == до)
}
#endif
