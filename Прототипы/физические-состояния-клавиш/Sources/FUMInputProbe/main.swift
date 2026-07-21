import FUMInputCore
import FUMInputMac
import Foundation

private struct ComparisonReport: Codable {
  let matrix: SourceComparison
  let macOS: SourceRecommendation
  let portableApple: SourceRecommendation
}

private final class TraceCollector: @unchecked Sendable {
  private let lock = NSLock()
  private var reducer = PhysicalKeyStateReducer()
  private(set) var acceptedCount = 0
  private(set) var rejectionCounts: [ObservationRejection: Int] = [:]
  private let encoder: JSONEncoder

  init() {
    encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  }

  func consume(_ observation: PhysicalKeyObservation) {
    lock.lock()
    defer { lock.unlock() }
    switch reducer.consume(observation) {
    case .accepted(let transition):
      let record = PhysicalKeyTraceRecord(
        sequenceNumber: UInt64(acceptedCount + 1),
        transition: transition
      )
      guard let data = try? encoder.encode(record) else {
        return
      }
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data([0x0A]))
      acceptedCount += 1
    case .rejected(let reason):
      rejectionCounts[reason, default: 0] += 1
    }
  }

  func summary() -> String {
    lock.lock()
    defer { lock.unlock() }
    let rejected =
      rejectionCounts
      .sorted { $0.key.rawValue < $1.key.rawValue }
      .map { "\($0.key.rawValue)=\($0.value)" }
      .joined(separator: ",")
    return "accepted=\(acceptedCount) rejected={\(rejected)}"
  }
}

private func encodeJSON<T: Encodable>(_ value: T) throws {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  let data = try encoder.encode(value)
  FileHandle.standardOutput.write(data)
  FileHandle.standardOutput.write(Data([0x0A]))
}

private func writeError(_ message: String) {
  FileHandle.standardError.write(Data((message + "\n").utf8))
}

private func makeSource(_ rawValue: String) throws -> any MacKeyboardObservationSource {
  guard let source = InputSourceID(rawValue: rawValue) else {
    throw MacKeyboardSourceError.sourceUnavailable(
      "неизвестный источник: \(rawValue)"
    )
  }
  return try MacKeyboardObservationSourceFactory.make(source)
}

private func printUsage() {
  print(
    """
    Использование:
      FUMInputProbe matrix
      FUMInputProbe environment
      FUMInputProbe devices
      FUMInputProbe record --source <iohid-manager|gc-keyboard|cg-event-tap|ns-event> --seconds <1...3600>

    record запускается только явно, пишет в stdout JSONL первичных изменений
    физического состояния и не сохраняет автоповтор или неизменившееся состояние.
    """
  )
}

private func option(_ name: String, in arguments: [String]) -> String? {
  guard let index = arguments.firstIndex(of: name),
    arguments.indices.contains(index + 1)
  else {
    return nil
  }
  return arguments[index + 1]
}

private func run() throws {
  let arguments = Array(CommandLine.arguments.dropFirst())
  guard let command = arguments.first else {
    printUsage()
    return
  }
  switch command {
  case "matrix":
    let matrix = SourceComparison.defaultMatrix
    try encodeJSON(
      ComparisonReport(
        matrix: matrix,
        macOS: matrix.recommendation(for: .macOS),
        portableApple: matrix.recommendation(for: .portableApple)
      ))
  case "environment":
    try encodeJSON(MacInputEnvironment.snapshot())
  case "devices":
    try encodeJSON(IOHIDKeyboardSource.inventory())
  case "record":
    guard let rawSource = option("--source", in: arguments),
      let rawSeconds = option("--seconds", in: arguments),
      let seconds = TimeInterval(rawSeconds),
      (1...3600).contains(seconds)
    else {
      throw MacKeyboardSourceError.sourceUnavailable(
        "record требует --source и --seconds от 1 до 3600"
      )
    }
    let source = try makeSource(rawSource)
    let collector = TraceCollector()
    try source.start { observation in
      collector.consume(observation)
    }
    defer {
      source.stop()
      writeError(collector.summary())
    }
    RunLoop.current.run(until: Date().addingTimeInterval(seconds))
  case "help", "--help", "-h":
    printUsage()
  default:
    throw MacKeyboardSourceError.sourceUnavailable(
      "неизвестная команда: \(command)"
    )
  }
}

do {
  try run()
} catch {
  writeError("Ошибка: \(error)")
  printUsage()
  exit(2)
}
