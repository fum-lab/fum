import CryptoKit
import Foundation
import СетьАгентов

public struct ЗаписьПутиМанифеста: Codable, Equatable, Sendable {
    public let путь: String
    public let sha256: String

    public init(путь: String, sha256: String) {
        self.путь = путь
        self.sha256 = sha256
    }
}

/// Факт от отдельного проверяющего источника. Оператор не читает дерево и не подменяет его работу.
public struct СвидетельствоПроверкиМанифеста: Equatable, Sendable {
    public let результат: РезультатПроверки
    public let версияПроверяющего: String
    public let проверяющий: String
    public let провереноВ: Date
    public let свежеДо: Date
    public let квитанция: Знание<String>
    public let sha256ПроверенныхБайтов: String
    public let провереннаяСсылка: String
    public let проверенныйКоммит: String
    public let проверенноеДерево: String
    public let проверенныеПути: [ЗаписьПутиМанифеста]

    public enum РезультатПроверки: String, Codable, Sendable {
        case пройдена, отказ, неизвестно
    }

    init(результат: РезультатПроверки, версияПроверяющего: String, проверяющий: String,
        провереноВ: Date, свежеДо: Date, квитанция: Знание<String>, sha256ПроверенныхБайтов: String,
        провереннаяСсылка: String, проверенныйКоммит: String, проверенноеДерево: String,
        проверенныеПути: [ЗаписьПутиМанифеста]) {
        self.результат = результат
        self.версияПроверяющего = версияПроверяющего
        self.проверяющий = проверяющий
        self.провереноВ = провереноВ
        self.свежеДо = свежеДо
        self.квитанция = квитанция
        self.sha256ПроверенныхБайтов = sha256ПроверенныхБайтов
        self.провереннаяСсылка = провереннаяСсылка
        self.проверенныйКоммит = проверенныйКоммит
        self.проверенноеДерево = проверенноеДерево
        self.проверенныеПути = проверенныеПути
    }
}

public struct СнимокМанифеста: Equatable, Sendable {
    public let путь: String
    public let байты: Data
    public let заявленныйSHA256: String
    public let версия: String
    public let исходнаяСсылка: String
    public let исходныйКоммит: String
    public let исходноеДерево: String
    public let записиПутей: [ЗаписьПутиМанифеста]
    public let свидетельство: СвидетельствоПроверкиМанифеста?

    public init(путь: String, байты: Data, заявленныйSHA256: String, версия: String,
        исходнаяСсылка: String, исходныйКоммит: String, исходноеДерево: String,
        записиПутей: [ЗаписьПутиМанифеста], свидетельство: СвидетельствоПроверкиМанифеста? = nil) {
        self.путь = путь
        self.байты = байты
        self.заявленныйSHA256 = заявленныйSHA256
        self.версия = версия
        self.исходнаяСсылка = исходнаяСсылка
        self.исходныйКоммит = исходныйКоммит
        self.исходноеДерево = исходноеДерево
        self.записиПутей = записиПутей
        self.свидетельство = свидетельство
    }

    public var вычисленныйSHA256: String { Self.вычислитьХэшSHA256(байты) }

    private static func вычислитьХэшSHA256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
}

public enum ВозможностьСвязыванияМанифеста: String, Codable, Sendable {
    case доступна, недоступна
}

public struct ЗапросСвязыванияМанифеста: Equatable, Sendable {
    public let id: UUID
    public let байты: Data
    public let версия: String
    public let автор: Знание<String>
    public let исполнитель: Знание<String>
    public let версияСостояния: Знание<UInt64>
    public let арендаДействуетДо: Знание<Date>
    public let возможностьАдаптера: Знание<ВозможностьСвязыванияМанифеста>
    public let снимок: СнимокМанифеста
    public let атрибуция: АтрибуцияРешенияУзла

    public init(id: UUID, байты: Data, версия: String, автор: Знание<String>, исполнитель: Знание<String>,
        версияСостояния: Знание<UInt64>, арендаДействуетДо: Знание<Date>,
        возможностьАдаптера: Знание<ВозможностьСвязыванияМанифеста>, снимок: СнимокМанифеста,
        атрибуция: АтрибуцияРешенияУзла) {
        self.id = id
        self.байты = байты
        self.версия = версия
        self.автор = автор
        self.исполнитель = исполнитель
        self.версияСостояния = версияСостояния
        self.арендаДействуетДо = арендаДействуетДо
        self.возможностьАдаптера = возможностьАдаптера
        self.снимок = снимок
        self.атрибуция = атрибуция
    }

    public var хэшSHA256БайтовЗапроса: String { Self.вычислитьХэшSHA256(байты) }

    private static func вычислитьХэшSHA256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }
}

public struct ИсторическаяПривязкаМанифеста: Equatable, Sendable {
    public let idКоманды: UUID
    public let idПоручения: UUID
    public let sha256Манифеста: String
    public let sha256Запроса: String
    public let квитанция: Знание<String>
    public let исход: ИсходКоманды

    init(idКоманды: UUID, idПоручения: UUID, sha256Манифеста: String,
        sha256Запроса: String, квитанция: Знание<String>, исход: ИсходКоманды) {
        self.idКоманды = idКоманды
        self.idПоручения = idПоручения
        self.sha256Манифеста = sha256Манифеста
        self.sha256Запроса = sha256Запроса
        self.квитанция = квитанция
        self.исход = исход
    }
}

public struct СнимокИсторииПривязок: Equatable, Sendable {
    fileprivate let записи: [ИсторическаяПривязкаМанифеста]

    init(записи: [ИсторическаяПривязкаМанифеста]) {
        self.записи = записи
    }
}

public struct РазрешениеНеизвестногоЭффекта: Equatable, Sendable {
    public enum Основание: String, Codable, Sendable { case терминальныйИсход, подтверждённоеОграждение }

    public let idКоманды: UUID
    public let основание: Основание
    public let владелец: String
    public let версияСостоянияПослеРазрешения: Знание<UInt64>
    public let терминальныйИсход: Знание<ИсходКоманды>
    public let свидетельствоОграждения: Знание<СвидетельствоОграждения>

    init(idКоманды: UUID, основание: Основание, владелец: String,
        версияСостоянияПослеРазрешения: Знание<UInt64>,
        терминальныйИсход: Знание<ИсходКоманды>, свидетельствоОграждения: Знание<СвидетельствоОграждения>) {
        self.idКоманды = idКоманды
        self.основание = основание
        self.владелец = владелец
        self.версияСостоянияПослеРазрешения = версияСостоянияПослеРазрешения
        self.терминальныйИсход = терминальныйИсход
        self.свидетельствоОграждения = свидетельствоОграждения
    }
}

public struct СвидетельствоОграждения: Equatable, Sendable {
    public let idКоманды: UUID
    public let владелец: String
    public let ожидаемаяВерсияСостояния: UInt64
    public let версияПослеОграждения: UInt64
    public let исключаетБудущиеЭффекты: Bool
    public let квитанция: String

    init(idКоманды: UUID, владелец: String, ожидаемаяВерсияСостояния: UInt64,
        версияПослеОграждения: UInt64, исключаетБудущиеЭффекты: Bool, квитанция: String) {
        self.idКоманды = idКоманды
        self.владелец = владелец
        self.ожидаемаяВерсияСостояния = ожидаемаяВерсияСостояния
        self.версияПослеОграждения = версияПослеОграждения
        self.исключаетБудущиеЭффекты = исключаетБудущиеЭффекты
        self.квитанция = квитанция
    }
}

public enum КодОтветаКоординатору: String, Codable, Sendable {
    case подготовитьСвязываниеМанифеста
    case ужеВыполнено
    case отказаноНесовпадениеПутей
    case отказаноНесовпадениеБайтов
    case требуетсяРешениеВладельца
    case эффектЕщёНеЗавершён
    case историяЭффектовНеизвестна
    case неизвестныйЭффектНеПовторять
    case неизвестнаяВозможностьАдаптера
    case адаптерНедоступен
    case неизвестныйГрантИлиНазначение
    case авторНекорректен
    case устаревшиеСвидетельства
    case проверяющийИсточникаНеизвестен
    case решениеНеРазрешаетЭффект
}

public enum СтатусОтветаКоординатору: String, Codable, Sendable {
    case планГотов, ужеВыполнено, отказ, удерживать, эскалация, неизвестно
}

public enum ОперацияСохраненияМанифеста: String, Codable, Sendable {
    case сохранитьТочныйМанифест
}

public enum ФазаКомандыGit: String, Sendable {
    case commit
    case push
    case observeRemote
}

public enum ОтказКомандыGit: String, Sendable {
    case отсутствуетПроверенноеСвидетельство
    case изменилсяЗаборПослеСнимка
    case профильИлиПоручениеНеСовпадают
    case наборИсходниковНеСовпадает
    case rawCommitНекорректен
    case базовыйСнимокНеСовпадает
    case родительДеревоИлиIdentityНеСовпадают
    case модельныйOIDНеСовпадает
    case нельзяПубликоватьЭтуВетку
    case soleOriginНеПодтверждён
}

/// Только данные конечной команды; этот тип не запускает git и не вызывает Process.
public struct ПланКомандыGit: Equatable, Sendable {
    public let фаза: ФазаКомандыGit
    public let рабочийКаталог: String
    public let программа: String
    public let аргументы: [String]
    public let окружение: [String: String]
    public let запускРазрешён: Bool

    fileprivate init(фаза: ФазаКомандыGit, рабочийКаталог: String, аргументы: [String],
        окружение: [String: String] = [:]) {
        self.фаза = фаза
        self.рабочийКаталог = рабочийКаталог
        self.программа = "git"
        self.аргументы = аргументы
        self.окружение = окружение
        self.запускРазрешён = false
    }
}

public enum РезультатПорожденияКомандыGit: Equatable, Sendable {
    case команда(ПланКомандыGit)
    case отказ(ОтказКомандыGit)
}

public enum ПодтверждениеДоставкиGit: String, Sendable {
    case подтверждено
    case неизвестно
}

public struct КвитанцияУдалённогоOID: Equatable, Sendable {
    public let remote: String
    public let полныйRef: String
    public let oid: String
    public let rawОтвет: Data

    init(remote: String, полныйRef: String, oid: String, rawОтвет: Data) {
        self.remote = remote
        self.полныйRef = полныйRef
        self.oid = oid
        self.rawОтвет = rawОтвет
    }
}

public struct ФайлСнимкаGit: Equatable, Sendable {
    public let путь: String
    public let sha256: String
    public let размер: Int

    init(путь: String, sha256: String, размер: Int) {
        self.путь = путь
        self.sha256 = sha256
        self.размер = размер
    }
}

public enum ВидИсточникаАвторстваGit: String, Sendable {
    case свежаяАтрибуция
    case явноеПоручениеБезАтрибуции
}

public struct ИсточникАвторстваGit: Equatable, Sendable {
    public let вид: ВидИсточникаАвторстваGit
    public let модель: String?
    public let усилие: String?
    public let наблюденоВ: Date?
    public let свежеДо: Date?
    public let sha256Профиля: String?
    public let assignmentPin: String?

    init(вид: ВидИсточникаАвторстваGit, модель: String? = nil, усилие: String? = nil,
        наблюденоВ: Date? = nil, свежеДо: Date? = nil,
        sha256Профиля: String? = nil, assignmentPin: String? = nil) {
        self.вид = вид
        self.модель = модель
        self.усилие = усилие
        self.наблюденоВ = наблюденоВ
        self.свежеДо = свежеДо
        self.sha256Профиля = sha256Профиля
        self.assignmentPin = assignmentPin
    }
}

/// Проверяющий поставщик выдаёт снимок после проверки raw Git-объектов и манифеста индекса.
/// Конструктор закрыт для вызывающего кода; производственный поставщик пока отсутствует.
public struct СнимокДоКоммитаGit: Equatable, Sendable {
    public let рабочийКаталог: String
    public let базовыйHEAD: String
    public let полныйRef: String
    public let rawКоммитHEAD: Data
    public let индексTreeOID: String
    public let rawИндексTree: Data
    public let изменённыеФайлы: [ФайлСнимкаGit]
    public let требуемыеФайлы: [ФайлСнимкаGit]
    public let разрешённыеПути: [String]
    public let sha256Профиля: String
    public let assignmentPin: String
    public let версияСостояния: UInt64
    public let leaseДо: Date
    public let моментСнимка: Date
    public let именаRemote: [String]
    public let originURL: String
    public let источникАвторства: ИсточникАвторстваGit
    public let авторGitСтрока: String
    public let committerGitСтрока: String
    public let путьФайлаСообщения: String
    public let байтыФайлаСообщения: Data
    public let sha256ФайлаСообщения: String

    init(рабочийКаталог: String, базовыйHEAD: String, полныйRef: String, rawКоммитHEAD: Data,
        индексTreeOID: String, rawИндексTree: Data, изменённыеФайлы: [ФайлСнимкаGit],
        требуемыеФайлы: [ФайлСнимкаGit], разрешённыеПути: [String], sha256Профиля: String,
        assignmentPin: String, версияСостояния: UInt64, leaseДо: Date, моментСнимка: Date,
        именаRemote: [String], originURL: String, источникАвторства: ИсточникАвторстваGit,
        авторGitСтрока: String, committerGitСтрока: String,
        путьФайлаСообщения: String, байтыФайлаСообщения: Data, sha256ФайлаСообщения: String) {
        self.рабочийКаталог = рабочийКаталог
        self.базовыйHEAD = базовыйHEAD
        self.полныйRef = полныйRef
        self.rawКоммитHEAD = rawКоммитHEAD
        self.индексTreeOID = индексTreeOID
        self.rawИндексTree = rawИндексTree
        self.изменённыеФайлы = изменённыеФайлы
        self.требуемыеФайлы = требуемыеФайлы
        self.разрешённыеПути = разрешённыеПути
        self.sha256Профиля = sha256Профиля
        self.assignmentPin = assignmentPin
        self.версияСостояния = версияСостояния
        self.leaseДо = leaseДо
        self.моментСнимка = моментСнимка
        self.именаRemote = именаRemote
        self.originURL = originURL
        self.источникАвторства = источникАвторства
        self.авторGitСтрока = авторGitСтрока
        self.committerGitСтрока = committerGitСтрока
        self.путьФайлаСообщения = путьФайлаСообщения
        self.байтыФайлаСообщения = байтыФайлаСообщения
        self.sha256ФайлаСообщения = sha256ФайлаСообщения
    }
}

public struct ЗаборGit: Equatable, Sendable {
    public let рабочийКаталог: String
    public let head: String
    public let полныйRef: String
    public let индексTreeOID: String
    public let sha256Профиля: String
    public let assignmentPin: String
    public let версияСостояния: UInt64
    public let leaseДо: Date
    public let момент: Date
    public let именаRemote: [String]
    public let originURL: String
    public let источникАвторства: ИсточникАвторстваGit
    public let sha256ФайлаСообщения: String

    init(рабочийКаталог: String, head: String, полныйRef: String, индексTreeOID: String,
        sha256Профиля: String, assignmentPin: String, версияСостояния: UInt64, leaseДо: Date,
        момент: Date, именаRemote: [String], originURL: String,
        источникАвторства: ИсточникАвторстваGit, sha256ФайлаСообщения: String) {
        self.рабочийКаталог = рабочийКаталог
        self.head = head
        self.полныйRef = полныйRef
        self.индексTreeOID = индексTreeOID
        self.sha256Профиля = sha256Профиля
        self.assignmentPin = assignmentPin
        self.версияСостояния = версияСостояния
        self.leaseДо = leaseДо
        self.момент = момент
        self.именаRemote = именаRemote
        self.originURL = originURL
        self.источникАвторства = источникАвторства
        self.sha256ФайлаСообщения = sha256ФайлаСообщения
    }
}

public struct СнимокДоставкиGit: Equatable, Sendable {
    public let базовыйHEAD: String
    public let полныйRef: String
    public let rawКоммитHEAD: Data
    public let коммитДоставки: Data
    public let индексTreeOID: String
    public let rawИндексTree: Data
    public let изменённыеФайлы: [ФайлСнимкаGit]
    public let требуемыеФайлы: [ФайлСнимкаGit]
    public let разрешённыеПути: [String]
    public let рабочийКаталог: String
    public let sha256Профиля: String
    public let assignmentPin: String
    public let версияСостояния: UInt64
    public let leaseДо: Date
    public let моментСнимка: Date
    public let именаRemote: [String]
    public let originURL: String
    public let источникАвторства: ИсточникАвторстваGit
    public let путьФайлаСообщения: String
    public let байтыФайлаСообщения: Data
    public let sha256ФайлаСообщения: String
    public let авторGitСтрока: String
    public let committerGitСтрока: String
    public let требуемыйOIDМанифеста: String

    init(базовыйHEAD: String, полныйRef: String, rawКоммитHEAD: Data, коммитДоставки: Data,
        индексTreeOID: String, rawИндексTree: Data, изменённыеФайлы: [ФайлСнимкаGit],
        требуемыеФайлы: [ФайлСнимкаGit], разрешённыеПути: [String], рабочийКаталог: String,
        sha256Профиля: String, assignmentPin: String, версияСостояния: UInt64, leaseДо: Date,
        моментСнимка: Date, именаRemote: [String], originURL: String,
        источникАвторства: ИсточникАвторстваGit, путьФайлаСообщения: String,
        байтыФайлаСообщения: Data, sha256ФайлаСообщения: String,
        авторGitСтрока: String, committerGitСтрока: String, требуемыйOIDМанифеста: String) {
        self.базовыйHEAD = базовыйHEAD
        self.полныйRef = полныйRef
        self.rawКоммитHEAD = rawКоммитHEAD
        self.коммитДоставки = коммитДоставки
        self.индексTreeOID = индексTreeOID
        self.rawИндексTree = rawИндексTree
        self.изменённыеФайлы = изменённыеФайлы
        self.требуемыеФайлы = требуемыеФайлы
        self.разрешённыеПути = разрешённыеПути
        self.рабочийКаталог = рабочийКаталог
        self.sha256Профиля = sha256Профиля
        self.assignmentPin = assignmentPin
        self.версияСостояния = версияСостояния
        self.leaseДо = leaseДо
        self.моментСнимка = моментСнимка
        self.именаRemote = именаRemote
        self.originURL = originURL
        self.источникАвторства = источникАвторства
        self.путьФайлаСообщения = путьФайлаСообщения
        self.байтыФайлаСообщения = байтыФайлаСообщения
        self.sha256ФайлаСообщения = sha256ФайлаСообщения
        self.авторGitСтрока = авторGitСтрока
        self.committerGitСтрока = committerGitСтрока
        self.требуемыйOIDМанифеста = требуемыйOIDМанифеста
    }
}

public struct ПривязкаМанифестаДляАдаптера: Codable, Equatable, Sendable {
    /// Конечная операция этого плана; произвольная команда или argv не принимаются.
    public var операция: ОперацияСохраненияМанифеста { .сохранитьТочныйМанифест }
    public let idЗапроса: UUID
    public let sha256Запроса: String
    public let версияЗапроса: String
    public let idПоручения: UUID
    public let исходнаяСсылка: String
    public let исходныйКоммит: String
    public let исходноеДерево: String
    public let путьМанифеста: String
    public let байтыМанифеста: Data
    public let sha256Манифеста: String
    public let версияМанифеста: String
    public let записиПутей: [ЗаписьПутиМанифеста]
    public let грант: String
    public let исполнитель: String
    public let автор: Знание<String>
    public let ожидаемаяВерсияСостояния: UInt64
    public let арендаДействуетДо: Date
    public let атрибуция: АтрибуцияРешенияУзла
    public let квитанцияПроверкиИсточника: String
    public let версияПроверяющегоИсточника: String

    fileprivate init(запрос: ЗапросСвязыванияМанифеста, поручение: КонтекстПорученияУзла,
        версияСостояния: UInt64, аренда: Date, грант: String, исполнитель: String,
        пути: [ЗаписьПутиМанифеста], shaМанифеста: String, квитанция: String,
        версияПроверяющегоИсточника: String) {
        self.idЗапроса = запрос.id
        self.sha256Запроса = запрос.хэшSHA256БайтовЗапроса
        self.версияЗапроса = запрос.версия
        self.idПоручения = поручение.id
        self.исходнаяСсылка = поручение.исходнаяСсылка
        self.исходныйКоммит = поручение.исходныйКоммит
        self.исходноеДерево = поручение.исходноеДерево
        self.путьМанифеста = запрос.снимок.путь
        self.байтыМанифеста = запрос.снимок.байты
        self.sha256Манифеста = shaМанифеста
        self.версияМанифеста = запрос.снимок.версия
        self.записиПутей = пути
        self.грант = грант
        self.исполнитель = исполнитель
        self.автор = запрос.автор
        self.ожидаемаяВерсияСостояния = версияСостояния
        self.арендаДействуетДо = аренда
        self.атрибуция = запрос.атрибуция
        self.квитанцияПроверкиИсточника = квитанция
        self.версияПроверяющегоИсточника = версияПроверяющегоИсточника
    }
}

public struct ПланОтветаКоординатору: Codable, Equatable, Sendable {
    public let idРешения: UUID
    public let idНаблюдения: UUID
    public let idПоручения: Знание<UUID>
    public let исходнаяВерсия: String
    public let код: КодОтветаКоординатору
    public let статус: СтатусОтветаКоординатору
    public let причины: [String]
    public let атрибуцияЗапроса: АтрибуцияРешенияУзла
    public let атрибуцияРешения: АтрибуцияРешенияУзла
    public let связывание: ПривязкаМанифестаДляАдаптера?
    /// Типизированная команда сохранения для существующего FUMA adapter.
    public var командаСохраненияИсходников: ПривязкаМанифестаДляАдаптера? { связывание }

    fileprivate init(idРешения: UUID, наблюдение: НаблюдениеУзла, idПоручения: Знание<UUID>,
        код: КодОтветаКоординатору, статус: СтатусОтветаКоординатору, причины: [String],
        атрибуцияЗапроса: АтрибуцияРешенияУзла, атрибуцияРешения: АтрибуцияРешенияУзла,
        связывание: ПривязкаМанифестаДляАдаптера?) {
        self.idРешения = idРешения
        self.idНаблюдения = наблюдение.id
        self.idПоручения = idПоручения
        self.исходнаяВерсия = наблюдение.версияИсточника
        self.код = код
        self.статус = статус
        self.причины = причины
        self.атрибуцияЗапроса = атрибуцияЗапроса
        self.атрибуцияРешения = атрибуцияРешения
        self.связывание = связывание
    }
}

/// Чистый планировщик ответов. Не отправляет, не сохраняет и не запускает команды.
public enum ОператорШтатныхОтветов {
    private static let профильныйХэш = ВосстановлениеСохранённогоПрофиля.sha256ЗакреплённогоСнимка
    private static let профильноеНазначение = "01a17797-519b-73c1-bcc8-fd295cdfe9b0"
    private static let профильныйRefGit = "refs/heads/fum-lab/fum/instrumentyi/shtatnyiye-otvetyi/master"
    private static let профильныйOriginGit = "https://github.com/fum-lab/fum.git"
    private static let профильныеПути = [
        "fuma/packages/otvety-koordinatoru/Package.swift",
        "fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ОператорШтатныхОтветов.swift",
        "fuma/packages/otvety-koordinatoru/Tests/ПроверкиОтветовКоординатору/ПроверкиОператораШтатныхОтветов.swift",
        "fuma/packages/otvety-koordinatoru/Sources/ОтветыКоординатору/ВосстановлениеСохранённогоПрофиля.swift",
        "fuma/packages/otvety-koordinatoru/Tests/ПроверкиОтветовКоординатору/ПроверкиВосстановленияПрофиля.swift"
    ]

    private struct ПоляRawCommit {
        let tree: String
        let parents: [String]
        let author: String
        let committer: String
        let сообщение: Data
    }

    /// Строит обычную команду commit из исходного снимка и свежего забора.
    /// Необработанные index/tree/base commit и staged file receipt выдаёт проверяющий поставщик.
    public static func подготовитьКомандуCommit(
        снимок: СнимокДоКоммитаGit,
        свежийЗабор: ЗаборGit
    ) -> РезультатПорожденияКомандыGit {
        guard снимок.sha256Профиля == профильныйХэш,
              снимок.assignmentPin == профильноеНазначение else {
            return .отказ(.профильИлиПоручениеНеСовпадают)
        }
        guard fence(снимок: снимок, забор: свежийЗабор, доCommit: true) else {
            return .отказ(.изменилсяЗаборПослеСнимка)
        }
        guard авторствоРазрешено(снимок.источникАвторства, sha256Профиля: снимок.sha256Профиля,
                  assignmentPin: снимок.assignmentPin, момент: снимок.моментСнимка),
              авторствоРазрешено(свежийЗабор.источникАвторства, sha256Профиля: свежийЗабор.sha256Профиля,
                  assignmentPin: свежийЗабор.assignmentPin, момент: свежийЗабор.момент) else {
            return .отказ(.профильИлиПоручениеНеСовпадают)
        }
        guard снимок.именаRemote == ["origin"], снимок.originURL == профильныйOriginGit,
              снимок.полныйRef == профильныйRefGit else {
            return .отказ(.soleOriginНеПодтверждён)
        }
        guard корректнаяВетка(снимок.полныйRef),
              совпадаютФайлы(изменённые: снимок.изменённыеФайлы,
                  требуемые: снимок.требуемыеФайлы, разрешённыеПути: снимок.разрешённыеПути),
              sha256(снимок.байтыФайлаСообщения) == снимок.sha256ФайлаСообщения,
              снимок.путьФайлаСообщения.hasPrefix("/"),
              gitOID(тип: "commit", raw: снимок.rawКоммитHEAD) == снимок.базовыйHEAD,
              gitOID(тип: "tree", raw: снимок.rawИндексTree) == снимок.индексTreeOID,
              разобратьCommit(снимок.rawКоммитHEAD) != nil,
              let автор = разобратьИдентичность("author \(снимок.авторGitСтрока)"),
              let committer = разобратьИдентичность("committer \(снимок.committerGitСтрока)") else {
            return .отказ(.наборИсходниковНеСовпадает)
        }
        let environment = [
            "GIT_AUTHOR_NAME": автор.имя,
            "GIT_AUTHOR_EMAIL": автор.email,
            "GIT_AUTHOR_DATE": автор.дата,
            "GIT_COMMITTER_NAME": committer.имя,
            "GIT_COMMITTER_EMAIL": committer.email,
            "GIT_COMMITTER_DATE": committer.дата
        ]
        return .команда(ПланКомандыGit(фаза: .commit, рабочийКаталог: снимок.рабочийКаталог,
            аргументы: ["commit", "--cleanup=verbatim",
                "--file", снимок.путьФайлаСообщения], окружение: environment))
    }

    /// Строит обычный push только из проверенного raw-коммита C.
    /// Предложенный моделью OID служит лишь проверкой отказа и не попадает в argv.
    public static func подготовитьКомандуPush(
        снимок: СнимокДоставкиGit,
        исходныйСнимок: СнимокДоКоммитаGit,
        свежийЗабор: ЗаборGit,
        предложенныйOIDМоделью: String? = nil
    ) -> РезультатПорожденияКомандыGit {
        guard снимок.sha256Профиля == профильныйХэш,
              снимок.assignmentPin == профильноеНазначение else {
            return .отказ(.профильИлиПоручениеНеСовпадают)
        }
        guard снимок.именаRemote == ["origin"], снимок.originURL == профильныйOriginGit,
              снимок.полныйRef == профильныйRefGit else {
            return .отказ(.soleOriginНеПодтверждён)
        }
        guard привязаноКБазе(снимок, исходныйСнимок: исходныйСнимок) else {
            return .отказ(.базовыйСнимокНеСовпадает)
        }
        guard корректнаяВетка(снимок.полныйRef), снимок.требуемыйOIDМанифеста == снимокOID(снимок),
              предложенныйOIDМоделью == nil || предложенныйOIDМоделью == снимок.требуемыйOIDМанифеста else {
            return .отказ(предложенныйOIDМоделью != nil && предложенныйOIDМоделью != снимок.требуемыйOIDМанифеста
                ? .модельныйOIDНеСовпадает : .нельзяПубликоватьЭтуВетку)
        }
        guard fence(снимок: снимок, забор: свежийЗабор) else {
            return .отказ(.изменилсяЗаборПослеСнимка)
        }
        guard разобратьCommit(снимок.rawКоммитHEAD) != nil,
              let delivery = разобратьCommit(снимок.коммитДоставки),
              gitOID(тип: "commit", raw: снимок.rawКоммитHEAD) == снимок.базовыйHEAD,
              gitOID(тип: "commit", raw: снимок.коммитДоставки) == снимок.требуемыйOIDМанифеста,
              gitOID(тип: "tree", raw: снимок.rawИндексTree) == снимок.индексTreeOID,
              delivery.parents == [снимок.базовыйHEAD],
              delivery.tree == снимок.индексTreeOID,
              delivery.author == снимок.авторGitСтрока,
              delivery.committer == снимок.committerGitСтрока,
              delivery.сообщение == снимок.байтыФайлаСообщения,
              sha256(снимок.байтыФайлаСообщения) == снимок.sha256ФайлаСообщения,
              совпадаютФайлы(изменённые: снимок.изменённыеФайлы,
                  требуемые: снимок.требуемыеФайлы, разрешённыеПути: снимок.разрешённыеПути) else {
            return .отказ(.родительДеревоИлиIdentityНеСовпадают)
        }
        let oid = снимок.требуемыйOIDМанифеста
        return .команда(ПланКомандыGit(фаза: .push, рабочийКаталог: снимок.рабочийКаталог,
            аргументы: ["push", "origin", "\(oid):\(снимок.полныйRef)"]))
    }

    /// После UNKNOWN старая команда не повторяется: планируется только read-only readback.
    public static func подготовитьНаблюдениеНеизвестногоPush(
        снимок: СнимокДоставкиGit,
        исходныйСнимок: СнимокДоКоммитаGit
    ) -> РезультатПорожденияКомандыGit {
        guard снимок.именаRemote == ["origin"], снимок.originURL == профильныйOriginGit,
              снимок.полныйRef == профильныйRefGit else {
            return .отказ(.soleOriginНеПодтверждён)
        }
        guard корректнаяВетка(снимок.полныйRef),
              привязаноКБазе(снимок, исходныйСнимок: исходныйСнимок),
              снимок.требуемыйOIDМанифеста == снимокOID(снимок),
              gitOID(тип: "commit", raw: снимок.коммитДоставки) == снимок.требуемыйOIDМанифеста else {
            return .отказ(.rawCommitНекорректен)
        }
        return .команда(ПланКомандыGit(фаза: .observeRemote, рабочийКаталог: снимок.рабочийКаталог,
            аргументы: ["ls-remote", "--refs", "origin", снимок.полныйRef]))
    }

    /// Подтверждает доставку только по независимой квитанции точного remote OID/ref.
    public static func подтвердитьДоставку(
        снимок: СнимокДоставкиGit,
        квитанция: КвитанцияУдалённогоOID?
    ) -> ПодтверждениеДоставкиGit {
        guard let квитанция, квитанция.remote == "origin",
              квитанция.полныйRef == снимок.полныйRef,
              корректныйOIDGit(квитанция.oid),
              let raw = String(data: квитанция.rawОтвет, encoding: .utf8),
              raw == "\(квитанция.oid)\t\(квитанция.полныйRef)\n",
              корректнаяВетка(снимок.полныйRef),
              снимок.требуемыйOIDМанифеста == снимокOID(снимок) else {
            return .неизвестно
        }
        return квитанция.oid == снимок.требуемыйOIDМанифеста ? .подтверждено : .неизвестно
    }

    private static func снимокOID(_ снимок: СнимокДоставкиGit) -> String {
        gitOID(тип: "commit", raw: снимок.коммитДоставки)
    }

    private static func привязаноКБазе(_ доставка: СнимокДоставкиGit,
        исходныйСнимок: СнимокДоКоммитаGit) -> Bool {
        доставка.базовыйHEAD == исходныйСнимок.базовыйHEAD
            && доставка.rawКоммитHEAD == исходныйСнимок.rawКоммитHEAD
            && доставка.полныйRef == исходныйСнимок.полныйRef
            && доставка.индексTreeOID == исходныйСнимок.индексTreeOID
            && доставка.rawИндексTree == исходныйСнимок.rawИндексTree
            && доставка.изменённыеФайлы == исходныйСнимок.изменённыеФайлы
            && доставка.требуемыеФайлы == исходныйСнимок.требуемыеФайлы
            && доставка.разрешённыеПути == исходныйСнимок.разрешённыеПути
            && доставка.рабочийКаталог == исходныйСнимок.рабочийКаталог
            && доставка.sha256Профиля == исходныйСнимок.sha256Профиля
            && доставка.assignmentPin == исходныйСнимок.assignmentPin
            && доставка.версияСостояния == исходныйСнимок.версияСостояния
            && доставка.leaseДо == исходныйСнимок.leaseДо
            && доставка.именаRemote == исходныйСнимок.именаRemote
            && доставка.originURL == исходныйСнимок.originURL
            && доставка.источникАвторства == исходныйСнимок.источникАвторства
            && доставка.путьФайлаСообщения == исходныйСнимок.путьФайлаСообщения
            && доставка.байтыФайлаСообщения == исходныйСнимок.байтыФайлаСообщения
            && доставка.sha256ФайлаСообщения == исходныйСнимок.sha256ФайлаСообщения
            && доставка.авторGitСтрока == исходныйСнимок.авторGitСтрока
            && доставка.committerGitСтрока == исходныйСнимок.committerGitСтрока
    }

    private static func fence(снимок: СнимокДоКоммитаGit, забор: ЗаборGit, доCommit: Bool) -> Bool {
        забор.рабочийКаталог == снимок.рабочийКаталог
            && забор.head == снимок.базовыйHEAD && забор.полныйRef == снимок.полныйRef
            && забор.индексTreeOID == снимок.индексTreeOID
            && забор.sha256Профиля == снимок.sha256Профиля
            && забор.assignmentPin == снимок.assignmentPin
            && забор.версияСостояния == снимок.версияСостояния
            && забор.leaseДо == снимок.leaseДо && забор.момент < снимок.leaseДо
            && забор.именаRemote == снимок.именаRemote && забор.originURL == снимок.originURL
            && забор.источникАвторства == снимок.источникАвторства
            && забор.sha256ФайлаСообщения == снимок.sha256ФайлаСообщения
            && доCommit
    }

    private static func fence(снимок: СнимокДоставкиGit, забор: ЗаборGit) -> Bool {
        забор.рабочийКаталог == снимок.рабочийКаталог
            && забор.head == снимокOID(снимок) && забор.полныйRef == снимок.полныйRef
            && забор.индексTreeOID == снимок.индексTreeOID
            && забор.sha256Профиля == снимок.sha256Профиля
            && забор.assignmentPin == снимок.assignmentPin
            && забор.версияСостояния == снимок.версияСостояния
            && забор.leaseДо == снимок.leaseДо && забор.момент < снимок.leaseДо
            && забор.именаRemote == снимок.именаRemote && забор.originURL == снимок.originURL
            && забор.источникАвторства == снимок.источникАвторства
            && забор.sha256ФайлаСообщения == снимок.sha256ФайлаСообщения
    }

    private static func совпадаютФайлы(изменённые: [ФайлСнимкаGit], требуемые: [ФайлСнимкаGit],
        разрешённыеПути: [String]) -> Bool {
        let сортировка: ([ФайлСнимкаGit]) -> [ФайлСнимкаGit] = { $0.sorted { $0.путь < $1.путь } }
        return !изменённые.isEmpty && Set(разрешённыеПути).count == разрешённыеПути.count
            && разрешённыеПути.sorted() == профильныеПути.sorted()
            && требуемые.map(\.путь).sorted() == разрешённыеПути.sorted()
            && сортировка(изменённые) == сортировка(требуемые)
            && изменённые.allSatisfy { корректныйSHA256($0.sha256) && $0.размер > 0 }
    }

    private static func авторствоРазрешено(_ источник: ИсточникАвторстваGit,
        sha256Профиля: String, assignmentPin: String, момент: Date) -> Bool {
        switch источник.вид {
        case .свежаяАтрибуция:
            return !(источник.модель ?? "").isEmpty && !(источник.усилие ?? "").isEmpty
                && источник.наблюденоВ.map { $0 <= момент } == true
                && источник.свежеДо.map { момент < $0 } == true
                && источник.sha256Профиля == nil && источник.assignmentPin == nil
        case .явноеПоручениеБезАтрибуции:
            return источник.модель == nil && источник.усилие == nil
                && источник.наблюденоВ == nil && источник.свежеДо == nil
                && источник.sha256Профиля == sha256Профиля
                && источник.assignmentPin == assignmentPin
        }
    }

    private static func корректнаяВетка(_ ref: String) -> Bool {
        guard ref.hasPrefix("refs/heads/"), ref != "refs/heads/master",
              !ref.contains(".."), !ref.contains("//"), !ref.contains("@{"),
              !ref.hasSuffix("."), !ref.hasSuffix("/"), !ref.contains(":"), !ref.contains("\\") else {
            return false
        }
        guard ref.range(of: #"\Arefs/heads/[A-Za-z0-9._/-]+\z"#, options: .regularExpression) != nil else {
            return false
        }
        return ref.dropFirst("refs/heads/".count).split(separator: "/").allSatisfy {
            !$0.hasPrefix(".") && !$0.hasSuffix(".lock") && !$0.isEmpty
        }
    }

    private static func корректныйSHA256(_ sha: String) -> Bool {
        sha.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil
    }

    private static func gitOID(тип: String, raw: Data) -> String {
        var payload = Data("\(тип) \(raw.count)\0".utf8)
        payload.append(raw)
        return Insecure.SHA1.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256(_ raw: Data) -> String {
        SHA256.hash(data: raw).map { String(format: "%02x", $0) }.joined()
    }

    private static func разобратьCommit(_ raw: Data) -> ПоляRawCommit? {
        guard let text = String(data: raw, encoding: .utf8),
              let separator = text.range(of: "\n\n") else { return nil }
        let header = text[..<separator.lowerBound].split(separator: "\n", omittingEmptySubsequences: false)
        var tree: String?
        var parents: [String] = []
        var author: String?
        var committer: String?
        for line in header {
            if line.hasPrefix("tree ") { tree = String(line.dropFirst(5)) }
            else if line.hasPrefix("parent ") { parents.append(String(line.dropFirst(7))) }
            else if line.hasPrefix("author ") { author = String(line.dropFirst(7)) }
            else if line.hasPrefix("committer ") { committer = String(line.dropFirst(10)) }
            else { return nil }
        }
        guard let tree, корректныйOIDGit(tree), let author, let committer,
              parents.allSatisfy(корректныйOIDGit) else { return nil }
        return ПоляRawCommit(tree: tree, parents: parents, author: author,
            committer: committer, сообщение: Data(text[separator.upperBound...].utf8))
    }

    private static func разобратьИдентичность(_ line: String) -> (имя: String, email: String, дата: String)? {
        guard line.hasPrefix("author ") || line.hasPrefix("committer "),
              let left = line.firstIndex(of: "<"), let right = line[left...].firstIndex(of: ">") else { return nil }
        let nameStart = line.index(after: line.firstIndex(of: " ")!)
        let name = String(line[nameStart..<left]).trimmingCharacters(in: .whitespaces)
        let email = String(line[line.index(after: left)..<right])
        let dateParts = line[line.index(after: right)...].split(whereSeparator: \.isWhitespace)
        guard dateParts.count == 2, let timestamp = Int64(dateParts[0]),
              !name.isEmpty, email.contains("@"),
              dateParts[1].range(of: #"\A[+-][0-9]{4}\z"#, options: .regularExpression) != nil else { return nil }
        return (name, email, "\(timestamp) \(dateParts[1])")
    }

    private static func корректныйOIDGit(_ oid: String) -> Bool {
        oid.range(of: #"\A[0-9a-f]{40}\z"#, options: .regularExpression) != nil
    }

    /// Конечная точка воспроизведения: восстановить сохранённый профиль и вернуть
    /// только типизированную привязку для существующего адаптера.
    public static func воспроизвестиПланСохраненияИсходников(
        сохранённыйКонверт: Data?,
        ожидаемыйSHA256Профиля: String,
        текущийКонтекст: КонтекстВосстановленияПрофиля,
        решение: РешениеУзла,
        наблюдение: НаблюдениеУзла,
        запрос: ЗапросСвязыванияМанифеста,
        история: СнимокИсторииПривязок? = nil,
        разрешениеНеизвестногоЭффекта: РазрешениеНеизвестногоЭффекта? = nil,
        момент: Date
    ) -> ПланОтветаКоординатору {
        let восстановление = ВосстановлениеСохранённогоПрофиля.восстановить(
            сохранённыйКонверт, ожидаемыйSHA256: ожидаемыйSHA256Профиля,
            текущийКонтекст: текущийКонтекст)
        return сформироватьПланПослеВосстановления(восстановление: восстановление,
            решение: решение, наблюдение: наблюдение, запрос: запрос, история: история,
            разрешениеНеизвестногоЭффекта: разрешениеНеизвестногоЭффекта, момент: момент)
    }

    /// Публичный план проходит через восстановленный профиль. Неизвестный checker
    /// или потерянный снимок останавливает путь до выдачи плана адаптеру.
    public static func сформироватьПланПослеВосстановления(
        восстановление: РезультатВосстановленияПрофиля,
        решение: РешениеУзла,
        наблюдение: НаблюдениеУзла,
        запрос: ЗапросСвязыванияМанифеста,
        история: СнимокИсторииПривязок? = nil,
        разрешениеНеизвестногоЭффекта: РазрешениеНеизвестногоЭффекта? = nil,
        момент: Date
    ) -> ПланОтветаКоординатору {
        guard восстановление.статус == .восстановленДляПодготовки,
              let профиль = восстановление.профиль,
              профиль.проверяющийИзвестен,
              профиль.sha256 == ВосстановлениеСохранённогоПрофиля.sha256ЗакреплённогоСнимка,
              профиль.версия == "routine-delivery-profile.1",
              профиль.assignmentPin == "01a17797-519b-73c1-bcc8-fd295cdfe9b0",
              профиль.исключения.contains(.python),
              профиль.исключения.contains(.legacyRouter),
              профиль.исключения.contains(.legacyJournalDispatch),
              профиль.исключения.contains(.произвольныйShellИлиProcess),
              профиль.исключения.contains(.новыйRunnerИлиChecker),
              профиль.исключения.contains(.compilerTestRuntimeИлиSourceWriteStart),
              профиль.арендаДействуетДо > момент,
              case .известно(let версияПрофиля) = запрос.версияСостояния,
              версияПрофиля == профиль.версияСостояния,
              case .известно(let арендаПрофиля) = запрос.арендаДействуетДо,
              арендаПрофиля == профиль.арендаДействуетДо else {
            return ПланОтветаКоординатору(idРешения: решение.id, наблюдение: наблюдение,
                idПоручения: наблюдение.поручение.idЗнания, код: .неизвестныйГрантИлиНазначение,
                статус: .неизвестно,
                причины: восстановление.причины + ["сохранённый профиль не даёт проверенного разрешения до адаптера"],
                атрибуцияЗапроса: запрос.атрибуция, атрибуцияРешения: решение.атрибуция, связывание: nil)
        }
        return сформироватьПлан(решение: решение, наблюдение: наблюдение, запрос: запрос,
            история: история, разрешениеНеизвестногоЭффекта: разрешениеНеизвестногоЭффекта, момент: момент)
    }

    /// Внутренняя основа планирования; публичный путь требует восстановленный профиль.
    static func сформироватьПлан(
        решение: РешениеУзла,
        наблюдение: НаблюдениеУзла,
        запрос: ЗапросСвязыванияМанифеста,
        история: СнимокИсторииПривязок? = nil,
        разрешениеНеизвестногоЭффекта: РазрешениеНеизвестногоЭффекта? = nil,
        момент: Date
    ) -> ПланОтветаКоординатору {
        let idПоручения = наблюдение.поручение.idЗнания

        func результат(_ код: КодОтветаКоординатору, _ статус: СтатусОтветаКоординатору,
            _ причина: String, связывание: ПривязкаМанифестаДляАдаптера? = nil) -> ПланОтветаКоординатору {
            ПланОтветаКоординатору(idРешения: решение.id, наблюдение: наблюдение,
                idПоручения: idПоручения, код: код, статус: статус, причины: [причина],
                атрибуцияЗапроса: запрос.атрибуция, атрибуцияРешения: решение.атрибуция, связывание: связывание)
        }

        guard let снимокИстории = история else {
            return результат(.историяЭффектовНеизвестна, .неизвестно,
                "нет доверенного снимка истории эффектов; нельзя считать историю пустой")
        }
        let история = снимокИстории.записи

        guard решение.idНаблюдения == наблюдение.id,
              решение.idПоручения == idПоручения,
              решение.исходнаяВерсия == .известно(наблюдение.версияИсточника) else {
            return результат(.неизвестныйГрантИлиНазначение, .неизвестно, "решение не связано с текущим наблюдением")
        }
        guard решение.статус == .разрешено else {
            let статус: СтатусОтветаКоординатору = решение.статус == .отклонено ? .отказ : .удерживать
            return результат(.решениеНеРазрешаетЭффект, статус, "решение не разрешило связывание")
        }
        guard let свидетельство = запрос.снимок.свидетельство else {
            return результат(.проверяющийИсточникаНеизвестен, .неизвестно,
                "проверяющий источник не подключён; квитанция не подтверждена")
        }
        guard моментВПределахСвежести(момент, наблюдалосьВ: наблюдение.наблюдалосьВ, свежеДо: наблюдение.свежоДо),
              момент < свидетельство.свежеДо,
              свидетельство.провереноВ <= момент else {
            return результат(.устаревшиеСвидетельства, .неизвестно, "наблюдение или проверка источника устарели")
        }
        guard case .известно(let поручение) = наблюдение.поручение,
              решение.контекстПоручения == .известно(поручение),
              решение.ожидаемаяВерсияСостояния == поручение.ожидаемаяВерсияСостояния,
              решение.арендаДействуетДо == запрос.арендаДействуетДо,
              case .известно(let грант) = поручение.свидетельствоГранта,
              !грант.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              момент < поручение.грантДействуетДо,
              case .известно(let единственныйПисатель) = наблюдение.свидетельствоЕдинственногоПисателя,
              единственныйПисатель == поручение.владелец,
              case .известно(let исполнитель) = запрос.исполнитель,
              исполнитель == поручение.владелец,
              case .известно(let состояние) = наблюдение.состояние.версия,
              case .известно(let ожидаемое) = поручение.ожидаемаяВерсияСостояния,
              состояние == ожидаемое,
              запрос.версияСостояния == .известно(состояние),
              case .известно(let аренда) = запрос.арендаДействуетДо,
              момент < аренда, аренда <= поручение.грантДействуетДо,
              case .известно(let возможность) = запрос.возможностьАдаптера,
              возможность == .доступна else {
            let код: КодОтветаКоординатору
            if case .известно(.недоступна) = запрос.возможностьАдаптера { код = .адаптерНедоступен }
            else if case .неизвестно = запрос.возможностьАдаптера { код = .неизвестнаяВозможностьАдаптера }
            else { код = .неизвестныйГрантИлиНазначение }
            return результат(код, .неизвестно, "грант, назначение, авторизация писателя, версия или аренда не подтверждены")
        }
        guard case .известно(let действияУзла) = наблюдение.возможности, !действияУзла.isEmpty else {
            return результат(.неизвестнаяВозможностьАдаптера, .неизвестно, "возможности узла неизвестны")
        }
        guard запрос.снимок.путь == поручение.путьМанифеста,
              запрос.снимок.исходнаяСсылка == поручение.исходнаяСсылка,
              запрос.снимок.исходныйКоммит == поручение.исходныйКоммит,
              запрос.снимок.исходноеДерево == поручение.исходноеДерево else {
            return результат(.отказаноНесовпадениеБайтов, .отказ, "путь манифеста или источник не совпадает с назначением")
        }
        guard case .известно(let хэшНазначения) = поручение.sha256Манифеста,
              корректныйХэш(хэшНазначения), запрос.снимок.вычисленныйSHA256 == хэшНазначения,
              запрос.снимок.заявленныйSHA256 == хэшНазначения else {
            return результат(.отказаноНесовпадениеБайтов, .отказ, "сырые байты не совпадают с назначенным SHA-256")
        }
        guard свидетельство.результат == .пройдена,
              !свидетельство.версияПроверяющего.isEmpty,
              !свидетельство.проверяющий.isEmpty,
              case .известно(let квитанцияПроверки) = свидетельство.квитанция,
              !квитанцияПроверки.isEmpty,
              свидетельство.sha256ПроверенныхБайтов == хэшНазначения,
              свидетельство.провереннаяСсылка == поручение.исходнаяСсылка,
              свидетельство.проверенныйКоммит == поручение.исходныйКоммит,
              свидетельство.проверенноеДерево == поручение.исходноеДерево,
              свидетельство.проверенныеПути == запрос.снимок.записиПутей else {
            return результат(.проверяющийИсточникаНеизвестен, .неизвестно,
                "нет доверенного положительного свидетельства проверяющего источника")
        }
        let обязательные = поручение.обязательныеПути
        let отображённые = запрос.снимок.записиПутей.map(\.путь)
        let разрешённые = Set(поручение.разрешённыеПути)
        guard !обязательные.isEmpty,
              Set(обязательные).count == обязательные.count,
              Set(отображённые).count == отображённые.count,
              Set(отображённые) == Set(обязательные),
              отображённые.allSatisfy({ разрешённые.contains($0) }),
              запрос.снимок.записиПутей.allSatisfy({ корректныйХэш($0.sha256) }) else {
            return результат(.отказаноНесовпадениеПутей, .отказ, "точный набор путей не совпадает с поручением")
        }

        if let активнаяКоманда = история.first(where: { $0.исход.статус == .accepted || $0.исход.статус == .queued || $0.исход.статус == .running }) {
            return результат(.эффектЕщёНеЗавершён, .удерживать,
                "команда \(активнаяКоманда.idКоманды) принята, поставлена в очередь или исполняется; повтор запрещён")
        }
        let неизвестныеЭффекты = история.filter { $0.исход.статус == .unknown }
        for неизвестный in неизвестныеЭффекты {
            guard let разрешениеНеизвестного = разрешениеНеизвестногоЭффекта,
                  разрешениеНеизвестного.idКоманды == неизвестный.idКоманды,
                  разрешениеНеизвестного.владелец == поручение.владелец,
                  case .известно(let стараяВерсия) = неизвестный.исход.ожидаемаяВерсияСостояния,
                  case .известно(let версияПослеРазрешения) = разрешениеНеизвестного.версияСостоянияПослеРазрешения,
                  версияПослеРазрешения > стараяВерсия else {
                return результат(.неизвестныйЭффектНеПовторять, .эскалация,
                    "неизвестный эффект команды \(неизвестный.idКоманды) требует терминального исхода или подтверждённого ограждения")
            }
            switch разрешениеНеизвестного.основание {
            case .терминальныйИсход:
                guard case .известно(let терминальныйИсход) = разрешениеНеизвестного.терминальныйИсход,
                      терминальныйИсход.idКоманды == неизвестный.idКоманды,
                      терминальныйИсход.владелец == поручение.владелец,
                      терминальныйИсход.ожидаемаяВерсияСостояния == неизвестный.исход.ожидаемаяВерсияСостояния,
                      терминальныйИсход.статус == .completed || терминальныйИсход.статус == .failed,
                      терминальныйИсход.наблюдаемаяВерсияСостояния == .известно(версияПослеРазрешения),
                      терминальныйИсход.наблюдалосьВ >= неизвестный.исход.наблюдалосьВ,
                      терминальныйИсход.наблюдалосьВ <= момент,
                      case .известно(let квитанцияИсхода) = терминальныйИсход.свидетельствоИлиКвитанция,
                      !квитанцияИсхода.isEmpty else {
                    return результат(.неизвестныйЭффектНеПовторять, .эскалация,
                        "терминальное разрешение не содержит связанный квитированный исход команды")
                }
            case .подтверждённоеОграждение:
                guard case .известно(let ограждение) = разрешениеНеизвестного.свидетельствоОграждения,
                      ограждение.idКоманды == неизвестный.idКоманды,
                      ограждение.владелец == поручение.владелец,
                      ограждение.ожидаемаяВерсияСостояния == стараяВерсия,
                      ограждение.версияПослеОграждения == версияПослеРазрешения,
                      ограждение.исключаетБудущиеЭффекты,
                      !ограждение.квитанция.isEmpty else {
                    return результат(.неизвестныйЭффектНеПовторять, .эскалация,
                        "свидетельство не подтверждает ограждение всех будущих эффектов старой команды")
                }
            }
        }
        let завершённыеПривязки = история.filter {
            $0.idПоручения == поручение.id && $0.sha256Манифеста == хэшНазначения && $0.исход.статус == .completed
        }
        for завершённаяПривязка in завершённыеПривязки {
            guard завершённаяПривязка.исход.idКоманды == завершённаяПривязка.idКоманды,
                  завершённаяПривязка.исход.владелец == поручение.владелец,
                  case .известно(let исходнаяКвитанция) = завершённаяПривязка.исход.свидетельствоИлиКвитанция,
                  !исходнаяКвитанция.isEmpty,
                  case .известно(let квитанция) = завершённаяПривязка.квитанция,
                  !квитанция.isEmpty else {
                return результат(.неизвестныйЭффектНеПовторять, .неизвестно,
                    "история сообщает completed без проверяемой квитанции; новая запись запрещена")
            }
        }
        if let ужеВыполненнаяПривязка = завершённыеПривязки.first {
            return результат(.ужеВыполнено, .ужеВыполнено,
                "та же привязка манифеста уже завершена по команде \(ужеВыполненнаяПривязка.idКоманды); новая запись не создаётся")
        }
        if let завершившаясяКоманда = история.first(where: { $0.исход.статус == .failed }) {
            guard case .известно(let прежняяВерсияСостояния) = завершившаясяКоманда.исход.ожидаемаяВерсияСостояния,
                  состояние > прежняяВерсияСостояния else {
                return результат(.эффектЕщёНеЗавершён, .удерживать, "терминальный отказ не подтверждён новой версией состояния")
            }
        }

        guard case .известно(let авторЗапроса) = запрос.автор else {
            // Неизвестная атрибуция сохраняется и не меняет полномочия.
            let связывание = создатьСвязывание(запрос: запрос, поручение: поручение, версияСостояния: состояние,
                аренда: аренда, грант: грант, исполнитель: исполнитель, пути: запрос.снимок.записиПутей,
                хэш: хэшНазначения, квитанция: квитанцияПроверки,
                версияПроверяющего: свидетельство.версияПроверяющего)
            return результат(.подготовитьСвязываниеМанифеста, .планГотов,
                "план привязан к назначению; автор запроса остаётся неизвестным: \(причинаНеизвестного(запрос.автор))", связывание: связывание)
        }
        guard !авторЗапроса.isEmpty else {
            return результат(.авторНекорректен, .неизвестно, "пустая строка автора не является подтверждённой атрибуцией")
        }
        let связывание = создатьСвязывание(запрос: запрос, поручение: поручение, версияСостояния: состояние,
            аренда: аренда, грант: грант, исполнитель: исполнитель, пути: запрос.снимок.записиПутей,
            хэш: хэшНазначения, квитанция: квитанцияПроверки,
            версияПроверяющего: свидетельство.версияПроверяющего)
        return результат(.подготовитьСвязываниеМанифеста, .планГотов,
            "точный манифест связан с действующим поручением; эффект остаётся у адаптера", связывание: связывание)
    }

    private static func создатьСвязывание(запрос: ЗапросСвязыванияМанифеста, поручение: КонтекстПорученияУзла,
        версияСостояния: UInt64, аренда: Date, грант: String, исполнитель: String,
        пути: [ЗаписьПутиМанифеста], хэш: String, квитанция: String,
        версияПроверяющего: String) -> ПривязкаМанифестаДляАдаптера {
        ПривязкаМанифестаДляАдаптера(запрос: запрос, поручение: поручение,
            версияСостояния: версияСостояния, аренда: аренда, грант: грант, исполнитель: исполнитель,
            пути: пути.sorted { $0.путь < $1.путь }, shaМанифеста: хэш, квитанция: квитанция,
            версияПроверяющегоИсточника: версияПроверяющего)
    }

    private static func моментВПределахСвежести(_ момент: Date, наблюдалосьВ: Date, свежеДо: Date) -> Bool {
        наблюдалосьВ <= момент && момент < свежеДо
    }

    private static func корректныйХэш(_ значение: String) -> Bool {
        значение.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil
    }

    private static func причинаНеизвестного(_ значение: Знание<String>) -> String {
        switch значение {
        case .известно: return ""
        case .неизвестно(let причина): return причина
        }
    }
}

private extension Знание where Value == UUID {
    var idЗнания: Знание<UUID> { self }
}

private extension Знание where Value == КонтекстПорученияУзла {
    var idЗнания: Знание<UUID> {
        switch self {
        case .известно(let поручение): .известно(поручение.id)
        case .неизвестно(let причина): .неизвестно(причина: причина)
        }
    }
}
