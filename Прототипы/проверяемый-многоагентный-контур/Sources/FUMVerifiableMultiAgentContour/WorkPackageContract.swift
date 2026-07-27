import CoreFoundation
import CryptoKit
import Darwin
import Foundation

private let jsonPointerSeparator = "/"
private let tildeMarker = "\u{007E}"

private func rootJSONPointer(_ relative: String) -> String {
  jsonPointerSeparator + relative
}

public enum WorkPackageDecision: String, Codable, Sendable {
  case ready
  case splitRequired = "split_required"
}

public struct WorkPackageViolation: Codable, Equatable, Hashable, Sendable {
  public let code: String
  public let path: String
  public let message: String
}

public struct WorkPackageReport: Encodable, Equatable, Sendable {
  public let schemaVersion: Int
  public let packageID: String?
  public let contractSHA256: String
  public let decision: WorkPackageDecision
  public let violations: [WorkPackageViolation]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case packageID = "package_id"
    case contractSHA256 = "contract_sha256"
    case decision
    case violations
  }

  init(
    packageID: String?,
    contractSHA256: String,
    violations: [WorkPackageViolation]
  ) {
    schemaVersion = 1
    self.packageID = packageID
    self.contractSHA256 = contractSHA256
    let ordered = Array(Set(violations)).sorted { left, right in
      if left.code != right.code { return left.code < right.code }
      if left.path != right.path { return left.path < right.path }
      return left.message < right.message
    }
    self.violations = ordered
    decision = ordered.isEmpty ? .ready : .splitRequired
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    if let packageID {
      try container.encode(packageID, forKey: .packageID)
    } else {
      try container.encodeNil(forKey: .packageID)
    }
    try container.encode(contractSHA256, forKey: .contractSHA256)
    try container.encode(decision, forKey: .decision)
    try container.encode(violations, forKey: .violations)
  }

  public func canonicalJSONData() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(self)
  }
}

public enum WorkPackageFixtureError: Error, CustomStringConvertible, Sendable {
  case unknownFixture(String)
  case missingResource(String)
  case missingWorkspace
  case resourceTooLarge(Int)

  public var description: String {
    switch self {
    case .unknownFixture(let identifier):
      "Неизвестная фикстура: \(identifier)."
    case .missingResource(let identifier):
      "Ресурс фикстуры отсутствует: \(identifier)."
    case .missingWorkspace:
      "Рабочая область фикстур отсутствует."
    case .resourceTooLarge(let size):
      "Ресурс фикстуры превышает допустимый размер: \(size)."
    }
  }
}

public enum WorkPackageFixtures {
  public static let identifiers = [
    "ready",
    "split-missing-required-input",
    "split-multiple-deliverables",
    "split-no-reserve",
    "split-unbounded-change-scope",
    "split-unresolved-dependency",
  ]

  public static func load(named identifier: String) throws -> Data {
    guard identifiers.contains(identifier) else {
      throw WorkPackageFixtureError.unknownFixture(identifier)
    }
    let url =
      Bundle.module.url(
        forResource: identifier,
        withExtension: "json",
        subdirectory: "Фикстуры"
      ) ?? Bundle.module.url(forResource: identifier, withExtension: "json")
    guard let url else {
      throw WorkPackageFixtureError.missingResource(identifier)
    }
    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    guard let size = values.fileSize, size <= WorkPackagePreflight.maximumEnvelopeBytes else {
      throw WorkPackageFixtureError.resourceTooLarge(values.fileSize ?? -1)
    }
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    guard data.count <= WorkPackagePreflight.maximumEnvelopeBytes else {
      throw WorkPackageFixtureError.resourceTooLarge(data.count)
    }
    return data
  }

  public static func workspaceRoot() throws -> URL {
    guard
      let url = Bundle.module.url(
        forResource: "РабочаяОбласть",
        withExtension: nil
      )
    else {
      throw WorkPackageFixtureError.missingWorkspace
    }
    return url
  }
}

public enum WorkPackagePreflight {
  public static let maximumEnvelopeBytes = 1_048_576

  private static let maximumInputBytes = 16 * 1_024 * 1_024
  private static let maximumTotalInputBytes = 64 * 1_024 * 1_024
  private static let maximumPlanningUnits = 100_000

  private struct ScopeSnapshot {
    let allowedPaths: [String]
    let excludedPaths: [String]
  }

  private struct StructuralCounts {
    let inputs: Int
    let changes: Int
    let checks: Int
    let handoffArtifacts: Int
  }

  private static let topLevelKeys: Set<String> = [
    "schema_version", "package_id", "goal", "deliverables", "inputs", "change_scope",
    "dependencies", "checks", "handoff", "budget", "preflight",
  ]

  public static func analyze(_ data: Data, workspaceRoot: URL) -> WorkPackageReport {
    let digest = SHA256.hash(data: data)
    let contractSHA256 = "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    var violations: [WorkPackageViolation] = []

    guard !data.isEmpty, data.count <= maximumEnvelopeBytes else {
      let code = data.isEmpty ? "invalid_json" : "input_limit_exceeded"
      append(
        code,
        path: "",
        message: data.isEmpty
          ? "Входной JSON отсутствует."
          : "Входной JSON превышает предел версии 1.",
        to: &violations
      )
      return WorkPackageReport(
        packageID: nil,
        contractSHA256: contractSHA256,
        violations: violations
      )
    }

    var duplicateKeyDetector = JSONDuplicateKeyDetector(data: data)
    do {
      let duplicatePaths = try duplicateKeyDetector.scan()
      for path in duplicatePaths {
        append(
          "duplicate_key",
          path: path,
          message: "JSON-объект содержит повторный ключ.",
          to: &violations
        )
      }
    } catch JSONScanError.structureLimitExceeded {
      append(
        "structure_limit_exceeded",
        path: "",
        message: "Структура JSON превышает предел глубины или числа узлов версии 1.",
        to: &violations
      )
      return WorkPackageReport(
        packageID: nil,
        contractSHA256: contractSHA256,
        violations: violations
      )
    } catch {
      append(
        "invalid_json",
        path: "",
        message: "Вход не является завершённым JSON-объектом.",
        to: &violations
      )
      return WorkPackageReport(
        packageID: nil,
        contractSHA256: contractSHA256,
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
      return WorkPackageReport(
        packageID: nil,
        contractSHA256: contractSHA256,
        violations: violations
      )
    }

    guard let root = raw as? [String: Any] else {
      append(
        "invalid_type",
        path: "",
        message: "Верхний уровень рабочего пакета должен быть объектом.",
        to: &violations
      )
      return WorkPackageReport(
        packageID: nil,
        contractSHA256: contractSHA256,
        violations: violations
      )
    }

    validateExactKeys(root, expected: topLevelKeys, path: "", violations: &violations)
    let packageID = string(
      root["package_id"], path: rootJSONPointer("package_id"), violations: &violations)
    validateSchema(root["schema_version"], violations: &violations)
    validateTechnicalIdentifier(
      packageID, path: rootJSONPointer("package_id"), violations: &violations)
    validateRequiredText(
      root["goal"],
      path: rootJSONPointer("goal"),
      maximumScalars: 4_096,
      violations: &violations
    )
    validateDeliverables(root["deliverables"], violations: &violations)
    let workspaceDescriptor = validateWorkspaceRoot(
      workspaceRoot,
      violations: &violations
    )
    defer {
      if let workspaceDescriptor {
        _ = Darwin.close(workspaceDescriptor)
      }
    }
    validateInputs(
      root["inputs"],
      workspaceDescriptor: workspaceDescriptor,
      violations: &violations
    )
    let scope = validateChangeScope(root["change_scope"], violations: &violations)
    validateDependencies(root["dependencies"], violations: &violations)
    validateChecks(root["checks"], violations: &violations)
    validateHandoff(root["handoff"], scope: scope, violations: &violations)
    validateBudget(
      root["budget"],
      minimums: structuralCounts(root),
      violations: &violations
    )
    validatePreflight(root["preflight"], violations: &violations)

    return WorkPackageReport(
      packageID: packageID,
      contractSHA256: contractSHA256,
      violations: violations
    )
  }

  private static func validateSchema(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) {
    guard
      let version = integer(raw, path: rootJSONPointer("schema_version"), violations: &violations)
    else {
      return
    }
    guard version == 1 else {
      append(
        "unsupported_schema",
        path: rootJSONPointer("schema_version"),
        message: "Поддерживается только schema_version 1.",
        to: &violations
      )
      return
    }
  }

  private static func validateDeliverables(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let values = array(raw, path: rootJSONPointer("deliverables"), violations: &violations)
    else {
      return
    }
    validateCollectionLimit(
      values, path: rootJSONPointer("deliverables"), maximum: 16, violations: &violations)
    if values.count != 1 {
      append(
        values.count > 1 ? "multiple_deliverables" : "primary_delivery_missing",
        path: rootJSONPointer("deliverables"),
        message: "Рабочий пакет должен содержать ровно одну основную поставку.",
        to: &violations
      )
    }

    var identifiers: Set<String> = []
    var primaryCount = 0
    for (index, value) in values.prefix(16).enumerated() {
      let path = rootJSONPointer("deliverables/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["id", "role", "description", "depends_on"],
        path: path,
        violations: &violations
      )
      let identifier = string(object["id"], path: "\(path)/id", violations: &violations)
      validateTechnicalIdentifier(identifier, path: "\(path)/id", violations: &violations)
      if let identifier, !identifiers.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: "\(path)/id",
          message: "Идентификатор поставки повторяется.",
          to: &violations
        )
      }
      let role = string(object["role"], path: "\(path)/role", violations: &violations)
      if role == "primary" { primaryCount += 1 }
      if role != nil, role != "primary", role != "supporting" {
        append(
          "invalid_value",
          path: "\(path)/role",
          message: "Роль поставки должна быть primary или supporting.",
          to: &violations
        )
      }
      validateRequiredText(
        object["description"],
        path: "\(path)/description",
        maximumScalars: 2_048,
        violations: &violations
      )
      if let dependencies = stringArray(
        object["depends_on"],
        path: "\(path)/depends_on",
        maximum: 16,
        violations: &violations
      ), !dependencies.isEmpty {
        append(
          "dependent_deliverable",
          path: "\(path)/depends_on",
          message: "Зависимую поставку нужно вынести в отдельный рабочий пакет.",
          to: &violations
        )
      }
    }
    if primaryCount != 1 {
      append(
        "primary_delivery_missing",
        path: rootJSONPointer("deliverables"),
        message: "Нужна ровно одна поставка с ролью primary.",
        to: &violations
      )
    }
  }

  private static func validateInputs(
    _ raw: Any?,
    workspaceDescriptor: Int32?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let values = array(raw, path: rootJSONPointer("inputs"), violations: &violations) else {
      return
    }
    validateCollectionLimit(
      values, path: rootJSONPointer("inputs"), maximum: 128, violations: &violations)
    if values.isEmpty {
      append(
        "input_manifest_missing",
        path: rootJSONPointer("inputs"),
        message: "Манифест входов не должен быть пустым.",
        to: &violations
      )
    }
    var identifiers: Set<String> = []
    var paths: Set<String> = []
    var totalInputBytes = 0
    for (index, value) in values.prefix(128).enumerated() {
      let path = rootJSONPointer("inputs/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["id", "path", "sha256", "required"],
        path: path,
        violations: &violations
      )
      let identifier = string(object["id"], path: "\(path)/id", violations: &violations)
      validateTechnicalIdentifier(identifier, path: "\(path)/id", violations: &violations)
      if let identifier, !identifiers.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: "\(path)/id",
          message: "Идентификатор входа повторяется.",
          to: &violations
        )
      }
      let inputPath = string(object["path"], path: "\(path)/path", violations: &violations)
      let pathIsValid = validateRelativePath(
        inputPath,
        path: "\(path)/path",
        violations: &violations
      )
      if let inputPath, !paths.insert(inputPath).inserted {
        append(
          "duplicate_path",
          path: "\(path)/path",
          message: "Путь входа повторяется.",
          to: &violations
        )
      }
      let hash = string(object["sha256"], path: "\(path)/sha256", violations: &violations)
      if let hash, !isSHA256(hash) {
        append(
          "invalid_hash",
          path: "\(path)/sha256",
          message: "Хэш входа должен иметь вид sha256:<64 lowercase hex>.",
          to: &violations
        )
      }
      let required = boolean(
        object["required"],
        path: "\(path)/required",
        violations: &violations
      )
      if let inputPath, pathIsValid, let hash, isSHA256(hash), let workspaceDescriptor {
        validateInputFile(
          relativePath: inputPath,
          expectedHash: hash,
          required: required == true,
          workspaceDescriptor: workspaceDescriptor,
          reportPath: path,
          totalInputBytes: &totalInputBytes,
          violations: &violations
        )
      }
    }
  }

  private static func validateWorkspaceRoot(
    _ raw: URL,
    violations: inout [WorkPackageViolation]
  ) -> Int32? {
    let root = raw.standardizedFileURL.resolvingSymlinksInPath()
    let descriptor = root.path.withCString { path in
      Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard descriptor >= 0 else {
      append(
        "workspace_unavailable",
        path: "",
        message: "Явный корень рабочей области нельзя безопасно открыть как каталог.",
        to: &violations
      )
      return nil
    }
    var metadata = stat()
    guard Darwin.fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFDIR else {
      _ = Darwin.close(descriptor)
      append(
        "workspace_unavailable",
        path: "",
        message: "Явный корень рабочей области не является каталогом.",
        to: &violations
      )
      return nil
    }
    return descriptor
  }

  private static func validateInputFile(
    relativePath: String,
    expectedHash: String,
    required: Bool,
    workspaceDescriptor: Int32,
    reportPath: String,
    totalInputBytes: inout Int,
    violations: inout [WorkPackageViolation]
  ) {
    let components = relativePath.split(separator: "/").map(String.init)
    guard let fileName = components.last else { return }
    var currentDescriptor = workspaceDescriptor
    var ownsCurrentDescriptor = false
    for component in components.dropLast() {
      let nextDescriptor = component.withCString { name in
        Darwin.openat(
          currentDescriptor,
          name,
          O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW
        )
      }
      if nextDescriptor < 0 {
        let errorCode = errno
        if ownsCurrentDescriptor { _ = Darwin.close(currentDescriptor) }
        appendInputOpenFailure(
          errorCode,
          required: required,
          reportPath: reportPath,
          violations: &violations
        )
        return
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
    let openError = errno
    if ownsCurrentDescriptor { _ = Darwin.close(currentDescriptor) }
    guard inputDescriptor >= 0 else {
      appendInputOpenFailure(
        openError,
        required: required,
        reportPath: reportPath,
        violations: &violations
      )
      return
    }
    defer { _ = Darwin.close(inputDescriptor) }

    var initialMetadata = stat()
    guard Darwin.fstat(inputDescriptor, &initialMetadata) == 0 else {
      append(
        "input_unreadable",
        path: reportPath,
        message: "Метаданные открытого входа недоступны.",
        to: &violations
      )
      return
    }
    guard initialMetadata.st_mode & S_IFMT == S_IFREG else {
      append(
        "input_not_regular_file",
        path: reportPath,
        message: "Вход должен быть обычным файлом без символических ссылок.",
        to: &violations
      )
      return
    }
    guard initialMetadata.st_size >= 0, initialMetadata.st_size <= maximumInputBytes else {
      append(
        "input_file_limit_exceeded",
        path: reportPath,
        message: "Размер одного входа превышает предел версии 1.",
        to: &violations
      )
      return
    }
    let declaredSize = Int(initialMetadata.st_size)
    let expectedTotal = totalInputBytes.addingReportingOverflow(declaredSize)
    guard !expectedTotal.overflow, expectedTotal.partialValue <= maximumTotalInputBytes else {
      append(
        "input_total_limit_exceeded",
        path: rootJSONPointer("inputs"),
        message: "Суммарный размер входов превышает предел версии 1.",
        to: &violations
      )
      return
    }

    var hasher = SHA256()
    var bytesRead = 0
    var buffer = [UInt8](repeating: 0, count: 64 * 1_024)
    while bytesRead < declaredSize {
      let requestedBytes = min(buffer.count, declaredSize - bytesRead)
      let count = buffer.withUnsafeMutableBytes { storage in
        Darwin.read(inputDescriptor, storage.baseAddress, requestedBytes)
      }
      if count < 0 {
        if errno == EINTR { continue }
        append(
          "input_unreadable",
          path: reportPath,
          message: "Вход нельзя полностью прочитать для проверки хэша.",
          to: &violations
        )
        return
      }
      guard count > 0 else { break }
      bytesRead += count
      totalInputBytes += count
      hasher.update(data: Data(buffer.prefix(count)))
    }

    var finalMetadata = stat()
    guard Darwin.fstat(inputDescriptor, &finalMetadata) == 0 else {
      append(
        "input_unreadable",
        path: reportPath,
        message: "Итоговые метаданные открытого входа недоступны.",
        to: &violations
      )
      return
    }
    let unchanged =
      finalMetadata.st_dev == initialMetadata.st_dev
      && finalMetadata.st_ino == initialMetadata.st_ino
      && finalMetadata.st_size == initialMetadata.st_size
      && finalMetadata.st_size == bytesRead
      && finalMetadata.st_mtimespec.tv_sec == initialMetadata.st_mtimespec.tv_sec
      && finalMetadata.st_mtimespec.tv_nsec == initialMetadata.st_mtimespec.tv_nsec
      && finalMetadata.st_ctimespec.tv_sec == initialMetadata.st_ctimespec.tv_sec
      && finalMetadata.st_ctimespec.tv_nsec == initialMetadata.st_ctimespec.tv_nsec
    guard unchanged else {
      append(
        "input_changed_during_read",
        path: reportPath,
        message: "Вход изменился во время предпусковой проверки.",
        to: &violations
      )
      return
    }

    let actualHash = "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
    if actualHash != expectedHash {
      append(
        "input_hash_mismatch",
        path: "\(reportPath)/sha256",
        message: "Фактический SHA-256 входа не совпадает с манифестом.",
        to: &violations
      )
    }
  }

  private static func appendInputOpenFailure(
    _ errorCode: Int32,
    required: Bool,
    reportPath: String,
    violations: inout [WorkPackageViolation]
  ) {
    if errorCode == ENOENT {
      if required {
        append(
          "required_input_missing",
          path: reportPath,
          message: "Обязательный вход отсутствует в явной рабочей области.",
          to: &violations
        )
      }
    } else if errorCode == ELOOP || errorCode == ENOTDIR {
      append(
        "input_path_unsafe",
        path: "\(reportPath)/path",
        message: "Путь входа содержит символическую ссылку или небезопасный компонент.",
        to: &violations
      )
    } else {
      append(
        "input_unreadable",
        path: reportPath,
        message: "Вход нельзя безопасно открыть для предпусковой проверки.",
        to: &violations
      )
    }
  }

  private static func validateChangeScope(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) -> ScopeSnapshot? {
    guard let object = object(raw, path: rootJSONPointer("change_scope"), violations: &violations)
    else {
      return nil
    }
    validateExactKeys(
      object,
      expected: ["policy", "allowed_paths", "excluded_paths"],
      path: rootJSONPointer("change_scope"),
      violations: &violations
    )
    let policy = string(
      object["policy"],
      path: rootJSONPointer("change_scope/policy"),
      violations: &violations
    )
    if let policy, policy != "listed_paths_only" {
      append(
        "unbounded_change_scope",
        path: rootJSONPointer("change_scope/policy"),
        message: "Версия 1 допускает только listed_paths_only.",
        to: &violations
      )
    }
    let allowed = stringArray(
      object["allowed_paths"],
      path: rootJSONPointer("change_scope/allowed_paths"),
      maximum: 128,
      violations: &violations
    )
    let excluded = stringArray(
      object["excluded_paths"],
      path: rootJSONPointer("change_scope/excluded_paths"),
      maximum: 128,
      violations: &violations
    )
    if let allowed, allowed.isEmpty {
      append(
        "allowed_paths_missing",
        path: rootJSONPointer("change_scope/allowed_paths"),
        message: "Допустимая область изменений не должна быть пустой.",
        to: &violations
      )
    }
    if let excluded, excluded.isEmpty {
      append(
        "exclusions_missing",
        path: rootJSONPointer("change_scope/excluded_paths"),
        message: "Рабочий пакет должен содержать явные исключения.",
        to: &violations
      )
    }
    for (index, value) in (allowed ?? []).enumerated() {
      validateRelativePath(
        value,
        path: rootJSONPointer("change_scope/allowed_paths/\(index)"),
        violations: &violations
      )
    }
    for (index, value) in (excluded ?? []).enumerated() {
      validateRelativePath(
        value,
        path: rootJSONPointer("change_scope/excluded_paths/\(index)"),
        violations: &violations
      )
    }
    for allowedPath in allowed ?? [] {
      if (excluded ?? []).contains(where: { pathsOverlap(allowedPath, $0) }) {
        append(
          "scope_overlap",
          path: rootJSONPointer("change_scope"),
          message: "Допустимая и исключённая области пересекаются.",
          to: &violations
        )
      }
    }
    return ScopeSnapshot(
      allowedPaths: allowed ?? [],
      excludedPaths: excluded ?? []
    )
  }

  private static func validateDependencies(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let values = array(raw, path: rootJSONPointer("dependencies"), violations: &violations)
    else {
      return
    }
    validateCollectionLimit(
      values, path: rootJSONPointer("dependencies"), maximum: 128, violations: &violations)
    var identifiers: Set<String> = []
    for (index, value) in values.prefix(128).enumerated() {
      let path = rootJSONPointer("dependencies/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["id", "status", "evidence"],
        path: path,
        violations: &violations
      )
      let identifier = string(object["id"], path: "\(path)/id", violations: &violations)
      validateTechnicalIdentifier(identifier, path: "\(path)/id", violations: &violations)
      if let identifier, !identifiers.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: "\(path)/id",
          message: "Идентификатор зависимости повторяется.",
          to: &violations
        )
      }
      let status = string(object["status"], path: "\(path)/status", violations: &violations)
      if let status, status != "resolved" {
        append(
          "unresolved_dependency",
          path: "\(path)/status",
          message: "Каждая зависимость должна иметь статус resolved.",
          to: &violations
        )
      }
      validateRequiredText(
        object["evidence"],
        path: "\(path)/evidence",
        maximumScalars: 2_048,
        violations: &violations
      )
    }
  }

  private static func validateChecks(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let values = array(raw, path: rootJSONPointer("checks"), violations: &violations) else {
      return
    }
    validateCollectionLimit(
      values, path: rootJSONPointer("checks"), maximum: 128, violations: &violations)
    if values.isEmpty {
      append(
        "checks_missing",
        path: rootJSONPointer("checks"),
        message: "Нужна хотя бы одна конечная проверка.",
        to: &violations
      )
    }
    var identifiers: Set<String> = []
    for (index, value) in values.prefix(128).enumerated() {
      let path = rootJSONPointer("checks/\(index)")
      guard let object = object(value, path: path, violations: &violations) else { continue }
      validateExactKeys(
        object,
        expected: ["id", "description"],
        path: path,
        violations: &violations
      )
      let identifier = string(object["id"], path: "\(path)/id", violations: &violations)
      validateTechnicalIdentifier(identifier, path: "\(path)/id", violations: &violations)
      if let identifier, !identifiers.insert(identifier).inserted {
        append(
          "duplicate_identifier",
          path: "\(path)/id",
          message: "Идентификатор проверки повторяется.",
          to: &violations
        )
      }
      validateRequiredText(
        object["description"],
        path: "\(path)/description",
        maximumScalars: 2_048,
        violations: &violations
      )
    }
  }

  private static func validateHandoff(
    _ raw: Any?,
    scope: ScopeSnapshot?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let object = object(raw, path: rootJSONPointer("handoff"), violations: &violations) else {
      return
    }
    validateExactKeys(
      object,
      expected: ["format", "required_artifacts"],
      path: rootJSONPointer("handoff"),
      violations: &violations
    )
    let format = string(
      object["format"], path: rootJSONPointer("handoff/format"), violations: &violations)
    validateTechnicalIdentifier(
      format, path: rootJSONPointer("handoff/format"), violations: &violations)
    if let artifacts = stringArray(
      object["required_artifacts"],
      path: rootJSONPointer("handoff/required_artifacts"),
      maximum: 128,
      violations: &violations
    ) {
      if artifacts.isEmpty {
        append(
          "handoff_missing",
          path: rootJSONPointer("handoff/required_artifacts"),
          message: "Формат передачи должен перечислять обязательные артефакты.",
          to: &violations
        )
      }
      var uniqueArtifacts: Set<String> = []
      for (index, value) in artifacts.enumerated() {
        let artifactPath = rootJSONPointer("handoff/required_artifacts/\(index)")
        let pathIsValid = validateRelativePath(
          value,
          path: artifactPath,
          violations: &violations
        )
        if !uniqueArtifacts.insert(value).inserted {
          append(
            "duplicate_path",
            path: artifactPath,
            message: "Путь обязательного артефакта повторяется.",
            to: &violations
          )
        }
        if pathIsValid, let scope {
          let isAllowed = scope.allowedPaths.contains { path(value, isWithin: $0) }
          let isExcluded = scope.excludedPaths.contains { pathsOverlap(value, $0) }
          if !isAllowed || isExcluded {
            append(
              "handoff_scope_conflict",
              path: artifactPath,
              message: "Обязательный артефакт передачи выходит из допустимой области изменений.",
              to: &violations
            )
          }
        }
      }
    }
  }

  private static func validateBudget(
    _ raw: Any?,
    minimums: StructuralCounts,
    violations: inout [WorkPackageViolation]
  ) {
    guard let object = object(raw, path: rootJSONPointer("budget"), violations: &violations) else {
      return
    }
    validateExactKeys(
      object,
      expected: ["unit", "limit", "reading", "work", "verification", "response", "reserve"],
      path: rootJSONPointer("budget"),
      violations: &violations
    )
    let unit = string(object["unit"], path: rootJSONPointer("budget/unit"), violations: &violations)
    if let unit, unit != "planning_units" {
      append(
        "invalid_value",
        path: rootJSONPointer("budget/unit"),
        message: "Версия 1 использует только planning_units.",
        to: &violations
      )
    }
    let limit = integer(
      object["limit"], path: rootJSONPointer("budget/limit"), violations: &violations)
    let reading = integer(
      object["reading"], path: rootJSONPointer("budget/reading"), violations: &violations)
    let work = integer(
      object["work"], path: rootJSONPointer("budget/work"), violations: &violations)
    let verification = integer(
      object["verification"],
      path: rootJSONPointer("budget/verification"),
      violations: &violations
    )
    let response = integer(
      object["response"], path: rootJSONPointer("budget/response"), violations: &violations)
    let reserve = integer(
      object["reserve"], path: rootJSONPointer("budget/reserve"), violations: &violations)

    if let limit, limit <= 0 || limit > maximumPlanningUnits {
      append(
        "budget_limit_invalid",
        path: rootJSONPointer("budget/limit"),
        message: "Общий лимит должен быть положительным и не превышать предел версии 1.",
        to: &violations
      )
    }
    for (name, value) in [
      ("reading", reading), ("work", work), ("verification", verification),
      ("response", response),
    ] {
      if let value, value <= 0 || value > maximumPlanningUnits {
        append(
          "budget_component_invalid",
          path: rootJSONPointer("budget/\(name)"),
          message: "Каждый рабочий компонент бюджета должен быть положительным и конечным.",
          to: &violations
        )
      }
    }
    if reserve == nil || reserve.map({ $0 <= 0 || $0 > maximumPlanningUnits }) == true {
      append(
        "reserve_missing",
        path: rootJSONPointer("budget/reserve"),
        message: "Рабочий пакет должен содержать положительный резерв.",
        to: &violations
      )
    }
    for (name, value, minimum) in [
      ("reading", reading, max(1, minimums.inputs)),
      ("work", work, max(1, minimums.changes)),
      ("verification", verification, max(1, minimums.checks)),
      ("response", response, max(1, minimums.handoffArtifacts)),
    ] {
      if let value, value < minimum {
        append(
          "budget_underdeclared",
          path: rootJSONPointer("budget/\(name)"),
          message: "Компонент бюджета меньше структурного минимума версии 1.",
          to: &violations
        )
      }
    }
    if let limit, let reading, let work, let verification, let response, let reserve {
      let components = [reading, work, verification, response, reserve]
      var total = 0
      var overflow = false
      for component in components {
        let addition = total.addingReportingOverflow(component)
        total = addition.partialValue
        overflow = overflow || addition.overflow
      }
      if overflow || total > limit {
        append(
          "budget_exceeded",
          path: rootJSONPointer("budget"),
          message: "Сумма раздельных бюджетов превышает общий лимит.",
          to: &violations
        )
      }
    }
  }

  private static func validatePreflight(
    _ raw: Any?,
    violations: inout [WorkPackageViolation]
  ) {
    guard let object = object(raw, path: rootJSONPointer("preflight"), violations: &violations)
    else { return }
    validateExactKeys(
      object,
      expected: ["before_model_call", "before_user_data_mutation"],
      path: rootJSONPointer("preflight"),
      violations: &violations
    )
    let beforeModel = boolean(
      object["before_model_call"],
      path: rootJSONPointer("preflight/before_model_call"),
      violations: &violations
    )
    let beforeMutation = boolean(
      object["before_user_data_mutation"],
      path: rootJSONPointer("preflight/before_user_data_mutation"),
      violations: &violations
    )
    if beforeModel != true || beforeMutation != true {
      append(
        "phase_order_invalid",
        path: rootJSONPointer("preflight"),
        message:
          "Анализ должен предшествовать модельному вызову и изменению пользовательских данных.",
        to: &violations
      )
    }
  }

  private static func validateExactKeys(
    _ object: [String: Any],
    expected: Set<String>,
    path: String,
    violations: inout [WorkPackageViolation]
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

  private static func validateRequiredText(
    _ raw: Any?,
    path: String,
    maximumScalars: Int,
    violations: inout [WorkPackageViolation]
  ) {
    guard let value = string(raw, path: path, violations: &violations) else { return }
    if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      append(
        "empty_value",
        path: path,
        message: "Строковое значение не должно быть пустым.",
        to: &violations
      )
    }
    if value.unicodeScalars.count > maximumScalars {
      append(
        "string_limit_exceeded",
        path: path,
        message: "Строковое значение превышает предел версии 1.",
        to: &violations
      )
    }
  }

  private static func validateTechnicalIdentifier(
    _ value: String?,
    path: String,
    violations: inout [WorkPackageViolation]
  ) {
    guard let value else { return }
    guard isTechnicalIdentifier(value) else {
      append(
        "invalid_identifier",
        path: path,
        message: "Значение не соответствует техническому идентификатору версии 1.",
        to: &violations
      )
      return
    }
  }

  @discardableResult
  private static func validateRelativePath(
    _ value: String?,
    path: String,
    violations: inout [WorkPackageViolation]
  ) -> Bool {
    guard let value else { return false }
    let segments = value.split(separator: "/", omittingEmptySubsequences: false)
    let forbiddenCharacters = CharacterSet(charactersIn: "*?[]{}$\\")
    let containsControl = value.unicodeScalars.contains { scalar in
      scalar.value <= 0x1F || (0x7F...0x9F).contains(scalar.value)
    }
    let invalid =
      value.isEmpty || value.unicodeScalars.count > 1_024 || value.hasPrefix("/")
      || value.hasPrefix(tildeMarker) || value.contains("://")
      || value.rangeOfCharacter(from: forbiddenCharacters) != nil
      || containsControl
      || segments.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
    if invalid {
      append(
        "invalid_path",
        path: path,
        message: "Путь должен быть ограниченным POSIX-путём относительно рабочей области.",
        to: &violations
      )
    }
    return !invalid
  }

  private static func validateCollectionLimit(
    _ values: [Any],
    path: String,
    maximum: Int,
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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
    violations: inout [WorkPackageViolation]
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

  private static func structuralCounts(_ root: [String: Any]) -> StructuralCounts {
    let inputCount = min((root["inputs"] as? [Any])?.count ?? 0, 128)
    let scope = root["change_scope"] as? [String: Any]
    let changeCount = min((scope?["allowed_paths"] as? [Any])?.count ?? 0, 128)
    let checkCount = min((root["checks"] as? [Any])?.count ?? 0, 128)
    let handoff = root["handoff"] as? [String: Any]
    let artifactCount = min((handoff?["required_artifacts"] as? [Any])?.count ?? 0, 128)
    return StructuralCounts(
      inputs: inputCount,
      changes: changeCount,
      checks: checkCount,
      handoffArtifacts: artifactCount
    )
  }

  private static func append(
    _ code: String,
    path: String,
    message: String,
    to violations: inout [WorkPackageViolation]
  ) {
    violations.append(WorkPackageViolation(code: code, path: path, message: message))
  }

  private static func pointer(_ base: String, _ field: String) -> String {
    let escaped = field.replacingOccurrences(
      of: tildeMarker,
      with: tildeMarker + "0"
    )
    .replacingOccurrences(
      of: jsonPointerSeparator,
      with: tildeMarker + "1"
    )
    return base + jsonPointerSeparator + escaped
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

  private static func path(_ candidate: String, isWithin root: String) -> Bool {
    if root == "/" { return candidate.hasPrefix("/") }
    return candidate == root || candidate.hasPrefix(root + "/")
  }

  private static func pathsOverlap(_ left: String, _ right: String) -> Bool {
    path(left, isWithin: right) || path(right, isWithin: left)
  }
}

private enum JSONScanError: Error {
  case invalidJSON
  case structureLimitExceeded
}

private struct JSONDuplicateKeyDetector {
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
    guard index == bytes.count else { throw JSONScanError.invalidJSON }
    return duplicatePaths
  }

  private mutating func parseValue(path: String, depth: Int) throws {
    guard depth <= Self.maximumDepth, nodeCount < Self.maximumNodeCount else {
      throw JSONScanError.structureLimitExceeded
    }
    nodeCount += 1
    skipWhitespace()
    guard index < bytes.count else { throw JSONScanError.invalidJSON }
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
      throw JSONScanError.invalidJSON
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
      try parseValue(path: path + rootJSONPointer("\(itemIndex)"), depth: depth + 1)
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
          throw JSONScanError.invalidJSON
        }
        return value
      }
      if byte < 0x20 { throw JSONScanError.invalidJSON }
      if byte == 0x5C {
        guard index < bytes.count else { throw JSONScanError.invalidJSON }
        let escape = bytes[index]
        index += 1
        if escape == 0x75 {
          guard index + 4 <= bytes.count else { throw JSONScanError.invalidJSON }
          for digit in bytes[index..<(index + 4)] where !isHexDigit(digit) {
            throw JSONScanError.invalidJSON
          }
          index += 4
        }
      }
    }
    throw JSONScanError.invalidJSON
  }

  private mutating func parseNumber() throws {
    let start = index
    while index < bytes.count, !isDelimiter(bytes[index]) {
      index += 1
    }
    guard index > start else { throw JSONScanError.invalidJSON }
    let data = Data(bytes[start..<index])
    _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  }

  private mutating func parseLiteral(_ value: String) throws {
    let literal = Array(value.utf8)
    guard index + literal.count <= bytes.count,
      Array(bytes[index..<(index + literal.count)]) == literal
    else {
      throw JSONScanError.invalidJSON
    }
    index += literal.count
  }

  private mutating func expect(_ byte: UInt8) throws {
    guard consume(byte) else { throw JSONScanError.invalidJSON }
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
      of: tildeMarker,
      with: tildeMarker + "0"
    )
    .replacingOccurrences(
      of: jsonPointerSeparator,
      with: tildeMarker + "1"
    )
    return base + jsonPointerSeparator + escaped
  }

  private func isDelimiter(_ byte: UInt8) -> Bool {
    [0x20, 0x09, 0x0A, 0x0D, 0x2C, 0x5D, 0x7D].contains(byte)
  }

  private func isHexDigit(_ byte: UInt8) -> Bool {
    (0x30...0x39).contains(byte) || (0x41...0x46).contains(byte)
      || (0x61...0x66).contains(byte)
  }
}
