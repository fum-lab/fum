import FUMLiveEpisodeCore
import Foundation

public enum LiveSingleAgentScenarioError: Error, Equatable, Sendable {
  case unsafeSourceDirectory
  case sourceDirectoryIsNotEmpty
  case invalidGitOutput(String)
  case deterministicValueMismatch(field: String, expected: String, actual: String)
}

extension LiveSingleAgentScenarioError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unsafeSourceDirectory:
      "Каталог исходного checkout должен быть существующим обычным пустым каталогом."
    case .sourceDirectoryIsNotEmpty:
      "Каталог исходного checkout должен быть пуст до подготовки сценария."
    case .invalidGitOutput(let message):
      message
    case .deterministicValueMismatch(let field, let expected, let actual):
      "Детерминированное значение \(field) не совпало: ожидалось \(expected), получено \(actual)."
    }
  }
}

/// Narrow synthetic Git scenario shared by the autonomous and opt-in live episode drivers.
/// The plan contains only repository-relative paths; the absolute source URL is runtime state.
public struct LiveSingleAgentScenario: Sendable {
  public let sourceCheckoutURL: URL
  public let plan: LiveGitCandidatePlan
  public let coordinates: LiveTransitionCoordinates
  public let actionAllowlist: [LiveAllowedAction]

  public var allowance: LiveAllowedAction { actionAllowlist[0] }
}

public enum LiveSingleAgentScenarioFactory {
  public static let artifactPath = "artifact.txt"
  public static let baseContents = Data("before\n".utf8)
  public static let candidateContents = Data("accepted\n".utf8)

  public static let baseBlobOID = "90be1f3056c4f471f977a28497b8d4b392c55a02"
  public static let baseTreeOID = "9f64cbfe95218530853d02a6726b7d7ab162f9ff"
  public static let baseCommitOID = "8c7ef0d85b6daae8fa9da249c0fe8932af2acd6e"
  public static let candidateBlobOID = "377cefa1ad78444622e2177083b644daf6f6dee6"
  public static let candidateTreeOID = "f7ba19785b4baa61770683c46cece0ec58e7d3a7"
  public static let candidateCommitOID = "27b70453870750f7504db957176aec88f90705ea"
  public static let planSHA256 =
    "sha256:ea37f8d99e51e22ac31108472f0389d59f8788c4368812fd62729e0a6a563808"

  public static let candidateBranch = "refs/heads/fum-live-episode-candidate"
  public static let resultRef = "refs/fum/candidates/fum-live-episode-candidate"

  /// Builds and validates the fixed plan without touching a checkout.
  public static func makePlan() throws -> LiveGitCandidatePlan {
    let candidateSignature = LiveGitCandidateSignature(
      name: "FUM Runtime Fixture",
      email: "fum-runtime@example.invalid",
      timestampSeconds: 1_700_000_060,
      timeZoneOffsetMinutes: 0
    )
    let policy = LiveGitCandidateCommitPolicy(
      allowedPaths: [artifactPath],
      checkers: [
        LiveGitCandidateCheckerSpec(
          checkerID: "git-diff-check",
          argvGrammar: .gitDiffCheckV1
        )
      ],
      baseCommitOID: baseCommitOID,
      expectedTreeOID: candidateTreeOID,
      expectedCandidateOID: candidateCommitOID,
      candidateBranch: candidateBranch,
      resultRef: resultRef,
      author: candidateSignature,
      committer: candidateSignature,
      message: "FUM live episode candidate\n",
      producerIDs: LiveGitCandidateProducerIDs(
        transitionUserConfirmed: "single-agent-runtime.confirmation.v1",
        authorized: "single-agent-runtime.authorization.v1",
        preflightPassed: "git-candidate-adapter.preflight.v1",
        executed: "git-candidate-adapter.execution.v1",
        observed: "git-candidate-adapter.observation.v1"
      )
    )
    try policy.validate()
    let plan = LiveGitCandidatePlan(
      policy: policy,
      writes: [
        LiveGitRegularFileWrite(
          path: artifactPath,
          mode: .regular,
          contents: candidateContents
        )
      ],
      preflightEventID: "event-candidate-preflight",
      preflightReceiptID: "receipt-candidate-preflight",
      executionEventID: "event-candidate-execution",
      executionReceiptID: "receipt-candidate-execution",
      observationEventID: "event-candidate-observation",
      observationReceiptID: "receipt-candidate-observation"
    )
    try require(
      try plan.canonicalSHA256(),
      equals: planSHA256,
      field: "plan SHA-256"
    )
    return plan
  }

  /// Initializes the exact SHA-1 source fixture in an existing empty ordinary directory.
  public static func prepare(at sourceCheckoutURL: URL) throws -> LiveSingleAgentScenario {
    let sourceURL = sourceCheckoutURL.standardizedFileURL
    try requireEmptyPlainDirectory(sourceURL)

    let runner = LiveGitProcessRunner()
    _ = try runner.run(
      ["init", "--quiet", "--initial-branch=master", "--object-format=sha1"],
      at: sourceURL
    )

    let artifactURL = sourceURL.appendingPathComponent(artifactPath, isDirectory: false)
    try baseContents.write(to: artifactURL, options: [.withoutOverwriting])

    let observedBaseBlob = try gitLine(
      runner.run(["hash-object", "-w", "--stdin"], at: sourceURL, input: baseContents).output
    )
    try require(observedBaseBlob, equals: baseBlobOID, field: "base blob OID")
    _ = try runner.run(
      ["update-index", "--add", "--cacheinfo", "100644", observedBaseBlob, artifactPath],
      at: sourceURL
    )
    let observedBaseTree = try gitLine(runner.run(["write-tree"], at: sourceURL).output)
    try require(observedBaseTree, equals: baseTreeOID, field: "base tree OID")

    let baseSignature = LiveGitCandidateSignature(
      name: "FUM Runtime Fixture",
      email: "fum-runtime@example.invalid",
      timestampSeconds: 1_700_000_000,
      timeZoneOffsetMinutes: 0
    )
    let observedBaseCommit = try gitLine(
      runner.run(
        ["commit-tree", observedBaseTree],
        at: sourceURL,
        input: Data("Base fixture\n".utf8),
        additionalEnvironment: gitIdentityEnvironment(baseSignature)
      ).output
    )
    try require(observedBaseCommit, equals: baseCommitOID, field: "base commit OID")
    _ = try runner.run(["update-ref", "refs/heads/master", observedBaseCommit], at: sourceURL)
    _ = try runner.run(["symbolic-ref", "HEAD", "refs/heads/master"], at: sourceURL)
    _ = try runner.run(["reset", "--hard", observedBaseCommit], at: sourceURL)

    try validateCandidateObjectIDs(runner: runner, sourceURL: sourceURL)
    try validatePreparedSource(runner: runner, sourceURL: sourceURL)

    let plan = try makePlan()
    let coordinates = LiveTransitionCoordinates(
      episodeID: "episode-single-agent-v1",
      transitionID: "transition-candidate",
      objectID: "candidate-artifact",
      expectedEffectSHA256: planSHA256
    )
    let allowance = LiveAllowedAction(
      allowanceID: "allow-git-candidate",
      operation: LiveGitCandidateContract.operation,
      adapterID: "fum-git-candidate-v1",
      effectClass: "isolated-git-write",
      candidateCommitPolicy: plan.policy
    )
    try allowance.validateCandidateCommitPolicy()
    return LiveSingleAgentScenario(
      sourceCheckoutURL: sourceURL,
      plan: plan,
      coordinates: coordinates,
      actionAllowlist: [allowance]
    )
  }

  /// Rechecks that candidate execution in the isolated clone did not alter the source checkout.
  public static func auditPreparedSource(at sourceCheckoutURL: URL) throws {
    let sourceURL = sourceCheckoutURL.standardizedFileURL
    let values = try sourceURL.resourceValues(forKeys: [
      .isDirectoryKey,
      .isSymbolicLinkKey,
    ])
    guard values.isDirectory == true, values.isSymbolicLink != true else {
      throw LiveSingleAgentScenarioError.unsafeSourceDirectory
    }
    try validatePreparedSource(runner: LiveGitProcessRunner(), sourceURL: sourceURL)
  }

  private static func requireEmptyPlainDirectory(_ directoryURL: URL) throws {
    guard directoryURL.isFileURL else {
      throw LiveSingleAgentScenarioError.unsafeSourceDirectory
    }
    let values = try directoryURL.resourceValues(forKeys: [
      .isDirectoryKey,
      .isSymbolicLinkKey,
    ])
    guard values.isDirectory == true, values.isSymbolicLink != true else {
      throw LiveSingleAgentScenarioError.unsafeSourceDirectory
    }
    let entries = try FileManager.default.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: nil,
      options: []
    )
    guard entries.isEmpty else {
      throw LiveSingleAgentScenarioError.sourceDirectoryIsNotEmpty
    }
  }

  private static func validateCandidateObjectIDs(
    runner: LiveGitProcessRunner,
    sourceURL: URL
  ) throws {
    let observedBlob = try gitLine(
      runner.run(["hash-object", "--stdin"], at: sourceURL, input: candidateContents).output
    )
    try require(observedBlob, equals: candidateBlobOID, field: "candidate blob OID")

    var treeContents = Data("100644 \(artifactPath)\0".utf8)
    treeContents.append(try oidBytes(observedBlob))
    let observedTree = try gitLine(
      runner.run(
        ["hash-object", "-t", "tree", "--stdin"],
        at: sourceURL,
        input: treeContents
      ).output
    )
    try require(observedTree, equals: candidateTreeOID, field: "candidate tree OID")

    let signature = "FUM Runtime Fixture <fum-runtime@example.invalid> 1700000060 +0000"
    let treeHeader = "tree \(observedTree)\n"
    let parentHeader = "parent \(baseCommitOID)\n"
    let authorHeader = "author \(signature)\n"
    let committerHeader = "committer \(signature)\n"
    let commitText =
      treeHeader + parentHeader + authorHeader + committerHeader
      + "\nFUM live episode candidate\n"
    let commitContents = Data(commitText.utf8)
    let observedCommit = try gitLine(
      runner.run(
        ["hash-object", "-t", "commit", "--stdin"],
        at: sourceURL,
        input: commitContents
      ).output
    )
    try require(observedCommit, equals: candidateCommitOID, field: "candidate commit OID")
  }

  private static func validatePreparedSource(
    runner: LiveGitProcessRunner,
    sourceURL: URL
  ) throws {
    try require(
      try gitLine(runner.run(["rev-parse", "--show-object-format"], at: sourceURL).output),
      equals: "sha1",
      field: "Git object format"
    )
    try require(
      try gitLine(runner.run(["rev-parse", "--verify", "HEAD^{commit}"], at: sourceURL).output),
      equals: baseCommitOID,
      field: "source HEAD"
    )
    try require(
      try gitLine(runner.run(["symbolic-ref", "HEAD"], at: sourceURL).output),
      equals: "refs/heads/master",
      field: "source HEAD ref"
    )
    try require(
      try gitLine(runner.run(["rev-parse", "HEAD^{tree}"], at: sourceURL).output),
      equals: baseTreeOID,
      field: "source HEAD tree"
    )
    guard
      try runner.run(
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        at: sourceURL
      ).output.isEmpty
    else {
      throw LiveSingleAgentScenarioError.invalidGitOutput(
        "Подготовленный исходный checkout не является чистым."
      )
    }
    guard try Data(contentsOf: sourceURL.appendingPathComponent(artifactPath)) == baseContents
    else {
      throw LiveSingleAgentScenarioError.invalidGitOutput(
        "Подготовленный artifact.txt не содержит точное базовое значение."
      )
    }
    for ref in [candidateBranch, resultRef] {
      let result = try runner.run(
        ["show-ref", "--verify", "--quiet", ref],
        at: sourceURL,
        acceptedStatuses: [0, 1]
      )
      guard result.status == 1 else {
        throw LiveSingleAgentScenarioError.invalidGitOutput(
          "Изолированная candidate-ссылка неожиданно появилась в исходном репозитории."
        )
      }
    }
    let candidateObject = try runner.run(
      ["cat-file", "-e", "\(candidateCommitOID)^{commit}"],
      at: sourceURL,
      acceptedStatuses: [0, 1, 128]
    )
    guard candidateObject.status != 0 else {
      throw LiveSingleAgentScenarioError.invalidGitOutput(
        "Candidate commit не должен существовать в исходной object database."
      )
    }
  }

  private static func gitIdentityEnvironment(
    _ signature: LiveGitCandidateSignature
  ) -> [String: String] {
    let date = "\(signature.timestampSeconds) +0000"
    return [
      "GIT_AUTHOR_NAME": signature.name,
      "GIT_AUTHOR_EMAIL": signature.email,
      "GIT_AUTHOR_DATE": date,
      "GIT_COMMITTER_NAME": signature.name,
      "GIT_COMMITTER_EMAIL": signature.email,
      "GIT_COMMITTER_DATE": date,
    ]
  }

  private static func oidBytes(_ oid: String) throws -> Data {
    guard oid.count == 40 else {
      throw LiveSingleAgentScenarioError.invalidGitOutput(
        "Candidate blob OID не является точным SHA-1."
      )
    }
    var result = Data()
    result.reserveCapacity(20)
    var index = oid.startIndex
    while index < oid.endIndex {
      let next = oid.index(index, offsetBy: 2)
      guard let byte = UInt8(oid[index..<next], radix: 16) else {
        throw LiveSingleAgentScenarioError.invalidGitOutput(
          "Candidate blob OID содержит не-hex значение."
        )
      }
      result.append(byte)
      index = next
    }
    return result
  }

  private static func gitLine(_ data: Data) throws -> String {
    guard let output = String(data: data, encoding: .utf8) else {
      throw LiveSingleAgentScenarioError.invalidGitOutput("Git вернул не-UTF-8 вывод.")
    }
    let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !line.isEmpty, !line.contains("\n"), !line.contains("\r") else {
      throw LiveSingleAgentScenarioError.invalidGitOutput(
        "Git не вернул одну ожидаемую строку."
      )
    }
    return line
  }

  private static func require(_ actual: String, equals expected: String, field: String) throws {
    guard actual == expected else {
      throw LiveSingleAgentScenarioError.deterministicValueMismatch(
        field: field,
        expected: expected,
        actual: actual
      )
    }
  }
}
