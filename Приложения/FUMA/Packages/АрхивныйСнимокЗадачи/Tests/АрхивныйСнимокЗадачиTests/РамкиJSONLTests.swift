import Foundation
import XCTest
@testable import АрхивныйСнимокЗадачи

final class ПроверкиРамокПотока: XCTestCase {
    func test_РамкиСохраняютПереводыИВозвратыСтрокПустуюСтрокуИХвост() throws {
        let исходные = Data([0x61, 0x0a, 0x0a, 0x62, 0x0d, 0x0a, 0xf0, 0x9f])
        let результат = try выделитьРамкиПотока(исходные)
        XCTAssertEqual(результат.рамки.map(\.данные), [Data([0x61, 0x0a]), Data([0x0a]), Data([0x62, 0x0d, 0x0a])])
        XCTAssertEqual(результат.рамки.map(\.позиция), [
            ПозицияСтроки(номер: 1, начало: 0, конец: 2, sha256: "87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7"),
            ПозицияСтроки(номер: 2, начало: 2, конец: 3, sha256: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"),
            ПозицияСтроки(номер: 3, начало: 3, конец: 6, sha256: "679e273f78fc8f8ba114db23c2dce80cc77c91083939825ca830152f2f080d08")])
        XCTAssertEqual(результат.префикс, ГраницаПрефикса(байты: 6, строки: 3,
            sha256: "22f4547d586ada74c538a29479406fffd43b88fc61e1eb3a4bc11542c5f0bb87"))
        XCTAssertEqual(результат.сыройХвост, Data([0xf0, 0x9f]))
        XCTAssertEqual(результат.пикБуфераСтроки, 3)
        for разрез in 0...исходные.count {
            let поток = try сканировать(исходные, разрезы: [разрез])
            XCTAssertEqual(поток.0.map(\.позиция), результат.рамки.map(\.позиция))
            XCTAssertEqual(поток.0.map(\.данные), результат.рамки.map(\.данные))
            XCTAssertEqual(поток.1.префикс, результат.префикс)
            XCTAssertEqual(поток.1.сыройХвост, Data([0xf0, 0x9f]))
            XCTAssertEqual(поток.1.прочитано, 8)
            XCTAssertEqual(поток.1.пикБуфераСтроки, 3)
        }
        for разрезы in [[1, 2, 3, 4, 5, 6, 7], [2, 4, 6]] {
            XCTAssertEqual(try сканировать(исходные, разрезы: разрезы).0.map(\.позиция), результат.рамки.map(\.позиция))
        }
        try сФайлом(исходные) { файл in
            var рамки: [РамкаПотока] = []
            let итог = try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) {
                рамки.append(РамкаПотока(данные: $0, позиция: $1))
            }
            XCTAssertEqual(рамки, результат.рамки)
            XCTAssertEqual(итог.0, результат.префикс)
            XCTAssertEqual(итог.1, 3)
        }
    }

    func test_ЭкранированиеСимволовИСрезНеМеняютГраницы() throws {
        let исходные = Data([0x7b, 0x22, 0x78, 0x22, 0x3a, 0x22, 0x5c, 0x6e,
            0xe2, 0x80, 0xa8, 0xe2, 0x80, 0xa9, 0x22, 0x7d, 0x0a])
        let результат = try выделитьРамкиПотока(исходные)
        XCTAssertEqual(результат.рамки.count, 1)
        XCTAssertEqual(результат.рамки.first?.данные, исходные)
        XCTAssertEqual(результат.рамки.first?.позиция, ПозицияСтроки(номер: 1, начало: 0, конец: 17,
            sha256: "0a7f9e40908605b2b19c1ea8727af8864444275cccc365cd5de7749a4c5178b8"))
        for разрез in 0...исходные.count {
            XCTAssertEqual(try сканировать(исходные, разрезы: [разрез]).0, результат.рамки)
        }
        let срез = Data([0x78, 0x61, 0x0a, 0x62]).dropFirst()
        XCTAssertNotEqual(срез.startIndex, 0)
        let рамкиСреза = try выделитьРамкиПотока(срез)
        XCTAssertEqual(рамкиСреза.рамки.first?.позиция, ПозицияСтроки(номер: 1, начало: 0, конец: 2,
            sha256: "87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7"))
        XCTAssertEqual(рамкиСреза.сыройХвост, Data([0x62]))
    }

    func test_ПустойВводИНезавершённыйХвостНеПолучаютПереводСтроки() throws {
        let пустой = try выделитьРамкиПотока(Data())
        XCTAssertEqual(пустой.рамки.count, 0)
        XCTAssertEqual(пустой.сыройХвост.count, 0)
        XCTAssertEqual(пустой.пикБуфераСтроки, 0)
        XCTAssertEqual(пустой.префикс, ГраницаПрефикса(байты: 0, строки: 0,
            sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"))
        let безПереводаСтроки = try выделитьРамкиПотока(Data([0x7b, 0x7d]))
        XCTAssertEqual(безПереводаСтроки.рамки.count, 0)
        XCTAssertEqual(безПереводаСтроки.сыройХвост, Data([0x7b, 0x7d]))
        XCTAssertEqual(безПереводаСтроки.пикБуфераСтроки, 2)
        let невернаяКодировка = try выделитьРамкиПотока(Data([0xff, 0x0a]))
        XCTAssertEqual(невернаяКодировка.рамки.map(\.данные), [Data([0xff, 0x0a])])
        XCTAssertEqual(невернаяКодировка.сыройХвост.count, 0)
    }

    func test_ПределыРамокВключаютПереводСтрокиИХвост() throws {
        var строка = Data(repeating: 0x61, count: 262_143)
        строка.append(0x0a)
        var полный = Data()
        for _ in 0..<4 { полный.append(строка) }
        XCTAssertEqual(try выделитьРамкиПотока(полный).рамки.count, 4)
        XCTAssertEqual(try выделитьРамкиПотока(Data(repeating: 0x0a, count: 128)).рамки.count, 128)
        XCTAssertEqual(try выделитьРамкиПотока(Data(repeating: 0x61, count: 262_144)).сыройХвост.count, 262_144)
        полный.append(0x61)
        XCTAssertThrowsError(try выделитьРамкиПотока(полный)) { XCTAssertEqual($0 as? ОшибкаАрхива, .предел) }
        XCTAssertThrowsError(try выделитьРамкиПотока(Data(repeating: 0x61, count: 262_145))) { XCTAssertEqual($0 as? ОшибкаАрхива, .предел) }
        XCTAssertThrowsError(try выделитьРамкиПотока(Data(repeating: 0x0a, count: 129))) { XCTAssertEqual($0 as? ОшибкаАрхива, .предел) }
        XCTAssertThrowsError(try ПределыРамокПотока(байты: 1_048_577))
        XCTAssertThrowsError(try ПределыРамокПотока(строка: 262_145))
        XCTAssertThrowsError(try ПределыРамокПотока(рамки: 129))
        XCTAssertThrowsError(try ПределыРамокПотока(байты: 0))
        XCTAssertThrowsError(try выделитьРамкиПотока(Data([0x61, 0x0a]),
            пределы: ПределыРамокПотока(строка: 1)))
        var бюджет = БюджетАрхива()
        бюджет.байты = 4
        let сканер = СканерРамокПотока(бюджет: бюджет, прежняя: nil)
        var вызовы = 0
        try Data([0x61, 0x0a]).withUnsafeBytes { буфер in
            try сканер.принять(буфер.bindMemory(to: UInt8.self)) { _, _ in вызовы += 1 }
        }
        XCTAssertThrowsError(try Data([0x62, 0x0a, 0x78]).withUnsafeBytes { буфер in
            try сканер.принять(буфер.bindMemory(to: UInt8.self)) { _, _ in вызовы += 1 }
        }) { XCTAssertEqual($0 as? ОшибкаАрхива, .предел) }
        XCTAssertEqual(вызовы, 1)
    }

    func test_ПрежнийПрефиксПроверяетсяДоГраничногоОбработчика() throws {
        let исходные = Data([0x61, 0x0a, 0x62, 0x0a])
        let прежняя = ГраницаПрефикса(байты: 2, строки: 1,
            sha256: "87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7")
        XCTAssertEqual(try сканировать(исходные, разрезы: [1, 3], прежняя: прежняя).0.count, 2)
        try сФайлом(исходные) { файл in
            var вызовы = 0
            _ = try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: прежняя) { _, _ in вызовы += 1 }
            XCTAssertEqual(вызовы, 2)
            let неверные = [ГраницаПрефикса(байты: 2, строки: 1, sha256: String(repeating: "0", count: 64)),
                ГраницаПрефикса(байты: 2, строки: 2, sha256: прежняя.sha256),
                ГраницаПрефикса(байты: 1, строки: 1, sha256: прежняя.sha256),
                ГраницаПрефикса(байты: 0, строки: 0, sha256: прежняя.sha256)]
            for неверная in неверные {
                вызовы = 0
                XCTAssertThrowsError(try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: неверная) { _, _ in вызовы += 1 }) {
                    XCTAssertEqual($0 as? ОшибкаАрхива, .подменаПрефикса)
                }
                XCTAssertEqual(вызовы, 0)
                let сканер = СканерРамокПотока(бюджет: БюджетАрхива(), прежняя: неверная)
                XCTAssertThrowsError(try исходные.withUnsafeBytes { буфер in
                    try сканер.принять(буфер.bindMemory(to: UInt8.self)) { _, _ in вызовы += 1 }
                }) { XCTAssertEqual($0 as? ОшибкаАрхива, .подменаПрефикса) }
                XCTAssertEqual(вызовы, 0)
            }
            let заКонцомФайла = ГраницаПрефикса(байты: 6, строки: 3, sha256: прежняя.sha256)
            вызовы = 0
            XCTAssertThrowsError(try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: заКонцомФайла) { _, _ in вызовы += 1 }) {
                XCTAssertEqual($0 as? ОшибкаАрхива, .подменаПрефикса)
            }
            XCTAssertEqual(вызовы, 0)
            let сканер = СканерРамокПотока(бюджет: БюджетАрхива(), прежняя: заКонцомФайла)
            try исходные.withUnsafeBytes { буфер in
                try сканер.принять(буфер.bindMemory(to: UInt8.self)) { _, _ in вызовы += 1 }
            }
            XCTAssertEqual(вызовы, 2)
            XCTAssertThrowsError(try сканер.завершить()) { XCTAssertEqual($0 as? ОшибкаАрхива, .подменаПрефикса) }
        }
        XCTAssertThrowsError(try сканировать(Data(), разрезы: [], прежняя:
            ГраницаПрефикса(байты: 0, строки: 0, sha256: прежняя.sha256)))
    }

    private enum МеткаОтказа: Error { case обработчик }

    func test_ОшибкаОбработчикаИИзменениеФайлаСохраняютПорядок() throws {
        let исходные = Data([0x61, 0x0a, 0x62, 0x0a])
        try сФайлом(исходные) { файл in
            var вызовы = 0
            XCTAssertThrowsError(try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) { _, _ in
                вызовы += 1
                try исходные.write(to: файл, options: .atomic)
                throw МеткаОтказа.обработчик
            }) { XCTAssertNotNil($0 as? МеткаОтказа) }
            XCTAssertEqual(вызовы, 1)
        }
        try сФайлом(исходные) { файл in
            var вызовы = 0
            XCTAssertThrowsError(try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) { _, _ in
                вызовы += 1
                if вызовы == 1 { try исходные.write(to: файл, options: .atomic) }
            }) { XCTAssertEqual($0 as? ОшибкаАрхива, .источникИзменился) }
            XCTAssertEqual(вызовы, 2)
        }
    }

    func test_ФайловыйБлокИПотоковыеОбработчикиСовпадаютССканером() throws {
        for конецВторой in [262_144, 262_145] {
            var исходные = Data([0x61, 0x0a])
            исходные.append(Data(repeating: 0x62, count: конецВторой - 3))
            исходные.append(contentsOf: [0x0a, 0x63, 0x0a])
            let фасад = try выделитьРамкиПотока(исходные)
            XCTAssertEqual(фасад.рамки.map { $0.позиция.конец }, [2, конецВторой, конецВторой + 2])
            XCTAssertEqual(фасад.пикБуфераСтроки, конецВторой - 2)
            let поток = try сканировать(исходные, разрезы: [262_144])
            XCTAssertEqual(поток.0, фасад.рамки)
            try сФайлом(исходные) { файл in
                var рамки: [РамкаПотока] = []
                let итог = try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) {
                    рамки.append(РамкаПотока(данные: $0, позиция: $1))
                }
                XCTAssertEqual(рамки, фасад.рамки)
                XCTAssertEqual(итог.0, фасад.префикс)
                XCTAssertEqual(итог.1, конецВторой - 2)
            }
        }
        var длинная = Data(repeating: 0x61, count: 262_144)
        длинная.append(0x0a)
        XCTAssertThrowsError(try выделитьРамкиПотока(длинная))
        try сФайлом(длинная) { файл in
            var сохранённая = Data()
            let итог = try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) { данные, _ in сохранённая = данные }
            XCTAssertEqual(сохранённая, длинная)
            XCTAssertEqual(итог.0.байты, 262_145)
            XCTAssertEqual(итог.1, 262_145)
        }
    }

    func test_ПрофильРамокНаПолномВходе() throws {
        var строка = Data(repeating: 0x61, count: 262_143)
        строка.append(0x0a)
        var исходные = Data()
        for _ in 0..<4 { исходные.append(строка) }
        let эталон = try выделитьРамкиПотока(исходные)
        var замерыДанных: [UInt64] = []
        var замерыФайла: [UInt64] = []
        try сФайлом(исходные) { файл in
            for повтор in 0..<25 {
                func измеритьДанные() throws {
                    let начало = DispatchTime.now().uptimeNanoseconds
                    let результат = try выделитьРамкиПотока(исходные)
                    let длительность = DispatchTime.now().uptimeNanoseconds - начало
                    XCTAssertEqual(результат, эталон)
                    замерыДанных.append(длительность)
                }
                func измеритьФайл() throws {
                    var рамки: [РамкаПотока] = []
                    let начало = DispatchTime.now().uptimeNanoseconds
                    let итог = try прочитатьПрефикс(файл, бюджет: БюджетАрхива(), прежняя: nil) {
                        рамки.append(РамкаПотока(данные: $0, позиция: $1))
                    }
                    let длительность = DispatchTime.now().uptimeNanoseconds - начало
                    XCTAssertEqual(рамки, эталон.рамки)
                    XCTAssertEqual(итог.0, эталон.префикс)
                    XCTAssertEqual(итог.1, 262_144)
                    замерыФайла.append(длительность)
                }
                if повтор % 2 == 0 { try измеритьДанные(); try измеритьФайл() }
                else { try измеритьФайл(); try измеритьДанные() }
            }
        }
        let профиль: [String: Any] = ["схема": "fuma.профиль-рамок-JSONL.1",
            "байты": исходные.count, "рамки": 4, "sha256": хэшАрхива(исходные),
            "пикБуфераСтроки": эталон.пикБуфераСтроки,
            "Data_наносекунды": замерыДанных, "файл_наносекунды": замерыФайла,
            "граница": "Debug; 25 чередующихся повторов; SHA и рамки; файл дополнительно включает read/stat. Подготовка фикстуры, сборка и сравнение результатов вне замера; пик означает длину строки, не RSS."]
        let байты = try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys, .withoutEscapingSlashes])
        print("ПРОФИЛЬ_РАМОК_JSONL:" + String(decoding: байты, as: UTF8.self))
    }

    private func сканировать(_ данные: Data, разрезы: [Int], прежняя: ГраницаПрефикса? = nil) throws
        -> ([РамкаПотока], ИтогСканераПотока) {
        let сканер = СканерРамокПотока(бюджет: БюджетАрхива(), прежняя: прежняя)
        var рамки: [РамкаПотока] = []
        try данные.withUnsafeBytes { сырые in
            let буфер = сырые.bindMemory(to: UInt8.self)
            var начало = 0
            for конец in разрезы + [буфер.count] {
                try сканер.принять(UnsafeBufferPointer(rebasing: буфер[начало..<конец])) {
                    рамки.append(РамкаПотока(данные: $0, позиция: $1))
                }
                начало = конец
            }
        }
        return (рамки, try сканер.завершить())
    }

    private func сФайлом(_ данные: Data, действие: (URL) throws -> Void) throws {
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: каталог) }
        let файл = каталог.appendingPathComponent("вход.jsonl")
        try данные.write(to: файл)
        try действие(файл)
    }
}
