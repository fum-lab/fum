import Foundation
import Darwin
import Testing

#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

private final class ФикстураНаблюденияГруппы {
    let корень: URL
    let исходы: URL
    init() throws {
        let адрес = FileManager.default.temporaryDirectory.appendingPathComponent("fum-group-watch-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: адрес, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        guard let физический = Darwin.realpath(адрес.path, nil) else {
            throw ОшибкаНаблюденияГруппы.отказ("fixture-realpath")
        }
        defer { free(физический) }
        корень = URL(fileURLWithPath: String(cString: физический), isDirectory: true)
        исходы = корень.appendingPathComponent("run")
        try FileManager.default.createDirectory(at: исходы, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    }
    deinit { try? FileManager.default.removeItem(at: корень) }
    func запрос(_ режим: String, память: UInt64 = 134_217_728, вывод: Int = 65_536, членов: Int = 32) throws -> Data {
        let программа = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
        let запрос = ЗапросНаблюденияГруппы(схема: "fum.запрос-наблюдения-группы.1",
            поколение: UUID().uuidString, программа: программа,
            программаSHA256: НаблюдательГруппыПроцессов.хэш(try Data(contentsOf: URL(fileURLWithPath: программа))),
            аргументы: ["--fixture", режим], рабочийКаталог: корень.path,
            каталогИсходов: исходы.path, исходники: [],
            пределы: .init(миллисекунды: 2_000, очисткаМиллисекунд: 1_000,
                памятьБайт: память, выводБайт: вывод, членов: членов))
        let кодер = JSONEncoder(); кодер.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try кодер.encode(запрос)
    }
}

@Suite(.serialized) struct ПроверкиНаблюдателяГруппы {
    @Test func наблюдательСохраняетВыводИПодтверждаетОтсутствиеГруппы() throws {
        let фикстура = try ФикстураНаблюденияГруппы()
        let итог = try НаблюдательГруппыПроцессов.выполнить(фикстура.запрос("echo"))
        #expect(итог.статус == "completed")
        #expect(итог.кодВыхода == 0)
        #expect(итог.группаОтсутствует && итог.оставшиеся.isEmpty)
        #expect(итог.неизвестное.isEmpty)
        #expect(try Data(contentsOf: фикстура.исходы.appendingPathComponent("stdout.bin")) == Data("ok\n".utf8))
        #expect(try Data(contentsOf: фикстура.исходы.appendingPathComponent("stderr.bin")) == Data("err\n".utf8))
    }

    @Test(arguments: ["tree", "orphan", "zombie"])
    func наблюдательЗавершаетГруппуСНепослушнымПотомком(_ режим: String) throws {
        let фикстура = try ФикстураНаблюденияГруппы()
        let итог = try НаблюдательГруппыПроцессов.выполнить(фикстура.запрос(режим))
        #expect(итог.статус == "stopped")
        #expect(итог.причина == (режим == "orphan" ? "leader-exited-with-members" : "time-budget"))
        #expect(итог.посланныеСигналы.contains(SIGKILL))
        #expect(итог.наибольшийСоставГруппы >= 2)
        #expect(итог.группаОтсутствует && итог.оставшиеся.isEmpty)
        #expect(итог.длительностьNS < 4_000_000_000) // alarm каждого fixture — 5 с.
        if режим == "zombie" {
            #expect(итог.наибольшийСоставЗомбиНеЛидеров > 0)
            let вывод = try String(contentsOf: фикстура.исходы.appendingPathComponent("stdout.bin"), encoding: .utf8)
            #expect(вывод.contains("zombie-ready\n"))
        }
        let PGID = try #require(итог.PGID)
        errno = 0
        let код = kill(-PGID, 0), ошибка = errno
        #expect(код == -1 && ошибка == ESRCH)
    }

    @Test(arguments: ["memory", "output"])
    func наблюдательОтличаетПамятьОтВывода(_ режим: String) throws {
        let фикстура = try ФикстураНаблюденияГруппы()
        let память: UInt64 = режим == "memory" ? 25_165_824 : 134_217_728
        let вывод = режим == "output" ? 1_024 : 65_536
        let итог = try НаблюдательГруппыПроцессов.выполнить(фикстура.запрос(режим, память: память, вывод: вывод))
        #expect(итог.статус == "stopped")
        #expect(итог.причина == (режим == "memory" ? "memory-budget" : "output-budget"))
        if режим == "memory" { #expect(итог.пикНаблюдённогоRSS > память) }
        else { #expect(итог.stdoutБайт + итог.stderrБайт <= вывод); #expect(итог.полученоБайт > UInt64(вывод)) }
        #expect(итог.группаОтсутствует && итог.оставшиеся.isEmpty)
        #expect(итог.длительностьNS < 4_000_000_000)
    }

    @Test func наблюдательНеВыдаётЧастичныйСоставЗаУспех() throws {
        let фикстура = try ФикстураНаблюденияГруппы()
        let итог = try НаблюдательГруппыПроцессов.выполнить(фикстура.запрос("tree", членов: 1))
        #expect(итог.статус == "UNKNOWN")
        #expect(итог.неизвестное.contains("group-capacity"))
        #expect(итог.группаОтсутствует && итог.оставшиеся.isEmpty)
        #expect(итог.посланныеСигналы.contains(SIGKILL))
        #expect(итог.длительностьNS < 4_000_000_000)
    }

    @Test func наблюдательНеПовторяетНачатуюПопытку() throws {
        let фикстура = try ФикстураНаблюденияГруппы(), данные = try фикстура.запрос("echo")
        _ = try НаблюдательГруппыПроцессов.выполнить(данные)
        let адресМетки = фикстура.исходы.appendingPathComponent("attempt.json")
        let до = try Data(contentsOf: адресМетки)
        do { _ = try НаблюдательГруппыПроцессов.выполнить(данные); Issue.record("Ожидался запрет повторной попытки") }
        catch { #expect(String(describing: error).contains("attempt-exists")) }
        #expect(try Data(contentsOf: адресМетки) == до)
        let неизвестная = try ФикстураНаблюденияГруппы()
        let неполная = Data("незавершённое намерение\n".utf8)
        try неполная.write(to: неизвестная.исходы.appendingPathComponent("attempt.json"))
        do { _ = try НаблюдательГруппыПроцессов.выполнить(неизвестная.запрос("echo")); Issue.record("Ожидался запрет неизвестного эффекта") }
        catch { #expect(String(describing: error).contains("attempt-exists")) }
        #expect(try Data(contentsOf: неизвестная.исходы.appendingPathComponent("attempt.json")) == неполная)
    }
}

#if ФУМ_ЗАПУСК_ПРОВЕРОК_НАБЛЮДАТЕЛЯ
private enum РежимФикстурыНаблюдателя {
    static func выдать(_ номер: Int32, _ текст: String) {
        let байты = Array(текст.utf8)
        байты.withUnsafeBytes { указатель in _ = Darwin.write(номер, указатель.baseAddress, указатель.count) }
    }
    static func потомок(_ режим: String = "linger") throws -> pid_t {
        let строки = [CommandLine.arguments[0], "--fixture", режим].map { strdup($0) }
        let среда = ProcessInfo.processInfo.environment.map { strdup($0.key + "=" + $0.value) }
        defer { for у in строки + среда { free(у) } }
        var а = строки + [nil], о = среда + [nil], PID: pid_t = 0
        let код = а.withUnsafeMutableBufferPointer { аа in о.withUnsafeMutableBufferPointer { оо in
            posix_spawn(&PID, CommandLine.arguments[0], nil, nil, аа.baseAddress, оо.baseAddress)
        } }
        guard код == 0 else { throw ОшибкаНаблюденияГруппы.отказ("fixture-spawn") }
        return PID
    }
    static func выполнить(_ режим: String) throws -> Never {
        _ = alarm(5)
        switch режим {
        case "echo": выдать(STDOUT_FILENO, "ok\n"); выдать(STDERR_FILENO, "err\n"); _exit(0)
        case "tree", "orphan":
            _ = signal(SIGTERM, SIG_IGN)
            _ = try потомок()
            if режим == "orphan" { _exit(0) }
        case "zombie":
            _ = signal(SIGTERM, SIG_IGN)
            let PID = try потомок("echo")
            let край = DispatchTime.now().uptimeNanoseconds + 500_000_000
            var готов = false
            repeat {
                var сведения = siginfo_t()
                if waitid(P_PID, id_t(PID), &сведения, WEXITED | WNOHANG | WNOWAIT) == 0
                    && сведения.si_pid == PID { готов = true; break }
                _ = poll(nil, 0, 1)
            } while DispatchTime.now().uptimeNanoseconds < край
            guard готов else { _exit(34) }
            выдать(STDOUT_FILENO, "zombie-ready\n")
        case "linger": _ = signal(SIGTERM, SIG_IGN)
        case "memory":
            let размер = 50_331_648
            guard let память = malloc(размер) else { _exit(31) }
            _ = memset(память, 0xA5, размер)
            выдать(STDOUT_FILENO, "allocated\n")
        case "output":
            while true { выдать(STDOUT_FILENO, String(repeating: "x", count: 4_096)) }
        default: _exit(32)
        }
        while true { _ = Darwin.pause() }
    }
}

@main struct ЗапускПроверокНаблюдателя {
    static func main() async {
        if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--fixture" {
            do { try РежимФикстурыНаблюдателя.выполнить(CommandLine.arguments[2]) }
            catch { _exit(33) }
        }
        let код: CInt = await Testing.__swiftPMEntryPoint()
        exit(код)
    }
}
#endif
