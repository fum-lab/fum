import Foundation

struct РазмерСоединенияСтрок {
  struct Результат {
    let содержимоеUTF8: Int
    let размерJSON: Int
  }

  static func прибавитьПроверенно(_ левое: Int, _ правое: Int) throws -> Int {
    let (сумма, переполнение) = левое.addingReportingOverflow(правое)
    guard !переполнение else {
      throw ОшибкаИсполнения("переполнение-JSON", "Переполнение размера JOIN")
    }
    return сумма
  }

  static func проверить(
    _ строки: [String], разделитель: String, пределJSON: Int,
    операция: () throws -> Void
  ) throws -> Результат {
    var содержимое = 0
    var размерJSON = 2

    func размерВнутриСтрокиJSON(_ строка: String) throws -> Int {
      var размер = 0
      for скаляр in строка.unicodeScalars {
        try операция()
        let добавка: Int
        switch скаляр.value {
        case 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x22, 0x5C:
          добавка = 2
        case 0x00...0x1F:
          добавка = 6
        default:
          switch скаляр.value {
          case 0x00...0x7F: добавка = 1
          case 0x80...0x7FF: добавка = 2
          case 0x800...0xFFFF: добавка = 3
          default: добавка = 4
          }
        }
        размер = try прибавитьПроверенно(размер, добавка)
      }
      return размер
    }

    let байтыРазделителя = строки.count > 1 ? разделитель.utf8.count : 0
    let jsonРазделителя = строки.count > 1 ? try размерВнутриСтрокиJSON(разделитель) : 0
    for (номер, строка) in строки.enumerated() {
      if номер > 0 {
        содержимое = try прибавитьПроверенно(содержимое, байтыРазделителя)
        размерJSON = try прибавитьПроверенно(размерJSON, jsonРазделителя)
      }
      содержимое = try прибавитьПроверенно(содержимое, строка.utf8.count)
      размерJSON = try прибавитьПроверенно(размерJSON, try размерВнутриСтрокиJSON(строка))
      guard размерJSON <= пределJSON else {
        throw ОшибкаИсполнения("предел-результата", "JOIN превышает общий бюджет результата")
      }
    }
    guard размерJSON <= пределJSON else {
      throw ОшибкаИсполнения("предел-результата", "JOIN превышает общий бюджет результата")
    }
    return Результат(содержимоеUTF8: содержимое, размерJSON: размерJSON)
  }
}
