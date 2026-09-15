import Foundation
import Darwin
import СнимокАгентскойЗадачи
import КонтейнерНаблюдений

@main struct КомандаСнимка {
    static func main() async {
        do { try await выполнить(Array(CommandLine.arguments.dropFirst())) }
        catch {
            FileHandle.standardError.write(Data(("Ошибка синтетического снимка: \(error)\n").utf8))
            exit(2)
        }
    }
    static func выполнить(_ аргументы: [String]) async throws {
        guard let команда = аргументы.first else { throw ОшибкаСнимка.неверныйВвод }
        switch команда {
        case "пример":
            guard аргументы.count == 1 else { throw ОшибкаСнимка.неверныйВвод }
            try вывести(каноническийJSON(примерСценария()) + Data([10]))
        case "собрать":
            guard аргументы.count == 4, аргументы[1].hasPrefix("/"), аргументы[2].hasPrefix("/"),
                  ["json", "markdown"].contains(аргументы[3]) else { throw ОшибкаСнимка.неверныйВвод }
            // Полный конечный ввод проверяется до открытия/создания контейнера.
            let сценарий = try прочитатьСценарий(прочитатьВход(аргументы[1], предел: БюджетСнимка.вход))
            let хранилище = try ХранилищеСнимка(корень: URL(fileURLWithPath: аргументы[2]),
                задача: сценарий.задача, запись: true)
            do {
                let снимок = try await хранилище.проиграть(сценарий)
                await хранилище.закрыть()
                try вывестиСнимок(снимок, аргументы[3])
            } catch {
                await хранилище.закрыть()
                throw error
            }
        case "восстановить":
            guard аргументы.count == 6, аргументы[1].hasPrefix("/"),
                  ["json", "markdown"].contains(аргументы[5]) else { throw ОшибкаСнимка.неверныйВвод }
            let задача = Задача(поставщик: аргументы[2], хост: аргументы[3], идентификатор: аргументы[4])
            let хранилище = try ХранилищеСнимка(корень: URL(fileURLWithPath: аргументы[1]), задача: задача, запись: false)
            do {
                let снимок = try await хранилище.получить()
                await хранилище.закрыть()
                try вывестиСнимок(снимок, аргументы[5])
            } catch {
                await хранилище.закрыть()
                throw error
            }
        case "профиль":
            guard аргументы.count == 3, аргументы[1].hasPrefix("/"),
                  let количество = Int(аргументы[2]) else { throw ОшибкаСнимка.неверныйВвод }
            let профиль = try await измеритьСнимок(корень: URL(fileURLWithPath: аргументы[1]), количество: количество)
            try вывести(каноническийJSON(профиль) + Data([10]))
        default: throw ОшибкаСнимка.неверныйВвод
        }
    }
    static func вывестиСнимок(_ снимок: Снимок, _ формат: String) throws {
        try вывести(формат == "json" ? каноническийJSON(снимок) + Data([10]) : Data(читаемыйMarkdown(снимок).utf8))
    }
    static func вывести(_ данные: Data) throws {
        try FileHandle.standardOutput.write(contentsOf: данные)
    }
}
