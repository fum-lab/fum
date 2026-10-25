import Foundation

public struct КадрSSELLM: Equatable, Sendable {
  public let событие: String
  public let идентификатор: String?
  public let данные: Data
  public let сырыеБайты: Data

  public init(
    событие: String = "message", идентификатор: String? = nil,
    данные: Data, сырыеБайты: Data
  ) {
    self.событие = событие
    self.идентификатор = идентификатор
    self.данные = данные
    self.сырыеБайты = сырыеБайты
  }
}

/// Инкрементальный SSE-разбор без сетевых эффектов и автоматического переподключения.
/// Предел охватывает исходные байты одной рамки, включая управляющие строки.
public struct РазборSSELLM: Sendable {
  private let пределБайтовРамки: Int
  private var байтыРамки: [UInt8] = []
  private var байтыСтроки: [UInt8] = []
  private var байтыДанных: [UInt8] = []
  private var имяСобытия = ""
  private var последнийИдентификатор: String?
  private var встреченыДанные = false
  private var перваяСтрока = true
  private var отложенВозвратКаретки = false
  private var потокЗавершён = false
  private var сохранённаяОшибка: ОшибкаLLM?

  public init(пределБайтовРамки: Int = 1_048_576) {
    self.пределБайтовРамки = пределБайтовРамки
  }

  /// Точные ещё не замкнутые пустой строкой байты, в том числе после EOF.
  public var незавершённыйХвост: Data { Data(байтыРамки) }

  public mutating func принять(_ данные: Data) throws -> [КадрSSELLM] {
    try проверитьСостояние()
    guard !потокЗавершён else {
      guard данные.isEmpty else {
        throw сохранитьОшибку(.протокол, "Данные поступили после завершения SSE")
      }
      return []
    }

    var кадры: [КадрSSELLM] = []
    do {
      for байт in данные {
        if отложенВозвратКаретки {
          отложенВозвратКаретки = false
          if байт == 0x0A {
            try добавитьВРамку(байт)
            try закончитьСтроку(кадры: &кадры)
            continue
          }
          try закончитьСтроку(кадры: &кадры)
        }

        try добавитьВРамку(байт)
        switch байт {
        case 0x0D:
          // Следующий байт определит точную исходную границу CR либо CRLF.
          отложенВозвратКаретки = true
        case 0x0A:
          try закончитьСтроку(кадры: &кадры)
        default:
          байтыСтроки.append(байт)
        }
      }
    } catch let ошибка as ОшибкаLLM {
      // Завершённые кадры выдаются один раз до сохранённого первого отказа.
      // Следующий принять(), включая пустой, или завершить() выдаст этот отказ.
      guard !кадры.isEmpty else { throw ошибка }
      return кадры
    }
    return кадры
  }

  public mutating func завершить() throws -> [КадрSSELLM] {
    try проверитьСостояние()
    guard !потокЗавершён else { return [] }

    var кадры: [КадрSSELLM] = []
    if отложенВозвратКаретки {
      отложенВозвратКаретки = false
      try закончитьСтроку(кадры: &кадры)
    }
    if !байтыСтроки.isEmpty {
      // Незаконченная строка не dispatch-ится, но ошибочная кодировка не скрывается.
      _ = try прочитатьСтроку()
    }
    потокЗавершён = true
    return кадры
  }

  private mutating func проверитьСостояние() throws {
    if let ошибка = сохранённаяОшибка { throw ошибка }
    guard пределБайтовРамки > 0 else {
      throw сохранитьОшибку(.пределРесурсов, "Предел рамки SSE должен быть положительным")
    }
  }

  private mutating func добавитьВРамку(_ байт: UInt8) throws {
    guard байтыРамки.count < пределБайтовРамки else {
      throw сохранитьОшибку(.пределРесурсов, "Рамка SSE превышает предел исходных байтов")
    }
    байтыРамки.append(байт)
  }

  private mutating func прочитатьСтроку() throws -> String {
    var начало = 0
    if перваяСтрока, байтыСтроки.count >= 3,
      байтыСтроки[0] == 0xEF, байтыСтроки[1] == 0xBB, байтыСтроки[2] == 0xBF
    {
      начало = 3
    }
    guard let строка = String(bytes: байтыСтроки.dropFirst(начало), encoding: .utf8) else {
      throw сохранитьОшибку(.протокол, "Поток SSE содержит неверную последовательность UTF-8")
    }
    return строка
  }

  private mutating func закончитьСтроку(кадры: inout [КадрSSELLM]) throws {
    let строка = try прочитатьСтроку()
    перваяСтрока = false
    байтыСтроки.removeAll(keepingCapacity: true)

    if строка.isEmpty {
      if встреченыДанные {
        кадры.append(
          КадрSSELLM(
            событие: имяСобытия.isEmpty ? "message" : имяСобытия,
            идентификатор: последнийИдентификатор,
            данные: Data(байтыДанных), сырыеБайты: Data(байтыРамки)
          )
        )
      }
      байтыРамки.removeAll(keepingCapacity: true)
      байтыДанных.removeAll(keepingCapacity: true)
      имяСобытия = ""
      встреченыДанные = false
      return
    }
    guard строка.first != ":" else { return }

    let поле: String
    var значение: String
    if let двоеточие = строка.firstIndex(of: ":") {
      поле = String(строка[..<двоеточие])
      значение = String(строка[строка.index(after: двоеточие)...])
      if значение.first == " " { значение.removeFirst() }
    } else {
      поле = строка
      значение = ""
    }

    switch поле {
    case "data":
      if встреченыДанные { байтыДанных.append(0x0A) }
      байтыДанных.append(contentsOf: значение.utf8)
      встреченыДанные = true
    case "event":
      имяСобытия = значение
    case "id":
      if !значение.utf8.contains(0) { последнийИдентификатор = значение }
    default:
      // Комментарии, retry и будущие поля остаются в байтах рамки, не создавая эффектов.
      break
    }
  }

  private mutating func сохранитьОшибку(
    _ вид: ВидОшибкиLLM, _ пояснение: String
  ) -> ОшибкаLLM {
    let ошибка = ОшибкаLLM(вид, пояснение)
    сохранённаяОшибка = ошибка
    return ошибка
  }
}
