import Foundation
import Testing
#if !ФУМ_АДАПТЕР_ПОЛИТИКИ_ТЕСТ
@testable import АктуализацияПутей
#endif

@Suite("Адресный JSON-адаптер policy путей")
struct ПроверкиАдаптераПолитики {
    let корень = КорневоеОтображениеМиграции(исходный: "Инструменты", целевой: "instrumentyi", источникИмени: "проверочная-фикстура")
    let строка = Data("let путь = \"/tmp/fixture\"\n".utf8)
    var хэшСтроки: String { "sha256:" + ОбщийПланировщикПутей.хэш(Data("let путь = \"/tmp/fixture\"".utf8)) }
    func политика(_ путь: String = "Инструменты/a.swift") -> Data {
        Data("""
        {
          "schema": "fum.machine-local-path-policy.v3",
          "exceptions": [
            {"id": "fixture", "path": "\(путь)", "kind": "posix-absolute", "line_sha256": "\(хэшСтроки)", "count": 1, "category": "allow.test-fixture", "reason": "Инструменты/остаётся-дословно"}
          ],
          "метаданные": []
        }

        """.utf8)
    }
    func план(_ данные: Data, файлы: [Data: БайтыПроверкиИсключений]? = nil) throws -> ПланМиграцииПолитики {
        try АдаптерПолитикиЛокальныхПутей.построить(данные, ожидаемыйSHA256: ОбщийПланировщикПутей.хэш(данные), корни: [корень],
            файлы: файлы ?? [Data("Инструменты/a.swift".utf8): .init(прежде: строка, после: строка)])
    }

    @Test("Меняется только строковый value-token указанного path")
    func точныйСелектор() throws {
        let данные = политика(), результат = try план(данные)
        let ожидаемые = String(decoding: данные, as: UTF8.self).replacingOccurrences(of: "\"path\": \"Инструменты/a.swift\"", with: "\"path\": \"instrumentyi/a.swift\"")
        #expect(результат.будущиеБайты == Data(ожидаемые.utf8))
        #expect(результат.правки.map(\.указатель) == ["/exceptions/0/path"])
        #expect(результат.препятствия.isEmpty)
        #expect(!результат.применениеРазрешено)
    }

    @Test("Похожий prefix не меняется, line SHA и причина сохраняются")
    func границаПрефикса() throws {
        let данные = политика("Инструменты-другое/a.swift"), результат = try план(данные)
        #expect(результат.будущиеБайты == данные)
        #expect(результат.правки.isEmpty)
    }

    @Test("Дубликаты JSON-полей и экранированные дубликаты закрываются")
    func повторныеКлючи() throws {
        for данные in [Data("{\"path\":1,\"path\":2}".utf8), Data(#"{"path":1,"pa\u0074h":2}"#.utf8)] {
            #expect(throws: (any Error).self) { try ТокеныJSONМиграции.разобрать(данные) }
        }
    }

    @Test("Указатели и диапазоны считаются по точным UTF-8 байтам")
    func диапазоныJSON() throws {
        let данные = Data(#"{"a/b":{"~":["ё🙂","x"]}}"#.utf8)
        let результат = try ТокеныJSONМиграции.разобрать(данные)
        let строка = try #require(результат.строки.first { $0.указатель == "/a~1b/~0/0" })
        #expect(строка.значение == "ё🙂")
        #expect(данные.subdata(in: строка.диапазон) == Data("\"ё🙂\"".utf8))
    }

    @Test("Дрейф SHA и неизвестная схема не дают план правки")
    func происхождение() throws {
        #expect(throws: (any Error).self) { try АдаптерПолитикиЛокальныхПутей.построить(политика(), ожидаемыйSHA256: String(repeating: "0", count: 64), корни: [корень]) }
        let неизвестная = Data(String(decoding: политика(), as: UTF8.self).replacingOccurrences(of: "fum.machine-local-path-policy.v3", with: "unknown").utf8)
        #expect(throws: (any Error).self) { try план(неизвестная) }
    }

    @Test("Изменённая строка не получает автоматический новый line SHA")
    func изменённыеИсходники() throws {
        for файлы in [[Data: БайтыПроверкиИсключений](), [Data("Инструменты/a.swift".utf8): .init(прежде: строка, после: Data("изменено\n".utf8))]] {
            let результат = try план(политика(), файлы: файлы)
            #expect(!результат.препятствия.isEmpty)
            #expect(String(decoding: результат.будущиеБайты, as: UTF8.self).contains(хэшСтроки))
            #expect(!результат.применениеРазрешено)
        }
    }

    @Test("Data slice сохраняет логические byte ranges без чужого префикса")
    func срезДанных() throws {
        let исходные = политика(), сПолем = Data(repeating: 32, count: 8) + исходные
        let срез = сПолем.dropFirst(8)
        #expect(срез.startIndex != 0)
        let результат = try план(срез)
        #expect(результат.будущиеБайты == (try план(исходные)).будущиеБайты)
    }

    @Test("Новые совпадающие policy identities не разрешаются переносом")
    func коллизияИсключений() throws {
        let данные = политика()
        let объект = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        var исключение = try #require((объект["exceptions"] as? [[String: Any]])?.first)
        var второе = исключение; второе["id"] = "fixture-2"; второе["path"] = "instrumentyi/a.swift"
        исключение["id"] = "fixture-1"
        let оба = try JSONSerialization.data(withJSONObject: ["schema": "fum.machine-local-path-policy.v3", "exceptions": [исключение, второе], "метаданные": []], options: [.sortedKeys, .prettyPrinted])
        let результат = try план(оба, файлы: [Data("Инструменты/a.swift".utf8): .init(прежде: строка, после: строка), Data("instrumentyi/a.swift".utf8): .init(прежде: строка, после: строка)])
        #expect(!результат.препятствия.isEmpty)
    }

    @Test("Недопустимая категория, count и форма metadata закрываются")
    func поляКонтракта() throws {
        let текст = String(decoding: политика(), as: UTF8.self)
        for неверный in [текст.replacingOccurrences(of: "allow.test-fixture", with: "test.fixture"),
            текст.replacingOccurrences(of: "\"count\": 1", with: "\"count\": 17"),
            текст.replacingOccurrences(of: "\"метаданные\": []", with: "\"метаданные\": false")] {
            #expect(throws: (any Error).self) { try план(Data(неверный.utf8)) }
        }
    }

    @Test("Экранированный путь меняется без пересериализации причины")
    func экранированныйПуть() throws {
        let текст = String(decoding: политика(), as: UTF8.self).replacingOccurrences(of: "/", with: #"\/"#)
        let результат = try план(Data(текст.utf8))
        let ожидаемый = текст.replacingOccurrences(of: #""path": "Инструменты\/a.swift""#, with: #""path": "instrumentyi/a.swift""#)
        #expect(результат.будущиеБайты == Data(ожидаемый.utf8))
        #expect(!результат.контекстПолитикиПроверен)
    }

    @Test("Адресный Git-снимок policy: селекторы меняются, остальное сохраняется",
          .enabled(if: ProcessInfo.processInfo.environment["ФУМ_ПОЛИТИКА_ИСТОЧНИК"] != nil))
    func адреснаяПолитика() throws {
        let среда = ProcessInfo.processInfo.environment
        let путь = try #require(среда["ФУМ_ПОЛИТИКА_ИСТОЧНИК"]), хэш = try #require(среда["ФУМ_ХЭШ_ПОЛИТИКИ"])
        let исключенияТекст = try #require(среда["ФУМ_ЧИСЛО_ИСКЛЮЧЕНИЙ"]), переносыТекст = try #require(среда["ФУМ_ЧИСЛО_ПЕРЕНОСОВ"])
        let числоИсключений = try #require(Int(исключенияТекст)), числоПереносов = try #require(Int(переносыТекст))
        let данные = try Data(contentsOf: URL(fileURLWithPath: путь))
        let результат = try АдаптерПолитикиЛокальныхПутей.построить(данные, ожидаемыйSHA256: хэш, корни: [корень])
        let до = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        let после = try #require(JSONSerialization.jsonObject(with: результат.будущиеБайты) as? [String: Any])
        let прежние = try #require(до["exceptions"] as? [[String: Any]]), будущие = try #require(после["exceptions"] as? [[String: Any]])
        #expect(прежние.count == числоИсключений); #expect(будущие.count == числоИсключений)
        #expect(результат.правки.count == числоПереносов)
        for номер in прежние.indices {
            for поле in ["id", "kind", "line_sha256", "count", "category", "reason"] {
                #expect((прежние[номер][поле] as? NSObject)?.isEqual(будущие[номер][поле]) == true)
            }
            let прежнийПуть = try #require(прежние[номер]["path"] as? String), будущийПуть = try #require(будущие[номер]["path"] as? String)
            let ожидаемый = прежнийПуть.hasPrefix("Инструменты/") ? "instrumentyi/" + прежнийПуть.dropFirst("Инструменты/".count) : прежнийПуть
            #expect(Data(будущийПуть.utf8) == Data(ожидаемый.utf8))
        }
        let метка = Data("\"метаданные\": ".utf8)
        let прежде = try #require(данные.range(of: метка)), теперь = try #require(результат.будущиеБайты.range(of: метка))
        #expect(данные.suffix(from: прежде.lowerBound) == результат.будущиеБайты.suffix(from: теперь.lowerBound))
        let прежниеТокены = Dictionary(uniqueKeysWithValues: try ТокеныJSONМиграции.разобрать(данные).строки.map { (Data($0.указатель.utf8), $0.диапазон) })
        func внеПравокРавно(_ будущиеБайты: Data) throws -> Bool {
            let будущиеТокены = Dictionary(uniqueKeysWithValues: try ТокеныJSONМиграции.разобрать(будущиеБайты).строки.map { (Data($0.указатель.utf8), $0.диапазон) })
            var прежнийКурсор = 0, будущийКурсор = 0
            for правка in результат.правки.sorted(by: { $0.диапазон.lowerBound < $1.диапазон.lowerBound }) {
                let старый = try #require(прежниеТокены[Data(правка.указатель.utf8)]), новый = try #require(будущиеТокены[Data(правка.указатель.utf8)])
                if данные.subdata(in: прежнийКурсор..<старый.lowerBound) != будущиеБайты.subdata(in: будущийКурсор..<новый.lowerBound) { return false }
                прежнийКурсор = старый.upperBound; будущийКурсор = новый.upperBound
            }
            return данные.suffix(from: прежнийКурсор) == будущиеБайты.suffix(from: будущийКурсор)
        }
        #expect(try внеПравокРавно(результат.будущиеБайты))
        #expect(try !внеПравокРавно(Data([10]) + результат.будущиеБайты))
        #expect(результат.препятствия.count == числоПереносов)
        #expect(результат.препятствия.allSatisfy { $0.код == "не-проверены-байты-исключения" })
        #expect(!результат.применениеРазрешено); #expect(!результат.контекстПолитикиПроверен)
        if let выход = среда["ФУМ_ПЛАН_ПОЛИТИКИ"] {
            let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            try (кодировщик.encode(результат) + Data([10])).write(to: URL(fileURLWithPath: выход), options: .withoutOverwriting)
        }
    }
}

#if ФУМ_АДАПТЕР_ПОЛИТИКИ_ТЕСТ && !ФУМ_ОБЩАЯ_МИГРАЦИЯ_ТЕСТ
@main struct ЗапускПроверокПолитики { static func main() async { let код: CInt = await Testing.__swiftPMEntryPoint(); exit(код) } }
#endif
