import Foundation
import Darwin
import CryptoKit
import Testing

struct СредаПроверкиЗапуска: Sendable {
    let корень: URL
    let хранилище: URL
    let бинарник: URL

    init() throws {
        let среда = ProcessInfo.processInfo.environment
        бинарник = URL(fileURLWithPath: try #require(среда["ФУМА_БИНАРНИК_ЗАПУСКА"]))
        let основание = URL(fileURLWithPath: try #require(среда["ФУМА_СВИДЕТЕЛЬСТВА_ЗАПУСКА"]))
        корень = основание.appendingPathComponent(UUID().uuidString.lowercased())
        хранилище = корень.appendingPathComponent("zapusk")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
    }

    func аргументы(_ событие: String) -> [String] {
        ["--хранилище", хранилище.path, "--событие", событие, "--профиль"]
    }
}

struct НаблюдениеПроцессаЗапуска: Codable, Sendable {
    let процесс: Int32
    let код: Int32
    let наносекунды: UInt64
    let вывод: Data
    let ошибки: Data
}

enum ОшибкаПроцессаЗапуска: Error { case бинарникИзменён, времяИстекло, завершение }

actor ПроцессыЗапуска {
    private let среда: СредаПроверкиЗапуска
    private let хэш: Data
    private var номер = 0

    init(среда: СредаПроверкиЗапуска) throws {
        self.среда = среда
        хэш = Data(SHA256.hash(data: try Data(contentsOf: среда.бинарник)))
    }

    func проверенныйХэш() throws -> String {
        guard Data(SHA256.hash(data: try Data(contentsOf: среда.бинарник))) == хэш
        else { throw ОшибкаПроцессаЗапуска.бинарникИзменён }
        return хэш.map { String(format: "%02x", $0) }.joined()
    }

    func запустить(_ аргументы: [String]) async throws -> НаблюдениеПроцессаЗапуска {
        try Task.checkCancellation()
        _ = try проверенныйХэш()
        номер += 1
        let номерЗапуска = номер
        let путьВывода = среда.корень.appendingPathComponent("\(номерЗапуска)-вывод.raw")
        let путьОшибок = среда.корень.appendingPathComponent("\(номерЗапуска)-ошибки.raw")
        guard FileManager.default.createFile(atPath: путьВывода.path, contents: nil,
                attributes: [.posixPermissions: 0o600]),
              FileManager.default.createFile(atPath: путьОшибок.path, contents: nil,
                attributes: [.posixPermissions: 0o600]) else { throw ОшибкаПроцессаЗапуска.завершение }
        let вывод = try FileHandle(forWritingTo: путьВывода)
        let ошибки = try FileHandle(forWritingTo: путьОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        let процесс = Process()
        процесс.executableURL = среда.бинарник
        процесс.arguments = аргументы
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        let часы = ContinuousClock()
        let начало = часы.now
        var запущен = false
        do {
            try процесс.run()
            запущен = true
            let предел = начало.advanced(by: .seconds(60))
            while процесс.isRunning {
                try Task.checkCancellation()
                guard часы.now < предел else { throw ОшибкаПроцессаЗапуска.времяИстекло }
                try await Task.sleep(for: .milliseconds(5))
            }
            try Task.checkCancellation()
        } catch let ошибка {
            if запущен {
                if процесс.isRunning {
                    guard процесс.processIdentifier > 1,
                        Darwin.kill(процесс.processIdentifier, SIGKILL) == 0 || errno == ESRCH
                    else { throw ОшибкаПроцессаЗапуска.завершение }
                }
                let пределЗавершения = часы.now.advanced(by: .seconds(5))
                while процесс.isRunning {
                    guard часы.now < пределЗавершения else { throw ОшибкаПроцессаЗапуска.завершение }
                    await Task.yield()
                }
            }
            throw ошибка
        }
        let интервал = начало.duration(to: часы.now).components
        _ = try проверенныйХэш()
        try вывод.synchronize()
        try ошибки.synchronize()
        let наблюдение = НаблюдениеПроцессаЗапуска(процесс: процесс.processIdentifier,
            код: процесс.terminationStatus,
            наносекунды: UInt64(интервал.seconds) * 1_000_000_000 + UInt64(интервал.attoseconds / 1_000_000_000),
            вывод: try Data(contentsOf: путьВывода), ошибки: try Data(contentsOf: путьОшибок))
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(наблюдение)
        данные.append(0x0a)
        try данные.write(to: среда.корень.appendingPathComponent("\(номерЗапуска)-процесс.json"),
            options: [.withoutOverwriting])
        return наблюдение
    }
}
