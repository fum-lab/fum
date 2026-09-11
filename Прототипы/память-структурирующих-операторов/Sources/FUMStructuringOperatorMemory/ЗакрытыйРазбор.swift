import Foundation

// Собственный закрытый JSON: целые числа, строки, массивы и объекты.
// Значения true/false/null и дроби не входят в схему определения.
indirect enum УзелОпределения: Encodable {
  case объект([String: УзелОпределения])
  case массив([УзелОпределения])
  case строка(String)
  case целое(Int)

  func encode(to кодировщик: any Encoder) throws {
    var контейнер = кодировщик.singleValueContainer()
    switch self {
    case .объект(let поля): try контейнер.encode(поля)
    case .массив(let элементы): try контейнер.encode(элементы)
    case .строка(let строка): try контейнер.encode(строка)
    case .целое(let число): try контейнер.encode(число)
    }
  }

  func объект(_ ключи: Set<String>) throws -> [String: УзелОпределения] {
    guard case .объект(let поля) = self, Set(поля.keys) == ключи else {
      throw ОшибкаИсполнения("схема", "Неизвестные, отсутствующие поля или неверный тип объекта")
    }
    return поля
  }

  func массив() throws -> [УзелОпределения] {
    guard case .массив(let элементы) = self else {
      throw ОшибкаИсполнения("схема", "Ожидался массив")
    }
    return элементы
  }

  func строка() throws -> String {
    guard case .строка(let строка) = self else {
      throw ОшибкаИсполнения("схема", "Ожидалась строка")
    }
    return строка
  }

  func целое() throws -> Int {
    guard case .целое(let число) = self else {
      throw ОшибкаИсполнения("схема", "Ожидалось целое число")
    }
    return число
  }
}

struct РазборОпределения {
  private let байты: [UInt8]
  private var позиция = 0
  private var узлов = 0

  init(_ данные: Data) throws {
    guard данные.count <= 65_536 else {
      throw ОшибкаИсполнения("предел-определения", "Определение превышает 65536 байтов")
    }
    guard String(data: данные, encoding: .utf8) != nil else {
      throw ОшибкаИсполнения("схема", "Определение должно быть строгим UTF-8")
    }
    байты = Array(данные)
  }

  mutating func разобрать() throws -> УзелОпределения {
    let результат = try значение(глубина: 0)
    пропуститьПробелы()
    guard позиция == байты.count else { throw отказ() }
    return результат
  }

  private func отказ() -> ОшибкаИсполнения {
    ОшибкаИсполнения("схема", "Некорректный закрытый JSON", позицияБайта: позиция)
  }

  private mutating func значение(глубина: Int) throws -> УзелОпределения {
    guard глубина <= 16, узлов < 8192 else {
      throw ОшибкаИсполнения("предел-структуры", "Превышены глубина или число узлов JSON")
    }
    узлов += 1
    пропуститьПробелы()
    guard позиция < байты.count else { throw отказ() }
    if принять(123) {
      var поля: [String: УзелОпределения] = [:]
      пропуститьПробелы()
      if принять(125) { return .объект(поля) }
      while true {
        пропуститьПробелы()
        let ключ = try строка()
        guard поля[ключ] == nil else {
          throw ОшибкаИсполнения("повтор-поля", "Повторное имя поля JSON", позицияБайта: позиция)
        }
        пропуститьПробелы()
        guard принять(58) else { throw отказ() }
        поля[ключ] = try значение(глубина: глубина + 1)
        пропуститьПробелы()
        if принять(125) { return .объект(поля) }
        guard принять(44) else { throw отказ() }
      }
    }
    if принять(91) {
      var элементы: [УзелОпределения] = []
      пропуститьПробелы()
      if принять(93) { return .массив(элементы) }
      while true {
        элементы.append(try значение(глубина: глубина + 1))
        пропуститьПробелы()
        if принять(93) { return .массив(элементы) }
        guard принять(44) else { throw отказ() }
      }
    }
    if байты[позиция] == 34 { return .строка(try строка()) }
    let начало = позиция
    _ = принять(45)
    guard позиция < байты.count else { throw отказ() }
    if !принять(48) {
      guard (49...57).contains(байты[позиция]) else { throw отказ() }
      while позиция < байты.count, (48...57).contains(байты[позиция]) { позиция += 1 }
    }
    guard let число = Int(String(decoding: байты[начало..<позиция], as: UTF8.self)) else {
      throw отказ()
    }
    return .целое(число)
  }

  private mutating func строка() throws -> String {
    let начало = позиция
    guard принять(34) else { throw отказ() }
    while позиция < байты.count {
      let байт = байты[позиция]
      позиция += 1
      if байт == 34 {
        do {
          return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция]))
        } catch { throw отказ() }
      }
      guard байт >= 32 else { throw отказ() }
      if байт == 92 {
        guard позиция < байты.count else { throw отказ() }
        позиция += 1
      }
    }
    throw отказ()
  }

  private mutating func принять(_ байт: UInt8) -> Bool {
    guard позиция < байты.count, байты[позиция] == байт else { return false }
    позиция += 1
    return true
  }

  private mutating func пропуститьПробелы() {
    while позиция < байты.count, [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 }
  }
}

public func каноническиеДанные<Значение: Encodable>(_ значение: Значение) throws -> Data {
  let кодировщик = JSONEncoder()
  кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  return try кодировщик.encode(значение)
}
