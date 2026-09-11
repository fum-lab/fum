import XCTest
@testable import ЯдроМашины

final class ПроверкиДоступаКГостю: XCTestCase {
    func test_восстановлению_нужен_явный_частный_адрес() throws {
        XCTAssertNoThrow(try ДоступКГостю.проверитьАдресВосстановления("192.168.64.2"))
        for адрес in ["", "fum", "127.0.0.1", "8.8.8.8", "192.168.64.2 -o StrictHostKeyChecking=no", "192.168.999.1"] {
            XCTAssertThrowsError(try ДоступКГостю.проверитьАдресВосстановления(адрес))
        }
    }
    func test_туннель_ограничивает_получателей_и_сохраняет_закрепление() throws {
        let аргументы = try ДоступКГостю.аргументы(каталог: "/личная VM", порт: 45678, черезХост: true)
        XCTAssertTrue(аргументы.contains("/личная VM/идентичность/ssh_config"))
        XCTAssertTrue(аргументы.contains("PermitRemoteOpen=ports.ubuntu.com:443 github.com:443"))
        XCTAssertTrue(аргументы.contains("127.0.0.1:1080"))
        XCTAssertFalse(аргументы.contains(where: { $0.contains("StrictHostKeyChecking=no") }))
        XCTAssertThrowsError(try ДоступКГостю.аргументы(каталог: "/личная VM", порт: 0, черезХост: true))
    }
}
