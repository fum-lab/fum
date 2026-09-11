import Foundation
import CryptoKit
import КонтейнерНаблюдений

public enum СостояниеПопытки: String, Codable, Sendable {
    case передОтправкой, ожидает, выполнено, отказ, требуетсяРазбор
}

public struct ИсходСообщения: Codable, Equatable, Sendable {
    public let временный: Int64
    public var окончательный: Int64?
    public var ошибка: Int64?
}

public struct Попытка: Codable, Equatable, Sendable {
    public let идентификатор: UUID
    public let черновик: Черновик
    public let разрешение: РазрешениеДействия
    public let запрос: ЗначениеДанных
    public internal(set) var состояние: СостояниеПопытки
    public internal(set) var сообщения: [ИсходСообщения]
    public internal(set) var кодОшибки: Int64?
    public internal(set) var противоречие = false
    init(черновик: Черновик, разрешение: РазрешениеДействия, запрос: ЗначениеДанных, идентификатор: UUID = UUID()) {
        self.идентификатор = идентификатор; self.черновик = черновик; self.разрешение = разрешение
        self.запрос = запрос; состояние = .передОтправкой; сообщения = []
    }
    func послеПерезапуска() -> Попытка {
        var копия = self
        if состояние == .передОтправкой || состояние == .ожидает { копия.состояние = .требуетсяРазбор }
        return копия
    }
}

enum ЛокальнаяЗапись: Codable, Equatable, Sendable {
    case черновик(Черновик), попытка(Попытка)
    case наблюдение(аккаунт: Int64, событие: ЗначениеДанных)
    case разрыв(String)
    case неприменённые([Data])
}

private struct ЗашифрованнаяЗапись: Codable {
    let версия: Int
    let данные: Data
}

/// Синхронный non-Sendable журнал принадлежит одному actor; fsync завершается до отправки.
/// Ключ передаётся отдельно и никогда не пишется в контейнер.
final class ЛокальныйЖурнал {
    private let контейнер: Сегмент
    private let ключ: SymmetricKey
    private var отказ = false
    init(корень: URL, ключ: Data, операции: ФайловыеОперации = .системные) throws {
        guard ключ.count == 32 else { throw ОшибкаКлиента.неверныеДанные("256-битный ключ локального журнала") }
        let свойства = try FileManager.default.attributesOfItem(atPath: корень.path)
        guard корень.isFileURL, корень.standardizedFileURL == корень.resolvingSymlinksInPath().standardizedFileURL,
              свойства[.type] as? FileAttributeType == .typeDirectory,
              (свойства[.posixPermissions] as? NSNumber)?.intValue == 0o700,
              (свойства[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() else {
            throw ОшибкаКлиента.доступЗапрещён("Журнал требует собственный приватный каталог 0700 без ссылок")
        }
        self.ключ = SymmetricKey(data: ключ)
        контейнер = try Сегмент(кореньДанных: корень, запись: true, операции: операции)
        if контейнер.естьХвост { контейнер.закрыть(); throw ОшибкаКлиента.требуетсяРазбор }
    }
    func восстановить() throws -> [ЛокальнаяЗапись] {
        guard !отказ else { throw ОшибкаКлиента.требуетсяРазбор }
        return try контейнер.записи.map { квитанция in
            guard квитанция.описание.тип == "телеграм/зашифрованное-событие", квитанция.описание.версияСхемы == 1,
                  квитанция.размер <= 32 * 1024 * 1024 else { throw ОшибкаКлиента.требуетсяРазбор }
            let оболочка = try JSONDecoder().decode(ЗашифрованнаяЗапись.self,
                from: контейнер.извлечь(квитанция.описание.идентификатор))
            guard оболочка.версия == 1 else { throw ОшибкаКлиента.требуетсяРазбор }
            let открыто = try AES.GCM.open(AES.GCM.SealedBox(combined: оболочка.данные), using: ключ,
                authenticating: Data(квитанция.описание.идентификатор.utf8))
            return try JSONDecoder().decode(ЛокальнаяЗапись.self, from: открыто)
        }
    }
    func добавить(_ запись: ЛокальнаяЗапись) throws {
        guard !отказ else { throw ОшибкаКлиента.требуетсяРазбор }
        let идентификатор = UUID().uuidString
        let данные = try кодироватьЛокально(запись)
        guard данные.count <= 24 * 1024 * 1024 else { throw ОшибкаКлиента.превышенПредел }
        let закрыто = try AES.GCM.seal(данные, using: ключ, authenticating: Data(идентификатор.utf8))
        guard let шифротекст = закрыто.combined else { throw ОшибкаКлиента.требуетсяРазбор }
        let оболочка = try кодироватьЛокально(ЗашифрованнаяЗапись(версия: 1, данные: шифротекст))
        guard оболочка.count <= 32 * 1024 * 1024 else { throw ОшибкаКлиента.превышенПредел }
        do {
            _ = try контейнер.добавить(ОписаниеНаблюдения(идентификатор: идентификатор,
                тип: "телеграм/зашифрованное-событие", источник: "локальный-клиент", время: "порядок-контейнера",
                спецификация: Data("FUM-STEP-0222/1; AES-256-GCM".utf8)),
                данные: оболочка)
        } catch { отказ = true; throw error }
    }
    func закрыть() { контейнер.закрыть(); отказ = true }
}
