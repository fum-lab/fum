import Foundation
import Testing
import ЭталонКлавиатуры
@testable import ЦиклОператора

@MainActor
private func создатьПодтверждённогоВладельца(
    окно: UUID,
    фокус: UUID,
    поколение: UInt64 = 1
) throws -> ВладелецТекстаСценыФУМА {
    let owner = ВладелецТекстаСценыФУМА()
    try owner.установитьОкно(окно)
    try owner.подтвердитьФокус(окно: окно, фокус: фокус, поколение: поколение)
    return owner
}

@Suite("Владелец текста и сцены окна", .serialized)
struct ПроверкиВладельцаТекстаСцены {
    @Test("UI projection replaces canonically equivalent text when UTF-8 bytes differ")
    func точнаяПроекцияUnicode() {
        let decomposed = "e\u{301}"
        let composed = "é"
        let update = ПроекцияТекстаОкнаФУМА.значениеДляОбновления(
            текущее: decomposed,
            авторитетное: composed
        )
        #expect(update?.utf8.elementsEqual(composed.utf8) == true)
        #expect(ПроекцияТекстаОкнаФУМА.значениеДляОбновления(
            текущее: composed,
            авторитетное: composed
        ) == nil)
    }

    @Test("Один вход атомарно меняет текст и сцены, повтор отвергается")
    @MainActor
    func причинныйПереходИПовтор() throws {
        let window = UUID()
        let focus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focus)
        let event = UUID()
        let layerRevision = owner.снимок.ревизияСцены

        let result = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: focus,
            поколениеФокуса: 1,
            идентификаторСобытия: event,
            порядок: 1,
            текст: "a",
            выделениеUTF16: 1..<1
        )
        #expect(result == .изменено)
        #expect(owner.снимок.текст == "a")
        #expect(owner.снимок.ревизияТекста == 1)
        #expect(owner.снимок.ревизияСцены == layerRevision + 1)
        #expect(owner.снимок.последнийИзменившийТекстВвод == event)
        #expect(owner.снимок.последнийВводСцены == event)

        let committed = owner.снимок
        do {
            _ = try owner.принять(
                идентификаторОкна: window,
                идентификаторФокуса: focus,
                поколениеФокуса: 1,
                идентификаторСобытия: event,
                порядок: 2,
                текст: "ab",
                выделениеUTF16: 2..<2
            )
            Issue.record("Повтор UUID неожиданно принят.")
        } catch ОшибкаПереходаКадра.повтор { } catch {
            Issue.record("Получен неожиданный отказ для повтора: \(String(reflecting: error))")
        }
        #expect(owner.снимок == committed)
    }

    @Test("Пустой результат учитывает вход без выдуманной смены ревизий")
    @MainActor
    func входБезИзменений() throws {
        let window = UUID()
        let focus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focus)
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: focus,
            поколениеФокуса: 1,
            идентификаторСобытия: UUID(),
            порядок: 1,
            текст: "",
            выделениеUTF16: 0..<0
        )
        let before = owner.снимок
        let result = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: focus,
            поколениеФокуса: 1,
            идентификаторСобытия: UUID(),
            порядок: 2,
            текст: "",
            выделениеUTF16: 0..<0
        )
        #expect(result == .безИзменений)
        #expect(owner.снимок.ревизияТекста == before.ревизияТекста)
        #expect(owner.снимок.ревизияСцены == before.ревизияСцены)
        #expect(owner.снимок.последнийВводСцены == before.последнийВводСцены)
    }

    @Test("UTF-8 различает канонически эквивалентные строки")
    @MainActor
    func точныеБайтыТекста() throws {
        let window = UUID()
        let focus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focus)
        let decomposed = "e\u{301}"
        let composed = "é"
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: focus,
            поколениеФокуса: 1,
            идентификаторСобытия: UUID(),
            порядок: 1,
            текст: decomposed,
            выделениеUTF16: 2..<2
        )
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: focus,
            поколениеФокуса: 1,
            идентификаторСобытия: UUID(),
            порядок: 2,
            текст: composed,
            выделениеUTF16: 1..<1
        )
        #expect(owner.снимок.ревизияТекста == 2)
        #expect(owner.снимок.текст.utf8.elementsEqual(composed.utf8))
    }

    @Test("Недопустимая граница UTF-16 не меняет authoritative snapshot")
    @MainActor
    func отказБезЧастичнойЗаписи() throws {
        let window = UUID()
        let focus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focus)
        let before = owner.снимок
        do {
            _ = try owner.принять(
                идентификаторОкна: window,
                идентификаторФокуса: focus,
                поколениеФокуса: 1,
                идентификаторСобытия: UUID(),
                порядок: 1,
                текст: "🙂",
                выделениеUTF16: 1..<1
            )
            Issue.record("Середина суррогатной пары неожиданно принята.")
        } catch ОшибкаПереходаКадра.неверноеВыделениеИлиРазмер { } catch {
            Issue.record("Получен неожиданный отказ для границы UTF-16: \(String(reflecting: error))")
        }
        #expect(owner.снимок == before)
    }

    @Test("Новый focus epoch сохраняет текст и ревизии, но начинает новый порядок")
    @MainActor
    func переходЭпохиФокуса() throws {
        let window = UUID()
        let firstFocus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: firstFocus)
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: firstFocus,
            поколениеФокуса: 1,
            идентификаторСобытия: UUID(),
            порядок: 1,
            текст: "a",
            выделениеUTF16: 1..<1
        )
        let secondFocus = UUID()
        try owner.подтвердитьФокус(окно: window, фокус: secondFocus, поколение: 2)
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: secondFocus,
            поколениеФокуса: 2,
            идентификаторСобытия: UUID(),
            порядок: 1,
            текст: "ab",
            выделениеUTF16: 2..<2
        )
        #expect(owner.снимок.текст == "ab")
        #expect(owner.снимок.ревизияТекста == 2)
        #expect(owner.снимок.ревизияСцены == 2)
    }
}

@Suite("Межэпоховая дедупликация ввода", .serialized)
struct ПроверкиДедупликацииМеждуФокусами {
    @Test("Смена focus generation не позволяет повторно применить известный UUID")
    @MainActor
    func повторПослеСменыФокуса() throws {
        let window = UUID()
        let firstFocus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: firstFocus)
        let acceptedEvent = UUID()
        _ = try owner.принять(
            идентификаторОкна: window,
            идентификаторФокуса: firstFocus,
            поколениеФокуса: 1,
            идентификаторСобытия: acceptedEvent,
            порядок: 1,
            текст: "a",
            выделениеUTF16: 1..<1
        )
        let secondFocus = UUID()
        try owner.подтвердитьФокус(окно: window, фокус: secondFocus, поколение: 2)
        let beforeReplay = owner.снимок
        do {
            _ = try owner.принять(
                идентификаторОкна: window,
                идентификаторФокуса: secondFocus,
                поколениеФокуса: 2,
                идентификаторСобытия: acceptedEvent,
                порядок: 1,
                текст: "ab",
                выделениеUTF16: 2..<2
            )
            Issue.record("Известный UUID повторно принят после смены focus generation.")
        } catch ОшибкаПереходаКадра.повтор { } catch {
            Issue.record("Получен неожиданный отказ для повтора между фокусами: \(String(reflecting: error))")
        }
        #expect(owner.снимок == beforeReplay)
    }

    @Test("Duplicate in a rejected new focus leaves old context order intact")
    @MainActor
    func повторНеСдвигаетКонтекст() throws {
        let window = UUID()
        let focusA = UUID()
        let focusB = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focusA)
        let reused = UUID()
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusA,
                              поколениеФокуса: 1, идентификаторСобытия: reused,
                              порядок: 1, текст: "a", выделениеUTF16: 1..<1)
        try owner.подтвердитьФокус(окно: window, фокус: focusB, поколение: 2)
        do {
            _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusB,
                                  поколениеФокуса: 2, идентификаторСобытия: reused,
                                  порядок: 1, текст: "b", выделениеUTF16: 1..<1)
            Issue.record("Повтор UUID в новом контексте неожиданно принят.")
        } catch ОшибкаПереходаКадра.повтор { } catch {
            Issue.record("Получен неожиданный отказ для повторного UUID: \(String(reflecting: error))")
        }
        let acceptedEvent = UUID()
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusB,
                              поколениеФокуса: 2, идентификаторСобытия: acceptedEvent,
                              порядок: 1, текст: "b", выделениеUTF16: 1..<1)
        #expect(owner.снимок.текст.utf8.elementsEqual("b".utf8))
        #expect(owner.снимок.последнийИзменившийТекстВвод == acceptedEvent)
        do {
            _ = try owner.принять(идентификаторОкна: UUID(), идентификаторФокуса: UUID(),
                                  поколениеФокуса: 1, идентификаторСобытия: UUID(),
                                  порядок: 1, текст: "c", выделениеUTF16: 1..<1)
            Issue.record("Событие от неустановленного окна неожиданно принято.")
        } catch ОшибкаПереходаКадра.устарело { } catch {
            Issue.record("Получен неожиданный отказ для неустановленного окна: \(String(reflecting: error))")
        }
        #expect(owner.снимок.текст.utf8.elementsEqual("b".utf8))
    }

    @Test("Invalid UTF-16 selection in a new focus is atomic for context and order")
    @MainActor
    func неверноеВыделениеНеСдвигаетКонтекст() throws {
        let window = UUID()
        let focusA = UUID()
        let focusB = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focusA)
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusA,
                              поколениеФокуса: 1, идентификаторСобытия: UUID(),
                              порядок: 1, текст: "a", выделениеUTF16: 1..<1)
        try owner.подтвердитьФокус(окно: window, фокус: focusB, поколение: 2)
        do {
            _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusB,
                                  поколениеФокуса: 2, идентификаторСобытия: UUID(),
                                  порядок: 1, текст: "🙂", выделениеUTF16: 1..<1)
            Issue.record("Невалидное выделение неожиданно принято.")
        } catch ОшибкаПереходаКадра.неверноеВыделениеИлиРазмер { } catch {
            Issue.record("Получен неожиданный отказ для UTF-16 выделения: \(String(reflecting: error))")
        }
        do {
            _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focusB,
                                  поколениеФокуса: 2, идентификаторСобытия: UUID(),
                                  порядок: 1, текст: "b", выделениеUTF16: 1..<1)
            Issue.record("Отклонённое выделение повредило переход следующего валидного события.")
        } catch {
            Issue.record("Валидный повторный переход после отказа неожиданно отклонён: \(String(reflecting: error))")
        }
        #expect(owner.снимок.текст.utf8.elementsEqual("b".utf8))
    }

    @Test("An older focus generation cannot replace the current generation")
    @MainActor
    func поколениеФокусаНеРегрессирует() throws {
        let window = UUID()
        let focus1 = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: focus1)
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focus1,
                              поколениеФокуса: 1, идентификаторСобытия: UUID(),
                              порядок: 1, текст: "a", выделениеUTF16: 1..<1)
        let focus2 = UUID()
        try owner.подтвердитьФокус(окно: window, фокус: focus2, поколение: 2)
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: focus2,
                              поколениеФокуса: 2, идентификаторСобытия: UUID(),
                              порядок: 1, текст: "ab", выделениеUTF16: 2..<2)
        do {
            try owner.подтвердитьФокус(окно: window, фокус: UUID(), поколение: 1)
            Issue.record("Старое поколение фокуса неожиданно принято.")
        } catch ОшибкаПереходаКадра.устарело { } catch {
            Issue.record("Получен неожиданный отказ для старого поколения: \(String(reflecting: error))")
        }
        #expect(owner.снимок.текст.utf8.elementsEqual("ab".utf8))
        #expect(owner.снимок.ревизияТекста == 2)
    }

    @Test("New window starts its own generation and rejects the old window")
    @MainActor
    func поколенияРаздельныПоОкнам() throws {
        let owner = ВладелецТекстаСценыФУМА()
        let firstWindow = UUID()
        let firstFocus = UUID()
        try owner.установитьОкно(firstWindow)
        try owner.подтвердитьФокус(окно: firstWindow, фокус: firstFocus, поколение: 2)
        _ = try owner.принять(идентификаторОкна: firstWindow, идентификаторФокуса: firstFocus,
                              поколениеФокуса: 2, идентификаторСобытия: UUID(),
                              порядок: 1, текст: "a", выделениеUTF16: 1..<1)

        let secondWindow = UUID()
        let secondFocus = UUID()
        try owner.установитьОкно(secondWindow)
        try owner.подтвердитьФокус(окно: secondWindow, фокус: secondFocus, поколение: 1)
        _ = try owner.принять(идентификаторОкна: secondWindow, идентификаторФокуса: secondFocus,
                              поколениеФокуса: 1, идентификаторСобытия: UUID(),
                              порядок: 1, текст: "ab", выделениеUTF16: 2..<2)
        do {
            _ = try owner.принять(идентификаторОкна: firstWindow, идентификаторФокуса: firstFocus,
                                  поколениеФокуса: 2, идентификаторСобытия: UUID(),
                                  порядок: 2, текст: "stale", выделениеUTF16: 5..<5)
            Issue.record("Событие старого окна неожиданно принято после перехода окна.")
        } catch ОшибкаПереходаКадра.устарело { } catch {
            Issue.record("Получен неожиданный отказ для старого окна: \(String(reflecting: error))")
        }
        #expect(owner.снимок.текст.utf8.elementsEqual("ab".utf8))
    }

    @Test("Focus no-op retains causal text and scene IDs across the epoch copy")
    @MainActor
    func noOpПослеСменыФокусаСохраняетПричины() throws {
        let window = UUID()
        let firstFocus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: firstFocus)
        let firstEvent = UUID()
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: firstFocus,
                              поколениеФокуса: 1, идентификаторСобытия: firstEvent,
                              порядок: 1, текст: "a", выделениеUTF16: 1..<1)

        let secondFocus = UUID()
        try owner.подтвердитьФокус(окно: window, фокус: secondFocus, поколение: 2)
        let result = try owner.принять(идентификаторОкна: window, идентификаторФокуса: secondFocus,
                                       поколениеФокуса: 2, идентификаторСобытия: UUID(),
                                       порядок: 1, текст: "a", выделениеUTF16: 1..<1)
        #expect(result == .безИзменений)
        #expect(owner.снимок.последнийИзменившийТекстВвод == firstEvent)
        #expect(owner.снимок.последнийВводСцены == firstEvent)
        #expect(owner.снимок.ревизияТекста == 1)
        #expect(owner.снимок.ревизияСцены == 1)
    }

    @Test("Focus selection-only transition keeps text cause and updates scene cause")
    @MainActor
    func выделениеПослеСменыФокусаСохраняетПричины() throws {
        let window = UUID()
        let firstFocus = UUID()
        let owner = try создатьПодтверждённогоВладельца(окно: window, фокус: firstFocus)
        let textEvent = UUID()
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: firstFocus,
                              поколениеФокуса: 1, идентификаторСобытия: textEvent,
                              порядок: 1, текст: "ab", выделениеUTF16: 2..<2)

        let secondFocus = UUID()
        try owner.подтвердитьФокус(окно: window, фокус: secondFocus, поколение: 2)
        let selectionEvent = UUID()
        _ = try owner.принять(идентификаторОкна: window, идентификаторФокуса: secondFocus,
                              поколениеФокуса: 2, идентификаторСобытия: selectionEvent,
                              порядок: 1, текст: "ab", выделениеUTF16: 1..<1)
        #expect(owner.снимок.последнийИзменившийТекстВвод == textEvent)
        #expect(owner.снимок.последнийВводСцены == selectionEvent)
        #expect(owner.снимок.ревизияТекста == 1)
        #expect(owner.снимок.ревизияСцены == 2)
        #expect(owner.снимок.выделениеUTF16 == 1..<1)
    }
}

@Suite("Стык с существующим оператором клавиатуры", .serialized)
struct ПроверкиРеальногоОператораКлавиатуры {
    @Test("Только закреплённый keycode 49 проходит как простой пробел")
    func политикаПробела() {
        #expect(ПолитикаИсточникаВводаФУМА.являетсяПоддерживаемойФизическойКлавишей(49))
        #expect(ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
            вид: .нажатие, код: 49, символСобытия: " ", модификаторы: .пустые,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false
        ))
        #expect(!ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
            вид: .нажатие, код: 49, символСобытия: " ",
            модификаторы: ФлагиМодификаторовТекстовогоВвода(сдвиг: true),
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false
        ))
        #expect(!ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
            вид: .нажатие, код: 49, символСобытия: " ",
            модификаторы: ФлагиМодификаторовТекстовогоВвода(опция: true),
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false
        ))
        #expect(!ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
            вид: .нажатие, код: 49, символСобытия: "x", модификаторы: .пустые,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false
        ))
    }

    @Test("Keycode 49 требует проверенный полный слой resource: отсутствующий и неверный отказывают")
    func ресурсПробелаFailClosed() {
        let missingKey = Data(#"{"текстовые_клавиши":{}}"#.utf8)
        let mismatchedShift = Data(
            #"{"текстовые_клавиши":{"49":{"базовый":" ","сдвиг":"x","опция":" "}}}"#.utf8
        )
        let candidates: [Data?] = [nil, missingKey, mismatchedShift]

        for candidate in candidates {
            let supported = ПолитикаИсточникаВводаФУМА.вычислитьПоддерживаемыеФизическиеКоды(
                изJSON: candidate
            )
            #expect(!supported.contains(49))
            #expect(!ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
                вид: .нажатие,
                код: 49,
                символСобытия: " ",
                модификаторы: .пустые,
                идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
                естьРазмеченнаяКомпозиция: false,
                разрешённыеКоды: supported
            ))
        }

        let matching = Data(
            #"{"текстовые_клавиши":{"49":{"базовый":" ","сдвиг":" ","опция":" "}}}"#.utf8
        )
        let supported = ПолитикаИсточникаВводаФУМА.вычислитьПоддерживаемыеФизическиеКоды(изJSON: matching)
        #expect(supported.contains(49))
        #expect(ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
            вид: .нажатие,
            код: 49,
            символСобытия: " ",
            модификаторы: .пустые,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false,
            разрешённыеКоды: supported
        ))
    }

    @Test("Существующий FUMA оператор возвращает пробел для закреплённого keycode 49")
    @MainActor
    func пробелЧерезОператор() throws {
        let keyboard = ВладелецКлавиатурногоАдаптера()
        let window = ИдентификаторОкнаВвода(rawValue: UUID())
        let confirmed = try keyboard.подтвердитьФокус(
            окно: window,
            фокус: ИдентификаторФокусаВвода(rawValue: UUID()),
            поколение: 1,
            снимокМодификаторов: .пустое,
            моментНаблюденияНс: 1
        )
        #expect(confirmed)
        let observation = try keyboard.обработатьПростуюКлавишу(
            код: 49, символСобытия: " ", повтор: false, моментНаблюденияНс: 2,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false, модификаторы: .пустые
        )
        guard let observation,
              case .текст(let text, источник: .fuma) = observation.результат.вывод else {
            Issue.record("Pinned оператор не вернул FUMA-пробел.")
            return
        }
        #expect(text.utf8.elementsEqual(" ".utf8))
        #expect(observation.событие.код == 49)
    }

    @Test("После отказа unsupported keydown следующий подтверждённый ввод принимается один раз")
    @MainActor
    func восстановлениеПослеОтказаКлавиши() throws {
        let keyboard = ВладелецКлавиатурногоАдаптера()
        let window = ИдентификаторОкнаВвода(rawValue: UUID())
        func confirm(_ generation: UInt64) throws {
            let confirmed = try keyboard.подтвердитьФокус(
                окно: window,
                фокус: ИдентификаторФокусаВвода(rawValue: UUID()),
                поколение: generation,
                снимокМодификаторов: .пустое,
                моментНаблюденияНс: generation
            )
            #expect(confirmed)
        }
        try confirm(1)
        let q = try keyboard.обработатьПростуюКлавишу(
            код: 12, символСобытия: "q", повтор: false, моментНаблюденияНс: 2,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false, модификаторы: .пустые
        )
        #expect(q?.событие.свидетельство.поколениеФокуса == 1)

        let shiftedSpace = ФлагиМодификаторовТекстовогоВвода(сдвиг: true)
        let rejected = try keyboard.обработатьПростуюКлавишу(
            код: 49, символСобытия: " ", повтор: false, моментНаблюденияНс: 3,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false, модификаторы: shiftedSpace
        )
        #expect(rejected == nil)

        try confirm(2)
        let r = try keyboard.обработатьПростуюКлавишу(
            код: 15, символСобытия: "r", повтор: false, моментНаблюденияНс: 4,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false, модификаторы: .пустые
        )
        #expect(r?.событие.свидетельство.поколениеФокуса == 2)
        #expect(r?.событие.свидетельство.порядок == 1)
        #expect(q?.событие.идентификатор != r?.событие.идентификатор)
    }

    @Test("Поздняя привязка старого view A не может затронуть новую привязку B")
    @MainActor
    func устаревшаяПривязкаОтсекается() {
        final class View {}
        let owner = ВладелецПривязкиВидаФУМА()
        let a = View()
        let b = View()
        let tokenA = owner.привязать(a)
        #expect(owner.являетсяТекущей(tokenA, для: a))

        let tokenB = owner.привязать(b)
        #expect(!owner.являетсяТекущей(tokenA, для: a))
        #expect(!owner.являетсяТекущей(tokenA, для: b))
        #expect(owner.являетсяТекущей(tokenB, для: b))
        #expect(owner.привязать(b) == tokenB)

        let weakOwner = ВладелецПривязкиВидаФУМА()
        var released: View? = View()
        let releasedToken = weakOwner.привязать(released!)
        released = nil
        let replacement = View()
        #expect(weakOwner.текущаяПривязка(для: replacement) == nil)
        let replacementToken = weakOwner.привязать(replacement)
        #expect(replacementToken != releasedToken)
    }

    @Test("Разрешённый результат существующего адаптера входит в одного владельца текста")
    @MainActor
    func адаптерКВладельцу() throws {
        let keyboard = ВладелецКлавиатурногоАдаптера()
        let window = ИдентификаторОкнаВвода(rawValue: UUID())
        let focus = ИдентификаторФокусаВвода(rawValue: UUID())
        let focusConfirmed = try keyboard.подтвердитьФокус(
            окно: window, фокус: focus, поколение: 1,
            снимокМодификаторов: .пустое, моментНаблюденияНс: 9
        )
        #expect(focusConfirmed)
        guard let observation = try keyboard.обработатьПростуюКлавишу(
            код: 12,
            символСобытия: "q",
            повтор: false,
            моментНаблюденияНс: 10,
            идентификаторИсточника: ПолитикаИсточникаВводаФУМА.идентификаторРаскладкиИсточника,
            естьРазмеченнаяКомпозиция: false,
            модификаторы: .пустые
        ) else {
            Issue.record("Существующий адаптер не вернул разрешённое событие q.")
            return
        }
        #expect(РешениеВводаКлавиатуры.классифицировать(observation.результат) == .применитьFUMA)
        guard case .текст(let text, источник: .fuma) = observation.результат.вывод else {
            Issue.record("Существующий адаптер вернул неподдержанный результат.")
            return
        }

        let owner = ВладелецТекстаСценыФУМА()
        let event = observation.событие
        let witness = event.свидетельство
        try owner.установитьОкно(witness.окно.rawValue)
        try owner.подтвердитьФокус(
            окно: witness.окно.rawValue,
            фокус: witness.фокус.rawValue,
            поколение: witness.поколениеФокуса
        )
        _ = try owner.принять(
            идентификаторОкна: witness.окно.rawValue,
            идентификаторФокуса: witness.фокус.rawValue,
            поколениеФокуса: witness.поколениеФокуса,
            идентификаторСобытия: event.идентификатор.rawValue,
            порядок: witness.порядок,
            текст: text,
            выделениеUTF16: (text as NSString).length..<(text as NSString).length
        )
        #expect(owner.снимок.текст == "q")
        #expect(owner.снимок.последнийИзменившийТекстВвод == event.идентификатор.rawValue)
    }
}
