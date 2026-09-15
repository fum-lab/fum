import Foundation
import XCTest
@testable import СценарийRuntime

final class СценарииTests: XCTestCase {
    func testТочныеБайтыИПовторПослеОткрытия() throws {
        let корень = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let физический = try XCTUnwrap(realpath(корень.path, nil))
        defer { free(физический) }
        let результат = try СценарийRuntime.выполнить(
            вход: Data([0, 0x41, 0xD1, 0x91, 0xF0, 0x9F, 0x8E, 0xBB]),
            корень: URL(fileURLWithPath: String(cString: физический)))
        let ожидаемые = Data([0,0,0,0, 0x41,0,0,0, 0x51,4,0,0, 0xBB,0xF3,1,0])
        XCTAssertEqual(результат.выход, ожидаемые)
        XCTAssertEqual(результат.повтор, ожидаемые)
        XCTAssertFalse(результат.профиль.isEmpty)
    }

    func testНеверныйUTF8НеСоздаётНаблюдение() throws {
        let корень = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try СценарийRuntime.выполнить(вход: Data([0xC0, 0xAF]), корень: корень))
        XCTAssertFalse(FileManager.default.fileExists(atPath: корень.path))
    }
}
