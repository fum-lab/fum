import Foundation
import SwiftUI

enum WorkspaceFocus: String, CaseIterable, Identifiable {
    case organs = "Organs"
    case knowledge = "Knowledge"
    case compose = "Compose"
    case map = "Map"
    case review = "Review"
    case vision = "Vision"
    case camera = "Camera"
    case video = "Video"
    case ship = "Ship"

    var id: String { rawValue }

    static var launchFocus: WorkspaceFocus {
        let arguments = CommandLine.arguments

        for index in arguments.indices {
            let argument = arguments[index]
            if ["--focus", "--mode"].contains(argument), arguments.indices.contains(index + 1) {
                return focus(named: arguments[index + 1]) ?? .compose
            }

            if argument.hasPrefix("--focus=") {
                return focus(named: String(argument.dropFirst("--focus=".count))) ?? .compose
            }

            if argument.hasPrefix("--mode=") {
                return focus(named: String(argument.dropFirst("--mode=".count))) ?? .compose
            }
        }

        return .organs
    }

    private static func focus(named name: String) -> WorkspaceFocus? {
        allCases.first { focus in
            focus.rawValue.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    var title: String {
        rawValue
    }

    var intent: String {
        switch self {
        case .organs:
            "One macOS body for FUM senses, screen, input, gaze, and media."
        case .knowledge:
            "Read the local FUM glossary and axioms without leaving the workspace."
        case .compose:
            "Shape a thought into a next visible action."
        case .map:
            "Keep nearby context spatial enough to return without hunting."
        case .review:
            "Separate observations, interpretations, risks, and decisions."
        case .vision:
            "Realtime map from the AX background reader."
        case .camera:
            "Live camera sight with brightness and motion telemetry."
        case .video:
            "A local screen for recorded memory, demos, and source footage."
        case .ship:
            "Prepare the next external action without hiding its consequence."
        }
    }

    var showsGridControl: Bool {
        self != .organs && self != .knowledge
    }

    var showsSketchControls: Bool {
        switch self {
        case .compose, .map, .review, .ship:
            true
        case .organs, .knowledge, .vision, .camera, .video:
            false
        }
    }

    var symbol: String {
        switch self {
        case .organs: "sensor.tag.radiowaves.forward"
        case .knowledge: "books.vertical"
        case .compose: "sparkles"
        case .map: "point.topleft.down.curvedto.point.bottomright.up"
        case .review: "checklist"
        case .vision: "eye"
        case .camera: "camera.viewfinder"
        case .video: "play.rectangle"
        case .ship: "paperplane"
        }
    }

    var color: Color {
        switch self {
        case .organs: .blue
        case .knowledge: .purple
        case .compose: .cyan
        case .map: .mint
        case .review: .orange
        case .vision: .teal
        case .camera: .indigo
        case .video: .red
        case .ship: .pink
        }
    }
}
