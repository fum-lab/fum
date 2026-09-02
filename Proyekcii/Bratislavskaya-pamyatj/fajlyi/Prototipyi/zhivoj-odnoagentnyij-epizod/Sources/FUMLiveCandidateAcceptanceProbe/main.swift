import FUMLiveEpisodeRuntime
import Foundation

private func readBoundedStandardInput() throws -> Data {
  var data = Data()
  while let chunk = try FileHandle.standardInput.read(upToCount: 8_192), !chunk.isEmpty {
    data.append(chunk)
    guard data.count <= LiveGitCandidateAcceptanceSchema.maximumCommandBytes else {
      throw LiveGitCandidateAcceptanceError.invalidCommand(
        "Acceptance-команда превышает лимит байтов."
      )
    }
  }
  guard !data.isEmpty else {
    throw LiveGitCandidateAcceptanceError.invalidCommand(
      "JSON acceptance-команды в stdin пуст."
    )
  }
  return data
}

private func errorCode(_ error: Error) -> String {
  guard let error = error as? LiveGitCandidateAcceptanceError else {
    return "invalid_command"
  }
  switch error {
  case .unsupportedCommandSchema: return "unsupported_command_schema"
  case .invalidCommand: return "invalid_command"
  case .noConfirmedCurrent: return "no_confirmed_current"
  case .rejected: return "rejected"
  case .receiptConflict: return "receipt_conflict"
  case .storage: return "storage_error"
  }
}

do {
  guard CommandLine.arguments.count == 2 else {
    throw LiveGitCandidateAcceptanceError.invalidCommand(
      "Использование: FUMLiveCandidateAcceptanceProbe <каталог-эпизода>."
    )
  }
  let data = try readBoundedStandardInput()
  let command: LiveGitCandidateAcceptanceCommand
  do {
    command = try LiveEpisodeRuntimeJSON.decode(
      LiveGitCandidateAcceptanceCommand.self,
      from: data
    )
  } catch let error as LiveGitCandidateAcceptanceError {
    throw error
  } catch {
    throw LiveGitCandidateAcceptanceError.invalidCommand(
      "JSON acceptance-команды не соответствует точной схеме."
    )
  }
  try command.validate()
  let episodeDirectoryURL = URL(
    fileURLWithPath: CommandLine.arguments[1],
    isDirectory: true
  )
  let output = try LiveGitCandidateAcceptanceRuntime(
    episodeDirectoryURL: episodeDirectoryURL
  ).evaluate(command)
  try FileHandle.standardOutput.write(
    contentsOf: LiveEpisodeRuntimeJSON.encode(output)
  )
} catch {
  let output = LiveGitCandidateAcceptanceErrorOutput(
    code: errorCode(error),
    message: String(describing: error)
  )
  if let data = try? LiveEpisodeRuntimeJSON.encode(output) {
    try? FileHandle.standardError.write(contentsOf: data)
  }
  exit(2)
}
