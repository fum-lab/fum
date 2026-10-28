#!/usr/bin/env swift
import Foundation

func reject(_ message: String) -> Never {
    print("ОТКАЗ: \(message)")
    exit(1)
}

guard CommandLine.arguments.count == 2 else {
    reject("нужен путь к JSON очереди")
}

do {
    let queueURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let data = try Data(contentsOf: queueURL)
    guard let queue = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        reject("корень JSON должен быть объектом")
    }
    guard queue["схема"] as? String == "fum.очередь-направлений.1" else {
        reject("неизвестная схема очереди")
    }

    let states = [
        "получено", "разобрано", "назначено", "начато",
        "передано", "принято", "применено"
    ]
    guard let progression = queue["порядок_состояний"] as? [String],
          progression == states else {
        reject("изменился закреплённый порядок состояний")
    }
    guard let meanings = queue["значения_состояний"] as? [String: String],
          Set(meanings.keys) == Set(states),
          meanings.values.allSatisfy({ !$0.isEmpty }) else {
        reject("каждое состояние должно иметь явное значение")
    }

    guard let transitionContract = queue["переходы"] as? [String: Any],
          let edges = transitionContract["допустимые"] as? [[String]] else {
        reject("отсутствуют допустимые переходы")
    }
    let expectedEdges = zip(states, states.dropFirst()).map { [$0.0, $0.1] }
    guard edges == expectedEdges else {
        reject("допустимы только соседние переходы")
    }

    func isAllowed(_ source: String, _ destination: String) -> Bool {
        guard let index = states.firstIndex(of: source), index + 1 < states.count else {
            return false
        }
        return states[index + 1] == destination
    }

    guard let probes = transitionContract["пробы"] as? [[String: Any]],
          probes.count == 2 else {
        reject("нужны ровно две контрольные пробы")
    }
    let expectedProbes: [(String, String, Bool)] = [
        ("начато", "передано", true),
        ("начато", "принято", false)
    ]
    for (probe, expected) in zip(probes, expectedProbes) {
        guard let source = probe["от"] as? String,
              let destination = probe["к"] as? String,
              let expectedResult = probe["ожидается"] as? Bool,
              source == expected.0,
              destination == expected.1,
              expectedResult == expected.2,
              isAllowed(source, destination) == expectedResult else {
            reject("пример разрешённого или запрещённого перехода не совпал")
        }
    }

    guard let items = queue["элементы"] as? [[String: Any]], !items.isEmpty else {
        reject("очередь должна содержать элементы")
    }
    let requiredTextFields = [
        "id", "владелец", "приоритет", "потребитель",
        "следующее_действие", "блокер", "условие_снятия_блокера"
    ]
    for item in items {
        for field in requiredTextFields {
            guard let value = item[field] as? String, !value.isEmpty else {
                reject("пустое или отсутствующее поле \(field)")
            }
        }
        guard let sources = item["источник"] as? [String], !sources.isEmpty,
              let basis = item["основание_обзора"] as? [String], !basis.isEmpty,
              let history = item["достигнутые_этапы"] as? [String],
              let current = item["текущий_этап"] as? String,
              !history.isEmpty,
              Array(states.prefix(history.count)) == history,
              history.last == current else {
            reject("история элемента не является непрерывным префиксом состояний")
        }
    }

    print("Проверка пройдена: элементов \(items.count); допустимый переход принят; переход с пропуском отвергнут.")
} catch {
    reject("не удалось прочитать очередь: \(error.localizedDescription)")
}
