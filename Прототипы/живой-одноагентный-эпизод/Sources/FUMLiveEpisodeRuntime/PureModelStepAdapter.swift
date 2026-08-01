import FUMLiveEpisodeCore
import FUMPureModelStep

public actor BudgetedLiveEpisodeModelAdapter: LiveEpisodeModelAdapter {
  public nonisolated let contract: LiveEpisodeModelAdapterContract

  private let adapter: BudgetedModelOnlyAdapter
  private let profile: ModelOnlyBudgetProfile

  /// Async construction reads the actual immutable actor profile. A caller cannot provide a
  /// second, merely asserted descriptor that differs from the adapter used for I/O.
  public init(adapter: BudgetedModelOnlyAdapter) async {
    self.adapter = adapter
    profile = await adapter.profile
    contract = Self.liveContract(profile)
  }

  public func complete(_ request: LiveEpisodeModelAdapterRequest) async
    -> LiveEpisodeModelAdapterResult
  {
    guard request.reservation == contract.perInvocationReservation else {
      return result(
        for: request,
        outcome: .invalidEvidence(
          "Reservation adapter-request не совпадает с точным adapter contract."
        )
      )
    }
    guard
      let disclosure = ModelOnlyDisclosureClass(rawValue: request.disclosureClass.rawValue)
    else {
      return result(
        for: request,
        outcome: .invalidEvidence("Disclosure class не имеет точного pure-model отображения.")
      )
    }
    let attempt = await adapter.complete(
      BudgetedModelOnlyInvocation(
        invocationID: request.invocationID,
        input: request.input,
        disclosureClass: disclosure,
        purpose: request.purpose
      )
    )
    if let evidenceFailure = validate(attempt, request: request) {
      return result(for: request, outcome: .invalidEvidence(evidenceFailure))
    }
    if attempt.settlement?.kind == .conservativeFullReservation {
      return result(for: request, outcome: .unknownUsage)
    }
    let charged = attempt.settlement.map { Self.liveBudget($0.charged) } ?? .zero
    switch attempt.status {
    case .completed:
      guard let output = attempt.output else {
        return result(
          for: request,
          outcome: .invalidEvidence("Completed pure-model attempt не содержит output.")
        )
      }
      return result(for: request, outcome: .completed(output: output, charged: charged))
    case .failed:
      return result(
        for: request,
        outcome: .failed(output: attempt.output ?? "", charged: charged)
      )
    }
  }

  private func validate(
    _ attempt: BudgetedModelOnlyAttempt,
    request: LiveEpisodeModelAdapterRequest
  ) -> String? {
    guard attempt.profileID == profile.profileID,
      attempt.invocationID == request.invocationID
    else {
      return "Pure-model attempt не связан с точным profile/invocation."
    }
    if let reservation = attempt.reservation,
      Self.liveBudget(reservation.maximum) != request.reservation
    {
      return "Pure-model reservation не совпадает с durable live-reservation."
    }
    if let settlement = attempt.settlement,
      Self.liveBudget(settlement.reservedMaximum) != request.reservation
    {
      return "Pure-model settlement не связан с durable live-reservation."
    }
    if let model = attempt.providerModelIdentity, model != profile.modelIdentity {
      return "Provider evidence содержит другую model identity."
    }
    if let runtime = attempt.providerRuntimeIdentity, runtime != profile.runtimeIdentity {
      return "Provider evidence содержит другую runtime identity."
    }
    if attempt.status == .completed,
      attempt.providerModelIdentity == nil || attempt.providerRuntimeIdentity == nil
    {
      return "Completed provider evidence не содержит model/runtime identity."
    }
    return nil
  }

  private func result(
    for request: LiveEpisodeModelAdapterRequest,
    outcome: LiveEpisodeModelAdapterOutcome
  ) -> LiveEpisodeModelAdapterResult {
    LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: outcome
    )
  }

  private static func liveContract(
    _ profile: ModelOnlyBudgetProfile
  ) -> LiveEpisodeModelAdapterContract {
    LiveEpisodeModelAdapterContract(
      profileID: profile.profileID,
      executionMode: LiveExecutionMode(rawValue: profile.executionMode.rawValue)!,
      providerIdentity: LiveProviderIdentity(
        providerID: profile.providerIdentity,
        interfaceID: profile.providerInterfaceID,
        modelID: profile.modelIdentity,
        runtimeID: "\(profile.runtimeIdentity.name)@\(profile.runtimeIdentity.version)"
      ),
      disclosure: LiveDisclosurePolicy(
        allowedClasses: profile.disclosure.allowedClasses.map {
          LiveDisclosureClass(rawValue: $0.rawValue)!
        },
        maximumInputBytes: profile.disclosure.maxInputBytes,
        allowedPurposes: profile.disclosure.allowedPurposes
      ),
      moneyUnit: LiveMoneyUnit(rawValue: profile.moneyUnit.rawValue)!,
      maximumBudget: liveBudget(profile.maximumBudget),
      perInvocationReservation: liveBudget(profile.perInvocationReservation),
      maximumOutputTokens: profile.maxOutputTokens,
      timeoutMilliseconds: profile.perInvocationReservation.wallClockMilliseconds,
      maximumComputeUnits: profile.perInvocationReservation.computeUnits
    )
  }

  private static func liveBudget(_ budget: ModelOnlyBudget) -> LiveBudget {
    LiveBudget(
      calls: budget.calls,
      inputTokens: budget.inputTokens,
      outputTokens: budget.outputTokens,
      wallClockMilliseconds: budget.wallClockMilliseconds,
      computeUnits: budget.computeUnits,
      moneyMicrounits: budget.moneyMicrounits
    )
  }
}
