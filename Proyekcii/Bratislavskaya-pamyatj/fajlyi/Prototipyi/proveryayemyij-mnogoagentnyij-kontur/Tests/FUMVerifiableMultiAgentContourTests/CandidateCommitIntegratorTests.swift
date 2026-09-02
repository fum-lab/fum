import CryptoKit
import Dispatch
import Foundation
import Testing

@testable import FUMVerifiableMultiAgentContour

@Suite("CAS-интеграция кандидатных commit")
struct CandidateCommitIntegratorTests {
  @Test("один кандидат публикуется CAS и остаётся прямым предком")
  func integratesOneCandidateWithoutRewritingIt() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-one",
      subnodeID: "writer-one",
      path: "output/one.txt",
      contents: "one\n"
    )
    let candidateBefore = try fixture.candidateSnapshot(candidate)
    let writersBefore = try fixture.writerSnapshot()
    let sentinelBefore = try fixture.sentinelSnapshot()
    let request = fixture.request(
      attemptID: "attempt-one",
      candidates: [candidate.reference],
      checks: ["one"]
    )
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "one": .regularFileSHA256(
          path: "output/one.txt",
          expectedSHA256: fixture.sha256("one\n")
        )
      ])
    )

    let result = try integrator.integrate(request)

    #expect(result.outcome == .integrated)
    let integrationOID = try #require(result.integrationOID)
    let passport = try #require(result.passport)
    #expect(try fixture.targetOID() == integrationOID)
    #expect(
      try fixture.parents(of: integrationOID)
        == [fixture.baseOID, candidate.commitOID]
    )
    #expect(try fixture.isAncestor(candidate.commitOID, of: integrationOID))
    #expect(passport.candidateOIDs == [candidate.commitOID])
    #expect(passport.expectedTargetOID == fixture.baseOID)
    #expect(passport.targetRef == "refs/heads/main")
    #expect(try fixture.candidateSnapshot(candidate) == candidateBefore)
    #expect(try fixture.writerSnapshot() == writersBefore)
    #expect(try fixture.sentinelSnapshot() == sentinelBefore)
  }

  @Test("несколько независимых кандидатов получают канонический порядок родителей")
  func integratesMultipleCandidatesInCanonicalOrder() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let second = try fixture.candidate(
      runID: "run-second",
      subnodeID: "writer-second",
      path: "output/second.txt",
      contents: "second\n"
    )
    let first = try fixture.candidate(
      runID: "run-first",
      subnodeID: "writer-first",
      path: "output/first.txt",
      contents: "first\n"
    )
    let candidates = [second, first]
    let sortedOIDs = candidates.map(\.commitOID).sorted()
    let request = fixture.request(
      attemptID: "attempt-many",
      candidates: candidates.map(\.reference),
      checks: ["first", "second"]
    )
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "first": .regularFileSHA256(
          path: "output/first.txt", expectedSHA256: fixture.sha256("first\n")),
        "second": .regularFileSHA256(
          path: "output/second.txt", expectedSHA256: fixture.sha256("second\n")),
      ])
    )

    let result = try integrator.integrate(request)

    let integrationOID = try #require(result.integrationOID)
    #expect(result.outcome == .integrated)
    #expect(try fixture.parents(of: integrationOID) == [fixture.baseOID] + sortedOIDs)
    for oid in sortedOIDs {
      #expect(try fixture.isAncestor(oid, of: integrationOID))
    }
  }

  @Test("производный manifest полностью пересобирается из объединённых канонических источников")
  func rebuildsDerivedManifestFromCanonicalSources() throws {
    let baseManifest = try CandidateDerivedManifest(
      schemaIdentity: "fum.fixture.derived-manifest",
      schemaVersion: 1,
      sources: [
        CandidateDerivedManifestSource(
          path: "sources/a.txt",
          sha256: sha256Text("a0\n"),
          byteCount: 3
        ),
        CandidateDerivedManifestSource(
          path: "sources/b.txt",
          sha256: sha256Text("b0\n"),
          byteCount: 3
        ),
      ]
    ).canonicalJSONData()
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "derived/index.json": String(decoding: baseManifest, as: UTF8.self),
      "sources/a.txt": "a0\n",
      "sources/b.txt": "b0\n",
    ])
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-derived-left",
      subnodeID: "writer-derived-left",
      writes: [
        "derived/index.json": "left branch must not win\n",
        "sources/a.txt": "a1\n",
      ]
    )
    let right = try fixture.candidate(
      runID: "run-derived-right",
      subnodeID: "writer-derived-right",
      writes: [
        "derived/index.json": "right branch must not win\n",
        "sources/b.txt": "b1\n",
      ]
    )
    let expectedManifest = try CandidateDerivedManifest(
      schemaIdentity: "fum.fixture.derived-manifest",
      schemaVersion: 1,
      sources: [
        CandidateDerivedManifestSource(
          path: "sources/a.txt",
          sha256: fixture.sha256("a1\n"),
          byteCount: 3
        ),
        CandidateDerivedManifestSource(
          path: "sources/b.txt",
          sha256: fixture.sha256("b1\n"),
          byteCount: 3
        ),
      ]
    ).canonicalJSONData()
    let resolverRegistry = CandidateConflictResolverRegistry(specifications: [
      "derived-index": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "derived/index.json",
        sourcePaths: ["sources/a.txt", "sources/b.txt"],
        schemaIdentity: "fum.fixture.derived-manifest",
        schemaVersion: 1,
        requiredCheckIDs: ["derived-index"]
      )
    ])
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "derived-index": .regularFileSHA256(
          path: "derived/index.json",
          expectedSHA256: "sha256:" + sha256Data(expectedManifest)
        )
      ]),
      resolverRegistry: resolverRegistry
    )

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-derived",
        candidates: [left.reference, right.reference],
        checks: ["derived-index"],
        resolverRuleIDs: ["derived-index"]
      )
    )

    #expect(result.outcome == .integrated)
    let integrationOID = try #require(result.integrationOID)
    let passport = try #require(result.passport)
    #expect(
      try fixture.blobData(at: integrationOID, path: "derived/index.json")
        == expectedManifest
    )
    #expect(passport.resolutions.map(\.ruleID) == ["derived-index"])
    #expect(passport.resolutions.map(\.ruleVersion) == [1])
    #expect(passport.schemaVersion == 2)
    #expect(
      passport.resolverRegistryIdentity
        == CandidateConflictResolverRegistry.registryIdentity
    )
    #expect(
      passport.resolverRegistryVersion
        == CandidateConflictResolverRegistry.registryVersion
    )
    #expect(passport.resolverRules.map(\.ruleID) == ["derived-index"])
    #expect(passport.resolverRules.map(\.path) == ["derived/index.json"])
    #expect(passport.resolutions.map(\.requiredCheckIDs) == [["derived-index"]])
    #expect(passport.resolutions.first?.inputSHA256s.count == 2)
    #expect(passport.resolutions.first?.invariants.contains("manifest_rebuilt") == true)
    #expect(
      passport.resolutions.first?.outputSHA256
        == "sha256:" + sha256Data(expectedManifest)
    )
    #expect(passport.checks == passport.repeatedChecks)
    #expect(
      try fixture.parents(of: integrationOID) == [fixture.baseOID]
        + [left, right].map(\.commitOID).sorted())
  }

  @Test("записи с устойчивыми ID объединяются при согласованной схеме и полях")
  func mergesStableRecordsWithCompatibleNormativeFields() throws {
    let baseDocument = try stableDocument([
      stableRecord(id: "base", normative: ["policy": "stable", "slug": "base"])
    ])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let leftDocument = try stableDocument([
      stableRecord(id: "base", normative: ["policy": "stable", "slug": "base"]),
      stableRecord(
        id: "left",
        normative: ["policy": "automatic", "slug": "left"],
        informative: ["note": "left contribution"]
      ),
    ])
    let rightDocument = try stableDocument([
      stableRecord(id: "base", normative: ["policy": "stable", "slug": "base"]),
      stableRecord(
        id: "right",
        normative: ["policy": "automatic", "slug": "right"],
        informative: ["note": "right contribution"]
      ),
    ])
    let expectedDocument = try stableDocument([
      stableRecord(id: "base", normative: ["policy": "stable", "slug": "base"]),
      stableRecord(
        id: "left",
        normative: ["policy": "automatic", "slug": "left"],
        informative: ["note": "left contribution"]
      ),
      stableRecord(
        id: "right",
        normative: ["policy": "automatic", "slug": "right"],
        informative: ["note": "right contribution"]
      ),
    ])
    let left = try fixture.candidate(
      runID: "run-record-left",
      subnodeID: "writer-record-left",
      path: "registry/records.json",
      contents: String(decoding: leftDocument, as: UTF8.self)
    )
    let right = try fixture.candidate(
      runID: "run-record-right",
      subnodeID: "writer-record-right",
      path: "registry/records.json",
      contents: String(decoding: rightDocument, as: UTF8.self)
    )
    let integrator = stableRecordIntegrator(
      fixture: fixture,
      expectedDocument: expectedDocument
    )

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-record-union",
        candidates: [left.reference, right.reference],
        checks: ["stable-records"],
        resolverRuleIDs: ["stable-records"]
      )
    )

    #expect(result.outcome == .integrated)
    let integrationOID = try #require(result.integrationOID)
    #expect(
      try fixture.blobData(at: integrationOID, path: "registry/records.json")
        == expectedDocument
    )
    #expect(result.passport?.resolutions.map(\.algorithm) == ["merge_stable_records_v1"])
  }

  @Test("неизвестный конфликт сохраняет варианты и каноническую диагностику")
  func unknownConflictRequiresResolutionAndPreservesInputs() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-unknown-left",
      subnodeID: "writer-unknown-left",
      path: "shared.txt",
      contents: "left\n"
    )
    let right = try fixture.candidate(
      runID: "run-unknown-right",
      subnodeID: "writer-unknown-right",
      path: "shared.txt",
      contents: "right\n"
    )
    let targetBefore = try fixture.targetSnapshot()
    let leftBefore = try fixture.candidateSnapshot(left)
    let rightBefore = try fixture.candidateSnapshot(right)
    let request = fixture.request(
      attemptID: "attempt-unknown-conflict",
      candidates: [left.reference, right.reference]
    )
    let integrator = fixture.integrator()

    let first = try integrator.integrate(request)
    let second = try integrator.integrate(request)

    #expect(first.outcome == .resolutionRequired)
    #expect(second.outcome == .resolutionRequired)
    #expect(first.diagnosticCanonicalJSON == second.diagnosticCanonicalJSON)
    #expect(first.diagnosticSHA256 == second.diagnosticSHA256)
    #expect(first.diagnostic?.issues.map(\.reason) == [.unknownPath])
    #expect(first.diagnostic?.affectedPaths == ["shared.txt"])
    #expect(first.diagnostic?.inputs.count == 4)
    #expect(
      try fixture.resolutionDiagnosticData(attemptID: "attempt-unknown-conflict")
        == first.diagnosticCanonicalJSON
    )
    let retainedInputs = try fixture.retainedIntegrationInputOIDs(
      attemptID: "attempt-unknown-conflict"
    )
    #expect(retainedInputs.count == 4)
    #expect(
      Set(retainedInputs)
        == Set([fixture.baseOID, left.commitOID, right.commitOID])
    )
    #expect(try fixture.targetSnapshot() == targetBefore)
    #expect(try fixture.candidateSnapshot(left) == leftBefore)
    #expect(try fixture.candidateSnapshot(right) == rightBefore)
  }

  @Test("конкурирующие правила одного пути требуют явного разрешения")
  func ambiguousRulesRequireResolution() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-ambiguous-left",
      subnodeID: "writer-ambiguous-left",
      path: "shared.txt",
      contents: "left\n"
    )
    let right = try fixture.candidate(
      runID: "run-ambiguous-right",
      subnodeID: "writer-ambiguous-right",
      path: "shared.txt",
      contents: "right\n"
    )
    let registry = CandidateConflictResolverRegistry(specifications: [
      "shared-a": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "shared.txt",
        sourcePaths: ["base.txt"],
        schemaIdentity: "fum.fixture.shared-a",
        schemaVersion: 1,
        requiredCheckIDs: ["base"]
      ),
      "shared-b": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "shared.txt",
        sourcePaths: ["base.txt"],
        schemaIdentity: "fum.fixture.shared-b",
        schemaVersion: 1,
        requiredCheckIDs: ["base"]
      ),
    ])
    let integrator = fixture.integrator(resolverRegistry: registry)

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-ambiguous",
        candidates: [left.reference, right.reference],
        resolverRuleIDs: ["shared-a", "shared-b"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.ambiguousRule])
    #expect(result.diagnostic?.issues.first?.matchingRuleIDs == ["shared-a", "shared-b"])
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("отсутствующая обязательная проверка нарушает предусловие resolver")
  func missingRequiredResolverCheckRequiresResolution() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-check-precondition-left",
      subnodeID: "writer-check-precondition-left",
      path: "shared.txt",
      contents: "left\n"
    )
    let right = try fixture.candidate(
      runID: "run-check-precondition-right",
      subnodeID: "writer-check-precondition-right",
      path: "shared.txt",
      contents: "right\n"
    )
    let registry = CandidateConflictResolverRegistry(specifications: [
      "shared": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "shared.txt",
        sourcePaths: ["base.txt"],
        schemaIdentity: "fum.fixture.shared",
        schemaVersion: 1,
        requiredCheckIDs: ["resolver-check"]
      )
    ])

    let result = try fixture.integrator(resolverRegistry: registry).integrate(
      fixture.request(
        attemptID: "attempt-required-check",
        candidates: [left.reference, right.reference],
        resolverRuleIDs: ["shared"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.preconditionFailed])
    #expect(result.diagnostic?.issues.first?.ruleID == "shared")
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("разные нормативные значения одного ID закрывают объединение")
  func conflictingNormativeFieldRequiresResolution() throws {
    let baseDocument = try stableDocument([])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-normative-left",
      subnodeID: "writer-normative-left",
      path: "registry/records.json",
      contents: String(
        decoding: try stableDocument([
          stableRecord(id: "same", normative: ["policy": "left", "slug": "same"])
        ]),
        as: UTF8.self
      )
    )
    let right = try fixture.candidate(
      runID: "run-normative-right",
      subnodeID: "writer-normative-right",
      path: "registry/records.json",
      contents: String(
        decoding: try stableDocument([
          stableRecord(id: "same", normative: ["policy": "right", "slug": "same"])
        ]),
        as: UTF8.self
      )
    )
    let integrator = stableRecordIntegrator(
      fixture: fixture,
      expectedDocument: baseDocument
    )

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-normative-conflict",
        candidates: [left.reference, right.reference],
        checks: ["stable-records"],
        resolverRuleIDs: ["stable-records"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.normativeFieldConflict])
    #expect(result.diagnostic?.issues.first?.recordID == "same")
    #expect(result.diagnostic?.issues.first?.field == "policy")
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("несогласованная схема закрывает объединение записей")
  func mismatchedStableRecordSchemaRequiresResolution() throws {
    let baseDocument = try stableDocument([])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let compatible = try stableDocument([
      stableRecord(id: "left", normative: ["policy": "stable", "slug": "left"])
    ])
    let mismatched = try CandidateStableRecordDocument(
      schemaIdentity: "fum.fixture.stable-records",
      schemaVersion: 2,
      records: [
        stableRecord(id: "right", normative: ["policy": "stable", "slug": "right"])
      ]
    ).canonicalJSONData()
    let left = try fixture.candidate(
      runID: "run-schema-left",
      subnodeID: "writer-schema-left",
      path: "registry/records.json",
      contents: String(decoding: compatible, as: UTF8.self)
    )
    let right = try fixture.candidate(
      runID: "run-schema-right",
      subnodeID: "writer-schema-right",
      path: "registry/records.json",
      contents: String(decoding: mismatched, as: UTF8.self)
    )

    let result = try stableRecordIntegrator(
      fixture: fixture,
      expectedDocument: baseDocument
    ).integrate(
      fixture.request(
        attemptID: "attempt-schema-mismatch",
        candidates: [left.reference, right.reference],
        checks: ["stable-records"],
        resolverRuleIDs: ["stable-records"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.schemaMismatch])
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("повторяющийся устойчивый ID закрывает объединение")
  func duplicateStableRecordIDRequiresResolution() throws {
    let baseDocument = try stableDocument([])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let duplicateDocument = """
      {
        "records": [
          {"id":"same","informative":{},"normative":{"policy":"stable","slug":"one"}},
          {"id":"same","informative":{},"normative":{"policy":"stable","slug":"two"}}
        ],
        "schema_identity": "fum.fixture.stable-records",
        "schema_version": 1
      }
      """
    let validDocument = try stableDocument([
      stableRecord(id: "other", normative: ["policy": "stable", "slug": "other"])
    ])
    let duplicate = try fixture.candidate(
      runID: "run-duplicate",
      subnodeID: "writer-duplicate",
      path: "registry/records.json",
      contents: duplicateDocument
    )
    let valid = try fixture.candidate(
      runID: "run-duplicate-peer",
      subnodeID: "writer-duplicate-peer",
      path: "registry/records.json",
      contents: String(decoding: validDocument, as: UTF8.self)
    )

    let result = try stableRecordIntegrator(
      fixture: fixture,
      expectedDocument: baseDocument
    ).integrate(
      fixture.request(
        attemptID: "attempt-duplicate-id",
        candidates: [duplicate.reference, valid.reference],
        checks: ["stable-records"],
        resolverRuleIDs: ["stable-records"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.duplicateID])
    #expect(result.diagnostic?.issues.first?.recordID == "same")
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("смысловая несовместимость обнаруживается после чистого textual merge")
  func semanticConflictWithoutTextConflictRequiresResolution() throws {
    let baseDocument = try stableDocument([
      stableRecord(id: "alpha", normative: ["policy": "stable", "slug": "alpha"]),
      stableRecord(id: "omega", normative: ["policy": "stable", "slug": "omega"]),
    ])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let leftDocument = try stableDocument([
      stableRecord(id: "alpha", normative: ["policy": "stable", "slug": "shared"]),
      stableRecord(id: "omega", normative: ["policy": "stable", "slug": "omega"]),
    ])
    let rightDocument = try stableDocument([
      stableRecord(id: "alpha", normative: ["policy": "stable", "slug": "alpha"]),
      stableRecord(id: "omega", normative: ["policy": "stable", "slug": "shared"]),
    ])
    let left = try fixture.candidate(
      runID: "run-semantic-left",
      subnodeID: "writer-semantic-left",
      path: "registry/records.json",
      contents: String(decoding: leftDocument, as: UTF8.self)
    )
    let right = try fixture.candidate(
      runID: "run-semantic-right",
      subnodeID: "writer-semantic-right",
      path: "registry/records.json",
      contents: String(decoding: rightDocument, as: UTF8.self)
    )
    #expect(try fixture.textualMergeSucceeds([left, right]))
    let integrator = stableRecordIntegrator(
      fixture: fixture,
      expectedDocument: baseDocument
    )

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-semantic-clean",
        candidates: [left.reference, right.reference],
        checks: ["stable-records"],
        resolverRuleIDs: ["stable-records"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.semanticConflict])
    #expect(result.diagnostic?.issues.first?.field == "slug")
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("сбой обязательной проверки после resolver не публикует дерево")
  func failedCheckAfterResolutionRequiresResolution() throws {
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "derived/index.json": "base\n",
      "sources/a.txt": "a0\n",
      "sources/b.txt": "b0\n",
    ])
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-check-left",
      subnodeID: "writer-check-left",
      writes: [
        "derived/index.json": "left\n",
        "sources/a.txt": "a1\n",
      ]
    )
    let right = try fixture.candidate(
      runID: "run-check-right",
      subnodeID: "writer-check-right",
      writes: [
        "derived/index.json": "right\n",
        "sources/b.txt": "b1\n",
      ]
    )
    let resolverRegistry = CandidateConflictResolverRegistry(specifications: [
      "derived-index": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "derived/index.json",
        sourcePaths: ["sources/a.txt", "sources/b.txt"],
        schemaIdentity: "fum.fixture.derived-manifest",
        schemaVersion: 1,
        requiredCheckIDs: ["derived-index"]
      )
    ])
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "derived-index": .regularFileSHA256(
          path: "derived/index.json",
          expectedSHA256: fixture.sha256("impossible\n")
        )
      ]),
      resolverRegistry: resolverRegistry
    )

    let result = try integrator.integrate(
      fixture.request(
        attemptID: "attempt-resolved-check-failure",
        candidates: [left.reference, right.reference],
        checks: ["derived-index"],
        resolverRuleIDs: ["derived-index"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.checkFailed])
    #expect(result.diagnostic?.checks.map(\.status) == [.failed])
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("движение цели отменяет старую подготовку, свежая база требует новой попытки")
  func targetMovementRequiresFreshAttemptAndChecks() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-fresh",
      subnodeID: "writer-fresh",
      path: "output/candidate.txt",
      contents: "candidate\n"
    )
    let oldTarget = fixture.baseOID
    let movedTarget = try fixture.advanceTarget(
      path: "output/concurrent.txt", contents: "concurrent\n")
    let registry = CandidateIntegrationCheckRegistry(specifications: [
      "candidate": .regularFileSHA256(
        path: "output/candidate.txt", expectedSHA256: fixture.sha256("candidate\n")),
      "concurrent": .regularFileSHA256(
        path: "output/concurrent.txt", expectedSHA256: fixture.sha256("concurrent\n")),
    ])
    let stale = fixture.request(
      attemptID: "attempt-stale",
      expectedTargetOID: oldTarget,
      candidates: [candidate.reference],
      checks: ["candidate", "concurrent"]
    )

    let staleResult = try CandidateCommitIntegrator(checkRegistry: registry).integrate(stale)

    #expect(staleResult.outcome == .targetChanged)
    #expect(try fixture.targetOID() == movedTarget)

    let fresh = fixture.request(
      attemptID: "attempt-fresh",
      expectedTargetOID: movedTarget,
      candidates: [candidate.reference],
      checks: ["candidate", "concurrent"]
    )
    let freshResult = try CandidateCommitIntegrator(checkRegistry: registry).integrate(fresh)
    let integrationOID = try #require(freshResult.integrationOID)
    #expect(freshResult.outcome == .integrated)
    #expect(try fixture.parents(of: integrationOID) == [movedTarget, candidate.commitOID])
    #expect(
      try fixture.blob(at: integrationOID, path: "output/concurrent.txt") == "concurrent"
    )
    #expect(freshResult.passport?.checks.map(\.checkID) == ["candidate", "concurrent"])
  }

  @Test("проигранный CAS не перезаписывает конкурентную вершину")
  func lostCompareAndSwapDoesNotPublishPreparedTree() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-cas",
      subnodeID: "writer-cas",
      path: "output/cas.txt",
      contents: "candidate\n"
    )
    let request = fixture.request(
      attemptID: "attempt-cas",
      candidates: [candidate.reference],
      checks: ["candidate"]
    )
    let movedOID = LockedValue<String>()
    let writersBefore = try fixture.writerSnapshot()
    let hooks = CandidateCommitIntegratorHooks(
      beforeCompareAndSwap: {
        movedOID.set(
          try fixture.advanceTarget(path: "output/winner.txt", contents: "winner\n"))
      }
    )
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "candidate": .regularFileSHA256(
          path: "output/cas.txt", expectedSHA256: fixture.sha256("candidate\n"))
      ]),
      hooks: hooks
    )

    let result = try integrator.integrate(request)

    #expect(result.outcome == .casLost)
    #expect(result.integrationOID == nil)
    #expect(try fixture.targetOID() == movedOID.get())
    #expect(try fixture.candidateIsReachable(candidate))
    #expect(try fixture.writerSnapshot() == writersBefore)

    let freshTarget = try #require(movedOID.get())
    let fresh = fixture.request(
      attemptID: "attempt-cas-fresh",
      expectedTargetOID: freshTarget,
      candidates: [candidate.reference],
      checks: ["candidate"]
    )
    let freshResult = try CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "candidate": .regularFileSHA256(
          path: "output/cas.txt", expectedSHA256: fixture.sha256("candidate\n"))
      ])
    ).integrate(fresh)
    let freshOID = try #require(freshResult.integrationOID)
    #expect(freshResult.outcome == .integrated)
    #expect(try fixture.parents(of: freshOID) == [freshTarget, candidate.commitOID])
    #expect(freshResult.passport?.checks.allSatisfy { $0.status == .passed } == true)
  }

  @Test("точный повтор успешной попытки идемпотентен")
  func exactSuccessfulRepeatIsIdempotent() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-repeat",
      subnodeID: "writer-repeat",
      path: "output/repeat.txt",
      contents: "repeat\n"
    )
    let request = fixture.request(
      attemptID: "attempt-repeat", candidates: [candidate.reference], checks: ["repeat"])
    let integrator = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "repeat": .regularFileSHA256(
          path: "output/repeat.txt", expectedSHA256: fixture.sha256("repeat\n"))
      ])
    )

    let first = try integrator.integrate(request)
    let targetAfterFirst = try fixture.targetSnapshot()
    let second = try integrator.integrate(request)

    #expect(first.outcome == .integrated)
    #expect(second.outcome == .alreadyIntegrated)
    #expect(second.integrationOID == first.integrationOID)
    #expect(second.passport == first.passport)
    #expect(try fixture.targetSnapshot() == targetAfterFirst)

    let changedRequest = fixture.request(
      attemptID: "attempt-repeat",
      commitMessage: "Changed integration request",
      candidates: [candidate.reference],
      checks: ["repeat"]
    )
    let changed = try integrator.integrate(changedRequest)
    #expect(changed.outcome == .attemptAlreadyExists)
    #expect(try fixture.targetSnapshot() == targetAfterFirst)
  }

  @Test("сбой ответа после CAS восстанавливается из подготовленного паспорта")
  func crashAfterCompareAndSwapRecoversAsSuccess() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-crash",
      subnodeID: "writer-crash",
      path: "output/crash.txt",
      contents: "crash\n"
    )
    let request = fixture.request(
      attemptID: "attempt-crash", candidates: [candidate.reference], checks: ["crash"])
    let registry = CandidateIntegrationCheckRegistry(specifications: [
      "crash": .regularFileSHA256(
        path: "output/crash.txt", expectedSHA256: fixture.sha256("crash\n"))
    ])
    let crashing = CandidateCommitIntegrator(
      checkRegistry: registry,
      hooks: CandidateCommitIntegratorHooks(afterCompareAndSwap: { throw FixtureFailure.crash })
    )

    #expect(throws: FixtureFailure.self) {
      try crashing.integrate(request)
    }
    let publishedOID = try fixture.targetOID()

    let recovered = try CandidateCommitIntegrator(checkRegistry: registry).integrate(request)

    #expect(recovered.outcome == .alreadyIntegrated)
    #expect(recovered.integrationOID == publishedOID)
    #expect(try fixture.parents(of: publishedOID) == [fixture.baseOID, candidate.commitOID])
  }

  @Test("сбой после подготовки сохраняет commit прямой ссылкой и допускает безопасный повтор")
  func crashBeforeCompareAndSwapRetainsPreparedCommit() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-prepared",
      subnodeID: "writer-prepared",
      path: "output/prepared.txt",
      contents: "prepared\n"
    )
    let request = fixture.request(
      attemptID: "attempt-prepared",
      candidates: [candidate.reference],
      checks: ["prepared"]
    )
    let registry = CandidateIntegrationCheckRegistry(specifications: [
      "prepared": .regularFileSHA256(
        path: "output/prepared.txt", expectedSHA256: fixture.sha256("prepared\n"))
    ])
    let interrupted = CandidateCommitIntegrator(
      checkRegistry: registry,
      hooks: CandidateCommitIntegratorHooks(beforeCompareAndSwap: {
        throw FixtureFailure.crash
      })
    )

    #expect(throws: FixtureFailure.self) {
      try interrupted.integrate(request)
    }
    #expect(try fixture.targetOID() == fixture.baseOID)
    try fixture.pruneIntegrationObjects(attemptID: "attempt-prepared")

    let recovered = try CandidateCommitIntegrator(checkRegistry: registry).integrate(request)
    let integrationOID = try #require(recovered.integrationOID)
    #expect(recovered.outcome == .integrated)
    #expect(try fixture.parents(of: integrationOID) == [fixture.baseOID, candidate.commitOID])
  }

  @Test("неизвестный кандидат и повреждённый паспорт не меняют цель")
  func rejectsUnknownAndCorruptCandidates() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-corrupt",
      subnodeID: "writer-corrupt",
      path: "output/corrupt.txt",
      contents: "valid\n"
    )
    let targetBefore = try fixture.targetSnapshot()
    let unknown = CandidateCommitReference(
      runID: candidate.reference.runID,
      executionRootURL: candidate.reference.executionRootURL,
      expectedCommitOID: String(repeating: "0", count: candidate.commitOID.count),
      expectedPassportSHA256: candidate.reference.expectedPassportSHA256
    )

    let unknownResult = try fixture.integrator().integrate(
      fixture.request(attemptID: "attempt-unknown", candidates: [unknown]))
    #expect(unknownResult.outcome == .candidateInvalid)
    #expect(try fixture.targetSnapshot() == targetBefore)

    try fixture.corruptPassport(runID: candidate.reference.runID)
    let corruptResult = try fixture.integrator().integrate(
      fixture.request(attemptID: "attempt-corrupt", candidates: [candidate.reference]))
    #expect(corruptResult.outcome == .candidateInvalid)
    #expect(try fixture.targetSnapshot() == targetBefore)
  }

  @Test("текстовый конфликт и смысловая ошибка валидатора не публикуются")
  func rejectsTextConflictAndSemanticFailure() throws {
    let conflictFixture = try CandidateIntegrationFixture()
    defer { conflictFixture.remove() }
    let left = try conflictFixture.candidate(
      runID: "run-left",
      subnodeID: "writer-left",
      path: "shared.txt",
      contents: "left\n"
    )
    let right = try conflictFixture.candidate(
      runID: "run-right",
      subnodeID: "writer-right",
      path: "shared.txt",
      contents: "right\n"
    )
    let conflictTarget = try conflictFixture.targetSnapshot()

    let conflict = try conflictFixture.integrator().integrate(
      conflictFixture.request(
        attemptID: "attempt-conflict", candidates: [left.reference, right.reference]))

    #expect(conflict.outcome == .resolutionRequired)
    #expect(conflict.diagnostic?.issues.map(\.reason) == [.unknownPath])
    #expect(try conflictFixture.targetSnapshot() == conflictTarget)

    let semanticFixture = try CandidateIntegrationFixture()
    defer { semanticFixture.remove() }
    let clean = try semanticFixture.candidate(
      runID: "run-semantic",
      subnodeID: "writer-semantic",
      path: "output/meaning.txt",
      contents: "syntactically clean\n"
    )
    let rule = try semanticFixture.candidate(
      runID: "run-semantic-rule",
      subnodeID: "writer-semantic-rule",
      path: "output/rule.txt",
      contents: "meaning must be semantically valid\n"
    )
    let semanticTarget = try semanticFixture.targetSnapshot()
    let semantic = try CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "semantic": .regularFileSHA256(
          path: "output/meaning.txt",
          expectedSHA256: semanticFixture.sha256("semantically valid\n")
        )
      ])
    ).integrate(
      semanticFixture.request(
        attemptID: "attempt-semantic",
        candidates: [clean.reference, rule.reference],
        checks: ["semantic"]
      )
    )
    #expect(semantic.outcome == .resolutionRequired)
    #expect(semantic.diagnostic?.issues.map(\.reason) == [.checkFailed])
    #expect(try semanticFixture.targetSnapshot() == semanticTarget)
  }

  @Test("машинный мусор отклоняется, секрет не становится кандидатом")
  func rejectsMachineJunkAndSecret() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let junk = try fixture.candidate(
      runID: "run-junk",
      subnodeID: "writer-junk",
      path: ".DS_Store",
      contents: "harmless machine state\n"
    )
    let targetBefore = try fixture.targetSnapshot()

    let junkResult = try fixture.integrator().integrate(
      fixture.request(attemptID: "attempt-junk", candidates: [junk.reference]))
    #expect(junkResult.outcome == .publicationRejected)
    #expect(try fixture.targetSnapshot() == targetBefore)

    let messageResult = try fixture.integrator().integrate(
      fixture.request(
        attemptID: "attempt-secret-message",
        commitMessage: "authorization: bearer forbidden-message",
        candidates: [junk.reference]
      )
    )
    #expect(messageResult.outcome == .secretDetected)
    #expect(try fixture.targetSnapshot() == targetBefore)

    let localPathMessage = try fixture.integrator().integrate(
      fixture.request(
        attemptID: "attempt-local-message",
        commitMessage: "Use /Users/local/machine state",
        candidates: [junk.reference]
      )
    )
    #expect(localPathMessage.outcome == .publicationRejected)
    #expect(try fixture.targetSnapshot() == targetBefore)

    #expect(throws: WritingSubnodeExecutorError.self) {
      try CandidateCommitIntegrator().integrate(
        fixture.request(
          attemptID: "attempt-without-checks",
          candidates: [junk.reference],
          checks: []
        )
      )
    }

    let secret = try fixture.rawWritingResult(
      runID: "run-secret",
      subnodeID: "writer-secret",
      path: "output/secret.txt",
      contents: "authorization: bearer forbidden-value\n"
    )
    #expect(secret.outcome == .secretDetected)
    #expect(secret.passport == nil)
    #expect(try fixture.targetSnapshot() == targetBefore)
  }

  @Test("одна цель допускает только одного локального интеграционного владельца")
  func serializesOneTargetOwner() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-owner",
      subnodeID: "writer-owner",
      path: "output/owner.txt",
      contents: "owner\n"
    )
    let gate = IntegrationGate()
    let firstResult = LockedValue<Result<CandidateCommitIntegrationResult, Error>>()
    let group = DispatchGroup()
    let registry = CandidateIntegrationCheckRegistry(specifications: [
      "owner": .regularFileSHA256(
        path: "output/owner.txt", expectedSHA256: fixture.sha256("owner\n"))
    ])
    let firstRequest = fixture.request(
      attemptID: "attempt-owner-first",
      ownerID: "owner-first",
      candidates: [candidate.reference],
      checks: ["owner"]
    )
    let firstIntegrator = CandidateCommitIntegrator(
      checkRegistry: registry,
      hooks: CandidateCommitIntegratorHooks(afterTargetLockAcquired: {
        gate.entered.signal()
        gate.release.wait()
      })
    )
    group.enter()
    let firstThread = Thread {
      defer { group.leave() }
      firstResult.set(Result { try firstIntegrator.integrate(firstRequest) })
    }
    firstThread.name = "fum-candidate-integrator-owner-test"
    firstThread.start()
    let firstEntered = gate.entered.wait(timeout: .now() + 30)
    if firstEntered != .success {
      gate.release.signal()
      group.wait()
    }
    try #require(firstEntered == .success)

    let second = try CandidateCommitIntegrator(checkRegistry: registry).integrate(
      fixture.request(
        attemptID: "attempt-owner-second",
        ownerID: "owner-second",
        integrationRootURL: fixture.root.appending(
          path: "other-integration-root", directoryHint: .isDirectory),
        candidates: [candidate.reference],
        checks: ["owner"]
      )
    )
    gate.release.signal()
    group.wait()

    #expect(second.outcome == .targetBusy)
    let first = try #require(firstResult.get()).get()
    #expect(first.outcome == .integrated)
  }

  @Test("небезопасная Git-граница, symref и пересечение runtime закрываются до публикации")
  func rejectsUnsafeGitAndRuntimeBoundaries() throws {
    let configFixture = try CandidateIntegrationFixture()
    defer { configFixture.remove() }
    let configCandidate = try configFixture.candidate(
      runID: "run-config",
      subnodeID: "writer-config",
      path: "output/config.txt",
      contents: "safe\n"
    )
    let configTarget = try configFixture.targetOID()
    try configFixture.setTargetConfig(key: "uploadpack.allowFilter", value: "true")
    #expect(throws: WritingSubnodeExecutorError.self) {
      try configFixture.integrator().integrate(
        configFixture.request(
          attemptID: "attempt-config", candidates: [configCandidate.reference])
      )
    }
    #expect(try configFixture.targetOID() == configTarget)

    let attributeFixture = try CandidateIntegrationFixture()
    defer { attributeFixture.remove() }
    let attributeCandidate = try attributeFixture.candidate(
      runID: "run-attributes",
      subnodeID: "writer-attributes",
      path: "output/attributes.txt",
      contents: "safe\n"
    )
    try attributeFixture.installTargetInfoAttributes()
    #expect(throws: WritingSubnodeExecutorError.self) {
      try attributeFixture.integrator().integrate(
        attributeFixture.request(
          attemptID: "attempt-attributes", candidates: [attributeCandidate.reference])
      )
    }
    #expect(try attributeFixture.targetOID() == attributeFixture.baseOID)

    let symbolicFixture = try CandidateIntegrationFixture()
    defer { symbolicFixture.remove() }
    let symbolicCandidate = try symbolicFixture.candidate(
      runID: "run-symbolic",
      subnodeID: "writer-symbolic",
      path: "output/symbolic.txt",
      contents: "safe\n"
    )
    try symbolicFixture.makeTargetRefSymbolic()
    #expect(throws: WritingSubnodeExecutorError.self) {
      try symbolicFixture.integrator().integrate(
        symbolicFixture.request(
          attemptID: "attempt-symbolic", candidates: [symbolicCandidate.reference])
      )
    }

    let overlapFixture = try CandidateIntegrationFixture()
    defer { overlapFixture.remove() }
    let overlapCandidate = try overlapFixture.candidate(
      runID: "run-overlap",
      subnodeID: "writer-overlap",
      path: "output/overlap.txt",
      contents: "safe\n"
    )
    let writersBefore = try overlapFixture.writerSnapshot()
    #expect(throws: WritingSubnodeExecutorError.self) {
      try overlapFixture.integrator().integrate(
        overlapFixture.request(
          attemptID: "attempt-overlap",
          integrationRootURL: overlapFixture.executionRoot,
          candidates: [overlapCandidate.reference]
        )
      )
    }
    #expect(try overlapFixture.writerSnapshot() == writersBefore)
  }

  @Test("нормализованные коллизии путей не зависят от регистра файловой системы")
  func rejectsNormalizedPathCollisions() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let upper = try fixture.candidate(
      runID: "run-upper",
      subnodeID: "writer-upper",
      path: "output/Case.txt",
      contents: "upper\n"
    )
    let lower = try fixture.candidate(
      runID: "run-lower",
      subnodeID: "writer-lower",
      path: "output/case.txt",
      contents: "lower\n"
    )
    let targetBefore = try fixture.targetSnapshot()

    let result = try fixture.integrator().integrate(
      fixture.request(
        attemptID: "attempt-case-collision",
        candidates: [upper.reference, lower.reference]
      )
    )

    #expect(result.outcome == .candidateInvalid)
    #expect(try fixture.targetSnapshot() == targetBefore)
  }

  @Test("нормализованная коллизия выходов resolver не публикуется")
  func rejectsNormalizedResolverOutputCollision() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-resolver-case",
      subnodeID: "writer-resolver-case",
      path: "output/touch.txt",
      contents: "candidate\n"
    )
    let registry = CandidateConflictResolverRegistry(specifications: [
      "derived-lower": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "derived/index.json",
        sourcePaths: ["base.txt"],
        schemaIdentity: "fum.fixture.derived-lower",
        schemaVersion: 1,
        requiredCheckIDs: ["base"]
      ),
      "derived-upper": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "derived/Index.json",
        sourcePaths: ["base.txt"],
        schemaIdentity: "fum.fixture.derived-upper",
        schemaVersion: 1,
        requiredCheckIDs: ["base"]
      ),
    ])

    let result = try fixture.integrator(resolverRegistry: registry).integrate(
      fixture.request(
        attemptID: "attempt-resolver-case-collision",
        candidates: [candidate.reference],
        resolverRuleIDs: ["derived-lower", "derived-upper"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(Set(result.diagnostic?.issues.map(\.reason) ?? []) == [.ambiguousRule])
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("каноническая подмена диагностики отклоняется повторным вычислением")
  func rejectsCanonicalDiagnosticTampering() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let left = try fixture.candidate(
      runID: "run-diagnostic-left",
      subnodeID: "writer-diagnostic-left",
      path: "shared.txt",
      contents: "left\n"
    )
    let right = try fixture.candidate(
      runID: "run-diagnostic-right",
      subnodeID: "writer-diagnostic-right",
      path: "shared.txt",
      contents: "right\n"
    )
    let request = fixture.request(
      attemptID: "attempt-diagnostic-tamper",
      candidates: [left.reference, right.reference]
    )
    let integrator = fixture.integrator()
    let first = try integrator.integrate(request)
    let diagnostic = try #require(first.diagnostic)
    let tampered = CandidateResolutionDiagnostic(
      attemptID: diagnostic.attemptID,
      targetRef: diagnostic.targetRef,
      expectedTargetOID: diagnostic.expectedTargetOID,
      inputs: diagnostic.inputs,
      affectedPaths: diagnostic.affectedPaths,
      issues: [
        CandidateResolutionDiagnosticIssue(
          reason: .preconditionFailed,
          path: "shared.txt"
        )
      ],
      checks: diagnostic.checks
    )
    try fixture.writeResolutionDiagnostic(
      tampered.canonicalJSONData(),
      attemptID: request.attemptID
    )

    #expect(throws: WritingSubnodeExecutorError.self) {
      try integrator.integrate(request)
    }
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("подмена resolver-происхождения prepared-паспорта отклоняется")
  func rejectsPreparedResolutionTampering() throws {
    let baseDocument = try stableDocument([])
    let expectedDocument = try stableDocument([
      stableRecord(id: "new", normative: ["policy": "stable", "slug": "new"])
    ])
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "registry/records.json": String(decoding: baseDocument, as: UTF8.self)
    ])
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-prepared-resolution",
      subnodeID: "writer-prepared-resolution",
      path: "registry/records.json",
      contents: String(decoding: expectedDocument, as: UTF8.self)
    )
    let request = fixture.request(
      attemptID: "attempt-prepared-resolution-tamper",
      candidates: [candidate.reference],
      checks: ["stable-records"],
      resolverRuleIDs: ["stable-records"]
    )
    let interrupted = CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "stable-records": .regularFileSHA256(
          path: "registry/records.json",
          expectedSHA256: "sha256:" + sha256Data(expectedDocument)
        )
      ]),
      resolverRegistry: CandidateConflictResolverRegistry(specifications: [
        "stable-records": .mergeStableRecords(
          ruleVersion: 1,
          path: "registry/records.json",
          schemaIdentity: "fum.fixture.stable-records",
          schemaVersion: 1,
          normativeFields: ["policy", "slug"],
          uniqueNormativeFields: ["slug"],
          requiredCheckIDs: ["stable-records"]
        )
      ]),
      hooks: CandidateCommitIntegratorHooks(beforeCompareAndSwap: {
        throw FixtureFailure.crash
      })
    )
    #expect(throws: FixtureFailure.self) {
      try interrupted.integrate(request)
    }
    try fixture.tamperPreparedResolution(attemptID: request.attemptID)

    #expect(throws: WritingSubnodeExecutorError.self) {
      try stableRecordIntegrator(
        fixture: fixture,
        expectedDocument: expectedDocument
      ).integrate(request)
    }
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("подмена prepared-commit с тем же tree и родителями отклоняется")
  func rejectsPreparedCommitPayloadTampering() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-prepared-payload",
      subnodeID: "writer-prepared-payload",
      path: "output/prepared-payload.txt",
      contents: "prepared\n"
    )
    let request = fixture.request(
      attemptID: "attempt-prepared-payload-tamper",
      candidates: [candidate.reference],
      checks: ["prepared-payload"]
    )
    let registry = CandidateIntegrationCheckRegistry(specifications: [
      "prepared-payload": .regularFileSHA256(
        path: "output/prepared-payload.txt",
        expectedSHA256: fixture.sha256("prepared\n")
      )
    ])
    let interrupted = CandidateCommitIntegrator(
      checkRegistry: registry,
      hooks: CandidateCommitIntegratorHooks(beforeCompareAndSwap: {
        throw FixtureFailure.crash
      })
    )
    #expect(throws: FixtureFailure.self) {
      try interrupted.integrate(request)
    }
    try fixture.tamperPreparedCommitPayload(attemptID: request.attemptID)

    #expect(throws: WritingSubnodeExecutorError.self) {
      try CandidateCommitIntegrator(checkRegistry: registry).integrate(request)
    }
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("symlink вместо канонического источника нарушает предусловие")
  func rejectsSymlinkAsDerivedSource() throws {
    let fixture = try CandidateIntegrationFixture(initialFiles: [
      "derived/index.json": "base\n",
      "sources/a.txt": "a0\n",
    ])
    defer { fixture.remove() }
    try fixture.replaceBaseFileWithSymlink(
      path: "sources/a.txt",
      destination: "../base.txt"
    )
    let candidate = try fixture.candidate(
      runID: "run-derived-symlink",
      subnodeID: "writer-derived-symlink",
      path: "derived/index.json",
      contents: "candidate\n"
    )
    let registry = CandidateConflictResolverRegistry(specifications: [
      "derived-index": .rebuildDerivedManifest(
        ruleVersion: 1,
        outputPath: "derived/index.json",
        sourcePaths: ["sources/a.txt"],
        schemaIdentity: "fum.fixture.derived-manifest",
        schemaVersion: 1,
        requiredCheckIDs: ["base"]
      )
    ])

    let result = try fixture.integrator(resolverRegistry: registry).integrate(
      fixture.request(
        attemptID: "attempt-derived-symlink",
        candidates: [candidate.reference],
        resolverRuleIDs: ["derived-index"]
      )
    )

    #expect(result.outcome == .resolutionRequired)
    #expect(result.diagnostic?.issues.map(\.reason) == [.preconditionFailed])
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("подмена безопасного blob в prepared-tree отклоняется полным повтором")
  func rejectsPreparedTreeTamperingByFullReplay() throws {
    let fixture = try CandidateIntegrationFixture()
    defer { fixture.remove() }
    let candidate = try fixture.candidate(
      runID: "run-prepared-tree",
      subnodeID: "writer-prepared-tree",
      path: "output/prepared-tree.txt",
      contents: "candidate\n"
    )
    let request = fixture.request(
      attemptID: "attempt-prepared-tree-tamper",
      candidates: [candidate.reference]
    )
    let interrupted = fixture.integrator(
      hooks: CandidateCommitIntegratorHooks(beforeCompareAndSwap: {
        throw FixtureFailure.crash
      })
    )
    #expect(throws: FixtureFailure.self) {
      try interrupted.integrate(request)
    }
    try fixture.tamperPreparedTree(
      attemptID: request.attemptID,
      path: "output/prepared-tree.txt",
      contents: "different but publishable\n",
      commitMessage: request.commitMessage
    )

    #expect(throws: WritingSubnodeExecutorError.self) {
      try fixture.integrator().integrate(request)
    }
    #expect(try fixture.targetOID() == fixture.baseOID)
  }

  @Test("нормализация видит коллизии target-путей и компонентов каталога")
  func recognizesTargetAndDirectoryComponentCollisions() {
    #expect(
      Set(
        CandidateIntegrationValidation.normalizedPathCollisions([
          "output/Case.txt", "output/case.txt",
        ])
      ) == ["output/Case.txt", "output/case.txt"]
    )
    #expect(
      Set(
        CandidateIntegrationValidation.normalizedPathCollisions([
          "Dir/a.txt", "dir/b.txt",
        ])
      ) == ["Dir/a.txt", "dir/b.txt"]
    )
  }
}

private enum FixtureFailure: Error {
  case crash
}

private func stableRecord(
  id: String,
  normative: [String: String],
  informative: [String: String] = [:]
) -> CandidateStableRecord {
  CandidateStableRecord(
    id: id,
    normative: normative,
    informative: informative
  )
}

private func stableDocument(_ records: [CandidateStableRecord]) throws -> Data {
  try CandidateStableRecordDocument(
    schemaIdentity: "fum.fixture.stable-records",
    schemaVersion: 1,
    records: records
  ).canonicalJSONData()
}

private func replacingIntegrationPassport(
  _ passport: CandidateCommitIntegrationPassport,
  integrationTreeOID: String? = nil,
  integrationOID: String? = nil,
  resolutions: [CandidateConflictResolutionRecord]? = nil
) -> CandidateCommitIntegrationPassport {
  CandidateCommitIntegrationPassport(
    schemaIdentity: passport.schemaIdentity,
    schemaVersion: passport.schemaVersion,
    attemptID: passport.attemptID,
    ownerID: passport.ownerID,
    repositoryID: passport.repositoryID,
    targetRef: passport.targetRef,
    expectedTargetOID: passport.expectedTargetOID,
    integrationTreeOID: integrationTreeOID ?? passport.integrationTreeOID,
    integrationOID: integrationOID ?? passport.integrationOID,
    integrationRef: passport.integrationRef,
    requestSHA256: passport.requestSHA256,
    candidates: passport.candidates,
    resolverRegistryIdentity: passport.resolverRegistryIdentity,
    resolverRegistryVersion: passport.resolverRegistryVersion,
    resolverRules: passport.resolverRules,
    resolutions: resolutions ?? passport.resolutions,
    checks: passport.checks,
    repeatedChecks: passport.repeatedChecks
  )
}

private func stableRecordIntegrator(
  fixture: CandidateIntegrationFixture,
  expectedDocument: Data
) -> CandidateCommitIntegrator {
  CandidateCommitIntegrator(
    checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
      "stable-records": .regularFileSHA256(
        path: "registry/records.json",
        expectedSHA256: "sha256:" + sha256Data(expectedDocument)
      )
    ]),
    resolverRegistry: CandidateConflictResolverRegistry(specifications: [
      "stable-records": .mergeStableRecords(
        ruleVersion: 1,
        path: "registry/records.json",
        schemaIdentity: "fum.fixture.stable-records",
        schemaVersion: 1,
        normativeFields: ["policy", "slug"],
        uniqueNormativeFields: ["slug"],
        requiredCheckIDs: ["stable-records"]
      )
    ])
  )
}

private func sha256Text(_ value: String) -> String {
  "sha256:" + sha256Data(Data(value.utf8))
}

private func sha256Data(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private final class IntegrationGate: @unchecked Sendable {
  let entered = DispatchSemaphore(value: 0)
  let release = DispatchSemaphore(value: 0)
}

private final class LockedValue<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value?

  func set(_ newValue: Value) {
    lock.lock()
    value = newValue
    lock.unlock()
  }

  func get() -> Value? {
    lock.lock()
    defer { lock.unlock() }
    return value
  }
}

private struct CandidateFixtureResult: Sendable {
  let reference: CandidateCommitReference
  let commitOID: String
  let cloneURL: URL
}

private final class CandidateIntegrationFixture: @unchecked Sendable {
  let root: URL
  let source: URL
  let target: URL
  let executionRoot: URL
  let integrationRoot: URL
  let sentinel: URL
  private(set) var baseOID = ""

  init(initialFiles: [String: String] = [:]) throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "fum-candidate-integration-tests-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    source = root.appending(path: "source", directoryHint: .isDirectory)
    target = root.appending(path: "target.git", directoryHint: .isDirectory)
    executionRoot = root.appending(path: "writers", directoryHint: .isDirectory)
    integrationRoot = root.appending(path: "integrations", directoryHint: .isDirectory)
    sentinel = root.appending(path: "fifo-sentinel", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: executionRoot, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: integrationRoot, withIntermediateDirectories: true)
    _ = try git(["init", "--quiet", "--initial-branch=main"], at: source)
    try Data("pinned input\n".utf8).write(to: source.appending(path: "base.txt"))
    try Data("base\n".utf8).write(to: source.appending(path: "shared.txt"))
    for (path, contents) in initialFiles.sorted(by: { $0.key < $1.key }) {
      let url = source.appending(path: path)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try Data(contents.utf8).write(to: url)
    }
    _ = try git(["add", "--", "."], at: source)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit",
        "--quiet", "-m", "base",
      ],
      at: source
    )
    baseOID = try git(["rev-parse", "HEAD"], at: source)
    _ = try git(["clone", "--quiet", "--bare", "--no-local", source.path, target.path], at: root)
    try FileManager.default.createDirectory(at: sentinel, withIntermediateDirectories: true)
    _ = try git(["init", "--quiet", "--initial-branch=main"], at: sentinel)
    try Data("sentinel\n".utf8).write(to: sentinel.appending(path: "sentinel.txt"))
    _ = try git(["add", "--", "sentinel.txt"], at: sentinel)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit",
        "--quiet", "-m", "sentinel",
      ],
      at: sentinel
    )
    let sentinelOID = try git(["rev-parse", "HEAD"], at: sentinel)
    _ = try git(
      ["update-ref", "refs/fum/worktree-task-queues/sentinel", sentinelOID],
      at: sentinel
    )
  }

  func candidate(
    runID: String,
    subnodeID: String,
    path: String,
    contents: String
  ) throws -> CandidateFixtureResult {
    try candidate(
      runID: runID,
      subnodeID: subnodeID,
      writes: [path: contents]
    )
  }

  func candidate(
    runID: String,
    subnodeID: String,
    writes: [String: String]
  ) throws -> CandidateFixtureResult {
    let result = try rawWritingResult(
      runID: runID,
      subnodeID: subnodeID,
      writes: writes
    )
    let passport = try #require(result.passport)
    let passportSHA256 = try #require(result.passportSHA256)
    let cloneURL = try #require(result.cloneURL)
    return CandidateFixtureResult(
      reference: CandidateCommitReference(
        runID: runID,
        executionRootURL: executionRoot,
        expectedCommitOID: passport.commitOID,
        expectedPassportSHA256: passportSHA256
      ),
      commitOID: passport.commitOID,
      cloneURL: cloneURL
    )
  }

  func rawWritingResult(
    runID: String,
    subnodeID: String,
    path: String,
    contents: String
  ) throws -> WritingSubnodeExecutionResult {
    try rawWritingResult(
      runID: runID,
      subnodeID: subnodeID,
      writes: [path: contents]
    )
  }

  func rawWritingResult(
    runID: String,
    subnodeID: String,
    writes: [String: String]
  ) throws -> WritingSubnodeExecutionResult {
    let dataByPath = writes.mapValues { Data($0.utf8) }
    let package = try workPackage(paths: Array(writes.keys))
    let specifications = Dictionary(
      uniqueKeysWithValues: dataByPath.map { path, content in
        (
          "content-check-" + sha256Data(Data(path.utf8)),
          WritingSubnodeCheckSpecification.regularFileSHA256(
            path: path,
            expectedSHA256: "sha256:" + sha256Data(content)
          )
        )
      }
    )
    let executor = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: specifications)
    )
    guard case .ready(let verified) = executor.verifyWorkPackage(package, workspaceRoot: source)
    else {
      throw FixtureFailure.crash
    }
    return try executor.execute(
      verified,
      request: WritingSubnodeExecutionRequest(
        episodeID: "episode-001",
        stepGenerationID: "generation-001",
        cardID: "FUM-STEP-0086",
        stepID: "step-0086",
        runID: runID,
        subnodeID: subnodeID,
        repositoryID: "repo-fixture",
        sourceCheckoutURL: source,
        executionRootURL: executionRoot,
        targetRef: "refs/heads/main",
        baseOID: baseOID,
        commitMessage: "Create integration candidate",
        writes: dataByPath.sorted(by: { $0.key < $1.key }).map {
          WritingSubnodeWrite(path: $0.key, contents: $0.value)
        }
      )
    )
  }

  func request(
    attemptID: String,
    ownerID: String = "integrator-001",
    expectedTargetOID: String? = nil,
    integrationRootURL: URL? = nil,
    commitMessage: String = "Integrate verified candidates",
    candidates: [CandidateCommitReference],
    checks: [String] = ["base"],
    resolverRuleIDs: [String] = []
  ) -> CandidateCommitIntegrationRequest {
    CandidateCommitIntegrationRequest(
      attemptID: attemptID,
      ownerID: ownerID,
      repositoryID: "repo-fixture",
      targetRepositoryURL: target,
      integrationRootURL: integrationRootURL ?? integrationRoot,
      targetRef: "refs/heads/main",
      expectedTargetOID: expectedTargetOID ?? baseOID,
      commitMessage: commitMessage,
      candidates: candidates,
      checkIDs: checks,
      resolverRuleIDs: resolverRuleIDs
    )
  }

  func advanceTarget(path: String, contents: String) throws -> String {
    let clone = root.appending(
      path: "mover-\(UUID().uuidString)", directoryHint: .isDirectory)
    _ = try git(["clone", "--quiet", "--no-local", target.path, clone.path], at: root)
    let url = clone.appending(path: path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(contents.utf8).write(to: url)
    _ = try git(["add", "--", path], at: clone)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit",
        "--quiet", "-m", "concurrent target",
      ],
      at: clone
    )
    let oid = try git(["rev-parse", "HEAD"], at: clone)
    _ = try git(["push", "--quiet", "origin", "HEAD:refs/heads/main"], at: clone)
    return oid
  }

  func targetOID() throws -> String {
    try git(["rev-parse", "refs/heads/main"], at: target)
  }

  func blob(at revision: String, path: String) throws -> String {
    try git(["cat-file", "blob", "\(revision):\(path)"], at: target)
  }

  func blobData(at revision: String, path: String) throws -> Data {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    process.arguments = [
      "--no-replace-objects", "--no-optional-locks", "cat-file", "blob",
      "\(revision):\(path)",
    ]
    process.currentDirectoryURL = target
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run()
    try output.fileHandleForWriting.close()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw FixtureFailure.crash }
    return data
  }

  func integrator(
    hooks: CandidateCommitIntegratorHooks = CandidateCommitIntegratorHooks(),
    resolverRegistry: CandidateConflictResolverRegistry = CandidateConflictResolverRegistry()
  ) -> CandidateCommitIntegrator {
    CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "base": .regularFileSHA256(
          path: "base.txt", expectedSHA256: sha256("pinned input\n"))
      ]),
      resolverRegistry: resolverRegistry,
      hooks: hooks
    )
  }

  func parents(of oid: String) throws -> [String] {
    let fields = try git(["rev-list", "--parents", "-n", "1", oid], at: target)
      .split(separator: " ").map(String.init)
    return Array(fields.dropFirst())
  }

  func isAncestor(_ ancestor: String, of descendant: String) throws -> Bool {
    try gitStatus(["merge-base", "--is-ancestor", ancestor, descendant], at: target).status == 0
  }

  func textualMergeSucceeds(_ candidates: [CandidateFixtureResult]) throws -> Bool {
    let clone = root.appending(
      path: "textual-merge-\(UUID().uuidString)", directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: clone) }
    _ = try git(["clone", "--quiet", "--no-local", target.path, clone.path], at: root)
    for candidate in candidates {
      _ = try git(
        [
          "fetch", "--quiet", "--no-tags", "--no-write-fetch-head",
          candidate.cloneURL.path, candidate.commitOID,
        ],
        at: clone
      )
    }
    _ = try git(["checkout", "--quiet", "--detach", baseOID], at: clone)
    return try gitStatus(
      ["merge", "--no-commit", "--no-ff", "--no-edit"]
        + candidates.map(\.commitOID).sorted(),
      at: clone
    ).status == 0
  }

  func candidateIsReachable(_ candidate: CandidateFixtureResult) throws -> Bool {
    try git(
      ["rev-parse", "--verify", candidate.reference.expectedCommitOID], at: candidate.cloneURL)
      == candidate.commitOID
  }

  func resolutionDiagnosticData(attemptID: String) throws -> Data {
    try Data(
      contentsOf: integrationRoot.appending(
        path: "attempts/\(attemptID)/resolution-required.json"
      )
    )
  }

  func writeResolutionDiagnostic(_ data: Data, attemptID: String) throws {
    try data.write(
      to: integrationRoot.appending(
        path: "attempts/\(attemptID)/resolution-required.json"
      )
    )
  }

  func tamperPreparedResolution(attemptID: String) throws {
    let preparedURL = integrationRoot.appending(
      path: "attempts/\(attemptID)/prepared.json"
    )
    let passport = try JSONDecoder().decode(
      CandidateCommitIntegrationPassport.self,
      from: Data(contentsOf: preparedURL)
    )
    let resolution = try #require(passport.resolutions.first)
    let tamperedResolution = CandidateConflictResolutionRecord(
      ruleID: resolution.ruleID,
      ruleVersion: resolution.ruleVersion,
      path: resolution.path,
      algorithm: resolution.algorithm,
      specificationSHA256: resolution.specificationSHA256,
      inputSHA256s: resolution.inputSHA256s,
      outputSHA256: resolution.outputSHA256,
      invariants: ["tampered_invariant"],
      requiredCheckIDs: resolution.requiredCheckIDs
    )
    let tampered = replacingIntegrationPassport(
      passport,
      resolutions: [tamperedResolution] + passport.resolutions.dropFirst()
    )
    try tampered.canonicalJSONData().write(to: preparedURL)
  }

  func tamperPreparedCommitPayload(attemptID: String) throws {
    let attemptURL = integrationRoot.appending(
      path: "attempts/\(attemptID)",
      directoryHint: .isDirectory
    )
    let preparedURL = attemptURL.appending(path: "prepared.json")
    let cloneURL = attemptURL.appending(path: "clone", directoryHint: .isDirectory)
    let passport = try JSONDecoder().decode(
      CandidateCommitIntegrationPassport.self,
      from: Data(contentsOf: preparedURL)
    )
    var arguments = [
      "-c", "user.name=FUM Tamper Fixture",
      "-c", "user.email=tamper@invalid",
      "commit-tree", passport.integrationTreeOID,
    ]
    for parentOID in [passport.expectedTargetOID] + passport.candidateOIDs {
      arguments += ["-p", parentOID]
    }
    arguments += ["-m", "tampered prepared commit"]
    let tamperedOID = try git(arguments, at: cloneURL)
    _ = try git(
      ["update-ref", passport.integrationRef, tamperedOID, passport.integrationOID],
      at: cloneURL
    )
    let tampered = replacingIntegrationPassport(
      passport,
      integrationOID: tamperedOID
    )
    try tampered.canonicalJSONData().write(to: preparedURL)
  }

  func tamperPreparedTree(
    attemptID: String,
    path: String,
    contents: String,
    commitMessage: String
  ) throws {
    let attemptURL = integrationRoot.appending(
      path: "attempts/\(attemptID)",
      directoryHint: .isDirectory
    )
    let preparedURL = attemptURL.appending(path: "prepared.json")
    let cloneURL = attemptURL.appending(path: "clone", directoryHint: .isDirectory)
    let passport = try JSONDecoder().decode(
      CandidateCommitIntegrationPassport.self,
      from: Data(contentsOf: preparedURL)
    )
    _ = try git(["read-tree", passport.integrationTreeOID], at: cloneURL)
    try Data(contents.utf8).write(to: cloneURL.appending(path: path))
    _ = try git(["add", "--", path], at: cloneURL)
    let tamperedTreeOID = try git(["write-tree"], at: cloneURL)
    var arguments = ["commit-tree", tamperedTreeOID]
    for parentOID in [passport.expectedTargetOID] + passport.candidateOIDs {
      arguments += ["-p", parentOID]
    }
    let tamperedOID = try git(
      arguments,
      at: cloneURL,
      input: Data((commitMessage + "\n").utf8),
      additionalEnvironment: CandidateIntegrationGit.commitEnvironment
    )
    _ = try git(
      ["update-ref", passport.integrationRef, tamperedOID, passport.integrationOID],
      at: cloneURL
    )
    let tampered = replacingIntegrationPassport(
      passport,
      integrationTreeOID: tamperedTreeOID,
      integrationOID: tamperedOID
    )
    try tampered.canonicalJSONData().write(to: preparedURL)
  }

  func retainedIntegrationInputOIDs(attemptID: String) throws -> [String] {
    let clone = integrationRoot.appending(
      path: "attempts/\(attemptID)/clone",
      directoryHint: .isDirectory
    )
    return try git(
      [
        "for-each-ref", "--format=%(objectname)",
        "refs/fum/integration-inputs/",
      ],
      at: clone
    ).split(separator: "\n").map(String.init).sorted()
  }

  func corruptPassport(runID: String) throws {
    let passport = executionRoot.appending(path: "passports/\(runID).json")
    var data = try Data(contentsOf: passport)
    data.append(10)
    try data.write(to: passport)
  }

  func pruneIntegrationObjects(attemptID: String) throws {
    let clone = integrationRoot.appending(
      path: "attempts/\(attemptID)/clone",
      directoryHint: .isDirectory
    )
    _ = try git(["reflog", "expire", "--expire=now", "--all"], at: clone)
    _ = try git(["gc", "--prune=now"], at: clone)
    _ = try git(["reflog", "expire", "--expire=now", "--all"], at: target)
    _ = try git(["gc", "--prune=now"], at: target)
  }

  func setTargetConfig(key: String, value: String) throws {
    _ = try git(["config", "--local", key, value], at: target)
  }

  func installTargetInfoAttributes() throws {
    let info = target.appending(path: "info", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: info, withIntermediateDirectories: true)
    try Data("* merge=union\n".utf8).write(to: info.appending(path: "attributes"))
  }

  func makeTargetRefSymbolic() throws {
    _ = try git(["update-ref", "refs/heads/real", baseOID], at: target)
    _ = try git(["symbolic-ref", "refs/heads/main", "refs/heads/real"], at: target)
  }

  func replaceBaseFileWithSymlink(path: String, destination: String) throws {
    let url = source.appending(path: path)
    try FileManager.default.removeItem(at: url)
    try FileManager.default.createSymbolicLink(
      atPath: url.path,
      withDestinationPath: destination
    )
    _ = try git(["add", "--", path], at: source)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit",
        "--quiet", "-m", "replace source with symlink",
      ],
      at: source
    )
    baseOID = try git(["rev-parse", "HEAD"], at: source)
    _ = try git(
      ["push", "--quiet", "--force", target.path, "HEAD:refs/heads/main"],
      at: source
    )
  }

  func candidateSnapshot(_ candidate: CandidateFixtureResult) throws -> Data {
    let values = [
      try git(["rev-parse", candidate.reference.expectedCommitOID], at: candidate.cloneURL),
      try git(["for-each-ref", "--format=%(refname)%00%(objectname)"], at: candidate.cloneURL),
      try git(["status", "--porcelain=v1", "--untracked-files=all"], at: candidate.cloneURL),
      try Data(
        contentsOf: executionRoot.appending(
          path: "passports/\(candidate.reference.runID).json")
      )
      .base64EncodedString(),
    ]
    return Data(values.joined(separator: "\n").utf8)
  }

  func targetSnapshot() throws -> Data {
    let values = [
      try targetOID(),
      try git(["for-each-ref", "--format=%(refname)%00%(objectname)%00%(objecttype)"], at: target),
    ]
    return Data(values.joined(separator: "\n").utf8)
  }

  func writerSnapshot() throws -> Data {
    try byteInventory(at: executionRoot)
  }

  func sentinelSnapshot() throws -> Data {
    let indexURL = sentinel.appending(path: ".git/index")
    let values = [
      try git(["rev-parse", "HEAD"], at: sentinel),
      try git(["symbolic-ref", "HEAD"], at: sentinel),
      try git(["status", "--porcelain=v1", "--untracked-files=all"], at: sentinel),
      try git(["for-each-ref", "--format=%(refname)%00%(objectname)"], at: sentinel),
      try git(["count-objects", "-v"], at: sentinel),
      try Data(contentsOf: indexURL).base64EncodedString(),
    ]
    return Data(values.joined(separator: "\n").utf8)
  }

  func sha256(_ value: String) -> String {
    "sha256:" + sha256Data(Data(value.utf8))
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }

  private func workPackage(paths: [String]) throws -> Data {
    let input = try Data(contentsOf: source.appending(path: "base.txt"))
    let package: [String: Any] = [
      "schema_version": 1,
      "package_id": "fum.integration.fixture.v1",
      "goal": "Создать проверяемый кандидатный commit.",
      "deliverables": [
        [
          "id": "candidate", "role": "primary", "description": "Кандидатный commit.",
          "depends_on": [],
        ]
      ],
      "inputs": [
        [
          "id": "pinned-input", "path": "base.txt",
          "sha256": "sha256:" + sha256Data(input), "required": true,
        ]
      ],
      "change_scope": [
        "policy": "listed_paths_only", "allowed_paths": paths.sorted(),
        "excluded_paths": [".git", "runtime"],
      ],
      "dependencies": [
        ["id": "git", "status": "resolved", "evidence": "Локальный Git доступен."]
      ],
      "checks": paths.sorted().map {
        [
          "id": "content-check-" + sha256Data(Data($0.utf8)),
          "description": "Содержимое детерминировано.",
        ]
      },
      "handoff": ["format": "candidate_commit_v1", "required_artifacts": paths.sorted()],
      "budget": [
        "unit": "planning_units", "limit": 20, "reading": 3, "work": 5,
        "verification": 3, "response": 2, "reserve": 7,
      ],
      "preflight": ["before_model_call": true, "before_user_data_mutation": true],
    ]
    return try JSONSerialization.data(withJSONObject: package, options: [.sortedKeys])
  }

  private func sha256Data(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private func byteInventory(at directory: URL) throws -> Data {
    guard
      let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: []
      )
    else {
      return Data()
    }
    var values: [String] = []
    for case let url as URL in enumerator {
      let attributes = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      let relative = String(url.path.dropFirst(directory.path.count + 1))
      if attributes.isSymbolicLink == true {
        values.append(
          "link:\(relative):\(try FileManager.default.destinationOfSymbolicLink(atPath: url.path))"
        )
      } else if attributes.isRegularFile == true {
        values.append(
          "file:\(relative):\(try Data(contentsOf: url).base64EncodedString())"
        )
      }
    }

    return Data(values.sorted().joined(separator: "\n").utf8)
  }

  @discardableResult
  private func git(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> String {
    let result = try gitStatus(
      arguments,
      at: directory,
      input: input,
      additionalEnvironment: additionalEnvironment
    )
    guard result.status == 0 else {
      throw NSError(
        domain: "CandidateIntegrationFixture.git",
        code: Int(result.status),
        userInfo: [NSLocalizedDescriptionKey: result.output]
      )
    }
    return result.output
  }

  private func gitStatus(
    _ arguments: [String],
    at directory: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:]
  ) throws -> (
    status: Int32, output: String
  ) {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    process.arguments =
      [
        "--no-replace-objects", "--no-optional-locks",
        "-c", "core.fsmonitor=false",
        "-c", "core.hooksPath=\(WritingSubnodeSystemRuntime.nullDevicePath)",
        "-c", "core.untrackedCache=false",
      ] + arguments
    process.currentDirectoryURL = directory
    var environment = ProcessInfo.processInfo.environment.filter {
      !$0.key.uppercased().hasPrefix("GIT_")
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] = WritingSubnodeSystemRuntime.nullDevicePath
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["LC_ALL"] = "C"
    for (key, value) in additionalEnvironment {
      environment[key] = value
    }
    process.environment = environment
    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    let inputPipe = input.map { _ in Pipe() }
    process.standardInput = inputPipe
    try process.run()
    if let input, let inputPipe {
      try inputPipe.fileHandleForWriting.write(contentsOf: input)
      try inputPipe.fileHandleForWriting.close()
    }
    try output.fileHandleForWriting.close()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (
      process.terminationStatus,
      String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    )
  }
}
