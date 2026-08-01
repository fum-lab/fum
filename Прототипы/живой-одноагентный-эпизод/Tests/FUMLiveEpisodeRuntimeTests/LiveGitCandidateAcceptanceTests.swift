import Darwin
import Foundation
import XCTest

@testable import FUMLiveEpisodeCore
@testable import FUMLiveEpisodeRuntime

final class LiveGitCandidateAcceptanceTests: XCTestCase {
  func testHeadlessProbeRejectsUnknownCommandField() throws {
    try withScratchDirectory { directory in
      let input = Data(
        #"""
        {"candidate_oid":"1111111111111111111111111111111111111111","command_id":"accept-command","schema_version":1,"untrusted_model_confirmation":true}
        """#.utf8
      )

      let execution = try runAcceptanceProbe(episode: directory, input: input)

      XCTAssertEqual(execution.status, 2)
      XCTAssertTrue(execution.output.isEmpty)
      XCTAssertTrue(
        String(decoding: execution.errorOutput, as: UTF8.self)
          .contains("invalid_command")
      )
    }
  }

  func testReceiptPublicationIsIdempotentAndConflictClosed() throws {
    try withScratchDirectory { directory in
      let oid = String(repeating: "1", count: 40)
      let receipt = LiveGitCandidateAcceptanceReceipt(
        verdict: .accepted,
        currentGenerationSHA256: hash("current"),
        admissionSHA256: hash("admission"),
        passportSHA256: hash("passport"),
        candidateOID: oid,
        observation: LiveGitCandidateAcceptanceObservation(
          parentOID: String(repeating: "2", count: 40),
          treeOID: String(repeating: "3", count: 40),
          rawCommitSHA256: hash("commit"),
          nulDiffSHA256: hash("diff"),
          changedPaths: ["README.md"],
          checkers: [
            LiveGitCandidateAcceptanceCheckerObservation(
              checkerID: "checker-git-diff",
              status: .passed,
              observationSHA256: hash("checker")
            )
          ]
        ),
        rejectionCodes: []
      )
      let store = LiveGitCandidateAcceptanceReceiptStore(episodeDirectoryURL: directory)

      let first = try store.publish(receipt)
      let repeated = try store.publish(receipt)

      XCTAssertEqual(first, repeated)
      let receiptDirectory = directory.appendingPathComponent("git-candidate-acceptance")
      XCTAssertEqual(
        try FileManager.default.contentsOfDirectory(atPath: receiptDirectory.path),
        ["\(oid).json"]
      )

      let conflicting = LiveGitCandidateAcceptanceReceipt(
        verdict: .rejected,
        currentGenerationSHA256: hash("current"),
        admissionSHA256: hash("admission"),
        passportSHA256: hash("passport"),
        candidateOID: oid,
        observation: receipt.observation,
        rejectionCodes: ["checker_failed"]
      )
      XCTAssertThrowsError(try store.publish(conflicting)) { error in
        XCTAssertEqual(error as? LiveGitCandidateAcceptanceError, .receiptConflict)
      }
    }
  }

  func testReceiptRetryLeavesSingleLinkAndRejectsHardlinkAliases() throws {
    try withScratchDirectory { directory in
      let oid = String(repeating: "1", count: 40)
      let receipt = LiveGitCandidateAcceptanceReceipt(
        verdict: .rejected,
        currentGenerationSHA256: hash("current"),
        admissionSHA256: hash("admission"),
        passportSHA256: hash("passport"),
        candidateOID: oid,
        observation: nil,
        rejectionCodes: ["synthetic_rejection"]
      )
      let store = LiveGitCandidateAcceptanceReceiptStore(episodeDirectoryURL: directory)
      let first = try store.publish(receipt)
      let receiptDirectory = directory.appendingPathComponent(
        "git-candidate-acceptance",
        isDirectory: true
      )
      let receiptURL = receiptDirectory.appendingPathComponent("\(oid).json")

      let repeated = try store.publish(receipt)

      XCTAssertEqual(repeated, first)
      XCTAssertEqual(
        try FileManager.default.contentsOfDirectory(atPath: receiptDirectory.path).sorted(),
        ["\(oid).json"]
      )
      var metadata = stat()
      XCTAssertEqual(lstat(receiptURL.path, &metadata), 0)
      XCTAssertEqual(metadata.st_nlink, 1)

      let internalAliasURL = receiptDirectory.appendingPathComponent(
        ".receipt-\(UUID().uuidString)"
      )
      try FileManager.default.linkItem(at: receiptURL, to: internalAliasURL)
      XCTAssertThrowsError(try store.publish(receipt))
      try FileManager.default.removeItem(at: internalAliasURL)

      let externalAliasURL = directory.appendingPathComponent("outside-receipt-hardlink.json")
      try FileManager.default.linkItem(at: receiptURL, to: externalAliasURL)
      XCTAssertThrowsError(try store.publish(receipt))
    }
  }

  func testReceiptPublicationRejectsSymlinkDirectory() throws {
    try withScratchDirectory { directory in
      let outside = directory.appendingPathComponent("outside", isDirectory: true)
      try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
      try FileManager.default.createSymbolicLink(
        at: directory.appendingPathComponent("git-candidate-acceptance"),
        withDestinationURL: outside
      )
      let receipt = LiveGitCandidateAcceptanceReceipt(
        verdict: .rejected,
        currentGenerationSHA256: hash("current"),
        admissionSHA256: hash("admission"),
        passportSHA256: hash("passport"),
        candidateOID: String(repeating: "1", count: 40),
        observation: nil,
        rejectionCodes: ["symlink_escape"]
      )

      XCTAssertThrowsError(
        try LiveGitCandidateAcceptanceReceiptStore(episodeDirectoryURL: directory)
          .publish(receipt)
      )
      XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: outside.path), [])
    }
  }

  func testHeadlessAcceptanceRerunsCheckerAndLeavesSourceAndMainUnchanged() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let sourceBefore = try fixture.sourceSnapshot()
      let mainBefore = try fixture.cloneMainSnapshot()
      let command = LiveGitCandidateAcceptanceCommand(
        commandID: "accept-candidate",
        candidateOID: fixture.candidateOID
      )

      let first = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(command)
      )
      let repeated = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(command)
      )

      XCTAssertEqual(first.status, 0, String(decoding: first.errorOutput, as: UTF8.self))
      XCTAssertEqual(repeated.status, 0, String(decoding: repeated.errorOutput, as: UTF8.self))
      let firstOutput = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: first.output
      )
      let repeatedOutput = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: repeated.output
      )
      XCTAssertEqual(firstOutput.verdict, .accepted)
      XCTAssertEqual(firstOutput.receiptSHA256, repeatedOutput.receiptSHA256)
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
      XCTAssertEqual(try fixture.cloneMainSnapshot(), mainBefore)

      let receiptURL = fixture.episodeURL
        .appendingPathComponent("git-candidate-acceptance", isDirectory: true)
        .appendingPathComponent("\(fixture.candidateOID).json", isDirectory: false)
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: receiptURL)
      )
      XCTAssertEqual(receipt.verdict, .accepted)
      XCTAssertEqual(receipt.observation?.checkers, fixture.expectedAcceptanceCheckers)
    }
  }

  func testHeadlessAcceptanceRequiresExactImmediateObservationConfirmation() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(
        at: root,
        checkerShouldFail: false,
        actualObservationConfirmationEventID: "event-foreign-generic-confirmation"
      )

      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "reject-foreign-generic-confirmation",
            candidateOID: fixture.candidateOID
          )
        )
      )

      XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: fixture.acceptanceReceiptURL)
      )
      XCTAssertEqual(receipt.rejectionCodes, ["observation_confirmation_invalid"])
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(
        at: root,
        checkerShouldFail: false,
        appendLaterGenerationConfirmation: true
      )

      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "reject-later-generation-confirmation",
            candidateOID: fixture.candidateOID
          )
        )
      )

      XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: fixture.acceptanceReceiptURL)
      )
      XCTAssertEqual(receipt.rejectionCodes, ["observation_confirmation_invalid"])
    }
  }

  func testWrongOIDMissingOrCorruptCurrentAndTamperedPassportAreClosed() throws {
    try withScratchDirectory { root in
      let emptyEpisode = root.appendingPathComponent("empty-episode", isDirectory: true)
      try FileManager.default.createDirectory(
        at: emptyEpisode,
        withIntermediateDirectories: true
      )
      let noCurrent = try runAcceptanceProbe(
        episode: emptyEpisode,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "no-current",
            candidateOID: String(repeating: "1", count: 40)
          )
        )
      )
      XCTAssertEqual(noCurrent.status, 2)
      XCTAssertTrue(
        String(decoding: noCurrent.errorOutput, as: UTF8.self)
          .contains("no_confirmed_current")
      )
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let wrongOID = fixture.baseOID
      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "wrong-oid",
            candidateOID: wrongOID
          )
        )
      )
      XCTAssertEqual(execution.status, 0)
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      var passportData = try Data(contentsOf: fixture.passportURL)
      passportData.append(0x20)
      try passportData.write(to: fixture.passportURL)
      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "tampered-passport",
            candidateOID: fixture.candidateOID
          )
        )
      )
      XCTAssertEqual(execution.status, 0)
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let currentURL = fixture.episodeURL.appendingPathComponent("CURRENT.json")
      try Data(#"{"schema_version":2}"#.utf8).write(to: currentURL)
      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "corrupt-current",
            candidateOID: fixture.candidateOID
          )
        )
      )
      XCTAssertEqual(execution.status, 2)
      XCTAssertTrue(String(decoding: execution.errorOutput, as: UTF8.self).contains("rejected"))
    }
  }

  func testHeadlessAcceptanceRejectsHardlinkedCandidatePassport() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      try FileManager.default.linkItem(
        at: fixture.passportURL,
        to: root.appendingPathComponent("outside-passport-hardlink.json")
      )

      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "hardlinked-passport",
            candidateOID: fixture.candidateOID
          )
        )
      )

      XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: fixture.acceptanceReceiptURL)
      )
      XCTAssertEqual(receipt.rejectionCodes, ["passport_not_regular"])
    }
  }

  func testHeadlessAcceptanceRejectsUnsafeCurrentAndGenerationArtifacts() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let currentURL = fixture.episodeURL.appendingPathComponent("CURRENT.json")
      let outsideURL = root.appendingPathComponent("outside-current.json")
      try FileManager.default.moveItem(at: currentURL, to: outsideURL)
      try FileManager.default.createSymbolicLink(
        at: currentURL,
        withDestinationURL: outsideURL
      )

      try assertAcceptanceStoreRejected(fixture, commandID: "symlink-current")
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let currentURL = fixture.episodeURL.appendingPathComponent("CURRENT.json")
      try FileManager.default.linkItem(
        at: currentURL,
        to: root.appendingPathComponent("outside-current-hardlink.json")
      )

      try assertAcceptanceStoreRejected(fixture, commandID: "hardlink-current")
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let currentURL = fixture.episodeURL.appendingPathComponent("CURRENT.json")
      try FileManager.default.removeItem(at: currentURL)
      XCTAssertEqual(mkfifo(currentURL.path, S_IRUSR | S_IWUSR), 0)

      try assertAcceptanceStoreRejected(fixture, commandID: "fifo-current")
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let generationURL = try currentGenerationURL(in: fixture.episodeURL)
      let outsideURL = root.appendingPathComponent("outside-generation.json")
      try FileManager.default.moveItem(at: generationURL, to: outsideURL)
      try FileManager.default.createSymbolicLink(
        at: generationURL,
        withDestinationURL: outsideURL
      )

      try assertAcceptanceStoreRejected(fixture, commandID: "symlink-generation")
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let generationURL = try currentGenerationURL(in: fixture.episodeURL)
      try FileManager.default.linkItem(
        at: generationURL,
        to: root.appendingPathComponent("outside-generation-hardlink.json")
      )

      try assertAcceptanceStoreRejected(fixture, commandID: "hardlink-generation")
    }
  }

  func testHeadlessAcceptanceIndependentlyRejectsTamperedCloneMetadata() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let sourceBefore = try fixture.sourceSnapshot()
      let objectsURL = fixture.cloneURL.appendingPathComponent(".git/objects", isDirectory: true)
      let fanout = try unusedObjectFanout(in: objectsURL)
      let outsideURL = root.appendingPathComponent("outside-object-fanout", isDirectory: true)
      try FileManager.default.createDirectory(at: outsideURL, withIntermediateDirectories: false)
      try FileManager.default.createSymbolicLink(
        at: objectsURL.appendingPathComponent(fanout, isDirectory: true),
        withDestinationURL: outsideURL
      )

      try assertCandidateMetadataRejected(fixture, commandID: "symlink-object-fanout")
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let sourceBefore = try fixture.sourceSnapshot()
      let nestedRefsURL = fixture.cloneURL.appendingPathComponent(
        ".git/refs/heads/fum-candidate",
        isDirectory: true
      )
      let outsideURL = root.appendingPathComponent("outside-candidate-refs", isDirectory: true)
      try FileManager.default.moveItem(at: nestedRefsURL, to: outsideURL)
      try FileManager.default.createSymbolicLink(
        at: nestedRefsURL,
        withDestinationURL: outsideURL
      )

      try assertCandidateMetadataRejected(fixture, commandID: "symlink-nested-ref")
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let sourceBefore = try fixture.sourceSnapshot()
      let objectURL = fixture.cloneURL.appendingPathComponent(
        ".git/objects/\(fixture.candidateOID.prefix(2))/\(fixture.candidateOID.dropFirst(2))",
        isDirectory: false
      )
      try FileManager.default.linkItem(
        at: objectURL,
        to: root.appendingPathComponent("outside-candidate-object")
      )

      try assertCandidateMetadataRejected(fixture, commandID: "hardlink-candidate-object")
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }

    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let sourceBefore = try fixture.sourceSnapshot()
      let externalMarkerURL = root.appendingPathComponent("hostile-config-executed")
      let configURL = fixture.cloneURL.appendingPathComponent(
        ".git/config",
        isDirectory: false
      )
      let hostileConfig = """
        [core]
        \trepositoryformatversion = 0
        \tfilemode = true
        \tbare = false
        \tlogallrefupdates = true
        \tfsmonitor = /usr/bin/touch \(externalMarkerURL.path)
        [extensions]
        \tpartialclone = origin
        [remote "origin"]
        \turl = file://\(fixture.sourceURL.path)
        \tpromisor = true

        """
      try Data(hostileConfig.utf8).write(to: configURL)

      try assertCandidateMetadataRejected(fixture, commandID: "hostile-promisor-config")
      XCTAssertFalse(FileManager.default.fileExists(atPath: externalMarkerURL.path))
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
    }
  }

  func testCheckerIsRerunAndRejectsAFalseStoredPass() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: true)
      let sourceBefore = try fixture.sourceSnapshot()
      let mainBefore = try fixture.cloneMainSnapshot()

      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "rerun-failing-checker",
            candidateOID: fixture.candidateOID
          )
        )
      )

      XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
      XCTAssertEqual(try fixture.sourceSnapshot(), sourceBefore)
      XCTAssertEqual(try fixture.cloneMainSnapshot(), mainBefore)
      let receipt = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceReceipt.self,
        from: Data(contentsOf: fixture.acceptanceReceiptURL)
      )
      XCTAssertEqual(receipt.rejectionCodes, ["checker_failed"])
    }
  }

  func testSymbolicCandidateRefIsRejectedEvenWhenItResolvesToExactOID() throws {
    try withScratchDirectory { root in
      let fixture = try makeAcceptanceFixture(at: root, checkerShouldFail: false)
      let targetRef = "refs/heads/fum-candidate/acceptance-target"
      try runTestGit(["update-ref", targetRef, fixture.candidateOID], at: fixture.cloneURL)
      try runTestGit(
        ["update-ref", "-d", fixture.passport.candidateBranchRef, fixture.candidateOID],
        at: fixture.cloneURL
      )
      try runTestGit(
        ["symbolic-ref", fixture.passport.candidateBranchRef, targetRef],
        at: fixture.cloneURL
      )

      let execution = try runAcceptanceProbe(
        episode: fixture.episodeURL,
        input: try LiveEpisodeRuntimeJSON.encode(
          LiveGitCandidateAcceptanceCommand(
            commandID: "symbolic-candidate-ref",
            candidateOID: fixture.candidateOID
          )
        )
      )

      XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
      let output = try LiveEpisodeRuntimeJSON.decode(
        LiveGitCandidateAcceptanceOutput.self,
        from: execution.output
      )
      XCTAssertEqual(output.verdict, .rejected)
    }
  }

  private func withScratchDirectory(_ body: (URL) throws -> Void) throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "fum-live-candidate-acceptance-tests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try body(directory)
  }

  private func runAcceptanceProbe(episode: URL, input: Data) throws -> ProbeExecution {
    let process = Process()
    process.executableURL = try acceptanceProbeExecutableURL()
    process.arguments = [episode.path]
    let standardInput = Pipe()
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardInput = standardInput
    process.standardOutput = standardOutput
    process.standardError = standardError
    let terminated = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in terminated.signal() }
    try process.run()
    try standardInput.fileHandleForWriting.write(contentsOf: input)
    try standardInput.fileHandleForWriting.close()
    guard terminated.wait(timeout: .now() + 30) == .success else {
      process.terminate()
      process.waitUntilExit()
      throw NSError(
        domain: "LiveGitCandidateAcceptanceTests",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Acceptance probe не завершился за 30 секунд."]
      )
    }
    process.waitUntilExit()
    return ProbeExecution(
      status: process.terminationStatus,
      output: standardOutput.fileHandleForReading.readDataToEndOfFile(),
      errorOutput: standardError.fileHandleForReading.readDataToEndOfFile()
    )
  }

  private func acceptanceProbeExecutableURL() throws -> URL {
    let executable =
      Bundle(for: LiveGitCandidateAcceptanceTests.self).bundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("FUMLiveCandidateAcceptanceProbe")
    guard FileManager.default.isExecutableFile(atPath: executable.path) else {
      throw NSError(
        domain: "LiveGitCandidateAcceptanceTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Acceptance probe executable не найден."]
      )
    }
    return executable
  }

  private func hash(_ value: String) -> String {
    LiveStrictIntentParser.sha256(of: value)
  }

  private func assertAcceptanceStoreRejected(
    _ fixture: AcceptanceFixture,
    commandID: String
  ) throws {
    let execution = try runAcceptanceProbe(
      episode: fixture.episodeURL,
      input: try LiveEpisodeRuntimeJSON.encode(
        LiveGitCandidateAcceptanceCommand(
          commandID: commandID,
          candidateOID: fixture.candidateOID
        )
      )
    )
    XCTAssertEqual(execution.status, 2)
    XCTAssertTrue(String(decoding: execution.errorOutput, as: UTF8.self).contains("rejected"))
  }

  private func currentGenerationURL(in episodeURL: URL) throws -> URL {
    let pointerData = try Data(
      contentsOf: episodeURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    )
    guard
      let object = try JSONSerialization.jsonObject(with: pointerData) as? [String: Any],
      let generationSHA256 = object["generation_sha256"] as? String,
      generationSHA256.hasPrefix("sha256:"),
      generationSHA256.count == 71
    else {
      throw NSError(
        domain: "LiveGitCandidateAcceptanceTests",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "CURRENT fixture не содержит generation_sha256."]
      )
    }
    return episodeURL.appendingPathComponent("generations", isDirectory: true)
      .appendingPathComponent(
        "\(generationSHA256.dropFirst(7)).json",
        isDirectory: false
      )
  }

  private func assertCandidateMetadataRejected(
    _ fixture: AcceptanceFixture,
    commandID: String
  ) throws {
    let execution = try runAcceptanceProbe(
      episode: fixture.episodeURL,
      input: try LiveEpisodeRuntimeJSON.encode(
        LiveGitCandidateAcceptanceCommand(
          commandID: commandID,
          candidateOID: fixture.candidateOID
        )
      )
    )
    XCTAssertEqual(execution.status, 0, String(decoding: execution.errorOutput, as: UTF8.self))
    let output = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceOutput.self,
      from: execution.output
    )
    XCTAssertEqual(output.verdict, .rejected)
    let receipt = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceReceipt.self,
      from: Data(contentsOf: fixture.acceptanceReceiptURL)
    )
    XCTAssertEqual(receipt.rejectionCodes, ["candidate_git_metadata_invalid"])
  }

  private func unusedObjectFanout(in objectsURL: URL) throws -> String {
    for value in 0...255 {
      let component = String(format: "%02x", value)
      if !FileManager.default.fileExists(
        atPath: objectsURL.appendingPathComponent(component, isDirectory: true).path
      ) {
        return component
      }
    }
    throw NSError(
      domain: "LiveGitCandidateAcceptanceTests",
      code: 4,
      userInfo: [NSLocalizedDescriptionKey: "Fixture не оставила свободного object fanout."]
    )
  }
}

private struct ProbeExecution {
  let status: Int32
  let output: Data
  let errorOutput: Data
}

private struct AcceptanceFixture {
  let sourceURL: URL
  let episodeURL: URL
  let cloneURL: URL
  let baseOID: String
  let candidateOID: String
  let passport: LiveGitCandidatePassport

  var passportURL: URL {
    episodeURL.appendingPathComponent(passport.storageRelativePath)
  }

  var acceptanceReceiptURL: URL {
    episodeURL
      .appendingPathComponent("git-candidate-acceptance", isDirectory: true)
      .appendingPathComponent("\(candidateOID).json", isDirectory: false)
  }

  var expectedAcceptanceCheckers: [LiveGitCandidateAcceptanceCheckerObservation] {
    passport.checkerObservations.map {
      LiveGitCandidateAcceptanceCheckerObservation(
        checkerID: $0.checkerID,
        status: $0.status == .passed ? .passed : .failed,
        observationSHA256: $0.observationSHA256
      )
    }
  }

  func sourceSnapshot() throws -> [Data] {
    [
      try runTestGit(["rev-parse", "HEAD"], at: sourceURL),
      try runTestGit(["show-ref", "--head"], at: sourceURL),
      try runTestGit(["ls-files", "--stage", "-z"], at: sourceURL),
      try runTestGit(
        ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
        at: sourceURL
      ),
      try Data(contentsOf: sourceURL.appendingPathComponent("README.md")),
    ]
  }

  func cloneMainSnapshot() throws -> [Data] {
    [
      try runTestGit(["rev-parse", "refs/heads/master"], at: cloneURL),
      try runTestGit(["symbolic-ref", "HEAD"], at: cloneURL),
    ]
  }
}

private func makeAcceptanceFixture(
  at rootURL: URL,
  checkerShouldFail: Bool,
  actualObservationConfirmationEventID: String? = nil,
  appendLaterGenerationConfirmation: Bool = false
) throws -> AcceptanceFixture {
  let sourceURL = rootURL.appendingPathComponent("source", isDirectory: true)
  let episodeURL = rootURL.appendingPathComponent("episode", isDirectory: true)
  let cloneURL = episodeURL.appendingPathComponent(
    LiveGitCandidateRuntimeSchema.cloneRelativePath,
    isDirectory: true
  )
  try FileManager.default.createDirectory(at: sourceURL, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: episodeURL, withIntermediateDirectories: true)
  try runTestGit(["init", "--initial-branch=master"], at: sourceURL)
  try Data("base\n".utf8).write(to: sourceURL.appendingPathComponent("README.md"))
  try runTestGit(["add", "--", "README.md"], at: sourceURL)
  let baseTree = try gitLine(runTestGit(["write-tree"], at: sourceURL))
  let baseOID = try commitTree(
    treeOID: baseTree,
    parentOID: nil,
    message: "Base fixture\n",
    at: sourceURL,
    timestamp: "1600000000 +0000"
  )
  try runTestGit(["update-ref", "refs/heads/master", baseOID], at: sourceURL)
  try runTestGit(["symbolic-ref", "HEAD", "refs/heads/master"], at: sourceURL)
  try runTestGit(["reset", "--hard", baseOID], at: sourceURL)

  try runTestGit(
    [
      "clone", "--no-local", "--no-hardlinks", "--no-checkout",
      sourceURL.path, cloneURL.path,
    ],
    at: rootURL
  )
  try runTestGit(["remote", "remove", "origin"], at: cloneURL)
  let candidateContents = checkerShouldFail ? "candidate trailing space \n" : "candidate\n"
  try Data(candidateContents.utf8).write(to: cloneURL.appendingPathComponent("README.md"))
  try runTestGit(["add", "--", "README.md"], at: cloneURL)
  let candidateTree = try gitLine(runTestGit(["write-tree"], at: cloneURL))
  let candidateOID = try commitTree(
    treeOID: candidateTree,
    parentOID: baseOID,
    message: "Candidate acceptance fixture\n",
    at: cloneURL,
    timestamp: "1700000000 +0000"
  )
  let candidateBranch = "refs/heads/fum-candidate/episode-acceptance"
  let resultRef = "refs/fum/candidates/episode-acceptance"
  try runTestGit(["update-ref", candidateBranch, candidateOID], at: cloneURL)
  try runTestGit(["update-ref", resultRef, candidateOID], at: cloneURL)
  try installAcceptanceCloneMetadata(
    sourceURL: sourceURL,
    cloneURL: cloneURL,
    baseOID: baseOID
  )

  let signature = LiveGitCandidateSignature(
    name: "FUM Acceptance Fixture",
    email: "acceptance@fum.invalid",
    timestampSeconds: 1_700_000_000,
    timeZoneOffsetMinutes: 0
  )
  let checker = LiveGitCandidateCheckerSpec(
    checkerID: "checker-git-diff",
    argvGrammar: .gitDiffCheckV1
  )
  let producerIDs = LiveGitCandidateProducerIDs(
    transitionUserConfirmed: "producer-user-confirmation",
    authorized: "producer-authorizer",
    preflightPassed: "producer-preflight",
    executed: "producer-git-executor",
    observed: "producer-git-observer"
  )
  let policy = LiveGitCandidateCommitPolicy(
    allowedPaths: ["README.md"],
    checkers: [checker],
    baseCommitOID: baseOID,
    expectedTreeOID: candidateTree,
    expectedCandidateOID: candidateOID,
    candidateBranch: candidateBranch,
    resultRef: resultRef,
    author: signature,
    committer: signature,
    message: "Candidate acceptance fixture\n",
    producerIDs: producerIDs
  )
  let write = LiveGitRegularFileWrite(
    path: "README.md",
    mode: .regular,
    contents: Data(candidateContents.utf8)
  )
  let plan = LiveGitCandidatePlan(
    policy: policy,
    writes: [write],
    preflightEventID: "event-preflight",
    preflightReceiptID: "receipt-preflight",
    executionEventID: "event-candidate-execution",
    executionReceiptID: "receipt-candidate-execution",
    observationEventID: "event-candidate-observation",
    observationReceiptID: "receipt-candidate-observation"
  )
  let planSHA256 = try plan.canonicalSHA256()
  let legacyFixture = try LiveEpisodeFixture.run()
  let coordinates = LiveTransitionCoordinates(
    episodeID: legacyFixture.passport.episodeID,
    transitionID: "transition-candidate-acceptance",
    objectID: "candidate-acceptance-object",
    expectedEffectSHA256: planSHA256
  )
  let expectedWrite = LiveGitCandidateExpectedWrite(
    path: "README.md",
    mode: .regular,
    contentsSHA256: testHash(candidateContents)
  )
  let provisionalPassport = LiveGitCandidatePassport(
    planSHA256: planSHA256,
    coordinates: coordinates,
    parentOID: baseOID,
    treeOID: candidateTree,
    candidateOID: candidateOID,
    candidateBranchRef: candidateBranch,
    resultRef: resultRef,
    allowedPaths: ["README.md"],
    changedPaths: ["README.md"],
    expectedWrites: [expectedWrite],
    checkerSpecifications: [checker],
    checkerObservations: [
      LiveGitCheckerObservation(
        checkerID: checker.checkerID,
        status: .passed,
        observationSHA256: testHash("placeholder-checker-observation")
      )
    ],
    author: signature,
    committer: signature,
    message: policy.message,
    preflightEventID: plan.preflightEventID,
    preflightReceiptID: plan.preflightReceiptID,
    executionEventID: plan.executionEventID,
    executionReceiptID: plan.executionReceiptID,
    observationEventID: plan.observationEventID,
    observationReceiptID: plan.observationReceiptID
  )
  let checkerObservations: [LiveGitCheckerObservation]
  if checkerShouldFail {
    checkerObservations = provisionalPassport.checkerObservations
  } else {
    checkerObservations = try LiveGitCheckerRegistry().verify(
      passport: provisionalPassport,
      episodeDirectoryURL: episodeURL
    )
  }
  let passport = LiveGitCandidatePassport(
    planSHA256: planSHA256,
    coordinates: coordinates,
    parentOID: baseOID,
    treeOID: candidateTree,
    candidateOID: candidateOID,
    candidateBranchRef: candidateBranch,
    resultRef: resultRef,
    allowedPaths: ["README.md"],
    changedPaths: ["README.md"],
    expectedWrites: [expectedWrite],
    checkerSpecifications: [checker],
    checkerObservations: checkerObservations,
    author: signature,
    committer: signature,
    message: policy.message,
    preflightEventID: plan.preflightEventID,
    preflightReceiptID: plan.preflightReceiptID,
    executionEventID: plan.executionEventID,
    executionReceiptID: plan.executionReceiptID,
    observationEventID: plan.observationEventID,
    observationReceiptID: plan.observationReceiptID
  )
  try passport.validate()
  let passportURL = episodeURL.appendingPathComponent(passport.storageRelativePath)
  try FileManager.default.createDirectory(
    at: passportURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try passport.canonicalJSON().write(to: passportURL)

  let legacy = legacyFixture.passport
  let livePassport = LiveEpisodePassport(
    schemaIdentity: legacy.schemaIdentity,
    schemaVersion: legacy.schemaVersion,
    episodeID: legacy.episodeID,
    goal: legacy.goal,
    context: legacy.context,
    modelPolicy: legacy.modelPolicy,
    actionAllowlist: [
      LiveAllowedAction(
        allowanceID: "allow-candidate",
        operation: LiveGitCandidateContract.operation,
        adapterID: "fum-git-candidate-v1",
        effectClass: "isolated_git_write",
        candidateCommitPolicy: policy
      )
    ],
    verificationCriteria: legacy.verificationCriteria,
    checkpointPolicy: legacy.checkpointPolicy,
    terminalOutcomes: legacy.terminalOutcomes
  )
  let observationConfirmationEventID = "event-confirm-observation-generation"
  let stored = try storeConfirmedObservedEpisode(
    passport: livePassport,
    coordinates: coordinates,
    candidatePassport: passport,
    sourceEvents: legacyFixture.events,
    episodeURL: episodeURL,
    observationConfirmationEventID: observationConfirmationEventID,
    actualObservationConfirmationEventID:
      actualObservationConfirmationEventID ?? observationConfirmationEventID,
    appendLaterGenerationConfirmation: appendLaterGenerationConfirmation
  )
  XCTAssertEqual(stored.state.transition?.phase, .observed)

  return AcceptanceFixture(
    sourceURL: sourceURL,
    episodeURL: episodeURL,
    cloneURL: cloneURL,
    baseOID: baseOID,
    candidateOID: candidateOID,
    passport: passport
  )
}

private struct AcceptanceCloneOwnerFixture: Encodable {
  let schemaIdentity = "fum.live_git_candidate.clone_owner"
  let schemaVersion = 1
  let sourceGitDirectory: String
  let baseOID: String
  let objectFormat: String

  enum CodingKeys: String, CodingKey {
    case schemaIdentity = "schema_identity"
    case schemaVersion = "schema_version"
    case sourceGitDirectory = "source_git_directory"
    case baseOID = "base_oid"
    case objectFormat = "object_format"
  }
}

private func installAcceptanceCloneMetadata(
  sourceURL: URL,
  cloneURL: URL,
  baseOID: String
) throws {
  let sourceGitDirectory = sourceURL.appendingPathComponent(".git", isDirectory: true)
    .standardizedFileURL.resolvingSymlinksInPath().path
  let objectFormat = try gitLine(
    runTestGit(["rev-parse", "--show-object-format"], at: cloneURL)
  )
  let gitURL = cloneURL.appendingPathComponent(".git", isDirectory: true)
  try acceptanceCanonicalCloneConfiguration(objectFormat: objectFormat).write(
    to: gitURL.appendingPathComponent("config", isDirectory: false)
  )
  let marker = AcceptanceCloneOwnerFixture(
    sourceGitDirectory: sourceGitDirectory,
    baseOID: baseOID,
    objectFormat: objectFormat
  )
  try LiveEpisodeRuntimeJSON.encode(marker).write(
    to: gitURL.appendingPathComponent("fum-runtime-owner.json", isDirectory: false)
  )
}

private func acceptanceCanonicalCloneConfiguration(objectFormat: String) -> Data {
  let repositoryFormatVersion = objectFormat == "sha256" ? 1 : 0
  var text = """
    [core]
    \trepositoryformatversion = \(repositoryFormatVersion)
    \tfilemode = true
    \tbare = false
    \tlogallrefupdates = true

    """
  if objectFormat == "sha256" {
    text += """
      [extensions]
      \tobjectformat = sha256

      """
  }
  return Data(text.utf8)
}

private func storeConfirmedObservedEpisode(
  passport: LiveEpisodePassport,
  coordinates: LiveTransitionCoordinates,
  candidatePassport: LiveGitCandidatePassport,
  sourceEvents: [LiveEpisodeEvent],
  episodeURL: URL,
  observationConfirmationEventID: String,
  actualObservationConfirmationEventID: String,
  appendLaterGenerationConfirmation: Bool
) throws -> StoredLiveEpisodeGeneration {
  var state = try LiveEpisodeReducer.initialState(passport: passport)
  var events: [LiveEpisodeEvent] = []
  let allowanceID = passport.actionAllowlist[0].allowanceID

  for sourceEvent in sourceEvents {
    if sourceEvent.kind == .budgetCheckpointCreated { continue }
    if sourceEvent.kind == .generationConfirmed || sourceEvent.kind == .continuationDecided {
      break
    }
    let payload: LiveEpisodeEventPayload
    switch sourceEvent.payload {
    case .pendingTransitionDeclared(let pending):
      payload = .pendingTransitionDeclared(
        LivePendingTransitionDeclared(
          coordinates: coordinates,
          allowanceID: allowanceID,
          parentCheckpointID: pending.parentCheckpointID
        )
      )
    case .modelResponseRecorded(let response):
      let intent = candidateIntent(variantID: response.variantID, coordinates: coordinates)
      let output = try LiveStrictIntentParser.canonicalOutput(for: intent)
      payload = .modelResponseRecorded(
        LiveModelResponseRecorded(
          responseID: response.responseID,
          requestID: response.requestID,
          variantID: response.variantID,
          providerIdentity: response.providerIdentity,
          status: response.status,
          output: output,
          outputSHA256: testHash(output),
          charged: response.charged
        )
      )
    case .untrustedIntentParsed(let parsed):
      payload = .untrustedIntentParsed(
        LiveUntrustedIntentParsed(
          variantID: parsed.variantID,
          sourceResponseID: parsed.sourceResponseID,
          intent: candidateIntent(variantID: parsed.variantID, coordinates: coordinates)
        )
      )
    default:
      payload = sourceEvent.payload
    }
    let event = LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: sourceEvent.eventID,
      sequence: state.nextSequence,
      payload: payload
    )
    state = try LiveEpisodeReducer.applying(event, to: state)
    events.append(event)
    if sourceEvent.kind == .modelSelectionRecorded { break }
  }

  var receipts: [LiveGitCandidateStageReceipt] = []
  func appendStage(
    eventID: String,
    receiptID: String,
    stage: LiveGitCandidateStage,
    producerID: String,
    evidence: LiveEvidenceObject,
    payload: LiveEpisodeEventPayload
  ) throws {
    let event = LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: eventID,
      sequence: state.nextSequence,
      payload: payload
    )
    state = try LiveEpisodeReducer.applying(event, to: state)
    events.append(event)
    let predecessor = try receipts.last.map {
      LiveGitCandidateReceiptLink(
        receiptID: $0.receiptID,
        receiptSHA256: try LiveGitCandidateCanonicalJSON.sha256($0)
      )
    }
    receipts.append(
      LiveGitCandidateStageReceipt(
        receiptID: receiptID,
        eventID: eventID,
        stage: stage,
        coordinates: coordinates,
        evidence: evidence,
        producerID: producerID,
        predecessor: predecessor
      )
    )
  }

  let confirmationEvidence = LiveEvidenceObject(
    evidenceID: "evidence-user-confirmation",
    evidenceSHA256: testHash("user-confirmation")
  )
  try appendStage(
    eventID: "event-user-confirmation",
    receiptID: "receipt-user-confirmation",
    stage: .transitionUserConfirmed,
    producerID: passport.actionAllowlist[0].candidateCommitPolicy!.producerIDs
      .transitionUserConfirmed,
    evidence: confirmationEvidence,
    payload: .transitionUserConfirmed(
      LiveTransitionUserConfirmed(
        coordinates: coordinates,
        evidence: confirmationEvidence
      )
    )
  )
  let authorizationEvidence = LiveEvidenceObject(
    evidenceID: "evidence-authorization",
    evidenceSHA256: testHash("authorization")
  )
  try appendStage(
    eventID: "event-authorization",
    receiptID: "receipt-authorization",
    stage: .authorized,
    producerID: passport.actionAllowlist[0].candidateCommitPolicy!.producerIDs.authorized,
    evidence: authorizationEvidence,
    payload: .authorizationDecided(
      LiveAuthorizationDecided(
        coordinates: coordinates,
        intentID: "intent-variant-a",
        allowanceID: allowanceID,
        decision: .allowed,
        evidence: authorizationEvidence
      )
    )
  )
  let preflightEvidence = LiveEvidenceObject(
    evidenceID: candidatePassport.preflightReceiptID,
    evidenceSHA256: testHash("preflight")
  )
  try appendStage(
    eventID: "event-preflight",
    receiptID: "receipt-preflight",
    stage: .preflightPassed,
    producerID: passport.actionAllowlist[0].candidateCommitPolicy!.producerIDs.preflightPassed,
    evidence: preflightEvidence,
    payload: .preflightCompleted(
      LivePreflightCompleted(
        coordinates: coordinates,
        authorizationEvidenceID: authorizationEvidence.evidenceID,
        status: .passed,
        evidence: preflightEvidence
      )
    )
  )
  let executionEvidence = LiveEvidenceObject(
    evidenceID: candidatePassport.executionReceiptID,
    evidenceSHA256: testHash(candidatePassport.candidateOID)
  )
  try appendStage(
    eventID: candidatePassport.executionEventID,
    receiptID: candidatePassport.executionReceiptID,
    stage: .executed,
    producerID: passport.actionAllowlist[0].candidateCommitPolicy!.producerIDs.executed,
    evidence: executionEvidence,
    payload: .executionRecorded(
      LiveExecutionRecorded(
        coordinates: coordinates,
        preflightEvidenceID: preflightEvidence.evidenceID,
        status: .succeeded,
        evidence: executionEvidence
      )
    )
  )
  let observationEvidence = LiveEvidenceObject(
    evidenceID: candidatePassport.observationReceiptID,
    evidenceSHA256: try candidatePassport.canonicalSHA256()
  )
  try appendStage(
    eventID: candidatePassport.observationEventID,
    receiptID: candidatePassport.observationReceiptID,
    stage: .observed,
    producerID: passport.actionAllowlist[0].candidateCommitPolicy!.producerIDs.observed,
    evidence: observationEvidence,
    payload: .observationRecorded(
      LiveObservationRecorded(
        coordinates: coordinates,
        executionEvidenceID: executionEvidence.evidenceID,
        status: .observed,
        evidence: observationEvidence
      )
    )
  )

  let invocations = events.compactMap { event -> LiveEpisodeInvocationReceipt? in
    guard case .modelRequestRecorded(let request) = event.payload,
      let responseEvent = events.first(where: { candidate in
        guard case .modelResponseRecorded(let response) = candidate.payload else {
          return false
        }
        return response.requestID == request.proposal.requestID
      }),
      case .modelResponseRecorded(let response) = responseEvent.payload
    else { return nil }
    return LiveEpisodeInvocationReceipt(
      requestEventID: event.eventID,
      responseEventID: responseEvent.eventID,
      responseID: response.responseID,
      budgetCheckpointEventID: "unused-budget-\(request.proposal.variantID)",
      budgetCheckpointID: "unused-checkpoint-\(request.proposal.variantID)",
      proposal: request.proposal,
      commandSHA256: testHash("command-\(request.proposal.variantID)")
    )
  }
  let store = LiveEpisodeGenerationStore(rootURL: episodeURL)
  let observed = try store.commit(
    passport: passport,
    events: events,
    invocations: invocations,
    candidateReceipts: receipts,
    candidateExecutionCommandSHA256: testHash("candidate-execution-command"),
    candidateObservationConfirmationEventID: observationConfirmationEventID,
    expectedPreviousGenerationSHA256: nil
  )
  let stateSHA256 = testHash(
    String(decoding: try LiveEpisodeRuntimeJSON.encode(state), as: UTF8.self)
  )
  let confirmation = LiveEpisodeEvent(
    episodeID: passport.episodeID,
    eventID: actualObservationConfirmationEventID,
    sequence: state.nextSequence,
    payload: .generationConfirmed(
      LiveGenerationConfirmed(
        generationID: String(observed.generationSHA256.dropFirst(7)),
        confirmedThroughSequence: state.nextSequence - 1,
        stateSHA256: stateSHA256
      )
    )
  )
  events.append(confirmation)
  var confirmed = try store.commit(
    passport: passport,
    events: events,
    invocations: invocations,
    candidateReceipts: receipts,
    candidateExecutionCommandSHA256: testHash("candidate-execution-command"),
    candidateObservationConfirmationEventID: observationConfirmationEventID,
    expectedPreviousGenerationSHA256: observed.generationSHA256
  )
  if appendLaterGenerationConfirmation {
    let laterConfirmation = LiveEpisodeEvent(
      episodeID: passport.episodeID,
      eventID: "event-later-generation-confirmation",
      sequence: confirmed.state.nextSequence,
      payload: .generationConfirmed(
        LiveGenerationConfirmed(
          generationID: String(confirmed.generationSHA256.dropFirst(7)),
          confirmedThroughSequence: confirmed.state.nextSequence - 1,
          stateSHA256: confirmed.generation.stateSHA256
        )
      )
    )
    events.append(laterConfirmation)
    confirmed = try store.commit(
      passport: passport,
      events: events,
      invocations: invocations,
      candidateReceipts: receipts,
      candidateExecutionCommandSHA256: testHash("candidate-execution-command"),
      candidateObservationConfirmationEventID: observationConfirmationEventID,
      expectedPreviousGenerationSHA256: confirmed.generationSHA256
    )
  }
  return confirmed
}

private func candidateIntent(
  variantID: String,
  coordinates: LiveTransitionCoordinates
) -> LiveUntrustedActionIntent {
  LiveUntrustedActionIntent(
    intentID: "intent-\(variantID)",
    operation: LiveGitCandidateContract.operation,
    adapterID: "fum-git-candidate-v1",
    effectClass: "isolated_git_write",
    objectID: coordinates.objectID,
    expectedEffectSHA256: coordinates.expectedEffectSHA256,
    argumentsSHA256: coordinates.expectedEffectSHA256
  )
}

@discardableResult
private func runTestGit(
  _ arguments: [String],
  at directory: URL,
  input: Data? = nil,
  identityTimestamp: String? = nil
) throws -> Data {
  let process = Process()
  let output = Pipe()
  let errors = Pipe()
  let standardInput = Pipe()
  process.executableURL = LiveGitSystemRuntime.gitExecutableURL
  process.arguments =
    [
      "--no-replace-objects", "-c",
      "core.hooksPath=\(LiveGitSystemRuntime.nullDevicePath)",
      "-c", "protocol.file.allow=always",
    ] + arguments
  process.currentDirectoryURL = directory
  var environment = [
    "GIT_ATTR_NOSYSTEM": "1",
    "GIT_CONFIG_GLOBAL": LiveGitSystemRuntime.nullDevicePath,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_NO_REPLACE_OBJECTS": "1",
    "GIT_OPTIONAL_LOCKS": "0",
    "GIT_TERMINAL_PROMPT": "0",
    "LANG": "C",
    "LC_ALL": "C",
    "PATH": LiveGitSystemRuntime.executableSearchPath,
    "TZ": "UTC",
  ]
  if let identityTimestamp {
    environment["GIT_AUTHOR_NAME"] = "FUM Acceptance Fixture"
    environment["GIT_AUTHOR_EMAIL"] = "acceptance@fum.invalid"
    environment["GIT_AUTHOR_DATE"] = identityTimestamp
    environment["GIT_COMMITTER_NAME"] = "FUM Acceptance Fixture"
    environment["GIT_COMMITTER_EMAIL"] = "acceptance@fum.invalid"
    environment["GIT_COMMITTER_DATE"] = identityTimestamp
  }
  process.environment = environment
  process.standardOutput = output
  process.standardError = errors
  process.standardInput = input == nil ? FileHandle.nullDevice : standardInput
  try process.run()
  if let input {
    try standardInput.fileHandleForWriting.write(contentsOf: input)
    try standardInput.fileHandleForWriting.close()
  }
  process.waitUntilExit()
  let stdout = output.fileHandleForReading.readDataToEndOfFile()
  let stderr = errors.fileHandleForReading.readDataToEndOfFile()
  guard process.terminationStatus == 0 else {
    throw NSError(
      domain: "LiveGitCandidateAcceptanceTests.Git",
      code: Int(process.terminationStatus),
      userInfo: [NSLocalizedDescriptionKey: String(decoding: stderr, as: UTF8.self)]
    )
  }
  return stdout
}

private func commitTree(
  treeOID: String,
  parentOID: String?,
  message: String,
  at directory: URL,
  timestamp: String
) throws -> String {
  var arguments = ["commit-tree", treeOID]
  if let parentOID { arguments += ["-p", parentOID] }
  arguments += ["-F", "-"]
  return try gitLine(
    runTestGit(
      arguments,
      at: directory,
      input: Data(message.utf8),
      identityTimestamp: timestamp
    )
  )
}

private func gitLine(_ data: Data) throws -> String {
  guard let value = String(data: data, encoding: .utf8),
    value.hasSuffix("\n"),
    !value.dropLast().contains("\n")
  else {
    throw NSError(
      domain: "LiveGitCandidateAcceptanceTests.Git",
      code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Git не вернул одну строку."]
    )
  }
  return String(value.dropLast())
}

private func testHash(_ value: String) -> String {
  LiveStrictIntentParser.sha256(of: value)
}
