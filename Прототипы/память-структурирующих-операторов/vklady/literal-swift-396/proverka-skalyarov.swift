import Foundation

@main
struct ПроверкаСкаляров {
  static func main() throws {
    var проверено = 0
    for число in UInt32(0)...UInt32(0x10FFFF) {
      guard let скаляр = Unicode.Scalar(число) else { continue }
      let вход = String(скаляр)
      let выход = try ЛитералSwift.построить(
        вход, пределИсходника: 32, пределJSON: 64, операция: {})
      let оценка = try ЛитералSwift.оценить(
        вход, пределИсходника: 32, пределJSON: 64, операция: {})
      let ожидаемый = "\"\\u{" + String(число, radix: 16) + "}\""
      guard выход.utf8.elementsEqual(ожидаемый.utf8),
        выход.utf8.count == оценка.исходник,
        try каноническиеДанные(выход).count == оценка.json
      else { throw ОшибкаИсполнения("тест", "Несовпадение скаляра \(число)") }
      проверено += 1
    }
    print("PASS scalar_encoding_and_budgets=\(проверено)")
  }
}
