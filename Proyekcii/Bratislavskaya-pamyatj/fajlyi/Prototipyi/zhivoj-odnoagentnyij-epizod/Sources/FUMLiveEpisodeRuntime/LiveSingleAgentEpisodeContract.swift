import CryptoKit
import FUMLiveEpisodeCore
import Foundation

public enum LiveSingleAgentEpisodeSchema {
  public static let executionPassportIdentity =
    "fum.live_single_agent_episode.execution_passport"
  public static let checkpointMarkerIdentity =
    "fum.live_single_agent_episode.checkpoint_marker"
  public static let externalConfirmationIdentity =
    "fum.live_single_agent_episode.external_confirmation"
  public static let workerOutputIdentity = "fum.live_single_agent_episode.worker_output"
  public static let reportIdentity = "fum.live_single_agent_episode.report"
  public static let projectionIdentity = "fum.live_single_agent_episode.projection"
  public static let version = 1
  public static let recordedProjectionSHA256 =
    "sha256:316f1189af9cd027fafbe87edba82a3799f67b691ea1dac54e1473ddfa42a9a1"

  public static let executionPassportFileName = "execution-passport.json"
  public static let episodeRelativePath = "episode"
  public static let sourceRelativePath = "source"
  public static let checkpointRelativePath = "checkpoints"
  public static let externalConfirmationFileName = "external-transition-confirmation.json"
}

public enum LiveSingleAgentTransportMode: String, Codable, Equatable, Sendable {
  case recorded
  case lmStudioLive = "lmstudio_live"
}

public enum LiveSingleAgentCheckpointID: String, Codable, CaseIterable, Sendable {
  case selectionGenerationConfirmed = "selection-generation-confirmed"
  case candidateObservationGenerationConfirmed =
    "candidate-observation-generation-confirmed"
}

public struct LiveSingleAgentModelPrompt: Codable, Equatable, Sendable {
  public let variantID: String
  public let input: String
  public let inputSHA256: String
  public let inputBytes: Int64
  public let inputTokens: Int64
  public let expectedOutput: String
  public let expectedOutputSHA256: String

  public init(
    variantID: String,
    input: String,
    inputSHA256: String,
    inputBytes: Int64,
    inputTokens: Int64,
    expectedOutput: String,
    expectedOutputSHA256: String
  ) {
    self.variantID = variantID
    self.input = input
    self.inputSHA256 = inputSHA256
    self.inputBytes = inputBytes
    self.inputTokens = inputTokens
    self.expectedOutput = expectedOutput
    self.expectedOutputSHA256 = expectedOutputSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case variantID = "variant_id"
    case input
    case inputSHA256 = "input_sha256"
    case inputBytes = "input_bytes"
    case inputTokens = "input_tokens"
    case expectedOutput = "expected_output"
    case expectedOutputSHA256 = "expected_output_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    variantID = try container.decode(String.self, forKey: .variantID)
    input = try container.decode(String.self, forKey: .input)
    inputSHA256 = try container.decode(String.self, forKey: .inputSHA256)
    inputBytes = try container.decode(Int64.self, forKey: .inputBytes)
    inputTokens = try container.decode(Int64.self, forKey: .inputTokens)
    expectedOutput = try container.decode(String.self, forKey: .expectedOutput)
    expectedOutputSHA256 = try container.decode(
      String.self,
      forKey: .expectedOutputSHA256
    )
  }
}

/// One immutable, versioned description of the deliberately narrow accepted episode.
/// The nested live passport owns goal, context, provider identity, budgets, disclosure,
/// action allowlist, verification criteria, checkpoint policy, and terminal outcomes.
public struct LiveSingleAgentExecutionPassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let transportMode: LiveSingleAgentTransportMode
  public let sourceCheckoutRelativePath: String
  public let episodeRelativePath: String
  public let episodePassport: LiveEpisodePassport
  public let candidatePlan: LiveGitCandidatePlan
  public let prompts: [LiveSingleAgentModelPrompt]
  public let checkpoints: [LiveSingleAgentCheckpointID]

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.executionPassportIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    transportMode: LiveSingleAgentTransportMode,
    sourceCheckoutRelativePath: String = LiveSingleAgentEpisodeSchema.sourceRelativePath,
    episodeRelativePath: String = LiveSingleAgentEpisodeSchema.episodeRelativePath,
    episodePassport: LiveEpisodePassport,
    candidatePlan: LiveGitCandidatePlan,
    prompts: [LiveSingleAgentModelPrompt],
    checkpoints: [LiveSingleAgentCheckpointID] = LiveSingleAgentCheckpointID.allCases
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.transportMode = transportMode
    self.sourceCheckoutRelativePath = sourceCheckoutRelativePath
    self.episodeRelativePath = episodeRelativePath
    self.episodePassport = episodePassport
    self.candidatePlan = candidatePlan
    self.prompts = prompts
    self.checkpoints = checkpoints
  }

  public func canonicalData() throws -> Data {
    try LiveEpisodeRuntimeJSON.encode(self)
  }

  public func canonicalSHA256() throws -> String {
    Self.sha256(try canonicalData())
  }

  public func validate() throws {
    guard
      self
        == (try LiveSingleAgentEpisodeRuntime.expectedExecutionPassport(
          mode: transportMode
        ))
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Execution-passport не совпадает с полным закреплённым контрактом сценария."
      )
    }
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case transportMode = "transport_mode"
    case sourceCheckoutRelativePath = "source_checkout_relative_path"
    case episodeRelativePath = "episode_relative_path"
    case episodePassport = "episode_passport"
    case candidatePlan = "candidate_plan"
    case prompts
    case checkpoints
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    transportMode = try container.decode(LiveSingleAgentTransportMode.self, forKey: .transportMode)
    sourceCheckoutRelativePath = try container.decode(
      String.self,
      forKey: .sourceCheckoutRelativePath
    )
    episodeRelativePath = try container.decode(String.self, forKey: .episodeRelativePath)
    episodePassport = try container.decode(LiveEpisodePassport.self, forKey: .episodePassport)
    candidatePlan = try container.decode(LiveGitCandidatePlan.self, forKey: .candidatePlan)
    prompts = try container.decode([LiveSingleAgentModelPrompt].self, forKey: .prompts)
    checkpoints = try container.decode(
      [LiveSingleAgentCheckpointID].self,
      forKey: .checkpoints
    )
  }

  public static func sha256(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

public struct LiveSingleAgentCheckpointMarker: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let checkpoint: LiveSingleAgentCheckpointID
  public let processID: Int32
  public let generationSHA256: String
  public let stateSHA256: String

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.checkpointMarkerIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    checkpoint: LiveSingleAgentCheckpointID,
    processID: Int32,
    generationSHA256: String,
    stateSHA256: String
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.checkpoint = checkpoint
    self.processID = processID
    self.generationSHA256 = generationSHA256
    self.stateSHA256 = stateSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case checkpoint
    case processID = "process_id"
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    checkpoint = try container.decode(LiveSingleAgentCheckpointID.self, forKey: .checkpoint)
    processID = try container.decode(Int32.self, forKey: .processID)
    generationSHA256 = try container.decode(String.self, forKey: .generationSHA256)
    stateSHA256 = try container.decode(String.self, forKey: .stateSHA256)
  }
}

/// A new, visible harness input written only after it has observed and killed the first
/// checkpoint worker. The resumed runtime binds it to the exact confirmed CURRENT.
public struct LiveSingleAgentExternalConfirmation: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let decision: String
  public let harnessProcessID: Int32
  public let observedCheckpoint: LiveSingleAgentCheckpointID
  public let observedWorkerProcessID: Int32
  public let generationSHA256: String
  public let stateSHA256: String
  public let executionPassportSHA256: String

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.externalConfirmationIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    decision: String = "confirm-isolated-candidate-transition",
    harnessProcessID: Int32,
    observedCheckpoint: LiveSingleAgentCheckpointID,
    observedWorkerProcessID: Int32,
    generationSHA256: String,
    stateSHA256: String,
    executionPassportSHA256: String
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.decision = decision
    self.harnessProcessID = harnessProcessID
    self.observedCheckpoint = observedCheckpoint
    self.observedWorkerProcessID = observedWorkerProcessID
    self.generationSHA256 = generationSHA256
    self.stateSHA256 = stateSHA256
    self.executionPassportSHA256 = executionPassportSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case decision
    case harnessProcessID = "harness_process_id"
    case observedCheckpoint = "observed_checkpoint"
    case observedWorkerProcessID = "observed_worker_process_id"
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
    case executionPassportSHA256 = "execution_passport_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    decision = try container.decode(String.self, forKey: .decision)
    harnessProcessID = try container.decode(Int32.self, forKey: .harnessProcessID)
    observedCheckpoint = try container.decode(
      LiveSingleAgentCheckpointID.self,
      forKey: .observedCheckpoint
    )
    observedWorkerProcessID = try container.decode(
      Int32.self,
      forKey: .observedWorkerProcessID
    )
    generationSHA256 = try container.decode(String.self, forKey: .generationSHA256)
    stateSHA256 = try container.decode(String.self, forKey: .stateSHA256)
    executionPassportSHA256 = try container.decode(
      String.self,
      forKey: .executionPassportSHA256
    )
  }
}

public enum LiveSingleAgentWorkerStatus: String, Codable, Equatable, Sendable {
  case checkpoint
  case completed
}

public struct LiveSingleAgentWorkerOutput: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let status: LiveSingleAgentWorkerStatus
  public let processID: Int32
  public let generationSHA256: String
  public let stateSHA256: String
  public let checkpoint: LiveSingleAgentCheckpointID?
  public let candidateOID: String?
  public let acceptanceProcessID: Int32?
  public let acceptanceVerdict: LiveGitCandidateAcceptanceVerdict?
  public let acceptanceReceiptSHA256: String?
  public let terminalOutcome: LiveContinuationDecision?

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.workerOutputIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    status: LiveSingleAgentWorkerStatus,
    processID: Int32,
    generationSHA256: String,
    stateSHA256: String,
    checkpoint: LiveSingleAgentCheckpointID? = nil,
    candidateOID: String? = nil,
    acceptanceProcessID: Int32? = nil,
    acceptanceVerdict: LiveGitCandidateAcceptanceVerdict? = nil,
    acceptanceReceiptSHA256: String? = nil,
    terminalOutcome: LiveContinuationDecision? = nil
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.status = status
    self.processID = processID
    self.generationSHA256 = generationSHA256
    self.stateSHA256 = stateSHA256
    self.checkpoint = checkpoint
    self.candidateOID = candidateOID
    self.acceptanceProcessID = acceptanceProcessID
    self.acceptanceVerdict = acceptanceVerdict
    self.acceptanceReceiptSHA256 = acceptanceReceiptSHA256
    self.terminalOutcome = terminalOutcome
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case status
    case processID = "process_id"
    case generationSHA256 = "generation_sha256"
    case stateSHA256 = "state_sha256"
    case checkpoint
    case candidateOID = "candidate_oid"
    case acceptanceProcessID = "acceptance_process_id"
    case acceptanceVerdict = "acceptance_verdict"
    case acceptanceReceiptSHA256 = "acceptance_receipt_sha256"
    case terminalOutcome = "terminal_outcome"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    status = try container.decode(LiveSingleAgentWorkerStatus.self, forKey: .status)
    processID = try container.decode(Int32.self, forKey: .processID)
    generationSHA256 = try container.decode(String.self, forKey: .generationSHA256)
    stateSHA256 = try container.decode(String.self, forKey: .stateSHA256)
    checkpoint = try container.decodeIfPresent(
      LiveSingleAgentCheckpointID.self,
      forKey: .checkpoint
    )
    candidateOID = try container.decodeIfPresent(String.self, forKey: .candidateOID)
    acceptanceProcessID = try container.decodeIfPresent(Int32.self, forKey: .acceptanceProcessID)
    acceptanceVerdict = try container.decodeIfPresent(
      LiveGitCandidateAcceptanceVerdict.self,
      forKey: .acceptanceVerdict
    )
    acceptanceReceiptSHA256 = try container.decodeIfPresent(
      String.self,
      forKey: .acceptanceReceiptSHA256
    )
    terminalOutcome = try container.decodeIfPresent(
      LiveContinuationDecision.self,
      forKey: .terminalOutcome
    )
  }
}

public struct LiveSingleAgentProjection: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let executionPassportSHA256: String
  public let eventKinds: [LiveEpisodeEventKind]
  public let chargedBudget: LiveBudget
  public let selectedVariantID: String
  public let transitionPhase: LiveTransitionPhase
  public let terminalOutcome: LiveContinuationDecision
  public let candidateOID: String
  public let parentOID: String
  public let treeOID: String
  public let candidateBranch: String
  public let resultRef: String
  public let acceptanceVerdict: LiveGitCandidateAcceptanceVerdict

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.projectionIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    executionPassportSHA256: String,
    eventKinds: [LiveEpisodeEventKind],
    chargedBudget: LiveBudget,
    selectedVariantID: String,
    transitionPhase: LiveTransitionPhase,
    terminalOutcome: LiveContinuationDecision,
    candidateOID: String,
    parentOID: String,
    treeOID: String,
    candidateBranch: String,
    resultRef: String,
    acceptanceVerdict: LiveGitCandidateAcceptanceVerdict
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.executionPassportSHA256 = executionPassportSHA256
    self.eventKinds = eventKinds
    self.chargedBudget = chargedBudget
    self.selectedVariantID = selectedVariantID
    self.transitionPhase = transitionPhase
    self.terminalOutcome = terminalOutcome
    self.candidateOID = candidateOID
    self.parentOID = parentOID
    self.treeOID = treeOID
    self.candidateBranch = candidateBranch
    self.resultRef = resultRef
    self.acceptanceVerdict = acceptanceVerdict
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case executionPassportSHA256 = "execution_passport_sha256"
    case eventKinds = "event_kinds"
    case chargedBudget = "charged_budget"
    case selectedVariantID = "selected_variant_id"
    case transitionPhase = "transition_phase"
    case terminalOutcome = "terminal_outcome"
    case candidateOID = "candidate_oid"
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
    case candidateBranch = "candidate_branch"
    case resultRef = "result_ref"
    case acceptanceVerdict = "acceptance_verdict"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    executionPassportSHA256 = try container.decode(
      String.self,
      forKey: .executionPassportSHA256
    )
    eventKinds = try container.decode([LiveEpisodeEventKind].self, forKey: .eventKinds)
    chargedBudget = try container.decode(LiveBudget.self, forKey: .chargedBudget)
    selectedVariantID = try container.decode(String.self, forKey: .selectedVariantID)
    transitionPhase = try container.decode(LiveTransitionPhase.self, forKey: .transitionPhase)
    terminalOutcome = try container.decode(LiveContinuationDecision.self, forKey: .terminalOutcome)
    candidateOID = try container.decode(String.self, forKey: .candidateOID)
    parentOID = try container.decode(String.self, forKey: .parentOID)
    treeOID = try container.decode(String.self, forKey: .treeOID)
    candidateBranch = try container.decode(String.self, forKey: .candidateBranch)
    resultRef = try container.decode(String.self, forKey: .resultRef)
    acceptanceVerdict = try container.decode(
      LiveGitCandidateAcceptanceVerdict.self,
      forKey: .acceptanceVerdict
    )
  }
}

public struct LiveSingleAgentEpisodeReport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let transportMode: LiveSingleAgentTransportMode
  public let executionPassportSHA256: String
  public let providerIdentity: LiveProviderIdentity
  public let chargedUsage: LiveBudget
  public let harnessProcessID: Int32
  public let workerProcessIDs: [Int32]
  public let sigkillProcessIDs: [Int32]
  public let replayProcessIDs: [Int32]
  public let checkpoints: [LiveSingleAgentCheckpointMarker]
  public let externalConfirmationSHA256: String
  public let candidateOID: String
  public let parentOID: String
  public let treeOID: String
  public let candidateBranch: String
  public let resultRef: String
  public let acceptanceProcessID: Int32
  public let acceptanceVerdict: LiveGitCandidateAcceptanceVerdict
  public let acceptanceReceiptSHA256: String
  public let terminalOutcome: LiveContinuationDecision
  public let finalGenerationSHA256: String
  public let finalStateSHA256: String
  public let eventJournalSHA256: String
  public let projectionSHA256: String
  public let eventCount: Int
  public let modelResponseCount: Int
  public let budgetCheckpointNoCall: Bool
  public let replayBytesEqual: Bool
  public let replayNoEffects: Bool
  public let sourceUnchanged: Bool

  public init(
    schemaIdentity: String = LiveSingleAgentEpisodeSchema.reportIdentity,
    schemaVersion: Int = LiveSingleAgentEpisodeSchema.version,
    transportMode: LiveSingleAgentTransportMode,
    executionPassportSHA256: String,
    providerIdentity: LiveProviderIdentity,
    chargedUsage: LiveBudget,
    harnessProcessID: Int32,
    workerProcessIDs: [Int32],
    sigkillProcessIDs: [Int32],
    replayProcessIDs: [Int32],
    checkpoints: [LiveSingleAgentCheckpointMarker],
    externalConfirmationSHA256: String,
    candidateOID: String,
    parentOID: String,
    treeOID: String,
    candidateBranch: String,
    resultRef: String,
    acceptanceProcessID: Int32,
    acceptanceVerdict: LiveGitCandidateAcceptanceVerdict,
    acceptanceReceiptSHA256: String,
    terminalOutcome: LiveContinuationDecision,
    finalGenerationSHA256: String,
    finalStateSHA256: String,
    eventJournalSHA256: String,
    projectionSHA256: String,
    eventCount: Int,
    modelResponseCount: Int,
    budgetCheckpointNoCall: Bool,
    replayBytesEqual: Bool,
    replayNoEffects: Bool,
    sourceUnchanged: Bool
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.transportMode = transportMode
    self.executionPassportSHA256 = executionPassportSHA256
    self.providerIdentity = providerIdentity
    self.chargedUsage = chargedUsage
    self.harnessProcessID = harnessProcessID
    self.workerProcessIDs = workerProcessIDs
    self.sigkillProcessIDs = sigkillProcessIDs
    self.replayProcessIDs = replayProcessIDs
    self.checkpoints = checkpoints
    self.externalConfirmationSHA256 = externalConfirmationSHA256
    self.candidateOID = candidateOID
    self.parentOID = parentOID
    self.treeOID = treeOID
    self.candidateBranch = candidateBranch
    self.resultRef = resultRef
    self.acceptanceProcessID = acceptanceProcessID
    self.acceptanceVerdict = acceptanceVerdict
    self.acceptanceReceiptSHA256 = acceptanceReceiptSHA256
    self.terminalOutcome = terminalOutcome
    self.finalGenerationSHA256 = finalGenerationSHA256
    self.finalStateSHA256 = finalStateSHA256
    self.eventJournalSHA256 = eventJournalSHA256
    self.projectionSHA256 = projectionSHA256
    self.eventCount = eventCount
    self.modelResponseCount = modelResponseCount
    self.budgetCheckpointNoCall = budgetCheckpointNoCall
    self.replayBytesEqual = replayBytesEqual
    self.replayNoEffects = replayNoEffects
    self.sourceUnchanged = sourceUnchanged
  }

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case transportMode = "transport_mode"
    case executionPassportSHA256 = "execution_passport_sha256"
    case providerIdentity = "provider_identity"
    case chargedUsage = "charged_usage"
    case harnessProcessID = "harness_process_id"
    case workerProcessIDs = "worker_process_ids"
    case sigkillProcessIDs = "sigkill_process_ids"
    case replayProcessIDs = "replay_process_ids"
    case checkpoints
    case externalConfirmationSHA256 = "external_confirmation_sha256"
    case candidateOID = "candidate_oid"
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
    case candidateBranch = "candidate_branch"
    case resultRef = "result_ref"
    case acceptanceProcessID = "acceptance_process_id"
    case acceptanceVerdict = "acceptance_verdict"
    case acceptanceReceiptSHA256 = "acceptance_receipt_sha256"
    case terminalOutcome = "terminal_outcome"
    case finalGenerationSHA256 = "final_generation_sha256"
    case finalStateSHA256 = "final_state_sha256"
    case eventJournalSHA256 = "event_journal_sha256"
    case projectionSHA256 = "projection_sha256"
    case eventCount = "event_count"
    case modelResponseCount = "model_response_count"
    case budgetCheckpointNoCall = "budget_checkpoint_no_call"
    case replayBytesEqual = "replay_bytes_equal"
    case replayNoEffects = "replay_no_effects"
    case sourceUnchanged = "source_unchanged"
  }
}
