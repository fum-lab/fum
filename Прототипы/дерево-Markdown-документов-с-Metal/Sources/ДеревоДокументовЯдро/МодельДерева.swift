import Foundation

public enum ВидУзлаДерева: String, Codable, Sendable {
  case корень
  case каталог
  case документ
}

public struct УзелДерева: Identifiable, Hashable, Sendable {
  public let id: String
  public let название: String
  public let относительныйПуть: String
  public let родитель: String?
  public let вид: ВидУзлаДерева
  public let глубина: Int
  public let числоСсылок: Int

  public init(
    идентификатор: String,
    название: String,
    относительныйПуть: String,
    родитель: String?,
    вид: ВидУзлаДерева,
    глубина: Int,
    числоСсылок: Int
  ) {
    self.id = идентификатор
    self.название = название
    self.относительныйПуть = относительныйПуть
    self.родитель = родитель
    self.вид = вид
    self.глубина = глубина
    self.числоСсылок = числоСсылок
  }
}

public struct СнимокДерева: Sendable {
  public let корень: URL
  public let узлы: [УзелДерева]
  public let числоДокументов: Int
  public let пропущенныеПути: [String]

  public init(
    корень: URL,
    узлы: [УзелДерева],
    числоДокументов: Int,
    пропущенныеПути: [String] = []
  ) {
    self.корень = корень
    self.узлы = узлы
    self.числоДокументов = числоДокументов
    self.пропущенныеПути = пропущенныеПути
  }

  public func узел(идентификатор: String) -> УзелДерева? {
    узлы.first { $0.id == идентификатор }
  }
}

public struct ТочкаДерева: Hashable, Sendable {
  public let поГоризонтали: Double
  public let поВертикали: Double

  public init(поГоризонтали: Double, поВертикали: Double) {
    self.поГоризонтали = поГоризонтали
    self.поВертикали = поВертикали
  }
}

public struct РеброРаскладки: Hashable, Sendable {
  public let от: String
  public let к: String

  public init(от: String, к: String) {
    self.от = от
    self.к = к
  }
}

public struct РезультатРаскладки: Sendable {
  public let положения: [String: ТочкаДерева]
  public let рёбра: [РеброРаскладки]
  public let видимыеИдентификаторы: [String]
  public let ширина: Double
  public let высота: Double

  public init(
    положения: [String: ТочкаДерева],
    рёбра: [РеброРаскладки],
    видимыеИдентификаторы: [String],
    ширина: Double,
    высота: Double
  ) {
    self.положения = положения
    self.рёбра = рёбра
    self.видимыеИдентификаторы = видимыеИдентификаторы
    self.ширина = ширина
    self.высота = высота
  }
}
