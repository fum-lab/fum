import Foundation
import XCTest

@testable import FUMDistributedEpisodeMemory

final class ContributionProvenanceTests: XCTestCase {
  func testDifferentObservedSourcesRemainSeparateConfirmations() throws {
    let primary = provenance(
      id: "contribution.primary",
      executorID: "executor.primary",
      roleID: "producer.primary",
      workPackageArtifactID: "package.primary",
      modelID: "model.primary",
      providerID: "provider.primary",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.primary", .model, sha("4")),
        link("group.source.primary", .sourceMaterial, sha("1")),
        link("group.template.primary", .systemTemplate, sha("5")),
      ]
    )
    let adversarial = provenance(
      id: "contribution.adversarial",
      executorID: "executor.adversarial",
      roleID: "producer.adversarial",
      workPackageArtifactID: "package.adversarial",
      modelID: "model.adversarial",
      providerID: "provider.adversarial",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("7"),
      resultSHA256: sha("8"),
      correlationLinks: [
        link("group.model.adversarial", .model, sha("9")),
        link("group.source.adversarial", .sourceMaterial, sha("6")),
        link("group.template.adversarial", .systemTemplate, sha("a")),
      ]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([
      primary,
      adversarial,
    ])

    XCTAssertEqual(
      report.statusesByContributionID[primary.contributionID],
      .independentByObservedFeatures
    )
    XCTAssertEqual(
      report.statusesByContributionID[adversarial.contributionID],
      .independentByObservedFeatures
    )
    XCTAssertEqual(report.independentConfirmationCount, 2)
    XCTAssertFalse(report.semanticIndependenceProven)
  }

  func testSharedModelAndSystemTemplateFormOneCorrelatedComponent() throws {
    let first = provenance(
      id: "contribution.first",
      executorID: "executor.first",
      roleID: "producer.first",
      workPackageArtifactID: "package.first",
      modelID: "model.shared",
      providerID: "provider.shared",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.shared", .model, sha("4")),
        link("group.source.first", .sourceMaterial, sha("1")),
        link("group.template.shared", .systemTemplate, sha("5")),
      ]
    )
    let second = provenance(
      id: "contribution.second",
      executorID: "executor.second",
      roleID: "producer.second",
      workPackageArtifactID: "package.second",
      modelID: "model.shared",
      providerID: "provider.shared",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("7"),
      resultSHA256: sha("8"),
      correlationLinks: [
        link("group.model.shared", .model, sha("4")),
        link("group.source.second", .sourceMaterial, sha("6")),
        link("group.template.shared", .systemTemplate, sha("5")),
      ]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([first, second])

    XCTAssertEqual(report.statusesByContributionID[first.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[second.contributionID], .correlated)
    XCTAssertEqual(report.independentConfirmationCount, 1)
    XCTAssertFalse(report.semanticIndependenceProven)
  }

  func testOverlappingGroupsCollapseTransitivelyAndReclassifyEarlierContributions() throws {
    let first = provenance(
      id: "contribution.a",
      executorID: "executor.a",
      roleID: "producer.a",
      workPackageArtifactID: "package.a",
      modelID: "model.shared-ab",
      providerID: "provider.shared-ab",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.ab", .model, sha("4")),
        link("group.source.a", .sourceMaterial, sha("1")),
        link("group.template.a", .systemTemplate, sha("5")),
      ]
    )
    let bridge = provenance(
      id: "contribution.b",
      executorID: "executor.b",
      roleID: "producer.b",
      workPackageArtifactID: "package.b",
      modelID: "model.shared-ab",
      providerID: "provider.shared-ab",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("7"),
      resultSHA256: sha("8"),
      correlationLinks: [
        link("group.model.ab", .model, sha("4")),
        link("group.source.bc", .sourceMaterial, sha("6")),
        link("group.template.b", .systemTemplate, sha("9")),
      ]
    )
    let third = provenance(
      id: "contribution.c",
      executorID: "executor.c",
      roleID: "producer.c",
      workPackageArtifactID: "package.c",
      modelID: "model.c",
      providerID: "provider.c",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("a"),
      resultSHA256: sha("b"),
      correlationLinks: [
        link("group.model.c", .model, sha("c")),
        link("group.source.bc", .sourceMaterial, sha("6")),
        link("group.template.c", .systemTemplate, sha("d")),
      ]
    )

    let beforeBridge = try SharedEpisodeProvenanceValidator.analyze([first])
    XCTAssertEqual(
      beforeBridge.statusesByContributionID[first.contributionID],
      .independentByObservedFeatures
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([first, bridge, third])

    XCTAssertEqual(report.statusesByContributionID[first.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[bridge.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[third.contributionID], .correlated)
    XCTAssertEqual(report.independentConfirmationCount, 1)
    XCTAssertFalse(report.semanticIndependenceProven)
  }

  func testDirectCopyHasNoAdditionalConfirmationCredit() throws {
    let originalResult = sha("1")
    let original = provenance(
      id: "contribution.original",
      executorID: "executor.original",
      roleID: "producer.original",
      workPackageArtifactID: "package.original",
      modelID: "model.original",
      providerID: "provider.original",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("2")],
      parentGenerationSHA256: sha("3"),
      resultSHA256: originalResult,
      correlationLinks: [
        link("group.model.original", .model, sha("4")),
        link("group.source.original", .sourceMaterial, sha("2")),
        link("group.template.original", .systemTemplate, sha("5")),
      ]
    )
    let copy = provenance(
      id: "contribution.copy",
      executorID: "executor.copy",
      roleID: "producer.copy",
      workPackageArtifactID: "package.copy",
      modelID: "model.copy",
      providerID: "provider.copy",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("7"),
      resultSHA256: originalResult,
      correlationLinks: [
        link(
          "group.copy.original",
          .copy,
          originalResult,
          sourceContributionID: original.contributionID
        ),
        link("group.model.copy", .model, sha("8")),
        link("group.source.copy", .sourceMaterial, sha("6")),
        link("group.template.copy", .systemTemplate, sha("9")),
      ]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([original, copy])

    XCTAssertEqual(report.statusesByContributionID[original.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[copy.contributionID], .copy)
    XCTAssertEqual(report.independentConfirmationCount, 1)
    XCTAssertFalse(report.semanticIndependenceProven)

    let falseCopy = provenance(
      id: "contribution.false-copy",
      executorID: "executor.false-copy",
      roleID: "producer.false-copy",
      workPackageArtifactID: "package.false-copy",
      modelID: "model.false-copy",
      providerID: "provider.false-copy",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("a")],
      parentGenerationSHA256: sha("b"),
      resultSHA256: sha("c"),
      correlationLinks: [
        link(
          "group.copy.original",
          .copy,
          originalResult,
          sourceContributionID: original.contributionID
        ),
        link("group.model.false-copy", .model, sha("d")),
        link("group.source.false-copy", .sourceMaterial, sha("a")),
        link("group.template.false-copy", .systemTemplate, sha("e")),
      ]
    )
    XCTAssertThrowsError(
      try SharedEpisodeProvenanceValidator.analyze([original, falseCopy])
    )
  }

  func testInstrumentObservationRemainsSeparateFromModelDerivedAssertion() throws {
    let observation = SharedEpisodeInstrumentObservation(
      observationID: "observation.compiler",
      sourceAuthority: .localTool,
      callID: "call.compiler.1",
      inputSHA256: sha("1"),
      resultSHA256: sha("2"),
      observedAtSeconds: 1_780_000_000
    )
    let derived = provenance(
      id: "contribution.derived",
      executorID: "executor.derived",
      roleID: "producer.derived",
      workPackageArtifactID: "package.derived",
      modelID: "model.derived",
      providerID: "provider.derived",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("3")],
      parentGenerationSHA256: sha("4"),
      resultSHA256: sha("5"),
      correlationLinks: [
        link("group.model.derived", .model, sha("6")),
        link("group.source.derived", .sourceMaterial, sha("3")),
        link("group.template.derived", .systemTemplate, sha("7")),
      ],
      instrumentObservations: [observation],
      derivedFromObservationIDs: [observation.observationID]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([derived])

    XCTAssertNotEqual(observation.resultSHA256, derived.resultSHA256)
    XCTAssertEqual(
      report.statusesByContributionID[derived.contributionID],
      .independentByObservedFeatures
    )
    XCTAssertEqual(report.independentConfirmationCount, 1)
    XCTAssertFalse(report.semanticIndependenceProven)

    let decoded = try canonicalRoundTrip(derived)
    XCTAssertEqual(decoded.instrumentObservations, [observation])
    XCTAssertEqual(decoded.derivedFromObservationIDs, [observation.observationID])
    XCTAssertEqual(decoded.resultSHA256, sha("5"))
    XCTAssertEqual(decoded.instrumentObservations[0].resultSHA256, sha("2"))

    let hiddenInstrumentInput = provenance(
      id: "contribution.hidden-instrument-input",
      executorID: "executor.hidden-instrument-input",
      roleID: "producer.hidden-instrument-input",
      workPackageArtifactID: "package.hidden-instrument-input",
      modelID: "model.hidden-instrument-input",
      providerID: "provider.hidden-instrument-input",
      taskSHA256: sha("0"),
      localInputSHA256s: [observation.resultSHA256],
      parentGenerationSHA256: sha("8"),
      resultSHA256: sha("9"),
      correlationLinks: [
        link("group.model.hidden-instrument", .model, sha("a")),
        link(
          "group.source.hidden-instrument",
          .sourceMaterial,
          observation.resultSHA256
        ),
        link("group.template.hidden-instrument", .systemTemplate, sha("b")),
      ],
      instrumentObservations: [observation]
    )
    XCTAssertThrowsError(
      try SharedEpisodeProvenanceValidator.analyze([hiddenInstrumentInput])
    )
  }

  func testPartialObservedModelIdentityIsUnconfirmedProvenance() throws {
    let incomplete = provenance(
      id: "contribution.incomplete",
      executorID: "executor.incomplete",
      roleID: "producer.incomplete",
      workPackageArtifactID: "package.incomplete",
      modelID: "model.observed",
      providerID: nil,
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.incomplete", .model, sha("4")),
        link("group.source.incomplete", .sourceMaterial, sha("1")),
        link("group.template.incomplete", .systemTemplate, sha("5")),
      ]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([incomplete])

    XCTAssertEqual(
      report.statusesByContributionID[incomplete.contributionID],
      .unconfirmedProvenance
    )
    XCTAssertEqual(report.independentConfirmationCount, 0)
    XCTAssertFalse(report.semanticIndependenceProven)
  }

  func testSharedExecutorDoesNotIncreaseIndependentConfirmationCount() throws {
    let first = provenance(
      id: "contribution.executor-first",
      executorID: "executor.shared",
      roleID: "producer.executor-first",
      workPackageArtifactID: "package.executor-first",
      modelID: "model.executor-first",
      providerID: "provider.executor-first",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.executor-first", .model, sha("4")),
        link("group.source.executor-first", .sourceMaterial, sha("1")),
        link("group.template.executor-first", .systemTemplate, sha("5")),
      ]
    )
    let second = provenance(
      id: "contribution.executor-second",
      executorID: "executor.shared",
      roleID: "producer.executor-second",
      workPackageArtifactID: "package.executor-second",
      modelID: "model.executor-second",
      providerID: "provider.executor-second",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("6")],
      parentGenerationSHA256: sha("7"),
      resultSHA256: sha("8"),
      correlationLinks: [
        link("group.model.executor-second", .model, sha("9")),
        link("group.source.executor-second", .sourceMaterial, sha("6")),
        link("group.template.executor-second", .systemTemplate, sha("a")),
      ]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([first, second])

    XCTAssertEqual(report.statusesByContributionID[first.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[second.contributionID], .correlated)
    XCTAssertEqual(report.independentConfirmationCount, 1)
  }

  func testRepeatedInstrumentCallCorrelatesAndConflictingReplayFailsClosed() throws {
    let firstObservation = SharedEpisodeInstrumentObservation(
      observationID: "observation.shared-call.first",
      sourceAuthority: .localTool,
      callID: "call.shared.1",
      inputSHA256: sha("1"),
      resultSHA256: sha("2"),
      observedAtSeconds: 1_780_000_010
    )
    let secondObservation = SharedEpisodeInstrumentObservation(
      observationID: "observation.shared-call.second",
      sourceAuthority: .localTool,
      callID: "call.shared.1",
      inputSHA256: sha("1"),
      resultSHA256: sha("2"),
      observedAtSeconds: 1_780_000_010
    )
    let first = provenance(
      id: "contribution.call-first",
      executorID: "executor.call-first",
      roleID: "producer.call-first",
      workPackageArtifactID: "package.call-first",
      modelID: "model.call-first",
      providerID: "provider.call-first",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("3")],
      parentGenerationSHA256: sha("4"),
      resultSHA256: sha("5"),
      correlationLinks: [
        link("group.model.call-first", .model, sha("6")),
        link("group.source.call-first", .sourceMaterial, sha("3")),
        link("group.template.call-first", .systemTemplate, sha("7")),
      ],
      instrumentObservations: [firstObservation],
      derivedFromObservationIDs: [firstObservation.observationID]
    )
    let second = provenance(
      id: "contribution.call-second",
      executorID: "executor.call-second",
      roleID: "producer.call-second",
      workPackageArtifactID: "package.call-second",
      modelID: "model.call-second",
      providerID: "provider.call-second",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("8")],
      parentGenerationSHA256: sha("9"),
      resultSHA256: sha("a"),
      correlationLinks: [
        link("group.model.call-second", .model, sha("b")),
        link("group.source.call-second", .sourceMaterial, sha("8")),
        link("group.template.call-second", .systemTemplate, sha("c")),
      ],
      instrumentObservations: [secondObservation],
      derivedFromObservationIDs: [secondObservation.observationID]
    )

    let report = try SharedEpisodeProvenanceValidator.analyze([first, second])
    XCTAssertEqual(report.statusesByContributionID[first.contributionID], .correlated)
    XCTAssertEqual(report.statusesByContributionID[second.contributionID], .correlated)
    XCTAssertEqual(report.independentConfirmationCount, 1)

    let conflictingObservation = SharedEpisodeInstrumentObservation(
      observationID: "observation.shared-call.conflicting",
      sourceAuthority: .localTool,
      callID: "call.shared.1",
      inputSHA256: sha("1"),
      resultSHA256: sha("d"),
      observedAtSeconds: 1_780_000_010
    )
    let conflicting = provenance(
      id: "contribution.call-conflicting",
      executorID: "executor.call-conflicting",
      roleID: "producer.call-conflicting",
      workPackageArtifactID: "package.call-conflicting",
      modelID: "model.call-conflicting",
      providerID: "provider.call-conflicting",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("e")],
      parentGenerationSHA256: sha("f"),
      resultSHA256: sha("0"),
      correlationLinks: [
        link("group.model.call-conflicting", .model, sha("1")),
        link("group.source.call-conflicting", .sourceMaterial, sha("e")),
        link("group.template.call-conflicting", .systemTemplate, sha("2")),
      ],
      instrumentObservations: [conflictingObservation],
      derivedFromObservationIDs: [conflictingObservation.observationID]
    )
    XCTAssertThrowsError(
      try SharedEpisodeProvenanceValidator.analyze([first, conflicting])
    )
  }

  func testDerivedResultInputRequiresDirectedCorrelationEdge() throws {
    let original = provenance(
      id: "contribution.derived-source",
      executorID: "executor.derived-source",
      roleID: "producer.derived-source",
      workPackageArtifactID: "package.derived-source",
      modelID: "model.derived-source",
      providerID: "provider.derived-source",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("1")],
      parentGenerationSHA256: sha("2"),
      resultSHA256: sha("3"),
      correlationLinks: [
        link("group.model.derived-source", .model, sha("4")),
        link("group.source.derived-source", .sourceMaterial, sha("1")),
        link("group.template.derived-source", .systemTemplate, sha("5")),
      ]
    )
    let hiddenDerivation = provenance(
      id: "contribution.hidden-derivation",
      executorID: "executor.hidden-derivation",
      roleID: "producer.hidden-derivation",
      workPackageArtifactID: "package.hidden-derivation",
      modelID: "model.hidden-derivation",
      providerID: "provider.hidden-derivation",
      taskSHA256: sha("0"),
      localInputSHA256s: [original.resultSHA256],
      parentGenerationSHA256: sha("6"),
      resultSHA256: sha("7"),
      correlationLinks: [
        link("group.model.hidden-derivation", .model, sha("8")),
        link(
          "group.source.hidden-derivation",
          .sourceMaterial,
          original.resultSHA256
        ),
        link("group.template.hidden-derivation", .systemTemplate, sha("9")),
      ]
    )
    XCTAssertThrowsError(
      try SharedEpisodeProvenanceValidator.analyze([original, hiddenDerivation])
    )

    let declaredDerivation = provenance(
      id: "contribution.declared-derivation",
      executorID: "executor.declared-derivation",
      roleID: "producer.declared-derivation",
      workPackageArtifactID: "package.declared-derivation",
      modelID: "model.declared-derivation",
      providerID: "provider.declared-derivation",
      taskSHA256: sha("0"),
      localInputSHA256s: [original.resultSHA256],
      parentGenerationSHA256: sha("a"),
      resultSHA256: sha("b"),
      correlationLinks: [
        link(
          "group.derived.original",
          .derivedAnswer,
          original.resultSHA256,
          sourceContributionID: original.contributionID
        ),
        link("group.model.declared-derivation", .model, sha("c")),
        link(
          "group.source.declared-derivation",
          .sourceMaterial,
          original.resultSHA256
        ),
        link("group.template.declared-derivation", .systemTemplate, sha("d")),
      ]
    )
    let report = try SharedEpisodeProvenanceValidator.analyze([
      original,
      declaredDerivation,
    ])
    XCTAssertEqual(report.statusesByContributionID[original.contributionID], .correlated)
    XCTAssertEqual(
      report.statusesByContributionID[declaredDerivation.contributionID],
      .correlated
    )
    XCTAssertEqual(report.independentConfirmationCount, 1)
  }

  func testCanonicalRoundTripPreservesLinksObservationsAndReport() throws {
    let observation = SharedEpisodeInstrumentObservation(
      observationID: "observation.fixture",
      sourceAuthority: .localTool,
      callID: "call.fixture.1",
      inputSHA256: sha("1"),
      resultSHA256: sha("2"),
      observedAtSeconds: 1_780_000_001
    )
    let correlation = link(
      "group.source.fixture",
      .sourceMaterial,
      sha("3")
    )
    let value = provenance(
      id: "contribution.fixture",
      executorID: "executor.fixture",
      roleID: "producer.fixture",
      workPackageArtifactID: "package.fixture",
      modelID: "model.fixture",
      providerID: "provider.fixture",
      taskSHA256: sha("0"),
      localInputSHA256s: [sha("3")],
      parentGenerationSHA256: sha("4"),
      resultSHA256: sha("5"),
      correlationLinks: [
        link("group.model.fixture", .model, sha("6")),
        correlation,
        link("group.template.fixture", .systemTemplate, sha("7")),
      ],
      instrumentObservations: [observation],
      derivedFromObservationIDs: [observation.observationID]
    )
    let report = try SharedEpisodeProvenanceValidator.analyze([value])

    XCTAssertEqual(try canonicalRoundTrip(correlation), correlation)
    XCTAssertEqual(try canonicalRoundTrip(observation), observation)
    XCTAssertEqual(try canonicalRoundTrip(value), value)
    XCTAssertEqual(try canonicalRoundTrip(report), report)
    XCTAssertFalse(report.semanticIndependenceProven)
  }

  private func provenance(
    id: String,
    executorID: String,
    roleID: String,
    workPackageArtifactID: String,
    modelID: String?,
    providerID: String?,
    taskSHA256: String,
    localInputSHA256s: [String],
    parentGenerationSHA256: String,
    resultSHA256: String,
    correlationLinks: [SharedEpisodeCorrelationLink],
    instrumentObservations: [SharedEpisodeInstrumentObservation] = [],
    derivedFromObservationIDs: [String] = []
  ) -> SharedEpisodeContributionProvenance {
    SharedEpisodeContributionProvenance(
      contributionID: id,
      executorID: executorID,
      roleID: roleID,
      workPackageArtifactID: workPackageArtifactID,
      modelID: modelID,
      providerID: providerID,
      taskSHA256: taskSHA256,
      localInputSHA256s: localInputSHA256s,
      parentGenerationSHA256: parentGenerationSHA256,
      resultSHA256: resultSHA256,
      correlationLinks: correlationLinks,
      instrumentObservations: instrumentObservations,
      derivedFromObservationIDs: derivedFromObservationIDs
    )
  }

  private func link(
    _ groupID: String,
    _ kind: SharedEpisodeCorrelationKind,
    _ basisSHA256: String,
    sourceContributionID: String? = nil
  ) -> SharedEpisodeCorrelationLink {
    SharedEpisodeCorrelationLink(
      groupID: groupID,
      kind: kind,
      basisSHA256: basisSHA256,
      sourceContributionID: sourceContributionID
    )
  }

  private func sha(_ digit: Character) -> String {
    "sha256:" + String(repeating: digit, count: 64)
  }

  private func canonicalRoundTrip<T>(
    _ value: T
  ) throws -> T where T: SharedEpisodeCanonicalValue & Equatable {
    let canonical = try value.canonicalJSONData()
    let decoded = try JSONDecoder().decode(T.self, from: canonical)
    XCTAssertEqual(decoded, value)
    XCTAssertEqual(
      try decoded.canonicalJSONData(),
      canonical
    )
    return decoded
  }
}
