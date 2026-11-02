import Foundation
import Darwin
import Testing
@testable import АктуализацияПутей

// Source02: настоящие fixture Git/Segment операции ниже НЕ запускались.
private enum ОтказСистемнойФикстурыДокументации: Error { case намеренный }
private final class СчётчикСистемнойФикстурыДокументации: @unchecked Sendable {
    // Все обращения к состоянию защищены одним NSLock.
    private let замок = NSLock()
    private var число = 0
    func следующий() -> Int { замок.lock(); defer { замок.unlock() }; число += 1; return число }
}
private final class СистемнаяФикстураДокументации {
    let основание: URL
    let корень: URL
    let хранилище: URL
    init(файлы: [String: String] = ["Документация/a.md": "# Документ\n", "dokumentaciya/keep.md": "# Сохранить\n"]) throws {
        основание = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("fum-путиДокументации-source02-" + UUID().uuidString)
        корень = основание.appendingPathComponent("repo"); хранилище = основание.appendingPathComponent("store")
        try FileManager.default.createDirectory(at: основание, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try FileManager.default.createDirectory(at: хранилище, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        _ = try ПримитивыДокументации.гит(корень, ["init", "--quiet", "-b", "fixture"])
        for (путь, текст) in файлы { try записать(путь, текст) }
        _ = try ПримитивыДокументации.гит(корень, ["add", "--all"])
        _ = try ПримитивыДокументации.гит(корень, ["-c", "user.name=FUM Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "core.hooksPath=/dev/null", "commit", "--quiet", "-m", "Открытая fixture Source02"])
    }
    func записать(_ путь: String, _ текст: String) throws {
        let адрес = корень.appendingPathComponent(путь)
        try FileManager.default.createDirectory(at: адрес.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o755])
        try Data(текст.utf8).write(to: адрес)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: адрес.path)
    }
    func пакет() throws -> ПакетИсполненияДокументации {
        let коммит = try ПримитивыДокументации.текстГит(корень, ["rev-parse", "HEAD"])
        return try ПакетноеОбъединениеДокументации.построить(корень: корень, вход: .init(
            корневаяЗадача: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", владелец: "открытая fixture",
            ожидаемыйКоммит: коммит, ожидаемаяВетка: "refs/heads/fixture", времяСвежести: "2026-11-02 22:00:00 MSK",
            времяЖурнала: "2026-11-02T19:00:00Z", объединитьREADME: false, входящие: []))
    }
    func допуск(_ пакет: ПакетИсполненияДокументации) throws -> ДопускИсполненияДокументации {
        try .init(источникРешения: "только собственная открытая fixture будущего разрешённого теста", пакетSHA256: хэшПутей(байтыПлана(пакет)),
            физическийКорень: корень.path, ветка: пакет.план.основа.ветка, коммит: пакет.план.основа.коммит,
            кореньХранилища: хранилище.path, новыйСлотРазрешён: true, удалениеИсходниковРазрешено: true,
            внешниеПодтверждения: [:], входящийОхватИГраницыРесурсов: "маленькая изолированная fixture, без внешних ссылок/сети; это не product grant")
    }
    func очиститьПослеИзвестногоУспеха() throws {
        try FileManager.default.removeItem(at: основание)
    }
    // UNKNOWN fixtures намеренно сохраняются для read-only recovery assertions.
}

@Suite("Concrete Segment/file adapters документации — testSOURCE")
struct ПроверкиСистемныхАдаптеровДокументации {
    private func модельАдреснойКопии22() -> (УзелОбщейМиграции, УзелОбщейМиграции, [СтрокаОбщегоОтображения], Set<Data>) {
        // Синтетическая distillation структуры proof22. НЕ реальные blob bytes
        // и не подстановка их SHA: literal Root-пара остаётся отдельным input.
        var старые: [String] = [], новые: [String] = []
        var пространство: Set<Data> = [Data("Документация/22.md".utf8), Data("dokumentaciya/22.md".utf8)]
        var карта = [СтрокаОбщегоОтображения(исходный: "Документация/22.md", целевой: "dokumentaciya/22.md"),
            .init(исходный: "dokumentaciya/22.md", целевой: "dokumentaciya/22.md")]
        for номер in 0..<34 {
            let путь = "Документация/Цель-\(номер).md"; пространство.insert(Data(путь.utf8))
            карта.append(.init(исходный: путь, целевой: "dokumentaciya/Цель-\(номер).md"))
        }
        for номер in 0..<251 {
            if номер < 87 {
                let адрес = "Цель-\(номер % 34).md"
                старые.append("[цель](\(адрес))"); новые.append("[цель](../Документация/\(адрес))")
            } else {
                let адрес = "../Глоссарий/Цель-\((номер - 87) % 109).md"
                пространство.insert(Data("Глоссарий/Цель-\((номер - 87) % 109).md".utf8))
                старые.append("[термин](\(адрес))"); новые.append("[термин](\(адрес))")
            }
        }
        for номер in 0..<34 { старые.append("Пояснение \(номер)"); новые.append("Пояснение \(номер)") }
        let из = УзелОбщейМиграции(путь: "Документация/22.md", вид: .файл, режим: "100644", байты: Data((старые.joined(separator: "\n") + "\n").utf8))
        let в = УзелОбщейМиграции(путь: "dokumentaciya/22.md", вид: .файл, режим: "100644", байты: Data((новые.joined(separator: "\n") + "\n").utf8))
        return (из, в, карта, пространство)
    }

    @Test("Distilled22: 87 prefix edits, 34 uniqueURI, 251 links, 143 targets, 285 lines")
    func модельДоказательства22() throws {
        let (из, в, карта, пространство) = модельАдреснойКопии22()
        let доказательство = try ДоказательствоАдреснойКопииДокументации.построить(исходный: из, целевой: в, отображения: карта, пространство: пространство)
        #expect(доказательство.изменённыхАдресов == 87 && доказательство.различныхИзменённыхАдресов == 34)
        #expect(доказательство.локальныхАдресов == 251 && доказательство.различныхЦелей == 143 && доказательство.строк == 285)
        #expect(в.байты.count - из.байты.count == 2436)
        #expect(!доказательство.якоряПроверены)
    }

    @Test("Адресный доказательство закрывает nonURI difference, unparsed и другой resolved target")
    func отрицательныеВариантыДоказательства22() throws {
        let (из, в, карта, пространство) = модельАдреснойКопии22()
        var другойТекст = в; другойТекст.байты.append(contentsOf: Data("чужая проза\n".utf8))
        #expect(throws: (any Error).self) { try ДоказательствоАдреснойКопииДокументации.построить(исходный: из, целевой: другойТекст, отображения: карта, пространство: пространство) }
        var другойАдрес = в
        другойАдрес.байты = Data(String(decoding: в.байты, as: UTF8.self).replacingOccurrences(of: "../Документация/Цель-0.md", with: "../Документация/Цель-1.md").utf8)
        #expect(throws: (any Error).self) { try ДоказательствоАдреснойКопииДокументации.построить(исходный: из, целевой: другойАдрес, отображения: карта, пространство: пространство) }
        var неполныйИз = из, неполныйВ = в
        неполныйИз.байты.append(contentsOf: Data("[неразобрано](%ZZ)\n".utf8)); неполныйВ.байты.append(contentsOf: Data("[неразобрано](%ZZ)\n".utf8))
        #expect(throws: (any Error).self) { try ДоказательствоАдреснойКопииДокументации.построить(исходный: неполныйИз, целевой: неполныйВ, отображения: карта, пространство: пространство) }
    }

    @Test("MOVE и повтор завершённого результата: физические bytes/index и ноль replay")
    func реальноеПрименениеИПовтор() throws {
        let фикстура = try СистемнаяФикстураДокументации()
        let пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск)
        #expect(итог.исход == .завершено)
        #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent("dokumentaciya/a.md")) == Data("# Документ\n".utf8))
        #expect(try !ПримитивыДокументации.есть(фикстура.корень.appendingPathComponent("Документация")))
        let индекс = try ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"])
        let физическийАдрес = URL(fileURLWithPath: пакет.каталогGit).appendingPathComponent("index")
        let физическийДо = try ПримитивыДокументации.прочитать(физическийАдрес, предел: 67_108_864)
        let второй = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск, неисправность: { _, _ in
            Issue.record("Завершённый replay не должен запускать примитив")
        })
        #expect(второй == итог)
        #expect(try ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"]) == индекс)
        let физическийПосле = try ПримитивыДокументации.прочитать(физическийАдрес, предел: 67_108_864)
        #expect(физическийДо.0 == физическийПосле.0 && физическийДо.1 == физическийПосле.1)
        try фикстура.очиститьПослеИзвестногоУспеха()
    }

    @Test("Настоящий Segment удерживает writer lock; незавершённый slot не становится новым")
    func замокИНезакрытыйСлот() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let первый = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        _ = try первый.открыть(план: байтыПлана(пакет.план))
        let конкурент = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        #expect(throws: (any Error).self) { try конкурент.открыть(план: байтыПлана(пакет.план)) }
        конкурент.закрыть(); первый.закрыть()
        let повтор = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        switch try повтор.открыть(план: байтыПлана(пакет.план)) {
        case .удержанныйПрефикс(let известный, let намерение): #expect(известный == 0 && намерение == nil)
        default: Issue.record("Сохранённый пакет не разрешает новую попытку")
        }
        #expect(try повтор.данныеДляВосстановления() == байтыПлана(пакет))
        повтор.закрыть()
    }

    @Test("Intent без receipt сохраняется, не усечён и не повторяется")
    func намерениеБезПодтверждения() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let журнал = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        _ = try журнал.открыть(план: байтыПлана(пакет.план))
        try журнал.намерение(пакет.план.шаги[0], хэшПлана: хэшПутей(байтыПлана(пакет.план)))
        let адрес = журнал.каталогСлота.appendingPathComponent("сегмент.fumobs")
        журнал.закрыть()
        let до = try Data(contentsOf: адрес)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск)
        #expect(итог.исход == .удержано && итог.подтверждённыйПрефикс == 0)
        #expect(try Data(contentsOf: адрес) == до)
        #expect(try ПримитивыДокументации.есть(фикстура.корень.appendingPathComponent("Документация/a.md")))
    }

    @Test("Prepared target сначала становится tracked; отказ между add/rm оставляет source и reserves")
    func подготовленнаяКопияИНеизвестность() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: ["Документация/02.md": "# Лицензия\n", "dokumentaciya/keep.md": "# Сохранить\n"])
        try фикстура.записать("dokumentaciya/02.md", "# Лицензия\n")
        let пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        #expect(пакет.план.каноны.first?.подготовленнаяЦель == true)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск, неисправность: { фаза, _ in
            if фаза == "после-prepared-add" { throw ОтказСистемнойФикстурыДокументации.намеренный }
        })
        #expect(итог.исход == .неизвестно)
        let записи = try ПримитивыДокументации.индекс(ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"]))
        #expect(записи[Data("dokumentaciya/02.md".utf8)]?.объект == ПримитивыДокументации.объектGit(Data("# Лицензия\n".utf8)))
        #expect(записи[Data("Документация/02.md".utf8)] != nil)
        let каталогGit = URL(fileURLWithPath: пакет.каталогGit)
        let резервы = try FileManager.default.contentsOfDirectory(atPath: каталогGit.path).filter { $0.hasSuffix(".reserve") }
        #expect(резервы.count == 2)
        let исходныеБайты = try Data(contentsOf: фикстура.корень.appendingPathComponent("Документация/02.md"))
        #expect(try резервы.contains { try Data(contentsOf: каталогGit.appendingPathComponent($0)) == исходныеБайты })
        let rawПосле = try Data(contentsOf: каталогGit.appendingPathComponent("index"))
        let повтор = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск)
        #expect(повтор.исход == .удержано)
        #expect(try Data(contentsOf: каталогGit.appendingPathComponent("index")) == rawПосле)
    }

    @Test("Prepared coalesce без отказа оставляет единственную tracked canonical copy")
    func подготовленнаяКопияУспех() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: ["Документация/02.md": "# Лицензия\n", "dokumentaciya/keep.md": "# Сохранить\n"])
        try фикстура.записать("dokumentaciya/02.md", "# Лицензия\n")
        let пакет = try фикстура.пакет()
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет))
        #expect(итог.исход == .завершено)
        let индекс = try ПримитивыДокументации.индекс(ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"]))
        #expect(индекс[Data("Документация/02.md".utf8)] == nil && индекс[Data("dokumentaciya/02.md".utf8)] != nil)
        try фикстура.очиститьПослеИзвестногоУспеха()
    }

    @Test("Отказ после fsync temp сохраняет preimage и не повторяет atomic payload")
    func незавершённыйPayload() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: ["Документация/a.md": "[b](../Документация/b.md)\n", "Документация/b.md": "# B\n", "dokumentaciya/keep.md": "# Сохранить\n"])
        let пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск, неисправность: { фаза, _ in
            if фаза == "после-payload-fsync" { throw ОтказСистемнойФикстурыДокументации.намеренный }
        })
        #expect(итог.исход == .неизвестно)
        #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent("dokumentaciya/a.md")) == Data("[b](../Документация/b.md)\n".utf8))
        #expect(try FileManager.default.contentsOfDirectory(atPath: фикстура.корень.appendingPathComponent("dokumentaciya").path).contains { $0.hasSuffix(".tmp") })
        #expect(try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск).исход == .удержано)
    }

    @Test("Gitignore *.tmp не препятствует проверенному собственному atomic payload")
    func игнорируемыйСобственныйВременныйФайл() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: [
            ".gitignore": "*.tmp\n", "Документация/a.md": "[b](../Документация/b.md)\n",
            "Документация/b.md": "# B\n", "dokumentaciya/keep.md": "# Сохранить\n"
        ])
        let пакет = try фикстура.пакет(), корень = фикстура.корень
        #expect(пакет.план.шаги.contains { $0.действие == .заменитьБайты && $0.целевой == "dokumentaciya/a.md" })
        let префиксИмени = String(хэшПутей(байтыПлана(пакет.план)).prefix(16))
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет), неисправность: { фаза, номер in
            if фаза == "после-payload-fsync" {
                let путь = "dokumentaciya/.fum-p4-" + префиксИмени + "-\(номер).tmp"
                #expect(try ПримитивыДокументации.текстГит(корень, ["check-ignore", "--", путь]) == путь)
                let видимые = try ПримитивыДокументации.гит(корень, ["ls-files", "--others", "--exclude-standard", "-z"])
                #expect(!видимые.split(separator: 0).contains { Data($0) == Data(путь.utf8) })
            }
        })
        #expect(итог.исход == .завершено && итог.подтверждённыйПрефикс == пакет.план.шаги.count)
        #expect(try Data(contentsOf: корень.appendingPathComponent("dokumentaciya/a.md")) == Data("[b](b.md)\n".utf8))
        #expect(try !FileManager.default.contentsOfDirectory(atPath: корень.appendingPathComponent("dokumentaciya").path).contains { $0.hasSuffix(".tmp") })
        try фикстура.очиститьПослеИзвестногоУспеха()
    }

    @Test("Игнорируемый посторонний файл после temp fsync удерживает payload до rename")
    func игнорируемыйПостороннийВременныйФайл() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: [
            ".gitignore": "*.tmp\n", "Документация/a.md": "[b](../Документация/b.md)\n",
            "Документация/b.md": "# B\n", "dokumentaciya/keep.md": "# Сохранить\n"
        ])
        let пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let посторонний = фикстура.корень.appendingPathComponent("dokumentaciya/foreign.tmp")
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск, неисправность: { фаза, _ in
            if фаза == "после-payload-fsync" { try Data("посторонний файл\n".utf8).write(to: посторонний) }
        })
        #expect(итог.исход == .неизвестно)
        #expect(try Data(contentsOf: фикстура.корень.appendingPathComponent("dokumentaciya/a.md")) == Data("[b](../Документация/b.md)\n".utf8))
        #expect(try Data(contentsOf: посторонний) == Data("посторонний файл\n".utf8))
        let повтор = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: допуск)
        #expect(повтор.исход == .удержано && повтор.подтверждённыйПрефикс == итог.подтверждённыйПрефикс)
    }

    @Test("Cleanup после durable receipt возвращает UNKNOWN с фактическим новым prefix")
    func отказОчисткиПослеReceipt() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет()
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет), неисправность: { фаза, _ in
            if фаза == "до-очистки-резервов" { throw ОтказСистемнойФикстурыДокументации.намеренный }
        })
        #expect(итог.исход == .неизвестно && итог.подтверждённыйПрефикс == 1)
        let повтор = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет))
        #expect(повтор.исход == .удержано && повтор.подтверждённыйПрефикс == 1)
        #expect(повтор.причина == "сохранённый-префикс-без-terminal-не-продолжен")
    }

    @Test("Чужой untracked drift вне Docs закрывает namespace до MOVE")
    func внешнийДрейфПространства() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет()
        try фикстура.записать("extra.md", "новая чужая цель\n")
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет))
        #expect(итог.исход == .неизвестно && итог.подтверждённыйПрефикс == 0)
        #expect(try ПримитивыДокументации.есть(фикстура.корень.appendingPathComponent("Документация/a.md")))
        #expect(try !ПримитивыДокументации.есть(фикстура.корень.appendingPathComponent("dokumentaciya/a.md")))
    }

    @Test("Чужой index.lock не принимается как свободный исходный snapshot")
    func дрейфИЗамокИндекса() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет()
        let замок = URL(fileURLWithPath: пакет.каталогGit).appendingPathComponent("index.lock")
        try Data("другой writer".utf8).write(to: замок)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет))
        #expect(итог.исход == .неизвестно && итог.подтверждённыйПрефикс == 0)
        #expect(try Data(contentsOf: замок) == Data("другой writer".utf8))
    }

    @Test("Физический mode индекса закреплён отдельно от неизменного logical ls-files")
    func физическийРежимИндекса() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет()
        let адрес = URL(fileURLWithPath: пакет.каталогGit).appendingPathComponent("index")
        let логическийДо = try ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"])
        let другойРежим: UInt32 = пакет.режимИндекса == 0o600 ? 0o644 : 0o600
        try FileManager.default.setAttributes([.posixPermissions: Int(другойРежим)], ofItemAtPath: адрес.path)
        let итог = try ПакетноеОбъединениеДокументации.применить(пакет, допуск: фикстура.допуск(пакет))
        #expect(итог.исход == .неизвестно && итог.подтверждённыйПрефикс == 0)
        #expect(try ПримитивыДокументации.гит(фикстура.корень, ["ls-files", "--stage", "-z"]) == логическийДо)
        #expect(try ПримитивыДокументации.прочитать(адрес, предел: 67_108_864).1 == другойРежим)
        #expect(try ПримитивыДокументации.есть(фикстура.корень.appendingPathComponent("Документация/a.md")))
    }

    @Test("Runtime внутри checkout и частичный slot отклоняются до записи Segment")
    func границаRuntimeИЧастичныйСлот() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет()
        let внутри = фикстура.корень.appendingPathComponent("private-runtime")
        try FileManager.default.createDirectory(at: внутри, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        var допуск = try фикстура.допуск(пакет); допуск.кореньХранилища = внутри.path
        let журнал = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        #expect(throws: (any Error).self) { try журнал.открыть(план: байтыПлана(пакет.план)) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: внутри.path).isEmpty)
        допуск.кореньХранилища = фикстура.хранилище.path
        let частичный = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        try FileManager.default.createDirectory(at: частичный.каталогСлота, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        #expect(throws: (any Error).self) { try частичный.открыть(план: байтыПлана(пакет.план)) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: частичный.каталогСлота.path).isEmpty)
    }

    @Test("Failed fsync Segment не превращает видимый пакет в разрешение повтора")
    func ошибкаСинхронизацииSegment() throws {
        let фикстура = try СистемнаяФикстураДокументации(), пакет = try фикстура.пакет(), допуск = try фикстура.допуск(пакет)
        let счётчик = СчётчикСистемнойФикстурыДокументации()
        let штатная = ФайловыеОперацииЖурналаДокументации.системные.синхронизация
        var операции = ФайловыеОперацииЖурналаДокументации.системные
        операции.синхронизация = { дескриптор in
            if счётчик.следующий() == 3 { throw ОтказСистемнойФикстурыДокументации.намеренный }
            try штатная(дескриптор)
        }
        let журнал = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск, операции: операции)
        #expect(throws: (any Error).self) { try журнал.открыть(план: байтыПлана(пакет.план)) }
        журнал.закрыть()
        let новый = try СегментныйЖурналДокументации(пакет: пакет, допуск: допуск)
        switch try новый.открыть(план: байтыПлана(пакет.план)) {
        case .удержанныйПрефикс(let известный, let намерение): #expect(известный == 0 && намерение == nil)
        default: Issue.record("Видимый пакет без terminal не даёт новый запуск")
        }
        новый.закрыть()
    }

    @Test("Ёмкость ограничена до эффектов; Int.max не переполняет расчёт")
    func пределыЖурнала() throws {
        try СегментныйЖурналДокументации.проверитьЁмкость(байтПакета: 1024, шагов: 1024)
        for число in [1025, Int.max] {
            #expect(throws: (any Error).self) { try СегментныйЖурналДокументации.проверитьЁмкость(байтПакета: 1024, шагов: число) }
        }
        #expect(throws: (any Error).self) { try СегментныйЖурналДокументации.проверитьЁмкость(байтПакета: Int.max, шагов: 1) }
    }

    @Test("Proof является gate: нельзя убрать свидетельство accepted Markdown copy")
    func обязательностьДоказательстваКопии() throws {
        let фикстура = try СистемнаяФикстураДокументации(файлы: ["Документация/01.md": "# Копия\n", "dokumentaciya/01.md": "# Копия\n"])
        var пакет = try фикстура.пакет(); #expect(пакет.доказательстваКопий.count == 1)
        пакет.доказательстваКопий.removeAll()
        #expect(throws: (any Error).self) { try СистемныеЭффектыДокументации(пакет: пакет, допуск: фикстура.допуск(пакет)) }
    }
}
