@_silgen_name("exit") func выход(_ код: Int32) -> Never
enum Ошибка: Error { case вход, схема, тип, диапазон, переполнение, операция }
indirect enum Значение { case число(Int64), строка(String), массив([Значение]), объект([String: Значение]) }
struct Разбор {
  let символы: [Character]; var индекс = 0
  init(_ текст: String) { символы = Array(текст) }
  mutating func пробелы() { while индекс < символы.count && " \n\r\t".contains(символы[индекс]) { индекс += 1 } }
  mutating func взять(_ с: Character) throws { пробелы(); guard индекс < символы.count && символы[индекс] == с else { throw Ошибка.вход }; индекс += 1 }
  mutating func значение(_ глубина: Int = 0) throws -> Значение {
    guard глубина <= 16 else { throw Ошибка.вход }; пробелы(); guard индекс < символы.count else { throw Ошибка.вход }
    let с = символы[индекс]
    if с == "\"" { return .строка(try строка()) }
    if с == "[" {
      индекс += 1; пробелы(); var а = [Значение]()
      if индекс < символы.count && символы[индекс] == "]" { индекс += 1; return .массив(а) }
      while true { guard а.count < 64 else { throw Ошибка.вход }; а.append(try значение(глубина + 1)); пробелы(); guard индекс < символы.count else { throw Ошибка.вход }; if символы[индекс] == "]" { индекс += 1; return .массив(а) }; try взять(",") }
    }
    if с == "{" {
      индекс += 1; пробелы(); var о = [String: Значение]()
      if индекс < символы.count && символы[индекс] == "}" { индекс += 1; return .объект(о) }
      while true { guard о.count < 64 else { throw Ошибка.вход }; let к = try строка(); try взять(":"); let в = try значение(глубина + 1); guard о.updateValue(в, forKey: к) == nil else { throw Ошибка.вход }; пробелы(); guard индекс < символы.count else { throw Ошибка.вход }; if символы[индекс] == "}" { индекс += 1; return .объект(о) }; try взять(",") }
    }
    let начало = индекс; if с == "-" { индекс += 1 }; while индекс < символы.count && символы[индекс].isASCII && символы[индекс].isNumber { индекс += 1 }; guard индекс > начало, let числоРезультат = Int64(String(символы[начало..<индекс])) else { throw Ошибка.тип }; return .число(числоРезультат)
  }
  mutating func строка() throws -> String { try взять("\""); var с = ""; while индекс < символы.count { let ч = символы[индекс]; индекс += 1; if ч == "\"" { return с }; guard ч != "\\" && ч != "\n" && ч != "\r" else { throw Ошибка.вход }; с.append(ч) }; throw Ошибка.вход }
  mutating func весь() throws -> Значение { let в = try значение(); пробелы(); guard индекс == символы.count else { throw Ошибка.вход }; return в }
}
func объект(_ узел: Значение) throws -> [String: Значение] { guard case let .объект(значение) = узел else { throw Ошибка.тип }; return значение }
func поле(_ узел: Значение, _ ключ: String) throws -> Значение { guard let значение = try объект(узел)[ключ] else { throw Ошибка.схема }; return значение }
func текст(_ узел: Значение) throws -> String { guard case let .строка(значение) = узел else { throw Ошибка.тип }; return значение }
func число(_ узел: Значение) throws -> Int64 { guard case let .число(значение) = узел else { throw Ошибка.тип }; return значение }
func вычислить(_ узел: Значение, _ вход: Значение, _ глубина: Int = 0) throws -> Значение {
 guard глубина <= 16, case let .массив(аргументы) = узел, !аргументы.isEmpty else { throw Ошибка.схема }
 switch try текст(аргументы[0]) {
 case "переменная": guard аргументы.count == 2, try текст(аргументы[1]) == "вход" else { throw Ошибка.схема }; return вход
 case "путь": guard аргументы.count == 3 else { throw Ошибка.схема }; return try поле(вычислить(аргументы[1], вход, глубина + 1), текст(аргументы[2]))
 case "потребовать-диапазон": guard аргументы.count == 4 else { throw Ошибка.схема }; let значение = try число(вычислить(аргументы[1], вход, глубина + 1)); let нижняя = try число(аргументы[2]); let верхняя = try число(аргументы[3]); guard нижняя <= значение && значение <= верхняя else { throw Ошибка.диапазон }; return .число(значение)
 case "сложить": guard аргументы.count == 3 else { throw Ошибка.схема }; let левое = try число(вычислить(аргументы[1], вход, глубина + 1)); let правое = try число(вычислить(аргументы[2], вход, глубина + 1)); let (числоРезультат, ошибка) = левое.addingReportingOverflow(правое); guard !ошибка else { throw Ошибка.переполнение }; return .число(числоРезультат)
 default: throw Ошибка.операция
 }
}
do {
 guard CommandLine.arguments.count == 3, CommandLine.arguments[1].utf8.count <= 65536, CommandLine.arguments[2].utf8.count <= 262144 else { throw Ошибка.вход }
 var п = Разбор(CommandLine.arguments[1]); var в = Разбор(CommandLine.arguments[2]); let программа = try п.весь(); let вход = try в.весь()
 guard try текст(поле(программа,"схема")) == "fum.определение-оператора.2", case let .массив(шаги) = try поле(программа,"шаги"), шаги.count == 1, try текст(поле(шаги[0],"оператор")) == "вычислить-JSON" else { throw Ошибка.схема }
 let граф = try поле(поле(шаги[0],"аргументы"),"граф"); guard try текст(поле(граф,"схема")) == "fuma.граф-JSON.2", try текст(поле(граф,"числа")) == "целые64-без-дробей", case let .массив(переменные) = try поле(граф,"переменные"), переменные.isEmpty else { throw Ошибка.схема }
 print(try число(вычислить(поле(граф,"результат"), вход)))
} catch { print("ОТКАЗ"); выход(1) }
