import Foundation
import CryptoKit
import Darwin

@main
struct КомандаПредварительногоЧтения {
    static func main() async throws {
        // Входы: NUL-байты `git ls-tree -rz --full-tree <OID>` и JSON политики.
        // Новый собственный output; доверенные предки и Git-происхождение закрепляет вызывающий.
        if CommandLine.arguments.count == 5, CommandLine.arguments[1] == "--имена" {
            let данные = try ПредварительноеЧтение.прочитатьФайл(CommandLine.arguments[2], предел: 16 * 1024 * 1024)
            let политика = try JSONDecoder().decode(ПолитикаПредпросмотраФабрики.self,
                from: ПредварительноеЧтение.прочитатьФайл(CommandLine.arguments[3]))
            let итог = try ПредпросмотрИмёнФабрики.построить(данные, политика: политика)
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var вывод = try кодировщик.encode(итог)
            вывод.append(10)
            let хэш = try сохранитьНовыйПредпросмотр(вывод, путь: CommandLine.arguments[4])
            print("Предпросмотр сохранён: байты=\(вывод.count); SHA256=\(хэш); записей=\(итог.записей); учтено=\(итог.учтено); исключено=\(итог.исключено); каталогов=\(итог.узлы.count).")
            return
        }
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

    /// Отказ сохраняет возможный частичный файл: неизвестный эффект нельзя повторить вслепую.
    private static func сохранитьНовыйПредпросмотр(_ данные: Data, путь: String) throws -> String {
        guard путь.hasPrefix("/"), !путь.utf8.contains(0), данные.count <= 16 * 1024 * 1024 else {
            throw ОшибкаКоманды.пределПредпросмотра
        }
        let файл = open(путь, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, mode_t(0o600))
        guard файл >= 0 else { throw ОшибкаКоманды.выходНеСоздан }
        defer { close(файл) }
        var записано = 0
        while записано < данные.count {
            let число = данные.withUnsafeBytes { байты in
                write(файл, байты.baseAddress!.advanced(by: записано), данные.count - записано)
            }
            if число < 0 && errno == EINTR { continue }
            guard число > 0 else { throw ОшибкаКоманды.неизвестныйИсходЗаписи }
            записано += число
        }
        guard fsync(файл) == 0, lseek(файл, 0, SEEK_SET) == 0 else { throw ОшибкаКоманды.неизвестныйИсходЗаписи }
        var буфер = [UInt8](repeating: 0, count: данные.count + 1)
        var прочитано = 0
        while прочитано < буфер.count {
            let число = буфер.withUnsafeMutableBytes { байты in
                read(файл, байты.baseAddress!.advanced(by: прочитано), байты.count - прочитано)
            }
            if число < 0 && errno == EINTR { continue }
            guard число >= 0 else { throw ОшибкаКоманды.неизвестныйИсходЗаписи }
            if число == 0 { break }
            прочитано += число
        }
        var открытый = stat(), именованный = stat()
        guard прочитано == данные.count, Data(буфер.prefix(прочитано)) == данные,
              fstat(файл, &открытый) == 0, lstat(путь, &именованный) == 0,
              (именованный.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG),
              именованный.st_dev == открытый.st_dev, именованный.st_ino == открытый.st_ino,
              открытый.st_nlink == 1, открытый.st_size == данные.count else {
            throw ОшибкаКоманды.неизвестныйИсходЗаписи
        }
        let родитель = URL(fileURLWithPath: путь).deletingLastPathComponent().path
        let каталог = open(родитель, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard каталог >= 0 else { throw ОшибкаКоманды.неизвестныйИсходЗаписи }
        defer { close(каталог) }
        guard fsync(каталог) == 0 else { throw ОшибкаКоманды.неизвестныйИсходЗаписи }
        return SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
}

enum ОшибкаКоманды: Error {
    case ожидаетсяПутьКФикстуре, неразрешённыйКорень, пределПредпросмотра, выходНеСоздан, неизвестныйИсходЗаписи
}
