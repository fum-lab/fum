import Foundation
import Darwin
import СтатистикаВызовов

@main
struct КомандаСтатистики {
    static func main() async {
        do { try await выполнить(Array(CommandLine.arguments.dropFirst())) }
        catch {
            let код = (error as? ОшибкаСтатистики).map { String(describing: $0) } ?? "ввод-вывод"
            FileHandle.standardError.write(Data(("статистика-вызовов: отказ (" + код + ").\n").utf8))
            exit(2)
        }
    }
    static func выполнить(_ аргументы: [String]) async throws {
        if аргументы.first == "профиль" {
            guard аргументы.count == 5, аргументы[1] == "--выход", аргументы[3] == "--размер",
                  аргументы[2].hasPrefix("/"), !аргументы[2].utf8.contains(0),
                  ["малый", "большой", "рабочий"].contains(аргументы[4]) else { throw ОшибкаСтатистики.формат }
            let профиль = try await профильСтатистики(корень: URL(fileURLWithPath: аргументы[2]),
                большой: аргументы[4] == "большой", рабочий: аргументы[4] == "рабочий")
            try FileHandle.standardOutput.write(contentsOf: кодироватьСтатистику(профиль) + Data([10]))
            return
        }
        guard let команда = аргументы.first, ["импорт", "отчёт"].contains(команда),
              аргументы.count % 2 == 1 else { throw ОшибкаСтатистики.формат }
        var поля: [String: String] = [:]
        let допустимые = команда == "импорт" ? ["--вход", "--выход", "--задача", "--формат"] : ["--выход", "--задача", "--формат"]
        for номер in stride(from: 1, to: аргументы.count, by: 2) {
            let ключ = аргументы[номер]
            guard допустимые.contains(ключ), поля[ключ] == nil else { throw ОшибкаСтатистики.формат }
            поля[ключ] = аргументы[номер + 1]
        }
        guard let выход = поля["--выход"], let задача = поля["--задача"] else { throw ОшибкаСтатистики.формат }
        let формат = поля["--формат"] ?? "json"
        guard ["json", "markdown"].contains(формат) else { throw ОшибкаСтатистики.формат }
        func путь(_ текст: String) throws -> URL {
            guard текст.hasPrefix("/"), !текст.utf8.contains(0) else { throw ОшибкаСтатистики.небезопасныйПуть }
            return URL(fileURLWithPath: текст)
        }
        let источник: URL?
        if команда == "импорт" {
            guard let вход = поля["--вход"] else { throw ОшибкаСтатистики.формат }
            источник = try путь(вход)
        } else { источник = nil }
        let хранилище = try ХранилищеСтатистики(корень: путь(выход), задача: задача, запись: команда == "импорт")
        let отчёт: ОтчётСтатистики
        do {
            if let источник { отчёт = try await хранилище.импортировать(источник).отчёт }
            else { отчёт = try await хранилище.получить() }
        } catch { await хранилище.закрыть(); throw error }
        await хранилище.закрыть()
        let данные = формат == "json" ? try кодироватьСтатистику(отчёт) + Data([10]) : Data(разметкаСтатистики(отчёт).utf8)
        try FileHandle.standardOutput.write(contentsOf: данные)
    }
}
