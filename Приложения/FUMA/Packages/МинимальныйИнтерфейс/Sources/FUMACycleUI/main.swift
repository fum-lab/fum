import Foundation
import Observation
import SwiftUI
import ЦиклОператора

@MainActor
@Observable
private final class МодельОкна {
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
    var состояние = СостояниеЦиклаФУМА()
    var выполняется = false

    private let цикл = ЦиклОператора()
    private var номерНаблюдения = 0
    private var цепочкаГеометрии: Task<Void, Never>?

    func принятьРазмерКонтентнойОбласти(_ размер: CGSize) {
        номерНаблюдения += 1
        let номер = номерНаблюдения
        let ширина = Double(размер.width)
        let высота = Double(размер.height)
        let предыдущаяЦепочка = цепочкаГеометрии
        let цикл = цикл
        цепочкаГеометрии = Task { [weak self] in
            await предыдущаяЦепочка?.value
            guard let self else { return }
            let событие: СобытиеНаблюденияРазмеров = self.состояние.область == nil
                ? .первоначальноеНаблюдение
                : .изменениеРазмера
            let наблюдение = НаблюдениеКонтентнойОбласти(
                номер: номер,
                ширина: ширина,
                высота: высота,
                единица: .пункты,
                источник: .роднаяГеометрия,
                событие: событие
            )
            let снимок = await цикл.наблюдатьКонтентнуюОбласть(наблюдение)
            self?.состояние.применитьЕслиНовее(снимок)
        }
    }

    func выполнитьОдинШаг() {
        guard !выполняется else { return }
        выполняется = true
        Task {
            do {
                _ = try await цикл.выполнитьОдинШаг(вход: вход, определение: определение)
            } catch {
                // Ошибка уже сохранена в общем состоянии FUMA и истории шага.
            }
            состояние.применитьЕслиНовее(await цикл.снимок())
            выполняется = false
        }
    }
}

@main
@MainActor
private struct ПриложениеМинимальногоИнтерфейсаFUMA: App {
    var body: some Scene {
        WindowGroup("FUMA · один шаг") {
            ГлавноеОкно()
                .frame(minWidth: 320, minHeight: 400)
        }
    }
}

@MainActor
private struct ГлавноеОкно: View {
    @State private var модель = МодельОкна()

    var body: some View {
        GeometryReader { прокси in
            ScrollView {
                панели
                    .padding(модель.состояние.раскладка?.компактнаяВысота == true ? 10 : 20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .onChange(of: прокси.size, initial: true) { _, новыйРазмер in
                модель.принятьРазмерКонтентнойОбласти(новыйРазмер)
            }
        }
    }

    @ViewBuilder
    private var панели: some View {
        let controls = панельДействия
        let outcome = панельСостояния
        if модель.состояние.раскладка?.числоКолонок == 2 {
            HStack(alignment: .top, spacing: 16) {
                controls.frame(maxWidth: .infinity, alignment: .topLeading)
                outcome.frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                controls
                outcome
            }
        }
    }

    private var панельДействия: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Цикл FUMA")
                .font(.largeTitle.bold())
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
        }
    }

    private var панельСостояния: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Состояние FUMA")
                .font(.headline)
            if модель.выполняется {
                Text("Исполняется один шаг…")
            }
            Text("Действия пользователя: \(модель.состояние.числоДействийПользователя) · вызовы исполнителя: \(модель.состояние.числоВызововИсполнителя)")
                .textSelection(.enabled)

            if let область = модель.состояние.область, let раскладка = модель.состояние.раскладка {
                Text("Content viewport: \(область.ширина) × \(область.высота) points")
                    .font(.subheadline)
                    .textSelection(.enabled)
                Text("Источник: \(область.источник.rawValue) · событие: \(область.событие.rawValue)")
                    .font(.caption)
                    .textSelection(.enabled)
                Text("Раскладка: \(раскладка.числоКолонок) колонки · компактная высота: \(раскладка.компактнаяВысота ? "да" : "нет")")
                Text("Геометрия принята: \(модель.состояние.принятоНаблюденийГеометрии) · отклонена: \(модель.состояние.отклоненоНаблюденийГеометрии)")
                    .font(.caption)
            } else {
                Text("Ожидается первое измерение content viewport в points.")
                    .font(.caption)
            }

            if let ошибкаГеометрии = модель.состояние.последняяОшибкаГеометрии {
                Text("Измерение геометрии отклонено: \(описать(ошибкаГеометрии))")
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
            }
            if let результат = модель.состояние.последнийРезультат {
                Text("Результат: \(результат.текст)")
                    .textSelection(.enabled)
            }
            if let ошибка = модель.состояние.последняяОшибкаИсполнения {
                Text("Ошибка шага: \(ошибка)")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Text("История")
                .font(.headline)
            ForEach(модель.состояние.история) { запись in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Предложено: вход «\(запись.вход)» · программа: \(запись.определение)")
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(запись.исход)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func описать(_ ошибка: ОшибкаГеометрии) -> String {
        switch ошибка {
        case .неположительныйРазмер: return "ширина и высота должны быть положительными"
        case .неКонечныйРазмер: return "ширина и высота должны быть конечными"
        case .размерЗаПределом: return "размер превышает предел 16384 points"
        case .устаревшийПорядок: return "порядок наблюдения не возрастает"
        case .неожиданноеСобытие: return "после начального наблюдения ожидалось событие изменения"
        }
    }
}
