import Foundation
import CryptoKit
import Testing
@testable import Svezhestj

@Suite(.serialized)
struct ПроверкиСвежестиMarkdown {
    private func дата(_ строка: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: строка))
    }

    private func хэш(_ строка: String) -> String {
        SHA256.hash(data: Data(строка.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func документ(_ тело: String, время: String, хэш: String? = nil) -> Data {
        Data((тело + "\n<!-- FUM-MD-RECENCY:BEGIN -->\n"
            + "<!-- last-content-edit: \(время) -->\n"
            + "<!-- content-sha256: sha256:\(хэш ?? self.хэш(тело)) -->\n"
            + "<!-- FUM-MD-RECENCY:END -->\n").utf8)
    }

    @Test func нормализацияИНовыйБлок() throws {
        let исходник = Data("# Заголовок\r\n\rТекст  \r\nХвост".utf8)
        let тело = "# Заголовок\n\nТекст  \nХвост\n"
        let результат = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:30:00Z"))
        #expect(результат.данные == документ(тело, время: "2026-10-29 23:30:00 MSK"))
        #expect(результат.хэш == хэш(тело))
        #expect(результат.изменено)
    }

    @Test func неизменныйХэшИПовтор() throws {
        let исходник = документ("# Текст\n\nСодержимое.\n", время: "2020-01-02 03:04:05 MSK")
        let первый = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:00:00Z"))
        let второй = try СвежестьMarkdown.обновить(первый.данные, сейчас: дата("2026-10-30T20:00:00Z"))
        #expect(первый.данные == исходник)
        #expect(второй.данные == исходник)
        #expect(второй.время == "2020-01-02 03:04:05 MSK")
        #expect(!первый.изменено && !второй.изменено)
    }

    @Test func изменениеИМосковскаяДата() throws {
        let тело = "# Новый текст\n"
        let исходник = документ(тело, время: "2020-01-02 03:04:05 MSK", хэш: хэш("# Старый текст\n"))
        let результат = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T22:30:00Z"))
        #expect(результат.данные == документ(тело, время: "2026-10-30 01:30:00 MSK"))
        #expect(результат.время == "2026-10-30 01:30:00 MSK")
        #expect(результат.хэш == хэш(тело))
    }

    @Test func прежняяМеткаОстаётсяСодержимым() throws {
        let тело = "# История\n\n<!-- FUM-MD-RECENCY:BEGIN -->\npending\n<!-- FUM-MD-RECENCY:END -->\n"
        let исходник = документ(тело, время: "2020-01-02 03:04:05 MSK")
        let результат = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:00:00Z"))
        #expect(результат.данные == исходник)
        #expect(результат.хэш == хэш(тело))
    }

    @Test func ограждённыеМаркерыОстаютсяСодержимым() throws {
        let тело = "# Цитата\n\n````swift\n```\n<!-- FUM-MD-RECENCY:BEGIN -->\npending\n<!-- FUM-MD-RECENCY:END -->\n````\n\n~~~text\n<!-- FUM-MD-RECENCY:BEGIN -->\npending\n<!-- FUM-MD-RECENCY:END -->\n~~~\n"
        let исходник = документ(тело, время: "2020-01-02 03:04:05 MSK")
        let результат = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:00:00Z"))
        #expect(результат.данные == исходник)
        #expect(результат.хэш == хэш(тело))
    }

    @Test func повреждённыйПоследнийБлокНеДаётОтката() throws {
        let старый = документ("# Старый текст\n", время: "2020-01-02 03:04:05 MSK")
        var исходник = старый
        исходник.append(Data("\n<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: 2026-10-29 20:00:00 MSK -->\n<!-- content-sha256: sha256:bad -->\n<!-- FUM-MD-RECENCY:END -->\n".utf8))
        do {
            _ = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:00:00Z"))
            Issue.record("Повреждённый конечный блок принят")
        } catch {
            #expect(error as? ОшибкаСвежести == .повреждённаяМетка)
        }
    }

    @Test func незакрытаяОградаЗакрываетЗапись() throws {
        var исходник = документ("# История\n", время: "2020-01-02 03:04:05 MSK")
        исходник.append(Data("\n~~~~\nДословный незакрытый пример.\n".utf8))
        do {
            _ = try СвежестьMarkdown.обновить(исходник, сейчас: дата("2026-10-29T20:00:00Z"))
            Issue.record("Незакрытая ограда принята")
        } catch {
            #expect(error as? ОшибкаСвежести == .незакрытаяОграда)
        }
    }

    @Test func командаОбновляетТолькоСвойОтслеживаемыйФайл() throws {
        let база = try #require(ProcessInfo.processInfo.environment["FUM_RECENCY_TEST_ROOT"])
        let корень = URL(fileURLWithPath: база).appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let файл = корень.appendingPathComponent("document.md")
        let исходник = Data("# Собственная открытая фикстура\n".utf8)
        try исходник.write(to: файл, options: .withoutOverwriting)
        _ = try GitСвежести.выполнить(корень: корень.path, аргументы: ["init", "--quiet"])
        _ = try GitСвежести.выполнить(корень: корень.path, аргументы: ["add", "--", "document.md"])
        let аргументы = ["--корень", корень.path, "--путь", "document.md"]
        let до = try КомандаСвежести.выполнить(аргументы: аргументы + ["--проверить"], ввод: nil, сейчас: дата("2026-10-29T20:00:00Z"))
        #expect(до.код == 1)
        #expect(try Data(contentsOf: файл) == исходник)
        let обновление = try КомандаСвежести.выполнить(аргументы: аргументы, ввод: nil, сейчас: дата("2026-10-29T20:00:00Z"))
        #expect(обновление.код == 0)
        let ожидаемое = документ("# Собственная открытая фикстура\n", время: "2026-10-29 23:00:00 MSK")
        #expect(try Data(contentsOf: файл) == ожидаемое)
        let повтор = try КомандаСвежести.выполнить(аргументы: аргументы + ["--проверить"], ввод: nil, сейчас: дата("2026-10-30T20:00:00Z"))
        #expect(повтор.код == 0)
        #expect(try Data(contentsOf: файл) == ожидаемое)
    }
}
