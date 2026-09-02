import CryptoKit
import Darwin
import FUMLiveEpisodeCore
import FUMLiveEpisodeRuntime
import Foundation

private struct ProcessCapture {
  let processID: Int32
  let terminationReason: Process.TerminationReason
  let terminationStatus: Int32
  let output: Data
  let errors: Data
}

private enum HarnessError: Error, CustomStringConvertible {
  case invalidArguments
  case timeout(String)
  case childFailure(String)
  case invariant(String)

  var description: String {
    switch self {
    case .invalidArguments:
      "Использование: FUMLiveEpisodeHarness <recorded|live> <пустой-run-directory>."
    case .timeout(let message), .childFailure(let message), .invariant(let message):
      message
    }
  }
}

private func executable(named name: String) -> URL {
  URL(fileURLWithPath: CommandLine.arguments[0], isDirectory: false)
    .standardizedFileURL
    .deletingLastPathComponent()
    .appendingPathComponent(name, isDirectory: false)
}

private func configuredProcess(
  executableURL: URL,
  arguments: [String],
  runDirectoryURL: URL
) throws -> (Process, Pipe, Pipe) {
  guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
    throw HarnessError.childFailure(
      "Дочерний executable \(executableURL.lastPathComponent) недоступен.")
  }
  let process = Process()
  process.executableURL = executableURL
  process.arguments = arguments
  process.currentDirectoryURL = runDirectoryURL
  process.environment = [
    "PATH": LiveGitSystemRuntime.executableSearchPath,
    "LC_ALL": "C",
  ]
  process.standardInput = FileHandle.nullDevice
  let output = Pipe()
  let errors = Pipe()
  process.standardOutput = output
  process.standardError = errors
  return (process, output, errors)
}

private func checkpointMarkerURL(
  _ checkpoint: LiveSingleAgentCheckpointID,
  runDirectoryURL: URL
) -> URL {
  runDirectoryURL
    .appendingPathComponent(
      LiveSingleAgentEpisodeSchema.checkpointRelativePath,
      isDirectory: true
    )
    .appendingPathComponent("\(checkpoint.rawValue).json", isDirectory: false)
}

private func runCheckpointWorker(
  checkpoint: LiveSingleAgentCheckpointID,
  passport: LiveSingleAgentExecutionPassport,
  workerURL: URL,
  runDirectoryURL: URL
) throws -> (LiveSingleAgentWorkerOutput, LiveSingleAgentCheckpointMarker) {
  let (process, outputPipe, errorPipe) = try configuredProcess(
    executableURL: workerURL,
    arguments: [runDirectoryURL.path],
    runDirectoryURL: runDirectoryURL
  )
  try process.run()
  var reaped = false
  defer {
    if !reaped, process.isRunning {
      _ = kill(process.processIdentifier, SIGKILL)
      process.waitUntilExit()
    }
  }
  let markerURL = checkpointMarkerURL(checkpoint, runDirectoryURL: runDirectoryURL)
  let deadline = DispatchTime.now().uptimeNanoseconds + 120_000_000_000
  while !FileManager.default.fileExists(atPath: markerURL.path) {
    guard process.isRunning else {
      process.waitUntilExit()
      reaped = true
      let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
      let errors = errorPipe.fileHandleForReading.readDataToEndOfFile()
      throw HarnessError.childFailure(
        "Worker завершился до checkpoint: reason=\(process.terminationReason.rawValue) "
          + "status=\(process.terminationStatus) stdout="
          + "\(String(decoding: output, as: UTF8.self)) stderr="
          + "\(String(decoding: errors, as: UTF8.self))."
      )
    }
    guard DispatchTime.now().uptimeNanoseconds < deadline else {
      throw HarnessError.timeout("Worker не достиг checkpoint \(checkpoint.rawValue).")
    }
    usleep(10_000)
  }
  let markerData = try Data(contentsOf: markerURL, options: [.mappedIfSafe])
  let marker = try LiveEpisodeRuntimeJSON.decode(
    LiveSingleAgentCheckpointMarker.self,
    from: markerData
  )
  guard markerData == (try LiveEpisodeRuntimeJSON.encode(marker)),
    marker.schemaIdentity == LiveSingleAgentEpisodeSchema.checkpointMarkerIdentity,
    marker.schemaVersion == LiveSingleAgentEpisodeSchema.version,
    marker.checkpoint == checkpoint,
    marker.processID == process.processIdentifier
  else {
    throw HarnessError.invariant("Checkpoint marker не связан с остановленным worker.")
  }
  let episodeURL = runDirectoryURL.appendingPathComponent(
    passport.episodeRelativePath,
    isDirectory: true
  )
  let current = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
    LiveEpisodeInspectCommand(commandID: "single-agent-harness-checkpoint-inspect")
  ).stored
  let requiredEventID: String
  switch checkpoint {
  case .selectionGenerationConfirmed:
    requiredEventID = "event-model-selection"
  case .candidateObservationGenerationConfirmed:
    requiredEventID = passport.candidatePlan.observationEventID
  }
  guard current.generationSHA256 == marker.generationSHA256,
    current.generation.stateSHA256 == marker.stateSHA256,
    current.state.model.commonCheckpoint?.ancestorSHA256 == (try passport.canonicalSHA256()),
    let confirmation = current.state.confirmedGeneration,
    let requiredEvent = current.state.events.first(where: { $0.eventID == requiredEventID }),
    requiredEvent.sequence <= confirmation.confirmation.confirmedThroughSequence
  else {
    throw HarnessError.invariant(
      "Harness не подтвердил marker по точному CURRENT и смысловому checkpoint."
    )
  }
  guard kill(process.processIdentifier, SIGKILL) == 0 else {
    throw HarnessError.childFailure("Harness не смог послать фактический SIGKILL.")
  }
  process.waitUntilExit()
  reaped = true
  let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
  let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
  guard process.terminationReason == .uncaughtSignal,
    process.terminationStatus == SIGKILL,
    errorData.isEmpty
  else {
    throw HarnessError.childFailure("Checkpoint worker завершён не точным SIGKILL.")
  }
  let output = try LiveEpisodeRuntimeJSON.decode(
    LiveSingleAgentWorkerOutput.self,
    from: outputData
  )
  guard outputData == (try LiveEpisodeRuntimeJSON.encode(output)),
    output.schemaIdentity == LiveSingleAgentEpisodeSchema.workerOutputIdentity,
    output.schemaVersion == LiveSingleAgentEpisodeSchema.version,
    output.status == .checkpoint,
    output.processID == marker.processID,
    output.checkpoint == marker.checkpoint,
    output.generationSHA256 == marker.generationSHA256,
    output.stateSHA256 == marker.stateSHA256
  else {
    throw HarnessError.invariant("Worker output не совпадает с checkpoint marker.")
  }
  return (output, marker)
}

private func publishExternalConfirmation(
  passport: LiveSingleAgentExecutionPassport,
  marker: LiveSingleAgentCheckpointMarker,
  runDirectoryURL: URL
) throws -> LiveSingleAgentExternalConfirmation {
  guard marker.checkpoint == .selectionGenerationConfirmed else {
    throw HarnessError.invariant("Внешнее подтверждение требует первый checkpoint.")
  }
  let confirmation = LiveSingleAgentExternalConfirmation(
    harnessProcessID: getpid(),
    observedCheckpoint: marker.checkpoint,
    observedWorkerProcessID: marker.processID,
    generationSHA256: marker.generationSHA256,
    stateSHA256: marker.stateSHA256,
    executionPassportSHA256: try passport.canonicalSHA256()
  )
  let data = try LiveEpisodeRuntimeJSON.encode(confirmation)
  let destination = runDirectoryURL.appendingPathComponent(
    LiveSingleAgentEpisodeSchema.externalConfirmationFileName,
    isDirectory: false
  )
  try data.write(to: destination, options: [.withoutOverwriting])
  return confirmation
}

private func runToExit(
  executableURL: URL,
  arguments: [String],
  runDirectoryURL: URL
) throws -> ProcessCapture {
  let (process, outputPipe, errorPipe) = try configuredProcess(
    executableURL: executableURL,
    arguments: arguments,
    runDirectoryURL: runDirectoryURL
  )
  try process.run()
  let processID = process.processIdentifier
  process.waitUntilExit()
  return ProcessCapture(
    processID: processID,
    terminationReason: process.terminationReason,
    terminationStatus: process.terminationStatus,
    output: outputPipe.fileHandleForReading.readDataToEndOfFile(),
    errors: errorPipe.fileHandleForReading.readDataToEndOfFile()
  )
}

private func treeSHA256(_ root: URL) throws -> String {
  guard
    let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey],
      options: [],
      errorHandler: { _, _ in false }
    )
  else {
    throw HarnessError.invariant("Не удалось перечислить run directory для no-call replay.")
  }
  var entries: [(String, URL)] = []
  for case let url as URL in enumerator {
    let relative = String(url.path.dropFirst(root.path.count + 1))
    entries.append((relative, url))
  }
  entries.sort { $0.0 < $1.0 }
  var data = Data()
  for (relative, url) in entries {
    let values = try url.resourceValues(forKeys: [
      .isRegularFileKey,
      .isDirectoryKey,
      .isSymbolicLinkKey,
    ])
    guard values.isSymbolicLink != true else {
      throw HarnessError.invariant("Run directory содержит неожиданный symlink.")
    }
    data.append(contentsOf: relative.utf8)
    data.append(0)
    if values.isDirectory == true {
      data.append(0x44)
    } else if values.isRegularFile == true {
      data.append(0x46)
      data.append(try Data(contentsOf: url, options: [.mappedIfSafe]))
    } else {
      throw HarnessError.invariant("Run directory содержит неподдерживаемый объект.")
    }
    data.append(0)
  }
  return "sha256:"
    + SHA256.hash(data: data).map {
      String(format: "%02x", $0)
    }.joined()
}

private func runHarness(
  mode: LiveSingleAgentTransportMode,
  runDirectoryURL: URL
) throws -> LiveSingleAgentEpisodeReport {
  let workerURL = executable(named: "FUMLiveEpisodeWorker")
  _ = try LiveSingleAgentEpisodeRuntime.prepare(
    runDirectoryURL: runDirectoryURL,
    transportMode: mode
  )
  let runtime = LiveSingleAgentEpisodeRuntime(
    runDirectoryURL: runDirectoryURL,
    acceptanceExecutableURL: executable(named: "FUMLiveCandidateAcceptanceProbe")
  )
  let passport = try runtime.loadExecutionPassport()

  let first = try runCheckpointWorker(
    checkpoint: .selectionGenerationConfirmed,
    passport: passport,
    workerURL: workerURL,
    runDirectoryURL: runDirectoryURL
  )
  let externalConfirmation = try publishExternalConfirmation(
    passport: passport,
    marker: first.1,
    runDirectoryURL: runDirectoryURL
  )
  let second = try runCheckpointWorker(
    checkpoint: .candidateObservationGenerationConfirmed,
    passport: passport,
    workerURL: workerURL,
    runDirectoryURL: runDirectoryURL
  )
  let thirdCapture = try runToExit(
    executableURL: workerURL,
    arguments: [runDirectoryURL.path],
    runDirectoryURL: runDirectoryURL
  )
  guard thirdCapture.terminationReason == .exit,
    thirdCapture.terminationStatus == 0,
    thirdCapture.errors.isEmpty
  else {
    throw HarnessError.childFailure(
      "Terminal worker завершился отказом: \(String(decoding: thirdCapture.errors, as: UTF8.self))."
    )
  }
  let third = try LiveEpisodeRuntimeJSON.decode(
    LiveSingleAgentWorkerOutput.self,
    from: thirdCapture.output
  )
  guard thirdCapture.output == (try LiveEpisodeRuntimeJSON.encode(third)),
    third.schemaIdentity == LiveSingleAgentEpisodeSchema.workerOutputIdentity,
    third.schemaVersion == LiveSingleAgentEpisodeSchema.version,
    third.status == .completed,
    third.processID == thirdCapture.processID,
    third.candidateOID == passport.candidatePlan.policy.expectedCandidateOID,
    let acceptanceProcessID = third.acceptanceProcessID,
    let acceptanceVerdict = third.acceptanceVerdict,
    acceptanceVerdict == .accepted,
    let acceptanceReceiptSHA256 = third.acceptanceReceiptSHA256,
    let terminalOutcome = third.terminalOutcome,
    terminalOutcome == .completed
  else {
    throw HarnessError.invariant("Terminal worker output неполон.")
  }
  let workerPIDs = [first.0.processID, second.0.processID, third.processID]
  guard Set(workerPIDs).count == 3,
    !workerPIDs.contains(acceptanceProcessID)
  else {
    throw HarnessError.invariant(
      "Два возобновления и отдельная приёмка требуют новые различные PID."
    )
  }

  let beforeReplay = try treeSHA256(runDirectoryURL)
  let replayOne = try runToExit(
    executableURL: workerURL,
    arguments: ["--replay", runDirectoryURL.path],
    runDirectoryURL: runDirectoryURL
  )
  let replayTwo = try runToExit(
    executableURL: workerURL,
    arguments: ["--replay", runDirectoryURL.path],
    runDirectoryURL: runDirectoryURL
  )
  guard replayOne.terminationReason == .exit, replayOne.terminationStatus == 0,
    replayOne.errors.isEmpty,
    replayTwo.terminationReason == .exit, replayTwo.terminationStatus == 0,
    replayTwo.errors.isEmpty
  else {
    throw HarnessError.childFailure("No-call replay завершился отказом.")
  }
  let afterReplay = try treeSHA256(runDirectoryURL)
  let projection = try LiveEpisodeRuntimeJSON.decode(
    LiveSingleAgentProjection.self,
    from: replayOne.output
  )
  let projectionSHA256 = LiveSingleAgentExecutionPassport.sha256(replayOne.output)
  guard replayOne.output == replayTwo.output,
    replayOne.output == (try LiveEpisodeRuntimeJSON.encode(projection)),
    beforeReplay == afterReplay,
    projection.schemaIdentity == LiveSingleAgentEpisodeSchema.projectionIdentity,
    projection.schemaVersion == LiveSingleAgentEpisodeSchema.version,
    projection.executionPassportSHA256 == (try passport.canonicalSHA256()),
    projection.eventKinds.filter({ $0 == .continuationDecided }).count == 1,
    projection.terminalOutcome == .completed,
    projection.candidateOID == passport.candidatePlan.policy.expectedCandidateOID,
    projection.parentOID == passport.candidatePlan.policy.baseCommitOID,
    projection.treeOID == passport.candidatePlan.policy.expectedTreeOID,
    projection.candidateBranch == passport.candidatePlan.policy.candidateBranch,
    projection.resultRef == passport.candidatePlan.policy.resultRef,
    projection.acceptanceVerdict == .accepted
  else {
    throw HarnessError.invariant(
      "Replay изменил состояние либо не воспроизвёл каноническую проекцию побайтово."
    )
  }
  if mode == .recorded,
    projectionSHA256 != LiveSingleAgentEpisodeSchema.recordedProjectionSHA256
  {
    throw HarnessError.invariant(
      "Recorded replay не совпал с закреплённым SHA канонической проекции."
    )
  }

  let episodeURL = runDirectoryURL.appendingPathComponent(
    passport.episodeRelativePath,
    isDirectory: true
  )
  let final = try LiveEpisodeRuntime(rootURL: episodeURL).inspect(
    LiveEpisodeInspectCommand(commandID: "single-agent-harness-final-inspect")
  ).stored
  guard final.generationSHA256 == third.generationSHA256,
    final.generation.stateSHA256 == third.stateSHA256,
    final.state.events.filter({ $0.kind == .continuationDecided }).count == 1,
    final.state.continuation?.continuation.decision == .completed
  else {
    throw HarnessError.invariant(
      "Terminal worker output не связан с единственным исходом в CURRENT."
    )
  }
  let modelResponseCount = final.state.events.filter {
    $0.kind == .modelResponseRecorded
  }.count
  let budgetCheckpointNoCall =
    final.state.events.contains(where: {
      guard case .budgetCheckpointCreated(let checkpoint) = $0.payload else { return false }
      return checkpoint.proposal.variantID == "variant-c"
    })
    && !final.state.events.contains(where: {
      guard case .modelRequestRecorded(let request) = $0.payload else { return false }
      return request.proposal.variantID == "variant-c"
    }) && modelResponseCount == 2
  guard budgetCheckpointNoCall else {
    throw HarnessError.invariant(
      "Независимый аудит не подтвердил третий budget checkpoint без model-вызова."
    )
  }
  let sourceURL = runDirectoryURL.appendingPathComponent(
    passport.sourceCheckoutRelativePath,
    isDirectory: true
  )
  try LiveSingleAgentScenarioFactory.auditPreparedSource(at: sourceURL)

  return LiveSingleAgentEpisodeReport(
    transportMode: mode,
    executionPassportSHA256: try passport.canonicalSHA256(),
    providerIdentity: passport.episodePassport.modelPolicy.providerIdentity,
    chargedUsage: final.state.model.budget.charged,
    harnessProcessID: getpid(),
    workerProcessIDs: workerPIDs,
    sigkillProcessIDs: [first.0.processID, second.0.processID],
    replayProcessIDs: [replayOne.processID, replayTwo.processID],
    checkpoints: [first.1, second.1],
    externalConfirmationSHA256: LiveSingleAgentExecutionPassport.sha256(
      try LiveEpisodeRuntimeJSON.encode(externalConfirmation)
    ),
    candidateOID: passport.candidatePlan.policy.expectedCandidateOID,
    parentOID: passport.candidatePlan.policy.baseCommitOID,
    treeOID: passport.candidatePlan.policy.expectedTreeOID,
    candidateBranch: passport.candidatePlan.policy.candidateBranch,
    resultRef: passport.candidatePlan.policy.resultRef,
    acceptanceProcessID: acceptanceProcessID,
    acceptanceVerdict: acceptanceVerdict,
    acceptanceReceiptSHA256: acceptanceReceiptSHA256,
    terminalOutcome: terminalOutcome,
    finalGenerationSHA256: third.generationSHA256,
    finalStateSHA256: third.stateSHA256,
    eventJournalSHA256: final.generation.eventJournalSHA256,
    projectionSHA256: projectionSHA256,
    eventCount: final.state.events.count,
    modelResponseCount: modelResponseCount,
    budgetCheckpointNoCall: budgetCheckpointNoCall,
    replayBytesEqual: replayOne.output == replayTwo.output,
    replayNoEffects: beforeReplay == afterReplay,
    sourceUnchanged: true
  )
}

do {
  guard CommandLine.arguments.count == 3 else { throw HarnessError.invalidArguments }
  let mode: LiveSingleAgentTransportMode
  switch CommandLine.arguments[1] {
  case "recorded": mode = .recorded
  case "live": mode = .lmStudioLive
  default: throw HarnessError.invalidArguments
  }
  let runDirectoryURL = URL(
    fileURLWithPath: CommandLine.arguments[2],
    isDirectory: true
  ).standardizedFileURL
  let report = try runHarness(mode: mode, runDirectoryURL: runDirectoryURL)
  try FileHandle.standardOutput.write(contentsOf: LiveEpisodeRuntimeJSON.encode(report))
} catch {
  let output = LiveEpisodeErrorOutput(
    code: "single_agent_harness_failed",
    message: String(describing: error)
  )
  if let data = try? LiveEpisodeRuntimeJSON.encode(output) {
    try? FileHandle.standardError.write(contentsOf: data)
  }
  exit(2)
}
