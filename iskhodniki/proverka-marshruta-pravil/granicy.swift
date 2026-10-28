import Darwin
import Foundation

struct ГраницаCheckout {
    let корень: URL

    init(_ исходныйКорень: URL) throws {
        guard let физический = realpath(исходныйКорень.path, nil) else {
            throw ОтказМаршрутаПравил(.выходЗаCheckout, "Корень checkout недоступен")
        }
        defer { free(физический) }
        корень = URL(fileURLWithPath: String(cString: физический), isDirectory: true)
    }

    func файл(
        _ относительный: String,
        отсутствует категория: ОтказМаршрутаПравил.Категория
    ) throws -> URL {
        let части = относительный.split(separator: "/", omittingEmptySubsequences: false)
        guard !относительный.isEmpty, !относительный.hasPrefix("/"),
              !относительный.contains("\\"), !относительный.contains("://"),
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git" }) else {
            throw ОтказМаршрутаПравил(.выходЗаCheckout, "Небезопасный путь \(относительный)")
        }
        var текущий = корень
        for сыраяЧасть in части {
            let часть = String(сыраяЧасть)
            let имена: [String]
            do {
                имена = try FileManager.default.contentsOfDirectory(atPath: текущий.path)
            } catch {
                throw ОтказМаршрутаПравил(категория, "Не найден \(относительный)")
            }
            guard let точное = имена.first(where: { Data($0.utf8) == Data(часть.utf8) }) else {
                if let похожее = имена.first(where: {
                    $0.compare(часть, options: [.caseInsensitive, .literal]) == .orderedSame
                }) {
                    throw ОтказМаршрутаПравил(
                        .неверныйРегистр,
                        "Компонент \(часть) не совпадает с фактическим \(похожее)")
                }
                throw ОтказМаршрутаПравил(категория, "Не найден \(относительный)")
            }
            текущий.appendPathComponent(точное)
            var сведения = stat()
            guard lstat(текущий.path, &сведения) == 0 else {
                throw ОтказМаршрутаПравил(категория, "Не найден \(относительный)")
            }
            guard (сведения.st_mode & S_IFMT) != S_IFLNK else {
                throw ОтказМаршрутаПравил(
                    .символическаяСсылка, "Путь \(относительный) содержит symlink")
            }
        }
        let физический: String
        guard let resolved = realpath(текущий.path, nil) else {
            throw ОтказМаршрутаПравил(категория, "Не найден \(относительный)")
        }
        физический = String(cString: resolved)
        free(resolved)
        let префикс = корень.path.hasSuffix("/") ? корень.path : корень.path + "/"
        guard физический == корень.path || физический.hasPrefix(префикс) else {
            throw ОтказМаршрутаПравил(
                .выходЗаCheckout, "Путь \(относительный) вышел за checkout")
        }
        var сведения = stat()
        guard lstat(текущий.path, &сведения) == 0,
              (сведения.st_mode & S_IFMT) == S_IFREG else {
            throw ОтказМаршрутаПравил(категория, "Путь \(относительный) не обычный файл")
        }
        return текущий
    }
}

enum ЗагрузкаИсходногоСнимка {
    static func загрузить(
        _ снимок: ИсходныйСнимок,
        корень: URL,
        источник: ИсточникСнимкаПравил
    ) throws -> Data {
        guard полныйGitOID(снимок.commit), полныйGitOID(снимок.blob),
              снимок.строк >= 0, снимок.unicodeСимволов >= 0, снимок.байтов >= 0,
              корректныйSHA256(снимок.sha256) else {
            throw ОтказМаршрутаПравил(.исходныйСнимок, "Некорректная идентичность снимка")
        }
        let данные: Data
        switch источник {
        case .данные(let вход):
            данные = вход
        case .git:
            let show = try git(["show", "\(снимок.commit):AGENTS.md"], корень: корень)
            guard show.код == 0 else {
                throw ОтказМаршрутаПравил(.исходныйСнимок, "Снимок AGENTS.md недоступен")
            }
            let blob = try git(["rev-parse", "\(снимок.commit):AGENTS.md"], корень: корень)
            guard blob.код == 0,
                  String(decoding: blob.данные, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines) == снимок.blob else {
                throw ОтказМаршрутаПравил(.исходныйСнимок, "Git blob снимка не совпадает")
            }
            данные = show.данные
        }
        guard let текст = String(data: данные, encoding: .utf8) else {
            throw ОтказМаршрутаПравил(.исходныйСнимок, "Снимок не является UTF-8")
        }
        let строк = числоСтрокКакSplitlines(текст)
        guard данные.count == снимок.байтов,
              текст.unicodeScalars.count == снимок.unicodeСимволов,
              строк == снимок.строк,
              хэшSHA256(данные) == снимок.sha256 else {
            throw ОтказМаршрутаПравил(.исходныйСнимок, "Метрики или хэш снимка не совпадают")
        }
        return данные
    }

    private struct GitРезультат {
        let код: Int32
        let данные: Data
    }

    private static func git(_ аргументы: [String], корень: URL) throws -> GitРезультат {
        let процесс = Process()
        let поток = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = [
            "-C", корень.path,
            "-c", "core.hooksPath=/dev/null",
            "-c", "core.fsmonitor=false",
        ] + аргументы
        процесс.standardOutput = поток
        процесс.standardError = поток
        var окружение = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        окружение["GIT_CONFIG_NOSYSTEM"] = "1"
        окружение["GIT_CONFIG_GLOBAL"] = "/dev/null"
        окружение["GIT_NO_REPLACE_OBJECTS"] = "1"
        окружение["GIT_TERMINAL_PROMPT"] = "0"
        окружение["LC_ALL"] = "C"
        процесс.environment = окружение
        try процесс.run()
        let данные = поток.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationReason == .exit else {
            throw ОтказМаршрутаПравил(.исходныйСнимок, "Git завершён сигналом")
        }
        return GitРезультат(код: процесс.terminationStatus, данные: данные)
    }
}

func числоСтрокКакSplitlines(_ текст: String) -> Int {
    guard !текст.isEmpty else { return 0 }
    var число = 0
    var предыдущийCR = false
    for scalar in текст.unicodeScalars {
        switch scalar.value {
        case 10:
            if !предыдущийCR { число += 1 }
            предыдущийCR = false
        case 13:
            число += 1
            предыдущийCR = true
        case 0x0B, 0x0C, 0x1C, 0x1D, 0x1E, 0x85, 0x2028, 0x2029:
            число += 1
            предыдущийCR = false
        default:
            предыдущийCR = false
        }
    }
    let последний = текст.unicodeScalars.last?.value
    let заканчиваетсяРазделителем = [10, 13, 0x0B, 0x0C, 0x1C, 0x1D, 0x1E, 0x85, 0x2028, 0x2029]
        .contains(последний)
    return заканчиваетсяРазделителем ? число : число + 1
}

func содержаниеБезRecency(_ текст: String) -> String {
    let началоМаркер = "<!-- FUM-MD-RECENCY:BEGIN -->"
    let конецМаркер = "<!-- FUM-MD-RECENCY:END -->"
    guard let начало = текст.range(of: началоМаркер, options: .backwards),
          let конец = текст.range(of: конецМаркер, range: начало.upperBound..<текст.endIndex),
          текст[конец.upperBound...].allSatisfy({ $0.isWhitespace }) else {
        return текст
    }
    var граница = начало.lowerBound
    if граница > текст.startIndex {
        let предыдущий = текст.index(before: граница)
        if текст[предыдущий] == "\n" { граница = предыдущий }
    }
    return String(текст[..<граница])
}
