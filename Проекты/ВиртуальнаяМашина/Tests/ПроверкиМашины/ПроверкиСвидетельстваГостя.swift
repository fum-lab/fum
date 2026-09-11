import XCTest
@testable import ЯдроМашины

final class ПроверкиСвидетельстваГостя: XCTestCase {
    func test_готовность_связана_с_запросом_и_полнотой_набора() throws {
        let машина = "12345678-1234-4234-8234-123456789abc"
        let проверка = "22345678-1234-4234-8234-123456789abc"
        let запуск = "32345678-1234-4234-8234-123456789abc"
        let план = String(repeating: "a", count: 64)
        let имена = ["fum-proyektnyiye-fajlyi", "fum-moskovskoye-vremya-rabochej-sessii", "fum-indeks-readme", "fum-obratnyiye-ssyilki-voprosov"]
        var тело: [String: Any] = ["схема": "fum.готовность-гостя.1", "машина": машина, "план": план,
            "запуск": запуск, "проверка": проверка, "гостевой_запуск": машина,
            "коммит": Профиль().коммит, "дерево": "03e9f37be0717b35e9e87a46fe27e540cd071d63",
            "инициализация": "done", "файловая_система": "ext4", "сохранённые_данные": String(repeating: "b", count: 64),
            "профиль": ["профиль": "fum.linux-portable.1", "тесты": 58, "проверки_индексов": 2,
                "наборы": zip(имена, [8, 4, 25, 21]).map { ["набор": $0, "счётчики": ["выполнено": $1, "ошибки": 0, "отказы": 0, "пропущено": 0, "ожидаемые_ошибки": 0, "неожиданные_успехи": 0]] as [String: Any] }]]
        func принять() throws {
            try ГотовностьГостя.проверитьСвидетельство(JSONSerialization.data(withJSONObject: тело), машина: машина, план: план, запуск: запуск, проверка: проверка)
        }
        XCTAssertNoThrow(try принять())
        let эталон = try JSONSerialization.data(withJSONObject: тело)
        тело["сохранённые_данные"] = String(repeating: "c", count: 64)
        XCTAssertThrowsError(try ГотовностьГостя.проверитьСохранность(JSONSerialization.data(withJSONObject: тело), эталон: эталон))
        тело["сохранённые_данные"] = String(repeating: "b", count: 64)
        XCTAssertNoThrow(try ГотовностьГостя.проверитьСохранность(JSONSerialization.data(withJSONObject: тело), эталон: эталон))
        тело["запуск"] = проверка
        XCTAssertThrowsError(try принять())
        тело["запуск"] = запуск
        тело["профиль"] = ["профиль": "fum.linux-portable.1", "тесты": 58, "проверки_индексов": 2, "наборы": []]
        XCTAssertThrowsError(try принять())
    }
}
