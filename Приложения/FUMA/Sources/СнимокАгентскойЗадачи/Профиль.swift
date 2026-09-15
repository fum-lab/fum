import Foundation
import CryptoKit
import КонтейнерНаблюдений

public struct ЗамерСнимка: Codable, Sendable {
    public let стадия: String
    public let наносекунды: UInt64
    public let глубина: Int
    public let исход: String
}
public struct ПрофильСнимка: Codable, Sendable {
    public let версия: Int
    public let наблюдений: Int
    public let повторов: Int
    public let байтовВхода: Int
    public let байтовХранения: Int
    public let приростБайтовПриПовторах: Int
    public let хэшСнимка: String
    public let хэшКонтейнера: String
    public let повторыНаносекунды: [UInt64]
    public let замеры: [ЗамерСнимка]
}

public func измеритьСнимок(корень: URL, количество: Int) async throws -> ПрофильСнимка {
    guard (1...256).contains(количество) else { throw ОшибкаСнимка.предел }
    let общийСтарт = DispatchTime.now().uptimeNanoseconds
    let задача = Задача(поставщик: "синтетический-профиль", хост: "стенд", идентификатор: "задача-1")
    let наблюдения = (1...количество).map { номер in
        Наблюдение(идентификатор: "п-\(номер)", задача: задача, источник: Источник(.журнал),
            такт: Int64(номер), годноДо: Int64(номер + 1),
            исходныйФакт: String(repeating: "ф", count: 256),
            заменяет: номер == 1 ? [] : ["п-\(номер - 1)"],
            факт: .значение(поле: .текущаяРабота, контекст: "", текст: "синтетическая работа \(номер)"))
    }
    let сценарий = Сценарий(задача: задача, наблюдения: наблюдения)
    let вход = try каноническийJSON(сценарий)
    let началоСборки = DispatchTime.now().uptimeNanoseconds
    var редуктор = try Редуктор(задача: задача)
    for наблюдение in наблюдения { try редуктор.принять(наблюдение) }
    let времяСборки = DispatchTime.now().uptimeNanoseconds - началоСборки
    let ожидаемыйХэш = try хэшСнимка(редуктор.снимок)
    let началоЗаписи = DispatchTime.now().uptimeNanoseconds
    let писатель = try ХранилищеСнимка(корень: корень, задача: задача, запись: true)
    do {
        guard try await писатель.получить().наблюдения.isEmpty else { throw ОшибкаСнимка.неверныйВвод }
        let записанный = try await писатель.проиграть(сценарий)
        guard try хэшСнимка(записанный) == ожидаемыйХэш else { throw ОшибкаСнимка.неверныйПереход }
        await писатель.закрыть()
    } catch {
        await писатель.закрыть()
        throw error
    }
    let времяЗаписи = DispatchTime.now().uptimeNanoseconds - началоЗаписи
    let файл = корень.appendingPathComponent("сегмент.fumobs")
    let доПовторов = try прочитатьВход(файл.path, предел: 16 * 1024 * 1024)
    let началоReplay = DispatchTime.now().uptimeNanoseconds
    let восстановитель = try ХранилищеСнимка(корень: корень, задача: задача, запись: true)
    let восстановленный = try await восстановитель.получить()
    let времяReplay = DispatchTime.now().uptimeNanoseconds - началоReplay
    var временаПовторов: [UInt64] = []
    do {
        guard try хэшСнимка(восстановленный) == ожидаемыйХэш else { throw ОшибкаСнимка.неверныйПереход }
        for _ in 0..<32 {
            let начало = DispatchTime.now().uptimeNanoseconds
            _ = try await восстановитель.принять(наблюдения[0])
            временаПовторов.append(DispatchTime.now().uptimeNanoseconds - начало)
        }
        await восстановитель.закрыть()
    } catch {
        await восстановитель.закрыть()
        throw error
    }
    let послеПовторов = try прочитатьВход(файл.path, предел: 16 * 1024 * 1024)
    guard доПовторов == послеПовторов else { throw ОшибкаСнимка.неверныйПереход }
    func замер(_ стадия: String, _ время: UInt64, _ глубина: Int = 1) -> ЗамерСнимка {
        ЗамерСнимка(стадия: стадия, наносекунды: время, глубина: глубина, исход: "успех")
    }
    return ПрофильСнимка(версия: 1, наблюдений: количество, повторов: временаПовторов.count,
        байтовВхода: вход.count, байтовХранения: доПовторов.count,
        приростБайтовПриПовторах: послеПовторов.count - доПовторов.count,
        хэшСнимка: ожидаемыйХэш,
        хэшКонтейнера: SHA256.hash(data: доПовторов).map { String(format: "%02x", $0) }.joined(),
        повторыНаносекунды: временаПовторов,
        замеры: [
            замер("чистая-сборка", времяСборки),
            замер("создание-и-запись-с-preflight-и-fsync", времяЗаписи),
            замер("новый-экземпляр-replay-и-сверка", времяReplay),
            замер("32-повтора-с-fsync", временаПовторов.reduce(0, +)),
            замер("весь-профиль", DispatchTime.now().uptimeNanoseconds - общийСтарт, 0)
        ])
}
