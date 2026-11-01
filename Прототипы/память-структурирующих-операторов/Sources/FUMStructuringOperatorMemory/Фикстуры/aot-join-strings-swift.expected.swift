import Foundation

@main enum СгенерированнаяПрограмма {
  static func main() throws {
    let части: [String] = [
      "\u{46}\u{55}\u{4d}\u{41}",
      "\u{53}\u{77}\u{69}\u{66}\u{74}",
    ]
    let разделитель: String = "\u{20}\u{2192}\u{20}"
    let результат = части.joined(separator: разделитель)
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let данные = try кодировщик.encode(результат)
    FileHandle.standardOutput.write(данные)
  }
}
