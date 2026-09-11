import Foundation

private final class ВладениеПриёмом: @unchecked Sendable {
    static let процесса = ВладениеПриёмом()
    private let замок = NSLock()
    private var владелец: UUID?
    func занять(_ идентификатор: UUID) throws {
        try замок.withLock {
            guard владелец == nil else { throw ОшибкаКлиента.ужеЕстьПриёмник }
            владелец = идентификатор
        }
    }
    func освободить(_ идентификатор: UUID) {
        замок.withLock { if владелец == идентификатор { владелец = nil } }
    }
}

/// Один receive-поток и один последовательный передатчик actor на процесс.
/// Передатчик ждёт завершения применения, поэтому порядок не зависит от планировщика Task.
final class ЦиклПриёма: @unchecked Sendable {
    private let идентификатор = UUID()
    private let транспорт: any ТранспортБиблиотеки
    private let очередь: ОчередьОбновлений
    private let применить: @Sendable (Data) async throws -> Void
    private let замок = NSLock()
    private let потоки = DispatchGroup()
    private var запущен = false
    private var остановлен = false
    private var отменён = false
    private var прерватьОбработку = false
    private var обработчик: Task<Void, Never>?
    private var неприменённое: Data?
    private var непринятое: Data?
    private var ошибка: ОшибкаКлиента?
    private let таймАут: Double

    init(транспорт: any ТранспортБиблиотеки, ёмкость: Int = 64,
         пределБайтов: Int = 8 * 1024 * 1024, таймАут: Double = 0.1,
         применить: @escaping @Sendable (Data) async throws -> Void) throws {
        guard таймАут.isFinite, таймАут > 0, таймАут <= 1 else {
            throw ОшибкаКлиента.неверныеДанные("Конечный положительный timeout")
        }
        self.транспорт = транспорт
        self.таймАут = таймАут
        self.применить = применить
        очередь = try ОчередьОбновлений(ёмкость: ёмкость, пределБайтов: пределБайтов)
    }

    func запустить() throws {
        try замок.withLock {
            guard !запущен, !остановлен else { throw ОшибкаКлиента.закрыт }
            try ВладениеПриёмом.процесса.занять(идентификатор)
            запущен = true
            потоки.enter()
            потоки.enter()
        }
        let приёмник = Thread { [self] in
            defer { очередь.закрыть(); потоки.leave() }
            while !замок.withLock({ отменён }) {
                do {
                    guard let данные = try транспорт.принять(таймАут: таймАут) else { continue }
                    let исход = очередь.положить(данные)
                    if исход != .принято {
                        замок.withLock {
                            непринятое = данные
                            if исход == .перегрузка { ошибка = .превышенПредел }
                        }
                        break
                    }
                } catch {
                    замок.withLock {
                        self.ошибка = error as? ОшибкаКлиента ?? .неверныеДанные("Ошибка C ABI")
                    }
                    break
                }
            }
        }
        приёмник.name = "FUM: приём TDLib"
        let передатчик = Thread { [self] in
            defer { потоки.leave() }
            while !замок.withLock({ прерватьОбработку }) {
                guard let данные = очередь.извлечь() else { break }
                if замок.withLock({ прерватьОбработку }) {
                    замок.withLock { неприменённое = данные }
                    break
                }
                let готово = DispatchSemaphore(value: 0)
                let задача = Task { [self] in
                    do { try await применить(данные) }
                    catch {
                        замок.withLock {
                            неприменённое = данные
                            ошибка = error as? ОшибкаКлиента ?? .требуетсяРазбор
                            отменён = true
                        }
                        очередь.закрыть()
                    }
                    готово.signal()
                }
                замок.withLock {
                    обработчик = задача
                    if прерватьОбработку { задача.cancel() }
                }
                готово.wait()
                замок.withLock { обработчик = nil }
                if замок.withLock({ неприменённое != nil }) { break }
            }
        }
        передатчик.name = "FUM: порядок обновлений"
        передатчик.start()
        приёмник.start()
    }

    /// Вызывает внешний владелец после возврата обработчика Closed, никогда не сам обработчик.
    /// Активная отмена требует кооперативного обработчика; произвольный зависший код не прерывается принудительно.
    func остановить(отменитьОбработку: Bool = false) async {
        let нужен = замок.withLock {
            отменён = true
            остановлен = true
            if отменитьОбработку { прерватьОбработку = true; обработчик?.cancel() }
            return запущен
        }
        очередь.закрыть()
        if нужен {
            await withCheckedContinuation { продолжение in
                потоки.notify(queue: .global()) { продолжение.resume() }
            }
            ВладениеПриёмом.процесса.освободить(идентификатор)
        }
    }

    var пикКоличество: Int { очередь.пикКоличество }
    var пикБайтов: Int { очередь.пикБайтов }
    var причинаОстановки: ОшибкаКлиента? { замок.withLock { ошибка } }
    /// Читать после остановки. Уже скопированные, но не применённые данные возвращаются в порядке приёма.
    var незавершённые: [Data] {
        let границы = замок.withLock { (неприменённое, непринятое) }
        return [границы.0].compactMap { $0 } + очередь.остаток + [границы.1].compactMap { $0 }
    }
}
