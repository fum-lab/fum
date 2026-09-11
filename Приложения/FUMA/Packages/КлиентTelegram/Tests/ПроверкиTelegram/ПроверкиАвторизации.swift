import Foundation
import Testing
@testable import КлиентTelegram

@Test func параметрыПовторноПроверяютПриватностьПередОтправкой() throws {
    let база = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: база) }
    let файлы = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: файлы) }
    let приложение = try ДанныеПриложения(идентификатор: 1, хэш: String(repeating: "a", count: 32))
    let параметры = try ПараметрыБиблиотеки(приложение: приложение, каталогБазы: база, каталогФайлов: файлы, ключБазы: Data(repeating: 1, count: 32))
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: база.path)
    #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(.параметры(параметры), состояние: .параметры) }
}

@Test func всеСостоянияЗакреплённойАвторизацииИНеизвестное() throws {
    let соответствия: [(String, СостояниеАвторизации)] = [
        ("WaitTdlibParameters", .параметры), ("WaitPhoneNumber", .телефон),
        ("WaitPremiumPurchase", .покупка), ("WaitEmailAddress", .почта),
        ("WaitEmailCode", .кодПочты), ("WaitCode", .кодТелефона),
        ("WaitOtherDeviceConfirmation", .подтверждениеУстройства),
        ("WaitRegistration", .регистрация), ("WaitPassword", .пароль),
        ("Ready", .готов), ("LoggingOut", .выход), ("Closing", .закрывается), ("Closed", .закрыт)
    ]
    for (суффикс, ожидаемое) in соответствия {
        #expect(СостояниеАвторизации(тип: "authorizationState" + суффикс) == ожидаемое)
        #expect(ожидаемое.разрешеныПрикладныеОперации == (ожидаемое == .готов))
    }
    #expect(СостояниеАвторизации(тип: "authorizationStateWaitEncryptionKey") == .неизвестно)
    #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(.кодТелефона("123"), состояние: .готов) }
    #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(.кодТелефона(""), состояние: .кодТелефона) }
    let письмо = try Авторизация.запрос(.кодПочты("123456"), состояние: .кодПочты)
    #expect(письмо["code"]?["@type"]?.строка == "emailAddressAuthenticationCode")
    #expect(письмо["code"]?["code"]?.строка == "123456")
    #expect(try Авторизация.запрос(.закрыть, состояние: .покупка)["@type"]?.строка == "close")
    #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(.телефон("+10000000000"), состояние: .регистрация) }
}

@Test func данныеСохраняютЧислаСтрокиКорреляциюИОтклоняютГраницы() throws {
    let исходник = Data(#"{"@type":"message","@client_id":2,"@extra":"попытка","id":1048576,"media_album_id":"9223372036854775807","flag":false}"#.utf8)
    let объект = try ЗначениеДанных.прочитать(исходник)
    #expect(объект["id"]?.целое == 1048576)
    #expect(объект["media_album_id"]?.строка == "9223372036854775807")
    #expect(объект["flag"]?.логическое == false)
    #expect(try ЗначениеДанных.прочитать(объект.байты()) == объект)
    #expect(throws: ОшибкаКлиента.self) { try ЗначениеДанных.прочитать(Data("[]".utf8)) }
    #expect(throws: ОшибкаКлиента.self) { try ЗначениеДанных.прочитать(исходник, предел: 5) }
}
