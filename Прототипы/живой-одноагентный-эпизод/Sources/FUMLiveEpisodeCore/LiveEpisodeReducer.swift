import Foundation

public enum LiveModelPlanDecision: Equatable, Sendable {
  case request(LiveModelRequestRecorded)
  case checkpoint(LiveBudgetCheckpointCreated)
}

public enum LiveEpisodeReducer {
  public static func initialState(passport: LiveEpisodePassport) throws -> LiveEpisodeState {
    try validate(passport: passport)
    return LiveEpisodeState(
      passport: passport,
      nextSequence: 1,
      events: [],
      model: LiveModelAxisState(
        budget: LiveBudgetState(maximum: passport.modelPolicy.maximumBudget)
      ),
      transition: nil,
      latestBudgetCheckpoint: nil,
      confirmedGeneration: nil,
      continuation: nil
    )
  }

  public static func replay(
    passport: LiveEpisodePassport,
    events: [LiveEpisodeEvent]
  ) throws -> LiveEpisodeState {
    var state = try initialState(passport: passport)
    for event in events {
      state = try applying(event, to: state)
    }
    return state
  }

  public static func planModelInvocation(
    _ proposal: LiveModelInvocationProposal,
    checkpointID: String,
    in state: LiveEpisodeState
  ) throws -> LiveModelPlanDecision {
    guard !state.isTerminal else { throw LiveEpisodeError.terminalEpisode }
    try validate(proposal: proposal, in: state)
    switch try affordability(of: proposal, in: state) {
    case .affordable:
      return .request(LiveModelRequestRecorded(proposal: proposal))
    case .insufficientBudget:
      guard state.passport.checkpointPolicy.checkpointOnBudgetRejection else {
        throw LiveEpisodeError.budgetInsufficient
      }
      try requireTechnicalIdentifier(checkpointID, field: "checkpoint_id")
      return .checkpoint(
        LiveBudgetCheckpointCreated(
          checkpointID: checkpointID,
          proposal: proposal,
          reason: .insufficientBudget,
          budget: state.model.budget
        )
      )
    case .zeroMoneyNotProvenFreeLocal:
      guard state.passport.checkpointPolicy.checkpointOnBudgetRejection else {
        throw LiveEpisodeError.budgetInsufficient
      }
      try requireTechnicalIdentifier(checkpointID, field: "checkpoint_id")
      return .checkpoint(
        LiveBudgetCheckpointCreated(
          checkpointID: checkpointID,
          proposal: proposal,
          reason: .zeroMoneyNotProvenFreeLocal,
          budget: state.model.budget
        )
      )
    }
  }

  public static func applying(
    _ event: LiveEpisodeEvent,
    to state: LiveEpisodeState
  ) throws -> LiveEpisodeState {
    if let existing = state.events.first(where: { $0.eventID == event.eventID }) {
      guard existing == event else {
        throw LiveEpisodeError.eventConflict(eventID: event.eventID)
      }
      return state
    }

    if state.isTerminal, !isLateTransitionEvent(event.payload) {
      throw LiveEpisodeError.terminalEpisode
    }
    try validateEnvelope(event, state: state)
    guard event.sequence == state.nextSequence else {
      throw LiveEpisodeError.unexpectedSequence(
        expected: state.nextSequence,
        actual: event.sequence
      )
    }

    var model = state.model
    var transition = state.transition
    var latestBudgetCheckpoint = state.latestBudgetCheckpoint
    var confirmedGeneration = state.confirmedGeneration
    var continuation = state.continuation

    switch event.payload {
    case .modelCheckpointCreated(let payload):
      guard model.commonCheckpoint == nil else {
        throw order(event, "Общий модельный предок уже зафиксирован.")
      }
      try requireTechnicalIdentifier(payload.checkpointID, field: "checkpoint_id")
      try requireSHA256(payload.ancestorSHA256, field: "ancestor_sha256")
      model = LiveModelAxisState(
        commonCheckpointEventID: event.eventID,
        commonCheckpoint: payload,
        variants: model.variants,
        selectionEventID: model.selectionEventID,
        selection: model.selection,
        budget: model.budget
      )

    case .pendingTransitionDeclared(let payload):
      guard transition == nil else {
        throw order(event, "Ожидающий переход уже существует.")
      }
      try validate(coordinates: payload.coordinates, state: state)
      guard model.commonCheckpoint?.checkpointID == payload.parentCheckpointID else {
        throw LiveEpisodeError.unknownReference(payload.parentCheckpointID)
      }
      guard
        state.passport.actionAllowlist.contains(where: {
          $0.allowanceID == payload.allowanceID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.allowanceID)
      }
      transition = LiveTransitionAxisState(
        declarationEventID: event.eventID,
        declaration: payload
      )

    case .modelRequestRecorded(let payload):
      let proposal = payload.proposal
      try validate(proposal: proposal, in: state)
      guard case .affordable = try affordability(of: proposal, in: state) else {
        throw LiveEpisodeError.budgetInsufficient
      }
      let newReserved = try checkedAdding(model.budget.reserved, proposal.reservation)
      model = LiveModelAxisState(
        commonCheckpointEventID: model.commonCheckpointEventID,
        commonCheckpoint: model.commonCheckpoint,
        variants: model.variants + [
          LiveModelVariantState(requestEventID: event.eventID, proposal: proposal)
        ],
        selectionEventID: model.selectionEventID,
        selection: model.selection,
        budget: LiveBudgetState(
          maximum: model.budget.maximum,
          reserved: newReserved,
          charged: model.budget.charged
        )
      )

    case .modelResponseRecorded(let payload):
      guard
        let index = model.variants.firstIndex(where: {
          $0.proposal.variantID == payload.variantID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.variantID)
      }
      let variant = model.variants[index]
      guard variant.proposal.requestID == payload.requestID else {
        throw LiveEpisodeError.identityMismatch(
          field: "request_id",
          expected: variant.proposal.requestID,
          actual: payload.requestID
        )
      }
      guard variant.response == nil else {
        throw order(event, "Ответ для model-only-вызова уже сохранён.")
      }
      guard payload.providerIdentity == state.passport.modelPolicy.providerIdentity else {
        throw LiveEpisodeError.identityMismatch(
          field: "provider_identity",
          expected: state.passport.modelPolicy.providerIdentity.providerID,
          actual: payload.providerIdentity.providerID
        )
      }
      try requireTechnicalIdentifier(payload.responseID, field: "response_id")
      try requireSHA256(payload.outputSHA256, field: "output_sha256")
      guard LiveStrictIntentParser.sha256(of: payload.output) == payload.outputSHA256 else {
        throw LiveEpisodeError.identityMismatch(
          field: "output_sha256",
          expected: LiveStrictIntentParser.sha256(of: payload.output),
          actual: payload.outputSHA256
        )
      }
      try requireNonnegative(payload.charged, field: "charged")
      guard componentwiseLessThanOrEqual(payload.charged, variant.proposal.reservation) else {
        throw LiveEpisodeError.falseStatusElevation(
          "Фактическое списание превышает сохранённый reservation."
        )
      }
      if payload.status == .completed, payload.output.isEmpty {
        throw LiveEpisodeError.invalidEvent("Завершённый model-only-ответ не должен быть пустым.")
      }
      let newReserved = try checkedSubtracting(
        model.budget.reserved,
        variant.proposal.reservation
      )
      let newCharged = try checkedAdding(model.budget.charged, payload.charged)
      guard
        try budgetFits(
          maximum: model.budget.maximum,
          reserved: newReserved,
          charged: newCharged
        )
      else {
        throw LiveEpisodeError.falseStatusElevation("Списанное потребление нарушает бюджет.")
      }
      var variants = model.variants
      variants[index] = LiveModelVariantState(
        requestEventID: variant.requestEventID,
        proposal: variant.proposal,
        responseEventID: event.eventID,
        response: payload,
        intentEventID: variant.intentEventID,
        intent: variant.intent,
        verificationEventIDs: variant.verificationEventIDs,
        verifications: variant.verifications
      )
      model = LiveModelAxisState(
        commonCheckpointEventID: model.commonCheckpointEventID,
        commonCheckpoint: model.commonCheckpoint,
        variants: variants,
        selectionEventID: model.selectionEventID,
        selection: model.selection,
        budget: LiveBudgetState(
          maximum: model.budget.maximum,
          reserved: newReserved,
          charged: newCharged
        )
      )

    case .untrustedIntentParsed(let payload):
      guard
        let index = model.variants.firstIndex(where: {
          $0.proposal.variantID == payload.variantID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.variantID)
      }
      let variant = model.variants[index]
      guard let response = variant.response, response.status == .completed else {
        throw order(event, "Разбор намерения требует завершённого model-only-ответа.")
      }
      guard response.responseID == payload.sourceResponseID else {
        throw LiveEpisodeError.identityMismatch(
          field: "source_response_id",
          expected: response.responseID,
          actual: payload.sourceResponseID
        )
      }
      guard variant.intent == nil else {
        throw order(event, "Намерение для варианта уже разобрано.")
      }
      try validate(intent: payload.intent)
      let reparsedIntent: LiveUntrustedActionIntent
      do {
        reparsedIntent = try LiveStrictIntentParser.parse(response.output)
      } catch {
        throw LiveEpisodeError.invalidEvent(
          "Сохранённый model-only-ответ не является строгим каноническим намерением."
        )
      }
      guard reparsedIntent == payload.intent else {
        throw LiveEpisodeError.untrustedActionMismatch
      }
      var variants = model.variants
      variants[index] = LiveModelVariantState(
        requestEventID: variant.requestEventID,
        proposal: variant.proposal,
        responseEventID: variant.responseEventID,
        response: variant.response,
        intentEventID: event.eventID,
        intent: payload,
        verificationEventIDs: variant.verificationEventIDs,
        verifications: variant.verifications
      )
      model = replacingVariants(model, with: variants)

    case .modelSelectionRecorded(let payload):
      guard model.selection == nil else {
        throw order(event, "Внутренний модельный выбор уже сохранён.")
      }
      try requireTechnicalIdentifier(payload.selectionID, field: "selection_id")
      guard payload.status == .selectedInModel else {
        throw LiveEpisodeError.falseStatusElevation("Поддерживается только selected_in_model.")
      }
      let considered = Set(payload.consideredVariantIDs)
      guard considered.count == payload.consideredVariantIDs.count, considered.count >= 2 else {
        throw LiveEpisodeError.invalidEvent(
          "selected_in_model требует не менее двух уникальных вариантов."
        )
      }
      guard considered.contains(payload.selectedVariantID) else {
        throw LiveEpisodeError.unknownReference(payload.selectedVariantID)
      }
      guard
        let selectedVariant = model.variants.first(where: {
          $0.proposal.variantID == payload.selectedVariantID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.selectedVariantID)
      }
      guard selectedVariant.response?.status == .completed,
        selectedVariant.response?.responseID == payload.sourceResponseID
      else {
        throw LiveEpisodeError.modelSelectionWithoutResponse(
          variantID: payload.selectedVariantID
        )
      }
      guard selectedVariant.intent?.intent.intentID == payload.sourceIntentID else {
        throw LiveEpisodeError.modelSelectionWithoutIntent(
          variantID: payload.selectedVariantID
        )
      }
      let basis = Set(payload.basisVerificationIDs)
      guard basis.count == payload.basisVerificationIDs.count else {
        throw LiveEpisodeError.invalidEvent("Свидетельства выбора не должны повторяться.")
      }
      for variantID in payload.consideredVariantIDs {
        guard
          let variant = model.variants.first(where: {
            $0.proposal.variantID == variantID
          })
        else {
          throw LiveEpisodeError.unknownReference(variantID)
        }
        guard variant.response?.status == .completed else {
          throw LiveEpisodeError.modelSelectionWithoutResponse(variantID: variantID)
        }
        guard variant.intent != nil else {
          throw LiveEpisodeError.modelSelectionWithoutIntent(variantID: variantID)
        }
        let passed = variant.verifications.filter { $0.status == .passed }
        guard passed.contains(where: { basis.contains($0.verificationID) }) else {
          throw LiveEpisodeError.modelSelectionWithoutVerification(variantID: variantID)
        }
        guard variant.proposal.parentCheckpointID == model.commonCheckpoint?.checkpointID else {
          throw LiveEpisodeError.identityMismatch(
            field: "parent_checkpoint_id",
            expected: model.commonCheckpoint?.checkpointID ?? "",
            actual: variant.proposal.parentCheckpointID
          )
        }
      }
      model = LiveModelAxisState(
        commonCheckpointEventID: model.commonCheckpointEventID,
        commonCheckpoint: model.commonCheckpoint,
        variants: model.variants,
        selectionEventID: event.eventID,
        selection: payload,
        budget: model.budget
      )

    case .transitionUserConfirmed(let payload):
      guard var current = transition else {
        throw order(event, "Подтверждаемого перехода нет.")
      }
      try requireMatchingCoordinates(payload.coordinates, transition: current)
      guard current.confirmation == nil else {
        throw order(event, "Пользовательское подтверждение уже сохранено.")
      }
      if state.passport.checkpointPolicy.requireCheckpointForTransitionConfirmation {
        guard model.commonCheckpoint != nil else {
          throw order(event, "Подтверждение требует сохранённой контрольной точки.")
        }
      }
      try validate(evidence: payload.evidence)
      current = LiveTransitionAxisState(
        declarationEventID: current.declarationEventID,
        declaration: current.declaration,
        confirmationEventID: event.eventID,
        confirmation: payload,
        authorizationEventID: current.authorizationEventID,
        authorization: current.authorization,
        preflightEventID: current.preflightEventID,
        preflight: current.preflight,
        executionEventID: current.executionEventID,
        execution: current.execution,
        observationEventID: current.observationEventID,
        observation: current.observation,
        verificationEventID: current.verificationEventID,
        verification: current.verification
      )
      transition = current

    case .authorizationDecided(let payload):
      guard var current = transition else {
        throw order(event, "Авторизуемого перехода нет.")
      }
      try requireMatchingCoordinates(payload.coordinates, transition: current)
      guard current.confirmation != nil else {
        throw LiveEpisodeError.falseStatusElevation(
          "Авторизация не может предшествовать точному подтверждению перехода."
        )
      }
      guard current.authorization == nil else {
        throw order(event, "Решение об авторизации уже сохранено.")
      }
      guard
        let parsed = model.variants.compactMap(\.intent).first(where: {
          $0.intent.intentID == payload.intentID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.intentID)
      }
      guard
        let allowance = state.passport.actionAllowlist.first(where: {
          $0.allowanceID == payload.allowanceID
        }), payload.allowanceID == current.declaration.allowanceID
      else {
        throw LiveEpisodeError.unknownReference(payload.allowanceID)
      }
      if payload.decision == .allowed {
        guard parsed.intent.operation == allowance.operation,
          parsed.intent.adapterID == allowance.adapterID,
          parsed.intent.effectClass == allowance.effectClass,
          parsed.intent.objectID == payload.coordinates.objectID,
          parsed.intent.expectedEffectSHA256 == payload.coordinates.expectedEffectSHA256
        else {
          throw LiveEpisodeError.untrustedActionMismatch
        }
      }
      try validate(evidence: payload.evidence)
      current = LiveTransitionAxisState(
        declarationEventID: current.declarationEventID,
        declaration: current.declaration,
        confirmationEventID: current.confirmationEventID,
        confirmation: current.confirmation,
        authorizationEventID: event.eventID,
        authorization: payload,
        preflightEventID: current.preflightEventID,
        preflight: current.preflight,
        executionEventID: current.executionEventID,
        execution: current.execution,
        observationEventID: current.observationEventID,
        observation: current.observation,
        verificationEventID: current.verificationEventID,
        verification: current.verification
      )
      transition = current

    case .preflightCompleted(let payload):
      guard var current = transition else {
        throw order(event, "Проверяемого перехода нет.")
      }
      try requireMatchingCoordinates(payload.coordinates, transition: current)
      guard current.authorization?.decision == .allowed,
        current.authorization?.evidence.evidenceID == payload.authorizationEvidenceID
      else {
        throw LiveEpisodeError.falseStatusElevation(
          "Preflight требует отдельного совпадающего allowed-свидетельства."
        )
      }
      guard current.preflight == nil else {
        throw order(event, "Результат preflight уже сохранён.")
      }
      try validate(evidence: payload.evidence)
      current = copy(current, preflightEventID: event.eventID, preflight: payload)
      transition = current

    case .executionRecorded(let payload):
      guard var current = transition else {
        throw order(event, "Исполняемого перехода нет.")
      }
      try requireMatchingCoordinates(payload.coordinates, transition: current)
      guard current.preflight?.status == .passed,
        current.preflight?.evidence.evidenceID == payload.preflightEvidenceID
      else {
        throw LiveEpisodeError.falseStatusElevation(
          "Исполнение требует отдельного совпадающего passed-preflight."
        )
      }
      guard current.execution == nil else {
        throw order(event, "Результат исполнения уже сохранён.")
      }
      try validate(evidence: payload.evidence)
      current = copy(current, executionEventID: event.eventID, execution: payload)
      transition = current

    case .observationRecorded(let payload):
      guard var current = transition else {
        throw order(event, "Наблюдаемого перехода нет.")
      }
      try requireMatchingCoordinates(payload.coordinates, transition: current)
      guard current.execution?.status == .succeeded,
        current.execution?.evidence.evidenceID == payload.executionEvidenceID
      else {
        throw LiveEpisodeError.falseStatusElevation(
          "Наблюдение требует отдельной совпадающей квитанции исполнения."
        )
      }
      guard current.observation == nil else {
        throw order(event, "Наблюдение результата уже сохранено.")
      }
      try validate(evidence: payload.evidence)
      current = copy(current, observationEventID: event.eventID, observation: payload)
      transition = current

    case .verificationRecorded(let payload):
      try requireTechnicalIdentifier(payload.verificationID, field: "verification_id")
      guard
        state.passport.verificationCriteria.contains(where: {
          $0.criterionID == payload.criterionID
        })
      else {
        throw LiveEpisodeError.unknownReference(payload.criterionID)
      }
      try validate(evidence: payload.evidence)
      switch payload.scope {
      case .modelVariant:
        guard payload.coordinates == nil else {
          throw LiveEpisodeError.invalidEvent(
            "Модельная проверка не принимает координаты внешнего перехода."
          )
        }
        guard
          let index = model.variants.firstIndex(where: {
            $0.proposal.variantID == payload.subjectID
          })
        else {
          throw LiveEpisodeError.unknownReference(payload.subjectID)
        }
        let variant = model.variants[index]
        guard variant.response?.status == .completed, variant.intent != nil else {
          throw order(event, "Проверка варианта требует ответа и разобранного намерения.")
        }
        guard
          !model.variants.flatMap(\.verifications).contains(where: {
            $0.verificationID == payload.verificationID
          })
        else {
          throw LiveEpisodeError.eventConflict(eventID: payload.verificationID)
        }
        var variants = model.variants
        variants[index] = LiveModelVariantState(
          requestEventID: variant.requestEventID,
          proposal: variant.proposal,
          responseEventID: variant.responseEventID,
          response: variant.response,
          intentEventID: variant.intentEventID,
          intent: variant.intent,
          verificationEventIDs: variant.verificationEventIDs + [event.eventID],
          verifications: variant.verifications + [payload]
        )
        model = replacingVariants(model, with: variants)
      case .transition:
        guard var current = transition, let coordinates = payload.coordinates else {
          throw order(event, "Проверка перехода требует его точных координат.")
        }
        try requireMatchingCoordinates(coordinates, transition: current)
        guard payload.subjectID == coordinates.transitionID else {
          throw LiveEpisodeError.identityMismatch(
            field: "subject_id",
            expected: coordinates.transitionID,
            actual: payload.subjectID
          )
        }
        guard current.observation?.status == .observed else {
          throw LiveEpisodeError.falseStatusElevation(
            "Проверка перехода требует отдельного наблюдения результата."
          )
        }
        guard current.verification == nil else {
          throw order(event, "Проверка перехода уже сохранена.")
        }
        current = copy(current, verificationEventID: event.eventID, verification: payload)
        transition = current
      }

    case .budgetCheckpointCreated(let payload):
      try requireTechnicalIdentifier(payload.checkpointID, field: "checkpoint_id")
      try validate(proposal: payload.proposal, in: state)
      guard payload.budget == model.budget else {
        throw LiveEpisodeError.invalidBudgetCheckpoint
      }
      let expected = try affordability(of: payload.proposal, in: state)
      switch (expected, payload.reason) {
      case (.insufficientBudget, .insufficientBudget),
        (.zeroMoneyNotProvenFreeLocal, .zeroMoneyNotProvenFreeLocal):
        break
      default:
        throw LiveEpisodeError.invalidBudgetCheckpoint
      }
      latestBudgetCheckpoint = LiveBudgetCheckpointState(
        eventID: event.eventID,
        checkpoint: payload
      )

    case .generationConfirmed(let payload):
      try requireTechnicalIdentifier(payload.generationID, field: "generation_id")
      try requireSHA256(payload.stateSHA256, field: "state_sha256")
      guard payload.confirmedThroughSequence == event.sequence - 1 else {
        throw LiveEpisodeError.identityMismatch(
          field: "confirmed_through_sequence",
          expected: String(event.sequence - 1),
          actual: String(payload.confirmedThroughSequence)
        )
      }
      guard
        model.selection != nil || latestBudgetCheckpoint != nil
          || transition?.verification != nil
      else {
        throw order(event, "Подтверждать поколение пока нечему.")
      }
      confirmedGeneration = LiveGenerationConfirmationState(
        eventID: event.eventID,
        confirmation: payload
      )

    case .continuationDecided(let payload):
      guard continuation == nil else {
        throw order(event, "Решение о продолжении уже сохранено.")
      }
      guard let generation = confirmedGeneration,
        generation.confirmation.generationID == payload.generationID
      else {
        throw LiveEpisodeError.falseStatusElevation(
          "Решение о продолжении требует точного подтверждённого поколения."
        )
      }
      guard !payload.basisEventIDs.isEmpty,
        Set(payload.basisEventIDs).count == payload.basisEventIDs.count,
        payload.basisEventIDs.allSatisfy({ basisID in
          state.events.contains(where: { $0.eventID == basisID })
            || basisID == generation.eventID
        })
      else {
        throw LiveEpisodeError.invalidEvent("Основания продолжения недействительны.")
      }
      guard !payload.reason.isEmpty else {
        throw LiveEpisodeError.invalidEvent("Причина продолжения не должна быть пустой.")
      }
      if payload.decision != .continue {
        let terminal = terminalOutcome(for: payload.decision)
        guard let terminal, state.passport.terminalOutcomes.contains(terminal) else {
          throw LiveEpisodeError.falseStatusElevation(
            "Терминальный исход не разрешён паспортом."
          )
        }
      }
      if payload.decision == .budgetExhausted || payload.decision == .needsInput {
        guard latestBudgetCheckpoint != nil else {
          throw LiveEpisodeError.falseStatusElevation(
            "Бюджетный исход требует сохранённой контрольной точки."
          )
        }
      }
      continuation = LiveContinuationState(eventID: event.eventID, continuation: payload)
    }

    var events = state.events
    events.append(event)
    return LiveEpisodeState(
      passport: state.passport,
      nextSequence: event.sequence + 1,
      events: events,
      model: model,
      transition: transition,
      latestBudgetCheckpoint: latestBudgetCheckpoint,
      confirmedGeneration: confirmedGeneration,
      continuation: continuation
    )
  }

  private enum Affordability {
    case affordable
    case insufficientBudget
    case zeroMoneyNotProvenFreeLocal
  }

  private static func isLateTransitionEvent(_ payload: LiveEpisodeEventPayload) -> Bool {
    switch payload {
    case .transitionUserConfirmed, .authorizationDecided, .preflightCompleted,
      .executionRecorded, .observationRecorded:
      true
    case .verificationRecorded(let verification):
      verification.scope == .transition
    default:
      false
    }
  }

  private static func affordability(
    of proposal: LiveModelInvocationProposal,
    in state: LiveEpisodeState
  ) throws -> Affordability {
    let policy = state.passport.modelPolicy
    guard
      componentwiseLessThanOrEqual(
        proposal.reservation,
        policy.perInvocationReservation
      )
    else {
      return .insufficientBudget
    }
    let used = try checkedAdding(state.model.budget.reserved, state.model.budget.charged)
    guard componentwiseLessThanOrEqual(used, state.model.budget.maximum) else {
      throw LiveEpisodeError.budgetArithmeticOverflow
    }
    let available = try checkedSubtracting(state.model.budget.maximum, used)
    guard componentwiseLessThanOrEqual(proposal.reservation, available) else {
      return .insufficientBudget
    }
    if available.moneyMicrounits == 0, proposal.reservation.moneyMicrounits == 0,
      !(policy.executionMode == .local && policy.moneyUnit == .none)
    {
      return .zeroMoneyNotProvenFreeLocal
    }
    return .affordable
  }

  private static func validate(passport: LiveEpisodePassport) throws {
    guard passport.schemaIdentity == LiveEpisodeSchema.identity,
      passport.schemaVersion == LiveEpisodeSchema.version
    else {
      throw LiveEpisodeError.unsupportedSchema(
        identity: passport.schemaIdentity,
        version: passport.schemaVersion
      )
    }
    try requireTechnicalIdentifier(passport.episodeID, field: "episode_id")
    try requireTechnicalIdentifier(passport.goal.goalID, field: "goal.goal_id")
    guard !passport.goal.summary.isEmpty else {
      throw LiveEpisodeError.invalidPassport("Цель не должна быть пустой.")
    }
    try requireTechnicalIdentifier(passport.context.objectID, field: "context.object_id")
    try requireSHA256(passport.context.contentSHA256, field: "context.content_sha256")
    guard
      passport.modelPolicy.disclosure.allowedClasses.contains(
        passport.context.disclosureClass
      ), passport.modelPolicy.disclosure.allowedPurposes.contains(passport.context.purpose),
      passport.modelPolicy.disclosure.maximumInputBytes > 0
    else {
      throw LiveEpisodeError.invalidPassport("Контекст не разрешён disclosure-политикой.")
    }
    let modelPolicy = passport.modelPolicy
    try requireTechnicalIdentifier(modelPolicy.profileID, field: "model_policy.profile_id")
    try validate(provider: modelPolicy.providerIdentity)
    try requireNonnegative(modelPolicy.maximumBudget, field: "maximum_budget")
    try requireNonnegative(
      modelPolicy.perInvocationReservation,
      field: "per_invocation_reservation"
    )
    guard
      componentwiseLessThanOrEqual(
        modelPolicy.perInvocationReservation,
        modelPolicy.maximumBudget
      ), modelPolicy.perInvocationReservation.calls == 1, modelPolicy.maximumVariants > 0
    else {
      throw LiveEpisodeError.invalidPassport("Модельный бюджет или число вариантов неверны.")
    }
    if modelPolicy.moneyUnit == .none {
      guard modelPolicy.maximumBudget.moneyMicrounits == 0,
        modelPolicy.perInvocationReservation.moneyMicrounits == 0
      else {
        throw LiveEpisodeError.invalidPassport("money_unit none требует нулевых денег.")
      }
    }
    guard !passport.actionAllowlist.isEmpty,
      Set(passport.actionAllowlist.map(\.allowanceID)).count == passport.actionAllowlist.count
    else {
      throw LiveEpisodeError.invalidPassport("Allowlist пуст или содержит дубликаты.")
    }
    for action in passport.actionAllowlist {
      try requireTechnicalIdentifier(action.allowanceID, field: "allowance_id")
      try requireTechnicalIdentifier(action.operation, field: "operation")
      try requireTechnicalIdentifier(action.adapterID, field: "adapter_id")
      try requireTechnicalIdentifier(action.effectClass, field: "effect_class")
    }
    guard !passport.verificationCriteria.isEmpty,
      Set(passport.verificationCriteria.map(\.criterionID)).count
        == passport.verificationCriteria.count
    else {
      throw LiveEpisodeError.invalidPassport("Критерии проверки пусты или повторяются.")
    }
    for criterion in passport.verificationCriteria {
      try requireTechnicalIdentifier(criterion.criterionID, field: "criterion_id")
      try requireTechnicalIdentifier(criterion.verifierID, field: "verifier_id")
      guard !criterion.subject.isEmpty, !criterion.expectedResult.isEmpty else {
        throw LiveEpisodeError.invalidPassport("Критерий проверки неполон.")
      }
    }
    guard !passport.terminalOutcomes.isEmpty,
      Set(passport.terminalOutcomes.map(\.rawValue)).count == passport.terminalOutcomes.count
    else {
      throw LiveEpisodeError.invalidPassport("Терминальные исходы пусты или повторяются.")
    }
    guard passport.checkpointPolicy.checkpointOnBudgetRejection else {
      throw LiveEpisodeError.invalidPassport(
        "Схема версии 1 требует контрольную точку при отклонении по бюджету."
      )
    }
  }

  private static func validateEnvelope(
    _ event: LiveEpisodeEvent,
    state: LiveEpisodeState
  ) throws {
    guard event.schemaIdentity == LiveEpisodeSchema.identity,
      event.schemaVersion == LiveEpisodeSchema.version
    else {
      throw LiveEpisodeError.unsupportedSchema(
        identity: event.schemaIdentity,
        version: event.schemaVersion
      )
    }
    guard event.episodeID == state.passport.episodeID else {
      throw LiveEpisodeError.identityMismatch(
        field: "episode_id",
        expected: state.passport.episodeID,
        actual: event.episodeID
      )
    }
    try requireTechnicalIdentifier(event.eventID, field: "event_id")
    guard event.sequence > 0 else {
      throw LiveEpisodeError.invalidEvent("sequence должен быть положительным.")
    }
  }

  private static func validate(
    proposal: LiveModelInvocationProposal,
    in state: LiveEpisodeState
  ) throws {
    try requireTechnicalIdentifier(proposal.requestID, field: "request_id")
    try requireTechnicalIdentifier(proposal.variantID, field: "variant_id")
    try requireTechnicalIdentifier(proposal.parentCheckpointID, field: "parent_checkpoint_id")
    try requireTechnicalIdentifier(proposal.inputObjectID, field: "input_object_id")
    try requireSHA256(proposal.inputSHA256, field: "input_sha256")
    try requireNonnegative(proposal.reservation, field: "reservation")
    guard proposal.reservation.calls == 1 else {
      throw LiveEpisodeError.invalidEvent("Model-only reservation должен содержать один вызов.")
    }
    guard state.model.commonCheckpoint?.checkpointID == proposal.parentCheckpointID else {
      throw LiveEpisodeError.unknownReference(proposal.parentCheckpointID)
    }
    guard state.model.selection == nil else {
      throw LiveEpisodeError.eventOrderViolation(
        kind: .modelRequestRecorded,
        reason: "Новый вариант не создаётся после selected_in_model."
      )
    }
    guard
      !state.model.variants.contains(where: {
        $0.proposal.variantID == proposal.variantID || $0.proposal.requestID == proposal.requestID
      })
    else {
      throw LiveEpisodeError.eventConflict(eventID: proposal.requestID)
    }
    guard Int64(state.model.variants.count) < state.passport.modelPolicy.maximumVariants else {
      throw LiveEpisodeError.budgetInsufficient
    }
    guard
      state.passport.modelPolicy.disclosure.allowedClasses.contains(
        proposal.disclosureClass
      ), state.passport.modelPolicy.disclosure.allowedPurposes.contains(proposal.purpose)
    else {
      throw LiveEpisodeError.invalidEvent("Model-only disclosure не разрешён паспортом.")
    }
  }

  private static func validate(intent: LiveUntrustedActionIntent) throws {
    try requireTechnicalIdentifier(intent.intentID, field: "intent_id")
    try requireTechnicalIdentifier(intent.operation, field: "intent.operation")
    try requireTechnicalIdentifier(intent.adapterID, field: "intent.adapter_id")
    try requireTechnicalIdentifier(intent.effectClass, field: "intent.effect_class")
    try requireTechnicalIdentifier(intent.objectID, field: "intent.object_id")
    try requireSHA256(intent.expectedEffectSHA256, field: "intent.expected_effect_sha256")
    try requireSHA256(intent.argumentsSHA256, field: "intent.arguments_sha256")
  }

  private static func validate(
    coordinates: LiveTransitionCoordinates,
    state: LiveEpisodeState
  ) throws {
    guard coordinates.episodeID == state.passport.episodeID,
      coordinates.schemaVersion == LiveEpisodeSchema.version
    else {
      throw LiveEpisodeError.transitionEvidenceMismatch
    }
    try requireTechnicalIdentifier(coordinates.transitionID, field: "transition_id")
    try requireTechnicalIdentifier(coordinates.objectID, field: "object_id")
    try requireSHA256(
      coordinates.expectedEffectSHA256,
      field: "expected_effect_sha256"
    )
  }

  private static func validate(provider: LiveProviderIdentity) throws {
    try requireTechnicalIdentifier(provider.providerID, field: "provider_id")
    try requireTechnicalIdentifier(provider.interfaceID, field: "interface_id")
    guard !provider.modelID.isEmpty, !provider.runtimeID.isEmpty else {
      throw LiveEpisodeError.invalidPassport("Идентичность модели или runtime пуста.")
    }
  }

  private static func validate(evidence: LiveEvidenceObject) throws {
    try requireTechnicalIdentifier(evidence.evidenceID, field: "evidence_id")
    try requireSHA256(evidence.evidenceSHA256, field: "evidence_sha256")
  }

  private static func requireMatchingCoordinates(
    _ coordinates: LiveTransitionCoordinates,
    transition: LiveTransitionAxisState
  ) throws {
    guard coordinates == transition.declaration.coordinates else {
      throw LiveEpisodeError.transitionEvidenceMismatch
    }
  }

  private static func requireTechnicalIdentifier(
    _ value: String,
    field: String
  ) throws {
    let scalars = value.unicodeScalars
    guard !scalars.isEmpty, scalars.count <= 128 else {
      throw LiveEpisodeError.invalidEvent("Поле \(field) не является техническим идентификатором.")
    }
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
    let firstAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
    guard let first = scalars.first, firstAllowed.contains(first),
      scalars.allSatisfy({ allowed.contains($0) })
    else {
      throw LiveEpisodeError.invalidEvent("Поле \(field) не является техническим идентификатором.")
    }
  }

  private static func requireSHA256(_ value: String, field: String) throws {
    guard value.hasPrefix("sha256:"), value.count == 71 else {
      throw LiveEpisodeError.invalidEvent("Поле \(field) не является SHA-256.")
    }
    let digest = value.dropFirst(7)
    guard digest.allSatisfy({ "0123456789abcdef".contains($0) }) else {
      throw LiveEpisodeError.invalidEvent("Поле \(field) не является SHA-256.")
    }
  }

  private static func requireNonnegative(_ budget: LiveBudget, field: String) throws {
    guard budgetValues(budget).allSatisfy({ $0 >= 0 }) else {
      throw LiveEpisodeError.invalidEvent("Бюджет \(field) содержит отрицательное значение.")
    }
  }

  private static func budgetValues(_ budget: LiveBudget) -> [Int64] {
    [
      budget.calls,
      budget.inputTokens,
      budget.outputTokens,
      budget.wallClockMilliseconds,
      budget.computeUnits,
      budget.moneyMicrounits,
    ]
  }

  private static func componentwiseLessThanOrEqual(
    _ lhs: LiveBudget,
    _ rhs: LiveBudget
  ) -> Bool {
    zip(budgetValues(lhs), budgetValues(rhs)).allSatisfy { pair in
      pair.0 <= pair.1
    }
  }

  private static func checkedAdding(_ lhs: LiveBudget, _ rhs: LiveBudget) throws -> LiveBudget {
    let values = try zip(budgetValues(lhs), budgetValues(rhs)).map { pair in
      let (left, right) = pair
      let (value, overflow) = left.addingReportingOverflow(right)
      guard !overflow else { throw LiveEpisodeError.budgetArithmeticOverflow }
      return value
    }
    return budget(from: values)
  }

  private static func checkedSubtracting(
    _ lhs: LiveBudget,
    _ rhs: LiveBudget
  ) throws -> LiveBudget {
    let values = try zip(budgetValues(lhs), budgetValues(rhs)).map { pair in
      let (left, right) = pair
      let (value, overflow) = left.subtractingReportingOverflow(right)
      guard !overflow, value >= 0 else { throw LiveEpisodeError.budgetArithmeticOverflow }
      return value
    }
    return budget(from: values)
  }

  private static func budget(from values: [Int64]) -> LiveBudget {
    LiveBudget(
      calls: values[0],
      inputTokens: values[1],
      outputTokens: values[2],
      wallClockMilliseconds: values[3],
      computeUnits: values[4],
      moneyMicrounits: values[5]
    )
  }

  private static func budgetFits(
    maximum: LiveBudget,
    reserved: LiveBudget,
    charged: LiveBudget
  ) throws -> Bool {
    componentwiseLessThanOrEqual(try checkedAdding(reserved, charged), maximum)
  }

  private static func replacingVariants(
    _ model: LiveModelAxisState,
    with variants: [LiveModelVariantState]
  ) -> LiveModelAxisState {
    LiveModelAxisState(
      commonCheckpointEventID: model.commonCheckpointEventID,
      commonCheckpoint: model.commonCheckpoint,
      variants: variants,
      selectionEventID: model.selectionEventID,
      selection: model.selection,
      budget: model.budget
    )
  }

  private static func copy(
    _ current: LiveTransitionAxisState,
    preflightEventID: String,
    preflight: LivePreflightCompleted
  ) -> LiveTransitionAxisState {
    LiveTransitionAxisState(
      declarationEventID: current.declarationEventID,
      declaration: current.declaration,
      confirmationEventID: current.confirmationEventID,
      confirmation: current.confirmation,
      authorizationEventID: current.authorizationEventID,
      authorization: current.authorization,
      preflightEventID: preflightEventID,
      preflight: preflight,
      executionEventID: current.executionEventID,
      execution: current.execution,
      observationEventID: current.observationEventID,
      observation: current.observation,
      verificationEventID: current.verificationEventID,
      verification: current.verification
    )
  }

  private static func copy(
    _ current: LiveTransitionAxisState,
    executionEventID: String,
    execution: LiveExecutionRecorded
  ) -> LiveTransitionAxisState {
    LiveTransitionAxisState(
      declarationEventID: current.declarationEventID,
      declaration: current.declaration,
      confirmationEventID: current.confirmationEventID,
      confirmation: current.confirmation,
      authorizationEventID: current.authorizationEventID,
      authorization: current.authorization,
      preflightEventID: current.preflightEventID,
      preflight: current.preflight,
      executionEventID: executionEventID,
      execution: execution,
      observationEventID: current.observationEventID,
      observation: current.observation,
      verificationEventID: current.verificationEventID,
      verification: current.verification
    )
  }

  private static func copy(
    _ current: LiveTransitionAxisState,
    observationEventID: String,
    observation: LiveObservationRecorded
  ) -> LiveTransitionAxisState {
    LiveTransitionAxisState(
      declarationEventID: current.declarationEventID,
      declaration: current.declaration,
      confirmationEventID: current.confirmationEventID,
      confirmation: current.confirmation,
      authorizationEventID: current.authorizationEventID,
      authorization: current.authorization,
      preflightEventID: current.preflightEventID,
      preflight: current.preflight,
      executionEventID: current.executionEventID,
      execution: current.execution,
      observationEventID: observationEventID,
      observation: observation,
      verificationEventID: current.verificationEventID,
      verification: current.verification
    )
  }

  private static func copy(
    _ current: LiveTransitionAxisState,
    verificationEventID: String,
    verification: LiveVerificationRecorded
  ) -> LiveTransitionAxisState {
    LiveTransitionAxisState(
      declarationEventID: current.declarationEventID,
      declaration: current.declaration,
      confirmationEventID: current.confirmationEventID,
      confirmation: current.confirmation,
      authorizationEventID: current.authorizationEventID,
      authorization: current.authorization,
      preflightEventID: current.preflightEventID,
      preflight: current.preflight,
      executionEventID: current.executionEventID,
      execution: current.execution,
      observationEventID: current.observationEventID,
      observation: current.observation,
      verificationEventID: verificationEventID,
      verification: verification
    )
  }

  private static func terminalOutcome(
    for decision: LiveContinuationDecision
  ) -> LiveTerminalOutcome? {
    switch decision {
    case .continue:
      nil
    case .completed:
      .completed
    case .needsInput:
      .needsInput
    case .budgetExhausted:
      .budgetExhausted
    case .blocked:
      .blocked
    case .refused:
      .refused
    case .cancelled:
      .cancelled
    case .failed:
      .failed
    }
  }

  private static func order(
    _ event: LiveEpisodeEvent,
    _ reason: String
  ) -> LiveEpisodeError {
    .eventOrderViolation(kind: event.kind, reason: reason)
  }
}
