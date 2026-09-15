import Foundation
import Darwin
import АрхивныйСнимокЗадачи
import СнимокАгентскойЗадачи

struct Замер: Codable {
    let режим: String
    let длительность: UInt64
    let стадии: ПрофильАрхива
    let памятьПикБайты: Int64
    let размерКонтейнера: Int
    let числоЗаписей: Int
    let shaСнимка: String
}
struct ОтчётПрофиля: Codable {
    let версия: Int
    let источник: String
    let байты: Int
    let максимальнаяСтрока: Int
    let одинаковыйРезультат: Bool
    let измерения: [Замер]
    let решение: String
}
func память() -> Int64 {
    var статистика = rusage()
    _ = getrusage(RUSAGE_SELF, &статистика)
    return Int64(статистика.ru_maxrss)
}
@main struct ПрофильАрхивногоСнимка {
    static func main() async throws {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        guard (аргументы.count == 2 || (аргументы.count == 3 && аргументы[2] == "--служебные-оболочки")),
              let размер = Int(аргументы[1]), (1_000_000...200_000_000).contains(размер) else {
            throw ОшибкаАрхива.формат
        }
        let служебныеОболочки = аргументы.count == 3
        // Новый каталог обязателен: профиль не перезаписывает существующий материал.
        let корень = URL(fileURLWithPath: аргументы[0])
        guard !FileManager.default.fileExists(atPath: корень.path) else { throw ОшибкаАрхива.формат }
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true)
        let источник = корень.appendingPathComponent("открытая-синтетика.jsonl")
        FileManager.default.createFile(atPath: источник.path, contents: nil)
        let файл = try FileHandle(forWritingTo: источник)
        let uuid = "11111111-1111-4111-8111-111111111111"
        var мета = "{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(uuid)\",\"cwd\":\"/synthetic/work\"}}\n"
        var контекст = "{\"type\":\"turn_context\",\"payload\":{\"turn_id\":\"33333333-3333-4333-8333-333333333333\",\"model\":\"model-one\"}}\n"
        if служебныеОболочки {
            func обёрнутая(_ строка: String, _ номер: Int) -> String {
                String(строка.dropLast(2)) + ",\"timestamp\":\"2026-09-09T00:00:00Z\",\"ordinal\":\(номер),\"metadata\":{\"synthetic\":true}}\n"
            }
            мета = обёрнутая(мета, 0); контекст = обёрнутая(контекст, 1)
        }
        try файл.write(contentsOf: Data((мета + контекст).utf8))
        var остаток = размер - (мета + контекст).utf8.count
        func префиксСтроки(_ номер: Int) -> String {
            guard служебныеОболочки else { return "{\"type\":\"response_item\",\"payload\":{\"text\":\"" }
            let тип = ["world_state", "token_usage_record", "inter_agent_communication_metadata"][(номер - 2) % 3]
            return "{\"type\":\"\(тип)\",\"timestamp\":\"2026-09-09T00:00:00Z\",\"ordinal\":\(номер),\"metadata\":{\"synthetic\":true},\"payload\":{\"text\":\""
        }
        let суффикс = "\"}}\n"
        var максимум = 0
        var номер = 2
        while остаток > 0 {
            let префикс = префиксСтроки(номер)
            var длина = min(служебныеОболочки ? 262_144 : 3_326_896, остаток)
            let минимум = префикс.utf8.count + суффикс.utf8.count
            let следующийМинимум = префиксСтроки(номер + 1).utf8.count + суффикс.utf8.count
            if остаток > длина && остаток - длина < следующийМинимум { длина -= следующийМинимум }
            guard длина >= минимум else { throw ОшибкаАрхива.формат }
            let строка = Data((префикс + String(repeating: "x", count: длина - минимум) + суффикс).utf8)
            try файл.write(contentsOf: строка)
            максимум = max(максимум, длина); остаток -= длина; номер += 1
        }
        try файл.synchronize(); try файл.close()
        let каталог = корень.appendingPathComponent("контейнер")
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
        var измерения: [Замер] = []
        var эталон: РезультатАрхива?
        var одинаковые = true
        for режим in ["первый-импорт", "повтор-полный-разбор", "повтор-проверенного-префикса", "replay-без-источника"] {
            let начало = DispatchTime.now().uptimeNanoseconds
            let архив = try АрхивЗадачи(корень: каталог, ожидаемыйUUID: uuid, запись: режим != "replay-без-источника")
            let результат: РезультатАрхива
            if режим == "replay-без-источника" {
                // Здесь init уже выполнил replay; удаляем источник перед выдачей снимка.
                try FileManager.default.removeItem(at: источник)
                guard let восстановленный = try await архив.получить() else { throw ОшибкаАрхива.повреждениеАрхива }
                результат = восстановленный
            } else {
                результат = try await архив.импортировать(источник, полныйРазбор: режим == "повтор-полный-разбор")
            }
            let время = DispatchTime.now().uptimeNanoseconds - начало
            if let эталон { одинаковые = одинаковые && эталон == результат } else { эталон = результат }
            let стадии = await архив.профиль()
            let число = await архив.числоЗаписей()
            await архив.закрыть()
            let атрибуты = try FileManager.default.attributesOfItem(atPath: каталог.appendingPathComponent("сегмент.fumobs").path)
            измерения.append(Замер(режим: режим, длительность: время, стадии: стадии,
                памятьПикБайты: память(), размерКонтейнера: (атрибуты[.size] as! NSNumber).intValue,
                числоЗаписей: число, shaСнимка: результат.архив.shaСнимка))
        }
        guard одинаковые, Set(измерения.map(\.размерКонтейнера)).count == 1,
              измерения.allSatisfy({ $0.числоЗаписей == 1 }),
              измерения[2].стадии.разобраноСтрок == 0 else { throw ОшибкаАрхива.повреждениеАрхива }
        let отчёт = ОтчётПрофиля(версия: 1, источник: "открытая синтетика; " + (служебныеОболочки ? "служебные оболочки; " : "") + "ru_maxrss — накопленный пик процесса в байтах macOS",
            байты: размер, максимальнаяСтрока: максимум, одинаковыйРезультат: одинаковые, измерения: измерения,
            решение: "Повтор перечитывает и хэширует прежний префикс, пропускает его повторный JSON-разбор; полный разбор сохранён как эталон. Файловый кэш не очищался; результаты сравниваются через Equatable; SHA снимков выведены отдельно.")
        print(String(decoding: try каноническийJSON(отчёт), as: UTF8.self))
    }
}
