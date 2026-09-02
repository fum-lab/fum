import Foundation
import XCTest

@testable import FUMStructuringOperatorMemory

final class StructuringOperatorMemoryTests: XCTestCase {
  private func suite() throws -> ScenarioSuite {
    try ScenarioFixtureLoader.loadBundledSuite()
  }

  private func report(_ id: String) throws -> ScenarioReport {
    let fixtureSuite = try suite()
    return try StructuringOperatorEngine().run(scenarioID: id, in: fixtureSuite)
  }

  private func mutatedSuite(
    scenarioID: String,
    mutate: (inout [String: Any]) throws -> Void
  ) throws -> ScenarioSuite {
    let data = try canonicalJSONData(try suite())
    guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      var scenarios = root["scenarios"] as? [[String: Any]],
      let index = scenarios.firstIndex(where: { $0["id"] as? String == scenarioID })
    else {
      throw OperatorMemoryError.invalidFixture("test mutation target is missing")
    }
    var scenario = scenarios[index]
    try mutate(&scenario)
    scenarios[index] = scenario
    root["scenarios"] = scenarios
    return try decodeSuite(root)
  }

  private func decodeSuite(_ object: [String: Any]) throws -> ScenarioSuite {
    let data = try JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(ScenarioSuite.self, from: data)
  }

  private func rehashRecordedEnvelope(in scenario: inout [String: Any]) throws {
    guard var envelope = scenario["recorded_llm"] as? [String: Any],
      let prompt = envelope["prompt_text"] as? String,
      let proposals = envelope["proposals"] as? [[String: Any]]
    else {
      throw OperatorMemoryError.invalidFixture("recorded envelope is missing")
    }
    let proposalData = try JSONSerialization.data(
      withJSONObject: proposals,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    envelope["prompt_hash"] = sha256Digest(Data(prompt.utf8))
    envelope["response_hash"] = sha256Digest(proposalData)
    scenario["recorded_llm"] = envelope
  }

  private func envelopeData(
    mutate: (inout [String: Any]) throws -> Void
  ) throws -> Data {
    let fixtureSuite = try suite()
    let scenario = try fixtureSuite.scenario(id: "local_stream")
    let data = try canonicalJSONData(try XCTUnwrap(scenario.recordedLlm))
    guard var envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw OperatorMemoryError.invalidFixture("recorded envelope is not an object")
    }
    try mutate(&envelope)
    return try JSONSerialization.data(
      withJSONObject: envelope,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
  }

  func testBundledFixtureCatalogIsCompleteAndStable() throws {
    let fixtureSuite = try suite()
    XCTAssertEqual(
      fixtureSuite.scenarios.map(\.id),
      [
        "local_stream",
        "bad_input_rejection",
        "exact_roundtrip",
        "semantic_compression",
        "language_forms",
        "cross_language_graph",
        "explainability_and_links",
        "automation_projection",
        "sync_external_confirmed",
        "sync_external_divergence",
        "sync_internal_subnodes",
      ]
    )
  }

  func testMalformedRecordedLLMEnvelopeIsRejected() throws {
    let data = try ScenarioFixtureLoader.loadBundledMalformedEnvelope()
    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: data))
  }

  func testLocalStreamBuildsBoundedForestLatticeAndPrunesDeterministically() throws {
    let first = try report("local_stream")
    let second = try report("local_stream")

    XCTAssertEqual(first, second)
    XCTAssertTrue(first.passed)
    XCTAssertGreaterThan(first.metrics.predictionGainMilliBits, 0)
    XCTAssertGreaterThan(first.metrics.compressionGainBits, 0)
    XCTAssertGreaterThanOrEqual(first.pruning.prunedContextHex.count, 1)
    XCTAssertGreaterThanOrEqual(first.pruning.prunedCandidateIDs.count, 1)
    XCTAssertEqual(first.candidate(id: "op.llm.fix_report")?.finalStatus, .confirmed)
    XCTAssertEqual(first.candidate(id: "op.llm.edit_marker")?.finalStatus, .lowConfidence)
    XCTAssertEqual(first.candidate(id: "op.llm.archive_report")?.finalStatus, .conflicting)
    XCTAssertTrue(
      first.pruning.prunedCandidateIDs.allSatisfy {
        first.candidate(id: $0)?.finalStatus == .obsolete
      }
    )
    XCTAssertTrue(first.lattices.allSatisfy(\.probabilitiesAreNormalized))
  }

  func testProbableInputErrorDoesNotBecomeAnOperator() throws {
    let result = try report("bad_input_rejection")
    XCTAssertTrue(result.passed)
    XCTAssertTrue(result.metrics.exactRoundTrip)
    XCTAssertEqual(result.candidate(id: "op.llm.tex.sectoin")?.finalStatus, .rejected)
    XCTAssertTrue(result.residuals.contains { $0.category == .probableInputError })
  }

  func testExactRoundTripPreservesMarkdownTeXAndSwiftBytes() throws {
    let result = try report("exact_roundtrip")
    XCTAssertTrue(result.passed)
    XCTAssertTrue(result.metrics.exactRoundTrip)
    XCTAssertTrue(result.metrics.operatorGenerationExact)
    XCTAssertGreaterThan(result.metrics.rawPreservedByteCount, 0)
    XCTAssertGreaterThan(result.metrics.operatorGeneratedByteCount, 0)
    XCTAssertGreaterThan(result.metrics.compressionGainBits, 0)
    XCTAssertTrue(result.sourcesUnchanged)
    let generatedUnits = result.lattices.flatMap(\.selectedUnits).filter {
      $0.reconstructionKind == .operatorGenerated
    }
    XCTAssertFalse(generatedUnits.isEmpty)
    XCTAssertTrue(generatedUnits.allSatisfy { $0.sourceBytesHex == $0.generatedBytesHex })
  }

  func testSemanticCompressionPreservesRequiredMeaningAndRawProvenance() throws {
    let result = try report("semantic_compression")
    XCTAssertTrue(result.passed)
    XCTAssertEqual(result.metrics.roundTripQualityPPM, 1_000_000)
    XCTAssertGreaterThan(result.metrics.compressionGainBits, 0)
    XCTAssertFalse(result.semanticGeneration.isEmpty)
    XCTAssertEqual(result.groundedSemanticFacts.count, 5)
    XCTAssertTrue(
      result.groundedSemanticFacts.allSatisfy {
        !$0.operatorIDs.isEmpty && $0.span.byteLength > 0
      }
    )
    XCTAssertTrue(result.sourcesUnchanged)
    XCTAssertFalse(result.sourceHashes.isEmpty)
  }

  func testSemanticFactsAreGroundedAndCorruptionLowersQuality() throws {
    let baseline = try report("semantic_compression")
    let corruptedSuite = try mutatedSuite(scenarioID: "semantic_compression") { scenario in
      guard var events = scenario["events"] as? [[String: Any]], !events.isEmpty else {
        throw OperatorMemoryError.invalidFixture("semantic event is missing")
      }
      events[0]["text"] =
        "Согласно плану завтра до полудня нужно испортить архив, затем проверить журнал и сохранить происхождение результата."
      scenario["events"] = events
    }
    let corrupted = try StructuringOperatorEngine().run(
      scenarioID: "semantic_compression",
      in: corruptedSuite
    )

    XCTAssertEqual(baseline.metrics.roundTripQualityPPM, 1_000_000)
    XCTAssertLessThan(corrupted.metrics.roundTripQualityPPM, baseline.metrics.roundTripQualityPPM)
    XCTAssertFalse(corrupted.sourcesUnchanged)
    XCTAssertFalse(
      corrupted.groundedSemanticFacts.contains {
        $0.fact.key == "action" || $0.fact.key == "target"
      }
    )
  }

  func testLanguageSpecificFormsRemainDistinctOperators() throws {
    let result = try report("language_forms")
    XCTAssertTrue(result.passed)
    let selected = Set(result.lattices.flatMap(\.selectedUnits).compactMap(\.operatorID))
    XCTAssertTrue(selected.contains("op.ru.large_house.nominative"))
    XCTAssertTrue(selected.contains("op.ru.large_house.genitive"))
    XCTAssertTrue(selected.contains("op.ru.large_house.instrumental"))
    XCTAssertTrue(selected.contains("op.ru.large_house.translit"))
  }

  func testCrossLanguageConnectionPassesThroughSemanticStratumAndKeepsResidues() throws {
    let result = try report("cross_language_graph")
    XCTAssertTrue(result.passed)
    XCTAssertEqual(
      result.graphPath,
      [
        "op.ru.correct.surface",
        "op.ru.correct.syntax",
        "op.semantic.correct_event",
        "op.en.correct.syntax",
        "op.en.correct.surface",
      ]
    )
    XCTAssertEqual(result.residuals.filter { $0.category == .translationLoss }.count, 2)
    XCTAssertFalse(
      result.graphEdges.contains {
        $0.fromID == "op.ru.correct.surface" && $0.toID == "op.en.correct.surface"
      }
    )
  }

  func testExplainabilityProducesHumanAndLLMViewsWithoutEditingSources() throws {
    let result = try report("explainability_and_links")
    XCTAssertTrue(result.passed)
    XCTAssertEqual(Set(result.explanations.map(\.status)), Set(CandidateStatus.linkStatuses))
    XCTAssertTrue(result.explanations.allSatisfy { !$0.humanView.isEmpty && !$0.llmView.isEmpty })
    XCTAssertTrue(result.sourcesUnchanged)
  }

  func testAutomationProjectionIsPureAndFeedsTraceBackToOperatorGraph() throws {
    let result = try report("automation_projection")
    let trace = try XCTUnwrap(result.automationTrace)
    XCTAssertTrue(result.passed)
    XCTAssertEqual(trace.output, "исправь отчёт")
    XCTAssertTrue(trace.effects.isEmpty)
    XCTAssertEqual(trace.steps.map(\.stepID), ["trim", "lowercase", "collapse"])
    XCTAssertTrue(trace.traceHash.hasPrefix("sha256:"))
    XCTAssertTrue(
      result.graphEdges.contains {
        $0.fromID == trace.operatorID
          && $0.toID == "trace:\(trace.traceHash)"
          && $0.relation == .verifies
      }
    )
  }

  func testExternalSynchronizationIncludesLLMNodeAndReachesJointAction() throws {
    let result = try report("sync_external_confirmed")
    let trace = try XCTUnwrap(result.synchronizationTrace)
    XCTAssertTrue(result.passed)
    XCTAssertTrue(trace.containsLLMBackedNode)
    XCTAssertTrue(trace.actionExecuted)
    XCTAssertTrue(trace.simulationOnly)
    XCTAssertTrue(trace.externalEffects.isEmpty)
    XCTAssertEqual(trace.nodeSnapshots.count, 2)
    XCTAssertNotEqual(trace.nodeSnapshots[0], trace.nodeSnapshots[1])
    XCTAssertNotEqual(trace.nodeSnapshots[0].factHistory, trace.nodeSnapshots[1].factHistory)
    let synchronizedValues = trace.nodeSnapshots.compactMap { snapshot in
      snapshot.facts.first { $0.key == "meeting_time" }?.value
    }
    XCTAssertEqual(Set(synchronizedValues), ["16:00"])
    XCTAssertTrue(
      result.provenance.contains {
        $0.initiator == "llm" && $0.source.hasPrefix("recorded:")
      }
    )
    let adapter = try XCTUnwrap(result.recordedAdapterTrace)
    XCTAssertEqual(adapter.model, "fixture-llm")
    XCTAssertFalse(adapter.externalExecution)
    XCTAssertEqual(
      trace.actTypes,
      [
        .statement, .question, .clarification, .correction, .paraphrase, .confirmation,
        .jointAction,
      ]
    )
    XCTAssertTrue(trace.roleBindings.contains { $0.form == "мы" && $0.representsComposite })
  }

  func testDivergenceIsPreservedAndBlocksJointAction() throws {
    let result = try report("sync_external_divergence")
    let trace = try XCTUnwrap(result.synchronizationTrace)
    XCTAssertTrue(result.passed)
    XCTAssertFalse(trace.actionExecuted)
    XCTAssertFalse(trace.divergences.isEmpty)
  }

  func testUnauthorizedOrIrrelevantConfirmationBlocksJointAction() throws {
    for mutation in ["unauthorized", "irrelevant"] {
      let fixtureSuite = try mutatedSuite(scenarioID: "sync_external_confirmed") { scenario in
        guard var synchronization = scenario["synchronization"] as? [String: Any],
          var acts = synchronization["acts"] as? [[String: Any]],
          let confirmationIndex = acts.firstIndex(where: {
            $0["type"] as? String == SpeechActType.confirmation.rawValue
          })
        else {
          throw OperatorMemoryError.invalidFixture("confirmation act is missing")
        }
        if mutation == "unauthorized" {
          acts[confirmationIndex]["authorized"] = false
        } else {
          var fact = try XCTUnwrap(acts[confirmationIndex]["fact"] as? [String: Any])
          fact["key"] = "irrelevant_note"
          acts[confirmationIndex]["fact"] = fact
        }
        synchronization["acts"] = acts
        synchronization["expect_action"] = false
        scenario["synchronization"] = synchronization
        var expectation = try XCTUnwrap(scenario["expectation"] as? [String: Any])
        expectation["action_executed"] = false
        scenario["expectation"] = expectation
      }
      let result = try StructuringOperatorEngine().run(
        scenarioID: "sync_external_confirmed",
        in: fixtureSuite
      )
      XCTAssertFalse(result.synchronizationTrace?.actionExecuted ?? true, mutation)
    }
  }

  func testInternalSubnodesUseTheSameSynchronizationContour() throws {
    let external = try XCTUnwrap(report("sync_external_confirmed").synchronizationTrace)
    let internalTrace = try XCTUnwrap(report("sync_internal_subnodes").synchronizationTrace)
    XCTAssertTrue(internalTrace.actionExecuted)
    XCTAssertEqual(internalTrace.actTypes, external.actTypes)
    XCTAssertTrue(internalTrace.nodeKinds.allSatisfy { $0 == .internalSubnode })
  }

  func testCanonicalReportIsStableAndContainsProvenance() throws {
    let result = try report("local_stream")
    let first = try result.canonicalJSON()
    let second = try result.canonicalJSON()
    XCTAssertEqual(first, second)
    XCTAssertTrue(first.contains("\"schema_version\":1"))
    XCTAssertFalse(result.provenance.isEmpty)
    XCTAssertTrue(result.fixtureResourceHash.hasPrefix("sha256:"))
    XCTAssertFalse(result.appliedOperators.isEmpty)
    XCTAssertTrue(result.sourceHashes.allSatisfy { $0.value.hasPrefix("sha256:") })
  }

  func testLowConfidenceCandidateNeverParticipatesInActiveParse() throws {
    let result = try report("local_stream")
    XCTAssertEqual(result.candidate(id: "op.llm.edit_marker")?.finalStatus, .lowConfidence)
    let lowConfidenceIDs = Set(
      result.candidates.filter { $0.finalStatus == .lowConfidence }.map(\.operatorID)
    )
    let selectedIDs = Set(result.lattices.flatMap(\.selectedUnits).compactMap(\.operatorID))
    XCTAssertTrue(lowConfidenceIDs.isDisjoint(with: selectedIDs))
  }

  func testLLMConfirmationRequiresCandidateEvidenceAndReversibleGeneration() throws {
    let baseline = try report("local_stream")
    let confirmed = try XCTUnwrap(baseline.candidate(id: "op.llm.fix_report"))
    let weak = try XCTUnwrap(baseline.candidate(id: "op.llm.edit_marker"))
    XCTAssertTrue(
      confirmed.compressionGainBits > 0 || confirmed.predictionGainMilliBits > 0
    )
    XCTAssertGreaterThan(confirmed.predictionGainMilliBits, weak.predictionGainMilliBits)

    let irreversibleSuite = try mutatedSuite(scenarioID: "local_stream") { scenario in
      guard var envelope = scenario["recorded_llm"] as? [String: Any],
        var proposals = envelope["proposals"] as? [[String: Any]],
        let index = proposals.firstIndex(where: { $0["id"] as? String == "op.llm.fix_report" })
      else {
        throw OperatorMemoryError.invalidFixture("LLM proposal is missing")
      }
      proposals[index].removeValue(forKey: "generation_template")
      envelope["proposals"] = proposals
      scenario["recorded_llm"] = envelope
      try rehashRecordedEnvelope(in: &scenario)
    }
    let irreversible = try StructuringOperatorEngine().run(
      scenarioID: "local_stream",
      in: irreversibleSuite
    )
    let rejected = try XCTUnwrap(irreversible.candidate(id: "op.llm.fix_report"))
    XCTAssertEqual(rejected.finalStatus, .rejected)
    XCTAssertEqual(rejected.roundTripQualityPPM, 0)

    let noEvidenceSuite = try mutatedSuite(scenarioID: "local_stream") { scenario in
      guard var events = scenario["events"] as? [[String: Any]],
        var envelope = scenario["recorded_llm"] as? [String: Any],
        var proposals = envelope["proposals"] as? [[String: Any]],
        let index = proposals.firstIndex(where: { $0["id"] as? String == "op.llm.fix_report" })
      else {
        throw OperatorMemoryError.invalidFixture("LLM proposal is missing")
      }
      events[events.count - 1]["text"] = "другой запрос"
      proposals[index]["storage_cost_bits"] = 999_999
      envelope["proposals"] = proposals
      scenario["events"] = events
      scenario["recorded_llm"] = envelope
      try rehashRecordedEnvelope(in: &scenario)
    }
    let noEvidence = try StructuringOperatorEngine().run(
      scenarioID: "local_stream",
      in: noEvidenceSuite
    )
    let unsupported = try XCTUnwrap(noEvidence.candidate(id: "op.llm.fix_report"))
    XCTAssertEqual(unsupported.finalStatus, .rejected)
    XCTAssertEqual(unsupported.predictionGainMilliBits, 0)
    XCTAssertLessThanOrEqual(unsupported.compressionGainBits, 0)
  }

  func testRecordedAdapterRecomputesHashesAndRejectsUnsafeProfiles() throws {
    let envelope = try XCTUnwrap(try suite().scenario(id: "local_stream").recordedLlm)
    XCTAssertEqual(envelope.promptHash, sha256Digest(Data(envelope.promptText.utf8)))
    XCTAssertEqual(envelope.responseHash, sha256Digest(try canonicalJSONData(envelope.proposals)))

    let changedPrompt = try envelopeData { object in
      object["prompt_text"] = "changed without matching hash"
    }
    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: changedPrompt)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidRecordedEnvelope("prompt hash mismatch")
      )
    }

    let changedResponse = try envelopeData { object in
      guard var proposals = object["proposals"] as? [[String: Any]] else { return }
      proposals[0]["storage_cost_bits"] = 999
      object["proposals"] = proposals
    }
    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: changedResponse)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidRecordedEnvelope("response hash mismatch")
      )
    }

    let invalidProfile = try envelopeData { object in
      guard var proposals = object["proposals"] as? [[String: Any]] else { return }
      proposals[0]["confidence_ppm"] = 1_000_001
      object["proposals"] = proposals
      let proposalData = try JSONSerialization.data(
        withJSONObject: proposals,
        options: [.sortedKeys, .withoutEscapingSlashes]
      )
      object["response_hash"] = sha256Digest(proposalData)
    }
    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: invalidProfile)) { error in
      guard case .invalidRecordedEnvelope = error as? OperatorMemoryError else {
        return XCTFail("unexpected error: \(error)")
      }
    }
  }

  func testDuplicateProposalsAndSeedProposalCollisionsAreRejectedBeforeIndexing() throws {
    let duplicateData = try envelopeData { object in
      guard var proposals = object["proposals"] as? [[String: Any]],
        let first = proposals.first
      else { return }
      proposals.append(first)
      object["proposals"] = proposals
      let proposalData = try JSONSerialization.data(
        withJSONObject: proposals,
        options: [.sortedKeys, .withoutEscapingSlashes]
      )
      object["response_hash"] = sha256Digest(proposalData)
    }
    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: duplicateData)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidRecordedEnvelope("duplicate proposal id")
      )
    }

    let collisionSuite = try mutatedSuite(scenarioID: "local_stream") { scenario in
      guard var envelope = scenario["recorded_llm"] as? [String: Any],
        var proposals = envelope["proposals"] as? [[String: Any]]
      else { return }
      proposals[0]["id"] = "op.request.correct"
      envelope["proposals"] = proposals
      scenario["recorded_llm"] = envelope
      try rehashRecordedEnvelope(in: &scenario)
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(collisionSuite)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidFixture("local_stream: seed/proposal operator id collision")
      )
    }
  }

  func testReservedDerivedNamespaceIsRejectedBeforeCandidateIndexing() throws {
    let reservedData = try envelopeData { object in
      guard var proposals = object["proposals"] as? [[String: Any]] else { return }
      proposals[0]["id"] = "unit.d0b0d0b0"
      object["proposals"] = proposals
      let proposalData = try JSONSerialization.data(
        withJSONObject: proposals,
        options: [.sortedKeys, .withoutEscapingSlashes]
      )
      object["response_hash"] = sha256Digest(proposalData)
    }

    XCTAssertThrowsError(try RecordedLLMProposalAdapter.decode(data: reservedData)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidRecordedEnvelope("reserved proposal id namespace: unit.")
      )
    }
  }

  func testExplicitCandidatesCannotExceedHardCandidateBudget() throws {
    let overBudget = try mutatedSuite(scenarioID: "local_stream") { scenario in
      guard var configuration = scenario["configuration"] as? [String: Any] else { return }
      configuration["max_candidates"] = 4
      scenario["configuration"] = configuration
    }
    XCTAssertThrowsError(
      try StructuringOperatorEngine().run(scenarioID: "local_stream", in: overBudget)
    ) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidFixture("local_stream: explicit candidates exceed max_candidates")
      )
    }
  }

  func testCandidateUtilityNormalizesMilliBitsBeforeStableScoring() {
    let candidate = OperatorCandidateReport(
      operatorID: "unit.score",
      origin: .derived,
      initialStatus: .hypothesis,
      finalStatus: .confirmed,
      support: 2,
      predictionGainMilliBits: 1_500,
      compressionGainBits: 10,
      roundTripQualityPPM: 1_000_000,
      conflictIDs: [],
      history: []
    )
    XCTAssertEqual(candidateUtilityScore(candidate), 211)
  }

  func testUnconfirmedAutomationDoesNotExecuteOrBecomeApplied() throws {
    let prompt = "Recorded weak automation proposal"
    let proposal = OperatorProfile(
      id: "op.llm.automation.normalize_request",
      version: 1,
      stratum: .automation,
      status: .hypothesis,
      recognitionPatterns: ["невстречающийся шаблон"],
      generationTemplate: "невстречающийся шаблон",
      language: "ru",
      script: "Cyrl",
      semanticKey: "weak_normalization",
      storageCostBits: 24,
      confidencePpm: 400_000,
      origin: .llm,
      positiveExamples: [],
      negativeExamples: []
    )
    let proposals = [proposal]
    let envelope = RecordedLLMEnvelope(
      schemaVersion: 1,
      adapterId: "recorded-weak-automation-v1",
      model: "fixture-llm",
      promptText: prompt,
      promptHash: sha256Digest(Data(prompt.utf8)),
      responseHash: sha256Digest(try canonicalJSONData(proposals)),
      proposals: proposals
    )
    let envelopeObject = try XCTUnwrap(
      JSONSerialization.jsonObject(with: canonicalJSONData(envelope)) as? [String: Any]
    )

    let weakSuite = try mutatedSuite(scenarioID: "automation_projection") { scenario in
      scenario["seed_operator_ids"] = ["op.semantic.report_dependency"]
      scenario["recorded_llm"] = envelopeObject
      guard var automation = scenario["automation"] as? [String: Any] else { return }
      automation["operator_id"] = proposal.id
      scenario["automation"] = automation
      scenario["graph_edges"] = [
        [
          "id": "edge-weak-automation-projection",
          "from_id": "op.semantic.report_dependency",
          "to_id": proposal.id,
          "relation": GraphRelation.projectsTo.rawValue,
          "provenance": [
            "initiator": "human",
            "executor": "fixture",
            "source": "test-projection",
            "ordinal": 1,
          ],
        ]
      ]
      var expectation = try XCTUnwrap(scenario["expectation"] as? [String: Any])
      expectation["candidate_statuses"] = [proposal.id: CandidateStatus.lowConfidence.rawValue]
      scenario["expectation"] = expectation
    }
    let result = try StructuringOperatorEngine().run(
      scenarioID: "automation_projection",
      in: weakSuite
    )

    XCTAssertEqual(result.candidate(id: proposal.id)?.finalStatus, .lowConfidence)
    XCTAssertNil(result.automationTrace)
    XCTAssertFalse(result.appliedOperators.contains { $0.id == proposal.id })
    XCTAssertFalse(
      result.graphEdges.contains {
        $0.fromID == proposal.id && $0.relation == .verifies
      }
    )
  }

  func testSemanticQualityPenalizesExtraGroundedFacts() throws {
    let prompt = "Recorded extra semantic proposal"
    let proposal = OperatorProfile(
      id: "op.llm.semantic.unexpected",
      version: 1,
      stratum: .semantic,
      status: .hypothesis,
      recognitionPatterns: ["Согласно"],
      generationTemplate: "Согласно",
      language: "ru",
      script: "Cyrl",
      semanticKey: "unexpected=extra",
      storageCostBits: 0,
      confidencePpm: 700_000,
      origin: .llm,
      positiveExamples: ["Согласно"],
      negativeExamples: []
    )
    let proposals = [proposal]
    let envelope = RecordedLLMEnvelope(
      schemaVersion: 1,
      adapterId: "recorded-extra-semantic-v1",
      model: "fixture-llm",
      promptText: prompt,
      promptHash: sha256Digest(Data(prompt.utf8)),
      responseHash: sha256Digest(try canonicalJSONData(proposals)),
      proposals: proposals
    )
    let envelopeObject = try XCTUnwrap(
      JSONSerialization.jsonObject(with: canonicalJSONData(envelope)) as? [String: Any]
    )
    let extraSuite = try mutatedSuite(scenarioID: "semantic_compression") { scenario in
      scenario["recorded_llm"] = envelopeObject
      var expectation = try XCTUnwrap(scenario["expectation"] as? [String: Any])
      expectation["semantic_quality_ppm"] = NSNull()
      scenario["expectation"] = expectation
    }
    let result = try StructuringOperatorEngine().run(
      scenarioID: "semantic_compression",
      in: extraSuite
    )

    XCTAssertEqual(result.groundedSemanticFacts.count, 6)
    XCTAssertLessThan(result.metrics.roundTripQualityPPM, 1_000_000)
  }

  func testAutomationRequiresIncomingOperatorGraphProjection() throws {
    let baseline = try report("automation_projection")
    let automationID = try XCTUnwrap(baseline.automationTrace?.operatorID)
    XCTAssertTrue(
      baseline.graphEdges.contains {
        $0.toID == automationID && [.projectsTo, .executesAs].contains($0.relation)
      }
    )

    let withoutProjection = try mutatedSuite(scenarioID: "automation_projection") { scenario in
      scenario["graph_edges"] = []
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(withoutProjection)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidFixture("automation_projection: automation operator lacks incoming projection")
      )
    }
  }

  func testSemanticLinksRejectDuplicateDanglingAndInvalidConfidence() throws {
    let duplicate = try mutatedSuite(scenarioID: "explainability_and_links") { scenario in
      guard var links = scenario["semantic_links"] as? [[String: Any]],
        let first = links.first
      else { return }
      links.append(first)
      scenario["semantic_links"] = links
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(duplicate))

    let dangling = try mutatedSuite(scenarioID: "explainability_and_links") { scenario in
      guard var links = scenario["semantic_links"] as? [[String: Any]] else { return }
      links[0]["target_event_id"] = "missing-event"
      scenario["semantic_links"] = links
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(dangling))

    let invalidConfidence = try mutatedSuite(
      scenarioID: "explainability_and_links"
    ) { scenario in
      guard var links = scenario["semantic_links"] as? [[String: Any]] else { return }
      links[0]["confidence_ppm"] = 1_000_001
      scenario["semantic_links"] = links
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(invalidConfidence))

    let unknownOperator = try mutatedSuite(
      scenarioID: "explainability_and_links"
    ) { scenario in
      guard var links = scenario["semantic_links"] as? [[String: Any]] else { return }
      links[0]["operator_id"] = "op.missing"
      scenario["semantic_links"] = links
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(unknownOperator))
  }

  func testLLMBackedRequirementNeedsRecordedEnvelopeAndParticipatingNode() throws {
    let withoutEnvelope = try mutatedSuite(
      scenarioID: "sync_external_confirmed"
    ) { scenario in
      scenario["recorded_llm"] = NSNull()
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(withoutEnvelope)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidFixture("sync_external_confirmed: LLM-backed requirement lacks recorded envelope")
      )
    }

    let unusedNode = try mutatedSuite(scenarioID: "sync_external_confirmed") { scenario in
      guard var synchronization = scenario["synchronization"] as? [String: Any],
        var nodes = synchronization["nodes"] as? [[String: Any]]
      else { return }
      nodes.append(
        [
          "id": "unused-llm",
          "kind": NodeKind.llmBacked.rawValue,
          "initial_facts": [],
        ]
      )
      synchronization["nodes"] = nodes
      scenario["synchronization"] = synchronization
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(unusedNode)) { error in
      XCTAssertEqual(
        error as? OperatorMemoryError,
        .invalidFixture("sync_external_confirmed: LLM-backed node unused-llm does not participate")
      )
    }
  }

  func testSynchronizationTraceMarksActualLLMParticipation() throws {
    let fixtureSuite = try mutatedSuite(scenarioID: "sync_external_confirmed") { scenario in
      guard var synchronization = scenario["synchronization"] as? [String: Any],
        var nodes = synchronization["nodes"] as? [[String: Any]],
        let llmIndex = nodes.firstIndex(where: { $0["id"] as? String == "llm-node" })
      else { return }
      nodes[llmIndex]["kind"] = NodeKind.humanLike.rawValue
      nodes.append(
        [
          "id": "unused-llm",
          "kind": NodeKind.llmBacked.rawValue,
          "initial_facts": [],
        ]
      )
      synchronization["nodes"] = nodes
      scenario["synchronization"] = synchronization
    }
    let synchronization = try XCTUnwrap(
      try fixtureSuite.scenario(id: "sync_external_confirmed").synchronization
    )
    let trace = try SynchronizationReducer.run(synchronization)
    XCTAssertFalse(trace.containsLLMBackedNode)
  }

  func testGraphAndAutomationReferencesAreValidatedBeforeTraversal() throws {
    let dangling = try mutatedSuite(scenarioID: "cross_language_graph") { scenario in
      guard var edges = scenario["graph_edges"] as? [[String: Any]] else { return }
      edges[0]["from_id"] = "op.missing"
      scenario["graph_edges"] = edges
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(dangling))

    let inverted = try mutatedSuite(scenarioID: "cross_language_graph") { scenario in
      guard var edges = scenario["graph_edges"] as? [[String: Any]] else { return }
      edges[0]["relation"] = GraphRelation.generates.rawValue
      scenario["graph_edges"] = edges
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(inverted))

    let wrongAutomation = try mutatedSuite(scenarioID: "automation_projection") { scenario in
      scenario["seed_operator_ids"] = ["op.request.correct"]
      guard var automation = scenario["automation"] as? [String: Any] else { return }
      automation["operator_id"] = "op.request.correct"
      scenario["automation"] = automation
    }
    XCTAssertThrowsError(try ScenarioFixtureLoader.validate(wrongAutomation))
  }
}
