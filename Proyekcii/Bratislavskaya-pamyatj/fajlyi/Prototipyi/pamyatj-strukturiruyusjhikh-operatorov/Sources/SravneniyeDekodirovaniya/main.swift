import Foundation
import СтендДекодирования

do {
  let аргументы = Array(CommandLine.arguments.dropFirst())
  guard аргументы == ["проверить"] || аргументы == ["измерить"] else {
    FileHandle.standardError.write(Data("Использование: СравнениеДекодирования проверить|измерить\n".utf8))
    exit(2)
  }
  FileHandle.standardOutput.write(try СтендДекодирования.выполнить(измерять: аргументы == ["измерить"]))
  FileHandle.standardOutput.write(Data([10]))
} catch {
  FileHandle.standardError.write(Data("Ошибка стенда: \(error)\n".utf8))
  exit(1)
}
