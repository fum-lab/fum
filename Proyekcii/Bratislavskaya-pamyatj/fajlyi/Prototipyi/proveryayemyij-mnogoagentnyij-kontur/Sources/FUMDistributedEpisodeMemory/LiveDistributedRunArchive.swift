import Darwin
import FUMReproducibleMemoryPopulation
import FUMVerifiableMultiAgentContour
import Foundation

public enum LiveDistributedRunArchiveError: Error, Equatable, Sendable {
  case invalidRequest(String)
  case unsafeSourcePath(String)
  case artifactReadFailed(String)
  case artifactHashMismatch(String)
  case artifactNotFound(String)
  case incompatibleGeneration(String)
  case corruptGeneration(String)
  case generationConflict(expected: String?, actual: String?)
  case generationStore(String)
}

extension LiveDistributedRunArchiveError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidRequest(let message), .incompatibleGeneration(let message),
      .corruptGeneration(let message), .generationStore(let message):
      return message
    case .unsafeSourcePath(let path):
      return "Недопустимый путь входного артефакта: \(path)."
    case .artifactReadFailed(let artifactID):
      return "Не удалось безопасно прочитать артефакт \(artifactID)."
    case .artifactHashMismatch(let artifactID):
      return "SHA-256 артефакта \(artifactID) не совпадает с манифестом."
    case .artifactNotFound(let artifactID):
      return "Артефакт \(artifactID) отсутствует в подтверждённом поколении."
    case .generationConflict(let expected, let actual):
      return
        "Конфликт поколения живого прогона: ожидалось \(expected ?? "пустое состояние"), подтверждено \(actual ?? "пустое состояние")."
    }
  }
}

public struct LiveDistributedRunArtifactSource:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let artifactID: String
  public let kind: String
  public let logicalPath: String
  public let mediaType: String
  public let sourcePath: String
  public let contentSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case artifactID = "artifact_id"
    case kind
    case logicalPath = "logical_path"
    case mediaType = "media_type"
    case sourcePath = "source_path"
    case contentSHA256 = "content_sha256"
  }

  public init(
    schemaVersion: Int = 1,
    artifactID: String,
    kind: String,
    logicalPath: String,
    mediaType: String,
    sourcePath: String,
    contentSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.artifactID = artifactID
    self.kind = kind
    self.logicalPath = logicalPath
    self.mediaType = mediaType
    self.sourcePath = sourcePath
    self.contentSHA256 = contentSHA256
  }
}

public struct LiveDistributedRunCorrelationGroup:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let groupID: String
  public let kind: String
  public let basis: String
  public let memberArtifactIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case groupID = "group_id"
    case kind
    case basis
    case memberArtifactIDs = "member_artifact_ids"
  }

  public init(
    schemaVersion: Int = 1,
    groupID: String,
    kind: String,
    basis: String,
    memberArtifactIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.groupID = groupID
    self.kind = kind
    self.basis = basis
    self.memberArtifactIDs = memberArtifactIDs
  }
}

public enum LiveDistributedRunDecisionStatus:
  String, Codable, Equatable, Sendable
{
  case accepted
  case inconclusive
  case unresolvedConflict = "unresolved_conflict"
}

public struct LiveDistributedRunDecision:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let status: LiveDistributedRunDecisionStatus
  public let basisArtifactIDs: [String]
  public let selectedClaimIDs: [String]
  public let rejectedClaimIDs: [String]
  public let unresolvedDisagreementIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case status
    case basisArtifactIDs = "basis_artifact_ids"
    case selectedClaimIDs = "selected_claim_ids"
    case rejectedClaimIDs = "rejected_claim_ids"
    case unresolvedDisagreementIDs = "unresolved_disagreement_ids"
  }

  public init(
    schemaVersion: Int = 1,
    status: LiveDistributedRunDecisionStatus,
    basisArtifactIDs: [String],
    selectedClaimIDs: [String],
    rejectedClaimIDs: [String],
    unresolvedDisagreementIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.status = status
    self.basisArtifactIDs = basisArtifactIDs
    self.selectedClaimIDs = selectedClaimIDs
    self.rejectedClaimIDs = rejectedClaimIDs
    self.unresolvedDisagreementIDs = unresolvedDisagreementIDs
  }
}

public enum LiveDistributedRunTerminalOutcome:
  String, Codable, Equatable, Sendable
{
  case goalMet = "goal_met"
  case inconclusive
  case unresolvedConflict = "unresolved_conflict"
  case failed
}

public struct LiveDistributedRunTerminal:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let outcome: LiveDistributedRunTerminalOutcome
  public let reasonCode: String
  public let evidenceArtifactIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case outcome
    case reasonCode = "reason_code"
    case evidenceArtifactIDs = "evidence_artifact_ids"
  }

  public init(
    schemaVersion: Int = 1,
    outcome: LiveDistributedRunTerminalOutcome,
    reasonCode: String,
    evidenceArtifactIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.outcome = outcome
    self.reasonCode = reasonCode
    self.evidenceArtifactIDs = evidenceArtifactIDs
  }
}

public struct LiveDistributedRunHandoff:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let nextCardID: String
  public let nextWorkPackageArtifactID: String
  public let requiredArtifactIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case nextCardID = "next_card_id"
    case nextWorkPackageArtifactID = "next_work_package_artifact_id"
    case requiredArtifactIDs = "required_artifact_ids"
  }

  public init(
    schemaVersion: Int = 1,
    nextCardID: String,
    nextWorkPackageArtifactID: String,
    requiredArtifactIDs: [String]
  ) {
    self.schemaVersion = schemaVersion
    self.nextCardID = nextCardID
    self.nextWorkPackageArtifactID = nextWorkPackageArtifactID
    self.requiredArtifactIDs = requiredArtifactIDs
  }
}

public struct LiveDistributedRunProvenance:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let rootCodexThreadID: String
  public let orchestrationSurface: String
  public let modelIdentityObservation: String
  public let producerArtifactIDs: [String]
  public let verifierArtifactID: String
  public let hiddenReasoningPersisted: Bool
  public let orchestratorMessagesPersisted: Bool

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case rootCodexThreadID = "root_codex_thread_id"
    case orchestrationSurface = "orchestration_surface"
    case modelIdentityObservation = "model_identity_observation"
    case producerArtifactIDs = "producer_artifact_ids"
    case verifierArtifactID = "verifier_artifact_id"
    case hiddenReasoningPersisted = "hidden_reasoning_persisted"
    case orchestratorMessagesPersisted = "orchestrator_messages_persisted"
  }

  public init(
    schemaVersion: Int = 1,
    rootCodexThreadID: String,
    orchestrationSurface: String,
    modelIdentityObservation: String,
    producerArtifactIDs: [String],
    verifierArtifactID: String,
    hiddenReasoningPersisted: Bool,
    orchestratorMessagesPersisted: Bool
  ) {
    self.schemaVersion = schemaVersion
    self.rootCodexThreadID = rootCodexThreadID
    self.orchestrationSurface = orchestrationSurface
    self.modelIdentityObservation = modelIdentityObservation
    self.producerArtifactIDs = producerArtifactIDs
    self.verifierArtifactID = verifierArtifactID
    self.hiddenReasoningPersisted = hiddenReasoningPersisted
    self.orchestratorMessagesPersisted = orchestratorMessagesPersisted
  }
}

public struct LiveDistributedRunArchiveRequest:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let runID: String
  public let previousGenerationSHA256: String?
  public let question: String
  public let artifacts: [LiveDistributedRunArtifactSource]
  public let correlationGroups: [LiveDistributedRunCorrelationGroup]
  public let decision: LiveDistributedRunDecision
  public let terminal: LiveDistributedRunTerminal
  public let handoff: LiveDistributedRunHandoff
  public let provenance: LiveDistributedRunProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case runID = "run_id"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case question
    case artifacts
    case correlationGroups = "correlation_groups"
    case decision
    case terminal
    case handoff
    case provenance
  }

  public init(
    schemaVersion: Int = 1,
    runID: String,
    previousGenerationSHA256: String?,
    question: String,
    artifacts: [LiveDistributedRunArtifactSource],
    correlationGroups: [LiveDistributedRunCorrelationGroup],
    decision: LiveDistributedRunDecision,
    terminal: LiveDistributedRunTerminal,
    handoff: LiveDistributedRunHandoff,
    provenance: LiveDistributedRunProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.runID = runID
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.question = question
    self.artifacts = artifacts
    self.correlationGroups = correlationGroups
    self.decision = decision
    self.terminal = terminal
    self.handoff = handoff
    self.provenance = provenance
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    try decodeLiveCanonical(Self.self, data: data, kind: "запрос архива живого прогона")
  }

  public func replacingArtifactSHA256(
    artifactID: String,
    with contentSHA256: String
  ) -> Self {
    Self(
      schemaVersion: schemaVersion,
      runID: runID,
      previousGenerationSHA256: previousGenerationSHA256,
      question: question,
      artifacts: artifacts.map { artifact in
        guard artifact.artifactID == artifactID else { return artifact }
        return LiveDistributedRunArtifactSource(
          schemaVersion: artifact.schemaVersion,
          artifactID: artifact.artifactID,
          kind: artifact.kind,
          logicalPath: artifact.logicalPath,
          mediaType: artifact.mediaType,
          sourcePath: artifact.sourcePath,
          contentSHA256: contentSHA256
        )
      },
      correlationGroups: correlationGroups,
      decision: decision,
      terminal: terminal,
      handoff: handoff,
      provenance: provenance
    )
  }

  public func replacingPreviousGenerationSHA256(_ value: String?) -> Self {
    Self(
      schemaVersion: schemaVersion,
      runID: runID,
      previousGenerationSHA256: value,
      question: question,
      artifacts: artifacts,
      correlationGroups: correlationGroups,
      decision: decision,
      terminal: terminal,
      handoff: handoff,
      provenance: provenance
    )
  }
}

public struct LiveDistributedRunGeneration:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public static let currentSchemaVersion = 1
  public static let profileID = "fum.live-distributed-run-generation.v1"

  public let schemaVersion: Int
  public let generationProfile: String
  public let runID: String
  public let previousGenerationSHA256: String?
  public let requestBase64: String
  public let requestSHA256: String
  public let question: String
  public let artifactManifestSHA256: String
  public let artifacts: [SharedEpisodeEmbeddedArtifact]
  public let correlationGroups: [LiveDistributedRunCorrelationGroup]
  public let decision: LiveDistributedRunDecision
  public let terminal: LiveDistributedRunTerminal
  public let handoff: LiveDistributedRunHandoff
  public let provenance: LiveDistributedRunProvenance

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case generationProfile = "generation_profile"
    case runID = "run_id"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case requestBase64 = "request_base64"
    case requestSHA256 = "request_sha256"
    case question
    case artifactManifestSHA256 = "artifact_manifest_sha256"
    case artifacts
    case correlationGroups = "correlation_groups"
    case decision
    case terminal
    case handoff
    case provenance
  }

  public init(
    schemaVersion: Int = Self.currentSchemaVersion,
    generationProfile: String = Self.profileID,
    runID: String,
    previousGenerationSHA256: String?,
    requestBase64: String,
    requestSHA256: String,
    question: String,
    artifactManifestSHA256: String,
    artifacts: [SharedEpisodeEmbeddedArtifact],
    correlationGroups: [LiveDistributedRunCorrelationGroup],
    decision: LiveDistributedRunDecision,
    terminal: LiveDistributedRunTerminal,
    handoff: LiveDistributedRunHandoff,
    provenance: LiveDistributedRunProvenance
  ) {
    self.schemaVersion = schemaVersion
    self.generationProfile = generationProfile
    self.runID = runID
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.requestBase64 = requestBase64
    self.requestSHA256 = requestSHA256
    self.question = question
    self.artifactManifestSHA256 = artifactManifestSHA256
    self.artifacts = artifacts
    self.correlationGroups = correlationGroups
    self.decision = decision
    self.terminal = terminal
    self.handoff = handoff
    self.provenance = provenance
  }

  public static func decodeCanonical(_ data: Data) throws -> Self {
    let generation = try decodeLiveCanonical(
      Self.self,
      data: data,
      kind: "поколение живого прогона"
    )
    try LiveDistributedRunArchive.validate(generation)
    return generation
  }

  public func artifact(named artifactID: String) throws -> SharedEpisodeEmbeddedArtifact {
    guard let artifact = artifacts.first(where: { $0.artifactID == artifactID }) else {
      throw LiveDistributedRunArchiveError.artifactNotFound(artifactID)
    }
    return artifact
  }
}

public struct StoredLiveDistributedRunGeneration: Equatable, Sendable {
  public let generationSHA256: String
  public let generation: LiveDistributedRunGeneration

  public init(generationSHA256: String, generation: LiveDistributedRunGeneration) {
    self.generationSHA256 = generationSHA256
    self.generation = generation
  }
}

public struct PublishedLiveDistributedRunArchive: Equatable, Sendable {
  public let stored: StoredLiveDistributedRunGeneration
  public let reportData: Data

  public init(stored: StoredLiveDistributedRunGeneration, reportData: Data) {
    self.stored = stored
    self.reportData = reportData
  }
}

public struct LiveDistributedRunArchiveReport:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let state: String
  public let generationSHA256: String
  public let generation: LiveDistributedRunGeneration

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case state
    case generationSHA256 = "generation_sha256"
    case generation
  }

  public init(
    schemaVersion: Int = 1,
    state: String,
    generationSHA256: String,
    generation: LiveDistributedRunGeneration
  ) {
    self.schemaVersion = schemaVersion
    self.state = state
    self.generationSHA256 = generationSHA256
    self.generation = generation
  }
}

private struct LiveDistributedRunArtifactManifest:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  let schemaVersion: Int
  let artifacts: [SharedEpisodeEmbeddedArtifact]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case artifacts
  }
}

private struct LiveRunPackageReference: Decodable {
  let path: String
  let packageID: String
  let preflightContractSHA256: String

  enum CodingKeys: String, CodingKey {
    case path
    case packageID = "package_id"
    case preflightContractSHA256 = "preflight_contract_sha256"
  }
}

private struct LiveRunInputIdentity: Hashable {
  let path: String
  let sha256: String
}

private struct LiveRunHandoffInputIdentity: Hashable {
  let inputID: String
  let path: String
  let sha256: String
}

private indirect enum LiveRunJSONShape: Sendable {
  case array(LiveRunJSONShape)
  case boolean
  case integer
  case number
  case object(
    required: [String: LiveRunJSONShape],
    optional: [String: LiveRunJSONShape]
  )
  case string

  func accepts(_ value: LiveRunJSONValue) -> Bool {
    switch self {
    case .array(let itemShape):
      guard case .array(let values) = value else { return false }
      return values.allSatisfy(itemShape.accepts)
    case .boolean:
      guard case .boolean = value else { return false }
      return true
    case .integer:
      guard case .integer = value else { return false }
      return true
    case .number:
      switch value {
      case .integer, .number:
        return true
      default:
        return false
      }
    case .object(let required, let optional):
      guard case .object(let object) = value else { return false }
      let allowedKeys = Set(required.keys).union(optional.keys)
      guard Set(required.keys).isSubset(of: object.keys),
        Set(object.keys).isSubset(of: allowedKeys)
      else { return false }
      for (key, nestedValue) in object {
        guard let shape = required[key] ?? optional[key],
          shape.accepts(nestedValue)
        else { return false }
      }
      return true
    case .string:
      guard case .string = value else { return false }
      return true
    }
  }
}

private indirect enum LiveRunJSONValue: Sendable {
  case array([LiveRunJSONValue])
  case boolean
  case integer
  case number
  case object([String: LiveRunJSONValue])
  case string
  case null
}

private enum LiveRunJSONParsingError: Error {
  case invalidJSON
  case structureLimitExceeded
}

private struct LiveRunJSONParser {
  private static let maximumDepth = 128
  private static let maximumNodeCount = 100_000

  private let bytes: [UInt8]
  private var index = 0
  private var nodeCount = 0

  init(data: Data) {
    bytes = Array(data)
  }

  mutating func parse() throws -> LiveRunJSONValue {
    skipWhitespace()
    let value = try parseValue(depth: 0)
    skipWhitespace()
    guard index == bytes.count else {
      throw LiveRunJSONParsingError.invalidJSON
    }
    return value
  }

  private mutating func parseValue(depth: Int) throws -> LiveRunJSONValue {
    guard depth <= Self.maximumDepth, nodeCount < Self.maximumNodeCount else {
      throw LiveRunJSONParsingError.structureLimitExceeded
    }
    nodeCount += 1
    skipWhitespace()
    guard index < bytes.count else {
      throw LiveRunJSONParsingError.invalidJSON
    }
    switch bytes[index] {
    case 0x7B:
      return try parseObject(depth: depth)
    case 0x5B:
      return try parseArray(depth: depth)
    case 0x22:
      _ = try parseString()
      return .string
    case 0x74:
      try parseLiteral("true")
      return .boolean
    case 0x66:
      try parseLiteral("false")
      return .boolean
    case 0x6E:
      try parseLiteral("null")
      return .null
    case 0x2D, 0x30...0x39:
      return try parseNumber()
    default:
      throw LiveRunJSONParsingError.invalidJSON
    }
  }

  private mutating func parseObject(depth: Int) throws -> LiveRunJSONValue {
    try expect(0x7B)
    skipWhitespace()
    if consume(0x7D) { return .object([:]) }
    var object: [String: LiveRunJSONValue] = [:]
    while true {
      skipWhitespace()
      let key = try parseString()
      guard object[key] == nil else {
        throw LiveRunJSONParsingError.invalidJSON
      }
      skipWhitespace()
      try expect(0x3A)
      object[key] = try parseValue(depth: depth + 1)
      skipWhitespace()
      if consume(0x7D) { return .object(object) }
      try expect(0x2C)
    }
  }

  private mutating func parseArray(depth: Int) throws -> LiveRunJSONValue {
    try expect(0x5B)
    skipWhitespace()
    if consume(0x5D) { return .array([]) }
    var values: [LiveRunJSONValue] = []
    while true {
      values.append(try parseValue(depth: depth + 1))
      skipWhitespace()
      if consume(0x5D) { return .array(values) }
      try expect(0x2C)
    }
  }

  private mutating func parseString() throws -> String {
    let start = index
    try expect(0x22)
    while index < bytes.count {
      let byte = bytes[index]
      index += 1
      if byte == 0x22 {
        let data = Data(bytes[start..<index])
        guard
          let value = try JSONSerialization.jsonObject(
            with: data,
            options: [.fragmentsAllowed]
          ) as? String
        else {
          throw LiveRunJSONParsingError.invalidJSON
        }
        return value
      }
      if byte < 0x20 {
        throw LiveRunJSONParsingError.invalidJSON
      }
      if byte == 0x5C {
        guard index < bytes.count else {
          throw LiveRunJSONParsingError.invalidJSON
        }
        let escape = bytes[index]
        index += 1
        if escape == 0x75 {
          guard index + 4 <= bytes.count else {
            throw LiveRunJSONParsingError.invalidJSON
          }
          for digit in bytes[index..<(index + 4)] where !isHexDigit(digit) {
            throw LiveRunJSONParsingError.invalidJSON
          }
          index += 4
        }
      }
    }
    throw LiveRunJSONParsingError.invalidJSON
  }

  private mutating func parseNumber() throws -> LiveRunJSONValue {
    _ = consume(0x2D)
    guard index < bytes.count else {
      throw LiveRunJSONParsingError.invalidJSON
    }
    if consume(0x30) {
      if index < bytes.count, isDigit(bytes[index]) {
        throw LiveRunJSONParsingError.invalidJSON
      }
    } else {
      guard consumeDigit(in: 0x31...0x39) else {
        throw LiveRunJSONParsingError.invalidJSON
      }
      while index < bytes.count, isDigit(bytes[index]) {
        index += 1
      }
    }

    var isFractional = false
    if consume(0x2E) {
      isFractional = true
      guard consumeDigit(in: 0x30...0x39) else {
        throw LiveRunJSONParsingError.invalidJSON
      }
      while index < bytes.count, isDigit(bytes[index]) {
        index += 1
      }
    }
    if consume(0x65) || consume(0x45) {
      isFractional = true
      _ = consume(0x2B) || consume(0x2D)
      guard consumeDigit(in: 0x30...0x39) else {
        throw LiveRunJSONParsingError.invalidJSON
      }
      while index < bytes.count, isDigit(bytes[index]) {
        index += 1
      }
    }
    guard index == bytes.count || isDelimiter(bytes[index]) else {
      throw LiveRunJSONParsingError.invalidJSON
    }
    return isFractional ? .number : .integer
  }

  private mutating func parseLiteral(_ literal: String) throws {
    let literalBytes = Array(literal.utf8)
    guard index + literalBytes.count <= bytes.count,
      Array(bytes[index..<(index + literalBytes.count)]) == literalBytes
    else {
      throw LiveRunJSONParsingError.invalidJSON
    }
    index += literalBytes.count
  }

  private mutating func expect(_ byte: UInt8) throws {
    guard consume(byte) else {
      throw LiveRunJSONParsingError.invalidJSON
    }
  }

  private mutating func consume(_ byte: UInt8) -> Bool {
    guard index < bytes.count, bytes[index] == byte else { return false }
    index += 1
    return true
  }

  private mutating func consumeDigit(in range: ClosedRange<UInt8>) -> Bool {
    guard index < bytes.count, range.contains(bytes[index]) else { return false }
    index += 1
    return true
  }

  private mutating func skipWhitespace() {
    while index < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[index]) {
      index += 1
    }
  }

  private func isDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte)
  }

  private func isDelimiter(_ byte: UInt8) -> Bool {
    [0x20, 0x09, 0x0A, 0x0D, 0x2C, 0x5D, 0x7D].contains(byte)
  }

  private func isHexDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }
}

private struct LiveRunWorkPackageArtifact: Decodable {
  struct Input: Decodable {
    let inputID: String
    let path: String
    let sha256: String
    let required: Bool

    var identity: LiveRunInputIdentity {
      LiveRunInputIdentity(path: path, sha256: sha256)
    }

    var handoffIdentity: LiveRunHandoffInputIdentity {
      LiveRunHandoffInputIdentity(inputID: inputID, path: path, sha256: sha256)
    }

    enum CodingKeys: String, CodingKey {
      case inputID = "id"
      case path
      case sha256
      case required
    }
  }

  struct Handoff: Decodable {
    let format: String
    let requiredArtifacts: [String]

    enum CodingKeys: String, CodingKey {
      case format
      case requiredArtifacts = "required_artifacts"
    }
  }

  let schemaVersion: Int
  let packageID: String
  let inputs: [Input]
  let handoff: Handoff

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case packageID = "package_id"
    case inputs
    case handoff
  }
}

private struct LiveRunPreflightArtifact: Decodable {
  private struct Violation: Decodable {}

  let schemaVersion: Int
  let packageID: String
  let contractSHA256: String
  let decision: String
  private let violations: [Violation]
  let observedDurationSeconds: Double

  var hasViolations: Bool { !violations.isEmpty }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case packageID = "package_id"
    case contractSHA256 = "contract_sha256"
    case decision
    case violations
    case observedDurationSeconds = "observed_duration_seconds"
  }
}

private struct LiveRunContributionArtifact: Decodable {
  struct Claim: Decodable {
    let claimID: String

    enum CodingKeys: String, CodingKey {
      case claimID = "claim_id"
    }
  }

  struct Input: Decodable {
    let path: String
    let sha256: String

    var identity: LiveRunInputIdentity {
      LiveRunInputIdentity(path: path, sha256: sha256)
    }
  }

  let schemaVersion: Int
  let contributionID: String
  let publicExecutorID: String
  let role: String
  let package: LiveRunPackageReference
  let question: String
  let rootCodexThreadID: String
  let inputs: [Input]
  let claims: [Claim]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case contributionID = "contribution_id"
    case publicExecutorID = "public_executor_id"
    case role
    case package
    case question
    case rootCodexThreadID = "root_codex_thread_id"
    case inputs
    case claims
  }
}

private struct LiveRunVerificationArtifact: Decodable {
  struct Assessment: Decodable {
    let claimID: String
    let status: String

    enum CodingKeys: String, CodingKey {
      case claimID = "claim_id"
      case status
    }
  }

  struct Input: Decodable {
    let path: String
    let sha256: String

    var identity: LiveRunInputIdentity {
      LiveRunInputIdentity(path: path, sha256: sha256)
    }
  }

  let schemaVersion: Int
  let verificationID: String
  let publicExecutorID: String
  let role: String
  let package: LiveRunPackageReference
  let rootCodexThreadID: String
  let inputs: [Input]
  let overallOutcome: String
  let claimAssessments: [Assessment]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case verificationID = "verification_id"
    case publicExecutorID = "public_executor_id"
    case role
    case package
    case rootCodexThreadID = "root_codex_thread_id"
    case inputs
    case overallOutcome = "overall_outcome"
    case claimAssessments = "claim_assessments"
  }
}

private struct LiveRunDecisionArtifact: Decodable {
  let schemaVersion: Int
  let status: String
  let verificationArtifactID: String
  let selectedClaimIDs: [String]
  let rejectedClaimIDs: [String]
  let unresolvedDisagreementIDs: [String]
  let voteCountUsed: Bool

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case status
    case verificationArtifactID = "verification_artifact_id"
    case selectedClaimIDs = "selected_claim_ids"
    case rejectedClaimIDs = "rejected_claim_ids"
    case unresolvedDisagreementIDs = "unresolved_disagreement_ids"
    case voteCountUsed = "vote_count_used"
  }
}

private struct LiveRunTerminalArtifact: Decodable {
  let schemaVersion: Int
  let outcome: String
  let reasonCode: String
  let unresolvedDisagreementIDs: [String]
  let handoffNextCardID: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case outcome
    case reasonCode = "reason_code"
    case unresolvedDisagreementIDs = "unresolved_disagreement_ids"
    case handoffNextCardID = "handoff_next_card_id"
  }
}

private struct LiveRunEpisodePassportArtifact: Decodable {
  let schemaVersion: Int
  let question: String
  let rootCodexThreadID: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case question
    case rootCodexThreadID = "root_codex_thread_id"
  }
}

private struct LiveRunHandoffResultArtifact: Decodable {
  struct InputCheck: Decodable {
    let inputID: String
    let path: String
    let sha256: String
    let status: String

    var identity: LiveRunHandoffInputIdentity {
      LiveRunHandoffInputIdentity(inputID: inputID, path: path, sha256: sha256)
    }

    enum CodingKeys: String, CodingKey {
      case inputID = "input_id"
      case path
      case sha256
      case status
    }
  }

  let schemaVersion: Int
  let previousGenerationSHA256: String
  let previousNextCardID: String
  let previousWorkPackageArtifactID: String
  let previousWorkPackageContentSHA256: String
  let executedPackageID: String
  let rootCodexThreadID: String
  let inputChecks: [InputCheck]
  let terminalOutcome: String
  let outcome: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case previousGenerationSHA256 = "previous_generation_sha256"
    case previousNextCardID = "previous_next_card_id"
    case previousWorkPackageArtifactID = "previous_work_package_artifact_id"
    case previousWorkPackageContentSHA256 = "previous_work_package_content_sha256"
    case executedPackageID = "executed_package_id"
    case rootCodexThreadID = "root_codex_thread_id"
    case inputChecks = "input_checks"
    case terminalOutcome = "terminal_outcome"
    case outcome
  }
}

private struct LiveRunProvenanceArtifact: Decodable {
  struct Contribution: Decodable {
    let artifactID: String
    let publicExecutorID: String
    let role: String
    let packageID: String
    let inputManifestSHA256s: [String]
    let sawOtherContributionBeforePublication: Bool

    enum CodingKeys: String, CodingKey {
      case artifactID = "artifact_id"
      case publicExecutorID = "public_executor_id"
      case role
      case packageID = "package_id"
      case inputManifestSHA256s = "input_manifest_sha256s"
      case sawOtherContributionBeforePublication =
        "saw_other_contribution_before_publication"
    }
  }

  struct CorrelationGroup: Decodable, Equatable {
    let groupID: String
    let kind: String
    let basis: String
    let memberArtifactIDs: [String]

    enum CodingKeys: String, CodingKey {
      case groupID = "group_id"
      case kind
      case basis
      case memberArtifactIDs = "member_artifact_ids"
    }
  }

  struct ObservedSeparation: Decodable {
    let distinctRoles: Bool
    let distinctPackageIDs: Bool
    let nonOverlappingPrimaryInputs: Bool
    let resultsWithheldUntilBothPublished: Bool
    let semanticIndependenceProven: Bool

    enum CodingKeys: String, CodingKey {
      case distinctRoles = "distinct_roles"
      case distinctPackageIDs = "distinct_package_ids"
      case nonOverlappingPrimaryInputs = "non_overlapping_primary_inputs"
      case resultsWithheldUntilBothPublished =
        "results_withheld_until_both_published"
      case semanticIndependenceProven = "semantic_independence_proven"
    }
  }

  let schemaVersion: Int
  let rootCodexThreadID: String
  let contributions: [Contribution]
  let correlationGroups: [CorrelationGroup]
  let observedSeparation: ObservedSeparation
  let notSharedMemory: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case rootCodexThreadID = "root_codex_thread_id"
    case contributions
    case correlationGroups = "correlation_groups"
    case observedSeparation = "observed_separation"
    case notSharedMemory = "not_shared_memory"
  }
}

public enum LiveDistributedRunArchive {
  private static let maximumRequestBytes = 1_048_576
  private static let maximumArtifactBytes = 4_194_304
  private static let maximumTotalArtifactBytes = 8_388_608
  private static let currentPointerRelativePath =
    ["memory", "CURRENT.json"].joined(separator: String(UnicodeScalar(0x2F)!))
  private static let currentPointerPathSuffix =
    String(UnicodeScalar(0x2F)!) + currentPointerRelativePath

  public static func contentSHA256(_ data: Data) -> String {
    CanonicalMemoryJSON.sha256(data)
  }

  public static func readRequestFile(at url: URL) throws -> Data {
    let fileName = url.lastPathComponent
    guard isSafeRelativePath(fileName), !fileName.contains("/") else {
      throw LiveDistributedRunArchiveError.unsafeSourcePath(url.path)
    }
    return try readRegularFile(
      relativePath: fileName,
      rootURL: url.deletingLastPathComponent(),
      maximumBytes: maximumRequestBytes,
      artifactID: "archive.request"
    )
  }

  public static func canonicalizeRequest(_ data: Data) throws -> Data {
    guard data.count <= maximumRequestBytes else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Запрос архива превышает допустимый размер."
      )
    }
    do {
      let request = try JSONDecoder().decode(LiveDistributedRunArchiveRequest.self, from: data)
      let canonical = try request.canonicalJSONData()
      let inputObject = try JSONSerialization.jsonObject(with: data) as AnyObject
      let canonicalObject = try JSONSerialization.jsonObject(with: canonical) as AnyObject
      guard inputObject.isEqual(canonicalObject) else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Запрос архива содержит неизвестные поля или значения вне схемы."
        )
      }
      try validate(request)
      return canonical
    } catch let error as LiveDistributedRunArchiveError {
      throw error
    } catch {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Запрос архива не соответствует схеме версии 1."
      )
    }
  }

  public static func archive(
    requestData: Data,
    repositoryRoot: URL,
    storeRoot: URL
  ) throws -> StoredLiveDistributedRunGeneration {
    try archivePublication(
      requestData: requestData,
      repositoryRoot: repositoryRoot,
      storeRoot: storeRoot
    ).stored
  }

  public static func archivePublication(
    requestData: Data,
    repositoryRoot: URL,
    storeRoot: URL
  ) throws -> PublishedLiveDistributedRunArchive {
    guard requestData.count <= maximumRequestBytes else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Запрос архива превышает допустимый размер."
      )
    }
    let request: LiveDistributedRunArchiveRequest
    do {
      request = try LiveDistributedRunArchiveRequest.decodeCanonical(requestData)
    } catch let error as LiveDistributedRunArchiveError {
      throw error
    } catch {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Запрос архива не соответствует каноническому JSON или схеме."
      )
    }
    try validate(request)

    var totalBytes = 0
    var embedded: [SharedEpisodeEmbeddedArtifact] = []
    for source in request.artifacts.sorted(by: { $0.artifactID < $1.artifactID }) {
      let data = try readArtifact(source, repositoryRoot: repositoryRoot)
      totalBytes += data.count
      guard totalBytes <= maximumTotalArtifactBytes else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Совокупный размер артефактов превышает допустимый предел."
        )
      }
      guard contentSHA256(data) == source.contentSHA256 else {
        throw LiveDistributedRunArchiveError.artifactHashMismatch(source.artifactID)
      }
      embedded.append(
        SharedEpisodeEmbeddedArtifact(
          artifactID: source.artifactID,
          kind: source.kind,
          logicalPath: source.logicalPath,
          mediaType: source.mediaType,
          data: data
        )
      )
    }
    try validateFreshWorkPackages(
      request: request,
      embedded: embedded,
      repositoryRoot: repositoryRoot
    )
    let manifest = LiveDistributedRunArtifactManifest(
      schemaVersion: 1,
      artifacts: embedded
    )
    let generation = LiveDistributedRunGeneration(
      runID: request.runID,
      previousGenerationSHA256: request.previousGenerationSHA256,
      requestBase64: requestData.base64EncodedString(),
      requestSHA256: contentSHA256(requestData),
      question: request.question,
      artifactManifestSHA256: contentSHA256(try manifest.canonicalJSONData()),
      artifacts: embedded,
      correlationGroups: request.correlationGroups.map { group in
        LiveDistributedRunCorrelationGroup(
          schemaVersion: group.schemaVersion,
          groupID: group.groupID,
          kind: group.kind,
          basis: group.basis,
          memberArtifactIDs: group.memberArtifactIDs.sorted()
        )
      }.sorted { $0.groupID < $1.groupID },
      decision: normalized(request.decision),
      terminal: normalized(request.terminal),
      handoff: normalized(request.handoff),
      provenance: normalized(request.provenance)
    )
    try validate(generation)
    let predictedGenerationSHA256 = contentSHA256(try generation.canonicalJSONData())
    let reportData = try LiveDistributedRunArchiveReport(
      state: "archived",
      generationSHA256: predictedGenerationSHA256,
      generation: generation
    ).canonicalJSONData()
    let stored = try LiveDistributedRunArchiveStore(rootURL: storeRoot).commit(generation)
    guard stored.generationSHA256 == predictedGenerationSHA256 else {
      throw LiveDistributedRunArchiveError.generationStore(
        "Подтверждённый адрес поколения не совпал с предпроверенным отчётом."
      )
    }
    return PublishedLiveDistributedRunArchive(
      stored: stored,
      reportData: reportData
    )
  }

  static func validate(_ request: LiveDistributedRunArchiveRequest) throws {
    guard request.schemaVersion == 1,
      isIdentifier(request.runID),
      isNonempty(request.question),
      request.previousGenerationSHA256.map(isSHA256) ?? true
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Версия, идентификатор, вопрос или родитель запроса недопустимы."
      )
    }
    guard request.decision.schemaVersion == 1,
      request.terminal.schemaVersion == 1,
      request.handoff.schemaVersion == 1,
      request.provenance.schemaVersion == 1
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Вложенная схема запроса не поддерживается."
      )
    }
    try validateArtifactSources(request.artifacts)
    let kinds = Dictionary(
      uniqueKeysWithValues: request.artifacts.map { ($0.artifactID, $0.kind) }
    )
    let contributionIDs = request.artifacts.filter { $0.kind == "contribution" }
      .map(\.artifactID).sorted()
    let workPackageIDs = request.artifacts.filter { $0.kind == "work_package" }
      .map(\.artifactID)
    let preflightIDs = request.artifacts.filter { $0.kind == "preflight" }
      .map(\.artifactID)
    let provenanceIDs = request.artifacts.filter { $0.kind == "provenance" }
      .map(\.artifactID)
    guard
      hasExactArtifactProfile(
        request.artifacts.map(\.kind),
        isSuccessor: request.previousGenerationSHA256 != nil
      ),
      request.artifacts.allSatisfy({ $0.mediaType == "application/json" }),
      contributionIDs.count == 2,
      request.provenance.producerArtifactIDs.sorted() == contributionIDs,
      kinds[request.provenance.verifierArtifactID] == "verification",
      request.artifacts.contains(where: { $0.kind == "episode_passport" }),
      request.artifacts.contains(where: { $0.kind == "decision" }),
      request.artifacts.contains(where: { $0.kind == "terminal" }),
      workPackageIDs.count == 4,
      preflightIDs.count == 4,
      provenanceIDs.count == 1
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Запрос должен содержать точный профиль из 15 артефактов первого запуска либо 16 артефактов преемника с результатом прежней передачи."
      )
    }
    try validateReferences(request, kinds: kinds, contributionIDs: contributionIDs)
    guard !request.provenance.hiddenReasoningPersisted,
      !request.provenance.orchestratorMessagesPersisted,
      isNonempty(request.provenance.rootCodexThreadID),
      isNonempty(request.provenance.orchestrationSurface),
      isNonempty(request.provenance.modelIdentityObservation)
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Скрытое рассуждение и сообщения оркестратора не являются общей памятью."
      )
    }
    if request.terminal.outcome == .goalMet {
      guard request.decision.status == .accepted,
        request.decision.unresolvedDisagreementIDs.isEmpty
      else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "goal_met требует принятого решения без неустранённых разногласий."
        )
      }
    }
  }

  static func validate(_ generation: LiveDistributedRunGeneration) throws {
    guard generation.schemaVersion == LiveDistributedRunGeneration.currentSchemaVersion,
      generation.generationProfile == LiveDistributedRunGeneration.profileID,
      isIdentifier(generation.runID),
      isNonempty(generation.question),
      isSHA256(generation.requestSHA256),
      generation.previousGenerationSHA256.map(isSHA256) ?? true
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение имеет недопустимую схему или идентичность."
      )
    }
    guard let requestData = Data(base64Encoded: generation.requestBase64),
      requestData.base64EncodedString() == generation.requestBase64,
      requestData.count <= maximumRequestBytes,
      contentSHA256(requestData) == generation.requestSHA256
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Канонический запрос поколения отсутствует или не совпадает со своим SHA-256."
      )
    }
    let request: LiveDistributedRunArchiveRequest
    do {
      request = try LiveDistributedRunArchiveRequest.decodeCanonical(requestData)
      try validate(request)
    } catch {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Встроенный запрос поколения не проходит исходную проверку архива."
      )
    }
    let artifactIDs = generation.artifacts.map(\.artifactID)
    guard artifactIDs == artifactIDs.sorted(),
      Set(artifactIDs).count == artifactIDs.count
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Артефакты поколения не упорядочены или повторяются."
      )
    }
    for artifact in generation.artifacts {
      guard artifact.schemaVersion == 1,
        isIdentifier(artifact.artifactID),
        isNonempty(artifact.kind),
        isSafeRelativePath(artifact.logicalPath),
        isNonempty(artifact.mediaType),
        isSHA256(artifact.contentSHA256)
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Встроенный артефакт имеет недопустимую схему или путь."
        )
      }
      _ = try decodedArtifactData(artifact)
    }
    let manifest = LiveDistributedRunArtifactManifest(
      schemaVersion: 1,
      artifacts: generation.artifacts
    )
    guard
      generation.artifactManifestSHA256
        == contentSHA256(try manifest.canonicalJSONData())
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Хэш манифеста артефактов не совпадает с поколением."
      )
    }
    guard generation.decision.schemaVersion == 1,
      generation.terminal.schemaVersion == 1,
      generation.handoff.schemaVersion == 1,
      generation.provenance.schemaVersion == 1
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение содержит неподдерживаемую вложенную схему."
      )
    }
    let kinds = Dictionary(
      uniqueKeysWithValues: generation.artifacts.map { ($0.artifactID, $0.kind) }
    )
    let contributionIDs = generation.artifacts.filter { $0.kind == "contribution" }
      .map(\.artifactID).sorted()
    let passportIDs = generation.artifacts.filter { $0.kind == "episode_passport" }
      .map(\.artifactID)
    let decisionArtifactIDs = generation.artifacts.filter { $0.kind == "decision" }
      .map(\.artifactID)
    let terminalArtifactIDs = generation.artifacts.filter { $0.kind == "terminal" }
      .map(\.artifactID)
    let workPackageArtifactIDs = generation.artifacts.filter {
      $0.kind == "work_package"
    }.map(\.artifactID)
    let preflightArtifactIDs = generation.artifacts.filter { $0.kind == "preflight" }
      .map(\.artifactID)
    let provenanceArtifactIDs = generation.artifacts.filter {
      $0.kind == "provenance"
    }.map(\.artifactID)
    guard
      hasExactArtifactProfile(
        generation.artifacts.map(\.kind),
        isSuccessor: generation.previousGenerationSHA256 != nil
      ),
      generation.artifacts.allSatisfy({ $0.mediaType == "application/json" }),
      contributionIDs.count == 2,
      generation.provenance.producerArtifactIDs == contributionIDs,
      kinds[generation.provenance.verifierArtifactID] == "verification",
      passportIDs.count == 1,
      decisionArtifactIDs.count == 1,
      terminalArtifactIDs.count == 1,
      workPackageArtifactIDs.count == 4,
      preflightArtifactIDs.count == 4,
      provenanceArtifactIDs.count == 1
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение не соответствует точному профилю 15 артефактов первого запуска либо 16 артефактов преемника."
      )
    }
    try validateRequestProjection(request, against: generation)
    let artifactSet = Set(artifactIDs)
    guard references(in: generation).allSatisfy(artifactSet.contains),
      kinds[generation.handoff.nextWorkPackageArtifactID] == "work_package",
      generation.handoff.requiredArtifactIDs.contains(
        generation.handoff.nextWorkPackageArtifactID
      ),
      generation.decision.basisArtifactIDs.contains(
        generation.provenance.verifierArtifactID
      ),
      generation.terminal.evidenceArtifactIDs.contains(
        generation.provenance.verifierArtifactID
      ),
      decisionArtifactIDs.allSatisfy(
        generation.terminal.evidenceArtifactIDs.contains
      ),
      !generation.provenance.hiddenReasoningPersisted,
      !generation.provenance.orchestratorMessagesPersisted,
      isNonempty(generation.provenance.rootCodexThreadID),
      isNonempty(generation.provenance.orchestrationSurface),
      isNonempty(generation.provenance.modelIdentityObservation),
      isNonempty(generation.handoff.nextCardID),
      isNonempty(generation.terminal.reasonCode),
      !generation.decision.basisArtifactIDs.isEmpty
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение содержит незамкнутые ссылки или запрещённую скрытую память."
      )
    }
    try validateCanonicalCollections(generation)
    try validateEmbeddedArtifactSemantics(generation, request: request)
    if generation.terminal.outcome == .goalMet {
      guard generation.decision.status == .accepted,
        !generation.decision.selectedClaimIDs.isEmpty,
        generation.decision.unresolvedDisagreementIDs.isEmpty
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "goal_met поколения требует принятого доказательного решения без разногласий."
        )
      }
    }
  }

  private static func hasExactArtifactProfile(
    _ kinds: [String],
    isSuccessor: Bool
  ) -> Bool {
    var expected = [
      "contribution": 2,
      "decision": 1,
      "episode_passport": 1,
      "preflight": 4,
      "provenance": 1,
      "terminal": 1,
      "verification": 1,
      "work_package": 4,
    ]
    if isSuccessor {
      expected["handoff_result"] = 1
    }
    let actual = Dictionary(grouping: kinds, by: { $0 }).mapValues(\.count)
    return actual == expected
  }

  private static func validateRequestProjection(
    _ request: LiveDistributedRunArchiveRequest,
    against generation: LiveDistributedRunGeneration
  ) throws {
    let normalizedGroups = request.correlationGroups.map { group in
      LiveDistributedRunCorrelationGroup(
        schemaVersion: group.schemaVersion,
        groupID: group.groupID,
        kind: group.kind,
        basis: group.basis,
        memberArtifactIDs: group.memberArtifactIDs.sorted()
      )
    }.sorted { $0.groupID < $1.groupID }
    guard request.runID == generation.runID,
      request.previousGenerationSHA256 == generation.previousGenerationSHA256,
      request.question == generation.question,
      normalizedGroups == generation.correlationGroups,
      normalized(request.decision) == generation.decision,
      normalized(request.terminal) == generation.terminal,
      normalized(request.handoff) == generation.handoff,
      normalized(request.provenance) == generation.provenance,
      request.artifacts.count == generation.artifacts.count
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение не является точной проекцией встроенного запроса архива."
      )
    }
    let sources = Dictionary(
      uniqueKeysWithValues: request.artifacts.map { ($0.artifactID, $0) }
    )
    for artifact in generation.artifacts {
      guard let source = sources[artifact.artifactID],
        source.kind == artifact.kind,
        source.logicalPath == artifact.logicalPath,
        source.mediaType == artifact.mediaType,
        source.contentSHA256 == artifact.contentSHA256
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Встроенный артефакт не совпадает с манифестом запроса."
        )
      }
    }
  }

  private static func validateCanonicalCollections(
    _ generation: LiveDistributedRunGeneration
  ) throws {
    let groupIDs = generation.correlationGroups.map(\.groupID)
    guard !groupIDs.isEmpty,
      groupIDs == groupIDs.sorted(),
      Set(groupIDs).count == groupIDs.count,
      generation.decision.basisArtifactIDs
        == generation.decision.basisArtifactIDs.sorted(),
      Set(generation.decision.basisArtifactIDs).count
        == generation.decision.basisArtifactIDs.count,
      generation.decision.selectedClaimIDs
        == generation.decision.selectedClaimIDs.sorted(),
      Set(generation.decision.selectedClaimIDs).count
        == generation.decision.selectedClaimIDs.count,
      generation.decision.rejectedClaimIDs
        == generation.decision.rejectedClaimIDs.sorted(),
      Set(generation.decision.rejectedClaimIDs).count
        == generation.decision.rejectedClaimIDs.count,
      generation.decision.unresolvedDisagreementIDs
        == generation.decision.unresolvedDisagreementIDs.sorted(),
      Set(generation.decision.unresolvedDisagreementIDs).count
        == generation.decision.unresolvedDisagreementIDs.count,
      Set(generation.decision.selectedClaimIDs).isDisjoint(
        with: Set(generation.decision.rejectedClaimIDs)
      ),
      generation.terminal.evidenceArtifactIDs
        == generation.terminal.evidenceArtifactIDs.sorted(),
      Set(generation.terminal.evidenceArtifactIDs).count
        == generation.terminal.evidenceArtifactIDs.count,
      generation.handoff.requiredArtifactIDs
        == generation.handoff.requiredArtifactIDs.sorted(),
      Set(generation.handoff.requiredArtifactIDs).count
        == generation.handoff.requiredArtifactIDs.count,
      generation.provenance.producerArtifactIDs
        == generation.provenance.producerArtifactIDs.sorted()
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Коллекции поколения не канонизированы или содержат повторы."
      )
    }
    let artifactSet = Set(generation.artifacts.map(\.artifactID))
    let contributionSet = Set(generation.provenance.producerArtifactIDs)
    var groupedContributions = Set<String>()
    for group in generation.correlationGroups {
      guard group.schemaVersion == 1,
        isIdentifier(group.groupID),
        isNonempty(group.kind),
        isNonempty(group.basis),
        group.memberArtifactIDs.count >= 2,
        group.memberArtifactIDs == group.memberArtifactIDs.sorted(),
        Set(group.memberArtifactIDs).count == group.memberArtifactIDs.count,
        group.memberArtifactIDs.allSatisfy(artifactSet.contains)
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Группа корреляции поколения неполна, неканонична или содержит незамкнутую ссылку."
        )
      }
      groupedContributions.formUnion(
        group.memberArtifactIDs.filter(contributionSet.contains)
      )
    }
    guard groupedContributions == contributionSet else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Не каждый вклад поколения входит в наблюдаемую группу корреляции."
      )
    }
  }

  private static func validateEmbeddedArtifactSemantics(
    _ generation: LiveDistributedRunGeneration,
    request: LiveDistributedRunArchiveRequest
  ) throws {
    for artifact in generation.artifacts where artifact.mediaType == "application/json" {
      let data = try decodedArtifactData(artifact)
      var parser = LiveRunJSONParser(data: data)
      guard
        let object = try? parser.parse(),
        let shape = artifactShapes[artifact.kind],
        shape.accepts(object)
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "JSON-артефакт \(artifact.artifactID) содержит неизвестное поле, неверный вложенный тип или не соответствует закрытому профилю."
        )
      }
    }

    let workPackageArtifactIDs = generation.artifacts.filter {
      $0.kind == "work_package"
    }.map(\.artifactID)
    var workPackagesByPackageID: [String: LiveRunWorkPackageArtifact] = [:]
    var packageArtifactIDByPackageID: [String: String] = [:]
    for artifactID in workPackageArtifactIDs {
      let package: LiveRunWorkPackageArtifact = try decodeArtifact(
        artifactID,
        from: generation
      )
      guard package.schemaVersion == 1,
        isIdentifier(package.packageID),
        !package.inputs.isEmpty,
        package.inputs.allSatisfy({
          isSafeRelativePath($0.path) && isSHA256($0.sha256) && $0.required
        }),
        Set(package.inputs.map(\.identity)).count == package.inputs.count,
        isNonempty(package.handoff.format),
        !package.handoff.requiredArtifacts.isEmpty,
        package.handoff.requiredArtifacts.allSatisfy(isSafeRelativePath),
        Set(package.handoff.requiredArtifacts).count
          == package.handoff.requiredArtifacts.count,
        workPackagesByPackageID[package.packageID] == nil
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Рабочие пакеты поколения неполны, повторяются или имеют недопустимую схему."
        )
      }
      workPackagesByPackageID[package.packageID] = package
      packageArtifactIDByPackageID[package.packageID] = artifactID
    }

    let preflightArtifactIDs = generation.artifacts.filter {
      $0.kind == "preflight"
    }.map(\.artifactID)
    var preflightArtifactIDByPackageID: [String: String] = [:]
    for artifactID in preflightArtifactIDs {
      let preflight: LiveRunPreflightArtifact = try decodeArtifact(
        artifactID,
        from: generation
      )
      guard preflight.schemaVersion == 1,
        isIdentifier(preflight.packageID),
        preflight.decision == "ready",
        !preflight.hasViolations,
        preflight.observedDurationSeconds.isFinite,
        preflight.observedDurationSeconds >= 0,
        preflightArtifactIDByPackageID[preflight.packageID] == nil,
        let packageArtifactID = packageArtifactIDByPackageID[preflight.packageID],
        preflight.contractSHA256
          == (try generation.artifact(named: packageArtifactID)).contentSHA256
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Предпусковой отчёт не подтверждает единственный точный рабочий пакет со статусом ready."
        )
      }
      preflightArtifactIDByPackageID[preflight.packageID] = artifactID
    }
    guard
      preflightArtifactIDByPackageID.keys.sorted()
        == workPackagesByPackageID.keys.sorted()
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Не каждый рабочий пакет поколения имеет ровно один связанный preflight."
      )
    }

    var contributionClaimIDs = Set<String>()
    var contributionPackages: [String: LiveRunPackageReference] = [:]
    var contributionExecutorIDs: [String: String] = [:]
    var contributionRoles: [String: String] = [:]
    var contributionInputs: [String: [LiveRunInputIdentity]] = [:]
    for artifactID in generation.provenance.producerArtifactIDs {
      let contribution: LiveRunContributionArtifact = try decodeArtifact(
        artifactID,
        from: generation
      )
      let claimIDs = contribution.claims.map(\.claimID)
      guard contribution.schemaVersion == 1,
        contribution.contributionID == artifactID,
        isIdentifier(contribution.publicExecutorID),
        isIdentifier(contribution.role),
        isSafeRelativePath(contribution.package.path),
        isIdentifier(contribution.package.packageID),
        isSHA256(contribution.package.preflightContractSHA256),
        contribution.question == generation.question,
        contribution.rootCodexThreadID == generation.provenance.rootCodexThreadID,
        !contribution.inputs.isEmpty,
        contribution.inputs.allSatisfy({
          isSafeRelativePath($0.path) && isSHA256($0.sha256)
        }),
        Set(contribution.inputs.map(\.identity)).count == contribution.inputs.count,
        !claimIDs.isEmpty,
        claimIDs.allSatisfy(isIdentifier),
        Set(claimIDs).count == claimIDs.count,
        contributionClaimIDs.isDisjoint(with: claimIDs)
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Вклад \(artifactID) не совпадает с происхождением или содержит повторное утверждение."
        )
      }
      contributionClaimIDs.formUnion(claimIDs)
      contributionPackages[artifactID] = contribution.package
      contributionExecutorIDs[artifactID] = contribution.publicExecutorID
      contributionRoles[artifactID] = contribution.role
      contributionInputs[artifactID] = contribution.inputs.map(\.identity)
    }

    let verification: LiveRunVerificationArtifact = try decodeArtifact(
      generation.provenance.verifierArtifactID,
      from: generation
    )
    let assessedClaimIDs = verification.claimAssessments.map(\.claimID)
    let allowedAssessmentStatuses = Set(["passed", "failed", "inconclusive"])
    guard verification.schemaVersion == 1,
      verification.verificationID == generation.provenance.verifierArtifactID,
      isIdentifier(verification.publicExecutorID),
      isIdentifier(verification.role),
      isSafeRelativePath(verification.package.path),
      isIdentifier(verification.package.packageID),
      isSHA256(verification.package.preflightContractSHA256),
      verification.rootCodexThreadID == generation.provenance.rootCodexThreadID,
      !verification.inputs.isEmpty,
      verification.inputs.allSatisfy({
        isSafeRelativePath($0.path) && isSHA256($0.sha256)
      }),
      Set(verification.inputs.map(\.identity)).count == verification.inputs.count,
      !contributionExecutorIDs.values.contains(verification.publicExecutorID),
      !contributionRoles.values.contains(verification.role),
      Set(assessedClaimIDs) == contributionClaimIDs,
      Set(assessedClaimIDs).count == assessedClaimIDs.count,
      verification.claimAssessments.allSatisfy({
        allowedAssessmentStatuses.contains($0.status)
      })
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Отдельная проверка не покрывает точный набор утверждений двух вкладов."
      )
    }
    let passedClaimIDs = Set(
      verification.claimAssessments.filter { $0.status == "passed" }.map(\.claimID)
    )
    let decidedClaimIDs = Set(
      generation.decision.selectedClaimIDs + generation.decision.rejectedClaimIDs
    )
    guard decidedClaimIDs.isSubset(of: contributionClaimIDs),
      Set(generation.decision.selectedClaimIDs).isSubset(of: passedClaimIDs)
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Доказательное решение ссылается на отсутствующее или не прошедшее проверку утверждение."
      )
    }

    let decisionArtifactID = try singleArtifactID(kind: "decision", in: generation)
    let decision: LiveRunDecisionArtifact = try decodeArtifact(
      decisionArtifactID,
      from: generation
    )
    guard decision.schemaVersion == 1,
      decision.status == generation.decision.status.rawValue,
      decision.verificationArtifactID == generation.provenance.verifierArtifactID,
      decision.selectedClaimIDs.sorted() == generation.decision.selectedClaimIDs,
      decision.rejectedClaimIDs.sorted() == generation.decision.rejectedClaimIDs,
      decision.unresolvedDisagreementIDs.sorted()
        == generation.decision.unresolvedDisagreementIDs,
      !decision.voteCountUsed
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Содержимое артефакта решения противоречит структурированному решению поколения."
      )
    }

    let terminalArtifactID = try singleArtifactID(kind: "terminal", in: generation)
    let terminal: LiveRunTerminalArtifact = try decodeArtifact(
      terminalArtifactID,
      from: generation
    )
    guard terminal.schemaVersion == 1,
      terminal.outcome == generation.terminal.outcome.rawValue,
      terminal.reasonCode == generation.terminal.reasonCode,
      terminal.unresolvedDisagreementIDs.sorted()
        == generation.decision.unresolvedDisagreementIDs,
      terminal.handoffNextCardID == generation.handoff.nextCardID
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Содержимое терминального артефакта противоречит исходу или передаче поколения."
      )
    }

    let passportArtifactID = try singleArtifactID(kind: "episode_passport", in: generation)
    let passport: LiveRunEpisodePassportArtifact = try decodeArtifact(
      passportArtifactID,
      from: generation
    )
    guard passport.schemaVersion == 1,
      passport.question == generation.question,
      passport.rootCodexThreadID == generation.provenance.rootCodexThreadID
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Паспорт эпизода противоречит вопросу или происхождению поколения."
      )
    }

    let sourcesByPath = Dictionary(
      uniqueKeysWithValues: request.artifacts.map { ($0.sourcePath, $0) }
    )
    let actorPackageReferences =
      Array(contributionPackages.values) + [verification.package]
    for packageReference in actorPackageReferences {
      guard
        let packageArtifactID = packageArtifactIDByPackageID[
          packageReference.packageID
        ],
        let source = sourcesByPath[packageReference.path],
        source.artifactID == packageArtifactID,
        source.contentSHA256 == packageReference.preflightContractSHA256,
        preflightArtifactIDByPackageID[packageReference.packageID] != nil,
        let package = workPackagesByPackageID[packageReference.packageID]
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Вклад или проверка не связаны с точным рабочим пакетом и его preflight."
        )
      }
      let expectedInputs: Set<LiveRunInputIdentity>
      if packageReference.packageID == verification.package.packageID {
        expectedInputs = Set(verification.inputs.map(\.identity))
      } else {
        guard
          let contributionArtifactID = contributionPackages.first(where: {
            $0.value.packageID == packageReference.packageID
          })?.key,
          let inputs = contributionInputs[
            contributionArtifactID
          ]
        else {
          throw LiveDistributedRunArchiveError.corruptGeneration(
            "Рабочий пакет не связан с вкладом или отдельной проверкой."
          )
        }
        expectedInputs = Set(inputs)
      }
      guard Set(package.inputs.map(\.identity)) == expectedInputs else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Манифест входов вклада или проверки не совпадает с рабочим пакетом."
        )
      }
    }
    let actorPackageIDs = actorPackageReferences.map(\.packageID)
    guard Set(actorPackageIDs).count == 3 else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Производители и проверяющий должны использовать разные рабочие пакеты."
      )
    }

    let nextPackageArtifact = try generation.artifact(
      named: generation.handoff.nextWorkPackageArtifactID
    )
    let nextPackage: LiveRunWorkPackageArtifact = try decodeArtifact(
      nextPackageArtifact.artifactID,
      from: generation
    )
    var nextInputArtifactIDs: [String] = []
    for input in nextPackage.inputs {
      guard let source = sourcesByPath[input.path],
        source.contentSHA256 == input.sha256
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Обязательный вход пакета следующего шага отсутствует или имеет другой SHA-256."
        )
      }
      nextInputArtifactIDs.append(source.artifactID)
    }
    let requiredNextInputArtifactIDs = Set(
      generation.provenance.producerArtifactIDs
        + [
          passportArtifactID,
          provenanceArtifactID(in: generation),
          generation.provenance.verifierArtifactID,
          decisionArtifactID,
          terminalArtifactID,
        ]
    )
    let currentPointerPaths = nextPackage.handoff.requiredArtifacts.filter {
      $0 == currentPointerRelativePath || $0.hasSuffix(currentPointerPathSuffix)
    }
    let resultPaths = nextPackage.handoff.requiredArtifacts.filter {
      !currentPointerPaths.contains($0)
    }
    guard
      let nextPreflightArtifactID = preflightArtifactIDByPackageID[
        nextPackage.packageID
      ],
      Set(generation.handoff.requiredArtifactIDs)
        == Set(
          nextInputArtifactIDs
            + [nextPackageArtifact.artifactID, nextPreflightArtifactID]
        ),
      Set(nextInputArtifactIDs) == requiredNextInputArtifactIDs,
      currentPointerPaths.count == 1,
      resultPaths.count == 1,
      Set(actorPackageIDs + [nextPackage.packageID])
        == Set(workPackagesByPackageID.keys)
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Пакет следующего шага, его preflight или обязательные встроенные входы не замкнуты передачей."
      )
    }

    let provenanceArtifactID = try singleArtifactID(kind: "provenance", in: generation)
    let provenance: LiveRunProvenanceArtifact = try decodeArtifact(
      provenanceArtifactID,
      from: generation
    )
    let provenanceContributionIDs = provenance.contributions.map(\.artifactID)
    guard provenance.schemaVersion == 1,
      provenance.rootCodexThreadID == generation.provenance.rootCodexThreadID,
      provenanceContributionIDs.sorted()
        == generation.provenance.producerArtifactIDs,
      Set(provenanceContributionIDs).count == provenanceContributionIDs.count,
      provenance.notSharedMemory.count >= 3,
      Set(provenance.notSharedMemory).count == provenance.notSharedMemory.count,
      provenance.notSharedMemory.allSatisfy(isNonempty),
      provenance.observedSeparation.distinctRoles,
      provenance.observedSeparation.distinctPackageIDs,
      provenance.observedSeparation.nonOverlappingPrimaryInputs,
      provenance.observedSeparation.resultsWithheldUntilBothPublished,
      !provenance.observedSeparation.semanticIndependenceProven,
      Set(contributionExecutorIDs.values).count == 2,
      Set(contributionRoles.values).count == 2,
      Set(contributionPackages.values.map(\.packageID)).count == 2
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Артефакт происхождения не подтверждает точные разделённые роли и границу независимости."
      )
    }
    let producerInputPathSets = generation.provenance.producerArtifactIDs.compactMap {
      contributionInputs[$0].map { Set($0.map(\.path)) }
    }
    guard producerInputPathSets.count == 2,
      producerInputPathSets[0].isDisjoint(with: producerInputPathSets[1])
    else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Первичные входы двух вкладов не подтверждают заявленное разделение."
      )
    }
    for contribution in provenance.contributions {
      guard
        contribution.publicExecutorID
          == contributionExecutorIDs[contribution.artifactID],
        contribution.role == contributionRoles[contribution.artifactID],
        contribution.packageID
          == contributionPackages[contribution.artifactID]?.packageID,
        contribution.inputManifestSHA256s.sorted()
          == contributionInputs[contribution.artifactID]?.map(\.sha256).sorted(),
        !contribution.inputManifestSHA256s.isEmpty,
        contribution.inputManifestSHA256s.allSatisfy(isSHA256),
        !contribution.sawOtherContributionBeforePublication
      else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Запись происхождения вклада противоречит самому вкладу или пакету."
        )
      }
    }
    let embeddedCorrelationGroups = provenance.correlationGroups.map { group in
      LiveRunProvenanceArtifact.CorrelationGroup(
        groupID: group.groupID,
        kind: group.kind,
        basis: group.basis,
        memberArtifactIDs: group.memberArtifactIDs.sorted()
      )
    }.sorted { $0.groupID < $1.groupID }
    let projectedCorrelationGroups = generation.correlationGroups.map { group in
      LiveRunProvenanceArtifact.CorrelationGroup(
        groupID: group.groupID,
        kind: group.kind,
        basis: group.basis,
        memberArtifactIDs: group.memberArtifactIDs
      )
    }.sorted { $0.groupID < $1.groupID }
    guard embeddedCorrelationGroups == projectedCorrelationGroups else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Сохранённое происхождение противоречит структурированным группам корреляции."
      )
    }

    if generation.decision.status == .accepted {
      guard verification.overallOutcome == "passed" else {
        throw LiveDistributedRunArchiveError.corruptGeneration(
          "Принятое решение требует положительного общего исхода отдельной проверки."
        )
      }
    }
  }

  private static func decodeArtifact<T: Decodable>(
    _ artifactID: String,
    from generation: LiveDistributedRunGeneration
  ) throws -> T {
    let artifact = try generation.artifact(named: artifactID)
    let data = try decodedArtifactData(artifact)
    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Артефакт \(artifactID) не соответствует обязательной смысловой схеме."
      )
    }
  }

  private static let stringArrayShape = LiveRunJSONShape.array(.string)
  private static let inputShape = LiveRunJSONShape.object(
    required: ["path": .string, "sha256": .string],
    optional: [:]
  )
  private static let packageReferenceShape = LiveRunJSONShape.object(
    required: [
      "package_id": .string,
      "path": .string,
      "preflight_contract_sha256": .string,
    ],
    optional: [:]
  )
  private static let artifactShapes: [String: LiveRunJSONShape] = [
    "contribution": .object(
      required: [
        "claims": .array(
          .object(
            required: ["claim_id": .string],
            optional: [
              "line_end": .integer,
              "line_start": .integer,
              "source_path": .string,
              "statement": .string,
            ]
          )
        ),
        "contribution_id": .string,
        "inputs": .array(inputShape),
        "package": packageReferenceShape,
        "public_executor_id": .string,
        "question": .string,
        "role": .string,
        "root_codex_thread_id": .string,
        "schema_version": .integer,
      ],
      optional: [
        "limitations": stringArrayShape,
        "negative_results": stringArrayShape,
        "result_summary": .string,
      ]
    ),
    "decision": .object(
      required: [
        "rejected_claim_ids": stringArrayShape,
        "schema_version": .integer,
        "selected_claim_ids": stringArrayShape,
        "status": .string,
        "unresolved_disagreement_ids": stringArrayShape,
        "verification_artifact_id": .string,
        "vote_count_used": .boolean,
      ],
      optional: [
        "basis": .string,
        "considered_contribution_ids": stringArrayShape,
        "decision_id": .string,
        "evidence_summary": .object(
          required: [
            "autonomous_commands_passed": .integer,
            "claim_assessments_failed": .integer,
            "claim_assessments_inconclusive": .integer,
            "claim_assessments_passed": .integer,
          ],
          optional: [:]
        ),
        "negative_results": stringArrayShape,
        "result": .string,
      ]
    ),
    "episode_passport": .object(
      required: [
        "question": .string,
        "root_codex_thread_id": .string,
        "schema_version": .integer,
      ],
      optional: [
        "episode_id": .string,
        "goal": .string,
        "memory_contract": .object(
          required: [
            "canonical_replay_required": .boolean,
            "current_path": .string,
            "exact_parent_required_for_successor": .boolean,
            "generation_directory": .string,
            "profile": .string,
          ],
          optional: [:]
        ),
        "proof_boundary": .string,
        "provenance_boundary": .object(
          required: [
            "hidden_reasoning_persisted": .boolean,
            "orchestrator_messages_persisted": .boolean,
            "public_role_and_input_provenance_persisted": .boolean,
            "semantic_independence_proven": .boolean,
            "subagent_private_identifiers_persisted": .boolean,
          ],
          optional: [:]
        ),
        "roles": .array(
          .object(
            required: [
              "input_scope": .string,
              "public_executor_id": .string,
              "role": .string,
            ],
            optional: ["package_id": .string]
          )
        ),
        "selection_policy": .object(
          required: [
            "agreement_is_evidence": .boolean,
            "allowed_outcomes": stringArrayShape,
            "basis": .string,
            "independence_inferred_from_count": .boolean,
          ],
          optional: [:]
        ),
        "stop_condition": .object(
          required: [
            "terminal_outcomes": stringArrayShape,
            "terminal_when": .string,
          ],
          optional: [:]
        ),
      ]
    ),
    "handoff_result": .object(
      required: [
        "executed_package_id": .string,
        "input_checks": .array(
          .object(
            required: [
              "input_id": .string,
              "path": .string,
              "sha256": .string,
              "status": .string,
            ],
            optional: [:]
          )
        ),
        "outcome": .string,
        "previous_generation_sha256": .string,
        "previous_next_card_id": .string,
        "previous_work_package_artifact_id": .string,
        "previous_work_package_content_sha256": .string,
        "root_codex_thread_id": .string,
        "schema_version": .integer,
        "terminal_outcome": .string,
      ],
      optional: [:]
    ),
    "preflight": .object(
      required: [
        "contract_sha256": .string,
        "decision": .string,
        "observed_duration_seconds": .number,
        "package_id": .string,
        "schema_version": .integer,
        "violations": .array(
          .object(
            required: [:],
            optional: [
              "code": .string,
              "message": .string,
              "path": .string,
            ]
          )
        ),
      ],
      optional: [:]
    ),
    "provenance": .object(
      required: [
        "contributions": .array(
          .object(
            required: [
              "artifact_id": .string,
              "input_manifest_sha256s": stringArrayShape,
              "package_id": .string,
              "public_executor_id": .string,
              "role": .string,
              "saw_other_contribution_before_publication": .boolean,
            ],
            optional: [:]
          )
        ),
        "correlation_groups": .array(
          .object(
            required: [
              "basis": .string,
              "group_id": .string,
              "kind": .string,
              "member_artifact_ids": stringArrayShape,
            ],
            optional: [:]
          )
        ),
        "not_shared_memory": stringArrayShape,
        "observed_separation": .object(
          required: [
            "distinct_package_ids": .boolean,
            "distinct_roles": .boolean,
            "non_overlapping_primary_inputs": .boolean,
            "results_withheld_until_both_published": .boolean,
            "semantic_independence_proven": .boolean,
          ],
          optional: [:]
        ),
        "root_codex_thread_id": .string,
        "schema_version": .integer,
      ],
      optional: [:]
    ),
    "terminal": .object(
      required: [
        "handoff_next_card_id": .string,
        "outcome": .string,
        "reason_code": .string,
        "schema_version": .integer,
        "unresolved_disagreement_ids": stringArrayShape,
      ],
      optional: [
        "decision_id": .string,
        "proof_boundary": .string,
        "terminal_id": .string,
        "verification_id": .string,
      ]
    ),
    "verification": .object(
      required: [
        "claim_assessments": .array(
          .object(
            required: ["claim_id": .string, "status": .string],
            optional: [
              "contribution_id": .string,
              "evidence": .array(
                .object(
                  required: ["kind": .string],
                  optional: [
                    "command": .string,
                    "line_end": .integer,
                    "line_start": .integer,
                    "path": .string,
                  ]
                )
              ),
              "note": .string,
            ]
          )
        ),
        "inputs": .array(inputShape),
        "overall_outcome": .string,
        "package": packageReferenceShape,
        "public_executor_id": .string,
        "role": .string,
        "root_codex_thread_id": .string,
        "schema_version": .integer,
        "verification_id": .string,
      ],
      optional: [
        "command_evidence": .array(
          .object(
            required: [
              "command": .string,
              "duration_seconds": .number,
              "exit_code": .integer,
              "observed_facts": stringArrayShape,
              "result": .string,
            ],
            optional: [:]
          )
        ),
        "disagreements": .array(
          .object(
            required: ["disagreement_id": .string],
            optional: [
              "claim_id": .string,
              "description": .string,
              "status": .string,
            ]
          )
        ),
        "limitations": stringArrayShape,
        "negative_results": stringArrayShape,
        "result_summary": .string,
      ]
    ),
    "work_package": .object(
      required: [
        "budget": .object(
          required: [
            "limit": .integer,
            "reading": .integer,
            "reserve": .integer,
            "response": .integer,
            "unit": .string,
            "verification": .integer,
            "work": .integer,
          ],
          optional: [:]
        ),
        "change_scope": .object(
          required: [
            "allowed_paths": stringArrayShape,
            "excluded_paths": stringArrayShape,
            "policy": .string,
          ],
          optional: [:]
        ),
        "checks": .array(
          .object(
            required: ["description": .string, "id": .string],
            optional: [:]
          )
        ),
        "deliverables": .array(
          .object(
            required: [
              "depends_on": stringArrayShape,
              "description": .string,
              "id": .string,
              "role": .string,
            ],
            optional: [:]
          )
        ),
        "dependencies": .array(
          .object(
            required: [
              "evidence": .string,
              "id": .string,
              "status": .string,
            ],
            optional: [:]
          )
        ),
        "goal": .string,
        "handoff": .object(
          required: [
            "format": .string,
            "required_artifacts": stringArrayShape,
          ],
          optional: [:]
        ),
        "inputs": .array(
          .object(
            required: [
              "id": .string,
              "path": .string,
              "required": .boolean,
              "sha256": .string,
            ],
            optional: [:]
          )
        ),
        "package_id": .string,
        "preflight": .object(
          required: [
            "before_model_call": .boolean,
            "before_user_data_mutation": .boolean,
          ],
          optional: [:]
        ),
        "schema_version": .integer,
      ],
      optional: [:]
    ),
  ]

  private static func decodedArtifactData(
    _ artifact: SharedEpisodeEmbeddedArtifact
  ) throws -> Data {
    do {
      return try artifact.decodedData()
    } catch {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Встроенный артефакт \(artifact.artifactID) повреждён."
      )
    }
  }

  private static func singleArtifactID(
    kind: String,
    in generation: LiveDistributedRunGeneration
  ) throws -> String {
    let identifiers = generation.artifacts.filter { $0.kind == kind }.map(\.artifactID)
    guard identifiers.count == 1, let identifier = identifiers.first else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "Поколение должно содержать ровно один артефакт вида \(kind)."
      )
    }
    return identifier
  }

  private static func provenanceArtifactID(
    in generation: LiveDistributedRunGeneration
  ) -> String {
    generation.artifacts.first(where: { $0.kind == "provenance" })?.artifactID ?? ""
  }

  private static func validateFreshWorkPackages(
    request: LiveDistributedRunArchiveRequest,
    embedded: [SharedEpisodeEmbeddedArtifact],
    repositoryRoot: URL
  ) throws {
    let embeddedByID = Dictionary(
      uniqueKeysWithValues: embedded.map { ($0.artifactID, $0) }
    )
    for source in request.artifacts
    where source.artifactID == request.handoff.nextWorkPackageArtifactID {
      guard let artifact = embeddedByID[source.artifactID] else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Рабочий пакет отсутствует во встраиваемом снимке."
        )
      }
      let data = try decodedArtifactData(artifact)
      let report = WorkPackagePreflight.analyze(data, workspaceRoot: repositoryRoot)
      guard report.decision == .ready,
        report.violations.isEmpty,
        report.contractSHA256 == source.contentSHA256
      else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Свежий предпусковой анализ рабочего пакета не подтвердил ready."
        )
      }
    }
  }

  private static func validateArtifactSources(
    _ artifacts: [LiveDistributedRunArtifactSource]
  ) throws {
    guard !artifacts.isEmpty else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Манифест артефактов пуст."
      )
    }
    let ids = artifacts.map(\.artifactID)
    let logicalPaths = artifacts.map(\.logicalPath)
    let sourcePaths = artifacts.map(\.sourcePath)
    guard Set(ids).count == ids.count,
      Set(logicalPaths).count == logicalPaths.count,
      Set(sourcePaths).count == sourcePaths.count
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Идентификаторы или пути артефактов повторяются."
      )
    }
    for artifact in artifacts {
      guard artifact.schemaVersion == 1,
        isIdentifier(artifact.artifactID),
        isNonempty(artifact.kind),
        isNonempty(artifact.mediaType),
        isSafeRelativePath(artifact.logicalPath),
        isSafeRelativePath(artifact.sourcePath),
        isSHA256(artifact.contentSHA256)
      else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Артефакт \(artifact.artifactID) имеет недопустимую схему, путь или SHA-256."
        )
      }
    }
  }

  private static func validateReferences(
    _ request: LiveDistributedRunArchiveRequest,
    kinds: [String: String],
    contributionIDs: [String]
  ) throws {
    let artifactIDs = Set(kinds.keys)
    let allReferences =
      request.decision.basisArtifactIDs
      + request.terminal.evidenceArtifactIDs
      + request.handoff.requiredArtifactIDs
      + [request.handoff.nextWorkPackageArtifactID]
      + request.correlationGroups.flatMap(\.memberArtifactIDs)
    guard allReferences.allSatisfy(artifactIDs.contains),
      kinds[request.handoff.nextWorkPackageArtifactID] == "work_package",
      request.handoff.requiredArtifactIDs.contains(request.handoff.nextWorkPackageArtifactID),
      isNonempty(request.handoff.nextCardID),
      isNonempty(request.terminal.reasonCode),
      !request.decision.basisArtifactIDs.isEmpty
    else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Решение, терминальный исход или передача содержат незамкнутую ссылку."
      )
    }
    let groupIDs = request.correlationGroups.map(\.groupID)
    guard !groupIDs.isEmpty, Set(groupIDs).count == groupIDs.count else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Группы корреляции отсутствуют или повторяются."
      )
    }
    let groupedContributions = Set(
      request.correlationGroups.flatMap(\.memberArtifactIDs)
        .filter { contributionIDs.contains($0) }
    )
    guard groupedContributions == Set(contributionIDs) else {
      throw LiveDistributedRunArchiveError.invalidRequest(
        "Каждый вклад должен входить хотя бы в одну наблюдаемую группу корреляции."
      )
    }
    for group in request.correlationGroups {
      guard group.schemaVersion == 1,
        isIdentifier(group.groupID),
        isNonempty(group.kind),
        isNonempty(group.basis),
        group.memberArtifactIDs.count >= 2,
        Set(group.memberArtifactIDs).count == group.memberArtifactIDs.count
      else {
        throw LiveDistributedRunArchiveError.invalidRequest(
          "Группа корреляции \(group.groupID) неполна или противоречива."
        )
      }
    }
  }

  private static func readArtifact(
    _ source: LiveDistributedRunArtifactSource,
    repositoryRoot: URL
  ) throws -> Data {
    try readRegularFile(
      relativePath: source.sourcePath,
      rootURL: repositoryRoot,
      maximumBytes: maximumArtifactBytes,
      artifactID: source.artifactID
    )
  }

  private static func readRegularFile(
    relativePath: String,
    rootURL: URL,
    maximumBytes: Int,
    artifactID: String
  ) throws -> Data {
    guard isSafeRelativePath(relativePath) else {
      throw LiveDistributedRunArchiveError.unsafeSourcePath(relativePath)
    }
    let root = rootURL.standardizedFileURL.resolvingSymlinksInPath()
    let rootDescriptor = root.path.withCString { path in
      Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard rootDescriptor >= 0 else {
      throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
    }
    defer { _ = Darwin.close(rootDescriptor) }

    let components = relativePath.split(separator: "/").map(String.init)
    guard let fileName = components.last else {
      throw LiveDistributedRunArchiveError.unsafeSourcePath(relativePath)
    }
    var currentDescriptor = rootDescriptor
    var ownsCurrentDescriptor = false
    defer {
      if ownsCurrentDescriptor { _ = Darwin.close(currentDescriptor) }
    }
    for component in components.dropLast() {
      let nextDescriptor = component.withCString { name in
        Darwin.openat(
          currentDescriptor,
          name,
          O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
      }
      guard nextDescriptor >= 0 else {
        throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
      }
      if ownsCurrentDescriptor { _ = Darwin.close(currentDescriptor) }
      currentDescriptor = nextDescriptor
      ownsCurrentDescriptor = true
    }

    let inputDescriptor = fileName.withCString { name in
      Darwin.openat(
        currentDescriptor,
        name,
        O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK
      )
    }
    guard inputDescriptor >= 0 else {
      throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
    }
    defer { _ = Darwin.close(inputDescriptor) }

    var initialMetadata = stat()
    guard Darwin.fstat(inputDescriptor, &initialMetadata) == 0,
      initialMetadata.st_mode & S_IFMT == S_IFREG,
      initialMetadata.st_size >= 0,
      initialMetadata.st_size <= maximumBytes
    else {
      throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
    }
    let declaredSize = Int(initialMetadata.st_size)
    var data = Data()
    data.reserveCapacity(declaredSize)
    var bytesRead = 0
    var buffer = [UInt8](repeating: 0, count: 64 * 1_024)
    while bytesRead < declaredSize {
      let requestedBytes = min(buffer.count, declaredSize - bytesRead)
      let count = buffer.withUnsafeMutableBytes { storage in
        Darwin.read(inputDescriptor, storage.baseAddress, requestedBytes)
      }
      if count < 0 {
        if errno == EINTR { continue }
        throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
      }
      guard count > 0 else { break }
      bytesRead += count
      data.append(contentsOf: buffer.prefix(count))
    }

    var finalMetadata = stat()
    guard Darwin.fstat(inputDescriptor, &finalMetadata) == 0,
      finalMetadata.st_dev == initialMetadata.st_dev,
      finalMetadata.st_ino == initialMetadata.st_ino,
      finalMetadata.st_size == initialMetadata.st_size,
      finalMetadata.st_size == bytesRead,
      finalMetadata.st_mtimespec.tv_sec == initialMetadata.st_mtimespec.tv_sec,
      finalMetadata.st_mtimespec.tv_nsec == initialMetadata.st_mtimespec.tv_nsec,
      finalMetadata.st_ctimespec.tv_sec == initialMetadata.st_ctimespec.tv_sec,
      finalMetadata.st_ctimespec.tv_nsec == initialMetadata.st_ctimespec.tv_nsec
    else {
      throw LiveDistributedRunArchiveError.artifactReadFailed(artifactID)
    }
    return data
  }

  private static func normalized(
    _ decision: LiveDistributedRunDecision
  ) -> LiveDistributedRunDecision {
    LiveDistributedRunDecision(
      schemaVersion: decision.schemaVersion,
      status: decision.status,
      basisArtifactIDs: decision.basisArtifactIDs.sorted(),
      selectedClaimIDs: decision.selectedClaimIDs.sorted(),
      rejectedClaimIDs: decision.rejectedClaimIDs.sorted(),
      unresolvedDisagreementIDs: decision.unresolvedDisagreementIDs.sorted()
    )
  }

  fileprivate static func validateSuccessor(
    _ candidate: LiveDistributedRunGeneration,
    previous: LiveDistributedRunGeneration,
    previousGenerationSHA256: String
  ) throws {
    guard
      candidate.provenance.rootCodexThreadID
        != previous.provenance.rootCodexThreadID
    else {
      throw LiveDistributedRunArchiveError.incompatibleGeneration(
        "Поколение-преемник должно происходить из новой корневой сессии."
      )
    }

    let previousPackageArtifact = try previous.artifact(
      named: previous.handoff.nextWorkPackageArtifactID
    )
    let previousPackage: LiveRunWorkPackageArtifact = try decodeArtifact(
      previousPackageArtifact.artifactID,
      from: previous
    )
    let previousResultPaths = previousPackage.handoff.requiredArtifacts.filter {
      $0 != currentPointerRelativePath && !$0.hasSuffix(currentPointerPathSuffix)
    }
    guard previousResultPaths.count == 1,
      let candidateRequestData = Data(base64Encoded: candidate.requestBase64)
    else {
      throw LiveDistributedRunArchiveError.incompatibleGeneration(
        "Предыдущая передача не закрепляет единственный результат для новой сессии."
      )
    }
    let candidateRequest = try LiveDistributedRunArchiveRequest.decodeCanonical(
      candidateRequestData
    )
    let resultArtifactID = try singleArtifactID(
      kind: "handoff_result",
      in: candidate
    )
    guard
      let resultSource = candidateRequest.artifacts.first(where: {
        $0.artifactID == resultArtifactID
      }),
      resultSource.sourcePath == previousResultPaths[0],
      candidate.terminal.evidenceArtifactIDs.contains(resultArtifactID)
    else {
      throw LiveDistributedRunArchiveError.incompatibleGeneration(
        "Преемник не встраивает терминальное свидетельство по точному пути прежней передачи."
      )
    }
    let result: LiveRunHandoffResultArtifact = try decodeArtifact(
      resultArtifactID,
      from: candidate
    )
    let expectedInputChecks = Set(previousPackage.inputs.map(\.handoffIdentity))
    let observedInputChecks = Set(result.inputChecks.map(\.identity))
    guard result.schemaVersion == 1,
      result.previousGenerationSHA256 == previousGenerationSHA256,
      result.previousNextCardID == previous.handoff.nextCardID,
      result.previousWorkPackageArtifactID
        == previous.handoff.nextWorkPackageArtifactID,
      result.previousWorkPackageContentSHA256
        == previousPackageArtifact.contentSHA256,
      result.executedPackageID == previousPackage.packageID,
      result.rootCodexThreadID == candidate.provenance.rootCodexThreadID,
      result.inputChecks.count == previousPackage.inputs.count,
      observedInputChecks.count == result.inputChecks.count,
      observedInputChecks == expectedInputChecks,
      result.inputChecks.allSatisfy({ $0.status == "passed" }),
      result.terminalOutcome == candidate.terminal.outcome.rawValue,
      result.outcome == "completed"
    else {
      throw LiveDistributedRunArchiveError.incompatibleGeneration(
        "Результат преемника не подтверждает исполнение точного пакета прежней передачи."
      )
    }
  }

  private static func normalized(
    _ terminal: LiveDistributedRunTerminal
  ) -> LiveDistributedRunTerminal {
    LiveDistributedRunTerminal(
      schemaVersion: terminal.schemaVersion,
      outcome: terminal.outcome,
      reasonCode: terminal.reasonCode,
      evidenceArtifactIDs: terminal.evidenceArtifactIDs.sorted()
    )
  }

  private static func normalized(
    _ handoff: LiveDistributedRunHandoff
  ) -> LiveDistributedRunHandoff {
    LiveDistributedRunHandoff(
      schemaVersion: handoff.schemaVersion,
      nextCardID: handoff.nextCardID,
      nextWorkPackageArtifactID: handoff.nextWorkPackageArtifactID,
      requiredArtifactIDs: handoff.requiredArtifactIDs.sorted()
    )
  }

  private static func normalized(
    _ provenance: LiveDistributedRunProvenance
  ) -> LiveDistributedRunProvenance {
    LiveDistributedRunProvenance(
      schemaVersion: provenance.schemaVersion,
      rootCodexThreadID: provenance.rootCodexThreadID,
      orchestrationSurface: provenance.orchestrationSurface,
      modelIdentityObservation: provenance.modelIdentityObservation,
      producerArtifactIDs: provenance.producerArtifactIDs.sorted(),
      verifierArtifactID: provenance.verifierArtifactID,
      hiddenReasoningPersisted: provenance.hiddenReasoningPersisted,
      orchestratorMessagesPersisted: provenance.orchestratorMessagesPersisted
    )
  }

  private static func references(in generation: LiveDistributedRunGeneration) -> [String] {
    generation.decision.basisArtifactIDs
      + generation.terminal.evidenceArtifactIDs
      + generation.handoff.requiredArtifactIDs
      + [generation.handoff.nextWorkPackageArtifactID]
      + generation.correlationGroups.flatMap(\.memberArtifactIDs)
  }
}

public struct LiveDistributedRunArchiveStore {
  private static let maximumGenerationBytes = 16_777_216

  public let rootURL: URL
  private let contentStore: ContentAddressedGenerationStore

  public init(rootURL: URL) {
    self.rootURL = rootURL
    contentStore = ContentAddressedGenerationStore(
      rootURL: rootURL,
      canonicalProfile: CanonicalMemoryJSON.profileID,
      maximumGenerationBytes: Self.maximumGenerationBytes,
      validateGeneration: { data in
        _ = try LiveDistributedRunGeneration.decodeCanonical(data)
      },
      validateLineage: Self.validateLineage,
      previousGenerationSHA256: { data in
        try LiveDistributedRunGeneration.decodeCanonical(data)
          .previousGenerationSHA256
      }
    )
  }

  public func loadCurrent() throws -> StoredLiveDistributedRunGeneration? {
    let stored = try translateStoreErrors { try contentStore.loadCurrent() }
    guard let stored else { return nil }
    return StoredLiveDistributedRunGeneration(
      generationSHA256: stored.generationSHA256,
      generation: try LiveDistributedRunGeneration.decodeCanonical(stored.canonicalData)
    )
  }

  func commit(
    _ generation: LiveDistributedRunGeneration
  ) throws -> StoredLiveDistributedRunGeneration {
    try LiveDistributedRunArchive.validate(generation)
    let stored = try translateStoreErrors {
      try contentStore.commit(
        generation.canonicalJSONData(),
        expectedPreviousGenerationSHA256: generation.previousGenerationSHA256
      )
    }
    return StoredLiveDistributedRunGeneration(
      generationSHA256: stored.generationSHA256,
      generation: try LiveDistributedRunGeneration.decodeCanonical(stored.canonicalData)
    )
  }

  private static func validateLineage(
    candidateData: Data,
    current: StoredContentAddressedGeneration?
  ) throws {
    let candidate = try LiveDistributedRunGeneration.decodeCanonical(candidateData)
    guard let current else {
      guard candidate.previousGenerationSHA256 == nil else {
        throw LiveDistributedRunArchiveError.incompatibleGeneration(
          "Первое поколение живого прогона не может ссылаться на родителя."
        )
      }
      return
    }
    let previous = try LiveDistributedRunGeneration.decodeCanonical(
      current.canonicalData
    )
    guard candidate.previousGenerationSHA256 == current.generationSHA256 else {
      throw LiveDistributedRunArchiveError.generationConflict(
        expected: candidate.previousGenerationSHA256,
        actual: current.generationSHA256
      )
    }
    guard candidate.runID != previous.runID else {
      throw LiveDistributedRunArchiveError.incompatibleGeneration(
        "Поколение-преемник должно иметь новый run_id."
      )
    }
    try LiveDistributedRunArchive.validateSuccessor(
      candidate,
      previous: previous,
      previousGenerationSHA256: current.generationSHA256
    )
  }

  private func translateStoreErrors<T>(_ body: () throws -> T) throws -> T {
    do {
      return try body()
    } catch let error as LiveDistributedRunArchiveError {
      throw error
    } catch let error as ContentAddressedGenerationStoreError {
      switch error {
      case .incompatibleGeneration(let message):
        throw LiveDistributedRunArchiveError.incompatibleGeneration(message)
      case .corruptGeneration(let message):
        throw LiveDistributedRunArchiveError.corruptGeneration(message)
      case .generationConflict(let expected, let actual):
        throw LiveDistributedRunArchiveError.generationConflict(
          expected: expected,
          actual: actual
        )
      case .generationStore(let message):
        throw LiveDistributedRunArchiveError.generationStore(message)
      }
    }
  }
}

private func decodeLiveCanonical<T: SharedEpisodeCanonicalValue>(
  _ type: T.Type,
  data: Data,
  kind: String
) throws -> T {
  do {
    try CanonicalMemoryJSON.requireCanonical(data)
    let value = try JSONDecoder().decode(T.self, from: data)
    guard try value.canonicalJSONData() == data else {
      throw LiveDistributedRunArchiveError.corruptGeneration(
        "\(kind) содержит неизвестные поля или неканонические значения."
      )
    }
    return value
  } catch let error as LiveDistributedRunArchiveError {
    throw error
  } catch {
    throw LiveDistributedRunArchiveError.corruptGeneration(
      "\(kind) не соответствует каноническому JSON или точной схеме."
    )
  }
}

private func isSHA256(_ value: String) -> Bool {
  guard value.hasPrefix("sha256:") else { return false }
  let digest = value.dropFirst(7).utf8
  return digest.count == 64
    && digest.allSatisfy { byte in
      (48...57).contains(byte) || (97...102).contains(byte)
    }
}

private func isIdentifier(_ value: String) -> Bool {
  guard isNonempty(value), value.count <= 160 else { return false }
  return value.allSatisfy { character in
    character.isLetter || character.isNumber || ".-_".contains(character)
  }
}

private func isNonempty(_ value: String) -> Bool {
  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

private func isSafeRelativePath(_ value: String) -> Bool {
  guard isNonempty(value), !value.hasPrefix("/"), !value.contains("\\"),
    value.utf8.first != 0x7E, !value.contains(":"),
    value.unicodeScalars.allSatisfy({
      !CharacterSet.controlCharacters.contains($0)
    })
  else { return false }
  let components = value.split(separator: "/", omittingEmptySubsequences: false)
  return !components.isEmpty
    && components.allSatisfy { component in
      !component.isEmpty && component != "." && component != ".."
    }
}
