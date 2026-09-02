import AppKit
import FUMInputCore
import FUMInputMac
import Foundation
import SwiftUI

@MainActor
final class CaptureViewModel: ObservableObject {
  enum Lifecycle {
    case idle
    case ready
    case recording
    case finished
  }

  struct SourceOption: Identifiable {
    let id: InputSourceID
    let title: String
    var isSelected: Bool
    var status: GuidedSourceStatus?
    var detail: String?
  }

  @Published var lifecycle: Lifecycle = .idle
  @Published var consentAccepted = false
  @Published var sourceOptions: [SourceOption]
  @Published var selectedScenarioID: String?
  @Published var activeScenarioID: String?
  @Published var scenarioStatuses: [String: GuidedScenarioStatus] = [:]
  @Published var recordedObservationCount = 0
  @Published var unexpectedObservationCount = 0
  @Published var lastEventSummary = "События ещё не записывались"
  @Published var errorMessage: String?
  @Published var outputURL: URL?
  @Published var environment: MacInputEnvironmentSnapshot
  @Published var isFinalizingScenario = false

  let plan = KeyboardTestPlan.standard
  let location: PrototypeRepositoryLocation?

  private var recorder: GuidedCaptureSessionRecorder?
  private var activeSources: [InputSourceID: any MacKeyboardObservationSource] = [:]
  private let eventGate = GuidedCaptureEventGate()
  private var activeScenarioToken: UUID?
  private var completedAttemptCounts: [String: Int] = [:]

  init() {
    environment = MacInputEnvironment.snapshot()
    sourceOptions = [
      .init(id: .ioHIDManager, title: "IOHIDManager", isSelected: true),
      .init(id: .gcKeyboard, title: "GCKeyboard", isSelected: true),
      .init(id: .cgEventTap, title: "CGEventTap", isSelected: true),
      .init(id: .nsEvent, title: "NSEvent", isSelected: true),
    ]
    do {
      location = try PrototypeRepositoryLocator.locate()
    } catch {
      location = nil
      errorMessage = String(describing: error)
    }
    selectedScenarioID = plan.scenarios.first?.id
  }

  deinit {
    for source in activeSources.values {
      source.stop()
    }
  }

  var selectedScenario: KeyboardTestScenario? {
    guard let selectedScenarioID else { return nil }
    return plan.scenario(id: selectedScenarioID)
  }

  var activeScenario: KeyboardTestScenario? {
    guard let activeScenarioID else { return nil }
    return plan.scenario(id: activeScenarioID)
  }

  var captureRootPath: String {
    location?.captureRoot.path ?? "Корень репозитория не подтверждён"
  }

  var completedScenarioCount: Int {
    plan.scenarios.filter(isScenarioResolved).count
  }

  var selectedSourceCount: Int {
    sourceOptions.filter(\.isSelected).count
  }

  var activeSourceCount: Int {
    sourceOptions.filter { $0.isSelected && $0.status == .active }.count
  }

  var needsInputMonitoring: Bool {
    sourceOptions.contains {
      $0.isSelected && ($0.id == .cgEventTap || $0.id == .nsEvent)
    }
  }

  func startSession() {
    errorMessage = nil
    guard consentAccepted else {
      errorMessage = "Подтвердите явное согласие перед созданием сеанса."
      return
    }
    guard let location else {
      errorMessage = "Путь репозитория не подтверждён; запись остановлена."
      return
    }
    let selectedSources = sourceOptions.filter(\.isSelected).map(\.id)
    guard selectedSources.isEmpty == false else {
      errorMessage = "Выберите хотя бы один источник."
      return
    }

    do {
      scenarioStatuses.removeAll()
      completedAttemptCounts.removeAll()
      let newRecorder = try GuidedCaptureSessionRecorder(
        rootDirectory: location.captureRoot,
        plan: plan,
        selectedSources: selectedSources
      )
      recorder = newRecorder
      outputURL = newRecorder.incompleteDirectoryURL
      activeSources.removeAll()
      for sourceID in selectedSources {
        startSource(sourceID)
      }
      guard activeSources.isEmpty == false else {
        try newRecorder.cancelAndDelete()
        recorder = nil
        outputURL = nil
        throw MacKeyboardSourceError.sourceUnavailable(
          "ни один выбранный источник не запустился"
        )
      }
      lifecycle = .ready
    } catch {
      errorMessage = String(describing: error)
    }
  }

  func beginSelectedScenario() {
    errorMessage = nil
    guard lifecycle == .ready, let selectedScenarioID else { return }
    do {
      try recorder?.beginScenario(selectedScenarioID)
      activeScenarioID = selectedScenarioID
      activeScenarioToken = eventGate.open()
      recordedObservationCount = 0
      unexpectedObservationCount = 0
      lastEventSummary = "Запись активна; выполните только указанные действия"
      lifecycle = .recording
    } catch {
      errorMessage = String(describing: error)
    }
  }

  func completeActiveScenario(as requestedStatus: GuidedScenarioStatus) {
    errorMessage = nil
    guard lifecycle == .recording, isFinalizingScenario == false,
      let activeScenarioToken
    else { return }
    isFinalizingScenario = true
    eventGate.close(activeScenarioToken) { [weak self] in
      MainActor.assumeIsolated {
        self?.finalizeActiveScenario(as: requestedStatus)
      }
    }
  }

  private func finalizeActiveScenario(as requestedStatus: GuidedScenarioStatus) {
    guard lifecycle == .recording, let activeScenarioID else { return }
    do {
      let actualStatus =
        try recorder?.completeCurrentScenario(as: requestedStatus)
        ?? requestedStatus
      scenarioStatuses[activeScenarioID] = actualStatus
      if actualStatus == .completed {
        completedAttemptCounts[activeScenarioID, default: 0] += 1
      }
      self.activeScenarioID = nil
      activeScenarioToken = nil
      isFinalizingScenario = false
      lifecycle = .ready
      lastEventSummary =
        actualStatus == .invalid
        ? "Попытка недействительна: свидетельство неполно или замечена неожиданная клавиша"
        : completionSummary(for: activeScenarioID, status: actualStatus)
    } catch {
      isFinalizingScenario = false
      errorMessage = String(describing: error)
    }
  }

  func finishSession() {
    errorMessage = nil
    guard lifecycle == .ready else { return }
    let unresolved = recorder?.unresolvedScenarioIDs() ?? plan.scenarios.map(\.id)
    guard unresolved.isEmpty else {
      errorMessage =
        "Сначала завершите или явно классифицируйте: \(unresolved.joined(separator: ", "))."
      return
    }
    do {
      let finalURL = try recorder?.finish(sourceResults: sourceResults())
      stopSources()
      recorder = nil
      outputURL = finalURL
      lifecycle = .finished
      lastEventSummary = "Сеанс завершён и сохранён"
    } catch {
      errorMessage = String(describing: error)
    }
  }

  func cancelSession() {
    eventGate.cancel(activeScenarioToken)
    activeScenarioToken = nil
    isFinalizingScenario = false
    stopSources()
    do {
      try recorder?.cancelAndDelete()
    } catch {
      errorMessage = String(describing: error)
    }
    recorder = nil
    outputURL = nil
    activeScenarioID = nil
    lifecycle = .idle
    scenarioStatuses.removeAll()
    completedAttemptCounts.removeAll()
    resetSourceStatuses()
  }

  func handleInterfaceClosure() {
    if lifecycle == .ready || lifecycle == .recording {
      cancelSession()
    }
  }

  func revealOutput() {
    guard let outputURL else { return }
    if FileManager.default.fileExists(atPath: outputURL.path) {
      NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }
  }

  func deleteFinishedSession() {
    guard lifecycle == .finished, let outputURL else { return }
    do {
      try FileManager.default.removeItem(at: outputURL)
      self.outputURL = nil
      lifecycle = .idle
      consentAccepted = false
      scenarioStatuses.removeAll()
      completedAttemptCounts.removeAll()
      resetSourceStatuses()
      lastEventSummary = "Локальные файлы сеанса удалены"
    } catch {
      errorMessage = String(describing: error)
    }
  }

  func requestInputMonitoring() {
    _ = MacInputEnvironment.requestListenEventAccess()
    environment = MacInputEnvironment.snapshot()
  }

  func openInputMonitoringSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
      )
    else { return }
    NSWorkspace.shared.open(url)
  }

  func status(for scenario: KeyboardTestScenario) -> GuidedScenarioStatus? {
    scenarioStatuses[scenario.id]
  }

  func completedAttemptCount(for scenario: KeyboardTestScenario) -> Int {
    completedAttemptCounts[scenario.id, default: 0]
  }

  func isScenarioResolved(_ scenario: KeyboardTestScenario) -> Bool {
    if completedAttemptCount(for: scenario) >= scenario.requiredCompletedAttempts {
      return true
    }
    return scenario.availability == .conditional
      && scenarioStatuses[scenario.id] == .unsupported
  }

  private func startSource(_ sourceID: InputSourceID) {
    do {
      let source = try MacKeyboardObservationSourceFactory.make(sourceID)
      let eventGate = eventGate
      try source.start(
        handler: { [weak self] observation in
          eventGate.submit { [weak self] scenarioToken in
            MainActor.assumeIsolated {
              self?.receive(observation, scenarioToken: scenarioToken)
            }
          }
        },
        diagnosticHandler: { [weak self] diagnostic in
          eventGate.submit { [weak self] scenarioToken in
            MainActor.assumeIsolated {
              self?.receive(diagnostic, scenarioToken: scenarioToken)
            }
          }
        }
      )
      activeSources[sourceID] = source
      updateSource(sourceID, status: .active, detail: nil)
    } catch let error as MacKeyboardSourceError {
      switch error {
      case .permissionRequired:
        updateSource(sourceID, status: .permissionRequired, detail: error.description)
      default:
        updateSource(sourceID, status: .unavailable, detail: error.description)
      }
    } catch {
      updateSource(sourceID, status: .unavailable, detail: String(describing: error))
    }
  }

  private func receive(
    _ observation: PhysicalKeyObservation,
    scenarioToken: UUID
  ) {
    guard lifecycle == .recording, activeScenarioToken == scenarioToken else { return }
    do {
      let disposition = try recorder?.record(observation) ?? .unexpectedKey
      if disposition == .unexpectedKey {
        unexpectedObservationCount += 1
        lastEventSummary = "Неожиданная клавиша не сохранена; попытку нужно повторить"
      } else {
        recordedObservationCount += 1
        lastEventSummary =
          "\(sourceTitle(observation.source)): \(observation.key.codeSpace.rawValue) "
          + "\(observation.key.usage) — \(disposition.rawValue)"
      }
    } catch {
      errorMessage = String(describing: error)
    }
  }

  private func receive(
    _ diagnostic: KeyboardSourceDiagnostic,
    scenarioToken: UUID
  ) {
    guard lifecycle == .recording, activeScenarioToken == scenarioToken else { return }
    let guidedKind: GuidedCaptureDiagnosticKind
    switch diagnostic.kind {
    case .tapDisabledByTimeout:
      guidedKind = .tapDisabledByTimeout
    case .tapDisabledByUserInput:
      guidedKind = .tapDisabledByUserInput
    }
    do {
      try recorder?.record(
        .init(
          source: diagnostic.source,
          kind: guidedKind,
          monotonicNanoseconds: diagnostic.monotonicNanoseconds
        ))
      recordedObservationCount += 1
      lastEventSummary = "Источник сообщил разрыв: \(diagnostic.kind.rawValue)"
    } catch {
      errorMessage = String(describing: error)
    }
  }

  private func stopSources() {
    for source in activeSources.values {
      source.stop()
    }
    activeSources.removeAll()
  }

  private func sourceResults() -> [GuidedSourceResult] {
    sourceOptions.filter(\.isSelected).map {
      .init(
        source: $0.id,
        status: $0.status ?? .unavailable,
        detail: $0.detail
      )
    }
  }

  private func updateSource(
    _ source: InputSourceID,
    status: GuidedSourceStatus,
    detail: String?
  ) {
    guard let index = sourceOptions.firstIndex(where: { $0.id == source }) else { return }
    sourceOptions[index].status = status
    sourceOptions[index].detail = detail
  }

  private func resetSourceStatuses() {
    for index in sourceOptions.indices {
      sourceOptions[index].status = nil
      sourceOptions[index].detail = nil
    }
  }

  private func sourceTitle(_ source: InputSourceID) -> String {
    sourceOptions.first { $0.id == source }?.title ?? source.rawValue
  }

  private func completionSummary(
    for scenarioID: String,
    status: GuidedScenarioStatus
  ) -> String {
    guard let scenario = plan.scenario(id: scenarioID), status == .completed else {
      return "Сценарий классифицирован как \(status.rawValue)"
    }
    let completedAttempts = completedAttemptCounts[scenarioID, default: 0]
    if completedAttempts < scenario.requiredCompletedAttempts {
      return
        "Попытка принята; повторите сценарий ещё \(scenario.requiredCompletedAttempts - completedAttempts) раз"
    }
    return "Сценарий завершён с достаточным свидетельством"
  }
}
