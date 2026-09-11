import XCTest
@testable import ЯдроМашины

final class ПроверкиУправления: XCTestCase {
    func testЗапускСамПоСебеНеГотовность() throws {
        var состояние = ЖизненныйЦикл()
        try состояние.перейти("работает")
        XCTAssertEqual(состояние.фаза, "работает")
        XCTAssertThrowsError(try состояние.перейти("готова"))
        try состояние.перейти("проверка готовности")
        try состояние.перейти("готова")
        try состояние.перейти("останавливается")
        XCTAssertThrowsError(try состояние.перейти("готова"))
        try состояние.перейти("остановлена")
        XCTAssertThrowsError(try состояние.перейти("работает"))
    }
    func testЧужойИПрошлыйЗапускНеПринимается() throws {
        let запись = ЗапускМашины(машина: UUID().uuidString, план: "план", портSSH: 1234, портУправления: 1235)
        XCTAssertNoThrow(try запись.проверить(токен: запись.токен, запуск: запись.запуск))
        XCTAssertThrowsError(try запись.проверить(токен: "чужой", запуск: запись.запуск))
        XCTAssertThrowsError(try запись.проверить(токен: запись.токен, запуск: UUID().uuidString))
    }
}
