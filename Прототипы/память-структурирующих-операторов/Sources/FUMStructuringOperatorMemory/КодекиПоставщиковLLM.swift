import Foundation

// Числа неизвестных полей не проходят через Double/Int и не пересериализуются.
// Авторитетным оригиналом каждого результата и события остаётся исходный Data.
private indirect enum ЗначениеJSONКодекаLLM: Sendable {
  case объект([String: ЗначениеJSONКодекаLLM])
  case массив([ЗначениеJSONКодекаLLM])
  case строка(String)
  case число(String)
  case логическое(Bool)
  case пусто

  var словарь: [String: ЗначениеJSONКодекаLLM]? {
    if case .объект(let значение) = self { return значение }
    return nil
  }
  var список: [ЗначениеJSONКодекаLLM]? {
    if case .массив(let значение) = self { return значение }
    return nil
  }
  var текст: String? {
    if case .строка(let значение) = self { return значение }
    return nil
  }
  var целое: Int? {
    guard case .число(let значение) = self, let число = Int(значение), число >= 0 else {
      return nil
    }
    return число
  }
  var код: String? {
    switch self {
    case .строка(let значение), .число(let значение): return значение
    default: return nil
    }
  }
  var отсутствует: Bool {
    if case .пусто = self { return true }
    return false
  }
}

/// Ограниченный RFC 8259-разбор с сохранением произвольной десятичной лексемы.
/// Это отдельный native HTTP-профиль, а не закрытый язык операторов FUM.
private struct РазборJSONКодекаLLM {
  let исходник: Data
  let байты: [UInt8]
  var позиция = 0
  var узлы = 0

  init(_ данные: Data) throws {
    guard данные.count <= 16_777_216 else {
      throw ОшибкаLLM(.пределРесурсов, "Превышен предел native JSON LLM", нативныеДанные: данные)
    }
    исходник = данные
    байты = Array(данные)
  }

  mutating func разобрать() throws -> [String: ЗначениеJSONКодекаLLM] {
    if байты.starts(with: [0xEF, 0xBB, 0xBF]) { позиция = 3 }
    let значение = try прочитать(глубина: 0)
    пропуститьПробелы()
    guard позиция == байты.count else { throw неверныйJSON() }
    guard let объект = значение.словарь else {
      throw ОшибкаLLM(.протокол, "Native JSON LLM должен быть объектом", нативныеДанные: исходник)
    }
    return объект
  }

  private func неверныйJSON() -> ОшибкаLLM {
    ОшибкаLLM(.неверныйJSON, "Неверный native JSON LLM", нативныеДанные: исходник)
  }
  private mutating func пропуститьПробелы() {
    while позиция < байты.count, [UInt8(0x20), 0x09, 0x0A, 0x0D].contains(байты[позиция]) {
      позиция += 1
    }
  }
  private mutating func принять(_ байт: UInt8) -> Bool {
    guard позиция < байты.count, байты[позиция] == байт else { return false }
    позиция += 1
    return true
  }
  private mutating func литерал(_ текст: String) throws {
    let конец = позиция + текст.utf8.count
    guard конец <= байты.count, байты[позиция..<конец].elementsEqual(текст.utf8) else {
      throw неверныйJSON()
    }
    позиция = конец
  }
  private mutating func прочитать(глубина: Int) throws -> ЗначениеJSONКодекаLLM {
    guard глубина <= 128, узлы < 1_048_576 else {
      throw ОшибкаLLM(
        .пределРесурсов, "Превышен предел структуры native JSON LLM", нативныеДанные: исходник)
    }
    узлы += 1
    пропуститьПробелы()
    guard позиция < байты.count else { throw неверныйJSON() }
    switch байты[позиция] {
    case 0x7B:
      позиция += 1
      пропуститьПробелы()
      var объект: [String: ЗначениеJSONКодекаLLM] = [:]
      if принять(0x7D) { return .объект(объект) }
      while true {
        пропуститьПробелы()
        let ключ = try прочитатьСтроку()
        guard объект[ключ] == nil else {
          throw ОшибкаLLM(.протокол, "Повторный ключ native JSON LLM", нативныеДанные: исходник)
        }
        пропуститьПробелы()
        guard принять(0x3A) else { throw неверныйJSON() }
        объект[ключ] = try прочитать(глубина: глубина + 1)
        пропуститьПробелы()
        if принять(0x7D) { return .объект(объект) }
        guard принять(0x2C) else { throw неверныйJSON() }
      }
    case 0x5B:
      позиция += 1
      пропуститьПробелы()
      var массив: [ЗначениеJSONКодекаLLM] = []
      if принять(0x5D) { return .массив(массив) }
      while true {
        массив.append(try прочитать(глубина: глубина + 1))
        пропуститьПробелы()
        if принять(0x5D) { return .массив(массив) }
        guard принять(0x2C) else { throw неверныйJSON() }
      }
    case 0x22: return .строка(try прочитатьСтроку())
    case 0x74:
      try литерал("true")
      return .логическое(true)
    case 0x66:
      try литерал("false")
      return .логическое(false)
    case 0x6E:
      try литерал("null")
      return .пусто
    case 0x2D, 0x30...0x39: return .число(try прочитатьЧисло())
    default: throw неверныйJSON()
    }
  }
  private mutating func прочитатьСтроку() throws -> String {
    let начало = позиция
    guard принять(0x22) else { throw неверныйJSON() }
    while позиция < байты.count {
      let байт = байты[позиция]
      позиция += 1
      if байт == 0x22 {
        do {
          return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция]))
        } catch { throw неверныйJSON() }
      }
      guard байт >= 0x20 else { throw неверныйJSON() }
      if байт == 0x5C {
        guard позиция < байты.count else { throw неверныйJSON() }
        let экранированный = байты[позиция]
        позиция += 1
        if экранированный == 0x75 {
          guard позиция + 4 <= байты.count else { throw неверныйJSON() }
          for шестнадцатеричный in байты[позиция..<(позиция + 4)] {
            guard
              (0x30...0x39).contains(шестнадцатеричный)
                || (0x41...0x46).contains(шестнадцатеричный)
                || (0x61...0x66).contains(шестнадцатеричный)
            else { throw неверныйJSON() }
          }
          позиция += 4
        } else {
          guard [UInt8(0x22), 0x5C, 0x2F, 0x62, 0x66, 0x6E, 0x72, 0x74].contains(экранированный)
          else {
            throw неверныйJSON()
          }
        }
      }
    }
    throw неверныйJSON()
  }
  private mutating func прочитатьЧисло() throws -> String {
    let начало = позиция
    _ = принять(0x2D)
    guard позиция < байты.count else { throw неверныйJSON() }
    if !принять(0x30) {
      guard (0x31...0x39).contains(байты[позиция]) else { throw неверныйJSON() }
      while позиция < байты.count, (0x30...0x39).contains(байты[позиция]) { позиция += 1 }
    }
    if принять(0x2E) {
      let цифра = позиция
      while позиция < байты.count, (0x30...0x39).contains(байты[позиция]) { позиция += 1 }
      guard позиция > цифра else { throw неверныйJSON() }
    }
    if принять(0x65) || принять(0x45) {
      if !принять(0x2B) { _ = принять(0x2D) }
      let цифра = позиция
      while позиция < байты.count, (0x30...0x39).contains(байты[позиция]) { позиция += 1 }
      guard позиция > цифра else { throw неверныйJSON() }
    }
    return String(decoding: байты[начало..<позиция], as: UTF8.self)
  }
}

private func объектJSONКодекаLLM(_ данные: Data) throws -> [String: ЗначениеJSONКодекаLLM] {
  var разбор = try РазборJSONКодекаLLM(данные)
  return try разбор.разобрать()
}

private struct СообщениеHTTPКодекаLLM: Encodable, Sendable {
  let роль: String
  let содержимое: String
  enum CodingKeys: String, CodingKey {
    case роль = "role"
    case содержимое = "content"
  }
}
private struct ТелоResponsesКодекаLLM: Encodable, Sendable {
  let модель: String
  let вход: [СообщениеHTTPКодекаLLM]
  let инструкции: String?
  let предел: Int
  let поток: Bool
  let хранить = false
  enum CodingKeys: String, CodingKey {
    case модель = "model"
    case вход = "input"
    case инструкции = "instructions"
    case предел = "max_output_tokens"
    case поток = "stream"
    case хранить = "store"
  }
}
private struct ТелоАнтропикКодекаLLM: Encodable, Sendable {
  let модель: String
  let сообщения: [СообщениеHTTPКодекаLLM]
  let система: String?
  let предел: Int
  let поток: Bool
  enum CodingKeys: String, CodingKey {
    case модель = "model"
    case сообщения = "messages"
    case система = "system"
    case предел = "max_tokens"
    case поток = "stream"
  }
}
private func байтыЗапросаКодекаLLM<Тело: Encodable>(_ тело: Тело) throws -> Data {
  let кодировщик = JSONEncoder()
  кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  do { return try кодировщик.encode(тело) } catch {
    throw ОшибкаLLM(.неверныйЗапрос, "Не удалось закодировать запрос LLM")
  }
}
private func проверитьЗапросКодекаLLM(_ запрос: ЗапросLLM, поставщик: ПоставщикLLM) throws {
  guard запрос.поставщик == поставщик,
    !запрос.запрошеннаяМодель.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
    !запрос.сообщения.isEmpty, запрос.пределТокенов > 0,
    !запрос.секрет.идентификатор.isEmpty
  else { throw ОшибкаLLM(.неверныйЗапрос, "Неверный профиль запроса LLM") }
}
private func подготовитьResponsesКодекаLLM(
  _ запрос: ЗапросLLM, поставщик: ПоставщикLLM, адрес: String
) throws -> HTTPЗапросLLM {
  try проверитьЗапросКодекаLLM(запрос, поставщик: поставщик)
  guard let конечныйАдрес = URL(string: адрес) else {
    throw ОшибкаLLM(.протокол, "Неверный закреплённый адрес LLM")
  }
  let тело = ТелоResponsesКодекаLLM(
    модель: запрос.запрошеннаяМодель,
    вход: запрос.сообщения.map { .init(роль: $0.роль.rawValue, содержимое: $0.текст) },
    инструкции: запрос.система, предел: запрос.пределТокенов, поток: запрос.поток)
  return HTTPЗапросLLM(
    адрес: конечныйАдрес,
    заголовки: [
      "Content-Type": "application/json",
      "Accept": запрос.поток ? "text/event-stream" : "application/json",
    ],
    тело: try байтыЗапросаКодекаLLM(тело), секрет: запрос.секрет)
}

private func ошибкаПоставщикаLLM(
  _ объект: [String: ЗначениеJSONКодекаLLM], сырые: Data, подтверждённаяОшибка: Bool = false
) -> ОшибкаLLM? {
  let ошибка = объект["error"]
  guard
    подтверждённаяОшибка || объект["type"]?.текст == "error"
      || (ошибка != nil && ошибка?.отсутствует == false)
  else { return nil }
  let поля = ошибка?.словарь ?? объект
  let пояснение = поля["message"]?.текст ?? ошибка?.текст ?? "Поставщик сообщил об ошибке"
  let код = поля["code"]?.код ?? поля["type"]?.текст
  return ОшибкаLLM(.поставщик, пояснение, кодПоставщика: код, нативныеДанные: сырые)
}
private func отказПоставщикаLLM(
  _ ошибка: ОшибкаLLM, объект: [String: ЗначениеJSONКодекаLLM], сырые: Data, текст: String = ""
) -> ОтветПоставщикаLLM {
  .init(
    идентификатор: объект["id"]?.текст, наблюдаемаяМодель: объект["model"]?.текст,
    текст: текст, завершение: .отказ, причинаОстановки: ошибка.кодПоставщика,
    учёт: учётКодекаLLM(объект["usage"], сырые: сырые), нативныеДанные: сырые, ошибка: ошибка)
}
private func учётКодекаLLM(_ значение: ЗначениеJSONКодекаLLM?, сырые: Data) -> УчётLLM? {
  guard let значение, !значение.отсутствует else { return nil }
  let поля = значение.словарь ?? [:]
  return .init(
    входныеТокены: поля["input_tokens"]?.целое,
    выходныеТокены: поля["output_tokens"]?.целое,
    всегоТокенов: поля["total_tokens"]?.целое, нативныеСнимки: [сырые])
}
private func текстResponsesКодекаLLM(_ вывод: [ЗначениеJSONКодекаLLM]) -> (String, String?) {
  var текст = ""
  var отказ: String?
  for элемент in вывод {
    guard let сообщение = элемент.словарь, сообщение["type"]?.текст == "message",
      let содержимое = сообщение["content"]?.список
    else { continue }
    for часть in содержимое {
      guard let поля = часть.словарь else { continue }
      if поля["type"]?.текст == "output_text", let фрагмент = поля["text"]?.текст {
        текст += фрагмент
      }
      if поля["type"]?.текст == "refusal" {
        отказ = поля["refusal"]?.текст ?? "Поставщик отказал в ответе"
      }
    }
  }
  return (текст, отказ)
}
private func разобратьResponsesКодекаLLM(
  _ объект: [String: ЗначениеJSONКодекаLLM], сырые: Data
) throws -> ОтветПоставщикаLLM {
  if let ошибка = ошибкаПоставщикаLLM(объект, сырые: сырые) {
    let текст = текстResponsesКодекаLLM(объект["output"]?.список ?? []).0
    return отказПоставщикаLLM(ошибка, объект: объект, сырые: сырые, текст: текст)
  }
  guard let статус = объект["status"]?.текст, let вывод = объект["output"]?.список else {
    throw ОшибкаLLM(.протокол, "Отсутствуют status/output профиля Responses", нативныеДанные: сырые)
  }
  let (текст, отказ) = текстResponsesКодекаLLM(вывод)
  let причина = объект["incomplete_details"]?.словарь?["reason"]?.текст ?? статус
  var завершение: ЗавершениеОтветаLLM = статус == "completed" ? .завершено : .неполно
  var ошибка: ОшибкаLLM?
  if статус == "failed" || статус == "cancelled" || отказ != nil {
    завершение = .отказ
    ошибка = .init(
      .поставщик, отказ ?? "Поставщик завершил ответ с отказом",
      кодПоставщика: отказ == nil ? статус : "refusal", нативныеДанные: сырые)
  }
  return .init(
    идентификатор: объект["id"]?.текст, наблюдаемаяМодель: объект["model"]?.текст,
    текст: текст, завершение: завершение, причинаОстановки: причина,
    учёт: учётКодекаLLM(объект["usage"], сырые: сырые), нативныеДанные: сырые, ошибка: ошибка)
}
private func завершениеАнтропикКодекаLLM(_ причина: String?) -> ЗавершениеОтветаLLM {
  switch причина {
  case "end_turn", "stop_sequence": return .завершено
  case "refusal": return .отказ
  default: return .неполно
  }
}
private func текстАнтропикКодекаLLM(_ содержимое: [ЗначениеJSONКодекаLLM]) -> String {
  содержимое.compactMap { часть -> String? in
    guard let поля = часть.словарь, поля["type"]?.текст == "text" else { return nil }
    return поля["text"]?.текст
  }.joined()
}

/// Отдельный конечный text-only профиль OpenAI POST /v1/responses.
public struct КодекОпенайLLM: КодекLLM {
  public init() {}
  public func подготовить(_ запрос: ЗапросLLM) throws -> HTTPЗапросLLM {
    try подготовитьResponsesКодекаLLM(
      запрос, поставщик: .опенай, адрес: "https://api.openai.com/v1/responses")
  }
  public func разобрать(_ данные: Data) throws -> ОтветПоставщикаLLM {
    try разобратьResponsesКодекаLLM(объектJSONКодекаLLM(данные), сырые: данные)
  }
}
/// Стабильный Messages-профиль: system отдельно, версия закреплена явно.
public struct КодекАнтропикLLM: КодекLLM {
  public init() {}
  public func подготовить(_ запрос: ЗапросLLM) throws -> HTTPЗапросLLM {
    try проверитьЗапросКодекаLLM(запрос, поставщик: .антропик)
    guard let конечныйАдрес = URL(string: "https://api.anthropic.com/v1/messages") else {
      throw ОшибкаLLM(.протокол, "Неверный закреплённый адрес Anthropic")
    }
    let тело = ТелоАнтропикКодекаLLM(
      модель: запрос.запрошеннаяМодель,
      сообщения: запрос.сообщения.map { .init(роль: $0.роль.rawValue, содержимое: $0.текст) },
      система: запрос.система, предел: запрос.пределТокенов, поток: запрос.поток)
    return HTTPЗапросLLM(
      адрес: конечныйАдрес,
      заголовки: [
        "Content-Type": "application/json",
        "Accept": запрос.поток ? "text/event-stream" : "application/json",
        "anthropic-version": "2026-10-21",
      ],
      тело: try байтыЗапросаКодекаLLM(тело), секрет: запрос.секрет)
  }
  public func разобрать(_ данные: Data) throws -> ОтветПоставщикаLLM {
    let объект = try объектJSONКодекаLLM(данные)
    if let ошибка = ошибкаПоставщикаLLM(объект, сырые: данные) {
      return отказПоставщикаLLM(ошибка, объект: объект, сырые: данные)
    }
    guard объект["type"]?.текст == "message", let содержимое = объект["content"]?.список else {
      throw ОшибкаLLM(
        .протокол, "Отсутствует message/content профиля Anthropic", нативныеДанные: данные)
    }
    let причина = объект["stop_reason"]?.текст
    let завершение = завершениеАнтропикКодекаLLM(причина)
    let ошибка: ОшибкаLLM? =
      завершение == .отказ
      ? .init(
        .поставщик, "Поставщик отказал в ответе", кодПоставщика: причина, нативныеДанные: данные)
      : nil
    return .init(
      идентификатор: объект["id"]?.текст, наблюдаемаяМодель: объект["model"]?.текст,
      текст: текстАнтропикКодекаLLM(содержимое), завершение: завершение, причинаОстановки: причина,
      учёт: учётКодекаLLM(объект["usage"], сырые: данные), нативныеДанные: данные, ошибка: ошибка)
  }
}
/// Отдельный xAI Responses-профиль. Поддерживается только проверенный общий text-срез.
public struct КодекИксайLLM: КодекLLM {
  public init() {}
  public func подготовить(_ запрос: ЗапросLLM) throws -> HTTPЗапросLLM {
    try подготовитьResponsesКодекаLLM(
      запрос, поставщик: .иксай, адрес: "https://api.x.ai/v1/responses")
  }
  public func разобрать(_ данные: Data) throws -> ОтветПоставщикаLLM {
    try разобратьResponsesКодекаLLM(объектJSONКодекаLLM(данные), сырые: данные)
  }
}
public func кодекLLM(_ поставщик: ПоставщикLLM) -> any КодекLLM {
  switch поставщик {
  case .опенай: КодекОпенайLLM()
  case .антропик: КодекАнтропикLLM()
  case .иксай: КодекИксайLLM()
  }
}

/// Чистое состояние разбора. Сетевых запросов, отмены транспорта и retry здесь нет.
public struct ДекодерПотокаLLM: Sendable {
  private let поставщик: ПоставщикLLM
  private var идентификатор: String?
  private var наблюдаемаяМодель: String?
  private var текст = ""
  private var причинаОстановки: String?
  private var входныеТокены: Int?
  private var выходныеТокены: Int?
  private var всегоТокенов: Int?
  private var нативныеСнимкиУчёта: [Data] = []
  private var последниеДанные = Data()
  private var терминал: ОтветПоставщикаLLM?
  private var перваяОшибка: ОшибкаLLM?
  private var конецТранспорта = false
  private var начатАнтропик = false
  private var видыБлоков: [Int: String] = [:]
  private var блоки: [Int: String] = [:]
  private var активныеБлоки: Set<Int> = []
  private var числоКадров = 0
  private var размерДанных = 0

  public init(поставщик: ПоставщикLLM) { self.поставщик = поставщик }

  private var учёт: УчётLLM? {
    guard !нативныеСнимкиУчёта.isEmpty else { return nil }
    return .init(
      входныеТокены: входныеТокены, выходныеТокены: выходныеТокены,
      всегоТокенов: всегоТокенов, нативныеСнимки: нативныеСнимкиУчёта)
  }
  public var частичныйОтвет: ОтветПоставщикаLLM? {
    if let терминал { return терминал }
    guard идентификатор != nil || наблюдаемаяМодель != nil || !текст.isEmpty || начатАнтропик else {
      return nil
    }
    return .init(
      идентификатор: идентификатор, наблюдаемаяМодель: наблюдаемаяМодель,
      текст: текст, завершение: .неполно, причинаОстановки: причинаОстановки,
      учёт: учёт, нативныеДанные: последниеДанные)
  }
  public mutating func принять(_ кадр: КадрSSELLM) throws -> [СобытиеLLM] {
    if let перваяОшибка { throw перваяОшибка }
    do { return try принятьКадр(кадр) } catch let ошибка as ОшибкаLLM {
      перваяОшибка = ошибка
      throw ошибка
    } catch {
      let ошибка = ОшибкаLLM(
        .протокол, "Не удалось разобрать нативное событие LLM", нативныеДанные: кадр.данные)
      перваяОшибка = ошибка
      throw ошибка
    }
  }
  private mutating func принятьКадр(_ кадр: КадрSSELLM) throws -> [СобытиеLLM] {
    guard !конецТранспорта else { throw отказПротокола("Событие после конца потока", кадр) }
    guard числоКадров < 65_536, кадр.данные.count <= 16_777_216 - размерДанных else {
      throw ОшибкаLLM(
        .пределРесурсов, "Превышен предел native SSE LLM", нативныеДанные: кадр.данные)
    }
    числоКадров += 1
    размерДанных += кадр.данные.count
    последниеДанные = кадр.данные
    if кадр.данные == Data("[DONE]".utf8), поставщик != .антропик {
      конецТранспорта = true
      return [событие("[DONE]", кадр, известное: true)]
    }
    if кадр.событие == "ping", кадр.данные.isEmpty {
      return [событие("ping", кадр, известное: true)]
    }
    let объект = try объектJSONКодекаLLM(кадр.данные)
    let типИзJSON = объект["type"]?.текст
    let типИзSSE = кадр.событие.isEmpty || кадр.событие == "message" ? nil : кадр.событие
    if let типИзJSON, let типИзSSE, типИзJSON != типИзSSE {
      throw отказПротокола("Типы JSON и SSE не совпадают", кадр)
    }
    let тип = типИзJSON ?? типИзSSE ?? "unknown"
    if тип == "ping" { return [событие(тип, кадр, известное: true)] }
    guard терминал == nil else { throw отказПротокола("Событие после нативного терминала", кадр) }
    if тип == "error" {
      let ошибка =
        ошибкаПоставщикаLLM(объект, сырые: кадр.данные, подтверждённаяОшибка: true)
        ?? .init(.поставщик, "Ошибка потока поставщика", нативныеДанные: кадр.данные)
      терминал = .init(
        идентификатор: идентификатор, наблюдаемаяМодель: наблюдаемаяМодель,
        текст: текст, завершение: .отказ, причинаОстановки: ошибка.кодПоставщика,
        учёт: учёт, нативныеДанные: кадр.данные, ошибка: ошибка)
      return [событие(тип, кадр, известное: true)]
    }
    if поставщик == .антропик { return try принятьАнтропик(тип, объект, кадр) }
    return try принятьResponses(тип, объект, кадр)
  }
  private func событие(
    _ тип: String, _ кадр: КадрSSELLM, известное: Bool, дельта: String? = nil
  ) -> СобытиеLLM {
    .init(
      тип: тип, текстоваяДельта: дельта, известное: известное, данные: кадр.данные,
      сыраяРамка: кадр.сырыеБайты)
  }
  private func отказПротокола(_ пояснение: String, _ кадр: КадрSSELLM) -> ОшибкаLLM {
    .init(.протокол, пояснение, нативныеДанные: кадр.данные)
  }
  private mutating func наблюдатьИдентичность(
    _ объект: [String: ЗначениеJSONКодекаLLM], кадр: КадрSSELLM
  ) throws {
    if let новый = объект["id"]?.текст {
      guard идентификатор == nil || идентификатор == новый else {
        throw отказПротокола("Изменился идентификатор нативного ответа", кадр)
      }
      идентификатор = новый
    }
    if let модель = объект["model"]?.текст { наблюдаемаяМодель = модель }
  }
  private mutating func принятьУчёт(_ значение: ЗначениеJSONКодекаLLM?, сырые: Data) {
    guard let значение, !значение.отсутствует else { return }
    нативныеСнимкиУчёта.append(сырые)
    guard let поля = значение.словарь else { return }
    if let значение = поля["input_tokens"] { входныеТокены = значение.целое }
    if let значение = поля["output_tokens"] { выходныеТокены = значение.целое }
    if let значение = поля["total_tokens"] { всегоТокенов = значение.целое }
  }
  private mutating func сохранитьНеизвестныйУчёт(_ значение: ЗначениеJSONКодекаLLM?, сырые: Data) {
    guard значение != nil else { return }
    // У неизвестного события нет принятой семантики счётчиков; сохраняется только оригинал.
    нативныеСнимкиУчёта.append(сырые)
  }
  private mutating func принятьResponses(
    _ тип: String, _ объект: [String: ЗначениеJSONКодекаLLM], _ кадр: КадрSSELLM
  ) throws -> [СобытиеLLM] {
    switch тип {
    case "response.created", "response.in_progress":
      guard let ответ = объект["response"]?.словарь else {
        throw отказПротокола("Lifecycle Responses не содержит response", кадр)
      }
      try наблюдатьИдентичность(ответ, кадр: кадр)
      принятьУчёт(ответ["usage"], сырые: кадр.данные)
      return [событие(тип, кадр, известное: true)]
    case "response.output_text.delta":
      guard let дельта = объект["delta"]?.текст else {
        throw отказПротокола("Отсутствует текстовая delta", кадр)
      }
      текст += дельта
      return [событие(тип, кадр, известное: true, дельта: дельта)]
    case "response.output_text.done":
      guard let полный = объект["text"]?.текст else {
        throw отказПротокола("Отсутствует финальный текст части", кадр)
      }
      if текст.isEmpty { текст = полный }
      return [событие(тип, кадр, известное: true)]
    case "response.completed", "response.failed", "response.incomplete":
      guard let ответ = объект["response"]?.словарь,
        let статус = ответ["status"]?.текст, тип == "response.\(статус)"
      else { throw отказПротокола("Неверный терминал Responses", кадр) }
      try наблюдатьИдентичность(ответ, кадр: кадр)
      принятьУчёт(ответ["usage"], сырые: кадр.данные)
      let разобранный = try разобратьResponsesКодекаLLM(ответ, сырые: кадр.данные)
      if !разобранный.текст.isEmpty || текст.isEmpty { текст = разобранный.текст }
      терминал = .init(
        идентификатор: идентификатор, наблюдаемаяМодель: наблюдаемаяМодель,
        текст: текст, завершение: разобранный.завершение,
        причинаОстановки: разобранный.причинаОстановки, учёт: учёт,
        нативныеДанные: кадр.данные, ошибка: разобранный.ошибка)
      return [событие(тип, кадр, известное: true)]
    case "response.output_item.added", "response.output_item.done", "response.content_part.added",
      "response.content_part.done",
      "response.reasoning_text.delta", "response.reasoning_text.done",
      "response.reasoning_summary_text.delta",
      "response.reasoning_summary_text.done", "response.refusal.delta", "response.refusal.done":
      return [событие(тип, кадр, известное: true)]
    default:
      сохранитьНеизвестныйУчёт(объект["usage"], сырые: кадр.данные)
      return [событие(тип, кадр, известное: false)]
    }
  }
  private mutating func принятьАнтропик(
    _ тип: String, _ объект: [String: ЗначениеJSONКодекаLLM], _ кадр: КадрSSELLM
  ) throws -> [СобытиеLLM] {
    switch тип {
    case "message_start":
      guard !начатАнтропик, let сообщение = объект["message"]?.словарь else {
        throw отказПротокола("Повторный или неверный message_start", кадр)
      }
      начатАнтропик = true
      try наблюдатьИдентичность(сообщение, кадр: кадр)
      принятьУчёт(сообщение["usage"], сырые: кадр.данные)
      if let содержимое = сообщение["content"]?.список {
        текст = текстАнтропикКодекаLLM(содержимое)
      }
      return [событие(тип, кадр, известное: true)]
    case "content_block_start":
      guard начатАнтропик, let индекс = объект["index"]?.целое,
        видыБлоков[индекс] == nil, let блок = объект["content_block"]?.словарь,
        let вид = блок["type"]?.текст
      else { throw отказПротокола("Неверное начало блока Anthropic", кадр) }
      видыБлоков[индекс] = вид
      активныеБлоки.insert(индекс)
      if вид == "text" {
        блоки[индекс] = блок["text"]?.текст ?? ""
        текст = блоки.keys.sorted().compactMap { блоки[$0] }.joined()
      }
      return [событие(тип, кадр, известное: true)]
    case "content_block_delta":
      guard начатАнтропик, let индекс = объект["index"]?.целое,
        активныеБлоки.contains(индекс), let дельта = объект["delta"]?.словарь,
        let вид = дельта["type"]?.текст
      else { throw отказПротокола("Дельта вне открытого блока Anthropic", кадр) }
      if вид == "text_delta" {
        guard видыБлоков[индекс] == "text", let фрагмент = дельта["text"]?.текст else {
          throw отказПротокола("Неверная text_delta Anthropic", кадр)
        }
        блоки[индекс, default: ""] += фрагмент
        текст = блоки.keys.sorted().compactMap { блоки[$0] }.joined()
        return [событие(тип, кадр, известное: true, дельта: фрагмент)]
      }
      return [событие(тип, кадр, известное: true)]
    case "content_block_stop":
      guard начатАнтропик, let индекс = объект["index"]?.целое,
        активныеБлоки.remove(индекс) != nil
      else { throw отказПротокола("Закрытие неизвестного блока Anthropic", кадр) }
      return [событие(тип, кадр, известное: true)]
    case "message_delta":
      guard начатАнтропик, let дельта = объект["delta"]?.словарь else {
        throw отказПротокола("message_delta до начала сообщения", кадр)
      }
      if let причина = дельта["stop_reason"]?.текст { причинаОстановки = причина }
      // output_tokens накопительный; новое наблюдение заменяет прежнее, а не суммируется.
      принятьУчёт(объект["usage"], сырые: кадр.данные)
      return [событие(тип, кадр, известное: true)]
    case "message_stop":
      guard начатАнтропик, активныеБлоки.isEmpty else {
        throw отказПротокола("message_stop до завершения блоков", кадр)
      }
      let завершение = завершениеАнтропикКодекаLLM(причинаОстановки)
      let ошибка: ОшибкаLLM? =
        завершение == .отказ
        ? .init(
          .поставщик, "Поставщик отказал в ответе", кодПоставщика: причинаОстановки,
          нативныеДанные: кадр.данные) : nil
      терминал = .init(
        идентификатор: идентификатор, наблюдаемаяМодель: наблюдаемаяМодель,
        текст: текст, завершение: завершение, причинаОстановки: причинаОстановки,
        учёт: учёт, нативныеДанные: кадр.данные, ошибка: ошибка)
      return [событие(тип, кадр, известное: true)]
    default:
      сохранитьНеизвестныйУчёт(объект["usage"], сырые: кадр.данные)
      return [событие(тип, кадр, известное: false)]
    }
  }
  public mutating func завершить() throws -> ОтветПоставщикаLLM {
    if let перваяОшибка { throw перваяОшибка }
    конецТранспорта = true
    guard let терминал else {
      let ошибка = ОшибкаLLM(
        .неполныйОтвет, "Поток завершился без нативного терминала", нативныеДанные: последниеДанные)
      перваяОшибка = ошибка
      throw ошибка
    }
    return терминал
  }
}
