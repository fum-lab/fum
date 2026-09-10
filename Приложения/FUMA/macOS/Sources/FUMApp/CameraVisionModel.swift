#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import AppKit
import AVFoundation
import CoreGraphics
import Foundation
import Vision

final class CameraVisionModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published var authorizationStatus: AVAuthorizationStatus = FUMFeatureFlags.cameraEnabled ? AVCaptureDevice.authorizationStatus(for: .video) : .restricted
    @Published var isRunning = false
    @Published var statusText = FUMFeatureFlags.cameraEnabled ? "Camera idle" : "Camera disabled"
    @Published var brightness: Double = 0
    @Published var motion: Double = 0
    @Published var frameSize = CGSize.zero
    @Published var gazeSample: CameraGazeSample?
    @Published var gazeStatus = FUMFeatureFlags.cameraEnabled ? "Gaze idle" : "Gaze disabled"
    @Published var gazeCalibrationProgress: Double = 0
    @Published var isGazeCursorEnabled = false
    @Published var faceRecognition = FUMFeatureFlags.cameraEnabled ? CameraFaceRecognitionSnapshot.empty : .disabled

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "fum.camera.session")
    private let sampleQueue = DispatchQueue(label: "fum.camera.samples")
    private var isConfigured = false
    private var previousBrightness: Double?
    private let gazeEstimator = CameraGazeEstimator()
    private let gazeCursor = GazeCursorController()
    private let faceRecognizer = CameraFaceRecognizer()
    private let cameraRequestFlagKey = "fum.camera.requested"
    private let faceRecognitionInterval: TimeInterval = 0.46
    private var lastFaceRecognitionTime = Date.distantPast
    private var lastEnrollmentFeaturePrintData: Data?

    var canPreview: Bool {
        FUMFeatureFlags.cameraEnabled && authorizationStatus == .authorized
    }

    var statusLabel: String {
        guard FUMFeatureFlags.cameraEnabled else {
            return "Camera Off"
        }

        switch authorizationStatus {
        case .authorized:
            return isRunning ? "Live Camera" : statusText
        case .notDetermined:
            return "Camera Permission Needed"
        case .denied, .restricted:
            return "Camera Blocked"
        @unknown default:
            return "Camera Unknown"
        }
    }

    func start() {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            startAuthorizedSession()
        case .notDetermined:
            if UserDefaults.standard.bool(forKey: cameraRequestFlagKey) {
                statusText = "Camera permission has not been granted"
            } else {
                requestCameraAccess()
            }
        case .denied, .restricted:
            statusText = "Enable camera access in System Settings"
        @unknown default:
            statusText = "Unsupported camera authorization state"
        }
    }

    func requestCameraAccess() {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            startAuthorizedSession()
        case .notDetermined:
            UserDefaults.standard.set(true, forKey: cameraRequestFlagKey)
            statusText = "Requesting camera access"
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    self?.statusText = granted ? "Starting camera" : "Camera access denied"
                    if granted {
                        self?.startAuthorizedSession()
                    }
                }
            }
        case .denied, .restricted:
            statusText = "Enable camera access in System Settings"
            openCameraSettings()
        @unknown default:
            statusText = "Unsupported camera authorization state"
        }
    }

    func stop() {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if session.isRunning {
                session.stopRunning()
            }
            DispatchQueue.main.async {
                self.isRunning = false
                self.statusText = "Camera stopped"
            }
        }
    }

    func openCameraSettings() {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func refreshAuthorizationStatus() {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            statusText = isRunning ? "Receiving camera frames" : "Camera access granted"
        case .notDetermined:
            statusText = "Camera permission has not been requested"
        case .denied, .restricted:
            statusText = "Enable camera access in System Settings"
        @unknown default:
            statusText = "Unsupported camera authorization state"
        }
    }

    func setGazeCursorEnabled(_ enabled: Bool) {
        guard FUMFeatureFlags.cameraEnabled else {
            markCameraDisabled()
            return
        }

        gazeCursor.setEnabled(enabled)
        isGazeCursorEnabled = gazeCursor.isEnabled
        gazeStatus = gazeCursor.status
    }

    func refreshKnownPeople() {
        guard FUMFeatureFlags.cameraEnabled else {
            faceRecognition = .disabled
            return
        }

        faceRecognition = faceRecognizer.currentSnapshot(status: "Face memory refreshed")
    }

    @discardableResult
    func enrollVisibleFace(named rawName: String) -> Bool {
        guard FUMFeatureFlags.cameraEnabled else {
            faceRecognition = .disabled
            return false
        }

        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            faceRecognition = faceRecognizer.currentSnapshot(status: "Name is required")
            return false
        }

        guard let featurePrintData = lastEnrollmentFeaturePrintData else {
            faceRecognition = faceRecognizer.currentSnapshot(status: "No visible face to enroll")
            return false
        }

        faceRecognition = faceRecognizer.enroll(name: name, featurePrintData: featurePrintData)
        return true
    }

    func forgetKnownPerson(id: UUID) {
        faceRecognition = faceRecognizer.removePerson(id: id)
    }

    private func markCameraDisabled() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }

        gazeCursor.setEnabled(false)
        authorizationStatus = .restricted
        isRunning = false
        statusText = "Camera disabled"
        brightness = 0
        motion = 0
        frameSize = .zero
        gazeSample = nil
        gazeStatus = "Gaze disabled"
        gazeCalibrationProgress = 0
        isGazeCursorEnabled = false
        faceRecognition = .disabled
        lastEnrollmentFeaturePrintData = nil
    }

    private func startAuthorizedSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                if !isConfigured {
                    try configureSession()
                }
                if !session.isRunning {
                    session.startRunning()
                }
                DispatchQueue.main.async {
                    self.isRunning = true
                    self.statusText = "Receiving camera frames"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.statusText = error.localizedDescription
                }
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(for: .video) else {
            throw CameraVisionError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraVisionError.cannotAddInput
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sampleQueue)

        guard session.canAddOutput(output) else {
            throw CameraVisionError.cannotAddOutput
        }
        session.addOutput(output)
        isConfigured = true
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let currentBrightness: Double

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        if let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let data = baseAddress.assumingMemoryBound(to: UInt8.self)
            let stepX = max(1, width / 48)
            let stepY = max(1, height / 32)
            var total: Double = 0
            var count: Double = 0

            for y in stride(from: 0, to: height, by: stepY) {
                for x in stride(from: 0, to: width, by: stepX) {
                    let offset = y * bytesPerRow + x * 4
                    let blue = Double(data[offset])
                    let green = Double(data[offset + 1])
                    let red = Double(data[offset + 2])
                    total += (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                    count += 1
                }
            }
            currentBrightness = count > 0 ? total / count : 0
        } else {
            currentBrightness = 0
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        let delta = abs(currentBrightness - (previousBrightness ?? currentBrightness))
        previousBrightness = currentBrightness

        DispatchQueue.main.async {
            self.frameSize = CGSize(width: width, height: height)
            self.brightness = self.brightness * 0.82 + currentBrightness * 0.18
            self.motion = self.motion * 0.76 + min(1, delta * 18) * 0.24
        }

        if let gazeSample = gazeEstimator.estimate(from: imageBuffer) {
            DispatchQueue.main.async {
                self.gazeSample = gazeSample
                self.gazeStatus = gazeSample.confidence > 0.24 ? "Gaze tracked" : "Gaze low confidence"
                self.gazeCursor.update(sample: gazeSample, screenFrame: CGDisplayBounds(CGMainDisplayID()))
                self.isGazeCursorEnabled = self.gazeCursor.isEnabled
                self.gazeCalibrationProgress = self.gazeCursor.calibrationProgress
                if self.gazeCursor.isEnabled {
                    self.gazeStatus = self.gazeCursor.status
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.gazeSample == nil {
                    self.gazeStatus = "Waiting for eyes"
                }
            }
        }

        updateFaceRecognition(from: imageBuffer)
    }

    private func updateFaceRecognition(from imageBuffer: CVPixelBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastFaceRecognitionTime) >= faceRecognitionInterval else {
            return
        }
        lastFaceRecognitionTime = now

        let result = faceRecognizer.recognize(in: imageBuffer)
        DispatchQueue.main.async {
            self.faceRecognition = result.snapshot
            self.lastEnrollmentFeaturePrintData = result.enrollmentFeaturePrintData
        }
    }
}

struct CameraFaceRecognitionSnapshot: Equatable {
    let status: String
    let knownPeople: [KnownCameraPerson]
    let visibleFaces: [RecognizedCameraFace]
    let enrollmentCandidateAvailable: Bool
    let lastUpdated: Date?

    static let empty = CameraFaceRecognitionSnapshot(
        status: "Face memory idle",
        knownPeople: [],
        visibleFaces: [],
        enrollmentCandidateAvailable: false,
        lastUpdated: nil
    )

    static let disabled = CameraFaceRecognitionSnapshot(
        status: "Face memory disabled",
        knownPeople: [],
        visibleFaces: [],
        enrollmentCandidateAvailable: false,
        lastUpdated: nil
    )

    var visibleSummary: String {
        guard !visibleFaces.isEmpty else {
            return "no visible faces"
        }

        return visibleFaces
            .map(\.displayName)
            .joined(separator: ", ")
    }
}

struct KnownCameraPerson: Identifiable, Equatable {
    let id: UUID
    let name: String
    let sampleCount: Int
    let updatedAt: Date
    let lastSeenAt: Date?
}

struct RecognizedCameraFace: Identifiable, Equatable {
    let id: String
    let personID: UUID?
    let name: String?
    let boundingBox: CGRect
    let distance: Float?
    let confidence: Double

    var isKnown: Bool {
        personID != nil
    }

    var displayName: String {
        name ?? "Unknown"
    }

    var scoreLabel: String {
        guard let distance else {
            return "new"
        }
        return String(format: "%.2f", distance)
    }
}

private struct CameraFaceRecognitionResult {
    let snapshot: CameraFaceRecognitionSnapshot
    let enrollmentFeaturePrintData: Data?
}

private final class CameraFaceRecognizer {
    private struct StoreFile: Codable {
        var people: [PersonRecord]
    }

    private struct PersonRecord: Codable {
        var id: UUID
        var name: String
        var featurePrints: [Data]
        var createdAt: Date
        var updatedAt: Date
        var lastSeenAt: Date?
    }

    private struct Match {
        let id: UUID
        let name: String
        let distance: Float
    }

    private let storeURL = URL(fileURLWithPath: ПутиПриложения.текущие.оперативныеДанные.appendingPathComponent("camera/known-people.json").path)
    private let lock = NSLock()
    private let matchThreshold: Float = 0.50
    private let maxSamplesPerPerson = 8
    private var records: [PersonRecord] = []

    init() {
        records = loadRecords()
    }

    func currentSnapshot(status: String) -> CameraFaceRecognitionSnapshot {
        CameraFaceRecognitionSnapshot(
            status: status,
            knownPeople: publicPeople(),
            visibleFaces: [],
            enrollmentCandidateAvailable: false,
            lastUpdated: Date()
        )
    }

    func enroll(name: String, featurePrintData: Data) -> CameraFaceRecognitionSnapshot {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if let index = records.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            records[index].featurePrints.append(featurePrintData)
            if records[index].featurePrints.count > maxSamplesPerPerson {
                records[index].featurePrints.removeFirst(records[index].featurePrints.count - maxSamplesPerPerson)
            }
            records[index].updatedAt = now
            records[index].lastSeenAt = now
        } else {
            records.append(PersonRecord(
                id: UUID(),
                name: name,
                featurePrints: [featurePrintData],
                createdAt: now,
                updatedAt: now,
                lastSeenAt: now
            ))
        }

        saveRecords(records)
        return snapshotLocked(status: "Enrolled \(name)", visibleFaces: [], candidate: false)
    }

    func removePerson(id: UUID) -> CameraFaceRecognitionSnapshot {
        lock.lock()
        defer { lock.unlock() }

        let removed = records.first(where: { $0.id == id })?.name ?? "person"
        records.removeAll { $0.id == id }
        saveRecords(records)
        return snapshotLocked(status: "Forgot \(removed)", visibleFaces: [], candidate: false)
    }

    func recognize(in pixelBuffer: CVPixelBuffer) -> CameraFaceRecognitionResult {
        let faces = detectFaces(in: pixelBuffer)
        guard !faces.isEmpty else {
            return CameraFaceRecognitionResult(
                snapshot: CameraFaceRecognitionSnapshot(
                    status: publicPeople().isEmpty ? "Enroll a visible face" : "No face in view",
                    knownPeople: publicPeople(),
                    visibleFaces: [],
                    enrollmentCandidateAvailable: false,
                    lastUpdated: Date()
                ),
                enrollmentFeaturePrintData: nil
            )
        }

        var visibleFaces: [RecognizedCameraFace] = []
        var enrollmentCandidate: Data?

        for (index, face) in faces.prefix(5).enumerated() {
            guard let featurePrint = featurePrint(in: pixelBuffer, faceBox: face.boundingBox) else {
                continue
            }

            let archivedFeaturePrint = archive(featurePrint)
            if enrollmentCandidate == nil {
                enrollmentCandidate = archivedFeaturePrint
            }

            let match = bestMatch(for: featurePrint)
            let acceptedMatch = match.flatMap { $0.distance <= matchThreshold ? $0 : nil }
            if let acceptedMatch {
                markSeen(id: acceptedMatch.id)
            }

            let confidence = acceptedMatch.map { matchConfidence(distance: $0.distance) } ?? 0
            visibleFaces.append(RecognizedCameraFace(
                id: "\(index)-\(Int(face.boundingBox.minX * 1000))-\(Int(face.boundingBox.minY * 1000))",
                personID: acceptedMatch?.id,
                name: acceptedMatch?.name,
                boundingBox: face.boundingBox,
                distance: match?.distance,
                confidence: confidence
            ))
        }

        let status: String
        if visibleFaces.isEmpty {
            status = "Face detected, no print"
        } else if visibleFaces.contains(where: \.isKnown) {
            status = visibleFaces.map(\.displayName).joined(separator: ", ")
        } else {
            status = "Unknown face"
        }

        return CameraFaceRecognitionResult(
            snapshot: CameraFaceRecognitionSnapshot(
                status: status,
                knownPeople: publicPeople(),
                visibleFaces: visibleFaces,
                enrollmentCandidateAvailable: enrollmentCandidate != nil,
                lastUpdated: Date()
            ),
            enrollmentFeaturePrintData: enrollmentCandidate
        )
    }

    private func detectFaces(in pixelBuffer: CVPixelBuffer) -> [VNFaceObservation] {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        return (request.results ?? [])
            .filter { $0.confidence >= 0.45 }
            .sorted { $0.boundingBox.width * $0.boundingBox.height > $1.boundingBox.width * $1.boundingBox.height }
    }

    private func featurePrint(in pixelBuffer: CVPixelBuffer, faceBox: CGRect) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        request.revision = VNGenerateImageFeaturePrintRequestRevision2
        request.regionOfInterest = expandedFaceRegion(faceBox)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            return nil
        }
    }

    private func bestMatch(for featurePrint: VNFeaturePrintObservation) -> Match? {
        lock.lock()
        let localRecords = records
        lock.unlock()

        var best: Match?
        for record in localRecords {
            for storedData in record.featurePrints {
                guard let storedPrint = unarchive(storedData) else {
                    continue
                }

                var distance: Float = .greatestFiniteMagnitude
                do {
                    try featurePrint.computeDistance(&distance, to: storedPrint)
                } catch {
                    continue
                }

                if best == nil || distance < (best?.distance ?? .greatestFiniteMagnitude) {
                    best = Match(id: record.id, name: record.name, distance: distance)
                }
            }
        }
        return best
    }

    private func markSeen(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return
        }
        records[index].lastSeenAt = Date()
    }

    private func publicPeople() -> [KnownCameraPerson] {
        lock.lock()
        defer { lock.unlock() }
        return records
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map {
                KnownCameraPerson(
                    id: $0.id,
                    name: $0.name,
                    sampleCount: $0.featurePrints.count,
                    updatedAt: $0.updatedAt,
                    lastSeenAt: $0.lastSeenAt
                )
            }
    }

    private func snapshotLocked(
        status: String,
        visibleFaces: [RecognizedCameraFace],
        candidate: Bool
    ) -> CameraFaceRecognitionSnapshot {
        CameraFaceRecognitionSnapshot(
            status: status,
            knownPeople: records
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .map {
                    KnownCameraPerson(
                        id: $0.id,
                        name: $0.name,
                        sampleCount: $0.featurePrints.count,
                        updatedAt: $0.updatedAt,
                        lastSeenAt: $0.lastSeenAt
                    )
                },
            visibleFaces: visibleFaces,
            enrollmentCandidateAvailable: candidate,
            lastUpdated: Date()
        )
    }

    private func loadRecords() -> [PersonRecord] {
        guard let data = try? Data(contentsOf: storeURL) else {
            return []
        }

        do {
            return try JSONDecoder().decode(StoreFile.self, from: data).people
        } catch {
            return []
        }
    }

    private func saveRecords(_ records: [PersonRecord]) {
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(StoreFile(people: records))
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            assertionFailure("Could not save camera face memory: \(error)")
        }
    }

    private func archive(_ featurePrint: VNFeaturePrintObservation) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: featurePrint, requiringSecureCoding: true)
    }

    private func unarchive(_ data: Data) -> VNFeaturePrintObservation? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data)
    }

    private func expandedFaceRegion(_ box: CGRect) -> CGRect {
        let expanded = box.insetBy(dx: -box.width * 0.28, dy: -box.height * 0.36)
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        let clipped = expanded.intersection(unit)
        guard clipped.width > 0.04, clipped.height > 0.04 else {
            return box.intersection(unit)
        }
        return clipped
    }

    private func matchConfidence(distance: Float) -> Double {
        let normalized = 1.0 - Double(distance / matchThreshold)
        return min(max(normalized, 0), 1)
    }
}

enum CameraVisionError: LocalizedError {
    case noCamera
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noCamera:
            return "No camera was found."
        case .cannotAddInput:
            return "Camera input could not be attached."
        case .cannotAddOutput:
            return "Camera frame output could not be attached."
        }
    }
}
