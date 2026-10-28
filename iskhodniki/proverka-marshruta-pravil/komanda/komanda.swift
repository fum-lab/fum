import Darwin
import Foundation
import ПроверкаМаршрутаПравил

private struct Параметры {
    let корень: URL
    let инвентарь: String
    let команда: String
    let триггеры: [String]

    init(_ аргументы: [String]) throws {
        var корень = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        var инвентарь = "Правила/агентов/инвентарь-правил.json"
        var номер = 0
        while номер < аргументы.count, аргументы[номер].hasPrefix("--") {
            guard номер + 1 < аргументы.count else {
                throw ОтказМаршрутаПравил(.инвентарь, "Глобальному ключу нужно значение")
            }
            switch аргументы[номер] {
            case "--корень-репозитория":
                корень = URL(fileURLWithPath: аргументы[номер + 1], isDirectory: true)
            case "--инвентарь":
                инвентарь = аргументы[номер + 1]
            default:
                throw ОтказМаршрутаПравил(.инвентарь, "Неизвестный глобальный ключ")
            }
            номер += 2
        }
        guard номер < аргументы.count,
              ["проверить", "маршрут"].contains(аргументы[номер]) else {
            throw ОтказМаршрутаПравил(.инвентарь, "Нужна команда проверить или маршрут")
        }
        команда = аргументы[номер]
        номер += 1
        var триггеры: [String] = []
        while номер < аргументы.count {
            guard команда == "маршрут", аргументы[номер] == "--триггер",
                  номер + 1 < аргументы.count else {
                throw ОтказМаршрутаПравил(.инвентарь, "Некорректные аргументы маршрута")
            }
            триггеры.append(аргументы[номер + 1])
            номер += 2
        }
        guard команда == "проверить" ? триггеры.isEmpty : !триггеры.isEmpty else {
            throw ОтказМаршрутаПравил(.инвентарь, "Маршруту нужен хотя бы один триггер")
        }
        self.корень = корень
        self.инвентарь = инвентарь
        self.триггеры = триггеры
    }
}

@main
private enum КомандаМаршрутаПравил {
    static func main() {
        do {
            let параметры = try Параметры(Array(CommandLine.arguments.dropFirst()))
            let результат = try ВалидаторМаршрутаПравил.проверить(
                корень: параметры.корень,
                инвентарь: параметры.инвентарь,
                триггеры: параметры.триггеры)
            if параметры.команда == "маршрут" {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
                FileHandle.standardOutput.write(try encoder.encode(результат))
                FileHandle.standardOutput.write(Data([10]))
            } else {
                print("Проверка route/inventory завершена")
            }
        } catch {
            FileHandle.standardError.write(Data("Ошибка: \(error)\n".utf8))
            exit(1)
        }
    }
}
