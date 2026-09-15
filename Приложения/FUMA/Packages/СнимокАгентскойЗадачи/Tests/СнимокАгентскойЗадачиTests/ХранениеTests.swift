import Foundation
import Darwin
import XCTest
@testable import СнимокАгентскойЗадачи
import КонтейнерНаблюдений

func временныйКорень() throws -> URL {
    let путь = FileManager.default.temporaryDirectory.appendingPathComponent("fum-снимок-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false)
    guard let физический = realpath(путь.path, nil) else { throw ОшибкаСнимка.неверныйВвод }
    defer { free(физический) }
    return URL(fileURLWithPath: String(cString: физический))
}

@MainActor final class ХранениеTests: XCTestCase {
    func testНовыйЭкземплярВосстанавливаетНеподтверждённыйЭффект() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let первое = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let вход = запись(1, .команда(операция: "операция-1", фаза: .отправлена, эффект: "открыта-задача-1", корректирует: nil), канал: .команда)
        let до = try await первое.принять(вход)
        await первое.закрыть()
        let второе = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: false)
        let после = try await второе.получить()
        await второе.закрыть()
        XCTAssertEqual(до, после)
        XCTAssertEqual(после.операции.count, 1)
        XCTAssertNil(после.операции.first?.подтверждение)
        let контейнер = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { контейнер.закрыть() }
        XCTAssertEqual(контейнер.записи.count, 1)
        XCTAssertFalse(try контейнер.извлечь("н-1").isEmpty)
    }

    func testПовторПослеReopenНеСоздаётНовогоПерехода() async throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }
        let первое = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let вход = запись(1, .значение(поле: .текущаяРабота, контекст: "", текст: "сборка"))
        let до = try await первое.принять(вход)
        await первое.закрыть()
        let второе = try ХранилищеСнимка(корень: корень, задача: задачаПримера, запись: true)
        let после = try await второе.принять(вход)
        await второе.закрыть()
        XCTAssertEqual(до, после)
        let контейнер = try Сегмент(кореньДанных: корень, запись: false, создать: false)
        defer { контейнер.закрыть() }
        XCTAssertEqual(контейнер.записи.count, 1)
    }
}
