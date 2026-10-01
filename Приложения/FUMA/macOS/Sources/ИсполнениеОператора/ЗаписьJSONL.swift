import Foundation
import CryptoKit
import АрхивныйСнимокЗадачи
import КонтейнерНаблюдений

struct ПрофильJSONL: Codable, Equatable {
    var схема = "fuma.профиль-JSONL.1"
    var байты = 1_048_576
    var строка = 262_144
    var рамки = 128
    var определение = 65_536
    var результат = 1_048_576
    var операции = 16_777_216
    var трасса = 256
    var глубина = 16
    var узлы = 8192
    static let текущий = ПрофильJSONL()

    func проверить() throws {
        guard схема == Self.текущий.схема,
              (1...1_048_576).contains(байты), (1...262_144).contains(строка),
              (1...128).contains(рамки), (1...65_536).contains(определение),
              (1...1_048_576).contains(результат), (1...16_777_216).contains(операции),
              (0...256).contains(трасса), (0...16).contains(глубина),
              (1...8192).contains(узлы) else { throw ОшибкаКомандногоИсполнения.записьПовтора }
    }
}

struct ДиапазонJSONL: Codable, Equatable {
    let начало: Int
    let конец: Int
    let sha256: String
}

struct ИсполненнаяРамкаJSONL: Codable, Equatable {
    let позиция: ПозицияСтроки
    let выделеноОпераций: Int
    let выполненоОпераций: Int
    let записейТрассы: Int
    let трассаПолна: Bool
    /// Канонические кодированные байты: runtime-наблюдение имеет только Encodable.
    let наблюдение: Data
    let sha256Наблюдения: String
}

struct ОтказРамкиJSONL: Codable, Equatable {
    let позиция: ПозицияСтроки
    let стадия: String
    let код: String
    let выделеноОпераций: Int
    let выполненоОпераций: Int?
    let учтеноОпераций: Int
}

/// Ссылки на отдельные durable объекты сохраняют raw вне бюджета производного JSON.
struct ЗаписьJSONL: Codable, Equatable {
    let схема: String
    let профиль: ПрофильJSONL
    let сыройВход: Квитанция
    let исходноеОпределение: Квитанция
    let замыкание: Квитанция
    let сохранённыйПрофиль: Квитанция
    var рамки: [ИсполненнаяРамкаJSONL]
    let границаLF: ГраницаПрефикса
    var исполненныйПрефикс: ГраницаПрефикса
    let сыройХвост: ДиапазонJSONL
    var неИсполненныйСуффикс: ДиапазонJSONL
    var отказ: ОтказРамкиJSONL?
    var учтеноОпераций: Int
    var записейТрассы: Int
    var трассаПолна: Bool
}

struct ОтветJSONL: Codable {
    let схема: String
    let квитанция: Квитанция
    let запись: ЗаписьJSONL
}

func кодироватьJSONL<Значение: Encodable>(_ значение: Значение) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var данные = try кодировщик.encode(значение)
    данные.append(10)
    return данные
}

func хэшJSONL(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
