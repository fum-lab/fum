import CryptoKit
import Darwin
import Foundation

public enum ОшибкаОбновленияСвежести: Error, CustomStringConvertible {
    case отказ(String)

    public var description: String {
        switch self {
        case .отказ(let причина): причина
        }
    }
}

public struct РезультатОбновленияСвежести: Sendable {
    public let путь: String
    public let время: String
    public let sha256: String
    public let изменён: Bool
}

public enum ОбновительСвежести {
    private static let меткаСвежестиНачало = "<!-- FUM-MD-RECENCY:BEGIN -->"
    private static let меткаСвежестиКонец = "<!-- FUM-MD-RECENCY:END -->"
    private static let заместительБлокаЗапусков = "<!-- FUM-CHECK-RUNS:MANAGED -->"

    public static func обновить(
        корень: URL,
        относительныйПуть: String,
        меткаВремени: String? = nil
    ) throws -> РезультатОбновленияСвежести {
        try ИменаПутей.проверитьПуть(относительныйПуть)
        guard относительныйПуть.hasSuffix(".md") else {
            throw ОшибкаОбновленияСвежести.отказ("Ожидался Markdown-файл с точным суффиксом .md")
        }

        let времяЗапуска = меткаВремени ?? форматировать(Date())
        try проверитьВремя(времяЗапуска)

        let части = относительныйПуть.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        let путьКорня = корень.standardizedFileURL.path
        let дескрипторКорня = путьКорня.withCString {
            Darwin.open($0, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        }
        guard дескрипторКорня >= 0 else { throw системныйОтказ("Не удалось открыть корень") }

        var дескрипторыКаталогов = [дескрипторКорня]
        defer { дескрипторыКаталогов.reversed().forEach { _ = Darwin.close($0) } }
        var дескрипторКаталога = дескрипторКорня
        for имяКаталога in части.dropLast() {
            let следующийДескриптор = имяКаталога.withCString {
                Darwin.openat(дескрипторКаталога, $0, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
            }
            guard следующийДескриптор >= 0 else {
                throw системныйОтказ("Небезопасный или отсутствующий каталог: \(имяКаталога)")
            }
            дескрипторыКаталогов.append(следующийДескриптор)
            дескрипторКаталога = следующийДескриптор
        }

        let имяФайла = части[части.count - 1]
        let дескрипторФайла = имяФайла.withCString {
            Darwin.openat(дескрипторКаталога, $0, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        }
        guard дескрипторФайла >= 0 else { throw системныйОтказ("Не удалось безопасно открыть целевой файл") }
        defer { _ = Darwin.close(дескрипторФайла) }

        var исходныйСтатус = stat()
        guard Darwin.fstat(дескрипторФайла, &исходныйСтатус) == 0 else {
            throw системныйОтказ("Не удалось проверить целевой файл")
        }
        guard исходныйСтатус.st_mode & S_IFMT == S_IFREG else {
            throw ОшибкаОбновленияСвежести.отказ("Цель должна быть обычным файлом")
        }

        let исходныеБайты = try прочитатьВсе(дескрипторФайла)
        guard let исходныйТекст = String(data: исходныеБайты, encoding: .utf8) else {
            throw ОшибкаОбновленияСвежести.отказ("Целевой Markdown не является корректным UTF-8")
        }
        guard !исходныйТекст.contains("\r") else {
            throw ОшибкаОбновленияСвежести.отказ("Поддерживаются только точные LF-переводы строк")
        }

        let разбор = try разобрать(исходныйТекст, путь: относительныйПуть)
        let содержание = каноническийТекст(разбор.содержание)
        let полныйХэш = хэш(Data(содержание.utf8))
        let стабильноеСодержание = try стабильноеСодержаниеОтчёта(
            содержание,
            путь: относительныйПуть
        )
        let стабильныйХэш = хэш(Data(стабильноеСодержание.utf8))

        if let метаданные = разбор.метаданные,
           метаданные.sha256 == полныйХэш || метаданные.sha256 == стабильныйХэш {
            let ожидаемыйХэш = метаданные.sha256 == полныйХэш ? полныйХэш : стабильныйХэш
            return РезультатОбновленияСвежести(
                путь: относительныйПуть,
                время: метаданные.время,
                sha256: ожидаемыйХэш,
                изменён: false
            )
        }

        let новыйХэш = стабильныйХэш
        let новыйТекст = прикрепитьМетку(
            содержание,
            время: времяЗапуска,
            sha256: новыйХэш
        )
        let новыеБайты = Data(новыйТекст.utf8)
        try заменитьАтомарно(
            новыеБайты,
            имяФайла: имяФайла,
            каталог: дескрипторКаталога,
            исходныйСтатус: исходныйСтатус
        )
        return РезультатОбновленияСвежести(
            путь: относительныйПуть,
            время: времяЗапуска,
            sha256: новыйХэш,
            изменён: true
        )
    }

    private struct Метаданные {
        let время: String
        let sha256: String
    }

    private struct Разбор {
        let содержание: String
        let метаданные: Метаданные?
    }

    private static func разобрать(_ текст: String, путь: String) throws -> Разбор {
        let маскаАрхива = маскироватьАрхив(текст, путь: путь)
        let (маска, оградаОткрыта) = маскироватьОграды(маскаАрхива)
        guard !оградаОткрыта else {
            throw ОшибкаОбновленияСвежести.отказ("Markdown содержит незакрытую кодовую ограду")
        }

        let выражение = try NSRegularExpression(
            pattern: #"(?:\A|\n)<!-- FUM-MD-RECENCY:BEGIN -->\n<!-- last-content-edit: ([^>]+) -->\n<!-- content-sha256: sha256:([0-9a-f]{64}) -->\n<!-- FUM-MD-RECENCY:END -->\n?\z"#
        )
        let маскаNSString = маска as NSString
        let диапазон = NSRange(location: 0, length: маскаNSString.length)
        if let совпадение = выражение.firstMatch(in: маска, range: диапазон),
           let времяДиапазон = Range(совпадение.range(at: 1), in: маска),
           let хэшДиапазон = Range(совпадение.range(at: 2), in: маска) {
            let время = String(маска[времяДиапазон])
            try проверитьВремя(время)
            let исходник = текст as NSString
            let начало = совпадение.range.location
            let конец = NSMaxRange(совпадение.range)
            let содержание = исходник.substring(to: начало) + исходник.substring(from: конец)
            return Разбор(
                содержание: содержание,
                метаданные: Метаданные(время: время, sha256: String(маска[хэшДиапазон]))
            )
        }

        guard !маска.contains(меткаСвежестиНачало), !маска.contains(меткаСвежестиКонец) else {
            throw ОшибкаОбновленияСвежести.отказ("Повреждён конечный блок FUM-MD-RECENCY")
        }
        return Разбор(содержание: текст, метаданные: nil)
    }

    private static func маскироватьАрхив(_ текст: String, путь: String) -> String {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard части.count == 7,
              Array(части.prefix(5)) == ["Источники", "URL", "https", "chatgpt.com", "share"],
              части[6].hasSuffix(".md") else { return текст }

        guard let маркеры = try? NSRegularExpression(
            pattern: #"(?m)^<!-- FUM-CHATGPT-SHARE-VERBATIM:(BEGIN|END) -->$"#
        ) else { return текст }
        let текстNSString = текст as NSString
        let совпадения = маркеры.matches(in: текст, range: NSRange(location: 0, length: текстNSString.length))
        guard совпадения.count == 2,
              let первое = Range(совпадения[0].range(at: 1), in: текст),
              let второе = Range(совпадения[1].range(at: 1), in: текст),
              текст[первое] == "BEGIN", текст[второе] == "END" else { return текст }

        let заголовокПеред = текстNSString.substring(to: совпадения[0].range.location)
            .components(separatedBy: "\n").last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard заголовокПеред?.trimmingCharacters(in: .whitespaces) == "## Диалог" else { return текст }
        return маскироватьДиапазон(
            текста: текст,
            диапазон: NSRange(
                location: совпадения[0].range.location,
                length: NSMaxRange(совпадения[1].range) - совпадения[0].range.location
            )
        )
    }

    private static func маскироватьОграды(_ текст: String) -> (String, Bool) {
        var единицы = Array(текст.utf16)
        var ограда: (знак: UInt16, длина: Int)?
        var началоСтроки = 0

        while началоСтроки < единицы.count {
            let конецСтроки = единицы[началоСтроки...].firstIndex(of: 10).map { $0 + 1 } ?? единицы.count
            let конецСодержимого = конецСтроки > началоСтроки && единицы[конецСтроки - 1] == 10
                ? конецСтроки - 1 : конецСтроки
            let описание = описаниеОграды(единицы[началоСтроки..<конецСодержимого])
            var скрыть = ограда != nil

            if let описание {
                if let открытая = ограда {
                    if описание.знак == открытая.знак,
                       описание.длина >= открытая.длина,
                       описание.хвост.allSatisfy({ $0 == 32 || $0 == 9 }) {
                        ограда = nil
                    }
                } else if описание.знак != 96 || !описание.хвост.contains(96) {
                    ограда = (описание.знак, описание.длина)
                    скрыть = true
                }
            }

            if скрыть {
                for индекс in началоСтроки..<конецСодержимого { единицы[индекс] = 32 }
            }
            началоСтроки = конецСтроки
        }
        return (String(decoding: единицы, as: UTF16.self), ограда != nil)
    }

    private static func описаниеОграды(
        _ строка: ArraySlice<UInt16>
    ) -> (знак: UInt16, длина: Int, хвост: [UInt16])? {
        let значения = Array(строка)
        var позиция = 0
        while позиция < min(3, значения.count), значения[позиция] == 32 { позиция += 1 }
        guard позиция < значения.count, значения[позиция] == 96 || значения[позиция] == 126 else { return nil }
        let знак = значения[позиция]
        let началоМаркера = позиция
        while позиция < значения.count, значения[позиция] == знак { позиция += 1 }
        guard позиция - началоМаркера >= 3 else { return nil }
        return (знак, позиция - началоМаркера, Array(значения[позиция...]))
    }

    private static func маскироватьДиапазон(текста: String, диапазон: NSRange) -> String {
        var единицы = Array(текста.utf16)
        let конец = min(единицы.count, NSMaxRange(диапазон))
        if диапазон.location < конец {
            for индекс in диапазон.location..<конец where единицы[индекс] != 10 && единицы[индекс] != 13 {
                единицы[индекс] = 32
            }
        }
        return String(decoding: единицы, as: UTF16.self)
    }

    private static func стабильноеСодержаниеОтчёта(_ содержание: String, путь: String) throws -> String {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard части.count == 3, части[0] == "Журнал", части[2] == "отчёт.md" else {
            return содержание
        }

        let началоМаркер = "<!-- FUM-CHECK-RUNS:BEGIN "
        let конецМаркер = "<!-- FUM-CHECK-RUNS:END -->"
        let числоНачал = вхождения(началоМаркер, в: содержание)
        let числоКонцов = вхождения(конецМаркер, в: содержание)
        if числоНачал == 0 && числоКонцов == 0 { return содержание }
        guard числоНачал == 1, числоКонцов == 1,
              let выражение = try? NSRegularExpression(
                pattern: #"(?m)^<!-- FUM-CHECK-RUNS:BEGIN (?:состояние=открыт; каталог=материалы/запуски-проверок|состояние=закрыт; снимок=материалы/запуски-проверок/снимок\.json; sha256=sha256:[0-9a-f]{64}) -->\n.*?\n<!-- FUM-CHECK-RUNS:END -->$"#,
                options: [.dotMatchesLineSeparators]
              ) else {
            throw ОшибкаОбновленияСвежести.отказ("Повреждена пара FUM-CHECK-RUNS в отчёте")
        }
        let содержаниеNSString = содержание as NSString
        let диапазон = NSRange(location: 0, length: содержаниеNSString.length)
        guard let совпадение = выражение.firstMatch(in: содержание, range: диапазон) else {
            throw ОшибкаОбновленияСвежести.отказ("Повреждена пара FUM-CHECK-RUNS в отчёте")
        }
        let заменённое = содержаниеNSString.replacingCharacters(in: совпадение.range, with: заместительБлокаЗапусков)
        return каноническийТекст(заменённое)
    }

    private static func вхождения(_ искомое: String, в текст: String) -> Int {
        var число = 0
        var остаток = текст[...]
        while let диапазон = остаток.range(of: искомое) {
            число += 1
            остаток = остаток[диапазон.upperBound...]
        }
        return число
    }

    private static func прикрепитьМетку(_ содержание: String, время: String, sha256: String) -> String {
        let тело = каноническийТекст(содержание)
        return "\(тело)\n\(меткаСвежестиНачало)\n<!-- last-content-edit: \(время) -->\n<!-- content-sha256: sha256:\(sha256) -->\n\(меткаСвежестиКонец)\n"
    }

    private static func каноническийТекст(_ текст: String) -> String {
        текст.hasSuffix("\n") ? текст : текст + "\n"
    }

    private static func форматировать(_ дата: Date) -> String {
        let формат = DateFormatter()
        формат.locale = Locale(identifier: "en_US_POSIX")
        формат.timeZone = TimeZone(identifier: "Europe/Moscow")
        формат.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"
        формат.isLenient = false
        return формат.string(from: дата)
    }

    private static func проверитьВремя(_ время: String) throws {
        let формат = DateFormatter()
        формат.locale = Locale(identifier: "en_US_POSIX")
        формат.timeZone = TimeZone(identifier: "Europe/Moscow")
        формат.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"
        формат.isLenient = false
        guard let дата = формат.date(from: время), формат.string(from: дата) == время else {
            throw ОшибкаОбновленияСвежести.отказ("Неверная метка времени MSK")
        }
    }

    private static func хэш(_ байты: Data) -> String {
        SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
    }

    private static func прочитатьВсе(_ дескриптор: Int32) throws -> Data {
        var итог = Data()
        while true {
            var буфер = [UInt8](repeating: 0, count: 64 * 1024)
            let количество = буфер.withUnsafeMutableBytes { сырые in
                Darwin.read(дескриптор, сырые.baseAddress, сырые.count)
            }
            if количество == 0 { return итог }
            if количество < 0 {
                if errno == EINTR { continue }
                throw системныйОтказ("Ошибка чтения целевого файла")
            }
            итог.append(contentsOf: буфер.prefix(количество))
        }
    }

    private static func заменитьАтомарно(
        _ байты: Data,
        имяФайла: String,
        каталог: Int32,
        исходныйСтатус: stat
    ) throws {
        let временноеИмя = ".fum-md-recency-\(UUID().uuidString)"
        let дескрипторВременногоФайла = временноеИмя.withCString {
            Darwin.openat(
                каталог,
                $0,
                O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
                mode_t(0o600)
            )
        }
        guard дескрипторВременногоФайла >= 0 else {
            throw системныйОтказ("Не удалось создать временный файл рядом с целью")
        }
        var временныйСуществует = true
        defer {
            _ = Darwin.close(дескрипторВременногоФайла)
            if временныйСуществует {
                _ = временноеИмя.withCString { Darwin.unlinkat(каталог, $0, 0) }
            }
        }

        guard Darwin.fchmod(дескрипторВременногоФайла, исходныйСтатус.st_mode & 0o7777) == 0 else {
            throw системныйОтказ("Не удалось сохранить режим файла")
        }
        try записатьВсе(байты, в: дескрипторВременногоФайла)
        guard Darwin.fsync(дескрипторВременногоФайла) == 0 else {
            throw системныйОтказ("Не удалось синхронизировать временный файл")
        }

        var текущийСтатус = stat()
        let найден = имяФайла.withCString {
            Darwin.fstatat(каталог, $0, &текущийСтатус, AT_SYMLINK_NOFOLLOW)
        }
        guard найден == 0,
              текущийСтатус.st_mode & S_IFMT == S_IFREG,
              текущийСтатус.st_dev == исходныйСтатус.st_dev,
              текущийСтатус.st_ino == исходныйСтатус.st_ino else {
            throw ОшибкаОбновленияСвежести.отказ("Целевой путь изменился до атомарной замены")
        }

        let переименовано = временноеИмя.withCString { временный in
            имяФайла.withCString { исходный in
                Darwin.renameat(каталог, временный, каталог, исходный)
            }
        }
        guard переименовано == 0 else { throw системныйОтказ("Не удалось атомарно заменить целевой файл") }
        временныйСуществует = false
        guard Darwin.fsync(каталог) == 0 else {
            throw ОшибкаОбновленияСвежести.отказ("Неизвестно, сохранена ли атомарная замена после ошибки fsync каталога")
        }
    }

    private static func записатьВсе(_ байты: Data, в дескриптор: Int32) throws {
        var смещение = 0
        while смещение < байты.count {
            let количество = байты.withUnsafeBytes { сырые in
                Darwin.write(
                    дескриптор,
                    сырые.baseAddress!.advanced(by: смещение),
                    сырые.count - смещение
                )
            }
            if количество < 0 {
                if errno == EINTR { continue }
                throw системныйОтказ("Ошибка записи временного файла")
            }
            guard количество > 0 else { throw ОшибкаОбновленияСвежести.отказ("Нулевая запись временного файла") }
            смещение += количество
        }
    }

    private static func системныйОтказ(_ действие: String) -> ОшибкаОбновленияСвежести {
        ОшибкаОбновленияСвежести.отказ("\(действие): \(String(cString: strerror(errno)))")
    }
}

// Основание: proverka-imyon.swift, commit 3e4ad89c49ef17fd6c377698f7828351aecfa051,
// blob 28cb87599896d29719d5bfa1e2d665aa8b4fcaaf; declaration: static func проверитьПуть(_ путь: String) throws.
// ОшибкаПутей.отказ — локальная копия соответствующего enum из modelj-plana.swift,
// blob fb301bc916a872f4ae6468ff6ae9e745b6f99740.
private enum ИменаПутей {
    static func проверитьПуть(_ путь: String) throws {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard !путь.isEmpty, путь.utf8.count <= 1024,
              !путь.contains("\\"),
              !путь.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git"
                  && $0.utf8.count <= 255 }) else {
            throw ОшибкаПутей.отказ("Небезопасный относительный путь")
        }
    }
}

private enum ОшибкаПутей: Error {
    case отказ(String)
}
