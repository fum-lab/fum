import Foundation
import XCTest

@testable import ДеревоДокументовЯдро

final class ТестыБезопасногоАдресаДокумента: XCTestCase {
  func test_разрешаетОбычныйВложенныйMarkdownДокумент() throws {
    try воВременномКаталоге { корень in
      let каталог = корень.appendingPathComponent("раздел", isDirectory: true)
      try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
      let документ = каталог.appendingPathComponent("документ.MD")
      try "# Документ".write(to: документ, atomically: true, encoding: .utf8)

      let адрес = try РазрешительПутиДокумента().безопасныйАдрес(
        корень: корень,
        относительныйПуть: "раздел/документ.MD"
      )

      XCTAssertEqual(адрес, документ.standardizedFileURL)
    }
  }

  func test_отклоняетВыходИзКорняИНеMarkdownПути() throws {
    try воВременномКаталоге { корень in
      let текст = корень.appendingPathComponent("заметка.txt")
      try "текст".write(to: текст, atomically: true, encoding: .utf8)
      let каталог = корень.appendingPathComponent("каталог", isDirectory: true)
      try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
      let разрешитель = РазрешительПутиДокумента()
      let абсолютныйПуть = FileManager.default.temporaryDirectory
        .appendingPathComponent("чужой.md").path

      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(корень: корень, относительныйПуть: абсолютныйПуть)
      )
      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(корень: корень, относительныйПуть: "../чужой.md")
      )
      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(корень: корень, относительныйПуть: "заметка.txt")
      )
      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(корень: корень, относительныйПуть: "каталог")
      )
    }
  }

  func test_отклоняетКонечнуюИПромежуточнуюСимволическиеСсылки() throws {
    try воВременномКаталоге { корень in
      let настоящийКаталог = корень.appendingPathComponent("настоящий", isDirectory: true)
      try FileManager.default.createDirectory(
        at: настоящийКаталог,
        withIntermediateDirectories: true
      )
      let настоящийДокумент = настоящийКаталог.appendingPathComponent("документ.md")
      try "# Документ".write(
        to: настоящийДокумент,
        atomically: true,
        encoding: .utf8
      )
      try FileManager.default.createSymbolicLink(
        at: корень.appendingPathComponent("ссылка.md"),
        withDestinationURL: настоящийДокумент
      )
      try FileManager.default.createSymbolicLink(
        at: корень.appendingPathComponent("ссылка-на-каталог"),
        withDestinationURL: настоящийКаталог
      )
      let разрешитель = РазрешительПутиДокумента()

      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(корень: корень, относительныйПуть: "ссылка.md")
      )
      XCTAssertThrowsError(
        try разрешитель.безопасныйАдрес(
          корень: корень,
          относительныйПуть: "ссылка-на-каталог/документ.md"
        )
      )
    }
  }

  func test_отклоняетФайлЗаменённыйПослеСканирования() throws {
    try воВременномКаталоге { корень in
      let внешний = корень.appendingPathComponent("внешний.md")
      let изменяемый = корень.appendingPathComponent("изменяемый.md")
      try "# Внешний".write(to: внешний, atomically: true, encoding: .utf8)
      try "# Исходный".write(to: изменяемый, atomically: true, encoding: .utf8)

      let снимок = try СканерРепозитория().сканировать(корень: корень)
      XCTAssertNotNil(снимок.узел(идентификатор: "изменяемый.md"))
      try FileManager.default.removeItem(at: изменяемый)
      try FileManager.default.createSymbolicLink(
        at: изменяемый,
        withDestinationURL: внешний
      )

      XCTAssertThrowsError(
        try РазрешительПутиДокумента().безопасныйАдрес(
          корень: корень,
          относительныйПуть: "изменяемый.md"
        )
      )
    }
  }

  func test_отклоняетСимволическуюСсылкуВместоКорня() throws {
    try воВременномКаталоге { внешнийКорень in
      let настоящийКорень = внешнийКорень.appendingPathComponent("настоящий", isDirectory: true)
      try FileManager.default.createDirectory(
        at: настоящийКорень,
        withIntermediateDirectories: true
      )
      try "# Документ".write(
        to: настоящийКорень.appendingPathComponent("документ.md"),
        atomically: true,
        encoding: .utf8
      )
      let ссылкаНаКорень = внешнийКорень.appendingPathComponent("корень-ссылка")
      try FileManager.default.createSymbolicLink(
        at: ссылкаНаКорень,
        withDestinationURL: настоящийКорень
      )

      XCTAssertThrowsError(
        try РазрешительПутиДокумента().безопасныйАдрес(
          корень: ссылкаНаКорень,
          относительныйПуть: "документ.md"
        )
      )
    }
  }
}

private func воВременномКаталоге(_ действие: (URL) throws -> Void) throws {
  let корень = FileManager.default.temporaryDirectory
    .appendingPathComponent("безопасный-адрес-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: корень) }
  try действие(корень)
}
