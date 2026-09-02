import Darwin
import FUMLiveEpisodeRuntime
import Foundation

private func acceptanceExecutableURL() -> URL {
  URL(fileURLWithPath: CommandLine.arguments[0], isDirectory: false)
    .standardizedFileURL
    .deletingLastPathComponent()
    .appendingPathComponent("FUMLiveCandidateAcceptanceProbe", isDirectory: false)
}

private func write<T: Encodable>(_ value: T, to handle: FileHandle) throws {
  try handle.write(contentsOf: LiveEpisodeRuntimeJSON.encode(value))
}

private func publishMarker(
  _ output: LiveSingleAgentWorkerOutput,
  runDirectoryURL: URL
) throws {
  guard let checkpoint = output.checkpoint else {
    throw LiveEpisodeRuntimeError.corruptGeneration(
      "Checkpoint worker output не содержит checkpoint ID."
    )
  }
  let marker = LiveSingleAgentCheckpointMarker(
    checkpoint: checkpoint,
    processID: output.processID,
    generationSHA256: output.generationSHA256,
    stateSHA256: output.stateSHA256
  )
  let directory = runDirectoryURL.appendingPathComponent(
    LiveSingleAgentEpisodeSchema.checkpointRelativePath,
    isDirectory: true
  )
  let destination = directory.appendingPathComponent(
    "\(checkpoint.rawValue).json",
    isDirectory: false
  )
  let data = try LiveEpisodeRuntimeJSON.encode(marker)
  if FileManager.default.fileExists(atPath: destination.path) {
    guard try Data(contentsOf: destination) == data else {
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Checkpoint marker уже содержит другие байты."
      )
    }
  } else {
    try data.write(to: destination, options: [.withoutOverwriting])
  }
}

do {
  let arguments = CommandLine.arguments
  if arguments.count == 2 {
    let runDirectoryURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
      .standardizedFileURL
    let runtime = LiveSingleAgentEpisodeRuntime(
      runDirectoryURL: runDirectoryURL,
      acceptanceExecutableURL: acceptanceExecutableURL()
    )
    let output = try await runtime.advance()
    try write(output, to: .standardOutput)
    if output.status == .checkpoint {
      try publishMarker(output, runDirectoryURL: runDirectoryURL)
      _ = raise(SIGSTOP)
      throw LiveEpisodeRuntimeError.corruptGeneration(
        "Checkpoint worker неожиданно продолжил работу после SIGSTOP."
      )
    }
  } else if arguments.count == 3, arguments[1] == "--replay" {
    let runDirectoryURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
      .standardizedFileURL
    let runtime = LiveSingleAgentEpisodeRuntime(
      runDirectoryURL: runDirectoryURL,
      acceptanceExecutableURL: acceptanceExecutableURL()
    )
    try write(runtime.replayProjection(), to: .standardOutput)
  } else {
    throw LiveEpisodeRuntimeError.invalidCommand(
      "Использование: FUMLiveEpisodeWorker [--replay] <run-directory>."
    )
  }
} catch {
  let output = LiveEpisodeErrorOutput(
    code: "single_agent_runtime_failed",
    message: String(describing: error)
  )
  try? write(output, to: .standardError)
  exit(2)
}
