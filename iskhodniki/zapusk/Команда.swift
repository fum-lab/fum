import Foundation
import Darwin
import ОсноваЗапуска

@main
struct Команда {
    static func main() async {
        let вывод: Data
        let код: Int32
        do {
            switch try ВходКоманды.разобрать(Array(CommandLine.arguments.dropFirst())) {
            case .помощь:
                try FileHandle.standardOutput.write(contentsOf: Data((ВходКоманды.справка + "\n").utf8))
                return
            case .запуск(let параметры):
                let результат = try await ЦиклЗапуска().выполнить(параметры)
                вывод = try ПредставлениеЗапуска.байты(ОтветЗапуска(результат: результат), читаемо: true)
                код = 0
            }
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
