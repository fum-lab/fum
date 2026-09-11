import Foundation

/// Общая конфигурация путей для приложения и его самостоятельных помощников.
public struct ПутиПриложения: Sendable {
    public let оперативныеДанные: URL
    public let память: URL
    public let документы: URL

    public static let текущие: ПутиПриложения = {
        do { return try ПутиПриложения() }
        catch { fatalError("Неверная конфигурация путей FUM: \(error)") }
    }()

    public init(
        среда: [String: String] = ProcessInfo.processInfo.environment,
        домашнийКаталог: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws {
        let данные = домашнийКаталог.appendingPathComponent("Library/Application Support/FUM", isDirectory: true)
        оперативныеДанные = try Self.внешнийКаталог(
            среда["FUM_RUNTIME_ROOT"] ?? данные.appendingPathComponent("run").path
        )
        память = try Self.внешнийКаталог(
            среда["FUM_MEMORY_ROOT"] ?? данные.appendingPathComponent("memory").path
        )
        let путьДокументов = среда["FUM_DOCUMENTS_ROOT"] ?? домашнийКаталог.appendingPathComponent("Documents").path
        guard NSString(string: путьДокументов).isAbsolutePath else {
            throw ОшибкаПутей.относительныйКаталог
        }
        документы = URL(fileURLWithPath: путьДокументов, isDirectory: true).standardizedFileURL
    }

    /// Никаких каталогов не создаёт; отклоняет запись внутрь checkout и его symlink-псевдонимов.
    public static func внешнийКаталог(_ путь: String) throws -> URL {
        guard NSString(string: путь).isAbsolutePath else { throw ОшибкаПутей.относительныйКаталог }
        let результат = URL(fileURLWithPath: путь, isDirectory: true).standardizedFileURL.resolvingSymlinksInPath()
        var предок = результат
        while true {
            if FileManager.default.fileExists(atPath: предок.appendingPathComponent(".git").path) {
                throw ОшибкаПутей.каталогИсходников
            }
            let следующий = предок.deletingLastPathComponent()
            if следующий.path == предок.path { break }
            предок = следующий
        }
        return результат
    }

    /// Разрешает явный абсолютный файл или команду в абсолютных каталогах PATH; ничего не запускает.
    public static func исполняемыйФайл(
        _ имя: String, среда: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        let кандидаты: [URL]
        if NSString(string: имя).isAbsolutePath {
            кандидаты = [URL(fileURLWithPath: имя)]
        } else {
            guard !имя.contains("/") else { return nil }
            кандидаты = (среда["PATH"] ?? "").split(separator: ":").compactMap { каталог in
                guard NSString(string: String(каталог)).isAbsolutePath else { return nil }
                return URL(fileURLWithPath: String(каталог)).appendingPathComponent(имя)
            }
        }
        return кандидаты.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}

public enum ОшибкаПутей: Error {
    case относительныйКаталог
    case каталогИсходников
}
