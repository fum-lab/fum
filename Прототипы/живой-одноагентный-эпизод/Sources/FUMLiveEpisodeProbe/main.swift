import Darwin
import FUMLiveEpisodeCore
import FUMLiveEpisodeRuntime
import Foundation

private struct FailpointMarker: Codable {
  let schemaVersion = 1
  let checkpoint: String
  let processID: Int32
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case checkpoint
    case processID = "process_id"
    case generationSHA256 = "generation_sha256"
  }
}

private func readBoundedStandardInput() throws -> Data {
  var data = Data()
  while let chunk = try FileHandle.standardInput.read(upToCount: 65_536), !chunk.isEmpty {
    data.append(chunk)
    guard data.count <= LiveEpisodeRuntimeJSON.maximumCommandBytes else {
      throw LiveEpisodeRuntimeError.invalidCommand("Команда превышает лимит байтов.")
    }
  }
  guard !data.isEmpty else {
    throw LiveEpisodeRuntimeError.invalidCommand("JSON-команда в stdin пуста.")
  }
  return data
}

private func writeJSON<T: Encodable>(_ value: T, to handle: FileHandle) throws {
  try handle.write(contentsOf: LiveEpisodeRuntimeJSON.encode(value))
}

private func errorCode(_ error: Error) -> String {
  guard let runtime = error as? LiveEpisodeRuntimeError else { return "invalid_json" }
  switch runtime {
  case .unsupportedCommandSchema: return "unsupported_command_schema"
  case .invalidCommand: return "invalid_command"
  case .noConfirmedGeneration: return "no_confirmed_generation"
  case .incompatibleGeneration: return "incompatible_generation"
  case .corruptGeneration: return "corrupt_generation"
  case .generationConflict: return "generation_conflict"
  case .generationStore: return "generation_store"
  case .unresolvedModelInvocation: return "unresolved_model_invocation"
  case .invalidAdapterResult: return "invalid_adapter_result"
  }
}

private func checkpointObserver() -> LiveEpisodeRuntime.CheckpointObserver? {
  let environment = ProcessInfo.processInfo.environment
  guard environment["FUM_LIVE_EPISODE_FAILPOINT"] == "reservation-generation-confirmed"
  else { return nil }
  return { checkpoint, stored in
    guard let markerPath = environment["FUM_LIVE_EPISODE_FAILPOINT_MARKER"],
      markerPath.hasPrefix("/")
    else {
      throw LiveEpisodeRuntimeError.invalidCommand(
        "Failpoint требует абсолютный путь marker вне состояния эпизода."
      )
    }
    let marker = FailpointMarker(
      checkpoint: checkpoint.rawValue,
      processID: getpid(),
      generationSHA256: stored.generationSHA256
    )
    try LiveEpisodeRuntimeJSON.encode(marker).write(
      to: URL(fileURLWithPath: markerPath),
      options: .atomic
    )
    _ = raise(SIGSTOP)
  }
}

private func runFixture() -> Int32 {
  do {
    let result = try LiveEpisodeFixture.run()
    let selection = result.state.model.selection?.selectedVariantID ?? "none"
    let transition = result.state.transition?.phase.rawValue ?? "none"
    print(
      "live_episode_fixture=passed events=\(result.events.count) "
        + "variants=\(result.state.model.variants.count) "
        + "selection=\(selection) transition=\(transition)"
    )
    return 0
  } catch {
    print("live_episode_fixture=failed error=\(error)")
    return 1
  }
}

private func runCommand(_ arguments: [String]) async throws {
  guard arguments.count == 3 else {
    throw LiveEpisodeRuntimeError.invalidCommand(
      "Использование: FUMLiveEpisodeProbe <create|inspect|status|resume|replay> <каталог>."
    )
  }
  let commandName = arguments[1]
  let directory = URL(fileURLWithPath: arguments[2], isDirectory: true)
  let data = try readBoundedStandardInput()
  switch commandName {
  case "create":
    let command = try LiveEpisodeRuntimeJSON.decode(LiveEpisodeCreateCommand.self, from: data)
    let runtime = LiveEpisodeRuntime(
      rootURL: directory,
      modelAdapter: LiveEpisodeUnavailableModelAdapter(modelPolicy: command.passport.modelPolicy)
    )
    try writeJSON(runtime.create(command), to: .standardOutput)
  case "inspect":
    let command = try LiveEpisodeRuntimeJSON.decode(LiveEpisodeInspectCommand.self, from: data)
    try writeJSON(LiveEpisodeRuntime(rootURL: directory).inspect(command), to: .standardOutput)
  case "status":
    let command = try LiveEpisodeRuntimeJSON.decode(LiveEpisodeStatusCommand.self, from: data)
    try writeJSON(LiveEpisodeRuntime(rootURL: directory).status(command), to: .standardOutput)
  case "replay":
    let command = try LiveEpisodeRuntimeJSON.decode(LiveEpisodeReplayCommand.self, from: data)
    try writeJSON(LiveEpisodeRuntime(rootURL: directory).replay(command), to: .standardOutput)
  case "resume":
    let command = try LiveEpisodeRuntimeJSON.decode(LiveEpisodeResumeCommand.self, from: data)
    let runtime: LiveEpisodeRuntime
    switch command.action {
    case .invokeModel:
      if let observer = checkpointObserver() {
        let stored = try LiveEpisodeRuntime(rootURL: directory).inspect(
          LiveEpisodeInspectCommand(commandID: "probe-read-passport")
        ).stored
        runtime = LiveEpisodeRuntime(
          rootURL: directory,
          modelAdapter: LiveEpisodeUnavailableModelAdapter(
            modelPolicy: stored.state.passport.modelPolicy
          ),
          checkpointObserver: observer
        )
      } else {
        runtime = LiveEpisodeRuntime(rootURL: directory)
      }
    case .appendEvents, .confirmGeneration:
      runtime = LiveEpisodeRuntime(rootURL: directory)
    }
    try await writeJSON(runtime.resume(command), to: .standardOutput)
  default:
    throw LiveEpisodeRuntimeError.invalidCommand("Неизвестная безоконная команда \(commandName).")
  }
}

let arguments = CommandLine.arguments
if arguments.count == 1 {
  exit(runFixture())
}

do {
  try await runCommand(arguments)
} catch {
  let output = LiveEpisodeErrorOutput(code: errorCode(error), message: String(describing: error))
  try? writeJSON(output, to: .standardError)
  exit(2)
}
