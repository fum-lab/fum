import Foundation
import АрхивныйСнимокЗадачи
import СнимокАгентскойЗадачи
import Darwin

@main struct КомандаАрхива {
    static func main() async {
        do {
            var аргументы = Array(CommandLine.arguments.dropFirst())
            let markdown = аргументы.last == "--markdown"
            if markdown { аргументы.removeLast() }
            guard let команда = аргументы.first else { throw ОшибкаАрхива.формат }
            let результат: РезультатАрхива?
            if команда == "импорт", аргументы.count == 4 {
                let архив = try АрхивЗадачи(корень: URL(fileURLWithPath: аргументы[2]), ожидаемыйUUID: аргументы[3], запись: true)
                do { результат = try await архив.импортировать(URL(fileURLWithPath: аргументы[1])) }
                catch { await архив.закрыть(); throw error }
                await архив.закрыть()
            } else if команда == "replay", аргументы.count == 3 {
                let архив = try АрхивЗадачи(корень: URL(fileURLWithPath: аргументы[1]), ожидаемыйUUID: аргументы[2], запись: false)
                результат = try await архив.получить(); await архив.закрыть()
            } else { throw ОшибкаАрхива.формат }
            guard let результат else { throw ОшибкаАрхива.формат }
            if markdown { print(архивныйMarkdown(результат), terminator: "") }
            else { FileHandle.standardOutput.write(try каноническийJSON(результат) + Data([10])) }
        } catch {
            // Не печатаем payload, исходные строки, URL и произвольное описание внешней ошибки.
            FileHandle.standardError.write(Data("Архивный снимок: операция не подтверждена. Проверьте UUID, формат, бюджеты и доступность контейнера.\n".utf8))
            exit(2)
        }
    }
}
