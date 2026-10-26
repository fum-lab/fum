import Foundation
import CryptoKit
import Testing
@testable import ОсноваЗапуска

@Suite("Ограниченный профиль обработчика пакета путей", .serialized)
struct ПрофильПакетаПутей {
    @Test("Три операции на фиксированных fixture через контролируемый адаптер")
    func триОперацииНаFixture() async throws {
        struct Образец: Encodable {
            let действие: String
            let повторов: Int
            let полноеВремяНаносекунды: UInt64
            let среднееНаносекунды: UInt64
        }
        struct Профиль: Encodable {
            let схема = "fuma.профиль-обработчика-пакета-путей.1"
            let граница = "3 серии по 10 повторов для построить, сверить и применить через фиксированный Sendable fixture; включает разбор, чтение малого файла, переход адаптера и разбор квитанции. Не включает сборку, запуск процесса, production backend или файловые эффекты backend. Это локальный профиль формы и накладных расходов, не оценка производительности Names."
            let размерПоручения: Int
            let размерПлана: Int
            let размерКвитанции: Int
            let образцы: [Образец]
        }

        guard let путьОтчёта = ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_ПАКЕТА_ПУТЕЙ"],
              путьОтчёта.hasPrefix("/") else {
            Issue.record("Задайте абсолютный путь профиля ФУМА_ПРОФИЛЬ_ПАКЕТА_ПУТЕЙ")
            return
        }

        let временный = try ВременнаяСредаПрофиляПакетаПутей()
        let поручение = Data("fixture: задание-построения-v1".utf8)
        let план = Data("fixture: неизменяемый-план-v1".utf8)
        let sha256 = SHA256.hash(data: план).map { String(format: "%02x", $0) }.joined()
        let квитанция = Data("""
        {"схема":"fum.квитанция-пакета-девяти-путей.1","план_sha256":"\(sha256)","исход":"завершено","подтверждённый_префикс":14,"наблюдённый_префикс":14}
        """.utf8)
        let файлПоручения = try временный.записать(поручение, под: "поручение.json")
        let файлПлана = try временный.записать(план, под: "план.json")
        let адаптер = ПрофильныйАдаптерПакетаПутей(план: план, квитанция: квитанция)
        let обработчик = ОбработчикПакетаПутей(адаптер: адаптер)
        let корень = временный.url.appendingPathComponent("рабочий-корень", isDirectory: true)
        let серии: [(String, [String], Int)] = [
            ("построить", ["построить", "--корень", корень.path, "--вход", файлПоручения.path], план.count),
            ("сверить", ["сверить", "--корень", корень.path, "--план", файлПлана.path, "--sha256", sha256], 0),
            ("применить", ["применить", "--корень", корень.path, "--план", файлПлана.path, "--sha256", sha256], квитанция.count)
        ]

        let часы = ContinuousClock()
        var образцы: [Образец] = []
        for (действие, аргументы, размерВывода) in серии {
            let начало = часы.now
            for _ in 0..<10 {
                let результат = await обработчик.выполнить(аргументы)
                guard результат.код == 0, результат.вывод.count == размерВывода,
                      результат.ошибка.isEmpty else {
                    Issue.record("Fixture-ответ не совпал с контрактом серии \(действие)")
                    return
                }
            }
            let части = начало.duration(to: часы.now).components
            let всего = UInt64(части.seconds) * 1_000_000_000
                + UInt64(части.attoseconds / 1_000_000_000)
            образцы.append(Образец(действие: действие, повторов: 10,
                полноеВремяНаносекунды: всего, среднееНаносекунды: всего / 10))
        }

        let профиль = Профиль(размерПоручения: поручение.count, размерПлана: план.count,
            размерКвитанции: квитанция.count, образцы: образцы)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var bytes = try encoder.encode(профиль)
        bytes.append(0x0a)
        try bytes.write(to: URL(fileURLWithPath: путьОтчёта), options: [.withoutOverwriting])
    }
}

private struct ПрофильныйАдаптерПакетаПутей: АдаптерПакетаПутей {
    let план: Data
    let квитанция: Data

    func построить(корень: URL, поручение: Data) async throws -> Data { план }
    func сверить(корень: URL, план: Data, sha256: String) async throws {}
    func применить(корень: URL, план: Data, sha256: String) async throws -> Data { квитанция }
}

private final class ВременнаяСредаПрофиляПакетаПутей {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fuma-профиль-пакета-путей-\(UUID().uuidString.lowercased())", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    }

    func записать(_ данные: Data, под именем: String) throws -> URL {
        let файл = url.appendingPathComponent(именем)
        try данные.write(to: файл)
        return файл
    }

    deinit { try? FileManager.default.removeItem(at: url) }
}
