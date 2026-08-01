import Darwin
import FUMLiveEpisodeCore
import FUMReproducibleMemoryPopulation
import Foundation

public struct LiveGitCheckerRegistry: Sendable {
  private enum Implementation: Sendable {
    case gitDiffCheckV1
  }

  private struct Registration: Sendable {
    let argvGrammar: LiveGitCandidateCheckerArgvGrammar
    let implementation: Implementation
  }

  private static let registrationsByCheckerID: [String: Registration] = [
    "checker-git-diff": Registration(
      argvGrammar: .gitDiffCheckV1,
      implementation: .gitDiffCheckV1
    ),
    "git-diff-check": Registration(
      argvGrammar: .gitDiffCheckV1,
      implementation: .gitDiffCheckV1
    ),
  ]

  public init() {}

  /// Validates the exact persisted pair against the same closed registry used for execution.
  /// This accepts the raw grammar so schema decoders and independent audit tests cannot make a
  /// future enum expansion silently choose an implementation by grammar alone.
  func validateRegistration(
    checkerID: String,
    persistedArgvGrammar: String
  ) throws {
    _ = try Self.registration(
      checkerID: checkerID,
      persistedArgvGrammar: persistedArgvGrammar
    )
  }

  /// Re-runs only the closed checker grammar stored in a durable passport. The passport can be
  /// loaded from confirmed CURRENT by a separate process; no executable or argv is accepted from
  /// model text or persisted JSON.
  public func verify(
    passport: LiveGitCandidatePassport,
    episodeDirectoryURL: URL
  ) throws -> [LiveGitCheckerObservation] {
    try passport.validate()
    guard passport.schemaIdentity == LiveGitCandidateRuntimeSchema.passportIdentity,
      passport.schemaVersion == LiveGitCandidateRuntimeSchema.version,
      passport.canonicalProfile == CanonicalMemoryJSON.profileID,
      passport.cloneRelativePath == LiveGitCandidateRuntimeSchema.cloneRelativePath
    else {
      throw LiveGitCandidateRuntimeError.checkerFailed(
        "Candidate passport has an unsupported checker contract."
      )
    }
    let cloneURL = episodeDirectoryURL.appendingPathComponent(
      LiveGitCandidateRuntimeSchema.cloneRelativePath,
      isDirectory: true
    )
    return try verify(
      specifications: passport.checkerSpecifications,
      parentOID: passport.parentOID,
      candidateOID: passport.candidateOID,
      allowedPaths: passport.allowedPaths,
      repositoryURL: cloneURL
    )
  }

  func verify(
    specifications: [LiveGitCandidateCheckerSpec],
    parentOID: String,
    candidateOID: String,
    allowedPaths: [String],
    repositoryURL: URL
  ) throws -> [LiveGitCheckerObservation] {
    var observations: [LiveGitCheckerObservation] = []
    observations.reserveCapacity(specifications.count)
    for specification in specifications {
      let registration = try Self.registration(
        checkerID: specification.checkerID,
        persistedArgvGrammar: specification.argvGrammar.rawValue
      )
      let output: Data
      switch registration.implementation {
      case .gitDiffCheckV1:
        do {
          let result = try LiveGitProcessRunner().run(
            [
              "--attr-source=\(candidateOID)",
              "diff", "--no-ext-diff", "--no-textconv", "--check", parentOID,
              candidateOID, "--",
            ] + allowedPaths,
            at: repositoryURL
          )
          guard result.errors.isEmpty else {
            throw LiveGitCandidateRuntimeError.checkerFailed(
              "Checker \(specification.checkerID) emitted unexpected diagnostics."
            )
          }
          output = result.output
        } catch {
          throw LiveGitCandidateRuntimeError.checkerFailed(
            "Checker \(specification.checkerID) failed: \(error)"
          )
        }
      }
      var evidence = Data()
      for value in [
        specification.checkerID,
        specification.argvGrammar.rawValue,
        parentOID,
        candidateOID,
      ] + allowedPaths {
        evidence.append(contentsOf: value.utf8)
        evidence.append(0)
      }
      evidence.append(output)
      observations.append(
        LiveGitCheckerObservation(
          checkerID: specification.checkerID,
          status: .passed,
          observationSHA256: CanonicalMemoryJSON.sha256(evidence)
        )
      )
    }
    return observations
  }

  private static func registration(
    checkerID: String,
    persistedArgvGrammar: String
  ) throws -> Registration {
    guard let registration = registrationsByCheckerID[checkerID] else {
      throw LiveGitCandidateRuntimeError.checkerFailed(
        "Checker \(checkerID) is not registered."
      )
    }
    guard registration.argvGrammar.rawValue == persistedArgvGrammar else {
      throw LiveGitCandidateRuntimeError.checkerFailed(
        "Checker \(checkerID) does not match its registered argv grammar."
      )
    }
    return registration
  }
}

struct LiveGitProcessResult: Sendable {
  let status: Int32
  let output: Data
  let errors: Data
}

struct LiveGitProcessRunner: Sendable {
  static let gitURL = LiveGitSystemRuntime.gitExecutableURL
  static let maximumOutputBytes = 4 * 1_024 * 1_024
  static let timeoutSeconds: UInt64 = 120
  static let identityEnvironmentKeys: Set<String> = [
    "GIT_AUTHOR_NAME",
    "GIT_AUTHOR_EMAIL",
    "GIT_AUTHOR_DATE",
    "GIT_COMMITTER_NAME",
    "GIT_COMMITTER_EMAIL",
    "GIT_COMMITTER_DATE",
  ]

  func run(
    _ arguments: [String],
    at directoryURL: URL,
    input: Data? = nil,
    additionalEnvironment: [String: String] = [:],
    acceptedStatuses: Set<Int32> = [0]
  ) throws -> LiveGitProcessResult {
    guard FileManager.default.isExecutableFile(atPath: Self.gitURL.path) else {
      throw LiveGitCandidateRuntimeError.gitProcess("Exact Git runtime is unavailable.")
    }
    guard arguments.allSatisfy({ !$0.contains("\0") }) else {
      throw LiveGitCandidateRuntimeError.gitProcess("Git argv contains NUL.")
    }
    let additionalKeys = Set(additionalEnvironment.keys)
    guard additionalKeys.isEmpty || additionalKeys == Self.identityEnvironmentKeys,
      additionalEnvironment.values.allSatisfy({ !$0.contains("\0") })
    else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Only the complete fixed Git author/committer identity environment is accepted."
      )
    }

    let fileManager = FileManager.default
    let processDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(
      "fum-live-git-process-\(UUID().uuidString)",
      isDirectory: true
    )
    do {
      try fileManager.createDirectory(at: processDirectoryURL, withIntermediateDirectories: false)
    } catch {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Git process scratch directory could not be created: \(error.localizedDescription)"
      )
    }
    defer { try? fileManager.removeItem(at: processDirectoryURL) }
    let outputURL = processDirectoryURL.appendingPathComponent("stdout")
    let errorURL = processDirectoryURL.appendingPathComponent("stderr")
    let inputURL = processDirectoryURL.appendingPathComponent("stdin")
    guard fileManager.createFile(atPath: outputURL.path, contents: nil),
      fileManager.createFile(atPath: errorURL.path, contents: nil)
    else {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Git process output files could not be created.")
    }
    if let input {
      try input.write(to: inputURL, options: [.atomic])
    }
    let standardOutput = try FileHandle(forWritingTo: outputURL)
    let standardError = try FileHandle(forWritingTo: errorURL)
    let standardInput = input == nil ? nil : try FileHandle(forReadingFrom: inputURL)
    defer {
      try? standardOutput.close()
      try? standardError.close()
      try? standardInput?.close()
    }
    let process = Process()
    process.executableURL = Self.gitURL
    process.arguments =
      [
        "--no-replace-objects",
        "-c", "core.hooksPath=\(LiveGitSystemRuntime.nullDevicePath)",
        "-c", "core.fsmonitor=false",
        "-c", "core.attributesFile=\(LiveGitSystemRuntime.nullDevicePath)",
        "-c", "core.logAllRefUpdates=false",
        "-c", "core.pager=cat",
        "-c", "diff.external=",
        "-c", "diff.trustExitCode=false",
        "-c", "commit.gpgSign=false",
        "-c", "gc.auto=0",
        "-c", "maintenance.auto=false",
        "-c", "protocol.allow=never",
        "-c", "protocol.file.allow=always",
        "-c", "uploadpack.packObjectsHook=\(LiveGitSystemRuntime.packObjectsCommand)",
      ] + arguments
    process.currentDirectoryURL = directoryURL
    var environment = [
      "GIT_ATTR_NOSYSTEM": "1",
      "GIT_CONFIG_GLOBAL": LiveGitSystemRuntime.nullDevicePath,
      "GIT_CONFIG_NOSYSTEM": "1",
      "GIT_CONFIG_SYSTEM": LiveGitSystemRuntime.nullDevicePath,
      "GIT_EDITOR": LiveGitSystemRuntime.disabledCommandPath,
      "GIT_NO_LAZY_FETCH": "1",
      "GIT_NO_REPLACE_OBJECTS": "1",
      "GIT_OPTIONAL_LOCKS": "0",
      "GIT_PAGER": "cat",
      "GIT_SEQUENCE_EDITOR": LiveGitSystemRuntime.disabledCommandPath,
      "GIT_SSH_COMMAND": LiveGitSystemRuntime.disabledCommandPath,
      "GIT_TERMINAL_PROMPT": "0",
      "LANG": "C",
      "LC_ALL": "C",
      "PAGER": "cat",
      "PATH": LiveGitSystemRuntime.executableSearchPath,
      "TZ": "UTC",
    ]
    for (key, value) in additionalEnvironment {
      environment[key] = value
    }
    process.environment = environment
    process.standardOutput = standardOutput
    process.standardError = standardError
    if standardInput != nil {
      process.standardInput = standardInput
    } else {
      process.standardInput = FileHandle.nullDevice
    }

    do {
      try process.run()
      let processIdentifier = process.processIdentifier
      let ownsProcessGroup =
        Darwin.setpgid(processIdentifier, processIdentifier) == 0
        || Darwin.getpgid(processIdentifier) == processIdentifier
      let deadline =
        DispatchTime.now().uptimeNanoseconds
        + Self.timeoutSeconds * 1_000_000_000
      var limitFailure: String?
      while process.isRunning, DispatchTime.now().uptimeNanoseconds < deadline {
        if processFileSize(standardOutput.fileDescriptor) > Self.maximumOutputBytes
          || processFileSize(standardError.fileDescriptor) > Self.maximumOutputBytes
        {
          limitFailure = "Git output exceeded the fixed limit."
          break
        }
        Darwin.usleep(10_000)
      }
      if process.isRunning, limitFailure == nil {
        limitFailure = "Git argv exceeded the fixed \(Self.timeoutSeconds)-second timeout."
      }
      if process.isRunning, limitFailure != nil {
        if ownsProcessGroup {
          _ = Darwin.kill(-processIdentifier, SIGTERM)
        } else {
          process.terminate()
        }
        let terminationDeadline = DispatchTime.now().uptimeNanoseconds + 2_000_000_000
        while process.isRunning, DispatchTime.now().uptimeNanoseconds < terminationDeadline {
          Darwin.usleep(10_000)
        }
        if process.isRunning {
          _ = Darwin.kill(
            ownsProcessGroup ? -processIdentifier : processIdentifier,
            SIGKILL
          )
        }
        process.waitUntilExit()
      }
      if let limitFailure {
        throw LiveGitCandidateRuntimeError.gitProcess(limitFailure)
      }
      process.waitUntilExit()
    } catch let error as LiveGitCandidateRuntimeError {
      throw error
    } catch {
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Git process could not run: \(error.localizedDescription)"
      )
    }
    try standardOutput.close()
    try standardError.close()
    let output = try Data(contentsOf: outputURL)
    let errors = try Data(contentsOf: errorURL)
    guard output.count <= Self.maximumOutputBytes, errors.count <= Self.maximumOutputBytes else {
      throw LiveGitCandidateRuntimeError.gitProcess("Git output exceeded the fixed limit.")
    }
    let result = LiveGitProcessResult(
      status: process.terminationStatus,
      output: output,
      errors: errors
    )
    guard acceptedStatuses.contains(result.status) else {
      let diagnostic = String(decoding: errors.prefix(16_384), as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      throw LiveGitCandidateRuntimeError.gitProcess(
        "Git argv failed with status \(result.status): \(diagnostic)"
      )
    }
    return result
  }
}

private func processFileSize(_ descriptor: Int32) -> Int {
  var information = stat()
  guard Darwin.fstat(descriptor, &information) == 0,
    information.st_size >= 0,
    information.st_size <= off_t(Int.max)
  else {
    return Int.max
  }
  return Int(information.st_size)
}
