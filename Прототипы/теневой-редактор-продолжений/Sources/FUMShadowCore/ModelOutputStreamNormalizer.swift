import Foundation

struct ModelOutputStreamNormalizer: Sendable {
  private enum Mode: Sendable {
    case undecided
    case awaitingPostEchoContent
    case passthrough
  }

  private static let helpSignatures = [
    Data("Run a model\n\nUsage:\n  ollama run MODEL".utf8),
    Data("Run a model\r\n\r\nUsage:\r\n  ollama run MODEL".utf8),
    Data("Usage:\n  ollama run MODEL".utf8),
    Data("Usage:\r\n  ollama run MODEL".utf8),
  ]

  private let context: Data
  private let horizonBytes: Int
  private var mode: Mode = .undecided
  private var pending = Data()
  private var emittedByteCount = 0

  init(context: Data, horizonBytes: Int) {
    precondition(horizonBytes > 0, "horizonBytes must be positive")
    self.context = context
    self.horizonBytes = horizonBytes
  }

  var isComplete: Bool {
    emittedByteCount >= horizonBytes
  }

  static func rawOutputByteLimit(contextByteCount: Int, horizonBytes: Int) -> Int {
    let echoAllowance = min(max(contextByteCount, 0), horizonBytes)
    let (combined, overflow) = horizonBytes.addingReportingOverflow(echoAllowance)
    return max(64, overflow ? Int.max : combined)
  }

  mutating func append(_ data: Data) throws -> Data {
    guard !data.isEmpty, !isComplete else { return Data() }

    switch mode {
    case .passthrough:
      return emit(data)
    case .awaitingPostEchoContent:
      pending.append(data)
      if Self.isConfirmedHelp(pending) {
        throw LocalRuntimeError.invalidModelOutput(.commandHelp)
      }
      guard pending.contains(where: { !$0.isASCIIWhitespace }) else {
        return Data()
      }
      mode = .passthrough
      return emitPending()
    case .undecided:
      pending.append(data)
      if Self.isConfirmedHelp(pending) {
        throw LocalRuntimeError.invalidModelOutput(.commandHelp)
      }

      let stillCouldBeHelp = Self.couldBeHelpPrefix(pending)
      if !context.isEmpty, pending.starts(with: context) {
        pending.removeFirst(context.count)
        mode = .awaitingPostEchoContent
        guard pending.contains(where: { !$0.isASCIIWhitespace }) else {
          return Data()
        }
        mode = .passthrough
        return emitPending()
      }

      if context.count > horizonBytes,
        Self.commonPrefixLength(pending, context) >= horizonBytes
      {
        throw LocalRuntimeError.invalidModelOutput(.echoedContext)
      }

      if pending.count < context.count, context.starts(with: pending) {
        return Data()
      }

      guard !stillCouldBeHelp else { return Data() }
      mode = .passthrough
      return emitPending()
    }
  }

  mutating func finish() throws -> Data {
    if Self.isConfirmedHelp(pending) {
      throw LocalRuntimeError.invalidModelOutput(.commandHelp)
    }

    switch mode {
    case .undecided:
      if !pending.isEmpty, !context.isEmpty, context.starts(with: pending) {
        throw LocalRuntimeError.invalidModelOutput(.echoedContext)
      }
      mode = .passthrough
      let final = emitPending()
      if emittedByteCount == 0 {
        throw LocalRuntimeError.invalidModelOutput(.emptyOutput)
      }
      return final
    case .awaitingPostEchoContent:
      if !pending.contains(where: { !$0.isASCIIWhitespace }) {
        throw LocalRuntimeError.invalidModelOutput(.echoedContext)
      }
      mode = .passthrough
      return emitPending()
    case .passthrough:
      if emittedByteCount == 0 {
        throw LocalRuntimeError.invalidModelOutput(.emptyOutput)
      }
      return Data()
    }
  }

  private mutating func emitPending() -> Data {
    let result = emit(pending)
    pending.removeAll(keepingCapacity: true)
    return result
  }

  private mutating func emit(_ data: Data) -> Data {
    let remaining = max(horizonBytes - emittedByteCount, 0)
    let accepted = Data(data.prefix(remaining))
    emittedByteCount += accepted.count
    return accepted
  }

  private static func isConfirmedHelp(_ data: Data) -> Bool {
    helpSignatures.contains { data.starts(with: $0) }
  }

  private static func couldBeHelpPrefix(_ data: Data) -> Bool {
    helpSignatures.contains { $0.starts(with: data) }
  }

  private static func commonPrefixLength(_ left: Data, _ right: Data) -> Int {
    var count = 0
    for (leftByte, rightByte) in zip(left, right) {
      guard leftByte == rightByte else { break }
      count += 1
    }
    return count
  }
}

extension UInt8 {
  fileprivate var isASCIIWhitespace: Bool {
    self == 0x09 || self == 0x0A || self == 0x0D || self == 0x20
  }
}
