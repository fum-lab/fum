import Foundation
import Testing
import ОсноваЗапуска

struct СовместимостьАрхиваСЗапуском {
    @Test func пакетИмеетОдинИсполняемыйПродукт() throws {
        let путь = try ПроверкиАрхиваКодекса().каталог()
        defer { try? FileManager.default.removeItem(at: путь) }
        let процесс = Process(), вывод = Pipe(), ошибки = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        процесс.arguments = ["swift", "package", "--scratch-path", путь.path, "describe", "--type", "json"]
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        try процесс.run(); процесс.waitUntilExit()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        _ = ошибки.fileHandleForReading.readDataToEndOfFile()
        #expect(процесс.terminationStatus == 0)
        let описание = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        let продукты = try #require(описание["products"] as? [[String: Any]])
        let исполняемые = продукты.filter { ($0["type"] as? [String: Any])?.keys.contains("executable") == true }
        #expect(исполняемые.count == 1)
        #expect(исполняемые.first?["name"] as? String == "fuma")
    }

    @Test func внешнийОтказПослеСохраненияБайтовОстаётсяНеизвестным() throws {
        let путь = try ПроверкиАрхиваКодекса().каталог()
        defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("вход.jsonl"), выход = путь.appendingPathComponent("восстановленный.jsonl")
        let корень = путь.appendingPathComponent("архив"), сессия = UUID().uuidString, поколение = UUID().uuidString
        let данные = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(UUID())\"}}\n".utf8)
        try данные.write(to: вход)
        let процессы = ПроцессыАрхиваКодекса(), программа = try процессы.бинарник()
        let отказ = try процессы.процесс(программа, ["импорт", корень.path, сессия, поколение, вход.path], ожидаемыйКод: 2)
        let ошибка = try #require(отказ["ошибка"] as? [String: Any])
        #expect(ошибка["записьСобытия"] as? String == "исходНеизвестен")
        try FileManager.default.removeItem(at: вход)
        _ = try процессы.процесс(программа, ["восстановить", корень.path, сессия, поколение, выход.path])
        #expect(try Data(contentsOf: выход) == данные)
    }

    @Test func прежнийПустойВходИПомощь() throws {
        guard case .запуск = try ВходКоманды.разобрать([]) else { Issue.record("Изменился пустой вход"); return }
        guard case .помощь = try ВходКоманды.разобрать(["--помощь"]) else { Issue.record("Изменилась помощь"); return }
        guard case .архив(let аргументы) = try ВходКоманды.разобрать(["архив-codex", "импорт"]) else {
            Issue.record("Нет маршрута архива"); return
        }
        #expect(аргументы == ["импорт"])
        let процесс = Process(), вывод = Pipe()
        процесс.executableURL = try ПроцессыАрхиваКодекса().бинарник()
        процесс.arguments = ["--помощь"]; процесс.standardOutput = вывод
        try процесс.run(); процесс.waitUntilExit()
        let текст = String(decoding: вывод.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        #expect(процесс.terminationStatus == 0)
        #expect(текст.hasPrefix("FUMA: локальная принятая история"))
        #expect(текст.contains("swift run") && текст.contains("архив-codex"))
    }
}
