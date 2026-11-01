import CryptoKit
import Foundation
import XCTest
import FUMStructuringOperatorMemory
import ЭталонКлавиатуры

final class ВводОкнаTests: XCTestCase {
  private var корень: URL!
  private var окно: ИдентификаторОкнаВвода!
  private var фокусА: ИдентификаторФокусаВвода!
  private var фокусБ: ИдентификаторФокусаВвода!

  override func setUpWithError() throws {
    guard let значение = ProcessInfo.processInfo.environment["КЛАВИАТУРА_КОРЕНЬ_ПАКЕТА"],
          значение.hasPrefix("/") else {
      throw NSError(domain: "Klaviatura.ввод-окна", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "КЛАВИАТУРА: отсутствует физический корень пакета"])
    }
    корень = URL(fileURLWithPath: значение, isDirectory: true)
    окно = ИдентификаторОкнаВвода(rawValue: UUID())
    фокусА = ИдентификаторФокусаВвода(rawValue: UUID())
    фокусБ = ИдентификаторФокусаВвода(rawValue: UUID())
  }

  private func новыйАдаптер(
    восстанавливая снимок: СнимокСобытийКлавиатуры? = nil
  ) throws -> АдаптерВводаОкна {
    try АдаптерВводаОкна(
      окно: окно,
      байтыОпределения: Data(contentsOf: корень.appendingPathComponent("определение.json")),
      байтыТаблицы: Data(contentsOf: корень.appendingPathComponent("таблица-раскладки.json")),
      привязка: .keyboardQwertyV1,
      восстанавливая: снимок
    )
  }

  private func provenance(
    focus: ИдентификаторФокусаВвода,
    generation: UInt64? = nil,
    order: UInt64,
    observedAt: UInt64? = nil
  ) -> СвидетельствоСобытияКлавиатуры {
    СвидетельствоСобытияКлавиатуры(
      окно: окно,
      фокус: focus,
      поколениеФокуса: generation ?? (focus == фокусА ? 1 : 2),
      порядок: order,
      моментНаблюденияНс: observedAt ?? order * 1_000
    )
  }

  private func physical(
    id: UUID = UUID(),
    focus: ИдентификаторФокусаВвода? = nil,
    generation: UInt64? = nil,
    order: UInt64,
    key: Int64,
    phase: ФазаФизическойКлавиши = .нажатие,
    repeat isRepeat: Bool = false,
    layout: ИдентификаторРаскладкиКлавиатуры = .qwerty,
    handling: ОбработкаНативногоСобытия = .fuma,
    modifiers: СостояниеМодификаторовКлавиатуры? = nil
  ) -> ФизическоеСобытиеКлавиатуры {
    let focus = focus ?? фокусА!
    return ФизическоеСобытиеКлавиатуры(
      идентификатор: ИдентификаторСобытияКлавиатуры(rawValue: id),
      свидетельство: provenance(focus: focus, generation: generation, order: order),
      код: key,
      фаза: phase,
      повтор: isRepeat,
      раскладка: layout,
      обработкаНативнымКраем: handling,
      снимокМодификаторов: modifiers
    )
  }

  private func ime(
    id: UUID = UUID(),
    composition: UUID,
    kind: ВидСобытияIME,
    relatedPhysical: UUID?,
    focus: ИдентификаторФокусаВвода? = nil,
    generation: UInt64? = nil,
    order: UInt64
  ) -> СобытиеIME {
    let focus = focus ?? фокусА!
    return СобытиеIME(
      идентификатор: ИдентификаторСобытияКлавиатуры(rawValue: id),
      композиция: composition,
      вид: kind,
      связаноСФизическимСобытием: relatedPhysical.map(ИдентификаторСобытияКлавиатуры.init(rawValue:)),
      свидетельство: provenance(focus: focus, generation: generation, order: order)
    )
  }

  private func подтвердитьФокус(
    _ адаптер: inout АдаптерВводаОкна,
    _ focus: ИдентификаторФокусаВвода,
    generation: UInt64? = nil
  ) {
    let подтверждено = адаптер.подтвердитьФокус(
      вОкне: окно,
      фокус: focus,
      поколение: generation ?? (focus == фокусА ? 1 : 2),
      снимокМодификаторов: .пустое,
      моментНаблюденияНс: 0
    )
    XCTAssertTrue(подтверждено)
  }

  func testЗакреплённыеХэшиRawИCanonicalИМашинныйГраф() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let физическое = physical(order: 1, key: 12)
    let результат = try адаптер.принять(физическое)

    XCTAssertEqual(АдаптерВводаОкна.привязкаQwertyV1.хэшОпределения, "6deb8aed4b93b7d2528e26df041da8314b9a9cc433483a2c44611b7585f7b4ac")
    XCTAssertEqual(Self.sha256(try ОпределениеОператора.разобрать(Data(contentsOf: корень.appendingPathComponent("определение.json"))).данные()), "sha256:435f7a15c1ec76a6650b3b4607f85c300b3e4d44a5a0b36be30ed8767d8cb272")
    XCTAssertEqual(результат.трасса?.хэшОпределения, "sha256:435f7a15c1ec76a6650b3b4607f85c300b3e4d44a5a0b36be30ed8767d8cb272")
    XCTAssertEqual(результат.вывод, .текст("q", источник: .fuma))
    XCTAssertEqual(результат.маршрут, .потребить)
    XCTAssertEqual(результат.трасса?.шаги.map(\.идентификатор), ["переход-раскладки"])
  }

  func testFUMAStateFromModifierTransitionsFeedsNextGraphEvent() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let shift = try адаптер.принять(physical(order: 1, key: 56))
    XCTAssertEqual(shift.вывод, .нет)
    XCTAssertEqual(shift.маршрут, .потребить)
    XCTAssertTrue(shift.состояние.сдвигСлева)

    let letter = try адаптер.принять(physical(order: 2, key: 12))
    XCTAssertEqual(letter.вывод, .текст("Q", источник: .fuma))
    XCTAssertTrue(letter.состояние.сдвигСлева)

    let release = try адаптер.принять(physical(order: 3, key: 56, phase: .отпускание))
    XCTAssertFalse(release.состояние.сдвигСлева)
    XCTAssertEqual(release.маршрут, .потребить)
  }

  func testStablePhysicalIDReplayCannotInsertTwice() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let input = physical(id: UUID(), order: 1, key: 12)
    let first = try адаптер.принять(input)
    XCTAssertEqual(first.вывод, .текст("q", источник: .fuma))
    XCTAssertEqual(first.маршрут, .потребить)

    let replay = try адаптер.принять(input)
    XCTAssertEqual(replay.статус, .повторСобытия)
    XCTAssertEqual(replay.вывод, .нет)
    XCTAssertEqual(replay.маршрут, .потребить)
    XCTAssertNil(replay.трасса)

    let снимок = адаптер.снимок()
    var восстановленныйАдаптер = try новыйАдаптер(восстанавливая: снимок)
    let replayAfterRestore = try восстановленныйАдаптер.принять(input)
    XCTAssertEqual(replayAfterRestore.статус, .повторСобытия)
    XCTAssertEqual(replayAfterRestore.вывод, .нет)
    XCTAssertEqual(replayAfterRestore.маршрут, .потребить)
  }

  func testNewFocusGenerationDropsOldLedgerAndSnapshotRestoresShortSequence() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    for order in 1...300 {
      let result = try адаптер.принять(physical(order: UInt64(order), key: 12))
      XCTAssertEqual(result.вывод, .текст("q", источник: .fuma))
    }

    подтвердитьФокус(&адаптер, фокусБ)
    let новоеСобытие = physical(focus: фокусБ, order: 1, key: 13)
    XCTAssertEqual(try адаптер.принять(новоеСобытие).вывод, .текст("w", источник: .fuma))
    let снимок = адаптер.снимок()
    XCTAssertEqual(снимок.фокус, фокусБ)
    XCTAssertEqual(снимок.физическиеСобытия.count, 1)

    var восстановленный = try новыйАдаптер(восстанавливая: снимок)
    let replay = try восстановленный.принять(новоеСобытие)
    XCTAssertEqual(replay.статус, .повторСобытия)
    XCTAssertEqual(replay.вывод, .нет)
  }

  func testBoundedLedgerRetainsHighWatermarkAfterOldIDIsEvicted() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let first = physical(order: 1, key: 12)
    _ = try адаптер.принять(first)
    for order in 2...300 {
      _ = try адаптер.принять(physical(order: UInt64(order), key: 12))
    }

    let снимок = адаптер.снимок()
    XCTAssertLessThanOrEqual(снимок.физическиеСобытия.count + снимок.событияIME.count, 256)
    XCTAssertEqual(снимок.последнийПорядок, 300)

    var восстановленный = try новыйАдаптер(восстанавливая: снимок)
    let oldReplay = try восстановленный.принять(first)
    XCTAssertEqual(oldReplay.статус, .неизвестно)
    XCTAssertEqual(oldReplay.вывод, .нет)
    XCTAssertNotEqual(oldReplay.маршрут, .потребить)
    XCTAssertEqual(восстановленный.снимок().последнийПорядок, 300)
  }

  func testReusedFocusTokenRequiresNewMonotonicGenerationAndRejectsOldReplay() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА, generation: 1)
    let firstGenerationEvent = physical(focus: фокусА, generation: 1, order: 1, key: 12)
    XCTAssertEqual(try адаптер.принять(firstGenerationEvent).вывод, .текст("q", источник: .fuma))

    подтвердитьФокус(&адаптер, фокусБ, generation: 2)
    XCTAssertEqual(try адаптер.принять(physical(focus: фокусБ, generation: 2, order: 1, key: 13)).вывод,
                   .текст("w", источник: .fuma))

    подтвердитьФокус(&адаптер, фокусА, generation: 3)
    let staleReplay = try адаптер.принять(firstGenerationEvent)
    XCTAssertEqual(staleReplay.статус, .неизвестно)
    XCTAssertEqual(staleReplay.вывод, .нет)
    XCTAssertNotEqual(staleReplay.маршрут, .потребить)

    let snapshot = адаптер.снимок()
    XCTAssertEqual(snapshot.максимальноеПоколениеФокуса, 3)
    var restored = try новыйАдаптер(восстанавливая: snapshot)
    XCTAssertFalse(restored.подтвердитьФокус(
      вОкне: окно,
      фокус: фокусА,
      поколение: 1,
      снимокМодификаторов: .пустое,
      моментНаблюденияНс: 10_000
    ))
    XCTAssertEqual(try restored.принять(physical(focus: фокусА, generation: 3, order: 1, key: 13)).вывод,
                   .текст("w", источник: .fuma))
  }

  func testStaleSameGenerationFocusSnapshotCannotRestoreShift() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let first = try адаптер.принять(physical(order: 1, key: 12))
    XCTAssertEqual(first.вывод, .текст("q", источник: .fuma))

    let принято = адаптер.подтвердитьФокус(
      вОкне: окно,
      фокус: фокусА,
      поколение: 1,
      снимокМодификаторов: СостояниеМодификаторовКлавиатуры(
        сдвигСлева: true,
        сдвигСправа: false,
        опцияСлева: false,
        опцияСправа: false,
        командаСлева: false,
        командаСправа: false,
        смешаннаяПоследовательность: false
      ),
      моментНаблюденияНс: 500
    )
    XCTAssertFalse(принято)

    let next = try адаптер.принять(physical(order: 2, key: 13))
    XCTAssertEqual(next.вывод, .текст("w", источник: .fuma))
    XCTAssertFalse(next.состояние.сдвигСлева)
  }

  func testReusedEventIDWithDifferentPayloadInvalidatesInput() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let id = UUID()
    _ = try адаптер.принять(physical(id: id, order: 1, key: 12))
    let conflict = try адаптер.принять(physical(id: id, order: 2, key: 13))
    XCTAssertEqual(conflict.статус, .неизвестно)
    XCTAssertEqual(conflict.вывод, .нет)
    XCTAssertEqual(conflict.маршрут, .неизвестен)
  }

  func testSystemShortcutPassesThroughAndUnknownOrderingDoesNotInsert() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let shortcut = try адаптер.принять(physical(order: 1, key: 12, handling: .системноеСочетание))
    XCTAssertEqual(shortcut.вывод, .нет)
    XCTAssertEqual(shortcut.маршрут, .пропустить)
    XCTAssertNotNil(shortcut.трасса)

    let uncertain = try адаптер.принять(physical(order: 2, key: 13, handling: .порядокНеизвестен))
    XCTAssertEqual(uncertain.статус, .неизвестно)
    XCTAssertEqual(uncertain.вывод, .нет)
    XCTAssertEqual(uncertain.маршрут, .неизвестен)
  }

  func testIMECommitRequiresActiveCompositionCurrentFocusAndEventCorrelation() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let composition = UUID()
    let physicalEvent = physical(
      order: 1,
      key: 12,
      handling: .ime(идентификаторКомпозиции: composition)
    )
    let physicalResult = try адаптер.принять(physicalEvent)
    XCTAssertEqual(physicalResult.вывод, .нет)
    XCTAssertEqual(physicalResult.маршрут, .пропустить)

    let commit = ime(
      composition: composition,
      kind: .зафиксировать("かな"),
      relatedPhysical: physicalEvent.идентификатор.rawValue,
      order: 2
    )
    let committed = адаптер.принять(commit)
    XCTAssertEqual(committed.вывод, .составленныйIMEТекст("かな"))
    XCTAssertEqual(committed.маршрут, .пропустить)
    XCTAssertNil(committed.трасса)

    let replay = адаптер.принять(commit)
    XCTAssertEqual(replay.вывод, .нет)
    XCTAssertEqual(replay.маршрут, .подавитьПовтор)
  }

  func testIMECommitWithoutActiveOrWithStaleFocusIsUnknown() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let noActive = адаптер.принять(ime(
      composition: UUID(), kind: .зафиксировать("かな"), relatedPhysical: UUID(), order: 1
    ))
    XCTAssertEqual(noActive.статус, .неизвестно)
    XCTAssertEqual(noActive.вывод, .нет)

    var адаптерПослеНовогоФокуса = try новыйАдаптер()
    подтвердитьФокус(&адаптерПослеНовогоФокуса, фокусБ)
    let composition = UUID()
    let physicalEvent = physical(focus: фокусБ, order: 1, key: 12, handling: .ime(идентификаторКомпозиции: composition))
    _ = try адаптерПослеНовогоФокуса.принять(physicalEvent)
    подтвердитьФокус(&адаптерПослеНовогоФокуса, фокусА, generation: 3)
    let stale = адаптерПослеНовогоФокуса.принять(ime(
      composition: composition,
      kind: .зафиксировать("かな"),
      relatedPhysical: physicalEvent.идентификатор.rawValue,
      focus: фокусБ,
      order: 2
    ))
    XCTAssertEqual(stale.статус, .неизвестно)
    XCTAssertEqual(stale.вывод, .нет)
    XCTAssertEqual(stale.маршрут, .неизвестен)
  }

  func testOutOfOrderIMECallbackCannotInsert() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let composition = UUID()
    let physicalEvent = physical(order: 1, key: 12, handling: .ime(идентификаторКомпозиции: composition))
    _ = try адаптер.принять(physicalEvent)
    let lateCommit = адаптер.принять(ime(
      composition: composition,
      kind: .зафиксировать("かな"),
      relatedPhysical: physicalEvent.идентификатор.rawValue,
      order: 3
    ))
    XCTAssertEqual(lateCommit.статус, .неизвестно)
    XCTAssertEqual(lateCommit.вывод, .нет)
    XCTAssertEqual(lateCommit.маршрут, .неизвестен)
  }

  func testUnsupportedLayoutInvalidatesModifiersUntilConfirmedSnapshot() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let shift = try адаптер.принять(physical(order: 1, key: 56))
    XCTAssertTrue(shift.состояние.сдвигСлева)

    let dvorak = try адаптер.принять(physical(order: 2, key: 56, phase: .отпускание, layout: .dvorak))
    XCTAssertEqual(dvorak.статус, .раскладкаНеПроверена)
    XCTAssertEqual(dvorak.маршрут, .неизвестен)

    let withoutSnapshot = try адаптер.принять(physical(order: 3, key: 12))
    XCTAssertEqual(withoutSnapshot.статус, .неизвестно)
    XCTAssertNil(withoutSnapshot.трасса)
    XCTAssertEqual(withoutSnapshot.вывод, .нет)

    let confirmed = try адаптер.принять(physical(
      order: 4,
      key: 12,
      modifiers: .пустое
    ))
    XCTAssertEqual(confirmed.вывод, .текст("q", источник: .fuma))
    XCTAssertFalse(confirmed.состояние.сдвигСлева)
  }

  func testForeignWindowAndFocusEventsAreRejected() throws {
    var адаптер = try новыйАдаптер()
    подтвердитьФокус(&адаптер, фокусА)
    let чужоеОкно = ИдентификаторОкнаВвода(rawValue: UUID())
    let foreign = physical(order: 1, key: 12)
    let foreignProvenance = СвидетельствоСобытияКлавиатуры(
      окно: чужоеОкно,
      фокус: фокусА,
      поколениеФокуса: 1,
      порядок: 1,
      моментНаблюденияНс: 1_000
    )
    let otherWindowEvent = ФизическоеСобытиеКлавиатуры(
      идентификатор: foreign.идентификатор,
      свидетельство: foreignProvenance,
      код: 12,
      фаза: .нажатие,
      повтор: false,
      раскладка: .qwerty,
      обработкаНативнымКраем: .fuma,
      снимокМодификаторов: nil
    )
    let rejected = try адаптер.принять(otherWindowEvent)
    XCTAssertEqual(rejected.статус, .проигнорировано)
    XCTAssertNil(rejected.трасса)

    let staleFocus = try адаптер.принять(physical(id: UUID(), focus: фокусБ, order: 1, key: 12))
    XCTAssertEqual(staleFocus.статус, .неизвестно)
    XCTAssertNil(staleFocus.трасса)
  }

  func testPinnedDefinitionAndTableRejectChangedRawBytes() throws {
    let definition = try Data(contentsOf: корень.appendingPathComponent("определение.json"))
    let table = try Data(contentsOf: корень.appendingPathComponent("таблица-раскладки.json"))
    XCTAssertEqual(Self.sha256(definition), "sha256:6deb8aed4b93b7d2528e26df041da8314b9a9cc433483a2c44611b7585f7b4ac")
    XCTAssertEqual(Self.sha256(table), "sha256:c914755f50b27da2b8d6d56cbdaaeb7db6f74ae2ab84d8f294eee4d6243f4ac3")
    XCTAssertThrowsError(try АдаптерВводаОкна(
      окно: окно,
      байтыОпределения: definition + Data([0]),
      байтыТаблицы: table,
      привязка: .keyboardQwertyV1
    ))
    XCTAssertThrowsError(try АдаптерВводаОкна(
      окно: окно,
      байтыОпределения: definition,
      байтыТаблицы: table + Data([0]),
      привязка: .keyboardQwertyV1
    ))
  }

  private static func sha256(_ bytes: Data) -> String {
    "sha256:" + SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
  }
}
