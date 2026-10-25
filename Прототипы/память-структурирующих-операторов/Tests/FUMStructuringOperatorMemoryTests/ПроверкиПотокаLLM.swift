import Foundation
import Testing

@testable import FUMStructuringOperatorMemory

@Suite("Байтовый разбор SSE для LLM")
struct ПроверкиПотокаLLM {
  @Test("Каждый байт UTF-8, BOM и CRLF сохраняет данные и исходные рамки")
  func каждыйБайтСохраняетПолнуюРамку() throws {
    var первая = Data([0xEF, 0xBB, 0xBF])
    первая.append(
      Data(": пояснение\r\nevent: text_delta\r\nid: 42\r\ndata: Ёж 🦔\r\ndata: ещё\r\n\r\n".utf8))
    let вторая = Data("data: конец\r\n\r\n".utf8)
    var всё = первая
    всё.append(вторая)
    let целиком = try собратьКадры([всё])
    let побайтно = try собратьКадры(всё.map { Data([$0]) })

    #expect(побайтно == целиком)
    #expect(побайтно.count == 2)
    let начало = try #require(побайтно.first)
    let конец = try #require(побайтно.last)
    #expect(начало.событие == "text_delta")
    #expect(начало.идентификатор == "42")
    #expect(начало.данные == Data("Ёж 🦔\nещё".utf8))
    #expect(начало.сырыеБайты == первая)
    #expect(конец.событие == "message")
    #expect(конец.идентификатор == "42")
    #expect(конец.данные == Data("конец".utf8))
    #expect(конец.сырыеБайты == вторая)
  }

  @Test("Любое одиночное дробление потока даёт одинаковые кадры")
  func каждоеДроблениеСохраняетИсход() throws {
    let данные = Data("event: α\r\ndata: Ё\r\n\r\ndata: 🦔\n\ndata: конец\r\r".utf8)
    let ожидаемые = try собратьКадры([данные])
    #expect(ожидаемые.count == 3)

    for позиция in 0...данные.count {
      let первая = Data(данные.prefix(позиция))
      let вторая = Data(данные.dropFirst(позиция))
      let фактические = try собратьКадры([первая, Data(), вторая])
      #expect(фактические == ожидаемые)
    }
  }

  @Test("LF, CR и CRLF одинаково разделяют строки")
  func триВидаРазделителейСтрок() throws {
    for разделитель in ["\n", "\r", "\r\n"] {
      let текст = "data: первая" + разделитель + "data: вторая" + разделитель + разделитель
      let данные = Data(текст.utf8)
      let кадры = try собратьКадры(данные.map { Data([$0]) })
      #expect(кадры.count == 1)
      let кадр = try #require(кадры.first)
      #expect(кадр.событие == "message")
      #expect(кадр.идентификатор == nil)
      #expect(кадр.данные == Data("первая\nвторая".utf8))
      #expect(кадр.сырыеБайты == данные)
    }
  }

  @Test("Комментарии и неизвестные поля остаются в исходных байтах")
  func неизвестныеПоляСохраняютсяВРамке() throws {
    let данные = Data(
      ": комментарий\nполе-без-двоеточия\nretry: 1500\nx-future: Ё\ndata: ответ\n\n".utf8)
    let кадры = try собратьКадры([данные])
    let кадр = try #require(кадры.first)
    #expect(кадры.count == 1)
    #expect(кадр.событие == "message")
    #expect(кадр.данные == Data("ответ".utf8))
    #expect(кадр.сырыеБайты == данные)
  }

  @Test("Пустая строка data является событием с пустыми данными")
  func пустыеДанныеОтличаютсяОтОтсутствующих() throws {
    for текст in ["data:\n\n", "data\n\n", "data: \n\n"] {
      let данные = Data(текст.utf8)
      let кадры = try собратьКадры([данные])
      #expect(кадры.count == 1)
      let кадр = try #require(кадры.first)
      #expect(кадр.данные == Data())
      #expect(кадр.сырыеБайты == данные)
    }
    let безДанных = try собратьКадры([
      Data(": ping\nevent: необъявленное\nx-extra: значение\n\n".utf8)
    ])
    #expect(безДанных.isEmpty)
  }

  @Test("Объединение data удаляет ровно один пробел после двоеточия")
  func многострочныеДанныеСохраняютПробелы() throws {
    let данные = Data("data:  начало \ndata:\ndata: хвост  \n\n".utf8)
    let кадры = try собратьКадры([данные])
    let кадр = try #require(кадры.first)
    #expect(кадры.count == 1)
    #expect(кадр.данные == Data(" начало \n\nхвост  ".utf8))
    #expect(кадр.сырыеБайты == данные)
  }

  @Test("Последние event и id действуют, пустой event возвращает message")
  func последниеПоляИПустоеИмяСобытия() throws {
    let первая = Data("event: раннее\nevent: новое\nid: 1\nid: 2\ndata: а\n\n".utf8)
    let вторая = Data("event:\ndata: б\n\n".utf8)
    let кадры = try собратьКадры([первая, вторая])
    #expect(кадры.count == 2)
    let начало = try #require(кадры.first)
    let конец = try #require(кадры.last)
    #expect(начало.событие == "новое")
    #expect(начало.идентификатор == "2")
    #expect(конец.событие == "message")
    #expect(конец.идентификатор == "2")
  }

  @Test("id сохраняется между рамками, NUL игнорируется, пустое id сбрасывает значение")
  func идентификаторСохраняетсяИСбрасывается() throws {
    let управление = Data("id: исходный\n\n".utf8)
    let первая = Data("id: неверный\u{0000}хвост\ndata: а\n\n".utf8)
    let вторая = Data("id:\ndata: б\n\n".utf8)
    let третья = Data("data: в\n\n".utf8)
    let кадры = try собратьКадры([управление, первая, вторая, третья])
    #expect(кадры.count == 3)
    let начало = try #require(кадры.first)
    #expect(начало.идентификатор == "исходный")
    #expect(начало.сырыеБайты == первая)
    #expect(кадры.dropFirst().allSatisfy { $0.идентификатор == "" })
  }

  @Test("Поля SSE чувствительны к регистру")
  func регистрПолейНеНормализуется() throws {
    let данные = Data("Data: лишнее\nEVENT: лишнее\ndata: ответ\n\n".utf8)
    let кадры = try собратьКадры([данные])
    let кадр = try #require(кадры.first)
    #expect(кадр.событие == "message")
    #expect(кадр.данные == Data("ответ".utf8))
    #expect(кадр.сырыеБайты == данные)
  }

  @Test("Граница CRLF между вызовами не создаёт лишнюю пустую строку")
  func разделённаяПараРазделителейНеЗавершаетРамкуРаньше() throws {
    var разбор = РазборSSELLM()
    let начало = try разбор.принять(Data("data: а\r".utf8))
    let продолжение = try разбор.принять(Data("\ndata: б\r\n".utf8))
    #expect(начало.isEmpty)
    #expect(продолжение.isEmpty)
    let кадры = try разбор.принять(Data("\r\n".utf8))
    #expect(кадры.count == 1)
    let кадр = try #require(кадры.first)
    #expect(кадр.данные == Data("а\nб".utf8))
    #expect(кадр.сырыеБайты == Data("data: а\r\ndata: б\r\n\r\n".utf8))
    #expect(try разбор.завершить().isEmpty)
    #expect(разбор.незавершённыйХвост.isEmpty)
  }

  @Test("EOF возвращает CR-only кадр только после настоящей пустой строки")
  func завершениеРазрешаетОтложенныйВозвратКаретки() throws {
    let данные = Data("data: конец\r\r".utf8)
    var разбор = РазборSSELLM()
    let доКонцаПотока = try разбор.принять(данные)
    #expect(доКонцаПотока.isEmpty)
    let кадры = try разбор.завершить()
    #expect(кадры.count == 1)
    let кадр = try #require(кадры.first)
    #expect(кадр.данные == Data("конец".utf8))
    #expect(кадр.сырыеБайты == данные)
    #expect(разбор.незавершённыйХвост.isEmpty)
  }

  @Test("EOF без пустой строки сохраняет хвост и не создаёт кадр")
  func незавершённыйХвостНеИсполняется() throws {
    for текст in ["data: хвост", "data: хвост\n", "data: хвост\r", "event: новое\ndata: хвост\r\n"]
    {
      let данные = Data(текст.utf8)
      var разбор = РазборSSELLM()
      #expect(try разбор.принять(данные).isEmpty)
      #expect(try разбор.завершить().isEmpty)
      #expect(разбор.незавершённыйХвост == данные)
    }
  }

  @Test("Полный кадр перед хвостом сохраняется ровно один раз")
  func полныйКадрНеТеряетсяИзЗаХвоста() throws {
    let первая = Data("data: готово\n\n".utf8)
    let хвост = Data("data: незаконченное".utf8)
    var всё = первая
    всё.append(хвост)
    var разбор = РазборSSELLM()
    let кадры = try разбор.принять(всё)
    #expect(кадры.count == 1)
    let кадр = try #require(кадры.first)
    #expect(кадр.сырыеБайты == первая)
    #expect(try разбор.завершить().isEmpty)
    #expect(разбор.незавершённыйХвост == хвост)
  }

  @Test("Неверный UTF-8 завершённой строки даёт типизированный отказ")
  func невернаяКодировкаНеПодменяетсяСимволомЗамены() {
    for префикс in ["data: ", ": ", "x-extra: "] {
      var данные = Data(префикс.utf8)
      данные.append(contentsOf: [0xC3, 0x28])
      данные.append(Data("\n\n".utf8))
      var разбор = РазборSSELLM()
      ожидатьОшибку(.протокол) { _ = try разбор.принять(данные) }
    }
  }

  @Test("Оборванная UTF-8 последовательность обнаруживается на EOF")
  func незавершённаяКодировкаОтказываетНаКонце() throws {
    var данные = Data("data: ".utf8)
    данные.append(contentsOf: [0xF0, 0x9F, 0xA6])
    var разбор = РазборSSELLM()
    #expect(try разбор.принять(данные).isEmpty)
    ожидатьОшибку(.протокол) { _ = try разбор.завершить() }
  }

  @Test("Точная граница размера рамки допускается")
  func точнаяГраницаРазмеровДопускается() throws {
    let данные = Data("data: Ё\n\n".utf8)
    let кадры = try собратьКадры([данные], предел: данные.count)
    #expect(кадры.count == 1)
    #expect(кадры.first?.сырыеБайты == данные)
  }

  @Test("Переполнение рамки даёт пределРесурсов и не накапливает лишний хвост")
  func превышениеПределаЗакрываетРазбор() throws {
    let предел = 16
    let данные = Data(("data: " + String(repeating: "а", count: 20) + "\n\n").utf8)
    var разбор = РазборSSELLM(пределБайтовРамки: предел)
    #expect(try разбор.принять(Data(данные.prefix(предел))).isEmpty)
    ожидатьОшибку(.пределРесурсов) {
      _ = try разбор.принять(Data(данные.dropFirst(предел)))
    }
    #expect(разбор.незавершённыйХвост.count <= предел)
  }

  @Test("Комментарии и неизвестные поля тоже ограничены размером рамки")
  func управляющиеСтрокиТожеОграничены() {
    for префикс in [": ", "x-extra: "] {
      let данные = Data((префикс + String(repeating: "я", count: 20) + "\n\n").utf8)
      var разбор = РазборSSELLM(пределБайтовРамки: 16)
      ожидатьОшибку(.пределРесурсов) { _ = try разбор.принять(данные) }
    }
  }

  @Test("Предел относится к одной рамке, а не ко всему сетевому chunk")
  func многоМаленькихРамокДопускаютсяВОдномВызове() throws {
    let данные = Data(String(repeating: "data: я\n\n", count: 40).utf8)
    let кадры = try собратьКадры([данные], предел: 32)
    #expect(кадры.count == 40)
    #expect(кадры.allSatisfy { $0.данные == Data("я".utf8) })
    #expect(кадры.reduce(into: Data()) { $0.append($1.сырыеБайты) } == данные)
  }
}

private func собратьКадры(_ части: [Data], предел: Int = 1_048_576) throws -> [КадрSSELLM] {
  var разбор = РазборSSELLM(пределБайтовРамки: предел)
  var кадры: [КадрSSELLM] = []
  for часть in части {
    кадры.append(contentsOf: try разбор.принять(часть))
  }
  кадры.append(contentsOf: try разбор.завершить())
  return кадры
}

private func ожидатьОшибку(_ вид: ВидОшибкиLLM, _ действие: () throws -> Void) {
  do {
    try действие()
    Issue.record("Ожидалась ошибка вида \(вид), получен успех")
  } catch let ошибка as ОшибкаLLM {
    #expect(ошибка.вид == вид)
  } catch let ошибка {
    Issue.record("Ожидалась ОшибкаLLM, получена \(ошибка)")
  }
}
