import Darwin
import FUMPureModelStep
import Foundation

private let fixture = """
  {
    "schema_version": 1,
    "invocation_id": "fixture-pure-model-step-v1",
    "provider": {
      "kind": "stub",
      "id": "fum.deterministic-echo.v1",
      "model": "deterministic-echo",
      "runtime": "FUMPureModelStep/1"
    },
    "messages": [
      {"role": "system", "content": "Верни только наблюдаемый текст."},
      {"role": "user", "content": "Предложение модели остаётся данными и не является действием."}
    ],
    "response_format": "text",
    "limits": {"max_output_bytes": 512, "timeout_milliseconds": 1000},
    "capabilities": {"tools": false, "files": false, "network": false}
  }
  """

private func printUsage() {
  print(
    """
    Использование: FUMModelStepProbe [fixture | stdin | --help]

    Без аргументов или с fixture выполняет встроенную детерминированную фикстуру.
    stdin читает один JSON-запрос версии 1 из стандартного ввода.
    """
  )
}

private func write(_ data: Data, to handle: FileHandle) {
  handle.write(data)
  handle.write(Data("\n".utf8))
}

private func readBoundedStandardInput() -> Data {
  var input = Data()
  let readLimit = ModelStepJSON.maximumEnvelopeBytes + 1

  while input.count < readLimit {
    let chunk = FileHandle.standardInput.readData(
      ofLength: min(64 * 1_024, readLimit - input.count)
    )
    guard !chunk.isEmpty else { break }
    input.append(chunk)
  }
  return input
}

let arguments = Array(CommandLine.arguments.dropFirst())
let input: Data

switch arguments {
case [], ["fixture"]:
  input = Data(fixture.utf8)
case ["stdin"]:
  input = readBoundedStandardInput()
case ["--help"], ["-h"]:
  printUsage()
  exit(0)
default:
  fputs("Неизвестная команда. Используйте --help.\n", stderr)
  exit(2)
}

var invocationID: String?
do {
  let request = try ModelStepJSON.decodeRequest(input)
  invocationID = request.invocationID
  let response = try DeterministicEchoProvider().complete(request)
  write(try ModelStepJSON.encodeResponse(response), to: .standardOutput)
} catch let error as ModelStepContractError {
  let envelope = ModelStepErrorEnvelope(invocationID: invocationID, error: error)
  if let data = try? ModelStepJSON.encodeError(envelope) {
    write(data, to: .standardError)
  }
  exit(2)
} catch {
  let safeError = ModelStepContractError(
    code: "internal_error",
    message: "Непредвиденная ошибка модельного шага.",
    retryable: false
  )
  let envelope = ModelStepErrorEnvelope(invocationID: invocationID, error: safeError)
  if let data = try? ModelStepJSON.encodeError(envelope) {
    write(data, to: .standardError)
  }
  exit(2)
}
