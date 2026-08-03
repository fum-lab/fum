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

    #expect(conflict.outcome == .mergeConflict)
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
    #expect(semantic.outcome == .checkFailed)
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
}

private enum FixtureFailure: Error {
  case crash
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

  init() throws {
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
    _ = try git(["add", "--", "base.txt", "shared.txt"], at: source)
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
    let result = try rawWritingResult(
      runID: runID, subnodeID: subnodeID, path: path, contents: contents)
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
    let content = Data(contents.utf8)
    let package = try workPackage(path: path)
    let executor = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "content-check": .regularFileSHA256(
          path: path, expectedSHA256: "sha256:" + sha256Data(content))
      ])
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
        writes: [WritingSubnodeWrite(path: path, contents: content)]
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
    checks: [String] = ["base"]
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
      checkIDs: checks
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

  func integrator(
    hooks: CandidateCommitIntegratorHooks = CandidateCommitIntegratorHooks()
  ) -> CandidateCommitIntegrator {
    CandidateCommitIntegrator(
      checkRegistry: CandidateIntegrationCheckRegistry(specifications: [
        "base": .regularFileSHA256(
          path: "base.txt", expectedSHA256: sha256("pinned input\n"))
      ]),
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

  func candidateIsReachable(_ candidate: CandidateFixtureResult) throws -> Bool {
    try git(
      ["rev-parse", "--verify", candidate.reference.expectedCommitOID], at: candidate.cloneURL)
      == candidate.commitOID
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

  private func workPackage(path: String) throws -> Data {
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
        "policy": "listed_paths_only", "allowed_paths": [path],
        "excluded_paths": [".git", "runtime"],
      ],
      "dependencies": [
        ["id": "git", "status": "resolved", "evidence": "Локальный Git доступен."]
      ],
      "checks": [
        ["id": "content-check", "description": "Содержимое детерминировано."]
      ],
      "handoff": ["format": "candidate_commit_v1", "required_artifacts": [path]],
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
  private func git(_ arguments: [String], at directory: URL) throws -> String {
    let result = try gitStatus(arguments, at: directory)
    guard result.status == 0 else {
      throw NSError(
        domain: "CandidateIntegrationFixture.git",
        code: Int(result.status),
        userInfo: [NSLocalizedDescriptionKey: result.output]
      )
    }
    return result.output
  }

  private func gitStatus(_ arguments: [String], at directory: URL) throws -> (
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
    process.environment = environment
    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    try process.run()
    try output.fileHandleForWriting.close()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (
      process.terminationStatus,
      String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    )
  }
}
