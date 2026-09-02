import FUMLiveEpisodeCore
import FUMPureModelStep
import Foundation

public enum LiveSingleAgentModelProfile {
  public static let purpose = "single_agent_candidate_variant"
  public static let liveProfileID = "fum.live.single-agent.lmstudio.v1"
  public static let recordedProfileID = "fum.live.single-agent.recorded.v1"
  public static let endpoint = "http://127.0.0.1:1234/api/v0/chat/completions"
  public static let modelID = "qwen/qwen3-0.6b"
  public static let runtimeName = "llama.cpp-mac-arm64-apple-metal-advsimd"
  public static let runtimeVersion = "2.27.1"
  public static let tokenizerIdentity =
    "lmstudio.rest-v0.qwen3-0.6b.live-episode-attestation.v1"
  public static let maximumOutputTokens: Int64 = 256

  public static let perInvocationReservation = LiveBudget(
    calls: 1,
    inputTokens: 256,
    outputTokens: maximumOutputTokens,
    wallClockMilliseconds: 30_000,
    computeUnits: 30_000,
    moneyMicrounits: 0
  )

  public static let maximumBudget = LiveBudget(
    calls: 2,
    inputTokens: 512,
    outputTokens: maximumOutputTokens * 2,
    wallClockMilliseconds: 60_000,
    computeUnits: 60_000,
    moneyMicrounits: 0
  )

  public static func providerIdentity(
    for mode: LiveSingleAgentTransportMode
  ) -> LiveProviderIdentity {
    switch mode {
    case .recorded:
      LiveProviderIdentity(
        providerID: "fum.recorded.model-only.v1",
        interfaceID: "fum.recorded.in-memory.v1",
        modelID: modelID,
        runtimeID: "FUMLiveSingleAgentRecordedModel/1"
      )
    case .lmStudioLive:
      LiveProviderIdentity(
        providerID: "lmstudio",
        interfaceID: "lmstudio.rest-api.v0.chat-completions",
        modelID: modelID,
        runtimeID: "\(runtimeName)@\(runtimeVersion)"
      )
    }
  }

  public static func policy(for mode: LiveSingleAgentTransportMode) -> LiveModelPolicy {
    LiveModelPolicy(
      profileID: mode == .recorded ? recordedProfileID : liveProfileID,
      executionMode: .local,
      providerIdentity: providerIdentity(for: mode),
      disclosure: LiveDisclosurePolicy(
        allowedClasses: [.synthetic],
        maximumInputBytes: 467,
        allowedPurposes: [purpose]
      ),
      moneyUnit: .none,
      maximumBudget: maximumBudget,
      perInvocationReservation: perInvocationReservation,
      maximumVariants: 3
    )
  }

  public static func adapterContract(
    for mode: LiveSingleAgentTransportMode
  ) -> LiveEpisodeModelAdapterContract {
    let policy = policy(for: mode)
    return LiveEpisodeModelAdapterContract(
      profileID: policy.profileID,
      executionMode: policy.executionMode,
      providerIdentity: policy.providerIdentity,
      disclosure: policy.disclosure,
      moneyUnit: policy.moneyUnit,
      maximumBudget: policy.maximumBudget,
      perInvocationReservation: policy.perInvocationReservation,
      maximumOutputTokens: maximumOutputTokens,
      timeoutMilliseconds: perInvocationReservation.wallClockMilliseconds,
      maximumComputeUnits: perInvocationReservation.computeUnits
    )
  }

  public static func makeLiveAdapter() async throws -> BudgetedLiveEpisodeModelAdapter {
    guard let endpointURL = URL(string: endpoint) else {
      throw LiveEpisodeRuntimeError.invalidCommand("Некорректный loopback endpoint provider.")
    }
    let runtime = ModelOnlyRuntimeIdentity(name: runtimeName, version: runtimeVersion)
    let profile = ModelOnlyBudgetProfile(
      schemaVersion: 2,
      profileID: liveProfileID,
      executionMode: .local,
      providerIdentity: "lmstudio",
      providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
      endpoint: endpoint,
      modelIdentity: modelID,
      runtimeIdentity: runtime,
      tokenizerIdentity: tokenizerIdentity,
      tokenizationMethod: .exact,
      computeUnit: .wallClockMillisecond,
      moneyUnit: .none,
      disclosure: ModelOnlyDisclosurePolicy(
        allowedClasses: [.synthetic],
        maxInputBytes: 467,
        allowedPurposes: [purpose]
      ),
      maximumBudget: pureBudget(maximumBudget),
      perInvocationReservation: pureBudget(perInvocationReservation),
      maxOutputTokens: maximumOutputTokens,
      durability: .processMemory
    )
    let pure = BudgetedModelOnlyAdapter(
      profile: profile,
      tokenizer: .lmStudioQwen3LiveEpisodeV1,
      transport: LMStudioRESTV0BudgetTransport(
        configuration: LMStudioRESTV0Configuration(
          endpoint: endpointURL,
          tokenizerIdentity: tokenizerIdentity
        )
      )
    )
    let adapter = await BudgetedLiveEpisodeModelAdapter(adapter: pure)
    guard adapter.contract == adapterContract(for: .lmStudioLive) else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Live model adapter не совпадает с execution-passport."
      )
    }
    return adapter
  }

  private static func pureBudget(_ value: LiveBudget) -> ModelOnlyBudget {
    ModelOnlyBudget(
      calls: value.calls,
      inputTokens: value.inputTokens,
      outputTokens: value.outputTokens,
      wallClockMilliseconds: value.wallClockMilliseconds,
      computeUnits: value.computeUnits,
      moneyMicrounits: value.moneyMicrounits
    )
  }
}

public actor LiveSingleAgentRecordedModelAdapter: LiveEpisodeModelAdapter {
  public nonisolated let contract: LiveEpisodeModelAdapterContract

  private let prompts: [LiveSingleAgentModelPrompt]
  private var completedInvocationIDs: Set<String> = []
  private var calls = 0

  public init(prompts: [LiveSingleAgentModelPrompt]) {
    self.prompts = prompts
    contract = LiveSingleAgentModelProfile.adapterContract(for: .recorded)
  }

  public var callCount: Int { calls }

  public func complete(_ request: LiveEpisodeModelAdapterRequest) async
    -> LiveEpisodeModelAdapterResult
  {
    guard request.reservation == contract.perInvocationReservation,
      request.disclosureClass == .synthetic,
      request.purpose == LiveSingleAgentModelProfile.purpose,
      let prompt = prompts.first(where: {
        $0.input == request.input
          && $0.inputSHA256 == LiveStrictIntentParser.sha256(of: request.input)
      })
    else {
      return result(
        request,
        .invalidEvidence("Recorded transport не знает точный model-only input.")
      )
    }
    guard completedInvocationIDs.insert(request.invocationID).inserted else {
      return result(
        request,
        .invalidEvidence("Recorded adapter не допускает повторный provider-вызов.")
      )
    }
    calls += 1
    let outputTokens: Int64 = 192
    return result(
      request,
      .completed(
        output: prompt.expectedOutput,
        charged: LiveBudget(
          calls: 1,
          inputTokens: prompt.inputTokens,
          outputTokens: outputTokens,
          wallClockMilliseconds: 25,
          computeUnits: 25,
          moneyMicrounits: 0
        )
      )
    )
  }

  private func result(
    _ request: LiveEpisodeModelAdapterRequest,
    _ outcome: LiveEpisodeModelAdapterOutcome
  ) -> LiveEpisodeModelAdapterResult {
    LiveEpisodeModelAdapterResult(
      invocationID: request.invocationID,
      inputSHA256: LiveStrictIntentParser.sha256(of: request.input),
      providerIdentity: contract.providerIdentity,
      outcome: outcome
    )
  }
}
