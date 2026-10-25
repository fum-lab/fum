import Foundation
import Darwin

enum ПутиМанифеста {
    static func проверить(_ путь: String) throws {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        try требоватьМанифест(!путь.isEmpty && путь.utf8.count <= 4096 && !путь.contains("\\")
            && !путь.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
            && части.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".."
                && $0.lowercased() != ".git" && $0.utf8.count <= 255 }, "небезопасный-путь")
    }

    static func вложен(_ путь: String, в родитель: String) -> Bool {
        путь == родитель || путь.hasPrefix(родитель + "/")
    }
}

final class ЧитательПутейМанифеста {
    private let дескриптор: CInt
    private let корень: URL

    init(_ корень: URL) throws {
        try требоватьМанифест(корень.isFileURL && корень.path.hasPrefix("/")
            && корень.path == корень.standardizedFileURL.path
            && корень.path == корень.resolvingSymlinksInPath().path, "нефизический-корень")
        let открытый = open(корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        try требоватьМанифест(открытый >= 0, "недоступный-корень")
        self.дескриптор = открытый
        self.корень = корень
    }

    deinit { close(дескриптор) }

    func проверитьНазначение(_ путь: String) throws -> Bool {
        try ПутиМанифеста.проверить(путь)
        var текущий = dup(дескриптор)
        try требоватьМанифест(текущий >= 0, "недоступный-дескриптор")
        defer { close(текущий) }
        let части = путь.split(separator: "/").map(String.init)
        for (номер, часть) in части.enumerated() {
            let новый = openat(текущий, часть, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK
                | (номер < части.count - 1 ? O_DIRECTORY : 0))
            if новый < 0 && errno == ENOENT { return false }
            try требоватьМанифест(новый >= 0, "небезопасный-префикс-назначения")
            close(текущий); текущий = новый
        }
        var сведения = stat()
        try требоватьМанифест(fstat(текущий, &сведения) == 0
            && [S_IFREG, S_IFDIR].contains(сведения.st_mode & S_IFMT), "необычное-назначение")
        return true
    }

    func каталог(_ путь: String) throws -> Bool {
        try ПутиМанифеста.проверить(путь)
        var текущий = dup(дескриптор)
        try требоватьМанифест(текущий >= 0, "недоступный-дескриптор")
        defer { close(текущий) }
        let части = путь.split(separator: "/").map(String.init)
        for (номер, часть) in части.enumerated() {
            let флаги = O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK
                | (номер < части.count - 1 ? O_DIRECTORY : 0)
            let новый = openat(текущий, часть, флаги)
            try требоватьМанифест(новый >= 0, "недоступный-или-символический-путь")
            close(текущий); текущий = новый
        }
        var сведения = stat()
        try требоватьМанифест(fstat(текущий, &сведения) == 0, "недоступный-тип")
        let тип = сведения.st_mode & S_IFMT
        try требоватьМанифест(тип == S_IFREG || тип == S_IFDIR, "необычный-тип")
        return тип == S_IFDIR
    }

    func файлы(_ путь: String) throws -> [String] {
        guard try каталог(путь) else { return [путь] }
        let имена = try FileManager.default.contentsOfDirectory(atPath: корень.appendingPathComponent(путь).path)
            .sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }
        var результат: [String] = []
        for имя in имена {
            try требоватьМанифест(имя.lowercased() != ".git", "служебная-область-в-цели")
            результат += try файлы(путь + "/" + имя)
        }
        return результат
    }
}
