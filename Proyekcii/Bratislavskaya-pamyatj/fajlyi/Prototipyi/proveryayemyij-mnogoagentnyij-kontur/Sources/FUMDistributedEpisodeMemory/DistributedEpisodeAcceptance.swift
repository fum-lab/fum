import FUMVerifiableMultiAgentContour
import Foundation

public struct DistributedEpisodeAcceptanceScenario:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let scenarioID: String
  public let status: String
  public let terminalOutcome: String?
  public let canonicalOutcomesEqual: Bool?
  public let processCount: Int?
  public let acceptedResult: Bool?
  public let correlatedAnswerCount: Int?
  public let independentConfirmationCount: Int?
  public let remainingBudget: SharedEpisodeBudgetVector?
  public let reasonCode: String?
  public let unconfirmedResultPublished: Bool?
  public let transitionPhase: String?
  public let episodeState: String?
  public let modelBranchCount: Int?
  public let userConfirmed: Bool?
  public let internallySelected: Bool?
  public let checks: [String]

  enum CodingKeys: String, CodingKey {
    case scenarioID = "scenario_id"
    case status
    case terminalOutcome = "terminal_outcome"
    case canonicalOutcomesEqual = "canonical_outcomes_equal"
    case processCount = "process_count"
    case acceptedResult = "accepted_result"
    case correlatedAnswerCount = "correlated_answer_count"
    case independentConfirmationCount = "independent_confirmation_count"
    case remainingBudget = "remaining_budget"
    case reasonCode = "reason_code"
    case unconfirmedResultPublished = "unconfirmed_result_published"
    case transitionPhase = "transition_phase"
    case episodeState = "episode_state"
    case modelBranchCount = "model_branch_count"
    case userConfirmed = "user_confirmed"
    case internallySelected = "internally_selected"
    case checks
  }
}

public struct DistributedEpisodeAcceptanceReport:
  SharedEpisodeCanonicalValue, Equatable, Sendable
{
  public let schemaVersion: Int
  public let status: String
  public let fixtureOnly: Bool
  public let liveMultiModelReady: Bool
  public let liveModelUsed: Bool
  public let liveToolUsed: Bool
  public let networkUsed: Bool
  public let scenarios: [DistributedEpisodeAcceptanceScenario]

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case status
    case fixtureOnly = "fixture_only"
    case liveMultiModelReady = "live_multi_model_ready"
    case liveModelUsed = "live_model_used"
    case liveToolUsed = "live_tool_used"
    case networkUsed = "network_used"
    case scenarios
  }
}

public enum DistributedEpisodeAcceptanceError:
  Error, CustomStringConvertible, Sendable
{
  case failed(String)

  public var description: String {
    switch self {
    case .failed(let message):
      "Автономная приёмка отклонена: \(message)"
    }
  }
}

public enum DistributedEpisodeAcceptance {
  public static let scenarioIdentifiers = [
    "positive_goal_met",
    "false_consensus",
    "budget_exhaustion",
    "pending_confirmation",
  ]

  private static let restartBoundaryIndex = 2

  public static func runAll(
    repositoryRoot: URL,
    probeExecutable: URL
  ) throws -> DistributedEpisodeAcceptanceReport {
    try require(
      FileManager.default.fileExists(atPath: repositoryRoot.path),
      "корень репозитория не существует"
    )

    let temporaryRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent(
        "fum-distributed-episode-acceptance-\(UUID().uuidString)",
        isDirectory: true
      )
    let continuousRoot = temporaryRoot.appendingPathComponent(
      "continuous",
      isDirectory: true
    )
    let resumedRoot = temporaryRoot.appendingPathComponent(
      "resumed",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: temporaryRoot,
      withIntermediateDirectories: false
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    try runProbeStage(
      "continuous",
      storeRoot: continuousRoot,
      repositoryRoot: repositoryRoot,
      probeExecutable: probeExecutable
    )
    try runProbeStage(
      "prepare-resumption",
      storeRoot: resumedRoot,
      repositoryRoot: repositoryRoot,
      probeExecutable: probeExecutable
    )
    try runProbeStage(
      "inspect-resumption",
      storeRoot: resumedRoot,
      repositoryRoot: repositoryRoot,
      probeExecutable: probeExecutable
    )
    try runProbeStage(
      "resume",
      storeRoot: resumedRoot,
      repositoryRoot: repositoryRoot,
      probeExecutable: probeExecutable
    )

    guard
      let continuous = try SharedEpisodeMemoryStore(rootURL: continuousRoot).loadCurrent(),
      let resumed = try SharedEpisodeMemoryStore(rootURL: resumedRoot).loadCurrent()
    else {
      throw DistributedEpisodeAcceptanceError.failed(
        "процессы не опубликовали оба терминальных CURRENT"
      )
    }
    let continuousBytes = try continuous.generation.canonicalJSONData()
    let resumedBytes = try resumed.generation.canonicalJSONData()
    try require(
      continuous.generationSHA256 == resumed.generationSHA256
        && continuousBytes == resumedBytes,
      "непрерывный и возобновлённый прогоны дали разные канонические поколения"
    )

    let positive = try positiveScenario(
      continuous.generation,
      canonicalOutcomesEqual: true,
      processCount: 4
    )
    let falseConsensus = try falseConsensusScenario()
    let budgetExhaustion = try budgetExhaustionScenario()
    let pendingConfirmation = try pendingConfirmationScenario(
      repositoryRoot: repositoryRoot
    )

    return DistributedEpisodeAcceptanceReport(
      schemaVersion: 1,
      status: "passed",
      fixtureOnly: true,
      liveMultiModelReady: false,
      liveModelUsed: false,
      liveToolUsed: false,
      networkUsed: false,
      scenarios: [
        positive,
        falseConsensus,
        budgetExhaustion,
        pendingConfirmation,
      ]
    )
  }

  public static func runStage(
    named stage: String,
    storeRoot: URL
  ) throws {
    let trace = try positiveTrace()
    let store = SharedEpisodeMemoryStore(rootURL: storeRoot)

    switch stage {
    case "continuous":
      try require(
        try store.loadCurrent() == nil,
        "непрерывный прогон получил непустой CURRENT"
      )
      for generation in trace {
        _ = try store.commit(generation)
      }

    case "prepare-resumption":
      try require(
        try store.loadCurrent() == nil,
        "подготовка возобновления получила непустой CURRENT"
      )
      for generation in trace.prefix(restartBoundaryIndex + 1) {
        _ = try store.commit(generation)
      }

    case "inspect-resumption":
      guard let current = try store.loadCurrent() else {
        throw DistributedEpisodeAcceptanceError.failed(
          "новый процесс не восстановил подтверждённый CURRENT"
        )
      }
      try require(
        current.generationSHA256
          == SharedEpisodeControlFixtures.generationSHA256(
            trace[restartBoundaryIndex]
          ),
        "новый процесс восстановил не то подтверждённое поколение"
      )
      try require(
        current.generation.state.contributions.map(\.contributionID)
          == ["contribution.primary"],
        "до возобновления восстановлен неподтверждённый второй вклад"
      )

    case "resume":
      guard let current = try store.loadCurrent() else {
        throw DistributedEpisodeAcceptanceError.failed(
          "возобновление не нашло подтверждённый CURRENT"
        )
      }
      try require(
        try current.generation.canonicalJSONData()
          == trace[restartBoundaryIndex].canonicalJSONData(),
        "возобновление стартует не с канонической границы"
      )
      for generation in trace.dropFirst(restartBoundaryIndex + 1) {
        _ = try store.commit(generation)
      }

    default:
      throw DistributedEpisodeAcceptanceError.failed(
        "неизвестная внутренняя стадия \(stage)"
      )
    }
  }

  private static func positiveTrace() throws -> [SharedEpisodeGeneration] {
    let plan = try SharedEpisodeControlFixtures.selectionFixtureControlPlan()
    var generations = try SharedEpisodeControlFixtures.selectionPrefixTrace(
      controlPlan: plan,
      correlatedCopyCount: 0,
      includeFailedVerification: false,
      includeAdversarialContribution: true
    )
    guard let verified = generations.last else {
      throw DistributedEpisodeAcceptanceError.failed(
        "положительная трасса не создала проверенное поколение"
      )
    }
    let selection = try SharedEpisodeControlFixtures.selectionSteps(
      named: .externalEvidence,
      from: verified
    )
    generations.append(contentsOf: selection)
    guard let selected = generations.last else {
      throw DistributedEpisodeAcceptanceError.failed(
        "положительная трасса не сохранила выбор"
      )
    }
    let prepared = try SharedEpisodeControlFixtures.prepareTerminal(
      from: selected,
      suffix: "acceptance.goal-met",
      outcome: .goalMet
    ) { _, reservedGeneration in
      SharedEpisodeTerminalReason(
        code: .goalCriteriaMet,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: reservedGeneration.state.selectionDecisions
          .compactMap(\.selectedContributionID)
          .sorted()
      )
    }
    generations.append(prepared.generation)
    generations.append(
      try SharedEpisodeControlFixtures.applyPreparedTerminal(prepared)
    )
    return generations
  }

  private static func positiveScenario(
    _ generation: SharedEpisodeGeneration,
    canonicalOutcomesEqual: Bool,
    processCount: Int
  ) throws -> DistributedEpisodeAcceptanceScenario {
    let state = generation.state
    try require(
      state.terminal?.outcome == .goalMet,
      "положительная трасса не завершилась goal_met"
    )
    try require(
      state.contributions.count == 2,
      "положительная трасса должна содержать ровно два вклада"
    )
    let executors = Set(state.contributions.map { $0.provenance.executorID })
    let roles = Set(state.contributions.map { $0.provenance.roleID })
    let packages = Set(state.contributions.map { $0.origin.workPackageArtifactID })
    let manifests = Set(state.contributions.map { $0.origin.inputManifestArtifactID })
    let hypotheses = Set(state.contributions.flatMap { $0.origin.hypothesisIDs })
    try require(
      executors.count == 2 && roles.count == 2 && packages.count == 2
        && manifests.count == 2 && hypotheses.count == 2,
      "два производителя не различены пакетом, манифестом, ролью и гипотезой"
    )
    try require(
      state.contributions.flatMap {
        $0.provenance.instrumentObservations
      }.count == 1,
      "положительная трасса не сохранила единственное инструментальное наблюдение"
    )
    try require(
      state.verificationReport.externalPassedCount == 1
        && state.verifications.count == 1,
      "отдельный проверяющий не подтвердил утверждение внешним свидетельством"
    )
    let verifierExecutors = Set(state.verifications.map { $0.provenance.executorID })
    try require(
      executors.isDisjoint(with: verifierExecutors),
      "производитель ошибочно выступил отдельным проверяющим"
    )
    try require(
      state.selectionDecisions.count == 1
        && state.selectionDecisions[0].selectedContributionID != nil
        && state.selectionDecisions[0].basis == .verifiedEvidence,
      "селектор не сохранил выбор по проверенному доказательству"
    )
    try require(
      state.openReservations.isEmpty,
      "после goal_met осталась открытая резервация"
    )
    try validatePositiveInputs(generation.seed)

    return DistributedEpisodeAcceptanceScenario(
      scenarioID: "positive_goal_met",
      status: "passed",
      terminalOutcome: state.terminal?.outcome.rawValue,
      canonicalOutcomesEqual: canonicalOutcomesEqual,
      processCount: processCount,
      acceptedResult: true,
      correlatedAnswerCount: nil,
      independentConfirmationCount: state.provenanceReport.independentConfirmationCount,
      remainingBudget: state.budgetState.remaining,
      reasonCode: state.terminal?.reason.code.rawValue,
      unconfirmedResultPublished: false,
      transitionPhase: nil,
      episodeState: nil,
      modelBranchCount: nil,
      userConfirmed: nil,
      internallySelected: true,
      checks: [
        "passport_valid",
        "two_context_fit_work_packages",
        "two_distinct_producers",
        "instrument_observation_recorded",
        "external_verifier_passed",
        "verified_selection_recorded",
        "confirmed_restart_byte_equal",
        "terminal_goal_met",
      ]
    )
  }

  private static func validatePositiveInputs(
    _ seed: SharedEpisodeMemorySeed
  ) throws {
    guard
      let passport = seed.artifacts.first(where: { $0.kind == "episode_passport" })
    else {
      throw DistributedEpisodeAcceptanceError.failed(
        "seed не содержит закреплённый паспорт"
      )
    }
    let passportReport = EpisodePassportPreflight.analyze(
      try passport.decodedData()
    )
    switch passportReport.decision {
    case .valid:
      break
    case .invalid:
      throw DistributedEpisodeAcceptanceError.failed(
        "закреплённый паспорт не прошёл preflight"
      )
    }

    let packages = seed.artifacts.filter { $0.kind == "work_package" }
      .sorted { $0.artifactID < $1.artifactID }
    try require(packages.count == 2, "seed не содержит два рабочих пакета")
    try require(
      Set(packages.map(\.contentSHA256)).count == 2,
      "рабочие пакеты не различаются побайтовым содержимым"
    )
    let workspaceRoot = try WorkPackageFixtures.workspaceRoot()
    for package in packages {
      let report = WorkPackagePreflight.analyze(
        try package.decodedData(),
        workspaceRoot: workspaceRoot
      )
      switch report.decision {
      case .ready:
        break
      case .splitRequired:
        throw DistributedEpisodeAcceptanceError.failed(
          "рабочий пакет \(package.artifactID) не прошёл preflight"
        )
      }
    }
  }

  private static func falseConsensusScenario()
    throws -> DistributedEpisodeAcceptanceScenario
  {
    let exactCheckBudget =
      try SharedEpisodeControlFixtures
      .meteredVerificationBudget(named: .inconclusive)
    let maximum = SharedEpisodeControlFixtures.roomyMaximumBudget
    let unaffordableCheckBudget =
      SharedEpisodeControlFixtures
      .replacingBudgetComponent(
        in: exactCheckBudget,
        dimension: .output,
        with: maximum.output
      )
    let plan = SharedEpisodeControlFixtures.controlPlan(
      maximum: maximum,
      verificationReserve: SharedEpisodeControlFixtures.roomyVerificationReserve,
      handoffReserve: SharedEpisodeControlFixtures.roomyHandoffReserve,
      continuations:
        try SharedEpisodeControlFixtures
        .selectionFixtureContinuations(includeModelOnly: false),
      distinguishingChecks: [
        SharedEpisodeDistinguishingCheck(
          checkID: "check.acceptance.false-consensus",
          safe: true,
          productive: true,
          budget: unaffordableCheckBudget
        )
      ]
    )
    var trace = try SharedEpisodeControlFixtures.selectionPrefixTrace(
      controlPlan: plan,
      correlatedCopyCount: 1,
      includeFailedVerification: true,
      includeExternalVerification: false
    )
    guard let checked = trace.last else {
      throw DistributedEpisodeAcceptanceError.failed(
        "ложный консенсус не создал проверяемую трассу"
      )
    }
    let prepared = try SharedEpisodeControlFixtures.prepareTerminal(
      from: checked,
      suffix: "acceptance.false-consensus",
      outcome: .unresolvedConflict
    ) { _, reservedGeneration in
      SharedEpisodeTerminalReason(
        code: .noDistinguishingCheck,
        budgetDimension: nil,
        blockedReservation: nil,
        pendingTransitionID: nil,
        failureCode: nil,
        relatedIDs: reservedGeneration.state.unresolvedDisagreementIDs
      )
    }
    trace.append(prepared.generation)
    trace.append(try SharedEpisodeControlFixtures.applyPreparedTerminal(prepared))
    guard let final = trace.last else {
      throw DistributedEpisodeAcceptanceError.failed(
        "ложный консенсус не создал терминальное поколение"
      )
    }
    let state = final.state
    let largestEqualAnswerGroup =
      Dictionary(
        grouping: state.contributions,
        by: \.contentSHA256
      ).values.map(\.count).max() ?? 0
    try require(
      state.terminal?.outcome == .unresolvedConflict
        && state.terminal?.reason.code == .noDistinguishingCheck,
      "ложный консенсус не остановлен как unresolved_conflict"
    )
    try require(
      largestEqualAnswerGroup == 2
        && state.contributions.count == 2
        && state.provenanceReport.independentConfirmationCount == 1,
      "фикстура не сохранила два одинаковых коррелированных ответа"
    )
    try require(
      state.verificationReport.externalPassedCount == 0
        && state.selectionDecisions.isEmpty,
      "неподтверждённый ложный консенсус был принят"
    )

    return DistributedEpisodeAcceptanceScenario(
      scenarioID: "false_consensus",
      status: "passed",
      terminalOutcome: state.terminal?.outcome.rawValue,
      canonicalOutcomesEqual: nil,
      processCount: nil,
      acceptedResult: false,
      correlatedAnswerCount: largestEqualAnswerGroup,
      independentConfirmationCount: state.provenanceReport.independentConfirmationCount,
      remainingBudget: state.budgetState.remaining,
      reasonCode: state.terminal?.reason.code.rawValue,
      unconfirmedResultPublished: false,
      transitionPhase: nil,
      episodeState: nil,
      modelBranchCount: nil,
      userConfirmed: nil,
      internallySelected: false,
      checks: [
        "two_equal_answers_retained",
        "correlation_not_independence",
        "failed_check_retained",
        "no_selection_published",
        "terminal_unresolved_conflict",
      ]
    )
  }

  private static func budgetExhaustionScenario()
    throws -> DistributedEpisodeAcceptanceScenario
  {
    let boundary = try SharedEpisodeControlFixtures.budgetBoundary(
      dimension: .modelCalls,
      overBy: 1
    )
    var reservationRejected = false
    do {
      _ = try SharedEpisodeMemoryReducer.continuation(
        from: boundary.generation,
        control: .actionReserved(boundary.reservation)
      )
    } catch {
      reservationRejected = true
    }
    try require(
      reservationRejected,
      "действие сверх бюджета не было отклонено до записи события"
    )
    let final = try SharedEpisodeControlFixtures.appendBudgetExhaustedTerminal(
      blockedReservation: boundary.reservation,
      to: boundary.generation
    )
    let state = final.state
    try require(
      state.terminal?.outcome == .budgetExhausted
        && state.terminal?.reason.code == .budgetLimitReached,
      "исчерпание бюджета не сохранило точную терминальную причину"
    )
    try require(
      state.contributions.isEmpty && state.selectionDecisions.isEmpty,
      "после бюджетного отказа опубликован неподтверждённый результат"
    )

    return DistributedEpisodeAcceptanceScenario(
      scenarioID: "budget_exhaustion",
      status: "passed",
      terminalOutcome: state.terminal?.outcome.rawValue,
      canonicalOutcomesEqual: nil,
      processCount: nil,
      acceptedResult: false,
      correlatedAnswerCount: nil,
      independentConfirmationCount: nil,
      remainingBudget: state.budgetState.remaining,
      reasonCode: state.terminal?.reason.code.rawValue,
      unconfirmedResultPublished: false,
      transitionPhase: nil,
      episodeState: nil,
      modelBranchCount: nil,
      userConfirmed: nil,
      internallySelected: false,
      checks: [
        "prospective_action_rejected",
        "remaining_budget_preserved",
        "budget_reason_preserved",
        "unconfirmed_result_not_published",
        "terminal_budget_exhausted",
      ]
    )
  }

  private static func pendingConfirmationScenario(
    repositoryRoot: URL
  ) throws -> DistributedEpisodeAcceptanceScenario {
    let schema = repositoryRoot.appendingPathComponent(
      "Документация/37-минимальный-формат-трассы-исполняемого-агентского-цикла/схема-события-v3.json"
    )
    let trace = repositoryRoot.appendingPathComponent(
      "Документация/37-минимальный-формат-трассы-исполняемого-агентского-цикла/фикстура-неблокирующего-модельного-ветвления-v3.jsonl"
    )
    let validator = repositoryRoot.appendingPathComponent(
      "Инструменты/fum-proverka-trassyi-agentskogo-cikla/scripts/proveritj-trassu-agentskogo-cikla.py"
    )
    for required in [schema, trace, validator] {
      try require(
        FileManager.default.fileExists(atPath: required.path),
        "не найден локальный материал ожидания подтверждения"
      )
    }

    let traceLines = String(decoding: try Data(contentsOf: trace), as: UTF8.self)
      .split(whereSeparator: \.isNewline)
    let traceEvents: [[String: Any]] = try traceLines.map { line in
      guard
        let event = try JSONSerialization.jsonObject(with: Data(line.utf8))
          as? [String: Any]
      else {
        throw DistributedEpisodeAcceptanceError.failed(
          "трасса ожидания подтверждения содержит не-объект"
        )
      }
      return event
    }
    let pendingTransitions = traceEvents.filter {
      $0["kind"] as? String == "pending_transition"
    }
    try require(
      pendingTransitions.count == 1
        && (pendingTransitions[0]["payload"] as? [String: Any])?["status"] as? String
          == "awaiting_confirmation",
      "трасса не сохраняет один точный ожидающий переход"
    )
    let transitionStages = traceEvents.filter {
      $0["kind"] as? String == "transition_stage"
    }
    try require(
      transitionStages.count == 1
        && (transitionStages[0]["payload"] as? [String: Any])?["stage"] as? String
          == "closed",
      "ожидающий переход не остался закрытым"
    )
    let modelBranches = traceEvents.filter {
      $0["kind"] as? String == "model_branch"
    }
    let branchParents = modelBranches.compactMap {
      ($0["payload"] as? [String: Any])?["parent_checkpoint_id"] as? String
    }
    try require(
      modelBranches.count == 2
        && Set(branchParents) == Set(["shared-model-ancestor"]),
      "две модельные ветви не продолжают общий точный предок"
    )
    let branchChecks = traceEvents.filter {
      $0["kind"] as? String == "branch_check"
    }
    let branchCheckIDs = branchChecks.compactMap {
      ($0["payload"] as? [String: Any])?["check_id"] as? String
    }
    try require(
      branchChecks.count == 2
        && Set(branchCheckIDs)
          == Set(["check-contract-separation", "check-late-signal-routing"])
        && branchChecks.allSatisfy {
          ($0["payload"] as? [String: Any])?["status"] as? String == "passed"
        },
      "трасса не сохраняет две успешные проверки модельных ветвей"
    )
    let selections = traceEvents.filter {
      $0["kind"] as? String == "branch_selection"
    }
    let selectionPayload = selections.first?["payload"] as? [String: Any]
    try require(
      selections.count == 1
        && selectionPayload?["status"] as? String == "selected_in_model"
        && selectionPayload?["canonical_state"] as? String == "candidate_only",
      "внутренний отбор не сохранён как модельный кандидат"
    )
    let finalPayload = traceEvents.last?["payload"] as? [String: Any]
    try require(
      traceEvents.last?["kind"] as? String == "episode_state"
        && finalPayload?["state"] as? String == "model_selection_preserved",
      "трасса не завершается сохранённым внутренним выбором"
    )

    let process = Process()
    process.executableURL = try executableURL(named: "python3")
    process.arguments = [
      validator.path,
      "--schema", schema.path,
      "--trace", trace.path,
      "--scenario", "nonblocking_branching_v3",
    ]
    process.currentDirectoryURL = repositoryRoot
    var environment = ProcessInfo.processInfo.environment
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    process.environment = environment
    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    try process.run()
    process.waitUntilExit()
    let errorData = error.fileHandleForReading.readDataToEndOfFile()
    _ = output.fileHandleForReading.readDataToEndOfFile()
    try require(
      process.terminationReason == .exit && process.terminationStatus == 0,
      "канонический валидатор неблокирующего ветвления отклонил трассу: "
        + String(decoding: errorData, as: UTF8.self)
    )

    return DistributedEpisodeAcceptanceScenario(
      scenarioID: "pending_confirmation",
      status: "passed",
      terminalOutcome: nil,
      canonicalOutcomesEqual: nil,
      processCount: 1,
      acceptedResult: false,
      correlatedAnswerCount: nil,
      independentConfirmationCount: nil,
      remainingBudget: nil,
      reasonCode: nil,
      unconfirmedResultPublished: false,
      transitionPhase: "awaiting_confirmation",
      episodeState: "model_selection_preserved",
      modelBranchCount: 2,
      userConfirmed: false,
      internallySelected: true,
      checks: [
        "exact_transition_parked",
        "two_bounded_model_only_branches",
        "common_model_checkpoint",
        "branch_checks_preserved",
        "internal_candidate_selected",
        "final_state_model_selection_preserved",
        "user_confirmation_not_fabricated",
        "no_external_action",
      ]
    )
  }

  private static func executableURL(named name: String) throws -> URL {
    let pathEntries = ProcessInfo.processInfo.environment["PATH"]?.split(separator: ":") ?? []
    for pathEntry in pathEntries {
      let directory = String(pathEntry)
      guard directory.hasPrefix("/") else { continue }
      let candidate = URL(fileURLWithPath: directory, isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    throw DistributedEpisodeAcceptanceError.failed(
      "исполняемый файл \(name) не найден в абсолютных каталогах PATH"
    )
  }

  private static func runProbeStage(
    _ stage: String,
    storeRoot: URL,
    repositoryRoot: URL,
    probeExecutable: URL
  ) throws {
    let process = Process()
    process.executableURL = probeExecutable
    process.arguments = ["acceptance", "__stage", stage, storeRoot.path]
    process.currentDirectoryURL = repositoryRoot
    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    try process.run()
    process.waitUntilExit()
    let errorData = error.fileHandleForReading.readDataToEndOfFile()
    _ = output.fileHandleForReading.readDataToEndOfFile()
    try require(
      process.terminationReason == .exit && process.terminationStatus == 0,
      "дочерний процесс \(stage) завершился с ошибкой: "
        + String(decoding: errorData, as: UTF8.self)
    )
  }

  private static func require(
    _ condition: @autoclosure () throws -> Bool,
    _ message: String
  ) throws {
    guard try condition() else {
      throw DistributedEpisodeAcceptanceError.failed(message)
    }
  }
}
