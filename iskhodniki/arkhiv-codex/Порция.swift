import Foundation
import CryptoKit

public enum ОшибкаАрхиваКодекса: Error, Equatable {
    case закрыт, повреждение, источникИзменён, сессияНеСовпала, неверныйПредел, небезопасныйПуть
}

struct МетаданныеПорции: Swift.Codable, Swift.Equatable {
    let версия: Int
    let вид: String
    let сессия: String
    let подтверждённаяСессия: String?
    let поколение: String
    let начало: UInt64
    let конец: UInt64
    let границаХранимыхСтрок: UInt64
    let обработано: UInt64
    let хэшБайтов: String
    let предыдущаяКвитанция: String

    // Имена схемы 1 сохраняют уже наблюдённые байты предыдущих порций.
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case версия = "версия"
        case вид = "вид"
        case сессия = "сессия"
        case подтверждённаяСессия = "подтверждённаяСессия"
        case поколение = "поколение"
        case начало = "начало"
        case конец = "конец"
        case границаХранимыхСтрок = "границаLF"
        case обработано = "обработано"
        case хэшБайтов = "хэшRAW"
        case предыдущаяКвитанция = "предыдущаяКвитанция"
    }
}

func вычислитьХэшБайтов(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

func кодироватьМетаданные(_ значение: МетаданныеПорции) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(значение)
}

func последняяГраницаСтроки(_ данные: Data, начало: UInt64, прежняя: UInt64) -> UInt64 {
    guard let индекс = данные.lastIndex(of: 10) else { return прежняя }
    return начало + UInt64(данные.distance(from: данные.startIndex, to: индекс)) + 1
}

/// Только ограниченный зонд идентичности после устойчивого append.
/// Слишком длинная строка пропускается зондом и сохраняется RAW буквально.
struct ЗондСессии {
    var строка = Data()
    var пропуск = false
    var найденная: String?
    var конфликт = false
    mutating func принять(_ данные: Data) {
        for байт in данные {
            if байт == 10 {
                if !пропуск,
                   let объект = try? JSONSerialization.jsonObject(with: строка) as? [String: Any],
                   объект["type"] as? String == "session_meta",
                   let тело = объект["payload"] as? [String: Any],
                   let имя = тело["id"] as? String, let идентификатор = UUID(uuidString: имя) {
                    let новый = идентификатор.uuidString.lowercased()
                    if let найденная, найденная != новый { конфликт = true }
                    else { найденная = новый }
                }
                строка.removeAll(keepingCapacity: true); пропуск = false
            } else if !пропуск {
                if строка.count < 65_536 { строка.append(байт) }
                else { строка.removeAll(keepingCapacity: true); пропуск = true }
            }
        }
    }
}
