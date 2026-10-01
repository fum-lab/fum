import XCTest
import МостЛибторрента
import ПробыМоста

final class ГраницаИсключенийТесты: XCTestCase {
    func сообщение(_ результат: РезультатГраницыМоста) -> String {
        var данные = результат.сообщение
        return withUnsafeBytes(of: &данные) { байты in
            XCTAssertEqual(байты.last, 0)
            let конец = байты.firstIndex(of: 0) ?? байты.count
            return String(decoding: байты.prefix(конец), as: UTF8.self)
        }
    }

    func test_ВызываетДействиеЧерезЧистуюГраницуСи() {
        var вызовы = 0
        let результат = withUnsafeMutablePointer(to: &вызовы) { адрес in
            выполнить_пробу_моста(0, { контекст in
                контекст!.assumingMemoryBound(to: Int.self).pointee += 1
            }, адрес)
        }
        XCTAssertEqual(версия_границы_моста(), 1)
        XCTAssertEqual(результат.код, 0)
        XCTAssertEqual(сообщение(результат), "")
        XCTAssertEqual(вызовы, 1)
    }

    func test_СохраняетОбычноеИсключение() {
        let результат = выполнить_пробу_моста(1, nil, nil)
        XCTAssertEqual(результат.код, 1)
        XCTAssertEqual(сообщение(результат), "проверочное исключение")
    }

    func test_ЛовитНеизвестноеИсключение() {
        let результат = выполнить_пробу_моста(2, nil, nil)
        XCTAssertEqual(результат.код, 1)
        XCTAssertFalse(сообщение(результат).isEmpty)
    }

    func test_ЛовитОтказВыделенияПамяти() {
        let результат = выполнить_пробу_моста(3, nil, nil)
        XCTAssertEqual(результат.код, 3)
        XCTAssertFalse(сообщение(результат).isEmpty)
    }

    func test_РазличаетОтменуИПовтор() {
        let отменённый = выполнить_пробу_моста(4, nil, nil)
        XCTAssertEqual(отменённый.код, 2)
        XCTAssertEqual(выполнить_пробу_моста(0, nil, nil).код, 0)
    }

    func test_ОграничиваетДлинноеСообщениеОшибки() {
        let результат = выполнить_пробу_моста(5, nil, nil)
        XCTAssertEqual(результат.код, 1)
        XCTAssertEqual(сообщение(результат), String(repeating: "a", count: 511))
    }

    func test_СохраняетОтменуОперацииИНачинаетНовуюПопытку() {
        var операция: OpaquePointer?
        let результат = создать_операцию_торрента(&операция)
        XCTAssertEqual(результат.код, 0)
        XCTAssertNotNil(операция)
        defer { уничтожить_операцию_торрента(операция) }
        let первоначальная = операция
        XCTAssertEqual(создать_операцию_торрента(&операция).код, 1)
        XCTAssertEqual(операция, первоначальная)
        XCTAssertEqual(запрошена_отмена_торрента(операция), 0)
        отменить_операцию_торрента(операция)
        отменить_операцию_торрента(операция)
        XCTAssertEqual(запрошена_отмена_торрента(операция), 1)
        var повтор: OpaquePointer?
        XCTAssertEqual(создать_операцию_торрента(&повтор).код, 0)
        defer { уничтожить_операцию_торрента(повтор) }
        XCTAssertEqual(запрошена_отмена_торрента(повтор), 0)
    }

    func test_ОтклоняетОтсутствующийАдресОперации() {
        let результат = создать_операцию_торрента(nil)
        XCTAssertEqual(результат.код, 1)
        XCTAssertFalse(сообщение(результат).isEmpty)
        XCTAssertEqual(запрошена_отмена_торрента(nil), 1)
        отменить_операцию_торрента(nil)
        уничтожить_операцию_торрента(nil)
    }
}
