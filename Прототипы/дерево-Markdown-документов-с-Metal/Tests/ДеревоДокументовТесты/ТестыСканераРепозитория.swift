import Foundation
import XCTest

@testable import ДеревоДокументовЯдро

final class ТестыСканераРепозитория: XCTestCase {
  func test_извлекаетПервыйЗаголовокИспользуетИмяФайлаИСчитаетСсылки() throws {
    try воВременномКаталоге { корень in
      let раздел = корень.appendingPathComponent("Раздел", isDirectory: true)
      try FileManager.default.createDirectory(at: раздел, withIntermediateDirectories: true)

      let текстСЗаголовком = """
        <!-- FUM-MD-RECENCY:BEGIN -->
        # Служебный заголовок
        [[не-считать]]
        <!-- FUM-MD-RECENCY:END -->

        # Содержательный заголовок ###

        [обычная](цель.md), [[вики-ссылка|подпись]], [справочная][метка]
        и <https://example.test/страница>.

        ```text
        [ссылка в примере](не-считать.md)
        ```

        [метка]: назначение.md
        """
      try текстСЗаголовком.write(
        to: раздел.appendingPathComponent("описание.MD"),
        atomically: true,
        encoding: .utf8
      )

      try "Текст без заголовка. [Одна ссылка](цель.md)".write(
        to: корень.appendingPathComponent("без-заголовка.md"),
        atomically: true,
        encoding: .utf8
      )

      let снимок = try СканерРепозитория().сканировать(корень: корень)

      XCTAssertEqual(снимок.числоДокументов, 2)
      XCTAssertEqual(
        снимок.узлы.map(\.id),
        [".", "Раздел", "Раздел/описание.MD", "без-заголовка.md"]
      )
      XCTAssertEqual(снимок.узел(идентификатор: "Раздел")?.вид, .каталог)
      XCTAssertEqual(снимок.узел(идентификатор: "Раздел")?.родитель, ".")
      XCTAssertEqual(
        снимок.узел(идентификатор: "Раздел/описание.MD")?.название,
        "Содержательный заголовок"
      )
      XCTAssertEqual(снимок.узел(идентификатор: "Раздел/описание.MD")?.числоСсылок, 4)
      XCTAssertEqual(снимок.узел(идентификатор: "без-заголовка.md")?.название, "без-заголовка")
      XCTAssertEqual(снимок.узел(идентификатор: "без-заголовка.md")?.числоСсылок, 1)
    }
  }

  func test_исключаетСлужебныеКаталогиВложенныйРепозиторийИСимволическиеСсылки() throws {
    try воВременномКаталоге { корень in
      try записать("# Видимый", в: корень.appendingPathComponent("видимый.Md"))
      try записать("не Markdown", в: корень.appendingPathComponent("заметка.txt"))

      let корневыеИсключения = ["Подузлы", ".build", ".swiftpm", ".cache"]
      for имя in корневыеИсключения {
        let каталог = корень.appendingPathComponent(имя, isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
        try записать("# Скрытый", в: каталог.appendingPathComponent("скрытый.md"))
      }

      let вложенныеПодузлы =
        корень
        .appendingPathComponent("раздел", isDirectory: true)
        .appendingPathComponent("Подузлы", isDirectory: true)
      try FileManager.default.createDirectory(
        at: вложенныеПодузлы, withIntermediateDirectories: true)
      try записать("# Вложенный", в: вложенныеПодузлы.appendingPathComponent("вложенный.md"))

      let отдельныйРепозиторий =
        корень
        .appendingPathComponent("вендор", isDirectory: true)
        .appendingPathComponent("репозиторий", isDirectory: true)
      try FileManager.default.createDirectory(
        at: отдельныйРепозиторий.appendingPathComponent(".git", isDirectory: true),
        withIntermediateDirectories: true
      )
      try записать("# Чужой", в: отдельныйРепозиторий.appendingPathComponent("чужой.md"))

      let настоящийКаталог = корень.appendingPathComponent("настоящий", isDirectory: true)
      try FileManager.default.createDirectory(
        at: настоящийКаталог, withIntermediateDirectories: true)
      try записать("# Настоящий", в: настоящийКаталог.appendingPathComponent("документ.md"))

      try FileManager.default.createSymbolicLink(
        at: корень.appendingPathComponent("ссылка-на-каталог"),
        withDestinationURL: настоящийКаталог
      )
      try FileManager.default.createSymbolicLink(
        at: корень.appendingPathComponent("ссылка.md"),
        withDestinationURL: корень.appendingPathComponent("видимый.Md")
      )
      try FileManager.default.createDirectory(
        at: корень.appendingPathComponent("пустой", isDirectory: true),
        withIntermediateDirectories: true
      )

      let снимок = try СканерРепозитория().сканировать(корень: корень)
      let путиДокументов = Set(
        снимок.узлы.filter { $0.вид == .документ }.map(\.относительныйПуть)
      )

      XCTAssertEqual(
        путиДокументов,
        [
          "видимый.Md",
          "настоящий/документ.md",
          "раздел/Подузлы/вложенный.md",
        ]
      )
      XCTAssertNil(снимок.узел(идентификатор: "Подузлы"))
      XCTAssertNil(снимок.узел(идентификатор: "вендор"))
      XCTAssertNil(снимок.узел(идентификатор: "пустой"))
      XCTAssertNil(снимок.узел(идентификатор: "ссылка.md"))
      XCTAssertNil(снимок.узел(идентификатор: "ссылка-на-каталог"))
    }
  }

  func test_повторноеСканированиеДетерминировано() throws {
    try воВременномКаталоге { корень in
      let каталог = корень.appendingPathComponent("документы", isDirectory: true)
      try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
      try записать("# Бета", в: каталог.appendingPathComponent("б.md"))
      try записать("# Альфа", в: каталог.appendingPathComponent("а.md"))
      try записать("# Корневой", в: корень.appendingPathComponent("корневой.md"))

      let сканер = СканерРепозитория()
      let первыйСнимок = try сканер.сканировать(корень: корень)
      let второйСнимок = try сканер.сканировать(корень: корень)

      XCTAssertEqual(первыйСнимок.узлы, второйСнимок.узлы)
      XCTAssertEqual(
        первыйСнимок.узлы.map(\.id),
        [".", "документы", "документы/а.md", "документы/б.md", "корневой.md"]
      )
    }
  }

  func test_неСчитаетКодИКомментарииСодержимымДокумента() throws {
    try воВременномКаталоге { корень in
      let текст = """
        <!--
        # Заголовок в комментарии
        [ссылка в комментарии](скрытая.md)
        -->

            # Заголовок в отступном коде

        ````text
        ```swift
        # Заголовок во вложенной ограде
        [ссылка в ограде](скрытая.md)
        ```
        ````

        # Видимый заголовок

        `[встроенный код](скрытая.md)` и [видимая ссылка](цель.md).
        """
      try записать(текст, в: корень.appendingPathComponent("проверка.md"))

      let снимок = try СканерРепозитория().сканировать(корень: корень)
      let документ = снимок.узел(идентификатор: "проверка.md")

      XCTAssertEqual(документ?.название, "Видимый заголовок")
      XCTAssertEqual(документ?.числоСсылок, 1)
    }
  }

  func test_декодируетПовреждённыйТекстБезОтказаВсегоСканирования() throws {
    try воВременномКаталоге { корень in
      try Data([0xFF, 0xFE, 0x41]).write(to: корень.appendingPathComponent("повреждённый.md"))

      let снимок = try СканерРепозитория().сканировать(корень: корень)

      XCTAssertEqual(снимок.числоДокументов, 1)
      XCTAssertEqual(
        снимок.узел(идентификатор: "повреждённый.md")?.название,
        "повреждённый"
      )
      XCTAssertTrue(снимок.пропущенныеПути.isEmpty)
    }
  }
}

private func воВременномКаталоге(_ действие: (URL) throws -> Void) throws {
  let корень = FileManager.default.temporaryDirectory
    .appendingPathComponent("дерево-документов-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: корень) }
  try действие(корень)
}

private func записать(_ текст: String, в ссылка: URL) throws {
  try текст.write(to: ссылка, atomically: true, encoding: .utf8)
}
