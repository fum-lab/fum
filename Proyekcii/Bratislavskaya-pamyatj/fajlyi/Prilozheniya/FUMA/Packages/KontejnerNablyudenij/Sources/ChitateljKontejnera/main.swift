import КонтейнерНаблюдений
import Foundation
import Darwin

do {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    guard аргументы.count == 3, аргументы[0] == "извлечь", аргументы[1].hasPrefix("/") else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    let читатель = try Сегмент(кореньДанных: URL(fileURLWithPath: аргументы[1]), запись: false)
    defer { читатель.закрыть() }
    try FileHandle.standardOutput.write(contentsOf: читатель.извлечь(аргументы[2]))
} catch {
    try? FileHandle.standardError.write(contentsOf: Data("Читатель: \(error)\n".utf8))
    exit(1)
}
