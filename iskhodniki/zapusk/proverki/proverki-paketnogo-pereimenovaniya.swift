import Foundation
import Testing

@Suite("Пакетная миграция файлов FUMA", .serialized)
struct ПроверкиПакетногоПереименования {
    private let коммит = "658aa31e8da6b9ac0f7790e184b27e73d635a542"
    private let ветка = "refs/heads/fum-lab/fum/fuma/zapusk/master"

    @Test("Все однофайловые планы предшествуют первому применению")
    func планыПредшествуютПрименению() throws {
        var вызовы: [String] = []
        let задания = Self.задания("a", "b", "c", "d")
        let переименователь = ПакетныйПереименователь { режим, перенос in
            вызовы.append("\(режим):\(перенос.источник)")
            return 0
        }

        try переименователь.выполнить(задания)

        #expect(вызовы == [
            "plan:a.swift", "plan:b.swift", "plan:c.swift", "plan:d.swift",
            "apply:a.swift", "apply:b.swift", "apply:c.swift", "apply:d.swift"
        ])
    }

    @Test("Отказ однофайлового плана предотвращает всё применение")
    func отказПланаНеПрименяетНичего() {
        var вызовы: [String] = []
        let переименователь = ПакетныйПереименователь { режим, перенос in
            вызовы.append("\(режим):\(перенос.источник)")
            return режим == "plan" && перенос.источник == "b.swift" ? 1 : 0
        }

        do {
            try переименователь.выполнить(Self.задания("a", "b", "c"))
            Issue.record("Неуспешный предварительный план был принят")
        } catch {
            #expect(вызовы == ["plan:a.swift", "plan:b.swift"])
        }
    }

    @Test("Отказ применения прекращает последующие однофайловые переносы")
    func отказПримененияПрекращаетОстаток() {
        var вызовы: [String] = []
        let переименователь = ПакетныйПереименователь { режим, перенос in
            вызовы.append("\(режим):\(перенос.источник)")
            return режим == "apply" && перенос.источник == "b.swift" ? 1 : 0
        }

        do {
            try переименователь.выполнить(Self.задания("a", "b", "c"))
            Issue.record("Неуспешное применение было принято")
        } catch {
            #expect(вызовы == [
                "plan:a.swift", "plan:b.swift", "plan:c.swift",
                "apply:a.swift", "apply:b.swift"
            ])
        }
    }

    @Test("Повторные или пересекающиеся пути отклоняются до исполнителя")
    func повторныеПутиЗакрытыДоЗапуска() {
        var числоВызовов = 0
        let переименователь = ПакетныйПереименователь { _, _ in
            числоВызовов += 1
            return 0
        }
        let повтор = ПакетныйПереименователь.Перенос(
            источник: "a.swift",
            назначение: "renamed.swift"
        )

        do {
            try переименователь.выполнить([повтор, повтор])
            Issue.record("Повторный путь был принят")
        } catch {
            #expect(числоВызовов == 0)
        }
    }

    @Test("Unicode пути канонизируются в точные NFC байты Git index")
    func путиКанонизируютсяПередЗапуском() throws {
        let имяGit = "источник-й.swift"
        let назначениеGit = "назначение-й.swift"
        let имяNFD = имяGit.decomposedStringWithCanonicalMapping
        let назначениеNFD = назначениеGit.decomposedStringWithCanonicalMapping
        var байтыИсточников: [[UInt8]] = []
        var байтыНазначений: [[UInt8]] = []
        let переименователь = ПакетныйПереименователь { _, перенос in
            байтыИсточников.append(Array(перенос.источник.utf8))
            байтыНазначений.append(Array(перенос.назначение.utf8))
            return 0
        }

        try переименователь.выполнить([
            ПакетныйПереименователь.Перенос(
                источник: имяNFD,
                назначение: назначениеNFD
            )
        ])

        #expect(байтыИсточников == [Array(имяGit.utf8), Array(имяGit.utf8)])
        #expect(байтыНазначений == [Array(назначениеGit.utf8), Array(назначениеGit.utf8)])
    }

    @Test("Одобренный набор переносится только при явном включении")
    func выполнитьОдобренныйНаборЕслиВыбран() throws {
        guard ProcessInfo.processInfo.environment["FUMA_RENAME_BATCH_APPLY"] == "1" else { return }
        guard let путьКорня = ProcessInfo.processInfo.environment["FUMA_RENAME_BATCH_ROOT"],
              путьКорня.hasPrefix("/") else {
            Issue.record("Для пакетного переноса задайте абсолютный FUMA_RENAME_BATCH_ROOT")
            return
        }
        let корень = URL(fileURLWithPath: путьКорня, isDirectory: true).standardizedFileURL
        let переименователь = ПакетныйПереименователь { режим, перенос in
            try Self.запуститьОднофайловыйИнструмент(
                режим,
                перенос: перенос,
                корень: корень,
                коммит: коммит,
                ветка: ветка
            )
        }
        let задания = [
            ПакетныйПереименователь.Перенос(
                источник: "iskhodniki/zapusk/ВходПакетаПутей.swift",
                назначение: "iskhodniki/zapusk/vkhod-paketa-putej.swift"
            ),
            ПакетныйПереименователь.Перенос(
                источник: "iskhodniki/zapusk/ОбработчикПакетаПутей.swift",
                назначение: "iskhodniki/zapusk/obrabotchik-paketa-putej.swift"
            ),
            ПакетныйПереименователь.Перенос(
                источник: "proverki/zapusk/ПроверкиПакетаПутей.swift",
                назначение: "iskhodniki/zapusk/proverki/proverki-paketa-putej.swift"
            ),
            ПакетныйПереименователь.Перенос(
                источник: "proverki/zapusk/ПрофильПакетаПутей.swift",
                назначение: "iskhodniki/zapusk/proverki/profilj-paketa-putej.swift"
            )
        ]

        try переименователь.выполнить(задания)
    }

    private static func задания(_ основы: String...) -> [ПакетныйПереименователь.Перенос] {
        основы.map {
            ПакетныйПереименователь.Перенос(
                источник: "\($0).swift",
                назначение: "\($0)-renamed.swift"
            )
        }
    }

    private static func запуститьОднофайловыйИнструмент(
        _ режим: String,
        перенос: ПакетныйПереименователь.Перенос,
        корень: URL,
        коммит: String,
        ветка: String
    ) throws -> Int32 {
        let путьPython = try найтиИсполняемыйФайл("python3")
        let путьGit = try найтиИсполняемыйФайл("git")
        try проверитьОпорноеСостояние(
            корень: корень,
            коммит: коммит,
            ветка: ветка,
            путьGit: путьGit
        )

        let путьИнструмента = корень.appendingPathComponent(
            "Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/" +
            "scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py"
        ).standardizedFileURL
        let физическийПутьИнструмента = путьИнструмента.resolvingSymlinksInPath().standardizedFileURL
        let атрибуты = try? FileManager.default.attributesOfItem(atPath: путьИнструмента.path)
        guard физическийПутьИнструмента.path == путьИнструмента.path,
              атрибуты?[.type] as? FileAttributeType == .typeRegular else {
            throw ОшибкаПакетногоПереименователя.инструментНедоступен(путьИнструмента.path)
        }

        let процесс = Process()
        процесс.executableURL = путьPython
        процесс.arguments = [
            путьИнструмента.path,
            режим,
            "--source", перенос.источник,
            "--destination", перенос.назначение,
            "--repo-root", корень.path
        ]
        процесс.currentDirectoryURL = корень
        процесс.standardOutput = FileHandle.standardOutput
        процесс.standardError = FileHandle.standardError
        try процесс.run()
        процесс.waitUntilExit()
        return процесс.terminationStatus
    }

    private static func найтиИсполняемыйФайл(_ имя: String) throws -> URL {
        guard let путь = ProcessInfo.processInfo.environment["PATH"]?
            .split(separator: ":")
            .map({ URL(fileURLWithPath: String($0), isDirectory: true).appendingPathComponent(имя) })
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw ОшибкаПакетногоПереименователя.исполняемыйФайлНеНайден(имя)
        }
        return путь
    }

    private static func проверитьОпорноеСостояние(
        корень: URL,
        коммит: String,
        ветка: String,
        путьGit: URL
    ) throws {
        let фактическийКорень = try прочитатьGit(
            ["rev-parse", "--show-toplevel"],
            корень: корень,
            путьGit: путьGit
        )
        let фактическийКоммит = try прочитатьGit(
            ["rev-parse", "HEAD"],
            корень: корень,
            путьGit: путьGit
        )
        let фактическаяВетка = try прочитатьGit(
            ["symbolic-ref", "HEAD"],
            корень: корень,
            путьGit: путьGit
        )
        guard URL(fileURLWithPath: фактическийКорень).resolvingSymlinksInPath().path ==
                корень.resolvingSymlinksInPath().path,
              фактическийКоммит == коммит,
              фактическаяВетка == ветка else {
            throw ОшибкаПакетногоПереименователя.опорноеСостояниеИзменилось
        }
    }

    private static func прочитатьGit(
        _ аргументы: [String],
        корень: URL,
        путьGit: URL
    ) throws -> String {
        let процесс = Process()
        let вывод = Pipe()
        let ошибки = Pipe()
        процесс.executableURL = путьGit
        процесс.arguments = ["--no-optional-locks", "-C", корень.path] + аргументы
        процесс.currentDirectoryURL = корень
        var окружение = ProcessInfo.processInfo.environment
        for имя in Array(окружение.keys) where имя.hasPrefix("GIT_") {
            окружение.removeValue(forKey: имя)
        }
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        процесс.environment = окружение
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        try процесс.run()
        процесс.waitUntilExit()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        guard процесс.terminationStatus == 0 else {
            let диагностика = String(
                decoding: ошибки.fileHandleForReading.readDataToEndOfFile(),
                as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            throw ОшибкаПакетногоПереименователя.gitОтказал(диагностика)
        }
        return String(decoding: данные, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum ОшибкаПакетногоПереименователя: Error {
    case исполняемыйФайлНеНайден(String)
    case инструментНедоступен(String)
    case опорноеСостояниеИзменилось
    case gitОтказал(String)
}

struct ПакетныйПереименователь {
    struct Перенос: Equatable {
        let источник: String
        let назначение: String
    }

    enum Ошибка: Error, CustomStringConvertible {
        case пустойПакет
        case повторныйИлиПересекающийсяПуть
        case отказПлана(Int32)
        case отказПрименения(Int32)

        var description: String {
            switch self {
            case .пустойПакет:
                "Пакет переносов пуст"
            case .повторныйИлиПересекающийсяПуть:
                "Пакет содержит повторные, пересекающиеся или самоназначенные пути"
            case .отказПлана(let код):
                "Однофайловый план переноса отказал, код \(код)"
            case .отказПрименения(let код):
                "Однофайловое применение отказало, код \(код)"
            }
        }
    }

    private let запуск: (String, Перенос) throws -> Int32

    init(запуск: @escaping (String, Перенос) throws -> Int32) {
        self.запуск = запуск
    }

    func выполнить(_ переносы: [Перенос]) throws {
        guard !переносы.isEmpty else { throw Ошибка.пустойПакет }
        let канонические = переносы.map {
            Перенос(
                источник: $0.источник.precomposedStringWithCanonicalMapping,
                назначение: $0.назначение.precomposedStringWithCanonicalMapping
            )
        }
        let источники = Set(канонические.map(\.источник))
        let назначения = Set(канонические.map(\.назначение))
        guard источники.count == канонические.count,
              назначения.count == канонические.count,
              источники.isDisjoint(with: назначения),
              канонические.allSatisfy({ $0.источник != $0.назначение }) else {
            throw Ошибка.повторныйИлиПересекающийсяПуть
        }
        for перенос in канонические {
            let код = try запуск("plan", перенос)
            guard код == 0 else { throw Ошибка.отказПлана(код) }
        }
        for перенос in канонические {
            let код = try запуск("apply", перенос)
            guard код == 0 else { throw Ошибка.отказПрименения(код) }
        }
    }
}
