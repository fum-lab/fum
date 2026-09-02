import CoreFoundation
import CryptoKit
import Foundation

private let compositionMaximumEnvelopeBytes = 1_048_576

public enum RepositoryCompositionSchemaError: Error, CustomStringConvertible, Sendable {
  case missingResource
  case resourceTooLarge(Int)

  public var description: String {
    switch self {
    case .missingResource:
      "Схема паспорта репозиторной композиции отсутствует."
    case .resourceTooLarge(let size):
      "Схема паспорта репозиторной композиции превышает допустимый размер: \(size)."
    }
  }
}

public enum RepositoryCompositionSchema {
  public static func load() throws -> Data {
    let url =
      Bundle.module.url(
        forResource: "repository-composition-v1.schema",
        withExtension: "json",
        subdirectory: "Фикстуры/РепозиторнаяКомпозиция"
      )
      ?? Bundle.module.url(
        forResource: "repository-composition-v1.schema",
        withExtension: "json",
        subdirectory: "РепозиторнаяКомпозиция"
      )
      ?? Bundle.module.url(
        forResource: "repository-composition-v1.schema",
        withExtension: "json"
      )
    guard let url else { throw RepositoryCompositionSchemaError.missingResource }
    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    guard let size = values.fileSize, size <= compositionMaximumEnvelopeBytes else {
      throw RepositoryCompositionSchemaError.resourceTooLarge(values.fileSize ?? -1)
    }
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard data.count <= compositionMaximumEnvelopeBytes else {
      throw RepositoryCompositionSchemaError.resourceTooLarge(data.count)
    }
    return data
  }
}

public enum RepositoryCompositionAccessLevel: String, Codable, Sendable {
  case `public`
  case restricted
  case `private`
  case closed

  fileprivate var restrictionRank: Int {
    switch self {
    case .public: 0
    case .restricted: 1
    case .private: 2
    case .closed: 3
    }
  }
}

public enum RepositoryCompositionChildKind: String, Codable, Sendable {
  case stepBranch = "step_branch"
  case specializedSubnode = "specialized_subnode"
  case project
}

public struct RepositoryCompositionHandoff: Codable, Equatable, Sendable {
  public let targetRepositoryID: String
  public let targetRef: String
  public let requiredCheckIDs: [String]

  enum CodingKeys: String, CodingKey {
    case targetRepositoryID = "target_repository_id"
    case targetRef = "target_ref"
    case requiredCheckIDs = "required_check_ids"
  }
}

public struct RepositoryCompositionNestedSubmodule: Codable, Equatable, Sendable {
  public let repositoryID: String
  public let submodulePath: String

  enum CodingKeys: String, CodingKey {
    case repositoryID = "repository_id"
    case submodulePath = "submodule_path"
  }
}

public struct RepositoryCompositionParentRepository: Codable, Equatable, Sendable {
  public let repositoryID: String
  public let repositoryURL: String
  public let snapshotOID: String
  public let liveRef: String
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel

  enum CodingKeys: String, CodingKey {
    case repositoryID = "repository_id"
    case repositoryURL = "repository_url"
    case snapshotOID = "snapshot_oid"
    case liveRef = "live_ref"
    case accessLevel = "access_level"
    case publicationBoundary = "publication_boundary"
  }
}

public struct RepositoryCompositionChild: Codable, Equatable, Sendable {
  public let entryID: String
  public let kind: RepositoryCompositionChildKind
  public let nodeID: String?
  public let projectID: String?
  public let targetRepositoryID: String?
  public let repositoryID: String?
  public let repositoryURL: String?
  public let upstreamRepositoryID: String?
  public let baseOID: String?
  public let liveRef: String
  public let submodulePath: String?
  public let gitlinkOID: String?
  public let snapshotMode: String?
  public let writerMode: String?
  public let nestedSubmodules: [RepositoryCompositionNestedSubmodule]?
  public let accessLevel: RepositoryCompositionAccessLevel
  public let publicationBoundary: RepositoryCompositionAccessLevel
  public let checks: [String]
  public let handoff: RepositoryCompositionHandoff

  enum CodingKeys: String, CodingKey {
    case entryID = "entry_id"
    case kind
    case nodeID = "node_id"
    case projectID = "project_id"
    case targetRepositoryID = "target_repository_id"
    case repositoryID = "repository_id"
    case repositoryURL = "repository_url"
    case upstreamRepositoryID = "upstream_repository_id"
    case baseOID = "base_oid"
    case liveRef = "live_ref"
    case submodulePath = "submodule_path"
    case gitlinkOID = "gitlink_oid"
    case snapshotMode = "snapshot_mode"
    case writerMode = "writer_mode"
    case nestedSubmodules = "nested_submodules"
    case accessLevel = "access_level"
    case publicationBoundary = "publication_boundary"
    case checks
    case handoff
  }
}

public struct RepositoryCompositionPassport: Codable, Equatable, Sendable {
  public let schemaVersion: Int
  public let passportID: String
  public let compositionID: String
  public let parentRepository: RepositoryCompositionParentRepository
  public let children: [RepositoryCompositionChild]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case passportID = "passport_id"
    case compositionID = "composition_id"
    case parentRepository = "parent_repository"
    case children
  }
}

public struct RepositoryCompositionCheckoutContext: Equatable, Sendable {
  public let snapshotURL: URL?
  public let writerURL: URL?

  public init(snapshotURL: URL? = nil, writerURL: URL? = nil) {
    self.snapshotURL = snapshotURL
    self.writerURL = writerURL
  }
}

public struct RepositoryCompositionContext: Equatable, Sendable {
  public let gitExecutableURL: URL
  public let bareRepositoriesByID: [String: URL]
  public let checkoutsByEntryID: [String: RepositoryCompositionCheckoutContext]

  public init(
    gitExecutableURL: URL,
    bareRepositoriesByID: [String: URL],
    checkoutsByEntryID: [String: RepositoryCompositionCheckoutContext] = [:]
  ) {
    self.gitExecutableURL = gitExecutableURL
    self.bareRepositoriesByID = bareRepositoriesByID
    self.checkoutsByEntryID = checkoutsByEntryID
  }
}

public enum RepositoryCompositionDecision: String, Codable, Sendable {
  case valid
  case invalid
}

public struct RepositoryCompositionViolation: Codable, Equatable, Hashable, Sendable {
  public let code: String
  public let path: String
  public let message: String
}

public struct RepositoryCompositionChildVerification: Codable, Equatable, Sendable {
  public let entryID: String
  public let kind: RepositoryCompositionChildKind
  public let liveRef: String
  public let liveRefOID: String?
  public let gitlinkOID: String?
  public let snapshotHEADOID: String?
  public let snapshotIsDetached: Bool?
  public let snapshotIsClean: Bool?
  public let writerSymbolicRef: String?
  public let writerIsSeparate: Bool?

  enum CodingKeys: String, CodingKey {
    case entryID = "entry_id"
    case kind
    case liveRef = "live_ref"
    case liveRefOID = "live_ref_oid"
    case gitlinkOID = "gitlink_oid"
    case snapshotHEADOID = "snapshot_head_oid"
    case snapshotIsDetached = "snapshot_is_detached"
    case snapshotIsClean = "snapshot_is_clean"
    case writerSymbolicRef = "writer_symbolic_ref"
    case writerIsSeparate = "writer_is_separate"
  }
}

public struct RepositoryCompositionReport: Encodable, Equatable, Sendable {
  public let schemaVersion: Int
  public let compositionID: String?
  public let passportSHA256: String
  public let decision: RepositoryCompositionDecision
  public let violations: [RepositoryCompositionViolation]
  public let childVerifications: [RepositoryCompositionChildVerification]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case compositionID = "composition_id"
    case passportSHA256 = "passport_sha256"
    case decision
    case violations
    case childVerifications = "child_verifications"
  }

  fileprivate init(
    compositionID: String?,
    passportSHA256: String,
    violations: [RepositoryCompositionViolation],
    childVerifications: [RepositoryCompositionChildVerification]
  ) {
    schemaVersion = 1
    self.compositionID = compositionID
    self.passportSHA256 = passportSHA256
    let orderedViolations = Array(Set(violations)).sorted {
      if $0.code != $1.code { return $0.code < $1.code }
      if $0.path != $1.path { return $0.path < $1.path }
      return $0.message < $1.message
    }
    self.violations = orderedViolations
    self.childVerifications = childVerifications.sorted {
      if $0.entryID != $1.entryID { return $0.entryID < $1.entryID }
      return $0.kind.rawValue < $1.kind.rawValue
    }
    decision = orderedViolations.isEmpty ? .valid : .invalid
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    if let compositionID {
      try container.encode(compositionID, forKey: .compositionID)
    } else {
      try container.encodeNil(forKey: .compositionID)
    }
    try container.encode(passportSHA256, forKey: .passportSHA256)
    try container.encode(decision, forKey: .decision)
    try container.encode(violations, forKey: .violations)
    try container.encode(childVerifications, forKey: .childVerifications)
  }

  public func canonicalJSONData() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(self)
  }
}

public enum RepositoryCompositionPreflight {
  public static let maximumEnvelopeBytes = compositionMaximumEnvelopeBytes

  private static let rootKeys: Set<String> = [
    "schema_version", "passport_id", "composition_id", "parent_repository", "children",
  ]
  private static let parentKeys: Set<String> = [
    "repository_id", "repository_url", "snapshot_oid", "live_ref", "access_level",
    "publication_boundary",
  ]
  private static let stepKeys: Set<String> = [
    "entry_id", "kind", "node_id", "target_repository_id", "base_oid", "live_ref",
    "access_level", "publication_boundary", "checks", "handoff",
  ]
  private static let specializedKeys: Set<String> = [
    "entry_id", "kind", "node_id", "repository_id", "repository_url",
    "upstream_repository_id", "base_oid", "live_ref", "submodule_path", "gitlink_oid",
    "snapshot_mode", "writer_mode", "nested_submodules", "access_level",
    "publication_boundary", "checks", "handoff",
  ]
  private static let projectKeys: Set<String> = [
    "entry_id", "kind", "project_id", "repository_id", "repository_url", "base_oid",
    "live_ref", "submodule_path", "gitlink_oid", "snapshot_mode", "writer_mode",
    "nested_submodules", "access_level", "publication_boundary", "checks", "handoff",
  ]
  private static let handoffKeys: Set<String> = [
    "target_repository_id", "target_ref", "required_check_ids",
  ]
  private static let nestedSubmoduleKeys: Set<String> = ["repository_id", "submodule_path"]
  private static let accessLevels: Set<String> = ["public", "restricted", "private", "closed"]

  public static func analyze(
    _ data: Data,
    context: RepositoryCompositionContext
  ) -> RepositoryCompositionReport {
    let digest = SHA256.hash(data: data)
    let passportSHA256 = "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    var violations: [RepositoryCompositionViolation] = []
    var compositionID: String?

    guard !data.isEmpty, data.count <= maximumEnvelopeBytes else {
      append(
        data.isEmpty ? "invalid_json" : "input_limit_exceeded",
        path: "",
        message: data.isEmpty
          ? "Входной JSON паспорта репозиторной композиции отсутствует."
          : "Входной JSON паспорта репозиторной композиции превышает предел версии 1.",
        to: &violations
      )
      return RepositoryCompositionReport(
        compositionID: nil,
        passportSHA256: passportSHA256,
        violations: violations,
        childVerifications: []
      )
    }

    var duplicateKeyDetector = JSONDuplicateKeyDetector(data: data)
    do {
      for path in try duplicateKeyDetector.scan() {
        append(
          "duplicate_key",
          path: path,
          message: "JSON-объект паспорта содержит повторный ключ.",
          to: &violations
        )
      }
    } catch JSONScanError.structureLimitExceeded {
      append(
        "input_limit_exceeded",
        path: "",
        message: "Структура JSON превышает пределы безопасного разбора.",
        to: &violations
      )
    } catch {
      append(
        "invalid_json",
        path: "",
        message: "Вход не является завершённым JSON-объектом.",
        to: &violations
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
      return RepositoryCompositionReport(
        compositionID: nil,
        passportSHA256: passportSHA256,
        violations: violations,
        childVerifications: []
      )
    }

    guard let root = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: "",
        message: "Верхний уровень паспорта должен быть объектом.",
        to: &violations
      )
      return RepositoryCompositionReport(
        compositionID: nil,
        passportSHA256: passportSHA256,
        violations: violations,
        childVerifications: []
      )
    }

    validateExactKeys(
      root,
      expected: rootKeys,
      path: "",
      unknownCode: "unknown_field",
      violations: &violations
    )
    validateSchemaVersion(root["schema_version"], violations: &violations)
    let passportID = string(
      root["passport_id"], path: pathSeparator + "passport_id", violations: &violations)
    compositionID = string(
      root["composition_id"], path: pathSeparator + "composition_id", violations: &violations)
    validateIdentifier(passportID, path: pathSeparator + "passport_id", violations: &violations)
    validateIdentifier(
      compositionID, path: pathSeparator + "composition_id", violations: &violations)
    validateParent(root["parent_repository"], violations: &violations)
    validateChildren(root["children"], violations: &violations)

    let decoder = JSONDecoder()
    guard let passport = try? decoder.decode(RepositoryCompositionPassport.self, from: data) else {
      if violations.isEmpty {
        append(
          "invalid_type",
          path: "",
          message: "Паспорт не соответствует типизированной схеме версии 1.",
          to: &violations
        )
      }
      return RepositoryCompositionReport(
        compositionID: compositionID,
        passportSHA256: passportSHA256,
        violations: violations,
        childVerifications: []
      )
    }

    let mayVerifyGit = violations.isEmpty
    validateSemantics(passport, violations: &violations)
    guard mayVerifyGit else {
      return RepositoryCompositionReport(
        compositionID: compositionID,
        passportSHA256: passportSHA256,
        violations: violations,
        childVerifications: []
      )
    }
    let childVerifications = verifyGit(
      passport,
      context: context,
      violations: &violations
    )
    return RepositoryCompositionReport(
      compositionID: compositionID,
      passportSHA256: passportSHA256,
      violations: violations,
      childVerifications: childVerifications
    )
  }
}

extension RepositoryCompositionPreflight {
  private static let pathSeparator = String(UnicodeScalar(0x2F)!)
  private static let pathSeparatorCharacter = Character(pathSeparator)
  private static let tilde = String(UnicodeScalar(0x7E)!)

  private static func validateSchemaVersion(
    _ raw: Any?,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let number = raw as? NSNumber, !isBoolean(number) else {
      append(
        "invalid_type",
        path: pathSeparator + "schema_version",
        message: "schema_version должен быть целым числом.",
        to: &violations
      )
      return
    }
    let value = number.int64Value
    guard NSNumber(value: value) == number else {
      append(
        "invalid_type",
        path: pathSeparator + "schema_version",
        message: "schema_version должен быть целым числом.",
        to: &violations
      )
      return
    }
    if value != 1 {
      append(
        "unsupported_schema",
        path: pathSeparator + "schema_version",
        message: "Поддерживается только schema_version 1.",
        to: &violations
      )
    }
  }

  private static func validateParent(
    _ raw: Any?,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let parent = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: pathSeparator + "parent_repository",
        message: "Описание родительского репозитория должно быть объектом.",
        to: &violations
      )
      return
    }
    validateExactKeys(
      parent,
      expected: parentKeys,
      path: pathSeparator + "parent_repository",
      unknownCode: "unknown_field",
      violations: &violations
    )
    validateIdentifier(
      string(
        parent["repository_id"],
        path: pathSeparator + "parent_repository/repository_id",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/repository_id",
      violations: &violations
    )
    validateRepositoryURL(
      string(
        parent["repository_url"],
        path: pathSeparator + "parent_repository/repository_url",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/repository_url",
      violations: &violations
    )
    validateOID(
      string(
        parent["snapshot_oid"],
        path: pathSeparator + "parent_repository/snapshot_oid",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/snapshot_oid",
      violations: &violations
    )
    validateLiveRef(
      string(
        parent["live_ref"],
        path: pathSeparator + "parent_repository/live_ref",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/live_ref",
      violations: &violations
    )
    validateAccess(
      string(
        parent["access_level"],
        path: pathSeparator + "parent_repository/access_level",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/access_level",
      violations: &violations
    )
    validateAccess(
      string(
        parent["publication_boundary"],
        path: pathSeparator + "parent_repository/publication_boundary",
        violations: &violations
      ),
      path: pathSeparator + "parent_repository/publication_boundary",
      violations: &violations
    )
  }

  private static func validateChildren(
    _ raw: Any?,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let children = raw as? [Any] else {
      append(
        "invalid_type",
        path: pathSeparator + "children",
        message: "children должен быть массивом.",
        to: &violations
      )
      return
    }
    if children.isEmpty {
      append(
        "collection_empty",
        path: pathSeparator + "children",
        message: "Паспорт должен содержать хотя бы одну дочернюю запись.",
        to: &violations
      )
    }
    if children.count > 256 {
      append(
        "collection_limit_exceeded",
        path: pathSeparator + "children",
        message: "Число дочерних записей превышает предел версии 1.",
        to: &violations
      )
    }

    for (index, value) in children.prefix(256).enumerated() {
      let path = pathSeparator + "children/\(index)"
      guard let child = value as? [String: Any] else {
        append(
          "invalid_type",
          path: path,
          message: "Дочерняя запись должна быть объектом.",
          to: &violations
        )
        continue
      }
      let kind = string(child["kind"], path: path + pathSeparator + "kind", violations: &violations)
      let expected: Set<String>
      switch kind {
      case RepositoryCompositionChildKind.stepBranch.rawValue:
        expected = stepKeys
      case RepositoryCompositionChildKind.specializedSubnode.rawValue:
        expected = specializedKeys
      case RepositoryCompositionChildKind.project.rawValue:
        expected = projectKeys
      case .some:
        expected = stepKeys.union(specializedKeys).union(projectKeys)
        append(
          "invalid_kind",
          path: path + pathSeparator + "kind",
          message: "Неизвестный вид дочерней записи.",
          to: &violations
        )
      case .none:
        expected = stepKeys.union(specializedKeys).union(projectKeys)
      }
      validateExactKeys(
        child,
        expected: expected,
        path: path,
        unknownCode: "field_not_allowed",
        violations: &violations
      )
      validateChild(child, kind: kind, path: path, violations: &violations)
    }
  }

  private static func validateChild(
    _ child: [String: Any],
    kind: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    validateIdentifier(
      string(child["entry_id"], path: path + pathSeparator + "entry_id", violations: &violations),
      path: path + pathSeparator + "entry_id",
      violations: &violations
    )
    if kind == RepositoryCompositionChildKind.stepBranch.rawValue
      || kind == RepositoryCompositionChildKind.specializedSubnode.rawValue
    {
      validateIdentifier(
        string(child["node_id"], path: path + pathSeparator + "node_id", violations: &violations),
        path: path + pathSeparator + "node_id",
        violations: &violations
      )
    }
    if kind == RepositoryCompositionChildKind.project.rawValue {
      validateIdentifier(
        string(
          child["project_id"], path: path + pathSeparator + "project_id", violations: &violations),
        path: path + pathSeparator + "project_id",
        violations: &violations
      )
    }

    if kind == RepositoryCompositionChildKind.stepBranch.rawValue {
      validateIdentifier(
        string(
          child["target_repository_id"],
          path: path + pathSeparator + "target_repository_id",
          violations: &violations
        ),
        path: path + pathSeparator + "target_repository_id",
        violations: &violations
      )
    } else if kind == RepositoryCompositionChildKind.specializedSubnode.rawValue
      || kind == RepositoryCompositionChildKind.project.rawValue
    {
      validateIdentifier(
        string(
          child["repository_id"],
          path: path + pathSeparator + "repository_id",
          violations: &violations
        ),
        path: path + pathSeparator + "repository_id",
        violations: &violations
      )
      validateRepositoryURL(
        string(
          child["repository_url"],
          path: path + pathSeparator + "repository_url",
          violations: &violations
        ),
        path: path + pathSeparator + "repository_url",
        violations: &violations
      )
      validateSubmodulePath(
        string(
          child["submodule_path"],
          path: path + pathSeparator + "submodule_path",
          violations: &violations
        ),
        path: path + pathSeparator + "submodule_path",
        violations: &violations
      )
      validateOID(
        string(
          child["gitlink_oid"],
          path: path + pathSeparator + "gitlink_oid",
          violations: &violations
        ),
        path: path + pathSeparator + "gitlink_oid",
        violations: &violations
      )
      validateLiteral(
        child["snapshot_mode"],
        expected: "detached_read_only",
        path: path + pathSeparator + "snapshot_mode",
        violations: &violations
      )
      validateLiteral(
        child["writer_mode"],
        expected: "separate_clone",
        path: path + pathSeparator + "writer_mode",
        violations: &violations
      )
      validateNestedSubmodules(
        child["nested_submodules"], path: path + pathSeparator + "nested_submodules",
        violations: &violations)
    }

    if kind == RepositoryCompositionChildKind.specializedSubnode.rawValue {
      validateIdentifier(
        string(
          child["upstream_repository_id"],
          path: path + pathSeparator + "upstream_repository_id",
          violations: &violations
        ),
        path: path + pathSeparator + "upstream_repository_id",
        violations: &violations
      )
    }
    if kind == RepositoryCompositionChildKind.stepBranch.rawValue
      || kind == RepositoryCompositionChildKind.specializedSubnode.rawValue
      || kind == RepositoryCompositionChildKind.project.rawValue
    {
      validateOID(
        string(child["base_oid"], path: path + pathSeparator + "base_oid", violations: &violations),
        path: path + pathSeparator + "base_oid",
        violations: &violations
      )
    }
    validateLiveRef(
      string(child["live_ref"], path: path + pathSeparator + "live_ref", violations: &violations),
      path: path + pathSeparator + "live_ref",
      violations: &violations
    )
    validateAccess(
      string(
        child["access_level"],
        path: path + pathSeparator + "access_level",
        violations: &violations
      ),
      path: path + pathSeparator + "access_level",
      violations: &violations
    )
    validateAccess(
      string(
        child["publication_boundary"],
        path: path + pathSeparator + "publication_boundary",
        violations: &violations
      ),
      path: path + pathSeparator + "publication_boundary",
      violations: &violations
    )
    validateChecks(child["checks"], path: path + pathSeparator + "checks", violations: &violations)
    validateHandoff(
      child["handoff"], path: path + pathSeparator + "handoff", violations: &violations)
  }

  private static func validateNestedSubmodules(
    _ raw: Any?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let nested = raw as? [Any] else {
      append(
        "invalid_type",
        path: path,
        message: "nested_submodules должен быть массивом.",
        to: &violations
      )
      return
    }
    if nested.count > 256 {
      append(
        "collection_limit_exceeded",
        path: path,
        message: "Число вложенных submodule превышает предел версии 1.",
        to: &violations
      )
    }
    for (index, value) in nested.prefix(256).enumerated() {
      let itemPath = path + pathSeparator + "\(index)"
      guard let item = value as? [String: Any] else {
        append(
          "invalid_type",
          path: itemPath,
          message: "Описание вложенного submodule должно быть объектом.",
          to: &violations
        )
        continue
      }
      validateExactKeys(
        item,
        expected: nestedSubmoduleKeys,
        path: itemPath,
        unknownCode: "unknown_field",
        violations: &violations
      )
      validateIdentifier(
        string(
          item["repository_id"],
          path: itemPath + pathSeparator + "repository_id",
          violations: &violations
        ),
        path: itemPath + pathSeparator + "repository_id",
        violations: &violations
      )
      validateSubmodulePath(
        string(
          item["submodule_path"],
          path: itemPath + pathSeparator + "submodule_path",
          violations: &violations
        ),
        path: itemPath + pathSeparator + "submodule_path",
        violations: &violations
      )
    }
  }

  private static func validateChecks(
    _ raw: Any?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let values = raw as? [Any] else {
      append(
        "invalid_type",
        path: path,
        message: "Список проверок должен быть массивом.",
        to: &violations
      )
      return
    }
    if values.isEmpty {
      append(
        "collection_empty",
        path: path,
        message: "Список проверок не должен быть пустым.",
        to: &violations
      )
    }
    if values.count > 64 {
      append(
        "collection_limit_exceeded",
        path: path,
        message: "Число проверок превышает предел версии 1.",
        to: &violations
      )
    }
    var seen: Set<String> = []
    for (index, value) in values.prefix(64).enumerated() {
      let itemPath = path + pathSeparator + "\(index)"
      let identifier = string(value, path: itemPath, violations: &violations)
      validateIdentifier(identifier, path: itemPath, violations: &violations)
      if let identifier, !seen.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: itemPath,
          message: "Идентификатор проверки повторяется.",
          to: &violations
        )
      }
    }
  }

  private static func validateHandoff(
    _ raw: Any?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let raw else { return }
    guard let handoff = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: path,
        message: "Маршрут передачи должен быть объектом.",
        to: &violations
      )
      return
    }
    validateExactKeys(
      handoff,
      expected: handoffKeys,
      path: path,
      unknownCode: "unknown_field",
      violations: &violations
    )
    validateIdentifier(
      string(
        handoff["target_repository_id"],
        path: path + pathSeparator + "target_repository_id",
        violations: &violations
      ),
      path: path + pathSeparator + "target_repository_id",
      violations: &violations
    )
    validateLiveRef(
      string(
        handoff["target_ref"], path: path + pathSeparator + "target_ref", violations: &violations),
      path: path + pathSeparator + "target_ref",
      violations: &violations
    )
    validateChecks(
      handoff["required_check_ids"],
      path: path + pathSeparator + "required_check_ids",
      violations: &violations
    )
  }

  private static func validateExactKeys(
    _ object: [String: Any],
    expected: Set<String>,
    path: String,
    unknownCode: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    for key in expected where object[key] == nil {
      append(
        "missing_field",
        path: pointer(path, key),
        message: "Обязательное поле отсутствует.",
        to: &violations
      )
    }
    for key in object.keys where !expected.contains(key) {
      append(
        unknownCode,
        path: pointer(path, key),
        message: unknownCode == "field_not_allowed"
          ? "Поле неприменимо к этому виду дочерней записи."
          : "Неизвестное поле запрещено закрытой схемой.",
        to: &violations
      )
    }
  }

  private static func string(
    _ raw: Any?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) -> String? {
    guard let raw else { return nil }
    guard let value = raw as? String else {
      append(
        "invalid_type",
        path: path,
        message: "Значение должно быть строкой.",
        to: &violations
      )
      return nil
    }
    return value
  }

  private static func validateIdentifier(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    let scalars = Array(value.unicodeScalars)
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:-")
    guard
      !scalars.isEmpty,
      scalars.count <= 160,
      scalars[0].properties.isAlphabetic || ("0"..."9").contains(Character(scalars[0])),
      scalars.allSatisfy({ allowed.contains($0) })
    else {
      append(
        "invalid_identifier",
        path: path,
        message: "Технический идентификатор не соответствует профилю версии 1.",
        to: &violations
      )
      return
    }
  }

  private static func validateOID(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    let isSupportedLength = value.count == 40 || value.count == 64
    let isLowercaseHex = value.unicodeScalars.allSatisfy {
      ("0"..."9").contains(Character($0)) || ("a"..."f").contains(Character($0))
    }
    if !isSupportedLength || !isLowercaseHex {
      append(
        "invalid_oid",
        path: path,
        message: "Git OID должен быть точным lowercase SHA-1 или SHA-256, а не ref ветки.",
        to: &violations
      )
    }
  }

  private static func validateLiveRef(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    let suffix = value.dropFirst("refs/heads/".count)
    let components = suffix.split(separator: "/", omittingEmptySubsequences: false)
    let forbidden = CharacterSet(charactersIn: " ~^:?*[\\")
    let invalid =
      !value.hasPrefix("refs/heads/")
      || suffix.isEmpty
      || components.contains(where: { component in
        component.isEmpty
          || component == "."
          || component == ".."
          || component.hasPrefix(".")
          || component.hasSuffix(".")
          || component.hasSuffix(".lock")
          || component.unicodeScalars.contains(where: { forbidden.contains($0) })
      })
      || value.contains("..")
      || value.contains("@{")
      || value.hasSuffix("/")
    if invalid {
      append(
        "invalid_ref",
        path: path,
        message: "Живая ветка должна быть полным безопасным ref вида refs/heads/....",
        to: &violations
      )
    }
  }

  private static func validateRepositoryURL(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    guard value.count <= 2_048, let components = URLComponents(string: value),
      let scheme = components.scheme, scheme.lowercased() != "file", components.user == nil,
      components.password == nil
    else {
      append(
        "invalid_repository_url",
        path: path,
        message:
          "Идентичность репозитория должна быть устойчивым абсолютным URI без credentials и машинно-локального file URL.",
        to: &violations
      )
      return
    }
  }

  private static func validateSubmodulePath(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    let components = value.split(separator: "/", omittingEmptySubsequences: false)
    let isInvalid =
      value.isEmpty
      || value.count > 1_024
      || value.hasPrefix("/")
      || value.contains("\\")
      || value.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7F })
      || components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
    if isInvalid {
      append(
        "invalid_path",
        path: path,
        message: "Путь submodule должен быть безопасным относительным путём.",
        to: &violations
      )
    }
  }

  private static func validateAccess(
    _ value: String?,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value else { return }
    if !accessLevels.contains(value) {
      append(
        "invalid_access_level",
        path: path,
        message: "Неизвестный уровень доступа.",
        to: &violations
      )
    }
  }

  private static func validateLiteral(
    _ raw: Any?,
    expected: String,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    guard let value = string(raw, path: path, violations: &violations) else { return }
    if value != expected {
      append(
        "invalid_value",
        path: path,
        message: "Поле должно иметь значение \(expected).",
        to: &violations
      )
    }
  }

  private static func pointer(_ base: String, _ key: String) -> String {
    let escaped = key.replacingOccurrences(of: tilde, with: tilde + "0")
      .replacingOccurrences(of: pathSeparator, with: tilde + "1")
    return base + pathSeparator + escaped
  }

  private static func isBoolean(_ number: NSNumber) -> Bool {
    CFGetTypeID(number) == CFBooleanGetTypeID()
  }

  private static func append(
    _ code: String,
    path: String,
    message: String,
    to violations: inout [RepositoryCompositionViolation]
  ) {
    violations.append(RepositoryCompositionViolation(code: code, path: path, message: message))
  }
}

extension RepositoryCompositionPreflight {
  private struct GitResult {
    let status: Int32
    let output: String
  }

  private static func validateSemantics(
    _ passport: RepositoryCompositionPassport,
    violations: inout [RepositoryCompositionViolation]
  ) {
    if passport.parentRepository.publicationBoundary.restrictionRank
      < passport.parentRepository.accessLevel.restrictionRank
    {
      append(
        "incompatible_access",
        path: pathSeparator + "parent_repository/publication_boundary",
        message: "Публикационная граница не может раскрывать данные шире уровня доступа.",
        to: &violations
      )
    }

    var entryIDs: Set<String> = []
    var repositoryIDs: Set<String> = [passport.parentRepository.repositoryID]
    var submodulePaths: Set<String> = []
    var containment: [String: Set<String>] = [:]
    var graph: [String: Set<String>] = [:]
    let childRepositoryIDs = Set(passport.children.compactMap(\.repositoryID))

    for (index, child) in passport.children.enumerated() {
      let path = pathSeparator + "children/\(index)"
      if !entryIDs.insert(child.entryID).inserted {
        append(
          "duplicate_entry_identity",
          path: path + pathSeparator + "entry_id",
          message: "Идентичность записи дочерней линии повторяется.",
          to: &violations
        )
      }
      if child.publicationBoundary.restrictionRank < child.accessLevel.restrictionRank {
        append(
          "incompatible_access",
          path: path + pathSeparator + "publication_boundary",
          message:
            "Публикационная граница не может раскрывать дочерний репозиторий шире уровня доступа.",
          to: &violations
        )
      }
      if passport.parentRepository.publicationBoundary.restrictionRank
        < child.accessLevel.restrictionRank
      {
        append(
          "incompatible_access",
          path: path + pathSeparator + "access_level",
          message:
            "Доступ дочернего репозитория несовместим с публикационной границей родительской композиции.",
          to: &violations
        )
      }
      if child.handoff.targetRepositoryID != passport.parentRepository.repositoryID {
        append(
          "invalid_handoff_target",
          path: path + pathSeparator + "handoff/target_repository_id",
          message: "Маршрут передачи должен вести в родительский репозиторий композиции.",
          to: &violations
        )
      }
      for (checkIndex, checkID) in child.handoff.requiredCheckIDs.enumerated()
      where !child.checks.contains(checkID) {
        append(
          "unknown_handoff_check",
          path: path + pathSeparator + "handoff/required_check_ids/\(checkIndex)",
          message: "Маршрут передачи ссылается на необъявленную проверку.",
          to: &violations
        )
      }

      guard child.kind != .stepBranch, let repositoryID = child.repositoryID else {
        continue
      }
      if !repositoryIDs.insert(repositoryID).inserted {
        append(
          "duplicate_repository_identity",
          path: path + pathSeparator + "repository_id",
          message: "Идентичность дочернего репозитория повторяется в композиции.",
          to: &violations
        )
      }
      containment[passport.parentRepository.repositoryID, default: []].insert(repositoryID)
      graph[passport.parentRepository.repositoryID, default: []].insert(repositoryID)
      if let upstream = child.upstreamRepositoryID {
        if upstream == passport.parentRepository.repositoryID
          || childRepositoryIDs.contains(upstream)
        {
          append(
            "invalid_upstream_identity",
            path: path + pathSeparator + "upstream_repository_id",
            message:
              "Upstream специализированного подузла должен быть отдельным core-репозиторием, а не самим подузлом или родительской композицией.",
            to: &violations
          )
        }
        containment[upstream, default: []].insert(repositoryID)
      }
      if let submodulePath = child.submodulePath,
        !submodulePaths.insert(submodulePath).inserted
      {
        append(
          "duplicate_submodule_path",
          path: path + pathSeparator + "submodule_path",
          message: "Путь дочернего submodule повторяется в композиции.",
          to: &violations
        )
      }
      var nestedPaths: Set<String> = []
      for (nestedIndex, nested) in (child.nestedSubmodules ?? []).enumerated() {
        let nestedPath = path + pathSeparator + "nested_submodules/\(nestedIndex)/repository_id"
        if !nestedPaths.insert(nested.submodulePath).inserted {
          append(
            "duplicate_submodule_path",
            path: path + pathSeparator + "nested_submodules/\(nestedIndex)/submodule_path",
            message: "Путь вложенного submodule повторяется в дочернем репозитории.",
            to: &violations
          )
        }
        graph[repositoryID, default: []].insert(nested.repositoryID)
        if nested.repositoryID == repositoryID {
          append(
            "recursive_initialization_forbidden",
            path: nestedPath,
            message: "Репозиторий нельзя рекурсивно инициализировать через самого себя.",
            to: &violations
          )
        } else if isReachable(
          from: nested.repositoryID,
          to: repositoryID,
          graph: containment
        ) {
          append(
            "submodule_references_ancestor",
            path: nestedPath,
            message: "Дочерний submodule не может ссылаться на репозиторий-предок.",
            to: &violations
          )
        }
      }
    }

    if containsCycle(graph) {
      append(
        "repository_cycle",
        path: pathSeparator + "children",
        message: "Граф идентичностей репозиториев содержит цикл.",
        to: &violations
      )
    }
  }

  private static func verifyGit(
    _ passport: RepositoryCompositionPassport,
    context: RepositoryCompositionContext,
    violations: inout [RepositoryCompositionViolation]
  ) -> [RepositoryCompositionChildVerification] {
    let parent = passport.parentRepository
    let parentRepository = context.bareRepositoriesByID[parent.repositoryID]
    if let parentRepository {
      validateBareRepository(
        parentRepository,
        identifier: parent.repositoryID,
        executable: context.gitExecutableURL,
        path: pathSeparator + "parent_repository/repository_id",
        violations: &violations
      )
      verifyCommit(
        parent.snapshotOID,
        repository: parentRepository,
        executable: context.gitExecutableURL,
        path: pathSeparator + "parent_repository/snapshot_oid",
        violations: &violations
      )
      _ = verifyLiveRef(
        parent.liveRef,
        repository: parentRepository,
        executable: context.gitExecutableURL,
        path: pathSeparator + "parent_repository/live_ref",
        violations: &violations
      )
    } else {
      append(
        "repository_context_missing",
        path: pathSeparator + "parent_repository/repository_id",
        message: "Runtime-контекст не содержит родительский bare-репозиторий.",
        to: &violations
      )
    }

    verifyObservedNestedTopology(passport, context: context, violations: &violations)

    var verifications: [RepositoryCompositionChildVerification] = []
    for (index, child) in passport.children.enumerated() {
      let path = pathSeparator + "children/\(index)"
      let repositoryID =
        child.kind == .stepBranch
        ? child.targetRepositoryID
        : child.repositoryID
      let repository = repositoryID.flatMap { context.bareRepositoriesByID[$0] }

      if let repository, let repositoryID {
        validateBareRepository(
          repository,
          identifier: repositoryID,
          executable: context.gitExecutableURL,
          path: path + pathSeparator
            + (child.kind == .stepBranch ? "target_repository_id" : "repository_id"),
          violations: &violations
        )
      } else {
        append(
          "repository_context_missing",
          path: path + pathSeparator
            + (child.kind == .stepBranch ? "target_repository_id" : "repository_id"),
          message: "Runtime-контекст не содержит объявленный bare-репозиторий.",
          to: &violations
        )
      }

      let liveRefOID: String?
      if let repository {
        liveRefOID = verifyLiveRef(
          child.liveRef,
          repository: repository,
          executable: context.gitExecutableURL,
          path: path + pathSeparator + "live_ref",
          violations: &violations
        )
        if let baseOID = child.baseOID {
          let baseExists = verifyCommit(
            baseOID,
            repository: repository,
            executable: context.gitExecutableURL,
            path: path + pathSeparator + "base_oid",
            violations: &violations
          )
          if baseExists, let liveRefOID,
            !isAncestor(
              baseOID,
              of: liveRefOID,
              repository: repository,
              executable: context.gitExecutableURL
            )
          {
            append(
              "base_not_ancestor",
              path: path + pathSeparator + "base_oid",
              message: "Базовая ревизия не является предком живой вершины.",
              to: &violations
            )
          }
        }
        if child.kind == .specializedSubnode,
          let upstreamID = child.upstreamRepositoryID,
          let baseOID = child.baseOID
        {
          if let upstream = context.bareRepositoriesByID[upstreamID] {
            let upstreamBaseExists = verifyCommit(
              baseOID,
              repository: upstream,
              executable: context.gitExecutableURL,
              path: path + pathSeparator + "base_oid",
              violations: &violations
            )
            if upstreamBaseExists,
              !treeGitlinks(
                repository: upstream,
                oid: baseOID,
                executable: context.gitExecutableURL
              ).isEmpty
            {
              append(
                "upstream_contains_submodule",
                path: path + pathSeparator + "upstream_repository_id",
                message:
                  "Core-upstream специализированного подузла не должен содержать экземплярные submodule.",
                to: &violations
              )
            }
          } else {
            append(
              "repository_context_missing",
              path: path + pathSeparator + "upstream_repository_id",
              message: "Runtime-контекст не содержит upstream специализированного подузла.",
              to: &violations
            )
          }
        }
      } else {
        liveRefOID = nil
      }

      var snapshotHEADOID: String?
      var snapshotIsDetached: Bool?
      var snapshotIsClean: Bool?
      var writerSymbolicRef: String?
      var writerIsSeparate: Bool?

      if child.kind != .stepBranch, let gitlinkOID = child.gitlinkOID {
        if let repository {
          let gitlinkExists = verifyCommit(
            gitlinkOID,
            repository: repository,
            executable: context.gitExecutableURL,
            path: path + pathSeparator + "gitlink_oid",
            violations: &violations
          )
          if gitlinkExists, let baseOID = child.baseOID,
            !isAncestor(
              baseOID,
              of: gitlinkOID,
              repository: repository,
              executable: context.gitExecutableURL
            )
          {
            append(
              "base_not_gitlink_ancestor",
              path: path + pathSeparator + "gitlink_oid",
              message: "Точный gitlink должен происходить от объявленной базовой ревизии.",
              to: &violations
            )
          }
          if gitlinkExists, let liveRefOID,
            !isAncestor(
              gitlinkOID,
              of: liveRefOID,
              repository: repository,
              executable: context.gitExecutableURL
            )
          {
            append(
              "gitlink_not_live_ancestor",
              path: path + pathSeparator + "gitlink_oid",
              message: "Живой ref должен сохранять объявленный gitlink в своей истории.",
              to: &violations
            )
          }
        }
        if let parentRepository, let repository, let submodulePath = child.submodulePath,
          isValidOID(parent.snapshotOID)
        {
          verifyGitlink(
            declaredOID: gitlinkOID,
            submodulePath: submodulePath,
            parentSnapshotOID: parent.snapshotOID,
            parentRepository: parentRepository,
            childRepository: repository,
            executable: context.gitExecutableURL,
            path: path,
            violations: &violations
          )
        }

        let checkout = context.checkoutsByEntryID[child.entryID]
        if let snapshot = checkout?.snapshotURL {
          snapshotHEADOID = checkoutOutput(
            ["rev-parse", "--verify", "HEAD"],
            checkout: snapshot,
            executable: context.gitExecutableURL
          )
          let symbolic = checkoutResult(
            ["symbolic-ref", "-q", "HEAD"],
            checkout: snapshot,
            executable: context.gitExecutableURL
          )
          snapshotIsDetached = symbolic.status == 1
          let status = checkoutResult(
            ["status", "--porcelain=v1", "--untracked-files=all"],
            checkout: snapshot,
            executable: context.gitExecutableURL
          )
          snapshotIsClean = status.status == 0 && status.output.isEmpty
          let superproject = checkoutOutput(
            ["rev-parse", "--show-superproject-working-tree"],
            checkout: snapshot,
            executable: context.gitExecutableURL
          )
          if snapshotHEADOID != gitlinkOID {
            append(
              "snapshot_oid_mismatch",
              path: path + pathSeparator + "gitlink_oid",
              message: "HEAD снимка не совпадает с объявленным gitlink.",
              to: &violations
            )
          }
          if snapshotIsDetached != true {
            append(
              "snapshot_not_detached",
              path: path + pathSeparator + "snapshot_mode",
              message: "Снимок submodule должен иметь detached HEAD.",
              to: &violations
            )
          }
          if snapshotIsClean != true {
            append(
              "snapshot_not_clean",
              path: path + pathSeparator + "snapshot_mode",
              message: "Снимок submodule должен быть чистым.",
              to: &violations
            )
          }
          if superproject?.isEmpty != false {
            append(
              "snapshot_not_restored_from_parent",
              path: path + pathSeparator + "snapshot_mode",
              message:
                "Checkout снимка должен быть нерекурсивно восстановлен как submodule свежего родительского clone.",
              to: &violations
            )
          }
          if let repository {
            verifyCheckoutOrigin(
              snapshot,
              repository: repository,
              executable: context.gitExecutableURL,
              path: path + pathSeparator + "repository_id",
              code: "snapshot_repository_mismatch",
              message: "Снимок submodule не связан с объявленным bare-репозиторием.",
              violations: &violations
            )
          }
        } else {
          append(
            "snapshot_context_missing",
            path: path + pathSeparator + "snapshot_mode",
            message: "Runtime-контекст не содержит checkout снимка.",
            to: &violations
          )
        }

        if let writer = checkout?.writerURL {
          writerSymbolicRef = checkoutOutput(
            ["symbolic-ref", "-q", "HEAD"],
            checkout: writer,
            executable: context.gitExecutableURL
          )
          if let snapshot = checkout?.snapshotURL {
            let snapshotCommonDirectory = checkoutCommonDirectory(
              snapshot, executable: context.gitExecutableURL)
            let writerCommonDirectory = checkoutCommonDirectory(
              writer, executable: context.gitExecutableURL)
            writerIsSeparate =
              snapshotCommonDirectory != nil && writerCommonDirectory != nil
              && snapshotCommonDirectory != writerCommonDirectory
          } else {
            writerIsSeparate = false
          }
          if writerSymbolicRef != child.liveRef {
            append(
              "writer_ref_mismatch",
              path: path + pathSeparator + "live_ref",
              message: "Пишущий клон не прикреплён к объявленному живому ref.",
              to: &violations
            )
          }
          let writerHEADOID = checkoutOutput(
            ["rev-parse", "--verify", "HEAD"],
            checkout: writer,
            executable: context.gitExecutableURL
          )
          if writerHEADOID != liveRefOID {
            append(
              "writer_oid_mismatch",
              path: path + pathSeparator + "live_ref",
              message: "HEAD пишущего клона не совпадает с вершиной объявленного живого ref.",
              to: &violations
            )
          }
          if writerIsSeparate != true {
            append(
              "writer_not_separate",
              path: path + pathSeparator + "writer_mode",
              message: "Пишущий клон должен быть отделён от checkout снимка.",
              to: &violations
            )
          }
          if let repository {
            verifyCheckoutOrigin(
              writer,
              repository: repository,
              executable: context.gitExecutableURL,
              path: path + pathSeparator + "repository_id",
              code: "writer_repository_mismatch",
              message: "Пишущий клон не связан с объявленным bare-репозиторием.",
              violations: &violations
            )
          }
        } else {
          append(
            "writer_context_missing",
            path: path + pathSeparator + "writer_mode",
            message: "Runtime-контекст не содержит отдельный пишущий клон.",
            to: &violations
          )
        }
      }

      verifications.append(
        RepositoryCompositionChildVerification(
          entryID: child.entryID,
          kind: child.kind,
          liveRef: child.liveRef,
          liveRefOID: liveRefOID,
          gitlinkOID: child.gitlinkOID,
          snapshotHEADOID: snapshotHEADOID,
          snapshotIsDetached: snapshotIsDetached,
          snapshotIsClean: snapshotIsClean,
          writerSymbolicRef: writerSymbolicRef,
          writerIsSeparate: writerIsSeparate
        )
      )
    }
    return verifications
  }

  private static func verifyObservedNestedTopology(
    _ passport: RepositoryCompositionPassport,
    context: RepositoryCompositionContext,
    violations: inout [RepositoryCompositionViolation]
  ) {
    let parentID = passport.parentRepository.repositoryID
    var containment: [String: Set<String>] = [:]
    var observedGraph: [String: Set<String>] = [:]
    for child in passport.children where child.kind != .stepBranch {
      guard let repositoryID = child.repositoryID else { continue }
      containment[parentID, default: []].insert(repositoryID)
      observedGraph[parentID, default: []].insert(repositoryID)
      if let upstream = child.upstreamRepositoryID {
        containment[upstream, default: []].insert(repositoryID)
      }
    }

    for (index, child) in passport.children.enumerated() where child.kind != .stepBranch {
      guard let ownerID = child.repositoryID,
        let repository = context.bareRepositoriesByID[ownerID],
        let gitlinkOID = child.gitlinkOID,
        isValidOID(gitlinkOID)
      else { continue }
      let path = pathSeparator + "children/\(index)"
      var declared: [String: String] = [:]
      for nested in child.nestedSubmodules ?? [] {
        declared[nested.submodulePath] = nested.repositoryID
      }
      let gitlinks = treeGitlinks(
        repository: repository,
        oid: gitlinkOID,
        executable: context.gitExecutableURL
      )
      let moduleURLs = submoduleURLsByPath(
        repository: repository,
        oid: gitlinkOID,
        executable: context.gitExecutableURL
      )

      for (nestedPath, _) in gitlinks {
        guard let rawURL = moduleURLs[nestedPath] else {
          append(
            "submodule_metadata_missing",
            path: path + pathSeparator + "nested_submodules",
            message: "Gitlink дочернего снимка не имеет согласованной записи .gitmodules.",
            to: &violations
          )
          continue
        }
        guard let location = resolveSubmoduleLocation(rawURL, relativeTo: repository),
          let targetID = repositoryID(for: location, context: context)
        else {
          append(
            "unknown_submodule_repository",
            path: path + pathSeparator + "nested_submodules",
            message:
              "Runtime-контекст не связывает фактический URL вложенного submodule с идентичностью.",
            to: &violations
          )
          continue
        }
        observedGraph[ownerID, default: []].insert(targetID)
        if declared[nestedPath] != targetID {
          append(
            "nested_topology_mismatch",
            path: path + pathSeparator + "nested_submodules",
            message: "Декларация вложенных submodule не совпадает с точным Git-деревом снимка.",
            to: &violations
          )
        }
        if targetID == ownerID {
          append(
            "recursive_initialization_forbidden",
            path: path + pathSeparator + "nested_submodules",
            message: "Репозиторий нельзя рекурсивно инициализировать через самого себя.",
            to: &violations
          )
        } else if isReachable(from: targetID, to: ownerID, graph: containment) {
          append(
            "submodule_references_ancestor",
            path: path + pathSeparator + "nested_submodules",
            message: "Дочерний submodule не может ссылаться на репозиторий-предок.",
            to: &violations
          )
        }
      }
      for nestedPath in declared.keys where gitlinks[nestedPath] == nil {
        append(
          "nested_topology_mismatch",
          path: path + pathSeparator + "nested_submodules",
          message: "Декларация вложенных submodule не совпадает с точным Git-деревом снимка.",
          to: &violations
        )
      }
    }

    if containsCycle(observedGraph) {
      append(
        "repository_cycle",
        path: pathSeparator + "children",
        message: "Фактический Git-граф идентичностей репозиториев содержит цикл.",
        to: &violations
      )
    }
  }

  private static func treeGitlinks(
    repository: URL,
    oid: String,
    executable: URL
  ) -> [String: String] {
    guard isValidOID(oid) else { return [:] }
    let result = bareGit(
      ["-c", "core.quotePath=false", "ls-tree", "-r", oid],
      repository: repository,
      executable: executable
    )
    guard result.status == 0 else { return [:] }
    var gitlinks: [String: String] = [:]
    for line in result.output.split(separator: "\n") {
      let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
      guard parts.count == 2 else { continue }
      let header = parts[0].split(separator: " ").map(String.init)
      guard header.count == 3, header[0] == "160000", header[1] == "commit" else {
        continue
      }
      gitlinks[parts[1]] = header[2]
    }
    return gitlinks
  }

  private static func submoduleURLsByPath(
    repository: URL,
    oid: String,
    executable: URL
  ) -> [String: String] {
    let result = bareGit(
      ["show", "\(oid):.gitmodules"],
      repository: repository,
      executable: executable
    )
    guard result.status == 0 else { return [:] }
    var currentName: String?
    var pathsByName: [String: String] = [:]
    var urlsByName: [String: String] = [:]
    for rawLine in result.output.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.hasPrefix("[submodule \"") && line.hasSuffix("\"]") {
        currentName = String(line.dropFirst(12).dropLast(2))
        continue
      }
      guard let currentName, let separator = line.firstIndex(of: "=") else { continue }
      let key = line[..<separator].trimmingCharacters(in: .whitespaces)
      let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
      if key == "path" { pathsByName[currentName] = value }
      if key == "url" { urlsByName[currentName] = value }
    }
    var resultByPath: [String: String] = [:]
    for (name, path) in pathsByName {
      if let url = urlsByName[name] { resultByPath[path] = url }
    }
    return resultByPath
  }

  private static func resolveSubmoduleLocation(_ raw: String, relativeTo repository: URL) -> URL? {
    if let url = URL(string: raw), url.isFileURL { return url.standardizedFileURL }
    if raw.hasPrefix("/") {
      return URL(fileURLWithPath: raw, isDirectory: true).standardizedFileURL
    }
    guard raw.hasPrefix("./") || raw.hasPrefix("../") else { return nil }
    return repository.appendingPathComponent(raw, isDirectory: true).standardizedFileURL
  }

  private static func repositoryID(
    for location: URL,
    context: RepositoryCompositionContext
  ) -> String? {
    let normalized = location.resolvingSymlinksInPath().standardizedFileURL
    return context.bareRepositoriesByID.first { _, repository in
      repository.resolvingSymlinksInPath().standardizedFileURL == normalized
    }?.key
  }

  private static func verifyCheckoutOrigin(
    _ checkout: URL,
    repository: URL,
    executable: URL,
    path: String,
    code: String,
    message: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    let origin = checkoutOutput(
      ["remote", "get-url", "origin"],
      checkout: checkout,
      executable: executable
    )
    if repositoryLocation(origin).map({
      $0.resolvingSymlinksInPath().standardizedFileURL
        == repository.resolvingSymlinksInPath().standardizedFileURL
    }) != true {
      append(code, path: path, message: message, to: &violations)
    }
  }

  private static func checkoutCommonDirectory(_ checkout: URL, executable: URL) -> URL? {
    guard
      let path = checkoutOutput(
        ["rev-parse", "--path-format=absolute", "--git-common-dir"],
        checkout: checkout,
        executable: executable
      )
    else { return nil }
    return URL(fileURLWithPath: path, isDirectory: true)
      .resolvingSymlinksInPath().standardizedFileURL
  }

  private static func validateBareRepository(
    _ repository: URL,
    identifier: String,
    executable: URL,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    let result = bareGit(
      ["rev-parse", "--is-bare-repository"],
      repository: repository,
      executable: executable
    )
    if result.status != 0 || result.output != "true" {
      append(
        "repository_not_bare",
        path: path,
        message: "Контекст идентичности \(identifier) не является локальным bare-репозиторием.",
        to: &violations
      )
    }
  }

  @discardableResult
  private static func verifyCommit(
    _ oid: String,
    repository: URL,
    executable: URL,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) -> Bool {
    guard isValidOID(oid) else { return false }
    let result = bareGit(["cat-file", "-t", oid], repository: repository, executable: executable)
    guard result.status == 0, result.output == "commit" else {
      append(
        "revision_missing",
        path: path,
        message: "Объявленная точная ревизия commit отсутствует в репозитории.",
        to: &violations
      )
      return false
    }
    return true
  }

  private static func verifyLiveRef(
    _ ref: String,
    repository: URL,
    executable: URL,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) -> String? {
    guard isValidLiveRef(ref) else { return nil }
    let result = bareGit(
      ["show-ref", "--verify", "--hash", ref],
      repository: repository,
      executable: executable
    )
    guard result.status == 0, isValidOID(result.output) else {
      append(
        "live_ref_missing",
        path: path,
        message: "Объявленный полный живой ref отсутствует.",
        to: &violations
      )
      return nil
    }
    if bareGit(
      ["cat-file", "-t", result.output], repository: repository, executable: executable
    ).output != "commit" {
      append(
        "live_ref_not_commit",
        path: path,
        message: "Живой ref должен указывать на commit.",
        to: &violations
      )
      return nil
    }
    return result.output
  }

  private static func verifyGitlink(
    declaredOID: String,
    submodulePath: String,
    parentSnapshotOID: String,
    parentRepository: URL,
    childRepository: URL,
    executable: URL,
    path: String,
    violations: inout [RepositoryCompositionViolation]
  ) {
    let result = bareGit(
      ["-c", "core.quotePath=false", "ls-tree", parentSnapshotOID, "--", submodulePath],
      repository: parentRepository,
      executable: executable
    )
    guard result.status == 0, !result.output.isEmpty else {
      append(
        "gitlink_missing",
        path: path + pathSeparator + "submodule_path",
        message: "В точном снимке родителя отсутствует объявленный путь submodule.",
        to: &violations
      )
      return
    }
    let header = result.output.split(separator: "\t", maxSplits: 1).first.map(String.init) ?? ""
    let fields = header.split(separator: " ").map(String.init)
    guard fields.count == 3, fields[0] == "160000", fields[1] == "commit" else {
      append(
        "gitlink_not_commit",
        path: path + pathSeparator + "submodule_path",
        message: "Путь родительского дерева должен быть gitlink режима 160000 на commit.",
        to: &violations
      )
      return
    }
    if fields[2] != declaredOID {
      append(
        "gitlink_mismatch",
        path: path + pathSeparator + "gitlink_oid",
        message: "OID gitlink не совпадает со снимком родительского дерева.",
        to: &violations
      )
    }
    let moduleURLs = submoduleURLsByPath(
      repository: parentRepository,
      oid: parentSnapshotOID,
      executable: executable
    )
    guard let rawURL = moduleURLs[submodulePath],
      let location = resolveSubmoduleLocation(rawURL, relativeTo: parentRepository),
      location.resolvingSymlinksInPath().standardizedFileURL
        == childRepository.resolvingSymlinksInPath().standardizedFileURL
    else {
      append(
        "submodule_metadata_mismatch",
        path: path + pathSeparator + "submodule_path",
        message:
          ".gitmodules точного родительского снимка не восстанавливает путь из объявленного дочернего bare-репозитория.",
        to: &violations
      )
      return
    }
  }

  private static func isAncestor(
    _ ancestor: String,
    of descendant: String,
    repository: URL,
    executable: URL
  ) -> Bool {
    bareGit(
      ["merge-base", "--is-ancestor", ancestor, descendant],
      repository: repository,
      executable: executable
    ).status == 0
  }

  private static func containsCycle(_ graph: [String: Set<String>]) -> Bool {
    enum Mark { case visiting, visited }
    var marks: [String: Mark] = [:]
    func visit(_ node: String) -> Bool {
      if marks[node] == .visiting { return true }
      if marks[node] == .visited { return false }
      marks[node] = .visiting
      for target in graph[node] ?? [] where visit(target) { return true }
      marks[node] = .visited
      return false
    }
    let nodes = Set(graph.keys).union(graph.values.flatMap { $0 })
    return nodes.contains(where: visit)
  }

  private static func isReachable(
    from source: String,
    to target: String,
    graph: [String: Set<String>]
  ) -> Bool {
    var pending = [source]
    var seen: Set<String> = []
    while let node = pending.popLast() {
      guard seen.insert(node).inserted else { continue }
      if node == target { return true }
      pending.append(contentsOf: graph[node] ?? [])
    }
    return false
  }

  private static func repositoryLocation(_ raw: String?) -> URL? {
    guard let raw, !raw.isEmpty else { return nil }
    if let url = URL(string: raw), url.isFileURL { return url }
    return URL(fileURLWithPath: raw, isDirectory: true)
  }

  private static func isValidOID(_ value: String) -> Bool {
    value.range(of: "^(?:[0-9a-f]{40}|[0-9a-f]{64})$", options: .regularExpression) != nil
  }

  private static func isValidLiveRef(_ value: String) -> Bool {
    value.hasPrefix("refs/heads/") && !value.dropFirst("refs/heads/".count).isEmpty
      && value.rangeOfCharacter(from: CharacterSet(charactersIn: " ~^:?*[\\")) == nil
      && !value.contains("..") && !value.contains("//") && !value.hasSuffix("/")
      && !value.hasSuffix(".") && !value.hasSuffix(".lock")
  }

  private static func bareGit(
    _ arguments: [String],
    repository: URL,
    executable: URL
  ) -> GitResult {
    runGit(
      ["--no-replace-objects", "--no-optional-locks", "--git-dir=\(repository.path)"] + arguments,
      executable: executable
    )
  }

  private static func checkoutResult(
    _ arguments: [String],
    checkout: URL,
    executable: URL
  ) -> GitResult {
    runGit(
      ["--no-replace-objects", "--no-optional-locks", "-C", checkout.path] + arguments,
      executable: executable
    )
  }

  private static func checkoutOutput(
    _ arguments: [String],
    checkout: URL,
    executable: URL
  ) -> String? {
    let result = checkoutResult(arguments, checkout: checkout, executable: executable)
    return result.status == 0 ? result.output : nil
  }

  private static func runGit(_ arguments: [String], executable: URL) -> GitResult {
    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    var environment = ProcessInfo.processInfo.environment.filter { key, _ in
      !key.hasPrefix("GIT_")
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] =
      FileManager.default.temporaryDirectory
      .appendingPathComponent("fum-absent-global-gitconfig-\(UUID().uuidString)")
      .path
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["LC_ALL"] = "C"
    process.environment = environment
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
      try? pipe.fileHandleForWriting.close()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      try? pipe.fileHandleForReading.close()
      return GitResult(
        status: process.terminationStatus,
        output: String(data: data, encoding: .utf8)?
          .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      )
    } catch {
      return GitResult(status: -1, output: "")
    }
  }
}
