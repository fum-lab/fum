import Foundation

public struct ОтветСпискаПотоков: Decodable, Sendable {
  let версияСхемы: Int?
  let закреплённыеПотоки: [ЗаписьПотока]?
  let обычныеПотоки: [ЗаписьПотока]?
  let числоНедоступныхХостов: Int?
  let числоНедоступныхИсточников: Int?

  private enum Ключи: String, CodingKey {
    case schemaVersion, pinnedThreads, threads, unavailableHosts, unavailableSources
  }

  public init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    версияСхемы = try? поля.decode(Int.self, forKey: .schemaVersion)
    закреплённыеПотоки = try? поля.decode([ЗаписьПотока].self, forKey: .pinnedThreads)
    обычныеПотоки = try? поля.decode([ЗаписьПотока].self, forKey: .threads)
    числоНедоступныхХостов =
      (try? поля.decode([ЗначениеJSON].self, forKey: .unavailableHosts))?.count
    числоНедоступныхИсточников =
      (try? поля.decode([ЗначениеJSON].self, forKey: .unavailableSources))?.count
  }
}

public struct ОтветОжиданияПотоков: Decodable, Sendable {
  let истеклоВремя: Bool?
  let опросы: [ОпросПотока]?
  let числоОшибок: Int?

  private enum Ключи: String, CodingKey { case timedOut, polls, errors }

  public init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    истеклоВремя = try? поля.decode(Bool.self, forKey: .timedOut)
    опросы = try? поля.decode([ОпросПотока].self, forKey: .polls)
    числоОшибок = (try? поля.decode([ЗначениеJSON].self, forKey: .errors))?.count
  }
}

struct ЗаписьПотока: Decodable, Sendable {
  let id: String?
  let hostID: String?
  let статус: СтатусПотока?

  private enum Ключи: String, CodingKey { case id, hostId, status }

  init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    id = try? поля.decode(String.self, forKey: .id)
    hostID = try? поля.decode(String.self, forKey: .hostId)
    статус = try? поля.decode(СтатусПотока.self, forKey: .status)
  }
}

struct СтатусПотока: Decodable, Sendable {
  let тип: String?
  let активныеФлаги: [String]

  private enum Ключи: String, CodingKey { case type, activeFlags }

  init(from декодер: Decoder) throws {
    if let single = try? декодер.singleValueContainer(),
      let строка = try? single.decode(String.self)
    {
      тип = строка
      активныеФлаги = []
      return
    }
    let поля = try декодер.container(keyedBy: Ключи.self)
    тип = try? поля.decode(String.self, forKey: .type)
    активныеФлаги = (try? поля.decode([String].self, forKey: .activeFlags)) ?? []
  }
}

struct ОпросПотока: Decodable, Sendable {
  let версияСхемы: Int?
  let поток: ЗаписьПотока?
  let последнийХод: СостояниеХода?
  let последнееСообщение: ФазаСообщения?
  let последнийИнструмент: МаркерИнструмента?

  private enum Ключи: String, CodingKey {
    case schemaVersion, thread, latestTurn, latestAssistantMessage, latestToolMarker
  }

  init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    версияСхемы = try? поля.decode(Int.self, forKey: .schemaVersion)
    поток = try? поля.decode(ЗаписьПотока.self, forKey: .thread)
    последнийХод = try? поля.decode(СостояниеХода.self, forKey: .latestTurn)
    последнееСообщение = try? поля.decode(ФазаСообщения.self, forKey: .latestAssistantMessage)
    последнийИнструмент = try? поля.decode(МаркерИнструмента.self, forKey: .latestToolMarker)
  }
}

struct СостояниеХода: Decodable, Sendable {
  let id: String?
  let статус: String?

  private enum Ключи: String, CodingKey { case id, status }

  init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    id = try? поля.decode(String.self, forKey: .id)
    статус = try? поля.decode(String.self, forKey: .status)
  }
}

struct ФазаСообщения: Decodable, Sendable {
  let ходID: String?
  let фаза: String?

  private enum Ключи: String, CodingKey { case turnId, phase }

  init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    ходID = try? поля.decode(String.self, forKey: .turnId)
    фаза = try? поля.decode(String.self, forKey: .phase)
  }
}

struct МаркерИнструмента: Decodable, Sendable {
  let имя: String?
  let статус: String?

  private enum Ключи: String, CodingKey { case name, status }

  init(from декодер: Decoder) throws {
    let поля = try декодер.container(keyedBy: Ключи.self)
    имя = try? поля.decode(String.self, forKey: .name)
    статус = try? поля.decode(String.self, forKey: .status)
  }
}

private indirect enum ЗначениеJSON: Decodable, Sendable {
  case пусто
  case логическое
  case число
  case строка
  case массив([ЗначениеJSON])
  case объект([String: ЗначениеJSON])

  init(from декодер: Decoder) throws {
    let одиночное = try декодер.singleValueContainer()
    if одиночное.decodeNil() {
      self = .пусто
    } else if (try? одиночное.decode(Bool.self)) != nil {
      self = .логическое
    } else if (try? одиночное.decode(Int64.self)) != nil
      || (try? одиночное.decode(Double.self)) != nil
    {
      self = .число
    } else if (try? одиночное.decode(String.self)) != nil {
      self = .строка
    } else if let массив = try? одиночное.decode([ЗначениеJSON].self) {
      self = .массив(массив)
    } else if let объект = try? одиночное.decode([String: ЗначениеJSON].self) {
      self = .объект(объект)
    } else {
      throw DecodingError.dataCorruptedError(
        in: одиночное, debugDescription: "Неизвестное JSON-значение")
    }
  }
}

public enum АдаптерИнструментовCodex {
  private static let пределБайтов = 1_048_576

  public static func декодироватьСписок(
    данные: Data, at время: Date, лимит: Int, ошибкаИнструмента: Bool = false
  ) -> ЗахватСписка {
    guard данные.count <= пределБайтов else {
      return ЗахватСписка(
        ответ: ЗахватОтвета(
          доступность: .превышенРазмер, значение: nil, доступныеБайты: данные.count,
          наблюдалось: время),
        лимит: лимит
      )
    }
    if ошибкаИнструмента {
      return ЗахватСписка(
        ответ: ЗахватОтвета(
          доступность: .ошибка, значение: nil, доступныеБайты: данные.count,
          наблюдалось: время),
        лимит: лимит
      )
    }
    let декодер = JSONDecoder()
    do {
      let ответ = try декодер.decode(ОтветСпискаПотоков.self, from: данные)
      let всеСтраницыЕсть = ответ.версияСхемы == 1
        && ответ.закреплённыеПотоки != nil && ответ.обычныеПотоки != nil
        && ответ.числоНедоступныхХостов != nil && ответ.числоНедоступныхИсточников != nil
      let доступность: ДоступностьОтвета = всеСтраницыЕсть ? .доступно : .страницаОтсутствует
      return ЗахватСписка(
        ответ: ЗахватОтвета(
          доступность: доступность, значение: ответ, доступныеБайты: данные.count,
          наблюдалось: время),
        лимит: лимит
      )
    } catch {
      return ЗахватСписка(
        ответ: ЗахватОтвета(
          доступность: .неверныйОтвет, значение: nil, доступныеБайты: данные.count,
          наблюдалось: время),
        лимит: лимит
      )
    }
  }

  public static func декодироватьОжидание(
    данные: Data, at время: Date, ошибкаИнструмента: Bool = false
  ) -> ЗахватОтвета<ОтветОжиданияПотоков> {
    guard данные.count <= пределБайтов else {
      return ЗахватОтвета(
        доступность: .превышенРазмер, значение: nil, доступныеБайты: данные.count,
        наблюдалось: время)
    }
    if ошибкаИнструмента {
      return ЗахватОтвета(
        доступность: .ошибка, значение: nil, доступныеБайты: данные.count,
        наблюдалось: время)
    }
    let декодер = JSONDecoder()
    do {
      let ответ = try декодер.decode(ОтветОжиданияПотоков.self, from: данные)
      let доступность: ДоступностьОтвета =
        ответ.истеклоВремя != nil && ответ.опросы != nil ? .доступно : .страницаОтсутствует
      return ЗахватОтвета(
        доступность: доступность, значение: ответ, доступныеБайты: данные.count,
        наблюдалось: время)
    } catch {
      return ЗахватОтвета(
        доступность: .неверныйОтвет, значение: nil, доступныеБайты: данные.count,
        наблюдалось: время)
    }
  }
}
