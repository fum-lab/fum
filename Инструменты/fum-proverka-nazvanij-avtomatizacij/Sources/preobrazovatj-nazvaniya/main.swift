import Foundation
import LinguisticKit

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

private func завершитьСОшибкой(_ сообщение: String, код: Int32) -> Never {
  FileHandle.standardError.write(Data((сообщение + "\n").utf8))
  exit(код)
}

let входныеДанные = FileHandle.standardInput.readDataToEndOfFile()
let исходныеСтроки: [String]
do {
  исходныеСтроки = try JSONDecoder().decode([String].self, from: входныеДанные)
} catch {
  завершитьСОшибкой("Ожидается JSON-массив строк: \(error)", код: 2)
}

let транслитерации = исходныеСтроки.map { исходнаяСтрока -> String in
  guard
    let результат = исходнаяСтрока.applyingTransform(
      from: .Cyrl,
      to: .Latn,
      withTable: .ru
    )
  else {
    завершитьСОшибкой("Таблица ru не поддерживает Cyrl → Latn", код: 3)
  }
  return результат
}

do {
  let выходныеДанные = try JSONEncoder().encode(транслитерации)
  FileHandle.standardOutput.write(выходныеДанные)
  FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
  завершитьСОшибкой("Не удалось закодировать JSON-ответ: \(error)", код: 4)
}
