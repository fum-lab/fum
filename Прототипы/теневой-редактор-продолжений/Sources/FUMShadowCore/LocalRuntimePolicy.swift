import Foundation

public enum ModelOutputRejection: Equatable, Sendable {
    case echoedContext
    case commandHelp
    case emptyOutput
}

public enum LocalRuntimeError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    case emptyModelName
    case invalidModelName
    case invalidModelOutput(ModelOutputRejection)
    case executableNotFound(String)
    case launchFailed(String)
    case processFailed(status: Int32, diagnostic: String)
    case timedOut

    public var description: String {
        switch self {
        case .emptyModelName:
            return "Имя локальной модели Ollama не указано."
        case .invalidModelName:
            return "Имя модели Ollama имеет недопустимый формат. Используйте каноническое имя из `ollama list`."
        case .invalidModelOutput(.echoedContext):
            return "Локальная LLM повторила замороженный префикс и не вернула надёжно отделимое продолжение."
        case .invalidModelOutput(.commandHelp):
            return "Ollama вернула справку CLI вместо продолжения. Проверьте имя установленной модели."
        case .invalidModelOutput(.emptyOutput):
            return "Локальная LLM не вернула продолжение."
        case .executableNotFound(let path):
            return "Исполняемый файл Ollama не найден: \(path)"
        case .launchFailed(let message):
            return "Не удалось запустить локальный процесс Ollama: \(message)"
        case .processFailed(let status, let diagnostic):
            return "Ollama завершилась с кодом \(status): \(diagnostic)"
        case .timedOut:
            return "Истекло время ожидания локальной LLM."
        }
    }

    public var errorDescription: String? {
        description
    }
}

public enum LocalRuntimePolicy {
    public static func validateModelName(_ model: String) throws {
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalRuntimeError.emptyModelName
        }
        guard model == model.trimmingCharacters(in: .whitespacesAndNewlines),
              model.utf8.count <= 255 else {
            throw LocalRuntimeError.invalidModelName
        }

        let pathComponents = model.split(separator: "/", omittingEmptySubsequences: false)
        guard !pathComponents.isEmpty else {
            throw LocalRuntimeError.invalidModelName
        }
        for pathComponent in pathComponents {
            let colonComponents = pathComponent.split(
                separator: ":",
                maxSplits: 2,
                omittingEmptySubsequences: false
            )
            guard colonComponents.count <= 2 else {
                throw LocalRuntimeError.invalidModelName
            }
            for component in colonComponents {
                let bytes = Array(component.utf8)
                guard let first = bytes.first,
                      let last = bytes.last,
                      isASCIIAlphaNumeric(first),
                      isASCIIAlphaNumeric(last),
                      bytes.allSatisfy(isAllowedModelNameByte) else {
                    throw LocalRuntimeError.invalidModelName
                }
            }
        }
    }

    public static func ollamaEnvironment(base: [String: String]) throws -> [String: String] {
        var environment = base
        environment["OLLAMA_HOST"] = "127.0.0.1:11434"
        environment["OLLAMA_NOHISTORY"] = "1"
        return environment
    }

    private static func isAllowedModelNameByte(_ byte: UInt8) -> Bool {
        isASCIIAlphaNumeric(byte) || byte == 0x2D || byte == 0x2E || byte == 0x5F
    }

    private static func isASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
        (0x30...0x39).contains(byte)
            || (0x41...0x5A).contains(byte)
            || (0x61...0x7A).contains(byte)
    }
}

public enum OllamaExecutableLocator {
    public static func locate(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        var candidates: [String] = []
        if let configured = environment["FUM_OLLAMA_EXECUTABLE"], !configured.isEmpty {
            candidates.append(configured)
        }
        candidates.append(contentsOf: [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/Applications/Ollama.app/Contents/Resources/ollama"
        ])

        return candidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}

public struct OllamaProcessRequest: Equatable, Sendable {
    public let arguments: [String]
    public let prompt: String
    public let standardInput: Data
}

public enum OllamaRequestBuilder {
    public static func request(
        context: String,
        model: String,
        horizonBytes: Int
    ) -> OllamaProcessRequest {
        let prompt = """
        Continue the text exactly where it ends. Return only the continuation, without commentary, quotation marks, or a repeated prefix. Keep the continuation concise; the caller will stop after approximately \(horizonBytes) UTF-8 bytes.

        --- BEGIN TEXT ---
        \(context)
        --- END TEXT ---
        """
        return OllamaProcessRequest(
            arguments: [
                "run",
                model,
                "--nowordwrap",
                "--think=false",
                "--keepalive",
                "5m"
            ],
            prompt: prompt,
            standardInput: Data(prompt.utf8)
        )
    }
}

public struct LocalProcessSpecification: Sendable {
    public let executableURL: URL
    public let arguments: [String]
    public let standardInput: Data
    public let environment: [String: String]
    public let maxOutputBytes: Int
    public let timeoutSeconds: TimeInterval

    public init(
        executableURL: URL,
        arguments: [String],
        standardInput: Data,
        environment: [String: String],
        maxOutputBytes: Int,
        timeoutSeconds: TimeInterval
    ) {
        precondition(maxOutputBytes > 0, "maxOutputBytes must be positive")
        precondition(timeoutSeconds > 0, "timeoutSeconds must be positive")
        self.executableURL = executableURL
        self.arguments = arguments
        self.standardInput = standardInput
        self.environment = environment
        self.maxOutputBytes = maxOutputBytes
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct LocalProcessRunner: Sendable {
    public init() {}

    public func stream(
        _ specification: LocalProcessSpecification
    ) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream(bufferingPolicy: .unbounded) { continuation in
            let state = ProcessStreamState(
                specification: specification,
                continuation: continuation
            )
            continuation.onTermination = { @Sendable _ in
                state.cancel()
            }
            state.start()
        }
    }

    public func collect(_ specification: LocalProcessSpecification) async throws -> Data {
        var result = Data()
        for try await chunk in stream(specification) {
            result.append(chunk)
        }
        return result
    }
}

private final class ProcessStreamState: @unchecked Sendable {
    private let lock = NSLock()
    private let specification: LocalProcessSpecification
    private let continuation: AsyncThrowingStream<Data, Error>.Continuation
    private let process = Process()
    private let standardInputPipe = Pipe()
    private let standardOutputPipe = Pipe()
    private let standardErrorPipe = Pipe()
    private var emittedByteCount = 0
    private var diagnostic = Data()
    private var reachedOutputLimit = false
    private var didTimeOut = false
    private var didFinish = false

    init(
        specification: LocalProcessSpecification,
        continuation: AsyncThrowingStream<Data, Error>.Continuation
    ) {
        self.specification = specification
        self.continuation = continuation
    }

    func start() {
        guard FileManager.default.isExecutableFile(atPath: specification.executableURL.path) else {
            finish(
                throwing: LocalRuntimeError.executableNotFound(specification.executableURL.path)
            )
            return
        }

        process.executableURL = specification.executableURL
        process.arguments = specification.arguments
        process.environment = specification.environment
        process.standardInput = standardInputPipe
        process.standardOutput = standardOutputPipe
        process.standardError = standardErrorPipe

        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.consumeStandardOutput(handle.availableData)
        }
        standardErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.consumeStandardError(handle.availableData)
        }
        process.terminationHandler = { [weak self] process in
            self?.processDidTerminate(status: process.terminationStatus)
        }

        do {
            try process.run()
            try standardInputPipe.fileHandleForWriting.write(contentsOf: specification.standardInput)
            try standardInputPipe.fileHandleForWriting.close()
        } catch {
            finish(throwing: LocalRuntimeError.launchFailed(String(describing: error)))
            return
        }

        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + specification.timeoutSeconds
        ) { [weak self] in
            self?.timeOutIfNeeded()
        }
    }

    func cancel() {
        lock.lock()
        let shouldTerminate = !didFinish && process.isRunning
        lock.unlock()
        if shouldTerminate {
            process.terminate()
        }
    }

    private func consumeStandardOutput(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        let remaining = max(specification.maxOutputBytes - emittedByteCount, 0)
        let accepted = Data(data.prefix(remaining))
        emittedByteCount += accepted.count
        if emittedByteCount >= specification.maxOutputBytes {
            reachedOutputLimit = true
        }
        let shouldTerminate = reachedOutputLimit && process.isRunning
        lock.unlock()

        if !accepted.isEmpty {
            continuation.yield(accepted)
        }
        if shouldTerminate {
            process.terminate()
        }
    }

    private func consumeStandardError(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        if diagnostic.count < 8_192 {
            diagnostic.append(data.prefix(8_192 - diagnostic.count))
        }
        lock.unlock()
    }

    private func processDidTerminate(status: Int32) {
        standardOutputPipe.fileHandleForReading.readabilityHandler = nil
        standardErrorPipe.fileHandleForReading.readabilityHandler = nil
        consumeStandardOutput(standardOutputPipe.fileHandleForReading.readDataToEndOfFile())
        consumeStandardError(standardErrorPipe.fileHandleForReading.readDataToEndOfFile())

        lock.lock()
        let limited = reachedOutputLimit
        let timedOut = didTimeOut
        let message = String(decoding: diagnostic, as: UTF8.self)
        lock.unlock()

        if timedOut {
            finish(throwing: LocalRuntimeError.timedOut)
        } else if status == 0 || limited {
            finish()
        } else {
            finish(
                throwing: LocalRuntimeError.processFailed(
                    status: status,
                    diagnostic: message
                )
            )
        }
    }

    private func timeOutIfNeeded() {
        lock.lock()
        guard !didFinish, process.isRunning else {
            lock.unlock()
            return
        }
        didTimeOut = true
        lock.unlock()
        process.terminate()
    }

    private func finish(throwing error: Error? = nil) {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        lock.unlock()

        standardOutputPipe.fileHandleForReading.readabilityHandler = nil
        standardErrorPipe.fileHandleForReading.readabilityHandler = nil
        if process.isRunning {
            process.terminate()
        }
        if let error {
            continuation.finish(throwing: error)
        } else {
            continuation.finish()
        }
    }
}

public protocol ContinuationProvider: Sendable {
    var identity: String { get }

    func streamContinuation(
        context: String,
        horizonBytes: Int
    ) throws -> AsyncThrowingStream<Data, Error>
}

public struct OllamaContinuationProvider: ContinuationProvider, Sendable {
    public let executableURL: URL
    public let model: String
    public let timeoutSeconds: TimeInterval
    private let runner = LocalProcessRunner()

    public init(
        executableURL: URL,
        model: String,
        timeoutSeconds: TimeInterval = 60
    ) {
        self.executableURL = executableURL
        self.model = model
        self.timeoutSeconds = timeoutSeconds
    }

    public var identity: String {
        "ollama/\(model)"
    }

    public func streamContinuation(
        context: String,
        horizonBytes: Int
    ) throws -> AsyncThrowingStream<Data, Error> {
        try LocalRuntimePolicy.validateModelName(model)
        let environment = try LocalRuntimePolicy.ollamaEnvironment(
            base: ProcessInfo.processInfo.environment
        )
        let request = OllamaRequestBuilder.request(
            context: context,
            model: model,
            horizonBytes: horizonBytes
        )
        let contextData = Data(context.utf8)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let showSpecification = LocalProcessSpecification(
                        executableURL: executableURL,
                        arguments: ["show", model],
                        standardInput: Data(),
                        environment: environment,
                        maxOutputBytes: 16_384,
                        timeoutSeconds: min(timeoutSeconds, 15)
                    )
                    _ = try await runner.collect(showSpecification)

                    let runSpecification = LocalProcessSpecification(
                        executableURL: executableURL,
                        arguments: request.arguments,
                        standardInput: request.standardInput,
                        environment: environment,
                        maxOutputBytes: ModelOutputStreamNormalizer.rawOutputByteLimit(
                            contextByteCount: contextData.count,
                            horizonBytes: horizonBytes
                        ),
                        timeoutSeconds: timeoutSeconds
                    )
                    var normalizer = ModelOutputStreamNormalizer(
                        context: contextData,
                        horizonBytes: horizonBytes
                    )
                    let processStream = runner.stream(runSpecification)
                    for try await chunk in processStream {
                        try Task.checkCancellation()
                        let normalized = try normalizer.append(chunk)
                        if !normalized.isEmpty {
                            continuation.yield(normalized)
                        }
                        if normalizer.isComplete {
                            break
                        }
                    }
                    let finalChunk = try normalizer.finish()
                    if !finalChunk.isEmpty {
                        continuation.yield(finalChunk)
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
