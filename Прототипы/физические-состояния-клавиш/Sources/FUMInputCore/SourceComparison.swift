public enum ApplePlatform: String, Codable, CaseIterable, Hashable, Sendable {
  case macOS
  case iOS
  case iPadOS
  case tvOS
  case visionOS
}

public enum ComparisonTarget: String, Codable, Sendable {
  case macOS
  case portableApple
}

public enum PrimaryTracePolicy: String, Codable, Sendable {
  case stateChangesOnly
}

public enum StateEvidence: String, Codable, Sendable {
  case hidElementValue
  case callbackPressedBoolean
  case queriedAggregateState
  case eventPhaseExceptModifiers
}

public enum DeviceIdentityFidelity: String, Codable, Sendable {
  case perDevice
  case coalesced
  case unavailable
}

public enum SourceLoss: String, Codable, Hashable, Sendable {
  case deviceIdentityCoalesced
  case deviceIdentityUnavailable
  case modifierPhaseIsFlagsChanged
  case aggregateStateAcrossDevices
  case applicationScopeOnly
  case noDedicatedRepeatMarker
  case platformSpecific
}

public struct SourceAssessment: Codable, Equatable, Sendable {
  public let source: InputSourceID
  public let platforms: [ApplePlatform]
  public let stateEvidence: StateEvidence
  public let deviceIdentity: DeviceIdentityFidelity
  public let usesHIDUsage: Bool
  public let distinguishesLeftAndRight: Bool
  public let exposesMonotonicTimestamp: Bool
  public let reportsAutoRepeat: Bool
  public let primaryTracePolicy: PrimaryTracePolicy
  public let losses: [SourceLoss]

  public init(
    source: InputSourceID,
    platforms: [ApplePlatform],
    stateEvidence: StateEvidence,
    deviceIdentity: DeviceIdentityFidelity,
    usesHIDUsage: Bool,
    distinguishesLeftAndRight: Bool,
    exposesMonotonicTimestamp: Bool,
    reportsAutoRepeat: Bool,
    primaryTracePolicy: PrimaryTracePolicy = .stateChangesOnly,
    losses: [SourceLoss]
  ) {
    self.source = source
    self.platforms = platforms
    self.stateEvidence = stateEvidence
    self.deviceIdentity = deviceIdentity
    self.usesHIDUsage = usesHIDUsage
    self.distinguishesLeftAndRight = distinguishesLeftAndRight
    self.exposesMonotonicTimestamp = exposesMonotonicTimestamp
    self.reportsAutoRepeat = reportsAutoRepeat
    self.primaryTracePolicy = primaryTracePolicy
    self.losses = losses
  }

  public var meetsPrimaryKeyboardContract: Bool {
    usesHIDUsage
      && distinguishesLeftAndRight
      && stateEvidence != .eventPhaseExceptModifiers
      && deviceIdentity == .perDevice
  }

  fileprivate var macOSRank: Int {
    var rank = 0
    rank += meetsPrimaryKeyboardContract ? 100 : 0
    rank += stateEvidence == .hidElementValue ? 40 : 0
    rank += deviceIdentity == .perDevice ? 30 : 0
    rank += usesHIDUsage ? 20 : 0
    rank += distinguishesLeftAndRight ? 10 : 0
    rank += exposesMonotonicTimestamp ? 5 : 0
    return rank
  }

  fileprivate var portableRank: Int {
    var rank = platforms.count * 20
    rank += stateEvidence == .callbackPressedBoolean ? 30 : 0
    rank += usesHIDUsage ? 20 : 0
    rank += distinguishesLeftAndRight ? 10 : 0
    return rank
  }
}

public struct SourceRecommendation: Codable, Equatable, Sendable {
  public let primary: InputSourceID
  public let portableFallback: InputSourceID?
  public let diagnostics: [InputSourceID]

  public init(
    primary: InputSourceID,
    portableFallback: InputSourceID?,
    diagnostics: [InputSourceID]
  ) {
    self.primary = primary
    self.portableFallback = portableFallback
    self.diagnostics = diagnostics
  }
}

public struct SourceComparison: Codable, Equatable, Sendable {
  public let assessments: [SourceAssessment]

  public init(assessments: [SourceAssessment]) {
    self.assessments = assessments
  }

  public func assessment(for source: InputSourceID) -> SourceAssessment? {
    assessments.first { $0.source == source }
  }

  public func recommendation(for target: ComparisonTarget) -> SourceRecommendation {
    switch target {
    case .macOS:
      let macCandidates = assessments.filter { $0.platforms.contains(.macOS) }
      let primary =
        macCandidates.max {
          if $0.macOSRank == $1.macOSRank {
            return $0.source.rawValue > $1.source.rawValue
          }
          return $0.macOSRank < $1.macOSRank
        }?.source ?? .ioHIDManager
      let portable =
        macCandidates
        .filter { $0.source != primary && $0.platforms.count > 1 }
        .max { $0.portableRank < $1.portableRank }?
        .source
      let diagnostics =
        macCandidates
        .map(\.source)
        .filter { $0 != primary && $0 != portable }
        .sorted { $0.rawValue < $1.rawValue }
      return .init(
        primary: primary,
        portableFallback: portable,
        diagnostics: diagnostics
      )
    case .portableApple:
      let primary =
        assessments.max {
          if $0.portableRank == $1.portableRank {
            return $0.source.rawValue > $1.source.rawValue
          }
          return $0.portableRank < $1.portableRank
        }?.source ?? .gcKeyboard
      return .init(
        primary: primary,
        portableFallback: nil,
        diagnostics: []
      )
    }
  }

  public static let defaultMatrix = SourceComparison(assessments: [
    .init(
      source: .ioHIDManager,
      platforms: [.macOS],
      stateEvidence: .hidElementValue,
      deviceIdentity: .perDevice,
      usesHIDUsage: true,
      distinguishesLeftAndRight: true,
      exposesMonotonicTimestamp: true,
      reportsAutoRepeat: false,
      losses: [.noDedicatedRepeatMarker, .platformSpecific]
    ),
    .init(
      source: .gcKeyboard,
      platforms: [.macOS, .iOS, .iPadOS, .tvOS, .visionOS],
      stateEvidence: .callbackPressedBoolean,
      deviceIdentity: .coalesced,
      usesHIDUsage: true,
      distinguishesLeftAndRight: true,
      exposesMonotonicTimestamp: false,
      reportsAutoRepeat: false,
      losses: [.deviceIdentityCoalesced, .noDedicatedRepeatMarker]
    ),
    .init(
      source: .cgEventTap,
      platforms: [.macOS],
      stateEvidence: .queriedAggregateState,
      deviceIdentity: .unavailable,
      usesHIDUsage: false,
      distinguishesLeftAndRight: true,
      exposesMonotonicTimestamp: true,
      reportsAutoRepeat: true,
      losses: [.deviceIdentityUnavailable, .aggregateStateAcrossDevices, .platformSpecific]
    ),
    .init(
      source: .nsEvent,
      platforms: [.macOS],
      stateEvidence: .eventPhaseExceptModifiers,
      deviceIdentity: .unavailable,
      usesHIDUsage: false,
      distinguishesLeftAndRight: true,
      exposesMonotonicTimestamp: true,
      reportsAutoRepeat: true,
      losses: [
        .deviceIdentityUnavailable,
        .modifierPhaseIsFlagsChanged,
        .applicationScopeOnly,
        .platformSpecific,
      ]
    ),
    .init(
      source: .uiPresses,
      platforms: [.iOS, .iPadOS, .tvOS, .visionOS],
      stateEvidence: .callbackPressedBoolean,
      deviceIdentity: .unavailable,
      usesHIDUsage: true,
      distinguishesLeftAndRight: true,
      exposesMonotonicTimestamp: true,
      reportsAutoRepeat: false,
      losses: [
        .deviceIdentityUnavailable,
        .applicationScopeOnly,
        .noDedicatedRepeatMarker,
      ]
    ),
  ])
}
