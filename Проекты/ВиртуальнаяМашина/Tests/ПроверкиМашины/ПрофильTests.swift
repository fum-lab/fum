import XCTest
@testable import ЯдроМашины

final class ПроверкиПрофиля: XCTestCase {
    func test_ДопустимыйПервыйПрофиль() throws {
        XCTAssertNoThrow(try Профиль().проверить())
    }
    func test_НедопустимыеРесурсыОтклоняются() {
        for значение in [-1, 0, Int.max] {
            var профиль = Профиль()
            профиль.процессоры = значение
            XCTAssertThrowsError(try профиль.проверить())
            профиль = Профиль()
            профиль.памятьГиБ = значение
            XCTAssertThrowsError(try профиль.проверить())
            профиль = Профиль()
            профиль.дискГиБ = значение
            XCTAssertThrowsError(try профиль.проверить())
        }
    }
    func test_ПлавающийИлиВнедрённыйКоммитОтклоняется() {
        for значение in ["master", "HEAD", "abc", "$(touch /tmp/example)", String(repeating: "f", count: 39), String(repeating: "f", count: 40) + "\n", String(repeating: "f", count: 40) + "\r\n", String(repeating: "f", count: 40) + "\u{2028}"] {
            var профиль = Профиль()
            профиль.коммит = значение
            XCTAssertThrowsError(try профиль.проверить())
        }
    }
}
