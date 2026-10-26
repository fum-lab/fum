import Foundation
import FUMStructuringOperatorMemory
import ОсноваЗапуска

struct ТелоЗаписи: Swift.Codable, Swift.Equatable, Swift.Sendable {
    var схема = "fum.локальная-запись-журнала.1"
    var идентификатор: String
    var хэшВхода: String
    var хэшОператора: String
    var данные: ВходЗаписи
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case схема = "схема"
        case идентификатор = "идентификатор"
        case хэшВхода = "входSHA256"
        case хэшОператора = "операторSHA256"
        case данные = "данные"
    }
}

struct ЗамерЗаписи: Codable, Sendable {
    var стадия: String
    var наносекунды: Int64
}

func наносекунды(_ начало: ContinuousClock.Instant) -> Int64 {
    let части = начало.duration(to: ContinuousClock.now).components
    return части.seconds * 1_000_000_000 + части.attoseconds / 1_000_000_000
}

struct СнимокЦели: Swift.Codable, Swift.Equatable, Swift.Sendable {
    var хэшКорня: String
    var область: String
    var узлы: [String]
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case хэшКорня = "кореньSHA256"
        case область = "область"
        case узлы = "узлы"
    }
}

struct ПланЗаписи: Swift.Codable, Swift.Equatable, Swift.Sendable {
    var схема = "fum.план-локальной-записи.1"
    var цель: СнимокЦели
    var идентификатор: String
    var путь: String
    var хэшВхода: String
    var хэшОператора: String
    var хэшСодержания: String
    var байты: Data
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case схема = "схема"
        case цель = "цель"
        case идентификатор = "идентификатор"
        case путь = "путь"
        case хэшВхода = "входSHA256"
        case хэшОператора = "операторSHA256"
        case хэшСодержания = "содержаниеSHA256"
        case байты = "байты"
    }
}

enum ПланировщикЗаписи {
    static func оператор() throws -> Data {
        guard let путь = Bundle.module.url(forResource: "sformirovatj-zapisj", withExtension: "json", subdirectory: "opredeleniya")
        else { throw ОтказЖурнала.вход }
        return try Data(contentsOf: путь)
    }

    static func построить(_ вход: Data, оператор: Data, цель: СнимокЦели,
                          профиль: ((ЗамерЗаписи) -> Void)? = nil) throws -> ПланЗаписи {
        let начало = ContinuousClock.now
        let определение = try ОпределениеОператора.разобрать(оператор)
        guard определение.идентификатор == "fum.сформировать-локальную-запись",
              определение.шаги.count == 1,
              case .вычислитьJSON = определение.шаги[0].действие,
              let текст = String(data: вход, encoding: .utf8) else { throw ОтказЖурнала.вход }
        // Именно engine разбирает исходный JSON до JSONDecoder: повторы ключей не теряются.
        let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(текст))
        guard case .текст(let результат) = исполнение.результат else { throw ОтказЖурнала.вход }
        let данные = try JSONDecoder().decode(ВходЗаписи.self, from: Data(результат.utf8))
        try данные.проверить()
        let каноническийВход = try каноническиеДанные(данные)
        let исходныеПоля = try JSONSerialization.jsonObject(with: вход) as? NSDictionary
        let типизированныеПоля = try JSONSerialization.jsonObject(with: каноническийВход) as? NSDictionary
        guard let исходныеПоля, let типизированныеПоля, исходныеПоля.isEqual(типизированныеПоля),
              Data(результат.utf8) == каноническийВход,
              Data(данные.область.utf8) == Data(цель.область.utf8) else { throw ОтказЖурнала.вход }
        let идентификатор = хэш(try каноническиеДанные(данные.экземпляр))
        let хэшВхода = хэш(вход)
        let хэшОператора = хэш(оператор)
        let тело = ТелоЗаписи(идентификатор: идентификатор, хэшВхода: хэшВхода,
            хэшОператора: хэшОператора, данные: данные)
        профиль?(ЗамерЗаписи(стадия: "чистое-формирование-FUMA-и-проверка-входа", наносекунды: наносекунды(начало)))
        let началоФормата = ContinuousClock.now
        let байты = try ПредставлениеЗапуска.байты(тело, читаемо: true)
        профиль?(ЗамерЗаписи(стадия: "форматирование-JSON", наносекунды: наносекунды(началоФормата)))
        return ПланЗаписи(цель: цель, идентификатор: идентификатор,
            путь: данные.область + "/zhurnal/" + идентификатор + ".json", хэшВхода: хэшВхода,
            хэшОператора: хэшОператора, хэшСодержания: хэш(байты), байты: байты)
    }
}

enum ГраницаЦели {
    static func проверитьОбласть(_ область: String) throws {
        guard !область.isEmpty, !область.hasPrefix("/"), !область.contains("\\"),
              область.split(separator: "/", omittingEmptySubsequences: false).allSatisfy({
                  !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git" && $0.utf8.count <= 255
              }), область.utf8.count <= 1024,
              !область.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else { throw ОтказЖурнала.путь }
    }
}
