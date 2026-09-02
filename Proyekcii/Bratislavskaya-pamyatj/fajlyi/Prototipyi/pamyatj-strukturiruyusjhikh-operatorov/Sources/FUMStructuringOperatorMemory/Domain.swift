import CryptoKit
import Foundation

public enum OperatorMemoryError: Error, Equatable, Sendable {
  case missingResource(String)
  case resourceTooLarge(Int)
  case unsupportedSchema(Int)
  case invalidConfiguration(String)
  case invalidFixture(String)
  case scenarioNotFound(String)
  case invalidRecordedEnvelope(String)
  case automationFailed(String)
}

public enum ScenarioKind: String, Codable, Equatable, Sendable {
  case stream
  case error
  case exactRoundtrip = "exact_roundtrip"
  case semanticCompression = "semantic_compression"
  case languageForms = "language_forms"
  case crossLanguageGraph = "cross_language_graph"
  case explainability
  case automation
  case synchronization
}

public enum RecoveryMode: String, Codable, Equatable, Sendable {
  case exact
  case semantic
}

public enum StreamEventKind: String, Codable, Equatable, Sendable {
  case request
  case edit
  case log
  case session
}

public enum OperatorStratum: String, Codable, CaseIterable, Equatable, Sendable {
  case raw
  case form
  case syntax
  case semantic
  case discourse
  case automation
  case action

  public var rank: Int {
    switch self {
    case .raw: 0
    case .form: 1
    case .syntax: 2
    case .semantic: 3
    case .discourse: 4
    case .automation: 5
    case .action: 6
    }
  }
}

public enum CandidateStatus: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
  case hypothesis
  case lowConfidence = "low_confidence"
  case confirmed
  case conflicting
  case rejected
  case obsolete
  case pendingExternalReview = "pending_external_review"

  public static let linkStatuses: [CandidateStatus] = [
    .confirmed,
    .rejected,
    .pendingExternalReview,
  ]
}

public enum OperatorOrigin: String, Codable, Equatable, Sendable {
  case seed
  case human
  case llm
  case automation
  case derived
}

public enum ResidualCategory: String, Codable, Equatable, Hashable, Sendable {
  case probableInputError = "probable_input_error"
  case unknownForm = "unknown_form"
  case ambiguity
  case translationLoss = "translation_loss"
  case unsupportedProjection = "unsupported_projection"
}

public enum GraphRelation: String, Codable, Equatable, Sendable {
  case recognizes
  case generates
  case composes
  case specializes
  case abstracts
  case translatesVia = "translates_via"
  case conflicts
  case verifies
  case projectsTo = "projects_to"
  case executesAs = "executes_as"
}

public enum AutomationStepKind: String, Codable, Equatable, Sendable {
  case trim
  case lowercase
  case collapseWhitespace = "collapse_whitespace"
  case replace
  case prefix
}

public enum NodeKind: String, Codable, Equatable, Sendable {
  case humanLike = "human_like"
  case llmBacked = "llm_backed"
  case internalSubnode = "internal_subnode"
}

public enum SpeechActType: String, Codable, Equatable, Sendable {
  case statement
  case question
  case clarification
  case correction
  case paraphrase
  case confirmation
  case divergence
  case jointAction = "joint_action"
}

public struct Provenance: Codable, Equatable, Sendable {
  public let initiator: String
  public let executor: String
  public let source: String
  public let ordinal: Int

  public init(initiator: String, executor: String, source: String, ordinal: Int) {
    self.initiator = initiator
    self.executor = executor
    self.source = source
    self.ordinal = ordinal
  }
}

public struct StreamEvent: Codable, Equatable, Sendable {
  public let id: String
  public let sequence: Int
  public let kind: StreamEventKind
  public let text: String
  public let nodeId: String
  public let provenance: Provenance

  public var bytes: [UInt8] { Array(text.utf8) }
  public var sha256: String { sha256Digest(Data(bytes)) }
}

public struct OperatorProfile: Codable, Equatable, Sendable {
  public let id: String
  public let version: Int
  public let stratum: OperatorStratum
  public let status: CandidateStatus
  public let recognitionPatterns: [String]
  public let generationTemplate: String?
  public let language: String?
  public let script: String?
  public let semanticKey: String?
  public let storageCostBits: Int
  public let confidencePpm: Int
  public let origin: OperatorOrigin
  public let positiveExamples: [String]
  public let negativeExamples: [String]

  public init(
    id: String,
    version: Int,
    stratum: OperatorStratum,
    status: CandidateStatus,
    recognitionPatterns: [String],
    generationTemplate: String?,
    language: String?,
    script: String?,
    semanticKey: String?,
    storageCostBits: Int,
    confidencePpm: Int,
    origin: OperatorOrigin,
    positiveExamples: [String],
    negativeExamples: [String]
  ) {
    self.id = id
    self.version = version
    self.stratum = stratum
    self.status = status
    self.recognitionPatterns = recognitionPatterns
    self.generationTemplate = generationTemplate
    self.language = language
    self.script = script
    self.semanticKey = semanticKey
    self.storageCostBits = storageCostBits
    self.confidencePpm = confidencePpm
    self.origin = origin
    self.positiveExamples = positiveExamples
    self.negativeExamples = negativeExamples
  }
}

public struct EngineConfiguration: Codable, Equatable, Sendable {
  public let maxDepth: Int
  public let maxNodes: Int
  public let maxUnitBytes: Int
  public let maxCandidates: Int
  public let maxEvents: Int
  public let maxEventBytes: Int
  public let maxOperators: Int
  public let maxLatticeCandidatesPerOffset: Int
  public let minSupport: Int
  public let referenceCostBits: Int

  public func validate() throws {
    try validateBound(maxDepth, named: "max_depth", range: 1...32)
    try validateBound(maxNodes, named: "max_nodes", range: 1...4_096)
    try validateBound(maxUnitBytes, named: "max_unit_bytes", range: 1...64)
    try validateBound(maxCandidates, named: "max_candidates", range: 1...1_024)
    try validateBound(maxEvents, named: "max_events", range: 1...128)
    try validateBound(maxEventBytes, named: "max_event_bytes", range: 1...65_536)
    try validateBound(maxOperators, named: "max_operators", range: 1...256)
    try validateBound(
      maxLatticeCandidatesPerOffset,
      named: "max_lattice_candidates_per_offset",
      range: 1...128
    )
    try validateBound(minSupport, named: "min_support", range: 1...1_000)
    try validateBound(referenceCostBits, named: "reference_cost_bits", range: 1...1_024)
  }

  private func validateBound(
    _ value: Int,
    named name: String,
    range: ClosedRange<Int>
  ) throws {
    guard range.contains(value) else {
      throw OperatorMemoryError.invalidConfiguration("\(name)=\(value)")
    }
  }
}

public struct RecordedLLMEnvelope: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let adapterId: String
  public let model: String
  public let promptText: String
  public let promptHash: String
  public let responseHash: String
  public let proposals: [OperatorProfile]
}

public struct ResidualHint: Codable, Equatable, Sendable {
  public let eventId: String
  public let needle: String
  public let category: ResidualCategory
  public let explanation: String
}

public struct SemanticFact: Codable, Equatable, Hashable, Sendable {
  public let key: String
  public let value: String
  public let language: String?
  public let sourceEventId: String
}

public struct GraphEdgeFixture: Codable, Equatable, Sendable {
  public let id: String
  public let fromId: String
  public let toId: String
  public let relation: GraphRelation
  public let provenance: Provenance
}

public struct SemanticLinkFixture: Codable, Equatable, Sendable {
  public let id: String
  public let sourceEventId: String
  public let targetEventId: String
  public let operatorId: String
  public let status: CandidateStatus
  public let confidencePpm: Int
  public let counterexample: String?
}

public struct AutomationStep: Codable, Equatable, Sendable {
  public let id: String
  public let kind: AutomationStepKind
  public let argument: String?
}

public struct AutomationFixture: Codable, Equatable, Sendable {
  public let operatorId: String
  public let input: String
  public let expectedOutput: String
  public let effects: [String]
  public let steps: [AutomationStep]
}

public struct KnowledgeFact: Codable, Equatable, Hashable, Sendable {
  public let key: String
  public let value: String
  public let modality: String
  public let time: String
  public let source: String
  public let confidencePpm: Int
}

public struct KnowledgeNode: Codable, Equatable, Sendable {
  public let id: String
  public let kind: NodeKind
  public let initialFacts: [KnowledgeFact]
}

public struct RoleBinding: Codable, Equatable, Sendable {
  public let form: String
  public let nodeIds: [String]
  public let groupVersion: String?
  public let quotedSpeakerId: String?
  public let representsComposite: Bool
}

public struct SpeechAct: Codable, Equatable, Sendable {
  public let id: String
  public let sequence: Int
  public let type: SpeechActType
  public let speakerId: String
  public let recipientIds: [String]
  public let fact: KnowledgeFact?
  public let roleBindings: [RoleBinding]
  public let authorized: Bool
  public let quoteSourceId: String?
}

public struct SynchronizationFixture: Codable, Equatable, Sendable {
  public let nodes: [KnowledgeNode]
  public let acts: [SpeechAct]
  public let requiredFactKeys: [String]
  public let expectAction: Bool
}

public struct ScenarioExpectation: Codable, Equatable, Sendable {
  public let exactRoundTrip: Bool?
  public let positivePredictionGain: Bool?
  public let positiveCompressionGain: Bool?
  public let semanticQualityPpm: Int?
  public let residualCategories: [ResidualCategory]
  public let candidateStatuses: [String: CandidateStatus]
  public let graphPath: [String]
  public let minimumPrunedContexts: Int
  public let minimumPrunedCandidates: Int
  public let actionExecuted: Bool?
  public let llmBackedRequired: Bool
  public let sourceUnchanged: Bool
}

public struct ScenarioFixture: Codable, Equatable, Sendable {
  public let id: String
  public let kind: ScenarioKind
  public let description: String
  public let recoveryMode: RecoveryMode
  public let configuration: EngineConfiguration
  public let events: [StreamEvent]
  public let expectedSourceHashes: [String: String]
  public let seedOperatorIds: [String]
  public let recordedLlm: RecordedLLMEnvelope?
  public let residualHints: [ResidualHint]
  public let expectedSemanticFacts: [SemanticFact]
  public let graphEdges: [GraphEdgeFixture]
  public let semanticLinks: [SemanticLinkFixture]
  public let automation: AutomationFixture?
  public let synchronization: SynchronizationFixture?
  public let expectation: ScenarioExpectation
}

public struct ScenarioSuite: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let operatorCatalog: [OperatorProfile]
  public let scenarios: [ScenarioFixture]

  public func scenario(id: String) throws -> ScenarioFixture {
    guard let scenario = scenarios.first(where: { $0.id == id }) else {
      throw OperatorMemoryError.scenarioNotFound(id)
    }
    return scenario
  }

  public func operators(ids: [String]) throws -> [OperatorProfile] {
    let byID = Dictionary(uniqueKeysWithValues: operatorCatalog.map { ($0.id, $0) })
    return try ids.map { id in
      guard let profile = byID[id] else {
        throw OperatorMemoryError.invalidFixture("missing operator \(id)")
      }
      return profile
    }
  }
}

public struct SourceSpan: Codable, Equatable, Sendable {
  public let eventID: String
  public let byteOffset: Int
  public let byteLength: Int
}

public struct DiagnosticResidual: Codable, Equatable, Sendable {
  public let id: String
  public let span: SourceSpan
  public let surface: String
  public let category: ResidualCategory
  public let explanation: String
  public let partialOperatorIDs: [String]
  public let competingExplanations: [String]
}

public struct ConflictRecord: Codable, Equatable, Sendable {
  public let id: String
  public let operatorIDs: [String]
  public let pattern: String
  public let resolution: String
}

public struct StatusTransition: Codable, Equatable, Sendable {
  public let from: CandidateStatus
  public let to: CandidateStatus
  public let reason: String
}

public struct OperatorCandidateReport: Codable, Equatable, Sendable {
  public let operatorID: String
  public let origin: OperatorOrigin
  public let initialStatus: CandidateStatus
  public let finalStatus: CandidateStatus
  public let support: Int
  public let predictionGainMilliBits: Int
  public let compressionGainBits: Int
  public let roundTripQualityPPM: Int
  public let conflictIDs: [String]
  public let history: [StatusTransition]
}

public enum ReconstructionKind: String, Codable, Equatable, Sendable {
  case rawPreserved = "raw_preserved"
  case operatorGenerated = "operator_generated"
}

public struct UnitCandidateRecord: Codable, Equatable, Sendable {
  public let start: Int
  public let length: Int
  public let operatorID: String?
  public let origin: OperatorOrigin
  public let probabilityPPM: Int
  public let rawScore: Int
  public let bytesHex: String
  public let sourceBytesHex: String
  public let generatedBytesHex: String
  public let reconstructionKind: ReconstructionKind
}

public struct LatticeReport: Codable, Equatable, Sendable {
  public let eventID: String
  public let byteCount: Int
  public let candidates: [UnitCandidateRecord]
  public let selectedUnits: [UnitCandidateRecord]

  public var probabilitiesAreNormalized: Bool {
    let groups = Dictionary(grouping: candidates, by: \.start)
    return groups.count == byteCount
      && groups.values.allSatisfy { group in
        group.reduce(0) { $0 + $1.probabilityPPM } == 1_000_000
      }
  }
}

public struct NextProbability: Codable, Equatable, Sendable {
  public let byte: UInt8
  public let count: Int
  public let probabilityPPM: Int
}

public struct ContextNodeReport: Codable, Equatable, Sendable {
  public let contextHex: String
  public let depth: Int
  public let support: Int
  public let continuations: [NextProbability]
}

public struct ContextForestReport: Codable, Equatable, Sendable {
  public let processedBytes: Int
  public let nodeCount: Int
  public let maxDepth: Int
  public let maxNodes: Int
  public let nodes: [ContextNodeReport]
}

public struct PruningReport: Codable, Equatable, Sendable {
  public let prunedContextHex: [String]
  public let prunedCandidateIDs: [String]
}

public struct ScenarioMetrics: Codable, Equatable, Sendable {
  public let predictionGainMilliBits: Int
  public let compressionGainBits: Int
  public let roundTripQualityPPM: Int
  public let exactRoundTrip: Bool
  public let operatorGenerationExact: Bool
  public let rawPreservedByteCount: Int
  public let operatorGeneratedByteCount: Int
  public let rawBits: Int
  public let descriptionBits: Int
}

public struct GroundedSemanticFact: Codable, Equatable, Sendable {
  public let fact: SemanticFact
  public let span: SourceSpan
  public let operatorIDs: [String]
}

public struct OperatorEdgeRecord: Codable, Equatable, Sendable {
  public let id: String
  public let fromID: String
  public let toID: String
  public let relation: GraphRelation
  public let provenance: Provenance
}

public struct ExplanationRecord: Codable, Equatable, Sendable {
  public let id: String
  public let operatorID: String
  public let sourceEventID: String
  public let targetEventID: String
  public let status: CandidateStatus
  public let confidencePPM: Int
  public let humanView: String
  public let llmView: String
  public let counterexample: String?
}

public struct AutomationStepTrace: Codable, Equatable, Sendable {
  public let stepID: String
  public let kind: AutomationStepKind
  public let inputHash: String
  public let outputHash: String
}

public struct AutomationTrace: Codable, Equatable, Sendable {
  public let operatorID: String
  public let input: String
  public let output: String
  public let effects: [String]
  public let steps: [AutomationStepTrace]
  public let traceHash: String
  public let passed: Bool
}

public struct RecordedAdapterTrace: Codable, Equatable, Sendable {
  public let adapterID: String
  public let model: String
  public let promptHash: String
  public let responseHash: String
  public let externalExecution: Bool
}

public struct AppliedOperator: Codable, Equatable, Sendable {
  public let id: String
  public let version: Int
  public let origin: OperatorOrigin
  public let finalStatus: CandidateStatus
}

public struct NodeKnowledgeSnapshot: Codable, Equatable, Sendable {
  public let nodeID: String
  public let kind: NodeKind
  public let facts: [KnowledgeFact]
  public let factHistory: [KnowledgeFact]
}

public struct SynchronizationTrace: Codable, Equatable, Sendable {
  public let nodeSnapshots: [NodeKnowledgeSnapshot]
  public let actTypes: [SpeechActType]
  public let roleBindings: [RoleBinding]
  public let divergences: [String]
  public let actionExecuted: Bool
  public let containsLLMBackedNode: Bool
  public let simulationOnly: Bool
  public let externalEffects: [String]

  public var nodeKinds: [NodeKind] { nodeSnapshots.map(\.kind) }
}

public struct ScenarioReport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let scenarioID: String
  public let scenarioKind: ScenarioKind
  public let fixtureResourceHash: String
  public let configurationHash: String
  public let sourceHashes: [String: String]
  public let provenance: [Provenance]
  public let forest: ContextForestReport
  public let lattices: [LatticeReport]
  public let candidates: [OperatorCandidateReport]
  public let metrics: ScenarioMetrics
  public let residuals: [DiagnosticResidual]
  public let conflicts: [ConflictRecord]
  public let pruning: PruningReport
  public let graphEdges: [OperatorEdgeRecord]
  public let graphPath: [String]
  public let explanations: [ExplanationRecord]
  public let automationTrace: AutomationTrace?
  public let recordedAdapterTrace: RecordedAdapterTrace?
  public let appliedOperators: [AppliedOperator]
  public let synchronizationTrace: SynchronizationTrace?
  public let groundedSemanticFacts: [GroundedSemanticFact]
  public let semanticGeneration: String
  public let sourcesUnchanged: Bool
  public let passed: Bool
  public let violations: [String]

  public func candidate(id: String) -> OperatorCandidateReport? {
    candidates.first { $0.operatorID == id }
  }

  public func canonicalJSON() throws -> String {
    let data = try canonicalJSONData(self)
    guard let text = String(data: data, encoding: .utf8) else {
      throw OperatorMemoryError.invalidFixture("report is not UTF-8")
    }
    return text
  }
}

public func sha256Digest(_ data: Data) -> String {
  let digest = SHA256.hash(data: data)
  return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
}

public func canonicalJSONData<T: Encodable>(_ value: T) throws -> Data {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
  return try encoder.encode(value)
}

func hexString(_ bytes: some Sequence<UInt8>) -> String {
  bytes.map { String(format: "%02x", $0) }.joined()
}

func bytesFromHex(_ text: String) -> [UInt8]? {
  guard text.count.isMultiple(of: 2) else { return nil }
  var result: [UInt8] = []
  result.reserveCapacity(text.count / 2)
  var index = text.startIndex
  while index < text.endIndex {
    let next = text.index(index, offsetBy: 2)
    guard let byte = UInt8(text[index..<next], radix: 16) else { return nil }
    result.append(byte)
    index = next
  }
  return result
}
