import Foundation
import Darwin
import ОсноваЗапуска
import ЖурналУзла
import МатериализацияУзлов

@main
struct Команда {
    static func main() async {
        if CommandLine.arguments.dropFirst().first == "stop" {
            let ответ = КомандаStop.выполнить(Array(CommandLine.arguments.dropFirst(2)))
            do { try FileHandle.standardOutput.write(contentsOf: ответ) }
            catch { Darwin.exit(2) }
            return
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
