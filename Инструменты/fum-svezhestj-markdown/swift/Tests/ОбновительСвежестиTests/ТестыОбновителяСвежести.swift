import Foundation
import Testing
@testable import ОбновительСвежести

struct ТестыОбновителяСвежести {
    @Test
    func адресноМеняетТолькоВыбранныйФайлИПовторНеМеняетБайты() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }

        let выбранный = корень.appendingPathComponent("выбранный.md")
        let соседний = корень.appendingPathComponent("соседний.md")
        try Data("# Исходник\n".utf8).write(to: выбранный)
        let исходныйСосед = Data("# Не менять\n".utf8)
        try исходныйСосед.write(to: соседний)

        let первое = try ОбновительСвежести.обновить(
            корень: корень,
            относительныйПуть: "выбранный.md",
            меткаВремени: "2026-10-29 00:00:00 MSK"
        )
        let первыеБайты = try Data(contentsOf: выбранный)
        let второе = try ОбновительСвежести.обновить(
            корень: корень,
            относительныйПуть: "выбранный.md",
            меткаВремени: "2026-10-29 01:00:00 MSK"
        )

        #expect(первое.изменён)
        #expect(!второе.изменён)
        #expect(try Data(contentsOf: выбранный) == первыеБайты)
        #expect(try Data(contentsOf: соседний) == исходныйСосед)
        #expect(String(decoding: первыеБайты, as: UTF8.self).contains("2026-10-29 00:00:00 MSK"))
    }

    @Test
    func изменениеТолькоБлокаЗапусковНеСдвигаетСвежестьОтчёта() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }

        let каталог = корень.appendingPathComponent("Журнал/сессия", isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
        let отчёт = каталог.appendingPathComponent("отчёт.md")
        let исходный = """
        # Отчёт

        <!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->
        запуск один
        <!-- FUM-CHECK-RUNS:END -->
        """ + "\n"
        try Data(исходный.utf8).write(to: отчёт)

        _ = try ОбновительСвежести.обновить(
            корень: корень,
            относительныйПуть: "Журнал/сессия/отчёт.md",
            меткаВремени: "2026-10-29 00:00:00 MSK"
        )
        let послеПервойЗаписи = String(decoding: try Data(contentsOf: отчёт), as: UTF8.self)
        let изменённыйБлок = послеПервойЗаписи.replacingOccurrences(of: "запуск один", with: "запуск два")
        try Data(изменённыйБлок.utf8).write(to: отчёт)

        let результат = try ОбновительСвежести.обновить(
            корень: корень,
            относительныйПуть: "Журнал/сессия/отчёт.md",
            меткаВремени: "2026-10-29 02:00:00 MSK"
        )
        let итог = String(decoding: try Data(contentsOf: отчёт), as: UTF8.self)

        #expect(результат.время == "2026-10-29 00:00:00 MSK")
        #expect(итог.contains("запуск два"))
        #expect(итог.contains("<!-- last-content-edit: 2026-10-29 00:00:00 MSK -->"))
    }

    @Test
    func повреждённыеМеткиИПутьЧерезSymlinkОтклоняютсяБезЗаписи() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }

        let повреждённый = корень.appendingPathComponent("повреждённый.md")
        let исходныеБайты = Data("# Текст\n<!-- FUM-MD-RECENCY:BEGIN -->\n".utf8)
        try исходныеБайты.write(to: повреждённый)
        var отказПовреждения = false
        do {
            _ = try ОбновительСвежести.обновить(
                корень: корень,
                относительныйПуть: "повреждённый.md",
                меткаВремени: "2026-10-29 00:00:00 MSK"
            )
        } catch {
            отказПовреждения = true
        }

        let внешнийКаталог = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: внешнийКаталог) }
        let внешнийФайл = внешнийКаталог.appendingPathComponent("цель.md")
        let исходныйВнешний = Data("# Вне корня\n".utf8)
        try исходныйВнешний.write(to: внешнийФайл)
        try FileManager.default.createSymbolicLink(
            at: корень.appendingPathComponent("ссылка", isDirectory: true),
            withDestinationURL: внешнийКаталог
        )
        try FileManager.default.createSymbolicLink(
            at: корень.appendingPathComponent("файл-ссылка.md"),
            withDestinationURL: внешнийФайл
        )
        var отказСсылкиКаталога = false
        do {
            _ = try ОбновительСвежести.обновить(
                корень: корень,
                относительныйПуть: "ссылка/цель.md",
                меткаВремени: "2026-10-29 00:00:00 MSK"
            )
        } catch {
            отказСсылкиКаталога = true
        }
        var отказСсылкиФайла = false
        do {
            _ = try ОбновительСвежести.обновить(
                корень: корень,
                относительныйПуть: "файл-ссылка.md",
                меткаВремени: "2026-10-29 00:00:00 MSK"
            )
        } catch {
            отказСсылкиФайла = true
        }

        var отказОбхода = false
        do {
            _ = try ОбновительСвежести.обновить(
                корень: корень,
                относительныйПуть: "../цель.md",
                меткаВремени: "2026-10-29 00:00:00 MSK"
            )
        } catch {
            отказОбхода = true
        }

        #expect(отказПовреждения)
        #expect(отказСсылкиКаталога)
        #expect(отказСсылкиФайла)
        #expect(отказОбхода)
        #expect(try Data(contentsOf: повреждённый) == исходныеБайты)
        #expect(try Data(contentsOf: внешнийФайл) == исходныйВнешний)
    }

    @Test
    func повреждённаяПараБлокаЗапусковОтклоняетсяБезЗаписи() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }

        let каталог = корень.appendingPathComponent("Журнал/сессия", isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
        let отчёт = каталог.appendingPathComponent("отчёт.md")
        let исходныеБайты = Data("""
        # Отчёт

        <!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->
        незакрытая пара
        """.utf8)
        try исходныеБайты.write(to: отчёт)

        var отказал = false
        do {
            _ = try ОбновительСвежести.обновить(
                корень: корень,
                относительныйПуть: "Журнал/сессия/отчёт.md",
                меткаВремени: "2026-10-29 00:00:00 MSK"
            )
        } catch {
            отказал = true
        }

        #expect(отказал)
        #expect(try Data(contentsOf: отчёт) == исходныеБайты)
    }

    @Test
    func маркерВнутриКодовойОградыОстаётсяСодержимым() throws {
        let корень = try временныйКорень()
        defer { try? FileManager.default.removeItem(at: корень) }

        let путь = корень.appendingPathComponent("пример.md")
        let исходный = """
        # Пример

        ```markdown
        <!-- FUM-MD-RECENCY:BEGIN -->
        ```
        """ + "\n"
        try Data(исходный.utf8).write(to: путь)

        let результат = try ОбновительСвежести.обновить(
            корень: корень,
            относительныйПуть: "пример.md",
            меткаВремени: "2026-10-29 00:00:00 MSK"
        )
        let итог = String(decoding: try Data(contentsOf: путь), as: UTF8.self)

        #expect(результат.изменён)
        #expect(итог.contains("```markdown\n<!-- FUM-MD-RECENCY:BEGIN -->\n```"))
        #expect(итог.contains("<!-- content-sha256: sha256:"))
    }

    private func временныйКорень() throws -> URL {
        let путь = FileManager.default.temporaryDirectory
            .appendingPathComponent("обновитель-свежести-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: true)
        return путь
    }
}
