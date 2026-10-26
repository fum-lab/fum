import Foundation
import Testing
@testable import АктуализацияПутей

/// Использует принятый Names/LK837 целиком, включая сегментацию исходного CamelCase.
@Test func получитьКартуСвоихИмён() async throws {
    guard let выход = ProcessInfo.processInfo.environment["ФУМ_КАРТА_ИМЁН"] else { return }
    let область = "iskhodniki/perekhod-vetok/"
    let историческиеИмена = ["uzlyi/Полномочия.swift", "proverki/ПроверкиПолномочий.swift",
        "proverki/ПрофильПолномочий.swift", "uzlyi/opredeleniya/самостоятельность.json",
        "программа.json", "постановка-аудита.json", "постановка-наблюдения.json",
        "профиль-самостоятельности.json", "квитанция-цикла-1.json"]
    let имена: [String]
    if let вход = ProcessInfo.processInfo.environment["ФУМ_ИСХОДНЫЕ_ИМЕНА"] {
        имена = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: вход)))
    } else {
        имена = историческиеИмена.map { область + $0 }
    }
    for имя in имена {
        try ИменаПутей.проверитьПуть(имя)
        try #require(имя.hasPrefix(область))
    }
    let карта = try await ШтатноеОтображениеПутей.отобразить(имена.map {
        ЗаписьСнимкаПутей(путь: $0)
    })
    try #require(карта.count == имена.count)
    try #require(Set(карта.map { ИменаПутей.ключКоллизии($0.целевой) }).count == имена.count)
    try #require(карта.allSatisfy { $0.целевой.utf8.allSatisfy { $0 < 128 }
        && $0.целевой == $0.целевой.lowercased() && $0.целевой.hasPrefix(область) })
    var данные = try JSONSerialization.data(withJSONObject: [
        "схема": "fum.карта-имён-среза-материализации.1",
        "ревизия": "837e2ce107b97ee7b9d3344c9fe99142281fe393",
        "механизм": "Принятый ШтатноеОтображениеПутей: Unicode segmentation, LinguisticKit Cyrl→Latn.ru, ASCII до lowercase, kebab; не ручная транслитерация",
        "карта": карта.map { ["исходный": $0.исходный, "целевой": $0.целевой] },
        "граница": "Только вычисленная карта. Перенос, синтаксические ссылки, сохранение исторических свидетельств и отсутствие цели отдельно проверяет владелец"
    ], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    данные.append(10)
    try данные.write(to: URL(fileURLWithPath: выход), options: [.withoutOverwriting])
}
