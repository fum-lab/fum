import Foundation
import Darwin
import ИсполнениеОператора

struct ВыводКоманды: Sendable {
    let данные: Data
    let диагностика: Data
    let код: Int32
}

/// Один actor-вызов целиком владеет синхронным исполнителем и контейнером.
/// Через границу передаются только строки, Data и код завершения.
actor ИсполнительКоманды {
    func выполнить(_ аргументы: [String]) -> ВыводКоманды {
        var метки: [МеткаИсполнения] = []
        let собирать: ((МеткаИсполнения) -> Void)? = аргументы.contains("--профиль") ? { метки.append($0) } : nil
        var данные = Data()
        var диагностика = Data()
        var код: Int32 = 0
        do {
            данные = try КомандноеИсполнениеОператора.выполнить(аргументы: аргументы, профиль: собирать)
        } catch {
            код = 2
            диагностика.append(Data(("Отказ исполнения оператора: " + String(describing: error) + "\n").utf8))
        }
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        do {
            for метка in метки {
                диагностика.append(try кодировщик.encode(метка))
                диагностика.append(10)
            }
        } catch {
            код = 2
            данные = Data()
            диагностика.append(Data(("Отказ кодирования профиля: " + String(describing: error) + "\n").utf8))
        }
        return ВыводКоманды(данные: данные, диагностика: диагностика, код: код)
    }
}

@main
struct КомандаОператора {
    static func main() async {
        let вывод = await ИсполнительКоманды().выполнить(Array(CommandLine.arguments.dropFirst()))
        do {
            try FileHandle.standardError.write(contentsOf: вывод.диагностика)
            try FileHandle.standardOutput.write(contentsOf: вывод.данные)
        } catch {
            try? FileHandle.standardError.write(contentsOf:
                Data(("Отказ вывода ответа оператора: " + String(describing: error) + "\n").utf8))
            Darwin.exit(2)
        }
        if вывод.код != 0 { Darwin.exit(вывод.код) }
    }
}
