import Foundation
import МоделиОтвета

do {
  let параметры = Array(CommandLine.arguments.dropFirst())
  guard параметры.count == 3, let бюджет = Int(параметры[2]) else {
    throw NSError(domain: "ПараметрыОтвета", code: 2)
  }
  var данные = Data()
  while let часть = try FileHandle.standardInput.read(upToCount: min(1_048_576, 134_217_729 - данные.count)), !часть.isEmpty {
    данные.append(часть)
    guard данные.count <= 134_217_728 else { throw NSError(domain: "РазмерОтвета", code: 2) }
  }
  let результат = try представитьСнимок(данные, ожидаемыйХэш: параметры[0], задача: параметры[1], максимумБайтов: бюджет)
  try FileHandle.standardOutput.write(contentsOf: результат)
} catch {
  try? FileHandle.standardError.write(contentsOf: Data("Профиль или представление отклонены; полный источник не изменён.\n".utf8))
  exit(2)
}
