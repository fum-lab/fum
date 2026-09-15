import Foundation
import XCTest
@testable import СтатистикаВызовов

let задачаФикстуры = "11111111-1111-4111-8111-111111111111"
func строка(_ тип: String, _ данные: [String: Any], время: Any? = "2026-09-09T12:00:00Z") throws -> Data {
    var объект: [String: Any] = ["type": тип, "payload": данные]
    if let время { объект["timestamp"] = время }
    var байты = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
    байты.append(10)
    return байты
}
func метаданные(_ задача: String = задачаФикстуры) throws -> Data {
    try строка("session_meta", ["id": задача])
}
func вызов(_ ключ: Any = "call_a", имя: Any = "functions.exec", время: Any? = "2026-09-09T12:00:00Z",
           аргументы: String = "ПРИВАТНЫЕ_АРГУМЕНТЫ", произвольный: Bool = false) throws -> Data {
    try строка("response_item", ["type": произвольный ? "custom_tool_call" : "function_call",
        "call_id": ключ, "name": имя, "arguments": аргументы], время: время)
}
func результат(_ ключ: Any = "call_a", время: Any? = "2026-09-09T12:00:00.250Z",
               произвольный: Bool = false) throws -> Data {
    try строка("response_item", ["type": произвольный ? "custom_tool_call_output" : "function_call_output",
        "call_id": ключ, "output": "ПРИВАТНЫЙ_ВЫВОД"], время: время)
}
func временныйКаталог() throws -> URL {
    let каталог = FileManager.default.temporaryDirectory.appendingPathComponent("fum-stats-test-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
    return каталог
}
func сФайлом<Значение>(_ данные: Data, _ действие: (URL) throws -> Значение) throws -> Значение {
    let каталог = try временныйКаталог()
    defer { try? FileManager.default.removeItem(at: каталог) }
    let путь = каталог.appendingPathComponent("публичная-фикстура.jsonl")
    try данные.write(to: путь)
    return try действие(путь)
}
func сводка(_ данные: Data) throws -> ОтчётСтатистики {
    try сФайлом(данные) { путь in
        let вход = try прочитатьПрефикс(путь, задача: задачаФикстуры)
        var учёт = try УчётВызовов(задача: задачаФикстуры)
        try учёт.принять(вход.события)
        return учёт.отчёт(граница: вход.граница)
    }
}
