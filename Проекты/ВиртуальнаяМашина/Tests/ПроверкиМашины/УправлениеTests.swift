import XCTest
@testable import ЯдроМашины

final class ПроверкиУправления: XCTestCase {
    func test_ПрежниеКлючиСостоянияСохраняютсяПриКодировании() throws {
        let прежнее: [String: Any] = ["схема": "fum.запуск-машины.1", "машина": "открытая-машина",
            "план": "открытый-план", "запуск": "открытый-запуск", "токен": "открытый-токен",
            "портSSH": 1234, "портУправления": 1235, "фаза": "работает", "причина": "Открытая диагностика"]
        let состояние = try JSONDecoder().decode(ЗапускМашины.self, from: JSONSerialization.data(withJSONObject: прежнее))
        XCTAssertEqual(состояние.портДоступаКГостю, 1234)
        XCTAssertEqual(состояние.причина, "Открытая диагностика")
        let итог = try XCTUnwrap(JSONSerialization.jsonObject(with: кодировать(состояние)) as? NSDictionary)
        XCTAssertEqual(итог, прежнее as NSDictionary)
    }
    func test_ЗапускСамПоСебеНеГотовность() throws {
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
    func test_ЧужойИПрошлыйЗапускНеПринимается() throws {
        let запись = ЗапускМашины(машина: UUID().uuidString, план: "план", портДоступаКГостю: 1234, портУправления: 1235)
        XCTAssertNoThrow(try запись.проверить(токен: запись.токен, запуск: запись.запуск))
        XCTAssertThrowsError(try запись.проверить(токен: "чужой", запуск: запись.запуск))
        XCTAssertThrowsError(try запись.проверить(токен: запись.токен, запуск: UUID().uuidString))
    }
}
