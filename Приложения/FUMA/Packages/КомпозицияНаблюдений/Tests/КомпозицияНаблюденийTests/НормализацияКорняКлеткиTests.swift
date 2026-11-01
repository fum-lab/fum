import Foundation
import Testing
import СнимокАгентскойЗадачи
@testable import КомпозицияНаблюдений

private struct ПодставнойПортСведенияКорней: ПортСведенияКорнейКлетки {
    var источник: СнимокКорневойКлетки?
    var цель: СнимокКорневойКлетки?
    var полныйОхват = true
    var намерения: [String: НамерениеСведенияКорней] = [:]
    var наблюдений = 0
    var применений = 0
    var сорватьПервоеПостнаблюдение = false
    var сорватьСледующееНаблюдение = false
    var изменитьЦельПослеПрименения = false
    var потерятьСвидетельствоЦелиПослеПрименения = false

    mutating func наблюдать(_ assignment: НазначениеКорневойКлетки,
                            отображение: ОтображениеКорнейКлетки) throws -> НаблюдениеКорнейКлетки {
        наблюдений += 1
        if сорватьСледующееНаблюдение {
            сорватьСледующееНаблюдение = false
            throw ОшибкаФикстуры.чтениеНедоступно
        }
        return .init(полныйОхват: полныйОхват,
            исходныйКорень: источник?.имяКорня == отображение.исходноеИмя ? источник : nil,
            целевойКорень: цель?.имяКорня == отображение.целевоеИмя ? цель : nil)
    }

    mutating func сохранитьНамерение(_ intent: НамерениеСведенияКорней) throws {
        if let existing = намерения[intent.идентификаторОперации], existing != intent {
            throw ОшибкаФикстуры.конфликтНамерения
        }
        намерения[intent.идентификаторОперации] = intent
    }

    mutating func прочитатьНамерение(операция: String) throws -> НамерениеСведенияКорней? {
        намерения[операция]
    }

    mutating func свестиКорни(_ intent: НамерениеСведенияКорней) throws -> ИсходСведенияПорта {
        guard намерения[intent.идентификаторОперации] == intent,
              источник == intent.ожидаемыйИсходныйКорень,
              цель == intent.ожидаемыйЦелевойКорень,
              полныйОхват else { throw ОшибкаФикстуры.дрейф }
        let existing = Dictionary(uniqueKeysWithValues: (цель?.записи ?? []).map { ($0.относительныйПуть, $0) })
        let conflicts = intent.ожидаемыйИсходныйКорень.записи.compactMap { record -> String? in
            guard let old = existing[record.относительныйПуть], old != record else { return nil }
            return record.относительныйПуть
        }
        if !conflicts.isEmpty { return .обнаруженыРазличающиесяЗаписи(пути: conflicts.sorted()) }
        цель = .init(назначение: intent.назначение, имяКорня: intent.отображение.целевоеИмя,
            поколение: "generation-merged", полныйОхват: true,
            проверкаВладения: .подтверждено(свидетельство: "fixture-owner-ref-readback"),
            записи: intent.ожидаемыеЗаписиЦели)
        источник = nil
        применений += 1
        if изменитьЦельПослеПрименения, let place = цель?.записи.firstIndex(where: { $0.вид == .файл }),
           let destination = цель {
            var records = destination.записи
            let old = records[place]
            records[place] = .init(относительныйПуть: old.относительныйПуть, вид: old.вид,
                содержимое: Data("{\"изменено\":true}\n".utf8), владелец: old.владелец, режим: old.режим)
            цель = .init(назначение: destination.назначение, имяКорня: destination.имяКорня,
                поколение: "generation-altered", полныйОхват: true,
                проверкаВладения: destination.проверкаВладения, записи: records)
        }
        if потерятьСвидетельствоЦелиПослеПрименения, let destination = цель {
            цель = .init(назначение: destination.назначение, имяКорня: destination.имяКорня,
                поколение: "generation-authority-unknown", полныйОхват: true,
                проверкаВладения: .неизвестно(причина: "fixture lost owner/ref attestation"),
                записи: destination.записи)
        }
        if сорватьПервоеПостнаблюдение { сорватьСледующееНаблюдение = true }
        return .эффектВозможен
    }
}

private enum ОшибкаФикстуры: Error {
    case чтениеНедоступно, дрейф, конфликтНамерения
}

private func назначениеКлетки(id: String = "cell-17", owner: String = "worker-17",
                              ref: String = "refs/heads/codex/worker-17/agents/cell-17") -> НазначениеКорневойКлетки {
    .init(идентификаторКлетки: id, владелец: owner, ветка: ref)
}

private func картаКорней(source: String = "Источники", target: String = "istochniki",
                         provenance: String = "Names/LinguisticKit; explicit mapping fixture") -> ОтображениеКорнейКлетки {
    .init(исходноеИмя: source, целевоеИмя: target, происхождение: provenance)
}

private let policy: ПолитикаСведенияКорней = .равныеДедуплицироватьНепересекающиесяПеренестиРазличающиесяСохранить

private func записиИсточника() -> [ЗаписьКорневойКлетки] {
    [
        .init(относительныйПуть: "Данные", вид: .каталог, содержимое: Data(), владелец: 501, режим: 0o755),
        .init(относительныйПуть: "Данные/сигнал.json", вид: .файл,
              содержимое: Data("{\"сигнал\":\"активен\",\"адрес\":\"Источники/URL\"}\n".utf8), владелец: 501, режим: 0o640),
        .init(относительныйПуть: "Ссылка", вид: .ссылка,
              содержимое: Data("Данные/сигнал.json".utf8), владелец: 501, режим: 0o777)
    ]
}

private func записиЦели() -> [ЗаписьКорневойКлетки] {
    [
        .init(относительныйПуть: "Данные", вид: .каталог, содержимое: Data(), владелец: 501, режим: 0o755),
        .init(относительныйПуть: "локальные/файл.bin", вид: .файл,
              содержимое: Data([0x00, 0xff, 0x41, 0x0a]), владелец: 501, режим: 0o600)
    ]
}

private func снимок(_ assignment: НазначениеКорневойКлетки, _ root: String,
                    generation: String = "generation-1", full: Bool = true,
                    proof: ПроверкаВладенияКорневойКлеткой = .подтверждено(свидетельство: "fixture-owner-ref"),
                    records: [ЗаписьКорневойКлетки]) -> СнимокКорневойКлетки {
    .init(назначение: assignment, имяКорня: root, поколение: generation,
          полныйОхват: full, проверкаВладения: proof, записи: records)
}

private func context(_ assignment: НазначениеКорневойКлетки, _ mapping: ОтображениеКорнейКлетки,
                     operation: String = "merge-cell-17", tick: Int64 = 1) -> КонтекстКомандыКлетки {
    .init(задача: .init(поставщик: "fuma", хост: "local", идентификатор: "task-17"),
        операция: operation, источникКоманды: .init(.команда, "cell-root-normalizer"),
        источникНаблюдения: .init(.интерфейс, "fixture-root-port"),
        область: КонтекстКомандыКлетки.областьДля(assignment, mapping, policy), первыйТакт: tick)
}

private func начальныйРедуктор() throws -> Редуктор {
    let task = Задача(поставщик: "fuma", хост: "local", идентификатор: "task-17")
    var reducer = try Редуктор(задача: task)
    try reducer.принять(.init(идентификатор: "main-plan-17", задача: task,
        источник: .init(.журнал, "plan"), такт: 0, область: "agent-task",
        факт: .значение(поле: .текущаяРабота, контекст: "", текст: "Continue primary processing plan")))
    try reducer.принять(.init(идентификатор: "cell-signal-17", задача: task,
        источник: .init(.интерфейс, "signal"), такт: 0, область: "agent-task",
        факт: .значение(поле: .ожидание, контекст: "", текст: "Normalize assigned cell roots")))
    return reducer
}

@Test func сводитДваКорняСохраняяДанныеИПродолжаетПлан() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let sourceRecords = записиИсточника()
    let targetRecords = записиЦели()
    let source = снимок(assignment, mapping.исходноеИмя, records: sourceRecords)
    let target = снимок(assignment, mapping.целевоеИмя, records: targetRecords)
    var normalizer = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(источник: source, цель: target))
    var reducer = try начальныйРедуктор()

    let result = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case let .сведено(next) = result else {
        Issue.record("Ожидалось сведение equal overlap и непересекающихся путей")
        return
    }
    #expect(next.целевойСнимок.имяКорня == "istochniki")
    #expect(next.целевойСнимок.записи == (sourceRecords + [targetRecords[1]]).sorted {
        $0.относительныйПуть.utf8.lexicographicallyPrecedes($1.относительныйПуть.utf8)
    })
    #expect(next.целевойСнимок.записи.first(where: { $0.относительныйПуть == "Данные/сигнал.json" })?.содержимое == sourceRecords[1].содержимое)
    #expect(next.целевойСнимок.записи.first(where: { $0.относительныйПуть == "Ссылка" })?.содержимое == Data("Данные/сигнал.json".utf8))
    #expect(next.идентификаторНамерения != nil)
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок.операции.first?.подтверждение != nil)
    #expect(reducer.снимок.значение(.текущаяРабота).кандидаты.map(\.значение) == ["Continue primary processing plan"])
    #expect(reducer.снимок.значение(.ожидание).кандидаты.map(\.значение) == ["Normalize assigned cell roots"])
    #expect(reducer.снимок.наблюдения.last?.исходныйФакт.contains(next.идентификаторНамерения!) == true)
    #expect(reducer.снимок.наблюдения.last?.исходныйФакт.contains(next.отпечатокЦелевогоКорня) == true)

    let saved = reducer.снимок
    let repeated = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .безИзменений = repeated else {
        Issue.record("Повторное наблюдение преобразованной пары должно быть no-op")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок == saved)
}

@Test func различающаясяЗаписьСохраняетОбаКорняИНеПодтверждаетЭффект() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let source = снимок(assignment, mapping.исходноеИмя, records: записиИсточника())
    var targetRecords = записиЦели()
    targetRecords.append(.init(относительныйПуть: "Данные/сигнал.json", вид: .файл,
        содержимое: Data("{\"иная\":true}\n".utf8), владелец: 501, режим: 0o600))
    let target = снимок(assignment, mapping.целевоеИмя, records: targetRecords)
    var normalizer = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(источник: source, цель: target))
    var reducer = try начальныйРедуктор()
    let before = reducer.снимок
    let result = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case let .нерешённаяКоллизия(paths, observation) = result else {
        Issue.record("Разные версии одного пути должны оставлять оба корня без записи")
        return
    }
    #expect(paths == ["Данные/сигнал.json"])
    #expect(observation.исходныйКорень == source)
    #expect(observation.целевойКорень == target)
    #expect(normalizer.состояниеПорта.применений == 0)
    #expect(normalizer.состояниеПорта.намерения.isEmpty)
    #expect(reducer.снимок == before)
}

@Test func файлПротивКаталогаСохраняетОбаКорня() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let sourceRecord = ЗаписьКорневойКлетки(относительныйПуть: "Дерево", вид: .файл,
        содержимое: Data([0x7f, 0x00]), владелец: 501, режим: 0o600)
    let targetParent = ЗаписьКорневойКлетки(относительныйПуть: "Дерево", вид: .каталог,
        содержимое: Data(), владелец: 501, режим: 0o755)
    let targetRecord = ЗаписьКорневойКлетки(относительныйПуть: "Дерево/дочерний.json", вид: .файл,
        содержимое: Data("{}\n".utf8), владелец: 501, режим: 0o640)
    let source = снимок(assignment, mapping.исходноеИмя, records: [sourceRecord])
    let target = снимок(assignment, mapping.целевоеИмя, records: [targetParent, targetRecord])
    var normalizer = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(источник: source, цель: target))
    var reducer = try начальныйРедуктор()
    let result = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case let .нерешённаяКоллизия(paths, observation) = result else {
        Issue.record("Структурное пересечение file/directory не должно затирать стороны")
        return
    }
    #expect(paths == ["Дерево"])
    #expect(observation.исходныйКорень == source)
    #expect(observation.целевойКорень == target)
    #expect(normalizer.состояниеПорта.применений == 0)
    #expect(normalizer.состояниеПорта.намерения.isEmpty)
}

@Test func unknownПослеВозможногоЭффектаСначалаПовторноНаблюдаетИНеПовторяетApply() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let port = ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя, records: записиИсточника()),
        цель: снимок(assignment, mapping.целевоеИмя, records: записиЦели()),
        сорватьПервоеПостнаблюдение: true)
    var normalizer = НормализаторКорнейКлетки(порт: port)
    var reducer = try начальныйРедуктор()
    let first = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = first else {
        Issue.record("Потеря post-observation оставляет исход UNKNOWN")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    let recovery = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .сведено = recovery else {
        Issue.record("Повторное наблюдение точной целевой инвентаризации может подтвердить исход")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок.операции.first?.подтверждение != nil)
}

@Test func изменённаяЦельПослеUnknownНеПодтверждается() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let port = ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя, records: записиИсточника()),
        цель: снимок(assignment, mapping.целевоеИмя, records: записиЦели()),
        сорватьПервоеПостнаблюдение: true, изменитьЦельПослеПрименения: true)
    var normalizer = НормализаторКорнейКлетки(порт: port)
    var reducer = try начальныйРедуктор()
    let first = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = first else {
        Issue.record("Изменённая после возможного эффекта цель остаётся UNKNOWN")
        return
    }
    let second = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .конфликт = second else {
        Issue.record("Отличающийся readback не подтверждает pinned intent")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок.операции.first?.подтверждение == nil)
}

@Test func неизвестноеСвидетельствоВладельцаНаПостнаблюденииНеПодтверждает() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let port = ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя, records: записиИсточника()),
        цель: снимок(assignment, mapping.целевоеИмя, records: записиЦели()),
        потерятьСвидетельствоЦелиПослеПрименения: true)
    var normalizer = НормализаторКорнейКлетки(порт: port)
    var reducer = try начальныйРедуктор()
    let result = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = result else {
        Issue.record("Точный inventory без post-owner/ref attestation не подтверждает эффект")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок.операции.first?.подтверждение == nil)
    let recovery = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = recovery else {
        Issue.record("Без свидетельства владельца/ref UNKNOWN сохраняется")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 1)
    #expect(reducer.снимок.операции.first?.подтверждение == nil)
}

@Test func чужойВладелецНеполныйОхватИНедопустимыйRefНеМеняютКорни() throws {
    let assignment = назначениеКлетки()
    let mapping = картаКорней()
    let source = снимок(assignment, mapping.исходноеИмя, records: записиИсточника())
    let foreign = назначениеКлетки(id: "other-cell", owner: "other-owner")
    var normalizer = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(
        источник: source, цель: снимок(foreign, mapping.целевоеИмя, records: записиЦели())))
    var reducer = try начальныйРедуктор()
    let result = try normalizer.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .конфликт = result else {
        Issue.record("Целевой корень другого владельца должен конфликтовать")
        return
    }
    #expect(normalizer.состояниеПорта.применений == 0)

    var partial = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя, full: false, records: записиИсточника())))
    let partialResult = try partial.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = partialResult else {
        Issue.record("Частичный inventory остаётся UNKNOWN")
        return
    }
    #expect(partial.состояниеПорта.намерения.isEmpty)
    #expect(partial.состояниеПорта.применений == 0)

    var unknownOwner = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя,
            proof: .неизвестно(причина: "owner/ref authority unavailable"), records: записиИсточника())))
    let ownerResult = try unknownOwner.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = ownerResult else {
        Issue.record("Неизвестное свидетельство owner/ref остаётся UNKNOWN")
        return
    }
    #expect(unknownOwner.состояниеПорта.намерения.isEmpty)
    #expect(unknownOwner.состояниеПорта.применений == 0)

    var escapedRecords = записиИсточника()
    escapedRecords[2] = .init(относительныйПуть: "Ссылка", вид: .ссылка,
        содержимое: Data("../outside".utf8), владелец: 501, режим: 0o777)
    var escaped = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(
        источник: снимок(assignment, mapping.исходноеИмя, records: escapedRecords)))
    let escapedResult = try escaped.выполнить(назначение: assignment, отображение: mapping,
        политика: policy, контекст: context(assignment, mapping), редуктор: &reducer)
    guard case .неизвестен = escapedResult else {
        Issue.record("Ссылка, выходящая за корень клетки, не разрешает сведение")
        return
    }
    #expect(escaped.состояниеПорта.намерения.isEmpty)
    #expect(escaped.состояниеПорта.применений == 0)

    for ref in ["refs/heads/codex/bad@{name}", "refs/heads/codex/name.lock"] {
        let bad = назначениеКлетки(ref: ref)
        var untouched = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней())
        var freshReducer = try начальныйРедуктор()
        var rejected = false
        do {
            _ = try untouched.выполнить(назначение: bad, отображение: mapping, политика: policy,
                контекст: context(bad, mapping), редуктор: &freshReducer)
        } catch ОшибкаСведенияКлетки.неверноеНазначениеИлиОтображение { rejected = true }
        #expect(rejected)
        #expect(untouched.состояниеПорта.наблюдений == 0)
    }
}

@Test func областиИнъективныИОграниченныйКонтекстПроверяетсяДоIntent() throws {
    let mapping = картаКорней()
    let first = назначениеКлетки(id: "a:b", owner: "c")
    let second = назначениеКлетки(id: "a", owner: "b:c")
    #expect(КонтекстКомандыКлетки.областьДля(first, mapping, policy)
        != КонтекстКомандыКлетки.областьДля(second, mapping, policy))
    #expect(назначениеКлетки().ветка.hasPrefix("refs/heads/codex/"))

    let assignment = назначениеКлетки()
    let source = снимок(assignment, mapping.исходноеИмя, records: записиИсточника())
    let target = снимок(assignment, mapping.целевоеИмя, records: записиЦели())
    var reducer = try начальныйРедуктор()
    for index in 0..<251 {
        try reducer.принять(.init(идентификатор: "clock-\(index)", задача: reducer.снимок.задача,
            источник: .init(.журнал, "tick"), такт: Int64(index + 1), факт: .время))
    }
    var normalizer = НормализаторКорнейКлетки(порт: ПодставнойПортСведенияКорней(источник: source, цель: target))
    let before = reducer.снимок
    var rejected = false
    do {
        _ = try normalizer.выполнить(назначение: assignment, отображение: mapping, политика: policy,
            контекст: context(assignment, mapping, tick: 252), редуктор: &reducer)
    } catch ОшибкаСведенияКлетки.неверныйКонтекстРедуктора { rejected = true }
    #expect(rejected)
    #expect(normalizer.состояниеПорта.намерения.isEmpty)
    #expect(normalizer.состояниеПорта.применений == 0)
    #expect(reducer.снимок == before)
}
