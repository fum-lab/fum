import Foundation
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

private func снимокПроверки(_ пути: [String], грязный: Bool = false) -> СнимокПутей {
    let каталоги = Set(пути.flatMap { путь in
        путь.indices.filter { путь[$0] == "/" }.map { String(путь[..<$0]) }
    })
    return СнимокПутей(коммит: String(repeating: "a", count: 40), дерево: String(repeating: "b", count: 40),
        ветка: "refs/heads/direction", индекс_sha256: String(repeating: "c", count: 64),
        индекс_изменён: грязный, записи: пути.map { путь in
            ЗаписьСнимкаПутей(путь: путь, тип: каталоги.contains(путь) ? "каталог" : "файл", sha256: "байты") })
}

private func контекстПроверки() -> КонтекстПутей {
    КонтекстПутей(корень: "узел/репозиторий/направление", владелец: "писатель", писатель: "писатель",
                 целевая_ветка: "refs/heads/direction")
}

private func планПроверки(_ пары: [(String, String)], грязный: Bool = false,
                         контекст: КонтекстПутей = контекстПроверки()) throws -> ПланПутей {
    try ПостроительПланаПутей.построить(снимокПроверки(пары.map(\.0), грязный: грязный),
        отображения: пары.map { ОтображениеПути(исходный: $0.0,
            целевой: $0.1.split(separator: "/", omittingEmptySubsequences: false).map { ИменаПутей.разбить(String($0)) }.joined(separator: "/")) },
        контекст: контекст, хэшОтображения: String(repeating: "d", count: 64))
}

@Test func планФайловИКаталоговДетерминирован() throws {
    let пары = [("Каталог", "Katalog"), ("Каталог/Файл.md", "Katalog/Fajl.md")]
    let первый = try планПроверки(пары)
    let второй = try планПроверки(пары.reversed())
    #expect(try байтыПлана(первый) == байтыПлана(второй))
    #expect(первый.отображения.map(\.целевой) == ["katalog", "katalog/fajl.md"])
    #expect(первый.препятствия.isEmpty)
    #expect(!первый.применение_разрешено)
}

@Test(arguments: ["../вне", "/вне", "a//b", "a/./b", "a\u{0000}b"])
func выходЗаКореньОтвергнут(путь: String) {
    #expect(throws: ОшибкаПутей.self) { try планПроверки([(путь, "safe")]) }
}

@Test(arguments: ["K.txt", "é.txt", "файл.txt"])
func проверяетсяЛатиницаДоНижнегоРегистра(имя: String) {
    #expect(throws: ОшибкаПутей.self) { try планПроверки([("старый.txt", имя)]) }
}

@Test func выявленыКоллизииРегистраИНормализации() throws {
    let план = try планПроверки([("Первый", "A"), ("Второй", "a")])
    #expect(план.препятствия.contains { $0.код == "коллизия-назначения" })
    let нормализация = try планПроверки([("é", "one"), ("e\u{301}", "two")])
    #expect(нормализация.отображения.count == 2)
    #expect(нормализация.препятствия.contains { $0.код == "коллизия-исходных-имён" })
    let регистр = try планПроверки([("ß", "one"), ("SS", "two")])
    #expect(регистр.препятствия.contains { $0.код == "коллизия-исходных-имён" })
}

@Test func циклИТолькоРегистрНеСкрыты() throws {
    let цикл = try планПроверки([("a", "b"), ("b", "a")])
    #expect(цикл.препятствия.contains { $0.код == "цикл-переносов" })
    let регистр = try планПроверки([("File.txt", "File.txt")])
    #expect(регистр.препятствия.contains { $0.код == "переименование-только-регистра" })
}

@Test func занятостьИГрязныйИндексБлокируют() throws {
    var контекст = контекстПроверки()
    контекст.занятые_пути = [ЗанятыйПуть(путь: "Каталог", владелец: "чужой")]
    let план = try планПроверки([("Каталог/Файл", "katalog/fajl")], грязный: true, контекст: контекст)
    #expect(план.препятствия.contains { $0.код == "чужой-писатель" })
    #expect(план.препятствия.contains { $0.код == "изменённый-индекс" })
}

@Test func конфликтПрефиксаВеткиПокомпонентный() throws {
    var контекст = контекстПроверки()
    контекст.целевая_ветка = "refs/heads/x/y"
    контекст.ветки = ["refs/heads/x", "refs/heads/xy"]
    let план = try планПроверки([("a", "a")], контекст: контекст)
    #expect(план.препятствия.filter { $0.код == "конфликт-префикса-ref" }.count == 1)
}

@Test func точныеИсключенияНеРасширяются() throws {
    let план = try планПроверки([("Package.swift", "Package.swift"), ("AGENTS.md", "AGENTS.md"),
        ("Инструменты/tool/SKILL.md", "Instrumentyi/tool/SKILL.md"), ("README.md", "README.md"),
        ("nested/AGENTS.md", "nested/AGENTS.md")])
    #expect(план.исключения.map(\.имя).sorted() == ["AGENTS.md", "AGENTS.md", "Package.swift", "SKILL.md"])
    #expect(план.отображения.contains { $0.исходный == "README.md" && $0.целевой == "readme.md" })
    #expect(план.отображения.contains { $0.исходный == "nested/AGENTS.md" && $0.целевой == "nested/AGENTS.md" })
    #expect(ИменаПутей.исключение("Инструменты/tool/SKILL.md") == nil)
}

@Test(arguments: [("ModeljPlana.swift", "modelj-plana.swift"), ("XMLParser", "xml-parser"),
    ("URLValue", "url-value"), ("parseURL", "parse-url"), ("JSON2Value", "json2-value"),
    ("UTF8Parser", "utf8-parser"), ("version2XMLParser", "version2-xml-parser"),
    ("URL", "url"), ("XMLHTTPParser", "xmlhttp-parser"), ("ABc", "a-bc"),
    ("aB", "a-b"), ("foo2bar", "foo2bar"), ("IPv6Address", "i-pv6-address")])
func границыРегистраИЦифр(пара: (String, String)) throws {
    let результат = try ИменаПутей.нормализовать(ИменаПутей.разбить(пара.0))
    #expect(результат == пара.1)
    #expect(try ИменаПутей.нормализовать(результат) == результат)
}

@Test func коллизииПослеРазбиенияВидны() throws {
    let план = try планПроверки([("XMLParser", "XMLParser"), ("XmlParser", "XmlParser"), ("xml-parser", "xml-parser")])
    #expect(план.препятствия.filter { $0.код == "коллизия-назначения" }.count == 2)
}

@Test func дочерняяВеткаКонфликтуетСТекущей() throws {
    var контекст = контекстПроверки()
    контекст.целевая_ветка = "refs/heads/direction/sub"
    контекст.ветки = ["refs/heads/direction"]
    #expect(try планПроверки([("a", "a")], контекст: контекст).препятствия.contains { $0.код == "конфликт-префикса-ref" })
}

@Test func переносРодителяУчитываетЗанятогоПотомка() throws {
    var контекст = контекстПроверки()
    контекст.занятые_пути = [ЗанятыйПуть(путь: "A/live", владелец: "чужой")]
    #expect(try планПроверки([("A", "b")], контекст: контекст).препятствия.contains { $0.код == "чужой-писатель" })
}

@Test func неполныеИНесогласованныеРодителиБлокируются() throws {
    let несогласованный = try планПроверки([("A", "x"), ("A/f", "y/f")])
    #expect(несогласованный.препятствия.contains { $0.код == "несогласованный-родитель" })
    let неполный = try планПроверки([("A/f", "a/f")])
    #expect(неполный.препятствия.contains { $0.код == "неполный-родитель" })
}

@Test(arguments: ["refs/heads/x.lock", "refs/heads/.hidden", "refs/heads/a.", "refs/heads/a\u{007f}"])
func недопустимаяВеткаОтклоняется(ветка: String) {
    var контекст = контекстПроверки(); контекст.целевая_ветка = ветка
    #expect(throws: ОшибкаПутей.self) { try планПроверки([("a", "a")], контекст: контекст) }
}

@Test func переносЦикличенНаРегистронезависимойСистеме() throws {
    #expect(try планПроверки([("A", "b"), ("b", "a")]).препятствия.contains { $0.код == "цикл-переносов" })
}

@Test func исключениеНеИсправляетЛожноеОтображение() {
    #expect(throws: ОшибкаПутей.self) { try планПроверки([("Package.swift", "K.swift")]) }
}

private func гитПроверки(_ корень: URL, _ аргументы: [String], вход: Data? = nil) throws -> Data {
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = ["--no-optional-locks", "-C", корень.path] + аргументы
    var среда = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
    среда["GIT_CONFIG_NOSYSTEM"] = "1"
    среда["GIT_CONFIG_GLOBAL"] = "/dev/null"
    процесс.environment = среда
    let канал = Pipe(); процесс.standardOutput = канал
    let ошибки = Pipe(); процесс.standardError = ошибки
    let ввод = вход == nil ? nil : Pipe()
    if let ввод { процесс.standardInput = ввод }
    try процесс.run()
    if let ввод, let вход { try ввод.fileHandleForWriting.write(contentsOf: вход); try ввод.fileHandleForWriting.close() }
    let результат = канал.fileHandleForReading.readDataToEndOfFile()
    let объяснение = ошибки.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    guard процесс.terminationStatus == 0 else {
        throw ОшибкаПутей.отказ("Git-фикстура \(аргументы) отказала: \(String(decoding: объяснение, as: UTF8.self))")
    }
    return результат
}

private func сДеревомПроверки(_ действие: (URL) async throws -> Void) async throws {
    let корень = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).resolvingSymlinksInPath()
    try FileManager.default.createDirectory(at: корень.appendingPathComponent("Каталог"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: корень) }
    try Data("# Проверка\n[файл](Файл.md)\n".utf8).write(to: корень.appendingPathComponent("Каталог/Обзор.md"))
    try Data("Проверяемые байты\n".utf8).write(to: корень.appendingPathComponent("Каталог/Файл.md"))
    _ = try гитПроверки(корень, ["init", "-q"])
    _ = try гитПроверки(корень, ["config", "core.precomposeUnicode", "true"])
    _ = try гитПроверки(корень, ["add", "--all"])
    _ = try гитПроверки(корень, ["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "Исходная фикстура"])
    try await действие(корень)
}

@Test func сухойПланЧитаетБезИзмененийИПовторСтабилен() async throws {
    try await сДеревомПроверки { корень in
        let до = try гитПроверки(корень, ["status", "--porcelain=v1", "-z"])
        let индексДо = try Data(contentsOf: корень.appendingPathComponent(".git/index"))
        let чтение = try ЧитательПутей.снять(корень: корень, области: ["Каталог"])
        let карта = try await ШтатноеОтображениеПутей.отобразить(чтение.снимок.записи)
        let план = try ПостроительПланаПутей.построить(чтение.снимок, отображения: карта,
            контекст: контекстПроверки(), хэшОтображения: хэшПутей(байтыПлана(карта)))
        #expect(план.отображения.contains { $0.целевой == "katalog/fajl.md" })
        try СверкаСнимкаПутей.проверить(план, снимок: ЧитательПутей.снять(корень: корень, области: ["Каталог"]).снимок)
        #expect(try гитПроверки(корень, ["status", "--porcelain=v1", "-z"]) == до)
        #expect(try Data(contentsOf: корень.appendingPathComponent(".git/index")) == индексДо)
        #expect(try ЧитательПутей.снять(корень: корень, области: ["Каталог"]).снимок.подпись() == чтение.снимок.подпись())
    }
}

@Test func байтыРежимИДобавленныйФайлДелаютПланНеактуальным() async throws {
    try await сДеревомПроверки { корень in
        let первый = try ЧитательПутей.снять(корень: корень, области: ["Каталог"])
        let карта = try await ШтатноеОтображениеПутей.отобразить(первый.снимок.записи)
        let план = try ПостроительПланаПутей.построить(первый.снимок, отображения: карта,
            контекст: контекстПроверки(), хэшОтображения: "вход")
        let файл = корень.appendingPathComponent("Каталог/Файл.md")
        try Data("Другие байты\n".utf8).write(to: файл)
        #expect(throws: ОшибкаПутей.self) { try СверкаСнимкаПутей.проверить(план, снимок: ЧитательПутей.снять(корень: корень, области: ["Каталог"]).снимок) }
        try Data("Проверяемые байты\n".utf8).write(to: файл)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: файл.path)
        #expect(throws: ОшибкаПутей.self) { try СверкаСнимкаПутей.проверить(план, снимок: ЧитательПутей.снять(корень: корень, области: ["Каталог"]).снимок) }
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: файл.path)
        try Data("Новый файл\n".utf8).write(to: корень.appendingPathComponent("Каталог/Новый.md"))
        #expect(throws: ОшибкаПутей.self) { try СверкаСнимкаПутей.проверить(план, снимок: ЧитательПутей.снять(корень: корень, области: ["Каталог"]).снимок) }
    }
}

@Test func символическаяСсылкаНеЧитаетсяВнеКорня() async throws {
    try await сДеревомПроверки { корень in
        try FileManager.default.createSymbolicLink(atPath: корень.appendingPathComponent("Каталог/ссылка").path,
            withDestinationPath: "/")
        #expect(throws: ОшибкаПутей.self) { try ЧитательПутей.снять(корень: корень, области: ["Каталог"]) }
    }
}

@Test func ссылкиВыявляютсяПоКлассамБезПравкиЦитатИСырья() {
    let тексты = [Data("doc.md".utf8): Data("[файл](Каталог/Файл.md)\n> [цитата](Каталог/Файл.md)\n".utf8),
        Data("code.swift".utf8): Data("let путь = \"Каталог/Файл.md\"\n".utf8),
        Data("config.toml".utf8): Data("path = \"./Каталог\"\n".utf8),
        Data("Журнал/история/материалы/запуски-проверок/1.json".utf8): Data("{\"path\":\"/исходный/адрес\"}\n".utf8)]
    let до = тексты
    let ссылки = АнализСсылокПутей.собрать(тексты)
    #expect(ссылки.contains { $0.файл == "doc.md" && $0.вид == "Markdown" && $0.строка == 1 })
    #expect(!ссылки.contains { $0.файл == "doc.md" && $0.строка == 2 && $0.состояние == "кандидат" })
    #expect(ссылки.contains { $0.файл == "code.swift" && $0.вид == "код" })
    #expect(ссылки.contains { $0.файл == "config.toml" && $0.вид == "конфигурация" })
    #expect(ссылки.contains { $0.состояние == "историческое/дословное — сохранено" })
    #expect(тексты == до)
}

@Test func сохраняемыйПланСвязываетПолныйВходИПовтор() async throws {
    try await сДеревомПроверки { корень in
        let вход = ВходПланаПутей(контекст: контекстПроверки(), области: ["Каталог"])
        let первый = try await КомандаПутей.построить(корень: корень, вход: вход, хэшВхода: "исходный-вход")
        let второй = try await КомандаПутей.построить(корень: корень, вход: вход, хэшВхода: "исходный-вход")
        #expect(первый.вход_sha256 == "исходный-вход")
        #expect(try байтыПлана(первый) == байтыПлана(второй))
        #expect(!первый.применение_разрешено)
    }
}

@Test func сегментацияUnicodeПредшествуетТранслитерации() async throws {
    let карта = try await ШтатноеОтображениеПутей.отобразить([ЗаписьСнимкаПутей(путь: "мЁд.swift"),
        ЗаписьСнимкаПутей(путь: "XMLПарсер2Файла.swift")])
    #expect(карта.map(\.целевой) == ["m-yod.swift", "xml-parser2-fajla.swift"])
}

@Test func корневойРодительТожеСохраняется() throws {
    #expect(try планПроверки([("a", "new/a")]).препятствия.contains { $0.код == "несогласованный-родитель" })
}

@Test func внешняяИПроизводнаяГраницыНеПереименовываются() async throws {
    let снимок = СнимокПутей(коммит: "a", дерево: "b", ветка: "refs/heads/direction", индекс_sha256: "c",
        индекс_изменён: false, записи: [ЗаписьСнимкаПутей(путь: "Зависимости", тип: "каталог"),
            ЗаписьСнимкаПутей(путь: "Зависимости/LinguisticKit", тип: "внешняя-зависимость"),
            ЗаписьСнимкаПутей(путь: "Proyekcii", тип: "производный-слой")])
    let карта = try await ШтатноеОтображениеПутей.отобразить(снимок.записи)
    let план = try ПостроительПланаПутей.построить(снимок, отображения: карта, контекст: контекстПроверки(), хэшОтображения: "d")
    #expect(план.отображения.contains { $0.исходный == "Зависимости/LinguisticKit" && $0.целевой == $0.исходный })
    #expect(план.отображения.contains { $0.исходный == "Proyekcii" && $0.целевой == "Proyekcii" })
    #expect(план.препятствия.contains { $0.код == "отдельный-владелец-области" })
}

@Test func пропавшийОтслеживаемыйФайлНеТеряется() async throws {
    try await сДеревомПроверки { корень in
        try FileManager.default.removeItem(at: корень.appendingPathComponent("Каталог/Файл.md"))
        #expect(throws: ОшибкаПутей.self) { try ЧитательПутей.снять(корень: корень, области: ["Каталог"]) }
    }
}

@Test func поздняяПодменаРанееПрочитанногоФайлаОтвергается() async throws {
    try await сДеревомПроверки { корень in
        #expect(throws: ОшибкаПутей.self) {
            try ЧитательПутей.снять(корень: корень, области: ["Каталог"], послеЧтенияДляПроверки: {
                try Data("Поздняя запись\n".utf8).write(to: корень.appendingPathComponent("Каталог/Обзор.md"))
            })
        }
    }
}

@Test func классификацияИспользуетПринятуюПолитику() throws {
    let политика = try ПолитикаГраницПутей.принятая()
    #expect(политика.граница("a/__pycache__", каталог: true))
    #expect(политика.граница("a/compiler-cache", каталог: true))
    #expect(политика.граница(".obsidian/graph.json", каталог: false))
    #expect(!политика.граница("a/cache.swift", каталог: false))
}

@Test func подменаПолногоСохранённогоПланаОтвергается() throws {
    let исходный = try планПроверки([("a", "a")])
    let байты = try байтыПлана(исходный)
    try КомандаПутей.сверить(сохранённые: байты, ожидаемыйХэш: хэшПутей(байты), текущий: исходный)
    var изменённый = исходный
    изменённый.применение_разрешено = true
    let подмена = try байтыПлана(изменённый)
    #expect(throws: ОшибкаПутей.self) { try КомандаПутей.сверить(сохранённые: подмена, ожидаемыйХэш: хэшПутей(подмена), текущий: исходный) }
    изменённый = исходный
    изменённый.отображения[0].целевой = "b"
    let другоеИмя = try байтыПлана(изменённый)
    #expect(throws: ОшибкаПутей.self) { try КомандаПутей.сверить(сохранённые: другоеИмя, ожидаемыйХэш: хэшПутей(другоеИмя), текущий: исходный) }
}

@Test func параллельныеОбращенияКТаблицеИзолированыАктором() async throws {
    let вход = [ЗаписьСнимкаПутей(путь: "создать-краткую-запись.swift")]
    try await withThrowingTaskGroup(of: [ОтображениеПути].self) { группа in
        for _ in 0..<32 {
            let экземпляр = ТранслитераторПутей()
            группа.addTask { try await экземпляр.отобразить(вход) }
        }
        var число = 0
        for try await результат in группа {
            #expect(результат.map(\.целевой) == ["sozdatj-kratkuyu-zapisj.swift"])
            число += 1
        }
        #expect(число == 32)
    }
}

@Test func единственныйUnicodeАлиасСвязанСТемЖеИндекснымОбъектом() async throws {
    try await сДеревомПроверки { корень in
        let чтение = try ЧитательПутей.снять(корень: корень, области: ["Каталог"])
        let файл = try #require(чтение.снимок.записи.first { $0.путь.precomposedStringWithCanonicalMapping == "Каталог/Файл.md" })
        #expect(файл.путь_индекса == "Каталог/Файл.md")
        #expect(файл.объект != nil && файл.режим_индекса == "100644")
    }
}

@Test func дваUnicodeЭквивалентныхИндексныхИмениОтвергаются() async throws {
    try await сДеревомПроверки { корень in
        let объект = String(decoding: try гитПроверки(корень, ["hash-object", "--stdin"], вход: Data("Проверяемые байты\n".utf8)), as: UTF8.self).trimmingCharacters(in: .newlines)
        let другое = "Каталог/Фаи\u{306}л.md"
        _ = try гитПроверки(корень, ["-c", "core.precomposeUnicode=false", "update-index", "-z", "--index-info"],
            вход: Data("100644 \(объект)\t\(другое)\u{0000}".utf8))
        #expect(throws: ОшибкаПутей.self) { try ЧитательПутей.снять(корень: корень, области: ["Каталог"]) }
    }
}

@Test func регистровоеИмяНеПолучаетUnicodeЛьготу() async throws {
    try await сДеревомПроверки { корень in
        let объект = String(decoding: try гитПроверки(корень, ["rev-parse", "HEAD:Каталог/Обзор.md"]), as: UTF8.self).trimmingCharacters(in: .newlines)
        _ = try гитПроверки(корень, ["update-index", "--force-remove", "--", "Каталог/Обзор.md"])
        _ = try гитПроверки(корень, ["update-index", "-z", "--index-info"],
            вход: Data("100644 \(объект)\tКаталог/обзор.md\u{0000}".utf8))
        #expect(throws: ОшибкаПутей.self) { try ЧитательПутей.снять(корень: корень, области: ["Каталог"]) }
    }
}

@Test func исходныйUnicodeДвойникНеСкрываетсяВнутриБиблиотеки() async {
    await #expect(throws: ОшибкаПутей.self) {
        try await ШтатноеОтображениеПутей.отобразить([ЗаписьСнимкаПутей(путь: "K.swift")])
    }
}

@Test func занятыйUnicodeАлиасНеТеряется() throws {
    var контекст = контекстПроверки()
    контекст.занятые_пути = [ЗанятыйПуть(путь: "Файлы/live", владелец: "чужой")]
    let план = try планПроверки([("Фаи\u{306}лы", "Fajlyi"), ("Фаи\u{306}лы/файл", "Fajlyi/fajl")], контекст: контекст)
    #expect(план.препятствия.contains { $0.код == "чужой-писатель" })
}

@Test func существующееНазначениеВнеОбластиВыявляетсяБезЕгоОбхода() async throws {
    try await сДеревомПроверки { корень in
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("katalog"), withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(atPath: корень.appendingPathComponent("katalog/чужая-ссылка").path, withDestinationPath: "/")
        let план = try await КомандаПутей.построить(корень: корень,
            вход: ВходПланаПутей(контекст: контекстПроверки(), области: ["Каталог"]), хэшВхода: "вход")
        #expect(план.препятствия.contains { $0.код == "занятое-назначение" })
    }
}

@Test func переносНеполногоРодителяНеРазрешается() async throws {
    try await сДеревомПроверки { корень in
        let план = try await КомандаПутей.построить(корень: корень,
            вход: ВходПланаПутей(контекст: контекстПроверки(), области: ["Каталог/Файл.md"]), хэшВхода: "вход")
        #expect(план.препятствия.contains { $0.код == "неполный-перенос-каталога" })
    }
}
