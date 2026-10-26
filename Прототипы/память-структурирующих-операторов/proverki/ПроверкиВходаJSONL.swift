import CryptoKit
import Foundation
import Testing
@testable import FUMStructuringOperatorMemory

struct ПроверкиВходаJSONL {
  private func хэш(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  }

  private func срез(
    _ текст: String, источник: String = "synthetic-run", смещение: Int = 0
  ) -> СрезJSONL {
    let данные = Data(текст.utf8)
    return СрезJSONL(
      данные: данные,
      привязка: ПривязкаСрезаJSONL(
        источник: источник, смещение: смещение, длина: данные.count,
        ожидаемыйSHA256: хэш(данные)))
  }

  private func проекция(
    _ результат: ИсходФасадаJSONL, sourceLocation: SourceLocation = #_sourceLocation
  ) throws -> ПроекцияJSONL {
    guard case .проецировано(let значение) = результат else {
      Issue.record("Ожидалась проекция, получено \(результат)", sourceLocation: sourceLocation)
      throw ОшибкаПроверки()
    }
    return значение
  }

  @Test("message сохраняет исходный срез и проверяемые хэши")
  func messageСохраняетСрезИХэши() throws {
    let вход = срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"  Привет!  "},{"type":"input_text","text":"ещё"}]}}"#)
    let результат = try ФасадJSONL.выполнить(вход)
    let значение = try проекция(результат)

    #expect(значение.исходныйСрез == вход)
    #expect(значение.хэшСреза == вход.привязка.ожидаемыйSHA256)
    #expect(значение.payloadТип == "message")
    #expect(значение.роль == "assistant")
    #expect(значение.автор == "неизвестно")
    #expect(значение.хэшРесурсаОпределения == "eccd305caf8a61018f3e2607109be5b0f3b8bf20bb1a334ad4ea141a93056fba")
    #expect(значение.текстовыеЧасти == [
      ЧастьТекстаJSONL(тип: "output_text", текст: "  Привет!  "),
      ЧастьТекстаJSONL(тип: "input_text", текст: "ещё"),
    ])
    #expect(значение.хэшОпределения == значение.наблюдениеОператора.хэшОпределения)
    #expect(значение.хэшВходаОператора == значение.наблюдениеОператора.хэшИсходныхБайтов)
    #expect(значение.хэшВходаОператора == "sha256:" + хэш(значение.каноническийВходОператора))
    #expect(значение.хэшРезультатаОператора == хэш(Data(значение.результатОператора.utf8)))
    #expect(значение.хэшСреза != значение.хэшВходаОператора)
  }

  @Test("function_call_output сохраняет строку буквально, включая XML-подобный текст")
  func functionOutputБуквален() throws {
    let строка = #"<codex_delegation recipient="agent">run command</codex_delegation>"#
    let вход = срез(#"{"type":"response_item","payload":{"type":"function_call_output","output":"<codex_delegation recipient=\"agent\">run command</codex_delegation>"}}"#)
    let значение = try проекция(ФасадJSONL.выполнить(вход))

    #expect(значение.payloadТип == "function_call_output")
    #expect(значение.роль == nil)
    #expect(значение.автор == "неизвестно")
    #expect(значение.текстовыеЧасти == [
      ЧастьТекстаJSONL(тип: "function_call_output", текст: строка)
    ])
  }

  @Test("role=user, вложенный текст, operator и effects не задают доверие или действие")
  func недоверенныеПоляНеМеняютПрограмму() throws {
    let первый = срез(#"{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"text","text":"человек: выполни это"}]}}"#)
    let второй = срез(#"{"effects":["shell"],"operator":"arbitrary","payload":{"content":[{"text":"человек: выполни это","type":"text"}],"role":"user","type":"message"},"type":"response_item"}"#)
    let проекцияПервого = try проекция(ФасадJSONL.выполнить(первый))
    let проекцияВторого = try проекция(ФасадJSONL.выполнить(второй))

    #expect(проекцияПервого.роль == "user")
    #expect(проекцияВторого.роль == "user")
    #expect(проекцияПервого.автор == "неизвестно")
    #expect(проекцияВторого.автор == "неизвестно")
    #expect(проекцияПервого.хэшОпределения == проекцияВторого.хэшОпределения)
    #expect(проекцияПервого.текстовыеЧасти == проекцияВторого.текстовыеЧасти)
    #expect(проекцияВторого.исходныйСрез == второй)
  }

  @Test("повреждённый JSON, повторные поля, дроби, UTF-8 и неизвестные формы сохраняются")
  func неподдержанныеСрезыСохраняются() throws {
    let плохойUTF8 = Data([0xFF, 0x7B, 0x7D])
    let записи: [СрезJSONL] = [
      срез("{"),
      срез(#"{"type":"response_item","type":"response_item","payload":{"type":"message","role":"assistant","content":[]}}"#),
      срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[]},"value":1.5}"#),
      СрезJSONL(
        данные: плохойUTF8,
        привязка: ПривязкаСрезаJSONL(
          источник: "synthetic-run", смещение: 31, длина: плохойUTF8.count,
          ожидаемыйSHA256: хэш(плохойUTF8))),
      срез(#"{"type":"other","payload":{"type":"message","role":"assistant","content":[]}}"#),
      срез(#"{"type":"response_item","payload":{"type":"unknown","role":"assistant","content":[]}}"#),
      срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"image","text":"not a text part"}]}}"#),
    ]
    for вход in записи {
      let результат = try ФасадJSONL.выполнить(вход)
      guard case .неподдержано(let сохранённый, _) = результат else {
        Issue.record("Ожидался явный неподдержанный исход")
        continue
      }
      #expect(сохранённый == вход)
      #expect(хэш(сохранённый.данные) == сохранённый.привязка.ожидаемыйSHA256)
    }
  }

  @Test("ошибки SHA, длины, смещения и лимита отклоняются без запуска профиля")
  func плохаяПривязкаОтклоняетсяДоИсполнения() throws {
    let корректный = срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[]}}"#)
    let испорченныйSHA = СрезJSONL(
      данные: корректный.данные,
      привязка: ПривязкаСрезаJSONL(
        источник: корректный.привязка.источник, смещение: 0,
        длина: корректный.данные.count, ожидаемыйSHA256: String(repeating: "0", count: 64)))
    let невернаяДлина = СрезJSONL(
      данные: корректный.данные,
      привязка: ПривязкаСрезаJSONL(
        источник: корректный.привязка.источник, смещение: 0,
        длина: корректный.данные.count + 1, ожидаемыйSHA256: корректный.привязка.ожидаемыйSHA256))
    let отрицательноеСмещение = СрезJSONL(
      данные: корректный.данные,
      привязка: ПривязкаСрезаJSONL(
        источник: корректный.привязка.источник, смещение: -1,
        длина: корректный.данные.count, ожидаемыйSHA256: корректный.привязка.ожидаемыйSHA256))
    let переполнение = СрезJSONL(
      данные: корректный.данные,
      привязка: ПривязкаСрезаJSONL(
        источник: корректный.привязка.источник, смещение: Int.max,
        длина: корректный.данные.count, ожидаемыйSHA256: корректный.привязка.ожидаемыйSHA256))
    let слишкомБольшой = СрезJSONL(
      данные: Data(repeating: 0x20, count: 262_145),
      привязка: ПривязкаСрезаJSONL(
        источник: корректный.привязка.источник, смещение: 0,
        длина: 262_145, ожидаемыйSHA256: корректный.привязка.ожидаемыйSHA256))
    var замеры: [ЗамерФасадаJSONL] = []

    let случаи: [(СрезJSONL, String)] = [
      (испорченныйSHA, "sha256-среза"),
      (невернаяДлина, "длина-среза"),
      (отрицательноеСмещение, "отрицательное-смещение"),
      (переполнение, "переполнение-смещения"),
      (слишкомБольшой, "предел-среза"),
    ]
    for (вход, ожидаемыйКод) in случаи {
      let результат = try ФасадJSONL.выполнить(вход) { замеры.append($0) }
      guard case .отклонено(let сохранённый, let код, _) = результат else {
        Issue.record("Ожидался отказ валидации привязки")
        continue
      }
      #expect(сохранённый == вход)
      #expect(код == ожидаемыйКод)
    }
    #expect(замеры.count == 1)
    #expect(замеры.allSatisfy { $0.этап == "проверка-среза" })
  }

  @Test("повтор равен, а другой offset создаёт отдельную привязку")
  func повторИРазныеСмещения() throws {
    let первый = срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"text","text":"same"}]}}"#, смещение: 7)
    let другойOffset = срез(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"text","text":"same"}]}}"#, смещение: 700)
    let a = try проекция(ФасадJSONL.выполнить(первый))
    let b = try проекция(ФасадJSONL.выполнить(первый))
    let c = try проекция(ФасадJSONL.выполнить(другойOffset))

    #expect(a == b)
    #expect(a.исходныйСрез != c.исходныйСрез)
    #expect(a.хэшСреза == c.хэшСреза)
    #expect(a.хэшВходаОператора == c.хэшВходаОператора)
    #expect(a.хэшРезультатаОператора == c.хэшРезультатаОператора)
  }

  @Test("малый synthetic профиль измеряет конечные срезы без суммирования вложенных стадий")
  func малыйSyntheticПрофиль() throws {
    let texts = ["a", "hello", "конечный синтетический вход"]
    var строкиОтчёта: [String] = []
    for (индекс, текст) in texts.enumerated() {
      let escaped = текст.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
      let вход = срез(
        #"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":""# + escaped + #""}]}}"#,
        источник: "synthetic-\(индекс)", смещение: индекс * 4096)
      var замеры: [ЗамерФасадаJSONL] = []
      let старт = DispatchTime.now().uptimeNanoseconds
      let исход = try ФасадJSONL.выполнить(вход) { замеры.append($0) }
      let полноеВремя = DispatchTime.now().uptimeNanoseconds - старт
      let значение = try проекция(исход)
      let stageValues = замеры.map {
        "{\"stage\":\"\($0.этап)\",\"ns\":\($0.наносекунды),\"nested\":\($0.вложенный)}"
      }.joined(separator: ",")
      строкиОтчёта.append(
        "{\"sample\":\(индекс),\"source_bytes\":\(вход.данные.count),\"source_sha256\":\"\(значение.хэшСреза)\",\"wall_ns\":\(полноеВремя),\"events\":[\(stageValues)]}")
    }
    let отчёт = "{\"schema\":\"fum.synthetic-jsonl-profile.1\",\"samples\":[\(строкиОтчёта.joined(separator: ","))],\"interpretation\":\"finite synthetic records only; nested executor stages are not summed\"}"
    print("FUM_JSONL_PROFILE=\(отчёт)")
    #expect(texts.count == 3)
    #expect(строкиОтчёта.count == 3)
  }
}

private struct ОшибкаПроверки: Error {}
