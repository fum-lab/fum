import Foundation

// Вспомогательная проверка внешнего вклада; не часть рантайма FUMA.
private struct ОтказПоставки: Error, CustomStringConvertible {
  let description: String
}

private func потребовать(_ условие: Bool, _ сообщение: String) throws {
  guard условие else { throw ОтказПоставки(description: сообщение) }
}

private func прочитать(_ путь: String, предел: Int = 2_097_152) throws -> Data {
  let свойства = try FileManager.default.attributesOfItem(atPath: путь)
  try потребовать(свойства[.type] as? FileAttributeType == .typeRegular,
    "Ожидался обычный файл, не ссылка: \(URL(fileURLWithPath: путь).lastPathComponent)")
  guard let размер = свойства[.size] as? NSNumber else {
    throw ОтказПоставки(description: "Неизвестный размер файла")
  }
  try потребовать(размер.intValue <= предел, "Слишком большой проверочный файл")
  let данные = try Data(contentsOf: URL(fileURLWithPath: путь))
  try потребовать(данные.count <= предел, "Файл вырос во время чтения")
  return данные
}

private func хэш(_ данные: Data, команда: [String]) throws -> String {
  let процесс = Process()
  let вход = Pipe()
  let выход = Pipe()
  процесс.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  процесс.arguments = команда
  процесс.standardInput = вход
  процесс.standardOutput = выход
  процесс.standardError = FileHandle.standardError
  try процесс.run()
  try вход.fileHandleForWriting.write(contentsOf: данные)
  try вход.fileHandleForWriting.close()
  let ответ = выход.fileHandleForReading.readDataToEndOfFile()
  процесс.waitUntilExit()
  try потребовать(процесс.terminationStatus == 0, "Команда проверки хэша завершилась ошибкой")
  try потребовать(ответ.count < 4096, "Неожиданный ответ команды проверки хэша")
  return String(decoding: ответ, as: UTF8.self).split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
}

private struct ФайлМанифеста: Decodable {
  let путь: String
  let байты: Int
  let хэшСодержимого: String
  let объект: String
  private enum CodingKeys: String, CodingKey {
    case путь = "path", байты = "bytes", хэшСодержимого = "sha256", объект = "git_blob"
  }
}

private struct Манифест: Decodable {
  let файлы: [ФайлМанифеста]
  private enum CodingKeys: String, CodingKey { case файлы = "files" }
}

private func проверитьМанифест(_ каталог: String) throws {
  let корень = URL(fileURLWithPath: каталог, isDirectory: true)
  let манифест = try JSONDecoder().decode(Манифест.self,
    from: прочитать(корень.appendingPathComponent("manifest.json").path))
  try потребовать(!манифест.файлы.isEmpty && манифест.файлы.count <= 256, "Неверный состав манифеста")
  var имена = Set<String>()
  for файл in манифест.файлы {
    try потребовать(файл.путь != "manifest.json" && !файл.путь.isEmpty &&
      файл.путь != "." && файл.путь != ".." &&
      файл.путь.utf8.allSatisfy { (48...57).contains($0) || (65...90).contains($0) ||
        (97...122).contains($0) || [45, 46, 95].contains($0) }, "Недопустимое имя в манифесте")
    try потребовать(имена.insert(файл.путь).inserted, "Повтор файла в манифесте")
    let данные = try прочитать(корень.appendingPathComponent(файл.путь).path)
    try потребовать(данные.count == файл.байты, "Размер не совпал: \(файл.путь)")
    try потребовать(try хэш(данные, команда: ["shasum", "-a", "256"]) == файл.хэшСодержимого,
      "SHA-256 не совпал: \(файл.путь)")
    try потребовать(try хэш(данные, команда: ["git", "hash-object", "--stdin"]) == файл.объект,
      "Git blob не совпал: \(файл.путь)")
  }
  let наличие = Set(try FileManager.default.contentsOfDirectory(atPath: каталог))
  try потребовать(наличие == имена.union(["manifest.json"]), "Неполный или лишний состав каталога")
  print("PASS_PACKAGE_FILES=\(имена.count)")
}

private struct Ожидания: Decodable {
  let схема: String
  let тесты: [String]
}

private struct СодержимоеСобытия: Decodable {
  let вид: String
  let идентификатор: String?
  let имя: String?
  let тест: String?
  let параметризован: Bool?
  private enum CodingKeys: String, CodingKey {
    case вид = "kind", идентификатор = "id", имя = "name", тест = "testID"
    case параметризован = "isParameterized"
  }
}

private struct ЗаписьСобытия: Decodable {
  let версия: Int
  let вид: String
  let содержимое: СодержимоеСобытия
  private enum CodingKeys: String, CodingKey {
    case версия = "version", вид = "kind", содержимое = "payload"
  }
}

private struct ИтогПроверок: Encodable {
  let схема = "fum.результат-внешних-проверок.1"
  let версияСобытий = 0
  let пройдено: Int
  let тесты: [String]
  let корневаяПриёмка = false
}

private func проверитьСобытия(_ данные: Data, ожидаемые: [String]) throws -> ИтогПроверок {
  try потребовать(!ожидаемые.isEmpty && Set(ожидаемые).count == ожидаемые.count, "Пустой или повторный список ожидаемых тестов")
  try потребовать(!данные.isEmpty && данные.last == 10, "Поток событий пуст или оборван")
  var функции: [String: String] = [:]
  var определения = Set<String>()
  var начатые = Set<String>()
  var завершённые = Set<String>()
  var запускНачат = false
  var запускЗавершён = false
  for строка in данные.split(separator: 10, omittingEmptySubsequences: false).dropLast() {
    try потребовать(!строка.isEmpty && строка.count <= 65_536, "Некорректная строка событий")
    let запись = try JSONDecoder().decode(ЗаписьСобытия.self, from: Data(строка))
    try потребовать(запись.версия == 0, "Неподдержанная версия событий Swift Testing")
    let событие = запись.содержимое
    switch запись.вид {
    case "test":
      try потребовать(!запускНачат, "Объявление теста после начала запуска")
      guard let идентификатор = событие.идентификатор else { throw ОтказПоставки(description: "Тест без ID") }
      try потребовать(определения.insert(идентификатор).inserted, "Повтор объявления теста")
      if событие.вид == "function" {
        guard let имя = событие.имя, событие.параметризован == false else {
          throw ОтказПоставки(description: "Неподдержанный профиль теста")
        }
        функции[идентификатор] = имя
      } else {
        try потребовать(событие.вид == "suite", "Неизвестное объявление теста")
      }
    case "event":
      try потребовать(!запускЗавершён, "Событие после завершения запуска")
      switch событие.вид {
      case "runStarted":
        try потребовать(!запускНачат, "Повтор начала запуска")
        запускНачат = true
      case "runEnded":
        try потребовать(запускНачат, "Конец запуска без начала")
        запускЗавершён = true
      case "testStarted":
        guard запускНачат, let идентификатор = событие.тест,
          определения.contains(идентификатор), начатые.insert(идентификатор).inserted
        else { throw ОтказПоставки(description: "Неизвестный или повторно начатый тест") }
      case "testEnded":
        guard запускНачат, let идентификатор = событие.тест,
          начатые.contains(идентификатор), завершённые.insert(идентификатор).inserted
        else { throw ОтказПоставки(description: "Неизвестный, не начатый или повторно завершённый тест") }
      default:
        // В частности, issueRecorded и testSkipped не считаются успешной проверкой.
        throw ОтказПоставки(description: "Непринимаемое событие: \(событие.вид)")
      }
    default:
      throw ОтказПоставки(description: "Неизвестная запись событий")
    }
  }
  try потребовать(запускНачат && запускЗавершён, "Нет завершённого запуска")
  try потребовать(Set(функции.values) == Set(ожидаемые) && функции.count == ожидаемые.count,
    "Фактический набор тестов не совпал с ожидаемым")
  try потребовать(начатые == определения && завершённые == определения,
    "Не все объявленные проверки начаты и завершены")
  return ИтогПроверок(пройдено: функции.count, тесты: ожидаемые)
}

private func самопроверка() throws {
  let объявление = #"{"version":0,"kind":"test","payload":{"kind":"function","id":"a","name":"пример()","isParameterized":false}}"#
  let начало = #"{"version":0,"kind":"event","payload":{"kind":"runStarted"}}"#
  let тестНачат = #"{"version":0,"kind":"event","payload":{"kind":"testStarted","testID":"a"}}"#
  let тестЗавершён = #"{"version":0,"kind":"event","payload":{"kind":"testEnded","testID":"a"}}"#
  let конец = #"{"version":0,"kind":"event","payload":{"kind":"runEnded"}}"#
  let строки = [объявление, начало, тестНачат, тестЗавершён, конец]
  func поток(_ строки: [String]) -> Data { Data((строки.joined(separator: "\n") + "\n").utf8) }
  _ = try проверитьСобытия(поток(строки), ожидаемые: ["пример()"])
  let отказы: [Data] = [
    Data(), поток([начало, конец]), поток(Array(строки.dropLast())),
    поток([объявление, начало, тестЗавершён, конец]),
    поток([объявление, начало, тестНачат, тестЗавершён, тестЗавершён, конец]),
    поток([объявление, начало, тестНачат, #"{"version":0,"kind":"event","payload":{"kind":"issueRecorded"}}"#, тестЗавершён, конец]),
    поток([объявление, начало, #"{"version":0,"kind":"event","payload":{"kind":"testSkipped","testID":"a"}}"#, конец]),
    поток(строки.map { $0.replacingOccurrences(of: "\"version\":0", with: "\"version\":1") }),
    Data(поток(строки).dropLast()),
    поток([объявление, начало, тестНачат, тестЗавершён, конец, конец]),
    поток([объявление.replacingOccurrences(of: "пример()", with: "чужой()"), начало, тестНачат, тестЗавершён, конец])
  ]
  for вход in отказы {
    var отклонён = false
    do { _ = try проверитьСобытия(вход, ожидаемые: ["пример()"]) } catch { отклонён = true }
    try потребовать(отклонён, "Самопроверка пропустила неверное свидетельство")
  }
  print("PASS_EVIDENCE_GUARD_NEGATIVES=\(отказы.count)")
}

@main
struct ПроверкаПоставки {
  static func main() {
    do {
      let аргументы = Array(CommandLine.arguments.dropFirst())
      switch аргументы.first {
      case "манифест" where аргументы.count == 2:
        try проверитьМанифест(аргументы[1])
      case "события" where аргументы.count == 4:
        let ожидания = try JSONDecoder().decode(Ожидания.self, from: прочитать(аргументы[2]))
        try потребовать(ожидания.схема == "fum.проверка-внешней-поставки.1", "Неизвестная схема ожиданий")
        let итог = try проверитьСобытия(прочитать(аргументы[1]), ожидаемые: ожидания.тесты)
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(итог)
        данные.append(10)
        try данные.write(to: URL(fileURLWithPath: аргументы[3]), options: .withoutOverwriting)
        print("PASS_SWIFT_TESTING=\(итог.пройдено)")
      case "самопроверка" where аргументы.count == 1:
        try самопроверка()
      default:
        throw ОтказПоставки(description: "Ожидались: манифест КАТАЛОГ; события JSONL ОЖИДАНИЯ ИТОГ; самопроверка")
      }
    } catch {
      try? FileHandle.standardError.write(contentsOf: Data("ОТКАЗ: \(error)\n".utf8))
      exit(1)
    }
  }
}
