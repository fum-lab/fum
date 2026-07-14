import FUMShadowCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = EditorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                PlainTextEditor(
                    text: model.text,
                    onChange: model.editorChanged,
                    onSelectionChange: model.selectionChanged
                )
                .frame(minWidth: 600)

                inspector
                    .frame(minWidth: 300, idealWidth: 350, maxWidth: 440)
            }
        }
        .navigationTitle(model.documentTitle + (model.isDirty ? " •" : ""))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button("Открыть", action: model.openDocument)
            Button("Сохранить", action: model.saveDocument)
            Divider().frame(height: 22)
            TextField("Установленная модель Ollama", text: $model.modelName)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 190, idealWidth: 240)
            Toggle("Автоматически", isOn: $model.automaticCheckpoints)
                .toggleStyle(.checkbox)
            Button("Новая точка", action: model.startCheckpoint)
            Button("Сравнить сейчас", action: model.completeCurrentComparison)
                .disabled(model.activeExperiment?.humanContinuation.isEmpty ?? true)
            Spacer()
            Text(model.documentTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Состояние") {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(model.statusMessage)
                        Text("Ollama: \(model.ollamaPath)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let error = model.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Суффиксно-контекстный индекс") {
                    VStack(alignment: .leading, spacing: 5) {
                        metric("Обработано байт", model.indexSummary.processedBytes)
                        metric("Узлов", model.indexSummary.nodeCount)
                        metric("Пропущено по бюджету", model.indexSummary.skippedNodeCreations)
                        Text("Глубина: \(model.indexConfiguration.maxDepth), бюджет: \(model.indexConfiguration.maxNodes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let active = model.activeExperiment {
                    GroupBox("Активная теневая точка") {
                        VStack(alignment: .leading, spacing: 5) {
                            metric("Гипотеза LLM, байт", active.modelContinuation.count)
                            metric("Факт человека, байт", active.humanContinuation.count)
                            metric("Переходов LLM", active.modelStructure.transitionCounts.count)
                            metric("Переходов человека", active.humanStructure.transitionCounts.count)
                            Text("Содержимое гипотезы скрыто до завершения горизонта.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let experiment = model.lastExperiment,
                   experiment.status == .completed,
                   let comparison = experiment.comparison {
                    comparisonView(experiment: experiment, comparison: comparison)
                }

                GroupBox("Граница интерпретации") {
                    Text("Прототип измеряет наблюдаемое расхождение двух текстовых продолжений и одинаково построенных структур. Это не прямое чтение мысли человека и не доказательство равенства или различия внутренних состояний.")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Локальная трасса") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Сохранять завершённые сравнения", isOn: $model.persistComparisonTrace)
                            .toggleStyle(.checkbox)
                        Text("По умолчанию выключено. При включении рядом с документом сохраняются два коротких продолжения и метрики, но не модельный контекст.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Удалить трассу этого прототипа", role: .destructive, action: model.clearTrace)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func comparisonView(
        experiment: ContinuationExperiment,
        comparison: ContinuationMetrics
    ) -> some View {
        GroupBox("Последнее сравнение") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Человек")
                    .font(.caption.bold())
                Text(String(decoding: experiment.humanContinuation, as: UTF8.self))
                    .textSelection(.enabled)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Text("Локальная LLM")
                    .font(.caption.bold())
                Text(String(decoding: experiment.modelContinuation, as: UTF8.self))
                    .textSelection(.enabled)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Divider()
                metric("Общий префикс, байт", comparison.commonPrefixBytes)
                metric("Редакционное расстояние", comparison.editDistanceBytes)
                metric(
                    "Нормированное расстояние",
                    comparison.normalizedEditDistance.formatted(.number.precision(.fractionLength(3)))
                )
                metric(
                    "Структурное сходство Жаккара",
                    comparison.weightedJaccardSimilarity.formatted(.number.precision(.fractionLength(3)))
                )
                metric("Только человек", comparison.humanOnlyTransitionWeight)
                metric("Только LLM", comparison.modelOnlyTransitionWeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metric(_ name: String, _ value: Int) -> some View {
        metric(name, String(value))
    }

    private func metric(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.caption)
    }
}
