import Foundation
import Darwin
import CryptoKit
import FUMStructuringOperatorMemory
#if LINGUISTICKIT_ORACLE
@testable import LinguisticKit
#endif

enum ОтказПроверки: Error { case вход(String) }

func вывести(_ объект: Any) throws {
  let данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys])
  FileHandle.standardOutput.write(данные + Data([10]))
}

func главная() throws {
  let аргументы = Array(CommandLine.arguments.dropFirst())
  guard аргументы.count == 4 || аргументы.count == 5 else {
    throw ОтказПроверки.вход("Нужны режим FUMA|oracle, определение, JSON-массив строк входа, число повторов и необязательное слово профиль")
  }
  let режим = аргументы[0]
  guard ["FUMA", "oracle"].contains(режим), let повторы = Int(аргументы[3]),
    (1...1000).contains(повторы) else { throw ОтказПроверки.вход("Неверный режим или число повторов") }
  let толькоПрофиль = аргументы.count == 5 && аргументы[4] == "профиль"
  if аргументы.count == 5 && !толькоПрофиль { throw ОтказПроверки.вход("Неизвестный аргумент") }
  let байтыВходов = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
  guard let входы = try JSONSerialization.jsonObject(with: байтыВходов) as? [String],
    !входы.isEmpty, входы.count <= 40000 else { throw ОтказПроверки.вход("Нужен конечный непустой набор строк") }
  if режим == "oracle" {
    #if !LINGUISTICKIT_ORACLE
    try вывести(["состояние": "заблокировано", "основание": "Зарегистрированный checkout Зависимости/LinguisticKit не материализован"])
    exit(2)
    #endif
  }
  let началоРазбора = DispatchTime.now().uptimeNanoseconds
  let определение: ОпределениеОператора? = режим == "FUMA"
    ? try ОпределениеОператора.разобрать(Data(contentsOf: URL(fileURLWithPath: аргументы[1]))) : nil
  let разбор = DispatchTime.now().uptimeNanoseconds - началоРазбора
  var результаты: [[String: Any]] = []
  var холодный: UInt64 = 0
  var повторные: [UInt64] = []
  var хэшиРаундов: [String] = []
  for повтор in 0..<повторы {
    var результатыРаунда: [[String: Any]] = []
    let начало = DispatchTime.now().uptimeNanoseconds
    for текст in входы {
      var запись: [String: Any]
      do {
        if let определение {
          let наблюдение = try AutomationExecutor.выполнить(
            определение, вход: .текст(текст), пределы: ПределыИсполнения())
          запись = ["наблюдение": try JSONSerialization.jsonObject(with: каноническиеДанные(наблюдение))]
        } else {
          #if LINGUISTICKIT_ORACLE
          guard let объект = try JSONSerialization.jsonObject(with: Data(текст.utf8)) as? [String: Any],
            Set(объект.keys) == Set(["буква", "слева", "справа"]),
            let буква = объект["буква"] as? String else { throw ОтказПроверки.вход("Форма oracle-входа") }
          let алфавит = Set("абвгдеёжзийклмнопрстуфхцчшщъыьэюя".unicodeScalars)
          func символ(_ значение: Any?) throws -> String {
            if значение is NSNull { return "" }
            guard let строка = значение as? String, строка.unicodeScalars.count == 1,
              let скаляр = строка.unicodeScalars.first, алфавит.contains(скаляр)
            else { throw ОтказПроверки.вход("Символ вне конечного домена oracle") }
            return строка
          }
          let цель = try символ(буква)
          guard !цель.isEmpty else { throw ОтказПроверки.вход("Пустая цель oracle") }
          guard let результат = ScriptTable.ru.element(
            of: .Latn, from: цель, of: .Cyrl,
            prefixElement: try символ(объект["слева"]), postfixString: try символ(объект["справа"]))
          else { throw ОтказПроверки.вход("Oracle не выбрал ячейку") }
          запись = ["результат": результат]
          #else
          throw ОтказПроверки.вход("Oracle недоступен")
          #endif
        }
      } catch let ошибка as ОшибкаИсполнения {
        if толькоПрофиль { throw ошибка }
        запись = ["ошибка": ошибка.код]
      }
      результатыРаунда.append(запись)
    }
    let длительность = DispatchTime.now().uptimeNanoseconds - начало
    let контрольныеБайты = try JSONSerialization.data(
      withJSONObject: результатыРаунда, options: [.sortedKeys])
    хэшиРаундов.append(SHA256.hash(data: контрольныеБайты).map { String(format: "%02x", $0) }.joined())
    if повтор == 0 { результаты = результатыРаунда }
    if повтор == 0 { холодный = длительность } else { повторные.append(длительность) }
  }
  var память = rusage()
  guard getrusage(RUSAGE_SELF, &память) == 0 else { throw ОтказПроверки.вход("Нет измерения памяти") }
  try вывести([
    "схема": "fum.linguistickit.наблюдение-harness.1", "режим": режим,
    "результаты": результаты, "входов": входы.count, "повторов": повторы,
    "разбор-определения-нс": режим == "FUMA" ? разбор as Any : NSNull(),
    "первый-набор-нс": холодный, "повторные-наборы-нс": повторные,
    "sha256-результатов-раундов": хэшиРаундов,
    "максимальная-память-процесса-байт": память.ru_maxrss,
    "граница": "Монотонные замеры набора включают исполнение, трассу и сериализацию наблюдения. Максимальная RSS охватывает целый отдельный процесс; подготовка входов и загрузка определения вне исполнения. Oracle не раскрывает внутренний разбор и кэширование."
  ])
}

do { try главная() }
catch let ошибка {
  FileHandle.standardError.write(Data("Отказ предметного harness: \(ошибка)\n".utf8))
  exit(1)
}
