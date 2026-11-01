import Foundation

/// Синтетическое подготовительное ядро: не является операцией графа FUMA и не принимает аудио.
public enum ПоискРечевыхПутей {
  public struct Узел: Equatable, Sendable {
    public let идентификатор: String
    public let отсчёт: Int64
    public init(_ идентификатор: String, _ отсчёт: Int64) {
      self.идентификатор = идентификатор
      self.отсчёт = отсчёт
    }
    public static func == (левый: Self, правый: Self) -> Bool {
      левый.идентификатор.utf8.elementsEqual(правый.идентификатор.utf8) && левый.отсчёт == правый.отсчёт
    }
  }

  public struct Ребро: Equatable, Sendable {
    public let идентификатор: String
    public let из: String
    public let в: String
    public let символ: String
    public let вес: Int64
    public init(_ идентификатор: String, из: String, в: String, символ: String, вес: Int64) {
      self.идентификатор = идентификатор
      self.из = из
      self.в = в
      self.символ = символ
      self.вес = вес
    }
    public static func == (левый: Self, правый: Self) -> Bool {
      левый.идентификатор.utf8.elementsEqual(правый.идентификатор.utf8)
        && левый.из.utf8.elementsEqual(правый.из.utf8) && левый.в.utf8.elementsEqual(правый.в.utf8)
        && левый.символ.utf8.elementsEqual(правый.символ.utf8) && левый.вес == правый.вес
    }
  }

  public struct Слово: Equatable, Sendable {
    public let идентификатор: String
    public let фонемы: [String]
    public let текст: String
    public let язык: String
    public init(_ идентификатор: String, фонемы: [String], текст: String, язык: String) {
      self.идентификатор = идентификатор
      self.фонемы = фонемы
      self.текст = текст
      self.язык = язык
    }
    public static func == (левый: Self, правый: Self) -> Bool {
      левый.идентификатор.utf8.elementsEqual(правый.идентификатор.utf8)
        && левый.фонемы.count == правый.фонемы.count
        && zip(левый.фонемы, правый.фонемы).allSatisfy { $0.0.utf8.elementsEqual($0.1.utf8) }
        && левый.текст.utf8.elementsEqual(правый.текст.utf8)
        && левый.язык.utf8.elementsEqual(правый.язык.utf8)
    }
  }

  public struct Вход: Sendable {
    public let полный: Bool
    public let начало: String
    public let конец: String
    public let узлы: [Узел]
    public let рёбра: [Ребро]
    public let словарь: [Слово]
    public init(полный: Bool, начало: String, конец: String, узлы: [Узел], рёбра: [Ребро], словарь: [Слово]) {
      self.полный = полный
      self.начало = начало
      self.конец = конец
      self.узлы = узлы
      self.рёбра = рёбра
      self.словарь = словарь
    }
  }

  public struct Сегмент: Equatable, Sendable {
    public let слово: String
    public let язык: String
    public let начало: Int64
    public let конец: Int64

    public static func == (левый: Self, правый: Self) -> Bool {
      левый.слово.utf8.elementsEqual(правый.слово.utf8)
        && левый.язык.utf8.elementsEqual(правый.язык.utf8)
        && левый.начало == правый.начало && левый.конец == правый.конец
    }
  }

  public struct Кандидат: Equatable, Sendable {
    public let рёбра: [String]
    public let идентификаторыСлов: [String]
    public let сегменты: [Сегмент]
    /// Сумма синтетических весов: больше — лучше, не вероятность.
    public let оценка: Int64

    public static func == (левый: Self, правый: Self) -> Bool {
      левый.рёбра.count == правый.рёбра.count
        && zip(левый.рёбра, правый.рёбра).allSatisfy { $0.0.utf8.elementsEqual($0.1.utf8) }
        && левый.идентификаторыСлов.count == правый.идентификаторыСлов.count
        && zip(левый.идентификаторыСлов, правый.идентификаторыСлов)
          .allSatisfy { $0.0.utf8.elementsEqual($0.1.utf8) }
        && левый.сегменты == правый.сегменты && левый.оценка == правый.оценка
    }
  }

  public enum Результат: Equatable, Sendable {
    case неизвестно
    case нетСовпадения
    case кандидат(Кандидат)
  }

  public enum Ошибка: Error, Equatable {
    case неверныйВход
    case пределРесурсов
    case переполнение
  }

  private struct Ключ: Hashable {
    let слово: Int
    let позиция: Int
  }
  private struct Гипотеза {
    let оценка: Int64
    let рёбра: [String]
    let словарныеID: [String]
    let сегменты: [Сегмент]
    let началоСлова: Int64?
  }

  private static func байты(_ строка: String) -> Data { Data(строка.utf8) }
  private static func допустимо(_ строка: String) -> Bool {
    !строка.isEmpty && строка.utf8.prefix(257).count <= 256
  }
  private static func раньше(_ a: [String], _ b: [String]) -> Bool {
    for (x, y) in zip(a, b) {
      let xx = байты(x), yy = байты(y)
      if xx != yy { return xx.lexicographicallyPrecedes(yy) }
    }
    return a.count < b.count
  }
  private static func лучше(_ a: Гипотеза, чем b: Гипотеза) -> Bool {
    if a.оценка != b.оценка { return a.оценка > b.оценка }
    if a.рёбра.map(байты) != b.рёбра.map(байты) { return раньше(a.рёбра, b.рёбра) }
    return раньше(a.словарныеID, b.словарныеID)
  }

  /// Лимит считает логические переходы этой синтетической реализации, не общий бюджет FUMA.
  /// Размеры строк и коллекций ограничены отдельно; исчерпание не возвращает частичный успех.
  public static func выполнить(_ вход: Вход, пределОпераций: Int = 250_000) throws -> Результат {
    guard вход.полный else { return .неизвестно }
    guard (1...250_000).contains(пределОпераций), (2...64).contains(вход.узлы.count),
      (1...128).contains(вход.рёбра.count), (1...32).contains(вход.словарь.count),
      допустимо(вход.начало), допустимо(вход.конец) else { throw Ошибка.неверныйВход }
    var осталось = пределОпераций
    func шаг() throws {
      guard осталось > 0 else { throw Ошибка.пределРесурсов }
      осталось -= 1
    }
    var узлы: [Data: Int] = [:]
    for (индекс, узел) in вход.узлы.enumerated() {
      try шаг()
      guard допустимо(узел.идентификатор), узел.отсчёт >= 0,
        узлы.updateValue(индекс, forKey: байты(узел.идентификатор)) == nil
      else { throw Ошибка.неверныйВход }
    }
    guard let начало = узлы[байты(вход.начало)], let конец = узлы[байты(вход.конец)], начало != конец
    else { throw Ошибка.неверныйВход }
    var идентификаторыРёбер = Set<Data>()
    var исходящие = Array(repeating: [Int](), count: вход.узлы.count)
    for (индекс, ребро) in вход.рёбра.enumerated() {
      try шаг()
      guard допустимо(ребро.идентификатор), допустимо(ребро.из), допустимо(ребро.в), допустимо(ребро.символ),
        идентификаторыРёбер.insert(байты(ребро.идентификатор)).inserted,
        let из = узлы[байты(ребро.из)], let в = узлы[байты(ребро.в)],
        вход.узлы[из].отсчёт < вход.узлы[в].отсчёт
      else { throw Ошибка.неверныйВход }
      исходящие[из].append(индекс)
    }
    var идентификаторыСлов = Set<Data>()
    for слово in вход.словарь {
      try шаг()
      guard допустимо(слово.идентификатор), допустимо(слово.текст), допустимо(слово.язык),
        (1...8).contains(слово.фонемы.count), слово.фонемы.allSatisfy(допустимо),
        идентификаторыСлов.insert(байты(слово.идентификатор)).inserted
      else { throw Ошибка.неверныйВход }
    }
    let порядок = вход.узлы.indices.sorted {
      let a = вход.узлы[$0], b = вход.узлы[$1]
      return a.отсчёт == b.отсчёт ? байты(a.идентификатор).lexicographicallyPrecedes(байты(b.идентификатор)) : a.отсчёт < b.отсчёт
    }
    var достигаетКонца = Array(repeating: false, count: вход.узлы.count)
    достигаетКонца[конец] = true
    for узел in порядок.reversed() where узел != конец {
      for индексРебра in исходящие[узел] {
        try шаг()
        guard let цель = узлы[байты(вход.рёбра[индексРебра].в)] else { throw Ошибка.неверныйВход }
        if достигаетКонца[цель] { достигаетКонца[узел] = true }
      }
    }
    guard достигаетКонца[начало] else { return .нетСовпадения }
    let граница = Ключ(слово: -1, позиция: 0)
    var состояния = Array(repeating: [Ключ: Гипотеза](), count: вход.узлы.count)
    состояния[начало][граница] = Гипотеза(оценка: 0, рёбра: [], словарныеID: [], сегменты: [], началоСлова: nil)
    var числоСостояний = 1
    func сохранить(_ гипотеза: Гипотеза, _ ключ: Ключ, _ узел: Int) throws {
      try шаг()
      if let прежнее = состояния[узел][ключ] {
        if лучше(гипотеза, чем: прежнее) { состояния[узел][ключ] = гипотеза }
      } else {
        guard числоСостояний < 8192 else { throw Ошибка.пределРесурсов }
        числоСостояний += 1
        состояния[узел][ключ] = гипотеза
      }
    }
    for узел in порядок where узел != конец && достигаетКонца[узел] {
      for (ключ, гипотеза) in состояния[узел] {
        for индексРебра in исходящие[узел] {
          try шаг()
          let ребро = вход.рёбра[индексРебра]
          guard let цель = узлы[байты(ребро.в)] else { throw Ошибка.неверныйВход }
          guard достигаетКонца[цель] else { continue }
          let варианты = ключ == граница ? Array(вход.словарь.indices) : [ключ.слово]
          for номер in варианты {
            try шаг()
            let слово = вход.словарь[номер]
            let позиция = ключ == граница ? 0 : ключ.позиция
            guard позиция < слово.фонемы.count,
              байты(слово.фонемы[позиция]) == байты(ребро.символ) else { continue }
            let (оценка, переполнение) = гипотеза.оценка.addingReportingOverflow(ребро.вес)
            guard !переполнение else { throw Ошибка.переполнение }
            let путь = гипотеза.рёбра + [ребро.идентификатор]
            let старт = гипотеза.началоСлова ?? вход.узлы[узел].отсчёт
            if позиция + 1 == слово.фонемы.count {
              let сегмент = Сегмент(слово: слово.текст, язык: слово.язык, начало: старт, конец: вход.узлы[цель].отсчёт)
              let новая = Гипотеза(оценка: оценка, рёбра: путь, словарныеID: гипотеза.словарныеID + [слово.идентификатор], сегменты: гипотеза.сегменты + [сегмент], началоСлова: nil)
              try сохранить(новая, граница, цель)
            } else {
              let новая = Гипотеза(оценка: оценка, рёбра: путь, словарныеID: гипотеза.словарныеID, сегменты: гипотеза.сегменты, началоСлова: старт)
              try сохранить(новая, Ключ(слово: номер, позиция: позиция + 1), цель)
            }
          }
        }
      }
    }
    guard let лучшая = состояния[конец][граница], !лучшая.сегменты.isEmpty else { return .нетСовпадения }
    return .кандидат(Кандидат(рёбра: лучшая.рёбра, идентификаторыСлов: лучшая.словарныеID, сегменты: лучшая.сегменты, оценка: лучшая.оценка))
  }
}
