import Foundation
import Darwin
import ОсноваЗапуска
import ЖурналУзла
import МатериализацияУзлов

@main
struct Команда {
    static func main() async {
        if CommandLine.arguments.dropFirst().first == "адресный-ответ" {
            let ответ = await КомандаАдресногоОтвета.выполнить(Array(CommandLine.arguments.dropFirst(2)))
            do { try FileHandle.standardOutput.write(contentsOf: ответ.данные) }
            catch { Darwin.exit(2) }
            if ответ.кодЗавершения != 0 { Darwin.exit(ответ.кодЗавершения) }
            return
        }
        if CommandLine.arguments.dropFirst().first == "stop" {
            let ответ = КомандаStop.выполнить(Array(CommandLine.arguments.dropFirst(2)))
            do { try FileHandle.standardOutput.write(contentsOf: ответ) }
            catch { Darwin.exit(2) }
            return
        }
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
        if let ответ = КомандаПроверкиАвторства.перехватить(Array(CommandLine.arguments.dropFirst())) {
            _ = Darwin.signal(SIGPIPE, SIG_IGN)
            do { try FileHandle.standardOutput.write(contentsOf: ответ.данные) }
            catch { Darwin.exit(2) }
            if ответ.кодЗавершения != 0 { Darwin.exit(ответ.кодЗавершения) }
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
                let справка = ВходКоманды.справка + "\n" +
                    "fuma адресный-ответ --хранилище <абсолютный путь> --дескриптор <JSON> --список <JSON> --сообщение <JSON>\n" +
                    "Сохраняет сообщение, проверяет точный readback и возвращает короткое решение; Native transport не вызывается.\n"
                try FileHandle.standardOutput.write(contentsOf: Data(справка.utf8))
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

private struct РезультатКомандыАдресногоОтвета {
    let данные: Data
    let кодЗавершения: Int32
}

private struct ВходноеСообщениеАдресногоОтвета: Decodable {
    let messageID: String
    let исходныеБайты: Data
}

private struct ОтветОтказаАдресногоОтвета: Encodable {
    let схема = "fum.отказ-адресного-ответа.1"
    let operationID: String
    let sha256: String
    let состояниеЗаписи: СостояниеЗаписиСобытия
    let код: КодОтказаЗапуска
    let побочныйЭффект = "UNKNOWN не повторять вслепую; сначала проверить ту же квитанцию"
}

private enum КомандаАдресногоОтвета {
    private static let ключи: Set<String> = ["--хранилище", "--дескриптор", "--список", "--сообщение"]
    private static let пределДокумента = 65_536
    private static let пределСообщения = 1_048_576

    static func выполнить(_ аргументы: [String]) async -> РезультатКомандыАдресногоОтвета {
        var запрос: ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла?
        do {
            let поля = try разобрать(аргументы)
            let дескриптор = try JSONDecoder().decode(
                ДескрипторЖизненногоЦиклаУзла.self,
                from: прочитать(поля["--дескриптор"], предел: пределДокумента))
            let список = try JSONDecoder().decode(
                СвойРабочийСписокУзла.self,
                from: прочитать(поля["--список"], предел: пределДокумента))
            let сообщениеВхода = try JSONDecoder().decode(
                ВходноеСообщениеАдресногоОтвета.self,
                from: прочитать(поля["--сообщение"], предел: пределСообщения))
            guard !сообщениеВхода.messageID.isEmpty,
                  сообщениеВхода.messageID.utf8.count <= 512,
                  !сообщениеВхода.messageID.utf8.contains(0),
                  сообщениеВхода.исходныеБайты.count <= пределСообщения else {
                throw ОшибкаКомандыАдресногоОтвета.аргументы
            }
            запрос = try ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла(
                дескриптор: дескриптор, рабочийСписок: список,
                сообщение: ВходящееСообщениеЖизненногоЦикла(
                    messageID: сообщениеВхода.messageID,
                    исходныеБайты: сообщениеВхода.исходныеБайты))
            let результат = try await ЦиклЗапуска().сохранитьАдресныйОтвет(
                хранилище: try значение("--хранилище", в: поля),
                дескриптор: дескриптор,
                рабочийСписок: список,
                сообщение: ВходящееСообщениеЖизненногоЦикла(
                    messageID: сообщениеВхода.messageID,
                    исходныеБайты: сообщениеВхода.исходныеБайты))
            return РезультатКомандыАдресногоОтвета(
                данные: try закодировать(результат), кодЗавершения: 0)
        } catch let ошибка as ОтказЗапуска {
            if let запрос {
                let отказ = ОтветОтказаАдресногоОтвета(
                    operationID: запрос.operationID, sha256: запрос.sha256КаноническихБайтов,
                    состояниеЗаписи: ошибка.записьСобытия, код: ошибка.код)
                return РезультатКомандыАдресногоОтвета(
                    данные: (try? закодировать(отказ)) ?? Data("{}\n".utf8), кодЗавершения: 2)
            }
            return отказ()
        } catch {
            return отказ()
        }
    }

    private enum ОшибкаКомандыАдресногоОтвета: Error { case аргументы, путь, файл, предел, чтение }

    private static func разобрать(_ аргументы: [String]) throws -> [String: String] {
        guard аргументы.count == 8 else { throw ОшибкаКомандыАдресногоОтвета.аргументы }
        var поля: [String: String] = [:]
        for номер in stride(from: 0, to: аргументы.count, by: 2) {
            let ключ = аргументы[номер]
            let значение = аргументы[номер + 1]
            guard ключи.contains(ключ), поля[ключ] == nil,
                  !значение.isEmpty, !значение.hasPrefix("--"),
                  !значение.utf8.contains(0) else { throw ОшибкаКомандыАдресногоОтвета.аргументы }
            поля[ключ] = значение
        }
        guard Set(поля.keys) == ключи else { throw ОшибкаКомандыАдресногоОтвета.аргументы }
        return поля
    }

    private static func значение(_ ключ: String, в поля: [String: String]) throws -> String {
        guard let значение = поля[ключ], значение.hasPrefix("/") else {
            throw ОшибкаКомандыАдресногоОтвета.путь
        }
        guard значение.utf8.count <= 4096, !значение.utf8.contains(0) else {
            throw ОшибкаКомандыАдресногоОтвета.путь
        }
        return значение
    }

    private static func прочитать(_ путь: String?, предел: Int) throws -> Data {
        guard let путь, путь.hasPrefix("/"), предел > 0 else {
            throw ОшибкаКомандыАдресногоОтвета.путь
        }
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard части.count > 1, части.first == "",
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ОшибкаКомандыАдресногоОтвета.путь }
        var каталог = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard каталог >= 0 else { throw ОшибкаКомандыАдресногоОтвета.файл }
        defer { _ = Darwin.close(каталог) }
        for часть in части.dropFirst().dropLast() {
            let следующий = String(часть).withCString {
                Darwin.openat(каталог, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            guard следующий >= 0 else { throw ОшибкаКомандыАдресногоОтвета.файл }
            _ = Darwin.close(каталог)
            каталог = следующий
        }
        guard let последняя = части.last else { throw ОшибкаКомандыАдресногоОтвета.путь }
        let файл = String(последняя).withCString {
            Darwin.openat(каталог, $0, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        }
        guard файл >= 0 else { throw ОшибкаКомандыАдресногоОтвета.файл }
        defer { _ = Darwin.close(файл) }
        var сведения = stat()
        guard Darwin.fstat(файл, &сведения) == 0,
              сведения.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            throw ОшибкаКомандыАдресногоОтвета.файл
        }
        guard сведения.st_size >= 0, сведения.st_size <= Int64(предел) else {
            throw ОшибкаКомандыАдресногоОтвета.предел
        }
        var данные = Data()
        var буфер = [UInt8](repeating: 0, count: 8192)
        while true {
            let запрос = min(буфер.count, предел + 1 - данные.count)
            let прочитано = буфер.withUnsafeMutableBytes { Darwin.read(файл, $0.baseAddress, запрос) }
            if прочитано < 0 {
                if errno == EINTR { continue }
                throw ОшибкаКомандыАдресногоОтвета.чтение
            }
            if прочитано == 0 { return данные }
            данные.append(contentsOf: буфер.prefix(прочитано))
            guard данные.count <= предел else { throw ОшибкаКомандыАдресногоОтвета.предел }
        }
    }

    private static func закодировать<Значение: Encodable>(_ значение: Значение) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение)
        данные.append(0x0a)
        return данные
    }

    private static func отказ() -> РезультатКомандыАдресногоОтвета {
        struct Представление: Encodable {
            let схема = "fum.отказ-адресного-ответа.1"
            let состояние = "отказ"
            let побочныйЭффект = "проверьте журнал; UNKNOWN не повторять вслепую"
        }
        let данные = (try? закодировать(Представление())) ?? Data("{}\n".utf8)
        return РезультатКомандыАдресногоОтвета(данные: данные, кодЗавершения: 2)
    }
}

private struct РезультатКомандыАвторства {
    let данные: Data
    let кодЗавершения: Int32
}

private enum ОшибкаКомандыАвторства: String, Error {
    case аргументы, путь, файл, предел, чтение
}

private enum КомандаПроверкиАвторства {
    private static let ключи: Set<String> = [
        "--снимок", "--выбор-источника", "--ожидаемый-этап",
        "--сообщение", "--сырой-коммит", "--объект",
    ]

    static func перехватить(_ аргументы: [String]) -> РезультатКомандыАвторства? {
        guard аргументы.first == "авторство" else { return nil }
        do {
            let поля = try разобрать(Array(аргументы.dropFirst()))
            let снимок = try прочитать(поля["--снимок"], предел: ПределыПроверкиПубликации.документ)
            let выбор = try прочитать(поля["--выбор-источника"], предел: ПределыПроверкиПубликации.документ)
            let этап = try прочитать(поля["--ожидаемый-этап"], предел: ПределыПроверкиПубликации.документ)
            let сообщение = try прочитать(поля["--сообщение"], предел: ПределыПроверкиПубликации.документ)
            let коммит = try прочитать(поля["--сырой-коммит"], предел: ПределыПроверкиПубликации.сыройКоммит)
            guard let объект = поля["--объект"] else { throw ОшибкаКомандыАвторства.аргументы }
            let квитанция = try ПроверкаВыбранногоАвторстваИТелаКодекс.проверить(
                данныеСнимка: снимок, данныеВыбораИсточника: выбор,
                данныеОжидаемогоЭтапа: этап, данныеСообщения: сообщение,
                идентификаторОбъекта: объект, байтыСырогоКоммита: коммит)
            return РезультатКомандыАвторства(данные: try закодировать(квитанция), кодЗавершения: 0)
        } catch let ошибка as ОтказПроверкиПубликации {
            return отказ(ошибка.rawValue, код: 1)
        } catch let ошибка as ОшибкаКомандыАвторства {
            return отказ(ошибка.rawValue, код: 2)
        } catch {
            return отказ("внутренняя", код: 2)
        }
    }

    private static func разобрать(_ аргументы: [String]) throws -> [String: String] {
        guard аргументы.first == "проверить", аргументы.count == 13 else {
            throw ОшибкаКомандыАвторства.аргументы
        }
        var поля: [String: String] = [:]
        for номер in stride(from: 1, to: аргументы.count, by: 2) {
            let ключ = аргументы[номер]
            let значение = аргументы[номер + 1]
            guard ключи.contains(ключ), поля[ключ] == nil,
                  !значение.isEmpty, !значение.hasPrefix("--"),
                  !значение.utf8.contains(0) else { throw ОшибкаКомандыАвторства.аргументы }
            поля[ключ] = значение
        }
        guard Set(поля.keys) == ключи else { throw ОшибкаКомандыАвторства.аргументы }
        return поля
    }

    private static func прочитать(_ путь: String?, предел: Int) throws -> Data {
        guard let путь, путь.hasPrefix("/"), предел > 0 else {
            throw ОшибкаКомандыАвторства.путь
        }
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard части.count > 1, части.first == "",
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw ОшибкаКомандыАвторства.путь }
        var каталог = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard каталог >= 0 else { throw ОшибкаКомандыАвторства.файл }
        defer { _ = Darwin.close(каталог) }
        for часть in части.dropFirst().dropLast() {
            let следующий = String(часть).withCString {
                Darwin.openat(каталог, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            guard следующий >= 0 else { throw ОшибкаКомандыАвторства.файл }
            _ = Darwin.close(каталог)
            каталог = следующий
        }
        guard let имя = части.last else { throw ОшибкаКомандыАвторства.путь }
        let файл = String(имя).withCString {
            Darwin.openat(каталог, $0, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        }
        guard файл >= 0 else { throw ОшибкаКомандыАвторства.файл }
        defer { _ = Darwin.close(файл) }
        var сведения = stat()
        guard Darwin.fstat(файл, &сведения) == 0,
              сведения.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            throw ОшибкаКомандыАвторства.файл
        }
        guard сведения.st_size >= 0, сведения.st_size <= Int64(предел) else {
            throw ОшибкаКомандыАвторства.предел
        }
        var данные = Data()
        var буфер = [UInt8](repeating: 0, count: 8192)
        while true {
            let запрос = min(буфер.count, предел + 1 - данные.count)
            let прочитано = буфер.withUnsafeMutableBytes {
                Darwin.read(файл, $0.baseAddress, запрос)
            }
            if прочитано < 0 {
                if errno == EINTR { continue }
                throw ОшибкаКомандыАвторства.чтение
            }
            if прочитано == 0 { return данные }
            данные.append(contentsOf: буфер.prefix(прочитано))
            guard данные.count <= предел else { throw ОшибкаКомандыАвторства.предел }
        }
    }

    private static func закодировать<Значение: Encodable>(_ значение: Значение) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(значение)
        данные.append(0x0a)
        return данные
    }

    private static func отказ(_ причина: String, код: Int32) -> РезультатКомандыАвторства {
        struct Представление: Encodable {
            let схема = "fum.отказ-команды-авторства.1"
            let код: String
            let побочныйЭффект = "нет"
            let источникМоделиАутентифицирован = false
        }
        let данные = (try? закодировать(Представление(код: причина)))
            ?? Data("{\"схема\":\"fum.отказ-команды-авторства.1\",\"код\":\"внутренняя\"}\n".utf8)
        return РезультатКомандыАвторства(данные: данные, кодЗавершения: код)
    }
}
