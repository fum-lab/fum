import Foundation
import CryptoKit
import Darwin

// Малый служебный адаптер текущего среза. Не прежний report/Creator и не второй product SwiftPM.
func хэш(_ данные: Data) -> String { SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined() }
func сохранить(_ значение: [String: Any], _ путь: URL) throws {
    var данные = try JSONSerialization.data(withJSONObject: значение, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes])
    данные.append(10)
    try данные.write(to: путь, options: [.withoutOverwriting])
}

enum ОтказУчёта: Error { case неполно, несовпадение }
func проверитьУчёт(_ каталог: URL, приватный: URL) throws -> Int {
    let имена = try FileManager.default.contentsOfDirectory(atPath: каталог.path)
    let начала = имена.filter { $0.hasSuffix(".nachalo.json") }.sorted()
    let исходы = имена.filter { $0.hasSuffix(".iskhod.json") }.sorted()
    guard !начала.isEmpty, Set(начала.map { $0.replacingOccurrences(of: ".nachalo.json", with: "") })
        == Set(исходы.map { $0.replacingOccurrences(of: ".iskhod.json", with: "") }) else { throw ОтказУчёта.неполно }
    for имя in начала {
        let префикс = String(имя.dropLast(".nachalo.json".count))
        guard let начало = try JSONSerialization.jsonObject(with: Data(contentsOf: каталог.appendingPathComponent(имя))) as? [String: Any],
              let итог = try JSONSerialization.jsonObject(with: Data(contentsOf: каталог.appendingPathComponent(префикс + ".iskhod.json"))) as? [String: Any],
              начало["схема"] as? String == "fum.намерение-адресной-проверки.1",
              итог["схема"] as? String == "fum.исход-адресной-проверки.1",
              начало["статус"] as? String == "намерение", итог["намерение"] as? String == имя,
              начало["название"] as? String == итог["название"] as? String,
              let команда = начало["команда_sha256"] as? String,
              команда == итог["команда_sha256"] as? String,
              let код = итог["код"] as? Int, let состояние = итог["состояние"] as? String,
              let длительность = итог["наносекунды"] as? Int64, длительность >= 0,
              ["успешно", "неуспешно", "прервано", "не запущено"].contains(состояние),
              (состояние == "успешно") == (код == 0),
              хэш(try Data(contentsOf: приватный.appendingPathComponent(префикс + ".argv.json"))) == команда
        else { throw ОтказУчёта.несовпадение }
        for канал in ["stdout", "stderr"] {
            let данные = try Data(contentsOf: приватный.appendingPathComponent(префикс + "." + канал))
            guard итог[канал + "_sha256"] as? String == хэш(данные), итог[канал + "_байтов"] as? Int == данные.count
            else { throw ОтказУчёта.несовпадение }
        }
    }
    return начала.count
}

let параметры = Array(CommandLine.arguments.dropFirst())
if параметры.first == "проверить", параметры.count == 3 {
    do {
        let число = try проверитьУчёт(URL(fileURLWithPath: параметры[1]), приватный: URL(fileURLWithPath: параметры[2]))
        try FileHandle.standardOutput.write(contentsOf: Data("Проверено терминальных пар и точных приватных каналов: \(число)\n".utf8))
        Darwin.exit(0)
    } catch {
        try? FileHandle.standardError.write(contentsOf: Data("Отказ учёта: отсутствуют или различаются свидетельства; повтор процесса не разрешён\n".utf8))
        Darwin.exit(2)
    }
}
guard параметры.count >= 4 else { fatalError("Нужны префикс записи, приватный каталог, название, executable и argv") }
let префикс = URL(fileURLWithPath: параметры[0])
let приватный = URL(fileURLWithPath: параметры[1], isDirectory: true)
let название = параметры[2]
let команда = Array(параметры.dropFirst(3))
let исходнаяКоманда = try JSONSerialization.data(withJSONObject: команда, options: [.sortedKeys])
var входныеЗакрепления: [[String: String]] = []
let собственнаяОбласть = "iskhodniki/zhurnal"
let исполняемаяОснова = "Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory"
var пути = ["Package.swift", "iskhodniki/zapusk/Команда.swift", "iskhodniki/zapusk/ПоляЗапуска.swift"]
for область in [собственнаяОбласть, исполняемаяОснова] {
    if let обход = FileManager.default.enumerator(atPath: область) {
        for case let относительный as String in обход {
            if область == собственнаяОбласть && (относительный == "zhurnal" || относительный.hasPrefix("zhurnal/")) { continue }
            if ["swift", "json"].contains(URL(fileURLWithPath: относительный).pathExtension) {
                пути.append(область + "/" + относительный)
            }
        }
    }
}
for путь in пути.sorted() {
    входныеЗакрепления.append(["путь": путь, "sha256": хэш(try Data(contentsOf: URL(fileURLWithPath: путь)))])
}
let начало = префикс.appendingPathExtension("nachalo.json")
let конец = префикс.appendingPathExtension("iskhod.json")
guard !FileManager.default.fileExists(atPath: начало.path), !FileManager.default.fileExists(atPath: конец.path) else {
    fatalError("Уже есть намерение или исход; сначала чтение прежнего результата")
}
try сохранить(["схема": "fum.намерение-адресной-проверки.1", "название": название,
    "команда_sha256": хэш(исходнаяКоманда), "статус": "намерение",
    "входные_закрепления": входныеЗакрепления,
    "граница": "Исход при отсутствии терминальной записи неизвестен; повтор не разрешён"], начало)
let имя = префикс.lastPathComponent
let вывод = приватный.appendingPathComponent(имя + ".stdout")
let ошибки = приватный.appendingPathComponent(имя + ".stderr")
try Data().write(to: вывод, options: [.withoutOverwriting])
try Data().write(to: ошибки, options: [.withoutOverwriting])
try исходнаяКоманда.write(to: приватный.appendingPathComponent(имя + ".argv.json"), options: [.withoutOverwriting])
let каналВывода = try FileHandle(forWritingTo: вывод)
let каналОшибок = try FileHandle(forWritingTo: ошибки)
let процесс = Process()
процесс.executableURL = URL(fileURLWithPath: команда[0])
процесс.arguments = Array(команда.dropFirst())
процесс.standardOutput = каналВывода
процесс.standardError = каналОшибок
let часы = ContinuousClock()
let старт = часы.now
var код: Int32 = 125
var состояние = "не запущено"
do {
    try процесс.run()
    процесс.waitUntilExit()
    код = процесс.terminationStatus
    состояние = процесс.terminationReason == .exit ? (код == 0 ? "успешно" : "неуспешно") : "прервано"
} catch { состояние = "не запущено" }
try каналВывода.close()
try каналОшибок.close()
let длительность = старт.duration(to: часы.now).components
let наносекунды = длительность.seconds * 1_000_000_000 + длительность.attoseconds / 1_000_000_000
let сырыеВывод = try Data(contentsOf: вывод)
let сырыеОшибки = try Data(contentsOf: ошибки)
try сохранить(["схема": "fum.исход-адресной-проверки.1", "название": название,
    "намерение": начало.lastPathComponent, "команда_sha256": хэш(исходнаяКоманда),
    "код": код, "состояние": состояние, "наносекунды": наносекунды,
    "stdout_sha256": хэш(сырыеВывод), "stdout_байтов": сырыеВывод.count,
    "stderr_sha256": хэш(сырыеОшибки), "stderr_байтов": сырыеОшибки.count,
    "оригиналы": "Точный argv, stdout и stderr сохранены приватно; сырые локальные пути не публикуются"], конец)
try FileHandle.standardOutput.write(contentsOf: Data(("\(название): \(состояние), код \(код), \(наносекунды) нс\n").utf8))
Darwin.exit(код)
