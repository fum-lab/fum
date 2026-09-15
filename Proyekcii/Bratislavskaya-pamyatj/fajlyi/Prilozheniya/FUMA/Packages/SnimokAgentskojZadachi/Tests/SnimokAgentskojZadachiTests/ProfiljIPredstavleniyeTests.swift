import Foundation
import CryptoKit
import XCTest
@testable import СнимокАгентскойЗадачи

@MainActor final class ПрофильИПредставлениеTests: XCTestCase {
    func testПрофильИзмеряетНастоящееХранениеИПовторыБезПрироста() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let профиль = try await измеритьСнимок(корень: корень, количество: 4)
        XCTAssertEqual(профиль.наблюдений, 4)
        XCTAssertEqual(профиль.повторов, 32)
        XCTAssertEqual(профиль.приростБайтовПриПовторах, 0)
        XCTAssertEqual(профиль.замеры.count, 5)
        XCTAssertTrue(профиль.замеры.allSatisfy { $0.наносекунды > 0 && $0.исход == "успех" })
        let байты = try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs"))
        XCTAssertEqual(профиль.байтовХранения, байты.count)
        XCTAssertEqual(профиль.хэшКонтейнера, SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined())
        let до = байты
        await ожидаетсяОтказ { _ = try await измеритьСнимок(корень: корень, количество: 4) }
        XCTAssertEqual(try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs")), до)
    }
    func testMarkdownНеИнтерпретируетИсходныйТекст() throws {
        let вход = запись(1, .значение(поле: .текущаяРабота, контекст: "", текст: "<script> | [ссылка](https://invalid.example) `"))
        let снимок = try свернуть([вход])
        let текст = try читаемыйТекст(снимок)
        let markdown = try читаемыйMarkdown(снимок)
        XCTAssertTrue(текст.contains("свидетельство"))
        XCTAssertTrue(markdown.split(separator: "\n").dropFirst().allSatisfy { $0.hasPrefix("    ") })
        XCTAssertEqual(снимок.неизвестныеПоля.count, Поле.allCases.count - 1)
        XCTAssertTrue(текст.contains("Поля без свидетельств"))
        XCTAssertEqual(try читаемыйMarkdown(снимок), markdown)
    }
}
