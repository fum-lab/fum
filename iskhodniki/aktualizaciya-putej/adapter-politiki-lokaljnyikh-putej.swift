import Foundation

struct БайтыПроверкиИсключений: Sendable {
    var прежде: Data
    var после: Data
}

struct ПравкаПутиИсключения: Codable, Equatable, Sendable {
    var указатель: String
    var идентификатор: String
    var прежнийПуть: String
    var будущийПуть: String
    var диапазон: Range<Int>
}

struct ПланМиграцииПолитики: Codable, Equatable, Sendable {
    var схема = "fum.миграция-селекторов-политики-локальных-путей.1"
    var исходныйSHA256: String
    var будущиеБайты: Data
    var правки: [ПравкаПутиИсключения]
    var препятствия: [ПрепятствиеОбщейМиграции]
    var контекстПолитикиПроверен = false
    var применениеРазрешено = false
}

enum АдаптерПолитикиЛокальныхПутей {
    static func построить(_ данные: Data, ожидаемыйSHA256: String, корни: [КорневоеОтображениеМиграции],
        файлы: [Data: БайтыПроверкиИсключений] = [:]) throws -> ПланМиграцииПолитики {
        let исходныйSHA256 = ОбщийПланировщикПутей.хэш(данные)
        guard исходныйSHA256 == ожидаемыйSHA256 else { throw ОтказJSONМиграции.условие("дрейф-политики") }
        let разбор = try ТокеныJSONМиграции.разобрать(данные)
        let политика = try JSONDecoder().decode(ПолитикаДляМиграции.self, from: данные)
        guard политика.схема == "fum.machine-local-path-policy.v3" else { throw ОтказJSONМиграции.условие("неизвестная-схема-политики") }
        let обязательные = Set(["schema", "exceptions", "метаданные"].map { Data($0.utf8) })
        let корневыеКлючи = разбор.ключиОбъектов[Data()] ?? []
        guard корневыеКлючи == обязательные else {
            throw ОтказJSONМиграции.условие("неизвестные-поля-политики")
        }
        guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any], объект["метаданные"] is [Any] else {
            throw ОтказJSONМиграции.условие("неверная-форма-метаданных")
        }
        for корень in корни {
            try проверитьПуть(корень.исходный); try проверитьПуть(корень.целевой)
            guard !корень.источникИмени.isEmpty, корень.ревизия == "837e2ce107b97ee7b9d3344c9fe99142281fe393" else { throw ОтказJSONМиграции.условие("нет-происхождения-имени") }
        }
        let токены = Dictionary(uniqueKeysWithValues: разбор.строки.map { (Data($0.указатель.utf8), $0) })
        var правки: [ПравкаПутиИсключения] = [], замены: [(Range<Int>, Data)] = []
        var препятствия: [ПрепятствиеОбщейМиграции] = [], идентификаторы: Set<Data> = []
        var проверкиСтрок: [Data: (хэши: Set<String>, отказ: String?)] = [:]
        var ожидаемая = политика
        let поляИсключения = Set(["id", "path", "kind", "line_sha256", "count", "category", "reason"].map { Data($0.utf8) })
        for (номер, исключение) in политика.исключения.enumerated() {
            let основание = "/exceptions/\(номер)", указатель = основание + "/path"
            guard разбор.ключиОбъектов[Data(основание.utf8)] == поляИсключения,
                  идентификаторы.insert(Data(исключение.идентификатор.utf8)).inserted,
                  исключение.идентификатор.range(of: #"\A[a-z0-9]+(?:-[a-z0-9]+)*\z"#, options: .regularExpression) != nil,
                  ["compiler-file-path", "file-uri", "home-expansion", "posix-absolute", "posix-user-home", "windows-drive", "windows-unc"].contains(исключение.вид), (1...16).contains(исключение.число),
                  ["allow.path-validation-definition", "allow.nonpath-syntax", "allow.test-fixture", "report.historical"].contains(исключение.категория), исключение.причина.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20,
                  исключение.хэшСтроки.range(of: #"\Asha256:[0-9a-f]{64}\z"#, options: .regularExpression) != nil else {
                throw ОтказJSONМиграции.условие("неверное-исключение-политики")
            }
            try проверитьПуть(исключение.путь)
            let совпадения = корни.filter { вложен(исключение.путь, в: $0.исходный) }
            guard совпадения.count <= 1 else { throw ОтказJSONМиграции.условие("неоднозначное-отображение-селектора") }
            guard let корень = совпадения.first else { continue }
            let будущий = корень.целевой + String(decoding: исключение.путь.utf8.dropFirst(корень.исходный.utf8.count), as: UTF8.self)
            try проверитьПуть(будущий)
            if Data(будущий.utf8) == Data(исключение.путь.utf8) { continue }
            guard let токен = токены[Data(указатель.utf8)], Data(токен.значение.utf8) == Data(исключение.путь.utf8) else {
                throw ОтказJSONМиграции.условие("нет-точного-value-токена")
            }
            let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.withoutEscapingSlashes]
            замены.append((токен.диапазон, try кодировщик.encode(будущий)))
            правки.append(.init(указатель: указатель, идентификатор: исключение.идентификатор, прежнийПуть: исключение.путь, будущийПуть: будущий, диапазон: токен.диапазон))
            ожидаемая.исключения[номер].путь = будущий

            let ключ = Data(исключение.путь.utf8)
            if проверкиСтрок[ключ] == nil {
                if let пара = файлы[ключ] {
                    if пара.прежде != пара.после { проверкиСтрок[ключ] = ([], "изменены-байты-исключения") }
                    else if let текст = String(data: пара.прежде, encoding: .utf8) {
                        let хэши = Set(текст.split(whereSeparator: \.isNewline).map { "sha256:" + ОбщийПланировщикПутей.хэш(Data($0.utf8)) })
                        проверкиСтрок[ключ] = (хэши, nil)
                    } else { проверкиСтрок[ключ] = ([], "не-UTF8-байты-исключения") }
                } else { проверкиСтрок[ключ] = ([], "не-проверены-байты-исключения") }
            }
            if let проверка = проверкиСтрок[ключ] {
                if let отказ = проверка.отказ { препятствия.append(.init(код: отказ, пути: [исключение.путь, указатель])) }
                else if !проверка.хэши.contains(исключение.хэшСтроки) { препятствия.append(.init(код: "не-найдена-строка-исключения", пути: [исключение.путь, указатель])) }
            }
        }
        замены.sort { $0.0.lowerBound < $1.0.lowerBound }
        for номер in замены.indices where номер > 0 {
            guard замены[номер - 1].0.upperBound <= замены[номер].0.lowerBound else { throw ОтказJSONМиграции.условие("пересекающиеся-правки-JSON") }
        }
        let отпечатки = try Dictionary(grouping: ожидаемая.исключения.enumerated().map { номер, исключение in
            (номер, try JSONEncoder().encode([исключение.путь, исключение.вид, исключение.хэшСтроки]))
        }, by: { $0.1 })
        for группа in отпечатки.values where группа.count > 1 {
            препятствия.append(.init(код: "коллизия-отпечатка-политики", пути: группа.map { "/exceptions/\($0.0)/path" }.sorted()))
        }
        препятствия.sort { $0.код == $1.код ? $0.пути.joined(separator: "\0").utf8.lexicographicallyPrecedes($1.пути.joined(separator: "\0").utf8) : $0.код.utf8.lexicographicallyPrecedes($1.код.utf8) }
        var будущие = Data(данные)
        for (диапазон, замена) in замены.reversed() { будущие.replaceSubrange(диапазон, with: замена) }
        _ = try ТокеныJSONМиграции.разобрать(будущие)
        guard try JSONDecoder().decode(ПолитикаДляМиграции.self, from: будущие) == ожидаемая else { throw ОтказJSONМиграции.условие("изменена-семантика-вне-селектора") }
        return .init(исходныйSHA256: исходныйSHA256, будущиеБайты: будущие, правки: правки, препятствия: препятствия)
    }

    private static func вложен(_ путь: String, в корне: String) -> Bool {
        Data(путь.utf8) == Data(корне.utf8) || путь.utf8.starts(with: (корне + "/").utf8)
    }
    private static func проверитьПуть(_ путь: String) throws {
        guard !путь.isEmpty, !путь.contains("\\"), !путь.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
              ИменаПутей.компоненты(путь, сохранятьПустые: true).allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.lowercased() != ".git" }) else {
            throw ОтказJSONМиграции.условие("небезопасный-путь-селектора")
        }
    }
}

private struct ПолитикаДляМиграции: Decodable, Equatable {
    var схема: String
    var исключения: [ИсключениеДляМиграции]
    enum CodingKeys: String, CodingKey { case схема = "schema", исключения = "exceptions" }
}

private struct ИсключениеДляМиграции: Decodable, Equatable {
    var идентификатор: String
    var путь: String
    var вид: String
    var хэшСтроки: String
    var число: Int
    var категория: String
    var причина: String
    enum CodingKeys: String, CodingKey {
        case идентификатор = "id", путь = "path", вид = "kind", хэшСтроки = "line_sha256", число = "count", категория = "category", причина = "reason"
    }
}
