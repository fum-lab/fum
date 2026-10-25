import Foundation
import Testing

private func сБудущимиИсходниками(_ действие: (URL, ОписаниеПакета) throws -> Void) throws {
    let база = ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.temporaryDirectory
    let корень = база.resolvingSymlinksInPath().appendingPathComponent("fum-future-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: корень) }
    for путь in ["src/s1.swift", "tests/t.swift"] {
        let файл = корень.appendingPathComponent(путь)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("// Фикстура\n".utf8).write(to: файл)
    }
    let описание = ОписаниеПакета(имя: "Пакет", платформы: [.init(платформа: .макОС, версия: "14.0")],
        продукты: [], цели: [.init(имя: "Основа", вид: .обычная, путь: "src"),
                            .init(имя: "Проверки", вид: .обычная, путь: "tests")])
    try действие(корень, описание)
}

private func картаБудущихИсходников(_ пары: [(String, String)]) throws -> Data {
    try JSONSerialization.data(withJSONObject: ["схема": "fum.план-актуализации-путей.1",
        "отображения": пары.map { ["исходный": $0.0, "целевой": $0.1] },
        "препятствия": [], "применение_разрешено": false], options: [.sortedKeys])
}

@Test func вложениеАвтоматическихЦелейОтклоняетсяНаБудущемСоставе() throws {
    try сБудущимиИсходниками { корень, описание in
        let исходное = try ГенераторМанифеста.породить(описание, корень: корень)
        #expect(исходное.описание.цели.allSatisfy { $0.исходники == nil })
        #expect(try ПроверкаМанифеста.файлы(описание, корень: корень).исходники == ["src/s1.swift", "tests/t.swift"])
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-src/sub")])
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("new-src").path))
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test func независимыеБудущиеКорниСохраняютАвтоподбор() throws {
    try сБудущимиИсходниками { корень, описание in
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests")])
        let результат = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        #expect(результат.описание.цели.map(\.путь) == ["new-src", "new-tests"])
        #expect(результат.описание.цели.allSatisfy { $0.исходники == nil })
    }
}

@Test(arguments: ["исключение", "ресурс", "файл", "каталог"])
func явнаяГраницаБудущегоСоставаСохраняется(граница: String) throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/sub"), withIntermediateDirectories: false)
        switch граница {
        case "исключение": описание.цели[0].исключения = ["sub"]
        case "ресурс": описание.цели[0].ресурсы = [.init(вид: .копировать, путь: "sub")]
        case "файл": описание.цели[0].исходники = ["s1.swift"]
        default:
            try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/own"), withIntermediateDirectories: false)
            try FileManager.default.moveItem(at: корень.appendingPathComponent("src/s1.swift"),
                                            to: корень.appendingPathComponent("src/own/s1.swift"))
            описание.цели[0].исходники = ["own"]
        }
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-src/sub")])
        let результат = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        #expect(результат.описание.цели[0].исходники == описание.цели[0].исходники)
        #expect(результат.описание.цели[1].исходники == nil)
        #expect(результат.описание.цели[0].исключения == описание.цели[0].исключения)
        #expect(результат.описание.цели[0].ресурсы.map(\.путь) == описание.цели[0].ресурсы.map(\.путь))
    }
}

@Test func явныйКаталогНеРазрешаетНовыйЧужойИсходник() throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/own"), withIntermediateDirectories: false)
        try FileManager.default.moveItem(at: корень.appendingPathComponent("src/s1.swift"),
                                        to: корень.appendingPathComponent("src/own/s1.swift"))
        описание.цели[0].исходники = ["own"]
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-src/own/sub")])
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test(arguments: ["исключение", "ресурс"])
func выходЗаГраницуНеДобавляетАвтоматическийИсходник(граница: String) throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/hidden"), withIntermediateDirectories: false)
        try Data("// Скрытый исходник\n".utf8).write(to: корень.appendingPathComponent("src/hidden/h.swift"))
        if граница == "исключение" { описание.цели[0].исключения = ["hidden"] }
        else { описание.цели[0].ресурсы = [.init(вид: .копировать, путь: "hidden")] }
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests"),
                                              ("src/hidden/h.swift", "new-src/h.swift")])
        do {
            _ = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
            Issue.record("Карта добавила исходник из защищённой области")
        } catch let ошибка as ОшибкаМанифеста {
            #expect(ошибка.код == "карта-меняет-состав-исходников")
        }
    }
}
