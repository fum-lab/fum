import CryptoKit
import Foundation
import FUMStructuringOperatorMemory

public struct ИдентификаторОкнаВвода: Hashable, Sendable {
  public let rawValue: UUID

  public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct ИдентификаторФокусаВвода: Hashable, Sendable {
  public let rawValue: UUID

  public init(rawValue: UUID) { self.rawValue = rawValue }
}

/// Идентификатор передаётся от владельца интерфейса без вывода раскладки из системных настроек.
public struct ИдентификаторРаскладкиКлавиатуры: RawRepresentable, Codable, Hashable, Sendable {
  public let rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }

  public static let qwerty = Self(rawValue: "qwerty")
  public static let dvorak = Self(rawValue: "dvorak")
  public static let colemak = Self(rawValue: "colemak")
  public static let azerty = Self(rawValue: "azerty")
  public static let qwertz = Self(rawValue: "qwertz")
  public static let qzerty = Self(rawValue: "qzerty")
}

public enum ФазаФизическойКлавиши: String, Codable, Equatable, Sendable {
  case нажатие
  case отпускание
  case прикосновение
}

public struct ФизическоеСобытиеКлавиатуры: Equatable, Sendable {
  /// Нативный край передаёт код без преобразования или таблицы в адаптере.
  public let код: Int64
  public let фаза: ФазаФизическойКлавиши
  public let повтор: Bool
  public let раскладка: ИдентификаторРаскладкиКлавиатуры

  public init(
    код: Int64,
    фаза: ФазаФизическойКлавиши,
    повтор: Bool,
    раскладка: ИдентификаторРаскладкиКлавиатуры
  ) {
    self.код = код
    self.фаза = фаза
    self.повтор = повтор
    self.раскладка = раскладка
  }
}

public enum СостояниеКомпозицииIME: Equatable, Sendable {
  case обычно
  case составляется(UUID)
}

public enum СобытиеIME: Equatable, Sendable {
  case начать(идентификатор: UUID)
  case обновить(идентификатор: UUID, помеченныйТекст: String)
  case зафиксировать(идентификатор: UUID, текст: String)
  case отменить(идентификатор: UUID)
}

public struct СостояниеМодификаторовКлавиатуры: Codable, Equatable, Sendable {
  public let сдвигСлева: Bool
  public let сдвигСправа: Bool
  public let опцияСлева: Bool
  public let опцияСправа: Bool
  public let командаСлева: Bool
  public let командаСправа: Bool
  public let смешаннаяПоследовательность: Bool

  public init(
    сдвигСлева: Bool,
    сдвигСправа: Bool,
    опцияСлева: Bool,
    опцияСправа: Bool,
    командаСлева: Bool,
    командаСправа: Bool,
    смешаннаяПоследовательность: Bool
  ) {
    self.сдвигСлева = сдвигСлева
    self.сдвигСправа = сдвигСправа
    self.опцияСлева = опцияСлева
    self.опцияСправа = опцияСправа
    self.командаСлева = командаСлева
    self.командаСправа = командаСправа
    self.смешаннаяПоследовательность = смешаннаяПоследовательность
  }

  public static let пустое = Self(
    сдвигСлева: false,
    сдвигСправа: false,
    опцияСлева: false,
    опцияСправа: false,
    командаСлева: false,
    командаСправа: false,
    смешаннаяПоследовательность: false
  )

  private enum CodingKeys: String, CodingKey {
    case сдвигСлева = "сдвиг_слева"
    case сдвигСправа = "сдвиг_справа"
    case опцияСлева = "опция_слева"
    case опцияСправа = "опция_справа"
    case командаСлева = "команда_слева"
    case командаСправа = "команда_справа"
    case смешаннаяПоследовательность = "смешанная_последовательность"
  }
}

public enum ИсточникТекстаКлавиатуры: String, Equatable, Sendable {
  case fuma
  case ime
}

public enum ВыводКлавиатурыОкна: Equatable, Sendable {
  case текст(String, источник: ИсточникТекстаКлавиатуры)
  case команда(String)
  case нет
}

public enum СтатусВводаКлавиатурыОкна: Equatable, Sendable {
  case обработано
  case проигнорировано
  case раскладкаНеПроверена
}

public struct РезультатВводаКлавиатурыОкна: Sendable {
  public let статус: СтатусВводаКлавиатурыОкна
  public let раскладка: ИдентификаторРаскладкиКлавиатуры?
  public let вывод: ВыводКлавиатурыОкна
  public let состояние: СостояниеМодификаторовКлавиатуры
  /// Нативное наблюдение FUMA для физического перехода; у IME commit его нет.
  public let трасса: НаблюдениеОператора?
}

/// Неизменяемая связь существующего определения и QWERTY-таблицы с первичным Keyboard.
public struct ПривязкаРаскладкиKeyboard: Equatable, Sendable {
  public let идентификаторРаскладки: ИдентификаторРаскладкиКлавиатуры
  public let идентификаторОператора: String
  public let версияОператора: Int
  public let хэшОпределения: String
  public let схемаТаблицы: String
  public let хэшТаблицы: String
  public let upstreamКоммит: String
  public let upstreamTree: String
  public let upstreamПутьТаблицы: String
  public let upstreamBlobЛицензии: String

  private init(
    идентификаторРаскладки: ИдентификаторРаскладкиКлавиатуры,
    идентификаторОператора: String,
    версияОператора: Int,
    хэшОпределения: String,
    схемаТаблицы: String,
    хэшТаблицы: String,
    upstreamКоммит: String,
    upstreamTree: String,
    upstreamПутьТаблицы: String,
    upstreamBlobЛицензии: String
  ) {
    self.идентификаторРаскладки = идентификаторРаскладки
    self.идентификаторОператора = идентификаторОператора
    self.версияОператора = версияОператора
    self.хэшОпределения = хэшОпределения
    self.схемаТаблицы = схемаТаблицы
    self.хэшТаблицы = хэшТаблицы
    self.upstreamКоммит = upstreamКоммит
    self.upstreamTree = upstreamTree
    self.upstreamПутьТаблицы = upstreamПутьТаблицы
    self.upstreamBlobЛицензии = upstreamBlobЛицензии
  }

  public static let keyboardQwertyV1 = Self(
    идентификаторРаскладки: .qwerty,
    идентификаторОператора: "переход-раскладки-Klaviatura",
    версияОператора: 1,
    хэшОпределения: "6deb8aed4b93b7d2528e26df041da8314b9a9cc433483a2c44611b7585f7b4ac",
    схемаТаблицы: "klaviatura.таблица.1",
    хэшТаблицы: "c914755f50b27da2b8d6d56cbdaaeb7db6f74ae2ab84d8f294eee4d6243f4ac3",
    upstreamКоммит: "7495174d91571f98e75db4e615da8a3799868f2e",
    upstreamTree: "a2f7c5cf84cfa446b3243aa6952ca28f6f7acf2e",
    upstreamПутьТаблицы: "KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.qwerty.swift",
    upstreamBlobЛицензии: "0e259d42c996742e9e3cba14c677129b2c1b6311"
  )
}

public enum ОшибкаАдаптераВводаОкна: Error, Equatable {
  case несовпавшийХэшОпределения(ожидалось: String, получено: String)
  case несовпавшийХэшТаблицы(ожидалось: String, получено: String)
  case несовпавшееОпределениеОператора
  case несовпавшаяТаблица
  case неверныйФорматГрафа
  case неизвестныйРезультатГрафа
}

/// Адаптер одного собственного окна. Он не регистрирует глобальные источники событий и не меняет UI.
public struct АдаптерВводаОкна {
  public let окно: ИдентификаторОкнаВвода
  public let привязка: ПривязкаРаскладкиKeyboard

  private let определение: ОпределениеОператора
  private var фокус: ИдентификаторФокусаВвода?
  private var состояние: СостояниеМодификаторовКлавиатуры = .пустое
  private var активнаяКомпозицияIME: UUID?
  private var ужеЗафиксированныеКомпозиции: Set<UUID> = []

  public init(
    окно: ИдентификаторОкнаВвода,
    байтыОпределения: Data,
    байтыТаблицы: Data,
    привязка: ПривязкаРаскладкиKeyboard
  ) throws {
    let хэшОпределения = Self.sha256(байтыОпределения)
    guard хэшОпределения == привязка.хэшОпределения else {
      throw ОшибкаАдаптераВводаОкна.несовпавшийХэшОпределения(
        ожидалось: привязка.хэшОпределения,
        получено: хэшОпределения
      )
    }
    let хэшТаблицы = Self.sha256(байтыТаблицы)
    guard хэшТаблицы == привязка.хэшТаблицы else {
      throw ОшибкаАдаптераВводаОкна.несовпавшийХэшТаблицы(
        ожидалось: привязка.хэшТаблицы,
        получено: хэшТаблицы
      )
    }

    let определение = try ОпределениеОператора.разобрать(байтыОпределения)
    guard определение.идентификатор == привязка.идентификаторОператора,
          определение.версия == привязка.версияОператора else {
      throw ОшибкаАдаптераВводаОкна.несовпавшееОпределениеОператора
    }
    let таблица = try JSONDecoder().decode(ЗаголовокТаблицы.self, from: байтыТаблицы)
    guard таблица.схема == привязка.схемаТаблицы,
          таблица.раскладка == привязка.идентификаторРаскладки.rawValue else {
      throw ОшибкаАдаптераВводаОкна.несовпавшаяТаблица
    }

    self.окно = окно
    self.привязка = привязка
    self.определение = определение
  }

  public static let привязкаQwertyV1 = ПривязкаРаскладкиKeyboard.keyboardQwertyV1

  /// Принимает события владельца своего NSWindow и его first responder.
  /// Стороны модификаторов приходят как физические down/up события; новое состояние берётся из ответа графа.
  public mutating func принять(
    _ событие: ФизическоеСобытиеКлавиатуры,
    композицияIME: СостояниеКомпозицииIME = .обычно,
    вОкне окноСобытия: ИдентификаторОкнаВвода?,
    фокус новыйФокус: ИдентификаторФокусаВвода?
  ) throws -> РезультатВводаКлавиатурыОкна {
    guard окноСобытия == окно, let новыйФокус else {
      return результат(.проигнорировано, раскладка: событие.раскладка, вывод: .нет)
    }
    сменитьФокусЕслиНужно(на: новыйФокус)
    guard событие.раскладка == привязка.идентификаторРаскладки else {
      return результат(.раскладкаНеПроверена, раскладка: событие.раскладка, вывод: .нет)
    }

    let активнаяIME: Bool
    switch композицияIME {
    case .обычно:
      активнаяIME = активнаяКомпозицияIME != nil
    case .составляется(let идентификатор):
      активнаяКомпозицияIME = идентификатор
      активнаяIME = true
    }

    let вход = ВходПерехода(
      клавиша: событие.код,
      фаза: событие.фаза.rawValue,
      повтор: событие.повтор,
      модификаторы: состояние
    )
    let данныеВхода = try Self.кодировать(вход)
    let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(данныеВхода))
    guard case .текст(let текстРезультата) = наблюдение.результат,
          let данныеРезультата = текстРезультата.data(using: .utf8) else {
      throw ОшибкаАдаптераВводаОкна.неверныйФорматГрафа
    }
    let выход = try JSONDecoder().decode(ВыходПерехода.self, from: данныеРезультата)
    guard выход.трасса.оператор == привязка.идентификаторОператора,
          выход.трасса.версия == привязка.версияОператора,
          выход.трасса.клавиша == событие.код,
          выход.трасса.фаза == событие.фаза.rawValue,
          выход.трасса.повтор == событие.повтор else {
      throw ОшибкаАдаптераВводаОкна.неверныйФорматГрафа
    }

    состояние = выход.модификаторы
    let вывод: ВыводКлавиатурыОкна
    if активнаяIME {
      // Физический переход обновляет FUMA-состояние, но не вставляет текст поверх preedit/commit.
      вывод = .нет
    } else {
      switch (выход.статус, выход.вывод.вид) {
      case ("поддержано", "текст"):
        вывод = выход.вывод.значение.isEmpty ? .нет : .текст(выход.вывод.значение, источник: .fuma)
      case ("поддержано", "команда"):
        вывод = выход.вывод.значение.isEmpty ? .нет : .команда(выход.вывод.значение)
      case (_, "нет"):
        вывод = .нет
      case ("неподдержано", _):
        вывод = .нет
      default:
        throw ОшибкаАдаптераВводаОкна.неизвестныйРезультатГрафа
      }
    }
    return результат(.обработано, раскладка: событие.раскладка, вывод: вывод, трасса: наблюдение)
  }

  /// IME events несут уже составленный текст отдельно; они не запускают клавиатурный граф.
  public mutating func принять(
    _ событие: СобытиеIME,
    вОкне окноСобытия: ИдентификаторОкнаВвода?,
    фокус новыйФокус: ИдентификаторФокусаВвода?
  ) -> РезультатВводаКлавиатурыОкна {
    guard окноСобытия == окно, let новыйФокус else {
      return результат(.проигнорировано, раскладка: nil, вывод: .нет)
    }
    сменитьФокусЕслиНужно(на: новыйФокус)

    switch событие {
    case .начать(let идентификатор):
      активнаяКомпозицияIME = идентификатор
      return результат(.обработано, раскладка: nil, вывод: .нет)
    case .обновить(let идентификатор, _):
      guard активнаяКомпозицияIME == идентификатор else {
        return результат(.проигнорировано, раскладка: nil, вывод: .нет)
      }
      return результат(.обработано, раскладка: nil, вывод: .нет)
    case .зафиксировать(let идентификатор, let текст):
      guard ужеЗафиксированныеКомпозиции.insert(идентификатор).inserted else {
        return результат(.проигнорировано, раскладка: nil, вывод: .нет)
      }
      if активнаяКомпозицияIME == идентификатор { активнаяКомпозицияIME = nil }
      return результат(
        .обработано,
        раскладка: nil,
        вывод: текст.isEmpty ? .нет : .текст(текст, источник: .ime)
      )
    case .отменить(let идентификатор):
      guard активнаяКомпозицияIME == идентификатор else {
        return результат(.проигнорировано, раскладка: nil, вывод: .нет)
      }
      активнаяКомпозицияIME = nil
      return результат(.обработано, раскладка: nil, вывод: .нет)
    }
  }

  /// Вызывается владельцем окна при потере first responder; синтетические отпускания не создаются.
  public mutating func потерятьФокус(_ потерянныйФокус: ИдентификаторФокусаВвода) {
    guard фокус == потерянныйФокус else { return }
    фокус = nil
    состояние = .пустое
    активнаяКомпозицияIME = nil
  }

  private mutating func сменитьФокусЕслиНужно(на новыйФокус: ИдентификаторФокусаВвода) {
    guard фокус != новыйФокус else { return }
    фокус = новыйФокус
    состояние = .пустое
    активнаяКомпозицияIME = nil
  }

  private func результат(
    _ статус: СтатусВводаКлавиатурыОкна,
    раскладка: ИдентификаторРаскладкиКлавиатуры?,
    вывод: ВыводКлавиатурыОкна,
    трасса: НаблюдениеОператора? = nil
  ) -> РезультатВводаКлавиатурыОкна {
    РезультатВводаКлавиатурыОкна(
      статус: статус,
      раскладка: раскладка,
      вывод: вывод,
      состояние: состояние,
      трасса: трасса
    )
  }

  private static func sha256(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  }

  private static func кодировать(_ вход: ВходПерехода) throws -> String {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let данные = try кодировщик.encode(вход)
    guard let строка = String(data: данные, encoding: .utf8) else {
      throw ОшибкаАдаптераВводаОкна.неверныйФорматГрафа
    }
    return строка
  }
}

private struct ЗаголовокТаблицы: Decodable {
  let схема: String
  let раскладка: String
}

private struct ВходПерехода: Encodable {
  let клавиша: Int64
  let фаза: String
  let повтор: Bool
  let модификаторы: СостояниеМодификаторовКлавиатуры
}

private struct ВыходПерехода: Decodable {
  let статус: String
  let вывод: ПолеВывода
  let модификаторы: СостояниеМодификаторовКлавиатуры
  let трасса: ПолеТрассы

  private enum CodingKeys: String, CodingKey {
    case статус
    case вывод
    case модификаторы
    case трасса
  }
}

private struct ПолеВывода: Decodable {
  let вид: String
  let значение: String
}

private struct ПолеТрассы: Decodable {
  let оператор: String
  let версия: Int
  let клавиша: Int64
  let фаза: String
  let повтор: Bool

  private enum CodingKeys: String, CodingKey {
    case оператор
    case версия
    case клавиша
    case фаза
    case повтор
  }
}
