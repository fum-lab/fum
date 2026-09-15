import AppKit
import CoreGraphics
import Foundation
import Vision

struct CameraGazeSample: Equatable {
    let x: Double
    let y: Double
    let confidence: Double

    var screenNormalizedPoint: CGPoint {
        CGPoint(x: min(max(x, 0.02), 0.98), y: min(max(y, 0.02), 0.98))
    }
}

final class CameraGazeEstimator {
    private var lastVisionTime = Date.distantPast

    func estimate(from pixelBuffer: CVPixelBuffer) -> CameraGazeSample? {
        guard Date().timeIntervalSince(lastVisionTime) > 0.055 else {
            return nil
        }
        lastVisionTime = Date()

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])

        guard
            let faces = request.results,
            let face = faces.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
        else {
            return nil
        }

        return estimate(face: face, pixelBuffer: pixelBuffer)
    }

    private func estimate(face: VNFaceObservation, pixelBuffer: CVPixelBuffer) -> CameraGazeSample? {
        guard
            let landmarks = face.landmarks,
            let leftEye = landmarks.leftEye,
            let rightEye = landmarks.rightEye
        else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard width > 0, height > 0 else {
            return nil
        }

        guard
            let left = eyeOffset(eye: leftEye, face: face.boundingBox, pixelBuffer: pixelBuffer, width: width, height: height),
            let right = eyeOffset(eye: rightEye, face: face.boundingBox, pixelBuffer: pixelBuffer, width: width, height: height)
        else {
            return nil
        }

        let horizontal = (left.x + right.x) / 2
        let vertical = (left.y + right.y) / 2
        let yaw = face.yaw?.doubleValue ?? 0
        let roll = face.roll?.doubleValue ?? 0

        return CameraGazeSample(
            x: min(max(0.5 + horizontal * 1.45 + yaw * 0.10, 0), 1),
            y: min(max(0.5 + vertical * 1.35 + roll * 0.04, 0), 1),
            confidence: min(left.confidence, right.confidence)
        )
    }

    private func eyeOffset(
        eye: VNFaceLandmarkRegion2D,
        face: CGRect,
        pixelBuffer: CVPixelBuffer,
        width: Int,
        height: Int
    ) -> (x: Double, y: Double, confidence: Double)? {
        let points = eye.normalizedPoints.map { point -> CGPoint in
            let normalizedX = face.minX + CGFloat(point.x) * face.width
            let normalizedY = face.minY + CGFloat(point.y) * face.height
            return CGPoint(x: normalizedX * CGFloat(width), y: (1 - normalizedY) * CGFloat(height))
        }

        guard
            let minX = points.map(\.x).min(),
            let maxX = points.map(\.x).max(),
            let minY = points.map(\.y).min(),
            let maxY = points.map(\.y).max()
        else {
            return nil
        }

        let eyeWidth = max(maxX - minX, 8)
        let eyeHeight = max(maxY - minY, 4)
        let rect = CGRect(
            x: minX - eyeWidth * 0.18,
            y: minY - eyeHeight * 0.55,
            width: eyeWidth * 1.36,
            height: eyeHeight * 2.1
        ).intersection(CGRect(x: 0, y: 0, width: width, height: height))

        guard
            rect.width >= 8,
            rect.height >= 6,
            let pupil = darkestPoint(in: rect, pixelBuffer: pixelBuffer, imageWidth: width, imageHeight: height)
        else {
            return nil
        }

        let confidence = min(max((pupil.contrast - 12) / 42, 0.15), 1.0)
        return (
            Double((pupil.point.x - rect.midX) / rect.width),
            Double((pupil.point.y - rect.midY) / rect.height),
            confidence
        )
    }

    private func darkestPoint(
        in rect: CGRect,
        pixelBuffer: CVPixelBuffer,
        imageWidth: Int,
        imageHeight: Int
    ) -> (point: CGPoint, contrast: Double)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let data = base.assumingMemoryBound(to: UInt8.self)
        let startX = max(Int(rect.minX), 0)
        let endX = min(Int(rect.maxX), imageWidth - 1)
        let startY = max(Int(rect.minY), 0)
        let endY = min(Int(rect.maxY), imageHeight - 1)
        var luminances: [Double] = []

        for y in stride(from: startY, through: endY, by: 2) {
            for x in stride(from: startX, through: endX, by: 2) {
                let offset = y * bytesPerRow + x * 4
                let blue = Double(data[offset])
                let green = Double(data[offset + 1])
                let red = Double(data[offset + 2])
                luminances.append(0.2126 * red + 0.7152 * green + 0.0722 * blue)
            }
        }

        guard !luminances.isEmpty else {
            return nil
        }

        let sorted = luminances.sorted()
        let darkThreshold = sorted[max(0, min(sorted.count - 1, sorted.count / 7))]
        let brightReference = sorted[max(0, min(sorted.count - 1, sorted.count * 4 / 5))]
        var weightedX = 0.0
        var weightedY = 0.0
        var totalWeight = 0.0

        for y in stride(from: startY, through: endY, by: 2) {
            for x in stride(from: startX, through: endX, by: 2) {
                let offset = y * bytesPerRow + x * 4
                let blue = Double(data[offset])
                let green = Double(data[offset + 1])
                let red = Double(data[offset + 2])
                let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
                guard luminance <= darkThreshold else {
                    continue
                }

                let dx = (Double(x) - Double(rect.midX)) / max(Double(rect.width), 1)
                let dy = (Double(y) - Double(rect.midY)) / max(Double(rect.height), 1)
                let centerPenalty = min(dx * dx + dy * dy, 0.45)
                let weight = max((darkThreshold - luminance) + 6, 0.1) * (1 - centerPenalty)
                weightedX += Double(x) * weight
                weightedY += Double(y) * weight
                totalWeight += weight
            }
        }

        guard totalWeight > 0 else {
            return nil
        }

        return (
            CGPoint(x: weightedX / totalWeight, y: weightedY / totalWeight),
            max(brightReference - darkThreshold, 0)
        )
    }
}

final class GazeCursorController {
    var isEnabled = false
    var status = "Gaze cursor idle"
    var calibrationProgress: Double {
        calibration.confidence
    }

    private var lastPoint: CGPoint?
    private let calibration = CursorGazeCalibration()
    private let smoothing: CGFloat = 0.68
    private let deadzone: CGFloat = 18

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard AXIsProcessTrusted() else {
                isEnabled = false
                status = "Accessibility permission needed"
                return
            }
            isEnabled = true
            lastPoint = currentCursorLocation()
            status = "Cursor priority, calibrating gaze"
        } else {
            isEnabled = false
            lastPoint = nil
            status = "Gaze cursor paused"
        }
    }

    func update(sample: CameraGazeSample, screenFrame: CGRect) {
        guard sample.confidence > 0.24 else {
            return
        }

        if let cursor = currentCursorLocation() {
            calibration.observe(sample: sample, cursorPoint: cursor, screenFrame: screenFrame)
        }

        guard isEnabled else {
            status = calibration.confidence > 0 ? "Auto-calibrating from cursor" : "Gaze tracked"
            return
        }

        let gazeTarget = calibration.map(sample: sample, screenFrame: screenFrame)
        let current = currentCursorLocation() ?? lastPoint ?? gazeTarget
        let gazeWeight = CGFloat(0.12 + calibration.confidence * 0.78)
        var target = CGPoint(
            x: current.x * (1 - gazeWeight) + gazeTarget.x * gazeWeight,
            y: current.y * (1 - gazeWeight) + gazeTarget.y * gazeWeight
        )

        if let previous = lastPoint {
            target = CGPoint(
                x: previous.x * smoothing + target.x * (1 - smoothing),
                y: previous.y * smoothing + target.y * (1 - smoothing)
            )

            guard hypot(target.x - previous.x, target.y - previous.y) >= deadzone else {
                return
            }
        }

        lastPoint = target
        CGWarpMouseCursorPosition(target)
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        status = calibration.confidence < 0.45
            ? "Cursor priority, calibrating gaze"
            : "Gaze cursor active"
    }

    private func currentCursorLocation() -> CGPoint? {
        CGEvent(source: nil)?.location
    }
}

private final class CursorGazeCalibration {
    private struct Observation {
        let gazeX: Double
        let gazeY: Double
        let cursorX: Double
        let cursorY: Double
        let weight: Double
    }

    private var observations: [Observation] = []
    private var xCoefficients: [Double]?
    private var yCoefficients: [Double]?
    private let maximumObservations = 90

    var confidence: Double {
        guard xCoefficients != nil, yCoefficients != nil else {
            return 0
        }
        return min(1, Double(max(0, observations.count - 3)) / 34)
    }

    func observe(sample: CameraGazeSample, cursorPoint: CGPoint, screenFrame: CGRect) {
        guard screenFrame.width > 0, screenFrame.height > 0 else {
            return
        }

        let normalizedCursorX = Double((cursorPoint.x - screenFrame.minX) / screenFrame.width)
        let normalizedCursorY = Double((cursorPoint.y - screenFrame.minY) / screenFrame.height)
        guard (0...1).contains(normalizedCursorX), (0...1).contains(normalizedCursorY) else {
            return
        }

        let last = observations.last
        let movedEnough = last.map { previous in
            hypot(previous.cursorX - normalizedCursorX, previous.cursorY - normalizedCursorY) > 0.015 ||
                hypot(previous.gazeX - sample.x, previous.gazeY - sample.y) > 0.018
        } ?? true
        guard movedEnough else {
            return
        }

        observations.append(Observation(
            gazeX: sample.x,
            gazeY: sample.y,
            cursorX: normalizedCursorX,
            cursorY: normalizedCursorY,
            weight: min(max(sample.confidence, 0.25), 1.0)
        ))

        if observations.count > maximumObservations {
            observations.removeFirst(observations.count - maximumObservations)
        }

        refit()
    }

    func map(sample: CameraGazeSample, screenFrame: CGRect) -> CGPoint {
        let normalized: CGPoint
        if let xCoefficients, let yCoefficients {
            normalized = CGPoint(
                x: evaluate(xCoefficients, sample: sample),
                y: evaluate(yCoefficients, sample: sample)
            )
        } else {
            normalized = sample.screenNormalizedPoint
        }

        let clamped = CGPoint(
            x: min(max(normalized.x, 0.02), 0.98),
            y: min(max(normalized.y, 0.02), 0.98)
        )
        return CGPoint(
            x: screenFrame.minX + clamped.x * screenFrame.width,
            y: screenFrame.minY + clamped.y * screenFrame.height
        )
    }

    private func refit() {
        guard observations.count >= 4 else {
            return
        }

        let rows = observations.map { observation in
            [1.0, observation.gazeX, observation.gazeY, observation.weight]
        }
        let cursorX = observations.map(\.cursorX)
        let cursorY = observations.map(\.cursorY)

        xCoefficients = solveLeastSquares(rows: rows, values: cursorX)
        yCoefficients = solveLeastSquares(rows: rows, values: cursorY)
    }

    private func evaluate(_ coefficients: [Double], sample: CameraGazeSample) -> CGFloat {
        CGFloat(coefficients[0] + coefficients[1] * sample.x + coefficients[2] * sample.y + coefficients[3] * sample.confidence)
    }

    private func solveLeastSquares(rows: [[Double]], values: [Double]) -> [Double]? {
        let width = 4
        var normal = Array(repeating: Array(repeating: 0.0, count: width), count: width)
        var rhs = Array(repeating: 0.0, count: width)

        for (row, value) in zip(rows, values) {
            for i in 0..<width {
                rhs[i] += row[i] * value
                for j in 0..<width {
                    normal[i][j] += row[i] * row[j]
                }
            }
        }

        return solveLinearSystem(matrix: normal, rhs: rhs)
    }

    private func solveLinearSystem(matrix: [[Double]], rhs: [Double]) -> [Double]? {
        var augmented = matrix.enumerated().map { index, row in
            row + [rhs[index]]
        }
        let width = rhs.count

        for column in 0..<width {
            var pivot = column
            for row in column..<width where abs(augmented[row][column]) > abs(augmented[pivot][column]) {
                pivot = row
            }
            guard abs(augmented[pivot][column]) > 0.000001 else {
                return nil
            }
            if pivot != column {
                augmented.swapAt(pivot, column)
            }

            let divisor = augmented[column][column]
            for index in column...width {
                augmented[column][index] /= divisor
            }

            for row in 0..<width where row != column {
                let factor = augmented[row][column]
                for index in column...width {
                    augmented[row][index] -= factor * augmented[column][index]
                }
            }
        }

        return (0..<width).map { augmented[$0][width] }
    }
}
