import CryptoKit
import Foundation

public enum ОшибкаПредставления: Error {
  case отказ(String)
}

func потребовать(_ условие: Bool, _ причина: String) throws {
  guard условие else { throw ОшибкаПредставления.отказ(причина) }
}

// Dictionary использует каноническое равенство String; wire-ключ требует точных скаляров.
extension Dictionary where Key == String {
  func точно(_ ключ: String) -> Value? {
    guard let индекс = index(forKey: ключ), self[индекс].key.utf8.elementsEqual(ключ.utf8) else { return nil }
    return self[индекс].value
  }
}

public indirect enum ЗначениеJSON: Codable, Equatable, Sendable {
  case объект([String: ЗначениеJSON])
  case массив([ЗначениеJSON])
  case строка(String)
  case целое(Int64)
  case логическое(Bool)
  case пусто
  case отсутствует

  public static func == (левое: Self, правое: Self) -> Bool {
    switch (левое, правое) {
    case (.строка(let а), .строка(let б)): return а.utf8.elementsEqual(б.utf8)
    case (.целое(let а), .целое(let б)): return а == б
    case (.логическое(let а), .логическое(let б)): return а == б
    case (.массив(let а), .массив(let б)): return а == б
    case (.объект(let а), .объект(let б)):
      return а.count == б.count && а.allSatisfy { ключ, значение in б.точно(ключ) == значение }
    case (.пусто, .пусто), (.отсутствует, .отсутствует): return true
    default: return false
    }
  }

  public init(from декодер: any Decoder) throws {
    let контейнер = try декодер.singleValueContainer()
    if контейнер.decodeNil() { self = .пусто }
    else if let значение = try? контейнер.decode(Bool.self) { self = .логическое(значение) }
    else if let значение = try? контейнер.decode(String.self) { self = .строка(значение) }
    else if let значение = try? контейнер.decode(Int64.self) { self = .целое(значение) }
    else if let значение = try? контейнер.decode([ЗначениеJSON].self) { self = .массив(значение) }
    else if let значение = try? контейнер.decode([String: ЗначениеJSON].self) { self = .объект(значение) }
    else { throw ОшибкаПредставления.отказ("Значение вне профиля JSON") }
  }

  public func encode(to кодировщик: any Encoder) throws {
    var контейнер = кодировщик.singleValueContainer()
    switch self {
    case .объект(let значение): try контейнер.encode(значение)
    case .массив(let значение): try контейнер.encode(значение)
    case .строка(let значение): try контейнер.encode(значение)
    case .целое(let значение): try контейнер.encode(значение)
    case .логическое(let значение): try контейнер.encode(значение)
    case .пусто: try контейнер.encodeNil()
    case .отсутствует: throw ОшибкаПредставления.отказ("Отсутствие не кодируется как null")
    }
  }

  func объект() throws -> [String: ЗначениеJSON] {
    guard case .объект(let значение) = self else { throw ОшибкаПредставления.отказ("Ожидался объект") }
    return значение
  }
  func массив() throws -> [ЗначениеJSON] {
    guard case .массив(let значение) = self else { throw ОшибкаПредставления.отказ("Ожидался массив") }
    return значение
  }
  func строка() throws -> String {
    guard case .строка(let значение) = self else { throw ОшибкаПредставления.отказ("Ожидалась строка") }
    return значение
  }
  func целое() throws -> Int64 {
    guard case .целое(let значение) = self else { throw ОшибкаПредставления.отказ("Ожидалось целое") }
    return значение
  }
  var есть: Bool { self != .пусто && self != .отсутствует }
}

public enum ПолеJSON<Значение: Codable & Sendable>: Sendable {
  case отсутствует
  case пусто
  case значение(Значение)
}

public func прочитатьПоле<Значение: Codable & Sendable, Ключ: CodingKey>(
  _ тип: Значение.Type, из контейнер: KeyedDecodingContainer<Ключ>, ключ: Ключ
) throws -> ПолеJSON<Значение> {
  if !контейнер.contains(ключ) { return .отсутствует }
  if try контейнер.decodeNil(forKey: ключ) { return .пусто }
  return .значение(try контейнер.decode(тип, forKey: ключ))
}

public func записатьПоле<Значение: Codable & Sendable, Ключ: CodingKey>(
  _ поле: ПолеJSON<Значение>, в контейнер: inout KeyedEncodingContainer<Ключ>, ключ: Ключ,
  обязательно: Bool
) throws {
  switch поле {
  case .отсутствует: try потребовать(!обязательно, "Отсутствует обязательное поле")
  case .пусто: try контейнер.encodeNil(forKey: ключ)
  case .значение(let значение): try контейнер.encode(значение, forKey: ключ)
  }
}

// Лексический допуск предшествует Codable: JSONDecoder может принять 1.0 как Int64.
// Разбор продолжает существующий подход закрытого парсера определения, не меняя его язык.
struct СтрогийРазборJSON {
  private let байты: [UInt8]
  private var позиция = 0

  init(_ данные: Data) throws {
    try потребовать(данные.count <= 134_217_728 && String(data: данные, encoding: .utf8) != nil,
      "Неверный размер или UTF-8 снимка")
    байты = Array(данные)
  }

  mutating func разобрать() throws -> ЗначениеJSON {
    let значение = try значение(глубина: 0)
    пробелы()
    try потребовать(позиция == байты.count, "Лишние байты JSON")
    return значение
  }

  private mutating func значение(глубина: Int) throws -> ЗначениеJSON {
    try потребовать(глубина <= 64, "Превышена глубина JSON")
    пробелы()
    try потребовать(позиция < байты.count, "Оборванный JSON")
    if принять(123) {
      var поля: [String: ЗначениеJSON] = [:]
      пробелы()
      if принять(125) { return .объект(поля) }
      while true {
        пробелы()
        let ключ = try строка()
        try потребовать(поля[ключ] == nil, "Повтор или канонически совпадающие ключи JSON")
        пробелы()
        try потребовать(принять(58), "Нет двоеточия")
        поля[ключ] = try значение(глубина: глубина + 1)
        пробелы()
        if принять(125) { return .объект(поля) }
        try потребовать(принять(44), "Нет запятой объекта")
      }
    }
    if принять(91) {
      var элементы: [ЗначениеJSON] = []
      пробелы()
      if принять(93) { return .массив(элементы) }
      while true {
        элементы.append(try значение(глубина: глубина + 1))
        пробелы()
        if принять(93) { return .массив(элементы) }
        try потребовать(принять(44), "Нет запятой массива")
      }
    }
    if байты[позиция] == 34 { return .строка(try строка()) }
    for (текст, значение) in [("true", ЗначениеJSON.логическое(true)), ("false", .логическое(false)), ("null", .пусто)] {
      let ожидаемые = Array(текст.utf8)
      if байты[позиция...].starts(with: ожидаемые) { позиция += ожидаемые.count; return значение }
    }
    let начало = позиция
    _ = принять(45)
    try потребовать(позиция < байты.count, "Оборванное число")
    if !принять(48) {
      try потребовать((49...57).contains(байты[позиция]), "Неподдержанное значение JSON")
      while позиция < байты.count, (48...57).contains(байты[позиция]) { позиция += 1 }
    }
    if позиция < байты.count, [46, 69, 101].contains(байты[позиция]) {
      throw ОшибкаПредставления.отказ("Дробные и экспоненциальные токены запрещены профилем")
    }
    guard let число = Int64(String(decoding: байты[начало..<позиция], as: UTF8.self)) else {
      throw ОшибкаПредставления.отказ("Число вне профиля Int64")
    }
    return .целое(число)
  }

  private mutating func строка() throws -> String {
    let начало = позиция
    try потребовать(принять(34), "Ожидалась строка JSON")
    while позиция < байты.count {
      let байт = байты[позиция]; позиция += 1
      if байт == 34 { return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция])) }
      try потребовать(байт >= 32, "Управляющий байт строки")
      if байт == 92 {
        try потребовать(позиция < байты.count, "Оборванное экранирование")
        позиция += 1
      }
    }
    throw ОшибкаПредставления.отказ("Оборванная строка")
  }
  private mutating func принять(_ байт: UInt8) -> Bool {
    guard позиция < байты.count, байты[позиция] == байт else { return false }
    позиция += 1
    return true
  }
  private mutating func пробелы() {
    while позиция < байты.count, [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
  }
}

func разобратьJSON(_ данные: Data) throws -> ЗначениеJSON {
  var разбор = try СтрогийРазборJSON(данные)
  return try разбор.разобрать()
}

public func подготовитьСнимок(_ данные: Data, ожидаемыйХэш: String, задача: String) throws -> ЗначениеJSON {
  try потребовать(данные.count <= 134_217_728, "Превышен размер снимка")
  try потребовать(задача.range(of: "^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", options: .regularExpression) != nil,
    "Нужен UUID задачи")
  let хэш = SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  try потребовать(хэш == ожидаемыйХэш, "Не совпал SHA полного артефакта")
  _ = try разобратьJSON(данные)
  return .объект(["sha256": .строка(хэш), "байты": .целое(Int64(данные.count))])
}

public func ограничитьВыход(_ данные: Data, максимумБайтов: Int) throws -> Data {
  try потребовать((100...1_048_576).contains(максимумБайтов), "Неверный бюджет")
  var результат = данные
  результат.append(10)
  try потребовать(результат.count <= максимумБайтов, "Бюджет превышен; оригинал не усечён")
  return результат
}
