import Foundation
import ОсноваЗапуска

private struct Данные: Decodable {
  let идентификатор: String
  let поколение: UInt64
  let время: String
  let назначениеПерехода: String
  let вопрос: String
  let ответ: String
  let ссылкаВопроса: ЗакреплённаяСсылка
  let ссылкаОтвета: ЗакреплённаяСсылка
  let состояние: СостояниеПреемника
  func вход() -> ВходВопросОтвета {
    ВходВопросОтвета(идентификатор: идентификатор, поколение: поколение, время: время,
      назначениеПерехода: назначениеПерехода, вопрос: вопрос, ответ: ответ,
      ссылкаВопроса: ссылкаВопроса, ссылкаОтвета: ссылкаОтвета, состояние: состояние)
  }
}
private struct Файл: Decodable { let вход: Данные }
private enum ОшибкаПробы: Error { case аргументы, неизвестныйИсход, несовпадение }
@main struct ПервыйВызовA12 {
  static func main() throws {
    guard CommandLine.arguments.count == 3 else { throw ОшибкаПробы.аргументы }
    let данные = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let вход = try JSONDecoder().decode(Файл.self, from: данные).вход.вход()
    let хранилище = ХранилищеАртефактов(кореньХранилища: CommandLine.arguments[2])
    let адаптер = АдаптерВопросОтвет(хранилище: хранилище)
    let часы = ContinuousClock()
    let начало = часы.now
    switch try адаптер.сохранить(вход) {
    case let .исходНеизвестен(идентификатор, хэш):
      print("UNKNOWN " + идентификатор + " " + хэш)
      throw ОшибкаПробы.неизвестныйИсход
    case let .подтверждён(артефакт, квитанция, исход):
      let части = начало.duration(to: часы.now).components
      let мс = Double(части.seconds) * 1000 + Double(части.attoseconds) / 1e15
      let восстановленный = try хранилище.восстановитьПреемника(
        идентификатор: вход.идентификатор, поколение: вход.поколение,
        как: НагрузкаВопросОтвета.self)
      guard восстановленный?.артефакт == артефакт,
            восстановленный?.квитанция == квитанция else { throw ОшибкаПробы.несовпадение }
      let отчёт: [String: String] = [
        "состояние": "CONFIRMED_REOPEN_MATCH", "исход": исход.rawValue,
        "запись": квитанция.описание.идентификатор, "sha256": квитанция.хэш,
        "байты": String(квитанция.размер), "входДоИсторииМс": String(мс)]
      print(String(decoding: try JSONSerialization.data(withJSONObject: отчёт,
        options: [.sortedKeys]), as: UTF8.self))
    }
  }
}
