import FUMVerifiableMultiAgentContour
import Foundation

guard CommandLine.arguments.count == 3 else {
  FileHandle.standardError.write(
    Data("Использование: FUMWritingSubnodePassportProbe <execution-root> <run-id>\n".utf8)
  )
  exit(64)
}

do {
  let result = try WritingSubnodeCandidateRecovery().recover(
    executionRootURL: URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true),
    runID: CommandLine.arguments[2]
  )
  guard result.outcome == .candidateCommitted,
    let canonical = result.passportCanonicalJSON
  else {
    throw WritingSubnodeExecutorError.persistenceFailed(
      "Проверенный кандидатный паспорт не восстановлен."
    )
  }
  try FileHandle.standardOutput.write(contentsOf: canonical)
} catch {
  FileHandle.standardError.write(Data("\(error)\n".utf8))
  exit(1)
}
