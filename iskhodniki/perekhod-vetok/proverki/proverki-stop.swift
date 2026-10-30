import Foundation
import Darwin
import Testing
import FUMStructuringOperatorMemory
@testable import МатериализацияУзлов

private let задачаStop = "00000000-0000-4000-8000-000000000479"
private let рабочийКаталогStop = "/tmp/fum-stop-tests"
private let узелStop = "fum-lab/fum/master"

private func обычныеУсловияStop() -> УсловияСамостоятельности {
    УсловияСамостоятельности(свояОбласть: true, естьПолномочия: true,
        неизвестныйОпасныйЭффект: false, естьНакопленноеПродвижение: true,
        можноБезопасноПродолжать: true, доступнаНезависимаяРабота: true,
        локальнаяИсправимаяПроблема: false, остановкаЗадачи: false,
        естьБезопасныйСледующийШаг: true)
}

private func событиеStop(задача: String = задачаStop, cwd: String = рабочийКаталогStop) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "session_id": задача,
        "hook_event_name": "Stop",
        "cwd": cwd,
        "turn_id": "ход-1",
        "stop_hook_active": false
    ], options: [.sortedKeys])
}

private func наблюденияStop(_ условия: УсловияСамостоятельности,
                            следующаяРабота: String = "продолжить независимый срез") throws -> Data {
    try JSONEncoder().encode(НаблюденияStop(задача: задачаStop, узел: узелStop,
        следующаяРабота: следующаяРабота, условия: условия))
}

private func объектОтвета(_ данные: Data) throws -> [String: Any] {
    try #require(данные.last == 0x0a)
    return try #require(try JSONSerialization.jsonObject(with: данные) as? [String: Any])
}

@Suite("FUMA Stop: приоритет и независимое продолжение")
struct ПроверкиStop {
    @Test("Неизвестный эффект A не запрещает доказанную независимую работу B")
    func неизвестныйЭффектСохраняетНезависимоеПродолжение() throws {
        var условия = обычныеУсловияStop()
        условия.неизвестныйОпасныйЭффект = true
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(условия) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect((ответ["reason"] as? String)?.contains("неизвестный опасный эффект") == true)
        #expect((ответ["reason"] as? String)?.contains("независим") == true)
    }

    @Test("Явный STOP человека выше неизвестного эффекта и независимой работы")
    func остановкаЧеловекаИмеетПриоритет() throws {
        var условия = обычныеУсловияStop()
        условия.неизвестныйОпасныйЭффект = true
        условия.остановкаЗадачи = true
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(условия, следующаяРабота: "") },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["continue"] as? Bool == false)
        #expect((ответ["stopReason"] as? String)?.contains("остановлена пользователем") == true)
        #expect(ответ["decision"] == nil)
    }

    @Test("Ошибка argv не принимает идентичность из native события")
    func ошибкаПараметровСохраняетГраницуЗадачи() throws {
        let чужаяЗадача = "00000000-0000-4000-8000-000000000480"
        let аргументы = ["--codex-thread-id", задачаStop, "--неизвестный-флаг", "значение"]
        let чужой = try объектОтвета(КомандаStop.выполнить(аргументы,
            ввод: try событиеStop(задача: чужаяЗадача)))
        #expect(чужой.isEmpty)

        let целевой = try объектОтвета(КомандаStop.выполнить(аргументы,
            ввод: try событиеStop()))
        #expect(целевой["decision"] as? String == "block")
        #expect(целевой["continue"] == nil)
        #expect((целевой["reason"] as? String)?.contains("неверный целевой вход") == true)

        let неоднозначный = try объектОтвета(КомандаStop.выполнить(
            ["--codex-thread-id", задачаStop, "--codex-thread-id", чужаяЗадача],
            ввод: try событиеStop()))
        #expect(неоднозначный["systemMessage"] != nil)
    }

    @Test("Безопасная доступная работа блокирует преждевременный final")
    func доступнаяРаботаБлокируетFinal() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect((ответ["reason"] as? String)?.contains("продолжить независимый срез") == true)
    }

    @Test("Чужое событие не читает локальные наблюдения")
    func чужоеСобытиеНеЧитаетНаблюдения() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(задача: "00000000-0000-4000-8000-000000000480"),
            наблюдения: { throw CocoaError(.fileNoSuchFile) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ.isEmpty)
    }

    @Test("Ошибка целевых наблюдений остаётся fail-closed")
    func ошибкаНаблюденийНеОткрываетFinal() throws {
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { Data("{".utf8) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
        #expect(ответ.isEmpty == false)
    }

    @Test("Повторное поле native Stop и наблюдений отклоняется")
    func повторныеПоляОтклоняются() throws {
        let повторСобытия = Data("""
        {"session_id":"\(задачаStop)","session_id":"\(задачаStop)","hook_event_name":"Stop","cwd":"\(рабочийКаталогStop)","turn_id":"ход-1","stop_hook_active":false}
        """.utf8)
        let ответСобытия = try объектОтвета(ОбработчикStop.ответ(
            событие: повторСобытия,
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответСобытия["systemMessage"] != nil)

        let корректные = try наблюденияStop(обычныеУсловияStop())
        let текст = try #require(String(data: корректные, encoding: .utf8))
        let повторНаблюдений = Data(текст.replacingOccurrences(
            of: "\"остановкаЗадачи\":false",
            with: "\"остановкаЗадачи\":false,\"остановкаЗадачи\":true").utf8)
        let ответНаблюдений = try объектОтвета(ОбработчикStop.ответ(
            событие: try событиеStop(),
            наблюдения: { повторНаблюдений },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответНаблюдений["decision"] as? String == "block")
        #expect(ответНаблюдений.isEmpty == false)
    }

    @Test("Дополнительное дробное native-поле не меняет решение")
    func полныйСинтаксисЧислаВДополнительномПоле() throws {
        let событие = Data("""
        {"session_id":"\(задачаStop)","hook_event_name":"Stop","cwd":"\(рабочийКаталогStop)","turn_id":"ход-1","stop_hook_active":false,"native_metric":1.25e+3}
        """.utf8)
        let ответ = try объектОтвета(ОбработчикStop.ответ(
            событие: событие,
            наблюдения: { try наблюденияStop(обычныеУсловияStop()) },
            ожидаемаяЗадача: задачаStop,
            ожидаемыйУзел: узелStop,
            ожидаемыйРабочийКаталог: рабочийКаталогStop))
        #expect(ответ["decision"] as? String == "block")
    }

    @Test("Приватный обычный файл наблюдений читается без следования ссылкам")
    func обычныйФайлНаблюдений() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        let данные = try наблюденияStop(обычныеУсловияStop())
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)
        #expect(try КомандаStop.прочитатьОбычныйФайл(путь.path) == данные)

        try FileManager.default.setAttributes([.posixPermissions: 0o644],
            ofItemAtPath: путь.path)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(путь.path)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        let жёсткаяСсылка = корень.appendingPathComponent("hardlink.json")
        try FileManager.default.linkItem(at: путь, to: жёсткаяСсылка)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(путь.path)
        }
        try FileManager.default.removeItem(at: жёсткаяСсылка)

        let символическаяСсылка = корень.appendingPathComponent("symlink.json")
        try FileManager.default.createSymbolicLink(at: символическаяСсылка,
            withDestinationURL: путь)
        #expect(throws: ОтказКомандыStop.self) {
            try КомандаStop.прочитатьОбычныйФайл(символическаяСсылка.path)
        }
    }

    @Test("Рост файла после предварительной проверки ограничивает чтение")
    func ростПослеПредварительнойПроверкиОграничен() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-growth-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        try Data([0x7b]).write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        var контрольныйДескриптор: Int32 = -1
        defer {
            if контрольныйДескриптор >= 0 {
                _ = Darwin.close(контрольныйДескриптор)
            }
        }
        #expect(throws: ОтказКомандыStop.превышенПределСостояния) {
            try КомандаStop.прочитатьОбычныйФайл(
                путь.path,
                послеПредварительнойПроверки: { дескриптор in
                    контрольныйДескриптор = Darwin.dup(дескриптор)
                    guard контрольныйДескриптор >= 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                    let писатель = Darwin.open(путь.path, O_WRONLY | O_CLOEXEC)
                    guard писатель >= 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                    defer { _ = Darwin.close(писатель) }
                    guard Darwin.ftruncate(писатель, 131_072) == 0 else {
                        throw ОтказКомандыStop.открытиеСостояния
                    }
                }
            )
        }
        #expect(Darwin.lseek(контрольныйДескриптор, 0, SEEK_CUR) == 65_537)
    }

    @Test("Файл ровно на границе 65 536 байт принимается")
    func файлНаГраницеПринимается() throws {
        let корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("fum-stop-limit-\(UUID().uuidString.lowercased())")
        try FileManager.default.createDirectory(at: корень,
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: корень) }
        let путь = корень.appendingPathComponent("state.json")
        let данные = Data(repeating: 0x20, count: 65_536)
        try данные.write(to: путь, options: [.withoutOverwriting])
        try FileManager.default.setAttributes([.posixPermissions: 0o600],
            ofItemAtPath: путь.path)

        #expect(try КомандаStop.прочитатьОбычныйФайл(путь.path) == данные)
    }
}

@Suite("Профиль Stop")
struct ПрофильStop {
    private struct РезультатПрофиля: Encodable {
        let схема = "fum.профиль-stop.1"
        let повторовВРаунде: Int
        let строгийJSONНаносекундыНаВызов: [UInt64]
        let полныйОтветНаносекундыНаВызов: [UInt64]
        let медианаСтрогогоJSON: UInt64
        let медианаПолногоОтвета: UInt64
    }

    @Test("Строгий JSON и полный FUMA-ответ измеряются раздельно")
    func измерить() throws {
        let повторов = 200
        let раундов = 5
        let событие = try событиеStop()
        let наблюдения = try наблюденияStop(обычныеУсловияStop())
        let часы = ContinuousClock()
        var json: [UInt64] = []
        var ответы: [UInt64] = []

        for _ in 0..<раундов {
            var начало = часы.now
            for _ in 0..<повторов {
                try ЗакрытыйJSON.проверить(событие)
                try ЗакрытыйJSON.проверить(наблюдения)
            }
            json.append(наносекунды(начало.duration(to: часы.now)) / UInt64(повторов))

            начало = часы.now
            for _ in 0..<повторов {
                let ответ = ОбработчикStop.ответ(событие: событие,
                    наблюдения: { наблюдения }, ожидаемаяЗадача: задачаStop,
                    ожидаемыйУзел: узелStop,
                    ожидаемыйРабочийКаталог: рабочийКаталогStop)
                #expect(ответ.last == 0x0a)
            }
            ответы.append(наносекунды(начало.duration(to: часы.now)) / UInt64(повторов))
        }

        let результат = РезультатПрофиля(повторовВРаунде: повторов,
            строгийJSONНаносекундыНаВызов: json,
            полныйОтветНаносекундыНаВызов: ответы,
            медианаСтрогогоJSON: json.sorted()[раундов / 2],
            медианаПолногоОтвета: ответы.sorted()[раундов / 2])
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(результат)
        данные.append(0x0a)
        if let путь = ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_STOP"] {
            try данные.write(to: URL(fileURLWithPath: путь), options: [.withoutOverwriting])
        }
        print(String(decoding: данные, as: UTF8.self), terminator: "")
    }

    private func наносекунды(_ длительность: Duration) -> UInt64 {
        let части = длительность.components
        return UInt64(части.seconds) * 1_000_000_000
            + UInt64(части.attoseconds / 1_000_000_000)
    }
}
