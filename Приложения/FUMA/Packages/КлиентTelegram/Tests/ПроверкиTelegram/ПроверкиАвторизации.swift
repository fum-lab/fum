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

@Test func сведенияАвторизацииДоходятДоПубличногоСнимка() async throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let транспорт = ЗаписывающийТранспорт()
    let ядро = try ЯдроКлиента(транспорт: транспорт, корень: каталог, ключ: Data(repeating: 41, count: 32))
    let первый = try await ядро.добавитьКлиента()
    let второй = try await ядро.добавитьКлиента()
    let запросовДо = транспорт.отправленные.count
    let сведения: [(СостояниеАвторизации, ЗначениеДанных)] = [
        (.подтверждениеУстройства, .типа("authorizationStateWaitOtherDeviceConfirmation", ["link": .текст("tg://login?token=synthetic-first")])),
        (.подтверждениеУстройства, .типа("authorizationStateWaitOtherDeviceConfirmation", ["link": .текст("tg://login?token=synthetic-second")])),
        (.почта, .типа("authorizationStateWaitEmailAddress", ["allow_apple_id": .флаг(true), "allow_google_id": .флаг(false)])),
        (.пароль, .типа("authorizationStateWaitPassword", ["password_hint": .текст(""), "has_recovery_email_address": .флаг(true),
            "has_passport_data": .флаг(false), "recovery_email_address_pattern": .текст("s***@example.invalid")])),
        (.регистрация, .типа("authorizationStateWaitRegistration", ["terms_of_service": .типа("termsOfService", [
            "text": .типа("formattedText", ["text": .текст("Синтетические условия"), "entities": .массив([])]), "min_user_age": .число(18), "show_popup": .флаг(true)])])),
        (.покупка, .типа("authorizationStateWaitPremiumPurchase", ["store_product_id": .текст("synthetic"), "premium_day_count": .число(0),
            "support_email_address": .текст("synthetic@example.invalid"), "support_email_subject": .текст("Синтетическая проверка")]))
    ]
    for (ожидаемое, данные) in сведения {
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": данные]), клиент: первый, ядро: ядро)
        let снимок = try await ядро.состояние(первый)
        #expect(снимок.авторизация == ожидаемое)
        #expect(снимок.сведенияАвторизации == данные)
        #expect(снимок.аккаунтПодтверждён == false)
    }
    for сброс: ЗначениеДанных in [.пусто, .типа("emailAddressResetStateAvailable", ["wait_period": .число(3600)]),
                                  .типа("emailAddressResetStatePending", ["reset_in": .число(60)])] {
        let данные = ЗначениеДанных.типа("authorizationStateWaitEmailCode", ["allow_apple_id": .флаг(false), "allow_google_id": .флаг(true),
            "code_info": .типа("emailAddressAuthenticationCodeInfo", ["email_address_pattern": .текст("s***@example.invalid"), "length": .число(6)]),
            "email_address_reset_state": сброс])
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": данные]), клиент: первый, ядро: ядро)
        #expect(try await ядро.состояние(первый).авторизация == .кодПочты)
        #expect(try await ядро.состояние(первый).сведенияАвторизации == данные)
    }
    #expect(try await ядро.состояние(второй).авторизация == .неизвестно)
    #expect(транспорт.отправленные.count == запросовДо)
    try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateClosed")]), клиент: первый, ядро: ядро)
    await #expect(throws: ОшибкаКлиента.self) {
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateReady")]), клиент: первый, ядро: ядро)
    }
    #expect(try await ядро.состояние(первый).авторизация == .закрыт)
    #expect(транспорт.отправленные.count == запросовДо)
    await ядро.закрытьЖурнал()
}

@Test func типизированнаяАвторизацияСоблюдаетСостояниеИГраницыВвода() async throws {
    let каталог = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: каталог) }
    let транспорт = ЗаписывающийТранспорт()
    let ядро = try ЯдроКлиента(транспорт: транспорт, корень: каталог, ключ: Data(repeating: 42, count: 32))
    let клиент = try await ядро.добавитьКлиента()
    let база = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: база) }
    let файлы = try создатьПриватныйКаталог(); defer { try? FileManager.default.removeItem(at: файлы) }
    let ключБазы = Data(repeating: 43, count: 32)
    let параметры = try ПараметрыБиблиотеки(приложение: ДанныеПриложения(идентификатор: 1, хэш: String(repeating: "a", count: 32)),
        каталогБазы: база, каталогФайлов: файлы, ключБазы: ключБазы)
    try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationStateWaitTdlibParameters")]), клиент: клиент, ядро: ядро)
    let параметрыКорреляция = try await ядро.авторизовать(клиент, действие: .параметры(параметры))
    let параметрыЗапрос = транспорт.отправленные.last!.1
    #expect(параметрыЗапрос.тип == "setTdlibParameters")
    #expect(параметрыЗапрос["database_directory"] == .текст(база.path))
    #expect(параметрыЗапрос["files_directory"] == .текст(файлы.path))
    #expect(параметрыЗапрос["database_encryption_key"] == .текст(ключБазы.base64EncodedString()))
    #expect(параметрыЗапрос["api_id"] == .число(1))
    #expect(параметрыЗапрос["api_hash"] == .текст(String(repeating: "a", count: 32)))
    #expect(параметрыЗапрос["use_secret_chats"] == .флаг(false))
    #expect(параметрыЗапрос["@extra"] == .текст(параметрыКорреляция))
    #expect(параметрыЗапрос["phone_number"] == nil && параметрыЗапрос["token"] == nil)
    try await доставить(.типа("ok"), клиент: клиент, ядро: ядро, запрос: параметрыЗапрос)
    let случаи: [(String, ДействиеАвторизации, ЗначениеДанных)] = [
        ("WaitPhoneNumber", .телефон("+10000000000"), .типа("setAuthenticationPhoneNumber", ["phone_number": .текст("+10000000000"), "settings": .пусто])),
        ("WaitPhoneNumber", .показатьКодУстройства, .типа("requestQrCodeAuthentication", ["other_user_ids": .массив([])])),
        ("WaitCode", .кодТелефона("123456"), .типа("checkAuthenticationCode", ["code": .текст("123456")])),
        ("WaitEmailAddress", .почта("synthetic@example.invalid"), .типа("setAuthenticationEmailAddress", ["email_address": .текст("synthetic@example.invalid")])),
        ("WaitEmailCode", .кодПочты("123456"), .типа("checkAuthenticationEmailCode", ["code": .типа("emailAddressAuthenticationCode", ["code": .текст("123456")])])),
        ("WaitPassword", .пароль("синтетический пароль"), .типа("checkAuthenticationPassword", ["password": .текст("синтетический пароль")]))
    ]
    for (состояние, действие, ожидаемый) in случаи {
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationState" + состояние)]), клиент: клиент, ядро: ядро)
        let до = транспорт.отправленные.count
        let корреляция = try await ядро.авторизовать(клиент, действие: действие)
        #expect(транспорт.отправленные.count == до + 1)
        #expect(транспорт.отправленные.last?.0 == клиент)
        #expect(try транспорт.отправленные.last?.1 == ожидаемый.добавив("@extra", .текст(корреляция)))
        try await доставить(.типа("ok"), клиент: клиент, ядро: ядро, запрос: транспорт.отправленные.last!.1)
        #expect(try await ядро.состояние(клиент).авторизация == СостояниеАвторизации(тип: "authorizationState" + состояние))
        #expect(try await ядро.взятьОтвет(корреляция, клиент: клиент)?.тип == "ok")
        #expect(try await ядро.взятьОтвет(корреляция, клиент: клиент) == nil)
    }
    let пределы: [(СостояниеАвторизации, Int, (String) -> ДействиеАвторизации)] = [
        (.телефон, 64, ДействиеАвторизации.телефон), (.кодТелефона, 128, ДействиеАвторизации.кодТелефона),
        (.почта, 320, ДействиеАвторизации.почта), (.кодПочты, 128, ДействиеАвторизации.кодПочты),
        (.пароль, 4096, ДействиеАвторизации.пароль)
    ]
    for (состояние, предел, действие) in пределы {
        _ = try Авторизация.запрос(действие(String(repeating: "я", count: предел / 2)), состояние: состояние)
        for неверное in ["", " \n", "a\0b", String(repeating: "я", count: предел / 2 + 1)] {
            #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(действие(неверное), состояние: состояние) }
        }
        for чужоеСостояние in СостояниеАвторизации.allCases where чужоеСостояние != состояние {
            #expect(throws: ОшибкаКлиента.self) { try Авторизация.запрос(действие("123"), состояние: чужоеСостояние) }
        }
    }
    for состояние in ["WaitRegistration", "WaitPremiumPurchase", "LoggingOut", "Closing", "Closed"] {
        try await доставить(.типа("updateAuthorizationState", ["authorization_state": .типа("authorizationState" + состояние)]), клиент: клиент, ядро: ядро)
        let до = транспорт.отправленные.count
        await #expect(throws: ОшибкаКлиента.self) { try await ядро.авторизовать(клиент, действие: .показатьКодУстройства) }
        #expect(транспорт.отправленные.count == до)
    }
    await ядро.закрытьЖурнал()
}
