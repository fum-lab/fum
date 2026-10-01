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

/// Современный C API не предоставляет уничтожение общего ClientManager.
/// Один успешно разрешённый образ намеренно удерживается до завершения процесса.
private final class ОбразБиблиотеки {
    typealias СоздатьКлиента = @convention(c) () -> Int32
    typealias ОтправитьЗапрос = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
    typealias ПринятьОтвет = @convention(c) (Double) -> UnsafePointer<CChar>?
    let дескриптор: UnsafeMutableRawPointer
    let создать: СоздатьКлиента
    let отправка: ОтправитьЗапрос
    let приём: ПринятьОтвет
    let путь: String

    init(путь: String) throws {
        guard let открытый = dlopen(путь, RTLD_NOW | RTLD_LOCAL) else { throw ОшибкаКлиента.библиотекаНедоступна }
        do {
            func символ<Тип>(_ имя: String, как: Тип.Type) throws -> Тип {
                guard let адрес = dlsym(открытый, имя) else { throw ОшибкаКлиента.отсутствуетСимвол(имя) }
                return unsafeBitCast(адрес, to: Тип.self)
            }
            создать = try символ("td_create_client_id", как: СоздатьКлиента.self)
            отправка = try символ("td_send", как: ОтправитьЗапрос.self)
            приём = try символ("td_receive", как: ПринятьОтвет.self)
            дескриптор = открытый
            self.путь = путь
        } catch {
            // До первого C-вызова не создано клиентов и нет активного receive.
            dlclose(открытый)
            throw error
        }
    }
}

private final class ОбразПроцесса: @unchecked Sendable {
    static let единственный = ОбразПроцесса()
    private let замок = NSLock()
    private var образ: ОбразБиблиотеки?
    func получить(_ библиотека: String) throws -> ОбразБиблиотеки {
        let путь = URL(fileURLWithPath: библиотека).resolvingSymlinksInPath().standardizedFileURL.path
        return try замок.withLock {
            if let образ {
                guard образ.путь == путь else { throw ОшибкаКлиента.доступЗапрещён("Процесс уже использует другой образ TDLib") }
                return образ
            }
            let открытый = try ОбразБиблиотеки(путь: путь)
            образ = открытый
            return открытый
        }
    }
}

/// Типизированная граница C ABI. Send/create потокобезопасны в TDLib;
/// единственный receive резервируется владельцем среды до создания клиентов.
public final class МостБиблиотеки: ТранспортБиблиотеки, @unchecked Sendable {
    private let образ: ОбразБиблиотеки
    private let пределОтвета: Int
    public init(библиотека: String, пределОтвета: Int = 8 * 1024 * 1024) throws {
        guard !библиотека.isEmpty, !библиотека.utf8.contains(0), пределОтвета > 0, пределОтвета < Int.max else {
            throw ОшибкаКлиента.неверныеДанные("Путь библиотеки и предел ответа")
        }
        образ = try ОбразПроцесса.единственный.получить(библиотека)
        self.пределОтвета = пределОтвета
    }
    func создатьКлиента() -> Int32 { образ.создать() }

    func отправить(клиент: Int32, запрос: Data) throws {
        guard клиент > 0, !запрос.contains(0), let строка = String(data: запрос, encoding: .utf8) else {
            throw ОшибкаКлиента.неверныеДанные("Запрос должен быть UTF-8 JSON без NUL")
        }
        строка.withCString { образ.отправка(клиент, $0) }
    }

    func принять(таймАут: Double) throws -> Data? {
        guard таймАут.isFinite, таймАут > 0, таймАут <= 1 else {
            throw ОшибкаКлиента.неверныеДанные("Receive требует конечный timeout (0, 1]")
        }
        guard let указатель = образ.приём(таймАут) else { return nil }
        return try скопироватьОтвет(указатель, предел: пределОтвета)
    }
}
