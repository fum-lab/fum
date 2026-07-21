import Foundation
import Testing

@testable import FUMInputMac

@Suite("Расположение локальных данных прототипа")
struct RepositoryLocationTests {
  @Test("полный путь исходника приводит к проверенному корню репозитория")
  func locatesRepositoryFromSourceFilePath() throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }

    let location = try PrototypeRepositoryLocator.locate(
      sourceFilePath: fixture.sourceFile.path
    )

    #expect(location.repositoryRoot == fixture.repositoryRoot)
    #expect(location.prototypeRoot == fixture.prototypeRoot)
    #expect(
      location.captureRoot
        == fixture.prototypeRoot.appendingPathComponent("Локальные-данные-прогонов"))
  }

  @Test("каталог без маркеров репозитория отклоняется")
  func rejectsUnverifiedPath() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appendingPathComponent("Sources/FUMInputMac/RepositoryLocation.swift")
    try FileManager.default.createDirectory(
      at: source.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    #expect(throws: PrototypeRepositoryLocationError.self) {
      try PrototypeRepositoryLocator.locate(sourceFilePath: source.path)
    }
  }

  @Test("символьная ссылка каталога прогонов за пределы репозитория отклоняется")
  func rejectsSymbolicLinkCaptureRoot() throws {
    let fixture = try RepositoryFixture()
    let outside = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer {
      fixture.remove()
      try? FileManager.default.removeItem(at: outside)
    }
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let captureRoot = fixture.prototypeRoot.appendingPathComponent("Локальные-данные-прогонов")
    try FileManager.default.createSymbolicLink(at: captureRoot, withDestinationURL: outside)

    #expect(throws: PrototypeRepositoryLocationError.self) {
      try PrototypeRepositoryLocator.locate(sourceFilePath: fixture.sourceFile.path)
    }
  }
}

private struct RepositoryFixture {
  let repositoryRoot: URL
  let prototypeRoot: URL
  let sourceFile: URL

  init() throws {
    repositoryRoot = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    prototypeRoot =
      repositoryRoot
      .appendingPathComponent("Прототипы")
      .appendingPathComponent("физические-состояния-клавиш")
    sourceFile =
      prototypeRoot
      .appendingPathComponent("Sources")
      .appendingPathComponent("FUMInputMac")
      .appendingPathComponent("RepositoryLocation.swift")
    try FileManager.default.createDirectory(
      at: sourceFile.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    FileManager.default.createFile(
      atPath: repositoryRoot.appendingPathComponent("AGENTS.md").path,
      contents: Data()
    )
    try FileManager.default.createDirectory(
      at: repositoryRoot.appendingPathComponent(".git"),
      withIntermediateDirectories: true
    )
    FileManager.default.createFile(
      atPath: prototypeRoot.appendingPathComponent("Package.swift").path,
      contents: Data()
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: repositoryRoot)
  }
}
