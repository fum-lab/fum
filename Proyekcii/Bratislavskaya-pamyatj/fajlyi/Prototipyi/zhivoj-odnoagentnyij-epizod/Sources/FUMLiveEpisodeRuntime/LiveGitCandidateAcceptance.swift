import Darwin
import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public enum LiveGitCandidateAcceptanceSchema {
  public static let identity = "fum.live_git_candidate.acceptance"
  public static let version = 1
  public static let maximumCommandBytes = 65_536
}

private struct LiveGitCandidateAcceptanceCurrentPointer: Codable {
  let schemaVersion: Int
  let canonicalProfile: String
  let generationSHA256: String

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case generationSHA256 = "generation_sha256"
  }

  init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    canonicalProfile = try container.decode(String.self, forKey: .canonicalProfile)
    generationSHA256 = try container.decode(String.self, forKey: .generationSHA256)
  }
}

private struct LiveGitCandidateAcceptanceCloneOwner: Codable {
  static let fileName = "fum-runtime-owner.json"

  let schemaIdentity: String
  let schemaVersion: Int
  let sourceGitDirectory: String
  let baseOID: String
  let objectFormat: String

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case sourceGitDirectory = "source_git_directory"
    case baseOID = "base_oid"
    case objectFormat = "object_format"
  }

  init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    sourceGitDirectory = try container.decode(String.self, forKey: .sourceGitDirectory)
    baseOID = try container.decode(String.self, forKey: .baseOID)
    objectFormat = try container.decode(String.self, forKey: .objectFormat)
  }
}

private struct LiveGitCandidateAcceptanceFileIdentity: Hashable {
  let device: UInt64
  let inode: UInt64

  init(_ information: stat) {
    device = UInt64(information.st_dev)
    inode = UInt64(information.st_ino)
  }
}

public enum LiveGitCandidateAcceptanceError: Error, Equatable, Sendable {
  case unsupportedCommandSchema(expected: Int, actual: Int)
  case invalidCommand(String)
  case noConfirmedCurrent
  case rejected(String)
  case receiptConflict
  case storage(String)
}

extension LiveGitCandidateAcceptanceError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unsupportedCommandSchema(let expected, let actual):
      return "Ожидалась версия acceptance-команды \(expected), получена \(actual)."
    case .invalidCommand(let message), .rejected(let message), .storage(let message):
      return message
    case .noConfirmedCurrent:
      return "Подтверждённый CURRENT эпизода не найден."
    case .receiptConflict:
      return "Acceptance-receipt для кандидата уже содержит другие байты."
    }
  }
}

public struct LiveGitCandidateAcceptanceCommand: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let candidateOID: String

  public init(
    schemaVersion: Int = LiveGitCandidateAcceptanceSchema.version,
    commandID: String,
    candidateOID: String
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.candidateOID = candidateOID
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case candidateOID = "candidate_oid"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    commandID = try container.decode(String.self, forKey: .commandID)
    candidateOID = try container.decode(String.self, forKey: .candidateOID)
  }

  public func validate() throws {
    guard schemaVersion == LiveGitCandidateAcceptanceSchema.version else {
      throw LiveGitCandidateAcceptanceError.unsupportedCommandSchema(
        expected: LiveGitCandidateAcceptanceSchema.version,
        actual: schemaVersion
      )
    }
    guard Self.isIdentifier(commandID) else {
      throw LiveGitCandidateAcceptanceError.invalidCommand(
        "command_id acceptance-команды не соответствует закрытой грамматике."
      )
    }
    guard Self.isExactOID(candidateOID) else {
      throw LiveGitCandidateAcceptanceError.invalidCommand(
        "candidate_oid должен быть полным строчным Git OID."
      )
    }
  }

  private static func isIdentifier(_ value: String) -> Bool {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let first = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    return !value.isEmpty && value.unicodeScalars.count <= 128
      && value.unicodeScalars.first.map(first.contains) == true
      && value.unicodeScalars.allSatisfy(allowed.contains)
  }

  static func isExactOID(_ value: String) -> Bool {
    (value.count == 40 || value.count == 64)
      && value.allSatisfy { "0123456789abcdef".contains($0) }
  }

}

public enum LiveGitCandidateAcceptanceVerdict: String, Codable, Equatable, Sendable {
  case accepted
  case rejected
}

public enum LiveGitCandidateAcceptanceCheckerStatus: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct LiveGitCandidateAcceptanceCheckerObservation:
  Codable, Equatable, Sendable
{
  public let checkerID: String
  public let status: LiveGitCandidateAcceptanceCheckerStatus
  public let observationSHA256: String

  public init(
    checkerID: String,
    status: LiveGitCandidateAcceptanceCheckerStatus,
    observationSHA256: String
  ) {
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
    status = try container.decode(LiveGitCandidateAcceptanceCheckerStatus.self, forKey: .status)
    observationSHA256 = try container.decode(String.self, forKey: .observationSHA256)
  }
}

public struct LiveGitCandidateAcceptanceObservation: Codable, Equatable, Sendable {
  public let parentOID: String
  public let treeOID: String
  public let rawCommitSHA256: String
  public let nulDiffSHA256: String
  public let changedPaths: [String]
  public let checkers: [LiveGitCandidateAcceptanceCheckerObservation]

  public init(
    parentOID: String,
    treeOID: String,
    rawCommitSHA256: String,
    nulDiffSHA256: String,
    changedPaths: [String],
    checkers: [LiveGitCandidateAcceptanceCheckerObservation]
  ) {
    self.parentOID = parentOID
    self.treeOID = treeOID
    self.rawCommitSHA256 = rawCommitSHA256
    self.nulDiffSHA256 = nulDiffSHA256
    self.changedPaths = changedPaths
    self.checkers = checkers
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case parentOID = "parent_oid"
    case treeOID = "tree_oid"
    case rawCommitSHA256 = "raw_commit_sha256"
    case nulDiffSHA256 = "nul_diff_sha256"
    case changedPaths = "changed_paths"
    case checkers
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    parentOID = try container.decode(String.self, forKey: .parentOID)
    treeOID = try container.decode(String.self, forKey: .treeOID)
    rawCommitSHA256 = try container.decode(String.self, forKey: .rawCommitSHA256)
    nulDiffSHA256 = try container.decode(String.self, forKey: .nulDiffSHA256)
    changedPaths = try container.decode([String].self, forKey: .changedPaths)
    checkers = try container.decode(
      [LiveGitCandidateAcceptanceCheckerObservation].self,
      forKey: .checkers
    )
  }
}

public struct LiveGitCandidateAcceptanceReceipt: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let verdict: LiveGitCandidateAcceptanceVerdict
  public let currentGenerationSHA256: String
  public let admissionSHA256: String
  public let passportSHA256: String
  public let candidateOID: String
  public let observation: LiveGitCandidateAcceptanceObservation?
  public let rejectionCodes: [String]

  public init(
    schemaIdentity: String = LiveGitCandidateAcceptanceSchema.identity,
    schemaVersion: Int = LiveGitCandidateAcceptanceSchema.version,
    verdict: LiveGitCandidateAcceptanceVerdict,
    currentGenerationSHA256: String,
    admissionSHA256: String,
    passportSHA256: String,
    candidateOID: String,
    observation: LiveGitCandidateAcceptanceObservation?,
    rejectionCodes: [String]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.verdict = verdict
    self.currentGenerationSHA256 = currentGenerationSHA256
    self.admissionSHA256 = admissionSHA256
    self.passportSHA256 = passportSHA256
    self.candidateOID = candidateOID
    self.observation = observation
    self.rejectionCodes = rejectionCodes
  }

  enum CodingKeys: String, CodingKey, CaseIterable {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case verdict
    case currentGenerationSHA256 = "current_generation_sha256"
    case admissionSHA256 = "admission_sha256"
    case passportSHA256 = "passport_sha256"
    case candidateOID = "candidate_oid"
    case observation
    case rejectionCodes = "rejection_codes"
  }

  public init(from decoder: Decoder) throws {
    try liveRuntimeRejectUnknownKeys(decoder, allowed: CodingKeys.self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaIdentity = try container.decode(String.self, forKey: .schemaIdentity)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    verdict = try container.decode(LiveGitCandidateAcceptanceVerdict.self, forKey: .verdict)
    currentGenerationSHA256 = try container.decode(String.self, forKey: .currentGenerationSHA256)
    admissionSHA256 = try container.decode(String.self, forKey: .admissionSHA256)
    passportSHA256 = try container.decode(String.self, forKey: .passportSHA256)
    candidateOID = try container.decode(String.self, forKey: .candidateOID)
    observation = try container.decodeIfPresent(
      LiveGitCandidateAcceptanceObservation.self,
      forKey: .observation
    )
    rejectionCodes = try container.decode([String].self, forKey: .rejectionCodes)
  }

  public func validate() throws {
    guard schemaIdentity == LiveGitCandidateAcceptanceSchema.identity,
      schemaVersion == LiveGitCandidateAcceptanceSchema.version,
      Self.isSHA256(currentGenerationSHA256),
      Self.isSHA256(admissionSHA256),
      Self.isSHA256(passportSHA256),
      LiveGitCandidateAcceptanceCommand.isExactOID(candidateOID),
      rejectionCodes == Array(Set(rejectionCodes)).sorted(),
      rejectionCodes.allSatisfy(Self.isIdentifier)
    else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Acceptance-receipt не соответствует канонической схеме."
      )
    }
    switch verdict {
    case .accepted:
      guard rejectionCodes.isEmpty, let observation,
        observation.checkers.allSatisfy({ $0.status == .passed })
      else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Принятый receipt требует полные успешные наблюдения."
        )
      }
      try Self.validate(observation, candidateOID: candidateOID)
    case .rejected:
      guard !rejectionCodes.isEmpty else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Отклонённый receipt требует типизированную причину."
        )
      }
      if let observation { try Self.validate(observation, candidateOID: candidateOID) }
    }
  }

  private static func validate(
    _ observation: LiveGitCandidateAcceptanceObservation,
    candidateOID: String
  ) throws {
    guard LiveGitCandidateAcceptanceCommand.isExactOID(observation.parentOID),
      LiveGitCandidateAcceptanceCommand.isExactOID(observation.treeOID),
      Set([candidateOID, observation.parentOID, observation.treeOID].map(\.count)).count == 1,
      isSHA256(observation.rawCommitSHA256),
      isSHA256(observation.nulDiffSHA256),
      !observation.changedPaths.isEmpty,
      observation.changedPaths == Array(Set(observation.changedPaths)).sorted(),
      observation.changedPaths.allSatisfy(isSafeRelativePath),
      !observation.checkers.isEmpty,
      observation.checkers.map(\.checkerID)
        == Array(Set(observation.checkers.map(\.checkerID))).sorted(),
      observation.checkers.allSatisfy({
        isIdentifier($0.checkerID) && isSHA256($0.observationSHA256)
      })
    else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Наблюдение acceptance-receipt неканонично."
      )
    }
  }

  private static func isSHA256(_ value: String) -> Bool {
    value.hasPrefix("sha256:") && value.count == 71
      && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
  }

  private static func isIdentifier(_ value: String) -> Bool {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let first = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    return !value.isEmpty && value.unicodeScalars.count <= 128
      && value.unicodeScalars.first.map(first.contains) == true
      && value.unicodeScalars.allSatisfy(allowed.contains)
  }

  private static func isSafeRelativePath(_ value: String) -> Bool {
    guard !value.isEmpty, value.utf8.count <= 4_096,
      value == value.precomposedStringWithCanonicalMapping,
      !value.hasPrefix("/"), !value.contains("\0"), !value.contains("\\"),
      !value.contains("\n"), !value.contains("\r")
    else { return false }
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    return !components.isEmpty
      && components.allSatisfy({
        !$0.isEmpty && $0 != "." && $0 != ".." && $0.lowercased() != ".git"
      })
  }
}

public struct StoredLiveGitCandidateAcceptanceReceipt: Equatable, Sendable {
  public let receiptSHA256: String
  public let receipt: LiveGitCandidateAcceptanceReceipt

  public init(receiptSHA256: String, receipt: LiveGitCandidateAcceptanceReceipt) {
    self.receiptSHA256 = receiptSHA256
    self.receipt = receipt
  }
}

public struct LiveGitCandidateAcceptanceReceiptStore {
  public let episodeDirectoryURL: URL

  public init(episodeDirectoryURL: URL) {
    self.episodeDirectoryURL = episodeDirectoryURL
  }

  public func publish(
    _ receipt: LiveGitCandidateAcceptanceReceipt
  ) throws -> StoredLiveGitCandidateAcceptanceReceipt {
    try receipt.validate()
    let data = try LiveEpisodeRuntimeJSON.encode(receipt)
    let receiptSHA256 = CanonicalMemoryJSON.sha256(data)
    let rootDescriptor = open(
      episodeDirectoryURL.path,
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW
    )
    guard rootDescriptor >= 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось открыть каталог эпизода для acceptance-receipt."
      )
    }
    defer { _ = close(rootDescriptor) }
    let directoryName = "git-candidate-acceptance"
    if mkdirat(rootDescriptor, directoryName, 0o700) != 0, errno != EEXIST {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось подготовить каталог acceptance-receipts."
      )
    }
    let directoryDescriptor = openat(
      rootDescriptor,
      directoryName,
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW
    )
    guard directoryDescriptor >= 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Каталог acceptance-receipts не является обычным каталогом."
      )
    }
    defer { _ = close(directoryDescriptor) }

    let destinationName = "\(receipt.candidateOID).json"
    let temporaryName = ".receipt-\(UUID().uuidString)"
    try writeNewFile(data, named: temporaryName, in: directoryDescriptor)
    var temporaryExists = true
    defer {
      if temporaryExists { _ = unlinkat(directoryDescriptor, temporaryName, 0) }
    }
    if renameatx_np(
      directoryDescriptor,
      temporaryName,
      directoryDescriptor,
      destinationName,
      UInt32(RENAME_EXCL)
    ) != 0 {
      let code = errno
      guard code == EEXIST else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Не удалось атомарно опубликовать acceptance-receipt."
        )
      }
      let existing = try readBounded(
        named: destinationName,
        in: directoryDescriptor,
        limit: 1_048_576
      )
      guard existing == data else {
        throw LiveGitCandidateAcceptanceError.receiptConflict
      }
      guard unlinkat(directoryDescriptor, temporaryName, 0) == 0 else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Не удалось удалить временный acceptance-receipt."
        )
      }
    }
    temporaryExists = false
    try synchronizeDirectory(directoryDescriptor)
    return StoredLiveGitCandidateAcceptanceReceipt(
      receiptSHA256: receiptSHA256,
      receipt: receipt
    )
  }

  private func writeNewFile(
    _ data: Data,
    named name: String,
    in directoryDescriptor: Int32
  ) throws {
    let descriptor = openat(
      directoryDescriptor,
      name,
      O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW,
      0o600
    )
    guard descriptor >= 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось создать временный acceptance-receipt."
      )
    }
    var closeNeeded = true
    var completed = false
    defer {
      if closeNeeded { _ = close(descriptor) }
      if !completed { _ = unlinkat(directoryDescriptor, name, 0) }
    }
    try data.withUnsafeBytes { buffer in
      guard let baseAddress = buffer.baseAddress else { return }
      var offset = 0
      while offset < buffer.count {
        let count = Darwin.write(
          descriptor,
          baseAddress.advanced(by: offset),
          buffer.count - offset
        )
        if count < 0, errno == EINTR { continue }
        guard count > 0 else {
          throw LiveGitCandidateAcceptanceError.storage(
            "Не удалось полностью записать acceptance-receipt."
          )
        }
        offset += count
      }
    }
    guard fsync(descriptor) == 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось синхронизировать acceptance-receipt."
      )
    }
    guard close(descriptor) == 0 else {
      closeNeeded = false
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось закрыть acceptance-receipt."
      )
    }
    closeNeeded = false
    completed = true
  }

  private func readBounded(
    named name: String,
    in directoryDescriptor: Int32,
    limit: Int
  ) throws -> Data {
    let descriptor = openat(
      directoryDescriptor,
      name,
      O_RDONLY | O_NOFOLLOW | O_NONBLOCK
    )
    guard descriptor >= 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось прочитать существующий acceptance-receipt."
      )
    }
    defer { _ = close(descriptor) }
    var metadata = stat()
    guard fstat(descriptor, &metadata) == 0,
      (metadata.st_mode & S_IFMT) == S_IFREG,
      metadata.st_nlink == 1,
      metadata.st_size >= 0,
      metadata.st_size <= limit
    else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Существующий acceptance-receipt не является ограниченным обычным файлом."
      )
    }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 8_192)
    while true {
      let count = Darwin.read(descriptor, &buffer, buffer.count)
      if count < 0, errno == EINTR { continue }
      guard count >= 0 else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Ошибка чтения acceptance-receipt."
        )
      }
      if count == 0 { break }
      data.append(contentsOf: buffer.prefix(count))
      guard data.count <= limit else {
        throw LiveGitCandidateAcceptanceError.storage(
          "Acceptance-receipt превышает лимит байтов."
        )
      }
    }
    var finalMetadata = stat()
    guard fstat(descriptor, &finalMetadata) == 0,
      data.count == Int(metadata.st_size),
      sameImmutableFile(metadata, finalMetadata)
    else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Существующий acceptance-receipt изменился во время чтения."
      )
    }
    return data
  }

  private func sameImmutableFile(_ first: stat, _ second: stat) -> Bool {
    first.st_dev == second.st_dev
      && first.st_ino == second.st_ino
      && first.st_mode == second.st_mode
      && first.st_nlink == second.st_nlink
      && first.st_size == second.st_size
      && first.st_mtimespec.tv_sec == second.st_mtimespec.tv_sec
      && first.st_mtimespec.tv_nsec == second.st_mtimespec.tv_nsec
      && first.st_ctimespec.tv_sec == second.st_ctimespec.tv_sec
      && first.st_ctimespec.tv_nsec == second.st_ctimespec.tv_nsec
  }

  private func synchronizeDirectory(_ descriptor: Int32) throws {
    guard fsync(descriptor) == 0 else {
      throw LiveGitCandidateAcceptanceError.storage(
        "Не удалось синхронизировать каталог acceptance-receipts."
      )
    }
  }
}

private struct LiveGitCandidateAcceptanceGenerationLoader {
  private static let maximumPointerBytes = 4_096

  let episodeDescriptor: Int32

  func loadCurrent() throws -> StoredLiveEpisodeGeneration? {
    guard
      let pointerData = try readImmutableFile(
        named: "CURRENT.json",
        in: episodeDescriptor,
        maximumBytes: Self.maximumPointerBytes,
        missingIsNil: true,
        failureCode: "current_pointer_invalid"
      )
    else {
      return nil
    }
    let pointer = try decodePointer(pointerData)
    let generationsDescriptor = openat(
      episodeDescriptor,
      "generations",
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard generationsDescriptor >= 0 else {
      throw LiveGitCandidateEvaluationFailure("current_generation_directory_invalid")
    }
    defer { _ = close(generationsDescriptor) }
    let generationName = "\(pointer.generationSHA256.dropFirst(7)).json"
    guard
      let generationData = try readImmutableFile(
        named: generationName,
        in: generationsDescriptor,
        maximumBytes: LiveEpisodeRuntimeSchema.maximumGenerationBytes,
        missingIsNil: false,
        failureCode: "current_generation_invalid"
      ),
      CanonicalMemoryJSON.sha256(generationData) == pointer.generationSHA256
    else {
      throw LiveGitCandidateEvaluationFailure("current_generation_digest_mismatch")
    }
    return try validateDomainGeneration(
      pointerData: pointerData,
      generationData: generationData,
      generationSHA256: pointer.generationSHA256
    )
  }

  private func decodePointer(
    _ data: Data
  ) throws -> LiveGitCandidateAcceptanceCurrentPointer {
    do {
      try CanonicalMemoryJSON.requireCanonical(data)
      let pointer = try JSONDecoder().decode(
        LiveGitCandidateAcceptanceCurrentPointer.self,
        from: data
      )
      guard try CanonicalMemoryJSON.encode(pointer) == data,
        pointer.schemaVersion == 2,
        pointer.canonicalProfile == CanonicalMemoryJSON.profileID,
        isSHA256(pointer.generationSHA256)
      else {
        throw LiveGitCandidateEvaluationFailure("current_pointer_invalid")
      }
      return pointer
    } catch let failure as LiveGitCandidateEvaluationFailure {
      throw failure
    } catch {
      throw LiveGitCandidateEvaluationFailure("current_pointer_invalid")
    }
  }

  private func readImmutableFile(
    named name: String,
    in directoryDescriptor: Int32,
    maximumBytes: Int,
    missingIsNil: Bool,
    failureCode: String
  ) throws -> Data? {
    let descriptor = openat(
      directoryDescriptor,
      name,
      O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC
    )
    if descriptor < 0, missingIsNil, errno == ENOENT { return nil }
    guard descriptor >= 0 else {
      throw LiveGitCandidateEvaluationFailure(failureCode)
    }
    defer { _ = close(descriptor) }

    var initial = stat()
    guard fstat(descriptor, &initial) == 0,
      (initial.st_mode & S_IFMT) == S_IFREG,
      initial.st_nlink == 1,
      initial.st_size >= 0,
      initial.st_size <= off_t(maximumBytes)
    else {
      throw LiveGitCandidateEvaluationFailure(failureCode)
    }
    var data = Data()
    data.reserveCapacity(Int(initial.st_size))
    var buffer = [UInt8](repeating: 0, count: 8_192)
    while true {
      let count = buffer.withUnsafeMutableBytes { bytes in
        Darwin.read(descriptor, bytes.baseAddress, bytes.count)
      }
      if count < 0, errno == EINTR { continue }
      guard count >= 0 else {
        throw LiveGitCandidateEvaluationFailure(failureCode)
      }
      if count == 0 { break }
      data.append(contentsOf: buffer.prefix(count))
      guard data.count <= maximumBytes else {
        throw LiveGitCandidateEvaluationFailure(failureCode)
      }
    }
    var final = stat()
    guard fstat(descriptor, &final) == 0,
      data.count == Int(initial.st_size),
      sameImmutableFile(initial, final)
    else {
      throw LiveGitCandidateEvaluationFailure(failureCode)
    }
    return data
  }

  private func validateDomainGeneration(
    pointerData: Data,
    generationData: Data,
    generationSHA256: String
  ) throws -> StoredLiveEpisodeGeneration {
    let fileManager = FileManager.default
    let validationURL = fileManager.temporaryDirectory.appendingPathComponent(
      "fum-live-candidate-acceptance-validation-\(UUID().uuidString.lowercased())",
      isDirectory: true
    )
    do {
      try fileManager.createDirectory(
        at: validationURL,
        withIntermediateDirectories: false,
        attributes: [.posixPermissions: NSNumber(value: 0o700)]
      )
    } catch {
      throw LiveGitCandidateEvaluationFailure("current_validation_store_failed")
    }
    defer { try? fileManager.removeItem(at: validationURL) }
    do {
      let generationsURL = validationURL.appendingPathComponent(
        "generations",
        isDirectory: true
      )
      try fileManager.createDirectory(
        at: generationsURL,
        withIntermediateDirectories: false,
        attributes: [.posixPermissions: NSNumber(value: 0o700)]
      )
      try pointerData.write(
        to: validationURL.appendingPathComponent("CURRENT.json", isDirectory: false),
        options: .withoutOverwriting
      )
      try generationData.write(
        to: generationsURL.appendingPathComponent(
          "\(generationSHA256.dropFirst(7)).json",
          isDirectory: false
        ),
        options: .withoutOverwriting
      )
      guard
        let stored = try LiveEpisodeGenerationStore(rootURL: validationURL).loadCurrent(),
        stored.generationSHA256 == generationSHA256
      else {
        throw LiveGitCandidateEvaluationFailure("current_generation_invalid")
      }
      return stored
    } catch let failure as LiveGitCandidateEvaluationFailure {
      throw failure
    } catch {
      throw LiveGitCandidateEvaluationFailure("current_generation_invalid")
    }
  }

  private func sameImmutableFile(_ first: stat, _ second: stat) -> Bool {
    first.st_dev == second.st_dev
      && first.st_ino == second.st_ino
      && first.st_mode == second.st_mode
      && first.st_nlink == second.st_nlink
      && first.st_size == second.st_size
      && first.st_mtimespec.tv_sec == second.st_mtimespec.tv_sec
      && first.st_mtimespec.tv_nsec == second.st_mtimespec.tv_nsec
      && first.st_ctimespec.tv_sec == second.st_ctimespec.tv_sec
      && first.st_ctimespec.tv_nsec == second.st_ctimespec.tv_nsec
  }

  private func isSHA256(_ value: String) -> Bool {
    value.hasPrefix("sha256:") && value.count == 71
      && value.dropFirst(7).allSatisfy { "0123456789abcdef".contains($0) }
  }
}

private struct LiveGitCandidateAcceptanceCloneMetadataValidator {
  let episodeDescriptor: Int32
  let passport: LiveGitCandidatePassport

  func validate() throws {
    let cloneDescriptor = try openPlainDirectory(
      at: episodeDescriptor,
      component: LiveGitCandidateRuntimeSchema.cloneRelativePath
    )
    defer { _ = close(cloneDescriptor) }
    let gitDescriptor = try openPlainDirectory(at: cloneDescriptor, component: ".git")
    defer { _ = close(gitDescriptor) }
    let objectsDescriptor = try openPlainDirectory(at: gitDescriptor, component: "objects")
    defer { _ = close(objectsDescriptor) }
    let refsDescriptor = try openPlainDirectory(at: gitDescriptor, component: "refs")
    defer { _ = close(refsDescriptor) }
    let infoDescriptor = try openPlainDirectory(at: objectsDescriptor, component: "info")
    defer { _ = close(infoDescriptor) }
    let packDescriptor = try openPlainDirectory(at: objectsDescriptor, component: "pack")
    defer { _ = close(packDescriptor) }

    let requiredDirectories = try [
      cloneDescriptor,
      gitDescriptor,
      objectsDescriptor,
      refsDescriptor,
      infoDescriptor,
      packDescriptor,
    ].map(directoryIdentity)
    guard Set(requiredDirectories).count == requiredDirectories.count else {
      throw invalidMetadata()
    }
    var cloneDirectoryIdentities: Set<LiveGitCandidateAcceptanceFileIdentity> = []
    var entryCount = 0
    try inspectPlainTree(
      directoryDescriptor: gitDescriptor,
      depth: 0,
      identities: &cloneDirectoryIdentities,
      entryCount: &entryCount
    )
    cloneDirectoryIdentities.formUnion(requiredDirectories)

    try requireMissingEntry(at: gitDescriptor, component: "commondir")
    try requireMissingEntry(at: gitDescriptor, component: "gitdir")
    try requireMissingEntry(at: infoDescriptor, component: "alternates")
    try requireMissingEntry(at: infoDescriptor, component: "http-alternates")
    _ = try readSafeRegularEntry(
      at: gitDescriptor,
      component: "HEAD",
      maximumBytes: 4_096,
      required: true
    )
    _ = try readSafeRegularEntry(
      at: gitDescriptor,
      component: "index",
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
      required: false
    )
    _ = try readSafeRegularEntry(
      at: gitDescriptor,
      component: "packed-refs",
      maximumBytes: LiveEpisodeRuntimeJSON.maximumCommandBytes,
      required: false
    )

    guard
      let markerData = try readSafeRegularEntry(
        at: gitDescriptor,
        component: LiveGitCandidateAcceptanceCloneOwner.fileName,
        maximumBytes: 16_384,
        required: true
      )
    else {
      throw invalidMetadata()
    }
    let marker = try decodeMarker(markerData)
    let objectFormat: String
    switch passport.candidateOID.count {
    case 40: objectFormat = "sha1"
    case 64: objectFormat = "sha256"
    default: throw invalidMetadata()
    }
    let sourceURL = URL(fileURLWithPath: marker.sourceGitDirectory, isDirectory: true)
    let resolvedSourceURL = sourceURL.standardizedFileURL.resolvingSymlinksInPath()
    guard marker.schemaIdentity == "fum.live_git_candidate.clone_owner",
      marker.schemaVersion == 1,
      marker.baseOID == passport.parentOID,
      marker.objectFormat == objectFormat,
      marker.sourceGitDirectory.hasPrefix("/"),
      marker.sourceGitDirectory == resolvedSourceURL.path
    else {
      throw invalidMetadata()
    }
    guard
      let configData = try readSafeRegularEntry(
        at: gitDescriptor,
        component: "config",
        maximumBytes: 1_048_576,
        required: true
      ),
      configData == canonicalCloneConfiguration(objectFormat: objectFormat)
    else {
      throw invalidMetadata()
    }
    let sourceIdentities = try sourceMetadataIdentities(sourceURL: resolvedSourceURL)
    guard sourceIdentities.isDisjoint(with: cloneDirectoryIdentities) else {
      throw invalidMetadata()
    }
  }

  private func decodeMarker(_ data: Data) throws -> LiveGitCandidateAcceptanceCloneOwner {
    do {
      try CanonicalMemoryJSON.requireCanonical(data)
      let marker = try JSONDecoder().decode(
        LiveGitCandidateAcceptanceCloneOwner.self,
        from: data
      )
      guard try CanonicalMemoryJSON.encode(marker) == data else {
        throw invalidMetadata()
      }
      return marker
    } catch let failure as LiveGitCandidateEvaluationFailure {
      throw failure
    } catch {
      throw invalidMetadata()
    }
  }

  private func openPlainDirectory(at parentDescriptor: Int32, component: String) throws -> Int32 {
    var before = stat()
    let inspected = component.withCString {
      fstatat(parentDescriptor, $0, &before, AT_SYMLINK_NOFOLLOW)
    }
    guard inspected == 0, isDirectory(before), !isSymbolicLink(before) else {
      throw invalidMetadata()
    }
    let descriptor = component.withCString {
      openat(parentDescriptor, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    }
    guard descriptor >= 0 else { throw invalidMetadata() }
    var after = stat()
    guard fstat(descriptor, &after) == 0,
      isDirectory(after),
      LiveGitCandidateAcceptanceFileIdentity(before)
        == LiveGitCandidateAcceptanceFileIdentity(after)
    else {
      _ = close(descriptor)
      throw invalidMetadata()
    }
    return descriptor
  }

  private func inspectPlainTree(
    directoryDescriptor: Int32,
    depth: Int,
    identities: inout Set<LiveGitCandidateAcceptanceFileIdentity>,
    entryCount: inout Int
  ) throws {
    guard depth <= 128 else { throw invalidMetadata() }
    let identity = try directoryIdentity(directoryDescriptor)
    guard identities.insert(identity).inserted else { throw invalidMetadata() }
    let duplicate = dup(directoryDescriptor)
    guard duplicate >= 0, let directory = fdopendir(duplicate) else {
      if duplicate >= 0 { _ = close(duplicate) }
      throw invalidMetadata()
    }
    defer { _ = closedir(directory) }
    errno = 0
    while let entry = readdir(directory) {
      let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
        pointer.withMemoryRebound(
          to: CChar.self,
          capacity: MemoryLayout.size(ofValue: entry.pointee.d_name)
        ) {
          String(validatingCString: $0)
        }
      }
      guard let name else { throw invalidMetadata() }
      if name == "." || name == ".." { continue }
      entryCount += 1
      guard entryCount <= 2_000_000,
        let information = try entryStatus(at: directoryDescriptor, component: name)
      else {
        throw invalidMetadata()
      }
      if isDirectory(information) {
        let childDescriptor = try openPlainDirectory(
          at: directoryDescriptor,
          component: name
        )
        do {
          try inspectPlainTree(
            directoryDescriptor: childDescriptor,
            depth: depth + 1,
            identities: &identities,
            entryCount: &entryCount
          )
          _ = close(childDescriptor)
        } catch {
          _ = close(childDescriptor)
          throw error
        }
      } else {
        guard isRegularFile(information), information.st_nlink == 1 else {
          throw invalidMetadata()
        }
      }
    }
    guard errno == 0 else { throw invalidMetadata() }
  }

  private func readSafeRegularEntry(
    at parentDescriptor: Int32,
    component: String,
    maximumBytes: Int,
    required: Bool
  ) throws -> Data? {
    guard let before = try entryStatus(at: parentDescriptor, component: component) else {
      if required { throw invalidMetadata() }
      return nil
    }
    guard isRegularFile(before), before.st_nlink == 1,
      before.st_size >= 0, before.st_size <= off_t(maximumBytes)
    else {
      throw invalidMetadata()
    }
    let descriptor = component.withCString {
      openat(parentDescriptor, $0, O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC)
    }
    guard descriptor >= 0 else { throw invalidMetadata() }
    defer { _ = close(descriptor) }
    var opened = stat()
    guard fstat(descriptor, &opened) == 0,
      sameFileVersion(before, opened)
    else {
      throw invalidMetadata()
    }
    var data = Data()
    data.reserveCapacity(Int(opened.st_size))
    var buffer = [UInt8](repeating: 0, count: 8_192)
    while true {
      let count = buffer.withUnsafeMutableBytes { bytes in
        read(descriptor, bytes.baseAddress, bytes.count)
      }
      if count < 0, errno == EINTR { continue }
      guard count >= 0 else { throw invalidMetadata() }
      if count == 0 { break }
      data.append(contentsOf: buffer.prefix(count))
      guard data.count <= maximumBytes else { throw invalidMetadata() }
    }
    var finished = stat()
    guard fstat(descriptor, &finished) == 0,
      data.count == Int(opened.st_size),
      sameFileVersion(opened, finished)
    else {
      throw invalidMetadata()
    }
    return data
  }

  private func sourceMetadataIdentities(
    sourceURL: URL
  ) throws -> Set<LiveGitCandidateAcceptanceFileIdentity> {
    let sourceDescriptor = sourceURL.withUnsafeFileSystemRepresentation { path -> Int32 in
      guard let path else { return -1 }
      return open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    }
    guard sourceDescriptor >= 0 else { throw invalidMetadata() }
    defer { _ = close(sourceDescriptor) }
    var identities: Set<LiveGitCandidateAcceptanceFileIdentity> = [
      try directoryIdentity(sourceDescriptor)
    ]
    let objectsDescriptor = try openSourceDirectory(
      at: sourceDescriptor,
      component: "objects"
    )
    if let objectsDescriptor {
      defer { _ = close(objectsDescriptor) }
      identities.insert(try directoryIdentity(objectsDescriptor))
      for component in ["info", "pack"] {
        if let descriptor = try openSourceDirectory(
          at: objectsDescriptor,
          component: component
        ) {
          identities.insert(try directoryIdentity(descriptor))
          _ = close(descriptor)
        }
      }
    }
    if let refsDescriptor = try openSourceDirectory(at: sourceDescriptor, component: "refs") {
      identities.insert(try directoryIdentity(refsDescriptor))
      _ = close(refsDescriptor)
    }
    return identities
  }

  private func openSourceDirectory(
    at parentDescriptor: Int32,
    component: String
  ) throws -> Int32? {
    let descriptor = component.withCString {
      openat(parentDescriptor, $0, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
    }
    if descriptor < 0, errno == ENOENT { return nil }
    guard descriptor >= 0 else { throw invalidMetadata() }
    return descriptor
  }

  private func directoryIdentity(
    _ descriptor: Int32
  ) throws -> LiveGitCandidateAcceptanceFileIdentity {
    var information = stat()
    guard fstat(descriptor, &information) == 0, isDirectory(information) else {
      throw invalidMetadata()
    }
    return LiveGitCandidateAcceptanceFileIdentity(information)
  }

  private func entryStatus(at parentDescriptor: Int32, component: String) throws -> stat? {
    var information = stat()
    let result = component.withCString {
      fstatat(parentDescriptor, $0, &information, AT_SYMLINK_NOFOLLOW)
    }
    if result == 0 { return information }
    if errno == ENOENT { return nil }
    throw invalidMetadata()
  }

  private func requireMissingEntry(at parentDescriptor: Int32, component: String) throws {
    guard try entryStatus(at: parentDescriptor, component: component) == nil else {
      throw invalidMetadata()
    }
  }

  private func sameFileVersion(_ first: stat, _ second: stat) -> Bool {
    LiveGitCandidateAcceptanceFileIdentity(first)
      == LiveGitCandidateAcceptanceFileIdentity(second)
      && first.st_mode == second.st_mode
      && first.st_nlink == second.st_nlink
      && first.st_size == second.st_size
      && first.st_mtimespec.tv_sec == second.st_mtimespec.tv_sec
      && first.st_mtimespec.tv_nsec == second.st_mtimespec.tv_nsec
      && first.st_ctimespec.tv_sec == second.st_ctimespec.tv_sec
      && first.st_ctimespec.tv_nsec == second.st_ctimespec.tv_nsec
  }

  private func canonicalCloneConfiguration(objectFormat: String) -> Data {
    let repositoryFormatVersion = objectFormat == "sha256" ? 1 : 0
    var text = """
      [core]
      \trepositoryformatversion = \(repositoryFormatVersion)
      \tfilemode = true
      \tbare = false
      \tlogallrefupdates = true

      """
    if objectFormat == "sha256" {
      text += """
        [extensions]
        \tobjectformat = sha256

        """
    }
    return Data(text.utf8)
  }

  private func isDirectory(_ information: stat) -> Bool {
    (information.st_mode & S_IFMT) == S_IFDIR
  }

  private func isRegularFile(_ information: stat) -> Bool {
    (information.st_mode & S_IFMT) == S_IFREG
  }

  private func isSymbolicLink(_ information: stat) -> Bool {
    (information.st_mode & S_IFMT) == S_IFLNK
  }

  private func invalidMetadata() -> LiveGitCandidateEvaluationFailure {
    LiveGitCandidateEvaluationFailure("candidate_git_metadata_invalid")
  }
}

public struct LiveGitCandidateAcceptanceRuntime: Sendable {
  public let episodeDirectoryURL: URL
  private let checkerRegistry: LiveGitCheckerRegistry

  public init(
    episodeDirectoryURL: URL,
    checkerRegistry: LiveGitCheckerRegistry = LiveGitCheckerRegistry()
  ) {
    self.episodeDirectoryURL = episodeDirectoryURL
    self.checkerRegistry = checkerRegistry
  }

  public func evaluate(
    _ command: LiveGitCandidateAcceptanceCommand
  ) throws -> LiveGitCandidateAcceptanceOutput {
    try command.validate()
    let episodeDescriptor = open(
      episodeDirectoryURL.path,
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard episodeDescriptor >= 0 else {
      throw LiveGitCandidateAcceptanceError.invalidCommand(
        "Каталог эпизода должен быть обычным каталогом без symlink."
      )
    }
    defer { _ = close(episodeDescriptor) }
    var episodeMetadata = stat()
    guard fstat(episodeDescriptor, &episodeMetadata) == 0,
      (episodeMetadata.st_mode & S_IFMT) == S_IFDIR
    else {
      throw LiveGitCandidateAcceptanceError.invalidCommand(
        "Каталог эпизода должен быть обычным каталогом без symlink."
      )
    }
    let generationLoader = LiveGitCandidateAcceptanceGenerationLoader(
      episodeDescriptor: episodeDescriptor
    )
    let loaded: StoredLiveEpisodeGeneration?
    do {
      loaded = try generationLoader.loadCurrent()
    } catch {
      throw LiveGitCandidateAcceptanceError.rejected(
        "Подтверждённый CURRENT не проходит независимую проверку."
      )
    }
    guard let current = loaded else {
      throw LiveGitCandidateAcceptanceError.noConfirmedCurrent
    }

    var admissionSHA256 = current.generation.passportSHA256
    var passportSHA256 = CanonicalMemoryJSON.sha256(Data())
    var passportCanonicalData: Data?
    var observation: LiveGitCandidateAcceptanceObservation?
    var rejectionCodes: [String] = []

    do {
      let action = try candidateAction(in: current)
      admissionSHA256 = CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(action))
      let passportData = try readCandidatePassport(
        episodeDescriptor: episodeDescriptor,
        candidateOID: command.candidateOID
      )
      passportCanonicalData = passportData
      passportSHA256 = CanonicalMemoryJSON.sha256(passportData)
      let passport = try decodeCandidatePassport(passportData)
      try validateAuthority(
        current: current,
        action: action,
        passport: passport,
        passportSHA256: passportSHA256,
        commandCandidateOID: command.candidateOID
      )
      observation = try observeCandidate(
        passport,
        episodeDescriptor: episodeDescriptor
      )
    } catch let failure as LiveGitCandidateEvaluationFailure {
      rejectionCodes = [failure.code]
    } catch let error as LiveGitCandidateRuntimeError {
      switch error {
      case .checkerFailed:
        rejectionCodes = ["checker_failed"]
      default:
        rejectionCodes = ["git_observation_failed"]
      }
    } catch {
      rejectionCodes = ["candidate_validation_failed"]
    }

    let reloaded: StoredLiveEpisodeGeneration?
    do {
      reloaded = try generationLoader.loadCurrent()
    } catch {
      throw LiveGitCandidateAcceptanceError.rejected(
        "CURRENT изменился или перестал проходить проверку во время приёмки."
      )
    }
    guard reloaded?.generationSHA256 == current.generationSHA256 else {
      throw LiveGitCandidateAcceptanceError.rejected(
        "CURRENT изменился во время приёмки."
      )
    }
    if let passportCanonicalData {
      guard
        (try? readCandidatePassport(
          episodeDescriptor: episodeDescriptor,
          candidateOID: command.candidateOID
        ))
          == passportCanonicalData
      else {
        throw LiveGitCandidateAcceptanceError.rejected(
          "Паспорт изменился во время приёмки."
        )
      }
    }

    let verdict: LiveGitCandidateAcceptanceVerdict =
      rejectionCodes.isEmpty ? .accepted : .rejected
    let receipt = LiveGitCandidateAcceptanceReceipt(
      verdict: verdict,
      currentGenerationSHA256: current.generationSHA256,
      admissionSHA256: admissionSHA256,
      passportSHA256: passportSHA256,
      candidateOID: command.candidateOID,
      observation: observation,
      rejectionCodes: rejectionCodes.sorted()
    )
    let stored = try LiveGitCandidateAcceptanceReceiptStore(
      episodeDirectoryURL: episodeDirectoryURL
    ).publish(receipt)
    return LiveGitCandidateAcceptanceOutput(
      commandID: command.commandID,
      candidateOID: command.candidateOID,
      verdict: verdict,
      receiptSHA256: stored.receiptSHA256
    )
  }

  private func candidateAction(
    in current: StoredLiveEpisodeGeneration
  ) throws -> LiveAllowedAction {
    let actions = current.state.passport.actionAllowlist.filter {
      $0.operation == LiveGitCandidateContract.operation
        && $0.candidateCommitPolicy != nil
    }
    guard current.state.passport.actionAllowlist.count == 1,
      actions.count == 1,
      let action = actions.first,
      let policy = action.candidateCommitPolicy
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_admission_count")
    }
    do {
      try action.validateCandidateCommitPolicy()
      try policy.validate()
    } catch {
      throw LiveGitCandidateEvaluationFailure("candidate_admission_invalid")
    }
    return action
  }

  private func readCandidatePassport(
    episodeDescriptor: Int32,
    candidateOID: String
  ) throws -> Data {
    let candidatesDescriptor = openat(
      episodeDescriptor,
      "candidates",
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard candidatesDescriptor >= 0 else {
      throw LiveGitCandidateEvaluationFailure("passport_missing")
    }
    defer { _ = close(candidatesDescriptor) }
    let candidateDescriptor = openat(
      candidatesDescriptor,
      candidateOID,
      O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
    )
    guard candidateDescriptor >= 0 else {
      throw LiveGitCandidateEvaluationFailure("passport_missing")
    }
    defer { _ = close(candidateDescriptor) }
    let passportDescriptor = openat(
      candidateDescriptor,
      "passport.json",
      O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC
    )
    guard passportDescriptor >= 0 else {
      throw LiveGitCandidateEvaluationFailure("passport_missing")
    }
    defer { _ = close(passportDescriptor) }
    var metadata = stat()
    guard fstat(passportDescriptor, &metadata) == 0,
      (metadata.st_mode & S_IFMT) == S_IFREG,
      metadata.st_nlink == 1,
      metadata.st_size >= 0,
      metadata.st_size <= 1_048_576
    else {
      throw LiveGitCandidateEvaluationFailure("passport_not_regular")
    }

    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 8_192)
    while true {
      let count = Darwin.read(passportDescriptor, &buffer, buffer.count)
      if count < 0, errno == EINTR { continue }
      guard count >= 0 else {
        throw LiveGitCandidateEvaluationFailure("passport_read_failed")
      }
      if count == 0 { break }
      data.append(contentsOf: buffer.prefix(count))
      guard data.count <= 1_048_576 else {
        throw LiveGitCandidateEvaluationFailure("passport_too_large")
      }
    }
    var finalMetadata = stat()
    guard fstat(passportDescriptor, &finalMetadata) == 0,
      data.count == Int(metadata.st_size),
      sameImmutableFile(metadata, finalMetadata)
    else {
      throw LiveGitCandidateEvaluationFailure("passport_changed_while_reading")
    }
    guard !data.isEmpty else {
      throw LiveGitCandidateEvaluationFailure("passport_empty")
    }
    return data
  }

  private func sameImmutableFile(_ first: stat, _ second: stat) -> Bool {
    first.st_dev == second.st_dev
      && first.st_ino == second.st_ino
      && first.st_mode == second.st_mode
      && first.st_nlink == second.st_nlink
      && first.st_size == second.st_size
      && first.st_mtimespec.tv_sec == second.st_mtimespec.tv_sec
      && first.st_mtimespec.tv_nsec == second.st_mtimespec.tv_nsec
      && first.st_ctimespec.tv_sec == second.st_ctimespec.tv_sec
      && first.st_ctimespec.tv_nsec == second.st_ctimespec.tv_nsec
  }

  private func decodeCandidatePassport(_ data: Data) throws -> LiveGitCandidatePassport {
    do {
      try CanonicalMemoryJSON.requireCanonical(data)
      let passport = try JSONDecoder().decode(LiveGitCandidatePassport.self, from: data)
      guard try CanonicalMemoryJSON.encode(passport) == data else {
        throw LiveGitCandidateEvaluationFailure("passport_noncanonical")
      }
      try passport.validate()
      return passport
    } catch let failure as LiveGitCandidateEvaluationFailure {
      throw failure
    } catch {
      throw LiveGitCandidateEvaluationFailure("passport_noncanonical")
    }
  }

  private func validateAuthority(
    current: StoredLiveEpisodeGeneration,
    action: LiveAllowedAction,
    passport: LiveGitCandidatePassport,
    passportSHA256: String,
    commandCandidateOID: String
  ) throws {
    guard let policy = action.candidateCommitPolicy else {
      throw LiveGitCandidateEvaluationFailure("candidate_admission_invalid")
    }
    guard passport.schemaIdentity == LiveGitCandidateRuntimeSchema.passportIdentity,
      passport.schemaVersion == LiveGitCandidateRuntimeSchema.version,
      passport.canonicalProfile == CanonicalMemoryJSON.profileID,
      passport.cloneRelativePath == LiveGitCandidateRuntimeSchema.cloneRelativePath,
      passport.candidateOID == commandCandidateOID,
      passport.candidateOID == policy.expectedCandidateOID,
      passport.parentOID == policy.baseCommitOID,
      passport.treeOID == policy.expectedTreeOID,
      passport.candidateBranchRef == policy.candidateBranch,
      passport.resultRef == policy.resultRef,
      passport.allowedPaths == policy.allowedPaths,
      passport.checkerSpecifications == policy.checkers,
      passport.author == policy.author,
      passport.committer == policy.committer,
      passport.message == policy.message
    else {
      throw LiveGitCandidateEvaluationFailure("passport_admission_mismatch")
    }
    guard passport.changedPaths == Array(Set(passport.changedPaths)).sorted(),
      Set(passport.changedPaths).isSubset(of: Set(policy.allowedPaths)),
      passport.expectedWrites.map(\.path) == passport.changedPaths,
      passport.checkerObservations.map(\.checkerID) == policy.checkers.map(\.checkerID),
      passport.checkerObservations.allSatisfy({ $0.status == .passed })
    else {
      throw LiveGitCandidateEvaluationFailure("passport_contents_invalid")
    }

    guard let transition = current.state.transition,
      transition.phase == .observed,
      transition.declaration.allowanceID == action.allowanceID,
      transition.declaration.coordinates == passport.coordinates,
      passport.planSHA256 == passport.coordinates.expectedEffectSHA256
    else {
      throw LiveGitCandidateEvaluationFailure("transition_not_observed")
    }
    guard let selection = current.state.model.selection,
      let selectedIntent = current.state.model.variants
        .compactMap(\.intent?.intent)
        .first(where: { $0.intentID == selection.sourceIntentID }),
      selectedIntent.operation == action.operation,
      selectedIntent.adapterID == action.adapterID,
      selectedIntent.effectClass == action.effectClass,
      selectedIntent.objectID == passport.coordinates.objectID,
      selectedIntent.expectedEffectSHA256 == passport.coordinates.expectedEffectSHA256,
      selectedIntent.argumentsSHA256 == passport.planSHA256
    else {
      throw LiveGitCandidateEvaluationFailure("selected_intent_mismatch")
    }

    guard let receiptJournal = current.generation.candidateReceiptJournal,
      receiptJournal.receipts.count == LiveGitCandidateStage.allCases.count
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_receipt_chain_missing")
    }
    let receipts = receiptJournal.receipts
    let receiptEventIDs = Set(receipts.map(\.eventID))
    let candidateEvents = current.generation.eventJournal.events.filter {
      receiptEventIDs.contains($0.eventID)
    }
    do {
      try LiveGitCandidateReceiptChain.validate(
        receipts,
        policy: policy,
        expectedCoordinates: passport.coordinates,
        candidateOwnedEvents: candidateEvents
      )
    } catch {
      throw LiveGitCandidateEvaluationFailure("candidate_receipt_chain_invalid")
    }
    guard let preflightReceipt = receipts.first(where: { $0.stage == .preflightPassed }),
      let executionReceipt = receipts.first(where: { $0.stage == .executed }),
      let observationReceipt = receipts.first(where: { $0.stage == .observed }),
      preflightReceipt.eventID == passport.preflightEventID,
      preflightReceipt.receiptID == passport.preflightReceiptID,
      preflightReceipt.evidence.evidenceID == passport.preflightReceiptID,
      executionReceipt.eventID == passport.executionEventID,
      executionReceipt.receiptID == passport.executionReceiptID,
      executionReceipt.evidence.evidenceID == passport.executionReceiptID,
      executionReceipt.evidence.evidenceSHA256
        == CanonicalMemoryJSON.sha256(Data(passport.candidateOID.utf8)),
      observationReceipt.eventID == passport.observationEventID,
      observationReceipt.receiptID == passport.observationReceiptID,
      observationReceipt.evidence.evidenceID == passport.observationReceiptID,
      observationReceipt.evidence.evidenceSHA256 == passportSHA256,
      transition.observation?.evidence == observationReceipt.evidence
    else {
      throw LiveGitCandidateEvaluationFailure("passport_evidence_mismatch")
    }
    let journalEvents = current.generation.eventJournal.events
    guard
      let expectedConfirmationEventID =
        receiptJournal.observationConfirmationEventID,
      let observationIndex = journalEvents.firstIndex(where: {
        $0.eventID == observationReceipt.eventID
      }),
      observationIndex == journalEvents.count - 2,
      case .observationRecorded(let durableObservation) =
        journalEvents[observationIndex].payload,
      durableObservation.coordinates == passport.coordinates,
      durableObservation.evidence == observationReceipt.evidence,
      let confirmationEvent = journalEvents.last,
      confirmationEvent.sequence == journalEvents[observationIndex].sequence + 1,
      confirmationEvent.eventID == expectedConfirmationEventID,
      case .generationConfirmed(let confirmation) = confirmationEvent.payload,
      confirmation.confirmedThroughSequence == journalEvents[observationIndex].sequence,
      let stageGenerationSHA256 = current.generation.previousGenerationSHA256,
      confirmation.generationID == String(stageGenerationSHA256.dropFirst(7)),
      current.state.confirmedGeneration?.eventID == confirmationEvent.eventID,
      current.state.confirmedGeneration?.confirmation == confirmation
    else {
      throw LiveGitCandidateEvaluationFailure("observation_confirmation_invalid")
    }
  }

  private func observeCandidate(
    _ passport: LiveGitCandidatePassport,
    episodeDescriptor: Int32
  ) throws -> LiveGitCandidateAcceptanceObservation {
    let metadataValidator = LiveGitCandidateAcceptanceCloneMetadataValidator(
      episodeDescriptor: episodeDescriptor,
      passport: passport
    )
    try metadataValidator.validate()
    let cloneURL = episodeDirectoryURL.appendingPathComponent(
      LiveGitCandidateRuntimeSchema.cloneRelativePath,
      isDirectory: true
    )
    try requirePlainDirectory(cloneURL, code: "candidate_clone_invalid")
    try requirePlainDirectory(
      cloneURL.appendingPathComponent(".git", isDirectory: true),
      code: "candidate_git_directory_invalid"
    )
    let runner = LiveGitProcessRunner()
    try validateCloneIsolation(cloneURL: cloneURL, runner: runner)
    let objectType = try normalizedLine(
      runner.run(["cat-file", "-t", passport.candidateOID], at: cloneURL).output
    )
    guard objectType == "commit" else {
      throw LiveGitCandidateEvaluationFailure("candidate_object_not_commit")
    }
    let rawCommit = try runner.run(
      ["cat-file", "commit", passport.candidateOID],
      at: cloneURL
    ).output
    try validateRawCommit(rawCommit, passport: passport, runner: runner, cloneURL: cloneURL)
    try validateExpectedWrites(passport, runner: runner, cloneURL: cloneURL)

    try validateCandidateRefs(passport, runner: runner, cloneURL: cloneURL)

    let changedPathData = try runner.run(
      [
        "diff-tree", "--no-ext-diff", "--no-textconv", "--no-renames", "--no-commit-id",
        "--name-only", "-z", "-r",
        passport.parentOID, passport.candidateOID, "--",
      ],
      at: cloneURL
    ).output
    let changedPaths = try parseNULTerminatedPaths(changedPathData)
    guard changedPaths == passport.changedPaths else {
      throw LiveGitCandidateEvaluationFailure("candidate_diff_mismatch")
    }
    let rawDiff = try runner.run(
      [
        "diff-tree", "--no-ext-diff", "--no-textconv", "--no-renames", "--raw", "-z", "-r",
        "--no-abbrev",
        passport.parentOID, passport.candidateOID, "--",
      ],
      at: cloneURL
    ).output
    let rerun = try checkerRegistry.verify(
      passport: passport,
      episodeDirectoryURL: episodeDirectoryURL
    )
    guard rerun == passport.checkerObservations else {
      throw LiveGitCandidateEvaluationFailure("checker_observation_mismatch")
    }
    try validateCandidateRefs(passport, runner: runner, cloneURL: cloneURL)
    try metadataValidator.validate()
    try validateCandidateRefs(passport, runner: runner, cloneURL: cloneURL)
    return LiveGitCandidateAcceptanceObservation(
      parentOID: passport.parentOID,
      treeOID: passport.treeOID,
      rawCommitSHA256: CanonicalMemoryJSON.sha256(rawCommit),
      nulDiffSHA256: CanonicalMemoryJSON.sha256(rawDiff),
      changedPaths: changedPaths,
      checkers: rerun.map {
        LiveGitCandidateAcceptanceCheckerObservation(
          checkerID: $0.checkerID,
          status: $0.status == .passed ? .passed : .failed,
          observationSHA256: $0.observationSHA256
        )
      }
    )
  }

  private func validateCloneIsolation(
    cloneURL: URL,
    runner: LiveGitProcessRunner
  ) throws {
    let expectedGitDirectory = cloneURL.appendingPathComponent(".git", isDirectory: true)
      .standardizedFileURL.resolvingSymlinksInPath()
    for component in ["objects", "objects/info", "objects/pack", "refs"] {
      try requirePlainDirectory(
        expectedGitDirectory.appendingPathComponent(component, isDirectory: true),
        code: "candidate_git_directory_invalid"
      )
    }
    let actualGitDirectory = try normalizedLine(
      runner.run(["rev-parse", "--absolute-git-dir"], at: cloneURL).output
    )
    let actualCommonDirectory = try normalizedLine(
      runner.run(
        ["rev-parse", "--path-format=absolute", "--git-common-dir"],
        at: cloneURL
      ).output
    )
    let resolvedGitDirectory = URL(fileURLWithPath: actualGitDirectory)
      .standardizedFileURL.resolvingSymlinksInPath()
    let resolvedCommonDirectory = URL(fileURLWithPath: actualCommonDirectory)
      .standardizedFileURL.resolvingSymlinksInPath()
    guard resolvedGitDirectory == expectedGitDirectory,
      resolvedCommonDirectory == expectedGitDirectory
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_git_directory_not_isolated")
    }
    var metadata = stat()
    let alternatesURL = expectedGitDirectory.appendingPathComponent(
      "objects/info/alternates",
      isDirectory: false
    )
    guard lstat(alternatesURL.path, &metadata) != 0, errno == ENOENT else {
      throw LiveGitCandidateEvaluationFailure("candidate_git_alternates_present")
    }
  }

  private func validateCandidateRefs(
    _ passport: LiveGitCandidatePassport,
    runner: LiveGitProcessRunner,
    cloneURL: URL
  ) throws {
    for ref in [passport.candidateBranchRef, passport.resultRef] {
      let symbolic = try runner.run(
        ["symbolic-ref", "-q", ref],
        at: cloneURL,
        acceptedStatuses: [0, 1]
      )
      guard symbolic.status == 1, symbolic.output.isEmpty else {
        throw LiveGitCandidateEvaluationFailure("candidate_ref_symbolic")
      }
      let resolved = try normalizedLine(
        runner.run(["rev-parse", "--verify", ref], at: cloneURL).output
      )
      guard resolved == passport.candidateOID else {
        throw LiveGitCandidateEvaluationFailure("candidate_ref_mismatch")
      }
    }
  }

  private func validateExpectedWrites(
    _ passport: LiveGitCandidatePassport,
    runner: LiveGitProcessRunner,
    cloneURL: URL
  ) throws {
    for write in passport.expectedWrites {
      let entry = try runner.run(
        ["ls-tree", "-z", "--full-name", passport.candidateOID, "--", write.path],
        at: cloneURL
      ).output
      guard entry.last == 0,
        entry.dropLast().firstIndex(of: 0) == nil,
        let tab = entry.firstIndex(of: 0x09)
      else {
        throw LiveGitCandidateEvaluationFailure("candidate_tree_entry_mismatch")
      }
      let headerBytes = entry[..<tab]
      let pathStart = entry.index(after: tab)
      let pathBytes = entry[pathStart..<entry.index(before: entry.endIndex)]
      guard let header = String(data: headerBytes, encoding: .utf8),
        Data(header.utf8) == headerBytes,
        pathBytes == Data(write.path.utf8)
      else {
        throw LiveGitCandidateEvaluationFailure("candidate_tree_entry_mismatch")
      }
      let fields = header.split(separator: " ").map(String.init)
      guard fields.count == 3,
        fields[0] == write.mode.rawValue,
        fields[1] == "blob",
        LiveGitCandidateAcceptanceCommand.isExactOID(fields[2])
      else {
        throw LiveGitCandidateEvaluationFailure("candidate_tree_entry_mismatch")
      }
      let contents = try runner.run(
        ["cat-file", "blob", fields[2]],
        at: cloneURL
      ).output
      guard CanonicalMemoryJSON.sha256(contents) == write.contentsSHA256 else {
        throw LiveGitCandidateEvaluationFailure("candidate_blob_mismatch")
      }
    }
  }

  private func validateRawCommit(
    _ data: Data,
    passport: LiveGitCandidatePassport,
    runner: LiveGitProcessRunner,
    cloneURL: URL
  ) throws {
    guard let separator = data.range(of: Data([0x0a, 0x0a])) else {
      throw LiveGitCandidateEvaluationFailure("candidate_commit_malformed")
    }
    let headerData = data[..<separator.lowerBound]
    let messageData = data[separator.upperBound...]
    guard let headers = String(data: headerData, encoding: .utf8),
      Data(headers.utf8) == headerData,
      messageData == Data(passport.message.utf8)
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_commit_metadata_mismatch")
    }
    let expectedHeaders = [
      "tree \(passport.treeOID)",
      "parent \(passport.parentOID)",
      signatureHeader("author", passport.author),
      signatureHeader("committer", passport.committer),
    ]
    guard
      headers.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        == expectedHeaders
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_commit_metadata_mismatch")
    }
    let recalculated = try normalizedLine(
      runner.run(
        ["hash-object", "-t", "commit", "--stdin"],
        at: cloneURL,
        input: data
      ).output
    )
    guard recalculated == passport.candidateOID else {
      throw LiveGitCandidateEvaluationFailure("candidate_oid_mismatch")
    }
  }

  private func signatureHeader(
    _ kind: String,
    _ signature: LiveGitCandidateSignature
  ) -> String {
    let absoluteOffset = abs(signature.timeZoneOffsetMinutes)
    let sign = signature.timeZoneOffsetMinutes < 0 ? "-" : "+"
    let timeZone = String(
      format: "%@%02d%02d",
      sign,
      absoluteOffset / 60,
      absoluteOffset % 60
    )
    return
      "\(kind) \(signature.name) <\(signature.email)> \(signature.timestampSeconds) \(timeZone)"
  }

  private func normalizedLine(_ data: Data) throws -> String {
    guard let value = String(data: data, encoding: .utf8),
      Data(value.utf8) == data,
      value.hasSuffix("\n"),
      !value.dropLast().contains("\n")
    else {
      throw LiveGitCandidateEvaluationFailure("git_output_invalid")
    }
    return String(value.dropLast())
  }

  private func parseNULTerminatedPaths(_ data: Data) throws -> [String] {
    guard !data.isEmpty, data.last == 0 else {
      throw LiveGitCandidateEvaluationFailure("candidate_diff_invalid")
    }
    var paths: [String] = []
    var start = data.startIndex
    for index in data.indices where data[index] == 0 {
      let bytes = data[start..<index]
      guard !bytes.isEmpty, let path = String(data: bytes, encoding: .utf8),
        Data(path.utf8) == bytes
      else {
        throw LiveGitCandidateEvaluationFailure("candidate_diff_invalid")
      }
      paths.append(path)
      start = data.index(after: index)
    }
    guard start == data.endIndex,
      paths == Array(Set(paths)).sorted()
    else {
      throw LiveGitCandidateEvaluationFailure("candidate_diff_invalid")
    }
    return paths
  }

  private func requirePlainDirectory(_ url: URL, code: String) throws {
    var metadata = stat()
    guard lstat(url.path, &metadata) == 0,
      (metadata.st_mode & S_IFMT) == S_IFDIR
    else {
      throw LiveGitCandidateEvaluationFailure(code)
    }
  }
}

private struct LiveGitCandidateEvaluationFailure: Error {
  let code: String

  init(_ code: String) {
    self.code = code
  }
}

public struct LiveGitCandidateAcceptanceOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let commandID: String
  public let candidateOID: String
  public let verdict: LiveGitCandidateAcceptanceVerdict
  public let receiptSHA256: String

  public init(
    schemaVersion: Int = LiveGitCandidateAcceptanceSchema.version,
    commandID: String,
    candidateOID: String,
    verdict: LiveGitCandidateAcceptanceVerdict,
    receiptSHA256: String
  ) {
    self.schemaVersion = schemaVersion
    self.commandID = commandID
    self.candidateOID = candidateOID
    self.verdict = verdict
    self.receiptSHA256 = receiptSHA256
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case commandID = "command_id"
    case candidateOID = "candidate_oid"
    case verdict
    case receiptSHA256 = "receipt_sha256"
  }
}

public struct LiveGitCandidateAcceptanceErrorOutput: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let code: String
  public let message: String

  public init(
    schemaVersion: Int = LiveGitCandidateAcceptanceSchema.version,
    code: String,
    message: String
  ) {
    self.schemaVersion = schemaVersion
    self.code = code
    self.message = message
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case code
    case message
  }
}
