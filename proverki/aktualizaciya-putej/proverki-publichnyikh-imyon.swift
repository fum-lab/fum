import Foundation
import CryptoKit
import Testing
import АктуализацияПутей

@Test(arguments: [("ModeljPlana.swift", "modelj-plana.swift"), ("XMLParser", "xml-parser"), ("SKILL.md", "skill.md"),
                  ("ПубличныйФасадИмён", "publichnyij-fasad-imyon")])
func публичныеИменаПреобразуютКомпонент(пара: (String, String)) async throws {
    let результат = try await ПубличныйФасадИмён.канонизировать(пара.0)
    #expect(результат.значение == пара.1)
}

@Test(arguments: ["а/б", "а\\б", "..", "AGENTS.md", "Package.swift", "K"])
func публичныеИменаОтклоняютОпасныеКомпоненты(компонент: String) async {
    await #expect(throws: (any Error).self) {
        try await ПубличныйФасадИмён.канонизировать(компонент)
    }
}

@Test func публичныеИменаЗакрепляютИсточники() async throws {
    let результат = try await ПубличныйФасадИмён.канонизировать("XMLParser")
    let происхождение = результат.происхождение
    #expect(происхождение.алгоритм == "fum.пути.unicode-boundary.Cyrl-Latn.ru.ascii-lower-kebab.1")
    #expect(происхождение.коммит == "c6af44bf1ec061675b6205b9c6ee889d98264f28")
    #expect(происхождение.путьЗависимости == "Зависимости/LinguisticKit")
    #expect(происхождение.ревизияЗависимости == "837e2ce107b97ee7b9d3344c9fe99142281fe393")
    #expect(происхождение.исходники.map(\.путь) == [
        "iskhodniki/aktualizaciya-putej/proverka-imyon.swift",
        "iskhodniki/aktualizaciya-putej/chteniye-snimka.swift"
    ])
    let корень = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    for исходник in происхождение.исходники {
        let байты = try Data(contentsOf: корень.appendingPathComponent(исходник.путь))
        let хэш = SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
        #expect(хэш == исходник.хэш)
    }
    // Объявленный gitlink отдельно сверяется с Git-деревом в предполёте писателя.
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["FUM_ПРОФИЛЬ_ИМЁН"] == "1"))
func профильПубличныхИмён() async throws {
    let исходное = "ПубличныйФасадИмён"
    var последнее = try await ПубличныйФасадИмён.канонизировать(исходное)
    let часы = ContinuousClock()
    let начало = часы.now
    for _ in 0..<1000 {
        последнее = try await ПубличныйФасадИмён.канонизировать(исходное)
    }
    let части = начало.duration(to: часы.now).components
    let наносекунды = части.seconds * 1_000_000_000 + части.attoseconds / 1_000_000_000
    #expect(последнее.значение == "publichnyij-fasad-imyon")
    let отчёт: [String: Any] = [
        "схема": "fum.профиль-публичных-имён.1", "исходное": исходное,
        "повторения": 1000, "длительность_наносекунды": наносекунды,
        "алгоритм": последнее.происхождение.алгоритм,
        "коммит_алгоритма": последнее.происхождение.коммит,
        "граница": "Один прогрев вне интервала, затем последовательный цикл публичных вызовов; сборка и запуск тестов вне интервала."
    ]
    let байты = try JSONSerialization.data(withJSONObject: отчёт, options: [.sortedKeys])
    print(String(decoding: байты, as: UTF8.self))
}

@Test(arguments: [
    (["Инструменты", "ИменаКаталогов", "ПубличныйФасадИмён"],
     "refs/heads/fum-lab/fum/instrumentyi/imena-katalogov/publichnyij-fasad-imyon/master"),
    (["instrumentyi", "imena-katalogov", "publichnyij-fasad-imyon"],
     "refs/heads/fum-lab/fum/instrumentyi/imena-katalogov/publichnyij-fasad-imyon/master"),
    (["Ёж"], "refs/heads/fum-lab/fum/yozh/master"),
    (["release.v2", "chastj-7"], "refs/heads/fum-lab/fum/release.v2/chastj-7/master")
])
func полныеСсылкиСоставляютТочноеНаправление(случай: ([String], String)) async throws {
    let ссылка = try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: случай.0)
    #expect(ссылка.значение == случай.1)
    #expect(ссылка.алгоритмСоставления == "fum.полная-ссылка-ветки.1")
    #expect(ссылка.компоненты.map(\.исходное) == случай.0)
    for компонент in ссылка.компоненты {
        let имя = try await ПубличныйФасадИмён.канонизировать(компонент.исходное)
        #expect(компонент.имя == имя)
        #expect(имя.происхождение.коммит == "c6af44bf1ec061675b6205b9c6ee889d98264f28")
        #expect(имя.происхождение.ревизияЗависимости == "837e2ce107b97ee7b9d3344c9fe99142281fe393")
    }
    let байты = try JSONEncoder().encode(ссылка)
    #expect(try JSONDecoder().decode(ПолнаяСсылкаВетки.self, from: байты) == ссылка)
}

private let отказныеПутиПолнойСсылки: [[String]] = [
    [], [""], ["a", ""], ["a/b"], ["a//b"], ["a\\b"],
    ["a\0b"], ["a\nb"], ["a\rb"], ["a\tb"], ["a\u{7F}b"], ["a\u{85}b"],
    ["."], [".."], [".a"], ["a."], ["a..b"], ["a.lock"], ["a.LOCK"],
    ["a@{b"], ["a~b"], ["a^b"], ["a:b"], ["a?b"], ["a*b"], ["a[b"], ["a]b"],
    ["a b"], ["a_b"], ["a--b"], ["-a"], ["a-"], ["a.-b"], ["a-.b"],
    ["Ёж  Дом"], [" Ёж"], ["Ёж "], ["Е\u{308}ж"], ["K"], ["Π"], ["🙂"],
    ["XMLParser"], ["AGENTS.md"], ["agents.md"], ["Package.swift"], ["package.swift"],
    ["SKILL.md"], ["skill.md"], ["АGENTS.md"],
    ["a", "a"], ["а", "a"], ["А", "а"], ["Ёж", "ёж"],
    ["refs/heads/a"], ["a/master"], [String(repeating: "a", count: 256)]
]

@Test(arguments: отказныеПутиПолнойСсылки)
func полныеСсылкиЗакрытоОтклоняютВход(компоненты: [String]) async {
    await #expect(throws: (any Error).self) {
        try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: компоненты)
    }
}

@Test func полныеСсылкиПроверяютБайтовуюГраницу() async throws {
    let компоненты = [
        "a" + String(repeating: "x", count: 247),
        "b" + String(repeating: "x", count: 247),
        "c" + String(repeating: "x", count: 247),
        "d" + String(repeating: "x", count: 246)
    ]
    let ссылка = try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: компоненты)
    #expect(ссылка.значение.utf8.count == 1024)
    var длиннее = компоненты
    длиннее[3] += "x"
    await #expect(throws: (any Error).self) {
        try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: длиннее)
    }
    let предельный = String(repeating: "a", count: 255)
    let короткая = try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: [предельный])
    #expect(короткая.компоненты[0].имя.значение == предельный)
    await #expect(throws: (any Error).self) {
        try await ПубличныйФасадИмён.составитьПолнуюСсылку(из: Array(repeating: "a", count: 1000))
    }
}
