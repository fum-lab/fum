import Foundation
import CryptoKit

/// Уменьшаемые пределы Data-фасада; файловый архив использует собственный бюджет.
public struct ПределыРамокJSONL: Equatable, Sendable {
    public let байты: Int
    public let строка: Int
    public let рамки: Int

    public init() {
        байты = 1_048_576
        строка = 262_144
        рамки = 128
    }

    public init(байты: Int = 1_048_576, строка: Int = 262_144, рамки: Int = 128) throws {
        guard (1...1_048_576).contains(байты), (1...262_144).contains(строка),
              (1...128).contains(рамки) else { throw ОшибкаАрхива.предел }
        self.байты = байты
        self.строка = строка
        self.рамки = рамки
    }
}

public struct РамкаJSONL: Equatable, Sendable {
    public let данные: Data
    public let позиция: ПозицияСтроки
}

public struct РезультатРамокJSONL: Equatable, Sendable {
    public let рамки: [РамкаJSONL]
    public let префикс: ГраницаПрефикса
    public let сыройХвост: Data
    /// Максимальная длина накопленной строки вместе с LF либо незавершённого хвоста.
    public let пикБуфераСтроки: Int

    /// Граница известного полного префикса; номер0 обозначает пустой префикс.
    public func префикс(до номер: Int) throws -> ГраницаПрефикса {
        guard (0...рамки.count).contains(номер) else { throw ОшибкаАрхива.предел }
        if номер == рамки.count { return префикс }
        var счётчик = SHA256()
        for рамка in рамки.prefix(номер) { счётчик.update(data: рамка.данные) }
        return ГраницаПрефикса(байты: номер == 0 ? 0 : рамки[номер - 1].позиция.конец,
            строки: номер, sha256: счётчик.finalize().map { String(format: "%02x", $0) }.joined())
    }
}

public func выделитьРамкиJSONL(_ данные: Data,
                              пределы: ПределыРамокJSONL = ПределыРамокJSONL()) throws -> РезультатРамокJSONL {
    var бюджет = БюджетАрхива()
    бюджет.байты = пределы.байты
    бюджет.строка = пределы.строка
    бюджет.строки = пределы.рамки
    let сканер = СканерРамокJSONL(бюджет: бюджет, прежняя: nil)
    var рамки: [РамкаJSONL] = []
    try данные.withUnsafeBytes { буфер in
        try сканер.принять(буфер.bindMemory(to: UInt8.self)) { строка, позиция in
            рамки.append(РамкаJSONL(данные: строка, позиция: позиция))
        }
    }
    let итог = try сканер.завершить()
    return РезультатРамокJSONL(рамки: рамки, префикс: итог.префикс,
        сыройХвост: итог.сыройХвост, пикБуфераСтроки: итог.пикБуфераСтроки)
}

struct ИтогСканераJSONL {
    let префикс: ГраницаПрефикса
    let прочитано: Int
    let сыройХвост: Data
    let пикБуфераСтроки: Int
}

/// Один потоковый LF-алгоритм. Бюджет задаёт вызывающий фасад, без сужения старого архива.
/// Буфер заимствуется на время вызова; ошибка callback прекращает этот сканер.
final class СканерРамокJSONL {
    private let бюджет: БюджетАрхива
    private let прежняя: ГраницаПрефикса?
    private var строка = Data()
    private var счётчик = SHA256()
    private var байты = 0
    private var прочитано = 0
    private var строки = 0
    private var пик = 0
    private var проверен: Bool
    private var завершён = false
    private var отказ = false

    init(бюджет: БюджетАрхива, прежняя: ГраницаПрефикса?) {
        self.бюджет = бюджет
        self.прежняя = прежняя
        проверен = прежняя == nil
    }

    func принять(_ буфер: UnsafeBufferPointer<UInt8>,
                 принять: (Data, ПозицияСтроки) throws -> Void) throws {
        guard !завершён, !отказ else { throw ОшибкаАрхива.формат }
        do {
            let число = буфер.count
            // Весь chunk проверяется до любого callback этого chunk.
            guard число <= бюджет.байты - прочитано else { throw ОшибкаАрхива.предел }
            прочитано += число
            var начало = 0
            for место in 0..<число where буфер[место] == 10 {
                guard место + 1 - начало <= бюджет.строка - строка.count else { throw ОшибкаАрхива.предел }
                строка.append(contentsOf: буфер[начало...место])
                пик = max(пик, строка.count)
                строки += 1
                guard строки <= бюджет.строки else { throw ОшибкаАрхива.предел }
                let конец = байты + строка.count
                счётчик.update(data: строка)
                if let прежняя, !проверен, конец >= прежняя.байты {
                    guard конец == прежняя.байты, строки == прежняя.строки,
                          счётчик.finalize().map({ String(format: "%02x", $0) }).joined() == прежняя.sha256 else {
                        throw ОшибкаАрхива.подменаПрефикса
                    }
                    проверен = true
                }
                let позиция = ПозицияСтроки(номер: строки, начало: байты, конец: конец, sha256: хэшАрхива(строка))
                try принять(строка, позиция)
                байты = конец
                строка.removeAll(keepingCapacity: true)
                начало = место + 1
            }
            if начало < число {
                guard число - начало <= бюджет.строка - строка.count else { throw ОшибкаАрхива.предел }
                строка.append(contentsOf: буфер[начало..<число])
                пик = max(пик, строка.count)
            }
        } catch {
            отказ = true
            throw error
        }
    }

    func завершить() throws -> ИтогСканераJSONL {
        guard !завершён, !отказ else { throw ОшибкаАрхива.формат }
        guard проверен else { отказ = true; throw ОшибкаАрхива.подменаПрефикса }
        завершён = true
        return ИтогСканераJSONL(префикс: ГраницаПрефикса(байты: байты, строки: строки,
            sha256: счётчик.finalize().map { String(format: "%02x", $0) }.joined()),
            прочитано: прочитано, сыройХвост: строка, пикБуфераСтроки: пик)
    }
}
