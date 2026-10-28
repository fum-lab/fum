import Foundation
import FUMStructuringOperatorMemory

public enum ВидОтказа: Equatable, Sendable {
  case несовпадениеСоставаПоставки
  case другой
}

public enum ОснованиеБазы: Equatable, Sendable {
  case полныйИдентификаторОбъекта(String)
  case токенФикстуры(String)

  fileprivate var значение: String {
    switch self {
    case .полныйИдентификаторОбъекта(let значение), .токенФикстуры(let значение): значение
    }
  }

  fileprivate var вид: String {
    switch self {
    case .полныйИдентификаторОбъекта: "полный-идентификатор-объекта"
    case .токенФикстуры: "токен-фикстуры"
    }
  }
}

public struct ТипизированныйОтказ: Sendable {
  public let вид: ВидОтказа
  public let идентификаторОстановки: String
  public let заявленныеПути: [String]

  public init(вид: ВидОтказа, идентификаторОстановки: String, заявленныеПути: [String]) {
    self.вид = вид
    self.идентификаторОстановки = идентификаторОстановки
    self.заявленныеПути = заявленныеПути
  }
}

public struct ДействующийДопуск: Sendable {
  public let активен: Bool
  public let ожидаемыеПути: [String]
  public let база: ОснованиеБазы
  public let владелец: String
  public let рабочееДерево: String
  public let ссылкаВетки: String
  public let опубликованнаяИстория: String

  public init(
    активен: Bool, ожидаемыеПути: [String], база: ОснованиеБазы, владелец: String,
    рабочееДерево: String, ссылкаВетки: String, опубликованнаяИстория: String
  ) {
    self.активен = активен
    self.ожидаемыеПути = ожидаемыеПути
    self.база = база
    self.владелец = владелец
    self.рабочееДерево = рабочееДерево
    self.ссылкаВетки = ссылкаВетки
    self.опубликованнаяИстория = опубликованнаяИстория
  }
}

public struct НаблюдаемоеСостояние: Sendable {
  public let фактическиеПутиРазличия: [String]
  public let база: ОснованиеБазы
  public let владелец: String
  public let рабочееДерево: String
  public let ссылкаВетки: String
  public let опубликованнаяИстория: String
  public let действуетПауза: Bool
  public let исходЭффектаНеизвестен: Bool

  public init(
    фактическиеПутиРазличия: [String], база: ОснованиеБазы, владелец: String,
    рабочееДерево: String, ссылкаВетки: String, опубликованнаяИстория: String,
    действуетПауза: Bool, исходЭффектаНеизвестен: Bool
  ) {
    self.фактическиеПутиРазличия = фактическиеПутиРазличия
    self.база = база
    self.владелец = владелец
    self.рабочееДерево = рабочееДерево
    self.ссылкаВетки = ссылкаВетки
    self.опубликованнаяИстория = опубликованнаяИстория
    self.действуетПауза = действуетПауза
    self.исходЭффектаНеизвестен = исходЭффектаНеизвестен
  }
}

public struct ЗапросОтвета: Sendable {
  public let отказ: ТипизированныйОтказ
  public let допуск: ДействующийДопуск
  public let состояние: НаблюдаемоеСостояние

  public init(отказ: ТипизированныйОтказ, допуск: ДействующийДопуск, состояние: НаблюдаемоеСостояние) {
    self.отказ = отказ
    self.допуск = допуск
    self.состояние = состояние
  }
}

public enum ПричинаЭскалации: String, Decodable, Equatable, Sendable {
  case неизвестныйОтказ = "неизвестный-отказ"
  case нетДействующегоДопуска = "нет-действующего-допуска"
  case действуетПауза = "действует-пауза"
  case неизвестныйИсходЭффекта = "неизвестный-исход-эффекта"
  case некорректныйИдентификаторОбъектаОснования = "некорректный-идентификатор-объекта-основания"
  case другаяБаза = "другая-база"
  case другойВладелец = "другой-владелец"
  case другоеРабочееДерево = "другое-рабочее-дерево"
  case другаяВетка = "другая-ветка"
  case другаяОпубликованнаяИстория = "другая-опубликованная-история"
  case некорректныйПуть = "некорректный-путь"
  case повторныйПуть = "повторный-путь"
  case ожидаемыйСоставНеСовпадает = "ожидаемый-состав-не-совпадает"
  case заявленныйПутьОтсутствует = "заявленный-путь-отсутствует"
  case неподдержанныйРазмерРазличия = "неподдержанный-размер-различия"
}

public enum ИсходОтвета: String, Decodable, Equatable, Sendable {
  case планИсправления = "план-исправления"
  case ничегоНеДелать = "ничего-не-делать"
  case эскалация
}

public struct ПутьПлана: Decodable, Equatable, Sendable {
  public let путь: String
  public let действие: String

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Ключи.self)
    try проверитьПоля(container.allKeys.map(\.rawValue), ожидаемые: ["путь", "действие"], decoder: decoder)
    путь = try container.decode(String.self, forKey: .путь)
    действие = try container.decode(String.self, forKey: .действие)
    guard действие == "вернуть-к-базе" else {
      throw DecodingError.dataCorruptedError(forKey: .действие, in: container, debugDescription: "Неизвестное действие")
    }
  }

  private enum Ключи: String, CodingKey { case путь, действие }
}

public struct ПланИсправления: Decodable, Equatable, Sendable {
  public let база: String
  public let видОснованияБазы: String
  public let полныйИдентификаторОбъектаПодтверждён: Bool
  public let точныйМанифестПодтверждён: Bool
  public let применимостьПодтверждена: Bool
  public let общийОбработчикМанифеста: Bool
  public let владелец: String
  public let рабочееДерево: String
  public let ссылкаВетки: String
  public let опубликованнаяИстория: String
  public let сохранитьПути: [String]
  public let изменитьИсторию: Bool
  public let применениеРазрешено: Bool
  public let отправкаРазрешена: Bool
  public let требуетсяПовторноеНаблюдение: Bool
  public let пути: [ПутьПлана]

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Ключи.self)
    try проверитьПоля(container.allKeys.map(\.rawValue), ожидаемые: [
      "база", "вид-основания-базы", "полный-идентификатор-объекта-подтверждён",
      "точный-манифест-подтверждён", "применимость-подтверждена", "общий-обработчик-манифеста",
      "владелец", "рабочее-дерево", "ссылка-ветки", "опубликованная-история",
      "сохранить-пути", "изменить-историю", "применение-разрешено", "отправка-разрешена",
      "требуется-повторное-наблюдение", "пути",
    ], decoder: decoder)
    база = try container.decode(String.self, forKey: .база)
    видОснованияБазы = try container.decode(String.self, forKey: .видОснованияБазы)
    полныйИдентификаторОбъектаПодтверждён = try container.decode(Bool.self, forKey: .полныйИдентификаторОбъектаПодтверждён)
    точныйМанифестПодтверждён = try container.decode(Bool.self, forKey: .точныйМанифестПодтверждён)
    применимостьПодтверждена = try container.decode(Bool.self, forKey: .применимостьПодтверждена)
    общийОбработчикМанифеста = try container.decode(Bool.self, forKey: .общийОбработчикМанифеста)
    владелец = try container.decode(String.self, forKey: .владелец)
    рабочееДерево = try container.decode(String.self, forKey: .рабочееДерево)
    ссылкаВетки = try container.decode(String.self, forKey: .ссылкаВетки)
    опубликованнаяИстория = try container.decode(String.self, forKey: .опубликованнаяИстория)
    сохранитьПути = try container.decode([String].self, forKey: .сохранитьПути)
    изменитьИсторию = try container.decode(Bool.self, forKey: .изменитьИсторию)
    применениеРазрешено = try container.decode(Bool.self, forKey: .применениеРазрешено)
    отправкаРазрешена = try container.decode(Bool.self, forKey: .отправкаРазрешена)
    требуетсяПовторноеНаблюдение = try container.decode(Bool.self, forKey: .требуетсяПовторноеНаблюдение)
    пути = try container.decode([ПутьПлана].self, forKey: .пути)
    guard Self.уникальны(сохранитьПути), сохранитьПути.count == 13,
      Self.уникальны(пути.map(\.путь)), пути.count == 23,
      пути.allSatisfy({ Self.допустимыйПуть($0.путь) }),
      Set(пути.map(\.путь)).isDisjoint(with: Set(сохранитьПути)),
      видОснованияБазы == "полный-идентификатор-объекта" || видОснованияБазы == "токен-фикстуры",
      полныйИдентификаторОбъектаПодтверждён == false, точныйМанифестПодтверждён == false,
      применимостьПодтверждена == false, общийОбработчикМанифеста == false,
      отправкаРазрешена == false
    else {
      throw DecodingError.dataCorruptedError(forKey: .пути, in: container, debugDescription: "План нарушает размер или состав")
    }
  }

  private enum Ключи: String, CodingKey {
    case база, владелец, пути
    case видОснованияБазы = "вид-основания-базы"
    case полныйИдентификаторОбъектаПодтверждён = "полный-идентификатор-объекта-подтверждён"
    case точныйМанифестПодтверждён = "точный-манифест-подтверждён"
    case применимостьПодтверждена = "применимость-подтверждена"
    case общийОбработчикМанифеста = "общий-обработчик-манифеста"
    case рабочееДерево = "рабочее-дерево"
    case ссылкаВетки = "ссылка-ветки"
    case опубликованнаяИстория = "опубликованная-история"
    case сохранитьПути = "сохранить-пути"
    case изменитьИсторию = "изменить-историю"
    case применениеРазрешено = "применение-разрешено"
    case отправкаРазрешена = "отправка-разрешена"
    case требуетсяПовторноеНаблюдение = "требуется-повторное-наблюдение"
  }

  private static func уникальны(_ значения: [String]) -> Bool { Set(значения).count == значения.count }

  private static func допустимыйПуть(_ путь: String) -> Bool {
    guard !путь.isEmpty, !путь.hasPrefix("/"), !путь.contains("\\"),
      путь.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
    else { return false }
    return путь.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
      !$0.isEmpty && $0 != "." && $0 != ".."
    }
  }
}

public struct ОтветОператора: Decodable, Equatable, Sendable {
  public let область: String
  public let схема: String
  public let исход: ИсходОтвета
  public let причина: ПричинаЭскалации?
  public let план: ПланИсправления?
  public let черновикСообщения: String
  public let эффект: String
  public let эффектРазрешён: Bool
  public let отправкаРазрешена: Bool
  public let применимостьПодтверждена: Bool

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Ключи.self)
    try проверитьПоля(container.allKeys.map(\.rawValue), ожидаемые: [
      "область", "схема", "исход", "причина", "план", "черновик-сообщения", "эффект",
      "эффект-разрешён", "отправка-разрешена", "применимость-подтверждена",
    ], decoder: decoder)
    область = try container.decode(String.self, forKey: .область)
    схема = try container.decode(String.self, forKey: .схема)
    исход = try container.decode(ИсходОтвета.self, forKey: .исход)
    причина = try container.decodeIfPresent(ПричинаЭскалации.self, forKey: .причина)
    план = try container.decodeIfPresent(ПланИсправления.self, forKey: .план)
    черновикСообщения = try container.decode(String.self, forKey: .черновикСообщения)
    эффект = try container.decode(String.self, forKey: .эффект)
    эффектРазрешён = try container.decode(Bool.self, forKey: .эффектРазрешён)
    отправкаРазрешена = try container.decode(Bool.self, forKey: .отправкаРазрешена)
    применимостьПодтверждена = try container.decode(Bool.self, forKey: .применимостьПодтверждена)
    guard область == "синтетическая-фикстура-stop-07d609-13-36",
      схема == "fuma.ответ-известному-отказу.пилот.2", эффект == "не-выполнять",
      эффектРазрешён == false, отправкаРазрешена == false, применимостьПодтверждена == false
    else {
      throw DecodingError.dataCorruptedError(
        forKey: .схема, in: container, debugDescription: "Неподдержанная схема ответа"
      )
    }
    switch исход {
    case .планИсправления:
      guard let план, причина == nil, план.пути.count == 23,
        план.изменитьИсторию == false, план.применениеРазрешено == false,
        план.требуетсяПовторноеНаблюдение
      else {
        throw DecodingError.dataCorruptedError(
          forKey: .план, in: container, debugDescription: "Небезопасный либо неполный план"
        )
      }
    case .ничегоНеДелать:
      guard план == nil, причина == nil else {
        throw DecodingError.dataCorruptedError(
          forKey: .план, in: container, debugDescription: "Пустое состояние содержит план"
        )
      }
    case .эскалация:
      guard план == nil, причина != nil else {
        throw DecodingError.dataCorruptedError(
          forKey: .причина, in: container, debugDescription: "Эскалации нужна типизированная причина"
        )
      }
    }
  }

  private enum Ключи: String, CodingKey {
    case область, схема, исход, причина, план, черновикСообщения = "черновик-сообщения", эффект
    case эффектРазрешён = "эффект-разрешён"
    case отправкаРазрешена = "отправка-разрешена"
    case применимостьПодтверждена = "применимость-подтверждена"
  }
}

public struct ОператорОтвета: Sendable {
  private let определение: ОпределениеОператора

  public init() throws {
    guard let url = Bundle.module.url(forResource: "определение", withExtension: "json") else {
      throw CocoaError(.fileReadNoSuchFile)
    }
    try self.init(данныеОпределения: Data(contentsOf: url))
  }

  public init(данныеОпределения: Data) throws {
    определение = try ОпределениеОператора.разобрать(данныеОпределения)
  }

  public func сформироватьОтвет(_ запрос: ЗапросОтвета) throws -> ОтветОператора {
    let подготовка = Self.подготовитьВход(запрос)
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let входныеБайты = try кодировщик.encode(подготовка)
    guard let входнойТекст = String(data: входныеБайты, encoding: .utf8) else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }
    let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(входнойТекст))
    guard case .текст(let результат) = наблюдение.результат else {
      throw CocoaError(.coderInvalidValue)
    }
    return try JSONDecoder().decode(ОтветОператора.self, from: Data(результат.utf8))
  }

  private struct ВходГрафа: Encodable {
    let разрешённыйПлан: Bool
    let причинаЭскалации: String
    let лишниеПути: [String]
    let ожидаемыеПути: [String]
    let база: String
    let видОснованияБазы: String
    let владелец: String
    let рабочееДерево: String
    let ссылкаВетки: String
    let опубликованнаяИстория: String
    let остановка: String

    enum CodingKeys: String, CodingKey {
      case разрешённыйПлан = "разрешённый-план"
      case причинаЭскалации = "причина-эскалации"
      case лишниеПути = "лишние-пути"
      case ожидаемыеПути = "ожидаемые-пути"
      case база, владелец
      case видОснованияБазы = "вид-основания-базы"
      case рабочееДерево = "рабочее-дерево"
      case ссылкаВетки = "ссылка-ветки"
      case опубликованнаяИстория = "опубликованная-история"
      case остановка
    }
  }

  private static func подготовитьВход(_ запрос: ЗапросОтвета) -> ВходГрафа {
    let отказ = запрос.отказ
    let допуск = запрос.допуск
    let состояние = запрос.состояние

    func эскалация(_ причина: ПричинаЭскалации) -> ВходГрафа {
      ВходГрафа(
        разрешённыйПлан: false, причинаЭскалации: причина.rawValue, лишниеПути: [],
        ожидаемыеПути: допуск.ожидаемыеПути, база: допуск.база.значение,
        видОснованияБазы: допуск.база.вид, владелец: допуск.владелец,
        рабочееДерево: допуск.рабочееДерево, ссылкаВетки: допуск.ссылкаВетки,
        опубликованнаяИстория: допуск.опубликованнаяИстория,
        остановка: отказ.идентификаторОстановки)
    }

    guard отказ.вид == .несовпадениеСоставаПоставки,
      отказ.идентификаторОстановки == "07d609"
    else { return эскалация(.неизвестныйОтказ) }
    guard допуск.активен else { return эскалация(.нетДействующегоДопуска) }
    guard !состояние.действуетПауза else { return эскалация(.действуетПауза) }
    guard !состояние.исходЭффектаНеизвестен else { return эскалация(.неизвестныйИсходЭффекта) }
    guard Self.допустимоеОснование(допуск.база), Self.допустимоеОснование(состояние.база) else {
      return эскалация(.некорректныйИдентификаторОбъектаОснования)
    }
    guard Self.равны(допуск.база, состояние.база) else {
      return эскалация(.другаяБаза)
    }
    guard Self.байты(допуск.владелец) == Self.байты(состояние.владелец) else {
      return эскалация(.другойВладелец)
    }
    guard Self.байты(допуск.рабочееДерево) == Self.байты(состояние.рабочееДерево) else {
      return эскалация(.другоеРабочееДерево)
    }
    guard Self.байты(допуск.ссылкаВетки) == Self.байты(состояние.ссылкаВетки) else {
      return эскалация(.другаяВетка)
    }
    guard Self.байты(допуск.опубликованнаяИстория) == Self.байты(состояние.опубликованнаяИстория) else {
      return эскалация(.другаяОпубликованнаяИстория)
    }
    guard (допуск.ожидаемыеПути + отказ.заявленныеПути + состояние.фактическиеПутиРазличия)
      .allSatisfy(Self.допустимыйПуть)
    else { return эскалация(.некорректныйПуть) }

    let ожидаемые = допуск.ожидаемыеПути.map(Self.байты)
    let заявленные = отказ.заявленныеПути.map(Self.байты)
    let фактические = состояние.фактическиеПутиРазличия.map(Self.байты)
    guard Self.уникальны(ожидаемые), Self.уникальны(заявленные) else {
      return эскалация(.повторныйПуть)
    }
    guard ожидаемые.count == 13, заявленные.count == 13,
      Set(ожидаемые) == Set(заявленные)
    else { return эскалация(.ожидаемыйСоставНеСовпадает) }
    guard Self.уникальны(фактические) else { return эскалация(.повторныйПуть) }
    let фактическоеМножество = Set(фактические)
    guard Set(ожидаемые).isSubset(of: фактическоеМножество) else {
      return эскалация(.заявленныйПутьОтсутствует)
    }
    let лишниеБайты = фактическоеМножество.subtracting(ожидаемые)
    guard (фактические.count == 13 && лишниеБайты.isEmpty)
      || (фактические.count == 36 && лишниеБайты.count == 23)
    else { return эскалация(.неподдержанныйРазмерРазличия) }

    let лишниеПути = лишниеБайты.map { String(decoding: $0, as: UTF8.self) }
      .sorted { Self.байты($0).lexicographicallyPrecedes(Self.байты($1)) }
    return ВходГрафа(
      разрешённыйПлан: true, причинаЭскалации: ПричинаЭскалации.неподдержанныйРазмерРазличия.rawValue,
      лишниеПути: лишниеПути,
      ожидаемыеПути: допуск.ожидаемыеПути.sorted {
        Self.байты($0).lexicographicallyPrecedes(Self.байты($1))
      },
      база: допуск.база.значение, видОснованияБазы: допуск.база.вид,
      владелец: допуск.владелец,
      рабочееДерево: допуск.рабочееДерево, ссылкаВетки: допуск.ссылкаВетки,
      опубликованнаяИстория: допуск.опубликованнаяИстория,
      остановка: отказ.идентификаторОстановки)
  }

  private static func байты(_ строка: String) -> Data { Data(строка.utf8) }

  private static func равны(_ первое: ОснованиеБазы, _ второе: ОснованиеБазы) -> Bool {
    switch (первое, второе) {
    case (.полныйИдентификаторОбъекта(let a), .полныйИдентификаторОбъекта(let b)), (.токенФикстуры(let a), .токенФикстуры(let b)):
      return Self.байты(a) == Self.байты(b)
    default: return false
    }
  }

  private static func допустимоеОснование(_ основание: ОснованиеБазы) -> Bool {
    switch основание {
    case .токенФикстуры(let значение): return Self.допустимыйПуть(значение) && !значение.contains("/")
    case .полныйИдентификаторОбъекта(let значение):
      return (значение.count == 40 || значение.count == 64)
        && значение.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
  }

  private static func уникальны(_ значения: [Data]) -> Bool {
    Set(значения).count == значения.count
  }

  private static func допустимыйПуть(_ путь: String) -> Bool {
    guard !путь.isEmpty, !путь.hasPrefix("/"), !путь.contains("\\"),
      путь.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
    else { return false }
    return путь.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
      !$0.isEmpty && $0 != "." && $0 != ".."
    }
  }
}

private func проверитьПоля(
  _ фактические: [String], ожидаемые: Set<String>, decoder: any Decoder
) throws {
  guard Set(фактические) == ожидаемые else {
    throw DecodingError.dataCorrupted(
      .init(codingPath: decoder.codingPath, debugDescription: "Неизвестные или отсутствующие поля")
    )
  }
}
