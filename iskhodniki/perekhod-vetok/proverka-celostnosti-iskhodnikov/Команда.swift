import Foundation
import Darwin

private func входнойФайл(_ путь: String) throws -> Data {
    let д = Darwin.open(путь, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
    guard д >= 0 else { throw ОтказЦелостности("ввод-вывод", 2) }
    let файл = FileHandle(fileDescriptor: д, closeOnDealloc: true)
    defer { try? файл.close() }
    var до = stat()
    guard fstat(д, &до) == 0 else { throw ОтказЦелостности("ввод-вывод", 2) }
    guard до.st_mode & S_IFMT == S_IFREG else { throw ОтказЦелостности("тип-входа", 2) }
    guard до.st_size >= 0, до.st_size <= ПределыЦелостности.манифест else { throw ОтказЦелостности("предел", 2) }
    var данные = Data()
    while данные.count <= ПределыЦелостности.манифест {
        let часть = try файл.read(upToCount: min(16_384, ПределыЦелостности.манифест + 1 - данные.count)) ?? Data()
        if часть.isEmpty { break }
        данные.append(часть)
    }
    var после = stat()
    guard fstat(д, &после) == 0, данные.count == до.st_size,
          данные.count <= ПределыЦелостности.манифест,
          до.st_dev == после.st_dev, до.st_ino == после.st_ino, до.st_size == после.st_size,
          до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec,
          до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
          до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec,
          до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec else { throw ОтказЦелостности("ввод-вывод", 2) }
    return данные
}
private func вывестиJSON(_ значение: [String: Any], _ предел: Int, _ поток: FileHandle) throws -> Int {
    var данные = try JSONSerialization.data(withJSONObject: значение, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    данные.append(10)
    guard данные.count <= предел else { throw ОтказЦелостности("предел", 2) }
    try поток.write(contentsOf: данные)
    return данные.count
}
@main
struct КомандаЦелостности {
    static func main() {
        let начало = DispatchTime.now().uptimeNanoseconds
        var хэшВхода: String?
        var размерВхода = 0
        var манифест: МанифестЦелостности?
        var чтение: ПроверкаОбъектов?
        var логические = 0
        var код: Int32 = 2
        var причина = "неизвестно"
        do {
            let а = Array(CommandLine.arguments.dropFirst())
            guard а.count == 4, а[0] == "--корень", а[2] == "--манифест",
                  а[1].hasPrefix("/"), а[3].hasPrefix("/"),
                  !а.contains(where: { $0.contains("\0") }) else { throw ОтказЦелостности("параметры", 2) }
            let данные = try входнойФайл(а[3])
            размерВхода = данные.count
            хэшВхода = хэшБайтов(данные)
            let разобранный = try МанифестЦелостности.прочитать(данные)
            манифест = разобранный
            let проверяющий = try ПроверкаОбъектов(корень: URL(fileURLWithPath: а[1]), формат: разобранный.источник.формат)
            чтение = проверяющий
            логические = try проверяющий.проверить(разобранный)
            код = 0; причина = "целостность-подтверждена"
        } catch let ошибка as ОтказЦелостности {
            код = ошибка.выход; причина = ошибка.причина
        } catch { код = 2; причина = "ввод-вывод" }
        let результат: [String: Any] = [
            "схема": "fum.результат-целостности-исходников.1",
            "версия_кода": "1",
            "хэш_входа": хэшВхода as Any? ?? NSNull(),
            "код": код, "причина": причина, "целостность": код == 0,
            "полномочия": "не проверялись",
            "проверенный_источник": код == 0 ? манифест!.источник.словарь : NSNull(),
            "проверенная_база": код == 0 ? (манифест?.база?.словарь as Any? ?? NSNull()) : NSNull(),
            "покрытие": манифест?.покрытие as Any? ?? NSNull(),
            "число_файлов": код == 0 ? манифест!.файлы.count : 0,
            "вне_подмножества": манифест?.покрытие == "подмножество" ? "неизвестно" : "не применимо"
        ]
        do {
            let байтыВывода = try вывестиJSON(результат, ПределыЦелостности.вывод, .standardOutput)
            var свой = rusage(), дочерний = rusage()
            let свойКод = getrusage(RUSAGE_SELF, &свой)
            let дочернийКод = getrusage(RUSAGE_CHILDREN, &дочерний)
            let профиль: [String: Any] = [
                "схема": "fum.профиль-целостности-исходников.1",
                "наносекунды": DispatchTime.now().uptimeNanoseconds - начало,
                "RSS_процесса_байты": свойКод == 0 ? NSNumber(value: свой.ru_maxrss) : NSNull(),
                "RSS_потомков_байты": дочернийКод == 0 ? NSNumber(value: дочерний.ru_maxrss) : NSNull(),
                "граница_RSS": "Раздельные максимумы; сумма не вычисляется",
                "байты_манифеста": размерВхода, "логические_байты": логические,
                "прочитано_тел_объектов": чтение?.прочитано ?? 0,
                "вызовы_Git": чтение?.вызовыGit ?? 0, "байты_результата": байтыВывода, "код": код
            ]
            _ = try вывестиJSON(профиль, ПределыЦелостности.профиль, .standardError)
        } catch { exit(2) }
        exit(код)
    }
}
