import Foundation
import Darwin

public enum РезультатСреды: Equatable, Sendable {
    case неизвестен, подтверждён(String), отказ(String)
}

/// Контракт границы среды; реализация Desktop здесь отсутствует.
public protocol ЭффектСреды: Sendable {
    func выполнить(_ действие: ВидДействияФабрики, идентификаторПопытки: String) async -> РезультатСреды
}

public protocol НаблюдательИсторииGit: Sendable {
    func проверитьПредка(база: String, наблюдаемыйHEAD: String) async -> ПроисхождениеБазы
}

public enum ЧтениеРезультатаGit {
    /// Только терминальный код проверки предка. Отказ запуска и иные коды — UNKNOWN.
    public static func происхождение(код: Int32?) -> ПроисхождениеБазы {
        switch код {
        case 0: .предок
        case 1: .неПредок
        default: .неизвестно
        }
    }
}

public struct ЗапросНаблюденияGit: Equatable, Sendable {
    public let программа: String
    public let аргументы: [String]
    public let рабочееДерево: String
    public let предельноеВремяСекунды: Int
}

/// Исполнитель обеспечивает отсутствие shell, ограничение времени и терминальный исход.
/// Неизвестный исход процесса представляется nil, не кодом не-предка.
public protocol ЧитательGit: Sendable {
    func выполнитьЧтение(_ запрос: ЗапросНаблюденияGit) async -> Int32?
}

public struct АдаптерИсторииGit: НаблюдательИсторииGit {
    public let рабочееДерево: String
    public let читатель: any ЧитательGit

    public init(рабочееДерево: String, читатель: any ЧитательGit) {
        self.рабочееДерево = рабочееДерево
        self.читатель = читатель
    }

    public func проверитьПредка(база: String, наблюдаемыйHEAD: String) async -> ПроисхождениеБазы {
        guard рабочееДерево.hasPrefix("/"), !рабочееДерево.utf8.contains(0),
              Self.полныйOID(база), Self.полныйOID(наблюдаемыйHEAD) else { return .неизвестно }
        let запрос = ЗапросНаблюденияGit(
            программа: "/usr/bin/git",
            аргументы: ["merge-base", "--is-ancestor", база, наблюдаемыйHEAD],
            рабочееДерево: рабочееДерево,
            предельноеВремяСекунды: 30)
        return ЧтениеРезультатаGit.происхождение(код: await читатель.выполнитьЧтение(запрос))
    }

    fileprivate static func полныйOID(_ значение: String) -> Bool {
        значение.utf8.count == 40 && значение.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}

/// Локальный ограниченный reader только для проверки предка двух полных OID.
/// Не использует shell, сетевые команды, очистку или изменения refs.
public struct СистемныйЧитательGit: ЧитательGit {
    public init() {}

    public func выполнитьЧтение(_ запрос: ЗапросНаблюденияGit) async -> Int32? {
        guard запрос.программа == "/usr/bin/git",
              запрос.аргументы.count == 4,
              запрос.аргументы[0] == "merge-base",
              запрос.аргументы[1] == "--is-ancestor",
              АдаптерИсторииGit.полныйOID(запрос.аргументы[2]),
              АдаптерИсторииGit.полныйOID(запрос.аргументы[3]),
              запрос.рабочееДерево.hasPrefix("/"),
              !запрос.рабочееДерево.utf8.contains(0),
              (1...30).contains(запрос.предельноеВремяСекунды) else { return nil }
        let аргументы = ["git", "--no-optional-locks", "--no-replace-objects", "-c", "protocol.allow=never", "-C", запрос.рабочееДерево] + запрос.аргументы
        let среда = ["PATH=/usr/bin:/bin", "LC_ALL=C", "GIT_CONFIG_NOSYSTEM=1", "GIT_TERMINAL_PROMPT=0", "GIT_OPTIONAL_LOCKS=0", "GIT_NO_LAZY_FETCH=1", "GIT_ALLOW_PROTOCOL="]
        var строки = аргументы.map { strdup($0) }
        var переменные = среда.map { strdup($0) }
        defer {
            for строка in строки { free(строка) }
            for переменная in переменные { free(переменная) }
        }
        guard строки.allSatisfy({ $0 != nil }), переменные.allSatisfy({ $0 != nil }) else { return nil }
        строки.append(nil)
        переменные.append(nil)
        var действия: posix_spawn_file_actions_t?
        guard posix_spawn_file_actions_init(&действия) == 0 else { return nil }
        defer { posix_spawn_file_actions_destroy(&действия) }
        var атрибуты: posix_spawnattr_t?
        guard posix_spawnattr_init(&атрибуты) == 0 else { return nil }
        defer { posix_spawnattr_destroy(&атрибуты) }
        guard posix_spawnattr_setflags(&атрибуты, Int16(POSIX_SPAWN_SETPGROUP)) == 0,
              posix_spawnattr_setpgroup(&атрибуты, 0) == 0 else { return nil }
        guard posix_spawn_file_actions_addopen(&действия, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
              posix_spawn_file_actions_addopen(&действия, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0 else { return nil }
        var идентификатор: pid_t = 0
        let запуск = строки.withUnsafeMutableBufferPointer { argv in
            переменные.withUnsafeMutableBufferPointer { envp in
                posix_spawn(&идентификатор, запрос.программа, &действия, &атрибуты, argv.baseAddress!, envp.baseAddress!)
            }
        }
        guard запуск == 0 else { return nil }
        let начало = DispatchTime.now().uptimeNanoseconds
        let лимит = UInt64(запрос.предельноеВремяСекунды) * 1_000_000_000
        var состояние: Int32 = 0
        while true {
            let результат = waitpid(идентификатор, &состояние, WNOHANG)
            if результат == идентификатор {
                guard (состояние & 0x7f) == 0 else { return nil }
                return (состояние >> 8) & 0xff
            }
            if результат < 0 && errno != EINTR { return nil }
            if Task.isCancelled || DispatchTime.now().uptimeNanoseconds - начало >= лимит {
                _ = kill(-идентификатор, SIGKILL)
                // Ожидание ограничено: неизвестность не превращается в повтор.
                let край = DispatchTime.now().uptimeNanoseconds + 1_000_000_000
                while DispatchTime.now().uptimeNanoseconds < край {
                    let завершение = waitpid(идентификатор, &состояние, WNOHANG)
                    if завершение == идентификатор || (завершение < 0 && errno != EINTR) { break }
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                return nil
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

public struct НеподдержаннаяСреда: ЭффектСреды {
    public init() {}
    public func выполнить(_ действие: ВидДействияФабрики, идентификаторПопытки: String) async -> РезультатСреды {
        _ = действие
        _ = идентификаторПопытки
        return .неизвестен
    }
}

public struct СнимокУзла: Decodable, Sendable {
    public let имя: String
    public let рабочееДерево: String
    public let ветка: String
    public let head: String
    public let дерево: String
    public let индексSHA256: String
    public let staged: Int
    public let изменённых: Int
    public let неотслеживаемых: Int
    public let владелец: String
}

public struct ФикстураУзлов: Decodable, Sendable {
    public let схема: String
    public let узлы: [СнимокУзла]
}

public enum ПредварительноеЧтение {
    public static func прочитатьФайл(_ путь: String) throws -> Data {
        let файл = open(путь, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        guard файл >= 0 else { throw ОшибкаЧтения.недоступныйФайл }
        defer { close(файл) }
        var сведения = stat()
        guard fstat(файл, &сведения) == 0,
              (сведения.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG),
              сведения.st_size >= 0, сведения.st_size <= 65_536 else { throw ОшибкаЧтения.неверныйФайл }
        var буфер = [UInt8](repeating: 0, count: 65_537)
        var прочитано = 0
        while прочитано < буфер.count {
            let количество = буфер.withUnsafeMutableBytes { байты in
                read(файл, байты.baseAddress!.advanced(by: прочитано), байты.count - прочитано)
            }
            if количество == 0 { break }
            if количество < 0 {
                if errno == EINTR { continue }
                throw ОшибкаЧтения.недоступныйФайл
            }
            прочитано += количество
        }
        guard прочитано <= 65_536, прочитано == сведения.st_size else { throw ОшибкаЧтения.неверныйФайл }
        return Data(буфер.prefix(прочитано))
    }

    public static func разобрать(_ данные: Data) throws -> [СнимокУзла] {
        guard данные.count <= 65_536 else { throw ОшибкаЧтения.слишкомБольшойВход }
        let фикстура = try JSONDecoder().decode(ФикстураУзлов.self, from: данные)
        guard фикстура.схема == "fum.фикстура-наблюдений-фабрики.1",
              (1...3).contains(фикстура.узлы.count) else { throw ОшибкаЧтения.невернаяФикстура }
        return фикстура.узлы
    }
}

public enum ОшибкаЧтения: Error { case слишкомБольшойВход, невернаяФикстура, недоступныйФайл, неверныйФайл }
