import CryptoKit
import Dispatch
import Foundation

public enum РешениеСквознойПриёмки: String, Codable, Equatable, Sendable {
  case принято
  case отклонено
}

public struct ПроверкаСквознойПриёмки: Codable, Equatable, Sendable {
  public let идентификатор: String
  public let пройдена: Bool
  public let свидетельство: String

  public init(идентификатор: String, пройдена: Bool, свидетельство: String) {
    self.идентификатор = идентификатор
    self.пройдена = пройдена
    self.свидетельство = свидетельство
  }
}

public struct ПокрытиеПишущихЗапусков: Codable, Equatable, Sendable {
  public let допущеноПишущихЗапусков: Int
  public let кандидатныхКоммитов: Int
  public let бездействий: Int
  public let блокировокДоЗаписи: Int
  public let публикационныхОтказов: Int
  public let конфликтовИнтеграции: Int
  public let искусственныхПустыхКоммитов: Int
  public let покрытыхКоммитов: Int
  public let требующихКоммита: Int
}

public struct СобытиеПишущегоЗапуска: Codable, Equatable, Sendable {
  public let идентификаторЗапуска: String
  public let идентификаторПодузла: String
  public let допущен: Bool
  public let требовалсяКоммит: Bool
  public let исход: WritingSubnodeOutcome
  public let базовыйКоммит: String
  public let созданныйКоммит: String?
  public let базовоеДерево: String
  public let итоговоеДерево: String?
  public let отпечатокПаспорта: String?
}

public struct СобытиеИнтеграцииСценария: Codable, Equatable, Sendable {
  public let идентификаторПопытки: String
  public let исход: CandidateCommitIntegrationOutcome
  public let кандидатныеКоммиты: [String]
  public let целевойКоммитДо: String
  public let целевойКоммитПосле: String
  public let созданныйКоммит: String?
  public let отпечатокПаспорта: String?
  public let отпечатокДиагностики: String?
}

public struct СвидетельствоВосстановленияОчереди: Codable, Equatable, Sendable {
  public let идентификаторОчереди: String
  public let идентификаторРепозитория: String
  public let ссылкаВетки: String
  public let последовательностьЗавершённогоБилета: Int
  public let последовательностьВосстановленногоБилета: Int
  public let отпечатокСледующегоШага: String
  public let локальныеСлужебныеСсылки: [String]
  public let каноническоеСостояние: Bool
  public let служебныеСсылкиНеОпубликованы: Bool
}

public struct ОтчётСквознойПриёмки: Codable, Equatable, Sendable {
  public let решение: РешениеСквознойПриёмки
  public let проверки: [ПроверкаСквознойПриёмки]
  public let покрытие: ПокрытиеПишущихЗапусков
  public let первыйОтпечатокПаспорта: String
  public let повторныйОтпечатокПаспорта: String
  public let первыеОтпечаткиПаспортов: [String: String]
  public let повторныеОтпечаткиПаспортов: [String: String]
  public let версияПрофиляЭквивалентностиПаспортов: Int
  public let исключённыеПоляЭквивалентностиПаспортов: [String]
  public let первыеИтоговыеДеревья: [String: String]
  public let повторныеИтоговыеДеревья: [String: String]
  public let событияПишущихЗапусков: [СобытиеПишущегоЗапуска]
  public let событияИнтеграции: [СобытиеИнтеграцииСценария]
  public let точкиПрерыванийПередСравнениемИЗаменой: [String]
  public let первыеВосстановленныеОчереди: [String: СвидетельствоВосстановленияОчереди]
  public let повторныеВосстановленныеОчереди: [String: СвидетельствоВосстановленияОчереди]
  public let границаДоказательства: String

  public func каноническиеДанные() throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(self)
  }
}

public enum СквознаяПриёмкаРепозиторнойКомпозиции {
  public static func выполнить() throws -> ОтчётСквознойПриёмки {
    let первый = try СтендСквознойПриёмки().выполнить()
    let повторный = try СтендСквознойПриёмки().выполнить()

    let проверки = [
      проверка(
        "два-параллельных-кандидата",
        первый.дваПараллельныхКандидата && повторный.дваПараллельныхКандидата,
        "Два допущенных исполнителя одновременно создали разные candidate refs в отдельных клонах; исходный checkout не изменён."
      ),
      проверка(
        "бесконфликтная-и-разрешённая-интеграция",
        первый.интеграцияЗавершена && повторный.интеграцияЗавершена,
        "Первый кандидат вошёл без конфликта; второй породил зарегистрированное разрешение и отдельный многородительский commit."
      ),
      проверка(
        "неизвестный-конфликт-сохранён",
        первый.неизвестныйКонфликтСохранён && повторный.неизвестныйКонфликтСохранён,
        "Неизвестный путь получил resolution_required, каноническую диагностику и достижимые входные commit; целевой ref не сдвинут."
      ),
      проверка(
        "покрытие-пишущих-запусков",
        первый.покрытие == повторный.покрытие
          && первый.событияПишущихЗапусков == повторный.событияПишущихЗапусков
          && первый.покрытие.искусственныхПустыхКоммитов == 0,
        "Зафиксированы candidate commit, no-op, блокировка до записи, публикационный отказ и integration conflict без пустых commit."
      ),
      проверка(
        "fork-и-проект-передали-результаты-в-общего-родителя",
        первый.дочерниеРезультатыПереданы && повторный.дочерниеРезультатыПереданы,
        "Две независимые живые ветки передали новые OID в общий parent.git; оба gitlink обновлены одним CAS."
      ),
      проверка(
        "свежие-клоны-восстановили-снимки-и-управление",
        первый.свежиеКлоныВосстановлены && повторный.свежиеКлоныВосстановлены
          && первый.восстановленныеОчереди == повторный.восстановленныеОчереди,
        "Свежий detached parent clone материализовал оба точных gitlink; свежие child clones восстановили live refs, очереди и next-step refs."
      ),
      проверка(
        "повтор-воспроизводит-паспорта-и-деревья",
        первый.отпечатокПаспорта == повторный.отпечатокПаспорта
          && первый.отпечаткиПаспортов == повторный.отпечаткиПаспортов
          && первый.итоговыеДеревья == повторный.итоговыеДеревья,
        "Фиксированные author/committer dates и канонический JSON дали одинаковые паспорта и tree OID двух независимых прогонов."
      ),
      проверка(
        "прерывания-перед-cas-атомарны",
        первый.прерыванияПередСравнениемИЗаменойАтомарны
          && повторный.прерыванияПередСравнениемИЗаменойАтомарны
          && первый.точкиПрерыванийПередСравнениемИЗаменой
            == повторный.точкиПрерыванийПередСравнениемИЗаменой,
        "Инъекции в восьми точках после передачи объектов и непосредственно перед заменой refs оставили цели в точном прежнем состоянии."
      ),
      проверка(
        "пробник-автономен-и-не-подменяет-инфраструктуру",
        первый.автономнаяГраницаСоблюдена && повторный.автономнаяГраницаСоблюдена,
        "Стенд запускает только локальный Git и файловые операции; паспорта запрещают сеть и модельные вызовы."
      ),
    ]
    let решение: РешениеСквознойПриёмки =
      проверки.allSatisfy(\.пройдена) ? .принято : .отклонено
    return ОтчётСквознойПриёмки(
      решение: решение,
      проверки: проверки,
      покрытие: первый.покрытие,
      первыйОтпечатокПаспорта: первый.отпечатокПаспорта,
      повторныйОтпечатокПаспорта: повторный.отпечатокПаспорта,
      первыеОтпечаткиПаспортов: первый.отпечаткиПаспортов,
      повторныеОтпечаткиПаспортов: повторный.отпечаткиПаспортов,
      версияПрофиляЭквивалентностиПаспортов: 1,
      исключённыеПоляЭквивалентностиПаспортов: [
        "candidate.execution_request_sha256",
        "candidate.source_repository_sha256",
        "integration.candidates[].passport_sha256",
        "integration.request_sha256",
      ],
      первыеИтоговыеДеревья: первый.итоговыеДеревья,
      повторныеИтоговыеДеревья: повторный.итоговыеДеревья,
      событияПишущихЗапусков: первый.событияПишущихЗапусков,
      событияИнтеграции: первый.событияИнтеграции,
      точкиПрерыванийПередСравнениемИЗаменой:
        первый.точкиПрерыванийПередСравнениемИЗаменой,
      первыеВосстановленныеОчереди: первый.восстановленныеОчереди,
      повторныеВосстановленныеОчереди: повторный.восстановленныеОчереди,
      границаДоказательства:
        "Локальная автономная фикстура без сети, секретов и модельных вызовов; внешняя инфраструктура и независимость моделей не заявлены."
    )
  }

  private static func проверка(
    _ идентификатор: String,
    _ пройдена: Bool,
    _ свидетельство: String
  ) -> ПроверкаСквознойПриёмки {
    ПроверкаСквознойПриёмки(
      идентификатор: идентификатор,
      пройдена: пройдена,
      свидетельство: свидетельство
    )
  }
}

private enum ОшибкаСквознойПриёмки: Error, Sendable {
  case нарушение(String)
  case командаКонтроляВерсий([String], Int32, String)
  case намеренноеПрерывание
}

private struct СнимокСквозногоПрогона: Sendable {
  let дваПараллельныхКандидата: Bool
  let интеграцияЗавершена: Bool
  let неизвестныйКонфликтСохранён: Bool
  let покрытие: ПокрытиеПишущихЗапусков
  let событияПишущихЗапусков: [СобытиеПишущегоЗапуска]
  let событияИнтеграции: [СобытиеИнтеграцииСценария]
  let дочерниеРезультатыПереданы: Bool
  let свежиеКлоныВосстановлены: Bool
  let прерыванияПередСравнениемИЗаменойАтомарны: Bool
  let автономнаяГраницаСоблюдена: Bool
  let отпечатокПаспорта: String
  let отпечаткиПаспортов: [String: String]
  let итоговыеДеревья: [String: String]
  let точкиПрерыванийПередСравнениемИЗаменой: [String]
  let восстановленныеОчереди: [String: СвидетельствоВосстановленияОчереди]
}

private struct ИтогКомпозиции {
  let паспорт: Data
  let отчёт: RepositoryCompositionReport
  let деревья: [String: String]
  let результатыПереданы: Bool
  let свежиеКлоныВосстановлены: Bool
  let прерыванияПередСравнениемИЗаменойАтомарны: Bool
  let точкиПрерыванийПередСравнениемИЗаменой: [String]
  let восстановленныеОчереди: [String: СвидетельствоВосстановленияОчереди]
}

private struct ПаспортВосстановленияОчереди: Codable, Equatable {
  let версияСхемы: Int
  let идентификаторОчереди: String
  let идентификаторРепозитория: String
  let ссылкаВетки: String
  let последовательностьЗавершённогоБилета: Int
  let следующаяПоследовательность: Int
  let состояние: String
  let владелец: String?
  let ожидающиеБилеты: [String]
  let идентификаторСледующегоШага: String
  let путьСледующегоШага: String
  let отпечатокСледующегоШага: String
  let отпечатокПредыдущегоСостояния: String

  func каноническиеДанные() throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try кодировщик.encode(self)
  }
}

private final class ХранилищеПараллельныхРезультатов: @unchecked Sendable {
  private let замок = NSLock()
  private var результаты: [Int: Result<WritingSubnodeExecutionResult, Error>] = [:]

  func сохранить(_ результат: Result<WritingSubnodeExecutionResult, Error>, для номера: Int) {
    замок.lock()
    результаты[номера] = результат
    замок.unlock()
  }

  func извлечь(_ номер: Int) throws -> WritingSubnodeExecutionResult {
    замок.lock()
    let результат = результаты[номер]
    замок.unlock()
    guard let результат else {
      throw ОшибкаСквознойПриёмки.нарушение("Параллельный исполнитель не вернул результат.")
    }
    return try результат.get()
  }
}

private final class СтендСквознойПриёмки: @unchecked Sendable {
  private let корень: URL
  private let файловаяСистема = FileManager.default

  init() throws {
    корень = FileManager.default.temporaryDirectory.appending(
      path: "fum-end-to-end-composition-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    try файловаяСистема.createDirectory(at: корень, withIntermediateDirectories: true)
  }

  deinit {
    try? файловаяСистема.removeItem(at: корень)
  }

  func выполнить() throws -> СнимокСквозногоПрогона {
    let источник = корень.appending(path: "writer-source", directoryHint: .isDirectory)
    try создатьИсточник(в: источник)
    let базовыйИдентификаторОбъекта = try текстКомандыКонтроляВерсий(
      ["rev-parse", "HEAD"], в: источник)
    let базовоеДерево = try текстКомандыКонтроляВерсий(
      ["rev-parse", "\(базовыйИдентификаторОбъекта)^{tree}"],
      в: источник
    )
    let исходныйСнимок = try снимокРепозитория(источник)

    let пустыеЗаписи = try документЗаписей([])
    let записиА = try документЗаписей([
      CandidateStableRecord(id: "alpha", normative: ["name": "Alpha"])
    ])
    let записиБ = try документЗаписей([
      CandidateStableRecord(id: "beta", normative: ["name": "Beta"])
    ])
    let общиеЗаписи = try документЗаписей([
      CandidateStableRecord(id: "alpha", normative: ["name": "Alpha"]),
      CandidateStableRecord(id: "beta", normative: ["name": "Beta"]),
    ])
    guard try Data(contentsOf: источник.appending(path: "data/records.json")) == пустыеЗаписи else {
      throw ОшибкаСквознойПриёмки.нарушение("Начальный документ записей недетерминирован.")
    }

    let прерываниеКандидатаА = try проверитьПрерываниеКандидата(
      обозначение: "a",
      источник: источник,
      базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
      содержимое: записиА
    )
    let прерываниеКандидатаБ = try проверитьПрерываниеКандидата(
      обозначение: "b",
      источник: источник,
      базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
      содержимое: записиБ
    )

    let параллельные = ХранилищеПараллельныхРезультатов()
    let содержимое = [записиА, записиБ]
    let текущийСтенд = self
    DispatchQueue.concurrentPerform(iterations: 2) { номер in
      do {
        let обозначение = номер == 0 ? "a" : "b"
        let исполнитель = WritingSubnodeExecutor(
          checkRegistry: WritingSubnodeCheckRegistry(specifications: [
            "records-\(обозначение)": .regularFileSHA256(
              path: "data/records.json",
              expectedSHA256: текущийСтенд.хеш(содержимое[номер])
            )
          ])
        )
        let пакет = try текущийСтенд.рабочийПакет(
          источник: источник,
          разрешённыеПути: ["data/records.json"],
          артефакты: ["data/records.json"],
          проверка: "records-\(обозначение)"
        )
        let результат = try исполнитель.execute(
          workPackageData: пакет,
          workspaceRoot: источник,
          request: текущийСтенд.запросЗаписи(
            источник: источник,
            кореньИсполнения: текущийСтенд.корень.appending(path: "execution-\(обозначение)"),
            базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
            запуск: "run-\(обозначение)",
            подузел: "writer-\(обозначение)",
            сообщение: "Create records candidate \(обозначение.uppercased())",
            записи: [WritingSubnodeWrite(path: "data/records.json", contents: содержимое[номер])]
          )
        )
        параллельные.сохранить(.success(результат), для: номер)
      } catch {
        параллельные.сохранить(.failure(error), для: номер)
      }
    }
    let кандидатА = try параллельные.извлечь(0)
    let кандидатБ = try параллельные.извлечь(1)

    let бездействие = try выполнитьБездействие(
      источник: источник, базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта)
    let блокировка = try выполнитьБлокировку(
      источник: источник, базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
      содержимое: записиА)
    let публикационныйОтказ = try выполнитьПубликационныйОтказ(
      источник: источник,
      базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
      содержимое: записиА
    )

    let целевойГолыйРепозиторий = корень.appending(
      path: "integration-target.git", directoryHint: .isDirectory)
    _ = try выполнитьКомандуКонтроляВерсий(
      ["clone", "--bare", источник.path, целевойГолыйРепозиторий.path], в: корень)
    _ = try выполнитьКомандуКонтроляВерсий(
      ["update-ref", "refs/heads/fault", базовыйИдентификаторОбъекта], в: целевойГолыйРепозиторий)
    let целевойГолыйРепозиторийКонфликта = корень.appending(
      path: "integration-conflict-target.git",
      directoryHint: .isDirectory
    )
    _ = try выполнитьКомандуКонтроляВерсий(
      ["clone", "--bare", источник.path, целевойГолыйРепозиторийКонфликта.path],
      в: корень
    )

    let ссылкаА = try ссылкаКандидата(
      кандидатА, кореньИсполнения: корень.appending(path: "execution-a"))
    let ссылкаБ = try ссылкаКандидата(
      кандидатБ, кореньИсполнения: корень.appending(path: "execution-b"))
    let реестрПроверок = CandidateIntegrationCheckRegistry(specifications: [
      "records-base": .regularFileSHA256(
        path: "data/records.json",
        expectedSHA256: хеш(пустыеЗаписи)
      ),
      "records-a": .regularFileSHA256(path: "data/records.json", expectedSHA256: хеш(записиА)),
      "records-ab": .regularFileSHA256(path: "data/records.json", expectedSHA256: хеш(общиеЗаписи)),
    ])
    let реестрРазрешений = CandidateConflictResolverRegistry(specifications: [
      "records-rule": .mergeStableRecords(
        ruleVersion: 1,
        path: "data/records.json",
        schemaIdentity: "fum.records",
        schemaVersion: 1,
        normativeFields: ["name"],
        uniqueNormativeFields: ["name"],
        requiredCheckIDs: ["records-ab"]
      )
    ])
    let интегратор = CandidateCommitIntegrator(
      checkRegistry: реестрПроверок,
      resolverRegistry: реестрРазрешений
    )
    let прерываниеИнтеграцииА = try проверитьПрерываниеИнтеграции(
      попытка: "fault-before-integration-a",
      целевойГолыйРепозиторий: целевойГолыйРепозиторий,
      базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
      кандидаты: [ссылкаА],
      проверки: ["records-a"],
      правила: [],
      реестрПроверок: реестрПроверок,
      реестрРазрешений: реестрРазрешений
    )
    let перваяИнтеграция = try интегратор.integrate(
      запросИнтеграции(
        попытка: "integrate-a",
        целевойГолыйРепозиторий: целевойГолыйРепозиторий,
        кореньИнтеграции: корень.appending(path: "integration-main-a"),
        целеваяСсылка: "refs/heads/main",
        ожидаемыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
        кандидаты: [ссылкаА],
        сообщение: "Integrate records candidate A",
        проверки: ["records-a"]
      )
    )
    guard let первыйИнтеграционныйИдентификаторОбъекта = перваяИнтеграция.integrationOID else {
      throw ОшибкаСквознойПриёмки.нарушение("Первая интеграция не создала commit.")
    }
    let прерываниеИнтеграцииБ = try проверитьПрерываниеИнтеграции(
      попытка: "fault-before-integration-b",
      целевойГолыйРепозиторий: целевойГолыйРепозиторий,
      базовыйИдентификаторОбъекта: первыйИнтеграционныйИдентификаторОбъекта,
      кандидаты: [ссылкаБ],
      проверки: ["records-ab"],
      правила: ["records-rule"],
      реестрПроверок: реестрПроверок,
      реестрРазрешений: реестрРазрешений
    )
    let втораяИнтеграция = try интегратор.integrate(
      запросИнтеграции(
        попытка: "integrate-b-resolved",
        целевойГолыйРепозиторий: целевойГолыйРепозиторий,
        кореньИнтеграции: корень.appending(path: "integration-main-b"),
        целеваяСсылка: "refs/heads/main",
        ожидаемыйИдентификаторОбъекта: первыйИнтеграционныйИдентификаторОбъекта,
        кандидаты: [ссылкаБ],
        сообщение: "Resolve and integrate records candidate B",
        проверки: ["records-ab"],
        правила: ["records-rule"]
      )
    )

    let неизвестныйКонфликт = try интегратор.integrate(
      запросИнтеграции(
        попытка: "unknown-conflict",
        целевойГолыйРепозиторий: целевойГолыйРепозиторийКонфликта,
        кореньИнтеграции: корень.appending(path: "integration-unknown-b"),
        целеваяСсылка: "refs/heads/main",
        ожидаемыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
        кандидаты: [ссылкаА, ссылкаБ],
        сообщение: "Attempt unknown records conflict",
        проверки: ["records-base"]
      )
    )

    let композиция = try выполнитьКомпозицию()
    guard let паспортА = кандидатА.passport,
      let паспортБ = кандидатБ.passport
    else {
      throw ОшибкаСквознойПриёмки.нарушение("Кандидатные паспорта отсутствуют.")
    }

    let событияПишущихЗапусков = try [
      событиеПишущегоЗапуска(
        идентификаторЗапуска: "run-a",
        идентификаторПодузла: "writer-a",
        требовалсяКоммит: true,
        результат: кандидатА,
        базовыйКоммит: базовыйИдентификаторОбъекта,
        базовоеДерево: базовоеДерево
      ),
      событиеПишущегоЗапуска(
        идентификаторЗапуска: "run-b",
        идентификаторПодузла: "writer-b",
        требовалсяКоммит: true,
        результат: кандидатБ,
        базовыйКоммит: базовыйИдентификаторОбъекта,
        базовоеДерево: базовоеДерево
      ),
      событиеПишущегоЗапуска(
        идентификаторЗапуска: "run-no-op",
        идентификаторПодузла: "writer-no-op",
        требовалсяКоммит: false,
        результат: бездействие,
        базовыйКоммит: базовыйИдентификаторОбъекта,
        базовоеДерево: базовоеДерево
      ),
      событиеПишущегоЗапуска(
        идентификаторЗапуска: "run-blocked",
        идентификаторПодузла: "writer-blocked",
        требовалсяКоммит: false,
        результат: блокировка,
        базовыйКоммит: базовыйИдентификаторОбъекта,
        базовоеДерево: базовоеДерево
      ),
      событиеПишущегоЗапуска(
        идентификаторЗапуска: "run-publication-rejected",
        идентификаторПодузла: "writer-publication-rejected",
        требовалсяКоммит: false,
        результат: публикационныйОтказ,
        базовыйКоммит: базовыйИдентификаторОбъекта,
        базовоеДерево: базовоеДерево
      ),
    ].sorted { $0.идентификаторЗапуска < $1.идентификаторЗапуска }

    let второйИнтеграционныйИдентификаторОбъекта = втораяИнтеграция.integrationOID ?? ""
    let событияИнтеграции = [
      try событиеИнтеграции(
        идентификаторПопытки: "integrate-a",
        результат: перваяИнтеграция,
        кандидаты: [паспортА.commitOID],
        целевойКоммитДо: базовыйИдентификаторОбъекта,
        целевойКоммитПосле: первыйИнтеграционныйИдентификаторОбъекта
      ),
      try событиеИнтеграции(
        идентификаторПопытки: "integrate-b-resolved",
        результат: втораяИнтеграция,
        кандидаты: [паспортБ.commitOID],
        целевойКоммитДо: первыйИнтеграционныйИдентификаторОбъекта,
        целевойКоммитПосле: второйИнтеграционныйИдентификаторОбъекта
      ),
      try событиеИнтеграции(
        идентификаторПопытки: "unknown-conflict",
        результат: неизвестныйКонфликт,
        кандидаты: [паспортА.commitOID, паспортБ.commitOID],
        целевойКоммитДо: базовыйИдентификаторОбъекта,
        целевойКоммитПосле: базовыйИдентификаторОбъекта
      ),
    ].sorted { $0.идентификаторПопытки < $1.идентификаторПопытки }
    let покрытие = построитьПокрытие(
      событияПишущихЗапусков: событияПишущихЗапусков,
      событияИнтеграции: событияИнтеграции
    )

    let источникНеизменён = try снимокРепозитория(источник) == исходныйСнимок
    let дваКандидата =
      кандидатА.outcome == .candidateCommitted
      && кандидатБ.outcome == .candidateCommitted
      && кандидатА.cloneURL != кандидатБ.cloneURL
      && паспортА.branchRef != паспортБ.branchRef
      && кандидатА.parentUnchanged && кандидатБ.parentUnchanged
      && источникНеизменён
    let родителиВторой = try текстКомандыКонтроляВерсий(
      ["rev-list", "--parents", "-n", "1", втораяИнтеграция.integrationOID ?? ""],
      в: целевойГолыйРепозиторий
    ).split(separator: " ").map(String.init)
    let кандидатАВРодословной = try успешнаКомандаКонтроляВерсий(
      ["merge-base", "--is-ancestor", паспортА.commitOID, "refs/heads/main"],
      в: целевойГолыйРепозиторий
    )
    let интеграцияЗавершена =
      перваяИнтеграция.outcome == .integrated
      && втораяИнтеграция.outcome == .integrated
      && втораяИнтеграция.passport?.resolutions.count == 1
      && родителиВторой == [
        втораяИнтеграция.integrationOID ?? "",
        первыйИнтеграционныйИдентификаторОбъекта,
        паспортБ.commitOID,
      ]
      && кандидатАВРодословной

    let диагностическиеВходы = Set(
      неизвестныйКонфликт.diagnostic?.inputs.map(\.commitOID) ?? []
    )
    let кандидатныеСсылкиДостижимы: Bool
    if let клонА = кандидатА.cloneURL, let клонБ = кандидатБ.cloneURL {
      кандидатныеСсылкиДостижимы =
        try текстКомандыКонтроляВерсий(["rev-parse", "--verify", паспортА.resultRef], в: клонА)
        == паспортА.commitOID
        && текстКомандыКонтроляВерсий(["rev-parse", "--verify", паспортБ.resultRef], в: клонБ)
          == паспортБ.commitOID
    } else {
      кандидатныеСсылкиДостижимы = false
    }
    let неизвестнаяЦельНеизменна =
      try текстКомандыКонтроляВерсий(
        ["rev-parse", "refs/heads/main"],
        в: целевойГолыйРепозиторийКонфликта
      ) == базовыйИдентификаторОбъекта
    let неизвестныйСохранён =
      неизвестныйКонфликт.outcome == .resolutionRequired
      && неизвестныйКонфликт.targetUnchanged
      && неизвестныйКонфликт.diagnosticCanonicalJSON != nil
      && неизвестнаяЦельНеизменна
      && файловаяСистема.fileExists(
        atPath: корень.appending(
          path: "integration-unknown-b/attempts/unknown-conflict/resolution-required.json"
        ).path
      )
      && диагностическиеВходы.contains(паспортА.commitOID)
      && диагностическиеВходы.contains(паспортБ.commitOID)
      && кандидатныеСсылкиДостижимы

    var итоговыеДеревья = композиция.деревья
    итоговыеДеревья["integration"] = try текстКомандыКонтроляВерсий(
      ["rev-parse", "refs/heads/main^{tree}"], в: целевойГолыйРепозиторий)
    guard let отпечатокДиагностики = неизвестныйКонфликт.diagnosticSHA256
    else {
      throw ОшибкаСквознойПриёмки.нарушение("Полный набор канонических паспортов отсутствует.")
    }
    let отпечаткиПаспортов = [
      "candidate:a": try отпечатокЭквивалентностиКандидата(кандидатА),
      "candidate:b": try отпечатокЭквивалентностиКандидата(кандидатБ),
      "integration:a": try отпечатокЭквивалентностиИнтеграции(перваяИнтеграция),
      "integration:b": try отпечатокЭквивалентностиИнтеграции(втораяИнтеграция),
      "diagnostic:unknown-conflict": отпечатокДиагностики,
      "composition": хеш(композиция.паспорт),
    ]
    let каноническийНаборПаспортов = try JSONSerialization.data(
      withJSONObject: отпечаткиПаспортов,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let отпечатокПаспорта = хеш(каноническийНаборПаспортов)
    let автономнаяГраница = [паспортА, паспортБ].allSatisfy {
      !$0.constraints.networkAllowed && !$0.constraints.modelCallsAllowed
        && !$0.constraints.sourceMutationAllowed
    }

    let точкиПрерыванийПередСравнениемИЗаменой =
      ([
        прерываниеКандидатаА ? "candidate-a" : nil,
        прерываниеКандидатаБ ? "candidate-b" : nil,
        прерываниеИнтеграцииА ? "integration-a" : nil,
        прерываниеИнтеграцииБ ? "integration-b" : nil,
      ].compactMap { $0 } + композиция.точкиПрерыванийПередСравнениемИЗаменой).sorted()

    return СнимокСквозногоПрогона(
      дваПараллельныхКандидата: дваКандидата,
      интеграцияЗавершена: интеграцияЗавершена,
      неизвестныйКонфликтСохранён: неизвестныйСохранён,
      покрытие: покрытие,
      событияПишущихЗапусков: событияПишущихЗапусков,
      событияИнтеграции: событияИнтеграции,
      дочерниеРезультатыПереданы: композиция.результатыПереданы,
      свежиеКлоныВосстановлены: композиция.свежиеКлоныВосстановлены,
      прерыванияПередСравнениемИЗаменойАтомарны:
        прерываниеКандидатаА && прерываниеКандидатаБ
        && прерываниеИнтеграцииА && прерываниеИнтеграцииБ
        && композиция.прерыванияПередСравнениемИЗаменойАтомарны,
      автономнаяГраницаСоблюдена: автономнаяГраница,
      отпечатокПаспорта: отпечатокПаспорта,
      отпечаткиПаспортов: отпечаткиПаспортов,
      итоговыеДеревья: итоговыеДеревья,
      точкиПрерыванийПередСравнениемИЗаменой:
        точкиПрерыванийПередСравнениемИЗаменой,
      восстановленныеОчереди: композиция.восстановленныеОчереди
    )
  }
}

extension СтендСквознойПриёмки {
  fileprivate func создатьИсточник(в адрес: URL) throws {
    try файловаяСистема.createDirectory(at: адрес, withIntermediateDirectories: true)
    _ = try выполнитьКомандуКонтроляВерсий(["init", "--quiet", "--initial-branch=main"], в: адрес)
    try записать(Data("pinned input\n".utf8), по: адрес.appending(path: "input.txt"))
    try записать(документЗаписей([]), по: адрес.appending(path: "data/records.json"))
    _ = try выполнитьКомандуКонтроляВерсий(
      ["add", "--", "input.txt", "data/records.json"], в: адрес)
    _ = try выполнитьКомандуКонтроляВерсий(
      ["commit", "--quiet", "-m", "writer source base"], в: адрес)
  }

  fileprivate func документЗаписей(_ записи: [CandidateStableRecord]) throws -> Data {
    try CandidateStableRecordDocument(
      schemaIdentity: "fum.records",
      schemaVersion: 1,
      records: записи
    ).canonicalJSONData()
  }

  fileprivate func рабочийПакет(
    источник: URL,
    разрешённыеПути: [String],
    артефакты: [String],
    проверка: String,
    статусЗависимости: String = "resolved"
  ) throws -> Data {
    let вход = try Data(contentsOf: источник.appending(path: "input.txt"))
    let объект: [String: Any] = [
      "schema_version": 1,
      "package_id": "fum.end-to-end.writer.v1",
      "goal": "Создать проверяемый кандидат сквозной фикстуры.",
      "deliverables": [
        [
          "id": "candidate", "role": "primary", "description": "Кандидатный commit.",
          "depends_on": [],
        ]
      ],
      "inputs": [
        [
          "id": "pinned-input", "path": "input.txt", "sha256": хеш(вход), "required": true,
        ]
      ],
      "change_scope": [
        "policy": "listed_paths_only", "allowed_paths": разрешённыеПути,
        "excluded_paths": [".git", "runtime"],
      ],
      "dependencies": [
        [
          "id": "git", "status": статусЗависимости, "evidence": "Локальный Git доступен.",
        ]
      ],
      "checks": [
        [
          "id": проверка, "description": "Содержимое детерминировано.",
        ]
      ],
      "handoff": [
        "format": "candidate_commit_v1", "required_artifacts": артефакты,
      ],
      "budget": [
        "unit": "planning_units", "limit": 20, "reading": 3, "work": 5,
        "verification": 3, "response": 2, "reserve": 7,
      ],
      "preflight": ["before_model_call": true, "before_user_data_mutation": true],
    ]
    return try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
  }

  fileprivate func запросЗаписи(
    источник: URL,
    кореньИсполнения: URL,
    базовыйИдентификаторОбъекта: String,
    запуск: String,
    подузел: String,
    сообщение: String,
    записи: [WritingSubnodeWrite]
  ) -> WritingSubnodeExecutionRequest {
    WritingSubnodeExecutionRequest(
      episodeID: "episode-end-to-end",
      stepGenerationID: "generation-0090",
      cardID: "FUM-STEP-0090",
      stepID: "step-0090",
      runID: запуск,
      subnodeID: подузел,
      repositoryID: "repo-end-to-end",
      sourceCheckoutURL: источник,
      executionRootURL: кореньИсполнения,
      targetRef: "refs/heads/main",
      baseOID: базовыйИдентификаторОбъекта,
      commitMessage: сообщение,
      writes: записи
    )
  }

  fileprivate func выполнитьБездействие(источник: URL, базовыйИдентификаторОбъекта: String) throws
    -> WritingSubnodeExecutionResult
  {
    let содержимое = try Data(contentsOf: источник.appending(path: "input.txt"))
    let исполнитель = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "input-check": .regularFileSHA256(path: "input.txt", expectedSHA256: хеш(содержимое))
      ])
    )
    return try исполнитель.execute(
      workPackageData: рабочийПакет(
        источник: источник,
        разрешённыеПути: ["input.txt"],
        артефакты: ["input.txt"],
        проверка: "input-check"
      ),
      workspaceRoot: источник,
      request: запросЗаписи(
        источник: источник,
        кореньИсполнения: корень.appending(path: "execution-no-op"),
        базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
        запуск: "run-no-op",
        подузел: "writer-no-op",
        сообщение: "Confirm unchanged input",
        записи: [WritingSubnodeWrite(path: "input.txt", contents: содержимое)]
      )
    )
  }

  fileprivate func выполнитьБлокировку(
    источник: URL,
    базовыйИдентификаторОбъекта: String,
    содержимое: Data
  ) throws -> WritingSubnodeExecutionResult {
    let исполнитель = WritingSubnodeExecutor()
    return try исполнитель.execute(
      workPackageData: рабочийПакет(
        источник: источник,
        разрешённыеПути: ["data/records.json"],
        артефакты: ["data/records.json"],
        проверка: "blocked-check",
        статусЗависимости: "unresolved"
      ),
      workspaceRoot: источник,
      request: запросЗаписи(
        источник: источник,
        кореньИсполнения: корень.appending(path: "execution-blocked"),
        базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
        запуск: "run-blocked",
        подузел: "writer-blocked",
        сообщение: "Blocked dependency",
        записи: [WritingSubnodeWrite(path: "data/records.json", contents: содержимое)]
      )
    )
  }

  fileprivate func выполнитьПубликационныйОтказ(
    источник: URL,
    базовыйИдентификаторОбъекта: String,
    содержимое: Data
  ) throws -> WritingSubnodeExecutionResult {
    let исполнитель = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "publication-check": .regularFileSHA256(
          path: "data/records.json", expectedSHA256: хеш(содержимое))
      ])
    )
    return try исполнитель.execute(
      workPackageData: рабочийПакет(
        источник: источник,
        разрешённыеПути: ["data/records.json"],
        артефакты: ["data/records.json"],
        проверка: "publication-check"
      ),
      workspaceRoot: источник,
      request: запросЗаписи(
        источник: источник,
        кореньИсполнения: корень.appending(path: "execution-publication-rejected"),
        базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
        запуск: "run-publication-rejected",
        подузел: "writer-publication-rejected",
        сообщение: "Read ~/private",
        записи: [WritingSubnodeWrite(path: "data/records.json", contents: содержимое)]
      )
    )
  }

  fileprivate func проверитьПрерываниеКандидата(
    обозначение: String,
    источник: URL,
    базовыйИдентификаторОбъекта: String,
    содержимое: Data
  ) throws -> Bool {
    let запуск = "run-fault-\(обозначение)"
    let подузел = "writer-fault-\(обозначение)"
    let проверка = "records-fault-\(обозначение)"
    let кореньИсполнения = корень.appending(path: "execution-fault-\(обозначение)")
    let исполнитель = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        проверка: .regularFileSHA256(
          path: "data/records.json",
          expectedSHA256: хеш(содержимое)
        )
      ]),
      хуки: ХукиПишущегоПодузла(
        передТранзакциейСсылок: { throw ОшибкаСквознойПриёмки.намеренноеПрерывание }
      )
    )
    var прервано = false
    do {
      _ = try исполнитель.execute(
        workPackageData: рабочийПакет(
          источник: источник,
          разрешённыеПути: ["data/records.json"],
          артефакты: ["data/records.json"],
          проверка: проверка
        ),
        workspaceRoot: источник,
        request: запросЗаписи(
          источник: источник,
          кореньИсполнения: кореньИсполнения,
          базовыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
          запуск: запуск,
          подузел: подузел,
          сообщение: "Interrupt records candidate \(обозначение.uppercased())",
          записи: [WritingSubnodeWrite(path: "data/records.json", contents: содержимое)]
        )
      )
    } catch ОшибкаСквознойПриёмки.намеренноеПрерывание {
      прервано = true
    }
    let клон = кореньИсполнения.appending(path: "runs/\(запуск)/clone")
    let ссылкаВетки = "refs/heads/fum-step/step-0090/\(подузел)-\(запуск)"
    let ссылкаРезультата = "refs/fum/results/repo-end-to-end/step-0090/\(подузел)-\(запуск)"
    let недостижимыеОбъекты = try текстКомандыКонтроляВерсий(
      ["fsck", "--unreachable", "--no-reflogs", "--no-progress"],
      в: клон
    )
    let подготовленныйКоммитСуществует = недостижимыеОбъекты.split(separator: "\n")
      .contains { $0.hasPrefix("unreachable commit ") }
    let веткаНеизменна =
      try текстКомандыКонтроляВерсий(
        ["rev-parse", ссылкаВетки],
        в: клон
      ) == базовыйИдентификаторОбъекта
    let ссылкаРезультатаСуществует = try успешнаКомандаКонтроляВерсий(
      ["show-ref", "--verify", "--quiet", ссылкаРезультата],
      в: клон
    )
    return прервано
      && веткаНеизменна
      && !ссылкаРезультатаСуществует
      && подготовленныйКоммитСуществует
  }

  fileprivate func событиеПишущегоЗапуска(
    идентификаторЗапуска: String,
    идентификаторПодузла: String,
    требовалсяКоммит: Bool,
    результат: WritingSubnodeExecutionResult,
    базовыйКоммит: String,
    базовоеДерево: String
  ) throws -> СобытиеПишущегоЗапуска {
    if let паспорт = результат.passport {
      guard паспорт.runID == идентификаторЗапуска,
        паспорт.subnodeID == идентификаторПодузла,
        паспорт.baseOID == базовыйКоммит,
        результат.passportSHA256 != nil
      else {
        throw ОшибкаСквознойПриёмки.нарушение(
          "Паспорт пишущего запуска не совпадает с записью покрытия."
        )
      }
    } else if результат.outcome == .candidateCommitted {
      throw ОшибкаСквознойПриёмки.нарушение(
        "Коммитируемый исход отсутствует в журнале паспортов."
      )
    }
    let отпечатокПаспорта = try результат.passport.map { _ in
      try отпечатокЭквивалентностиКандидата(результат)
    }
    return СобытиеПишущегоЗапуска(
      идентификаторЗапуска: идентификаторЗапуска,
      идентификаторПодузла: идентификаторПодузла,
      допущен: true,
      требовалсяКоммит: требовалсяКоммит,
      исход: результат.outcome,
      базовыйКоммит: базовыйКоммит,
      созданныйКоммит: результат.passport?.commitOID,
      базовоеДерево: базовоеДерево,
      итоговоеДерево: результат.passport?.treeOID,
      отпечатокПаспорта: отпечатокПаспорта
    )
  }

  fileprivate func событиеИнтеграции(
    идентификаторПопытки: String,
    результат: CandidateCommitIntegrationResult,
    кандидаты: [String],
    целевойКоммитДо: String,
    целевойКоммитПосле: String
  ) throws -> СобытиеИнтеграцииСценария {
    let отпечатокПаспорта = try результат.passport.map { _ in
      try отпечатокЭквивалентностиИнтеграции(результат)
    }
    return СобытиеИнтеграцииСценария(
      идентификаторПопытки: идентификаторПопытки,
      исход: результат.outcome,
      кандидатныеКоммиты: кандидаты.sorted(),
      целевойКоммитДо: целевойКоммитДо,
      целевойКоммитПосле: целевойКоммитПосле,
      созданныйКоммит: результат.integrationOID,
      отпечатокПаспорта: отпечатокПаспорта,
      отпечатокДиагностики: результат.diagnosticSHA256
    )
  }

  fileprivate func отпечатокЭквивалентностиКандидата(
    _ результат: WritingSubnodeExecutionResult
  ) throws -> String {
    guard let данные = результат.passportCanonicalJSON,
      var объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
      объект.removeValue(forKey: "execution_request_sha256") != nil,
      объект.removeValue(forKey: "source_repository_sha256") != nil
    else {
      throw ОшибкаСквознойПриёмки.нарушение(
        "Кандидатный паспорт не соответствует профилю эквивалентности версии 1."
      )
    }
    return try отпечатокПроекцииПаспорта(
      вид: "candidate",
      объект: объект,
      исключённыеПоля: [
        "candidate.execution_request_sha256",
        "candidate.source_repository_sha256",
      ]
    )
  }

  fileprivate func отпечатокЭквивалентностиИнтеграции(
    _ результат: CandidateCommitIntegrationResult
  ) throws -> String {
    guard let данные = результат.passportCanonicalJSON,
      var объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
      объект.removeValue(forKey: "request_sha256") != nil,
      let исходныеКандидаты = объект["candidates"] as? [[String: Any]]
    else {
      throw ОшибкаСквознойПриёмки.нарушение(
        "Интеграционный паспорт не соответствует профилю эквивалентности версии 1."
      )
    }
    var кандидаты: [[String: Any]] = []
    for var кандидат in исходныеКандидаты {
      guard кандидат.removeValue(forKey: "passport_sha256") != nil else {
        throw ОшибкаСквознойПриёмки.нарушение(
          "Интеграционный кандидат не содержит исключаемый отпечаток паспорта."
        )
      }
      кандидаты.append(кандидат)
    }
    объект["candidates"] = кандидаты
    return try отпечатокПроекцииПаспорта(
      вид: "integration",
      объект: объект,
      исключённыеПоля: [
        "integration.candidates[].passport_sha256",
        "integration.request_sha256",
      ]
    )
  }

  fileprivate func отпечатокПроекцииПаспорта(
    вид: String,
    объект: [String: Any],
    исключённыеПоля: [String]
  ) throws -> String {
    let проекция: [String: Any] = [
      "версия_профиля": 1,
      "вид": вид,
      "исключённые_поля": исключённыеПоля.sorted(),
      "паспорт": объект,
    ]
    guard JSONSerialization.isValidJSONObject(проекция) else {
      throw ОшибкаСквознойПриёмки.нарушение("Проекция паспорта не является JSON.")
    }
    return хеш(
      try JSONSerialization.data(
        withJSONObject: проекция,
        options: [.sortedKeys, .withoutEscapingSlashes]
      )
    )
  }

  fileprivate func построитьПокрытие(
    событияПишущихЗапусков: [СобытиеПишущегоЗапуска],
    событияИнтеграции: [СобытиеИнтеграцииСценария]
  ) -> ПокрытиеПишущихЗапусков {
    ПокрытиеПишущихЗапусков(
      допущеноПишущихЗапусков: событияПишущихЗапусков.filter(\.допущен).count,
      кандидатныхКоммитов: событияПишущихЗапусков.filter {
        $0.исход == .candidateCommitted
      }.count,
      бездействий: событияПишущихЗапусков.filter { $0.исход == .noOp }.count,
      блокировокДоЗаписи: событияПишущихЗапусков.filter {
        $0.исход == .blockedBeforeWrite
      }.count,
      публикационныхОтказов: событияПишущихЗапусков.filter {
        $0.исход == .publicationRejected
      }.count,
      конфликтовИнтеграции: событияИнтеграции.filter {
        $0.исход == .resolutionRequired
      }.count,
      искусственныхПустыхКоммитов: событияПишущихЗапусков.filter {
        $0.созданныйКоммит != nil && $0.базовоеДерево == $0.итоговоеДерево
      }.count,
      покрытыхКоммитов: событияПишущихЗапусков.filter {
        $0.созданныйКоммит != nil && $0.отпечатокПаспорта != nil
      }.count,
      требующихКоммита: событияПишущихЗапусков.filter(\.требовалсяКоммит).count
    )
  }

  fileprivate func ссылкаКандидата(
    _ результат: WritingSubnodeExecutionResult,
    кореньИсполнения: URL
  ) throws -> CandidateCommitReference {
    guard let паспорт = результат.passport, let отпечаток = результат.passportSHA256 else {
      throw ОшибкаСквознойПриёмки.нарушение("Нельзя создать ссылку на кандидат.")
    }
    return CandidateCommitReference(
      runID: паспорт.runID,
      executionRootURL: кореньИсполнения,
      expectedCommitOID: паспорт.commitOID,
      expectedPassportSHA256: отпечаток
    )
  }

  fileprivate func запросИнтеграции(
    попытка: String,
    целевойГолыйРепозиторий: URL,
    кореньИнтеграции: URL,
    целеваяСсылка: String,
    ожидаемыйИдентификаторОбъекта: String,
    кандидаты: [CandidateCommitReference],
    сообщение: String,
    проверки: [String],
    правила: [String] = []
  ) -> CandidateCommitIntegrationRequest {
    CandidateCommitIntegrationRequest(
      attemptID: попытка,
      ownerID: "acceptance-owner",
      repositoryID: "repo-end-to-end",
      targetRepositoryURL: целевойГолыйРепозиторий,
      integrationRootURL: кореньИнтеграции,
      targetRef: целеваяСсылка,
      expectedTargetOID: ожидаемыйИдентификаторОбъекта,
      commitMessage: сообщение,
      candidates: кандидаты,
      checkIDs: проверки,
      resolverRuleIDs: правила
    )
  }

  fileprivate func проверитьПрерываниеИнтеграции(
    попытка: String,
    целевойГолыйРепозиторий: URL,
    базовыйИдентификаторОбъекта: String,
    кандидаты: [CandidateCommitReference],
    проверки: [String],
    правила: [String],
    реестрПроверок: CandidateIntegrationCheckRegistry,
    реестрРазрешений: CandidateConflictResolverRegistry
  ) throws -> Bool {
    let интегратор = CandidateCommitIntegrator(
      checkRegistry: реестрПроверок,
      resolverRegistry: реестрРазрешений,
      hooks: CandidateCommitIntegratorHooks(
        beforeCompareAndSwap: { throw ОшибкаСквознойПриёмки.намеренноеПрерывание }
      )
    )
    let кореньИнтеграции = корень.appending(path: попытка)
    var прервано = false
    do {
      _ = try интегратор.integrate(
        запросИнтеграции(
          попытка: попытка,
          целевойГолыйРепозиторий: целевойГолыйРепозиторий,
          кореньИнтеграции: кореньИнтеграции,
          целеваяСсылка: "refs/heads/main",
          ожидаемыйИдентификаторОбъекта: базовыйИдентификаторОбъекта,
          кандидаты: кандидаты,
          сообщение: "Prepare interrupted integration",
          проверки: проверки,
          правила: правила
        )
      )
    } catch ОшибкаСквознойПриёмки.намеренноеПрерывание {
      прервано = true
    }
    let подготовленныйАдрес = кореньИнтеграции.appending(
      path: "attempts/\(попытка)/prepared.json"
    )
    let подготовленныеДанные = try Data(contentsOf: подготовленныйАдрес)
    let подготовленныйПаспорт = try JSONDecoder().decode(
      CandidateCommitIntegrationPassport.self,
      from: подготовленныеДанные
    )
    let подготовленныйКоммитПередан = try успешнаКомандаКонтроляВерсий(
      ["cat-file", "-e", "\(подготовленныйПаспорт.integrationOID)^{commit}"],
      в: целевойГолыйРепозиторий
    )
    let квитанцияОтсутствует = !файловаяСистема.fileExists(
      atPath: кореньИнтеграции.appending(path: "attempts/\(попытка)/result.json").path
    )
    let каноническиеПодготовленныеДанные = try подготовленныйПаспорт.canonicalJSONData()
    let цельНеизменна =
      try текстКомандыКонтроляВерсий(
        ["rev-parse", "refs/heads/main"],
        в: целевойГолыйРепозиторий
      ) == базовыйИдентификаторОбъекта
    return прервано
      && подготовленныеДанные == каноническиеПодготовленныеДанные
      && подготовленныйКоммитПередан
      && квитанцияОтсутствует
      && цельНеизменна
  }
}

extension СтендСквознойПриёмки {
  fileprivate func выполнитьКомпозицию() throws -> ИтогКомпозиции {
    try RepositoryCompositionFixtures.withFixture(named: "valid") { фикстура in
      let исходныйПаспорт = try JSONDecoder().decode(
        RepositoryCompositionPassport.self,
        from: фикстура.passportData
      )
      guard
        let подузел = исходныйПаспорт.children.first(where: { $0.kind == .specializedSubnode }),
        let проект = исходныйПаспорт.children.first(where: { $0.kind == .project }),
        let путьПодузла = подузел.submodulePath,
        let путьПроекта = проект.submodulePath,
        let базаПодузла = подузел.baseOID,
        let базаПроекта = проект.baseOID,
        let репозиторийРодителя = фикстура.context.bareRepositoriesByID["repository.parent"],
        let репозиторийЯдра = фикстура.context.bareRepositoriesByID["repository.core"],
        let репозиторийПодузла = фикстура.context.bareRepositoriesByID["repository.specialized"],
        let репозиторийПроекта = фикстура.context.bareRepositoriesByID["repository.project"],
        let живойПодузел = фикстура.context.checkoutsByEntryID["entry.specialized"]?.writerURL,
        let живойПроект = фикстура.context.checkoutsByEntryID["entry.project"]?.writerURL
      else {
        throw ОшибкаСквознойПриёмки.нарушение(
          "Базовая композиционная фикстура не содержит обязательные репозитории."
        )
      }

      let прежнийПодузел = try текстКомандыКонтроляВерсий(
        ["rev-parse", подузел.liveRef], в: репозиторийПодузла)
      let прежнийПроект = try текстКомандыКонтроляВерсий(
        ["rev-parse", проект.liveRef], в: репозиторийПроекта)
      let прежнееЯдро = try текстКомандыКонтроляВерсий(
        ["rev-parse", "refs/heads/main"], в: репозиторийЯдра)
      let прежнийРодитель = try текстКомандыКонтроляВерсий(
        ["rev-parse", исходныйПаспорт.parentRepository.liveRef],
        в: репозиторийРодителя
      )

      try записать(
        Data(
          "# Правила fork-подузла\n\nОчередь и следующий шаг принадлежат этому checkout.\n".utf8),
        по: живойПодузел.appending(path: "AGENTS.md")
      )
      let следующийШагПодузла = Data(
        "# Следующий шаг fork-подузла\n\nСостояние: ready.\nИдентификатор: fork-step-2.\n".utf8
      )
      try записать(
        следующийШагПодузла,
        по: живойПодузел.appending(path: "Планирование/следующий-шаг.md")
      )
      let очередьПодузла = ПаспортВосстановленияОчереди(
        версияСхемы: 1,
        идентификаторОчереди: "queue.specialized",
        идентификаторРепозитория: "repository.specialized",
        ссылкаВетки: подузел.liveRef,
        последовательностьЗавершённогоБилета: 1,
        следующаяПоследовательность: 2,
        состояние: "свободна",
        владелец: nil,
        ожидающиеБилеты: [],
        идентификаторСледующегоШага: "fork-step-2",
        путьСледующегоШага: "Планирование/следующий-шаг.md",
        отпечатокСледующегоШага: хеш(следующийШагПодузла),
        отпечатокПредыдущегоСостояния: хеш(Data("queue.specialized:0\n".utf8))
      )
      try записать(
        try очередьПодузла.каноническиеДанные(),
        по: живойПодузел.appending(path: "Планирование/состояние-очереди.json")
      )
      try записать(
        Data("Общее улучшение fork-подузла.\n".utf8),
        по: живойПодузел.appending(path: "Общее/улучшение.txt")
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        [
          "add", "--", "AGENTS.md", "Планирование/следующий-шаг.md",
          "Планирование/состояние-очереди.json", "Общее/улучшение.txt",
        ],
        в: живойПодузел
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["commit", "--quiet", "-m", "continue durable fork and prepare handoff"],
        в: живойПодузел
      )
      let новыйПодузел = try текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: живойПодузел)
      let прерываниеПодузла = try продвинутьСсылкуСПроверкойПрерывания(
        новыйКоммит: новыйПодузел,
        прежнийКоммит: прежнийПодузел,
        ссылка: подузел.liveRef,
        источник: живойПодузел,
        цель: репозиторийПодузла
      )

      let клонЯдра = корень.appending(path: "composition-core-integration")
      _ = try выполнитьКомандуКонтроляВерсий(
        ["clone", репозиторийЯдра.path, клонЯдра.path], в: корень)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["remote", "add", "fork", репозиторийПодузла.path], в: клонЯдра)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["fetch", "--no-tags", "fork", новыйПодузел], в: клонЯдра)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["merge", "--no-ff", "--no-edit", "FETCH_HEAD"],
        в: клонЯдра
      )
      let новоеЯдро = try текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: клонЯдра)
      let прерываниеПередачи = try продвинутьСсылкуСПроверкойПрерывания(
        новыйКоммит: новоеЯдро,
        прежнийКоммит: прежнееЯдро,
        ссылка: "refs/heads/main",
        источник: клонЯдра,
        цель: репозиторийЯдра
      )

      try записать(
        Data("# Правила проекта\n\nОчередь и следующий шаг принадлежат проекту.\n".utf8),
        по: живойПроект.appending(path: "AGENTS.md")
      )
      let следующийШагПроекта = Data(
        "# Следующий шаг проекта\n\nСостояние: ready.\nИдентификатор: project-step-2.\n".utf8
      )
      try записать(
        следующийШагПроекта,
        по: живойПроект.appending(path: "Планирование/следующий-шаг.md")
      )
      let очередьПроекта = ПаспортВосстановленияОчереди(
        версияСхемы: 1,
        идентификаторОчереди: "queue.project",
        идентификаторРепозитория: "repository.project",
        ссылкаВетки: проект.liveRef,
        последовательностьЗавершённогоБилета: 1,
        следующаяПоследовательность: 2,
        состояние: "свободна",
        владелец: nil,
        ожидающиеБилеты: [],
        идентификаторСледующегоШага: "project-step-2",
        путьСледующегоШага: "Планирование/следующий-шаг.md",
        отпечатокСледующегоШага: хеш(следующийШагПроекта),
        отпечатокПредыдущегоСостояния: хеш(Data("queue.project:0\n".utf8))
      )
      try записать(
        try очередьПроекта.каноническиеДанные(),
        по: живойПроект.appending(path: "Планирование/состояние-очереди.json")
      )
      try записать(
        Data("Проверенный результат проектного шага.\n".utf8),
        по: живойПроект.appending(path: "Результаты/шаг.txt")
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        [
          "add", "--", "AGENTS.md", "Планирование/следующий-шаг.md",
          "Планирование/состояние-очереди.json", "Результаты/шаг.txt",
        ],
        в: живойПроект
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["commit", "--quiet", "-m", "execute independent project step"],
        в: живойПроект
      )
      let новыйПроект = try текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: живойПроект)
      let прерываниеПроекта = try продвинутьСсылкуСПроверкойПрерывания(
        новыйКоммит: новыйПроект,
        прежнийКоммит: прежнийПроект,
        ссылка: проект.liveRef,
        источник: живойПроект,
        цель: репозиторийПроекта
      )

      let клонРодителя = корень.appending(path: "composition-parent-integration")
      _ = try выполнитьКомандуКонтроляВерсий(
        ["clone", репозиторийРодителя.path, клонРодителя.path], в: корень)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["update-index", "--cacheinfo", "160000,\(новыйПодузел),\(путьПодузла)"],
        в: клонРодителя
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["update-index", "--cacheinfo", "160000,\(новыйПроект),\(путьПроекта)"],
        в: клонРодителя
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["commit", "--quiet", "-m", "accept fork and project snapshots"],
        в: клонРодителя
      )
      let новыйРодитель = try текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: клонРодителя)
      let прерываниеРодителя = try продвинутьСсылкуСПроверкойПрерывания(
        новыйКоммит: новыйРодитель,
        прежнийКоммит: прежнийРодитель,
        ссылка: исходныйПаспорт.parentRepository.liveRef,
        источник: клонРодителя,
        цель: репозиторийРодителя
      )

      let свежийРодитель = корень.appending(path: "composition-parent-snapshot")
      _ = try выполнитьКомандуКонтроляВерсий(
        ["clone", "--no-checkout", репозиторийРодителя.path, свежийРодитель.path],
        в: корень
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["checkout", "--detach", новыйРодитель], в: свежийРодитель)
      _ = try выполнитьКомандуКонтроляВерсий(
        [
          "-c", "protocol.file.allow=always", "submodule", "update", "--init", "--",
          путьПодузла, путьПроекта,
        ],
        в: свежийРодитель
      )
      let снимокПодузла = свежийРодитель.appending(path: путьПодузла)
      let снимокПроекта = свежийРодитель.appending(path: путьПроекта)

      let свежийПодузел = корень.appending(path: "composition-fork-live")
      let свежийПроект = корень.appending(path: "composition-project-live")
      _ = try выполнитьКомандуКонтроляВерсий(
        ["clone", репозиторийПодузла.path, свежийПодузел.path], в: корень)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["switch", "--force-create", "specialized/main", "origin/specialized/main"],
        в: свежийПодузел
      )
      _ = try выполнитьКомандуКонтроляВерсий(
        ["clone", репозиторийПроекта.path, свежийПроект.path], в: корень)
      _ = try выполнитьКомандуКонтроляВерсий(
        ["switch", "--force-create", "project/main", "origin/project/main"],
        в: свежийПроект
      )
      let подузелБезСлужебныхСсылок = try текстКомандыКонтроляВерсий(
        ["for-each-ref", "--format=%(refname)", "refs/fum/"],
        в: свежийПодузел
      ).isEmpty
      let проектБезСлужебныхСсылок = try текстКомандыКонтроляВерсий(
        ["for-each-ref", "--format=%(refname)", "refs/fum/"],
        в: свежийПроект
      ).isEmpty
      let восстановленнаяОчередьПодузла = try восстановитьОчередь(
        в: свежийПодузел,
        голыйРепозиторий: репозиторийПодузла
      )
      let восстановленнаяОчередьПроекта = try восстановитьОчередь(
        в: свежийПроект,
        голыйРепозиторий: репозиторийПроекта
      )

      let паспорт = try данныеПаспортаКомпозиции(
        снимокРодителя: новыйРодитель,
        базовыйПодузел: базаПодузла,
        базовыйПроект: базаПроекта,
        живойПодузел: подузел.liveRef,
        живойПроект: проект.liveRef,
        путьПодузла: путьПодузла,
        путьПроекта: путьПроекта,
        снимокПодузла: новыйПодузел,
        снимокПроекта: новыйПроект
      )
      let контекст = RepositoryCompositionContext(
        gitExecutableURL: WritingSubnodeSystemRuntime.gitExecutableURL,
        bareRepositoriesByID: [
          "repository.parent": репозиторийРодителя,
          "repository.core": репозиторийЯдра,
          "repository.specialized": репозиторийПодузла,
          "repository.project": репозиторийПроекта,
        ],
        checkoutsByEntryID: [
          "entry.specialized": RepositoryCompositionCheckoutContext(
            snapshotURL: снимокПодузла,
            writerURL: свежийПодузел
          ),
          "entry.project": RepositoryCompositionCheckoutContext(
            snapshotURL: снимокПроекта,
            writerURL: свежийПроект
          ),
        ]
      )
      let отчёт = RepositoryCompositionPreflight.analyze(паспорт, context: контекст)
      let сервисныеСсылкиНеОпубликованы =
        try текстКомандыКонтроляВерсий(
          ["for-each-ref", "--format=%(refname)", "refs/fum/"],
          в: репозиторийПодузла
        ).isEmpty
        && текстКомандыКонтроляВерсий(
          ["for-each-ref", "--format=%(refname)", "refs/fum/"],
          в: репозиторийПроекта
        ).isEmpty
      let дочерниеРезультатыПереданы =
        try успешнаКомандаКонтроляВерсий(
          ["merge-base", "--is-ancestor", новыйПодузел, "refs/heads/main"],
          в: репозиторийЯдра
        )
        && отчёт.decision == .valid
      let свежиеКлоныВосстановлены =
        отчёт.decision == .valid
        && подузелБезСлужебныхСсылок
        && проектБезСлужебныхСсылок
        && сервисныеСсылкиНеОпубликованы
        && восстановленнаяОчередьПодузла.каноническоеСостояние
        && восстановленнаяОчередьПроекта.каноническоеСостояние
      let деревья = [
        "parent": try текстКомандыКонтроляВерсий(
          ["rev-parse", "\(новыйРодитель)^{tree}"], в: репозиторийРодителя),
        "core": try текстКомандыКонтроляВерсий(
          ["rev-parse", "\(новоеЯдро)^{tree}"], в: репозиторийЯдра),
        "fork": try текстКомандыКонтроляВерсий(
          ["rev-parse", "\(новыйПодузел)^{tree}"], в: репозиторийПодузла),
        "project": try текстКомандыКонтроляВерсий(
          ["rev-parse", "\(новыйПроект)^{tree}"], в: репозиторийПроекта),
      ]
      return ИтогКомпозиции(
        паспорт: паспорт,
        отчёт: отчёт,
        деревья: деревья,
        результатыПереданы: дочерниеРезультатыПереданы,
        свежиеКлоныВосстановлены: свежиеКлоныВосстановлены,
        прерыванияПередСравнениемИЗаменойАтомарны:
          прерываниеПодузла && прерываниеПередачи && прерываниеПроекта && прерываниеРодителя,
        точкиПрерыванийПередСравнениемИЗаменой: [
          прерываниеПодузла ? "fork" : nil,
          прерываниеПередачи ? "core" : nil,
          прерываниеПроекта ? "project" : nil,
          прерываниеРодителя ? "parent" : nil,
        ].compactMap { $0 }.sorted(),
        восстановленныеОчереди: [
          "fork": восстановленнаяОчередьПодузла,
          "project": восстановленнаяОчередьПроекта,
        ]
      )
    }
  }

  fileprivate func данныеПаспортаКомпозиции(
    снимокРодителя: String,
    базовыйПодузел: String,
    базовыйПроект: String,
    живойПодузел: String,
    живойПроект: String,
    путьПодузла: String,
    путьПроекта: String,
    снимокПодузла: String,
    снимокПроекта: String
  ) throws -> Data {
    let проверки = ["commit_exists", "live_ref_matches", "handoff_ready"]
    let передача: [String: Any] = [
      "target_repository_id": "repository.parent",
      "target_ref": "refs/heads/main",
      "required_check_ids": проверки,
    ]
    let объект: [String: Any] = [
      "schema_version": 1,
      "passport_id": "passport.repository-composition.end-to-end.v1",
      "composition_id": "fum.repository-composition.end-to-end.v1",
      "parent_repository": [
        "repository_id": "repository.parent",
        "repository_url": "urn:fum:repository:end-to-end-parent",
        "snapshot_oid": снимокРодителя,
        "live_ref": "refs/heads/main",
        "access_level": "public",
        "publication_boundary": "public",
      ],
      "children": [
        [
          "entry_id": "entry.specialized",
          "kind": "specialized_subnode",
          "node_id": "node.specialized.end-to-end",
          "repository_id": "repository.specialized",
          "repository_url": "urn:fum:repository:end-to-end-specialized",
          "upstream_repository_id": "repository.core",
          "base_oid": базовыйПодузел,
          "live_ref": живойПодузел,
          "submodule_path": путьПодузла,
          "gitlink_oid": снимокПодузла,
          "snapshot_mode": "detached_read_only",
          "writer_mode": "separate_clone",
          "nested_submodules": [],
          "access_level": "public",
          "publication_boundary": "public",
          "checks": проверки,
          "handoff": передача,
        ],
        [
          "entry_id": "entry.project",
          "kind": "project",
          "project_id": "project.independent.end-to-end",
          "repository_id": "repository.project",
          "repository_url": "urn:fum:repository:end-to-end-project",
          "base_oid": базовыйПроект,
          "live_ref": живойПроект,
          "submodule_path": путьПроекта,
          "gitlink_oid": снимокПроекта,
          "snapshot_mode": "detached_read_only",
          "writer_mode": "separate_clone",
          "nested_submodules": [],
          "access_level": "public",
          "publication_boundary": "public",
          "checks": проверки,
          "handoff": передача,
        ],
      ],
    ]
    return try JSONSerialization.data(
      withJSONObject: объект,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }

  fileprivate func продвинутьСсылкуСПроверкойПрерывания(
    новыйКоммит: String,
    прежнийКоммит: String,
    ссылка: String,
    источник: URL,
    цель: URL
  ) throws -> Bool {
    _ = try выполнитьКомандуКонтроляВерсий(
      [
        "fetch", "--quiet", "--no-tags", "--no-write-fetch-head", источник.path,
        новыйКоммит,
      ],
      в: цель
    )
    guard
      try успешнаКомандаКонтроляВерсий(
        ["cat-file", "-e", "\(новыйКоммит)^{commit}"],
        в: цель
      ),
      try текстКомандыКонтроляВерсий(["rev-parse", ссылка], в: цель) == прежнийКоммит
    else {
      return false
    }
    var прервано = false
    do {
      throw ОшибкаСквознойПриёмки.намеренноеПрерывание
    } catch ОшибкаСквознойПриёмки.намеренноеПрерывание {
      прервано = true
    }
    guard прервано,
      try текстКомандыКонтроляВерсий(["rev-parse", ссылка], в: цель) == прежнийКоммит,
      try успешнаКомандаКонтроляВерсий(
        ["cat-file", "-e", "\(новыйКоммит)^{commit}"],
        в: цель
      )
    else {
      return false
    }
    _ = try выполнитьКомандуКонтроляВерсий(
      ["update-ref", ссылка, новыйКоммит, прежнийКоммит],
      в: цель
    )
    return try текстКомандыКонтроляВерсий(["rev-parse", ссылка], в: цель) == новыйКоммит
  }

  fileprivate func восстановитьОчередь(
    в клон: URL,
    голыйРепозиторий: URL
  ) throws -> СвидетельствоВосстановленияОчереди {
    let адресСостояния = клон.appending(path: "Планирование/состояние-очереди.json")
    let данныеСостояния = try Data(contentsOf: адресСостояния)
    let паспорт = try JSONDecoder().decode(
      ПаспортВосстановленияОчереди.self,
      from: данныеСостояния
    )
    let адресСледующегоШага = клон.appending(path: паспорт.путьСледующегоШага)
    let следующийШаг = try Data(contentsOf: адресСледующегоШага)
    let текстСледующегоШага = String(decoding: следующийШаг, as: UTF8.self)
    let каноническиеДанныеСостояния = try паспорт.каноническиеДанные()
    let ссылкаВетки = try текстКомандыКонтроляВерсий(["symbolic-ref", "HEAD"], в: клон)
    let вершина = try текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: клон)
    let каноническоеСостояние =
      паспорт.версияСхемы == 1
      && паспорт.ссылкаВетки == ссылкаВетки
      && паспорт.следующаяПоследовательность
        == паспорт.последовательностьЗавершённогоБилета + 1
      && паспорт.состояние == "свободна"
      && паспорт.владелец == nil
      && паспорт.ожидающиеБилеты.isEmpty
      && паспорт.путьСледующегоШага == "Планирование/следующий-шаг.md"
      && паспорт.отпечатокСледующегоШага == хеш(следующийШаг)
      && паспорт.отпечатокПредыдущегоСостояния.hasPrefix("sha256:")
      && паспорт.отпечатокПредыдущегоСостояния.count == 71
      && текстСледующегоШага.contains("Состояние: ready.")
      && текстСледующегоШага.contains(
        "Идентификатор: \(паспорт.идентификаторСледующегоШага)."
      )
      && данныеСостояния == каноническиеДанныеСостояния
    guard каноническоеСостояние else {
      throw ОшибкаСквознойПриёмки.нарушение(
        "Свежий клон не восстановил каноническое состояние очереди."
      )
    }

    let основаниеСсылки = "refs/fum/worktree-task-queues/\(паспорт.идентификаторОчереди)"
    let ссылкаСостояния = "\(основаниеСсылки)/state"
    let ссылкаБилета = "\(основаниеСсылки)/tickets/\(паспорт.следующаяПоследовательность)"
    let нулевойОбъект = String(repeating: "0", count: 40)
    _ = try выполнитьКомандуКонтроляВерсий(
      ["update-ref", ссылкаСостояния, вершина, нулевойОбъект],
      в: клон
    )
    _ = try выполнитьКомандуКонтроляВерсий(
      ["update-ref", ссылкаБилета, вершина, нулевойОбъект],
      в: клон
    )
    let локальныеСсылки = try текстКомандыКонтроляВерсий(
      ["for-each-ref", "--format=%(refname)", основаниеСсылки],
      в: клон
    ).split(separator: "\n").map(String.init).sorted()
    let ожидаемыеСсылки = [ссылкаСостояния, ссылкаБилета].sorted()
    let служебныеСсылкиНеОпубликованы = try текстКомандыКонтроляВерсий(
      ["for-each-ref", "--format=%(refname)", "refs/fum/"],
      в: голыйРепозиторий
    ).isEmpty
    guard локальныеСсылки == ожидаемыеСсылки, служебныеСсылкиНеОпубликованы else {
      throw ОшибкаСквознойПриёмки.нарушение(
        "Восстановленная очередь не сохранила checkout-local границу."
      )
    }
    return СвидетельствоВосстановленияОчереди(
      идентификаторОчереди: паспорт.идентификаторОчереди,
      идентификаторРепозитория: паспорт.идентификаторРепозитория,
      ссылкаВетки: паспорт.ссылкаВетки,
      последовательностьЗавершённогоБилета: паспорт.последовательностьЗавершённогоБилета,
      последовательностьВосстановленногоБилета: паспорт.следующаяПоследовательность,
      отпечатокСледующегоШага: паспорт.отпечатокСледующегоШага,
      локальныеСлужебныеСсылки: локальныеСсылки,
      каноническоеСостояние: каноническоеСостояние,
      служебныеСсылкиНеОпубликованы: служебныеСсылкиНеОпубликованы
    )
  }
}

extension СтендСквознойПриёмки {
  fileprivate func хеш(_ данные: Data) -> String {
    "sha256:" + SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
  }

  fileprivate func записать(_ данные: Data, по адресу: URL) throws {
    try файловаяСистема.createDirectory(
      at: адресу.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try данные.write(to: адресу, options: .atomic)
  }

  fileprivate func снимокРепозитория(_ репозиторий: URL) throws -> String {
    try [
      текстКомандыКонтроляВерсий(["rev-parse", "HEAD"], в: репозиторий),
      текстКомандыКонтроляВерсий(
        ["status", "--porcelain=v2", "--branch", "--untracked-files=all"], в: репозиторий),
      текстКомандыКонтроляВерсий(
        ["for-each-ref", "--format=%(refname) %(objectname)"], в: репозиторий),
    ].joined(separator: "\n---\n")
  }

  @discardableResult
  fileprivate func выполнитьКомандуКонтроляВерсий(_ аргументы: [String], в каталог: URL) throws
    -> Data
  {
    let процесс = Process()
    процесс.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    процесс.arguments = аргументы
    процесс.currentDirectoryURL = каталог
    var окружение = [
      "GIT_CONFIG_NOSYSTEM": "1",
      "GIT_CONFIG_GLOBAL": WritingSubnodeSystemRuntime.nullDevicePath,
      "GIT_ATTR_NOSYSTEM": "1",
      "GIT_TERMINAL_PROMPT": "0",
      "GIT_OPTIONAL_LOCKS": "0",
      "GIT_AUTHOR_NAME": "FUM Acceptance",
      "GIT_AUTHOR_EMAIL": "acceptance@fum.invalid",
      "GIT_COMMITTER_NAME": "FUM Acceptance",
      "GIT_COMMITTER_EMAIL": "acceptance@fum.invalid",
      "GIT_AUTHOR_DATE": "2001-01-02T00:00:00Z",
      "GIT_COMMITTER_DATE": "2001-01-02T00:00:00Z",
      "LC_ALL": "C",
      "LANG": "C",
    ]
    if let путьИсполнения = ProcessInfo.processInfo.environment["PATH"] {
      окружение["PATH"] = путьИсполнения
    }
    if let временныйКаталог = ProcessInfo.processInfo.environment["TMPDIR"] {
      окружение["TMPDIR"] = временныйКаталог
    }
    процесс.environment = окружение
    let канал = Pipe()
    процесс.standardOutput = канал
    процесс.standardError = канал
    try процесс.run()
    try? канал.fileHandleForWriting.close()
    let данные = канал.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    try? канал.fileHandleForReading.close()
    guard процесс.terminationReason == .exit, процесс.terminationStatus == 0 else {
      let текст = String(decoding: данные, as: UTF8.self)
      throw ОшибкаСквознойПриёмки.командаКонтроляВерсий(
        аргументы,
        процесс.terminationStatus,
        текст.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }
    return данные
  }

  fileprivate func текстКомандыКонтроляВерсий(_ аргументы: [String], в каталог: URL) throws
    -> String
  {
    String(decoding: try выполнитьКомандуКонтроляВерсий(аргументы, в: каталог), as: UTF8.self)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  fileprivate func успешнаКомандаКонтроляВерсий(_ аргументы: [String], в каталог: URL) throws
    -> Bool
  {
    do {
      _ = try выполнитьКомандуКонтроляВерсий(аргументы, в: каталог)
      return true
    } catch ОшибкаСквознойПриёмки.командаКонтроляВерсий {
      return false
    }
  }
}
