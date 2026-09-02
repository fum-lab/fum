import Foundation
import Testing

@testable import FUMInputMac

@Suite("Расположение локальных данных прототипа")
struct RepositoryLocationTests {
  @Test("отсутствующий runtime-корень репозитория отклоняется")
  func rejectsMissingRuntimeRepositoryRoot() {
    #expect(throws: PrototypeRepositoryLocationError.repositoryRootNotConfigured) {
      try PrototypeRepositoryLocator.locate(environment: [:])
    }
  }

  @Test("относительный runtime-корень репозитория отклоняется")
  func rejectsRelativeRuntimeRepositoryRoot() {
    #expect(throws: PrototypeRepositoryLocationError.repositoryRootMustBeAbsolute) {
      try PrototypeRepositoryLocator.locate(
        environment: [PrototypeRepositoryLocator.environmentKey: "relative/checkout"]
      )
    }
  }

  @Test("проверенный runtime-корень приводит к каталогу данных прототипа")
  func locatesRepositoryFromRuntimeEnvironment() throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }

    let location = try PrototypeRepositoryLocator.locate(
      environment: fixture.environment
    )

    #expect(location.repositoryRoot == fixture.repositoryRoot)
    #expect(location.prototypeRoot == fixture.prototypeRoot)
    #expect(
      location.captureRoot
        == fixture.prototypeRoot.appendingPathComponent("Локальные-данные-прогонов"))
  }

  @Test("старый runtime-корень после переноса checkout отклоняется")
  func rejectsOldRuntimeRootAfterCheckoutMoves() throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let oldEnvironment = fixture.environment
    _ = try fixture.moveCheckout()

    #expect(throws: PrototypeRepositoryLocationError.repositoryNotFound) {
      try PrototypeRepositoryLocator.locate(environment: oldEnvironment)
    }
  }

  @Test("перенесённый checkout принимается по новому runtime-корню")
  func acceptsNewRuntimeRootAfterCheckoutMoves() throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let movedRoot = try fixture.moveCheckout()

    let location = try PrototypeRepositoryLocator.locate(
      environment: [PrototypeRepositoryLocator.environmentKey: movedRoot.path]
    )

    #expect(location.repositoryRoot == movedRoot)
    #expect(
      location.captureRoot
        == movedRoot
        .appendingPathComponent("Прототипы")
        .appendingPathComponent("физические-состояния-клавиш")
        .appendingPathComponent("Локальные-данные-прогонов"))
  }

  @Test("каталог без маркеров репозитория отклоняется")
  func rejectsUnverifiedPath() throws {
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)
    let root = container.appendingPathComponent("checkout")
    defer { try? FileManager.default.removeItem(at: container) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    #expect(throws: PrototypeRepositoryLocationError.repositoryNotFound) {
      try PrototypeRepositoryLocator.locate(
        environment: [PrototypeRepositoryLocator.environmentKey: root.path]
      )
    }
  }

  @Test("символьная ссылка каталога прогонов за пределы репозитория отклоняется")
  func rejectsSymbolicLinkCaptureRoot() throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let outside = fixture.container.appendingPathComponent("outside")
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let captureRoot = fixture.prototypeRoot.appendingPathComponent("Локальные-данные-прогонов")
    try FileManager.default.createSymbolicLink(at: captureRoot, withDestinationURL: outside)

    #expect(throws: PrototypeRepositoryLocationError.capturePathIsSymbolicLink) {
      try PrototypeRepositoryLocator.locate(environment: fixture.environment)
    }
  }
}

private final class RepositoryFixture {
  let container: URL
  private(set) var repositoryRoot: URL

  var prototypeRoot: URL {
    repositoryRoot
      .appendingPathComponent("Прототипы")
      .appendingPathComponent("физические-состояния-клавиш")
  }

  var environment: [String: String] {
    [PrototypeRepositoryLocator.environmentKey: repositoryRoot.path]
  }

  init() throws {
    container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    repositoryRoot = container.appendingPathComponent("checkout")
    try FileManager.default.createDirectory(
      at: prototypeRoot,
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

  func moveCheckout() throws -> URL {
    let movedRoot = container.appendingPathComponent("moved-checkout")
    try FileManager.default.moveItem(at: repositoryRoot, to: movedRoot)
    repositoryRoot = movedRoot
    return movedRoot
  }

  func remove() {
    try? FileManager.default.removeItem(at: container)
  }
}
