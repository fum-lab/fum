import Foundation
import Observation
import SwiftUI
import ЦиклОператора

@MainActor
@Observable
private final class МодельОкна {
    struct ЗаписьИстории: Identifiable {
        let id: UUID
        let вход: String
        let определение: String
        var исход: String

        var предложено: String { "Предложено: вход «\(вход)» · программа: \(определение)" }
    }

    var вход = "ёж"
    var определение = """
    {
      "схема": "fum.определение-оператора.1",
      "идентификатор": "prefix-example",
      "версия": 1,
      "правила": [],
      "шаги": [
        {
          "идентификатор": "добавить-префикс",
          "оператор": "префикс",
          "аргументы": { "текст": "FUM: " }
        }
      ]
    }
    """
    var состояние = "Готово к одному явному шагу"
    var выполняется = false
    var история: [ЗаписьИстории] = []

    private let цикл = ЦиклОператора()

    func выполнитьОдинШаг() {
        guard !выполняется else { return }
        let запись = ЗаписьИстории(
            id: UUID(),
            вход: вход,
            определение: определение,
            исход: "Выполнение не завершено"
        )
        история.insert(запись, at: 0)
        if история.count > 20 { история.removeLast() }
        выполняется = true
        состояние = "Исполняется один шаг…"

        Task {
            do {
                let результат = try await цикл.выполнитьОдинШаг(вход: запись.вход, определение: запись.определение)
                обновить(id: запись.id, исход: "Выполнено: \(результат.текст)")
                состояние = "Шаг завершён · \(результат.выполненоОпераций) операций · \(результат.хэшНаблюдения)"
            } catch {
                let описание = error.localizedDescription
                обновить(id: запись.id, исход: "Ошибка: \(описание)")
                состояние = "Ошибка шага: \(описание)"
            }
            выполняется = false
        }
    }

    private func обновить(id: UUID, исход: String) {
        guard let номер = история.firstIndex(where: { $0.id == id }) else { return }
        история[номер].исход = исход
    }
}

@main
@MainActor
private struct ПриложениеМинимальногоИнтерфейсаFUMA: App {
    var body: some Scene {
        WindowGroup("FUMA · один шаг") {
            ГлавноеОкно()
                .frame(minWidth: 680, minHeight: 620)
        }
    }
}

@MainActor
private struct ГлавноеОкно: View {
    @State private var модель = МодельОкна()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Цикл FUMA")
                .font(.largeTitle.bold())
            LabeledContent("Состояние", value: модель.состояние)
                .textSelection(.enabled)

            Text("Программа · ровно один простой оператор")
                .font(.headline)
            TextEditor(text: $модель.определение)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 230)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))

            TextField("Текстовый вход", text: $модель.вход)
                .textFieldStyle(.roundedBorder)
            Button("Выполнить один шаг", action: модель.выполнитьОдинШаг)
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(модель.выполняется)

            Text("История")
                .font(.headline)
            List(модель.история) { запись in
                VStack(alignment: .leading, spacing: 4) {
                    Text(запись.предложено)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(запись.исход)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 3)
            }
        }
        .padding(20)
    }
}
