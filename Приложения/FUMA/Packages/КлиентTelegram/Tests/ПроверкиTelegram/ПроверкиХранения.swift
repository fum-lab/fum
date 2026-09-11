import Foundation
import Testing
@testable import КлиентTelegram

@Test func намерениеЗашифрованоПереживаетРестартИНеПовторяетсяСамо() throws {
    let каталог = try создатьПриватныйКаталог()
    defer { try? FileManager.default.removeItem(at: каталог) }
    let ключ = Data(repeating: 7, count: 32)
    let черновик = Черновик(аккаунт: 17, канал: -100001, действие: .текст("Точный приватный текст"), цель: "Открытая синтетика")
    let разрешение = try РазрешениеДействия(черновик: черновик, основание: "Явная синтетическая команда")
    let попытка = Попытка(черновик: черновик, разрешение: разрешение, запрос: .типа("sendMessage"))
    let первый = try ЛокальныйЖурнал(корень: каталог, ключ: ключ)
    try первый.добавить(.черновик(черновик))
    try первый.добавить(.попытка(попытка))
    первый.закрыть()
    let второй = try ЛокальныйЖурнал(корень: каталог, ключ: ключ)
    let записи = try второй.восстановить()
    #expect(записи == [.черновик(черновик), .попытка(попытка)])
    #expect(попытка.послеПерезапуска().состояние == .требуетсяРазбор)
    второй.закрыть()
    let байты = try Data(contentsOf: каталог.appendingPathComponent("сегмент.fumobs"))
    #expect(байты.range(of: Data("Точный приватный текст".utf8)) == nil)
    #expect(throws: (any Error).self) {
        let чужой = try ЛокальныйЖурнал(корень: каталог, ключ: Data(repeating: 8, count: 32))
        defer { чужой.закрыть() }
        _ = try чужой.восстановить()
    }
    let изменённый = Черновик(идентификатор: черновик.идентификатор, аккаунт: 17, канал: -100001, действие: .текст("Другие байты"), цель: черновик.цель)
    #expect(throws: ОшибкаКлиента.self) { try разрешение.проверить(изменённый) }
}

func создатьПриватныйКаталог() throws -> URL {
    let путь = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    guard let физический = realpath(путь.path, nil) else { throw ОшибкаКлиента.неверныеДанные("Недоступен физический каталог фикстуры") }
    defer { free(физический) }
    return URL(fileURLWithPath: String(cString: физический))
}
