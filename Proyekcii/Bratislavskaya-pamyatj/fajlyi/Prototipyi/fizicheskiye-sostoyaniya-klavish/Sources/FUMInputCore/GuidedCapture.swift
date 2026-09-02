import Dispatch
import Foundation

public enum GuidedObservationDisposition: String, Codable, Equatable, Sendable {
  case accepted
  case autoRepeat
  case missingPhysicalState
  case unchangedPhysicalState
  case unexpectedKey
}

public enum GuidedScenarioStatus: String, Codable, Sendable {
  case completed
  case skipped
  case unsupported
  case invalid
}

public struct GuidedScenarioResult: Codable, Equatable, Sendable {
  public let scenarioID: String
  public let attemptNumber: Int
  public let status: GuidedScenarioStatus
  public let recordedObservationCount: Int
  public let acceptedTransitionCount: Int
  public let bestSourceAcceptedTransitionCount: Int
  public let unexpectedObservationCount: Int
  public let evidenceSatisfied: Bool

  public init(
    scenarioID: String,
    attemptNumber: Int,
    status: GuidedScenarioStatus,
    recordedObservationCount: Int,
    acceptedTransitionCount: Int,
    bestSourceAcceptedTransitionCount: Int,
    unexpectedObservationCount: Int,
    evidenceSatisfied: Bool
  ) {
    self.scenarioID = scenarioID
    self.attemptNumber = attemptNumber
    self.status = status
    self.recordedObservationCount = recordedObservationCount
    self.acceptedTransitionCount = acceptedTransitionCount
    self.bestSourceAcceptedTransitionCount = bestSourceAcceptedTransitionCount
    self.unexpectedObservationCount = unexpectedObservationCount
    self.evidenceSatisfied = evidenceSatisfied
  }
}

public enum GuidedSourceStatus: String, Codable, Sendable {
  case active
  case unavailable
  case permissionRequired
}

public struct GuidedSourceResult: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let status: GuidedSourceStatus
  public let detail: String?

  public init(source: InputSourceID, status: GuidedSourceStatus, detail: String?) {
    self.source = source
    self.status = status
    self.detail = detail
  }
}

public enum GuidedCaptureDiagnosticKind: String, Codable, Sendable {
  case tapDisabledByTimeout
  case tapDisabledByUserInput
}

public struct GuidedCaptureDiagnostic: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let kind: GuidedCaptureDiagnosticKind
  public let monotonicNanoseconds: UInt64?

  public init(
    source: InputSourceID,
    kind: GuidedCaptureDiagnosticKind,
    monotonicNanoseconds: UInt64?
  ) {
    self.source = source
    self.kind = kind
    self.monotonicNanoseconds = monotonicNanoseconds
  }
}

public struct GuidedCaptureEventRecord: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public let schemaVersion: Int
  public let sequenceNumber: UInt64
  public let scenarioID: String
  public let observation: PhysicalKeyObservation?
  public let disposition: GuidedObservationDisposition?
  public let transition: PhysicalKeyTransition?
  public let diagnostic: GuidedCaptureDiagnostic?

  public init(
    schemaVersion: Int = GuidedCaptureEventRecord.currentSchemaVersion,
    sequenceNumber: UInt64,
    scenarioID: String,
    observation: PhysicalKeyObservation?,
    disposition: GuidedObservationDisposition?,
    transition: PhysicalKeyTransition?,
    diagnostic: GuidedCaptureDiagnostic?
  ) {
    self.schemaVersion = schemaVersion
    self.sequenceNumber = sequenceNumber
    self.scenarioID = scenarioID
    self.observation = observation
    self.disposition = disposition
    self.transition = transition
    self.diagnostic = diagnostic
  }
}

public struct GuidedCaptureManifest: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public let schemaVersion: Int
  public let capturePolicy: String
  public let startedAt: String
  public let finishedAt: String
  public let plan: KeyboardTestPlan
  public let selectedSources: [InputSourceID]
  public let sourceResults: [GuidedSourceResult]
  public let scenarioResults: [GuidedScenarioResult]
  public let eventsFile: String

  public init(
    schemaVersion: Int = GuidedCaptureManifest.currentSchemaVersion,
    capturePolicy: String,
    startedAt: String,
    finishedAt: String,
    plan: KeyboardTestPlan,
    selectedSources: [InputSourceID],
    sourceResults: [GuidedSourceResult],
    scenarioResults: [GuidedScenarioResult],
    eventsFile: String
  ) {
    self.schemaVersion = schemaVersion
    self.capturePolicy = capturePolicy
    self.startedAt = startedAt
    self.finishedAt = finishedAt
    self.plan = plan
    self.selectedSources = selectedSources
    self.sourceResults = sourceResults
    self.scenarioResults = scenarioResults
    self.eventsFile = eventsFile
  }
}

public enum GuidedCaptureRecorderError: Error, CustomStringConvertible, Sendable {
  case unknownScenario(String)
  case scenarioAlreadyActive
  case noActiveScenario
  case sourceNotSelected(InputSourceID)
  case alreadyFinished
  case destinationExists(String)
  case unsafeDestination(String)
  case unresolvedScenarios([String])

  public var description: String {
    switch self {
    case .unknownScenario(let identifier):
      "неизвестный сценарий: \(identifier)"
    case .scenarioAlreadyActive:
      "предыдущий сценарий ещё активен"
    case .noActiveScenario:
      "сценарий записи не запущен"
    case .sourceNotSelected(let source):
      "источник не выбран для сеанса: \(source.rawValue)"
    case .alreadyFinished:
      "сеанс уже завершён"
    case .destinationExists(let path):
      "каталог завершённого сеанса уже существует: \(path)"
    case .unsafeDestination(let path):
      "небезопасный каталог тестовых данных: \(path)"
    case .unresolvedScenarios(let identifiers):
      "не завершены обязательные сценарии: \(identifiers.joined(separator: ", "))"
    }
  }
}

public final class GuidedCaptureSessionRecorder: @unchecked Sendable {
  public let incompleteDirectoryURL: URL

  private struct ActiveScenario {
    let definition: KeyboardTestScenario
    var recordedObservationCount = 0
    var unexpectedObservationCount = 0
    var acceptedTransitionCounts: [InputSourceID: Int] = [:]
    var observedKeys: [InputSourceID: Set<KeyboardTestKey>] = [:]
    var pressedKeys: [InputSourceID: Set<PhysicalKey>] = [:]
    var deviceIDs: [InputSourceID: Set<String>] = [:]
    var transitionSequences: [InputSourceID: [KeyboardTestTransition]] = [:]
    var firstAcceptedTimestamps: [InputSourceID: UInt64] = [:]
    var lastAcceptedTimestamps: [InputSourceID: UInt64] = [:]

    var acceptedTransitionCount: Int {
      acceptedTransitionCounts.values.reduce(0, +)
    }

    var bestSourceAcceptedTransitionCount: Int {
      acceptedTransitionCounts.values.max() ?? 0
    }

    var evidenceSatisfied: Bool {
      acceptedTransitionCounts.keys.contains { source in
        guard
          acceptedTransitionCounts[source, default: 0]
            >= definition.minimumAcceptedTransitionsPerSource,
          pressedKeys[source, default: []].isEmpty,
          deviceIDs[source, default: []].count >= definition.minimumDistinctDevicesPerSource
        else {
          return false
        }
        guard
          Set(definition.requiredObservedKeys).isSubset(
            of: observedKeys[source, default: []]
          )
        else {
          return false
        }
        if let expectedTransitionSequence = definition.expectedTransitionSequence,
          transitionSequences[source, default: []] != expectedTransitionSequence
        {
          return false
        }
        if let minimumDuration = definition.minimumDurationNanosecondsPerSource {
          guard let first = firstAcceptedTimestamps[source],
            let last = lastAcceptedTimestamps[source],
            last >= first,
            last - first >= minimumDuration
          else {
            return false
          }
        }
        return true
      }
    }
  }

  private let lock = NSLock()
  private let fileManager: FileManager
  private let rootDirectory: URL
  private let plan: KeyboardTestPlan
  private let selectedSources: [InputSourceID]
  private let selectedSourceSet: Set<InputSourceID>
  private let startedAt: Date
  private let sessionID: UUID
  private let encoder: JSONEncoder
  private var eventFileHandle: FileHandle?
  private var reducers: [InputSourceID: PhysicalKeyStateReducer] = [:]
  private var activeScenario: ActiveScenario?
  private var scenarioResults: [GuidedScenarioResult] = []
  private var nextSequenceNumber: UInt64 = 1
  private var finished = false

  public init(
    rootDirectory: URL,
    plan: KeyboardTestPlan,
    selectedSources: [InputSourceID],
    startedAt: Date = Date(),
    sessionID: UUID = UUID(),
    fileManager: FileManager = .default
  ) throws {
    self.rootDirectory = rootDirectory.standardizedFileURL
    self.plan = plan
    self.selectedSources = selectedSources
    selectedSourceSet = Set(selectedSources)
    self.startedAt = startedAt
    self.sessionID = sessionID
    self.fileManager = fileManager
    encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    incompleteDirectoryURL = self.rootDirectory.appendingPathComponent(
      ".incomplete-\(sessionID.uuidString.lowercased())",
      isDirectory: true
    )

    if Self.isSymbolicLink(at: self.rootDirectory, fileManager: fileManager) {
      throw GuidedCaptureRecorderError.unsafeDestination(self.rootDirectory.path)
    }
    var rootIsDirectory: ObjCBool = false
    if fileManager.fileExists(atPath: self.rootDirectory.path, isDirectory: &rootIsDirectory) {
      guard rootIsDirectory.boolValue else {
        throw GuidedCaptureRecorderError.unsafeDestination(self.rootDirectory.path)
      }
    } else {
      try fileManager.createDirectory(
        at: self.rootDirectory,
        withIntermediateDirectories: false,
        attributes: [.posixPermissions: NSNumber(value: 0o700)]
      )
    }
    guard Self.isSymbolicLink(at: self.rootDirectory, fileManager: fileManager) == false else {
      throw GuidedCaptureRecorderError.unsafeDestination(self.rootDirectory.path)
    }
    try fileManager.setAttributes(
      [.posixPermissions: NSNumber(value: 0o700)],
      ofItemAtPath: self.rootDirectory.path
    )
    try fileManager.createDirectory(
      at: incompleteDirectoryURL,
      withIntermediateDirectories: false,
      attributes: [.posixPermissions: NSNumber(value: 0o700)]
    )
    let eventsURL = incompleteDirectoryURL.appendingPathComponent("events.jsonl")
    guard
      fileManager.createFile(
        atPath: eventsURL.path,
        contents: Data(),
        attributes: [.posixPermissions: NSNumber(value: 0o600)]
      )
    else {
      throw CocoaError(.fileWriteUnknown)
    }
    try fileManager.setAttributes(
      [.posixPermissions: NSNumber(value: 0o600)],
      ofItemAtPath: eventsURL.path
    )
    eventFileHandle = try FileHandle(forWritingTo: eventsURL)
  }

  deinit {
    try? eventFileHandle?.close()
  }

  public var currentUnexpectedObservationCount: Int {
    lock.withLock { activeScenario?.unexpectedObservationCount ?? 0 }
  }

  public func beginScenario(_ identifier: String) throws {
    try lock.withLock {
      try ensureNotFinished()
      guard activeScenario == nil else {
        throw GuidedCaptureRecorderError.scenarioAlreadyActive
      }
      guard let scenario = plan.scenario(id: identifier) else {
        throw GuidedCaptureRecorderError.unknownScenario(identifier)
      }
      activeScenario = ActiveScenario(definition: scenario)
      reducers.removeAll(keepingCapacity: true)
    }
  }

  @discardableResult
  public func record(_ observation: PhysicalKeyObservation) throws -> GuidedObservationDisposition {
    try lock.withLock {
      try ensureNotFinished()
      guard var scenario = activeScenario else {
        throw GuidedCaptureRecorderError.noActiveScenario
      }
      guard selectedSourceSet.contains(observation.source) else {
        throw GuidedCaptureRecorderError.sourceNotSelected(observation.source)
      }
      guard scenario.definition.allows(observation.key) else {
        scenario.unexpectedObservationCount += 1
        activeScenario = scenario
        return .unexpectedKey
      }

      var reducer = reducers[observation.source] ?? PhysicalKeyStateReducer()
      let result = reducer.consume(observation)
      reducers[observation.source] = reducer
      let disposition: GuidedObservationDisposition
      let transition: PhysicalKeyTransition?
      switch result {
      case .accepted(let acceptedTransition):
        disposition = .accepted
        transition = acceptedTransition
        scenario.acceptedTransitionCounts[observation.source, default: 0] += 1
        if let testKey = scenario.definition.testKey(matching: observation.key) {
          scenario.observedKeys[observation.source, default: []].insert(testKey)
          scenario.transitionSequences[observation.source, default: []].append(
            .init(testKey, acceptedTransition.state)
          )
        }
        if scenario.firstAcceptedTimestamps[observation.source] == nil {
          scenario.firstAcceptedTimestamps[observation.source] =
            acceptedTransition.monotonicNanoseconds
        }
        scenario.lastAcceptedTimestamps[observation.source] =
          acceptedTransition.monotonicNanoseconds
        scenario.deviceIDs[observation.source, default: []].insert(observation.key.deviceID)
        switch acceptedTransition.state {
        case .pressed:
          scenario.pressedKeys[observation.source, default: []].insert(observation.key)
        case .released:
          scenario.pressedKeys[observation.source, default: []].remove(observation.key)
        }
      case .rejected(let rejection):
        disposition = Self.disposition(for: rejection)
        transition = nil
      }
      let record = GuidedCaptureEventRecord(
        sequenceNumber: nextSequenceNumber,
        scenarioID: scenario.definition.id,
        observation: observation,
        disposition: disposition,
        transition: transition,
        diagnostic: nil
      )
      try append(record)
      nextSequenceNumber += 1
      scenario.recordedObservationCount += 1
      activeScenario = scenario
      return disposition
    }
  }

  public func record(_ diagnostic: GuidedCaptureDiagnostic) throws {
    try lock.withLock {
      try ensureNotFinished()
      guard let scenario = activeScenario else {
        throw GuidedCaptureRecorderError.noActiveScenario
      }
      guard selectedSourceSet.contains(diagnostic.source) else {
        throw GuidedCaptureRecorderError.sourceNotSelected(diagnostic.source)
      }
      let record = GuidedCaptureEventRecord(
        sequenceNumber: nextSequenceNumber,
        scenarioID: scenario.definition.id,
        observation: nil,
        disposition: nil,
        transition: nil,
        diagnostic: diagnostic
      )
      try append(record)
      nextSequenceNumber += 1
    }
  }

  @discardableResult
  public func completeCurrentScenario(
    as requestedStatus: GuidedScenarioStatus
  ) throws -> GuidedScenarioStatus {
    try lock.withLock {
      try ensureNotFinished()
      guard let scenario = activeScenario else {
        throw GuidedCaptureRecorderError.noActiveScenario
      }
      let status: GuidedScenarioStatus =
        requestedStatus == .completed
          && (scenario.unexpectedObservationCount > 0 || scenario.evidenceSatisfied == false)
        ? .invalid : requestedStatus
      let attemptNumber =
        scenarioResults.filter { $0.scenarioID == scenario.definition.id }.count + 1
      scenarioResults.append(
        .init(
          scenarioID: scenario.definition.id,
          attemptNumber: attemptNumber,
          status: status,
          recordedObservationCount: scenario.recordedObservationCount,
          acceptedTransitionCount: scenario.acceptedTransitionCount,
          bestSourceAcceptedTransitionCount: scenario.bestSourceAcceptedTransitionCount,
          unexpectedObservationCount: scenario.unexpectedObservationCount,
          evidenceSatisfied: scenario.evidenceSatisfied
        ))
      activeScenario = nil
      reducers.removeAll(keepingCapacity: true)
      try eventFileHandle?.synchronize()
      return status
    }
  }

  public func finish(
    sourceResults: [GuidedSourceResult],
    finishedAt: Date = Date()
  ) throws -> URL {
    try lock.withLock {
      try ensureNotFinished()
      guard activeScenario == nil else {
        throw GuidedCaptureRecorderError.scenarioAlreadyActive
      }
      let unresolved = unresolvedScenarioIDsLocked()
      guard unresolved.isEmpty else {
        throw GuidedCaptureRecorderError.unresolvedScenarios(unresolved)
      }
      try eventFileHandle?.synchronize()
      try eventFileHandle?.close()
      eventFileHandle = nil

      let manifest = GuidedCaptureManifest(
        capturePolicy: "guided-allowlist-v1",
        startedAt: startedAt.ISO8601Format(),
        finishedAt: finishedAt.ISO8601Format(),
        plan: plan,
        selectedSources: selectedSources,
        sourceResults: sourceResults,
        scenarioResults: scenarioResults,
        eventsFile: "events.jsonl"
      )
      let manifestURL = incompleteDirectoryURL.appendingPathComponent("manifest.json")
      let manifestData = try encoder.encode(manifest)
      try manifestData.write(to: manifestURL, options: .atomic)
      try fileManager.setAttributes(
        [.posixPermissions: NSNumber(value: 0o600)],
        ofItemAtPath: manifestURL.path
      )

      let sessionName =
        "session-\(Self.moscowFilename(from: startedAt))-"
        + String(sessionID.uuidString.lowercased().prefix(8))
      let finalDirectory = rootDirectory.appendingPathComponent(sessionName, isDirectory: true)
      guard fileManager.fileExists(atPath: finalDirectory.path) == false else {
        throw GuidedCaptureRecorderError.destinationExists(sessionName)
      }
      try fileManager.moveItem(at: incompleteDirectoryURL, to: finalDirectory)
      finished = true
      return finalDirectory
    }
  }

  public func cancelAndDelete() throws {
    try lock.withLock {
      guard finished == false else {
        throw GuidedCaptureRecorderError.alreadyFinished
      }
      try eventFileHandle?.close()
      eventFileHandle = nil
      if fileManager.fileExists(atPath: incompleteDirectoryURL.path) {
        try fileManager.removeItem(at: incompleteDirectoryURL)
      }
      finished = true
    }
  }

  private func append(_ record: GuidedCaptureEventRecord) throws {
    guard let eventFileHandle else {
      throw GuidedCaptureRecorderError.alreadyFinished
    }
    var data = try encoder.encode(record)
    data.append(0x0A)
    try eventFileHandle.write(contentsOf: data)
  }

  private func ensureNotFinished() throws {
    if finished {
      throw GuidedCaptureRecorderError.alreadyFinished
    }
  }

  public func unresolvedScenarioIDs() -> [String] {
    lock.withLock { unresolvedScenarioIDsLocked() }
  }

  private func unresolvedScenarioIDsLocked() -> [String] {
    plan.scenarios.compactMap { scenario in
      let results = scenarioResults.filter { $0.scenarioID == scenario.id }
      let completedAttempts = results.filter { $0.status == .completed }.count
      if completedAttempts >= scenario.requiredCompletedAttempts {
        return nil
      }
      if scenario.availability == .conditional,
        results.contains(where: { $0.status == .unsupported })
      {
        return nil
      }
      return scenario.id
    }
  }

  private static func isSymbolicLink(
    at url: URL,
    fileManager: FileManager
  ) -> Bool {
    (try? fileManager.destinationOfSymbolicLink(atPath: url.path)) != nil
  }

  private static func disposition(
    for rejection: ObservationRejection
  ) -> GuidedObservationDisposition {
    switch rejection {
    case .autoRepeat:
      .autoRepeat
    case .missingPhysicalState:
      .missingPhysicalState
    case .unchangedPhysicalState:
      .unchangedPhysicalState
    }
  }

  private static func moscowFilename(from date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: date
    )
    return String(
      format: "%04d-%02d-%02d_%02d-%02d-%02d_MSK",
      components.year!,
      components.month!,
      components.day!,
      components.hour!,
      components.minute!,
      components.second!
    )
  }
}

public final class GuidedCaptureEventGate: @unchecked Sendable {
  private let lock = NSLock()
  private let deliveryQueue: DispatchQueue
  private var activeToken: UUID?
  private var pendingDeliveries: [UUID: Int] = [:]
  private var drainHandlers: [UUID: @Sendable () -> Void] = [:]

  public init(deliveryQueue: DispatchQueue = .main) {
    self.deliveryQueue = deliveryQueue
  }

  @discardableResult
  public func open() -> UUID {
    lock.withLock {
      let token = UUID()
      activeToken = token
      pendingDeliveries[token] = 0
      return token
    }
  }

  public func submit(
    _ delivery: @escaping @Sendable (_ scenarioToken: UUID) -> Void
  ) {
    lock.lock()
    guard let token = activeToken else {
      lock.unlock()
      return
    }
    pendingDeliveries[token, default: 0] += 1
    deliveryQueue.async { [self] in
      delivery(token)
      finishDelivery(for: token)
    }
    lock.unlock()
  }

  public func close(
    _ token: UUID,
    onDrained: @escaping @Sendable () -> Void
  ) {
    lock.lock()
    guard activeToken == token else {
      lock.unlock()
      deliveryQueue.async(execute: onDrained)
      return
    }
    activeToken = nil
    if pendingDeliveries[token, default: 0] == 0 {
      pendingDeliveries[token] = nil
      lock.unlock()
      deliveryQueue.async(execute: onDrained)
    } else {
      drainHandlers[token] = onDrained
      lock.unlock()
    }
  }

  public func cancel(_ token: UUID?) {
    guard let token else { return }
    lock.withLock {
      if activeToken == token {
        activeToken = nil
      }
      drainHandlers[token] = nil
    }
  }

  private func finishDelivery(for token: UUID) {
    var drainHandler: (@Sendable () -> Void)?
    lock.lock()
    let remaining = max(0, pendingDeliveries[token, default: 1] - 1)
    pendingDeliveries[token] = remaining
    if remaining == 0, activeToken != token {
      pendingDeliveries[token] = nil
      drainHandler = drainHandlers.removeValue(forKey: token)
    }
    lock.unlock()
    drainHandler?()
  }
}

extension NSLock {
  fileprivate func withLock<T>(_ operation: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try operation()
  }
}
