import Foundation
import Darwin
import Testing
import КомпозицияНаблюдений
import КонтейнерНаблюдений
@testable import ИсполнениеОператора

private final class СчётчикСинхронизацииВвода: @unchecked Sendable {
    private let замок = NSLock()
    private var число = 0
    func следующий() -> Int { замок.withLock { число += 1; return число } }
}

@Suite("Ввод наблюдения JSONL через команду", .serialized)
struct ПроверкиВводаНаблюденияJSONL {
    @Test("Хвост, повтор и дрейф через реальный CLI")
    func хвостПовторИДрейф() throws {
        let бинарник = try #require(ProcessInfo.processInfo.environment["ФУМА_КОМАНДА_ОПЕРАТОРА"])
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let указатель = try #require(realpath(временный.path, nil))
        defer { free(указатель) }
        let корень = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
        var завершено = false
        defer {
            if завершено { try? FileManager.default.removeItem(at: корень) }
            else { print("Незавершённая приватная история: \(корень.path)") }
        }
        let вход = корень.appendingPathComponent("вход", isDirectory: true)
        let история = корень.appendingPathComponent("история", isDirectory: true)
        for каталог in [вход, история] {
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        let файл = вход.appendingPathComponent("данные.jsonl")
        try #require(FileManager.default.createFile(atPath: файл.path, contents: Data("{}\n{".utf8),
            attributes: [.posixPermissions: 0o600]))
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let определение = пакет.appendingPathComponent("Операторы/тождество-байтов.json")
        func запуск(_ после: String?, _ подтверждение: String?) throws -> [String: Any] {
            let процесс = Process()
            let вывод = Pipe(), ошибки = Pipe()
            процесс.executableURL = URL(fileURLWithPath: бинарник)
            процесс.arguments = ["--ввод-наблюдения-JSONL", "--корень-файловой-системы", вход.path,
                "--имя-файла", "данные.jsonl", "--источник", "фикстура", "--поколение", "1",
                "--определение", определение.path, "--журнал", история.path]
                + (после.map { ["--после", $0] } ?? [])
                + (подтверждение.map { ["--подтверждение", $0] } ?? [])
            процесс.standardOutput = вывод
            процесс.standardError = ошибки
            try процесс.run()
            процесс.waitUntilExit()
            let ответ = вывод.fileHandleForReading.readDataToEndOfFile()
            let диагностика = ошибки.fileHandleForReading.readDataToEndOfFile()
            try #require(процесс.terminationStatus == 0, "\(String(decoding: диагностика, as: UTF8.self))")
            let объект = try #require(JSONSerialization.jsonObject(with: ответ) as? [String: Any])
            try #require(объект["состояние"] as? String != "неизвестно")
            return объект
        }
        let первый = try запуск(nil, nil)
        try #require(первый["состояние"] as? String == "записано")
        let перваяСсылка = try #require(первый["пакет"] as? String)
        let первоеПодтверждение = try #require(первый["подтверждение"] as? String)
        try #require((первый["связи"] as? [[String: Any]])?.count == 1)
        try Data("{}\n{}\n".utf8).write(to: файл)
        let второй = try запуск(перваяСсылка, первоеПодтверждение)
        try #require(второй["состояние"] as? String == "записано")
        let втораяСсылка = try #require(второй["пакет"] as? String)
        let второеПодтверждение = try #require(второй["подтверждение"] as? String)
        let связи = try #require(второй["связи"] as? [[String: Any]])
        try #require(связи.count == 1)
        try #require(связи.first?["начало"] as? Int == 3)
        try #require(связи.first?["конец"] as? Int == 6)
        let цикл = ЦиклВводаJSONL()
        let первыйПакет = try цикл.прочитать(перваяСсылка, история: история)
        let второйПакет = try цикл.прочитать(втораяСсылка, история: история)
        try #require(первыйПакет.рамки.first?.начало == 0)
        try #require(первыйПакет.рамки.first?.конец == 3)
        try #require(второйПакет.сырыеНовыеБайты == Data("}\n".utf8))
        try #require(второйПакет.поколение == "1")
        try #require(цикл.восстановить(втораяСсылка, история: история) == Data("{}\n{}\n".utf8))
        let повтор = try запуск(втораяСсылка, второеПодтверждение)
        try #require(повтор["состояние"] as? String == "повтор")
        try #require((повтор["связи"] as? [[String: Any]])?.count == 1)
        try Data("[]\n{}\n".utf8).write(to: файл)
        let дрейф = try запуск(втораяСсылка, второеПодтверждение)
        try #require(дрейф["состояние"] as? String == "дрейф")
        try #require(дрейф["отклонённыеБайтыСохранены"] as? Bool == false)
        try #require(цикл.числоПакетов(история: история) == 2)
        let читатель = try Сегмент(кореньДанных: история, запись: false, создать: false)
        try #require(читатель.записи.filter { $0.описание.тип == "fuma.связь-рамки-jsonl.1" }.count == 2)
        читатель.закрыть()
        завершено = true
    }

    @Test("Хвост сохраняет определение, отказ синхронизации остаётся неизвестным")
    func хвостИНеизвестнаяСинхронизация() throws {
        let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let указатель = try #require(realpath(временный.path, nil))
        defer { free(указатель) }
        let корень = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
        print("Приватная история с неизвестным исходом: \(корень.path)")
        let вход = корень.appendingPathComponent("вход", isDirectory: true)
        let история = корень.appendingPathComponent("история", isDirectory: true)
        for каталог in [вход, история] {
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        }
        let файл = вход.appendingPathComponent("данные.jsonl")
        try #require(FileManager.default.createFile(atPath: файл.path, contents: Data("{".utf8),
            attributes: [.posixPermissions: 0o600]))
        let пакет = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let определение = пакет.appendingPathComponent("Операторы/тождество-байтов.json")
        let аргументы = ["--ввод-наблюдения-JSONL", "--корень-файловой-системы", вход.path,
            "--имя-файла", "данные.jsonl", "--источник", "фикстура", "--поколение", "1",
            "--определение", определение.path, "--журнал", история.path]
        let данные = try МостВводаНаблюденияJSONL.выполнить(аргументы: аргументы)
        let ответ = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        try #require(ответ["состояние"] as? String == "записано")
        let ссылка = try #require(ответ["пакет"] as? String)
        let подтверждение = try #require(ответ["подтверждение"] as? String)
        let читатель = try Сегмент(кореньДанных: история, запись: false, создать: false)
        try #require(читатель.записи.contains { $0.описание.тип == "сырые-байты/определение-оператора" })
        читатель.закрыть()
        try Data("{ ".utf8).write(to: файл)
        let счётчик = СчётчикСинхронизацииВвода()
        let операции = ФайловыеОперации(запись: { дескриптор, буфер in
            let число = Darwin.write(дескриптор, буфер.baseAddress, буфер.count)
            if число < 0 { throw ОшибкаКонтейнера.система(errno) }
            return число
        }, синхронизация: { дескриптор in
            if счётчик.следующий() == 3 { throw ОшибкаКонтейнера.система(EIO) }
            guard Darwin.fsync(дескриптор) == 0 else { throw ОшибкаКонтейнера.система(errno) }
        })
        let неизвестно = try МостВводаНаблюденияJSONL.выполнить(
            аргументы: аргументы + ["--после", ссылка, "--подтверждение", подтверждение], операции: операции)
        let исход = try #require(JSONSerialization.jsonObject(with: неизвестно) as? [String: Any])
        try #require(исход["состояние"] as? String == "неизвестно")
        try #require(исход["стадия"] as? String == "подтверждение-пакета")
        try #require(исход["подтверждение"] == nil)
        let послеОтказа = try Сегмент(кореньДанных: история, запись: false, создать: false)
        defer { послеОтказа.закрыть() }
        let видимая = try #require(послеОтказа.записи.last { $0.описание.тип == "fuma.подтверждение-пакета-jsonl.1" })
        let данныеПодтверждения = try послеОтказа.извлечь(видимая.описание.идентификатор)
        let запись = try #require(JSONSerialization.jsonObject(with: данныеПодтверждения) as? [String: Any])
        try #require(запись["хэшПодтверждения"] as? String != nil)
        try #require(запись["подтверждение"] == nil)
    }
}
