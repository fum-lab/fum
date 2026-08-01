import Foundation
import Testing

@testable import FUMPureModelStep

@Suite("Исполнимый бюджет model-only-профиля")
struct BudgetedModelOnlyAdapterTests {
  @Test("Версионный профиль независимо сохраняет режим, identity, disclosure и все пределы")
  func profileRoundTripPreservesIndependentAuthority() throws {
    var original = profile()
    original = ModelOnlyBudgetProfile(
      schemaVersion: original.schemaVersion,
      profileID: original.profileID,
      executionMode: .remote,
      providerIdentity: original.providerIdentity,
      providerInterfaceID: original.providerInterfaceID,
      endpoint: "https://provider.invalid/v1/chat",
      modelIdentity: original.modelIdentity,
      runtimeIdentity: original.runtimeIdentity,
      tokenizerIdentity: original.tokenizerIdentity,
      tokenizationMethod: original.tokenizationMethod,
      computeUnit: original.computeUnit,
      moneyUnit: original.moneyUnit,
      disclosure: original.disclosure,
      maximumBudget: original.maximumBudget,
      perInvocationReservation: original.perInvocationReservation,
      maxOutputTokens: original.maxOutputTokens,
      durability: .processMemory
    )

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ModelOnlyBudgetProfile.self, from: encoded)

    #expect(decoded == original)
    #expect(decoded.executionMode == .remote)
    #expect(decoded.disclosure.allowedClasses == [.synthetic])
    #expect(decoded.disclosure.allowedPurposes == ["model_only_reasoning"])
    #expect(decoded.disclosure.maxInputBytes == 128)
    #expect(
      decoded.maximumBudget
        == budget(calls: 2, input: 128, output: 8, time: 2_000, compute: 200, money: 0))
    #expect(decoded.computeUnit == .wallClockMillisecond)
    #expect(decoded.moneyUnit == .none)
  }

  @Test("Неизвестные поля профиля и вложенной disclosure-политики отклоняются")
  func authorityProfileRejectsUnknownFields() throws {
    let encoded = try JSONEncoder().encode(profile())
    var topLevel = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    topLevel["allow_network"] = true
    let topLevelData = try JSONSerialization.data(withJSONObject: topLevel)

    var nested = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    var disclosure = try #require(nested["disclosure"] as? [String: Any])
    disclosure["allow_secrets"] = true
    nested["disclosure"] = disclosure
    let nestedData = try JSONSerialization.data(withJSONObject: nested)

    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(ModelOnlyBudgetProfile.self, from: topLevelData)
    }
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(ModelOnlyBudgetProfile.self, from: nestedData)
    }

    for key in ["runtime_identity", "maximum_budget", "per_invocation_reservation"] {
      var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
      var nestedObject = try #require(object[key] as? [String: Any])
      nestedObject["allow_override"] = true
      object[key] = nestedObject
      let data = try JSONSerialization.data(withJSONObject: object)
      #expect(throws: (any Error).self) {
        try JSONDecoder().decode(ModelOnlyBudgetProfile.self, from: data)
      }
    }
  }

  @Test("Абсолютные prehash-пределы метаданных закрываются до SHA, ledger и provider")
  func oversizedMetadataIsRejectedBeforeCanonicalization() async {
    let huge = String(repeating: "x", count: 4_194_304)
    let base = profile()
    let oversizedProfile = ModelOnlyBudgetProfile(
      schemaVersion: base.schemaVersion,
      profileID: huge,
      executionMode: base.executionMode,
      providerIdentity: base.providerIdentity,
      providerInterfaceID: base.providerInterfaceID,
      endpoint: base.endpoint,
      modelIdentity: base.modelIdentity,
      runtimeIdentity: base.runtimeIdentity,
      tokenizerIdentity: base.tokenizerIdentity,
      tokenizationMethod: base.tokenizationMethod,
      computeUnit: base.computeUnit,
      moneyUnit: base.moneyUnit,
      disclosure: base.disclosure,
      maximumBudget: base.maximumBudget,
      perInvocationReservation: base.perInvocationReservation,
      maxOutputTokens: base.maxOutputTokens,
      durability: base.durability
    )
    let oversizedInvocation = BudgetedModelOnlyInvocation(
      invocationID: huge,
      input: "hello",
      disclosureClass: .synthetic,
      purpose: "model_only_reasoning"
    )

    for (index, candidate) in [
      (oversizedProfile, invocation(id: "bounded-id")),
      (base, oversizedInvocation),
    ].enumerated() {
      let tokenizer = RecordingTokenizer(tokens: 8)
      let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
      let adapter = makeAdapter(
        profile: candidate.0,
        tokenizer: tokenizer,
        transport: transport
      )

      let result = await adapter.complete(candidate.1)

      #expect(result.failure?.code == (index == 0 ? .invalidProfile : .disclosureDenied))
      #expect(result.requestSHA256 == nil)
      #expect(result.invocationID == (index == 0 ? "bounded-id" : "invalid-invocation"))
      #expect(await tokenizer.callCount() == 0)
      #expect(await transport.callCount() == 0)
      #expect(await adapter.budgetSnapshot().charged == .zero)
    }
  }

  @Test("Remote профиль сериализуется, но adapter закрывает не реализованный transport")
  func remoteExecutionIsNotImplemented() async {
    let base = profile()
    let remote = ModelOnlyBudgetProfile(
      schemaVersion: base.schemaVersion,
      profileID: "remote-fixture",
      executionMode: .remote,
      providerIdentity: "remote-provider",
      providerInterfaceID: "remote.chat.v1",
      endpoint: "https://provider.invalid/chat",
      modelIdentity: base.modelIdentity,
      runtimeIdentity: base.runtimeIdentity,
      tokenizerIdentity: base.tokenizerIdentity,
      tokenizationMethod: base.tokenizationMethod,
      computeUnit: base.computeUnit,
      moneyUnit: .usdMicrounit,
      disclosure: base.disclosure,
      maximumBudget: base.maximumBudget,
      perInvocationReservation: base.perInvocationReservation,
      maxOutputTokens: base.maxOutputTokens,
      durability: base.durability
    )
    let tokenizer = RecordingTokenizer(tokens: 8)
    let transport = RecordingBudgetTransport(
      capability: ModelOnlyProviderCapability(
        executionMode: .remote,
        providerIdentity: remote.providerIdentity,
        providerInterfaceID: remote.providerInterfaceID,
        endpoint: remote.endpoint,
        tokenizerIdentity: remote.tokenizerIdentity,
        maxOutputTokenField: "max_tokens",
        trustedUsageSource: .structuredProviderResponse
      ),
      outcomes: [.completed(response())]
    )
    let adapter = makeAdapter(profile: remote, tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(invocation(id: "remote-not-implemented"))

    #expect(result.failure?.code == .invalidProfile)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
  }

  @Test("Запрещённое раскрытие закрывается до tokenizer, reservation и provider")
  func disclosureDenialDoesNotReachProvider() async {
    let tokenizer = RecordingTokenizer(tokens: 8)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(
      invocation(id: "denied", dataClass: .userData, purpose: "model_only_reasoning")
    )
    let snapshot = await adapter.budgetSnapshot()

    #expect(result.failure?.code == .disclosureDenied)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
    #expect(snapshot.reserved == .zero)
    #expect(snapshot.charged == .zero)
  }

  @Test("Запрещённое назначение закрывается до tokenizer, reservation и provider")
  func disclosurePurposeDenialDoesNotReachProvider() async {
    let tokenizer = RecordingTokenizer(tokens: 8)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(
      invocation(id: "denied-purpose", purpose: "unapproved")
    )

    #expect(result.failure?.code == .disclosureDenied)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
    #expect(await adapter.budgetSnapshot().charged == .zero)
  }

  @Test("Точный max_tokens передаётся provider, а trusted usage согласует reservation")
  func exactOutputCapAndTrustedUsageReconcileReservation() async throws {
    let tokenizer = RecordingTokenizer(tokens: 10)
    let transport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(
            text:
              #"{"usage":{"completion_tokens":999999},"reservation":"released","max_tokens":999999}"#,
            usage: ProviderTokenUsage(inputTokens: 10, outputTokens: 3, totalTokens: 13),
            elapsedMilliseconds: 40
          )
        )
      ]
    )
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(invocation(id: "success"))
    let requests = await transport.recordedRequests()
    let snapshot = await adapter.budgetSnapshot()
    let encodedAttempt = try JSONEncoder().encode(result)
    let attemptObject = try #require(
      JSONSerialization.jsonObject(with: encodedAttempt) as? [String: Any]
    )

    #expect(result.status == .completed)
    #expect(
      result.output
        == #"{"usage":{"completion_tokens":999999},"reservation":"released","max_tokens":999999}"#
    )
    #expect(result.providerUsage?.inputTokens == 10)
    #expect(result.providerUsage?.outputTokens == 3)
    #expect(result.providerUsage?.source == .structuredProviderResponse)
    #expect(requests.count == 1)
    #expect(requests.first?.maxOutputTokens == 4)
    #expect(requests.first?.maxOutputTokenField == "max_tokens")
    #expect(snapshot.reserved == .zero)
    #expect(
      snapshot.charged == budget(calls: 1, input: 10, output: 3, time: 40, compute: 40, money: 0))
    #expect(result.settlement?.kind == .reconciledWithMeasuredLocalCompute)
    #expect(result.providerResponseSHA256 == "sha256:" + String(repeating: "a", count: 64))
    #expect(attemptObject["schema_version"] as? Int == 2)
    #expect(attemptObject["schemaVersion"] == nil)
  }

  @Test("Отсутствие usage удерживает максимум и replay не вызывает provider повторно")
  func missingUsageKeepsReservationAndReplayIsIdempotent() async {
    let transport = RecordingBudgetTransport(
      outcomes: [.completed(response(usage: nil, elapsedMilliseconds: 20))]
    )
    let adapter = makeAdapter(transport: transport)
    let request = invocation(id: "missing-usage")

    let first = await adapter.complete(request)
    let second = await adapter.complete(request)
    let snapshot = await adapter.budgetSnapshot()

    #expect(first.failure?.code == .providerUsageMissing)
    #expect(second == first)
    #expect(await transport.callCount() == 1)
    #expect(snapshot.reserved == .zero)
    #expect(snapshot.charged == profile().perInvocationReservation)
    #expect(first.settlement?.kind == .conservativeFullReservation)
  }

  @Test("Терминальный replay сохраняется в ledger между экземплярами adapter")
  func replaySurvivesAdapterRecreation() async {
    let sharedLedger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
    let transport = RecordingBudgetTransport(
      outcomes: [.completed(response()), .completed(response(text: "must-not-run"))]
    )
    let request = invocation(id: "cross-adapter-replay")
    let firstAdapter = makeAdapter(transport: transport, ledger: sharedLedger)
    let first = await firstAdapter.complete(request)
    let afterFirst = await firstAdapter.budgetSnapshot()
    let secondAdapter = makeAdapter(transport: transport, ledger: sharedLedger)

    let second = await secondAdapter.complete(request)

    #expect(second == first)
    #expect(await transport.callCount() == 1)
    #expect(await secondAdapter.budgetSnapshot() == afterFirst)
  }

  @Test("Одинаковый concurrent invocation линеаризуется ledger и не портит владельца")
  func concurrentSameInvocationIsLinearizedByLedger() async {
    let ledger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
    let transport = GatedBudgetTransport()
    let firstAdapter = makeAdapter(transport: transport, ledger: ledger)
    let secondAdapter = makeAdapter(transport: transport, ledger: ledger)
    let request = invocation(id: "same-active-id")

    let firstTask = Task { await firstAdapter.complete(request) }
    while await transport.callCount() == 0 {
      await Task.yield()
    }
    let concurrent = await secondAdapter.complete(request)
    await transport.release(with: .completed(response()))
    let first = await firstTask.value
    let replayAdapter = makeAdapter(transport: transport, ledger: ledger)
    let replay = await replayAdapter.complete(request)

    #expect(concurrent.failure?.code == .invocationInProgress)
    #expect(first.status == .completed)
    #expect(replay == first)
    #expect(await transport.callCount() == 1)
  }

  @Test("Тайм-аут и частичный ответ имеют разные терминальные исходы и не повторяются")
  func timeoutAndPartialResponseAreDistinctConservativeTerminals() async {
    let timeoutTransport = RecordingBudgetTransport(outcomes: [.timedOut])
    let partialTransport = RecordingBudgetTransport(outcomes: [.partialResponse])
    let timeoutAdapter = makeAdapter(transport: timeoutTransport)
    let partialAdapter = makeAdapter(transport: partialTransport)

    let timeout = await timeoutAdapter.complete(invocation(id: "timeout"))
    let partial = await partialAdapter.complete(invocation(id: "partial"))
    _ = await timeoutAdapter.complete(invocation(id: "timeout"))
    _ = await partialAdapter.complete(invocation(id: "partial"))

    #expect(timeout.failure?.code == .providerTimedOut)
    #expect(partial.failure?.code == .providerPartialResponse)
    #expect(timeout.failure?.retryable == false)
    #expect(partial.failure?.retryable == false)
    #expect(await timeoutTransport.callCount() == 1)
    #expect(await partialTransport.callCount() == 1)
    #expect(await timeoutAdapter.budgetSnapshot().charged == profile().perInvocationReservation)
    #expect(await partialAdapter.budgetSnapshot().charged == profile().perInvocationReservation)
  }

  @Test("Неподдерживаемый output limit закрывается без reservation и provider")
  func unsupportedOutputLimitFailsClosed() async {
    let transport = RecordingBudgetTransport(
      capability: capability(maxOutputTokenField: nil),
      outcomes: [.completed(response())]
    )
    let adapter = makeAdapter(transport: transport)

    let result = await adapter.complete(invocation(id: "unsupported-capability"))
    let snapshot = await adapter.budgetSnapshot()

    #expect(result.failure?.code == .unsupportedOutputTokenLimit)
    #expect(await transport.callCount() == 0)
    #expect(snapshot == ModelOnlyBudgetSnapshot(maximum: profile().maximumBudget))
  }

  @Test("Неверное имя output-поля и отсутствие trusted usage закрываются до provider")
  func incompleteCapabilitiesFailClosed() async {
    let capabilities = [
      ModelOnlyProviderCapability(
        executionMode: .local,
        providerIdentity: "lmstudio",
        providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
        endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
        tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
        maxOutputTokenField: "max_completion_tokens",
        trustedUsageSource: .structuredProviderResponse
      ),
      ModelOnlyProviderCapability(
        executionMode: .local,
        providerIdentity: "lmstudio",
        providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
        endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
        tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
        maxOutputTokenField: "max_tokens",
        trustedUsageSource: nil
      ),
    ]

    for (index, capability) in capabilities.enumerated() {
      let tokenizer = RecordingTokenizer(tokens: 8)
      let transport = RecordingBudgetTransport(
        capability: capability,
        outcomes: [.completed(response())]
      )
      let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)
      let result = await adapter.complete(invocation(id: "incomplete-capability-\(index)"))

      #expect(result.failure?.code == .unsupportedOutputTokenLimit)
      #expect(await tokenizer.callCount() == 0)
      #expect(await transport.callCount() == 0)
    }
  }

  @Test("Локальный профиль с ненулевой ценой закрывается до tokenizer и provider")
  func localMoneyMustBeExactlyZero() async {
    let base = profile()
    let paidBudget = budget(
      calls: 2,
      input: 128,
      output: 8,
      time: 2_000,
      compute: 200,
      money: 1
    )
    let paidReservation = budget(
      calls: 1,
      input: 64,
      output: 4,
      time: 1_000,
      compute: 100,
      money: 1
    )
    let paidProfile = ModelOnlyBudgetProfile(
      schemaVersion: base.schemaVersion,
      profileID: base.profileID,
      executionMode: base.executionMode,
      providerIdentity: base.providerIdentity,
      providerInterfaceID: base.providerInterfaceID,
      endpoint: base.endpoint,
      modelIdentity: base.modelIdentity,
      runtimeIdentity: base.runtimeIdentity,
      tokenizerIdentity: base.tokenizerIdentity,
      tokenizationMethod: base.tokenizationMethod,
      computeUnit: base.computeUnit,
      moneyUnit: .none,
      disclosure: base.disclosure,
      maximumBudget: paidBudget,
      perInvocationReservation: paidReservation,
      maxOutputTokens: base.maxOutputTokens,
      durability: base.durability
    )
    let tokenizer = RecordingTokenizer(tokens: 8)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(
      profile: paidProfile,
      tokenizer: tokenizer,
      transport: transport
    )

    let result = await adapter.complete(invocation(id: "paid-local"))

    #expect(result.failure?.code == .invalidProfile)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
  }

  @Test("Режим, provider, интерфейс и endpoint capability должны совпасть точно")
  func capabilityAuthorityMustMatchExactly() async {
    let expected = capability()
    let mismatches = [
      ModelOnlyProviderCapability(
        executionMode: .remote,
        providerIdentity: expected.providerIdentity,
        providerInterfaceID: expected.providerInterfaceID,
        endpoint: expected.endpoint,
        tokenizerIdentity: expected.tokenizerIdentity,
        maxOutputTokenField: expected.maxOutputTokenField,
        trustedUsageSource: expected.trustedUsageSource
      ),
      ModelOnlyProviderCapability(
        executionMode: expected.executionMode,
        providerIdentity: "other",
        providerInterfaceID: expected.providerInterfaceID,
        endpoint: expected.endpoint,
        tokenizerIdentity: expected.tokenizerIdentity,
        maxOutputTokenField: expected.maxOutputTokenField,
        trustedUsageSource: expected.trustedUsageSource
      ),
      ModelOnlyProviderCapability(
        executionMode: expected.executionMode,
        providerIdentity: expected.providerIdentity,
        providerInterfaceID: "other-interface",
        endpoint: expected.endpoint,
        tokenizerIdentity: expected.tokenizerIdentity,
        maxOutputTokenField: expected.maxOutputTokenField,
        trustedUsageSource: expected.trustedUsageSource
      ),
      ModelOnlyProviderCapability(
        executionMode: expected.executionMode,
        providerIdentity: expected.providerIdentity,
        providerInterfaceID: expected.providerInterfaceID,
        endpoint: "http://127.0.0.1:4321/api/v0/chat/completions",
        tokenizerIdentity: expected.tokenizerIdentity,
        maxOutputTokenField: expected.maxOutputTokenField,
        trustedUsageSource: expected.trustedUsageSource
      ),
    ]

    for (index, mismatch) in mismatches.enumerated() {
      let tokenizer = RecordingTokenizer(tokens: 8)
      let transport = RecordingBudgetTransport(
        capability: mismatch,
        outcomes: [.completed(response())]
      )
      let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)
      let result = await adapter.complete(invocation(id: "authority-mismatch-\(index)"))

      #expect(result.failure?.code == .providerIdentityMismatch)
      #expect(await tokenizer.callCount() == 0)
      #expect(await transport.callCount() == 0)
    }
  }

  @Test("Tokenizer должен быть закреплён за тем же provider-интерфейсом")
  func incompatibleTokenizerFailsBeforeReservation() async {
    let tokenizer = RecordingTokenizer(tokens: 8, identity: "other-tokenizer")
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(invocation(id: "tokenizer-mismatch"))

    #expect(result.failure?.code == .tokenizerIdentityMismatch)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
    #expect(await adapter.budgetSnapshot().charged == .zero)
  }

  @Test("Метод tokenizer закреплён профилем и не может меняться неявно")
  func tokenizerMethodMismatchFailsBeforeReservation() async {
    let tokenizer = RecordingTokenizer(tokens: 8, method: .conservativeUpperBound)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(invocation(id: "tokenizer-method-mismatch"))

    #expect(result.failure?.code == .tokenizerIdentityMismatch)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
    #expect(await adapter.budgetSnapshot().charged == .zero)
  }

  @Test("Предварительная токенизация выше reservation отменяет его до inference")
  func inputTokenPreflightCannotExceedReservation() async {
    let tokenizer = RecordingTokenizer(tokens: 65)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)

    let result = await adapter.complete(invocation(id: "input-over-limit"))
    let snapshot = await adapter.budgetSnapshot()

    #expect(result.failure?.code == .inputTokenLimitExceeded)
    #expect(await transport.callCount() == 0)
    #expect(snapshot.reserved == .zero)
    #expect(snapshot.charged == .zero)
  }

  @Test("Provider usage не может повысить профильный предел выхода")
  func providerCannotRaiseOutputLimit() async {
    let transport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(usage: ProviderTokenUsage(inputTokens: 8, outputTokens: 5, totalTokens: 13))
        )
      ]
    )
    let adapter = makeAdapter(transport: transport)

    let result = await adapter.complete(invocation(id: "output-over-limit"))

    #expect(result.failure?.code == .providerUsageInconsistent)
    #expect(result.providerUsage == nil)
    #expect(await adapter.budgetSnapshot().charged == profile().perInvocationReservation)
  }

  @Test("Exact pretokenization обязана равняться provider prompt_tokens")
  func providerInputUsageMustMatchExactTokenization() async {
    let ledger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
    let transport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(usage: ProviderTokenUsage(inputTokens: 7, outputTokens: 2, totalTokens: 9))
        ),
        .completed(response()),
      ]
    )
    let request = invocation(id: "tokenization-usage-mismatch")
    let firstAdapter = makeAdapter(transport: transport, ledger: ledger)
    let first = await firstAdapter.complete(request)
    let replayAdapter = makeAdapter(transport: transport, ledger: ledger)
    let replay = await replayAdapter.complete(request)

    #expect(first.failure?.code == .providerUsageInconsistent)
    #expect(first.settlement?.kind == .conservativeFullReservation)
    #expect(replay == first)
    #expect(await transport.callCount() == 1)
  }

  @Test("Malformed response-body digest закрывает успешный usage консервативно")
  func malformedRawResponseDigestFailsClosed() async {
    let transport = RecordingBudgetTransport(
      outcomes: [.completed(response(responseBodySHA256: "sha256:not-a-digest"))]
    )
    let adapter = makeAdapter(transport: transport)

    let result = await adapter.complete(invocation(id: "bad-raw-hash"))

    #expect(result.failure?.code == .providerUsageInconsistent)
    #expect(result.settlement?.kind == .conservativeFullReservation)
    #expect(await adapter.budgetSnapshot().charged == profile().perInvocationReservation)
  }

  @Test("Несовпадение фактической модели или runtime удерживает полный reservation")
  func providerResponseIdentityMismatchIsConservative() async {
    let mismatches = [
      response(modelIdentity: "other/model"),
      response(runtimeIdentity: ModelOnlyRuntimeIdentity(name: "other-runtime", version: "1")),
    ]
    for (index, mismatch) in mismatches.enumerated() {
      let transport = RecordingBudgetTransport(outcomes: [.completed(mismatch)])
      let adapter = makeAdapter(transport: transport)

      let result = await adapter.complete(invocation(id: "response-identity-\(index)"))

      #expect(result.failure?.code == .providerIdentityMismatch)
      #expect(result.settlement?.kind == .conservativeFullReservation)
      #expect(await adapter.budgetSnapshot().charged == profile().perInvocationReservation)
    }
  }

  @Test("Повтор invocation с другим входом конфликтует и не списывает бюджет второй раз")
  func replayWithDifferentInputIsAConflict() async {
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(transport: transport)
    let first = invocation(id: "same-id")
    let conflicting = BudgetedModelOnlyInvocation(
      invocationID: "same-id",
      input: "different",
      disclosureClass: .synthetic,
      purpose: "model_only_reasoning"
    )

    let completed = await adapter.complete(first)
    let conflict = await adapter.complete(conflicting)

    #expect(completed.status == .completed)
    #expect(conflict.failure?.code == .invocationConflict)
    #expect(await transport.callCount() == 1)
    #expect(await adapter.budgetSnapshot().charged.calls == 1)
  }

  @Test("Превышение разрешённого объёма раскрытия не вызывает tokenizer и provider")
  func disclosureVolumeIsCheckedBeforeProvider() async {
    let tokenizer = RecordingTokenizer(tokens: 8)
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(tokenizer: tokenizer, transport: transport)
    let request = BudgetedModelOnlyInvocation(
      invocationID: "too-many-bytes",
      input: String(repeating: "x", count: 4_194_304),
      disclosureClass: .synthetic,
      purpose: "model_only_reasoning"
    )

    let result = await adapter.complete(request)

    #expect(result.failure?.code == .disclosureDenied)
    #expect(result.requestSHA256 == nil)
    #expect(await tokenizer.callCount() == 0)
    #expect(await transport.callCount() == 0)
    #expect(await adapter.budgetSnapshot().charged == .zero)
  }

  @Test("Каждое измерение бюджета проверяется до provider-вызова")
  func everyBudgetDimensionIsAffordableBeforeProvider() async {
    let reservation = profile().perInvocationReservation
    let insufficient = [
      budget(calls: 0, input: 64, output: 4, time: 1_000, compute: 100, money: 0),
      budget(calls: 1, input: 63, output: 4, time: 1_000, compute: 100, money: 0),
      budget(calls: 1, input: 64, output: 3, time: 1_000, compute: 100, money: 0),
      budget(calls: 1, input: 64, output: 4, time: 999, compute: 100, money: 0),
      budget(calls: 1, input: 64, output: 4, time: 1_000, compute: 99, money: 0),
      budget(calls: 1, input: 64, output: 4, time: 1_000, compute: 100, money: 9),
    ]

    for (index, maximum) in insufficient.enumerated() {
      var candidate = profile(maximumBudget: maximum, reservation: reservation)
      if index == 5 {
        candidate = profile(
          maximumBudget: maximum,
          reservation: budget(calls: 1, input: 64, output: 4, time: 1_000, compute: 100, money: 10)
        )
      }
      let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
      let adapter = makeAdapter(profile: candidate, transport: transport)

      let result = await adapter.complete(invocation(id: "insufficient-\(index)"))

      #expect(result.failure?.code == .budgetInsufficient)
      #expect(await transport.callCount() == 0)
      #expect(await adapter.budgetSnapshot().charged == .zero)
    }
  }

  @Test("Два параллельных вызова атомарно делят один доступный reservation")
  func concurrentReservationsAreLinearized() async {
    let oneCallProfile = profile(
      maximumBudget: profile().perInvocationReservation,
      reservation: profile().perInvocationReservation
    )
    let transport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(usage: ProviderTokenUsage(inputTokens: 8, outputTokens: 2, totalTokens: 10)))
      ]
    )
    let adapter = makeAdapter(profile: oneCallProfile, transport: transport)

    async let first = adapter.complete(invocation(id: "parallel-a"))
    async let second = adapter.complete(invocation(id: "parallel-b"))
    let results = await [first, second]

    #expect(results.filter { $0.status == .completed }.count == 1)
    #expect(results.filter { $0.failure?.code == .budgetInsufficient }.count == 1)
    #expect(await transport.callCount() == 1)
  }

  @Test("Отрицательные, переполненные и несогласованные счётчики различимы")
  func arithmeticFailuresAreDistinct() async {
    let negativeProfile = profile(
      maximumBudget: budget(calls: -1, input: 128, output: 8, time: 2_000, compute: 200, money: 0)
    )
    let negativeAdapter = makeAdapter(profile: negativeProfile)
    let overflowTransport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(
            usage: ProviderTokenUsage(
              inputTokens: .max,
              outputTokens: 1,
              totalTokens: .max
            )
          )
        )
      ]
    )
    let overflowAdapter = makeAdapter(transport: overflowTransport)
    let inconsistentLedger = VolatileModelBudgetLedger(
      maximum: profile().maximumBudget,
      initialCharged: profile().maximumBudget,
      initialReserved: profile().perInvocationReservation
    )
    let inconsistentAdapter = makeAdapter(ledger: inconsistentLedger)

    let negative = await negativeAdapter.complete(invocation(id: "negative"))
    let overflow = await overflowAdapter.complete(invocation(id: "overflow"))
    let inconsistent = await inconsistentAdapter.complete(invocation(id: "inconsistent"))

    #expect(negative.failure?.code == .negativeBudgetValue)
    #expect(overflow.failure?.code == .budgetArithmeticOverflow)
    #expect(inconsistent.failure?.code == .budgetCountersInconsistent)
  }

  @Test("Negative, overflow и inconsistent остаются терминальными между adapter")
  func arithmeticTerminalsReplayAcrossAdapters() async {
    let cases: [(String, ModelOnlyProviderResponse, ModelOnlyBudgetFailureCode)] = [
      (
        "negative-replay",
        response(usage: ProviderTokenUsage(inputTokens: -1, outputTokens: 1, totalTokens: 0)),
        .negativeBudgetValue
      ),
      (
        "overflow-replay",
        response(
          usage: ProviderTokenUsage(inputTokens: .max, outputTokens: 1, totalTokens: .max)
        ),
        .budgetArithmeticOverflow
      ),
      (
        "inconsistent-replay",
        response(usage: ProviderTokenUsage(inputTokens: 8, outputTokens: 2, totalTokens: 11)),
        .providerUsageInconsistent
      ),
    ]

    for (id, providerResponse, expectedCode) in cases {
      let ledger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
      let transport = RecordingBudgetTransport(
        outcomes: [.completed(providerResponse), .completed(response())]
      )
      let firstAdapter = makeAdapter(transport: transport, ledger: ledger)
      let first = await firstAdapter.complete(invocation(id: id))
      let secondAdapter = makeAdapter(transport: transport, ledger: ledger)
      let second = await secondAdapter.complete(invocation(id: id))

      #expect(first.failure?.code == expectedCode)
      #expect(second == first)
      #expect(await transport.callCount() == 1)
      #expect(await secondAdapter.budgetSnapshot().charged == profile().perInvocationReservation)
    }
  }

  @Test("Transport failures становятся консервативными terminal snapshots ledger")
  func transportFailuresSettleAndReplayAcrossAdapters() async {
    let cases: [(String, ModelOnlyProviderTransportOutcome, ModelOnlyBudgetFailureCode)] = [
      ("wire-overflow", .arithmeticOverflow, .budgetArithmeticOverflow),
      ("invalid-json-schema", .invalidResponse, .providerUsageInconsistent),
      ("too-large", .responseTooLarge, .providerResponseTooLarge),
      ("provider-failed", .failed, .providerFailed),
    ]

    for (id, outcome, expectedCode) in cases {
      let ledger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
      let transport = RecordingBudgetTransport(
        outcomes: [outcome, .completed(response())]
      )
      let firstAdapter = makeAdapter(transport: transport, ledger: ledger)
      let first = await firstAdapter.complete(invocation(id: id))
      let replayAdapter = makeAdapter(transport: transport, ledger: ledger)
      let replay = await replayAdapter.complete(invocation(id: id))

      #expect(first.failure?.code == expectedCode)
      #expect(first.failure?.retryable == false)
      #expect(first.settlement?.kind == .conservativeFullReservation)
      #expect(replay == first)
      #expect(await transport.callCount() == 1)
      #expect(await replayAdapter.budgetSnapshot().charged == profile().perInvocationReservation)
    }
  }

  @Test("Отрицательные tokenizer и elapsed имеют типизированные terminal outcomes")
  func negativePreflightAndElapsedAreTyped() async {
    let tokenizerLedger = VolatileModelBudgetLedger(maximum: profile().maximumBudget)
    let negativeTokenizer = RecordingTokenizer(tokens: -1)
    let tokenizerTransport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let tokenizerAdapter = makeAdapter(
      tokenizer: negativeTokenizer,
      transport: tokenizerTransport,
      ledger: tokenizerLedger
    )
    let tokenizerRequest = invocation(id: "negative-tokenizer")
    let tokenizerFailure = await tokenizerAdapter.complete(tokenizerRequest)
    let tokenizerReplay = await makeAdapter(
      tokenizer: negativeTokenizer,
      transport: tokenizerTransport,
      ledger: tokenizerLedger
    ).complete(tokenizerRequest)

    #expect(tokenizerFailure.failure?.code == .negativeBudgetValue)
    #expect(tokenizerFailure.settlement?.charged.calls == 0)
    #expect(tokenizerFailure.settlement?.charged.inputTokens == 0)
    #expect(tokenizerFailure.settlement?.charged.outputTokens == 0)
    #expect(tokenizerReplay == tokenizerFailure)
    #expect(await tokenizerTransport.callCount() == 0)

    let elapsedTransport = RecordingBudgetTransport(
      outcomes: [.completed(response(elapsedMilliseconds: -1))]
    )
    let elapsedAdapter = makeAdapter(transport: elapsedTransport)
    let elapsedFailure = await elapsedAdapter.complete(invocation(id: "negative-elapsed"))

    #expect(elapsedFailure.failure?.code == .negativeBudgetValue)
    #expect(elapsedFailure.settlement?.kind == .conservativeFullReservation)
  }

  @Test("Provider usage с неверной суммой не принимается и удерживает reservation")
  func inconsistentProviderUsageIsTyped() async {
    let transport = RecordingBudgetTransport(
      outcomes: [
        .completed(
          response(usage: ProviderTokenUsage(inputTokens: 8, outputTokens: 2, totalTokens: 11))
        )
      ]
    )
    let adapter = makeAdapter(transport: transport)

    let result = await adapter.complete(invocation(id: "bad-usage"))

    #expect(result.failure?.code == .providerUsageInconsistent)
    #expect(await adapter.budgetSnapshot().charged == profile().perInvocationReservation)
  }

  @Test("Ожидание и чтение snapshot не меняют счётчики")
  func waitingDoesNotSpendBudget() async {
    let adapter = makeAdapter()

    let before = await adapter.budgetSnapshot()
    await Task.yield()
    let after = await adapter.budgetSnapshot()

    #expect(after == before)
    #expect(after.charged == .zero)
    #expect(after.reserved == .zero)
  }

  @Test("Tokenizer расходует общий deadline до provider-вызова")
  func tokenizationReducesProviderDeadline() async {
    let clock = SequenceModelOnlyClock(values: [0, 40])
    let transport = RecordingBudgetTransport(
      outcomes: [.completed(response(elapsedMilliseconds: 50))]
    )
    let adapter = makeAdapter(transport: transport, clock: clock)

    let result = await adapter.complete(invocation(id: "shared-deadline"))
    let request = await transport.recordedRequests().first

    #expect(request?.timeoutMilliseconds == 60)
    #expect(result.settlement?.charged.wallClockMilliseconds == 90)
    #expect(result.settlement?.charged.computeUnits == 90)
  }

  @Test("Общий monotonic clock закрывает лживое малое elapsed от transport")
  func overallClockEnforcesDeadlineAfterTransport() async {
    let clock = SequenceModelOnlyClock(values: [0, 10, 150])
    let transport = RecordingBudgetTransport(
      outcomes: [.completed(response(elapsedMilliseconds: 1))]
    )
    let adapter = makeAdapter(transport: transport, clock: clock)

    let result = await adapter.complete(invocation(id: "lying-transport-clock"))

    #expect(result.failure?.code == .providerTimedOut)
    #expect(result.settlement?.kind == .conservativeFullReservation)
    #expect(await adapter.budgetSnapshot().charged == profile().perInvocationReservation)
  }

  @Test("Исчерпавшая deadline токенизация не вызывает provider")
  func tokenizationCanExhaustDeadline() async {
    let clock = SequenceModelOnlyClock(values: [0, 100])
    let transport = RecordingBudgetTransport(outcomes: [.completed(response())])
    let adapter = makeAdapter(transport: transport, clock: clock)

    let result = await adapter.complete(invocation(id: "tokenizer-timeout"))

    #expect(result.failure?.code == .providerTimedOut)
    #expect(await transport.callCount() == 0)
    #expect(result.settlement?.kind == .conservativeFullReservation)
  }

  @Test("Точная аттестация токенизации закрывается на другом входе или модели")
  func pinnedExactTokenizationIsInputAndModelSpecific() async throws {
    let attestedProfile = profile()
    let tokenizer = PinnedModelOnlyExactTokenization(
      identity: attestedProfile.tokenizerIdentity,
      providerIdentity: attestedProfile.providerIdentity,
      providerInterfaceID: attestedProfile.providerInterfaceID,
      endpoint: attestedProfile.endpoint,
      modelIdentity: attestedProfile.modelIdentity,
      runtimeIdentity: attestedProfile.runtimeIdentity,
      inputSHA256: "sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
      inputBytes: 5,
      inputTokens: 1
    )
    let wrongRuntimeTokenizer = PinnedModelOnlyExactTokenization(
      identity: attestedProfile.tokenizerIdentity,
      providerIdentity: attestedProfile.providerIdentity,
      providerInterfaceID: attestedProfile.providerInterfaceID,
      endpoint: attestedProfile.endpoint,
      modelIdentity: attestedProfile.modelIdentity,
      runtimeIdentity: ModelOnlyRuntimeIdentity(name: "other", version: "1"),
      inputSHA256: "sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
      inputBytes: 5,
      inputTokens: 1
    )

    #expect(try await tokenizer.countInputTokens("hello", profile: attestedProfile) == 1)
    await #expect(throws: ModelOnlyBudgetFailure.self) {
      try await tokenizer.countInputTokens("other", profile: attestedProfile)
    }
    await #expect(throws: ModelOnlyBudgetFailure.self) {
      try await wrongRuntimeTokenizer.countInputTokens("hello", profile: attestedProfile)
    }
  }

  @Test("Публичная exact-аттестация побайтово закреплена за live-фикстурой")
  func publicExactAttestationMatchesLiveFixture() async throws {
    let tokenizer = PinnedModelOnlyExactTokenization.lmStudioQwen3SmallFixtureV1
    let prompt = "Return the single letter A."
    let reservation = budget(
      calls: 1,
      input: 64,
      output: 1,
      time: 120_000,
      compute: 120_000,
      money: 0
    )
    let fixtureProfile = ModelOnlyBudgetProfile(
      schemaVersion: 2,
      profileID: "fum.lm-studio-rest-v0.budgeted.v1.live-fixture",
      executionMode: .local,
      providerIdentity: tokenizer.providerIdentity,
      providerInterfaceID: tokenizer.providerInterfaceID,
      endpoint: tokenizer.endpoint,
      modelIdentity: tokenizer.modelIdentity,
      runtimeIdentity: tokenizer.runtimeIdentity,
      tokenizerIdentity: tokenizer.identity,
      tokenizationMethod: .exact,
      computeUnit: .wallClockMillisecond,
      moneyUnit: .none,
      disclosure: ModelOnlyDisclosurePolicy(
        allowedClasses: [.synthetic],
        maxInputBytes: 64,
        allowedPurposes: ["live_contract_fixture"]
      ),
      maximumBudget: reservation,
      perInvocationReservation: reservation,
      maxOutputTokens: 1,
      durability: .processMemory
    )

    #expect(tokenizer.identity == "lmstudio.rest-v0.qwen3-0.6b.prompt-attestation.v1")
    #expect(tokenizer.providerIdentity == "lmstudio")
    #expect(tokenizer.providerInterfaceID == "lmstudio.rest-api.v0.chat-completions")
    #expect(tokenizer.endpoint == "http://127.0.0.1:1234/api/v0/chat/completions")
    #expect(tokenizer.modelIdentity == "qwen/qwen3-0.6b")
    #expect(tokenizer.runtimeIdentity.name == "llama.cpp-mac-arm64-apple-metal-advsimd")
    #expect(tokenizer.runtimeIdentity.version == "2.27.1")
    #expect(tokenizer.inputBytes == 27)
    #expect(
      tokenizer.inputSHA256
        == "sha256:3b4f065553a72298c43e428be7ac80976181ac641c95bf4c588253fb2c6a203f"
    )
    #expect(try await tokenizer.countInputTokens(prompt, profile: fixtureProfile) == 14)
    await #expect(throws: ModelOnlyBudgetFailure.self) {
      try await tokenizer.countInputTokens("Return the single letter B.", profile: fixtureProfile)
    }
  }

  @Test("Аттестация live-эпизода закрепляет ровно два входа и их profile identity")
  func liveEpisodeExactAttestationAcceptsOnlyPinnedInputs() async throws {
    let tokenizer = PinnedModelOnlyExactTokenization.lmStudioQwen3LiveEpisodeV1
    let promptPrefix =
      String(UnicodeScalar(0x2F)!)
      + "no_think\nReturn exactly the JSON on the next line, byte for byte, with no markdown or explanation.\n"
    let promptA =
      promptPrefix
      + #"{"adapter_id":"fum-git-candidate-v1","arguments_sha256":"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808","effect_class":"isolated-git-write","expected_effect_sha256":"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808","intent_id":"intent-variant-a","object_id":"candidate-artifact","operation":"create_candidate_commit"}"#
    let promptB =
      promptPrefix
      + #"{"adapter_id":"fum-git-candidate-v1","arguments_sha256":"sha256:27747689baf9903c9aae69d82a95e8dcf4254c648ca13e4c9ff49adb1e546bb6","effect_class":"isolated-git-write","expected_effect_sha256":"sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808","intent_id":"intent-variant-b","object_id":"candidate-artifact","operation":"create_candidate_commit"}"#
    let reservation = budget(
      calls: 1,
      input: 256,
      output: 256,
      time: 120_000,
      compute: 120_000,
      money: 0
    )

    func makeProfile(tokenizerIdentity: String) -> ModelOnlyBudgetProfile {
      ModelOnlyBudgetProfile(
        schemaVersion: 2,
        profileID: "fum.lm-studio-rest-v0.budgeted.v1.live-episode",
        executionMode: .local,
        providerIdentity: tokenizer.providerIdentity,
        providerInterfaceID: tokenizer.providerInterfaceID,
        endpoint: tokenizer.endpoint,
        modelIdentity: tokenizer.modelIdentity,
        runtimeIdentity: tokenizer.runtimeIdentity,
        tokenizerIdentity: tokenizerIdentity,
        tokenizationMethod: .exact,
        computeUnit: .wallClockMillisecond,
        moneyUnit: .none,
        disclosure: ModelOnlyDisclosurePolicy(
          allowedClasses: [.synthetic],
          maxInputBytes: 467,
          allowedPurposes: ["live_single_agent_episode"]
        ),
        maximumBudget: reservation,
        perInvocationReservation: reservation,
        maxOutputTokens: 256,
        durability: .processMemory
      )
    }

    let liveProfile = makeProfile(tokenizerIdentity: tokenizer.identity)

    #expect(tokenizer.identity == "lmstudio.rest-v0.qwen3-0.6b.live-episode-attestation.v1")
    #expect(tokenizer.inputAttestationCount == 2)
    #expect(tokenizer.inputBytes == 467)
    #expect(
      tokenizer.inputSHA256
        == "sha256:0ee3d9bd4a4553bdc542c52a8d47b6d08bd672cb1a364877d2bea11cc0795864"
    )
    #expect(promptA.utf8.count == 467)
    #expect(promptB.utf8.count == 467)
    #expect(try await tokenizer.countInputTokens(promptA, profile: liveProfile) == 219)
    #expect(try await tokenizer.countInputTokens(promptB, profile: liveProfile) == 214)
    await #expect(throws: ModelOnlyBudgetFailure.self) {
      try await tokenizer.countInputTokens(promptA + "\n", profile: liveProfile)
    }
    await #expect(throws: ModelOnlyBudgetFailure.self) {
      try await tokenizer.countInputTokens(
        promptA,
        profile: makeProfile(tokenizerIdentity: "unattested-tokenizer")
      )
    }
  }

  private func makeAdapter(
    profile: ModelOnlyBudgetProfile? = nil,
    tokenizer: (any ModelOnlyInputTokenizing)? = nil,
    transport: (any ModelOnlyBudgetTransport)? = nil,
    ledger: VolatileModelBudgetLedger? = nil,
    clock: any ModelOnlyMonotonicClock = FixedModelOnlyClock(value: 0)
  ) -> BudgetedModelOnlyAdapter {
    let selectedProfile = profile ?? self.profile()
    return BudgetedModelOnlyAdapter(
      profile: selectedProfile,
      tokenizer: tokenizer ?? RecordingTokenizer(tokens: 8),
      transport: transport ?? RecordingBudgetTransport(outcomes: [.completed(response())]),
      ledger: ledger ?? VolatileModelBudgetLedger(maximum: selectedProfile.maximumBudget),
      clock: clock
    )
  }

  private func profile(
    maximumBudget: ModelOnlyBudget? = nil,
    reservation: ModelOnlyBudget? = nil
  ) -> ModelOnlyBudgetProfile {
    ModelOnlyBudgetProfile(
      schemaVersion: 2,
      profileID: "fum.lm-studio-rest-v0.budgeted.v1.local-fixture",
      executionMode: .local,
      providerIdentity: "lmstudio",
      providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
      endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
      modelIdentity: "publisher/model/file.gguf",
      runtimeIdentity: ModelOnlyRuntimeIdentity(
        name: "llama.cpp-mac-arm64-apple-metal-advsimd",
        version: "2.27.1"
      ),
      tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
      tokenizationMethod: .exact,
      computeUnit: .wallClockMillisecond,
      moneyUnit: .none,
      disclosure: ModelOnlyDisclosurePolicy(
        allowedClasses: [.synthetic],
        maxInputBytes: 128,
        allowedPurposes: ["model_only_reasoning"]
      ),
      maximumBudget: maximumBudget
        ?? budget(calls: 2, input: 128, output: 8, time: 2_000, compute: 200, money: 0),
      perInvocationReservation: reservation
        ?? budget(calls: 1, input: 64, output: 4, time: 1_000, compute: 100, money: 0),
      maxOutputTokens: 4,
      durability: .processMemory
    )
  }

  private func invocation(
    id: String,
    dataClass: ModelOnlyDisclosureClass = .synthetic,
    purpose: String = "model_only_reasoning"
  ) -> BudgetedModelOnlyInvocation {
    BudgetedModelOnlyInvocation(
      invocationID: id,
      input: "hello",
      disclosureClass: dataClass,
      purpose: purpose
    )
  }

  private func capability(maxOutputTokenField: String? = "max_tokens")
    -> ModelOnlyProviderCapability
  {
    ModelOnlyProviderCapability(
      executionMode: .local,
      providerIdentity: "lmstudio",
      providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
      endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
      tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
      maxOutputTokenField: maxOutputTokenField,
      trustedUsageSource: .structuredProviderResponse
    )
  }

  private func response(
    text: String = "ok",
    usage: ProviderTokenUsage? = ProviderTokenUsage(
      inputTokens: 8,
      outputTokens: 2,
      totalTokens: 10
    ),
    elapsedMilliseconds: Int64 = 25,
    modelIdentity: String = "publisher/model/file.gguf",
    runtimeIdentity: ModelOnlyRuntimeIdentity = ModelOnlyRuntimeIdentity(
      name: "llama.cpp-mac-arm64-apple-metal-advsimd",
      version: "2.27.1"
    ),
    responseBodySHA256: String = "sha256:" + String(repeating: "a", count: 64)
  ) -> ModelOnlyProviderResponse {
    ModelOnlyProviderResponse(
      responseID: "response-1",
      modelIdentity: modelIdentity,
      runtimeIdentity: runtimeIdentity,
      text: text,
      finishReason: "length",
      usage: usage,
      elapsedMilliseconds: elapsedMilliseconds,
      responseBodySHA256: responseBodySHA256
    )
  }

  private func budget(
    calls: Int64,
    input: Int64,
    output: Int64,
    time: Int64,
    compute: Int64,
    money: Int64
  ) -> ModelOnlyBudget {
    ModelOnlyBudget(
      calls: calls,
      inputTokens: input,
      outputTokens: output,
      wallClockMilliseconds: time,
      computeUnits: compute,
      moneyMicrounits: money
    )
  }
}

private actor RecordingTokenizer: ModelOnlyInputTokenizing {
  nonisolated let identity: String
  nonisolated let method: ModelOnlyTokenizationMethod
  private let tokens: Int64
  private var calls = 0

  init(
    tokens: Int64,
    identity: String = "lmstudio.gguf-byte-upper-bound.v1",
    method: ModelOnlyTokenizationMethod = .exact
  ) {
    self.tokens = tokens
    self.identity = identity
    self.method = method
  }

  func countInputTokens(_ input: String, profile: ModelOnlyBudgetProfile) async throws -> Int64 {
    calls += 1
    return tokens
  }

  func callCount() -> Int { calls }
}

private actor RecordingBudgetTransport: ModelOnlyBudgetTransport {
  nonisolated let capability: ModelOnlyProviderCapability
  private var outcomes: [ModelOnlyProviderTransportOutcome]
  private var requests: [ModelOnlyProviderRequest] = []

  init(
    capability: ModelOnlyProviderCapability = ModelOnlyProviderCapability(
      executionMode: .local,
      providerIdentity: "lmstudio",
      providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
      endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
      tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
      maxOutputTokenField: "max_tokens",
      trustedUsageSource: .structuredProviderResponse
    ),
    outcomes: [ModelOnlyProviderTransportOutcome]
  ) {
    self.capability = capability
    self.outcomes = outcomes
  }

  func generate(_ request: ModelOnlyProviderRequest) async -> ModelOnlyProviderTransportOutcome {
    requests.append(request)
    guard !outcomes.isEmpty else { return .failed }
    return outcomes.removeFirst()
  }

  func callCount() -> Int { requests.count }

  func recordedRequests() -> [ModelOnlyProviderRequest] { requests }
}

private actor GatedBudgetTransport: ModelOnlyBudgetTransport {
  nonisolated let capability = ModelOnlyProviderCapability(
    executionMode: .local,
    providerIdentity: "lmstudio",
    providerInterfaceID: "lmstudio.rest-api.v0.chat-completions",
    endpoint: "http://127.0.0.1:1234/api/v0/chat/completions",
    tokenizerIdentity: "lmstudio.gguf-byte-upper-bound.v1",
    maxOutputTokenField: "max_tokens",
    trustedUsageSource: .structuredProviderResponse
  )

  private var calls = 0
  private var continuation: CheckedContinuation<ModelOnlyProviderTransportOutcome, Never>?

  func generate(_ request: ModelOnlyProviderRequest) async -> ModelOnlyProviderTransportOutcome {
    calls += 1
    return await withCheckedContinuation { continuation = $0 }
  }

  func callCount() -> Int { calls }

  func release(with outcome: ModelOnlyProviderTransportOutcome) {
    continuation?.resume(returning: outcome)
    continuation = nil
  }
}

private struct FixedModelOnlyClock: ModelOnlyMonotonicClock {
  let value: UInt64

  func nowMilliseconds() -> UInt64 { value }
}

private final class SequenceModelOnlyClock: ModelOnlyMonotonicClock, @unchecked Sendable {
  private let lock = NSLock()
  private var values: [UInt64]
  private var last: UInt64

  init(values: [UInt64]) {
    self.values = values
    self.last = values.last ?? 0
  }

  func nowMilliseconds() -> UInt64 {
    lock.lock()
    defer { lock.unlock() }
    guard !values.isEmpty else { return last }
    last = values.removeFirst()
    return last
  }
}
