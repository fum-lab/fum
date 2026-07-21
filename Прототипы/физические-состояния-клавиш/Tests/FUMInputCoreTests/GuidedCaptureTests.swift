import Dispatch
import Foundation
import Testing

@testable import FUMInputCore

@Suite("Управляемый сбор клавиатурных событий")
struct GuidedCaptureTests {
  @Test("план покрывает обязательные физические и граничные сценарии")
  func planCoversRequiredScenarios() {
    let identifiers = Set(KeyboardTestPlan.standard.scenarios.map(\.id))

    #expect(KeyboardTestPlan.standard.version == 1)
    #expect(identifiers.count == KeyboardTestPlan.standard.scenarios.count)
    #expect(
      identifiers.isSuperset(
        of: [
          "ordinary-tap-and-rollover",
          "ordinary-long-hold",
          "modifier-sides",
          "command-overlap",
          "modifier-key-chord",
          "caps-lock-two-cycles",
          "layout-invariance",
          "fn-and-top-row",
          "media-key-boundary",
          "focus-boundary",
          "second-keyboard",
          "disconnect-reconnect",
          "sleep-wake",
          "permission-loss",
          "load-burst",
        ]))
  }

  @Test("одинаковые коды разных источников сокращаются независимо")
  func keepsReducersSeparateBySource() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let recorder = try fixture.makeRecorder(sources: [.cgEventTap, .nsEvent])
    try recorder.beginScenario("ordinary-tap-and-rollover")
    let key = PhysicalKey(
      deviceID: "combined-session",
      codeSpace: .macVirtualKeyCode,
      usagePage: 0,
      usage: 0
    )

    let cgDisposition = try recorder.record(
      .init(
        source: .cgEventTap,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))
    let nsDisposition = try recorder.record(
      .init(
        source: .nsEvent,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 11,
        isAutoRepeat: false
      ))

    #expect(cgDisposition == .accepted)
    #expect(nsDisposition == .accepted)
  }

  @Test("автоповтор остаётся диагностическим событием, а не переходом")
  func preservesAutoRepeatDiagnostic() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let recorder = try fixture.makeRecorder(sources: [.cgEventTap])
    try recorder.beginScenario("ordinary-long-hold")
    let key = PhysicalKey(
      deviceID: "combined-session",
      codeSpace: .macVirtualKeyCode,
      usagePage: 0,
      usage: 0
    )

    _ = try recorder.record(
      .init(
        source: .cgEventTap,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))
    let disposition = try recorder.record(
      .init(
        source: .cgEventTap,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 20,
        isAutoRepeat: true
      ))

    #expect(disposition == .autoRepeat)
    let records = try fixture.decodeRecords(from: recorder.incompleteDirectoryURL)
    #expect(records.count == 2)
    #expect(records.last?.observation?.isAutoRepeat == true)
    #expect(records.last?.disposition == .autoRepeat)
    #expect(records.last?.transition == nil)
  }

  @Test("неожиданная клавиша не сохраняется и только аннулирует попытку")
  func doesNotPersistUnexpectedKey() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let recorder = try fixture.makeRecorder(sources: [.cgEventTap])
    try recorder.beginScenario("ordinary-tap-and-rollover")

    let disposition = try recorder.record(
      .init(
        source: .cgEventTap,
        key: .init(
          deviceID: "combined-session",
          codeSpace: .macVirtualKeyCode,
          usagePage: 0,
          usage: 14
        ),
        state: .pressed,
        monotonicNanoseconds: 30,
        isAutoRepeat: false
      ))

    #expect(disposition == .unexpectedKey)
    #expect(try fixture.decodeRecords(from: recorder.incompleteDirectoryURL).isEmpty)
    #expect(recorder.currentUnexpectedObservationCount == 1)
  }

  @Test("завершённый сеанс атомарно получает манифест без абсолютного пути")
  func finalizesProtectedSession() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let scenario = KeyboardTestPlan.standard.scenario(id: "ordinary-long-hold")!
    let recorder = try fixture.makeRecorder(
      sources: [.ioHIDManager],
      plan: .init(version: 1, scenarios: [scenario])
    )
    try recorder.beginScenario(scenario.id)
    _ = try recorder.record(
      .init(
        source: .ioHIDManager,
        key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
        state: .pressed,
        monotonicNanoseconds: 40,
        isAutoRepeat: false
      ))
    _ = try recorder.record(
      .init(
        source: .ioHIDManager,
        key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
        state: .released,
        monotonicNanoseconds: 3_000_000_050,
        isAutoRepeat: false
      ))
    let status = try recorder.completeCurrentScenario(as: .completed)

    let finalDirectory = try recorder.finish(
      sourceResults: [
        .init(source: .ioHIDManager, status: .active, detail: nil)
      ])
    let manifestData = try Data(contentsOf: finalDirectory.appendingPathComponent("manifest.json"))
    let manifest = try JSONDecoder().decode(GuidedCaptureManifest.self, from: manifestData)
    let manifestText = String(decoding: manifestData, as: UTF8.self)

    #expect(finalDirectory.lastPathComponent.hasPrefix("session-"))
    #expect(manifest.capturePolicy == "guided-allowlist-v1")
    #expect(manifest.eventsFile == "events.jsonl")
    #expect(manifestText.contains(fixture.root.path) == false)
    #expect(manifest.scenarioResults.first?.status == .completed)
    #expect(manifest.scenarioResults.first?.evidenceSatisfied == true)
    #expect(status == .completed)
    #expect(fileMode(finalDirectory) == 0o700)
    #expect(fileMode(finalDirectory.appendingPathComponent("events.jsonl")) == 0o600)
    #expect(fileMode(finalDirectory.appendingPathComponent("manifest.json")) == 0o600)
  }

  @Test("неполный или слишком короткий цикл нельзя отметить выполненным")
  func rejectsIncompleteScenarioEvidence() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let recorder = try fixture.makeRecorder(sources: [.ioHIDManager])
    try recorder.beginScenario("ordinary-long-hold")
    _ = try recorder.record(
      .init(
        source: .ioHIDManager,
        key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
        state: .pressed,
        monotonicNanoseconds: 1,
        isAutoRepeat: false
      ))
    _ = try recorder.record(
      .init(
        source: .ioHIDManager,
        key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
        state: .released,
        monotonicNanoseconds: 2,
        isAutoRepeat: false
      ))

    #expect(try recorder.completeCurrentScenario(as: .completed) == .invalid)
  }

  @Test("последовательные Command не проходят сценарий перекрытия")
  func rejectsWrongTransitionOrder() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let recorder = try fixture.makeRecorder(sources: [.ioHIDManager])
    try recorder.beginScenario("command-overlap")
    for (offset, transition) in [
      (0xE3, PhysicalKeyState.pressed),
      (0xE3, .released),
      (0xE7, .pressed),
      (0xE7, .released),
    ].enumerated() {
      _ = try recorder.record(
        .init(
          source: .ioHIDManager,
          key: .init(
            deviceID: "keyboard-1",
            usagePage: 0x07,
            usage: UInt32(transition.0)
          ),
          state: transition.1,
          monotonicNanoseconds: UInt64(offset),
          isAutoRepeat: false
        ))
    }

    #expect(try recorder.completeCurrentScenario(as: .completed) == .invalid)
  }

  @Test("сеанс нельзя сохранить до классификации всех сценариев")
  func rejectsUnresolvedSession() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let scenario = KeyboardTestPlan.standard.scenario(id: "ordinary-long-hold")!
    let recorder = try fixture.makeRecorder(
      sources: [.ioHIDManager],
      plan: .init(version: 1, scenarios: [scenario])
    )

    #expect(throws: GuidedCaptureRecorderError.self) {
      try recorder.finish(sourceResults: [])
    }
  }

  @Test("раскладочный сценарий требует две полные попытки")
  func requiresTwoLayoutAttempts() throws {
    let fixture = try CaptureFixture()
    defer { fixture.remove() }
    let scenario = KeyboardTestPlan.standard.scenario(id: "layout-invariance")!
    let recorder = try fixture.makeRecorder(
      sources: [.ioHIDManager],
      plan: .init(version: 1, scenarios: [scenario])
    )

    try recordACycle(recorder: recorder, scenarioID: scenario.id, timestamp: 10)
    #expect(recorder.unresolvedScenarioIDs() == [scenario.id])
    try recordACycle(recorder: recorder, scenarioID: scenario.id, timestamp: 20)
    #expect(recorder.unresolvedScenarioIDs().isEmpty)
  }

  @Test("граница сценария дожидается всех уже принятых callback")
  func eventGateDrainsAcceptedCallbacksInOrder() {
    let deliveryQueue = DispatchQueue(label: "fum.keyboard-test.event-gate")
    deliveryQueue.suspend()
    let gate = GuidedCaptureEventGate(deliveryQueue: deliveryQueue)
    let log = TestDeliveryLog()
    let drained = DispatchSemaphore(value: 0)
    let token = gate.open()

    gate.submit { _ in log.append(1) }
    gate.submit { _ in log.append(2) }
    gate.close(token) { drained.signal() }
    gate.submit { _ in log.append(3) }

    #expect(drained.wait(timeout: .now()) == .timedOut)
    deliveryQueue.resume()
    #expect(drained.wait(timeout: .now() + 2) == .success)
    deliveryQueue.sync {}
    #expect(log.values == [1, 2])
  }

  @Test("символьная ссылка не принимается как корень записи")
  func rejectsSymbolicLinkCaptureRoot() throws {
    let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let outside = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer {
      try? FileManager.default.removeItem(at: parent)
      try? FileManager.default.removeItem(at: outside)
    }
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let linkedRoot = parent.appendingPathComponent("capture")
    try FileManager.default.createSymbolicLink(at: linkedRoot, withDestinationURL: outside)

    #expect(throws: GuidedCaptureRecorderError.self) {
      try GuidedCaptureSessionRecorder(
        rootDirectory: linkedRoot,
        plan: .init(version: 1, scenarios: []),
        selectedSources: []
      )
    }
  }
}

private struct CaptureFixture {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }

  func makeRecorder(
    sources: [InputSourceID],
    plan: KeyboardTestPlan = .standard
  ) throws -> GuidedCaptureSessionRecorder {
    try GuidedCaptureSessionRecorder(
      rootDirectory: root,
      plan: plan,
      selectedSources: sources,
      startedAt: Date(timeIntervalSince1970: 1_721_578_400),
      sessionID: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    )
  }

  func decodeRecords(from directory: URL) throws -> [GuidedCaptureEventRecord] {
    let data = try Data(contentsOf: directory.appendingPathComponent("events.jsonl"))
    return try data.split(separator: 0x0A).map {
      try JSONDecoder().decode(GuidedCaptureEventRecord.self, from: Data($0))
    }
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private func recordACycle(
  recorder: GuidedCaptureSessionRecorder,
  scenarioID: String,
  timestamp: UInt64
) throws {
  try recorder.beginScenario(scenarioID)
  for (offset, state) in [PhysicalKeyState.pressed, .released].enumerated() {
    _ = try recorder.record(
      .init(
        source: .ioHIDManager,
        key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
        state: state,
        monotonicNanoseconds: timestamp + UInt64(offset),
        isAutoRepeat: false
      ))
  }
  #expect(try recorder.completeCurrentScenario(as: .completed) == .completed)
}

private final class TestDeliveryLog: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [Int] = []

  var values: [Int] {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }

  func append(_ value: Int) {
    lock.lock()
    storage.append(value)
    lock.unlock()
  }
}

private func fileMode(_ url: URL) -> Int {
  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
  return (attributes?[.posixPermissions] as? NSNumber)?.intValue ?? 0
}
