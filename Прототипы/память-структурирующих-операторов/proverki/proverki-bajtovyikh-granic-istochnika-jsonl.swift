import CryptoKit
import Foundation
import Testing
@testable import FUMStructuringOperatorMemory

struct ПроверкиБайтовыхГраницИсточникаJSONL {
  private let хэшФикстуры = "26af636482d084730cee896bab1715180e8d867377c1fe8624d8b1dd2a5d1ea1"
  private let хэшРесурса = "eccd305caf8a61018f3e2607109be5b0f3b8bf20bb1a334ad4ea141a93056fba"

  private func хэш(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  }

  private func фикстура() -> Data {
    Data(#"{"type":"response_item","payload":{"type":"message","role":"assistant","content":[]}}"#.utf8)
  }

  private func граничныеИсточники() -> (принятый: String, отклонённый: String, принятыеБайты: Data, отклонённыеБайты: Data) {
    var составныеБайты = Data(repeating: 0x61, count: 254)
    составныеБайты.append(contentsOf: [0xC3, 0xA9])
    var nfdБайты = Data(repeating: 0x61, count: 254)
    nfdБайты.append(contentsOf: [0x65, 0xCC, 0x81])
    return (
      String(decoding: составныеБайты, as: UTF8.self),
      String(decoding: nfdБайты, as: UTF8.self),
      составныеБайты,
      nfdБайты)
  }

  private func срез(источник: String, данные: Data, смещение: Int = 4_096) -> СрезJSONL {
    СрезJSONL(
      данные: данные,
      привязка: ПривязкаСрезаJSONL(
        источник: источник,
        смещение: смещение,
        длина: данные.count,
        ожидаемыйSHA256: хэш(данные)))
  }

  private func проверитьСохранение(
    _ сохранённый: СрезJSONL,
    ожидаемый: СрезJSONL,
    байтыИсточника: Data
  ) {
    #expect(сохранённый.данные == ожидаемый.данные)
    #expect(Data(сохранённый.привязка.источник.utf8) == байтыИсточника)
    #expect(Data(ожидаемый.привязка.источник.utf8) == байтыИсточника)
    #expect(сохранённый.привязка.смещение == ожидаемый.привязка.смещение)
    #expect(сохранённый.привязка.длина == ожидаемый.привязка.длина)
    #expect(сохранённый.привязка.ожидаемыйSHA256 == ожидаемый.привязка.ожидаемыйSHA256)
  }

  @Test("Ровно 256 UTF-8 байт принимаются, а канонически равные 257 байт NFD отклоняются")
  func границаUTF8ИТочныеБайты() throws {
    let источники = граничныеИсточники()
    #expect(источники.принятый == источники.отклонённый)
    #expect(источники.принятыеБайты.count == 256)
    #expect(источники.отклонённыеБайты.count == 257)
    #expect(источники.принятыеБайты != источники.отклонённыеБайты)
    #expect(Data(источники.принятый.utf8) == источники.принятыеБайты)
    #expect(Data(источники.отклонённый.utf8) == источники.отклонённыеБайты)

    let данные = фикстура()
    #expect(хэш(данные) == хэшФикстуры)
    let принятыйСрез = срез(источник: источники.принятый, данные: данные)
    let отклонённыйСрез = срез(источник: источники.отклонённый, данные: данные)

    let принятыйИсход = try ФасадJSONL.выполнить(принятыйСрез)
    guard case .проецировано(let проекция) = принятыйИсход else {
      Issue.record("Ожидалась проекция 256-байтового source ID")
      return
    }
    проверитьСохранение(
      проекция.исходныйСрез,
      ожидаемый: принятыйСрез,
      байтыИсточника: источники.принятыеБайты)
    #expect(проекция.хэшСреза == хэшФикстуры)
    #expect(проекция.автор == "неизвестно")
    #expect(проекция.хэшРесурсаОпределения == хэшРесурса)

    var событияОтказа: [ЗамерФасадаJSONL] = []
    let отклонённыйИсход = try ФасадJSONL.выполнить(отклонённыйСрез) { событияОтказа.append($0) }
    guard case .отклонено(let сохранённый, let код, let вычисленныйSHA256) = отклонённыйИсход else {
      Issue.record("Ожидался typed-отказ 257-байтового source ID")
      return
    }
    проверитьСохранение(
      сохранённый,
      ожидаемый: отклонённыйСрез,
      байтыИсточника: источники.отклонённыеБайты)
    #expect(код == "источник")
    #expect(вычисленныйSHA256 == nil)
    #expect(событияОтказа.isEmpty)
  }

  @Test("Малый профиль двух конечных source ID не задаёт порогов")
  func малыйПрофильГраницыUTF8() throws {
    let источники = граничныеИсточники()
    let данные = фикстура()
    let образцы = [
      (имя: "accepted-256", источник: источники.принятый, байты: источники.принятыеБайты),
      (имя: "rejected-257-nfd", источник: источники.отклонённый, байты: источники.отклонённыеБайты),
    ]
    var строки: [String] = []
    for (номер, образец) in образцы.enumerated() {
      let вход = срез(источник: образец.источник, данные: данные, смещение: 8_192 + номер)
      var события: [ЗамерФасадаJSONL] = []
      let начало = DispatchTime.now().uptimeNanoseconds
      let результат = try ФасадJSONL.выполнить(вход) { события.append($0) }
      let время = DispatchTime.now().uptimeNanoseconds - начало
      let исход: String
      switch результат {
      case .проецировано: исход = "projected"
      case .отклонено(_, let код, _): исход = "rejected:\(код)"
      case .неподдержано(_, let код): исход = "unsupported:\(код)"
      }
      let событияJSON = события.map {
        "{\"stage\":\"\($0.этап)\",\"ns\":\($0.наносекунды),\"outcome\":\"\($0.исход)\",\"nested\":\($0.вложенный)}"
      }.joined(separator: ",")
      строки.append(
        "{\"sample\":\"\(образец.имя)\",\"source_bytes\":\(образец.байты.count),\"source_sha256\":\"\(хэш(образец.байты))\",\"frame_sha256\":\"\(хэш(данные))\",\"offset\":\(вход.привязка.смещение),\"outcome\":\"\(исход)\",\"wall_ns\":\(время),\"events\":[\(событияJSON)]}")
    }
    let отчёт = "{\"schema\":\"fum.synthetic-jsonl-source-boundary-profile.1\",\"samples\":[\(строки.joined(separator: ","))],\"interpretation\":\"two finite open samples only; no thresholds or speed claim; nested events are not summed\"}"
    print("FUM_JSONL_SOURCE_BOUNDARY_PROFILE=\(отчёт)")
    #expect(строки.count == 2)
  }
}
