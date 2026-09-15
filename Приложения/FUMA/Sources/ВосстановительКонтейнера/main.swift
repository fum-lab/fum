import КонтейнерНаблюдений
import Foundation
import Darwin

do {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    guard аргументы.count == 1, аргументы[0].hasPrefix("/") else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    let сегмент = try Сегмент(кореньДанных: URL(fileURLWithPath: аргументы[0]), запись: true, создать: false)
    defer { сегмент.закрыть() }
    try сегмент.восстановитьХвост()
    try вывестиJSON(["сохранено_записей": сегмент.записи.count])
} catch {
    try? FileHandle.standardError.write(contentsOf: Data("Восстановитель: \(error)\n".utf8))
    exit(1)
}
