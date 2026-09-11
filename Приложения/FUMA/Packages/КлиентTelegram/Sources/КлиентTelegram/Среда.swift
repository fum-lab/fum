import Foundation

public struct ИтогЗакрытия: Codable, Equatable, Sendable {
    public let всеЗакрыты: Bool
    public let потокиЗавершены: Bool
    public let требуетсяРазбор: Bool
    public let неприменённыхКадров: Int
    public let пикОчереди: Int
    public let пикБайтовОчереди: Int
}

/// Владелец единственного приёмника и последовательного прикладного ядра.
/// Внешняя отмена ожидания не отменяет операцию закрытия и не освобождает живой TDLib.
public actor СредаКлиента {
    public nonisolated let ядро: ЯдроКлиента
    private let цикл: ЦиклПриёма
    private var закрытие: Task<ИтогЗакрытия, Error>?

    private init(ядро: ЯдроКлиента, цикл: ЦиклПриёма) { self.ядро = ядро; self.цикл = цикл }

    public static func открыть(библиотека: String, корень: URL, ключ: Data) async throws -> СредаКлиента {
        let транспорт = try МостБиблиотеки(библиотека: библиотека)
        return try await начать(транспорт: транспорт, корень: корень, ключ: ключ)
    }

    static func начать(транспорт: any ТранспортБиблиотеки, корень: URL, ключ: Data) async throws -> СредаКлиента {
        let ядро = try ЯдроКлиента(транспорт: транспорт, корень: корень, ключ: ключ)
        do {
            let цикл = try ЦиклПриёма(транспорт: транспорт) { данные in
                try Task.checkCancellation()
                try await ядро.принять(данные)
            }
            // Резервирование происходит до первого create_client_id.
            try цикл.запустить()
            return СредаКлиента(ядро: ядро, цикл: цикл)
        } catch { await ядро.закрытьЖурнал(); throw error }
    }

    public func добавитьКлиента(аккаунт: Int64? = nil) async throws -> Int32 {
        guard закрытие == nil else { throw ОшибкаКлиента.закрыт }
        return try await ядро.добавитьКлиента(аккаунт: аккаунт)
    }

    public func дождатьсяНачальногоОтвета(_ клиент: Int32, таймАут: Double = 5) async throws -> НачальныйОтвет {
        try Self.проверитьСрок(таймАут)
        let предел = ContinuousClock.now + .seconds(таймАут)
        while ContinuousClock.now < предел {
            try Task.checkCancellation()
            guard цикл.причинаОстановки == nil else { throw ОшибкаКлиента.требуетсяРазбор }
            if let ответ = try await ядро.состояние(клиент).начальныйОтвет { return ответ }
            guard закрытие == nil else { throw ОшибкаКлиента.закрыт }
            try await Task.sleep(for: .milliseconds(5))
        }
        throw ОшибкаКлиента.требуетсяРазбор
    }

    public func закрыть(таймАут: Double = 5) async throws -> ИтогЗакрытия {
        try Self.проверитьСрок(таймАут)
        if let закрытие { return try await закрытие.value }
        let задача = Task { try await закрытьОдинРаз(таймАут: таймАут) }
        закрытие = задача
        return try await задача.value
    }

    private static func проверитьСрок(_ срок: Double) throws {
        guard срок.isFinite, срок > 0, срок <= 60 else { throw ОшибкаКлиента.неверныеДанные("Срок ожидания: (0, 60] секунд") }
    }

    private func закрытьОдинРаз(таймАут: Double) async throws -> ИтогЗакрытия {
        var причина: ОшибкаКлиента?
        do { try await ядро.начатьЗакрытие() }
        catch { причина = error as? ОшибкаКлиента ?? .требуетсяРазбор }
        let предел = ContinuousClock.now + .seconds(таймАут)
        while причина == nil, цикл.причинаОстановки == nil, !(await ядро.всеЗакрыты), ContinuousClock.now < предел {
            try await Task.sleep(for: .milliseconds(5))
        }
        let былиЗакрыты = await ядро.всеЗакрыты
        await цикл.остановить(отменитьОбработку: !былиЗакрыты, освободитьВладение: false)
        причина = причина ?? цикл.причинаОстановки
        let всеЗакрыты = await ядро.всеЗакрыты
        let хвост = цикл.незавершённые
        do {
            let разбор = try await ядро.завершитьПриём(хвост: хвост, причина: причина)
            if всеЗакрыты, причина == nil, хвост.isEmpty { цикл.освободитьВладение() }
            else { цикл.сохранитьАварийноеВладение() }
            return ИтогЗакрытия(всеЗакрыты: всеЗакрыты, потокиЗавершены: true, требуетсяРазбор: разбор,
                неприменённыхКадров: хвост.count, пикОчереди: цикл.пикКоличество, пикБайтовОчереди: цикл.пикБайтов)
        } catch {
            цикл.сохранитьАварийноеВладение()
            throw error
        }
    }
}
