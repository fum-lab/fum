import Foundation

// Только файловый транспорт и независимая проверка; генерация исходника задаётся JSON-графом.
@main
struct СквознаяПроверка {
  static func main() throws {
    guard CommandLine.arguments.count == 5 else {
      throw NSError(domain: "FUMA-проверка", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Нужны граф.json корпус.json вывод.swift эталон.bin"])
    }
    let пути = CommandLine.arguments
    var разбор = try РазборОпределения(Data(contentsOf: URL(fileURLWithPath: пути[1])))
    let программа = try ГрафJSON(разбор.разобрать())
    let данные = try Data(contentsOf: URL(fileURLWithPath: пути[2]))
    guard let текст = String(data: данные, encoding: .utf8) else {
      throw NSError(domain: "FUMA-проверка", code: 3)
    }
    var операций = 0
    let результат = try программа.вычислить(текст, пределБайтов: 262_144) {
      операций += 1
      guard операций <= 10_000_000 else {
        throw ОшибкаИсполнения("предел-операций", "Исчерпан бюджет проверочного запуска")
      }
    }
    let исходник = try JSONDecoder().decode(String.self, from: Data(результат.utf8))
    try Data(исходник.utf8).write(to: URL(fileURLWithPath: пути[3]), options: .withoutOverwriting)

    // Эталон строится из исходных входов, не из результата оператора или сгенерированного текста.
    let входы = try JSONDecoder().decode([String].self, from: данные)
    var эталон = Data()
    for вход in входы {
      let байты = Data(вход.utf8)
      эталон.append(Data("\(байты.count)\n".utf8))
      эталон.append(байты)
    }
    try эталон.write(to: URL(fileURLWithPath: пути[4]), options: .withoutOverwriting)
    print("PASS graph_generated_source_cases=\(входы.count)")
    print("SOURCE_BYTES \(исходник.utf8.count)")
    print("EXPECTED_BYTES \(эталон.count)")
    print("GRAPH_OPERATIONS \(операций)")
  }
}
