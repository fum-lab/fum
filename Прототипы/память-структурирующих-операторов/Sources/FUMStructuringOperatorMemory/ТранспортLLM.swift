import Foundation

/// Секрет существует только в подготовленном URLRequest отдельного HTTP-вызова.
///
/// Транспорт не сохраняет запрос, ответ или секрет и не повторяет отправку.
/// Получатель видит сначала заголовки, затем точные байты тела, выданные Foundation.
/// Это не запись TLS, HTTP-фреймов или исходного порядка заголовков на проводе.
public actor ТранспортURLSessionLLM: ТранспортLLM {
  private let секреты: any ИсточникСекретовLLM

  public init(секреты: any ИсточникСекретовLLM) {
    self.секреты = секреты
  }

  public func отправить(
    _ запрос: HTTPЗапросLLM,
    приём: @Sendable (ЧастьHTTPОтветаLLM) async throws -> Void
  ) async throws {
    try Task.checkCancellation()
    _ = try проверитьHTTPЗапросLLM(запрос)

    let значениеСекрета: String
    do {
      значениеСекрета = try await секреты.получить(запрос.секрет)
    } catch let причина {
      if Task.isCancelled || причина is CancellationError {
        throw CancellationError()
      }
      // Чужая ошибка способна включать сам секрет; её описание не переносится.
      throw ОшибкаLLM(.транспорт, "Получение секрета завершилось ошибкой")
    }
    try Task.checkCancellation()

    let подготовленный = try подготовитьURLЗапросLLM(
      запрос, значениеСекрета: значениеСекрета
    )
    let сессия = URLSession(configuration: конфигурацияТранспортаLLM())
    let делегат = ЗапретПереадресацииLLM()
    defer { сессия.invalidateAndCancel() }

    do {
      try await withTaskCancellationHandler {
        try Task.checkCancellation()
        // Единственный сетевой вход. Автоматического повторного вызова здесь нет.
        let (байты, ответ) = try await сессия.bytes(
          for: подготовленный, delegate: делегат
        )
        guard let ответHTTP = ответ as? HTTPURLResponse else {
          throw ОшибкаLLM(.протокол, "Транспорт получил ответ без HTTP-метаданных")
        }
        try Task.checkCancellation()
        try await приём(
          .заголовки(
            МетаданныеHTTPОтветаLLM(
              статус: ответHTTP.statusCode,
              заголовки: безопасныеЗаголовкиHTTPОтветаLLM(ответHTTP)
            )
          )
        )

        var фрагмент = Data()
        фрагмент.reserveCapacity(4096)
        do {
          for try await байт in байты {
            фрагмент.append(байт)
            try Task.checkCancellation()
            // LF передаёт SSE без ожидания всего ответа; размер ограничивает фрагмент.
            if байт == 0x0A || фрагмент.count == 4096 {
              let блок = фрагмент
              фрагмент = Data()
              фрагмент.reserveCapacity(4096)
              // Обнуление до callback исключает повтор при его неизвестном исходе.
              try await приём(.данные(блок))
            }
          }
        } catch let причина {
          if !фрагмент.isEmpty {
            let хвост = фрагмент
            фрагмент = Data()
            // Уже полученный незавершённый хвост сохраняется и при обрыве.
            try await приём(.данные(хвост))
          }
          throw причина
        }
        if !фрагмент.isEmpty {
          let хвост = фрагмент
          фрагмент = Data()
          try await приём(.данные(хвост))
        }
        try Task.checkCancellation()
      } onCancel: {
        сессия.invalidateAndCancel()
      }
    } catch let причина {
      if Task.isCancelled || причина is CancellationError {
        throw CancellationError()
      }
      // Код известной ошибки получателя сохраняется, её частное описание — нет.
      if let ошибка = причина as? ОшибкаLLM {
        throw ОшибкаLLM(ошибка.вид, "Передача HTTP-ответа завершилась ошибкой")
      }
      throw ОшибкаLLM(.транспорт, "HTTP-транспорт завершился ошибкой")
    }
  }
}

/// Допускаются только три явно выбранных HTTP-профиля первого среза.
private enum АвторизацияHTTPЗапросаLLM {
  case носитель
  case ключ
}

private func проверитьHTTPЗапросLLM(
  _ запрос: HTTPЗапросLLM
) throws -> АвторизацияHTTPЗапросаLLM {
  guard
    запрос.метод == "POST",
    let части = URLComponents(url: запрос.адрес, resolvingAgainstBaseURL: false),
    части.scheme?.lowercased() == "https",
    части.port == nil || части.port == 443,
    части.user == nil, части.password == nil,
    части.query == nil, части.fragment == nil,
    let хост = части.host?.lowercased()
  else {
    throw ОшибкаLLM(.неверныйЗапрос, "Неподдержанный адрес или метод HTTP-запроса")
  }

  let авторизация: АвторизацияHTTPЗапросаLLM
  switch (хост, части.percentEncodedPath) {
  case ("api.openai.com", "/v1/responses"), ("api.x.ai", "/v1/responses"):
    авторизация = .носитель
  case ("api.anthropic.com", "/v1/messages"):
    авторизация = .ключ
  default:
    throw ОшибкаLLM(.неверныйЗапрос, "Адрес не входит в выбранный профиль поставщиков")
  }

  let разрешённые = Set(["accept", "content-type", "anthropic-version"])
  var имена = Set<String>()
  var значения: [String: String] = [:]
  for (имя, значение) in запрос.заголовки {
    let ключ = имя.lowercased()
    guard
      разрешённые.contains(ключ), имена.insert(ключ).inserted,
      !значение.isEmpty, значение.utf8.count <= 8192,
      значение.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value <= 0x7E })
    else {
      throw ОшибкаLLM(.неверныйЗапрос, "Неподдержанный или неоднозначный HTTP-заголовок")
    }
    значения[ключ] = значение
  }
  guard значения["content-type"]?.lowercased() == "application/json" else {
    throw ОшибкаLLM(.неверныйЗапрос, "HTTP-запрос требует application/json")
  }
  if let принятие = значения["accept"],
    !["application/json", "text/event-stream"].contains(принятие.lowercased())
  {
    throw ОшибкаLLM(.неверныйЗапрос, "Неподдержанный формат HTTP-ответа")
  }
  switch авторизация {
  case .ключ:
    guard значения["anthropic-version"] != nil else {
      throw ОшибкаLLM(.неверныйЗапрос, "Для Messages API требуется заголовок версии")
    }
  case .носитель:
    guard значения["anthropic-version"] == nil else {
      throw ОшибкаLLM(.неверныйЗапрос, "Заголовок версии Messages API не относится к поставщику")
    }
  }
  return авторизация
}

/// Чистое преобразование: исходный Codable DTO остаётся без значения секрета.
func подготовитьURLЗапросLLM(
  _ запрос: HTTPЗапросLLM, значениеСекрета: String
) throws -> URLRequest {
  let авторизация = try проверитьHTTPЗапросLLM(запрос)
  guard
    !значениеСекрета.isEmpty, значениеСекрета.utf8.count <= 8192,
    значениеСекрета.unicodeScalars.allSatisfy({ $0.value >= 0x21 && $0.value <= 0x7E })
  else {
    throw ОшибкаLLM(.неверныйЗапрос, "Секрет имеет неподдержанную форму")
  }

  var подготовленный = URLRequest(
    url: запрос.адрес, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60
  )
  подготовленный.httpMethod = запрос.метод
  подготовленный.httpBody = запрос.тело
  подготовленный.httpShouldHandleCookies = false
  for (имя, значение) in запрос.заголовки {
    подготовленный.setValue(значение, forHTTPHeaderField: имя)
  }
  switch авторизация {
  case .носитель:
    подготовленный.setValue("Bearer " + значениеСекрета, forHTTPHeaderField: "Authorization")
  case .ключ:
    подготовленный.setValue(значениеСекрета, forHTTPHeaderField: "x-api-key")
  }
  return подготовленный
}

func конфигурацияТранспортаLLM() -> URLSessionConfiguration {
  let конфигурация = URLSessionConfiguration.ephemeral
  конфигурация.urlCache = nil
  конфигурация.urlCredentialStorage = nil
  конфигурация.httpCookieStorage = nil
  конфигурация.httpShouldSetCookies = false
  конфигурация.httpCookieAcceptPolicy = .never
  конфигурация.httpAdditionalHeaders = nil
  конфигурация.requestCachePolicy = .reloadIgnoringLocalCacheData
  конфигурация.waitsForConnectivity = false
  конфигурация.timeoutIntervalForRequest = 60
  конфигурация.timeoutIntervalForResource = 300
  return конфигурация
}

func безопасныеЗаголовкиHTTPОтветаLLM(_ ответ: HTTPURLResponse) -> [String: String] {
  let разрешённые = Set(["content-type", "request-id", "x-request-id", "retry-after"])
  var результат: [String: String] = [:]
  for (имя, значение) in ответ.allHeaderFields {
    guard let имя = имя as? String, let значение = значение as? String else { continue }
    let ключ = имя.lowercased()
    if разрешённые.contains(ключ) {
      результат[ключ] = значение
    }
  }
  return результат
}

/// Неизменяемый адаптер внешнего callback API; переадресация не получает секрет.
private final class ЗапретПереадресацииLLM: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ сессия: URLSession, task задача: URLSessionTask,
    willPerformHTTPRedirection ответ: HTTPURLResponse, newRequest запрос: URLRequest,
    completionHandler завершить: @escaping @Sendable (URLRequest?) -> Void
  ) {
    завершить(nil)
  }
}
