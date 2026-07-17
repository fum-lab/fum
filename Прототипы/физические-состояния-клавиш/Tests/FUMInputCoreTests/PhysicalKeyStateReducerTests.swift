import Foundation
import Testing

@testable import FUMInputCore

@Suite("Физическое состояние клавиш")
struct PhysicalKeyStateReducerTests {
  @Test("явные нажатие и отпускание образуют два перехода")
  func acceptsExplicitDownAndUp() {
    var reducer = PhysicalKeyStateReducer()
    let key = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0xE3)

    let down = reducer.consume(
      .init(
        source: .ioHIDManager,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))
    let up = reducer.consume(
      .init(
        source: .ioHIDManager,
        key: key,
        state: .released,
        monotonicNanoseconds: 20,
        isAutoRepeat: false
      ))

    #expect(
      down
        == .accepted(
          .init(
            source: .ioHIDManager,
            key: key,
            previousState: nil,
            state: .pressed,
            monotonicNanoseconds: 10
          )))
    #expect(
      up
        == .accepted(
          .init(
            source: .ioHIDManager,
            key: key,
            previousState: .pressed,
            state: .released,
            monotonicNanoseconds: 20
          )))
  }

  @Test("помеченный автоповтор исключается из первичной трассы")
  func rejectsMarkedAutoRepeat() {
    var reducer = PhysicalKeyStateReducer()
    let key = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04)
    _ = reducer.consume(
      .init(
        source: .cgEventTap,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))

    let result = reducer.consume(
      .init(
        source: .cgEventTap,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 20,
        isAutoRepeat: true
      ))

    #expect(result == .rejected(.autoRepeat))
    #expect(reducer.currentState(of: key) == .pressed)
  }

  @Test("повтор того же состояния исключается даже без флага автоповтора")
  func rejectsDuplicateState() {
    var reducer = PhysicalKeyStateReducer()
    let key = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04)
    let observation = PhysicalKeyObservation(
      source: .gcKeyboard,
      key: key,
      state: .pressed,
      monotonicNanoseconds: 10,
      isAutoRepeat: false
    )

    _ = reducer.consume(observation)
    let result = reducer.consume(
      .init(
        source: .gcKeyboard,
        key: key,
        state: .pressed,
        monotonicNanoseconds: 20,
        isAutoRepeat: false
      ))

    #expect(result == .rejected(.unchangedPhysicalState))
  }

  @Test("наблюдение без явного физического состояния не попадает в трассу")
  func rejectsMissingPhysicalState() {
    var reducer = PhysicalKeyStateReducer()
    let key = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x39)

    let result = reducer.consume(
      .init(
        source: .nsEvent,
        key: key,
        state: nil,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))

    #expect(result == .rejected(.missingPhysicalState))
    #expect(reducer.currentState(of: key) == nil)
  }

  @Test("левая и правая Command имеют независимые состояния")
  func keepsSidesIndependent() {
    var reducer = PhysicalKeyStateReducer()
    let left = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0xE3)
    let right = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0xE7)

    _ = reducer.consume(
      .init(
        source: .ioHIDManager,
        key: left,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))
    _ = reducer.consume(
      .init(
        source: .ioHIDManager,
        key: right,
        state: .pressed,
        monotonicNanoseconds: 20,
        isAutoRepeat: false
      ))

    #expect(reducer.currentState(of: left) == .pressed)
    #expect(reducer.currentState(of: right) == .pressed)
  }

  @Test("одна и та же HID-клавиша на разных устройствах не объединяется")
  func keepsDevicesIndependent() {
    var reducer = PhysicalKeyStateReducer()
    let first = PhysicalKey(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x39)
    let second = PhysicalKey(deviceID: "keyboard-2", usagePage: 0x07, usage: 0x39)

    _ = reducer.consume(
      .init(
        source: .ioHIDManager,
        key: first,
        state: .pressed,
        monotonicNanoseconds: 10,
        isAutoRepeat: false
      ))

    #expect(reducer.currentState(of: first) == .pressed)
    #expect(reducer.currentState(of: second) == nil)
  }

  @Test("версионированная запись трассы побитово воспроизводимо читается")
  func traceRecordRoundTrip() throws {
    let transition = PhysicalKeyTransition(
      source: .ioHIDManager,
      key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0x04),
      previousState: nil,
      state: .pressed,
      monotonicNanoseconds: 100
    )
    let record = PhysicalKeyTraceRecord(
      sequenceNumber: 1,
      transition: transition
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(record)
    let decoded = try JSONDecoder().decode(PhysicalKeyTraceRecord.self, from: data)

    #expect(record.schemaVersion == 1)
    #expect(record.sequenceNumber == 1)
    #expect(decoded == record)
    #expect(String(decoding: data, as: UTF8.self).contains("\"isAutoRepeat\"") == false)
  }
}
