import Foundation

@main
struct КомандаПредварительногоЧтения {
    static func main() async throws {
        if CommandLine.arguments.count == 5, CommandLine.arguments[1] == "--предок" {
            let корень = CommandLine.arguments[2]
            guard корень.hasPrefix("/") else { throw ОшибкаКоманды.неразрешённыйКорень }
            let адаптер = АдаптерИсторииGit(рабочееДерево: корень, читатель: СистемныйЧитательGit())
            let итог = await адаптер.проверитьПредка(база: CommandLine.arguments[3], наблюдаемыйHEAD: CommandLine.arguments[4])
            print("Проверка предка сохранённой вершины: \(итог.rawValue); текущий HEAD этим вызовом не проверен.")
            return
        }
        guard CommandLine.arguments.count == 2 else {
            throw ОшибкаКоманды.ожидаетсяПутьКФикстуре
        }
        let данные = try ПредварительноеЧтение.прочитатьФайл(CommandLine.arguments[1])
        let узлы = try ПредварительноеЧтение.разобрать(данные)
        let вывод = узлы.map { "\($0.имя): владелец=\($0.владелец); staged=\($0.staged); head=\($0.head)" }
        for строка in вывод { print(строка) }
        print("Наблюдение историческое; допуск и текущее владение не подтверждены.")
    }
}

enum ОшибкаКоманды: Error { case ожидаетсяПутьКФикстуре, неразрешённыйКорень }
