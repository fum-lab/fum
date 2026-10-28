import Foundation
import CryptoKit
import Darwin

enum ОтказЧитателяЯзыка: Error, Equatable {
    case гит, предел, формат, дрейф, политика
    case путь(String)
}

struct ИзменениеИндексаЯзыка {
    let путь: String
    let старыйОбъект: String
    let новыйОбъект: String
    let режим: String
    let статус: String
}

struct ЧитательГитЯзыка {
    let корень: String
    let среда: [String: String]

    static func окружение(_ исходное: [String: String]) -> [String: String] {
        var окружение = исходное
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        окружение["GIT_NO_REPLACE_OBJECTS"] = "1"
        окружение["GIT_NO_LAZY_FETCH"] = "1"
        return окружение
    }

    static func физическийПуть(_ путь: String) throws -> String {
        guard let адрес = путь.withCString({ Darwin.realpath($0, nil) }) else {
            throw ОтказЧитателяЯзыка.путь("realpath")
        }
        defer { free(адрес) }
        return String(cString: адрес)
    }

    func выполнить(_ аргументы: [String], предел: Int = 4_194_304) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["--no-optional-locks", "--literal-pathspecs", "-c", "core.fsmonitor=false",
                              "-C", корень] + аргументы
        процесс.environment = Self.окружение(среда) // Включая effective GIT_INDEX_FILE настоящего Git hook.
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        var данные = Data()
        var превышен = false
        while true {
            let часть = канал.fileHandleForReading.readData(ofLength: 65_536)
            if часть.isEmpty { break }
            if !превышен, часть.count <= предел - данные.count { данные.append(часть) }
            else {
                if !превышен { процесс.terminate() }
                превышен = true
            }
        }
        процесс.waitUntilExit()
        guard !превышен else { throw ОтказЧитателяЯзыка.предел }
        guard процесс.terminationReason == .exit, процесс.terminationStatus == 0 else {
            throw ОтказЧитателяЯзыка.гит
        }
        return данные
    }

    func строка(_ аргументы: [String]) throws -> String {
        let данные = try выполнить(аргументы)
        guard let текст = String(data: данные, encoding: .utf8), текст.hasSuffix("\n") else {
            throw ОтказЧитателяЯзыка.формат
        }
        return String(текст.dropLast())
    }

    func байтыОбъекта(_ объект: String) throws -> Data {
        guard let размер = Int(try строка(["cat-file", "-s", объект])), размер >= 0,
              размер <= 4_194_304 else { throw ОтказЧитателяЯзыка.предел }
        let данные = try выполнить(["cat-file", "blob", объект])
        guard данные.count == размер else { throw ОтказЧитателяЯзыка.дрейф }
        return данные
    }

    func дельта(_ основа: String) throws -> Data {
        try выполнить(["diff", "--cached", "--raw", "-z", "--no-abbrev", "--no-renames",
            "--no-ext-diff", "--no-textconv", основа, "--"])
    }

    static func изменения(_ данные: Data) throws -> [ИзменениеИндексаЯзыка] {
        guard данные.isEmpty || данные.last == 0 else { throw ОтказЧитателяЯзыка.формат }
        let части = данные.split(separator: 0, omittingEmptySubsequences: false).dropLast()
        guard части.count % 2 == 0 else { throw ОтказЧитателяЯзыка.формат }
        let записи = Array(части)
        var результат: [ИзменениеИндексаЯзыка] = []
        for номер in stride(from: 0, to: записи.count, by: 2) {
            guard let заголовок = String(data: записи[номер], encoding: .utf8),
                  let путь = String(data: записи[номер + 1], encoding: .utf8),
                  !путь.isEmpty, !путь.hasPrefix("/"),
                  путь.split(separator: "/").allSatisfy({ $0 != "." && $0 != ".." }) else {
                throw ОтказЧитателяЯзыка.формат
            }
            let поля = заголовок.split(separator: " ").map(String.init)
            guard поля.count == 5, поля[0].hasPrefix(":"), ["A", "M", "D", "T"].contains(поля[4]),
                  объект(поля[2]), объект(поля[3]) else { throw ОтказЧитателяЯзыка.формат }
            результат.append(.init(путь: путь, старыйОбъект: поля[2], новыйОбъект: поля[3],
                режим: поля[1], статус: поля[4]))
        }
        return результат
    }

    func объектИндекса(_ путь: String) throws -> String {
        let данные = try выполнить(["ls-files", "--stage", "-z", "--", путь])
        guard данные.last == 0, данные.dropLast().contains(0) == false,
              let раздел = данные.firstIndex(of: 9),
              let заголовок = String(data: данные[..<раздел], encoding: .utf8),
              Data(данные[(раздел + 1)..<данные.index(before: данные.endIndex)]) == Data(путь.utf8)
        else { throw ОтказЧитателяЯзыка.политика }
        let поля = заголовок.split(separator: " ").map(String.init)
        guard поля.count == 3, поля[0] == "100644", объект(поля[1]), поля[2] == "0" else {
            throw ОтказЧитателяЯзыка.политика
        }
        return поля[1]
    }

    static func вычислитьХэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private static func объект(_ текст: String) -> Bool {
        [40, 64].contains(текст.utf8.count) && текст.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private func объект(_ текст: String) -> Bool { Self.объект(текст) }
}
