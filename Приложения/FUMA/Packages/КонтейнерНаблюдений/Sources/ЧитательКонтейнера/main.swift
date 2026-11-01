import КонтейнерНаблюдений
import Foundation
import Darwin

struct Перечень: Encodable {
    let схема = "fum.перечень-контейнера.1"
    let неполный_хвост: Bool
    let записи: [Квитанция]
}

do {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    guard (аргументы.count == 3 && аргументы[0] == "извлечь") ||
          (аргументы.count == 2 && аргументы[0] == "перечень") else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    guard аргументы[1].hasPrefix("/") else {
        throw ОшибкаКонтейнера.небезопасныйПуть
    }
    let читатель = try Сегмент(кореньДанных: URL(fileURLWithPath: аргументы[1]), запись: false)
    defer { читатель.закрыть() }
    let данные: Data
    if аргументы[0] == "перечень" {
        данные = try JSONEncoder().encode(Перечень(неполный_хвост: читатель.естьХвост, записи: читатель.записи))
        guard данные.count <= 67_108_864 else { throw ОшибкаКонтейнера.небезопасныйПуть }
    } else {
        данные = try читатель.извлечь(аргументы[2])
    }
    try FileHandle.standardOutput.write(contentsOf: данные)
} catch {
    try? FileHandle.standardError.write(contentsOf: Data("Читатель: \(error)\n".utf8))
    exit(1)
}
