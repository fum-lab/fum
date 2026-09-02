import Foundation
import Testing

@testable import FUMInputMac

@Suite("Единая шкала монотонного времени")
struct MonotonicTimestampNormalizerTests {
  @Test("тики Mach преобразуются с коэффициентом, отличным от единицы")
  func convertsNonUnitMachTimebase() {
    let normalizer = MonotonicTimestampNormalizer(
      machNumerator: 125,
      machDenominator: 3
    )

    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: 1) == 41)
    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: 2) == 83)
    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: 3) == 125)
    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: 240) == 10_000)
  }

  @Test("преобразование Mach не переполняет промежуточное произведение")
  func avoidsIntermediateOverflow() {
    let normalizer = MonotonicTimestampNormalizer(
      machNumerator: 2,
      machDenominator: 2
    )

    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: .max) == .max)

    let nonUnitNormalizer = MonotonicTimestampNormalizer(
      machNumerator: 3,
      machDenominator: 2
    )
    #expect(
      nonUnitNormalizer.nanoseconds(fromMachAbsoluteTime: 0xAAAA_AAAA_AAAA_AAAA)
        == .max
    )
  }

  @Test("непредставимый результат Mach отклоняется без аварии")
  func rejectsResultOverflow() {
    let normalizer = MonotonicTimestampNormalizer(
      machNumerator: 2,
      machDenominator: 1
    )

    #expect(normalizer.nanoseconds(fromMachAbsoluteTime: .max) == nil)

    let nonUnitNormalizer = MonotonicTimestampNormalizer(
      machNumerator: 3,
      machDenominator: 2
    )
    #expect(
      nonUnitNormalizer.nanoseconds(fromMachAbsoluteTime: 0xAAAA_AAAA_AAAA_AAAB)
        == nil
    )
  }

  @Test("источники сводятся к одной наносекундной шкале")
  func alignsSourceTimestampDomains() {
    let normalizer = MonotonicTimestampNormalizer(
      machNumerator: 125,
      machDenominator: 3
    )
    let fromIOHID = IOHIDKeyboardSource.normalizedTimestamp(
      fromAbsoluteTime: 240_000,
      using: normalizer
    )
    let fromCGEvent = CGEventTapKeyboardSource.normalizedTimestamp(
      fromNanosecondsSinceStartup: 10_000_000,
      using: normalizer
    )
    let fromNSEvent = NSEventKeyboardSource.normalizedTimestamp(
      fromSecondsSinceStartup: 0.01,
      using: normalizer
    )
    let fromGCKeyboard = GCKeyboardSource.normalizedTimestamp(
      fromNanosecondsSinceStartup: 10_000_000,
      using: normalizer
    )

    #expect(fromIOHID == 10_000_000)
    #expect(fromCGEvent == 10_000_000)
    #expect(fromNSEvent == 10_000_000)
    #expect(fromGCKeyboard == 10_000_000)

    let overflowingNormalizer = MonotonicTimestampNormalizer(
      machNumerator: 2,
      machDenominator: 1
    )
    #expect(
      IOHIDKeyboardSource.normalizedTimestamp(
        fromAbsoluteTime: .max,
        using: overflowingNormalizer
      ) == nil
    )
  }

  @Test("некорректные секунды не превращаются в метку времени")
  func rejectsInvalidSeconds() {
    let normalizer = MonotonicTimestampNormalizer(
      machNumerator: 1,
      machDenominator: 1
    )

    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: .nan) == nil)
    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: -.infinity) == nil)
    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: .infinity) == nil)
    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: -.leastNonzeroMagnitude) == nil)
    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: 0) == 0)
    #expect(normalizer.nanoseconds(fromSecondsSinceStartup: .leastNonzeroMagnitude) == 0)
  }
}
