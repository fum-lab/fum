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
    public static func прочитатьФайл(_ путь: String, предел: Int = 65_536) throws -> Data {
        guard (1...(16 * 1024 * 1024)).contains(предел) else { throw ОшибкаЧтения.слишкомБольшойВход }
        let файл = open(путь, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
        guard файл >= 0 else { throw ОшибкаЧтения.недоступныйФайл }
        defer { close(файл) }
        var сведения = stat()
        guard fstat(файл, &сведения) == 0,
              (сведения.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG),
              сведения.st_size >= 0, сведения.st_size <= предел else { throw ОшибкаЧтения.неверныйФайл }
        var буфер = [UInt8](repeating: 0, count: предел + 1)
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
        guard прочитано <= предел, прочитано == сведения.st_size else { throw ОшибкаЧтения.неверныйФайл }
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

/// Только имена из `git ls-tree -rz --full-tree <полный OID>`; чтения содержимого и эффектов нет.
public struct ПолитикаПредпросмотраФабрики: Codable, Sendable {
    public let схема: String
    public let коммит: String
    public let дерево: String
    public let источникНазначений: String
    public let исключения: [String: String]
    public let роли: [String: String]
    public let владельцы: [String: String]
    /// Только принятые соответствия alias → физическая каноническая область.
    public let псевдонимы: [String: String]
    public let источникПсевдонимов: String?
}

public struct УзелПредпросмотраФабрики: Codable, Equatable, Sendable {
    public let путь: String
    public let родитель: String?
    public let дети: [String]
    public let прямыхЗаписей: Int
    public let роль: String
    public let владелец: String?
    public let каноническаяОбласть: String
    public let исключение: String?
    public let состояние: String
    public let конечнаяЗадача: String
}

public struct ПокрытиеИмёнФабрики: Codable, Sendable {
    public let схема: String
    public let коммит: String
    public let дерево: String
    public let записей: Int
    public let учтено: Int
    public let исключено: Int
    public let причиныИсключений: [String: Int]
    public let узлы: [УзелПредпросмотраФабрики]
    public let неизвестности: [String]
}

public enum ОшибкаПредпросмотраФабрики: Error {
    case невернаяПолитика, неверныйПуть, невернаяЗапись, повторПути, конфликтНазначений
}

/// Детерминированный счётчик структурной работы; не wall-clock и не доказательство сложности по байтам.
/// Сборка считает операнды соединения строк, а не скопированные UTF-8 байты.
/// Сортировка, хеширование, COW и кодирование JSON не объявляются линейными.
struct РаботаПредпросмотраФабрики: Codable, Equatable, Sendable {
    var входныхБайтов = 0
    var входныхКомпонентов = 0
    var компонентовСборкиПутей = 0
    var компонентовРазбораВыхода = 0
    var ключейСортировки = 0
    var байтовКлючейСортировки = 0
    var байтовВыходныхПутей = 0
}

public enum ПредпросмотрИмёнФабрики {
    private struct Каталог {
        let путь: String
        let родитель: Int?
        let область: String
        let применёнПсевдоним: Bool
        let исключение: String?
        var дети: [String: Int] = [:]
        var прямыхЗаписей = 0
    }

    private static func компоненты(_ путь: String) throws -> [String] {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard !путь.isEmpty, !путь.utf8.contains(0),
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ОшибкаПредпросмотраФабрики.неверныйПуть
        }
        return части
    }

    public static func построить(_ данные: Data, политика: ПолитикаПредпросмотраФабрики) throws -> ПокрытиеИмёнФабрики {
        var работа = РаботаПредпросмотраФабрики()
        return try построить(данные, политика: политика, работа: &работа)
    }

    static func построить(_ данные: Data, политика: ПолитикаПредпросмотраФабрики,
        работа: inout РаботаПредпросмотраФабрики) throws -> ПокрытиеИмёнФабрики {
        работа = РаботаПредпросмотраФабрики()
        работа.входныхБайтов = данные.count
        guard политика.схема == "fum.политика-предпросмотра-фабрики.1",
              АдаптерИсторииGit.полныйOID(политика.коммит), АдаптерИсторииGit.полныйOID(политика.дерево),
              !политика.источникНазначений.isEmpty,
              политика.псевдонимы.isEmpty || !(политика.источникПсевдонимов ?? "").isEmpty,
              данные.count <= 16 * 1024 * 1024,
              данные.isEmpty || данные.last == 0 else { throw ОшибкаПредпросмотраФабрики.невернаяПолитика }
        let служебные = Set([".git", ".build", "build", "cache", ".cache", "node_modules"])
        for путь in Set(политика.исключения.keys).union(политика.роли.keys).union(политика.владельцы.keys)
            .union(политика.псевдонимы.keys).union(политика.псевдонимы.values) { _ = try компоненты(путь) }
        guard политика.исключения.values.allSatisfy({ !$0.isEmpty }),
              политика.роли.values.allSatisfy({ !$0.isEmpty }),
              политика.владельцы.values.allSatisfy({ !$0.isEmpty }) else {
            throw ОшибкаПредпросмотраФабрики.невернаяПолитика
        }
        for (псевдоним, цель) in политика.псевдонимы {
            guard псевдоним != цель, политика.псевдонимы[цель] == nil,
                  политика.владельцы[псевдоним] == nil else { throw ОшибкаПредпросмотраФабрики.конфликтНазначений }
        }
        // Предок и потомок не получают конкурирующие owned scopes.
        for путь in политика.владельцы.keys {
            let части = try компоненты(путь)
            for конец in 1..<части.count where политика.владельцы[части.prefix(конец).joined(separator: "/")] != nil {
                throw ОшибкаПредпросмотраФабрики.конфликтНазначений
            }
        }
        // Индексы связывают уже построенные узлы: общий префикс не собирается для каждого листа.
        var каталоги = [Каталог(путь: ".", родитель: nil, область: ".",
            применёнПсевдоним: false, исключение: nil)]
        var индексПути = [".": 0]
        var пути = Set<String>(), причины: [String: Int] = [:]
        var исключено = 0
        for запись in данные.split(separator: 0) {
            guard let табуляция = запись.firstIndex(of: 9),
                  let заголовок = String(data: Data(запись[..<табуляция]), encoding: .utf8),
                  let путь = String(data: Data(запись[запись.index(after: табуляция)...]), encoding: .utf8) else {
                throw ОшибкаПредпросмотраФабрики.невернаяЗапись
            }
            let поля = заголовок.split(separator: " ")
            guard поля.count == 3, ["100644", "100755", "120000", "160000"].contains(String(поля[0])),
                  поля[1] == (поля[0] == "160000" ? "commit" : "blob"),
                  АдаптерИсторииGit.полныйOID(String(поля[2])) else { throw ОшибкаПредпросмотраФабрики.невернаяЗапись }
            guard пути.insert(путь).inserted else { throw ОшибкаПредпросмотраФабрики.повторПути }
            let части = try компоненты(путь)
            работа.входныхКомпонентов += части.count
            var текущий = 0
            for позиция in 0..<(части.count - 1) {
                let имя = части[позиция]
                if let существующий = каталоги[текущий].дети[имя] {
                    текущий = существующий
                    continue
                }
                let родитель = текущий
                let префикс: String
                if родитель == 0 { префикс = имя }
                else {
                    работа.компонентовСборкиПутей += 2
                    префикс = каталоги[родитель].путь + "/" + имя
                }
                var причина = каталоги[родитель].исключение ?? политика.исключения[префикс]
                if причина == nil && служебные.contains(имя) { причина = "служебные данные, сборка или кэш" }
                if причина == nil && части[0] == "Proyekcii" { причина = "производная проекция" }
                if причина == nil && позиция > 0 && (части[0] == "Журнал" || части[0] == "zhurnal") {
                    причина = "отдельная запись Журнала; один владелец направления"
                }
                let область: String
                let применёнПсевдоним: Bool
                if каталоги[родитель].применёнПсевдоним {
                    работа.компонентовСборкиПутей += 2
                    область = каталоги[родитель].область + "/" + имя
                    применёнПсевдоним = true
                } else if let цель = политика.псевдонимы[префикс] {
                    область = цель
                    применёнПсевдоним = true
                } else {
                    область = префикс
                    применёнПсевдоним = false
                }
                текущий = каталоги.count
                каталоги[родитель].дети[имя] = текущий
                индексПути[префикс] = текущий
                каталоги.append(Каталог(путь: префикс, родитель: родитель, область: область,
                    применёнПсевдоним: применёнПсевдоним, исключение: причина))
            }
            // Полный путь листа уже получен из входа; ещё одна сборка префиксов не нужна.
            var причина = каталоги[текущий].исключение ?? политика.исключения[путь]
            if причина == nil && служебные.contains(части[части.count - 1]) { причина = "служебные данные, сборка или кэш" }
            if причина == nil && части[0] == "Proyekcii" { причина = "производная проекция" }
            if поля[0] == "160000" { причина = причина ?? "внешняя Git-зависимость; внутренности не входят в дерево" }
            if поля[0] == "120000" { причина = причина ?? "символическая ссылка; цель не обходится" }
            if let причина { исключено += 1; причины[причина, default: 0] += 1 }
            каталоги[текущий].прямыхЗаписей += 1
        }
        for (псевдоним, цель) in политика.псевдонимы {
            guard индексПути[псевдоним] != nil, индексПути[цель] != nil,
                  !цель.hasPrefix(псевдоним + "/"), !псевдоним.hasPrefix(цель + "/") else {
                throw ОшибкаПредпросмотраФабрики.конфликтНазначений
            }
        }
        guard Set(политика.роли.keys).union(политика.владельцы.keys).isSubset(of: Set(индексПути.keys)) else {
            throw ОшибкаПредпросмотраФабрики.невернаяПолитика
        }
        работа.ключейСортировки += каталоги.count
        работа.байтовКлючейСортировки += каталоги.reduce(0) { $0 + $1.путь.utf8.count }
        let узлы = каталоги.sorted { $0.путь < $1.путь }.map { каталог in
            let область = каталог.область
            let исключение = каталог.исключение
            let дети = каталог.дети.values.map { каталоги[$0].путь }
            работа.ключейСортировки += дети.count
            работа.байтовКлючейСортировки += дети.reduce(0) { $0 + $1.utf8.count }
            let узел = УзелПредпросмотраФабрики(путь: каталог.путь,
                родитель: каталог.родитель.map { каталоги[$0].путь },
                дети: дети.sorted(), прямыхЗаписей: каталог.прямыхЗаписей,
                роль: политика.роли[область] ?? "не выбрана",
                владелец: политика.владельцы[область], каноническаяОбласть: область,
                исключение: исключение, состояние: "объявлен; развёртывание и полезная работа UNKNOWN",
                конечнаяЗадача: исключение == nil
                    ? "Сверить локальные входы и существующего владельца области; предложить одну конечную задачу родителю до назначения."
                    : "Сохранить физическое имя и основание исключения без создания отдельного писателя.")
            работа.байтовВыходныхПутей += узел.путь.utf8.count + узел.каноническаяОбласть.utf8.count
                + (узел.родитель?.utf8.count ?? 0) + узел.дети.reduce(0) { $0 + $1.utf8.count }
            return узел
        }
        return ПокрытиеИмёнФабрики(схема: "fum.предпросмотр-имён-фабрики.1", коммит: политика.коммит,
            дерево: политика.дерево, записей: пути.count, учтено: пути.count - исключено,
            исключено: исключено, причиныИсключений: причины, узлы: узлы,
            неизвестности: ["OID и источник входа сверяет вызывающий; имена сами не доказывают Git-происхождение.",
                "Неподтверждённые alias не объединены; карта без источника отклоняется.",
                "Роль и известный UUID не доказывают развёртывание, запуск, работу, доставку или использование.",
                "Локальность: родитель и прямые соседи через его индекс детей; стоимость доставки и свежесть UNKNOWN.",
                "Непринятые имена и конечные задачи требуют локального решения владельца; Native apply отсутствует."])
    }
}
