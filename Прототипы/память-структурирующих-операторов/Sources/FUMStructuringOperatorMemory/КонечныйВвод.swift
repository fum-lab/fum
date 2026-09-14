import Foundation

public enum КонечныйВвод {
  public static func прочитать(_ поток: FileHandle, предел: Int) throws -> Data {
    guard (0...1_048_576).contains(предел) else {
      throw ОшибкаИсполнения("предел-ввода", "Неверный предел загрузки")
    }
    var данные = Data()
    while данные.count <= предел {
      let часть = try поток.read(upToCount: min(8192, предел + 1 - данные.count)) ?? Data()
      if часть.isEmpty { return данные }
      данные.append(часть)
    }
    throw ОшибкаИсполнения("предел-ввода", "Ввод превышает конечный предел")
  }

  public static func определение(_ путь: String) throws -> Data {
    let поток = try FileHandle(forReadingFrom: URL(fileURLWithPath: путь))
    defer { try? поток.close() }
    return try прочитать(поток, предел: 65_536)
  }
}

public struct ПараметрыИсполнения: Sendable {
  public let путьОпределения: String
  public let типВхода: String
  public let профиль: Bool

  public static func разобрать(_ аргументы: [String]) throws -> ПараметрыИсполнения {
    var значения: [String: String] = [:]
    var профиль = false
    var позиция = 0
    while позиция < аргументы.count {
      let ключ = аргументы[позиция]
      позиция += 1
      if ключ == "--профиль", !профиль {
        профиль = true
        continue
      }
      guard ["--определение", "--вход"].contains(ключ), значения[ключ] == nil,
        позиция < аргументы.count, !аргументы[позиция].isEmpty
      else { throw ОшибкаИсполнения("параметры", "Неизвестный, повторный или неполный параметр") }
      значения[ключ] = аргументы[позиция]
      позиция += 1
    }
    guard let путь = значения["--определение"], let тип = значения["--вход"],
      ["байты", "текст", "скаляры"].contains(тип)
    else { throw ОшибкаИсполнения("параметры", "Нужны --определение и --вход байты|текст|скаляры") }
    return ПараметрыИсполнения(путьОпределения: путь, типВхода: тип, профиль: профиль)
  }

  public func значение(_ данные: Data) throws -> ЗначениеОператора {
    guard данные.count <= 262_144 else {
      throw ОшибкаИсполнения("предел-входа", "Вход превышает предел")
    }
    switch типВхода {
    case "байты": return .байты(Array(данные))
    case "текст":
      guard let текст = String(data: данные, encoding: .utf8) else {
        throw ОшибкаИсполнения("тип-входа", "Текстовый stdin должен быть строгим UTF-8")
      }
      return .текст(текст)
    default:
      var разбор = try РазборОпределения(данные)
      let скаляры = try разбор.разобрать().массив().map { узел in
        let число = try узел.целое()
        guard (0...0x10FFFF).contains(число), !(0xD800...0xDFFF).contains(число) else {
          throw ОшибкаИсполнения("скаляр", "Некорректное значение скаляра")
        }
        return UInt32(число)
      }
      return .скаляры(скаляры)
    }
  }
}
