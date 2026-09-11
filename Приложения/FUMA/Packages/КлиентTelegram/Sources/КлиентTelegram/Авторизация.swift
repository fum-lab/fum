import Foundation

public enum СостояниеАвторизации: String, Codable, Sendable, CaseIterable {
    case параметры, телефон, покупка, почта, кодПочты, кодТелефона, подтверждениеУстройства
    case регистрация, пароль, готов, выход, закрывается, закрыт, неизвестно
    public init(тип: String) {
        switch тип {
        case "authorizationStateWaitTdlibParameters": self = .параметры
        case "authorizationStateWaitPhoneNumber": self = .телефон
        case "authorizationStateWaitPremiumPurchase": self = .покупка
        case "authorizationStateWaitEmailAddress": self = .почта
        case "authorizationStateWaitEmailCode": self = .кодПочты
        case "authorizationStateWaitCode": self = .кодТелефона
        case "authorizationStateWaitOtherDeviceConfirmation": self = .подтверждениеУстройства
        case "authorizationStateWaitRegistration": self = .регистрация
        case "authorizationStateWaitPassword": self = .пароль
        case "authorizationStateReady": self = .готов
        case "authorizationStateLoggingOut": self = .выход
        case "authorizationStateClosing": self = .закрывается
        case "authorizationStateClosed": self = .закрыт
        default: self = .неизвестно
        }
    }
    public var разрешеныПрикладныеОперации: Bool { self == .готов }
}

/// Секреты не Codable и не включаются в локальную историю действий.
public struct ДанныеПриложения: Sendable {
    public let идентификатор: Int32
    public let хэш: String
    public init(идентификатор: Int32, хэш: String) throws {
        guard идентификатор > 0, хэш.count == 32, хэш.allSatisfy(\.isHexDigit) else {
            throw ОшибкаКлиента.неверныеДанные("Отдельные api_id и api_hash приложения")
        }
        self.идентификатор = идентификатор; self.хэш = хэш
    }
}

public struct ПараметрыБиблиотеки: Sendable {
    public let приложение: ДанныеПриложения
    public let каталогБазы: URL
    public let каталогФайлов: URL
    public let ключБазы: Data
    public init(приложение: ДанныеПриложения, каталогБазы: URL, каталогФайлов: URL, ключБазы: Data) throws {
        guard ключБазы.count == 32, каталогБазы != каталогФайлов else {
            throw ОшибкаКлиента.неверныеДанные("Раздельные приватные каталоги и 256-битный ключ базы")
        }
        for каталог in [каталогБазы, каталогФайлов] {
            guard каталог.isFileURL, каталог.path.hasPrefix("/"), каталог.path != "/",
                  каталог.standardizedFileURL == каталог.resolvingSymlinksInPath().standardizedFileURL else {
                throw ОшибкаКлиента.неверныеДанные("Приватный каталог без символических ссылок")
            }
            let свойства = try FileManager.default.attributesOfItem(atPath: каталог.path)
            guard свойства[.type] as? FileAttributeType == .typeDirectory,
                  (свойства[.posixPermissions] as? NSNumber)?.intValue == 0o700,
                  (свойства[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() else {
                throw ОшибкаКлиента.доступЗапрещён("Каталог должен принадлежать пользователю и иметь режим 0700")
            }
        }
        self.приложение = приложение; self.каталогБазы = каталогБазы
        self.каталогФайлов = каталогФайлов; self.ключБазы = ключБазы
    }
}

public enum ДействиеАвторизации: Sendable {
    case параметры(ПараметрыБиблиотеки), телефон(String), кодТелефона(String), почта(String)
    case кодПочты(String), пароль(String), показатьКодУстройства, закрыть
}

enum Авторизация {
    static func запрос(_ действие: ДействиеАвторизации, состояние: СостояниеАвторизации) throws -> ЗначениеДанных {
        func строка(_ значение: String, предел: Int = 4096) throws -> ЗначениеДанных {
            guard !значение.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  значение.utf8.count <= предел, !значение.contains("\0") else {
                throw ОшибкаКлиента.неверныеДанные("Пустой или недопустимый приватный ввод")
            }
            return .текст(значение)
        }
        switch (действие, состояние) {
        case (.закрыть, let состояние) where состояние != .закрыт:
            return .типа("close")
        case (.параметры(let вход), .параметры):
            return .типа("setTdlibParameters", [
                "use_test_dc": .флаг(false), "database_directory": .текст(вход.каталогБазы.path),
                "files_directory": .текст(вход.каталогФайлов.path),
                "database_encryption_key": .текст(вход.ключБазы.base64EncodedString()),
                "use_file_database": .флаг(true), "use_chat_info_database": .флаг(true),
                "use_message_database": .флаг(true), "use_secret_chats": .флаг(false),
                "api_id": .число(Int64(вход.приложение.идентификатор)), "api_hash": .текст(вход.приложение.хэш),
                "system_language_code": .текст("ru"), "device_model": .текст("FUMA macOS arm64"),
                "system_version": .текст(ProcessInfo.processInfo.operatingSystemVersionString),
                "application_version": .текст("FUM-STEP-0222/1")])
        case (.телефон(let значение), .телефон):
            return .типа("setAuthenticationPhoneNumber", ["phone_number": try строка(значение, предел: 64), "settings": .пусто])
        case (.кодТелефона(let значение), .кодТелефона):
            return .типа("checkAuthenticationCode", ["code": try строка(значение, предел: 128)])
        case (.почта(let значение), .почта):
            return .типа("setAuthenticationEmailAddress", ["email_address": try строка(значение, предел: 320)])
        case (.кодПочты(let значение), .кодПочты):
            return .типа("checkAuthenticationEmailCode", ["code": .типа("emailAddressAuthenticationCode", ["code": try строка(значение, предел: 128)])])
        case (.пароль(let значение), .пароль):
            return .типа("checkAuthenticationPassword", ["password": try строка(значение)])
        case (.показатьКодУстройства, .телефон):
            return .типа("requestQrCodeAuthentication", ["other_user_ids": .массив([])])
        default: throw ОшибкаКлиента.доступЗапрещён("Действие не соответствует состоянию авторизации")
        }
    }
}
