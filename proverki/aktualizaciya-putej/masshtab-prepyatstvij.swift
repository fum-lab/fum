import Foundation
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

private final class СчётчикРавенстваПутей {
    var число = 0
}

private struct НаблюдаемоеПрепятствие: Hashable {
    var значение: ПрепятствиеПути
    var счётчик: СчётчикРавенстваПутей

    static func == (левое: Self, правое: Self) -> Bool {
        левое.счётчик.число += 1
        return левое.значение == правое.значение
    }

    func hash(into хэшер: inout Hasher) { значение.hash(into: &хэшер) }
}

private struct ВходМасштабаПутей {
    var снимок: СнимокПутей
    var отображения: [ОтображениеПути]
    var контекст: КонтекстПутей

    init(файлов: Int) {
        let пути = ["data"] + (0..<файлов).map { "data/f\($0)" }
        снимок = СнимокПутей(коммит: String(repeating: "a", count: 40),
            дерево: String(repeating: "b", count: 40), ветка: "refs/heads/direction",
            индекс_sha256: String(repeating: "c", count: 64), индекс_изменён: false,
            записи: пути.enumerated().map { номер, путь in
                ЗаписьСнимкаПутей(путь: путь, тип: номер == 0 ? "каталог" : "файл", sha256: "байты")
            })
        отображения = пути.map { ОтображениеПути(исходный: $0, целевой: $0) }
        контекст = КонтекстПутей(корень: "узел/репозиторий/направление", владелец: "писатель",
            писатель: "писатель", целевая_ветка: "refs/heads/direction",
            занятые_пути: [ЗанятыйПуть(путь: "data", владелец: "другой")])
    }

    func построить() throws -> ПланПутей {
        try ПостроительПланаПутей.построить(снимок, отображения: отображения,
            контекст: контекст, хэшОтображения: String(repeating: "d", count: 64))
    }
}

@Test func дедупликацияСохраняетПорядокИОграничиваетСравнения() throws {
    let число = 1024
    let счётчик = СчётчикРавенстваПутей()
    var наблюдаемый = УпорядоченныйНаборПутей<НаблюдаемоеПрепятствие>()
    for номер in 0..<число {
        наблюдаемый.добавить(НаблюдаемоеПрепятствие(
            значение: ПрепятствиеПути(код: "чужой-писатель", пути: ["data/f\(номер)"]), счётчик: счётчик))
    }
    #expect(счётчик.число <= 16 * число)
    #expect(наблюдаемый.значения.count == число)

    let первое = ПрепятствиеПути(код: "помеха", пути: ["data/e\u{301}"])
    let равное = ПрепятствиеПути(код: "помеха", пути: ["data/é"])
    #expect(первое == равное)
    var представители = УпорядоченныйНаборПутей<ПрепятствиеПути>()
    представители.добавить(первое); представители.добавить(равное)
    #expect(try байтыПлана(представители.значения) == байтыПлана([первое]))

    let вход = ВходМасштабаПутей(файлов: число)
    let план = try вход.построить()
    #expect(план.препятствия.count == число + 1)
    #expect(план.препятствия.allSatisfy { $0.код == "чужой-писатель" })
    #expect(try байтыПлана(план) == байтыПлана(вход.построить()))
    var переставленный = вход
    переставленный.снимок.записи.reverse()
    переставленный.отображения.reverse()
    переставленный.контекст.занятые_пути += вход.контекст.занятые_пути
    #expect(try байтыПлана(план) == байтыПлана(переставленный.построить()))
}

private struct ЗамерМасштабаПутей: Codable {
    var файлов: Int
    var препятствий: Int
    var длительности_нс: [UInt64]
    var хэш_плана: String
}

private struct ПрофильМасштабаПутей: Codable {
    var схема = "fum.профиль-дедупликации-препятствий.1"
    var метка: String
    var занятых_областей = 1
    var подготовка_вне_измерения = true
    var сериализация_вне_измерения = true
    var повторов = 5
    var исходники: [String: String]
    var замеры: [ЗамерМасштабаПутей]
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["FUM_PROFILE_OUT"] != nil))
func измеритьСлучайЧужогоПисателя() throws {
    let среда = ProcessInfo.processInfo.environment
    let корень = URL(fileURLWithPath: try #require(среда["FUM_PROFILE_ROOT"])).resolvingSymlinksInPath()
    let выход = URL(fileURLWithPath: try #require(среда["FUM_PROFILE_OUT"]))
    try #require(выход.path == выход.resolvingSymlinksInPath().path)
    let свойства = try FileManager.default.attributesOfItem(atPath: выход.deletingLastPathComponent().path)
    try #require((свойства[.posixPermissions] as? NSNumber)?.intValue == 0o700)
    var предок = выход.deletingLastPathComponent()
    while true {
        guard !FileManager.default.fileExists(atPath: предок.appendingPathComponent(".git").path) else {
            throw ОшибкаПутей.отказ("Профиль должен сохраняться вне Git")
        }
        let родитель = предок.deletingLastPathComponent()
        if родитель.path == предок.path { break }
        предок = родитель
    }
    let пути = ["Package.swift", "iskhodniki/aktualizaciya-putej/chteniye-snimka.swift",
        "iskhodniki/aktualizaciya-putej/modelj-plana.swift", "iskhodniki/aktualizaciya-putej/postroyeniye-plana.swift",
        "iskhodniki/aktualizaciya-putej/proveritj-puti.swift", "iskhodniki/aktualizaciya-putej/proverka-imyon.swift",
        "proverki/aktualizaciya-putej/proverki-putej.swift", "proverki/aktualizaciya-putej/masshtab-prepyatstvij.swift",
        "Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json"]
    func хэши() throws -> [String: String] {
        try Dictionary(uniqueKeysWithValues: пути.map {
            ($0, try хэшПутей(Data(contentsOf: корень.appendingPathComponent($0))))
        })
    }
    let до = try хэши()
    let входы = [1000, 2000, 4000].map { ВходМасштабаПутей(файлов: $0) }
    var замеры: [ЗамерМасштабаПутей] = []
    for (число, вход) in zip([1000, 2000, 4000], входы) {
        var времена: [UInt64] = []
        var ожидаемые: Data?
        for _ in 0..<5 {
            let начало = DispatchTime.now().uptimeNanoseconds
            let план = try вход.построить()
            времена.append(DispatchTime.now().uptimeNanoseconds - начало)
            let байты = try байтыПлана(план)
            if let ожидаемые { #expect(байты == ожидаемые) } else { ожидаемые = байты }
            #expect(план.препятствия.count == число + 1)
        }
        замеры.append(ЗамерМасштабаПутей(файлов: число, препятствий: число + 1,
            длительности_нс: времена, хэш_плана: хэшПутей(try #require(ожидаемые))))
    }
    #expect(try хэши() == до)
    let профиль = ПрофильМасштабаПутей(метка: try #require(среда["FUM_PROFILE_LABEL"]),
        исходники: до, замеры: замеры)
    try байтыПлана(профиль).write(to: выход, options: .withoutOverwriting)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: выход.path)
}
