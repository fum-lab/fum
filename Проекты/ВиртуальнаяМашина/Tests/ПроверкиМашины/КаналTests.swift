import XCTest
import Darwin
@testable import ЯдроМашины

final class ПроверкиКанала: XCTestCase {
    func test_ПринятыйНеблокирующийДескрипторНормализуется() throws {
        let файл = socket(AF_INET, SOCK_STREAM, 0); defer { close(файл) }
        XCTAssertGreaterThanOrEqual(файл, 0)
        XCTAssertEqual(fcntl(файл, F_SETFL, O_NONBLOCK), 0)
        Канал.настроить(файл)
        XCTAssertEqual(fcntl(файл, F_GETFL) & O_NONBLOCK, 0)
    }
    func test_КадрСКириллицейИОтказОтПустогоКадра() throws {
        var файлы: [Int32] = [-1, -1]
        XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &файлы), 0)
        defer { файлы.forEach { close($0) } }
        файлы.forEach { Канал.настроить($0) }
        let байты = Data("готова ё\nещё строка".utf8)
        try Канал.отправить(файлы[0], байты)
        XCTAssertEqual(try Канал.получить(файлы[1]), байты)
        XCTAssertThrowsError(try Канал.отправить(файлы[0], Data()))
    }
    func test_ПроверкаПодлинностиОтклоняетЧужойКлючИИзменённыйКадр() throws {
        let байты = Data("nonce:состояние".utf8)
        let подпись = ПодлинностьКанала.подписать(байты, ключ: "собственный")
        XCTAssertNoThrow(try ПодлинностьКанала.проверить(байты, подпись: подпись, ключ: "собственный"))
        XCTAssertThrowsError(try ПодлинностьКанала.проверить(байты, подпись: подпись, ключ: "чужой"))
        XCTAssertThrowsError(try ПодлинностьКанала.проверить(байты + Data([0]), подпись: подпись, ключ: "собственный"))
    }
    func test_ОжиданиеКадраОграниченоОбщимВременем() throws {
        var файлы: [Int32] = [-1, -1]
        XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &файлы), 0)
        defer { файлы.forEach { close($0) } }
        файлы.forEach { Канал.настроить($0) }
        let начало = DispatchTime.now().uptimeNanoseconds
        XCTAssertThrowsError(try Канал.получить(файлы[0], предел: 0.1))
        XCTAssertLessThan(Double(DispatchTime.now().uptimeNanoseconds - начало) / 1e9, 0.5)
    }
}
