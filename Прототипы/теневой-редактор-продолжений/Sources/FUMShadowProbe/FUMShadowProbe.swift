import Foundation
import FUMShadowCore

@main
struct FUMShadowProbe {
    static func main() async {
        do {
            let options = try ProbeOptions(arguments: Array(CommandLine.arguments.dropFirst()))
            guard let executableURL = options.executableURL ?? OllamaExecutableLocator.locate() else {
                throw LocalRuntimeError.executableNotFound("ollama")
            }
            let provider = OllamaContinuationProvider(
                executableURL: executableURL,
                model: options.model,
                timeoutSeconds: options.timeoutSeconds
            )
            let stream = try provider.streamContinuation(
                context: options.context,
                horizonBytes: options.horizonBytes
            )
            for try await chunk in stream {
                try FileHandle.standardOutput.write(contentsOf: chunk)
            }
            try FileHandle.standardOutput.write(contentsOf: Data("\n".utf8))
        } catch {
            let message = "FUMShadowProbe: \(error)\n"
            try? FileHandle.standardError.write(contentsOf: Data(message.utf8))
            exit(2)
        }
    }
}

private struct ProbeOptions {
    let model: String
    let context: String
    let horizonBytes: Int
    let timeoutSeconds: TimeInterval
    let executableURL: URL?

    init(arguments: [String]) throws {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            guard key.hasPrefix("--"), index + 1 < arguments.count else {
                throw ProbeError.invalidArguments
            }
            values[key] = arguments[index + 1]
            index += 2
        }

        guard let model = values["--model"], !model.isEmpty else {
            throw ProbeError.missingModel
        }
        if let filePath = values["--file"] {
            context = try String(contentsOfFile: filePath, encoding: .utf8)
        } else if let directContext = values["--context"] {
            context = directContext
        } else {
            context = String(
                decoding: try FileHandle.standardInput.readToEnd() ?? Data(),
                as: UTF8.self
            )
        }
        self.model = model
        horizonBytes = Int(values["--horizon"] ?? "128") ?? 128
        timeoutSeconds = TimeInterval(values["--timeout"] ?? "60") ?? 60
        executableURL = values["--executable"].map { URL(fileURLWithPath: $0) }

        guard horizonBytes > 0, timeoutSeconds > 0 else {
            throw ProbeError.invalidArguments
        }
    }
}

private enum ProbeError: Error {
    case missingModel
    case invalidArguments
}
