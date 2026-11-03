import Foundation

public enum ОшибкаНаблюдателяРепозитория: Error, Equatable {
    case аргументы
    case корень
    case неРепозиторий
    case ветка
    case коммит
    case статус
    case путь
    case кодировка
    case выводСлишкомВелик
    case отказСистемнойКоманды
}

public struct СнимокРепозитория: Codable, Equatable, Sendable {
    public let схема: String
    public let корень: String
    public let коммит: String
    public let ссылка: String
    public let изменённыеПути: [String]
    public let неотслеживаемыеПути: [String]

    public init(корень: String, коммит: String, ссылка: String,
                изменённыеПути: [String], неотслеживаемыеПути: [String]) {
        self.схема = "fuma.снимок-репозитория.1"
        self.корень = корень
        self.коммит = коммит
        self.ссылка = ссылка
        self.изменённыеПути = изменённыеПути
        self.неотслеживаемыеПути = неотслеживаемыеПути
    }
}

public enum НаблюдательРепозитория {
    private static let пределВывода = 1_048_576

    /// Принимает только физический корень репозитория; команды Git закреплены внутри адаптера.
    public static func наблюдать(корень: URL) throws -> СнимокРепозитория {
        guard корень.isFileURL, корень.path.hasPrefix("/"),
            корень.query == nil, корень.fragment == nil,
            let физическийУказатель = realpath(корень.path, nil)
        else { throw ОшибкаНаблюдателяРепозитория.корень }
        defer { free(физическийУказатель) }
        let физическийКорень = String(cString: физическийУказатель)
        var каталог = ObjCBool(false)
        guard корень.path == физическийКорень,
            FileManager.default.fileExists(atPath: физическийКорень, isDirectory: &каталог),
            каталог.boolValue
        else { throw ОшибкаНаблюдателяРепозитория.корень }

        let вершина: Data
        do {
            вершина = try выполнитьКоманду(["rev-parse", "--show-toplevel"], корень: физическийКорень)
        } catch ОшибкаНаблюдателяРепозитория.отказСистемнойКоманды {
            throw ОшибкаНаблюдателяРепозитория.неРепозиторий
        }
        guard let вершинаСтрока = String(data: вершина, encoding: .utf8),
            убратьLF(вершинаСтрока) == физическийКорень
        else { throw ОшибкаНаблюдателяРепозитория.неРепозиторий }

        let коммитДанные = try выполнитьКоманду(["rev-parse", "--verify", "HEAD^{commit}"], корень: физическийКорень)
        guard let коммитСтрока = String(data: коммитДанные, encoding: .utf8) else {
            throw ОшибкаНаблюдателяРепозитория.кодировка
        }
        let коммит = убратьLF(коммитСтрока)
        guard (коммит.count == 40 || коммит.count == 64),
            коммит.allSatisfy({ $0.isASCII && ($0.isNumber || ("a"..."f").contains($0)) })
        else { throw ОшибкаНаблюдателяРепозитория.коммит }

        let ссылкаДанные = try выполнитьКоманду(["rev-parse", "--symbolic-full-name", "HEAD"], корень: физическийКорень)
        guard let ссылкаСтрока = String(data: ссылкаДанные, encoding: .utf8) else {
            throw ОшибкаНаблюдателяРепозитория.кодировка
        }
        let ссылка = убратьLF(ссылкаСтрока)
        guard ссылка.hasPrefix("refs/heads/"),
            ссылка.dropFirst("refs/heads/".count).split(separator: "/", omittingEmptySubsequences: false)
                .allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ОшибкаНаблюдателяРепозитория.ветка }

        let статус = try выполнитьКоманду(
            ["status", "--porcelain=v2", "-z", "--untracked-files=all", "--ignore-submodules=all"],
            корень: физическийКорень)
        let (изменённые, неотслеживаемые) = try разобратьСтатус(статус)
        return СнимокРепозитория(корень: физическийКорень, коммит: коммит, ссылка: ссылка,
            изменённыеПути: изменённые, неотслеживаемыеПути: неотслеживаемые)
    }

    private static func убратьLF(_ текст: String) -> String {
        if текст.last == "\n" { return String(текст.dropLast()) }
        return текст
    }

    private static func выполнитьКоманду(_ аргументы: [String], корень: String) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["-c", "core.fsmonitor=false"] + аргументы
        процесс.currentDirectoryURL = URL(fileURLWithPath: корень, isDirectory: true)
        процесс.environment = [
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_OPTIONAL_LOCKS": "0",
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_CEILING_DIRECTORIES": корень
        ]
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = канал
        do {
            try процесс.run()
        } catch {
            throw ОшибкаНаблюдателяРепозитория.отказСистемнойКоманды
        }
        var данные = Data()
        while true {
            let порция: Data
            do {
                порция = try канал.fileHandleForReading.read(upToCount: 65_536) ?? Data()
            } catch {
                процесс.terminate()
                процесс.waitUntilExit()
                throw ОшибкаНаблюдателяРепозитория.отказСистемнойКоманды
            }
            if порция.isEmpty { break }
            guard данные.count + порция.count <= пределВывода else {
                процесс.terminate()
                процесс.waitUntilExit()
                throw ОшибкаНаблюдателяРепозитория.выводСлишкомВелик
            }
            данные.append(порция)
        }
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else { throw ОшибкаНаблюдателяРепозитория.отказСистемнойКоманды }
        return данные
    }

    private static func разобратьСтатус(_ данные: Data) throws -> ([String], [String]) {
        guard данные.isEmpty || данные.last == 0 else { throw ОшибкаНаблюдателяРепозитория.статус }
        if данные.isEmpty { return ([], []) }
        let кадры = данные.split(separator: 0, omittingEmptySubsequences: false)
        guard кадры.last?.isEmpty == true else { throw ОшибкаНаблюдателяРепозитория.статус }
        var изменённые = Set<String>()
        var неотслеживаемые = Set<String>()
        var индекс = 0
        while индекс < кадры.count - 1 {
            let кадр = Data(кадры[индекс])
            guard let разделитель = кадр.firstIndex(of: 0x20),
                let тип = String(data: кадр[..<разделитель], encoding: .utf8)
            else { throw ОшибкаНаблюдателяРепозитория.статус }
            let хвост = Data(кадр: кадр, после: разделитель)
            switch тип {
            case "1":
                let поля = хвост.split(separator: 0x20, maxSplits: 7, omittingEmptySubsequences: false)
                guard поля.count == 8 else { throw ОшибкаНаблюдателяРепозитория.статус }
                изменённые.insert(try проверитьПуть(Data(поля[7])))
            case "2":
                let поля = хвост.split(separator: 0x20, maxSplits: 8, omittingEmptySubsequences: false)
                guard поля.count == 9, индекс + 1 < кадры.count - 1 else {
                    throw ОшибкаНаблюдателяРепозитория.статус
                }
                изменённые.insert(try проверитьПуть(Data(поля[8])))
                изменённые.insert(try проверитьПуть(Data(кадры[индекс + 1])))
                индекс += 1
            case "u":
                let поля = хвост.split(separator: 0x20, maxSplits: 9, omittingEmptySubsequences: false)
                guard поля.count == 10 else { throw ОшибкаНаблюдателяРепозитория.статус }
                изменённые.insert(try проверитьПуть(Data(поля[9])))
            case "?":
                неотслеживаемые.insert(try проверитьПуть(хвост))
            case "!":
                break
            default:
                throw ОшибкаНаблюдателяРепозитория.статус
            }
            индекс += 1
        }
        return (изменённые.sorted(), неотслеживаемые.sorted())
    }

    private static func проверитьПуть(_ данные: Data) throws -> String {
        guard let путь = String(data: данные, encoding: .utf8), !путь.isEmpty,
            !путь.hasPrefix("/"),
            путь.split(separator: "/", omittingEmptySubsequences: false)
                .allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ОшибкаНаблюдателяРепозитория.путь }
        return путь
    }
}

private extension Data {
    init(кадр данные: Data, после индекс: Data.Index) {
        self = Data(данные[данные.index(after: индекс)...])
    }
}
