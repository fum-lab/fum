import AppKit
import Foundation
import FUMShadowCore

@MainActor
final class EditorViewModel: ObservableObject {
    @Published private(set) var text = ""
    @Published private(set) var documentURL: URL?
    @Published private(set) var isDirty = false
    @Published private(set) var indexSummary = SuffixIndexSummary(
        processedBytes: 0,
        nodeCount: 1,
        skippedNodeCreations: 0
    )
    @Published private(set) var activeExperiment: ContinuationExperiment?
    @Published private(set) var lastExperiment: ContinuationExperiment?
    @Published private(set) var statusMessage = "Откройте или сохраните текстовый файл."
    @Published private(set) var errorMessage: String?
    @Published var modelName: String
    @Published var automaticCheckpoints = true
    @Published var persistComparisonTrace = false

    let indexConfiguration = SuffixIndexConfiguration(maxDepth: 48, maxNodes: 250_000)
    let horizonBytes = 128
    let contextWindowBytes = 12_000

    private var documentVersion = 0
    private var selection = NSRange(location: 0, length: 0)
    private var documentIndex: BoundedSuffixContextTree
    private var checkpointTask: Task<Void, Never>?
    private var modelTask: Task<Void, Never>?
    private var autosaveTask: Task<Void, Never>?
    private var indexRebuildTask: Task<BoundedSuffixContextTree?, Never>?
    private var indexApplyTask: Task<Void, Never>?
    private let ollamaExecutableURL: URL?

    init() {
        let environment = ProcessInfo.processInfo.environment
        modelName = environment["FUM_LLM_MODEL"] ?? ""
        ollamaExecutableURL = OllamaExecutableLocator.locate(environment: environment)
        documentIndex = BoundedSuffixContextTree(configuration: indexConfiguration)

        if let argument = CommandLine.arguments.dropFirst().first,
           !argument.hasPrefix("--") {
            loadDocument(at: URL(fileURLWithPath: argument))
        }
    }

    var documentTitle: String {
        documentURL?.lastPathComponent ?? "Без имени"
    }

    var ollamaPath: String {
        ollamaExecutableURL?.path ?? "не найден"
    }

    var caretIsAtEnd: Bool {
        selection.location + selection.length == (text as NSString).length
    }

    func editorChanged(
        to newText: String,
        selection newSelection: NSRange,
        change: PlainTextChange?
    ) {
        let previousUTF16Length = (text as NSString).length
        let newUTF16Length = (newText as NSString).length
        let appendedBytes: Data?
        if let change,
           change.range.location == previousUTF16Length,
           change.range.length == 0,
           newUTF16Length == previousUTF16Length + (change.replacement as NSString).length {
            appendedBytes = Data(change.replacement.utf8)
        } else {
            appendedBytes = nil
        }

        text = newText
        selection = newSelection
        documentVersion += 1
        isDirty = true
        errorMessage = nil

        if let appendedBytes, indexRebuildTask == nil {
            documentIndex.append(appendedBytes)
            indexSummary = documentIndex.summary
            observeHumanAppend(appendedBytes)
        } else {
            let newData = Data(newText.utf8)
            rebuildIndex(for: newData, version: documentVersion)
            observeHumanDocument(newData)
        }

        scheduleAutosave()
        scheduleAutomaticCheckpoint()
    }

    func selectionChanged(_ newSelection: NSRange) {
        selection = newSelection
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadDocument(at: url)
    }

    func saveDocument() {
        if let documentURL {
            saveDocument(to: documentURL)
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "мысль.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        documentURL = url
        saveDocument(to: url)
    }

    func startCheckpoint() {
        checkpointTask?.cancel()
        guard activeExperiment == nil else { return }
        guard caretIsAtEnd else {
            statusMessage = "Контрольная точка создаётся только в конце файла."
            return
        }
        guard !text.isEmpty else {
            statusMessage = "Нужен непустой префикс текста."
            return
        }
        guard !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Укажите имя уже установленной локальной модели Ollama."
            return
        }
        guard let ollamaExecutableURL else {
            statusMessage = "Локальный исполняемый файл Ollama не найден."
            return
        }

        let provider = OllamaContinuationProvider(
            executableURL: ollamaExecutableURL,
            model: modelName
        )
        let experiment = ContinuationExperiment(
            prefix: Data(text.utf8),
            documentVersion: documentVersion,
            modelIdentity: provider.identity,
            horizonBytes: horizonBytes,
            contextWindowBytes: contextWindowBytes,
            indexConfiguration: indexConfiguration
        )
        activeExperiment = experiment
        statusMessage = "Теневая гипотеза строится локально; её текст пока скрыт."
        let checkpointID = experiment.checkpoint.id
        let context = String(decoding: experiment.checkpoint.modelContext, as: UTF8.self)

        modelTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = try provider.streamContinuation(
                    context: context,
                    horizonBytes: horizonBytes
                )
                for try await chunk in stream {
                    try Task.checkCancellation()
                    appendModelChunk(chunk, checkpointID: checkpointID)
                }
                if activeExperiment?.checkpoint.id == checkpointID {
                    statusMessage = "Гипотеза готова и скрыта; продолжается ожидание текста человека."
                }
            } catch is CancellationError {
                return
            } catch {
                failActiveExperiment(checkpointID: checkpointID, error: error)
            }
        }
    }

    func completeCurrentComparison() {
        guard var experiment = activeExperiment else { return }
        do {
            try experiment.completeCurrentHumanHorizon()
            guard experiment.status == .completed else { return }
            finish(experiment)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func clearTrace() {
        guard let sidecarURL else { return }
        let traceURL = sidecarURL.appendingPathComponent("comparisons.jsonl")
        do {
            if FileManager.default.fileExists(atPath: traceURL.path) {
                try FileManager.default.removeItem(at: traceURL)
            }
            if FileManager.default.fileExists(atPath: sidecarURL.path),
               try FileManager.default.contentsOfDirectory(atPath: sidecarURL.path).isEmpty {
                try FileManager.default.removeItem(at: sidecarURL)
            }
            statusMessage = "Локальная трасса сравнений удалена."
        } catch {
            errorMessage = "Не удалось удалить трассу: \(error)"
        }
    }

    private func loadDocument(at url: URL) {
        do {
            let loadedText = try String(contentsOf: url, encoding: .utf8)
            cancelCurrentWork()
            text = loadedText
            documentURL = url
            documentVersion += 1
            selection = NSRange(location: (loadedText as NSString).length, length: 0)
            isDirty = false
            lastExperiment = nil
            errorMessage = nil
            rebuildIndex(for: Data(loadedText.utf8), version: documentVersion)
            statusMessage = "Файл открыт; после паузы будет создана теневая контрольная точка."
            scheduleAutomaticCheckpoint()
        } catch {
            errorMessage = "Не удалось открыть файл: \(error)"
        }
    }

    private func saveDocument(to url: URL) {
        do {
            try Data(text.utf8).write(to: url, options: .atomic)
            isDirty = false
            statusMessage = "Файл сохранён локально."
        } catch {
            errorMessage = "Не удалось сохранить файл: \(error)"
        }
    }

    private func observeHumanDocument(_ data: Data) {
        guard var experiment = activeExperiment else { return }
        do {
            try experiment.observeDocument(data, documentVersion: documentVersion)
            activeExperiment = experiment
            if experiment.status == .completed || experiment.status == .invalidated {
                finish(experiment)
            }
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func observeHumanAppend(_ data: Data) {
        guard var experiment = activeExperiment else { return }
        do {
            try experiment.observeAppendedBytes(data, documentVersion: documentVersion)
            activeExperiment = experiment
            if experiment.status == .completed {
                finish(experiment)
            }
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func appendModelChunk(_ chunk: Data, checkpointID: UUID) {
        guard var experiment = activeExperiment,
              experiment.checkpoint.id == checkpointID else {
            return
        }
        experiment.appendModelChunk(chunk)
        activeExperiment = experiment
        statusMessage = "Теневая гипотеза: \(experiment.modelContinuation.count) из \(horizonBytes) байт; текст скрыт."
    }

    private func failActiveExperiment(checkpointID: UUID, error: Error) {
        guard var experiment = activeExperiment,
              experiment.checkpoint.id == checkpointID else {
            return
        }
        experiment.failModel()
        activeExperiment = nil
        lastExperiment = experiment
        errorMessage = "Локальная LLM не выполнила прогноз: \(error)"
        statusMessage = "Контрольная точка завершилась ошибкой локальной модели."
    }

    private func finish(_ experiment: ContinuationExperiment) {
        modelTask?.cancel()
        modelTask = nil
        activeExperiment = nil
        lastExperiment = experiment

        switch experiment.status {
        case .completed:
            if persistComparisonTrace {
                statusMessage = "Сравнение завершено; обе ветви, метрики и локальная трасса готовы."
                appendTrace(experiment)
            } else {
                statusMessage = "Сравнение завершено; трасса не сохранялась."
            }
        case .invalidated:
            statusMessage = "Контрольная точка отменена: изменён текст до её позиции."
        case .failed:
            statusMessage = "Контрольная точка завершилась ошибкой."
        case .collecting:
            break
        }
    }

    private func rebuildIndex(for data: Data, version: Int) {
        let previousBuild = indexRebuildTask
        previousBuild?.cancel()
        indexApplyTask?.cancel()
        let configuration = indexConfiguration
        let buildTask = Task.detached(priority: .utility) {
            () -> BoundedSuffixContextTree? in
            if let previousBuild {
                _ = await previousBuild.value
            }
            guard !Task.isCancelled else { return nil }
            return try? BoundedSuffixContextTree.buildCancellable(
                data: data,
                configuration: configuration
            )
        }
        indexRebuildTask = buildTask
        indexApplyTask = Task { [weak self, buildTask] in
            guard let rebuilt = await buildTask.value,
                  !Task.isCancelled,
                  let self,
                  self.documentVersion == version else {
                return
            }
            self.documentIndex = rebuilt
            self.indexSummary = rebuilt.summary
            self.indexRebuildTask = nil
            self.indexApplyTask = nil
        }
    }

    private func scheduleAutomaticCheckpoint() {
        checkpointTask?.cancel()
        guard automaticCheckpoints, activeExperiment == nil else { return }
        let scheduledVersion = documentVersion
        checkpointTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled, let self,
                  self.documentVersion == scheduledVersion,
                  self.activeExperiment == nil else {
                return
            }
            self.startCheckpoint()
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        guard documentURL != nil else { return }
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self, let url = self.documentURL else { return }
            self.saveDocument(to: url)
        }
    }

    private func cancelCurrentWork() {
        checkpointTask?.cancel()
        modelTask?.cancel()
        autosaveTask?.cancel()
        indexRebuildTask?.cancel()
        indexApplyTask?.cancel()
        indexApplyTask = nil
        activeExperiment = nil
    }

    private var sidecarURL: URL? {
        documentURL?.appendingPathExtension("fum")
    }

    private func appendTrace(_ experiment: ContinuationExperiment) {
        guard persistComparisonTrace else { return }
        guard let directory = sidecarURL,
              let comparison = experiment.comparison else {
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o700],
                ofItemAtPath: directory.path
            )
            let record = ComparisonTraceRecord(
                checkpoint: TraceCheckpointMetadata(experiment.checkpoint),
                completedAt: Date(),
                humanContinuation: experiment.humanContinuation,
                modelContinuation: experiment.modelContinuation,
                comparison: comparison
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var line = try encoder.encode(record)
            line.append(0x0A)
            let traceURL = directory.appendingPathComponent("comparisons.jsonl")
            if FileManager.default.fileExists(atPath: traceURL.path) {
                let handle = try FileHandle(forWritingTo: traceURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: line)
                try handle.close()
            } else {
                try line.write(to: traceURL, options: .atomic)
            }
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: traceURL.path
            )
        } catch {
            errorMessage = "Сравнение готово, но трассу сохранить не удалось: \(error)"
        }
    }
}

private struct ComparisonTraceRecord: Codable {
    let checkpoint: TraceCheckpointMetadata
    let completedAt: Date
    let humanContinuation: Data
    let modelContinuation: Data
    let comparison: ContinuationMetrics
}

private struct TraceCheckpointMetadata: Codable {
    let id: UUID
    let createdAt: Date
    let documentVersion: Int
    let prefixByteCount: Int
    let prefixFingerprint: UInt64
    let modelContextByteCount: Int
    let modelIdentity: String
    let horizonBytes: Int
    let indexConfiguration: SuffixIndexConfiguration

    init(_ checkpoint: ShadowCheckpoint) {
        id = checkpoint.id
        createdAt = checkpoint.createdAt
        documentVersion = checkpoint.documentVersion
        prefixByteCount = checkpoint.prefixByteCount
        prefixFingerprint = checkpoint.prefixFingerprint
        modelContextByteCount = checkpoint.modelContext.count
        modelIdentity = checkpoint.modelIdentity
        horizonBytes = checkpoint.horizonBytes
        indexConfiguration = checkpoint.indexConfiguration
    }
}
