import Darwin
import Foundation
import ОбновительСвежести

struct ОтветCLI: Encodable {
    let схема = "fum.md-recency.single-file.1"
    let путь: String
    let время: String
    let sha256: String
    let изменён: Bool
}

func отказ(_ текст: String, код: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data("Ошибка: \(текст)\n".utf8))
    Darwin.exit(код)
}

let аргументы = Array(CommandLine.arguments.dropFirst())
if аргументы == ["--help"] || аргументы == ["-h"] {
    print("""
    Использование:
      обновить-свежесть-md --корень <каталог> --путь <относительный.md> [--время 'YYYY-MM-DD HH:MM:SS MSK']

    Меняет метку свежести ровно одного существующего Markdown-файла.
    """)
} else {
    var корень: String?
    var путь: String?
    var время: String?
    var индекс = 0
    while индекс < аргументы.count {
        let флаг = аргументы[индекс]
        guard индекс + 1 < аргументы.count else { отказ("Для \(флаг) требуется значение") }
        let значение = аргументы[индекс + 1]
        switch флаг {
        case "--корень":
            guard корень == nil else { отказ("Повторён --корень") }
            корень = значение
        case "--путь":
            guard путь == nil else { отказ("Повторён --путь") }
            путь = значение
        case "--время":
            guard время == nil else { отказ("Повторён --время") }
            время = значение
        default:
            отказ("Неизвестный параметр: \(флаг)")
        }
        индекс += 2
    }

    guard let корень, let путь else { отказ("Обязательны --корень и --путь") }
    do {
        let результат = try ОбновительСвежести.обновить(
            корень: URL(fileURLWithPath: корень, isDirectory: true),
            относительныйПуть: путь,
            меткаВремени: время
        )
        let ответ = ОтветCLI(
            путь: результат.путь,
            время: результат.время,
            sha256: результат.sha256,
            изменён: результат.изменён
        )
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let json = String(data: try кодировщик.encode(ответ), encoding: .utf8) else {
            отказ("Не удалось сформировать JSON результата", код: 1)
        }
        print(json)
    } catch {
        отказ(String(describing: error), код: 1)
    }
}
