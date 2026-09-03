import Foundation

public enum ОшибкаБезопасногоАдресаДокумента: Error, Equatable, LocalizedError, Sendable {
  case недопустимыйОтносительныйПуть(String)
  case кореньНеЯвляетсяОбычнымКаталогом(String)
  case путьИзменился(String)
  case путьВыходитЗаКорень(String)

  public var errorDescription: String? {
    switch self {
    case .недопустимыйОтносительныйПуть(let путь):
      return "Недопустимый относительный путь документа: \(путь)"
    case .кореньНеЯвляетсяОбычнымКаталогом(let путь):
      return "Корень документов не является обычным каталогом: \(путь)"
    case .путьИзменился(let путь):
      return "Путь документа изменился после сканирования: \(путь). Обновите дерево."
    case .путьВыходитЗаКорень(let путь):
      return "Путь документа выходит за выбранный корень: \(путь)"
    }
  }
}

public struct РазрешительПутиДокумента: Sendable {
  public init() {}

  public func безопасныйАдрес(
    корень: URL,
    относительныйПуть: String
  ) throws -> URL {
    let компоненты = относительныйПуть.split(
      separator: "/",
      omittingEmptySubsequences: false
    ).map(String.init)
    guard
      !относительныйПуть.isEmpty,
      !NSString(string: относительныйПуть).isAbsolutePath,
      !компоненты.isEmpty,
      !компоненты.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
    else {
      throw ОшибкаБезопасногоАдресаДокумента.недопустимыйОтносительныйПуть(
        относительныйПуть
      )
    }

    let файловаяСистема = FileManager.default
    let корневаяСсылка = корень.standardizedFileURL
    guard
      let атрибутыКорня = try? файловаяСистема.attributesOfItem(
        atPath: корневаяСсылка.path
      ),
      атрибутыКорня[.type] as? FileAttributeType == .typeDirectory
    else {
      throw ОшибкаБезопасногоАдресаДокумента.кореньНеЯвляетсяОбычнымКаталогом(
        корневаяСсылка.path
      )
    }

    var ссылка = корневаяСсылка
    for (индекс, компонент) in компоненты.enumerated() {
      let последний = индекс == компоненты.count - 1
      ссылка.appendPathComponent(компонент, isDirectory: !последний)
      guard
        let атрибуты = try? файловаяСистема.attributesOfItem(atPath: ссылка.path),
        let тип = атрибуты[.type] as? FileAttributeType,
        тип != .typeSymbolicLink,
        последний ? тип == .typeRegular : тип == .typeDirectory
      else {
        throw ОшибкаБезопасногоАдресаДокумента.путьИзменился(относительныйПуть)
      }
    }

    guard ссылка.pathExtension.lowercased() == "md" else {
      throw ОшибкаБезопасногоАдресаДокумента.путьИзменился(относительныйПуть)
    }
    try проверитьВложенность(
      ссылки: ссылка.standardizedFileURL,
      в: корневаяСсылка,
      исходныйПуть: относительныйПуть
    )
    try проверитьВложенность(
      ссылки: ссылка.resolvingSymlinksInPath().standardizedFileURL,
      в: корневаяСсылка.resolvingSymlinksInPath().standardizedFileURL,
      исходныйПуть: относительныйПуть
    )
    return ссылка.standardizedFileURL
  }
}

private func проверитьВложенность(
  ссылки: URL,
  в корень: URL,
  исходныйПуть: String
) throws {
  let компонентыКорня = корень.pathComponents
  let компонентыСсылки = ссылки.pathComponents
  guard
    компонентыСсылки.count > компонентыКорня.count,
    компонентыСсылки.prefix(компонентыКорня.count).elementsEqual(компонентыКорня)
  else {
    throw ОшибкаБезопасногоАдресаДокумента.путьВыходитЗаКорень(исходныйПуть)
  }
}
