import Foundation
import Darwin
import ПроверкаПарНормВетки

do {
    let args = CommandLine.arguments
    guard args.count == 3, args[1] == "--корень", args[2].hasPrefix("/") else {
        throw ОшибкаПарыНорм.отказ("ожидается --корень и абсолютный путь checkout")
    }
    let результат = try проверитьПаруНормВКорне(URL(fileURLWithPath: args[2], isDirectory: true))
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    FileHandle.standardOutput.write(try encoder.encode(результат))
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data("проверка пары: \(error)\n".utf8))
    exit(1)
}
