import Foundation
import Testing
import АрхивныйСнимокЗадачи

@Test func профильПоследовательныхРамок() throws {
    var строка = Data(repeating: 0x61, count: 4_095)
    строка.append(0x0a)
    var порция = Data()
    for _ in 0..<16 { порция.append(строка) }

    let повторов = 7
    let порций = 64
    let байтов = порция.count * порций
    let рамок = 16 * порций
    let пределы = try ПределыПоследовательныхРамок(порция: порция.count,
        строка: строка.count, рамки: рамок, байты: байтов)
    var создание: [UInt64] = []
    var приём: [UInt64] = []
    var завершение: [UInt64] = []
    var всего: [UInt64] = []

    for повтор in 0..<повторов {
        let началоВсего = DispatchTime.now().uptimeNanoseconds
        let началоСоздания = DispatchTime.now().uptimeNanoseconds
        let поток = try ПоследовательныеРамкиJSONL(начальноеСмещение: 1_000_000_000,
            пределы: пределы)
        создание.append(DispatchTime.now().uptimeNanoseconds - началоСоздания)

        var вызовы = 0
        var смещение = 1_000_000_000
        let началоПриёма = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<порций {
            смещение = try поток.принять(порция, смещение: смещение) { _ in вызовы += 1 }
        }
        приём.append(DispatchTime.now().uptimeNanoseconds - началоПриёма)

        let началоЗавершения = DispatchTime.now().uptimeNanoseconds
        let итог = try поток.завершить()
        завершение.append(DispatchTime.now().uptimeNanoseconds - началоЗавершения)
        всего.append(DispatchTime.now().uptimeNanoseconds - началоВсего)

        #expect(вызовы == рамок)
        #expect(итог.префикс.байты == байтов)
        #expect(итог.префикс.строки == рамок)
        #expect(итог.сыройХвост.isEmpty)
        #expect(итог.следующееСмещение == 1_000_000_000 + байтов)
        #expect(итог.пикБуфераСтроки == строка.count)
        #expect(повтор < повторов)
    }

    let профиль: [String: Any] = [
        "схема": "fuma.профиль-последовательных-рамок-jsonl.1",
        "режим": "Debug; Swift 6; complete concurrency; warnings as errors; actor data-race checks",
        "повторов": повторов,
        "байты_потока": байтов,
        "байты_порции": порция.count,
        "байты_строки": строка.count,
        "callbacks": рамок,
        "пик_буфера_строки": строка.count,
        "создание_наносекунды": создание.map(Int64.init),
        "приём_наносекунды": приём.map(Int64.init),
        "завершение_наносекунды": завершение.map(Int64.init),
        "всего_наносекунды": всего.map(Int64.init),
        "граница": "Синтетическая повторяемая порция Data; без файла и RAW. Всего включает создание, приём и завершение; стадии вложены и отдельно не суммируются. Подготовка порции, проверки результата и JSON-представление вне замера. Пик — длина текущей строки, не RSS."
    ]
    let данные = try JSONSerialization.data(withJSONObject: профиль,
        options: [.sortedKeys, .withoutEscapingSlashes])
    print("ПРОФИЛЬ_ПОСЛЕДОВАТЕЛЬНЫХ_РАМОК_JSONL:" + String(decoding: данные, as: UTF8.self))
}
