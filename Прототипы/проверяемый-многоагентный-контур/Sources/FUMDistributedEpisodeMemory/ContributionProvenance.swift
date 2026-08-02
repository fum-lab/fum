import FUMReproducibleMemoryPopulation
import Foundation

public enum SharedEpisodeCorrelationKind:
  String, Codable, Equatable, Hashable, Sendable
{
  case model
  case provider
  case sourceMaterial = "source_material"
  case parentResult = "parent_result"
  case systemTemplate = "system_template"
  case copy
  case derivedAnswer = "derived_answer"
}

public struct SharedEpisodeCorrelationLink:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let groupID: String
  public let kind: SharedEpisodeCorrelationKind
  public let basisSHA256: String
  public let sourceContributionID: String?

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case groupID = "group_id"
    case kind
    case basisSHA256 = "basis_sha256"
    case sourceContributionID = "source_contribution_id"
  }

  public init(
    schemaVersion: Int = 1,
    groupID: String,
    kind: SharedEpisodeCorrelationKind,
    basisSHA256: String,
    sourceContributionID: String? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.groupID = groupID
    self.kind = kind
    self.basisSHA256 = basisSHA256
    self.sourceContributionID = sourceContributionID
  }
}

public enum SharedEpisodeInstrumentSourceAuthority:
  String, Codable, Equatable, Hashable, Sendable
{
  case localTool = "local_tool"
  case repository
  case remoteService = "remote_service"
  case externalArtifact = "external_artifact"
}

public struct SharedEpisodeInstrumentObservation:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let observationID: String
  public let sourceAuthority: SharedEpisodeInstrumentSourceAuthority
  public let callID: String
  public let inputSHA256: String
  public let resultSHA256: String
  public let observedAtSeconds: Int

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case observationID = "observation_id"
    case sourceAuthority = "source_authority"
    case callID = "call_id"
    case inputSHA256 = "input_sha256"
    case resultSHA256 = "result_sha256"
    case observedAtSeconds = "observed_at_seconds"
  }

  public init(
    schemaVersion: Int = 1,
    observationID: String,
    sourceAuthority: SharedEpisodeInstrumentSourceAuthority,
    callID: String,
    inputSHA256: String,
    resultSHA256: String,
    observedAtSeconds: Int
  ) {
    self.schemaVersion = schemaVersion
    self.observationID = observationID
    self.sourceAuthority = sourceAuthority
    self.callID = callID
    self.inputSHA256 = inputSHA256
    self.resultSHA256 = resultSHA256
    self.observedAtSeconds = observedAtSeconds
  }
}

public struct SharedEpisodeContributionProvenance:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let contributionID: String
  public let executorID: String
  public let roleID: String
  public let workPackageArtifactID: String
  public let modelID: String?
  public let providerID: String?
  public let taskSHA256: String
  public let localInputSHA256s: [String]
  public let parentGenerationSHA256: String
  public let resultSHA256: String
  public let correlationLinks: [SharedEpisodeCorrelationLink]
  public let instrumentObservations: [SharedEpisodeInstrumentObservation]
  public let derivedFromObservationIDs: [String]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case contributionID = "contribution_id"
    case executorID = "executor_id"
    case roleID = "role_id"
    case workPackageArtifactID = "work_package_artifact_id"
    case modelID = "model_id"
    case providerID = "provider_id"
    case taskSHA256 = "task_sha256"
    case localInputSHA256s = "local_input_sha256s"
    case parentGenerationSHA256 = "parent_generation_sha256"
    case resultSHA256 = "result_sha256"
    case correlationLinks = "correlation_links"
    case instrumentObservations = "instrument_observations"
    case derivedFromObservationIDs = "derived_from_observation_ids"
  }

  public init(
    schemaVersion: Int = 1,
    contributionID: String,
    executorID: String,
    roleID: String,
    workPackageArtifactID: String,
    modelID: String?,
    providerID: String?,
    taskSHA256: String,
    localInputSHA256s: [String],
    parentGenerationSHA256: String,
    resultSHA256: String,
    correlationLinks: [SharedEpisodeCorrelationLink],
    instrumentObservations: [SharedEpisodeInstrumentObservation] = [],
    derivedFromObservationIDs: [String] = []
  ) {
    self.schemaVersion = schemaVersion
    self.contributionID = contributionID
    self.executorID = executorID
    self.roleID = roleID
    self.workPackageArtifactID = workPackageArtifactID
    self.modelID = modelID
    self.providerID = providerID
    self.taskSHA256 = taskSHA256
    self.localInputSHA256s = localInputSHA256s
    self.parentGenerationSHA256 = parentGenerationSHA256
    self.resultSHA256 = resultSHA256
    self.correlationLinks = correlationLinks
    self.instrumentObservations = instrumentObservations
    self.derivedFromObservationIDs = derivedFromObservationIDs
  }
}

public enum SharedEpisodeContributionProvenanceStatus:
  String, Codable, Equatable, Sendable
{
  case independentByObservedFeatures = "independent_by_observed_features"
  case correlated
  case copy
  case unconfirmedProvenance = "unconfirmed_provenance"
}

public struct SharedEpisodeContributionProvenanceAssessment:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let contributionID: String
  public let status: SharedEpisodeContributionProvenanceStatus

  enum CodingKeys: String, CodingKey {
    case contributionID = "contribution_id"
    case status
  }

  public init(
    contributionID: String,
    status: SharedEpisodeContributionProvenanceStatus
  ) {
    self.contributionID = contributionID
    self.status = status
  }
}

public struct SharedEpisodeProvenanceReport:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let assessments: [SharedEpisodeContributionProvenanceAssessment]
  public let independentConfirmationCount: Int
  public let semanticIndependenceProven: Bool

  public var statusesByContributionID: [String: SharedEpisodeContributionProvenanceStatus] {
    Dictionary(uniqueKeysWithValues: assessments.map { ($0.contributionID, $0.status) })
  }

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case assessments
    case independentConfirmationCount = "independent_confirmation_count"
    case semanticIndependenceProven = "semantic_independence_proven"
  }

  fileprivate init(
    assessments: [SharedEpisodeContributionProvenanceAssessment],
    independentConfirmationCount: Int
  ) {
    schemaVersion = 1
    self.assessments = assessments
    self.independentConfirmationCount = independentConfirmationCount
    semanticIndependenceProven = false
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    assessments = try container.decode(
      [SharedEpisodeContributionProvenanceAssessment].self,
      forKey: .assessments
    )
    independentConfirmationCount = try container.decode(
      Int.self,
      forKey: .independentConfirmationCount
    )
    semanticIndependenceProven = try container.decode(
      Bool.self,
      forKey: .semanticIndependenceProven
    )
    guard schemaVersion == 1,
      independentConfirmationCount >= 0,
      semanticIndependenceProven == false,
      assessments.map(\.contributionID) == assessments.map(\.contributionID).sorted(),
      Set(assessments.map(\.contributionID)).count == assessments.count
    else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Отчёт происхождения не соответствует схеме версии 1."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schemaVersion, forKey: .schemaVersion)
    try container.encode(assessments, forKey: .assessments)
    try container.encode(
      independentConfirmationCount,
      forKey: .independentConfirmationCount
    )
    try container.encode(false, forKey: .semanticIndependenceProven)
  }
}

public enum SharedEpisodeProvenanceValidator {
  public static let maximumContributions = 256
  public static let maximumLocalInputs = 128
  public static let maximumCorrelationLinks = 64
  public static let maximumInstrumentObservations = 64

  public static func analyze(
    _ contributions: [SharedEpisodeContributionProvenance]
  ) throws -> SharedEpisodeProvenanceReport {
    guard contributions.count <= maximumContributions else {
      throw provenanceFailure("Число вкладов превышает предел версии 1.")
    }

    var indexByContributionID: [String: Int] = [:]
    var observationOwnerByID: [String: Int] = [:]
    var executorOwnerByID: [String: Int] = [:]
    var sharedExecutorOwners: [(Int, Int)] = []
    var callOwnerByIdentity: [SharedEpisodeInstrumentCallIdentity: Int] = [:]
    var callDeclarationByIdentity:
      [SharedEpisodeInstrumentCallIdentity: SharedEpisodeInstrumentCallDeclaration] = [:]
    var sharedCallOwners: [(Int, Int)] = []
    for (index, contribution) in contributions.enumerated() {
      try validateLocal(contribution)
      guard indexByContributionID[contribution.contributionID] == nil else {
        throw provenanceFailure("Идентификатор вклада повторяется.")
      }
      indexByContributionID[contribution.contributionID] = index
      if let owner = executorOwnerByID[contribution.executorID] {
        sharedExecutorOwners.append((index, owner))
      } else {
        executorOwnerByID[contribution.executorID] = index
      }
      for observation in contribution.instrumentObservations {
        guard observationOwnerByID[observation.observationID] == nil else {
          throw provenanceFailure("Идентификатор инструментального наблюдения повторяется.")
        }
        observationOwnerByID[observation.observationID] = index
        let identity = SharedEpisodeInstrumentCallIdentity(
          sourceAuthority: observation.sourceAuthority,
          callID: observation.callID
        )
        let declaration = SharedEpisodeInstrumentCallDeclaration(
          inputSHA256: observation.inputSHA256,
          resultSHA256: observation.resultSHA256,
          observedAtSeconds: observation.observedAtSeconds
        )
        if let existing = callDeclarationByIdentity[identity], existing != declaration {
          throw provenanceFailure(
            "Один инструментальный вызов имеет несогласованные вход, результат или время."
          )
        }
        callDeclarationByIdentity[identity] = declaration
        if let owner = callOwnerByIdentity[identity] {
          sharedCallOwners.append((index, owner))
        } else {
          callOwnerByIdentity[identity] = index
        }
      }
    }

    for contribution in contributions {
      for observationID in contribution.derivedFromObservationIDs
      where observationOwnerByID[observationID] == nil {
        throw provenanceFailure(
          "Производное утверждение ссылается на неизвестное инструментальное наблюдение."
        )
      }
    }

    try validateObservableSharedSources(contributions)
    try validateDerivedResultInputs(contributions)
    try validateInstrumentResultInputs(contributions)

    var unionFind = SharedEpisodeProvenanceUnionFind(count: contributions.count)
    var declarationByGroupID: [String: SharedEpisodeCorrelationDeclaration] = [:]
    var groupOwnerByID: [String: Int] = [:]
    var groupIDByCommonBasis: [SharedEpisodeCorrelationBasis: String] = [:]
    var copyIndexes = Set<Int>()

    for (index, owner) in sharedExecutorOwners + sharedCallOwners {
      unionFind.union(index, owner)
    }

    for (index, contribution) in contributions.enumerated() {
      for observationID in contribution.derivedFromObservationIDs {
        guard let owner = observationOwnerByID[observationID] else { continue }
        unionFind.union(index, owner)
      }
    }

    for (index, contribution) in contributions.enumerated() {
      for link in contribution.correlationLinks {
        let declaration = SharedEpisodeCorrelationDeclaration(
          kind: link.kind,
          basisSHA256: link.basisSHA256
        )
        if let existing = declarationByGroupID[link.groupID], existing != declaration {
          throw provenanceFailure(
            "Одна группа корреляции имеет разные виды или опорные хэши."
          )
        }
        declarationByGroupID[link.groupID] = declaration

        if link.kind.isSharedObservedSource {
          let basis = SharedEpisodeCorrelationBasis(
            kind: link.kind,
            basisSHA256: link.basisSHA256
          )
          if let existingGroupID = groupIDByCommonBasis[basis], existingGroupID != link.groupID {
            throw provenanceFailure(
              "Один наблюдаемый источник разнесён по разным группам корреляции."
            )
          }
          groupIDByCommonBasis[basis] = link.groupID
        }

        if let owner = groupOwnerByID[link.groupID] {
          unionFind.union(index, owner)
        } else {
          groupOwnerByID[link.groupID] = index
        }

        switch link.kind {
        case .model, .provider, .sourceMaterial, .systemTemplate:
          guard link.sourceContributionID == nil else {
            throw provenanceFailure(
              "Группа общего источника не должна подменяться направленным ребром."
            )
          }
        case .copy, .parentResult, .derivedAnswer:
          guard let sourceID = link.sourceContributionID,
            let sourceIndex = indexByContributionID[sourceID],
            sourceIndex != index
          else {
            throw provenanceFailure(
              "Направленное ребро корреляции не ссылается на другой известный вклад."
            )
          }
          let source = contributions[sourceIndex]
          guard link.basisSHA256 == source.resultSHA256 else {
            throw provenanceFailure(
              "Ребро корреляции не закрепляет точный хэш результата источника."
            )
          }
          if link.kind == .copy {
            guard contribution.resultSHA256 == source.resultSHA256 else {
              throw provenanceFailure(
                "Прямая копия не совпадает с хэшем исходного результата."
              )
            }
            copyIndexes.insert(index)
          }
          unionFind.union(index, sourceIndex)
        }
      }
    }

    var componentSizes: [Int: Int] = [:]
    for index in contributions.indices {
      componentSizes[unionFind.find(index), default: 0] += 1
    }

    var countedComponents = Set<Int>()
    var assessments: [SharedEpisodeContributionProvenanceAssessment] = []
    for (index, contribution) in contributions.enumerated() {
      let root = unionFind.find(index)
      let status: SharedEpisodeContributionProvenanceStatus
      if copyIndexes.contains(index) {
        status = .copy
      } else if !hasCompleteObservedIdentity(contribution) {
        status = .unconfirmedProvenance
      } else if componentSizes[root, default: 0] > 1 {
        status = .correlated
      } else {
        status = .independentByObservedFeatures
      }
      if status != .copy, status != .unconfirmedProvenance {
        countedComponents.insert(root)
      }
      assessments.append(
        SharedEpisodeContributionProvenanceAssessment(
          contributionID: contribution.contributionID,
          status: status
        )
      )
    }
    assessments.sort { $0.contributionID < $1.contributionID }
    return SharedEpisodeProvenanceReport(
      assessments: assessments,
      independentConfirmationCount: countedComponents.count
    )
  }

  private static func validateLocal(
    _ contribution: SharedEpisodeContributionProvenance
  ) throws {
    guard contribution.schemaVersion == 1,
      isProvenanceIdentifier(contribution.contributionID),
      isProvenanceIdentifier(contribution.executorID),
      isProvenanceIdentifier(contribution.roleID),
      isProvenanceIdentifier(contribution.workPackageArtifactID),
      contribution.modelID.map(isObservedIdentity) ?? true,
      contribution.providerID.map(isObservedIdentity) ?? true,
      isProvenanceSHA256(contribution.taskSHA256),
      isProvenanceSHA256(contribution.parentGenerationSHA256),
      isProvenanceSHA256(contribution.resultSHA256),
      !contribution.localInputSHA256s.isEmpty,
      contribution.localInputSHA256s.count <= maximumLocalInputs,
      contribution.localInputSHA256s.allSatisfy(isProvenanceSHA256),
      contribution.localInputSHA256s == contribution.localInputSHA256s.sorted(),
      Set(contribution.localInputSHA256s).count == contribution.localInputSHA256s.count,
      !contribution.correlationLinks.isEmpty,
      contribution.correlationLinks.count <= maximumCorrelationLinks,
      contribution.correlationLinks == contribution.correlationLinks.sorted(by: correlationOrder),
      contribution.instrumentObservations.count <= maximumInstrumentObservations,
      contribution.instrumentObservations
        == contribution.instrumentObservations.sorted(by: {
          $0.observationID < $1.observationID
        }),
      contribution.derivedFromObservationIDs.count <= maximumInstrumentObservations,
      contribution.derivedFromObservationIDs
        == contribution.derivedFromObservationIDs.sorted(),
      Set(contribution.derivedFromObservationIDs).count
        == contribution.derivedFromObservationIDs.count
    else {
      throw provenanceFailure(
        "Вклад нарушает схему, пределы или канонический порядок происхождения."
      )
    }

    var linkKeys = Set<String>()
    var hasModelLink = false
    var sourceMaterialSHA256s = Set<String>()
    var hasTemplateLink = false
    for link in contribution.correlationLinks {
      guard link.schemaVersion == 1,
        isProvenanceIdentifier(link.groupID),
        isProvenanceSHA256(link.basisSHA256),
        link.sourceContributionID.map(isProvenanceIdentifier) ?? true
      else {
        throw provenanceFailure("Ребро корреляции нарушает схему версии 1.")
      }
      let key = [
        link.groupID,
        link.kind.rawValue,
        link.basisSHA256,
        link.sourceContributionID ?? "",
      ].joined(separator: "\u{0}")
      guard linkKeys.insert(key).inserted else {
        throw provenanceFailure("Ребро корреляции повторяется.")
      }
      switch link.kind {
      case .model:
        hasModelLink = true
      case .sourceMaterial:
        guard contribution.localInputSHA256s.contains(link.basisSHA256) else {
          throw provenanceFailure(
            "Группа исходного материала не связана с хэшами локальных входов."
          )
        }
        sourceMaterialSHA256s.insert(link.basisSHA256)
      case .systemTemplate:
        hasTemplateLink = true
      case .provider, .parentResult, .copy, .derivedAnswer:
        break
      }
    }
    guard sourceMaterialSHA256s == Set(contribution.localInputSHA256s),
      hasTemplateLink,
      (contribution.modelID == nil && contribution.providerID == nil) || hasModelLink
    else {
      throw provenanceFailure(
        "Наблюдаемые модель, исходный материал и системный шаблон должны иметь явные связи корреляции."
      )
    }

    var observationIDs = Set<String>()
    for observation in contribution.instrumentObservations {
      guard observation.schemaVersion == 1,
        isProvenanceIdentifier(observation.observationID),
        isProvenanceIdentifier(observation.callID),
        isProvenanceSHA256(observation.inputSHA256),
        isProvenanceSHA256(observation.resultSHA256),
        observation.observedAtSeconds >= 0,
        observation.observedAtSeconds <= Int(CanonicalMemoryJSON.maximumSafeInteger),
        observationIDs.insert(observation.observationID).inserted
      else {
        throw provenanceFailure(
          "Инструментальное наблюдение нарушает схему, хэши или временную границу версии 1."
        )
      }
    }
  }

  private static func validateObservableSharedSources(
    _ contributions: [SharedEpisodeContributionProvenance]
  ) throws {
    for leftIndex in contributions.indices {
      for rightIndex in contributions.indices where rightIndex > leftIndex {
        let left = contributions[leftIndex]
        let right = contributions[rightIndex]
        if let leftModel = left.modelID,
          let rightModel = right.modelID,
          leftModel == rightModel,
          !shareLink(left, right, kind: .model)
        {
          throw provenanceFailure(
            "Общая наблюдаемая модель не отражена одной группой корреляции."
          )
        }
        if let leftProvider = left.providerID,
          let rightProvider = right.providerID,
          leftProvider == rightProvider,
          left.modelID != right.modelID,
          !shareLink(left, right, kind: .provider)
        {
          throw provenanceFailure(
            "Общий наблюдаемый поставщик не отражён одной группой корреляции."
          )
        }
        let commonInputs = Set(left.localInputSHA256s).intersection(right.localInputSHA256s)
        if !commonInputs.isEmpty,
          !shareLink(left, right, kind: .sourceMaterial, allowedBases: commonInputs)
        {
          throw provenanceFailure(
            "Общий хэш исходного материала не отражён одной группой корреляции."
          )
        }
      }
    }
  }

  private static func validateDerivedResultInputs(
    _ contributions: [SharedEpisodeContributionProvenance]
  ) throws {
    var sourceIDsByResultSHA256: [String: Set<String>] = [:]
    for contribution in contributions {
      sourceIDsByResultSHA256[contribution.resultSHA256, default: []]
        .insert(contribution.contributionID)
    }
    for contribution in contributions {
      for inputSHA256 in contribution.localInputSHA256s {
        let sourceIDs = sourceIDsByResultSHA256[inputSHA256, default: []]
          .subtracting([contribution.contributionID])
        guard !sourceIDs.isEmpty else { continue }
        let hasDirectedEdge = contribution.correlationLinks.contains { link in
          switch link.kind {
          case .parentResult, .derivedAnswer, .copy:
            return link.basisSHA256 == inputSHA256
              && link.sourceContributionID.map(sourceIDs.contains) == true
          case .model, .provider, .sourceMaterial, .systemTemplate:
            return false
          }
        }
        guard hasDirectedEdge else {
          throw provenanceFailure(
            "Локальный вход из результата другого вклада не закреплён направленным ребром."
          )
        }
      }
    }
  }

  private static func validateInstrumentResultInputs(
    _ contributions: [SharedEpisodeContributionProvenance]
  ) throws {
    var observationIDsByResultSHA256: [String: Set<String>] = [:]
    for contribution in contributions {
      for observation in contribution.instrumentObservations {
        observationIDsByResultSHA256[observation.resultSHA256, default: []]
          .insert(observation.observationID)
      }
    }
    for contribution in contributions {
      for inputSHA256 in contribution.localInputSHA256s {
        let observationIDs = observationIDsByResultSHA256[inputSHA256, default: []]
        guard !observationIDs.isEmpty else { continue }
        guard !observationIDs.isDisjoint(with: contribution.derivedFromObservationIDs) else {
          throw provenanceFailure(
            "Локальный вход из инструментального результата не отмечен как производное модельное утверждение."
          )
        }
      }
    }
  }

  private static func shareLink(
    _ left: SharedEpisodeContributionProvenance,
    _ right: SharedEpisodeContributionProvenance,
    kind: SharedEpisodeCorrelationKind,
    allowedBases: Set<String>? = nil
  ) -> Bool {
    let leftLinks = left.correlationLinks.filter {
      $0.kind == kind && (allowedBases?.contains($0.basisSHA256) ?? true)
    }
    return right.correlationLinks.contains { rightLink in
      rightLink.kind == kind
        && (allowedBases?.contains(rightLink.basisSHA256) ?? true)
        && leftLinks.contains {
          $0.groupID == rightLink.groupID && $0.basisSHA256 == rightLink.basisSHA256
        }
    }
  }

  private static func hasCompleteObservedIdentity(
    _ contribution: SharedEpisodeContributionProvenance
  ) -> Bool {
    contribution.modelID != nil && contribution.providerID != nil
  }

  private static func correlationOrder(
    _ left: SharedEpisodeCorrelationLink,
    _ right: SharedEpisodeCorrelationLink
  ) -> Bool {
    if left.groupID != right.groupID { return left.groupID < right.groupID }
    if left.kind.rawValue != right.kind.rawValue {
      return left.kind.rawValue < right.kind.rawValue
    }
    if left.basisSHA256 != right.basisSHA256 {
      return left.basisSHA256 < right.basisSHA256
    }
    return (left.sourceContributionID ?? "") < (right.sourceContributionID ?? "")
  }
}

extension SharedEpisodeCorrelationKind {
  fileprivate var isSharedObservedSource: Bool {
    switch self {
    case .model, .provider, .sourceMaterial, .systemTemplate:
      return true
    case .parentResult, .copy, .derivedAnswer:
      return false
    }
  }
}

private struct SharedEpisodeCorrelationDeclaration: Equatable {
  let kind: SharedEpisodeCorrelationKind
  let basisSHA256: String
}

private struct SharedEpisodeCorrelationBasis: Hashable {
  let kind: SharedEpisodeCorrelationKind
  let basisSHA256: String
}

private struct SharedEpisodeInstrumentCallIdentity: Hashable {
  let sourceAuthority: SharedEpisodeInstrumentSourceAuthority
  let callID: String
}

private struct SharedEpisodeInstrumentCallDeclaration: Equatable {
  let inputSHA256: String
  let resultSHA256: String
  let observedAtSeconds: Int
}

private struct SharedEpisodeProvenanceUnionFind {
  private var parents: [Int]
  private var ranks: [Int]

  init(count: Int) {
    parents = Array(0..<count)
    ranks = Array(repeating: 0, count: count)
  }

  mutating func find(_ index: Int) -> Int {
    var root = index
    while parents[root] != root {
      root = parents[root]
    }
    var cursor = index
    while parents[cursor] != cursor {
      let next = parents[cursor]
      parents[cursor] = root
      cursor = next
    }
    return root
  }

  mutating func union(_ left: Int, _ right: Int) {
    let leftRoot = find(left)
    let rightRoot = find(right)
    guard leftRoot != rightRoot else { return }
    if ranks[leftRoot] < ranks[rightRoot] {
      parents[leftRoot] = rightRoot
    } else if ranks[leftRoot] > ranks[rightRoot] {
      parents[rightRoot] = leftRoot
    } else {
      parents[rightRoot] = leftRoot
      ranks[leftRoot] += 1
    }
  }
}

private func provenanceFailure(_ message: String) -> SharedEpisodeMemoryError {
  .invalidContribution(message)
}

private func isProvenanceSHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}

private func isProvenanceIdentifier(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 128 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    switch scalar.value {
    case 45, 46, 48...57, 65...90, 95, 97...122:
      true
    default:
      false
    }
  }
}

private func isObservedIdentity(_ value: String) -> Bool {
  guard !value.isEmpty, value.utf8.count <= 256 else { return false }
  return value.unicodeScalars.allSatisfy { scalar in
    scalar.value >= 0x20 && scalar.value != 0x7f
      && !(0xfdd0...0xfdef).contains(scalar.value)
      && scalar.value & 0xffff != 0xfffe
      && scalar.value & 0xffff != 0xffff
  }
}
