import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import КлиентTelegram

@Test(arguments: [false, true]) func подменаКорняВложенийНеПишетПоСимволическойСсылке(обычныйКаталог: Bool) async throws {
    let каталог = try создатьПриватныйКаталог()
    let посторонний = try создатьПриватныйКаталог()
    let сохранённый = каталог.appendingPathExtension("исходный")
    defer {
        try? FileManager.default.removeItem(at: каталог)
        try? FileManager.default.removeItem(at: сохранённый)
        try? FileManager.default.removeItem(at: посторонний)
    }
    let транспорт = ЗаписывающийТранспорт()
    let ядро = try ЯдроКлиента(транспорт: транспорт, корень: каталог, ключ: Data(repeating: 5, count: 32))
    let клиент = try await готовыйКлиент(ядро, транспорт: транспорт)
    let черновик = Черновик(аккаунт: 17, канал: -100001,
        действие: .документ(Вложение(имя: "пример.txt", данные: Data("Открытая фикстура".utf8)), nil), цель: "Проверка пути")
    try await ядро.сохранитьЧерновик(черновик)
    let попытка = try await ядро.выполнить(клиент, черновик: черновик.идентификатор,
        разрешение: РазрешениеДействия(черновик: черновик, основание: "Синтетическая проверка"))
    try FileManager.default.moveItem(at: каталог, to: сохранённый)
    if обычныйКаталог { #expect(mkdir(каталог.path, 0o700) == 0) }
    else { #expect(symlink(посторонний.path, каталог.path) == 0) }
    try await провестиПроверкуЧата(ядро, клиент: клиент, транспорт: транспорт)
    #expect(await ядро.взятьОтказПодготовки(попытка) != nil)
    #expect(!транспорт.отправленные.contains { $0.1.тип == "sendMessage" })
    #expect(try FileManager.default.contentsOfDirectory(atPath: посторонний.path).isEmpty)
    if обычныйКаталог { #expect(try FileManager.default.contentsOfDirectory(atPath: каталог.path).isEmpty) }
    await ядро.закрытьЖурнал()
}

@Test func клиентскийЖурналПроверяетПриватностьКорняИСегмента() throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let файл = каталог.appendingPathComponent("сегмент.fumobs")
    let ключ = Data(repeating: 29, count: 32)
    #expect(chmod(каталог.path, 0o755) == 0)
    #expect(throws: ОшибкаКлиента.self) { _ = try ЛокальныйЖурнал(корень: каталог, ключ: ключ) }
    #expect(!FileManager.default.fileExists(atPath: файл.path))

    #expect(chmod(каталог.path, 0o700) == 0)
    let обычный = try Сегмент(кореньДанных: каталог, запись: true)
    обычный.закрыть()
    #expect(chmod(файл.path, 0o644) == 0)
    let до = try Data(contentsOf: файл)
    #expect(throws: ОшибкаКлиента.self) { _ = try ЛокальныйЖурнал(корень: каталог, ключ: ключ) }
    #expect(try Data(contentsOf: файл) == до)

    #expect(chmod(файл.path, 0o600) == 0)
    let журнал = try ЛокальныйЖурнал(корень: каталог, ключ: ключ)
    defer { журнал.закрыть() }
    let доЗаписи = try Data(contentsOf: файл)
    #expect(chmod(файл.path, 0o644) == 0)
    #expect(throws: ОшибкаКлиента.self) { try журнал.добавить(.разрыв("проверка приватности")) }
    #expect(try Data(contentsOf: файл) == доЗаписи)
    #expect(chmod(файл.path, 0o600) == 0)
}

@Test func получениеРасширенногоДоступаПоДескриптору() throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let дескриптор = Darwin.open(каталог.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    #expect(дескриптор >= 0); defer { Darwin.close(дескриптор) }
    try проверитьОтсутствиеРасширенногоДоступа(дескриптор)
    #expect(throws: ОшибкаКлиента.self) { try проверитьОтсутствиеРасширенногоДоступа(-1) }
}

@Test func пустойРасширенныйСписокИмеетОжидаемуюГраницуDarwin() throws {
    let список = try #require(acl_init(0))
    defer { acl_free(UnsafeMutableRawPointer(список)) }
    #expect(acl_valid(список) == 0)
    var запись: acl_entry_t?
    errno = 0
    let результат = acl_get_entry(список, Int32(ACL_FIRST_ENTRY.rawValue), &запись)
    let код = errno
    #expect(результат == -1)
    #expect(код == EINVAL)
}

@Test func отдельныйКлючПроверяетБайтыПраваСсылкиИТип() throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let файл = каталог.appendingPathComponent("ключ")
    let ключ = Data(repeating: 23, count: 32)
    try ключ.write(to: файл)
    #expect(chmod(файл.path, 0o600) == 0)
    #expect(try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ") == ключ)
    for размер in [0, 31, 33] {
        try Data(repeating: 23, count: размер).write(to: файл)
        #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ") }
    }
    try ключ.write(to: файл)
    for права: mode_t in [0o644, 0o640, 0o4600] {
        #expect(chmod(файл.path, права) == 0)
        #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ") }
    }
    #expect(chmod(файл.path, 0o600) == 0)
    for имя in ["", ".", "..", "../ключ", "ключ/дочерний", "ключ\0хвост"] {
        #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: имя) }
    }
    let ссылка = каталог.appendingPathComponent("ссылка")
    #expect(symlink(файл.path, ссылка.path) == 0)
    #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ссылка") }
    let жёсткая = каталог.appendingPathComponent("вторая")
    #expect(link(файл.path, жёсткая.path) == 0)
    #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ") }
    #expect(unlink(жёсткая.path) == 0)
    let канал = каталог.appendingPathComponent("канал")
    #expect(mkfifo(канал.path, 0o600) == 0)
    #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "канал") }
    try установитьРасширенныйДоступ(файл)
    #expect(throws: ОшибкаКлиента.self) { try прочитатьПриватныйКлюч(каталог: каталог, имяФайла: "ключ") }
}

func установитьРасширенныйДоступ(_ путь: URL) throws {
    let команда = Process()
    команда.executableURL = URL(fileURLWithPath: "/bin/chmod")
    команда.arguments = ["+a", "everyone allow read,search", путь.path]
    try команда.run(); команда.waitUntilExit()
    guard команда.terminationStatus == 0 else { throw ОшибкаКлиента.требуетсяРазбор }
}

@Test func расширенныйДоступНеСчитаетсяПриватнымКаталогом() throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    try установитьРасширенныйДоступ(каталог)
    #expect(throws: ОшибкаКлиента.self) { try идентичностьПриватногоКаталога(каталог) }
}
