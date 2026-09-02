import Foundation

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

public enum PrototypeRepositoryLocationError: Error, CustomStringConvertible, Equatable, Sendable {
  case repositoryRootNotConfigured
  case repositoryRootMustBeAbsolute
  case repositoryNotFound
  case capturePathEscapesRepository
  case capturePathIsSymbolicLink

  public var description: String {
    switch self {
    case .repositoryRootNotConfigured:
      "не задана переменная среды FUM_REPOSITORY_ROOT"
    case .repositoryRootMustBeAbsolute:
      "FUM_REPOSITORY_ROOT должна содержать абсолютный путь текущего checkout"
    case .repositoryNotFound:
      "не удалось подтвердить корень репозитория по FUM_REPOSITORY_ROOT"
    case .capturePathEscapesRepository:
      "каталог тестовых данных выходит за пределы репозитория"
    case .capturePathIsSymbolicLink:
      "каталог тестовых данных не может быть символьной ссылкой"
    }
  }
}

public enum PrototypeRepositoryLocator {
  public static let environmentKey = "FUM_REPOSITORY_ROOT"

  public static func locate(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    fileManager: FileManager = .default
  ) throws -> PrototypeRepositoryLocation {
    guard let configuredRoot = environment[environmentKey], !configuredRoot.isEmpty else {
      throw PrototypeRepositoryLocationError.repositoryRootNotConfigured
    }
    guard (configuredRoot as NSString).isAbsolutePath else {
      throw PrototypeRepositoryLocationError.repositoryRootMustBeAbsolute
    }

    let configuredURL = URL(fileURLWithPath: configuredRoot, isDirectory: true).standardizedFileURL
    let repositoryRoot = URL(
      fileURLWithPath: configuredURL.resolvingSymlinksInPath().standardizedFileURL.path,
      isDirectory: false
    )
    let prototypeRoot =
      repositoryRoot
      .appendingPathComponent("Прототипы")
      .appendingPathComponent("физические-состояния-клавиш")
      .standardizedFileURL
    let agents = repositoryRoot.appendingPathComponent("AGENTS.md")
    let git = repositoryRoot.appendingPathComponent(".git")
    let package = prototypeRoot.appendingPathComponent("Package.swift")
    guard fileManager.fileExists(atPath: agents.path),
      fileManager.fileExists(atPath: git.path),
      fileManager.fileExists(atPath: package.path)
    else {
      throw PrototypeRepositoryLocationError.repositoryNotFound
    }

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
}
