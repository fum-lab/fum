import Foundation

private let compiledRepositoryLocatorSourceFilePath = #filePath

public struct PrototypeRepositoryLocation: Equatable, Sendable {
  public let repositoryRoot: URL
  public let prototypeRoot: URL
  public let captureRoot: URL

  public init(repositoryRoot: URL, prototypeRoot: URL, captureRoot: URL) {
    self.repositoryRoot = repositoryRoot
    self.prototypeRoot = prototypeRoot
    self.captureRoot = captureRoot
  }
}

public enum PrototypeRepositoryLocationError: Error, CustomStringConvertible, Sendable {
  case repositoryNotFound
  case capturePathEscapesRepository
  case capturePathIsSymbolicLink

  public var description: String {
    switch self {
    case .repositoryNotFound:
      "не удалось подтвердить корень репозитория по #filePath"
    case .capturePathEscapesRepository:
      "каталог тестовых данных выходит за пределы репозитория"
    case .capturePathIsSymbolicLink:
      "каталог тестовых данных не может быть символьной ссылкой"
    }
  }
}

public enum PrototypeRepositoryLocator {
  public static func locateFromCompiledSource(
    fileManager: FileManager = .default
  ) throws -> PrototypeRepositoryLocation {
    try locate(
      sourceFilePath: compiledRepositoryLocatorSourceFilePath,
      fileManager: fileManager
    )
  }

  public static func locate(
    sourceFilePath: String,
    fileManager: FileManager = .default
  ) throws -> PrototypeRepositoryLocation {
    var candidate = URL(fileURLWithPath: sourceFilePath).deletingLastPathComponent()
    while candidate.path != candidate.deletingLastPathComponent().path {
      let agents = candidate.appendingPathComponent("AGENTS.md")
      let git = candidate.appendingPathComponent(".git")
      let prototype =
        candidate
        .appendingPathComponent("Прототипы")
        .appendingPathComponent("физические-состояния-клавиш")
      let package = prototype.appendingPathComponent("Package.swift")
      if fileManager.fileExists(atPath: agents.path),
        fileManager.fileExists(atPath: git.path),
        fileManager.fileExists(atPath: package.path)
      {
        let repositoryRoot = URL(
          fileURLWithPath: candidate.resolvingSymlinksInPath().standardizedFileURL.path,
          isDirectory: false
        )
        let prototypeRoot = URL(
          fileURLWithPath: prototype.resolvingSymlinksInPath().standardizedFileURL.path,
          isDirectory: false
        )
        let captureRoot =
          prototypeRoot
          .appendingPathComponent("Локальные-данные-прогонов")
          .standardizedFileURL
        if (try? fileManager.destinationOfSymbolicLink(atPath: captureRoot.path)) != nil {
          throw PrototypeRepositoryLocationError.capturePathIsSymbolicLink
        }
        let resolvedCaptureRoot = captureRoot.resolvingSymlinksInPath().standardizedFileURL
        guard captureRoot.path.hasPrefix(repositoryRoot.path + "/") else {
          throw PrototypeRepositoryLocationError.capturePathEscapesRepository
        }
        guard resolvedCaptureRoot.path.hasPrefix(repositoryRoot.path + "/") else {
          throw PrototypeRepositoryLocationError.capturePathEscapesRepository
        }
        return .init(
          repositoryRoot: repositoryRoot,
          prototypeRoot: prototypeRoot,
          captureRoot: captureRoot
        )
      }
      candidate.deleteLastPathComponent()
    }
    throw PrototypeRepositoryLocationError.repositoryNotFound
  }
}
