import Foundation
import Darwin

public enum ОшибкаКлиента: Error, Equatable, Sendable {
    case библиотекаНедоступна
    case отсутствуетСимвол(String)
    case превышенПредел
    case неверныеДанные(String)
    case ужеЕстьПриёмник
    case доступЗапрещён(String)
    case неподдерживаемоеДействие
    case закрыт
    case требуетсяРазбор
}

/// Копирование завершается синхронно, пока C-буфер ещё принадлежит текущему receive.
func скопироватьОтвет(_ указатель: UnsafePointer<CChar>, предел: Int) throws -> Data {
    guard предел > 0, предел < Int.max else { throw ОшибкаКлиента.превышенПредел }
    let длина = strnlen(указатель, предел + 1)
    guard длина <= предел else { throw ОшибкаКлиента.превышенПредел }
    return Data(bytes: указатель, count: длина)
}

/// Внутренний транспорт не является публичным универсальным интерфейсом отправки.
protocol ТранспортБиблиотеки: AnyObject, Sendable {
    func создатьКлиента() -> Int32
    func отправить(клиент: Int32, запрос: Data) throws
    func принять(таймАут: Double) throws -> Data?
}

/// Типизированная граница C ABI. TDLib удерживается до освобождения её владельца.
/// Sendable допустим: send/create потокобезопасны в TDLib, receive защищён владельцем процесса.
public final class МостБиблиотеки: ТранспортБиблиотеки, @unchecked Sendable {
    private typealias СоздатьКлиента = @convention(c) () -> Int32
    private typealias ОтправитьЗапрос = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
    private typealias ПринятьОтвет = @convention(c) (Double) -> UnsafePointer<CChar>?
    private let дескриптор: UnsafeMutableRawPointer
    private let создать: СоздатьКлиента
    private let отправка: ОтправитьЗапрос
    private let приём: ПринятьОтвет
    private let пределОтвета: Int

    public init(библиотека: String, пределОтвета: Int = 8 * 1024 * 1024) throws {
        guard !библиотека.isEmpty, пределОтвета > 0, пределОтвета < Int.max else {
            throw ОшибкаКлиента.неверныеДанные("Путь библиотеки и предел ответа")
        }
        guard let открытый = dlopen(библиотека, RTLD_NOW | RTLD_LOCAL) else {
            throw ОшибкаКлиента.библиотекаНедоступна
        }
        do {
            func символ<Тип>(_ имя: String, как: Тип.Type) throws -> Тип {
                guard let адрес = dlsym(открытый, имя) else {
                    throw ОшибкаКлиента.отсутствуетСимвол(имя)
                }
                return unsafeBitCast(адрес, to: Тип.self)
            }
            создать = try символ("td_create_client_id", как: СоздатьКлиента.self)
            отправка = try символ("td_send", как: ОтправитьЗапрос.self)
            приём = try символ("td_receive", как: ПринятьОтвет.self)
            дескриптор = открытый
            self.пределОтвета = пределОтвета
        } catch {
            dlclose(открытый)
            throw error
        }
    }

    deinit { dlclose(дескриптор) }

    func создатьКлиента() -> Int32 { создать() }

    func отправить(клиент: Int32, запрос: Data) throws {
        guard клиент > 0, !запрос.contains(0), let строка = String(data: запрос, encoding: .utf8) else {
            throw ОшибкаКлиента.неверныеДанные("Запрос должен быть UTF-8 JSON без NUL")
        }
        строка.withCString { отправка(клиент, $0) }
    }

    func принять(таймАут: Double) throws -> Data? {
        guard таймАут.isFinite, таймАут > 0, таймАут <= 1 else {
            throw ОшибкаКлиента.неверныеДанные("Receive требует конечный timeout (0, 1]")
        }
        guard let указатель = приём(таймАут) else { return nil }
        return try скопироватьОтвет(указатель, предел: пределОтвета)
    }
}
