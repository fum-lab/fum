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
