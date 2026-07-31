import Foundation
import XCTest

@testable import FUMLiveEpisodeCore

final class LiveEpisodeContractBoundaryTests: XCTestCase {
  func testStrictIntentParserRejectsUnknownActionFieldAndNoncanonicalJSON() throws {
    let fixture = try LiveEpisodeFixture.run()
    let intent = try XCTUnwrap(fixture.state.model.variants.first?.intent?.intent)
    let canonical = try LiveStrictIntentParser.canonicalOutput(for: intent)

    XCTAssertEqual(try LiveStrictIntentParser.parse(canonical), intent)

    let unknownField = String(canonical.dropLast()) + ",\"authorized\":true}"
    assertParserError(.invalidJSON) {
      _ = try LiveStrictIntentParser.parse(unknownField)
    }
    assertParserError(.noncanonicalJSON) {
      _ = try LiveStrictIntentParser.parse(" \(canonical)")
    }
  }

  func testCoreSourceContainsNoFileProcessNetworkGitOrProviderInvocationAPI() throws {
    let workingDirectory = URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath,
      isDirectory: true
    )
    let relativeSourceRoots = [
      "Sources/FUMLiveEpisodeCore",
      "Прототипы/живой-одноагентный-эпизод/Sources/FUMLiveEpisodeCore",
    ]
    let sourceRoot = try XCTUnwrap(
      relativeSourceRoots
        .map { URL(fileURLWithPath: $0, relativeTo: workingDirectory).standardizedFileURL }
        .first { FileManager.default.fileExists(atPath: $0.path) }
    )
    let sourceFiles = try FileManager.default.contentsOfDirectory(
      at: sourceRoot,
      includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "swift" }
    let absoluteGitExecutable = ["", "usr", "bin", "git"].joined(separator: "/")
    let forbidden = [
      "FileManager", "Process(", "URLSession", "FoundationNetworking",
      "posix_spawn", "popen(", "system(", absoluteGitExecutable, "provider.generate(",
      "provider.complete(", "LMStudioREST", "FoundationModelOnlyProcessTransport",
    ]

    XCTAssertFalse(sourceFiles.isEmpty)
    for sourceFile in sourceFiles {
      let source = try String(contentsOf: sourceFile, encoding: .utf8)
      for token in forbidden {
        XCTAssertFalse(
          source.contains(token),
          "Core-source \(sourceFile.lastPathComponent) содержит запрещённый API \(token)."
        )
      }
    }
  }

  private func assertParserError(
    _ expected: LiveIntentParserError,
    file: StaticString = (#fileID),
    line: UInt = #line,
    _ operation: () throws -> Void
  ) {
    XCTAssertThrowsError(try operation(), file: file, line: line) { error in
      XCTAssertEqual(error as? LiveIntentParserError, expected, file: file, line: line)
    }
  }
}
