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

@Test func внешнийПрефиксНеДобавляетНеучтённыйИсходник() throws {
    try сБудущимиИсходниками { корень, описание in
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("extra"), withIntermediateDirectories: false)
        try Data("// Внешний для целей исходник\n".utf8).write(to: корень.appendingPathComponent("extra/e.swift"))
        #expect(try ПроверкаМанифеста.файлы(описание, корень: корень).все == ["src/s1.swift", "tests/t.swift"])
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests"), ("extra", "new-src/sub")])
        #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("new-src").path))
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test(arguments: ["внутри", "предок", "затенение"])
func непокрытыйПрообразБудущегоКорняДаётЯвныйОтказ(положение: String) throws {
    try сБудущимиИсходниками { корень, описание in
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("extra/src"), withIntermediateDirectories: true)
        try Data("// Неучтённый исходник\n".utf8).write(to: корень.appendingPathComponent("extra/src/e.swift"))
        var пары = положение != "предок"
            ? [("src", "new-src"), ("tests", "new-tests"), ("extra", "new-src/sub")]
            : [("src", "new-root/src"), ("tests", "new-tests"), ("extra", "new-root")]
        if положение == "затенение" { пары.append(("extra/src", "unrelated")) }
        let карта = try картаБудущихИсходников(пары)
        do {
            _ = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
            Issue.record("Принят непокрытый прообраз будущего корня")
        } catch let ошибка as ОшибкаМанифеста { #expect(ошибка.код == "неполный-инвентарь-карты") }
    }
}

@Test func независимаяВнешняяКартаНеТребуетРасширенияИнвентаря() throws {
    try сБудущимиИсходниками { корень, описание in
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("extra"), withIntermediateDirectories: false)
        try Data("// Посторонний исходник\n".utf8).write(to: корень.appendingPathComponent("extra/e.swift"))
        let обычная = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests")])
        let внешняя = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests"), ("extra", "unrelated")])
        let до = try ГенераторМанифеста.породить(описание, корень: корень, карта: обычная, хэшКарты: хэшМанифеста(обычная))
        let после = try ГенераторМанифеста.породить(описание, корень: корень, карта: внешняя, хэшКарты: хэшМанифеста(внешняя))
        #expect(до.байты == после.байты)
        #expect(после.описание.цели.allSatisfy { $0.исходники == nil })
    }
}

@Test func покрытыйПрообразНеТребуетПолнотыВсегоРодителя() throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/own"), withIntermediateDirectories: false)
        try FileManager.default.moveItem(at: корень.appendingPathComponent("src/s1.swift"),
                                        to: корень.appendingPathComponent("src/own/s1.swift"))
        try Data("// Вне цели\n".utf8).write(to: корень.appendingPathComponent("src/outside.swift"))
        описание.цели[0].путь = "src/own"
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests")])
        let результат = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        #expect(результат.описание.цели[0].путь == "new-src/own")
        #expect(результат.описание.цели.allSatisfy { $0.исходники == nil })
    }
}

@Test(arguments: ["extra", "tests"])
func неоднозначныйРегистрНазначенияНеСкрываетВнешнийПрефикс(источник: String) throws {
    try сБудущимиИсходниками { корень, описание in
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("extra"), withIntermediateDirectories: false)
        try Data("// Неучтённый исходник\n".utf8).write(to: корень.appendingPathComponent("extra/e.swift"))
        let пары = источник == "extra"
            ? [("src", "new-src"), ("tests", "new-tests"), ("extra", "NEW-SRC/sub")]
            : [("src", "new-src"), ("tests", "NEW-SRC/sub")]
        let карта = try картаБудущихИсходников(пары)
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test func манифестЗависимостиНеДоказываетПолнотуЕёКаталога() throws {
    try сФикстуройМанифеста { корень, описание in
        let инвентарь = try ПроверкаМанифеста.файлы(описание, корень: корень).все
        #expect(инвентарь.contains("dep/Package.swift"))
        #expect(!инвентарь.contains("dep/source/a.swift"))
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests"), ("dep", "new-src/dep")])
        do {
            _ = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
            Issue.record("Манифест зависимости ошибочно подтвердил полноту каталога")
        } catch let ошибка as ОшибкаМанифеста { #expect(ошибка.код == "неполный-инвентарь-карты") }
    }
}

@Test(arguments: ["SRC", "src/S1.swift"])
func неоднозначныйРегистрИсточникаНеСкрываетПеренос(путь: String) throws {
    try сБудущимиИсходниками { корень, описание in
        let карта = try картаБудущихИсходников([(путь, "moved"), ("tests", "new-tests")])
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test(arguments: ["исключение", "ресурс"])
func неоднозначноеНазначениеНеОбходитЗащищённуюГраницу(граница: String) throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/hidden"), withIntermediateDirectories: false)
        if граница == "исключение" { описание.цели[0].исключения = ["hidden"] }
        else { описание.цели[0].ресурсы = [.init(вид: .копировать, путь: "hidden")] }
        let карта = try картаБудущихИсходников([("src", "new-src"), ("tests", "new-tests"),
                                              ("src/s1.swift", "new-src/HIDDEN/s1.swift")])
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test(arguments: ["файл", "каталог", "прообраз", "полное-покрытие"])
func отображённыйИнвентарьНеСкрываетВложениеВДругомРегистре(выбор: String) throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        let относительный = выбор == "каталог" ? "dir/HIDDEN/t.swift" : "HIDDEN/t.swift"
        let файл = корень.appendingPathComponent("tests/" + относительный)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: корень.appendingPathComponent("tests/t.swift"), to: файл)
        описание.цели[1].исходники = [выбор == "каталог" ? "dir" : относительный]
        let пары: [(String, String)]
        if выбор == "прообраз" || выбор == "полное-покрытие" {
            try FileManager.default.createDirectory(at: корень.appendingPathComponent("src/parent/hidden"), withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: корень.appendingPathComponent("src/s1.swift"),
                                            to: корень.appendingPathComponent("src/parent/hidden/s1.swift"))
            описание.цели[0].путь = "src/parent/hidden"
            if выбор == "полное-покрытие" {
                try Data("// Независимый явный исходник\n".utf8).write(to: корень.appendingPathComponent("src/parent/safe.swift"))
                описание.цели.append(.init(имя: "Дополнение", вид: .обычная, путь: "src/parent", исходники: ["safe.swift"]))
            }
            пары = [("src", "new-root"), ("tests", "new-root/parent")]
        } else {
            let назначение = выбор == "файл" ? "new-src/hidden" : "new-src/dir/hidden"
            пары = [("src", назначение), ("tests", "new-src")]
        }
        _ = try ГенераторМанифеста.породить(описание, корень: корень)
        let карта = try картаБудущихИсходников(пары)
        #expect(throws: ОшибкаМанифеста.self) {
            try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
        }
    }
}

@Test(arguments: ["HIDDEN", "hidden"])
func триПокрытыеЦелиРазличаютАлиасИОбычноеПересечение(сегмент: String) throws {
    try сБудущимиИсходниками { корень, исходное in
        var описание = исходное
        try FileManager.default.removeItem(at: корень.appendingPathComponent("src/s1.swift"))
        try FileManager.default.removeItem(at: корень.appendingPathComponent("tests/t.swift"))
        for путь in ["src/foo/" + сегмент + "/t.swift", "other/control.swift", "other/hidden/s1.swift"] {
            let файл = корень.appendingPathComponent(путь)
            try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("// Три раздельные цели\n".utf8).write(to: файл)
        }
        описание.цели = [.init(имя: "Основа", вид: .обычная, путь: "src", исходники: ["foo/" + сегмент + "/t.swift"]),
                         .init(имя: "Контроль", вид: .обычная, путь: "other", исходники: ["control.swift"]),
                         .init(имя: "Автоподбор", вид: .обычная, путь: "other/hidden")]
        _ = try ГенераторМанифеста.породить(описание, корень: корень)
        let карта = try картаБудущихИсходников([("src", "new-src"), ("other", "new-src/foo")])
        do {
            _ = try ГенераторМанифеста.породить(описание, корень: корень, карта: карта, хэшКарты: хэшМанифеста(карта))
            Issue.record("Будущее вложение осталось незамеченным")
        } catch let ошибка as ОшибкаМанифеста {
            #expect(ошибка.код == (сегмент == "HIDDEN" ? "неоднозначная-граница-карты" : "пересечение-исходников"))
        }
    }
}
