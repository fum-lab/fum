import CryptoKit
import Darwin
import Foundation
import Testing

// Имя «проверки» переиспользует вычисленный LK837-компонент принятой карты имён.
// Процессный сценарий следует существующему proverki/zapusk/ПроцессыЗапуска.swift;
// все входы, RAW и наблюдения этого набора остаются в приватном каталоге вызывающего.
private struct НаблюдениеКомандыСинхронизации: Codable, Sendable {
    let процесс: Int32
    let код: Int32
    let наносекунды: UInt64
    let вывод: Data
    let ошибки: Data
    let хэшБинарника: String
}

private enum ОшибкаПроверкиКоманды: Error {
    case нетСреды, бинарникИзменён, коллизия, времяИстекло, завершение
}

private actor ПроцессыКомандыСинхронизации {
    private let бинарник: URL
    private let каталог: URL
    private let хэш: String
    private var номер = 0

    init() throws {
        let среда = ProcessInfo.processInfo.environment
        guard let путьБинарника = среда["ФУМ_БИНАРНИК_СИНХРОНИЗАЦИИ"],
              let основание = среда["ФУМ_СВИДЕТЕЛЬСТВА_СИНХРОНИЗАЦИИ"]
        else { throw ОшибкаПроверкиКоманды.нетСреды }
        бинарник = URL(fileURLWithPath: путьБинарника)
        каталог = URL(fileURLWithPath: основание)
            .appendingPathComponent(UUID().uuidString.lowercased())
        хэш = Self.хэш(try Data(contentsOf: бинарник))
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
    }

    private static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    func запустить(_ аргументы: [String], в корне: URL? = nil) async throws -> НаблюдениеКомандыСинхронизации {
        try Task.checkCancellation()
        guard Self.хэш(try Data(contentsOf: бинарник)) == хэш
        else { throw ОшибкаПроверкиКоманды.бинарникИзменён }
        номер += 1
        let экземпляр = номер
        let путьВывода = каталог.appendingPathComponent("\(экземпляр).stdout")
        let путьОшибок = каталог.appendingPathComponent("\(экземпляр).stderr")
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil,
                attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil,
                attributes: [.posixPermissions: 0o600])
        else { throw ОшибкаПроверкиКоманды.коллизия }
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var команда = try кодировщик.encode([бинарник.path, "синхронизация"] + аргументы)
        команда.append(10)
        try команда.write(to: каталог.appendingPathComponent("\(экземпляр).argv.json"),
            options: [.withoutOverwriting])
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        let процесс = Process()
        процесс.executableURL = бинарник
        процесс.arguments = ["синхронизация"] + аргументы
        процесс.currentDirectoryURL = корне
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        let часы = ContinuousClock()
        let начало = часы.now
        var запущен = false
        do {
            try процесс.run()
            запущен = true
            let предел = начало.advanced(by: .seconds(30))
            while процесс.isRunning {
                try Task.checkCancellation()
                guard часы.now < предел else { throw ОшибкаПроверкиКоманды.времяИстекло }
                try await Task.sleep(for: .milliseconds(5))
            }
            try Task.checkCancellation()
        } catch {
            if запущен {
                if процесс.isRunning {
                    guard процесс.processIdentifier > 1,
                          Darwin.kill(процесс.processIdentifier, SIGKILL) == 0 || errno == ESRCH
                    else { throw ОшибкаПроверкиКоманды.завершение }
                }
                let предел = часы.now.advanced(by: .seconds(5))
                while процесс.isRunning {
                    guard часы.now < предел else { throw ОшибкаПроверкиКоманды.завершение }
                    await Task.yield()
                }
            }
            throw error
        }
        let длительность = начало.duration(to: часы.now).components
        try вывод.synchronize()
        try ошибки.synchronize()
        guard Self.хэш(try Data(contentsOf: бинарник)) == хэш
        else { throw ОшибкаПроверкиКоманды.бинарникИзменён }
        let наблюдение = НаблюдениеКомандыСинхронизации(
            процесс: процесс.processIdentifier, код: процесс.terminationStatus,
            наносекунды: UInt64(длительность.seconds) * 1_000_000_000
                + UInt64(длительность.attoseconds / 1_000_000_000),
            вывод: try Data(contentsOf: путьВывода), ошибки: try Data(contentsOf: путьОшибок),
            хэшБинарника: хэш)
        var данные = try кодировщик.encode(наблюдение)
        данные.append(10)
        try данные.write(to: каталог.appendingPathComponent("\(экземпляр).process.json"),
            options: [.withoutOverwriting])
        return наблюдение
    }
}

private struct ОтветОтказаКомандыСинхронизации: Decodable {
    let схема: String
    let код: String
}

@Suite("Синхронизация через общий product fuma", .serialized)
struct ПроверкиКомандыСинхронизации {
    @Test func справкаОбрабатываетсяОбщимПродуктом() async throws {
        let процессы = try ПроцессыКомандыСинхронизации()
        let наблюдение = try await процессы.запустить(["--help"])
        try #require(наблюдение.код == 0)
        #expect(String(decoding: наблюдение.вывод, as: UTF8.self).contains("синхронизация"))
        #expect(наблюдение.ошибки.isEmpty)
    }

    @Test(arguments: [[], ["неизвестная-операция"], ["plan"], ["no-op"], ["--help", "лишнее"]])
    func ошибкиАргументовОстаютсяТипизированными(_ аргументы: [String]) async throws {
        let процессы = try ПроцессыКомандыСинхронизации()
        let наблюдение = try await процессы.запустить(аргументы)
        try #require(наблюдение.код == 2)
        let ответ = try JSONDecoder().decode(ОтветОтказаКомандыСинхронизации.self, from: наблюдение.вывод)
        #expect(ответ.схема == "fum.отказ-синхронизации.1")
        #expect(ответ.код == "аргументы")
        #expect(наблюдение.ошибки.isEmpty)
    }
}
