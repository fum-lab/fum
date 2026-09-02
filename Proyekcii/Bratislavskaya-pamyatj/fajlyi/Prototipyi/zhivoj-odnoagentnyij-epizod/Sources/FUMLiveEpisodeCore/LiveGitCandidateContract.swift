import CryptoKit
import Foundation

public enum LiveGitCandidateContract {
  public static let policyIdentity = "fum.live_single_agent_episode.git_candidate_policy"
  public static let receiptIdentity = "fum.live_single_agent_episode.git_candidate_stage_receipt"
  public static let version = 1
  public static let operation = "create_candidate_commit"
}

public enum LiveGitCandidateContractError: Error, Equatable, Sendable {
  case unsupportedPolicySchema(identity: String, version: Int)
  case unsupportedReceiptSchema(identity: String, version: Int)
  case invalidPolicy(String)
  case invalidReceipt(String)
}

extension LiveGitCandidateContractError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unsupportedPolicySchema(let identity, let version):
      "Неподдерживаемая схема candidate policy \(identity) версии \(version)."
    case .unsupportedReceiptSchema(let identity, let version):
      "Неподдерживаемая схема candidate receipt \(identity) версии \(version)."
    case .invalidPolicy(let message), .invalidReceipt(let message):
      message
    }
  }
}

public enum LiveGitCandidateCanonicalJSON {
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
  }

  public static func sha256<T: Encodable>(_ value: T) throws -> String {
    let digest = SHA256.hash(data: try encode(value))
    return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
  }
}

public enum LiveGitCandidateCheckerArgvGrammar: String, Codable, CaseIterable, Sendable {
  case gitDiffCheckV1 = "git_diff_check_v1"
}

public struct LiveGitCandidateCheckerSpec: Codable, Equatable, Sendable {
  public let checkerID: String
  public let argvGrammar: LiveGitCandidateCheckerArgvGrammar

  public init(checkerID: String, argvGrammar: LiveGitCandidateCheckerArgvGrammar) {
    self.checkerID = checkerID
    self.argvGrammar = argvGrammar
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case checkerID = "checker_id"
    case argvGrammar = "argv_grammar"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checkerID = try container.decode(String.self, forKey: .checkerID)
    argvGrammar = try container.decode(
      LiveGitCandidateCheckerArgvGrammar.self,
      forKey: .argvGrammar
    )
  }
}

public struct LiveGitCandidateSignature: Codable, Equatable, Sendable {
  public let name: String
  public let email: String
  public let timestampSeconds: Int64
  public let timeZoneOffsetMinutes: Int

  public init(
    name: String,
    email: String,
    timestampSeconds: Int64,
    timeZoneOffsetMinutes: Int
  ) {
    self.name = name
    self.email = email
    self.timestampSeconds = timestampSeconds
    self.timeZoneOffsetMinutes = timeZoneOffsetMinutes
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case name
    case email
    case timestampSeconds = "timestamp_seconds"
    case timeZoneOffsetMinutes = "time_zone_offset_minutes"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    email = try container.decode(String.self, forKey: .email)
    timestampSeconds = try container.decode(Int64.self, forKey: .timestampSeconds)
    timeZoneOffsetMinutes = try container.decode(Int.self, forKey: .timeZoneOffsetMinutes)
  }
}

public enum LiveGitCandidateStage: String, Codable, CaseIterable, Sendable {
  case transitionUserConfirmed = "transition_user_confirmed"
  case authorized
  case preflightPassed = "preflight_passed"
  case executed
  case observed
}

public struct LiveGitCandidateProducerIDs: Codable, Equatable, Sendable {
  public let transitionUserConfirmed: String
  public let authorized: String
  public let preflightPassed: String
  public let executed: String
  public let observed: String

  public init(
    transitionUserConfirmed: String,
    authorized: String,
    preflightPassed: String,
    executed: String,
    observed: String
  ) {
    self.transitionUserConfirmed = transitionUserConfirmed
    self.authorized = authorized
    self.preflightPassed = preflightPassed
    self.executed = executed
    self.observed = observed
  }

  public func producerID(for stage: LiveGitCandidateStage) -> String {
    switch stage {
    case .transitionUserConfirmed: transitionUserConfirmed
    case .authorized: authorized
    case .preflightPassed: preflightPassed
    case .executed: executed
    case .observed: observed
    }
  }

  var ordered: [String] {
    LiveGitCandidateStage.allCases.map(producerID(for:))
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case transitionUserConfirmed = "transition_user_confirmed"
    case authorized
    case preflightPassed = "preflight_passed"
    case executed
    case observed
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    transitionUserConfirmed = try container.decode(
      String.self,
      forKey: .transitionUserConfirmed
    )
    authorized = try container.decode(String.self, forKey: .authorized)
    preflightPassed = try container.decode(String.self, forKey: .preflightPassed)
    executed = try container.decode(String.self, forKey: .executed)
    observed = try container.decode(String.self, forKey: .observed)
  }
}

public struct LiveGitCandidateCommitPolicy: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let allowedPaths: [String]
  public let checkers: [LiveGitCandidateCheckerSpec]
  public let baseCommitOID: String
  public let expectedTreeOID: String
  public let expectedCandidateOID: String
  public let candidateBranch: String
  public let resultRef: String
  public let author: LiveGitCandidateSignature
  public let committer: LiveGitCandidateSignature
  public let message: String
  public let producerIDs: LiveGitCandidateProducerIDs

  public init(
    schemaIdentity: String = LiveGitCandidateContract.policyIdentity,
    schemaVersion: Int = LiveGitCandidateContract.version,
    allowedPaths: [String],
    checkers: [LiveGitCandidateCheckerSpec],
    baseCommitOID: String,
    expectedTreeOID: String,
    expectedCandidateOID: String,
    candidateBranch: String,
    resultRef: String,
    author: LiveGitCandidateSignature,
    committer: LiveGitCandidateSignature,
    message: String,
    producerIDs: LiveGitCandidateProducerIDs
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.allowedPaths = allowedPaths
    self.checkers = checkers
    self.baseCommitOID = baseCommitOID
    self.expectedTreeOID = expectedTreeOID
    self.expectedCandidateOID = expectedCandidateOID
    self.candidateBranch = candidateBranch
    self.resultRef = resultRef
    self.author = author
    self.committer = committer
    self.message = message
    self.producerIDs = producerIDs
  }

  public func validate() throws {
    guard schemaIdentity == LiveGitCandidateContract.policyIdentity,
      schemaVersion == LiveGitCandidateContract.version
    else {
      throw LiveGitCandidateContractError.unsupportedPolicySchema(
        identity: schemaIdentity,
        version: schemaVersion
      )
    }
    guard !allowedPaths.isEmpty,
      allowedPaths == allowedPaths.sorted(),
      Set(allowedPaths).count == allowedPaths.count
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "allowed_paths должен быть непустым сортированным списком без повторов."
      )
    }
    for path in allowedPaths {
      guard Self.isSafeRelativePath(path) else {
        throw LiveGitCandidateContractError.invalidPolicy(
          "Разрешённый путь \(path) не является безопасным относительным путём."
        )
      }
    }
    guard !checkers.isEmpty,
      checkers.map(\.checkerID) == checkers.map(\.checkerID).sorted(),
      Set(checkers.map(\.checkerID)).count == checkers.count
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "checkers должен быть непустым сортированным списком без повторов."
      )
    }
    for checker in checkers {
      guard Self.isTechnicalIdentifier(checker.checkerID) else {
        throw LiveGitCandidateContractError.invalidPolicy(
          "checker_id не является техническим идентификатором."
        )
      }
    }
    let objectIDs = [baseCommitOID, expectedTreeOID, expectedCandidateOID]
    guard objectIDs.allSatisfy(Self.isGitOID),
      Set(objectIDs.map(\.count)).count == 1
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "Git object IDs должны быть точными lowercase SHA-1 либо SHA-256 одного формата."
      )
    }
    guard Self.isValidRef(candidateBranch, prefix: "refs/heads/") else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "candidate_branch не является закрытой веткой refs/heads/."
      )
    }
    guard Self.isValidRef(resultRef, prefix: "refs/fum/candidates/") else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "result_ref не принадлежит refs/fum/candidates/."
      )
    }
    try Self.validate(signature: author, field: "author")
    try Self.validate(signature: committer, field: "committer")
    guard !message.isEmpty, message.utf8.count <= 65_536,
      !message.contains("\0"), !message.contains("\r"), message.hasSuffix("\n")
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "Commit message должен быть непустым точным UTF-8-текстом с завершающим LF."
      )
    }
    guard producerIDs.ordered.allSatisfy(Self.isTechnicalIdentifier),
      Set(producerIDs.ordered).count == LiveGitCandidateStage.allCases.count
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "Пять стадий требуют разные зарегистрированные producer_id."
      )
    }
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case allowedPaths = "allowed_paths"
    case checkers
    case baseCommitOID = "base_commit_oid"
    case expectedTreeOID = "expected_tree_oid"
    case expectedCandidateOID = "expected_candidate_oid"
    case candidateBranch = "candidate_branch"
    case resultRef = "result_ref"
    case author
    case committer
    case message
    case producerIDs = "producer_ids"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    allowedPaths = try container.decode([String].self, forKey: .allowedPaths)
    checkers = try container.decode([LiveGitCandidateCheckerSpec].self, forKey: .checkers)
    baseCommitOID = try container.decode(String.self, forKey: .baseCommitOID)
    expectedTreeOID = try container.decode(String.self, forKey: .expectedTreeOID)
    expectedCandidateOID = try container.decode(String.self, forKey: .expectedCandidateOID)
    candidateBranch = try container.decode(String.self, forKey: .candidateBranch)
    resultRef = try container.decode(String.self, forKey: .resultRef)
    author = try container.decode(LiveGitCandidateSignature.self, forKey: .author)
    committer = try container.decode(LiveGitCandidateSignature.self, forKey: .committer)
    message = try container.decode(String.self, forKey: .message)
    producerIDs = try container.decode(LiveGitCandidateProducerIDs.self, forKey: .producerIDs)
  }

  private static func isSafeRelativePath(_ value: String) -> Bool {
    guard !value.isEmpty, value.utf8.count <= 4_096,
      value == value.precomposedStringWithCanonicalMapping,
      !value.hasPrefix("/"), !value.contains("\0"), !value.contains("\\"),
      !value.contains("\n"), !value.contains("\r")
    else { return false }
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    guard !components.isEmpty,
      components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
    else { return false }
    return components.allSatisfy { $0.lowercased() != ".git" }
  }

  private static func isGitOID(_ value: String) -> Bool {
    (value.count == 40 || value.count == 64)
      && value.allSatisfy { "0123456789abcdef".contains($0) }
  }

  private static func isValidRef(_ value: String, prefix: String) -> Bool {
    guard value.hasPrefix(prefix), value.utf8.count <= 255,
      !value.hasSuffix("/"), !value.hasSuffix("."),
      !value.contains(".."), !value.contains("@{"), !value.contains("//"),
      !value.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7f })
    else { return false }
    let forbidden = CharacterSet(charactersIn: " ~^:?*[\\")
    guard value.unicodeScalars.allSatisfy({ !forbidden.contains($0) }) else {
      return false
    }
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    return components.allSatisfy {
      !$0.isEmpty && !$0.hasPrefix(".") && !$0.hasSuffix(".lock")
    }
  }

  static func isTechnicalIdentifier(_ value: String) -> Bool {
    let scalars = value.unicodeScalars
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let firstAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    return !scalars.isEmpty && scalars.count <= 128
      && scalars.first.map(firstAllowed.contains) == true
      && scalars.allSatisfy(allowed.contains)
  }

  static func isSHA256(_ value: String) -> Bool {
    value.hasPrefix("sha256:") && value.count == 71
      && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
  }

  private static func validate(
    signature: LiveGitCandidateSignature,
    field: String
  ) throws {
    let invalidScalars = CharacterSet(charactersIn: "\0\r\n<>")
    guard !signature.name.isEmpty, signature.name.utf8.count <= 256,
      signature.name.unicodeScalars.allSatisfy({ !invalidScalars.contains($0) }),
      !signature.email.isEmpty, signature.email.utf8.count <= 320,
      signature.email.contains("@"),
      signature.email.unicodeScalars.allSatisfy({ !invalidScalars.contains($0) }),
      signature.timestampSeconds >= 0,
      ((-14 * 60)...(14 * 60)).contains(signature.timeZoneOffsetMinutes)
    else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "\(field) не задаёт детерминированную Git-подпись."
      )
    }
  }
}

extension LiveAllowedAction {
  public func validateCandidateCommitPolicy() throws {
    if let candidateCommitPolicy {
      guard operation == LiveGitCandidateContract.operation else {
        throw LiveGitCandidateContractError.invalidPolicy(
          "candidate_commit_policy допустим только для create_candidate_commit."
        )
      }
      try candidateCommitPolicy.validate()
      return
    }
    guard operation != LiveGitCandidateContract.operation else {
      throw LiveGitCandidateContractError.invalidPolicy(
        "create_candidate_commit требует candidate_commit_policy."
      )
    }
  }
}

public struct LiveGitCandidateReceiptLink: Codable, Equatable, Sendable {
  public let receiptID: String
  public let receiptSHA256: String

  public init(receiptID: String, receiptSHA256: String) {
    self.receiptID = receiptID
    self.receiptSHA256 = receiptSHA256
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case receiptID = "receipt_id"
    case receiptSHA256 = "receipt_sha256"
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    receiptID = try container.decode(String.self, forKey: .receiptID)
    receiptSHA256 = try container.decode(String.self, forKey: .receiptSHA256)
  }
}

public struct LiveGitCandidateStageReceipt: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let receiptID: String
  public let eventID: String
  public let stage: LiveGitCandidateStage
  public let coordinates: LiveTransitionCoordinates
  public let evidence: LiveEvidenceObject
  public let producerID: String
  public let predecessor: LiveGitCandidateReceiptLink?

  public init(
    schemaIdentity: String = LiveGitCandidateContract.receiptIdentity,
    schemaVersion: Int = LiveGitCandidateContract.version,
    receiptID: String,
    eventID: String,
    stage: LiveGitCandidateStage,
    coordinates: LiveTransitionCoordinates,
    evidence: LiveEvidenceObject,
    producerID: String,
    predecessor: LiveGitCandidateReceiptLink?
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.receiptID = receiptID
    self.eventID = eventID
    self.stage = stage
    self.coordinates = coordinates
    self.evidence = evidence
    self.producerID = producerID
    self.predecessor = predecessor
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case receiptID = "receipt_id"
    case eventID = "event_id"
    case stage
    case coordinates
    case evidence
    case producerID = "producer_id"
    case predecessor
  }

  public init(from decoder: Decoder) throws {
    try liveRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    receiptID = try container.decode(String.self, forKey: .receiptID)
    eventID = try container.decode(String.self, forKey: .eventID)
    stage = try container.decode(LiveGitCandidateStage.self, forKey: .stage)
    coordinates = try container.decode(LiveTransitionCoordinates.self, forKey: .coordinates)
    evidence = try container.decode(LiveEvidenceObject.self, forKey: .evidence)
    producerID = try container.decode(String.self, forKey: .producerID)
    predecessor = try container.decodeIfPresent(
      LiveGitCandidateReceiptLink.self,
      forKey: .predecessor
    )
  }
}

public enum LiveGitCandidateReceiptChain {
  public static func validate(
    _ receipts: [LiveGitCandidateStageReceipt],
    policy: LiveGitCandidateCommitPolicy,
    expectedCoordinates: LiveTransitionCoordinates,
    candidateOwnedEvents: [LiveEpisodeEvent]? = nil
  ) throws {
    try validatePrefix(
      receipts,
      through: .observed,
      policy: policy,
      expectedCoordinates: expectedCoordinates,
      candidateOwnedEvents: candidateOwnedEvents
    )
  }

  public static func validatePrefix(
    _ receipts: [LiveGitCandidateStageReceipt],
    through expectedLastStage: LiveGitCandidateStage,
    policy: LiveGitCandidateCommitPolicy,
    expectedCoordinates: LiveTransitionCoordinates,
    candidateOwnedEvents: [LiveEpisodeEvent]? = nil
  ) throws {
    try policy.validate()
    try validate(coordinates: expectedCoordinates)
    guard
      let lastIndex = LiveGitCandidateStage.allCases.firstIndex(of: expectedLastStage),
      receipts.count == lastIndex + 1
    else {
      throw LiveGitCandidateContractError.invalidReceipt(
        "Candidate receipt prefix не заканчивается на заявленной стадии."
      )
    }

    var receiptIDs = Set<String>()
    var eventIDs = Set<String>()
    var evidenceIDs = Set<String>()
    var producerIDs = Set<String>()
    for (index, receipt) in receipts.enumerated() {
      try validate(receipt: receipt)
      let expectedStage = LiveGitCandidateStage.allCases[index]
      guard receipt.stage == expectedStage else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Candidate receipt stages нарушают закрытый порядок."
        )
      }
      guard receipt.coordinates == expectedCoordinates else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Candidate receipt использует другие transition coordinates."
        )
      }
      guard receipt.producerID == policy.producerIDs.producerID(for: receipt.stage) else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Candidate receipt создан незарегистрированным producer_id."
        )
      }
      guard receiptIDs.insert(receipt.receiptID).inserted,
        eventIDs.insert(receipt.eventID).inserted,
        evidenceIDs.insert(receipt.evidence.evidenceID).inserted,
        producerIDs.insert(receipt.producerID).inserted
      else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Receipt, event, evidence и producer identities пяти стадий должны быть уникальны."
        )
      }
      if index == 0 {
        guard receipt.predecessor == nil else {
          throw LiveGitCandidateContractError.invalidReceipt(
            "transition_user_confirmed не принимает predecessor receipt."
          )
        }
      } else {
        let previous = receipts[index - 1]
        let expected = LiveGitCandidateReceiptLink(
          receiptID: previous.receiptID,
          receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256(previous)
        )
        guard receipt.predecessor == expected else {
          throw LiveGitCandidateContractError.invalidReceipt(
            "Candidate receipt не связан с точными id и SHA-256 предыдущей стадии."
          )
        }
      }
    }

    if let candidateOwnedEvents {
      try validateEventBindings(receipts: receipts, events: candidateOwnedEvents)
    }
  }

  private static func validate(receipt: LiveGitCandidateStageReceipt) throws {
    guard receipt.schemaIdentity == LiveGitCandidateContract.receiptIdentity,
      receipt.schemaVersion == LiveGitCandidateContract.version
    else {
      throw LiveGitCandidateContractError.unsupportedReceiptSchema(
        identity: receipt.schemaIdentity,
        version: receipt.schemaVersion
      )
    }
    guard LiveGitCandidateCommitPolicy.isTechnicalIdentifier(receipt.receiptID),
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(receipt.eventID),
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(receipt.producerID),
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(receipt.evidence.evidenceID),
      LiveGitCandidateCommitPolicy.isSHA256(receipt.evidence.evidenceSHA256)
    else {
      throw LiveGitCandidateContractError.invalidReceipt(
        "Candidate receipt содержит нетехническую identity или неверный evidence SHA-256."
      )
    }
    if let predecessor = receipt.predecessor {
      guard LiveGitCandidateCommitPolicy.isTechnicalIdentifier(predecessor.receiptID),
        LiveGitCandidateCommitPolicy.isSHA256(predecessor.receiptSHA256)
      else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Predecessor receipt link содержит неверные id или SHA-256."
        )
      }
    }
    try validate(coordinates: receipt.coordinates)
  }

  private static func validate(coordinates: LiveTransitionCoordinates) throws {
    guard coordinates.schemaVersion == LiveEpisodeSchema.version,
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(coordinates.episodeID),
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(coordinates.transitionID),
      LiveGitCandidateCommitPolicy.isTechnicalIdentifier(coordinates.objectID),
      LiveGitCandidateCommitPolicy.isSHA256(coordinates.expectedEffectSHA256)
    else {
      throw LiveGitCandidateContractError.invalidReceipt(
        "Candidate receipt coordinates не соответствуют live-схеме."
      )
    }
  }

  private static func validateEventBindings(
    receipts: [LiveGitCandidateStageReceipt],
    events: [LiveEpisodeEvent]
  ) throws {
    guard events.count == receipts.count,
      Set(events.map(\.eventID)).count == events.count,
      events.map(\.eventID) == receipts.map(\.eventID),
      zip(events, events.dropFirst()).allSatisfy({
        $0.0.sequence < $0.1.sequence
      })
    else {
      throw LiveGitCandidateContractError.invalidReceipt(
        "Candidate-owned events требуют ровно одну receipt и точный порядок стадий."
      )
    }
    let eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.eventID, $0) })
    for receipt in receipts {
      guard let event = eventsByID[receipt.eventID],
        event.episodeID == receipt.coordinates.episodeID,
        event.schemaIdentity == LiveEpisodeSchema.identity,
        event.schemaVersion == LiveEpisodeSchema.version,
        binding(of: event)
          == EventBinding(
            stage: receipt.stage,
            coordinates: receipt.coordinates,
            evidence: receipt.evidence
          )
      else {
        throw LiveGitCandidateContractError.invalidReceipt(
          "Stage receipt не имеет точного двунаправленного event binding."
        )
      }
    }
  }

  private struct EventBinding: Equatable {
    let stage: LiveGitCandidateStage
    let coordinates: LiveTransitionCoordinates
    let evidence: LiveEvidenceObject
  }

  private static func binding(of event: LiveEpisodeEvent) -> EventBinding? {
    switch event.payload {
    case .transitionUserConfirmed(let value):
      return EventBinding(
        stage: .transitionUserConfirmed,
        coordinates: value.coordinates,
        evidence: value.evidence
      )
    case .authorizationDecided(let value) where value.decision == .allowed:
      return EventBinding(
        stage: .authorized,
        coordinates: value.coordinates,
        evidence: value.evidence
      )
    case .preflightCompleted(let value) where value.status == .passed:
      return EventBinding(
        stage: .preflightPassed,
        coordinates: value.coordinates,
        evidence: value.evidence
      )
    case .executionRecorded(let value) where value.status == .succeeded:
      return EventBinding(
        stage: .executed,
        coordinates: value.coordinates,
        evidence: value.evidence
      )
    case .observationRecorded(let value) where value.status == .observed:
      return EventBinding(
        stage: .observed,
        coordinates: value.coordinates,
        evidence: value.evidence
      )
    default:
      return nil
    }
  }
}
