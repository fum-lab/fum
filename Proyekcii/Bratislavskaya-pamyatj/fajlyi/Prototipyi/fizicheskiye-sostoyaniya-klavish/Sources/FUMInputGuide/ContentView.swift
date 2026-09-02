import FUMInputCore
import SwiftUI

struct ContentView: View {
  @ObservedObject var model: CaptureViewModel
  @State private var showsDeleteConfirmation = false

  var body: some View {
    NavigationSplitView {
      scenarioSidebar
    } detail: {
      VStack(spacing: 0) {
        header
        Divider()
        ScrollView {
          Group {
            switch model.lifecycle {
            case .idle:
              consentView
            case .ready:
              scenarioView(recording: false)
            case .recording:
              scenarioView(recording: true)
            case .finished:
              finishedView
            }
          }
          .padding(28)
          .frame(maxWidth: 820, alignment: .leading)
        }
      }
    }
    .confirmationDialog(
      "Удалить все локальные файлы этого сеанса?",
      isPresented: $showsDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Удалить без возможности восстановления", role: .destructive) {
        model.deleteFinishedSession()
      }
      Button("Отмена", role: .cancel) {}
    } message: {
      Text("Будут удалены manifest.json и events.jsonl текущего завершённого сеанса.")
    }
    .onDisappear {
      model.handleInterfaceClosure()
    }
  }

  private var scenarioSidebar: some View {
    VStack(spacing: 0) {
      List(selection: $model.selectedScenarioID) {
        Section("Сценарии \(model.completedScenarioCount)/\(model.plan.scenarios.count)") {
          ForEach(model.plan.scenarios) { scenario in
            Label {
              VStack(alignment: .leading, spacing: 2) {
                Text(scenario.title)
                if scenario.availability == .conditional {
                  Text("По доступности")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if scenario.requiredCompletedAttempts > 1 {
                  Text(
                    "Принято попыток: \(model.completedAttemptCount(for: scenario))/\(scenario.requiredCompletedAttempts)"
                  )
                  .font(.caption)
                  .foregroundStyle(.secondary)
                }
              }
            } icon: {
              Image(systemName: scenarioIcon(scenario))
                .foregroundStyle(scenarioColor(scenario))
            }
            .tag(Optional(scenario.id))
          }
        }
      }
      .disabled(model.lifecycle == .recording)

      Divider()
      VStack(alignment: .leading, spacing: 8) {
        ProgressView(
          value: Double(model.completedScenarioCount),
          total: Double(model.plan.scenarios.count)
        )
        Text(
          "Активная карточка сразу пишет защищённый .incomplete-сеанс; штатная отмена или закрытие окна удаляет его"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding()
    }
    .navigationSplitViewColumnWidth(min: 270, ideal: 310)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Image(systemName: model.lifecycle == .recording ? "record.circle.fill" : "keyboard")
        .font(.title2)
        .foregroundStyle(model.lifecycle == .recording ? Color.red : Color.accentColor)
      VStack(alignment: .leading, spacing: 2) {
        Text("Проводник физической проверки клавиатуры")
          .font(.headline)
        Text(headerSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      if let outputURL = model.outputURL {
        Button("Показать в Finder", systemImage: "folder") {
          model.revealOutput()
        }
        .help(outputURL.path)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .background(model.lifecycle == .recording ? Color.red.opacity(0.08) : Color.clear)
  }

  private var consentView: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Сначала — границы сбора")
          .font(.largeTitle.bold())
        Text(
          "Стенд записывает физические коды, фазы, источник, монотонное время и причины фильтрации только во время активной карточки сценария. Символы и введённый текст не сохраняются."
        )
        .font(.title3)
      }

      GroupBox("Локальное хранение") {
        VStack(alignment: .leading, spacing: 10) {
          LabeledContent("Путь") {
            Text(model.captureRootPath)
              .font(.system(.caption, design: .monospaced))
              .textSelection(.enabled)
          }
          LabeledContent("Git") {
            Text("Каталог точно игнорируется до отдельной публикационной проверки")
          }
          LabeledContent("Доступ") {
            Text("Каталог 0700, файлы 0600")
          }
          LabeledContent("Срок") {
            Text("Завершённый сеанс — до явного удаления; аварийный .incomplete может остаться")
          }
        }
        .padding(6)
      }

      GroupBox("Источники") {
        VStack(alignment: .leading, spacing: 10) {
          ForEach($model.sourceOptions) { $source in
            HStack {
              Toggle(source.title, isOn: $source.isSelected)
              Spacer()
              if let status = source.status {
                sourceStatus(status)
              }
            }
          }
          if model.needsInputMonitoring && model.environment.listenEventAccess == false {
            Divider()
            HStack {
              Image(systemName: "exclamationmark.shield")
                .foregroundStyle(.orange)
              Text("CGEventTap и NSEvent требуют Input Monitoring.")
              Spacer()
              Button("Запросить") { model.requestInputMonitoring() }
              Button("Открыть настройки") { model.openInputMonitoringSettings() }
            }
          }
        }
        .padding(6)
      }

      Toggle(isOn: $model.consentAccepted) {
        Text(
          "Я понимаю назначение, состав, место хранения и включаю сбор только для указанных безопасных действий."
        )
      }
      .toggleStyle(.checkbox)

      if let errorMessage = model.errorMessage {
        errorBanner(errorMessage)
      }

      Button("Создать локальный сеанс", systemImage: "record.circle") {
        model.startSession()
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(
        model.consentAccepted == false || model.selectedSourceCount == 0 || model.location == nil
      )
    }
  }

  @ViewBuilder
  private func scenarioView(recording: Bool) -> some View {
    if let scenario = recording ? model.activeScenario : model.selectedScenario {
      VStack(alignment: .leading, spacing: 22) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 6) {
            Text(scenario.title)
              .font(.largeTitle.bold())
            Text(scenario.purpose)
              .font(.title3)
              .foregroundStyle(.secondary)
          }
          Spacer()
          if scenario.availability == .conditional {
            Text("ПО ДОСТУПНОСТИ")
              .font(.caption.bold())
              .padding(.horizontal, 8)
              .padding(.vertical, 5)
              .background(.orange.opacity(0.15), in: Capsule())
          }
        }

        if recording {
          HStack(spacing: 10) {
            Image(systemName: "record.circle.fill")
              .foregroundStyle(.red)
            Text("ЗАПИСЬ АКТИВНА ТОЛЬКО ДЛЯ ЭТОГО СЦЕНАРИЯ")
              .font(.headline)
            Spacer()
            Text("Событий: \(model.recordedObservationCount)")
            Text("Неожиданных: \(model.unexpectedObservationCount)")
              .foregroundStyle(
                model.unexpectedObservationCount == 0 ? Color.secondary : Color.red
              )
          }
          .padding()
          .background(Color.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
        }

        instructionSection(title: "Действия", items: scenario.instructions, numbered: true)
        instructionSection(
          title: "Ожидаемое свидетельство",
          items: scenario.expectedEvidence,
          numbered: false
        )

        GroupBox("Источники этого сеанса") {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(model.sourceOptions.filter(\.isSelected)) { source in
              HStack {
                Text(source.title)
                Spacer()
                sourceStatus(source.status ?? .unavailable)
              }
              if let detail = source.detail {
                Text(detail)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .padding(6)
        }

        GroupBox("Текущий сигнал") {
          Text(model.lastEventSummary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }

        if let errorMessage = model.errorMessage {
          errorBanner(errorMessage)
        }

        if recording {
          HStack {
            Button("Выполнено", systemImage: "checkmark.circle") {
              model.completeActiveScenario(as: .completed)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isFinalizingScenario)
            if scenario.availability == .conditional {
              Button("Не поддерживается", systemImage: "nosign") {
                model.completeActiveScenario(as: .unsupported)
              }
              .disabled(model.isFinalizingScenario)
            }
            Button("Пропустить", systemImage: "forward") {
              model.completeActiveScenario(as: .skipped)
            }
            .disabled(model.isFinalizingScenario)
            Spacer()
            Button("Отменить весь сеанс", role: .destructive) {
              model.cancelSession()
            }
          }
        } else {
          HStack {
            Button("Начать запись сценария", systemImage: "record.circle") {
              model.beginSelectedScenario()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
            Button("Завершить и сохранить сеанс", systemImage: "externaldrive") {
              model.finishSession()
            }
            .disabled(model.completedScenarioCount != model.plan.scenarios.count)
            Button("Отменить сеанс", role: .destructive) {
              model.cancelSession()
            }
          }
        }
      }
    } else {
      ContentUnavailableView(
        "Выберите сценарий",
        systemImage: "list.bullet.rectangle",
        description: Text("Карточка покажет точные безопасные действия и ожидаемые свидетельства.")
      )
    }
  }

  private var finishedView: some View {
    VStack(alignment: .leading, spacing: 22) {
      Label("Сеанс сохранён", systemImage: "checkmark.circle.fill")
        .font(.largeTitle.bold())
        .foregroundStyle(.green)
      Text(
        "Манифест содержит снимок плана и исходы сценариев, а events.jsonl — только разрешённые события и диагностические решения редуктора. Файлы остаются локальными и игнорируются Git."
      )
      .font(.title3)
      if let outputURL = model.outputURL {
        Text(outputURL.path)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
      }
      HStack {
        Button("Показать в Finder", systemImage: "folder") {
          model.revealOutput()
        }
        .buttonStyle(.borderedProminent)
        Button("Удалить локальные данные", systemImage: "trash", role: .destructive) {
          showsDeleteConfirmation = true
        }
      }
      Text(
        "Перед любой публикацией нужен отдельный просмотр: точные времена и последовательности нажатий могут быть чувствительными данными."
      )
      .font(.callout)
      .foregroundStyle(.secondary)
    }
  }

  private func instructionSection(title: String, items: [String], numbered: Bool) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.headline)
      ForEach(Array(items.enumerated()), id: \.offset) { index, item in
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Text(numbered ? "\(index + 1)." : "•")
            .foregroundStyle(.secondary)
            .frame(width: 24, alignment: .trailing)
          Text(item)
        }
      }
    }
  }

  private func sourceStatus(_ status: GuidedSourceStatus) -> some View {
    let presentation: (String, String, Color) =
      switch status {
      case .active:
        ("Активен", "checkmark.circle.fill", .green)
      case .unavailable:
        ("Недоступен", "xmark.circle", .secondary)
      case .permissionRequired:
        ("Нужно разрешение", "exclamationmark.shield", .orange)
      }
    return Label(presentation.0, systemImage: presentation.1)
      .foregroundStyle(presentation.2)
      .font(.caption)
  }

  private func errorBanner(_ message: String) -> some View {
    Label(message, systemImage: "exclamationmark.triangle.fill")
      .foregroundStyle(.red)
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
  }

  private func scenarioIcon(_ scenario: KeyboardTestScenario) -> String {
    if model.activeScenarioID == scenario.id { return "record.circle.fill" }
    switch model.status(for: scenario) {
    case .completed:
      return model.isScenarioResolved(scenario) ? "checkmark.circle.fill" : "arrow.clockwise.circle"
    case .unsupported:
      return "nosign"
    case .skipped:
      return "forward.circle"
    case .invalid:
      return "exclamationmark.circle.fill"
    case nil:
      return "circle"
    }
  }

  private func scenarioColor(_ scenario: KeyboardTestScenario) -> Color {
    if model.activeScenarioID == scenario.id { return .red }
    switch model.status(for: scenario) {
    case .completed:
      return model.isScenarioResolved(scenario) ? .green : .orange
    case .unsupported, .skipped:
      return .secondary
    case .invalid:
      return .orange
    case nil:
      return .secondary
    }
  }

  private var headerSubtitle: String {
    switch model.lifecycle {
    case .idle:
      "Сбор выключен"
    case .ready:
      "Активно источников: \(model.activeSourceCount)/\(model.selectedSourceCount); запись выключена"
    case .recording:
      "Активно источников: \(model.activeSourceCount)/\(model.selectedSourceCount); идёт ограниченная запись"
    case .finished:
      "Сбор остановлен"
    }
  }
}
