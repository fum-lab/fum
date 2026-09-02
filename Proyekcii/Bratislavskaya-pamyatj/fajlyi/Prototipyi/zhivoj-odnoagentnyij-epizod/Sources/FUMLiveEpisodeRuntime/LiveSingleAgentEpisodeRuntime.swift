import Darwin
import FUMLiveEpisodeCore
import Foundation

public struct LiveSingleAgentEpisodeRuntime {
  public let runDirectoryURL: URL
  public let acceptanceExecutableURL: URL

  public init(runDirectoryURL: URL, acceptanceExecutableURL: URL) {
    self.runDirectoryURL = runDirectoryURL.standardizedFileURL
    self.acceptanceExecutableURL = acceptanceExecutableURL.standardizedFileURL
  }

  public static func prepare(
    runDirectoryURL: URL,
    transportMode: LiveSingleAgentTransportMode
  ) throws -> LiveSingleAgentExecutionPassport {
    let root = runDirectoryURL.standardizedFileURL
    try requireEmptyPlainDirectory(root)
    let source = root.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.sourceRelativePath,
      isDirectory: true
    )
    let episode = root.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.episodeRelativePath,
      isDirectory: true
    )
    let checkpoints = root.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.checkpointRelativePath,
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: false)
    let scenario = try LiveSingleAgentScenarioFactory.prepare(at: source)
    try FileManager.default.createDirectory(at: episode, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: checkpoints, withIntermediateDirectories: false)
    let passport = try makeExecutionPassport(mode: transportMode, scenario: scenario)
    try passport.validate()
    let data = try passport.canonicalData()
    let destination = root.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.executionPassportFileName,
      isDirectory: false
    )
    try data.write(to: destination, options: [.withoutOverwriting])
    return passport
  }

  /// Advances exactly one runtime-owned phase inferred only from the validated passport and
  /// confirmed CURRENT. The caller never supplies a phase, intent, action, or continuation.
  public func advance() async throws -> LiveSingleAgentWorkerOutput {
    let passport = try loadExecutionPassport()
    let episodeURL = try childDirectory(relativePath: passport.episodeRelativePath)
    let current: StoredLiveEpisodeGeneration?
    do {
      current = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-read-current")
      ).stored
    } catch LiveEpisodeRuntimeError.noConfirmedGeneration {
      current = nil
    }

    if let current {
      try requirePassportBinding(passport, state: current.state)
    }

    if let current, current.state.isTerminal {
      return try completedOutput(
        current: current,
        passport: passport,
        acceptanceProcessID: nil
      )
    }
    if current?.state.model.selection == nil {
      return try await advanceModelPhase(passport: passport, episodeURL: episodeURL)
    }
    guard let transition = current?.state.transition else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "После model selection отсутствует объявленный переход."
      )
    }
    switch transition.phase {
    case .awaitingConfirmation:
      return try advanceCandidatePhase(
        passport: passport,
        episodeURL: episodeURL,
        current: current!
      )
    case .observed, .verified:
      return try advanceAcceptancePhase(
        passport: passport,
        episodeURL: episodeURL,
        current: current!
      )
    default:
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "CURRENT остановлен внутри неподдерживаемой промежуточной стадии \(transition.phase.rawValue)."
      )
    }
  }

  /// Pure read/reduce projection. It constructs no model, Git, action, or acceptance adapter.
  public func replayProjection() throws -> LiveSingleAgentProjection {
    let passport = try loadExecutionPassport()
    let episodeURL = try childDirectory(relativePath: passport.episodeRelativePath)
    let replayed = try LiveEpisodeRuntime(rootURL: episodeURL).replay(
      LiveEpisodeReplayCommand(commandID: "single-agent-no-call-replay")
    )
    try requirePassportBinding(passport, state: replayed.state)
    let state = replayed.state
    guard state.isTerminal,
      state.events.filter({ $0.kind == .continuationDecided }).count == 1,
      let selected = state.model.selection?.selectedVariantID,
      let phase = state.transition?.phase,
      let terminal = state.continuation?.continuation.decision
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Replay требует ровно один терминальный исход принятого эпизода."
      )
    }
    let candidateOID = passport.candidatePlan.policy.expectedCandidateOID
    let receiptURL =
      episodeURL
      .appendingPathComponent("git-candidate-acceptance", isDirectory: true)
      .appendingPathComponent("\(candidateOID).json", isDirectory: false)
    let receiptData = try Self.boundedData(at: receiptURL, maximumBytes: 1_048_576)
    let receipt = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceReceipt.self,
      from: receiptData
    )
    try receipt.validate()
    let receiptSHA256 = LiveSingleAgentExecutionPassport.sha256(receiptData)
    guard receipt.verdict == LiveGitCandidateAcceptanceVerdict.accepted,
      receipt.candidateOID == candidateOID,
      receiptData == (try LiveEpisodeRuntimeJSON.encode(receipt))
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Replay не нашёл точную принятую candidate receipt."
      )
    }
    try requireAcceptanceEvidence(
      receiptSHA256: receiptSHA256,
      passport: passport,
      state: state
    )
    return LiveSingleAgentProjection(
      executionPassportSHA256: try passport.canonicalSHA256(),
      eventKinds: state.events.map(\.kind),
      chargedBudget: state.model.budget.charged,
      selectedVariantID: selected,
      transitionPhase: phase,
      terminalOutcome: terminal,
      candidateOID: candidateOID,
      parentOID: passport.candidatePlan.policy.baseCommitOID,
      treeOID: passport.candidatePlan.policy.expectedTreeOID,
      candidateBranch: passport.candidatePlan.policy.candidateBranch,
      resultRef: passport.candidatePlan.policy.resultRef,
      acceptanceVerdict: receipt.verdict
    )
  }

  public func loadExecutionPassport() throws -> LiveSingleAgentExecutionPassport {
    let url = runDirectoryURL.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.executionPassportFileName,
      isDirectory: false
    )
    let data = try Self.boundedData(at: url, maximumBytes: 1_048_576)
    let passport = try LiveEpisodeRuntimeJSON.decode(
      LiveSingleAgentExecutionPassport.self,
      from: data
    )
    try passport.validate()
    guard try passport.canonicalData() == data else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Execution-passport не является закреплённым каноническим JSON."
      )
    }
    return passport
  }

  private func advanceModelPhase(
    passport: LiveSingleAgentExecutionPassport,
    episodeURL: URL
  ) async throws -> LiveSingleAgentWorkerOutput {
    let adapter: any LiveEpisodeModelAdapter
    switch passport.transportMode {
    case .recorded:
      adapter = LiveSingleAgentRecordedModelAdapter(prompts: passport.prompts)
    case .lmStudioLive:
      adapter = try await LiveSingleAgentModelProfile.makeLiveAdapter()
    }
    let runtime = LiveEpisodeRuntime(rootURL: episodeURL, modelAdapter: adapter)
    var current: StoredLiveEpisodeGeneration
    do {
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-model-phase")
      ).stored
    } catch LiveEpisodeRuntimeError.noConfirmedGeneration {
      let passportSHA256 = try passport.canonicalSHA256()
      let initialEvents = [
        LiveEpisodeEvent(
          episodeID: passport.episodePassport.episodeID,
          eventID: "event-common-checkpoint",
          sequence: 1,
          payload: .modelCheckpointCreated(
            LiveModelCheckpointCreated(
              checkpointID: "checkpoint-common-ancestor",
              ancestorSHA256: passportSHA256
            )
          )
        ),
        LiveEpisodeEvent(
          episodeID: passport.episodePassport.episodeID,
          eventID: "event-pending-transition",
          sequence: 2,
          payload: .pendingTransitionDeclared(
            LivePendingTransitionDeclared(
              coordinates: scenarioCoordinates(passport),
              allowanceID: "allow-git-candidate",
              parentCheckpointID: "checkpoint-common-ancestor"
            )
          )
        ),
      ]
      let created = try runtime.create(
        LiveEpisodeCreateCommand(
          commandID: "single-agent-create",
          passport: passport.episodePassport,
          initialEvents: initialEvents
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-created")
      ).stored
      guard created.status == .created || created.status == .alreadyApplied else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Runtime не создал начальное подтверждённое поколение."
        )
      }
    }

    for prompt in passport.prompts {
      current = try await completeVariant(
        prompt,
        passport: passport,
        runtime: runtime,
        current: current
      )
    }

    if current.state.latestBudgetCheckpoint == nil {
      let prompt = passport.prompts[0]
      let proposal = modelProposal(
        suffix: "c",
        prompt: prompt,
        reservation: passport.episodePassport.modelPolicy.perInvocationReservation
      )
      let output = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-budget-proposal-c",
          expectedGenerationSHA256: current.generationSHA256,
          action: .invokeModel(
            LiveEpisodeModelInvocationCommand(
              requestEventID: "event-request-variant-c",
              responseEventID: "event-response-variant-c",
              responseID: "response-variant-c",
              budgetCheckpointEventID: "event-budget-checkpoint",
              budgetCheckpointID: "checkpoint-budget-exhausted",
              proposal: proposal,
              input: prompt.input
            )
          )
        )
      )
      guard output.status == .checkpointed,
        output.state.model.variants.count == 2,
        !output.state.events.contains(where: {
          if case .modelRequestRecorded(let request) = $0.payload {
            return request.proposal.variantID == "variant-c"
          }
          return false
        })
      else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Третий вариант не завершился no-call budget checkpoint."
        )
      }
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-budget-checkpoint")
      ).stored
    }

    if current.state.model.selection == nil {
      let matching = current.state.model.variants.filter {
        $0.intent?.intent.argumentsSHA256 == LiveSingleAgentScenarioFactory.planSHA256
          && $0.verifications.contains(where: {
            $0.criterionID == "criterion-plan-match" && $0.status == .passed
          })
      }
      guard matching.count == 1,
        let selected = matching.first,
        let response = selected.response,
        let intent = selected.intent
      else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Внутренний выбор требует один подтверждённый plan-matching вариант."
        )
      }
      let selection = LiveEpisodeEvent(
        episodeID: passport.episodePassport.episodeID,
        eventID: "event-model-selection",
        sequence: current.state.nextSequence,
        payload: .modelSelectionRecorded(
          LiveModelSelectionRecorded(
            selectionID: "selection-plan-matching-variant",
            selectedVariantID: selected.proposal.variantID,
            sourceResponseID: response.responseID,
            sourceIntentID: intent.intent.intentID,
            consideredVariantIDs: passport.prompts.map(\.variantID),
            basisVerificationIDs: [
              "verification-canonical-a",
              "verification-canonical-b",
              "verification-plan-a",
            ]
          )
        )
      )
      let appended = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-select-model-variant",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [selection]))
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-selection")
      ).stored
      guard appended.state.transition?.phase == .awaitingConfirmation else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Внутренний выбор повысил внешний переход без независимого свидетельства."
        )
      }
    }

    if !current.state.events.contains(where: { $0.eventID == "event-selection-confirmed" }) {
      _ = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-confirm-selection-generation",
          expectedGenerationSHA256: current.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(eventID: "event-selection-confirmed")
          )
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-selection-confirmed")
      ).stored
    }
    try requireConfirmedEvent("event-model-selection", in: current)
    return checkpointOutput(
      checkpoint: .selectionGenerationConfirmed,
      current: current,
      candidateOID: nil
    )
  }

  private func completeVariant(
    _ prompt: LiveSingleAgentModelPrompt,
    passport: LiveSingleAgentExecutionPassport,
    runtime: LiveEpisodeRuntime,
    current initial: StoredLiveEpisodeGeneration
  ) async throws -> StoredLiveEpisodeGeneration {
    let suffix = String(prompt.variantID.suffix(1))
    var current = initial
    var variant = current.state.model.variants.first(where: {
      $0.proposal.variantID == prompt.variantID
    })
    if variant == nil {
      let proposal = modelProposal(
        suffix: suffix,
        prompt: prompt,
        reservation: passport.episodePassport.modelPolicy.perInvocationReservation
      )
      let invoked = try await runtime.resume(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-invoke-\(prompt.variantID)",
          expectedGenerationSHA256: current.generationSHA256,
          action: .invokeModel(
            LiveEpisodeModelInvocationCommand(
              requestEventID: "event-request-\(prompt.variantID)",
              responseEventID: "event-response-\(prompt.variantID)",
              responseID: "response-\(prompt.variantID)",
              budgetCheckpointEventID: "unused-budget-event-\(prompt.variantID)",
              budgetCheckpointID: "unused-budget-checkpoint-\(prompt.variantID)",
              proposal: proposal,
              input: prompt.input
            )
          )
        )
      )
      guard invoked.status == .advanced else {
        throw LiveEpisodeRuntimeError.invalidAdapterResult(
          "Model-only-вариант \(prompt.variantID) не завершён."
        )
      }
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-\(prompt.variantID)")
      ).stored
      variant = current.state.model.variants.first(where: {
        $0.proposal.variantID == prompt.variantID
      })
    }
    guard let variant, let response = variant.response,
      response.status == .completed,
      response.output == prompt.expectedOutput,
      response.outputSHA256 == prompt.expectedOutputSHA256,
      response.charged.inputTokens == prompt.inputTokens,
      response.charged.calls == 1
    else {
      throw LiveEpisodeRuntimeError.invalidAdapterResult(
        "Provider output/usage не совпали с точным execution-passport."
      )
    }
    if variant.intent == nil {
      let intent = try LiveStrictIntentParser.parse(response.output)
      let planMatches = intent.argumentsSHA256 == LiveSingleAgentScenarioFactory.planSHA256
      let sequence = current.state.nextSequence
      let events = [
        LiveEpisodeEvent(
          episodeID: passport.episodePassport.episodeID,
          eventID: "event-intent-\(prompt.variantID)",
          sequence: sequence,
          payload: .untrustedIntentParsed(
            LiveUntrustedIntentParsed(
              variantID: prompt.variantID,
              sourceResponseID: response.responseID,
              intent: intent
            )
          )
        ),
        LiveEpisodeEvent(
          episodeID: passport.episodePassport.episodeID,
          eventID: "event-verification-canonical-\(suffix)",
          sequence: sequence + 1,
          payload: .verificationRecorded(
            LiveVerificationRecorded(
              verificationID: "verification-canonical-\(suffix)",
              criterionID: "criterion-canonical-intent",
              scope: .modelVariant,
              subjectID: prompt.variantID,
              coordinates: nil,
              status: .passed,
              evidence: evidence("canonical-\(suffix)", response.outputSHA256)
            )
          )
        ),
        LiveEpisodeEvent(
          episodeID: passport.episodePassport.episodeID,
          eventID: "event-verification-plan-\(suffix)",
          sequence: sequence + 2,
          payload: .verificationRecorded(
            LiveVerificationRecorded(
              verificationID: "verification-plan-\(suffix)",
              criterionID: "criterion-plan-match",
              scope: .modelVariant,
              subjectID: prompt.variantID,
              coordinates: nil,
              status: planMatches ? .passed : .failed,
              evidence: evidence(
                "plan-match-\(suffix)",
                LiveStrictIntentParser.sha256(of: intent.argumentsSHA256)
              )
            )
          )
        ),
      ]
      _ = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-parse-verify-\(prompt.variantID)",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: events))
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-parsed-\(suffix)")
      ).stored
    }
    return current
  }

  private func advanceCandidatePhase(
    passport: LiveSingleAgentExecutionPassport,
    episodeURL: URL,
    current initial: StoredLiveEpisodeGeneration
  ) throws -> LiveSingleAgentWorkerOutput {
    let externalConfirmation = try loadExternalConfirmation(
      passport: passport,
      current: initial
    )
    let admission = LiveGitCandidateAdmissionRuntime(episodeDirectoryURL: episodeURL)
    var current = initial
    let confirmation = try admission.recordUserConfirmation(
      LiveGitCandidateUserConfirmationCommand(
        commandID: "single-agent-record-user-confirmation",
        expectedGenerationSHA256: current.generationSHA256,
        eventID: "event-transition-user-confirmed",
        receiptID: "receipt-transition-user-confirmed",
        generationConfirmationEventID: "event-transition-user-confirmed-generation",
        evidence: evidence(
          "evidence-user-confirmation",
          externalConfirmation.sha256
        )
      )
    )
    current = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
      LiveEpisodeInspectCommand(commandID: "single-agent-inspect-user-confirmation")
    ).stored
    guard confirmation.state.transition?.phase == .transitionUserConfirmed else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Независимое пользовательское подтверждение не сохранено."
      )
    }
    let authorization = try admission.authorizeSelectedIntent(
      LiveGitCandidateAuthorizationCommand(
        commandID: "single-agent-authorize-selected-intent",
        expectedGenerationSHA256: current.generationSHA256,
        eventID: "event-transition-authorized",
        receiptID: "receipt-transition-authorized",
        generationConfirmationEventID: "event-transition-authorized-generation",
        evidence: evidence(
          "evidence-authorization",
          LiveStrictIntentParser.sha256(of: "execution-passport-action-allowlist")
        )
      )
    )
    current = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
      LiveEpisodeInspectCommand(commandID: "single-agent-inspect-authorization")
    ).stored
    guard authorization.state.transition?.phase == .authorized else {
      throw LiveEpisodeRuntimeError.corruptGeneration("Точное намерение не авторизовано.")
    }
    let sourceURL = try childDirectory(relativePath: passport.sourceCheckoutRelativePath)
    let candidate = try LiveGitCandidateEpisodeRuntime(
      episodeDirectoryURL: episodeURL,
      sourceCheckoutURL: sourceURL
    ).createCandidateCommit(
      LiveGitCandidateEpisodeCommand(
        commandID: "single-agent-create-candidate",
        expectedGenerationSHA256: current.generationSHA256,
        preflightConfirmationEventID: "event-candidate-preflight-generation",
        observationConfirmationEventID: "event-candidate-observation-generation",
        plan: passport.candidatePlan
      )
    )
    current = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
      LiveEpisodeInspectCommand(commandID: "single-agent-inspect-candidate")
    ).stored
    guard candidate.candidateOID == passport.candidatePlan.policy.expectedCandidateOID,
      current.state.transition?.phase == .observed
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Кандидатный коммит не получил точное наблюдение."
      )
    }
    try requireConfirmedEvent(passport.candidatePlan.observationEventID, in: current)
    return checkpointOutput(
      checkpoint: .candidateObservationGenerationConfirmed,
      current: current,
      candidateOID: candidate.candidateOID
    )
  }

  private func advanceAcceptancePhase(
    passport: LiveSingleAgentExecutionPassport,
    episodeURL: URL,
    current initial: StoredLiveEpisodeGeneration
  ) throws -> LiveSingleAgentWorkerOutput {
    let candidateOID = passport.candidatePlan.policy.expectedCandidateOID
    let acceptance = try runAcceptance(
      episodeURL: episodeURL,
      candidateOID: candidateOID,
      expectedCurrentGenerationSHA256: initial.generationSHA256
    )
    guard acceptance.output.verdict == .accepted else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Отдельная приёмка отклонила точный кандидат."
      )
    }
    var current = initial
    if current.state.transition?.verification == nil {
      let verification = LiveEpisodeEvent(
        episodeID: passport.episodePassport.episodeID,
        eventID: "event-transition-acceptance-verified",
        sequence: current.state.nextSequence,
        payload: .verificationRecorded(
          LiveVerificationRecorded(
            verificationID: "verification-candidate-acceptance",
            criterionID: "criterion-candidate-acceptance",
            scope: .transition,
            subjectID: scenarioCoordinates(passport).transitionID,
            coordinates: scenarioCoordinates(passport),
            status: .passed,
            evidence: evidence(
              "evidence-candidate-acceptance",
              acceptance.receiptSHA256
            )
          )
        )
      )
      let runtime = LiveEpisodeRuntime(rootURL: episodeURL)
      _ = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-record-acceptance-verification",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [verification]))
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-acceptance-verification")
      ).stored
    }
    if !current.state.events.contains(where: { $0.eventID == "event-terminal-generation" }) {
      let runtime = LiveEpisodeRuntime(rootURL: episodeURL)
      _ = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-confirm-terminal-generation",
          expectedGenerationSHA256: current.generationSHA256,
          action: .confirmGeneration(
            LiveEpisodeConfirmGenerationCommand(eventID: "event-terminal-generation")
          )
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-terminal-generation")
      ).stored
    }
    if current.state.continuation == nil {
      guard let generation = current.state.confirmedGeneration else {
        throw LiveEpisodeRuntimeError.corruptGeneration(
          "Терминальный исход требует подтверждённое поколение."
        )
      }
      let continuation = LiveEpisodeEvent(
        episodeID: passport.episodePassport.episodeID,
        eventID: "event-continuation-completed",
        sequence: current.state.nextSequence,
        payload: .continuationDecided(
          LiveContinuationDecided(
            decision: .completed,
            generationID: generation.confirmation.generationID,
            basisEventIDs: [
              "event-budget-checkpoint",
              "event-model-selection",
              passport.candidatePlan.observationEventID,
              "event-transition-acceptance-verified",
              generation.eventID,
            ],
            reason: "Два model-only-варианта проверены, кандидат отдельно принят."
          )
        )
      )
      let runtime = LiveEpisodeRuntime(rootURL: episodeURL)
      _ = try runtime.resumeWithoutModel(
        LiveEpisodeResumeCommand(
          commandID: "single-agent-complete-terminal-outcome",
          expectedGenerationSHA256: current.generationSHA256,
          action: .appendEvents(LiveEpisodeAppendEventsCommand(events: [continuation]))
        )
      )
      current = try runtime.inspect(
        LiveEpisodeInspectCommand(commandID: "single-agent-inspect-completed")
      ).stored
    }
    return try completedOutput(
      current: current,
      passport: passport,
      acceptanceProcessID: acceptance.processID,
      acceptanceReceiptSHA256: acceptance.receiptSHA256
    )
  }

  private func completedOutput(
    current: StoredLiveEpisodeGeneration,
    passport: LiveSingleAgentExecutionPassport,
    acceptanceProcessID: Int32?,
    acceptanceReceiptSHA256: String? = nil
  ) throws -> LiveSingleAgentWorkerOutput {
    guard current.state.isTerminal,
      current.state.events.filter({ $0.kind == .continuationDecided }).count == 1,
      current.state.continuation?.continuation.decision == .completed,
      current.state.transition?.phase == .verified
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Принятый эпизод не завершён единственным completed-исходом."
      )
    }
    let candidateOID = passport.candidatePlan.policy.expectedCandidateOID
    let episodeURL = try childDirectory(relativePath: passport.episodeRelativePath)
    let storedReceipt = try validatedAcceptanceReceipt(
      episodeURL: episodeURL,
      candidateOID: candidateOID
    )
    if let acceptanceReceiptSHA256,
      acceptanceReceiptSHA256 != storedReceipt.sha256
    {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Acceptance-output не связан с фактической receipt."
      )
    }
    try requireAcceptanceEvidence(
      receiptSHA256: storedReceipt.sha256,
      passport: passport,
      state: current.state
    )
    return LiveSingleAgentWorkerOutput(
      status: .completed,
      processID: getpid(),
      generationSHA256: current.generationSHA256,
      stateSHA256: current.generation.stateSHA256,
      candidateOID: candidateOID,
      acceptanceProcessID: acceptanceProcessID,
      acceptanceVerdict: .accepted,
      acceptanceReceiptSHA256: storedReceipt.sha256,
      terminalOutcome: .completed
    )
  }

  private func checkpointOutput(
    checkpoint: LiveSingleAgentCheckpointID,
    current: StoredLiveEpisodeGeneration,
    candidateOID: String?
  ) -> LiveSingleAgentWorkerOutput {
    LiveSingleAgentWorkerOutput(
      status: .checkpoint,
      processID: getpid(),
      generationSHA256: current.generationSHA256,
      stateSHA256: current.generation.stateSHA256,
      checkpoint: checkpoint,
      candidateOID: candidateOID
    )
  }

  private func runAcceptance(
    episodeURL: URL,
    candidateOID: String,
    expectedCurrentGenerationSHA256: String
  ) throws -> (
    processID: Int32,
    output: LiveGitCandidateAcceptanceOutput,
    receiptSHA256: String
  ) {
    guard FileManager.default.isExecutableFile(atPath: acceptanceExecutableURL.path) else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Отдельный acceptance executable недоступен."
      )
    }
    let command = LiveGitCandidateAcceptanceCommand(
      commandID: "single-agent-independent-acceptance",
      candidateOID: candidateOID
    )
    let process = Process()
    process.executableURL = acceptanceExecutableURL
    process.arguments = [episodeURL.path]
    process.currentDirectoryURL = runDirectoryURL
    process.environment = [
      "PATH": LiveGitSystemRuntime.executableSearchPath,
      "LC_ALL": "C",
    ]
    let input = Pipe()
    let output = Pipe()
    let errors = Pipe()
    process.standardInput = input
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    let processID = process.processIdentifier
    try input.fileHandleForWriting.write(contentsOf: LiveEpisodeRuntimeJSON.encode(command))
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = errors.fileHandleForReading.readDataToEndOfFile()
    guard process.terminationReason == .exit, process.terminationStatus == 0,
      errorData.isEmpty
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Отдельная acceptance-проверка завершилась отказом."
      )
    }
    let decoded = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceOutput.self,
      from: outputData
    )
    guard outputData == (try LiveEpisodeRuntimeJSON.encode(decoded)),
      decoded.schemaVersion == LiveGitCandidateAcceptanceSchema.version,
      decoded.commandID == command.commandID,
      decoded.candidateOID == candidateOID
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Acceptance-output не связан с точной версионной командой."
      )
    }
    let storedReceipt = try validatedAcceptanceReceipt(
      episodeURL: episodeURL,
      candidateOID: candidateOID,
      expectedCurrentGenerationSHA256: expectedCurrentGenerationSHA256
    )
    guard decoded.verdict == storedReceipt.receipt.verdict,
      decoded.receiptSHA256 == storedReceipt.sha256
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Acceptance-output не связан с фактической валидированной receipt."
      )
    }
    return (processID, decoded, storedReceipt.sha256)
  }

  private func validatedAcceptanceReceipt(
    episodeURL: URL,
    candidateOID: String,
    expectedCurrentGenerationSHA256: String? = nil
  ) throws -> (
    receipt: LiveGitCandidateAcceptanceReceipt,
    sha256: String
  ) {
    let receiptURL =
      episodeURL
      .appendingPathComponent("git-candidate-acceptance", isDirectory: true)
      .appendingPathComponent("\(candidateOID).json", isDirectory: false)
    let data = try Self.boundedData(at: receiptURL, maximumBytes: 1_048_576)
    let receipt = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceReceipt.self,
      from: data
    )
    try receipt.validate()
    guard data == (try LiveEpisodeRuntimeJSON.encode(receipt)),
      receipt.candidateOID == candidateOID,
      expectedCurrentGenerationSHA256.map({
        receipt.currentGenerationSHA256 == $0
      }) ?? true
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Acceptance-receipt не связана с точным кандидатом и CURRENT."
      )
    }
    return (
      receipt,
      LiveSingleAgentExecutionPassport.sha256(data)
    )
  }

  private func requireAcceptanceEvidence(
    receiptSHA256: String,
    passport: LiveSingleAgentExecutionPassport,
    state: LiveEpisodeState
  ) throws {
    guard
      let event = state.events.first(where: {
        $0.eventID == "event-transition-acceptance-verified"
      }),
      case .verificationRecorded(let verification) = event.payload,
      verification.verificationID == "verification-candidate-acceptance",
      verification.criterionID == "criterion-candidate-acceptance",
      verification.scope == .transition,
      verification.subjectID == scenarioCoordinates(passport).transitionID,
      verification.coordinates == scenarioCoordinates(passport),
      verification.status == .passed,
      verification.evidence
        == evidence("evidence-candidate-acceptance", receiptSHA256)
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Терминальная трасса не связана с точной acceptance-receipt."
      )
    }
  }

  private func modelProposal(
    suffix: String,
    prompt: LiveSingleAgentModelPrompt,
    reservation: LiveBudget
  ) -> LiveModelInvocationProposal {
    LiveModelInvocationProposal(
      requestID: "request-variant-\(suffix)",
      variantID: "variant-\(suffix)",
      parentCheckpointID: "checkpoint-common-ancestor",
      inputObjectID: "input-variant-\(suffix)",
      inputSHA256: prompt.inputSHA256,
      disclosureClass: .synthetic,
      purpose: LiveSingleAgentModelProfile.purpose,
      reservation: reservation
    )
  }

  private func scenarioCoordinates(
    _ passport: LiveSingleAgentExecutionPassport
  ) -> LiveTransitionCoordinates {
    LiveTransitionCoordinates(
      episodeID: passport.episodePassport.episodeID,
      transitionID: "transition-candidate",
      objectID: "candidate-artifact",
      expectedEffectSHA256: LiveSingleAgentScenarioFactory.planSHA256
    )
  }

  private func evidence(_ identifier: String, _ digest: String) -> LiveEvidenceObject {
    LiveEvidenceObject(evidenceID: identifier, evidenceSHA256: digest)
  }

  private func requireConfirmedEvent(
    _ eventID: String,
    in current: StoredLiveEpisodeGeneration
  ) throws {
    guard let confirmation = current.state.confirmedGeneration,
      let event = current.state.events.first(where: { $0.eventID == eventID }),
      event.sequence <= confirmation.confirmation.confirmedThroughSequence
    else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Checkpoint не подтверждает требуемое событие \(eventID)."
      )
    }
  }

  private func requirePassportBinding(
    _ passport: LiveSingleAgentExecutionPassport,
    state: LiveEpisodeState
  ) throws {
    let expected = try passport.canonicalSHA256()
    guard state.model.commonCheckpoint?.ancestorSHA256 == expected else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Execution-passport не совпадает с SHA, закреплённым в подтверждённом CURRENT."
      )
    }
  }

  private func loadExternalConfirmation(
    passport: LiveSingleAgentExecutionPassport,
    current: StoredLiveEpisodeGeneration
  ) throws -> (value: LiveSingleAgentExternalConfirmation, sha256: String) {
    let confirmationURL = runDirectoryURL.appendingPathComponent(
      LiveSingleAgentEpisodeSchema.externalConfirmationFileName,
      isDirectory: false
    )
    let data = try Self.boundedData(at: confirmationURL, maximumBytes: 65_536)
    let confirmation = try LiveEpisodeRuntimeJSON.decode(
      LiveSingleAgentExternalConfirmation.self,
      from: data
    )
    guard data == (try LiveEpisodeRuntimeJSON.encode(confirmation)),
      confirmation.schemaIdentity == LiveSingleAgentEpisodeSchema.externalConfirmationIdentity,
      confirmation.schemaVersion == LiveSingleAgentEpisodeSchema.version,
      confirmation.decision == "confirm-isolated-candidate-transition",
      confirmation.harnessProcessID > 0,
      confirmation.observedCheckpoint == .selectionGenerationConfirmed,
      confirmation.observedWorkerProcessID > 0,
      confirmation.observedWorkerProcessID != getpid(),
      confirmation.generationSHA256 == current.generationSHA256,
      confirmation.stateSHA256 == current.generation.stateSHA256,
      confirmation.executionPassportSHA256 == (try passport.canonicalSHA256())
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Внешнее подтверждение не связано с точным первым checkpoint и CURRENT."
      )
    }
    let markerURL =
      runDirectoryURL
      .appendingPathComponent(
        LiveSingleAgentEpisodeSchema.checkpointRelativePath,
        isDirectory: true
      )
      .appendingPathComponent(
        "\(LiveSingleAgentCheckpointID.selectionGenerationConfirmed.rawValue).json",
        isDirectory: false
      )
    let markerData = try Self.boundedData(at: markerURL, maximumBytes: 65_536)
    let marker = try LiveEpisodeRuntimeJSON.decode(
      LiveSingleAgentCheckpointMarker.self,
      from: markerData
    )
    guard markerData == (try LiveEpisodeRuntimeJSON.encode(marker)),
      marker.schemaIdentity == LiveSingleAgentEpisodeSchema.checkpointMarkerIdentity,
      marker.schemaVersion == LiveSingleAgentEpisodeSchema.version,
      marker.checkpoint == confirmation.observedCheckpoint,
      marker.processID == confirmation.observedWorkerProcessID,
      marker.generationSHA256 == confirmation.generationSHA256,
      marker.stateSHA256 == confirmation.stateSHA256
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Внешнее подтверждение не совпадает с наблюдаемым checkpoint marker."
      )
    }
    try requireConfirmedEvent("event-model-selection", in: current)
    let stableEvidence = [
      confirmation.schemaIdentity,
      String(confirmation.schemaVersion),
      confirmation.decision,
      confirmation.observedCheckpoint.rawValue,
      confirmation.generationSHA256,
      confirmation.stateSHA256,
      confirmation.executionPassportSHA256,
    ].joined(separator: "\n")
    return (
      confirmation,
      LiveSingleAgentExecutionPassport.sha256(Data(stableEvidence.utf8))
    )
  }

  private func childDirectory(relativePath: String) throws -> URL {
    guard
      relativePath == LiveSingleAgentEpisodeSchema.episodeRelativePath
        || relativePath == LiveSingleAgentEpisodeSchema.sourceRelativePath
    else {
      throw LiveEpisodeRuntimeError.invalidCommand("Неизвестный относительный каталог.")
    }
    let child = runDirectoryURL.appendingPathComponent(relativePath, isDirectory: true)
      .standardizedFileURL
    guard child.deletingLastPathComponent() == runDirectoryURL else {
      throw LiveEpisodeRuntimeError.invalidCommand("Относительный каталог вышел за run root.")
    }
    return child
  }

  private static func makeExecutionPassport(
    mode: LiveSingleAgentTransportMode,
    scenario: LiveSingleAgentScenario
  ) throws -> LiveSingleAgentExecutionPassport {
    let expected = try expectedExecutionPassport(mode: mode)
    guard scenario.plan == expected.candidatePlan,
      scenario.actionAllowlist == expected.episodePassport.actionAllowlist
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Подготовленный source checkout не совпадает с точным execution-passport."
      )
    }
    return expected
  }

  static func expectedExecutionPassport(
    mode: LiveSingleAgentTransportMode
  ) throws -> LiveSingleAgentExecutionPassport {
    let plan = try LiveSingleAgentScenarioFactory.makePlan()
    let allowance = LiveAllowedAction(
      allowanceID: "allow-git-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated-git-write",
      candidateCommitPolicy: plan.policy
    )
    try allowance.validateCandidateCommitPolicy()
    let outputA =
      "{\"adapter_id\":\"fum-git-candidate-v1\",\"arguments_sha256\":\"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808\",\"effect_class\":\"isolated-git-write\",\"expected_effect_sha256\":\"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808\",\"intent_id\":\"intent-variant-a\",\"object_id\":\"candidate-artifact\",\"operation\":\"create_candidate_commit\"}"
    let outputB =
      "{\"adapter_id\":\"fum-git-candidate-v1\",\"arguments_sha256\":\"sha256:27747689baf9903c9aae69d82a95e8dcf4254c648ca13e4c9ff49adb1e546bb6\",\"effect_class\":\"isolated-git-write\",\"expected_effect_sha256\":\"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808\",\"intent_id\":\"intent-variant-b\",\"object_id\":\"candidate-artifact\",\"operation\":\"create_candidate_commit\"}"
    let prefix =
      String(UnicodeScalar(0x2F)!)
      + "no_think\nReturn exactly the JSON on the next line, byte for byte, with no markdown or explanation.\n"
    let prompts = [
      LiveSingleAgentModelPrompt(
        variantID: "variant-a",
        input: prefix + outputA,
        inputSHA256: "sha256:0ee3d9bd4a4553bdc542c52a8d47b6d08bd672cb1a364877d2bea11cc0795864",
        inputBytes: 467,
        inputTokens: 219,
        expectedOutput: outputA,
        expectedOutputSHA256:
          "sha256:1d4c8988c1bf3deaea6c81168c6273b943199e76b1950b3884bd27ef4e210a9e"
      ),
      LiveSingleAgentModelPrompt(
        variantID: "variant-b",
        input: prefix + outputB,
        inputSHA256: "sha256:5301ee0fef1db1216ea01a1e0a673fe6fe5932185ff4ad1b747e7e14a912bdcb",
        inputBytes: 467,
        inputTokens: 214,
        expectedOutput: outputB,
        expectedOutputSHA256:
          "sha256:8f36755113a3a026f2dcccd5570af7cbe88da89240806e9cac023fc3272c0fd8"
      ),
    ]
    let episodePassport = LiveEpisodePassport(
      episodeID: "episode-single-agent-v1",
      goal: LiveEpisodeGoal(
        goalID: "goal-create-accepted-candidate",
        summary: "Создать и отдельно принять один изолированный синтетический Git-кандидат."
      ),
      context: LiveEpisodeContext(
        objectID: "context-candidate-plan-v1",
        contentSHA256: LiveSingleAgentScenarioFactory.planSHA256,
        disclosureClass: .synthetic,
        purpose: LiveSingleAgentModelProfile.purpose
      ),
      modelPolicy: LiveSingleAgentModelProfile.policy(for: mode),
      actionAllowlist: [allowance],
      verificationCriteria: [
        LiveVerificationCriterion(
          criterionID: "criterion-canonical-intent",
          subject: "Ответ является точным каноническим намерением из model-only-трассы.",
          verifierID: "single-agent-runtime.strict-parser.v1",
          expectedResult: "passed"
        ),
        LiveVerificationCriterion(
          criterionID: "criterion-plan-match",
          subject: "Аргументы намерения совпадают с закреплённым candidate plan.",
          verifierID: "single-agent-runtime.plan-verifier.v1",
          expectedResult: "passed"
        ),
        LiveVerificationCriterion(
          criterionID: "criterion-candidate-acceptance",
          subject: "Отдельный процесс заново проверил точный кандидат и принял его.",
          verifierID: "fum-live-candidate-acceptance.v1",
          expectedResult: "passed"
        ),
      ],
      checkpointPolicy: LiveCheckpointPolicy(
        checkpointOnBudgetRejection: true,
        requireCheckpointForTransitionConfirmation: true,
        requireConfirmedGenerationForContinuation: true
      ),
      terminalOutcomes: [.completed, .needsInput, .budgetExhausted, .failed]
    )
    return LiveSingleAgentExecutionPassport(
      transportMode: mode,
      episodePassport: episodePassport,
      candidatePlan: plan,
      prompts: prompts
    )
  }

  private static func requireEmptyPlainDirectory(_ url: URL) throws {
    guard url.isFileURL else {
      throw LiveEpisodeRuntimeError.invalidCommand("Run root должен быть локальным каталогом.")
    }
    let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
    guard values.isDirectory == true, values.isSymbolicLink != true,
      try FileManager.default.contentsOfDirectory(atPath: url.path).isEmpty
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Run root должен быть существующим пустым обычным каталогом."
      )
    }
  }

  private static func boundedData(at url: URL, maximumBytes: Int) throws -> Data {
    let values = try url.resourceValues(forKeys: [
      .isRegularFileKey,
      .isSymbolicLinkKey,
      .fileSizeKey,
    ])
    guard values.isRegularFile == true, values.isSymbolicLink != true,
      let size = values.fileSize, size > 0, size <= maximumBytes
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Runtime JSON-файл недоступен или слишком велик.")
    }
    return try Data(contentsOf: url, options: [.mappedIfSafe])
  }

}
