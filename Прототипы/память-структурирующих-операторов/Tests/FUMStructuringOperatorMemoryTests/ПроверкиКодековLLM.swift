import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

private func байтыКодекаLLM(_ текст: String) -> Data { Data(текст.utf8) }

private func запросКодекаLLM(_ поставщик: ПоставщикLLM, поток: Bool = false) -> ЗапросLLM {
  ЗапросLLM(
    идентификатор: "проверка-\(поставщик.rawValue)", поставщик: поставщик,
    запрошеннаяМодель: "requested-model", система: "Система Ё",
    сообщения: [.init(текст: "Запрос Ё"), .init(роль: .ассистент, текст: "Предыдущий ответ")],
    пределТокенов: 37, поток: поток, секрет: .init("ключ-в-реестре")
  )
}

private func объектКодекаLLM(_ данные: Data) throws -> [String: Any] {
  try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
}

private func кадрКодекаLLM(_ текст: String, событие: String = "", идентификатор: String? = nil)
  -> КадрSSELLM
{
  let заголовок = событие.isEmpty ? "" : "event: \(событие)\r\n"
  let номер = идентификатор.map { "id: \($0)\r\n" } ?? ""
  return КадрSSELLM(
    событие: событие, идентификатор: идентификатор, данные: байтыКодекаLLM(текст),
    сырыеБайты: байтыКодекаLLM("\(заголовок)\(номер)data: \(текст)\r\n\r\n")
  )
}

private func обычныйОтветКодекаLLM(_ поставщик: ПоставщикLLM) -> Data {
  switch поставщик {
  case .антропик:
    return байтыКодекаLLM(
      " \n"
        + #"{"type":"message","id":"an-1","role":"assistant","model":"observed-anthropic","content":[{"type":"text","text":"Ёж"}],"stop_reason":"end_turn","stop_sequence":null,"usage":{"input_tokens":7,"output_tokens":3,"future_usage":{"значение":"9007199254740993"}},"future_response":{"Ё":true}}"#
        + "\r\n")
  case .опенай, .иксай:
    return байтыКодекаLLM(
      " \n"
        + #"{"id":"resp-1","object":"response","model":"observed-response","status":"completed","output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Ёж"}]}],"usage":{"input_tokens":7,"output_tokens":3,"total_tokens":10,"future_usage":{"значение":"9007199254740993"}},"future_response":{"Ё":true}}"#
        + "\r\n")
  }
}

private func ошибкаПоставщикаКодекаLLM(_ поставщик: ПоставщикLLM) -> Data {
  switch поставщик {
  case .антропик:
    return байтыКодекаLLM(
      #"{"type":"error","error":{"type":"overloaded_error","message":"Поставщик занят"},"future_error":{"Ё":1}}"#
    )
  case .опенай:
    return байтыКодекаLLM(
      #"{"error":{"type":"api_error","code":"server_error","message":"Поставщик занят","param":null},"future_error":{"Ё":1}}"#
    )
  case .иксай:
    return байтыКодекаLLM(
      #"{"error":{"type":"api_error","code":503,"message":"Поставщик занят","param":"input"},"future_error":{"Ё":1}}"#
    )
  }
}

private func потокУспехаКодекаLLM(_ поставщик: ПоставщикLLM) -> [КадрSSELLM] {
  if поставщик == .антропик {
    return [
      кадрКодекаLLM(
        #"{"type":"message_start","message":{"id":"an-stream","type":"message","role":"assistant","model":"observed-anthropic","content":[],"stop_reason":null,"usage":{"input_tokens":7,"output_tokens":0,"future_start":true}}}"#,
        событие: "message_start"),
      кадрКодекаLLM(
        #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
        событие: "content_block_start"),
      кадрКодекаLLM(
        #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Ёж"}}"#,
        событие: "content_block_delta"),
      кадрКодекаLLM(#"{"type":"content_block_stop","index":0}"#, событие: "content_block_stop"),
      кадрКодекаLLM(
        #"{"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":3,"future_usage":{"значение":"9007199254740993"}}}"#,
        событие: "message_delta"),
      кадрКодекаLLM(
        #"{"type":"message_stop","future_terminal":{"Ё":true}}"#, событие: "message_stop"),
    ]
  }
  // xAI допускает отсутствие sequence_number и индексов текстовой дельты.
  let последовательность = поставщик == .опенай ? #", "sequence_number": 1"# : ""
  return [
    кадрКодекаLLM(
      #"{"type":"response.created","response":{"id":"resp-stream","model":"observed-response","status":"in_progress","output":[]}}"#,
      событие: "response.created"),
    кадрКодекаLLM(
      #"{"type":"response.output_text.delta","delta":"Ёж""# + последовательность + "}",
      событие: "response.output_text.delta"),
    кадрКодекаLLM(
      #"{"type":"response.output_text.done","text":"Ёж"}"#, событие: "response.output_text.done"),
    кадрКодекаLLM(
      #"{"type":"response.completed","response":{"id":"resp-stream","model":"observed-response","status":"completed","output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Ёж"}]}],"usage":{"input_tokens":7,"output_tokens":3,"total_tokens":10,"future_usage":{"значение":"9007199254740993"}},"future_terminal":{"Ё":true}}}"#,
      событие: "response.completed"),
  ]
}

private func ожидатьОшибкуКодекаLLM(
  _ вид: ВидОшибкиLLM, _ действие: () throws -> Void
) {
  do {
    try действие()
    Issue.record("Ожидался типизированный отказ \(вид.rawValue)")
  } catch let ошибка as ОшибкаLLM {
    #expect(ошибка.вид == вид)
  } catch {
    Issue.record("Ожидалась ОшибкаLLM, получена \(error)")
  }
}

@Suite("Отдельные HTTP-кодеки и нативные потоки LLM")
struct ПроверкиКодековLLM {
  @Test(arguments: ПоставщикLLM.allCases)
  func запросСохраняетПрофильПоставщикаБезСекрета(_ поставщик: ПоставщикLLM) throws {
    let запрос = запросКодекаLLM(поставщик, поток: true)
    let http = try кодекLLM(поставщик).подготовить(запрос)
    #expect(http.метод == "POST")
    #expect(http.секрет == запрос.секрет)
    #expect(http.заголовки["Content-Type"] == "application/json")
    #expect(http.заголовки["Authorization"] == nil)
    #expect(http.заголовки["x-api-key"] == nil)
    let тело = try объектКодекаLLM(http.тело)
    #expect(тело["model"] as? String == "requested-model")
    #expect(тело["stream"] as? Bool == true)
    #expect(тело["temperature"] == nil)
    #expect(тело["tools"] == nil)
    #expect(тело["secret"] == nil)
    if поставщик == .антропик {
      #expect(http.адрес.absoluteString == "https://api.anthropic.com/v1/messages")
      #expect(http.заголовки["anthropic-version"] == "2026-10-21")
      #expect(тело["system"] as? String == "Система Ё")
      #expect(тело["max_tokens"] as? Int == 37)
      let сообщения = try #require(тело["messages"] as? [[String: Any]])
      #expect(сообщения.map { $0["role"] as? String } == ["user", "assistant"])
      #expect(сообщения.first?["content"] as? String == "Запрос Ё")
    } else {
      let адрес =
        поставщик == .опенай
        ? "https://api.openai.com/v1/responses" : "https://api.x.ai/v1/responses"
      #expect(http.адрес.absoluteString == адрес)
      #expect(тело["store"] as? Bool == false)
      #expect(тело["max_output_tokens"] as? Int == 37)
      let вход = try #require(тело["input"] as? [[String: Any]])
      let системные = вход.filter { $0["role"] as? String == "system" }
      #expect(
        тело["instructions"] as? String == "Система Ё"
          || системные.first?["content"] as? String == "Система Ё")
      let сообщения = вход.filter { $0["role"] as? String != "system" }
      #expect(сообщения.map { $0["role"] as? String } == ["user", "assistant"])
      #expect(сообщения.first?["content"] as? String == "Запрос Ё")
    }
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func обычныйОтветХранитНативныеБайтыИУчёт(_ поставщик: ПоставщикLLM) throws {
    let данные = обычныйОтветКодекаLLM(поставщик)
    let ответ = try кодекLLM(поставщик).разобрать(данные)
    #expect(ответ.текст == "Ёж")
    #expect(ответ.завершение == .завершено)
    #expect(ответ.ошибка == nil)
    #expect(ответ.наблюдаемаяМодель != "requested-model")
    #expect(ответ.нативныеДанные == данные)
    let учёт = try #require(ответ.учёт)
    #expect(учёт.входныеТокены == 7)
    #expect(учёт.выходныеТокены == 3)
    #expect(учёт.всегоТокенов == (поставщик == .антропик ? nil : 10))
    #expect(учёт.нативныеСнимки == [данные])
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func ошибкаПоставщикаВнутриУспешногоHTTPНеСтановитсяУспехом(_ поставщик: ПоставщикLLM) throws {
    let данные = ошибкаПоставщикаКодекаLLM(поставщик)
    let ответ = try кодекLLM(поставщик).разобрать(данные)
    #expect(ответ.завершение == .отказ)
    #expect(ответ.ошибка?.вид == .поставщик)
    #expect(ответ.нативныеДанные == данные)
    #expect(ответ.ошибка?.нативныеДанные == данные)
    #expect(ответ.ошибка?.пояснение == "Поставщик занят")
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func неизвестныйУчётНеПодменяетсяНулём(_ поставщик: ПоставщикLLM) throws {
    let строка = String(decoding: обычныйОтветКодекаLLM(поставщик), as: UTF8.self)
    let прежнее =
      поставщик == .антропик
      ? #""input_tokens":7,"output_tokens":3,"future_usage":{"значение":"9007199254740993"}"#
      : #""input_tokens":7,"output_tokens":3,"total_tokens":10,"future_usage":{"значение":"9007199254740993"}"#
    let данные = байтыКодекаLLM(
      строка.replacingOccurrences(
        of: прежнее, with: #""future_counter":{"значение":9007199254740993}"#))
    let ответ = try кодекLLM(поставщик).разобрать(данные)
    let учёт = try #require(ответ.учёт)
    #expect(учёт.входныеТокены == nil)
    #expect(учёт.выходныеТокены == nil)
    #expect(учёт.всегоТокенов == nil)
    #expect(учёт.нативныеСнимки == [данные])
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func неверныйJSONИМассивЗакрываютОбычныйРазбор(_ поставщик: ПоставщикLLM) {
    ожидатьОшибкуКодекаLLM(.неверныйJSON) {
      _ = try кодекLLM(поставщик).разобрать(байтыКодекаLLM("{обрыв"))
    }
    ожидатьОшибкуКодекаLLM(.протокол) {
      _ = try кодекLLM(поставщик).разобрать(байтыКодекаLLM("[]"))
    }
  }

  @Test func антропикНеПринимаетЧужуюФормуResponses() {
    ожидатьОшибкуКодекаLLM(.протокол) {
      _ = try КодекАнтропикLLM().разобрать(обычныйОтветКодекаLLM(.опенай))
    }
    ожидатьОшибкуКодекаLLM(.протокол) {
      _ = try КодекОпенайLLM().разобрать(обычныйОтветКодекаLLM(.антропик))
    }
    ожидатьОшибкуКодекаLLM(.протокол) {
      _ = try КодекИксайLLM().разобрать(обычныйОтветКодекаLLM(.антропик))
    }
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func успешныйПотокСохраняетСобытияТерминалИНативныйУчёт(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    let кадры = потокУспехаКодекаLLM(поставщик)
    var события: [СобытиеLLM] = []
    for кадр in кадры {
      let полученные = try декодер.принять(кадр)
      #expect(полученные.count == 1)
      #expect(полученные.first?.данные == кадр.данные)
      #expect(полученные.first?.сыраяРамка == кадр.сырыеБайты)
      события += полученные
    }
    let ответ = try декодер.завершить()
    #expect(ответ.текст == "Ёж")
    #expect(события.compactMap(\.текстоваяДельта).joined() == "Ёж")
    #expect(события.allSatisfy { $0.известное })
    #expect(ответ.завершение == .завершено)
    #expect(ответ.нативныеДанные == кадры.last?.данные)
    #expect(ответ.учёт?.входныеТокены == 7)
    #expect(ответ.учёт?.выходныеТокены == 3)
    #expect(ответ.учёт?.всегоТокенов == (поставщик == .антропик ? nil : 10))
    let снимки = try #require(ответ.учёт?.нативныеСнимки)
    #expect(снимки.allSatisfy { кадры.map(\.данные).contains($0) })
    #expect(!снимки.isEmpty)
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func неизвестноеСобытиеСохраняетсяБезПотериПотока(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    let кадр = кадрКодекаLLM(
      #"{"type":"future.event","usage":{"future":9007199254740993},"Ё":"ёж"}"#,
      событие: "future.event", идентификатор: "raw-id")
    let события = try декодер.принять(кадр)
    #expect(события.count == 1)
    #expect(события.first?.тип == "future.event")
    #expect(события.first?.известное == false)
    #expect(события.first?.данные == кадр.данные)
    #expect(события.first?.сыраяРамка == кадр.сырыеБайты)
    for следующий in потокУспехаКодекаLLM(поставщик) { _ = try декодер.принять(следующий) }
    #expect(try декодер.завершить().текст == "Ёж")
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func обрывБезТерминалаСохраняетЧастичныйОтвет(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    let кадры = потокУспехаКодекаLLM(поставщик)
    for кадр in кадры.dropLast() { _ = try декодер.принять(кадр) }
    #expect(декодер.частичныйОтвет?.текст == "Ёж")
    ожидатьОшибкуКодекаLLM(.неполныйОтвет) { _ = try декодер.завершить() }
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func неверныйJSONПотокаДаётТипизированныйОтказ(_ поставщик: ПоставщикLLM) {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    ожидатьОшибкуКодекаLLM(.неверныйJSON) {
      _ = try декодер.принять(кадрКодекаLLM("{обрыв", событие: "response.output_text.delta"))
    }
  }

  @Test(arguments: ПоставщикLLM.allCases)
  func ошибкаВнутриПотокаHTTPДвестиТерминальна(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    _ = try декодер.принять(потокУспехаКодекаLLM(поставщик)[0])
    let данные =
      поставщик == .антропик
      ? #"{"type":"error","error":{"type":"overloaded_error","message":"Поставщик занят"},"future":true}"#
      : #"{"type":"error","code":503,"message":"Поставщик занят","param":"input","future":true}"#
    let кадр = кадрКодекаLLM(данные, событие: "error")
    let события = try декодер.принять(кадр)
    #expect(события.first?.известное == true)
    let ответ = try декодер.завершить()
    #expect(ответ.завершение == .отказ)
    #expect(ответ.ошибка?.вид == .поставщик)
    #expect(ответ.ошибка?.нативныеДанные == кадр.данные)
    #expect(ответ.нативныеДанные == кадр.данные)
  }

  @Test func иксайНеТребуетНеобязательнойПоследовательности() throws {
    var декодер = ДекодерПотокаLLM(поставщик: .иксай)
    for кадр in потокУспехаКодекаLLM(.иксай) { _ = try декодер.принять(кадр) }
    #expect(try декодер.завершить().завершение == .завершено)
  }

  @Test func иксайНеПринимаетDoneЗаТерминальныйОтвет() throws {
    var декодер = ДекодерПотокаLLM(поставщик: .иксай)
    _ = try декодер.принять(кадрКодекаLLM("[DONE]"))
    ожидатьОшибкуКодекаLLM(.неполныйОтвет) { _ = try декодер.завершить() }
  }

  @Test func антропикНеСуммируетНакопительныеВыходныеТокены() throws {
    var декодер = ДекодерПотокаLLM(поставщик: .антропик)
    let начало = потокУспехаКодекаLLM(.антропик)[0]
    let первый = кадрКодекаLLM(
      #"{"type":"message_delta","delta":{"stop_reason":null},"usage":{"output_tokens":2,"future":"первый"}}"#,
      событие: "message_delta")
    let второй = кадрКодекаLLM(
      #"{"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5,"future":"второй"}}"#,
      событие: "message_delta")
    let конец = потокУспехаКодекаLLM(.антропик).last!
    for кадр in [начало, первый, второй, конец] { _ = try декодер.принять(кадр) }
    let учёт = try #require(декодер.завершить().учёт)
    #expect(учёт.входныеТокены == 7)
    #expect(учёт.выходныеТокены == 5)
    #expect(учёт.всегоТокенов == nil)
    #expect(учёт.нативныеСнимки == [начало.данные, первый.данные, второй.данные])
  }

  @Test(arguments: [ПоставщикLLM.опенай, .иксай])
  func терминальныйНеполныйОтветНеСчитаетсяЗавершённым(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    let кадр = кадрКодекаLLM(
      #"{"type":"response.incomplete","response":{"id":"incomplete-1","model":"observed","status":"incomplete","output":[],"incomplete_details":{"reason":"max_output_tokens","future":true}}}"#,
      событие: "response.incomplete")
    _ = try декодер.принять(кадр)
    let ответ = try декодер.завершить()
    #expect(ответ.завершение == .неполно)
    #expect(ответ.причинаОстановки == "max_output_tokens")
    #expect(ответ.нативныеДанные == кадр.данные)
  }

  @Test(arguments: [ПоставщикLLM.опенай, .иксай])
  func терминальныйОтказСохраняетПричинуИЧастичныйВывод(_ поставщик: ПоставщикLLM) throws {
    var декодер = ДекодерПотокаLLM(поставщик: поставщик)
    let кадр = кадрКодекаLLM(
      #"{"type":"response.failed","response":{"id":"failed-1","model":"observed","status":"failed","output":[{"type":"message","content":[{"type":"output_text","text":"часть"}]}],"error":{"code":"server_error","message":"Сбой"}}}"#,
      событие: "response.failed")
    _ = try декодер.принять(кадр)
    let ответ = try декодер.завершить()
    #expect(ответ.завершение == .отказ)
    #expect(ответ.текст == "часть")
    #expect(ответ.ошибка?.кодПоставщика == "server_error")
  }

  @Test func антропикСохраняетНативныйЛимитВывода() throws {
    let данные = байтыКодекаLLM(
      #"{"type":"message","id":"limit-1","model":"observed","content":[{"type":"text","text":"часть"}],"stop_reason":"max_tokens","usage":{"input_tokens":1,"output_tokens":37}}"#
    )
    let ответ = try КодекАнтропикLLM().разобрать(данные)
    #expect(ответ.завершение == .неполно)
    #expect(ответ.причинаОстановки == "max_tokens")
    #expect(ответ.нативныеДанные == данные)
  }

  @Test func иксайСохраняетКодИСообщениеОшибкиИзЗаголовкаСобытия() throws {
    var декодер = ДекодерПотокаLLM(поставщик: .иксай)
    _ = try декодер.принять(потокУспехаКодекаLLM(.иксай)[0])
    let кадр = кадрКодекаLLM(
      #"{"code":503,"message":"Временно занят","param":"input","future_error":{"Ё":true}}"#,
      событие: "error")
    let события = try декодер.принять(кадр)
    #expect(события.count == 1)
    #expect(события.first?.тип == "error")
    #expect(события.first?.известное == true)
    #expect(события.first?.данные == кадр.данные)
    #expect(события.first?.сыраяРамка == кадр.сырыеБайты)
    let ответ = try декодер.завершить()
    #expect(ответ.завершение == .отказ)
    #expect(ответ.ошибка?.вид == .поставщик)
    #expect(ответ.ошибка?.кодПоставщика == "503")
    #expect(ответ.ошибка?.пояснение == "Временно занят")
    #expect(ответ.ошибка?.нативныеДанные == кадр.данные)
    #expect(ответ.нативныеДанные == кадр.данные)
  }

  @Test func неизвестноеСобытиеНеПодменяетПризнанныйУчётАнтропик() throws {
    var декодер = ДекодерПотокаLLM(поставщик: .антропик)
    let начало = потокУспехаКодекаLLM(.антропик)[0]
    let признанный = кадрКодекаLLM(
      #"{"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}"#,
      событие: "message_delta")
    let неизвестный = кадрКодекаLLM(
      #"{"type":"future.event","usage":{"input_tokens":999,"output_tokens":999,"total_tokens":1998,"future_usage":9.001e21}}"#,
      событие: "future.event")
    let конец = try #require(потокУспехаКодекаLLM(.антропик).last)
    for кадр in [начало, признанный] { _ = try декодер.принять(кадр) }
    let события = try декодер.принять(неизвестный)
    #expect(события.count == 1)
    #expect(события.first?.тип == "future.event")
    #expect(события.first?.известное == false)
    #expect(события.first?.данные == неизвестный.данные)
    #expect(события.first?.сыраяРамка == неизвестный.сырыеБайты)
    _ = try декодер.принять(конец)
    let ответ = try декодер.завершить()
    let учёт = try #require(ответ.учёт)
    #expect(учёт.входныеТокены == 7)
    #expect(учёт.выходныеТокены == 5)
    #expect(учёт.всегоТокенов == nil)
    #expect(учёт.нативныеСнимки == [начало.данные, признанный.данные, неизвестный.данные])
    #expect(ответ.нативныеДанные == конец.данные)
  }
}
