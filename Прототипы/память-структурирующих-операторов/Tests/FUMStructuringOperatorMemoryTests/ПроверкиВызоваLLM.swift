import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

private actor ПоддельныйHTTPДляВызоваLLM: ТранспортLLM {
  let части: [ЧастьHTTPОтветаLLM]
  let отказ: ОшибкаLLM?
  var запросы: [HTTPЗапросLLM] = []
  init(_ части: [ЧастьHTTPОтветаLLM], отказ: ОшибкаLLM? = nil) {
    self.части = части
    self.отказ = отказ
  }
  func отправить(
    _ запрос: HTTPЗапросLLM,
    приём: @Sendable (ЧастьHTTPОтветаLLM) async throws -> Void
  ) async throws {
    запросы.append(запрос)
    for часть in части { try await приём(часть) }
    if let отказ { throw отказ }
  }
}

private func запросВызоваLLM(
  _ поставщик: ПоставщикLLM = .опенай, поток: Bool = false,
  формат: ФорматОтветаLLM = .текст
) -> ЗапросLLM {
  .init(
    идентификатор: "вызов-\(поставщик.rawValue)", поставщик: поставщик,
    запрошеннаяМодель: "requested", система: "Сохрани Ё",
    сообщения: [.init(текст: "Ответь")], поток: поток, секрет: .init("ссылка"),
    форматОтвета: формат
  )
}

private func обычныеБайтыВызоваLLM(
  _ поставщик: ПоставщикLLM, текст: String = "Ёж"
) throws -> Data {
  let объект: [String: Any]
  if поставщик == .антропик {
    объект = [
      "type": "message", "role": "assistant", "id": "msg", "model": "observed",
      "content": [["type": "text", "text": текст]], "stop_reason": "end_turn",
      "usage": ["input_tokens": 2, "output_tokens": 1, "unknown": ["Ё": true]],
    ]
  } else {
    объект = [
      "id": "resp", "model": "observed", "status": "completed",
      "output": [
        [
          "type": "message", "role": "assistant",
          "content": [["type": "output_text", "text": текст]],
        ]
      ],
      "usage": ["input_tokens": 2, "output_tokens": 1, "total_tokens": 3],
    ]
  }
  return try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
}

private func потоковыеБайтыВызоваLLM(_ поставщик: ПоставщикLLM) throws -> Data {
  if поставщик == .антропик {
    return Data(
      """
      event: message_start
      data: {"type":"message_start","message":{"id":"msg","model":"observed","content":[],"usage":{"input_tokens":2,"output_tokens":0}}}

      event: content_block_start
      data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Ёж"}}

      event: content_block_stop
      data: {"type":"content_block_stop","index":0}

      event: message_delta
      data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}

      event: message_stop
      data: {"type":"message_stop"}


      """.utf8)
  }
  let ответ = try JSONSerialization.jsonObject(with: обычныеБайтыВызоваLLM(поставщик))
  let событие = try JSONSerialization.data(
    withJSONObject: ["type": "response.completed", "sequence_number": 1, "response": ответ],
    options: [.sortedKeys])
  return Data(
    ("event: response.completed\r\ndata: "
      + String(decoding: событие, as: UTF8.self) + "\r\n\r\n").utf8)
}

private func частиВызоваLLM(_ байты: Data, поток: Bool, размер: Int = 7) -> [ЧастьHTTPОтветаLLM] {
  var части: [ЧастьHTTPОтветаLLM] = [
    .заголовки(
      .init(
        статус: 200, заголовки: ["content-type": поток ? "text/event-stream" : "application/json"]))
  ]
  for начало in stride(from: 0, to: байты.count, by: размер) {
    части.append(.данные(байты.subdata(in: начало..<min(байты.count, начало + размер))))
  }
  return части
}

@Suite("Исполняемый вызов LLM и сохранённое воспроизведение")
struct ПроверкиВызоваLLM {
  @Test(arguments: ПоставщикLLM.allCases, [false, true])
  func намерениеЧистоеАОтветСохраняетRAW(
    _ поставщик: ПоставщикLLM, _ поток: Bool
  ) async throws {
    let запрос = запросВызоваLLM(поставщик, поток: поток)
    let сырые = try поток ? потоковыеБайтыВызоваLLM(поставщик) : обычныеБайтыВызоваLLM(поставщик)
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(сырые, поток: поток, размер: 1))
    let намерение = try ВызовLLM.сформировать(запрос)
    #expect(await транспорт.запросы.isEmpty)
    let исполнитель = ИсполнительLLM(транспорт: транспорт)
    let запись = try await исполнитель.исполнить(намерение)
    #expect(запись.намерение == намерение)
    #expect(запись.сырыеБайтыОтвета == сырые)
    #expect(запись.хэшСырогоОтвета == sha256Digest(сырые))
    #expect(запись.ответ?.текст == "Ёж")
    #expect(запись.ответ?.наблюдаемаяМодель == "observed")
    #expect(запись.намерение.запрос.запрошеннаяМодель == "requested")
    #expect(запись.исходОтправки == .ответПолучен)
    #expect(запись.ошибка == nil)
    #expect(await транспорт.запросы == [намерение.запросHTTP])
    let копия = try await исполнитель.исполнить(намерение)
    #expect(копия == запись)
    #expect(await транспорт.запросы.count == 1)
  }

  @Test
  func сохранённыйРезультатВосстанавливаетсяБезОтправки() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let байты = try обычныеБайтыВызоваLLM(.опенай)
    let первый = ИсполнительLLM(
      транспорт: ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: false)))
    let запись = try await первый.исполнить(намерение)
    let сохранённая = try JSONDecoder().decode(
      ЗаписьВызоваLLM.self, from: JSONEncoder().encode(запись))
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    let новый = ИсполнительLLM(транспорт: пустой)
    #expect(try await новый.восстановить(сохранённая) == запись)
    #expect(try await новый.исполнить(намерение) == запись)
    #expect(await пустой.запросы.isEmpty)
  }

  @Test
  func подменаСырыхБайтовНеВосстанавливается() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let байты = try обычныеБайтыВызоваLLM(.опенай)
    let первый = ИсполнительLLM(
      транспорт: ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: false)))
    let запись = try await первый.исполнить(намерение)
    var объект = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(запись)) as? [String: Any])
    объект["сырыеБайтыОтвета"] = Data("подмена".utf8).base64EncodedString()
    let подмена = try JSONDecoder().decode(
      ЗаписьВызоваLLM.self, from: JSONSerialization.data(withJSONObject: объект))
    let транспорт = ПоддельныйHTTPДляВызоваLLM([])
    let новый = ИсполнительLLM(транспорт: транспорт)
    await #expect(throws: ОшибкаLLM.self) { try await новый.восстановить(подмена) }
    #expect(await транспорт.запросы.isEmpty)
  }

  @Test
  func обрывПослеОтправкиОстаётсяНеизвестнымБезПовтора() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let транспорт = ПоддельныйHTTPДляВызоваLLM(
      [
        .заголовки(.init(статус: 200, заголовки: ["content-type": "application/json"])),
        .данные(Data("{\"".utf8)),
      ],
      отказ: ОшибкаLLM(.транспорт, "Соединение оборвано"))
    let исполнитель = ИсполнительLLM(транспорт: транспорт)
    let запись = try await исполнитель.исполнить(намерение)
    #expect(запись.исходОтправки == .неизвестен)
    #expect(запись.ошибка?.вид == .транспорт)
    #expect(запись.сырыеБайтыОтвета == Data("{\"".utf8))
    #expect(try await исполнитель.исполнить(намерение) == запись)
    #expect(await транспорт.запросы.count == 1)
  }

  @Test
  func отменаПослеОтправкиНеДоказываетУдалённуюОтмену() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let транспорт = ПоддельныйHTTPДляВызоваLLM([], отказ: .init(.отмена, "Отмена"))
    let исполнитель = ИсполнительLLM(транспорт: транспорт)
    let запись = try await исполнитель.исполнить(намерение)
    #expect(запись.ошибка?.вид == .отмена)
    #expect(запись.исходОтправки == .неизвестен)
    #expect(try await исполнитель.исполнить(намерение) == запись)
    #expect(await транспорт.запросы.count == 1)
  }

  @Test(arguments: [false, true])
  func ошибкаВнутриУспешногоHTTPНеСтановитсяУспехом(_ поток: Bool) async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM(поток: поток))
    let json = #"{"type":"error","code":"server_error","message":"Отказ"}"#
    let байты = Data((поток ? "event: error\ndata: \(json)\n\n" : json).utf8)
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: поток))
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .поставщик)
    #expect(запись.сырыеБайтыОтвета == байты)
  }

  @Test
  func неверныйJSONСохраняетсяКакОтказ() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let байты = Data("{Ё".utf8)
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: false))
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .неверныйJSON)
    #expect(запись.сырыеБайтыОтвета == байты)
    #expect(await транспорт.запросы.count == 1)
  }

  @Test
  func потокБезТерминалаСохраняетНеизвестныйИсход() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM(поток: true))
    let байты = Data(
      "event: response.created\ndata: {\"type\":\"response.created\",\"response\":{\"id\":\"r\",\"model\":\"observed\",\"status\":\"in_progress\",\"output\":[]}}\n\n"
        .utf8)
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: true))
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .неполныйОтвет)
    #expect(запись.исходОтправки == .неизвестен)
    #expect(запись.события.count == 1)
  }

  @Test
  func предложенияJSONПроверяютсяПрежнимАдаптером() async throws {
    let профиль = OperatorProfile(
      id: "llm.ёж", version: 1, stratum: .form, status: .hypothesis,
      recognitionPatterns: ["Ёж"], generationTemplate: "Ёж", language: "ru",
      script: "Cyrl", semanticKey: nil, storageCostBits: 24, confidencePpm: 700_000,
      origin: .llm, positiveExamples: ["Ёж"], negativeExamples: [])
    let json = try canonicalJSONData([профиль])
    let байты = try обычныеБайтыВызоваLLM(.опенай, текст: String(decoding: json, as: UTF8.self))
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM(формат: .предложения))
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(байты, поток: false))
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    let конверт = try #require(запись.предложения)
    #expect(конверт.proposals == [профиль])
    #expect(конверт.responseHash == sha256Digest(json))
    #expect(конверт.responseHash != запись.хэшСырогоОтвета)
    #expect(try RecordedLLMProposalAdapter.decode(data: canonicalJSONData(конверт)) == конверт)
  }

  @Test
  func префиксSSEПриОшибкеНеЗависитОтДробленияИВосстанавливается() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM(поток: true))
    let кадр = Data(
      "event: response.created\ndata: {\"type\":\"response.created\",\"response\":{\"id\":\"r\",\"model\":\"observed\",\"status\":\"in_progress\",\"output\":[]}}\n\n"
        .utf8)
    var повреждение = Data("data: ".utf8)
    повреждение.append(0xFF)
    повреждение.append(Data("\n\n".utf8))
    let целое = кадр + повреждение
    var записи: [ЗаписьВызоваLLM] = []
    for фрагменты in [[целое], [кадр, повреждение]] {
      let части: [ЧастьHTTPОтветаLLM] =
        [
          .заголовки(.init(статус: 200, заголовки: ["content-type": "text/event-stream"]))
        ] + фрагменты.map { .данные($0) }
      let транспорт = ПоддельныйHTTPДляВызоваLLM(части)
      let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
      #expect(запись.события.count == 1)
      #expect(запись.сырыеБайтыОтвета == целое)
      #expect(запись.ошибка?.вид == .протокол)
      #expect(запись.исходОтправки == .неизвестен)
      let пустой = ПоддельныйHTTPДляВызоваLLM([])
      let новый = ИсполнительLLM(транспорт: пустой)
      #expect(try await новый.восстановить(запись) == запись)
      #expect(await пустой.запросы.isEmpty)
      записи.append(запись)
    }
    #expect(записи[0] == записи[1])
  }

  @Test
  func локальныйОтказПотокаНеСтановитсяТранспортнымПриВосстановлении() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM(поток: true))
    let данные = try обычныеБайтыВызоваLLM(.опенай)
    let транспорт = ПоддельныйHTTPДляВызоваLLM(частиВызоваLLM(данные, поток: false))
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .протокол)
    #expect(запись.ответ?.текст == "Ёж")
    let сохранённая = try JSONDecoder().decode(
      ЗаписьВызоваLLM.self, from: JSONEncoder().encode(запись))
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    #expect(try await ИсполнительLLM(транспорт: пустой).восстановить(сохранённая) == запись)
    #expect(await пустой.запросы.isEmpty)
  }

  @Test
  func пределОтветаСохраняетПрефиксНезависимоОтДробленияИВосстанавливается() async throws {
    let кадр = Data(
      "event: response.created\ndata: {\"type\":\"response.created\",\"response\":{\"id\":\"r\",\"model\":\"observed\",\"status\":\"in_progress\",\"output\":[]}}\n\n"
        .utf8)
    let хвост = Data((": " + String(repeating: "x", count: 64) + "\n\n").utf8)
    let целое = кадр + хвост
    let предел = кадр.count + 8
    let образец = запросВызоваLLM(поток: true)
    let запрос = ЗапросLLM(
      идентификатор: образец.идентификатор, поставщик: образец.поставщик,
      запрошеннаяМодель: образец.запрошеннаяМодель, система: образец.система,
      сообщения: образец.сообщения, пределТокенов: образец.пределТокенов,
      поток: образец.поток, секрет: образец.секрет,
      форматОтвета: образец.форматОтвета, пределБайтовОтвета: предел)
    let намерение = try ВызовLLM.сформировать(запрос)
    var записи: [ЗаписьВызоваLLM] = []

    for фрагменты in [[целое], [кадр, хвост]] {
      let части: [ЧастьHTTPОтветаLLM] =
        [
          .заголовки(.init(статус: 200, заголовки: ["content-type": "text/event-stream"]))
        ] + фрагменты.map { .данные($0) }
      let транспорт = ПоддельныйHTTPДляВызоваLLM(части)
      let исполнитель = ИсполнительLLM(транспорт: транспорт)
      let запись = try await исполнитель.исполнить(намерение)
      #expect(запись.сырыеБайтыОтвета == Data(целое.prefix(предел)))
      #expect(запись.хэшСырогоОтвета == sha256Digest(Data(целое.prefix(предел))))
      #expect(запись.события.count == 1)
      #expect(запись.события.first?.сыраяРамка == кадр)
      #expect(запись.ошибка?.вид == .пределРесурсов)
      #expect(запись.ошибкаТранспорта == nil)
      #expect(запись.исходОтправки == .неизвестен)
      #expect(try await исполнитель.исполнить(намерение) == запись)
      #expect(await транспорт.запросы.count == 1)

      let сохранённая = try JSONDecoder().decode(
        ЗаписьВызоваLLM.self, from: JSONEncoder().encode(запись))
      let пустой = ПоддельныйHTTPДляВызоваLLM([])
      let новый = ИсполнительLLM(транспорт: пустой)
      #expect(try await новый.восстановить(сохранённая) == запись)
      #expect(try await новый.исполнить(намерение) == запись)
      #expect(await пустой.запросы.isEmpty)
      записи.append(запись)
    }

    // Квитанция сохраняет границы фрагментов; сравнивается наблюдаемый префикс.
    #expect(записи[0].события == записи[1].события)
    #expect(записи[0].сырыеБайтыОтвета == записи[1].сырыеБайтыОтвета)
    #expect(записи[0].хэшСырогоОтвета == записи[1].хэшСырогоОтвета)
    #expect(записи[0].ошибка == записи[1].ошибка)
    #expect(записи[0].ответ == записи[1].ответ)
    #expect(записи[0].исходОтправки == записи[1].исходОтправки)
  }

  @Test
  func повторныеЗаголовкиПослеТелаВосстанавливаютсяБезОтправки() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let данные = try обычныеБайтыВызоваLLM(.опенай)
    let первые = МетаданныеHTTPОтветаLLM(
      статус: 200, заголовки: ["content-type": "application/json"])
    let повторные = МетаданныеHTTPОтветаLLM(
      статус: 202, заголовки: ["content-type": "text/plain", "x-observation": "повтор"])
    let транспорт = ПоддельныйHTTPДляВызоваLLM([
      .заголовки(первые), .данные(данные), .заголовки(повторные),
    ])
    let исполнитель = ИсполнительLLM(транспорт: транспорт)
    let запись = try await исполнитель.исполнить(намерение)
    #expect(запись.метаданные == первые)
    #expect(запись.сырыеБайтыОтвета == данные)
    #expect(запись.хэшСырогоОтвета == sha256Digest(данные))
    #expect(запись.ошибка?.вид == .протокол)
    #expect(запись.ошибкаТранспорта == nil)
    #expect(запись.исходОтправки == .неизвестен)
    #expect(try await исполнитель.исполнить(намерение) == запись)
    #expect(await транспорт.запросы.count == 1)

    let сохранённая = try JSONDecoder().decode(
      ЗаписьВызоваLLM.self, from: JSONEncoder().encode(запись))
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    let новый = ИсполнительLLM(транспорт: пустой)
    #expect(try await новый.восстановить(сохранённая) == запись)
    #expect(try await новый.исполнить(намерение) == запись)
    #expect(await пустой.запросы.isEmpty)
  }
  @Test
  func данныеДоЗаголовковСохраняютЛокальныйОтказПриПовторе() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let транспорт = ПоддельныйHTTPДляВызоваLLM([.данные(Data("не HTTP body".utf8))])
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .протокол)
    #expect(запись.ошибкаТранспорта == nil)
    #expect(запись.метаданные == nil)
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    let новый = ИсполнительLLM(транспорт: пустой)
    #expect(try await новый.восстановить(запись) == запись)
    #expect(try await новый.исполнить(намерение) == запись)
    #expect(await пустой.запросы.isEmpty)
  }

  @Test(arguments: [401, 429, 503])
  func статусHTTPСохраняетсяБезПовторнойОтправки(_ статус: Int) async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let тело = Data(#"{"error":{"code":"busy","message":"Сервис занят"}}"#.utf8)
    let транспорт = ПоддельныйHTTPДляВызоваLLM([
      .заголовки(.init(статус: статус, заголовки: ["content-type": "application/json"])),
      .данные(тело),
    ])
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .отказHTTP)
    #expect(запись.ошибка?.кодПоставщика == "busy")
    #expect(запись.исходОтправки == .ответПолучен)
    #expect(запись.метаданные?.статус == статус)
    #expect(запись.сырыеБайтыОтвета == тело)
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    #expect(try await ИсполнительLLM(транспорт: пустой).восстановить(запись) == запись)
    #expect(await пустой.запросы.isEmpty)
  }

  @Test
  func наблюдённыйОтветНеМожетСтатьНеОтправленнымПриВосстановлении() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let данные = try обычныеБайтыВызоваLLM(.опенай)
    let первые = МетаданныеHTTPОтветаLLM(
      статус: 200, заголовки: ["content-type": "application/json"])
    let повторные = МетаданныеHTTPОтветаLLM(
      статус: 202, заголовки: ["content-type": "text/plain", "x-observation": "повтор"])
    let транспорт = ПоддельныйHTTPДляВызоваLLM([
      .заголовки(первые), .данные(данные), .заголовки(повторные),
    ])
    let запись = try await ИсполнительLLM(транспорт: транспорт).исполнить(намерение)
    #expect(запись.ошибка?.вид == .протокол)
    #expect(запись.исходОтправки == .неизвестен)
    #expect(запись.метаданные == первые)
    #expect(запись.сырыеБайтыОтвета == данные)
    #expect(запись.отклонениеПриёма != nil)
    #expect(await транспорт.запросы.count == 1)

    let сохранённыеБайты = try JSONEncoder().encode(запись)
    let сохранённая = try JSONDecoder().decode(ЗаписьВызоваLLM.self, from: сохранённыеБайты)
    let контрольныйТранспорт = ПоддельныйHTTPДляВызоваLLM([])
    let контрольныйИсполнитель = ИсполнительLLM(транспорт: контрольныйТранспорт)
    #expect(try await контрольныйИсполнитель.восстановить(сохранённая) == запись)
    #expect(await контрольныйТранспорт.запросы.isEmpty)

    var объект = try #require(
      JSONSerialization.jsonObject(with: сохранённыеБайты) as? [String: Any])
    объект["исходОтправки"] = ИсходОтправкиLLM.неОтправлялся.rawValue
    let подмена = try JSONDecoder().decode(
      ЗаписьВызоваLLM.self, from: JSONSerialization.data(withJSONObject: объект))
    let пустой = ПоддельныйHTTPДляВызоваLLM([])
    let новый = ИсполнительLLM(транспорт: пустой)
    do {
      _ = try await новый.восстановить(подмена)
      Issue.record("Наблюдённый HTTP-ответ принят как неотправленный вызов")
    } catch let ошибка as ОшибкаLLM {
      #expect(ошибка.вид == .протокол)
    } catch let ошибка {
      Issue.record("Ожидалась ОшибкаLLM, получена \(ошибка)")
    }
    #expect(await пустой.запросы.isEmpty)
  }

  @Test
  func отменаДоОтправкиВосстанавливаетсяБезHTTP() async throws {
    let намерение = try ВызовLLM.сформировать(запросВызоваLLM())
    let транспорт = ПоддельныйHTTPДляВызоваLLM([])
    let исполнитель = ИсполнительLLM(транспорт: транспорт)
    let запись = try await withThrowingTaskGroup(of: ЗаписьВызоваLLM.self) { группа in
      группа.addTask {
        withUnsafeCurrentTask { $0?.cancel() }
        return try await исполнитель.исполнить(намерение)
      }
      return try #require(await группа.next())
    }
    #expect(запись.исходОтправки == .неОтправлялся)
    #expect(запись.ошибка?.вид == .отмена)
    #expect(await транспорт.запросы.isEmpty)
    let новый = ИсполнительLLM(транспорт: транспорт)
    #expect(try await новый.восстановить(запись) == запись)
    #expect(try await новый.исполнить(намерение) == запись)
    #expect(await транспорт.запросы.isEmpty)
  }

}
