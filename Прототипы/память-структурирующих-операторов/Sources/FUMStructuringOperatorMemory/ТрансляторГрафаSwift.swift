import Foundation

enum ТрансляторГрафаSwift {
  static func перевести(_ граф: ГрафJSON, пределИсходника: Int) throws -> String {
    guard !граф.композиция else { throw отказНеподдержанногоГрафа() }
    let поля = try граф.узел.объект(["схема", "числа", "переменные", "результат"])
    guard поля["схема"] == .строка("fuma.граф-JSON.1"),
      поля["переменные"] == .массив([]),
      case .массив(let вызов) = поля["результат"], вызов.count == 3,
      вызов[0] == .строка("соединить-строки"),
      case .массив(let массив) = вызов[1], массив.first == .строка("массив"),
      case .строка(let разделитель) = вызов[2]
    else { throw отказНеподдержанногоГрафа() }

    var части: [String] = []
    for элемент in массив.dropFirst() {
      guard case .строка(let строка) = элемент else { throw отказНеподдержанногоГрафа() }
      части.append(строка)
    }

    var фрагменты: [String] = []
    var размерИсходника = 0
    func добавить(_ фрагмент: String) throws {
      let (новыйРазмер, переполнение) = размерИсходника.addingReportingOverflow(фрагмент.utf8.count)
      guard !переполнение else {
        throw ОшибкаИсполнения("переполнение-исходника-aot", "Размер Swift-исходника не представим")
      }
      guard пределИсходника >= 0, новыйРазмер <= пределИсходника else {
        throw ОшибкаИсполнения("предел-исходника-aot", "Swift-исходник превышает бюджет")
      }
      фрагменты.append(фрагмент)
      размерИсходника = новыйРазмер
    }
    func литерал(_ строка: String) throws -> String {
      try КодированиеЛитералаSwift.кодировать(
        строка, пределИсходныхБайтов: max(0, пределИсходника - размерИсходника),
        пределJSON: Int.max, операция: {})
    }

    try добавить("""
      import Foundation

      private enum ОшибкаAOT: Error { case переполнение, предел }

      private func прибавитьПроверенно(_ a: Int, _ b: Int) throws -> Int {
        let (сумма, переполнение) = a.addingReportingOverflow(b)
        guard !переполнение else { throw ОшибкаAOT.переполнение }
        return сумма
      }

      private func размерJSONВнутриСтроки(_ строка: String) throws -> Int {
        var размер = 0
        for scalar in строка.unicodeScalars {
          let добавка: Int
          switch scalar.value {
          case 0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x22, 0x5C: добавка = 2
          case 0x00...0x1F: добавка = 6
          case 0x00...0x7F: добавка = 1
          case 0x80...0x7FF: добавка = 2
          case 0x800...0xFFFF: добавка = 3
          default: добавка = 4
          }
          размер = try прибавитьПроверенно(размер, добавка)
        }
        return размер
      }

      @main enum СгенерированнаяПрограмма {
        static func main() throws {
          let части: [String] = [
      """)
    for (индекс, строка) in части.enumerated() {
      if индекс > 0 { try добавить(",\n") }
      try добавить(try литерал(строка))
    }
    try добавить("\n")
    try добавить("""
          ]
          let разделитель: String =
      """)
    try добавить(" ")
    try добавить(try литерал(разделитель))
    try добавить("""

          let предел: Int
          if let аргумент = CommandLine.arguments.dropFirst().first {
            guard let число = Int(аргумент) else { throw ОшибкаAOT.предел }
            предел = число
          } else {
            предел = \(ПределыИсполнения().байтовРезультата)
          }
          guard предел >= 0 else { throw ОшибкаAOT.предел }
          var размерUTF8 = 0
          var размерJSON = 2
          for индекс in части.indices {
            if индекс > 0 {
              размерUTF8 = try прибавитьПроверенно(размерUTF8, разделитель.utf8.count)
              размерJSON = try прибавитьПроверенно(
                размерJSON, размерJSONВнутриСтроки(разделитель))
            }
            размерUTF8 = try прибавитьПроверенно(размерUTF8, части[индекс].utf8.count)
            размерJSON = try прибавитьПроверенно(
              размерJSON, размерJSONВнутриСтроки(части[индекс]))
          }
          guard размерJSON <= предел else { throw ОшибкаAOT.предел }

          var результат = String()
          результат.reserveCapacity(размерUTF8)
          for индекс in части.indices {
            if индекс > 0 { результат.append(contentsOf: разделитель) }
            результат.append(contentsOf: части[индекс])
          }
          let encoder = JSONEncoder()
          encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
          let данные = try encoder.encode(результат)
          guard данные.count == размерJSON, данные.count <= предел else {
            throw ОшибкаAOT.предел
          }
          FileHandle.standardOutput.write(данные)
        }
      }
      """)

    let исходник = фрагменты.joined()
    guard исходник.utf8.count == размерИсходника else {
      throw ОшибкаИсполнения("несовпадение-размера-aot", "Размер Swift-исходника изменился при сборке")
    }
    return исходник
  }

  private static func отказНеподдержанногоГрафа() -> ОшибкаИсполнения {
    ОшибкаИсполнения("aot-операция", "AOT пока поддерживает только корневой JOIN строковых литералов")
  }
}
