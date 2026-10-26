import Foundation
import Testing

func сФикстуройИмени382(_ действие: (URL, ОписаниеПакета) throws -> Void) throws {
    let окружение = ProcessInfo.processInfo.environment
    let база = URL(fileURLWithPath: окружение["ФУМ_КАТАЛОГ_ФИКСТУР"]!)
    let корень = база.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: корень.appendingPathComponent("src"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: корень) }
    try Data("// Фикстура имени цели\n".utf8).write(to: корень.appendingPathComponent("src/a.swift"))
    let описание = try ОписаниеПакета.прочитать(Data(contentsOf: URL(fileURLWithPath: окружение["ФУМ_ОПИСАНИЕ_382"]!)))
    try действие(корень, описание)
}

@Suite struct ПроверкиИмёнЦелей382 {
    @Test func точноеПринятоеИмяСохраняется() throws {
        try сФикстуройИмени382 { корень, описание in
            let результат = try ГенераторМанифеста.породить(описание, корень: корень)
            #expect(результат.описание.цели[0].имя == "proverki-aktualizaciya-putej")
            #expect(String(decoding: результат.байты, as: UTF8.self)
                .contains(".testTarget(name: \"proverki-aktualizaciya-putej\""))
        }
    }

    @Test(arguments: ["A-B", "a_b", "Основа-Ёж"])
    func безопасныеСоставныеИменаСохраняются(имя: String) throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].имя = имя
            let результат = try ГенераторМанифеста.породить(описание, корень: корень)
            #expect(результат.описание.цели[0].имя == имя)
        }
    }

    @Test(arguments: ["", "-a", "a-", "a--b", "../a", "a/b", "a\\b", "a\n", "a\r", "a\u{0000}", "a\"b"])
    func неподдержанныеИменаОтказывают(имя: String) throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].имя = имя
            #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
        }
    }

    @Test func определениеОстаётсяИдентификатором() throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].определения = ["A-B"]
            do {
                _ = try ГенераторМанифеста.породить(описание, корень: корень)
                Issue.record("Недопустимое определение принято")
            } catch let ошибка as ОшибкаМанифеста { #expect(ошибка.код == "неверное-определение") }
        }
    }

    @Test(arguments: ["точный", "регистр", "нормализация"])
    func прежниеКоллизииНеОслаблены(случай: String) throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            try Data("// Второй исходник\n".utf8).write(to: корень.appendingPathComponent("src/b.swift"))
            if случай == "нормализация" { описание.цели[0].имя = "Цельё" }
            var вторая = описание.цели[0]
            вторая.исходники = ["b.swift"]
            if случай == "регистр" { вторая.имя = вторая.имя.uppercased() }
            if случай == "нормализация" { вторая.имя = "Целье\u{0308}" }
            описание.цели.append(вторая)
            #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
        }
    }

    @Test func ссылкиИспользуютСыроеИмяЦели() throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].имя = "a-b"
            описание.цели[0].вид = .обычная
            try Data("// Потребитель\n".utf8).write(to: корень.appendingPathComponent("src/b.swift"))
            описание.цели.append(.init(имя: "consumer-test", вид: .проверочная, путь: "src",
                зависимости: [.init(цель: "a-b")], исходники: ["b.swift"]))
            описание.продукты = [.init(имя: "Библиотека", вид: .библиотека, цели: ["a-b"])]
            let текст = String(decoding: try ГенераторМанифеста.породить(описание, корень: корень).байты, as: UTF8.self)
            #expect(текст.contains("targets: [\"a-b\"]"))
            #expect(текст.contains(".target(name: \"a-b\")"))
        }
    }

    @Test func сырыеИменаНеСливаютсяПоМодульномуПредставлению() throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].имя = "a-b"
            описание.цели[0].вид = .обычная
            try Data("// Второй модуль\n".utf8).write(to: корень.appendingPathComponent("src/b.swift"))
            описание.цели.append(.init(имя: "a_b", вид: .обычная, путь: "src", исходники: ["b.swift"]))
            let результат = try ГенераторМанифеста.породить(описание, корень: корень)
            #expect(результат.описание.цели.map(\.имя) == ["a-b", "a_b"])
        }
    }

    @Test func обходПутиОстаётсяОтказом() throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].путь = "../src"
            #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
        }
    }

    @Test(arguments: ["самоссылка", "отсутствие", "цикл"])
    func графСоставныхИмёнПроверяется(случай: String) throws {
        try сФикстуройИмени382 { корень, исходное in
            var описание = исходное
            описание.цели[0].имя = "a-b"
            описание.цели[0].вид = .обычная
            try Data("// Второй узел\n".utf8).write(to: корень.appendingPathComponent("src/b.swift"))
            описание.цели.append(.init(имя: "c-d", вид: .обычная, путь: "src", исходники: ["b.swift"]))
            switch случай {
            case "самоссылка": описание.цели[0].зависимости = [.init(цель: "a-b")]
            case "отсутствие": описание.цели[0].зависимости = [.init(цель: "нет-цели")]
            default:
                описание.цели[0].зависимости = [.init(цель: "c-d")]
                описание.цели[1].зависимости = [.init(цель: "a-b")]
            }
            #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
        }
    }

    @Test func настоящийDumpСохраняетТочноеПринятоеИмя() throws {
        try сФикстуройИмени382 { корень, описание in
            let манифест = try ГенераторМанифеста.породить(описание, корень: корень).байты
            try манифест.write(to: корень.appendingPathComponent("Package.swift"))
            let процесс = Process()
            процесс.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            процесс.arguments = ["swift", "package", "--package-path", корень.path,
                "--scratch-path", корень.appendingPathComponent("scratch").path,
                "--cache-path", корень.appendingPathComponent("cache").path,
                "--config-path", корень.appendingPathComponent("config").path,
                "--security-path", корень.appendingPathComponent("security").path,
                "--disable-sandbox", "dump-package"]
            процесс.environment = ProcessInfo.processInfo.environment.merging([
                "CLANG_MODULE_CACHE_PATH": корень.appendingPathComponent("modules").path,
                "SWIFTPM_MODULECACHE_OVERRIDE": корень.appendingPathComponent("modules").path
            ]) { _, новое in новое }
            let вывод = Pipe(), ошибки = Pipe()
            процесс.standardOutput = вывод; процесс.standardError = ошибки
            try процесс.run()
            let данные = вывод.fileHandleForReading.readDataToEndOfFile()
            let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
            процесс.waitUntilExit()
            #expect(процесс.terminationStatus == 0, "\(String(decoding: диагностика, as: UTF8.self))")
            let пакет = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
            let цели = try #require(пакет["targets"] as? [[String: Any]])
            #expect(цели.count == 1)
            #expect(цели[0]["name"] as? String == "proverki-aktualizaciya-putej")
            #expect(String(decoding: данные, as: UTF8.self).contains("strict-concurrency=complete"))
            let выход = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ФУМ_АРТЕФАКТЫ_382"]!)
            try данные.write(to: выход.appendingPathComponent("fixture-dump.json"))
            try манифест.write(to: выход.appendingPathComponent("fixture-Package.swift"))
            try описание.байты().write(to: выход.appendingPathComponent("fixture-description.json"))
        }
    }
}
