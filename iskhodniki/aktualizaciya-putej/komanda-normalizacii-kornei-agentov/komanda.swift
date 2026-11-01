import АктуализацияПутей
import Darwin
import Foundation

@main
struct КомандаНормализацииКорнейАгентов {
    static func main() async {
        do {
            let результат = try await выполнить(Array(CommandLine.arguments.dropFirst()))
            var байты = try сериализовать(результат)
            байты.append(0x0A)
            FileHandle.standardOutput.write(байты)
            if результат.исход == .неизвестно { exit(3) }
        } catch {
            FileHandle.standardError.write(Data(("Отказ команды: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func выполнить(
        _ аргументы: [String]
    ) async throws -> РезультатНормализацииКорнейАгентов {
        guard аргументы.first == "применить" else {
            throw ОшибкаКомандыНормализации.невернаяКоманда
        }
        var параметры: [String: String] = [:]
        var индекс = 1
        while индекс < аргументы.count {
            let имя = аргументы[индекс]
            guard ["--назначение", "--хранилище"].contains(имя),
                  индекс + 1 < аргументы.count,
                  параметры[имя] == nil else {
                throw ОшибкаКомандыНормализации.неверныеПараметры
            }
            параметры[имя] = аргументы[индекс + 1]
            индекс += 2
        }
        guard let путьНазначения = параметры["--назначение"],
              let путьХранилища = параметры["--хранилище"] else {
            throw ОшибкаКомандыНормализации.неверныеПараметры
        }

        let файлНазначения = URL(fileURLWithPath: путьНазначения)
        let байтыНазначения = try Data(contentsOf: файлНазначения)
        let назначение = try JSONDecoder().decode(
            НазначениеНормализацииКорнейАгентов.self,
            from: байтыНазначения)
        let кореньХранилища = URL(fileURLWithPath: путьХранилища, isDirectory: true).standardizedFileURL
        try проверитьКаталогХранилища(кореньХранилища, вне: назначение.допуск.trustedRoot)

        let operationID = НормализацияКорнейАгентов.идентификаторОперации(назначение: назначение)
        let хранилище = ХранилищеКонтрольныхТочекВСегменте(кореньДанных: кореньХранилища)
        let сохранённая = try await хранилище.загрузитьПоследнююКонтрольнуюТочку(
            operationID: operationID)
        guard try Data(contentsOf: файлНазначения) == байтыНазначения else {
            throw ОшибкаКомандыНормализации.дрейфНазначения
        }
        return try await НормализацияКорнейАгентов.выполнить(
            назначение: назначение,
            контрольнаяТочка: сохранённая,
            сохранитьИПеречитать: { намерение in
                guard try Data(contentsOf: файлНазначения) == байтыНазначения else {
                    throw ОшибкаКомандыНормализации.дрейфНазначения
                }
                return try await хранилище.сохранитьИПеречитать(намерение)
            })
    }

    private static func проверитьКаталогХранилища(_ каталог: URL, вне корня: String) throws {
        let путьКорня = URL(fileURLWithPath: корня, isDirectory: true)
            .resolvingSymlinksInPath().standardizedFileURL.path
        let путьКаталога = try физическийПутьКаталогаБезСимволическихСсылок(каталог)
        let префиксКорня = путьКорня.hasSuffix("/") ? путьКорня : путьКорня + "/"
        guard путьКаталога != путьКорня,
              !путьКаталога.hasPrefix(префиксКорня) else {
            throw ОшибкаКомандыНормализации.хранилищеВнутриРепозитория
        }
    }

    private static func физическийПутьКаталогаБезСимволическихСсылок(_ каталог: URL) throws -> String {
        let стандартный = каталог.standardizedFileURL
        let компоненты = стандартный.pathComponents
        guard стандартный.isFileURL, стандартный.path.hasPrefix("/"), компоненты.first == "/" else {
            throw ОшибкаКомандыНормализации.неверныйКаталогХранилища
        }
        var текущий = "/"
        for компонент in компоненты.dropFirst() {
            текущий = текущий == "/" ? текущий + компонент : текущий + "/" + компонент
            var сведения = stat()
            guard lstat(текущий, &сведения) == 0 else {
                throw ОшибкаКомандыНормализации.неверныйКаталогХранилища
            }
            let тип = сведения.st_mode & S_IFMT
            guard тип != S_IFLNK else {
                throw ОшибкаКомандыНормализации.символическаяСсылкаВКаталогеХранилища
            }
            guard тип == S_IFDIR else {
                throw ОшибкаКомандыНормализации.неверныйКаталогХранилища
            }
        }
        return URL(fileURLWithPath: текущий, isDirectory: true)
            .resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func сериализовать(_ результат: РезультатНормализацииКорнейАгентов) throws -> Data {
        let сводка = СводкаКоманды(
            operationID: результат.контрольнаяТочка.operationID,
            исход: результат.исход.rawValue,
            фаза: результат.контрольнаяТочка.фаза.rawValue,
            шагов: результат.контрольнаяТочка.шаги.count,
            следующийШаг: результат.контрольнаяТочка.следующийШаг,
            изменённыхПутей: результат.изменённыеПути.count,
            конфликтов: результат.конфликты.count)
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let байты = try кодировщик.encode(сводка)
        guard байты.count <= 4096 else { throw ОшибкаКомандыНормализации.слишкомБольшойОтвет }
        return байты
    }
}

private struct СводкаКоманды: Encodable {
    let схема = "fum.cli-сводка-нормализации-корней-агентов.1"
    let operationID: String
    let исход: String
    let фаза: String
    let шагов: Int
    let следующийШаг: Int
    let изменённыхПутей: Int
    let конфликтов: Int
}

private enum ОшибкаКомандыНормализации: Error {
    case невернаяКоманда
    case неверныеПараметры
    case неверныйКаталогХранилища
    case хранилищеВнутриРепозитория
    case символическаяСсылкаВКаталогеХранилища
    case слишкомБольшойОтвет
    case дрейфНазначения
}
