import Foundation
import Testing
import МатериализацияУзлов

@Suite("Команда fuma stop", .serialized)
struct ПроверкиКомандыStop {
    private let задача = "01a17797-519b-73c1-bcc8-fd295cdfe9b0"
    private let узел = "fum-lab/fum/master"

    private func событие(cwd: String, задача: String? = nil) throws -> Data {
        var данные = try JSONSerialization.data(withJSONObject: [
            "session_id": задача ?? self.задача,
            "hook_event_name": "Stop",
            "cwd": cwd,
            "turn_id": "ход-e2e",
            "stop_hook_active": false
        ], options: [.sortedKeys])
        данные.append(0x0a)
        return данные
    }

    private func условия(неизвестный: Bool, остановка: Bool) -> УсловияСамостоятельности {
        УсловияСамостоятельности(свояОбласть: true, естьПолномочия: true,
            неизвестныйОпасныйЭффект: неизвестный, естьНакопленноеПродвижение: true,
            можноБезопасноПродолжать: true, доступнаНезависимаяРабота: true,
            локальнаяИсправимаяПроблема: false, остановкаЗадачи: остановка,
            естьБезопасныйСледующийШаг: true)
    }

    private func сохранитьНаблюдения(_ наблюдения: НаблюденияStop, в путь: URL) throws {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(наблюдения)
        данные.append(0x0a)
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)
    }

    private func аргументы(cwd: String, состояние: URL) -> [String] {
        ["stop", "--идентификатор-обработчика", "fum.stop-handler.1",
         "--codex-thread-id", задача, "--идентификатор-узла", узел,
         "--ожидаемый-cwd", cwd,
         "--состояние", состояние.path]
    }

    @Test("Реальный binary различает unknown+independent и human STOP без Python/PATH")
    func процессныйКонтракт() async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let пустойPATH = среда.корень.appendingPathComponent("empty-path")
        try FileManager.default.createDirectory(at: пустойPATH,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let окружение = ["PATH": пустойPATH.path]

        let неизвестность = среда.корень.appendingPathComponent("unknown.json")
        try сохранитьНаблюдения(НаблюденияStop(задача: задача, узел: узел,
            следующаяРабота: "выполнить независимую работу B",
            условия: условия(неизвестный: true, остановка: false)), в: неизвестность)
        let первый = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: неизвестность),
            ввод: try событие(cwd: среда.корень.path), окружение: окружение)
        #expect(первый.код == 0)
        #expect(первый.ошибки.isEmpty)
        let первыйОтвет = try #require(try JSONSerialization.jsonObject(with: первый.вывод) as? [String: Any])
        #expect(первыйОтвет["decision"] as? String == "block")
        #expect((первыйОтвет["reason"] as? String)?.contains("неизвестный опасный эффект") == true)
        #expect((первыйОтвет["reason"] as? String)?.contains("работу B") == true)

        let остановка = среда.корень.appendingPathComponent("stop.json")
        try сохранитьНаблюдения(НаблюденияStop(задача: задача, узел: узел,
            следующаяРабота: "не должна исполняться",
            условия: условия(неизвестный: true, остановка: true)), в: остановка)
        let второй = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: остановка),
            ввод: try событие(cwd: среда.корень.path), окружение: окружение)
        #expect(второй.код == 0)
        #expect(второй.ошибки.isEmpty)
        let второйОтвет = try #require(try JSONSerialization.jsonObject(with: второй.вывод) as? [String: Any])
        #expect(второйОтвет["continue"] as? Bool == false)
        #expect((второйОтвет["stopReason"] as? String)?.contains("остановлена пользователем") == true)

        let отсутствует = среда.корень.appendingPathComponent("missing.json")
        let чужой = try await процессы.запустить(
            аргументы(cwd: среда.корень.path, состояние: отсутствует),
            ввод: try событие(cwd: среда.корень.path,
                задача: "01a17797-519b-73c1-bcc8-fd295cdfe9b9"), окружение: окружение)
        #expect(чужой.код == 0)
        #expect(чужой.вывод == Data("{}\n".utf8))
        #expect(чужой.ошибки.isEmpty)
        #expect(первый.процесс != второй.процесс)
        #expect(второй.процесс != чужой.процесс)
        _ = try await процессы.проверенныйХэш()
    }
}
