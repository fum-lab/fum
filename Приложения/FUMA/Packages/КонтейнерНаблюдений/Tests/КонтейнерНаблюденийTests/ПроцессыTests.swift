import Foundation
import Darwin
import Testing
@testable import КонтейнерНаблюдений

struct ПроцессыTests {
    @Test func полноеОписаниеСохраняетсяИПовторНеМеняетБайты() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("ответ.json")
        let описание = путь.appendingPathComponent("описание.json")
        let данные = Data("{\"полный\":\"доступный MCP-объект\"}".utf8)
        try данные.write(to: вход)
        let метаданные = ОписаниеНаблюдения(идентификатор: "цикл-1-задача-1", тип: "codex-read_thread",
            версияСхемы: 1, источник: "mcp__codex_app__read_thread",
            время: "2026-10-08T20:30:00Z", спецификация: Data([0, 255, 10, 128]))
        try JSONEncoder().encode(метаданные).write(to: описание)
        let аргументы = ["добавить-описание", путь.path, описание.path, вход.path]
        let первый = try выполнить("писатель-контейнера", аргументы)
        try #require(первый.0 == 0)
        let квитанция = try JSONDecoder().decode(Квитанция.self, from: первый.1)
        #expect(квитанция.описание == метаданные)
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let до = try Data(contentsOf: файл)
        #expect(try выполнить("писатель-контейнера", аргументы).0 == 0)
        #expect(try Data(contentsOf: файл) == до)
        #expect(try выполнить("читатель-контейнера", ["извлечь", путь.path, метаданные.идентификатор]).1 == данные)
        let читатель = try Сегмент(кореньДанных: путь, запись: false)
        defer { читатель.закрыть() }
        #expect(читатель.записи.count == 1)
        #expect(читатель.записи.first?.описание == метаданные)
        читатель.закрыть()
        let другое = ОписаниеНаблюдения(идентификатор: метаданные.идентификатор, тип: метаданные.тип,
            источник: "изменённый источник", время: метаданные.время, спецификация: метаданные.спецификация)
        try JSONEncoder().encode(другое).write(to: описание)
        #expect(try выполнить("писатель-контейнера", аргументы).0 != 0)
        try JSONEncoder().encode(метаданные).write(to: описание)
        try Data([99]).write(to: вход)
        #expect(try выполнить("писатель-контейнера", аргументы).0 != 0)
        #expect(try Data(contentsOf: файл) == до)
    }

    @Test func полноеОписаниеЗакрытоОтвергаетПовторыИНеизвестныеПоляДоЗаписи() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("ответ.bin")
        let описание = путь.appendingPathComponent("описание.json")
        try Data([1, 2, 3]).write(to: вход)
        let основа = "\"идентификатор\":\"один\",\"тип\":\"codex-read_thread\",\"версияСхемы\":1,\"источник\":\"MCP\",\"время\":\"2026-10-08T20:30:00Z\",\"спецификация\":\"eA==\""
        for плохое in ["{\(основа),\"лишнее\":1}", "{\(основа),\"тип\":\"другой\"}",
                       "{\(основа),\"\\u0442\\u0438\\u043f\":\"другой\"}", "{\"идентификатор\":\"один\"}",
                       "{\(основа.replacingOccurrences(of: "eA==", with: "!не-base64!"))}"] {
            try Data(плохое.utf8).write(to: описание)
            let ответ = try выполнить("писатель-контейнера", ["добавить-описание", путь.path, описание.path, вход.path])
            #expect(ответ.0 != 0); #expect(ответ.1.isEmpty)
            #expect(!FileManager.default.fileExists(atPath: путь.appendingPathComponent("сегмент.fumobs").path))
        }
        let хорошее = try #require(JSONSerialization.jsonObject(with: Data("{\(основа)}".utf8)) as? [String: Any])
        for поле in хорошее.keys.sorted() {
            for неверное in [NSNull(), false, 1.5] as [Any] {
                var вариант = хорошее
                вариант[поле] = неверное
                try JSONSerialization.data(withJSONObject: вариант).write(to: описание)
                #expect(try выполнить("писатель-контейнера", ["добавить-описание", путь.path, описание.path, вход.path]).0 != 0)
            }
            var неполное = хорошее
            неполное.removeValue(forKey: поле)
            try JSONSerialization.data(withJSONObject: неполное).write(to: описание)
            #expect(try выполнить("писатель-контейнера", ["добавить-описание", путь.path, описание.path, вход.path]).0 != 0)
        }
        for число in ["0", "-1", "1.0", "true", "01", "1e0"] {
            let плохое = основа.replacingOccurrences(of: "\"версияСхемы\":1", with: "\"версияСхемы\":\(число)")
            try Data("{\(плохое)}".utf8).write(to: описание)
            #expect(try выполнить("писатель-контейнера", ["добавить-описание", путь.path, описание.path, вход.path]).0 != 0)
        }
        #expect(!FileManager.default.fileExists(atPath: путь.appendingPathComponent("сегмент.fumobs").path))
    }

    @Test func полныйОтветРовно64МиБИзвлекаетсяБезУсеченияАПревышениеНеПишется() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("граница.bin"), описание = путь.appendingPathComponent("описание.json")
        let данные = Data(repeating: 0xD1, count: 67_108_864)
        try данные.write(to: вход)
        let метаданные = ОписаниеНаблюдения(идентификатор: "граница", тип: "полные байты",
            источник: "синтетический тест", время: "2026-10-08T20:30:00Z", спецификация: Data([0, 255]))
        try JSONEncoder().encode(метаданные).write(to: описание)
        let аргументы = ["добавить-описание", путь.path, описание.path, вход.path]
        let запись = try выполнить("писатель-контейнера", аргументы, таймаут: 60)
        try #require(запись.0 == 0)
        #expect(try JSONDecoder().decode(Квитанция.self, from: запись.1).размер == 67_108_864)
        let чтение = try выполнить("читатель-контейнера", ["извлечь", путь.path, "граница"], таймаут: 60)
        #expect(чтение.0 == 0); #expect(чтение.1 == данные)
        let сегмент = путь.appendingPathComponent("сегмент.fumobs"), до = try Data(contentsOf: сегмент)
        let поток = try FileHandle(forWritingTo: вход)
        try поток.seekToEnd(); try поток.write(contentsOf: Data([1])); try поток.close()
        #expect(try выполнить("писатель-контейнера", аргументы, таймаут: 60).0 != 0)
        #expect(try Data(contentsOf: сегмент) == до)
    }

    private func каталогИсполняемыхФайлов() -> URL {
        if let путь = ProcessInfo.processInfo.environment["FUM_TEST_BIN_DIR"], !путь.isEmpty {
            return URL(fileURLWithPath: путь, isDirectory: true)
        }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/debug")
    }

    func команда(_ имя: String, _ аргументы: [String]) -> Process {
        let каталог = каталогИсполняемыхФайлов()
        let процесс = Process()
        процесс.executableURL = каталог.appendingPathComponent(имя)
        процесс.arguments = аргументы
        return процесс
    }

    func выполнить(_ имя: String, _ аргументы: [String], таймаут: Double = 5) throws -> (Int32, Data) {
        let процесс = команда(имя, аргументы)
        let каталог = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: каталог) }
        let файл = каталог.appendingPathComponent("вывод"), файлОшибок = каталог.appendingPathComponent("ошибки")
        try Data().write(to: файл); try Data().write(to: файлОшибок)
        let вывод = try FileHandle(forWritingTo: файл), ошибки = try FileHandle(forWritingTo: файлОшибок)
        defer { try? вывод.close(); try? ошибки.close() }
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        let завершён = DispatchSemaphore(value: 0)
        процесс.terminationHandler = { _ in завершён.signal() }
        try процесс.run()
        if завершён.wait(timeout: .now() + таймаут) == .timedOut {
            kill(процесс.processIdentifier, SIGKILL)
            процесс.waitUntilExit()
            throw ОшибкаКонтейнера.система(ETIMEDOUT)
        }
        return (процесс.terminationStatus, try Data(contentsOf: файл))
    }

    @Test func восстановительНеСоздаётОтсутствующийСегмент() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let ответ = try выполнить("восстановитель-контейнера", [путь.path])
        #expect(ответ.0 != 0); #expect(ответ.1.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: путь.appendingPathComponent("сегмент.fumobs").path))
    }

    @Test func замокКорняПредшествуетСозданиюСегмента() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let каталог = try открытьКорень(путь)
        defer { _ = Darwin.close(каталог) }
        try #require(flock(каталог, LOCK_EX | LOCK_NB) == 0)
        let вход = путь.appendingPathComponent("синтетика.bin")
        try Data([7]).write(to: вход)
        let отказ = try выполнить("писатель-контейнера", ["добавить", путь.path, "первый", "байты", вход.path])
        #expect(отказ.0 != 0); #expect(отказ.1.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: путь.appendingPathComponent("сегмент.fumobs").path))
        try #require(flock(каталог, LOCK_UN) == 0)
        #expect(try выполнить("писатель-контейнера", ["добавить", путь.path, "первый", "байты", вход.path]).0 == 0)
    }

    @Test func дваПроцессаЗамокИВосстановлениеПослеУбийства() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let вход = путь.appendingPathComponent("синтетика.bin")
        try Data([42]).write(to: вход)
        let владелец = команда("писатель-контейнера", ["удерживать", путь.path])
        let барьер = Pipe(), вывод = Pipe()
        владелец.standardInput = барьер; владелец.standardOutput = вывод
        try владелец.run()
        defer {
            if владелец.isRunning { kill(владелец.processIdentifier, SIGKILL); владелец.waitUntilExit() }
        }
        var ожидание = pollfd(fd: вывод.fileHandleForReading.fileDescriptor, events: Int16(POLLIN), revents: 0)
        try #require(poll(&ожидание, 1, 5000) == 1)
        var буфер = [UInt8](repeating: 0, count: 1024)
        let прочитано = Darwin.read(вывод.fileHandleForReading.fileDescriptor, &буфер, буфер.count)
        try #require(прочитано > 0)
        let готов = Data(буфер.prefix(прочитано))
        #expect(String(decoding: готов, as: UTF8.self).contains("замок-удерживается"))
        let до = try Data(contentsOf: путь.appendingPathComponent("сегмент.fumobs"))
        let второй = try выполнить("писатель-контейнера", ["добавить", путь.path, "один", "байты", вход.path])
        #expect(второй.0 != 0); #expect(второй.1.isEmpty)
        #expect(try выполнить("восстановитель-контейнера", [путь.path]).0 != 0)
        #expect(try выполнить("читатель-контейнера", ["извлечь", путь.path, "один"]).0 != 0)
        #expect(try Data(contentsOf: путь.appendingPathComponent("сегмент.fumobs")) == до)
        #expect(kill(владелец.processIdentifier, SIGKILL) == 0)
        владелец.waitUntilExit()
        #expect(try выполнить("восстановитель-контейнера", [путь.path]).0 == 0)
        #expect(try выполнить("писатель-контейнера", ["добавить", путь.path, "один", "байты", вход.path]).0 == 0)
        let после = try Data(contentsOf: путь.appendingPathComponent("сегмент.fumobs"))
        #expect(try выполнить("писатель-контейнера", ["добавить", путь.path, "один", "байты", вход.path]).0 == 0)
        #expect(try Data(contentsOf: путь.appendingPathComponent("сегмент.fumobs")) == после)
        #expect(try выполнить("читатель-контейнера", ["извлечь", путь.path, "один"]).1 == Data([42]))
    }

    @Test func полныеDataКадрыБезCommitВосстанавливаютсяДругимПроцессом() throws {
        let путь = try СегментTests().корень()
        defer { try? FileManager.default.removeItem(at: путь) }
        let писатель = try Сегмент(кореньДанных: путь, запись: true)
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "до", тип: "байты"), данные: Data([1]))
        let файл = путь.appendingPathComponent("сегмент.fumobs")
        let префикс = try Data(contentsOf: файл)
        _ = try писатель.добавить(ОписаниеНаблюдения(идентификатор: "хвост", тип: "байты"), данные: Data([2]))
        писатель.закрыть()
        let полные = try Data(contentsOf: файл)
        var позиция = префикс.count
        for _ in 0..<2 {
            позиция += 88 + Int(число(полные, позиция + 8, 4)) + Int(число(полные, позиция + 12, 4))
        }
        try полные.prefix(позиция).write(to: файл)
        let читатель = try Сегмент(кореньДанных: путь, запись: false)
        #expect(читатель.естьХвост); #expect(читатель.записи.count == 1)
        читатель.закрыть()
        #expect(try выполнить("восстановитель-контейнера", [путь.path]).0 == 0)
        #expect(try Data(contentsOf: файл) == префикс)
        #expect(try выполнить("восстановитель-контейнера", [путь.path]).0 == 0)
        #expect(try Data(contentsOf: файл) == префикс)
    }
}
