import Foundation
import Darwin

public struct РезультатПроцесса {
    public var код: Int32
    public var вывод: String
    public var ошибки: String
}
public enum Исполнитель {
    public static func выполнить(_ программа: String, _ аргументы: [String], предел: TimeInterval = 60,
                                 среда: [String: String] = [:], вход: Data? = nil) throws -> РезультатПроцесса {
        guard предел > 0, предел.isFinite, программа.hasPrefix("/"), !программа.contains("\0"),
              !аргументы.contains(where: { $0.contains("\0") }) else { throw ОшибкаМашины("Неверная команда или предел ожидания.") }
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent("fum-vm-process-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: каталог) }
        func поток(_ имя: String) throws -> FileHandle {
            let путь = каталог.appendingPathComponent(имя).path
            let файл = Darwin.open(путь, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            guard файл >= 0 else { throw ОшибкаМашины("Не удалось создать закрытый поток команды.") }
            return FileHandle(fileDescriptor: файл, closeOnDealloc: true)
        }
        let вывод = try поток("stdout"), ошибки = try поток("stderr")
        let входнойПоток = try поток("stdin")
        if let вход {
            guard вход.count <= 4 * 1024 * 1024 else { throw ОшибкаМашины("Вход процесса превышает 4 MiB.") }
            try входнойПоток.write(contentsOf: вход)
            try входнойПоток.seek(toOffset: 0)
        }
        var окружение = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("DYLD_") }
        окружение.merge(среда, uniquingKeysWith: { _, новое in новое })
        guard окружение.allSatisfy({ !$0.key.contains("=") && !$0.key.contains("\0") && !$0.value.contains("\0") }) else {
            throw ОшибкаМашины("Неверная переменная окружения процесса.")
        }
        var действия: posix_spawn_file_actions_t?, атрибуты: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&действия) == 0 else { throw ОшибкаМашины("Не удалось подготовить дескрипторы процесса.") }
        defer { posix_spawn_file_actions_destroy(&действия) }
        guard posix_spawnattr_init(&атрибуты) == 0 else { throw ОшибкаМашины("Не удалось подготовить атрибуты процесса.") }
        defer { posix_spawnattr_destroy(&атрибуты) }
        for (исходный, целевой) in [(входнойПоток.fileDescriptor, STDIN_FILENO), (вывод.fileDescriptor, STDOUT_FILENO), (ошибки.fileDescriptor, STDERR_FILENO)] {
            guard posix_spawn_file_actions_adddup2(&действия, исходный, целевой) == 0 else { throw ОшибкаМашины("Не удалось привязать поток процесса.") }
        }
        var пустые = sigset_t(), обычные = sigset_t()
        sigemptyset(&пустые); sigfillset(&обычные)
        let флаги = Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_CLOEXEC_DEFAULT)
        guard posix_spawnattr_setflags(&атрибуты, флаги) == 0,
              posix_spawnattr_setpgroup(&атрибуты, 0) == 0,
              posix_spawnattr_setsigmask(&атрибуты, &пустые) == 0,
              posix_spawnattr_setsigdefault(&атрибуты, &обычные) == 0 else { throw ОшибкаМашины("Не удалось изолировать группу процесса.") }
        let строкиАргументов = ([программа] + аргументы).map { strdup($0)! }
        let строкиСреды = окружение.sorted { $0.key < $1.key }.map { strdup($0.key + "=" + $0.value)! }
        defer { (строкиАргументов + строкиСреды).forEach { free($0) } }
        var argv = строкиАргументов.map(Optional.some) + [nil], envp = строкиСреды.map(Optional.some) + [nil]
        var процесс: pid_t = 0
        let кодЗапуска = argv.withUnsafeMutableBufferPointer { a in
            envp.withUnsafeMutableBufferPointer { e in posix_spawn(&процесс, программа, &действия, &атрибуты, a.baseAddress!, e.baseAddress!) }
        }
        guard кодЗапуска == 0 else { throw ОшибкаМашины("Не удалось выполнить процесс, код POSIX \(кодЗапуска).") }
        let начало = DispatchTime.now().uptimeNanoseconds
        var статус: Int32 = 0
        while true {
            let наблюдение = waitpid(процесс, &статус, WNOHANG)
            if наблюдение == процесс { break }
            if наблюдение < 0 && errno == EINTR { continue }
            guard наблюдение == 0 else { kill(-процесс, SIGKILL); throw ОшибкаМашины("Не удалось получить статус своего процесса.") }
            if Double(DispatchTime.now().uptimeNanoseconds - начало) / 1e9 > предел {
                kill(-процесс, SIGTERM)
                let граница = DispatchTime.now().uptimeNanoseconds
                var собран = false
                while DispatchTime.now().uptimeNanoseconds - граница < 2_000_000_000 {
                    if waitpid(процесс, &статус, WNOHANG) == процесс { собран = true; break }
                    usleep(20_000)
                }
                // Группа создаётся до exec; позднее дерево PID не обходится.
                kill(-процесс, SIGKILL)
                if !собран { while waitpid(процесс, &статус, 0) < 0 && errno == EINTR {} }
                throw ОшибкаМашины("Команда превысила предел \(предел) с; её группа остановлена, результат не принят.")
            }
            usleep(20_000)
        }
        if kill(-процесс, 0) == 0 {
            kill(-процесс, SIGKILL)
            throw ОшибкаМашины("После завершения команды остались потомки; группа остановлена, результат не принят.")
        }
        func текст(_ поток: FileHandle) throws -> String {
            try поток.seek(toOffset: 0)
            let байты = try поток.read(upToCount: 16 * 1024 * 1024 + 1) ?? Data()
            guard байты.count <= 16 * 1024 * 1024 else { throw ОшибкаМашины("Вывод команды превысил 16 MiB.") }
            return String(decoding: байты, as: UTF8.self)
        }
        let код = статус & 0x7f == 0 ? (статус >> 8) & 0xff : 128 + (статус & 0x7f)
        return РезультатПроцесса(код: код, вывод: try текст(вывод), ошибки: try текст(ошибки))
    }
}

public struct СобытиеМашины: Codable, Equatable {
    public var идентификатор: String
    public var родитель: String?
    public var операция: String
    public var длительностьНс: UInt64?
    public var исход: String
    public init(идентификатор: String, родитель: String?, операция: String, длительностьНс: UInt64?, исход: String) {
        self.идентификатор = идентификатор; self.родитель = родитель; self.операция = операция
        self.длительностьНс = длительностьНс; self.исход = исход
    }
}
public func объединитьСобытия(_ события: [СобытиеМашины]) throws -> [СобытиеМашины] {
    var уникальные: [String: СобытиеМашины] = [:]
    for событие in события {
        guard UUID(uuidString: событие.идентификатор) != nil else { throw ОшибкаМашины("Неверный UUID события.") }
        if let прежнее = уникальные[событие.идентификатор], прежнее != событие {
            throw ОшибкаМашины("Один UUID события содержит разные байты; импорт остановлен.")
        }
        уникальные[событие.идентификатор] = событие
    }
    return уникальные.values.sorted { $0.идентификатор < $1.идентификатор }
}

public final class МетрикиМашины {
    public let хранилище: Хранилище
    private var родители: [String] = []
    public var текущийРодитель: String? { родители.last }
    public init(_ хранилище: Хранилище) { self.хранилище = хранилище }
    public func измерить<T>(_ название: String, _ действие: () throws -> T) throws -> T {
        let идентификатор = UUID().uuidString.lowercased()
        var событие = СобытиеМашины(идентификатор: идентификатор, родитель: родители.last, операция: название,
                                    длительностьНс: nil, исход: "выполняется")
        let имя = "событие-" + идентификатор + ".json"
        try хранилище.записать(имя, байты: кодировать(событие))
        let начало = DispatchTime.now().uptimeNanoseconds
        родители.append(идентификатор)
        defer { родители.removeLast() }
        do {
            let результат = try действие()
            событие.длительностьНс = DispatchTime.now().uptimeNanoseconds - начало
            событие.исход = "успех"
            try хранилище.записать(имя, байты: кодировать(событие))
            return результат
        } catch {
            событие.длительностьНс = DispatchTime.now().uptimeNanoseconds - начало
            событие.исход = "ошибка"
            try хранилище.записать(имя, байты: кодировать(событие))
            throw error
        }
    }
    @discardableResult
    public func команда(_ название: String, _ программа: String, _ аргументы: [String], предел: TimeInterval = 60,
                        среда: [String: String] = [:]) throws -> РезультатПроцесса {
        try измерить(название) {
            let результат = try Исполнитель.выполнить(программа, аргументы, предел: предел, среда: среда)
            guard результат.код == 0 else {
                throw ОшибкаМашины("\(название): код \(результат.код). \(результат.ошибки.suffix(2000))")
            }
            return результат
        }
    }
}
