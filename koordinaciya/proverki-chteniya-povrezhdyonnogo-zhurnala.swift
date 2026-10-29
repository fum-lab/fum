import Foundation
import Testing
@testable import KoordinaciyaJSONLReader

struct ПроверкиЧтенияПовреждённогоЖурнала {
    private let rootUUID = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"

    @Test("повреждённая середина сохраняет смещения и соседние события")
    func повреждённаяСерединаНеУдаляетСоседей() {
        let first = terminated(event(order: 1, id: "first"))
        let damaged = terminated("{broken-json")
        let last = terminated(event(order: 3, id: "last"))
        let input = concatenate([first, damaged, last])

        let result = ЧтениеЖурналаJSONL.разобрать(
            байты: input,
            ожидаемыйКорневойUUID: rootUUID
        )

        #expect(result.состояние == .повреждён)
        #expect(result.полноеПокрытие)
        #expect(result.события.map(\.номерСтроки) == [1, 3])
        #expect(result.события.map(\.идентификатор) == ["first", "last"])
        #expect(result.повреждённыеДиапазоны.count == 1)
        let повреждение = result.повреждённыеДиапазоны.first
        #expect(повреждение?.номерСтроки == 2)
        #expect(повреждение?.диапазон.начало == first.count)
        #expect(повреждение?.диапазон.конец == first.count + damaged.count)
        #expect(повреждение?.причины.contains(.некорректныйJSON) == true)
    }

    @Test("валидный JSON без конечного LF остаётся повреждённым хвостом")
    func неполныйХвостНеСчитаетсяСобытием() {
        let first = terminated(event(order: 1, id: "first"))
        let tail = Data(event(order: 2, id: "tail").utf8)
        let input = concatenate([first, tail])

        let result = ЧтениеЖурналаJSONL.разобрать(
            байты: input,
            ожидаемыйКорневойUUID: rootUUID
        )

        #expect(result.состояние == .повреждён)
        #expect(result.полноеПокрытие)
        #expect(result.события.map(\.идентификатор) == ["first"])
        #expect(result.повреждённыеДиапазоны.count == 1)
        let повреждение = result.повреждённыеДиапазоны.first
        #expect(повреждение?.номерСтроки == 2)
        #expect(повреждение?.диапазон.начало == first.count)
        #expect(повреждение?.диапазон.конец == input.count)
        #expect(повреждение?.телоЯвляетсяJSON == true)
        #expect(повреждение?.причины.contains(.незавершённаяПоследняяЗапись) == true)
    }

    @Test("полная последняя запись после повреждения не теряется")
    func валидноеПоследнееСобытиеОстаётсяВИнвентаре() {
        let damaged = terminated("{not-json}")
        let last = terminated(event(order: 1, id: "last-after-damage"))
        let input = concatenate([damaged, last])

        let result = ЧтениеЖурналаJSONL.разобрать(
            байты: input,
            ожидаемыйКорневойUUID: rootUUID
        )

        #expect(result.события.count == 1)
        let lastEvent = result.события.first
        let damagedRange = result.повреждённыеДиапазоны.first
        #expect(lastEvent?.номерСтроки == 2)
        #expect(lastEvent?.идентификатор == "last-after-damage")
        #expect(damagedRange?.диапазон.начало == 0)
        #expect(damagedRange?.диапазон.конец == damaged.count)
        #expect(result.полноеПокрытие)
        #expect(result.состояние == .повреждён)
    }

    @Test("ограничение байтов обозначает неизвестный остаток, а не отсутствие событий")
    func пределБайтовСохраняетНеизвестныйХвост() {
        let first = terminated(event(order: 1, id: "first"))
        let second = terminated(event(order: 2, id: "second"))
        let input = concatenate([first, second])

        let result = ЧтениеЖурналаJSONL.разобрать(
            байты: input,
            ожидаемыйКорневойUUID: rootUUID,
            максимумБайт: first.count + 2,
            максимумЗаписей: 20
        )

        #expect(result.полноеПокрытие == false)
        #expect(result.состояние == .повреждён)
        #expect(result.размерВхода == input.count)
        #expect(result.байтПросмотрено == first.count + 2)
        #expect(result.повреждённыеДиапазоны.contains { $0.причины.contains(.превышенПределБайт) })
    }

    private func event(order: Int, id: String) -> String {
        "{\"порядок\":\(order),\"идентификатор\":\"\(id)\",\"корневойUUID\":\"\(rootUUID)\",\"время\":\"2026-10-29T00:00:00Z\",\"вид\":\"test\",\"свидетельство\":\"fixture\"}"
    }

    private func terminated(_ value: String) -> Data {
        Data((value + "\n").utf8)
    }

    private func concatenate(_ values: [Data]) -> Data {
        values.reduce(into: Data()) { result, value in
            result.append(value)
        }
    }
}
