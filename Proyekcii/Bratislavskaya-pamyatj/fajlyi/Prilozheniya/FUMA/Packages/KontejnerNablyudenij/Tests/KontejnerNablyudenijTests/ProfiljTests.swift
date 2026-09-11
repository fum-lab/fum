import Foundation
import CryptoKit
import Testing
@testable import КонтейнерНаблюдений

struct ПрофильTests {
    @Test func профильВосстановленияНеУдерживаетВесьФайл() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let команды = ПроцессыTests()
        let запись = try команды.выполнить("профиль-контейнера", ["записать", путь.path, "64", "524288"])
        try #require(запись.0 == 0)
        let байты = try Data(contentsOf: путь.appendingPathComponent("сегмент.fumobs"))
        let ожидаемыйХэш = Data(SHA256.hash(data: байты)).map { String(format: "%02x", $0) }.joined()
        let ответ = try команды.выполнить("профиль-контейнера", ["восстановить", путь.path])
        try #require(ответ.0 == 0)
        let поля = try #require(try JSONSerialization.jsonObject(with: ответ.1) as? [String: Any])
        let память = try #require(поля["память_пик_байт"] as? Int)
        // Локальный диагностический бюджет для этой 32-МиБ фикстуры, не SLA API.
        #expect(память < 67_108_864)
        #expect(поля["хэш_до"] as? String == поля["хэш_после"] as? String)
        #expect(поля["хэш_до"] as? String == ожидаемыйХэш)
    }
    @Test func профильПишетИПроверяетНеизменностьВДругомПроцессе() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let процессы = ПроцессыTests()
        let запись = try процессы.выполнить("профиль-контейнера", ["записать", путь.path, "2", "128"])
        #expect(запись.0 == 0)
        try #require(!запись.1.isEmpty)
        let метрики = try #require(JSONSerialization.jsonObject(with: запись.1) as? [String: Any])
        #expect(метрики["байт"] as? Int == 256)
        #expect((метрики["память_пик_байт"] as? Int ?? 0) > 0)
        #expect((метрики["подтверждения_наносекунды"] as? [UInt64])?.count == 2)
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let до = try Data(contentsOf: файл)
        let восстановление = try процессы.выполнить("профиль-контейнера", ["восстановить", путь.path])
        #expect(восстановление.0 == 0)
        let повтор = try #require(JSONSerialization.jsonObject(with: восстановление.1) as? [String: Any])
        #expect(повтор["хэш_до"] as? String == повтор["хэш_после"] as? String)
        #expect(try Data(contentsOf: файл) == до)
        let читатель = try Сегмент(кореньДанных: путь, запись: false)
        #expect(читатель.записи.count == 2)
        #expect(try читатель.извлечь("профиль-0") == Data((0..<128).map { UInt8(truncatingIfNeeded: $0 * 131) }))
    }
}
