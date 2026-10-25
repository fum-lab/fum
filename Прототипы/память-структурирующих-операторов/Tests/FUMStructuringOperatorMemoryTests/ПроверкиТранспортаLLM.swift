import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

/// Синтетические значения ниже не являются ключами доступа.
@Suite("Подготовка HTTP-транспорта LLM без сети")
struct ПроверкиТранспортаLLM {
  @Test("Каждый поставщик получает свой заголовок авторизации только в URLRequest")
  func авторизацияПоставщиков() throws {
    let варианты = [
      ("https://api.openai.com/v1/responses", "Authorization", "Bearer fixture-not-a-real-key"),
      ("https://api.anthropic.com/v1/messages", "x-api-key", "fixture-not-a-real-key"),
      ("https://api.x.ai/v1/responses", "Authorization", "Bearer fixture-not-a-real-key"),
    ]
    for (адрес, имя, значение) in варианты {
      let исходный = try запросТранспортаLLM(
        адрес: адрес,
        заголовки: [
          "Content-Type": "application/json",
          "Accept": "text/event-stream",
          "anthropic-version": "2023-06-01",
        ].filter { адрес.contains("anthropic.com") || $0.key != "anthropic-version" }
      )
      let подготовленный = try подготовитьURLЗапросLLM(
        исходный, значениеСекрета: "fixture-not-a-real-key"
      )

      #expect(подготовленный.value(forHTTPHeaderField: имя) == значение)
      #expect(подготовленный.httpMethod == "POST")
      #expect(подготовленный.url == исходный.адрес)
      #expect(подготовленный.value(forHTTPHeaderField: "Accept") == "text/event-stream")
      #expect(подготовленный.value(forHTTPHeaderField: "Content-Type") == "application/json")
      if адрес.contains("anthropic.com") {
        #expect(подготовленный.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(подготовленный.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
      } else {
        #expect(подготовленный.value(forHTTPHeaderField: "x-api-key") == nil)
      }
    }
  }

  @Test("Тело HTTP передаётся побайтно, включая байты вне UTF-8")
  func сыроеТелоНеПреобразуется() throws {
    let тело = Data([0x00, 0xFF, 0xD0, 0x81, 0x0D, 0x0A, 0x20])
    let исходный = try запросТранспортаLLM(тело: тело)
    let подготовленный = try подготовитьURLЗапросLLM(
      исходный, значениеСекрета: "fixture-not-a-real-key"
    )
    #expect(подготовленный.httpBody == тело)
    #expect(подготовленный.httpBodyStream == nil)
  }

  @Test("Codable-запрос и ссылка на секрет не изменяются при подготовке")
  func историяСодержитСсылкуБезЗначенияСекрета() throws {
    let исходный = try запросТранспортаLLM()
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys]
    let до = try кодировщик.encode(исходный)
    let подготовленный = try подготовитьURLЗапросLLM(
      исходный, значениеСекрета: "fixture-not-a-real-key"
    )
    let после = try кодировщик.encode(исходный)

    #expect(до == после)
    #expect(исходный.секрет == СсылкаНаСекретLLM("fixture-secret-reference"))
    #expect(исходный.заголовки["Authorization"] == nil)
    #expect(подготовленный.value(forHTTPHeaderField: "Authorization") != nil)
    #expect(!String(decoding: после, as: UTF8.self).contains("fixture-not-a-real-key"))
    #expect(String(decoding: после, as: UTF8.self).contains("fixture-secret-reference"))
  }

  @Test("Встроенные auth и cookie-заголовки отвергаются независимо от регистра")
  func секретныеЗаголовкиВЗапросеОтвергаются() throws {
    for имя in [
      "Authorization", "authorization", "aUtHoRiZaTiOn", "Proxy-Authorization",
      "Cookie", "cookie", "x-api-key", "X-API-KEY", "Set-Cookie",
    ] {
      let исходный = try запросТранспортаLLM(
        заголовки: ["Content-Type": "application/json", имя: "fixture-forbidden-value"]
      )
      #expect(throws: ОшибкаLLM.self) {
        try подготовитьURLЗапросLLM(исходный, значениеСекрета: "fixture-not-a-real-key")
      }
    }
  }

  @Test("Значение секрета не допускает пустоту, CR, LF и управляющие символы")
  func значениеСекретаНеРазрешаетВнедрениеЗаголовка() throws {
    let исходный = try запросТранспортаLLM()
    for значение in [
      "", " ", "\rfixture", "fixture\n", "fixture\r\nX-Test: injected", "fixture\u{0}",
    ] {
      #expect(throws: ОшибкаLLM.self) {
        try подготовитьURLЗапросLLM(исходный, значениеСекрета: значение)
      }
    }
  }

  @Test("Неподдержанные адреса не получают секрет")
  func точныеHTTPSАдресаПроверяютсяДоПодготовки() throws {
    for адрес in [
      "http://api.openai.com/v1/responses",
      "https://api.openai.com.evil.example/v1/responses",
      "https://api.openai.com:444/v1/responses",
      "https://user:password@api.openai.com/v1/responses",
      "https://api.openai.com/v1/responses?api_key=fixture",
      "https://api.openai.com/v1/responses#fragment",
      "https://api.openai.com/v1/chat/completions",
      "https://api.anthropic.com/v1/responses",
      "https://api.x.ai/v1/messages",
    ] {
      let исходный = try запросТранспортаLLM(адрес: адрес)
      #expect(throws: ОшибкаLLM.self) {
        try подготовитьURLЗапросLLM(исходный, значениеСекрета: "fixture-not-a-real-key")
      }
    }
  }

  @Test("Первый профиль принимает только POST и безопасные заголовки")
  func неподдержанныйМетодИВнедрениеЗаголовковОтвергаются() throws {
    let адрес = try #require(URL(string: "https://api.openai.com/v1/responses"))
    let неверныйМетод = HTTPЗапросLLM(
      адрес: адрес, метод: "GET", заголовки: ["Content-Type": "application/json"],
      тело: Data("{}".utf8), секрет: СсылкаНаСекретLLM("fixture-secret-reference")
    )
    #expect(throws: ОшибкаLLM.self) {
      try подготовитьURLЗапросLLM(неверныйМетод, значениеСекрета: "fixture-not-a-real-key")
    }
    for заголовки in [
      ["Content-Type": "application/json\r\nX-Injected: yes"],
      ["Content-Type\r\nX-Injected": "application/json"],
      ["Content-Type": "application/json", "X-Unknown-Private": "fixture-private-value"],
    ] {
      let исходный = try запросТранспортаLLM(заголовки: заголовки)
      #expect(throws: ОшибкаLLM.self) {
        try подготовитьURLЗапросLLM(исходный, значениеСекрета: "fixture-not-a-real-key")
      }
    }
  }

  @Test("Запрос не читает HTTP cache и не обрабатывает cookie")
  func отдельныйЗапросНеИспользуетСохранённыеДанные() throws {
    let подготовленный = try подготовитьURLЗапросLLM(
      запросТранспортаLLM(), значениеСекрета: "fixture-not-a-real-key"
    )
    #expect(подготовленный.cachePolicy == .reloadIgnoringLocalCacheData)
    #expect(!подготовленный.httpShouldHandleCookies)
  }

  @Test("Конфигурация сессии не сохраняет cache, cookie и credentials")
  func конфигурацияЭфемерна() {
    let конфигурация = конфигурацияТранспортаLLM()
    #expect(конфигурация.identifier == nil)
    #expect(конфигурация.urlCache == nil)
    #expect(конфигурация.httpCookieStorage == nil)
    #expect(конфигурация.urlCredentialStorage == nil)
    #expect(!конфигурация.httpShouldSetCookies)
    #expect(конфигурация.httpCookieAcceptPolicy == .never)
    #expect(конфигурация.requestCachePolicy == .reloadIgnoringLocalCacheData)
    #expect(!конфигурация.waitsForConnectivity)
    #expect(конфигурация.httpAdditionalHeaders == nil)
  }

  @Test("В историю попадает только безопасный whitelist ответных заголовков")
  func заголовкиОтветаНеСохраняютСекретыИCookie() throws {
    let адрес = try #require(URL(string: "https://api.openai.com/v1/responses"))
    let ответ = try #require(
      HTTPURLResponse(
        url: адрес, statusCode: 200, httpVersion: "HTTP/1.1",
        headerFields: [
          "Content-Type": "text/event-stream",
          "X-Request-ID": "fixture-request",
          "Request-ID": "fixture-anthropic-request",
          "Retry-After": "3",
          "Set-Cookie": "fixture-cookie=private",
          "Authorization": "Bearer fixture-not-a-real-key",
          "X-API-Key": "fixture-not-a-real-key",
          "X-Unknown-Private": "fixture-private-value",
        ]
      )
    )
    #expect(
      безопасныеЗаголовкиHTTPОтветаLLM(ответ) == [
        "content-type": "text/event-stream",
        "x-request-id": "fixture-request",
        "request-id": "fixture-anthropic-request",
        "retry-after": "3",
      ]
    )
  }

  @Test("Предшествующая отмена не обращается к secret actor и не начинает HTTP")
  func отменённыйВызовНеЗапрашиваетСекрет() async throws {
    let секреты = ТестовыйИсточникСекретовLLM()
    let приёмник = ПриёмникТестаТранспортаLLM()
    let транспорт = ТранспортURLSessionLLM(секреты: секреты)
    let запрос = try запросТранспортаLLM()
    let отменён = await withTaskGroup(of: Bool.self) { группа in
      группа.cancelAll()
      группа.addTask {
        do {
          try await транспорт.отправить(запрос) { часть in
            await приёмник.принять(часть)
          }
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
      return await группа.next() ?? false
    }
    #expect(отменён)
    #expect(await секреты.числоВызовов == 0)
    #expect(await приёмник.части.isEmpty)
  }
}

private func запросТранспортаLLM(
  адрес: String = "https://api.openai.com/v1/responses",
  заголовки: [String: String] = ["Content-Type": "application/json"],
  тело: Data = Data("{\"input\":\"Ё 🧠\"}".utf8)
) throws -> HTTPЗапросLLM {
  HTTPЗапросLLM(
    адрес: try #require(URL(string: адрес)), заголовки: заголовки, тело: тело,
    секрет: СсылкаНаСекретLLM("fixture-secret-reference")
  )
}

private actor ТестовыйИсточникСекретовLLM: ИсточникСекретовLLM {
  private(set) var числоВызовов = 0

  func получить(_ ссылка: СсылкаНаСекретLLM) async throws -> String {
    числоВызовов += 1
    return "fixture-not-a-real-key"
  }
}

private actor ПриёмникТестаТранспортаLLM {
  private(set) var части: [ЧастьHTTPОтветаLLM] = []

  func принять(_ часть: ЧастьHTTPОтветаLLM) {
    части.append(часть)
  }
}
