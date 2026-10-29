import Foundation
import Darwin
import ИсполнениеОператора
import КомпозицияНаблюдений

struct ВыводКоманды: Sendable {
    let данные: Data
    let диагностика: Data
    let код: Int32
}

/// Один actor-вызов целиком владеет синхронным исполнителем и контейнером.
/// Через границу передаются только строки, Data и код завершения.
actor ИсполнительКоманды {
    func выполнить(_ аргументы: [String]) async -> ВыводКоманды {
        if аргументы.contains("--исполнить-цикл-наблюдений") {
            return await выполнитьЦикл(аргументы)
        }
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

    private func выполнитьЦикл(_ аргументы: [String]) async -> ВыводКоманды {
        var планСохранён = false
        do {
            let параметры: Set<String> = ["--корень-файловой-системы", "--источник-файловой-системы",
                "--корень-репозитория", "--определение", "--журнал"]
            var значения: [String: String] = [:]
            var выбран = false
            var профиль = false
            var номер = 0
            while номер < аргументы.count {
                let имя = аргументы[номер]
                if имя == "--исполнить-цикл-наблюдений" {
                    guard !выбран else { throw ОшибкаКомандногоИсполнения.аргументы }
                    выбран = true
                    номер += 1
                } else if имя == "--профиль" {
                    guard !профиль else { throw ОшибкаКомандногоИсполнения.аргументы }
                    профиль = true
                    номер += 1
                } else {
                    guard параметры.contains(имя), значения[имя] == nil,
                          номер + 1 < аргументы.count, !аргументы[номер + 1].isEmpty,
                          !аргументы[номер + 1].hasPrefix("--") else {
                        throw ОшибкаКомандногоИсполнения.аргументы
                    }
                    значения[имя] = аргументы[номер + 1]
                    номер += 2
                }
            }
            guard выбран, Set(значения.keys) == параметры,
                  let источник = значения["--источник-файловой-системы"],
                  !источник.isEmpty, источник.utf8.count <= 256,
                  !источник.utf8.contains(0) else { throw ОшибкаКомандногоИсполнения.аргументы }
            func физическийКаталог(_ путь: String) throws -> URL {
                guard путь.hasPrefix("/"), !путь.utf8.contains(0),
                      let указатель = realpath(путь, nil) else { throw ОшибкаКомандногоИсполнения.аргументы }
                defer { free(указатель) }
                let физический = String(cString: указатель)
                var каталог = ObjCBool(false)
                guard физический == путь,
                      FileManager.default.fileExists(atPath: путь, isDirectory: &каталог), каталог.boolValue else {
                    throw ОшибкаКомандногоИсполнения.аргументы
                }
                return URL(fileURLWithPath: физический, isDirectory: true)
            }
            let файловаяСистема = try физическийКаталог(значения["--корень-файловой-системы"]!)
            let репозиторий = try физическийКаталог(значения["--корень-репозитория"]!)
            let подготовка = try МостСрезаНаблюдений.подготовить(
                определение: значения["--определение"]!, журнал: значения["--журнал"]!)
            guard !подготовка.каталог.pathComponents.starts(with: репозиторий.pathComponents) else {
                throw ОшибкаКомандногоИсполнения.приватныйКаталог
            }
            // Git может вынести служебный каталог и общий каталог за рабочее дерево.
            // Они не являются допустимым местом для нативной истории.
            let процесс = Process()
            let канал = Pipe()
            процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            процесс.currentDirectoryURL = репозиторий
            процесс.arguments = ["-c", "core.fsmonitor=false", "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir"]
            процесс.environment = ["GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
                "GIT_OPTIONAL_LOCKS": "0", "GIT_NO_REPLACE_OBJECTS": "1", "GIT_TERMINAL_PROMPT": "0",
                "GIT_CEILING_DIRECTORIES": репозиторий.path]
            процесс.standardOutput = канал
            процесс.standardError = канал
            try процесс.run()
            var выводGit = Data()
            do {
                while true {
                    let часть = try канал.fileHandleForReading.read(upToCount: 4096) ?? Data()
                    if часть.isEmpty { break }
                    guard выводGit.count + часть.count <= 8192 else {
                        throw ОшибкаКомандногоИсполнения.аргументы
                    }
                    выводGit.append(часть)
                }
            } catch {
                if процесс.isRunning { процесс.terminate() }
                процесс.waitUntilExit()
                throw error
            }
            процесс.waitUntilExit()
            guard процесс.terminationStatus == 0,
                  let текстGit = String(data: выводGit, encoding: .utf8) else {
                throw ОшибкаКомандногоИсполнения.аргументы
            }
            let каталогиGit = текстGit.split(separator: "\n", omittingEmptySubsequences: false)
            guard каталогиGit.count == 3, каталогиGit[2].isEmpty else {
                throw ОшибкаКомандногоИсполнения.аргументы
            }
            for путь in каталогиGit.prefix(2) {
                guard путь.hasPrefix("/"), !путь.utf8.contains(0), let указатель = realpath(String(путь), nil) else {
                    throw ОшибкаКомандногоИсполнения.аргументы
                }
                let каталогGit = URL(fileURLWithPath: String(cString: указатель), isDirectory: true)
                free(указатель)
                guard !подготовка.каталог.pathComponents.starts(with: каталогGit.pathComponents) else {
                    throw ОшибкаКомандногоИсполнения.приватныйКаталог
                }
            }
            let цикл = ЦиклНаблюденийСостояния<СистемныйПоставщикНаблюденийСостояния>()
            let план = try await цикл.выполнить(
                кореньФайловойСистемы: файловаяСистема, источникФайловойСистемы: источник,
                кореньРепозитория: репозиторий, кореньИстории: подготовка.каталог,
                времяИстории: ISO8601DateFormatter().string(from: Date()))
            планСохранён = true
            var метки: [МеткаИсполнения] = []
            let собирать: ((МеткаИсполнения) -> Void)? = профиль ? { метки.append($0) } : nil
            let исход = try МостСрезаНаблюдений.исполнить(подготовка, вход: план.каноническиеБайты, профиль: собирать)
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            var диагностика = Data()
            for метка in метки { диагностика.append(try кодировщик.encode(метка)); диагностика.append(10) }
            if !исход.завершено {
                диагностика.append(Data("План сохранён; исполнение оператора не завершено.\n".utf8))
            }
            return ВыводКоманды(данные: исход.данные, диагностика: диагностика, код: исход.завершено ? 0 : 2)
        } catch {
            let граница = планСохранён ? "План сохранён; последующий исход требует проверки истории" : "Исполнение цикла не подтверждено; проверьте историю до повтора"
            return ВыводКоманды(данные: Data(), диагностика: Data((граница + ": " + String(describing: error) + "\n").utf8), код: 2)
        }
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
