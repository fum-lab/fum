import Foundation
import Darwin
import LinguisticKit

struct ЧтениеПутей {
    var снимок: СнимокПутей
    var тексты: [Data: Data]
    var соседи: [Data: [Data]]
}

enum ЧитательПутей {
    static func гит(_ корень: URL, _ аргументы: [String], коды: Set<Int32> = [0]) throws -> (Data, Int32) {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-C", корень.path] + аргументы
        var среда = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        среда["GIT_OPTIONAL_LOCKS"] = "0"
        среда["GIT_CONFIG_NOSYSTEM"] = "1"
        среда["GIT_CONFIG_GLOBAL"] = "/dev/null"
        процесс.environment = среда
        let канал = Pipe(); процесс.standardOutput = канал; процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        let байты = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard коды.contains(процесс.terminationStatus) else { throw ОшибкаПутей.отказ("Читающий Git-вызов отказал") }
        return (байты, процесс.terminationStatus)
    }

    private static func метаданные(_ состояние: stat) -> String {
        "\(состояние.st_dev):\(состояние.st_ino):\(состояние.st_mode):\(состояние.st_uid):\(состояние.st_nlink):\(состояние.st_size):\(состояние.st_mtimespec.tv_sec):\(состояние.st_mtimespec.tv_nsec):\(состояние.st_ctimespec.tv_sec):\(состояние.st_ctimespec.tv_nsec)"
    }

    private static func состояние(_ дескриптор: Int32) throws -> stat {
        var итог = stat()
        guard fstat(дескриптор, &итог) == 0 else { throw ОшибкаПутей.отказ("Не прочитан inode") }
        return итог
    }

    private static func имена(_ дескриптор: Int32) throws -> [Data] {
        let копия = dup(дескриптор)
        guard копия >= 0, let каталог = fdopendir(копия) else {
            if копия >= 0 { close(копия) }
            throw ОшибкаПутей.отказ("Не прочитан каталог")
        }
        defer { closedir(каталог) }
        rewinddir(каталог)
        var итог: [Data] = []
        errno = 0
        while let запись = readdir(каталог) {
            var имя = запись.pointee.d_name
            let байты = withUnsafeBytes(of: &имя) { буфер in Data(буфер.prefix(while: { $0 != 0 })) }
            guard let текст = String(data: байты, encoding: .utf8) else { throw ОшибкаПутей.отказ("НеUTF8-имя не поддержано") }
            if текст != ".", текст != ".." { итог.append(байты) }
            errno = 0
        }
        guard errno == 0 else { throw ОшибкаПутей.отказ("Неполное перечисление каталога") }
        let группы = Dictionary(grouping: итог, by: { Data(String(decoding: $0, as: UTF8.self).precomposedStringWithCanonicalMapping.utf8) })
        guard !группы.values.contains(where: { $0.count > 1 }) else { throw ОшибкаПутей.отказ("Несколько NFC-эквивалентных физических имён") }
        return итог.sorted { $0.lexicographicallyPrecedes($1) }
    }

    static func снять(корень: URL, области: [String], политика: ПолитикаГраницПутей? = nil,
                      послеЧтенияДляПроверки: (() throws -> Void)? = nil) throws -> ЧтениеПутей {
        let политика = try политика ?? ПолитикаГраницПутей.принятая()
        guard Data(корень.path.utf8) == Data(корень.resolvingSymlinksInPath().path.utf8), !области.isEmpty else {
            throw ОшибкаПутей.отказ("Нужен физический корень и конечные области")
        }
        for область in области { try ИменаПутей.проверитьПуть(область) }
        func гитТекст(_ аргументы: [String]) throws -> String {
            let байты = try гит(корень, аргументы).0
            guard let строка = String(data: байты, encoding: .utf8) else { throw ОшибкаПутей.отказ("НеUTF8 Git-ответ") }
            return строка.trimmingCharacters(in: .newlines)
        }
        let гитКорень = URL(fileURLWithPath: try гитТекст(["rev-parse", "--show-toplevel"]))
            .resolvingSymlinksInPath().standardizedFileURL
        guard Data(гитКорень.path.utf8) == Data(корень.standardizedFileURL.path.utf8) else {
            throw ОшибкаПутей.отказ("Неверный корень Git-worktree")
        }
        let коммит = try гитТекст(["rev-parse", "HEAD"])
        let дерево = try гитТекст(["rev-parse", "HEAD^{tree}"])
        let ветка = try гитТекст(["symbolic-ref", "HEAD"])
        let индекс = try гит(корень, ["ls-files", "--stage", "-z"]).0
        var объекты: [Data: (String, String)] = [:]
        for сырая in индекс.split(separator: 0) {
            guard let строка = String(data: Data(сырая), encoding: .utf8), let табуляция = строка.firstIndex(of: "\t") else {
                throw ОшибкаПутей.отказ("НеUTF8 или повреждённый Git-путь")
            }
            let поля = строка[..<табуляция].split(separator: " ")
            guard поля.count == 3 else { throw ОшибкаПутей.отказ("Повреждённый Git-index") }
            guard поля[2] == "0" else { throw ОшибкаПутей.отказ("Неразрешённый Git-index") }
            let путь = String(строка[строка.index(after: табуляция)...])
            guard объекты[Data(путь.utf8)] == nil else { throw ОшибкаПутей.отказ("Повтор exact Git-пути") }
            объекты[Data(путь.utf8)] = (String(поля[0]), String(поля[1]))
        }
        let индексныеГруппы = Dictionary(grouping: объекты.keys, by: { Data(String(decoding: $0, as: UTF8.self).precomposedStringWithCanonicalMapping.utf8) })
        let грязный = try гит(корень, ["diff-index", "--cached", "--quiet", "HEAD", "--"], коды: [0, 1]).1 != 0
        let корневой = open(корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard корневой >= 0 else { throw ОшибкаПутей.отказ("Не открыт физический корень") }
        defer { close(корневой) }
        var записи: [ЗаписьСнимкаПутей] = []
        var тексты: [Data: Data] = [:]
        var привязки: [String] = []
        var найденные: Set<Data> = []
        var найденныеИндексные: Set<Data> = []
        var состояния: [Data: String] = [:]
        var каталоги: [Data: [Data]] = [:]
        var границы: Set<Data> = []
        func нормальный(_ путь: String) -> String { путь.precomposedStringWithCanonicalMapping }
        func выбран(_ путь: String) -> Bool {
            области.contains { ИменаПутей.вложен(нормальный(путь), в: нормальный($0)) || ИменаПутей.вложен(нормальный($0), в: нормальный(путь)) }
        }
        func открытьТочныйАлиас(_ путь: String) throws -> stat {
            try ИменаПутей.проверитьПуть(путь)
            var текущий = dup(корневой)
            guard текущий >= 0 else { throw ОшибкаПутей.отказ("Не открыт корень alias-proof") }
            defer { close(текущий) }
            let части = путь.split(separator: "/").map(String.init)
            for (номер, часть) in части.enumerated() {
                let следующий = openat(текущий, часть, O_RDONLY | O_NOFOLLOW | (номер + 1 < части.count ? O_DIRECTORY : 0))
                guard следующий >= 0 else { throw ОшибкаПутей.отказ("Точный Git/входной путь не открывается") }
                close(текущий); текущий = следующий
            }
            return try состояние(текущий)
        }
        func обойти(_ дескриптор: Int32, _ родитель: String) throws {
            let до = try состояние(дескриптор)
            let список = try имена(дескриптор)
            состояния[Data(родитель.utf8)] = метаданные(до)
            каталоги[Data(родитель.utf8)] = список
            let байтыИмен = список.reduce(into: Data()) { $0.append($1); $0.append(0) }
            привязки.append(родитель + ":" + метаданные(до) + ":" + хэшПутей(байтыИмен))
            for байты in список {
                let имя = String(decoding: байты, as: UTF8.self)
                if имя == ".git" { continue }
                let путь = родитель.isEmpty ? имя : родитель + "/" + имя
                guard выбран(путь) else { continue }
                try ИменаПутей.проверитьПуть(путь)
                var именованное = stat()
                guard fstatat(дескриптор, имя, &именованное, AT_SYMLINK_NOFOLLOW) == 0 else { throw ОшибкаПутей.отказ("Дрейф имени") }
                let вид = именованное.st_mode & S_IFMT
                guard вид == S_IFREG || вид == S_IFDIR else { throw ОшибкаПутей.отказ("Символический или специальный путь: " + путь) }
                let файл = openat(дескриптор, имя, O_RDONLY | O_NOFOLLOW | (вид == S_IFDIR ? O_DIRECTORY : 0))
                guard файл >= 0 else { throw ОшибкаПутей.отказ("Не открыт точный путь: " + путь) }
                defer { close(файл) }
                let начальное = try состояние(файл)
                guard метаданные(начальное) == метаданные(именованное) else { throw ОшибкаПутей.отказ("Подмена inode") }
                let ключ = Data(путь.utf8)
                найденные.insert(ключ)
                let кандидаты = индексныеГруппы[Data(нормальный(путь).utf8)] ?? []
                guard кандидаты.count <= 1 else { throw ОшибкаПутей.отказ("Несколько NFC-эквивалентных Git-путей") }
                let индексныйКлюч = кандидаты.first
                if let индексныйКлюч, индексныйКлюч != ключ {
                    let индексноеСостояние = try открытьТочныйАлиас(String(decoding: индексныйКлюч, as: UTF8.self))
                    guard метаданные(индексноеСостояние) == метаданные(начальное) else {
                        throw ОшибкаПутей.отказ("NFC-кандидат обозначает другой inode/тип")
                    }
                }
                let индексная = индексныйКлюч.flatMap { объекты[$0] }
                if let индексныйКлюч { найденныеИндексные.insert(индексныйКлюч) }
                let вложенный = вид == S_IFDIR ? try имена(файл).contains(Data(".git".utf8)) : false
                let внешний = индексная?.0 == "160000" || вложенный
                let производный = политика.граница(нормальный(путь), каталог: вид == S_IFDIR)
                состояния[ключ] = метаданные(начальное)
                if внешний || производный { границы.insert(ключ) }
                if вид == S_IFDIR {
                    записи.append(ЗаписьСнимкаПутей(путь: путь, тип: внешний ? "внешняя-зависимость" : производный ? "производный-слой" : "каталог", режим: "040000", объект: индексная?.1,
                        путь_индекса: индексныйКлюч.map { String(decoding: $0, as: UTF8.self) }, режим_индекса: индексная?.0))
                    if !внешний && !производный { try обойти(файл, путь) }
                } else if производный {
                    записи.append(ЗаписьСнимкаПутей(путь: путь, тип: "производный-слой", режим: "100644", объект: индексная?.1,
                        путь_индекса: индексныйКлюч.map { String(decoding: $0, as: UTF8.self) }, режим_индекса: индексная?.0))
                } else {
                    let данные = try FileHandle(fileDescriptor: файл, closeOnDealloc: false).readToEnd() ?? Data()
                    записи.append(ЗаписьСнимкаПутей(путь: путь, режим: начальное.st_mode & 0o111 == 0 ? "100644" : "100755",
                        объект: индексная?.1, sha256: хэшПутей(данные),
                        путь_индекса: индексныйКлюч.map { String(decoding: $0, as: UTF8.self) }, режим_индекса: индексная?.0))
                    if данные.count <= 4_194_304 { тексты[ключ] = данные }
                }
                var позднее = stat()
                guard fstatat(дескриптор, имя, &позднее, AT_SYMLINK_NOFOLLOW) == 0,
                      try метаданные(состояние(файл)) == метаданные(начальное),
                      метаданные(позднее) == метаданные(начальное) else { throw ОшибкаПутей.отказ("Дрейф байтов или режима") }
                привязки.append(путь + ":" + метаданные(начальное))
            }
            guard try имена(дескриптор) == список, try метаданные(состояние(дескриптор)) == метаданные(до) else {
                throw ОшибкаПутей.отказ("Дрейф namespace каталога")
            }
        }
        try обойти(корневой, "")
        for ключ in объекты.keys {
            let путь = String(decoding: ключ, as: UTF8.self)
            if области.contains(where: { ИменаПутей.вложен(нормальный(путь), в: нормальный($0)) }), !найденныеИндексные.contains(ключ),
               !границы.contains(where: { ИменаПутей.вложен(нормальный(путь), в: нормальный(String(decoding: $0, as: UTF8.self))) }) {
                let похожий = найденные.first { ИменаПутей.ключКоллизии(String(decoding: $0, as: UTF8.self)) == ИменаПутей.ключКоллизии(путь) }
                throw ОшибкаПутей.отказ("Пропал exact Git-путь: \(путь); UTF8 Git=\(ключ.base64EncodedString()); похожий ФС=\(похожий?.base64EncodedString() ?? "нет")")
            }
        }
        // Замыкание наблюдённого состава: ранний файл не теряется за поздним.
        func сверить(_ дескриптор: Int32, _ родитель: String) throws {
            let ключ = Data(родитель.utf8)
            guard try метаданные(состояние(дескриптор)) == состояния[ключ],
                  try имена(дескриптор) == каталоги[ключ] else { throw ОшибкаПутей.отказ("Поздний дрейф каталога") }
            for имяБайты in каталоги[ключ] ?? [] {
                let имя = String(decoding: имяБайты, as: UTF8.self)
                let путь = родитель.isEmpty ? имя : родитель + "/" + имя
                let дочерний = Data(путь.utf8)
                guard let ожидалось = состояния[дочерний] else { continue }
                var позднее = stat()
                guard fstatat(дескриптор, имя, &позднее, AT_SYMLINK_NOFOLLOW) == 0, метаданные(позднее) == ожидалось else {
                    throw ОшибкаПутей.отказ("Поздний дрейф ранее прочитанного входа")
                }
                if каталоги[дочерний] != nil {
                    let следующий = openat(дескриптор, имя, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
                    guard следующий >= 0 else { throw ОшибкаПутей.отказ("Поздняя подмена каталога") }
                    defer { close(следующий) }
                    try сверить(следующий, путь)
                }
            }
        }
        try послеЧтенияДляПроверки?()
        try сверить(корневой, "")
        for область in области {
            let совпадения = найденные.filter { Data(нормальный(String(decoding: $0, as: UTF8.self)).utf8) == Data(нормальный(область).utf8) }
            guard совпадения.count == 1, let совпадение = совпадения.first,
                  try метаданные(открытьТочныйАлиас(область)) == состояния[совпадение] else { throw ОшибкаПутей.отказ("Неверная или неоднозначная область") }
        }
        guard
              try гитТекст(["rev-parse", "HEAD"]) == коммит, try гитТекст(["symbolic-ref", "HEAD"]) == ветка,
              try гит(корень, ["ls-files", "--stage", "-z"]).0 == индекс else { throw ОшибкаПутей.отказ("Неполный или изменившийся снимок") }
        let снимок = СнимокПутей(коммит: коммит, дерево: дерево, ветка: ветка, индекс_sha256: хэшПутей(индекс),
            индекс_изменён: грязный, записи: записи.sorted { порядокПутей($0.путь, $1.путь) },
            пространство_sha256: хэшПутей(Data(привязки.sorted(by: порядокПутей).joined(separator: "\n").utf8)))
        return ЧтениеПутей(снимок: снимок, тексты: тексты, соседи: каталоги)
    }
}

actor ШтатноеОтображениеПутей {
    private static let общий = ШтатноеОтображениеПутей()
    private init() {}

    static func отобразить(_ записи: [ЗаписьСнимкаПутей]) async throws -> [ОтображениеПути] {
        try await общий.вычислить(записи)
    }

    // Ревизия837 содержит изменяемые кэши ScriptTable.ru. Внутри этой границы
    // нет await: все обращения нашего компонента строго последовательны.
    private func вычислить(_ записи: [ЗаписьСнимкаПутей]) throws -> [ОтображениеПути] {
        var имена: [Data: String] = [:]
        return try записи.map { запись in
            if запись.тип == "внешняя-зависимость" || запись.тип == "производный-слой" {
                return ОтображениеПути(исходный: запись.путь, целевой: запись.путь)
            }
            let исходные = запись.путь.split(separator: "/").map(String.init)
            let части = try исходные.enumerated().map { номер, исходное in
                if номер == исходные.count - 1, let исключение = ИменаПутей.исключение(запись.путь) { return исключение.имя }
                guard исходное.unicodeScalars.allSatisfy({ $0.value < 128 || (0x400...0x4FF).contains($0.value) || (0x300...0x36F).contains($0.value) }) else {
                    throw ОшибкаПутей.отказ("Неподдерживаемый исходный алфавит имени")
                }
                let ключ = Data(исходное.utf8)
                if let имя = имена[ключ] { return имя }
                guard let результат = ИменаПутей.разбить(исходное).applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru) else {
                    throw ОшибкаПутей.отказ("Не поддержано штатное Cyrl→Latn.ru")
                }
                let имя = try ИменаПутей.нормализовать(результат)
                имена[ключ] = имя
                return имя
            }
            return ОтображениеПути(исходный: запись.путь, целевой: части.joined(separator: "/"))
        }
    }
}

enum СверкаСнимкаПутей {
    static func проверить(_ план: ПланПутей, снимок: СнимокПутей) throws {
        guard try снимок.подпись() == план.снимок_sha256 else { throw ОшибкаПутей.отказ("Дрейф входов сохранённого плана") }
    }
}
