import Foundation

public enum CandidateConflictResolverSpecification: Codable, Equatable, Sendable {
  case rebuildDerivedManifest(
    ruleVersion: Int,
    outputPath: String,
    sourcePaths: [String],
    schemaIdentity: String,
    schemaVersion: Int,
    requiredCheckIDs: [String]
  )
  case mergeStableRecords(
    ruleVersion: Int,
    path: String,
    schemaIdentity: String,
    schemaVersion: Int,
    normativeFields: [String],
    uniqueNormativeFields: [String],
    requiredCheckIDs: [String]
  )

  public var ruleVersion: Int {
    switch self {
    case .rebuildDerivedManifest(let ruleVersion, _, _, _, _, _),
      .mergeStableRecords(let ruleVersion, _, _, _, _, _, _):
      ruleVersion
    }
  }

  public var path: String {
    switch self {
    case .rebuildDerivedManifest(_, let outputPath, _, _, _, _): outputPath
    case .mergeStableRecords(_, let path, _, _, _, _, _): path
    }
  }

  public var algorithm: String {
    switch self {
    case .rebuildDerivedManifest: "rebuild_derived_manifest_v1"
    case .mergeStableRecords: "merge_stable_records_v1"
    }
  }

  public var requiredCheckIDs: [String] {
    switch self {
    case .rebuildDerivedManifest(_, _, _, _, _, let identifiers),
      .mergeStableRecords(_, _, _, _, _, _, let identifiers):
      identifiers
    }
  }

  public var exactPaths: [String] {
    switch self {
    case .rebuildDerivedManifest(_, let outputPath, let sourcePaths, _, _, _):
      [outputPath] + sourcePaths
    case .mergeStableRecords(_, let path, _, _, _, _, _):
      [path]
    }
  }
}

public struct CandidateConflictResolverBinding: Codable, Equatable, Sendable {
  public let ruleID: String
  public let ruleVersion: Int
  public let path: String
  public let algorithm: String
  public let specificationSHA256: String
  public let requiredCheckIDs: [String]

  public init(
    ruleID: String,
    ruleVersion: Int,
    path: String,
    algorithm: String,
    specificationSHA256: String,
    requiredCheckIDs: [String]
  ) {
    self.ruleID = ruleID
    self.ruleVersion = ruleVersion
    self.path = path
    self.algorithm = algorithm
    self.specificationSHA256 = specificationSHA256
    self.requiredCheckIDs = requiredCheckIDs
  }

  enum CodingKeys: String, CodingKey {
    case ruleID = "rule_id"
    case ruleVersion = "rule_version"
    case path
    case algorithm
    case specificationSHA256 = "specification_sha256"
    case requiredCheckIDs = "required_check_ids"
  }
}

public struct CandidateConflictResolutionRecord: Codable, Equatable, Sendable {
  public let ruleID: String
  public let ruleVersion: Int
  public let path: String
  public let algorithm: String
  public let specificationSHA256: String
  public let inputSHA256s: [String]
  public let outputSHA256: String
  public let invariants: [String]
  public let requiredCheckIDs: [String]

  public init(
    ruleID: String,
    ruleVersion: Int,
    path: String,
    algorithm: String,
    specificationSHA256: String,
    inputSHA256s: [String],
    outputSHA256: String,
    invariants: [String],
    requiredCheckIDs: [String]
  ) {
    self.ruleID = ruleID
    self.ruleVersion = ruleVersion
    self.path = path
    self.algorithm = algorithm
    self.specificationSHA256 = specificationSHA256
    self.inputSHA256s = inputSHA256s
    self.outputSHA256 = outputSHA256
    self.invariants = invariants
    self.requiredCheckIDs = requiredCheckIDs
  }

  enum CodingKeys: String, CodingKey {
    case ruleID = "rule_id"
    case ruleVersion = "rule_version"
    case path
    case algorithm
    case specificationSHA256 = "specification_sha256"
    case inputSHA256s = "input_sha256s"
    case outputSHA256 = "output_sha256"
    case invariants
    case requiredCheckIDs = "required_check_ids"
  }
}

public struct CandidateConflictResolverVariant: Codable, Equatable, Sendable {
  public let identifier: String
  public let data: Data

  public init(identifier: String, data: Data) {
    self.identifier = identifier
    self.data = data
  }
}

public struct CandidateConflictResolutionOutput: Codable, Equatable, Sendable {
  public let data: Data
  public let record: CandidateConflictResolutionRecord

  public init(data: Data, record: CandidateConflictResolutionRecord) {
    self.data = data
    self.record = record
  }
}

public struct CandidateDerivedManifestSource: Codable, Equatable, Sendable {
  public let path: String
  public let sha256: String
  public let byteCount: Int

  public init(path: String, sha256: String, byteCount: Int) {
    self.path = path
    self.sha256 = sha256
    self.byteCount = byteCount
  }

  enum CodingKeys: String, CodingKey {
    case path
    case sha256
    case byteCount = "byte_count"
  }
}

public struct CandidateDerivedManifest: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let sources: [CandidateDerivedManifestSource]

  public init(
    schemaIdentity: String,
    schemaVersion: Int,
    sources: [CandidateDerivedManifestSource]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.sources = sources
  }

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case sources
  }

  public func canonicalJSONData() throws -> Data {
    guard WritingSubnodeValidation.isIdentifier(schemaIdentity), schemaVersion > 0,
      sources.count <= CandidateResolverLimits.maximumEntries,
      sources.allSatisfy({
        WritingSubnodeValidation.isRelativePath($0.path)
          && WritingSubnodeValidation.isSHA256($0.sha256)
          && $0.byteCount >= 0
      })
    else {
      throw CandidateConflictResolverError.invalidRule("Производный manifest некорректен.")
    }
    let orderedSources = sources.sorted { CandidateResolverOrdering.path($0.path, before: $1.path) }
    guard CandidateResolverOrdering.hasUniqueNormalizedPaths(orderedSources.map(\.path)) else {
      throw CandidateConflictResolverError.invalidRule(
        "Производный manifest содержит повторяющиеся пути."
      )
    }
    return try CandidateResolverJSON.encode(
      CandidateDerivedManifest(
        schemaIdentity: schemaIdentity,
        schemaVersion: schemaVersion,
        sources: orderedSources
      )
    )
  }
}

public struct CandidateStableRecord: Codable, Equatable, Sendable {
  public let id: String
  public let normative: [String: String]
  public let informative: [String: String]

  public init(
    id: String,
    normative: [String: String],
    informative: [String: String] = [:]
  ) {
    self.id = id
    self.normative = normative
    self.informative = informative
  }
}

public struct CandidateStableRecordDocument: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let records: [CandidateStableRecord]

  public init(
    schemaIdentity: String,
    schemaVersion: Int,
    records: [CandidateStableRecord]
  ) {
    self.schemaIdentity = schemaIdentity
    self.schemaVersion = schemaVersion
    self.records = records
  }

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case records
  }

  public func canonicalJSONData() throws -> Data {
    try CandidateStableRecordValidation.validateGeneral(self)
    let orderedRecords = records.sorted {
      CandidateResolverOrdering.identifier($0.id, before: $1.id)
    }
    return try CandidateResolverJSON.encode(
      CandidateStableRecordDocument(
        schemaIdentity: schemaIdentity,
        schemaVersion: schemaVersion,
        records: orderedRecords
      )
    )
  }
}

public enum CandidateResolutionFailureReason: String, Codable, Equatable, Sendable {
  case unknownPath = "unknown_path"
  case ambiguousRule = "ambiguous_rule"
  case preconditionFailed = "precondition_failed"
  case schemaMismatch = "schema_mismatch"
  case duplicateID = "duplicate_id"
  case normativeFieldConflict = "normative_field_conflict"
  case semanticConflict = "semantic_conflict"
  case checkFailed = "check_failed"
  case resolverFailed = "resolver_failed"
}

public struct CandidateResolutionDiagnosticIssue: Codable, Equatable, Sendable {
  public let reason: CandidateResolutionFailureReason
  public let path: String
  public let matchingRuleIDs: [String]
  public let ruleID: String?
  public let recordID: String?
  public let field: String?
  public let checkID: String?

  public init(
    reason: CandidateResolutionFailureReason,
    path: String,
    matchingRuleIDs: [String] = [],
    ruleID: String? = nil,
    recordID: String? = nil,
    field: String? = nil,
    checkID: String? = nil
  ) {
    self.reason = reason
    self.path = path
    self.matchingRuleIDs = Array(Set(matchingRuleIDs)).sorted()
    self.ruleID = ruleID
    self.recordID = recordID
    self.field = field
    self.checkID = checkID
  }

  enum CodingKeys: String, CodingKey {
    case reason
    case path
    case matchingRuleIDs = "matching_rule_ids"
    case ruleID = "rule_id"
    case recordID = "record_id"
    case field
    case checkID = "check_id"
  }
}

public struct CandidateResolutionDiagnosticInput: Codable, Equatable, Sendable {
  public let role: String
  public let identifier: String
  public let commitOID: String
  public let treeOID: String
  public let blobOIDs: [String: String]

  public init(
    role: String,
    identifier: String,
    commitOID: String,
    treeOID: String,
    blobOIDs: [String: String] = [:]
  ) {
    self.role = role
    self.identifier = identifier
    self.commitOID = commitOID
    self.treeOID = treeOID
    self.blobOIDs = blobOIDs
  }

  enum CodingKeys: String, CodingKey {
    case role
    case identifier
    case commitOID = "commit_oid"
    case treeOID = "tree_oid"
    case blobOIDs = "blob_oids"
  }
}

public struct CandidateResolutionDiagnostic: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let attemptID: String
  public let targetRef: String
  public let expectedTargetOID: String
  public let inputs: [CandidateResolutionDiagnosticInput]
  public let affectedPaths: [String]
  public let issues: [CandidateResolutionDiagnosticIssue]
  public let checks: [CandidateIntegrationRecordedCheck]

  public init(
    attemptID: String,
    targetRef: String,
    expectedTargetOID: String,
    inputs: [CandidateResolutionDiagnosticInput],
    affectedPaths: [String],
    issues: [CandidateResolutionDiagnosticIssue],
    checks: [CandidateIntegrationRecordedCheck] = []
  ) {
    schemaIdentity = "fum.candidate-resolution-diagnostic"
    schemaVersion = 1
    self.attemptID = attemptID
    self.targetRef = targetRef
    self.expectedTargetOID = expectedTargetOID
    self.inputs = inputs.sorted(by: CandidateResolverOrdering.diagnosticInput)
    self.affectedPaths = Array(Set(affectedPaths)).sorted(by: CandidateResolverOrdering.path)
    self.issues = issues.sorted(by: CandidateResolverOrdering.diagnosticIssue)
    self.checks = checks.sorted { $0.checkID < $1.checkID }
  }

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case attemptID = "attempt_id"
    case targetRef = "target_ref"
    case expectedTargetOID = "expected_target_oid"
    case inputs
    case affectedPaths = "affected_paths"
    case issues
    case checks
  }

  public func canonicalJSONData() throws -> Data {
    try CandidateResolverJSON.encode(self)
  }

  public var sha256: String {
    (try? canonicalJSONData()).map(WritingSubnodeJSON.sha256)
      ?? WritingSubnodeJSON.sha256(Data("invalid-resolution-diagnostic".utf8))
  }
}

public enum CandidateConflictResolverError: Error, Equatable, Sendable {
  case invalidRule(String)
  case resolutionRequired(CandidateResolutionDiagnosticIssue)

  public var issue: CandidateResolutionDiagnosticIssue? {
    guard case .resolutionRequired(let issue) = self else { return nil }
    return issue
  }
}

public struct CandidateConflictResolverRegistry: Sendable {
  public static let registryIdentity = "fum.candidate-conflict-resolver-registry"
  public static let registryVersion = 1

  private let specifications: [String: CandidateConflictResolverSpecification]

  public init(specifications: [String: CandidateConflictResolverSpecification] = [:]) {
    self.specifications = specifications
  }

  public func specification(for ruleID: String) -> CandidateConflictResolverSpecification? {
    specifications[ruleID]
  }

  public func stableBindings(
    _ identifiers: [String]
  ) throws -> [CandidateConflictResolverBinding] {
    guard identifiers.count == Set(identifiers).count else {
      throw CandidateConflictResolverError.invalidRule(
        "Список resolver-правил содержит повторяющийся идентификатор."
      )
    }
    return try identifiers.sorted().map { identifier in
      guard WritingSubnodeValidation.isIdentifier(identifier),
        let specification = specifications[identifier]
      else {
        throw CandidateConflictResolverError.invalidRule(
          "Resolver-правило не зарегистрировано."
        )
      }
      try Self.validate(ruleID: identifier, specification: specification)
      return CandidateConflictResolverBinding(
        ruleID: identifier,
        ruleVersion: specification.ruleVersion,
        path: specification.path,
        algorithm: specification.algorithm,
        specificationSHA256: WritingSubnodeJSON.sha256(
          try WritingSubnodeJSON.encode(specification)
        ),
        requiredCheckIDs: specification.requiredCheckIDs
      )
    }
  }

  public func matchingBindings(
    for path: String,
    identifiers: [String]
  ) throws -> [CandidateConflictResolverBinding] {
    try stableBindings(identifiers).filter { $0.path == path }
  }

  public func rebuildDerivedManifest(
    ruleID: String,
    sources: [String: Data]
  ) throws -> CandidateConflictResolutionOutput {
    guard let specification = specifications[ruleID] else {
      throw CandidateConflictResolverError.invalidRule("Resolver-правило не зарегистрировано.")
    }
    try Self.validate(ruleID: ruleID, specification: specification)
    guard
      case .rebuildDerivedManifest(
        let ruleVersion,
        let outputPath,
        let sourcePaths,
        let schemaIdentity,
        let schemaVersion,
        let requiredCheckIDs
      ) = specification
    else {
      throw CandidateConflictResolverError.invalidRule(
        "Resolver-правило имеет другой алгоритм."
      )
    }
    guard Set(sources.keys) == Set(sourcePaths),
      sources.values.allSatisfy({ $0.count <= CandidateResolverLimits.maximumInputBytes })
    else {
      throw resolutionIssue(
        reason: .preconditionFailed,
        path: outputPath,
        ruleID: ruleID
      )
    }
    let manifest = CandidateDerivedManifest(
      schemaIdentity: schemaIdentity,
      schemaVersion: schemaVersion,
      sources: sourcePaths.map { path in
        let data = sources[path] ?? Data()
        return CandidateDerivedManifestSource(
          path: path,
          sha256: WritingSubnodeJSON.sha256(data),
          byteCount: data.count
        )
      }
    )
    let output: Data
    do {
      output = try manifest.canonicalJSONData()
    } catch {
      throw resolutionIssue(
        reason: .preconditionFailed,
        path: outputPath,
        ruleID: ruleID
      )
    }
    let binding = try stableBinding(ruleID: ruleID, specification: specification)
    return CandidateConflictResolutionOutput(
      data: output,
      record: CandidateConflictResolutionRecord(
        ruleID: ruleID,
        ruleVersion: ruleVersion,
        path: outputPath,
        algorithm: specification.algorithm,
        specificationSHA256: binding.specificationSHA256,
        inputSHA256s: sourcePaths.map { WritingSubnodeJSON.sha256(sources[$0] ?? Data()) },
        outputSHA256: WritingSubnodeJSON.sha256(output),
        invariants: [
          "canonical_sources_complete",
          "manifest_rebuilt",
          "output_path_exact",
        ],
        requiredCheckIDs: requiredCheckIDs
      )
    )
  }

  public func mergeStableRecords(
    ruleID: String,
    base: Data,
    variants: [CandidateConflictResolverVariant]
  ) throws -> CandidateConflictResolutionOutput {
    guard let specification = specifications[ruleID] else {
      throw CandidateConflictResolverError.invalidRule("Resolver-правило не зарегистрировано.")
    }
    try Self.validate(ruleID: ruleID, specification: specification)
    guard
      case .mergeStableRecords(
        let ruleVersion,
        let path,
        let schemaIdentity,
        let schemaVersion,
        let normativeFields,
        let uniqueNormativeFields,
        let requiredCheckIDs
      ) = specification
    else {
      throw CandidateConflictResolverError.invalidRule(
        "Resolver-правило имеет другой алгоритм."
      )
    }
    guard !variants.isEmpty,
      variants.count <= CandidateResolverLimits.maximumVariants,
      Set(variants.map(\.identifier)).count == variants.count,
      variants.allSatisfy({
        !$0.identifier.isEmpty
          && $0.identifier.utf8.count <= CandidateResolverLimits.maximumIdentifierBytes
          && $0.data.count <= CandidateResolverLimits.maximumInputBytes
      }),
      base.count <= CandidateResolverLimits.maximumInputBytes
    else {
      throw resolutionIssue(reason: .preconditionFailed, path: path, ruleID: ruleID)
    }

    let baseDocument = try decodeStableDocument(
      base,
      path: path,
      ruleID: ruleID,
      schemaIdentity: schemaIdentity,
      schemaVersion: schemaVersion,
      normativeFields: normativeFields
    )
    let orderedVariants = variants.sorted { $0.identifier < $1.identifier }
    let variantDocuments = try orderedVariants.map { variant in
      try decodeStableDocument(
        variant.data,
        path: path,
        ruleID: ruleID,
        schemaIdentity: schemaIdentity,
        schemaVersion: schemaVersion,
        normativeFields: normativeFields
      )
    }
    let baseRecords = Dictionary(uniqueKeysWithValues: baseDocument.records.map { ($0.id, $0) })
    let variantRecords = variantDocuments.map {
      Dictionary(uniqueKeysWithValues: $0.records.map { ($0.id, $0) })
    }
    let allIDs = Set(baseRecords.keys).union(variantRecords.flatMap(\.keys))
    let idsByNormalizedValue = Dictionary(grouping: allIDs) {
      $0.precomposedStringWithCanonicalMapping.lowercased()
    }
    if let duplicateIDs = idsByNormalizedValue.values
      .filter({ $0.count > 1 })
      .sorted(by: { ($0.sorted().first ?? "") < ($1.sorted().first ?? "") })
      .first
    {
      throw resolutionIssue(
        reason: .duplicateID,
        path: path,
        ruleID: ruleID,
        recordID: duplicateIDs.sorted().first
      )
    }
    var mergedRecords: [CandidateStableRecord] = []
    for id in allIDs.sorted(by: CandidateResolverOrdering.identifier) {
      let baseRecord = baseRecords[id]
      let records = variantRecords.compactMap { $0[id] }
      if baseRecord != nil && records.count != variantRecords.count {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: id
        )
      }
      guard !records.isEmpty else {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: id
        )
      }
      let normative = try mergeNormativeFields(
        path: path,
        ruleID: ruleID,
        recordID: id,
        fields: normativeFields,
        base: baseRecord?.normative,
        variants: records.map(\.normative)
      )
      let informative = try mergeInformativeFields(
        path: path,
        ruleID: ruleID,
        recordID: id,
        base: baseRecord?.informative,
        variants: records.map(\.informative)
      )
      mergedRecords.append(
        CandidateStableRecord(id: id, normative: normative, informative: informative)
      )
    }
    try validateSemanticUniqueness(
      mergedRecords,
      fields: uniqueNormativeFields,
      path: path,
      ruleID: ruleID
    )
    let outputDocument = CandidateStableRecordDocument(
      schemaIdentity: schemaIdentity,
      schemaVersion: schemaVersion,
      records: mergedRecords
    )
    let output: Data
    do {
      output = try outputDocument.canonicalJSONData()
    } catch {
      throw resolutionIssue(reason: .resolverFailed, path: path, ruleID: ruleID)
    }
    let binding = try stableBinding(ruleID: ruleID, specification: specification)
    return CandidateConflictResolutionOutput(
      data: output,
      record: CandidateConflictResolutionRecord(
        ruleID: ruleID,
        ruleVersion: ruleVersion,
        path: path,
        algorithm: specification.algorithm,
        specificationSHA256: binding.specificationSHA256,
        inputSHA256s: [WritingSubnodeJSON.sha256(base)]
          + orderedVariants.map { WritingSubnodeJSON.sha256($0.data) },
        outputSHA256: WritingSubnodeJSON.sha256(output),
        invariants: [
          "normative_fields_consistent",
          "schema_agreed",
          "semantic_uniqueness",
          "stable_ids_unique",
        ],
        requiredCheckIDs: requiredCheckIDs
      )
    )
  }

  private func stableBinding(
    ruleID: String,
    specification: CandidateConflictResolverSpecification
  ) throws -> CandidateConflictResolverBinding {
    CandidateConflictResolverBinding(
      ruleID: ruleID,
      ruleVersion: specification.ruleVersion,
      path: specification.path,
      algorithm: specification.algorithm,
      specificationSHA256: WritingSubnodeJSON.sha256(
        try WritingSubnodeJSON.encode(specification)
      ),
      requiredCheckIDs: specification.requiredCheckIDs
    )
  }

  private static func validate(
    ruleID: String,
    specification: CandidateConflictResolverSpecification
  ) throws {
    guard WritingSubnodeValidation.isIdentifier(ruleID), specification.ruleVersion == 1,
      WritingSubnodeValidation.isRelativePath(specification.path),
      isOrderedUniqueIdentifiers(specification.requiredCheckIDs),
      !specification.requiredCheckIDs.isEmpty
    else {
      throw CandidateConflictResolverError.invalidRule("Resolver-правило некорректно.")
    }
    switch specification {
    case .rebuildDerivedManifest(
      _, let outputPath, let sourcePaths, let schemaIdentity, let schemaVersion, _):
      guard WritingSubnodeValidation.isIdentifier(schemaIdentity), schemaVersion > 0,
        !sourcePaths.isEmpty,
        sourcePaths.count <= CandidateResolverLimits.maximumEntries,
        sourcePaths == sourcePaths.sorted(by: CandidateResolverOrdering.path),
        CandidateResolverOrdering.hasUniqueNormalizedPaths(sourcePaths),
        sourcePaths.allSatisfy(WritingSubnodeValidation.isRelativePath),
        CandidateResolverOrdering.hasUniqueNormalizedPaths([outputPath] + sourcePaths)
      else {
        throw CandidateConflictResolverError.invalidRule(
          "Правило пересборки производного manifest некорректно."
        )
      }
    case .mergeStableRecords(
      _, _, let schemaIdentity, let schemaVersion, let normativeFields,
      let uniqueNormativeFields, _):
      guard WritingSubnodeValidation.isIdentifier(schemaIdentity), schemaVersion > 0,
        !normativeFields.isEmpty,
        isOrderedUniqueIdentifiers(normativeFields),
        isOrderedUniqueIdentifiers(uniqueNormativeFields),
        Set(uniqueNormativeFields).isSubset(of: Set(normativeFields))
      else {
        throw CandidateConflictResolverError.invalidRule(
          "Правило объединения записей некорректно."
        )
      }
    }
  }

  private static func isOrderedUniqueIdentifiers(_ values: [String]) -> Bool {
    values == values.sorted() && values.count == Set(values).count
      && values.allSatisfy(WritingSubnodeValidation.isIdentifier)
  }

  private func decodeStableDocument(
    _ data: Data,
    path: String,
    ruleID: String,
    schemaIdentity: String,
    schemaVersion: Int,
    normativeFields: [String]
  ) throws -> CandidateStableRecordDocument {
    let document: CandidateStableRecordDocument
    do {
      document = try JSONDecoder().decode(CandidateStableRecordDocument.self, from: data)
      if let duplicateID = CandidateStableRecordValidation.duplicateIdentifier(in: document) {
        throw resolutionIssue(
          reason: .duplicateID,
          path: path,
          ruleID: ruleID,
          recordID: duplicateID
        )
      }
      try CandidateStableRecordValidation.validateGeneral(document)
      guard try document.canonicalJSONData() == data else {
        throw CandidateConflictResolverError.invalidRule("Документ не каноничен.")
      }
    } catch let error as CandidateConflictResolverError {
      if case .resolutionRequired = error { throw error }
      throw resolutionIssue(reason: .preconditionFailed, path: path, ruleID: ruleID)
    } catch {
      throw resolutionIssue(reason: .preconditionFailed, path: path, ruleID: ruleID)
    }
    guard document.schemaIdentity == schemaIdentity, document.schemaVersion == schemaVersion else {
      throw resolutionIssue(reason: .schemaMismatch, path: path, ruleID: ruleID)
    }
    for record in document.records {
      guard Set(record.normative.keys) == Set(normativeFields) else {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: record.id
        )
      }
    }
    return document
  }

  private func mergeNormativeFields(
    path: String,
    ruleID: String,
    recordID: String,
    fields: [String],
    base: [String: String]?,
    variants: [[String: String]]
  ) throws -> [String: String] {
    var result: [String: String] = [:]
    for field in fields {
      let baseValue = base?[field]
      let changedValues = Set(
        variants.compactMap { values -> String? in
          guard let value = values[field] else { return nil }
          return value == baseValue ? nil : value
        })
      if changedValues.count > 1 {
        throw resolutionIssue(
          reason: .normativeFieldConflict,
          path: path,
          ruleID: ruleID,
          recordID: recordID,
          field: field
        )
      }
      if let changedValue = changedValues.first {
        result[field] = changedValue
      } else if let baseValue {
        result[field] = baseValue
      } else if let first = variants.first?[field] {
        result[field] = first
      } else {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: recordID,
          field: field
        )
      }
      guard variants.allSatisfy({ $0[field] != nil }) else {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: recordID,
          field: field
        )
      }
    }
    return result
  }

  private func mergeInformativeFields(
    path: String,
    ruleID: String,
    recordID: String,
    base: [String: String]?,
    variants: [[String: String]]
  ) throws -> [String: String] {
    let allFields = Set(base?.keys ?? [String: String]().keys)
      .union(variants.flatMap(\.keys))
    var result: [String: String] = [:]
    for field in allFields.sorted() {
      let baseValue = base?[field]
      if baseValue != nil && variants.contains(where: { $0[field] == nil }) {
        throw resolutionIssue(
          reason: .preconditionFailed,
          path: path,
          ruleID: ruleID,
          recordID: recordID,
          field: field
        )
      }
      let changedValues = Set(
        variants.compactMap { values -> String? in
          guard let value = values[field] else { return nil }
          return value == baseValue ? nil : value
        })
      if changedValues.count > 1 {
        throw resolutionIssue(
          reason: .semanticConflict,
          path: path,
          ruleID: ruleID,
          recordID: recordID,
          field: field
        )
      }
      if let changedValue = changedValues.first {
        result[field] = changedValue
      } else if let baseValue {
        result[field] = baseValue
      } else if let first = variants.compactMap({ $0[field] }).first {
        result[field] = first
      }
    }
    return result
  }

  private func validateSemanticUniqueness(
    _ records: [CandidateStableRecord],
    fields: [String],
    path: String,
    ruleID: String
  ) throws {
    for field in fields {
      var ownerByValue: [String: String] = [:]
      for record in records.sorted(by: {
        CandidateResolverOrdering.identifier($0.id, before: $1.id)
      }) {
        guard let value = record.normative[field] else {
          throw resolutionIssue(
            reason: .preconditionFailed,
            path: path,
            ruleID: ruleID,
            recordID: record.id,
            field: field
          )
        }
        let normalized = value.precomposedStringWithCanonicalMapping.lowercased()
        if let owner = ownerByValue[normalized], owner != record.id {
          throw resolutionIssue(
            reason: .semanticConflict,
            path: path,
            ruleID: ruleID,
            recordID: [owner, record.id].sorted().first,
            field: field
          )
        }
        ownerByValue[normalized] = record.id
      }
    }
  }

  private func resolutionIssue(
    reason: CandidateResolutionFailureReason,
    path: String,
    ruleID: String,
    recordID: String? = nil,
    field: String? = nil
  ) -> CandidateConflictResolverError {
    .resolutionRequired(
      CandidateResolutionDiagnosticIssue(
        reason: reason,
        path: path,
        matchingRuleIDs: [ruleID],
        ruleID: ruleID,
        recordID: recordID,
        field: field
      )
    )
  }
}

private enum CandidateResolverLimits {
  static let maximumEntries = 10_000
  static let maximumVariants = 128
  static let maximumInputBytes = 16 * 1_024 * 1_024
  static let maximumIdentifierBytes = 256
  static let maximumValueBytes = 16 * 1_024
}

private enum CandidateResolverJSON {
  static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(value)
    data.append(0x0A)
    return data
  }
}

private enum CandidateResolverOrdering {
  static func normalized(_ value: String) -> String {
    value.precomposedStringWithCanonicalMapping.lowercased()
  }

  static func path(_ left: String, before right: String) -> Bool {
    let normalizedLeft = normalized(left)
    let normalizedRight = normalized(right)
    return normalizedLeft == normalizedRight ? left < right : normalizedLeft < normalizedRight
  }

  static func identifier(_ left: String, before right: String) -> Bool {
    let normalizedLeft = normalized(left)
    let normalizedRight = normalized(right)
    return normalizedLeft == normalizedRight ? left < right : normalizedLeft < normalizedRight
  }

  static func hasUniqueNormalizedPaths(_ paths: [String]) -> Bool {
    Set(paths.map(normalized)).count == paths.count
  }

  static func diagnosticInput(
    _ left: CandidateResolutionDiagnosticInput,
    _ right: CandidateResolutionDiagnosticInput
  ) -> Bool {
    (left.role, left.identifier, left.commitOID, left.treeOID)
      < (right.role, right.identifier, right.commitOID, right.treeOID)
  }

  static func diagnosticIssue(
    _ left: CandidateResolutionDiagnosticIssue,
    _ right: CandidateResolutionDiagnosticIssue
  ) -> Bool {
    let leftKey = [
      left.path,
      left.reason.rawValue,
      left.ruleID ?? "",
      left.recordID ?? "",
      left.field ?? "",
      left.checkID ?? "",
      left.matchingRuleIDs.joined(separator: "\u{0}"),
    ]
    let rightKey = [
      right.path,
      right.reason.rawValue,
      right.ruleID ?? "",
      right.recordID ?? "",
      right.field ?? "",
      right.checkID ?? "",
      right.matchingRuleIDs.joined(separator: "\u{0}"),
    ]
    return leftKey.lexicographicallyPrecedes(rightKey)
  }
}

private enum CandidateStableRecordValidation {
  static func duplicateIdentifier(in document: CandidateStableRecordDocument) -> String? {
    var originalByNormalizedID: [String: String] = [:]
    for record in document.records {
      let normalizedID = record.id.precomposedStringWithCanonicalMapping.lowercased()
      if let original = originalByNormalizedID[normalizedID] {
        return [original, record.id].sorted().first
      }
      originalByNormalizedID[normalizedID] = record.id
    }
    return nil
  }

  static func validateGeneral(_ document: CandidateStableRecordDocument) throws {
    guard WritingSubnodeValidation.isIdentifier(document.schemaIdentity),
      document.schemaVersion > 0,
      document.records.count <= CandidateResolverLimits.maximumEntries,
      document.records.allSatisfy(isValidRecord)
    else {
      throw CandidateConflictResolverError.invalidRule("Документ устойчивых записей некорректен.")
    }
    guard duplicateIdentifier(in: document) == nil else {
      throw CandidateConflictResolverError.invalidRule(
        "Документ устойчивых записей содержит повторяющийся ID."
      )
    }
  }

  private static func isValidRecord(_ record: CandidateStableRecord) -> Bool {
    WritingSubnodeValidation.isIdentifier(record.id)
      && record.normative.keys.allSatisfy(WritingSubnodeValidation.isIdentifier)
      && record.informative.keys.allSatisfy(WritingSubnodeValidation.isIdentifier)
      && record.normative.values.allSatisfy(isValidValue)
      && record.informative.values.allSatisfy(isValidValue)
  }

  private static func isValidValue(_ value: String) -> Bool {
    !value.isEmpty && value.utf8.count <= CandidateResolverLimits.maximumValueBytes
      && !value.unicodeScalars.contains(where: {
        $0.value == 0 || (0x01...0x08).contains($0.value)
          || (0x0B...0x0C).contains($0.value) || (0x0E...0x1F).contains($0.value)
      })
  }
}
