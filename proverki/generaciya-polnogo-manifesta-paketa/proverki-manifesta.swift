import Foundation
import Testing

func сФикстуройМанифеста(_ действие: (URL, ОписаниеПакета) throws -> Void) throws {
    let база = ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.temporaryDirectory
    let корень = база.resolvingSymlinksInPath()
        .appendingPathComponent("fum-manifest-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: корень) }
    for путь in ["src/a.swift", "src/main.swift", "tests/test.swift", "dep/Package.swift", "dep/source/a.swift", "src/data.txt"] {
        let файл = корень.appendingPathComponent(путь)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("// Фикстура\n".utf8).write(to: файл)
    }
    try Data("// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: \"dep\", products: [.library(name: \"Dependency\", targets: [\"Dependency\"])], targets: [.target(name: \"Dependency\", path: \"source\")])\n".utf8)
        .write(to: корень.appendingPathComponent("dep/Package.swift"))
    let описание = ОписаниеПакета(имя: "Пакет", платформы: [.init(платформа: .макОС, версия: "14.0")],
        продукты: [.init(имя: "library", вид: .библиотека, цели: ["Основа"]),
                   .init(имя: "run", вид: .исполняемый, цели: ["Команда"])],
        зависимости: [.init(имя: "dep", путь: "dep", продукты: ["Dependency"])],
        цели: [.init(имя: "Основа", вид: .обычная, путь: "src", исключения: ["main.swift", "data.txt"]),
               .init(имя: "Команда", вид: .исполняемая, путь: "src", зависимости: [.init(цель: "Основа")],
                     исключения: ["a.swift", "data.txt"], исходники: ["main.swift"]),
               .init(имя: "Проверки", вид: .проверочная, путь: "tests", зависимости: [.init(цель: "Основа")])])
    try действие(корень, описание)
}

private func процессМанифеста(_ корень: URL, _ аргументы: [String], вход: Data? = nil) throws -> (CInt, Data, Data) {
    let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    процесс.arguments = аргументы; процесс.currentDirectoryURL = корень
    процесс.environment = ProcessInfo.processInfo.environment.merging([
        "CLANG_MODULE_CACHE_PATH": корень.appendingPathComponent("modules").path,
        "SWIFTPM_MODULECACHE_OVERRIDE": корень.appendingPathComponent("modules").path
    ]) { _, новое in новое }
    let выход = Pipe(); let ошибки = Pipe(); let ввод = Pipe()
    процесс.standardOutput = выход; процесс.standardError = ошибки; процесс.standardInput = ввод
    try процесс.run()
    if let вход { try ввод.fileHandleForWriting.write(contentsOf: вход) }
    try ввод.fileHandleForWriting.close()
    let байты = выход.fileHandleForReading.readDataToEndOfFile()
    let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    return (процесс.terminationStatus, байты, диагностика)
}

@Test func настоящийМенеджерПакетовПринимаетМанифестБезСети() throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное
        описание.имя = "Пакет\"\\\n\t\\(fatalError())"
        описание.цели[0].зависимости = [.init(продукт: "Dependency", пакет: "dep")]
        описание.цели[0].исключения = ["main.swift"]
        описание.цели[0].ресурсы = [.init(вид: .копировать, путь: "data.txt")]
        let результат = try ГенераторМанифеста.породить(описание, корень: корень)
        try результат.байты.write(to: корень.appendingPathComponent("Package.swift"))
        let до = try Data(contentsOf: корень.appendingPathComponent("Package.swift"))
        let (код, данные, ошибки) = try процессМанифеста(корень, ["swift", "package", "--disable-sandbox",
            "--scratch-path", корень.appendingPathComponent("scratch").path,
            "--cache-path", корень.appendingPathComponent("cache").path,
            "--config-path", корень.appendingPathComponent("config").path,
            "--security-path", корень.appendingPathComponent("security").path, "dump-package"])
        #expect(код == 0, "\(String(decoding: ошибки, as: UTF8.self))")
        let пакет = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        #expect(пакет["name"] as? String == описание.имя)
        let цели = try #require(пакет["targets"] as? [[String: Any]])
        #expect(цели.count == 3)
        #expect((пакет["dependencies"] as? [Any])?.count == 1)
        #expect((пакет["products"] as? [Any])?.count == 2)
        let текст = String(decoding: данные, as: UTF8.self)
        #expect(текст.contains("strict-concurrency=complete"))
        #expect(текст.contains("warnings-as-errors"))
        #expect(текст.contains("enable-actor-data-race-checks"))
        #expect(текст.contains("swiftLanguageMode"))
        #expect(текст.contains("data.txt"))
        #expect(try Data(contentsOf: корень.appendingPathComponent("Package.swift")) == до)
    }
}

@Test(arguments: ["// previous\n", "a\r\nb\r\n", "a", ""])
func полнаяРазницаПрименяетсяИПовторСтановитсяПустой(текст: String) throws {
    try сФикстуройМанифеста { корень, описание in
        let старый = Data(текст.utf8)
        try старый.write(to: корень.appendingPathComponent("Package.swift"))
        let результат = try ГенераторМанифеста.породить(описание, корень: корень, прежний: старый)
        let (код, _, ошибки) = try процессМанифеста(корень, ["git", "apply", "-"], вход: Data(результат.текстРазницы.utf8))
        #expect(код == 0, "\(String(decoding: ошибки, as: UTF8.self))")
        #expect(try Data(contentsOf: корень.appendingPathComponent("Package.swift")) == результат.байты)
    }
}

@Test(arguments: ["\n", "\r\n"])
func строгиеИменаНеПринимаютКонечныйПереводСтроки(хвост: String) throws {
    #expect(!ПроверкаМанифеста.идентификатор("Основа" + хвост))
    try сФикстуройМанифеста { корень, исходное in
        var определение = исходное; определение.цели[0].определения = ["ФЛАГ" + хвост]
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(определение, корень: корень) }
        var платформа = исходное; платформа.платформы[0].версия = "14.0" + хвост
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(платформа, корень: корень) }
    }
}

@Test(arguments: ["схема", #"\u0441хема"#])
func повторКлючаНеСхлопываетсяВПарсере(ключ: String) throws {
    try сФикстуройМанифеста { _, описание in
        let строка = String(decoding: try описание.байты(), as: UTF8.self)
        let дубль = Data(("{\"" + ключ + "\":\"fum.описание-пакета.1\"," + строка.dropFirst()).utf8)
        #expect(throws: ОшибкаМанифеста.self) { try ОписаниеПакета.прочитать(дубль) }
    }
}

@Test func полныйМанифестПовторяетБайты() throws {
    try сФикстуройМанифеста { корень, описание in
        let первый = try ГенераторМанифеста.породить(описание, корень: корень)
        let второй = try ГенераторМанифеста.породить(описание, корень: корень)
        #expect(первый.байты == второй.байты)
        let текст = String(decoding: первый.байты, as: UTF8.self)
        #expect(текст.hasPrefix("// swift-tools-version: 6.0\n"))
        #expect(текст.contains(".testTarget("))
        #expect(текст.contains("-strict-concurrency=complete"))
        #expect(текст.contains("-warnings-as-errors"))
        #expect(текст.contains("-enable-actor-data-race-checks"))
        #expect(текст.contains("swiftLanguageModes: [.v6]"))
        #expect(первый.текстРазницы.hasPrefix("--- a/Package.swift\n+++ b/Package.swift\n"))
        #expect(try ГенераторМанифеста.породить(описание, корень: корень, прежний: первый.байты).текстРазницы == "")
    }
}

@Test func форматированноеОписаниеЗамыкается() throws {
    try сФикстуройМанифеста { _, описание in
        let байты = try описание.байты()
        #expect(байты.last == 10)
        #expect(String(decoding: байты, as: UTF8.self).contains("\n  \""))
        #expect(try ОписаниеПакета.прочитать(байты) == описание)
        var поля = try #require(JSONSerialization.jsonObject(with: байты) as? [String: Any])
        поля["исполняемый_swift"] = "fatalError()"
        #expect(throws: ОшибкаМанифеста.self) { try ОписаниеПакета.прочитать(JSONSerialization.data(withJSONObject: поля)) }
    }
}

@Test(arguments: ["дубль", "цель", "цикл", "пакет", "продукт", "исходники", "исключения", "определение", "вид", "коллизия"])
func неверныеСвязиОтклоняются(случай: String) throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное
        switch случай {
        case "дубль": описание.цели.append(описание.цели[0])
        case "цель": описание.цели[0].зависимости = [.init(цель: "Нет")]
        case "цикл": описание.цели[0].зависимости = [.init(цель: "Команда")]
        case "пакет": описание.цели[0].зависимости = [.init(продукт: "Dependency", пакет: "нет")]
        case "продукт": описание.продукты[0].цели = ["Проверки"]
        case "исходники": описание.цели[1].исходники = ["a.swift", "main.swift"]; описание.цели[1].исключения = ["data.txt"]
        case "исключения": описание.цели[0].исходники = ["main.swift"]
        case "определение": описание.цели[0].определения = ["X); fatalError()"]
        case "вид": описание.продукты[1].цели = ["Основа"]
        default: описание.цели.append(.init(имя: "основа", вид: .обычная, путь: "src"))
        }
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
    }
}

@Test(arguments: ["../src", "/src", "src//x", "src/./x", "src/../src", "src\\x", ".git", "src\u{0000}x"])
func небезопасныеПутиОтклоняются(путь: String) throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное; описание.цели[0].путь = путь
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
    }
}

@Test(arguments: ["src/link.swift", "dep/link", "link"])
func символическиеКомпонентыОтклоняются(путь: String) throws {
    try сФикстуройМанифеста { корень, исходное in
        try FileManager.default.createSymbolicLink(atPath: корень.appendingPathComponent(путь).path, withDestinationPath: корень.appendingPathComponent("src").path)
        var описание = исходное
        if путь == "dep/link" { описание.зависимости[0].путь = путь }
        if путь == "link" { описание.цели[0].путь = путь }
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень) }
    }
}

@Test func данныеСтрокНеСтановятсяКодом() throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное
        описание.имя = "Пакет\"\\\n\t\\(fatalError())"
        let текст = String(decoding: try ГенераторМанифеста.породить(описание, корень: корень).байты, as: UTF8.self)
        #expect(текст.contains(String(reflecting: описание.имя)))
    }
}

@Test func ресурсыИЗависимостьПорождаютсяТипизированно() throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное
        описание.цели[0].исключения = ["main.swift"]
        описание.цели[0].ресурсы = [.init(вид: .копировать, путь: "data.txt")]
        описание.цели[0].определения = ["ФУМ_ПРОВЕРКА"]
        описание.цели[0].зависимости = [.init(продукт: "Dependency", пакет: "dep")]
        let текст = String(decoding: try ГенераторМанифеста.породить(описание, корень: корень).байты, as: UTF8.self)
        #expect(текст.contains(".product(name: \"Dependency\", package: \"dep\")"))
        #expect(текст.contains(".copy(\"data.txt\")"))
        #expect(текст.contains(".define(\"ФУМ_ПРОВЕРКА\")"))
    }
}

@Test func картаРодителяМеняетПолныйАдресИСохраняетМодули() throws {
    try сФикстуройМанифеста { корень, описание in
        let карта = Data(#"{"схема":"fum.план-актуализации-путей.1","отображения":[{"исходный":"src","целевой":"new-src"},{"исходный":"src/main.swift","целевой":"new-src/run.swift"}],"препятствия":[],"применение_разрешено":false}"#.utf8)
        let результат = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        #expect(результат.описание.цели[1].путь == "new-src")
        #expect(результат.описание.цели[1].исходники == ["run.swift"])
        #expect(результат.описание.цели[0].исключения.contains("run.swift"))
        #expect(результат.описание.цели[1].имя == "Команда")
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("new-src").path))
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: String(repeating: "0", count: 64)) }
        let чужой = Data(String(decoding: карта, as: UTF8.self).replacingOccurrences(of: "new-src/run.swift", with: "outside/run.swift").utf8)
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень, карта: чужой, хэшКарты: хэшМанифеста(чужой)) }
    }
}

@Test(arguments: ["символический-префикс", "невыбранный-файл", "занятый-каталог"])
func назначениеКартыНеОбходитФайловыеГраницы(случай: String) throws {
    try сФикстуройМанифеста { корень, исходное in
        var описание = исходное
        let старый: String; let новый: String
        if случай == "символический-префикс" {
            try FileManager.default.createSymbolicLink(atPath: корень.appendingPathComponent("mapped").path, withDestinationPath: "/")
            старый = "src"; новый = "mapped"
        } else if случай == "занятый-каталог" {
            старый = "src"; новый = "tests"
        } else {
            старый = "src/a.swift"; новый = "src/data.txt"
            описание.цели = [описание.цели[0]]; описание.продукты = [описание.продукты[0]]
        }
        let карта = try JSONSerialization.data(withJSONObject: ["схема": "fum.план-актуализации-путей.1", "отображения": [["исходный": старый, "целевой": новый]], "препятствия": [], "применение_разрешено": false])
        #expect(throws: ОшибкаМанифеста.self) { try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта)) }
    }
}
