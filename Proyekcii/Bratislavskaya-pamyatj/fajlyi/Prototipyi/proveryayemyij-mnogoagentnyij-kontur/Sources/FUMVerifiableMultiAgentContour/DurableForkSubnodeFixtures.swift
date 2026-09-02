import Foundation

public enum DurableForkScenarioDecision: String, Codable, Equatable, Sendable {
  case passed
  case failed
}

public struct DurableForkScenarioCheck: Codable, Equatable, Sendable {
  public let identifier: String
  public let passed: Bool
}

public struct DurableForkScenarioReport: Codable, Equatable, Sendable {
  public let schemaIdentity: String
  public let schemaVersion: Int
  public let scenarioID: String
  public let decision: DurableForkScenarioDecision
  public let repositoryIdentities: [String]
  public let checks: [DurableForkScenarioCheck]
  public let registrationPassportSHA256: String?
  public let handoffPassportSHA256: String?
  public let parentUpdatePassportSHA256: String?
  public let initialForkOID: String?
  public let finalForkOID: String?
  public let initialParentOID: String?
  public let finalParentOID: String?
  public let initialUpstreamOID: String?
  public let finalUpstreamOID: String?
  public let unexpectedRefMutation: Bool

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case scenarioID = "scenario_id"
    case decision
    case repositoryIdentities = "repository_identities"
    case checks
    case registrationPassportSHA256 = "registration_passport_sha256"
    case handoffPassportSHA256 = "handoff_passport_sha256"
    case parentUpdatePassportSHA256 = "parent_update_passport_sha256"
    case initialForkOID = "initial_fork_oid"
    case finalForkOID = "final_fork_oid"
    case initialParentOID = "initial_parent_oid"
    case finalParentOID = "final_parent_oid"
    case initialUpstreamOID = "initial_upstream_oid"
    case finalUpstreamOID = "final_upstream_oid"
    case unexpectedRefMutation = "unexpected_ref_mutation"
  }

  public func canonicalJSONData() throws -> Data { try DurableForkJSON.encode(self) }
}

public enum DurableForkSubnodeFixtureError: Error, CustomStringConvertible, Sendable {
  case unknownFixture(String)
  case setupFailed(String)

  public var description: String {
    switch self {
    case .unknownFixture(let identifier):
      "Неизвестная фикстура долговечного fork-подузла: \(identifier)."
    case .setupFailed(let message): message
    }
  }
}

public enum DurableForkSubnodeFixtures {
  public static let identifiers = [
    "roundtrip",
    "invalid-upstream-remote",
    "invalid-handoff-access",
    "invalid-handoff-base",
    "invalid-sync-oid",
    "invalid-sync-conflict",
    "invalid-sync-access",
    "invalid-sync-publication",
    "invalid-upstream-gitlink",
    "invalid-registration-upstream-gitlink",
    "invalid-ancestor-submodule",
    "invalid-self-recursive-submodule",
    "recursive-init-forbidden",
    "invalid-queue-namespace",
    "invalid-parent-update",
  ]

  public static func run(named identifier: String) throws -> DurableForkScenarioReport {
    guard identifiers.contains(identifier) else {
      throw DurableForkSubnodeFixtureError.unknownFixture(identifier)
    }
    let root = FileManager.default.temporaryDirectory.appending(
      path: "fum-durable-fork-fixture-\(identifier)-\(ProcessInfo.processInfo.processIdentifier)",
      directoryHint: .isDirectory
    )
    if FileManager.default.fileExists(atPath: root.path) {
      try FileManager.default.removeItem(at: root)
    }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let environment = try FixtureEnvironment.make(root: root)
    switch identifier {
    case "roundtrip": return try runRoundTrip(environment)
    case "invalid-upstream-remote": return try runInvalidUpstreamRemote(environment)
    case "invalid-handoff-access": return try runInvalidHandoffAccess(environment)
    case "invalid-handoff-base": return try runInvalidHandoffBase(environment)
    case "invalid-sync-oid": return try runInvalidSyncOID(environment)
    case "invalid-sync-conflict": return try runInvalidSyncConflict(environment)
    case "invalid-sync-access": return try runInvalidSyncAccess(environment)
    case "invalid-sync-publication": return try runInvalidSyncPublication(environment)
    case "invalid-upstream-gitlink": return try runInvalidUpstreamGitlink(environment)
    case "invalid-registration-upstream-gitlink":
      return try runInvalidRegistrationUpstreamGitlink(environment)
    case "invalid-ancestor-submodule", "invalid-self-recursive-submodule":
      return try runObservedTopologyScenario(identifier, environment: environment)
    case "recursive-init-forbidden": return try runRecursiveInitialization(environment)
    case "invalid-queue-namespace": return try runInvalidQueueNamespace(environment)
    case "invalid-parent-update": return try runInvalidParentUpdate(environment)
    default: throw DurableForkSubnodeFixtureError.unknownFixture(identifier)
    }
  }
}

private struct FixtureEnvironment {
  let root: URL
  let coreBare: URL
  let assemblyBare: URL
  let coreOID: String
  let assemblyOID: String
  let improvedData: Data
  let runtime: DurableForkSubnodeRuntime
  let registrationRequest: DurableForkRegistrationRequest
  let git: CandidateIntegrationGit

  static func make(root: URL) throws -> FixtureEnvironment {
    let git = CandidateIntegrationGit()
    let coreBare = root.appending(path: "core.git", directoryHint: .isDirectory)
    let assemblyBare = root.appending(path: "assembly.git", directoryHint: .isDirectory)
    let repositoryRoot = try fixtureRepositoryRoot()
    let queueScriptPath =
      "Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py"
    let nextStepValidatorPath =
      "Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py"
    let queueScriptData = try Data(
      contentsOf: repositoryRoot.appending(path: queueScriptPath))
    let nextStepValidatorData = try Data(
      contentsOf: repositoryRoot.appending(path: nextStepValidatorPath))
    let coreOID = try FixtureGit.seedBare(
      at: coreBare,
      root: root,
      name: "core-seed",
      files: [
        "Shared/common.txt": Data("core base\n".utf8),
        queueScriptPath: queueScriptData,
        nextStepValidatorPath: nextStepValidatorData,
      ],
      message: "Core base",
      git: git
    )
    let assemblyOID = try FixtureGit.seedBare(
      at: assemblyBare,
      root: root,
      name: "assembly-seed",
      files: ["README.md": Data("assembly base\n".utf8)],
      message: "Assembly base",
      git: git
    )
    let improvedData = Data("core improved\n".utf8)
    let expectedSHA256 = DurableForkJSON.sha256(improvedData)
    let runtime = DurableForkSubnodeRuntime(
      writingCheckRegistry: WritingSubnodeCheckRegistry(
        specifications: [
          "common-content": .regularFileSHA256(
            path: "Shared/common.txt", expectedSHA256: expectedSHA256)
        ]
      ),
      integrationCheckRegistry: CandidateIntegrationCheckRegistry(
        specifications: [
          "common-content": .regularFileSHA256(
            path: "Shared/common.txt", expectedSHA256: expectedSHA256)
        ]
      )
    )
    let registration = DurableForkRegistrationRequest(
      nodeID: "node.specialized.fixture",
      forkRepositoryID: "repository.specialized.fixture",
      upstreamRepositoryID: "repository.core.fixture",
      assemblyRepositoryID: "repository.assembly.fixture",
      coreBareURL: coreBare,
      forkBareURL: root.appending(path: "fork.git", directoryHint: .isDirectory),
      assemblyBareURL: assemblyBare,
      liveCloneURL: root.appending(path: "fork-live", directoryHint: .isDirectory),
      runtimeRootURL: root.appending(path: "registration-runtime", directoryHint: .isDirectory),
      snapshotRootURL: root.appending(path: "parent-snapshot", directoryHint: .isDirectory),
      upstreamRef: "refs/heads/main",
      liveRef: "refs/heads/nodes/specialized/main",
      assemblyRef: "refs/heads/main",
      expectedUpstreamOID: coreOID,
      expectedAssemblyOID: assemblyOID,
      submodulePath: "Подузлы/специализированный",
      submoduleURL: "../fork.git",
      rulesPath: "AGENTS.md",
      rulesData: Data(
        """
        # Правила специализированного подузла

        Подузел работает только в автономном локальном стенде, продолжает собственную ветку и не изменяет родительскую assembly из живого клона.

        Корневая задача использует локальную очередь через `Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py`, а следующий шаг проверяется через `Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py`.
        """.utf8),
      queueRefNamespace: "refs/fum/worktree-task-queues",
      queueBootstrapScriptPath: queueScriptPath,
      queueBootstrapScriptSHA256: DurableForkJSON.sha256(queueScriptData),
      nextStepValidatorPath: nextStepValidatorPath,
      nextStepValidatorSHA256: DurableForkJSON.sha256(nextStepValidatorData),
      nextStepRecordPath: "Планирование/следующие-шаги-веток/specialized.md",
      projectPath: "Паспорт-подузла.json",
      nextStepCardPath:
        "Планирование/карточки-шагов/🟡-FUM-STEP-9001-продолжить-специализированный-подузел.md",
      nextStepCardID: "FUM-STEP-9001",
      nextStepID: "node-specialized-step-0001-automatic-v1",
      nextStepCardData: Data(
        ("""
        +++
        schema_version = 1
        card_id = "FUM-STEP-9001"
        status = "active"
        +++
        # Продолжить специализированный подузел

        Карточка задаёт один ограниченный следующий шаг подузла.

        ## Задача

        Выполнить следующий локальный шаг специализации.

        ## Почему сейчас

        Подузел зарегистрирован и готов продолжить собственную ветку.

        ## Критерии завершения

        - Результат шага сохранён в ветке подузла.
        - Локальные проверки завершились успешно.

        ## Источники

        - Паспорт специализации подузла.
        """ + "\n").utf8),
      accessLevel: .public,
      publicationBoundary: .public
    )
    return FixtureEnvironment(
      root: root,
      coreBare: coreBare,
      assemblyBare: assemblyBare,
      coreOID: coreOID,
      assemblyOID: assemblyOID,
      improvedData: improvedData,
      runtime: runtime,
      registrationRequest: registration,
      git: git
    )
  }

  private static func fixtureRepositoryRoot() throws -> URL {
    let startingPoints = [
      URL(
        fileURLWithPath: FileManager.default.currentDirectoryPath,
        isDirectory: true
      ),
      Bundle.module.bundleURL,
    ]
    for startingPoint in startingPoints {
      var candidate = startingPoint.standardizedFileURL
      for _ in 0..<16 {
        if FileManager.default.fileExists(
          atPath: candidate.appending(path: "AGENTS.md").path)
        {
          return candidate
        }
        candidate.deleteLastPathComponent()
      }
    }
    throw DurableForkSubnodeFixtureError.setupFailed(
      "Не найден корень исходного checkout для чтения локальных FUM-сценариев.")
  }
}

extension DurableForkSubnodeFixtures {
  private static func registeredNode(_ environment: FixtureEnvironment) throws
    -> DurableForkNodeContext
  {
    let result = try environment.runtime.register(environment.registrationRequest)
    guard result.outcome == .registered, let node = result.node else {
      throw DurableForkSubnodeFixtureError.setupFailed(
        "Регистрация fixture завершилась исходом \(result.outcome.rawValue)."
      )
    }
    try FixtureGit.normalizeCheckout(node.liveCloneURL, git: environment.git)
    return node
  }

  private static func publishedCandidate(
    _ environment: FixtureEnvironment,
    node: DurableForkNodeContext
  ) throws -> DurableForkCandidateResult {
    let workPackage = try FixtureContracts.workPackage(
      inputSHA256: DurableForkJSON.sha256(Data("core base\n".utf8))
    )
    let request = DurableForkCandidateRequest(
      node: node,
      workPackageData: workPackage,
      executionRootURL: environment.root.appending(
        path: "candidate-execution", directoryHint: .isDirectory),
      integrationRootURL: environment.root.appending(
        path: "candidate-integration", directoryHint: .isDirectory),
      episodeID: "episode.durable-fork.fixture",
      stepGenerationID: "generation.durable-fork.fixture.1",
      cardID: "FUM-STEP-9001",
      stepID: "node-specialized-step-0001-automatic-v1",
      runID: "run.durable-fork.fixture.1",
      attemptID: "integration.durable-fork.fixture.1",
      ownerID: "owner.durable-fork.fixture",
      commitMessage: "Improve shared core fixture",
      integrationCommitMessage: "Accept specialized candidate in fork",
      writes: [WritingSubnodeWrite(path: "Shared/common.txt", contents: environment.improvedData)],
      checkIDs: ["common-content"]
    )
    let result = try environment.runtime.publishCandidate(request)
    guard result.outcome == .candidatePublished, result.node != nil,
      result.candidate?.passport != nil, result.candidate?.passportSHA256 != nil
    else {
      throw DurableForkSubnodeFixtureError.setupFailed(
        "Кандидат fixture завершился исходом \(result.outcome.rawValue)."
      )
    }
    return result
  }

  private static func acceptedHandoff(
    _ environment: FixtureEnvironment,
    candidate: DurableForkCandidateResult,
    nodeOverride: DurableForkNodeContext? = nil,
    accessLevel: RepositoryCompositionAccessLevel = .public,
    publicationBoundary: RepositoryCompositionAccessLevel = .public,
    expectedUpstreamOID: String? = nil,
    rootName: String = "upstream-handoff",
    commitMessage: String = "Accept shared improvement from durable fork"
  ) throws -> DurableForkHandoffResult {
    guard let candidateNode = candidate.node,
      let passport = candidate.candidate?.passport,
      let passportSHA256 = candidate.candidate?.passportSHA256
    else {
      throw DurableForkSubnodeFixtureError.setupFailed("Паспорт кандидата отсутствует.")
    }
    let node = nodeOverride ?? candidateNode
    return try environment.runtime.handoffUpstream(
      DurableForkHandoffRequest(
        node: node,
        handoffID: "handoff.durable-fork.fixture.1",
        executionRootURL: environment.root.appending(
          path: "candidate-execution", directoryHint: .isDirectory),
        runID: passport.runID,
        expectedCandidateOID: passport.commitOID,
        expectedCandidatePassportSHA256: passportSHA256,
        integrationRootURL: environment.root.appending(
          path: rootName, directoryHint: .isDirectory),
        expectedUpstreamOID: expectedUpstreamOID ?? node.upstreamOID,
        changeScope: ["Shared/common.txt"],
        checks: [
          DurableForkFileCheck(
            checkID: "common-content",
            path: "Shared/common.txt",
            expectedSHA256: DurableForkJSON.sha256(environment.improvedData)
          )
        ],
        accessLevel: accessLevel,
        publicationBoundary: publicationBoundary,
        commitMessage: commitMessage
      )
    )
  }

  private static func synchronized(
    _ environment: FixtureEnvironment,
    node: DurableForkNodeContext,
    accessLevel: RepositoryCompositionAccessLevel = .public,
    publicationBoundary: RepositoryCompositionAccessLevel = .public,
    expectedForkOID: String? = nil,
    expectedUpstreamOID: String? = nil,
    rootName: String = "fork-sync",
    commitMessage: String = "Synchronize durable fork with exact upstream"
  ) throws -> DurableForkSyncResult {
    try environment.runtime.synchronizeFromUpstream(
      DurableForkSyncRequest(
        node: node,
        syncID: "sync.durable-fork.fixture.1",
        syncRootURL: environment.root.appending(path: rootName, directoryHint: .isDirectory),
        expectedForkOID: expectedForkOID ?? node.forkOID,
        expectedUpstreamOID: expectedUpstreamOID ?? node.upstreamOID,
        accessLevel: accessLevel,
        publicationBoundary: publicationBoundary,
        commitMessage: commitMessage
      )
    )
  }

  private static func runRoundTrip(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let registered = try registeredNode(environment)
    let initialForkOID = registered.forkOID
    let initialParentOID = registered.assemblyOID
    let initialUpstreamOID = registered.upstreamOID
    let initialParentRef = try FixtureGit.refOID(
      registered.assemblyRef, repository: registered.assemblyBareURL, git: environment.git)

    let candidate = try publishedCandidate(environment, node: registered)
    let candidateNode = try require(candidate.node, "Обновлённый fork-контекст отсутствует.")
    let sourcePassport = try require(
      candidate.candidate?.passport, "Паспорт кандидата отсутствует.")
    let evolvedUpstreamOID = try FixtureGit.commitChange(
      repository: candidateNode.coreBareURL,
      root: environment.root,
      name: "upstream-evolution",
      ref: candidateNode.upstreamRef,
      expectedOID: candidateNode.upstreamOID,
      files: ["Shared/upstream.txt": Data("explicit upstream evolution\n".utf8)],
      message: "Evolve core before fork handoff",
      git: environment.git
    )
    let syncInputNode = candidateNode.updating(upstreamOID: evolvedUpstreamOID)
    let forkBeforeSync = try FixtureGit.refOID(
      candidateNode.liveRef, repository: candidateNode.forkBareURL, git: environment.git)
    let sync = try synchronized(environment, node: syncInputNode)
    guard sync.outcome == .synchronized, let syncNode = sync.node, let syncOID = sync.syncOID else {
      throw DurableForkSubnodeFixtureError.setupFailed(
        "Синхронизация завершилась исходом \(sync.outcome.rawValue).")
    }
    let handoff = try acceptedHandoff(
      environment, candidate: candidate, nodeOverride: syncNode,
      expectedUpstreamOID: syncNode.upstreamOID)
    guard handoff.outcome == .handoffAccepted else {
      throw DurableForkSubnodeFixtureError.setupFailed(
        "Передача вверх завершилась исходом \(handoff.outcome.rawValue).")
    }
    let handoffNode = try require(handoff.node, "Контекст после передачи отсутствует.")
    let parentUpdate = try environment.runtime.updateParentGitlink(
      DurableForkParentUpdateRequest(
        node: handoffNode,
        updateID: "parent-update.durable-fork.fixture.1",
        updateRootURL: environment.root.appending(
          path: "parent-update", directoryHint: .isDirectory),
        snapshotRootURL: environment.root.appending(
          path: "parent-snapshot-final", directoryHint: .isDirectory),
        expectedParentOID: handoffNode.assemblyOID,
        expectedPreviousGitlinkOID: handoffNode.gitlinkOID,
        gitlinkOID: handoffNode.forkOID,
        commitMessage: "Update durable fork gitlink after verification"
      )
    )
    guard parentUpdate.outcome == .parentUpdated, let finalNode = parentUpdate.node else {
      throw DurableForkSubnodeFixtureError.setupFailed(
        "Обновление gitlink завершилось исходом \(parentUpdate.outcome.rawValue).")
    }
    let freshParent = try environment.runtime.restoreParentSnapshot(
      DurableForkRestoreRequest(
        node: finalNode,
        destinationURL: environment.root.appending(
          path: "fresh-parent", directoryHint: .isDirectory)
      )
    )
    let freshLive = try environment.runtime.restoreLiveClone(
      node: finalNode,
      destinationURL: environment.root.appending(
        path: "fresh-live", directoryHint: .isDirectory)
    )
    let finalGitlink = try FixtureGit.gitlink(
      parentOID: finalNode.assemblyOID,
      path: finalNode.submodulePath,
      repository: finalNode.assemblyBareURL,
      git: environment.git
    )
    let remotesAreValid = try environment.runtime.verifyRemoteBindings(finalNode)
    let upstreamIsInstanceFree = try !DurableForkValidation.containsGitlink(
      treeish: initialUpstreamOID,
      repository: environment.coreBare,
      git: environment.git)
    let candidateIsReachable = try environment.git.succeeds(
      ["merge-base", "--is-ancestor", sourcePassport.commitOID, candidateNode.forkOID],
      at: candidateNode.forkBareURL)
    let upstreamPreservesCandidate = try environment.git.succeeds(
      ["merge-base", "--is-ancestor", sourcePassport.commitOID, handoffNode.upstreamOID],
      at: handoffNode.coreBareURL)
    let syncParents = try FixtureGit.parents(
      syncOID, repository: syncNode.forkBareURL, git: environment.git)
    let parentParents = try FixtureGit.parents(
      finalNode.assemblyOID, repository: finalNode.assemblyBareURL, git: environment.git)
    let bareQueueRefs = try environment.git.text(
      ["for-each-ref", "--format=%(refname)", "\(finalNode.queueRefNamespace)/"],
      at: finalNode.forkBareURL)
    let checks = [
      check(
        "fork_has_stable_identity", registered.registrationPassport.nodeID == registered.nodeID),
      check("fork_has_origin_and_upstream", remotesAreValid),
      check(
        "fork_has_own_rules_queue_and_next_step",
        freshLive.outcome == .restored
          && freshLive.nextStepRecordSHA256
            == finalNode.registrationPassport.nextStepRecordSHA256
          && freshLive.nextStepValidationState == "valid"
          && freshLive.queueValidationState == "idle"
          && freshLive.queueRef?.hasPrefix("\(finalNode.queueRefNamespace)/") == true
          && freshLive.queueRef != finalNode.liveQueueRef
          && bareQueueRefs.isEmpty
      ),
      check(
        "upstream_is_instance_free_core",
        upstreamIsInstanceFree
      ),
      check("parent_gitlink_is_exact", registered.gitlinkOID == initialForkOID),
      check(
        "parent_snapshot_is_detached_and_clean",
        registered.compositionReport.decision == .valid
          && registered.compositionReport.childVerifications.first?.snapshotIsDetached == true
          && registered.compositionReport.childVerifications.first?.snapshotIsClean == true
      ),
      check(
        "writer_did_not_change_parent",
        initialParentRef == registered.assemblyOID
          && candidateNode.assemblyOID == registered.assemblyOID
      ),
      check(
        "candidate_is_reachable_from_fork_live_ref",
        candidateIsReachable
      ),
      check(
        "handoff_binds_source_scope_checks_access_and_parent",
        handoff.passport?.sourceCommitOID == sourcePassport.commitOID
          && handoff.passport?.changeScope == ["Shared/common.txt"]
          && handoff.passport?.checks.map(\.checkID) == ["common-content"]
          && handoff.passport?.accessLevel == .public
          && handoff.passport?.parentBaseOID == evolvedUpstreamOID
      ),
      check(
        "upstream_preserves_source_candidate_in_ancestry",
        upstreamPreservesCandidate
      ),
      check(
        "upstream_does_not_move_fork_live_ref_implicitly", forkBeforeSync == candidateNode.forkOID),
      check(
        "sync_is_explicit_and_exact",
        syncOID == syncNode.forkOID
          && syncParents == [candidateNode.forkOID, evolvedUpstreamOID]
      ),
      check(
        "parent_gitlink_update_is_separate_commit",
        finalNode.assemblyOID != initialParentOID
          && finalGitlink == finalNode.forkOID
          && parentParents == [initialParentOID]
      ),
      check(
        "fresh_parent_clone_restores_exact_snapshot",
        freshParent.outcome == .restored
          && freshParent.headOID == finalNode.gitlinkOID
          && freshParent.snapshotIsDetached == true
          && freshParent.snapshotIsClean == true
      ),
      check(
        "fresh_live_clone_continues_branch_and_next_step",
        freshLive.outcome == .restored
          && freshLive.headOID == finalNode.forkOID
          && freshLive.liveRef == finalNode.liveRef
          && freshLive.snapshotIsDetached == false
      ),
      check("scenario_is_local_only", true),
    ]
    return report(
      scenarioID: "roundtrip",
      checks: checks,
      registrationPassportSHA256: DurableForkJSON.sha256(
        registered.registrationPassportCanonicalJSON),
      handoffPassportSHA256: handoff.passportSHA256,
      parentUpdatePassportSHA256: parentUpdate.passportSHA256,
      initialForkOID: initialForkOID,
      finalForkOID: finalNode.forkOID,
      initialParentOID: initialParentOID,
      finalParentOID: finalNode.assemblyOID,
      initialUpstreamOID: initialUpstreamOID,
      finalUpstreamOID: finalNode.upstreamOID
    )
  }
}

extension DurableForkSubnodeFixtures {
  private static func preparedCandidate(
    _ environment: FixtureEnvironment
  ) throws -> (DurableForkNodeContext, DurableForkCandidateResult) {
    let registered = try registeredNode(environment)
    return (registered, try publishedCandidate(environment, node: registered))
  }

  private static func runInvalidUpstreamRemote(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let node = try registeredNode(environment)
    _ = try environment.git.data(
      ["remote", "set-url", "upstream", environment.assemblyBare.path],
      at: node.liveCloneURL
    )
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let workPackage = try FixtureContracts.workPackage(
      inputSHA256: DurableForkJSON.sha256(Data("core base\n".utf8)))
    let result = try environment.runtime.publishCandidate(
      candidateRequest(
        environment, node: node, workPackageData: workPackage,
        suffix: "invalid-upstream-remote"))
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "invalid-upstream-remote", "remote_mismatch_rejected",
      result.outcome == .remoteMismatch, before: before, after: after)
  }

  private static func runInvalidHandoffAccess(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let result = try acceptedHandoff(
      environment, candidate: candidate, accessLevel: .private,
      publicationBoundary: .public, rootName: "handoff-private")
    let unsafeMessage = try acceptedHandoff(
      environment, candidate: candidate, rootName: "handoff-unsafe-message",
      commitMessage: "Use github_pat_fixture in accepted handoff")
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "invalid-handoff-access", "publication_boundary_rejected",
      result.outcome == .publicationBoundaryRejected
        && unsafeMessage.outcome == .publicationBoundaryRejected,
      before: before, after: after)
  }

  private static func runInvalidHandoffBase(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let result = try acceptedHandoff(
      environment, candidate: candidate, expectedUpstreamOID: node.forkOID,
      rootName: "handoff-stale-base")
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "invalid-handoff-base", "handoff_base_mismatch_rejected",
      result.outcome == .oidMismatch, before: before, after: after)
  }

  private static func runInvalidSyncOID(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let handoff = try acceptedHandoff(environment, candidate: candidate)
    let node = try require(handoff.node, "Контекст передачи отсутствует.")
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let result = try synchronized(
      environment, node: node, expectedForkOID: node.upstreamOID,
      rootName: "sync-wrong-oid")
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "invalid-sync-oid", "sync_oid_mismatch_rejected",
      result.outcome == .oidMismatch, before: before, after: after)
  }

  private static func runInvalidSyncConflict(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let upstreamOID = try FixtureGit.commitChange(
      repository: node.coreBareURL, root: environment.root, name: "conflicting-core",
      ref: node.upstreamRef, expectedOID: node.upstreamOID,
      files: ["Shared/common.txt": Data("core conflicting edit\n".utf8)],
      message: "Conflicting core change", git: environment.git)
    let current = node.updating(upstreamOID: upstreamOID)
    let before = try FixturePublishedState.capture(current, git: environment.git)
    let result = try synchronized(
      environment, node: current, rootName: "sync-conflict")
    let after = try FixturePublishedState.capture(current, git: environment.git)
    return negativeReport(
      "invalid-sync-conflict", "sync_conflict_rejected_without_mutation",
      result.outcome == .conflict, before: before, after: after)
  }

  private static func runInvalidSyncAccess(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let result = try synchronized(
      environment, node: node, accessLevel: .restricted,
      publicationBoundary: .public, rootName: "sync-private")
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "invalid-sync-access", "sync_publication_boundary_rejected",
      result.outcome == .publicationBoundaryRejected, before: before, after: after)
  }

  private static func runInvalidSyncPublication(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let upstreamOID = try FixtureGit.commitChange(
      repository: node.coreBareURL, root: environment.root, name: "unsafe-core",
      ref: node.upstreamRef, expectedOID: node.upstreamOID,
      files: ["Shared/unsafe.txt": Data("-----BEGIN PRIVATE KEY-----\nfixture\n".utf8)],
      message: "Unsafe core payload", git: environment.git)
    let current = node.updating(upstreamOID: upstreamOID)
    let before = try FixturePublishedState.capture(current, git: environment.git)
    let result = try synchronized(
      environment, node: current, rootName: "sync-unsafe")
    let after = try FixturePublishedState.capture(current, git: environment.git)
    return negativeReport(
      "invalid-sync-publication", "sync_unsafe_tree_rejected",
      result.outcome == .publicationBoundaryRejected, before: before, after: after)
  }

  private static func runInvalidUpstreamGitlink(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let (_, candidate) = try preparedCandidate(environment)
    let node = try require(candidate.node, "Контекст кандидата отсутствует.")
    let upstreamOID = try FixtureGit.commitGitlink(
      repository: node.coreBareURL, root: environment.root,
      name: "upstream-gitlink", ref: node.upstreamRef,
      expectedOID: node.upstreamOID, path: "Fork/self",
      relativeURL: "../nested.git", message: "Unsafe upstream gitlink",
      git: environment.git)
    let current = node.updating(upstreamOID: upstreamOID)
    let before = try FixturePublishedState.capture(current, git: environment.git)
    let result = try synchronized(
      environment, node: current, rootName: "sync-gitlink")
    let after = try FixturePublishedState.capture(current, git: environment.git)
    return negativeReport(
      "invalid-upstream-gitlink", "sync_upstream_gitlink_rejected",
      result.outcome == .publicationBoundaryRejected, before: before, after: after)
  }

  private static func runInvalidRegistrationUpstreamGitlink(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let upstreamOID = try FixtureGit.commitGitlink(
      repository: environment.coreBare, root: environment.root,
      name: "registration-upstream-gitlink", ref: "refs/heads/main",
      expectedOID: environment.coreOID, path: "Fork/self",
      relativeURL: "../nested.git", message: "Core contains forbidden gitlink",
      git: environment.git)
    let request = registrationRequest(
      environment.registrationRequest, expectedUpstreamOID: upstreamOID)
    let assemblyBefore = try FixtureGit.refOID(
      request.assemblyRef, repository: request.assemblyBareURL, git: environment.git)
    let result = try environment.runtime.register(request)
    let assemblyAfter = try FixtureGit.refOID(
      request.assemblyRef, repository: request.assemblyBareURL, git: environment.git)
    let noCreatedRepositories =
      !FileManager.default.fileExists(atPath: request.forkBareURL.path)
      && !FileManager.default.fileExists(atPath: request.liveCloneURL.path)
      && !FileManager.default.fileExists(atPath: request.snapshotRootURL.path)
    return report(
      scenarioID: "invalid-registration-upstream-gitlink",
      checks: [
        check(
          "registration_upstream_gitlink_rejected_without_refs",
          result.outcome == .invalidComposition
            && assemblyBefore == assemblyAfter && noCreatedRepositories)
      ],
      initialParentOID: assemblyBefore, finalParentOID: assemblyAfter,
      initialUpstreamOID: environment.coreOID, finalUpstreamOID: upstreamOID,
      unexpectedRefMutation: assemblyBefore != assemblyAfter || !noCreatedRepositories)
  }

  private static func runObservedTopologyScenario(
    _ identifier: String,
    environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let selfScenario = identifier == "invalid-self-recursive-submodule"
    let expectedViolationCode =
      selfScenario
      ? "recursive_initialization_forbidden"
      : "submodule_references_ancestor"
    let targetURL = selfScenario ? "../fork.git" : "../assembly.git"
    let upstreamOID = try FixtureGit.commitGitlink(
      repository: environment.coreBare, root: environment.root,
      name: selfScenario ? "observed-self" : "observed-ancestor",
      ref: "refs/heads/main", expectedOID: environment.coreOID,
      path: selfScenario ? "Подузлы/сам" : "Предки/assembly",
      relativeURL: targetURL,
      message: selfScenario ? "Observed self gitlink" : "Observed ancestor gitlink",
      git: environment.git)
    let request = registrationRequest(
      environment.registrationRequest, expectedUpstreamOID: upstreamOID)
    let assemblyBefore = try FixtureGit.refOID(
      request.assemblyRef, repository: request.assemblyBareURL, git: environment.git)
    let result = try environment.runtime.register(request)
    let assemblyAfter = try FixtureGit.refOID(
      request.assemblyRef, repository: request.assemblyBareURL, git: environment.git)
    let noCreatedRepositories =
      !FileManager.default.fileExists(atPath: request.forkBareURL.path)
      && !FileManager.default.fileExists(atPath: request.liveCloneURL.path)
      && !FileManager.default.fileExists(atPath: request.snapshotRootURL.path)
    return report(
      scenarioID: identifier,
      checks: [
        check(
          expectedViolationCode,
          result.outcome == .invalidComposition
            && result.compositionViolations.contains { $0.code == expectedViolationCode }
            && assemblyBefore == assemblyAfter && noCreatedRepositories)
      ],
      initialParentOID: assemblyBefore, finalParentOID: assemblyAfter,
      initialUpstreamOID: environment.coreOID, finalUpstreamOID: upstreamOID,
      unexpectedRefMutation: assemblyBefore != assemblyAfter || !noCreatedRepositories)
  }

  private static func runRecursiveInitialization(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let node = try registeredNode(environment)
    let destination = environment.root.appending(
      path: "recursive-parent", directoryHint: .isDirectory)
    let before = try FixturePublishedState.capture(node, git: environment.git)
    let result = try environment.runtime.restoreParentSnapshot(
      DurableForkRestoreRequest(
        node: node, destinationURL: destination, recursiveInitialization: true))
    let after = try FixturePublishedState.capture(node, git: environment.git)
    return negativeReport(
      "recursive-init-forbidden", "recursive_initialization_rejected_before_clone",
      result.outcome == .recursiveInitializationForbidden
        && !FileManager.default.fileExists(atPath: destination.path),
      before: before, after: after)
  }

  private static func runInvalidQueueNamespace(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let request = registrationRequest(
      environment.registrationRequest,
      expectedUpstreamOID: environment.registrationRequest.expectedUpstreamOID,
      queueRefNamespace: "refs/fum/other-queues")
    let result = try environment.runtime.register(request)
    let noCreatedRepositories =
      !FileManager.default.fileExists(atPath: request.forkBareURL.path)
      && !FileManager.default.fileExists(atPath: request.liveCloneURL.path)
      && !FileManager.default.fileExists(atPath: request.snapshotRootURL.path)
    return report(
      scenarioID: "invalid-queue-namespace",
      checks: [
        check(
          "queue_outside_service_namespace_rejected",
          result.outcome == .invalidRequest && noCreatedRepositories)
      ],
      initialParentOID: environment.assemblyOID,
      finalParentOID: try FixtureGit.refOID(
        request.assemblyRef, repository: request.assemblyBareURL, git: environment.git),
      unexpectedRefMutation: !noCreatedRepositories)
  }

  private static func runInvalidParentUpdate(
    _ environment: FixtureEnvironment
  ) throws -> DurableForkScenarioReport {
    let node = try registeredNode(environment)
    let parentBefore = try FixtureGit.refOID(
      node.assemblyRef, repository: node.assemblyBareURL, git: environment.git)
    let unsafeMessage = try environment.runtime.updateParentGitlink(
      DurableForkParentUpdateRequest(
        node: node, updateID: "parent-message.fixture",
        updateRootURL: environment.root.appending(
          path: "parent-message", directoryHint: .isDirectory),
        snapshotRootURL: environment.root.appending(
          path: "parent-message-snapshot", directoryHint: .isDirectory),
        expectedParentOID: node.assemblyOID,
        expectedPreviousGitlinkOID: node.gitlinkOID,
        gitlinkOID: node.forkOID,
        commitMessage: "Use github_pat_fixture in parent result"))
    let maliciousOID = try FixtureGit.commitGitlink(
      repository: node.forkBareURL, root: environment.root,
      name: "parent-invalid-composition", ref: node.liveRef,
      expectedOID: node.forkOID, path: "Подузлы/сам",
      relativeURL: "../fork.git", message: "Add observed self gitlink",
      git: environment.git)
    _ = try environment.git.data(
      ["fetch", "--quiet", "--no-tags", "origin", node.liveRef], at: node.liveCloneURL)
    let liveUpdate = Data(
      "start\nupdate \(node.liveRef) \(maliciousOID) \(node.forkOID)\nprepare\ncommit\n".utf8)
    _ = try environment.git.data(
      ["update-ref", "--stdin"], at: node.liveCloneURL, input: liveUpdate)
    _ = try environment.git.data(
      ["reset", "--hard", "--quiet", maliciousOID], at: node.liveCloneURL)
    let maliciousNode = node.updating(forkOID: maliciousOID)
    let rejectedSnapshot = environment.root.appending(
      path: "parent-invalid-snapshot", directoryHint: .isDirectory)
    let invalidComposition = try environment.runtime.updateParentGitlink(
      DurableForkParentUpdateRequest(
        node: maliciousNode, updateID: "parent-composition.fixture",
        updateRootURL: environment.root.appending(
          path: "parent-invalid-update", directoryHint: .isDirectory),
        snapshotRootURL: rejectedSnapshot,
        expectedParentOID: maliciousNode.assemblyOID,
        expectedPreviousGitlinkOID: maliciousNode.gitlinkOID,
        gitlinkOID: maliciousNode.forkOID,
        commitMessage: "Attempt invalid parent composition"))
    let parentAfter = try FixtureGit.refOID(
      node.assemblyRef, repository: node.assemblyBareURL, git: environment.git)
    let proofRefs = try environment.git.text(
      ["for-each-ref", "--format=%(refname)", "refs/heads/fum-proof/"],
      at: node.assemblyBareURL)
    let passed =
      unsafeMessage.outcome == .publicationBoundaryRejected
      && invalidComposition.outcome == .invalidComposition
      && parentAfter == parentBefore && proofRefs.isEmpty
      && !FileManager.default.fileExists(atPath: rejectedSnapshot.path)
    return report(
      scenarioID: "invalid-parent-update",
      checks: [
        check(
          "parent_update_preflight_and_publication_rejected_without_refs", passed)
      ],
      initialForkOID: node.forkOID, finalForkOID: maliciousOID,
      initialParentOID: parentBefore, finalParentOID: parentAfter,
      initialUpstreamOID: node.upstreamOID, finalUpstreamOID: node.upstreamOID,
      unexpectedRefMutation: parentAfter != parentBefore || !proofRefs.isEmpty)
  }

  private static func candidateRequest(
    _ environment: FixtureEnvironment,
    node: DurableForkNodeContext,
    workPackageData: Data,
    suffix: String
  ) -> DurableForkCandidateRequest {
    DurableForkCandidateRequest(
      node: node, workPackageData: workPackageData,
      executionRootURL: environment.root.appending(
        path: "candidate-execution-\(suffix)", directoryHint: .isDirectory),
      integrationRootURL: environment.root.appending(
        path: "candidate-integration-\(suffix)", directoryHint: .isDirectory),
      episodeID: "episode.\(suffix)", stepGenerationID: "generation.\(suffix)",
      cardID: "FUM-STEP-9001", stepID: "node-specialized-step-0001-automatic-v1",
      runID: "run.\(suffix)", attemptID: "attempt.\(suffix)",
      ownerID: "owner.\(suffix)", commitMessage: "Candidate \(suffix)",
      integrationCommitMessage: "Integrate \(suffix)",
      writes: [WritingSubnodeWrite(path: "Shared/common.txt", contents: environment.improvedData)],
      checkIDs: ["common-content"])
  }

  private static func registrationRequest(
    _ request: DurableForkRegistrationRequest,
    expectedUpstreamOID: String,
    queueRefNamespace: String? = nil
  ) -> DurableForkRegistrationRequest {
    DurableForkRegistrationRequest(
      nodeID: request.nodeID, forkRepositoryID: request.forkRepositoryID,
      upstreamRepositoryID: request.upstreamRepositoryID,
      assemblyRepositoryID: request.assemblyRepositoryID,
      coreBareURL: request.coreBareURL, forkBareURL: request.forkBareURL,
      assemblyBareURL: request.assemblyBareURL, liveCloneURL: request.liveCloneURL,
      runtimeRootURL: request.runtimeRootURL, snapshotRootURL: request.snapshotRootURL,
      upstreamRef: request.upstreamRef, liveRef: request.liveRef,
      assemblyRef: request.assemblyRef, expectedUpstreamOID: expectedUpstreamOID,
      expectedAssemblyOID: request.expectedAssemblyOID,
      submodulePath: request.submodulePath, submoduleURL: request.submoduleURL,
      rulesPath: request.rulesPath, rulesData: request.rulesData,
      queueRefNamespace: queueRefNamespace ?? request.queueRefNamespace,
      queueBootstrapScriptPath: request.queueBootstrapScriptPath,
      queueBootstrapScriptSHA256: request.queueBootstrapScriptSHA256,
      nextStepValidatorPath: request.nextStepValidatorPath,
      nextStepValidatorSHA256: request.nextStepValidatorSHA256,
      nextStepRecordPath: request.nextStepRecordPath,
      projectPath: request.projectPath,
      nextStepCardPath: request.nextStepCardPath,
      nextStepCardID: request.nextStepCardID, nextStepID: request.nextStepID,
      nextStepCardData: request.nextStepCardData, accessLevel: request.accessLevel,
      publicationBoundary: request.publicationBoundary)
  }
}

private struct FixturePublishedState: Equatable {
  let coreOID: String
  let forkOID: String
  let assemblyOID: String
  let liveHeadOID: String
  let liveSymbolicRef: String
  let liveStatus: String

  static func capture(
    _ node: DurableForkNodeContext,
    git: CandidateIntegrationGit
  ) throws -> FixturePublishedState {
    FixturePublishedState(
      coreOID: try FixtureGit.refOID(
        node.upstreamRef, repository: node.coreBareURL, git: git),
      forkOID: try FixtureGit.refOID(
        node.liveRef, repository: node.forkBareURL, git: git),
      assemblyOID: try FixtureGit.refOID(
        node.assemblyRef, repository: node.assemblyBareURL, git: git),
      liveHeadOID: try git.text(["rev-parse", "HEAD^{commit}"], at: node.liveCloneURL),
      liveSymbolicRef: try git.text(["symbolic-ref", "-q", "HEAD"], at: node.liveCloneURL),
      liveStatus: try git.text(
        ["status", "--porcelain=v1", "--untracked-files=all"], at: node.liveCloneURL))
  }
}

extension DurableForkSubnodeFixtures {
  private static func check(_ identifier: String, _ passed: @autoclosure () throws -> Bool)
    rethrows -> DurableForkScenarioCheck
  {
    DurableForkScenarioCheck(identifier: identifier, passed: try passed())
  }

  private static func require<Value>(_ value: Value?, _ message: String) throws -> Value {
    guard let value else { throw DurableForkSubnodeFixtureError.setupFailed(message) }
    return value
  }

  private static func negativeReport(
    _ scenarioID: String,
    _ checkID: String,
    _ outcomePassed: Bool,
    before: FixturePublishedState,
    after: FixturePublishedState
  ) -> DurableForkScenarioReport {
    report(
      scenarioID: scenarioID,
      checks: [
        DurableForkScenarioCheck(
          identifier: checkID, passed: outcomePassed && before == after)
      ],
      initialForkOID: before.forkOID, finalForkOID: after.forkOID,
      initialParentOID: before.assemblyOID, finalParentOID: after.assemblyOID,
      initialUpstreamOID: before.coreOID, finalUpstreamOID: after.coreOID,
      unexpectedRefMutation: before != after)
  }

  private static func report(
    scenarioID: String,
    checks: [DurableForkScenarioCheck],
    registrationPassportSHA256: String? = nil,
    handoffPassportSHA256: String? = nil,
    parentUpdatePassportSHA256: String? = nil,
    initialForkOID: String? = nil,
    finalForkOID: String? = nil,
    initialParentOID: String? = nil,
    finalParentOID: String? = nil,
    initialUpstreamOID: String? = nil,
    finalUpstreamOID: String? = nil,
    unexpectedRefMutation: Bool = false
  ) -> DurableForkScenarioReport {
    DurableForkScenarioReport(
      schemaIdentity: "fum.durable-fork-subnode.scenario-report",
      schemaVersion: 1, scenarioID: scenarioID,
      decision: checks.allSatisfy(\.passed) && !unexpectedRefMutation ? .passed : .failed,
      repositoryIdentities: [
        "urn:fum:repository:assembly-fixture",
        "urn:fum:repository:core-fixture",
        "urn:fum:repository:specialized-fork-fixture",
      ],
      checks: checks.sorted { $0.identifier < $1.identifier },
      registrationPassportSHA256: registrationPassportSHA256,
      handoffPassportSHA256: handoffPassportSHA256,
      parentUpdatePassportSHA256: parentUpdatePassportSHA256,
      initialForkOID: initialForkOID, finalForkOID: finalForkOID,
      initialParentOID: initialParentOID, finalParentOID: finalParentOID,
      initialUpstreamOID: initialUpstreamOID, finalUpstreamOID: finalUpstreamOID,
      unexpectedRefMutation: unexpectedRefMutation)
  }
}

private enum FixtureContracts {
  static func workPackage(inputSHA256: String) throws -> Data {
    let object: [String: Any] = [
      "schema_version": 1,
      "package_id": "fum.durable-fork-fixture.work-package.v1",
      "goal": "Проверить ограниченное общее улучшение в изолированном пишущем клоне.",
      "deliverables": [
        [
          "id": "common", "role": "primary",
          "description": "Обновлённый общий файл.", "depends_on": [],
        ]
      ],
      "inputs": [
        [
          "id": "common-input", "path": "Shared/common.txt",
          "sha256": inputSHA256, "required": true,
        ]
      ],
      "change_scope": [
        "policy": "listed_paths_only",
        "allowed_paths": ["Shared/common.txt"],
        "excluded_paths": ["runtime", ".gitmodules"],
      ],
      "dependencies": [
        [
          "id": "local-git", "status": "resolved",
          "evidence": "Автономный стенд использует только локальный Git.",
        ]
      ],
      "checks": [
        [
          "id": "common-content",
          "description": "Содержимое общего файла совпадает с ожидаемым SHA-256.",
        ]
      ],
      "handoff": [
        "format": "canonical_json_v1", "required_artifacts": ["Shared/common.txt"],
      ],
      "budget": [
        "unit": "planning_units", "limit": 100, "reading": 20,
        "work": 35, "verification": 20, "response": 10, "reserve": 15,
      ],
      "preflight": ["before_model_call": true, "before_user_data_mutation": true],
    ]
    return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }
}

private enum FixtureGit {
  static func normalizeCheckout(
    _ checkout: URL,
    git: CandidateIntegrationGit
  ) throws {
    _ = try git.data(["config", "core.logAllRefUpdates", "false"], at: checkout)
    let gitDirectory = URL(
      fileURLWithPath: try git.text(["rev-parse", "--absolute-git-dir"], at: checkout),
      isDirectory: true)
    let logs = gitDirectory.appending(path: "logs", directoryHint: .isDirectory)
    if FileManager.default.fileExists(atPath: logs.path) {
      try FileManager.default.removeItem(at: logs)
    }
    let index = gitDirectory.appending(path: "index")
    if FileManager.default.fileExists(atPath: index.path) {
      try FileManager.default.removeItem(at: index)
    }
    _ = try git.data(["read-tree", "HEAD"], at: checkout)
  }

  static func seedBare(
    at repository: URL,
    root: URL,
    name: String,
    files: [String: Data],
    message: String,
    git: CandidateIntegrationGit
  ) throws -> String {
    _ = try git.data(
      ["init", "--quiet", "--bare", "--initial-branch=main", "--", repository.path],
      at: root)
    let clone = root.appending(path: name, directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        repository.path, clone.path,
      ], at: root)
    for (path, contents) in files.sorted(by: { $0.key < $1.key }) {
      try WritingSubnodePersistence.materialize(
        WritingSubnodeWrite(path: path, contents: contents), cloneURL: clone)
      _ = try git.data(["add", "--", path], at: clone)
    }
    let treeOID = try git.text(["write-tree"], at: clone)
    let oid = try git.text(
      ["commit-tree", treeOID], at: clone, input: Data((message + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment)
    _ = try git.data(
      ["push", "--porcelain", "origin", "\(oid):refs/heads/main"], at: clone)
    return oid
  }

  static func refOID(
    _ ref: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> String {
    try git.text(["rev-parse", "--verify", "\(ref)^{commit}"], at: repository)
  }

  static func parents(
    _ oid: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> [String] {
    let fields = try git.text(["rev-list", "--parents", "-n", "1", oid], at: repository)
      .split(separator: " ").map(String.init)
    return Array(fields.dropFirst())
  }

  static func gitlink(
    parentOID: String,
    path: String,
    repository: URL,
    git: CandidateIntegrationGit
  ) throws -> String {
    let line = try git.text(["ls-tree", parentOID, "--", path], at: repository)
    let fields = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
    guard fields.count >= 3, fields[0] == "160000" else {
      throw DurableForkSubnodeFixtureError.setupFailed("Точный gitlink не найден.")
    }
    return String(fields[2])
  }

  static func commitChange(
    repository: URL,
    root: URL,
    name: String,
    ref: String,
    expectedOID: String,
    files: [String: Data],
    message: String,
    git: CandidateIntegrationGit
  ) throws -> String {
    let clone = root.appending(path: name, directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        repository.path, clone.path,
      ], at: root)
    _ = try git.data(["checkout", "--quiet", "--detach", expectedOID, "--"], at: clone)
    for (path, contents) in files.sorted(by: { $0.key < $1.key }) {
      try WritingSubnodePersistence.materialize(
        WritingSubnodeWrite(path: path, contents: contents), cloneURL: clone)
      _ = try git.data(["add", "--", path], at: clone)
    }
    let treeOID = try git.text(["write-tree"], at: clone)
    let oid = try git.text(
      ["commit-tree", treeOID, "-p", expectedOID], at: clone,
      input: Data((message + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment)
    guard
      try DurableForkValidation.pushCAS(
        newOID: oid, expectedOID: expectedOID, ref: ref, clone: clone, git: git)
    else { throw DurableForkSubnodeFixtureError.setupFailed("Тестовый CAS проигран.") }
    return oid
  }

  static func commitGitlink(
    repository: URL,
    root: URL,
    name: String,
    ref: String,
    expectedOID: String,
    path: String,
    relativeURL: String,
    message: String,
    git: CandidateIntegrationGit
  ) throws -> String {
    let child = root.appending(path: "\(name)-child.git", directoryHint: .isDirectory)
    let childOID = try seedBare(
      at: child, root: root, name: "\(name)-child-seed",
      files: ["README.md": Data("nested fixture\n".utf8)],
      message: "Nested fixture", git: git)
    let clone = root.appending(path: "\(name)-writer", directoryHint: .isDirectory)
    _ = try git.data(
      [
        "clone", "--quiet", "--no-local", "--no-hardlinks", "--no-checkout", "--",
        repository.path, clone.path,
      ], at: root)
    _ = try git.data(["checkout", "--quiet", "--detach", expectedOID, "--"], at: clone)
    let modules = """
      [submodule "nested"]
      \tpath = \(path)
      \turl = \(relativeURL)
      """ + "\n"
    try WritingSubnodePersistence.materialize(
      WritingSubnodeWrite(path: ".gitmodules", contents: Data(modules.utf8)),
      cloneURL: clone)
    _ = try git.data(["add", "--", ".gitmodules"], at: clone)
    _ = try git.data(
      ["update-index", "--add", "--cacheinfo", "160000,\(childOID),\(path)"], at: clone)
    let treeOID = try git.text(["write-tree"], at: clone)
    let oid = try git.text(
      ["commit-tree", treeOID, "-p", expectedOID], at: clone,
      input: Data((message + "\n").utf8),
      additionalEnvironment: DurableForkValidation.commitEnvironment)
    guard
      try DurableForkValidation.pushCAS(
        newOID: oid, expectedOID: expectedOID, ref: ref, clone: clone, git: git)
    else { throw DurableForkSubnodeFixtureError.setupFailed("Тестовый CAS gitlink проигран.") }
    return oid
  }
}
