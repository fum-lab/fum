import CryptoKit
import Foundation

public struct ПривязкаСрезаJSONL: Equatable, Sendable {
  public let источник: String
  public let смещение: Int
  public let длина: Int
  public let ожидаемыйSHA256: String

  public init(источник: String, смещение: Int, длина: Int, ожидаемыйSHA256: String) {
    self.источник = источник
    self.смещение = смещение
    self.длина = длина
    self.ожидаемыйSHA256 = ожидаемыйSHA256
  }
}

public struct СрезJSONL: Equatable, Sendable {
  public let данные: Data
  public let привязка: ПривязкаСрезаJSONL

  public init(данные: Data, привязка: ПривязкаСрезаJSONL) {
    self.данные = данные
    self.привязка = привязка
  }
}

public enum КлассификацияПроисхожденияJSONL: Equatable, Sendable {
  case непроверено
}

public enum ОснованиеПроисхожденияJSONL: Equatable, Sendable {
  case буквальнаяРольНеДоказываетАвторство
}

public struct НормализованныйВходСообщенияJSONL: Equatable, Sendable {
  public let исходныйСрез: СрезJSONL
  public let хэшСреза: String
  public let буквальнаяРоль: String
  public let классификацияПроисхождения: КлассификацияПроисхожденияJSONL
  public let основаниеПроисхождения: ОснованиеПроисхожденияJSONL
  public let каноническиеДанные: Data
  public let хэшВходаОператора: String
  public let входОператора: ЗначениеОператора

  init(
    исходныйСрез: СрезJSONL, хэшСреза: String, буквальнаяРоль: String,
    каноническиеДанные: Data, хэшВходаОператора: String
  ) {
    self.исходныйСрез = исходныйСрез
    self.хэшСреза = хэшСреза
    self.буквальнаяРоль = буквальнаяРоль
    классификацияПроисхождения = .непроверено
    основаниеПроисхождения = .буквальнаяРольНеДоказываетАвторство
    self.каноническиеДанные = каноническиеДанные
    self.хэшВходаОператора = хэшВходаОператора
    входОператора = .текст(String(decoding: каноническиеДанные, as: UTF8.self))
  }
}

public enum ИсходНормализацииСообщенияJSONL: Equatable, Sendable {
  case нормализовано(НормализованныйВходСообщенияJSONL)
  case неподдержано(СрезJSONL, код: String)
  case отклонено(СрезJSONL, код: String, вычисленныйSHA256: String?)
}

public struct ЧастьТекстаJSONL: Equatable, Sendable {
  public let тип: String
  public let текст: String

  public init(тип: String, текст: String) {
    self.тип = тип
    self.текст = текст
  }
}

public struct ПроекцияJSONL: Equatable, Sendable {
  public let исходныйСрез: СрезJSONL
  public let хэшСреза: String
  public let payloadТип: String
  public let роль: String?
  public let автор: String
  public let текстовыеЧасти: [ЧастьТекстаJSONL]
  public let хэшРесурсаОпределения: String
  public let хэшОпределения: String
  public let каноническийВходОператора: Data
  public let результатОператора: String
  public let хэшВходаОператора: String
  public let хэшРезультатаОператора: String
  public let наблюдениеОператора: НаблюдениеОператора

  init(
    исходныйСрез: СрезJSONL, хэшСреза: String, payloadТип: String, роль: String?,
    текстовыеЧасти: [ЧастьТекстаJSONL], хэшРесурсаОпределения: String,
    результатОператора: String, каноническийВходОператора: Data,
    хэшРезультатаОператора: String, наблюдениеОператора: НаблюдениеОператора
  ) {
    self.исходныйСрез = исходныйСрез
    self.хэшСреза = хэшСреза
    self.payloadТип = payloadТип
    self.роль = роль
    автор = "неизвестно"
    self.текстовыеЧасти = текстовыеЧасти
    self.хэшРесурсаОпределения = хэшРесурсаОпределения
    хэшОпределения = наблюдениеОператора.хэшОпределения
    self.каноническийВходОператора = каноническийВходОператора
    self.результатОператора = результатОператора
    хэшВходаОператора = наблюдениеОператора.хэшИсходныхБайтов
    self.хэшРезультатаОператора = хэшРезультатаОператора
    self.наблюдениеОператора = наблюдениеОператора
  }
}

public struct ЗамерФасадаJSONL: Equatable, Sendable {
  public let этап: String
  public let наносекунды: UInt64
  public let исход: String
  public let вложенный: Bool

  public init(этап: String, наносекунды: UInt64, исход: String, вложенный: Bool) {
    self.этап = этап
    self.наносекунды = наносекунды
    self.исход = исход
    self.вложенный = вложенный
  }
}

public enum ИсходФасадаJSONL: Equatable, Sendable {
  case проецировано(ПроекцияJSONL)
  case неподдержано(СрезJSONL, код: String)
  case отклонено(СрезJSONL, код: String, вычисленныйSHA256: String?)
}

public enum ОшибкаФасадаJSONL: Error, Equatable, Sendable {
  case ресурсОпределенияОтсутствует
  case ресурсОпределенияНекорректен
  case ресурсОпределенияНеСовпадает(СрезJSONL, вычисленныйSHA256: String)
  case результатОпределенияНекорректен
}

/// Чистая ограниченная проекция одной уже framed записи JSONL.
public enum ФасадJSONL {
  private static let пределБайтовСреза = 262_144
  private static let имяРесурсаОпределения = "vkhod-jsonl-fuma"
  private static let ожидаемыйSHA256РесурсаОпределения =
    "eccd305caf8a61018f3e2607109be5b0f3b8bf20bb1a334ad4ea141a93056fba"

  public static func выполнить(
    _ срез: СрезJSONL,
    профиль: ((ЗамерФасадаJSONL) -> Void)? = nil
  ) throws -> ИсходФасадаJSONL {
    try выполнить(
      срез, изменитьДанныеРесурса: nil, профиль: профиль)
  }

  /// Нормализует одну уже прочитанную и выделенную запись message без загрузки определения
  /// и без вызова `AutomationExecutor`; исполнение остаётся отдельным действием.
  public static func нормализоватьСообщение(
    _ срез: СрезJSONL
  ) -> ИсходНормализацииСообщенияJSONL {
    guard валидныйИсточник(срез.привязка.источник) else {
      return .отклонено(срез, код: "источник", вычисленныйSHA256: nil)
    }
    guard срез.привязка.смещение >= 0 else {
      return .отклонено(срез, код: "отрицательное-смещение", вычисленныйSHA256: nil)
    }
    guard срез.данные.count <= пределБайтовСреза else {
      return .отклонено(срез, код: "предел-среза", вычисленныйSHA256: nil)
    }
    guard срез.привязка.длина >= 0, срез.привязка.длина == срез.данные.count else {
      return .отклонено(срез, код: "длина-среза", вычисленныйSHA256: nil)
    }
    let (_, переполнение) = срез.привязка.смещение.addingReportingOverflow(срез.привязка.длина)
    guard !переполнение else {
      return .отклонено(срез, код: "переполнение-смещения", вычисленныйSHA256: nil)
    }
    guard валидныйSHA256(срез.привязка.ожидаемыйSHA256) else {
      return .отклонено(срез, код: "формат-sha256", вычисленныйSHA256: nil)
    }
    let хэшСреза = Self.sha256(срез.данные)
    guard хэшСреза == срез.привязка.ожидаемыйSHA256 else {
      return .отклонено(срез, код: "sha256-среза", вычисленныйSHA256: хэшСреза)
    }

    do {
      var разбор = try РазборОпределения(срез.данные, входJSON: true)
      let узел = try разбор.разобрать()
      let роль = try буквальнаяРольСообщения(узел)
      let каноническиеБайты = try каноническиеДанные(узел)
      return .нормализовано(НормализованныйВходСообщенияJSONL(
        исходныйСрез: срез,
        хэшСреза: хэшСреза,
        буквальнаяРоль: роль,
        каноническиеДанные: каноническиеБайты,
        хэшВходаОператора: "sha256:" + Self.sha256(каноническиеБайты)))
    } catch {
      return .неподдержано(срез, код: кодОшибки(error))
    }
  }

  static func выполнитьДляПроверки(
    _ срез: СрезJSONL,
    изменитьДанныеРесурса: @escaping (Data) -> Data,
    профиль: ((ЗамерФасадаJSONL) -> Void)? = nil
  ) throws -> ИсходФасадаJSONL {
    try выполнить(
      срез, изменитьДанныеРесурса: изменитьДанныеРесурса, профиль: профиль)
  }

  private static func выполнить(
    _ срез: СрезJSONL,
    изменитьДанныеРесурса: ((Data) -> Data)?,
    профиль: ((ЗамерФасадаJSONL) -> Void)?
  ) throws -> ИсходФасадаJSONL {
    guard валидныйИсточник(срез.привязка.источник) else {
      return .отклонено(срез, код: "источник", вычисленныйSHA256: nil)
    }
    guard срез.привязка.смещение >= 0 else {
      return .отклонено(срез, код: "отрицательное-смещение", вычисленныйSHA256: nil)
    }
    guard срез.данные.count <= пределБайтовСреза else {
      return .отклонено(срез, код: "предел-среза", вычисленныйSHA256: nil)
    }
    guard срез.привязка.длина >= 0, срез.привязка.длина == срез.данные.count else {
      return .отклонено(срез, код: "длина-среза", вычисленныйSHA256: nil)
    }
    let (_, переполнение) = срез.привязка.смещение.addingReportingOverflow(срез.привязка.длина)
    guard !переполнение else {
      return .отклонено(срез, код: "переполнение-смещения", вычисленныйSHA256: nil)
    }
    guard валидныйSHA256(срез.привязка.ожидаемыйSHA256) else {
      return .отклонено(срез, код: "формат-sha256", вычисленныйSHA256: nil)
    }

    let началоПроверки = DispatchTime.now().uptimeNanoseconds
    let хэшСреза = Self.sha256(срез.данные)
    let проверкаУспешна = хэшСреза == срез.привязка.ожидаемыйSHA256
    профиль?(ЗамерФасадаJSONL(
      этап: "проверка-среза", наносекунды: DispatchTime.now().uptimeNanoseconds - началоПроверки,
      исход: проверкаУспешна ? "успешно" : "отказ", вложенный: false))
    guard проверкаУспешна else {
      return .отклонено(срез, код: "sha256-среза", вычисленныйSHA256: хэшСреза)
    }

    let началоРазбора = DispatchTime.now().uptimeNanoseconds
    let каноническийВход: Data
    do {
      var разбор = try РазборОпределения(срез.данные, входJSON: true)
      let вход = try разбор.разобрать()
      каноническийВход = try каноническиеДанные(вход)
    } catch {
      профиль?(ЗамерФасадаJSONL(
        этап: "закрытый-разбор", наносекунды: DispatchTime.now().uptimeNanoseconds - началоРазбора,
        исход: "неподдержано", вложенный: false))
      return .неподдержано(срез, код: кодОшибки(error))
    }
    профиль?(ЗамерФасадаJSONL(
      этап: "закрытый-разбор", наносекунды: DispatchTime.now().uptimeNanoseconds - началоРазбора,
      исход: "успешно", вложенный: false))

    let началоРесурса = DispatchTime.now().uptimeNanoseconds
    guard let url = Bundle.module.url(
      forResource: имяРесурсаОпределения, withExtension: "json", subdirectory: "Определения")
    else { throw ОшибкаФасадаJSONL.ресурсОпределенияОтсутствует }
    let прочитанныеДанныеРесурса: Data
    let определение: ОпределениеОператора
    do {
      прочитанныеДанныеРесурса = try Data(contentsOf: url)
    } catch {
      throw ОшибкаФасадаJSONL.ресурсОпределенияНекорректен
    }
    let данныеРесурса = изменитьДанныеРесурса?(прочитанныеДанныеРесурса)
      ?? прочитанныеДанныеРесурса
    let хэшРесурса = Self.sha256(данныеРесурса)
    guard хэшРесурса == ожидаемыйSHA256РесурсаОпределения else {
      профиль?(ЗамерФасадаJSONL(
        этап: "ресурс-определения",
        наносекунды: DispatchTime.now().uptimeNanoseconds - началоРесурса,
        исход: "отказ", вложенный: false))
      throw ОшибкаФасадаJSONL.ресурсОпределенияНеСовпадает(
        срез, вычисленныйSHA256: хэшРесурса)
    }
    do {
      определение = try ОпределениеОператора.разобрать(данныеРесурса)
    } catch {
      throw ОшибкаФасадаJSONL.ресурсОпределенияНекорректен
    }
    профиль?(ЗамерФасадаJSONL(
      этап: "ресурс-определения", наносекунды: DispatchTime.now().uptimeNanoseconds - началоРесурса,
      исход: "успешно", вложенный: false))

    let входОператора = String(decoding: каноническийВход, as: UTF8.self)
    let началоИсполнения = DispatchTime.now().uptimeNanoseconds
    var замерыИсполнителя: [ЗамерИсполнения] = []
    let наблюдение: НаблюдениеОператора
    do {
      наблюдение = try AutomationExecutor.выполнить(
        определение, вход: .текст(входОператора),
        профиль: { замерыИсполнителя.append($0) })
    } catch {
      for замер in замерыИсполнителя {
        профиль?(ЗамерФасадаJSONL(
          этап: "исполнитель.\(замер.стадия)", наносекунды: замер.наносекунды,
          исход: замер.исход, вложенный: true))
      }
      профиль?(ЗамерФасадаJSONL(
        этап: "исполнитель", наносекунды: DispatchTime.now().uptimeNanoseconds - началоИсполнения,
        исход: "неподдержано", вложенный: false))
      return .неподдержано(срез, код: кодОшибки(error))
    }
    for замер in замерыИсполнителя {
      профиль?(ЗамерФасадаJSONL(
        этап: "исполнитель.\(замер.стадия)", наносекунды: замер.наносекунды,
        исход: замер.исход, вложенный: true))
    }
    профиль?(ЗамерФасадаJSONL(
      этап: "исполнитель", наносекунды: DispatchTime.now().uptimeNanoseconds - началоИсполнения,
      исход: "успешно", вложенный: false))

    guard case .текст(let результатОператора) = наблюдение.результат else {
      throw ОшибкаФасадаJSONL.результатОпределенияНекорректен
    }
    let началоСборки = DispatchTime.now().uptimeNanoseconds
    let проекция: ПроекцияJSONL
    do {
      проекция = try Self.собратьПроекцию(
        срез: срез, хэшСреза: хэшСреза, каноническийВход: каноническийВход,
        данныеРесурса: данныеРесурса, результат: результатОператора, наблюдение: наблюдение)
    } catch {
      профиль?(ЗамерФасадаJSONL(
        этап: "сборка-проекции", наносекунды: DispatchTime.now().uptimeNanoseconds - началоСборки,
        исход: "неподдержано", вложенный: false))
      return .неподдержано(срез, код: кодОшибки(error))
    }
    профиль?(ЗамерФасадаJSONL(
      этап: "сборка-проекции", наносекунды: DispatchTime.now().uptimeNanoseconds - началоСборки,
      исход: "успешно", вложенный: false))
    return .проецировано(проекция)
  }

  private static func собратьПроекцию(
    срез: СрезJSONL, хэшСреза: String, каноническийВход: Data, данныеРесурса: Data,
    результат: String, наблюдение: НаблюдениеОператора
  ) throws -> ПроекцияJSONL {
    var разбор = try РазборОпределения(Data(результат.utf8), входJSON: true)
    let поля = try разбор.разобрать().объект(["classification", "payload_type", "role", "text_parts"])
    let classification = try поля["classification"]!.строка()
    let payloadType = try поля["payload_type"]!.строка()
    guard ["message", "function_call_output"].contains(classification),
      payloadType == classification
    else { throw ОшибкаИсполнения("неподдержанный-тип", "Неподдержанный тип response_item") }

    let роль: String?
    switch поля["role"]! {
    case .пусто: роль = nil
    case .строка(let строка): роль = строка
    default: throw ОшибкаИсполнения("тип-роли", "Метка роли не является строкой")
    }
    let части = try поля["text_parts"]!.массив().map { часть -> ЧастьТекстаJSONL in
      let значения = try часть.объект(["type", "text"])
      return ЧастьТекстаJSONL(
        тип: try значения["type"]!.строка(), текст: try значения["text"]!.строка())
    }
    if classification == "message" {
      guard роль != nil,
        части.allSatisfy({ ["input_text", "output_text", "text"].contains($0.тип) })
      else { throw ОшибкаИсполнения("неподдержанная-часть", "Неподдержанная форма message") }
    } else {
      guard роль == nil, части.count == 1,
        части[0].тип == "function_call_output"
      else { throw ОшибкаИсполнения("неподдержанный-output", "Неподдержанная форма output") }
    }
    return ПроекцияJSONL(
      исходныйСрез: срез, хэшСреза: хэшСреза, payloadТип: payloadType, роль: роль,
      текстовыеЧасти: части, хэшРесурсаОпределения: Self.sha256(данныеРесурса),
      результатОператора: результат, каноническийВходОператора: каноническийВход,
      хэшРезультатаОператора: Self.sha256(Data(результат.utf8)),
      наблюдениеОператора: наблюдение)
  }

  private static func валидныйИсточник(_ источник: String) -> Bool {
    !источник.isEmpty && источник.utf8.count <= 256
      && источник.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
  }

  private static func буквальнаяРольСообщения(_ узел: УзелОпределения) throws -> String {
    guard case .объект(let запись) = узел,
      запись["type"] == .строка("response_item"),
      case .some(.объект(let полезнаяНагрузка)) = запись["payload"],
      полезнаяНагрузка["type"] == .строка("message"),
      case .some(.строка(let роль)) = полезнаяНагрузка["role"],
      case .some(.массив(_)) = полезнаяНагрузка["content"]
    else {
      throw ОшибкаИсполнения("неподдержанная-форма", "Ожидалась уже выделенная запись message")
    }
    return роль
  }

  private static func валидныйSHA256(_ хэш: String) -> Bool {
    хэш.count == 64 && хэш.utf8.allSatisfy {
      (48...57).contains($0) || (97...102).contains($0)
    }
  }

  private static func кодОшибки(_ ошибка: any Error) -> String {
    (ошибка as? ОшибкаИсполнения)?.код ?? "закрытый-json"
  }

  private static func sha256(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  }
}
