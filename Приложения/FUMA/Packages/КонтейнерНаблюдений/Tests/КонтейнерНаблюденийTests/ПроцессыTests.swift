import Foundation
import Darwin
import Testing
@testable import КонтейнерНаблюдений

struct ПроцессыTests {
    func команда(_ имя: String, _ аргументы: [String]) -> Process {
        let каталог = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/debug")
        let процесс = Process()
        процесс.executableURL = каталог.appendingPathComponent(имя)
        процесс.arguments = аргументы
        return процесс
    }

    func выполнить(_ имя: String, _ аргументы: [String]) throws -> (Int32, Data) {
        let процесс = команда(имя, аргументы)
        let вывод = Pipe(), ошибки = Pipe()
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        let завершён = DispatchSemaphore(value: 0)
        процесс.terminationHandler = { _ in завершён.signal() }
        try процесс.run()
        if завершён.wait(timeout: .now() + 5) == .timedOut {
            kill(процесс.processIdentifier, SIGKILL)
            процесс.waitUntilExit()
            throw ОшибкаКонтейнера.система(ETIMEDOUT)
        }
        return (процесс.terminationStatus, вывод.fileHandleForReading.readDataToEndOfFile())
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
