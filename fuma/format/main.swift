import CryptoKit
import Darwin
import Foundation
import АктуализацияПутей

private struct ЗаписьGit: Sendable {
    let путь: String
    let режим: String
    let объект: String
}

private struct ЗаписьПеремещения: Codable, Sendable {
    let исходное: String
    let целевое: String
    let режимGit: String
    let исходныйОбъект: String
    let sha256До: String
    let sha256После: String
}

private struct ЗаписьСсылки: Codable, Sendable {
    let путь: String
    let числоЗамен: Int
    let sha256До: String
    let sha256После: String
}

private struct МанифестФорматирования: Codable {
    let схема: String
    let версия: String
    let исходныйКоммит: String
    let деревоИсточника: String
    let карта: КартаПутейFUMA
    let перемещения: [ЗаписьПеремещения]
    let ссылки: [ЗаписьСсылки]
}

private struct ПланФорматирования: Codable {
    let схема: String
    let версия: String
    let исходныйКоммит: String
    let деревоИсточника: String
    let файлов: Int
    let компонентов: [СопоставлениеКомпонентаFUMA]
    let пути: [ЗаписьПутиFUMA]
    let ссылки: [ЗаписьСсылки]
}

private struct ЗаголовокМаркера: Decodable {
    let версия: String
}

private struct ПодготовленныйПлан {
    let карта: КартаПутейFUMA
    let исходныеФайлы: [ЗаписьGit]
    let путиСсылок: [(путь: String, целевойПуть: String, до: Data, после: Data, замены: Int)]
    let исходныйКоммит: String
    let деревоИсточника: String
}

@main
private struct КомандаФорматированияFUMA {
    private static let путьМаркера = "fuma/manifest-path-format.v1.json"
    private static let путьСпискаПутей = "fuma/manifest-path-format.v1.paths"

    static func main() async {
        do {
            try await выполнить(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("ОТКАЗ: " + String(describing: error) + "\n").utf8))
            exit(2)
        }
    }

    private static func выполнить(_ аргументы: [String]) async throws {
        switch ФорматировщикПутейFUMA.режимКоманды(аргументы: аргументы) {
        case .версия:
            print(ФорматировщикПутейFUMA.версия)
            return
        case .план:
            break
        case .отказ(let сообщение):
            throw ОшибкаКомандыFUMA(сообщение)
        }

        let корень = try получитьКореньРепозитория()
        let старыйКорень = корень.appendingPathComponent(ФорматировщикПутейFUMA.исходныйКорень)
        let маркерURL = корень.appendingPathComponent(путьМаркера)
        let маркерВерсии = try прочитатьВерсиюМаркера(маркерURL)
        let состояние = ФорматировщикПутейFUMA.состояние(
            версияМаркера: маркерВерсии,
            старыйКореньСуществует: FileManager.default.fileExists(atPath: старыйКорень.path))

        switch состояние {
        case .noOp:
            throw ОшибкаКомандыFUMA("NO_OP закрыт до независимой проверки происхождения и полного состава дерева")
        case .отказ(let сообщение):
            throw ОшибкаКомандыFUMA(сообщение)
        case .применить:
            break
        }

        let план = try await подготовитьПлан(корень: корень)
        let вывод = ПланФорматирования(
            схема: "fum.fuma.path-format-plan.v1",
            версия: ФорматировщикПутейFUMA.версия,
            исходныйКоммит: план.исходныйКоммит,
            деревоИсточника: план.деревоИсточника,
            файлов: план.исходныеФайлы.count,
            компонентов: план.карта.компоненты,
            пути: план.карта.пути,
            ссылки: записиСсылок(из: план.путиСсылок))
        try записатьJSON(вывод, в: FileHandle.standardOutput)
    }

    private static func получитьКореньРепозитория() throws -> URL {
        let текущийКаталог = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
        let данные = try git(["rev-parse", "--show-toplevel"], в: текущийКаталог)
        guard let текст = String(data: данные, encoding: .utf8) else {
            throw ОшибкаКомандыFUMA("Git не вернул UTF-8 путь checkout")
        }
        let корень = URL(fileURLWithPath: текст.trimmingCharacters(in: .newlines)).standardizedFileURL
        guard корень.path == текущийКаталог.path else {
            throw ОшибкаКомандыFUMA("Команду нужно запускать из корня checkout")
        }
        return корень
    }

    private static func прочитатьВерсиюМаркера(_ url: URL) throws -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let данные = try Data(contentsOf: url)
        return try JSONDecoder().decode(ЗаголовокМаркера.self, from: данные).версия
    }

    private static func проверитьКаноническоеДерево(маркерURL: URL, корень: URL) throws {
        let маркер = try JSONDecoder().decode(
            МанифестФорматирования.self, from: Data(contentsOf: маркерURL))
        guard маркер.схема == "fum.fuma.path-format-manifest.v1",
              маркер.версия == ФорматировщикПутейFUMA.версия,
              маркер.карта.версия == ФорматировщикПутейFUMA.версия,
              !маркер.перемещения.isEmpty else {
            throw ОшибкаКомандыFUMA("Манифест не подтверждает версию форматирования")
        }
        for запись in маркер.перемещения {
            let url = корень.appendingPathComponent(запись.целевое)
            let атрибуты = try FileManager.default.attributesOfItem(atPath: url.path)
            guard атрибуты[.type] as? FileAttributeType == .typeRegular else {
                throw ОшибкаКомандыFUMA("Форматированный файл отсутствует или имеет другой тип: " + запись.целевое)
            }
        }
    }

    private static func подготовитьПлан(корень: URL) async throws -> ПодготовленныйПлан {
        let путьИсточника = ФорматировщикПутейFUMA.исходныйКорень
        let изменённыеФайлы = try git(["status", "--porcelain=v1", "-z", "--", путьИсточника], в: корень)
        guard изменённыеФайлы.isEmpty else {
            throw ОшибкаКомандыFUMA("Исходный каталог имеет локальные изменения")
        }
        let неотслеживаемые = try git(
            ["ls-files", "--others", "--exclude-standard", "-z", "--", путьИсточника], в: корень)
        guard неотслеживаемые.isEmpty else {
            throw ОшибкаКомандыFUMA("В исходном каталоге есть неотслеживаемые файлы")
        }

        let записи = try разобратьЗаписиGit(
            git(["ls-files", "--stage", "-z", "--", путьИсточника], в: корень))
        guard !записи.isEmpty else { throw ОшибкаКомандыFUMA("В индексе нет файлов FUMA") }
        guard записи.allSatisfy({ $0.режим == "100644" || $0.режим == "100755" }) else {
            throw ОшибкаКомандыFUMA("Исходное дерево содержит symlink, gitlink или специальный файл")
        }
        try проверитьПутиИсточника(записи, в: корень)

        let карта = try await ФорматировщикПутейFUMA.составитьКарту(путей: записи.map(\.путь))
        try проверитьНазначения(карта, записи: записи, в: корень)

        let исходныйКоммит = try gitText(["rev-parse", "HEAD"], в: корень)
        let деревоИсточника = try gitText(["rev-parse", "HEAD:" + путьИсточника], в: корень)
        let деревоCheckout = try gitText(["rev-parse", "HEAD^{tree}"], в: корень)
        let ветка = try gitText(["symbolic-ref", "-q", "HEAD"], в: корень)
        let индекс = try git(["ls-files", "--stage", "-z"], в: корень)
        _ = try РазборВыводаПутейFUMA.байтовыеЗаписиИндекса(индекс)
        let окружение = ProcessInfo.processInfo.environment
        guard let задача = окружение["FUMA_ROOT_TASK_UUID"], UUID(uuidString: задача) != nil,
              let владелец = окружение["FUMA_OWNER_TASK_UUID"], UUID(uuidString: владелец) != nil else {
            throw ОшибкаКомандыFUMA("Не заданы идентификаторы задачи и владельца")
        }
        let файлыТопологии = try записи.map { запись in
            ЗаписьИсходногоФайлаДереваFUMA(
                путь: запись.путь,
                режимGit: запись.режим,
                объектGit: запись.объект,
                байты: try Data(contentsOf: корень.appendingPathComponent(запись.путь), options: [.mappedIfSafe]))
        }
        let препятствия = try ФорматировщикПутейFUMA.проверитьТопологию(
            карты: карта,
            файлы: файлыТопологии,
            контекст: КонтекстПроверкиДереваFUMA(
                корневаяЗадача: задача,
                владелец: владелец,
                ветка: ветка,
                коммит: исходныйКоммит,
                дерево: деревоCheckout,
                индексSHA256: хэш(индекс)))
        guard препятствия.isEmpty else {
            let описание = препятствия.map { $0.код + ":" + $0.пути.joined(separator: ",") }
            throw ОшибкаКомандыFUMA("Общий планировщик отклонил топологию: " + описание.joined(separator: "; "))
        }
        let путиТекстовыхСсылок = try git(["grep", "-I", "-l", "-z", "-F", "-e", путьИсточника, "--", "."],
                                           в: корень, допустимыеКоды: [0, 1])
        let найденныеПути = try разобратьZСтроки(путиТекстовыхСсылок)
        var запланированныеСсылки: [(путь: String, целевойПуть: String, до: Data, после: Data, замены: Int)] = []
        let путиПеремещения = Dictionary(uniqueKeysWithValues: карта.пути.map { ($0.исходное, $0.целевое) })

        for путь in найденныеПути.sorted() where разрешёнПерезаписьСсылок(в: путь) {
            let данные = try Data(contentsOf: корень.appendingPathComponent(путь))
            let результатПерезаписи = карта.переписатьБайтыСПодсчётом(данные)
            let переписанные = результатПерезаписи.байты
            guard переписанные != данные else { continue }
            let целевойПуть = путиПеремещения[путь] ?? путь
            запланированныеСсылки.append((
                путь: путь,
                целевойПуть: целевойПуть,
                до: данные,
                после: переписанные,
                замены: результатПерезаписи.числоЗамен))
        }

        return ПодготовленныйПлан(
            карта: карта,
            исходныеФайлы: записи.sorted { $0.путь < $1.путь },
            путиСсылок: запланированныеСсылки,
            исходныйКоммит: исходныйКоммит,
            деревоИсточника: деревоИсточника)
    }

    private static func проверитьПутиИсточника(_ записи: [ЗаписьGit], в корень: URL) throws {
        for запись in записи {
            let путь = корень.appendingPathComponent(запись.путь)
            let атрибуты = try FileManager.default.attributesOfItem(atPath: путь.path)
            guard атрибуты[.type] as? FileAttributeType == .typeRegular else {
                throw ОшибкаКомандыFUMA("Необычный тип файла: " + запись.путь)
            }
        }
    }

    private static func проверитьНазначения(_ карта: КартаПутейFUMA, записи: [ЗаписьGit], в корень: URL) throws {
        let исходники = Set(записи.map(\.путь))
        for запись in записи {
            guard let назначение = карта.целевойПутьДляСсылки(запись.путь) else {
                throw ОшибкаКомандыFUMA("Для файла нет назначения: " + запись.путь)
            }
            guard !исходники.contains(назначение) else {
                throw ОшибкаКомандыFUMA("Назначение попадает в старый источник: " + назначение)
            }
            var накопленный = ""
            let части = назначение.split(separator: "/").map(String.init)
            for (номер, часть) in части.enumerated() {
                накопленный = накопленный.isEmpty ? часть : накопленный + "/" + часть
                let url = корень.appendingPathComponent(накопленный)
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                let атрибуты = try FileManager.default.attributesOfItem(atPath: url.path)
                let тип = атрибуты[.type] as? FileAttributeType
                if номер == части.count - 1 || тип != .typeDirectory {
                    throw ОшибкаКомандыFUMA("Целевой путь уже занят: " + накопленный)
                }
            }
        }
        let маркер = корень.appendingPathComponent(путьМаркера)
        let списокПутей = корень.appendingPathComponent(путьСпискаПутей)
        guard !FileManager.default.fileExists(atPath: маркер.path),
              !FileManager.default.fileExists(atPath: списокПутей.path) else {
            throw ОшибкаКомандыFUMA("Маркер форматирования неожиданно существует")
        }
    }

    private static func разрешёнПерезаписьСсылок(в путь: String) -> Bool {
        let компоненты = путь.split(separator: "/").map { String($0).lowercased() }
        let имя = компоненты.last ?? ""
        let расширение = URL(fileURLWithPath: путь).pathExtension.lowercased()
        let текстовыеРасширения: Set<String> = [
            "swift", "md", "json", "py", "sh", "toml", "yaml", "yml", "txt", "xml",
            "plist", "pbxproj", "xcscheme", "xcconfig", "entitlements", "strings", "c", "h",
            "modulemap", "js", "m", "mm", "gradle", "kts", "properties", "gitignore"
        ]
        guard текстовыеРасширения.contains(расширение) || имя == ".gitignore",
              !имя.hasSuffix(".jsonl"),
              !путь.hasPrefix("Proyekcii/"),
              !путь.hasPrefix("Issues/"),
              !путь.hasPrefix("Sboi/"),
              !путь.hasPrefix("Сбои/"),
              !путь.hasPrefix("Zhurnal/"),
              !путь.hasPrefix("Журнал/"),
              !путь.hasPrefix("zhurnal/"),
              !путь.hasPrefix("zhurnal/"),
              !путь.hasPrefix("koordinaciya/"),
              !путь.hasPrefix("Источники/URL/"),
              !путь.hasPrefix("Вопросы и ответы/"),
              !путь.hasPrefix("otchyot-"),
              !путь.hasPrefix("fuma/format/"),
              !путь.hasPrefix("fuma/zhurnal/"),
              !путь.hasSuffix("/манифест-переноса.json"),
              путь != "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy-кандидата-слияния.json",
              путь != "iskhodniki/aktualizaciya-putej/formatirovatj-derevo-fuma.swift",
              путь != "proverki/aktualizaciya-putej/proverki-formatirovaniya-dereva-fuma.swift",
              путь != "dokumentaciya/rabochaya-arkhitektura-fum-fuma.md",
              !компоненты.contains("профили"),
              !компоненты.contains("фикстуры"),
              !компоненты.contains("совместимость"),
              !компоненты.contains("zhurnal"),
              !компоненты.contains("журнал"),
              !компоненты.contains("tests-фикстуры") else { return false }

        let историческиеРазделыПланирования: Set<String> = [
            "дочерние-поручения", "параллельные-постановки", "карточки-шагов", "поставки",
            "предложения", "рабочий-контекст-задачи", "материалы-базиса-узла", "решения-постановки",
            "работы-задач", "задачи"
        ]
        if компоненты.contains("планирование"),
           !Set(компоненты).isDisjoint(with: историческиеРазделыПланирования) {
            return false
        }
        if путь == "Инструменты/fum-konvejyer-proizvodnykh-vetok/SKILL.md" { return false }
        return true
    }

    private static func записиСсылок(
        из ссылки: [(путь: String, целевойПуть: String, до: Data, после: Data, замены: Int)]
    ) -> [ЗаписьСсылки] {
        ссылки.map { ссылка in
            ЗаписьСсылки(
                путь: ссылка.целевойПуть,
                числоЗамен: ссылка.замены,
                sha256До: хэш(ссылка.до),
                sha256После: хэш(ссылка.после))
        }
    }

    private static func применить(_ план: ПодготовленныйПлан, в корень: URL, маркерURL: URL) throws {
        var исходныеДанные: [String: Data] = [:]
        for файл in план.исходныеФайлы {
            исходныеДанные[файл.путь] = try Data(contentsOf: корень.appendingPathComponent(файл.путь))
        }

        for файл in план.исходныеФайлы {
            guard let назначение = план.карта.целевойПутьДляСсылки(файл.путь) else {
                throw ОшибкаКомандыFUMA("План потерял путь назначения: " + файл.путь)
            }
            let целевойURL = корень.appendingPathComponent(назначение)
            try FileManager.default.createDirectory(
                at: целевойURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            _ = try git(["mv", "--", файл.путь, назначение], в: корень)
            guard let до = исходныеДанные[файл.путь],
                  try Data(contentsOf: целевойURL) == до else {
                throw ОшибкаКомандыFUMA("git mv изменил байты файла: " + назначение)
            }
            try восстановитьРежимGit(файл.режим, для: целевойURL)
        }

        for ссылка in план.путиСсылок {
            let url = корень.appendingPathComponent(ссылка.целевойПуть)
            guard try Data(contentsOf: url) == ссылка.до else {
                throw ОшибкаКомандыFUMA("Файл ссылки изменился после планирования: " + ссылка.целевойПуть)
            }
            let атрибутыДоЗаписи = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let режимДоЗаписи = атрибутыДоЗаписи[.posixPermissions] as? NSNumber else {
                throw ОшибкаКомандыFUMA("Не удалось сохранить права файла: " + ссылка.целевойПуть)
            }
            try ссылка.после.write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: режимДоЗаписи], ofItemAtPath: url.path)
            guard try Data(contentsOf: url) == ссылка.после else {
                throw ОшибкаКомандыFUMA("Не удалось проверить обновлённую ссылку: " + ссылка.целевойПуть)
            }
        }

        let картаСтадии = try РазборВыводаПутейFUMA.байтовыеЗаписиИндекса(
            git(["ls-files", "--stage", "-z"], в: корень))
        let нужныеПути = Set(план.исходныеФайлы.compactMap {
            план.карта.целевойПутьДляСсылки($0.путь).map { Data($0.utf8) }
        })
        var стадии: [Data: БайтоваяЗаписьИндексаFUMA] = [:]
        for запись in картаСтадии where нужныеПути.contains(запись.путь) {
            guard запись.стадия == 0, стадии[запись.путь] == nil else {
                throw ОшибкаКомандыFUMA("Повтор или конфликтная стадия целевого пути в индексе")
            }
            стадии[запись.путь] = запись
        }
        var перемещения: [ЗаписьПеремещения] = []
        for файл in план.исходныеФайлы {
            guard let целевойПуть = план.карта.целевойПутьДляСсылки(файл.путь),
                  let записьИндекса = стадии[Data(целевойПуть.utf8)] else {
                throw ОшибкаКомандыFUMA("После git mv путь не найден в индексе")
            }
            let послеПеремещения = try Data(contentsOf: корень.appendingPathComponent(целевойПуть))
            let данныеПосле = план.путиСсылок.first(where: { $0.целевойПуть == целевойПуть })?.после
                ?? исходныеДанные[файл.путь]!
            guard записьИндекса.режим == файл.режим,
                  записьИндекса.объект == файл.объект,
                  послеПеремещения == данныеПосле else {
                throw ОшибкаКомандыFUMA("Не сохранены режим или байты файла: " + целевойПуть)
            }
            перемещения.append(ЗаписьПеремещения(
                исходное: файл.путь,
                целевое: целевойПуть,
                режимGit: файл.режим,
                исходныйОбъект: файл.объект,
                sha256До: хэш(исходныеДанные[файл.путь]!),
                sha256После: хэш(данныеПосле)))
        }

        let манифест = МанифестФорматирования(
            схема: "fum.fuma.path-format-manifest.v1",
            версия: ФорматировщикПутейFUMA.версия,
            исходныйКоммит: план.исходныйКоммит,
            деревоИсточника: план.деревоИсточника,
            карта: план.карта,
            перемещения: перемещения,
            ссылки: записиСсылок(из: план.путиСсылок))
        let данныеМаркера = try кодироватьJSON(манифест)
        let данныеСпискаПутей = Data(([ФорматировщикПутейFUMA.версия]
            + перемещения.map(\.целевое)).joined(separator: "\n").appending("\n").utf8)
        try FileManager.default.createDirectory(
            at: маркерURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try данныеМаркера.write(to: маркерURL, options: .atomic)
        try данныеСпискаПутей.write(
            to: корень.appendingPathComponent(путьСпискаПутей), options: .atomic)
    }

    private static func восстановитьРежимGit(_ режим: String, для url: URL) throws {
        let права: NSNumber
        switch режим {
        case "100644": права = 0o644
        case "100755": права = 0o755
        default: throw ОшибкаКомандыFUMA("Неизвестный режим Git: " + режим)
        }
        try FileManager.default.setAttributes([.posixPermissions: права], ofItemAtPath: url.path)
    }

    private static func разобратьЗаписиGit(_ данные: Data) throws -> [ЗаписьGit] {
        try РазборВыводаПутейFUMA.записиИндекса(данные).map { запись in
            ЗаписьGit(путь: запись.путь, режим: запись.режим, объект: запись.объект)
        }
    }

    private static func разобратьZСтроки(_ данные: Data) throws -> [String] {
        try РазборВыводаПутейFUMA.пути(данные)
    }

    private static func gitText(_ аргументы: [String], в корень: URL) throws -> String {
        guard let текст = String(data: try git(аргументы, в: корень), encoding: .utf8) else {
            throw ОшибкаКомандыFUMA("Git вернул не-UTF-8 текст")
        }
        return текст.trimmingCharacters(in: .newlines)
    }

    private static func git(
        _ аргументы: [String],
        в корень: URL,
        допустимыеКоды: Set<Int> = [0]
    ) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = корень
        let stdout = Pipe()
        let stderr = Pipe()
        процесс.standardOutput = stdout
        процесс.standardError = stderr
        try процесс.run()
        let вывод = stdout.fileHandleForReading.readDataToEndOfFile()
        let ошибка = stderr.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard допустимыеКоды.contains(Int(процесс.terminationStatus)) else {
            let текст = String(data: ошибка, encoding: .utf8) ?? "ошибка Git"
            throw ОшибкаКомандыFUMA("git " + аргументы.joined(separator: " ") + ": " + текст)
        }
        return вывод
    }

    private static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private static func кодироватьJSON<T: Encodable>(_ значение: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try encoder.encode(значение)
        данные.append(10)
        return данные
    }

    private static func записатьJSON<T: Encodable>(_ значение: T, в файл: FileHandle) throws {
        try файл.write(contentsOf: кодироватьJSON(значение))
    }
}

private struct ОшибкаКомандыFUMA: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
