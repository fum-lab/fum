import Darwin
import Foundation

private enum ОшибкаКомандыBootstrap: Error, CustomStringConvertible {
    case аргументы(String)

    var description: String {
        switch self {
        case .аргументы(let пояснение): return пояснение
        }
    }
}

private struct ПараметрыКомандыBootstrap {
    let команда: String
    let значения: [String: String]

    init(_ аргументы: [String]) throws {
        guard let первая = аргументы.first,
              ["plan", "apply", "readback"].contains(первая) else {
            throw ОшибкаКомандыBootstrap.аргументы(
                "Нужна команда plan, apply или readback")
        }
        команда = первая
        var поля: [String: String] = [:]
        var номер = 1
        while номер < аргументы.count {
            let ключ = аргументы[номер]
            guard ключ.hasPrefix("--"), номер + 1 < аргументы.count,
                  поля[ключ] == nil else {
                throw ОшибкаКомандыBootstrap.аргументы(
                    "Аргументы должны быть уникальными парами --ключ значение")
            }
            поля[ключ] = аргументы[номер + 1]
            номер += 2
        }
        значения = поля
        let ожидаемые: Set<String>
        switch команда {
        case "plan": ожидаемые = ["--repo-root", "--path", "--plan"]
        default: ожидаемые = ["--plan", "--outcome"]
        }
        guard Set(поля.keys) == ожидаемые else {
            throw ОшибкаКомандыBootstrap.аргументы(
                "Команда \(команда) получила неполный или лишний набор аргументов")
        }
    }
}

@main
private enum КомандаBootstrapЗависимости {
    static func main() {
        do {
            let параметры = try ПараметрыКомандыBootstrap(
                Array(CommandLine.arguments.dropFirst()))
            switch параметры.команда {
            case "plan":
                let план = try BootstrapЗависимости.построитьПлан(
                    корень: URL(
                        fileURLWithPath: параметры.значения["--repo-root"]!,
                        isDirectory: true),
                    путь: параметры.значения["--path"]!)
                try BootstrapЗависимости.записатьПлан(
                    план, в: URL(fileURLWithPath: параметры.значения["--plan"]!))
                вывести(try BootstrapЗависимости.данныеПлана(план))
            case "apply":
                let план = try BootstrapЗависимости.прочитатьПлан(
                    URL(fileURLWithPath: параметры.значения["--plan"]!))
                let исход = try BootstrapЗависимости.применить(
                    план: план,
                    квитанция: URL(fileURLWithPath: параметры.значения["--outcome"]!))
                вывести(try данные(исход))
            case "readback":
                let план = try BootstrapЗависимости.прочитатьПлан(
                    URL(fileURLWithPath: параметры.значения["--plan"]!))
                let исход = try BootstrapЗависимости.проверитьПослеПрименения(
                    план: план,
                    квитанция: URL(fileURLWithPath: параметры.значения["--outcome"]!))
                вывести(try данные(исход))
            default:
                throw ОшибкаКомандыBootstrap.аргументы("Неизвестная команда")
            }
        } catch {
            FileHandle.standardError.write(Data("Ошибка: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func данные<T: Encodable>(_ значение: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(значение)
    }

    private static func вывести(_ данные: Data) {
        FileHandle.standardOutput.write(данные)
        FileHandle.standardOutput.write(Data([10]))
    }
}
