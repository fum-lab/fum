import Foundation

enum ИсходОчереди: Equatable, Sendable { case принято, перегрузка, закрыто }

/// Кольцевая очередь. Закрытие будит ожидающих и сохраняет уже принятые элементы.
final class ОчередьОбновлений: @unchecked Sendable {
    private let условие = NSCondition()
    private var элементы: [Data?]
    private var начало = 0
    private var количество = 0
    private var байты = 0
    private var закрыта = false
    private var максимумКоличество = 0
    private var максимумБайтов = 0
    private let пределБайтов: Int

    init(ёмкость: Int, пределБайтов: Int) throws {
        guard ёмкость > 0, ёмкость <= 65536, пределБайтов > 0 else {
            throw ОшибкаКлиента.неверныеДанные("Положительная ограниченная ёмкость очереди")
        }
        элементы = Array(repeating: nil, count: ёмкость)
        self.пределБайтов = пределБайтов
    }

    func положить(_ данные: Data, ожидать: Bool = true) -> ИсходОчереди {
        условие.lock()
        defer { условие.unlock() }
        guard данные.count <= пределБайтов else { return .перегрузка }
        while !закрыта && (количество == элементы.count || данные.count > пределБайтов - байты) {
            if !ожидать { return .перегрузка }
            условие.wait()
        }
        guard !закрыта else { return .закрыто }
        элементы[(начало + количество) % элементы.count] = данные
        количество += 1
        байты += данные.count
        максимумКоличество = max(максимумКоличество, количество)
        максимумБайтов = max(максимумБайтов, байты)
        условие.broadcast()
        return .принято
    }

    func извлечь() -> Data? {
        условие.lock()
        defer { условие.unlock() }
        while количество == 0 && !закрыта { условие.wait() }
        guard количество > 0, let данные = элементы[начало] else { return nil }
        элементы[начало] = nil
        начало = (начало + 1) % элементы.count
        количество -= 1
        байты -= данные.count
        условие.broadcast()
        return данные
    }

    func закрыть() {
        условие.lock()
        закрыта = true
        условие.broadcast()
        условие.unlock()
    }

    var пикБайтов: Int { условие.withLock { максимумБайтов } }
    var пикКоличество: Int { условие.withLock { максимумКоличество } }
    var остаток: [Data] {
        условие.withLock {
            (0..<количество).compactMap { элементы[(начало + $0) % элементы.count] }
        }
    }
}
