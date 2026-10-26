import Foundation
import CryptoKit
import Testing
@testable import МатериализацияУзлов

func закрепленияСамостоятельности() throws -> [String: String] {
    let пути = ["Package.swift", "iskhodniki/perekhod-vetok/uzlyi/Полномочия.swift",
        "iskhodniki/perekhod-vetok/uzlyi/opredeleniya/самостоятельность.json",
        "iskhodniki/perekhod-vetok/proverki/ПроверкиПолномочий.swift",
        "iskhodniki/perekhod-vetok/proverki/ПрофильПолномочий.swift"]
    return try Dictionary(uniqueKeysWithValues: пути.map { путь in
        (путь, SHA256.hash(data: try Data(contentsOf: URL(fileURLWithPath: путь)))
            .map { String(format: "%02x", $0) }.joined())
    })
}

@Test func профильСамостоятельности() throws {
    guard let путь = ProcessInfo.processInfo.environment["ФУМ_ПРОФИЛЬ_ПОЛНОМОЧИЙ"] else { return }
    let закрепления = try закрепленияСамостоятельности()
    var входы: [УсловияСамостоятельности] = [обычнаяРабота()]
    var исправление = обычнаяРабота()
    исправление.локальнаяИсправимаяПроблема = true
    входы.append(исправление)
    for основание in ОснованиеОбращения.allCases {
        var условия = обычнаяРабота()
        switch основание {
        case .неизвестныйОпасныйЭффект: условия.неизвестныйОпасныйЭффект = true
        case .чужаяОбласть: условия.свояОбласть = false
        case .нужныПолномочия: условия.естьПолномочия = false
        case .безопасноеПродолжениеНевозможно: условия.можноБезопасноПродолжать = false
        case .нетПолезногоПродвижения: условия.естьПолезноеПродвижение = false
        }
        входы.append(условия)
    }
    var независимое = обычнаяРабота()
    независимое.неизвестныйОпасныйЭффект = true
    независимое.доступнаНезависимаяРабота = true
    входы.append(независимое)
    var замеры: [Int64] = []
    for _ in 0..<3 {
        let начало = ContinuousClock.now
        let решения = try входы.map { try СамостоятельностьУзла.решить($0) }
        let части = начало.duration(to: ContinuousClock.now).components
        замеры.append(части.seconds * 1_000_000_000 + части.attoseconds / 1_000_000_000)
        #expect(решения.map(\.действие) == [.действоватьСамостоятельно, .исправлятьСамостоятельно,
            .сообщитьРодителю, .сообщитьРодителю, .сообщитьРодителю,
            .сообщитьРодителю, .сообщитьРодителю, .сообщитьИПродолжитьНезависимое])
    }
    #expect(try закрепленияСамостоятельности() == закрепления)
    var данные = try JSONSerialization.data(withJSONObject: [
        "схема": "fum.профиль-самостоятельности-узла.1",
        "режим": "Debug; три последовательных набора по восемь решений",
        "входов_в_наборе": входы.count, "повторов": замеры.count,
        "наносекунды_набора": замеры, "закрепления": закрепления,
        "граница": "Включены чтение ресурса, разбор определения, JSON encode, исполнение FUMA и decode. Сборка, подготовка входов и host/модель не входят. Кэш ОС не сбрасывался; ускорение не заявлено",
        "оптимизация": "Алгоритм сохранён: измеряется конечное управляющее решение, частота рабочего потока не измерена; оснований добавлять кэш или ослаблять проверку определения нет"
    ], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    данные.append(10)
    try данные.write(to: URL(fileURLWithPath: путь), options: [.withoutOverwriting])
}
