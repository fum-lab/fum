import Foundation

private struct Observation {
    let id: String
    let result: String
    let owner: String
    let source: String
    let evidence: String
    let state: String
    let eventTime: Date?
    let rawEventTime: String?
}

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("Ошибка: \(message)\n").utf8))
    exit(2)
}

private func object(_ value: Any?, _ name: String) -> [String: Any] {
    guard let value = value as? [String: Any] else { fail("ожидался объект \(name)") }
    return value
}

private func string(_ value: Any?, _ name: String) -> String {
    guard let value = value as? String, !value.isEmpty else { fail("ожидалась непустая строка \(name)") }
    return value
}

private func timestamp(_ value: String, _ name: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    guard let date = formatter.date(from: value) else { fail("неверное время ISO 8601 в \(name): \(value)") }
    return date
}

private func render(_ source: [String: Any]) -> [String: Any] {
    guard string(source["схема"], "схема") == "fum.daily-summary-input.v1" else {
        fail("неподдерживаемая схема входа")
    }
    let run = object(source["запуск"], "запуск")
    let window = object(source["окно"], "окно")
    let startText = string(window["начало"], "окно.начало")
    let endText = string(window["конец"], "окно.конец")
    let start = timestamp(startText, "окно.начало")
    let end = timestamp(endText, "окно.конец")
    guard end.timeIntervalSince(start) == 86_400 else { fail("окно должно длиться ровно 86400 секунд") }
    guard end > start else { fail("конец окна должен быть позже начала") }
    let launchText = string(run["время_запуска"], "запуск.время_запуска")
    _ = timestamp(launchText, "запуск.время_запуска")
    let timezone = string(run["часовой_пояс_отображения"], "запуск.часовой_пояс_отображения")
    guard let observations = source["наблюдения"] as? [[String: Any]] else { fail("ожидался массив наблюдений") }

    var included: [Observation] = []
    var unresolved: [[String: Any]] = []
    for item in observations {
        let id = string(item["идентификатор"], "наблюдение.идентификатор")
        let result = string(item["результат"], "наблюдение.результат")
        let owner = string(item["владелец"], "наблюдение.владелец")
        let origin = string(item["источник"], "наблюдение.источник")
        let evidence = string(item["свидетельство"], "наблюдение.свидетельство")
        let state = string(item["состояние"], "наблюдение.состояние")
        guard ["CONFIRMED", "PARTIAL", "BLOCKED", "UNKNOWN", "NOT_APPLICABLE"].contains(state) else {
            fail("неизвестное состояние у \(id)")
        }
        func unresolvedRecord(_ reason: String) -> [String: Any] {
            ["идентификатор": id, "причина": reason, "результат": result, "владелец": owner,
             "источник": origin, "свидетельство": evidence, "состояние": state]
        }
        guard let rawTime = item["время_события"] as? String else {
            unresolved.append(unresolvedRecord("время события не подтверждено"))
            continue
        }
        let eventDate = timestamp(rawTime, "наблюдение.время_события")
        guard eventDate >= start && eventDate < end else {
            unresolved.append(unresolvedRecord(eventDate == end ? "событие на исключённой правой границе окна" : "событие вне окна"))
            continue
        }
        included.append(Observation(id: id, result: result, owner: owner, source: origin, evidence: evidence, state: state, eventTime: eventDate, rawEventTime: rawTime))
    }
    included.sort {
        if $0.eventTime! == $1.eventTime! { return $0.id < $1.id }
        return $0.eventTime! < $1.eventTime!
    }
    unresolved.sort { ( $0["идентификатор"] as? String ?? "") < ($1["идентификатор"] as? String ?? "") }

    let results: [[String: Any]] = included.map {
        ["идентификатор": $0.id, "время_события": $0.rawEventTime!, "результат": $0.result,
         "владелец": $0.owner, "исходная_ветка_или_ссылка": $0.source,
         "свидетельство_проверки": $0.evidence, "состояние": $0.state]
    }
    let baseCoverage = object(source["покрытие_источников"], "покрытие_источников")
    let coverageState = string(baseCoverage["состояние"], "покрытие_источников.состояние")
    let finalCoverage = (coverageState == "CONFIRMED" && unresolved.isEmpty) ? "CONFIRMED" : "PARTIAL"
    let receipt = string(source["происхождение"], "происхождение")
    return [
        "схема": "fum.ежедневная-сводка.1",
        "запуск": ["время_запуска": launchText, "начало_окна": startText, "конец_окна": endText,
                   "границы": "[начало, конец)", "часовой_пояс_отображения": timezone],
        "покрытие_источников": ["ожидалось": baseCoverage["ожидалось"] ?? "не указано",
                                  "наблюдалось": results.count, "отсутствует": unresolved,
                                  "состояние": finalCoverage],
        "результаты": results,
        "проверки": source["проверки"] as? [[String: Any]] ?? [],
        "доставка": source["доставка"] as? [[String: Any]] ?? [],
        "измерения": source["измерения"] as? [[String: Any]] ?? [],
        "блокеры": source["блокеры"] as? [[String: Any]] ?? [],
        "следующие_шаги": source["следующие_шаги"] as? [[String: Any]] ?? [],
        "происхождение": receipt
    ]
}

guard CommandLine.arguments.count == 2 else {
    fail("использование: swift sobratj-svodku.swift <вход.json>")
}
let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let inputData = try? Data(contentsOf: inputURL) else { fail("не удалось прочитать входной JSON") }
guard let input = try? JSONSerialization.jsonObject(with: inputData) else { fail("вход не является корректным JSON") }
let output = render(object(input, "корень"))
guard let encoded = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) else {
    fail("не удалось сериализовать сводку")
}
FileHandle.standardOutput.write(encoded)
FileHandle.standardOutput.write(Data([0x0A]))
