import Foundation

public enum ВидУзла: String, Codable, Hashable, Sendable {
  case поток = "поток"
  case эфемерныйАгент = "эфемерный-агент"
}

public struct УзелНаблюдения: Codable, Hashable, Sendable {
  public let вид: ВидУзла
  public let значение: String
  public let hostID: String?

  private init(вид: ВидУзла, значение: String, hostID: String?) {
    self.вид = вид
    self.значение = значение
    self.hostID = hostID
  }

  public static func поток(_ идентификатор: UUID, hostID: String) -> Self {
    Self(вид: .поток, значение: идентификатор.uuidString.lowercased(), hostID: hostID)
  }

  public static func агент(_ идентификатор: String) -> Self {
    Self(вид: .эфемерныйАгент, значение: идентификатор, hostID: nil)
  }

  public var uuid: UUID? {
    guard вид == .поток else { return nil }
    return UUID(uuidString: значение)
  }
}

public struct ОжидаемыйУзел: Codable, Equatable, Sendable {
  public let идентификатор: УзелНаблюдения
  public let репозиторий: String?
  public let корень: UUID?
  public let родитель: УзелНаблюдения?
  public let предки: [УзелНаблюдения]
  public let линияИзвестна: Bool

  public init(
    идентификатор: УзелНаблюдения, репозиторий: String?, корень: UUID?,
    родитель: УзелНаблюдения?, предки: [УзелНаблюдения], линияИзвестна: Bool
  ) {
    self.идентификатор = идентификатор
    self.репозиторий = репозиторий
    self.корень = корень
    self.родитель = родитель
    self.предки = предки
    self.линияИзвестна = линияИзвестна
  }
}

public enum ДоступностьОтвета: String, Codable, Equatable, Sendable, CaseIterable {
  case доступно = "доступно"
  case ошибка = "ошибка"
  case неЗагружено = "не-загружено"
  case страницаОтсутствует = "страница-отсутствует"
  case неверныйОтвет = "неверный-ответ"
  case превышенРазмер = "превышен-размер"
}

public struct ЗахватОтвета<Ответ: Sendable>: Sendable {
  public let доступность: ДоступностьОтвета
  public let значение: Ответ?
  public let доступныеБайты: Int
  public let наблюдалось: Date

  public init(
    доступность: ДоступностьОтвета, значение: Ответ?, доступныеБайты: Int,
    наблюдалось: Date
  ) {
    self.доступность = доступность
    self.значение = значение
    self.доступныеБайты = доступныеБайты
    self.наблюдалось = наблюдалось
  }
}

public struct ЗахватСписка: Sendable {
  public let ответ: ЗахватОтвета<ОтветСпискаПотоков>
  public let лимит: Int

  public init(ответ: ЗахватОтвета<ОтветСпискаПотоков>, лимит: Int) {
    self.ответ = ответ
    self.лимит = лимит
  }
}

public struct ЗапросОжидания: Sendable {
  public let вызывающийУзел: УзелНаблюдения
  public let цели: [УзелНаблюдения]
  public let timeoutМС: Int

  public init(
    вызывающийУзел: УзелНаблюдения, цели: [УзелНаблюдения], timeoutМС: Int
  ) throws {
    guard (0...120_000).contains(timeoutМС) else {
      throw ОшибкаСнимка.недопустимоеОкноОжидания
    }
    var уникальные: [УзелНаблюдения] = []
    var ужеДобавленные: Set<УзелНаблюдения> = []
    for цель in цели {
      let совпалСобственныйПоток = цель.вид == .поток
        && вызывающийУзел.вид == .поток
        && цель.uuid != nil && цель.uuid == вызывающийУзел.uuid
      guard цель != вызывающийУзел, !совпалСобственныйПоток else {
        throw ОшибкаСнимка.ожиданиеСобственногоУзла
      }
      if ужеДобавленные.insert(цель).inserted { уникальные.append(цель) }
    }
    self.вызывающийУзел = вызывающийУзел
    self.цели = уникальные
    self.timeoutМС = timeoutМС
  }
}

public struct ЗахватОжидания: Sendable {
  public let запрос: ЗапросОжидания
  public let ответ: ЗахватОтвета<ОтветОжиданияПотоков>

  public init(запрос: ЗапросОжидания, ответ: ЗахватОтвета<ОтветОжиданияПотоков>) {
    self.запрос = запрос
    self.ответ = ответ
  }
}

public struct НаблюдениеЭфемерногоАгента: Sendable {
  public let идентификатор: УзелНаблюдения
  public let состояние: String
  public let наблюдалось: Date
  public let репозиторий: String?
  public let корень: UUID?
  public let родитель: УзелНаблюдения?
  public let предки: [УзелНаблюдения]
  public let доступныеБайты: Int

  public init(
    идентификатор: УзелНаблюдения, состояние: String, наблюдалось: Date,
    репозиторий: String?, корень: UUID?, родитель: УзелНаблюдения?,
    предки: [УзелНаблюдения], доступныеБайты: Int = 0
  ) {
    self.идентификатор = идентификатор
    self.состояние = состояние
    self.наблюдалось = наблюдалось
    self.репозиторий = репозиторий
    self.корень = корень
    self.родитель = родитель
    self.предки = предки
    self.доступныеБайты = доступныеБайты
  }
}

public struct ЗапросСнимка: Sendable {
  public let репозиторий: String
  public let корень: UUID
  public let вызывающийУзел: УзелНаблюдения
  public let версия: Int
  public let времяСоздания: Date
  public let пределУстареванияСекунд: TimeInterval
  public let пределОжиданийМС: Int
  public let пределЗаписей: Int
  public let ожидаемыеУзлы: [ОжидаемыйУзел]
  public let предыдущийСнимок: СнимокНаблюдений?

  public init(
    репозиторий: String, корень: UUID, вызывающийУзел: УзелНаблюдения,
    версия: Int, времяСоздания: Date, пределУстареванияСекунд: TimeInterval,
    пределОжиданийМС: Int, пределЗаписей: Int, ожидаемыеУзлы: [ОжидаемыйУзел],
    предыдущийСнимок: СнимокНаблюдений? = nil
  ) throws {
    guard !репозиторий.isEmpty, репозиторий.utf8.count <= 512, версия > 0,
      времяСоздания.timeIntervalSince1970.isFinite,
      пределУстареванияСекунд.isFinite, пределУстареванияСекунд >= 0,
      (0...120_000).contains(пределОжиданийМС), (1...10_000).contains(пределЗаписей),
      ожидаемыеУзлы.count <= пределЗаписей
    else { throw ОшибкаСнимка.неверныеПределы }
    if let предыдущийСнимок {
      guard предыдущийСнимок.корень == корень,
        предыдущийСнимок.репозиторий == репозиторий,
        предыдущийСнимок.версия < версия
      else { throw ОшибкаСнимка.версияНеВозрастает }
    }
    self.репозиторий = репозиторий
    self.корень = корень
    self.вызывающийУзел = вызывающийУзел
    self.версия = версия
    self.времяСоздания = времяСоздания
    self.пределУстареванияСекунд = пределУстареванияСекунд
    self.пределОжиданийМС = пределОжиданийМС
    self.пределЗаписей = пределЗаписей
    self.ожидаемыеУзлы = ожидаемыеУзлы
    self.предыдущийСнимок = предыдущийСнимок
  }
}

public enum СмысловойСтатус: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
  case активенПоAPI = "активен-по-api"
  case выполняется = "выполняется"
  case содержательнаяРабота = "содержательная-работа"
  case ожиданиеИнструмента = "ожидание-инструмента"
  case ожиданиеДочернегоУзла = "ожидание-дочернего-узла"
  case ожиданиеЧеловека = "ожидание-человека"
  case готовКПередаче = "готов-к-передаче"
  case приостановлен = "приостановлен"
  case отменён = "отменён"
  case завершён = "завершён"
  case сбой = "сбой"
  case ограниченЁмкостью = "ограничен-ёмкостью"
  case устарел = "устарел"
  case неизвестно = "неизвестно"
  case конфликт = "конфликт"
}

public enum ИсточникЗаписи: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
  case закреплённыйСписокПотоков = "закреплённый-список-потоков"
  case обычныйСписокПотоков = "обычный-список-потоков"
  case ограниченноеОжиданиеПотоков = "ограниченное-ожидание-потоков"
  case эфемерныйАгент = "эфемерный-агент"
  case предыдущийСнимок = "предыдущий-снимок"
  case оценкаПокрытия = "оценка-покрытия"
}

public struct СвидетельствоЗаписи: Codable, Equatable, Sendable {
  public let источник: ИсточникЗаписи
  public let наблюдалось: Date
  public let версия: Int

  public init(источник: ИсточникЗаписи, наблюдалось: Date, версия: Int) {
    self.источник = источник
    self.наблюдалось = наблюдалось
    self.версия = версия
  }
}

public struct ЗаписьСнимка: Codable, Equatable, Sendable {
  public let идентификатор: УзелНаблюдения
  public let репозиторий: String?
  public let корень: UUID?
  public let родитель: УзелНаблюдения?
  public let предки: [УзелНаблюдения]
  public let линияИзвестна: Bool
  public let наблюдалось: Date
  public let источники: [ИсточникЗаписи]
  public let свидетельства: [СвидетельствоЗаписи]
  public let версия: Int
  public let статусы: [СмысловойСтатус]
  public let предыдущиеСтатусы: [СмысловойСтатус]

  public init(
    идентификатор: УзелНаблюдения, репозиторий: String?, корень: UUID?,
    родитель: УзелНаблюдения?, предки: [УзелНаблюдения], линияИзвестна: Bool,
    наблюдалось: Date, источники: [ИсточникЗаписи], свидетельства: [СвидетельствоЗаписи] = [],
    версия: Int,
    статусы: [СмысловойСтатус], предыдущиеСтатусы: [СмысловойСтатус] = []
  ) {
    self.идентификатор = идентификатор
    self.репозиторий = репозиторий
    self.корень = корень
    self.родитель = родитель
    self.предки = предки
    self.линияИзвестна = линияИзвестна
    self.наблюдалось = наблюдалось
    self.источники = источники
    self.свидетельства = свидетельства
    self.версия = версия
    self.статусы = статусы
    self.предыдущиеСтатусы = предыдущиеСтатусы
  }
}

public enum СостояниеПокрытия: String, Codable, Equatable, Sendable {
  case ограниченное = "ограниченное"
  case неполное = "неполное"
  case неизвестное = "неизвестное"
}

public struct ПокрытиеСнимка: Codable, Equatable, Sendable {
  public let доступностьСписка: ДоступностьОтвета
  public let доступностиОжиданий: [ДоступностьОтвета]
  public let недостающиеОжидаемыеУзлы: [УзелНаблюдения]
  public let достигнутЛимитОбычногоСписка: Bool
  public let пропущеноИсточников: Int
  public let пропущеноХостов: Int
  public let неверныхИдентификаторов: Int
  public let неверныхОпросов: Int
  public let строкВнеОбласти: Int
  public let неадресныхОпросов: Int
  public let пустыхСнимковОжидания: Int
  public let истеклоОжиданий: Int
  public let ошибокОжиданий: Int
  public let полнота: СостояниеПокрытия
}

/// Счётчики отражают проходы по входным и выходным записям; это не оценка CPU.
public struct СчётчикиНаблюдения: Codable, Equatable, Sendable {
  public let строкСпискаПрочитано: Int
  public let опросовПрочитано: Int
  public let целейОжиданияПрочитано: Int
  public let ожидаемыхУзловПрочитано: Int
  public let связейЛинииПрочитано: Int
  public let предыдущихЗаписейПрочитано: Int
  public let эфемерныхАгентовПрочитано: Int
  public let записейСнимка: Int
  public let операций: Int
  public let доступныхБайтов: Int
}

public struct СнимокНаблюдений: Codable, Equatable, Sendable {
  public let репозиторий: String
  public let корень: UUID
  public let версия: Int
  public let создано: Date
  public let записи: [ЗаписьСнимка]
  public let покрытие: ПокрытиеСнимка
  public let счётчики: СчётчикиНаблюдения

  public init(
    репозиторий: String, корень: UUID, версия: Int, создано: Date,
    записи: [ЗаписьСнимка], покрытие: ПокрытиеСнимка, счётчики: СчётчикиНаблюдения
  ) {
    self.репозиторий = репозиторий
    self.корень = корень
    self.версия = версия
    self.создано = создано
    self.записи = записи
    self.покрытие = покрытие
    self.счётчики = счётчики
  }

  public func форматированныйJSON() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    var bytes = try encoder.encode(self)
    if bytes.last != 0x0A { bytes.append(0x0A) }
    return bytes
  }
}

public enum ОшибкаСнимка: Error, Equatable, Sendable {
  case ожиданиеСобственногоУзла
  case недопустимоеОкноОжидания
  case неверныеПределы
  case неверныйИдентификатор
  case повторОжидаемогоУзла
  case невернаяЛиния
  case версияНеВозрастает
  case превышенПределЗаписей
  case превышенПределБайтов
  case превышенПределОжиданий
  case переполнениеСчётчика
}
