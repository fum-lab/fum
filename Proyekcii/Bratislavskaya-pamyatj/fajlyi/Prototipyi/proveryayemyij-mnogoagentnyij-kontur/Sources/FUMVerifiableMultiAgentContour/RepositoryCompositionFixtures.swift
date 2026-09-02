import Foundation

public struct RepositoryCompositionFixture: Sendable {
  public let passportData: Data
  public let context: RepositoryCompositionContext

  public init(passportData: Data, context: RepositoryCompositionContext) {
    self.passportData = passportData
    self.context = context
  }
}

public enum RepositoryCompositionFixtureError: Error, CustomStringConvertible, Sendable {
  case unknownFixture(String)
  case commandFailed(arguments: [String], status: Int32, output: String)
  case invalidUTF8(arguments: [String])
  case invalidPassport
  case executableNotFound(String)

  public var description: String {
    switch self {
    case .unknownFixture(let identifier):
      "Неизвестная фикстура репозиторной композиции: \(identifier)."
    case .commandFailed(let arguments, let status, let output):
      "Локальная Git-команда завершилась с кодом \(status): git \(arguments.joined(separator: " ")); \(output)"
    case .invalidUTF8(let arguments):
      "Локальная Git-команда вернула не-UTF-8: git \(arguments.joined(separator: " "))."
    case .invalidPassport:
      "Не удалось построить JSON-паспорт репозиторной композиции."
    case .executableNotFound(let name):
      "Не найден обязательный локальный исполняемый файл: \(name)."
    }
  }
}

public enum RepositoryCompositionFixtures {
  public static let identifiers = [
    "valid",
    "invalid-access",
    "invalid-ancestor-submodule",
    "invalid-duplicate-identity",
    "invalid-duplicate-path",
    "invalid-missing-revision",
    "invalid-repository-cycle",
    "invalid-self-recursion",
  ]

  public static func withFixture<Result>(
    named identifier: String,
    _ body: (RepositoryCompositionFixture) throws -> Result
  ) throws -> Result {
    guard identifiers.contains(identifier) else {
      throw RepositoryCompositionFixtureError.unknownFixture(identifier)
    }

    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("fum-repository-composition-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let fixture = try makeFixture(named: identifier, root: root)
    return try body(fixture)
  }

  private static func makeFixture(
    named identifier: String,
    root: URL
  ) throws -> RepositoryCompositionFixture {
    let coreBare = root.appendingPathComponent("core.git", isDirectory: true)
    let specializedBare = root.appendingPathComponent("specialized.git", isDirectory: true)
    let projectBare = root.appendingPathComponent("project.git", isDirectory: true)
    let parentBare = root.appendingPathComponent("parent.git", isDirectory: true)

    let coreSeed = root.appendingPathComponent("core-seed", isDirectory: true)
    try initializeBare(coreBare)
    try clone(coreBare, to: coreSeed)
    try configureAuthor(in: coreSeed)
    try write("core fixture\n", to: coreSeed.appendingPathComponent("core.txt"))
    try git(["add", "core.txt"], in: coreSeed)
    try git(["commit", "-m", "core base"], in: coreSeed)
    let coreBaseOID = try gitOutput(["rev-parse", "HEAD"], in: coreSeed)
    try git(["push", "origin", "HEAD:refs/heads/main"], in: coreSeed)

    try git(["clone", "--bare", coreBare.path, specializedBare.path], in: root)
    let specializedWriter = root.appendingPathComponent("specialized-writer", isDirectory: true)
    try clone(specializedBare, to: specializedWriter)
    try configureAuthor(in: specializedWriter)
    try git(["switch", "-c", "specialized/main"], in: specializedWriter)
    try write(
      "specialized accepted\n",
      to: specializedWriter.appendingPathComponent("specialized.txt")
    )
    try git(["add", "specialized.txt"], in: specializedWriter)
    try git(["commit", "-m", "specialized accepted"], in: specializedWriter)
    let specializedAcceptedOID = try gitOutput(["rev-parse", "HEAD"], in: specializedWriter)
    var specializedGitlinkOID = specializedAcceptedOID
    try git(
      ["push", "-u", "origin", "HEAD:refs/heads/specialized/main"],
      in: specializedWriter
    )
    try write(
      "specialized live tip\n",
      to: specializedWriter.appendingPathComponent("specialized.txt")
    )
    try git(["commit", "-am", "specialized live tip"], in: specializedWriter)
    try git(["push", "origin", "HEAD:refs/heads/specialized/main"], in: specializedWriter)

    try initializeBare(projectBare)
    let projectWriter = root.appendingPathComponent("project-writer", isDirectory: true)
    try clone(projectBare, to: projectWriter)
    try configureAuthor(in: projectWriter)
    try git(["switch", "-c", "project/main"], in: projectWriter)
    try write("project accepted\n", to: projectWriter.appendingPathComponent("project.txt"))
    try git(["add", "project.txt"], in: projectWriter)
    try git(["commit", "-m", "project accepted"], in: projectWriter)
    let projectBaseOID = try gitOutput(["rev-parse", "HEAD"], in: projectWriter)
    var projectGitlinkOID = projectBaseOID
    try git(["push", "-u", "origin", "HEAD:refs/heads/project/main"], in: projectWriter)
    try write("project live tip\n", to: projectWriter.appendingPathComponent("project.txt"))
    try git(["commit", "-am", "project live tip"], in: projectWriter)
    try git(["push", "origin", "HEAD:refs/heads/project/main"], in: projectWriter)

    try initializeBare(parentBare)
    let parentWriter = root.appendingPathComponent("parent-writer", isDirectory: true)
    try clone(parentBare, to: parentWriter)
    try configureAuthor(in: parentWriter)
    try write("parent fixture\n", to: parentWriter.appendingPathComponent("README.md"))
    try git(["add", "README.md"], in: parentWriter)
    try git(["commit", "-m", "parent base"], in: parentWriter)
    let parentBaseOID = try gitOutput(["rev-parse", "HEAD"], in: parentWriter)
    try git(["push", "origin", "HEAD:refs/heads/main"], in: parentWriter)

    switch identifier {
    case "invalid-ancestor-submodule":
      specializedGitlinkOID = try addNestedSubmodule(
        to: specializedWriter,
        name: "parent",
        path: "Предки/FUM",
        relativeURL: "../parent.git",
        gitlinkOID: parentBaseOID,
        message: "specialized references parent",
        liveRef: "refs/heads/specialized/main"
      )
    case "invalid-repository-cycle":
      specializedGitlinkOID = try addNestedSubmodule(
        to: specializedWriter,
        name: "project-cycle",
        path: "Проекты/цикл",
        relativeURL: "../project.git",
        gitlinkOID: projectBaseOID,
        message: "specialized references project",
        liveRef: "refs/heads/specialized/main"
      )
      projectGitlinkOID = try addNestedSubmodule(
        to: projectWriter,
        name: "specialized-cycle",
        path: "Подузлы/цикл",
        relativeURL: "../specialized.git",
        gitlinkOID: specializedAcceptedOID,
        message: "project references specialized",
        liveRef: "refs/heads/project/main"
      )
    case "invalid-self-recursion":
      projectGitlinkOID = try addNestedSubmodule(
        to: projectWriter,
        name: "project-self",
        path: "Проекты/сам",
        relativeURL: "../project.git",
        gitlinkOID: projectBaseOID,
        message: "project references itself",
        liveRef: "refs/heads/project/main"
      )
    default:
      break
    }

    let specializedPath = "Подузлы/специализированный"
    let projectPath = "Проекты/самостоятельный"
    let modules = """
      [submodule "specialized"]
      \tpath = \(specializedPath)
      \turl = ../specialized.git
      [submodule "project"]
      \tpath = \(projectPath)
      \turl = ../project.git
      """
    try write(modules + "\n", to: parentWriter.appendingPathComponent(".gitmodules"))
    try git(["add", ".gitmodules"], in: parentWriter)
    try git(
      [
        "update-index", "--add", "--cacheinfo",
        "160000,\(specializedGitlinkOID),\(specializedPath)",
      ],
      in: parentWriter
    )
    try git(
      ["update-index", "--add", "--cacheinfo", "160000,\(projectGitlinkOID),\(projectPath)"],
      in: parentWriter
    )
    try git(["commit", "-m", "composition snapshot"], in: parentWriter)
    let parentSnapshotOID = try gitOutput(["rev-parse", "HEAD"], in: parentWriter)
    try git(["push", "origin", "HEAD:refs/heads/main"], in: parentWriter)

    try git(["switch", "-c", "steps/fixture"], in: parentWriter)
    try write("step fixture\n", to: parentWriter.appendingPathComponent("step.txt"))
    try git(["add", "step.txt"], in: parentWriter)
    try git(["commit", "-m", "ephemeral step"], in: parentWriter)
    try git(["push", "-u", "origin", "HEAD:refs/heads/steps/fixture"], in: parentWriter)

    let parentSnapshot = root.appendingPathComponent("parent-snapshot", isDirectory: true)
    try clone(parentBare, to: parentSnapshot, noCheckout: true)
    try git(["checkout", "--detach", parentSnapshotOID], in: parentSnapshot)
    try git(
      [
        "-c", "protocol.file.allow=always", "submodule", "update", "--init", "--",
        specializedPath, projectPath,
      ],
      in: parentSnapshot
    )
    let specializedSnapshot = parentSnapshot.appendingPathComponent(
      specializedPath, isDirectory: true)
    let projectSnapshot = parentSnapshot.appendingPathComponent(projectPath, isDirectory: true)

    var passport = validPassport(
      parentSnapshotOID: parentSnapshotOID,
      coreBaseOID: coreBaseOID,
      projectBaseOID: projectBaseOID,
      specializedGitlinkOID: specializedGitlinkOID,
      projectGitlinkOID: projectGitlinkOID,
      specializedPath: specializedPath,
      projectPath: projectPath
    )
    try mutate(&passport, for: identifier)
    guard JSONSerialization.isValidJSONObject(passport) else {
      throw RepositoryCompositionFixtureError.invalidPassport
    }
    let passportData = try JSONSerialization.data(
      withJSONObject: passport,
      options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let context = RepositoryCompositionContext(
      gitExecutableURL: try gitExecutableURL(),
      bareRepositoriesByID: [
        "repository.parent": parentBare,
        "repository.core": coreBare,
        "repository.specialized": specializedBare,
        "repository.project": projectBare,
      ],
      checkoutsByEntryID: [
        "entry.specialized": RepositoryCompositionCheckoutContext(
          snapshotURL: specializedSnapshot,
          writerURL: specializedWriter
        ),
        "entry.project": RepositoryCompositionCheckoutContext(
          snapshotURL: projectSnapshot,
          writerURL: projectWriter
        ),
      ]
    )
    return RepositoryCompositionFixture(passportData: passportData, context: context)
  }

  private static func validPassport(
    parentSnapshotOID: String,
    coreBaseOID: String,
    projectBaseOID: String,
    specializedGitlinkOID: String,
    projectGitlinkOID: String,
    specializedPath: String,
    projectPath: String
  ) -> [String: Any] {
    let checks = ["commit_exists", "live_ref_matches", "handoff_ready"]
    let parentHandoff: [String: Any] = [
      "target_repository_id": "repository.parent",
      "target_ref": "refs/heads/main",
      "required_check_ids": checks,
    ]
    return [
      "schema_version": 1,
      "passport_id": "passport.repository-composition.fixture.v1",
      "composition_id": "fum.repository-composition.fixture.v1",
      "parent_repository": [
        "repository_id": "repository.parent",
        "repository_url": "urn:fum:repository:parent-fixture",
        "snapshot_oid": parentSnapshotOID,
        "live_ref": "refs/heads/main",
        "access_level": "public",
        "publication_boundary": "public",
      ],
      "children": [
        [
          "entry_id": "entry.step",
          "kind": "step_branch",
          "node_id": "node.step.fixture",
          "target_repository_id": "repository.parent",
          "base_oid": parentSnapshotOID,
          "live_ref": "refs/heads/steps/fixture",
          "access_level": "public",
          "publication_boundary": "public",
          "checks": checks,
          "handoff": parentHandoff,
        ],
        [
          "entry_id": "entry.specialized",
          "kind": "specialized_subnode",
          "node_id": "node.specialized.fixture",
          "repository_id": "repository.specialized",
          "repository_url": "urn:fum:repository:specialized-fixture",
          "upstream_repository_id": "repository.core",
          "base_oid": coreBaseOID,
          "live_ref": "refs/heads/specialized/main",
          "submodule_path": specializedPath,
          "gitlink_oid": specializedGitlinkOID,
          "snapshot_mode": "detached_read_only",
          "writer_mode": "separate_clone",
          "nested_submodules": [],
          "access_level": "public",
          "publication_boundary": "public",
          "checks": checks,
          "handoff": parentHandoff,
        ],
        [
          "entry_id": "entry.project",
          "kind": "project",
          "project_id": "project.independent.fixture",
          "repository_id": "repository.project",
          "repository_url": "urn:fum:repository:project-fixture",
          "base_oid": projectBaseOID,
          "live_ref": "refs/heads/project/main",
          "submodule_path": projectPath,
          "gitlink_oid": projectGitlinkOID,
          "snapshot_mode": "detached_read_only",
          "writer_mode": "separate_clone",
          "nested_submodules": [],
          "access_level": "public",
          "publication_boundary": "public",
          "checks": checks,
          "handoff": parentHandoff,
        ],
      ],
    ]
  }

  private static func mutate(_ passport: inout [String: Any], for identifier: String) throws {
    guard identifier != "valid" else { return }
    guard var children = passport["children"] as? [[String: Any]] else {
      throw RepositoryCompositionFixtureError.invalidPassport
    }

    switch identifier {
    case "invalid-access":
      children[1]["access_level"] = "private"
      children[1]["publication_boundary"] = "private"
    case "invalid-ancestor-submodule":
      children[1]["nested_submodules"] = [
        ["repository_id": "repository.parent", "submodule_path": "Предки/FUM"]
      ]
    case "invalid-duplicate-identity":
      children[2]["repository_id"] = children[1]["repository_id"]
    case "invalid-duplicate-path":
      children[2]["submodule_path"] = children[1]["submodule_path"]
    case "invalid-missing-revision":
      children[2]["gitlink_oid"] = String(repeating: "f", count: 40)
    case "invalid-repository-cycle":
      children[1]["nested_submodules"] = [
        ["repository_id": "repository.project", "submodule_path": "Проекты/цикл"]
      ]
      children[2]["nested_submodules"] = [
        ["repository_id": "repository.specialized", "submodule_path": "Подузлы/цикл"]
      ]
    case "invalid-self-recursion":
      children[2]["nested_submodules"] = [
        ["repository_id": "repository.project", "submodule_path": "Проекты/сам"]
      ]
    default:
      throw RepositoryCompositionFixtureError.unknownFixture(identifier)
    }
    passport["children"] = children
  }

  private static func addNestedSubmodule(
    to writer: URL,
    name: String,
    path: String,
    relativeURL: String,
    gitlinkOID: String,
    message: String,
    liveRef: String
  ) throws -> String {
    let modules = """
      [submodule "\(name)"]
      \tpath = \(path)
      \turl = \(relativeURL)
      """
    try write(modules + "\n", to: writer.appendingPathComponent(".gitmodules"))
    try git(["add", ".gitmodules"], in: writer)
    try git(
      ["update-index", "--add", "--cacheinfo", "160000,\(gitlinkOID),\(path)"],
      in: writer
    )
    try git(["commit", "-m", message], in: writer)
    let oid = try gitOutput(["rev-parse", "HEAD"], in: writer)
    try git(["push", "origin", "HEAD:\(liveRef)"], in: writer)
    return oid
  }

  private static func initializeBare(_ url: URL) throws {
    try git(
      ["init", "--bare", "--initial-branch=main", url.path], in: url.deletingLastPathComponent())
  }

  private static func clone(_ repository: URL, to checkout: URL, noCheckout: Bool = false) throws {
    var arguments = ["clone"]
    if noCheckout { arguments.append("--no-checkout") }
    arguments += [repository.path, checkout.path]
    try git(arguments, in: checkout.deletingLastPathComponent())
  }

  private static func configureAuthor(in repository: URL) throws {
    try git(["config", "user.name", "FUM Fixture"], in: repository)
    try git(["config", "user.email", "fixture@fum.invalid"], in: repository)
  }

  private static func write(_ string: String, to url: URL) throws {
    try Data(string.utf8).write(to: url, options: .atomic)
  }

  @discardableResult
  private static func git(_ arguments: [String], in directory: URL) throws -> Data {
    let process = Process()
    process.executableURL = try gitExecutableURL()
    process.arguments = arguments
    process.currentDirectoryURL = directory
    process.environment = cleanGitEnvironment(in: directory)

    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    try process.run()
    try? output.fileHandleForWriting.close()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    try? output.fileHandleForReading.close()
    guard process.terminationReason == .exit, process.terminationStatus == 0 else {
      let text = String(data: data, encoding: .utf8) ?? "<не-UTF-8>"
      throw RepositoryCompositionFixtureError.commandFailed(
        arguments: arguments,
        status: process.terminationStatus,
        output: text.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }
    return data
  }

  private static func gitOutput(_ arguments: [String], in directory: URL) throws -> String {
    let data = try git(arguments, in: directory)
    guard let output = String(data: data, encoding: .utf8) else {
      throw RepositoryCompositionFixtureError.invalidUTF8(arguments: arguments)
    }
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func gitExecutableURL() throws -> URL {
    let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
    for directory in path.split(separator: ":") where !directory.isEmpty {
      let candidate = URL(fileURLWithPath: String(directory), isDirectory: true)
        .appendingPathComponent("git", isDirectory: false)
      if FileManager.default.isExecutableFile(atPath: candidate.path) {
        return candidate
      }
    }
    throw RepositoryCompositionFixtureError.executableNotFound("git")
  }

  private static func cleanGitEnvironment(in directory: URL) -> [String: String] {
    var environment = ProcessInfo.processInfo.environment.filter { key, _ in
      !key.hasPrefix("GIT_")
    }
    environment["GIT_CONFIG_NOSYSTEM"] = "1"
    environment["GIT_CONFIG_GLOBAL"] =
      directory
      .appendingPathComponent("fum-absent-global-gitconfig-\(UUID().uuidString)")
      .path
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["GIT_AUTHOR_DATE"] = "2001-01-01T00:00:00Z"
    environment["GIT_COMMITTER_DATE"] = "2001-01-01T00:00:00Z"
    environment["LC_ALL"] = "C"
    return environment
  }
}
