import Foundation
import Darwin
import ОсноваЗапуска
import ЖурналУзла

@main
struct Команда {
    static func main() async {
        if CommandLine.arguments.dropFirst().first == "пакет-путей" {
            let текст: String
            do {
                _ = try РазборПакетаПутей.разобрать(Array(CommandLine.arguments.dropFirst(2)))
                текст = "Backend пакета путей не подключён; операция не выполнялась.\n"
            } catch {
                текст = "Некорректные аргументы пакет-путей; используйте fuma --помощь.\n"
            }
            try? FileHandle.standardError.write(contentsOf: Data(текст.utf8))
            Darwin.exit(2)
        }
        let вывод: Data
        let код: Int32
        do {
            if CommandLine.arguments.dropFirst().first == "журнал" {
                let ответ = try КомандаЖурнала.выполнить(Array(CommandLine.arguments.dropFirst(2)))
                try FileHandle.standardOutput.write(contentsOf: ответ)
                return
            }
            switch try ВходКоманды.разобрать(Array(CommandLine.arguments.dropFirst())) {
            case .помощь:
                try FileHandle.standardOutput.write(contentsOf: Data((ВходКоманды.справка + "\n").utf8))
                return
            case .запуск(let параметры):
                let результат = try await ЦиклЗапуска().выполнить(параметры)
                вывод = try ПредставлениеЗапуска.байты(ОтветЗапуска(результат: результат), читаемо: true)
                код = 0
            }
        } catch let ошибка as ОтказКомандыЖурнала {
            вывод = (try? ошибка.представление()) ?? Data("{}\n".utf8)
            код = 2
        } catch let ошибка {
            let отказ = ошибка as? ОтказЗапуска ?? ОтказЗапуска(код: .внутренняя,
                сообщение: String(describing: ошибка))
            вывод = (try? ПредставлениеЗапуска.байты(ОтветЗапуска(ошибка: отказ), читаемо: true))
                ?? Data("{\"версияСхемы\":1,\"состояние\":\"отказ\",\"ошибка\":{\"код\":\"внутренняя\",\"сообщение\":\"Ошибка кодирования ответа\"}}\n".utf8)
            код = 2
        }
        do { try FileHandle.standardOutput.write(contentsOf: вывод) }
        catch { Darwin.exit(2) }
        if код != 0 { Darwin.exit(код) }
    }
}
