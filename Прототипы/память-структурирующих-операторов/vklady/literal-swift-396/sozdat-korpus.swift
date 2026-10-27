import Foundation

// Детерминированный открытый корпус; не содержит данных рабочей сессии.
@main
struct КорпусЛитерала {
  static func main() throws {
    var входы = [
      "", "hello", "\"", "\\", "\\(1 + 1)",
      "\\(fatalError(\"unexpected interpolation\"))",
      "\"; fatalError(\"escaped\"); let x = \"", "\r\n", "\u{0}",
      "ё", "е\u{0308}", "e\u{0301}", "\u{2028}\u{2029}",
      "👩‍💻", "\u{202E}abc\u{202C}", "\"\"\"", "#\"\\#(1)\"#"
    ]
    for число in UInt32(0)...UInt32(127) { входы.append(String(Unicode.Scalar(число)!)) }
    for число: UInt32 in [0x80, 0x7FF, 0x800, 0xD7FF, 0xE000, 0xFFFF, 0x10000, 0x10FFFF] {
      входы.append(String(Unicode.Scalar(число)!))
    }
    var состояние: UInt64 = 0x396398
    for номер in 0..<512 {
      var значение = String()
      for _ in 0..<(номер % 19 + 1) {
        состояние = состояние &* 6364136223846793005 &+ 1442695040888963407
        let число = UInt32(состояние % 0x110000)
        if let скаляр = Unicode.Scalar(число) { значение.unicodeScalars.append(скаляр) }
      }
      входы.append(значение)
    }
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try FileHandle.standardOutput.write(contentsOf: кодировщик.encode(входы))
  }
}
