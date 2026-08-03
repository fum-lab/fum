import CryptoKit
import Darwin
import Foundation
import Testing

@testable import FUMVerifiableMultiAgentContour

@Suite("Изолированный пишущий подузел")
struct WritingSubnodeExecutorTests {
  @Test("осмысленный diff создаёт один кандидатный commit вне исходного checkout")
  func createsCandidateWithoutChangingSource() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let sourceBefore = try fixture.sourceSnapshot()
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "content-check": .regularFileSHA256(
          path: "output/result.txt",
          expectedSHA256: "sha256:" + fixture.sha256(Data("candidate\n".utf8))
        )
      ])
    )

    let verification = executor.verifyWorkPackage(package, workspaceRoot: fixture.source)
    guard case .ready(let verifiedPackage) = verification else {
      Issue.record("Рабочий пакет должен пройти предпусковую проверку")
      return
    }
    let result = try executor.execute(
      verifiedPackage,
      request: try fixture.request(
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )

    #expect(result.outcome == .candidateCommitted)
    let passport = try #require(result.passport)
    let cloneURL = try #require(result.cloneURL)
    #expect(passport.episodeID == "episode-001")
    #expect(passport.stepGenerationID == "generation-001")
    #expect(passport.cardID == "FUM-STEP-0085")
    #expect(passport.stepID == "step-0085")
    #expect(passport.runID == "run-001")
    #expect(passport.subnodeID == "writer-001")
    #expect(passport.repositoryID == "repo-fixture")
    #expect(passport.parentOID == fixture.baseOID)
    #expect(passport.actualPaths == ["output/result.txt"])
    #expect(passport.branchRef == "refs/heads/fum-step/step-0085/writer-001-run-001")
    #expect(passport.resultRef == "refs/fum/results/repo-fixture/step-0085/writer-001-run-001")
    #expect(passport.transfer.targetRef == "refs/heads/main")
    #expect(passport.transfer.targetRepositoryID == "repo-fixture")
    #expect(passport.transfer.state == .prepared)
    #expect(!passport.transfer.accepted)
    #expect(!passport.transfer.published)
    #expect(passport.inputs.count == 1)
    #expect(passport.inputs.first?.inputID == "pinned-input")
    #expect(passport.inputs.first?.path == "input.txt")
    #expect(
      passport.inputs.first?.sha256
        == "sha256:" + fixture.sha256(Data("pinned input\n".utf8)))
    #expect(passport.inputs.first?.required == true)
    #expect(passport.dependencies.count == 1)
    #expect(passport.dependencies.first?.dependencyID == "git")
    #expect(passport.dependencies.first?.status == "resolved")
    #expect(passport.dependencies.first?.evidence == "Локальный Git доступен.")
    #expect(passport.checks.map(\.checkID) == ["content-check"])
    #expect(passport.checks.allSatisfy { $0.status == .passed })
    #expect(
      passport.checks.first?.evidence
        == "sha256:" + fixture.sha256(Data("candidate\n".utf8)))
    #expect(passport.checks.first?.specificationSHA256.hasPrefix("sha256:") == true)
    #expect(passport.constraints.changePolicy == "listed_paths_only")
    #expect(passport.constraints.allowedPaths == ["output/result.txt"])
    #expect(passport.constraints.excludedPaths == [".git", "runtime"])
    #expect(passport.constraints.isolatedClone)
    #expect(!passport.constraints.sourceMutationAllowed)
    #expect(!passport.constraints.modelCallsAllowed)
    #expect(!passport.constraints.networkAllowed)
    #expect(!passport.constraints.integrationAllowed)
    #expect(passport.budget.unit == "planning_units")
    #expect(passport.budget.limit == 20)
    #expect(passport.budget.reading == 3)
    #expect(passport.budget.work == 5)
    #expect(passport.budget.verification == 3)
    #expect(passport.budget.response == 2)
    #expect(passport.budget.reserve == 7)
    #expect(passport.handoff.format == "candidate_commit_v1")
    #expect(passport.handoff.requiredArtifacts == ["output/result.txt"])
    #expect(result.passportCanonicalJSON?.contains(Data(fixture.root.path.utf8)) == false)
    #expect(
      result.passportSHA256
        == result.passportCanonicalJSON.map { "sha256:" + fixture.sha256($0) }
    )
    #expect(
      try fixture.git(["rev-parse", "--verify", passport.branchRef], at: cloneURL)
        == passport.commitOID)
    #expect(try fixture.git(["cat-file", "-t", passport.branchRef], at: cloneURL) == "commit")
    #expect(
      try fixture.git(["rev-parse", "--verify", passport.resultRef], at: cloneURL)
        == passport.commitOID)
    #expect(try fixture.git(["cat-file", "-t", passport.resultRef], at: cloneURL) == "commit")
    #expect(
      try fixture.git(["rev-parse", "\(passport.commitOID)^{tree}"], at: cloneURL)
        == passport.treeOID)
    #expect(
      try fixture.git(
        ["diff", "--name-only", "--no-renames", passport.parentOID, passport.commitOID, "--"],
        at: cloneURL
      ) == "output/result.txt"
    )
    #expect(
      !(try fixture.git(
        ["diff", "--binary", "--no-renames", passport.parentOID, passport.commitOID, "--"],
        at: cloneURL
      )).isEmpty
    )
    try fixture.expectIsolatedClone(cloneURL)
    #expect(
      try Data(contentsOf: cloneURL.appending(path: "output/result.txt"))
        == Data("candidate\n".utf8)
    )

    let storedPassport = try WritingSubnodePassportStore(rootURL: fixture.executionRoot)
      .load(runID: "run-001")
    #expect(storedPassport == passport)

    let recovered = try fixture.runPassportProbe(runID: "run-001")
    #expect(recovered.status == 0)
    #expect(recovered.processID != getpid())
    #expect(recovered.output == result.passportCanonicalJSON)

    let parents = try fixture.git(
      ["rev-list", "--parents", "-n", "1", passport.commitOID], at: cloneURL
    )
    .split(separator: " ").map(String.init)
    #expect(parents == [passport.commitOID, fixture.baseOID])

    let second = try executor.execute(
      verifiedPackage,
      request: try fixture.request(
        runID: "run-002",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )
    let secondPassport = try #require(second.passport)
    let secondCloneURL = try #require(second.cloneURL)
    #expect(second.outcome == .candidateCommitted)
    #expect(secondCloneURL != cloneURL)
    #expect(secondPassport.branchRef != passport.branchRef)
    #expect(secondPassport.resultRef != passport.resultRef)
    try fixture.expectIsolatedClone(secondCloneURL)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("no-op не создаёт искусственный commit или result_ref")
  func noOpDoesNotCreateCandidate() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    try fixture.commitFile(path: "output/result.txt", contents: Data("candidate\n".utf8))
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = fixture.passingExecutor()
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()

    let result = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-no-op",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )

    #expect(result.outcome == .noOp)
    try fixture.expectNoCandidate(result)
    let repeated = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-no-op",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )
    #expect(repeated.outcome == .noOp)
    try fixture.expectNoCandidate(repeated)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("pre-commit отказы типизированы и не меняют исходный репозиторий")
  func rejectsForbiddenDirtySecretAndBlockedRuns() throws {
    for scenario in WritingRejectionScenario.allCases {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package: Data
      let request: WritingSubnodeExecutionRequest

      switch scenario {
      case .forbidden:
        package = try fixture.workPackage(
          allowedPaths: ["output/result.txt"],
          requiredArtifacts: ["output/result.txt"]
        )
        request = try fixture.request(
          runID: "run-forbidden",
          writes: [
            WritingSubnodeWrite(path: "outside/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      case .gitMetadata:
        package = try fixture.workPackage(
          allowedPaths: [".GIT/config"],
          requiredArtifacts: [".GIT/config"]
        )
        request = try fixture.request(
          runID: "run-git-metadata",
          writes: [
            WritingSubnodeWrite(path: ".GIT/config", contents: Data("candidate\n".utf8))
          ]
        )
      case .dirtySource:
        package = try fixture.workPackage(
          allowedPaths: ["output/result.txt"],
          requiredArtifacts: ["output/result.txt"]
        )
        try Data("untracked\n".utf8).write(to: fixture.source.appending(path: "dirty.txt"))
        request = try fixture.request(
          runID: "run-dirty",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      case .secret:
        package = try fixture.workPackage(
          allowedPaths: ["output/result.txt"],
          requiredArtifacts: ["output/result.txt"]
        )
        request = try fixture.request(
          runID: "run-secret",
          writes: [
            WritingSubnodeWrite(
              path: "output/result.txt",
              contents: Data("-----BEGIN PRIVATE KEY-----\nfixture\n".utf8)
            )
          ]
        )
      case .blockedPackage:
        package = try fixture.workPackage(
          allowedPaths: ["output/result.txt"],
          requiredArtifacts: ["output/result.txt"],
          dependencyStatus: "unresolved"
        )
        request = try fixture.request(
          runID: "run-blocked",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      }

      let sourceBefore = try fixture.sourceSnapshot()
      let result: WritingSubnodeExecutionResult
      if scenario == .blockedPackage {
        result = try executor.execute(
          workPackageData: package,
          workspaceRoot: fixture.source,
          request: request
        )
      } else {
        let verified = try #require(fixture.readyPackage(package, executor: executor))
        result = try executor.execute(verified, request: request)
      }

      #expect(result.outcome == scenario.expectedOutcome, "scenario: \(scenario)")
      #expect(result.cloneURL == nil, "pre-write scenario unexpectedly created clone: \(scenario)")
      if scenario == .blockedPackage {
        #expect(result.workPackageReport?.decision == .splitRequired)
        let repeated = try executor.execute(
          workPackageData: package,
          workspaceRoot: fixture.source,
          request: request
        )
        #expect(repeated.outcome == .blockedBeforeWrite)
        #expect(repeated.workPackageReport == result.workPackageReport)
        try fixture.expectNoCandidate(repeated)
      }
      try fixture.expectNoCandidate(result)
      #expect(try fixture.sourceSnapshot() == sourceBefore, "scenario: \(scenario)")
    }
  }

  @Test("изменение входа после первичной верификации закрывает запись")
  func changedInputAfterVerificationIsRejected() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = fixture.passingExecutor()
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    try Data("changed after verification\n".utf8).write(
      to: fixture.source.appending(path: "input.txt")
    )
    let sourceBefore = try fixture.sourceSnapshot()

    let result = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-input-changed",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )

    #expect(result.outcome == .inputChanged)
    #expect(result.cloneURL == nil)
    #expect(
      result.workPackageReport?.violations.contains { $0.code == "input_hash_mismatch" } == true)
    try fixture.expectNoCandidate(result)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("публикационно недопустимые commit message и бинарный diff получают типизированный исход")
  func rejectsUnsafePublicationValues() throws {
    let scenarios: [(String, String, Data, String, WritingSubnodeOutcome)] = [
      (
        "run-local-message", "Read /Users/example/private", Data("candidate\n".utf8),
        "repo-fixture",
        .publicationRejected
      ),
      (
        "run-secret-message", "Use github_pat_fixture", Data("candidate\n".utf8),
        "repo-fixture",
        .secretDetected
      ),
      (
        "run-rsa-secret", "-----BEGIN RSA PRIVATE KEY-----", Data("candidate\n".utf8),
        "repo-fixture", .secretDetected
      ),
      (
        "run-bearer-secret", "AUTHORIZATION : bEaReR fixture-token", Data("candidate\n".utf8),
        "repo-fixture", .secretDetected
      ),
      (
        "run-binary", "Create candidate result", Data([0xFF, 0x00, 0x41]), "repo-fixture",
        .publicationRejected
      ),
      (
        "run-local-repository", "Create candidate result", Data("candidate\n".utf8), "localhost",
        .publicationRejected
      ),
      (
        "run-windows-message", #"Read C:\Users\example\private"#, Data("candidate\n".utf8),
        "repo-fixture", .publicationRejected
      ),
      (
        "run-home-message", "Read ~/private", Data("candidate\n".utf8), "repo-fixture",
        .publicationRejected
      ),
    ]
    for (runID, commitMessage, contents, repositoryID, expected) in scenarios {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      let result = try executor.execute(
        verified,
        request: try fixture.request(
          runID: runID,
          repositoryID: repositoryID,
          commitMessage: commitMessage,
          writes: [WritingSubnodeWrite(path: "output/result.txt", contents: contents)]
        )
      )
      #expect(result.outcome == expected)
      #expect(result.cloneURL == nil)
      try fixture.expectNoCandidate(result)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }
  }

  @Test("незавершённая положительная попытка безопасно повторяется в новом клоне")
  func resumesIncompleteAttemptWithoutReusingClone() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = fixture.passingExecutor()
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let request = try fixture.request(
      runID: "run-resume",
      writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
    )
    let sourceBefore = try fixture.sourceSnapshot()
    let first = try executor.execute(verified, request: request)
    #expect(first.outcome == .candidateCommitted)
    try FileManager.default.removeItem(
      at: fixture.executionRoot.appending(path: "runs/run-resume/result.json"))
    try FileManager.default.removeItem(
      at: fixture.executionRoot.appending(path: "passports/run-resume.json"))

    let resumed = try executor.execute(verified, request: request)
    #expect(resumed.outcome == .candidateCommitted)
    #expect(resumed.passport?.commitOID == first.passport?.commitOID)
    #expect(
      FileManager.default.fileExists(
        atPath: fixture.executionRoot.appending(path: "runs/run-resume/abandoned/clone-00001").path
      )
    )
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("восстановление отвергает изменённые refs, паспорт, иерархию и Git-конфигурацию")
  func recoveryRejectsTampering() throws {
    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      let result = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-tampered-ref",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let cloneURL = try #require(result.cloneURL)
      let resultRef = try #require(result.passport?.resultRef)
      _ = try fixture.git(
        [
          "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "tag", "-a",
          "tampered-result", "-m", "tampered result",
        ],
        at: cloneURL
      )
      let tagOID = try fixture.git(["rev-parse", "refs/tags/tampered-result"], at: cloneURL)
      _ = try fixture.git(["update-ref", resultRef, tagOID], at: cloneURL)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-tampered-ref"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-tampered-receipt",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let receiptURL = fixture.executionRoot.appending(
        path: "runs/run-tampered-receipt/result.json")
      var receipt = try #require(
        JSONSerialization.jsonObject(with: Data(contentsOf: receiptURL)) as? [String: Any]
      )
      receipt["passport_sha256"] = "sha256:" + String(repeating: "0", count: 64)
      try JSONSerialization.data(withJSONObject: receipt, options: [.sortedKeys]).write(
        to: receiptURL)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-tampered-receipt"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-symlink-passport",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let passportURL = fixture.executionRoot.appending(path: "passports/run-symlink-passport.json")
      let backupURL = fixture.executionRoot.appending(path: "passport-backup.json")
      try FileManager.default.copyItem(at: passportURL, to: backupURL)
      try FileManager.default.removeItem(at: passportURL)
      try FileManager.default.createSymbolicLink(at: passportURL, withDestinationURL: backupURL)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-symlink-passport"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      let result = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-filter-config",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let cloneURL = try #require(result.cloneURL)
      let sentinel = fixture.executionRoot.appending(path: "unexpected-filter-execution")
      _ = try fixture.git(
        ["config", "filter.evil.clean", "touch \(sentinel.path)"],
        at: cloneURL
      )
      try Data("output/result.txt filter=evil\n".utf8).write(
        to: cloneURL.appending(path: ".git/info/attributes")
      )
      try Data("candidate\n".utf8).write(to: cloneURL.appending(path: "output/result.txt"))
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-filter-config"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(!FileManager.default.fileExists(atPath: sentinel.path))
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      let result = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-fifo-config",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let configURL = try #require(result.cloneURL).appending(path: ".git/config")
      try FileManager.default.removeItem(at: configURL)
      #expect(configURL.path.withCString { mkfifo($0, 0o600) } == 0)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-fifo-config"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      let result = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-symlink-git-directory",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let cloneURL = try #require(result.cloneURL)
      let gitURL = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
      let backupURL = cloneURL.appending(path: ".git-backup", directoryHint: .isDirectory)
      try FileManager.default.moveItem(at: gitURL, to: backupURL)
      try FileManager.default.createSymbolicLink(at: gitURL, withDestinationURL: backupURL)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-symlink-git-directory"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }

    do {
      let fixture = try WritingFixture()
      defer { fixture.remove() }
      let executor = fixture.passingExecutor()
      let package = try fixture.workPackage(
        allowedPaths: ["output/result.txt"],
        requiredArtifacts: ["output/result.txt"]
      )
      let verified = try #require(fixture.readyPackage(package, executor: executor))
      let sourceBefore = try fixture.sourceSnapshot()
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-symlink-runs",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      let runsURL = fixture.executionRoot.appending(path: "runs", directoryHint: .isDirectory)
      let backupURL = fixture.executionRoot.appending(
        path: "runs-backup", directoryHint: .isDirectory)
      try FileManager.default.moveItem(at: runsURL, to: backupURL)
      try FileManager.default.createSymbolicLink(at: runsURL, withDestinationURL: backupURL)
      var rejected = false
      do {
        _ = try WritingSubnodeCandidateRecovery().recover(
          executionRootURL: fixture.executionRoot,
          runID: "run-symlink-runs"
        )
      } catch {
        rejected = true
      }
      #expect(rejected)
      #expect(try fixture.sourceSnapshot() == sourceBefore)
    }
  }

  @Test("исполняемая локальная Git-конфигурация закрывает запуск до клонирования")
  func rejectsExecutableSourceGitConfiguration() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    _ = try fixture.git(["config", "core.fsmonitor", "fixture-monitor"], at: fixture.source)
    let executor = fixture.passingExecutor()
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()
    var rejected = false
    do {
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-unsafe-config",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
    } catch WritingSubnodeExecutorError.invalidRequest {
      rejected = true
    } catch {
      Issue.record("Ожидался типизированный invalidRequest, получено: \(error)")
    }
    #expect(rejected)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
    #expect(
      !FileManager.default.fileExists(atPath: fixture.executionRoot.appending(path: "runs").path))
  }

  @Test("alternate refs shell-команда закрывается до клонирования")
  func rejectsAlternateRefsCommandBeforeClone() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let sentinel = fixture.executionRoot.appending(path: "unexpected-alternate-refs-execution")
    _ = try fixture.git(
      ["config", "core.alternateRefsCommand", "touch \(sentinel.path)"],
      at: fixture.source
    )
    let executor = fixture.passingExecutor()
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    var rejected = false

    do {
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-alternate-refs-command",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
    } catch WritingSubnodeExecutorError.invalidRequest {
      rejected = true
    } catch {
      Issue.record("Ожидался типизированный invalidRequest, получено: \(error)")
    }
    #expect(rejected)
    #expect(!FileManager.default.fileExists(atPath: sentinel.path))
    #expect(
      !FileManager.default.fileExists(atPath: fixture.executionRoot.appending(path: "runs").path))
  }

  @Test("специальный файл Git-конфигурации источника отвергается до запуска Git")
  func rejectsSourceGitConfigurationFIFO() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let executor = fixture.passingExecutor()
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()
    let configURL = fixture.source.appending(path: ".git/config")
    let backupURL = fixture.source.appending(path: ".git/config.backup")
    try FileManager.default.moveItem(at: configURL, to: backupURL)
    #expect(configURL.path.withCString { mkfifo($0, 0o600) } == 0)
    var rejected = false
    do {
      _ = try executor.execute(
        verified,
        request: try fixture.request(
          runID: "run-source-config-fifo",
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
    } catch WritingSubnodeExecutorError.unsafePath {
      rejected = true
    } catch {
      Issue.record("Ожидался типизированный unsafePath, получено: \(error)")
    }
    try FileManager.default.removeItem(at: configURL)
    try FileManager.default.moveItem(at: backupURL, to: configURL)
    #expect(rejected)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
    #expect(
      !FileManager.default.fileExists(atPath: fixture.executionRoot.appending(path: "runs").path))
  }

  @Test("крупная безопасная Git-конфигурация не взаимоблокирует аудит")
  func largeSafeGitConfigurationDoesNotDeadlockAudit() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let configURL = fixture.source.appending(path: ".git/config")
    var config = try Data(contentsOf: configURL)
    config.append(Data("\n[core]\n".utf8))
    for index in 0..<12_000 {
      config.append(Data(String(format: "ignorecase = true # %05d\n", index).utf8))
    }
    try config.write(to: configURL)
    let executor = fixture.passingExecutor()
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()

    let result = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-large-safe-config",
        writes: [
          WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
        ]
      )
    )
    let recovered = try WritingSubnodeCandidateRecovery().recover(
      executionRootURL: fixture.executionRoot,
      runID: "run-large-safe-config"
    )

    #expect(result.outcome == .candidateCommitted)
    #expect(recovered.passport == result.passport)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("провал зарегистрированной проверки не создаёт candidate commit")
  func failingRegisteredCheckIsRejected() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "content-check": .regularFileSHA256(
          path: "output/result.txt",
          expectedSHA256: "sha256:" + String(repeating: "0", count: 64)
        )
      ])
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()

    let result = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-check-failed",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
      )
    )

    #expect(result.outcome == .checkFailed)
    try fixture.expectNoCandidate(result)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("отсутствующая закрытая проверка даёт устойчивую блокировку до записи")
  func unregisteredCheckIsDurablyBlocked() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = WritingSubnodeExecutor()
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let request = try fixture.request(
      runID: "run-unregistered-check",
      writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
    )
    let sourceBefore = try fixture.sourceSnapshot()

    let first = try executor.execute(verified, request: request)
    let repeated = try executor.execute(verified, request: request)

    #expect(first.outcome == .blockedBeforeWrite)
    #expect(repeated.outcome == .blockedBeforeWrite)
    #expect(first.cloneURL == nil)
    #expect(repeated.cloneURL == nil)
    try fixture.expectNoCandidate(first)
    try fixture.expectNoCandidate(repeated)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("бюджет и обычное исключение проверяются до создания клона")
  func budgetAndOrdinaryExclusionAreRejectedBeforeClone() throws {
    let scenarios: [(String, Data, String)]
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    scenarios = [
      (
        "run-scope-overlap",
        try fixture.workPackage(
          allowedPaths: ["output"],
          requiredArtifacts: ["output/result.txt"],
          excludedPaths: ["output/private"]
        ),
        "scope_overlap"
      ),
      (
        "run-budget-exceeded",
        try fixture.workPackage(
          allowedPaths: ["output/result.txt"],
          requiredArtifacts: ["output/result.txt"],
          budgetWork: 30
        ),
        "budget_exceeded"
      ),
    ]
    let executor = fixture.passingExecutor()
    let sourceBefore = try fixture.sourceSnapshot()

    for (runID, package, expectedViolation) in scenarios {
      let result = try executor.execute(
        workPackageData: package,
        workspaceRoot: fixture.source,
        request: try fixture.request(
          runID: runID,
          writes: [
            WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
          ]
        )
      )
      #expect(result.outcome == .blockedBeforeWrite)
      #expect(result.cloneURL == nil)
      #expect(
        result.workPackageReport?.violations.contains { $0.code == expectedViolation } == true)
      try fixture.expectNoCandidate(result)
    }
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }

  @Test("слишком длинные компоненты ref и пути отвергаются до создания клона")
  func oversizedRefAndPathComponentsAreRejectedBeforeClone() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let executor = fixture.passingExecutor()
    let package = try fixture.workPackage(
      allowedPaths: ["output"],
      requiredArtifacts: ["output/result.txt"]
    )
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let sourceBefore = try fixture.sourceSnapshot()
    let requests = [
      try fixture.request(
        runID: String(repeating: "r", count: 128),
        subnodeID: String(repeating: "s", count: 128),
        writes: [
          WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))
        ]
      ),
      try fixture.request(
        runID: "run-long-path",
        writes: [
          WritingSubnodeWrite(
            path: "output/" + String(repeating: "p", count: 241),
            contents: Data("candidate\n".utf8)
          )
        ]
      ),
    ]

    for request in requests {
      var rejected = false
      do {
        _ = try executor.execute(verified, request: request)
      } catch WritingSubnodeExecutorError.invalidRequest {
        rejected = true
      } catch {
        Issue.record("Ожидался типизированный invalidRequest, получено: \(error)")
      }
      #expect(rejected)
    }
    #expect(try fixture.sourceSnapshot() == sourceBefore)
    #expect(
      !FileManager.default.fileExists(atPath: fixture.executionRoot.appending(path: "runs").path))
  }

  @Test("точный повтор идемпотентен, а конфликтующий run_id не переписывает результат")
  func exactRepeatAndConflictingReuseAreDistinguished() throws {
    let fixture = try WritingFixture()
    defer { fixture.remove() }
    let package = try fixture.workPackage(
      allowedPaths: ["output/result.txt"],
      requiredArtifacts: ["output/result.txt"]
    )
    let executor = fixture.passingExecutor()
    let verified = try #require(fixture.readyPackage(package, executor: executor))
    let request = try fixture.request(
      runID: "run-repeat",
      writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("candidate\n".utf8))]
    )
    let sourceBefore = try fixture.sourceSnapshot()
    let first = try executor.execute(verified, request: request)
    #expect(first.outcome == .candidateCommitted)
    #expect(first.passport != nil)
    #expect(first.passportCanonicalJSON != nil)
    #expect(first.passportSHA256 != nil)
    let cloneURL = try #require(first.cloneURL)
    let cloneAfterFirst = try fixture.repositorySnapshot(at: cloneURL)
    let executionAfterFirst = try fixture.executionSnapshot()

    let repeated = try executor.execute(verified, request: request)
    #expect(repeated.outcome == .candidateCommitted)
    #expect(repeated.passport == first.passport)
    #expect(repeated.passportCanonicalJSON == first.passportCanonicalJSON)
    #expect(repeated.passportSHA256 == first.passportSHA256)
    #expect(try fixture.repositorySnapshot(at: cloneURL) == cloneAfterFirst)
    #expect(try fixture.executionSnapshot() == executionAfterFirst)

    let conflicting = try executor.execute(
      verified,
      request: try fixture.request(
        runID: "run-repeat",
        writes: [WritingSubnodeWrite(path: "output/result.txt", contents: Data("different\n".utf8))]
      )
    )
    #expect(conflicting.outcome == .runAlreadyExists)
    #expect(conflicting.passport == nil)
    #expect(conflicting.passportSHA256 == nil)
    #expect(try fixture.executionSnapshot() == executionAfterFirst)

    let changedCheckExecutor = WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "content-check": .regularFileSHA256(
          path: "output/result.txt",
          expectedSHA256: "sha256:" + String(repeating: "0", count: 64)
        )
      ])
    )
    let changedCheck = try changedCheckExecutor.execute(verified, request: request)
    #expect(changedCheck.outcome == .runAlreadyExists)
    #expect(try fixture.repositorySnapshot(at: cloneURL) == cloneAfterFirst)
    #expect(try fixture.executionSnapshot() == executionAfterFirst)
    #expect(try fixture.sourceSnapshot() == sourceBefore)
  }
}

private enum WritingRejectionScenario: CaseIterable {
  case forbidden
  case gitMetadata
  case dirtySource
  case secret
  case blockedPackage

  var expectedOutcome: WritingSubnodeOutcome {
    switch self {
    case .forbidden, .gitMetadata: .forbiddenPath
    case .dirtySource: .dirtySource
    case .secret: .secretDetected
    case .blockedPackage: .blockedBeforeWrite
    }
  }
}

private final class WritingFixture: @unchecked Sendable {
  let root: URL
  let source: URL
  let executionRoot: URL
  private(set) var baseOID = ""

  init() throws {
    root = FileManager.default.temporaryDirectory.appending(
      path: "fum-writing-subnode-tests-\(UUID().uuidString)",
      directoryHint: .isDirectory
    )
    source = root.appending(path: "source", directoryHint: .isDirectory)
    executionRoot = root.appending(path: "execution", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: executionRoot, withIntermediateDirectories: true)
    _ = try git(["init", "--quiet", "--initial-branch=main"], at: source)
    try Data("pinned input\n".utf8).write(to: source.appending(path: "input.txt"))
    _ = try git(["add", "--", "input.txt"], at: source)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit", "--quiet",
        "-m", "base",
      ],
      at: source
    )
    baseOID = try git(["rev-parse", "HEAD"], at: source)
  }

  func request(
    runID: String = "run-001",
    subnodeID: String = "writer-001",
    repositoryID: String = "repo-fixture",
    commitMessage: String = "Create candidate result",
    writes: [WritingSubnodeWrite]
  ) throws -> WritingSubnodeExecutionRequest {
    WritingSubnodeExecutionRequest(
      episodeID: "episode-001",
      stepGenerationID: "generation-001",
      cardID: "FUM-STEP-0085",
      stepID: "step-0085",
      runID: runID,
      subnodeID: subnodeID,
      repositoryID: repositoryID,
      sourceCheckoutURL: source,
      executionRootURL: executionRoot,
      targetRef: "refs/heads/main",
      baseOID: baseOID,
      commitMessage: commitMessage,
      writes: writes
    )
  }

  func workPackage(
    allowedPaths: [String],
    requiredArtifacts: [String],
    dependencyStatus: String = "resolved",
    excludedPaths: [String] = [".git", "runtime"],
    budgetWork: Int = 5
  ) throws -> Data {
    let input = try Data(contentsOf: source.appending(path: "input.txt"))
    let package: [String: Any] = [
      "schema_version": 1,
      "package_id": "fum.writer.fixture.v1",
      "goal": "Создать один проверяемый кандидатный результат.",
      "deliverables": [
        [
          "id": "candidate", "role": "primary", "description": "Кандидатный commit.",
          "depends_on": [],
        ]
      ],
      "inputs": [
        [
          "id": "pinned-input", "path": "input.txt", "sha256": "sha256:" + sha256(input),
          "required": true,
        ]
      ],
      "change_scope": [
        "policy": "listed_paths_only", "allowed_paths": allowedPaths,
        "excluded_paths": excludedPaths,
      ],
      "dependencies": [
        [
          "id": "git", "status": dependencyStatus, "evidence": "Локальный Git доступен.",
        ]
      ],
      "checks": [
        [
          "id": "content-check", "description": "Содержимое результата детерминировано.",
        ]
      ],
      "handoff": [
        "format": "candidate_commit_v1", "required_artifacts": requiredArtifacts,
      ],
      "budget": [
        "unit": "planning_units", "limit": 20, "reading": 3, "work": budgetWork,
        "verification": 3, "response": 2, "reserve": 7,
      ],
      "preflight": ["before_model_call": true, "before_user_data_mutation": true],
    ]
    return try JSONSerialization.data(withJSONObject: package, options: [.sortedKeys])
  }

  func passingExecutor() -> WritingSubnodeExecutor {
    WritingSubnodeExecutor(
      checkRegistry: WritingSubnodeCheckRegistry(specifications: [
        "content-check": .regularFileSHA256(
          path: "output/result.txt",
          expectedSHA256: "sha256:" + sha256(Data("candidate\n".utf8))
        )
      ])
    )
  }

  func readyPackage(
    _ data: Data,
    executor: WritingSubnodeExecutor
  ) -> VerifiedWritingSubnodeWorkPackage? {
    guard case .ready(let verified) = executor.verifyWorkPackage(data, workspaceRoot: source) else {
      return nil
    }
    return verified
  }

  func commitFile(path: String, contents: Data) throws {
    let url = source.appending(path: path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try contents.write(to: url)
    _ = try git(["add", "--", path], at: source)
    _ = try git(
      [
        "-c", "user.name=FUM Fixture", "-c", "user.email=fixture@invalid", "commit", "--quiet",
        "-m", "fixture content",
      ],
      at: source
    )
    baseOID = try git(["rev-parse", "HEAD"], at: source)
  }

  func sourceSnapshot() throws -> Data {
    try repositorySnapshot(at: source)
  }

  func executionSnapshot() throws -> Data {
    try JSONSerialization.data(
      withJSONObject: try byteInventory(at: executionRoot),
      options: [.sortedKeys]
    )
  }

  func repositorySnapshot(at repository: URL) throws -> Data {
    let values: [String: Any] = [
      "head": try git(["rev-parse", "HEAD"], at: repository),
      "symbolic_head": try git(["symbolic-ref", "-q", "HEAD"], at: repository),
      "status": try git(["status", "--porcelain=v1", "--untracked-files=all"], at: repository),
      "refs": try git(
        ["for-each-ref", "--format=%(refname)%00%(objectname)%00%(objecttype)"], at: repository),
      "history": try git(["rev-list", "--all", "--objects"], at: repository),
      "objects": try git(["count-objects", "-v"], at: repository),
      "bytes": try byteInventory(at: repository),
    ]
    return try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
  }

  func expectNoCandidate(_ result: WritingSubnodeExecutionResult) throws {
    #expect(result.passport == nil)
    #expect(result.passportCanonicalJSON == nil)
    #expect(result.passportSHA256 == nil)
    #expect(result.parentUnchanged)
    let sourceCommits = try allCommitOIDs(at: source)
    for cloneURL in try executionCloneURLs() {
      #expect(
        try git(["for-each-ref", "--format=%(refname)", "refs/fum/results"], at: cloneURL)
          .isEmpty
      )
      #expect(try allCommitOIDs(at: cloneURL).isSubset(of: sourceCommits))
    }
  }

  func expectIsolatedClone(_ cloneURL: URL) throws {
    let gitDirectory = try git(["rev-parse", "--absolute-git-dir"], at: cloneURL)
    let commonDirectory = try git(
      ["rev-parse", "--path-format=absolute", "--git-common-dir"],
      at: cloneURL
    )
    let expected = cloneURL.appending(path: ".git", directoryHint: .isDirectory)
      .standardizedFileURL.path
    #expect(URL(fileURLWithPath: gitDirectory).standardizedFileURL.path == expected)
    #expect(URL(fileURLWithPath: commonDirectory).standardizedFileURL.path == expected)
    #expect(try git(["remote"], at: cloneURL).isEmpty)
    #expect(try git(["status", "--porcelain=v1", "--untracked-files=all"], at: cloneURL).isEmpty)
    #expect(
      try cloneURL.appending(path: ".git", directoryHint: .isDirectory)
        .resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == false
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: URL(fileURLWithPath: gitDirectory).appending(path: "objects/info/alternates").path
      )
    )
  }

  private func executionCloneURLs() throws -> [URL] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: executionRoot,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: []
      )
    else {
      return []
    }
    var clones: [URL] = []
    for case let url as URL in enumerator where url.lastPathComponent == ".git" {
      let values = try url.resourceValues(forKeys: [.isDirectoryKey])
      if values.isDirectory == true { clones.append(url.deletingLastPathComponent()) }
    }
    return clones.sorted { $0.path < $1.path }
  }

  private func allCommitOIDs(at repository: URL) throws -> Set<String> {
    Set(
      try git(
        ["cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype)"],
        at: repository
      )
      .split(separator: "\n")
      .compactMap { line in
        let fields = line.split(separator: " ")
        guard fields.count == 2, fields[1] == "commit" else { return nil }
        return String(fields[0])
      }
    )
  }

  private func byteInventory(at root: URL) throws -> [String: String] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: []
      )
    else {
      return [:]
    }
    var inventory: [String: String] = [:]
    for case let url as URL in enumerator {
      let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      let relative = String(url.path.dropFirst(root.path.count + 1))
      if values.isSymbolicLink == true {
        inventory[relative] =
          "link:" + (try FileManager.default.destinationOfSymbolicLink(atPath: url.path))
      } else if values.isRegularFile == true {
        inventory[relative] = "file:" + (try Data(contentsOf: url)).base64EncodedString()
      }
    }
    return inventory
  }

  func git(_ arguments: [String], at directory: URL?) throws -> String {
    let process = Process()
    process.executableURL = WritingSubnodeSystemRuntime.gitExecutableURL
    process.arguments =
      [
        "--no-replace-objects", "--no-optional-locks",
        "-c", "core.fsmonitor=false",
        "-c", "core.hooksPath=\(WritingSubnodeSystemRuntime.nullDevicePath)",
        "-c", "core.untrackedCache=false",
      ]
      + (directory.map { ["-C", $0.path] } ?? []) + arguments
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
    guard process.terminationStatus == 0 else {
      throw NSError(
        domain: "WritingFixture.git", code: Int(process.terminationStatus),
        userInfo: [
          NSLocalizedDescriptionKey: String(decoding: data, as: UTF8.self)
        ])
    }
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  func runPassportProbe(runID: String) throws -> WritingProbeResult {
    let executable = Bundle(for: WritingSubnodeTestBundleToken.self).bundleURL
      .deletingLastPathComponent()
      .appending(path: "FUMWritingSubnodePassportProbe")
    let output = Pipe()
    let error = Pipe()
    let process = Process()
    process.executableURL = executable
    process.arguments = [executionRoot.path, runID]
    process.standardOutput = output
    process.standardError = error
    try process.run()
    try output.fileHandleForWriting.close()
    try error.fileHandleForWriting.close()
    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = error.fileHandleForReading.readDataToEndOfFile()
    let processID = process.processIdentifier
    process.waitUntilExit()
    return WritingProbeResult(
      processID: processID,
      status: process.terminationStatus,
      output: outputData,
      error: errorData
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private final class WritingSubnodeTestBundleToken: NSObject {}

private struct WritingProbeResult {
  let processID: Int32
  let status: Int32
  let output: Data
  let error: Data
}
