import Foundation

private enum ОшибкаСканирования: Error {
  case кореньНеЯвляетсяОбычнымКаталогом(URL)
}

private struct НайденныйДокумент {
  let относительныйПуть: String
  let название: String
  let числоСсылок: Int
}

private struct ОграждениеКода {
  let знак: Character
  let длина: Int
}

private let выраженияСсылок = [
  #"(?<!"# + #"\"# + #"\"# + #")\[\[[^\]\r\n]+\]\]"#,
  #"(?<!!)(?<!"# + #"\"# + #"\"# + #")\[[^\]\r\n]+\]\([^\)\r\n]+\)"#,
  #"(?<!!)(?<!"# + #"\"# + #"\"# + #")\[[^\]\r\n]+\]\[[^\]\r\n]*\]"#,
  #"<(?:https?://|mailto:)[^>\r\n]+>"#,
].compactMap { try? NSRegularExpression(pattern: $0) }

public struct СканерРепозитория: Sendable {
  public init() {}

  public func сканировать(корень: URL) throws -> СнимокДерева {
    let корневаяСсылка = корень.standardizedFileURL
    let файловаяСистема = FileManager.default
    let атрибутыКорня = try файловаяСистема.attributesOfItem(atPath: корневаяСсылка.path)

    guard атрибутыКорня[.type] as? FileAttributeType == .typeDirectory else {
      throw ОшибкаСканирования.кореньНеЯвляетсяОбычнымКаталогом(корневаяСсылка)
    }

    var документы: [НайденныйДокумент] = []
    var пропущенныеПути: [String] = []
    try обойти(
      каталог: корневаяСсылка,
      относительныеКомпоненты: [],
      файловаяСистема: файловаяСистема,
      документы: &документы,
      пропущенныеПути: &пропущенныеПути
    )

    документы.sort {
      предшествуетПуть($0.относительныйПуть, $1.относительныйПуть)
    }

    var путиКаталогов = Set<String>()
    for документ in документы {
      let компоненты = документ.относительныйПуть.split(separator: "/").map(String.init)
      guard компоненты.count > 1 else { continue }

      for длина in 1..<компоненты.count {
        путиКаталогов.insert(компоненты.prefix(длина).joined(separator: "/"))
      }
    }

    let отсортированныеКаталоги = путиКаталогов.sorted(by: предшествуетПуть)
    var узлы: [УзелДерева] = [
      УзелДерева(
        идентификатор: ".",
        название: корневаяСсылка.lastPathComponent,
        относительныйПуть: ".",
        родитель: nil,
        вид: .корень,
        глубина: 0,
        числоСсылок: 0
      )
    ]

    узлы.append(
      contentsOf: отсортированныеКаталоги.map { путь in
        УзелДерева(
          идентификатор: путь,
          название: путь.split(separator: "/").last.map(String.init) ?? путь,
          относительныйПуть: путь,
          родитель: родительскийПуть(для: путь),
          вид: .каталог,
          глубина: глубинаПути(путь),
          числоСсылок: 0
        )
      })

    узлы.append(
      contentsOf: документы.map { документ in
        УзелДерева(
          идентификатор: документ.относительныйПуть,
          название: документ.название,
          относительныйПуть: документ.относительныйПуть,
          родитель: родительскийПуть(для: документ.относительныйПуть),
          вид: .документ,
          глубина: глубинаПути(документ.относительныйПуть),
          числоСсылок: документ.числоСсылок
        )
      })

    узлы.sort {
      if $0.id == "." { return $1.id != "." }
      if $1.id == "." { return false }
      return предшествуетПуть($0.относительныйПуть, $1.относительныйПуть)
    }

    return СнимокДерева(
      корень: корневаяСсылка,
      узлы: узлы,
      числоДокументов: документы.count,
      пропущенныеПути: пропущенныеПути
    )
  }
}

private func обойти(
  каталог: URL,
  относительныеКомпоненты: [String],
  файловаяСистема: FileManager,
  документы: inout [НайденныйДокумент],
  пропущенныеПути: inout [String]
) throws {
  let содержимое = try файловаяСистема.contentsOfDirectory(
    at: каталог,
    includingPropertiesForKeys: nil,
    options: []
  ).sorted {
    предшествуетПуть($0.lastPathComponent, $1.lastPathComponent)
  }

  for ссылка in содержимое {
    let имя = ссылка.lastPathComponent
    let компонентыПути = относительныеКомпоненты + [имя]
    let путь = компонентыПути.joined(separator: "/")
    guard let атрибуты = try? файловаяСистема.attributesOfItem(atPath: ссылка.path) else {
      пропущенныеПути.append(путь)
      continue
    }
    let тип = атрибуты[.type] as? FileAttributeType

    if тип == .typeSymbolicLink {
      continue
    }

    if тип == .typeDirectory {
      if исключёнКаталог(
        имя: имя,
        находитсяВКорне: относительныеКомпоненты.isEmpty
      ) {
        continue
      }

      if содержитМаркерРепозитория(каталог: ссылка, файловаяСистема: файловаяСистема) {
        continue
      }

      do {
        try обойти(
          каталог: ссылка,
          относительныеКомпоненты: компонентыПути,
          файловаяСистема: файловаяСистема,
          документы: &документы,
          пропущенныеПути: &пропущенныеПути
        )
      } catch {
        пропущенныеПути.append(путь)
      }
      continue
    }

    guard тип == .typeRegular, ссылка.pathExtension.lowercased() == "md" else {
      continue
    }

    guard let данные = try? Data(contentsOf: ссылка, options: [.mappedIfSafe]) else {
      пропущенныеПути.append(путь)
      continue
    }
    let текст = String(decoding: данные, as: UTF8.self)
    let строки = содержательныеСтроки(текста: текст)
    let название =
      первыйЗаголовок(в: строки)
      ?? ссылка.deletingPathExtension().lastPathComponent

    документы.append(
      НайденныйДокумент(
        относительныйПуть: путь,
        название: название,
        числоСсылок: подсчитатьСсылки(в: строки.joined(separator: "\n"))
      )
    )
  }
}

private func исключёнКаталог(имя: String, находитсяВКорне: Bool) -> Bool {
  if находитсяВКорне, имя == "Подузлы" {
    return true
  }

  let нормализованноеИмя = имя.lowercased()
  let точныеИсключения: Set<String> = [
    ".git",
    ".build",
    ".swiftpm",
    ".cache",
    ".caches",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "__pycache__",
    "cache",
    "caches",
    "deriveddata",
    "кэш",
    "кэши",
  ]

  return точныеИсключения.contains(нормализованноеИмя)
    || нормализованноеИмя.hasSuffix(".cache")
    || нормализованноеИмя.hasSuffix("_cache")
}

private func содержитМаркерРепозитория(каталог: URL, файловаяСистема: FileManager) -> Bool {
  guard let имена = try? файловаяСистема.contentsOfDirectory(atPath: каталог.path) else {
    return false
  }
  return имена.contains(".git")
}

private func содержательныеСтроки(текста: String) -> [String] {
  var результат: [String] = []
  var внутриБлокаСвежести = false
  var внутриКомментария = false
  var ограждение: ОграждениеКода?

  for исходнаяСтрока in текста.split(separator: "\n", omittingEmptySubsequences: false) {
    let строка = String(исходнаяСтрока)
    let строкаДляМаркера = строка.trimmingCharacters(in: .whitespaces)

    if строкаДляМаркера.contains("<!-- FUM-MD-RECENCY:BEGIN -->") {
      внутриБлокаСвежести = true
      continue
    }
    if строкаДляМаркера.contains("<!-- FUM-MD-RECENCY:END -->") {
      внутриБлокаСвежести = false
      continue
    }
    if внутриБлокаСвежести {
      continue
    }

    let безКомментариев = удалитьКомментарииРазметки(
      из: строка,
      внутриКомментария: &внутриКомментария
    )

    if let текущееОграждение = ограждение {
      if закрываетОграждение(безКомментариев, ограждение: текущееОграждение) {
        ограждение = nil
      }
      continue
    }

    if let новоеОграждение = открывающееОграждение(безКомментариев) {
      ограждение = новоеОграждение
      continue
    }

    guard !являетсяОтступнымКодом(безКомментариев) else {
      continue
    }
    результат.append(удалитьВстроенныйКод(из: безКомментариев))
  }

  return результат
}

private func открывающееОграждение(_ строка: String) -> ОграждениеКода? {
  guard let начало = началоПослеДопустимогоОтступа(в: строка) else {
    return nil
  }
  guard начало < строка.endIndex else { return nil }
  let знак = строка[начало]
  guard знак == "`" || знак.asciiValue == 126 else { return nil }

  let длина = длинаСерии(знака: знак, от: начало, в: строка)
  return длина >= 3 ? ОграждениеКода(знак: знак, длина: длина) : nil
}

private func закрываетОграждение(
  _ строка: String,
  ограждение: ОграждениеКода
) -> Bool {
  guard let начало = началоПослеДопустимогоОтступа(в: строка) else {
    return false
  }
  let длина = длинаСерии(знака: ограждение.знак, от: начало, в: строка)
  guard длина >= ограждение.длина else { return false }
  let конец = строка.index(начало, offsetBy: длина)
  return строка[конец...].allSatisfy(\.isWhitespace)
}

private func началоПослеДопустимогоОтступа(в строка: String) -> String.Index? {
  var индекс = строка.startIndex
  var числоПробелов = 0
  while индекс < строка.endIndex, строка[индекс] == " " {
    числоПробелов += 1
    guard числоПробелов <= 3 else { return nil }
    индекс = строка.index(after: индекс)
  }
  guard индекс == строка.endIndex || строка[индекс] != "\t" else { return nil }
  return индекс
}

private func длинаСерии(
  знака: Character,
  от начало: String.Index,
  в строка: String
) -> Int {
  var индекс = начало
  var длина = 0
  while индекс < строка.endIndex, строка[индекс] == знака {
    длина += 1
    индекс = строка.index(after: индекс)
  }
  return длина
}

private func являетсяОтступнымКодом(_ строка: String) -> Bool {
  строка.hasPrefix("    ") || строка.hasPrefix("\t")
}

private func удалитьКомментарииРазметки(
  из строка: String,
  внутриКомментария: inout Bool
) -> String {
  var результат = ""
  var остаток = строка[...]

  while !остаток.isEmpty {
    if внутриКомментария {
      guard let конец = остаток.range(of: "-->") else {
        return результат
      }
      остаток = остаток[конец.upperBound...]
      внутриКомментария = false
      continue
    }

    guard let начало = остаток.range(of: "<!--") else {
      результат.append(contentsOf: остаток)
      return результат
    }
    результат.append(contentsOf: остаток[..<начало.lowerBound])
    остаток = остаток[начало.upperBound...]
    внутриКомментария = true
  }

  return результат
}

private func удалитьВстроенныйКод(из строка: String) -> String {
  var результат = ""
  var индекс = строка.startIndex

  while индекс < строка.endIndex {
    guard строка[индекс] == "`" else {
      результат.append(строка[индекс])
      индекс = строка.index(after: индекс)
      continue
    }

    let длина = длинаСерии(знака: "`", от: индекс, в: строка)
    let послеОткрытия = строка.index(индекс, offsetBy: длина)
    var кандидат = послеОткрытия
    var конец: String.Index?
    while кандидат < строка.endIndex {
      if строка[кандидат] == "`",
        длинаСерии(знака: "`", от: кандидат, в: строка) == длина
      {
        конец = кандидат
        break
      }
      кандидат = строка.index(after: кандидат)
    }

    guard let конец else {
      результат.append(contentsOf: строка[индекс..<послеОткрытия])
      индекс = послеОткрытия
      continue
    }
    индекс = строка.index(конец, offsetBy: длина)
  }

  return результат
}

private func первыйЗаголовок(в строки: [String]) -> String? {
  var предыдущаяСтрока: String?

  for строка in строки {
    let безПробелов = строка.trimmingCharacters(in: .whitespaces)

    if let заголовок = заголовокПервогоУровня(из: строка) {
      return заголовок
    }

    if являетсяПодчёркиваниемПервогоУровня(безПробелов),
      let предыдущаяСтрока,
      !предыдущаяСтрока.isEmpty
    {
      return предыдущаяСтрока
    }

    предыдущаяСтрока = безПробелов.isEmpty ? nil : безПробелов
  }

  return nil
}

private func заголовокПервогоУровня(из строка: String) -> String? {
  guard let начало = началоПослеДопустимогоОтступа(в: строка) else { return nil }
  let безНачальныхПробелов = строка[начало...]
  guard безНачальныхПробелов.first == "#" else { return nil }

  let послеРешётки = безНачальныхПробелов.dropFirst()
  guard let первыйСимвол = послеРешётки.first, первыйСимвол.isWhitespace else {
    return nil
  }

  var заголовок = String(послеРешётки).trimmingCharacters(in: .whitespaces)
  var началоЗамыкающихРешёток = заголовок.endIndex

  while началоЗамыкающихРешёток > заголовок.startIndex {
    let предыдущийИндекс = заголовок.index(before: началоЗамыкающихРешёток)
    guard заголовок[предыдущийИндекс] == "#" else { break }
    началоЗамыкающихРешёток = предыдущийИндекс
  }

  if началоЗамыкающихРешёток < заголовок.endIndex,
    началоЗамыкающихРешёток > заголовок.startIndex
  {
    let индексПередРешётками = заголовок.index(before: началоЗамыкающихРешёток)
    if заголовок[индексПередРешётками].isWhitespace {
      заголовок = String(заголовок[..<индексПередРешётками])
        .trimmingCharacters(in: .whitespaces)
    }
  }

  return заголовок.isEmpty ? nil : заголовок
}

private func являетсяПодчёркиваниемПервогоУровня(_ строка: String) -> Bool {
  !строка.isEmpty && строка.allSatisfy { $0 == "=" }
}

private func подсчитатьСсылки(в текст: String) -> Int {
  let диапазон = NSRange(текст.startIndex..<текст.endIndex, in: текст)

  return выраженияСсылок.reduce(into: 0) { сумма, выражение in
    сумма += выражение.numberOfMatches(in: текст, range: диапазон)
  }
}

private func родительскийПуть(для путь: String) -> String {
  let компоненты = путь.split(separator: "/")
  guard компоненты.count > 1 else { return "." }
  return компоненты.dropLast().joined(separator: "/")
}

private func глубинаПути(_ путь: String) -> Int {
  путь.split(separator: "/").count
}

private func предшествуетПуть(_ левый: String, _ правый: String) -> Bool {
  левый.utf8.lexicographicallyPrecedes(правый.utf8)
}

public struct РаскладчикДерева: Sendable {
  private let горизонтальныйШаг: Double
  private let вертикальныйШаг: Double

  public init(горизонтальныйШаг: Double = 78, вертикальныйШаг: Double = 116) {
    self.горизонтальныйШаг = горизонтальныйШаг
    self.вертикальныйШаг = вертикальныйШаг
  }

  public func разложить(
    снимок: СнимокДерева,
    свёрнутые: Set<String> = []
  ) -> РезультатРаскладки {
    var узлыПоИдентификатору: [String: УзелДерева] = [:]
    for узел in снимок.узлы where узлыПоИдентификатору[узел.id] == nil {
      узлыПоИдентификатору[узел.id] = узел
    }

    guard let корневойУзел = узлыПоИдентификатору["."] else {
      return РезультатРаскладки(
        положения: [:],
        рёбра: [],
        видимыеИдентификаторы: [],
        ширина: 0,
        высота: 0
      )
    }

    var дети: [String: [УзелДерева]] = [:]
    for узел in узлыПоИдентификатору.values {
      guard let родитель = узел.родитель else { continue }
      дети[родитель, default: []].append(узел)
    }
    for родитель in дети.keys {
      дети[родитель]?.sort {
        предшествуетПуть($0.относительныйПуть, $1.относительныйПуть)
      }
    }

    var положения: [String: ТочкаДерева] = [:]
    var рёбра: [РеброРаскладки] = []
    var видимыеИдентификаторы: [String] = []
    var следующийЛист = 0

    func разместить(_ узел: УзелДерева) -> Double {
      видимыеИдентификаторы.append(узел.id)
      let видимыеДети = свёрнутые.contains(узел.id) ? [] : (дети[узел.id] ?? [])
      let поГоризонтали: Double

      if видимыеДети.isEmpty {
        поГоризонтали = (Double(следующийЛист) + 0.5) * горизонтальныйШаг
        следующийЛист += 1
      } else {
        var положенияДетей: [Double] = []
        for ребёнок in видимыеДети {
          рёбра.append(РеброРаскладки(от: узел.id, к: ребёнок.id))
          положенияДетей.append(разместить(ребёнок))
        }
        поГоризонтали = положенияДетей.reduce(0, +) / Double(положенияДетей.count)
      }

      положения[узел.id] = ТочкаДерева(
        поГоризонтали: поГоризонтали,
        поВертикали: (Double(узел.глубина) + 0.5) * вертикальныйШаг
      )
      return поГоризонтали
    }

    _ = разместить(корневойУзел)

    let наибольшаяГлубина =
      видимыеИдентификаторы.compactMap {
        узлыПоИдентификатору[$0]?.глубина
      }.max() ?? 0

    return РезультатРаскладки(
      положения: положения,
      рёбра: рёбра,
      видимыеИдентификаторы: видимыеИдентификаторы,
      ширина: Double(max(следующийЛист, 1)) * горизонтальныйШаг,
      высота: Double(наибольшаяГлубина + 1) * вертикальныйШаг
    )
  }
}
