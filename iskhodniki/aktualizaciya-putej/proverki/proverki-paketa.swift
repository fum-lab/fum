import Foundation
import Darwin
import Testing
@testable import АктуализацияПутей

@Suite("Пакет девяти путей")
struct ПроверкиПакета {
    private func разрешающийВход() -> ВходРешенияПакета {
        ВходРешенияПакета(ограды: ОградыПакета(план_совпадает: true, снимок_совпадает: true,
            индекс_совпадает: true, пути_разрешены: true), число_переносов: 9, состояние_намерения: "сохранено")
    }

    @Test("Долговечное намерение и все ограды различают решение существующего FUMA")
    func структурирующееРешение() throws {
        let результат = try ПравилаПакета.выполнить(разрешающийВход())
        #expect(результат.решение.допустить_применение)
        #expect(результат.решение.применение == "не-выполнено")
        #expect(результат.решение.причина == nil)
        let наблюдение = try #require(JSONSerialization.jsonObject(with: результат.наблюдение) as? [String: Any])
        #expect(наблюдение["схема"] as? String == "fum.наблюдение-оператора.2")
        let применения = try #require(наблюдение["применения"] as? [[String: Any]])
        #expect(применения.count == 1)
        #expect(применения.first?["определение"] as? String == "все-ограды-разрешают")
    }

    @Test("Число, схема, намерение и каждая отдельная ограда закрывают применение")
    func структурирующиеОтказы() throws {
        for номер in 0..<7 {
            var вход = разрешающийВход()
            let причина: String
            switch номер {
            case 0: вход.схема = "неизвестно"; причина = "неверная-схема-входа"
            case 1: вход.число_переносов = 8; причина = "не-девять-переносов"
            case 2: вход.состояние_намерения = "неизвестно"; причина = "намерение-не-сохранено"
            case 3: вход.ограды.план_совпадает = false; причина = "ограды-не-пройдены"
            case 4: вход.ограды.снимок_совпадает = false; причина = "ограды-не-пройдены"
            case 5: вход.ограды.индекс_совпадает = false; причина = "ограды-не-пройдены"
            default: вход.ограды.пути_разрешены = false; причина = "ограды-не-пройдены"
            }
            let решение = try ПравилаПакета.выполнить(вход).решение
            #expect(!решение.допустить_применение)
            #expect(решение.причина == причина)
        }
    }

    @Test("Один план связывает девять blob, полный Markdown и пять правок")
    func конечныйПакетныйПлан() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        #expect(план.переносы.count == 9)
        #expect(план.правки.count == 5)
        #expect(план.документы.count == 7)
        #expect(план.документы.contains { $0.путь == "заметка.md" })
        #expect(план.переносы.map(\.целевой) == ФикстураПакета.пути.map { $0.1 })
        for перенос in план.переносы {
            #expect(перенос.режим == "100644")
            #expect(try фикстура.гит(["rev-parse", "HEAD:" + перенос.исходный]) == Data((перенос.объект + "\n").utf8))
        }
    }

    @Test("Каноническое равенство String не подменяет exact UTF-8 плана")
    func байтоваяСвязностьПлана() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        var подмена = план
        подмена.переносы[4].исходный = подмена.переносы[4].исходный.decomposedStringWithCanonicalMapping
        #expect(подмена.переносы[4].исходный == план.переносы[4].исходный)
        #expect(Data(подмена.переносы[4].исходный.utf8) != Data(план.переносы[4].исходный.utf8))
        let изменённые = try байтыПлана(подмена)
        #expect(throws: ОтказПакета.условие("дрейф-снимка")) {
            try ПакетПутей.сверить(сохранённые: изменённые, ожидаемыйХэш: хэшПутей(изменённые), текущий: план)
        }
        let сохранённые = try байтыПлана(план)
        try ПакетПутей.сверить(сохранённые: сохранённые, ожидаемыйХэш: хэшПутей(сохранённые), текущий: план)
    }

    @Test("Разбор не прячет активные ссылки и не меняет protected reference")
    func оградыРазбораMarkdown() throws {
        let пары = ФикстураПакета.пути.map { ОтображениеПути(исходный: $0.0, целевой: $0.1) }
        func разрешить(_ текст: String, путь: String) throws -> [ИзменениеСсылокПакета] {
            let данные = Data(текст.utf8)
            return try РешательСсылокПакета.разрешить(документы: [ДокументСсылокПакета(
                путь: путь, байты: данные, sha256: хэшПутей(данные))], ожидаемыеПути: [путь],
                пары: пары, разрешённыеДокументы: ПакетПутей.разрешённыеДокументы, проверитьАдрес: { _ in })
        }
        let живойПуть = "iskhodniki/zapusk/README.md"
        let ссылка = "[Архив](../arkhiv-codex/README.md)"
        #expect(try разрешить("```example```\n\n" + ссылка + "\n", путь: живойПуть).count == 1)
        #expect(try разрешить("Перед `x\n\n" + ссылка + "\n\nПосле `.\n", путь: живойПуть).count == 1)
        let закодированный = "../arkhiv-codex/README.md".unicodeScalars.map { "&#x" + String($0.value, radix: 16) + ";" }.joined()
        #expect(throws: ОтказСсылокПакета.self) {
            try разрешить("<a\nhref=\n\"" + закодированный + "\"\n>x\n</a>\n", путь: живойПуть)
        }
        let путьЗапроса = "Журнал/2026-10-26_01-48-08_MSK_включить-принятую-основу-в-архив-codex/запрос.md"
        #expect(throws: ОтказСсылокПакета.self) {
            try разрешить("## Текст запроса\n[сырьё][r]\n\n## Повлиял на файлы\n[r]: ../../iskhodniki/arkhiv-codex/README.md\n", путь: путьЗапроса)
        }
    }

    @Test("Открытый FD не заменяет позднюю проверку имени каталога")
    func именнаяСвязьКаталога() throws {
        let фикстура = try ФикстураПакета()
        let исходный = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/komanda")
        let запасной = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/запасной")
        let временный = фикстура.корень.appendingPathComponent("iskhodniki/arkhiv-codex/временный")
        try FileManager.default.createDirectory(at: запасной, withIntermediateDirectories: false)
        try Data("другой inode\n".utf8).write(to: запасной.appendingPathComponent("Команда.swift"))
        let читатель = try ЧитательПакета(фикстура.корень)
        _ = try читатель.прочитать(ФикстураПакета.пути[0].0)
        try FileManager.default.moveItem(at: исходный, to: временный)
        try FileManager.default.moveItem(at: запасной, to: исходный)
        try FileManager.default.moveItem(at: временный, to: запасной)
        #expect(throws: ОтказПакета.self) { try читатель.снимокКаталогов() }
    }

    @Test("Apply переносит всю партию; Package и Markdown остаются вне индекса")
    func переносПартииИСтадирование() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let байты = try байтыПлана(план)
        let квитанция = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        #expect(квитанция.исход == "завершено")
        #expect(квитанция.подтверждённый_префикс == 14)
        for перенос in план.переносы {
            #expect(!FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(перенос.исходный).path))
            let данные = try Data(contentsOf: фикстура.корень.appendingPathComponent(перенос.целевой))
            #expect(хэшПутей(данные) == перенос.sha256)
            #expect(try фикстура.гит(["rev-parse", ":" + перенос.целевой]) == Data((перенос.объект + "\n").utf8))
        }
        let неиндексированные = Set(String(decoding: try фикстура.гит(["diff", "--name-only"]), as: UTF8.self).split(separator: "\n").map(String.init))
        #expect(неиндексированные == Set(план.правки.map(\.путь)))
        #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent("Источники/native.jsonl")) == фикстура.сырые)
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        let повтор = try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
            ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        #expect(повтор == квитанция)
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
    }

    @Test("Позднее изменение untracked Markdown останавливает партию до первого эффекта")
    func позднийДрейфMarkdown() async throws {
        let фикстура = try ФикстураПакета()
        let план = try await ПакетПутей.построить(корень: фикстура.корень, вход: фикстура.поручение())
        let индекс = try фикстура.гит(["ls-files", "--stage", "-z"])
        try фикстура.записать("заметка.md", "изменено\n")
        let байты = try байтыПлана(план)
        await #expect(throws: ОтказПакета.условие("дрейф-снимка")) {
            try await ПакетПутей.применить(корень: фикстура.корень, план: байты,
                ожидаемыйХэш: хэшПутей(байты), хранилищеДляПроверки: фикстура.хранилище)
        }
        #expect(try фикстура.гит(["ls-files", "--stage", "-z"]) == индекс)
        #expect(FileManager.default.fileExists(atPath: фикстура.корень.appendingPathComponent(ФикстураПакета.пути[0].0).path))
    }
}

private final class ФикстураПакета {
    static let пути = [
        ("iskhodniki/arkhiv-codex/komanda/Команда.swift", "iskhodniki/arkhiv-codex/komanda/komanda.swift"),
        ("iskhodniki/arkhiv-codex/Архив.swift", "iskhodniki/arkhiv-codex/arkhiv.swift"),
        ("iskhodniki/arkhiv-codex/Источник.swift", "iskhodniki/arkhiv-codex/istochnik.swift"),
        ("iskhodniki/arkhiv-codex/Порция.swift", "iskhodniki/arkhiv-codex/porciya.swift"),
        ("iskhodniki/arkhiv-codex/Файлы.swift", "iskhodniki/arkhiv-codex/fajlyi.swift"),
        ("proverki/arkhiv-codex/АрхивТесты.swift", "proverki/arkhiv-codex/arkhiv-testyi.swift"),
        ("proverki/arkhiv-codex/ПроцессыИПрофиль.swift", "proverki/arkhiv-codex/processyi-i-profilj.swift"),
        ("proverki/arkhiv-codex/СовместимостьЗапуска.swift", "proverki/arkhiv-codex/sovmestimostj-zapuska.swift"),
        ("iskhodniki/arkhiv-codex/README.md", "iskhodniki/arkhiv-codex/rukovodstvo.md")
    ]
    let родитель: URL
    let корень: URL
    let хранилище: URL
    let сырые = Data([0, 1, 2, 255, 10, 13, 0])

    init() throws {
        родитель = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("fum-batch-" + UUID().uuidString)
        корень = родитель.appendingPathComponent("worktree")
        хранилище = родитель.appendingPathComponent("runtime")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        _ = try гит(["init", "--initial-branch=codex/batch-fixture"])
        for (путь, _) in Self.пути { try записать(путь, "синтетические байты \(путь)\n") }
        try записать("iskhodniki/arkhiv-codex/README.md", "# Архив\n\n[Другое](../другое.md)\n")
        try записать("Package.swift", """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(name: "Фикстура", targets: [
            .target(name: "АрхивКодекса", dependencies: [],
                path: "iskhodniki/arkhiv-codex", exclude: ["README.md", "zhurnal"])
        ])

        """)
        try записать("iskhodniki/zapusk/README.md", "# Запуск\n\n[Архив](../arkhiv-codex/README.md)\n")
        try записать("Журнал/2026-10-26_00-11-30_MSK_сохранить-многосегментный-raw-codex/отчёт.md",
            "# Отчёт\n\n## Источники\n\n[Архив](../../iskhodniki/arkhiv-codex/README.md)\n")
        try записать("Журнал/2026-10-26_01-48-08_MSK_включить-принятую-основу-в-архив-codex/запрос.md",
            "# Запрос\n\n## Текст запроса\n\n```text\n[Дословно](../../iskhodniki/arkhiv-codex/README.md)\n```\n\n## Повлиял на файлы\n\n[Архив](../../iskhodniki/arkhiv-codex/README.md)\n")
        try записать("Сбои/FUM-СБОЙ-0241-декомпозиция-имени-профиля.md",
            "# Сбой\n\n[Профиль](../proverki/arkhiv-codex/ПроцессыИПрофиль.swift)\n")
        try записать("Источники/сырой.md", "```text\n[Дословно](../iskhodniki/arkhiv-codex/README.md)\n```\n")
        try сырые.write(to: корень.appendingPathComponent("Источники/native.jsonl"))
        _ = try гит(["add", "--all", "--", "."])
        _ = try гит(["-c", "user.name=Фикстура", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgSign=false", "commit", "-m", "Фикстура"])
        try записать("заметка.md", "# Новая неигнорируемая заметка\n")
    }

    deinit { try? FileManager.default.removeItem(at: родитель) }

    func записать(_ путь: String, _ текст: String) throws {
        let файл = корень.appendingPathComponent(путь)
        try FileManager.default.createDirectory(at: файл.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(текст.utf8).write(to: файл)
    }

    func гит(_ аргументы: [String]) throws -> Data {
        do { return try ЧитательПакета.гит(корень, аргументы) }
        catch { throw ОтказПакета.условие("отказ-фикстуры: " + аргументы.joined(separator: " ")) }
    }

    func поручение() throws -> ПоручениеПакета {
        func строка(_ аргументы: [String]) throws -> String {
            String(decoding: try гит(аргументы), as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        return try ПоручениеПакета(корневая_задача: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
            владелец: ProcessInfo.processInfo.environment["CODEX_THREAD_ID"]!,
            коммит: строка(["rev-parse", "HEAD"]), дерево: строка(["rev-parse", "HEAD^{tree}"]),
            ветка: строка(["symbolic-ref", "HEAD"]), время_свежести: "2026-10-26 04:31:22 MSK")
    }
}
