import Darwin
import Foundation

public struct MonotonicTimestampNormalizer: Equatable, Sendable {
  public let machNumerator: UInt32
  public let machDenominator: UInt32

  public init(machNumerator: UInt32, machDenominator: UInt32) {
    precondition(machNumerator > 0, "Числитель шкалы Mach должен быть положительным")
    precondition(machDenominator > 0, "Знаменатель шкалы Mach должен быть положительным")
    self.machNumerator = machNumerator
    self.machDenominator = machDenominator
  }

  public static let system: Self = {
    var timebase = mach_timebase_info_data_t()
    let result = mach_timebase_info(&timebase)
    precondition(result == KERN_SUCCESS, "Не удалось получить шкалу времени Mach")
    return Self(
      machNumerator: timebase.numer,
      machDenominator: timebase.denom
    )
  }()

  public func nanoseconds(fromMachAbsoluteTime ticks: UInt64) -> UInt64? {
    let product = ticks.multipliedFullWidth(by: UInt64(machNumerator))
    let divisor = UInt64(machDenominator)
    guard product.high < divisor else {
      return nil
    }
    return divisor.dividingFullWidth(product).quotient
  }

  public func nanoseconds(fromNanosecondsSinceStartup nanoseconds: UInt64) -> UInt64 {
    nanoseconds
  }

  public func nanoseconds(fromSecondsSinceStartup seconds: TimeInterval) -> UInt64? {
    guard seconds.isFinite, seconds >= 0 else {
      return nil
    }
    let nanoseconds = seconds * 1_000_000_000
    guard nanoseconds.isFinite, nanoseconds < Double(UInt64.max) else {
      return nil
    }
    return UInt64(nanoseconds.rounded(.towardZero))
  }
}
