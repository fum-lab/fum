import Foundation
import LinguisticKit

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

private func fail(_ message: String, code: Int32) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(code)
}

let inputData = FileHandle.standardInput.readDataToEndOfFile()
let sources: [String]
do {
  sources = try JSONDecoder().decode([String].self, from: inputData)
} catch {
  fail("Ожидается JSON-массив строк: \(error)", code: 2)
}

let transliterations = sources.map { source -> String in
  guard
    let result = source.applyingTransform(
      from: .Cyrl,
      to: .Latn,
      withTable: .ru
    )
  else {
    fail("Таблица ru не поддерживает Cyrl → Latn", code: 3)
  }
  return result
}

do {
  let outputData = try JSONEncoder().encode(transliterations)
  FileHandle.standardOutput.write(outputData)
  FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
  fail("Не удалось закодировать JSON-ответ: \(error)", code: 4)
}
