import Foundation
import FUMStructuringOperatorMemory
import Darwin

@main
struct КлиентВыводаСводки {
  private static let пределВывода = 16384
  private enum Отказ: String, Error {
    case аргументы = "число-аргументов"
    case файл = "предел-файла"
    case кодировка = "строгий-UTF8"
    case объект = "ожидался-объект-JSON"
    case тип = "результат-не-текст"
    case результат = "предел-результата"
    case контракт = "контракт-сводки"
    case вывод = "предел-вывода"
  }
  private struct КонтрольСводки: Decodable {
    let схема: String
    let статус: String
    let эффектыРазрешены: Bool
  }
  private static func прочитать(_ путь: String, предел: Int) throws -> Data {
    let файл = try FileHandle(forReadingFrom: URL(fileURLWithPath: путь))
    defer { try? файл.close() }
    var данные = Data()
    while данные.count <= предел {
      guard let часть = try файл.read(upToCount: предел + 1 - данные.count), !часть.isEmpty else { break }
      данные.append(часть)
    }
    guard данные.count <= предел else { throw Отказ.файл }
    return данные
  }
  private static func объект(_ данные: Data, предел: Int) throws -> [String: Any] {
    guard данные.count <= предел else { throw Отказ.результат }
    guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any] else { throw Отказ.объект }
    return объект
  }
  private static func ошибка(_ код: String, библиотека: String? = nil) -> Data {
    var поля: [String: Any] = ["схема": "fum.ошибка-вывода-сводки.1", "код": код, "эффектыРазрешены": false]
    if let библиотека { поля["кодБиблиотеки"] = библиотека.utf8.count <= 128 ? библиотека : "код-вне-предела" }
    if var данные = try? JSONSerialization.data(withJSONObject: поля, options: [.sortedKeys, .withoutEscapingSlashes]), данные.count + 1 <= 1024 {
      данные.append(10)
      return данные
    }
    return Data("{\"схема\":\"fum.ошибка-вывода-сводки.1\",\"код\":\"ошибка-сериализации\",\"эффектыРазрешены\":false}\n".utf8)
  }
  private static func завершить(_ данные: Data) -> Never {
    try? FileHandle.standardError.write(contentsOf: данные)
    exit(1)
  }
  static func main() {
    do {
      let аргументы = CommandLine.arguments
      guard аргументы.count == 3 else { throw Отказ.аргументы }
      let исходник = try прочитать(аргументы[1], предел: 65536)
      let вход = try прочитать(аргументы[2], предел: 262144)
      guard let строкаВхода = String(data: вход, encoding: .utf8) else { throw Отказ.кодировка }
      _ = try объект(вход, предел: 262144)
      let определение = try ОпределениеОператора.разобрать(исходник)
      let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(строкаВхода), пределы: ПределыИсполнения(), профиль: nil)
      guard case .текст(let строкаРезультата) = наблюдение.результат else { throw Отказ.тип }
      let байтыРезультата = Data(строкаРезультата.utf8)
      let результат = try объект(байтыРезультата, предел: пределВывода)
      let контроль = try JSONDecoder().decode(КонтрольСводки.self, from: байтыРезультата)
      guard контроль.схема == "fum.сводка-агентов.1", !контроль.эффектыРазрешены else { throw Отказ.контракт }
      if контроль.статус == "сводка-подготовлена" {
        guard Set(результат.keys) == Set(["схема", "статус", "снимок", "текст", "эффектыРазрешены"]),
              результат["снимок"] is [String: Any], результат["текст"] is String else { throw Отказ.контракт }
      } else if контроль.статус == "диагностика" {
        guard Set(результат.keys) == Set(["схема", "статус", "код", "эффектыРазрешены"]), результат["код"] is String else { throw Отказ.контракт }
      } else { throw Отказ.контракт }
      let итог: [String: Any] = [
        "схема": "fum.исход-вычисления-сводки.1", "версия": 1, "результат": результат,
        "хэшОпределения": наблюдение.хэшОпределения, "хэшВхода": наблюдение.хэшИсходныхБайтов,
        "эффектыРазрешены": false
      ]
      var вывод = try JSONSerialization.data(withJSONObject: итог, options: [.sortedKeys, .withoutEscapingSlashes])
      guard вывод.count + 1 <= пределВывода else { throw Отказ.вывод }
      вывод.append(10)
      try FileHandle.standardOutput.write(contentsOf: вывод)
    } catch let отказ as Отказ { завершить(ошибка(отказ.rawValue))
    } catch let отказ as ОшибкаИсполнения { завершить(ошибка("ошибка-библиотеки", библиотека: отказ.код))
    } catch { завершить(ошибка("ввод-вывод-или-JSON")) }
  }
}
