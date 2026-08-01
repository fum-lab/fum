import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public enum LiveGitCandidateRuntimeSchema {
  public static let planIdentity = "fum.live_git_candidate.plan"
  public static let passportIdentity = "fum.live_git_candidate.passport"
  public static let version = 1
  public static let operation = "create_candidate_commit"
  public static let cloneRelativePath = "git-candidate-clone"
  public static let candidatesRelativePath = "candidates"
  public static let passportFileName = "passport.json"

  public static func passportRelativePath(candidateOID: String) -> String {
    "\(candidatesRelativePath)/\(candidateOID)/\(passportFileName)"
  }
}

public enum LiveGitRegularFileMode: String, Codable, Equatable, Sendable {
  case regular = "100644"
  case executable = "100755"
}

public struct LiveGitRegularFileWrite: Codable, Equatable, Sendable {
  public let path: String
  public let mode: LiveGitRegularFileMode
  public let contentsBase64: String

  public init(path: String, mode: LiveGitRegularFileMode, contents: Data) {
    self.path = path
    self.mode = mode
    contentsBase64 = contents.base64EncodedString()
  }

  public var contents: Data? {
    guard let decoded = Data(base64Encoded: contentsBase64),
      decoded.base64EncodedString() == contentsBase64
    else {
      return nil
    }
    return decoded
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case path
    case mode
    case contentsBase64 = "contents_base64"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    path = try container.decode(String.self, forKey: .path)
    mode = try container.decode(LiveGitRegularFileMode.self, forKey: .mode)
    contentsBase64 = try container.decode(String.self, forKey: .contentsBase64)
  }
}

/// Canonical action arguments. Transition coordinates deliberately live outside this value:
/// `expected_effect_sha256` and the selected intent's `arguments_sha256` both bind to this
/// object's canonical digest without creating a self-referential hash.
public struct LiveGitCandidatePlan: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let operation: String
  public let policy: LiveGitCandidateCommitPolicy
  public let writes: [LiveGitRegularFileWrite]
  public let preflightEventID: String
  public let preflightReceiptID: String
  public let executionEventID: String
  public let executionReceiptID: String
  public let observationEventID: String
  public let observationReceiptID: String

  public init(
    schemaIdentity: String = LiveGitCandidateRuntimeSchema.planIdentity,
    schemaVersion: Int = LiveGitCandidateRuntimeSchema.version,
    operation: String = LiveGitCandidateRuntimeSchema.operation,
    policy: LiveGitCandidateCommitPolicy,
    writes: [LiveGitRegularFileWrite],
    preflightEventID: String,
    preflightReceiptID: String,
    executionEventID: String,
    executionReceiptID: String,
    observationEventID: String,
    observationReceiptID: String
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.operation = operation
    self.policy = policy
    self.writes = writes
    self.preflightEventID = preflightEventID
    self.preflightReceiptID = preflightReceiptID
    self.executionEventID = executionEventID
    self.executionReceiptID = executionReceiptID
    self.observationEventID = observationEventID
    self.observationReceiptID = observationReceiptID
  }

  public func canonicalSHA256() throws -> String {
    CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(self))
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case operation
    case policy
    case writes
    case preflightEventID = "preflight_event_id"
    case preflightReceiptID = "preflight_receipt_id"
    case executionEventID = "execution_event_id"
    case executionReceiptID = "execution_receipt_id"
    case observationEventID = "observation_event_id"
    case observationReceiptID = "observation_receipt_id"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    operation = try container.decode(String.self, forKey: .operation)
    policy = try container.decode(LiveGitCandidateCommitPolicy.self, forKey: .policy)
    writes = try container.decode([LiveGitRegularFileWrite].self, forKey: .writes)
    preflightEventID = try container.decode(String.self, forKey: .preflightEventID)
    preflightReceiptID = try container.decode(String.self, forKey: .preflightReceiptID)
    executionEventID = try container.decode(String.self, forKey: .executionEventID)
    executionReceiptID = try container.decode(String.self, forKey: .executionReceiptID)
    observationEventID = try container.decode(String.self, forKey: .observationEventID)
    observationReceiptID = try container.decode(String.self, forKey: .observationReceiptID)
  }
}

public struct LiveGitCandidateExpectedWrite: Codable, Equatable, Sendable {
  public let path: String
  public let mode: LiveGitRegularFileMode
  public let contentsSHA256: String

  public init(path: String, mode: LiveGitRegularFileMode, contentsSHA256: String) {
    self.path = path
    self.mode = mode
    self.contentsSHA256 = contentsSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case path
    case mode
    case contentsSHA256 = "contents_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    path = try container.decode(String.self, forKey: .path)
    mode = try container.decode(LiveGitRegularFileMode.self, forKey: .mode)
    contentsSHA256 = try container.decode(String.self, forKey: .contentsSHA256)
  }
}

public enum LiveGitCheckerStatus: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct LiveGitCheckerObservation: Codable, Equatable, Sendable {
  public let checkerID: String
  public let status: LiveGitCheckerStatus
  public let observationSHA256: String

  public init(checkerID: String, status: LiveGitCheckerStatus, observationSHA256: String) {
    self.checkerID = checkerID
    self.status = status
    self.observationSHA256 = observationSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case checkerID = "checker_id"
    case status
    case observationSHA256 = "observation_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checkerID = try container.decode(String.self, forKey: .checkerID)
    status = try container.decode(LiveGitCheckerStatus.self, forKey: .status)
    observationSHA256 = try container.decode(String.self, forKey: .observationSHA256)
  }
}

public struct LiveGitCandidatePassport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let canonicalProfile: String
  public let planSHA256: String
  public let coordinates: LiveTransitionCoordinates
  public let parentOID: String
  public let treeOID: String
  public let candidateOID: String
  public let candidateBranchRef: String
  public let resultRef: String
  public let cloneRelativePath: String
  public let storageRelativePath: String
  public let allowedPaths: [String]
  public let changedPaths: [String]
  public let expectedWrites: [LiveGitCandidateExpectedWrite]
  public let checkerSpecifications: [LiveGitCandidateCheckerSpec]
  public let checkerObservations: [LiveGitCheckerObservation]
  public let author: LiveGitCandidateSignature
  public let committer: LiveGitCandidateSignature
  public let message: String
  public let preflightEventID: String
  public let preflightReceiptID: String
  public let executionEventID: String
  public let executionReceiptID: String
  public let observationEventID: String
  public let observationReceiptID: String

  public init(
    schemaIdentity: String = LiveGitCandidateRuntimeSchema.passportIdentity,
    schemaVersion: Int = LiveGitCandidateRuntimeSchema.version,
    canonicalProfile: String = CanonicalMemoryJSON.profileID,
    planSHA256: String,
    coordinates: LiveTransitionCoordinates,
    parentOID: String,
    treeOID: String,
    candidateOID: String,
    candidateBranchRef: String,
    resultRef: String,
    cloneRelativePath: String = LiveGitCandidateRuntimeSchema.cloneRelativePath,
    storageRelativePath: String? = nil,
    allowedPaths: [String],
    changedPaths: [String],
    expectedWrites: [LiveGitCandidateExpectedWrite],
    checkerSpecifications: [LiveGitCandidateCheckerSpec],
    checkerObservations: [LiveGitCheckerObservation],
    author: LiveGitCandidateSignature,
    committer: LiveGitCandidateSignature,
    message: String,
    preflightEventID: String,
    preflightReceiptID: String,
    executionEventID: String,
    executionReceiptID: String,
    observationEventID: String,
    observationReceiptID: String
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.canonicalProfile = canonicalProfile
    self.planSHA256 = planSHA256
    self.coordinates = coordinates
    self.parentOID = parentOID
    self.treeOID = treeOID
    self.candidateOID = candidateOID
    self.candidateBranchRef = candidateBranchRef
    self.resultRef = resultRef
    self.cloneRelativePath = cloneRelativePath
    self.storageRelativePath =
      storageRelativePath
      ?? LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: candidateOID)
    self.allowedPaths = allowedPaths
    self.changedPaths = changedPaths
    self.expectedWrites = expectedWrites
    self.checkerSpecifications = checkerSpecifications
    self.checkerObservations = checkerObservations
    self.author = author
    self.committer = committer
    self.message = message
    self.preflightEventID = preflightEventID
    self.preflightReceiptID = preflightReceiptID
    self.executionEventID = executionEventID
    self.executionReceiptID = executionReceiptID
    self.observationEventID = observationEventID
    self.observationReceiptID = observationReceiptID
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case planSHA256 = "plan_sha256"
    case coordinates
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
    case candidateOID = "candidate_oid"
    case candidateBranchRef = "candidate_branch_ref"
    case resultRef = "result_ref"
    case cloneRelativePath = "clone_relative_path"
    case storageRelativePath = "storage_relative_path"
    case allowedPaths = "allowed_paths"
    case changedPaths = "changed_paths"
    case expectedWrites = "expected_writes"
    case checkerSpecifications = "checker_specifications"
    case checkerObservations = "checker_observations"
    case author
    case committer
    case message
    case preflightEventID = "preflight_event_id"
    case preflightReceiptID = "preflight_receipt_id"
    case executionEventID = "execution_event_id"
    case executionReceiptID = "execution_receipt_id"
    case observationEventID = "observation_event_id"
    case observationReceiptID = "observation_receipt_id"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    canonicalProfile = try container.decode(String.self, forKey: .canonicalProfile)
    planSHA256 = try container.decode(String.self, forKey: .planSHA256)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    parentOID = try container.decode(String.self, forKey: .parentOID)
    treeOID = try container.decode(String.self, forKey: .treeOID)
    candidateOID = try container.decode(String.self, forKey: .candidateOID)
    candidateBranchRef = try container.decode(String.self, forKey: .candidateBranchRef)
    resultRef = try container.decode(String.self, forKey: .resultRef)
    cloneRelativePath = try container.decode(String.self, forKey: .cloneRelativePath)
    storageRelativePath = try container.decode(String.self, forKey: .storageRelativePath)
    allowedPaths = try container.decode([String].self, forKey: .allowedPaths)
    changedPaths = try container.decode([String].self, forKey: .changedPaths)
    expectedWrites = try container.decode(
      [LiveGitCandidateExpectedWrite].self, forKey: .expectedWrites)
    checkerSpecifications = try container.decode(
      [LiveGitCandidateCheckerSpec].self,
      forKey: .checkerSpecifications
    )
    checkerObservations = try container.decode(
      [LiveGitCheckerObservation].self,
      forKey: .checkerObservations
    )
    author = try container.decode(LiveGitCandidateSignature.self, forKey: .author)
    committer = try container.decode(LiveGitCandidateSignature.self, forKey: .committer)
    message = try container.decode(String.self, forKey: .message)
    preflightEventID = try container.decode(String.self, forKey: .preflightEventID)
    preflightReceiptID = try container.decode(String.self, forKey: .preflightReceiptID)
    executionEventID = try container.decode(String.self, forKey: .executionEventID)
    executionReceiptID = try container.decode(String.self, forKey: .executionReceiptID)
    observationEventID = try container.decode(String.self, forKey: .observationEventID)
    observationReceiptID = try container.decode(String.self, forKey: .observationReceiptID)
  }

  public func canonicalJSON() throws -> Data {
    try CanonicalMemoryJSON.encode(self)
  }

  public func canonicalSHA256() throws -> String {
    CanonicalMemoryJSON.sha256(try canonicalJSON())
  }

  public func validate() throws {
    guard schemaIdentity == LiveGitCandidateRuntimeSchema.passportIdentity,
      schemaVersion == LiveGitCandidateRuntimeSchema.version,
      canonicalProfile == CanonicalMemoryJSON.profileID,
      liveGitIsSHA256(planSHA256),
      coordinates.expectedEffectSHA256 == planSHA256,
      cloneRelativePath == LiveGitCandidateRuntimeSchema.cloneRelativePath,
      storageRelativePath
        == LiveGitCandidateRuntimeSchema.passportRelativePath(candidateOID: candidateOID)
    else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport identity, binding, or storage path is invalid."
      )
    }
    let validationPolicy = LiveGitCandidateCommitPolicy(
      allowedPaths: allowedPaths,
      checkers: checkerSpecifications,
      baseCommitOID: parentOID,
      expectedTreeOID: treeOID,
      expectedCandidateOID: candidateOID,
      candidateBranch: candidateBranchRef,
      resultRef: resultRef,
      author: author,
      committer: committer,
      message: message,
      producerIDs: LiveGitCandidateProducerIDs(
        transitionUserConfirmed: "passport-validator-confirmed",
        authorized: "passport-validator-authorized",
        preflightPassed: "passport-validator-preflight",
        executed: "passport-validator-executed",
        observed: "passport-validator-observed"
      )
    )
    do {
      try validationPolicy.validate()
    } catch {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport policy projection is invalid: \(error)"
      )
    }
    guard changedPaths == changedPaths.sorted(),
      !changedPaths.isEmpty,
      Set(changedPaths).count == changedPaths.count,
      Set(changedPaths).isSubset(of: Set(allowedPaths)),
      expectedWrites.map(\.path) == changedPaths,
      expectedWrites.allSatisfy({ liveGitIsSHA256($0.contentsSHA256) }),
      checkerObservations.map(\.checkerID) == checkerSpecifications.map(\.checkerID),
      checkerObservations.allSatisfy({ $0.status == .passed }),
      checkerObservations.allSatisfy({ liveGitIsSHA256($0.observationSHA256) }),
      [
        preflightEventID,
        preflightReceiptID,
        executionEventID,
        executionReceiptID,
        observationEventID,
        observationReceiptID,
      ].allSatisfy(liveGitIsTechnicalIdentifier),
      Set([
        preflightEventID,
        preflightReceiptID,
        executionEventID,
        executionReceiptID,
        observationEventID,
        observationReceiptID,
      ]).count == 6
    else {
      throw LiveGitCandidateRuntimeError.persistence(
        "Candidate passport diff or checker observations are invalid."
      )
    }
  }
}

private func liveGitIsSHA256(_ value: String) -> Bool {
  value.hasPrefix("sha256:") && value.count == 71
    && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
}

private func liveGitIsTechnicalIdentifier(_ value: String) -> Bool {
  guard let first = value.unicodeScalars.first, value.unicodeScalars.count <= 128 else {
    return false
  }
  let initial = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
  let remaining = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
  return initial.contains(first) && value.unicodeScalars.allSatisfy(remaining.contains)
}

public struct LiveGitCandidateCommitResult: Equatable, Sendable {
  public let passport: LiveGitCandidatePassport
  public let passportCanonicalJSON: Data
  public let passportSHA256: String
  public let candidateOID: String
  public let executionEvidence: LiveEvidenceObject

  public init(passport: LiveGitCandidatePassport, passportCanonicalJSON: Data) {
    self.passport = passport
    self.passportCanonicalJSON = passportCanonicalJSON
    passportSHA256 = CanonicalMemoryJSON.sha256(passportCanonicalJSON)
    candidateOID = passport.candidateOID
    executionEvidence = LiveEvidenceObject(
      evidenceID: passport.executionReceiptID,
      evidenceSHA256: CanonicalMemoryJSON.sha256(Data(passport.candidateOID.utf8))
    )
  }
}

public struct LiveGitCandidateObservationRequest: Sendable {
  public let episodeDirectoryURL: URL
  public let coordinates: LiveTransitionCoordinates
  public let plan: LiveGitCandidatePlan
  public let candidateOID: String
  public let expectedPassportSHA256: String

  public init(
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    candidateOID: String,
    expectedPassportSHA256: String
  ) {
    self.episodeDirectoryURL = episodeDirectoryURL
    self.coordinates = coordinates
    self.plan = plan
    self.candidateOID = candidateOID
    self.expectedPassportSHA256 = expectedPassportSHA256
  }
}

public struct LiveGitCandidateObservationResult: Equatable, Sendable {
  public let passport: LiveGitCandidatePassport
  public let passportSHA256: String
  public let observationEvidence: LiveEvidenceObject

  public init(passport: LiveGitCandidatePassport, passportSHA256: String) {
    self.passport = passport
    self.passportSHA256 = passportSHA256
    observationEvidence = LiveEvidenceObject(
      evidenceID: passport.observationReceiptID,
      evidenceSHA256: passportSHA256
    )
  }
}

public struct LiveGitCandidateExecutionRequest: Sendable {
  public let sourceCheckoutURL: URL
  public let episodeDirectoryURL: URL
  public let coordinates: LiveTransitionCoordinates
  public let plan: LiveGitCandidatePlan
  public let selectedIntent: LiveUntrustedActionIntent
  public let allowance: LiveAllowedAction
  public let confirmedPreflightReceipts: [LiveGitCandidateStageReceipt]
  public let confirmedPreflightEvents: [LiveEpisodeEvent]

  public init(
    sourceCheckoutURL: URL,
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    selectedIntent: LiveUntrustedActionIntent,
    allowance: LiveAllowedAction,
    confirmedPreflightReceipts: [LiveGitCandidateStageReceipt],
    confirmedPreflightEvents: [LiveEpisodeEvent]
  ) {
    self.sourceCheckoutURL = sourceCheckoutURL
    self.episodeDirectoryURL = episodeDirectoryURL
    self.coordinates = coordinates
    self.plan = plan
    self.selectedIntent = selectedIntent
    self.allowance = allowance
    self.confirmedPreflightReceipts = confirmedPreflightReceipts
    self.confirmedPreflightEvents = confirmedPreflightEvents
  }
}

public struct LiveGitCandidatePreflightRequest: Sendable {
  public let sourceCheckoutURL: URL
  public let episodeDirectoryURL: URL
  public let coordinates: LiveTransitionCoordinates
  public let plan: LiveGitCandidatePlan
  public let selectedIntent: LiveUntrustedActionIntent
  public let allowance: LiveAllowedAction
  public let confirmedAuthorizationReceipts: [LiveGitCandidateStageReceipt]
  public let confirmedAuthorizationEvents: [LiveEpisodeEvent]

  public init(
    sourceCheckoutURL: URL,
    episodeDirectoryURL: URL,
    coordinates: LiveTransitionCoordinates,
    plan: LiveGitCandidatePlan,
    selectedIntent: LiveUntrustedActionIntent,
    allowance: LiveAllowedAction,
    confirmedAuthorizationReceipts: [LiveGitCandidateStageReceipt],
    confirmedAuthorizationEvents: [LiveEpisodeEvent]
  ) {
    self.sourceCheckoutURL = sourceCheckoutURL
    self.episodeDirectoryURL = episodeDirectoryURL
    self.coordinates = coordinates
    self.plan = plan
    self.selectedIntent = selectedIntent
    self.allowance = allowance
    self.confirmedAuthorizationReceipts = confirmedAuthorizationReceipts
    self.confirmedAuthorizationEvents = confirmedAuthorizationEvents
  }
}

public struct LiveGitCandidatePreflightResult: Equatable, Sendable {
  public let planSHA256: String
  public let baseCommitOID: String
  public let objectFormat: String
  public let preflightEventID: String
  public let preflightEvidence: LiveEvidenceObject

  public init(
    planSHA256: String,
    baseCommitOID: String,
    objectFormat: String,
    preflightEventID: String,
    preflightEvidence: LiveEvidenceObject
  ) {
    self.planSHA256 = planSHA256
    self.baseCommitOID = baseCommitOID
    self.objectFormat = objectFormat
    self.preflightEventID = preflightEventID
    self.preflightEvidence = preflightEvidence
  }
}

public enum LiveGitCandidateCheckpoint: String, Equatable, Sendable {
  case clonePrepared = "clone-prepared"
  case writesStaged = "writes-staged"
  case resultRefPublished = "result-ref-published"
}

public enum LiveGitCandidateRuntimeError: Error, Equatable, Sendable {
  case invalidPlan(String)
  case invalidEvidence(String)
  case unsafePath(String)
  case sourceBaseChanged(expected: String, actual: String)
  case gitProcess(String)
  case unexpectedDiff(expected: [String], actual: [String])
  case checkerFailed(String)
  case candidateConflict(ref: String, expected: String, actual: String?)
  case persistence(String)
}

extension LiveGitCandidateRuntimeError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidPlan(let message), .invalidEvidence(let message), .gitProcess(let message),
      .checkerFailed(let message), .persistence(let message):
      return message
    case .unsafePath(let path):
      return "Unsafe candidate path: \(path)"
    case .sourceBaseChanged(let expected, let actual):
      return "Source HEAD changed: expected \(expected), actual \(actual)."
    case .unexpectedDiff(let expected, let actual):
      return "Unexpected diff: expected \(expected), actual \(actual)."
    case .candidateConflict(let ref, let expected, let actual):
      return
        "Candidate ref conflict at \(ref): expected \(expected), actual \(actual ?? "missing")."
    }
  }
}
