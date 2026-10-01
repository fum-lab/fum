import Foundation
import Testing
@testable import КлиентTelegram

@Test func профильВосстановленияОтклоняетИзменённоеНаблюдение() async throws {
    for поле in ["content", "sending_state"] {
        let каталог = try создатьПриватныйКаталог()
        defer { try? FileManager.default.removeItem(at: каталог) }
        let корень = каталог.appendingPathComponent("журнал", isDirectory: true)
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let ключ = Data(repeating: 71, count: 32)
        let путьКлюча = каталог.appendingPathComponent("ключ")
        try ключ.write(to: путьКлюча)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: путьКлюча.path)
        _ = try await измеритьВосстановление(каталог: каталог, количество: 16, подготовка: true)
        let исходный = try ЛокальныйЖурнал(корень: корень, ключ: ключ)
        let записи = try исходный.восстановить()
        исходный.закрыть()
        try FileManager.default.removeItem(at: корень)
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let изменённый = try ЛокальныйЖурнал(корень: корень, ключ: ключ)
        var заменено = 0
        for запись in записи {
            if case .наблюдение(let аккаунт, let событие) = запись, заменено == 0 {
                let значение: ЗначениеДанных = поле == "content"
                    ? .типа("messageText", ["text": .типа("formattedText", ["text": .текст("Искажённое сообщение"), "entities": .массив([])])])
                    : .типа("messageSendingStatePending", ["sending_id": .число(999999)])
                try изменённый.добавить(.наблюдение(аккаунт: аккаунт, событие: событие.добавив(поле, значение)))
                заменено += 1
            } else { try изменённый.добавить(запись) }
        }
        изменённый.закрыть()
        #expect(заменено == 1)
        let сегмент = try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs"))
        let путьКвитанции = каталог.appendingPathComponent("квитанция.json")
        let квитанция = try ЗначениеДанных.прочитать(Data(contentsOf: путьКвитанции))
            .добавив("сегментШа256", .текст(отпечаток(сегмент)))
            .добавив("сегментБайтов", .число(Int64(сегмент.count)))
        // Свидетельство исходного сообщения остаётся от подготовки; обновлён только контейнер.
        try квитанция.байты().write(to: путьКвитанции)
        await #expect(throws: ОшибкаКлиента.требуетсяРазбор) {
            _ = try await измеритьВосстановление(каталог: каталог, количество: 16, подготовка: false)
        }
        #expect(try Data(contentsOf: корень.appendingPathComponent("сегмент.fumobs")) == сегмент)
    }
}
