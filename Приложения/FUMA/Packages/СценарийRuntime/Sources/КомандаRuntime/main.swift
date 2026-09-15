import СценарийRuntime
import Foundation

do {
    let аргументы = Array(CommandLine.arguments.dropFirst())
    guard аргументы.count == 4 else {
        throw NSError(domain: "СценарийRuntime", code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Нужны: определение.json вход.bin корень-контейнера каталог-результата"])
    }
    let начало = DispatchTime.now().uptimeNanoseconds
    let результат = try СценарийRuntime.выполнить(
        вход: Data(contentsOf: URL(fileURLWithPath: аргументы[1])),
        корень: URL(fileURLWithPath: аргументы[2]),
        определение: Data(contentsOf: URL(fileURLWithPath: аргументы[0])))
    let каталог = URL(fileURLWithPath: аргументы[3])
    try результат.выход.write(to: каталог.appendingPathComponent("выход.bin"))
    try результат.повтор.write(to: каталог.appendingPathComponent("повтор.bin"))
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys]
    try кодировщик.encode(результат.профиль).write(to: каталог.appendingPathComponent("профиль.json"))
    let длительность = DispatchTime.now().uptimeNanoseconds - начало
    print("{\"схема\":\"fum.сценарий-runtime.1\",\"наносекунды\":\(длительность),\"байты\":\(результат.выход.count)}")
} catch {
    try? FileHandle.standardError.write(contentsOf: Data("\(error)\n".utf8))
    exit(1)
}
