import Testing

@testable import FUMInputCore

@Suite("Сравнение источников клавиатуры")
struct SourceComparisonTests {
  @Test("на macOS первичным источником выбирается IOHIDManager")
  func recommendsIOHIDOnMacOS() {
    let recommendation = SourceComparison.defaultMatrix.recommendation(for: .macOS)

    #expect(recommendation.primary == .ioHIDManager)
    #expect(recommendation.portableFallback == .gcKeyboard)
    #expect(recommendation.diagnostics.contains(.cgEventTap))
    #expect(recommendation.diagnostics.contains(.nsEvent))
  }

  @Test("для переносимого слоя Apple выбирается GCKeyboard")
  func recommendsGCKeyboardForPortableAppleLayer() {
    let recommendation = SourceComparison.defaultMatrix.recommendation(for: .portableApple)

    #expect(recommendation.primary == .gcKeyboard)
    #expect(recommendation.portableFallback == nil)
  }

  @Test("NSEvent не проходит жёсткий контракт физических фаз модификаторов")
  func rejectsNSEventAsPrimary() {
    let assessment = SourceComparison.defaultMatrix.assessment(for: .nsEvent)

    #expect(assessment?.meetsPrimaryKeyboardContract == false)
    #expect(assessment?.losses.contains(.modifierPhaseIsFlagsChanged) == true)
    #expect(assessment?.losses.contains(.deviceIdentityUnavailable) == true)
  }

  @Test("автоповтор нигде не считается физическим переходом")
  func allCandidatesExcludeAutoRepeatFromPrimaryTrace() {
    for assessment in SourceComparison.defaultMatrix.assessments {
      #expect(assessment.primaryTracePolicy == .stateChangesOnly)
    }
  }
}
