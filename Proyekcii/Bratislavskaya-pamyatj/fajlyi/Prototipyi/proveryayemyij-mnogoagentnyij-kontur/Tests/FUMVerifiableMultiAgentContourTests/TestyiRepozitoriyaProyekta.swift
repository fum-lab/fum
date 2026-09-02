import Foundation
import XCTest

@testable import FUMVerifiableMultiAgentContour

final class ТестыРепозиторияПроекта: XCTestCase {
  func test_ИнвентарьФикстурСтабилен() {
    XCTAssertEqual(
      ФикстурыРепозиторияПроекта.идентификаторы,
      [
        "сквозной-сценарий",
        "обычный-каталог-вместо-gitlink",
        "нет-паспорта",
        "нет-следующего-шага",
        "общий-checkout",
        "неверный-gitlink",
        "цикл",
        "недоступная-публикация",
      ]
    )
  }

  func test_СквознойСценарийСоздаётПроектВыполняетШагИОбновляетСсылкуПодмодуля() throws {
    let отчёт = try ФикстурыРепозиторияПроекта.выполнить(имя: "сквозной-сценарий")

    XCTAssertEqual(отчёт.решение, .пройдено)
    for проверка in отчёт.проверки {
      XCTAssertTrue(проверка.пройдена, проверка.идентификатор)
    }
    XCTAssertEqual(
      Set(отчёт.проверки.map(\.идентификатор)),
      Set([
        "проект-имеет-собственную-репозиторную-идентичность",
        "паспорт-хранит-полный-контракт",
        "проект-хранит-собственные-правила-очередь-claim-и-следующий-шаг",
        "очередь-и-claim-привязаны-к-физическому-checkout",
        "родитель-хранит-только-композиционную-регистрацию",
        "родительский-путь-является-точным-gitlink",
        "пишущий-шаг-выполнен-в-отдельном-клоне",
        "обновление-gitlink-является-отдельным-CAS-коммитом",
        "живой-ref-проекта-опережает-принятый-gitlink",
        "свежий-клон-без-материализации-сохраняет-точную-ревизию",
        "материализованный-снимок-detached-и-чист",
        "сценарий-использует-только-локальные-bare-репозитории",
      ])
    )
    XCTAssertNotNil(отчёт.хэшПаспорта)
    XCTAssertNotEqual(отчёт.исходныйКоммитПроекта, отчёт.итоговыйКоммитПроекта)
    XCTAssertNotEqual(отчёт.исходныйКоммитРодителя, отчёт.итоговыйКоммитРодителя)
    XCTAssertFalse(отчёт.неожиданноеИзменениеСсылок)
  }

  func test_РодительскаяРегистрацияЗакрытаНаКаждомУровне() throws {
    let данные = try данныеЗакрытойРегистрации()
    XCTAssertNotNil(
      ПредварительнаяПроверкаПроекта.разобратьЗакрытуюРегистрацию(
        данные: данные,
        путьПроекта: "Проекты/самостоятельный"
      )
    )

    var корень = try XCTUnwrap(
      JSONSerialization.jsonObject(with: данные) as? [String: Any])
    var проект = try XCTUnwrap(корень["проект"] as? [String: Any])
    проект["task"] = "скрытая копия внутренней задачи"
    корень["проект"] = проект
    let данныеСЛишнимПолем = try JSONSerialization.data(withJSONObject: корень)
    XCTAssertNil(
      ПредварительнаяПроверкаПроекта.разобратьЗакрытуюРегистрацию(
        данные: данныеСЛишнимПолем,
        путьПроекта: "Проекты/самостоятельный"
      )
    )

    корень = try XCTUnwrap(JSONSerialization.jsonObject(with: данные) as? [String: Any])
    проект = try XCTUnwrap(корень["проект"] as? [String: Any])
    var маршрут = try XCTUnwrap(проект["handoff"] as? [String: Any])
    маршрут["target_ref"] = "refs/heads/другая"
    проект["handoff"] = маршрут
    корень["проект"] = проект
    let данныеСНевернымМаршрутом = try JSONSerialization.data(withJSONObject: корень)
    XCTAssertNil(
      ПредварительнаяПроверкаПроекта.разобратьЗакрытуюРегистрацию(
        данные: данныеСНевернымМаршрутом,
        путьПроекта: "Проекты/самостоятельный"
      )
    )
  }

  func test_ОтрицательныеСценарииЗакрываютсяДоНепредусмотреннойПубликации() throws {
    let ожидаемыеПроверки = [
      "обычный-каталог-вместо-gitlink": "обычный-каталог-отклонён",
      "нет-паспорта": "проект-без-паспорта-отклонён",
      "нет-следующего-шага": "проект-без-следующего-шага-отклонён",
      "общий-checkout": "общий-checkout-с-родителем-отклонён",
      "неверный-gitlink": "неверный-gitlink-отклонён",
      "цикл": "цикл-репозиторной-композиции-отклонён",
      "недоступная-публикация": "недоступная-публикация-отклонена",
    ]

    for (имя, ожидаемаяПроверка) in ожидаемыеПроверки {
      let отчёт = try ФикстурыРепозиторияПроекта.выполнить(имя: имя)
      XCTAssertEqual(отчёт.решение, .пройдено, имя)
      XCTAssertEqual(отчёт.проверки.map(\.идентификатор), [ожидаемаяПроверка], имя)
      XCTAssertEqual(отчёт.проверки.first?.пройдена, true, имя)
      XCTAssertFalse(отчёт.неожиданноеИзменениеСсылок, имя)
      XCTAssertEqual(отчёт.исходныйКоммитРодителя, отчёт.итоговыйКоммитРодителя, имя)
    }
  }

  func test_КаноническийОтчётВоспроизводимИНеСодержитВременныйПуть() throws {
    let первый = try ФикстурыРепозиторияПроекта.выполнить(имя: "сквозной-сценарий")
    let второй = try ФикстурыРепозиторияПроекта.выполнить(имя: "сквозной-сценарий")
    let первыеДанные = try первый.каноническиеДанные()
    let вторыеДанные = try второй.каноническиеДанные()
    let текст = try XCTUnwrap(String(data: первыеДанные, encoding: .utf8))

    XCTAssertEqual(первыеДанные, вторыеДанные)
    XCTAssertFalse(текст.contains(FileManager.default.temporaryDirectory.path))
    XCTAssertFalse(текст.contains("file:"))
    XCTAssertTrue(текст.contains("urn:fum:"))
  }

  private func данныеЗакрытойРегистрации() throws -> Data {
    let проверки = ["project-passport", "project-control-plane", "project-parent-gitlink"]
    return try РегистрацияПроекта(
      идентификаторСхемы: "urn:fum:schema:project-registration:v1",
      версияСхемы: 1,
      проект: RepositoryCompositionChild(
        entryID: "entry.project.fixture",
        kind: .project,
        nodeID: nil,
        projectID: "project.independent.fixture",
        targetRepositoryID: nil,
        repositoryID: "repository.project.fixture",
        repositoryURL: "urn:fum:repository:project-fixture",
        upstreamRepositoryID: nil,
        baseOID: String(repeating: "1", count: 40),
        liveRef: "refs/heads/project-main",
        submodulePath: "Проекты/самостоятельный",
        gitlinkOID: String(repeating: "2", count: 40),
        snapshotMode: "detached_read_only",
        writerMode: "separate_clone",
        nestedSubmodules: [],
        accessLevel: .public,
        publicationBoundary: .public,
        checks: проверки,
        handoff: RepositoryCompositionHandoff(
          targetRepositoryID: "repository.parent.fixture",
          targetRef: "refs/heads/main",
          requiredCheckIDs: проверки
        )
      )
    ).каноническиеДанные()
  }
}
