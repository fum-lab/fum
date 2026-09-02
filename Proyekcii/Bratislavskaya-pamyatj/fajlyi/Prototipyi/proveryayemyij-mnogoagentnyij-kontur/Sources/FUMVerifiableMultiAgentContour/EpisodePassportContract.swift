import CoreFoundation
import CryptoKit
import Foundation

private let episodeJSONPointerSeparator = "/"
private let episodeTildeMarker = "\u{007E}"

private func episodeRootJSONPointer(_ relative: String) -> String {
  episodeJSONPointerSeparator + relative
}

public enum EpisodePassportDecision: String, Codable, Sendable {
  case valid
  case invalid
}

public struct EpisodePassportViolation: Codable, Equatable, Hashable, Sendable {
  public let code: String
  public let path: String
  public let message: String
}

public struct EpisodePassportReport: Encodable, Equatable, Sendable {
  public let schemaVersion: Int
  public let episodeID: String?
  public let passportSHA256: String
  public let decision: EpisodePassportDecision
  public let violations: [EpisodePassportViolation]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case episodeID = "episode_id"
    case passportSHA256 = "passport_sha256"
    case decision
    case violations
  }

  init(
    episodeID: String?,
    passportSHA256: String,
    violations: [EpisodePassportViolation]
  ) {
    schemaVersion = 1
    self.episodeID = episodeID
    self.passportSHA256 = passportSHA256
    let ordered = Array(Set(violations)).sorted { left, right in
      if left.code != right.code { return left.code < right.code }
      if left.path != right.path { return left.path < right.path }
      return left.message < right.message
    }
    self.violations = ordered
    decision = ordered.isEmpty ? .valid : .invalid
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    if let episodeID {
      try container.encode(episodeID, forKey: .episodeID)
    } else {
      try container.encodeNil(forKey: .episodeID)
    }
    try container.encode(passportSHA256, forKey: .passportSHA256)
    try container.encode(decision, forKey: .decision)
    try container.encode(violations, forKey: .violations)
  }

  public func canonicalJSONData() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(self)
  }
}

public enum EpisodePassportFixtureError: Error, CustomStringConvertible, Sendable {
  case unknownFixture(String)
  case missingResource(String)
  case resourceTooLarge(Int)

  public var description: String {
    switch self {
    case .unknownFixture(let identifier):
      "Неизвестная фикстура паспорта эпизода: \(identifier)."
    case .missingResource(let identifier):
      "Ресурс фикстуры паспорта эпизода отсутствует: \(identifier)."
    case .resourceTooLarge(let size):
      "Ресурс фикстуры паспорта эпизода превышает допустимый размер: \(size)."
    }
  }
}

public enum EpisodePassportFixtures {
  public static let identifiers = [
    "valid",
    "invalid-assertion-vote",
    "invalid-missing-role",
    "invalid-shared-package",
    "invalid-unsaved-memory",
  ]

  public static func load(named identifier: String) throws -> Data {
    guard identifiers.contains(identifier) else {
      throw EpisodePassportFixtureError.unknownFixture(identifier)
    }
    let url =
      Bundle.module.url(
        forResource: identifier,
        withExtension: "json",
        subdirectory: "Фикстуры/ПаспортаЭпизода"
      )
      ?? Bundle.module.url(
        forResource: identifier,
        withExtension: "json",
        subdirectory: "ПаспортаЭпизода"
      )
    guard let url else {
      throw EpisodePassportFixtureError.missingResource(identifier)
    }
    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    guard let size = values.fileSize, size <= EpisodePassportPreflight.maximumEnvelopeBytes else {
      throw EpisodePassportFixtureError.resourceTooLarge(values.fileSize ?? -1)
    }
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard data.count <= EpisodePassportPreflight.maximumEnvelopeBytes else {
      throw EpisodePassportFixtureError.resourceTooLarge(data.count)
    }
    return data
  }
}

public enum EpisodePassportPreflight {
  public static let maximumEnvelopeBytes = 1_048_576

  private static let artifactKinds: Set<String> = [
    "goal", "criteria", "work_package", "input_manifest", "shared_memory",
    "contribution", "observation", "verification", "selection", "stop",
  ]
  private static let roleKinds: Set<String> = ["producer", "verifier", "selector"]
  private static let topLevelKeys: Set<String> = [
    "schema_version", "episode_id", "artifacts", "goal", "roles", "hypotheses",
    "work_packages", "shared_memory", "contributions", "observations", "verification",
    "selection", "stop", "handoff", "evidence_policy",
  ]

  private struct ArtifactSnapshot {
    let identifier: String
    let kind: String
    let persistence: String
  }

  private struct RoleSnapshot {
    let identifier: String
    let kind: String
  }

  private struct WorkPackageSnapshot {
    let identifier: String
    let roleID: String
    let hypothesisIDs: [String]
    let inputManifestID: String
  }

  private struct ContributionSnapshot {
    let identifier: String
    let roleID: String
    let hypothesisIDs: [String]
    let packageID: String
    let inputManifestID: String
  }

  private struct ObservationSnapshot {
    let identifier: String
  }

  public static func analyze(_ data: Data) -> EpisodePassportReport {
    let digest = SHA256.hash(data: data)
    let passportSHA256 = "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    var violations: [EpisodePassportViolation] = []

    guard !data.isEmpty, data.count <= maximumEnvelopeBytes else {
      append(
        data.isEmpty ? "invalid_json" : "input_limit_exceeded",
        path: "",
        message: data.isEmpty
          ? "Входной JSON паспорта отсутствует."
          : "Входной JSON паспорта превышает предел версии 1.",
        to: &violations
      )
      return EpisodePassportReport(
        episodeID: nil,
        passportSHA256: passportSHA256,
        violations: violations
      )
    }

    var duplicateKeyDetector = EpisodeJSONDuplicateKeyDetector(data: data)
    do {
      for path in try duplicateKeyDetector.scan() {
        append(
          "duplicate_key",
          path: path,
          message: "JSON-объект содержит повторный ключ.",
          to: &violations
        )
      }
    } catch EpisodeJSONScanError.structureLimitExceeded {
      append(
        "structure_limit_exceeded",
        path: "",
        message: "Структура JSON превышает предел глубины или числа узлов версии 1.",
        to: &violations
      )
      return EpisodePassportReport(
        episodeID: nil,
        passportSHA256: passportSHA256,
        violations: violations
      )
    } catch {
      append(
        "invalid_json",
        path: "",
        message: "Вход не является завершённым JSON-объектом.",
        to: &violations
      )
      return EpisodePassportReport(
        episodeID: nil,
        passportSHA256: passportSHA256,
        violations: violations
      )
    }

    let raw: Any
    do {
      raw = try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
      append(
        "invalid_json",
        path: "",
        message: "Вход не является завершённым JSON-объектом.",
        to: &violations
      )
      return EpisodePassportReport(
        episodeID: nil,
        passportSHA256: passportSHA256,
        violations: violations
      )
    }

    guard let root = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: "",
        message: "Верхний уровень паспорта должен быть объектом.",
        to: &violations
      )
      return EpisodePassportReport(
        episodeID: nil,
        passportSHA256: passportSHA256,
        violations: violations
      )
    }

    validateExactKeys(root, expected: topLevelKeys, path: "", violations: &violations)
    validateSchema(root["schema_version"], violations: &violations)
    let episodeID = string(
      root["episode_id"],
      path: episodeRootJSONPointer("episode_id"),
      violations: &violations
    )
    validateTechnicalIdentifier(
      episodeID,
      path: episodeRootJSONPointer("episode_id"),
      violations: &violations
    )

    let artifacts = validateArtifacts(root["artifacts"], violations: &violations)
    validateGoal(root["goal"], artifacts: artifacts, violations: &violations)
    let roles = validateRoles(root["roles"], violations: &violations)
    let hypotheses = validateHypotheses(root["hypotheses"], violations: &violations)
    let workPackages = validateWorkPackages(
      root["work_packages"],
      artifacts: artifacts,
      roles: roles,
      hypotheses: hypotheses,
      violations: &violations
    )
    let memoryID = validateSharedMemory(
      root["shared_memory"],
      artifacts: artifacts,
      violations: &violations
    )
    let contributions = validateContributions(
      root["contributions"],
      artifacts: artifacts,
      roles: roles,
      hypotheses: hypotheses,
      workPackages: workPackages,
      memoryID: memoryID,
      violations: &violations
    )
    let observations = validateObservations(
      root["observations"],
      artifacts: artifacts,
      contributions: contributions,
      violations: &violations
    )
    let verificationID = validateVerification(
      root["verification"],
      artifacts: artifacts,
      roles: roles,
      contributions: contributions,
      observations: observations,
      violations: &violations
    )
    let selectionID = validateSelection(
      root["selection"],
      artifacts: artifacts,
      roles: roles,
      contributions: contributions,
      verificationID: verificationID,
      violations: &violations
    )
    validateStop(
      root["stop"],
      artifacts: artifacts,
      selectionID: selectionID,
      violations: &violations
    )
    validateHandoff(root["handoff"], artifacts: artifacts, violations: &violations)
    validateEvidencePolicy(root["evidence_policy"], violations: &violations)

    return EpisodePassportReport(
      episodeID: episodeID,
      passportSHA256: passportSHA256,
      violations: violations
    )
  }

  private static func validateSchema(
    _ raw: Any?,
    violations: inout [EpisodePassportViolation]
  ) {
    guard
      let version = integer(
        raw,
        path: episodeRootJSONPointer("schema_version"),
        violations: &violations
      )
    else { return }
    if version != 1 {
      append(
        "unsupported_schema",
        path: episodeRootJSONPointer("schema_version"),
        message: "Поддерживается только schema_version 1.",
        to: &violations
      )
    }
  }

  private static func validateArtifacts(
    _ raw: Any?,
    violations: inout [EpisodePassportViolation]
  ) -> [String: ArtifactSnapshot] {
    guard
      let values = array(raw, path: episodeRootJSONPointer("artifacts"), violations: &violations)
    else {
      return [:]
    }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("artifacts"), maximum: 128, violations: &violations)
    if values.isEmpty {
      append(
        "artifacts_missing",
        path: episodeRootJSONPointer("artifacts"),
        message: "Реестр сохраняемых артефактов не должен быть пустым.",
        to: &violations
      )
    }

    var result: [String: ArtifactSnapshot] = [:]
    for (index, value) in values.prefix(128).enumerated() {
      let path = episodeRootJSONPointer("artifacts/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["artifact_id", "kind", "persistence", "sha256"],
        path: path,
        violations: &violations
      )
      let identifier = string(
        object["artifact_id"],
        path: "\(path)/artifact_id",
        violations: &violations
      )
      validateTechnicalIdentifier(identifier, path: "\(path)/artifact_id", violations: &violations)
      let kind = string(object["kind"], path: "\(path)/kind", violations: &violations)
      if let kind, !artifactKinds.contains(kind) {
        append(
          "invalid_artifact_kind",
          path: "\(path)/kind",
          message: "Тип артефакта не поддерживается версией 1.",
          to: &violations
        )
      }
      let persistence = string(
        object["persistence"],
        path: "\(path)/persistence",
        violations: &violations
      )
      if let persistence, persistence != "persisted" {
        append(
          "artifact_not_persisted",
          path: "\(path)/persistence",
          message: "Межсессионный артефакт должен быть явно сохранён.",
          to: &violations
        )
      }
      let hash = string(object["sha256"], path: "\(path)/sha256", violations: &violations)
      if let hash, !isSHA256(hash) {
        append(
          "invalid_hash",
          path: "\(path)/sha256",
          message: "Хэш артефакта должен иметь вид sha256:<64 lowercase hex>.",
          to: &violations
        )
      }
      if let identifier, let kind, let persistence {
        if result[identifier] != nil {
          append(
            "duplicate_identifier",
            path: "\(path)/artifact_id",
            message: "Идентификатор артефакта повторяется.",
            to: &violations
          )
        } else {
          result[identifier] = ArtifactSnapshot(
            identifier: identifier,
            kind: kind,
            persistence: persistence
          )
        }
      }
    }
    return result
  }

  private static func validateGoal(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    violations: inout [EpisodePassportViolation]
  ) {
    guard let object = object(raw, path: episodeRootJSONPointer("goal"), violations: &violations)
    else { return }
    validateExactKeys(
      object,
      expected: ["goal_artifact_id", "criteria_artifact_id"],
      path: episodeRootJSONPointer("goal"),
      violations: &violations
    )
    let goalID = string(
      object["goal_artifact_id"], path: episodeRootJSONPointer("goal/goal_artifact_id"),
      violations: &violations)
    let criteriaID = string(
      object["criteria_artifact_id"],
      path: episodeRootJSONPointer("goal/criteria_artifact_id"),
      violations: &violations
    )
    validateArtifactReference(
      goalID,
      expectedKind: "goal",
      path: episodeRootJSONPointer("goal/goal_artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
    validateArtifactReference(
      criteriaID,
      expectedKind: "criteria",
      path: episodeRootJSONPointer("goal/criteria_artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
  }

  private static func validateRoles(
    _ raw: Any?,
    violations: inout [EpisodePassportViolation]
  ) -> [String: RoleSnapshot] {
    guard let values = array(raw, path: episodeRootJSONPointer("roles"), violations: &violations)
    else { return [:] }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("roles"), maximum: 32, violations: &violations)
    if values.isEmpty {
      append(
        "roles_missing",
        path: episodeRootJSONPointer("roles"),
        message: "Паспорт должен объявлять роли эпизода.",
        to: &violations
      )
    }
    var result: [String: RoleSnapshot] = [:]
    for (index, value) in values.prefix(32).enumerated() {
      let path = episodeRootJSONPointer("roles/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["role_id", "kind"],
        path: path,
        violations: &violations
      )
      let identifier = string(object["role_id"], path: "\(path)/role_id", violations: &violations)
      validateTechnicalIdentifier(identifier, path: "\(path)/role_id", violations: &violations)
      let kind = string(object["kind"], path: "\(path)/kind", violations: &violations)
      if let kind, !roleKinds.contains(kind) {
        append(
          "invalid_role_kind",
          path: "\(path)/kind",
          message: "Тип роли не поддерживается версией 1.",
          to: &violations
        )
      }
      if let identifier, let kind {
        if result[identifier] != nil {
          append(
            "duplicate_identifier",
            path: "\(path)/role_id",
            message: "Идентификатор роли повторяется.",
            to: &violations
          )
        } else {
          result[identifier] = RoleSnapshot(identifier: identifier, kind: kind)
        }
      }
    }
    return result
  }

  private static func validateHypotheses(
    _ raw: Any?,
    violations: inout [EpisodePassportViolation]
  ) -> Set<String> {
    guard
      let values = array(raw, path: episodeRootJSONPointer("hypotheses"), violations: &violations)
    else {
      return []
    }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("hypotheses"), maximum: 128, violations: &violations)
    var result: Set<String> = []
    for (index, value) in values.prefix(128).enumerated() {
      let path = episodeRootJSONPointer("hypotheses/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["hypothesis_id"],
        path: path,
        violations: &violations
      )
      let identifier = string(
        object["hypothesis_id"], path: "\(path)/hypothesis_id", violations: &violations)
      validateTechnicalIdentifier(
        identifier,
        path: "\(path)/hypothesis_id",
        violations: &violations
      )
      if let identifier, !result.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: "\(path)/hypothesis_id",
          message: "Идентификатор гипотезы повторяется.",
          to: &violations
        )
      }
    }
    return result
  }

  private static func validateWorkPackages(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    roles: [String: RoleSnapshot],
    hypotheses: Set<String>,
    violations: inout [EpisodePassportViolation]
  ) -> [String: WorkPackageSnapshot] {
    guard
      let values = array(
        raw, path: episodeRootJSONPointer("work_packages"), violations: &violations)
    else {
      return [:]
    }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("work_packages"), maximum: 64, violations: &violations)
    if values.count < 2 {
      append(
        "work_packages_insufficient",
        path: episodeRootJSONPointer("work_packages"),
        message: "Ограниченный эпизод должен объявлять не менее двух рабочих пакетов.",
        to: &violations
      )
    }

    var result: [String: WorkPackageSnapshot] = [:]
    var artifactIDs: Set<String> = []
    var manifestIDs: Set<String> = []
    for (index, value) in values.prefix(64).enumerated() {
      let path = episodeRootJSONPointer("work_packages/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: [
          "package_id", "artifact_id", "role_id", "hypothesis_ids", "input_manifest_id",
        ],
        path: path,
        violations: &violations
      )
      let packageID = string(
        object["package_id"],
        path: "\(path)/package_id",
        violations: &violations
      )
      validateTechnicalIdentifier(packageID, path: "\(path)/package_id", violations: &violations)
      let artifactID = string(
        object["artifact_id"],
        path: "\(path)/artifact_id",
        violations: &violations
      )
      validateArtifactReference(
        artifactID,
        expectedKind: "work_package",
        path: "\(path)/artifact_id",
        artifacts: artifacts,
        violations: &violations
      )
      if let artifactID, !artifactIDs.insert(artifactID).inserted {
        append(
          "work_package_artifact_reused",
          path: "\(path)/artifact_id",
          message: "Два рабочих пакета не могут быть одним артефактом.",
          to: &violations
        )
      }
      let roleID = string(object["role_id"], path: "\(path)/role_id", violations: &violations)
      validateRoleReference(
        roleID,
        expectedKind: "producer",
        path: "\(path)/role_id",
        roles: roles,
        violations: &violations
      )
      let hypothesisIDs = stringArray(
        object["hypothesis_ids"],
        path: "\(path)/hypothesis_ids",
        maximum: 32,
        violations: &violations
      )
      validateHypothesisReferences(
        hypothesisIDs,
        path: "\(path)/hypothesis_ids",
        hypotheses: hypotheses,
        violations: &violations
      )
      let manifestID = string(
        object["input_manifest_id"],
        path: "\(path)/input_manifest_id",
        violations: &violations
      )
      validateArtifactReference(
        manifestID,
        expectedKind: "input_manifest",
        path: "\(path)/input_manifest_id",
        artifacts: artifacts,
        violations: &violations
      )
      if let manifestID, !manifestIDs.insert(manifestID).inserted {
        append(
          "shared_input_manifest",
          path: "\(path)/input_manifest_id",
          message: "Каждый рабочий пакет должен иметь собственный идентификатор манифеста входов.",
          to: &violations
        )
      }

      if let packageID, let roleID, let hypothesisIDs, let manifestID {
        if result[packageID] != nil {
          append(
            "duplicate_identifier",
            path: "\(path)/package_id",
            message: "Идентификатор рабочего пакета повторяется.",
            to: &violations
          )
        } else {
          result[packageID] = WorkPackageSnapshot(
            identifier: packageID,
            roleID: roleID,
            hypothesisIDs: hypothesisIDs,
            inputManifestID: manifestID
          )
        }
      }
    }
    return result
  }

  private static func validateSharedMemory(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    violations: inout [EpisodePassportViolation]
  ) -> String? {
    guard
      let object = object(
        raw, path: episodeRootJSONPointer("shared_memory"), violations: &violations)
    else {
      return nil
    }
    validateExactKeys(
      object,
      expected: ["memory_id", "artifact_id"],
      path: episodeRootJSONPointer("shared_memory"),
      violations: &violations
    )
    let memoryID = string(
      object["memory_id"], path: episodeRootJSONPointer("shared_memory/memory_id"),
      violations: &violations)
    validateTechnicalIdentifier(
      memoryID, path: episodeRootJSONPointer("shared_memory/memory_id"), violations: &violations)
    let artifactID = string(
      object["artifact_id"], path: episodeRootJSONPointer("shared_memory/artifact_id"),
      violations: &violations)
    validateArtifactReference(
      artifactID,
      expectedKind: "shared_memory",
      path: episodeRootJSONPointer("shared_memory/artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
    return memoryID
  }

  private static func validateContributions(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    roles: [String: RoleSnapshot],
    hypotheses: Set<String>,
    workPackages: [String: WorkPackageSnapshot],
    memoryID: String?,
    violations: inout [EpisodePassportViolation]
  ) -> [String: ContributionSnapshot] {
    guard
      let values = array(
        raw, path: episodeRootJSONPointer("contributions"), violations: &violations)
    else {
      return [:]
    }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("contributions"), maximum: 64, violations: &violations)
    if values.count < 2 {
      append(
        "contributions_insufficient",
        path: episodeRootJSONPointer("contributions"),
        message: "Допустимый эпизод должен содержать не менее двух вкладов.",
        to: &violations
      )
    }

    var result: [String: ContributionSnapshot] = [:]
    var artifactIDs: Set<String> = []
    var usedPackageIDs: Set<String> = []
    for (index, value) in values.prefix(64).enumerated() {
      let path = episodeRootJSONPointer("contributions/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: [
          "contribution_id", "artifact_id", "role_id", "hypothesis_ids", "package_id",
          "input_manifest_id", "memory_id",
        ],
        path: path,
        violations: &violations
      )
      let contributionID = string(
        object["contribution_id"], path: "\(path)/contribution_id", violations: &violations)
      validateTechnicalIdentifier(
        contributionID, path: "\(path)/contribution_id", violations: &violations)
      let artifactID = string(
        object["artifact_id"],
        path: "\(path)/artifact_id",
        violations: &violations
      )
      validateArtifactReference(
        artifactID,
        expectedKind: "contribution",
        path: "\(path)/artifact_id",
        artifacts: artifacts,
        violations: &violations
      )
      if let artifactID, !artifactIDs.insert(artifactID).inserted {
        append(
          "contribution_artifact_reused",
          path: "\(path)/artifact_id",
          message: "Два вклада не могут быть одним артефактом.",
          to: &violations
        )
      }
      let roleID = string(object["role_id"], path: "\(path)/role_id", violations: &violations)
      validateRoleReference(
        roleID,
        expectedKind: "producer",
        path: "\(path)/role_id",
        roles: roles,
        violations: &violations
      )
      let hypothesisIDs = stringArray(
        object["hypothesis_ids"],
        path: "\(path)/hypothesis_ids",
        maximum: 32,
        violations: &violations
      )
      validateHypothesisReferences(
        hypothesisIDs,
        path: "\(path)/hypothesis_ids",
        hypotheses: hypotheses,
        violations: &violations
      )
      let packageID = string(
        object["package_id"],
        path: "\(path)/package_id",
        violations: &violations
      )
      if let packageID, !usedPackageIDs.insert(packageID).inserted {
        append(
          "shared_work_package",
          path: "\(path)/package_id",
          message: "Каждый вклад должен ссылаться на отдельный рабочий пакет.",
          to: &violations
        )
      }
      let manifestID = string(
        object["input_manifest_id"],
        path: "\(path)/input_manifest_id",
        violations: &violations
      )
      validateArtifactReference(
        manifestID,
        expectedKind: "input_manifest",
        path: "\(path)/input_manifest_id",
        artifacts: artifacts,
        violations: &violations
      )
      let referencedMemoryID = string(
        object["memory_id"], path: "\(path)/memory_id", violations: &violations)
      if let referencedMemoryID, let memoryID, referencedMemoryID != memoryID {
        append(
          "memory_reference_mismatch",
          path: "\(path)/memory_id",
          message: "Вклад ссылается не на объявленную общую память.",
          to: &violations
        )
      }

      if let packageID {
        guard let package = workPackages[packageID] else {
          append(
            "dangling_work_package_reference",
            path: "\(path)/package_id",
            message: "Ссылка на рабочий пакет не разрешается.",
            to: &violations
          )
          continue
        }
        if let roleID, roleID != package.roleID {
          append(
            "contribution_package_role_mismatch",
            path: "\(path)/role_id",
            message: "Роль вклада не совпадает с ролью рабочего пакета.",
            to: &violations
          )
        }
        if let hypothesisIDs, Set(hypothesisIDs) != Set(package.hypothesisIDs) {
          append(
            "contribution_package_hypothesis_mismatch",
            path: "\(path)/hypothesis_ids",
            message: "Гипотезы вклада не совпадают с гипотезами рабочего пакета.",
            to: &violations
          )
        }
        if let manifestID, manifestID != package.inputManifestID {
          append(
            "contribution_package_manifest_mismatch",
            path: "\(path)/input_manifest_id",
            message: "Манифест входов вклада не совпадает с манифестом рабочего пакета.",
            to: &violations
          )
        }
      }

      if let contributionID, let roleID, let hypothesisIDs, let packageID, let manifestID {
        if result[contributionID] != nil {
          append(
            "duplicate_identifier",
            path: "\(path)/contribution_id",
            message: "Идентификатор вклада повторяется.",
            to: &violations
          )
        } else {
          result[contributionID] = ContributionSnapshot(
            identifier: contributionID,
            roleID: roleID,
            hypothesisIDs: hypothesisIDs,
            packageID: packageID,
            inputManifestID: manifestID
          )
        }
      }
    }

    let snapshots = Array(result.values)
    if snapshots.count >= 2 {
      let distinctRoles = Set(snapshots.map(\.roleID)).count
      let distinctHypothesisSets = Set(
        snapshots.map { $0.hypothesisIDs.sorted().joined(separator: "\u{0}") }
      ).count
      if distinctRoles < 2, distinctHypothesisSets < 2 {
        append(
          "contributions_indistinguishable",
          path: episodeRootJSONPointer("contributions"),
          message: "Вклады должны различаться ролью или набором гипотез.",
          to: &violations
        )
      }
    }
    return result
  }

  private static func validateObservations(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    contributions: [String: ContributionSnapshot],
    violations: inout [EpisodePassportViolation]
  ) -> [String: ObservationSnapshot] {
    guard
      let values = array(raw, path: episodeRootJSONPointer("observations"), violations: &violations)
    else {
      return [:]
    }
    validateCollectionLimit(
      values, path: episodeRootJSONPointer("observations"), maximum: 128, violations: &violations)
    if values.isEmpty {
      append(
        "observations_missing",
        path: episodeRootJSONPointer("observations"),
        message: "Паспорт должен ссылаться хотя бы на одно инструментальное наблюдение.",
        to: &violations
      )
    }
    var result: [String: ObservationSnapshot] = [:]
    for (index, value) in values.prefix(128).enumerated() {
      let path = episodeRootJSONPointer("observations/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["observation_id", "artifact_id", "contribution_id"],
        path: path,
        violations: &violations
      )
      let observationID = string(
        object["observation_id"], path: "\(path)/observation_id", violations: &violations)
      validateTechnicalIdentifier(
        observationID, path: "\(path)/observation_id", violations: &violations)
      let artifactID = string(
        object["artifact_id"],
        path: "\(path)/artifact_id",
        violations: &violations
      )
      validateArtifactReference(
        artifactID,
        expectedKind: "observation",
        path: "\(path)/artifact_id",
        artifacts: artifacts,
        violations: &violations
      )
      let contributionID = string(
        object["contribution_id"], path: "\(path)/contribution_id", violations: &violations)
      if let contributionID, contributions[contributionID] == nil {
        append(
          "dangling_contribution_reference",
          path: "\(path)/contribution_id",
          message: "Наблюдение ссылается на неизвестный вклад.",
          to: &violations
        )
      }
      if let observationID {
        if result[observationID] != nil {
          append(
            "duplicate_identifier",
            path: "\(path)/observation_id",
            message: "Идентификатор наблюдения повторяется.",
            to: &violations
          )
        } else {
          result[observationID] = ObservationSnapshot(identifier: observationID)
        }
      }
    }
    return result
  }

  private static func validateVerification(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    roles: [String: RoleSnapshot],
    contributions: [String: ContributionSnapshot],
    observations: [String: ObservationSnapshot],
    violations: inout [EpisodePassportViolation]
  ) -> String? {
    guard
      let object = object(
        raw, path: episodeRootJSONPointer("verification"), violations: &violations)
    else {
      return nil
    }
    validateExactKeys(
      object,
      expected: [
        "verification_id", "artifact_id", "role_id", "contribution_ids", "observation_ids",
      ],
      path: episodeRootJSONPointer("verification"),
      violations: &violations
    )
    let verificationID = string(
      object["verification_id"], path: episodeRootJSONPointer("verification/verification_id"),
      violations: &violations)
    validateTechnicalIdentifier(
      verificationID, path: episodeRootJSONPointer("verification/verification_id"),
      violations: &violations)
    let artifactID = string(
      object["artifact_id"], path: episodeRootJSONPointer("verification/artifact_id"),
      violations: &violations)
    validateArtifactReference(
      artifactID,
      expectedKind: "verification",
      path: episodeRootJSONPointer("verification/artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
    let roleID = string(
      object["role_id"], path: episodeRootJSONPointer("verification/role_id"),
      violations: &violations)
    validateRoleReference(
      roleID,
      expectedKind: "verifier",
      path: episodeRootJSONPointer("verification/role_id"),
      roles: roles,
      violations: &violations
    )
    let contributionIDs = stringArray(
      object["contribution_ids"],
      path: episodeRootJSONPointer("verification/contribution_ids"),
      maximum: 64,
      violations: &violations
    )
    validateRequiredReferences(
      contributionIDs,
      path: episodeRootJSONPointer("verification/contribution_ids"),
      known: Set(contributions.keys),
      danglingCode: "dangling_contribution_reference",
      label: "вклад",
      violations: &violations
    )
    let observationIDs = stringArray(
      object["observation_ids"],
      path: episodeRootJSONPointer("verification/observation_ids"),
      maximum: 128,
      violations: &violations
    )
    validateRequiredReferences(
      observationIDs,
      path: episodeRootJSONPointer("verification/observation_ids"),
      known: Set(observations.keys),
      danglingCode: "dangling_observation_reference",
      label: "наблюдение",
      violations: &violations
    )
    return verificationID
  }

  private static func validateSelection(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    roles: [String: RoleSnapshot],
    contributions: [String: ContributionSnapshot],
    verificationID: String?,
    violations: inout [EpisodePassportViolation]
  ) -> String? {
    guard
      let object = object(raw, path: episodeRootJSONPointer("selection"), violations: &violations)
    else {
      return nil
    }
    validateExactKeys(
      object,
      expected: [
        "selection_id", "artifact_id", "role_id", "verification_id",
        "considered_contribution_ids", "basis",
      ],
      path: episodeRootJSONPointer("selection"),
      violations: &violations
    )
    let selectionID = string(
      object["selection_id"], path: episodeRootJSONPointer("selection/selection_id"),
      violations: &violations)
    validateTechnicalIdentifier(
      selectionID, path: episodeRootJSONPointer("selection/selection_id"), violations: &violations)
    let artifactID = string(
      object["artifact_id"], path: episodeRootJSONPointer("selection/artifact_id"),
      violations: &violations)
    validateArtifactReference(
      artifactID,
      expectedKind: "selection",
      path: episodeRootJSONPointer("selection/artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
    let roleID = string(
      object["role_id"], path: episodeRootJSONPointer("selection/role_id"), violations: &violations)
    validateRoleReference(
      roleID,
      expectedKind: "selector",
      path: episodeRootJSONPointer("selection/role_id"),
      roles: roles,
      violations: &violations
    )
    let referencedVerificationID = string(
      object["verification_id"],
      path: episodeRootJSONPointer("selection/verification_id"),
      violations: &violations
    )
    if let referencedVerificationID,
      referencedVerificationID != verificationID
    {
      append(
        "dangling_verification_reference",
        path: episodeRootJSONPointer("selection/verification_id"),
        message: "Решение выбора ссылается не на объявленную проверку.",
        to: &violations
      )
    }
    let considered = stringArray(
      object["considered_contribution_ids"],
      path: episodeRootJSONPointer("selection/considered_contribution_ids"),
      maximum: 64,
      violations: &violations
    )
    validateRequiredReferences(
      considered,
      path: episodeRootJSONPointer("selection/considered_contribution_ids"),
      known: Set(contributions.keys),
      danglingCode: "dangling_contribution_reference",
      label: "вклад",
      violations: &violations
    )
    let basis = string(
      object["basis"], path: episodeRootJSONPointer("selection/basis"), violations: &violations)
    if let basis, basis != "verified_evidence" {
      append(
        "assertion_vote_forbidden",
        path: episodeRootJSONPointer("selection/basis"),
        message: "Число совпавших утверждений не заменяет проверяемое основание выбора.",
        to: &violations
      )
    }
    return selectionID
  }

  private static func validateStop(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    selectionID: String?,
    violations: inout [EpisodePassportViolation]
  ) {
    guard let object = object(raw, path: episodeRootJSONPointer("stop"), violations: &violations)
    else { return }
    validateExactKeys(
      object,
      expected: ["stop_id", "artifact_id", "selection_id"],
      path: episodeRootJSONPointer("stop"),
      violations: &violations
    )
    let stopID = string(
      object["stop_id"], path: episodeRootJSONPointer("stop/stop_id"), violations: &violations)
    validateTechnicalIdentifier(
      stopID, path: episodeRootJSONPointer("stop/stop_id"), violations: &violations)
    let artifactID = string(
      object["artifact_id"],
      path: episodeRootJSONPointer("stop/artifact_id"),
      violations: &violations
    )
    validateArtifactReference(
      artifactID,
      expectedKind: "stop",
      path: episodeRootJSONPointer("stop/artifact_id"),
      artifacts: artifacts,
      violations: &violations
    )
    let referencedSelectionID = string(
      object["selection_id"], path: episodeRootJSONPointer("stop/selection_id"),
      violations: &violations)
    if let referencedSelectionID, referencedSelectionID != selectionID {
      append(
        "dangling_selection_reference",
        path: episodeRootJSONPointer("stop/selection_id"),
        message: "Условие остановки ссылается не на объявленное решение выбора.",
        to: &violations
      )
    }
  }

  private static func validateHandoff(
    _ raw: Any?,
    artifacts: [String: ArtifactSnapshot],
    violations: inout [EpisodePassportViolation]
  ) {
    guard let object = object(raw, path: episodeRootJSONPointer("handoff"), violations: &violations)
    else { return }
    validateExactKeys(
      object,
      expected: ["artifact_ids"],
      path: episodeRootJSONPointer("handoff"),
      violations: &violations
    )
    guard
      let artifactIDs = stringArray(
        object["artifact_ids"],
        path: episodeRootJSONPointer("handoff/artifact_ids"),
        maximum: 128,
        violations: &violations
      )
    else { return }
    if artifactIDs.isEmpty {
      append(
        "handoff_missing",
        path: episodeRootJSONPointer("handoff/artifact_ids"),
        message: "Межсессионная передача должна перечислять сохраняемые артефакты.",
        to: &violations
      )
    }
    var unique: Set<String> = []
    for (index, identifier) in artifactIDs.enumerated() {
      let path = episodeRootJSONPointer("handoff/artifact_ids/\(index)")
      if !unique.insert(identifier).inserted {
        append(
          "duplicate_reference",
          path: path,
          message: "Ссылка передачи повторяется.",
          to: &violations
        )
      }
      guard let artifact = artifacts[identifier] else {
        append(
          "dangling_artifact_reference",
          path: path,
          message: "Ссылка передачи не разрешается в реестре артефактов.",
          to: &violations
        )
        continue
      }
      if artifact.persistence != "persisted" {
        append(
          "handoff_unpersisted_artifact",
          path: path,
          message: "Передача между сессиями допускает только сохранённый артефакт.",
          to: &violations
        )
      }
    }
  }

  private static func validateEvidencePolicy(
    _ raw: Any?,
    violations: inout [EpisodePassportViolation]
  ) {
    guard
      let object = object(
        raw, path: episodeRootJSONPointer("evidence_policy"), violations: &violations)
    else {
      return
    }
    validateExactKeys(
      object,
      expected: ["agreement_is_evidence", "independence_inferred_from_count"],
      path: episodeRootJSONPointer("evidence_policy"),
      violations: &violations
    )
    let agreement = boolean(
      object["agreement_is_evidence"],
      path: episodeRootJSONPointer("evidence_policy/agreement_is_evidence"),
      violations: &violations
    )
    if agreement != false {
      append(
        "agreement_as_evidence_forbidden",
        path: episodeRootJSONPointer("evidence_policy/agreement_is_evidence"),
        message: "Совпадение утверждений не является самостоятельным доказательством.",
        to: &violations
      )
    }
    let independence = boolean(
      object["independence_inferred_from_count"],
      path: episodeRootJSONPointer("evidence_policy/independence_inferred_from_count"),
      violations: &violations
    )
    if independence != false {
      append(
        "independence_from_count_forbidden",
        path: episodeRootJSONPointer("evidence_policy/independence_inferred_from_count"),
        message: "Число вкладов не доказывает их независимость.",
        to: &violations
      )
    }
  }

  private static func validateArtifactReference(
    _ identifier: String?,
    expectedKind: String,
    path: String,
    artifacts: [String: ArtifactSnapshot],
    violations: inout [EpisodePassportViolation]
  ) {
    guard let identifier else { return }
    validateTechnicalIdentifier(identifier, path: path, violations: &violations)
    guard let artifact = artifacts[identifier] else {
      append(
        "dangling_artifact_reference",
        path: path,
        message: "Ссылка не разрешается в реестре артефактов.",
        to: &violations
      )
      return
    }
    if artifact.kind != expectedKind {
      append(
        "artifact_kind_mismatch",
        path: path,
        message: "Ссылка указывает на артефакт другого типа.",
        to: &violations
      )
    }
  }

  private static func validateRoleReference(
    _ identifier: String?,
    expectedKind: String,
    path: String,
    roles: [String: RoleSnapshot],
    violations: inout [EpisodePassportViolation]
  ) {
    guard let identifier else { return }
    validateTechnicalIdentifier(identifier, path: path, violations: &violations)
    guard let role = roles[identifier] else {
      append(
        "dangling_role_reference",
        path: path,
        message: "Ссылка на роль не разрешается.",
        to: &violations
      )
      return
    }
    if role.kind != expectedKind {
      append(
        "role_kind_mismatch",
        path: path,
        message: "Ссылка указывает на роль другого типа.",
        to: &violations
      )
    }
  }

  private static func validateHypothesisReferences(
    _ identifiers: [String]?,
    path: String,
    hypotheses: Set<String>,
    violations: inout [EpisodePassportViolation]
  ) {
    guard let identifiers else { return }
    var unique: Set<String> = []
    for (index, identifier) in identifiers.enumerated() {
      let itemPath = "\(path)/\(index)"
      validateTechnicalIdentifier(identifier, path: itemPath, violations: &violations)
      if !unique.insert(identifier).inserted {
        append(
          "duplicate_reference",
          path: itemPath,
          message: "Ссылка на гипотезу повторяется.",
          to: &violations
        )
      }
      if !hypotheses.contains(identifier) {
        append(
          "dangling_hypothesis_reference",
          path: itemPath,
          message: "Ссылка на гипотезу не разрешается.",
          to: &violations
        )
      }
    }
  }

  private static func validateRequiredReferences(
    _ identifiers: [String]?,
    path: String,
    known: Set<String>,
    danglingCode: String,
    label: String,
    violations: inout [EpisodePassportViolation]
  ) {
    guard let identifiers else { return }
    if identifiers.isEmpty {
      append(
        "references_missing",
        path: path,
        message: "Список ссылок не должен быть пустым.",
        to: &violations
      )
    }
    var unique: Set<String> = []
    for (index, identifier) in identifiers.enumerated() {
      let itemPath = "\(path)/\(index)"
      validateTechnicalIdentifier(identifier, path: itemPath, violations: &violations)
      if !unique.insert(identifier).inserted {
        append(
          "duplicate_reference",
          path: itemPath,
          message: "Ссылка повторяется.",
          to: &violations
        )
      }
      if !known.contains(identifier) {
        append(
          danglingCode,
          path: itemPath,
          message: "Ссылка на \(label) не разрешается.",
          to: &violations
        )
      }
    }
  }

  private static func validateExactKeys(
    _ object: [String: Any],
    expected: Set<String>,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) {
    let actual = Set(object.keys)
    for field in actual.subtracting(expected).sorted() {
      append(
        "unknown_field",
        path: pointer(path, field),
        message: "Объект содержит неизвестное поле.",
        to: &violations
      )
    }
    for field in expected.subtracting(actual).sorted() {
      append(
        "missing_field",
        path: pointer(path, field),
        message: "Обязательное поле отсутствует.",
        to: &violations
      )
    }
  }

  private static func validateTechnicalIdentifier(
    _ value: String?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) {
    guard let value else { return }
    if !isTechnicalIdentifier(value) {
      append(
        "invalid_identifier",
        path: path,
        message: "Значение не соответствует техническому идентификатору версии 1.",
        to: &violations
      )
    }
  }

  private static func validateCollectionLimit(
    _ values: [Any],
    path: String,
    maximum: Int,
    violations: inout [EpisodePassportViolation]
  ) {
    if values.count > maximum {
      append(
        "collection_limit_exceeded",
        path: path,
        message: "Коллекция превышает конечный предел версии 1.",
        to: &violations
      )
    }
  }

  private static func object(
    _ raw: Any?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) -> [String: Any]? {
    guard let raw else { return nil }
    guard let value = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: path,
        message: "Поле должно быть объектом.",
        to: &violations
      )
      return nil
    }
    return value
  }

  private static func array(
    _ raw: Any?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) -> [Any]? {
    guard let raw else { return nil }
    guard let value = raw as? [Any] else {
      append(
        "invalid_type",
        path: path,
        message: "Поле должно быть массивом.",
        to: &violations
      )
      return nil
    }
    return value
  }

  private static func string(
    _ raw: Any?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) -> String? {
    guard let raw else { return nil }
    guard let value = raw as? String else {
      append(
        "invalid_type",
        path: path,
        message: "Поле должно быть строкой.",
        to: &violations
      )
      return nil
    }
    return value
  }

  private static func integer(
    _ raw: Any?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) -> Int? {
    guard let raw else { return nil }
    guard let number = raw as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID(),
      let value = Int(number.stringValue)
    else {
      append(
        "invalid_type",
        path: path,
        message: "Поле должно быть целым числом.",
        to: &violations
      )
      return nil
    }
    return value
  }

  private static func boolean(
    _ raw: Any?,
    path: String,
    violations: inout [EpisodePassportViolation]
  ) -> Bool? {
    guard let raw else { return nil }
    guard let number = raw as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
      append(
        "invalid_type",
        path: path,
        message: "Поле должно быть логическим значением.",
        to: &violations
      )
      return nil
    }
    return number.boolValue
  }

  private static func stringArray(
    _ raw: Any?,
    path: String,
    maximum: Int,
    violations: inout [EpisodePassportViolation]
  ) -> [String]? {
    guard let values = array(raw, path: path, violations: &violations) else { return nil }
    validateCollectionLimit(values, path: path, maximum: maximum, violations: &violations)
    var result: [String] = []
    for (index, value) in values.prefix(maximum).enumerated() {
      if let item = string(value, path: "\(path)/\(index)", violations: &violations) {
        result.append(item)
      }
    }
    return result
  }

  private static func append(
    _ code: String,
    path: String,
    message: String,
    to violations: inout [EpisodePassportViolation]
  ) {
    violations.append(EpisodePassportViolation(code: code, path: path, message: message))
  }

  private static func pointer(_ base: String, _ field: String) -> String {
    let escaped = field.replacingOccurrences(
      of: episodeTildeMarker,
      with: episodeTildeMarker + "0"
    )
    .replacingOccurrences(
      of: episodeJSONPointerSeparator,
      with: episodeTildeMarker + "1"
    )
    return base + episodeJSONPointerSeparator + escaped
  }

  private static func isTechnicalIdentifier(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard !bytes.isEmpty, bytes.count <= 128, String(bytes: bytes, encoding: .utf8) == value else {
      return false
    }
    let isAlphaNumeric: (UInt8) -> Bool = { byte in
      (0x61...0x7A).contains(byte) || (0x30...0x39).contains(byte)
    }
    guard let first = bytes.first, isAlphaNumeric(first) else { return false }
    return bytes.allSatisfy { byte in
      isAlphaNumeric(byte) || [0x2E, 0x5F, 0x2D].contains(byte)
    }
  }

  private static func isSHA256(_ value: String) -> Bool {
    let bytes = Array(value.utf8)
    guard bytes.count == 71, bytes.starts(with: Array("sha256:".utf8)) else { return false }
    return bytes.dropFirst(7).allSatisfy { byte in
      (0x30...0x39).contains(byte) || (0x61...0x66).contains(byte)
    }
  }
}

private enum EpisodeJSONScanError: Error {
  case invalidJSON
  case structureLimitExceeded
}

private struct EpisodeJSONDuplicateKeyDetector {
  private static let maximumDepth = 64
  private static let maximumNodeCount = 10_000

  private let bytes: [UInt8]
  private var index = 0
  private var nodeCount = 0
  private var duplicatePaths: [String] = []

  init(data: Data) {
    bytes = Array(data)
  }

  mutating func scan() throws -> [String] {
    skipWhitespace()
    try parseValue(path: "", depth: 0)
    skipWhitespace()
    guard index == bytes.count else { throw EpisodeJSONScanError.invalidJSON }
    return duplicatePaths
  }

  private mutating func parseValue(path: String, depth: Int) throws {
    guard depth <= Self.maximumDepth, nodeCount < Self.maximumNodeCount else {
      throw EpisodeJSONScanError.structureLimitExceeded
    }
    nodeCount += 1
    skipWhitespace()
    guard index < bytes.count else { throw EpisodeJSONScanError.invalidJSON }
    switch bytes[index] {
    case 0x7B:
      try parseObject(path: path, depth: depth)
    case 0x5B:
      try parseArray(path: path, depth: depth)
    case 0x22:
      _ = try parseString()
    case 0x74:
      try parseLiteral("true")
    case 0x66:
      try parseLiteral("false")
    case 0x6E:
      try parseLiteral("null")
    case 0x2D, 0x30...0x39:
      try parseNumber()
    default:
      throw EpisodeJSONScanError.invalidJSON
    }
  }

  private mutating func parseObject(path: String, depth: Int) throws {
    try expect(0x7B)
    skipWhitespace()
    if consume(0x7D) { return }
    var keys: Set<String> = []
    while true {
      skipWhitespace()
      let key = try parseString()
      let keyPath = pointer(path, key)
      if !keys.insert(key).inserted {
        duplicatePaths.append(keyPath)
      }
      skipWhitespace()
      try expect(0x3A)
      try parseValue(path: keyPath, depth: depth + 1)
      skipWhitespace()
      if consume(0x7D) { return }
      try expect(0x2C)
    }
  }

  private mutating func parseArray(path: String, depth: Int) throws {
    try expect(0x5B)
    skipWhitespace()
    if consume(0x5D) { return }
    var itemIndex = 0
    while true {
      try parseValue(path: path + episodeRootJSONPointer("\(itemIndex)"), depth: depth + 1)
      itemIndex += 1
      skipWhitespace()
      if consume(0x5D) { return }
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
          throw EpisodeJSONScanError.invalidJSON
        }
        return value
      }
      if byte < 0x20 { throw EpisodeJSONScanError.invalidJSON }
      if byte == 0x5C {
        guard index < bytes.count else { throw EpisodeJSONScanError.invalidJSON }
        let escape = bytes[index]
        index += 1
        if escape == 0x75 {
          guard index + 4 <= bytes.count else { throw EpisodeJSONScanError.invalidJSON }
          for digit in bytes[index..<(index + 4)] where !isHexDigit(digit) {
            throw EpisodeJSONScanError.invalidJSON
          }
          index += 4
        }
      }
    }
    throw EpisodeJSONScanError.invalidJSON
  }

  private mutating func parseNumber() throws {
    let start = index
    while index < bytes.count, !isDelimiter(bytes[index]) {
      index += 1
    }
    guard index > start else { throw EpisodeJSONScanError.invalidJSON }
    let data = Data(bytes[start..<index])
    _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  private mutating func parseLiteral(_ value: String) throws {
    let literal = Array(value.utf8)
    guard index + literal.count <= bytes.count,
      Array(bytes[index..<(index + literal.count)]) == literal
    else {
      throw EpisodeJSONScanError.invalidJSON
    }
    index += literal.count
  }

  private mutating func expect(_ byte: UInt8) throws {
    guard consume(byte) else { throw EpisodeJSONScanError.invalidJSON }
  }

  private mutating func consume(_ byte: UInt8) -> Bool {
    guard index < bytes.count, bytes[index] == byte else { return false }
    index += 1
    return true
  }

  private mutating func skipWhitespace() {
    while index < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[index]) {
      index += 1
    }
  }

  private func pointer(_ base: String, _ field: String) -> String {
    let escaped = field.replacingOccurrences(
      of: episodeTildeMarker,
      with: episodeTildeMarker + "0"
    )
    .replacingOccurrences(
      of: episodeJSONPointerSeparator,
      with: episodeTildeMarker + "1"
    )
    return base + episodeJSONPointerSeparator + escaped
  }

  private func isDelimiter(_ byte: UInt8) -> Bool {
    [0x20, 0x09, 0x0A, 0x0D, 0x2C, 0x5D, 0x7D].contains(byte)
  }

  private func isHexDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }
}
