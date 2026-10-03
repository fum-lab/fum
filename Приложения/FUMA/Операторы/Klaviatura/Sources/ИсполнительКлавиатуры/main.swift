import Foundation
import ЭталонКлавиатуры
import FUMStructuringOperatorMemory
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

func основная() throws {
  let аргументы = Array(CommandLine.arguments.dropFirst())
  guard аргументы.count % 2 == 0 else { throw CocoaError(.coderInvalidValue) }
  var параметры: [String: String] = [:]
  for номер in stride(from: 0, to: аргументы.count, by: 2) {
    let имя = аргументы[номер]
    guard ["--определение", "--вход", "--режим", "--повторы", "--выход"].contains(имя), параметры[имя] == nil else { throw CocoaError(.coderInvalidValue) }
    параметры[имя] = аргументы[номер + 1]
  }
  guard let путьВхода = параметры["--вход"] else { throw CocoaError(.coderInvalidValue) }
  let режим = параметры["--режим"] ?? "FUMA"
  guard ["FUMA", "эталон"].contains(режим), let повторы = Int(параметры["--повторы"] ?? "1"), (1...100).contains(повторы) else { throw CocoaError(.coderInvalidValue) }
  let началоРазбора = DispatchTime.now().uptimeNanoseconds
  let данныеВхода = try Data(contentsOf: URL(fileURLWithPath: путьВхода))
  guard let объект = try JSONSerialization.jsonObject(with: данныеВхода) as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
  if объект["входы"] != nil && !(объект["входы"] is [[String: Any]]) { throw CocoaError(.coderInvalidValue) }
  let входы = (объект["входы"] as? [[String: Any]]) ?? [объект]
  for вход in входы {
    guard Set(вход.keys) == Set(["клавиша", "фаза", "повтор", "модификаторы"]) else { throw CocoaError(.coderInvalidValue) }
  }
  let байты = try входы.map { try JSONSerialization.data(withJSONObject: $0, options: [.sortedKeys]) }
  let события = try байты.map { try JSONDecoder().decode(СобытиеКлавиатуры.self, from: $0) }
  for событие in события { try проверитьВход(событие) }
  let разборВходов = DispatchTime.now().uptimeNanoseconds - началоРазбора
  var определение: ОпределениеОператора?
  var разборОпределения: UInt64 = 0
  if режим == "FUMA" {
    guard let путь = параметры["--определение"] else { throw CocoaError(.coderInvalidValue) }
    let данные = try Data(contentsOf: URL(fileURLWithPath: путь))
    let начало = DispatchTime.now().uptimeNanoseconds
    определение = try ОпределениеОператора.разобрать(данные)
    разборОпределения = DispatchTime.now().uptimeNanoseconds - начало
  }
  // Прогрев исключён из внутреннего таймера; все последующие повторы исполняют одинаковые байты.
  if let первое = байты.first {
    if let определение { _ = try выполнитьПереход(определение, первое) }
    else { _ = try эталонныйПереход(события[0]) }
  }
  var выходы: [NSDictionary] = []
  var наблюдения: [НаблюдениеОператора] = []
  let началоПереходов = DispatchTime.now().uptimeNanoseconds
  for _ in 0..<повторы {
    выходы.removeAll(keepingCapacity: true)
    наблюдения.removeAll(keepingCapacity: true)
    for номер in входы.indices {
      if let определение {
        let наблюдение = try выполнитьПереход(определение, байты[номер])
        наблюдения.append(наблюдение)
        выходы.append(try разобратьРезультат(наблюдение))
      } else { выходы.append(try эталонныйПереход(события[номер])) }
    }
  }
  let переходы = DispatchTime.now().uptimeNanoseconds - началоПереходов
  var ресурсы = rusage()
  guard getrusage(RUSAGE_SELF, &ресурсы) == 0 else { throw CocoaError(.fileReadUnknown) }
  #if os(Linux)
  let память = Int64(ресурсы.ru_maxrss) * 1024
  #else
  let память = Int64(ресурсы.ru_maxrss)
  #endif
  var результат: [String: Any] = ["схема": "klaviatura.прогон.1", "режим": режим,
    "число_входов": входы.count, "повторы": повторы, "входы": входы, "выходы": выходы,
    "профиль": ["разбор_входов_нс": разборВходов, "разбор_определения_нс": разборОпределения, "переходы_нс": переходы, "пик_памяти_байты": память]]
  if режим == "FUMA" {
    результат["наблюдения"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(наблюдения))
  }
  let данные = try JSONSerialization.data(withJSONObject: результат, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) + Data([10])
  if let путь = параметры["--выход"] { try данные.write(to: URL(fileURLWithPath: путь), options: [.atomic]) }
  else { FileHandle.standardOutput.write(данные) }
}

do { try основная() }
catch {
  FileHandle.standardError.write(Data("Klaviatura: \(error)\n".utf8))
  exit(2)
}
